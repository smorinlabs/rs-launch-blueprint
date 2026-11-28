//! Application state (`FromRef`), router assembly, graceful shutdown (`SIGTERM`/`SIGINT`), and
//! blocking server entrypoint (`R69`, `R74`, `R80`).

use std::future::{Future, IntoFuture as _};
use std::io;
use std::net::SocketAddr;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use axum::Router;
use axum::extract::FromRef;
use rs_launch_blueprint_core::{
    Diagnostics, ErasedProjectsService, Exit, IdempotencyStore, InMemoryIdempotencyStore,
};
use thiserror::Error;
use tokio::net::TcpListener;
use tokio::sync::Notify;

use crate::middleware::apply_middleware;
use crate::pagination::PaginationLimits;
use crate::problems::{method_not_allowed, not_found};
use crate::rate_limit::{InMemoryRateLimitStore, RateLimitStore};
use crate::routes;
use crate::routes::ops::{DiagnosticsRunner, Readiness};
use crate::settings::WebSettings;

/// Shared application state wired at the composition root and extracted via [`FromRef`] (`R69`).
#[derive(Clone)]
pub struct AppState {
    /// Shared synchronous projects domain service (`R01`, `R05`).
    pub service: Arc<ErasedProjectsService>,
    /// Validated web service settings (`R77`).
    pub settings: WebSettings,
    /// Pagination default and upper-bound limits (`R72`).
    pub pagination: PaginationLimits,
    /// Idempotency store port (`R73`).
    pub idempotency: Arc<dyn IdempotencyStore>,
    /// Rate-limit store port (`R74`).
    pub rate_limit: Arc<dyn RateLimitStore>,
    /// Atomic shutdown readiness latch (`R80`).
    pub readiness: Readiness,
    /// Shared synchronous diagnostics callback for `/readyz` (`R80`).
    pub diagnostics: DiagnosticsRunner,
}

impl std::fmt::Debug for AppState {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("AppState")
            .field("settings", &self.settings)
            .field("pagination", &self.pagination)
            .field("readiness", &self.readiness)
            .finish_non_exhaustive()
    }
}

impl AppState {
    /// Construct a fully configured [`AppState`] from explicit composition-root dependencies.
    #[must_use]
    pub fn new(
        service: Arc<ErasedProjectsService>,
        settings: WebSettings,
        idempotency: Arc<dyn IdempotencyStore>,
        rate_limit: Arc<dyn RateLimitStore>,
        readiness: Readiness,
        diagnostics: DiagnosticsRunner,
    ) -> Self {
        Self {
            service,
            settings,
            pagination: PaginationLimits::default(),
            idempotency,
            rate_limit,
            readiness,
            diagnostics,
        }
    }

    /// Construct a default [`AppState`] for hermetic `ServiceExt::oneshot` integration tests.
    #[must_use]
    pub fn for_testing(service: Arc<ErasedProjectsService>) -> Self {
        let settings = WebSettings::default();
        let idempotency: Arc<dyn IdempotencyStore> = Arc::new(InMemoryIdempotencyStore::new(
            settings.idempotency_ttl,
            settings.idempotency_in_flight,
            settings.idempotency_max_entries.get(),
        ));
        let rate_limit: Arc<dyn RateLimitStore> = Arc::new(InMemoryRateLimitStore::new(
            settings.rate_limit_max_entries.get(),
        ));
        let diagnostics: DiagnosticsRunner = Arc::new(|| Diagnostics { checks: Vec::new() });
        Self::new(
            service,
            settings,
            idempotency,
            rate_limit,
            Readiness::new(),
            diagnostics,
        )
    }

    /// Replace [`WebSettings`], rebuilding the default rate-limit store capacity to match.
    #[must_use]
    pub fn with_settings(mut self, settings: WebSettings) -> Self {
        self.rate_limit = Arc::new(InMemoryRateLimitStore::new(
            settings.rate_limit_max_entries.get(),
        ));
        self.settings = settings;
        self
    }

    /// Replace the [`PaginationLimits`].
    #[must_use]
    pub const fn with_pagination(mut self, pagination: PaginationLimits) -> Self {
        self.pagination = pagination;
        self
    }

    /// Replace the [`IdempotencyStore`].
    #[must_use]
    pub fn with_idempotency(mut self, store: Arc<dyn IdempotencyStore>) -> Self {
        self.idempotency = store;
        self
    }

    /// Replace the [`RateLimitStore`].
    #[must_use]
    pub fn with_rate_limit(mut self, store: Arc<dyn RateLimitStore>) -> Self {
        self.rate_limit = store;
        self
    }

    /// Replace the [`Readiness`] latch.
    #[must_use]
    pub fn with_readiness(mut self, readiness: Readiness) -> Self {
        self.readiness = readiness;
        self
    }

    /// Replace the [`DiagnosticsRunner`] invoked by `/readyz`.
    #[must_use]
    pub fn with_diagnostics(mut self, diagnostics: DiagnosticsRunner) -> Self {
        self.diagnostics = diagnostics;
        self
    }
}

impl FromRef<AppState> for Arc<ErasedProjectsService> {
    fn from_ref(state: &AppState) -> Self {
        Arc::clone(&state.service)
    }
}

impl FromRef<AppState> for WebSettings {
    fn from_ref(state: &AppState) -> Self {
        state.settings.clone()
    }
}

impl FromRef<AppState> for PaginationLimits {
    fn from_ref(state: &AppState) -> Self {
        state.pagination
    }
}

impl FromRef<AppState> for Arc<dyn IdempotencyStore> {
    fn from_ref(state: &AppState) -> Self {
        Arc::clone(&state.idempotency)
    }
}

impl FromRef<AppState> for Arc<dyn RateLimitStore> {
    fn from_ref(state: &AppState) -> Self {
        Arc::clone(&state.rate_limit)
    }
}

impl FromRef<AppState> for Readiness {
    fn from_ref(state: &AppState) -> Self {
        state.readiness.clone()
    }
}

impl FromRef<AppState> for DiagnosticsRunner {
    fn from_ref(state: &AppState) -> Self {
        Arc::clone(&state.diagnostics)
    }
}

/// Assemble the complete HTTP [`Router`] with versioned routes, root operational probes,
/// RFC 9457 fallbacks, and the fixed-order R75 middleware stack (`R69`, `R75`, `R80`).
pub fn build_router(state: AppState) -> Router {
    let projects_router = routes::projects::router(&state);
    let api_router = if state.settings.root_path.is_empty() {
        projects_router
    } else {
        Router::new().nest(&state.settings.root_path, projects_router)
    };

    let router = Router::new()
        .merge(routes::ops::router())
        .merge(api_router)
        .fallback(not_found)
        .method_not_allowed_fallback(method_not_allowed)
        .with_state(state.clone());

    apply_middleware(router, &state.settings, Arc::clone(&state.rate_limit))
}

/// OS termination signal observed by [`shutdown_signal`] (`R69`, `R67`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ShutdownSignal {
    /// `SIGINT` / Ctrl-C (`Exit::SigInt` = `130`).
    SigInt,
    /// `SIGTERM` (`Exit::SigTerm` = `143`).
    SigTerm,
}

impl ShutdownSignal {
    /// Map the termination signal to its POSIX [`Exit`] code (`R67`).
    #[must_use]
    pub const fn exit(self) -> Exit {
        match self {
            Self::SigInt => Exit::SigInt,
            Self::SigTerm => Exit::SigTerm,
        }
    }
}

/// Fatal server lifecycle errors returned by [`serve_until`] and [`run_server_blocking`] (`R69`).
#[derive(Debug, Error)]
pub enum ServeError {
    /// Binding the TCP listener failed.
    #[error("failed to bind HTTP listener on {addr}: {source}")]
    Bind {
        /// Requested socket address.
        addr: SocketAddr,
        /// Underlying OS error.
        #[source]
        source: io::Error,
    },
    /// Tokio runtime initialization failed.
    #[error("failed to initialize async web runtime: {0}")]
    Runtime(#[source] io::Error),
    /// Server encountered an I/O error while serving.
    #[error("HTTP server error: {0}")]
    Serve(#[source] io::Error),
    /// In-flight requests did not drain within the configured graceful shutdown budget.
    #[error("graceful shutdown timed out after {}ms", .0.as_millis())]
    GracefulShutdownTimedOut(Duration),
}

/// Wait for `SIGINT` (Ctrl-C) or Unix `SIGTERM` (`R69`).
pub async fn shutdown_signal() -> ShutdownSignal {
    let ctrl_c = async {
        let _ = tokio::signal::ctrl_c().await;
    };

    #[cfg(unix)]
    {
        match tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate()) {
            Ok(mut sigterm) => {
                tokio::select! {
                    () = ctrl_c => ShutdownSignal::SigInt,
                    _ = sigterm.recv() => ShutdownSignal::SigTerm,
                }
            }
            Err(_) => {
                ctrl_c.await;
                ShutdownSignal::SigInt
            }
        }
    }

    #[cfg(not(unix))]
    {
        ctrl_c.await;
        ShutdownSignal::SigInt
    }
}

/// Serve `app` on `listener` using `into_make_service_with_connect_info::<SocketAddr>()` until
/// `shutdown` resolves, flipping `readiness` immediately, pausing for `readiness_pause`, and
/// draining in-flight connections within `drain_budget` (`R69`, `R74`, `R80`).
pub async fn serve_until<F>(
    listener: TcpListener,
    app: Router,
    shutdown: F,
    readiness: Readiness,
    readiness_pause: Duration,
    drain_budget: Duration,
) -> Result<Option<ShutdownSignal>, ServeError>
where
    F: Future<Output = ShutdownSignal> + Send + 'static,
{
    let stop_accepting = Arc::new(Notify::new());
    let drain_started = Arc::new(Notify::new());
    let captured_signal: Arc<Mutex<Option<ShutdownSignal>>> = Arc::new(Mutex::new(None));

    let stop_tx = Arc::clone(&stop_accepting);
    let drain_tx = Arc::clone(&drain_started);
    let sig_slot = Arc::clone(&captured_signal);

    let signal_task = tokio::spawn(async move {
        let sig = shutdown.await;
        readiness.begin_draining();
        if let Ok(mut guard) = sig_slot.lock() {
            *guard = Some(sig);
        }
        if !readiness_pause.is_zero() {
            tokio::time::sleep(readiness_pause).await;
        }
        stop_tx.notify_one();
        drain_tx.notify_one();
    });

    let stop_rx = Arc::clone(&stop_accepting);
    let server = axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .with_graceful_shutdown(async move {
        stop_rx.notified().await;
    })
    .into_future();

    tokio::pin!(server);

    let result = tokio::select! {
        res = &mut server => {
            signal_task.abort();
            res.map_err(ServeError::Serve)?;
            let sig = captured_signal.lock().ok().and_then(|g| *g);
            Ok(sig)
        }
        () = drain_started.notified() => {
            tokio::select! {
                res = &mut server => {
                    res.map_err(ServeError::Serve)?;
                    let sig = captured_signal.lock().ok().and_then(|g| *g);
                    Ok(sig)
                }
                () = tokio::time::sleep(drain_budget) => {
                    Err(ServeError::GracefulShutdownTimedOut(drain_budget))
                }
            }
        }
    };

    result
}

/// Start the Tokio multi-threaded runtime inside `crates/web`, bind the configured socket, serve
/// until `SIGINT`/`SIGTERM`, and return the mapped POSIX [`Exit`] code (`R69`).
///
/// Keeping Tokio runtime construction here preserves root-crate isolation from `tokio`/`axum`.
pub fn run_server_blocking(state: AppState) -> Result<Exit, ServeError> {
    let runtime = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .map_err(ServeError::Runtime)?;

    runtime.block_on(async move {
        let addr = state.settings.bind_addr();
        let listener = TcpListener::bind(addr)
            .await
            .map_err(|source| ServeError::Bind { addr, source })?;
        let local_addr = listener.local_addr().unwrap_or(addr);
        let readiness = state.readiness.clone();
        let readiness_pause = state.settings.readiness_pause;
        let drain_budget = state.settings.drain_budget();
        let app = build_router(state);

        tracing::info!(addr = %local_addr, "web service listening");

        let sig = serve_until(
            listener,
            app,
            shutdown_signal(),
            readiness,
            readiness_pause,
            drain_budget,
        )
        .await?;

        Ok(sig.map_or(Exit::Success, ShutdownSignal::exit))
    })
}
