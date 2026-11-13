# 2026-09-27 — R78 — opentelemetry-integration (crate, Deep) — decision (revision 1)

**Revision note, revision 1.** This is the first synthesis of R78. No earlier revision exists,
no audit has reviewed any revision, and nothing has been published for R78, so there is no
`## Supersedes`. It adjudicates four raw reports — `raw/muse.md`, `raw/opus.md`,
`raw/doxa-openai.normalized.md` and `raw/doxa-gemini.normalized.md` — against three fresh
evidence scripts under `review/evidence/`. **It is a conditional decision: its one consumed
parameter, R58's `logging-pipeline-contract`, has no published value**, so the decision states
the exact assumptions it makes about R58 and cannot be accepted until R58 publishes (see
`## Parameters`).

**Bindings.** This synthesis read the run's `inputs/prompt.md` (sha256
`e3ef88cf9e274e336008ba1d20f8661e6a7395331aacdcac144c50b35a824509`, the hash `manifest.json`
records). The canonical prompt
`research/topics/78-opentelemetry-integration/prompts/opentelemetry-integration.prompt.md`
now hashes to `38e5b4f3d25ea0d769fe6d715b9ba484d21ff041a0982806f4011753dfce306e`. A `diff` of
the two shows exactly two changed lines: the `- engines:` line (`codex, opus, doxa` in the
snapshot, `muse, opus, doxa` in the canonical file) and one added sentence in the tier
guidance naming the Muse substitution. No question, requirement, gate or scope line differs.
The controller decides whether that drift requires revalidation (RUNBOOK §3, "Changed prompt,
policy, parameter or prerequisite").

| Report | Engine and model (as recorded) | sha256 |
|---|---|---|
| `raw/muse.md` | Muse (Meta); **no model ID recorded** in the report or in `operations/` | `c3a61ef9f8f298866c879dd727cac2c06b0278c888966b8991166211005a726d` |
| `raw/opus.md` | Claude Opus seat, `claude-opus-5-5` (`raw/opus.md:3`) | `7b2fbae3b17db23a6a35a5f8d679962451b8671651a9e47c469958b71c276b75` |
| `raw/doxa-openai.normalized.md` (original `raw/doxa-openai.md`, `20d249ba…`) | Doxa 3.3.0 → OpenAI `gpt-5.6-sol`, operation `research-20260926-154216-13b4474cda404105` (`operations/doxa.json`) | `4817dac1862ce8c7c1875f6aabbb18222d2aa7e6b0e87ae68df8e4b3b4fbee4d` |
| `raw/doxa-gemini.normalized.md` (original `raw/doxa-gemini.md`, `ee0dee7a…`) | Doxa 3.3.0 → Gemini `deep-research-preview-04-2026`, operation `research-20260926-154326-1247324c19ce49c6` | `560515a381565eee03ee5fc38d92fe49608d06f74a3682d775c02d62a37032c1` |

`operations/doxa.json` records the Doxa leg as two single-provider operations with **no
Perplexity provider by design** ("one single-provider op per leg, no perplexity"), and records
a transient poll-side 403 on the Gemini job that did not cause a resubmission.

Actor `synth-opus-2026-09-26T190312Z-8cf4b61ddead-r1`, model `claude-opus-5-5` (Anthropic),
item kind `crate`, effort tier `deep`. This context produced none of the four reports and none
of their evidence. **It is the same model as the Opus leg's seat**, so the synthesis is
independent work but not a second model family on the Opus leg's claims; the RUNBOOK §2 table
names a fresh Claude Fable context as the default synthesizer, and this run used the Opus seat
by the controller's instruction.

**Dates.** Every endpoint call in `review/evidence/` ran between 04:02 and 04:28 UTC on
**2026-09-27** (US Pacific 2026-09-26). This decision uses the UTC date throughout, and that is
the date to re-verify against. Carried claims keep their report's date: all four reports were
written 2026-09-26 (Pacific).

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)`** for every
candidate. The ruling is carried from `raw/opus.md:17-20`, which cites
`docs/port/OWNER-REVIEW.md`, section "2026-09-12 — no licence check for anything the template
uses (Q4, superseded and widened by Q7.B)"; the published R53 decision records the same ruling
(`research/topics/53-config-schema-validation/DECISION.md:45`). This synthesis did not re-read
`OWNER-REVIEW.md`, which is outside its permitted reads. Licence strings below are metadata.
Muse, Doxa-OpenAI and Doxa-Gemini applied gate 1 as a live gate; no candidate passed or failed
on it in any report, so no disposition changes.

**Context flags found by this synthesis.** The dispatch reported none; five exist.

1. **R58 has no decision.** `inputs/prerequisites.json` records R58 `decision: missing`,
   `acceptance: missing`, and `inputs/parameters.json` records `logging-pipeline-contract`
   with value `—`. Every report noticed and assumed a `tracing_subscriber::Registry`.
2. **Prompt snapshot drift**, described under Bindings.
3. **`inputs/EXECUTION.json` still lists `codex, opus, doxa`** for R78, although the Q17.A
   substitution (RUNBOOK §2, "Q17.A (2026-09-27) extends the substitution to … R78") ran Muse.
   The snapshot predates the policy change.
4. **`manifest.json` is stale**: `state: ready`, `operations: {}`, and a `required_engines`
   list of `codex, opus, doxa`, although four reports and two Doxa operation records exist.
   Updating it is the controller's work; this synthesis ran no runner command.
5. **The Muse leg has no recorded model identity.** Acceptance requires the actual resolved
   model (RUNBOOK §2); the controller must supply it or record the gap.

## Decision

**This decision is a proposal validated in the implementation phase** (owner ruling
2026-09-10, as recorded in `research/topics/53-config-schema-validation/DECISION.md:54-57`).
`rs-launch-blueprint` has no Rust source yet. The one piece of Rust this synthesis compiled
and ran is a throwaway probe under `$TMPDIR`, deleted after each run (`## Empirical check`).
No Rust file was written into the repository.

### The recommended crate set

**Named crate: `tracing-opentelemetry`, version range `>= 0.34.0, < 0.35.0`.** It is the
`tracing`-to-OpenTelemetry bridge layer, maintained in the `tokio-rs` organization. It needs
the OpenTelemetry Rust SIG's **0.33 generation** alongside it. All five crates are optional and
are enabled only by the `otel` feature, which R69's registered value already names as
`otel = ["web", ...]` (`research/topics/69-web-framework-stack/DECISION.md:1586`):

```toml
[features]
otel = [
    "web",
    "dep:opentelemetry",
    "dep:opentelemetry_sdk",
    "dep:opentelemetry-otlp",
    "dep:opentelemetry-http",
    "dep:tracing-opentelemetry",
]

[dependencies]
opentelemetry         = { version = ">= 0.33.0, < 0.34.0", optional = true, default-features = false, features = ["trace"] }
opentelemetry_sdk     = { version = ">= 0.33.0, < 0.34.0", optional = true, default-features = false, features = ["trace"] }
opentelemetry-otlp    = { version = ">= 0.33.0, < 0.34.0", optional = true, default-features = false,
                          features = ["trace", "http-proto", "reqwest-blocking-client", "internal-logs"] }
opentelemetry-http    = { version = ">= 0.33.0, < 0.34.0", optional = true, default-features = false }
tracing-opentelemetry = { version = ">= 0.34.0, < 0.35.0", optional = true, default-features = false }
```

This exact block compiled on local stable 1.98.1 and under **Rust 1.96.0**, the current
`msrv-policy` floor, and it resolved to `opentelemetry v0.33.0` and
`tracing-opentelemetry v0.34.0` with a single `opentelemetry` version in the tree
(`r78-probe.log` checks `B02`, `M01`, `T02`, `T03`, `T04`).

**Why the five move as one unit.** `tracing-opentelemetry` 0.34.0 declares
`opentelemetry ^0.33.0`, and 0.33.0 declared `^0.32.0` (`r78-figures.log` `V01`, `V02`). Two
`opentelemetry` minor versions in one tree compile as two unrelated sets of types, so a
context built by one cannot parent a span in the other. A bump of any one crate is therefore a
bump of all five, verified by `cargo tree -d` showing no duplicate `opentelemetry`.

**Why each feature choice.**

- **`default-features = false` everywhere.** `opentelemetry-otlp` 0.33.0's defaults are
  `http-proto`, `reqwest-blocking-client`, `trace`, `metrics`, `logs` and `internal-logs`
  (`r78-figures.log` `F01`, §3). The explicit list keeps four of them and drops `logs`, which is
  outside this tracing-only item (R58 decides log export), and `metrics`, which is R79's; the
  API and SDK defaults likewise add `metrics` and `logs`. `tracing-opentelemetry`'s defaults are `metrics` and `tracing-log`
  (`F04`): the `MetricsLayer` is R79's call, and `tracing-log` bridges `log`-crate records,
  which is R58's pipeline concern.
- **Metrics code is compiled in anyway.** `opentelemetry-otlp`'s `http-proto` feature is
  defined as `[prost, opentelemetry-http, opentelemetry-proto/gen-tonic-messages, http,
  httpdate, trace, metrics]` (`F03`), so the `otel` build activates
  `opentelemetry_sdk/metrics` despite `default-features = false` (`r78-probe.log` `T05`). The
  code is inert unless a `MeterProvider` is built. R79 inherits that at zero marginal
  dependency cost if it chooses OpenTelemetry metrics.
- **`internal-logs` is kept.** It is what makes a collector outage visible: with the collector
  unreachable, the SDK emitted `WARN opentelemetry-otlp: name="Export.Failed.Exhausted" …
  retries=3` and `ERROR opentelemetry_sdk: name="BatchSpanProcessor.ExportError"` through the
  ordinary `tracing` pipeline (`r78-probe.log` §9, `D14`).
- **No TLS feature.** `opentelemetry-otlp` declares its `reqwest` dependency with
  `default-features = false` (`r78-source-census.log` `S20`), so an `https://` collector needs
  the additive `opentelemetry-otlp/reqwest-rustls` feature. This decision leaves it off: the
  template's demonstrated topology is a collector on the local or cluster network over plain
  OTLP/HTTP, and rustls adds a TLS stack no acceptance criterion needs. **This is a proposal,
  not a measurement**, and P03 must confirm it (see *What P03 must validate*).
- **OTLP over HTTP/protobuf with the blocking `reqwest` client**, which is the crate's own
  default transport (`F01`, `F02`). The batch processor exports on an SDK-owned OS thread
  (`r78-source-census.log` `S07`) and the blocking client is constructed on a separately
  spawned thread (`S13`), so export has no Tokio coupling and initialization is safe inside
  R69's `#[tokio::main]`, which the probe did.

### The degrade contract — what replaces py's runtime soft-import

Cargo feature absence removes the code at compile time, but three runtime failure modes remain
once `otel` is compiled in. The measured behavior settles which guards the template needs.

| State | Required behavior | Mechanism | Evidence |
|---|---|---|---|
| `otel` not compiled | Serves; no OpenTelemetry crate in the tree or the binary. If `OTEL_EXPORTER_OTLP_ENDPOINT` is set, one warning that it is ignored. | `#[cfg(not(feature = "otel"))]` path | `T01`, `T06`, `W01`–`W03` |
| `otel` compiled, runtime flag unset | Serves; **no export attempted, no warning**; the collector receives nothing even with an endpoint configured | Gate 2: an explicit enable flag, default `false` | `D01`–`D04` |
| Flag set, no `OTEL_EXPORTER_OTLP_*` variable | **Exports to `http://localhost:4318`** — measured, not inferred | the exporter's compiled-in default (`S01`, `exporter/mod.rs:55`) | `D05`: 12 spans received on 127.0.0.1:4318 |
| `OTEL_SDK_DISABLED=true` | Serves; exports nothing | Gate 2: the template reads the variable, because **no crate in the set does** | `S03`; `D06` (SDK alone still exported 9 spans), `D07` (guarded: 0) |
| Invalid endpoint variable | Serves; **one** `otel_unavailable` warning carrying the build error; no OTel layer installed | Gate 3: `SpanExporter::builder().with_http().build()` returns `Err` in 0.33 (`S02`); the error is a value, logged after the subscriber exists | `D08`, `D09` |
| Collector unreachable after start | Serves at unchanged latency; spans are dropped in bounded memory; each failed batch logs one WARN and one ERROR line | SDK: bounded queue of 2,048 spans (`S08`), OS-thread export (`S07`), default retries 3 with backoff (`S04`) | `D10`–`D14`: 100/100 × 200 in 1,729 ms vs 1,705 ms flag-off |
| Graceful shutdown | Buffered spans are flushed; shutdown is bounded; **the exit code is unchanged** (143 after SIGTERM, 130 after SIGINT) | `SdkTracerProvider::shutdown_with_timeout(budget)` inside `tokio::task::spawn_blocking` after `with_graceful_shutdown` returns (`S12`; `S11` documents the deadlock risk of blocking shutdown on a runtime thread) | `E02`, `E13`, `D12`, `D13` |

Two facts in this table decide disagreements between the reports (`## Engines`,
Disagreements 3 and 4). First, **an `otel` build with no endpoint does not stay quiet: it
exports to localhost**. A compile-time gate alone therefore cannot express "compiled in but
not wanted", which is why gate 2 exists. Second, **`shutdown_with_timeout` returned `Ok`
after 442 ms even though the final batch was lost to the dead collector** (`r78-probe.log`
§9). The return value does not report data loss; the `internal-logs` lines do. The template
must not treat `Ok` from shutdown as "all spans delivered".

**The enable flag's name and type are R77's** (`web-env-settings`). This decision requires only
that one boolean exists, defaults to `false`, and is read before the subscriber is assembled.
Endpoint, headers and protocol stay on the standard `OTEL_EXPORTER_OTLP_*` variables and are
not duplicated as template settings. The shutdown budget must not exceed R69's drain deadline.

### Instrumentation points (the `src/web/telemetry.rs` module)

R69's owned value places "every later web layer … as modules inside that same gated
`src/web/` tree" (`DECISION.md:1586`), so the module is `src/web/telemetry.rs`, compiled with
`web`, with its OpenTelemetry half under `#[cfg(feature = "otel")]`. The probe implemented each
piece below; the names are illustrative.

1. **Subscriber composition — a pure addition.** `tracing-subscriber` 0.3.23 implements
   `impl<L, S> Layer<S> for Option<L>` (`S15`), so R58's
   `registry().with(...).with(fmt_layer)` chain takes one more `.with(otel_layer_option)`,
   `None` whenever a gate is closed, and the subscriber type is identical in every
   configuration. The probe composed exactly that (`r78-probe.log` §4).
2. **A per-layer filter on the OpenTelemetry layer.** `Targets` turning off `hyper`,
   `hyper_util`, `h2`, `reqwest` and the `opentelemetry*` targets keeps the exporter's own HTTP
   client from generating exported spans. With it, only the application's spans were exported
   (`E10`). This is the one coupling R58 must accept; it does not alter R58's global filter.
3. **Propagator installation.** The global text-map propagator defaults to
   `NoopTextMapPropagator` (`S14`), so `global::set_text_map_propagator(TraceContextPropagator::new())`
   is mandatory; without it an incoming `traceparent` is ignored.
4. **Server span with remote parent.** A request middleware creates the server span from the
   matched route (axum's `MatchedPath`, a default feature R69 kept for R78 and R79,
   `DECISION.md:2349`), calls `OpenTelemetrySpanExt::set_parent` with the context extracted
   through `opentelemetry_http::HeaderExtractor` **before** the span is entered, and
   instruments the request future with it. `set_parent` returns
   `Result<(), SetParentError>` in 0.34.0 (`S16`). The span itself exists in every build; only
   the `set_parent` call is feature-gated. If R75 selects a request-span middleware, that call
   moves into R75's span constructor and no second server span is created.
5. **Outbound injection.** The outbound call runs inside a `otel.kind = "client"` span, and
   `opentelemetry_http::HeaderInjector` writes the current span's context into the request's
   `http::HeaderMap` (`S17`). The probe's `/downstream` server span came out as a child of that
   client span (`E08`), which proves injection and re-extraction.
6. **Log correlation.** Inside a request, the current span's OpenTelemetry context yields the
   trace ID; the probe logged it as a `trace_id` field on an ordinary event and the line
   carried the incoming trace ID (`E12`). How R58's formatter surfaces it — a field on the
   request span, or OTel log export through `opentelemetry-appender-tracing` — is R58's
   choice. **This decision adds no log-export crate.**
7. **Shutdown.** The guard holds the `SdkTracerProvider`; the serve binary calls
   `shutdown_with_timeout` in `spawn_blocking` after the server drains, logs a warning on
   `Err`, and returns R69's exit code unchanged. `shutdown_with_timeout` flushes: with a
   60-second batch delay, the collector held 0 spans before SIGTERM and all 4 afterwards
   (`E02`, `E04`), so no separate `force_flush` call is needed.

### Ledger rows and baseline findings

**F325** (`docs/port/COMMONALITY.md`, verdict `DIVERGENT`, "OpenTelemetry tracing is opt-in and
soft-imported"; row identity from `inputs/prompt.md:8` and `raw/opus.md:101-102`) is settled by
this decision: the Rust realization is a compile-time `otel` feature **plus** a runtime enable
flag **plus** an exporter-build degrade, with the SDK's own bounded export and a bounded
shutdown behind them. **F304** is R58's row after the 2026-09-04 baseline review
(`inputs/prompt.md:14`); this item defines what lives inside that boundary and does not
re-decide it.

`BASELINE-REVIEW: F325` is raised by two reports (Opus, Doxa-OpenAI) with the same direction;
both lines are carried verbatim with their disposition under `## Engines`. **The ledger is not
edited here.**

### What this decision does not decide

- **The subscriber pipeline, the log format and log export** — R58.
- **The request-span middleware as a product choice, and `tower-http`** — R75 (R69's decision
  leaves `tower-http` to R75, `DECISION.md:694`). One coupling is recorded for R75: the `otel`
  tree already contains `tower-http` 0.6.11, because `reqwest` 0.13.5 depends on
  `tower-http ^0.6.8` non-optionally and `reqwest` enters through the exporter's blocking
  client (`r78-figures.log` `V07`, `r78-probe.log` §2). If R75 selects `tower-http` 0.7.x, the
  `otel` build will carry two `tower-http` versions; R75 should weigh that.
- **The enable flag's name** — R77.
- **Metrics** — R79. The "useful metrics" leg of RUNBOOK §5's required OpenTelemetry example
  (`research/RUNBOOK.md:208-212`) is R79's contribution; this item's probe does not exercise
  metrics and does not claim that leg.
- **The outbound HTTP client.** R01's registered `http-transport-injection-seam` puts outbound
  I/O behind a production adapter; the injection helper wraps whichever client that adapter
  uses, provided its header map is `http` 1.x (the probe used `reqwest` 0.13.5 because it is
  already in the `otel` tree).
- **TLS to the collector** — left off; see the feature notes above.

### Principles and implementation

**The shared requirement, its source and its agreement level.** The owner direction of
2026-09-04 requires every web example to demonstrate OpenTelemetry with the idiomatic libraries
of its language (`inputs/prompt.md:11`, `:37`); the 2026-09-04 baseline review adds that the
required web example must not become optional (`:14`). All four reports agree on the level:
**capability and standard** — observable behavior plus the wire standards (OTLP, W3C Trace
Context) must agree across py, ts and rs; the optionality mechanism must not.

| What must agree | Observable criterion | Rust realization |
|---|---|---|
| Tracing is opt-in, off by default | Compiled in but not enabled: nothing exported, no warning | Runtime flag default `false` (`D01`–`D03`) |
| Absence or failure never breaks serving | Feature off, flag off, invalid endpoint, dead collector: every request 200, one visible diagnostic | `D08`–`D11`, `W01` |
| Vendor-neutral export, standard configuration | OTLP; endpoint from `OTEL_EXPORTER_OTLP_*` | OTLP/HTTP protobuf (`F01`), env-configured (`E01`–`E04` via `OTEL_EXPORTER_OTLP_ENDPOINT`) |
| W3C context in and out | Incoming parent becomes the server span's parent; outbound request carries the same trace | `E05`, `E07`, `E08` |
| Service identity | `service.name` on every span | `E09` (`probe-web`; the template's value is `<app>-web`, per py's `"<APP_NAME>-web"`, `raw/opus.md:119`) |
| Flush on graceful shutdown, bounded | Spans present after SIGTERM; bounded with the collector down | `E02`, `E13`, `D13` |
| Logs correlate with traces | A request's log line carries its trace ID | `E12` |

**What may vary, and why each difference is justified.** py detects a missing module at run
time (`src/py_launch_blueprint/web/telemetry.py:71`, `inputs/prompt.md:8`) and has a second,
runtime settings gate (`otel_enabled`, carried from `raw/opus.md:124-125`; not re-read). Rust
removes the code at compile time — Cargo features are the native optionality mechanism and F304
fixes the layering — and keeps py's runtime gate as the enable flag. py's server span comes
from auto-instrumentation (`FastAPIInstrumentor`); Rust has no monkey-patching, so the span
comes from explicit middleware. ts has no web service (F303, `inputs/prompt.md:8`), so ts's
absence is missing capability, not drift; the follow-on ts project inherits this contract, and
Opus's leads for it (`raw/opus.md:893-897`) are unverified. **One low-level value agrees for
free**: py exports over OTLP/HTTP (`raw/opus.md:114-116`), which is also the Rust exporter's
default. No other shared low-level value is recommended.

**Architectural alternatives, compared before libraries.** All four reports reached the same
verdicts on A–C; D and E are Opus's additions.

| Alternative | Verdict and ground |
|---|---|
| **A. `tracing` spans → `tracing-opentelemetry` layer → SDK → OTLP** | **Chosen.** One span model shared by library, handlers, middleware and logs; a pure `Option<L>` addition to R58's registry (`S15`); the library and CLI stay OpenTelemetry-free. Executed end to end (`E01`–`E13`). |
| B. Direct OpenTelemetry API spans in application code | Rejected. Two span models; the library's `tracing` spans would be invisible to OTel unless the core crate took an OTel dependency, which the CLI/library fit forbids. Doxa-OpenAI ranks it first runner-up (`raw/doxa-openai.normalized.md:331-333`), for a version reason Disagreement 1 removes. |
| C. `fastrace` + `fastrace-opentelemetry` | Rejected: replaces the `tracing` model R58 is assumed to adopt; its newest adapter still requires `opentelemetry ^0.32.0` (`V05`) and declares `rust_version` 1.91.0; 4 reverse dependencies. |
| D. Collector-less (trace IDs in logs only) | Rejected by Opus (`raw/opus.md:211`): fails the owner's requirement that the example demonstrate export. |
| E. A plus prebuilt glue (`axum-tracing-opentelemetry`, `reqwest-tracing`, `init-tracing-opentelemetry`, `tracing-otel`) | Not adopted: every glue crate's newest release pins the 0.32 generation (`V04`, `V06`, and `init-tracing-opentelemetry` 0.41.1 / `tracing-otel` 0.33.2 at `^0.32` in `r78-figures.log` §2), and the init helpers assemble the whole subscriber, which is R58's. Becomes the ranked runner-up's substance (below). |

**Landscape: the three-bin map** (the census is the union of all four reports; figures fresh
from `r78-figures.log`).

| Bin | Candidates |
|---|---|
| Built-in or first-party | `tracing` + `tracing-subscriber` (Tokio; the substrate, not an exporter); the OpenTelemetry Rust SIG's `opentelemetry`, `opentelemetry_sdk`, `opentelemetry-otlp`, `opentelemetry-http`, `opentelemetry-appender-tracing`, `opentelemetry-stdout`, `opentelemetry-zipkin`; and `tracing-opentelemetry` in `tokio-rs` |
| Established industry standard (third-party glue on the standard stack) | `axum-tracing-opentelemetry` + `tracing-opentelemetry-instrumentation-sdk` + `init-tracing-opentelemetry` (davidB); `reqwest-tracing` (TrueLayer) |
| Up-and-comers and alternatives | `fastrace` + `fastrace-opentelemetry`; `tracing-otel`; `logfire` (vendor-packaged, carried from `raw/opus.md:564-567`) |
| Legacy | `opentelemetry-jaeger` (RUSTSEC-2025-0123, `R02`); `minitrace` (RUSTSEC-2024-0390, `R03`); `rustracing` (carried from `raw/opus.md:554`) |

**Authority, and why each source counts.** The published crate sources at the exact versions
(`r78-source-census.sh` extracts the crates.io tarballs) are the artifacts the template will
compile, and they outrank documentation, docs.rs pages and GitHub `main`. The crates.io API is
the registry of record for versions, dependency requirements and downloads. RustSec is the Rust
Secure Code working group's advisory database. The GitHub API is the named source for stars and
issue data. The SIG README's maturity table was read by Opus, Doxa-OpenAI and Doxa-Gemini
(traces **Beta**; logs and metrics **Stable**); this synthesis did not re-read it because
repository file contents are not a named endpoint, and records the three-report agreement as
the evidence. The 0.33.0 `CHANGELOG.md` inside the published `opentelemetry-otlp` tarball
confirms the pre-stable posture indirectly: 0.33.0 carries **Breaking** entries
(`r78-source-census.log` §1, §3).

**Practice evidence.** Opus read seven adopter manifests (`raw/opus.md:68-76`): hyperswitch,
neon, GreptimeDB, Spin, Materialize, Apollo Router and logfire-rust. Every one uses
architecture A, and their pins span 0.27 to 0.32; none is on 0.33 yet, eight days after its
release. Doxa-OpenAI adds `rust-lang/crates.io` on the official stack at 0.33.0 and `rustup`'s
optional OpenTelemetry feature (`raw/doxa-openai.normalized.md:30-31`). **These manifests are
carried, not re-read** (repository contents are not a named endpoint). The registry-side
adoption was re-measured: reverse dependencies `opentelemetry_sdk` 1,294,
`tracing-opentelemetry` 1,056, `opentelemetry-otlp` 1,003, `reqwest-tracing` 108,
`axum-tracing-opentelemetry` 18, `fastrace-opentelemetry` 4 (`r78-figures.log` §4).

**Maturity, dependability, compatibility.** The OpenTelemetry trace specification and OTLP are
stable; the Rust trace API, SDK and exporter are Beta (three reports agree) and 0.33.0 made
intentional breaking changes. The release cadence Opus measured — 0.29.0 2025-03-22, 0.30.0
2025-05-23, 0.31.0 2025-09-25, 0.32.0 2026-05-08, 0.33.0 2026-09-18 (`raw/opus.md:244-246`;
the 0.33.0 date re-confirmed by `C03`, the earlier dates carried) — implies one forced five-crate bump every four to eight months.
`tracing-opentelemetry` followed 0.33.0 in 5 days this cycle (2026-09-23, `C02`).

| Pair | Released | Requirement | Evidence |
|---|---|---|---|
| **OTel 0.33.0 ↔ `tracing-opentelemetry` 0.34.0** | 2026-09-18 / 2026-09-23 | `opentelemetry ^0.33.0`; `tracing-subscriber ^0.3.22`; `tracing ^0.1.35` | `C01`–`C03`, `V01`, `V03`; resolved and run in the probe |
| OTel 0.32.x ↔ `tracing-opentelemetry` 0.33.0 | 2026-05-08 / 2026-05-18 | `opentelemetry ^0.32.0` | `V02` |
| All five selected crates | — | `rust_version` 1.75.0, under the 1.96 floor | `C04-*`; the whole locked tree compiled under 1.96.0 (`M01`) |

**Representative cost.** No benchmark was run and none is claimed; no report ran one either.
What was measured is a smoke comparison, not a workload: on this host, 100 sequential
`GET /demo` requests (each with one internal span and one loopback outbound call) took 1,705 ms
with the flag off and 1,729 ms exporting into a closed port (`r78-probe.log` §9). Debug,
unstripped binary size was 12,592,488 bytes for `web` and 16,960,824 bytes for `web,otel`
(`r78-probe.log` §1); **that is not a release-profile size and is not a template figure**.
Qualitatively, the `otel` tree adds `prost`, `opentelemetry-proto`, blocking `reqwest` and the
SDK; `hyper` and `tokio` are already present through `axum`. Doxa-Gemini's "approximately 100KB
to 200KB" (`raw/doxa-gemini.normalized.md:102`) is unsourced and is not adopted. The
measurement P03 should run is Opus's stated workload (`raw/opus.md:418-422`) extended with
Doxa-OpenAI's configurations and fields (`raw/doxa-openai.normalized.md:636-668`): release
builds of `web`, `web,otel` flag off, `web,otel` exporting, and `web,otel` with a dead
collector; p50/p95/p99 latency, throughput, CPU, peak RSS, dropped-span count, build times and
stripped binary size, on identical hardware. The flag-off configuration must match `web` within
noise.

**Qualified shortlist.** Four candidates passed every applicable gate — fewer than five, which
is itself the finding: the field is one official stack, one bridge, and glue or alternatives on
top. Figures from `r78-figures.log` §1, §4 and §5 (endpoints in the script header), retrieved
2026-09-27 UTC.

| Name · role | 90-day dl | All-time dl | Stars | Last release | Maintenance | Notable adopters | Trade-off |
|---|---:|---:|---:|---|---|---|---|
| `tracing-opentelemetry` · bridge layer (**the pick**) | 46,120,245 | 210,366,232 | 409 | 0.34.0, 2026-09-23 | active | 1,056 reverse deps; the seven manifests above (carried) | Must move in lockstep with the OTel 0.x train |
| `opentelemetry-otlp` + `opentelemetry` + `opentelemetry_sdk` + `opentelemetry-http` · exporter, API, SDK, header carriers | 42,378,989 (otlp); 62,093,844 / 56,201,160 / 37,981,616 | 160,163,609; 273,950,228 / 228,219,587 / 152,353,252 | 2,718 | 0.33.0, 2026-09-18 | active | 1,003 / 1,294 reverse deps (otlp / sdk) | Official and vendor-neutral, but traces are Beta with breaking releases |
| `opentelemetry-appender-tracing` · logs-to-OTel bridge (for R58's log-export option only) | 8,504,463 | 19,617,877 | 2,718 | 0.33.0, 2026-09-18 | active | Spin (carried, `raw/opus.md:73`) | Correlation at the collector for free, but a second provider and R58's decision |
| `fastrace-opentelemetry` + `fastrace` · alternative span model | 1,057,902 / 1,408,144 | 4,970,189 / 7,177,731 | 1,135 | 0.18.1, 2026-06-17 / 0.7.19, 2026-07-31 | active | 4 reverse deps | Lower per-span overhead, but replaces `tracing` and pins OTel 0.32 |

Maintenance by the rubric: `open-telemetry/opentelemetry-rust` — 216 open issues, pushed
2026-09-25, release 8 days before retrieval → **active**. Its 10 most recent issues show 3
answered with a median of 0.1 days and 7 without a maintainer-association comment; the
unanswered count is not used for the rubric, because 4 of the 7 are under 4 days old and
Opus's caveat that private organization membership reports as `CONTRIBUTOR` applies
(`raw/opus.md:526`). `tokio-rs/tracing-opentelemetry` — 18 open issues, median first response
0.5 days over 6 answered, 4 unanswered, one 124-day response (`r78-figures.log` §6) → **active**
(released 5 days after upstream). `fast/fastrace` — 11 open issues, pushed 2026-07-31 →
**active** (carried rubric; responsiveness not re-sampled).

**The six gates, per candidate** (before popularity).

| Gate | `tracing-opentelemetry` 0.34.0 | OTel core 0.33.0 (5 crates) | `fastrace-opentelemetry` 0.18.1 |
|---|---|---|---|
| 1 licence | inapplicable (Q7.B); MIT | inapplicable (Q7.B); Apache-2.0 | inapplicable (Q7.B); Apache-2.0 |
| 2 MSRV ≤ 1.96 | 1.75.0; tree compiled under 1.96.0 (`M01`) | 1.75.0; same | 1.91.0 (`r78-figures.log` §1); not compiled |
| 3 advisories | none (RustSec 404, validated by control `atty` → 200, `R01`) | none (`R04-*`) | none carried (`raw/opus.md:513`); not re-checked |
| 3 `unsafe` | **3 lines**: two `unsafe fn downcast_raw` (`src/layer.rs:1557`, `src/layer/filtered.rs:172`) and one `unsafe` block calling the inner layer's hook (`filtered.rs:176`) — the `tracing-subscriber` `Layer` trait's required downcast mechanism (`S19`) | **0** lines in `src/` of all five (`S18`) | one block, carried (`raw/opus.md:514`) |
| 4 OS | upstream CI on ubuntu, windows, macos (carried, `raw/opus.md:515`; Muse agrees, `raw/muse.md:73`); **executed here on macOS only** | same (carried; `raw/muse.md:70-72`) | carried |
| 5 default features and runtime | defaults `metrics`, `tracing-log` (`F04`) — turned off; no runtime coupling | otlp defaults `http-proto`, `reqwest-blocking-client`, `trace`, `metrics`, `logs`, `internal-logs` (`F01`); export on an OS thread (`S07`, `S13`); gRPC would need Tokio | none carried |
| 6 size and compile cost | small | moderate: `prost`, `opentelemetry-proto`, blocking `reqwest`; +4.37 MB debug unstripped over `web` (`r78-probe.log` §1) | small, plus a second span model |

**Excluded by gate.**

- **`opentelemetry-jaeger` 0.22.0** (last release 2024-05-15) — gate 3: RUSTSEC-2025-0123 is on
  its RustSec page (`R02`). Jaeger ingests OTLP natively.
- **`minitrace` 0.6.7** (2024-06-23) — gate 3: RUSTSEC-2024-0390 (`R03`); renamed `fastrace`.
- **`axum-tracing-opentelemetry` 0.39.1 + `tracing-opentelemetry-instrumentation-sdk` 0.38.3**
  — excluded here on **version compatibility**, which this synthesis verified: both require
  `opentelemetry ^0.32` and `tracing-opentelemetry ^0.33` (`V04`), so combining them with the
  pick would put two `opentelemetry` versions in the tree. Opus additionally excludes it on
  gate 4 (upstream CI matrix `ubuntu-latest` only, `raw/opus.md:544`); that claim is
  **carried and uncorroborated**, because repository workflow files are not a named endpoint.
  Figures: 2,386,325 / 16,371,187 downloads, 249 stars, 0.39.1 on 2026-08-30, 18 reverse
  deps, `rust_version` 1.91.0.

**Passed the gates but excluded by fit.** `reqwest-tracing` 0.7.1 — its `opentelemetry_*`
features stop at `opentelemetry_0_32` (`V06`), so it would compile a second `opentelemetry`;
`HeaderInjector` does the same job in a few lines (`E08`). `init-tracing-opentelemetry`
0.41.1 and `tracing-otel` 0.33.2 — both pin `^0.32` and both own subscriber initialization,
which is R58's. `opentelemetry-stdout` and `opentelemetry-zipkin` 0.33.0 — non-OTLP; the
former is a reasonable dev-dependency, as is `opentelemetry_sdk`'s `testing` feature (present
in 0.33.0, `r78-figures.log` §3).

**Up-and-comers.** `fastrace` (revisit if a measured workload shows `tracing` overhead matters
and R58 leaves `tracing`); an axum or tower instrumentation crate in the SIG's
`opentelemetry-rust-contrib`, which would release in lockstep and replace the hand-written
middleware — **none was found** (Opus's census, `raw/opus.md:568-572`; not re-searched);
`logfire` as a vendor wrapper, which binds to a vendor and is not a template candidate.

**Fit for this template.** *CLI* — no OpenTelemetry. `otel` requires `web`, the CLI binary
never initializes telemetry, and the library's `tracing` spans cost nothing without a layer.
*Library* — no OpenTelemetry dependency, ever; a library user who wants export installs the
bridge in their own binary and the library's spans export unchanged, which is the decisive
reason A beats B. *Web* — one module, one middleware call, one outbound helper, one guard;
fits R69's multi-thread `#[tokio::main]` and its drain deadline, and serves in every
telemetry state (`D01`–`D14`, `W01`–`W03`).

**Recommendation.** Adopt `tracing-opentelemetry >= 0.34.0, < 0.35.0` with `opentelemetry`,
`opentelemetry_sdk`, `opentelemetry-otlp` and `opentelemetry-http` at `>= 0.33.0, < 0.34.0`,
feature-selected as in the TOML block above, behind `otel = ["web", …]`, with the three-gate
degrade contract and the seven instrumentation points.

**Ranked runner-up: the same architecture and generation with the prebuilt glue** —
`axum-tracing-opentelemetry` for the server span and `reqwest-tracing` for the outbound client —
in place of the hand-written middleware and injection helper. **It wins when both publish
releases compatible with the pick's OTel generation** (today both pin 0.32, `V04`, `V06`) **and
there is macOS evidence for `axum-tracing-opentelemetry`**, whether from upstream CI or from the
template's own `macos-latest` job. Maintained, semantic-convention-aware middleware then beats
about 40 hand-written lines. The glue lagged 16 days in the 0.32 cycle (`raw/opus.md:269-270`,
carried). **Fallback, not a runner-up:** if a 0.33.x regression in trace export surfaces
before P03, drop the whole set to the 0.32 generation (`tracing-opentelemetry >= 0.33.0,
< 0.34.0` with OTel `>= 0.32.0, < 0.33.0`), which is what the surveyed adopters run and what
Doxa-OpenAI recommended.

**Tradeoffs, and why each cost is accepted.**

- *Versus the glue runner-up:* the pick gives up prebuilt semantic-convention attributes and
  accepts roughly 40 lines P03 must test. Accepted because mixing generations is a
  correctness hazard, and the hand-written code uses only APIs that release in lockstep with
  the pick (`HeaderExtractor`, `HeaderInjector`, `set_parent`); the probe exercised all three.
- *Versus the 0.32 generation:* the pick takes an 8-day-old generation no surveyed adopter runs
  yet. Accepted because 0.33 is the generation that turns an invalid endpoint into a build
  error rather than a silent localhost fallback (`S02`, `D08`) and enables retries by default
  (`S04`), and because starting on the current generation maximizes time to the next forced
  bump.
- *Versus OTLP/gRPC (`grpc-tonic`):* the pick gives up gRPC streaming efficiency and tonic's
  mTLS plumbing. Accepted because HTTP/protobuf is the crate's default, keeps export free of
  Tokio, avoids `tonic` and HTTP/2 in the tree, and matches py. A collector that exposes only
  gRPC flips one feature; everything else stays.
- *Versus direct OpenTelemetry instrumentation:* the pick gives up exact native span APIs and
  pays one extra layer callback per span. Accepted because a single span model is what keeps
  the library and CLI OpenTelemetry-free.
- *Versus leaving the SDK defaults:* the template carries a runtime flag and one
  `OTEL_SDK_DISABLED` check the SDK does not provide. Accepted because without them an `otel`
  build exports to localhost by default (`D05`) and ignores the standard kill switch (`D06`).

**Migration implications (files P03 creates; proposals).**

| File | Change |
|---|---|
| `Cargo.toml` | The `otel` feature and five optional dependencies above. Dev-dependency for hermetic tests: `opentelemetry_sdk` with its `testing` feature (in-memory exporter). |
| `src/web/telemetry.rs` | Enable-flag and `OTEL_SDK_DISABLED` gate; exporter build returning a value on error; provider with batch exporter and `service.name = <app>-web`; propagator installation; the optional, per-layer-filtered bridge layer; the guard; the `cfg(not(feature = "otel"))` path that warns once when OTLP variables are set. |
| R58's subscriber assembly | One `.with(otel_layer_option)`; log `otel_unavailable` after `init()`. |
| `src/web/` router (R69's `build_router`) | The server-span middleware, or its `set_parent` call folded into R75's request-span middleware. |
| Serve binary (R69) | `shutdown_with_timeout(budget)` in `spawn_blocking` after `with_graceful_shutdown`; warn on `Err`; exit code unchanged. |
| R01's production adapter | The outbound client span and `HeaderInjector` call around the adapter's HTTP request. |
| R77's settings | The enable flag (default `false`) and the shutdown budget (not above the drain deadline). |
| Collector recipe for the acceptance job | A pinned OpenTelemetry Collector with an OTLP/HTTP receiver on 4318 and a file exporter, on `ubuntu-latest`; the `macos-latest` leg runs the hermetic in-memory tests (GitHub's macOS runners lack Docker, `raw/opus.md:705`, carried). |
| CI | `web` and `web,otel` builds and tests on both OSes; the `cargo tree` absence checks; `cargo +1.96` check of `web,otel`. |

**Validation strategy.** Everything in `r78-probe.sh` is **executed** evidence on one macOS host
(`## Empirical check`). The same sequence against the real template is **planned** for P03 and
is listed under *What P03 must validate* at the end of `## Engines`.

**Confidence.** High on the architecture, the transport and the degrade contract: each rests on
published sources at the exact versions and on an executed end-to-end run. Medium-high on the
generation: 0.33/0.34 compiles, resolves singly, runs end to end and compiles at the MSRV floor,
but it is 8 days old and no surveyed adopter runs it yet. Medium on anything Linux-specific:
nothing ran on `ubuntu-latest`.

re-verify: 2026-12-27, or earlier on any of — R58 publishing `logging-pipeline-contract` (this decision's assumptions below must then be checked, and the decision revised if R58 does not assemble a `tracing_subscriber::Registry` with an optional-layer extension point); opentelemetry-rust publishing 0.34.0 or any 0.33.x that changes the trace, OTLP-HTTP or batch-processor behavior this decision measured, or tracing-opentelemetry publishing 0.35.0; axum-tracing-opentelemetry and reqwest-tracing both publishing releases compatible with opentelemetry 0.33 (the runner-up's winning condition); R79 choosing OpenTelemetry metrics (shared generation, shared Resource, one shutdown place); R75 selecting tower-http 0.7.x (the duplicate tower-http recorded above); R77 naming the enable flag; the SIG's README declaring traces stable; a RustSec advisory against any of the five crates; or any of the five declaring a rust-version above the then-current stable-minus-2 floor.

## Parameters

R78 owns no registry parameter: the binding prompt's `## Couplings` carries an empty
`- owns:` line (`inputs/prompt.md:24`), and `inputs/PARAMETERS.md` lists no R78 owner. Its one
consumed parameter is R58's (`inputs/prompt.md:25`). R69's `web-extra-surface` is also a
prerequisite (`inputs/prerequisites.json`, decision sha256
`d4507f5b2ca4201d9837caf013de16f30070cb3e2f5558eb66f7ded9dfd2c10d`, which matches the file on
disk) through the prompt's `- related` mention of R69. It is not a `- consumes:` parameter, so
it carries no `- assumes` line, following the published convention (R69's own decision lists
only the four fixed parameters and its one consumed parameter). Its value is recorded after the
list, exactly as registered.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes logging-pipeline-contract = —

**`logging-pipeline-contract` is unresolved.** The registered value is `—`
(`inputs/parameters.json`), and `inputs/prerequisites.json` records R58 `decision: missing`,
`acceptance: missing`.

**Relied on from the R69 prerequisite decision (not a consumed parameter):**
`web-extra-surface` = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files

**The conditions this decision assumes of R58, stated so the controller can check them against
R58's published value.** (1) The base pipeline is a `tracing_subscriber::Registry` assembled
from composable layers. (2) Before `.init()`, it accepts one additional `Option<L>` layer from
`src/web/telemetry.rs`, compiled only with `otel`. (3) It accepts a per-layer `Targets` filter
on that layer, independent of its global filter; if R58 does not enable `tracing-subscriber`'s
`env-filter` feature, `Targets` needs none (the probe used `Targets`). (4) Warnings emitted
after `.init()` reach the operator, so `otel_unavailable` is visible. (5) R58 decides whether
log correlation is a local `trace_id` field or OpenTelemetry log export; this decision
supports either and adds no crate for it. If R58 selects a non-`tracing` substrate, this
decision must be re-run rather than patched.

**No `CONFLICT:` line.** No report raised one, and nothing here requires a registered value to
change. R69's owned value already names `otel = ["web", …]` and "heavier opt-ins nest on top
rather than widening it"; this decision fills that slot and moves nothing in `web`.

**How the assumed parameters bear on the decision.** `msrv-policy` sets the floor at 1.96
against local stable 1.98.1; all five crates declare 1.75.0 (`C04-*`) and the locked `otel` tree
compiled under 1.96.0 (`M01`). `rust-edition = 2024` is the probe's edition. `target-os-matrix`
is the gate-4 obligation: upstream CI evidence for macOS is carried, and this run executed on
macOS only, so `ubuntu-latest` is P03's receipt. `license` is metadata only (Q7.B).
`web-extra-surface` fixes the module location (`src/web/`), the runtime (`tokio` 1.53.1
multi-thread), the exit codes 143/130 the shutdown path must preserve, and the `matched-path`
feature the server span's route attribute uses.

## Empirical check

**Toolchain and host.** `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`,
`cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, and `rustc 1.96.0 (ac68faa20 2026-05-25)` via
`rustup run 1.96.0`; macOS 26.4 (build 25E246), `Darwin 25.4.0 arm64`; `curl 8.7.1`, `jq-1.8.2`,
`gh version 2.101.0`, `ShellCheck 0.11.0`; `/usr/bin/grep` by absolute path in every script.
Private `CARGO_HOME=/tmp/cargo-s13-R78`. The probe pins `CARGO_TARGET_DIR` inside its own
workspace, because this environment exports a different one.

**Commands and working directory.** Three scripts, each run from the evidence directory, each
shellchecked first. All three were rerun fresh for the committed logs.

```bash
cd /Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R78/2026-09-26T190312Z-8cf4b61ddead/review/evidence
shellcheck r78-figures.sh        && bash r78-figures.sh        > r78-figures.log 2>&1
shellcheck r78-source-census.sh  && bash r78-source-census.sh  > r78-source-census.log 2>&1
shellcheck r78-probe.sh          && bash r78-probe.sh          > r78-probe.log 2>&1
```

**Observed result.** `shellcheck` exits 0 with no finding on all three scripts.

| Script | What it reads or runs | Checks | Result |
|---|---|---:|---|
| `r78-figures.sh` | crates.io API, GitHub API (`repos`, `search/issues`, issue comments), RustSec pages | 33 | 33 pass, exit 0 |
| `r78-source-census.sh` | the published tarballs of `opentelemetry`, `opentelemetry_sdk`, `opentelemetry-otlp`, `opentelemetry-http` 0.33.0, `tracing-opentelemetry` 0.34.0 and `tracing-subscriber` 0.3.23, fetched by `cargo fetch` and read by absolute path | 26 | 26 pass, exit 0 |
| `r78-probe.sh` | a two-crate workspace built and run end to end (below) | 41 | 41 pass, exit 0 |

**100 assertions, none failing, none skipped on this host.** Each script's exit status is its
failure count, and each assertion compares expected content, so none can pass on an empty
input: an earlier draft of the probe exposed exactly that hazard (an inherited
`CARGO_TARGET_DIR` left no binaries and several checks passed vacuously), and the committed
script now aborts before any runtime scenario unless all three binaries exist and asserts both
`cargo tree` listings are non-empty (`T00`).

**What the probe is.** `svc` is an axum 0.8.9 / tokio 1.53.1 service built with the exact
dependency block in `## Decision`. `GET /demo` runs an instrumented `demo.work` span, then makes
an outbound `GET /downstream` to itself inside a client span with the context injected.
`collector` is a real OTLP/HTTP receiver: it accepts `POST /v1/traces`, decodes the protobuf
`ExportTraceServiceRequest` with `opentelemetry-proto` 0.33.0 and `prost` 0.14, and writes one
JSON line per span. It is a separate crate so `svc`'s dependency tree is measured alone. Every
scenario runs two real processes over loopback and stops the service with a real SIGTERM.

**The deciding end-to-end run** (`r78-probe.log` §4). The request carried
`traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01`, and the service ran with
`OTEL_BSP_SCHEDULE_DELAY=60000`, so no periodic export could fire. The collector held **0**
spans before SIGTERM; the process exited **143** in 11 ms; the collector then held these four
spans in the incoming trace, plus one separate root trace from the script's readiness probe:

```text
http.server.request  kind 2 (SERVER)  route /demo        span 432e2a91a4377b08  parent 00f067aa0ba902b7  (the incoming parent)
demo.work            kind 1 (INTERNAL)                   span b84a289c7a4b974f  parent 432e2a91a4377b08
http.client.request  kind 3 (CLIENT)                     span 7e5aae067d1e41fc  parent 432e2a91a4377b08
http.server.request  kind 2 (SERVER)  route /downstream  span 0e74b374b244a62e  parent 7e5aae067d1e41fc  (injected, re-extracted)
```

All four carry trace ID `4bf92f3577b34da6a3ce929d0e0e4736` and `service.name = probe-web`, the
`/demo` span recorded status 200, and the service log line `demo request completed
trace_id=4bf92f3577b34da6a3ce929d0e0e4736` correlates the request (`E01`–`E13`). That covers
RUNBOOK §5's incoming request, handler, outbound operation, propagation in and out, actual
export decoded at a receiver, and shutdown. Exporter failure is §8 and §9; metrics are R79's.

**The degrade and boundary runs**, summarized in the table under *The degrade contract*:
feature absence (`T00`–`T06`: 0 OpenTelemetry crates in the `web` tree, `cargo tree -i
opentelemetry` exits 101 "did not match any packages", 0 `opentelemetry` strings in the `web`
binary); one generation (`T02`–`T04`: single `opentelemetry v0.33.0`, `tracing-opentelemetry
v0.34.0`, the only duplicated crate is `syn` 2/3); the MSRV compile (`M01`); flag off (`D01`–`D04`);
unconfigured endpoint exporting to `127.0.0.1:4318` (`D05`); `OTEL_SDK_DISABLED` ignored by the
SDK and honoured by the guard (`D06`, `D07`); invalid endpoint (`D08`, `D09`: `WARN svc:
otel_unavailable error=invalid exporter configuration: OTEL_EXPORTER_OTLP_ENDPOINT: invalid
endpoint '::not a url': invalid uri character`); unreachable collector (`D10`–`D14`: 100/100
× 200, SIGTERM-to-exit 454 ms against a 2,000 ms budget); web-only build with OTLP variables set
(`W01`–`W03`).

**Reproducibility.** crates.io releases are immutable, so every source-census line and every
version or dependency edge reproduces exactly. Download counts, stars, issue counts and the
responsiveness sample move with time. The probe's span and trace IDs other than the fixed
incoming ones, its ports, and its millisecond timings differ on every run; its assertions do
not depend on them. The probe prints the first three exporter-diagnostic lines with `head` for
display only; the count asserted in `D14` is computed separately over the whole log.

**What this check does not prove**, listed rather than glossed:

1. **`ubuntu-latest`.** Nothing ran on Linux. Gate 4 is satisfied only by the template's own
   CI job on both OSes.
2. **A real OpenTelemetry Collector.** The receiver is a minimal OTLP/HTTP decoder; it proves
   the wire format and the span graph, not interoperability with `otelcol-contrib` or a vendor
   backend. The collector-backed acceptance job is P03's.
3. **Release-profile cost.** No release build, no stripped size, no benchmark.
4. **R58's actual pipeline.** The probe's `fmt` layer stands in for whatever R58 selects.
5. **Metrics**, which are R79's leg of the shared example.
6. **TLS to a collector**, deliberately not enabled.
7. **Hermetic in-memory tests** (`opentelemetry_sdk` `testing`) for the macOS CI leg — the
   feature exists (`r78-figures.log` §3); no test using it was written.
8. **The unreachable-collector memory bound under load.** The 2,048-span queue bound is read
   from source (`S08`); 100 sequential requests produce 400 spans and do not fill it.

## Engines

- **Muse (Meta)**, model not recorded — `raw/muse.md`, sha256 `c3a61ef9…`. Recommends the 0.33 /
  0.34 train, `opentelemetry-otlp` **with default features**, the bridge with
  `default-features = false`, outbound propagation through `reqwest-tracing`, and a degrade
  path that, when unconfigured, "read[s] standard `OTEL_EXPORTER_OTLP_*` env vars with the SDK
  default endpoint" (`raw/muse.md:96-98`). Runner-up: the same stack over `grpc-tonic`
  (`:102`). Raises no `BASELINE-REVIEW:` (`:60`) and no `CONFLICT:`.
- **Claude Opus** (`claude-opus-5-5`) — `raw/opus.md`, sha256 `7b2fbae3…`. Recommends the 0.33 /
  0.34 set plus `opentelemetry-http`, all `default-features = false`, a hand-written server
  middleware and injection helper, and a **three-gate ladder** (`raw/opus.md:157-180`).
  Runner-up: the 0.32 generation with `axum-tracing-opentelemetry` and `reqwest-tracing`
  (`:639-655`). Raises `BASELINE-REVIEW: F325` (`:424-434`). No `CONFLICT:`.
- **Doxa → OpenAI** (`gpt-5.6-sol`) — `raw/doxa-openai.normalized.md`, sha256 `4817dac1…`.
  Recommends `tracing-opentelemetry 0.33` with the **0.32** OTel set plus `opentelemetry-http`
  and `reqwest-rustls`, endpoint-presence activation, `OTEL_SDK_DISABLED`, and no retries
  (`raw/doxa-openai.normalized.md:160-168`, `:250-306`). Runner-up: direct OTel 0.33, then
  gRPC (`:331-337`). Raises `BASELINE-REVIEW: F325` (`:140`). Declares five `owns R78.*` lines
  (`:353-361`). Could not reach crates.io or the GitHub API and marks every figure `NR` (`:35`).
- **Doxa → Gemini** (`deep-research-preview-04-2026`) — `raw/doxa-gemini.normalized.md`, sha256
  `560515a3…`. Recommends the OTel **0.33.0** set with `tracing-opentelemetry` **0.33.0** and
  `axum-tracing-opentelemetry` "0.20+" (`raw/doxa-gemini.normalized.md:78-82`). Runner-up:
  `tower_http::trace::TraceLayer` (`:92`). Raises a line labelled `BASELINE-REVIEW: F304`
  (`:33`). No `CONFLICT:`.

**Agreements that are not disagreements.** All four choose architecture A (the `tracing` bridge
into the official SDK and OTLP exporter), OTLP over HTTP/protobuf as the default transport, the
batch span processor, and "the web example stays gated by `web` only". All four reject `fastrace`
as the template's span model and treat `opentelemetry-jaeger` as dead. All four say the bridge is
a pure addition to a `tracing_subscriber::Registry`. The executed evidence confirms each point
it touches (`E01`–`E13`, `S15`, `F01`).

**Disagreement 1 — which generation pairs with which bridge. Settled for Muse and Opus by the
registry and by compilation.** Doxa-OpenAI states that "`tracing-opentelemetry` 0.33.0 depends
on `opentelemetry` 0.32.0, while the official OTel crates released 0.33.0" and that the current
bridge therefore forces the 0.32 set (`raw/doxa-openai.normalized.md:73`). Doxa-Gemini pairs
`tracing-opentelemetry` 0.33.0 with OTel 0.33.0 (`raw/doxa-gemini.normalized.md:81`, `:98`).
Muse and Opus pair 0.34.0 with 0.33. crates.io shows `tracing-opentelemetry` 0.34.0, published
2026-09-23T08:25:46Z, requiring `opentelemetry ^0.33.0`, and 0.33.0 requiring `^0.32.0`
(`C01`, `C02`, `V01`, `V02`). Doxa-OpenAI's own sources are docs.rs `latest` pages captured as
0.33.0 (`:768`), and its retrieval of the registry failed (`:35`), which explains a view three
days stale. Gemini's pairing would not resolve to one `opentelemetry`. The recommended set
resolves singly and runs (`T02`–`T04`, §4).

**Disagreement 2 — the server-span middleware: hand-written, `axum-tracing-opentelemetry`, or
framework-neutral. Settled for hand-written.** Gemini adopts `axum-tracing-opentelemetry` "0.20+
or the corresponding release supporting OTel 0.33" and lists it as "v0.12.0-alpha"
(`raw/doxa-gemini.normalized.md:55`, `:82`); the crate is at 0.39.1 and no release supports
0.33 (`V04`, `r78-figures.log` §1). Doxa-OpenAI refuses framework middleware because "R69 has
not selected a framework" (`raw/doxa-openai.normalized.md:16`, `:212-214`); R69 is resolved
and selects axum 0.8.9 (`inputs/prerequisites.json`; `DECISION.md:1586`), so that ground no
longer holds, but its conclusion survives on the version ground. Opus's hand-written
`from_fn` middleware ran correctly end to end (`E05`–`E08`).

**Disagreement 3 — does an unconfigured `otel` build need a runtime gate? Settled for a runtime
flag, by measurement.** Muse's degrade (b) uses "the SDK default endpoint" when nothing is
configured (`raw/muse.md:98`). Opus says the exporter "defaults the endpoint to
`http://localhost:4318`" and requires a flag (`raw/opus.md:163-171`); Doxa-OpenAI requires an
explicit endpoint instead (`raw/doxa-openai.normalized.md:82-86`); Doxa-Gemini says the service
"will attempt to export, fail gracefully" (`:88`). The source defines
`OTEL_EXPORTER_OTLP_HTTP_ENDPOINT_DEFAULT = "http://localhost:4318"` (`S01`, at
`opentelemetry-otlp-0.33.0/src/exporter/mod.rs:55`; Opus's `lib.rs:222` citation is the
environment-variable table row, not the constant), and the probe measured 12 spans arriving on
127.0.0.1:4318 with no endpoint variable set (`D05`). Muse's semantics would make a sidecar-less
deployment send spans to whatever listens on localhost, so a gate is required. **Between Opus's
flag and Doxa-OpenAI's endpoint-presence activation, the flag is chosen**: it mirrors py's
`otel_enabled` settings gate (carried), so the two repositories share the same two-gate
behavior; it keeps the SDK's standard default usable for the common localhost-sidecar topology
without restating the default as configuration; and it makes "compiled in but off" an explicit,
testable state (`D01`–`D03`). The cost is one setting, owned by R77. Doxa-OpenAI's
feature-absent warning is adopted as well (`W03`), because in a `web`-only build it is the only
signal an operator gets.

**Disagreement 4 — `OTEL_SDK_DISABLED`. Settled for Opus and Doxa-OpenAI.** Both say the
template must honor it. No crate in the set reads it (`S03`), and the probe exported 9 spans
with `OTEL_SDK_DISABLED=true` when the guard was off (`D06`) and 0 when it was on (`D07`). Muse
and Gemini do not mention it.

**Disagreement 5 — retries. Settled for Opus.** Doxa-OpenAI says "Do not enable experimental
retry features by default" (`raw/doxa-openai.normalized.md:92`). In 0.33.0 retries are on by
default, with no feature flag: the 0.33.0 `CHANGELOG.md` says "Retries are now enabled by
default for OTLP/HTTP and OTLP/gRPC" and tells users to remove the `experimental-*-retry` flags,
the manifest declares no retry feature, and `RetryPolicy::recommended()` is 3 retries from
100 ms to 1,600 ms (`S04`, `S05`). The probe's log showed `retries=3` on each exhausted batch,
and shutdown still finished in 454 ms (`D13`), so the default is kept.
`RetryPolicy::disabled()` remains available if P03's measurements argue otherwise.

**Disagreement 6 — how shutdown flushes. Settled against Gemini; Opus and Doxa-OpenAI differ
only in detail.** Gemini calls `opentelemetry::global::shutdown_tracer_provider()`
(`raw/doxa-gemini.normalized.md:69`, `:120`); the function does not exist in 0.33.0 (`S06`) and
the crate's `CHANGELOG.md` records its removal in favor of `tracer_provider.shutdown()`.
Doxa-OpenAI calls `force_flush` then a bounded shutdown (`raw/doxa-openai.normalized.md:124`);
Opus calls `shutdown_with_timeout` in `spawn_blocking` (`raw/opus.md:199-202`). The probe shows
`shutdown_with_timeout` alone delivers the buffered spans (`E02`, `E04`), so the extra flush
is unnecessary. Doxa-OpenAI's collector check expects `test "$?" -eq 0` after SIGTERM
(`raw/doxa-openai.normalized.md:579`); R69's registered value fixes **143** after a
SIGTERM-initiated drain, which the probe observed (`E03`). That is a raw error, not a
`CONFLICT:`.

**Disagreement 7 — who runs the batch processor. Settled against Gemini.** Gemini says "The
`tokio` asynchronous runtime … natively powers the `BatchSpanProcessor`"
(`raw/doxa-gemini.normalized.md:73`). In 0.33.0 the processor spawns an OS thread (`S07`) and
the blocking HTTP client is built on its own thread (`S13`), which is why export is
runtime-independent. Gemini's CLI section (`:69`) also has the CLI flushing telemetry; the CLI
never initializes it (`## Decision`, *Fit*).

**Disagreement 8 — `unsafe` in the bridge. Neither report is exact.** Muse says "zero `unsafe`
in `src/`" for `tracing-opentelemetry` (`raw/muse.md:73`); Opus says one `unsafe fn
downcast_raw` (`raw/opus.md:514`). The 0.34.0 tarball has three lines: two `unsafe fn
downcast_raw` and one `unsafe` block (`S19`). All three implement `tracing-subscriber`'s
`Layer::downcast_raw` hook, which is how `Span::context()` reaches the layer. The four OTel
crates have none (`S18`), matching Muse and Opus's code search.

**Disagreement 9 — outbound propagation: `reqwest-tracing` or `opentelemetry-http`. Settled for
`opentelemetry-http`.** Muse relies on `reqwest-tracing` "or equivalent" (`raw/muse.md:90`);
its newest release offers `opentelemetry_*` features only through `opentelemetry_0_32` (`V06`),
so it cannot share the pick's types. `HeaderInjector` from `opentelemetry-http` 0.33.0 (`S17`)
did the job in the probe (`E08`). Opus and Doxa-OpenAI both include `opentelemetry-http`;
Muse and Gemini omit it.

**Disagreement 10 — default features. Settled for explicit features (Opus, Doxa-OpenAI) against
Muse's `opentelemetry-otlp` defaults.** The defaults add the `logs` signal, outside this item's
scope (`F01`). Opus's note that the set "is not metrics-free" is correct and measured (`F03`,
`T05`); Doxa-OpenAI's "No metrics/log signals" (`raw/doxa-openai.normalized.md:193`) is wrong for
metrics for the same reason.

**Disagreement 11 — TLS. Left off, as Opus proposes; Doxa-OpenAI's `reqwest-rustls` is not
adopted.** Doxa-OpenAI enables it for an "application-level OpenSSL" reason
(`raw/doxa-openai.normalized.md:192`); the feature is additive (`S20`) and no acceptance criterion
needs an `https://` collector. Recorded as a gap for P03 to confirm.

**Disagreement 12 — the runner-up.** Four different runners-up were proposed: gRPC transport
(Muse), 0.32 plus glue (Opus), direct OTel 0.33 (Doxa-OpenAI), `tower-http`'s `TraceLayer`
(Gemini). The ranked runner-up here is the glue crates on the pick's generation, because it is
the only alternative whose winning condition is an observable, dated event (`V04`, `V06`), and
it keeps every other part of the decision. gRPC is a transport configuration of the pick rather
than a different crate choice, and is recorded under *Tradeoffs*. Direct OTel is rejected on
architecture (B). `TraceLayer` is R75's to select and does not by itself propagate W3C context.
The 0.32 generation is recorded as a fallback.

**Raw errors not adopted, beyond those above.** Gemini's "6.9k" stars for
`tracing-opentelemetry` (`raw/doxa-gemini.normalized.md:54`) is `tokio-rs/tracing`'s figure
(6,891); the bridge's repository has 409 (`G01`, `G02`). Gemini's collector recipe points
`OTEL_EXPORTER_OTLP_ENDPOINT` at port 4317, the gRPC port, while recommending the HTTP exporter
(`:128`). Gemini's `assumes logging-pipeline-contract = F304 DIVERGENT` (`:110`) is not a
parameter value. Doxa-OpenAI's five `owns R78.*` lines (`raw/doxa-openai.normalized.md:353-361`)
are **rejected**: the prompt's `- owns:` line is empty (`inputs/prompt.md:24`) and no registry
row names R78 as an owner; their content is carried here as decision text, not as parameters.
Muse's exclusion of `opentelemetry-jaeger` "on maintenance fitness", "Not a
license/MSRV/advisory failure" (`raw/muse.md:77`), misses RUSTSEC-2025-0123 (`R02`); the
exclusion stands on gate 3.

**`BASELINE-REVIEW:` lines, carried verbatim with their disposition. The ledger is not edited
here.**

> **BASELINE-REVIEW: F325 — optional tracing never breaks the service — the row text "whether
> Rust's optional OTel support is a compile-time Cargo feature gate rather than py's runtime
> soft-import degrade" should read "compile-time feature gate **plus** a runtime enable flag and
> a runtime exporter-build degrade" — evidence:** (`raw/opus.md:424-427`, evidence bullets
> `:429-434`)

> **BASELINE-REVIEW: F325 — optional observability must soft-degrade without becoming a service
> dependency — replace Python's runtime import fallback with Rust's compile-time feature
> exclusion plus runtime exporter activation/fallback; warn once and continue for absent
> feature, absent configuration, initialization failure, collector failure, and shutdown
> failure — Cargo's native optional dependency boundary, the runtime-independent HTTP/batch
> architecture, and Python's existing warning-not-crash behavior preserve the same policy while
> using ecosystem-appropriate mechanisms.** (`raw/doxa-openai.normalized.md:140`)

**Disposition: accepted in substance, for the controller to apply to F325.** Both lines say the
same thing — a compile-time gate alone does not preserve "opt-in and never breaks the service"
— and the evidence now supports it directly: `D05` (an unconfigured `otel` build exports to
localhost), `D06` (the SDK ignores `OTEL_SDK_DISABLED`), `D08` (0.33 turns an invalid endpoint
into a build error the template must catch). Where they differ, this decision takes Opus's
"runtime enable flag" over Doxa-OpenAI's "runtime exporter activation" (Disagreement 3) and
Doxa-OpenAI's "warn once … for absent feature" (`W03`). One qualification to "warn once … collector
failure": the SDK emits one WARN and one ERROR line **per failed batch**, not once
(`r78-probe.log` §9), which is bounded by the batch schedule rather than single. Affected
items: R78 and R58 (which owns the F304 boundary); the verdict `DIVERGENT` is unchanged.

> `BASELINE-REVIEW: F304 — The web example must not become optional — F304 is classified DIVERGENT in R58.` (`raw/doxa-gemini.normalized.md:33`)

**Disposition: not a finding.** The line lacks the required
`principle — proposed change — evidence` shape: it proposes no change, and its text restates
the prompt's own baseline note (`inputs/prompt.md:14`). This decision keeps the web example
gated by `web` only, as all four reports do.

**`CONFLICT:` lines.** None raised by any report; none raised here.

**Sources this synthesis relied on but did not itself re-read** (outside the named endpoints or
the permitted reads): the py source files and `pyproject.toml` (via `inputs/prompt.md:8` and
`raw/opus.md:110-127`); the ts census (`raw/opus.md:129-130`); `docs/port/OWNER-REVIEW.md` and
`docs/port/COMMONALITY.md`; the SIG README maturity table and `docs/release_0.33.md` (their
0.33.0 claims were checked against the crate's own `CHANGELOG.md` instead); the seven adopter
manifests and Doxa-OpenAI's `crates.io`/`rustup` manifests; the upstream CI workflow files
behind gate 4; and `fastrace`'s `unsafe` block.

**Gaps recorded.**

1. **R58's `logging-pipeline-contract` is unpublished.** Acceptance cannot complete until it
   is, and the conditions under `## Parameters` must then be checked.
2. **The Muse leg's model identity is not recorded**, and `manifest.json` has not been updated
   with the collected operations (controller).
3. **Prompt snapshot drift** (engines line only) awaits the controller's revalidation ruling.
4. **Nothing ran on `ubuntu-latest`**, and gate-4 evidence for every crate is carried from
   upstream CI claims.
5. **No real OpenTelemetry Collector**, no release-profile cost measurement, no benchmark.
6. **TLS to the collector** is left off as a proposal.
7. **Outbound client ownership.** R01's adapter is where injection lands; the client crate is
   not chosen by this item.
8. **`axum-tracing-opentelemetry`'s gate-4 exclusion** is carried, not corroborated.
9. **The metrics leg** of RUNBOOK §5's shared example is R79's and is not covered here.

**What P03 must validate.** Each line is a check that can fail.

1. **The MSRV floor on the real tree.** `cargo +1.96 check --features web,otel --locked` once the
   template's lockfile exists. This synthesis compiled the probe's tree, not the template's.
2. **Both OSes.** `web` and `web,otel` build and test green on `ubuntu-latest` and
   `macos-latest`; the macOS leg runs the hermetic `opentelemetry_sdk` `testing` tests.
3. **The collector-backed acceptance job** on `ubuntu-latest` against a pinned OpenTelemetry
   Collector: the four-span chain of `r78-probe.log` §4 with the fixed `traceparent`,
   `service.name = <app>-web`, a correlated log line, and all spans present after SIGTERM with
   exit 143.
4. **Every degrade row** of the contract table, including exactly one `otel_unavailable`
   warning for an invalid endpoint and no export with the flag unset.
5. **Feature absence.** `cargo tree -e normal --features web -i opentelemetry` fails, and the
   `web` binary contains no `opentelemetry` string.
6. **A single generation.** `cargo tree -d --features web,otel` lists no duplicate
   `opentelemetry`, `http`, `reqwest` or `hyper`, and — once R75 decides — no duplicate
   `tower-http`.
7. **The shutdown budget** is at most R69's drain deadline, and SIGTERM-to-exit with a dead
   collector stays within drain deadline plus budget.
8. **Cost**, by the stated workload, in release mode; the flag-off configuration within noise of
   `web`.
9. **TLS**: whether the template's documented deployment needs `reqwest-rustls`.
