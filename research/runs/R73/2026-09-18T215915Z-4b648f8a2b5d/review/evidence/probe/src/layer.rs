//! The replay layer. Stands in for `crates/web/src/idempotency.rs`.
//!
//! `axum::middleware::from_fn_with_state` gives all four capabilities the layer
//! needs in one `async fn`: see the request before the handler, see the response
//! after, be able to *not* call the handler, and hold shared state. It returns a
//! real `tower::Layer` (`FromFnLayer`) without naming `tower` as a dependency.

use std::sync::Arc;

use axum::body::{Body, HttpBody, to_bytes};
use axum::extract::{Request, State};
use axum::http::{HeaderName, HeaderValue, Method, StatusCode, header};
use axum::middleware::Next;
use axum::response::{IntoResponse, Response};
use sha2::{Digest, Sha256};

use crate::port::{Begin, CacheKey, CachedResponse, Fingerprint, IdempotencyStore};

/// The request header. Reserved by the org REST API Design Standard v2.0.0
/// §1.10 (`rest-api-standard.md:347`) and required by R3.9 (`:651`).
pub const IDEMPOTENCY_KEY: HeaderName = HeaderName::from_static("idempotency-key");

/// The replay marker. Not a reserved name; this template registers it.
/// Its value is the RFC 9651 structured-field Boolean `?1`, per R4.12
/// (`rest-api-standard.md:880`) — py emits the bare token `true`
/// (`py .../web/idempotency.py:110-121`), which is not a Boolean.
pub const IDEMPOTENCY_REPLAYED: HeaderName = HeaderName::from_static("idempotency-replayed");

/// The RFC 9651 sf-boolean true.
pub const REPLAYED_TRUE: &str = "?1";

/// Stripe's published ceiling. The expired IETF draft states no limit.
pub const MAX_KEY_BYTES: usize = 255;

/// Correlation headers are never carried in a cached entry. A replayed response
/// must carry the *live* request's correlation identity, not the first
/// request's: R11.7 (`rest-api-standard.md:1752`) makes `request-id` mandatory
/// on every response, and R11.8 (`:1757`) makes `traceparent` propagation
/// mandatory. Storing them verbatim would replay a stale trace.
const NEVER_CACHED: [HeaderName; 3] = [
    HeaderName::from_static("request-id"),
    HeaderName::from_static("traceparent"),
    HeaderName::from_static("tracestate"),
];

#[derive(Clone)]
pub struct IdempotencyState {
    pub store: Arc<dyn IdempotencyStore>,
    pub max_request_bytes: usize,
    pub max_response_bytes: usize,
}

/// Releases an unfinished claim when the inner future is dropped — a timeout, a
/// caught panic, or a client disconnect. Without it one dropped request pins a
/// key until the in-flight deadline.
struct AbandonOnDrop {
    armed: Option<(Arc<dyn IdempotencyStore>, CacheKey)>,
}

impl AbandonOnDrop {
    fn new(store: Arc<dyn IdempotencyStore>, key: CacheKey) -> Self {
        Self {
            armed: Some((store, key)),
        }
    }
    fn disarm(&mut self) {
        self.armed = None;
    }
}

impl Drop for AbandonOnDrop {
    fn drop(&mut self) {
        if let Some((store, key)) = self.armed.take() {
            let _ = store.abandon(&key);
        }
    }
}

/// A stand-in for R70's `application/problem+json` envelope. R70 owns the body;
/// the probe needs only the status, and says so rather than inventing a shape.
fn problem(status: StatusCode) -> Response {
    (
        status,
        [(header::CONTENT_TYPE, "application/json")],
        format!("{{\"status\":{}}}", status.as_u16()),
    )
        .into_response()
}

/// R3.9 (`:651`) binds "non-idempotent state-changing requests". py's set at
/// `idempotency.py:45` is `POST`, `PUT`, `PATCH`; `PUT` is idempotent by
/// RFC 9110 §9.2.2 and is included anyway, which R3.9's exception permits
/// (the exception is a relaxation, not a prohibition).
fn is_in_scope(method: &Method) -> bool {
    matches!(*method, Method::POST | Method::PUT | Method::PATCH)
}

/// R3.12.4 (`rest-api-standard.md:733`): a dry-run "MUST NOT consume an
/// `Idempotency-Key`". `dry_run` is reserved standard-wide (§1.10, `:335`), so
/// its presence in the query string suppresses the claim unconditionally; an
/// endpoint that does not implement dry-run still rejects it with 400 under
/// R1.9 (`:318`), and that rejection is a non-2xx which stores nothing.
fn is_dry_run(query: &str) -> bool {
    query
        .split('&')
        .any(|pair| pair == "dry_run" || pair.starts_with("dry_run="))
}

/// Validates before the value is used as a map key: non-empty, at most 255
/// bytes, visible ASCII only.
fn validate_key(raw: &HeaderValue) -> Option<String> {
    let bytes = raw.as_bytes();
    if bytes.is_empty() || bytes.len() > MAX_KEY_BYTES {
        return None;
    }
    if !bytes.iter().all(|b| (0x21..=0x7e).contains(b)) {
        return None;
    }
    String::from_utf8(bytes.to_vec()).ok()
}

pub async fn idempotency(
    State(state): State<IdempotencyState>,
    request: Request,
    next: Next,
) -> Response {
    if !is_in_scope(request.method()) {
        return next.run(request).await;
    }

    let mut values = request.headers().get_all(IDEMPOTENCY_KEY).iter();
    let Some(raw) = values.next() else {
        return next.run(request).await;
    };
    if values.next().is_some() {
        // Two different keys on one request is malformed syntax: R5.3 (`:939`)
        // puts malformed syntax at 400.
        return problem(StatusCode::BAD_REQUEST);
    }
    let Some(key) = validate_key(raw) else {
        return problem(StatusCode::BAD_REQUEST);
    };

    let (parts, body) = request.into_parts();
    let query = parts.uri.query().unwrap_or("").to_owned();
    if is_dry_run(&query) {
        return next.run(Request::from_parts(parts, body)).await;
    }

    let Ok(bytes) = to_bytes(body, state.max_request_bytes).await else {
        // `to_bytes` consumes the body on overflow, so forwarding is not an
        // option. RFC 9110 §15.5.14's registered semantics; R5.2 (`:936`)
        // forbids anything unregistered.
        return problem(StatusCode::PAYLOAD_TOO_LARGE);
    };
    let fingerprint = Fingerprint(Sha256::digest(&bytes).into());

    let cache_key = CacheKey {
        method: parts.method.as_str().to_owned(),
        path: parts.uri.path().to_owned(),
        query,
        idempotency_key: key,
    };

    match state.store.begin(&cache_key, &fingerprint) {
        Err(_) => return problem(StatusCode::SERVICE_UNAVAILABLE),
        Ok(Begin::Mismatch) => return problem(StatusCode::UNPROCESSABLE_ENTITY),
        Ok(Begin::InFlight) | Ok(Begin::Completed) => return problem(StatusCode::CONFLICT),
        Ok(Begin::Replay(saved)) => return replay(saved),
        Ok(Begin::Fresh) => {}
    }

    let mut guard = AbandonOnDrop::new(Arc::clone(&state.store), cache_key.clone());
    let response = next
        .run(Request::from_parts(parts, Body::from(bytes)))
        .await;

    if !response.status().is_success() {
        // F314: only an outcome that is safe to replay is stored. Every other
        // outcome releases the claim through `guard`, so the client may retry
        // the same key for real — which is what R11.6 (`:1743`) requires the
        // API to document.
        return response;
    }

    let (response_parts, response_body) = response.into_parts();
    let bounded = response_body
        .size_hint()
        .upper()
        .is_some_and(|upper| usize::try_from(upper).is_ok_and(|n| n <= state.max_response_bytes));

    if !bounded {
        // Completed, but nothing replayable was captured. Record the completion
        // so a retry is answered rather than re-executed: R3.9 (`:651`) makes
        // non-re-execution the guarantee, and re-running the handler here would
        // break it silently.
        let _ = state.store.complete(&cache_key, None);
        guard.disarm();
        return Response::from_parts(response_parts, response_body);
    }

    let Ok(captured) = to_bytes(response_body, state.max_response_bytes).await else {
        let _ = state.store.complete(&cache_key, None);
        guard.disarm();
        return problem(StatusCode::INTERNAL_SERVER_ERROR);
    };

    let headers = response_parts
        .headers
        .iter()
        .filter(|(name, _)| !NEVER_CACHED.contains(name))
        .map(|(name, value)| (name.as_str().to_owned(), value.as_bytes().to_vec()))
        .collect();

    let _ = state.store.complete(
        &cache_key,
        Some(CachedResponse {
            status: response_parts.status.as_u16(),
            headers,
            body: captured.to_vec(),
        }),
    );
    guard.disarm();
    Response::from_parts(response_parts, Body::from(captured))
}

/// Rebuilds the stored response and appends the replay marker to a *fresh* copy
/// of the stored header list, so the marker never stacks across replays — py's
/// `idempotency.py:115-121` bug-avoidance, kept.
fn replay(saved: CachedResponse) -> Response {
    let mut response = Response::new(Body::from(saved.body));
    *response.status_mut() =
        StatusCode::from_u16(saved.status).unwrap_or(StatusCode::INTERNAL_SERVER_ERROR);
    for (name, value) in saved.headers {
        if let (Ok(name), Ok(value)) = (
            HeaderName::try_from(name.as_str()),
            HeaderValue::from_bytes(&value),
        ) {
            response.headers_mut().append(name, value);
        }
    }
    response
        .headers_mut()
        .insert(IDEMPOTENCY_REPLAYED, HeaderValue::from_static(REPLAYED_TRUE));
    response
}
