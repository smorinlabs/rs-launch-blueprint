//! Optional Axum HTTP web service binary crate and middleware (`R69`–`R78`, `R80`, `OV-18`).
//!
//! Marked `publish = false`: this crate owns the deployment HTTP server (`rslbp-serve`),
//! idempotency store, OpenTelemetry tracing pipeline, and Axum middleware stack, depending
//! strictly on the standalone library crate `rs-launch-blueprint` and never on `crates/cli`.
//!
//! All internal modules are private and re-exported through this curated crate root (`R04`).
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

mod composition;
mod cors;
mod idempotency;
mod idempotency_store;
#[cfg(feature = "metrics")]
mod metrics;
mod middleware;
mod openapi;
#[cfg(feature = "otel")]
mod otel;
mod pagination;
mod problems;
mod rate_limit;
mod routes;
mod server;
mod settings;
mod telemetry;

pub use composition::{
    build_web_app_state, in_memory_idempotency_store, in_memory_rate_limit_store,
    web_http_projects_port, web_production_service,
};
pub use cors::{DEFAULT_CORS_MAX_AGE, apply_cors, default_exposed_headers};
pub use idempotency::{
    IDEMPOTENCY_KEY_HEADER, IDEMPOTENCY_REPLAYED_HEADER, IDEMPOTENCY_REPLAYED_VALUE,
    IdempotencyConfig, MAX_IDEMPOTENCY_KEY_BYTES, StoreDispatch, apply_idempotency,
    compute_fingerprint, idempotency_middleware,
};
pub use idempotency_store::{
    AlwaysFreshIdempotencyStore, CachedResponse, ClaimToken, Clock, CompletedOutcome,
    DEFAULT_IDEMPOTENCY_IN_FLIGHT, DEFAULT_IDEMPOTENCY_MAX_ENTRIES, DEFAULT_IDEMPOTENCY_TTL,
    FakeClock, IdempotencyBegin, IdempotencyCacheKey, IdempotencyStore, InMemoryIdempotencyStore,
    PayloadFingerprint, SystemClock,
};
#[cfg(feature = "metrics")]
pub use metrics::{
    DURATION_BUCKETS, HTTP_REQUEST_DURATION_SECONDS, HTTP_UNMATCHED_REQUESTS_TOTAL,
    PROMETHEUS_CONTENT_TYPE, count_unmatched, metrics_recorder, run_metrics_upkeep,
};
pub use middleware::{
    ACCESS_LOG_EXCLUDED_ROUTES, DEPRECATION_HEADER, InboundTraceparent, REQUEST_ID, SUNSET_HEADER,
    TRACEPARENT, access_log, apply_middleware, deprecation_headers, echo_request_id,
    inbound_traceparent, install_panic_hook, propagate_traceparent,
};
pub use openapi::{
    API_DOCUMENT_VERSION, CheckSchema, CheckStatusSchema, CreateProjectInputSchema,
    DiagnosticsSchema, OPENAPI_PATH, Problem, ProjectListResponseSchema, ProjectSchema,
    declare_problem_responses, serialize_openapi,
};
#[cfg(feature = "otel")]
pub use otel::{
    OtelConfig, OtelGuard, OtelInit, OtelLayer, RedactingSpanExporter,
    build_otel_layer_with_exporter, init_otel_from_config, inject_trace_context,
    otel_feedback_filter, outbound_trace_headers,
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
    AppState, Exit, ServeError, ShutdownSignal, build_router, build_router_and_openapi,
    openapi_document, openapi_json, run_server_blocking, serve_until, shutdown_signal,
};
pub use settings::{
    DEFAULT_GRACEFUL_SHUTDOWN_SECONDS, DEFAULT_MAX_BODY_BYTES, DEFAULT_PROBLEM_BASE_URI,
    DEFAULT_REQUEST_TIMEOUT_SECONDS, SettingsError, WEB_ENV_PREFIX, WEB_ENV_VARS, WebSettings,
};
pub use telemetry::{
    REDACTED, SENSITIVE_KEY_PARTS, ServiceHumanFields, ServiceJsonEvent, ServiceJsonFields,
    ServiceLogFormat, ServiceTelemetryHandles, ServiceTelemetryInit, ServiceTelemetryProfile,
    build_service_subscriber, init_service_telemetry, is_sensitive_key, level_to_env_filter,
    level_to_filter, warn_if_otlp_env_ignored,
};
#[cfg(feature = "otel")]
pub use telemetry::{build_service_subscriber_with_otel, init_service_telemetry_with_otel};
