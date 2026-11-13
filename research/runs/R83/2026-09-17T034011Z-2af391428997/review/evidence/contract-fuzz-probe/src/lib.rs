//! R83 synthesis probe — the service under test, NOT template code.
//!
//! Three routes: the served OpenAPI 3.1 document, a documented create operation and a
//! documented read operation. The create handler carries a deliberately seeded defect,
//! enabled by the environment variable `R83_SEED_DEFECT`, so that the same build can be
//! observed both with a 5xx reachable from a documented-valid input and without one.

use axum::{
    Json, Router,
    extract::Path,
    http::{StatusCode, header},
    response::IntoResponse,
    routing::{get, post},
};
use serde_json::{Value, json};

/// The OpenAPI 3.1 document this service serves, and the only description of its
/// operations the fuzz harness is allowed to read.
pub const OPENAPI_DOC: &str = include_str!("openapi.json");

/// Environment variable that arms the seeded 5xx defect.
pub const SEED_DEFECT_ENV: &str = "R83_SEED_DEFECT";

/// Arms a seeded violation of REST API Design Standard R4.3 (bare array at the JSON top
/// level) that is NOT a 5xx, so the reach of the three oracles can be told apart.
pub const SEED_ARRAY_BODY_ENV: &str = "R83_SEED_ARRAY_BODY";

/// Arms a seeded violation of REST API Design Standard R5.2 (unregistered status code)
/// that is neither a 5xx nor a body-shape defect.
pub const SEED_UNREGISTERED_STATUS_ENV: &str = "R83_SEED_UNREGISTERED_STATUS";

/// Builds the router. Mirrors the shape of a `build_router()` the template would own.
pub fn build_router() -> Router {
    Router::new()
        .route("/openapi.json", get(openapi_document))
        .route("/projects", post(create_project))
        .route("/projects/{id}", get(read_project))
}

async fn openapi_document() -> impl IntoResponse {
    (
        [(header::CONTENT_TYPE, "application/json")],
        OPENAPI_DOC,
    )
}

async fn create_project(Json(body): Json<Value>) -> impl IntoResponse {
    let name = body.get("name").and_then(Value::as_str).unwrap_or_default();
    let limit = body.get("limit").and_then(Value::as_i64).unwrap_or(-1);

    if name.is_empty() || name.len() > 8 || !(0..=100).contains(&limit) {
        return (StatusCode::BAD_REQUEST, Json(json!({"error": "invalid"})));
    }

    // Seeded defect. `limit = 0` is documented valid (`"minimum": 0`), so a harness that
    // generates from the document must be able to reach it. With the variable unset the
    // same input is handled correctly and the operation returns 201.
    if limit == 0 && std::env::var_os(SEED_DEFECT_ENV).is_some() {
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "seeded defect: limit = 0"})),
        );
    }

    if std::env::var_os(SEED_ARRAY_BODY_ENV).is_some() {
        // A 201 with a bare array at the JSON top level: no server error, no unregistered
        // status, and still nonconformant under R4.3.
        return (StatusCode::CREATED, Json(json!([{"name": name}])));
    }

    if std::env::var_os(SEED_UNREGISTERED_STATUS_ENV).is_some() {
        // 299 is not in the IANA HTTP status registry: no server error, object body, and
        // still nonconformant under R5.2.
        return (
            StatusCode::from_u16(299).unwrap(),
            Json(json!({"name": name, "limit": limit})),
        );
    }

    (StatusCode::CREATED, Json(json!({"name": name, "limit": limit})))
}

async fn read_project(Path(id): Path<String>) -> impl IntoResponse {
    if id.is_empty() || id.len() > 6 {
        return (StatusCode::BAD_REQUEST, Json(json!({"error": "invalid"})));
    }
    (StatusCode::OK, Json(json!({"id": id})))
}
