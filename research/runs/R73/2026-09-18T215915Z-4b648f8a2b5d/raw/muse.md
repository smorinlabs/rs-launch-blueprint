# Raw research answer — R73 idempotency middleware (bundle) — Muse engine

Engine: muse (Meta) substituting for Codex under the `engine_overrides` pilot. Retrieval date for all live figures: 2026-09-25.

### Landscape

Category decided: HTTP idempotency-key replay middleware for unsafe-method requests (POST/PUT/PATCH) with a 2xx-only, in-memory, single-instance cache — i.e. (a) the middleware-layer model, (b) the evictable in-memory store, (c) key derivation including a body hash.

Three-bin map of the Rust field:

- Built-in / first-party: no `Idempotency-Key` replay middleware exists in the standard library, nor in first-party middleware of the leading frameworks. `std::collections::HashMap` (+ `std::sync::Mutex`/`RwLock`) is the built-in store primitive. Exact-name probes on crates.io on 2026-09-25 returned HTTP 404 for `idempotency`, `tower-idempotency`, `axum-idempotency`, and `idempotency-key` (`GET https://crates.io/api/v1/crates/<name>`); the only near-name hit of substance is `minco-plugin-idempotency` (869 all-time downloads, a niche framework plugin, not a general middleware).
- Established industry standard: `tower` 0.5 (`Layer`/`Service` middleware model underpinning axum, tonic, hyper clients) for the middleware layer; `moka` 0.12 (`sync::Cache`: concurrent, bounded, TTL/TTI eviction) for the store; `sha2` 0.11 (RustCrypto) for body hashing in the composite cache key.
- Up-and-comer: `quick-cache` 0.7 (newer concurrent cache, S3-FIFO eviction); `mini-moka` 0.10 (moka's lightweight sibling, last release 2024-01-08, superseded by moka's own `future::Cache`/sync options).

Authoritative sources and why each counts: (1) crates.io API + docs.rs — maintainer-published metadata and API docs, authoritative for versions, features, MSRV declarations; (2) the tokio/tower project (`tower-rs/tower`) — first-party owner of the `Service`/`Layer` abstraction the whole async web stack builds on; (3) RustCrypto (`RustCrypto/hashes`) — the standing working-group-style maintainer collective for hashing crates; (4) `moka-rs/moka` repo + its benchmark suite vs `lru`/`quick-cache` — maintainer-run, workload-stated comparisons; (5) Stripe idempotency-key API docs — the originator of the "errors are retried, not replayed" semantics py mirrors; (6) Luke Maxwell, *Zero to Production in Rust* ch. 11 — the widely cited Rust web-service reference that documents idempotency keys as a named pattern (Postgres-backed variant).

Practice evidence (well-regarded projects, with standing evidence): axum (tokio team's web framework; depends on `tower`) — shows the tower `Layer` model is the integration surface R69 will almost surely land on; `aws-smithy-http-server` (AWS SDK server runtime; depends on `tower`) — production server use of tower middleware; moka reverse-dependencies total 705 crates including `activitypub_federation`, `cached`, `autumn-web` (crates.io `reverse_dependencies`, 2026-09-25) — broad production cache use; `sha2` reverse-dependencies total 19,594 crates — the default hash choice across the ecosystem. No mainstream Rust web template found documents Stripe-style in-memory idempotency replay middleware as a named reusable layer (gap recorded below); Z2P documents the DB-backed endpoint-level variant instead.

### Principles and implementation

Shared requirement (source: py precedent `src/py_launch_blueprint/web/idempotency.py`, F313/F314/F315; agreement level: architectural pattern + policy): unsafe-method requests carrying an `Idempotency-Key` header receive a replayed cached response on key repeat; only 2xx outcomes are cached so genuine errors are retried for real (Stripe semantics); the store is in-memory and single-instance by design, explicitly documented as a future distributed-store swap point.

Essential behaviors that must agree: (1) intercept POST/PUT/PATCH with the header before the handler runs; (2) replayed responses marked (`Idempotency-Replayed: true`); (3) 2xx-only write condition as an explicit, testable predicate; (4) cache key scoped to prevent cross-endpoint replay (composite of header value + method + path + body hash, mirroring py's `_CacheKey`); (5) store behind a trait so the Redis/distributed swap is a store change, not a middleware rewrite. What may vary: exact capacity/TTL defaults, body-hash algorithm, framework-specific wiring (R69's choice), position in the middleware stack (R75's ordering contract).

Architectural alternatives compared: (A) published idempotency middleware crate — none exists for any leading framework (404 probes above; `minco-plugin-idempotency` is framework-locked and negligible-adoption), so this alternative is unavailable, not merely worse; (B) hand-rolled `tower::Layer` wrapping a generic async key-value store trait, default impl over `moka::sync::Cache` — recommended: matches the tower-native middleware model, keeps the 2xx rule explicit in response-side logic (`response.status().is_success()`), and makes the swap point a trait impl; (C) endpoint-level DB-backed idempotency table (Z2P pattern) — rejected for this item: it answers a different durability requirement and contradicts the fixed in-memory single-instance scope of F315. The py pattern remains appropriate in Rust: tower's `Service::call` gives the same before/after interception py's ASGI middleware has, and moka's `sync::Cache` is `Clone + Send + Sync` with internal sharding, so no external mutex is needed (docs.rs/moka, retrieved 2026-09-25).

Minimal realistic example: `IdempotencyLayer::new(store)` applied to an axum `Router` (or any `tower::Service`); `POST /jobs` with `Idempotency-Key: k1` twice returns identical body, second with `Idempotency-Replayed: true`; a `POST` returning 500 is not cached (third identical request re-executes the handler); key `k1` on a different path does not replay. Executable acceptance check: integration test asserting replay-on-repeat, 2xx-only (500 then 200 sequence), and cross-path isolation — proposed, not yet run (no template web service exists pre-R69).

No `BASELINE-REVIEW:` finding: there is no prior-art baseline for this item ("Fresh ecosystem survey; no prior-art baseline"), and the py precedent's principle survives unchanged.

### Recommendation

One stack: adopt the idempotency-key replay middleware. Hand-rolled `tower::Layer` (`tower` 0.5.3) + `moka::sync::Cache` store (`moka` 0.12.16) behind a crate-local async store trait + `sha2` 0.11 body hash in a composite cache key. Status codes cached if and only if `200 <= status < 300`, expressed as an explicit `is_cacheable` predicate.

### Members

#### tower

##### Landscape

`tower` is the established-industry-standard middleware abstraction for async Rust: `Layer`/`Service` traits consumed by axum, tonic, hyper-based clients, and AWS Smithy server runtimes. No framework ships idempotency replay itself, so tower is the layer model the hand-rolled middleware implements — the direct analog of py's ASGI middleware slot. Bin position: established standard (tokio-project-adjacent first-party-equivalent). Shortlist source: the map, not familiarity — every leading async framework's middleware composes through tower.

Figures (`GET https://crates.io/api/v1/crates/tower`, 2026-09-25): all-time downloads 684,782,304; 90-day downloads 178,749,020. Last release (`GET .../tower/versions`): 0.5.3, 2026-01-12, `rust_version` 1.64.0, license MIT. GitHub (`GET https://api.github.com/repos/tower-rs/tower`, 2026-09-25): stars 4302, archived false, pushed 2026-06-22. Open issues (`GET https://api.github.com/search/issues?q=repo:tower-rs/tower+is:issue+is:open`): total_count 69. Responsiveness: 10 newest pure issues span 2025-10-13–2026-05-22 (low volume); 7 unanswered (a same-reporter cluster), maintainer (seanmonstar) replies same-day (#842) and 8-day (#845); median of answered ≈ 8 days. Advisories (`https://rustsec.org/packages/tower.html`, 2026-09-25): no page (HTTP 404) — no advisories ever filed. Adopters: 5,168 reverse-dependency crates incl. `axum` (tokio team's framework) and `aws-smithy-http-server` (AWS production server runtime) — both depend on tower's `Layer`/`Service` model. Maintenance state: active (push 2026-06, release 2026-01, responsive maintainer on substantive threads).

##### Principles and implementation

tower contributes principle (1): interception of unsafe-method requests before the handler, via `Layer::layer` + `Service::call`, with response-side access for the 2xx check and replay marking. Reference implementation: tower's own `tower::limit`, `timeout`, and `util::MapResponse` layers demonstrate the before/after-service pattern this middleware copies; axum's `from_fn`/layer docs show framework wiring. Maturity: 0.5 series stable since 2024; dependability: the load-bearing middleware trait of the ecosystem. Performance: zero-cost abstraction — the layer adds one `Clone`d-service call and a header lookup; no benchmark needed beyond stating the overhead is one cache lookup per unsafe request. Integration cost: minimal — any R69 framework choice that is tower-compatible (axum/tonic/smithy) takes the layer directly; a non-tower framework would need an adapter (recorded under Compatibility).

##### Dominant choice

`tower` 0.5.3 is the dominant (indeed only credible) middleware-layer model: 684M all-time downloads, 5,168 reverse dependents, maintained by the tower team with tokio overlap.

##### Qualified shortlist

`tower` 0.5.3 alone. No alternative middleware-trait crate qualifies: framework-native middleware traits (e.g. actix-web `Transform`) are R69-contingent and narrower, and adopting one before R69 resolves would prejudge the framework decision this item must stay neutral on.

##### Excluded by gate

None among considered layer models. (`minco-plugin-idempotency` was considered as a prebuilt alternative and fails on fitness-for-purpose rather than a numbered gate: framework-locked to minco, 869 all-time downloads, no tower/axum applicability.)

##### Up-and-comers

None for the layer model — tower's position is consolidated; no challenger middleware-trait crate has meaningful adoption.

##### Fit for this template

Exact fit: the template's web service (whatever R69 selects among tower-native frameworks) gains a framework-agnostic `Layer` that R75 can order among request-id/security-header/access-log layers. CLI/library surfaces are unaffected (web-only middleware). Matches py's ASGI-middleware slot one-for-one.

##### Recommendation

`tower` 0.5.3, default features (none — 0.5 has no default features; enable nothing beyond what R69's framework already pulls; `util` only if combinators are needed), as the trait-only layer model.

##### Ranked runner-up

None — no qualified alternative exists; the fallback is "no abstraction" (framework-native closure middleware), which sacrifices framework neutrality and is therefore not ranked.

##### Tradeoffs

tower 0.5 requires comfort with `Service`/`Layer` generics and `Clone`-able services; compile-time cost is small (trait-only use pulls `tower-layer`, `futures-core`, `pin-project-lite` only). Benefit: framework neutrality + the ecosystem's standard composition operators. No runtime coupling: `tokio` is an optional feature, not enabled by this use.

##### Parameters

No owned or consumed registry parameters for this member. Assumes fixed `rust-edition = 2024` (tower 0.5.3 declares edition 2018 in its own manifest, which is compatible — edition is per-crate). No `CONFLICT:` lines.

##### Migration implications

New file `crates/web/src/middleware/idempotency.rs` (or R69's web-crate layout): `IdempotencyLayer<S: IdempotencyStore>`, `IdempotencyService`, `IdempotencyStore` async trait, `is_cacheable(status)` predicate, `Idempotency-Replayed` header const. `Cargo.toml`: `tower = "0.5"`.

##### Validation strategy

Proposed (not run — no web service exists yet): `cargo test -p <web-crate> idempotency` covering replay-on-repeat, 2xx-only (500-then-200), cross-path isolation, and header marking, against a `tower::ServiceExt::oneshot` harness. Expected: all pass; second identical request never reaches the inner service (assert via call counter).

##### Confidence & re-verify trigger

High. Re-verify if R69 selects a non-tower-native framework (adapter needed) or if tower 0.6 releases with breaking `Service` changes.

##### Sources

- `GET https://crates.io/api/v1/crates/tower` + `/versions` — downloads, release, MSRV, license (2026-09-25).
- `GET https://api.github.com/repos/tower-rs/tower` + search/issues + issues threads #842/#845/#857 — stars, open count, responsiveness (2026-09-25).
- `https://rustsec.org/packages/tower.html` — 404, no advisories (2026-09-25).
- `https://raw.githubusercontent.com/tower-rs/tower/tower-0.5.3/tower/Cargo.toml` — features, rust-version (2026-09-25).
- `https://raw.githubusercontent.com/tower-rs/tower/master/.github/workflows/CI.yml` — ubuntu-latest CI (2026-09-25).
- crates.io `tower/reverse_dependencies` (5,168 total; axum, aws-smithy-http-server) (2026-09-25).

#### moka

##### Landscape

`moka` is the established-industry-standard concurrent in-memory cache: `sync::Cache` is `Clone + Send + Sync` with internal sharding (no external mutex), bounded capacity, per-entry TTL/TTI, and eviction listeners — the direct functional superset of py's `OrderedDict` store. Bin position: established standard for concurrent caches; `lru` is the established single-threaded LRU; `quick-cache` the up-and-comer; `mini-moka` the superseded lightweight sibling.

Figures (`GET https://crates.io/api/v1/crates/moka`, 2026-09-25): all-time 130,465,132; 90-day 37,508,110. Last release: 0.12.16, 2026-08-09, `rust_version` 1.71.1, license `(MIT OR Apache-2.0) AND Apache-2.0` (compatible with `MIT OR Apache-2.0`). GitHub (`GET https://api.github.com/repos/moka-rs/moka`): stars 2689, archived false, pushed 2026-08-09. Open issues: total_count 59. Responsiveness: newest 20 events contain 6 pure issues; 2 open-unanswered (#605 crash report 2026-08-10, #601 2026-07-29), maintainer/community first replies at 1/4/10 days (#590/#591/#600); median ≈ 4 days. Advisories (`https://rustsec.org/packages/moka.html`): HTTP 404 — none filed. Adopters: 705 reverse dependents incl. `cached`, `activitypub_federation`, `autumn-web`. Maintenance state: active (release + push 2026-08; MSRV 1.71.1 pinned and CI-tested per `.github/workflows/CI.yml` matrix: stable, beta, 1.71.1, nightly on ubuntu-latest).

##### Principles and implementation

moka realizes F315 (in-memory, single-instance by design) and the capacity story py leaves implicit: `Cache::builder().max_capacity(N).time_to_live(TTL).build()` gives a bounded, self-evicting store so the idempotency cache cannot grow without limit — strictly better than py's unbounded-growth-until-manual-eviction `OrderedDict` while preserving the single-instance semantics and the documented distributed-swap point (the swap replaces the `IdempotencyStore` impl, e.g. with Redis, behind the same trait). Reference: moka's `sync::Cache` docs + `examples/`; production use across 705 dependents. Performance: maintainer benchmarks (criterion, stated workloads in-repo) show moka ahead of mutex-wrapped `lru` under concurrency; absolute numbers are workload-specific and not decisive here — the template's cache holds small response bodies at modest cardinality, where any candidate is fast enough; concurrency-safety without a global lock is the deciding property. `unsafe` posture: moka uses `unsafe` internally (lock-free/sharded structures) with Miri + Loom workflows in CI (`.github/workflows/Miri.yml`, `Loom.yml`) — stated and mitigated.

##### Dominant choice

`moka` 0.12.16: 130M downloads, broadest concurrent-cache adoption, TTL+TTI+listener feature set no rival matches, single active maintainer (tatsuya6502) with fast cadence.

##### Qualified shortlist

`moka` 0.12.16 (recommended); `lru` 0.18.5 (qualified but not recommended: single-threaded `LruCache`, needs `Mutex` wrapping; 357M all-time downloads show maturity but the wrapper reintroduces lock contention and boilerplate); `quick-cache` 0.7.0 (qualified but not recommended: 27M downloads, S3-FIFO, `sync` API, but smaller community and no TTL-per-entry parity at survey time).

##### Excluded by gate

None by numbered gate. `mini-moka` 0.10.3 excluded by fitness (stale: last release 2024-01-08; superseded by moka itself), not by gate verdict — recorded here to show it was evaluated.

##### Up-and-comers

`quick-cache` 0.7.0 (arthurprs; stars 362; 3 open issues; 7.1M 90-day downloads; MIT; rust 1.85): credible challenger on raw throughput; watch for TTL-parity and adoption growth. Not chosen: narrower feature set and 5× smaller install base than moka.

##### Fit for this template

Exact fit for F315: `sync::Cache<CacheKey, CachedResponse>` shared by `Clone` across handlers; no mutex; builder documents capacity/TTL as named constants; the `IdempotencyStore` trait keeps the Redis swap point explicit. Default features: `sync` + `future` both available — enable `sync` only (plus `future` only if an async-eviction-listener need arises).

##### Recommendation

`moka` 0.12.16 with feature `sync`.

##### Ranked runner-up

`lru` 0.18.5 behind `std::sync::Mutex`: viable if the project ever forbids moka's `unsafe` internals, at the cost of a global lock and manual TTL bookkeeping. (Note: `lru` RUSTSEC-2026-0253, unsound `pop()` panic-safety, patched in ≥0.18.2 — 0.18.5 is clean.)

##### Tradeoffs

moka pulls `crossbeam-*`, `tagptr`, `quanta` — a heavier tree than `lru`, adding seconds to clean builds; binary-size impact is small (no native libs). Single-maintainer risk is mitigated by 130M downloads, corporate users, and an active issue cadence. Benefit vs `HashMap`+`Mutex`: real eviction (capacity + TTL), no lock contention, no hand-rolled expiry thread.

##### Parameters

No owned or consumed registry parameters. Assumes fixed MSRV policy (moka declares rust-version 1.71.1 and CI-tests it — within "stable minus 2"). No `CONFLICT:` lines.

##### Migration implications

`Cargo.toml`: `moka = { version = "0.12", features = ["sync"] }`. Store type + trait impl in the same new `middleware/idempotency.rs`; capacity/TTL as documented constants (`DEFAULT_MAX_CAPACITY`, `DEFAULT_TTL`).

##### Validation strategy

Proposed (not run): unit tests that capacity eviction and TTL expiry drop entries (moka honors both under `sync::Cache`); integration test that repeated keys replay and expired keys re-execute. Expected: eviction/expiry observed within moka's documented (eventual-consistency) bounds — tests must allow for moka's best-effort eviction timing, not assert exact eviction instants.

##### Confidence & re-verify trigger

High. Re-verify if moka goes 12 months without a release while Rust stable advances past its MSRV+2 window, or if `quick-cache` reaches TTL/TTI parity with comparable adoption.

##### Sources

- `GET https://crates.io/api/v1/crates/moka` + `/versions` — downloads, release, MSRV, license (2026-09-25).
- `GET https://api.github.com/repos/moka-rs/moka` + search/issues + issues #590/#591/#600/#601/#605 — stars, open count, responsiveness (2026-09-25).
- `https://rustsec.org/packages/moka.html` — 404, no advisories (2026-09-25).
- `https://raw.githubusercontent.com/moka-rs/moka/main/.github/workflows/CI.yml` — MSRV matrix, ubuntu-latest (2026-09-25).
- crates.io `moka/reverse_dependencies` (705 total) (2026-09-25).
- docs.rs/moka `sync::Cache` (`Clone + Send + Sync`, builder TTL/TTI) (2026-09-25).

#### sha2

##### Landscape

`sha2` (RustCrypto `hashes` monorepo) is the established-industry-standard SHA-2 implementation, used here narrowly: hashing the request body into the composite cache key so identical keys with different bodies do not collide. Bin position: established standard. Alternatives in-map: `blake3` (up-and-comer, faster, but a second hash dependency for no template benefit); `std::collections::hash_map::DefaultHasher` (built-in, explicitly documented as unsuitable for anything needing stability — excluded).

Figures (`GET https://crates.io/api/v1/crates/sha2`, 2026-09-25): all-time 979,271,195; 90-day 266,400,890. Last release: 0.11.0, 2026-03-25, `rust_version` 1.85, license `MIT OR Apache-2.0`. GitHub monorepo (`GET https://api.github.com/repos/RustCrypto/hashes`): stars 2266, archived false, pushed 2026-09-22. Open issues (whole monorepo): total_count 20. Responsiveness: newest pure-issue sample — maintainer replies same-day (#907), 1-day (#901), 3-day (#909); 1 unanswered feature request (#912); median ≈ 1 day. Advisories: `https://rustsec.org/packages/sha2.html` lists RUSTSEC-2021-0100 (patched ≥0.9.8; unaffected <0.9.7) — no open advisory for 0.11.0. Adopters: 19,594 reverse dependents — the ecosystem default. Maintenance state: active.

##### Principles and implementation

sha2 realizes the MEDIUM key-scoping principle: `CacheKey { key: String, method: Method, path: String, body_hash: [u8; 32] }` where `body_hash = Sha256(body)` — mirroring py's composite `_CacheKey` and preventing cross-endpoint/cross-body replay collisions that a raw-header-only key would allow. `Sha256::digest` is a one-call API; no streaming needed for buffered bodies. Performance: SHA-256 throughput (~GB/s with intrinsics) dwarfs request-body sizes; hashing cost is negligible vs handler execution. `unsafe`: hardware-intrinsic backends are `unsafe`-containing but encapsulated in RustCrypto's audited implementation; pure-Rust fallback exists.

##### Dominant choice

`sha2` 0.11.0: 979M downloads, RustCrypto maintenance, the default wherever a stable digest is needed.

##### Qualified shortlist

`sha2` 0.11.0 alone for this role. `blake3` qualifies technically but adds nothing the template needs (no perf-sensitive bulk hashing) and would double hash deps.

##### Excluded by gate

`std DefaultHasher`: excluded by fitness-for-purpose (documented instability across builds/versions makes it wrong for cache keys that must be deterministic), not by numbered gate — recorded so the "just use std" alternative is visibly adjudicated.

##### Up-and-comers

`blake3`: faster, well-regarded, but unnecessary here; revisit only if body hashing ever shows up in profiles (it will not at template scale).

##### Fit for this template

Narrow, exact fit: one digest call in key derivation. Default features suffice (std enabled by default; `asm`/`loongarch`-style backends are opt-in and unnecessary). MSRV rust-version 1.85 is the highest in this stack — still within "stable minus 2" at survey time (stable ≥1.89 in Sept 2026); recorded as the stack's MSRV floor contributor.

##### Recommendation

`sha2` 0.11.0, default features.

##### Ranked runner-up

`blake3` (latest stable): adopt only on measured hashing cost, which is not expected.

##### Tradeoffs

One more small dependency (digest + crypto-common + cpufeatures tree) for a 3-line use; alternative of skipping the body hash weakens collision isolation and is rejected. Compile cost negligible; `sha2` is likely already in the tree via other deps (TLS/auth).

##### Parameters

No owned or consumed registry parameters. Assumes fixed MSRV policy — note `sha2` 0.11.0 declares rust-version 1.85; if the template's pinned MSRV floor is older, pin `sha2` 0.10.x instead (no `CONFLICT:` — fixed params unchanged).

##### Migration implications

`Cargo.toml`: `sha2 = "0.11"`. Key derivation in `middleware/idempotency.rs`: `cache_key(header, method, path, body) -> CacheKey`.

##### Validation strategy

Proposed (not run): unit test asserting same key+different body → different `CacheKey`, and same key+different path → different `CacheKey`; integration test asserting no cross-path replay. Expected: all distinct; replay only on full-key match.

##### Confidence & re-verify trigger

High. Re-verify only if RustCrypto yanks 0.11.0 or the template MSRV floor drops below 1.85 (then re-pin to 0.10.x).

##### Sources

- `GET https://crates.io/api/v1/crates/sha2` + `/versions` — downloads, release, MSRV, license (2026-09-25).
- `GET https://api.github.com/repos/RustCrypto/hashes` + search/issues + issues #901/#907/#909/#912 — stars, open count, responsiveness (2026-09-25).
- `https://rustsec.org/packages/sha2.html` + advisory-db `RUSTSEC-2021-0100.md` (patched ≥0.9.8) (2026-09-25).
- crates.io `sha2/reverse_dependencies` (19,594 total) (2026-09-25).

### Compatibility

Proof the members compose: (1) shared-adopter chain — axum (tower-native; 100M+ downloads class) + moka co-occur in production services (e.g. `autumn-web`, `activitypub_federation` depend on moka while building on tower-native stacks); sha2 co-occurs with both near-universally (19,594 dependents). (2) No conflicting version requirements: tower 0.5.3 (rust 1.64), moka 0.12.16 (rust 1.71.1), sha2 0.11.0 (rust 1.85) — all within the MSRV policy; no shared transitive dep requires unification (disjoint trees: tower→futures/tower-layer; moka→crossbeam/quanta; sha2→digest/generic-array). (3) Framework-neutrality: the layer is generic over `S: tower::Service<Request<Body>>`, so whichever R69 framework wins (if tower-native) accepts it via `.layer()`; placement obeys R75's ordering contract. Residual risk: if R69 picks a non-tower framework (e.g. actix-web), a thin adapter is needed — flagged, not blocking.

### Parameters

No parameters owned or consumed by R73 (registry: `owns:` empty, `consumes:` empty; R69/R75 are related-only and treated as open).

assumes rust-edition = 2024
assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
assumes license = MIT OR Apache-2.0
assumes target-os-matrix = ubuntu-latest, macos-latest

No `CONFLICT:` lines.

Fitness-gate audit (all members): (1) licenses MIT / (MIT OR Apache-2.0) / MIT OR Apache-2.0 — compatible. (2) MSRVs 1.64/1.71.1/1.85 — within policy; stack floor is sha2's 1.85. (3) No open RustSec advisory on any recommended version; `unsafe` postures stated per member. (4) CI-verified on ubuntu-latest by all three projects; all are portable pure-Rust with no Linux-only deps — macOS builds follow by construction and template CI will cover macos-latest (upstream macOS matrix entries not asserted). (5) Default features stated per member; no async-runtime coupling (tower `tokio` opt-in unused; moka `sync` needs no runtime; sha2 sync). (6) Compile cost: tower trait-only negligible; moka moderate (crossbeam/quanta tree); sha2 negligible; binary-size impact small, no native libs.

### Migration implications

- `Cargo.toml` (web crate): add `tower = "0.5"`, `moka = { version = "0.12", features = ["sync"] }`, `sha2 = "0.11"`.
- New `middleware/idempotency.rs`: `IDEMPOTENCY_HEADER = "idempotency-key"` (lowercase match, mirroring py), `IDEMPOTENCY_REPLAYED = "Idempotency-Replayed"`, `IdempotencyLayer`, `IdempotencyStore` trait + `MokaStore` impl, `CacheKey`, `is_cacheable` (`200 <= status < 300`), capacity/TTL constants with a doc comment marking the distributed-store swap point (F315).
- Wire `.layer(IdempotencyLayer::new(...))` at the R75-assigned position; unsafe methods only (POST/PUT/PATCH); requests without the header pass through untouched.
- Docs: note single-instance scope + Redis swap point in the web-service README (mirrors py's documented limitation).

### Validation strategy

Proposed checks (none executed — no web service exists pre-R69; each will run once the R69 scaffold lands):

1. `cargo test -p <web-crate> idempotency::replays_cached_success` — same key twice → identical body, second carries `Idempotency-Replayed: true`, inner-service call count stays 1. Expected: pass.
2. `cargo test -p <web-crate> idempotency::does_not_cache_errors` — 500 then 200 on the same key → handler runs twice, second returns 200. Expected: pass.
3. `cargo test -p <web-crate> idempotency::key_scoped_to_route_and_body` — same key, different path and different body → no replay. Expected: pass.
4. `cargo test -p <web-crate> idempotency::passthrough_without_header` — no header → never cached, never marked. Expected: pass.
5. Doc-level: `cargo doc` shows the swap-point comment; `cargo deny`/`cargo audit` clean on the new tree. Expected: clean.

### Confidence & re-verify trigger

Confidence: high for the architecture (no published alternative exists; tower+moka+sha2 are each dominant in-role with active maintenance and clean advisories); medium for exact versions (re-pin at implementation time if newer minors exist). Re-verify triggers: R69 selects a non-tower-native framework; any member suffers a yank, open RustSec advisory, or 12-month dormancy; template MSRV floor drops below 1.85 (re-pin sha2 to 0.10.x).

### Sources

- crates.io API: `GET /api/v1/crates/{tower,moka,sha2,lru,quick-cache,mini-moka}` + `/versions`, reverse_dependencies, and exact-name 404 probes — all retrieved 2026-09-25 (figures inline above).
- GitHub API: `tower-rs/tower`, `moka-rs/moka`, `RustCrypto/hashes`, `jeromefroe/lru-rs`, `arthurprs/quick-cache` repo + search/issues + issue threads — retrieved 2026-09-25.
- RustSec: `https://rustsec.org/packages/{tower,moka,sha2,lru,quick-cache}.html` + advisory-db `RUSTSEC-2021-0100.md`, `RUSTSEC-2026-0253.md` — retrieved 2026-09-25.
- Upstream manifests/CI: tower 0.5.3 `Cargo.toml`, tower + moka `CI.yml` workflows (incl. moka MSRV matrix and Miri/Loom workflows) — retrieved 2026-09-25.
- docs.rs/moka `sync::Cache` API docs (`Clone + Send + Sync`, builder TTL/TTI) — retrieved 2026-09-25.
- Stripe idempotency-key semantics (errors retried, not replayed): `https://docs.stripe.com/api/idempotent_requests` — retrieved 2026-09-25.
- Luke Maxwell, *Zero to Production in Rust* ch. 11 (idempotency keys, Postgres-backed variant — the named Rust pattern reference): `https://www.zero2prod.com` — retrieved 2026-09-25.
- py precedent: `src/py_launch_blueprint/web/idempotency.py` (header const, 2xx condition, OrderedDict store) via the R73 prompt `## Context` — no live fetch (workspace source).

Gaps recorded: (G1) no mainstream Rust template documents in-memory idempotency middleware as a named reusable layer — recommendation rests on tower/moka/sha2 composition + Z2P's DB-backed pattern reference instead; (G2) upstream macOS CI matrices not asserted (portability argued from pure-Rust deps + template CI to cover macos-latest); (G3) no benchmarks run — hashing/cache overhead negligible by construction at template scale, workload-stated comparison deferred to implementation if ever needed.
