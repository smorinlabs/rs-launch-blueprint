### Landscape

**Research date and evidence convention:** all web sources and package metadata cited below were retrieved on **September 18, 2026**. Repository paths such as F250–F304 are owner-supplied evidence from the prompt. Proposed implementation checks were not executed against `rs-launch-blueprint`.

**Quantitative evidence limitation:** the mandated crates.io and GitHub REST endpoints were requested, but this research environment could not retrieve their JSON responses. I therefore do **not** substitute estimated downloads, HTML issue counts, or rounded stars for the required figures. Those fields are marked `UNAVAILABLE`, not zero. Release versions and dates are corroborated from docs.rs, and exact collection commands are included under `### Validation strategy`. This means the architecture recommendation is fit-complete but the maintenance ledger is not evidence-complete until those commands run.

#### Three-bin field map

| Bin | Candidates found | Assessment for CLI + library + optional web |
|---|---|---|
| **Built-in or first-party toolchain** | `eprintln!`, `std::io::IsTerminal`; Rust-project `log`; Rust CLI WG’s `env_logger` | `IsTerminal` removes the need for an `atty` dependency. `log` is a strong host-owned facade and now supports key-values, but `env_logger` remains a conventional record formatter without async causal spans or a native OpenTelemetry trace layer. ([doc.rust-lang.org](https://doc.rust-lang.org/stable/std/io/trait.IsTerminal.html)) |
| **Established industry standard** | `tracing`, `tracing-subscriber`, `tracing-opentelemetry`, OpenTelemetry Rust API/SDK/OTLP; `slog` | `tracing` supplies structured events and spans; `tracing-subscriber` supplies native layered composition; `tracing-opentelemetry` is the maintained bridge to the official OpenTelemetry Rust SDK. `slog` remains a credible structured/drain architecture but lacks comparably strong current web-middleware and OTel practice evidence for this template. ([docs.rs](https://docs.rs/crate/tracing/latest)) |
| **Up-and-comer** | `emit`, `logforth`, `redactkit`, `redactable`, `tracing-microjson` | `emit` and `logforth` are active modern alternatives; `logforth` documents an MSRV of 1.89 and says its core APIs are still evolving. `redactkit` and `redactable` are useful redaction leads, but the former explicitly redacts formatted output only and neither replaces cross-sink policy enforcement. ([docs.rs](https://docs.rs/crate/emit/latest)) |

#### Authorities used

1. **Rust project sources:** the standard-library `IsTerminal` API, the official release channel, and the `rust-lang/log` repository establish toolchain support, the current MSRV reference point, and Rust’s application-versus-library logging ownership convention. Rust stable is **1.98.1** as of September 18, 2026, so the fixed “stable minus two minor versions” template MSRV is **1.96**. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))
2. **Tokio maintainers’ documentation:** authoritative for `tracing`, subscriber composition, global-dispatch semantics, reload behavior, and the recommendation that libraries emit events but do not install a global subscriber. ([docs.rs](https://docs.rs/crate/tracing/latest))
3. **OpenTelemetry project and specification:** authoritative for trace context, SDK/exporter roles, OTLP, and the Rust compatibility line. ([docs.rs](https://docs.rs/crate/tracing-opentelemetry/latest))
4. **OWASP Logging Cheat Sheet:** authoritative security guidance for excluding access tokens, passwords and similar data, and for sanitizing event data against log injection. ([cheatsheetseries.owasp.org](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html))
5. **Annual Rust survey:** reviewed as broad community context, but it does not rank logging architectures and therefore was not used to select a crate. ([blog.rust-lang.org](https://blog.rust-lang.org/2025/02/13/2024-State-Of-Rust-Survey-results/))
6. **Independent ecosystem map:** the Rust Project Primer corroborates `log`, `tracing`, and `slog` as the principal architectural families, but it is supporting—not decisive—evidence. ([rustprojectprimer.com](https://rustprojectprimer.com/ecosystem/logging.html))

#### Practice evidence

- **Cargo**, the official Rust package manager, directly uses `tracing 0.1.44` and `tracing-subscriber 0.3.23`, including the `env-filter` capability. That is strong CLI/toolchain practice evidence. ([github.com](https://github.com/rust-lang/cargo/blob/master/Cargo.toml))
- **rust-libp2p** is a shared adopter of the complete proposed compatibility line: `tracing 0.1`, `tracing-subscriber 0.3`, `tracing-opentelemetry 0.33`, and OpenTelemetry `0.32`. It is especially relevant as a concurrent networking library plus executable/examples ecosystem. ([github.com](https://github.com/libp2p/rust-libp2p/blob/master/Cargo.toml))
- **AWS SDK for Rust** directs applications to initialize `tracing-subscriber`; **tower-http** implements its HTTP request tracing around `tracing`. These show library-host ownership and web middleware convergence. ([docs.aws.amazon.com](https://docs.aws.amazon.com/sdk-for-rust/latest/dg/aws-sdk-rust-developer-guide.pdf))
- **Buck2** uses `tracing-subscriber` with JSON, registry, and environment filtering, providing another large application example of the structured-console pattern. ([github.com](https://github.com/facebook/buck2/blob/main/shim/third-party/rust/Cargo.toml))

#### Required figures

| Crate | 90-day downloads | All-time downloads | Newest non-yanked release, corroborated | GitHub REST figures | Issue responsiveness |
|---|---:|---:|---|---|---|
| `tracing` | `UNAVAILABLE` | `UNAVAILABLE` | `0.1.44`, 2025-12-18 | `UNAVAILABLE` | `UNAVAILABLE` |
| `tracing-subscriber` | `UNAVAILABLE` | `UNAVAILABLE` | `0.3.23`, 2026-03-13 | Same `tokio-rs/tracing` repository; `UNAVAILABLE` | `UNAVAILABLE` |
| `tracing-opentelemetry` | `UNAVAILABLE` | `UNAVAILABLE` | `0.33.0`, 2026-05-18 | `UNAVAILABLE` | `UNAVAILABLE` |
| `opentelemetry` | `UNAVAILABLE` | `UNAVAILABLE` | `0.33.0`, 2026-09-18; selected line is `0.32` | Shared OTel repository; `UNAVAILABLE` | `UNAVAILABLE` |
| `opentelemetry_sdk` | `UNAVAILABLE` | `UNAVAILABLE` | `0.33.0`, 2026-09-18; selected line is `0.32.1` | Shared OTel repository; `UNAVAILABLE` | `UNAVAILABLE` |
| `opentelemetry-otlp` | `UNAVAILABLE` | `UNAVAILABLE` | `0.33.0`, 2026-09-18; selected line is `0.32` | Shared OTel repository; `UNAVAILABLE` | `UNAVAILABLE` |

The release corroboration comes from docs.rs; it is not represented as a successful fetch of the mandated crates.io API endpoints. ([docs.rs](https://docs.rs/crate/tracing/latest))

#### Fitness gates before popularity

| Architecture | Gate result |
|---|---|
| **`tracing` bundle** | **Conditional pass.** Licenses are MIT for the Tokio tracing crates and Apache-2.0 for OpenTelemetry. Current documented MSRVs—1.65 for tracing-family crates and 1.75 for OTel 0.32—are below 1.96. Core tracing has no async-runtime dependency; exporter transport is optional. The stack is not asserted to be `unsafe`-free and has historical RustSec entries, so the actual lockfile must pass `cargo audit` and `cargo geiger`. Ubuntu/macOS template CI remains mandatory. ([github.com](https://github.com/tokio-rs/tracing/blob/main/tracing-subscriber/Cargo.toml)) |
| **`log` + `env_logger`** | Fitness-compatible, but **fails the required-capability gate**: a custom formatter could add JSON and redaction, and `log` can carry key-values, but causal spans, web trace propagation, console correlation, and OTel export would require constructing a second architecture around it. ([github.com](https://github.com/rust-lang/log)) |
| **`slog` drain tree** | Structurally capable of structured output and redacting drains, and explicit logger values are attractive for ownership. Excluded on ecosystem fit: no comparably maintained and practiced first-class OTel/web integration was established in this survey. ([docs.rs](https://docs.rs/crate/slog/latest)) |
| **`emit`** | Promising modern diagnostics model, but excluded from the qualified shortlist because equivalent mainstream adopter, tower/web middleware, and maintained reference-integration evidence was not established. ([docs.rs](https://docs.rs/crate/emit/latest)) |
| **`logforth`** | Current MSRV 1.89 fits, but its documentation says core APIs are still being stabilized. It is an up-and-comer, not the template default. ([docs.rs](https://docs.rs/crate/logforth/latest)) |
| **`redactkit` as the redaction answer** | Excluded as the sole control because it explicitly sanitizes formatted output only; raw values remain available to OTel and other layers. ([docs.rs](https://docs.rs/crate/redactkit/latest)) |

### Principles and implementation

#### Shared requirement and agreement level

The shared engineering principle is:

> **Diagnostics are a security-sensitive, host-owned observability boundary: emit structured facts once, let the executable compose their destinations, prevent sensitive values from crossing any egress boundary, and preserve enough context to correlate a failure across local logs and distributed traces.**

The required agreement level is **architectural pattern plus policy**, with capability-level acceptance tests. Agreement is **not** required on Python’s processor-chain mechanism or TypeScript’s writer implementation.

This derives from:

- F250/F251: machine-parseable and human-readable representations of the same structured event;
- F252: centrally enforced secret handling;
- F253/F304: optional dependency inclusion, but a working OTel web integration when that surface exists;
- F254/F274: predictable exact-level precedence;
- F262: the host owns process-global diagnostics;
- F263: one engine with front-end-specific policy.

#### What must agree and what may vary

| Must agree across CLI and web | May differ by front-end or ecosystem |
|---|---|
| Structured event fields, stable level vocabulary and stable JSON schema | CLI defaults to `auto`; web defaults to JSON |
| Same case-insensitive sensitive-key policy and `[REDACTED]` mask | Human color, target display and span rendering |
| Flag > environment > config file > inherited `-q`/`-v` ladder | Web may have an independent OTel sampler/filter |
| Library emits but never initializes global diagnostics | Rust uses `Layer`, `Visit`, `FormatFields`, exporter decorators and reload handles rather than structlog processors |
| No duplicate handlers/lines after repeated initialization | Only console level is reloadable; format, writer and OTel provider changes require restart |
| Valid active trace/span IDs appear in console output when OTel is enabled | CLI-only builds contain no OTel dependencies |
| Console output goes to stderr | R59 may later add a separately filtered file layer |

#### Architectural alternatives

1. **Conventional `log` records plus `env_logger`:** excellent producer/backend separation and host ownership. `log` now has structured key-values, so it is not merely a string API. It still lacks the event/span context required for async web requests, and `env_logger` does not provide the necessary OTel layer or correlation. Choosing it would mean implementing a parallel context-propagation system. ([github.com](https://github.com/rust-lang/log))
2. **`slog` logger/drain graph:** closest to a processor/drain pipeline and naturally supports explicit ownership. It is less native to current tower-based web middleware and no equally strong maintained OTel bridge was established. ([docs.rs](https://docs.rs/crate/slog/latest))
3. **`tracing` events/spans plus layered subscriber:** directly represents structured facts and causal scopes, accepts records from `log`-instrumented dependencies, lets each destination have its own filter, and has a maintained OpenTelemetry bridge. This best matches the combined CLI/library/web requirement. ([docs.rs](https://docs.rs/crate/tracing/latest))
4. **Newer diagnostics frameworks:** `emit` and `logforth` merit future review, but fit and integration evidence is weaker than for `tracing`. ([docs.rs](https://docs.rs/crate/emit/latest))

#### Recommended native composition

```text
tracing events/spans from library, CLI and web
                  │
                  ▼
       tracing-subscriber Registry
          ├── console fmt layer
          │     ├── reloadable per-layer LevelFilter
          │     ├── CLI or web profile
          │     ├── redacting field visitor
          │     ├── control-character escaping
          │     └── optional trace_id/span_id formatter
          │                         └── stderr
          │
          ├── optional tracing-opentelemetry layer
          │                         ▼
          │               OpenTelemetry SDK
          │                         ▼
          │              RedactingSpanExporter
          │                         ▼
          │                       OTLP
          │
          └── future R59 file layer
                └── must reuse the same redaction policy
```

A single global `Registry` supplies span identity; destinations are `Layer`s. This is the native Rust equivalent of a processor pipeline, but layers observe the same original event rather than transforming it serially for the next layer. ([docs.rs](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/layer/))

That distinction drives the redaction design.

#### Secret redaction

**Recommendation: hand-roll the small policy and visitors; do not adopt a redaction crate as the security boundary.**

Implement one local `RedactionPolicy`:

```rust
const REDACTED: &str = "[REDACTED]";

const SENSITIVE_KEY_PARTS: &[&str] = &[
    "token",
    "password",
    "passwd",
    "secret",
    "authorization",
    "cookie",
    "api_key",
    "apikey",
    "private_key",
    "client_secret",
    "credential",
];

fn is_sensitive_key(name: &str) -> bool {
    SENSITIVE_KEY_PARTS
        .iter()
        .any(|part| ascii_contains_ignore_case(name, part))
}
```

Apply it in three places:

1. **Console event and span formatting:** implement `tracing::field::Visit` plus `tracing_subscriber::fmt::FormatFields`. Preserve the field name but replace the entire value with `[REDACTED]`. The visitor API is expressly intended for typed field recording. ([docs.rs](https://docs.rs/tracing/0.1.44/tracing/field/trait.Visit.html))
2. **OTel export:** decorate the `SpanExporter`, sanitizing span attributes, span-event attributes and link attributes immediately before delegation to OTLP. A formatting-only helper is insufficient because the OTel layer receives original field values. `redactkit` documents this exact limitation. ([docs.rs](https://docs.rs/crate/redactkit/latest))
3. **At source:** secrets should use local redacted wrapper types, and `#[instrument]` must use `skip` or `skip_all` for request bodies, credentials and configuration objects. Key matching cannot protect a secret interpolated into the free-form `message` field or hidden inside a non-sensitive `Debug` object. `#[instrument]` records function parameters by default, so this is an explicit migration rule. ([docs.rs](https://docs.rs/crate/tracing/latest))

Additional controls:

- The human formatter must escape ESC, CR, LF and other control characters rather than writing raw user values. This avoids reintroducing the terminal-injection class fixed in `tracing-subscriber >=0.3.20`. ([deps.rs](https://deps.rs/crate/tracing-opentelemetry/latest))
- Web instrumentation should allowlist fields such as method, route template, status, latency and request ID. It should not log raw `Authorization`, `Cookie`, query strings or request bodies. OWASP likewise identifies passwords, access tokens, session identifiers and similar data as values that should not normally be recorded directly. ([cheatsheetseries.owasp.org](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html))
- An OTel Collector redaction processor is useful defense in depth, but not a substitute for in-process sanitization before network egress. ([github.com](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/processor/redactionprocessor/README.md))

A custom subscriber **layer alone is the wrong abstraction** for redaction: it cannot mutate an event for subsequent layers. The correct pattern is one shared predicate with sink-specific adapters.

#### OpenTelemetry support and correlation

`tracing-opentelemetry` provides maintained first-class conversion of `tracing` spans and in-span events into OpenTelemetry spans/events. It can be Cargo-feature gated exactly as Python soft-imports its optional dependency. ([docs.rs](https://docs.rs/tracing-opentelemetry/latest/tracing_opentelemetry/fn.layer.html))

There is an important qualification:

- **Trace creation, propagation and export:** first-class.
- **Automatically adding OTel `trace_id` and `span_id` to `tracing-subscriber` JSON console lines:** not turnkey. The tracing repository still has an open feature request for injecting these extra fields into the JSON formatter. A custom `FormatEvent` is therefore required. ([github.com](https://github.com/tokio-rs/tracing/issues/1531))

The formatter should:

- add lowercase hexadecimal `trace_id` and `span_id` only when the active context is valid;
- omit them outside a span rather than emit zero IDs;
- use the same IDs exported by the OTel layer;
- avoid treating `--log-level` as the OTel sampling control.

The console filter must therefore be a **per-layer filter**. A quiet console must not silently turn off web tracing. The OTel sampler and any telemetry event filter belong to R78.

As of **September 18, 2026**, OpenTelemetry API/SDK/OTLP `0.33.0` was released that day, but `tracing-opentelemetry 0.33.0` declares `opentelemetry ^0.32.0`. The compatible recommendation is therefore the OTel `0.32` line until a newer bridge release explicitly supports `0.33`. ([docs.rs](https://docs.rs/crate/tracing-opentelemetry/latest))

#### Host ownership, idempotence and reload

Libraries should depend on `tracing` and emit events; they should not set a subscriber. Tokio’s documentation explicitly warns libraries not to call `set_global_default`. ([docs.rs](https://docs.rs/crate/tracing/latest))

The application support code should expose two levels:

```rust
pub fn build_diagnostics(
    config: &ResolvedDiagnostics,
    writer: impl MakeWriter + Send + Sync + 'static,
) -> Result<BuiltDiagnostics>;

pub(crate) fn try_install_global(
    config: &ResolvedDiagnostics,
) -> Result<InitOutcome>;
```

`build_diagnostics` is side-effect-free with respect to globals and returns a `Dispatch`, reload handle and optional OTel provider guard. Tests and embedding hosts can use the dispatch in a scoped context.

`try_install_global` is binary-only and follows these rules:

1. If this module has never installed a subscriber, build it and call a fallible global initializer.
2. If another host already installed one, return `InitOutcome::HostOwned`; do not panic, replace it or install `env_logger`.
3. If this module already owns the subscriber and only the console level changed, update its `reload::Handle`.
4. If format, profile, writer, OTel endpoint or resource configuration changed, return `RestartRequired`; do not attempt replacement.
5. Retain the `SdkTracerProvider` and explicitly flush/shut it down during orderly web-service termination.

The global default is process-wide and normally set once. `tracing-subscriber::reload` is the supported mechanism for a small dynamically changing filter and documents its overhead as relatively small. ([docs.rs](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/reload/))

This is materially different from Python’s handler removal/reinstallation. OpenTelemetry’s own issue tracker also documents unresolved complexity around bounded shutdown and in-flight telemetry, reinforcing the need to own and explicitly close the provider. ([github.com](https://github.com/open-telemetry/opentelemetry-rust/issues/3542))

#### Log-level resolution

The pipeline consumes—not parses—the verbosity controls:

```text
1. command-line --log-level
2. <APP>_LOG_LEVEL environment variable
3. config-file exact level
4. level produced by R60/R273's -q/-v/--debug ladder
```

Within the first tier, an explicit command-line value wins over the environment. The resolved value is one of `off | error | warn | info | debug | trace` and becomes a reloadable `LevelFilter` on the console layer.

Do **not** call `EnvFilter::from_default_env()` in the default implementation: an ambient `RUST_LOG` would introduce an undocumented tier ahead of F274. `EnvFilter` can be added later only through an explicit, separately documented advanced-filter setting.

#### CLI and web profiles

| Policy | CLI profile | Web profile |
|---|---|---|
| Default format | `auto`: human when stderr is terminal, JSON otherwise | JSON |
| Explicit format | `auto | human | json` | `human | json`, with JSON default |
| Destination | stderr | stderr |
| Console level | F274 resolver | Same resolver from available config/env inputs |
| OTel | Not compiled in base CLI build | Optional Cargo feature, mandatory CI example if R69 enables web |
| Access fields | Command/action/result | Method, route template, status, latency, request ID |
| Trace IDs | Only if web/OTel-enabled execution supplies a valid context | Included when valid |

TTY detection uses `std::io::IsTerminal`, stable since Rust 1.70 and implemented for Unix handles, so no additional terminal-detection crate is needed for Ubuntu or macOS. ([doc.rust-lang.org](https://doc.rust-lang.org/stable/std/io/trait.IsTerminal.html))

A process installs **one** subscriber. CLI and web are configuration profiles, not independently initialized global subscribers. If a CLI command launches the web server, it selects the web profile before the one installation.

#### Minimal realistic composition

```toml
[dependencies]
tracing = "0.1.44"
tracing-subscriber = { version = "0.3.23", features = ["json"] }

[features]
default = []
web-otel = [
  "dep:tracing-opentelemetry",
  "dep:opentelemetry",
  "dep:opentelemetry_sdk",
  "dep:opentelemetry-otlp",
]

[dependencies.tracing-opentelemetry]
version = "0.33"
optional = true
default-features = false

[dependencies.opentelemetry]
version = "0.32"
optional = true
default-features = false
features = ["trace"]

[dependencies.opentelemetry_sdk]
version = "0.32.1"
optional = true
default-features = false
features = ["trace"]

[dependencies.opentelemetry-otlp]
version = "0.32"
optional = true
default-features = false
features = ["trace", "http-proto", "reqwest-blocking-client"]
```

If R69/R78 select a Tokio-native gRPC transport, only the final OTLP transport features change; the event, subscriber, redaction and ownership architecture does not.

```rust
use tracing_subscriber::{
    filter::LevelFilter,
    fmt,
    layer::SubscriberExt,
    reload,
    Layer,
};

fn build(config: &ResolvedDiagnostics) -> Result<BuiltDiagnostics> {
    let style = config.resolve_style(std::io::stderr().is_terminal());

    let (console_filter, reload_handle) =
        reload::Layer::new(LevelFilter::from_level(config.console_level));

    let console = fmt::layer()
        .with_writer(std::io::stderr)
        .fmt_fields(SanitizingFields::new(config.redaction.clone()))
        .event_format(DiagnosticEventFormat::new(
            style,
            config.redaction.clone(),
        ))
        .with_filter(console_filter);

    #[cfg(feature = "web-otel")]
    let (otel_layer, provider) = build_otel(config)?;

    #[cfg(not(feature = "web-otel"))]
    let otel_layer = None;

    let subscriber = tracing_subscriber::registry()
        .with(otel_layer)
        .with(console);

    Ok(BuiltDiagnostics::new(
        tracing::Dispatch::new(subscriber),
        reload_handle,
        provider,
    ))
}
```

This is the intended composition shape. The generic details of the custom `FormatFields`, `FormatEvent` and exporter implementations must be fixed by a compiling reference example rather than copied untested from prose.

#### Performance and integration cost

No surveyed benchmark matched this workload—TTY/human versus JSON, key redaction, active spans, optional OTel, stderr I/O—and therefore no “fastest logger” claim is made.

Representative workload to measure:

- 1,000,000 disabled `debug!` events;
- 100,000 enabled events to `io::sink()`, with 0, 4 and 12 fields;
- human versus JSON;
- no sensitive keys versus 25% sensitive keys;
- OTel disabled versus 1% and 100% sampled spans;
- synchronous test exporter versus bounded batch OTLP exporter.

Record event-call p50/p95/p99 latency, events/s, allocations, peak RSS, dropped spans, binary size and clean incremental build time. `reload` should be measured both present and absent. The OTel feature is expected to have the largest compile-time and binary-size cost and is therefore feature-gated; docs.rs build metadata also shows a meaningfully larger exporter dependency surface than the core producer. ([docs.rs](https://docs.rs/crate/tracing/latest))

#### Observable acceptance criteria

1. Identical event fields produce valid human and NDJSON representations.
2. `auto` selects human only when injected stderr terminal status is true.
3. Every sensitive-key case is masked in human output, JSON output and captured OTel `SpanData`.
4. Raw ESC, CR and LF from untrusted fields cannot alter terminal/log record structure.
5. Flag > environment > config > verbosity ladder is proven by a table-driven test.
6. Calling initialization twice emits one line per event; a changed level reloads without duplication.
7. A preinstalled host subscriber is not replaced or torn down.
8. Library functions emit under a host-provided scoped subscriber without initializing globals.
9. With OTel enabled, a console event’s IDs exactly equal the exported span IDs.
10. With OTel disabled, the base dependency tree contains none of the OTel crates.
11. CLI and web snapshots share schema and redaction while retaining different defaults.
12. Both Rust 1.96 and current stable pass on `ubuntu-latest` and `macos-latest`.
13. The working web example extracts incoming trace context and exports a child/server span when R69 enables web.
14. `cargo audit` reports no advisory affecting the resolved lockfile.

`BASELINE-REVIEW: F262 — host ownership is the invariant, not Python handler teardown — translate reconfiguration to one process-wide application subscriber plus an owned reloadable console filter; refuse to replace a host subscriber and require restart for structural changes — tracing’s global default is set once and its reload module is the native supported mechanism.` ([docs.rs](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/reload/))

`BASELINE-REVIEW: F304 — optionality applies to Cargo dependency inclusion, not to whether the web reference proves telemetry — keep tracing/OpenTelemetry dependencies inside the web-scoped feature boundary owned across R58/R69/R78, while requiring the working OTel web example whenever R69 enables web — tracing-opentelemetry supplies the maintained bridge and its declared dependency matrix fixes the compatible OTel line.` ([docs.rs](https://docs.rs/crate/tracing-opentelemetry/latest))

### Recommendation

Adopt this stack:

1. **`tracing 0.1.44`** as the only diagnostics producer API used by the library, CLI and web code.
2. **`tracing-subscriber 0.3.23`** as the application-owned registry, formatter and reload mechanism, with JSON enabled.
3. **Local, safe Rust components**:
   - `RedactionPolicy`;
   - `SanitizingFields: FormatFields`;
   - `DiagnosticEventFormat: FormatEvent`;
   - `RedactingSpanExporter<E>`;
   - `DiagnosticsProfile::{Cli, Web}`;
   - an executable-only idempotent installer.
4. **Web-scoped optional telemetry**:
   - `tracing-opentelemetry 0.33`;
   - `opentelemetry 0.32`;
   - `opentelemetry_sdk 0.32.1`;
   - `opentelemetry-otlp 0.32`.
5. Use **`std::io::IsTerminal`**, not `atty`.
6. Do not initialize `env_logger`; accept legacy `log` records through `tracing-subscriber`’s existing bridge.
7. Apply the exact-level resolver before constructing/reloading the console filter.
8. Keep OTel sampling/filtering independent of console verbosity.

### Members

#### tracing

##### Landscape

Established event/span instrumentation API maintained by the Tokio project. Required crates.io download figures and GitHub REST figures are `UNAVAILABLE`; the newest release is corroborated as `0.1.44` from December 18, 2025. Maintenance classification: **stable-quiet**—the specific crate has not released in more than six months, but its shared repository remains active. ([docs.rs](https://docs.rs/crate/tracing/latest))

##### Principles and implementation

It supplies structured events and causal spans while leaving collection to the host. Its documentation explicitly tells libraries to depend only on `tracing` and not install a global default. ([docs.rs](https://docs.rs/crate/tracing/latest))

##### Dominant choice

Dominant for async-aware structured instrumentation in current Tokio/tower-oriented Rust software, as demonstrated by Cargo, tower-http, AWS SDK guidance and rust-libp2p. ([github.com](https://github.com/rust-lang/cargo/blob/master/Cargo.toml))

##### Qualified shortlist

`log 0.4.34` is the qualified alternative for a library that needs flat records but no request/span causality. ([docs.rs](https://docs.rs/crate/log/latest))

##### Excluded by gate

`log` fails this item’s capability gate because OTel correlation and web request scopes would require an additional context model. `slog` is excluded on current web/OTel ecosystem fit, not basic structured-logging capability.

##### Up-and-comers

`emit 2.23.0` offers a modern diagnostics model but lacks the same surveyed practice evidence. ([docs.rs](https://docs.rs/crate/emit/latest))

##### Fit for this template

Strong fit across all three surfaces: no-op without a subscriber, host-owned in library consumers, structured CLI events, and native web spans.

##### Recommendation

Use:

```toml
tracing = "0.1.44"
```

Keep default `std` and attribute support. Do not enable compile-time maximum-level features in the library because they globally constrain a host’s diagnostics.

##### Ranked runner-up

`log 0.4.34`.

##### Tradeoffs

`#[instrument]` adds proc-macro compile cost and can accidentally record sensitive arguments. Require `skip`/`skip_all` review for every instrumented boundary. Async code must use `#[instrument]` or `.instrument(...)`, not retain an entered-span guard across `.await`. ([docs.rs](https://docs.rs/crate/tracing/latest))

##### Parameters

- Compatible license: MIT.
- Documented `rust-version`: 1.65, below required 1.96.
- No async-runtime coupling.
- Not asserted to be `unsafe`-free; RustSec lists a historical unsoundness advisory.
- Ubuntu/macOS validation remains an integration gate. ([github.com](https://github.com/tokio-rs/tracing/blob/main/tracing/Cargo.toml))

##### Migration implications

Replace hand-rolled logger calls with `tracing::{error,warn,info,debug,trace}!` and structured fields. Add spans around commands, library operations and web requests. Audit every interpolated value and automatic function argument.

##### Validation strategy

Compile and test with no subscriber, a scoped host subscriber and the global application subscriber. Add compile-fail or lint-review examples showing that secret-bearing parameters use `#[instrument(skip(...))]`.

##### Confidence & re-verify trigger

**High architectural confidence; medium maintenance-figure confidence.** Reverify on `tracing 0.2`, any new RustSec advisory, or an MSRV change above the template’s current 1.96 floor.

##### Sources

Retrieved 2026-09-18:

- `https://docs.rs/crate/tracing/0.1.44`
- `https://github.com/tokio-rs/tracing`
- `https://github.com/tokio-rs/tracing/blob/main/tracing/Cargo.toml`
- `https://rustsec.org/packages/tracing.html`
- Required metrics endpoints: `https://crates.io/api/v1/crates/tracing`, `https://crates.io/api/v1/crates/tracing/versions`, `https://api.github.com/repos/tokio-rs/tracing`

#### tracing-subscriber

##### Landscape

Established subscriber composition and formatting crate. Required API figures are `UNAVAILABLE`; newest release is corroborated as `0.3.23` from March 13, 2026. Maintenance classification: **active**, with a current release-risk caveat described below. ([docs.rs](https://docs.rs/crate/tracing-subscriber/latest))

##### Principles and implementation

Provides `Registry`, composable `Layer`s, human/JSON formatting, per-layer filters and reload support—the native Rust architecture replacing a Python processor chain. ([docs.rs](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/reload/))

##### Dominant choice

The dominant application collector paired with `tracing`; used by Cargo, rust-libp2p and Buck2. ([github.com](https://github.com/rust-lang/cargo/blob/master/Cargo.toml))

##### Qualified shortlist

`env_logger 0.11.11` for conventional `log` records; `slog` for explicit logger/drain composition. ([docs.rs](https://docs.rs/crate/env_logger/latest))

##### Excluded by gate

`env_logger` fails the span/correlation capability gate. A hand-rolled subscriber is excluded because it would recreate mature filtering, registry and compatibility behavior.

##### Up-and-comers

`logforth` is modular and current but still stabilizing its core APIs. `tracing-microjson` can reduce JSON-only dependency cost but does not solve the complete redaction/correlation contract. ([docs.rs](https://docs.rs/crate/logforth/latest))

##### Fit for this template

Best fit for one pipeline with profile-specific formatting, an independently reloadable console filter, a future R59 file layer and an optional OTel layer.

##### Recommendation

Use:

```toml
tracing-subscriber = { version = "0.3.23", features = ["json"] }
```

Keep default features for `fmt`, ANSI-aware human output, registry and `log` compatibility. Use `reload::Layer<LevelFilter>` on the console layer rather than reading `RUST_LOG`.

##### Ranked runner-up

`slog 2.8.2`, because its explicit drain graph is stronger than `env_logger` for structured multi-sink composition.

##### Tradeoffs

The global subscriber cannot be replaced. Custom `FormatFields`/`FormatEvent` code must preserve escaping and JSON validity. An open issue reports a reproducible `Dispatcher::clone_span` panic against 0.3.22/0.3.23 on both Linux and Darwin, with a proposed fix not yet represented by a release in the collected evidence. This requires a stress-test and release recheck before lockfile approval. ([github.com](https://github.com/tokio-rs/tracing/issues/3514))

##### Parameters

- License: MIT.
- Shared tracing-project MSRV is below 1.96.
- No required async runtime.
- JSON adds `serde`/`serde_json`; optional OTel is the substantial feature cost.
- Historical ANSI-injection advisory is patched in `>=0.3.20`; selected `0.3.23` is above that line. ([github.com](https://github.com/tokio-rs/tracing/blob/main/tracing-subscriber/Cargo.toml))

##### Migration implications

Add one diagnostics builder, custom formatters, one reload handle and one binary-owned installer. Remove any competing `env_logger::init()` calls.

##### Validation strategy

Run concurrency stress tests for span create/clone/drop; test raw ANSI/control characters; parse every JSON line; run repeated initialization in isolated subprocesses to avoid test-global interference.

##### Confidence & re-verify trigger

**Medium-high**, reduced by issue #3514. Reverify when a release containing its resolution appears; prefer that patched version after CI confirmation.

##### Sources

Retrieved 2026-09-18:

- `https://docs.rs/crate/tracing-subscriber/0.3.23`
- `https://docs.rs/tracing-subscriber/0.3.23/tracing_subscriber/reload/`
- `https://docs.rs/tracing-subscriber/0.3.23/tracing_subscriber/layer/`
- `https://github.com/tokio-rs/tracing/issues/3514`
- `https://rustsec.org/packages/tracing-subscriber.html`
- Required metrics endpoints: `https://crates.io/api/v1/crates/tracing-subscriber`, `https://crates.io/api/v1/crates/tracing-subscriber/versions`, `https://api.github.com/repos/tokio-rs/tracing`

#### tracing-opentelemetry

##### Landscape

Established maintained bridge between `tracing` and OpenTelemetry. Required API figures are `UNAVAILABLE`; newest release is corroborated as `0.33.0` from May 18, 2026. Maintenance classification: **active**. ([docs.rs](https://docs.rs/crate/tracing-opentelemetry/latest))

##### Principles and implementation

Adds OTel context to tracing spans, maps child-parent relationships and in-span events, and exposes context propagation through `OpenTelemetrySpanExt`. ([docs.rs](https://docs.rs/tracing-opentelemetry/latest/tracing_opentelemetry/fn.layer.html))

##### Dominant choice

It is the direct maintained bridge for the selected two ecosystems and is used with the same version line by rust-libp2p. ([github.com](https://github.com/libp2p/rust-libp2p/blob/master/Cargo.toml))

##### Qualified shortlist

Direct instrumentation through the OpenTelemetry API, or an application-specific bridge.

##### Excluded by gate

`opentelemetry-appender-tracing` alone is excluded: it addresses OTel log records, not conversion of application `tracing` spans into distributed traces.

##### Up-and-comers

Third-party correlation helper crates exist, but none established stronger maintenance and adoption evidence than a small local `FormatEvent`.

##### Fit for this template

Allows the library and CLI/web code to instrument only through `tracing`; the web feature can add export without changing event sites.

##### Recommendation

Use:

```toml
tracing-opentelemetry = {
  version = "0.33",
  optional = true,
  default-features = false
}
```

Enable only under the web-scoped telemetry feature.

##### Ranked runner-up

Direct OpenTelemetry API spans in the web layer.

##### Tradeoffs

It provides first-class trace export but not turnkey console `trace_id`/`span_id` fields. Its version is not synchronized with OpenTelemetry’s version number, making a tested compatibility matrix essential. ([github.com](https://github.com/tokio-rs/tracing/issues/1531))

##### Parameters

- License: MIT.
- Documented family MSRV: 1.65.
- Core bridge has no requirement that application code run on Tokio.
- Selected `0.33.0` requires OpenTelemetry `^0.32.0`, not the newly released 0.33 line. ([docs.rs](https://docs.rs/crate/tracing-opentelemetry/0.32.1/source/CHANGELOG.md))

##### Migration implications

Add the optional OTel layer to the same registry, update web request middleware to set extracted parent context, and add formatter correlation.

##### Validation strategy

Export a span to a capturing exporter and assert that console IDs, parent IDs and exported IDs match. Verify events outside an active span omit correlation IDs.

##### Confidence & re-verify trigger

**High for architecture, medium for version pin.** Reverify immediately when a bridge release supporting OTel 0.33 appears.

##### Sources

Retrieved 2026-09-18:

- `https://docs.rs/crate/tracing-opentelemetry/0.33.0`
- `https://github.com/tokio-rs/tracing-opentelemetry`
- `https://github.com/tokio-rs/tracing/issues/1531`
- Required metrics endpoints: `https://crates.io/api/v1/crates/tracing-opentelemetry`, `https://crates.io/api/v1/crates/tracing-opentelemetry/versions`, `https://api.github.com/repos/tokio-rs/tracing-opentelemetry`

#### opentelemetry

##### Landscape

Official OpenTelemetry Rust API. Latest is corroborated as `0.33.0`, released September 18, 2026; the selected compatibility line is `0.32.0`. Required API figures are `UNAVAILABLE`. Maintenance classification: **active**. ([docs.rs](https://docs.rs/crate/opentelemetry/latest))

##### Principles and implementation

Defines trace context, tracers, span IDs and propagation-neutral APIs used by the bridge and SDK.

##### Dominant choice

The standards-body implementation; choosing another API would abandon direct OpenTelemetry compatibility.

##### Qualified shortlist

No equivalent independent API is qualified for the same standard. Vendor SDK APIs may sit downstream of OTLP but should not replace instrumentation.

##### Excluded by gate

`0.33.0` is excluded from this exact bundle by the `tracing-opentelemetry 0.33.0 -> opentelemetry ^0.32.0` compatibility gate.

##### Up-and-comers

Inapplicable: this member is the standard API rather than a logger category.

##### Fit for this template

Needed only by the optional web feature for propagation and provider interoperability.

##### Recommendation

Use:

```toml
opentelemetry = {
  version = "0.32",
  optional = true,
  default-features = false,
  features = ["trace"]
}
```

##### Ranked runner-up

No direct runner-up; omit telemetry entirely when the web feature is absent.

##### Tradeoffs

OpenTelemetry Rust is still on a pre-1.0 version line with regular cross-crate compatibility changes. Pin one coherent minor line and upgrade it as a bundle.

##### Parameters

- License: Apache-2.0.
- OTel 0.32 manifest documents `rust-version = 1.75.0`.
- Default features include more signals than this item needs; disable defaults and select `trace`.
- No direct runtime coupling in the API crate. ([github.com](https://github.com/open-telemetry/opentelemetry-rust/blob/main/opentelemetry/Cargo.toml))

##### Migration implications

Use it only in `diagnostics/otel.rs` and web propagation code; do not expose OTel types from the core library’s public API unless R78 explicitly requires that coupling.

##### Validation strategy

Compile the base crate without it; compile the web feature with only `trace`; test valid/invalid remote parent contexts.

##### Confidence & re-verify trigger

**High**, with immediate recheck when upgrading `tracing-opentelemetry`.

##### Sources

Retrieved 2026-09-18:

- `https://docs.rs/crate/opentelemetry/0.32.0`
- `https://docs.rs/crate/opentelemetry/0.33.0`
- `https://github.com/open-telemetry/opentelemetry-rust`
- Required metrics endpoints: `https://crates.io/api/v1/crates/opentelemetry`, `https://crates.io/api/v1/crates/opentelemetry/versions`, `https://api.github.com/repos/open-telemetry/opentelemetry-rust`

#### opentelemetry_sdk

##### Landscape

Official SDK implementation. Latest is corroborated as `0.33.0`, released September 18, 2026; selected version is `0.32.1`. Required API figures are `UNAVAILABLE`. Maintenance classification: **active**. ([docs.rs](https://docs.rs/crate/opentelemetry_sdk/latest))

##### Principles and implementation

Owns sampling, span processing, batching, resources, exporter invocation, flushing and shutdown.

##### Dominant choice

The standard SDK behind the official Rust OTLP exporter.

##### Qualified shortlist

A vendor-provided SDK implementing the OTel API, or a minimal custom provider for specialized environments.

##### Excluded by gate

`0.33.0` is excluded from this bundle until the selected tracing bridge supports the same API line.

##### Up-and-comers

Inapplicable at this layer; exporter and processor experimentation should remain behind OTel traits.

##### Fit for this template

Provides the provider guard and batch processor required by a realistic web-service example while remaining absent from base CLI/library builds.

##### Recommendation

Use:

```toml
opentelemetry_sdk = {
  version = "0.32.1",
  optional = true,
  default-features = false,
  features = ["trace"]
}
```

Wrap its exporter rather than trying to mutate events inside a tracing subscriber layer.

##### Ranked runner-up

A simple processor for deterministic tests only; not the production default.

##### Tradeoffs

Batching adds a worker, memory queue, export latency and shutdown obligations. OpenTelemetry Rust tracks unresolved design complexity around cancellation and bounded shutdown, so startup and graceful shutdown are part of the architecture rather than incidental glue. ([github.com](https://github.com/open-telemetry/opentelemetry-rust/issues/3542))

##### Parameters

- License: Apache-2.0.
- Selected line fits the 1.96 MSRV.
- Async-runtime features are optional; do not enable one until R69/R78 select a transport/runtime.
- Compile and binary cost: high relative to the core stack, therefore optional.

##### Migration implications

Store `SdkTracerProvider` in `DiagnosticsGuard`; call `force_flush`/`shutdown` during web termination; surface failures through a final stderr diagnostic without recursively tracing that failure.

##### Validation strategy

Test queue saturation, export failure, forced flush and shutdown timeout with a controllable exporter. Assert that the exporter receives only sanitized attributes.

##### Confidence & re-verify trigger

**Medium-high.** Reverify shutdown behavior, processor APIs and MSRV on every OTel minor upgrade.

##### Sources

Retrieved 2026-09-18:

- `https://docs.rs/crate/opentelemetry_sdk/0.32.1`
- `https://github.com/open-telemetry/opentelemetry-rust`
- `https://github.com/open-telemetry/opentelemetry-rust/issues/3542`
- Required metrics endpoints: `https://crates.io/api/v1/crates/opentelemetry_sdk`, `https://crates.io/api/v1/crates/opentelemetry_sdk/versions`, `https://api.github.com/repos/open-telemetry/opentelemetry-rust`

#### opentelemetry-otlp

##### Landscape

Official OTLP exporter. Latest is corroborated as `0.33.0`, released September 18, 2026; selected version is `0.32.0`. Required API figures are `UNAVAILABLE`. Maintenance classification: **active**. ([docs.rs](https://docs.rs/crate/opentelemetry-otlp/latest))

##### Principles and implementation

Provides standards-compatible export to an OpenTelemetry Collector rather than coupling the template to a specific observability vendor.

##### Dominant choice

Dominant portable exporter choice for OTel-compatible backends.

##### Qualified shortlist

Vendor-specific exporters and stdout/in-memory exporters for tests.

##### Excluded by gate

`0.33.0` is excluded by bundle compatibility. A stdout exporter is excluded as the production web example because it does not prove network propagation/export.

##### Up-and-comers

Inapplicable to the logging architecture itself; alternative OTLP client implementations can remain behind the exporter trait.

##### Fit for this template

Supports a shared collector-based web example while keeping the destination vendor-neutral.

##### Recommendation

Use `0.32` under `web-otel`. The runtime-neutral reference profile should use HTTP/protobuf with the blocking reqwest client on the SDK’s exporter worker. If R69/R78 already require Tokio and choose gRPC, switch only to the tonic transport features. The 0.32 feature names are demonstrated in current production Cargo manifests. ([github.com](https://github.com/gakonst/nanocodex/blob/master/Cargo.toml))

##### Ranked runner-up

A vendor exporter behind the same `SpanExporter` decorator.

##### Tradeoffs

HTTP/gRPC clients, protobuf and TLS substantially increase compile time and binary size. Network failures, backpressure and endpoint credentials must never be recursively included in telemetry.

##### Parameters

- License: Apache-2.0.
- Selected line fits the 1.96 MSRV.
- Default features must be disabled to avoid pulling unused signals and transports.
- Runtime coupling depends on the selected transport, not the tracing core.

##### Migration implications

Add endpoint/resource configuration to the web surface; pass the concrete exporter through `RedactingSpanExporter`; add a collector service to the example.

##### Validation strategy

Send a known trace to a local collector, assert service/resource attributes, verify parent propagation and scan collector output for test secrets.

##### Confidence & re-verify trigger

**Medium-high.** Reverify on any transport/TLS decision from R69/R78 and when upgrading to OTel 0.33.

##### Sources

Retrieved 2026-09-18:

- `https://docs.rs/crate/opentelemetry-otlp/0.32.0`
- `https://docs.rs/crate/opentelemetry-otlp/0.33.0`
- `https://github.com/open-telemetry/opentelemetry-rust`
- Required metrics endpoints: `https://crates.io/api/v1/crates/opentelemetry-otlp`, `https://crates.io/api/v1/crates/opentelemetry-otlp/versions`, `https://api.github.com/repos/open-telemetry/opentelemetry-rust`

### Compatibility

There are two independent compatibility proofs.

1. **Declared dependency matrix:** `tracing-opentelemetry 0.33.0` declares:
   - `tracing ^0.1.35`;
   - `tracing-subscriber ^0.3.22`;
   - `opentelemetry ^0.32.0`.

   The recommended `tracing 0.1.44`, `tracing-subscriber 0.3.23`, and OTel 0.32 line satisfy that matrix. ([docs.rs](https://docs.rs/crate/tracing-opentelemetry/latest))

2. **Shared adopter:** rust-libp2p’s current workspace manifest contains:
   - `tracing = "0.1"`;
   - `tracing-subscriber = "0.3"`;
   - `tracing-opentelemetry = "0.33"`;
   - `opentelemetry = "0.32"`;
   - `opentelemetry_sdk = "0.32"`;
   - `opentelemetry-otlp = "0.32"`.

   This is the same bundle line recommended here. ([github.com](https://github.com/libp2p/rust-libp2p/blob/master/Cargo.toml))

Version matrix:

| Member | Recommended |
|---|---|
| `tracing` | `0.1.44` |
| `tracing-subscriber` | `0.3.23`, subject to #3514 stress/release recheck |
| `tracing-opentelemetry` | `0.33.x` |
| `opentelemetry` | `0.32.x` |
| `opentelemetry_sdk` | `0.32.1` |
| `opentelemetry-otlp` | `0.32.x` |

Do not independently upgrade the three OTel crates to `0.33.0`, despite their September 18, 2026 release, until the tracing bridge’s manifest supports that line. ([docs.rs](https://docs.rs/crate/opentelemetry/latest))

### Parameters

`owns logging-pipeline-contract = tracing event/span producers + one application-owned tracing-subscriber registry + stderr human/NDJSON profiles + shared key-redaction policy applied at every egress + control-character escaping + flag/env/config/verbosity level precedence + reloadable console filter + optional web-scoped tracing-opentelemetry/OpenTelemetry export`

`assumes R69:web-extra-surface = unresolved; false means the core tracing stack only, true means the web profile and web-otel feature are compiled and tested`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions; rust-version = 1.96 as of 2026-09-18; raised only in a template minor release and tested in CI`

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

No `CONFLICT:` is required.

### Migration implications

Proposed file-level changes:

- **`Cargo.toml`**
  - add `tracing` and `tracing-subscriber`;
  - add `web-otel` optional feature;
  - add compatible OTel 0.32 dependencies under that feature;
  - declare `rust-version = "1.96"`;
  - retain a committed lockfile for binaries/examples.

- **`src/diagnostics/mod.rs`**
  - `DiagnosticsProfile`;
  - `ResolvedDiagnostics`;
  - side-effect-free `build_diagnostics`;
  - opaque `DiagnosticsGuard`;
  - shared schema constants.

- **`src/diagnostics/redact.rs`**
  - sensitive-key predicate;
  - `[REDACTED]` mask;
  - field visitor;
  - control-character escaping;
  - tests for mixed case, dotted names and false positives.

- **`src/diagnostics/format.rs`**
  - `FormatFields` implementation;
  - `FormatEvent` implementation;
  - human and NDJSON styles;
  - trace/span correlation;
  - UTC timestamp and stable schema.

- **`src/diagnostics/install.rs`**
  - executable-only ownership state;
  - fallible global installation;
  - idempotent same-config result;
  - console-level reload;
  - `HostOwned` and `RestartRequired` outcomes.

- **`src/diagnostics/otel.rs`**, behind `web-otel`
  - provider/exporter construction;
  - `RedactingSpanExporter`;
  - resource fields;
  - explicit flush/shutdown.

- **Library modules**
  - replace hand-rolled lines with structured `tracing` events;
  - add spans around units of work;
  - no call to initialization functions;
  - mark secret-bearing arguments `skip`/`skip_all`.

- **CLI context/options**
  - parse exact `--log-level` and environment value;
  - pass the already-resolved verbosity-ladder fallback;
  - initialize once before command execution;
  - preserve stdout for command data.

- **Web entry point**, only if R69 enables it
  - select web profile;
  - install once after runtime/config construction;
  - add request span middleware;
  - extract/inject W3C context as specified by R78;
  - flush provider on shutdown.

- **`examples/web-otel.rs` or equivalent**
  - collector-backed working example;
  - one incoming request and one nested operation;
  - correlated console event;
  - no secrets in console or exported data.

- **Tests**
  - `tests/diagnostics_format.rs`;
  - `tests/diagnostics_redaction.rs`;
  - `tests/diagnostics_levels.rs`;
  - `tests/diagnostics_host_ownership.rs`;
  - `tests/diagnostics_otel.rs`;
  - subprocess tests for global initialization.

- **Documentation**
  - field naming policy;
  - sensitive-data policy;
  - exact precedence table;
  - CLI versus web defaults;
  - immutable-after-init settings;
  - OTel feature and shutdown behavior.

Primary migration risks:

1. Python-style complete reconfiguration is not available after global installation.
2. A formatting-layer sanitizer does not sanitize OTel or a future R59 layer.
3. `#[instrument]` can capture secrets automatically.
4. The OTel crates must be upgraded as a compatibility bundle.
5. Custom human formatting must retain the upstream terminal-injection fix.
6. `tracing-subscriber 0.3.23` needs an explicit recheck against open issue #3514. ([github.com](https://github.com/tokio-rs/tracing/issues/3514))

### Validation strategy

**Execution status:** all commands below are **planned**. They were not run against `rs-launch-blueprint` during this research.

#### 0. Complete the required quantitative evidence

```bash
set -euo pipefail

crates=(
  tracing
  tracing-subscriber
  tracing-opentelemetry
  opentelemetry
  opentelemetry_sdk
  opentelemetry-otlp
)

for crate in "${crates[@]}"; do
  curl -fsS \
    -H 'User-Agent: rs-launch-blueprint-research/1.0' \
    "https://crates.io/api/v1/crates/${crate}" \
    | jq '{
        crate: .crate.id,
        recent_downloads: .crate.recent_downloads,
        downloads: .crate.downloads
      }'

  curl -fsS \
    -H 'User-Agent: rs-launch-blueprint-research/1.0' \
    "https://crates.io/api/v1/crates/${crate}/versions" \
    | jq '
        [.versions[] | select(.yanked == false)]
        | sort_by(.created_at)
        | last
        | {num, created_at}
      '
done
```

For each repository:

```bash
gh api repos/tokio-rs/tracing \
  --jq '{stargazers_count, archived, pushed_at}'

gh api search/issues \
  -f q='repo:tokio-rs/tracing is:issue is:open' \
  --jq '{total_count}'

gh api repos/tokio-rs/tracing-opentelemetry \
  --jq '{stargazers_count, archived, pushed_at}'

gh api repos/open-telemetry/opentelemetry-rust \
  --jq '{stargazers_count, archived, pushed_at}'
```

A small checked-in research script should fetch the ten newest issues per repository, inspect comments whose `author_association` is `MEMBER`, `OWNER` or `COLLABORATOR`, and report median days to first response plus unanswered count. Bots should be excluded.

**Expected:** exact figures replace every `UNAVAILABLE` field before the ledger is accepted.

#### 1. Toolchain, OS and feature boundary

```bash
rustup toolchain install 1.96.0
cargo +1.96.0 test --workspace --all-targets --no-default-features
cargo +1.96.0 test --workspace --all-targets --features web-otel

cargo +stable test --workspace --all-targets --no-default-features
cargo +stable test --workspace --all-targets --features web-otel

cargo tree --no-default-features | grep -E 'opentelemetry|tracing-opentelemetry' && exit 1 || true
cargo tree --features web-otel
```

Run all four test commands on `ubuntu-latest` and `macos-latest`.

**Expected:** OTel crates are absent without `web-otel`; every configuration builds on Rust 1.96 and current stable.

#### 2. Format and schema

```bash
cargo test --test diagnostics_format
cargo test --test diagnostics_schema
```

Tests inject:

- `terminal = true`, profile CLI, format auto → human;
- `terminal = false`, profile CLI, format auto → NDJSON;
- profile web, no explicit format → NDJSON;
- explicit human/JSON → explicit format always wins.

Each JSON line is parsed with `serde_json`; assertions inspect values, not object order.

#### 3. Redaction and injection safety

```bash
cargo test --test diagnostics_redaction
```

Emit:

```rust
tracing::info!(
    user = "alice",
    password = "hunter2",
    api_token = "abc",
    "Authorization" = "Bearer xyz",
    "db.password" = "db-secret",
    control = "\u{1b}]0;owned\u{7}\r\nforged",
    "login attempted"
);
```

**Expected:**

- `user == "alice"`;
- every sensitive value equals `[REDACTED]`;
- no raw secret occurs anywhere in captured human output, JSON or OTel data;
- no raw ESC byte;
- one physical NDJSON record;
- ordinary fields retain their type where possible.

Also test a secret wrapper and `#[instrument(skip(secret))]`. Document that deliberately interpolating a secret into `message` is a programmer-policy violation not recoverable by key matching.

#### 4. Level precedence

```bash
cargo test --test diagnostics_levels
```

Use a table covering every combination of:

- command flag;
- environment;
- config file;
- supplied ladder result.

**Expected:** flag > environment > config > ladder. Test all six levels and invalid input diagnostics.

#### 5. Host ownership and idempotence

```bash
cargo test --test diagnostics_host_ownership -- --test-threads=1
```

Use subprocesses for each global case:

1. no existing subscriber → `Installed`;
2. second identical call → `AlreadyInstalled`, no duplicate event;
3. second call with changed level → `Reloaded`;
4. second call with changed format → `RestartRequired`;
5. host subscriber first → `HostOwned`, host still receives the event;
6. library call under scoped dispatch → event captured, no global mutation.

#### 6. OpenTelemetry correlation and redaction

```bash
cargo test --features web-otel --test diagnostics_otel
```

Use a local capturing exporter wrapped by `RedactingSpanExporter`.

**Expected:**

- console `trace_id` equals exported span trace ID;
- console `span_id` equals the active exported span ID;
- extracted remote parent ID is retained;
- invalid parent starts a fresh trace;
- sensitive span, event and link attributes are masked;
- no IDs appear outside a valid context;
- changing console level does not change OTel span sampling.

#### 7. Collector-backed web example

```bash
docker compose -f examples/otel/docker-compose.yml up -d
cargo run --features web-otel --bin rs-launch-blueprint-web
```

Then:

```bash
curl \
  -H 'traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01' \
  -H 'authorization: Bearer do-not-export' \
  'http://127.0.0.1:8080/example?token=do-not-log'
```

**Expected:**

- one server span with the supplied remote parent;
- nested application span;
- correlated JSON event;
- route template, not raw query;
- no authorization value, query token or test secret in application or collector output;
- provider flushes during graceful shutdown.

#### 8. Security, licenses and unsafe inventory

```bash
cargo audit
cargo deny check advisories licenses bans sources
cargo geiger --all-features
```

**Expected:** no advisory affects the lockfile; all licenses comply; the unsafe inventory is reviewed rather than assumed empty.

#### 9. Performance, compile time and size

```bash
cargo bench --bench diagnostics
cargo build --release --no-default-features
cargo bloat --release --crates

cargo build --release --features web-otel
cargo bloat --release --features web-otel --crates

CARGO_PROFILE_RELEASE_DEBUG=0 cargo build --release --timings
```

Benchmark the exact workload specified under `### Principles and implementation`.

No fixed “must beat crate X” threshold is recommended. Acceptance should instead set regression budgets after the first run, for example:

- disabled event cost;
- enabled human and JSON p95;
- redaction overhead versus identical non-sensitive fields;
- no dropped spans below the configured queue capacity;
- documented binary-size and clean-build delta for `web-otel`.

### Confidence & re-verify trigger

**Architecture confidence: high.** `tracing` plus a layered application-owned subscriber is the strongest fit for structured CLI diagnostics, library host ownership and tower/OpenTelemetry web integration.

**Exact-version confidence: medium.** Three facts require revalidation immediately before implementation:

1. OpenTelemetry `0.33.0` was released on **September 18, 2026**, while the current tracing bridge still declares OTel `0.32`.
2. `tracing-subscriber 0.3.23` has a reported cross-platform span-cloning panic with an unreleased proposed fix.
3. Required crates.io/GitHub quantitative figures and issue-response medians could not be retrieved in this environment.

Re-run research when:

- `tracing-opentelemetry` releases support for OTel 0.33 or later;
- a `tracing-subscriber` release resolves #3514/#3567;
- `tracing 0.2` stabilizes;
- Rust stable advances and the owner MSRV moves from 1.96;
- a RustSec advisory affects any resolved dependency;
- R69/R78 select a concrete web runtime or OTLP transport;
- `tracing-subscriber` gains first-class OTel ID injection;
- R59 introduces a file formatter that cannot reuse the sanitizer;
- the sensitive-key policy or event schema changes.

### Sources

All retrieved 2026-09-18.

**Owner-provided evidence**

- `docs/port/COMMONALITY.md`: F250–F254, F262–F263, F274
- `docs/port/PARAMETERS.md`
- `docs/port/OWNER-REVIEW.md`
- `docs/port/BASELINE-REVIEW.md`: F304
- `ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`: D-018

**Rust and library ownership**

- `https://blog.rust-lang.org/releases/`
- `https://doc.rust-lang.org/stable/std/io/trait.IsTerminal.html`
- `https://github.com/rust-lang/log`
- `https://docs.rs/log/latest/log/`
- `https://github.com/rust-cli/env_logger`
- `https://blog.rust-lang.org/2025/02/13/2024-State-Of-Rust-Survey-results/`

**Tracing architecture**

- `https://docs.rs/crate/tracing/0.1.44`
- `https://docs.rs/crate/tracing-subscriber/0.3.23`
- `https://docs.rs/tracing-subscriber/0.3.23/tracing_subscriber/layer/`
- `https://docs.rs/tracing-subscriber/0.3.23/tracing_subscriber/reload/`
- `https://docs.rs/tracing/0.1.44/tracing/field/trait.Visit.html`
- `https://github.com/tokio-rs/tracing`
- `https://github.com/tokio-rs/tracing/issues/1531`
- `https://github.com/tokio-rs/tracing/issues/3514`
- `https://rustsec.org/packages/tracing.html`
- `https://rustsec.org/packages/tracing-subscriber.html`

**OpenTelemetry**

- `https://docs.rs/crate/tracing-opentelemetry/0.33.0`
- `https://github.com/tokio-rs/tracing-opentelemetry`
- `https://docs.rs/crate/opentelemetry/0.32.0`
- `https://docs.rs/crate/opentelemetry_sdk/0.32.1`
- `https://docs.rs/crate/opentelemetry-otlp/0.32.0`
- `https://github.com/open-telemetry/opentelemetry-rust`
- `https://github.com/open-telemetry/opentelemetry-rust/issues/3542`
- `https://opentelemetry.io/docs/specs/otel/logs/`
- `https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/processor/redactionprocessor/README.md`

**Security and alternatives**

- `https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html`
- `https://docs.rs/crate/slog/latest`
- `https://docs.rs/crate/emit/latest`
- `https://docs.rs/crate/logforth/latest`
- `https://docs.rs/crate/redactkit/latest`
- `https://docs.rs/redactable/latest/redactable/tracing/`
- `https://docs.rs/tracing-microjson/latest/tracing_microjson/`

**Adopters and maintained examples**

- `https://github.com/rust-lang/cargo/blob/master/Cargo.toml`
- `https://github.com/libp2p/rust-libp2p/blob/master/Cargo.toml`
- `https://github.com/tower-rs/tower-http/blob/main/tower-http/src/trace/mod.rs`
- `https://github.com/facebook/buck2/blob/main/shim/third-party/rust/Cargo.toml`
- `https://docs.aws.amazon.com/sdk-for-rust/latest/dg/`

**Mandated quantitative endpoints to rerun**

```text
GET https://crates.io/api/v1/crates/<name>
GET https://crates.io/api/v1/crates/<name>/versions
GET https://api.github.com/repos/<owner>/<repo>
GET https://api.github.com/search/issues?q=repo:<owner>/<repo>+is:issue+is:open
https://rustsec.org/packages/<name>.html
```

## Sources

- [https://doc.rust-lang.org/stable/std/io/trait.IsTerminal.html](https://doc.rust-lang.org/stable/std/io/trait.IsTerminal.html)
- [https://docs.rs/crate/tracing/latest](https://docs.rs/crate/tracing/latest)
- [https://docs.rs/crate/emit/latest](https://docs.rs/crate/emit/latest)
- [https://blog.rust-lang.org/releases/](https://blog.rust-lang.org/releases/)
- [https://docs.rs/crate/tracing-opentelemetry/latest](https://docs.rs/crate/tracing-opentelemetry/latest)
- [https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html)
- [https://blog.rust-lang.org/2025/02/13/2024-State-Of-Rust-Survey-results/](https://blog.rust-lang.org/2025/02/13/2024-State-Of-Rust-Survey-results/)
- [https://rustprojectprimer.com/ecosystem/logging.html](https://rustprojectprimer.com/ecosystem/logging.html)
- [https://github.com/rust-lang/cargo/blob/master/Cargo.toml](https://github.com/rust-lang/cargo/blob/master/Cargo.toml)
- [https://github.com/libp2p/rust-libp2p/blob/master/Cargo.toml](https://github.com/libp2p/rust-libp2p/blob/master/Cargo.toml)
- [https://docs.aws.amazon.com/sdk-for-rust/latest/dg/aws-sdk-rust-developer-guide.pdf](https://docs.aws.amazon.com/sdk-for-rust/latest/dg/aws-sdk-rust-developer-guide.pdf)
- [https://github.com/facebook/buck2/blob/main/shim/third-party/rust/Cargo.toml](https://github.com/facebook/buck2/blob/main/shim/third-party/rust/Cargo.toml)
- [https://github.com/tokio-rs/tracing/blob/main/tracing-subscriber/Cargo.toml](https://github.com/tokio-rs/tracing/blob/main/tracing-subscriber/Cargo.toml)
- [https://github.com/rust-lang/log](https://github.com/rust-lang/log)
- [https://docs.rs/crate/slog/latest](https://docs.rs/crate/slog/latest)
- [https://docs.rs/crate/logforth/latest](https://docs.rs/crate/logforth/latest)
- [https://docs.rs/crate/redactkit/latest](https://docs.rs/crate/redactkit/latest)
- [https://docs.rs/tracing-subscriber/latest/tracing_subscriber/layer/](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/layer/)
- [https://docs.rs/tracing/0.1.44/tracing/field/trait.Visit.html](https://docs.rs/tracing/0.1.44/tracing/field/trait.Visit.html)
- [https://deps.rs/crate/tracing-opentelemetry/latest](https://deps.rs/crate/tracing-opentelemetry/latest)
- [https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/processor/redactionprocessor/README.md](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/processor/redactionprocessor/README.md)
- [https://docs.rs/tracing-opentelemetry/latest/tracing_opentelemetry/fn.layer.html](https://docs.rs/tracing-opentelemetry/latest/tracing_opentelemetry/fn.layer.html)
- [https://github.com/tokio-rs/tracing/issues/1531](https://github.com/tokio-rs/tracing/issues/1531)
- [https://docs.rs/tracing-subscriber/latest/tracing_subscriber/reload/](https://docs.rs/tracing-subscriber/latest/tracing_subscriber/reload/)
- [https://github.com/open-telemetry/opentelemetry-rust/issues/3542](https://github.com/open-telemetry/opentelemetry-rust/issues/3542)
- [https://docs.rs/crate/log/latest](https://docs.rs/crate/log/latest)
- [https://github.com/tokio-rs/tracing/blob/main/tracing/Cargo.toml](https://github.com/tokio-rs/tracing/blob/main/tracing/Cargo.toml)
- [https://docs.rs/crate/tracing-subscriber/latest](https://docs.rs/crate/tracing-subscriber/latest)
- [https://docs.rs/crate/env_logger/latest](https://docs.rs/crate/env_logger/latest)
- [https://github.com/tokio-rs/tracing/issues/3514](https://github.com/tokio-rs/tracing/issues/3514)
- [https://docs.rs/crate/tracing-opentelemetry/0.32.1/source/CHANGELOG.md](https://docs.rs/crate/tracing-opentelemetry/0.32.1/source/CHANGELOG.md)
- [https://docs.rs/crate/opentelemetry/latest](https://docs.rs/crate/opentelemetry/latest)
- [https://github.com/open-telemetry/opentelemetry-rust/blob/main/opentelemetry/Cargo.toml](https://github.com/open-telemetry/opentelemetry-rust/blob/main/opentelemetry/Cargo.toml)
- [https://docs.rs/crate/opentelemetry_sdk/latest](https://docs.rs/crate/opentelemetry_sdk/latest)
- [https://docs.rs/crate/opentelemetry-otlp/latest](https://docs.rs/crate/opentelemetry-otlp/latest)
- [https://github.com/gakonst/nanocodex/blob/master/Cargo.toml](https://github.com/gakonst/nanocodex/blob/master/Cargo.toml)
