//! Operational liveness (`/healthz`) and readiness (`/readyz`) probe endpoints (`R80`, `OV-05`).
//!
//! - `/healthz` is stateless, takes no `State`, performs zero I/O, and stays `200 OK` during drain.
//! - `/readyz` checks the atomic [`Readiness`] shutdown latch first, then executes the shared
//!   synchronous `crates/core` diagnostics runner via `tokio::task::spawn_blocking`, redacting
//!   paths/internals before serializing (`R5.17`) and returning RFC 9457 `503` with `diagnostics`
//!   when draining or when any check reports `CheckStatus::Error`.

use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};

use axum::Json;
use axum::extract::State;
use axum::http::{HeaderValue, StatusCode, header};
use axum::response::{IntoResponse, Response};
use rs_launch_blueprint_core::{Diagnostics, VERSION, draining_diagnostics};
use serde::Serialize;
use utoipa::ToSchema;
use utoipa_axum::router::OpenApiRouter;
use utoipa_axum::routes;

use crate::openapi::{DiagnosticsSchema, Problem};
use crate::problems::{PROBLEM_CONTENT_TYPE, WebError, join_error_to_web_error};
use crate::server::AppState;
use crate::settings::WebSettings;

/// Atomic shutdown latch flipped to draining before graceful server drain begins (`R80`, `R69`).
#[derive(Debug, Clone)]
pub struct Readiness(Arc<AtomicBool>);

impl Default for Readiness {
    fn default() -> Self {
        Self::new()
    }
}

impl Readiness {
    /// Create a [`Readiness`] latch initialized to ready (`true`).
    #[must_use]
    pub fn new() -> Self {
        Self(Arc::new(AtomicBool::new(true)))
    }

    /// Return `true` while the service is accepting traffic and not draining.
    #[must_use]
    pub fn is_ready(&self) -> bool {
        self.0.load(Ordering::Acquire)
    }

    /// Flip the readiness latch to draining so `/readyz` immediately returns `503`.
    pub fn begin_draining(&self) {
        self.0.store(false, Ordering::Release);
    }
}

/// Shared synchronous diagnostics provider invoked on Tokio's blocking pool by `/readyz` (`R80`).
pub type DiagnosticsRunner = Arc<dyn Fn() -> Diagnostics + Send + Sync>;

/// Static liveness status token emitted by `/healthz` (`R80`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, ToSchema)]
#[serde(rename_all = "lowercase")]
pub enum LiveStatus {
    /// Process event loop is alive.
    Ok,
}

/// Exact four-field byte-stable payload emitted by `GET /healthz` (`R80` AC1, AC2).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, ToSchema)]
pub struct LivenessReport {
    /// Always `"ok"`.
    pub status: LiveStatus,
    /// Package SemVer version from `crates/core`.
    pub version: &'static str,
    /// Target operating system (`std::env::consts::OS`).
    pub os: &'static str,
    /// Target CPU architecture (`std::env::consts::ARCH`).
    pub arch: &'static str,
}

/// Compile-time constant liveness payload so repeated `/healthz` calls are byte-identical (`R80`).
pub const LIVENESS_REPORT: LivenessReport = LivenessReport {
    status: LiveStatus::Ok,
    version: VERSION,
    os: std::env::consts::OS,
    arch: std::env::consts::ARCH,
};

#[utoipa::path(
    get,
    path = "/healthz",
    tag = "ops",
    operation_id = "ops-healthz",
    responses(
        (status = 200, description = "Process liveness report", body = LivenessReport)
    )
)]
async fn healthz() -> Response {
    (
        StatusCode::OK,
        [(header::CACHE_CONTROL, HeaderValue::from_static("no-cache"))],
        Json(LIVENESS_REPORT),
    )
        .into_response()
}

#[utoipa::path(
    get,
    path = "/readyz",
    tag = "ops",
    operation_id = "ops-readyz",
    responses(
        (status = 200, description = "Service readiness diagnostics", body = DiagnosticsSchema),
        (
            status = 503,
            description = "Service draining or readiness check failed",
            body = Problem,
            content_type = PROBLEM_CONTENT_TYPE
        )
    )
)]
async fn readyz(
    State(readiness): State<Readiness>,
    State(diagnostics): State<DiagnosticsRunner>,
    State(settings): State<WebSettings>,
) -> Response {
    if !readiness.is_ready() {
        let redacted = draining_diagnostics().redacted_for_http();
        return WebError::service_unavailable(
            &settings.problem_base_uri,
            "/readyz",
            "Service is shutting down and no longer accepting new traffic.",
        )
        .with_diagnostics(redacted)
        .with_header(header::CACHE_CONTROL, HeaderValue::from_static("no-cache"))
        .into_response();
    }

    let runner = Arc::clone(&diagnostics);
    let raw_diag = match tokio::task::spawn_blocking(move || runner()).await {
        Ok(diag) => diag,
        Err(join_err) => {
            return join_error_to_web_error(join_err, &settings.problem_base_uri, "/readyz")
                .into_response();
        }
    };

    let redacted = raw_diag.redacted_for_http();
    if redacted.has_error() {
        return WebError::service_unavailable(
            &settings.problem_base_uri,
            "/readyz",
            "One or more readiness checks reported an error.",
        )
        .with_diagnostics(redacted)
        .with_header(header::CACHE_CONTROL, HeaderValue::from_static("no-cache"))
        .into_response();
    }

    (
        StatusCode::OK,
        [(header::CACHE_CONTROL, HeaderValue::from_static("no-cache"))],
        Json(redacted),
    )
        .into_response()
}

pub(crate) fn router() -> OpenApiRouter<AppState> {
    OpenApiRouter::new()
        .routes(routes!(healthz))
        .routes(routes!(readyz))
}
