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
use rs_launch_blueprint::ErrorCode;
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

/// RFC 9745 route deprecation header name (`F309`).
pub const DEPRECATION_HEADER: HeaderName = HeaderName::from_static("deprecation");

/// RFC 8594 route sunset header name (`F309`).
pub const SUNSET_HEADER: HeaderName = HeaderName::from_static("sunset");

/// Validate an RFC 9110 §5.6.7 `IMF-fixdate` (`Day, DD Mon YYYY HH:MM:SS GMT`) string.
fn is_valid_imf_fixdate(value: &str) -> bool {
    let b = value.as_bytes();
    if b.len() != 29 || !value.is_ascii() {
        return false;
    }
    if b[3] != b','
        || b[4] != b' '
        || b[7] != b' '
        || b[11] != b' '
        || b[16] != b' '
        || b[19] != b':'
        || b[22] != b':'
        || b[25] != b' '
        || &value[26..29] != "GMT"
    {
        return false;
    }

    let Some(weekday) = (match &value[0..3] {
        "Sun" => Some(0u32),
        "Mon" => Some(1),
        "Tue" => Some(2),
        "Wed" => Some(3),
        "Thu" => Some(4),
        "Fri" => Some(5),
        "Sat" => Some(6),
        _ => None,
    }) else {
        return false;
    };

    let Some(month) = (match &value[8..11] {
        "Jan" => Some(1u32),
        "Feb" => Some(2),
        "Mar" => Some(3),
        "Apr" => Some(4),
        "May" => Some(5),
        "Jun" => Some(6),
        "Jul" => Some(7),
        "Aug" => Some(8),
        "Sep" => Some(9),
        "Oct" => Some(10),
        "Nov" => Some(11),
        "Dec" => Some(12),
        _ => None,
    }) else {
        return false;
    };

    let (Ok(day), Ok(year), Ok(hour), Ok(minute), Ok(second)) = (
        value[5..7].parse::<u32>(),
        value[12..16].parse::<u32>(),
        value[17..19].parse::<u32>(),
        value[20..22].parse::<u32>(),
        value[23..25].parse::<u32>(),
    ) else {
        return false;
    };

    if year == 0 || hour > 23 || minute > 59 || second > 60 {
        return false;
    }

    let is_leap = (year.is_multiple_of(4) && !year.is_multiple_of(100)) || year.is_multiple_of(400);
    let max_day = match month {
        1 | 3 | 5 | 7 | 8 | 10 | 12 => 31,
        4 | 6 | 9 | 11 => 30,
        2 if is_leap => 29,
        2 => 28,
        _ => return false,
    };
    if day == 0 || day > max_day {
        return false;
    }

    // Verify Gregorian day-of-week matches the calendar date (Sakamoto's algorithm).
    const OFFSETS: [u32; 12] = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4];
    let adj_year = if month < 3 { year - 1 } else { year };
    let expected_weekday = (adj_year + adj_year / 4 - adj_year / 100
        + adj_year / 400
        + OFFSETS[(month - 1) as usize]
        + day)
        % 7;
    weekday == expected_weekday
}

/// Build RFC 9745 `Deprecation` (`@<unix-timestamp>`) and optional RFC 8594 `Sunset` response
/// headers for deprecated HTTP routes (`F309`).
///
/// The optional `sunset_http_date` is validated as an RFC 9110 `IMF-fixdate` (`GMT`) and omitted
/// if malformed.
#[must_use]
pub fn deprecation_headers(
    deprecated_at_unix: i64,
    sunset_http_date: Option<&str>,
) -> Vec<(HeaderName, HeaderValue)> {
    let mut headers = Vec::with_capacity(2);
    if let Ok(val) = HeaderValue::from_str(&format!("@{deprecated_at_unix}")) {
        headers.push((DEPRECATION_HEADER, val));
    }
    if let Some(sunset) = sunset_http_date
        && is_valid_imf_fixdate(sunset)
        && let Ok(val) = HeaderValue::from_str(sunset)
    {
        headers.push((SUNSET_HEADER, val));
    }
    headers
}

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

/// Create the HTTP server `tracing` span for each request, attaching the extracted W3C Trace
/// Context parent when the `otel` feature is compiled in (`R78` point 4).
async fn http_server_span(req: Request, next: Next) -> Response {
    let method = req.method().as_str().to_owned();
    let request_id = req
        .headers()
        .get(REQUEST_ID)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("-")
        .to_owned();

    let span = tracing::info_span!(
        "http.server.request",
        otel.kind = "server",
        http.request.method = %method,
        http.route = tracing::field::Empty,
        http.response.status_code = tracing::field::Empty,
        request_id = %request_id,
    );

    #[cfg(feature = "otel")]
    {
        use opentelemetry::global;
        use opentelemetry::trace::TraceContextExt as _;
        use opentelemetry_http::HeaderExtractor;
        use tracing_opentelemetry::OpenTelemetrySpanExt as _;

        let parent_cx =
            global::get_text_map_propagator(|prop| prop.extract(&HeaderExtractor(req.headers())));
        if parent_cx.span().span_context().is_valid() {
            let _ = span.set_parent(parent_cx);
        }
    }

    let res = tracing::Instrument::instrument(next.run(req), span.clone()).await;
    span.record("http.response.status_code", res.status().as_u16());
    if let Some(MatchedRoute(route)) = res.extensions().get::<MatchedRoute>() {
        span.record("http.route", route.as_str());
    }
    res
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

    // L4: HTTP server tracing span (with W3C parent extraction under `otel`, R78).
    let router = router.layer(middleware::from_fn(http_server_span));

    // L3b: Opaque inbound traceparent propagation.
    let router = router.layer(middleware::from_fn(propagate_traceparent));

    // L3: Echo live request-id on every response.
    let router = router.layer(middleware::from_fn(echo_request_id));

    // L2: Baseline security response headers (if_not_present).
    let router = apply_security_headers(router);

    // L1 (outermost): Generate or preserve request-id header on incoming requests.
    router.layer(SetRequestIdLayer::new(REQUEST_ID, MakeRequestUuid))
}

#[cfg(test)]
mod tests {
    use super::{DEPRECATION_HEADER, SUNSET_HEADER, deprecation_headers};

    #[test]
    fn deprecation_headers_emit_rfc9745_date_and_optional_sunset() {
        let only_dep = deprecation_headers(1_767_225_600, None);
        assert_eq!(only_dep.len(), 1);
        assert_eq!(only_dep[0].0, DEPRECATION_HEADER);
        assert_eq!(only_dep[0].1, "@1767225600");

        let with_sunset = deprecation_headers(1_767_225_600, Some("Thu, 31 Dec 2026 23:59:59 GMT"));
        assert_eq!(with_sunset.len(), 2);
        assert_eq!(with_sunset[0].0, DEPRECATION_HEADER);
        assert_eq!(with_sunset[0].1, "@1767225600");
        assert_eq!(with_sunset[1].0, SUNSET_HEADER);
        assert_eq!(with_sunset[1].1, "Thu, 31 Dec 2026 23:59:59 GMT");

        let bad_sunset = deprecation_headers(1_767_225_600, Some("invalid\r\nheader"));
        assert_eq!(bad_sunset.len(), 1);
        assert_eq!(bad_sunset[0].0, DEPRECATION_HEADER);

        let printable_invalid = deprecation_headers(1_767_225_600, Some("not-a-date"));
        assert_eq!(printable_invalid.len(), 1);
        assert_eq!(printable_invalid[0].0, DEPRECATION_HEADER);

        let bad_calendar =
            deprecation_headers(1_767_225_600, Some("Sun, 31 Feb 2026 00:00:00 GMT"));
        assert_eq!(bad_calendar.len(), 1);

        let wrong_weekday =
            deprecation_headers(1_767_225_600, Some("Mon, 31 Dec 2026 23:59:59 GMT"));
        assert_eq!(wrong_weekday.len(), 1);

        let bad_time = deprecation_headers(1_767_225_600, Some("Thu, 31 Dec 2026 25:00:00 GMT"));
        assert_eq!(bad_time.len(), 1);

        let bad_sep = deprecation_headers(1_767_225_600, Some("Thu- 31 Dec 2026 23:59:59 GMT"));
        assert_eq!(bad_sep.len(), 1);

        let bad_weekday_token =
            deprecation_headers(1_767_225_600, Some("Xxx, 31 Dec 2026 23:59:59 GMT"));
        assert_eq!(bad_weekday_token.len(), 1);

        let bad_month_token =
            deprecation_headers(1_767_225_600, Some("Thu, 31 Xxx 2026 23:59:59 GMT"));
        assert_eq!(bad_month_token.len(), 1);

        let bad_digits = deprecation_headers(1_767_225_600, Some("Thu, AA Dec 2026 23:59:59 GMT"));
        assert_eq!(bad_digits.len(), 1);

        // Valid leap day (2024-02-29 is a Thursday) and 30-day month (2026-04-30 is a Thursday)
        let leap_day = deprecation_headers(1_709_164_800, Some("Thu, 29 Feb 2024 00:00:00 GMT"));
        assert_eq!(leap_day.len(), 2);
        let non_leap = deprecation_headers(1_740_700_800, Some("Fri, 28 Feb 2025 00:00:00 GMT"));
        assert_eq!(non_leap.len(), 2);
        let april_30 = deprecation_headers(1_777_507_200, Some("Thu, 30 Apr 2026 00:00:00 GMT"));
        assert_eq!(april_30.len(), 2);
    }
}
