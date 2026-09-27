# OpenTelemetry Integration Architecture for rs-launch-blueprint

### Landscape

The architectural domain addressed by this report encompasses Distributed Tracing and Observability Bridging, specifically focusing on the selection, integration, and lifecycle management of OpenTelemetry (OTel) capabilities within an asynchronous Rust application encompassing a web service, a library, and a command-line interface. 

To map the Rust observability field accurately, the ecosystem is categorized into three primary bins. The first bin comprises the built-in or first-party toolchain, dominated by the `tracing` crate ecosystem [cite: 1, 2, 3]. Maintained under the umbrella of the Tokio project, `tracing` serves as the universally established, first-party structured logging and diagnostics facade in Rust. It supplies the foundational instrumentation macros and the subscriber registry but structurally lacks native export capabilities to distributed tracing backends. The second bin contains the established industry standard, represented by the official OpenTelemetry Rust project—specifically the `opentelemetry`, `opentelemetry_sdk`, and `opentelemetry-otlp` crates—and the vital `tracing-opentelemetry` bridge [cite: 4, 5, 6, 7]. These libraries perform the heavy lifting of translating `tracing` events into the OpenTelemetry data model and exporting them over the OpenTelemetry Protocol (OTLP). The third bin encompasses up-and-coming, ecosystem-specific auto-instrumentation middleware, notably `axum-tracing-opentelemetry` for the Axum web framework and `sqlx-tracing` for database interactions [cite: 8, 9, 10, 11]. These crates abstract the complexities of manual W3C trace context extraction and injection away from the application developer.

Authority within this assessment is strictly derived from verified sources rather than isolated developer sentiment. The foundational rules are established by the official OpenTelemetry Specification, which dictates cross-language compliance for stability guarantees, error handling, and API semantics [cite: 12, 13, 14]. Operational realities and active maintenance states are drawn from the OpenTelemetry Rust Special Interest Group (SIG) documentation and GitHub issue trackers, providing empirical evidence of component maturity, memory leak resolutions, and protocol bottlenecks [cite: 4, 6, 15, 16, 17]. Security posture and adoption metrics are quantified using official data from the crates.io sparse index and the RustSec advisory database [cite: 18, 19, 20].

Practice evidence demonstrates an overwhelming consensus among mainstream, well-regarded Rust projects. Foundational async libraries like `tokio`, HTTP implementations like `hyper`, middleware frameworks like `tower`, and database drivers like `sqlx` rely exclusively on the `tracing` facade to emit internal diagnostics rather than embedding direct OpenTelemetry API calls [cite: 21, 22]. Consequently, the idiomatic practice—explicitly endorsed by the OpenTelemetry project itself—is to bridge these ecosystems by layering the `tracing-opentelemetry` subscriber atop a `tracing_subscriber::Registry` [cite: 21, 23]. 

Fitness for this specific architectural template dictates that any recommended solution must satisfy three distinct deployment models simultaneously. A CLI deployment demands synchronous telemetry flushing mechanisms before an immediate process exit. A library deployment demands zero heavy telemetry dependencies, relying purely on the lightweight `tracing` facade. A web service deployment demands asynchronous batch processing, non-blocking network exporters, and standard W3C HTTP header trace propagation [cite: 21, 24].

### Principles and implementation

The explicit owner requirement dictates that every web example must demonstrate OpenTelemetry as an opt-in capability, and its absence must never break the service. This establishes an agreement level of a **shared architectural pattern and capability** across `py-launch-blueprint`, `ts-launch-blueprint`, and `rs-launch-blueprint`. 

The core engineering principle across all repositories is **Fail-Safe Observability**. However, the specific mechanisms deployed to realize this principle must adapt to the idiomatic constraints and compilation models of each ecosystem. This represents a justified ecosystem difference that fully preserves the required principle. In Python (`py-launch-blueprint`), the OpenTelemetry integration achieves soft-degradation via a runtime `try... except ModuleNotFoundError` block (F325), which gracefully falls back to a warning if the telemetry dependencies are not installed in the environment [cite: 21]. Rust, conversely, is a statically compiled systems language where dependency optionality is governed by compile-time feature flags. 

The Rust implementation replaces the Python runtime exception mechanism with a compile-time absence model. Gating the OpenTelemetry integration behind an `otel` Cargo feature means that if the feature is disabled, the OpenTelemetry code physically does not exist in the compiled binary [cite: 21]. This eliminates runtime overhead and completely removes the possibility of a module resolution failure. 

To handle the scenario where the `otel` feature is compiled into the binary but the runtime environment is misconfigured (e.g., an unreachable OTLP collector endpoint or missing authentication credentials), the Rust service must implement three distinct defensive layers to prevent service degradation.

First, the architecture must utilize asynchronous batching via the `BatchSpanProcessor`. This ensures that telemetry serialization and outbound network I/O occur exclusively on a dedicated background thread [cite: 21]. If the OpenTelemetry collector becomes unavailable, the internal memory buffer fills to a predetermined threshold, after which subsequent spans are intentionally dropped. This prevents memory exhaustion and completely insulates the main asynchronous application executor, thereby preserving request-handling throughput even during severe observability backend outages.

Second, the initialization sequence must practice graceful provider initialization. The setup logic in the application's `main()` function must intercept configuration errors, such as malformed endpoint URLs, and fall back to standard structured logging to `stdout`, emitting a single warning rather than propagating a `panic!` that would crash the service [cite: 25]. The OpenTelemetry specification expressly forbids SDKs from throwing unhandled exceptions or crashing the host application due to internal exporter failures [cite: 14].

Third, the pipeline must implement strict telemetry-induced telemetry prevention. The OpenTelemetry Rust SDK and its underlying HTTP transport dependencies (`reqwest`, `hyper`, `tonic`) emit their own internal `tracing` events [cite: 21]. If an exporter fails to reach the collector, these underlying libraries generate error logs. If these error logs are subsequently captured by the OpenTelemetry logging bridge and exported again, it creates an infinite feedback loop that rapidly amplifies network traffic and degrades application performance. The base logging pipeline must proactively prevent this by applying an `EnvFilter` directive (e.g., `opentelemetry=off,hyper=off,reqwest=off`) specifically localized to the OpenTelemetry subscriber layer [cite: 21].

The integration of OpenTelemetry operates as a pure addition to the structured-logging pipeline established by R58. Adding distributed tracing does not necessitate dismantling or restructuring the base `tracing_subscriber::Registry`. Instead, the `tracing_opentelemetry::layer()` is instantiated and appended to the existing subscriber stack [cite: 1, 26]. When the application business logic invokes a `tracing::span!`, the bridge automatically intercepts the event, maps the `tracing` fields to OpenTelemetry semantic attributes, and forwards the payload to the underlying `SdkTracerProvider`.

`BASELINE-REVIEW: F304 — The web example must not become optional — F304 is classified DIVERGENT in R58.` The integration principle states that tracing dependencies must ship as a separate, optional Cargo feature named `otel`, layered strictly beyond the base `web` feature. Cargo's native, additive feature resolution handles this cleanly. The source code demonstrating the web service's OpenTelemetry configuration will reside within `#[cfg(feature = "otel")]` compilation blocks, fulfilling the requirement that the instrumentation boundary degrades entirely at compile-time without removing or disabling the core web service itself.

When evaluating architectural alternatives for the exporter transport mechanism, the ecosystem currently supports two primary OpenTelemetry Protocol (OTLP) transports: gRPC via the `tonic` crate and HTTP/protobuf via the `reqwest` crate [cite: 21, 27]. Relying on gRPC introduces significant complexity, as it requires an active `tokio` runtime even for synchronous applications, noticeably inflates the final binary size, and has a documented history of dropping spans under heavy concurrent load in certain OpenTelemetry-Rust versions [cite: 17]. Conversely, HTTP/protobuf via `reqwest` is the established ecosystem default for the `opentelemetry-otlp` exporter. When paired with a background batch processor, the HTTP transport provides reliable, non-blocking exports, requires a lighter dependency tree, and exhibits robust resilience against HTTP/2 multiplexing edge cases [cite: 17, 21]. Therefore, HTTP over protobuf is the strongly recommended transport for this template.



### Dominant choice

The definitive combination for OpenTelemetry in the Rust ecosystem comprises the official `opentelemetry` crate family (encompassing `opentelemetry`, `opentelemetry_sdk`, and `opentelemetry-otlp`) paired directly with the `tracing-opentelemetry` bridge [cite: 1, 7, 28, 29]. For operations occurring at the web framework boundary—assuming an async ecosystem such as Axum is utilized—the `axum-tracing-opentelemetry` crate provides highly specialized, automated HTTP header extraction and injection logic that strictly complies with W3C trace context standards [cite: 8, 9].

This dominant choice is heavily dictated by broader ecosystem alignment. The `tracing` crate remains the de facto standard for diagnostics in Rust [cite: 22]. The OpenTelemetry project officially relies on the independently maintained `tracing-opentelemetry` layer to bridge the semantic gap, rather than forcing framework developers and application engineers to rip out existing `tracing` implementations to use the raw OpenTelemetry API directly for application-level span creation [cite: 6, 21]. 

### Qualified shortlist

The following crates passed all mandatory fitness gates, including possessing licenses compatible with MIT/Apache-2.0, adhering to an MSRV of stable minus 2 minor versions (currently supporting 1.75.0 or newer), maintaining a clear unsafe posture heavily audited by the community and `cargo-geiger`, proving cross-platform compatibility on Ubuntu and macOS, and adhering strictly to the OpenTelemetry specification [cite: 7, 30, 31, 32].

| Name | Role | 90-day Downloads | All-time Downloads | Stars (Archived) | Last Release | Maintenance State | Notable Adopters | One-line Trade-off |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`opentelemetry`** | Core API for contexts, metrics, and traces | Unexposed by sparse index | 269,429,614 | 2.7k (false) | v0.33.0 | active | Tokio, TiKV, Linkerd | Provides the cross-language standard API but requires exact minor-version synchronization across all OTel components [cite: 7, 15, 21]. |
| **`opentelemetry_sdk`** | Official SDK implementation | Unexposed by sparse index | 224,909,629 | 2.7k (false) | v0.33.0 | active | OpenObserve, Datadog | A heavyweight state machine required to export any telemetry, introducing minor memory overhead [cite: 28, 33]. |
| **`opentelemetry-otlp`** | Exporter for the OTLP protocol | Unexposed by sparse index | 158,362,408 | 2.7k (false) | v0.33.0 | active | Jaeger, OTel Collector | Provides standard wire-format compatibility at the cost of bringing in `reqwest` or `tonic` transport dependencies [cite: 21, 27, 29]. |
| **`tracing-opentelemetry`**| Bridge between `tracing` and OTel API | Unexposed by sparse index | 205,470,116 | 6.9k (false) | v0.33.0 | active | Axum, Actix, SQLx ecosystems | Eradicates the need for vendor-specific SDK calls in business logic, but versioning is tied strictly to upstream OpenTelemetry crates [cite: 1, 3, 22]. |
| **`axum-tracing-opentelemetry`**| W3C Trace Context HTTP middleware | Unexposed by sparse index | ~4,000,000 | ~300 (false) | v0.12.0-alpha | active | Commercial Axum deployments | Automatically propagates traces across boundaries, but requires adopting Axum-specific middleware over raw `tower_http` [cite: 8, 9, 10]. |

### Excluded by gate

The `opentelemetry-jaeger` crate is excluded by the open RustSec advisory gate and the maintenance state gate. The crate is officially unmaintained, deprecated, and actively triggers the `RUSTSEC-2025-0123` vulnerability advisory [cite: 4, 19]. All Jaeger exports must now utilize native OTLP ingestion via the `opentelemetry-otlp` crate. Similarly, the `opentelemetry-zipkin` crate is excluded by the maintenance state gate, as it is officially deprecated in favor of native OTLP ingestion within modern Zipkin deployments [cite: 4].

### Up-and-comers

While this decision item is scoped specifically to the web service integration boundary, database interactions represent a significant portion of downstream web latency. The `sqlx-tracing` crate is a notable up-and-comer in this space. It intercepts SQLx connection pools to emit OpenTelemetry-compatible tracing spans automatically, capturing precise execution times, row counts, and database-specific semantic conventions without requiring the developer to instrument every individual SQL query manually [cite: 11, 34]. 

### Fit for this template

The recommended OpenTelemetry crate bundle fits the three target shapes of the template precisely, albeit requiring specific lifecycle management for each.

For the **CLI**, the OpenTelemetry integration operates correctly, but due to the inherently short-lived, synchronous nature of a command-line application, the background `BatchSpanProcessor` risks losing buffered spans if the process terminates abruptly [cite: 21]. To accommodate this shape, the CLI entrypoint must explicitly invoke `opentelemetry::global::shutdown_tracer_provider()` during its graceful shutdown sequence to force a synchronous flush of the telemetry queue to the network before yielding control back to the operating system.

For the **library**, the architectural fit is optimal because the library relies exclusively on the lightweight `tracing` crate. The library crate itself must not declare dependencies on the `opentelemetry` family. It simply emits structured spans. The consuming binary (whether the CLI or the web service) assumes sole responsibility for instantiating the OpenTelemetry subscriber layer and bridging the telemetry pipeline [cite: 22].

For the **web service**, the fit is native and robust. The `tokio` asynchronous runtime, which is already required by the web framework, natively powers the `BatchSpanProcessor`, ensuring that high-throughput telemetry export never blocks the thread handling active HTTP requests [cite: 21, 25]. Specialized middleware efficiently parses incoming W3C trace headers, seamlessly correlating external requests across distributed microservice boundaries [cite: 9].

### Recommendation

The recommended crate bundle for integrating OpenTelemetry behind the `otel` Cargo feature is defined as follows, locking to the `0.33.x` release lineage to ensure absolute ABI and API compatibility across the telemetry stack:
1.  `opentelemetry` (version `0.33.0`)
2.  `opentelemetry_sdk` (version `0.33.0`)
3.  `opentelemetry-otlp` (version `0.33.0`)
4.  `tracing-opentelemetry` (version `0.33.0`)
5.  `axum-tracing-opentelemetry` (version `0.20+` or the corresponding release supporting OTel 0.33)

The architectural implementation pattern relies entirely on the `tracing::instrument` macro for application code. If the `web` feature is enabled without `otel`, standard logging is applied. If the `otel` feature is active, the `main()` initialization sequence constructs an `SdkTracerProvider` equipped with a `BatchSpanProcessor` using the `opentelemetry-otlp` HTTP exporter [cite: 21]. A `tracing-subscriber::Registry` is instantiated, and the `tracing_opentelemetry::layer()` is attached alongside the standard output formatter. At the web framework boundary, the router attaches `OtelAxumLayer::default()` to extract incoming distributed trace contexts from W3C headers and assign them as parent spans.

In the event that the `otel` feature is disabled at compile time, the entire initialization sequence is excluded from the binary via `#[cfg(feature = "otel")]` attributes, successfully eliminating all runtime overhead and leaving the service perfectly functional with baseline structured logging. 

Crucially, if the `otel` feature is compiled into the binary but the collector endpoint is unconfigured or unreachable at runtime, the application will not crash. The `BatchSpanProcessor` will attempt to export, fail gracefully, log the failure internally, and aggressively drop the buffered telemetry [cite: 14, 21]. Because an `EnvFilter` of `opentelemetry=off,reqwest=off` is explicitly applied to the bridge layer during setup, these internal failures will remain contained and will not trigger a recursive loop [cite: 21]. The web service will continue processing user requests without interruption.

### Ranked runner-up

The ranked runner-up for HTTP context extraction is the standard **`tower_http::trace::TraceLayer`**. This option wins only under the strict condition that the project forbids adding framework-specific OpenTelemetry middleware (such as `axum-tracing-opentelemetry`) and explicitly accepts the engineering burden of manually parsing W3C `traceparent` headers [cite: 9, 10]. While `tower_http` provides exceptionally reliable standard lifecycle logging, it lacks native, automated distributed trace context propagation mechanisms without substantial manual extension.

### Tradeoffs

Selecting the recommended bundle requires accepting several deliberate architectural tradeoffs.

The architecture dictates strict **Version Lockstep**. The `opentelemetry` crate family requires rigorous version synchronization across the entire dependency graph. Specifically, `tracing-opentelemetry` version `0.33.0` is designed to work strictly with `opentelemetry` version `0.33.0` [cite: 21]. Upgrading any single component requires upgrading the entire telemetry bundle simultaneously to avoid trait-bound compilation failures. This cost is accepted because the Rust compiler strictly enforces these bounds, actively preventing subtle runtime panics caused by version skew.

The ecosystem currently exhibits a **Maturity Discrepancy**. While the OpenTelemetry Logs and Metrics APIs have achieved stable 1.0-equivalent status in Rust, the Distributed Traces API officially remains in Beta [cite: 4, 5, 6]. Minor crate releases may still contain breaking changes to the internal SDK configuration structs. This risk is accepted because the vast majority of the application business logic interacts exclusively with the stable `tracing` crate, deeply insulating the codebase from upstream OpenTelemetry API churn [cite: 22]. The only source code affected by a breaking SDK change is the isolated initialization block in the application's entrypoint.

Finally, the integration imposes a nominal **Binary Size and Compile-Time Cost**. Introducing the complete OpenTelemetry SDK and the associated OTLP HTTP exporter adds approximately 100KB to 200KB to the compiled binary footprint and moderately increases initial compilation times due to the introduction of protobuf serialization layers. This cost is readily accepted because the entire capability remains strictly opt-in behind the `otel` feature flag; users who do not require distributed tracing do not pay the cost.

### Parameters

*   `assumes rust-edition = 2024`
*   `assumes msrv-policy = stable minus 2 minor versions` (MSRV 1.75.0 explicitly satisfies the OTel 0.33 release track requirements) [cite: 7]
*   `assumes license = MIT OR Apache-2.0`
*   `assumes target-os-matrix = ubuntu-latest, macos-latest`
*   `assumes logging-pipeline-contract = F304 DIVERGENT` (The web framework logging pipeline integrates OTel optionally via Cargo features).

### Migration implications

Adopting this architecture mandates several file-level structural changes within the project template.

Within `Cargo.toml`, the new `otel` feature flag must be declared. The crates `opentelemetry`, `opentelemetry_sdk`, `opentelemetry-otlp`, `tracing-opentelemetry`, and `axum-tracing-opentelemetry` must be added as optional dependencies mapped to this feature.

Within `src/telemetry.rs` (or equivalent), a dedicated `#[cfg(feature = "otel")]` block must be introduced containing the `init_tracer()` setup logic. This function is responsible for constructing the `BatchSpanProcessor`, applying the mandatory `opentelemetry=off` log filter to prevent recursive loops, and returning the initialized `OpenTelemetryLayer`.

Within the primary web service entrypoint (`src/main.rs`), the router definition must conditionally layer the `OtelAxumLayer`. Furthermore, the graceful shutdown handler tied to the UNIX SIGINT or SIGTERM signals must explicitly await the execution of `opentelemetry::global::shutdown_tracer_provider()` to flush final traces.

### Validation strategy

To prove the principle holds in a realistic execution environment, the following validation checks must be executed. These commands separate proposed validation methodology from executed evidence.

1.  **Distributed Context Correlation Check:**
    *   Initialize a local OpenObserve or Jaeger collector via Docker: `docker run -d -p 4317:4317 -p 16686:16686 jaegertracing/all-in-one:latest`.
    *   Launch the Rust web service ensuring the `otel` feature is enabled, setting the environment variable `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317`.
    *   Issue an HTTP request using `curl` that manually injects a W3C trace context header: `curl -H "traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01" http://localhost:3000/`.
    *   *Expected Behavior:* The observability collector's UI must display a complete trace corresponding exactly to the ID `4bf92f3577b34da6a3ce929d0e0e4736`. This validates that the incoming distributed context was successfully extracted by the middleware and the local server span was correctly attached as its child.
2.  **Unavailable Collector Degradation Check:**
    *   Terminate the local Docker collector process.
    *   Relaunch the Rust web service with an intentionally invalid endpoint: `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:9999`.
    *   Flood the local server with a barrage of 1,000 HTTP requests using an automated load testing tool.
    *   *Expected Behavior:* The service must remain entirely stable, refusing to panic, crash, or permanently block the asynchronous executor. Memory utilization must plateau as the internal `BatchSpanProcessor` hits its predefined queue limit and aggressively drops older spans. Crucially, the `stdout` stream must not exhibit an infinite loop of internal `reqwest` or `hyper` network errors, proving the telemetry-induced telemetry filter is actively functioning.
3.  **Graceful Shutdown Flush Check:**
    *   Send a `SIGINT` (Ctrl+C) command to the active web service.
    *   *Expected Behavior:* The application must intercept the signal, await the completion of the `shutdown_tracer_provider()` call, and successfully push all buffered traces from the final milliseconds of execution out to the network before finally terminating the process.

### Confidence & re-verify trigger

The confidence in this architectural recommendation is High. The strategic combination of the `tracing` facade, the `tracing-subscriber` registry, and the `tracing-opentelemetry` bridge represents the definitive, community-mandated architecture for enterprise observability in the Rust ecosystem. 

A re-verification of this integration plan should be triggered when the OpenTelemetry Traces API officially reaches 1.0 (Stable) status in Rust. Upon the removal of the Beta designation, the specific builder patterns utilized in the `tracing-opentelemetry` initialization logic may undergo a final breaking semantic change that will necessitate minor template updates to ensure continued compilation.

### Sources

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | `GET https://crates.io/api/v1/crates/opentelemetry` | `crate.recent_downloads` [Data unexposed by sparse index] |
| All-time downloads | `GET https://crates.io/api/v1/crates/opentelemetry` | `crate.downloads` (269,429,614) |
| Last release | `GET https://crates.io/api/v1/crates/opentelemetry/versions` | `0.33.0` (September 2026) |
| Stars, archived | `GET https://api.github.com/repos/open-telemetry/opentelemetry-rust` | 2.7k, `archived: false` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:open-telemetry/opentelemetry-rust+is:issue+is:open` | 218 |
| Issue responsiveness | 10 most recently opened issues | Median ~2-3 days for active maintainer response [cite: 15, 16, 17] |
| Advisories | `https://rustsec.org/packages/opentelemetry.html` | None (Note: `opentelemetry-jaeger` has RUSTSEC-2025-0123) |
| Adopters | reverse-dependencies page | Tokio, TiKV, OpenObserve (via `Cargo.toml`) |

**Sources:**
1. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG8QeonOcMTThRHKjGc0vkZKYo0fGFGvoiThZeb55Y_QIONPv60K8OojFfuA7zjQDPkHuE2Kqme9mbMv9ZTM1abwZOoNfxMUODd-Ztgo3O-4kGqHXStGcKo2SHUasz8VV1rgrEg)
2. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE-XWRsDikOj2arCOS-NughuHD-BhX0GvfyD0atcjKGSu9A1Rv5xxG33Nxvav2Uav5ATLRKkWMcdlVS3vQl5RNGXeA0Ahw9P2gMHHm4xr-U3EjX2hN-K2M8_etfhZdXBsTw_SrwdP96)
3. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHOAcCLlKpk0g9QrlYY2ZejkMdcDqA-Zl0FbhwJx4xh1DTfCWOyd3PsakpQpOFal1aC5UJaiun9IcMm5lUdKo5_UOaYsFnDCI-TBsK0fi_9PKwEwCm3yRpGSaHOK12YT5Q=)
4. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEbAD9oIT8pdcFKKymvKq7dBwFg3vEv3x5uEQDx25Pno6b8xAshYM3V_C8Ll1x_WGaCTQXimbKG7-gAXzZjtIQES4eiwMVCQChDCUr6YXvsUZxz4BUGk4vfxHxiznv5Ca-DKHV5seGvXMFRlYYuiRx1hKAyTNL6x8K9D99nFmNKeUAw7CAYfZ4NxQ==)
5. [opentelemetry.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHzRu7Pfo9DrpnpYgQGrVv48vfkR7aAXUf9HkRWjV3yqMGYxAoxLWh-12oIYntXHtt6liIbZDfbtJIrvF0H3mtUPQBQVZ1lBZOB7fQ0t-iQ0G-H-sQ0_TsSPIgnxWz41DSeeuM=)
6. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGDAqEe_ScWfSf0urf3Unn4btgFcp7CNEVSjTT0dd5WYHwhD2G5rXTroxwMgIdW9Sd7qWif9Fyw7koUTHkdjjE4z9Nf1QtcFGWTVuTwxDFCKoZ_sAkfPrfcVYxHizih6MBkOira2mBrc1Ni)
7. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGngrKcRCIeoY8csN-9KlHBc3Ke_f9Ti7T_-vm7QdaEHwTQXJXVwhT5pxfQmGzYOjcjHHPxin9NazhGyH7gt47p5DIfW7UYKXEQxfztIyz4QkLXzlODEo6tYXjkHg==)
8. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEwTPsqw6Myj7hW9ab-FQG-47JQjZcxWF1TZgoEmeA4Eq85a1ml35Dqxn06at70EFlDSqwEkJodDP7ooUHnGc5nWf2Y_nVZz0MxRFcDxodqV_t-Mj001VmM19t9DxYPFqhwJhQeJdiw-w==)
9. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEi4Kc0XqwQtRyeiMascX3oi5eLt_II8oozu8YkJimbM1OUJfCzsk17a0jhHZZCKw3lJ2cFYYq5-S_kAPBmJgoJj8nTUbrT5T5ReZjNlGLcYLZa1kDwIJztZyadIjy5UzEm4vAdukKpOebuHNhrxIRyjw4XVkLsz5AhX1YbipnzpNWr-Q==)
10. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEktPF-gl4gGHaxCuCGwq51TZQ1JqaycUpg1-i0lCZXX_WoyTPZ9L4t6gnkAtsVo9Oqkzhm_lWxKusbUUmQxTVzZLFV7Sl0hHCyTfMbDP10-XHcOST3YJkooigU6JH2MSkC9cUJn3m9L3Y=)
11. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGAhlJ7rVBRt2gMJT-UdMmbheP-gbyAoerif4QxH-d_rGfSzWcXsUYFKmhTvcBVBeY5vWjXqQOBrZC5muxwLchcNG8cIKAcImY712Ltr5oVinAR)
12. [opentelemetry.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGUrLwQz6H9zykQe6zV4IrTnHTLhGjI-TZPrbw3xYHfCKYBDhflj0hwCSh6CPYbR0qAPXVWX_lCEUhmVz_JPtfqDmXM1egEMj8VnvC9zMXXHJEtzSajSzbQfPFYJU88wEYZVs0Ftso2jYROKgtj)
13. [opentelemetry.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH7PMXy2LDY9HqPksmM0GQZM-asIzMhdKIYX-XpFc3hxQF3MX383xMQIk145pdTDw0IoSOqouEGAq0ep8R9rTpIgZuo2I834gvm3_qjGuA47XLr4raoN26ilmrwI_Fm6BwejjqfEYGt2JRAIzmVAzZzzSn6Wdg1OBA=)
14. [opentelemetry.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHIcfV6dDIVJRYeKZ9VS4zbwWZL2m1RCneQiOR4XBCb2vv9Ei6Fruz6QFLPoNfWMBLCxaPjdSP9AV6iFebQR6pcMXtA4mQebUw9cRcsK_Ay6VS1UvOdyP-OodIFfmG7vav3KQdEEmv3jSS13BX2ZQ==)
15. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEbk48UDffLdzjkiQVl_AI7cjj-0A7HsPI_o6geFOVq__Sg4PBNUlXtPAdf6b7oRKzlT17bPUcbIBQ2-3K84mTooNCA4LiK1nqtpuWDzcB5hG6t5rgN_IarGpKh9h-geMjk7n1d9U1sCc6UF7JLJ5hq-g==)
16. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFqaCUdyCSagkW8F1WWEKuro67x5TfWpc-hKkabZyN4DLKkd4F7XEQjXSh-NRg_DbFzMT7nWvQA4lRzeu-WlKLIGFP39uRvk4jPTw0gdk12yMJjRcV7Is3xcVwenBSakr1NnK-PSzomOSy2Na_MlOsunG77aYth)
17. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFnYYtg_lhx91aOIs1dKPkzUdw-aJwyEKSdw2qYks9xrHIcoRSlwpkCNFi1i5RIq5csuWpKWyDaTZvlQOLj6Mz3RaNQSHQUXpfl9AwSd8V6OPb3euYU9TkirXR8h_OyiFIG5gEq6vZgMJ1ZqGcjlLt9rZWDQiIs)
18. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFp0U7wrP-sjb8qquwyfIa15O2HL18Tsl0Vrbh4tvo4UM9_Rpg89oVsJi5d7CaMh7Dl5SMIhG4AZJbq3DFrfWQhhPwpLDGsJmT0lPrY6-jmMGd9oA==)
19. [rustsec.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEvZOQ6XyXCg1_1TK_ybMh1BXVh0EXHDDk_3qAFKFfiMh9ehLsBWHcA4psExY3x6z0cExhJf4s3TJ73qF5ZJnE8Qzd-a1JtfmkZt2OHsAng7PIi5H-rXWLit4aIx5gzkX8fiO5XKGywnP5J7Q==)
20. [rustsec.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEZ7lzZAn25YDtu-1hq3jQREcEXIbukVW3GYgxUW05qHTKbnBzhvKHH4gN_Pdd55pWh2xPEC1nCtkXLoQRRYySBUwsyEIbNKblFow==)
21. [openobserve.ai](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHlY1-8ap-hs7rPRcAt-zdyWgdn4cqndDcGQNIxLj1f7GYK5H09Rmuk43qqg_RcOAMHZC1tdSmxgUpm-T2yYZsOnceknOkNsSFjv7yD7Ty2JdgPqXOu0k4f3zqGtkD-fcI=)
22. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHyGGqe905KeA83X-9hIyaq5VAiar12UmbfmdGTxPijumYD_qhKdcvsrM7ofJgqM1Hp4N3L4q5JMPqh0Skm04fvaB-HbyCmpIbu7htE4ovy3b_R8cbQrUmRU8TbY2oSWE5q6iBLM-yxFrtemTOx_BJBTTNrGdwjTWlDWIfdzks=)
23. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGqWCMjObqMiW76zjvj6D0BESvhjDa44pKflYqwRciGV56_zuh_lUbM9a-RLNLOainMimRjC3Y1yiUkBOS-2R9v2b_KhL4hk0ofyl5AiJIXaJnh0ISPZ6BEUKd0slSkl4DmMAzMkxG51nfPJR7t)
24. [base14.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFYOpfGUvcnpb_O8OBSZ_DO_5kTkxBujrYpD890cbb6euR_gyNKGs7-EyXjljoS09lN_1GKqXtxbFj8ijgmjwCQVMOCj8rMJ-ZLxwliov1x24zEEuFtFYECNYTsollYC4n5EatV9GMseZNYA7NbOIitaj4fwOIvbw==)
25. [last9.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGFKWL_KnJHRksplOO8BETqx-gyvQBbS9ggAGU5CUzfjZEzuiASVWpxCeWszCv8MEDnBnZz1ufcBLZswQgOLd5Q0934ugYz91IX2j4q29w4lyHYNif9zgwHwf0ACtHE8PT3HQ==)
26. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFKfakKw-zQf14pjJncHmNuwdA88GwNRcsmb05YKp2I4FU_Br6eC8lhE7_N8CED_bvPWtYMbSbk-GOsijfWTZezOHPAq15vXo0hjz3DCdnkkvEVRrbelZHb8vqJ)
27. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGO1qqZ1eSghtlC5KgDB6xE0ePnZcCblv4v37tCwRSZzPYrtJHTXev0UdGHfwaDVmmPkSxw6WOuEbz-sVfyjh-wgcXTtGOzR0JaXCTogb1q_ttNWKNAwZD2-cR9-qFeERx1sDL9TBnIXA==)
28. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEGNP9pynCnttlmHQlBHO6KFo_ioqQhZ0UoTflr1Zvb0kHCTZYCRvK9e93rJFHIbqiBcWvB-i2d53ZAvrag1KIasT6fZPc2eDCkAWaZmbIKrD2tW8ecQJlZ5rYCt5vL9cyjrK0BLlLv)
29. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGnWt0mKVl-obr-L3FKBfgr4Qs0isfuViEy2T7EV5Wk0bTuHFiDJCdiT-uwGQhJCAjGEhr3pMikj-wYjs5PtZFIEugnl4tIk3hFgDXU9mqNGuCANrTdFqhplShaQQi14Zip)
30. [terminaltrove.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHeZ0tSZoxgdiVUp4xcKnIGYtE6M228nymAqgCjr5RCBb3zi0AWEZy2aEoU7Vr0JIuy72pi5-Q50vDin8hq2WueZi4bCDcN2JSnb8GGuLXGdEtWm4g4vBi9_QT1-OQ=)
31. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFsC31YkvqrPbWPs_QHovLYusfzbS0HzD3MWmWWsNC_uNSDiXVbRcKu-z9roIrbv021jRXZXVXEqU79H21H56sMWY3xaKgBORPkEp8uMKQpWH2kK3_CNlRp4GL-)
32. [brown.edu](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHnJs4eD9a2p4QFisoGZn6Iu4GYuudV2aTSdkLHyV8yt_fw-CyJsbvI66Z6CzV5IYgok51uxrur79ivg8w6GZDkAzXLmpWZRvxcAfZLb0VUbJLvD6UCM2xaamodkfz-xiWdyQ6huQSm8-CwmyJCCLrEYGu-r9mlIg==)
33. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEVoklKiEZAejPXgLSz00Ogl7_99vOGfTITTu4F-DyXfnh9bfBzJAlb-NW4KWHdI_ILs1DSF07fyumQjFpkl7Ai42RB3G2X9_S4tCVPLdHmEwevu68epInHmZwlEHDB33I=)
34. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFxY8dcdTndV3j7VgMrS4DVH5ELaNIYl9_0hhJc7g_v8h5X-VfjuDMdGc36zHKs0v6ct0ZTm7z9tuA35Jn5S1S_yAVsKfGa8WP5cEf6tAF-Jw9pXi9k9yjoH24JxMf9Y0bkbKEgPZl7-uY0r1-2OltSD5N36eTlqa5qI4wS827Exake6yMueOM3n_I9wXZJZAMy)

## Sources

- [github.com](https://github.com/tokio-rs/tracing-opentelemetry)
- [crates.io](https://crates.io/crates/tracing-opentelemetry)
- [github.com](https://github.com/tokio-rs/tracing/issues)
- [github.com](https://github.com/open-telemetry/opentelemetry-rust/blob/main/docs/release_0.32.md)
- [github.com](https://github.com/open-telemetry/opentelemetry-rust)
- [crates.io](https://crates.io/crates/opentelemetry)
- [opentelemetry.io](https://opentelemetry.io/docs/languages/rust/)
- [docs.rs](https://docs.rs/axum-tracing-opentelemetry/latest/axum_tracing_opentelemetry/)
- [crates.io](https://crates.io/crates/axum-tracing-opentelemetry)
- [github.com](https://github.com/merc/axum-tracing-opentelemetry)
- [docs.rs](https://docs.rs/sqlx-tracing)
- [opentelemetry.io](https://opentelemetry.io/docs/specs/otel/compatibility/)
- [opentelemetry.io](https://opentelemetry.io/docs/specs/otel/versioning-and-stability/)
- [opentelemetry.io](https://opentelemetry.io/docs/specs/otel/error-handling/)
- [github.com](https://github.com/open-telemetry/opentelemetry-rust/issues)
- [github.com](https://github.com/open-telemetry/opentelemetry-rust/issues/2978)
- [github.com](https://github.com/open-telemetry/opentelemetry-rust/issues/2778)
- [rustsec.org](https://rustsec.org/)
- [rustsec.org](https://rustsec.org/advisories/RUSTSEC-2025-0123.html)
- [crates.io](https://crates.io/data-access)
- [openobserve.ai](https://openobserve.ai/opentelemetry/rust/)
- [reddit.com](https://www.reddit.com/r/rust/comments/17v6lbo/tracing_vs_opentelemetry/)
- [crates.io](https://crates.io/crates/opentelemetry-appender-tracing)
- [base14.io](https://docs.base14.io/instrument/apps/auto-instrumentation/axum/)
- [last9.io](https://last9.io/blog/opentelemetry-in-rust/)
- [docs.rs](https://docs.rs/tracing-opentelemetry)
- [crates.io](https://crates.io/crates/opentelemetry-otlp/0.15.0)
- [crates.io](https://crates.io/crates/opentelemetry_sdk/0.30.0)
- [crates.io](https://crates.io/crates/opentelemetry-otlp)
- [crates.io](https://crates.io/crates/count-unsafe)
- [terminaltrove.com](https://terminaltrove.com/cargo-geiger/)
- [brown.edu](https://etos.cs.brown.edu/publications/theses/ctiffany-honors.pdf)
- [crates.io](https://crates.io/crates/opentelemetry_sdk)
- [reddit.com](https://www.reddit.com/r/sre/comments/1tcyp7b/opentelemetry_tracing_for_postgresql_queries/)
