// R80 probe workspace — the two probe handlers, as they would sit in
// `crates/web/src/routes/ops.rs` plus the `Readiness` latch that R69 revision
// 10's `shutdown_signal()` would flip, which would sit in `crates/web/src/lib.rs`.
//
// The 503 body here is a PLAIN JSON stand-in, not R70's RFC 9457 problem
// document: R70 is still being researched, so the probe measures the status code
// and the presence of the report, never the envelope's member names.

use std::path::PathBuf;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};

use axum::Json;
use axum::Router;
use axum::extract::State;
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::routing::get;
use probe_core::{Diagnostics, run_diagnostics};

pub const WEB_PKG_VERSION: &str = env!("CARGO_PKG_VERSION");

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
async fn healthz() -> Json<LivenessReport> {
    Json(LivenessReport {
        status: LiveStatus::Ok,
        version: probe_core::VERSION,
        os: std::env::consts::OS,
        arch: std::env::consts::ARCH,
    })
}

/// The pure half of readiness: status from the latch OR'd with the report.
/// Callable with no environment at all, which is what makes the 503 branch
/// testable on any machine.
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
    (status, Json(body)).into_response()
}

async fn readyz(State(state): State<AppState>) -> Response {
    let draining = !state.readiness.is_accepting();
    let config_path = state.config_path.clone();
    let has_credential = state.has_credential;
    // R05 revision 3's bridge: the synchronous core is reached through
    // spawn_blocking. `.expect` is the probe's shape, NOT the recommendation:
    // production maps a JoinError to 503.
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
