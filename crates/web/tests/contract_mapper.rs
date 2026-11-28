//! Default-tier unit tests for the R83 OpenAPI 3.1 schema-to-`Strategy` mapper (`AC7`).
//!
//! Runs on every default `just test` invocation to prevent silent under-generation of declared
//! valid boundaries and boundary-invalid single-constraint mutations.

mod common;

use std::collections::BTreeSet;

use axum::http::Method;
use oas3::Spec;
use oas3::spec::Schema;
use proptest::strategy::{Strategy, ValueTree};
use proptest::test_runner::TestRunner;
use serde_json::{Value, json};

fn parse_schema(raw: Value) -> (Spec, Schema) {
    let spec_json = json!({
        "openapi": "3.1.0",
        "info": { "title": "mapper-test", "version": "0.0.0" },
        "paths": {},
        "components": {
            "schemas": {
                "Target": raw
            }
        }
    });
    let spec: Spec = oas3::from_json(spec_json.to_string()).expect("parse inline OpenAPI 3.1");
    let schema = spec
        .components
        .as_ref()
        .expect("inline components")
        .schemas
        .get("Target")
        .expect("Target schema")
        .clone();
    (spec, schema)
}

#[test]
fn valid_strategy_hits_declared_integer_string_array_enum_and_nullable_boundaries() {
    // 1. R72 pagination limit: integer 1..=100 -> must hit both 1 and 100 reliably.
    let (spec, limit_schema) = parse_schema(json!({
        "type": "integer",
        "minimum": 1,
        "maximum": 100
    }));
    let strategy = common::valid_strategy(&limit_schema, &spec);
    let mut runner = TestRunner::deterministic();
    let mut seen_ints = BTreeSet::new();
    for _ in 0..64 {
        let v = strategy.new_tree(&mut runner).unwrap().current();
        let n = v.as_i64().expect("integer sample");
        assert!((1..=100).contains(&n), "generated out-of-range valid {n}");
        seen_ints.insert(n);
    }
    assert!(
        seen_ints.contains(&1) && seen_ints.contains(&100),
        "boundary bias must generate 1 and 100, got: {seen_ints:?}"
    );

    // 2. String with minLength=2, maxLength=8 -> must hit lengths 2 and 8.
    let (spec, str_schema) = parse_schema(json!({
        "type": "string",
        "minLength": 2,
        "maxLength": 8
    }));
    let strategy = common::valid_strategy(&str_schema, &spec);
    let mut seen_lens = BTreeSet::new();
    for _ in 0..64 {
        let v = strategy.new_tree(&mut runner).unwrap().current();
        let len = v.as_str().expect("string sample").len();
        assert!((2..=8).contains(&len));
        seen_lens.insert(len);
    }
    assert!(
        seen_lens.contains(&2) && seen_lens.contains(&8),
        "string boundary bias must generate min and max lengths: {seen_lens:?}"
    );

    // 3. OpenAPI 3.1 nullable type array: ["string", "null"].
    let (spec, nullable_schema) = parse_schema(json!({
        "type": ["string", "null"],
        "minLength": 1,
        "maxLength": 4
    }));
    let strategy = common::valid_strategy(&nullable_schema, &spec);
    let mut saw_null = false;
    let mut saw_str = false;
    for _ in 0..64 {
        let v = strategy.new_tree(&mut runner).unwrap().current();
        if v.is_null() {
            saw_null = true;
        } else if v.is_string() {
            saw_str = true;
        } else {
            panic!("unexpected value for nullable string: {v}");
        }
    }
    assert!(
        saw_null && saw_str,
        "3.1 nullable type must produce both null and string"
    );

    // 4. Enum schema produces all declared enum variants.
    let (spec, enum_schema) = parse_schema(json!({
        "type": "string",
        "enum": ["ok", "warn", "error"]
    }));
    let strategy = common::valid_strategy(&enum_schema, &spec);
    let mut seen_enum = BTreeSet::new();
    for _ in 0..64 {
        let v = strategy.new_tree(&mut runner).unwrap().current();
        seen_enum.insert(v.as_str().unwrap().to_owned());
    }
    assert_eq!(
        seen_enum,
        BTreeSet::from(["error".to_owned(), "ok".to_owned(), "warn".to_owned()])
    );

    // 5. Exclusive float bounds: exclusiveMinimum=0.0, maximum=1.0 -> valid samples strictly > 0.0
    //    and <= 1.0, and invalid enumeration emits the excluded boundary 0.0.
    let (spec, float_schema) = parse_schema(json!({
        "type": "number",
        "exclusiveMinimum": 0.0,
        "maximum": 1.0
    }));
    let strategy = common::valid_strategy(&float_schema, &spec);
    for _ in 0..64 {
        let v = strategy.new_tree(&mut runner).unwrap().current();
        let f = v.as_f64().expect("float sample");
        assert!(
            f > 0.0 && f <= 1.0,
            "exclusiveMinimum=0.0 must never emit 0.0 or > 1.0, got {f}"
        );
    }
    let det_float = common::sample_valid_value(&float_schema, &spec)
        .as_f64()
        .expect("deterministic float");
    assert!(det_float > 0.0 && det_float <= 1.0);
    let float_invalids = common::enumerate_boundary_invalid(&float_schema, &spec);
    assert!(
        float_invalids
            .iter()
            .any(|c| c.arm.contains("exclusiveMinimum") && c.value.as_f64() == Some(0.0)),
        "expected excluded boundary 0.0 in invalid cases: {float_invalids:?}"
    );

    // 6. Negative-only upper bound: integer maximum=-200 -> fallback lo stays <= -200.
    let (spec, neg_int_schema) = parse_schema(json!({
        "type": "integer",
        "maximum": -200
    }));
    let strategy = common::valid_strategy(&neg_int_schema, &spec);
    let mut saw_max = false;
    for _ in 0..64 {
        let v = strategy.new_tree(&mut runner).unwrap().current();
        let n = v.as_i64().expect("negative integer sample");
        assert!(n <= -200, "generated sample {n} violated maximum -200");
        if n == -200 {
            saw_max = true;
        }
    }
    assert!(saw_max, "expected boundary -200 to be generated");

    // 7. Declared string bounds up to 255 (e.g. Idempotency-Key) and minLength > 32 stay intact.
    let (spec, long_str_schema) = parse_schema(json!({
        "type": "string",
        "minLength": 40,
        "maxLength": 255
    }));
    let strategy = common::valid_strategy(&long_str_schema, &spec);
    let mut seen_long_lens = BTreeSet::new();
    for _ in 0..64 {
        let v = strategy.new_tree(&mut runner).unwrap().current();
        let len = v.as_str().expect("long string sample").len();
        assert!(
            (40..=255).contains(&len),
            "sample length {len} outside 40..=255"
        );
        seen_long_lens.insert(len);
    }
    assert!(
        seen_long_lens.contains(&40) && seen_long_lens.contains(&255),
        "must preserve declared boundaries 40 and 255, got: {seen_long_lens:?}"
    );
    let det_long = common::sample_valid_value(&long_str_schema, &spec);
    assert!(det_long.as_str().expect("det long string").len() >= 40);
    let long_invalids = common::enumerate_boundary_invalid(&long_str_schema, &spec);
    assert!(
        long_invalids
            .iter()
            .any(|c| c.value.as_str().is_some_and(|s| s.len() == 39)),
        "expected below_minLength(39): {long_invalids:?}"
    );
    assert!(
        long_invalids
            .iter()
            .any(|c| c.value.as_str().is_some_and(|s| s.len() == 256)),
        "expected above_maxLength(256): {long_invalids:?}"
    );
}

#[test]
fn boundary_invalid_enumeration_covers_every_declared_constraint_with_single_violation() {
    // Integer 1..=100 -> must deterministically emit 0 (min - 1), 101 (max + 1), and wrong type.
    let (spec, limit_schema) = parse_schema(json!({
        "type": "integer",
        "minimum": 1,
        "maximum": 100
    }));
    let invalids = common::enumerate_boundary_invalid(&limit_schema, &spec);
    let values: Vec<&Value> = invalids.iter().map(|c| &c.value).collect();
    assert!(
        values.contains(&&json!(0)),
        "missing minimum-1 (0): {invalids:?}"
    );
    assert!(
        values.contains(&&json!(101)),
        "missing maximum+1 (101): {invalids:?}"
    );
    assert!(
        invalids.iter().any(|c| c.arm.starts_with("type:")),
        "missing wrong-type arm: {invalids:?}"
    );

    // Object with required `name` (minLength=1) and optional `count` (1..=5).
    let (spec, obj_schema) = parse_schema(json!({
        "type": "object",
        "required": ["name"],
        "properties": {
            "name": { "type": "string", "minLength": 1, "maxLength": 10 },
            "count": { "type": "integer", "minimum": 1, "maximum": 5 }
        }
    }));
    let invalids = common::enumerate_boundary_invalid(&obj_schema, &spec);
    assert!(
        invalids
            .iter()
            .any(|c| c.arm == "object:missing_required(name)"
                && c.value.as_object().is_some_and(|m| !m.contains_key("name"))),
        "missing required property removal arm: {invalids:?}"
    );
    assert!(
        invalids
            .iter()
            .any(|c| c.arm == "property(name):string:below_minLength(1 - 1)"
                && c.value["name"] == json!("")),
        "missing empty-name boundary-invalid arm: {invalids:?}"
    );
    assert!(
        invalids
            .iter()
            .any(|c| c.arm == "property(count):integer:above_maximum(5 + 1)"
                && c.value["count"] == json!(6)
                && c.value["name"].as_str().is_some_and(|s| !s.is_empty())),
        "property boundary-invalid arm must preserve other valid required fields: {invalids:?}"
    );
}

#[test]
fn request_assembly_handles_path_query_header_and_cookie_parameters() {
    let spec_json = json!({
        "openapi": "3.1.0",
        "info": { "title": "param-test", "version": "0.0.0" },
        "paths": {
            "/v1/items/{id}": {
                "post": {
                    "operationId": "items-create",
                    "parameters": [
                        { "name": "id", "in": "path", "required": true, "schema": { "type": "string", "minLength": 1 } },
                        { "name": "limit", "in": "query", "required": false, "schema": { "type": "integer", "minimum": 1, "maximum": 100 } },
                        { "name": "x-trace", "in": "header", "required": false, "schema": { "type": "string", "maxLength": 8 } },
                        { "name": "session", "in": "cookie", "required": false, "schema": { "type": "string", "minLength": 1 } }
                    ],
                    "requestBody": {
                        "required": true,
                        "content": {
                            "application/json": {
                                "schema": {
                                    "type": "object",
                                    "required": ["name"],
                                    "properties": {
                                        "name": { "type": "string", "minLength": 1 }
                                    }
                                }
                            }
                        }
                    },
                    "responses": { "200": { "description": "ok" } }
                }
            }
        }
    });
    let spec: Spec = oas3::from_json(spec_json.to_string()).unwrap();
    let (path, method, op) = spec.operations().next().unwrap();
    assert_eq!(method, Method::POST);

    let invalid_reqs = common::operation_boundary_invalid_requests(&path, op, &spec);
    assert!(
        invalid_reqs.iter().any(
            |(arm, req)| arm.contains("param(limit):integer:below_minimum")
                && req.query.iter().any(|(k, v)| k == "limit" && v == "0")
        ),
        "expected query limit=0 boundary-invalid request: {invalid_reqs:?}"
    );
    assert!(
        invalid_reqs.iter().any(
            |(arm, req)| arm.contains("param(limit):integer:above_maximum")
                && req.query.iter().any(|(k, v)| k == "limit" && v == "101")
        ),
        "expected query limit=101 boundary-invalid request: {invalid_reqs:?}"
    );
    assert!(
        invalid_reqs
            .iter()
            .any(|(arm, req)| arm.contains("param(x-trace)") && !req.headers.is_empty()),
        "expected header boundary-invalid request"
    );
    assert!(
        invalid_reqs
            .iter()
            .any(|(arm, req)| arm.contains("param(session)") && !req.cookies.is_empty()),
        "expected cookie boundary-invalid request"
    );

    assert!(
        invalid_reqs.iter().any(
            |(arm, req)| arm.contains("param(id):string:below_minLength")
                && req.path == "/v1/items/"
        ),
        "expected empty path segment preserved for below_minLength(1 - 1): {invalid_reqs:?}"
    );

    // Ensure every generated request builds cleanly into an Axum HTTP request.
    for (_, req) in &invalid_reqs {
        let http_req = req.to_http_request(&method);
        assert_eq!(http_req.method(), &Method::POST);
    }
}
