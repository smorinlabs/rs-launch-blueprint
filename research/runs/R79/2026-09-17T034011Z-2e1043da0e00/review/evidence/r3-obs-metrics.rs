// src/web/obs/metrics.rs -- compiled only with the `metrics` feature (R69 revision 9 tree).
use axum::{
    Router,
    extract::{MatchedPath, RawQuery, Request},
    http::{StatusCode, header},
    middleware::{self, Next},
    response::{IntoResponse, Response},
    routing::get,
};
use metrics_exporter_prometheus::{Matcher, PrometheusBuilder, PrometheusHandle};
use std::{
    sync::OnceLock,
    time::{Duration, Instant},
};

pub const DURATION: &str = "http_server_request_duration_seconds";
pub const UNMATCHED: &str = "http_server_unmatched_requests_total";
pub const BUCKETS: &[f64] = &[
    0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 7.5, 10.0,
];
// R7.1 (:1259) and R7.3 tier 1 (:1281): a mutable resource states its caching posture.
const CACHE_CONTROL: &str = "private, no-cache";
// OV-07(a): the Prometheus text exposition format, whatever the Accept header says.
const EXPOSITION: &str = "text/plain; version=0.0.4; charset=utf-8";

static HANDLE: OnceLock<PrometheusHandle> = OnceLock::new();

pub fn recorder() -> &'static PrometheusHandle {
    HANDLE.get_or_init(|| {
        let handle = PrometheusBuilder::new()
            .set_buckets_for_metric(Matcher::Full(DURATION.to_string()), BUCKETS)
            .expect("bucket list is non-empty")
            .install_recorder()
            .expect("no other global recorder is installed");
        metrics::describe_histogram!(
            DURATION,
            metrics::Unit::Seconds,
            "Duration of HTTP server requests."
        );
        metrics::describe_counter!(UNMATCHED, "HTTP requests that matched no route template.");
        handle
    })
}

pub async fn run_upkeep(handle: &'static PrometheusHandle) {
    let mut ticker = tokio::time::interval(Duration::from_secs(5));
    loop {
        ticker.tick().await;
        handle.run_upkeep();
    }
}

async fn track(req: Request, next: Next) -> Response {
    let start = Instant::now();
    let method = req.method().as_str().to_owned();
    let route = req
        .extensions()
        .get::<MatchedPath>()
        .map(|p| p.as_str().to_owned());
    let response = next.run(req).await;
    let status = response.status().as_u16().to_string();
    if let Some(route) = route {
        metrics::histogram!(
            DURATION,
            "http_request_method" => method,
            "http_route" => route,
            "http_response_status_code" => status,
        )
        .record(start.elapsed().as_secs_f64());
    }
    response
}

pub fn count_unmatched() {
    metrics::counter!(UNMATCHED).increment(1);
}

// R13.3 (:1935): `stream` with any value, or none, is a 400 on an endpoint that does not stream.
fn asks_to_stream(query: Option<&str>) -> bool {
    query.is_some_and(|q| {
        q.split('&')
            .any(|pair| pair == "stream" || pair.starts_with("stream="))
    })
}

async fn scrape(RawQuery(query): RawQuery) -> Response {
    if asks_to_stream(query.as_deref()) {
        return (StatusCode::BAD_REQUEST, [(header::CACHE_CONTROL, CACHE_CONTROL)]).into_response();
    }
    (
        [
            (header::CACHE_CONTROL, CACHE_CONTROL),
            (header::CONTENT_TYPE, EXPOSITION),
        ],
        recorder().render(),
    )
        .into_response()
}

pub fn instrument(business: Router) -> Router {
    recorder();
    business
        .route_layer(middleware::from_fn(track))
        .merge(Router::new().route("/metrics", get(scrape)))
}
