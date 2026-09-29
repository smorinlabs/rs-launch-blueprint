//! Router checks `w01`-`w17`, driven through `tower::ServiceExt::oneshot`
//! against a `Router` — R69 revision 10's selected in-process test idiom, with
//! `tower` as a dev-dependency only.

use std::collections::VecDeque;
use std::pin::Pin;
use std::sync::atomic::{AtomicU64, AtomicUsize, Ordering};
use std::sync::Arc;
use std::task::{Context, Poll};
use std::time::Duration;

use axum::body::{Body, Bytes, to_bytes};
use axum::http::{HeaderValue, Request, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::routing::post;
use axum::Router;
use sha2::{Digest, Sha256};
use tower::ServiceExt;

use r73_probe::adapter::InMemoryIdempotencyStore;
use r73_probe::layer::{IDEMPOTENCY_REPLAYED, IdempotencyState, REPLAYED_TRUE, idempotency};
use r73_probe::port::{CacheKey, Clock, Fingerprint, IdempotencyStore};

// ---------------------------------------------------------------- helpers ---

#[derive(Default)]
struct TestClock(AtomicU64);

impl TestClock {
    fn set(&self, millis: u64) {
        self.0.store(millis, Ordering::SeqCst);
    }
}

impl Clock for TestClock {
    fn now_millis(&self) -> u64 {
        self.0.load(Ordering::SeqCst)
    }
}

/// A body whose length is not known in advance: `size_hint().upper()` is `None`.
struct UnknownLength(VecDeque<&'static [u8]>);

impl http_body::Body for UnknownLength {
    type Data = Bytes;
    type Error = std::convert::Infallible;

    fn poll_frame(
        self: Pin<&mut Self>,
        _cx: &mut Context<'_>,
    ) -> Poll<Option<Result<http_body::Frame<Self::Data>, Self::Error>>> {
        Poll::Ready(
            self.get_mut()
                .0
                .pop_front()
                .map(|chunk| Ok(http_body::Frame::data(Bytes::from_static(chunk)))),
        )
    }
}

#[derive(Clone)]
struct Counters {
    create: Arc<AtomicUsize>,
    other: Arc<AtomicUsize>,
}

impl Counters {
    fn new() -> Self {
        Self {
            create: Arc::new(AtomicUsize::new(0)),
            other: Arc::new(AtomicUsize::new(0)),
        }
    }
    fn creates(&self) -> usize {
        self.create.load(Ordering::SeqCst)
    }
}

fn app(state: IdempotencyState, counters: Counters) -> Router {
    let create = Arc::clone(&counters.create);
    let slow = Arc::clone(&counters.create);
    let other = Arc::clone(&counters.other);
    let cookies = Arc::clone(&counters.other);
    let stream = Arc::clone(&counters.create);
    let big = Arc::clone(&counters.create);

    Router::new()
        .route(
            "/things",
            post(move || {
                let hits = Arc::clone(&create);
                async move {
                    let n = hits.fetch_add(1, Ordering::SeqCst) + 1;
                    (
                        StatusCode::CREATED,
                        [
                            ("content-type", "application/json"),
                            ("location", "/things/1"),
                            // A correlation header the replay must NOT carry.
                            ("request-id", "first-request"),
                        ],
                        format!("{{\"run\":{n}}}"),
                    )
                        .into_response()
                }
            })
            .get(move || {
                let hits = Arc::clone(&other);
                async move {
                    hits.fetch_add(1, Ordering::SeqCst);
                    (StatusCode::OK, "listed").into_response()
                }
            }),
        )
        .route(
            "/slow",
            post(move || {
                let hits = Arc::clone(&slow);
                async move {
                    tokio::time::sleep(Duration::from_millis(150)).await;
                    let n = hits.fetch_add(1, Ordering::SeqCst) + 1;
                    (StatusCode::CREATED, format!("{{\"run\":{n}}}")).into_response()
                }
            }),
        )
        .route(
            "/fail",
            post(|| async { (StatusCode::INTERNAL_SERVER_ERROR, "boom").into_response() }),
        )
        .route(
            "/cookies",
            post(move || {
                let hits = Arc::clone(&cookies);
                async move {
                    hits.fetch_add(1, Ordering::SeqCst);
                    let mut response = (StatusCode::OK, "ok").into_response();
                    response
                        .headers_mut()
                        .append("set-cookie", HeaderValue::from_static("a=1"));
                    response
                        .headers_mut()
                        .append("set-cookie", HeaderValue::from_static("b=2"));
                    response
                }
            }),
        )
        .route(
            "/stream",
            post(move || {
                let hits = Arc::clone(&stream);
                async move {
                    hits.fetch_add(1, Ordering::SeqCst);
                    Response::new(Body::new(UnknownLength(VecDeque::from(vec![
                        b"alpha".as_slice(),
                        b"beta".as_slice(),
                    ]))))
                }
            }),
        )
        .route(
            "/big",
            post(move || {
                let hits = Arc::clone(&big);
                async move {
                    hits.fetch_add(1, Ordering::SeqCst);
                    (StatusCode::OK, "x".repeat(4_096)).into_response()
                }
            }),
        )
        .layer(axum::middleware::from_fn_with_state(state, idempotency))
}

fn state(store: Arc<InMemoryIdempotencyStore>) -> IdempotencyState {
    IdempotencyState {
        store,
        max_request_bytes: 64,
        max_response_bytes: 1_024,
    }
}

fn fixture() -> (Router, Counters, Arc<InMemoryIdempotencyStore>, Arc<TestClock>) {
    let clock = Arc::new(TestClock::default());
    let store = Arc::new(InMemoryIdempotencyStore::new(
        60_000,
        1_000,
        1_024,
        Arc::clone(&clock) as Arc<dyn Clock>,
    ));
    let counters = Counters::new();
    let router = app(state(Arc::clone(&store)), counters.clone());
    (router, counters, store, clock)
}

fn post_with(path: &str, key: Option<&str>, body: &'static str) -> Request<Body> {
    let mut builder = Request::builder().method("POST").uri(path);
    if let Some(key) = key {
        builder = builder.header("idempotency-key", key);
    }
    builder.body(Body::from(body)).expect("request builds")
}

async fn send(router: &Router, request: Request<Body>) -> (StatusCode, Vec<u8>, Response<Body>) {
    let response = router
        .clone()
        .oneshot(request)
        .await
        .expect("the router is infallible");
    let status = response.status();
    let (parts, body) = response.into_parts();
    let bytes = to_bytes(body, usize::MAX).await.expect("body collects");
    let rebuilt = Response::from_parts(parts, Body::from(bytes.clone()));
    (status, bytes.to_vec(), rebuilt)
}

// ------------------------------------------------------------------ checks ---

#[tokio::test]
async fn w01_second_request_replays_byte_for_byte_and_the_handler_ran_once() {
    let (router, counters, _store, _clock) = fixture();
    let (first_status, first_body, first) =
        send(&router, post_with("/things", Some("k1"), "{}")).await;
    let (second_status, second_body, second) =
        send(&router, post_with("/things", Some("k1"), "{}")).await;

    assert_eq!(first_status, StatusCode::CREATED);
    assert_eq!(second_status, StatusCode::CREATED, "w01: the replay keeps the status");
    assert_eq!(first_body, second_body, "w01: the body is byte-for-byte identical");
    assert_eq!(
        first.headers().get("location"),
        second.headers().get("location"),
        "w01: Location survives the replay, which R5.6 makes mandatory on a create"
    );
    assert!(first.headers().get(IDEMPOTENCY_REPLAYED).is_none(), "w01: the first response is not marked");
    assert_eq!(
        second.headers().get(IDEMPOTENCY_REPLAYED).map(HeaderValue::as_bytes),
        Some(REPLAYED_TRUE.as_bytes()),
        "w01: the replay carries the RFC 9651 sf-boolean ?1"
    );
    assert_eq!(counters.creates(), 1, "w01: the handler ran exactly once");
}

#[tokio::test]
async fn w02_a_five_hundred_is_not_cached() {
    let (router, _counters, _store, _clock) = fixture();
    let (first, _, _) = send(&router, post_with("/fail", Some("k1"), "{}")).await;
    let (second, _, second_response) = send(&router, post_with("/fail", Some("k1"), "{}")).await;
    assert_eq!(first, StatusCode::INTERNAL_SERVER_ERROR);
    assert_eq!(
        second,
        StatusCode::INTERNAL_SERVER_ERROR,
        "w02: the second attempt really re-executes rather than replaying or conflicting"
    );
    assert!(
        second_response.headers().get(IDEMPOTENCY_REPLAYED).is_none(),
        "w02: a re-execution carries no replay marker"
    );
}

#[tokio::test]
async fn w03_same_key_different_body_is_unprocessable() {
    let (router, counters, _store, _clock) = fixture();
    send(&router, post_with("/things", Some("k1"), "{\"a\":1}")).await;
    let (status, _, _) = send(&router, post_with("/things", Some("k1"), "{\"a\":2}")).await;
    assert_eq!(
        status,
        StatusCode::UNPROCESSABLE_ENTITY,
        "w03: R3.9 requires rejecting a reused key carrying a different payload"
    );
    assert_eq!(counters.creates(), 1, "w03: the handler did not run for the mismatch");
}

#[tokio::test]
async fn w04_a_different_query_string_executes_independently() {
    let (router, counters, _store, _clock) = fixture();
    send(&router, post_with("/things?a=1", Some("k1"), "{}")).await;
    let (status, _, response) = send(&router, post_with("/things?a=2", Some("k1"), "{}")).await;
    assert_eq!(status, StatusCode::CREATED);
    assert!(
        response.headers().get(IDEMPOTENCY_REPLAYED).is_none(),
        "w04: /things?a=1 must not replay into /things?a=2"
    );
    assert_eq!(counters.creates(), 2, "w04: both requests reached the handler");
}

#[tokio::test]
async fn w05_no_key_means_no_caching() {
    let (router, counters, _store, _clock) = fixture();
    send(&router, post_with("/things", None, "{}")).await;
    let (_, _, response) = send(&router, post_with("/things", None, "{}")).await;
    assert!(response.headers().get(IDEMPOTENCY_REPLAYED).is_none());
    assert_eq!(counters.creates(), 2, "w05: the header is opt-in; without it nothing is cached");
}

#[tokio::test]
async fn w06_a_get_carrying_the_header_passes_through_untouched() {
    let (router, counters, _store, _clock) = fixture();
    let request = Request::builder()
        .method("GET")
        .uri("/things")
        .header("idempotency-key", "k1")
        .body(Body::empty())
        .expect("request builds");
    let (status, body, response) = send(&router, request).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(body, b"listed");
    assert!(response.headers().get(IDEMPOTENCY_REPLAYED).is_none());
    assert_eq!(counters.other.load(Ordering::SeqCst), 1);
}

#[tokio::test]
async fn w07_multi_valued_headers_survive_and_the_marker_does_not_stack() {
    let (router, _counters, _store, _clock) = fixture();
    let (_, _, first) = send(&router, post_with("/cookies", Some("k1"), "{}")).await;
    let cookies: Vec<_> = first.headers().get_all("set-cookie").iter().collect();
    assert_eq!(cookies.len(), 2, "w07: the handler really sends two Set-Cookie values");

    for round in 1..=3 {
        let (_, _, replay) = send(&router, post_with("/cookies", Some("k1"), "{}")).await;
        let replayed: Vec<_> = replay.headers().get_all("set-cookie").iter().collect();
        assert_eq!(replayed.len(), 2, "w07 round {round}: both cookies survive the replay");
        let markers: Vec<_> = replay.headers().get_all(IDEMPOTENCY_REPLAYED).iter().collect();
        assert_eq!(markers.len(), 1, "w07 round {round}: the marker does not stack");
        assert_eq!(markers[0].as_bytes(), REPLAYED_TRUE.as_bytes());
    }
}

#[tokio::test]
async fn w08_an_oversize_request_body_with_a_key_is_rejected_before_the_handler() {
    let (router, counters, _store, _clock) = fixture();
    let oversize: &'static str = Box::leak("y".repeat(1_000).into_boxed_str());
    let (status, _, _) = send(&router, post_with("/things", Some("k1"), oversize)).await;
    assert_eq!(
        status,
        StatusCode::PAYLOAD_TOO_LARGE,
        "w08: the layer must read the body to fingerprint it, so it cannot forward an oversize one"
    );
    assert_eq!(counters.creates(), 0, "w08: the handler never ran");
}

#[tokio::test]
async fn w09_an_unknown_length_response_streams_through_whole_and_is_not_replayed() {
    let (router, counters, _store, _clock) = fixture();
    let (status, body, response) = send(&router, post_with("/stream", Some("k1"), "{}")).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(body, b"alphabeta", "w09: the streaming body reaches the client whole");
    assert!(response.headers().get(IDEMPOTENCY_REPLAYED).is_none());

    let (retry, _, _) = send(&router, post_with("/stream", Some("k1"), "{}")).await;
    assert_eq!(
        retry,
        StatusCode::CONFLICT,
        "w09: a completed-but-unreplayable outcome answers the retry rather than re-executing it"
    );
    assert_eq!(counters.creates(), 1, "w09: the side effect happened exactly once");
}

#[tokio::test]
async fn w09b_an_oversize_response_behaves_the_same_way() {
    let (router, counters, _store, _clock) = fixture();
    let (status, body, _) = send(&router, post_with("/big", Some("k1"), "{}")).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(body.len(), 4_096, "w09b: the oversize body reaches the client whole");
    let (retry, _, _) = send(&router, post_with("/big", Some("k1"), "{}")).await;
    assert_eq!(retry, StatusCode::CONFLICT);
    assert_eq!(counters.creates(), 1);
}

#[tokio::test]
async fn w10_an_empty_key_and_an_oversize_key_are_both_rejected() {
    let (router, counters, _store, _clock) = fixture();
    let too_long: &'static str = Box::leak("k".repeat(256).into_boxed_str());
    for key in ["", too_long] {
        let (status, _, _) = send(&router, post_with("/things", Some(key), "{}")).await;
        assert_eq!(
            status,
            StatusCode::BAD_REQUEST,
            "w10: key of {} bytes must be rejected as malformed syntax",
            key.len()
        );
    }
    assert_eq!(counters.creates(), 0, "w10: validation happens before the handler");
}

#[tokio::test]
async fn w11_a_duplicate_arriving_while_the_first_is_in_flight_conflicts() {
    let (router, counters, store, _clock) = fixture();
    // Seed the in-flight marker with the fingerprint the request will produce.
    let fingerprint = Fingerprint(Sha256::digest(b"{}").into());
    let key = CacheKey {
        method: "POST".to_owned(),
        path: "/things".to_owned(),
        query: String::new(),
        idempotency_key: "k1".to_owned(),
    };
    store.begin(&key, &fingerprint).expect("seeding the claim");

    let (status, _, _) = send(&router, post_with("/things", Some("k1"), "{}")).await;
    assert_eq!(status, StatusCode::CONFLICT, "w11: R5.3 puts a conflict with current state at 409");
    assert_eq!(counters.creates(), 0, "w11: the handler did not run");
}

#[tokio::test]
async fn w12_an_entry_expires_at_its_ttl_and_the_handler_runs_again() {
    let (router, counters, _store, clock) = fixture();
    send(&router, post_with("/things", Some("k1"), "{}")).await;
    clock.set(59_999);
    let (_, _, inside) = send(&router, post_with("/things", Some("k1"), "{}")).await;
    assert!(inside.headers().get(IDEMPOTENCY_REPLAYED).is_some(), "w12: still inside the ttl");
    clock.set(60_000);
    let (status, _, outside) = send(&router, post_with("/things", Some("k1"), "{}")).await;
    assert_eq!(status, StatusCode::CREATED);
    assert!(outside.headers().get(IDEMPOTENCY_REPLAYED).is_none(), "w12: the entry expired");
    assert_eq!(counters.creates(), 2);
}

#[tokio::test]
async fn w13_a_non_two_hundred_releases_the_claim() {
    let (router, _counters, _store, _clock) = fixture();
    send(&router, post_with("/fail", Some("k1"), "{}")).await;
    let (status, _, _) = send(&router, post_with("/fail", Some("k1"), "{}")).await;
    assert_ne!(
        status,
        StatusCode::CONFLICT,
        "w13: a failed attempt must not pin the key behind a stale claim"
    );
    assert_eq!(status, StatusCode::INTERNAL_SERVER_ERROR);
}

#[tokio::test(flavor = "multi_thread", worker_threads = 4)]
async fn w14_two_live_concurrent_requests_execute_the_handler_once() {
    let (router, counters, _store, _clock) = fixture();
    let left = router.clone();
    let right = router.clone();
    let (a, b) = tokio::join!(
        async move { send(&left, post_with("/slow", Some("k1"), "{}")).await },
        async move { send(&right, post_with("/slow", Some("k1"), "{}")).await }
    );
    let mut observed = [a.0, b.0];
    observed.sort_by_key(axum::http::StatusCode::as_u16);
    assert_eq!(
        observed,
        [StatusCode::CREATED, StatusCode::CONFLICT],
        "w14: of two genuinely concurrent requests, exactly one executes and the other conflicts"
    );
    assert_eq!(counters.creates(), 1, "w14: the side effect happened exactly once");
}

#[tokio::test]
async fn w15_a_poisoned_store_surfaces_as_service_unavailable() {
    let (router, counters, store, _clock) = fixture();
    store.poison();
    let (status, _, _) = send(&router, post_with("/things", Some("k1"), "{}")).await;
    assert_eq!(
        status,
        StatusCode::SERVICE_UNAVAILABLE,
        "w15: PortError::Unavailable becomes 503, and the handler is not reached"
    );
    assert_eq!(counters.creates(), 0);
}

#[tokio::test]
async fn w16_correlation_headers_are_never_replayed() {
    let (router, _counters, _store, _clock) = fixture();
    let (_, _, first) = send(&router, post_with("/things", Some("k1"), "{}")).await;
    assert_eq!(
        first.headers().get("request-id").map(HeaderValue::as_bytes),
        Some(b"first-request".as_slice()),
        "w16: the handler really emits a correlation header"
    );
    let (_, _, replay) = send(&router, post_with("/things", Some("k1"), "{}")).await;
    assert!(
        replay.headers().get(IDEMPOTENCY_REPLAYED).is_some(),
        "w16: this is the replay path"
    );
    assert!(
        replay.headers().get("request-id").is_none(),
        "w16: a replay must not carry the first request's correlation id (R11.7)"
    );
}

#[tokio::test]
async fn w17_a_dry_run_never_consumes_the_key() {
    let (router, counters, _store, _clock) = fixture();
    let (first, _, first_response) =
        send(&router, post_with("/things?dry_run=true", Some("k1"), "{}")).await;
    assert_eq!(first, StatusCode::CREATED);
    assert!(first_response.headers().get(IDEMPOTENCY_REPLAYED).is_none());
    let (second, _, second_response) =
        send(&router, post_with("/things?dry_run=true", Some("k1"), "{}")).await;
    assert_eq!(
        second,
        StatusCode::CREATED,
        "w17: R3.12.4 forbids a dry-run consuming the key, so no claim is held"
    );
    assert!(second_response.headers().get(IDEMPOTENCY_REPLAYED).is_none());
    assert_eq!(counters.creates(), 2, "w17: neither call was replayed");

    // ...and the key is still free for the real call.
    let (real, _, real_response) = send(&router, post_with("/things", Some("k1"), "{}")).await;
    assert_eq!(real, StatusCode::CREATED);
    assert!(real_response.headers().get(IDEMPOTENCY_REPLAYED).is_none());
}
