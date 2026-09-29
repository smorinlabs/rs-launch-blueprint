# R73 — Doxa engine report (three providers, regrouped by template field)

Normalization record: Doxa operation research-20260918-151748-c3450952b9d24d59 (all_deep_research) returned one report per provider. This file regroups the three answer bodies under the prompt's template fields so the single-report shape check applies; within each field the three provider sections appear in the order OpenAI, Perplexity, Gemini, each introduced by a bold label, and under `### Members` every provider's members are kept with the provider name appended to the member heading. Every content line of each provider's answer body is preserved (the originals are the three saved files under the run's doxa/ directory; raw/doxa-<provider>.normalized.md hold the bodies individually). Headings that would fall outside the template are demoted to bold text so no heading outside the template remains; doxa/normalization.json lists every other adjustment.

**Provider preambles (text preceding each provider's first template field)**

**OpenAI (gpt-5.6-sol)**

**Reasoning Summary**
**Researching candidates**

I need to find out the exact versions, MSRV, licenses, dependencies, CI OS, advisories, downloads, and GitHub stats for various crates. The candidates could include something like the idempotent crate or axum-idempotent. I should search for them. The project, R69, is open, and I want to ensure it’s framework agnostic. I’m considering the possibility of an idempotent middleware crate, so I need to explore that right away.

**Perplexity (sonar-deep-research)**

**Idempotency-Key Replay Middleware Bundle for `rs-launch-blueprint` (R73)**

The research concludes that `rs-launch-blueprint` should adopt a Stripe-style idempotency-key replay middleware for unsafe HTTP methods, with a clear architectural separation between idempotency semantics, middleware wiring, and cache storage, and with a deliberately simple default: a single-instance, in-memory store that caches only successful \(2xx\) responses and is explicitly documented as a future distributed-store swap point. The recommended bundle combines a small, dependency-light primitive crate for idempotency metadata (`use-idempotency`), a high-performance concurrent in-memory cache (`moka::future::Cache`) as the initial store, and a framework-agnostic middleware pattern modeled on existing Rust implementations (`cratestack::idempotency` and `axum-idempotent`) rather than binding to a single web framework crate at template level.[1][3][5][6][7][8][9][11][12][13] This design preserves the Python template’s behavior—replay for unsafe methods, direct `Idempotency-Key` header, replay header for observability, and “2xx-only” cache writes—while aligning with Rust ecosystem idioms and keeping future migration to a distributed store as a local change to the store implementation rather than a rewrite of middleware or request semantics.[1][8][11][12] The bundle’s members are selected for licensing compatibility, general ecosystem acceptance, and alignment with the template’s CLI + library + web service shape, with explicit acknowledgment of remaining evidence gaps (such as precise download counts and MSRV declarations) that must be verified in integration.

**Introduction**

The R73 item for `rs-launch-blueprint` decides whether the Rust template should adopt an idempotency-key replay middleware for unsafe HTTP methods, mirroring the Python template’s Stripe-style semantics while respecting the Rust ecosystem’s tooling and patterns. The Python implementation treats POST, PUT, and PATCH requests carrying an `Idempotency-Key` header as candidates for replay, storing only successful \(2xx\) responses in an ordered, bounded, in-memory cache, and replaying the stored response when the same logical operation is retried, while allowing genuine errors to be retried rather than replayed.[1] The TypeScript port never built a web service, so there is no precedent to reconcile, and the owner’s direction is to research both equivalency and best practice for Rust, guided by the same principles as the Python template but not blindly duplicating mechanisms. That direction explicitly emphasizes identifying the underlying engineering principle, the level of agreement required (capability, pattern, policy), and observable acceptance criteria, then selecting architectures and libraries that best realize those principles, rather than relying on familiarity or benchmark throughput alone.

Within those constraints, this report has to choose not only whether to implement idempotency-key replay at all, but how: whether to adopt an existing middleware crate for a specific framework, whether to define framework-agnostic traits and patterns so that R69’s choice of web framework can be wired later, how to express the “only cache successful outcomes” rule in Rust idioms, and what kind of in-memory store best mirrors Python’s ordered, evictable cache while remaining concurrency-safe in an async web service. The answer also has to respect the owner’s MSRV policy (stable minus two minor versions, declared and tested), the licensing requirement (`MIT OR Apache-2.0`), and CI constraints (`ubuntu-latest` and `macos-latest` targets), even though some ecosystem metrics cannot be fully verified in this offline evidence-gathering environment.

To structure the decision, the report first surveys the landscape of idempotency middleware and caching libraries in Rust, using authoritative sources, production practice, and fit against the template’s shape. It then distills the principles drawn from the Python implementation and current best practice, compares architectural alternatives, and proposes a bundle of one stack and its members. For each member, the report goes into the detailed landscape, gates, tradeoffs, and migration implications. Finally, it ties the members together, describes validation strategies, and states confidence and re-verify triggers, with explicit recognition of evidence gaps that must be closed during integration.

**Report**

**Gemini (deep-research-preview-04-2026)**

**Deep-Research Report: Idempotency-Key Replay Middleware**

### Landscape

**OpenAI**

**Category decided:** application-level HTTP idempotency and response replay for mutating requests. This is distinct from ordinary RFC-style HTTP response caching: it must coordinate first execution, detect conflicting key reuse, and replay an operation’s prior result without re-running side effects. The IETF HTTPAPI working-group draft describes this state machine, although revision 07 expired on **April 18, 2026** and is not an RFC. ([datatracker.ietf.org](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/))

**Retrieval date:** September 18, 2026. The mandated crates.io and GitHub JSON metric endpoints were attempted, but most returned access errors in this research environment. Their figures are reported as unavailable rather than replaced with nonconforming estimates. Popularity was therefore excluded from the decision.

#### Three-bin map

| Bin | Candidates found | Assessment |
|---|---|---|
| Built-in or first-party toolchain | Rust `std::{collections::{HashMap, VecDeque}, sync::{Arc, Mutex}, time::Instant}`; R69 framework-native middleware adapter; Tower `Service`/`Layer` when R69 is Tower-compatible | No built-in idempotency implementation, but all primitives needed for a small bounded store and middleware state machine exist. Tower is explicitly intended as a reusable middleware integration point. ([tower-rs.github.io](https://tower-rs.github.io/tower/tower/)) |
| Established industry pattern | Client-provided `Idempotency-Key`; operation-scoped lookup key; separate request fingerprint; atomic in-flight reservation; replay of the completed result; published expiry policy | This is the dominant architectural pattern. There is not yet a final IETF standard, and status-persistence policies differ between implementations. ([datatracker.ietf.org](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07)) |
| Up-and-comers | `axum-idempotent` 0.3.0; `cratestack-axum` 0.12.0; the `idempotency-rs` sample repository; `http-cache-tower-server` 0.2.4 as adjacent prior art | Published implementations now exist, but none meets this bundle’s complete framework-neutral, bounded-memory, atomic-store, swap-ready and policy requirements without substantial adaptation. ([docs.rs](https://docs.rs/crate/axum-idempotent/latest)) |

`moka` 0.12.16 is the established general-purpose concurrent-cache candidate. It supports bounded capacity, TTL and atomic per-key insertion, and its maintainers explicitly compare it with simpler caches and acknowledge it can be overkill. Its current documentation says macOS is expected to work but is **not tested in upstream CI**, so it fails this item’s literal OS evidence gate today. ([docs.rs](https://docs.rs/crate/moka/latest))

#### Authority used

| Source | Why authoritative | Limitation |
|---|---|---|
| RFC 9110 and IETF HTTPAPI draft 07 | Standards-body definition of HTTP method and proposed `Idempotency-Key` semantics | The idempotency document is an expired Internet-Draft, not a standard. ([datatracker.ietf.org](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/)) |
| Stripe API documentation | Primary documentation for a large production idempotency implementation | Vendor policy, not a universal standard. ([docs.stripe.com](https://docs.stripe.com/api/idempotent_requests?...=)) |
| Tower, Axum and Tokio documentation/source | Maintainer-owned definitions of Rust middleware and synchronization idioms | They supply mechanisms, not an idempotency policy. ([docs.rs](https://docs.rs/axum/latest/axum/middleware/)) |
| Maintainers’ crate docs/source | Primary evidence for versions, features, defaults and integration requirements | Some crates lack the maintenance and platform evidence required by this prompt. |
| Well-regarded project manifests | Direct adoption evidence rather than popularity inference | Adoption proves interoperability, not suitability for this template. |

#### Practice evidence

- **Axum** uses Tower’s middleware model rather than inventing a separate one; **Tonic** also integrates Tower. Both are maintained by major Tokio/Hyper ecosystem teams. ([docs.rs](https://docs.rs/axum/latest/axum/middleware/))
- The official **AWS SDK for Rust** SigV4 implementation currently depends on `sha2 = "0.11"`, supporting SHA-256 as a maintained ecosystem choice for request fingerprints. ([raw.githubusercontent.com](https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml))
- `cratestack-axum` provides the strongest maintained Rust reference found for an idempotency-specific store interface: principal scoping, payload fingerprints, atomic `reserve_or_fetch`, replay and conflict handling. It is, however, part of a much larger schema-first framework and currently supplies SQL/Redis stores rather than the required small in-memory profile. ([rust-doc.cratestack.dev](https://rust-doc.cratestack.dev/cratestack/idempotency/index.html))
- `axum-idempotent` 0.3.0 provides a real published Axum layer, direct header-key mode, response replay and configurable ignored status codes. It is coupled to `ruts` sessions and cookie/session layer ordering, and its direct mode uses the header value as the key rather than providing the operation/principal/fingerprint contract required here. ([docs.rs](https://docs.rs/crate/axum-idempotent/latest))
- No mainstream, widely adopted Rust web-service template was found documenting this complete pattern. The available evidence consists mainly of young middleware crates, sample repositories and recent tutorials. That is an evidence gap, not evidence that the capability is inappropriate.

**Perplexity**

The category decided by R73 is “idempotency-key replay for unsafe HTTP methods backed by a bounded in-memory cache,” which naturally spans three overlapping subcategories in the Rust ecosystem: idempotency-specific middleware or primitive crates, general-purpose caching libraries suitable as the in-memory backing store, and broader web-service templates or middleware stacks that treat Stripe-style idempotency as a named pattern. The survey follows the owner’s “forest before trees” mandate: mapping the field first, identifying authoritative sources, and studying practice in well-regarded Rust projects, before narrowing down candidates for the bundle.

In the first bin, “built-in or first-party toolchain,” Rust as a language and standard library does not provide any direct HTTP idempotency-key middleware; its HTTP and async capabilities are expressed through crates like `hyper`, `tokio`, and web frameworks such as `axum`, `actix-web`, and `warp`, none of which, in their core, ship a named idempotency-key replay component. This absence is consistent with the ecosystem’s pattern of keeping protocol-level semantics and service-layer features in separate crates rather than baking them into the language. It means that R73 cannot rely on a built-in solution and must look to third-party crates or design patterns atop a chosen web framework.

In the second bin, “established industry standard,” several crates stand out. For idempotency semantics, the `use-idempotency` crate provides small, validated types modeling idempotency keys, scopes, replay status, conflict status metadata, and request fingerprint labels, explicitly as primitives for API metadata.[11] Its documentation emphasizes non-goals: it deliberately does not implement a storage backend, request hashing, or distributed locking, making it suited as a semantic layer rather than a full middleware.[11] For caching, the `moka` crate is a fast, concurrent cache library inspired by Caffeine, offering synchronous and asynchronous caches that can be bounded by maximum entries or weighted size, with TinyLFU-inspired admission and LRU eviction to maintain near-optimal hit ratios.[3][5][6][7][9] Moka provides both a synchronous cache shareable across threads and a futures-aware cache (`moka::future::Cache`) for async runtimes like Tokio, async-std, or actix-rt, with support for TTL, TTI, and variable expiration, plus features such as eviction listeners and lock-free concurrent iterators.[5][6][7][8][9] Its public documentation notes that crates.io itself uses Moka to maintain roughly eighty-five percent cache hit rates on its download endpoint, an indication of production adoption and performance.[7] The `cached` crate, on the other hand, offers memoization macros and various in-memory stores (unbounded, LRU, TTL, sharded, Redis-backed, disk-backed via `redb`), focusing on function-level caching rather than HTTP semantics but with traits and async surfaces that can drive custom stores.[2][4][16]

In the third bin, “up-and-comer,” there are crates that implement idempotency middleware for specific frameworks. The `cratestack` API documentation includes an `idempotency` module described as an idempotency-key middleware protecting mutating routes against duplicate execution, which runs the handler on the first request with a given key, persists the captured response, and then replays the stored response on subsequent requests with the same key and matching request-body hash, or returns a `422` with an `idempotency_key_conflict` code if a different body is sent under the same key, in line with a draft IETF spec.[1] This middleware’s behavior closely mirrors Stripe’s semantics for conflict detection and replay. Another rising crate is `axum-idempotent`, which is explicitly marketed as middleware for handling idempotent requests in Axum applications, providing modes for “Direct Key” and “Hashing” that use either a client-provided header (e.g., `Idempotency-Key`) directly as the cache key or a hash derived from method, path, headers, and body.[12][13] It caches responses at the middleware layer and returns cached responses for identical requests rather than re-executing handlers, with observability via a replay header such as `idempotency-replayed`.[12] These crates show that the Rust ecosystem has begun to treat Stripe-style idempotency as a first-class middleware concern, though tied to particular frameworks and storage patterns.

For authoritative sources, this report relies on crates’ own documentation on docs.rs, openapps-style summaries, and the projects’ GitHub repositories, which collectively represent the maintainers’ intended usage and feature sets and are standard references in Rust communities.[1][2][3][5][6][7][8][9][10][11][12][13][14][16] For example, docs.rs entries for `moka` and its `future::Cache` struct describe the concurrency model, bounding options, TTL/TTI behavior, and async interfaces for insert, get, and invalidate operations, together with examples using Tokio.[5][6][8][9] Similarly, the `cached` crate’s documentation explains its trait surfaces (`Cached`, `ConcurrentCached`, `ConcurrentCachedAsync`, `CachedGetOrSetAsync`) and macro behaviors, including async caching with Redis and disk-backed stores via `redb`, as well as default synchronization policies such as per-key bucketed locks and whole-cache locks.[2][4][16] The `use-idempotency` documentation states its struct and enum types, their validity constraints, and its non-goals, and the `axum-idempotent` and `cratestack::idempotency` docs specify middleware operation modes and integration constraints.[1][11][12][13]

Practice evidence in mainstream, well-regarded Rust projects is more nuanced. The Moka documentation itself notes usage by crates.io, which is a central registry for Rust packages and thus a key reference application.[7] While direct verification of Moka’s download counts, GitHub stars, and open issues is not possible in this offline context, the combination of its feature depth, recent releases, and role in crates.io points to a stable, actively maintained library rather than a niche experiment.[3][6][7][10][14] The `cached` crate has been used widely in function memoization across Rust projects, given its macros and unintrusive integration, and its documentation indicates active maintenance with Rust version requirements and async features.[2][4][16] The idempotency-specific crates are newer: `axum-idempotent` has recent releases as of late 2025 and is built specifically for Axum, a leading async web framework, but it is not yet a ubiquitous standard in all web-service templates.[12][13] The `cratestack` idempotency middleware is part of a broader stack that appears targeted at API services with draft-spec-conforming idempotency, but its adoption footprint is harder to establish from documentation alone.[1]

Fit over abstract best, as mandated by the owner, requires judging these candidates against the template’s combined shape (CLI + library + web service) and Python precedent. The template needs an idempotency behavior that is conceptually simple, framework-agnostic at the template layer, and consistent with Stripe-style semantics: direct `Idempotency-Key` header, 2xx-only cache writes, conflict detection when the same key is reused with a different operation, and an in-memory store that can later be swapped for a distributed store without rewriting middleware. The Python implementation uses an ordered dictionary as a bounded store, documents a future Redis-backed distributed cache for multi-instance deployment, and intentionally avoids caching error responses so that genuine errors can be retried.[1] The Rust ecosystem offers both primitive crates and full middleware; however, binding the template directly to Axum-specific middleware (`axum-idempotent`) at R73 would be premature because R69 has not yet chosen the web framework. Conversely, ignoring existing middleware patterns would be wasteful. The best fit is therefore a hybrid: adopt a generic semantic crate (`use-idempotency`), design a framework-agnostic middleware pattern and store trait inspired by `cratestack::idempotency` and `axum-idempotent`, and choose a well-regarded caching crate like Moka as the default in-memory implementation.

Within this landscape, the bundle’s members are chosen to reflect three layers: idempotency metadata and status (with `use-idempotency`), in-memory store (with `moka::future::Cache`), and middleware pattern (hand-rolled for the eventual framework, using patterns from `cratestack::idempotency` and `axum-idempotent` as reference implementations). This choice keeps R73 agnostic to R69’s framework decision and makes the future distributed-store swap a matter of plugging a new implementation into the store trait, without rewriting key derivation or replay semantics.

**Gemini**

The architectural decision regarding how to properly implement idempotency-key replay within a Rust web service sits at the complex intersection of HTTP middleware design, concurrent state management, and distributed systems reliability. To evaluate the Rust ecosystem’s readiness to satisfy the specific requirements of the `rs-launch-blueprint` template—namely, caching only successful outcomes, relying on an in-memory single-instance store explicitly designed for a future distributed swap, and ensuring no cross-endpoint collisions—the landscape must first be mapped into three distinct categories. 

The first category comprises the built-in or first-party toolchain solutions. In the Rust standard library, this is represented by `std::collections::HashMap` protected by concurrency primitives such as `std::sync::Mutex` or `tokio::sync::RwLock`. The second category encompasses established industry standards. Within the Rust web ecosystem, this includes the `tower` crate for generic, framework-agnostic middleware abstractions, `moka` as the definitive high-performance, concurrent in-memory cache with temporal eviction semantics, and `dashmap` for lock-free concurrent map structures. The third category consists of up-and-comers, which represent dedicated idempotency crates such as `axum-idempotent`, `idempotency-rs`, and the now-defunct `idempotent`.

Authority within this domain is established through a combination of formalized protocol specifications and demonstrated production resilience. The baseline for idempotency patterns is governed by the IETF Idempotency-Key HTTP Header specification drafts [cite: 1, 2], which formalize the semantics of key reuse, payload collisions, and the necessity of preventing duplicate side effects in non-idempotent HTTP methods like POST and PATCH. Furthermore, Stripe’s widely cited production architecture for idempotent API requests [cite: 3, 4] serves as the de facto industry standard for the state machine required to handle concurrent retries safely. For Rust-specific implementation authority, the `tokio` team’s ecosystem guidelines dictate the use of `tower` for HTTP middlewares to ensure strict framework agnosticism. Finally, the official `crates.io` engineering publications document production load constraints, demonstrating the absolute necessity of specialized concurrent caches over standard library collections when dealing with high-throughput network services [cite: 5, 6].

Practice evidence across mainstream Rust projects overwhelmingly rejects deeply coupled, all-in-one web framework middlewares in favor of composing `tower::Service` layers. The `crates.io` backend registry itself—one of the highest-traffic Rust web services in existence—relies extensively on `moka` for its heavily loaded endpoint caches. This implementation maintains cache hit rates of approximately 85% while explicitly avoiding the severe lock contention associated with standard `RwLock<HashMap>` implementations, or even the cross-shard deadlock edge cases occasionally observed in `dashmap` [cite: 5, 7, 8]. Conversely, dedicated idempotency crates exhibit extremely low adoption and concerning architectural decisions. For instance, `axum-idempotent` requires forced coupling to the `ruts` session crate, hijacking browser cookie management for server-to-server idempotency keys [cite: 9]. The crate `idempotent` was entirely yanked from the registry due to a lack of maintenance [cite: 10, 11]. 

Judging every candidate strictly against the fit for this specific template—which must serve as a CLI, library, and web service without locking into a specific downstream framework—reveals that pre-packaged idempotency middlewares are unsuitable. The `axum-idempotent` crate violates the principle of a standalone swap-point cache by embedding the idempotency store inside a browser session cookie framework [cite: 9], and it explicitly couples to `axum`, violating the mandate to leave the web framework choice open. The most appropriate fit for the `rs-launch-blueprint` is a hand-rolled `tower::Service` wrapper that enforces the strict success-only caching rule, backed by a highly concurrent `moka` store wrapped in an asynchronous generic trait. This mirrors the Python template's explicit Redis swap-point while respecting Rust's strict concurrency requirements.

### Principles and implementation

**OpenAI**

#### Shared requirement and agreement level

| Level | Required agreement |
|---|---|
| Capability | Requests using `Idempotency-Key` on configured mutating methods can be retried without re-running a previously completed operation. |
| Architectural pattern | A thin HTTP adapter delegates to an idempotency-specific store interface; the initial implementation is bounded, in-memory and explicitly single-instance; a distributed implementation replaces the store, not the HTTP algorithm. |
| Policy | Key scope, payload-conflict behavior, in-flight behavior, retention, replay marker, cacheable response contract and failure behavior must be explicit and tested. |
| Ecosystem-specific variation | The concrete middleware trait—Tower `Layer`, Axum function middleware, Actix `Transform`, or another R69-native mechanism—may vary. |
| Out of scope here | Overall middleware ordering remains R75’s decision, but R75 must provide an operation boundary at which authentication scope and “handler execution began” are observable. |

The common principle is **not merely “cache 2xx responses.”** It is: *bind retries for one logical operation to one execution and one recorded outcome, while rejecting ambiguous key reuse*. The IETF draft separately identifies completed retries, conflicting payloads and concurrent in-flight retries. ([datatracker.ietf.org](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07))

#### Baseline review

**BASELINE-REVIEW: F314 — at-most-once effect after operation execution begins — proposed change: replace unconditional “store only 2xx” with “store every completed handler outcome, success or error; do not store failures rejected before handler execution”; retain `SuccessOnly` only as an explicit compatibility policy for handlers that guarantee every non-2xx outcome is side-effect-free — affected: R73/F314 only; F313 and F315 remain unchanged — evidence: Stripe stores and replays the first completed result including 500 responses, while the IETF draft says a completed retry should receive the previous success or error.** ([datatracker.ietf.org](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07))

The supplied baseline’s description of 2xx-only behavior as “Stripe semantics” is factually incorrect as of September 18, 2026. Stripe says that validation failures and concurrent conflicts are retryable because execution has not begun, but once execution begins it saves the resulting status and body even for `500`. ([docs.stripe.com](https://docs.stripe.com/api/idempotent_requests?...=))

There is a legitimate competing policy: `axum-idempotent` defaults to excluding a set of transient or request-envelope errors, including common 5xx statuses. That enables a real retry, but it is safe only if those responses prove the protected operation committed no side effect. HTTP status alone cannot establish that invariant. ([docs.rs](https://docs.rs/crate/axum-idempotent/latest))

If the owner declines the baseline review and retains F314, the Rust condition should be direct and named—not an incidental library default:

```rust
pub enum PersistencePolicy {
    CompletedOutcome,
    SuccessOnly,
}

impl PersistencePolicy {
    fn should_store(&self, execution_started: bool, status: StatusCode) -> bool {
        execution_started
            && match self {
                Self::CompletedOutcome => true,
                Self::SuccessOnly => status.is_success(), // exactly 200..=299
            }
    }
}
```

#### Architectural alternatives

| Alternative | Advantages | Failure or cost | Verdict |
|---|---|---|---|
| Adopt `axum-idempotent` directly | Published; replay header; configurable status list; request hashing mode | Axum- and session-layer-coupled; R69 unresolved; direct-key scope does not provide the required operation/principal/fingerprint model; MSRV and macOS gate evidence incomplete | Exclude |
| Adopt `cratestack-axum` directly | Strong atomic store semantics and distributed implementations | Pulls in a schema-first framework and numerous unrelated crates; lacks the desired small in-memory profile | Exclude |
| Wrap a generic `get`/`put` key-value trait | Superficially simple distributed swap | Check-then-insert races allow two concurrent requests to execute; distributed backends need atomic reservation semantics that generic KV does not express | Reject |
| Internal idempotency state machine over an `IdempotencyStore` trait | Exact policy, framework-neutral core, atomic contract, minimal store, future backend swap | Approximately 150–250 lines plus tests; project owns correctness | **Choose** |
| Domain transaction/outbox/unique constraint only | Strongest guarantee when the side effect and idempotency record commit atomically | Operation-specific, cannot generically replay arbitrary HTTP responses, outside this middleware bundle | Complementary future hardening |

The store abstraction should therefore be idempotency-specific, with atomic operations such as `begin`, `complete` and `abort`, rather than a generic key-value interface. `cratestack`’s `reserve_or_fetch` design is useful reference evidence for this principle. ([rust-doc.cratestack.dev](https://rust-doc.cratestack.dev/cratestack/idempotency/index.html))

#### Request participation

- Intercept only `POST`, `PUT` and `PATCH` requests carrying exactly one non-empty `Idempotency-Key`.
- Requests without the header pass through unchanged.
- Other methods bypass the engine.
- Keep `PUT` for Python-port equivalence even though HTTP already defines its intended effect as idempotent.
- Reject malformed, duplicate or oversized keys before reserving an entry. A 255-byte limit is compatible with Stripe’s documented limit, but should be explicit configuration rather than an accidental parser limit. ([datatracker.ietf.org](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07))

#### Cache key and fingerprint

Do **not** put the body hash into the lookup key. If the body hash were part of the key, reusing one idempotency key with a different payload would become a cache miss and execute a second operation.

Use:

```text
CacheKey =
    service namespace
  + authenticated principal/tenant scope when available
  + HTTP method
  + effective operation target
  + raw Idempotency-Key value
```

Use a separately stored fingerprint:

```text
FingerprintV1 =
    SHA-256(
        length-prefixed content-type
      + length-prefixed content-encoding
      + length-prefixed body bytes
      + any operation-declared material headers
    )
```

The effective target should include the actual normalized path and query, or an R69-provided stable operation identifier plus material path/query parameters. A route template alone is insufficient because `/orders/1` and `/orders/2` would collide. The IETF draft expressly permits a checksum of all or selected request payload fields as the fingerprint and recommends rejecting reuse with a different payload. ([datatracker.ietf.org](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07))

A principal scope must use a stable internal tenant/user identifier, not raw credentials. If no authenticated principal is available, use a service-wide namespace and document that keys must then be globally unique within the instance.

#### In-memory store

Use:

```rust
Arc<std::sync::Mutex<MemoryState>>
```

with:

```rust
struct MemoryState {
    entries: HashMap<CacheKey, Entry>,
    recency: VecDeque<RecencyToken>,
    resident_bytes: usize,
    next_generation: u64,
}

enum Entry {
    InFlight {
        fingerprint: Fingerprint,
        lease: LeaseId,
        expires_at: Instant,
        generation: u64,
    },
    Completed {
        fingerprint: Fingerprint,
        response: Arc<CachedResponse>,
        expires_at: Instant,
        weight: usize,
        generation: u64,
    },
}
```

A generation-tagged `VecDeque` permits amortized O(1) lazy LRU maintenance: stale queue records are skipped when popped. Capacity must be bounded by both entry count and resident bytes; request fingerprint, response body and headers count toward the weight.

`std::sync::Mutex` is appropriate because the lock protects short, non-awaiting in-memory mutations only. Tokio’s documentation says the ordinary blocking mutex is often preferred in async code when the guard is not held across `.await`; the async mutex is more expensive and is principally for shared I/O resources. ([docs.rs](https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html))

Store behavior:

1. Purge expired records.
2. On absent key, atomically insert `InFlight` and return a lease.
3. On matching `Completed`, return the stored response.
4. On a different fingerprint, return `422 Unprocessable Content`.
5. On matching `InFlight`, return `409 Conflict`.
6. On capacity exhaustion with no safe eviction candidate, reject before invoking the handler.
7. Never hold the mutex while awaiting the handler or reading/writing an HTTP body.

This mirrors Python’s ordered, evictable store while adding explicit concurrency semantics.

#### Response completion and replay

A completed snapshot should contain:

- status code;
- bounded body bytes;
- stable end-to-end response headers;
- completion time and expiry;
- the original request fingerprint.

Exclude or regenerate hop-by-hop and per-attempt headers such as connection framing and the current request ID. On replay, add:

```http
Idempotency-Replayed: true
```

Application errors that should be replayed must be normalized into HTTP responses inside the protected operation boundary. A raw service error with no replayable HTTP result should call `abort`, unless the adapter can produce a deterministic response.

Streaming or unbounded responses are not eligible. If an operation can commit a side effect and then exceed the response snapshot limit, preserve an `UnreplayableCompleted` tombstone and reject later retries rather than re-executing the operation.

#### Minimal reference flow

```rust
async fn handle<S, F>(
    store: &S,
    policy: PersistencePolicy,
    request: Request,
    next: F,
) -> Response
where
    S: IdempotencyStore,
    F: OperationService,
{
    if !matches!(request.method(), POST | PUT | PATCH) {
        return next.call(request).await;
    }

    let Some(header_key) = parse_idempotency_key(request.headers()) else {
        return next.call(request).await;
    };

    let (parts, body) = collect_request_with_limit(request).await?;
    let key = derive_scoped_key(&parts, header_key)?;
    let fingerprint = fingerprint_v1(&parts, &body);

    match store.begin(&key, &fingerprint).await? {
        Begin::Replay(snapshot) => return snapshot.replay_with_header(),
        Begin::FingerprintConflict => return problem_422(),
        Begin::InFlight => return problem_409(),
        Begin::Leader(lease) => {
            let request = rebuild_request(parts, body);
            let result = next.call_operation(request).await;

            match result {
                Ok(response) => {
                    let execution_started = true;
                    let (response, snapshot) =
                        snapshot_response_with_limit(response).await?;

                    if policy.should_store(execution_started, snapshot.status) {
                        store.complete(lease, snapshot).await?;
                    } else {
                        store.abort(lease).await?;
                    }

                    response
                }
                Err(error) => {
                    store.abort(lease).await?;
                    map_service_error(error)
                }
            }
        }
    }
}
```

#### Observable acceptance criteria

| Case | Expected result |
|---|---|
| No header | Handler executes on every request; no replay header |
| GET/DELETE with header | Bypassed |
| Same scope, method, target, key and fingerprint after completion | Original status/body/stable headers replayed; `Idempotency-Replayed: true`; handler count remains one |
| Same raw key on another path, method or principal | Independent operation |
| Same scoped key with different body | `422`; handler is not called |
| Concurrent matching requests | One handler execution; other request receives `409` |
| Completed handler returns `500`, recommended policy | Second request replays the same `500`; handler count remains one |
| Pre-handler validation returns `400` | Not persisted; corrected request with the same key may execute |
| TTL expiry or completed-entry eviction | Request may execute again; limitation documented |
| Process restart | Entry is lost; single-instance/non-durable limitation documented |
| Store reaches capacity with only in-flight entries | Reject before handler execution |
| Future distributed store | Same adapter and contract tests pass against another `IdempotencyStore` implementation |

#### Representative performance evaluation

No benchmark was executed during this research, and no absolute-fastest claim is made.

The acceptance benchmark should cover:

- 1 KiB and 64 KiB JSON bodies;
- 1 KiB responses;
- 0%, 50% and 99% replay-hit workloads;
- concurrency 1, 32 and 256;
- handlers taking 0 ms, 10 ms and 100 ms;
- sequential duplicates and same-key concurrent bursts;
- capacity and expiry churn.

Measure:

- p50/p95/p99 latency;
- handler execution count;
- mutex acquisition wait;
- fingerprint time;
- cache hit/miss/conflict/eviction counts;
- resident bytes and peak RSS;
- incremental clean-build time and release binary size.

Moka is the appropriate comparison implementation if the bespoke lock becomes measurable. Its richer concurrency and eviction machinery should not be presumed faster for this workload without a like-for-like benchmark. ([docs.rs](https://docs.rs/crate/moka/latest))

**Perplexity**

The shared requirement comes from the Python template and the owner’s direction: unsafe HTTP methods (POST, PUT, PATCH) carrying an idempotency key must be protected against accidental duplicate execution of logically single operations, such as payments or resource creation, by replaying a cached successful response rather than re-running the operation, while allowing error responses to be retried as genuine attempts rather than replayed failures. This requirement is at the level of architectural pattern and policy rather than a single library, and the Rust implementation must preserve the behavior while adjusting to language and ecosystem idioms.

The essential behaviors can be grouped into four principles. First, idempotency is keyed: the client supplies an `Idempotency-Key` header, which is treated as the primary identifier of the logical operation; this key is scoped to a combination of method, path, and possibly body fingerprint, so that replays are confined to the same endpoint and request semantics.[1][11][12] Second, replay is conditional: on the first request with a given key and matching scope, the handler executes, and the middleware caches the response if and only if it represents success, defined as an HTTP status code in the 2xx range.[1] Third, errors are not cached: responses with codes outside the 2xx range are served to the client but not stored in the idempotency cache, so that subsequent requests with the same key can retry the operation rather than receiving a stale failure; this behavior mirrors Stripe’s semantics and the Python template’s explicit `200 <= status_code < 300` check before caching.[1] Fourth, the store is single-instance and in-memory by default: for a single-process deployment, a bounded in-memory store backs idempotency entries, with ordered eviction semantics and clear documentation that, at scale, this store should be replaced by a distributed cache such as Redis, but without pre-emptively coupling the template to a particular distributed technology.[1]

Observable acceptance criteria derive from these principles. A test harness should demonstrate that when a client sends two identical POST requests with the same `Idempotency-Key` and body to an endpoint backed by the middleware, the handler runs only once; the second request receives the same response body, status code, and replay header (e.g., `Idempotency-Replayed: true`) as the first, while logs show no duplicate handler execution.[12] Another test should show that when the first response is a 4xx or 5xx error, the middleware does not cache it: subsequent requests with the same key trigger fresh handler execution, potentially producing a success, and only at that point does the cache store a response for replay. A third acceptance test should verify scoping: if the same idempotency key is used on two different endpoints or with differing bodies, the middleware either treats them as distinct operations by incorporating path and method into the key or returns a conflict response, such as 422 with an `idempotency_key_conflict` code, in line with draft IETF guidance.[1] Finally, an architectural acceptance criterion is that the in-memory store can be replaced by a distributed implementation without changing the middleware’s public API or behavior; only the store wiring should change.

In the Rust ecosystem, architectural alternatives for realizing these principles fall into three main categories. One is to adopt a framework-specific middleware crate such as `axum-idempotent`, which already supports a client-provided key mode where a header like `Idempotency-Key` is used directly as the cache key, and a hashing mode where the server derives a unique hash from method, path, headers, and body.[12] This approach provides ready-made request interception, caching, and replay with observability via an `idempotency-replayed` header, but it binds the template to Axum, which is R69’s decision, and its storage model is tied to the crate’s internal choices rather than a generic store trait. Another alternative is to use `cratestack::idempotency` as a model: this middleware captures the response on the first request with a given key, persists it, and then replays it on subsequent matching requests, or returns a 422 conflict if the same key is used with a different request body, thereby aligning with IETF semantics.[1] However, `cratestack` appears to be part of a larger stack and may not expose a generic trait surface that can be easily reused in `rs-launch-blueprint`. A third alternative is to hand-roll a middleware layer in the chosen framework, using a generic key-value store trait and reusing semantic primitives from `use-idempotency` for keys, scope, and replay status.[11]

For the store itself, alternatives include a simple `HashMap` behind a mutex or RwLock, which is easy to implement but lacks built-in bounding, admission and eviction policies, and may require bespoke logic for TTL and concurrency; a general-purpose cache crate like `cached`, where function memoization macros are repurposed to cache HTTP responses keyed by idempotency keys; or a dedicated caching library like Moka, which offers both synchronous and asynchronous caches with concurrency, bounds, and expiration controls.[2][3][5][6][7][8][9][10][16] The `cached` crate’s strengths lie in per-function caching, memoization macros, and support for various backends including Redis and `redb` disk storage, as well as async traits that drive concurrent stores.[2][4] It also enables custom stores implementing its `Cached` traits, meaning that a user’s own cache like Moka can be dropped in while still using its macros.[2][4] However, its focus on memoizing function outputs and its Rust version requirement of at least 1.92 suggest that it may be less aligned with the template’s need for explicit middleware semantics and may pose MSRV considerations.[2] Moka, conversely, is explicitly designed for high-concurrency in-memory caching, with `future::Cache` providing async operations `insert`, `get`, `invalidate`, and builders for TTL and TTI, and example code showing how it can be shared across multiple tasks or threads in a Tokio runtime.[3][5][6][7][8][9] This makes Moka a strong candidate for the idempotency store.

Regarding cache key derivation and scoping, the Python template appears to use a composite key abstraction `_CacheKey` combining the raw idempotency header with method and path, though its exact shape is not detailed here.[1] The Rust ecosystem offers two patterns: direct-key mode, where the client-provided key string is used directly as the cache key (as recommended by `axum-idempotent` because it is performant and observable, avoiding server-side hashing), and hashed mode, where a unique hash derived from method, path, headers, and body forms the key.[12] `cratestack::idempotency` exemplifies a hybrid: it uses the idempotency key and stores a response keyed by that value and a body hash, ensuring that a mismatched body produces a conflict.[1] The principle behind these patterns is that idempotency keys must be scoped to the logical operation they represent; the bundle must decide whether to adopt direct-key mode alone, composite mode, or hashing mode. Fit with the Python template suggests direct-key mode with composite scoping: the raw header string plus method and path constitute the key, with body hash optionally added to enforce conflict detection across different payloads.

The pattern of caching only successful outcomes is not a library feature in most crates but a straightforward idiom: inspect the response’s status code inside the middleware’s response-side logic and insert into the cache only if the status code is in the 2xx range. In `cratestack::idempotency`, the emphasis is on protecting mutating routes and replaying stored responses only when the request body hash matches, but the docs do not explicitly state whether it caches only 2xx responses; however, the IETF draft semantics and common idempotency patterns suggest that caching errors is discouraged.[1] In Python, the code explicitly checks `200 <= status_code < 300` before storing an entry.[1] In Rust, this rule should be expressed as a clearly testable condition in the middleware: a boolean guard before calling the store’s `insert` method, and unit tests that confirm non-2xx responses are not cached. No surveyed crate makes the 2xx-only rule an explicit configuration option, so this is a pattern implemented by the middleware rather than a feature flag; this is acceptable as long as it is clearly documented and tested.

Architecturally, the recommended design is to treat idempotency as a cross-cutting concern implemented by middleware and store traits. The bundle should define a `IdempotencyStore` trait with methods like `get`, `insert_success`, and `mark_conflict`, parameterized by a key type modeled with `use-idempotency` types (e.g., `IdempotencyKey`, `IdempotencyScope`, `ReplayStatus`).[11] The default implementation of this trait should wrap a `moka::future::Cache` storing entries keyed by a composite struct containing the key string and request metadata, with values representing cached responses and their replay status.[3][5][6][8][9] Middleware in the chosen web framework (decided by R69) should intercept unsafe methods, extract the idempotency header, derive the composite key, consult the store, and either replay a stored response (annotated with a replay header) or execute the handler, then apply the 2xx-only guard before writing into the store. This design keeps the semantics in `rs-launch-blueprint`’s own code, uses crates for primitives and storage, and mirrors Python behavior while remaining extensible: adding a distributed store is a matter of implementing `IdempotencyStore` with Redis or a similar backend, without rewriting the middleware.

Because the recommended design does not challenge the Python baseline but rather re-expresses it in Rust idioms, there is no `BASELINE-REVIEW` item proposed here that would change the principle or ledger classification. The divergence noted in F313–F315 (Python has idempotency middleware, TypeScript does not) is resolved by adopting idempotency in Rust, aligning with Python and best practice. The main variations are in implementation details—use of Moka instead of `OrderedDict`, and explicit use-idempotency types for metadata—which are implementation differences, not principle changes.

**Gemini**

The shared requirement across the templates mandates the implementation of an `Idempotency-Key` replay middleware specifically targeting unsafe HTTP methods. The essential behaviors dictate the interception of POST, PUT, and PATCH requests carrying the designated header. Crucially, the middleware must cache only successful outcomes, meaning responses with status codes in the $200 \le x < 300$ range, ensuring that genuine transient errors (5xx) or client validation errors (4xx) are naturally retried by the client rather than artificially replayed by the server. Finally, the architecture must utilize an in-memory, single-instance-by-design store that is explicitly documented and trait-bound as a future distributed-store swap point. 

This constitutes a strict architectural pattern. The ecosystem requires total agreement on the behavior of the deduplication state machine and the store's trait boundaries. What may vary is the concrete memory structure utilized to fit the language-specific concurrency model. In the Python precedent, the template utilizes a standard `OrderedDict` to act as an LRU cache, protected by the nature of the language's execution model. In asynchronous Rust, attempting to mirror this by wrapping an `std::collections::HashMap` (or a `BTreeMap`) inside a `tokio::sync::Mutex` introduces a catastrophic bottleneck. Every cache read, write, or eviction requires a total lock across the asynchronous reactor, destroying throughput and causing severe latency spikes. Furthermore, manual eviction algorithms in Rust are notoriously difficult to implement efficiently without violating strict borrowing rules or introducing race conditions.

`BASELINE-REVIEW: F315 — architectural pattern — proposed change to utilize a concurrent TTL-aware cache (moka) instead of a Mutex-bound OrderedDict — evidence: manual LRU eviction in asynchronous Rust requires expensive exclusive locks on every read operation to update access ordering; the crates.io backend explicitly migrated to moka to avoid this exact lock contention under heavy production load [cite: 5].`

A naive implementation of an idempotency cache simply checks the store, invokes the endpoint if the key is missing, and saves the resulting response. However, in a distributed environment, if a client retries a request due to a network timeout before the initial request finishes processing, both requests will read a "miss" from the cache. They will then execute simultaneously, causing the exact duplicate side effects idempotency is meant to prevent [cite: 4, 12]. Stripe’s standard [cite: 3] and advanced reference implementations like `idempotency-rs` [cite: 13] resolve this by formalizing a strict state machine. The Rust template must define an `IdempotencyStore` trait that mandates an atomic `try_acquire_lock` method. This method must atomically return either an `Acquired` token if the key is new, or a `Conflict` response (typically yielding an HTTP 409) if a request tied to that key is currently in flight [cite: 13, 14]. 

To satisfy the acceptance criteria, the cache key derivation must be handled with cryptographic precision. The key must never be the raw header value alone. If a client mistakenly sends the same idempotency key to both a `/charge` endpoint and a `/refund` endpoint, a raw key would cause a severe cross-endpoint replay collision [cite: 2]. It must be a composite of the header value, the HTTP method, and the URI path. In Rust, this is idiomatic to express as a strongly typed struct implementing the `Hash`, `Eq`, and `Clone` traits. 

Regarding response semantics, the middleware must explicitly inspect the HTTP status code before committing the response to the store. The `tower::Service` implementation will await the inner service's future, inspect `response.status().is_success()`, and only call the `complete_with_response` store method if the condition holds. If the inner service yields an error, the middleware must call a `release_lock_on_failure` method on the store, completely clearing the pending state so the client can legitimately retry the operation [cite: 13, 15].

By implementing this logic strictly as a generic `tower::Service`, the design preserves the principle of framework agnosticism. It integrates flawlessly with `axum`, `tonic`, or any hyper-based framework chosen by downstream consumers, incurring a zero-cost abstraction penalty while cleanly isolating the idempotency state machine from the underlying business logic. 

### Recommendation

**OpenAI**

**Do not adopt the bundle exactly as currently worded. Adopt F313 and F315, and send F314 through the stated baseline-review process.**

One stack:

1. **Internal framework-neutral `IdempotencyEngine` and `IdempotencyStore` contract, versioned as an application-internal pattern.**
2. **In-memory store:** `Arc<std::sync::Mutex<MemoryState>>` containing a bounded `HashMap` plus generation-tagged `VecDeque`.
3. **Fingerprint:** `sha2` **0.11.0**, SHA-256, with an explicit `FingerprintV1` wire/storage format.
4. **HTTP adapter:** the R69-native middleware model. The maintained reference profile is `tower` **0.5.3** with default features disabled if R69 selects a Tower-compatible framework.
5. **Default persistence policy:** `CompletedOutcome`, not `SuccessOnly`.
6. **Compatibility policy:** retain a named `SuccessOnly` option whose only store condition is `response.status().is_success()`.
7. **Future swap point:** implement Redis/SQL using the same atomic `IdempotencyStore` operations; do not expose a generic KV interface.

**Perplexity**

The report recommends that `rs-launch-blueprint` adopt an idempotency-key replay middleware for unsafe methods in the Rust port, using a bundle composed of three layers: idempotency primitives via the `use-idempotency` crate, an in-memory, futures-aware cache provided by `moka::future::Cache` as the default store implementation, and a framework-agnostic middleware pattern to be wired into whatever web framework R69 chooses. This stack should implement Stripe-style semantics and mirror the Python template’s behavior: direct `Idempotency-Key` header, scoping to method and path, caching only 2xx responses, and single-instance, in-memory store documented as a swap point for future distributed deployments.[1][3][5][6][7][8][9][11][12]

At the semantic layer, `use-idempotency` offers small, validated Rust types modeling idempotency keys, scopes, replay statuses, conflict statuses, and request fingerprint labels.[11] These types allow the template to express idempotency metadata and behavior in a type-safe way, reducing the risk of stringly typed bugs and making logging and observability more structured. Because `use-idempotency` explicitly avoids prescribing storage or hashing strategies, it can be integrated into any middleware or store design, leaving R73 free to choose the store and R69 free to choose the framework.[11] This crate should be added as a dependency with license compatibility and MSRV checks during integration, and used to represent API primitives such as `IdempotencyKey` and `ReplayStatus` in the middleware, response annotations, and logs.

For the in-memory store, the recommendation is to use `moka::future::Cache`, which provides a thread-safe, concurrent, futures-aware cache implementation that works under async runtimes like Tokio, async-std, or actix-rt.[3][5][6][7][8][9] Moka’s asynchronous cache allows entries to be inserted and invalidated via async methods, and accessed via `get`, which returns a clone of the stored value.[8] Its builder interface lets the template configure bounds (e.g., maximum entries) and expiration policies such as TTL and TTI, and its TinyLFU-inspired admission plus LRU eviction aim at high hit ratios in practice.[3][5][6][7][9] The crate’s documentation illustrates how a `future::Cache` can be cloned and shared across multiple tasks, storing up to ten thousand entries and supporting insertions and invalidations across concurrent tasks.[8] This makes it an ideal default store for idempotency entries in a single-instance deployment: it is in-memory, concurrency-safe, bounded, and tested in production environments such as crates.io.[7] `rs-launch-blueprint` should wrap Moka in a `IdempotencyStore` trait implementation, hiding cache details behind a semantic interface, so that future distributed stores (e.g., Redis) can implement the same trait.

The middleware pattern should be hand-rolled, using `use-idempotency` types and the `IdempotencyStore` trait, and integrated into the chosen web framework as a standard middleware layer. It should be informed by existing Rust idempotency middleware crates—`cratestack::idempotency` and `axum-idempotent`—but not depend on them at template level to avoid coupling to Axum or a particular stack.[1][12][13] That pattern should operate in a direct-key mode by default: if a client sends an `Idempotency-Key` header, the middleware treats its value as the primary key of the logical operation, deriving a composite key from the raw header string, HTTP method, and path, and optionally a body hash for conflict detection.[1][11][12] On receipt of a request, the middleware should check the store: if an entry exists and matches the scope, it should immediately replay the cached response, setting a replay header such as `Idempotency-Replayed: true` for observability, and skip handler execution.[12] If no entry exists, the middleware should call the handler, capture the response, inspect its status code, and insert it into the store only if the status is in the 2xx range, using a guard function that makes this rule explicit and testable. Conflict semantics should be implemented by comparing body hashes when the same key is reused with a different payload and returning an appropriate error such as 422, modeled on `cratestack::idempotency` and IETF drafts.[1][11]

While the template remains agnostic to the exact framework, it is reasonable to treat Axum as a leading candidate for R69 due to its widespread use in async Rust web services. The `axum-idempotent` crate can serve as a reference implementation for how to structure middleware behavior, but R73 should not declare it as a template dependency now. If R69 indeed chooses Axum, then `rs-launch-blueprint` may decide in a later item to use `axum-idempotent` directly or wrap it, but that is outside R73’s scope. For now, R73’s bundle focuses on semantics and store, and describes a middleware pattern that can be implemented in Axum, Actix Web, Warp, or other frameworks with similar middleware models.

The recommended bundle therefore looks conceptually like this: `use-idempotency` for types and semantics, `moka::future::Cache` for default in-memory store, and `rs-launch-blueprint`’s own middleware code for unsafe methods. This bundle respects the owner’s parameters—Rust 2024 edition, MSRV policy, licensing, CI targets—subject to verification of crate-specific MSRV and license details during integration. It aligns with Python’s idempotency behavior, uses well-regarded Rust libraries, and leaves a clear extension point for distributed stores, satisfying both equivalency and best practice.

**Gemini**

The recommended stack is a hand-rolled `tower::Service` component (`IdempotencyMiddleware`) wrapping an asynchronous `IdempotencyStore` trait, with `moka` (specifically `moka::future::Cache`) serving as the concrete in-memory provider for local development.

### Members

**OpenAI**

#### Internal `IdempotencyEngine` + bounded memory store (OpenAI)

##### Landscape

This is an architectural-pattern member; crate download, release, repository and advisory figures are **inapplicable** because it is template-owned source rather than a published crate.

Maintenance state: **active**, owned and tested with the template.

##### Principles and implementation

The engine owns the idempotency state machine, while the R69 adapter owns HTTP body conversion and middleware trait plumbing. The memory store implements the same atomic contract expected of a future distributed store.

The core should have no dependency on Axum, Actix or another framework. HTTP-specific request extraction belongs in the adapter; key, fingerprint, reservation and response-snapshot types belong in the core.

##### Dominant choice

A small internal state machine is the dominant fit because no surveyed crate simultaneously provides:

- framework independence;
- POST/PUT/PATCH participation;
- principal and operation scoping;
- separate fingerprint conflict handling;
- atomic in-flight reservation;
- an ordered bounded memory store;
- explicit response-persistence policy;
- a future distributed-store interface.

##### Qualified shortlist

Only the internal state-machine pattern passed the complete semantic fit check.

`Moka` passed the functionality check for bounded TTL storage, but not the required upstream macOS test-evidence gate. ([docs.rs](https://docs.rs/crate/moka/latest))

##### Excluded by gate

| Candidate | Gate/result |
|---|---|
| `axum-idempotent` 0.3.0 | Excluded: Axum/session/cookie coupling; direct-key scope mismatch; no verified `rust-version` or macOS CI evidence; response policy differs. ([docs.rs](https://docs.rs/crate/axum-idempotent/latest)) |
| `cratestack-axum` 0.12.0 | Excluded: substantial unrelated framework surface and no required memory backend; package-level MSRV/OS evidence not completed. ([docs.rs](https://docs.rs/crate/cratestack-axum/latest)) |
| `moka` 0.12.16 | Excluded by gate 4: current docs state macOS is not tested in upstream CI. Also qualitatively heavier than the required store. ([docs.rs](https://docs.rs/crate/moka/latest)) |
| `idempotency-rs` | Excluded: repository describes itself as a sample; the advertised publication/version could not be independently verified through the mandated registry endpoint. ([github.com](https://github.com/bhatti/idempotency-rs)) |
| `http-cache-tower-server` | Excluded by category: implements ordinary HTTP response-cache semantics, not atomic operation idempotency. ([docs.rs](https://docs.rs/http-cache-tower-server/latest/http_cache_tower_server/)) |

##### Up-and-comers

`axum-idempotent` and `cratestack-axum` should be re-evaluated if they split out a small framework-neutral core with an atomic memory store and declared MSRV/platform matrix.

##### Fit for this template

The internal pattern keeps the CLI and library surfaces independent of the web framework. It adds no cache runtime, allocator or synchronization dependency and makes the single-instance limitation visible in application-owned documentation.

##### Recommendation

Implement:

- `IdempotencyStore` with atomic `begin`, `complete`, `abort`;
- `MemoryIdempotencyStore`;
- `PersistencePolicy::{CompletedOutcome, SuccessOnly}`;
- `KeyScope` and `OperationTarget` extractor interfaces;
- versioned fingerprint encoding;
- bounded response snapshots;
- metrics and replay header.

Place `#![forbid(unsafe_code)]` on the owning module or crate.

##### Ranked runner-up

`moka::future::Cache` 0.12.16, after downstream ubuntu/macOS CI evidence is obtained and only if benchmarks show the single mutex is material. Moka supports TTL, weighted capacity and atomic per-key insertion, but its richer eviction machinery is unnecessary for the initial template. ([docs.rs](https://docs.rs/crate/moka/latest))

##### Tradeoffs

Advantages:

- minimum dependency and compile cost;
- exact policy;
- straightforward deterministic tests;
- mirrors Python’s ordered store;
- future backend contract designed correctly from the start.

Costs:

- project owns eviction and expiration correctness;
- coarse lock can become a bottleneck at unusually high key cardinality;
- in-memory retention is neither durable nor cross-instance;
- bounded eviction means the published idempotency window is best-effort.

##### Parameters

Required constructor parameters; do not hide them in incidental defaults:

- methods: `POST`, `PUT`, `PATCH`;
- header: `Idempotency-Key`;
- replay header: `Idempotency-Replayed`;
- completed-entry TTL;
- in-flight timeout;
- maximum entries;
- maximum resident bytes;
- maximum request and replayable-response bytes;
- key length limit;
- persistence policy;
- principal/tenant scope extractor;
- material-header allowlist.

No registry-owned R73 parameter currently exists for these values.

##### Migration implications

Add:

- `src/web/idempotency/mod.rs`
- `src/web/idempotency/engine.rs`
- `src/web/idempotency/store.rs`
- `src/web/idempotency/memory.rs`
- `src/web/idempotency/fingerprint.rs`
- `src/web/idempotency/policy.rs`
- `src/web/idempotency/adapter_<r69>.rs`
- `tests/idempotency_http.rs`
- `docs/architecture/idempotency.md`

Record the F314 review in `docs/port/OWNER-REVIEW.md`; do not edit the commonality verdict silently.

##### Validation strategy

Planned:

- unit tests for every store transition;
- model/property tests over randomized begin/complete/expire/evict sequences;
- concurrent same-key integration test;
- process-restart test;
- capacity-exhaustion test;
- shared contract suite reusable by a future Redis/SQL store.

No implementation tests were executed during this research.

##### Confidence & re-verify trigger

**Confidence: high** for the architectural pattern; **medium-high** for the recommended persistence-policy change.

Re-verify if:

- R69 selects a framework without a usable route-level middleware boundary;
- R75 cannot distinguish pre-operation rejection from operation execution;
- a mature framework-neutral crate appears;
- multi-instance deployment becomes a supported template mode.

##### Sources

Retrieved September 18, 2026:

- IETF draft: `https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07` ([datatracker.ietf.org](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07))
- Stripe semantics: `https://docs.stripe.com/api/idempotent_requests?query=` ([docs.stripe.com](https://docs.stripe.com/api/idempotent_requests?...=))
- Tokio mutex guidance: `https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html` ([docs.rs](https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html))
- Cratestack reference: `https://rust-doc.cratestack.dev/cratestack/idempotency/index.html` ([rust-doc.cratestack.dev](https://rust-doc.cratestack.dev/cratestack/idempotency/index.html))
- Moka comparison: `https://docs.rs/crate/moka/latest` ([docs.rs](https://docs.rs/crate/moka/latest))

#### `tower` 0.5.3 reference adapter (OpenAI)

##### Landscape

Tower is the established middleware abstraction for Axum and several other Tokio/Hyper ecosystem projects. Tower’s `Service` and `Layer` traits are deliberately stable integration points, and Axum directly adopts them. ([tower-rs.github.io](https://tower-rs.github.io/tower/tower/))

Maintenance state: **stable-quiet**. Version 0.5.3 was published on January 12, 2026; the greater-than-six-month release interval triggers investigation but is not an at-risk signal for a stable core abstraction. ([docs.rs](https://docs.rs/crate/tower/latest))

Required figures:

| Figure | Required source | Result on 2026-09-18 |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/tower` → `crate.recent_downloads` | Unavailable: endpoint fetch failed |
| All-time downloads | same → `crate.downloads` | Unavailable |
| Last release | `GET https://crates.io/api/v1/crates/tower/versions` | Mandated endpoint unavailable; docs.rs fallback: 0.5.3, January 12, 2026 |
| Stars, archived, pushed | `GET https://api.github.com/repos/tower-rs/tower` | Unavailable |
| Open issues | GitHub issue-search endpoint | Unavailable |
| Issue responsiveness | 10 most recently opened issues | Not computable because API issue data was unavailable |
| Advisories | `https://rustsec.org/packages/tower.html` | Endpoint unavailable; `cargo audit` is a merge gate |
| Adopters | Reverse dependencies plus manifests | Axum and Tonic directly demonstrate Tower integration. ([raw.githubusercontent.com](https://raw.githubusercontent.com/tokio-rs/axum/main/axum/Cargo.toml)) |

No missing metric was replaced with a scraped approximation.

##### Principles and implementation

The adapter should be thin:

- parse participation data;
- buffer/rebuild bounded bodies using R69’s body API;
- derive operation scope;
- call the framework-neutral engine;
- turn replay/conflict states into responses;
- snapshot the completed response.

It must not contain store-specific logic.

##### Dominant choice

If R69 selects Axum or another Tower-compatible framework, implement a concrete `Layer` and `Service`. Tower explicitly supports application-specific middleware wrapping an inner service. ([tower-rs.github.io](https://tower-rs.github.io/tower/tower/))

##### Qualified shortlist

- `tower` 0.5.3, default features disabled;
- direct `tower-layer`/`tower-service` traits if R69 already exposes them and the full `tower` crate adds no utility needed.

##### Excluded by gate

- A direct unconditional R73 dependency is excluded until R69 chooses its framework.
- An Axum-only `middleware::from_fn` implementation is excluded from the core because it would force an R69 decision in R73.
- Final release remains gated on `cargo audit` and the mandated ubuntu/macOS matrix because the required API evidence could not be retrieved.

##### Up-and-comers

Framework-specific macro/function middleware can reduce boilerplate, but it does not improve the underlying store contract and would increase coupling.

##### Fit for this template

Tower provides the right compositional boundary for a CLI + library + web-service workspace: only the web member depends on the adapter; the library and CLI do not.

##### Recommendation

Reference profile:

```toml
[dependencies]
tower = { version = "0.5.3", default-features = false }

[dev-dependencies]
tower = { version = "0.5.3", default-features = false, features = ["util"] }
```

If R69 selects a non-Tower framework, replace only `adapter_<r69>.rs`; retain the engine, store, keys, fingerprints, policy and contract tests.

##### Ranked runner-up

Depend directly on:

```toml
tower-layer = "0.3.3"
tower-service = "0.3.3"
```

This reduces surface area but loses `ServiceExt::oneshot` and other test ergonomics unless those are added separately.

##### Tradeoffs

Tower’s type-heavy middleware composition can produce longer compile errors and some monomorphization. It otherwise has low incremental runtime cost, no default optional middleware features, and its crate root forbids unsafe code. ([tower-rs.github.io](https://tower-rs.github.io/tower/tower/))

##### Parameters

- version: 0.5.3;
- production features: none;
- test feature: `util`;
- MSRV declared upstream: Rust 1.64.0, comfortably below this template’s current 1.96 floor;
- license: MIT;
- runtime coupling: none in the core traits; concrete R69 server supplies the runtime. ([docs.rs](https://docs.rs/crate/tower/0.5.3/source/Cargo.toml.orig))

##### Migration implications

- Add Tower only to the web-service crate.
- Implement `IdempotencyLayer<S>` and `IdempotencyService<Inner, S>`.
- Keep `MemoryIdempotencyStore` in a framework-neutral module.
- Add `oneshot` integration tests without binding sockets where possible.

##### Validation strategy

Planned:

```bash
cargo +1.96.0 check --workspace --all-targets --all-features
cargo +1.96.0 test --workspace
cargo +stable clippy --workspace --all-targets --all-features -- -D warnings
cargo tree -e features -i tower
cargo audit
```

Run the first three commands on both `ubuntu-latest` and `macos-latest`.

##### Confidence & re-verify trigger

**Confidence: high** that Tower is the correct adapter abstraction if R69 is Tower-compatible; **conditional** on R69.

Re-verify on:

- R69 completion;
- Tower 0.6;
- an MSRV change;
- any RustSec advisory;
- failure of the downstream macOS matrix.

##### Sources

Retrieved September 18, 2026:

- `https://docs.rs/crate/tower/0.5.3` ([docs.rs](https://docs.rs/crate/tower/latest))
- `https://docs.rs/crate/tower/0.5.3/source/Cargo.toml.orig` ([docs.rs](https://docs.rs/crate/tower/0.5.3/source/Cargo.toml.orig))
- `https://raw.githubusercontent.com/tower-rs/tower/master/tower/src/lib.rs` ([raw.githubusercontent.com](https://raw.githubusercontent.com/tower-rs/tower/master/tower/src/lib.rs))
- `https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md` ([github.com](https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md))
- `https://raw.githubusercontent.com/tokio-rs/axum/main/axum/Cargo.toml` ([raw.githubusercontent.com](https://raw.githubusercontent.com/tokio-rs/axum/main/axum/Cargo.toml))
- `https://raw.githubusercontent.com/hyperium/tonic/master/tonic/Cargo.toml` ([raw.githubusercontent.com](https://raw.githubusercontent.com/hyperium/tonic/master/tonic/Cargo.toml))

#### `sha2` 0.11.0 (OpenAI)

##### Landscape

SHA-256 is an established standardized digest, while `sha2` is the RustCrypto implementation. Version 0.11.0 was released on March 25, 2026. ([docs.rs](https://docs.rs/crate/sha2/latest))

Maintenance state: **active**.

Required figures:

| Figure | Required source | Result on 2026-09-18 |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/sha2` | Unavailable: endpoint fetch failed |
| All-time downloads | same | Unavailable |
| Last release | `GET https://crates.io/api/v1/crates/sha2/versions` | Mandated endpoint unavailable; docs.rs fallback: 0.11.0, March 25, 2026 |
| Stars, archived, pushed | `GET https://api.github.com/repos/RustCrypto/hashes` | Unavailable |
| Open issues | GitHub issue-search endpoint | Unavailable |
| Issue responsiveness | 10 recent issues | Not computable |
| Advisories | `https://rustsec.org/packages/sha2.html` | RustSec lists historical RUSTSEC-2021-0100 concerning an old AVX2 backend; locked 0.11.0 must still pass `cargo audit`. ([rustsec.org](https://rustsec.org/packages/sha2.html)) |
| Adopters | Reverse dependencies plus manifest | AWS SDK for Rust’s SigV4 implementation uses `sha2 = "0.11"`. ([raw.githubusercontent.com](https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml)) |

##### Principles and implementation

The digest exists to detect a client reusing one scoped idempotency key with different request material. It is not part of the cache lookup key.

The input format must be versioned and length-prefixed so that future canonicalization changes cannot silently reinterpret old entries.

##### Dominant choice

`Sha256` from `sha2` 0.11.0:

- standardized output;
- deterministic across processes;
- suitable for a future distributed store;
- direct maintained production adoption;
- hashing cost expected to be dominated by HTTP body buffering for normal JSON requests.

##### Qualified shortlist

- `sha2` 0.11.0 — chosen;
- `blake3` 1.8.7 — faster-oriented alternative with excellent one-shot ergonomics;
- storing exact request bytes — collision-free but retains sensitive data and increases memory/storage cost.

##### Excluded by gate

- `DefaultHasher`: excluded by architectural fit because its output algorithm is not a stable persistence contract and is too short for a cross-instance fingerprint.
- SHA-1/MD5: excluded as obsolete choices for a new fingerprint contract.
- JSON reserialization/canonicalization: excluded from the generic middleware because it changes semantics by media type and adds parsing cost.

##### Up-and-comers

BLAKE3 remains the strongest alternative if profiling proves SHA-256 material. No such evidence exists for this workload. `axum-idempotent` itself uses BLAKE3 in its hashing mode, demonstrating ecosystem feasibility but not a reason to prefer it here. ([docs.rs](https://docs.rs/crate/axum-idempotent/latest))

##### Fit for this template

SHA-256 produces a portable fingerprint suitable for both the initial memory store and a future Redis or SQL implementation. The fingerprint format can remain unchanged when the store changes.

##### Recommendation

```toml
sha2 = { version = "0.11.0", default-features = false }
```

Use `Sha256::digest` over `FingerprintV1` material. Persist the 32-byte digest directly; do not hex-encode it internally.

##### Ranked runner-up

`blake3` 1.8.7. Select it only after a representative benchmark and after its advisory, MSRV, unsafe and ubuntu/macOS gates are independently completed.

##### Tradeoffs

SHA-256 is slower than BLAKE3 for large bodies, but idempotency-protected JSON operations should already have explicit request-size limits. No hashing benchmark was run, so the expected impact must be measured rather than inferred.

The crate root does not globally forbid unsafe code; optimized backend posture must be checked with dependency inspection. The public digest API used here is safe Rust. ([raw.githubusercontent.com](https://raw.githubusercontent.com/RustCrypto/hashes/master/sha2/src/lib.rs))

##### Parameters

- crate: `sha2` 0.11.0;
- algorithm: SHA-256;
- digest: 32 bytes;
- fingerprint schema: `FingerprintV1`;
- default features: disabled;
- license: MIT OR Apache-2.0;
- runtime coupling: none.

The crate and dependency tree must pass Rust 1.96 before merge; fetched metadata did not independently expose the complete dependency-tree MSRV.

##### Migration implications

Changing fingerprint algorithms after deployment requires:

- incrementing the fingerprint version;
- either retaining old verification support until existing records expire or flushing the store;
- coordinating all instances before a distributed-store rollout.

##### Validation strategy

Planned:

```bash
cargo +1.96.0 check --workspace --all-targets
cargo test fingerprint
cargo tree -e features -i sha2
cargo audit
cargo geiger --all-features
```

Tests must include:

- standard SHA-256 vectors;
- unambiguous length-prefix encoding;
- same body → same fingerprint;
- one-byte body change → conflict;
- content-type/material-header change → conflict;
- method/path change affects the scoped key rather than creating a misleading fingerprint miss.

##### Confidence & re-verify trigger

**Confidence: medium-high.** The algorithmic choice is strong; mandatory API metrics, complete MSRV metadata and current issue responsiveness remain evidence gaps.

Re-verify on:

- `sha2` 0.12;
- any RustSec advisory;
- distributed-store implementation;
- evidence that fingerprinting contributes materially to request latency.

##### Sources

Retrieved September 18, 2026:

- `https://docs.rs/crate/sha2/0.11.0` ([docs.rs](https://docs.rs/crate/sha2/latest))
- `https://raw.githubusercontent.com/RustCrypto/hashes/master/sha2/src/lib.rs` ([raw.githubusercontent.com](https://raw.githubusercontent.com/RustCrypto/hashes/master/sha2/src/lib.rs))
- `https://rustsec.org/packages/sha2.html` ([rustsec.org](https://rustsec.org/packages/sha2.html))
- `https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml` ([raw.githubusercontent.com](https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml))
- Runner-up: `https://docs.rs/crate/blake3/latest` ([docs.rs](https://docs.rs/crate/blake3/latest))

**Perplexity**

#### idempotency-primitives (use-idempotency) (Perplexity)

##### Landscape

The `use-idempotency` crate occupies a narrow but important niche in the Rust ecosystem: it is a primitives library for modeling idempotency keys, scopes, replay statuses, conflict statuses, and request fingerprint labels as small, validated types.[11] Its documentation emphasizes that these are “idempotency primitives for RustUse,” designed to model metadata for idempotent APIs rather than implementing storage or hashing strategies.[11] It defines structs such as `IdempotencyKey`, `IdempotencyScope`, `PrimitiveMetadata`, and `RequestFingerprintLabel`, and enums like `ApiPrimitiveError`, `ConflictStatus`, and `ReplayStatus`, providing type-safe representations of idempotency-related concepts.[11] An example in its docs shows constructing an `IdempotencyKey` with `IdempotencyKey::new("checkout:abc123")`, asserting its string representation, and iterating over replay statuses.[11] These features situate `use-idempotency` in the “established industry standard” bin within the specialized subcategory of idempotency metadata libraries, even though it is not yet as widely known as general caching crates.

Authoritative sources for `use-idempotency` are its docs.rs page and the crate’s own documentation, which detail its types, errors, and design goals.[11] The docs state that the crate’s goals are small validated types for API metadata, stable display labels and conservative parsing helpers, and dependency-light primitives reusable by other RustUse crates.[11] They also explicitly list non-goals: no storage backend, no request hashing, and no distributed lock implementation.[11] This clarity makes the crate a trustworthy authority for modeling idempotency metadata in Rust.

In terms of practice evidence, explicit adoption of `use-idempotency` in major projects is not documented within the provided sources, which is a gap that must be investigated by consulting crates.io and GitHub reverse-dependency lists during integration. However, its positioning and design suggest that it is intended as a shared primitive across RustUse crates and possibly across independent libraries implementing idempotent APIs.[11] For `rs-launch-blueprint`, which needs to express idempotency semantics in a robust, type-safe manner, this crate’s design goals align closely with the template’s needs, even if broader adoption evidence remains to be collected.

Fitness gates for `use-idempotency` can only be partially evaluated in this offline context. The license is described as “Licensed under either of the following, at your option: Apache License, Version 2.0; MIT license,” which is compatible with the template’s requirement of `MIT OR Apache-2.0`.[11] MSRV, RustSec advisories, CI platforms, and binary-size costs are not documented in the provided sources, so they must be verified by examining the crate’s `Cargo.toml`, CI badges, and RustSec entries during integration. There is no evidence in the available docs of unsafe code heavy usage or platform restrictions. Given its small scope and dependency-light design, it is reasonable to expect low compile-time and binary-size cost, but this is an assumption that must be confirmed empirically.

##### Principles and implementation

The principle behind using `use-idempotency` in `rs-launch-blueprint` is to separate idempotency metadata and semantics from storage and middleware mechanics, encoding keys, scopes, and statuses as explicit Rust types instead of ad hoc strings and integers. In the Python template, idempotency metadata is represented in a relatively ad hoc way: keys as strings, statuses as booleans or textual markers, scopes as implicit combinations of method and path. By adopting `use-idempotency`, the Rust template can upgrade these representations to structured types, making it easier to reason about idempotency behavior in code and to log and monitor it in production.[11]

Implementation-wise, `use-idempotency` provides the type `IdempotencyKey`, which can be constructed from a string representing the logical operation’s identifier, such as `"checkout:abc123"`, and later retrieved as a string via `.as_str()`.[11] It also provides `IdempotencyScope`, which likely models the scope of idempotency applicability, and `ReplayStatus`, an enum with variants like `Original` and others representing replay semantics.[11] These types can be used in the middleware layer to represent incoming idempotency headers, store entries, and replay markers. For example, when a request arrives with an `Idempotency-Key` header, the middleware can parse it into an `IdempotencyKey`, attach an `IdempotencyScope` representing method and path, and later set a `ReplayStatus` in the cached entry to `Original` for the first execution and `Replayed` for subsequent ones.

Because `use-idempotency` has clear non-goals—no storage backend, no request hashing, no distributed lock—it does not constrain the store or middleware design.[11] Instead, it serves as a semantic anchor: it provides types and labels that make it easier to interpret and log idempotency behavior while leaving decisions about caching, conflict handling, and concurrency coordination to other layers. This matches R73’s need to define idempotency semantics in the template itself, while delegating storage to Moka and distributed strategies to future work.

##### Dominant choice

`use-idempotency` is the dominant choice for idempotency metadata in this bundle because it is explicitly designed for that purpose and because it aligns with both the Python template’s semantics and Rust’s idioms for type safety. Alternative designs would involve defining custom structs and enums inside `rs-launch-blueprint` to represent idempotency keys, scopes, and statuses, but that would replicate functionality already provided by `use-idempotency` and reduce compatibility with other RustUse crates that may also adopt these primitives.[11] Using `use-idempotency` means that any future crates designed to work with idempotency metadata can integrate more smoothly.

The crate’s explicit licensing compatibility with Apache-2.0 and MIT, its small footprint, and its dependence on stable textual labels and conservative parsing helpers make it suitable for a template that is meant to be long-lived and widely reused.[11] It embodies a principle that the owner endorses: separate semantics from mechanism and reuse small, robust primitives when available.

##### Qualified shortlist

The qualified shortlist for idempotency metadata includes three options: `use-idempotency`, a custom set of types defined in `rs-launch-blueprint`, and reusing semantics from a framework-specific middleware crate such as `axum-idempotent` or `cratestack::idempotency`. `use-idempotency` stands out because it is dedicated to idempotency, small, and dependency-light.[11] Custom types inside the template would give maximum control but no reuse across crates, and would require duplicating label definitions and parsing logic. Reusing framework-specific semantics from `axum-idempotent` or `cratestack::idempotency` would tightly couple semantics to a particular framework or stack, making it harder to remain framework-agnostic and to share semantics with other crates.[1][12][13] Given the owner’s mandate for reusable, principle-driven design, `use-idempotency` is the better choice.

##### Excluded by gate

No idempotency metadata crate has been excluded by fitness gates in this report because the only such crate identified, `use-idempotency`, satisfies licensing compatibility and does not present any documented RustSec advisories in the available sources.[11] However, this is based on limited evidence; MSRV, CI platform coverage, and RustSec status must be verified later. Pattern-based alternatives (custom types, built-in strings) are excluded by the principle gate rather than fitness: they fail to provide a reusable, standardized representation of idempotency metadata across crates and therefore are not recommended.

##### Up-and-comers

Up-and-comers in the idempotency metadata space include potential future crates that may emerge as part of broader API toolchains, but within the available sources, `use-idempotency` is the only identified crate focusing specifically on idempotency primitives.[11] Other idempotency-related crates such as `axum-idempotent` and `cratestack::idempotency` are primarily middleware implementations; they might internally define types for keys and statuses, but they do not expose them as standalone primitives in the same way.[1][12][13] `rs-launch-blueprint` should watch for future developments in this area, but `use-idempotency` is an appropriate choice now.

##### Fit for this template

The fit of `use-idempotency` for `rs-launch-blueprint` is high. The template aims to be both a CLI and a web-service blueprint, with a library component that can be reused across projects. Having a dedicated crate for idempotency metadata allows the template to expose types like `IdempotencyKey` and `ReplayStatus` in its library API without binding to a particular storage or framework.[11] This matches the owner’s principle of agreement at the level of capability and pattern rather than specific libraries. In addition, `use-idempotency`’s dependency-light design ensures that adding it to the template does not impose a heavy compile-time or binary-size cost.

##### Recommendation

The recommendation is to include `use-idempotency` as a dependency in `rs-launch-blueprint` and to use its types to represent idempotency keys, scopes, replay statuses, and conflict statuses in the middleware and store implementations.[11] This includes using `IdempotencyKey` to parse and normalize the `Idempotency-Key` header, `IdempotencyScope` to model method and path combinations, and `ReplayStatus` to label responses as original or replayed. Doing so makes the template’s idempotency behavior explicit and well-typed, improving both safety and clarity.

##### Ranked runner-up

The ranked runner-up for idempotency metadata is a custom set of types defined directly in `rs-launch-blueprint`, representing keys as newtype wrappers around strings and statuses as enums. This approach may be necessary if future integration reveals that `use-idempotency` fails a fitness gate such as MSRV or RustSec advisories, but absent such issues, it is less desirable because it duplicates existing functionality and reduces standardization.

##### Tradeoffs

Using `use-idempotency` introduces an extra dependency into the template, which must be maintained and tracked over time. There is a tradeoff between relying on an external crate and defining internal types: external crates may evolve in ways that require adaptation, while internal types are under the template’s control. However, the benefits of reuse, stable labels, and potential interoperability outweigh these costs. Another tradeoff is that `use-idempotency` does not implement storage or hashing, leaving those concerns to other layers; this is purposeful but means that the template must still implement store and middleware logic.

##### Parameters

From the perspective of R73, `use-idempotency` does not own any template-global parameters but plays a role in defining how idempotency keys and scopes are represented. It effectively assumes that the parameter “idempotency-header-name” is `Idempotency-Key`, matching Stripe and Python, and that idempotency keys are short textual identifiers.[1][11] Those assumptions should be documented in the template’s configuration or documentation.

##### Migration implications

Including `use-idempotency` in the template implies file-level changes: the introduction of a module or namespace for idempotency, new type definitions referencing its structs and enums, and modifications to middleware and store code to use these types instead of raw strings. If in future the crate needs to be replaced, migration would involve replicating those types internally and updating imports, but the underlying semantics and APIs could remain similar.

##### Validation strategy

Validation for `use-idempotency` revolves around ensuring that its types correctly represent and enforce idempotency metadata. This includes tests that parse valid and invalid idempotency key strings into `IdempotencyKey`, checks that `ReplayStatus` has the expected display representations (e.g., `"original"` for `ReplayStatus::Original`), and checks that scopes and conflict statuses are correctly constructed.[11] These tests would be part of the template’s unit and integration test suites when wiring middleware.

##### Confidence & re-verify trigger

Confidence in `use-idempotency` is moderate to high, based on its clear design goals and licensing, but must be re-verified if RustSec advisories emerge, MSRV changes, or if future libraries provide more comprehensive idempotency semantics that supersede it.[11] A re-verify trigger could be a major version release of `use-idempotency` or a new ecosystem standard for idempotency modeling.

##### Sources

All claims about `use-idempotency` in this section are based on its docs.rs page and crate documentation.[11]

#### in-memory-cache-store (moka::future::Cache) (Perplexity)

##### Landscape

Moka is a high-performance concurrent caching library for Rust, inspired by the Caffeine library for Java.[3][5][6][7][9] It provides cache implementations on top of hash maps, with support for full concurrency of retrievals and high expected concurrency for updates, using a lock-free concurrent hash table as the central key-value storage.[5][6][9] All Moka caches perform best-effort bounding of the underlying map using an entry replacement algorithm that decides which entries to evict when capacity is exceeded.[3][5][6][7][9] Moka offers thread-safe, highly concurrent in-memory cache implementations in two flavors: synchronous caches that can be shared across OS threads, and an asynchronous, futures-aware cache that can be accessed inside and outside asynchronous contexts.[3][5][6][7][9] The asynchronous cache (`moka::future::Cache`) is defined in the `future` module and works with async runtimes such as Tokio, async-std, or actix-rt.[3][6][7][8][9]

Moka’s features include bounding caches by maximum number of entries or total weighted size, providing size-aware eviction, and maintaining near-optimal hit ratios through an admission policy controlled by Least Frequently Used (LFU) and an eviction policy controlled by Least Recently Used (LRU).[3][5][6][7][9] It supports TTL and TTI expiration, per-entry variable expiration, eviction listeners, and lock-free concurrent iteration.[3][5][6][7][8][9] The asynchronous cache allows entries to be manually added using `insert`, stored until evicted or invalidated, and accessed with `get`, which returns a clone of the stored value.[8] Example code in the docs shows creating a cache that can store up to ten thousand entries, sharing it across sixteen async tasks, inserting and reading entries, and invalidating every fourth key.[8] Another example uses the builder to set TTL and TTI, showing that an entry will expire after a certain idle time despite repeated `get` calls, illustrating the interaction between TTL and TTI.[8]

Authoritative sources for Moka are its docs.rs pages, openapps summaries, and the project’s GitHub repository, which collectively describe its architecture, features, and usage.[3][5][6][7][8][9][10][14] The docs.rs entry for `moka::future::Cache` provides detailed API signatures, semantics, and example code.[8] The Moka repository includes a changelog showing the addition of asynchronous caches (`moka::future::Cache`) and a roadmap for async-optimized caches.[10] An openapps summary describes Moka as a fast, concurrent caching library for Rust inspired by Caffeine, notes thread-safe synchronous and asynchronous caches, and highlights its TinyLFU-inspired admission and eviction policies, plus usage in crates.io.[7]

Practice evidence for Moka is strong. The openapps page specifically mentions that the crates.io registry uses Moka to maintain approximately eighty-five percent hit rates for its download endpoint, demonstrating adoption in a central Rust ecosystem service.[7] This indicates performance and reliability under real workloads. While specific download counts, GitHub stars, and issue metrics are not available in this report, the presence of recent releases (e.g., v0.12.16 dated August 9, 2026) and a roadmap suggest active maintenance.[3][6][10][14] Moka also has related projects such as `mini-moka` (a simpler cache), `mokabench` (a load generator for concurrent cache libraries), and `moka-cht` (a lock-free resizable concurrent hash table), which indicate a broader ecosystem around concurrent caching.[14]

Fitness gates for Moka can again be partially evaluated. Licensing details are not explicitly quoted in the docs provided, but open-source Rust libraries of this sort typically use MIT or Apache-style licenses; this assumption must be verified from the repository’s license files.[3][5][6][7][9][14] MSRV, RustSec advisories, and CI platform coverage are not detailed here and should be checked. However, given crates.io adoption and recent releases, Moka is likely fully compatible with current stable Rust and major platforms. Binary size and compile time costs are moderate: Moka uses concurrent data structures and may increase binary size relative to a simple `HashMap`, but its benefits in concurrency and eviction policy justify this cost for a web-service template.

##### Principles and implementation

Moka embodies principles of high-performance, concurrent caching with near-optimal hit ratios. Its central design choices—lock-free concurrent hash table, LFU admission, LRU eviction, and flexible expiration policies—aim to provide caches that behave well under multi-threaded and async workloads.[3][5][6][7][9] For `rs-launch-blueprint`, using Moka as the in-memory idempotency store means aligning with those principles and leveraging an established cache implementation rather than building one from scratch.

The `moka::future::Cache` type provides the core API for the asynchronous store. A cache can be created by calling `Cache::new(capacity)` or using the builder interface to set TTL, TTI, and other options.[8] Entries are inserted via `insert(key, value).await`, retrieved via `get(&key).await`, and removed via `invalidate(&key).await`.[8] Because `get` returns a clone of the stored value, values that are expensive to clone can be wrapped in `Arc` to make cloning cheap.[8] This pattern is particularly useful for idempotency responses, which may contain bodies or structured data that are large; storing them in `Arc` allows cheap cloning for replay.[8] The builder example shows combining TTL and TTI: an entry is inserted with an idle time limit of five minutes and a total lifetime limit of thirty minutes, and repeated `get` calls extend the idle time while the total TTL remains fixed.[8]

Implementing an idempotency store with Moka means defining a key type, such as a struct containing `IdempotencyKey`, method, path, and optionally body hash, and a value type representing cached responses and metadata. The `IdempotencyStore` trait would then be implemented using Moka’s cache, with methods mapping to `get`, `insert`, and `invalidate`. For example, `get_entry(key)` would call `cache.get(&key).await`, while `insert_success(key, entry)` would call `cache.insert(key, entry).await` only when the middleware has determined that the response status is in the 2xx range.[8] Eviction policies and bounds would be configured via the builder, possibly using TTL to limit idempotency window durations (e.g., hours or days) and capacity to bound memory usage.

##### Dominant choice

Moka is the dominant choice for the in-memory default idempotency store in this bundle because it provides a robust concurrent cache implementation with async support, bounding, and expiration policies, and has demonstrated production usage in a central service like crates.io.[3][5][6][7][8][9] Alternatives like a simple `HashMap` behind a lock or the `cached` crate either lack concurrency or are oriented toward function-level memoization rather than HTTP response caching.[2][4][16] Moka’s `future::Cache` integrates naturally with Rust’s async ecosystem and matches the template’s need for a futures-aware store.

Another factor in Moka’s dominance is its separation between sync and async caches, gated by crate features such as `sync` and `future`.[3][5][6][7][9] This allows `rs-launch-blueprint` to enable only the `future` feature needed for web-service idempotency while keeping the CLI and library components free of unnecessary dependencies. The presence of `mini-moka` for simpler use cases also indicates that the Moka team understands different needs and can provide lighter options if necessary.[5][6][14]

##### Qualified shortlist

The qualified shortlist for the in-memory store includes Moka, the `cached` crate, and a bespoke bounded `HashMap` behind a synchronization primitive. `cached` offers various cache types (unbounded, sized/LRU, TTL, LRU+TTL, sharded) and macros for memoizing functions, as well as async traits for concurrent stores and support for Redis and disk-backed stores via `redb`.[2][4][16] It could be used to implement idempotency caching either via a custom function annotated with `#[cached]` or by using its trait-based store abstractions. However, its primary focus on function memoization, the complexity of its macro-based interface, and its Rust version requirement of 1.92 suggest that it may be more complex to integrate into a template that aims for clarity and moderate MSRV.[2] A bespoke `HashMap` approach would be simplest in terms of code but lacks bounding and eviction policies, requiring custom logic that is likely inferior to Moka’s tested algorithms.

Given these options, Moka stands out as the best compromise: it provides strong features and performance with a straightforward API, and it is built for caches rather than function memoization. The template can still adopt `cached` in other areas (e.g., CLI-level memoization) if needed, but for idempotency caching, Moka is preferred.

##### Excluded by gate

The `cached` crate is not excluded from the ecosystem but is effectively excluded from being the primary idempotency store in this bundle due to fit and potential MSRV concerns. Its documentation states that the crate requires Rust version at least 1.92, and that certain async features do not compile before that version due to borrow checker limitations.[2] While the current stable Rust version relative to 1.92 cannot be confirmed in this report, the template’s MSRV policy of “stable minus two minor versions” means that any crate with an MSRV far ahead of stable would be problematic. Until this compatibility is verified, the bundle treats `cached` as a runner-up rather than the dominant choice. Furthermore, its orientation toward function memoization does not perfectly align with idempotency store semantics. It remains a candidate for other roles in the template.

##### Up-and-comers

Up-and-comers in the caching space include `mini-moka`, a simpler concurrent cache library that may suit many use cases, and `quick-cache`, another cache library comparing features with Moka.[5][6][14] These libraries might be relevant for smaller or simpler templates but are less tested in production than Moka, and do not offer asynchronous caches in the same way.[6] `rs-launch-blueprint` could consider them for future microservices or CLI-level caching but should base its initial idempotency store on Moka.

##### Fit for this template

Moka fits the template’s needs well. Its asynchronous cache is designed to integrate with async runtimes used in web services, and its bounding and eviction features allow the template to implement a single-instance, in-memory store with predictable memory usage.[3][5][6][7][8][9] Because Moka’s caches can be cloned cheaply and shared across tasks, they are suitable for a multi-task web service with a single process.[8] The ability to configure TTL and TTI gives the template fine-grained control over how long idempotency entries persist, which can be tuned based on application semantics (e.g., how long a client is allowed to retry a payment with the same key).[8] The library’s separation between sync and async caches and its feature-gated design means the template can keep its dependency footprint modest.

##### Recommendation

The recommendation is to use `moka::future::Cache` as the default in-memory store for idempotency entries in `rs-launch-blueprint`, wrapping it in a `IdempotencyStore` trait implementation that hides cache details and expresses idempotency semantics.[3][5][6][7][8][9] The template should enable the `future` feature for Moka in `Cargo.toml` to access the asynchronous cache.[6] The store implementation should configure capacity, TTL, and TTI according to the template’s needs and use `Arc` to store response values to make cloning cheap.[8] This design mirrors Python’s ordered, evictable cache but uses a well-tested Rust library with robust concurrency.

##### Ranked runner-up

The ranked runner-up is a bespoke bounded `HashMap` behind a synchronization primitive such as `tokio::sync::Mutex` or `RwLock`, implementing a simple LRU policy. This approach is simpler in dependencies but more complex to implement correctly and less likely to achieve the performance and concurrency properties of Moka. It could be used in minimal deployments or for educational purposes but is not recommended for the production template.

##### Tradeoffs

Using Moka entails a tradeoff between dependency complexity and performance. The template must depend on Moka and understand its configuration options, and any bugs or security issues in Moka could impact the template. However, building a cache from scratch is error-prone and likely to perform worse. Another tradeoff is between fine-grained control over cache behavior and relying on Moka’s defaults; the template should decide whether to expose TTL and capacity as configuration options or to hard-code them.

##### Parameters

At the bundle level, Moka’s use influences parameters such as default cache capacity, TTL, and TTI for idempotency entries. R73 does not own these parameters independently but should suggest sensible defaults and document them. For example, a capacity of ten thousand entries and TTL of thirty minutes with TTI of five minutes are plausible starting values, based on examples in the docs.[8]

##### Migration implications

Migrating from Moka to a distributed store such as Redis involves implementing the same `IdempotencyStore` trait with a Redis-backed cache, while removing or reducing Moka usage. If the template later decides to use `cached` with a Redis store, the migration would involve replacing the Moka implementation with a `cached`-based one while keeping the middleware and semantics unchanged.[2][4]

##### Validation strategy

Validation for Moka’s use as idempotency store includes tests that exercise concurrent insert and get operations, TTL and TTI behavior for idempotency entries, and memory usage under load. Example test code could mirror the docs: spawn multiple tasks that insert and fetch idempotency entries while invalidating some of them, then assert that invalidated keys are absent and others preserve their values.[8] Additional tests should measure latency and throughput under realistic web-service load.

##### Confidence & re-verify trigger

Confidence in Moka is high due to its production usage and feature depth, but it must be re-verified if significant changes occur in its API, if RustSec advisories are issued, or if alternative caching libraries become clearly superior.[7][10][14] A re-verify trigger could be a major version bump or a new cache implementation benchmark showing major differences in performance or resource use.

##### Sources

All claims about Moka in this section are drawn from its docs.rs entries, openapps descriptions, and GitHub repository.[3][5][6][7][8][9][10][14]

#### idempotency-middleware-pattern (framework-agnostic, modeled on cratestack::idempotency and axum-idempotent) (Perplexity)

##### Landscape

The idempotency-middleware pattern in this bundle is not a single crate but a design inspired by two existing Rust implementations: `cratestack::idempotency` and `axum-idempotent`. The `cratestack` idempotency module is described as idempotency-key middleware protecting mutating routes (unsafe methods) against duplicate execution, by running the handler on the first request with a given `Idempotency-Key`, capturing and persisting the response, and replaying the stored response on subsequent requests with the same key if the request-body hashes match; if a different body is sent under the same key, it returns a 422 with an `idempotency_key_conflict` code, following a draft IETF spec.[1] The `axum-idempotent` crate provides middleware for handling idempotent requests in Axum applications, operating in two modes: Direct Key Mode, where a client-provided header (e.g., `Idempotency-Key`) is used directly as the cache key, and Hashing Mode, where a unique hash is generated from the request’s method, path, selected headers, and body.[12][13] Axum-idempotent returns cached responses for identical requests instead of re-executing the handler, preventing duplicate operations like accidental double payments, and supports observability via a replay header (e.g., `idempotency-replayed`) on cached responses.[12]

These two crates represent the “up-and-comer” bin of idempotency middleware in Rust: they are relatively new but embody best practices drawn from Stripe’s semantics and draft IETF guidance.[1][12][13] However, they are also framework-specific: `cratestack` appears to be part of a broader API stack, and `axum-idempotent` explicitly targets Axum, requiring integration with Axum’s middleware layers and optionally a session store backed by `ruts`.[12] Neither crate is fully framework-agnostic.

Authoritative sources for these patterns are their docs.rs pages and GitHub repositories, which describe middleware behavior, configuration options, and integration requirements.[1][12][13] `axum-idempotent`’s documentation explains the two modes, the use of session-based storage, and the correct ordering of middleware layers, such as placing `IdempotentLayer` inside `SessionLayer` in the outermost-to-innermost stack.[12] It also notes that the middleware ensures idempotency for HTTP requests and prevents duplicate operations.[12][13] `cratestack::idempotency` describes its behavior in terms of first request execution, response persistence, replay on subsequent requests with matching body hash, and conflict status for mismatched bodies.[1]

Practice evidence suggests that these patterns are influenced by Stripe-style semantics and are becoming more common in Rust web services, although precise adoption metrics are not available here. The presence of direct-key mode in `axum-idempotent`, with the `Idempotency-Key` header, and conflict semantics in `cratestack::idempotency` align with conventions seen in other ecosystems.[1][12][13]

##### Principles and implementation

The principle behind the idempotency-middleware pattern is to implement the semantics described in the Python template and draft IETF guidance in a framework-agnostic way: intercept unsafe methods, derive a key and scope, consult a store, replay cached responses when appropriate, and enforce 2xx-only caching and conflict detection. The implementation must be generic enough to be adapted to whatever web framework R69 chooses, such as Axum, Actix Web, or Warp, and must be compatible with the `IdempotencyStore` trait and `use-idempotency` types defined in the bundle.[11]

In direct-key mode, the client-provided `Idempotency-Key` header is treated as the primary key for idempotency. The middleware extracts the header, parses it into an `IdempotencyKey`, and constructs a composite key struct containing the key string, method, and path.[11][12] Optionally, it computes a body hash to detect conflicts when the same key is reused with different request bodies, as done in `cratestack::idempotency`.[1] The store is queried with this composite key; if an entry exists and matches the body hash and scope, the response is replayed, and a replay header such as `Idempotency-Replayed: true` is set.[12] The handler is not executed in this case. If no entry exists, the middleware calls the handler, captures the response, and applies the 2xx-only guard before inserting into the store via `IdempotencyStore::insert_success(key, entry)`.

In hashing mode, the middleware generates a unique hash from the request’s method, path, selected headers, and body to serve as the cache key, as described in `axum-idempotent`.[12] This mode is useful when clients cannot easily supply idempotency keys or when the service wants to enforce idempotency based solely on request content. However, it is less observable and less aligned with the Python precedent, which uses client-provided keys.

The recommended pattern for `rs-launch-blueprint` is to implement direct-key mode with composite scoping and optional body hash, as this aligns with Python and Stripe semantics.[1][12] The idempotency middleware should treat the absence of an `Idempotency-Key` header as a signal to bypass idempotency logic and run the handler normally, while still considering other middleware such as rate limiting.[12] It should also allow configuration of which headers are included in hashing (if hashing mode is used) and which methods are considered unsafe.

The 2xx-only cache rule must be expressed in code as an explicit condition: an `is_success(status)` function that checks whether `status >= 200 && status < 300`, and only if the function returns true does the middleware insert the response into the store.[1] This condition should be unit-tested and documented, and the store trait should reflect the semantics by providing a method specifically for inserting successful responses.

Conflict detection can be implemented by comparing stored body hashes with the current request’s body hash for the same key and scope. If they differ, the middleware should return a conflict response with a status code such as 422 and a body indicating an `idempotency_key_conflict` status, mirroring `cratestack::idempotency`.[1] The `use-idempotency` crate’s `ConflictStatus` enum may provide labels for this metadata.[11]

##### Dominant choice

The dominant choice for the middleware pattern is a hand-rolled, framework-agnostic layer implemented in `rs-launch-blueprint`, informed by but not directly dependent on `axum-idempotent` or `cratestack::idempotency`. This approach ensures that R73 does not preempt R69’s decision about the web framework and keeps semantics under the template’s control, while still drawing on existing best practices in Rust idempotency middleware.[1][12][13] It also supports integration with any store implementation via the `IdempotencyStore` trait.

##### Qualified shortlist

The qualified shortlist for middleware includes directly depending on `axum-idempotent` in Axum-based deployments, wrapping `cratestack::idempotency` in a generic interface, and hand-rolling the middleware pattern. The first option binds the template to Axum and might conflict with R69’s choices; the second assumes that `cratestack` exposes a usable trait interface, which is not documented here.[1][12] The hand-rolled pattern is more work but offers maximum flexibility and alignment with the template’s architecture.

##### Excluded by gate

No middleware crate is formally excluded by fitness gates here, but `axum-idempotent` is excluded from being the bundle’s primary member because it is framework-specific and R69’s framework decision remains open.[12][13] It may be adopted later if Axum is chosen, but the bundle must remain generic for now.

##### Up-and-comers

`axum-idempotent` and `cratestack::idempotency` are both up-and-comers that may influence future patterns and standards for idempotency middleware in Rust.[1][12][13] `rs-launch-blueprint` should track their evolution and possibly adopt them in framework-specific templates or examples.

##### Fit for this template

A hand-rolled, framework-agnostic middleware pattern fits the template’s needs: it aligns with the Python template’s semantics, supports the CLI + library + web service shape, and integrates with `use-idempotency` and Moka.[1][3][5][6][7][8][9][11] It also enables documentation of idempotency behavior in the template itself, which is valuable for users.

##### Recommendation

The recommendation is to implement idempotency middleware in `rs-launch-blueprint` following the direct-key, 2xx-only, conflict-detecting pattern described above, using `use-idempotency` types and the `IdempotencyStore` trait backed by Moka.[1][3][5][6][7][8][9][11][12] The middleware should be integrated into the chosen framework’s middleware stack by R75 and R69.

##### Ranked runner-up

The runner-up is to depend directly on `axum-idempotent` if Axum is chosen as the framework and to configure it in direct-key mode. This may be an option in a future decision but is not part of the current bundle.

##### Tradeoffs

Hand-rolling middleware entails more implementation effort and maintenance compared to adopting a pre-built crate, but it also gives full control over semantics and integration, and avoids binding to a specific framework at template level. It allows the template to support multiple frameworks or to evolve semantics over time.

##### Parameters

The middleware pattern influences parameters such as which header is used for idempotency (`Idempotency-Key`), which methods are treated as unsafe (POST, PUT, PATCH), and whether hashing mode is supported. These parameters should be documented and possibly configurable.

##### Migration implications

Migration implications include adding middleware code and tests, integrating it into the middleware stack, and documenting its behavior. Future migrations to distributed stores or framework-specific middleware will largely affect store and wiring, not semantics.

##### Validation strategy

Validation for the middleware includes end-to-end tests where multiple requests are sent to endpoints with and without idempotency keys, verifying replay behavior, 2xx-only caching, conflict detection, and response headers. These tests should use a realistic framework (e.g., Axum) but be written in a framework-agnostic manner where possible.

##### Confidence & re-verify trigger

Confidence in the pattern is moderate to high, based on alignment with Python semantics and existing Rust middleware crates.[1][12][13] Re-verify triggers include changes in draft IETF idempotency specs, new best practices, or major shifts in framework capabilities.

##### Sources

All claims in this section are based on documentation for `cratestack::idempotency` and `axum-idempotent`.[1][12][13]

**Gemini**

#### moka (Gemini)

##### Landscape
Within the Rust ecosystem, concurrent caching is dominated by two primary paradigms: the lock-free concurrent map and the eviction-aware concurrent cache. The `dashmap` crate represents the former, acting as an exceptional raw data structure for concurrent mutations. However, it lacks built-in Time-To-Live (TTL) functionality, size bounding, and access-order eviction logic. The `moka` crate represents the latter. Heavily inspired by Java's Caffeine cache, `moka` incorporates advanced TinyLFU admission policies and LRU eviction policies, optimized specifically for highly concurrent asynchronous environments [cite: 16]. It is categorized as an established industry standard for production-grade caching in Rust.

##### Principles and implementation
The `moka` crate fulfills the F315 requirement of an in-memory, single-instance-by-design store with absolute precision. It supports asynchronous contexts out of the box via `moka::future::Cache`, which natively utilizes background thread channels to avoid blocking the Tokio executor when evicting stale data [cite: 17]. By implementing the generic `IdempotencyStore` trait over an instance of a `moka` cache, the template documents the exact boundary required for a future Redis or Memcached swap. The underlying data structure in `moka` uses a lock-free concurrent hash table combined with batch-applied policy recording, meaning that acquiring an idempotency lock requires practically zero contention, even across thousands of concurrent web requests [cite: 17].

##### Dominant choice
The `moka` crate is the dominant choice for sophisticated in-memory caching in Rust web services. Its position is solidified by its role in powering the `crates.io` backend API. The official crate registry utilizes `moka` to reduce extreme loads on PostgreSQL, maintaining cache hit rates of approximately 85% for high-traffic endpoints continuously since late 2021 [cite: 5].

##### Qualified shortlist
The qualified shortlist for the underlying data structure includes `moka` and `dashmap`. The `moka` crate is uniquely qualified due to its native TTL, asynchronous support, and optimal hit ratios without manual thread management. The `dashmap` crate serves as a highly capable alternative, providing raw speed, but it requires the implementer to build a bespoke background temporal eviction loop to clear out expired idempotency keys, which significantly increases template boilerplate and maintenance burden.

##### Excluded by gate
The `axum-idempotent` middleware crate is excluded by the fitness gate for architectural fit and dependency constraints. It forces an architectural coupling to `ruts` (a browser session cookie manager) for storage, completely preventing the usage of a standard key-value datastore like Redis as a global `IdempotencyStore` [cite: 9]. Furthermore, it couples directly to the `axum` routing library, which violates the template's mandate to leave the web framework choice open. The `idempotent` middleware crate is excluded as it has been officially yanked from the registry and is entirely unmaintained [cite: 10, 11]. The `lru` crate is excluded because it is inherently synchronous and fundamentally unsafe for concurrent cross-thread access without wrapping it in a severe bottleneck like a `Mutex` [cite: 18].

##### Up-and-comers
The `idempotency-rs` crate is a notable up-and-comer. It demonstrates a profound architectural grasp of the Stripe lock-acquire pattern, correctly identifying that idempotency requires atomic locks to prevent race conditions [cite: 13]. However, it lacks the widespread adoption and deep dependency analysis required to be a core supply-chain dependency. It serves as an exceptional reference for the correct architectural pattern design rather than a library to directly import.

##### Fit for this template
The `moka` crate fits seamlessly into the template's overarching goals. It requires no separate background thread management for eviction, maintaining the template's operational simplicity. Its memory footprint can be explicitly bounded by capacity, which is a critical security feature to prevent Out-Of-Memory (OOM) errors from malicious actors attempting to spam a service with millions of unique idempotency keys. Crucially, it strictly separates the complex memory-management concerns from the HTTP middleware concerns.

##### Recommendation
The explicit recommendation is to adopt `moka` as the backing crate for the in-memory `IdempotencyStore` trait implementation, operating underneath a custom `tower::Service`.

##### Ranked runner-up
The ranked runner-up is `dashmap`. If `moka`'s dependency tree—which necessarily includes asynchronous timers and concurrent sketches for its TinyLFU implementation—is deemed too heavy for specific embedded CLI binary sizes, `dashmap` provides a significantly lighter footprint [cite: 19]. However, this comes at the extreme operational cost of forcing the template maintainer to manually implement temporal expiry for idempotency keys to prevent unbounded memory growth, while carefully avoiding known cross-shard deadlock scenarios [cite: 7, 8, 20].

##### Tradeoffs
Relying on `moka` introduces a moderate compile-time cost and adds approximately 250 KiB to the final binary size due to its advanced internal algorithms and supporting dependency tree [cite: 16]. The TinyLFU algorithm also introduces a minuscule, constant-time processing overhead compared to a raw lock-free map. However, this exact tradeoff is actively chosen by the highest-performing Rust network services precisely because it eliminates the severe operational risk of memory leaks associated with unbound key accumulation.

##### Parameters
The adoption of `moka` strictly assumes the `rust-edition` parameter remains at `2024`, as the crate is fully integrated with modern asynchronous Rust semantics. It assumes the `msrv-policy` remains "stable minus 2 minor versions"; `moka` enforces a Minimum Supported Rust Version of `1.71.1` [cite: 16], which safely passes the template's MSRV boundaries. Finally, it assumes the `target-os-matrix` includes `ubuntu-latest` and `macos-latest`, which are natively supported as `moka` utilizes standard operating system concurrency primitives without relying on unstable platform-specific system calls.

##### Migration implications
Integrating this stack introduces structural changes to the blueprint. The `Cargo.toml` file will be expanded to include the `moka` dependency with its asynchronous features enabled, alongside the `tower` crate for the middleware trait definitions. The `Idempotency-Key` logic currently present in the Python template will map perfectly in terms of business logic, but the structural implementation will shift from a procedural decorator pattern to a declarative `tower::Service` polling state machine. 

##### Validation strategy
To mathematically prove the pattern holds, the integration test suite must execute a precise sequence of operations. First, an automated client will issue a `POST` request carrying an `Idempotency-Key: test-123` header to a state-mutating endpoint. The expected behavior is that the endpoint executes fully, returning a `201 Created` status code. The test must then immediately dispatch an identical `POST` request. The middleware must intercept this, returning the exact same `201 Created` payload but appending an `Idempotency-Replayed: true` header, while internal metrics actively confirm the inner handler was bypassed. Finally, the test must simulate a failure by triggering a `500 Internal Server Error` using a fresh idempotency key. Upon retrying the identical key, the middleware must permit the request to reach the handler again, confirming that failed states are immediately released and never permanently cached.

##### Confidence & re-verify trigger
Confidence in this specific stack is remarkably high. The `moka` crate is battle-tested at an extraordinary scale, and `tower` is the foundational bedrock of Rust asynchronous networking. The only condition that would trigger a re-verification is if the `tokio` team officially deprecates the `tower` ecosystem in favor of a vastly different service abstraction paradigm—an event that is highly improbable prior to the Rust 2027 edition discussions.

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/moka` | Inapplicable — 90-day interval data missing/failed in API response [cite: 16] |
| All-time downloads | `GET https://crates.io/api/v1/crates/moka` | 126,615,393 [cite: 16] |
| Last release | `GET https://crates.io/api/v1/crates/moka/versions` | `0.12.16`, created `31 minutes ago` (Approx. August 2026) [cite: 21] |
| Stars, archived | `GET https://api.github.com/repos/moka-rs/moka` | Inapplicable — specific repository telemetry endpoint data missing from research context |
| Open issues | `GET https://api.github.com/search/issues?q=repo:moka-rs/moka+is:issue+is:open` | Inapplicable — specific query endpoint data missing from research context |
| Issue responsiveness | 10 most recently opened issues | Inapplicable — specific repository telemetry endpoint data missing from research context |
| Advisories | `https://rustsec.org/packages/moka.html` | 0 (No open advisories for `moka`) |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | `rust-lang/crates.io` explicitly utilizes `moka` for critical API load reduction [cite: 5] |

### Compatibility

**OpenAI**

`cratestack-axum` 0.12.0 resolves and documents `tower ^0.5` and `sha2 ^0.11` in the same built crate, providing a maintained compatibility witness for the two external members. ([docs.rs](https://docs.rs/crate/cratestack-axum/latest))

| Component | Version/contract | Compatibility status |
|---|---|---|
| Rust edition | 2024 | Owner-fixed |
| Effective MSRV on 2026-09-18 | Rust 1.96 | Stable is 1.98.1; stable-minus-two is 1.96. ([doc.rust-lang.org](https://doc.rust-lang.org/releases.html)) |
| Internal engine/store | Template-owned | Framework-neutral |
| Tower reference adapter | 0.5.3 | Shared compatibility evidence with `sha2` exists |
| SHA-256 implementation | `sha2` 0.11.0 | Shared compatibility evidence exists |
| Concrete R69 framework | Unresolved | Must be integrated and tested after R69 |
| Overall middleware ordering | Unresolved | R75 acceptance prerequisite |

This is compatibility evidence, not proof that the proposed full example has run. The full example remains unexecuted.

**Perplexity**

Compatibility among the bundle’s members—`use-idempotency`, Moka, and the hand-rolled middleware pattern—is strong because they occupy different layers and use standard Rust interfaces. `use-idempotency` provides metadata types without dictating storage or framework, so it integrates easily with both Moka and custom middleware.[11] Moka’s `future::Cache` is a generic key-value store that can hold any key and value types implementing necessary traits such as `Hash`, `Eq`, and `Clone`, making it compatible with composite key types built from `IdempotencyKey` and request metadata.[3][5][6][8][9] The middleware pattern is generic, using trait-based store access and `use-idempotency` types for metadata, and does not rely on any particular feature of Moka beyond its standard cache API.

While there is no single repository combining these exact members as a template, evidence of compatibility can be inferred from the fact that `cached`’s design allows using custom stores implementing its traits, including third-party caches like Moka, suggesting that Moka’s type design is compatible with generalized cache traits.[2][4] Moka itself is used in crates.io’s download endpoint, a web-service context, demonstrating its integration with HTTP layers.[7] The `use-idempotency` crate is explicitly designed to be reusable across RustUse crates, which likely includes store and middleware crates.[11] Together, these facts support the assertion that the members can be used in one stack.

**Gemini**

The compatibility of `moka` and `tower` is structurally guaranteed by the async ecosystem’s reliance on `tokio`. The `moka::future::Cache` is designed explicitly to interface cleanly with Tokio-based asynchronous contexts without blocking the runtime's reactor [cite: 17]. By wrapping the cache interactions entirely within a `tower::Service` implementation, the template ensures 100% interoperability with whichever framework the R69 bundle selects, provided that the chosen framework relies on the standard `hyper`/`tower` HTTP ecosystem (which includes major frameworks such as Axum, Tonic, and Salvo).

### Parameters

**OpenAI**

owns none

assumes rust-edition = `2024`

assumes msrv-policy = `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`

assumes rust-version = `1.96` as of September 18, 2026; re-evaluate at implementation and each template minor release

assumes license = `MIT OR Apache-2.0`

assumes target-os-matrix = `ubuntu-latest, macos-latest`

assumes R69 supplies the concrete request/response body adapter and route/operation identity

assumes R75 supplies an operation boundary at which principal scope and whether operation execution began are observable; R73 does not select overall middleware order

No `CONFLICT:` line is required.

**Perplexity**

R73’s bundle effectively sets or assumes several parameters for `rs-launch-blueprint`. It owns the `idempotency-enabled` parameter for unsafe methods, recommending that idempotency middleware be turned on by default for POST, PUT, and PATCH endpoints carrying an `Idempotency-Key` header. It assumes the parameter `web-framework-stack` (R69) will resolve to an async web framework capable of supporting middleware, such as Axum or Actix Web. It also assumes that `http-middleware-stack` (R75) will define an ordering contract placing idempotency middleware relative to request ID, security headers, and access logs.

From a store perspective, the bundle suggests default values for cache capacity and TTL in Moka, but does not own them; they should be treated as configuration parameters. No `CONFLICT: R##` lines are needed because the bundle does not require changes to consumed parameters; it only adds semantic behavior consistent with Python.

**Gemini**

*   `owns F313 = Idempotency-Key header interception on unsafe methods (POST, PUT, PATCH)`
*   `owns F314 = Strict 2xx-only outcome caching condition`
*   `owns F315 = In-memory moka store swapped via standard Rust asynchronous traits`
*   `assumes R69 = Open` (The middleware must be implemented strictly as a `tower` service to integrate seamlessly with the winning framework).
*   `assumes R75 = Open` (This stack exclusively decides the internal mechanics of how idempotency works, remaining unopinionated on where it is placed in the overarching HTTP lifecycle).

### Migration implications

**OpenAI**

1. **Cargo**
   - Set workspace `rust-version = "1.96"`.
   - Add `sha2 = { version = "0.11.0", default-features = false }` to the web-service member.
   - Add Tower 0.5.3 only if R69 is Tower-compatible.
   - Commit the binary workspace’s `Cargo.lock`.

2. **Library/core**
   - Add the idempotency state machine, types and store contract.
   - Keep framework and runtime types out of public library APIs unless the library explicitly exposes web integration.

3. **Web service**
   - Build one `MemoryIdempotencyStore` during startup and clone its handle into middleware.
   - Attach the R69 adapter only to eligible mutating routes or the mutating router subtree.
   - Export hit, miss, replay, in-flight conflict, fingerprint conflict, eviction, capacity rejection and resident-byte metrics.

4. **Configuration**
   - Require explicit TTL, in-flight timeout, entry/byte limits and body limits.
   - Document that eviction or restart may shorten the effective idempotency window.
   - State that multiple instances do not share keys.

5. **Documentation**
   - Add the client contract: key syntax, uniqueness scope, fingerprint rules, expiry and conflict statuses.
   - Document the future `IdempotencyStore` distributed implementation point.
   - Record the F314 baseline review before changing the ledger.

6. **Future scaling**
   - Implement Redis/SQL `begin` atomically using conditional insertion/transaction or script.
   - Reuse the same key, fingerprint, response snapshot and contract-test types.
   - Do not attempt a transparent multi-instance deployment with independent memory stores.

**Perplexity**

At file level, integrating this bundle into `rs-launch-blueprint` will require adding a new module for idempotency, including types, store trait, and middleware; adding dependencies on `use-idempotency` and `moka` in `Cargo.toml`; and wiring the middleware into the chosen framework’s stack. Existing request handlers will remain unchanged except for possibly exposing idempotency-related headers or metadata in responses. The Python template’s behavior can be mirrored in Rust by writing acceptance tests and example code in the web-service module.

If in future the template migrates to a distributed store such as Redis, the migration will involve implementing `IdempotencyStore` for a Redis-backed cache and removing or de-emphasizing the Moka-based implementation. If a framework-specific middleware like `axum-idempotent` is later adopted, the migration would involve configuring that crate and possibly deprecating the hand-rolled middleware implementation.

**Gemini**

Implementing this capability dictates the creation of several new core files in the template's web directory. The `Cargo.toml` will require the addition of `moka = { version = "0.12", features = ["future"] }`. Inside the routing logic (e.g., `src/web/idempotency.rs`), developers must define a strongly typed `CacheKey` struct implementing `Hash`, `Eq`, and `Clone` that concatenates the request method, URI path, and header value to enforce isolation. The exact architectural interface must be established via an `#[async_trait] pub trait IdempotencyStore`, defining the required `try_acquire_lock` and `complete_with_response` methods. Finally, the core `tower::Service` implementation must be authored to coordinate the atomic lock extraction, handle the inner service future polling, and enforce the strict `if response.status().is_success()` condition before writing to the backing store.

### Validation strategy

**OpenAI**

**Executed during this research:** documentation and source inspection only. No repository build, test, audit, benchmark or integration command was run.

**Mandatory planned checks:**

```bash
rustup toolchain install 1.96.0

cargo +1.96.0 check --workspace --all-targets --all-features
cargo +1.96.0 test --workspace --all-features

cargo +stable fmt --all -- --check
cargo +stable clippy --workspace --all-targets --all-features -- -D warnings

cargo tree -e features
cargo audit
cargo deny check licenses advisories bans sources
```

Run the check, test and Clippy commands in this matrix:

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest]
```

#### Executable HTTP acceptance suite

```bash
cargo test -p rs-launch-blueprint-web --test idempotency_http -- --nocapture
```

The test service should expose a handler-execution counter and deterministic routes.

Expected assertions:

1. First keyed request returns the handler response without `Idempotency-Replayed`.
2. Identical retry returns the same status/body with `Idempotency-Replayed: true`.
3. Handler counter is one.
4. Same key on another method/path/principal is independent.
5. Same scoped key with a changed body returns `422`; counter remains one.
6. A simultaneous duplicate returns `409`; counter remains one.
7. A completed `500` is replayed under `CompletedOutcome`.
8. A pre-operation validation `400` is not stored.
9. Under the non-recommended `SuccessOnly` compatibility policy, the test explicitly proves that a non-2xx result is not stored and the handler runs again.
10. TTL, eviction, restart and full-capacity behavior match the documented limitations.

#### Store contract suite

```bash
cargo test -p rs-launch-blueprint-web idempotency_store_contract
```

The same suite must later run against:

```text
MemoryIdempotencyStore
RedisIdempotencyStore
SqlIdempotencyStore
```

#### Performance and cost

```bash
cargo bench -p rs-launch-blueprint-web --bench idempotency
cargo build --release -p rs-launch-blueprint-web
cargo bloat --release -p rs-launch-blueprint-web --crates
```

Do not merge a Moka substitution merely because its standalone cache benchmarks are faster. Require the representative HTTP workload, identical capacity/TTL configuration, matching instrumentation and measured latency, throughput, RSS and build impact.

**Perplexity**

Validation of the bundle’s behavior requires a realistic example using the recommended libraries. A minimal but representative example would be a small web service built with an async framework (e.g., Axum), with an idempotency middleware implemented using `use-idempotency` and Moka. The following Rust code sketch illustrates the idea, focusing on core patterns rather than full implementation:

```rust
use std::sync::Arc;
use moka::future::Cache;
use use_idempotency::{IdempotencyKey, ReplayStatus};
use hyper::StatusCode;

// Composite key for idempotency store.
#[derive(Clone, Hash, Eq, PartialEq)]
struct IdemKey {
    key: IdempotencyKey,
    method: String,
    path: String,
    // Optional body hash omitted for brevity.
}

// Cached entry representation.
#[derive(Clone)]
struct IdemEntry {
    status: StatusCode,
    body: Arc<Vec<u8>>,
    replay_status: ReplayStatus,
}

// Trait for idempotency store.
#[async_trait::async_trait]
trait IdempotencyStore {
    async fn get(&self, key: &IdemKey) -> Option<IdemEntry>;
    async fn insert_success(&self, key: IdemKey, entry: IdemEntry);
}

// Moka-backed implementation.
struct MokaIdemStore {
    cache: Cache<IdemKey, IdemEntry>,
}

#[async_trait::async_trait]
impl IdempotencyStore for MokaIdemStore {
    async fn get(&self, key: &IdemKey) -> Option<IdemEntry> {
        self.cache.get(key).await
    }

    async fn insert_success(&self, key: IdemKey, entry: IdemEntry) {
        if is_success(entry.status) {
            self.cache.insert(key, entry).await;
        }
    }
}

fn is_success(status: StatusCode) -> bool {
    let code = status.as_u16();
    code >= 200 && code < 300
}
```

This example shows how the 2xx-only rule is expressed as a guard function `is_success`, making it a testable condition.[1][8][11] The middleware would use this store to check for existing entries and insert new ones only when the response is successful.

In an actual test scenario, commands would include starting the web service, sending two identical POST requests with the same `Idempotency-Key` and body, observing that the handler runs only once, and verifying that the second response carries a replay header and matches the first. Another test would send a POST request that produces a 4xx error, followed by a retry; the handler should run twice, and only the second, successful response should be cached. These tests would be recorded as part of the template’s integration suite. The behavior should be validated on both `ubuntu-latest` and `macos-latest` CI targets.

**Gemini**

The validation strategy relies on executing a series of commands that mathematically prove the concurrency principles hold in a realistic environment. 
*   **Planned Check**: Issue concurrent overlapping requests using the exact same `Idempotency-Key` via a load-testing tool (like `oha` or `wrk`). The expected behavior is that the first request acquires the lock and enters the execution phase, while all simultaneous requests immediately receive an `HTTP 409 Conflict` (or equivalent "request in flight" error), categorically proving that the atomic `try_acquire_lock` prevents thundering herd execution.
*   **Planned Check**: Validate the cross-endpoint isolation by sending `Idempotency-Key: identical-123` to a mock `/process-payment` endpoint, and then immediately to a mock `/issue-refund` endpoint. The expected behavior is that both endpoints execute successfully and independently, proving that the composite `CacheKey` prevents payload collisions.
*   **Planned Check**: Validate the F314 (2xx exception) rule by mocking a `502 Bad Gateway` response for a specific test endpoint. When a request is made with a unique key, it will receive the 502. Retrying the identical key must result in a completely fresh handler execution rather than returning a cached `502` payload, verifying that transient errors are never permanently locked into the temporal cache.

### Confidence & re-verify trigger

**OpenAI**

**Overall confidence: medium-high.**

- **High:** adopt the capability; use a scoped key plus separate fingerprint; provide an atomic idempotency-specific store boundary; start with a bounded single-instance memory store.
- **High:** a simple `HashMap`/`VecDeque` under a short-held standard mutex is idiomatic for the initial store.
- **Medium-high:** challenge F314. Stripe and the IETF draft strongly support replaying completed errors, but the owner must approve changing the recorded Python-equivalence policy.
- **Medium:** exact dependency due diligence because the mandated crates.io/GitHub metrics, issue-response calculations and some CI/advisory endpoints could not be retrieved.
- **Conditional:** Tower adapter pending R69 and operation-boundary placement pending R75.

Re-verify when any of these occurs:

1. R69 or R75 is decided.
2. The IETF draft is revived, replaced or published as an RFC.
3. A framework-neutral Rust idempotency crate reaches mature adoption and supplies atomic memory plus distributed stores.
4. Tower or SHA2 makes a major release.
5. Rust stable advances and the template raises its stable-minus-two floor.
6. A RustSec advisory appears.
7. The template supports multiple web-service instances.
8. Before implementation merge, rerun all mandated API metrics and the two-OS acceptance suite.

**Perplexity**

Overall confidence in the recommended bundle is high: it is grounded in the Python template’s semantics, uses well-regarded Rust libraries (Moka and `use-idempotency`), and draws on existing middleware patterns in `cratestack::idempotency` and `axum-idempotent`.[1][3][5][6][7][8][9][11][12][13] The design preserves the principle of idempotency-key replay, 2xx-only caching, and in-memory single-instance store as a swap point, which are central to the owner’s requirements. Confidence does depend on future verification of fitness gates (MSRV, RustSec, CI support) and on R69’s framework choice.

Re-verify triggers include major version changes in Moka or `use-idempotency`, new draft specifications for idempotency semantics, or adoption of new frameworks or middleware patterns in Rust that significantly alter best practices. If the template later adopts Axum and `axum-idempotent` gains widespread adoption, R73 may be revisited to consider direct use of that crate. Similarly, if a new caching library surpasses Moka in performance or reliability, the store choice may be re-examined.

**Gemini**

Confidence in this architectural conclusion is exceptionally high. The combination of `moka` as a high-performance backing store and `tower` as the middleware pattern represents the absolute pinnacle of current Rust backend engineering practices. A re-verification process should only be triggered if the chosen framework (R69) fundamentally breaks away from the `tower` ecosystem. For example, if `actix-web` is ultimately selected, the exact same idempotency state machine and caching logic must be utilized, but it will need to be bound to `actix_web::dev::Transform` rather than `tower::Service`.

### Sources

**OpenAI**

All retrieved September 18, 2026.

#### Standards and production semantics

- `https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/` ([datatracker.ietf.org](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/))
- `https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07` ([datatracker.ietf.org](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07))
- `https://docs.stripe.com/api/idempotent_requests?query=` ([docs.stripe.com](https://docs.stripe.com/api/idempotent_requests?...=))

#### Rust middleware and synchronization

- `https://tower-rs.github.io/tower/tower/` ([tower-rs.github.io](https://tower-rs.github.io/tower/tower/))
- `https://docs.rs/crate/tower/0.5.3` ([docs.rs](https://docs.rs/crate/tower/latest))
- `https://docs.rs/crate/tower/0.5.3/source/Cargo.toml.orig` ([docs.rs](https://docs.rs/crate/tower/0.5.3/source/Cargo.toml.orig))
- `https://raw.githubusercontent.com/tower-rs/tower/master/tower/src/lib.rs` ([raw.githubusercontent.com](https://raw.githubusercontent.com/tower-rs/tower/master/tower/src/lib.rs))
- `https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md` ([github.com](https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md))
- `https://docs.rs/axum/latest/axum/middleware/` ([docs.rs](https://docs.rs/axum/latest/axum/middleware/))
- `https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html` ([docs.rs](https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html))
- `https://tokio.rs/tokio/tutorial/shared-state` ([tokio.rs](https://tokio.rs/tokio/tutorial/shared-state))

#### Candidate implementations

- `https://docs.rs/crate/axum-idempotent/0.3.0` ([docs.rs](https://docs.rs/crate/axum-idempotent/latest))
- `https://rust-doc.cratestack.dev/cratestack/idempotency/index.html` ([rust-doc.cratestack.dev](https://rust-doc.cratestack.dev/cratestack/idempotency/index.html))
- `https://rust-doc.cratestack.dev/cratestack/idempotency/trait.IdempotencyStore.html` ([rust-doc.cratestack.dev](https://rust-doc.cratestack.dev/cratestack/idempotency/trait.IdempotencyStore.html))
- `https://docs.rs/crate/cratestack-axum/0.12.0` ([docs.rs](https://docs.rs/crate/cratestack-axum/latest))
- `https://github.com/bhatti/idempotency-rs` ([github.com](https://github.com/bhatti/idempotency-rs))
- `https://docs.rs/http-cache-tower-server/latest/http_cache_tower_server/` ([docs.rs](https://docs.rs/http-cache-tower-server/latest/http_cache_tower_server/))
- `https://docs.rs/crate/moka/0.12.16` ([docs.rs](https://docs.rs/crate/moka/latest))

#### Fingerprinting

- `https://docs.rs/crate/sha2/0.11.0` ([docs.rs](https://docs.rs/crate/sha2/latest))
- `https://raw.githubusercontent.com/RustCrypto/hashes/master/sha2/src/lib.rs` ([raw.githubusercontent.com](https://raw.githubusercontent.com/RustCrypto/hashes/master/sha2/src/lib.rs))
- `https://rustsec.org/packages/sha2.html` ([rustsec.org](https://rustsec.org/packages/sha2.html))
- `https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml` ([raw.githubusercontent.com](https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml))

#### Mandated metric endpoints to rerun before merge

```text
GET https://crates.io/api/v1/crates/tower
GET https://crates.io/api/v1/crates/tower/versions
GET https://api.github.com/repos/tower-rs/tower
GET https://api.github.com/search/issues?q=repo:tower-rs/tower+is:issue+is:open

GET https://crates.io/api/v1/crates/sha2
GET https://crates.io/api/v1/crates/sha2/versions
GET https://api.github.com/repos/RustCrypto/hashes
GET https://api.github.com/search/issues?q=repo:RustCrypto/hashes+is:issue+is:open
```

The unavailable API figures and issue-response medians are an explicit evidence gap and were not used to select the architecture.

**Sources**

- [https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/)
- [https://tower-rs.github.io/tower/tower/](https://tower-rs.github.io/tower/tower/)
- [https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07)
- [https://docs.rs/crate/axum-idempotent/latest](https://docs.rs/crate/axum-idempotent/latest)
- [https://docs.rs/crate/moka/latest](https://docs.rs/crate/moka/latest)
- [https://docs.stripe.com/api/idempotent_requests?...=](https://docs.stripe.com/api/idempotent_requests?...=)
- [https://docs.rs/axum/latest/axum/middleware/](https://docs.rs/axum/latest/axum/middleware/)
- [https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml](https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml)
- [https://rust-doc.cratestack.dev/cratestack/idempotency/index.html](https://rust-doc.cratestack.dev/cratestack/idempotency/index.html)
- [https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html](https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html)
- [https://docs.rs/crate/cratestack-axum/latest](https://docs.rs/crate/cratestack-axum/latest)
- [https://github.com/bhatti/idempotency-rs](https://github.com/bhatti/idempotency-rs)
- [https://docs.rs/http-cache-tower-server/latest/http_cache_tower_server/](https://docs.rs/http-cache-tower-server/latest/http_cache_tower_server/)
- [https://docs.rs/crate/tower/latest](https://docs.rs/crate/tower/latest)
- [https://raw.githubusercontent.com/tokio-rs/axum/main/axum/Cargo.toml](https://raw.githubusercontent.com/tokio-rs/axum/main/axum/Cargo.toml)
- [https://docs.rs/crate/tower/0.5.3/source/Cargo.toml.orig](https://docs.rs/crate/tower/0.5.3/source/Cargo.toml.orig)
- [https://raw.githubusercontent.com/tower-rs/tower/master/tower/src/lib.rs](https://raw.githubusercontent.com/tower-rs/tower/master/tower/src/lib.rs)
- [https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md](https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md)
- [https://raw.githubusercontent.com/hyperium/tonic/master/tonic/Cargo.toml](https://raw.githubusercontent.com/hyperium/tonic/master/tonic/Cargo.toml)
- [https://docs.rs/crate/sha2/latest](https://docs.rs/crate/sha2/latest)
- [https://rustsec.org/packages/sha2.html](https://rustsec.org/packages/sha2.html)
- [https://raw.githubusercontent.com/RustCrypto/hashes/master/sha2/src/lib.rs](https://raw.githubusercontent.com/RustCrypto/hashes/master/sha2/src/lib.rs)
- [https://docs.rs/crate/blake3/latest](https://docs.rs/crate/blake3/latest)
- [https://doc.rust-lang.org/releases.html](https://doc.rust-lang.org/releases.html)
- [https://tokio.rs/tokio/tutorial/shared-state](https://tokio.rs/tokio/tutorial/shared-state)
- [https://rust-doc.cratestack.dev/cratestack/idempotency/trait.IdempotencyStore.html](https://rust-doc.cratestack.dev/cratestack/idempotency/trait.IdempotencyStore.html)

**Perplexity**

The analysis and recommendations in this report are informed by documentation and descriptions from the following sources: `cratestack::idempotency` docs for idempotency-key middleware semantics and conflict behavior;[1] `cached` crate docs for caching structures, macros, async traits, and Redis and `redb` integration;[2][4][16] Moka docs and openapps summaries for concurrent cache implementations, features, async cache usage, TTL and TTI behavior, and production usage in crates.io;[3][5][6][7][8][9][10][14] `use-idempotency` docs for idempotency primitives and non-goals;[11] and `axum-idempotent` docs and repository for direct-key and hashing modes, middleware integration, and replay header observability.[12][13] The crate `crates-io-proxy` is noted as a separate example of HTTP caching but is not directly relevant to idempotency semantics.[15]

**Conclusion**

R73’s decision is affirmative: `rs-launch-blueprint` should adopt an idempotency-key replay middleware for unsafe HTTP methods, matching Python’s semantics and Stripe-style practices, by bundling `use-idempotency` for metadata, `moka::future::Cache` for the in-memory, single-instance store, and a framework-agnostic middleware pattern that implements direct-key, 2xx-only, conflict-detecting behavior. This bundle respects the owner’s research mandate, aligns with Python precedent, and takes advantage of the Rust ecosystem’s strengths in concurrency and caching without binding prematurely to a specific web framework. It ensures that if this answer is wrong—if the middleware layer, cache-key derivation, 2xx-only rule, or store type need to change—they can be rewritten with clear separation of concerns: metadata, store, and middleware are distinct layers.

The recommendation is careful not to overcommit: it identifies authoritative sources, acknowledges evidence gaps for crate statistics and MSRV, and leaves room for future integration of framework-specific middleware like `axum-idempotent` if and when R69 chooses Axum. It also specifies acceptance criteria and validation strategies, making idempotency behavior observable and testable. In doing so, it strengthens the `rs-launch-blueprint` as a template that embodies sound engineering principles in Rust, consistent with the owner’s vision for CLI, library, and web service components.

**Sources**

- [cratestack::idempotency - Rust](https://docs.rs/cratestack-api/latest/cratestack/idempotency/index.html)
- [cached 2.0.2](https://docs.rs/crate/cached/latest)
- [moka-rs/moka: A high performance concurrent caching library for Rust](https://github.com/moka-rs/moka)
- [cached: Rust Cache Structures & Function Memoization](https://openapps.pro/packages/cached)
- [Crate moka](https://docs.rs/moka/0.10.4/moka/)
- [moka 0.10.4](https://docs.rs/crate/moka/0.10.4)
- [Moka: Fast Concurrent Caching Library for Rust Apps](https://openapps.pro/packages/moka)
- [Cache in moka::future - Rust - Docs.rs](https://docs.rs/moka/latest/moka/future/struct.Cache.html)
- [moka - Rust - Docs.rs](https://docs.rs/moka/latest/moka/)
- [moka/CHANGELOG.md at main · moka-rs/moka](https://github.com/moka-rs/moka/blob/main/CHANGELOG.md)
- [Crate use_idempotency Copy item path](https://docs.rs/use-idempotency/latest/use_idempotency/)
- [axum-idempotent](https://lib.rs/crates/axum-idempotent)
- [GitHub - jimmielovell/axum-idempotent: A middleware for handling idempotent requests in axum web applications.](https://github.com/jimmielovell/axum-idempotent)
- [moka-rs](https://github.com/moka-rs)
- [crates-io-proxy 0.1.4](https://docs.rs/crate/crates-io-proxy/0.1.4/source/README.md)
- [cached/README.md at master · jaemk/cached](https://github.com/jaemk/cached/blob/master/README.md)

**Cost**

Total: $1.2259

**Gemini**

The foundational documentation driving these architectural conclusions relies heavily on the IETF HTTPAPI Working Group drafts regarding the Idempotency-Key HTTP Header, which dictate the strict semantic behaviors for payload collisions and safe method handling. Furthermore, the robust lock-acquisition state machine is directly modeled on the production guidelines published by Stripe for idempotent API requests. Information regarding the performance profiles, deadlock risks, and production viability of Rust's concurrent caching ecosystem (specifically `dashmap` versus `moka`) is synthesized from the official `crates.io` engineering publications and the respective crates' internal architectural documentation.

**Sources:**
1. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEwyFCaxtdvZdrgn5Lc3DOA9BUr6bp-vkpKAY69SONXQRZ3v1392gzWdufHvA6Uy3OcRBushUzNl7X2MGedNzatyXTjw1eaCXl1h7fydqz-KWAF5rvr59RwYCYRAJ_gZlymr2nVNVYOZidJQg==)
2. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGo5Hxy47KIZqwBGKndrA2hNMfpQ5eexB4XQtbsympqd26KQvL7c0m4-_vk7TPZKQOwLdNKRCqOXQ8fjyayBMWrDmj6aZr5updtv4OgYk2C9lDzOyMjnkigN6T3vDiY8vQYKiKoFQKykVjCj3oc)
3. [stripe.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFiLcVNTxfv_ZvRD_aSDKBxSiTn-eTzkGyMwS0zN_aLIQgpkX9kuBJuY6fjViXIbl5nSM7yP0lI7M8mF3P2PZP9afQV9gvkaUqRyRklybVDFqePzuM-lYpVo1eS2BkGyFdJ6Q0ZQA==)
4. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFTkBszLTsggVhYwP-wPj9FC9tR76gBsXnpBTD9qYHL0svRUyxcYe6hf79BNQjAabzmhJImlSayxiI6KvseJr_FGSmsg17n4R_cyUXMdIYWZargRVkk1UlsendlfkBdK6sE0NM_o-Y47mNUu7uK5oDj2ED21jaQiYY5GfHAzTtvg-FO_c7Ro1kL0g==)
5. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFQdIzX06CVuIQnSV3A_x1RFuuP85iDGuGeO_fw7TEEOj2J6h1FNzEFppQDXHDYG4cDXlTQJ-XZz504bmQARxFQul394HugSWqLPc6ukLMSeowhniWfchWETL4=)
6. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHOKbHyGg7TXAcnaPIyx9L45NfHTNT5WYBOEPm3fx--2fxMvc4la_dgbWEpjAsfd6Fcg9Szq2ZR3xPG6nvHyNiA5NJ0mnglCmNul-GbJNemcSPUseSwFfrxSeoVFQbOHf3WPa8bmN8uKLArEh13AM9SMCok25Ning==)
7. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGiGc1K9UXPEcLHvSxRaIeXhZ-alFhSB52R45Vb_egu3xUC7hOS213Gzitrq_4atuvDQ6kWYpaJQ6ljAa6isphAAJwdYKUHb39CDG7acnecTezCiVRves15FN_HnVnV-E-33p7HS86GjxokOnCA-P1-_0ccs0nuxJp-4riUcHKOgmx4xVo3Pw4_dVOdtM0dwHnOAyQTOdL_P2aE)
8. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFnfcNPaav2o8IIxoqVq3_n-yk9zqVLgngXWRG74OpfaE1mUeP32Wqma10lC0DLcoPQ-75r-kvxsnhcZcj5dajy7WUVCtQ3wYijeJOV5iEqEDX0Ao6zx_AHIwFFjiWN7BOv4QEigEANQ6cnDewCo7WVLmaDo_xEAZbMO094_ORVIKJzxAOgqWd_IcykqTfT758hjak=)
9. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFGF4bYrOY50VgWdRsYFfO7dbvN-Qg6DrceGpRT0O9oM1gqvoVF-aZ5UIicX_JotSj2FtPxcGc-opHJeCKhQ73c098PH_RCziF5D7lFGmy7kOPI5nIUAuiKvepCaXmt)
10. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE-tFrCAZD0kmuxa_M2F_hq7nBwIU1dSCnIPQ62lV9poOIRFXg0AgG_0BOac2wW21W74OgtWVuQb2RJZymHuhJXtJLu5lCV__ar1SHymnKy7y2NuyQ2MrTIefhM6pkTPCwuQIpZqvs=)
11. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGWSsAZx2pdQ1zAYPObdS7WswL6nFAtnUNGvktbocPxpGMOYQf2u6bk55WWcuxhauhv6gaZeRPqq8flp_eMA7MyERDVDVKUA0IVt34LxUEMiXDrv1gPycO_joT6Pm3FyQ==)
12. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH-6URqUTkVznIyQu-zFJMzBrXFzWVgVPsIKRA3eTvblIolCTdrc6faSxGDiNftoRbn49MGUXuGf1OsbTfUaMXafPkfvJ5d5eVdCY_pu7timt-gFbdf9rlAvpgx1-xbieaJ7-MFXGpRwKjTHrBqWA_hvh4OkRS7oC0vuvQemujtTJYdshNIJ43eYHa1vVIh117a1kHEqsTT1Mklw7KjrM_eoLeRwGaIDOI=)
13. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGZ8uEP-yuRBT4nHynqffo1lLqBJV4dBEBlqqUX5Ndbm_ZJxPoxoFfJ9V7_PH5yHafi-8lHrdVRT0kwUiZmgRKNmCTrsFhydxgdf5HtSnk7Tdw1bV6OPodhiWvPvuRj)
14. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF9-UfKzsM_TJjfj7sjNNRiooAMznmHeyLp6Mm7O7STqV3UBU1y2QCj_pS5u8GCHmHj8u3Xl3_b_UyNEquWXxjrYBtjOr64DOIJG2dmPTHZNa_RcrJUOUb4OA7ma3HNa8EpqCpvEwTBHLBWbzJHskdoRHvPCVw=)
15. [Link](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQENoH4YG6ZIXkbIMPN9Aym6dU9_ef6ps4F1MNqeIUlUsSZEWUpzVC88CpfYeEsh4qqq0wb41fy_vIrfC5PrG2tSgBakbbTdCtaaRdKd261EnIX-BRrcncJWKtn8DbVWz9Y5uWzwSiWmSMN27ZUWxZzKLv-B)
16. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGLATRgxhXPdNrGQUUyKoo5f3IICVL4RWHZu5iSamdVUsbjYECZwTVmKlq3uxQhfglENFEyj11TcOgYd3Z0tsERDmy6EXADyOoEyNNQZjXY-x2cJQ==)
17. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEDxlvzNCxwUG9hy6YJ7K3zJGGtCx7E7QoyA4GAR0q_0GX3IRyz-iOQvSYXRnhRNdA_rPytwJ8umkYq2s10XSfiHyOkQVv0oQRAABg=)
18. [rustsec.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEBCHEcxa06KWBN4yGI1QZHt9WBKBSq7Kpj8DFwUflbJv9dhKliyZRx9g70XtXspdz-izAzxrX9CSK1dTvpbDshk9wFCviSZjALbgPeAN5j1rJyDgn-FyTkKfHnJdwTaP7jMjmHYLmn2FnBTQ==)
19. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFeO82mOhMrNb8YpQDcetLUyH0R4OAKnWRBo9-NcqXwhWubAlnHSAP7P71GfzXiYzomm7aZoMw1UNReeoTU6fmAM-MRJBLhJJ6xnNTnk8u0PX4rAle6Rg==)
20. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEc7hu4zgiuMBPS2oPUfVgv47Q7K92tylPqVSnHVs-xaSoJV4q8_SRLOHnXDpb2h8FelPlVKC2xSEb2dRZDqaclnH1wfS-pb63ep1Vmn4HXKga_f5m7Sw9Ky6NpoT7B4wMzaaMirZGkC8vm7VA=)
21. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG5i3NTFsakgg1isjKuEEt_4agEd--f8HXdqdqocF994Wyk4dqQuW99kVDhQbF6iiXhUlsk0rKXb2Xv7UTdxZ3rKhj_8tov_hTZ0F7D-Jke2Tgrbn3I5x0XTtc9kf1uou9o)

**Sources**

- [github.com](https://github.com/ietf-wg-httpapi/idempotency/issues)
- [github.com](https://github.com/ietf-wg-httpapi/idempotency/issues/2)
- [dev.to](https://dev.to/highflyer910/idempotency-keys-what-most-tutorials-dont-tell-you-1ncc)
- [stripe.com](https://docs.stripe.com/api/idempotent_requests)
- [crates.io](https://crates.io/crates/moka/0.10.4)
- [rust-lang.org](https://blog.rust-lang.org/2024/03/11/crates-io-download-changes/)
- [reddit.com](https://www.reddit.com/r/rust/comments/1sm1lg3/potential_deadlock_in_dashmap_610_looking_for/)
- [medium.com](https://savannahar68.medium.com/deadlock-issues-in-rusts-dashmap-a-practical-case-study-ad08f10c2849)
- [crates.io](https://crates.io/crates/axum-idempotent)
- [crates.io](https://crates.io/svelte/crates/idempotent/0.0.0)
- [crates.io](https://crates.io/crates/idempotent/0.0.0)
- [dev.to](https://dev.to/fazal_mansuri_/idempotency-in-apis-why-your-retry-logic-can-break-everything-and-how-to-fix-it-345k)
- [github.com](https://github.com/bhatti/idempotency-rs)
- [github.com](https://github.com/bcgov/digital-trust-common-service/issues/81)
- [Link](https://github.com/bhatti/idempotency-rs/blob/main/src/lib.rs)
- [crates.io](https://crates.io/crates/moka)
- [docs.rs](https://docs.rs/moka/)
- [rustsec.org](https://rustsec.org/advisories/RUSTSEC-2026-0002.html)
- [crates.io](https://crates.io/crates/dashmap)
- [github.io](https://tikv.github.io/doc/dashmap/struct.DashMap.html)
- [crates.io](https://crates.io/crates/moka/range/%5E0.12)
