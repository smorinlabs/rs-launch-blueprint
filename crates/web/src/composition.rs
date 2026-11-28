//! Web service composition helpers wiring [`AppState`], stores, and outbound HTTP trace
//! propagation (`R01`, `R69`, `R73`, `R74`, `R80`, `OV-18`).

use std::sync::Arc;

use rs_launch_blueprint::{
    ErasedProjectsService, HttpProjectsPort, ProjectsPort, Token, build_projects_service,
};

use crate::idempotency_store::{IdempotencyStore, InMemoryIdempotencyStore};
use crate::rate_limit::{InMemoryRateLimitStore, RateLimitStore};
use crate::routes::ops::{DiagnosticsRunner, Readiness};
use crate::server::AppState;
use crate::settings::WebSettings;

/// Build a bounded process-local [`IdempotencyStore`] sized from [`WebSettings`] (`R73`).
#[must_use]
pub fn in_memory_idempotency_store(settings: &WebSettings) -> Arc<dyn IdempotencyStore> {
    Arc::new(InMemoryIdempotencyStore::new(
        settings.idempotency_ttl,
        settings.idempotency_in_flight,
        settings.idempotency_max_entries.get(),
    ))
}

/// Build a bounded process-local [`RateLimitStore`] sized from [`WebSettings`] (`R74`).
#[must_use]
pub fn in_memory_rate_limit_store(settings: &WebSettings) -> Arc<dyn RateLimitStore> {
    Arc::new(InMemoryRateLimitStore::new(
        settings.rate_limit_max_entries.get(),
    ))
}

/// Build an outbound [`HttpProjectsPort`] wired with W3C Trace Context propagation when `otel` is
/// enabled (`R78`, `OV-18`).
#[must_use]
pub fn web_http_projects_port(base_url: impl Into<String>, token: Token) -> HttpProjectsPort {
    let port = HttpProjectsPort::new(base_url, token);
    #[cfg(feature = "otel")]
    let port = port.with_header_injector(Arc::new(crate::otel::outbound_trace_headers));
    port
}

/// Wire the production [`ErasedProjectsService`] for the web service backed by
/// [`web_http_projects_port`].
#[must_use]
pub fn web_production_service(base_url: impl Into<String>, token: Token) -> ErasedProjectsService {
    let port: Arc<dyn ProjectsPort> = Arc::new(web_http_projects_port(base_url, token));
    build_projects_service(port)
}

/// Assemble the web service [`AppState`] (`R01`, `R69`, `R73`, `R74`, `R80`).
#[must_use]
pub fn build_web_app_state(
    service: ErasedProjectsService,
    settings: WebSettings,
    diagnostics: DiagnosticsRunner,
) -> AppState {
    let idempotency = in_memory_idempotency_store(&settings);
    let rate_limit = in_memory_rate_limit_store(&settings);
    AppState::new(
        Arc::new(service),
        settings,
        idempotency,
        rate_limit,
        Readiness::new(),
        diagnostics,
    )
}
