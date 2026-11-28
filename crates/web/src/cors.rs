//! Conditional browser CORS middleware (`R76`, `OV-08`).
//!
//! When the configured allowlist is empty, no `CorsLayer` is attached at all so non-browser APIs
//! emit zero `Vary` / `Access-Control-*` overhead and `OPTIONS` falls through to `405` with
//! `Allow`. When non-empty, `CorsLayer` attaches on the router outside rate limiting with an
//! explicit `Access-Control-Expose-Headers` list (`OV-08`: omitted on preflight responses).

use std::time::Duration;

use axum::Router;
use axum::http::{HeaderName, HeaderValue, header};
use tower_http::cors::{Any, CorsLayer};

use crate::idempotency::IDEMPOTENCY_REPLAYED_HEADER;
use crate::middleware::REQUEST_ID;
use crate::rate_limit::{RATE_LIMIT_HEADER, RATE_LIMIT_POLICY_HEADER, RETRY_AFTER_HEADER};

/// Default browser preflight cache duration (`600 s`, `R76`).
pub const DEFAULT_CORS_MAX_AGE: Duration = Duration::from_secs(600);

/// Explicit header list exposed to cross-origin browser clients (`R4.17`, `R76`, never `*`).
#[must_use]
pub fn default_exposed_headers() -> Vec<HeaderName> {
    vec![
        REQUEST_ID,
        header::ALLOW,
        RETRY_AFTER_HEADER,
        RATE_LIMIT_HEADER,
        RATE_LIMIT_POLICY_HEADER,
        IDEMPOTENCY_REPLAYED_HEADER,
        header::WWW_AUTHENTICATE,
    ]
}

/// Conditionally attach [`CorsLayer`] when `origins` is non-empty (`R76`, `OV-08`).
pub fn apply_cors(router: Router, origins: &[HeaderValue]) -> Router {
    if origins.is_empty() {
        return router;
    }

    let cors = CorsLayer::new()
        .allow_origin(origins.to_vec())
        .allow_methods(Any)
        .allow_headers(Any)
        .expose_headers(default_exposed_headers())
        .max_age(DEFAULT_CORS_MAX_AGE);

    router.layer(cors)
}
