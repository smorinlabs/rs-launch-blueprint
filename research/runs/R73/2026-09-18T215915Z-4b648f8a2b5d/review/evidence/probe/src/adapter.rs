//! The shipped in-memory production adapter. Stands in for the root package's
//! composition root.
//!
//! One `std::sync::Mutex<Inner>`. Expiry is checked on the entry touched, never
//! by sweeping — the raw report measured a sweep-every-call design at
//! 477,159 ns/op debug against 1,595 ns/op for this one. Eviction removes the
//! minimum `used` tick, and only when an insert would exceed `max_entries`, so
//! the O(n) work sits on the insert-when-full path and not on the hit path.

use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::time::Instant;

use crate::port::{Begin, CacheKey, CachedResponse, Clock, Fingerprint, IdempotencyStore, PortError};

#[derive(Debug)]
enum Slot {
    InFlight {
        fingerprint: Fingerprint,
        at: u64,
        used: u64,
    },
    Done {
        fingerprint: Fingerprint,
        at: u64,
        used: u64,
        /// `None` records a completed but unreplayable outcome (an unknown-length
        /// or oversize 2xx that streamed through uncached).
        response: Option<CachedResponse>,
    },
}

impl Slot {
    fn at(&self) -> u64 {
        match self {
            Slot::InFlight { at, .. } | Slot::Done { at, .. } => *at,
        }
    }
    fn used(&self) -> u64 {
        match self {
            Slot::InFlight { used, .. } | Slot::Done { used, .. } => *used,
        }
    }
    fn set_used(&mut self, tick: u64) {
        match self {
            Slot::InFlight { used, .. } | Slot::Done { used, .. } => *used = tick,
        }
    }
    fn fingerprint(&self) -> Fingerprint {
        match self {
            Slot::InFlight { fingerprint, .. } | Slot::Done { fingerprint, .. } => *fingerprint,
        }
    }
}

#[derive(Debug, Default)]
struct Inner {
    slots: HashMap<CacheKey, Slot>,
    tick: u64,
}

pub struct SystemClock {
    origin: Instant,
}

impl Default for SystemClock {
    fn default() -> Self {
        Self {
            origin: Instant::now(),
        }
    }
}

impl Clock for SystemClock {
    fn now_millis(&self) -> u64 {
        u64::try_from(self.origin.elapsed().as_millis()).unwrap_or(u64::MAX)
    }
}

pub struct InMemoryIdempotencyStore {
    inner: Mutex<Inner>,
    ttl_millis: u64,
    in_flight_millis: u64,
    max_entries: usize,
    clock: Arc<dyn Clock>,
}

impl InMemoryIdempotencyStore {
    pub fn new(
        ttl_millis: u64,
        in_flight_millis: u64,
        max_entries: usize,
        clock: Arc<dyn Clock>,
    ) -> Self {
        Self {
            inner: Mutex::new(Inner::default()),
            ttl_millis,
            in_flight_millis,
            max_entries,
            clock,
        }
    }

    /// Test-only reach-in: how many slots are resident. Used by `s06`.
    pub fn len(&self) -> usize {
        self.inner.lock().map(|g| g.slots.len()).unwrap_or(0)
    }

    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }

    /// Deliberately poison the mutex, so check `s10` can execute the branch the
    /// raw report's probe did not (`raw/opus.md:1298-1302`).
    pub fn poison(self: &Arc<Self>) {
        let me = Arc::clone(self);
        let handle = std::thread::spawn(move || {
            let _guard = me.inner.lock().expect("fresh lock");
            panic!("deliberate poison for check s10");
        });
        assert!(handle.join().is_err(), "the poisoning thread must panic");
    }

    fn expired(&self, slot: &Slot, now: u64) -> bool {
        let age = now.saturating_sub(slot.at());
        match slot {
            Slot::Done { .. } => age >= self.ttl_millis,
            Slot::InFlight { .. } => age >= self.in_flight_millis,
        }
    }
}

fn lock_poisoned() -> PortError {
    // R03 rule 5: the poisoned-Mutex case is `PortError::Unavailable`, mapped to
    // the catalogue's `RSLB101`. The adapter returns it rather than panicking.
    PortError::Unavailable {
        detail: "idempotency store lock poisoned".to_owned(),
    }
}

impl IdempotencyStore for InMemoryIdempotencyStore {
    fn begin(&self, key: &CacheKey, fingerprint: &Fingerprint) -> Result<Begin, PortError> {
        let now = self.clock.now_millis();
        let mut guard = self.inner.lock().map_err(|_| lock_poisoned())?;
        guard.tick = guard.tick.saturating_add(1);
        let tick = guard.tick;

        let stale = guard
            .slots
            .get(key)
            .is_some_and(|slot| self.expired(slot, now));
        if stale {
            guard.slots.remove(key);
        }

        if let Some(slot) = guard.slots.get_mut(key) {
            if slot.fingerprint() != *fingerprint {
                return Ok(Begin::Mismatch);
            }
            slot.set_used(tick);
            return Ok(match slot {
                Slot::InFlight { .. } => Begin::InFlight,
                Slot::Done {
                    response: Some(saved),
                    ..
                } => Begin::Replay(saved.clone()),
                Slot::Done { response: None, .. } => Begin::Completed,
            });
        }

        if guard.slots.len() >= self.max_entries
            && let Some(victim) = guard
                .slots
                .iter()
                .min_by_key(|(_, slot)| slot.used())
                .map(|(k, _)| k.clone())
        {
            guard.slots.remove(&victim);
        }

        guard.slots.insert(
            key.clone(),
            Slot::InFlight {
                fingerprint: *fingerprint,
                at: now,
                used: tick,
            },
        );
        Ok(Begin::Fresh)
    }

    fn complete(&self, key: &CacheKey, response: Option<CachedResponse>) -> Result<(), PortError> {
        let now = self.clock.now_millis();
        let mut guard = self.inner.lock().map_err(|_| lock_poisoned())?;
        guard.tick = guard.tick.saturating_add(1);
        let tick = guard.tick;
        // Only an outstanding claim may be completed. If the claim was evicted
        // or expired meanwhile, the completion is dropped rather than resurrecting
        // an entry whose fingerprint this call does not carry.
        let fingerprint = match guard.slots.get(key) {
            Some(Slot::InFlight { fingerprint, .. }) => *fingerprint,
            _ => return Ok(()),
        };
        guard.slots.insert(
            key.clone(),
            Slot::Done {
                fingerprint,
                at: now,
                used: tick,
                response,
            },
        );
        Ok(())
    }

    fn abandon(&self, key: &CacheKey) -> Result<(), PortError> {
        let mut guard = self.inner.lock().map_err(|_| lock_poisoned())?;
        if matches!(guard.slots.get(key), Some(Slot::InFlight { .. })) {
            guard.slots.remove(key);
        }
        Ok(())
    }
}
