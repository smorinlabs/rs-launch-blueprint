//! Optional Axum HTTP web service core and middleware (`R69`–`R77`, `R80`).
//!
//! All internal modules are private and re-exported through this curated crate root (`R04`).
//! Built only when the workspace `web` feature is enabled.
//!
//! Internal modules cannot be deep-imported by external consumers (`R04`):
//!
//! ```compile_fail,E0603
//! use rs_launch_blueprint_web::settings::WebSettings;
//! ```
//!
//! ```compile_fail,E0603
//! use rs_launch_blueprint_web::problems::WebError;
//! ```

mod cors;
mod idempotency;
#[cfg(feature = "metrics")]
mod metrics;
mod middleware;
mod openapi;
mod pagination;
mod problems;
mod rate_limit;
mod routes;
mod server;
mod settings;

pub use cors::{DEFAULT_CORS_MAX_AGE, apply_cors, default_exposed_headers};
pub use idempotency::{
    IDEMPOTENCY_KEY_HEADER, IDEMPOTENCY_REPLAYED_HEADER, IDEMPOTENCY_REPLAYED_VALUE,
    IdempotencyConfig, MAX_IDEMPOTENCY_KEY_BYTES, StoreDispatch, apply_idempotency,
    compute_fingerprint, idempotency_middleware,
};
#[cfg(feature = "metrics")]
pub use metrics::{
    DURATION_BUCKETS, HTTP_REQUEST_DURATION_SECONDS, HTTP_UNMATCHED_REQUESTS_TOTAL,
    PROMETHEUS_CONTENT_TYPE, count_unmatched, metrics_recorder, run_metrics_upkeep,
};
pub use middleware::{
    ACCESS_LOG_EXCLUDED_ROUTES, InboundTraceparent, REQUEST_ID, TRACEPARENT, access_log,
    apply_middleware, echo_request_id, inbound_traceparent, install_panic_hook,
    propagate_traceparent,
};
pub use openapi::{
    API_DOCUMENT_VERSION, CheckSchema, CheckStatusSchema, CreateProjectInputSchema,
    DiagnosticsSchema, OPENAPI_PATH, Problem, ProjectListResponseSchema, ProjectSchema,
    declare_problem_responses, serialize_openapi,
};
pub use pagination::{
    CursorError, DEFAULT_PAGE_LIMIT, Limit, ListResponse, MAX_PAGE_LIMIT, PageRequest, Pagination,
    PaginationLimits, decode_cursor, encode_cursor, paginate_slice,
};
pub use problems::{
    FieldError, NOT_REQUEST_REACHABLE, PROBLEM_CONTENT_TYPE, ProblemCatalogEntry, ProblemExt,
    ProblemJson, ProblemPath, ProblemQuery, ProblemSource, WebError, detail_is_public, http_code,
    http_status, join_error_to_web_error, method_not_allowed, not_found, problem_catalog,
    problem_type,
};
pub use rate_limit::{
    DEFAULT_RATE_LIMIT_BURST, DEFAULT_RATE_LIMIT_MAX_ENTRIES, DEFAULT_RATE_LIMIT_PER_IP,
    InMemoryRateLimitStore, PolicyParseError, RATE_LIMIT_HEADER, RATE_LIMIT_POLICY_HEADER,
    RETRY_AFTER_HEADER, RateLimitDecision, RateLimitKey, RateLimitPolicy, RateLimitStore,
    install_rate_limit, install_rate_limit_with_base, retry_after_seconds,
};
pub use routes::ops::{DiagnosticsRunner, LIVENESS_REPORT, LiveStatus, LivenessReport, Readiness};
pub use server::{
    AppState, ServeError, ShutdownSignal, build_router, build_router_and_openapi, openapi_document,
    openapi_json, run_server_blocking, serve_until, shutdown_signal,
};
pub use settings::{
    DEFAULT_GRACEFUL_SHUTDOWN_SECONDS, DEFAULT_MAX_BODY_BYTES, DEFAULT_PROBLEM_BASE_URI,
    DEFAULT_REQUEST_TIMEOUT_SECONDS, SettingsError, WEB_ENV_PREFIX, WEB_ENV_VARS, WebSettings,
};
