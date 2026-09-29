# R78 raw report (muse engine) — OpenTelemetry integration, kind: crate

### Landscape

Category decided: Rust crates that export web-service traces via OpenTelemetry (OTLP), bridged from the service's `tracing` spans, gated behind an `otel` Cargo feature.

Three-bin map of the Rust field (bins per prompt; candidates placed from evidence below, not familiarity):

- Built-in / first-party toolchain: `tracing` + `tracing-subscriber` (Tokio project; the span/event substrate every bridge consumes). Not themselves an OTel exporter, so not shortlisted — they are the integration surface. Evidence: `tracing-opentelemetry 0.34.0` depends on `tracing ^0.1.35` and `tracing-subscriber ^0.3.22` with `registry` (`GET https://crates.io/api/v1/crates/tracing-opentelemetry/0.34.0/dependencies`, retrieved 2026-09-26).
- Established industry standard: `opentelemetry` 0.33.0 (API), `opentelemetry_sdk` 0.33.0 (SDK: tracer provider, batch processor, sampler), `opentelemetry-otlp` 0.33.0 (OTLP exporter), `tracing-opentelemetry` 0.34.0 (bridge layer). All four shortlisted. Supporting evidence: single coordinated release train (`0.33.0` across the opentelemetry-rust workspace on 2026-09-18), 1,001 reverse dependencies on the OTLP exporter and 1,055 on the bridge (`GET https://crates.io/api/v1/crates/<name>/reverse_dependencies`, retrieved 2026-09-26).
- Up-and-comer: `fastrace` 0.7.19 + `fastrace-opentelemetry` 0.18.1 (a separate span-capture ecosystem with an OTel export adapter). Evaluated under `### Up-and-comers`, not shortlisted: it duplicates rather than reuses the `tracing` substrate the base logging pipeline is built on.

Authoritative sources used and why each counts:

- Maintainers' own repositories: `open-telemetry/opentelemetry-rust` (the OpenTelemetry project's official Rust SIG implementation; 2,718 stars, pushed 2026-09-25, not archived) and `tokio-rs/tracing-opentelemetry` (the Tokio organization's bridge crate; 409 stars, pushed 2026-09-23, not archived) — authoritative because they are the canonical homes of the candidate code (`GET https://api.github.com/repos/<o>/<r>`, retrieved 2026-09-26).
- Published crate sources themselves: `opentelemetry-otlp 0.33.0`, `opentelemetry_sdk 0.33.0`, `tracing-opentelemetry 0.34.0` tarballs (feature tables in `Cargo.toml`, `src/span.rs` builder API, `src/layer.rs` `OpenTelemetryLayer`, `src/trace/provider.rs` shutdown docs) — authoritative as the exact artifacts the template would depend on (`GET https://crates.io/api/v1/crates/<name>/<version>/download`, retrieved 2026-09-26).
- crates.io API metadata (downloads, versions, dependency edges, reverse dependencies) — authoritative as the registry of record for adoption and compatibility facts (retrieved 2026-09-26).
- GitHub issue tracker data (open-issue counts, first-response sampling) — authoritative for maintenance responsiveness (retrieved 2026-09-26).
- RustSec advisory pages (404 = no advisory page exists for a crate; validated against control crate `atty`, HTTP 200 with RUSTSEC-2021-0145 and RUSTSEC-2024-0375) — authoritative for known-vulnerability status (`https://rustsec.org/packages/<name>.html`, retrieved 2026-09-26).
- OTLP / W3C Trace Context specifications (`https://opentelemetry.io/docs/specs/otlp/`, `https://www.w3.org/TR/trace-context/`) — cited as the wire standard; protocol facts used here (HTTP/protobuf default endpoint path, env-var configuration) were cross-checked against the fetched 0.33.0 crate sources rather than re-fetched from these pages this leg.

Practice evidence (well-regarded projects using the shortlisted stack; adoption shown via the reverse-dependency lists above, retrieved 2026-09-26):

- `axum-tracing-opentelemetry` 0.39.1 — the standard Axum request-span middleware; depends on both the bridge and the OTLP exporter. Relevant because R69 owns the web framework choice and Axum-family middleware is the likely span source.
- `reqwest-tracing` 0.7.1 (1.6M+ version downloads) and `tonic-tracing-opentelemetry` 0.38.0 — outbound-request span propagation for the two dominant Rust HTTP/gRPC clients; both build on `tracing-opentelemetry`. Relevant as the outbound leg of the required example.
- `autometrics` 3.0.0 — Prometheus-style metrics from `tracing` spans; shows the bridge coexists with the R79 sibling concern.
- `tracing-actix-web`, `tracing-opentelemetry-instrumentation-sdk`, `tarpc`, `clickhouse` — further framework and infrastructure adopters confirming the bridge is the ecosystem's common span-to-OTel path, not a niche adapter.

Fit framing: the template is CLI + library + web service; only the web service consumes this decision, and only behind `otel`. CLI/library fit is therefore "must cost nothing when disabled", which Cargo feature gating satisfies structurally.

### Principles and implementation

Shared requirement (source: owner direction 2026-09-04 in `docs/port/OWNER-REVIEW.md`, "Take the principles of using Otel and find the best Otel libraries and equivalents"; prompt `## Questions` HIGH): every web example demonstrates OpenTelemetry with idiomatic libraries and instrumentation for its language.

Agreement levels that must hold across py / ts / rs:

- Standard level: traces are exported as OTLP, and context propagates across the HTTP boundary and outbound requests using W3C Trace Context. This is what makes the three examples observably the same system under one collector. Must agree; verified by the same collector-side acceptance check in each repo.
- Capability level: tracing is opt-in and its absence never breaks the service. Must agree as observable behavior (service boots, serves, and shuts down cleanly with tracing absent, unconfigured, or pointing at a dead collector).
- Policy level: the required web example exercises tracing end to end (incoming context → server spans → outbound span → export → log correlation); the example itself must not become optional even though the capability is (prompt baseline review: "the required web example must not become optional").
- May vary (justified ecosystem differences): the opt-in *mechanism* — py uses a runtime install extra with `except ModuleNotFoundError` soft-degrade (`src/py_launch_blueprint/web/telemetry.py:71`); Rust uses a compile-time `otel` Cargo feature layered beyond `web` (F304, nothing-to-choose mechanism). Both preserve the capability-level principle; neither repo should imitate the other's mechanism. ts has no web service (F303), so ts agreement is currently missing capability, not drift — a follow-on project per the prompt.

Essential behaviors and observable acceptance criteria:

1. With `otel` disabled, the service builds and runs with zero OTel code in the binary; `cargo build` (no `--features otel`) succeeds and the binary has no `opentelemetry*` in `cargo tree`.
2. With `otel` enabled but no collector configured, the service boots, serves requests, and shuts down with exit 0; degradation is a warning, never a panic or failed boot.
3. With a collector reachable, one inbound request carrying a `traceparent` header yields related server + outbound spans at the collector sharing the trace ID, logs correlated to that trace, a clean export flush, and a documented unavailable-collector behavior (spans dropped after retry/backoff; service unaffected).

Architectural alternatives compared before choosing libraries:

- A. Bridge from the existing `tracing` subscriber pipeline (`tracing-opentelemetry::OpenTelemetryLayer` added to the R58 `Registry`) + OTel SDK + OTLP exporter. Spans are created once with `tracing` macros; the layer mirrors them into OTel spans and exports. Verified composable: `OpenTelemetryLayer<S, T>` implements `Layer<S>` (`src/layer.rs:1126` in the fetched 0.34.0 sources), so it is a pure `.with(...)` addition to whatever `Registry` stack R58 assembles — no restructuring of the base pipeline.
- B. Direct OTel instrumentation (application code calls the OTel API explicitly, bypassing `tracing`). Rejected: it forks span creation into two APIs, doubles instrumentation cost in handlers, and contradicts the R58 direction that the base pipeline is `tracing`-subscriber layering; every framework middleware in practice evidence uses alternative A.
- C. Separate span ecosystem (`fastrace`) with an OTel adapter. Rejected for this template: it replaces rather than reuses the `tracing` substrate (see `### Up-and-comers`).

Maturity statement (API/SDK vs. standard, per prompt): the OpenTelemetry standard and OTLP protocol are mature and stable. The Rust SDK is pre-1.0 (`0.33.0`) and still makes breaking releases on a coordinated train — API maturity is "stable in practice, version-pinned in policy": the template must pin the `0.33` train together (bridge 0.34 is the matching companion; dependency edge `opentelemetry ^0.33` verified in the fetched dependency data) and re-verify on each train bump. Dependability evidence: 216 open issues on opentelemetry-rust with median maintainer first response ~1 day among answered reporters' issues (sample of 10 newest pure issues, 2026-09-26; 5/10 without maintainer reply, 3 of them under 4 days old); 18 open issues on the bridge repo with median ~1 day (3/10 unanswered, including two long-tail replies at ~124 and ~396 days — small-maintainer-team latency, not abandonment: release 0.34.0 shipped 2026-09-23).

Performance posture: no absolute claims from unlike benchmarks (per prompt). Representative cost structure, stated qualitatively from the architecture: span creation adds one `tracing` event dispatch plus a batch-queue enqueue (amortized; export happens on a background batch processor, not the request path). With `otel` disabled the cost is exactly zero (code absent from the binary). The default HTTP exporter (`reqwest-blocking-client`) performs export I/O off the async runtime; the `grpc-tonic` alternative adds tonic + tokio to the export path. No benchmark was executed this leg (see gaps in report).

Minimal realistic example (proposed, not executed): web example with one `GET /work` handler that (1) extracts incoming `traceparent`, (2) creates a server span via the Axum-family middleware, (3) makes one outbound `reqwest` call carrying the propagated context, (4) returns 200; a `telemetry` module (cfg-gated on `otel`) builds the `SdkTracerProvider` + batch processor + OTLP exporter, installs `OpenTelemetryLayer`, and exposes `init() -> Result<ShutdownGuard, TelemetryError>` plus a no-op `init()` when the feature is off.

No `BASELINE-REVIEW:` finding: F304's feature-layering mechanism stands, and no recorded principle required challenging to reach this design.

### Dominant choice

The coordinated opentelemetry-rust release train plus the Tokio bridge: `opentelemetry` + `opentelemetry_sdk` + `opentelemetry-otlp` (all 0.33.0) with `tracing-opentelemetry` 0.34.0 as the `tracing`-subscriber bridge. It is dominant by registry adoption (tens of millions of recent downloads per member), by reverse-dependency breadth (1,001 on the exporter, 1,055 on the bridge), and by practice evidence (every cited framework middleware builds on it). There is no credible second ecosystem for OTel-native Rust tracing; the only alternative span ecosystem (`fastrace`) still exports *through* OTLP types for interop.

### Qualified shortlist

Each member passed all six fitness gates (gate evidence inline; figures retrieved 2026-09-26):

- `opentelemetry` 0.33.0 · role: OTel API (tracer, propagators, context) · 90-day: 62,550,665 · all-time: 273,825,643 · stars: 2,718 (repo `open-telemetry/opentelemetry-rust`) · last release: 0.33.0 on 2026-09-18 · maintenance: active (release train + `pushed_at` 2026-09-25) · adopters: the whole workspace, `tracing-opentelemetry`, `fastrace-opentelemetry` · trade-off: API-only; needs SDK + exporter to do anything. Gates: Apache-2.0 ✓; rust-version 1.75.0 ≤ stable-minus-2 (local stable 1.98.1 ⇒ ≈1.96) ✓; no RustSec page (HTTP 404) ✓; CI covers ubuntu-latest + macos-latest (+ windows) ✓; default features trace/metrics/logs/internal-logs, no async-runtime coupling in the API crate ✓; thin API types, negligible size/compile cost ✓.
- `opentelemetry_sdk` 0.33.0 · role: tracer provider, batch/simple span processors, samplers · 90-day: 56,622,256 · all-time: 228,106,882 · stars: 2,718 (same repo) · last release: 0.33.0 on 2026-09-18 · maintenance: active · adopters: `opentelemetry-otlp`, every framework middleware transitively · trade-off: pulls the SDK's processor/sampler machinery even for small services. Gates: Apache-2.0 ✓; rust-version 1.75.0 ✓; no RustSec page ✓; same CI ✓; default features trace/metrics/logs/internal-logs; tokio only behind optional `experimental_*_with_async_runtime` / exporter features — batch export works without tokio on defaults ✓; moderate compile cost, zero `unsafe` in `src/` (fetched tarball grep) ✓.
- `opentelemetry-otlp` 0.33.0 · role: OTLP span/metric/log exporter (HTTP and gRPC transports) · 90-day: 42,719,223 · all-time: 160,082,417 · stars: 2,718 (same repo) · last release: 0.33.0 on 2026-09-18 · maintenance: active · adopters: `axum-tracing-opentelemetry`, `tonic-tracing-opentelemetry`, `autometrics`, `tarpc` (reverse-deps list) · trade-off: default HTTP transport trades gRPC throughput tuning for a smaller footprint. Gates: Apache-2.0 ✓; rust-version 1.75.0 ✓; no RustSec page ✓; same CI ✓; defaults are `http-proto` + `reqwest-blocking-client` (+ trace/metrics/logs/internal-logs), verified in the shipped `Cargo.toml` — HTTP/protobuf is the default transport, `grpc-tonic` is opt-in; no tokio on the default path (only via `reqwest-client`, `hyper-client`, `grpc-tonic`) ✓; default tree is reqwest-blocking + prost; zero `unsafe` in `src/` ✓.
- `tracing-opentelemetry` 0.34.0 · role: `Layer` bridge mirroring `tracing` spans/events into OTel · 90-day: 46,486,213 · all-time: 210,280,833 · stars: 409 (repo `tokio-rs/tracing-opentelemetry`; split out of `tokio-rs/tracing` — recorded repo per crates.io metadata) · last release: 0.34.0 on 2026-09-23 · maintenance: active · adopters: `reqwest-tracing`, `axum-tracing-opentelemetry`, `tracing-actix-web`, `tracing-opentelemetry-instrumentation-sdk` · trade-off: version-locked to the OTel train (0.34 ↔ OTel 0.33; edge `opentelemetry ^0.33`, `tracing ^0.1.35`, `tracing-subscriber ^0.3.22` verified) so train bumps must move together. Gates: MIT ✓; rust-version 1.75.0 ✓; no RustSec page ✓; CI covers ubuntu-latest + macos-latest (+ windows) ✓; defaults `tracing-log` + `metrics`; no async-runtime coupling (pure `Layer`) ✓; thin bridge, zero `unsafe` in `src/` ✓.

### Excluded by gate

- `opentelemetry-jaeger` 0.22.0 — excluded on maintenance fitness. Last release 2024-05-15 (28 months stale; workspace peers are at 0.33.0), while upstream Jaeger accepts OTLP natively, making a dedicated native-protocol exporter obsolete. Concrete at-risk signal: frozen two major train generations behind its own workspace with the use case absorbed by OTLP. (Figures: 90-day 1,789,694, all-time 20,382,043 residual downloads; `GET https://crates.io/api/v1/crates/opentelemetry-jaeger`, retrieved 2026-09-26.) Not a license/MSRV/advisory failure — a superseded-mechanism exclusion.
- No shortlisted candidate failed gates 1–6; the exclusion list is this one legacy exporter only.

### Up-and-comers

- `fastrace` 0.7.19 + `fastrace-opentelemetry` 0.18.1 — an independent high-performance span-capture ecosystem (TiKV-origin, repo `fast/fastrace`) with an OTel export adapter. Figures: fastrace 90-day 1,416,104 / all-time 7,173,746, released 2026-07-31, rust-version 1.91.0, Apache-2.0; adapter 90-day 1,065,207 / all-time 4,968,215, released 2026-06-17 (`GET https://crates.io/api/v1/crates/<name>` + `/versions`, retrieved 2026-09-26). Why not shortlisted: it replaces the `tracing` substrate instead of bridging from it, so adopting it would fork span creation away from the R58 pipeline and every framework middleware cited above; its declared MSRV (1.91.0) is also far newer than the shortlist's 1.75.0, narrowing toolchain headroom. Watch trigger: if a future R58 revision ever abandons `tracing`-subscriber layering, re-evaluate.
- `opentelemetry-appender-tracing` 0.33.0 (90-day 8,552,512 / all-time 19,597,590; same 0.33.0 train, Apache-2.0, rust 1.75.0, no RustSec page) — the *log*-record → OTel bridge (complement of the span bridge). Not shortlisted because this item is tracing-only (R58 owns the logging pipeline; R79 owns metrics); noted here because the log-correlation leg of the acceptance check may legitimately use it once R58 decides, without changing this item's span-export decision.
- `opentelemetry-zipkin` 0.33.0 — current-train Zipkin exporter; a transport alternative for shops standardized on Zipkin rather than a collector. Not shortlisted: OTLP is the agreed standard level (see Principles), and Zipkin natively ingests OTLP anyway.

### Fit for this template

- CLI: no direct use. Fit requirement is negative: the `otel` feature must not leak into the CLI surface or default build. Satisfied structurally — OTel crates live only behind `otel`, which layers beyond `web`, and neither is in the default feature set.
- Library: no direct use. The library must stay telemetry-agnostic (plain `tracing` spans at most, which remain free-standing events without any OTel layer installed). The bridge design preserves this: unexported spans are simply never mirrored anywhere.
- Web: the sole consumer. The service's `telemetry` module (new, cfg-gated) wires provider → batch processor → OTLP/HTTP exporter → `OpenTelemetryLayer` on the R58 `Registry`; framework middleware (whatever R69 selects; Axum-family `axum-tracing-opentelemetry`-style or Actix-family equivalents exist for both stacks) creates request spans that flow through the same pipeline. Outbound propagation uses the client libraries' existing `tracing` integrations (`reqwest-tracing` or equivalent), so no custom propagation code is needed.

### Recommendation

Adopt the coordinated train behind the `otel` Cargo feature (layered beyond `web`, not in defaults):

- `opentelemetry` version `0.33`, `opentelemetry_sdk` version `0.33`, `opentelemetry-otlp` version `0.33` with default features (which select OTLP/HTTP+protobuf via `reqwest-blocking-client`: no tokio coupling on the export path, smallest viable footprint), and `tracing-opentelemetry` version `0.34` with `default-features = false` (pure span bridge; re-enable its `metrics` feature only if R79 routes metrics through OTel).
- Pin all four together; bump them only as a verified train (bridge ↔ API compatibility is major-locked: 0.34 requires OTel `^0.33`).
- Degrade semantics (this item's answer to py's F325 runtime soft-degrade): (a) feature off → telemetry module compiles to a no-op `init()`; zero OTel code in the binary; (b) feature on but unconfigured → read standard `OTEL_EXPORTER_OTLP_*` env vars with the SDK default endpoint; if exporter construction fails, log a warning and serve without a provider (global no-op tracer) — boot and shutdown stay green; (c) collector unreachable at runtime → the batch processor retries with backoff and drops spans, surfacing export errors through the SDK's internal-logs path, never panicking the service; (d) shutdown → flush via `TracerProvider::shutdown()` in the graceful-shutdown path (documented in fetched `src/trace/provider.rs`). Behaviors (b)–(d) are the runtime failure modes that survive the compile-time gating and must be covered by the acceptance check.

### Ranked runner-up

Runner-up: the same stack with `opentelemetry-otlp` features switched to `grpc-tonic` (OTLP/gRPC via tonic, tokio-coupled) instead of the default HTTP transport. It wins if the adopting shop standardizes on gRPC to its collector (existing gRPC load-balancing, mTLS via tonic, or a collector fleet that only exposes the gRPC receiver) or if export-throughput tuning favors tonic's connection multiplexing. Everything else — API, SDK, bridge, degrade semantics — stays identical, so the switch is a feature-flag change plus dependency-footprint acceptance (tonic + prost + tokio on the export path).

### Tradeoffs

- Versus the gRPC runner-up: the recommended HTTP default gives up tonic's multiplexed-stream throughput tuning and gRPC-native mTLS plumbing in exchange for a smaller dependency tree (no tonic/tokio required for export) and the ecosystem's current default (matching what most collectors and examples assume). Accepted because template defaults should minimize footprint; shops needing gRPC flip one feature.
- Versus direct OTel instrumentation (alternative B): the bridge adds one `tracing`-dispatch hop per span in exchange for a single instrumentation API shared with logging and framework middleware. Accepted because dual-API instrumentation doubles handler code and diverges from R58.
- Versus `fastrace` (alternative C): the bridge gives up fastrace's lower per-span overhead in exchange for reusing the `tracing` substrate, framework middleware, and the dominant adopter base. Accepted because template web throughput is not span-bound and ecosystem fit dominates micro-benchmarks here.
- Versus enabling the bridge's default `metrics` feature: giving it up keeps this decision tracing-only per scope (R79 owns metrics); trivially re-enabled if R79 chooses OTel metrics.
- Pre-1.0 train risk (0.33/0.34): accepted with the train-pinning + re-verify-trigger mitigation below; the alternative (no OTel, or a hand-rolled exporter) fails the owner requirement outright.

### Parameters

- `assumes logging-pipeline-contract = (pending — R58 decision missing at research time; this answer assumes the base pipeline assembles a tracing-subscriber Registry to which OpenTelemetryLayer is a pure .with() addition. Inputs snapshot: R58 acceptance missing, R58 decision missing, per inputs/prerequisites.json.)`
- `assumes rust-edition = 2024`
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`
- `assumes license = MIT OR Apache-2.0`
- `assumes target-os-matrix = ubuntu-latest, macos-latest`
- No `CONFLICT:` line: no consumed value needs changing. (If R58 selects a non-`tracing` logging substrate, this decision must be revisited through the controller rather than conflict-patched here, since the bridge architecture assumes `tracing` spans.)

### Migration implications

File-level changes in the `rs-launch-blueprint` template (all additive; no existing file's behavior changes when `otel` is off):

- `Cargo.toml` (web crate): add `otel = ["web", "dep:opentelemetry", "dep:opentelemetry_sdk", "dep:opentelemetry-otlp", "dep:tracing-opentelemetry"]` feature plus the four optional dependencies with the versions in `### Recommendation` (otlp defaults; bridge `default-features = false`).
- New `src/telemetry.rs` (or `web/telemetry.rs`): cfg-gated `init()` returning a shutdown guard; no-op `init()` under `not(feature = "otel")`; env-var endpoint configuration; warning-and-continue on exporter build failure.
- Base-pipeline assembly point (owned by R58): one additive `.with(opentelemetry_layer)` under `cfg(feature = "otel")` — no restructuring.
- Web example (e.g. `examples/web-otel/` or the required web example's handler): one instrumented endpoint + one outbound call demonstrating propagation; shutdown hook calling `provider.shutdown()`.
- CI/docs: document `OTEL_EXPORTER_OTLP_*` configuration and the unavailable-collector behavior; no new OS matrix entries (gates already cover ubuntu + macos).

### Validation strategy

Planned checks (proposed; none executed this leg — no code was compiled or run):

1. Feature-absence check: `cargo build` (defaults) succeeds; `cargo tree -e normal | grep -c opentelemetry` returns 0. Expected: clean build, no OTel in tree.
2. Feature-presence check: `cargo build --features otel` succeeds on ubuntu-latest and macos-latest; `cargo tree -e normal --features otel | grep opentelemetry` shows the 0.33/0.34 train only. Expected: single-version train, no duplicates.
3. Degrade check: run the example with `otel` enabled and no collector (unset/closed endpoint); curl the endpoint; stop the service. Expected: HTTP 200, exit 0, exactly one startup warning about export unavailability, no panic.
4. End-to-end collector check: start an OTel collector (or the SDK `in_memory_exporter` in a test harness — `src/trace/export.rs`/`in_memory_exporter.rs` exist in the fetched SDK sources); send a request with a `traceparent` header; assert server + outbound spans share the trace ID at the receiver; assert correlated log records; exercise shutdown flush and the collector-killed-mid-run path. Expected: related spans observed, logs correlated, clean flush, dropped-spans-only on collector loss.
5. Gate regression: `cargo deny` (license/advisory) and `rust-version` MSRV check on the locked tree; re-run on every train bump.

Executed results: none this leg (research worker; empirical execution belongs to synthesis/acceptance per the runbook).

### Confidence & re-verify trigger

Confidence: high in the stack choice (dominant adoption, coordinated train, verified API compatibility edges, zero-gate-failure shortlist, pure-addition bridge composition confirmed in the shipped sources). Medium in two details that rest on documentation rather than executed proof: exact unavailable-collector retry/drop tuning of the batch processor, and the `tracing-log`/`metrics`-disabled bridge build (recommended `default-features = false` was not compiled this leg).

Re-verify when any of: the opentelemetry-rust train releases 0.34+ (re-check bridge companion version + dependency edges); R58 resolves `logging-pipeline-contract` to a non-`tracing` substrate (revisit bridge architecture); R79 routes metrics through OTel (re-enable bridge `metrics`); any shortlist member gains a RustSec advisory or declares `rust-version` newer than stable-minus-2; or 2027-01-31, whichever comes first.

### Sources

Retrieval date for all live endpoints: 2026-09-26. Engine: muse (Meta).

- Registry metadata: `GET https://crates.io/api/v1/crates/opentelemetry`, `.../opentelemetry_sdk`, `.../opentelemetry-otlp`, `.../tracing-opentelemetry`, `.../opentelemetry-appender-tracing`, `.../fastrace`, `.../fastrace-opentelemetry`, `.../opentelemetry-jaeger`, `.../opentelemetry-zipkin`, `.../opentelemetry-http` (recent/all-time downloads, max version, repo, rust-version, license).
- Release data: `GET https://crates.io/api/v1/crates/<name>/versions` (newest non-yanked `num` + `created_at` per candidate above).
- Compatibility edges: `GET https://crates.io/api/v1/crates/tracing-opentelemetry/0.34.0/dependencies`, `GET https://crates.io/api/v1/crates/opentelemetry-otlp/0.33.0/dependencies`, `GET https://crates.io/api/v1/crates/opentelemetry_sdk/0.33.0/dependencies`.
- Stars/archived/pushed: `GET https://api.github.com/repos/open-telemetry/opentelemetry-rust` (2,718 stars, pushed 2026-09-25), `GET https://api.github.com/repos/tokio-rs/tracing-opentelemetry` (409 stars, pushed 2026-09-23). (Unauthenticated quota exhausted, HTTP 403; same endpoints re-read via authenticated `gh api`.)
- Open-issue counts: `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` → 216 (opentelemetry-rust), 18 (tracing-opentelemetry); responsiveness from 10 newest pure issues + first-comment `author_association` per issue.
- CI matrices: `.github/workflows/ci.yml` (opentelemetry-rust) and `.github/workflows/CI.yml` (tracing-opentelemetry) via `GET https://api.github.com/repos/<o>/<r>/contents/...` — both test ubuntu-latest + macos-latest (+ windows-latest).
- Shipped sources: `GET https://crates.io/api/v1/crates/opentelemetry-otlp/0.33.0/download`, `.../tracing-opentelemetry/0.34.0/download`, `.../opentelemetry_sdk/0.33.0/download` — feature tables (`default = ["http-proto", "reqwest-blocking-client", ...]`), `src/layer.rs` (`OpenTelemetryLayer`, `Layer` impl, `with_tracer`), `src/span.rs` (`builder()`, `with_tonic`/`with_http`, `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`), `src/trace/provider.rs` (`shutdown`), zero `unsafe` matches in all three `src/` trees.
- Advisories: `https://rustsec.org/packages/<name>.html` → HTTP 404 (no advisory page) for all five shortlist-relevant crates; control `https://rustsec.org/packages/atty.html` → HTTP 200 with RUSTSEC-2021-0145, RUSTSEC-2024-0375, validating the 404-means-clean reading.
- Adopters: `GET https://crates.io/api/v1/crates/opentelemetry-otlp/reverse_dependencies` (1,001 total) and `.../tracing-opentelemetry/reverse_dependencies` (1,055 total).
- Local toolchain context: `rustc 1.98.1` (2026-09-01) — used only to interpret the relative MSRV policy, not as a source-repo claim.
- Prompt and inputs: `research/topics/78-opentelemetry-integration/prompts/opentelemetry-integration.prompt.md`; run inputs under `research/runs/R78/2026-09-26T190312Z-8cf4b61ddead/inputs/` (prompt, parameters, prerequisites snapshots).
