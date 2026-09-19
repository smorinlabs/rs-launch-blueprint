// R80 revision 2 — P1..P6, the conformance measurements the REST API Design
// Standard v2.0.0 makes decidable only by running axum 0.8.9.
//
// P1 and P2 assert the MOVED recommendation (R7.1's Cache-Control).
// P3, P4 and P5 MEASURE axum's out-of-the-box behaviour for three rules the
// framework does not satisfy on its own; each measurement is the evidence
// behind a SHOULD deviation or an obligation handed to another item, and each
// asserts the observed value so the claim cannot drift silently.

use std::path::PathBuf;

use axum::body::{Body, to_bytes};
use axum::http::{Method, Request, StatusCode};
use probe_web::{AppState, Readiness, build_router};
use tower::ServiceExt;

fn state() -> AppState {
    AppState {
        readiness: Readiness::accepting(),
        config_path: PathBuf::from("/nonexistent-r80-probe/config.toml"),
        has_credential: false,
    }
}

async fn call(
    state: AppState,
    method: Method,
    path: &str,
    accept: Option<&str>,
) -> (StatusCode, Vec<(String, String)>, Vec<u8>) {
    let app = build_router(state);
    let mut builder = Request::builder().method(method).uri(path);
    if let Some(value) = accept {
        builder = builder.header("accept", value);
    }
    let response = app.oneshot(builder.body(Body::empty()).unwrap()).await.unwrap();
    let status = response.status();
    let headers = response
        .headers()
        .iter()
        .map(|(k, v)| (k.to_string(), v.to_str().unwrap_or("<non-utf8>").to_string()))
        .collect();
    let bytes = to_bytes(response.into_body(), usize::MAX).await.unwrap().to_vec();
    (status, headers, bytes)
}

fn header<'a>(headers: &'a [(String, String)], name: &str) -> Option<&'a str> {
    headers
        .iter()
        .find(|(k, _)| k == name)
        .map(|(_, v)| v.as_str())
}

#[tokio::test(flavor = "multi_thread")]
async fn p1_liveness_carries_cache_control() {
    let (status, headers, _body) = call(state(), Method::GET, "/healthz", None).await;
    let cc = header(&headers, "cache-control");
    let ct = header(&headers, "content-type");
    println!("P1 GET /healthz status={status} cache-control={cc:?} content-type={ct:?}");
    assert_eq!(status, StatusCode::OK, "P1: liveness still answers 200");
    assert_eq!(
        cc,
        Some("no-cache"),
        "P1 (R7.1): every response MUST carry an explicit Cache-Control header"
    );
    assert_eq!(
        ct,
        Some("application/json"),
        "P1 (R4.10): the default media type is application/json"
    );
}

#[tokio::test(flavor = "multi_thread")]
async fn p2_readiness_carries_cache_control_on_both_branches() {
    let (ok_status, ok_headers, _ok) = call(state(), Method::GET, "/readyz", None).await;
    let draining = state();
    draining.readiness.begin_draining();
    let (bad_status, bad_headers, bad_body) = call(draining, Method::GET, "/readyz", None).await;
    let ok_cc = header(&ok_headers, "cache-control");
    let bad_cc = header(&bad_headers, "cache-control");
    println!("P2 GET /readyz 200-branch cache-control={ok_cc:?}; 503-branch status={bad_status} cache-control={bad_cc:?}");
    assert_eq!(ok_status, StatusCode::OK, "P2: warn-only readiness holds at 200");
    assert_eq!(
        bad_status,
        StatusCode::SERVICE_UNAVAILABLE,
        "P2: the drain latch still answers 503"
    );
    assert_eq!(ok_cc, Some("no-cache"), "P2 (R7.1): 200 branch");
    assert_eq!(bad_cc, Some("no-cache"), "P2 (R7.1): 503 branch — the branch a cache must never serve stale");
    assert!(
        !bad_body.is_empty(),
        "P2: the 503 still carries a body for a human to read"
    );
}

#[tokio::test(flavor = "multi_thread")]
async fn p3_trailing_slash_is_not_redirected_by_axum() {
    // R2.6: a request with a trailing slash SHOULD receive 308 to the canonical
    // form. Measured, not asserted-as-conformant: axum 0.8.9 supplies no such
    // redirect, which is the evidence behind this decision's SHOULD deviation.
    let (status, headers, _body) = call(state(), Method::GET, "/healthz/", None).await;
    let location = header(&headers, "location");
    println!("P3 GET /healthz/ status={status} location={location:?} (R2.6 wants 308)");
    assert_eq!(
        status,
        StatusCode::NOT_FOUND,
        "P3 (R2.6): axum 0.8.9 answers a trailing-slash probe path with 404, not the 308 the rule prefers"
    );
    assert_eq!(location, None, "P3: and sends no Location header");
}

#[tokio::test(flavor = "multi_thread")]
async fn p4_unsatisfiable_accept_is_not_406() {
    // R4.10: a request whose Accept excludes every supported representation
    // SHOULD receive 406. Measured: axum's Json responder ignores Accept.
    let (status, headers, _body) =
        call(state(), Method::GET, "/healthz", Some("application/xml")).await;
    let ct = header(&headers, "content-type");
    println!("P4 GET /healthz Accept: application/xml -> status={status} content-type={ct:?} (R4.10 wants 406)");
    assert_eq!(
        status,
        StatusCode::OK,
        "P4 (R4.10): axum 0.8.9's Json responder ignores Accept and serves JSON rather than 406"
    );
    assert_eq!(ct, Some("application/json"), "P4: and labels it application/json");
}

#[tokio::test(flavor = "multi_thread")]
async fn p5_no_request_id_header_is_emitted_by_the_handlers() {
    // R11.7: every response, including errors, MUST carry the `request-id`
    // correlation header. Measured: the handlers emit none, because the header
    // is middleware's to add — R75's. The measurement is what makes the
    // obligation this decision hands to R75 concrete rather than assumed.
    let (_status, headers, _body) = call(state(), Method::GET, "/healthz", None).await;
    let rid = header(&headers, "request-id");
    let names: Vec<&str> = headers.iter().map(|(k, _)| k.as_str()).collect();
    println!("P5 GET /healthz response headers={names:?} request-id={rid:?} (R11.7 requires it)");
    assert_eq!(
        rid, None,
        "P5 (R11.7): the probe handlers alone emit no request-id; the middleware that adds it is R75's and MUST NOT skip these two paths"
    );
}

#[tokio::test(flavor = "multi_thread")]
async fn p6_method_not_allowed_still_carries_allow() {
    // R5.11 makes T7's observation a standard-bound MUST rather than a nicety.
    let (status, headers, _body) = call(state(), Method::POST, "/healthz", None).await;
    let allow = header(&headers, "allow");
    println!("P6 POST /healthz status={status} allow={allow:?} (R5.11 requires Allow on 405)");
    assert_eq!(status, StatusCode::METHOD_NOT_ALLOWED, "P6: 405");
    assert_eq!(
        allow,
        Some("GET,HEAD"),
        "P6 (R5.11): 405 MUST carry an Allow header, and axum supplies it"
    );
}
