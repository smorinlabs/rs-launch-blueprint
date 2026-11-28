//! Exhaustive edge-case and error-path tests for `crates/web` settings, problem extractors,
//! pagination, idempotency drop/error paths, GCRA rate limiting, probes, and server lifecycle.

use std::ffi::OsString;
use std::net::{IpAddr, Ipv6Addr};
use std::num::{NonZeroU32, NonZeroUsize};
use std::str::FromStr;
use std::sync::Arc;
use std::time::{Duration, Instant};

use axum::Router;
use axum::body::Body;
use axum::extract::FromRef;
use axum::http::{HeaderValue, Method, Request, StatusCode, header};
use axum::response::IntoResponse;
use axum::routing::{get, post};
use rs_launch_blueprint::{
    Diagnostics, DomainError, ErasedProjectsService, ErrorCode, InMemoryProjectsPort, LogLevel,
    PortError, Project, ProjectsPort, ProjectsService,
};
use rs_launch_blueprint_web::{
    AlwaysFreshIdempotencyStore, AppState, ClaimToken, CompletedOutcome, DEFAULT_PROBLEM_BASE_URI,
    DiagnosticsRunner, IDEMPOTENCY_KEY_HEADER, IdempotencyBegin, IdempotencyCacheKey,
    IdempotencyConfig, IdempotencyStore, InMemoryIdempotencyStore, InMemoryRateLimitStore,
    PaginationLimits, PayloadFingerprint, ProblemJson, ProblemPath, ProblemQuery, ProblemSource,
    RateLimitKey, RateLimitPolicy, RateLimitStore, Readiness, ServeError, ServiceLogFormat,
    ShutdownSignal, StoreDispatch, WebError, WebSettings, apply_idempotency, build_router,
    decode_cursor, encode_cursor, install_rate_limit, run_server_blocking, serve_until,
};
use serde::Deserialize;
use tokio::net::TcpListener;
use tower::ServiceExt;

use crate::response_json;

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
fn settings_covers_every_env_var_valid_invalid_and_non_utf8() {
    // Valid values for all 19 RSLBP_WEB_* variables.
    let all = WebSettings::from_vars(vars(&[
        ("RSLBP_WEB_HOST", "::1"),
        ("RSLBP_WEB_PORT", "9090"),
        ("RSLBP_WEB_ROOT_PATH", "/api/internal"),
        ("RSLBP_WEB_LOG_LEVEL", "debug"),
        ("RSLBP_WEB_LOG_FORMAT", "console"),
        (
            "RSLBP_WEB_CORS_ORIGINS",
            "http://localhost:3000, ,https://a.example",
        ),
        ("RSLBP_WEB_REQUEST_TIMEOUT_SECONDS", "45"),
        ("RSLBP_WEB_MAX_BODY_BYTES", "2097152"),
        ("RSLBP_WEB_RATE_LIMIT_PER_IP", "50/minute"),
        ("RSLBP_WEB_RATE_LIMIT_PER_IP_BURST", "75"),
        ("RSLBP_WEB_RATE_LIMIT_MAX_ENTRIES", "500"),
        ("RSLBP_WEB_IDEMPOTENCY_TTL_SECONDS", "3600"),
        ("RSLBP_WEB_IDEMPOTENCY_IN_FLIGHT_SECONDS", "90"),
        ("RSLBP_WEB_IDEMPOTENCY_MAX_ENTRIES", "256"),
        (
            "RSLBP_WEB_PROBLEM_BASE_URI",
            "https://errors.example.com/p/",
        ),
        ("RSLBP_WEB_METRICS_ENABLED", "0"),
        ("RSLBP_WEB_OTEL_ENABLED", "1"),
        ("RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS", "15"),
        ("RSLBP_WEB_READINESS_PAUSE_SECONDS", "4"),
    ]))
    .expect("all valid env vars");
    assert_eq!(all.host, IpAddr::V6(Ipv6Addr::LOCALHOST));
    assert_eq!(all.port, 9090);
    assert_eq!(all.bind_addr().port(), 9090);
    assert_eq!(all.root_path, "/api/internal");
    assert_eq!(all.log_level, LogLevel::Debug);
    assert_eq!(all.log_format, ServiceLogFormat::Console);
    assert_eq!(all.cors_origins.len(), 2);
    assert_eq!(all.request_timeout, Duration::from_secs(45));
    assert_eq!(all.max_body_bytes, 2_097_152);
    assert_eq!(all.effective_rate_limit_policy().burst().get(), 75);
    assert_eq!(all.rate_limit_max_entries.get(), 500);
    assert_eq!(all.idempotency_ttl, Duration::from_secs(3600));
    assert_eq!(all.idempotency_in_flight, Duration::from_secs(90));
    assert_eq!(all.idempotency_max_entries.get(), 256);
    assert_eq!(all.problem_base_uri, "https://errors.example.com/p");
    assert!(!all.metrics_enabled);
    assert!(all.otel_enabled);
    assert_eq!(all.drain_budget(), Duration::from_secs(11));

    // Also test bool "true"/"false" spellings.
    let bools = WebSettings::from_vars(vars(&[
        ("RSLBP_WEB_METRICS_ENABLED", "true"),
        ("RSLBP_WEB_OTEL_ENABLED", "false"),
    ]))
    .unwrap();
    assert!(bools.metrics_enabled);
    assert!(!bools.otel_enabled);

    // Invalid values for every validated field.
    for (k, v) in [
        ("RSLBP_WEB_HOST", "not-an-ip"),
        ("RSLBP_WEB_PORT", "99999"),
        ("RSLBP_WEB_ROOT_PATH", "/"),
        ("RSLBP_WEB_ROOT_PATH", "/api/"),
        ("RSLBP_WEB_ROOT_PATH", "/a//b"),
        ("RSLBP_WEB_LOG_LEVEL", "verbose"),
        ("RSLBP_WEB_LOG_FORMAT", "xml"),
        ("RSLBP_WEB_CORS_ORIGINS", "https://a.example/path"),
        ("RSLBP_WEB_CORS_ORIGINS", "https://bad\r\nheader"),
        ("RSLBP_WEB_CORS_ORIGINS", "https://bad\x7fheader"),
        ("RSLBP_WEB_REQUEST_TIMEOUT_SECONDS", "0"),
        ("RSLBP_WEB_MAX_BODY_BYTES", "0"),
        ("RSLBP_WEB_RATE_LIMIT_PER_IP_BURST", "0"),
        ("RSLBP_WEB_RATE_LIMIT_MAX_ENTRIES", "0"),
        ("RSLBP_WEB_IDEMPOTENCY_TTL_SECONDS", "0"),
        ("RSLBP_WEB_IDEMPOTENCY_IN_FLIGHT_SECONDS", "0"),
        ("RSLBP_WEB_IDEMPOTENCY_MAX_ENTRIES", "0"),
        ("RSLBP_WEB_PROBLEM_BASE_URI", "https://"),
        ("RSLBP_WEB_PROBLEM_BASE_URI", "https://ex.com?q=1"),
        ("RSLBP_WEB_METRICS_ENABLED", "maybe"),
        ("RSLBP_WEB_OTEL_ENABLED", "yes"),
        ("RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS", "0"),
        ("RSLBP_WEB_READINESS_PAUSE_SECONDS", "-1"),
    ] {
        let err = WebSettings::from_vars(vars(&[(k, v)])).unwrap_err();
        assert_eq!(err.error_code(), ErrorCode::ConfigInvalid);
        assert!(err.to_string().contains(k), "expected {k} in {err}");
    }

    // Non-UTF-8 value on prefixed key fails; non-UTF-8 key is skipped.
    #[cfg(unix)]
    {
        use std::os::unix::ffi::OsStringExt;
        let bad_val = OsString::from_vec(vec![0xff, 0xfe]);
        let bad_key = OsString::from_vec(vec![0xff, 0xfe]);
        let err =
            WebSettings::from_vars(vec![(OsString::from("RSLBP_WEB_PORT"), bad_val)]).unwrap_err();
        assert!(err.to_string().contains("non-UTF-8"));
        assert!(WebSettings::from_vars(vec![(bad_key, OsString::from("ignored"))]).is_ok());
    }

    // Exercise from_env() cleanly (assuming CI/dev env has valid or unset RSLBP_WEB_*).
    let _ = WebSettings::from_env();
}

#[tokio::test]
async fn problems_extractors_accessors_and_edge_cases() {
    // ProblemSource trait, Display, accessors, with_instance, with_base_uri, catalog JSON serialize.
    let domain = DomainError::NotFound {
        kind: "project",
        id: "p1".to_owned(),
    };
    let err = domain
        .to_web_error(DEFAULT_PROBLEM_BASE_URI, Some(""))
        .with_instance("/v1/projects/p1?secret=1")
        .with_base_uri("https://custom.example.com");
    assert_eq!(err.status(), StatusCode::NOT_FOUND);
    assert_eq!(err.code(), "resource_not_found");
    assert_eq!(err.catalog_code(), "RSLB301");
    assert!(err.to_string().contains("404 resource_not_found (RSLB301)"));

    let catalog = rs_launch_blueprint_web::problem_catalog(DEFAULT_PROBLEM_BASE_URI);
    let catalog_json = serde_json::to_value(&catalog).unwrap();
    assert_eq!(catalog_json.as_array().unwrap().len(), ErrorCode::ALL.len());

    // Cover unauthorized / service_unavailable default_safe_detail branches.
    let rej = WebError::from_domain(
        &DomainError::Port(PortError::Unauthorized {
            detail: "bad token".to_owned(),
            source: None,
        }),
        DEFAULT_PROBLEM_BASE_URI,
        None,
    );
    let rej_body = response_json(rej.into_response()).await;
    assert_eq!(rej_body["status"], 401);
    assert!(!rej_body.to_string().contains("bad token"));

    // Cover ProblemPath, ProblemQuery, ProblemJson (missing field pointer & missing params).
    #[derive(Deserialize)]
    struct QueryParams {
        #[allow(dead_code, reason = "deserialization target for ProblemQuery test")]
        count: u32,
    }
    #[derive(Deserialize)]
    struct BodyPayload {
        #[allow(dead_code, reason = "deserialization target for ProblemJson test")]
        required_field: String,
    }

    let state = empty_state();
    let app = Router::new()
        .route(
            "/num/{n}",
            get(|ProblemPath(n): ProblemPath<u32>| async move { n.to_string() }),
        )
        .route(
            "/missing-param",
            get(|ProblemPath(n): ProblemPath<u32>| async move { n.to_string() }),
        )
        .route(
            "/q",
            get(|ProblemQuery(q): ProblemQuery<QueryParams>| async move { q.count.to_string() }),
        )
        .route(
            "/j",
            post(|ProblemJson(b): ProblemJson<BodyPayload>| async move { b.required_field }),
        )
        .with_state(state);

    // Valid & invalid ProblemPath.
    let ok_p = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/num/42")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(ok_p.status(), StatusCode::OK);
    let bad_p = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/num/abc")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(bad_p.status(), StatusCode::BAD_REQUEST);
    let miss_p = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/missing-param")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(miss_p.status(), StatusCode::BAD_REQUEST);
    let (mut bare_parts, _) = Request::builder()
        .uri("/bare")
        .body(Body::empty())
        .unwrap()
        .into_parts();
    let missing_err =
        <ProblemPath<u32> as axum::extract::FromRequestParts<AppState>>::from_request_parts(
            &mut bare_parts,
            &empty_state(),
        )
        .await
        .unwrap_err();
    assert_eq!(missing_err.status(), StatusCode::INTERNAL_SERVER_ERROR);

    // Valid & invalid ProblemQuery.
    let ok_q = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/q?count=7")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(ok_q.status(), StatusCode::OK);
    let bad_q = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/q?count=notnum")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(bad_q.status(), StatusCode::BAD_REQUEST);

    // ProblemJson missing field extracts safe `/required_field` pointer, and failing body hits BytesRejection.
    let miss_j = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/j")
                .header(header::CONTENT_TYPE, "application/json")
                .body(Body::from("{}"))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(miss_j.status(), StatusCode::UNPROCESSABLE_ENTITY);
    let body = response_json(miss_j).await;
    assert_eq!(body["errors"][0]["pointer"], "/required_field");

    struct FailingBody;
    impl http_body::Body for FailingBody {
        type Data = axum::body::Bytes;
        type Error = std::io::Error;
        fn poll_frame(
            self: std::pin::Pin<&mut Self>,
            _cx: &mut std::task::Context<'_>,
        ) -> std::task::Poll<Option<Result<http_body::Frame<Self::Data>, Self::Error>>> {
            std::task::Poll::Ready(Some(Err(std::io::Error::other("read failed"))))
        }
    }
    let bad_body_j = app
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/j")
                .header(header::CONTENT_TYPE, "application/json")
                .body(Body::new(FailingBody))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(bad_body_j.status(), StatusCode::BAD_REQUEST);

    // Cancelled spawn_blocking task JoinError branch.
    let task = tokio::task::spawn_blocking(|| {
        std::thread::sleep(Duration::from_secs(5));
    });
    task.abort();
    if let Err(je) = task.await {
        let we = rs_launch_blueprint_web::join_error_to_web_error(
            je,
            DEFAULT_PROBLEM_BASE_URI,
            "/cancel",
        );
        assert_eq!(we.status(), StatusCode::INTERNAL_SERVER_ERROR);
    }
}

#[tokio::test]
async fn pagination_and_projects_query_error_edges() {
    // Non-UTF-8 base64 cursor, Limit::get(), and percent_decode '+' + uppercase hex.
    let bad_utf8 = base64::Engine::encode(
        &base64::engine::general_purpose::URL_SAFE_NO_PAD,
        [0xff, 0xfe],
    );
    assert!(decode_cursor(&bad_utf8).is_err());
    assert!(decode_cursor("").is_err());
    assert_eq!(decode_cursor(&encode_cursor("ok")).unwrap(), "ok");

    let (mut p_parts, _) = Request::builder()
        .uri("/v1/projects?limit=15")
        .body(Body::empty())
        .unwrap()
        .into_parts();
    let rs_launch_blueprint_web::Pagination(page_req) =
        <rs_launch_blueprint_web::Pagination as axum::extract::FromRequestParts<AppState>>::from_request_parts(
            &mut p_parts,
            &empty_state(),
        )
        .await
        .unwrap();
    assert_eq!(page_req.limit.get(), 15);

    let port = Arc::new(InMemoryProjectsPort::with_projects(vec![Project {
        id: "p1".to_owned(),
        name: "One".to_owned(),
        workspace: Some("eng".to_owned()),
    }]));
    let app = build_router(AppState::for_testing(Arc::new(ProjectsService::new(
        Arc::clone(&port) as Arc<dyn ProjectsPort>,
    ))));

    // Duplicate limit, duplicate cursor, duplicate workspace, invalid percent-encoding, stream on GET/{id}.
    for uri in [
        "/v1/projects?limit=1&limit=2",
        "/v1/projects?cursor=YQ&cursor=Yg",
        "/v1/projects?workspace=a&workspace=b",
        "/v1/projects?workspace=%ZZ",
        "/v1/projects?limit=%2",
        "/v1/projects?workspace=eng&",
        "/v1/projects?workspace=a+b%3AC",
        "/v1/projects/p1?stream=true",
        "/v1/projects/p1?bad=%ZZ",
    ] {
        let res = app
            .clone()
            .oneshot(Request::builder().uri(uri).body(Body::empty()).unwrap())
            .await
            .unwrap();
        if uri == "/v1/projects?workspace=eng&" || uri == "/v1/projects?workspace=a+b%3AC" {
            assert_eq!(res.status(), StatusCode::OK);
        } else {
            assert_eq!(res.status(), StatusCode::BAD_REQUEST, "uri: {uri}");
        }
    }

    // Service failure on POST create and DELETE -> 500 problem+json.
    port.set_failure(Some("db down".to_owned())).unwrap();
    let res_post = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/v1/projects")
                .header(header::CONTENT_TYPE, "application/json")
                .body(Body::from(r#"{"name":"Fail"}"#))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res_post.status(), StatusCode::INTERNAL_SERVER_ERROR);

    let res_del = app
        .oneshot(
            Request::builder()
                .method(Method::DELETE)
                .uri("/v1/projects/p1")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res_del.status(), StatusCode::INTERNAL_SERVER_ERROR);
}

struct FailingIdempotencyStore {
    fail_begin: bool,
    fail_complete: bool,
    fail_abandon: bool,
}

impl IdempotencyStore for FailingIdempotencyStore {
    fn begin(
        &self,
        _key: &IdempotencyCacheKey,
        _fingerprint: PayloadFingerprint,
    ) -> Result<IdempotencyBegin, PortError> {
        if self.fail_begin {
            Err(PortError::Unavailable {
                detail: "store down".to_owned(),
            })
        } else {
            Ok(IdempotencyBegin::Fresh(ClaimToken::new(1)))
        }
    }

    fn complete(
        &self,
        _key: &IdempotencyCacheKey,
        _token: ClaimToken,
        _outcome: CompletedOutcome,
    ) -> Result<bool, PortError> {
        if self.fail_complete {
            Err(PortError::Unavailable {
                detail: "complete failed".to_owned(),
            })
        } else {
            Ok(true)
        }
    }

    fn abandon(&self, _key: &IdempotencyCacheKey, _token: ClaimToken) -> Result<bool, PortError> {
        if self.fail_abandon {
            Err(PortError::Unavailable {
                detail: "abandon failed".to_owned(),
            })
        } else {
            Ok(true)
        }
    }
}

#[tokio::test]
async fn idempotency_error_non_2xx_abandon_drop_guard_and_debug_paths() {
    let inline = StoreDispatch::Inline(Arc::new(AlwaysFreshIdempotencyStore::new()));
    let offload = StoreDispatch::Offload(Arc::new(AlwaysFreshIdempotencyStore::new()));
    assert!(format!("{inline:?}").contains("Inline"));
    assert!(format!("{offload:?}").contains("Offload"));

    // Failing begin -> 503.
    let fail_begin_app = apply_idempotency(
        Router::new().route("/x", post(|| async { (StatusCode::CREATED, "ok") })),
        IdempotencyConfig {
            dispatch: StoreDispatch::Inline(Arc::new(FailingIdempotencyStore {
                fail_begin: true,
                fail_complete: false,
                fail_abandon: false,
            })),
            max_body_bytes: 1024,
            problem_base_uri: DEFAULT_PROBLEM_BASE_URI.to_owned(),
        },
    );
    let res = fail_begin_app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/x")
                .header(IDEMPOTENCY_KEY_HEADER, "k1")
                .body(Body::from("hi"))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::SERVICE_UNAVAILABLE);

    // Non-UTF-8 Idempotency-Key header -> 400.
    let bad_hdr = HeaderValue::from_bytes(&[0xff]).unwrap();
    let res_hdr = fail_begin_app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/x")
                .header(IDEMPOTENCY_KEY_HEADER, bad_hdr)
                .body(Body::from("hi"))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res_hdr.status(), StatusCode::BAD_REQUEST);

    // Invalid percent-encoding in query with Idempotency-Key -> 400.
    let res_q = fail_begin_app
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/x?a=%ZZ")
                .header(IDEMPOTENCY_KEY_HEADER, "k-q")
                .body(Body::from("hi"))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res_q.status(), StatusCode::BAD_REQUEST);

    // Non-2xx response triggers abandon (and logs warn if abandon errors), and failing complete still returns 2xx.
    for dispatch_mode in [false, true] {
        let store: Arc<dyn IdempotencyStore> = Arc::new(FailingIdempotencyStore {
            fail_begin: false,
            fail_complete: true,
            fail_abandon: true,
        });
        let dispatch = if dispatch_mode {
            StoreDispatch::Offload(store)
        } else {
            StoreDispatch::Inline(store)
        };
        let app = apply_idempotency(
            Router::new()
                .route("/ok", post(|| async { (StatusCode::CREATED, "ok") }))
                .route(
                    "/big",
                    post(|| async { (StatusCode::CREATED, "0123456789abcdef_oversize") }),
                )
                .route("/err", post(|| async { StatusCode::BAD_REQUEST }))
                .route(
                    "/hang",
                    post(|| async {
                        tokio::time::sleep(Duration::from_secs(5)).await;
                        "never"
                    }),
                ),
            IdempotencyConfig {
                dispatch,
                max_body_bytes: 8,
                problem_base_uri: DEFAULT_PROBLEM_BASE_URI.to_owned(),
            },
        );
        assert_eq!(
            app.clone()
                .oneshot(
                    Request::builder()
                        .method(Method::POST)
                        .uri("/ok")
                        .header(IDEMPOTENCY_KEY_HEADER, "k-ok")
                        .body(Body::from("a"))
                        .unwrap()
                )
                .await
                .unwrap()
                .status(),
            StatusCode::CREATED
        );
        assert_eq!(
            app.clone()
                .oneshot(
                    Request::builder()
                        .method(Method::POST)
                        .uri("/big")
                        .header(IDEMPOTENCY_KEY_HEADER, "k-big")
                        .body(Body::from("a"))
                        .unwrap()
                )
                .await
                .unwrap()
                .status(),
            StatusCode::CREATED
        );
        assert_eq!(
            app.clone()
                .oneshot(
                    Request::builder()
                        .method(Method::POST)
                        .uri("/err")
                        .header(IDEMPOTENCY_KEY_HEADER, "k-err")
                        .body(Body::from("a"))
                        .unwrap()
                )
                .await
                .unwrap()
                .status(),
            StatusCode::BAD_REQUEST
        );

        // Cancel in-flight request to exercise AbandonOnDrop for both Inline & Offload!
        let fut = app.clone().oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/hang")
                .header(IDEMPOTENCY_KEY_HEADER, "k-drop")
                .body(Body::from("a"))
                .unwrap(),
        );
        let _ = tokio::time::timeout(Duration::from_millis(20), fut).await;
        tokio::time::sleep(Duration::from_millis(20)).await;
    }

    // Stream error inside 2xx response marks claim Unreplayable and forwards body stream.
    struct ErrorStreamBody;
    impl http_body::Body for ErrorStreamBody {
        type Data = axum::body::Bytes;
        type Error = std::io::Error;
        fn poll_frame(
            self: std::pin::Pin<&mut Self>,
            _cx: &mut std::task::Context<'_>,
        ) -> std::task::Poll<Option<Result<http_body::Frame<Self::Data>, Self::Error>>> {
            std::task::Poll::Ready(Some(Err(std::io::Error::other("stream broken"))))
        }
    }
    let stream_err_app = apply_idempotency(
        Router::new().route(
            "/broken-stream",
            post(|| async {
                axum::http::Response::builder()
                    .status(StatusCode::CREATED)
                    .body(Body::new(ErrorStreamBody))
                    .unwrap()
            }),
        ),
        IdempotencyConfig {
            dispatch: StoreDispatch::Inline(Arc::new(AlwaysFreshIdempotencyStore::new())),
            max_body_bytes: 128,
            problem_base_uri: DEFAULT_PROBLEM_BASE_URI.to_owned(),
        },
    );
    let broken_res = stream_err_app
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/broken-stream")
                .header(IDEMPOTENCY_KEY_HEADER, "k-stream-err")
                .body(Body::from("a"))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(broken_res.status(), StatusCode::CREATED);
}

#[tokio::test]
async fn rate_limit_ops_and_server_state_builder_edges() {
    // RateLimitPolicy extra slash & InMemoryRateLimitStore Default/is_empty/Arc impl/install_rate_limit.
    assert!(RateLimitPolicy::from_str("1/2/s").is_err());
    let store = Arc::new(InMemoryRateLimitStore::default());
    assert!(store.is_empty());
    let policy = RateLimitPolicy::default();
    let dec = RateLimitStore::check(&store, &RateLimitKey::Global, &policy, Instant::now());
    assert!(dec.allowed);
    assert!(!store.is_empty());

    // Bounded store sweeps expired entries before failing open.
    let small = InMemoryRateLimitStore::new(1);
    let t0 = Instant::now();
    let p = RateLimitPolicy::from_str("10/second")
        .unwrap()
        .with_burst(NonZeroU32::new(1).unwrap());
    assert!(small.check(&RateLimitKey::Global, &p, t0).allowed);
    assert!(
        small
            .check(
                &RateLimitKey::Ip(IpAddr::V6(Ipv6Addr::LOCALHOST)),
                &p,
                t0 + Duration::from_secs(5),
            )
            .allowed
    );
    assert_eq!(small.len(), 1);

    // install_rate_limit convenience wrapper.
    let rl_app = install_rate_limit(
        Router::new().route("/ping", get(|| async { "pong" })),
        Arc::new(InMemoryRateLimitStore::new(8)),
        policy,
    );
    let ping = rl_app
        .oneshot(Request::builder().uri("/ping").body(Body::empty()).unwrap())
        .await
        .unwrap();
    assert_eq!(ping.status(), StatusCode::OK);

    // Readiness::default & panicking diagnostics runner on /readyz -> 500 redacted problem+json.
    let r_def = Readiness::default();
    assert!(r_def.is_ready());
    let panic_state = empty_state().with_diagnostics(Arc::new(|| {
        panic!("DIAG_SECRET_PANIC");
    }));
    let panic_app = build_router(panic_state);
    let res = panic_app
        .oneshot(
            Request::builder()
                .uri("/readyz")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::INTERNAL_SERVER_ERROR);
    let body = response_json(res).await;
    assert!(!body.to_string().contains("DIAG_SECRET_PANIC"));

    // AppState Debug, builders, and FromRef impls.
    let st = empty_state()
        .with_pagination(PaginationLimits {
            default_limit: NonZeroU32::new(10).unwrap(),
            max_limit: NonZeroU32::new(50).unwrap(),
        })
        .with_idempotency(Arc::new(InMemoryIdempotencyStore::default()))
        .with_rate_limit(Arc::new(InMemoryRateLimitStore::new(
            NonZeroUsize::new(8).unwrap().get(),
        )));
    assert!(format!("{st:?}").contains("AppState"));
    let _svc: Arc<ErasedProjectsService> = FromRef::from_ref(&st);
    let _idem: Arc<dyn IdempotencyStore> = FromRef::from_ref(&st);
    let _rl: Arc<dyn RateLimitStore> = FromRef::from_ref(&st);
    let _diag: DiagnosticsRunner = FromRef::from_ref(&st);
    let _ = Diagnostics { checks: Vec::new() };

    // ShutdownSignal::exit mappings & run_server_blocking bind error when port is occupied.
    assert_eq!(
        ShutdownSignal::SigInt.exit(),
        rs_launch_blueprint_web::Exit::SigInt
    );
    assert_eq!(
        ShutdownSignal::SigTerm.exit(),
        rs_launch_blueprint_web::Exit::SigTerm
    );

    let occupied = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let occupied_port = occupied.local_addr().unwrap().port();
    let bind_err = tokio::task::spawn_blocking(move || {
        let s = WebSettings {
            port: occupied_port,
            ..WebSettings::default()
        };
        run_server_blocking(empty_state().with_settings(s))
    })
    .await
    .unwrap()
    .unwrap_err();
    assert!(matches!(bind_err, ServeError::Bind { .. }));
    assert!(bind_err.to_string().contains("failed to bind"));
    drop(occupied);

    // serve_until with zero readiness_pause clean shutdown.
    let l = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let out = serve_until(
        l,
        Router::new(),
        async { ShutdownSignal::SigInt },
        Readiness::new(),
        Duration::ZERO,
        Duration::from_secs(1),
    )
    .await
    .unwrap();
    assert_eq!(out, Some(ShutdownSignal::SigInt));
}
