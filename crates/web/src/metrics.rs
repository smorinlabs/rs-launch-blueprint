//! Prometheus RED metrics instrumentation and `/metrics` text exposition endpoint (`R79` rev 6,
//! `OV-07`).
//!
//! Compiled only when the optional `metrics` feature (`metrics = ["web", ...]`) is enabled.
//!
//! - Uses `metrics 0.24.6` + `metrics-exporter-prometheus 0.18.3` with `default-features = false`
//!   so no second HTTP listener or TLS stack is pulled in.
//! - Uses OpenTelemetry HTTP semantic convention names (`http_server_request_duration_seconds`
//!   histogram + label-free `http_server_unmatched_requests_total` counter).
//! - Excludes `/metrics`, `/healthz`, `/readyz`, and `/openapi.json` structurally by applying
//!   `track` only to the business router before merging operational routes.
//! - Conforms to REST R7.1/R7.3 (`Cache-Control: private, no-cache`), R13.3 (`?stream` -> `400`),
//!   R11.7 (`request-id` via outer middleware), and documents `OV-07(a)` (unconditional
//!   `text/plain; version=0.0.4; charset=utf-8` regardless of `Accept`) and `OV-07(b)`
//!   (unauthenticated `/metrics` bound to loopback by default).

use std::sync::OnceLock;
use std::time::{Duration, Instant};

use axum::Router;
use axum::extract::{MatchedPath, RawQuery, Request, State};
use axum::http::{HeaderValue, StatusCode, Uri, header};
use axum::middleware::Next;
use axum::response::{IntoResponse, Response};
use axum::routing::get;
use metrics_exporter_prometheus::{Matcher, PrometheusBuilder, PrometheusHandle};
use rs_launch_blueprint_core::ErrorCode;

use crate::problems::WebError;
use crate::settings::WebSettings;

/// Prometheus histogram carrying Rate (`_count`), Errors (status label), and Duration (`_bucket`)
/// under OpenTelemetry HTTP semantic conventions (`R79`).
pub const HTTP_REQUEST_DURATION_SECONDS: &str = "http_server_request_duration_seconds";

/// Label-free Prometheus counter tracking unmatched 404 requests without minting unbounded URI
/// labels (`R79` AC6).
pub const HTTP_UNMATCHED_REQUESTS_TOTAL: &str = "http_server_unmatched_requests_total";

/// Explicit histogram bucket boundaries in seconds (`R79`).
pub const DURATION_BUCKETS: &[f64] = &[
    0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 7.5, 10.0,
];

/// Prometheus text exposition format 0.0.4 media type served unconditionally (`R79`, `OV-07(a)`).
pub const PROMETHEUS_CONTENT_TYPE: &str = "text/plain; version=0.0.4; charset=utf-8";

const CACHE_CONTROL: &str = "private, no-cache";
const UPKEEP_INTERVAL: Duration = Duration::from_secs(5);

static HANDLE: OnceLock<PrometheusHandle> = OnceLock::new();

/// Install and return the process-wide [`PrometheusHandle`] idempotently (`R79`).
///
/// Uses [`OnceLock`] so repeated router construction across integration tests never panics.
#[must_use]
pub fn metrics_recorder() -> &'static PrometheusHandle {
    HANDLE.get_or_init(|| {
        let handle = PrometheusBuilder::new()
            .set_buckets_for_metric(
                Matcher::Full(HTTP_REQUEST_DURATION_SECONDS.to_owned()),
                DURATION_BUCKETS,
            )
            .expect("DURATION_BUCKETS is non-empty")
            .install_recorder()
            .expect("no competing global metrics recorder is installed");
        metrics::describe_histogram!(
            HTTP_REQUEST_DURATION_SECONDS,
            metrics::Unit::Seconds,
            "Duration of HTTP server requests."
        );
        metrics::describe_counter!(
            HTTP_UNMATCHED_REQUESTS_TOTAL,
            "HTTP requests that matched no route template."
        );
        handle
    })
}

/// Periodic upkeep task draining pending histogram samples between scrapes (`R79` 5-second ticker).
pub async fn run_metrics_upkeep(handle: &'static PrometheusHandle) {
    let mut ticker = tokio::time::interval(UPKEEP_INTERVAL);
    loop {
        ticker.tick().await;
        handle.run_upkeep();
    }
}

/// Route-scoped middleware recording bounded-cardinality RED metrics using Axum's [`MatchedPath`]
/// template (never falling back to raw request URIs, `R79`).
pub(crate) async fn track(req: Request, next: Next) -> Response {
    let start = Instant::now();
    let method = req.method().as_str().to_owned();
    let route = req
        .extensions()
        .get::<MatchedPath>()
        .map(|p| p.as_str().to_owned());

    let response = next.run(req).await;

    if let Some(route) = route {
        let status = response.status().as_u16().to_string();
        metrics::histogram!(
            HTTP_REQUEST_DURATION_SECONDS,
            "http_request_method" => method,
            "http_route" => route,
            "http_response_status_code" => status,
        )
        .record(start.elapsed().as_secs_f64());
    }
    response
}

/// Increment the label-free unmatched-request counter from the router `404` fallback (`R79`).
///
/// No-op if no global recorder was installed (e.g. `RSLBP_WEB_METRICS_ENABLED=false`).
pub fn count_unmatched() {
    metrics::counter!(HTTP_UNMATCHED_REQUESTS_TOTAL).increment(1);
}

/// REST R13.3: `stream` with any value or none is rejected with `400` on non-streaming endpoints.
fn asks_to_stream(query: Option<&str>) -> bool {
    query.is_some_and(|q| {
        q.split('&')
            .any(|pair| pair == "stream" || pair.starts_with("stream="))
    })
}

async fn scrape(
    State(settings): State<WebSettings>,
    RawQuery(query): RawQuery,
    uri: Uri,
) -> Response {
    if asks_to_stream(query.as_deref()) {
        return WebError::framework(
            StatusCode::BAD_REQUEST,
            "streaming_not_supported",
            ErrorCode::Usage,
            "The 'stream' query parameter is not supported on this endpoint.",
            &settings.problem_base_uri,
            Some(uri.path()),
        )
        .with_header(
            header::CACHE_CONTROL,
            HeaderValue::from_static(CACHE_CONTROL),
        )
        .into_response();
    }

    (
        [
            (header::CACHE_CONTROL, CACHE_CONTROL),
            (header::CONTENT_TYPE, PROMETHEUS_CONTENT_TYPE),
        ],
        metrics_recorder().render(),
    )
        .into_response()
}

/// Build the unmeasured, OpenAPI-excluded `/metrics` scrape router (`R79`).
pub(crate) fn metrics_router(settings: WebSettings) -> Router {
    Router::new()
        .route("/metrics", get(scrape))
        .with_state(settings)
}
