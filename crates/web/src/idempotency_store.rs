//! Compare-and-set idempotency store port and `std`-only in-memory adapter (`R73`, `OV-16`,
//! `OV-18`).
//!
//! Lives in `crates/web` so HTTP idempotency mechanics stay cleanly separated from the standalone
//! domain library (`crates/core` / `rs-launch-blueprint`).

use std::collections::HashMap;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use rs_launch_blueprint::PortError;

/// Default retention TTL for completed idempotency entries (`86,400 s` / 24 hours per R3.9).
pub const DEFAULT_IDEMPOTENCY_TTL: Duration = Duration::from_secs(86_400);

/// Default in-flight claim expiry deadline (strictly longer than the default 30 s request
/// timeout per `R73` clause 8).
pub const DEFAULT_IDEMPOTENCY_IN_FLIGHT: Duration = Duration::from_secs(60);

/// Default maximum entry capacity for [`InMemoryIdempotencyStore`] (`R73`, `OV-16`).
pub const DEFAULT_IDEMPOTENCY_MAX_ENTRIES: usize = 1024;

/// 32-byte SHA-256 request payload fingerprint stored alongside an idempotency entry (`R73`).
pub type PayloadFingerprint = [u8; 32];

/// Monotonic generation token proving ownership of an in-flight idempotency claim (`R73` clause 6).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct ClaimToken(u64);

impl ClaimToken {
    /// Construct a [`ClaimToken`] from a raw generation counter.
    #[must_use]
    pub const fn new(raw: u64) -> Self {
        Self(raw)
    }

    /// Return the underlying raw generation value.
    #[must_use]
    pub const fn raw(self) -> u64 {
        self.0
    }
}

/// Cache key scoping idempotency replay (`(method, path, query, idempotency-key)`, `R73` clause 4).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct IdempotencyCacheKey {
    /// HTTP method (e.g., `"POST"`).
    pub method: String,
    /// Request path without query string.
    pub path: String,
    /// Raw query string (empty when absent).
    pub query: String,
    /// Validated `Idempotency-Key` header value.
    pub idempotency_key: String,
}

/// Stored 2xx HTTP response replayed on genuine retries (`R73`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CachedResponse {
    /// HTTP 2xx status code.
    pub status: u16,
    /// Raw response header pairs excluding correlation headers (`request-id`, `traceparent`,
    /// `tracestate`).
    pub headers: Vec<(String, Vec<u8>)>,
    /// Buffered response body bytes.
    pub body: Vec<u8>,
}

/// Completed outcome persisted when an idempotent operation succeeds with a 2xx response (`R73`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CompletedOutcome {
    /// 2xx response buffered within the configured body cap and safe to replay verbatim.
    Replayable(CachedResponse),
    /// 2xx response exceeded the buffer cap or had unknown streaming length: retries answer `409`
    /// rather than re-executing the side effect (`R73` clause 10).
    Unreplayable,
}

/// Compare-and-set outcome returned by [`IdempotencyStore::begin`] (`R73` revision 4).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum IdempotencyBegin {
    /// Caller acquired an exclusive in-flight claim identified by this [`ClaimToken`].
    Fresh(ClaimToken),
    /// Another request with the same key and payload is currently executing (`409`).
    InFlight,
    /// A prior attempt completed with a replayable 2xx response.
    Replay(CachedResponse),
    /// A prior attempt completed with an unreplayable 2xx response (`409`, never re-execute).
    Completed,
    /// Key is active (in-flight or completed) with a different payload fingerprint (`422`).
    Mismatch,
}

/// Injectable monotonic clock seam for deterministic TTL and deadline testing (`R73`).
pub trait Clock: Send + Sync {
    /// Return the current monotonic instant.
    fn now(&self) -> Instant;
}

impl<T: Clock + ?Sized> Clock for Arc<T> {
    fn now(&self) -> Instant {
        (**self).now()
    }
}

/// Production [`Clock`] backed by [`Instant::now`].
#[derive(Debug, Default, Clone, Copy)]
pub struct SystemClock;

impl Clock for SystemClock {
    fn now(&self) -> Instant {
        Instant::now()
    }
}

/// Deterministic test [`Clock`] whose monotonic instant advances only when requested.
#[derive(Debug)]
pub struct FakeClock {
    current: Mutex<Instant>,
}

impl FakeClock {
    /// Create a [`FakeClock`] pinned at `start`.
    #[must_use]
    pub fn new(start: Instant) -> Self {
        Self {
            current: Mutex::new(start),
        }
    }

    /// Advance the simulated clock forward by `delta`.
    pub fn advance(&self, delta: Duration) {
        if let Ok(mut guard) = self.current.lock() {
            *guard += delta;
        }
    }
}

impl Clock for FakeClock {
    fn now(&self) -> Instant {
        self.current
            .lock()
            .map(|guard| *guard)
            .unwrap_or_else(|poisoned| *poisoned.into_inner())
    }
}

/// Synchronous, dyn-compatible driven port for `Idempotency-Key` compare-and-set persistence
/// (`R73`, `R01`, `R05`).
pub trait IdempotencyStore: Send + Sync {
    /// Atomically inspect or claim `key` for `fingerprint`.
    fn begin(
        &self,
        key: &IdempotencyCacheKey,
        fingerprint: PayloadFingerprint,
    ) -> Result<IdempotencyBegin, PortError>;

    /// Transition an owned in-flight claim into a completed entry.
    fn complete(
        &self,
        key: &IdempotencyCacheKey,
        token: ClaimToken,
        outcome: CompletedOutcome,
    ) -> Result<bool, PortError>;

    /// Release an owned in-flight claim after a non-2xx outcome, panic, or dropped future.
    fn abandon(&self, key: &IdempotencyCacheKey, token: ClaimToken) -> Result<bool, PortError>;
}

impl<T: IdempotencyStore + ?Sized> IdempotencyStore for Arc<T> {
    fn begin(
        &self,
        key: &IdempotencyCacheKey,
        fingerprint: PayloadFingerprint,
    ) -> Result<IdempotencyBegin, PortError> {
        (**self).begin(key, fingerprint)
    }

    fn complete(
        &self,
        key: &IdempotencyCacheKey,
        token: ClaimToken,
        outcome: CompletedOutcome,
    ) -> Result<bool, PortError> {
        (**self).complete(key, token, outcome)
    }

    fn abandon(&self, key: &IdempotencyCacheKey, token: ClaimToken) -> Result<bool, PortError> {
        (**self).abandon(key, token)
    }
}

#[derive(Debug)]
enum Slot {
    InFlight {
        token: ClaimToken,
        fingerprint: PayloadFingerprint,
        expires_at: Instant,
    },
    Done {
        fingerprint: PayloadFingerprint,
        outcome: CompletedOutcome,
        expires_at: Instant,
        last_used: u64,
    },
}

impl Slot {
    fn expires_at(&self) -> Instant {
        match self {
            Self::InFlight { expires_at, .. } | Self::Done { expires_at, .. } => *expires_at,
        }
    }
}

#[derive(Debug, Default)]
struct StoreInner {
    entries: HashMap<IdempotencyCacheKey, Slot>,
    lru_tick: u64,
    next_token: u64,
}

impl StoreInner {
    fn bump_tick(&mut self) -> u64 {
        self.lru_tick = self.lru_tick.saturating_add(1);
        self.lru_tick
    }

    fn alloc_token(&mut self) -> ClaimToken {
        self.next_token = self.next_token.saturating_add(1);
        ClaimToken::new(self.next_token)
    }
}

/// Process-local, bounded in-memory [`IdempotencyStore`] adapter (`R73`, `OV-16`).
pub struct InMemoryIdempotencyStore {
    ttl: Duration,
    in_flight_deadline: Duration,
    max_entries: usize,
    clock: Arc<dyn Clock>,
    inner: Mutex<StoreInner>,
}

impl std::fmt::Debug for InMemoryIdempotencyStore {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("InMemoryIdempotencyStore")
            .field("ttl", &self.ttl)
            .field("in_flight_deadline", &self.in_flight_deadline)
            .field("max_entries", &self.max_entries)
            .finish_non_exhaustive()
    }
}

impl Default for InMemoryIdempotencyStore {
    fn default() -> Self {
        Self::new(
            DEFAULT_IDEMPOTENCY_TTL,
            DEFAULT_IDEMPOTENCY_IN_FLIGHT,
            DEFAULT_IDEMPOTENCY_MAX_ENTRIES,
        )
    }
}

impl InMemoryIdempotencyStore {
    /// Construct a new store backed by [`SystemClock`].
    #[must_use]
    pub fn new(ttl: Duration, in_flight_deadline: Duration, max_entries: usize) -> Self {
        Self::with_clock(ttl, in_flight_deadline, max_entries, Arc::new(SystemClock))
    }

    /// Construct a new store with an explicitly injected [`Clock`] for deterministic tests.
    #[must_use]
    pub fn with_clock(
        ttl: Duration,
        in_flight_deadline: Duration,
        max_entries: usize,
        clock: impl Clock + 'static,
    ) -> Self {
        Self {
            ttl,
            in_flight_deadline,
            max_entries: max_entries.max(1),
            clock: Arc::new(clock),
            inner: Mutex::new(StoreInner::default()),
        }
    }

    fn lock_inner(&self) -> Result<std::sync::MutexGuard<'_, StoreInner>, PortError> {
        self.inner.lock().map_err(|_| PortError::Unavailable {
            detail: "idempotency store lock poisoned".to_owned(),
        })
    }
}

impl IdempotencyStore for InMemoryIdempotencyStore {
    fn begin(
        &self,
        key: &IdempotencyCacheKey,
        fingerprint: PayloadFingerprint,
    ) -> Result<IdempotencyBegin, PortError> {
        let mut inner = self.lock_inner()?;
        let now = self.clock.now();

        if inner
            .entries
            .get(key)
            .is_some_and(|slot| now >= slot.expires_at())
        {
            inner.entries.remove(key);
        }

        let tick = inner.bump_tick();
        if let Some(slot) = inner.entries.get_mut(key) {
            return match slot {
                Slot::InFlight {
                    fingerprint: fp, ..
                } => {
                    if *fp != fingerprint {
                        Ok(IdempotencyBegin::Mismatch)
                    } else {
                        Ok(IdempotencyBegin::InFlight)
                    }
                }
                Slot::Done {
                    fingerprint: fp,
                    outcome,
                    last_used,
                    ..
                } => {
                    if *fp != fingerprint {
                        Ok(IdempotencyBegin::Mismatch)
                    } else {
                        *last_used = tick;
                        match outcome {
                            CompletedOutcome::Replayable(cached) => {
                                Ok(IdempotencyBegin::Replay(cached.clone()))
                            }
                            CompletedOutcome::Unreplayable => Ok(IdempotencyBegin::Completed),
                        }
                    }
                }
            };
        }

        if inner.entries.len() >= self.max_entries {
            inner.entries.retain(|_, slot| now < slot.expires_at());
        }

        if inner.entries.len() >= self.max_entries {
            let victim = inner
                .entries
                .iter()
                .filter_map(|(k, slot)| match slot {
                    Slot::Done { last_used, .. } => Some((k.clone(), *last_used)),
                    Slot::InFlight { .. } => None,
                })
                .min_by_key(|(_, used)| *used)
                .map(|(k, _)| k);

            match victim {
                Some(evict_key) => {
                    inner.entries.remove(&evict_key);
                }
                None => {
                    return Err(PortError::Unavailable {
                        detail: "idempotency store at capacity with active in-flight claims"
                            .to_owned(),
                    });
                }
            }
        }

        let token = inner.alloc_token();
        inner.entries.insert(
            key.clone(),
            Slot::InFlight {
                token,
                fingerprint,
                expires_at: now + self.in_flight_deadline,
            },
        );
        Ok(IdempotencyBegin::Fresh(token))
    }

    fn complete(
        &self,
        key: &IdempotencyCacheKey,
        token: ClaimToken,
        outcome: CompletedOutcome,
    ) -> Result<bool, PortError> {
        let mut inner = self.lock_inner()?;
        let now = self.clock.now();
        let tick = inner.bump_tick();

        let matched = match inner.entries.get(key) {
            Some(Slot::InFlight {
                token: current,
                fingerprint,
                ..
            }) if *current == token => Some(*fingerprint),
            _ => None,
        };

        if let Some(fingerprint) = matched {
            inner.entries.insert(
                key.clone(),
                Slot::Done {
                    fingerprint,
                    outcome,
                    expires_at: now + self.ttl,
                    last_used: tick,
                },
            );
            Ok(true)
        } else {
            Ok(false)
        }
    }

    fn abandon(&self, key: &IdempotencyCacheKey, token: ClaimToken) -> Result<bool, PortError> {
        let mut inner = self.lock_inner()?;
        let matches = matches!(
            inner.entries.get(key),
            Some(Slot::InFlight { token: current, .. }) if *current == token
        );
        if matches {
            inner.entries.remove(key);
            Ok(true)
        } else {
            Ok(false)
        }
    }
}

/// Stateless fake [`IdempotencyStore`] that always grants a fresh claim (`R73` M2).
#[derive(Debug, Default)]
pub struct AlwaysFreshIdempotencyStore {
    next_token: AtomicU64,
}

impl AlwaysFreshIdempotencyStore {
    /// Create a new stateless [`AlwaysFreshIdempotencyStore`].
    #[must_use]
    pub const fn new() -> Self {
        Self {
            next_token: AtomicU64::new(1),
        }
    }
}

impl IdempotencyStore for AlwaysFreshIdempotencyStore {
    fn begin(
        &self,
        _key: &IdempotencyCacheKey,
        _fingerprint: PayloadFingerprint,
    ) -> Result<IdempotencyBegin, PortError> {
        let raw = self.next_token.fetch_add(1, Ordering::Relaxed);
        Ok(IdempotencyBegin::Fresh(ClaimToken::new(raw)))
    }

    fn complete(
        &self,
        _key: &IdempotencyCacheKey,
        _token: ClaimToken,
        _outcome: CompletedOutcome,
    ) -> Result<bool, PortError> {
        Ok(true)
    }

    fn abandon(&self, _key: &IdempotencyCacheKey, _token: ClaimToken) -> Result<bool, PortError> {
        Ok(true)
    }
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;
    use std::time::{Duration, Instant};

    use super::{
        CachedResponse, CompletedOutcome, FakeClock, IdempotencyBegin, IdempotencyCacheKey,
        IdempotencyStore, InMemoryIdempotencyStore,
    };

    fn k(id: &str, query: &str) -> IdempotencyCacheKey {
        IdempotencyCacheKey {
            method: "POST".to_owned(),
            path: "/v1/projects".to_owned(),
            query: query.to_owned(),
            idempotency_key: id.to_owned(),
        }
    }

    #[test]
    fn query_string_scopes_entries_and_lru_evicts_least_recently_used_done_entry() {
        let clock = Arc::new(FakeClock::new(Instant::now()));
        let store = InMemoryIdempotencyStore::with_clock(
            Duration::from_secs(60),
            Duration::from_secs(10),
            3,
            Arc::clone(&clock),
        );
        let fp = [1u8; 32];
        let resp = CachedResponse {
            status: 201,
            headers: Vec::new(),
            body: b"ok".to_vec(),
        };

        for name in ["a", "b", "c"] {
            let key = k(name, "");
            let IdempotencyBegin::Fresh(tok) = store.begin(&key, fp).unwrap() else {
                panic!("expected fresh");
            };
            assert!(
                store
                    .complete(&key, tok, CompletedOutcome::Replayable(resp.clone()))
                    .unwrap()
            );
        }
        assert!(matches!(
            store.begin(&k("a", ""), fp).unwrap(),
            IdempotencyBegin::Replay(_)
        ));
        let IdempotencyBegin::Fresh(tok_d) = store.begin(&k("d", ""), fp).unwrap() else {
            panic!("expected fresh d");
        };
        assert!(
            store
                .complete(&k("d", ""), tok_d, CompletedOutcome::Replayable(resp))
                .unwrap()
        );
        assert!(matches!(
            store.begin(&k("a", ""), fp).unwrap(),
            IdempotencyBegin::Replay(_)
        ));
        assert!(matches!(
            store.begin(&k("b", ""), fp).unwrap(),
            IdempotencyBegin::Fresh(_)
        ));
    }

    #[test]
    fn poisoned_mutex_returns_port_error_unavailable_without_panicking() {
        let store = Arc::new(InMemoryIdempotencyStore::default());
        let poison_clone = Arc::clone(&store);
        let _ = std::thread::spawn(move || {
            let _guard = poison_clone.inner.lock().unwrap();
            panic!("intentional poison");
        })
        .join();

        let key = k("k", "");
        let err = store.begin(&key, [0u8; 32]).unwrap_err();
        assert!(err.to_string().contains("poisoned"));
        assert!(
            store
                .complete(
                    &key,
                    super::ClaimToken::new(1),
                    CompletedOutcome::Unreplayable
                )
                .is_err()
        );
        assert!(store.abandon(&key, super::ClaimToken::new(1)).is_err());

        let tok = super::ClaimToken::new(42);
        assert_eq!(tok.raw(), 42);
        assert!(format!("{store:?}").contains("InMemoryIdempotencyStore"));

        let fc = Arc::new(FakeClock::new(Instant::now()));
        let fc2 = Arc::clone(&fc);
        let _ = std::thread::spawn(move || {
            let _g = fc2.current.lock().unwrap();
            panic!("poison fake clock");
        })
        .join();
        let _ = super::Clock::now(&fc);
        fc.advance(Duration::from_secs(1));
    }
}
