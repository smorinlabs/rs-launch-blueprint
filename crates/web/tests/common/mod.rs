//! Shared OpenAPI 3.1 schema-to-`proptest::Strategy` mapper for both default-tier mapper unit
//! tests (`tests/contract_mapper.rs`) and slow-tier contract fuzzing (`tests/contract_fuzz.rs`)
//! (`R83` revision 6).

#![allow(
    dead_code,
    reason = "shared helper module consumed across multiple integration test binaries"
)]

use std::collections::BTreeMap;

use axum::body::Body;
use axum::http::{Method, Request, header};
use oas3::Spec;
use oas3::spec::{
    ObjectOrReference, ObjectSchema, Operation, Parameter, ParameterIn, Schema, SchemaType,
    SchemaTypeSet,
};
use proptest::prelude::*;
use serde_json::{Map, Number, Value};

/// One deterministically enumerated boundary-invalid mutation arm (`R83` P2).
#[derive(Debug, Clone)]
pub(crate) struct BoundaryInvalidCase {
    /// Human-readable name identifying the exact violated constraint arm.
    pub(crate) arm: String,
    /// Single-constraint-violating JSON value.
    pub(crate) value: Value,
}

/// Generated request payload for one OpenAPI operation (`R83`).
#[derive(Debug, Clone)]
pub(crate) struct GeneratedRequest {
    /// Target path with path parameters substituted and percent-encoded.
    pub(crate) path: String,
    /// Query `(key, value)` pairs.
    pub(crate) query: Vec<(String, String)>,
    /// HTTP headers `(name, value)`.
    pub(crate) headers: Vec<(String, String)>,
    /// Cookie `(name, value)` pairs.
    pub(crate) cookies: Vec<(String, String)>,
    /// Optional JSON request body.
    pub(crate) body: Option<Value>,
}

impl GeneratedRequest {
    /// Render this generated case into an executable Axum [`Request`].
    pub(crate) fn to_http_request(&self, method: &Method) -> Request<Body> {
        let mut uri = self.path.clone();
        if !self.query.is_empty() {
            uri.push('?');
            for (idx, (k, v)) in self.query.iter().enumerate() {
                if idx > 0 {
                    uri.push('&');
                }
                uri.push_str(&percent_encode_component(k));
                uri.push('=');
                uri.push_str(&percent_encode_component(v));
            }
        }

        let mut builder = Request::builder().method(method.clone()).uri(&uri);
        for (name, val) in &self.headers {
            if let (Ok(hn), Ok(hv)) = (
                axum::http::HeaderName::from_bytes(name.as_bytes()),
                axum::http::HeaderValue::from_str(val),
            ) {
                builder = builder.header(hn, hv);
            }
        }
        if !self.cookies.is_empty() {
            let cookie_val: String = self
                .cookies
                .iter()
                .map(|(k, v)| format!("{k}={v}"))
                .collect::<Vec<_>>()
                .join("; ");
            if let Ok(hv) = axum::http::HeaderValue::from_str(&cookie_val) {
                builder = builder.header(header::COOKIE, hv);
            }
        }

        match &self.body {
            Some(val) => {
                let bytes = serde_json::to_vec(val).expect("serialize generated JSON body");
                builder
                    .header(header::CONTENT_TYPE, "application/json")
                    .body(Body::from(bytes))
                    .expect("build HTTP request with JSON body")
            }
            None => builder
                .body(Body::empty())
                .expect("build HTTP request with empty body"),
        }
    }
}

/// Percent-encode a URI path or query component safely while keeping unreserved bytes intact.
pub(crate) fn percent_encode_component(raw: &str) -> String {
    let mut out = String::with_capacity(raw.len());
    for byte in raw.bytes() {
        let unreserved = byte.is_ascii_alphanumeric() || matches!(byte, b'-' | b'_' | b'.' | b'~');
        if unreserved {
            out.push(char::from(byte));
        } else {
            use std::fmt::Write as _;
            let _ = write!(&mut out, "%{byte:02X}");
        }
    }
    out
}

/// Resolve an [`oas3::spec::Schema`] through `$ref` into an [`ObjectSchema`].
pub(crate) fn resolve_object_schema(schema: &Schema, spec: &Spec) -> Option<ObjectSchema> {
    let mut current = schema.clone();
    for _ in 0..8 {
        current = current.resolve(spec).ok()?;
        match current {
            Schema::Boolean(_) => return None,
            Schema::Object(obj_ref) => match *obj_ref {
                ObjectOrReference::Object(obj) => return Some(obj),
                ObjectOrReference::Ref { .. } => {
                    current = Schema::Object(obj_ref);
                }
            },
        }
    }
    None
}

fn primary_types(obj: &ObjectSchema) -> (Vec<SchemaType>, bool) {
    match &obj.schema_type {
        Some(SchemaTypeSet::Single(t)) => (vec![*t], *t == SchemaType::Null),
        Some(SchemaTypeSet::Multiple(list)) => {
            let nullable = list.contains(&SchemaType::Null);
            let non_null: Vec<SchemaType> = list
                .iter()
                .copied()
                .filter(|t| *t != SchemaType::Null)
                .collect();
            (non_null, nullable)
        }
        None => {
            if !obj.properties.is_empty() {
                (vec![SchemaType::Object], false)
            } else if obj.items.is_some() {
                (vec![SchemaType::Array], false)
            } else {
                (vec![SchemaType::String], false)
            }
        }
    }
}

fn integer_bounds(obj: &ObjectSchema) -> (Option<i64>, Option<i64>) {
    let min = obj.minimum.as_ref().and_then(Number::as_i64).or_else(|| {
        obj.exclusive_minimum
            .as_ref()
            .and_then(Number::as_i64)
            .map(|v| v.saturating_add(1))
    });
    let max = obj.maximum.as_ref().and_then(Number::as_i64).or_else(|| {
        obj.exclusive_maximum
            .as_ref()
            .and_then(Number::as_i64)
            .map(|v| v.saturating_sub(1))
    });
    (min, max)
}

fn float_bounds(obj: &ObjectSchema) -> (Option<f64>, Option<f64>) {
    let min = obj
        .minimum
        .as_ref()
        .and_then(Number::as_f64)
        .or_else(|| obj.exclusive_minimum.as_ref().and_then(Number::as_f64));
    let max = obj
        .maximum
        .as_ref()
        .and_then(Number::as_f64)
        .or_else(|| obj.exclusive_maximum.as_ref().and_then(Number::as_f64));
    (min, max)
}

/// Build a **valid**, boundary-biased `proptest` strategy for an OpenAPI 3.1 [`Schema`] (`R83` P2).
///
/// Explicitly biases integers toward `{minimum, maximum, 0-if-in-range, uniform}` and strings
/// toward `{shortest, longest, uniform}` so declared schema boundaries are hit reliably (AC7).
pub(crate) fn valid_strategy(schema: &Schema, spec: &Spec) -> BoxedStrategy<Value> {
    valid_strategy_depth(schema, spec, 0)
}

fn valid_strategy_depth(schema: &Schema, spec: &Spec, depth: usize) -> BoxedStrategy<Value> {
    if depth > 4 {
        return Just(Value::Null).boxed();
    }
    let Some(obj) = resolve_object_schema(schema, spec) else {
        return Just(Value::Object(Map::new())).boxed();
    };
    valid_object_strategy(&obj, spec, depth)
}

fn valid_object_strategy(obj: &ObjectSchema, spec: &Spec, depth: usize) -> BoxedStrategy<Value> {
    if let Some(const_val) = &obj.const_value {
        return Just(const_val.clone()).boxed();
    }
    if !obj.enum_values.is_empty() {
        let choices: Vec<BoxedStrategy<Value>> = obj
            .enum_values
            .iter()
            .cloned()
            .map(|v| Just(v).boxed())
            .collect();
        return proptest::strategy::Union::new(choices).boxed();
    }

    let (types, nullable) = primary_types(obj);
    let mut arms: Vec<BoxedStrategy<Value>> = Vec::new();

    for ty in types {
        let strategy: BoxedStrategy<Value> = match ty {
            SchemaType::Null => Just(Value::Null).boxed(),
            SchemaType::Boolean => any::<bool>().prop_map(Value::Bool).boxed(),
            SchemaType::Integer => {
                let (decl_min, decl_max) = integer_bounds(obj);
                let lo = decl_min.unwrap_or(-100);
                let hi = decl_max.unwrap_or(100).max(lo);
                let mut int_arms: Vec<BoxedStrategy<i64>> =
                    vec![Just(lo).boxed(), Just(hi).boxed(), (lo..=hi).boxed()];
                if lo <= 0 && 0 <= hi {
                    int_arms.push(Just(0).boxed());
                }
                proptest::strategy::Union::new(int_arms)
                    .prop_map(|n| Value::Number(Number::from(n)))
                    .boxed()
            }
            SchemaType::Number => {
                let (decl_min, decl_max) = float_bounds(obj);
                let lo = decl_min.unwrap_or(-100.0);
                let hi = decl_max.unwrap_or(100.0).max(lo);
                let mut f_arms: Vec<BoxedStrategy<f64>> =
                    vec![Just(lo).boxed(), Just(hi).boxed(), (lo..=hi).boxed()];
                if lo <= 0.0 && 0.0 <= hi {
                    f_arms.push(Just(0.0).boxed());
                }
                proptest::strategy::Union::new(f_arms)
                    .prop_map(|f| {
                        Number::from_f64(f)
                            .map_or_else(|| Value::Number(Number::from(0)), Value::Number)
                    })
                    .boxed()
            }
            SchemaType::String => {
                let min_len = usize::try_from(obj.min_length.unwrap_or(0))
                    .unwrap_or(0)
                    .min(32);
                let max_len = usize::try_from(obj.max_length.unwrap_or(16))
                    .unwrap_or(16)
                    .min(64)
                    .max(min_len);
                let shortest = "a".repeat(min_len);
                let longest = "z".repeat(max_len);
                let uniform = proptest::collection::vec(
                    prop::sample::select(b"abcdefghijklmnopqrstuvwxyz0123456789-_".to_vec()),
                    min_len..=max_len,
                )
                .prop_map(move |bytes| {
                    String::from_utf8(bytes).unwrap_or_else(|_| "a".repeat(min_len))
                });
                proptest::strategy::Union::new(vec![
                    Just(shortest).boxed(),
                    Just(longest).boxed(),
                    uniform.boxed(),
                ])
                .prop_map(Value::String)
                .boxed()
            }
            SchemaType::Array => {
                let min_items = usize::try_from(obj.min_items.unwrap_or(0))
                    .unwrap_or(0)
                    .min(8);
                let max_items = usize::try_from(obj.max_items.unwrap_or(3))
                    .unwrap_or(3)
                    .min(8)
                    .max(min_items);
                let item_strategy = obj.items.as_deref().map_or_else(
                    || Just(Value::String("x".to_owned())).boxed(),
                    |s| valid_strategy_depth(s, spec, depth + 1),
                );
                let shortest =
                    proptest::collection::vec(item_strategy.clone(), min_items..=min_items);
                let longest =
                    proptest::collection::vec(item_strategy.clone(), max_items..=max_items);
                let uniform = proptest::collection::vec(item_strategy, min_items..=max_items);
                proptest::strategy::Union::new(vec![
                    shortest.boxed(),
                    longest.boxed(),
                    uniform.boxed(),
                ])
                .prop_map(Value::Array)
                .boxed()
            }
            SchemaType::Object => {
                let mut prop_entries: Vec<(String, bool, BoxedStrategy<Value>)> = Vec::new();
                for (name, prop_schema) in &obj.properties {
                    let is_req = obj.required.contains(name);
                    let prop_strategy = valid_strategy_depth(prop_schema, spec, depth + 1);
                    prop_entries.push((name.clone(), is_req, prop_strategy));
                }
                prop_entries.sort_by(|a, b| a.0.cmp(&b.0));

                if prop_entries.is_empty() {
                    Just(Value::Object(Map::new())).boxed()
                } else {
                    let field_strats: Vec<BoxedStrategy<(String, Option<Value>)>> = prop_entries
                        .into_iter()
                        .map(|(name, is_req, s)| {
                            if is_req {
                                s.prop_map(move |v| (name.clone(), Some(v))).boxed()
                            } else {
                                proptest::option::of(s)
                                    .prop_map(move |opt| (name.clone(), opt))
                                    .boxed()
                            }
                        })
                        .collect();
                    field_strats
                        .prop_map(|pairs| {
                            let mut map = Map::new();
                            for (k, opt) in pairs {
                                if let Some(v) = opt {
                                    map.insert(k, v);
                                }
                            }
                            Value::Object(map)
                        })
                        .boxed()
                }
            }
        };
        arms.push(strategy);
    }

    if nullable {
        arms.push(Just(Value::Null).boxed());
    }
    if arms.is_empty() {
        return Just(Value::Null).boxed();
    }
    proptest::strategy::Union::new(arms).boxed()
}

/// Produce one deterministic valid sample value for a schema (used as base for single-constraint
/// boundary-invalid mutations so each invalid case violates **exactly one** declared constraint).
pub(crate) fn sample_valid_value(schema: &Schema, spec: &Spec) -> Value {
    sample_valid_depth(schema, spec, 0)
}

fn sample_valid_depth(schema: &Schema, spec: &Spec, depth: usize) -> Value {
    if depth > 4 {
        return Value::Null;
    }
    let Some(obj) = resolve_object_schema(schema, spec) else {
        return Value::Object(Map::new());
    };
    if let Some(c) = &obj.const_value {
        return c.clone();
    }
    if let Some(first) = obj.enum_values.first() {
        return first.clone();
    }
    let (types, _) = primary_types(&obj);
    match types.first().copied().unwrap_or(SchemaType::String) {
        SchemaType::Null => Value::Null,
        SchemaType::Boolean => Value::Bool(true),
        SchemaType::Integer => {
            let (min, max) = integer_bounds(&obj);
            let val = match (min, max) {
                (Some(lo), Some(hi)) => lo.saturating_add(hi.saturating_sub(lo) / 2),
                (Some(lo), None) => lo,
                (None, Some(hi)) => hi,
                (None, None) => 1,
            };
            Value::Number(Number::from(val))
        }
        SchemaType::Number => {
            let (min, max) = float_bounds(&obj);
            let val = match (min, max) {
                (Some(lo), Some(hi)) => f64::midpoint(lo, hi),
                (Some(lo), None) => lo,
                (None, Some(hi)) => hi,
                (None, None) => 1.0,
            };
            Number::from_f64(val).map_or_else(|| Value::Number(Number::from(1)), Value::Number)
        }
        SchemaType::String => {
            let min_len = usize::try_from(obj.min_length.unwrap_or(1))
                .unwrap_or(1)
                .max(1);
            let max_len = obj
                .max_length
                .and_then(|m| usize::try_from(m).ok())
                .unwrap_or(min_len);
            let len = min_len.min(max_len).min(32);
            Value::String("a".repeat(len))
        }
        SchemaType::Array => {
            let count = usize::try_from(obj.min_items.unwrap_or(0))
                .unwrap_or(0)
                .min(4);
            let item = obj
                .items
                .as_deref()
                .map_or(Value::String("x".to_owned()), |s| {
                    sample_valid_depth(s, spec, depth + 1)
                });
            Value::Array(vec![item; count])
        }
        SchemaType::Object => {
            let mut map = Map::new();
            for req in &obj.required {
                if let Some(prop_schema) = obj.properties.get(req) {
                    map.insert(
                        req.clone(),
                        sample_valid_depth(prop_schema, spec, depth + 1),
                    );
                }
            }
            Value::Object(map)
        }
    }
}

/// Deterministically enumerate every declared **boundary-invalid** constraint arm for `schema`
/// (`R83` P2, AC7).
///
/// Only generates arms for constraints actually declared in the schema (never fallback ranges)
/// and guarantees each arm violates a single constraint.
pub(crate) fn enumerate_boundary_invalid(schema: &Schema, spec: &Spec) -> Vec<BoundaryInvalidCase> {
    let Some(obj) = resolve_object_schema(schema, spec) else {
        return Vec::new();
    };
    let mut out = Vec::new();

    if !obj.enum_values.is_empty() {
        out.push(BoundaryInvalidCase {
            arm: "enum:outside_declared_values".to_owned(),
            value: Value::String("__invalid_enum_sentinel__".to_owned()),
        });
    }

    let (types, nullable) = primary_types(&obj);
    if !types.is_empty() {
        let wrong_type = if !types.contains(&SchemaType::Boolean) {
            Value::Bool(true)
        } else if !types.contains(&SchemaType::Object) {
            Value::Object(Map::new())
        } else {
            Value::Array(Vec::new())
        };
        if !(nullable && wrong_type.is_null()) {
            out.push(BoundaryInvalidCase {
                arm: "type:wrong_json_type".to_owned(),
                value: wrong_type,
            });
        }
    }

    if types.contains(&SchemaType::Integer) {
        let (min, max) = integer_bounds(&obj);
        if let Some(lo) = min {
            out.push(BoundaryInvalidCase {
                arm: format!("integer:below_minimum({lo} - 1)"),
                value: Value::Number(Number::from(lo.saturating_sub(1))),
            });
        }
        if let Some(hi) = max {
            out.push(BoundaryInvalidCase {
                arm: format!("integer:above_maximum({hi} + 1)"),
                value: Value::Number(Number::from(hi.saturating_add(1))),
            });
        }
    }

    if types.contains(&SchemaType::Number) {
        let (min, max) = float_bounds(&obj);
        if let Some(lo) = min
            && let Some(n) = Number::from_f64(lo - 1.0)
        {
            out.push(BoundaryInvalidCase {
                arm: format!("number:below_minimum({lo} - 1.0)"),
                value: Value::Number(n),
            });
        }
        if let Some(hi) = max
            && let Some(n) = Number::from_f64(hi + 1.0)
        {
            out.push(BoundaryInvalidCase {
                arm: format!("number:above_maximum({hi} + 1.0)"),
                value: Value::Number(n),
            });
        }
    }

    if types.contains(&SchemaType::String) {
        if let Some(min_len) = obj.min_length
            && min_len > 0
            && let Ok(len) = usize::try_from(min_len - 1)
        {
            out.push(BoundaryInvalidCase {
                arm: format!("string:below_minLength({min_len} - 1)"),
                value: Value::String("a".repeat(len.min(64))),
            });
        }
        if let Some(max_len) = obj.max_length
            && let Ok(len) = usize::try_from(max_len.saturating_add(1))
        {
            out.push(BoundaryInvalidCase {
                arm: format!("string:above_maxLength({max_len} + 1)"),
                value: Value::String("z".repeat(len.min(512))),
            });
        }
    }

    if types.contains(&SchemaType::Array) {
        if let Some(min_items) = obj.min_items
            && min_items > 0
            && let Ok(len) = usize::try_from(min_items - 1)
        {
            let elem = obj
                .items
                .as_deref()
                .map_or(Value::String("x".to_owned()), |s| {
                    sample_valid_value(s, spec)
                });
            out.push(BoundaryInvalidCase {
                arm: format!("array:below_minItems({min_items} - 1)"),
                value: Value::Array(vec![elem; len.min(16)]),
            });
        }
        if let Some(max_items) = obj.max_items
            && let Ok(len) = usize::try_from(max_items.saturating_add(1))
        {
            let elem = obj
                .items
                .as_deref()
                .map_or(Value::String("x".to_owned()), |s| {
                    sample_valid_value(s, spec)
                });
            out.push(BoundaryInvalidCase {
                arm: format!("array:above_maxItems({max_items} + 1)"),
                value: Value::Array(vec![elem; len.min(32)]),
            });
        }
    }

    if types.contains(&SchemaType::Object) {
        let base_obj = match sample_valid_value(schema, spec) {
            Value::Object(m) => m,
            _ => Map::new(),
        };
        for req_name in &obj.required {
            let mut mutated = base_obj.clone();
            mutated.remove(req_name);
            out.push(BoundaryInvalidCase {
                arm: format!("object:missing_required({req_name})"),
                value: Value::Object(mutated),
            });
        }
        let mut prop_names: Vec<&String> = obj.properties.keys().collect();
        prop_names.sort();
        for prop_name in prop_names {
            if let Some(prop_schema) = obj.properties.get(prop_name) {
                for sub_invalid in enumerate_boundary_invalid(prop_schema, spec) {
                    let mut mutated = base_obj.clone();
                    mutated.insert(prop_name.clone(), sub_invalid.value);
                    out.push(BoundaryInvalidCase {
                        arm: format!("property({prop_name}):{}", sub_invalid.arm),
                        value: Value::Object(mutated),
                    });
                }
            }
        }
    }

    out
}

fn value_to_param_string(val: &Value) -> Option<String> {
    match val {
        Value::Null => None,
        Value::Bool(b) => Some(b.to_string()),
        Value::Number(n) => Some(n.to_string()),
        Value::String(s) => Some(s.clone()),
        other => Some(other.to_string()),
    }
}

fn operation_parameters(op: &Operation, spec: &Spec) -> Vec<Parameter> {
    op.parameters
        .iter()
        .filter_map(|p| p.resolve(spec).ok())
        .collect()
}

fn operation_json_body_schema(op: &Operation, spec: &Spec) -> Option<Schema> {
    let rb = op.request_body.as_ref()?.resolve(spec).ok()?;
    let mt = rb.content.get("application/json")?;
    mt.schema.clone()
}

/// Build a **valid** `proptest` strategy producing [`GeneratedRequest`] instances for `op` (`R83`).
pub(crate) fn operation_valid_request_strategy(
    path_template: &str,
    op: &Operation,
    spec: &Spec,
) -> BoxedStrategy<GeneratedRequest> {
    let params = operation_parameters(op, spec);
    let body_schema = operation_json_body_schema(op, spec);

    let param_strats: Vec<BoxedStrategy<(ParameterIn, String, Option<String>)>> = params
        .into_iter()
        .map(|param| {
            let name = param.name.clone();
            let loc = param.location;
            let required = param.required.unwrap_or(loc == ParameterIn::Path);
            let s = param.schema.as_ref().map_or_else(
                || Just(Value::String("sample".to_owned())).boxed(),
                |sc| valid_strategy(sc, spec),
            );
            if required {
                s.prop_map(move |v| {
                    let text = value_to_param_string(&v).unwrap_or_else(|| "a".to_owned());
                    (loc, name.clone(), Some(text))
                })
                .boxed()
            } else {
                proptest::option::of(s)
                    .prop_map(move |opt| {
                        (
                            loc,
                            name.clone(),
                            opt.as_ref().and_then(value_to_param_string),
                        )
                    })
                    .boxed()
            }
        })
        .collect();

    let body_strategy: BoxedStrategy<Option<Value>> = match body_schema {
        Some(sc) => valid_strategy(&sc, spec).prop_map(Some).boxed(),
        None => Just(None).boxed(),
    };

    let template = path_template.to_owned();
    (param_strats, body_strategy)
        .prop_map(move |(param_vals, body)| assemble_request(&template, param_vals, body))
        .boxed()
}

/// Deterministically enumerate one [`GeneratedRequest`] per declared boundary-invalid constraint
/// arm across all parameters and JSON request body of `op` (`R83` P2, AC7).
pub(crate) fn operation_boundary_invalid_requests(
    path_template: &str,
    op: &Operation,
    spec: &Spec,
) -> Vec<(String, GeneratedRequest)> {
    let params = operation_parameters(op, spec);
    let body_schema = operation_json_body_schema(op, spec);

    // Construct a valid baseline for all parameters + body.
    let mut base_params: BTreeMap<(String, u8), (ParameterIn, String, Option<String>)> =
        BTreeMap::new();
    for p in &params {
        let required = p.required.unwrap_or(p.location == ParameterIn::Path);
        let val = if required {
            let sample = p
                .schema
                .as_ref()
                .map_or(Value::String("a".to_owned()), |s| {
                    sample_valid_value(s, spec)
                });
            Some(value_to_param_string(&sample).unwrap_or_else(|| "a".to_owned()))
        } else {
            None
        };
        base_params.insert(
            (p.name.clone(), loc_discriminant(p.location)),
            (p.location, p.name.clone(), val),
        );
    }
    let base_body = body_schema.as_ref().map(|s| sample_valid_value(s, spec));

    let mut cases = Vec::new();

    for p in &params {
        let Some(p_schema) = &p.schema else {
            continue;
        };
        for invalid in enumerate_boundary_invalid(p_schema, spec) {
            let mut mutated = base_params.clone();
            let raw_text = value_to_param_string(&invalid.value).unwrap_or_default();
            mutated.insert(
                (p.name.clone(), loc_discriminant(p.location)),
                (p.location, p.name.clone(), Some(raw_text)),
            );
            let req = assemble_request(
                path_template,
                mutated.into_values().collect(),
                base_body.clone(),
            );
            cases.push((format!("param({}):{}", p.name, invalid.arm), req));
        }
    }

    if let Some(b_schema) = &body_schema {
        for invalid in enumerate_boundary_invalid(b_schema, spec) {
            let req = assemble_request(
                path_template,
                base_params.values().cloned().collect(),
                Some(invalid.value),
            );
            cases.push((format!("body:{}", invalid.arm), req));
        }
    }

    cases
}

const fn loc_discriminant(loc: ParameterIn) -> u8 {
    match loc {
        ParameterIn::Path => 0,
        ParameterIn::Query => 1,
        ParameterIn::Header => 2,
        ParameterIn::Cookie => 3,
    }
}

fn assemble_request(
    path_template: &str,
    params: Vec<(ParameterIn, String, Option<String>)>,
    body: Option<Value>,
) -> GeneratedRequest {
    let mut path = path_template.to_owned();
    let mut query = Vec::new();
    let mut headers = Vec::new();
    let mut cookies = Vec::new();

    for (loc, name, val) in params {
        match loc {
            ParameterIn::Path => {
                let raw = val.unwrap_or_else(|| "x".to_owned());
                let safe = if raw.is_empty() {
                    "x".to_owned()
                } else {
                    percent_encode_component(&raw)
                };
                path = path.replace(&format!("{{{name}}}"), &safe);
            }
            ParameterIn::Query => {
                if let Some(v) = val {
                    query.push((name, v));
                }
            }
            ParameterIn::Header => {
                if let Some(v) = val {
                    headers.push((name, v));
                }
            }
            ParameterIn::Cookie => {
                if let Some(v) = val {
                    cookies.push((name, v));
                }
            }
        }
    }

    GeneratedRequest {
        path,
        query,
        headers,
        cookies,
        body,
    }
}
