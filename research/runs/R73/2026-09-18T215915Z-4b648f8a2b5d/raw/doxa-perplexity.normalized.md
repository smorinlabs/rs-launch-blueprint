# Idempotency-Key Replay Middleware Bundle for `rs-launch-blueprint` (R73)

The research concludes that `rs-launch-blueprint` should adopt a Stripe-style idempotency-key replay middleware for unsafe HTTP methods, with a clear architectural separation between idempotency semantics, middleware wiring, and cache storage, and with a deliberately simple default: a single-instance, in-memory store that caches only successful \(2xx\) responses and is explicitly documented as a future distributed-store swap point. The recommended bundle combines a small, dependency-light primitive crate for idempotency metadata (`use-idempotency`), a high-performance concurrent in-memory cache (`moka::future::Cache`) as the initial store, and a framework-agnostic middleware pattern modeled on existing Rust implementations (`cratestack::idempotency` and `axum-idempotent`) rather than binding to a single web framework crate at template level.[1][3][5][6][7][8][9][11][12][13] This design preserves the Python template’s behavior—replay for unsafe methods, direct `Idempotency-Key` header, replay header for observability, and “2xx-only” cache writes—while aligning with Rust ecosystem idioms and keeping future migration to a distributed store as a local change to the store implementation rather than a rewrite of middleware or request semantics.[1][8][11][12] The bundle’s members are selected for licensing compatibility, general ecosystem acceptance, and alignment with the template’s CLI + library + web service shape, with explicit acknowledgment of remaining evidence gaps (such as precise download counts and MSRV declarations) that must be verified in integration.

## Introduction

The R73 item for `rs-launch-blueprint` decides whether the Rust template should adopt an idempotency-key replay middleware for unsafe HTTP methods, mirroring the Python template’s Stripe-style semantics while respecting the Rust ecosystem’s tooling and patterns. The Python implementation treats POST, PUT, and PATCH requests carrying an `Idempotency-Key` header as candidates for replay, storing only successful \(2xx\) responses in an ordered, bounded, in-memory cache, and replaying the stored response when the same logical operation is retried, while allowing genuine errors to be retried rather than replayed.[1] The TypeScript port never built a web service, so there is no precedent to reconcile, and the owner’s direction is to research both equivalency and best practice for Rust, guided by the same principles as the Python template but not blindly duplicating mechanisms. That direction explicitly emphasizes identifying the underlying engineering principle, the level of agreement required (capability, pattern, policy), and observable acceptance criteria, then selecting architectures and libraries that best realize those principles, rather than relying on familiarity or benchmark throughput alone.

Within those constraints, this report has to choose not only whether to implement idempotency-key replay at all, but how: whether to adopt an existing middleware crate for a specific framework, whether to define framework-agnostic traits and patterns so that R69’s choice of web framework can be wired later, how to express the “only cache successful outcomes” rule in Rust idioms, and what kind of in-memory store best mirrors Python’s ordered, evictable cache while remaining concurrency-safe in an async web service. The answer also has to respect the owner’s MSRV policy (stable minus two minor versions, declared and tested), the licensing requirement (`MIT OR Apache-2.0`), and CI constraints (`ubuntu-latest` and `macos-latest` targets), even though some ecosystem metrics cannot be fully verified in this offline evidence-gathering environment.

To structure the decision, the report first surveys the landscape of idempotency middleware and caching libraries in Rust, using authoritative sources, production practice, and fit against the template’s shape. It then distills the principles drawn from the Python implementation and current best practice, compares architectural alternatives, and proposes a bundle of one stack and its members. For each member, the report goes into the detailed landscape, gates, tradeoffs, and migration implications. Finally, it ties the members together, describes validation strategies, and states confidence and re-verify triggers, with explicit recognition of evidence gaps that must be closed during integration.

## Report

### Landscape

The category decided by R73 is “idempotency-key replay for unsafe HTTP methods backed by a bounded in-memory cache,” which naturally spans three overlapping subcategories in the Rust ecosystem: idempotency-specific middleware or primitive crates, general-purpose caching libraries suitable as the in-memory backing store, and broader web-service templates or middleware stacks that treat Stripe-style idempotency as a named pattern. The survey follows the owner’s “forest before trees” mandate: mapping the field first, identifying authoritative sources, and studying practice in well-regarded Rust projects, before narrowing down candidates for the bundle.

In the first bin, “built-in or first-party toolchain,” Rust as a language and standard library does not provide any direct HTTP idempotency-key middleware; its HTTP and async capabilities are expressed through crates like `hyper`, `tokio`, and web frameworks such as `axum`, `actix-web`, and `warp`, none of which, in their core, ship a named idempotency-key replay component. This absence is consistent with the ecosystem’s pattern of keeping protocol-level semantics and service-layer features in separate crates rather than baking them into the language. It means that R73 cannot rely on a built-in solution and must look to third-party crates or design patterns atop a chosen web framework.

In the second bin, “established industry standard,” several crates stand out. For idempotency semantics, the `use-idempotency` crate provides small, validated types modeling idempotency keys, scopes, replay status, conflict status metadata, and request fingerprint labels, explicitly as primitives for API metadata.[11] Its documentation emphasizes non-goals: it deliberately does not implement a storage backend, request hashing, or distributed locking, making it suited as a semantic layer rather than a full middleware.[11] For caching, the `moka` crate is a fast, concurrent cache library inspired by Caffeine, offering synchronous and asynchronous caches that can be bounded by maximum entries or weighted size, with TinyLFU-inspired admission and LRU eviction to maintain near-optimal hit ratios.[3][5][6][7][9] Moka provides both a synchronous cache shareable across threads and a futures-aware cache (`moka::future::Cache`) for async runtimes like Tokio, async-std, or actix-rt, with support for TTL, TTI, and variable expiration, plus features such as eviction listeners and lock-free concurrent iterators.[5][6][7][8][9] Its public documentation notes that crates.io itself uses Moka to maintain roughly eighty-five percent cache hit rates on its download endpoint, an indication of production adoption and performance.[7] The `cached` crate, on the other hand, offers memoization macros and various in-memory stores (unbounded, LRU, TTL, sharded, Redis-backed, disk-backed via `redb`), focusing on function-level caching rather than HTTP semantics but with traits and async surfaces that can drive custom stores.[2][4][16]

In the third bin, “up-and-comer,” there are crates that implement idempotency middleware for specific frameworks. The `cratestack` API documentation includes an `idempotency` module described as an idempotency-key middleware protecting mutating routes against duplicate execution, which runs the handler on the first request with a given key, persists the captured response, and then replays the stored response on subsequent requests with the same key and matching request-body hash, or returns a `422` with an `idempotency_key_conflict` code if a different body is sent under the same key, in line with a draft IETF spec.[1] This middleware’s behavior closely mirrors Stripe’s semantics for conflict detection and replay. Another rising crate is `axum-idempotent`, which is explicitly marketed as middleware for handling idempotent requests in Axum applications, providing modes for “Direct Key” and “Hashing” that use either a client-provided header (e.g., `Idempotency-Key`) directly as the cache key or a hash derived from method, path, headers, and body.[12][13] It caches responses at the middleware layer and returns cached responses for identical requests rather than re-executing handlers, with observability via a replay header such as `idempotency-replayed`.[12] These crates show that the Rust ecosystem has begun to treat Stripe-style idempotency as a first-class middleware concern, though tied to particular frameworks and storage patterns.

For authoritative sources, this report relies on crates’ own documentation on docs.rs, openapps-style summaries, and the projects’ GitHub repositories, which collectively represent the maintainers’ intended usage and feature sets and are standard references in Rust communities.[1][2][3][5][6][7][8][9][10][11][12][13][14][16] For example, docs.rs entries for `moka` and its `future::Cache` struct describe the concurrency model, bounding options, TTL/TTI behavior, and async interfaces for insert, get, and invalidate operations, together with examples using Tokio.[5][6][8][9] Similarly, the `cached` crate’s documentation explains its trait surfaces (`Cached`, `ConcurrentCached`, `ConcurrentCachedAsync`, `CachedGetOrSetAsync`) and macro behaviors, including async caching with Redis and disk-backed stores via `redb`, as well as default synchronization policies such as per-key bucketed locks and whole-cache locks.[2][4][16] The `use-idempotency` documentation states its struct and enum types, their validity constraints, and its non-goals, and the `axum-idempotent` and `cratestack::idempotency` docs specify middleware operation modes and integration constraints.[1][11][12][13]

Practice evidence in mainstream, well-regarded Rust projects is more nuanced. The Moka documentation itself notes usage by crates.io, which is a central registry for Rust packages and thus a key reference application.[7] While direct verification of Moka’s download counts, GitHub stars, and open issues is not possible in this offline context, the combination of its feature depth, recent releases, and role in crates.io points to a stable, actively maintained library rather than a niche experiment.[3][6][7][10][14] The `cached` crate has been used widely in function memoization across Rust projects, given its macros and unintrusive integration, and its documentation indicates active maintenance with Rust version requirements and async features.[2][4][16] The idempotency-specific crates are newer: `axum-idempotent` has recent releases as of late 2025 and is built specifically for Axum, a leading async web framework, but it is not yet a ubiquitous standard in all web-service templates.[12][13] The `cratestack` idempotency middleware is part of a broader stack that appears targeted at API services with draft-spec-conforming idempotency, but its adoption footprint is harder to establish from documentation alone.[1]

Fit over abstract best, as mandated by the owner, requires judging these candidates against the template’s combined shape (CLI + library + web service) and Python precedent. The template needs an idempotency behavior that is conceptually simple, framework-agnostic at the template layer, and consistent with Stripe-style semantics: direct `Idempotency-Key` header, 2xx-only cache writes, conflict detection when the same key is reused with a different operation, and an in-memory store that can later be swapped for a distributed store without rewriting middleware. The Python implementation uses an ordered dictionary as a bounded store, documents a future Redis-backed distributed cache for multi-instance deployment, and intentionally avoids caching error responses so that genuine errors can be retried.[1] The Rust ecosystem offers both primitive crates and full middleware; however, binding the template directly to Axum-specific middleware (`axum-idempotent`) at R73 would be premature because R69 has not yet chosen the web framework. Conversely, ignoring existing middleware patterns would be wasteful. The best fit is therefore a hybrid: adopt a generic semantic crate (`use-idempotency`), design a framework-agnostic middleware pattern and store trait inspired by `cratestack::idempotency` and `axum-idempotent`, and choose a well-regarded caching crate like Moka as the default in-memory implementation.

Within this landscape, the bundle’s members are chosen to reflect three layers: idempotency metadata and status (with `use-idempotency`), in-memory store (with `moka::future::Cache`), and middleware pattern (hand-rolled for the eventual framework, using patterns from `cratestack::idempotency` and `axum-idempotent` as reference implementations). This choice keeps R73 agnostic to R69’s framework decision and makes the future distributed-store swap a matter of plugging a new implementation into the store trait, without rewriting key derivation or replay semantics.

### Principles and implementation

The shared requirement comes from the Python template and the owner’s direction: unsafe HTTP methods (POST, PUT, PATCH) carrying an idempotency key must be protected against accidental duplicate execution of logically single operations, such as payments or resource creation, by replaying a cached successful response rather than re-running the operation, while allowing error responses to be retried as genuine attempts rather than replayed failures. This requirement is at the level of architectural pattern and policy rather than a single library, and the Rust implementation must preserve the behavior while adjusting to language and ecosystem idioms.

The essential behaviors can be grouped into four principles. First, idempotency is keyed: the client supplies an `Idempotency-Key` header, which is treated as the primary identifier of the logical operation; this key is scoped to a combination of method, path, and possibly body fingerprint, so that replays are confined to the same endpoint and request semantics.[1][11][12] Second, replay is conditional: on the first request with a given key and matching scope, the handler executes, and the middleware caches the response if and only if it represents success, defined as an HTTP status code in the 2xx range.[1] Third, errors are not cached: responses with codes outside the 2xx range are served to the client but not stored in the idempotency cache, so that subsequent requests with the same key can retry the operation rather than receiving a stale failure; this behavior mirrors Stripe’s semantics and the Python template’s explicit `200 <= status_code < 300` check before caching.[1] Fourth, the store is single-instance and in-memory by default: for a single-process deployment, a bounded in-memory store backs idempotency entries, with ordered eviction semantics and clear documentation that, at scale, this store should be replaced by a distributed cache such as Redis, but without pre-emptively coupling the template to a particular distributed technology.[1]

Observable acceptance criteria derive from these principles. A test harness should demonstrate that when a client sends two identical POST requests with the same `Idempotency-Key` and body to an endpoint backed by the middleware, the handler runs only once; the second request receives the same response body, status code, and replay header (e.g., `Idempotency-Replayed: true`) as the first, while logs show no duplicate handler execution.[12] Another test should show that when the first response is a 4xx or 5xx error, the middleware does not cache it: subsequent requests with the same key trigger fresh handler execution, potentially producing a success, and only at that point does the cache store a response for replay. A third acceptance test should verify scoping: if the same idempotency key is used on two different endpoints or with differing bodies, the middleware either treats them as distinct operations by incorporating path and method into the key or returns a conflict response, such as 422 with an `idempotency_key_conflict` code, in line with draft IETF guidance.[1] Finally, an architectural acceptance criterion is that the in-memory store can be replaced by a distributed implementation without changing the middleware’s public API or behavior; only the store wiring should change.

In the Rust ecosystem, architectural alternatives for realizing these principles fall into three main categories. One is to adopt a framework-specific middleware crate such as `axum-idempotent`, which already supports a client-provided key mode where a header like `Idempotency-Key` is used directly as the cache key, and a hashing mode where the server derives a unique hash from method, path, headers, and body.[12] This approach provides ready-made request interception, caching, and replay with observability via an `idempotency-replayed` header, but it binds the template to Axum, which is R69’s decision, and its storage model is tied to the crate’s internal choices rather than a generic store trait. Another alternative is to use `cratestack::idempotency` as a model: this middleware captures the response on the first request with a given key, persists it, and then replays it on subsequent matching requests, or returns a 422 conflict if the same key is used with a different request body, thereby aligning with IETF semantics.[1] However, `cratestack` appears to be part of a larger stack and may not expose a generic trait surface that can be easily reused in `rs-launch-blueprint`. A third alternative is to hand-roll a middleware layer in the chosen framework, using a generic key-value store trait and reusing semantic primitives from `use-idempotency` for keys, scope, and replay status.[11]

For the store itself, alternatives include a simple `HashMap` behind a mutex or RwLock, which is easy to implement but lacks built-in bounding, admission and eviction policies, and may require bespoke logic for TTL and concurrency; a general-purpose cache crate like `cached`, where function memoization macros are repurposed to cache HTTP responses keyed by idempotency keys; or a dedicated caching library like Moka, which offers both synchronous and asynchronous caches with concurrency, bounds, and expiration controls.[2][3][5][6][7][8][9][10][16] The `cached` crate’s strengths lie in per-function caching, memoization macros, and support for various backends including Redis and `redb` disk storage, as well as async traits that drive concurrent stores.[2][4] It also enables custom stores implementing its `Cached` traits, meaning that a user’s own cache like Moka can be dropped in while still using its macros.[2][4] However, its focus on memoizing function outputs and its Rust version requirement of at least 1.92 suggest that it may be less aligned with the template’s need for explicit middleware semantics and may pose MSRV considerations.[2] Moka, conversely, is explicitly designed for high-concurrency in-memory caching, with `future::Cache` providing async operations `insert`, `get`, `invalidate`, and builders for TTL and TTI, and example code showing how it can be shared across multiple tasks or threads in a Tokio runtime.[3][5][6][7][8][9] This makes Moka a strong candidate for the idempotency store.

Regarding cache key derivation and scoping, the Python template appears to use a composite key abstraction `_CacheKey` combining the raw idempotency header with method and path, though its exact shape is not detailed here.[1] The Rust ecosystem offers two patterns: direct-key mode, where the client-provided key string is used directly as the cache key (as recommended by `axum-idempotent` because it is performant and observable, avoiding server-side hashing), and hashed mode, where a unique hash derived from method, path, headers, and body forms the key.[12] `cratestack::idempotency` exemplifies a hybrid: it uses the idempotency key and stores a response keyed by that value and a body hash, ensuring that a mismatched body produces a conflict.[1] The principle behind these patterns is that idempotency keys must be scoped to the logical operation they represent; the bundle must decide whether to adopt direct-key mode alone, composite mode, or hashing mode. Fit with the Python template suggests direct-key mode with composite scoping: the raw header string plus method and path constitute the key, with body hash optionally added to enforce conflict detection across different payloads.

The pattern of caching only successful outcomes is not a library feature in most crates but a straightforward idiom: inspect the response’s status code inside the middleware’s response-side logic and insert into the cache only if the status code is in the 2xx range. In `cratestack::idempotency`, the emphasis is on protecting mutating routes and replaying stored responses only when the request body hash matches, but the docs do not explicitly state whether it caches only 2xx responses; however, the IETF draft semantics and common idempotency patterns suggest that caching errors is discouraged.[1] In Python, the code explicitly checks `200 <= status_code < 300` before storing an entry.[1] In Rust, this rule should be expressed as a clearly testable condition in the middleware: a boolean guard before calling the store’s `insert` method, and unit tests that confirm non-2xx responses are not cached. No surveyed crate makes the 2xx-only rule an explicit configuration option, so this is a pattern implemented by the middleware rather than a feature flag; this is acceptable as long as it is clearly documented and tested.

Architecturally, the recommended design is to treat idempotency as a cross-cutting concern implemented by middleware and store traits. The bundle should define a `IdempotencyStore` trait with methods like `get`, `insert_success`, and `mark_conflict`, parameterized by a key type modeled with `use-idempotency` types (e.g., `IdempotencyKey`, `IdempotencyScope`, `ReplayStatus`).[11] The default implementation of this trait should wrap a `moka::future::Cache` storing entries keyed by a composite struct containing the key string and request metadata, with values representing cached responses and their replay status.[3][5][6][8][9] Middleware in the chosen web framework (decided by R69) should intercept unsafe methods, extract the idempotency header, derive the composite key, consult the store, and either replay a stored response (annotated with a replay header) or execute the handler, then apply the 2xx-only guard before writing into the store. This design keeps the semantics in `rs-launch-blueprint`’s own code, uses crates for primitives and storage, and mirrors Python behavior while remaining extensible: adding a distributed store is a matter of implementing `IdempotencyStore` with Redis or a similar backend, without rewriting the middleware.

Because the recommended design does not challenge the Python baseline but rather re-expresses it in Rust idioms, there is no `BASELINE-REVIEW` item proposed here that would change the principle or ledger classification. The divergence noted in F313–F315 (Python has idempotency middleware, TypeScript does not) is resolved by adopting idempotency in Rust, aligning with Python and best practice. The main variations are in implementation details—use of Moka instead of `OrderedDict`, and explicit use-idempotency types for metadata—which are implementation differences, not principle changes.

### Recommendation

The report recommends that `rs-launch-blueprint` adopt an idempotency-key replay middleware for unsafe methods in the Rust port, using a bundle composed of three layers: idempotency primitives via the `use-idempotency` crate, an in-memory, futures-aware cache provided by `moka::future::Cache` as the default store implementation, and a framework-agnostic middleware pattern to be wired into whatever web framework R69 chooses. This stack should implement Stripe-style semantics and mirror the Python template’s behavior: direct `Idempotency-Key` header, scoping to method and path, caching only 2xx responses, and single-instance, in-memory store documented as a swap point for future distributed deployments.[1][3][5][6][7][8][9][11][12]

At the semantic layer, `use-idempotency` offers small, validated Rust types modeling idempotency keys, scopes, replay statuses, conflict statuses, and request fingerprint labels.[11] These types allow the template to express idempotency metadata and behavior in a type-safe way, reducing the risk of stringly typed bugs and making logging and observability more structured. Because `use-idempotency` explicitly avoids prescribing storage or hashing strategies, it can be integrated into any middleware or store design, leaving R73 free to choose the store and R69 free to choose the framework.[11] This crate should be added as a dependency with license compatibility and MSRV checks during integration, and used to represent API primitives such as `IdempotencyKey` and `ReplayStatus` in the middleware, response annotations, and logs.

For the in-memory store, the recommendation is to use `moka::future::Cache`, which provides a thread-safe, concurrent, futures-aware cache implementation that works under async runtimes like Tokio, async-std, or actix-rt.[3][5][6][7][8][9] Moka’s asynchronous cache allows entries to be inserted and invalidated via async methods, and accessed via `get`, which returns a clone of the stored value.[8] Its builder interface lets the template configure bounds (e.g., maximum entries) and expiration policies such as TTL and TTI, and its TinyLFU-inspired admission plus LRU eviction aim at high hit ratios in practice.[3][5][6][7][9] The crate’s documentation illustrates how a `future::Cache` can be cloned and shared across multiple tasks, storing up to ten thousand entries and supporting insertions and invalidations across concurrent tasks.[8] This makes it an ideal default store for idempotency entries in a single-instance deployment: it is in-memory, concurrency-safe, bounded, and tested in production environments such as crates.io.[7] `rs-launch-blueprint` should wrap Moka in a `IdempotencyStore` trait implementation, hiding cache details behind a semantic interface, so that future distributed stores (e.g., Redis) can implement the same trait.

The middleware pattern should be hand-rolled, using `use-idempotency` types and the `IdempotencyStore` trait, and integrated into the chosen web framework as a standard middleware layer. It should be informed by existing Rust idempotency middleware crates—`cratestack::idempotency` and `axum-idempotent`—but not depend on them at template level to avoid coupling to Axum or a particular stack.[1][12][13] That pattern should operate in a direct-key mode by default: if a client sends an `Idempotency-Key` header, the middleware treats its value as the primary key of the logical operation, deriving a composite key from the raw header string, HTTP method, and path, and optionally a body hash for conflict detection.[1][11][12] On receipt of a request, the middleware should check the store: if an entry exists and matches the scope, it should immediately replay the cached response, setting a replay header such as `Idempotency-Replayed: true` for observability, and skip handler execution.[12] If no entry exists, the middleware should call the handler, capture the response, inspect its status code, and insert it into the store only if the status is in the 2xx range, using a guard function that makes this rule explicit and testable. Conflict semantics should be implemented by comparing body hashes when the same key is reused with a different payload and returning an appropriate error such as 422, modeled on `cratestack::idempotency` and IETF drafts.[1][11]

While the template remains agnostic to the exact framework, it is reasonable to treat Axum as a leading candidate for R69 due to its widespread use in async Rust web services. The `axum-idempotent` crate can serve as a reference implementation for how to structure middleware behavior, but R73 should not declare it as a template dependency now. If R69 indeed chooses Axum, then `rs-launch-blueprint` may decide in a later item to use `axum-idempotent` directly or wrap it, but that is outside R73’s scope. For now, R73’s bundle focuses on semantics and store, and describes a middleware pattern that can be implemented in Axum, Actix Web, Warp, or other frameworks with similar middleware models.

The recommended bundle therefore looks conceptually like this: `use-idempotency` for types and semantics, `moka::future::Cache` for default in-memory store, and `rs-launch-blueprint`’s own middleware code for unsafe methods. This bundle respects the owner’s parameters—Rust 2024 edition, MSRV policy, licensing, CI targets—subject to verification of crate-specific MSRV and license details during integration. It aligns with Python’s idempotency behavior, uses well-regarded Rust libraries, and leaves a clear extension point for distributed stores, satisfying both equivalency and best practice.

### Members

#### idempotency-primitives (use-idempotency)

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

#### in-memory-cache-store (moka::future::Cache)

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

#### idempotency-middleware-pattern (framework-agnostic, modeled on cratestack::idempotency and axum-idempotent)

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

### Compatibility

Compatibility among the bundle’s members—`use-idempotency`, Moka, and the hand-rolled middleware pattern—is strong because they occupy different layers and use standard Rust interfaces. `use-idempotency` provides metadata types without dictating storage or framework, so it integrates easily with both Moka and custom middleware.[11] Moka’s `future::Cache` is a generic key-value store that can hold any key and value types implementing necessary traits such as `Hash`, `Eq`, and `Clone`, making it compatible with composite key types built from `IdempotencyKey` and request metadata.[3][5][6][8][9] The middleware pattern is generic, using trait-based store access and `use-idempotency` types for metadata, and does not rely on any particular feature of Moka beyond its standard cache API.

While there is no single repository combining these exact members as a template, evidence of compatibility can be inferred from the fact that `cached`’s design allows using custom stores implementing its traits, including third-party caches like Moka, suggesting that Moka’s type design is compatible with generalized cache traits.[2][4] Moka itself is used in crates.io’s download endpoint, a web-service context, demonstrating its integration with HTTP layers.[7] The `use-idempotency` crate is explicitly designed to be reusable across RustUse crates, which likely includes store and middleware crates.[11] Together, these facts support the assertion that the members can be used in one stack.

### Parameters

R73’s bundle effectively sets or assumes several parameters for `rs-launch-blueprint`. It owns the `idempotency-enabled` parameter for unsafe methods, recommending that idempotency middleware be turned on by default for POST, PUT, and PATCH endpoints carrying an `Idempotency-Key` header. It assumes the parameter `web-framework-stack` (R69) will resolve to an async web framework capable of supporting middleware, such as Axum or Actix Web. It also assumes that `http-middleware-stack` (R75) will define an ordering contract placing idempotency middleware relative to request ID, security headers, and access logs.

From a store perspective, the bundle suggests default values for cache capacity and TTL in Moka, but does not own them; they should be treated as configuration parameters. No `CONFLICT: R##` lines are needed because the bundle does not require changes to consumed parameters; it only adds semantic behavior consistent with Python.

### Migration implications

At file level, integrating this bundle into `rs-launch-blueprint` will require adding a new module for idempotency, including types, store trait, and middleware; adding dependencies on `use-idempotency` and `moka` in `Cargo.toml`; and wiring the middleware into the chosen framework’s stack. Existing request handlers will remain unchanged except for possibly exposing idempotency-related headers or metadata in responses. The Python template’s behavior can be mirrored in Rust by writing acceptance tests and example code in the web-service module.

If in future the template migrates to a distributed store such as Redis, the migration will involve implementing `IdempotencyStore` for a Redis-backed cache and removing or de-emphasizing the Moka-based implementation. If a framework-specific middleware like `axum-idempotent` is later adopted, the migration would involve configuring that crate and possibly deprecating the hand-rolled middleware implementation.

### Validation strategy

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

### Confidence & re-verify trigger

Overall confidence in the recommended bundle is high: it is grounded in the Python template’s semantics, uses well-regarded Rust libraries (Moka and `use-idempotency`), and draws on existing middleware patterns in `cratestack::idempotency` and `axum-idempotent`.[1][3][5][6][7][8][9][11][12][13] The design preserves the principle of idempotency-key replay, 2xx-only caching, and in-memory single-instance store as a swap point, which are central to the owner’s requirements. Confidence does depend on future verification of fitness gates (MSRV, RustSec, CI support) and on R69’s framework choice.

Re-verify triggers include major version changes in Moka or `use-idempotency`, new draft specifications for idempotency semantics, or adoption of new frameworks or middleware patterns in Rust that significantly alter best practices. If the template later adopts Axum and `axum-idempotent` gains widespread adoption, R73 may be revisited to consider direct use of that crate. Similarly, if a new caching library surpasses Moka in performance or reliability, the store choice may be re-examined.

### Sources

The analysis and recommendations in this report are informed by documentation and descriptions from the following sources: `cratestack::idempotency` docs for idempotency-key middleware semantics and conflict behavior;[1] `cached` crate docs for caching structures, macros, async traits, and Redis and `redb` integration;[2][4][16] Moka docs and openapps summaries for concurrent cache implementations, features, async cache usage, TTL and TTI behavior, and production usage in crates.io;[3][5][6][7][8][9][10][14] `use-idempotency` docs for idempotency primitives and non-goals;[11] and `axum-idempotent` docs and repository for direct-key and hashing modes, middleware integration, and replay header observability.[12][13] The crate `crates-io-proxy` is noted as a separate example of HTTP caching but is not directly relevant to idempotency semantics.[15]

## Conclusion

R73’s decision is affirmative: `rs-launch-blueprint` should adopt an idempotency-key replay middleware for unsafe HTTP methods, matching Python’s semantics and Stripe-style practices, by bundling `use-idempotency` for metadata, `moka::future::Cache` for the in-memory, single-instance store, and a framework-agnostic middleware pattern that implements direct-key, 2xx-only, conflict-detecting behavior. This bundle respects the owner’s research mandate, aligns with Python precedent, and takes advantage of the Rust ecosystem’s strengths in concurrency and caching without binding prematurely to a specific web framework. It ensures that if this answer is wrong—if the middleware layer, cache-key derivation, 2xx-only rule, or store type need to change—they can be rewritten with clear separation of concerns: metadata, store, and middleware are distinct layers.

The recommendation is careful not to overcommit: it identifies authoritative sources, acknowledges evidence gaps for crate statistics and MSRV, and leaves room for future integration of framework-specific middleware like `axum-idempotent` if and when R69 chooses Axum. It also specifies acceptance criteria and validation strategies, making idempotency behavior observable and testable. In doing so, it strengthens the `rs-launch-blueprint` as a template that embodies sound engineering principles in Rust, consistent with the owner’s vision for CLI, library, and web service components.

## Sources

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

## Cost

Total: $1.2259
