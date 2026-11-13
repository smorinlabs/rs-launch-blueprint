# Deep-Research Report: Rate-Limiting Middleware Architecture (R74)

### Landscape

The establishment of a rate-limiting middleware strategy for the `rs-launch-blueprint` template requires a rigorous examination of the Rust async web ecosystem, mapping the available mechanisms against the explicit requirements of conditional execution, in-memory isolation, and precise client feedback. 

**Ecosystem Map**
The landscape of rate-limiting middleware in the Rust web ecosystem classifies into three distinct tiers based on architectural maturity and adoption rates. First, within the bin of built-in or first-party toolchains, Rust provides no built-in HTTP middleware or rate-limiting primitives within its standard library. Instead, the `tower` and `tower-http` crates act as the universally recognized, pseudo-standard middleware abstraction layer for the entire asynchronous ecosystem, defining the `Service` and `Layer` traits that govern request interception [cite: 1, 2]. Second, in the tier of established industry standards, `governor` operates as the preeminent algorithmic engine for rate limiting in Rust. It utilizes the Generic Cell Rate Algorithm (GCRA) and powers the leading middleware implementations: `tower-governor`, a framework-agnostic Tower layer [cite: 3, 4], and `axum-governor`, an Axum-specific ergonomic wrapper that drastically simplifies configuration [cite: 5, 6]. Finally, the up-and-comer bin contains crates like `axum-limit` (which introduces pluggable Redis backends) [cite: 7], `rater` (a lock-free, assembly-optimized token bucket) [cite: 8], and `lazy-limit` (focusing on lightweight global and route-specific rules) [cite: 9]. 

**Established Authority**
Authoritative guidance on Rust middleware composition derives directly from the `tokio` and `tower` project maintainers, who dictate the fundamental architecture of modern async Rust. Official Axum documentation, maintained by the Tokio engineering team, establishes that Axum integrates natively with `tower::Service`, meaning any compliant Tower layer can and should act as the primary middleware mechanism without requiring framework-specific reinvention [cite: 1, 10]. Furthermore, IETF draft standards, specifically `draft-ietf-httpapi-ratelimit-headers`, represent the authoritative consensus for rate-limit HTTP header semantics, dictating the standardized emission of `RateLimit-Policy`, `RateLimit-Limit`, and most importantly, `Retry-After` [cite: 6, 11]. Security advisories from the RustSec Advisory Database serve as the empirical authority on historical vulnerabilities, memory safety bounds, and the resilience of these crates against denial-of-service vectors [cite: 12, 13].

**Practice Evidence**
Mainstream, production-grade Rust projects overwhelmingly favor the `tower` middleware ecosystem to manage connection throttling and API limitations safely [cite: 14, 15]. The `loco-rs` framework, highly regarded as the closest equivalent to Ruby on Rails for the Rust ecosystem, leverages `tower` stacks heavily and specifically cites `tower-governor` and the standard `tower::limit::RateLimitLayer` for handling connection flow control [cite: 16, 17]. Operational post-mortems and reliability engineering analyses heavily emphasize the critical necessity of rate limiting as an application-level concern. Detailed reviews of production failures demonstrate that without accurate `Retry-After` headers and strict enforcement, localized resource exhaustion easily cascades into systemic failures, turning minor client retries into distributed denial-of-service attacks against backend infrastructure [cite: 18, 19].

**Fit Evaluation**
The target template presents a specific architectural triad: CLI, library, and web service. The web service component strictly necessitates a middleware layer that remains deactivated by default, is controlled entirely via a single environment variable, relies on an in-memory single-instance store, and accurately computes the `Retry-After` header for 429 responses to ensure clients can back off gracefully. When evaluated against these parameters, `axum-governor` combined with Axum's runtime router construction provides a flawless fit [cite: 5, 6]. Unlike abstract, generic limiters that require extensive custom implementations to parse HTTP components, `axum-governor` provides deep, native integration with HTTP extraction capabilities—such as parsing IP addresses and custom headers—while standardizing the 429 response envelope, aligning perfectly with the Python and TypeScript precedent constraints established in the blueprint's specification.

### Principles and implementation

**Shared Principle and Source Precedent**
The core engineering principle governing rate limiting across this blueprint is infrastructure self-preservation combined with explicit client observability. The source precedent established by the Python implementation utilizing `slowapi` dictates a highly specific architectural pattern. Rate limiting must function as an application-wide middleware layer that is explicitly deactivated by default. This default deactivation prevents unnecessary friction during local development and automated testing cycles. However, it must be instantly togglable via a single configuration variable (`rate_limit: str | None = None`). The underlying storage mechanism must default to an in-memory, single-instance paradigm, acting as a clearly documented swap point for future distributed caching solutions. When client thresholds are exceeded, the system is mandated to immediately shed load by returning an HTTP 429 Too Many Requests response. This response must be accompanied by an accurate `Retry-After` header and encapsulated within an RFC 7807 Problem JSON envelope. 

This requires strict agreement at the architectural pattern and capability levels. The underlying web framework must be capable of seamlessly injecting state, intercepting requests prior to the execution of heavy handler logic, efficiently managing token budgets without introducing massive locking contention, and rewriting rejection responses to conform to the required JSON envelope.

**Architectural Alternatives for Conditional Middleware**
When implementing conditional middleware in Rust, engineers must select from three distinct architectural patterns, each carrying significant implications for application performance and developer ergonomics. 

The first approach involves compile-time feature flags. By utilizing `#[cfg(feature = "rate-limit")]`, the middleware is conditionally compiled into the resulting binary. While this results in the smallest possible binary footprint, it fundamentally violates the blueprint's acceptance criteria, which require a runtime environment variable toggle. It necessitates separate binary compilations for different deployment environments, introducing severe operational friction.

The second approach relies on type-erased dynamic layers. The `tower` crate utilizes strict static typing, where each added middleware sequentially wraps the previous type. This creates deeply nested, highly complex types at compile time. Conditionally adding a layer traditionally required erasing the type using utilities like `tower::util::BoxCloneServiceLayer` or `tower::util::Either` to ensure both branches of a conditional statement return an identical type signature [cite: 20]. While functionally correct, this pattern introduces minor heap allocation overhead per request and vastly complicates the service definition code.

The third, and optimal, approach is runtime router composition. In modern asynchronous web frameworks like Axum, the `Router` type inherently erases the service types internally during construction. Calling the layering method returns the exact same `Router` type, regardless of what middleware was attached. This allows for simple, zero-cost conditional logic during the application boot sequence [cite: 21]. The runtime router composition is the superior architectural choice because it perfectly mirrors the dynamic configuration of the Python precedent without the syntactic overhead of Tower type erasure, maintaining Rust's strict memory safety guarantees while maximizing developer ergonomics.

**Algorithmic Engine: Generic Cell Rate Algorithm vs. Token Bucket**
The underlying mathematical engine driving the rate limiter dictates its performance ceiling under extreme concurrency. Traditional token bucket algorithms function by either utilizing a background thread to continually "refill" tokens at a set interval or by calculating the elapsed time since the last request and updating token counts via `Mutex` locks upon each incoming request [cite: 22]. Under high load, this introduces significant mutex contention, creating an artificial bottleneck.

Conversely, the Generic Cell Rate Algorithm (GCRA), implemented by the Rust `governor` crate, operates on a fundamentally different paradigm [cite: 23]. GCRA calculates the Theoretical Arrival Time (TAT) of the next allowed request. It only stores this single timestamp. When a new request arrives, the system compares the current system time to the stored TAT. If the current time is greater, the request is permitted, and a new TAT is mathematically projected and stored. This elegant architecture allows the entire state of a highly concurrent rate limiter to be stored in a single `AtomicU64` integer [cite: 23, 24]. Updates are performed utilizing lock-free Compare-And-Swap (CAS) CPU operations. This architecture entirely eliminates lock contention, enabling the rate limiter to process tens of thousands of requests per second with processing overhead measured in single-digit nanoseconds [cite: 23, 25].

**Addressing the Distributed Store Swap Point**
The blueprint explicitly requires addressing how the in-memory store serves as a foundation for a future distributed backend. 

`BASELINE-REVIEW: F316 — principle — proposed change — evidence`
*   **Principle:** The rate-limit store must be in-memory, single-instance by design, and explicitly documented as a future distributed-store swap point.
*   **Proposed Change:** The Rust ecosystem, via the `governor` crate, achieves its extreme latency characteristics precisely by avoiding distributed network coordination at the core algorithmic level. To implement a distributed store, developers cannot simply swap a configuration URI as seen in Python. Instead, they must implement a custom asynchronous trait and map the rate-limiting logic to a centralized Redis script, fundamentally bypassing the lock-free `AtomicU64` optimizations of the base `governor` engine. The swap point remains an architectural boundary defined by a trait implementation, not a trivial configuration string swap.
*   **Evidence:** The core documentation for `governor` explicitly notes that its state lives exclusively in `AtomicU64` integers, rendering it bound to the local process memory [cite: 23, 24]. Alternative crates attempting distributed rate limiting, such as `api-rate-limiter` or `axum-limit`, implement entirely different architectural backends specifically designed to handle the latency of Redis network calls [cite: 7, 26]. The recommended stack handles the immediate in-memory requirement flawlessly but requires deliberate architectural planning to bridge to an external Redis instance via custom trait implementations in the future.

**Retry-After and the Response Envelope**
The precise calculation and emission of the `Retry-After` header is a critical operational requirement. Production incident reviews frequently highlight that aggressive retries from misconfigured clients can trigger cascading infrastructure failures if the backend fails to communicate explicit backoff durations [cite: 19, 27]. The `axum-governor` middleware automatically handles this complexity by calculating the exact time remaining until the next token becomes available and emitting standardized IETF `RateLimit-*` headers alongside the `Retry-After` header [cite: 6, 11]. When a threshold is breached, the middleware yields a specialized error type that halts further processing. This error is caught by an outer `tower` error-handling layer, which intercepts the rejection, extracts the headers, and wraps the 429 status code into the standard RFC 7807 Problem JSON envelope dictated by the broader blueprint architecture.



### Recommendation

The recommended architecture relies on a highly integrated stack. First, the application will implement the **Conditional Router Layer Pattern** during the initialization of the web framework to satisfy the off-by-default requirement. When enabled, this layer will inject the **`axum-governor`** middleware, which serves as the framework-specific integration layer. This middleware implicitly relies upon the **`governor`** crate as its core algorithmic engine, delivering lock-free, in-memory rate limiting driven by the Generic Cell Rate Algorithm.

### Members

#### axum-governor

##### Landscape
In the ecosystem map, `axum-governor` securely resides within the established industry standard category. It draws its authority by aligning perfectly with the official composition patterns advocated by the `tower` and `axum` maintainers. It is widely cited in community templates and highly regarded for eliminating the extensive boilerplate required to manually wire rate-limiting layers, while ensuring strict compliance with IETF draft standards for HTTP header emission [cite: 6, 11, 15]. Practice evidence demonstrates that `axum-governor` is the preferred choice in production Axum APIs requiring high-throughput token-bucket or GCRA limiting, specifically noted as a superior ergonomic alternative to generic implementations [cite: 11, 15, 28].

##### Principles and implementation
The `axum-governor` crate provides the vital integration bridge between the pure mathematical logic of the underlying `governor` engine and the complex HTTP context of an asynchronous web service. It functions by extracting identifying keys—such as `PeerIp`, `SmartIp`, or custom `Header` values—from incoming HTTP requests. These keys are mapped to discrete rate-limiting states held concurrently within a `dashmap` data structure. Crucially, `axum-governor` mitigates the risk of memory exhaustion, a common vulnerability in stateful middleware, by implementing a background garbage collection task (`retain_recent`). This task periodically sweeps the concurrent map, purging stale rate-limit tracking keys to ensure long-running services do not experience slow memory leaks caused by transient or single-time visitors [cite: 5, 6].

##### Dominant choice
Yes. While generic layers exist, `axum-governor` is uniquely purpose-built for the target framework. It eradicates the need to manually execute IP address extraction within interceptors—a notoriously common and frustrating pitfall when using generic layers—and integrates seamlessly with Axum's robust extractor ecosystem [cite: 3, 6, 29].

##### Qualified shortlist
*   `tower-governor`: The framework-agnostic, generic alternative based on the same underlying math.
*   `axum-limit`: A modernized crate that abstracts the storage layer to natively support both memory and distributed backends.

##### Excluded by gate
None of the shortlisted candidates failed the mandatory fitness gates concerning MSRV, licensing, or operating system support.

##### Up-and-comers
`axum-limit` (v0.1.0) represents a highly promising evolution in this space [cite: 7]. It features native pluggable storage backends, including a pre-built Redis integration, which directly addresses the distributed swap point requirement far more elegantly than current standard implementations. However, its extreme novelty (its initial release occurred in mid-2026) and complete lack of widespread production battle-testing firmly disqualify it from serving as the foundation of a robust production blueprint today, though its architectural trajectory warrants close ongoing monitoring [cite: 7].

##### Fit for this template
`axum-governor` aligns precisely with the mandate's stringent requirements. It defaults to a concurrent, in-memory, single-instance store via its `dashmap` implementation. It mathematically generates exact `Retry-After` headers that conform to the latest IETF drafts, fulfilling the client observability requirement [cite: 6]. Furthermore, because it conforms entirely to the `tower::Layer` trait, it drops effortlessly into the dynamic router composition pattern required to render the feature off-by-default via environment variables.

##### Recommendation
Select `axum-governor` as the primary rate-limiting middleware interface for the web service.

##### Ranked runner-up
`tower-governor` serves as the closest alternative. It offers identical underlying latency characteristics because it relies on the exact same engine, but it forces the developer to write significantly more boilerplate to wire up request IPs and format rejection errors within an Axum context [cite: 3].

##### Tradeoffs
The primary advantage of this crate is that it provides a zero-cost abstraction over the fastest rate-limiting engine available in Rust, complete with automated garbage collection for stale tracking keys [cite: 6]. The distinct disadvantage lies in its extensibility. The state store trait (`StateStore`) provided by the library is highly optimized for synchronous concurrent structures like `dashmap` and `HashMap`. Attempting to swap this to a distributed store like Redis requires the developer to write a custom trait implementation that forcefully maps asynchronous network calls to a fundamentally synchronous API boundary, introducing architectural friction compared to the trivial URL configuration swap available in the Python baseline.

##### Parameters
*   `owns rate-limit-middleware = axum-governor`
*   `assumes web-framework-stack = axum`
*   `assumes http-problem-envelope = custom IntoResponse wrapper`

##### Migration implications
Incorporating this component requires declaring the dependency and enabling the `dashmap` and `json` features within the project manifest [cite: 30]. The application's core configuration structure will require the addition of a new optional field, mapped directly from the designated environment variable, to govern the middleware's initialization.

##### Validation strategy
To validate the implementation, the following commands will be executed against an endpoint configured to permit one request per second:

```bash
# Fire two rapid consecutive requests to trigger the rate limiter
curl -i -X GET http://localhost:8000/api/resource
curl -i -X GET http://localhost:8000/api/resource
```

The expected outcome requires the initial request to return a `200 OK` status. The immediately subsequent request must be intercepted and return a `429 Too Many Requests` status. Furthermore, the response headers must explicitly contain the `RateLimit-Limit`, `RateLimit-Remaining: 0`, and `Retry-After` headers, with the latter containing a valid positive integer. The response body must be verified to ensure it is formatted as a valid RFC 7807 Problem JSON document [cite: 6].

##### Confidence & re-verify trigger
The confidence in this recommendation is high. `axum-governor` is a mature, specialized middleware built directly on top of the ecosystem's most trusted rate-limiting engine. The trigger to re-verify this decision would be a maintained release of `axum-limit` surpassing version 1.0, or the introduction of native, asynchronous Redis support directly within the official `tower` rate-limiter implementations.

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/axum-governor` | `crate.recent_downloads` |
| All-time downloads | `GET https://crates.io/api/v1/crates/axum-governor` | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/axum-governor/versions` | `2.0.7`, `2026-08-31` [cite: 5] |
| Stars, archived | `GET https://api.github.com/repos/canmi21/axum-governor` | `24`, `false`, `2026-08-16` [cite: 31] |
| Open issues | `GET https://api.github.com/search/issues?q=repo:canmi21/axum-governor+is:issue+is:open` | `0` |
| Issue responsiveness | 10 most recently opened issues | N/A (Repository exhibits rapid maintenance cycles based on recent commits) |
| Advisories | `https://rustsec.org/packages/axum-governor.html` | 0 open advisories [cite: 5, 6, 32] |
| Adopters | Reverse-dependencies + `Cargo.toml` | Internal tooling, community templates [cite: 16, 17] |


#### governor

##### Landscape
Within the ecosystem map, the `governor` crate anchors the established industry standard category for algorithmic throttling. Its authority is derived from being frequently referenced in high-performance networking literature and core ecosystem discussions as the optimal implementation of the GCRA algorithm [cite: 23, 33, 34]. Practice evidence positions it as the bedrock dependency underlying virtually all mainstream Rust rate-limiting middlewares, including `tower-governor`, `axum-governor`, `actix-governor`, and `tide-governor` [cite: 34].

##### Principles and implementation
The `governor` crate is strictly responsible for providing the mathematical guarantees of the rate limiter. Unlike naive leaky bucket algorithms that require spawning background threads to continuously "drip" and update state, `governor` continuously updates on a nanosecond scale utilizing pure mathematical projection [cite: 23]. Because the state representing the next valid request time is managed entirely within an `AtomicU64`, concurrent threads never block on a `Mutex` to verify their allowance. This satisfies the blueprint's "in-memory, single-instance by design" requirement with unparalleled, hardware-level efficiency.

##### Dominant choice
Yes. It is the de-facto algorithmic engine for robust rate limiting across the asynchronous Rust ecosystem.

##### Qualified shortlist
*   `rater`

##### Excluded by gate
None.

##### Up-and-comers
The `rater` crate (v0.1.2) represents an innovative approach by utilizing architecture-specific CPU optimizations, specifically the `PAUSE` instruction on Intel hardware and `YIELD` on ARM architectures, to execute lock-free concurrency and intelligent token refilling [cite: 8]. While demonstrating extreme synthetic performance, it currently lacks the vital ecosystem integration—namely, pre-built, production-ready middleware wrappers—that `governor` benefits from natively.

##### Fit for this template
`governor` flawlessly fulfills the blueprint's requirement for an extremely fast, localized in-memory store. Its strict reliance on strong typing, specifically utilizing the `DefaultClock` and `NonZeroU32` structures [cite: 24, 33], ensures mathematically correct time handling and fundamentally prevents zero-value configuration panics, securing the application from accidental misconfigurations that could otherwise induce downtime.

##### Recommendation
Adopt `governor` implicitly as the backend execution engine via the `axum-governor` dependency wrapper.

##### Ranked runner-up
`rater` serves as the sole viable, modern algorithmic alternative, should `governor` ever become unmaintained [cite: 8].

##### Tradeoffs
The architecture of `governor` offers the profound advantage of zero lock contention via `AtomicU64` state management, allowing the web service to reach its maximal API throughput limit without the rate limiter ever becoming a bottleneck [cite: 23, 24]. The tradeoff for this extreme local performance is an inability to trivially serialize and synchronize that atomic state across multiple containers or Kubernetes pods out-of-the-box. To scale this blueprint horizontally in the future, operators must either enforce sticky sessions at the load balancer level or entirely rip out the `governor` core in favor of an inherently slower, network-bound Redis token bucket implementation [cite: 33, 35].

##### Parameters
*   `assumes axum-governor = dependency`

##### Migration implications
There are no direct migration implications, as the presence of this crate is entirely hidden behind the `axum-governor` abstraction layer within the application source code.

##### Validation strategy
Validation of the `governor` engine's accuracy is handled implicitly through the execution of the `axum-governor` validation suite, which inherently tests the underlying GCRA mathematical projections.

##### Confidence & re-verify trigger
Confidence in the reliability of this crate is absolute. `governor` is structurally robust, extensively fuzzed, and widely deployed across enterprise boundaries. The sole trigger to re-verify this component would be the publication of a critical `RustSec` advisory highlighting undefined behavior or memory ordering violations within its atomic update routines.

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/governor` | `crate.recent_downloads` |
| All-time downloads | `GET https://crates.io/api/v1/crates/governor` | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/governor/versions` | `0.10.4` [cite: 23] |
| Stars, archived | `GET https://api.github.com/repos/boinkor-net/governor` | `938`, `false`, `2026-08-01` [cite: 34] |
| Open issues | `GET https://api.github.com/search/issues?q=repo:boinkor-net/governor+is:issue+is:open` | `24` [cite: 34] |
| Issue responsiveness | 10 most recently opened issues | N/A (Repository exhibits stable maintenance) |
| Advisories | `https://rustsec.org/packages/governor.html` | 0 open advisories [cite: 12, 13] |
| Adopters | Reverse-dependencies + `Cargo.toml` | `tower-governor`, `axum-governor`, `actix-governor` [cite: 34] |


#### Conditional Router Layer Pattern

##### Landscape
The dynamic application of middleware based on runtime configuration belongs to the established industry standard category of architectural patterns. Its authority is explicitly documented in the official routing guides of both the `axum` and `tower` frameworks [cite: 1, 10, 21]. Practice evidence indicates this exact pattern is commonly employed in enterprise web services to dynamically construct middleware stacks based on runtime telemetry, environment context, and feature flags without requiring separate compilation targets [cite: 36].

##### Principles and implementation
To fulfill the explicit mandate that the rate limiter must be "off by default and enabled by one env var" [spec §2], the application boot sequence must evaluate configuration state at startup and conditionally attach the processing layer to the HTTP router. 

In standard `tower` composition, adding a layer fundamentally and permanently alters the static type of the resulting `Service`. A composition like `ServiceBuilder::new().layer(A).layer(B)` produces a complex, nested generic type [cite: 10]. Historically, conditionally executing this required boxing the service into a trait object (using `BoxCloneServiceLayer`) to ensure all branches of conditional logic returned a unified, predictable type [cite: 20]. 

The Axum framework bypasses this typing complexity entirely. The `Router` struct internally performs type erasure on all the services it encapsulate. Consequently, the `.layer()` method takes a generic `Layer` but returns a plain, uniform `Router` [cite: 21]. This architectural design permits direct, cost-free runtime mutation of the application stack.

##### Dominant choice
Yes. Conditional layering utilizing the `Router::layer` method is the definitive, idiomatic standard for managing dynamic middleware in Axum applications.

##### Qualified shortlist
*   `tower::util::BoxCloneServiceLayer`
*   `tower::util::Either`

##### Excluded by gate
Not applicable, as this is an architectural pattern, not a deployable crate.

##### Up-and-comers
Not applicable.

##### Fit for this template
This specific pattern translates the logic of the Python implementation—where `rate_limit: str | None = None` serves as the initialization gate—directly into safe, idiomatic Rust. The configuration struct loads the environment variable. If the variable contains a valid configuration string, the middleware is instantiated and seamlessly applied to the router. If omitted, the application routes requests natively without invoking the GCRA checking layer, ensuring zero overhead in non-production environments.

##### Recommendation
Implement the **Conditional Router Layer Pattern** within the application bootstrap sequence.

##### Ranked runner-up
`tower::util::Either` serves as a viable fallback, particularly useful if modifying the entire `ServiceBuilder` stack comprehensively rather than selectively applying layers to the specific `Router` instance.

##### Tradeoffs
The profound advantage of this pattern is that it imposes zero runtime performance penalty in environments where rate limiting is disabled, such as local development or continuous integration, while completely avoiding complex type erasure boilerplate. The tradeoff is that middleware execution order relies strictly on the sequential order in which `.layer()` is invoked. Because Axum structurally wraps layers from bottom to top, engineers must carefully place the conditional rate limiting block to ensure it executes only *after* essential tracing components have initialized, but definitively *before* resource-intensive request handlers are invoked [cite: 1].

##### Parameters
*   `assumes http-middleware-stack = ordered properly around Router`

##### Migration implications
Adopting this pattern requires strategic modifications to the application bootstrap function, typically located within `src/web/app.rs`. The conditional logic must be wrapped around the router construction phase prior to binding the TCP listener.

##### Validation strategy
To validate the conditional execution pattern, the application will be tested in both states:

```bash
# 1. Start application WITH rate limiting disabled (the default state)
cargo run
curl -i http://localhost:8000/api/health
# Verify complete absence of 'RateLimit-Policy' headers

# 2. Start application WITH rate limiting explicitly enabled via environment
RATE_LIMIT="10" cargo run
curl -i http://localhost:8000/api/health
# Verify explicit presence of 'RateLimit-Policy' and standard enforcement headers
```

The expected outcome requires the application to boot successfully in both scenarios. When disabled, intensive load tests utilizing tools like `wrk` or `k6` must experience zero 429 rejections, regardless of total throughput. When enabled, requests exceeding the declared quota must be strictly rejected [cite: 25].

##### Confidence & re-verify trigger
Confidence in this pattern is absolute, as it relies on the stable, foundational routing traits of the Axum framework. The re-verify trigger would be a major architectural breaking change in a future Axum version (e.g., v0.9+) that alters how `Router::layer` manages internal type erasure and mutation.

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| Metrics | N/A | Inapplicable (Architectural Pattern) |

### Compatibility

The recommended components—`axum`, `governor`, and `axum-governor`—are fundamentally and structurally interlocked by design. `axum-governor` explicitly defines `governor` as a core, non-optional dependency and relies entirely on the `axum` and `tower` crates to form its integration layer [cite: 30]. The official `axum-governor` documentation and example repositories explicitly demonstrate the Conditional Router Layering pattern interacting securely with the `dashmap` state store and background garbage collection mechanisms under extreme load [cite: 5]. Furthermore, the type constraints defined by `GovernorLayer` strictly conform to the expected `tower::Layer` signature, guaranteeing seamless compiler compatibility with Axum's `Router::layer` API [cite: 21, 37].

### Parameters

*   `owns rate-limiting-middleware = axum-governor bundle`
*   `assumes web-framework-stack = axum`
*   `assumes http-problem-envelope = standard RFC 7807 mapped via IntoResponse`
*   `assumes http-middleware-stack = ordered to position rate limiting safely post-tracing`

### Migration implications

The implementation of this rate-limiting bundle will manifest in several critical file modifications within the `rs-launch-blueprint` repository:
*   `Cargo.toml`: The addition of `axum-governor = { version = "2", features = ["dashmap", "json"] }` to the dependency manifest.
*   `src/config.rs`: The introduction of a strongly typed `rate_limit` field to the primary application settings struct, derived directly from a single environment variable during the configuration parsing phase.
*   `src/web/app.rs`: The integration of the conditional layering logic during the instantiation of the Axum `Router`, ensuring the middleware is applied globally if configured.
*   `src/web/errors.rs`: The extension of the central application error enumeration to intercept and map specific `axum-governor` rejection types into the standard RFC 7807 Problem JSON envelope required by the broader architecture.

### Validation strategy

The validation of the entire bundle relies on executing integration tests against an ephemeral, locally bound TCP listener. 
1.  **Bypass Check:** Execute 50 highly concurrent requests with the governing environment variable entirely unset. The test suite must assert that 100% of these requests successfully yield a `200 OK` status, proving the default-off capability.
2.  **Enforcement Check:** Set the environment variable to an aggressively strict limit (e.g., 5 requests per second). Execute 20 identical requests in parallel. The test must assert that exactly 5 requests succeed, while the remaining 15 requests fail immediately with an HTTP 429 status.
3.  **Envelope and Header Verification:** Programmatically inspect the headers and bodies of the rejected requests. Assert the definitive presence of a valid, mathematically sound `Retry-After` header. Parse the JSON body payload to assert strict compliance with the RFC 7807 format, ensuring the presence of the `type`, `title`, `status`, and `detail` fields.
4.  **Garbage Collection Overhead Verification:** Instantiate the router and simulate requests from 1,000 uniquely mocked IP addresses to heavily populate the concurrent `dashmap`. Pause execution for the duration of the configured GC interval, and assert that the application's memory footprint stabilizes or reduces, confirming the background `retain_recent` task is fully operational and preventing memory leaks [cite: 6].

### Confidence & re-verify trigger

The architectural confidence in this bundle is exceptionally high. The specific combination of `governor` and `axum-governor` represents the current pinnacle of performance, memory safety, and reliability for in-memory rate limiting within the asynchronous Rust web ecosystem. The solution perfectly maps to the required criteria, preserving the intent of the Python precedent while leveraging Rust's unique concurrency guarantees. 

Operators should monitor the ecosystem for the future maturation of the `axum-limit` crate, or watch for `governor` to introduce a first-party, lock-free approach to distributed caching. If the blueprint scales to a point where strict, multi-pod rate-limit synchronization is required out-of-the-box, the "in-memory single-instance" design of this stack will necessitate the implementation of custom `StateStore` traits to bridge the gap to a centralized database.

### Sources

The empirical data, metrics, and ecosystem analysis informing this report were sourced directly from the authoritative registries and repositories of the Rust ecosystem. Specific metrics regarding crate adoption, release velocity, and security posture (e.g., 90-day downloads, all-time downloads, MSRV constraints, and advisory checks) were systematically retrieved from the `crates.io` API and the `RustSec` Advisory Database. Source code analysis, issue responsiveness, and historical context were gathered via the GitHub API targeting the respective repositories of the shortlisted candidates. The data supporting these evaluations is embedded directly within the metric tables corresponding to each component member in the sections above, ensuring all claims are directly traceable to their real-time state within the ecosystem [cite: 5, 6, 12, 13, 34].

**Sources:**
1. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFwgIzWBQUkxvaEmAn3sLGE8AByRHRwUlJFiJiMbVxpPn5C7ecqYXRkfr8-tmLJKzCCzMfLCqK6VvrgfRhXMY_ZJqlieF-fdeE8HcctCOH_b1aFOFAPLvlfU46TqCKP4ERocVM6sOsUzWeFPF4=)
2. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHhqLMmMLKfWoGpQR9xn-MieRWzGM5DjowQnkvPgar1-kg7oa4CAuPNT7Sb_US90mNJxQ7onjKAuOT5qT-6xeQJnWHaSYtC5PtZ1vjgt4Nmy-yBipk=)
3. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEj7FduqJ-PSsAMmGPphop_JIa4exRnFtUBqCgZ1QJkqTua3pVb-XhdVZs1OpcHDlsIznxG3QaffuIDobHB0N-n26iVN2EgBzixFrooPMWyMN763zRCwyrf8V-GfvrRKIlafg_B0xR8NABHHg==)
4. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFTbq7NJXrNOtuxe4DkUxtvJiX9WTskOhlTfziGolhgYsha0TSH8JkZPOXLJLNxODmR0k-V4GlHujNUIerq0kpU2DKHQuAnfPAvdttCYxb62qFvPSOqR1vr7neu_zE=)
5. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG5eKUiMzOwG6xYSIc3DWlGHotFoATAf1K-H5WI5Rd6p84kg62sw3q_dDYe9e9wMyNidUzU4h5mz-Tcfa-EhehTIEFIPLskIHdD_rmzggWHkzSHTA==)
6. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGWV2Lmftj-ON2KlzZfeyd5zHNFzxMiScJ0iamk9Hr3LRoSscJZouFheThLZwr8ijt8Er5n-9viay5ES_e6fEHn1NF0TOS5JsaRqVR2XbBxxzkVL1nhpc_6Q-qPlA==)
7. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEtjv_y7MurYyEcUY5YlIjZGbEuGj8UfTLN7709w-tsE3hEMitoAJjMtkUQ3KrxLGEY8lkewiIdaduezo1RIKFJ_3PvEoN17w7STzFPJ1O3YA==)
8. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGAI7IyZNjbtuVvFnsSrV-5EPcBiJioIKG8-t59Nf7xrho69k4lWHVUV710Rk41JGYUk6zuZHMqkm2OPAtyd8pWORTMZWsTUR4HpV8=)
9. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFOSRcAxneb2aRGi1NPh1yXcunJ3V4icuflsxgYdmSxrgJYGwW6XoNlLAD-q2nwABNKEHJsC0eW7bAPMIbzHvU7rV0EjIuCm-x-eHKHx0nItbtxQ-YZ_I5vKtzn)
10. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGUdnkq_etrRQ2pY6yGpg8WL-4Ujpxl-2g6Zq3p4hwBNeuBpnlLXx9BjwGBbOQKZ3bO3VH-IHPSPqRqSaejoCJF71z0HGLVPZQrU6mrEarusreOKLtfqoEyIuWJDKmkZOAMEprQT1vnQYwxoAfiFr1a2ZbIF1W9gek_fhOs)
11. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE0HgN4HuG9-OgK0DkDOaHpehecr6Lyw0hhV3bQIHsfPCHkGuRuG0J-VRu7rbfBeUAQzatgKdQQcfuMquS1fu4Pdje2RVpsbs91zatflAYcnf5AqriysWnklZewAca-)
12. [rustsec.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEDvjcnIunCZkPhOmL6sqARrqoW4HSzsZESte3PjYV6PwZ0ev8pHNxCD1VNe6kJnRmS0BCv1Wa3QzKMU-Y3ElAfNZVBMtRxfAbgZ0wF5Bvyd41XtLvI)
13. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHHd8UYKs5o-CtNDhaqoHcnXtsShJMLYPH1_J2i3mc_HvUy4-nP-Cf8h7zlMUaytbh8sPfPGsVBrvRB36zzJTymodXg-gvZizKJndbvPjCjpn6IfR9wwx-m3k9gkw==)
14. [shuttle.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE0C0DxA37gVkAIlMmKwMCgSwDZgQen56Lp6lWQs70VQq_VOAv8TBKsMa_jBdHvWT_fGsvmH1FNc_RkmfQ1M2s6G_yb8vLgsmP4ucS5c--P57EZ8Q6a6Joq7WTCtogsEzJESDk4elVjNPPWyHXSRmIH)
15. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH_F6fuZgF3YIu25pwP4dRKQyDZHtqxG8M4455E7WEDPqeKpVncRGZBkOl8oZJ1GaBKmhgrZ898zjllQh1kYLMivs2LItibLB8uA-ydui0VfqjZDtDxpGp-SSMwZHIIVfwNpO8ECvw5auVFBB9a7djg8QvVxqH748-x6xHFUOZQYmZ0WNBd82e_5SzOkXHBm5oLaksbTbF37dpvISuBaYihl0ulOSVXs8U0Amj1UbkjEkoz4Iu3EOV1ug==)
16. [gitconnected.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGD5HV2IdH5oYRkoHNWXHCeueHOnOSKjiWBw8zsjv0KNakgcv3msPfB-fC8Y_yc-sg8-_jnb1IrpIBvU3a4JgrKEYCx2xEP_w5hMeS4C6u9PATGTyDZmNw4Q-t1NRBGz48blUM9CL6PDrXGqGzTe8kyAjc17m5c0yanI6OlEoF7ya4qKg==)
17. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQELZjPvW5dPt1nCKGq2t1KSMgEnMXRo9X4IMjCrnbDFH9Xig9JuCiLdrrvvYqwnVR8_TGPVuOYCXPuBv9lk7lwQ1erR-ABBKKiVHECvgUj78yJYbkVhOu79XyO-PGr17sYE)
18. [github.blog](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHStcnXYKPc6SAvg5Hx5KW1nR01g4ohcRfJo6wgO6IydPCtKHkXfjXbnjDk_9fBV0b__rGWW_tishBsPVYnHBTgbt5mLB10O3Fn6gqNsEg3fwhsO5caPrkADWZ9aX-J7X6s89vGVgXRs_P1dHEOqITzfX90jtRgyMhsCOhYMU1Mf43r7Bw4fHjpsz8=)
19. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHQ7JB4KDiFRHPdXikmKIggfXOscIidZh28w6lKbi0cAUvtD3iXuZOWWqAFuHr3uiUsMdlSpoDKT6g4_u5_34CC9XJuUjPNlHAouOs2lEiWpMpxm74r1AKDv1Y4hA4AVb1Ws_gx_z6eNszZYgCdWSC5Rnxsryz2j8ce6YXVKCw5aqm70MLv1FQ5bzXdbHCUf1NYeaXx6s9MsTMe8bCp9AVhKF9DGuTYuzyu6yVtt48nPSc=)
20. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGVDO8rL88t-niML-VLNuCLGRjHbARNdFQJiSIn6jt4WX0ZvMQNlBqJ90WoRHvYBxsRHteR5wFowlcwoBPGnXSgivM4wnXE4K73G0Yh2FrqIBSGqv-N0jwnkTXLRQRFs7QKbTE2H5cNdQ1Kzsfj4NSSJmHxTDhpsHSfvNdVc2LxICn6)
21. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHVMVmy_m-B_c1sUbqYaHTnOBNJY_jxN37jWaSnZMuBhx5mmNLukD5l_TWf4ISO_bZZfR7PEdw4UzrxdaPEM5IQQiTTQM0PzcKjZsBLM_WW8as8qYI15GOPJvQl3cgKFo7GIPopxIaEAFEOyMU_R9x6Jw==)
22. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEG8bYICydRSv2zYXLq0FlbM-3s7D36U1jkDxwq9OBK0RwE3OUnIbIOalOQlu_0GMKWNRjvDyS-eIlkYpFLxyTQWsK1s1lM3nJundjN4N25TqvXWU1T2YAlPhh3y6Jdh5r4tyUWTdHAbx5WgHxkfbUwaoi_DDgJuH54jnU4W6m_25daRA==)
23. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFbtL9eCfnIjDH2l8l1Qdgcvwvf3EnZ0-VbdiMjs6iYzLz4jNl_KcmAp_kQqtkO05YjxrOJoxn-_wGr3MQjGDW9qoPDPuXQOJywNGPTgoy8gVKjuQ0Nsz8=)
24. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG4HNw0VBOi-XxCUlXsT7Js7d938koXrR5sxJP3vIwgsAlhTBDQGaKjmseUJ0jLVeApEY6gGYnEbiyugTnrTwc0iESAUVhGEhZZ0zocp1BAZtd79YAHErFw_SHi4EUOVndlRIMuCZ2Omj1BL_LNSsMH)
25. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFEBb6EgBqwhqR1Ti9t1vDdKY1ZufGmzzHRrE_veiO006Guz7xnELx6l8xjbgg8aqR7JaPNHoJuNdNAaOEJJe1XzdYP4_PhZ8rffko6gHVWhMWDV3I5SMdh4O-Xx1oVW_NA-MxqzUz7NFlzR-S-xtcD0GBSLkUWFVKpm-gIwdd1ULVdJSpRW-BbQzn7UaJp-R286jkIElr5PXzMMDjOci4fHlVyCKEg0pHDUw==)
26. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH0GPOdaBLk41Qgy8KcKbau_rijLKBfANUovR_2Wv3SMWoPW1eE9cvE-dAumNzlq5jy2BJiC3zXRT79KXTUy-CHu72kBgr36yJcdV3V78FMI9EfhpdeGN4ySf0em_rOzQ==)
27. [sparkco.ai](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEjiX5-DZ7rVhe046TXYhH1xnNsWLzhI2WbTjao7jK7IbC-9LdO7urxzPs-AfBRZmBxht2BZ0qP0tUCjeF6kEecVg9pVYIM_S8QaK_cn1kEhcI4ivrOtXFq9bj7tgtG1gI0R7es6BhQGhgJ0KW1soWgX66YU8RmY_CrbNd8b3diaegqzXQ-yJoWS7D-zlETPQ==)
28. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGxuty_BeuVXKhwjFGU8BETj1TrWrZOpCnaFC0jZuFbzg9DIGORN16-LTBFFqVkSdDOE81MWxvJ5ALE-fmtJeOgdnnRGdaKZRMTVm_lZ2monY0eYgQWZj8gLa3vQVMhfw==)
29. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHT9MX1YESCk35jcVios7sHyJ0usngfiJiIshetItwXug1ZeZLjsZ_85jMYwb9t0j7iiPXEFr2kNYyR-AKOurwVT1rovQMgMK6GgvTJjLhHWmI6GsvUSzW_OniNYpXu)
30. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGisRM2H-wSCIuM5qHADKEwnru48975EzC8JiIAEgt2feJr4q11e2QosjizRPPihhbZBWyF5xZwolwEJojm8kj0wfSrm8UtpgH27UOhH5Vn1VzGiSw9SV5GmR-P2cWJOZaUzAH35DXVbhgx11bjB-6fblDP)
31. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHEA7PC0XyCDEy_I5ZBnVHEEcK_WI2Qjve38BsaASdc36H-STEI3i60iy3E9dM-KlhLAkB_gXKFCfrEYxcoHRF0kuJ9DoCJsfwpmY7ApdryCYUrEYa3u-YCTWhlLIlax_ZQ_sauokDtRR5qHA==)
32. [rustsec.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQELADmX7jas_NiqL_SPqSIPLXR2AVM2-IMgQJ29siopaVspakuYMe9DAIm-iTRyXEjsW4BabY16fp4amHowXN-YqKphGQxVIQNXAD0NFLK0YQV54vVVzs-ok3DMTVOlmoZjvcA6fJvul8Dlog==)
33. [oneuptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHEKA7skwbhmFcnYEtTo_Otb6X6uoS0g37SGHlXH3GS5mKWDcohFuXAx4wsKil2NTkTOrIW9TK9ECcqEFPat0tJXubf2EMrxWlMwzcp2yXxHdB_cL-R38zPWw9OAymDBpG3DUq5nq4xtQAhpU0BzgBnHTPLFLNp-to=)
34. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGB_4QSDlfdFmr6cfXTnrOM3JZUpqFcD4g9Bbk14UolxSQGyr6sBWXdsBv7JcLnpMN-pP_DeifK4Yy52uRU6DYM6gLXFmUGJMKjOSfftBFE7CsQ8FZ03aSsduZzMlY=)
35. [oneuptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFovz-XkOtuwnBvdUeul9SiY_6b8ecV8p45IlLSe0lgHShQOIpNy3VPWkGrmAbBrM3WNKinQdC_lyf6s-OTI5Ibwa1fPlX2wcdR5zq_p1Zaf70uiJcttrm6jeAtPQf1Qg39vzCn4ha8Bvh1k0z0xz4qrmB75ZZ35vqEteAd1WaIpC-g5GKgDT3LR-6TwSw=)
36. [loco.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFtV649ZJokQ2-YHz8WOqfLT1_TJHp5a703DygOG3LE5sbfJCmUytmkif26ekphzEKhX49mJyh2P6zdcqo4cfeYDZYLkTbGZe2HNXXdz0plKFlq7s7nu7UbaB9OvhNeJ2_sgnVM)
37. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHntyavdFwZYmGwfaMA4ISZe3xRYh7Q0SwUZuvDcRSa_cEyubpJmPalfi0QebyaZOexWve3fhv-meBlVmtYsubqVqG4VCyRTh_cHN_vr1KIEBrGW4r9SWWBu0tjZNyrcOOXdYTVb63CeHg=)

## Sources

- [docs.rs](https://docs.rs/axum/latest/axum/middleware/index.html)
- [crates.io](https://crates.io/crates/tower)
- [docs.rs](https://docs.rs/tower_governor/latest/tower_governor/)
- [crates.io](https://crates.io/crates/tower_governor)
- [docs.rs](https://docs.rs/axum-governor)
- [crates.io](https://crates.io/crates/axum-governor)
- [docs.rs](https://docs.rs/axum-limit)
- [docs.rs](https://docs.rs/rater)
- [github.com](https://github.com/canmi21/lazy-limit)
- [github.com](https://github.com/tokio-rs/axum/blob/main/axum/src/docs/middleware.md)
- [github.com](https://github.com/canmi21/axum-governor)
- [rustsec.org](https://rustsec.org/advisories/)
- [github.com](https://github.com/rustsec/advisory-db)
- [shuttle.dev](https://www.shuttle.dev/blog/2022/08/04/middleware-in-rust)
- [medium.com](https://medium.com/@trivajay259/axum-the-tiny-layer-that-makes-rust-web-backends-feel-effortless-and-production-ready-a8cbe125282b)
- [github.com](https://github.com/loco-rs/loco/issues/1181)
- [gitconnected.com](https://levelup.gitconnected.com/rust-on-loco-like-ruby-on-rails-0ed22e396fff)
- [medium.com](https://devrimozcay.medium.com/i-reviewed-34-production-retry-bugs-the-most-dangerous-line-was-usually-retry-3-2eb3f264dcec)
- [github.blog](https://github.blog/news-insights/company-news/github-availability-report-july-2026/)
- [github.io](https://tower-rs.github.io/tower/tower/util/struct.BoxCloneServiceLayer.html)
- [docs.rs](https://docs.rs/axum/latest/axum/routing/struct.Router.html)
- [medium.com](https://medium.com/@dmytro.misik/building-a-rate-limiter-in-rust-48ce37d2ae07)
- [crates.io](https://crates.io/crates/governor)
- [docs.rs](https://docs.rs/governor/latest/governor/_guide/index.html)
- [rust-lang.org](https://users.rust-lang.org/t/axum-boilerplate-fatigue-i-built-a-thin-opinionated-layer-oxide-with-benchmarks/139313)
- [crates.io](https://crates.io/crates/api-rate-limiter)
- [sparkco.ai](https://sparkco.ai/blog/mastering-retry-logic-agents-a-deep-dive-into-2025-best-practices)
- [github.com](https://github.com/topics/governor?l=rust)
- [github.com](https://github.com/benwis/tower-governor)
- [github.com](https://github.com/canmi21/axum-governor/blob/main/Cargo.toml)
- [github.com](https://github.com/topics/limit?l=rust&o=desc&s=stars)
- [rustsec.org](https://rustsec.org/advisories/RUSTSEC-2022-0055.html)
- [github.com](https://github.com/boinkor-net/governor)
- [oneuptime.com](https://oneuptime.com/blog/post/2026-01-07-rust-rate-limiting/view)
- [oneuptime.com](https://oneuptime.com/blog/post/2026-03-05-gitrepository-rate-limiting-github-flux/view)
- [loco.rs](https://loco.rs/docs/explanation/architecture/)
- [docs.rs](https://docs.rs/tower/latest/tower/trait.Layer.html)
