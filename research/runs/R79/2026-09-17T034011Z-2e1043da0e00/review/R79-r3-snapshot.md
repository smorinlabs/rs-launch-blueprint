# 2026-09-18 — R79 — prometheus-metrics (crate, Focused) — decision (revision 3)

Item R79 (`prometheus-metrics`, kind `crate`, Focused tier, owns nothing). Run
`research/runs/R79/2026-09-17T034011Z-2e1043da0e00`.

**Revision note (revision 3).** Revision 3 answers two round-1 audits of revision 2 (sha256
`1551c96d483f7be26ca0d50d1df2caa32d4542ccf66e0423ad40e5827ae2e215`, preserved byte for byte
at `review/R79-r2-snapshot.md`): the judgment audit `review/audit-fable.md` (verdict `reject`,
seven findings) and the empirical audit `review/audit-claude.md` (verdict `reject`, six
findings EA-1 to EA-6). Both audits were read in full. **The crate pair, the version ranges,
`default-features = false`, the metric names, the label set, the architecture choice and the
runner-up do not move.** Two things in the recommendation do move, because two findings
require it:

1. **The on-by-default posture now has py's off switch.** Revision 2 said py has no
   environment gate. That is false at the py pin: `settings.py:64` declares
   `metrics_enabled: bool = True`, and `app.py:148` applies the instrumentator only
   `if settings.metrics_enabled:`. The template now defines R77's
   `RSLBP_WEB_METRICS_ENABLED`, default `true`, with py's semantics (audit-fable F1).
2. **`BASELINE-REVIEW: F326` is raised.** Under R69's registered value, `--features web`
   alone serves no `/metrics`. That weakens "on by default", and the prompt requires the
   marker for such a challenge (audit-fable F3).

The feature graph, module paths and migration table are rewritten against R69's
**published revision 9**, the registered value this run's `inputs/prerequisites.json` pins,
rather than the unpublished revision 10 (audit-fable F5).

| Finding | Disposition in revision 3 |
|---|---|
| **F1** (fable, blocking) — py's metrics setting misread | **Accepted in full; the recommendation moves.** `### Principles and implementation` now quotes `settings.py:38`, `:44`, `:63`–`:64` and `app.py:148`–`:149` at the pin. The agreement table requires the off switch to agree. The MEDIUM answer, the R77 coupling and re-verify trigger (5) are rewritten. The new test target `metrics_disabled` executes `metrics_enabled = false` (check F1). The prompt's Context sentence "unconditionally (on by default, no env gate)" is wrong at the same source lines; it is flagged to the controller below, not edited here |
| **F2** (fable, blocking) — `## Engines` names Codex and adjudicates no Muse disagreement | **Accepted in full.** `## Engines` now names Muse and Opus with their report hashes and cites the substitution authority. It records the Muse leg's registration gap and adjudicates the ten disagreements the audit lists, plus four more found on reading `raw/muse.md`. The "Claims found wrong" table is relabelled as synthesizer-versus-Opus |
| **F3** (fable) — `--features web` serves no `/metrics`; no `BASELINE-REVIEW` | **Accepted in full.** `BASELINE-REVIEW: F326` is raised under `## Decision`, proposing a coupling request to R69. The unqualified "on by default within the enabled web surface" wording is withdrawn. The fact is now executed: test target `web_only` answers `404` at `/metrics` under `--features web` (check F3) |
| **F4** (fable) — revision 2's `/metrics` HTTP behaviour neither executed nor listed as unproven; `scrape` not routable | **Accepted; executed rather than listed.** The module the decision quotes is now `review/evidence/r3-obs-metrics.rs`, compiled and tested by `cargo-probes-r3.sh`. The self-check asserts the quoted block is byte-identical to that file. The tests assert `Cache-Control: private, no-cache`, the `Content-Type`, `200` for an `Accept: application/json` request, and `400` for four spellings of `stream`. `scrape` takes only `RawQuery` and calls `recorder()` |
| **F5** (fable) — designs against unpublished R69 revision 10 | **Accepted; retargeted to revision 9.** Every path, the feature graph and the migration table now use the registered value: one package, `web = ["dep:axum", "dep:tokio"]`, `metrics = ["web", "dep:metrics", "dep:metrics-exporter-prometheus"]`, tree `src/web/`. E1 compiles exactly that spelling. A translation to revision 10's form is kept under `## Parameters` for when R69 republishes |
| **F6** (fable, minor) — "matches py byte for byte" | **Accepted.** OV-07(a) option (a) now says the endpoint serves the same text exposition format under the same `text/plain` media type as py. It no longer claims identical bytes, and it does not claim py's version parameter, which was not verified |
| **F7** (fable, minor) — `scripts/research_validation.py` line citations drifted | **Accepted.** Citations now name the function and the message, not line numbers, and the self-check asserts each name is present in the file |
| **EA-1** (claude) — probe aborts under `CARGO_TARGET_DIR`; hard-coded path; `stat -c` | **Accepted.** `cargo-probes-r3.sh` passes `--target-dir "$d/target"` to every build, check and test. It reads sizes with `wc -c <`, and an unreadable size is a counted FAIL. It was run with `CARGO_TARGET_DIR` set and again with it unset |
| **EA-2** (claude) — E4's 12 did not reproduce; the join drops drifted crates silently | **Accepted.** E4 now resolves against its own snapshotted lock `locks-r3/baseB-msrv.lock` and walks its own `cargo tree` graph. It FAILs if any graph crate is missing from `cargo metadata` at the same version. The figure is restated with that scope |
| **EA-3** (claude) — binary bytes move with the toolchain; "exact" is false | **Accepted.** The bytes are reported as toolchain-bound, with `rustc -V` printed beside them. The delta is asserted within ±10% of revision 1's +378,048 B. The "exact" sentence is withdrawn. `rust-toolchain.toml` was not used: this host's `rustc` is Homebrew's, so a pin file would not select a toolchain |
| **EA-4** (claude) — `rest-conformance-r2.sh` omits revision-1 checks; digests printed, not asserted | **Accepted.** The new `decision-self-check-r3.sh` ports every revision-1 block and every revision-2 block, and asserts every revision-1 and revision-2 artifact against a literal sha256. The revision-2 sentences that claimed otherwise are withdrawn below |
| **EA-5** (claude) — `cargo-probes.log` differs beyond two header lines | **Accepted.** cargo progress lines are filtered, and the advisory-db path is redacted. Every value that moves between honest reruns sits on a line beginning `volatile:`. The reproducibility statement names that rule and was tested by two runs |
| **EA-6** (claude) — `promtool` absent; E8 skipped on rerun | **Accepted.** When no `promtool` is on PATH, `cargo-probes-r3.sh` fetches the Prometheus 3.14.0 release for the host. It verifies the tarball against the release's own `sha256sums.txt`, and on darwin-arm64 also against a literal pin. The binary is cached under `$TMPDIR` and never committed |

**Revision 2's statements about its own evidence, corrected.** Revision 2 said
`rest-conformance-r2.sh` "re-executes its whole check set" of `decision-self-check.sh`; it
did not (EA-4). It said the revision-1 digests were "pinned"; they were printed, not compared.
It said rerunning `decision-self-check.sh` against revision 2 "fails on exactly those two
checks", H1 and sha256; the sha256 is printed, not asserted. Against revision 3, that
superseded script fails on two checks: the H1 line and the raw-report count, which is now
two. `rest-conformance-r2.sh` also fails on two: its H1 check, and its OV census, which
excludes only `DECISION.md` and so now finds `OV-07` in this run's own
`review/R79-r2-snapshot.md` and `review/audit-fable.md`. No other item claims `OV-07`. Both
scripts are revision-bound by construction and stay unedited. **`review/evidence/decision-self-check-r3.sh` is the
self-check an auditor reruns for revision 3.**

**Completion note (second pass, 2026-09-27).** A machine session-usage limit interrupted the
first pass of this revision after it had revised the text through the re-verify line and
written the revision-3 probe, RustSec and rerun logs, and before it wrote
`decision-self-check-r3.sh` or brought `## Parameters`, `## Empirical check` and `## Engines`
into line with the table above. A second pass, still revision 3, completed that work:

- it wrote `decision-self-check-r3.sh` and its log (316/0/0);
- it reran `cargo-probes-r3.sh` from a `/tmp` copy with `CARGO_TARGET_DIR` unset, as
  `cargo-probes-r3.run2.log` (54/0/0);
- it rewrote those three sections to cite the revision-3 logs and to carry the F2, F5 and EA
  dispositions the table records;
- it verified every file-and-line citation and every cited count against its source.

The citations it corrected are these:

- R77's two lines are cited at the committed revision 3.
- The OV reservation list now follows the ledger's correction at `:1074`.
- The owner reference's metrics clause is quoted without added bold.
- Both superseded self-checks are stated to fail on two checks each.

The recommendation is unchanged except as this revision note already states.

**What is not this synthesis's to do, recorded for the controller.**

- **Prompt Context sentence.** `research/topics/79-prometheus-metrics/prompts/prometheus-metrics.prompt.md`
  says py exposes metrics "unconditionally (on by default, no env gate)". py's
  `settings.py:64` and `app.py:148` contradict it. R77, R78 and later consumers should not
  inherit it.
- **Muse leg registration.** `raw/muse.md` (sha256
  `15529e48b13cf58728a187a459183276240ad79074530e818972af31f056c378`) is on disk and
  untracked. `manifest.json` still records its operation `d4a2338f77114baba83a7670688fe894`
  as `submitting`. This decision adjudicates the file's bytes; the runner must collect and
  hash-pin it before acceptance.
- **R69 revision 10 publication**, which re-opens the paths in this decision (re-verify
  trigger 1).
- **`BASELINE-REVIEW: F326`**, which asks the controller to adjudicate with R69.
- **OV-07 numbering**, still open from revision 2 (re-verify trigger 14).

**Engine-substitution authority and input freshness.** The prompt's `- engines:` line reads
`muse, opus`. `research/EXECUTION.json` `engine_overrides.R79` is `["muse", "opus"]`.
`manifest.json` records the 2026-09-21 migration from `codex` under "owner decision Q5.A".
`research/RUNBOOK.md` §2 is the live paragraph carrying the substitution. It names R79 in
the Q5.A bulk set and records Q9.B, which retired Codex from P02. It also records **Q17.A**
(2026-09-27), the live owner override that extended the same substitution to a later research
wave. **Q17.A's list does not include R79**; it is cited here as the current statement of the
policy, and the authority for this item is Q5.A. `inputs/prompt.md` and the live prompt have
the same sha256, `206b3fad2f7d73ad28ac0a48244b38bbef390b427851f6025e144af1fbe827de`, which
is also `manifest.json`'s `input_hashes.prompt`. Both files are uncommitted working-tree state,
refreshed by the controller; this synthesis edited no input.

**What revision 2 did (context, kept).** Revision 2 is a **pre-audit revision** occasioned by owner
ruling **W2-REST** of 2026-09-18 (`docs/port/OWNER-REVIEW.md:187`, heading "2026-09-18 — the
REST API Design Standard binds the HTTP surface (W2-REST)"), which was made after revision 1
(sha256 `2e804161b9fbe65c7d33be04de5e024612ce628e1ea914c4e636443e0f0885c3`) was written. The
ruling holds that the organisation's REST API Design Standard v2.0.0 —
`/Users/stevemorin/c/rest-standards/rest-api-standard.md`, commit
`0850d43e45d919ef5e37f7174c4212b46013c49f`, file blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`
— governs this template's optional HTTP surface the way the CLI Design Standard governs its
CLI, and that every departure is recorded as an `OVERRIDE (OV-nn)` in the shape of the
standard's own §1.9 deviation note.

In revision 2, **the crate pair, the version pins, the feature graph, the metric names, the
label set, the architecture comparison, the gate answers, every ledger and reference-row
disposition and all four `- assumes` lines did not move.** What moved was the `/metrics`
endpoint's HTTP behaviour: revision 2 added three requirements the standard imposes and
recorded two departures it cannot meet. Moving the recommendation is allowed here and is stated plainly rather than deferred —
this decision has not been accepted, so a conformance repair lands in the recommendation
itself rather than as a follow-on.

**Note on the ruling's own enumeration.** W2-REST names "Every web item (R70 R72 R73 R74 R76
R77 R80 and the later R71 R83 R84)" at `docs/port/OWNER-REVIEW.md:198`. **R79 is not in that
list**, yet R79 registers an HTTP route on exactly the surface the ruling binds. This revision
treats the omission as an enumeration gap rather than an exemption, on the ground the ruling
itself states — the standard "governs this template's optional HTTP surface" — and because
§1.8 of the standard refuses to let a missing declaration act as an exemption. The controller
may wish to correct the enumeration; nothing in this decision depends on that correction.

There is no `## Supersedes` because no revision of this decision has been published.

## Decision

**Adopt `metrics` `0.24.6` (range `^0.24.6`) as the instrumentation facade and
`metrics-exporter-prometheus` `0.18.3` (range `^0.18.3`, `default-features = false`) as the
recorder and Prometheus text renderer, declared as optional dependencies of the package that
hosts the binary targets and enabled by R69's registered feature
`metrics = ["web", "dep:metrics", "dep:metrics-exporter-prometheus"]`, with the RED middleware
(about forty lines of `axum::middleware::from_fn`) and the `/metrics` handler written in the
template itself rather than taken from a framework-specific middleware crate. At runtime,
collection and the `/metrics` route are on unless R77's `RSLBP_WEB_METRICS_ENABLED` is set
false, which is py's `metrics_enabled` switch under this template's prefix.**

This is a **proposal validated in the implementation phase** (owner ruling, 2026-09-10). It
records what the research found and what it recommends; P03 builds the template and its CI
proves the recommendation. `## Engines` lists what P03 must validate. A recommendation that
does not survive implementation is revised against this recorded research, not researched
again from scratch.

**Ledger rows settled.** **F326** — `docs/port/COMMONALITY.md:330`, verbatim:

> `| F326 | Prometheus RED metrics exposed at /metrics, on by default | web-service | py-only | DIVERGENT | R79 | standalone; whether Rust adopts a metrics crate/exporter (e.g. \`metrics\` + \`metrics-exporter-prometheus\`) for RED metrics at \`/metrics\` |`

F326 is settled in part. The template adopts a metrics crate and exporter and exposes RED
series at `/metrics`. At runtime they are on by default, with an environment off switch
exactly as py has one. **At the packaging level they are not on by default within the web
surface**, and this item cannot fix that, because the packaging is R69's owned value. The
prompt requires that challenge to be reported, not settled by README wording:

`BASELINE-REVIEW: F326 — RED metrics at /metrics are on by default wherever the web service is built (py ships prometheus-fastapi-instrumentator inside its web extra, pyproject.toml:62 at pin b08bccfb, and gates it only by the default-true metrics_enabled at settings.py:64 and app.py:148) — under R69's registered web-extra-surface value, metrics = ["web", ...] is a separate opt-in above web, so --features web serves no /metrics; proposed change: a coupling request to R69 that its web feature enable metrics (web = ["dep:axum", "dep:tokio", "dep:metrics", "dep:metrics-exporter-prometheus"], or an equivalent that keeps the metrics feature name as an alias), leaving RSLBP_WEB_METRICS_ENABLED as the operator's off switch — evidence: review/evidence/cargo-probes-r3.log check F3 (--features web answers 404 at /metrics), and the measured cost of the change, +28 runtime crates and about +0.38 to +0.39 MB stripped, toolchain-bound (check E3); affected items R69 (owner of the value), R11 (CI feature selector), R77 (the switch), R51 (container build features)`

Until the controller adjudicates it with R69, this decision designs against the registered
value, and nothing below depends on the outcome: if R69 accepts, one feature list changes.
No `CONFLICT:` line is raised, because R79 consumes no parameter; web-extra-surface is a
research prerequisite here, not a consumed value. F303 (no web service in ts) and F320 (probe
exclusion from *access-log* volume, R75's) are named as context, not settled here.

**The metric surface, in full.**

| Series | Type | Labels | Which of RED it carries |
|---|---|---|---|
| `http_server_request_duration_seconds` | histogram, explicit buckets `[0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10]` | `http_request_method`, `http_route`, `http_response_status_code` | all three: `_count` is the rate, the status-code label is the error split, the buckets are the duration |
| `http_server_unmatched_requests_total` | counter | none | 404 volume at cardinality 1, kept out of the route-labelled space on purpose |

**Two instruments, not three, and the reason is the Prometheus project's own cardinality
rule.** py emits a separate `http_requests_total` counter alongside its duration histogram. A
Prometheus histogram already publishes `_count` at the same label set, so
`rate(http_server_request_duration_seconds_count[5m])` is the R of RED and the same expression
filtered on `http_response_status_code=~"5.."` is the E. Emitting a redundant counter doubles
the series count for no query that cannot already be written. This is a deliberate reduction
against the source, argued on the naming guide's own ground rather than on preference.

**Metric names follow the OpenTelemetry HTTP semantic conventions, not py's library
defaults — a position this synthesis takes rather than a hedge it relays.** The Opus report
recorded this as its one medium-confidence recommendation and named the alternative (py's
`http_requests_total` / `http_request_duration_seconds` with labels `handler`/`method`/`status`).
The decision is to adopt the semconv names, for one reason: the agreement level F326 requires
is *capability plus policy*, not metric name, and semconv is a versioned cross-language
standard that R78's spans will carry anyway, whereas py's names are one Python library's
defaults with no shipped dashboard to break. `http.server.request.duration` is marked
**Stable** in the conventions, with unit `s`, `http.request.method` Required,
`http.response.status_code` and `http.route` Conditionally Required, and the dotted-to-underscore
mapping used above is the one a Prometheus OTLP receiver performs itself
(`https://opentelemetry.io/docs/specs/semconv/http/http-metrics/`, retrieved 2026-09-18). One
paragraph of README and a note for the follow-on py/ts harmonisation project is the whole cost.

**What the `metrics` feature actually adds to the web build, measured.** Twenty-eight runtime
crates, named in full in `review/evidence/cargo-probes-r3.log`: `metrics`,
`metrics-exporter-prometheus`, `metrics-util`, `quanta`, `evmap`, `left-right`, `hashbag`,
`sketches-ddsketch`, `indexmap`, two `hashbrown` majors (0.16.1 and 0.17.1), `foldhash`,
`equivalent`, `rapidhash`, `crossbeam-epoch`, `crossbeam-utils`, `thiserror` and
`thiserror-impl`, `rand`, `rand_chacha`, `rand_core`, `rand_xoshiro`, `ppv-lite86`,
`getrandom`, `zerocopy`, `base64`, `cfg-if` and `rustversion`. **`tower` is already in the
runtime graph through `axum` and is not added by this feature; `tower-http` does not join the
runtime graph at all**, and the recommendation needs no direct `tower` manifest entry, because
`axum::middleware::from_fn` is axum's own re-export and the probe compiled with `tower` present
only as a `[dev-dependencies]` entry (checks E1, E3). That matters because R69 records `tower`
0.5.3 as a dev-dependency *not gated by the feature*, and hands `tower-http` to
R75; the ranked runner-up would break both, adding `tower-http` 0.7.1 to the runtime graph
(check: runner-up footprint).

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**

*Requirement (principle).* A service built from this template publishes, with no configuration
step, a scrape-able RED time series for every request it handles, unless an operator
explicitly switches collection off, keyed by a **route template**
rather than a request URI, and the endpoint that publishes those series neither measures itself
nor appears in the service's public API contract.

*Source.* Ledger row **F326** (`docs/port/COMMONALITY.md:330`), origin `py-only`, verdict
`DIVERGENT`, item R79. The py evidence was re-read at its pin
(`git -C ~/c/py-launch-blueprint show b08bccfb55d05f15e46a83b52c5660b1881d19f5:src/py_launch_blueprint/web/telemetry.py`,
2026-09-18), lines 46–48:

```python
    Instrumentator(
        excluded_handlers=["/metrics", "/healthz", "/readyz"],
    ).instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)
```

The same pin also gates that call. Revision 2 missed this, and it is the ground of this
revision's posture change (`settings.py` lines 38, 44 and 63–64; `app.py` lines 148–149):

```python
ENV_PREFIX: str = f"{APP_NAME.upper()}_WEB_"
    model_config = SettingsConfigDict(env_prefix=ENV_PREFIX, extra="ignore")
    #: Expose Prometheus RED metrics at /metrics (WEB-11).
    metrics_enabled: bool = True

    if settings.metrics_enabled:
        instrument_metrics(app)
```

`APP_NAME` is `"plbp"` (`src/py_launch_blueprint/core/paths.py:58` at the pin), so py's switch
is `PLBP_WEB_METRICS_ENABLED`, default true. py is therefore **on by default, with an
environment off switch**. The ledger row says only "on by default". The phrase "no env gate"
comes from the prompt's Context sentence, which is wrong at these lines.

Two further facts the ledger row's one-line summary does not carry, both confirmed at the pin
and both load-bearing here. First, the exclusion set is **three paths, not one** — `/metrics`,
`/healthz` and `/readyz` — so R80's probe routes are inside this item's exclusion story, which
is stated below as a requirement handed to R80 rather than decided for it. Second,
`prometheus-fastapi-instrumentator>=7.0.0` ships in py's **`web` extra**, not in a separate
one (`pyproject.toml:62` at the same pin, under `[project.optional-dependencies]` `web` at
`:56`), while the heavier OpenTelemetry dependencies sit in a separate `otel` extra at `:64`.
ts has no web service at all (F303, `docs/port/COMMONALITY.md:307`), so `TS_PORT_DECISIONS.md`
has nothing to say.

*Agreement level.* **Capability plus policy** — not library, and not metric name.

| Must agree across py, ts and rs | May justifiably vary per ecosystem |
|---|---|
| the endpoint path `/metrics` | the crate or package that provides it |
| the three RED quantities | the metric **names** and label keys |
| on-by-default posture: collection and `/metrics` are on with no configuration step | whether a redundant request counter accompanies the histogram |
| an operator off switch, defaulting to on (`PLBP_WEB_METRICS_ENABLED` in py, `RSLBP_WEB_METRICS_ENABLED` here) | the name of that switch, which follows each repository's prefix |
| the metrics endpoint is excluded from its own measurements | the packaging unit the capability travels in (a Python extra, a Cargo feature) |
| the metrics endpoint is excluded from the generated OpenAPI schema | the exclusion *mechanism* (a handler list, or structural placement) |
| bounded label cardinality | the bucket boundaries, where a standard does not fix them |

**Observable acceptance criteria.** Each is asserted by the executed check recorded under
`## Empirical check`, not proposed:

1. A successful request to a templated route produces a duration-histogram series whose route
   label is the **template** (`/v1/projects/{id}`), never the URI.
2. A failing request produces a series carrying its status code (`500`).
3. Buckets, `_sum` and `_count` are all present, and `_count` is the rate signal.
4. 51 requests across 50 distinct path-parameter values produce exactly **one** route label
   value for that route.
5. Two scrapes of `/metrics` produce **no** series labelled with `/metrics`.
6. A request matching no route produces no route-labelled series at all, and increments the
   label-free unmatched counter instead.
7. The exposition text parses under the Prometheus project's own parser
   (`promtool check metrics`), not merely under `String::contains`.
8. `GET /metrics` answers `200` with `Cache-Control: private, no-cache` and
   `Content-Type: text/plain; version=0.0.4; charset=utf-8`, whatever the `Accept` header says.
9. `GET /metrics` with a `stream` query parameter, with any value or none, answers `400`.
10. With the setting `metrics_enabled` false, `/metrics` answers `404`, business routes still
    serve, and no global recorder is installed.

**Architecture alternatives, compared before any library was picked.**

| # | Architecture | How RED is collected | How exposition happens | Verdict for this template |
|---|---|---|---|---|
| A | Framework middleware crate (`axum-prometheus`) | a `tower::Layer` the crate owns | the crate returns a `PrometheusHandle`; you route it | Viable; the **ranked runner-up**. Buys an in-flight gauge, a body-size histogram and a declarative ignore list; costs `tower-http` 0.7.1 in the runtime graph ahead of R75, a per-axum-major upgrade treadmill under one maintainer, and a panic on a second layer construction |
| B | **Framework-neutral facade + recorder + about forty lines of middleware the template owns** (`metrics` + `metrics-exporter-prometheus`) | `axum::middleware::from_fn` in the template's own source | `handle.render()` inside an ordinary axum handler | **Recommended.** The framework maintainers' own example shape, and the template owns the code that decides its label set |
| C | Registry-object client (`prometheus`, `prometheus-client`) | build and thread `HistogramVec` / `Family` handles through `AppState` | `TextEncoder` / `encode` into a `String` | Architecturally clean — typed labels, no process-global state — but pushes an observability object into R01's composition root, where today only the erased `ProjectsService` lives; and `prometheus-client` fails gate 2 |
| D | OpenTelemetry metrics pipeline (`opentelemetry` + `opentelemetry_sdk` + `opentelemetry-prometheus`) | OTel `Meter` instruments | a `prometheus::Registry` bridged out | **Rejected on the maintainers' own advice**, and because it would make a default-on surface structurally depend on the crate set R69 deliberately nested behind the *optional* `otel` feature |

**Why architecture B, stated as principle rather than preference.** The facade split is the
architecture the Rust ecosystem already settled on for diagnostics: `log` and `tracing` are
facades, and the subscriber is chosen at the binary. Three consequences fall out that this
template specifically needs.

1. **The core library can be instrumented without paying for an exporter.** `metrics`' macros
   compile to a no-op when no recorder is installed, and recording a value requires no async
   runtime — which is what R05 revision 3's synchronous core requires ("Adopt a synchronous,
   blocking execution model for the library crate and the CLI binary, and confine async to
   R69's optional `web` feature"). Nothing in this design asks `crates/core` to hold a
   registry, so R02 revision 2's core external-dependency allow-list is untouched.
2. **The template owns its label set.** Cardinality is the one failure mode that turns a
   metrics endpoint into an outage, and the Prometheus project's own guidance — "Do not use
   labels to store dimensions with high cardinality" and "try to keep the cardinality of your
   metrics below 10" (`https://prometheus.io/docs/practices/naming/` and
   `.../instrumentation/`, retrieved 2026-09-18) — is a rule about *your* labels. A middleware
   crate that decides them for you is a crate you must audit anyway.
3. **Recorder and exposition are replaceable independently.** Swapping
   `metrics-exporter-prometheus` for `metrics-exporter-otel` later changes one function, not
   every call site — which is the seam that lets R78 and R79 converge without touching
   instrumentation.

**Why not D, in the maintainers' own words.** `opentelemetry-prometheus` 0.33.0's own
`README.md` steers new projects to `opentelemetry-otlp` instead (re-read from the published
tarball, sha256 recorded in `review/evidence/crate-sources.log`, 2026-09-18), and its
`Cargo.toml.orig` declares `prometheus = { version = "0.14", default-features = false }` — so
choosing D means adopting architecture C transitively and carrying two client libraries in one
graph. This settles the R78 coordination question cleanly: **R78 exports traces over OTLP
behind the optional `otel` feature; R79 exposes metrics by native Prometheus scrape; the
template ships no OTel-metrics-to-Prometheus bridge.** Coherence with R78 is bought with a
shared vocabulary — the semconv names above — rather than with a shared library.

**The exclusion of `/metrics` from its own measurements is structural here, not configured,
and this is the sharpest difference between the two viable candidates.** Both directions were
re-read at source.

- With the recommended design, `/metrics` is registered on a router **merged after**
  `route_layer` has been applied, so the middleware is not in its service stack at all. There
  is no ignore list to keep in sync and no way to forget it: registering the route inside the
  instrumented group would be a visible code change. The executed check asserts
  `!body.contains("http_route=\"/metrics\"")` after two scrapes, and passes.
- `axum-prometheus` does **not** exclude `/metrics` out of the box. Its own crate
  documentation shows the opposite: the sample scrape at `src/lib.rs:73` reads
  `axum_http_requests_total{method="GET",endpoint="/metrics",status="200"} 5`, and
  `:74`–`:88` carry the pending gauge and the whole duration histogram for `/metrics` as well.
  Exclusion is available but is an explicit call —
  `MetricLayerBuilder::with_ignore_pattern` at `src/builder.rs:89`, or `with_ignore_patterns`
  at `:114` for the probe paths too.

So the direct answer to the prompt's fourth HIGH question is: **neither candidate excludes it
"for free" in py's sense. The recommended design excludes it by construction; the runner-up
excludes it by a hand-written pattern list — which is, note, the closest thing in the field to
py's `excluded_handlers`.**

**Bounded cardinality is enforced by `MatchedPath`, and by refusing the fallback.** axum
inserts `MatchedPath` into request extensions when a route matches, and `route_layer`
middleware runs after matching, so the extension is present. The conventions say `http.route`
"MUST NOT be populated when this is not supported by the HTTP server framework"; for an
unmatched request there *is* no template, and substituting `req.uri().path()` — which axum's
own example does, and which `axum-prometheus`'s default `EndpointLabel::MatchedPath` also does
as a fallback (`src/builder.rs:28`, "first trying to extract and return
`axum::extract::MatchedPath`") — is exactly the unbounded-label mistake the naming guide warns
about: a scanner spraying random paths mints a new series per path, permanently. The
recommended design therefore records **no route-labelled series** for an unmatched request and
increments the label-free `http_server_unmatched_requests_total` instead.

**The maintenance contract that silently breaks if ignored — upkeep — and a real defect in the
otherwise-authoritative reference.** The exporter's own `src/lib.rs:108`–`:110` states that
when the lower-level `PrometheusBuilder::build_recorder` or `install_recorder` is used, the
upkeep task "is _not_ spawned" automatically and the caller must hold a `PrometheusHandle` and
call `run_upkeep` at a regular interval. Upkeep drains histogram buckets; without it memory
grows with distinct observations. `install()` and `build()`, which *do* spawn it, sit behind a
real multi-line compilation gate `#[cfg(any(feature = "http-listener", feature =
"push-gateway", feature = "push-gateway-no-tls-provider"))]` at `src/exporter/builder.rs:443`
and `:531` — exactly the heavyweight features this template turns off. `install_recorder`
(`:506`) and `build_recorder` (`:605`) carry no such gate and are available with
`default-features = false`; that was verified by walking the attribute block above each
declaration, not by a line regex. Consequence: **axum's own worked example calls
`install_recorder()` and never runs upkeep** — `run_upkeep` does not appear anywhere in
`examples/prometheus-metrics/src/main.rs` at tag `axum-v0.8.9`. The template must spawn the
upkeep ticker next to the server, at the exporter's own 5-second default
(`let upkeep_timeout = Duration::from_secs(5);`, `src/exporter/builder.rs:88`).
`axum-prometheus` gets this right (`src/lib.rs:889`), which is a genuine point in the
runner-up's favour and the reason the recommended design copies that loop rather than copying
axum's example verbatim.

**The minimal realistic example.** One new module, `src/web/obs/metrics.rs`, about 110 lines.
It is reproduced below **byte for byte** from `review/evidence/r3-obs-metrics.rs`, the file
`cargo-probes-r3.sh` copies into the probe package, compiles and tests. The self-check asserts
the two are identical, so the code shown is the code that ran. `OnceLock` is not decoration:
`metrics::set_global_recorder` succeeds once per process and `install_recorder()` returns `Err`
on a second call, so building the router in two `#[tokio::test]` functions in one
integration-test binary would otherwise panic. That is also why the design does not copy
`axum-prometheus`'s `Handle::default()`, whose
`metrics::set_global_recorder(recorder).expect("Failed to set global recorder")`
(`src/lib.rs:892`) is unconditional.

```rust
// src/web/obs/metrics.rs -- compiled only with the `metrics` feature (R69 revision 9 tree).
use axum::{
    Router,
    extract::{MatchedPath, RawQuery, Request},
    http::{StatusCode, header},
    middleware::{self, Next},
    response::{IntoResponse, Response},
    routing::get,
};
use metrics_exporter_prometheus::{Matcher, PrometheusBuilder, PrometheusHandle};
use std::{
    sync::OnceLock,
    time::{Duration, Instant},
};

pub const DURATION: &str = "http_server_request_duration_seconds";
pub const UNMATCHED: &str = "http_server_unmatched_requests_total";
pub const BUCKETS: &[f64] = &[
    0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 7.5, 10.0,
];
// R7.1 (:1259) and R7.3 tier 1 (:1281): a mutable resource states its caching posture.
const CACHE_CONTROL: &str = "private, no-cache";
// OV-07(a): the Prometheus text exposition format, whatever the Accept header says.
const EXPOSITION: &str = "text/plain; version=0.0.4; charset=utf-8";

static HANDLE: OnceLock<PrometheusHandle> = OnceLock::new();

pub fn recorder() -> &'static PrometheusHandle {
    HANDLE.get_or_init(|| {
        let handle = PrometheusBuilder::new()
            .set_buckets_for_metric(Matcher::Full(DURATION.to_string()), BUCKETS)
            .expect("bucket list is non-empty")
            .install_recorder()
            .expect("no other global recorder is installed");
        metrics::describe_histogram!(
            DURATION,
            metrics::Unit::Seconds,
            "Duration of HTTP server requests."
        );
        metrics::describe_counter!(UNMATCHED, "HTTP requests that matched no route template.");
        handle
    })
}

pub async fn run_upkeep(handle: &'static PrometheusHandle) {
    let mut ticker = tokio::time::interval(Duration::from_secs(5));
    loop {
        ticker.tick().await;
        handle.run_upkeep();
    }
}

async fn track(req: Request, next: Next) -> Response {
    let start = Instant::now();
    let method = req.method().as_str().to_owned();
    let route = req
        .extensions()
        .get::<MatchedPath>()
        .map(|p| p.as_str().to_owned());
    let response = next.run(req).await;
    let status = response.status().as_u16().to_string();
    if let Some(route) = route {
        metrics::histogram!(
            DURATION,
            "http_request_method" => method,
            "http_route" => route,
            "http_response_status_code" => status,
        )
        .record(start.elapsed().as_secs_f64());
    }
    response
}

pub fn count_unmatched() {
    metrics::counter!(UNMATCHED).increment(1);
}

// R13.3 (:1935): `stream` with any value, or none, is a 400 on an endpoint that does not stream.
fn asks_to_stream(query: Option<&str>) -> bool {
    query.is_some_and(|q| {
        q.split('&')
            .any(|pair| pair == "stream" || pair.starts_with("stream="))
    })
}

async fn scrape(RawQuery(query): RawQuery) -> Response {
    if asks_to_stream(query.as_deref()) {
        return (StatusCode::BAD_REQUEST, [(header::CACHE_CONTROL, CACHE_CONTROL)]).into_response();
    }
    (
        [
            (header::CACHE_CONTROL, CACHE_CONTROL),
            (header::CONTENT_TYPE, EXPOSITION),
        ],
        recorder().render(),
    )
        .into_response()
}

pub fn instrument(business: Router) -> Router {
    recorder();
    business
        .route_layer(middleware::from_fn(track))
        .merge(Router::new().route("/metrics", get(scrape)))
}
```

The composition root applies it only when R77's setting is on. This is the probe's
`build_router`, with `metrics_enabled` standing for R77's `WebSettings::metrics_enabled`:

```rust
#[cfg(feature = "metrics")]
let business = if metrics_enabled {
    obs::metrics::instrument(business)
} else {
    business
};
```

**Feature graph, spelled out against R69's registered revision 9.**

```toml
# Cargo.toml (the package that hosts the binary targets, per R69 revision 9)
[dependencies]
metrics = { version = "0.24.6", optional = true }
metrics-exporter-prometheus = { version = "0.18.3", optional = true, default-features = false }

[features]
web     = ["dep:axum", "dep:tokio"]
metrics = ["web", "dep:metrics", "dep:metrics-exporter-prometheus"]
```

A Cargo feature named `metrics` coexisting with an optional dependency named `metrics` looks
illegal and is not: naming `dep:metrics` anywhere in `[features]` suppresses the implicit
same-named feature. That was compiled, not assumed: check E1 in `cargo-probes-r3.log` compiles
exactly this `[features]` table, with `--features metrics`, `--features web` and no feature.
That keeps this design on R69's recorded `metrics = ["web", …]` spelling instead of defensively
renaming the feature.

**`default-features = false` is the single highest-value line in the recommendation, and the
cost of omitting it is measured.** The exporter's defaults are
`default = ["http-listener", "push-gateway"]` (`Cargo.toml.orig:19`, 0.18.3), which pull an
HTTP server, an HTTP client, TLS and a crypto provider. On a minimal two-crate base the
resolved normal graph is **37 crates with `default-features = false` and 81 with the defaults
on** — 44 added, including `aws-lc-rs`, `aws-lc-sys` (a C and assembly build), `rustls`,
`rustls-native-certs`, `rustls-webpki`, `hyper`, `hyper-rustls`, `hyper-util`, `h2`,
`tokio-rustls`, `security-framework` and `ipnet`. None of it is used: the template renders into
its own axum route and opens no second port. Both reth and `axum-prometheus` independently
reached the same `default-features = false` conclusion.

**Answering the two MEDIUM questions directly.**

*On-by-default posture.* At the **runtime** level, yes. The recorder is installed and the
`/metrics` route registered during startup with no configuration step. Nothing about the
candidate fights it: `install_recorder` and `render` need no feature and no listener. **The
template also carries py's off switch.** R77 revision 3 names `RSLBP_WEB_METRICS_ENABLED` as a
rename of py's field and defers its semantics to this item (R77's decision at
`research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md:663`, and its table row
"`METRICS_ENABLED` | not decided | R79" at `:684`, both as committed at `1e3cdb5b`. R77's uncommitted revision 4 in the working tree
carries the same two lines at other line numbers, which move while that revision is edited; the
self-check prints them as volatile). **The semantics, decided here:** the value is
a boolean, default `true`, parsed by R77's mechanism. When it is `true`, `build_router` applies
`obs::metrics::instrument`. When it is `false`, `build_router` does not call it: no RED layer,
no `/metrics` route (a scrape answers `404`), and no global recorder. The unmatched counter's
call in the fallback is then a no-op, because the `metrics` facade records nothing without a
recorder. That mirrors py's `if settings.metrics_enabled: instrument_metrics(app)` exactly, and
check F1 executes it. The switch does not weaken F326: "on by default" is about the default,
and the default is on. It stays deliberately unlike R74's opt-in rate limiting, whose default
is off.

At the **packaging** level the answer is no, and this is the `BASELINE-REVIEW: F326` raised
under `## Decision`. py ships the instrumentator *inside* the `web` extra, so a py user
installing `[web]` gets metrics. Under R69's registered value, an rs user enabling only
`--features web` does not: check F3 answers `404` at `/metrics`. That value is R69's to change,
not this item's. This decision does not propose `default = ["metrics"]`, which would widen R69's
`web` feature by the back door. Until the controller rules, P03 documents the gap: the README's
web quickstart shows `--features metrics` (or `--all-features`).

*OpenAPI exclusion.* Automatic, on one stated condition. R71 owns the generation pipeline;
every Rust OpenAPI generator in that space derives the document from annotated handler or route
registrations (a `utoipa`-style `#[utoipa::path]` plus `OpenApiRouter`, or an `aide`-style typed
route method). `/metrics` here is registered with plain `axum::routing::get` on a plain
`Router`, with no annotation and no typed registration, so there is nothing for the generator to
pick up — the py analogue of `include_in_schema=False` is "never in the schema's input set"
rather than "removed from its output". The condition is that R71 must not adopt a generator
that enumerates a live `axum::Router`'s route table; if it does, the route needs an explicit
exclusion and this paragraph must be revisited. The requirement handed to R71 is one sentence:
**the metrics route must be excludable from the generated document, and is excluded today by
being registered outside the annotated path.**

**Owner reference architecture — the C10 rows, re-checked at source.** Only the C10 block
overlaps this item (`inputs/owner-reference-axum-companion-stack-2026-09-16.md`, section
"### C10 Observability on GCP" at line 110, the paragraph at line 111).

| Reference row or clause | Position | Ground |
|---|---|---|
| "Metrics: start with log-based metrics/Cloud Monitoring; add the `metrics` crate + exporter only when needed" — the *posture* half | **DIFFER** | The reference is written for a Cloud Run deployment where Cloud Monitoring is already present. This template ships no deployment target, and F326 (`docs/port/COMMONALITY.md:330`, quoted verbatim above) is an owner-recorded baseline: RED metrics at `/metrics`, on by default. Log-based metrics also cannot supply a duration **histogram** with bucket boundaries — you get counts and derived rates, not quantiles — so "start with log-based metrics" would fail the D of RED outright. The difference rests on sourced ground, not preference |
| The same clause's *crate family* half: "the `metrics` crate + exporter" | **AGREE** | When the reference does reach for metrics, it names exactly the family recommended here. Independent agreement, recorded |
| C10 table row, line 68: "Logs/traces — **tracing + tracing-subscriber (JSON)** (+ tracing-stackdriver)" | **HAND-OFF** | R58 (`logging-pipeline-contract`) owns it; unpublished, registry value `—`. Not decided here |
| C10 table row, line 69: "Error reporting — **sentry + sentry-tower**" | **HAND-OFF** | No P02 row assigns error reporting to R79. Not decided here |

Tally: **1 agree, 1 differ, 2 hand-offs** — the same disposition the Opus report reached,
re-checked line by line rather than carried.

**Couplings stated, not decided.**

- **R80 (`health-probe-endpoints`, in parallel).** py excludes `/healthz` and `/readyz` from
  measurement alongside `/metrics`, so R80's probe routes belong on the **unmeasured** side of
  `route_layer`. R80's own raw report puts them in `crates/web/src/routes/ops.rs` and merges
  them with `.merge(ops::router())` into the one shared `Router` (`raw/opus.md:1030`–`:1034`,
  `:1084`–`:1089`), rejects a second admin listener (`:166`), and explicitly takes "**No
  position**" on observability, assigning only the *access-log* exclusion to R75 and F320
  (`:357`). **No item currently owns excluding the probes from metrics measurement.** The
  requirement this item states, and which R80 or R75 must land: `route_layer` applies to the
  `/v1` nested business router; `ops::router()` and the `/metrics` route are both merged
  **after** it. R80 chooses the paths; this item owns only where they sit relative to the
  layer.
- **R77 (`web-env-settings`, in parallel).** R77 owns the name and the parsing mechanism of
  `RSLBP_WEB_METRICS_ENABLED`; this item supplies its semantics, stated above: boolean, default
  `true`, `false` skips `instrument()`. That is consistent with R77 revision 3's naming rule and
  with py. Should a later item want a knob for the scrape path or the upkeep interval, the seam
  is the two name constants and the ticker interval in `obs/metrics.rs`.
- **R58 (`logging-pipeline-architecture`, Wave 3, unpublished, registry value `—`).** The
  exporter is used without its `tracing` feature, so it emits no log lines and imposes nothing
  on the pipeline. R58's current raw material mentions neither R79 nor `/metrics`.
- **R78 (`opentelemetry-integration`).** **No run directory exists**; R78 is unresearched. The
  `otel`/`metrics` sibling relationship is asserted only by R69's owned value. This decision
  therefore fixes the interface rather than the counterpart: R79 does not emit through the OTel
  SDK, and coherence is carried by the semconv names above.
- **R75 (`http-middleware-stack`).** The metrics middleware is an ordinary `from_fn` layer and
  takes its place in R75's ordering; R75 owns excluding `/metrics` from access-log volume
  (F320), which this item does not touch.
- **R01, R02, R05.** No metrics dependency enters `crates/core`; no registry enters R01's
  composition root; nothing on the recording path needs a runtime. The one piece that does need
  the runtime is the upkeep ticker, and it lives beside the server.

**Conformance with the REST API Design Standard v2.0.0 (owner ruling W2-REST, 2026-09-18).**

Every rule below was read from the pinned blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`
(`git -C /Users/stevemorin/c/rest-standards show 71bd813c…`), quoted at its line, and asserted
by `review/evidence/rest-conformance-r2.sh` against a committed snapshot of those lines, and
again by `review/evidence/decision-self-check-r3.sh` for revision 3.

**The finding that frames every row: the standard has no vocabulary for an operational
endpoint.** Searched case-insensitively over all 3,427 lines of the blob, the words
`Prometheus`, `telemetry`, `scrape`, `exposition`, `healthz`, `readyz`, `liveness`,
`readiness`, `monitoring` and `instrumentation` are **absent**, and `metrics` appears exactly
once in a rule — R3.3 at `:599`, "**Exception:** logging and metrics side effects do not
violate safety". There is therefore no carve-out to invoke. Three facts close that door
deliberately rather than by oversight: the applicability-switch vocabulary at `:237`–`:238` is
closed to `webhooks · async-operations · bulk-operations · streaming`, and `:238`–`:239` says
it "grows only when a new rule needs a switch"; §1.2 shows what an explicit exclusion looks
like when the standard means one — WebSockets at `:99`–`:105`, "neither conformant nor
nonconformant on it" — and no such sentence exists for operational paths; and R2.1 at `:447`
ends "There is no RPC carve-out for any service class." R1.5 at `:219` adds that "Every rule in
this standard applies at every tier unless the rule itself states a tier scope", and none of
the rules below carries a tier annotation. So `/metrics` is inside the standard's reach, and
where it cannot conform the departure is written down — which is what R1.7 at `:271` requires:
"silent deviation from any rule strength is nonconformance regardless of the deviation's
merits."

| Rule | Line | Rule text, quoted | Disposition |
|---|---|---|---|
| **R1.8** | `:312` | "A conforming API MUST NOT use a reserved name for any purpose other than the meaning registered here" | **CONFORMS.** `metrics` appears in none of §1.10's six registers. The only reserved path segments are the seven action verbs at `:383`–`:387` (`cancel`, `archive`/`restore`, `approve`/`reject`, `publish`/`unpublish`, `duplicate`); `metrics` is not among them |
| **R1.9** | `:318` | "a **mutating** request carrying the `dry_run` parameter … MUST be rejected with `400`" | **N/A with reason** (the §1.8 `:232`–`:235` discipline): the guard is scoped to mutating requests and `GET /metrics` is safe. Recorded, not omitted |
| **R2.1** | `:443` | "An API MUST present a resource-oriented surface: noun resources … There is no RPC carve-out for any service class" | **CONFORMS.** `/metrics` is a noun resource read with `GET`, not an RPC method overlay |
| **R2.2** | `:456` | "Collection resources MUST use plural nouns" | **CONFORMS.** `metrics` is plural |
| **R2.4** | `:477` | "Path segments MUST use kebab-case … pattern `^[a-z][a-z\-0-9]*$`" | **CONFORMS.** Asserted by running the pattern against the literal segment in the check script |
| **R2.5** | `:487` | "a path MUST NOT reference more than three resources" | **CONFORMS.** One segment |
| **R2.6** | `:499` | "Canonical URIs have no trailing slash … a request with a trailing slash SHOULD receive `308 Permanent Redirect`" | **MOVED.** The template registers `/metrics` and never `/metrics/`; the 308 belongs to R75's stack and is handed to it as a requirement |
| **R2.9** | `:525` | "an operation modifier MUST NOT be encoded as a path segment" | **CONFORMS.** No modifier in the path |
| **R2.10** | `:533` | "Personally identifiable information MUST NOT appear in any URI" | **CONFORMS.** No PII in the path, and none in the label set either — see R8.12 |
| **R2.11**–**R2.13** | `:542`, `:562`, `:569` | the `POST /{collection}/{id}/{action}` action form | **N/A with reason.** `/metrics` is a `GET` of a representation, not a non-CRUD action |
| **R4.1** | `:742` | "Every API MUST publish an OpenAPI document as the contract source of truth" | **CONFORMS.** The obligation binds the API to publish a document — R71's — not every path to appear in it. A case-insensitive search of the blob for a per-endpoint coverage rule ("every operation", "undocumented") finds none. The residual is recorded as a re-verify trigger rather than argued away |
| **R4.3** | `:762` | "Every JSON response body MUST have an object at the top level … **Exception:** non-JSON media types" | **CONFORMS by the rule's own exception.** The Prometheus exposition body is not JSON |
| **R4.4**–**R4.9**, **R4.16** | `:768`–`:834`, `:779` | JSON body-content rules | **N/A with reason.** No JSON body and no query parameters on this endpoint |
| **R4.10** | `:846` | "The default media type — served when a request carries no `Accept` header — is `application/json`, encoded UTF-8. Media-type selection MUST use HTTP content negotiation, never a `format` query parameter. A request whose `Accept` header excludes every representation the endpoint supports SHOULD receive `406 Not Acceptable`" | **OVERRIDE (OV-07)(a)**, below. The middle clause conforms — the endpoint selects nothing by `format` — and the first and third are the departure |
| **R4.11** | `:856` | "Every response whose content was selected by a request header MUST send `Vary` … **Exception:** responses with no negotiation" | **CONFORMS by the rule's own exception**, and the exception is earned rather than assumed: the handler returns one representation unconditionally, so no request header influences selection and no `Vary` is owed |
| **R4.17** | `:864` | `Access-Control-Expose-Headers` for cross-origin browser clients | **N/A with reason.** A Prometheus server is not a browser client; CORS is R76's, and this endpoint asks nothing of it |
| **R7.1** | `:1259` | "Every response MUST carry an explicit `Cache-Control` header — stating freshness, `no-cache`, or `no-store` per the R7.3 posture — because silence is not a decision" | **MOVED.** Revision 1 set no caching header, which violates an unconditional MUST that carries no exception, no tier scope and no switch scope. The handler now sets one on every answer, the `400` included; executed in revision 3 (check F4) |
| **R7.3** | `:1281` | tier 1: "Authenticated or mutable resources default to `Cache-Control: private, no-cache`, revalidating via the strong `ETag` machinery of R3.10"; tier 2: "`no-store` is reserved for genuinely sensitive payloads. Blanket `no-store` is a named anti-pattern" | **MOVED to tier 1.** A scrape is mutable, so tier 1 applies and the header is **`Cache-Control: private, no-cache`**. `no-store` is rejected on the rule's own words: the payload is not sensitive. The `ETag` half of tier 1 does not bind, because R3.10 at `:693` scopes it to "A resource that supports conditional update" and carries "**Exception:** resources never updated by clients" — a scrape is never updated by a client |
| **R8.1** | `:1317` | "APIs MUST be served only over TLS 1.2 or higher" | **Handed on, and it binds this path like every other.** The listener is R69's and the deployment R51's; R79 adds no plaintext-only requirement |
| **R8.2** | `:1323` | "Access tokens MUST NOT be accepted or emitted in URI query parameters" | **CONFORMS.** The endpoint accepts no query parameter at all |
| **R8.6** | `:1356` | "Every request MUST be authorized against the specific object, not only the endpoint … deny-by-default, never gateway-enforced" | **OVERRIDE (OV-07)(b)**, below |
| **R8.12** | `:1422` | "Secrets, credentials, and PII MUST NOT appear in … any other response content" | **CONFORMS**, and it is the REST standard's twin of R56 revision 2's rule. The label set is `http_request_method`, `http_route` (a route template) and `http_response_status_code`; none can carry a caller value. The refusal to fall back to `req.uri().path()` is what keeps it true |
| **R11.7** | `:1752` | "Every response, including errors, MUST carry the `request-id` correlation header" | **MOVED**, and this is the correction with the most structural reach. Revision 1 said `/metrics` sits outside the middleware; that is true only of the **RED measurement layer**, which is applied with `route_layer` to the business router. R75's request-id layer must be applied with `.layer()` to the **merged** router so that it covers `/metrics` and R80's probes too. Stated as a requirement handed to R75, and as a constraint on where `instrument()` sits in `build_router` |
| **R11.8** | `:1759` | "W3C Trace Context `traceparent` MUST be propagated" | **MOVED.** Same placement argument as R11.7; the propagation mechanism is R75's and R78's, and this decision records only that `/metrics` is inside it |
| **R13.3** | `:1935` | "An endpoint that does not implement streaming and receives `stream` — as a query parameter or a request-body member, with any value — MUST reject the request with `400`" | **MOVED.** §1.8 at `:258`–`:264` singles this rule out as binding **per endpoint** whatever the API's `streaming` switch says, so `GET /metrics?stream=1` must answer `400`. A Prometheus scrape never sends it, which is precisely why it would have been forgotten. Executed in revision 3 for `?stream=1`, `?stream`, `?a=1&stream=` and `?stream=false`, with `?streaming=1` still `200` (check F4) |
| **R9.1** | `:1435` | "An API MUST use one uniform version-marker placement: the major version in the path (`/v1`), never `/v1.0`" | **CONFORMS, with the argument shown rather than assumed.** The rule constrains the *placement and form* of the version marker, not its presence on every path; a search of the blob for a universality clause ("every path") finds none, and R2.5's counting rule at `:491` treats the version segment as separate from the resource segments. The API's resources live under `/v1` and the marker never appears as `/v1.0`. This is the weakest row here and is recorded as a re-verify trigger |

**What the recommendation adds, concretely.** The `scrape` handler, the two constants it
uses and the `asks_to_stream` guard in the module shown above, plus one requirement on
`build_router`. Revision 2 showed a `scrape` that took `&'static PrometheusHandle` as a handler
parameter, which is not an axum extractor, so that handler could not be routed. Revision 3's
`scrape` takes only `RawQuery` and calls `recorder()`, and check F4 compiles, routes and tests it.
In `build_router`, the RED layer stays a `route_layer` on the business router, while R75's
cross-cutting stack is applied to the merged router. So `/metrics` is **outside the metrics
measurement layer and inside the request-id and trace layer**: two different layers that
revision 1 collapsed into one sentence. The `400` carries no body here; its problem-details
body is R70's envelope once that item publishes.

**OVERRIDE (OV-07) — R79's single allocated override, covering two independent departures.**

The controller allocated `OV-07` to R79 and allocates override numbers centrally from now on
(controller notice, 2026-09-18, issued after two syntheses collided on `OV-04` by searching
concurrently). R79 records **two** departures, and they do not share a fact: one is about the
response media type, the other about authentication. They are kept as separate arguments under
the one allocated number rather than merged into a single argument, because merging two
unrelated deviations into one would hide one of them — which is the outcome R1.7 exists to
prevent. **A decision the controller owns:** either `OV-07` carries both rows, as written here,
or R79 needs a second number. The §1.9 conformance note records deviations per rule ID in any
case, so the two rows below land in it either way; only this repository's tracking handle is at
stake. The precedent for one number carrying several rule rows is R80's `OV-04`, which covers
four MUST rules — though there a single fact created all four.

**OV-07(a) — the response media type is the Prometheus text exposition format, not
`application/json`.**

**Argument:** R4.10 at `:846` fixes `application/json` as the media type served to a request
carrying no `Accept` header, and asks for `406 Not Acceptable` when a client's `Accept`
excludes every supported representation. A Prometheus server scrapes with
`Accept: text/plain;version=0.0.4;q=0.5,*/*;q=0.1` and parses the text exposition format; a
`curl` with no `Accept` must receive the same bytes or the endpoint is useless to the tool it
exists for. The format is fixed by the Prometheus project, not by this template, and
`metrics-exporter-prometheus` 0.18.3 renders only that format — `PrometheusHandle::render`
returns a `String` of it, with no JSON path to select. Conformance was attempted first, as
Appendix B `:2799` requires: serving JSON by default and the exposition format only on an
explicit `Accept` would mean every scrape works and every human `curl` silently gets a
different document, which trades a tool-facing break for a human-facing one and satisfies no
reader. The standard already records the identical structural hole for the analogous case, at
`:2218`: a no-`Accept` request to an always-streaming resource "cannot produce" JSON, and
"R4.10's default clause carries no BCP 14 keyword, so this is a taxonomy hole rather than a
live conflict." That release is granted explicitly to streaming resources by R13.2 and not to
this one, so it is cited as the standard's own acknowledgement of the shape of the problem,
not as an exemption this endpoint may borrow. **Strengths, stated exactly:** the default-media-type
clause carries no BCP 14 keyword and so is not a MUST; the `406` clause is a **SHOULD**. This
override therefore records one SHOULD-strength deviation plus a position on a keyword-less
clause, not a MUST violation.

**Options:**
- **(a) Serve the exposition format unconditionally — recommended, and taken.** `/metrics`
  answers `200` with `Content-Type: text/plain; version=0.0.4; charset=utf-8` whatever the
  `Accept` header says, and never `406`. Cost: the two R4.10 clauses above. Benefit: the
  endpoint works with every Prometheus server and every `curl`, and serves the same text
  exposition format under the same `text/plain` media type as py. The bytes differ from py's,
  because the metric names differ by design, and py's exact `version` parameter depends on its
  installed `prometheus_client` and was not verified. Check F4 executes this option for no
  `Accept`, `Accept: application/json` and a Prometheus server's `Accept`.
- **(b) Negotiate: JSON by default, exposition format on an explicit `Accept`.** Conforms to
  R4.10 literally. Cost: a `curl /metrics` returns a JSON document no Prometheus tool reads,
  the template must invent and maintain a JSON rendering of a histogram the exporter does not
  produce, and R4.11's `Vary: Accept` becomes owed. Rejected: it manufactures a second
  representation to satisfy a default nobody requests.
- **(c) Move the endpoint off the API surface onto a second port,** which R80 evaluated and
  rejected as its alternative D. Cost: a second bound listener, a second address in R77's
  settings, a second row in R51's container contract, and it does not actually make the
  standard stop applying — it relocates the same bytes. Rejected.

*Recorded in §1.9 template form for the template's conformance note:*
`- R4.10 · SHOULD (the 406 clause; the default-media-type clause carries no BCP 14 keyword) · /metrics serves text/plain; version=0.0.4 for every Accept and never 406 · the Prometheus exposition format is fixed by the Prometheus project and is the endpoint's whole purpose · approver: owner (pending) · date: 2026-09-18 · review: at the next major version of the template's HTTP surface`

**OV-07(b) — `/metrics` is unauthenticated.**

**Argument:** R8.6 at `:1356` requires that "Every request MUST be authorized against the
specific object, not only the endpoint", centralized and deny-by-default. An unauthenticated
scrape endpoint has no principal for that decision to run against. The standard grants no
exception: a case-insensitive search of the blob for `anonymous` and `public endpoint` returns
nothing, and the four occurrences of `unauthenticated` are a rate-limit axis row at `:1397`
that prices unauthenticated traffic without permitting or forbidding it. Against that, F326 is
an owner-recorded baseline — RED metrics at `/metrics`, on by default, with no configuration
step — and py's instrumentator is unauthenticated at the pin. The off switch adopted in
revision 3 does not change this: it can only turn the endpoint off, never add a credential. Requiring a credential would
make the endpoint unusable without one, which is a configuration step, which is what F326
forbids. Conformance was attempted first: an API-key gate under R8.3 was considered and
rejected because the template ships no deployment target and therefore no key issuer, so the
gate would have to ship disabled — a rule satisfied in text and not in fact, which R1.7 treats
as worse than a recorded deviation. **Strength: MUST.** Under R1.7 at `:273` this makes the
surface nonconformant unless recorded, and Appendix B `:2803`–`:2806` routes a
requirement-strength deviation to the standard's owner. It is recorded here and flagged for
that approval; R79 does not grant itself the exception.

**Options:**
- **(a) Unauthenticated `/metrics`, on by default — recommended, and taken.** Cost: R8.6, at
  MUST strength, pending the owner's approval. Benefit: F326 is met exactly; the scrape works
  with a stock Prometheus server; py and rs behave identically. Mitigation the template can
  carry without a configuration step: the exposition carries no secrets by construction
  (R8.12, R56), and the served bind address is loopback by default under R77's proposed
  `RSLBP_WEB_HOST` default of `127.0.0.1`, so a container must opt into `0.0.0.0` before the
  endpoint is reachable off-host.
- **(b) Require an API key on `/metrics`.** Conforms to R8.6. Cost: the endpoint is off until
  configured, contradicting F326's "no configuration step"; the template ships no key issuer,
  so the shipped default would be a disabled gate. Rejected.
- **(c) Bind `/metrics` to a separate loopback-only listener.** Reduces exposure without a
  credential, but still has no principal, so R8.6 is equally unmet — and it costs the second
  port R80 already rejected. Rejected as not addressing the rule it appears to address.

*Recorded in §1.9 template form:*
`- R8.6 · MUST · /metrics is served without authentication or authorization · F326 requires RED metrics on by default with no configuration step, and the template ships no credential issuer; the payload carries no secrets (R8.12) and the default bind address is loopback · approver: standard owner (required by Appendix B step 3, pending) · date: 2026-09-18 · review: at the next major version of the template's HTTP surface`

**The override number is the controller's allocation, and this synthesis's own search was
wrong — both facts recorded rather than the second quietly dropped.**

Override numbers are allocated centrally as of 2026-09-18. `docs/planning/p02/execution-ledger.md:1073`
records why and what: "R77 revision 2 (`d36492b`) and R80 revision 2 (`ce291fe`) both allocated
OV-04 by concurrent 'next free number' searches. Resolution: OV numbers are allocated by the
controller from now on." The same line carries the allocation table, and R79's entry in it is
**`OV-07`**, reserved "whether or not used (gaps are acceptable)". This decision takes that
number and runs no allocation search of its own. The next line of the ledger, `:1074`, corrects the table and leaves `OV-07 R79` standing: `OV-08`, `OV-09` and `OV-12` through `OV-15` are reserved to R76, R58, R84, R72, R51 and R83, `OV-10` and `OV-11` stay with an existing holder, and R73 and R74 moved to `OV-16` and `OV-17`. A search would have collided with any of them.

**The search this synthesis did run before that notice was a truncated search reported as a
census, and it was false.** It ran
`/usr/bin/grep -rnoE "\bOV-[0-9]+\b" research docs` over the whole working tree; that walks
132,859 files, exceeded its timeout, and returned **no output** — read as "no `OV-nn` is in
use". `OV-01` through `OV-06` were in fact already held. A scoped rerun over the 7,344 markdown
files where an override can actually be recorded —
`find research docs -type f -name '*.md' -print0 | xargs -0 /usr/bin/grep -noE "\bOV-[0-9]+\b"` —
completes in seconds and returns the true set. An intermediate draft of this revision then
allocated `OV-10` and `OV-11` from that corrected census; the controller's notice supersedes
that choice, and both were renumbered to `OV-07` before committing. A second miss followed and
is recorded for the same reason: the renumbering at first left `OV-10` and `OV-11` standing in
two conformance-walk table rows, because the enumeration grep was piped through `cut -c1-135`
and the references sat past that column. The evidence script caught it, which is what it is
for, and the repair is the corrected enumeration shown here rather than a re-read.

`review/evidence/decision-self-check-r3.sh` still executes the scoped census, as
`rest-conformance-r2.sh` did — not to allocate,
which is no longer this item's job, but to assert three things: that no OVERRIDE heading here
carries a number other than `OV-07`; that no other **item** claims `OV-07` (the controller's
ledger naturally names it and is excluded as the allocator's own register, while its
`OV-07 R79` row is asserted separately); and that the census never comes back empty again,
since an empty result now means the search is broken rather than that the numbers are free.
The census **listing** is deliberately withheld from the log: it enumerates other items'
decision files, several of them uncommitted work by other agents in this shared worktree, so
printing it would make an honest rerun's log differ from the committed one. The assertion
outcome is printed instead, and that is what this decision relies on.

**What R79 contributes to the template's conformance note.** The note itself is one document
per API and is R71's or R69's to hold, not R79's to create. R79 supplies four rows for it: the
two deviation rows quoted above, and two N/A rows — `- R1.9 · the dry_run guard binds mutating
requests; /metrics is safe` and `- R2.11–R2.13 · /metrics is a GET of a representation, not a
non-CRUD action`. R1.5 at `:210` requires the note to declare one conformance tier; that
declaration is the API's, and none of the rules above changes with it, because none carries a
tier annotation.

re-verify: on any of these, whichever comes first — (1) **R69 republishes** at revision 10 or later, at which point the paths and feature bodies here are translated by the table under `## Parameters` and the `metrics = ["web", …]` clause is re-checked against the republished row; (2) **R02 publishes** a topology other than the four-package workspace with `crates/web`; (3) **R80 publishes** its probe paths, which must join `/metrics` on the unmeasured side of `route_layer`; (4) **R71 publishes** a generator that enumerates a live `axum::Router` rather than annotated registrations, which would make the automatic OpenAPI exclusion need an explicit mechanism; (5) **R77 publishes** a settings surface that drops `RSLBP_WEB_METRICS_ENABLED`, gives it a default other than `true`, or gives it semantics other than skipping `instrument()`; (6) **R78 publishes** a decision that emits metrics, not only traces, through the OTel SDK, at which point the two items need one recorder rather than two pipelines; (7) **`prometheus-client` declares a `rust-version`**, clearing gate 2 and deserving a fresh head-to-head it currently wins on design grounds; (8) **`metrics-exporter-prometheus` releases 0.19 or `metrics` releases 0.25**, both semver-breaking under caret-on-`0.x`; (9) **`axum` publishes 0.9**, re-opening `MatchedPath` and `route_layer` semantics; (10) **Prometheus native histograms become the default advice**, retiring the bucket constant; (11) at the next **`msrv-policy` floor advance past 1.96**, re-running `review/evidence/cargo-probes-r3.sh` at the new toolchain; (12) **the REST API Design Standard publishes a blob other than `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`**, which re-opens every rule line number and rule text quoted in the conformance walk, and in particular any change to R4.10, R8.6, R7.1, R7.3, R11.7, R11.8 or R13.3; (13) **the standard's owner rules on OV-07(b)**, whose MUST-strength deviation is recorded pending that approval under Appendix B step 3, or on OV-07(a); (14) **the controller rules on whether the single allocated number `OV-07` may carry both of R79's departures or whether a second number is issued**, the open question recorded under the override; (15) **R71 publishes a reading of R4.1 that requires every path to appear in the OpenAPI document**, or **R75 publishes a middleware stack that does not place `/metrics` inside its `request-id` and `traceparent` layers**, either of which turns a row recorded above as CONFORMS or MOVED into an override; (16) **the controller adjudicates `BASELINE-REVIEW: F326` with R69**, which changes one feature list if R69 makes `web` enable metrics; (17) **the Muse leg is collected and registered** with a sha256 other than `15529e48b13cf58728a187a459183276240ad79074530e818972af31f056c378`, which re-opens the engine adjudication; or (18) by **2027-03-18**.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

This item owns no shared parameter: its prompt's `- owns:` line is empty, so no
`- owns <param> = <value>` line is written.

**Why there is no `- assumes web-extra-surface` line, which is a departure from the controller's
task message and is recorded rather than made quietly.** R79's prompt carries an **empty**
`- consumes:` line, and `inputs/parameters.json` lists exactly the four fixed parameters above
and no consumed one. `scripts/research_validation.py` computes
`expected_assumptions = expected_fixed | expected_consumed` and reports
`"DECISION.md current assumed parameter set does not match fixed and consumed values"` whenever
the declared set differs (cited by expression and message, not line number, because the file
moves; the self-check asserts both strings are present). A fifth `- assumes` line would therefore fail strict
acceptance validation at publication. R69 is a **research prerequisite** of this run
(`inputs/prerequisites.json` records its decision hash `d4507f5b…`), not a parameter coupling,
so its value is consumed in prose instead. The clause this design rests on is byte-identical in
R69's published revision 9 and its accepted revision 10, and is quoted here from the live
registry row `web-extra-surface` in `docs/port/PARAMETERS.md`:

> heavier opt-ins nest on top rather than widening it, as separate features that require web -
> otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel
> extras

The same registry row records `tower 0.5.3 is a dev-dependency only, for the
ServiceExt::oneshot in-process test idiom, and is not gated by the feature`, and that is the
clause the `from_fn` middleware choice above is written to respect. **Every path, the feature
graph and the migration table in this decision use that registered revision-9 value**: one
package, `web = ["dep:axum", "dep:tokio"]`, the gated tree `src/web/`, and integration tests in
`tests/` gated file-level with `#![cfg(feature = "web")]`. E1 compiles exactly that
`[features]` table.

**Revision 10 of R69 is owner-accepted and not yet published.** It moves six clauses of that
value (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791`, with the
clause-by-clause substitution table at `:54`–`:61`). If R69 republishes at revision 10, which is
re-verify trigger (1), this decision translates mechanically:

| This decision, against revision 9 | The same thing under revision 10 |
|---|---|
| `metrics` and `metrics-exporter-prometheus` optional in the root `Cargo.toml` | optional in `crates/web/Cargo.toml` |
| `metrics = ["web", "dep:metrics", "dep:metrics-exporter-prometheus"]` in the root package | root: `metrics = ["web", "rs-launch-blueprint-web/metrics"]`; `crates/web`: `metrics = ["dep:metrics", "dep:metrics-exporter-prometheus"]` |
| `src/web/obs/metrics.rs`, `src/web/obs/mod.rs` | `crates/web/src/obs/metrics.rs`, `crates/web/src/obs/mod.rs` |
| `build_router` in `src/web/mod.rs` | `build_router` in `crates/web/src/lib.rs` |
| `tests/metrics.rs` with `#![cfg(feature = "metrics")]` | `crates/web/tests/metrics.rs` with no file-level gate |
| `tokio::spawn(rs_launch_blueprint::web::obs::metrics::run_upkeep(..))` in `src/bin/<app>-serve.rs` | `tokio::spawn(rs_launch_blueprint_web::obs::metrics::run_upkeep(..))` in the same serve binary |
| CI path skip-gating keyed on `src/web/**` | keyed on `crates/web/**` |

No row changes a crate, a version, a metric, a label or a behaviour. The translation is a stated
forward dependency, not a conflict, so no `CONFLICT:` line is raised.

The fixed parameters bear on the decision as follows. `msrv-policy` sets the floor at **1.96**
for the `rustc 1.98.0` stable of 2026-09-18 and again for the `rustc 1.98.1` of the
revision-3 run, derived in the check script rather than asserted;
both recommended crates publish `rust-version` `1.71.1`, and the resolved `--features metrics`
tree's highest declared value is `hashbrown` 0.17.1's **1.85.0**, eleven minors inside the
floor. `rust-edition = 2024` is the probe manifest's declared edition throughout.
`target-os-matrix` is the reason `default-features = false` is not optional: it removes
`aws-lc-sys`, the only C and assembly build in the graph, leaving two pure-Rust crates that
carry no platform-gated code path — but see `## Engines`, because **nothing was built on
`ubuntu-latest` in this run**. `license` is recorded and not evaluated, because fitness gate 1
is struck from every item's evaluation by the owner's ruling; the gate is recorded, not
deleted, and its verdict is:

`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`

## Empirical check

**Toolchain and environment, revision 3.** `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`,
`cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, macOS on Darwin arm64,
`grep (BSD grep, GNU compatible) 2.6.0-FreeBSD` invoked as `/usr/bin/grep`,
`cargo-audit-audit 0.22.1`, `curl 8.7.1`, ShellCheck 0.11.0. `promtool` is not installed on
this host; `cargo-probes-r3.sh` fetched `promtool, version 3.14.0` itself (E8). The revision-3
runs are dated 2026-09-27 (UTC); revision 1's ran on `rustc 1.98.0 (88d9e12ae 2026-08-18)` on
2026-09-18, and its figures are quoted below as revision-1 history where they differ. Working
directory for every script: `research/runs/R79/2026-09-17T034011Z-2e1043da0e00/review/evidence/`.
Every cargo probe built only throwaway packages under a `$TMPDIR` subdirectory the script
creates and deletes, each with `--target-dir` inside that subdirectory; no `target/` tree was
written inside this worktree and the recommendation was not implemented anywhere in the
repository.

| Script | Command | PASS | FAIL | SKIP | Log |
|---|---|---|---|---|---|
| Cargo probes (revision 3) | `./cargo-probes-r3.sh` | 54 | 0 | 0 | `review/evidence/cargo-probes-r3.log` |
| Cargo probes (revision 3), second run from a `/tmp` copy with `CARGO_TARGET_DIR` unset | `env -u CARGO_TARGET_DIR ./cargo-probes-r3.sh` | 54 | 0 | 0 | `review/evidence/cargo-probes-r3.run2.log` |
| Crate sources and registry figures, rerun unchanged | `./crate-sources.sh` | 66 | 0 | 0 | `review/evidence/crate-sources-r3.log` |
| GitHub repository figures, rerun unchanged | `./github-api.sh` | 5 | 0 | 0 | `review/evidence/github-api-r3.log` |
| RustSec method (revision 3; settles `## Engines` item vii) | `./rustsec-method-r3.sh` | 9 | 0 | 0 | `review/evidence/rustsec-method-r3.log` |
| Decision self-check (revision 3) | `./decision-self-check-r3.sh` | 316 | 0 | 0 | `review/evidence/decision-self-check-r3.log` |

The revision-1 and revision-2 logs stay on disk, byte-identical, as the record of those runs:
`cargo-probes.log` (34/0/0), `crate-sources.log` (66/0/0), `github-api.log` (5/0/0),
`decision-self-check.log` (70/0/0) and `rest-conformance-r2.log` (122/0/0).
`decision-self-check-r3.sh` asserts each of them, and each of their scripts, against a literal
sha256.

**Why the carried `crate-sources.log` and `github-api.log` are still cited.** Their scripts
were rerun unchanged for revision 3 and passed with the same counts, 66 and 5. The reruns differ
from the committed logs only in fields both scripts print and never assert: the header date and
scratch path, the `gh` version, the 90-day and all-time download counters, the
reverse-dependency totals, `pushed_at`, stars and the issue counts. Every asserted field
(`num`, `created_at`, `rust_version`, `license`, each tarball sha256 and each quoted source
line, `full_name` and `archived`) is byte-identical. So the shortlist table's registry and
GitHub figures stay **as retrieved on 2026-09-18** from the carried logs, and the revision-3
rerun is cited for currency: for example, `metrics` reverse dependencies moved from 1,199 to
1,220 and `metrics-exporter-prometheus` from 460 to 465, and `metrics-rs/metrics`'s repository
object now reports 84 open issues against the search API's 51.

**Which script an auditor reruns.** For revision 3 it is `decision-self-check-r3.sh` for the
decision text and `cargo-probes-r3.sh` for the probes. The two earlier self-checks are
revision-bound and stay unedited. Against revision 3, `decision-self-check.sh` fails on two
checks, its revision-1 H1 and its one-report count (72/2/0; its per-script hygiene loop now also counts `decision-self-check-r3.sh`), and `rest-conformance-r2.sh` fails
on two, its revision-2 H1 and its OV census, which now meets `OV-07` in this run's own snapshot
and audit file (120/2/0). `decision-self-check-r3.sh` carries every check of both, as follows:

- every revision-1 block: the raw-report identity and count (now two reports), the raw-answer
  validator (now run on both reports), the decision-shape and gate-1 blocks, the parameter
  byte-comparison, every measured figure cross-checked with its log, the `promtool` record,
  the hygiene block, the User-Agent check and the F326 line check;
- every revision-2 block, copied from `rest-conformance-r2.sh` with two edits, which the script
  marks: the blob read and re-hash, the 45 quoted rule lines and their snapshot diff, the
  absent-vocabulary sweep, the conformance claims, the OV census and the W2-REST line check. The
  census excludes this run's own `review/` directory, not only `DECISION.md`, because the
  revision-2 snapshot and the audits of this item name `OV-07` as R79's; and the block's print
  of the decision's own sha256 is marked `volatile:`;
- a literal-sha256 assertion for every revision-1 and revision-2 artifact, which replaces the
  revision-2 loop that only printed digests;
- the revision-3 additions: each count in the table above against its log's summary line, the
  quoted module against `r3-obs-metrics.rs` and against the digest `cargo-probes-r3.log`
  recorded, the F1, F3 and F4 PASS lines, the Muse leg's hash, the substitution authority, the
  input-prompt freshness chain, and every cross-item and py-pin line citation this decision
  makes.

The self-check reads the sibling clones `/Users/stevemorin/c/rest-standards` and
`/Users/stevemorin/c/py-launch-blueprint` with `git` when they are present, and the committed
R77 revision with `git show` when a `.git` is present. Each such check is a named SKIP when its
source is absent. Nothing else shells out to `git`.

**What the cargo probes executed, and what each observed** (revision 3, `cargo-probes-r3.log`).

| # | Command | Observed |
|---|---|---|
| E1 | `cargo check --locked` with `--features metrics`, with `--features web`, and with no feature, on a single package whose `[features]` is R69 revision 9's `web = ["dep:axum", "dep:tokio"]` plus `metrics = ["web", "dep:metrics", "dep:metrics-exporter-prometheus"]` | all three compiled; `dep:metrics` suppresses the implicit feature, so R69's feature spelling is legal beside an optional dependency named `metrics` |
| E2 | `cargo tree -e normal` on two two-crate manifests differing only in `default-features` on the exporter, on revision 1's locks | **37 versus 81** distinct crates; the 44 added include `aws-lc-rs`, `aws-lc-sys`, `rustls`, `hyper`, `hyper-rustls`, `h2`, `tokio-rustls`, `ipnet`; with the defaults off there is no `tokio` edge at all |
| E3 | `cargo tree -e normal` and `cargo build --locked --release` (`strip = true`) with `--features web` and with `--features metrics`, on axum 0.8.9 + tokio 1.53.1 | **51 → 79** crates (**+28**, listed by name in the log); `tower-http` absent from both graphs; `tower` present in both, added by `axum`, not by this feature. Stripped binary **1,307,936 B → 1,702,752 B** (**+394,816 B, +30.2%**) on `rustc 1.98.1`. The bytes are toolchain-bound and printed on `volatile:` lines; the assertion is that the delta lies within ±10% of revision 1's **+378,048 B** (revision 1: 1,307,968 B → 1,686,016 B on `rustc 1.98.0`, in `cargo-probes.log`). Revision 3's probe binary also carries the `scrape` handler's headers and `stream` guard, which revision 1's did not |
| E4 | `cargo generate-lockfile` under `rust-version = "1.96"`, snapshotted as `locks-r3/baseB-msrv.lock` and reused with `--locked`; then this lock's own `cargo tree -e normal --features metrics` graph joined against `cargo metadata --features metrics --filter-platform <host>` on the same lock | the MSRV-aware resolver ran (`Locking 118 packages to latest Rust 1.96 compatible versions`, printed as volatile); the lock holds 119 packages; the graph has 79 crates, and **78 of 78** non-root graph crates were found in `cargo metadata` at the same version, so none was dropped; highest declared `rust-version` is `hashbrown 0.17.1` at **1.85.0**; **12** crates in that graph declare none, named in the log |
| E5 | `cargo audit --file` over `locks-r3/baseB-msrv.lock` | no vulnerabilities; 119 crate dependencies scanned; `RUSTSEC-2021-0113` does not apply, because the resolved `metrics-util` is 0.20.4, past that advisory's `>=0.7.0` patch. The advisory-database size is live and printed as volatile: 1,271 on 2026-09-27, against revision 1's 1,251 |
| E6 | `cargo test --locked --features metrics --test metrics -- --nocapture` | 2 passed. `distinct http_route label values = {"/v1/boom", "/v1/projects/{id}"}`: 51 requests over 50 distinct ids, **two** label values; `_count` 51; `http_server_unmatched_requests_total 1`; no `http_route="/metrics"` after two scrapes |
| F4 | the second test in the same binary, `scrape_http_behaviour` | `GET /metrics` answers `200` with `Cache-Control: private, no-cache` and `Content-Type: text/plain; version=0.0.4; charset=utf-8` for no `Accept`, for `Accept: application/json` and for a Prometheus server's `Accept`; `400` with the same `Cache-Control` for `?stream=1`, `?stream`, `?a=1&stream=` and `?stream=false`; `200` for `?streaming=1` and `?a=1` |
| F1 | `cargo test --locked --features metrics --test metrics_disabled` | with `metrics_enabled = false`: `/metrics` answers `404`, `/v1/projects/7` answers `200`, and a fresh `install_recorder()` afterwards returns `Ok`, so no global recorder had been installed |
| F3 | `cargo test --locked --features web --test web_only` | with `metrics_enabled = true` but only `--features web`: `/metrics` answers `404` |
| E7 | `cargo build --locked --release` with `--features web` | compiled; `metrics-exporter-prometheus` absent from the normal graph |
| E8 | `promtool check metrics < scrape-sample-r3.txt` | **accepted**. With no `promtool` on PATH the script fetched `prometheus-3.14.0.darwin-arm64.tar.gz`, verified it against the release's `sha256sums.txt` and against the literal pin `a9623f7f…c01c`, and parsed the 41-line verbatim capture with no error, invalid or parse complaint |
| runner-up | `cargo tree -e normal` on the axum base plus `axum-prometheus` 0.10.1, on revision 1's lock | **82** crates; `tower-http` joins the runtime graph |

The acceptance test drives the router in process with `tower::ServiceExt::oneshot` — R69's
recorded idiom — so no port is bound and the test would run identically on both CI runners. The
scrape it produced contains, among its 41 lines:

```text
# HELP http_server_unmatched_requests_total HTTP requests that matched no route template.
# TYPE http_server_unmatched_requests_total counter
http_server_unmatched_requests_total 1

# HELP http_server_request_duration_seconds Duration of HTTP server requests.
# TYPE http_server_request_duration_seconds histogram
http_server_request_duration_seconds_bucket{http_request_method="GET",http_route="/v1/boom",http_response_status_code="500",le="0.005"} 1
```

**What the source and registry checks executed.** Every crate manifest, feature map and source
line cited in this decision was read from the **published `.crate` tarball** at
`https://static.crates.io/crates/<name>/<name>-<version>.crate`, whose sha256 the log records,
rather than from a rendered documentation page: `metrics` 0.24.6,
`metrics-exporter-prometheus` 0.18.3, `axum-prometheus` 0.10.1, `prometheus-client` 0.25.1,
`prometheus` 0.14.0 and `opentelemetry-prometheus` 0.33.0. crates.io figures came from
`GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`, `crate.downloads`),
`.../versions` (newest `yanked: false`) and `.../reverse_dependencies?per_page=30`
(`meta.total`), at roughly one request per second with the repository URL as User-Agent. RustSec
was read as `https://rustsec.org/packages/<name>.html`, where HTTP 404 means no advisory page
exists; `rustsec-method-r3.sh` checks that reading against a crate that has an advisory. GitHub
came from keyring-authenticated `gh api` at one call per 20 seconds, using
`GET /repos/<o>/<r>` and `GET /search/issues?q=repo:<o>/<r>+is:issue+is:open` — the search
endpoint's `total_count`, which the prompt requires, not the repository object's
`open_issues_count`, which it forbids; both are printed in the log so the gap between them is
visible (for `metrics-rs/metrics`, 51 against 83 on 2026-09-18).

**Reproducibility, stated exactly rather than asserted.** What varies between an honest rerun
and a committed log is named below, per file, with the rule for comparing across it.

- `cargo-probes-r3.log`: **every line that can move between honest reruns begins `volatile:`**.
  That covers the toolchain, `grep` and `uname` lines, the date, the scratch path, the
  `CARGO_TARGET_DIR` value, the stripped-binary bytes, the live `Locking` line, the
  `cargo audit` version and its advisory count. cargo's progress lines (`Updating`,
  `Downloading`, `Downloaded`, `Compiling`, `Locking` and the like) and its
  `Blocking waiting for file lock` line are filtered, and the
  advisory-db path is redacted to `<advisory-db>`. The rule was tested by two runs:
  `cargo-probes-r3.log` in place with `CARGO_TARGET_DIR=/tmp/cargo-s27-R79-r3-target` set, and
  `cargo-probes-r3.run2.log` from a `/tmp` copy of `evidence/` with `CARGO_TARGET_DIR` unset.
  With `volatile:` lines removed, the two logs differ in exactly one line:
  `lock: created snapshot locks-r3/baseB-msrv.lock` in the first run against
  `lock: reused snapshot locks-r3/baseB-msrv.lock` in the second, which is the first run
  creating the snapshot the second reuses. The scrape itself is timing-dependent, so the log
  prints a **canonical** form of it — sorted, with bucket occupancies and the `_sum` value
  redacted to `<occupancy>` and `<duration>`, and the test's wall time to `<elapsed>` — while
  keeping every series identity, the `_count` value of 51 and the unmatched counter's value of 1.
  The crate counts and package names are pinned by the lockfile snapshots under `locks/` and
  `locks-r3/`; deleting them re-resolves against the live registry, and the counts may then move.
- `scrape-sample-r3.txt` is the **verbatim** capture the `promtool` parse consumed, and it is
  deliberately *not* byte-stable: it is rewritten on every run, and its `_sum` values and
  low-bucket occupancies differ each time. What is stable in it is the series identity set, the
  `_count` value and the absence of any `http_route="/metrics"` series. `scrape-sample.txt` is
  revision 1's capture and is never rewritten by the revision-3 script.
- `crate-sources.log` and its rerun `crate-sources-r3.log` are **byte-identical for every
  tarball sha256 and every quoted source line**, because a published `.crate` artifact is
  immutable. The crates.io counters are not: the comparison rule the script enforces is that
  `num`, `created_at`, `rust_version` and `license` must equal the snapshot under
  `review/evidence/snapshots/` byte for byte, and the all-time `downloads` counter must not
  fall. `recent_downloads` is a rolling 90-day window that legitimately falls, so it is printed
  and never asserted. **The reverse-dependency totals are volatile too**: they are printed and
  asserted only as an order of magnitude, which is why the rerun's 1,220 and 465 pass.
- `github-api.log` and `github-api-r3.log` assert only `full_name` and `archived` against the
  snapshot; `archived` flipping to true is the maintenance signal the check exists to catch.
  Stars, `pushed_at` and the issue `total_count` all move in both directions and are printed
  without assertion, so an honest rerun cannot fail on them.
- `rustsec-method-r3.log` differs between reruns only in its `volatile:` header lines; every
  HTTP status it asserts is live and would move only if RustSec changed a page.
- `decision-self-check-r3.log` differs between reruns only in its lines beginning `volatile:`:
  the date, the resolved repository root, the `.git` context, and the sha256 of `DECISION.md`
  itself, which a self-check cannot assert without asserting its own output. Its external
  dependencies are ShellCheck, the two sibling clones and `git`; where one is absent, the
  check that needs it is a **named** SKIP, and none fired in the run recorded here.

**Gate answers for the recommended pair.** Gate 1 is recorded once here and referred to from
the shortlist table below by that reference rather than restated.

| Gate | `metrics` 0.24.6 | `metrics-exporter-prometheus` 0.18.3 |
|---|---|---|
| 1. Licence | `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`. The declared field is recorded without evaluation: crates.io reports `MIT` | Same ruling, same reference. crates.io reports `MIT AND Apache-2.0` |
| 2. MSRV within stable minus 2 (floor 1.96) | The shipped `Cargo.toml.orig:5` reads `rust-version = { workspace = true }`, so the crate's own manifest carries **no literal value**; crates.io `/versions` resolves and publishes it as **1.71.1**. This decision takes the position, explicitly rather than leaving it for an auditor to argue, that a workspace inheritance the registry resolves to a concrete version **is** a declaration for gate 2's purposes: the strict reading settled on 2026-09-11 fails a candidate that declares *nothing*, and a consumer resolving this crate gets 1.71.1 enforced by Cargo exactly as a literal would be — unlike `prometheus-client`, whose `/versions` reports `rust_version: null`. **Pass**, 25 minors of headroom | published `rust-version` **1.71.1** — pass |
| 3. RustSec advisory; `unsafe` posture | `https://rustsec.org/packages/metrics.html` → HTTP 404, so no advisory. `unsafe` posture **corrected against the raw report**: 35 occurrences across **three** files — 27 in `src/cow.rs`, 5 in `src/recorder/cell.rs`, 3 in `src/recorder/mod.rs` — not 34 confined to `src/cow.rs`. All are in a borrowed-or-owned pointer type and the recorder cell, none is a foreign-function call, and the crate carries no `unsafe` on the macro path | `https://rustsec.org/packages/metrics-exporter-prometheus.html` → HTTP 404. **Exactly one** `unsafe` occurrence in the crate, at `src/recorder.rs`. Its dependency `metrics-util` does have an advisory page — `RUSTSEC-2021-0113`, patched `>=0.7.0` — and the resolved 0.20.4 is unaffected (E5) |
| 4. Builds on `ubuntu-latest, macos-latest` | Built, linked and tested on macOS arm64 in this run. **Not built on Linux here** — see `## Engines`. Pure Rust with no C dependency once `default-features = false` removes `aws-lc-sys`, which is the gate-4 argument for turning the defaults off | same |
| 5. Default features and async-runtime coupling | **no `[features]` table at all** in the shipped manifest, and no `tokio` dependency — verified by asserting the absence of both keys | `default = ["http-listener", "push-gateway"]`, **turned off**; with them off there is no `tokio` edge (E2), and `install_recorder` / `build_recorder` are not feature-gated (verified by walking the attribute block above each declaration). The only async touch-point is the upkeep ticker the template spawns |
| 6. Binary-size and compile-time cost | measured jointly (E2, E3): +28 crates and, on R69's axum base, +394,816 B stripped on `rustc 1.98.1` (revision 1: +378,048 B on `rustc 1.98.0`); the bytes are toolchain-bound, the crate count is not. Compile time was **not** re-measured here; the Opus report's approximate +8 s on a cold target directory is carried, with its own caveat that run-to-run noise was of the same order | same measurement — the pair ships together and was measured together |

**Qualified shortlist.** Five candidates cleared gate 2 and carry no RustSec advisory. Gate 1
is `inapplicable` for every row by the ruling recorded above. Evidence depth is not uniform and
each row says how far it reaches.

| Candidate | Role | 90-day downloads | All-time | Stars | Last release | Maintenance | Notable adopters | Trade-off, in one line |
|---|---|---|---|---|---|---|---|---|
| `metrics` 0.24.6 | instrumentation facade | 20,185,758 | 108,173,967 | 1,486 (`metrics-rs/metrics`) | 2026-05-13 | **active** — `pushed_at` 2026-09-18T14:54:13Z, 51 open issues, not archived | reth, Vector, apalis, rumqttd | one global recorder per process, so tests need a `OnceLock` |
| `metrics-exporter-prometheus` 0.18.3 | recorder and Prometheus text renderer | 13,007,165 | 47,578,577 | 1,486 (same repository) | 2026-04-30 | **active** (same signals) | reth, at this exact pin and this exact `default-features = false` form | the defaults pull a whole HTTP and TLS stack you do not want, and upkeep is the caller's job |
| `axum-prometheus` 0.10.1 | axum middleware over the `metrics` facade | 1,388,212 | 5,658,682 | 92 (`Ptrskay3/axum-prometheus`) | 2026-07-31 | **active** — `pushed_at` 2026-07-31T07:07:09Z, 10 open issues, single maintainer | downstream service templates | gives an in-flight gauge, a body-size histogram and ignore patterns; costs `tower-http` 0.7.1 in the runtime graph (measured) and a per-axum-major treadmill |
| `prometheus` 0.14.0 | registry-object client (tikv) | 24,842,546 | 145,764,833 | 1,181 (`tikv/rust-prometheus`) | 2025-03-27 | **stable-quiet** — 18 months since release, `pushed_at` 2025-12-31T07:01:42Z, 66 open issues, **but** no advisory, no maintainer notice and no broken build, so the rubric forbids `at-risk` | TiKV, Neon; `opentelemetry-prometheus` 0.33.0 depends on it | highest raw volume in the field, but you thread `HistogramVec` handles through app state, and `default = ["protobuf"]` (read at source) |
| `opentelemetry-prometheus` 0.33.0 | OTel-metrics to Prometheus bridge | 2,518,260 | 14,203,757 | 2,708 (`open-telemetry/opentelemetry-rust`, whole-project repository) | 2026-09-18 | **active** — released the day of retrieval, 218 open issues across the whole project | OTel users needing scrape instead of OTLP | passes every gate, but its own README steers new projects to `opentelemetry-otlp`, and it drags `prometheus` 0.14 in transitively |

`prometheus` and `opentelemetry-prometheus` were assessed from their published manifests and
sources only; they were not built or tree-walked in this run, and the rows say so rather than
implying uniform depth. The `metrics` pair and `axum-prometheus` were all three resolved and
tree-walked, and the first two were built and tested.

**Excluded by gate.** Gate 2 is applied under the strict reading settled by the owner on
2026-09-11 and recorded in `docs/planning/p02/owner-decisions.md`: a candidate that declares no
`rust-version` fails the gate.

| Candidate | Gate failed | Evidence, re-read at source |
|---|---|---|
| `prometheus-client` 0.25.1 — the Prometheus organisation's own Rust client | **Gate 2**, no `rust-version` declared | `prometheus-client-0.25.1/Cargo.toml.orig` from the published tarball has no `rust-version` key, asserted as an absence; crates.io `/versions` reports `rust_version: null`. A painful exclusion — 606 stars, `pushed_at` 2026-09-14T11:44:30Z, typed labels, OpenMetrics output, no global state — and it is recorded as a re-verify trigger |
| `autometrics` 3.0.0 | **Gate 2** (crates.io `/versions` reports `rust_version: null`) **and maintenance rubric `dormant`** | the repository README's own notice, "Autometrics is no longer actively maintained" — a maintainer's own statement, which the rubric names as sufficient for `dormant` |
| `axum-otel-metrics` 0.14.1 | **Gate 2**, no `rust-version` (crates.io `/versions`, `rust_version: null`) | also the smallest candidate surveyed, and architecturally inside the rejected alternative D |
| Log-based metrics / Cloud Monitoring, the owner reference's first suggestion | **Capability**, not a fitness gate | it cannot produce a duration histogram with bucket boundaries, so it cannot satisfy the D of RED. Recorded as the `DIFFER` row above |

**Ranked runner-up, and the condition under which it wins.** `axum-prometheus` 0.10.1 —
`rust-version = "1.75"` (`Cargo.toml.orig:8`), `default = ["prometheus"]` (`:32`), zero
`unsafe` in `src/lib.rs`, no RustSec page, and it independently pins
`metrics-exporter-prometheus = { version = "0.18.3", optional = true, default-features = false }`
(`:18`) — i.e. it reached the same `default-features = false` conclusion. **It wins if the
template decides RED is not enough** and wants the in-flight gauge and body-size histogram out
of the box, plus a declarative ignore list that R80's probe paths and `/metrics` join in one
line. What tips it to second place is measured, not argued: it adds `tower-http` 0.7.1,
`bitflags` and itself to the runtime graph (**82 crates against the recommended 79** on the
identical base), and R75 has not chosen a `tower-http` version — the owner reference names
`tower-http 0.6` at C11, so adopting 0.7.1 here would create a version-skew risk between two
unpublished items. Its `tokio = { version = "1.53", features = ["rt-multi-thread", "macros"] }`
(`:21`) is non-optional, and its `Handle::default()` calls
`metrics::set_global_recorder(recorder).expect("Failed to set global recorder")`
(`src/lib.rs:892`) unconditionally, so a second layer construction in one test binary panics —
at which point the template would wrap it in a `OnceLock` anyway and have re-implemented most of
the convenience.

**Up-and-comer worth a later look.** `measured` 0.0.25 is the most interesting *design* in the
field — label sets are types, so high cardinality becomes a compile-time conversation — and it
has one verifiable production user in Neon. Two reasons it is not shortlisted for a **template**:
`0.0.25` offers no semver breakage protection, which is a poor default for code other people
copy, and the one verified adopter employs the author, so the independent-adoption evidence is
thin. Worth re-verifying at its 0.1.0.

**Migration implications — file-level changes in the template**, written against R69's
registered revision 9: one package, the gated tree `src/web/`, and integration tests in `tests/`.
No file outside `src/web/`, the serve binary, `tests/`, the manifest, CI and the README changes.
The translation to R69 revision 10's `crates/web` form is the table under `## Parameters`.

| File | Change |
|---|---|
| `Cargo.toml` (the package that hosts the binary targets) | add `metrics` `0.24.6` and `metrics-exporter-prometheus` `0.18.3` (`default-features = false`) as optional dependencies, and `metrics = ["web", "dep:metrics", "dep:metrics-exporter-prometheus"]` to `[features]`, exactly as shown above |
| `src/web/obs/metrics.rs` (new, about 110 lines) | the module shown above: `recorder()`, `run_upkeep()`, `track()`, `count_unmatched()`, `scrape()`, `instrument()`, the name, bucket and header constants, and the `stream` guard. `recorder()` and `run_upkeep()` are `pub`, because the ticker is spawned from the serve binary |
| `src/web/obs/mod.rs` (new) | `pub mod metrics;`, declared from `src/web/mod.rs` as `#[cfg(feature = "metrics")] pub mod obs;` |
| `src/web/mod.rs` (`build_router`) | wrap the business router as the composition-root snippet above shows: `obs::metrics::instrument(business)` when R77's `metrics_enabled` is true, applied to the `/v1` business routes **before** `ops::router()` is merged. The `metrics`-off build is byte-for-byte what R69 describes |
| `src/web/` router fallback | the 404 fallback handler gains one gated line, `#[cfg(feature = "metrics")] obs::metrics::count_unmatched();` |
| `src/bin/<app>-serve.rs` (the R69 serve binary) | one gated `tokio::spawn(rs_launch_blueprint::web::obs::metrics::run_upkeep(rs_launch_blueprint::web::obs::metrics::recorder()))` beside `axum::serve(...)`, when `metrics_enabled` is true. It needs no shutdown handling: the task dies with the runtime and holds no state that must be flushed |
| `tests/metrics.rs` and `tests/metrics_disabled.rs` (new) | the acceptance, HTTP-behaviour and off-switch tests above, gated file-level with `#![cfg(feature = "metrics")]` as R69 revision 9 gates web tests |
| `.github/workflows/ci.yml` (R11 owns the shape) | the web job's feature selector becomes `--features metrics` or `--all-features`, so the new code and its tests are compiled and run; path-based skip-gating already keys on `src/web/**` |
| `README.md` / web quickstart | the web example command becomes `cargo run --features metrics --bin <app>-serve`, because `--features web` alone does **not** enable metrics under R69's nesting (check F3), and the README names `RSLBP_WEB_METRICS_ENABLED=false` as the off switch |
| `docs/port/COMMONALITY.md` F326 | no wording change proposed by this item; the packaging challenge is raised as `BASELINE-REVIEW: F326` under `## Decision`, for the controller to adjudicate with R69 |

`cargo deny` must run as `cargo deny --all-features check bans` — R02 revision 2's executed
finding, `CD5a`–`CD5d` — or the optional metrics dependencies are absent from the resolved
graph entirely.

## Engines

The prompt's `- engines:` line reads `muse, opus`. Muse substitutes for Codex under the
`engine_overrides` pilot: owner decision Q5.A (2026-09-21, recorded as the migration event in
`manifest.json`), with Q9.B's retirement of Codex from P02 and Q17.A's extension to a later
wave as the current statement of the policy in `research/RUNBOOK.md` §2. Both reports were read
in full.

- **Claude Opus 5** — `raw/opus.md`, sha256
  `c1d02b81cd0929881f66c7810af782496a84f73a8f45472e86e773a0300145ac`, collected 2026-09-18,
  15 H3 sections, passing `validate_answer_text(text, "crate")` with no diagnostics.
- **Muse** (`muse-spark`, Meta) — `raw/muse.md`, sha256
  `15529e48b13cf58728a187a459183276240ad79074530e818972af31f056c378`, retrieval date
  2026-09-25, 15 H3 sections, passing `validate_answer_text(text, "crate")` with no
  diagnostics. **Registration gap:** the file is on disk and untracked, and `manifest.json`
  still records its operation `d4a2338f77114baba83a7670688fe894` as `submitting`. This decision
  adjudicates exactly those bytes; the runner must collect and hash-pin the leg before
  acceptance (re-verify trigger 17).

The two reports are from different model families, which revisions 1 and 2 lacked. Every
load-bearing claim was still re-verified at source by this synthesizer, and the tables below say
which claims were re-executed, which were found wrong, and which are carried on an engine's word.

**A note on validation shape.** `validate_answer_text(text, "crate")` checks the fifteen H3
answer fields of a *raw report*. A `DECISION.md` carries the four H2 sections the RUNBOOK
mandates plus one `### Principles and implementation`, which is what `_validate_decision_text`
in `scripts/research_validation.py` checks (cited by function name, not line number, because the
file moves). The answer validator was run on both raw reports, where it applies, and returned no
diagnostics; `decision-self-check-r3.sh` runs `_validate_decision_text` on this decision.

**Re-verified at source by this synthesis — reproduced exactly.**

| Claim | How it was re-verified | Result |
|---|---|---|
| crates.io figures for all nine surveyed crates (downloads, newest non-yanked version, `created_at`, `rust_version`, `license`) | `GET https://crates.io/api/v1/crates/<name>` and `.../versions`, 2026-09-18 | every figure in the shortlist and exclusion tables reproduced exactly **as retrieved on 2026-09-18**. The 90-day download column is a rolling window and a later rerun will legitimately differ from the numbers printed in those tables; the comparison rule recorded above is what a rerun enforces instead |
| reverse-dependency totals: `metrics` 1,199, `metrics-exporter-prometheus` 460 | `.../reverse_dependencies?per_page=30`, `meta.total` | exact **as retrieved on 2026-09-18**; the revision-3 rerun reads 1,220 and 465, and the totals are printed as volatile |
| GitHub stars, `archived`, `pushed_at` and open-issue `total_count` for all five shortlisted repositories | keyring-authenticated `gh api`, one call per 20 s | 1,486/51, 92/10, 1,181/66, 606/44, 2,708/218 — all exact; none archived |
| exporter `default = ["http-listener", "push-gateway"]`; the upkeep contract; the `#[cfg(any(...))]` gate on `install()`/`build()` at `:443` and `:531`; `install_recorder` at `:506` and `build_recorder` at `:605` ungated; the 5-second `upkeep_timeout` default at `:88` | published tarball, sha256 recorded | every line number and every claim exact. The report's `:443-448` citation is the multi-line attribute at `:443`–`:447` |
| `axum-prometheus`: `tower-http = "0.7"`, non-optional `tokio`, `default = ["prometheus"]`, the `/metrics` sample scrape at `src/lib.rs:73`, the unconditional `set_global_recorder(...).expect(...)` at `:892`, `run_upkeep` at `:889`, `with_ignore_pattern` at `src/builder.rs:89`, the `EndpointLabel::MatchedPath` fallback at `:28` | published tarball | exact |
| `prometheus-client` 0.25.1 declares no `rust-version`; `prometheus` 0.14.0 `default = ["protobuf"]`; `opentelemetry-prometheus` depends on `prometheus` 0.14 and its README steers to `opentelemetry-otlp`; the `autometrics` retirement notice | published tarballs and `raw.githubusercontent.com` | exact — this discharges the report's own "gates 3–6 read, not built" gap for these three |
| axum's own example at tag `axum-v0.8.9`: the "tower-http will hopefully have a metrics middleware" comment, `PrometheusBuilder`/`install_recorder`, `route_layer`, and the **absence** of `run_upkeep` | `raw.githubusercontent.com`, sha256 of both files recorded | exact, including the defect |
| RustSec: HTTP 404 for `metrics`, `metrics-exporter-prometheus`, `axum-prometheus`, `prometheus`, `prometheus-client`, `opentelemetry-prometheus`, `autometrics`, `measured`, `quanta`; HTTP 200 with `RUSTSEC-2021-0113` for `metrics-util` | `https://rustsec.org/packages/<name>.html` | exact |
| 37 versus 81 crates on the exporter default-feature delta | E2 | exact |
| 51 → 79 crates (+28) for the `metrics` feature on R69's axum base | E3 | exact |
| `Locking 118 packages to latest Rust 1.96 compatible versions`; highest declared tree `rust-version` is `hashbrown` 0.17.1 at 1.85.0 | E4, on its own snapshotted lock, with 78 of 78 graph crates joined | exact |
| `cargo audit`: 119 crate dependencies, no vulnerabilities | E5 | exact; the advisory count is live (1,251 on 2026-09-18, 1,271 on 2026-09-27) |
| the ten acceptance criteria, including 50 distinct URIs producing one label value, no `/metrics` series after two scrapes, the `/metrics` headers, the `stream` guard and the off switch | E6, E8, F1, F4 | exact |
| `axum-prometheus` footprint of 82 crates on the identical base | runner-up probe | exact |
| py's `excluded_handlers=["/metrics", "/healthz", "/readyz"]`, `include_in_schema=False`, and `prometheus-fastapi-instrumentator>=7.0.0` inside the `web` extra | `git show` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5` | exact, including that the exclusion set is three paths and that the dependency is in `web`, not `otel` |

**Claims found wrong, not reproduced, or reproduced only in part — synthesizer versus the Opus report.**

| Report claim | What was observed | Disposition |
|---|---|---|
| `metrics`' `unsafe` is "34 occurrences, all in `src/cow.rs`" | **35** occurrences across **three** files: 27 in `src/cow.rs`, 5 in `src/recorder/cell.rs`, 3 in `src/recorder/mod.rs` | **Wrong, and the confinement half is the load-bearing half.** Gate 3 is restated above with the measured figures. It does not change the recommendation: none of the eight occurrences outside `src/cow.rs` is a foreign-function call, and the crate still carries no `unsafe` on the macro path |
| stripped binary `1,256,896 B → 1,617,952 B`, delta `+361,056 B` | revision 1: `1,307,968 B → 1,686,016 B`, delta **+378,048 B** on `rustc 1.98.0`; revision 3: `1,307,936 B → 1,702,752 B`, delta **+394,816 B** on `rustc 1.98.1` | **Not reproduced exactly, and could not be**: the probe binaries are not the same program, and the bytes move with the compiler. All were built with `strip = true` on the same axum and tokio pins. The load-bearing figure is the delta: the cost is **about +0.36 to +0.39 MB, roughly +29% to +30%**. All three figures are shown rather than one silently preferred |
| "Twenty packages in the tree declare no `rust-version`" | **12**, in the `cargo tree -e normal --features metrics` runtime graph of E4's own snapshotted lock `locks-r3/baseB-msrv.lock`, with every graph crate joined | **Different scope, not reconciled by guessing.** The report's 20 is over a wider set (the lock includes dev-dependencies and both feature states); this decision's 12 is the graph gate 2 is actually asked about, and it is stated with that scope. The empirical audit's 11 came from joining a fresh lock against an older graph, which dropped five drifted crates; revision 3 pins E4's lock and fails on any drop |
| "it is the only family in which *both* crates declare a `rust-version` (1.71.1)" | `metrics` 0.24.6's shipped `Cargo.toml.orig:5` reads `rust-version = { workspace = true }` — **no literal value in the crate's own manifest**; 1.71.1 is what crates.io `/versions` resolves it to | **Half-wrong at source, and it touches a gate.** It does not change the verdict: the gate-2 cell above now takes an explicit position that a registry-resolved workspace inheritance is a declaration, and says why that is different from `prometheus-client`'s `rust_version: null` |
| compile time approximately +8 s cold, "noisy" | **not re-measured** | **Carried on the single engine's word**, with its own caveat that run-to-run noise on a warm registry cache was of the same order. The crate count and the binary bytes are the robust figures and both were re-measured |
| issue-responsiveness medians (0.57 days for `metrics-rs/metrics` over 7 answered-or-not issues; 10.3 days for `Ptrskay3/axum-prometheus`) | **not re-collected** | **Carried.** Re-collecting them needs a per-issue comment walk at one call per 20 s across 14 issues, which was not run. Neither figure triggers `at-risk` under the rubric, which needs a concrete signal, and none exists for either repository |
| reth, Vector and Neon adopter manifests at `raw.githubusercontent.com` | **not re-fetched** | **Carried**, with their retrieval date. The claim that reth pins this exact version in this exact `default-features = false` form is the report's, not this synthesis's retrieval |

**Disagreements between the Muse report and this decision, and the evidence that settles
each.** Items i–x are the ten the judgment audit listed; items xi–xiv were found on reading
`raw/muse.md` in full. Line references are to `raw/muse.md`.

| # | Topic | Muse report | This decision | Settled by | Outcome |
|---|---|---|---|---|---|
| i | Metric names | `http_requests_total` / `http_request_duration_seconds` (`:90`, `:127`) | the semconv names | argument, not execution: F326 fixes capability plus policy, not names, and Muse's own agreement list puts metric names under "May vary" (`:41`) | decision stands; the two reports agree names may vary |
| ii | Instruments | a labelled request counter plus a histogram (`:90`) | a duration histogram plus the label-free unmatched counter | E6: the histogram's `_count` reads 51 for 51 requests, so it carries the rate | decision stands |
| iii | Dependencies | unconditional, "No env vars, no feature flags" (`:126`, `:129`) | optional behind the `metrics` feature | R69's registered `web-extra-surface` value, which owns the feature and spells `metrics = ["web", …]`; E1 compiles it | decision stands on R69's owned value; Muse's shape is the change `BASELINE-REVIEW: F326` asks R69 to consider |
| iv | Self-exclusion | an explicit path check in the middleware (`:98`, `:127`) | structural: `/metrics` merged after `route_layer` | E6: no `http_route="/metrics"` series after two scrapes | both designs meet the criterion; structural placement is kept because no list can drift |
| v | Status label | status class `4xx`/`5xx` preferred (`:99`) | the raw status code | the semconv attribute `http.response.status_code` is the code; a class can be derived at query time (`=~"5.."`), a code cannot be recovered from a class, and the code set is bounded | decision stands |
| vi | Unmatched routes | `MatchedPath` "with a grouped-pattern fallback" (`:99`) | no fallback; the label-free counter | E6 (unmatched counter 1, two route labels) and the semconv rule that `http.route` "MUST NOT be populated" without a template. Muse conditions the fallback on frameworks without `MatchedPath` (`:148`); R69 chose axum, which has it | decision stands |
| vii | RustSec method | per-package pages "retired (404 shell)", OSV substituted (`:73`, `:152`, `:167`) | HTTP 404 means no advisory page exists | `rustsec-method-r3.log`: `metrics-util.html` answers 200 and names `RUSTSEC-2021-0113`, so the pages are live; the seven surveyed crates answer 404 | Muse's method claim is wrong; its OSV result, no vulnerabilities, agrees with this decision's conclusion |
| viii | `autometrics` | `stable-quiet`, passing every gate (`:84`) | `dormant`, failing gate 2 | `crate-sources-r3.log`: `rust_version=None` from crates.io `/versions`, and the README line "Autometrics is no longer actively maintained". Muse's own Sources line records "rust-version undeclared" (`:164`) | decision stands |
| ix | Excluded by gate | "None" (`:80`); `prometheus-client` never assessed | three exclusions | `crate-sources-r3.log`: `prometheus-client` 0.25.1 declares no `rust-version` in its tarball, and `rust_version=None` for `prometheus-client`, `autometrics` and `axum-otel-metrics` | decision stands; Muse's survey omits the Prometheus organisation's own client, a coverage gap |
| x | Runner-up premise | `axum-prometheus` wins only "conditioned on R69 selecting Axum" (`:45`, `:105`) | R69 has selected axum 0.8.9 | the registered `web-extra-surface` value | the condition is met; both reports rank `axum-prometheus` second |
| xi | Environment gate | "on by default with no env gate" (`:34`, `:96`) | py's default-true off switch, as `RSLBP_WEB_METRICS_ENABLED` | py at pin `b08bccfb`: `settings.py:64` and `app.py:148`, asserted by the self-check; F1 executes the switch | decision stands; Muse inherited the prompt's wrong Context sentence |
| xii | `metrics` `unsafe` | "confines `unsafe` to its `Cow` primitive (`src/cow.rs` …)" (`:73`) | 35 occurrences across three files | `crate-sources-r3.log`: "total across src/: 35 ; in src/cow.rs alone: 27" | Muse repeats the Opus report's error; decision stands |
| xiii | `prometheus` 0.14.0 default features | "inert (`gen`, `process`, `push` opt-in)" (`:75`) | `default = ["protobuf"]` | `crate-sources-r3.log`: the tarball's `Cargo.toml.orig:19` reads `default = ["protobuf"]` | decision stands |
| xiv | `BASELINE-REVIEW` | "No `BASELINE-REVIEW` finding" (`:51`) | `BASELINE-REVIEW: F326` raised | F3: `--features web` alone answers 404 at `/metrics` under R69's registered value | decision stands; Muse's unconditional dependencies (iii) would themselves change R69's owned value |

**Where the two reports agree, independently.** The crate pair and its version lines;
`default-features = false` on the exporter; a template-owned middleware of about forty lines;
the OpenTelemetry bridge rejected because the default-on path must not depend on the optional
`otel` feature; `axum-prometheus` as the ranked runner-up; and OpenAPI exclusion by registering
`/metrics` outside the annotated path. Muse's executed probe (`:144`) compiled
`install_recorder` and `render` with the defaults off on `rustc 1.98.1`, which E1 and E6 also
show. Two Muse statements are procedural rather than factual and are not adjudicated as
disagreements: its gate-1 licence evaluation (`:71`), which owner ruling Q7.B makes
inapplicable, and its `prometheus` release date of 2026-03-27 in the shortlist (`:65`), which
its own Sources line (`:164`) and `crate-sources-r3.log` give as 2025-03-27.

**Additions this synthesis makes that neither report carried**, flagged as such: the
semantics of R77's `RSLBP_WEB_METRICS_ENABLED`; the finding that **no item currently owns**
excluding R80's probe paths from metrics measurement, since R80 takes "No position" and R75 owns
only the access-log exclusion; the executed `promtool` conformance parse, which the Opus report
proposed and did not run; and the executed `/metrics` HTTP behaviour under the REST standard.

**Unproven, and left for P03 to prove in the real template.**

1. **Nothing was built on `ubuntu-latest`.** Gate 4 for the recommended pair rests on the
   executed macOS build plus both crates being pure Rust with no C dependency once
   `default-features = false` removes `aws-lc-sys` — not on a green Linux job anyone watched.
   P03 proves it by running the same `--features metrics` job on both matrix runners.
2. **`cargo hack --each-feature check --workspace`** — proves `metrics` on and off both compile
   and that `metrics` cannot be enabled without `web`. Needs the real workspace.
3. **`cargo deny --all-features check bans licenses advisories`** in the real four-package
   workspace, in R02's executed argument order.
4. **An end-to-end scrape against the real serve binary.** E8 parsed the in-process scrape under
   `promtool check metrics` and it passed, which retires the exposition-format question; what
   remains unproven is the same check against a bound listener with the upkeep ticker running.
5. **An OpenAPI-exclusion assertion once R71 publishes** — `jq -e '.paths | has("/metrics") | not'`
   over the generated document, wired into R71's snapshot gate rather than duplicated here.
6. **A memory-shape check for upkeep**: record a large number of observations across a handful of
   label sets, run the ticker, and assert that process RSS plateaus. This is the only claimed
   behaviour the in-process acceptance test cannot reach, and the one whose absence would hurt
   most in production.
7. **No adoption survey figure.** No Rust annual-survey question enumerating metrics crates was
   retrieved by either the report or this synthesis; adoption evidence is registry counts and
   named projects, and that limit is stated rather than filled.
8. **Whether a `MEMBER`/`OWNER` issue reply is substantive rather than triage** was not judged by
   either the report or this synthesis; the responsiveness figure is time to first maintainer
   comment.

**Revision history.**

| Revision | sha256 | What it changed |
|---|---|---|
| 1 | `2e804161b9fbe65c7d33be04de5e024612ce628e1ea914c4e636443e0f0885c3` | The decision as first written from `raw/opus.md`, with the Codex leg absent under W1-CODEX3 and every load-bearing claim re-verified at source. Checks 34 / 66 / 5 / 70 = 175 PASS. Committed at `fca40a5` after three repairs to its own reproducibility claims |
| 2 | `1551c96d483f7be26ca0d50d1df2caa32d4542ccf66e0423ad40e5827ae2e215` (preserved at `review/R79-r2-snapshot.md`) | **Pre-audit revision** under owner ruling W2-REST (2026-09-18). Adds the conformance walk against the REST API Design Standard v2.0.0 at blob `71bd813c…`: 45 rule lines quoted at their line numbers, 21 dispositions, three **MOVED** rows that change the recommendation's HTTP behaviour, two departures recorded under the controller-allocated `OV-07`. Adds `rest-conformance-r2.sh` (122 PASS) and supersedes `decision-self-check.sh`. Both round-1 audits rejected it |
| 3 | this file | Answers the round-1 audits `audit-fable.md` (F1–F7) and `audit-claude.md` (EA-1–EA-6), as the revision note at the top records. Adds py's off switch as `RSLBP_WEB_METRICS_ENABLED`, raises `BASELINE-REVIEW: F326`, retargets paths to R69 revision 9, executes the `/metrics` HTTP behaviour, adjudicates the Muse report, and replaces the probe and self-check scripts with `cargo-probes-r3.sh` and `decision-self-check-r3.sh`. The crate pair, versions, metric names and labels do not move |

