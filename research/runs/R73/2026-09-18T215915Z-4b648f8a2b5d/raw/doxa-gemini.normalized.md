# Deep-Research Report: Idempotency-Key Replay Middleware

### Landscape

The architectural decision regarding how to properly implement idempotency-key replay within a Rust web service sits at the complex intersection of HTTP middleware design, concurrent state management, and distributed systems reliability. To evaluate the Rust ecosystem’s readiness to satisfy the specific requirements of the `rs-launch-blueprint` template—namely, caching only successful outcomes, relying on an in-memory single-instance store explicitly designed for a future distributed swap, and ensuring no cross-endpoint collisions—the landscape must first be mapped into three distinct categories. 

The first category comprises the built-in or first-party toolchain solutions. In the Rust standard library, this is represented by `std::collections::HashMap` protected by concurrency primitives such as `std::sync::Mutex` or `tokio::sync::RwLock`. The second category encompasses established industry standards. Within the Rust web ecosystem, this includes the `tower` crate for generic, framework-agnostic middleware abstractions, `moka` as the definitive high-performance, concurrent in-memory cache with temporal eviction semantics, and `dashmap` for lock-free concurrent map structures. The third category consists of up-and-comers, which represent dedicated idempotency crates such as `axum-idempotent`, `idempotency-rs`, and the now-defunct `idempotent`.

Authority within this domain is established through a combination of formalized protocol specifications and demonstrated production resilience. The baseline for idempotency patterns is governed by the IETF Idempotency-Key HTTP Header specification drafts [cite: 1, 2], which formalize the semantics of key reuse, payload collisions, and the necessity of preventing duplicate side effects in non-idempotent HTTP methods like POST and PATCH. Furthermore, Stripe’s widely cited production architecture for idempotent API requests [cite: 3, 4] serves as the de facto industry standard for the state machine required to handle concurrent retries safely. For Rust-specific implementation authority, the `tokio` team’s ecosystem guidelines dictate the use of `tower` for HTTP middlewares to ensure strict framework agnosticism. Finally, the official `crates.io` engineering publications document production load constraints, demonstrating the absolute necessity of specialized concurrent caches over standard library collections when dealing with high-throughput network services [cite: 5, 6].

Practice evidence across mainstream Rust projects overwhelmingly rejects deeply coupled, all-in-one web framework middlewares in favor of composing `tower::Service` layers. The `crates.io` backend registry itself—one of the highest-traffic Rust web services in existence—relies extensively on `moka` for its heavily loaded endpoint caches. This implementation maintains cache hit rates of approximately 85% while explicitly avoiding the severe lock contention associated with standard `RwLock<HashMap>` implementations, or even the cross-shard deadlock edge cases occasionally observed in `dashmap` [cite: 5, 7, 8]. Conversely, dedicated idempotency crates exhibit extremely low adoption and concerning architectural decisions. For instance, `axum-idempotent` requires forced coupling to the `ruts` session crate, hijacking browser cookie management for server-to-server idempotency keys [cite: 9]. The crate `idempotent` was entirely yanked from the registry due to a lack of maintenance [cite: 10, 11]. 

Judging every candidate strictly against the fit for this specific template—which must serve as a CLI, library, and web service without locking into a specific downstream framework—reveals that pre-packaged idempotency middlewares are unsuitable. The `axum-idempotent` crate violates the principle of a standalone swap-point cache by embedding the idempotency store inside a browser session cookie framework [cite: 9], and it explicitly couples to `axum`, violating the mandate to leave the web framework choice open. The most appropriate fit for the `rs-launch-blueprint` is a hand-rolled `tower::Service` wrapper that enforces the strict success-only caching rule, backed by a highly concurrent `moka` store wrapped in an asynchronous generic trait. This mirrors the Python template's explicit Redis swap-point while respecting Rust's strict concurrency requirements.

### Principles and implementation

The shared requirement across the templates mandates the implementation of an `Idempotency-Key` replay middleware specifically targeting unsafe HTTP methods. The essential behaviors dictate the interception of POST, PUT, and PATCH requests carrying the designated header. Crucially, the middleware must cache only successful outcomes, meaning responses with status codes in the $200 \le x < 300$ range, ensuring that genuine transient errors (5xx) or client validation errors (4xx) are naturally retried by the client rather than artificially replayed by the server. Finally, the architecture must utilize an in-memory, single-instance-by-design store that is explicitly documented and trait-bound as a future distributed-store swap point. 

This constitutes a strict architectural pattern. The ecosystem requires total agreement on the behavior of the deduplication state machine and the store's trait boundaries. What may vary is the concrete memory structure utilized to fit the language-specific concurrency model. In the Python precedent, the template utilizes a standard `OrderedDict` to act as an LRU cache, protected by the nature of the language's execution model. In asynchronous Rust, attempting to mirror this by wrapping an `std::collections::HashMap` (or a `BTreeMap`) inside a `tokio::sync::Mutex` introduces a catastrophic bottleneck. Every cache read, write, or eviction requires a total lock across the asynchronous reactor, destroying throughput and causing severe latency spikes. Furthermore, manual eviction algorithms in Rust are notoriously difficult to implement efficiently without violating strict borrowing rules or introducing race conditions.

`BASELINE-REVIEW: F315 — architectural pattern — proposed change to utilize a concurrent TTL-aware cache (moka) instead of a Mutex-bound OrderedDict — evidence: manual LRU eviction in asynchronous Rust requires expensive exclusive locks on every read operation to update access ordering; the crates.io backend explicitly migrated to moka to avoid this exact lock contention under heavy production load [cite: 5].`

A naive implementation of an idempotency cache simply checks the store, invokes the endpoint if the key is missing, and saves the resulting response. However, in a distributed environment, if a client retries a request due to a network timeout before the initial request finishes processing, both requests will read a "miss" from the cache. They will then execute simultaneously, causing the exact duplicate side effects idempotency is meant to prevent [cite: 4, 12]. Stripe’s standard [cite: 3] and advanced reference implementations like `idempotency-rs` [cite: 13] resolve this by formalizing a strict state machine. The Rust template must define an `IdempotencyStore` trait that mandates an atomic `try_acquire_lock` method. This method must atomically return either an `Acquired` token if the key is new, or a `Conflict` response (typically yielding an HTTP 409) if a request tied to that key is currently in flight [cite: 13, 14]. 

To satisfy the acceptance criteria, the cache key derivation must be handled with cryptographic precision. The key must never be the raw header value alone. If a client mistakenly sends the same idempotency key to both a `/charge` endpoint and a `/refund` endpoint, a raw key would cause a severe cross-endpoint replay collision [cite: 2]. It must be a composite of the header value, the HTTP method, and the URI path. In Rust, this is idiomatic to express as a strongly typed struct implementing the `Hash`, `Eq`, and `Clone` traits. 

Regarding response semantics, the middleware must explicitly inspect the HTTP status code before committing the response to the store. The `tower::Service` implementation will await the inner service's future, inspect `response.status().is_success()`, and only call the `complete_with_response` store method if the condition holds. If the inner service yields an error, the middleware must call a `release_lock_on_failure` method on the store, completely clearing the pending state so the client can legitimately retry the operation [cite: 13, 15].

By implementing this logic strictly as a generic `tower::Service`, the design preserves the principle of framework agnosticism. It integrates flawlessly with `axum`, `tonic`, or any hyper-based framework chosen by downstream consumers, incurring a zero-cost abstraction penalty while cleanly isolating the idempotency state machine from the underlying business logic. 

### Recommendation

The recommended stack is a hand-rolled `tower::Service` component (`IdempotencyMiddleware`) wrapping an asynchronous `IdempotencyStore` trait, with `moka` (specifically `moka::future::Cache`) serving as the concrete in-memory provider for local development.

### Members

#### moka

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
The compatibility of `moka` and `tower` is structurally guaranteed by the async ecosystem’s reliance on `tokio`. The `moka::future::Cache` is designed explicitly to interface cleanly with Tokio-based asynchronous contexts without blocking the runtime's reactor [cite: 17]. By wrapping the cache interactions entirely within a `tower::Service` implementation, the template ensures 100% interoperability with whichever framework the R69 bundle selects, provided that the chosen framework relies on the standard `hyper`/`tower` HTTP ecosystem (which includes major frameworks such as Axum, Tonic, and Salvo).

### Parameters
*   `owns F313 = Idempotency-Key header interception on unsafe methods (POST, PUT, PATCH)`
*   `owns F314 = Strict 2xx-only outcome caching condition`
*   `owns F315 = In-memory moka store swapped via standard Rust asynchronous traits`
*   `assumes R69 = Open` (The middleware must be implemented strictly as a `tower` service to integrate seamlessly with the winning framework).
*   `assumes R75 = Open` (This stack exclusively decides the internal mechanics of how idempotency works, remaining unopinionated on where it is placed in the overarching HTTP lifecycle).

### Migration implications
Implementing this capability dictates the creation of several new core files in the template's web directory. The `Cargo.toml` will require the addition of `moka = { version = "0.12", features = ["future"] }`. Inside the routing logic (e.g., `src/web/idempotency.rs`), developers must define a strongly typed `CacheKey` struct implementing `Hash`, `Eq`, and `Clone` that concatenates the request method, URI path, and header value to enforce isolation. The exact architectural interface must be established via an `#[async_trait] pub trait IdempotencyStore`, defining the required `try_acquire_lock` and `complete_with_response` methods. Finally, the core `tower::Service` implementation must be authored to coordinate the atomic lock extraction, handle the inner service future polling, and enforce the strict `if response.status().is_success()` condition before writing to the backing store.

### Validation strategy
The validation strategy relies on executing a series of commands that mathematically prove the concurrency principles hold in a realistic environment. 
*   **Planned Check**: Issue concurrent overlapping requests using the exact same `Idempotency-Key` via a load-testing tool (like `oha` or `wrk`). The expected behavior is that the first request acquires the lock and enters the execution phase, while all simultaneous requests immediately receive an `HTTP 409 Conflict` (or equivalent "request in flight" error), categorically proving that the atomic `try_acquire_lock` prevents thundering herd execution.
*   **Planned Check**: Validate the cross-endpoint isolation by sending `Idempotency-Key: identical-123` to a mock `/process-payment` endpoint, and then immediately to a mock `/issue-refund` endpoint. The expected behavior is that both endpoints execute successfully and independently, proving that the composite `CacheKey` prevents payload collisions.
*   **Planned Check**: Validate the F314 (2xx exception) rule by mocking a `502 Bad Gateway` response for a specific test endpoint. When a request is made with a unique key, it will receive the 502. Retrying the identical key must result in a completely fresh handler execution rather than returning a cached `502` payload, verifying that transient errors are never permanently locked into the temporal cache.

### Confidence & re-verify trigger
Confidence in this architectural conclusion is exceptionally high. The combination of `moka` as a high-performance backing store and `tower` as the middleware pattern represents the absolute pinnacle of current Rust backend engineering practices. A re-verification process should only be triggered if the chosen framework (R69) fundamentally breaks away from the `tower` ecosystem. For example, if `actix-web` is ultimately selected, the exact same idempotency state machine and caching logic must be utilized, but it will need to be bound to `actix_web::dev::Transform` rather than `tower::Service`.

### Sources
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

## Sources

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
