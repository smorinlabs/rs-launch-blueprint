//! Integration and unit tests for owned GCRA rate limiting (`R74`, `OV-17`) and conditional
//! CORS middleware (`R76`, `OV-08`).

use std::net::{IpAddr, Ipv4Addr, SocketAddr};
use std::num::{NonZeroU32, NonZeroUsize};
use std::str::FromStr;
use std::sync::Arc;
use std::time::{Duration, Instant};

use axum::body::Body;
use axum::extract::ConnectInfo;
use axum::http::{HeaderValue, Method, Request, StatusCode, header};
use rs_launch_blueprint_core::{InMemoryProjectsPort, ProjectsPort, ProjectsService};
use rs_launch_blueprint_web::{
    AppState, InMemoryRateLimitStore, RATE_LIMIT_HEADER, RATE_LIMIT_POLICY_HEADER, REQUEST_ID,
    RETRY_AFTER_HEADER, RateLimitKey, RateLimitPolicy, RateLimitStore, WebSettings, build_router,
    retry_after_seconds,
};
use tower::ServiceExt;

use crate::response_json;

fn empty_state() -> AppState {
    let port: Arc<dyn ProjectsPort> = Arc::new(InMemoryProjectsPort::new());
    AppState::for_testing(Arc::new(ProjectsService::new(port)))
}

#[test]
fn rate_limit_policy_grammar_gcra_burst_independence_and_ceiling() {
    // Ceiling arithmetic (R74 B6 / R12.2): never 0, never truncates below true wait.
    assert_eq!(retry_after_seconds(Duration::ZERO), 1);
    assert_eq!(retry_after_seconds(Duration::from_millis(1)), 1);
    assert_eq!(retry_after_seconds(Duration::from_millis(1500)), 2);
    assert_eq!(retry_after_seconds(Duration::from_millis(29_990)), 30);

    // Policy parsing.
    let p = RateLimitPolicy::from_str("100/minute")
        .unwrap()
        .with_burst(NonZeroU32::new(250).unwrap());
    assert_eq!(p.rate().get(), 100);
    assert_eq!(p.period(), Duration::from_secs(60));
    assert_eq!(p.burst().get(), 250);
    assert_eq!(p.policy_header_value(), "\"default\";q=100;w=60");

    for valid in [
        "10/second",
        "5/sec",
        "1/s",
        "60/min",
        "2/m",
        "100/hour",
        "5/hr",
        "1/h",
        "10/day",
        "10/d",
    ] {
        assert!(
            RateLimitPolicy::from_str(valid).is_ok(),
            "should parse {valid}"
        );
    }
    for invalid in [
        "",
        "off",
        "0/second",
        "100",
        "100/fortnight",
        "-5/second",
        "abc/s",
    ] {
        assert!(
            RateLimitPolicy::from_str(invalid).is_err(),
            "should reject {invalid}"
        );
    }

    // Independent sustained rate (10/s) and burst (20) over 10s simulated time -> 120 admissions (R74).
    let store = InMemoryRateLimitStore::new(16);
    let policy = RateLimitPolicy::default(); // 10/second, burst 20
    let start = Instant::now();
    let key = RateLimitKey::Ip(IpAddr::V4(Ipv4Addr::LOCALHOST));
    let mut admitted = 0u32;
    for ms in 0..=10_000u64 {
        if store
            .check(&key, &policy, start + Duration::from_millis(ms))
            .allowed
        {
            admitted += 1;
        }
    }
    assert_eq!(admitted, 120, "10/s with burst 20 over 10s must admit 120");

    // 2/minute with burst 2 refuses 3rd request with Retry-After = 30.
    let store2 = InMemoryRateLimitStore::new(16);
    let two_per_min = RateLimitPolicy::from_str("2/minute")
        .unwrap()
        .with_burst(NonZeroU32::new(2).unwrap());
    assert!(store2.check(&key, &two_per_min, start).allowed);
    assert!(store2.check(&key, &two_per_min, start).allowed);
    let third = store2.check(&key, &two_per_min, start);
    assert!(!third.allowed);
    assert_eq!(third.retry_after_seconds, Some(30));

    // Per-key isolation and bounded capacity (fail open on saturation).
    let bounded = InMemoryRateLimitStore::new(3);
    for octet in 1..=10u8 {
        let k = RateLimitKey::Ip(IpAddr::V4(Ipv4Addr::new(10, 0, 0, octet)));
        assert!(bounded.check(&k, &two_per_min, start).allowed);
    }
    assert!(
        bounded.len() <= 3,
        "store must remain bounded at capacity 3"
    );
}

#[tokio::test]
async fn default_rate_limit_enforces_429_isolates_ips_and_keeps_probes_reachable() {
    let app = build_router(empty_state());
    let ip1 = SocketAddr::from(([198, 51, 100, 1], 40001));
    let ip2 = SocketAddr::from(([198, 51, 100, 2], 40002));

    // Default posture: 10/s, burst 20 -> first 20 admitted, 21st refused with 429!
    for i in 0..20 {
        let mut req = Request::builder()
            .uri("/v1/projects")
            .body(Body::empty())
            .unwrap();
        req.extensions_mut().insert(ConnectInfo(ip1));
        let res = app.clone().oneshot(req).await.unwrap();
        assert_eq!(
            res.status(),
            StatusCode::OK,
            "request {} should pass",
            i + 1
        );
    }

    let mut req21 = Request::builder()
        .uri("/v1/projects")
        .body(Body::empty())
        .unwrap();
    req21.extensions_mut().insert(ConnectInfo(ip1));
    let res21 = app.clone().oneshot(req21).await.unwrap();
    assert_eq!(res21.status(), StatusCode::TOO_MANY_REQUESTS);
    assert_eq!(
        res21.headers().get(header::CONTENT_TYPE).unwrap(),
        "application/problem+json"
    );
    let retry_after: u64 = res21
        .headers()
        .get(RETRY_AFTER_HEADER)
        .expect("429 MUST carry Retry-After (R11.2, R11.5)")
        .to_str()
        .unwrap()
        .parse()
        .unwrap();
    assert!(retry_after >= 1);
    assert_eq!(
        res21.headers().get(RATE_LIMIT_POLICY_HEADER).unwrap(),
        "\"default\";q=10;w=1"
    );
    assert!(res21.headers().contains_key(RATE_LIMIT_HEADER));
    assert!(res21.headers().contains_key(REQUEST_ID));
    // R11.4: no proprietary x-ratelimit-* headers.
    for name in res21.headers().keys() {
        assert!(
            !name.as_str().starts_with("x-ratelimit"),
            "proprietary header forbidden: {name}"
        );
    }
    let body = response_json(res21).await;
    assert_eq!(body["code"], "rate_limit_exceeded");
    assert_eq!(body["status"], 429);

    // Second IP is completely unaffected (B4).
    let mut req_ip2 = Request::builder()
        .uri("/v1/projects")
        .body(Body::empty())
        .unwrap();
    req_ip2.extensions_mut().insert(ConnectInfo(ip2));
    let res_ip2 = app.clone().oneshot(req_ip2).await.unwrap();
    assert_eq!(res_ip2.status(), StatusCode::OK);

    // /healthz and /readyz remain reachable for throttled ip1 (R74 / R80).
    for probe in ["/healthz", "/readyz"] {
        let mut req = Request::builder().uri(probe).body(Body::empty()).unwrap();
        req.extensions_mut().insert(ConnectInfo(ip1));
        let res = app.clone().oneshot(req).await.unwrap();
        assert_eq!(
            res.status(),
            StatusCode::OK,
            "probe {probe} must remain reachable while caller is rate-limited"
        );
    }
}

#[tokio::test]
async fn cors_absent_by_default_and_conforms_with_ov08_when_configured() {
    // 1. Default (empty allowlist): no CORS layer, no Vary, OPTIONS -> 405 with Allow (R76).
    let app_no_cors = build_router(empty_state());
    let res = app_no_cors
        .clone()
        .oneshot(
            Request::builder()
                .uri("/v1/projects")
                .header(header::ORIGIN, "https://app.example.com")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
    assert!(res.headers().get(header::VARY).is_none());
    assert!(
        res.headers()
            .get(header::ACCESS_CONTROL_ALLOW_ORIGIN)
            .is_none()
    );

    let opt = app_no_cors
        .oneshot(
            Request::builder()
                .method(Method::OPTIONS)
                .uri("/v1/projects")
                .header(header::ORIGIN, "https://app.example.com")
                .header(header::ACCESS_CONTROL_REQUEST_METHOD, "GET")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(opt.status(), StatusCode::METHOD_NOT_ALLOWED);
    assert!(opt.headers().contains_key(header::ALLOW));

    // 2. Non-empty allowlist: actual responses expose explicit list, preflight carries request-id +
    //    security headers + max-age 600 and omits expose list (OV-08), cross-origin 429 carries ACAO!
    let settings = WebSettings {
        cors_origins: vec![HeaderValue::from_static("https://app.example.com")],
        rate_limit_per_ip: RateLimitPolicy::from_str("1/minute").unwrap(),
        rate_limit_per_ip_burst: NonZeroU32::new(1).unwrap(),
        rate_limit_max_entries: NonZeroUsize::new(16).unwrap(),
        ..WebSettings::default()
    };
    let app = build_router(empty_state().with_settings(settings));
    let ip = SocketAddr::from(([203, 0, 113, 9], 55555));

    // Preflight OPTIONS.
    let preflight = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::OPTIONS)
                .uri("/v1/projects")
                .header(header::ORIGIN, "https://app.example.com")
                .header(header::ACCESS_CONTROL_REQUEST_METHOD, "POST")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(preflight.status(), StatusCode::OK);
    assert_eq!(
        preflight
            .headers()
            .get(header::ACCESS_CONTROL_ALLOW_ORIGIN)
            .unwrap(),
        "https://app.example.com"
    );
    assert_eq!(
        preflight
            .headers()
            .get(header::ACCESS_CONTROL_MAX_AGE)
            .unwrap(),
        "600"
    );
    // R11.7 + R75: L1/L2 outside L7 -> preflight carries request-id and security headers.
    assert!(preflight.headers().contains_key(REQUEST_ID));
    assert_eq!(
        preflight.headers().get(header::X_FRAME_OPTIONS).unwrap(),
        "DENY"
    );
    // OV-08: preflight carries no Access-Control-Expose-Headers.
    assert!(
        preflight
            .headers()
            .get(header::ACCESS_CONTROL_EXPOSE_HEADERS)
            .is_none()
    );

    // Actual cross-origin GET -> 200 with explicit Access-Control-Expose-Headers (never `*`).
    let mut req1 = Request::builder()
        .uri("/v1/projects")
        .header(header::ORIGIN, "https://app.example.com")
        .body(Body::empty())
        .unwrap();
    req1.extensions_mut().insert(ConnectInfo(ip));
    let actual = app.clone().oneshot(req1).await.unwrap();
    assert_eq!(actual.status(), StatusCode::OK);
    assert_eq!(
        actual
            .headers()
            .get(header::ACCESS_CONTROL_ALLOW_ORIGIN)
            .unwrap(),
        "https://app.example.com"
    );
    assert!(
        actual
            .headers()
            .get(header::VARY)
            .unwrap()
            .to_str()
            .unwrap()
            .to_ascii_lowercase()
            .contains("origin")
    );
    let exposed = actual
        .headers()
        .get(header::ACCESS_CONTROL_EXPOSE_HEADERS)
        .expect("actual response must carry Access-Control-Expose-Headers (R4.17)")
        .to_str()
        .unwrap()
        .to_ascii_lowercase();
    assert_ne!(exposed.trim(), "*");
    for required in [
        "request-id",
        "allow",
        "retry-after",
        "ratelimit",
        "ratelimit-policy",
        "idempotency-replayed",
        "www-authenticate",
    ] {
        assert!(
            exposed.contains(required),
            "exposed headers `{exposed}` missing required `{required}`"
        );
    }

    // Second request from same IP hits rate limit (L8 inside L7 CORS) -> 429 STILL carries ACAO!
    let mut req2 = Request::builder()
        .uri("/v1/projects")
        .header(header::ORIGIN, "https://app.example.com")
        .body(Body::empty())
        .unwrap();
    req2.extensions_mut().insert(ConnectInfo(ip));
    let throttled = app.clone().oneshot(req2).await.unwrap();
    assert_eq!(throttled.status(), StatusCode::TOO_MANY_REQUESTS);
    assert_eq!(
        throttled
            .headers()
            .get(header::ACCESS_CONTROL_ALLOW_ORIGIN)
            .unwrap(),
        "https://app.example.com",
        "R75 L7 outside L8: cross-origin 429 must carry Access-Control-Allow-Origin"
    );

    // Disallowed origin gets no Access-Control-Allow-Origin.
    let mut req_evil = Request::builder()
        .uri("/healthz")
        .header(header::ORIGIN, "https://evil.example")
        .body(Body::empty())
        .unwrap();
    req_evil.extensions_mut().insert(ConnectInfo(ip));
    let evil = app.oneshot(req_evil).await.unwrap();
    assert!(
        evil.headers()
            .get(header::ACCESS_CONTROL_ALLOW_ORIGIN)
            .is_none()
    );
}
