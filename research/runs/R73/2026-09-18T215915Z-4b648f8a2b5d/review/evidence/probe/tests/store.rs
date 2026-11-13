//! Store checks `s01`-`s10`. Plain `#[test]`, no `#[tokio::test]`, no runtime in
//! scope: the port is synchronous, which is what R05's "no executor in the
//! library crate" requires.

use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use std::time::Instant;

use r73_probe::adapter::InMemoryIdempotencyStore;
use r73_probe::port::{
    Begin, CacheKey, CachedResponse, Clock, Fingerprint, IdempotencyStore, PortError,
};

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

fn key(idempotency_key: &str) -> CacheKey {
    CacheKey {
        method: "POST".to_owned(),
        path: "/things".to_owned(),
        query: String::new(),
        idempotency_key: idempotency_key.to_owned(),
    }
}

fn fingerprint(byte: u8) -> Fingerprint {
    Fingerprint([byte; 32])
}

fn saved() -> CachedResponse {
    CachedResponse {
        status: 201,
        headers: vec![("content-type".to_owned(), b"application/json".to_vec())],
        body: b"{\"id\":1}".to_vec(),
    }
}

/// ttl 60_000 ms, in-flight 1_000 ms, 1_024 entries.
fn store(clock: Arc<TestClock>) -> Arc<InMemoryIdempotencyStore> {
    Arc::new(InMemoryIdempotencyStore::new(60_000, 1_000, 1_024, clock))
}

#[test]
fn s01_fresh_then_in_flight_then_replay() {
    let clock = Arc::new(TestClock::default());
    let store = store(Arc::clone(&clock));
    let k = key("k1");
    let f = fingerprint(1);

    assert_eq!(store.begin(&k, &f).unwrap(), Begin::Fresh, "s01: first claim");
    assert_eq!(
        store.begin(&k, &f).unwrap(),
        Begin::InFlight,
        "s01: the claim is the in-flight marker"
    );
    store.complete(&k, Some(saved())).unwrap();
    assert_eq!(
        store.begin(&k, &f).unwrap(),
        Begin::Replay(saved()),
        "s01: the completed outcome replays byte-for-byte"
    );
}

#[test]
fn s02_fingerprint_mismatch() {
    let clock = Arc::new(TestClock::default());
    let store = store(Arc::clone(&clock));
    let k = key("k1");
    assert_eq!(store.begin(&k, &fingerprint(1)).unwrap(), Begin::Fresh);
    assert_eq!(
        store.begin(&k, &fingerprint(2)).unwrap(),
        Begin::Mismatch,
        "s02: the same key with a different payload is a mismatch, not a new operation"
    );
    store.complete(&k, Some(saved())).unwrap();
    assert_eq!(
        store.begin(&k, &fingerprint(2)).unwrap(),
        Begin::Mismatch,
        "s02: mismatch outranks replay on a completed entry too"
    );
}

#[test]
fn s03_abandon_releases_the_claim() {
    let clock = Arc::new(TestClock::default());
    let store = store(Arc::clone(&clock));
    let k = key("k1");
    let f = fingerprint(1);
    assert_eq!(store.begin(&k, &f).unwrap(), Begin::Fresh);
    store.abandon(&k).unwrap();
    assert_eq!(
        store.begin(&k, &f).unwrap(),
        Begin::Fresh,
        "s03: an abandoned claim is free again"
    );
    store.complete(&k, Some(saved())).unwrap();
    store.abandon(&k).unwrap();
    assert_eq!(
        store.begin(&k, &f).unwrap(),
        Begin::Replay(saved()),
        "s03: abandon never removes a completed entry"
    );
}

#[test]
fn s04_ttl_boundary_asserted_at_one_millisecond() {
    let clock = Arc::new(TestClock::default());
    let store = store(Arc::clone(&clock));
    let k = key("k1");
    let f = fingerprint(1);
    store.begin(&k, &f).unwrap();
    store.complete(&k, Some(saved())).unwrap();

    clock.set(59_999);
    assert_eq!(
        store.begin(&k, &f).unwrap(),
        Begin::Replay(saved()),
        "s04: one millisecond inside the ttl the entry still replays"
    );
    clock.set(60_000);
    assert_eq!(
        store.begin(&k, &f).unwrap(),
        Begin::Fresh,
        "s04: at the ttl the entry is gone and the key is claimable"
    );
}

#[test]
fn s05_in_flight_deadline_is_separate_and_shorter() {
    let clock = Arc::new(TestClock::default());
    let store = store(Arc::clone(&clock));
    let k = key("k1");
    let f = fingerprint(1);
    store.begin(&k, &f).unwrap();

    clock.set(999);
    assert_eq!(
        store.begin(&k, &f).unwrap(),
        Begin::InFlight,
        "s05: inside the in-flight deadline the claim holds"
    );
    clock.set(1_000);
    assert_eq!(
        store.begin(&k, &f).unwrap(),
        Begin::Fresh,
        "s05: a stalled claim expires at 1_000 ms, far short of the 60_000 ms entry ttl"
    );
}

#[test]
fn s06_eviction_removes_the_least_recently_used() {
    let clock = Arc::new(TestClock::default());
    let store = Arc::new(InMemoryIdempotencyStore::new(60_000, 1_000, 3, clock));
    let f = fingerprint(1);
    for name in ["a", "b", "c"] {
        store.begin(&key(name), &f).unwrap();
        store.complete(&key(name), Some(saved())).unwrap();
    }
    // Touch "a" so it is the most recently *used* while still the least
    // recently *written*.
    assert_eq!(store.begin(&key("a"), &f).unwrap(), Begin::Replay(saved()));

    store.begin(&key("d"), &f).unwrap();
    assert_eq!(store.len(), 3, "s06: the store stays at max_entries");
    assert_eq!(
        store.begin(&key("a"), &f).unwrap(),
        Begin::Replay(saved()),
        "s06: the touched entry survived"
    );
    assert_eq!(
        store.begin(&key("b"), &f).unwrap(),
        Begin::Fresh,
        "s06: the least recently used entry was evicted, not the oldest written"
    );
}

#[test]
fn s07_keys_are_scoped_by_method_path_and_query() {
    let clock = Arc::new(TestClock::default());
    let store = store(Arc::clone(&clock));
    let f = fingerprint(1);
    let base = key("k1");
    store.begin(&base, &f).unwrap();
    store.complete(&base, Some(saved())).unwrap();

    for variant in [
        CacheKey {
            method: "PATCH".to_owned(),
            ..base.clone()
        },
        CacheKey {
            path: "/others".to_owned(),
            ..base.clone()
        },
        CacheKey {
            query: "a=1".to_owned(),
            ..base.clone()
        },
    ] {
        assert_eq!(
            store.begin(&variant, &f).unwrap(),
            Begin::Fresh,
            "s07: {variant:?} must not replay the base key's outcome"
        );
    }
}

#[test]
fn s08_hit_path_cost_at_one_thousand_twenty_four_entries() {
    let clock = Arc::new(TestClock::default());
    let store = store(Arc::clone(&clock));
    let f = fingerprint(1);
    for index in 0..1_024u32 {
        let k = key(&format!("key-{index}"));
        store.begin(&k, &f).unwrap();
        store.complete(&k, Some(saved())).unwrap();
    }
    let hot = key("key-512");
    // Warm, then measure.
    for _ in 0..1_000 {
        store.begin(&hot, &f).unwrap();
    }
    let iterations = 10_000u32;
    let started = Instant::now();
    for _ in 0..iterations {
        let outcome = store.begin(&hot, &f).unwrap();
        assert!(matches!(outcome, Begin::Replay(_)), "s08: measuring the hit path");
    }
    let per_op = started.elapsed().as_nanos() / u128::from(iterations);
    println!("s08 ns_per_op={per_op} entries=1024 iterations={iterations}");
    assert!(
        per_op < 1_000_000,
        "s08: the hit path must stay far below one millisecond, measured {per_op} ns/op"
    );
}

#[test]
fn s09_blanket_arc_impl_and_erased_handle() {
    fn assert_send_sync<T: Send + Sync>() {}
    assert_send_sync::<Arc<dyn IdempotencyStore>>();

    let clock = Arc::new(TestClock::default());
    let concrete = store(Arc::clone(&clock));
    // The blanket `impl for Arc<T>` means the Arc itself is a store.
    let through_arc: &dyn IdempotencyStore = &concrete;
    let k = key("k1");
    let f = fingerprint(1);
    assert_eq!(through_arc.begin(&k, &f).unwrap(), Begin::Fresh);

    // ...and erasing to `Arc<dyn IdempotencyStore>` is what the composition root does.
    let erased: Arc<dyn IdempotencyStore> = concrete;
    assert_eq!(
        erased.begin(&k, &f).unwrap(),
        Begin::InFlight,
        "s09: the erased handle reaches the same store"
    );
}

#[test]
fn s10_poisoned_lock_returns_unavailable_rather_than_panicking() {
    let clock = Arc::new(TestClock::default());
    let store = store(Arc::clone(&clock));
    let k = key("k1");
    let f = fingerprint(1);
    assert_eq!(store.begin(&k, &f).unwrap(), Begin::Fresh);

    store.poison();

    // R03 rule 5: the poisoned-`Mutex` case is `PortError::Unavailable`.
    // The raw report recommended this and did not execute it; this check does.
    for outcome in [
        store.begin(&k, &f).err(),
        store.complete(&k, Some(saved())).err(),
        store.abandon(&k).err(),
    ] {
        let Some(PortError::Unavailable { detail }) = outcome else {
            panic!("s10: every port method must return Unavailable once the lock is poisoned");
        };
        assert!(
            detail.contains("poisoned"),
            "s10: the detail names the cause, got {detail:?}"
        );
    }
}
