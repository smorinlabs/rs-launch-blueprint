//! Fixed-order `tower-http` middleware stack (`R75`).
//!
//! Enforces the exact outermost-to-innermost composition:
//! - **L1**: `SetRequestIdLayer` (`request-id` UUIDv4 generation / preservation)
//! - **L2**: Security response headers (`if_not_present`, handler-set wins)
//! - **L3**: `echo_request_id` (copies live `request-id` onto every response)
//! - **L3b**: `propagate_traceparent` (opaque extension + task-local, never echoed)
//! - **L5**: `SetSensitiveRequestHeadersLayer` + structured `access_log` (excluding matched probe routes)
//! - **L6**: `CatchPanicLayer` (redacted RFC 9457 `500`, inside `access_log` & `echo_request_id`)
//! - **L7**: Conditional `CorsLayer` (outside rate limiting so cross-origin `429` carries ACAO)
//! - **L8**: Per-IP GCRA rate limiting
//! - **L9**: `TimeoutLayer` + `RequestBodyLimitLayer` normalized to RFC 9457 `408`/`413`

use std::any::Any;
use std::sync::Arc;
use std::time::Instant;

use axum::Router;
use axum::extract::{MatchedPath, Request, State};
use axum::http::header::{self, HeaderName, HeaderValue};
use axum::http::{Response as HttpResponse, StatusCode};
use axum::middleware::{self, Next};
use axum::response::{IntoResponse, Response};
use rs_launch_blueprint_core::ErrorCode;
use tower_http::catch_panic::{CatchPanicLayer, ResponseForPanic};
use tower_http::limit::RequestBodyLimitLayer;
use tower_http::request_id::{MakeRequestUuid, SetRequestIdLayer};
use tower_http::sensitive_headers::SetSensitiveRequestHeadersLayer;
use tower_http::set_header::SetResponseHeaderLayer;
use tower_http::timeout::TimeoutLayer;

use crate::cors::apply_cors;
use crate::problems::{PROBLEM_CONTENT_TYPE, WebError};
use crate::rate_limit::{RateLimitStore, install_rate_limit_with_base};
use crate::settings::WebSettings;

/// Request correlation ID header name (`R75`).
pub const REQUEST_ID: HeaderName = HeaderName::from_static("request-id");

/// W3C Trace Context inbound header name (`R75` L3b).
pub const TRACEPARENT: HeaderName = HeaderName::from_static("traceparent");

/// Matched route templates excluded from routine access logs (`R75` F320).
///
/// Unmatched paths such as `/healthz/` produce no `MatchedPath` and are therefore logged.
pub const ACCESS_LOG_EXCLUDED_ROUTES: &[&str] = &["/healthz", "/readyz", "/metrics"];

/// Opaque inbound `traceparent` value carried via request extensions and task-local storage
/// (`R75` L3b).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct InboundTraceparent(pub HeaderValue);

tokio::task_local! {
    static INBOUND_TRACEPARENT: Option<HeaderValue>;
}

/// Read the active request's opaque inbound `traceparent` header from task-local context (`R75`).
#[must_use]
pub fn inbound_traceparent() -> Option<HeaderValue> {
    INBOUND_TRACEPARENT.try_with(Clone::clone).ok().flatten()
}

#[derive(Debug, Clone)]
struct MatchedRoute(String);

/// Record the matched route template on the response so outer L5 `access_log` distinguishes
/// matched probe endpoints (`/healthz`) from unmatched 404 paths (`/healthz/`).
async fn record_matched_route(req: Request, next: Next) -> Response {
    let matched = req
        .extensions()
        .get::<MatchedPath>()
        .map(|mp| mp.as_str().to_owned());
    let mut res = next.run(req).await;
    if let Some(route) = matched {
        res.extensions_mut().insert(MatchedRoute(route));
    }
    res
}

/// Echo the live `request-id` header onto every outgoing response (`R75` L3).
pub async fn echo_request_id(req: Request, next: Next) -> Response {
    let req_id = req.headers().get(REQUEST_ID).cloned();
    let mut res = next.run(req).await;
    if let Some(id) = req_id {
        res.headers_mut().insert(REQUEST_ID, id);
    }
    res
}

/// Propagate inbound `traceparent` opaquely via request extension and task-local scope without
/// echoing it on the HTTP response (`R75` L3b).
pub async fn propagate_traceparent(mut req: Request, next: Next) -> Response {
    let tp = req.headers().get(TRACEPARENT).cloned();
    if let Some(ref val) = tp {
        req.extensions_mut().insert(InboundTraceparent(val.clone()));
    }
    INBOUND_TRACEPARENT.scope(tp, next.run(req)).await
}

/// Emit one structured `rs_launch_blueprint::http_access` log event per request, skipping matched
/// operational probe routes in [`ACCESS_LOG_EXCLUDED_ROUTES`] (`R75` L5).
pub async fn access_log(req: Request, next: Next) -> Response {
    let method = req.method().as_str().to_owned();
    let path = req.uri().path().to_owned();
    let request_id = req
        .headers()
        .get(REQUEST_ID)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("-")
        .to_owned();
    let started = Instant::now();

    let res = next.run(req).await;

    let excluded = res
        .extensions()
        .get::<MatchedRoute>()
        .is_some_and(|mr| ACCESS_LOG_EXCLUDED_ROUTES.contains(&mr.0.as_str()));

    if !excluded {
        let status = res.status().as_u16();
        let latency_ms = u64::try_from(started.elapsed().as_millis()).unwrap_or(u64::MAX);
        tracing::info!(
            target: "rs_launch_blueprint::http_access",
            method = %method,
            path = %path,
            status,
            latency_ms,
            request_id = %request_id,
            "http_request"
        );
    }

    res
}

#[derive(Clone)]
struct PanicToProblem {
    problem_base_uri: String,
}

impl ResponseForPanic for PanicToProblem {
    type ResponseBody = axum::body::Body;

    fn response_for_panic(
        &mut self,
        _err: Box<dyn Any + Send + 'static>,
    ) -> HttpResponse<Self::ResponseBody> {
        tracing::error!("request handler panicked; returning redacted 500 problem response");
        WebError::internal(&self.problem_base_uri, None).into_response()
    }
}

#[derive(Clone)]
struct ProblemNormalizerState {
    problem_base_uri: String,
}

/// Convert bare `408 Request Timeout` / `413 Payload Too Large` responses emitted by `tower-http`
/// layers into RFC 9457 `application/problem+json` envelopes (`R70` W3, `R75` L9).
async fn normalize_layer_errors(
    State(state): State<ProblemNormalizerState>,
    req: Request,
    next: Next,
) -> Response {
    let path = req.uri().path().to_owned();
    let res = next.run(req).await;
    let is_problem = res
        .headers()
        .get(header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .is_some_and(|ct| ct.starts_with(PROBLEM_CONTENT_TYPE));
    if is_problem {
        return res;
    }

    match res.status() {
        StatusCode::REQUEST_TIMEOUT => WebError::framework(
            StatusCode::REQUEST_TIMEOUT,
            "request_timeout",
            ErrorCode::Io,
            "Request timed out before completing.",
            &state.problem_base_uri,
            Some(&path),
        )
        .into_response(),
        StatusCode::PAYLOAD_TOO_LARGE => WebError::framework(
            StatusCode::PAYLOAD_TOO_LARGE,
            "payload_too_large",
            ErrorCode::Usage,
            "Request body exceeds the maximum allowed size.",
            &state.problem_base_uri,
            Some(&path),
        )
        .into_response(),
        _ => res,
    }
}

/// Apply the four baseline security headers (`if_not_present`, handler-set wins, `R75` L2).
fn apply_security_headers(router: Router) -> Router {
    router
        .layer(SetResponseHeaderLayer::if_not_present(
            header::STRICT_TRANSPORT_SECURITY,
            HeaderValue::from_static("max-age=63072000; includeSubDomains"),
        ))
        .layer(SetResponseHeaderLayer::if_not_present(
            header::REFERRER_POLICY,
            HeaderValue::from_static("no-referrer"),
        ))
        .layer(SetResponseHeaderLayer::if_not_present(
            header::X_FRAME_OPTIONS,
            HeaderValue::from_static("DENY"),
        ))
        .layer(SetResponseHeaderLayer::if_not_present(
            header::X_CONTENT_TYPE_OPTIONS,
            HeaderValue::from_static("nosniff"),
        ))
}

/// Install a process-wide structured panic hook for the `rslbp-serve` binary (`R75` F327).
///
/// Must be called **only** by the binary entrypoint, never inside library constructors or tests.
pub fn install_panic_hook() {
    let previous = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |info| {
        let location = info.location().map_or_else(
            || "unknown".to_owned(),
            |loc| format!("{}:{}", loc.file(), loc.line()),
        );
        tracing::error!(location = %location, "unhandled panic captured by service hook");
        previous(info);
    }));
}

/// Wrap `router` in the fixed-order R75 middleware stack (`L1` outermost through `L9` innermost).
pub fn apply_middleware(
    router: Router,
    settings: &WebSettings,
    rate_store: Arc<dyn RateLimitStore>,
) -> Router {
    let sensitive_headers: Arc<[HeaderName]> = Arc::from([
        header::AUTHORIZATION,
        header::COOKIE,
        header::PROXY_AUTHORIZATION,
        HeaderName::from_static("x-api-key"),
    ]);

    // Innermost route marker so L5 access_log can distinguish matched `/healthz` from 404 `/healthz/`.
    let router = router.route_layer(middleware::from_fn(record_matched_route));

    // L9: Request body limit + timeout, normalized to RFC 9457 problem+json.
    let router = router
        .layer(RequestBodyLimitLayer::new(settings.max_body_bytes))
        .layer(TimeoutLayer::with_status_code(
            StatusCode::REQUEST_TIMEOUT,
            settings.request_timeout,
        ))
        .layer(middleware::from_fn_with_state(
            ProblemNormalizerState {
                problem_base_uri: settings.problem_base_uri.clone(),
            },
            normalize_layer_errors,
        ));

    // L8: Per-IP GCRA rate limiting (inside CORS so cross-origin 429 carries ACAO).
    let router = install_rate_limit_with_base(
        router,
        rate_store,
        settings.effective_rate_limit_policy(),
        &settings.problem_base_uri,
    );

    // L7: Conditional CORS (absent when cors_origins is empty).
    let router = apply_cors(router, &settings.cors_origins);

    // L6: Panic containment returning redacted RFC 9457 500 inside access_log and echo_request_id.
    let router = router.layer(CatchPanicLayer::custom(PanicToProblem {
        problem_base_uri: settings.problem_base_uri.clone(),
    }));

    // L5: Sensitive request header marking + structured access logging.
    let router = router
        .layer(SetSensitiveRequestHeadersLayer::from_shared(
            sensitive_headers,
        ))
        .layer(middleware::from_fn(access_log));

    // L3b: Opaque inbound traceparent propagation.
    let router = router.layer(middleware::from_fn(propagate_traceparent));

    // L3: Echo live request-id on every response.
    let router = router.layer(middleware::from_fn(echo_request_id));

    // L2: Baseline security response headers (if_not_present).
    let router = apply_security_headers(router);

    // L1 (outermost): Generate or preserve request-id header on incoming requests.
    router.layer(SetRequestIdLayer::new(REQUEST_ID, MakeRequestUuid))
}
