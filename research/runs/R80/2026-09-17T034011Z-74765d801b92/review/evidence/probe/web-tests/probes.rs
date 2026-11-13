// R80 probe workspace — T1 through T8. Run with
// `cargo test --offline -p probe-web --test probes -- --nocapture`.
// Every test asserts on content; a test that only printed would not be evidence.

use std::path::PathBuf;

use axum::body::{Body, to_bytes};
use axum::http::{Method, Request, StatusCode};
use probe_core::{Check, CheckStatus, Diagnostics};
use probe_web::{AppState, Readiness, build_router, readiness_response};
use tower::ServiceExt;

fn state() -> AppState {
    AppState {
        readiness: Readiness::accepting(),
        // A path that cannot exist, so `config-file` is a WARN, never an ERROR.
        config_path: PathBuf::from("/nonexistent-r80-probe/config.toml"),
        has_credential: false,
    }
}

async fn call(state: AppState, method: Method, path: &str) -> (StatusCode, Vec<(String, String)>, Vec<u8>) {
    let app = build_router(state);
    let response = app
        .oneshot(
            Request::builder()
                .method(method)
                .uri(path)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    let status = response.status();
    let headers = response
        .headers()
        .iter()
        .map(|(k, v)| (k.to_string(), v.to_str().unwrap_or("<non-utf8>").to_string()))
        .collect();
    let bytes = to_bytes(response.into_body(), usize::MAX).await.unwrap().to_vec();
    (status, headers, bytes)
}

#[tokio::test(flavor = "multi_thread")]
async fn t1_healthz_200_and_four_fields() {
    let (status, _headers, body) = call(state(), Method::GET, "/healthz").await;
    println!("T1 GET /healthz status={status} body={}", String::from_utf8_lossy(&body));
    assert_eq!(status, StatusCode::OK, "T1: liveness must answer 200");
    let json: serde_json::Value = serde_json::from_slice(&body).expect("T1: body must be JSON");
    assert_eq!(json["status"], "ok", "T1: status field");
    assert_eq!(json["version"], probe_core::VERSION, "T1: version field");
    assert_eq!(json["os"], std::env::consts::OS, "T1: os field");
    assert_eq!(json["arch"], std::env::consts::ARCH, "T1: arch field");
    assert_eq!(
        json.as_object().map(|o| o.len()),
        Some(4),
        "T1: exactly four fields"
    );
}

#[tokio::test(flavor = "multi_thread")]
async fn t2_healthz_body_is_byte_stable() {
    let (_s1, _h1, first) = call(state(), Method::GET, "/healthz").await;
    let (_s2, _h2, second) = call(state(), Method::GET, "/healthz").await;
    println!("T2 byte-stable={}", first == second);
    assert_eq!(first, second, "T2: two liveness bodies must be byte-identical");
}

#[tokio::test(flavor = "multi_thread")]
async fn t3_warn_only_checks_keep_readiness() {
    let (status, _headers, body) = call(state(), Method::GET, "/readyz").await;
    println!("T3 GET /readyz status={status} body={}", String::from_utf8_lossy(&body));
    assert_eq!(
        status,
        StatusCode::OK,
        "T3: a missing config file and a missing credential are WARN, so readiness holds"
    );
    let json: serde_json::Value = serde_json::from_slice(&body).expect("T3: body must be JSON");
    let names: Vec<&str> = json["diagnostics"]["checks"]
        .as_array()
        .expect("T3: checks array")
        .iter()
        .map(|c| c["name"].as_str().expect("T3: check name"))
        .collect();
    assert_eq!(
        names,
        vec!["build", "config-file", "credential"],
        "T3: the ported check set"
    );
    let statuses: Vec<&str> = json["diagnostics"]["checks"]
        .as_array()
        .unwrap()
        .iter()
        .map(|c| c["status"].as_str().unwrap())
        .collect();
    assert_eq!(
        statuses,
        vec!["ok", "warn", "warn"],
        "T3: warn is spelled lowercase on the wire"
    );
}

#[tokio::test(flavor = "multi_thread")]
async fn t4_drain_latch_removes_traffic() {
    let state = state();
    state.readiness.begin_draining();
    let (status, _headers, body) = call(state, Method::GET, "/readyz").await;
    println!("T4 GET /readyz (draining) status={status} body={}", String::from_utf8_lossy(&body));
    assert_eq!(
        status,
        StatusCode::SERVICE_UNAVAILABLE,
        "T4: draining must answer 503"
    );
    let json: serde_json::Value = serde_json::from_slice(&body).expect("T4: body must be JSON");
    assert_eq!(json["status"], "unavailable", "T4: status field");
    assert!(
        json["diagnostics"]["checks"].is_array(),
        "T4: the 503 body still carries the report"
    );
}

#[tokio::test(flavor = "multi_thread")]
async fn t5_draining_is_not_a_restart_signal() {
    let state = state();
    state.readiness.begin_draining();
    let (status, _headers, body) = call(state, Method::GET, "/healthz").await;
    println!("T5 GET /healthz (draining) status={status}");
    assert_eq!(
        status,
        StatusCode::OK,
        "T5: liveness must stay 200 while the process drains"
    );
    let json: serde_json::Value = serde_json::from_slice(&body).unwrap();
    assert_eq!(json["status"], "ok", "T5: liveness still reports ok");
}

#[test]
fn t6_error_report_yields_503_without_touching_the_environment() {
    let report = Diagnostics {
        checks: vec![Check {
            name: "config-file",
            status: CheckStatus::Error,
            detail: "hand-built error, no filesystem read".to_string(),
        }],
    };
    let response = readiness_response(false, report);
    println!("T6 readiness_response(false, <one error check>) status={}", response.status());
    assert_eq!(
        response.status(),
        StatusCode::SERVICE_UNAVAILABLE,
        "T6: one error-level check must answer 503"
    );
}

#[tokio::test(flavor = "multi_thread")]
async fn t7_post_healthz_is_405_with_allow() {
    let (status, headers, _body) = call(state(), Method::POST, "/healthz").await;
    let allow = headers
        .iter()
        .find(|(k, _)| k == "allow")
        .map(|(_, v)| v.clone());
    println!("T7 POST /healthz status={status} allow={allow:?}");
    assert_eq!(
        status,
        StatusCode::METHOD_NOT_ALLOWED,
        "T7: a non-GET method must be 405"
    );
    assert_eq!(
        allow.as_deref(),
        Some("GET,HEAD"),
        "T7: axum's MethodRouter supplies Allow: GET,HEAD"
    );
}

#[tokio::test(flavor = "multi_thread")]
async fn t8_head_is_served_by_the_get_handler() {
    let (status, _headers, body) = call(state(), Method::HEAD, "/healthz").await;
    println!("T8 HEAD /healthz status={status} body_len={}", body.len());
    assert_eq!(status, StatusCode::OK, "T8: HEAD must answer 200");
    assert!(body.is_empty(), "T8: a HEAD response carries no body");
}
