#!/usr/bin/env bash
# R75 synthesis probe: materialize the scratch crate that every other R75 check runs,
# resolve it once, and log the version matrix and feature facts the decision cites.
#
# The crate lives OUTSIDE this repository (default "$TMPDIR/r75-synth-probe"; override
# with R75_PROBE_DIR). No Rust file is written into the repository. The first run needs
# crates.io (index.crates.io / static.crates.io) to resolve and download; every later
# cargo invocation in the R75 checks runs --offline --locked against the private
# CARGO_HOME this run was given.
#
# Usage: bash probe-crate.sh            (prints the resolution log to stdout)
set -euo pipefail

probe="${R75_PROBE_DIR:-${TMPDIR:-/tmp}/r75-synth-probe}"
mkdir -p "$probe/src" "$probe/tests/common"
cd "$probe"

cat > Cargo.toml <<'EOF'
[package]
name = "r75probe"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"
publish = false

# Normal dependencies: R69's axum/tokio pins plus the recommended tower-http feature set.
[dependencies]
axum = "=0.8.9"
tokio = { version = "=1.53.1", features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }
tower-http = { version = "=0.7.1", default-features = false, features = ["request-id", "set-header", "catch-panic", "timeout"] }
tracing = "0.1.44"

# Test-only: tower for oneshot (R69's dev idiom), trace/cors for the variants and the R76
# stand-in, a capturing subscriber, io-util for the raw-socket client, log for the fold-in check.
[dev-dependencies]
tower = { version = "=0.5.3", features = ["util"] }
tower-http = { version = "=0.7.1", default-features = false, features = ["request-id", "set-header", "catch-panic", "timeout", "trace", "cors"] }
tracing-subscriber = { version = "0.3.23", default-features = false, features = ["registry", "std"] }
tokio = { version = "=1.53.1", features = ["io-util"] }
log = { version = "0.4", features = ["std"] }
EOF

cat > src/lib.rs <<'EOF'
//! R75 synthesis probe: the recommended stack's building blocks and its one composition
//! function. The R73/R74/R76 slot stand-ins live in the tests.
use std::time::{Duration, Instant};

use axum::{
    Router,
    extract::{MatchedPath, Request},
    http::{HeaderName, HeaderValue, StatusCode, header},
    middleware::{self, Next},
    response::Response,
};
use tower_http::{
    catch_panic::CatchPanicLayer,
    request_id::{MakeRequestUuid, RequestId, SetRequestIdLayer},
    set_header::response::SetMultipleResponseHeadersLayer,
    timeout::TimeoutLayer,
};
use tracing::Instrument;

/// REST API Design Standard section 1.10 / R11.7: the lowercase `request-id` (RFC 6648).
pub const REQUEST_ID: HeaderName = HeaderName::from_static("request-id");
pub const TRACEPARENT: HeaderName = HeaderName::from_static("traceparent");
pub const ACCESS_LOG_EXCLUDED_ROUTES: &[&str] = &["/healthz", "/readyz", "/metrics"];
pub const ACCESS_TARGET: &str = "r75probe::http_access";
pub const PANIC_TARGET: &str = "r75probe::panic";

/// py's four values (F321), stamped where a handler has not set its own.
pub fn security_header_values() -> Vec<(HeaderName, HeaderValue)> {
    vec![
        (header::X_CONTENT_TYPE_OPTIONS, HeaderValue::from_static("nosniff")),
        (header::X_FRAME_OPTIONS, HeaderValue::from_static("DENY")),
        (header::REFERRER_POLICY, HeaderValue::from_static("no-referrer")),
        (
            header::STRICT_TRANSPORT_SECURITY,
            HeaderValue::from_static("max-age=63072000; includeSubDomains"),
        ),
    ]
}

pub fn security_headers() -> SetMultipleResponseHeadersLayer<Response> {
    SetMultipleResponseHeadersLayer::if_not_present(
        security_header_values().into_iter().map(Into::into).collect(),
    )
}

/// L3: echo the edge-selected id, overwriting any id an inner layer wrote (py assigns).
pub async fn echo_request_id(req: Request, next: Next) -> Response {
    let id = req.extensions().get::<RequestId>().map(|id| id.header_value().clone());
    let mut res = next.run(req).await;
    if let Some(id) = id {
        res.headers_mut().insert(REQUEST_ID, id);
    }
    res
}

tokio::task_local! {
    static INBOUND_TRACEPARENT: Option<HeaderValue>;
}

/// The inbound W3C `traceparent`, kept as opaque bytes (never parsed, never generated).
#[derive(Clone, Debug)]
pub struct InboundTraceparent(pub HeaderValue);

/// L3b: opaque `traceparent` passthrough (REST R11.8), with no OpenTelemetry crate: the
/// inbound value goes into a request extension and is scoped task-locally around the
/// inner service, so an outbound adapter forwards it without seeing the request.
pub async fn propagate_traceparent(mut req: Request, next: Next) -> Response {
    let inbound = req.headers().get(TRACEPARENT).cloned();
    if let Some(v) = &inbound {
        req.extensions_mut().insert(InboundTraceparent(v.clone()));
    }
    INBOUND_TRACEPARENT.scope(inbound, next.run(req)).await
}

/// What an outbound adapter forwards as `traceparent`, if the current request carried one.
pub fn inbound_traceparent() -> Option<HeaderValue> {
    INBOUND_TRACEPARENT.try_with(Clone::clone).ok().flatten()
}

/// F327: the process-wide panic hook. It replaces std's default hook, so the plain-text
/// `thread '..' panicked at ..` stderr line is never written; the message and location go
/// through the tracing pipeline as one ERROR event in the current span (the request span
/// for a handler panic). The serve binary's main installs it once, right after
/// telemetry::init; library code never does.
pub fn install_panic_hook() {
    std::panic::set_hook(Box::new(|info| {
        let payload = info.payload();
        let message = payload
            .downcast_ref::<&str>()
            .copied()
            .or_else(|| payload.downcast_ref::<String>().map(String::as_str))
            .unwrap_or("Box<dyn Any>");
        let location = info.location().map(|l| format!("{}:{}:{}", l.file(), l.line(), l.column()));
        tracing::error!(
            target: PANIC_TARGET,
            panic_message = message,
            location = location.as_deref(),
            "panic"
        );
    }));
}

/// L5: the one canonical `http_request` event, every field on the event.
pub async fn access_log(req: Request, next: Next) -> Response {
    let route = req.extensions().get::<MatchedPath>().map(|m| m.as_str().to_owned());
    let excluded = route.as_deref().is_some_and(|r| ACCESS_LOG_EXCLUDED_ROUTES.contains(&r));
    let request_id = req
        .extensions()
        .get::<RequestId>()
        .and_then(|id| id.header_value().to_str().ok())
        .unwrap_or_default()
        .to_owned();
    let method = req.method().clone();
    let path = req.uri().path().to_owned();
    let span = tracing::info_span!("request", request_id = %request_id);
    let start = Instant::now();
    let res = next.run(req).instrument(span.clone()).await;
    if !excluded {
        let _entered = span.enter();
        tracing::info!(
            target: ACCESS_TARGET,
            request_id = %request_id,
            method = %method,
            route = route.as_deref(),
            path = %path,
            status = res.status().as_u16(),
            duration_ms = start.elapsed().as_secs_f64() * 1000.0,
            "http_request"
        );
    }
    res
}

/// Outermost -> innermost: L1 SetRequestId, L2 security headers, L3 id echo,
/// L3b traceparent passthrough, [L4 R78/R79], L5 access log, L6 catch-panic, [L7 R76 CORS], [L8 R74 rate limit],
/// L9 timeout, [L10 R73 idempotency], handlers. Written innermost-first: each
/// `Router::layer` call wraps every layer applied before it.
pub fn apply_middleware(
    router: Router,
    timeout: Duration,
    idempotency_slot: impl FnOnce(Router) -> Router,
    policy_slots: impl FnOnce(Router) -> Router,
) -> Router {
    let router = idempotency_slot(router); // L10 (R73)
    let router =
        router.layer(TimeoutLayer::with_status_code(StatusCode::REQUEST_TIMEOUT, timeout)); // L9
    let router = policy_slots(router); // L8 (R74), then L7 (R76) outside it
    router
        .layer(CatchPanicLayer::new()) // L6
        .layer(middleware::from_fn(access_log)) // L5
        // L4: R78/R79 slot
        .layer(middleware::from_fn(propagate_traceparent)) // L3b
        .layer(middleware::from_fn(echo_request_id)) // L3
        .layer(security_headers()) // L2
        .layer(SetRequestIdLayer::new(REQUEST_ID, MakeRequestUuid)) // L1
}
EOF

cat > tests/common/mod.rs <<'EOF'
#![allow(dead_code)]
use std::{
    collections::BTreeMap,
    sync::{Arc, Mutex},
    time::Duration,
};

use axum::{
    Router,
    body::Body,
    extract::Request,
    http::{Method, StatusCode, header},
    middleware::{self, Next},
    response::{IntoResponse, Response},
    routing::get,
};
use tower::ServiceExt;
use tower_http::{
    cors::{Any, CorsLayer},
    request_id::RequestId,
    trace::{MakeSpan, OnResponse},
};
use tracing::{
    Level, Span, Subscriber,
    field::{Field, Visit},
    span,
};
use tracing_subscriber::{Layer, layer::Context, prelude::*, registry::LookupSpan};

pub use r75probe::ACCESS_TARGET;

#[derive(Debug, Clone)]
pub struct Ev {
    pub target: String,
    pub level: Level,
    pub fields: BTreeMap<String, String>,
    pub span_request_id: Option<String>,
}

#[derive(Clone, Default)]
pub struct Capture(pub Arc<Mutex<Vec<Ev>>>);

impl Capture {
    pub fn take(&self) -> Vec<Ev> {
        std::mem::take(&mut *self.0.lock().unwrap())
    }
}

#[derive(Default)]
struct Fields(BTreeMap<String, String>);

impl Visit for Fields {
    fn record_str(&mut self, f: &Field, v: &str) {
        self.0.insert(f.name().into(), v.into());
    }
    fn record_debug(&mut self, f: &Field, v: &dyn std::fmt::Debug) {
        self.0.insert(f.name().into(), format!("{v:?}"));
    }
}

struct SpanFields(BTreeMap<String, String>);

impl<S: Subscriber + for<'a> LookupSpan<'a>> Layer<S> for Capture {
    fn on_new_span(&self, attrs: &span::Attributes<'_>, id: &span::Id, ctx: Context<'_, S>) {
        let mut f = Fields::default();
        attrs.record(&mut f);
        if let Some(s) = ctx.span(id) {
            s.extensions_mut().insert(SpanFields(f.0));
        }
    }
    fn on_event(&self, event: &tracing::Event<'_>, ctx: Context<'_, S>) {
        let mut f = Fields::default();
        event.record(&mut f);
        let span_request_id = ctx.event_scope(event).and_then(|scope| {
            scope.from_root().find_map(|s| {
                s.extensions().get::<SpanFields>().and_then(|x| x.0.get("request_id").cloned())
            })
        });
        self.0.lock().unwrap().push(Ev {
            target: event.metadata().target().into(),
            level: *event.metadata().level(),
            fields: f.0,
            span_request_id,
        });
    }
}

/// Thread-local capture for current-thread tests.
pub fn capture() -> (Capture, tracing::subscriber::DefaultGuard) {
    let cap = Capture::default();
    let guard = tracing::subscriber::set_default(tracing_subscriber::registry().with(cap.clone()));
    (cap, guard)
}

pub fn access(events: &[Ev]) -> Vec<&Ev> {
    events.iter().filter(|e| e.target == ACCESS_TARGET).collect()
}

async fn boom() -> &'static str {
    panic!("boom")
}

pub fn routes() -> Router {
    Router::new()
        .route("/v1/projects/{id}", get(|| async { "project" }))
        .route(
            "/v1/work",
            get(|| async {
                tracing::info!(target: "r75probe::handler", "handler work");
                "worked"
            }),
        )
        .route("/healthz", get(|| async { "ok" }))
        .route("/boom", get(boom))
        .route(
            "/slow",
            get(|| async {
                tokio::time::sleep(Duration::from_secs(5)).await;
                "late"
            }),
        )
        .route("/framed", get(|| async { ([(header::X_FRAME_OPTIONS, "SAMEORIGIN")], "framed") }))
        .route(
            "/v1/outbound",
            get(|req: Request| async move {
                // What a handler and an outbound adapter (no request in hand) each see.
                let ext = req
                    .extensions()
                    .get::<r75probe::InboundTraceparent>()
                    .map(|t| t.0.to_str().unwrap().to_owned());
                let tl = r75probe::inbound_traceparent().map(|v| v.to_str().unwrap().to_owned());
                format!(
                    "ext={} tl={}",
                    ext.unwrap_or_else(|| "NONE".into()),
                    tl.unwrap_or_else(|| "NONE".into())
                )
            }),
        )
}

/// R74 stand-in: a 429 when the test asks for one.
pub async fn rate_limit_stand_in(req: Request, next: Next) -> Response {
    if req.headers().contains_key("x-test-throttle") {
        return StatusCode::TOO_MANY_REQUESTS.into_response();
    }
    next.run(req).await
}

/// R73 stand-in: a replay returns a stored response that still carries the ORIGINAL
/// request's id, as a naive response store would.
pub async fn idempotency_stand_in(req: Request, next: Next) -> Response {
    if req.headers().contains_key("x-test-replay") {
        return ([("request-id", "original-111")], "replayed").into_response();
    }
    next.run(req).await
}

/// R76 stand-in: a real tower-http CorsLayer.
pub fn cors() -> CorsLayer {
    CorsLayer::new().allow_origin(Any).allow_methods([Method::GET])
}

pub fn recommended_app() -> Router {
    r75probe::apply_middleware(
        routes(),
        Duration::from_millis(200),
        |r| r.layer(middleware::from_fn(idempotency_stand_in)),
        |r| r.layer(middleware::from_fn(rate_limit_stand_in)).layer(cors()),
    )
}

pub async fn send(app: Router, method: Method, uri: &str, headers: &[(&str, &str)]) -> Response {
    let mut b = Request::builder().method(method).uri(uri);
    for (k, v) in headers {
        b = b.header(*k, *v);
    }
    app.oneshot(b.body(Body::empty()).unwrap()).await.unwrap()
}

pub fn hdr(res: &Response, name: &str) -> Option<String> {
    res.headers().get(name).map(|v| v.to_str().unwrap().to_owned())
}

pub fn is_uuid_v4(s: &str) -> bool {
    let b = s.as_bytes();
    b.len() == 36 && b[14] == b'4' && [8, 13, 18, 23].iter().all(|&i| b[i] == b'-')
}

pub const SEC: [(&str, &str); 4] = [
    ("x-content-type-options", "nosniff"),
    ("x-frame-options", "DENY"),
    ("referrer-policy", "no-referrer"),
    ("strict-transport-security", "max-age=63072000; includeSubDomains"),
];

/// Assert and print one numbered check.
pub fn check(id: &str, what: &str, ok: bool, observed: String) {
    println!("{} {id} {what} :: {observed}", if ok { "PASS" } else { "FAIL" });
    assert!(ok, "{id} failed: {what} :: {observed}");
}

/// The engines' TraceLayer variant: span from the RequestId extension ("-" if absent),
/// one counted event on response.
#[derive(Clone)]
pub struct IdSpan;
impl<B> MakeSpan<B> for IdSpan {
    fn make_span(&mut self, req: &axum::http::Request<B>) -> Span {
        let id = req
            .extensions()
            .get::<RequestId>()
            .and_then(|i| i.header_value().to_str().ok())
            .unwrap_or("-")
            .to_owned();
        tracing::info_span!("http_request_span", request_id = %id)
    }
}
#[derive(Clone)]
pub struct CountResponse;
impl<B> OnResponse<B> for CountResponse {
    fn on_response(self, res: &axum::http::Response<B>, _latency: Duration, _span: &Span) {
        tracing::info!(target: ACCESS_TARGET, status = res.status().as_u16(), "http_request");
    }
}
EOF

cat > tests/acceptance.rs <<'EOF'
//! The recommended stack, driven in-process through `tower::ServiceExt::oneshot`.
mod common;
use axum::http::Method;
use common::*;

const PREFLIGHT: [(&str, &str); 2] =
    [("origin", "https://app.example"), ("access-control-request-method", "GET")];

fn envelope(res: &axum::response::Response, skip: &str) -> (bool, String) {
    let id = hdr(res, "request-id");
    let legacy = hdr(res, "x-request-id");
    let mut ok = id.is_some() && legacy.is_none();
    let mut seen = vec![format!(
        "request-id={} x-request-id={}",
        id.unwrap_or_else(|| "NONE".into()),
        legacy.unwrap_or_else(|| "NONE".into())
    )];
    for (n, v) in SEC {
        if n == skip {
            continue;
        }
        let got = hdr(res, n);
        ok &= got.as_deref() == Some(v);
        seen.push(format!("{n}={}", got.unwrap_or_else(|| "NONE".into())));
    }
    (ok, seen.join(" "))
}

#[tokio::test]
async fn recommended_stack_contract() {
    let (cap, _g) = capture();
    let app = recommended_app;

    // A01 matched request: generated uuid v4, full envelope, one event with the template.
    cap.take();
    let res = send(app(), Method::GET, "/v1/projects/7", &[]).await;
    let ev = cap.take();
    let a = access(&ev);
    let id = hdr(&res, "request-id").unwrap_or_default();
    let (env_ok, env) = envelope(&res, "");
    check("A01", "200: envelope + uuid v4 id", res.status() == 200 && env_ok && is_uuid_v4(&id), env);
    check(
        "A01b",
        "one http_request event, route template, request_id == header",
        a.len() == 1
            && a[0].fields.get("route").map(String::as_str) == Some("/v1/projects/{id}")
            && a[0].fields.get("status").map(String::as_str) == Some("200")
            && a[0].fields.get("request_id") == Some(&id)
            && a[0].fields.get("method").map(String::as_str) == Some("GET")
            && a[0].fields.contains_key("duration_ms"),
        format!("events={} fields={:?}", a.len(), a.first().map(|e| &e.fields)),
    );

    // A02 inbound id preserved and bound.
    let res = send(app(), Method::GET, "/v1/projects/7", &[("request-id", "abc-123")]).await;
    let ev = cap.take();
    let a = access(&ev);
    check(
        "A02",
        "inbound request-id echoed and on the event",
        hdr(&res, "request-id").as_deref() == Some("abc-123")
            && a.len() == 1
            && a[0].fields.get("request_id").map(String::as_str) == Some("abc-123"),
        format!("header={:?} events={}", hdr(&res, "request-id"), a.len()),
    );

    // A03 handler events inherit the request span's id (F318 "bound to log context").
    let res = send(app(), Method::GET, "/v1/work", &[("request-id", "ctx-9")]).await;
    let ev = cap.take();
    let h: Vec<_> = ev.iter().filter(|e| e.target == "r75probe::handler").collect();
    check(
        "A03",
        "handler event carries span request_id",
        res.status() == 200 && h.len() == 1 && h[0].span_request_id.as_deref() == Some("ctx-9"),
        format!("handler_events={} span_request_id={:?}", h.len(), h.first().and_then(|e| e.span_request_id.clone())),
    );

    // A04/A05 probes: no event, envelope still present, query does not defeat exclusion.
    for (cid, uri) in [("A04", "/healthz"), ("A05", "/healthz?probe=1")] {
        let res = send(app(), Method::GET, uri, &[]).await;
        let ev = cap.take();
        let (env_ok, env) = envelope(&res, "");
        check(cid, &format!("{uri}: 0 events, envelope present"),
            res.status() == 200 && access(&ev).is_empty() && env_ok,
            format!("status={} events={} {env}", res.status(), access(&ev).len()));
    }

    // A06/A07 unmatched paths reach the fallback through the stack: logged, route absent.
    for (cid, uri) in [("A06", "/nope"), ("A07", "/healthz/")] {
        let res = send(app(), Method::GET, uri, &[]).await;
        let ev = cap.take();
        let a = access(&ev);
        let (env_ok, env) = envelope(&res, "");
        check(cid, &format!("{uri}: 404 logged once, no route, envelope present"),
            res.status() == 404 && a.len() == 1 && !a[0].fields.contains_key("route") && env_ok,
            format!("status={} events={} {env}", res.status(), a.len()));
    }

    // A08 rate-limit 429 (L8 stand-in) keeps the envelope and is logged once.
    let res = send(app(), Method::GET, "/v1/projects/7", &[("x-test-throttle", "1")]).await;
    let ev = cap.take();
    let (env_ok, env) = envelope(&res, "");
    check("A08", "429: envelope + one event", res.status() == 429 && env_ok && access(&ev).len() == 1,
        format!("status={} events={} {env}", res.status(), access(&ev).len()));

    // A09 a cross-origin 429 carries CORS headers because CORS (L7) wraps rate limit (L8).
    let res = send(app(), Method::GET, "/v1/projects/7",
        &[("x-test-throttle", "1"), ("origin", "https://app.example")]).await;
    cap.take();
    check("A09", "cross-origin 429 carries access-control-allow-origin",
        res.status() == 429 && hdr(&res, "access-control-allow-origin").is_some(),
        format!("status={} acao={:?}", res.status(), hdr(&res, "access-control-allow-origin")));

    // A10 CORS preflight short-circuited at L7 keeps the envelope and is logged once.
    let res = send(app(), Method::OPTIONS, "/v1/projects/7", &PREFLIGHT).await;
    let ev = cap.take();
    let (env_ok, env) = envelope(&res, "");
    check("A10", "preflight: envelope + acao + one event",
        res.status() == 200 && env_ok && hdr(&res, "access-control-allow-origin").is_some()
            && access(&ev).len() == 1,
        format!("status={} events={} {env}", res.status(), access(&ev).len()));

    // A11 handler panic -> 500 via L6, logged once, plus one catch_panic ERROR in the span.
    let res = send(app(), Method::GET, "/boom", &[]).await;
    let ev = cap.take();
    let id = hdr(&res, "request-id");
    let cp: Vec<_> = ev.iter().filter(|e| e.target == "tower_http::catch_panic").collect();
    let (env_ok, env) = envelope(&res, "");
    check("A11", "panic: 500, envelope, one event, one catch_panic ERROR with the id",
        res.status() == 500 && env_ok && access(&ev).len() == 1 && cp.len() == 1
            && cp[0].level == tracing::Level::ERROR && cp[0].span_request_id == id,
        format!("status={} events={} catch_panic={} span_id_matches={} {env}",
            res.status(), access(&ev).len(), cp.len(),
            cp.first().map(|e| e.span_request_id == id).unwrap_or(false)));

    // A12 per-request timeout (L9) -> 408, logged once with the elapsed bound.
    let res = send(app(), Method::GET, "/slow", &[]).await;
    let ev = cap.take();
    let a = access(&ev);
    let dur: f64 = a.first().and_then(|e| e.fields.get("duration_ms")).and_then(|d| d.parse().ok()).unwrap_or(-1.0);
    let (env_ok, env) = envelope(&res, "");
    check("A12", "timeout: 408, envelope, one event, duration_ms >= 200",
        res.status() == 408 && env_ok && a.len() == 1 && dur >= 200.0,
        format!("status={} events={} duration_ms={dur:.1} {env}", res.status(), a.len()));

    // A13 a handler's own header value wins (py setdefault semantics).
    let res = send(app(), Method::GET, "/framed", &[]).await;
    cap.take();
    let (env_ok, env) = envelope(&res, "x-frame-options");
    check("A13", "handler X-Frame-Options survives; the other three present",
        hdr(&res, "x-frame-options").as_deref() == Some("SAMEORIGIN") && env_ok,
        format!("x-frame-options={:?} {env}", hdr(&res, "x-frame-options")));

    // A14 a replayed stored response (L10 stand-in) gets the NEW request's id echoed.
    let res = send(app(), Method::GET, "/v1/projects/7", &[("x-test-replay", "1")]).await;
    let ev = cap.take();
    let a = access(&ev);
    let id = hdr(&res, "request-id").unwrap_or_default();
    check("A14", "replay: echoed id is this request's, equals the event's",
        id != "original-111" && is_uuid_v4(&id) && a.len() == 1
            && a[0].fields.get("request_id") == Some(&id),
        format!("header={id} event={:?}", a.first().and_then(|e| e.fields.get("request_id"))));

    // A15 traceparent passthrough (L3b, no OTel crate): inbound bytes reach the handler's
    // extension and the task-local an outbound adapter reads; absent stays absent; no echo.
    let tp = "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01";
    let with = send(app(), Method::GET, "/v1/outbound", &[("traceparent", tp)]).await;
    let without = send(app(), Method::GET, "/v1/outbound", &[]).await;
    cap.take();
    let body = |r: axum::response::Response| async move {
        String::from_utf8(axum::body::to_bytes(r.into_body(), 1024).await.unwrap().to_vec()).unwrap()
    };
    let (with_echo, without_echo) = (hdr(&with, "traceparent"), hdr(&without, "traceparent"));
    let (bw, bo) = (body(with).await, body(without).await);
    check("A15", "traceparent forwarded opaquely to extension + task-local; absent -> none; not echoed",
        bw == format!("ext={tp} tl={tp}") && bo == "ext=NONE tl=NONE"
            && with_echo.is_none() && without_echo.is_none(),
        format!("with=[{bw}] without=[{bo}] response_traceparent={with_echo:?}/{without_echo:?}"));
}
EOF

cat > tests/negative.rs <<'EOF'
//! Variants the engines or the owner reference proposed, each run to show what it does.
mod common;
use std::time::Duration;

use axum::{Router, http::{Method, StatusCode, header}, middleware, routing::get};
use common::*;
use r75probe::*;
use tower::ServiceBuilder;
use tower_http::{
    catch_panic::CatchPanicLayer,
    request_id::{MakeRequestUuid, PropagateRequestIdLayer, SetRequestIdLayer},
    set_header::{SetResponseHeaderLayer, response::SetMultipleResponseHeadersLayer},
    timeout::TimeoutLayer,
    trace::TraceLayer,
};

const PREFLIGHT: [(&str, &str); 2] =
    [("origin", "https://app.example"), ("access-control-request-method", "GET")];

fn xfo(res: &axum::response::Response) -> String {
    hdr(res, "x-frame-options").unwrap_or_else(|| "NONE".into())
}

/// N01: the order the opus leg quotes from the owner reference's C11 — TraceLayer outside
/// the request-id pair, security headers innermost — expressed top-down in a ServiceBuilder.
#[tokio::test]
async fn n01_owner_reference_c11_order() {
    let (cap, _g) = capture();
    let app = || {
        routes().layer(
            ServiceBuilder::new()
                .layer(TraceLayer::new_for_http().make_span_with(IdSpan).on_request(()).on_response(CountResponse).on_failure(()))
                .layer(SetRequestIdLayer::new(REQUEST_ID, MakeRequestUuid))
                .layer(PropagateRequestIdLayer::new(REQUEST_ID))
                .layer(cors())
                .layer(middleware::from_fn(rate_limit_stand_in))
                .layer(TimeoutLayer::with_status_code(StatusCode::REQUEST_TIMEOUT, Duration::from_millis(200)))
                .layer(SetResponseHeaderLayer::overriding(header::X_FRAME_OPTIONS, header::HeaderValue::from_static("DENY")))
                .layer(SetResponseHeaderLayer::overriding(header::X_CONTENT_TYPE_OPTIONS, header::HeaderValue::from_static("nosniff"))),
        )
    };
    let ok = send(app(), Method::GET, "/v1/projects/7", &[]).await;
    let ev = cap.take();
    let span_id = ev.iter().find(|e| e.target == ACCESS_TARGET).and_then(|e| e.span_request_id.clone());
    check("N01a", "C11 order: a routed 200 still gets the headers (control)", xfo(&ok) == "DENY", format!("xfo={}", xfo(&ok)));
    check("N01b", "C11 order: the access span has no id (TraceLayer outside SetRequestId)",
        span_id.as_deref() == Some("-") && hdr(&ok, "request-id").is_some(),
        format!("span_request_id={span_id:?} response_id={:?}", hdr(&ok, "request-id")));
    let r429 = send(app(), Method::GET, "/v1/projects/7", &[("x-test-throttle", "1")]).await;
    check("N01c", "C11 order: the 429 loses X-Frame-Options", r429.status() == 429 && xfo(&r429) == "NONE", format!("status={} xfo={}", r429.status(), xfo(&r429)));
    let pre = send(app(), Method::OPTIONS, "/v1/projects/7", &PREFLIGHT).await;
    check("N01d", "C11 order: the preflight loses X-Frame-Options", xfo(&pre) == "NONE", format!("status={} xfo={}", pre.status(), xfo(&pre)));
    cap.take();
}

/// N02: the muse/gemini design — TraceLayer as route_layer on the API router only, probes
/// merged without it, envelope and policy layers outside via one ServiceBuilder.
#[tokio::test]
async fn n02_route_layer_access_log() {
    let (cap, _g) = capture();
    let app = || {
        let api = Router::new()
            .route("/v1/projects/{id}", get(|| async { "project" }))
            .route_layer(TraceLayer::new_for_http().make_span_with(IdSpan).on_request(()).on_response(CountResponse).on_failure(()));
        let probes = Router::new().route("/healthz", get(|| async { "ok" }));
        Router::new().merge(probes).merge(api).layer(
            ServiceBuilder::new()
                .layer(SetRequestIdLayer::new(REQUEST_ID, MakeRequestUuid))
                .layer(PropagateRequestIdLayer::new(REQUEST_ID))
                .layer(security_headers())
                .layer(cors())
                .layer(middleware::from_fn(rate_limit_stand_in)),
        )
    };
    let mut counts = Vec::new();
    for (name, method, uri, h) in [
        ("200", Method::GET, "/v1/projects/7", &[][..]),
        ("probe", Method::GET, "/healthz", &[][..]),
        ("404", Method::GET, "/nope", &[][..]),
        ("429", Method::GET, "/v1/projects/7", &[("x-test-throttle", "1")][..]),
        ("preflight", Method::OPTIONS, "/v1/projects/7", &PREFLIGHT[..]),
    ] {
        let res = send(app(), method, uri, h).await;
        let n = access(&cap.take()).len();
        counts.push((name, res.status().as_u16(), n, xfo(&res)));
    }
    let n = |k: &str| counts.iter().find(|c| c.0 == k).unwrap().2;
    check("N02a", "route_layer design: the routed 200 is logged once", n("200") == 1, format!("{counts:?}"));
    check("N02b", "route_layer design: the 429 from an outer rate-limit layer is NOT logged", n("429") == 0, format!("{counts:?}"));
    check("N02c", "route_layer design: the preflight and the 404 are NOT logged", n("preflight") == 0 && n("404") == 0, format!("{counts:?}"));
    check("N02d", "route_layer design: the envelope still reaches the 429 and the probe",
        counts.iter().filter(|c| c.0 == "429" || c.0 == "probe").all(|c| c.3 == "DENY"), format!("{counts:?}"));
}

/// N03: stock PropagateRequestIdLayer at L3 does not overwrite an inner layer's id.
#[tokio::test]
async fn n03_stock_propagate_keeps_replayed_id() {
    let (cap, _g) = capture();
    let app = routes()
        .layer(middleware::from_fn(idempotency_stand_in))
        .layer(middleware::from_fn(access_log))
        .layer(PropagateRequestIdLayer::new(REQUEST_ID))
        .layer(security_headers())
        .layer(SetRequestIdLayer::new(REQUEST_ID, MakeRequestUuid));
    let res = send(app, Method::GET, "/v1/projects/7", &[("x-test-replay", "1")]).await;
    let ev = cap.take();
    let logged = access(&ev).first().and_then(|e| e.fields.get("request_id").cloned());
    check("N03", "stock propagate: replay echoes the ORIGINAL id, not the logged one",
        hdr(&res, "request-id").as_deref() == Some("original-111") && logged.as_deref() != Some("original-111"),
        format!("header={:?} event_request_id={logged:?}", hdr(&res, "request-id")));
}

/// N04: without CatchPanicLayer a handler panic unwinds through the access layer: no event,
/// no response.
#[tokio::test]
async fn n04_no_catch_panic_loses_the_event() {
    use tower::ServiceExt;
    let (cap, _g) = capture();
    let app = routes()
        .layer(middleware::from_fn(access_log))
        .layer(middleware::from_fn(echo_request_id))
        .layer(security_headers())
        .layer(SetRequestIdLayer::new(REQUEST_ID, MakeRequestUuid));
    let req = axum::http::Request::get("/boom").body(axum::body::Body::empty()).unwrap();
    let joined = tokio::spawn(app.oneshot(req)).await;
    let n = access(&cap.take()).len();
    check("N04", "no CatchPanicLayer: the request panics and emits 0 http_request events",
        joined.as_ref().err().is_some_and(|e| e.is_panic()) && n == 0,
        format!("task_panicked={} events={n}", joined.as_ref().err().is_some_and(|e| e.is_panic())));
    let _ = CatchPanicLayer::new(); // the layer this variant omits
}

/// N05: `overriding` (muse/openai) replaces a handler's value; `if_not_present` keeps it.
#[tokio::test]
async fn n05_overriding_replaces_handler_value() {
    let over = SetMultipleResponseHeadersLayer::<axum::response::Response>::overriding(
        security_header_values().into_iter().map(Into::into).collect(),
    );
    let res = send(routes().layer(over), Method::GET, "/framed", &[]).await;
    check("N05", "overriding: handler SAMEORIGIN becomes DENY", xfo(&res) == "DENY", format!("xfo={}", xfo(&res)));
}

/// N06: the same stack spelled top-down with ServiceBuilder behaves identically.
#[tokio::test]
async fn n06_service_builder_spelling_is_equivalent() {
    let (cap, _g) = capture();
    let app = || {
        routes().layer(
            ServiceBuilder::new()
                .layer(SetRequestIdLayer::new(REQUEST_ID, MakeRequestUuid))
                .layer(security_headers())
                .layer(middleware::from_fn(echo_request_id))
                .layer(middleware::from_fn(propagate_traceparent))
                .layer(middleware::from_fn(access_log))
                .layer(CatchPanicLayer::new())
                .layer(cors())
                .layer(middleware::from_fn(rate_limit_stand_in))
                .layer(TimeoutLayer::with_status_code(StatusCode::REQUEST_TIMEOUT, Duration::from_millis(200)))
                .layer(middleware::from_fn(idempotency_stand_in)),
        )
    };
    let r429 = send(app(), Method::GET, "/v1/projects/7", &[("x-test-throttle", "1")]).await;
    let n429 = access(&cap.take()).len();
    let rep = send(app(), Method::GET, "/v1/projects/7", &[("x-test-replay", "1")]).await;
    let ev = cap.take();
    let logged = access(&ev).first().and_then(|e| e.fields.get("request_id").cloned());
    check("N06", "ServiceBuilder spelling: 429 enveloped and logged once; replay id echoed",
        xfo(&r429) == "DENY" && n429 == 1 && hdr(&rep, "request-id") == logged,
        format!("429_xfo={} 429_events={n429} replay_header={:?} replay_event={logged:?}", xfo(&r429), hdr(&rep, "request-id")));
}
EOF

cat > tests/foldin.rs <<'EOF'
//! F327: a real listener under axum::serve with a GLOBAL subscriber (as production) and a
//! counting `log` logger. Tallies every event by target and level.
mod common;
use std::{
    collections::BTreeMap,
    net::SocketAddr,
    sync::atomic::{AtomicUsize, Ordering},
};

use common::*;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tracing::Level;
use tracing_subscriber::prelude::*;

static LOG_RECORDS: AtomicUsize = AtomicUsize::new(0);
struct CountingLogger;
impl log::Log for CountingLogger {
    fn enabled(&self, _: &log::Metadata<'_>) -> bool {
        true
    }
    fn log(&self, r: &log::Record<'_>) {
        LOG_RECORDS.fetch_add(1, Ordering::SeqCst);
        println!("LOG-RECORD target={} level={}", r.target(), r.level());
    }
    fn flush(&self) {}
}
static LOGGER: CountingLogger = CountingLogger;

async fn raw_get(addr: SocketAddr, path: &str) -> (String, Option<String>) {
    let mut s = tokio::net::TcpStream::connect(addr).await.unwrap();
    s.write_all(format!("GET {path} HTTP/1.1\r\nHost: probe\r\nConnection: close\r\n\r\n").as_bytes())
        .await
        .unwrap();
    let mut buf = Vec::new();
    s.read_to_end(&mut buf).await.unwrap();
    let text = String::from_utf8_lossy(&buf).into_owned();
    let status = text.lines().next().unwrap_or_default().to_owned();
    let id = text
        .lines()
        .find_map(|l| l.strip_prefix("request-id: "))
        .map(str::to_owned);
    (status, id)
}

#[test]
fn framework_and_server_output_folds_into_tracing() {
    let cap = Capture::default();
    tracing::subscriber::set_global_default(tracing_subscriber::registry().with(cap.clone())).unwrap();
    r75probe::install_panic_hook(); // as the serve binary's main does, after telemetry::init
    log::set_logger(&LOGGER).unwrap();
    log::set_max_level(log::LevelFilter::Trace);

    let rt = tokio::runtime::Builder::new_multi_thread().enable_all().build().unwrap();
    let statuses = rt.block_on(async {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        let (tx, rx) = tokio::sync::oneshot::channel::<()>();
        let server = tokio::spawn(
            axum::serve(listener, recommended_app())
                .with_graceful_shutdown(async {
                    rx.await.ok();
                })
                .into_future(),
        );
        let mut out = Vec::new();
        for p in ["/v1/projects/7", "/healthz", "/nope", "/boom"] {
            out.push((p, raw_get(addr, p).await));
        }
        tx.send(()).unwrap();
        server.await.unwrap().unwrap();
        out
    });

    let events = cap.take();
    let mut tally: BTreeMap<(String, String), usize> = BTreeMap::new();
    for e in &events {
        *tally.entry((e.target.clone(), e.level.to_string())).or_default() += 1;
    }
    for (p, (s, _)) in &statuses {
        println!("STATUS {p} -> {s}");
    }
    for ((t, l), n) in &tally {
        println!("TALLY target={t} level={l} count={n}");
    }
    let framework_loud: Vec<_> = events
        .iter()
        .filter(|e| {
            let t = e.target.as_str();
            (t.starts_with("axum") || t.starts_with("hyper") || t.starts_with("tower"))
                && t != "tower_http::catch_panic"
                && e.level <= Level::INFO
        })
        .collect();
    let a = access(&events);
    let log_records = LOG_RECORDS.load(Ordering::SeqCst);
    check("F01", "3 http_request events for 4 requests (probe excluded)", a.len() == 3, format!("events={}", a.len()));
    check("F02", "no axum/hyper/tower event at INFO or above besides catch_panic",
        framework_loud.is_empty(), format!("loud={}", framework_loud.len()));
    check("F03", "no `log` records while a tracing subscriber is set", log_records == 0, format!("log_records={log_records}"));
    check("F04", "real-listener statuses", statuses.iter().map(|s| s.1.0.as_str()).collect::<Vec<_>>()
        == ["HTTP/1.1 200 OK", "HTTP/1.1 200 OK", "HTTP/1.1 404 Not Found", "HTTP/1.1 500 Internal Server Error"],
        format!("{statuses:?}"));
    let boom_id = statuses.iter().find(|s| s.0 == "/boom").and_then(|s| s.1.1.clone());
    let hook: Vec<_> = events.iter().filter(|e| e.target == r75probe::PANIC_TARGET).collect();
    check("F05", "panic hook: one ERROR event with message and location, in the request span",
        hook.len() == 1
            && hook[0].level == Level::ERROR
            && hook[0].fields.get("panic_message").map(String::as_str) == Some("boom")
            && hook[0].fields.contains_key("location")
            && boom_id.is_some()
            && hook[0].span_request_id == boom_id,
        format!("hook_events={} fields={:?} span_request_id={:?} response_id={boom_id:?}",
            hook.len(), hook.first().map(|e| &e.fields), hook.first().and_then(|e| e.span_request_id.clone())));
}
EOF

# Resolve once (network only if no lockfile yet), then everything is offline and locked.
if [[ ! -f Cargo.lock ]]; then
  cargo generate-lockfile --quiet
fi
cargo fetch --locked --quiet

echo "== R75 probe crate: $probe"
echo "== generated: $(date -u +%Y-%m-%dT%H:%M:%SZ) (UTC)"
echo "== toolchains: $(rustc --version) | $(rustup run 1.96.0 rustc --version)"
echo "== Cargo.lock sha256: $(shasum -a 256 Cargo.lock | cut -d' ' -f1)"
echo "== source sha256:"
shasum -a 256 Cargo.toml src/lib.rs tests/common/mod.rs tests/acceptance.rs tests/negative.rs tests/foldin.rs
echo "== resolved versions (normal edges, the shipped tree)"
cargo tree --offline --locked -e normal --prefix none \
  | grep -E '^(axum|axum-core|tokio|tower|tower-http|tower-layer|tower-service|tracing|tracing-core|uuid|hyper|hyper-util|http|log) v' \
  | sort -u
echo "== unique packages in the normal tree: $(cargo tree --offline --locked -e normal --prefix none | sed 's/ (\*)$//' | sort -u | wc -l | tr -d ' ')"
echo "== duplicate packages in the normal tree (cargo tree -d -e normal):"
cargo tree --offline --locked -d -e normal || true
echo "== highest declared rust-version among normal-tree packages:"
cargo metadata --offline --locked --format-version 1 \
  | jq -r '.packages[] | select(.rust_version != null) | "\(.rust_version) \(.name) \(.version)"' \
  | sort -V | tail -3
echo "== why tracing has its log feature (cargo tree -e features -i tracing, normal edges):"
cargo tree --offline --locked -e normal,features -i tracing | grep -E 'tracing feature|tower feature "log"|axum feature "tower-log"|axum feature "default"' | sort -u
echo "== hyper features enabled (tracing absent means hyper emits nothing):"
cargo tree --offline --locked -e normal,features -i hyper | grep -E '^hyper v|hyper feature' | sort -u
echo "== tower-http features enabled in the shipped tree:"
cargo tree --offline --locked -e normal,features -i tower-http | grep -E 'tower-http feature' | sort -u
echo "== opentelemetry packages in the normal tree (the traceparent passthrough needs none): $(cargo tree --offline --locked -e normal --prefix none | grep -c '^opentelemetry' || true)"
echo "== tokio \"rt\" feature enabled (tokio::task_local! for the passthrough needs it):"
cargo tree --offline --locked -e normal,features -i tokio | grep -E 'tokio feature "rt"' | sort -u
echo "== packages reachable in the normal tree ONLY through tower-http (full tree minus --prune tower-http):"
comm -23 \
  <(cargo tree --quiet --offline --locked -e normal --prefix none | sed 's/ (\*)$//' | sort -u) \
  <(cargo tree --quiet --offline --locked -e normal --prefix none --prune tower-http | sed 's/ (\*)$//' | sort -u)
