//! `Idempotency-Key` replay middleware driving [`IdempotencyStore`] (`R73`, `OV-16`).
//!
//! Computes SHA-256 request payload fingerprints, enforces single-execution CAS semantics with
//! drop-safe abandonment, streams oversize 2xx responses without dropping bytes while recording
//! `CompletedOutcome::Unreplayable`, and preserves multi-valued response headers while stripping
//! per-request correlation headers (`request-id`, `traceparent`, `tracestate`).

use std::collections::VecDeque;
use std::pin::Pin;
use std::sync::Arc;
use std::task::{Context, Poll};

use axum::Router;
use axum::body::{Body, Bytes};
use axum::extract::{Request, State};
use axum::http::header::{HeaderName, HeaderValue};
use axum::http::{Method, StatusCode};
use axum::middleware::{self, Next};
use axum::response::{IntoResponse, Response};
use http_body::{Body as HttpBody, Frame};
use rs_launch_blueprint::{ErrorCode, PortError};
use sha2::{Digest, Sha256};

use crate::idempotency_store::{
    CachedResponse, ClaimToken, CompletedOutcome, IdempotencyBegin, IdempotencyCacheKey,
    IdempotencyStore, PayloadFingerprint,
};
use crate::problems::{WebError, parse_query_pairs};

/// Request header carrying the caller-supplied idempotency token (`R73`).
pub const IDEMPOTENCY_KEY_HEADER: HeaderName = HeaderName::from_static("idempotency-key");

/// Structured-Field boolean response header marking a replayed response (`?1`, `R73`).
pub const IDEMPOTENCY_REPLAYED_HEADER: HeaderName = HeaderName::from_static("idempotency-replayed");

/// RFC 8941 Structured-Field boolean `true` token emitted on replayed responses.
pub const IDEMPOTENCY_REPLAYED_VALUE: &str = "?1";

/// Maximum accepted byte length of `Idempotency-Key` (`255`, `R73`).
pub const MAX_IDEMPOTENCY_KEY_BYTES: usize = 255;

/// Dispatch strategy for invoking the synchronous [`IdempotencyStore`] port from async middleware
/// (`R73`, `R05`).
#[derive(Clone)]
pub enum StoreDispatch {
    /// Invoke fast in-memory stores directly on the worker thread without spawning.
    Inline(Arc<dyn IdempotencyStore>),
    /// Offload blocking I/O stores (SQL/Redis) onto Tokio's blocking thread pool.
    Offload(Arc<dyn IdempotencyStore>),
}

impl std::fmt::Debug for StoreDispatch {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Inline(_) => f.write_str("StoreDispatch::Inline(..)"),
            Self::Offload(_) => f.write_str("StoreDispatch::Offload(..)"),
        }
    }
}

impl StoreDispatch {
    async fn begin(
        &self,
        key: IdempotencyCacheKey,
        fingerprint: PayloadFingerprint,
    ) -> Result<IdempotencyBegin, PortError> {
        match self {
            Self::Inline(store) => store.begin(&key, fingerprint),
            Self::Offload(store) => {
                let store = Arc::clone(store);
                tokio::task::spawn_blocking(move || store.begin(&key, fingerprint))
                    .await
                    .map_err(|_| PortError::Unavailable {
                        detail: "idempotency store blocking task failed".to_owned(),
                    })?
            }
        }
    }

    async fn complete(
        &self,
        key: IdempotencyCacheKey,
        token: ClaimToken,
        outcome: CompletedOutcome,
    ) -> Result<bool, PortError> {
        match self {
            Self::Inline(store) => store.complete(&key, token, outcome),
            Self::Offload(store) => {
                let store = Arc::clone(store);
                tokio::task::spawn_blocking(move || store.complete(&key, token, outcome))
                    .await
                    .map_err(|_| PortError::Unavailable {
                        detail: "idempotency store blocking task failed".to_owned(),
                    })?
            }
        }
    }

    async fn abandon(
        &self,
        key: IdempotencyCacheKey,
        token: ClaimToken,
    ) -> Result<bool, PortError> {
        match self {
            Self::Inline(store) => store.abandon(&key, token),
            Self::Offload(store) => {
                let store = Arc::clone(store);
                tokio::task::spawn_blocking(move || store.abandon(&key, token))
                    .await
                    .map_err(|_| PortError::Unavailable {
                        detail: "idempotency store blocking task failed".to_owned(),
                    })?
            }
        }
    }

    fn abandon_on_drop(&self, key: IdempotencyCacheKey, token: ClaimToken) {
        match self {
            Self::Inline(store) => {
                if let Err(err) = store.abandon(&key, token) {
                    tracing::warn!(error = %err, "failed to abandon idempotency claim on drop");
                }
            }
            Self::Offload(store) => {
                let store = Arc::clone(store);
                if let Ok(handle) = tokio::runtime::Handle::try_current() {
                    handle.spawn_blocking(move || {
                        if let Err(err) = store.abandon(&key, token) {
                            tracing::warn!(
                                error = %err,
                                "failed to abandon offloaded idempotency claim on drop"
                            );
                        }
                    });
                } else if let Err(err) = store.abandon(&key, token) {
                    tracing::warn!(error = %err, "failed to abandon idempotency claim on drop");
                }
            }
        }
    }
}

/// Configuration state supplied to [`idempotency_middleware`] and [`apply_idempotency`] (`R73`).
#[derive(Debug, Clone)]
pub struct IdempotencyConfig {
    /// Store dispatch mode (`Inline` or `Offload`).
    pub dispatch: StoreDispatch,
    /// Maximum request and cached-response body size in bytes.
    pub max_body_bytes: usize,
    /// RFC 9457 `type` base URI for middleware error envelopes.
    pub problem_base_uri: String,
}

/// Compute the 32-byte SHA-256 payload fingerprint for `body` (`R73` criterion 21).
#[must_use]
pub fn compute_fingerprint(body: &[u8]) -> PayloadFingerprint {
    let digest = Sha256::digest(body);
    let mut out = [0u8; 32];
    out.copy_from_slice(&digest);
    out
}

struct AbandonOnDrop {
    dispatch: StoreDispatch,
    key: Option<IdempotencyCacheKey>,
    token: ClaimToken,
}

impl AbandonOnDrop {
    const fn new(dispatch: StoreDispatch, key: IdempotencyCacheKey, token: ClaimToken) -> Self {
        Self {
            dispatch,
            key: Some(key),
            token,
        }
    }

    fn disarm(&mut self) -> Option<IdempotencyCacheKey> {
        self.key.take()
    }
}

impl Drop for AbandonOnDrop {
    fn drop(&mut self) {
        if let Some(key) = self.key.take() {
            self.dispatch.abandon_on_drop(key, self.token);
        }
    }
}

enum DryRunState {
    Normal,
    Bypass,
}

fn inspect_dry_run(
    query: Option<&str>,
    base_uri: &str,
    path: &str,
) -> Result<DryRunState, WebError> {
    let Some(raw_q) = query else {
        return Ok(DryRunState::Normal);
    };
    let pairs = parse_query_pairs(raw_q).map_err(|()| {
        WebError::framework(
            StatusCode::BAD_REQUEST,
            "invalid_query_parameter",
            ErrorCode::Usage,
            "Query string contains invalid percent-encoding.",
            base_uri,
            Some(path),
        )
    })?;
    let mut found: Option<Option<String>> = None;
    for (k, v) in pairs {
        if k == "dry_run" {
            if found.is_some() {
                return Err(WebError::framework(
                    StatusCode::BAD_REQUEST,
                    "invalid_query_parameter",
                    ErrorCode::Usage,
                    "Duplicate 'dry_run' query parameter.",
                    base_uri,
                    Some(path),
                ));
            }
            found = Some(v);
        }
    }
    match found {
        None => Ok(DryRunState::Normal),
        Some(Some(val)) if val == "true" => Ok(DryRunState::Bypass),
        Some(Some(val)) if val == "false" => Ok(DryRunState::Normal),
        Some(_) => Err(WebError::framework(
            StatusCode::BAD_REQUEST,
            "invalid_query_parameter",
            ErrorCode::Usage,
            "Query parameter 'dry_run' must be 'true' or 'false'.",
            base_uri,
            Some(path),
        )),
    }
}

fn is_unsafe_method(method: &Method) -> bool {
    matches!(
        *method,
        Method::POST | Method::PUT | Method::PATCH | Method::DELETE
    )
}

fn is_valid_idempotency_key(key: &str) -> bool {
    !key.is_empty()
        && key.len() <= MAX_IDEMPOTENCY_KEY_BYTES
        && key.bytes().all(|b| (0x21..=0x7e).contains(&b))
}

fn is_correlation_or_replay_header(name: &HeaderName) -> bool {
    let s = name.as_str();
    s.eq_ignore_ascii_case("request-id")
        || s.eq_ignore_ascii_case("traceparent")
        || s.eq_ignore_ascii_case("tracestate")
        || s.eq_ignore_ascii_case("idempotency-replayed")
}

/// Axum middleware enforcing `Idempotency-Key` semantics (`R73`).
pub async fn idempotency_middleware(
    State(cfg): State<IdempotencyConfig>,
    req: Request,
    next: Next,
) -> Response {
    if !is_unsafe_method(req.method()) {
        return next.run(req).await;
    }

    let path = req.uri().path().to_owned();
    let base_uri = cfg.problem_base_uri.as_str();

    // Extract & validate single Idempotency-Key header.
    let mut header_iter = req.headers().get_all(IDEMPOTENCY_KEY_HEADER).iter();
    let Some(first_hv) = header_iter.next() else {
        return next.run(req).await;
    };
    if header_iter.next().is_some() {
        return WebError::framework(
            StatusCode::BAD_REQUEST,
            "duplicate_idempotency_key",
            ErrorCode::Usage,
            "Only a single Idempotency-Key header is permitted.",
            base_uri,
            Some(&path),
        )
        .into_response();
    }
    let Ok(key_str) = first_hv.to_str() else {
        return WebError::framework(
            StatusCode::BAD_REQUEST,
            "invalid_idempotency_key",
            ErrorCode::Usage,
            "Idempotency-Key must be printable ASCII without whitespace.",
            base_uri,
            Some(&path),
        )
        .into_response();
    };
    if !is_valid_idempotency_key(key_str) {
        return WebError::framework(
            StatusCode::BAD_REQUEST,
            "invalid_idempotency_key",
            ErrorCode::Usage,
            "Idempotency-Key must be 1..=255 printable ASCII characters with no whitespace.",
            base_uri,
            Some(&path),
        )
        .into_response();
    }
    let idempotency_key = key_str.to_owned();

    // Criterion 26: dry_run=true bypasses without claiming or consuming the key; invalid -> 400.
    match inspect_dry_run(req.uri().query(), base_uri, &path) {
        Ok(DryRunState::Bypass) => return next.run(req).await,
        Ok(DryRunState::Normal) => {}
        Err(err) => return err.into_response(),
    }

    let method = req.method().as_str().to_owned();
    let query = req.uri().query().unwrap_or("").to_owned();
    let (parts, body) = req.into_parts();

    // Buffer request body up to max_body_bytes before claiming (w08).
    let req_bytes = match axum::body::to_bytes(body, cfg.max_body_bytes).await {
        Ok(bytes) => bytes,
        Err(_) => {
            return WebError::framework(
                StatusCode::PAYLOAD_TOO_LARGE,
                "payload_too_large",
                ErrorCode::Usage,
                "Request body exceeds the maximum allowed size.",
                base_uri,
                Some(&path),
            )
            .into_response();
        }
    };

    let fingerprint = compute_fingerprint(&req_bytes);
    let cache_key = IdempotencyCacheKey {
        method,
        path: path.clone(),
        query,
        idempotency_key,
    };

    let token = match cfg.dispatch.begin(cache_key.clone(), fingerprint).await {
        Ok(IdempotencyBegin::Fresh(token)) => token,
        Ok(IdempotencyBegin::Replay(cached)) => return build_replay_response(cached),
        Ok(IdempotencyBegin::Mismatch) => {
            return WebError::framework(
                StatusCode::UNPROCESSABLE_ENTITY,
                "idempotency_key_mismatch",
                ErrorCode::Usage,
                "Idempotency-Key was already used with a different request payload.",
                base_uri,
                Some(&path),
            )
            .into_response();
        }
        Ok(IdempotencyBegin::InFlight) => {
            return WebError::framework(
                StatusCode::CONFLICT,
                "idempotency_in_flight",
                ErrorCode::Conflict,
                "A request with this Idempotency-Key is currently in progress.",
                base_uri,
                Some(&path),
            )
            .into_response();
        }
        Ok(IdempotencyBegin::Completed) => {
            return WebError::framework(
                StatusCode::CONFLICT,
                "idempotency_unreplayable",
                ErrorCode::Conflict,
                "A request with this Idempotency-Key already completed but its response cannot be replayed.",
                base_uri,
                Some(&path),
            )
            .into_response();
        }
        Err(err) => {
            tracing::error!(error = %err, "idempotency store unavailable during begin");
            return WebError::service_unavailable(
                base_uri,
                &path,
                "Idempotency store is temporarily unavailable.",
            )
            .into_response();
        }
    };

    let mut guard = AbandonOnDrop::new(cfg.dispatch.clone(), cache_key, token);
    let rebuilt_req = Request::from_parts(parts, Body::from(req_bytes));
    let response = next.run(rebuilt_req).await;

    if !response.status().is_success() {
        if let Some(key) = guard.disarm()
            && let Err(err) = cfg.dispatch.abandon(key, token).await
        {
            tracing::warn!(error = %err, "failed to abandon idempotency claim after non-2xx");
        }
        return response;
    }

    // 2xx response: buffer up to `max_body_bytes`; if exceeded, stream whole response to caller
    // and mark the claim `CompletedOutcome::Unreplayable` so retries return 409 (w09).
    let (resp_parts, mut resp_body) = response.into_parts();
    let mut chunks: VecDeque<Bytes> = VecDeque::new();
    let mut total_bytes: usize = 0;
    let mut exceeded = false;
    let mut stream_err = false;

    loop {
        let next_frame = std::future::poll_fn(|cx| Pin::new(&mut resp_body).poll_frame(cx)).await;
        match next_frame {
            None => break,
            Some(Ok(frame)) => {
                if let Ok(data) = frame.into_data() {
                    total_bytes = total_bytes.saturating_add(data.len());
                    chunks.push_back(data);
                    if total_bytes > cfg.max_body_bytes {
                        exceeded = true;
                        break;
                    }
                }
            }
            Some(Err(_)) => {
                stream_err = true;
                break;
            }
        }
    }

    if stream_err {
        if let Some(key) = guard.disarm() {
            let _ = cfg
                .dispatch
                .complete(key, token, CompletedOutcome::Unreplayable)
                .await;
        }
        let body = Body::new(PrefixBody {
            prefix: chunks,
            tail: resp_body,
        });
        return Response::from_parts(resp_parts, body);
    }

    if exceeded {
        if let Some(key) = guard.disarm()
            && let Err(err) = cfg
                .dispatch
                .complete(key, token, CompletedOutcome::Unreplayable)
                .await
        {
            tracing::warn!(error = %err, "failed to mark oversize 2xx response unreplayable");
        }
        let body = Body::new(PrefixBody {
            prefix: chunks,
            tail: resp_body,
        });
        return Response::from_parts(resp_parts, body);
    }

    let mut full_body = Vec::with_capacity(total_bytes);
    for chunk in chunks {
        full_body.extend_from_slice(&chunk);
    }

    let mut stored_headers = Vec::with_capacity(resp_parts.headers.len());
    for (name, value) in &resp_parts.headers {
        if !is_correlation_or_replay_header(name) {
            stored_headers.push((name.as_str().to_owned(), value.as_bytes().to_vec()));
        }
    }

    let cached = CachedResponse {
        status: resp_parts.status.as_u16(),
        headers: stored_headers,
        body: full_body.clone(),
    };

    if let Some(key) = guard.disarm()
        && let Err(err) = cfg
            .dispatch
            .complete(key, token, CompletedOutcome::Replayable(cached))
            .await
    {
        tracing::warn!(error = %err, "failed to persist replayable 2xx idempotency outcome");
    }

    Response::from_parts(resp_parts, Body::from(full_body))
}

fn build_replay_response(cached: CachedResponse) -> Response {
    let status = StatusCode::from_u16(cached.status).unwrap_or(StatusCode::OK);
    let mut response = Response::new(Body::from(cached.body));
    *response.status_mut() = status;
    for (name, raw_val) in cached.headers {
        if let (Ok(hn), Ok(hv)) = (
            HeaderName::from_bytes(name.as_bytes()),
            HeaderValue::from_bytes(&raw_val),
        ) && !is_correlation_or_replay_header(&hn)
        {
            response.headers_mut().append(hn, hv);
        }
    }
    response.headers_mut().insert(
        IDEMPOTENCY_REPLAYED_HEADER,
        HeaderValue::from_static(IDEMPOTENCY_REPLAYED_VALUE),
    );
    response
}

/// Body adapter yielding already-buffered chunks before lazily forwarding remaining frames from
/// an inner [`Body`].
struct PrefixBody {
    prefix: VecDeque<Bytes>,
    tail: Body,
}

impl HttpBody for PrefixBody {
    type Data = Bytes;
    type Error = axum::Error;

    fn poll_frame(
        mut self: Pin<&mut Self>,
        cx: &mut Context<'_>,
    ) -> Poll<Option<Result<Frame<Self::Data>, Self::Error>>> {
        if let Some(chunk) = self.prefix.pop_front() {
            return Poll::Ready(Some(Ok(Frame::data(chunk))));
        }
        Pin::new(&mut self.tail).poll_frame(cx)
    }
}

/// Apply [`idempotency_middleware`] as a route-scoped layer on `router` (`R73`).
pub fn apply_idempotency(router: Router, config: IdempotencyConfig) -> Router {
    router.route_layer(middleware::from_fn_with_state(
        config,
        idempotency_middleware,
    ))
}
