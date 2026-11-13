# R78 — opentelemetry-integration (crate, deep) — raw report, Opus engine

Engine: Claude Opus seat, model `claude-opus-5-5`, CLI run 2026-09-26, run directory
`research/runs/R78/2026-09-26T190312Z-8cf4b61ddead`. This is research for P03 to implement.
It is not an implementation, and no Rust code in this report was compiled.

**Retrieval date.** Every figure and every source below was retrieved in one session on
**2026-09-26 (US Pacific) = 2026-09-27 UTC**, unless a line states otherwise. Some GitHub
`pushed_at` values are therefore dated 2026-09-27 UTC.

**Toolchain reference.** Current Rust stable is **1.98.1**, published 2026-09-03
(`GET https://api.github.com/repos/rust-lang/rust/releases/latest`, fields `tag_name`,
`published_at`). The owner-fixed `msrv-policy` ("stable minus 2 minor versions") therefore
puts the template's declared floor at **`rust-version = 1.96`** today. Every MSRV gate below is
judged against 1.96.

**Licence gate.** Gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B)`
(`docs/port/OWNER-REVIEW.md`, section "2026-09-12 — no licence check for anything the template
uses (Q4, superseded and widened by Q7.B)"). No candidate is excluded on licence grounds.
Licence strings appear below as metadata only.

**Independence.** This leg did not open any other engine's report for R78.

### Landscape

**Category decided.** This item decides the crate set that turns the web service's
`tracing` spans into OpenTelemetry (OTel) spans. That set also exports the spans to a
collector and propagates W3C trace context into and out of the service. Everything sits behind
an `otel` Cargo feature layered on `web`. Metrics (R79) and the base subscriber pipeline (R58)
are out of scope.

**Three-bin map of the Rust field.**

| Bin | Candidates found | Role |
|---|---|---|
| Built-in or first-party (the OpenTelemetry project's own Rust SIG and the Tokio project) | `opentelemetry` (API), `opentelemetry_sdk` (SDK), `opentelemetry-otlp` (OTLP exporter), `opentelemetry-http` (HTTP header carriers and the client trait), `opentelemetry-semantic-conventions`, `opentelemetry-appender-tracing` (logs bridge), `opentelemetry-stdout`, `opentelemetry-zipkin`; `tracing-opentelemetry` (the `tracing`-to-OTel bridge, in the `tokio-rs` organization) | The standard stack. The API, SDK and exporter crates release in lockstep (all 0.33.0 on 2026-09-18). |
| Established industry standard (third-party glue with wide adoption) | `axum-tracing-opentelemetry` + `tracing-opentelemetry-instrumentation-sdk` + `init-tracing-opentelemetry` (all from `davidB/tracing-opentelemetry-instrumentation-sdk`); `reqwest-tracing` + `reqwest-middleware` (TrueLayer); `opentelemetry-datadog` and `opentelemetry-instrumentation-actix-web` (from `opentelemetry-rust-contrib`) | Prebuilt server middleware, outbound-client middleware and init helpers layered on the standard stack |
| Up-and-comers and alternatives | `fastrace` + `fastrace-opentelemetry` (a non-`tracing` span model that exports to OTel); `logfire` (Pydantic's vendor SDK built on the standard stack) | Different instrumentation models or vendor packaging |
| Legacy or retired (listed so the census is complete) | `opentelemetry-jaeger` (flagged unmaintained, RUSTSEC-2025-0123); `minitrace` (renamed to `fastrace`, flagged unmaintained, RUSTSEC-2024-0390); `rustracing` (OpenTracing-era, last release 2022-04-05) | Not viable |

**Authoritative sources used, and why each counts.**

- **The OpenTelemetry Rust SIG's own repository** (`open-telemetry/opentelemetry-rust`). It is
  the CNCF OpenTelemetry project's official Rust implementation. Its README "Project Status"
  table is the maintainers' own maturity statement. Its `docs/release_0.33.md` is the
  maintainers' own release note. Its `opentelemetry-otlp/src/lib.rs` crate docs state the
  default transport and environment variables. Its `opentelemetry-otlp/examples/basic-otlp-http`
  is the maintainers' reference example.
- **The `tokio-rs/tracing-opentelemetry` repository.** It is maintained under the Tokio
  organization, which also owns `tracing` and `tracing-subscriber`, the logging stack R58 is
  expected to build on. Its README states the version-compatibility rule. Its CHANGELOG
  records each OTel upgrade. Its `examples/opentelemetry-otlp.rs` is the reference composition
  of the bridge with the OTLP exporter.
- **`tokio-rs/tracing` source** (`tracing-subscriber/src/layer/mod.rs`). This is the primary
  evidence for how layers compose.
- **crates.io API and RustSec.** These are the named figure endpoints in the prompt. RustSec is
  the Rust Secure Code working group's advisory database.
- **Production manifests.** The `Cargo.toml` files of the projects listed under
  "Practice evidence" below show what well-regarded Rust services actually ship.
- **Gap.** The OpenTelemetry specification site (`opentelemetry.io`), docs.rs, and the annual
  Rust survey are not among this topic's named endpoints, so this leg did not fetch them. Claims
  that would normally cite the specification cite the SIG's own crate docs instead.

**Practice evidence: what well-regarded Rust services use.** Each manifest was read through
`GET https://api.github.com/repos/<o>/<r>/contents/<path>`. Standing is shown by stars and a
recent `pushed_at` value from `GET https://api.github.com/repos/<o>/<r>`.

| Project (why it is a relevant reference) | Stars · `pushed_at` | OTel crates in its manifest |
|---|---|---|
| `juspay/hyperswitch`, a payments switch in production at Juspay | 44,239 · 2026-09-27 | `crates/router_env/Cargo.toml`: `opentelemetry` 0.27.1, `opentelemetry-otlp` 0.27.0 (`grpc-tonic`), `opentelemetry_sdk` 0.27.1, `tracing-opentelemetry` 0.28.0 |
| `neondatabase/neon`, serverless Postgres | 23,134 · 2026-08-31 | `Cargo.toml`: `opentelemetry` 0.30, `opentelemetry-otlp` 0.30 (`http-proto`, `reqwest-blocking-client`), `tracing-opentelemetry` 0.31, `reqwest-tracing` 0.5 (`opentelemetry_0_30`) |
| `GreptimeTeam/greptimedb`, a time-series database | 6,714 · 2026-09-26 | `Cargo.toml`: `tracing-opentelemetry` 0.33.0, `opentelemetry-proto` 0.32 |
| `spinframework/spin`, a CNCF WebAssembly framework | 6,520 · 2026-09-25 | `Cargo.toml`: `opentelemetry` 0.29, `opentelemetry-otlp` 0.29 (`http-proto`, `reqwest-client`), `tracing-opentelemetry` 0.30; `crates/telemetry/Cargo.toml` adds `opentelemetry-appender-tracing` 0.29 |
| `MaterializeInc/materialize`, a streaming database | 6,371 · 2026-09-27 | `Cargo.toml`: `opentelemetry` 0.32.0, `opentelemetry-otlp` 0.32.0 (`grpc-tonic`), `opentelemetry_sdk` 0.32.1, `tracing-opentelemetry` 0.33.0 |
| `apollographql/router`, Apollo's GraphQL router | 980 · 2026-09-26 | `apollo-router/Cargo.toml`: `opentelemetry` 0.31, `opentelemetry-otlp` 0.31, `opentelemetry-http` 0.31, `opentelemetry_sdk` 0.31 |
| `pydantic/logfire-rust`, Pydantic's vendor SDK | 77 · 2026-09-24 | `logfire/Cargo.toml`: `opentelemetry` 0.32, `opentelemetry-otlp` 0.32, `tracing-opentelemetry` 0.33, `axum-tracing-opentelemetry` 0.38 (dev) |

Two findings follow from this table.

1. **Every surveyed service uses the same architecture**: `tracing` spans, the
   `tracing-opentelemetry` bridge, and the SDK's OTLP exporter. No surveyed service uses
   `fastrace` or a direct OTel-API-only instrumentation.
2. **The pins span five generations (0.27 to 0.32), and no surveyed project is on 0.33 yet.**
   This is evidence of how much the lockstep 0.x release train costs adopters. It is not an
   endorsement of any version. The OTel 0.33 generation is 8 days old at retrieval.

Reverse-dependency counts (`GET https://crates.io/api/v1/crates/<name>/reverse_dependencies`,
`meta.total`): `opentelemetry_sdk` 1,294; `tracing-opentelemetry` 1,056; `opentelemetry-otlp`
1,003; `reqwest-tracing` 108; `axum-tracing-opentelemetry` 18; `fastrace-opentelemetry` 4.

**Fit lens.** The template is CLI + library + web service. Only the web service (R69:
`axum` 0.8.9 on `tokio` 1.53.1, behind `web`) is instrumented. The CLI and the library must not
see OTel at all. That favors a design where OTel lives entirely in the web binary's startup
code and in one middleware. The `tracing` spans that the library emits are then exported for
free, because they are already `tracing` spans.

### Principles and implementation

**Shared requirement and its source.** The owner direction of 2026-09-04
(`docs/port/OWNER-REVIEW.md`) says: every web example demonstrates OpenTelemetry, using the
idiomatic libraries of its language. The ledger row is F325 (`docs/port/COMMONALITY.md:329`),
"OpenTelemetry tracing is opt-in and soft-imported", verdict `DIVERGENT`, origin py-only. The
OTel feature boundary is part of R58's `logging-pipeline-contract` (F304, reclassified on
2026-09-04).

**Agreement level: capability and standard.** The three repositories must agree on observable
behavior and on the wire standard (OTLP and W3C Trace Context). They should not agree on
mechanism.

**Evidence from the source repositories** (read at py `b55b8c26`, 2026-09-22; ts `e5100b4f`,
2026-09-15).

- **py** `src/py_launch_blueprint/web/telemetry.py:51-89`:
  - `instrument_tracing` imports the SDK, the **OTLP/HTTP** span exporter
    (`opentelemetry.exporter.otlp.proto.http.trace_exporter`, line 67) and the FastAPI
    instrumentor dynamically.
  - On `ModuleNotFoundError` it logs `otel_unavailable` with an install hint, returns `False`,
    and the service keeps serving (lines 71-76).
  - The resource is `service.name = "<APP_NAME>-web"` (line 78).
  - Export uses a `BatchSpanProcessor` (line 85).
  - Flush relies on the SDK's `atexit` hook (lines 79-81).
  - Endpoint configuration comes from the standard `OTEL_EXPORTER_OTLP_*` environment variables
    (lines 83-84).
- **py runtime gate.** `web/settings.py:65-67` declares `otel_enabled: bool = False`.
  `web/app.py:150-151` calls `instrument_tracing(app)` only when that flag is set.
- **py install gate.** `pyproject.toml` declares an `otel` extra separate from `web`.
- **Summary of py.** py has **two** gates: install-time (the extra) and runtime (the settings
  flag). A third failure mode, a missing module, degrades to a warning.
- **ts.** A census of `*.ts` and `*.json` files outside `node_modules` for `opentelemetry` or
  `otel` found no matches. ts has no web service (F303), so it has no OTel implementation.

**Essential behaviors (what must agree), each with an observable criterion.**

| # | Principle | Observable acceptance criterion |
|---|---|---|
| P1 | Tracing is opt-in and off by default | With the feature compiled in but the runtime flag unset, no export is attempted, no warning is logged, and the collector receives nothing |
| P2 | The absence or failure of tracing never breaks serving | With the feature off, with the flag off, with an invalid endpoint, and with an unreachable collector, every request to the example returns its normal status. The process neither crashes nor stalls. A failure is visible as one warning line. |
| P3 | Export uses the vendor-neutral standard, configured by standard variables | OTLP (HTTP/protobuf by default), endpoint from `OTEL_EXPORTER_OTLP_ENDPOINT` / `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` |
| P4 | W3C Trace Context is propagated in and out | An incoming `traceparent` becomes the parent of the server span. An outbound request carries a `traceparent` whose trace ID equals the incoming one. |
| P5 | Service identity | The resource carries `service.name = <app>-web` |
| P6 | Buffered spans are flushed on graceful shutdown, within a bound | After SIGTERM, spans from in-flight requests reach the collector. With the collector down, shutdown still finishes within the configured budget. |
| P7 | Application logs correlate with traces | Log records emitted inside a request carry that request's trace ID, either at the collector or in local structured logs (R58 decides which) |

**What may vary, and why.**

- **How absence is expressed.** py detects a missing module at runtime. Rust removes the code
  at compile time: code behind an unenabled Cargo feature does not exist in the binary. This is
  a justified ecosystem difference. Cargo features are the native optionality mechanism
  (F304), and a runtime `dlopen`-style soft import has no idiomatic Rust equivalent.
- **Instrumentation style.** py uses auto-instrumentation (`FastAPIInstrumentor`). Rust has no
  monkey-patching, so the server span comes from explicit middleware. This is justified: it is
  the only mechanism available.
- **Shared low-level values.** Agreement on the transport (OTLP over HTTP/protobuf) and on the
  resource name comes free, because the Rust exporter's own default matches py's choice. No
  other shared low-level value is recommended.

**Answer to the HIGH question on degrade: what replaces py's runtime soft-degrade.** Rust
needs a **three-gate ladder**. The third gate is the direct replacement for py's
`except ModuleNotFoundError`.

1. **Compile time.** `otel` is off, so no OTel code or dependency exists. There is nothing to
   guard. The `#[cfg(not(feature = "otel"))]` path of `telemetry::init` returns "off".
2. **Runtime flag.** `otel` is compiled in, but `<APP>_WEB_OTEL_ENABLED` is unset (default
   `false`, mirroring py's `otel_enabled`). The service returns "off" without touching the
   network. This gate matters for a specific reason: `opentelemetry-otlp` defaults the endpoint
   to `http://localhost:4318` when no variable is set (`opentelemetry-otlp/src/lib.rs:222`).
   Without the flag, a binary built with `otel` would silently try to export to localhost.
   The Rust SDK has **no `OTEL_SDK_DISABLED` support**: a code search of
   `repo:open-telemetry/opentelemetry-rust` for `OTEL_SDK_DISABLED` returned 0 hits. The
   template should therefore also honor `OTEL_SDK_DISABLED=true` itself, as a standard
   kill switch. That costs one line.
3. **Exporter build failure.** This is the direct replacement for py's `except`. Since 0.33,
   "Invalid OTLP endpoint environment variables (HTTP and gRPC) now produce a build error
   instead of silently falling back to localhost" (`docs/release_0.33.md`, "Stabilisation
   cleanups"). `SpanExporter::builder().with_http().build()` returns
   `Result<_, ExporterBuildError>`. On `Err`, the service logs **one** `otel_unavailable`
   warning with the error text and continues with no OTel layer.
   **Timing detail.** The warning must be emitted *after* the subscriber is installed.
   Otherwise it goes nowhere, because the layer is built before `init()`. So `telemetry::init`
   returns the error as a value, and the caller logs it after `init()`.

**Two runtime failure modes that need no guard code, because the SDK already degrades.**

- **Collector unreachable after startup.**
  - The default `BatchSpanProcessor` exports on an SDK-owned background thread (`thread::Builder`
    at `opentelemetry-sdk/src/trace/span_processor.rs:571`). Request handling therefore never
    waits on export.
  - The queue is bounded: `OTEL_BSP_MAX_QUEUE_SIZE_DEFAULT = 2_048` (line 63). When it is full,
    spans are dropped, and a single log line is emitted for the first drop (lines 868-872).
  - Since 0.33, OTLP/HTTP retries up to 3 times with exponential backoff and jitter
    (`docs/release_0.33.md`, "Retries enabled by default").
- **Shutdown with the collector down.**
  - `SdkTracerProvider::shutdown_with_timeout(Duration)` exists
    (`opentelemetry-sdk/src/trace/provider.rs:246`).
  - Plain `shutdown()` is bounded by `OTEL_BSP_EXPORT_TIMEOUT_DEFAULT = 30_000` ms
    (`span_processor.rs:80`), which can exceed R69's settings-driven drain deadline.
  - The processor docs warn that `shutdown()` is blocking and can deadlock on a current-thread
    Tokio runtime (`span_processor.rs:480-483`).
  - **Design.** After `axum::serve(..).with_graceful_shutdown(..)` returns, call
    `provider.shutdown_with_timeout(otel_shutdown_budget)` inside
    `tokio::task::spawn_blocking`. On `Err`, log a warning. **Do not change the exit code**:
    R69/R67 already fixed 143 after SIGTERM and 130 after SIGINT.

**Architectural alternatives, compared before choosing libraries.**

| Alternative | How it works | Verdict |
|---|---|---|
| A. **`tracing` bridge** (`tracing-opentelemetry` layer on the `tracing-subscriber` `Registry`) | Library, handler and middleware code emit ordinary `tracing` spans. One extra layer converts them into OTel spans. | **Chosen.** It is a pure addition to R58's pipeline. The library and CLI stay OTel-free. It is universal in the practice survey. |
| B. Direct OTel API instrumentation (`opentelemetry::trace::Tracer` calls in handlers) | Code creates OTel spans explicitly, and `tracing` stays for logs only | Rejected. Two span models would exist, the library's `tracing` spans would be invisible to OTel, and the core crate would need an OTel dependency (which violates the rule that CLI and library never see OTel). |
| C. `fastrace` + `fastrace-opentelemetry` | A separate, low-overhead span model that exports to OTel | Rejected for this template. It replaces the `tracing` span model that R58 is expected to adopt, has 4 reverse dependencies, and is pinned to OTel 0.32. |
| D. Collector-less (logs only, with trace IDs) | No export; trace IDs are printed | Fails P3 and the owner's requirement that the example demonstrate export |
| E. Prebuilt glue (`axum-tracing-opentelemetry`, `reqwest-tracing`, `init-tracing-opentelemetry`) on top of A | Same as A, with the middleware and init code supplied by crates | **Ranked runner-up** (see below). The deciding fact is version lag. |

**Answer to the MEDIUM question: does `tracing-opentelemetry` require restructuring R58's
pipeline?** No. It is a **pure addition**, and the evidence is concrete.

- `tracing-subscriber` implements `impl<L, S> Layer<S> for Option<L>`
  (`tokio-rs/tracing`, `tracing-subscriber/src/layer/mod.rs:1560`). R58's
  `registry().with(filter).with(fmt_layer)` chain can take `.with(otel_layer_option)`, where
  the option is `None` whenever any gate is closed. The subscriber type is the same in every
  configuration.
- The maintained reference `tracing-opentelemetry/examples/opentelemetry-otlp.rs` (lines
  76-119) composes `tracing_subscriber::registry()`, a level filter, `fmt::layer()` and
  `OpenTelemetryLayer::new(tracer)`. It uses a `Drop` guard that calls
  `tracer_provider.shutdown()`.
- **The one coupling R58 must accept: a per-layer filter on the OTel layer.** The official
  `basic-otlp-http` example (lines 95-117) turns off `hyper`, `tonic`, `h2` and `reqwest` on
  the OTel layer to prevent a "telemetry-induced-telemetry loop". Without that filter, spans
  from the exporter's own HTTP client would be exported. This is a per-layer filter
  (`Layer::with_filter`), so it does not change R58's global filter. The sketch below uses
  `EnvFilter` because the official example does, and `EnvFilter` needs `tracing-subscriber`'s
  `env-filter` feature. If R58 does not enable that feature,
  `tracing_subscriber::filter::Targets` expresses the same directives with no extra feature.

**Maturity, stated separately from the maturity of the OTel standard.** The OTel
*specification* for traces and OTLP is stable. The Rust *implementation* is not:

- The `opentelemetry-rust` README "Project Status" table lists
  **Traces-API Beta, Traces-SDK Beta, Traces-OTLP Exporter Beta, Propagators Beta,
  Context Beta**. It lists Logs-API, Logs-SDK and Logs-Appender-Tracing as **Stable**, and
  Metrics-API and Metrics-SDK as **Stable**.
- The 0.33 release note says the tracing API, SDK and exporter "remain pre-stable, and this
  release includes intentional breaking changes in that area".
- **Consequence.** Expect a breaking bump roughly every 4 to 8 months, based on the release
  cadence: 0.29.0 on 2025-03-22, 0.30.0 on 2025-05-23, 0.31.0 on 2025-09-25, 0.32.0 on
  2026-05-08, 0.33.0 on 2026-09-18. Each bump requires a matching `tracing-opentelemetry`
  release.

**Answer to the HIGH question: version-compatibility matrix** (crates.io
`/api/v1/crates/<name>/<version>/dependencies`, normal dependencies).

| `opentelemetry` / `_sdk` / `-otlp` / `-http` / `-appender-tracing` | `tracing-opentelemetry` | released | `tracing-subscriber` req | `tracing` req | MSRV (`rust_version`) |
|---|---|---|---|---|---|
| **0.33.0** (2026-09-18) | **0.34.0** (2026-09-23; requires `opentelemetry ^0.33.0`) | 5 days apart | `^0.3.22` (`registry`, `std`) | `^0.1.35` | 1.75.0 for all |
| 0.32.x (0.32.0 2026-05-08; sdk 0.32.1 2026-05-26) | 0.33.0 (2026-05-18; `^0.32.0`) | 10 days apart | `^0.3.22` | `^0.1.35` | 1.75.0 |
| 0.31.0 (2025-09-25) | 0.32.0 (2025-09-30) / 0.32.1 | 5 days apart | — | — | 1.75.0 |

- **Rule.** `tracing-opentelemetry` 0.N+1 pairs with `opentelemetry` 0.N. The README says
  this is not guaranteed: "due to semver compatibility concerns, this may not always be the
  case" (README, "Compatibility with OpenTelemetry crates").
- **Failure mode.** A mismatch compiles two copies of `opentelemetry`. Types then fail to unify
  at compile time, or context silently fails to propagate.
- **Glue-crate lag at retrieval.** Every glue crate still pins the *previous* generation:
  - `axum-tracing-opentelemetry` 0.39.1 and `tracing-opentelemetry-instrumentation-sdk` 0.38.3
    require `opentelemetry ^0.32` and `tracing-opentelemetry ^0.33`.
  - `init-tracing-opentelemetry` 0.41.1 also requires `^0.32`.
  - `reqwest-tracing` 0.7.1 offers features only up to `opentelemetry_0_32`.
  - `fastrace-opentelemetry` 0.18.1 requires `^0.32`.
- **History of the lag.** `axum-tracing-opentelemetry` 0.38.0, the release for the 0.32
  generation, shipped 2026-05-24, 16 days after `opentelemetry` 0.32.0.

**Answer to the MEDIUM question: default exporter transport.**

- The default is **OTLP over HTTP with protobuf bodies** through a **blocking `reqwest`
  client**. `opentelemetry-otlp` 0.33.0 default features are `http-proto`,
  `reqwest-blocking-client`, `trace`, `metrics`, `logs` and `internal-logs` (crates.io version
  features); `lib.rs:286-289` confirms this. gRPC (`grpc-tonic`) is opt-in.
- **Why the blocking client.** The crate docs (`lib.rs:522-530`) explain that the default batch
  processors "run exports on SDK-owned background threads, so OTLP/HTTP should use the default
  `reqwest-blocking-client`". Async clients must not be combined with the default batch
  processors.
- **Async-runtime coupling: none on the export path.** The exporter builds its blocking
  `reqwest` client on a freshly spawned OS thread
  (`opentelemetry-otlp/src/exporter/http/mod.rs:241-265`). The known panic from constructing a
  blocking client inside a Tokio runtime therefore cannot occur, and init is safe inside
  `#[tokio::main]`.
- **gRPC by contrast** requires a Tokio runtime (`lib.rs:72`) and pulls in `tonic` 0.14,
  `prost` and HTTP/2.
- **Agreement with py.** The HTTP default also matches py's exporter choice.

**Maintained reference implementations.**

1. `opentelemetry-rust/opentelemetry-otlp/examples/basic-otlp-http` shows the exporter,
   provider, per-layer filter and shutdown.
2. `tracing-opentelemetry/examples/opentelemetry-otlp.rs` shows the bridge layer and the
   `Drop` guard.
3. `tracing-opentelemetry/examples/opentelemetry-remote-context.rs` shows extraction of a
   remote parent (listed at `repos/tokio-rs/tracing-opentelemetry/contents/examples`).
4. **Gap.** No maintained upstream example combines an **axum 0.8 server, an outbound request
   and OTLP export at OTel 0.33**. The composition below is this leg's proposal, and nothing
   has run it.

**Minimal realistic example: proposed, not compiled.** Module layout: `src/web/telemetry.rs`,
compiled only with `web`; its OTel half is under `#[cfg(feature = "otel")]`.

```rust
// src/web/telemetry.rs — the OTel half exists only with feature "otel".
pub enum OtelInit<L> { Off, Unavailable(String), On(L, OtelGuard) }

#[cfg(feature = "otel")]
pub fn otel_layer<S>(s: &WebSettings) -> OtelInit<impl tracing_subscriber::Layer<S>>
where S: tracing::Subscriber + for<'a> tracing_subscriber::registry::LookupSpan<'a> {
    use opentelemetry::{global, trace::TracerProvider as _};
    use opentelemetry_sdk::{propagation::TraceContextPropagator, trace::SdkTracerProvider, Resource};
    use tracing_subscriber::{EnvFilter, Layer as _};
    if !s.otel_enabled || std::env::var("OTEL_SDK_DISABLED").is_ok_and(|v| v.eq_ignore_ascii_case("true")) {
        return OtelInit::Off;                                   // gate 2
    }
    let exporter = match opentelemetry_otlp::SpanExporter::builder().with_http().build() {
        Ok(e) => e,
        Err(e) => return OtelInit::Unavailable(e.to_string()),  // gate 3 — py's `except`
    };
    let provider = SdkTracerProvider::builder()
        .with_batch_exporter(exporter)
        .with_resource(Resource::builder().with_service_name(format!("{APP_NAME}-web")).build())
        .build();
    // The global default propagator is a no-op (opentelemetry/src/global/propagation.rs:10-15);
    // without this line an incoming traceparent is silently ignored.
    global::set_text_map_propagator(TraceContextPropagator::new());
    let layer = tracing_opentelemetry::layer()
        .with_tracer(provider.tracer("rs-launch-blueprint-web"))
        .with_filter(EnvFilter::new("info,hyper=off,h2=off,reqwest=off,tonic=off")); // or filter::Targets
    OtelInit::On(layer, OtelGuard(provider))
}
// R58's assembly (the only change is the optional layer):
//   let otel = telemetry::otel_layer(&settings);
//   registry().with(r58_filter).with(r58_fmt).with(otel.layer_option()).init();
//   if let Some(msg) = otel.unavailable() { tracing::warn!(error = %msg, "otel_unavailable"); }
```

```rust
// Server-side extraction: axum::middleware::from_fn, no extra crate.
// tower-http's TraceLayer is R75's to select (R69 DECISION.md), so it is not assumed here.
async fn otel_context(req: axum::extract::Request, next: axum::middleware::Next) -> axum::response::Response {
    use tracing::Instrument;
    let route = req.extensions().get::<axum::extract::MatchedPath>().map(|p| p.as_str().to_owned());
    let span = tracing::info_span!("http.server.request", otel.kind = "server",
        http.request.method = %req.method(), http.route = route.as_deref().unwrap_or(""),
        http.response.status_code = tracing::field::Empty);
    #[cfg(feature = "otel")] {
        use tracing_opentelemetry::OpenTelemetrySpanExt;
        let parent = opentelemetry::global::get_text_map_propagator(|p|
            p.extract(&opentelemetry_http::HeaderExtractor(req.headers())));
        let _ = span.set_parent(parent);   // returns Result; SetParentError is public from 0.32.1 (CHANGELOG)
    }
    let resp = next.run(req).instrument(span.clone()).await;
    span.record("http.response.status_code", resp.status().as_u16());
    resp
}

// Outbound injection: a client span plus a W3C header on the outgoing request.
#[cfg(feature = "otel")]
fn inject(headers: &mut http::HeaderMap) {
    use tracing_opentelemetry::OpenTelemetrySpanExt;
    let cx = tracing::Span::current().context();
    opentelemetry::global::get_text_map_propagator(|p|
        p.inject_context(&cx, &mut opentelemetry_http::HeaderInjector(headers)));
}
```

**Integration assumptions the example depends on.**

- `opentelemetry-http` 0.33 requires `http ^1.1`. `axum` 0.8 uses `http` 1.x. The outbound
  client's `HeaderMap` must also be `http` 1.x. This assumption is **unverified for the
  client**: R69 did not select an outbound HTTP client, and this report does not select one
  either. `reqwest` 0.13 is already in the `otel` tree through the exporter's blocking client,
  so an async `reqwest` client for the example adds features, not a new crate.
  `cargo tree -d` must show a single `http` 1.x.
- The middleware creates the server span whether or not `otel` is on. Only the `set_parent`
  block is feature-gated. If R58 or R75 already owns a request-span middleware, the
  `#[cfg(feature = "otel")]` block moves into that middleware's span constructor, and no
  second span is created.

**Coordination with R58 and R79** (both still undecided; `inputs/prerequisites.json` shows R58
`decision: missing`).

- **R58.**
  - This report assumes R58 assembles a `tracing_subscriber::Registry` with composable layers.
  - R78 needs exactly one optional layer, plus the per-layer filter above.
  - **Log correlation (P7) has two acceptable realizations. R58 chooses one.**
    - (a) Enable `opentelemetry-appender-tracing` 0.33 (Logs-Appender-Tracing is **Stable**
      per the README) behind `otel`. Log records then reach the collector with trace and span
      IDs attached, and correlation is observed at the collector.
    - (b) Have R58's JSON formatter write `trace_id`/`span_id` from the current span's OTel
      context into local log lines.
  - Option (a) adds one crate and a `LoggerProvider` to shut down. Option (b) keeps logs local
    but needs a custom formatter.
- **R79.**
  - If R79 exports metrics through OTel (`opentelemetry-prometheus` or OTLP metrics), it must
    use the **same 0.33 generation** and the same `Resource`.
  - `telemetry.rs` should own every provider's lifecycle and shut them down in one place after
    the server drains.
  - If R79 picks a non-OTel metrics crate, the only coupling is shutdown ordering.
  - `tracing-opentelemetry`'s `metrics` feature (its `MetricsLayer`) is on by default. This
    report disables default features, so R79 decides whether that layer is used.
  - **The metrics SDK is compiled in anyway.** `opentelemetry-otlp` 0.33.0's `http-proto`
    feature is defined as `["prost", "opentelemetry-http", "opentelemetry-proto/gen-tonic-messages",
    "http", "httpdate", "trace", "metrics"]` (crates.io version features). The recommended HTTP
    exporter therefore enables `opentelemetry/metrics` and `opentelemetry_sdk/metrics` as a side
    effect. The code is present but inert unless a `MeterProvider` is built. That lowers R79's
    marginal cost if R79 chooses OTel metrics.

**Representative performance and cost.** Not measured. This leg ran no builds.

- **Qualitative per-request cost.** One extra layer callback per span event. At the default
  `AlwaysOn` sampler, one `SpanData` allocation per span is enqueued on a bounded channel.
  Export runs off the request path.
- **Stated measurement for P03.** Workload: `GET` on the example route at a fixed rate on
  loopback, using the release profile on `ubuntu-latest`. Compare three configurations: (i)
  `web` only; (ii) `web,otel` with the flag off; (iii) `web,otel` exporting to a local
  collector. Report p50/p99 latency, throughput and RSS. Configuration (ii) must match
  configuration (i) within noise.

**BASELINE-REVIEW: F325 — optional tracing never breaks the service — the row text "whether
Rust's optional OTel support is a compile-time Cargo feature gate rather than py's runtime
soft-import degrade" should read "compile-time feature gate **plus** a runtime enable flag and
a runtime exporter-build degrade" — evidence:**

- `opentelemetry-otlp` 0.33 turns an invalid endpoint variable into a build error
  (`docs/release_0.33.md`).
- It defaults the endpoint to localhost when no variable is set (`lib.rs:222`).
- A compile-time gate alone therefore does not preserve P1 or P2.
- Affected items: R78 (this item) and R58 (which owns the feature boundary). No other item is
  affected, and the verdict `DIVERGENT` is unchanged.

### Dominant choice

**`tracing-opentelemetry` 0.34** is the dominant choice: the `tracing`-to-OpenTelemetry bridge
layer. It is used with the OpenTelemetry Rust SIG's **0.33 generation**:

- `opentelemetry` 0.33 (API)
- `opentelemetry_sdk` 0.33 (batch span processor and tracer provider)
- `opentelemetry-otlp` 0.33 (OTLP over HTTP/protobuf, blocking `reqwest` client)
- `opentelemetry-http` 0.33 (W3C header extractor and injector)

All of these sit behind `otel = ["web", …]`.

It is dominant for four reasons:

1. It is the only bridge from the `tracing` span model, which the library, the CLI and the axum
   ecosystem already use, to OTel.
2. It is maintained by the Tokio organization.
3. It has 46.1 M downloads in 90 days and 1,056 reverse dependencies.
4. Every surveyed production service uses it.

### Qualified shortlist

Each entry below passed every applicable gate. Gate 1 is inapplicable (Q7.B).
`axum-tracing-opentelemetry`, originally a shortlist candidate, failed gate 4 on the evidence
available and is listed under *Excluded by gate*. Figures come from
`GET https://crates.io/api/v1/crates/<name>` (`recent_downloads` for 90-day downloads,
`downloads` for all-time), `/versions` (newest non-yanked `num` and `created_at`), and
`GET https://api.github.com/repos/<o>/<r>` (`stargazers_count`).

1. **`tracing-opentelemetry`**
   - Role: bridge layer (the pick).
   - Downloads: 46,120,245 in 90 days; 210,366,232 all-time.
   - Stars: 409 (`tokio-rs/tracing-opentelemetry`).
   - Last release: 0.34.0, 2026-09-23.
   - Maintenance: **active**.
   - Adopters: hyperswitch, neon, GreptimeDB, Spin, Materialize, logfire-rust.
   - Trade-off: the only mainstream bridge, but it must move in lockstep with `opentelemetry`
     0.x.
2. **`opentelemetry-otlp`**, with companions `opentelemetry` / `opentelemetry_sdk` /
   `opentelemetry-http`
   - Role: exporter, SDK and API.
   - Downloads: 42,378,989 in 90 days; 160,163,609 all-time. Companions: `opentelemetry`
     62,093,844 / 273,950,228; `opentelemetry_sdk` 56,201,160 / 228,219,587;
     `opentelemetry-http` 37,981,616 / 152,353,252.
   - Stars: 2,718 (`open-telemetry/opentelemetry-rust`).
   - Last release: 0.33.0, 2026-09-18, for all four.
   - Maintenance: **active**.
   - Adopters: every project in the practice table.
   - Trade-off: the official, vendor-neutral stack, but traces are still **Beta**, with
     intentional breaking changes per release.
3. **`opentelemetry-appender-tracing`**
   - Role: logs-to-OTel bridge, for P7 option (a).
   - Downloads: 8,504,463 in 90 days; 19,617,877 all-time.
   - Stars: 2,718 (same repository).
   - Last release: 0.33.0, 2026-09-18.
   - Maintenance: **active**.
   - Adopters: Spin (`crates/telemetry/Cargo.toml`).
   - Trade-off: Stable status and correlation for free at the collector, but it adds a second
     provider and overlaps with R58's sink decision.
4. **`fastrace-opentelemetry`**, with `fastrace`
   - Role: an alternative span model with an OTel exporter.
   - Downloads: `fastrace-opentelemetry` 1,057,902 in 90 days / 4,970,189 all-time; `fastrace`
     1,408,144 / 7,177,731.
   - Stars: 1,135 (`fast/fastrace`).
   - Last release: 0.18.1, 2026-06-17 (`fastrace` 0.7.19, 2026-07-31).
   - Maintenance: **active**.
   - Adopters: 4 reverse dependencies. No surveyed service uses it.
   - Trade-off: lower overhead, but it replaces the `tracing` span model and pins OTel 0.32.

**Per-candidate gate answers.** These answers were recorded before popularity was weighed.
Maintenance figures follow the table.

| Gate | `tracing-opentelemetry` | OTel core (`opentelemetry`, `_sdk`, `-otlp`, `-http`, `-appender-tracing`) | `axum-tracing-opentelemetry` (excluded, gate 4) | `fastrace-opentelemetry` |
|---|---|---|---|---|
| 1 licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; metadata: MIT | inapplicable (Q7.B); metadata: Apache-2.0 | inapplicable (Q7.B); metadata: CC0-1.0 | inapplicable (Q7.B); metadata: Apache-2.0 |
| 2 MSRV ≤ 1.96 | `rust_version` 1.75.0; CI checks 1.75.0 (`.github/workflows/CI.yml:83-91`) | 1.75.0; the repository runs a `cargo-msrv` job (`ci.yml:132-150`) and its README promises the current stable plus the three prior minor versions | 1.91.0 | 1.91.0 |
| Dependency-tree MSRV | **Not executed.** Largest declared floors in the `otel` tree: `tonic` 1.88 (gRPC only, not selected); `reqwest` 0.13.5 at 1.85.0. Proposed check under Validation strategy. | same | same | same |
| 3 advisories | None (RustSec page 404 = no advisories) | None for all five crates. `tonic` RUSTSEC-2024-0376 is patched at ≥0.12.3 and does not apply to 0.14.6. | None | None |
| 3 `unsafe` posture | One `unsafe fn downcast_raw` (`src/layer.rs:1557`), which is the `tracing-subscriber` `Layer` trait's required downcast hook | A GitHub code search for `unsafe` under `opentelemetry-sdk/src` and `opentelemetry-otlp/src` returned 0 hits. The index can be incomplete; confirm with `cargo geiger` (proposed). | `#![forbid(unsafe_code)]` in `axum-tracing-opentelemetry/src/lib.rs:2` and `tracing-opentelemetry-instrumentation-sdk/src/lib.rs:2` | `fastrace` uses one `unsafe` block (`crates/fastrace/src/collector/global_collector.rs:55`, sending on a thread-local channel) |
| 4 OS | Tests on ubuntu, windows and macos (`CI.yml:113-127`) | Stable toolchain on ubuntu, windows, macos and ubuntu-arm (`ci.yml:20-34`) | **FAIL (unproven).** `.github/workflows/ci.yml:29-31` matrix is `ubuntu-latest` only; `# - macos-latest` is commented out. No stated platform list was found. | Tests on windows, macos and ubuntu (`fast/fastrace` `.github/workflows/ci.yml:43-47`) |
| 5 default features and runtime | Defaults `tracing-log`, `metrics`; **use `default-features = false`**. No runtime coupling. | SDK defaults: `trace`, `metrics`, `logs`, `internal-logs`. OTLP defaults: `http-proto`, `reqwest-blocking-client`, `trace`, `metrics`, `logs`, `internal-logs`. Export runs on an SDK thread with no Tokio requirement; gRPC requires Tokio. | `axum` + `tokio` features | none (`pollster` blocks internally) |
| 6 size and compile cost | small | Moderate: `prost`, `reqwest` (blocking), `opentelemetry-proto`. `hyper`/`tokio` are already present through `axum`. gRPC would add `tonic` and HTTP/2. | small, plus a second OTel generation if mixed | small, plus a second span model |

**Maintenance evidence** (`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`,
`total_count`; responsiveness is the median days to the first comment whose
`author_association` is OWNER, MEMBER or COLLABORATOR, over the 10 most recently opened
issues).

| Repository | Open issues | Median first response (days) | Unanswered of 10 | `pushed_at` | Rubric |
|---|---|---|---|---|---|
| `open-telemetry/opentelemetry-rust` | 216 | 1.9 | 7 | 2026-09-25 | **active**. Five releases in 18 months, the latest 2026-09-18. The unanswered count is very likely an artifact: `author_association` reports members with private organization membership as CONTRIBUTOR, and 4 of the 7 issues are under 3 days old. The count is not used for the rubric. |
| `tokio-rs/tracing-opentelemetry` | 18 | 0.5 | 4 | 2026-09-23 | **active** (released 5 days after upstream) |
| `davidB/tracing-opentelemetry-instrumentation-sdk` | 7 | 3.6 | 2 | 2026-09-23 | **active** (not yet on 0.33) |
| `TrueLayer/reqwest-middleware` | 29 | 13.5 | 6 | 2026-05-19 | **stable-quiet**, with a concrete lag signal: no 0.33 feature 8 days after upstream |
| `fast/fastrace` | 11 | 0.6 | 3 | 2026-07-31 | **active** |

Only four candidates qualify, fewer than the five allowed, and that is itself a finding. The OTel Rust
field is one official stack plus one bridge. Everything else is glue on top of that stack or an
alternative span model.

### Excluded by gate

**Gate failures.**

| Candidate | Gate | Evidence |
|---|---|---|
| `opentelemetry-jaeger` 0.22.0 (last release 2024-05-15) | 3: open advisory | RUSTSEC-2025-0123 (INFO, unmaintained), dated 2025-11-18 (`https://rustsec.org/packages/opentelemetry-jaeger.html`). Jaeger ingests OTLP natively, and the SIG's own docs run `jaegertracing/jaeger` against OTLP (`lib.rs:147`). |
| `minitrace` 0.6.7 (last release 2024-06-23) | 3: open advisory | RUSTSEC-2024-0390 (INFO, unmaintained), dated 2024-11-10; renamed to `fastrace` |
| `axum-tracing-opentelemetry` 0.39.1 + `tracing-opentelemetry-instrumentation-sdk` 0.38.3 | 4: OS coverage unproven | The upstream CI matrix is `ubuntu-latest` only, with `macos-latest` commented out (`davidB/tracing-opentelemetry-instrumentation-sdk` `.github/workflows/ci.yml:29-31`, read through `api.github.com/repos/.../contents`). No stated platform list. It passed the other gates: MSRV 1.91.0, no advisory, `#![forbid(unsafe_code)]`. Figures: 2,386,325 downloads in 90 days; 16,371,187 all-time; 249 stars; last release 2026-08-30; **active** (7 open issues; median first response 3.6 days); 18 reverse dependencies; adopter logfire-rust (dev, 0.38). Fit concern besides the gate: it pins OTel 0.32. It remains the ranked runner-up, conditional on gate 4 being satisfied (see Ranked runner-up). |

**Passed the gates but excluded by fit** (these are not gate failures; listed so the exclusion
reason is explicit).

| Candidate | Reason |
|---|---|
| `reqwest-tracing` 0.7.1 + `reqwest-middleware` 0.5.2 | Features stop at `opentelemetry_0_32`. With the 0.33 pick, it would compile a second `opentelemetry` and lose propagation. The outbound injection is 4 lines with `opentelemetry_http::HeaderInjector`. It is also a middleware wrapper around the client, and the outbound client is not this item's choice. |
| `init-tracing-opentelemetry` 0.41.1 | It assembles the whole subscriber (`tracing_subscriber_ext` feature), which is R58's decision. It pins 0.32. |
| `opentelemetry-stdout` 0.33.0, `opentelemetry-zipkin` 0.33.0, `opentelemetry-datadog` 0.20.1 | Non-OTLP or vendor exporters fail P3's vendor-neutral default. `opentelemetry-stdout` is a reasonable **dev-dependency** for tests. |
| `rustracing` 0.6.0 (2022-04-05) | OpenTracing-era, not OTel. There is no advisory, so the rubric verdict is not `dormant`, but it is irrelevant to the category. |
| `opentelemetry-instrumentation-actix-web` 0.25.0 | For actix-web; R69 chose axum |
| Direct OTel-API instrumentation, the collector-less design, and `fastrace` as the template's span model | Architectural alternatives B, C and D, rejected under Principles and implementation |

### Up-and-comers

- **`fastrace` 0.7.19 / `fastrace-opentelemetry` 0.18.1** (1,135 stars; 1,408,144 downloads in
  90 days). It is a performance-first span model, the successor to TiKV's `minitrace`. It is
  worth revisiting if tracing overhead becomes a measured bottleneck and R58 adopts a
  non-`tracing` model. Neither condition holds today.
- **`logfire` 0.13.1** (Pydantic; 123,361 downloads in 90 days; `rust_version` 1.91; MIT;
  released 2026-09-17). It is a vendor-packaged init over the same standard stack. That the
  crate exists is evidence that the stack is the convergence point, not a candidate: it binds
  the template to a vendor.
- **`opentelemetry-instrumentation-*` crates in `opentelemetry-rust-contrib`**
  (`opentelemetry-instrumentation-actix-web` 0.25.0 already targets OTel 0.33, released
  2026-09-21). If the SIG adds an axum or tower instrumentation crate there, it becomes the
  natural replacement for the hand-written middleware, because it would release in lockstep.
  **Gap:** no such axum crate was found in the crates.io census performed here.

### Fit for this template

- **CLI.** No OTel. The `otel` feature requires `web`, and the CLI binary is not built with it.
  The core library keeps emitting plain `tracing` spans, which cost nothing without a
  subscriber layer. P1 holds by construction.
- **Library.** No OTel dependency, ever. Library users who want OTel install
  `tracing-opentelemetry` in *their* binary, and the library's spans export unchanged. This is
  the main reason alternative A (the bridge) beats alternative B (direct API).
- **Web.**
  - One `telemetry.rs` module, one middleware, one outbound helper, and one `OtelGuard` shut
    down after the server drains.
  - It fits R69's `#[tokio::main]` multi-thread runtime: the export thread is SDK-owned, and
    the blocking client is built off-runtime.
  - It fits R69's drain deadline through `shutdown_with_timeout`.
  - The three-gate ladder keeps the service serving in every OTel state.

### Recommendation

Adopt **`tracing-opentelemetry = "0.34"`** (caret, meaning ≥0.34.0 and <0.35.0) as the pick,
with `opentelemetry = "0.33"`, `opentelemetry_sdk = "0.33"`, `opentelemetry-otlp = "0.33"`
and `opentelemetry-http = "0.33"`. All are optional, all are enabled only by
`otel = ["web", …]`, and all use `default-features = false`:

```toml
[features]
otel = ["web", "dep:opentelemetry", "dep:opentelemetry_sdk", "dep:opentelemetry-otlp",
        "dep:opentelemetry-http", "dep:tracing-opentelemetry"]

[dependencies]
opentelemetry         = { version = "0.33", optional = true, default-features = false, features = ["trace"] }
opentelemetry_sdk     = { version = "0.33", optional = true, default-features = false, features = ["trace"] }
opentelemetry-otlp    = { version = "0.33", optional = true, default-features = false,
                          features = ["trace", "http-proto", "reqwest-blocking-client", "internal-logs"] }
opentelemetry-http    = { version = "0.33", optional = true, default-features = false }
tracing-opentelemetry = { version = "0.34", optional = true, default-features = false }
```

**The set is not metrics-free.** `default-features = false` keeps the dependency set small,
but not free of metrics code. `http-proto` transitively enables the `metrics` feature of
`opentelemetry-otlp`, `opentelemetry` and `opentelemetry_sdk`, as shown under Principles and
implementation. Of the metrics pieces, only the bridge's `MetricsLayer` stays opt-in.

**Why `internal-logs` is kept.** It makes exporter failures (connection refused, dropped spans)
visible through `tracing` as `opentelemetry*`-target events. That visibility is P2's "one
warning line".

**TLS.** No TLS feature is enabled. `opentelemetry-otlp`'s `reqwest` dependency is declared
with `default-features = false`, so an `https://` collector needs the additive
`opentelemetry-otlp/reqwest-rustls` feature. P03 decides whether the template enables it by
default. This is a parameter gap, recorded here.

**Why the 0.33 generation rather than 0.32.**

1. 0.33 turns an invalid endpoint into a *build error*. The three-gate ladder catches that
   error; under 0.32, the same input silently falls back to localhost.
2. Retries are on by default.
3. The SIG intends to declare the Logs and Metrics OTLP exporters stable in 0.33.1, "about two
   weeks after" 2026-09-18. R79 and P7 option (a) then land on stable exporters.
4. Starting on the current generation maximizes the time before the next forced bump.

**The only thing given up** is the prebuilt axum middleware, which costs about 25 lines,
shown above.

### Ranked runner-up

**The OTel 0.32 generation, with `axum-tracing-opentelemetry` 0.39.1 for the server span.**
That set is `opentelemetry`/`_sdk`/`-otlp` 0.32.x, `tracing-opentelemetry` 0.33.0,
`axum-tracing-opentelemetry` 0.39.1 (`OtelAxumLayer`, `OtelInResponseLayer`) and
`reqwest-tracing` 0.7.1 with the `opentelemetry_0_32` feature for the outbound client.

**Gate status.** As the evidence stands, `axum-tracing-opentelemetry` fails gate 4
(*Excluded by gate*). The runner-up is therefore conditional: the template's own CI must test it
on `macos-latest`, or upstream must restore its macOS job.

**It wins, provided gate 4 is satisfied, under either of two conditions.**

1. **Before P03 implements,** `axum-tracing-opentelemetry` and `reqwest-tracing` publish
   0.33-compatible releases. Using maintained, semantic-conventions-aware middleware then beats
   hand-written code, and the runner-up becomes "the same crates on 0.33". This is the most
   likely outcome, because the 0.32 cycle closed its lag in 16 days.
2. **A 0.33.x regression** in trace export surfaces before P03 implements. Staying on 0.32,
   the generation the surveyed adopters run, is then safer.

### Tradeoffs

- **Versus the runner-up (0.32 plus glue).**
  - The pick gives up about 25 lines of prebuilt server middleware, which also records
    semantic-convention attributes automatically, and prebuilt outbound middleware.
  - It accepts hand-written middleware that P03 must test.
  - This cost is accepted because mixing generations is a correctness hazard. The glue crates
    would pin the whole set to the slowest member of the release train. And the hand-written
    code uses only first-party APIs (`HeaderExtractor`, `HeaderInjector`, `set_parent`), which
    release in lockstep with the pick.
- **Versus `fastrace`.** The pick gives up lower per-span overhead. That cost is accepted
  because no workload measurement shows `tracing` overhead matters for this template, while
  `fastrace` would split the span model the library and R58 share.
- **Versus gRPC transport** (`grpc-tonic`). The pick gives up gRPC's streaming efficiency. That
  cost is accepted because HTTP/protobuf is the SIG's default, needs no Tokio coupling on the
  export path, avoids `tonic`'s footprint and RUSTSEC-2024-0376 history, and matches py.
- **Versus a Beta-free stack.** None exists. Traces are Beta in every Rust option. The accepted
  cost is a bump every 4 to 8 months.

### Parameters

- owns: none. The prompt's `## Couplings` lists no owned parameter.
- `assumes logging-pipeline-contract = — (unresolved)`. R58 has not decided
  (`inputs/prerequisites.json`: R58 `decision: missing`). This report assumes R58 assembles a
  `tracing_subscriber::Registry` with composable layers, accepts one `Option<L>` layer carrying
  a per-layer filter, and exposes the `otel` feature boundary as `otel = ["web", …]`. If R58
  chooses a non-`tracing` pipeline, this recommendation must be re-run.
- `assumes rust-edition = 2024`.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`
  (floor 1.96 at retrieval).
- `assumes license = MIT OR Apache-2.0` (gate 1 inapplicable, Q7.B).
- `assumes target-os-matrix = ubuntu-latest, macos-latest`.
- No `CONFLICT:` lines. Nothing in the recommendation needs a consumed value to change.

### Migration implications

Files P03 creates or changes in the template. These are proposals.

| File | Change |
|---|---|
| `Cargo.toml` | Add the five optional dependencies and the `otel = ["web", …]` feature shown under Recommendation. Add `opentelemetry-appender-tracing = { version = "0.33", optional = true }` to `otel` only if R58 picks P7 option (a). Add `opentelemetry_sdk` with the `testing` feature, or `opentelemetry-stdout` 0.33, as a dev-dependency for in-memory span assertions. |
| `src/web/telemetry.rs` (new; its OTel half is `#[cfg(feature = "otel")]`) | `OtelInit`, `otel_layer`, `OtelGuard` (holds `SdkTracerProvider`), and the propagator installation |
| `src/web/settings.rs` (R77's settings type) | `otel_enabled: bool` (default `false`, env `<APP>_WEB_OTEL_ENABLED`) and `otel_shutdown_timeout` (default 5 s, and never more than R69's drain deadline). Endpoint, headers and protocol stay on the standard `OTEL_EXPORTER_OTLP_*` variables and are not duplicated. |
| R58's subscriber assembly (e.g. `src/web/logging.rs`) | `.with(otel.layer_option())`, then log `otel_unavailable` after `init()` |
| `src/web/router.rs` (R69's `build_router`) | `.layer(axum::middleware::from_fn(otel_context))`, or the `set_parent` block folded into R75's request-span middleware |
| `src/web/main.rs` (R69's serve binary) | After `with_graceful_shutdown` returns: `spawn_blocking(move \|\| guard.shutdown_with_timeout(budget))`, warning on `Err`, exit code unchanged |
| Example outbound handler (for instance `GET /demo/outbound`) | Creates an `otel.kind = "client"` span and calls `inject(&mut headers)` before sending |
| `compose.otel.yaml` or a Justfile recipe `otel-up` | A pinned OpenTelemetry Collector (contrib) with an OTLP/HTTP receiver on 4318 and a `file` exporter for traces and logs, used by the acceptance check. Optionally Jaeger for humans. |
| CI (`ubuntu-latest`, `macos-latest`) | Jobs `cargo test --features web`, `cargo test --features web,otel`, and `cargo tree`-based feature-absence checks. The collector-backed acceptance job runs on `ubuntu-latest` only, because GitHub's macOS runners lack Docker. The macOS leg runs the in-memory exporter tests. |

### Validation strategy

**Status: every check below is PLANNED. None was executed in this leg.** What *was* executed is
limited to HTTP retrievals: crates.io, the GitHub API and RustSec, as listed under Sources.

**A. Feature absence (P1, compile time).**

```bash
cargo tree -e normal --features web -i opentelemetry        # expect: error, package not found
cargo tree -e normal --features web,otel -i opentelemetry   # expect: exactly one opentelemetry v0.33.x
cargo tree -e normal --features web,otel -d | grep -E '^(opentelemetry|http) '  # expect: no duplicates
cargo +1.96 check --features web,otel                       # dependency-tree MSRV at the policy floor
```

**B. Endpoint acceptance check (P2 to P7), with the collector running.** This is the runnable
check the HIGH question asks for.

```bash
just otel-up                          # collector: OTLP/HTTP :4318 -> file exporter /tmp/otel/out.json
APP_WEB_OTEL_ENABLED=1 OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318 OTEL_BSP_SCHEDULE_DELAY=200 \
  cargo run --features web,otel --bin <app>-web &   PID=$!
curl -fsS -H 'traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01' \
  http://127.0.0.1:8080/demo/outbound             # handler calls GET /healthz on itself via the outbound client
kill -TERM $PID; wait $PID; echo "exit=$?"         # expect exit=143 (R67/R69)
jq -c '.resourceSpans[]?.scopeSpans[].spans[] | {traceId, spanId, parentSpanId, name, kind}' /tmp/otel/out.json
```

Expected behavior:

- At least three spans share `traceId` `4bf92f3577b34da6a3ce929d0e0e4736`:
  1. a SERVER span whose `parentSpanId` is `00f067aa0ba902b7` (the incoming context);
  2. a CLIENT span that is a child of span 1 (the outbound request);
  3. a SERVER span for `/healthz` that is a child of span 2. This proves the header was
     injected and extracted again.
- `resource.service.name` equals `<app>-web`.
- **P7, option (a):** log records in the same file carry that `traceId`.
- **P7, option (b):** the service's JSON log lines for the request carry `trace_id` equal to
  `4bf92f3577b34da6a3ce929d0e0e4736`.
- All spans are present after the SIGTERM. This proves the shutdown flush (P6).

**C. Degrade paths (P2).** Each case must serve normally.

| Case | Setup | Expected |
|---|---|---|
| Flag off | `otel` compiled in, `APP_WEB_OTEL_ENABLED` unset, collector up | 200 responses; the collector file stays empty; no `otel_unavailable` line |
| Kill switch | flag on, `OTEL_SDK_DISABLED=true` | Same as flag off |
| Invalid endpoint | flag on, `OTEL_EXPORTER_OTLP_ENDPOINT='::not a url'` | Starts; exactly one `otel_unavailable` warning with the build error; 200 responses |
| Collector unreachable | flag on, collector stopped | 100 sequential requests all return 200, with latency within noise of the flag-off run; `opentelemetry`-target warnings appear; SIGTERM exits 143 within `drain deadline + otel_shutdown_timeout`; a shutdown warning is logged |
| Feature off | `cargo run --features web` | Serves; no OTel symbols (`cargo tree` check A) |

**D. Hermetic unit test for both OSes.** This test needs no Docker. It uses the SDK's in-memory
exporter (`opentelemetry_sdk` `testing` feature, which is in the version feature list) and
drives `build_router` with `tower::ServiceExt::oneshot` (R69's idiom). It asserts on the parent
link from an injected `traceparent`, and that an outbound `HeaderMap` receives a `traceparent`
with the same trace ID.

**E. Performance, per the stated workload** (see Principles and implementation). The flag-off
configuration must match `web`-only within noise.

### Confidence & re-verify trigger

**Confidence: medium-high** on the architecture (bridge layer, OTLP over HTTP, three-gate
ladder, pure-addition composition). Each of these rests on primary sources:

- the crate docs
- the SIG's release note
- the `tracing-subscriber` `Option<L>` impl
- the SDK source line numbers cited above

**Confidence: medium** on the exact generation (0.33 / 0.34), for two reasons. The generation
is 8 days old, and no surveyed adopter runs it yet. The example composition and every
acceptance check are unexecuted.

**Gaps recorded.**

1. No maintained upstream example of axum 0.8 + outbound + OTLP at 0.33 exists.
2. The npm figures for the ts leads were not collected; npm is not a named endpoint.
3. `axum-tracing-opentelemetry` has no upstream macOS CI evidence (gate 4), so it is excluded
   pending the template's own CI.
4. The dependency-tree MSRV and `http` single-version checks were not run.
5. The OTel specification site and docs.rs were not fetched (not named endpoints).
6. The opentelemetry-rust responsiveness figure is distorted by `author_association`.

**Re-verify when any of the following happens.**

- R58 publishes its decision (the `logging-pipeline-contract` assumption).
- R79 selects OTel metrics (shared generation and provider lifecycle).
- `axum-tracing-opentelemetry` or `reqwest-tracing` publish OTel-0.33-compatible releases (the
  runner-up's winning condition).
- `opentelemetry` 0.33.1 ships, or 0.34.0 ships (the next lockstep bump).
- The SIG declares Traces stable in the README status table.
- **2026-12-26**, as a date backstop.

### Sources

All sources were retrieved 2026-09-26 (Pacific) / 2026-09-27 UTC.

**Registry and advisory endpoints.**

- crates.io crate figures: `https://crates.io/api/v1/crates/<name>` and `.../versions` for
  `opentelemetry`, `opentelemetry_sdk`, `opentelemetry-otlp`, `opentelemetry-http`,
  `opentelemetry-stdout`, `opentelemetry-semantic-conventions`, `opentelemetry-appender-tracing`,
  `opentelemetry-proto`, `opentelemetry-zipkin`, `opentelemetry-datadog`, `opentelemetry-jaeger`,
  `opentelemetry-instrumentation-actix-web`, `tracing-opentelemetry`, `tracing`,
  `tracing-subscriber`, `axum-tracing-opentelemetry`, `tracing-opentelemetry-instrumentation-sdk`,
  `init-tracing-opentelemetry`, `reqwest-tracing`, `reqwest-middleware`, `reqwest`, `tonic`,
  `tower-http`, `fastrace`, `fastrace-opentelemetry`, `minitrace`, `rustracing`, `logfire`.
- crates.io dependency requirements:
  `https://crates.io/api/v1/crates/<name>/<version>/dependencies` and
  `https://crates.io/api/v1/crates/<name>/<version>` for `tracing-opentelemetry` 0.34.0 and
  0.33.0, `opentelemetry` / `opentelemetry_sdk` / `opentelemetry-otlp` / `opentelemetry-http` /
  `opentelemetry-appender-tracing` 0.33.0, `axum-tracing-opentelemetry` 0.39.1,
  `tracing-opentelemetry-instrumentation-sdk` 0.38.3, `init-tracing-opentelemetry` 0.41.1,
  `reqwest-tracing` 0.7.1 and `fastrace-opentelemetry` 0.18.1.
- crates.io reverse dependencies:
  `https://crates.io/api/v1/crates/<name>/reverse_dependencies` (`meta.total`).
- RustSec package pages: `https://rustsec.org/packages/<name>.html` for every crate above. The
  following advisory pages were read: `https://rustsec.org/advisories/RUSTSEC-2025-0123.html`,
  `RUSTSEC-2024-0390`, `RUSTSEC-2024-0376`, `RUSTSEC-2025-0055`, `RUSTSEC-2023-0078`,
  `RUSTSEC-2022-0043`.

**GitHub repository statistics.**

- `https://api.github.com/repos/<o>/<r>` for `open-telemetry/opentelemetry-rust`,
  `open-telemetry/opentelemetry-rust-contrib`, `tokio-rs/tracing-opentelemetry`,
  `tokio-rs/tracing`, `davidB/tracing-opentelemetry-instrumentation-sdk`,
  `TrueLayer/reqwest-middleware`, `fast/fastrace`, `tower-rs/tower-http`, and every adopter
  repository.
- `https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` (`total_count`).
- `https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created` and `.../comments`
  (responsiveness).
- `https://api.github.com/repos/rust-lang/rust/releases/latest` (Rust 1.98.1).
- `https://api.github.com/search/code?q=OTEL_SDK_DISABLED+repo:open-telemetry/opentelemetry-rust`
  (0 hits), and the same search for `unsafe` under the SDK and OTLP paths (0 hits).

**Primary source files.** All were read through
`https://api.github.com/repos/<o>/<r>/contents/<path>`.

- `open-telemetry/opentelemetry-rust`:
  - `README.md` (Project Status table)
  - `docs/release_0.33.md`
  - `opentelemetry-otlp/src/lib.rs`
  - `opentelemetry-otlp/src/exporter/http/mod.rs`
  - `opentelemetry-sdk/src/trace/span_processor.rs`
  - `opentelemetry-sdk/src/trace/provider.rs`
  - `opentelemetry/src/global/propagation.rs`
  - `opentelemetry-otlp/examples/basic-otlp-http/src/main.rs` and its `Cargo.toml`
  - `.github/workflows/ci.yml`
- `tokio-rs/tracing-opentelemetry`:
  - `README.md`
  - `CHANGELOG.md`
  - `examples/opentelemetry-otlp.rs`
  - `src/layer.rs`
  - `.github/workflows/CI.yml`
- `tokio-rs/tracing`: `tracing-subscriber/src/layer/mod.rs`.
- `davidB/tracing-opentelemetry-instrumentation-sdk`: `.github/workflows/ci.yml`,
  `axum-tracing-opentelemetry/src/lib.rs`, `tracing-opentelemetry-instrumentation-sdk/src/lib.rs`.
- `fast/fastrace`: `.github/workflows/ci.yml`, `crates/fastrace/src/collector/global_collector.rs`.
- Code searches for `unsafe` in the two repositories above
  (`https://api.github.com/search/code?q=unsafe+repo:<o>/<r>+language:rust`).

**Adopter manifests.**

- `apollographql/router`: `apollo-router/Cargo.toml`
- `spinframework/spin`: `Cargo.toml`, `crates/telemetry/Cargo.toml`
- `pydantic/logfire-rust`: `logfire/Cargo.toml`
- `neondatabase/neon`: `Cargo.toml`
- `MaterializeInc/materialize`: `Cargo.toml`
- `GreptimeTeam/greptimedb`: `Cargo.toml`
- `juspay/hyperswitch`: `crates/router_env/Cargo.toml`

**Source repositories** (local checkouts):

- py-launch-blueprint `b55b8c26` (2026-09-22): `src/py_launch_blueprint/web/telemetry.py:20-89`,
  `web/app.py:148-151`, `web/settings.py:65-67`, `pyproject.toml` (the `otel` extra).
- ts-launch-blueprint `e5100b4f` (2026-09-15): a census of `*.ts` and `*.json` files outside
  `node_modules` for `opentelemetry` or `otel` found no matches.

**This repository.**

- `docs/port/COMMONALITY.md:307-308,329` (F303, F304, F325)
- `docs/port/OWNER-REVIEW.md` (the 2026-09-04 direction; Q7.B)
- `research/topics/69-web-framework-stack/DECISION.md` (`axum` 0.8.9, `tokio` 1.53.1, drain
  deadline, and `tower-http` left to R75)
- `research/runs/R78/2026-09-26T190312Z-8cf4b61ddead/inputs/`

**Leads for the ts follow-on project (not fetched).** When ts gains a web service, the
idiomatic realization is the OpenTelemetry JS SDK: `@opentelemetry/sdk-node`, an OTLP/HTTP
trace exporter package, and framework instrumentation. Its absence-handling should follow the
same three-gate ladder: optional install, a runtime flag, and a degrade on exporter failure.
npm figures are a recorded gap.
