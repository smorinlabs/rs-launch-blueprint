// R80 revision 2 — the probe handlers AFTER the move that rule R7.1 of the org
// REST API Design Standard v2.0.0 forces: every response MUST carry an explicit
// Cache-Control header. Revision 1's probe source at ../probe/web-src/lib.rs is
// unchanged and still the artifact its own log was produced from; this file is
// the r2 variant, and the two differ only in what this comment names.
//
// Differences from ../probe/web-src/lib.rs, and nothing else:
//   1. both handlers emit `Cache-Control: no-cache` (R7.1; R7.3 tier 1, with
//      R7.2's genuinely-public exception carrying the absence of `private`);
//   2. a `content_type_of`/`cache_control_of` test seam is not needed — the
//      tests read the real response headers.
//
// The 503 body is still a PLAIN JSON stand-in, not R70's problem document:
// R70 is still in flight, so this probe measures the status code, the headers
// and the presence of the report, never the envelope's member names.

use std::path::PathBuf;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};

use axum::Json;
use axum::Router;
use axum::extract::State;
use axum::http::StatusCode;
use axum::http::header::{CACHE_CONTROL, HeaderValue};
use axum::response::{IntoResponse, Response};
use axum::routing::get;
use probe_core::{Diagnostics, run_diagnostics};

pub const WEB_PKG_VERSION: &str = env!("CARGO_PKG_VERSION");

/// The single place the probe surface's caching posture is decided.
/// `no-cache` (not `no-store`): R7.3 names blanket `no-store` an anti-pattern
/// reserved for genuinely sensitive payloads, and a probe body is not one.
const PROBE_CACHE_CONTROL: &str = "no-cache";

fn with_probe_headers(mut response: Response) -> Response {
    response.headers_mut().insert(
        CACHE_CONTROL,
        HeaderValue::from_static(PROBE_CACHE_CONTROL),
    );
    response
}

#[derive(Debug, Clone)]
pub struct Readiness(Arc<AtomicBool>);

impl Readiness {
    pub fn accepting() -> Self {
        Self(Arc::new(AtomicBool::new(true)))
    }
    pub fn is_accepting(&self) -> bool {
        self.0.load(Ordering::Acquire)
    }
    pub fn begin_draining(&self) {
        self.0.store(false, Ordering::Release);
    }
}

#[derive(Debug, Clone)]
pub struct AppState {
    pub readiness: Readiness,
    pub config_path: PathBuf,
    pub has_credential: bool,
}

#[derive(Debug, Clone, Copy, serde::Serialize)]
#[serde(rename_all = "lowercase")]
pub enum LiveStatus {
    Ok,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct LivenessReport {
    pub status: LiveStatus,
    pub version: &'static str,
    pub os: &'static str,
    pub arch: &'static str,
}

/// Liveness. Declines `State`, so it can reach no dependency by construction.
async fn healthz() -> Response {
    with_probe_headers(
        Json(LivenessReport {
            status: LiveStatus::Ok,
            version: probe_core::VERSION,
            os: std::env::consts::OS,
            arch: std::env::consts::ARCH,
        })
        .into_response(),
    )
}

/// The pure half of readiness: status from the latch OR'd with the report.
pub fn readiness_response(draining: bool, report: Diagnostics) -> Response {
    let ready = !draining && !report.has_error();
    let status = if ready {
        StatusCode::OK
    } else {
        StatusCode::SERVICE_UNAVAILABLE
    };
    let body = serde_json::json!({
        "status": if ready { "ok" } else { "unavailable" },
        "diagnostics": report,
    });
    with_probe_headers((status, Json(body)).into_response())
}

async fn readyz(State(state): State<AppState>) -> Response {
    let draining = !state.readiness.is_accepting();
    let config_path = state.config_path.clone();
    let has_credential = state.has_credential;
    let report = tokio::task::spawn_blocking(move || run_diagnostics(&config_path, has_credential))
        .await
        .expect("diagnostics task panicked");
    readiness_response(draining, report)
}

pub fn ops_router() -> Router<AppState> {
    Router::new()
        .route("/healthz", get(healthz))
        .route("/readyz", get(readyz))
}

pub fn build_router(state: AppState) -> Router {
    Router::new().merge(ops_router()).with_state(state)
}
