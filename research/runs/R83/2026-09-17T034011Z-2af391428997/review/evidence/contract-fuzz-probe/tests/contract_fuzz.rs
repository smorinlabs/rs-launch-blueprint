//! R83 synthesis probe — the contract-fuzz harness under observation.
//!
//! This file is EVIDENCE, not template code. It exists so the synthesis can observe
//! whether the architecture the raw report recommends (parse the served OpenAPI 3.1
//! document with `oas3`, map each operation's declared schema onto a `proptest`
//! strategy, drive the router in process with `tower::ServiceExt::oneshot`, assert on
//! the response) actually behaves as claimed. P03 writes the template's real harness.
//!
//! No operation name appears below: every operation is enumerated from the document the
//! service serves, which is the point of principle P1.
//!
//! Three oracles are implemented so that their separate reach can be measured:
//!   * `not_a_server_error` — no 5xx (py's check; principle P3).
//!   * `registered_status`  — the status code is IANA-registered (REST standard R5.2).
//!   * `json_object_body`   — a JSON response body has an object at the top level
//!                            (REST standard R4.3).
//! Response-SCHEMA conformance is deliberately NOT asserted (principle P3).

use axum::{
    Router,
    body::{Body, to_bytes},
    http::{Method, Request, StatusCode, header},
};
use oas3::{
    Spec,
    spec::{
        ObjectOrReference, ObjectSchema, Operation, ParameterIn, Schema, SchemaType,
        SchemaTypeSet,
    },
};
use proptest::{
    prelude::*,
    strategy::{BoxedStrategy, Union, ValueTree},
    test_runner::{Config, RngAlgorithm, TestError, TestRng, TestRunner},
};
use r83_probe::build_router;
use serde_json::{Map as JsonMap, Value};
use tower::ServiceExt;

/// Cases generated per operation. py's suite uses `max_examples=10`.
const CASES_PER_OPERATION: u32 = 16;

/// Path at which the service serves its own contract. The only thing the harness needs
/// to be told; everything else comes out of the document.
const DOCUMENT_PATH: &str = "/openapi.json";

/// Status codes registered with IANA for HTTP (RFC 9110 and the registry's later
/// additions). REST API Design Standard R5.2: "Unregistered status codes MUST NOT be
/// defined or used."
const REGISTERED_STATUS: &[u16] = &[
    100, 101, 102, 103, 200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302,
    303, 304, 305, 306, 307, 308, 400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410,
    411, 412, 413, 414, 415, 416, 417, 418, 421, 422, 423, 424, 425, 426, 428, 429, 431,
    451, 500, 501, 502, 503, 504, 505, 506, 507, 508, 510, 511,
];

/// One generated case: the concrete request path, and the JSON body if the operation
/// declares an `application/json` request body.
type Case = (String, Option<Value>);

#[test]
fn contract_fuzz() {
    let runtime = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .expect("current-thread runtime");
    let router = build_router();

    // --- discovery: fetch the document the service itself serves, in process ---------
    let document = runtime.block_on(async {
        let response = router
            .clone()
            .oneshot(
                Request::builder()
                    .method(Method::GET)
                    .uri(DOCUMENT_PATH)
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .expect("router served the contract document");
        assert_eq!(response.status(), StatusCode::OK, "{DOCUMENT_PATH} status");
        let bytes = to_bytes(response.into_body(), 4 * 1024 * 1024).await.unwrap();
        String::from_utf8(bytes.to_vec()).expect("utf-8 document")
    });

    let spec: Spec = oas3::from_json(&document).expect("served document parses as OpenAPI");
    let version = spec
        .validate_version()
        .expect("served document is within oas3's supported OpenAPI version range");
    println!("document version: {version}");

    // --- enumeration: every documented operation, from the document alone ------------
    let operations: Vec<(String, Method, &Operation)> = spec.operations().collect();
    println!("operations discovered: {}", operations.len());
    assert!(
        !operations.is_empty(),
        "the served document documented no operation at all"
    );

    let mut failures: Vec<String> = Vec::new();

    for (template, method, operation) in &operations {
        let name = operation
            .operation_id
            .clone()
            .unwrap_or_else(|| format!("{method} {template}"));
        let strategy = case_strategy(template, operation, &spec);

        // A deterministic RNG, so that this evidence log reproduces byte for byte. A
        // template's real suite would use proptest's default entropy source; nothing in
        // the design depends on the choice.
        let mut runner = TestRunner::new_with_rng(
            Config {
                cases: CASES_PER_OPERATION,
                failure_persistence: None,
                ..Config::default()
            },
            TestRng::deterministic_rng(RngAlgorithm::ChaCha),
        );

        let result = runner.run(&strategy, |(path, body): Case| {
            let (status, content_type, payload) =
                runtime.block_on(send(&router, method, &path, body.as_ref()));

            // Oracle 1 — principle P3, py's `not_a_server_error`.
            prop_assert!(
                !status.is_server_error(),
                "{status} for {method} {path} body={}",
                body.as_ref().map(|b| b.to_string()).unwrap_or_default()
            );
            // Oracle 2 — REST API Design Standard R5.2.
            prop_assert!(
                REGISTERED_STATUS.contains(&status.as_u16()),
                "unregistered status {status} for {method} {path}"
            );
            // Oracle 3 — REST API Design Standard R4.3.
            if content_type.starts_with("application/json") {
                let parsed: Value =
                    serde_json::from_slice(&payload).expect("declared JSON body parses");
                prop_assert!(
                    parsed.is_object(),
                    "non-object JSON top level ({parsed}) for {method} {path}"
                );
            }
            Ok(())
        });

        match result {
            Ok(()) => println!("{name}: {CASES_PER_OPERATION} cases, no finding"),
            Err(TestError::Fail(reason, minimal)) => {
                let line = format!("{name}: {reason}; minimal failing input: {minimal:?}");
                println!("{line}");
                failures.push(line);
            }
            Err(TestError::Abort(reason)) => panic!("{name}: aborted: {reason}"),
        }
    }

    assert!(failures.is_empty(), "contract findings:\n{}", failures.join("\n"));
}

/// Issues one generated request against the router in process and returns the parts the
/// oracles read.
async fn send(
    router: &Router,
    method: &Method,
    path: &str,
    body: Option<&Value>,
) -> (StatusCode, String, Vec<u8>) {
    let request = Request::builder().method(method).uri(path);
    let request = match body {
        Some(value) => request
            .header(header::CONTENT_TYPE, "application/json")
            .body(Body::from(value.to_string()))
            .unwrap(),
        None => request.body(Body::empty()).unwrap(),
    };
    let response = router.clone().oneshot(request).await.expect("infallible router");
    let status = response.status();
    let content_type = response
        .headers()
        .get(header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or_default()
        .to_owned();
    let bytes = to_bytes(response.into_body(), 4 * 1024 * 1024).await.unwrap();
    (status, content_type, bytes.to_vec())
}

/// Builds the per-operation strategy: the concrete path (path parameters substituted
/// from their declared schemas) paired with the declared JSON request body, if any.
fn case_strategy(template: &str, operation: &Operation, spec: &Spec) -> BoxedStrategy<Case> {
    let mut names: Vec<String> = Vec::new();
    let mut parts: Vec<BoxedStrategy<Value>> = Vec::new();

    for parameter in &operation.parameters {
        let Ok(parameter) = parameter.resolve(spec) else {
            continue;
        };
        if parameter.location != ParameterIn::Path {
            continue; // query/header/cookie parameters are out of this probe's scope
        }
        let schema = parameter
            .schema
            .as_ref()
            .and_then(|s| resolve_object(s, spec))
            .unwrap_or_default();
        names.push(parameter.name.clone());
        parts.push(value_strategy(&schema, spec, 0));
    }

    let template = template.to_owned();
    let path = parts.prop_map(move |values| {
        let mut rendered = template.clone();
        for (name, value) in names.iter().zip(values) {
            let literal = match value {
                Value::String(s) => s,
                other => other.to_string(),
            };
            rendered = rendered.replace(&format!("{{{name}}}"), &literal);
        }
        rendered
    });

    let body = match request_body_schema(operation, spec) {
        Some(schema) => value_strategy(&schema, spec, 0).prop_map(Some).boxed(),
        None => Just(None).boxed(),
    };

    (path, body).boxed()
}

/// The `application/json` request-body schema of an operation, resolved through `$ref`.
fn request_body_schema(operation: &Operation, spec: &Spec) -> Option<ObjectSchema> {
    let body = operation.request_body.as_ref()?.resolve(spec).ok()?;
    let media = body.content.get("application/json")?;
    resolve_object(media.schema.as_ref()?, spec)
}

/// Follows `$ref` until an inline object schema is reached.
fn resolve_object(schema: &Schema, spec: &Spec) -> Option<ObjectSchema> {
    match schema.resolve(spec).ok()? {
        Schema::Object(boxed) => match *boxed {
            ObjectOrReference::Object(object) => Some(object),
            ObjectOrReference::Ref { .. } => None,
        },
        Schema::Boolean(_) => None,
    }
}

/// Maps one JSON-Schema object onto a `proptest` strategy over `serde_json::Value`.
///
/// Keyword subset: `enum`, `type`, `minimum`/`maximum`, `minLength`/`maxLength`,
/// `minItems`/`maxItems`, `properties`, `items`. Every numeric and string strategy is a
/// `Union` that explicitly includes the declared boundaries — see the comment on
/// `integer_strategy`; a uniform draw is not enough.
fn value_strategy(schema: &ObjectSchema, spec: &Spec, depth: usize) -> BoxedStrategy<Value> {
    if !schema.enum_values.is_empty() {
        let choices: Vec<BoxedStrategy<Value>> = schema
            .enum_values
            .iter()
            .map(|v| Just(v.clone()).boxed())
            .collect();
        return Union::new(choices).boxed();
    }
    if let Some(constant) = &schema.const_value {
        return Just(constant.clone()).boxed();
    }

    let kind = match &schema.schema_type {
        Some(SchemaTypeSet::Single(t)) => *t,
        Some(SchemaTypeSet::Multiple(set)) => *set.first().unwrap_or(&SchemaType::Object),
        None => SchemaType::Object,
    };

    match kind {
        SchemaType::Boolean => any::<bool>().prop_map(Value::Bool).boxed(),
        SchemaType::Null => Just(Value::Null).boxed(),
        SchemaType::Integer => integer_strategy(schema),
        SchemaType::Number => integer_strategy(schema),
        SchemaType::String => string_strategy(schema),
        SchemaType::Array if depth < 3 => {
            let min = schema.min_items.unwrap_or(0) as usize;
            let max = schema.max_items.unwrap_or(3).max(min as u64) as usize;
            match schema.items.as_ref().and_then(|i| resolve_object(i, spec)) {
                Some(item) => proptest::collection::vec(
                    value_strategy(&item, spec, depth + 1),
                    min..=max,
                )
                .prop_map(Value::Array)
                .boxed(),
                None => Just(Value::Array(Vec::new())).boxed(),
            }
        }
        SchemaType::Object if depth < 3 => {
            let mut fields: Vec<(String, BoxedStrategy<Value>)> = Vec::new();
            for (name, property) in &schema.properties {
                if let Some(property) = resolve_object(property, spec) {
                    fields.push((name.clone(), value_strategy(&property, spec, depth + 1)));
                }
            }
            if fields.is_empty() {
                return Just(Value::Object(JsonMap::new())).boxed();
            }
            let (names, strategies): (Vec<String>, Vec<BoxedStrategy<Value>>) =
                fields.into_iter().unzip();
            strategies
                .prop_map(move |values| {
                    let mut object = JsonMap::new();
                    for (name, value) in names.iter().zip(values) {
                        object.insert(name.clone(), value);
                    }
                    Value::Object(object)
                })
                .boxed()
        }
        _ => Just(Value::Null).boxed(),
    }
}

/// Integers and numbers, with the declared boundaries drawn explicitly.
///
/// MEASURED REQUIREMENT, not a stylistic choice: with `Just(min)`/`Just(max)`/`Just(0)`
/// removed from this `Union`, 16 uniform draws from `0..=100` miss `0` often enough that
/// the seeded defect at `limit = 0` goes undetected. See review/evidence/ for the run
/// that shows it. A schema-to-strategy mapper must ask for boundary bias explicitly;
/// unlike Hypothesis, `proptest` does not supply it for a bare range.
fn integer_strategy(schema: &ObjectSchema) -> BoxedStrategy<Value> {
    let min = schema
        .minimum
        .as_ref()
        .and_then(|n| n.as_i64())
        .unwrap_or(-1_000);
    let max = schema
        .maximum
        .as_ref()
        .and_then(|n| n.as_i64())
        .unwrap_or(1_000)
        .max(min);

    if std::env::var_os(NO_BOUNDARY_BIAS_ENV).is_some() {
        // The counterfactual: a uniform draw over the declared range and nothing else.
        return (min..=max).prop_map(Value::from).boxed();
    }

    let mut choices: Vec<BoxedStrategy<Value>> = vec![
        Just(Value::from(min)).boxed(),
        Just(Value::from(max)).boxed(),
        (min..=max).prop_map(Value::from).boxed(),
    ];
    if min <= 0 && 0 <= max {
        choices.push(Just(Value::from(0_i64)).boxed());
    }
    Union::new(choices).boxed()
}

/// Set to drop the boundary bias from `integer_strategy`, which is how the
/// `boundary_bias_is_required` measurement below and the harness's own counterfactual leg
/// are taken.
const NO_BOUNDARY_BIAS_ENV: &str = "R83_NO_BOUNDARY_BIAS";

/// Measures which OpenAPI versions `oas3` 0.22.0 will validate, because the answer is a
/// constraint this item places on whichever generator R71 selects.
#[test]
fn supported_openapi_version_range() {
    let three_one = oas3::from_json(r83_probe::OPENAPI_DOC).expect("3.1.0 document parses");
    println!(
        "3.1.0 validate_version: {:?}",
        three_one.validate_version().map(|v| v.to_string())
    );
    assert_eq!(
        three_one.validate_version().unwrap().to_string(),
        "3.1.0",
        "the served 3.1.0 document must validate"
    );

    let relabelled = r83_probe::OPENAPI_DOC.replacen("3.1.0", "3.0.3", 1);
    let three_zero = oas3::from_json(&relabelled).expect("a 3.0.3-labelled document still parses");
    let outcome = three_zero.validate_version();
    println!("3.0.3 validate_version: {outcome:?}");
    assert!(
        outcome.is_err(),
        "oas3 0.22.0 must refuse to validate a 3.0-labelled document"
    );
    println!(
        "3.0.3 operations still enumerated: {}",
        three_zero.operations().count()
    );
}

/// Measures, rather than asserts, why `integer_strategy` carries an explicit `Union` over
/// the declared boundaries.
///
/// For each of 20 fixed RNG seeds it draws `CASES_PER_OPERATION` values from the
/// `{"type":"integer","minimum":0,"maximum":100}` schema, once with the boundary bias and
/// once without, and counts the seeds whose 16 draws contain the boundary value `0` — the
/// value at which the probe's service carries its seeded 500. The biased mapper must find
/// it under every seed; the uniform one must miss it under most.
#[test]
fn boundary_bias_is_required() {
    let schema: ObjectSchema =
        serde_json::from_str(r#"{"type":"integer","minimum":0,"maximum":100}"#).unwrap();

    let reaches_zero = |biased: bool| -> usize {
        // SAFETY of the measurement, not of memory: the two arms are run sequentially in
        // one test, and the variable is removed before the next arm is taken.
        let mut hits = 0_usize;
        for seed in 0_u8..20 {
            let mut runner = TestRunner::new_with_rng(
                Config {
                    cases: CASES_PER_OPERATION,
                    failure_persistence: None,
                    ..Config::default()
                },
                TestRng::from_seed(RngAlgorithm::ChaCha, &[seed; 32]),
            );
            let strategy = if biased {
                biased_integer_strategy(&schema)
            } else {
                (0_i64..=100).prop_map(Value::from).boxed()
            };
            let found = (0..CASES_PER_OPERATION).any(|_| {
                strategy
                    .new_tree(&mut runner)
                    .map(|tree| tree.current() == Value::from(0_i64))
                    .unwrap_or(false)
            });
            hits += usize::from(found);
        }
        hits
    };

    let with_bias = reaches_zero(true);
    let without_bias = reaches_zero(false);
    println!("seeds reaching the declared boundary 0 in {CASES_PER_OPERATION} draws:");
    println!("  with explicit boundary bias: {with_bias}/20");
    println!("  uniform draw only:           {without_bias}/20");
    assert_eq!(with_bias, 20, "the biased mapper must reach every boundary");
    assert!(
        without_bias < 20,
        "a uniform mapper that never misses the boundary would make the bias pointless"
    );
}

/// The biased arm of `boundary_bias_is_required`, independent of the environment variable
/// so that both arms can be measured inside one process.
fn biased_integer_strategy(schema: &ObjectSchema) -> BoxedStrategy<Value> {
    let min = schema.minimum.as_ref().and_then(|n| n.as_i64()).unwrap_or(-1_000);
    let max = schema
        .maximum
        .as_ref()
        .and_then(|n| n.as_i64())
        .unwrap_or(1_000)
        .max(min);
    let mut choices: Vec<BoxedStrategy<Value>> = vec![
        Just(Value::from(min)).boxed(),
        Just(Value::from(max)).boxed(),
        (min..=max).prop_map(Value::from).boxed(),
    ];
    if min <= 0 && 0 <= max {
        choices.push(Just(Value::from(0_i64)).boxed());
    }
    Union::new(choices).boxed()
}

/// Strings, with the declared length boundaries drawn explicitly.
fn string_strategy(schema: &ObjectSchema) -> BoxedStrategy<Value> {
    let min = schema.min_length.unwrap_or(0);
    let max = schema.max_length.unwrap_or(16).max(min);
    let exact = |n: u64| {
        proptest::string::string_regex(&format!("[a-z]{{{n}}}"))
            .expect("literal regex")
            .prop_map(Value::String)
            .boxed()
    };
    let spread = proptest::string::string_regex(&format!("[a-z]{{{min},{max}}}"))
        .expect("literal regex")
        .prop_map(Value::String)
        .boxed();
    Union::new(vec![exact(min), exact(max), spread]).boxed()
}
