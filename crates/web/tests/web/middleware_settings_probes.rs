//! Integration tests for the fixed-order `tower-http` middleware stack (`R75`),
//! `WebSettings::from_vars()` validation (`R77`, `OV-04`), operational probes `/healthz` and
//! `/readyz` (`R80`, `OV-05`), and real-listener `serve_until` graceful drain (`R69`, `R74`).

use std::ffi::OsString;
use std::fs;
use std::net::{IpAddr, Ipv4Addr};
use std::path::PathBuf;
use std::sync::Arc;
use std::time::Duration;

use axum::Router;
use axum::body::Body;
use axum::http::{HeaderValue, Method, Request, StatusCode, header};
use axum::routing::{get, post};
use rs_launch_blueprint::{
    Check, CheckStatus, Diagnostics, DiagnosticsContext, ErrorCode, InMemoryProjectsPort, LogLevel,
    ProjectsPort, ProjectsService, run_diagnostics,
};
use rs_launch_blueprint_web::{
    AppState, InMemoryRateLimitStore, InboundTraceparent, REQUEST_ID, Readiness, ServeError,
    ServiceLogFormat, ShutdownSignal, TRACEPARENT, WEB_ENV_PREFIX, WEB_ENV_VARS, WebSettings,
    apply_middleware, build_router, inbound_traceparent, serve_until,
};
use tokio::net::TcpListener;
use tower::ServiceExt;

use crate::{CapturingSubscriber, response_json};

fn vars(pairs: &[(&str, &str)]) -> Vec<(OsString, OsString)> {
    pairs
        .iter()
        .map(|(k, v)| (OsString::from(k), OsString::from(v)))
        .collect()
}

fn empty_state() -> AppState {
    let port: Arc<dyn ProjectsPort> = Arc::new(InMemoryProjectsPort::new());
    AppState::for_testing(Arc::new(ProjectsService::new(port)))
}

#[test]
fn web_settings_from_vars_prefix_defaults_validation_and_env_isolation() {
    // AC1: compile-time derived prefix.
    assert_eq!(WEB_ENV_PREFIX, "RSLBP_WEB_");

    // Defaults (R77, R74, R73, R80).
    let def = WebSettings::from_vars(Vec::<(OsString, OsString)>::new()).unwrap();
    assert_eq!(def.host, IpAddr::V4(Ipv4Addr::LOCALHOST));
    assert_eq!(def.port, 8000);
    assert_eq!(def.root_path, "");
    assert_eq!(def.log_level, LogLevel::Info);
    assert_eq!(def.log_format, ServiceLogFormat::Json);
    assert!(def.cors_origins.is_empty());
    assert!(def.metrics_enabled);
    assert!(!def.otel_enabled);
    assert_eq!(def.graceful_shutdown, Duration::from_secs(8));
    assert_eq!(def.readiness_pause, Duration::from_secs(0));
    assert_eq!(def.drain_budget(), Duration::from_secs(8));
    assert_eq!(def.idempotency_ttl, Duration::from_secs(86_400));
    assert_eq!(def.idempotency_max_entries.get(), 1024);

    // AC3: unprefixed and exported-but-empty vars leave defaults intact.
    let ignored = WebSettings::from_vars(vars(&[
        ("PORT", "9999"),
        ("RSLBP_WEB_PORT", ""),
        ("RSLBP_WEB_HOST", ""),
        ("RSLBP_WEB_RATE_LIMIT_PER_IP", ""),
        ("RSLBP_WEB_READINESS_PAUSE_SECONDS", ""),
    ]))
    .unwrap();
    assert_eq!(ignored, def);

    // AC2: malformed port names variable, offending value, and expectation (R77).
    let err = WebSettings::from_vars(vars(&[("RSLBP_WEB_PORT", "eighty")])).unwrap_err();
    assert_eq!(err.error_code(), ErrorCode::ConfigInvalid);
    let msg = err.to_string();
    assert!(msg.contains("RSLBP_WEB_PORT"), "msg: {msg}");
    assert!(msg.contains("eighty"), "msg: {msg}");
    assert!(msg.contains("0..=65535"), "msg: {msg}");

    // Service log format rejects `auto` (R58).
    let auto_err = WebSettings::from_vars(vars(&[("RSLBP_WEB_LOG_FORMAT", "auto")])).unwrap_err();
    assert!(auto_err.to_string().contains("RSLBP_WEB_LOG_FORMAT"));

    // AC12: root_path rejects version segments (/v1, /v2, /v1.0) and accepts /api.
    for bad_root in ["/v1", "/v2", "/v1.0", "/api/v1", "no-leading-slash"] {
        let e = WebSettings::from_vars(vars(&[("RSLBP_WEB_ROOT_PATH", bad_root)])).unwrap_err();
        assert!(
            e.to_string().contains("RSLBP_WEB_ROOT_PATH"),
            "bad root {bad_root}: {e}"
        );
    }
    let ok_root = WebSettings::from_vars(vars(&[("RSLBP_WEB_ROOT_PATH", "/api")])).unwrap();
    assert_eq!(ok_root.root_path, "/api");

    // AC15: readiness pause < graceful_shutdown budget invariant.
    let paused =
        WebSettings::from_vars(vars(&[("RSLBP_WEB_READINESS_PAUSE_SECONDS", "3")])).unwrap();
    assert_eq!(paused.readiness_pause, Duration::from_secs(3));
    assert_eq!(paused.drain_budget(), Duration::from_secs(5));

    let pause_err =
        WebSettings::from_vars(vars(&[("RSLBP_WEB_READINESS_PAUSE_SECONDS", "8")])).unwrap_err();
    let pmsg = pause_err.to_string();
    assert!(
        pmsg.contains("RSLBP_WEB_READINESS_PAUSE_SECONDS")
            && pmsg.contains("RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS")
    );

    // R74: rate limit can never be disabled via env.
    for bad_rl in ["off", "none", "0/second"] {
        assert!(
            WebSettings::from_vars(vars(&[("RSLBP_WEB_RATE_LIMIT_PER_IP", bad_rl)])).is_err(),
            "rate limit must reject {bad_rl}"
        );
    }

    // R70: problem base URI must be https, never http or about:blank.
    for bad_uri in ["http://example.com", "about:blank", "not-a-uri"] {
        assert!(
            WebSettings::from_vars(vars(&[("RSLBP_WEB_PROBLEM_BASE_URI", bad_uri)])).is_err(),
            "problem base URI must reject {bad_uri}"
        );
    }
    let ok_uri = WebSettings::from_vars(vars(&[(
        "RSLBP_WEB_PROBLEM_BASE_URI",
        "https://errors.example.com/problems",
    )]))
    .unwrap();
    assert_eq!(
        ok_uri.problem_base_uri,
        "https://errors.example.com/problems"
    );

    // R76/R77: comma-separated CORS origins; malformed origin rejected.
    let cors = WebSettings::from_vars(vars(&[(
        "RSLBP_WEB_CORS_ORIGINS",
        "https://a.example, https://b.example:8443",
    )]))
    .unwrap();
    assert_eq!(
        cors.cors_origins,
        vec![
            HeaderValue::from_static("https://a.example"),
            HeaderValue::from_static("https://b.example:8443"),
        ]
    );
    assert!(WebSettings::from_vars(vars(&[("RSLBP_WEB_CORS_ORIGINS", "not-an-origin")])).is_err());

    // AC11 + AC13: no secret-shaped variable names and no applicability-switch variable names.
    for &var in WEB_ENV_VARS {
        assert!(var.starts_with(WEB_ENV_PREFIX));
        for forbidden in [
            "TOKEN",
            "SECRET",
            "KEY",
            "PASSWORD",
            "WEBHOOK",
            "ASYNC",
            "BULK",
            "STREAM",
            "API_VERSION",
            "BASE_PATH",
        ] {
            assert!(
                !var.contains(forbidden),
                "WEB_ENV_VARS contains forbidden pattern `{forbidden}` in `{var}`"
            );
        }
    }

    // AC7: process env reads in crates/web are restricted to settings.rs, otel.rs, and the
    // bin/serve.rs entrypoint — never inside HTTP routes, middleware, or handlers.
    let web_src = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("src");
    fn scan(dir: &std::path::Path, hits: &mut Vec<PathBuf>) {
        for entry in fs::read_dir(dir).unwrap() {
            let p = entry.unwrap().path();
            if p.is_dir() {
                scan(&p, hits);
            } else if p.extension().and_then(|e| e.to_str()) == Some("rs") {
                let text = fs::read_to_string(&p).unwrap();
                if text.contains("std::env::var") || text.contains("env::var") {
                    hits.push(p);
                }
            }
        }
    }
    let mut env_hits = Vec::new();
    scan(&web_src, &mut env_hits);
    env_hits.sort();
    let rel_hits: Vec<String> = env_hits
        .iter()
        .map(|p| {
            p.strip_prefix(&web_src)
                .unwrap()
                .to_string_lossy()
                .replace('\\', "/")
        })
        .collect();
    assert_eq!(
        rel_hits,
        vec!["bin/serve.rs", "otel.rs", "settings.rs"],
        "HTTP routes and middleware must never read process env directly: {rel_hits:?}"
    );
}

#[tokio::test]
async fn middleware_stack_request_id_traceparent_security_headers_access_log_panic_timeout_limit() {
    let settings = WebSettings {
        request_timeout: Duration::from_millis(80),
        max_body_bytes: 32,
        ..WebSettings::default()
    };
    let rate_store = Arc::new(InMemoryRateLimitStore::new(64));

    let raw_router = Router::new()
        .route(
            "/trace",
            get(|req: Request<Body>| async move {
                let ext = req
                    .extensions()
                    .get::<InboundTraceparent>()
                    .map(|v| v.0.to_str().unwrap().to_owned());
                let local = inbound_traceparent().map(|v| v.to_str().unwrap().to_owned());
                format!("{ext:?}|{local:?}")
            }),
        )
        .route(
            "/custom-hdr",
            get(|| async { ([(header::X_FRAME_OPTIONS, "SAMEORIGIN")], "ok") }),
        )
        .route(
            "/panic",
            get(|| async {
                panic!("SECRET_HANDLER_PANIC_999");
                #[allow(unreachable_code, reason = "panic test handler return type inference")]
                ""
            }),
        )
        .route(
            "/slow",
            get(|| async {
                tokio::time::sleep(Duration::from_millis(250)).await;
                "late"
            }),
        )
        .route("/echo", post(|body: String| async move { body }))
        .route("/healthz", get(|| async { "ok" }));

    let app = apply_middleware(raw_router, &settings, rate_store);

    // 1. Request-id generated when absent; echoed verbatim when supplied; security headers stamped.
    let res_gen = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/trace")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res_gen.status(), StatusCode::OK);
    let gen_id = res_gen
        .headers()
        .get(REQUEST_ID)
        .expect("must generate request-id")
        .to_str()
        .unwrap();
    assert_eq!(gen_id.len(), 36);
    assert_eq!(
        res_gen
            .headers()
            .get(header::X_CONTENT_TYPE_OPTIONS)
            .unwrap(),
        "nosniff"
    );
    assert_eq!(
        res_gen.headers().get(header::X_FRAME_OPTIONS).unwrap(),
        "DENY"
    );
    assert_eq!(
        res_gen.headers().get(header::REFERRER_POLICY).unwrap(),
        "no-referrer"
    );
    assert_eq!(
        res_gen
            .headers()
            .get(header::STRICT_TRANSPORT_SECURITY)
            .unwrap(),
        "max-age=63072000; includeSubDomains"
    );

    // 2. Handler-set security header wins (if_not_present, R75 F321).
    let res_custom = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/custom-hdr")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(
        res_custom.headers().get(header::X_FRAME_OPTIONS).unwrap(),
        "SAMEORIGIN"
    );

    // 3. Inbound traceparent propagated opaquely via extension AND task_local, NOT echoed on response (R75 L3b).
    let tp = "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa012902b7-01";
    let res_tp = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/trace")
                .header(REQUEST_ID, "caller-req-42")
                .header(TRACEPARENT, tp)
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res_tp.headers().get(REQUEST_ID).unwrap(), "caller-req-42");
    assert!(
        res_tp.headers().get(TRACEPARENT).is_none(),
        "L3b must NOT echo traceparent on response"
    );
    let tp_body = axum::body::to_bytes(res_tp.into_body(), usize::MAX)
        .await
        .unwrap();
    assert_eq!(
        String::from_utf8(tp_body.to_vec()).unwrap(),
        format!("Some(\"{tp}\")|Some(\"{tp}\")")
    );

    // 4. CatchPanicLayer turns handler panic into 500 problem+json with request-id & security headers,
    //    hiding panic message, and logs access event!
    let cap = CapturingSubscriber::new();
    let res_panic = cap
        .capture(
            app.clone().oneshot(
                Request::builder()
                    .uri("/panic")
                    .header(REQUEST_ID, "panic-req-1")
                    .body(Body::empty())
                    .unwrap(),
            ),
        )
        .await
        .unwrap();
    assert_eq!(res_panic.status(), StatusCode::INTERNAL_SERVER_ERROR);
    assert_eq!(res_panic.headers().get(REQUEST_ID).unwrap(), "panic-req-1");
    assert_eq!(
        res_panic.headers().get(header::X_FRAME_OPTIONS).unwrap(),
        "DENY"
    );
    assert_eq!(
        res_panic.headers().get(header::CONTENT_TYPE).unwrap(),
        "application/problem+json"
    );
    let panic_body = response_json(res_panic).await;
    assert!(!panic_body.to_string().contains("SECRET_HANDLER_PANIC_999"));
    assert!(
        cap.events()
            .iter()
            .any(|e| e.target == "rs_launch_blueprint::http_access"
                && e.level == tracing::Level::INFO
                && e.fields.get("request_id").map(String::as_str) == Some("panic-req-1")
                && e.fields.get("status").map(String::as_str) == Some("500")),
        "panic must produce one http_request access event: {:?}",
        cap.events()
    );

    // 5. TimeoutLayer returns 408 problem+json with request-id & security headers.
    let res_timeout = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/slow")
                .header(REQUEST_ID, "slow-req-1")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res_timeout.status(), StatusCode::REQUEST_TIMEOUT);
    assert_eq!(res_timeout.headers().get(REQUEST_ID).unwrap(), "slow-req-1");
    assert_eq!(
        res_timeout.headers().get(header::CONTENT_TYPE).unwrap(),
        "application/problem+json"
    );

    // 6. RequestBodyLimitLayer rejects oversize body with 413 problem+json.
    let res_big = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/echo")
                .body(Body::from("x".repeat(64)))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res_big.status(), StatusCode::PAYLOAD_TOO_LARGE);
    assert_eq!(
        res_big.headers().get(header::CONTENT_TYPE).unwrap(),
        "application/problem+json"
    );

    // 7. Access log excludes matched `/healthz`, but LOGS unmatched `/healthz/` 404 (R75 F320)!
    let cap2 = CapturingSubscriber::new();
    let _ = cap2
        .capture(
            app.clone().oneshot(
                Request::builder()
                    .uri("/healthz?foo=bar")
                    .body(Body::empty())
                    .unwrap(),
            ),
        )
        .await
        .unwrap();
    assert!(
        !cap2
            .events()
            .iter()
            .any(|e| e.target == "rs_launch_blueprint::http_access"),
        "/healthz must be excluded from access logs: {:?}",
        cap2.events()
    );

    let _ = cap2
        .capture(
            app.oneshot(
                Request::builder()
                    .uri("/healthz/")
                    .body(Body::empty())
                    .unwrap(),
            ),
        )
        .await
        .unwrap();
    assert!(
        cap2.events()
            .iter()
            .any(|e| e.target == "rs_launch_blueprint::http_access"
                && e.fields.get("status").map(String::as_str) == Some("404")),
        "unmatched /healthz/ 404 MUST be logged: {:?}",
        cap2.events()
    );
}

#[tokio::test]
async fn probes_healthz_readyz_redaction_and_shutdown_latch() {
    let readiness = Readiness::new();
    let missing_cfg = PathBuf::from("/nonexistent-r80-secret-dir/rslbp_config.toml");
    let cfg_clone = missing_cfg.clone();
    let diag_runner = Arc::new(move || {
        run_diagnostics(&DiagnosticsContext {
            config_path: &cfg_clone,
            token_source: None,
            token_error: None,
        })
    });
    let state = empty_state()
        .with_readiness(readiness.clone())
        .with_diagnostics(diag_runner);
    let app = build_router(state);

    // AC1 & AC2: /healthz 200, byte-stable, exact keys, Cache-Control: no-cache, request-id present.
    let h1 = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/healthz")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(h1.status(), StatusCode::OK);
    assert_eq!(h1.headers().get(header::CACHE_CONTROL).unwrap(), "no-cache");
    assert!(h1.headers().contains_key(REQUEST_ID));
    let b1 = axum::body::to_bytes(h1.into_body(), usize::MAX)
        .await
        .unwrap();

    let h2 = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/healthz")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    let b2 = axum::body::to_bytes(h2.into_body(), usize::MAX)
        .await
        .unwrap();
    assert_eq!(b1, b2, "AC2: /healthz body must be byte-stable");
    let hjson: serde_json::Value = serde_json::from_slice(&b1).unwrap();
    assert_eq!(hjson["status"], "ok");
    assert_eq!(hjson["version"], rs_launch_blueprint::VERSION);
    assert_eq!(hjson["os"], std::env::consts::OS);
    assert_eq!(hjson["arch"], std::env::consts::ARCH);
    assert_eq!(hjson.as_object().unwrap().len(), 4);

    // AC8: HEAD /healthz -> 200; POST /healthz -> 405 with Allow: GET,HEAD.
    let head = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::HEAD)
                .uri("/healthz")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(head.status(), StatusCode::OK);
    let post_h = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/healthz")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(post_h.status(), StatusCode::METHOD_NOT_ALLOWED);
    assert_eq!(post_h.headers().get(header::ALLOW).unwrap(), "GET,HEAD");

    // AC4 + R5.17: missing config & token are `warn` -> /readyz stays 200, NO filesystem paths leaked!
    let r1 = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/readyz")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(r1.status(), StatusCode::OK);
    assert_eq!(r1.headers().get(header::CACHE_CONTROL).unwrap(), "no-cache");
    assert!(r1.headers().contains_key(REQUEST_ID));
    let rjson = response_json(r1).await;
    assert!(
        !rjson.to_string().contains("nonexistent-r80-secret-dir"),
        "R5.17: /readyz must redact filesystem paths: {rjson}"
    );

    // AC6 & AC7: begin_draining() -> /readyz returns 503 problem+json with `diagnostics` extension,
    // while /healthz STILL returns 200!
    readiness.begin_draining();
    let r_drain = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/readyz")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(r_drain.status(), StatusCode::SERVICE_UNAVAILABLE);
    assert_eq!(
        r_drain.headers().get(header::CONTENT_TYPE).unwrap(),
        "application/problem+json"
    );
    assert_eq!(
        r_drain.headers().get(header::CACHE_CONTROL).unwrap(),
        "no-cache"
    );
    let drain_json = response_json(r_drain).await;
    assert_eq!(drain_json["status"], 503);
    assert!(drain_json["diagnostics"]["checks"].is_array());

    let h_after = app
        .oneshot(
            Request::builder()
                .uri("/healthz")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(h_after.status(), StatusCode::OK);

    // AC5: failing diagnostic check yields 503 problem+json carrying `diagnostics` extension.
    let failing_state = empty_state().with_diagnostics(Arc::new(|| Diagnostics {
        checks: vec![Check {
            name: "token",
            status: CheckStatus::Error,
            detail: "/etc/secret/path unreadable".to_owned(),
        }],
    }));
    let failing_app = build_router(failing_state);
    let r_fail = failing_app
        .oneshot(
            Request::builder()
                .uri("/readyz")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(r_fail.status(), StatusCode::SERVICE_UNAVAILABLE);
    assert_eq!(
        r_fail.headers().get(header::CONTENT_TYPE).unwrap(),
        "application/problem+json"
    );
    let fail_json = response_json(r_fail).await;
    assert!(fail_json["diagnostics"]["checks"].is_array());
    assert!(!fail_json.to_string().contains("/etc/secret/path"));
}

#[tokio::test]
async fn serve_until_real_listener_connect_info_readiness_pause_and_drain() {
    let readiness = Readiness::new();
    let app = build_router(empty_state().with_readiness(readiness.clone()));
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    let (sig_tx, sig_rx) = tokio::sync::oneshot::channel::<ShutdownSignal>();
    let srv_readiness = readiness.clone();
    let handle = tokio::spawn(async move {
        serve_until(
            listener,
            app,
            async move { sig_rx.await.unwrap_or(ShutdownSignal::SigTerm) },
            srv_readiness,
            Duration::from_millis(120),
            Duration::from_secs(2),
        )
        .await
    });

    // Helper using std::net::TcpStream on spawn_blocking so crates/web needs no extra tokio/io-util feature.
    async fn http_get(addr: std::net::SocketAddr, path: &str) -> String {
        let path = path.to_owned();
        tokio::task::spawn_blocking(move || {
            use std::io::{Read, Write};
            let mut stream = std::net::TcpStream::connect(addr).unwrap();
            let req =
                format!("GET {path} HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n");
            stream.write_all(req.as_bytes()).unwrap();
            let mut buf = Vec::new();
            stream.read_to_end(&mut buf).unwrap();
            String::from_utf8(buf).unwrap()
        })
        .await
        .unwrap()
    }

    let ok_resp = http_get(addr, "/readyz").await;
    assert!(ok_resp.starts_with("HTTP/1.1 200"), "got: {ok_resp}");

    // Trigger SIGTERM -> readiness latch flips immediately while listener stays open for pause!
    sig_tx.send(ShutdownSignal::SigTerm).unwrap();
    tokio::time::sleep(Duration::from_millis(30)).await;
    let draining_resp = http_get(addr, "/readyz").await;
    assert!(
        draining_resp.starts_with("HTTP/1.1 503"),
        "during readiness_pause, fresh /readyz MUST return 503, got: {draining_resp}"
    );
    let healthz_resp = http_get(addr, "/healthz").await;
    assert!(
        healthz_resp.starts_with("HTTP/1.1 200"),
        "during readiness_pause, /healthz MUST stay 200, got: {healthz_resp}"
    );

    let outcome = handle.await.unwrap().expect("clean drain");
    assert_eq!(outcome, Some(ShutdownSignal::SigTerm));

    // Also test drain deadline expiry -> ServeError::GracefulShutdownTimedOut.
    let listener2 = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr2 = listener2.local_addr().unwrap();
    let (started_tx, started_rx) = tokio::sync::oneshot::channel::<()>();
    let started_tx = Arc::new(std::sync::Mutex::new(Some(started_tx)));
    let slow_app = Router::new().route(
        "/hang",
        get(move || {
            let tx = Arc::clone(&started_tx);
            async move {
                if let Some(ch) = tx.lock().unwrap().take() {
                    let _ = ch.send(());
                }
                tokio::time::sleep(Duration::from_secs(5)).await;
                "done"
            }
        }),
    );
    let (sig2_tx, sig2_rx) = tokio::sync::oneshot::channel::<ShutdownSignal>();
    let handle2 = tokio::spawn(async move {
        serve_until(
            listener2,
            slow_app,
            async move { sig2_rx.await.unwrap_or(ShutdownSignal::SigInt) },
            Readiness::new(),
            Duration::ZERO,
            Duration::from_millis(60),
        )
        .await
    });

    let _client = tokio::spawn(async move {
        let _ = http_get(addr2, "/hang").await;
    });
    started_rx.await.unwrap();
    sig2_tx.send(ShutdownSignal::SigInt).unwrap();
    let err = handle2.await.unwrap().unwrap_err();
    assert!(matches!(err, ServeError::GracefulShutdownTimedOut(_)));
}

#[cfg(feature = "otel")]
#[tokio::test]
async fn otel_middleware_extracts_w3c_traceparent_and_runs_blocking_handlers_cleanly() {
    let app = build_router(empty_state());
    let req = Request::builder()
        .uri("/v1/projects")
        .header(
            TRACEPARENT,
            "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ca902b7-01",
        )
        .body(Body::empty())
        .unwrap();
    let res = app.oneshot(req).await.unwrap();
    assert_eq!(res.status(), StatusCode::OK);
    assert!(
        !res.headers().contains_key(TRACEPARENT),
        "R75: traceparent must never be echoed on responses"
    );
}
