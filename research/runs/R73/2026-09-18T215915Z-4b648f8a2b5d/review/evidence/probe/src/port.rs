//! The driven port. Stands in for `crates/core/src/idempotency.rs`.
//!
//! R01's registered `http-transport-injection-seam` constraints are structural
//! here and are asserted by check `s09`: `Send + Sync`, no `async fn`, no
//! generic methods, no associated consts, no non-receiver `Self`, a blanket
//! `impl` for `Arc<T>`, erased to `Arc<dyn IdempotencyStore>`.

use std::fmt;
use std::sync::Arc;

/// py's `_CacheKey` shape at `idempotency.py:48-62`, including the query
/// string, whose presence py justifies in a comment at `:99-101`.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct CacheKey {
    pub method: String,
    pub path: String,
    pub query: String,
    pub idempotency_key: String,
}

/// A SHA-256 digest of the request payload. Compared, never keyed.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Fingerprint(pub [u8; 32]);

/// py's `_Entry` shape at `idempotency.py:65-77`: status as a `u16`, headers as
/// raw name/value pairs rather than a map so multi-valued headers survive, body
/// as bytes. Identical to Zero To Production's `HeaderPairRecord`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CachedResponse {
    pub status: u16,
    pub headers: Vec<(String, Vec<u8>)>,
    pub body: Vec<u8>,
}

/// The compare-and-set outcome. Zero To Production's `NextAction` widened by the
/// two states the design needs and ZTP does not implement.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Begin {
    /// The key was free and is now claimed by this caller.
    Fresh,
    /// Another request holds the claim and has not completed.
    InFlight,
    /// A completed outcome is stored for this key; replay it.
    Replay(CachedResponse),
    /// The operation completed but its outcome is not replayable — the 2xx body
    /// had unknown or oversize length, so it was streamed through uncached.
    /// Re-executing would break the standard's R3.9 guarantee, so the caller
    /// answers a retry rather than running the handler again.
    Completed,
    /// The key is known but the payload fingerprint differs.
    Mismatch,
}

/// R03 rule 2's shape: `#[non_exhaustive]`, no `NotFound` variant.
/// Hand-implemented rather than `thiserror`-derived; see `lib.rs`.
#[derive(Debug)]
#[non_exhaustive]
pub enum PortError {
    Unavailable { detail: String },
}

impl fmt::Display for PortError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            PortError::Unavailable { detail } => write!(f, "store unavailable: {detail}"),
        }
    }
}

impl std::error::Error for PortError {}

/// The seam F315 names. A Redis adapter implements `begin` with `SET key .. NX`;
/// a Postgres adapter with `INSERT .. ON CONFLICT DO NOTHING`.
pub trait IdempotencyStore: Send + Sync {
    fn begin(&self, key: &CacheKey, fingerprint: &Fingerprint) -> Result<Begin, PortError>;
    fn complete(&self, key: &CacheKey, response: Option<CachedResponse>) -> Result<(), PortError>;
    fn abandon(&self, key: &CacheKey) -> Result<(), PortError>;
}

impl<T: IdempotencyStore + ?Sized> IdempotencyStore for Arc<T> {
    fn begin(&self, key: &CacheKey, fingerprint: &Fingerprint) -> Result<Begin, PortError> {
        (**self).begin(key, fingerprint)
    }
    fn complete(&self, key: &CacheKey, response: Option<CachedResponse>) -> Result<(), PortError> {
        (**self).complete(key, response)
    }
    fn abandon(&self, key: &CacheKey) -> Result<(), PortError> {
        (**self).abandon(key)
    }
}

/// Injected clock: the difference between a TTL that is asserted and a TTL that
/// is slept through.
pub trait Clock: Send + Sync {
    fn now_millis(&self) -> u64;
}

/// The shipped fake. Always `Fresh`, never replays.
pub struct AlwaysFreshStore;

impl IdempotencyStore for AlwaysFreshStore {
    fn begin(&self, _key: &CacheKey, _fingerprint: &Fingerprint) -> Result<Begin, PortError> {
        Ok(Begin::Fresh)
    }
    fn complete(&self, _key: &CacheKey, _response: Option<CachedResponse>) -> Result<(), PortError> {
        Ok(())
    }
    fn abandon(&self, _key: &CacheKey) -> Result<(), PortError> {
        Ok(())
    }
}
