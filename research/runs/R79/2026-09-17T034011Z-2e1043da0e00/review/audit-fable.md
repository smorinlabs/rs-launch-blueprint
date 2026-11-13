actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 1551c96d483f7be26ca0d50d1df2caa32d4542ccf66e0423ad40e5827ae2e215
verdict: reject
unresolved-findings:
1. JF-4/JF-1/JF-10: py's precedent is misread. py has a default-on environment kill switch for metrics; the decision's "no env gate, matching py exactly" is false at source, and its R77 disposition rests on that false premise.
2. JF-3: `## Engines` does not represent the current engine set (`muse, opus`). It names Codex, says one engine ran, and adjudicates none of the Muse report's disagreements.
3. JF-2/JF-1: the decision claims metrics are "on by default within the enabled web surface", but `--features web` alone yields no `/metrics`. It challenges the inherited direction without the `BASELINE-REVIEW: F326` that the prompt requires.
4. JF-2: revision 2's HTTP behaviour was not executed and is not listed as unproven: `Cache-Control`, the R13.3 `400` and `Content-Type`. The shown `scrape` handler also cannot be routed as written.
5. JF-7: the decision designs against R69 revision 10, which is accepted but unpublished. Its pinned prerequisite and the live registry are still R69 revision 9.
6. JF-1 (minor): "matches py byte for byte" contradicts the decision's own semconv metric names.
7. JF-4 (drift, minor): the `scripts/research_validation.py` line citations have moved.

# Judgment audit — R79 prometheus-metrics, DECISION.md revision 2

Auditor: fable (fresh context; not a raw producer, not the synthesizer). Date: 2026-09-26.
Target: `research/runs/R79/2026-09-17T034011Z-2e1043da0e00/review/DECISION.md`.
Hash check: I recomputed the sha256 with `shasum -a 256`. It gives `1551c96d…e2215`, which equals the expected value.
Scope: this audit judges reasoning and fidelity only; the separate empirical audit reruns the scripts. I read no `review/audit-*.md` file and no snapshot file.
Against current state: this audit judges the decision against the live prompt (`research/topics/79-prometheus-metrics/prompts/prometheus-metrics.prompt.md`, sha256 `206b3fad…`, identical to `inputs/prompt.md`) and the working-tree `docs/port/PARAMETERS.md`. It also uses `research/topics/69-web-framework-stack/DECISION.md` (sha256 `d4507f5b…`, revision 9) and the py pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`.

## Check results

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** | Findings 3 and 6. The on-by-default claim contradicts the packaging concession. The "byte for byte" claim contradicts the semconv metric names. |
| JF-2 prompt questions and constraints | **fail** | Findings 3 and 4. The HIGH and LOW questions are all addressed; the Landscape, three-bin map and CLI/library/web fit are carried by `raw/opus.md` (`### Landscape` at :10, `### Fit for this template` at :444). Two constraints are breached: the prompt's BASELINE-REVIEW instruction, and its demand to "distinguish proposed checks from checks actually run". |
| JF-3 Engines fidelity and adjudication | **fail** | Finding 2 |
| JF-4 load-bearing claims trace to sources | **fail** | Finding 1 (py) and finding 7 (drift). The other spot-checks reproduced exactly; see "Spot-checks that passed". |
| JF-5 couplings hand over owned choices | pass | R80 keeps the probe paths ("R80 chooses the paths; this item owns only where they sit relative to the layer"). R75 receives the request-id/traceparent placement and the 308 redirect as requirements. R71 receives one exclusion sentence plus a re-verify trigger. R77 deferred `METRICS_ENABLED` semantics to R79 (`research/runs/R77/2026-09-17T034011Z-5884fd6b6366/raw/opus.md:379`, "not decided \| R79, R78"), so deciding the variable is in scope. The disposition's premise is wrong, which is finding 1. |
| JF-6 assumes lines byte-identical to the live registry | pass | The four `- assumes` values at DECISION `:661`–`:664` equal `docs/port/PARAMETERS.md:7`–`:10` byte for byte, and they match `inputs/parameters.json`. The prompt's `- consumes:` line is empty, so no fifth line is owed. |
| JF-7 no conflict with accepted or published prerequisites | **fail** | Finding 5 |
| JF-8 evidence scripts exist; counts match | pass | Each of the five cited logs has its script beside it. The PASS lines are 34, 66, 5, 70 and 122; each `grep -c '^PASS'` result (35/67/6/71/123) includes the summary line. The spot-checked figures match the logs: 37→81, 51→79, 82, 1,307,968→1,686,016 B, "Locking 118", hashbrown 1.85.0, 1251 advisories / 119 deps, and the E6 `_count` of 51. |
| JF-9 decision shape follows the contract | pass | The file has the H2s `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`; `### Principles and implementation`; and a `re-verify:` line (:657). No `## Supersedes` is needed. `rest-conformance-r2.log` records `PASS _validate_decision_text(DECISION.md, "R79") returns no diagnostics`. |
| JF-10 recommendation follows from the evidence | **fail (in part)** | The crate pair, `metrics` ^0.24.6 with `metrics-exporter-prometheus` ^0.18.3 and `default-features = false`, is supported by both engines and by the executed probes. The posture half of the recommendation is not supported: no env knob, and the R77 disposition. It rests on finding 1. |

## Findings

### 1. py's metrics posture is misread at source (JF-4, JF-1, JF-10) — blocking

**Failed claims.**
- DECISION `:366`–`:369`: "no environment variable gates collection, the recorder is installed during startup unconditionally, and the `/metrics` route is registered unconditionally — matching py exactly".
- DECISION `:373`–`:375`: "F326's 'on by default, no env gate' is an owner-recorded baseline, and a knob that can turn RED collection off is the thing F326 exists to forbid."
- The agreement table at `:156` lists "on-by-default posture: no environment variable gates collection" as something that must agree across py, ts and rs.
- `:130`–`:132` says the py evidence "was re-read at its pin".

**Evidence.** At the pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, py gates metrics behind a default-true setting that the environment controls:
- `src/py_launch_blueprint/web/settings.py:63`–`:64`: `#: Expose Prometheus RED metrics at /metrics (WEB-11).` / `metrics_enabled: bool = True`
- `settings.py:38` `ENV_PREFIX: str = f"{APP_NAME.upper()}_WEB_"` and `:44` `model_config = SettingsConfigDict(env_prefix=ENV_PREFIX, extra="ignore")`. The field is therefore settable as `<APP>_WEB_METRICS_ENABLED`.
- `src/py_launch_blueprint/web/app.py:148`–`:149`: `if settings.metrics_enabled:` / `instrument_metrics(app)`.

py is therefore on by default, with an off switch. The F326 row (`docs/port/COMMONALITY.md:330`) says only "Prometheus RED metrics exposed at /metrics, on by default". The words "no env gate" come from the prompt's Context sentence ("exposes Prometheus RED metrics at `/metrics` unconditionally (on by default, no env gate)"), not from the ledger, and that sentence is itself wrong at source.

R77 revision 3 still defines `RSLBP_WEB_METRICS_ENABLED` (`research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md:663`) as a rename of py's field. That is consistent with py. R79's disposition, "the template defines no such variable", contradicts both py and R77, and its stated ground is false.

**Repair.**
- Correct the precedent statement at `:130`–`:146` and the agreement row at `:156`. The row should say that on-by-default must agree, while the presence of an off switch is either shared behaviour or a recorded difference.
- Then do one of the following. This audit does not choose between them; the synthesizer argues the choice.
  - (a) Align with py and R77: a default-true `RSLBP_WEB_METRICS_ENABLED` that skips `instrument()`.
  - (b) Keep no knob as a deliberate departure from py, recorded as `BASELINE-REVIEW: F326 — …` with evidence, and handed to R77 as a coupling.
- Remove "matching py exactly" in either case.
- Controller-side: the prompt's Context sentence "unconditionally (on by default, no env gate)" is contradicted by `settings.py:64` and `app.py:148`. It should be corrected in the prompt so that R77, R78 and later consumers do not inherit it.

### 2. `## Engines` does not reflect the current engine set (JF-3) — blocking

**Failed claims.**
- `:948`–`:951`: "Codex — absent … This Focused item's prompt requires the engines `codex, opus`; one of the two ran."
- `:1030`–`:1031`: "Disagreements between engines: none to settle. With one registered engine there is no inter-engine disagreement."

**Evidence.**
- The live prompt and `inputs/prompt.md` read `- engines: muse, opus`, and "This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot" (`git diff` of the topic prompt: `-codex, opus` → `+muse, opus`).
- `manifest.json` records the 2026-09-21 migration from codex, with `required_engines: ["muse", "opus"]` and `state: partial`. The Muse operation (`request_id d4a2338f…`) is still `submitting`. `scripts/research_scan.py --todo` reports "R79 … collect in-flight: muse (submitting)".
- `raw/muse.md` exists (sha256 `15529e48…c378`, retrieved 2026-09-25) but is uncollected and untracked. The decision cannot represent it and does not.

The Muse report disagrees with the decision on these points:

| # | Topic | Muse report | Decision |
|---|---|---|---|
| i | Metric names | `http_requests_total` / `http_request_duration_seconds` | semconv names |
| ii | Instruments | a labelled request counter plus a histogram | a duration histogram plus the label-free `http_server_unmatched_requests_total` counter; no labelled request counter (`:78`–`:81`) |
| iii | Dependencies | "unconditional (non-optional) dependencies … No env vars, no feature flags" | an optional `metrics` feature |
| iv | Self-exclusion | an explicit path check in the middleware | structural placement |
| v | Status label | status class `4xx`/`5xx` preferred | the raw status code |
| vi | Unmatched routes | a "grouped-pattern fallback" | no fallback, plus a label-free counter |
| vii | RustSec method | pages "retired (404 shell)", with OSV substituted | 404 means no advisory |
| viii | `autometrics` | `stable-quiet` and a gate pass | `dormant` and a gate-2 failure |
| ix | Excluded by gate | "None" (never assesses `prometheus-client`) | three exclusions |
| x | Runner-up (Muse's premise is stale) | conditioned on R69 choosing Axum | R69 has already chosen Axum |

A read-only probe on 2026-09-26 favours the decision on vii: `https://rustsec.org/packages/metrics-util.html` returns HTTP 200 containing `RUSTSEC-2021-0113`, and `metrics.html` returns 404. The pages are therefore not retired. The decision still has to record that adjudication.

**Repair.**
- Collect and register the Muse leg (hash-pin `raw/muse.md` in the manifest).
- Issue revision 3. Its `## Engines` must name Muse and Opus with their report hashes, remove the Codex-absence narrative and the "one registered engine" statement, and adjudicate items i–x with evidence. Point iii bears directly on finding 3.
- Keep the executed-evidence tables. Relabel the "Claims found wrong" table as synthesizer-versus-Opus.

### 3. The on-by-default claim contradicts the packaging, and no BASELINE-REVIEW is raised (JF-2, JF-1)

**Failed claims.**
- `:69`–`:71`: "exposes RED series at `/metrics`, and does so on by default within the enabled web surface. **No `BASELINE-REVIEW:` finding is raised by this item**".
- The decision itself concedes at `:377`–`:380`: "a py user installing `[web]` gets metrics, while an rs user enabling only `--features web` will not."

**Evidence.** The prompt's Context says "This item is on-by-default in the web example … Keep this metrics crate default-enabled unless evidence shows Rust packaging norms require another shape; report any challenge to the inherited direction as `BASELINE-REVIEW: F326` rather than silently changing the owner requirement."

Under the recommended feature graph (`:333`–`:346`), the enabled web surface serves no `/metrics` unless a second feature is turned on. That is a change to the inherited posture. The decision accepts it and repairs it with a README instruction (`:381`–`:384`), without the required marker.

The R69 clause it defers to, "mirroring py's web plus otel extras", does not mirror py for metrics. py ships `prometheus-fastapi-instrumentator>=7.0.0` inside `web` (`pyproject.toml:62`), as the decision itself verified.

**Repair.** Either raise `BASELINE-REVIEW: F326 — on by default — metrics is a separate opt-in above web under R69's value — evidence …`, or record a coupling request to R69, the owner, asking that `web` enable `metrics`. In both cases, stop describing the posture as on by default within the web surface without qualification. Let the controller adjudicate with R69 rather than settling the question through README wording.

### 4. Revision 2's HTTP behaviour was not executed and is not listed as unproven (JF-2)

**Failed claims.**
- `:496`–`:512`: "What the recommendation adds, concretely. Three lines in `instrument()` …", with the `scrape` handler setting `Cache-Control: private, no-cache` and `Content-Type`, and answering `400` on `stream`.
- The "Unproven, and left for P03" list at `:997`–`:1021` omits these behaviours.

**Evidence.** The decision states that `cargo-probes.sh` and its log are byte-identical to revision 1 (`:33`–`:36`). `rest-conformance-r2.sh` asserts only that the decision *text* claims the header and the guard (`claim 'Cache-Control: private, no-cache'` at `:299`, `claim 'stream'` at `:304`); it compiles and runs nothing. No executed check therefore covers the three MOVED behaviours: the R7.1/R7.3 header, the R13.3 `400`, and the declared `Content-Type`.

In addition, `scrape` takes `handle: &'static PrometheusHandle` as a handler parameter. This is reasoning about axum's `Handler` trait, not something I compiled: that type is not an extractor, so `scrape` cannot be passed to `get()` as written. The "three lines in `instrument()`" that would wrap it are not shown. The minimal example at `:323`–`:328` still routes a bare `handle.render()` with no headers.

The prompt requires the decision to "distinguish proposed checks from checks actually run". The RUNBOOK requires that "Configuration, command and version-pin recommendations must execute."

**Repair.** Choose one:
- Add a probe that compiles the revised `instrument()`/`scrape` wiring and asserts three things: `Cache-Control: private, no-cache` on the `200`, a `400` for `GET /metrics?stream=1`, and the `Content-Type` value.
- List all three behaviours under "Unproven" and show the actual routing lines.

### 5. The decision designs against an unpublished R69 revision; its pinned prerequisite is revision 9 (JF-7)

**Failed claim.** `:694`–`:697`: "**Every path in this decision uses revision 10's `crates/web` form** … That is a stated forward dependency, not a conflict". The same applies to the feature graph `web = ["dep:rs-launch-blueprint-web"]` at `:336`.

**Evidence.**
- `inputs/prerequisites.json` pins R69 decision `d4507f5b…`. That hash is the published `research/topics/69-web-framework-stack/DECISION.md`, whose header reads "revision 9".
- The live registry row `web-extra-surface` (`docs/port/PARAMETERS.md:17`) still reads "declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"]", with the gated tree at `src/web/`.
- Revision 10 (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`, sha256 `d34ab6e8…`) is owner-accepted (`OWNER-ACCEPTANCES` row, 2026-09-18). Eight days later it is still unpublished.
- RUNBOOK §4: "A consumer never adopts an unregistered value". §5: acceptance requires "current consumed values and prerequisite decisions".

The decision is candid about all of this. This is therefore an acceptance-gating defect, not a reasoning error.

**Repair.** Choose one:
- Publish R69 revision 10, refresh R79's run inputs so that `prerequisites.json` pins the published revision-10 hash, and re-verify the quoted registry clause (`:682`–`:687`) against the republished row.
- Rewrite the feature graph and paths against the registered revision-9 value.

### 6. "Matches py byte for byte" is false (JF-1, minor)

**Failed claim.** `:560`–`:561`, OV-07(a) option (a): "the endpoint works with every Prometheus server and every `curl`, and matches py byte for byte."

**Evidence.** The decision deliberately adopts semconv names (`http_server_request_duration_seconds`) and drops py's `http_requests_total` counter (`:83`–`:103`). The exposition bytes therefore cannot match py's.

**Repair.** Say that the media type and content type match py's. Do not say the bytes match.

### 7. The validator citations have drifted (JF-4, minor)

**Failed claim.**
- `:673`–`:675` cites `scripts/research_validation.py` "(`:762`–`:766`)" for `expected_assumptions = expected_fixed | expected_consumed` and the "current assumed parameter set does not match" error.
- `:960` cites `_validate_decision_text` at `:489`–`:507`.

**Evidence.** Those lines were correct at the revision-2 commit (`c815b10c`: `:762`, `:764`, `:490`). The current file, changed by `c2e06e81`, has them at `:782`–`:784` and `def _validate_decision_text` at `:510`. The argument itself still holds.

**Repair.** Update the line numbers in revision 3, or cite the function and message names without line numbers.

## Spot-checks that passed (JF-4)

- F326 is quoted verbatim at `COMMONALITY.md:330`, and F303 is at `:307`.
- W2-REST's heading is at `OWNER-REVIEW.md:187`, and the enumeration that omits R79 is at `:198`.
- The OV allocation "OV-07 R79" appears at `execution-ledger.md:1073`.
- For REST standard blob `71bd813c…` (still HEAD's blob at commit `0850d43e`, 3,427 lines), the rules are at the cited lines: R1.5 :219, R1.7 :271, R1.8 :312, R2.1 :447, R3.3 :599, R4.1 :742, R4.10 :846, R4.11 :856, R7.1 :1259, R7.3 :1281, R8.6 :1356, R8.12 :1422, R11.7 :1752, R13.3 :1935, the streaming taxonomy row :2218, and Appendix B :2799/:2803. R4.10's `406` clause is a SHOULD and its default clause carries no BCP 14 keyword, as the decision states.
- py's `excluded_handlers=["/metrics", "/healthz", "/readyz"]` is at `telemetry.py:46`–`:48`, and the instrumentator is in the `web` extra at `pyproject.toml:62`.
- R77's raw report lines :220, :364 and :379 match. R80's raw report lines :166, :357, :1030–:1034 and :1084–:1089 match.
- R69 revision 10's substitution table is at :54–:61, with its `owns` line at :1791.
- `crate-sources.log` holds the registry rows, the `run_upkeep` lines at lib.rs :110 and axum-prometheus :889, and the `opentelemetry-otlp` README steer.
- The attributions to the Opus report are faithful: "34 … all in `src/cow.rs`" at `raw/opus.md:371`/`:580`, 1,256,896→1,617,952 B at `:567`, "≈ +8 s cold" at `:568`, and "only family in which *both* crates declare" at `:356`.
- The owner rulings exist: Q7.B licence ruling at `owner-decisions.md:157`–`:159`, and the strict gate-2 reading at `:452`–`:461`.

## Observation (not a finding)

OV-07(b) reads R8.6 as requiring authentication on `/metrics`. R8.6's text centres on authorizing "every call site that resolves a client-supplied ID", and `/metrics` resolves none, so a narrower reading was available. Recording a MUST-strength deviation and routing it to the owner is a conservative choice that the decision may legitimately take.
