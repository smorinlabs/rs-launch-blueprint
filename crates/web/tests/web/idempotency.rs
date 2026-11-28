//! Unit and integration tests for `IdempotencyStore` (`crates/core`) and `Idempotency-Key`
//! replay middleware (`crates/web`, `R73`, criteria `s01`–`s10`, `w01`–`w17`, 21, 23–27).

use std::sync::Arc;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::{Duration, Instant};

use axum::Router;
use axum::body::Body;
use axum::http::{HeaderValue, Method, Request, StatusCode, header};
use axum::routing::{get, post};
use rs_launch_blueprint::{InMemoryProjectsPort, PortError, ProjectsPort, ProjectsService};
use rs_launch_blueprint_web::{
    AlwaysFreshIdempotencyStore, AppState, CachedResponse, CompletedOutcome,
    DEFAULT_PROBLEM_BASE_URI, FakeClock, IDEMPOTENCY_KEY_HEADER, IDEMPOTENCY_REPLAYED_HEADER,
    IdempotencyBegin, IdempotencyCacheKey, IdempotencyConfig, IdempotencyStore,
    InMemoryIdempotencyStore, REQUEST_ID, StoreDispatch, apply_idempotency, build_router,
    compute_fingerprint,
};
use tower::ServiceExt;

use crate::response_json;

fn key(id: &str) -> IdempotencyCacheKey {
    IdempotencyCacheKey {
        method: "POST".to_owned(),
        path: "/v1/projects".to_owned(),
        query: String::new(),
        idempotency_key: id.to_owned(),
    }
}

fn cached_201(body: &[u8]) -> CachedResponse {
    CachedResponse {
        status: 201,
        headers: vec![("content-type".to_owned(), b"application/json".to_vec())],
        body: body.to_vec(),
    }
}

#[test]
fn sha256_fingerprint_matches_known_nist_test_vector() {
    // R73 criterion 21: pinned SHA-256 vector for `"abc"`.
    let digest = compute_fingerprint(b"abc");
    let hex: String = digest.iter().map(|b| format!("{b:02x}")).collect();
    assert_eq!(
        hex,
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
    );
}

#[test]
fn in_memory_idempotency_store_contract_cas_ttl_lru_claim_tokens_and_poison() {
    let clock = Arc::new(FakeClock::new(Instant::now()));
    let store = InMemoryIdempotencyStore::with_clock(
        Duration::from_secs(60),
        Duration::from_secs(5),
        3,
        Arc::clone(&clock),
    );
    let fp1 = compute_fingerprint(b"payload-1");
    let fp2 = compute_fingerprint(b"payload-2");

    // s01/s02: fresh claim, in-flight conflict, payload mismatch, completion, replay.
    let k1 = key("k1");
    let token1 = match store.begin(&k1, fp1).unwrap() {
        IdempotencyBegin::Fresh(t) => t,
        other => panic!("expected Fresh, got {other:?}"),
    };
    assert_eq!(store.begin(&k1, fp1).unwrap(), IdempotencyBegin::InFlight);
    assert_eq!(store.begin(&k1, fp2).unwrap(), IdempotencyBegin::Mismatch);
    assert!(
        store
            .complete(&k1, token1, CompletedOutcome::Replayable(cached_201(b"ok")))
            .unwrap()
    );
    assert_eq!(
        store.begin(&k1, fp1).unwrap(),
        IdempotencyBegin::Replay(cached_201(b"ok"))
    );
    assert_eq!(store.begin(&k1, fp2).unwrap(), IdempotencyBegin::Mismatch);

    // s04: TTL boundary ±1 ms.
    clock.advance(Duration::from_millis(59_999));
    assert!(matches!(
        store.begin(&k1, fp1).unwrap(),
        IdempotencyBegin::Replay(_)
    ));
    clock.advance(Duration::from_millis(1));
    let token1b = match store.begin(&k1, fp1).unwrap() {
        IdempotencyBegin::Fresh(t) => t,
        other => panic!("expected Fresh after TTL expiry, got {other:?}"),
    };
    assert!(store.abandon(&k1, token1b).unwrap());

    // Criteria 23 & 24: stale ClaimToken complete() and abandon() do NOT affect successor claim.
    let ks = key("stale-key");
    let tok_a = match store.begin(&ks, fp1).unwrap() {
        IdempotencyBegin::Fresh(t) => t,
        other => panic!("expected Fresh for A, got {other:?}"),
    };
    // A's in-flight deadline expires; B claims the key with fp2.
    clock.advance(Duration::from_secs(6));
    let tok_b = match store.begin(&ks, fp2).unwrap() {
        IdempotencyBegin::Fresh(t) => t,
        other => panic!("expected Fresh for B, got {other:?}"),
    };
    assert_ne!(tok_a, tok_b);
    // A's stale complete and stale abandon must both return Ok(false) and leave B's claim intact!
    assert!(
        !store
            .complete(&ks, tok_a, CompletedOutcome::Replayable(cached_201(b"A")))
            .unwrap()
    );
    assert!(!store.abandon(&ks, tok_a).unwrap());
    assert_eq!(store.begin(&ks, fp2).unwrap(), IdempotencyBegin::InFlight);
    assert!(
        store
            .complete(&ks, tok_b, CompletedOutcome::Replayable(cached_201(b"B")))
            .unwrap()
    );
    assert_eq!(
        store.begin(&ks, fp2).unwrap(),
        IdempotencyBegin::Replay(cached_201(b"B"))
    );

    // s06 + criterion 25: LRU evicts Done entries only; capacity full of running claims returns Unavailable.
    let cap_store = InMemoryIdempotencyStore::with_clock(
        Duration::from_secs(60),
        Duration::from_secs(5),
        2,
        Arc::clone(&clock),
    );
    let t_run1 = match cap_store.begin(&key("r1"), fp1).unwrap() {
        IdempotencyBegin::Fresh(t) => t,
        other => panic!("expected Fresh, got {other:?}"),
    };
    let t_run2 = match cap_store.begin(&key("r2"), fp1).unwrap() {
        IdempotencyBegin::Fresh(t) => t,
        other => panic!("expected Fresh, got {other:?}"),
    };
    // Both slots hold InFlight claims -> third key MUST fail with PortError::Unavailable (never evict running!).
    let err = cap_store.begin(&key("r3"), fp1).unwrap_err();
    assert!(matches!(err, PortError::Unavailable { .. }));
    assert_eq!(
        cap_store.begin(&key("r1"), fp1).unwrap(),
        IdempotencyBegin::InFlight
    );

    // Complete r1; now r3 evicts r1 (Done) while keeping r2 (InFlight)!
    assert!(
        cap_store
            .complete(&key("r1"), t_run1, CompletedOutcome::Unreplayable)
            .unwrap()
    );
    assert_eq!(
        cap_store.begin(&key("r1"), fp1).unwrap(),
        IdempotencyBegin::Completed
    );
    let _t_run3 = match cap_store.begin(&key("r3"), fp1).unwrap() {
        IdempotencyBegin::Fresh(t) => t,
        other => panic!("expected Fresh after evicting Done r1, got {other:?}"),
    };
    assert_eq!(
        cap_store.begin(&key("r2"), fp1).unwrap(),
        IdempotencyBegin::InFlight
    );
    let _ = cap_store.abandon(&key("r2"), t_run2);

    // Erased Arc<dyn IdempotencyStore> + AlwaysFreshIdempotencyStore.
    let erased: Arc<dyn IdempotencyStore> = Arc::new(AlwaysFreshIdempotencyStore::new());
    let tok = match erased.begin(&key("always"), fp1).unwrap() {
        IdempotencyBegin::Fresh(t) => t,
        other => panic!("expected Fresh, got {other:?}"),
    };
    assert!(
        erased
            .complete(&key("always"), tok, CompletedOutcome::Unreplayable)
            .unwrap()
    );
    assert!(erased.abandon(&key("always"), tok).unwrap());
}

#[tokio::test]
async fn idempotency_middleware_replay_mismatch_query_headers_and_405_before_claim() {
    let port = Arc::new(InMemoryProjectsPort::new());
    let service = Arc::new(ProjectsService::new(
        Arc::clone(&port) as Arc<dyn ProjectsPort>
    ));
    let app = build_router(AppState::for_testing(service));

    // w01 + w16: First POST with Idempotency-Key creates project; second replays byte-for-byte
    // with `Idempotency-Replayed: ?1`, preserves Location, runs handler once, and carries LIVE request-id!
    let req1 = Request::builder()
        .method(Method::POST)
        .uri("/v1/projects")
        .header(header::CONTENT_TYPE, "application/json")
        .header(IDEMPOTENCY_KEY_HEADER, "idem-key-1")
        .header(REQUEST_ID, "req-first-id")
        .body(Body::from(r#"{"name":"Idempotent"}"#))
        .unwrap();
    let res1 = app.clone().oneshot(req1).await.unwrap();
    assert_eq!(res1.status(), StatusCode::CREATED);
    assert!(res1.headers().get(IDEMPOTENCY_REPLAYED_HEADER).is_none());
    assert_eq!(res1.headers().get(REQUEST_ID).unwrap(), "req-first-id");
    let loc1 = res1
        .headers()
        .get(header::LOCATION)
        .unwrap()
        .to_str()
        .unwrap()
        .to_owned();
    let body1 = response_json(res1).await;

    // Replay 3 times to verify marker never stacks (w07) and live request-id replaces stored one (w16).
    for i in 1..=3 {
        let live_id = format!("req-replay-{i}");
        let req = Request::builder()
            .method(Method::POST)
            .uri("/v1/projects")
            .header(header::CONTENT_TYPE, "application/json")
            .header(IDEMPOTENCY_KEY_HEADER, "idem-key-1")
            .header(REQUEST_ID, &live_id)
            .body(Body::from(r#"{"name":"Idempotent"}"#))
            .unwrap();
        let res = app.clone().oneshot(req).await.unwrap();
        assert_eq!(res.status(), StatusCode::CREATED);
        let replayed: Vec<_> = res
            .headers()
            .get_all(IDEMPOTENCY_REPLAYED_HEADER)
            .iter()
            .collect();
        assert_eq!(replayed, vec![&HeaderValue::from_static("?1")]);
        assert_eq!(res.headers().get(REQUEST_ID).unwrap(), live_id.as_str());
        assert_eq!(res.headers().get(header::LOCATION).unwrap(), loc1.as_str());
        let body = response_json(res).await;
        assert_eq!(body, body1);
    }

    // Only ONE project exists in the store.
    assert_eq!(
        port.list(&rs_launch_blueprint::ProjectQuery::default())
            .unwrap()
            .len(),
        1
    );

    // w03: Same key + different payload -> 422 Unprocessable Entity, handler NOT run.
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/v1/projects")
                .header(header::CONTENT_TYPE, "application/json")
                .header(IDEMPOTENCY_KEY_HEADER, "idem-key-1")
                .body(Body::from(r#"{"name":"Different"}"#))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::UNPROCESSABLE_ENTITY);
    assert_eq!(
        res.headers().get(header::CONTENT_TYPE).unwrap(),
        "application/problem+json"
    );

    // w10: Empty key and 256-byte key and duplicate header -> 400 before handler.
    let long_key = "a".repeat(256);
    for bad_key in ["", long_key.as_str(), "has space"] {
        let res = app
            .clone()
            .oneshot(
                Request::builder()
                    .method(Method::POST)
                    .uri("/v1/projects")
                    .header(header::CONTENT_TYPE, "application/json")
                    .header(IDEMPOTENCY_KEY_HEADER, bad_key)
                    .body(Body::from(r#"{"name":"BadKey"}"#))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::BAD_REQUEST);
    }
    let dup_res = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/v1/projects")
                .header(header::CONTENT_TYPE, "application/json")
                .header(IDEMPOTENCY_KEY_HEADER, "k-a")
                .header(IDEMPOTENCY_KEY_HEADER, "k-b")
                .body(Body::from(r#"{"name":"DupKey"}"#))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(dup_res.status(), StatusCode::BAD_REQUEST);

    // Criterion 27: PUT with valid OR malformed Idempotency-Key on GET+POST route -> 405 before claim!
    for k in ["valid-put-key", ""] {
        let res = app
            .clone()
            .oneshot(
                Request::builder()
                    .method(Method::PUT)
                    .uri("/v1/projects")
                    .header(IDEMPOTENCY_KEY_HEADER, k)
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(
            res.status(),
            StatusCode::METHOD_NOT_ALLOWED,
            "criterion 27: PUT must return 405 before idempotency layer"
        );
    }
}

#[tokio::test]
async fn idempotency_concurrency_dry_run_streaming_and_offload_dispatch() {
    let store: Arc<dyn IdempotencyStore> = Arc::new(InMemoryIdempotencyStore::new(
        Duration::from_secs(60),
        Duration::from_secs(10),
        16,
    ));
    let calls = Arc::new(AtomicUsize::new(0));
    let barrier = Arc::new(tokio::sync::Barrier::new(2));
    let release = Arc::new(tokio::sync::Notify::new());

    let c1 = Arc::clone(&calls);
    let b1 = Arc::clone(&barrier);
    let r1 = Arc::clone(&release);
    let slow_handler = move || {
        let c = Arc::clone(&c1);
        let b = Arc::clone(&b1);
        let r = Arc::clone(&r1);
        async move {
            c.fetch_add(1, Ordering::SeqCst);
            b.wait().await;
            r.notified().await;
            (
                StatusCode::CREATED,
                axum::response::AppendHeaders([
                    (header::SET_COOKIE, "a=1"),
                    (header::SET_COOKIE, "b=2"),
                    (header::LOCATION, "/items/1"),
                ]),
                "created",
            )
        }
    };

    let dry_calls = Arc::new(AtomicUsize::new(0));
    let dc = Arc::clone(&dry_calls);
    let dry_handler = move |req: Request<Body>| {
        let dc = Arc::clone(&dc);
        async move {
            let is_dry = req
                .uri()
                .query()
                .is_some_and(|q| q.contains("dry_run=true") || q.contains("dry%5Frun=true"));
            if !is_dry {
                dc.fetch_add(1, Ordering::SeqCst);
            }
            (StatusCode::CREATED, "ok")
        }
    };

    let stream_calls = Arc::new(AtomicUsize::new(0));
    let sc = Arc::clone(&stream_calls);
    let stream_handler = move || {
        let sc = Arc::clone(&sc);
        async move {
            sc.fetch_add(1, Ordering::SeqCst);
            // Response larger than max_body_bytes (16 bytes) -> completed-unreplayable -> retry 409!
            (StatusCode::CREATED, "0123456789abcdef_oversize_2xx_body")
        }
    };

    let cfg = IdempotencyConfig {
        dispatch: StoreDispatch::Offload(Arc::clone(&store)),
        max_body_bytes: 16,
        problem_base_uri: DEFAULT_PROBLEM_BASE_URI.to_owned(),
    };
    let app = apply_idempotency(
        Router::new()
            .route("/slow", post(slow_handler))
            .route("/dry", post(dry_handler))
            .route("/large", post(stream_handler))
            .route("/get", get(|| async { "ok" })),
        cfg,
    );

    // w14: Concurrent live requests on same key -> 1x 201, 1x 409, handler executes once!
    let app_a = app.clone();
    let task_a = tokio::spawn(async move {
        app_a
            .oneshot(
                Request::builder()
                    .method(Method::POST)
                    .uri("/slow")
                    .header(IDEMPOTENCY_KEY_HEADER, "concurrent-k")
                    .body(Body::from("x"))
                    .unwrap(),
            )
            .await
            .unwrap()
    });
    // Wait until handler A is inside the handler (holding the InFlight claim).
    barrier.wait().await;
    let res_b = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/slow")
                .header(IDEMPOTENCY_KEY_HEADER, "concurrent-k")
                .body(Body::from("x"))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res_b.status(), StatusCode::CONFLICT);
    release.notify_one();
    let res_a = task_a.await.unwrap();
    assert_eq!(res_a.status(), StatusCode::CREATED);
    assert_eq!(calls.load(Ordering::SeqCst), 1);

    // w07: Multi-valued Set-Cookie survives caching and replay intact.
    let replay = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/slow")
                .header(IDEMPOTENCY_KEY_HEADER, "concurrent-k")
                .body(Body::from("x"))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(replay.status(), StatusCode::CREATED);
    let cookies: Vec<&str> = replay
        .headers()
        .get_all(header::SET_COOKIE)
        .iter()
        .map(|v| v.to_str().unwrap())
        .collect();
    assert_eq!(cookies, vec!["a=1", "b=2"]);

    // w08: Oversize request body (>16 bytes) -> 413 before handler.
    let res = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/dry")
                .header(IDEMPOTENCY_KEY_HEADER, "oversize-req")
                .body(Body::from("0123456789abcdef_too_big"))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::PAYLOAD_TOO_LARGE);
    assert_eq!(dry_calls.load(Ordering::SeqCst), 0);

    // w09: Oversize 2xx response streams whole to client and marks Completed -> retry is 409!
    let res1 = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/large")
                .header(IDEMPOTENCY_KEY_HEADER, "large-2xx")
                .body(Body::from("ok"))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res1.status(), StatusCode::CREATED);
    let bytes = axum::body::to_bytes(res1.into_body(), usize::MAX)
        .await
        .unwrap();
    assert_eq!(&bytes[..], b"0123456789abcdef_oversize_2xx_body");
    let res2 = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/large")
                .header(IDEMPOTENCY_KEY_HEADER, "large-2xx")
                .body(Body::from("ok"))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res2.status(), StatusCode::CONFLICT);
    assert_eq!(stream_calls.load(Ordering::SeqCst), 1);

    // Criterion 26: dry_run=true bypasses without consuming key; dry_run=false claims; invalid -> 400.
    for uri in ["/dry?dry_run=true", "/dry?dry%5Frun=true"] {
        let res = app
            .clone()
            .oneshot(
                Request::builder()
                    .method(Method::POST)
                    .uri(uri)
                    .header(IDEMPOTENCY_KEY_HEADER, "dry-k")
                    .body(Body::from("hi"))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(res.status(), StatusCode::CREATED);
        assert!(res.headers().get(IDEMPOTENCY_REPLAYED_HEADER).is_none());
    }
    assert_eq!(dry_calls.load(Ordering::SeqCst), 0);

    // Key is still free for a real call with dry_run=false.
    let real1 = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/dry?dry_run=false")
                .header(IDEMPOTENCY_KEY_HEADER, "dry-k")
                .body(Body::from("hi"))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(real1.status(), StatusCode::CREATED);
    let real2 = app
        .clone()
        .oneshot(
            Request::builder()
                .method(Method::POST)
                .uri("/dry?dry_run=false")
                .header(IDEMPOTENCY_KEY_HEADER, "dry-k")
                .body(Body::from("hi"))
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(
        real2.headers().get(IDEMPOTENCY_REPLAYED_HEADER).unwrap(),
        "?1"
    );
    assert_eq!(dry_calls.load(Ordering::SeqCst), 1);

    for bad_dry in [
        "/dry?dry_run=",
        "/dry?dry_run",
        "/dry?dry_run=yes",
        "/dry?dry_run=true&dry_run=false",
    ] {
        let res = app
            .clone()
            .oneshot(
                Request::builder()
                    .method(Method::POST)
                    .uri(bad_dry)
                    .header(IDEMPOTENCY_KEY_HEADER, "bad-dry-k")
                    .body(Body::from("hi"))
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(
            res.status(),
            StatusCode::BAD_REQUEST,
            "expected 400 for {bad_dry}"
        );
    }

    // w06: GET with Idempotency-Key passes through untouched.
    let res = app
        .oneshot(
            Request::builder()
                .method(Method::GET)
                .uri("/get")
                .header(IDEMPOTENCY_KEY_HEADER, "")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(res.status(), StatusCode::OK);
}
