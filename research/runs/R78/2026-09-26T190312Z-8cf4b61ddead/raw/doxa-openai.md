---
prompt: # Deep-research prompt — OpenTelemetry integration (R78, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: how `rs-launch-blueprint`'s web service integrates OpenTelemetry tracing as an opt-in capability whose absence never breaks the service. Item kind: `crate`. Value test: if this answer is wrong, the `otel` Cargo feature's dependency set, the tracing-export code path, and how the service behaves when tracing is unconfigured all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py's web layer imports its OpenTelemetry integration at runtime and degrades to a warning (not a crash) when the `otel` install extra is absent; ts has no web service to compare against. Evidence: py `src/py_launch_blueprint/web/telemetry.py:71` — `except ModuleNotFoundError:` degrades to a warning, not a crash; ts: none (no web service exists in ts; F303). Ledger rows: F325 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); tracing dependencies already ship as a further, separate optional Cargo feature layered beyond the base `web` feature (F304, `ADOPT` — Cargo's native feature layering makes this a nothing-to-choose mechanism, do not redesign it, just pick what lives behind it); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing OpenTelemetry integration.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Take the principles of using Otel and find the best Otel libraries and equivalents for TypeScript and Rust. Implement them there.

### Baseline review (2026-09-04)
- F304 was reclassified `DIVERGENT` under R58, whose `logging-pipeline-contract` includes the optional OTel feature boundary; this item defines the OpenTelemetry integration inside that boundary, and the required web example must not become optional (evidence in `docs/port/BASELINE-REVIEW.md`).

## Out of scope
- Whether the template adopts a web framework at all, and which one; R69 (`web-framework-stack`) owns `web-extra-surface` — this item does not pick a framework, it decides the OTel crate(s) that live behind the `otel` feature.
- Whether Prometheus/RED metrics are adopted and how; R79 (`prometheus-metrics`) owns F326 — this item is tracing-only, not metrics.
- The shared structured-logging pipeline's base architecture (subscriber layering, sinks, log-record shape); R58 (`logging-pipeline-architecture`) owns that — this item is scoped to OTel trace/span export and its integration point with that pipeline, not the pipeline itself.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R78
- owns:
- consumes: R58: logging-pipeline-contract
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (integration guidance; registry dependency above): R58 (`logging-pipeline-architecture`) decides the base `tracing`-crate subscriber pipeline this item's OTel layer plugs into; use the logging architecture that R58 establishes; compare direct OpenTelemetry instrumentation with a bridge from that architecture, and record any required change rather than assuming a specific logging crate.
- related (not a registry dependency): R69 (`web-framework-stack`) owns `web-extra-surface` and picks the framework this item's tracing spans instrument; treat the framework choice as open.
- related (not a registry dependency): R79 (`prometheus-metrics`) is the sibling metrics decision for the same web service; using OpenTelemetry and useful request metrics in the example is shared; coordinate compatible integration boundaries while each item retains its own decision scope.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what Rust crate(s), gated behind an `otel` Cargo feature layered beyond `web`, provide OpenTelemetry tracing integration for the web service, and what happens when tracing is unconfigured or the feature is disabled.
- HIGH: Preserve the named shared requirement: every web example demonstrates OpenTelemetry, with idiomatic libraries and instrumentation for its language. Compare instrumentation at the HTTP boundary, propagation through application work and an outbound request, and the export path. State the API/SDK maturity and version compatibility independently of the maturity of the OpenTelemetry standard.
- HIGH: Define a runnable endpoint acceptance check that starts with an incoming trace context, observes the related server and outbound spans at a collector, correlates the relevant logs, and verifies export/shutdown and unavailable-collector behavior. Coordinate with R58 and R79 so the example works as one system; separate proposed validation from executed evidence.
- HIGH: What are the current, standard OpenTelemetry Rust SDK/exporter crates and the `tracing`-integration bridge crate (candidates: `opentelemetry`, `opentelemetry_sdk`, `opentelemetry-otlp`, `tracing-opentelemetry`), and what is their version-compatibility matrix with each other and with the `tracing`/`tracing-subscriber` ecosystem?
- HIGH: Given Cargo feature-absence is compile-time (code behind an unenabled `otel` feature simply does not exist in the binary), what replaces py's runtime soft-degrade (F325) — is there still a runtime failure mode to guard (e.g. the feature is compiled in but no collector endpoint is configured), and how should that degrade instead of crash the service?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: How does `tracing-opentelemetry` compose as a layer atop a `tracing_subscriber::Registry`, and does adding it require restructuring how the base logging pipeline (owned by R58) is assembled, or is it a pure addition?
- MEDIUM: What exporter transport does the current ecosystem default to (OTLP over gRPC vs. HTTP), and what does that imply for the crate's async-runtime coupling and dependency footprint?
- LOW: What is the binary-size and compile-time cost of the OTel crate set, given they are feature-gated and only paid for when `otel` is enabled?

## Required evidence
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the py and ts precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library already named in this prompt is a research lead, not a closed shortlist. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + source link demonstrating adoption and why the project is a relevant, well-regarded reference |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Dominant choice
### Qualified shortlist
Up to five that passed every gate (fewer is a finding): name · role · 90-day downloads · all-time downloads · stars · last release · maintenance state · notable adopters · one-line trade-off.
### Excluded by gate
### Up-and-comers
### Fit for this template
CLI · library · web, separately.
### Recommendation
### Ranked runner-up
And the condition under which it wins.
### Tradeoffs
What the pick gives up versus each runner-up and why that cost is accepted.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
mode: deep_research
provider: openai
model: gpt-5.6-sol
operation_id: research-20260926-154216-13b4474cda404105
created_at: 2026-09-26T15:42:16.883692
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives.
Organize findings clearly and highlight key insights.

User: # Deep-research prompt — OpenTelemetry integration (R78, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: how `rs-launch-blueprint`'s web service integrates OpenTelemetry tracing as an opt-in capability whose absence never breaks the service. Item kind: `crate`. Value test: if this answer is wrong, the `otel` Cargo feature's dependency set, the tracing-export code path, and how the service behaves when tracing is unconfigured all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py's web layer imports its OpenTelemetry integration at runtime and degrades to a warning (not a crash) when the `otel` install extra is absent; ts has no web service to compare against. Evidence: py `src/py_launch_blueprint/web/telemetry.py:71` — `except ModuleNotFoundError:` degrades to a warning, not a crash; ts: none (no web service exists in ts; F303). Ledger rows: F325 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); tracing dependencies already ship as a further, separate optional Cargo feature layered beyond the base `web` feature (F304, `ADOPT` — Cargo's native feature layering makes this a nothing-to-choose mechanism, do not redesign it, just pick what lives behind it); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing OpenTelemetry integration.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Take the principles of using Otel and find the best Otel libraries and equivalents for TypeScript and Rust. Implement them there.

### Baseline review (2026-09-04)
- F304 was reclassified `DIVERGENT` under R58, whose `logging-pipeline-contract` includes the optional OTel feature boundary; this item defines the OpenTelemetry integration inside that boundary, and the required web example must not become optional (evidence in `docs/port/BASELINE-REVIEW.md`).

## Out of scope
- Whether the template adopts a web framework at all, and which one; R69 (`web-framework-stack`) owns `web-extra-surface` — this item does not pick a framework, it decides the OTel crate(s) that live behind the `otel` feature.
- Whether Prometheus/RED metrics are adopted and how; R79 (`prometheus-metrics`) owns F326 — this item is tracing-only, not metrics.
- The shared structured-logging pipeline's base architecture (subscriber layering, sinks, log-record shape); R58 (`logging-pipeline-architecture`) owns that — this item is scoped to OTel trace/span export and its integration point with that pipeline, not the pipeline itself.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R78
- owns:
- consumes: R58: logging-pipeline-contract
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (integration guidance; registry dependency above): R58 (`logging-pipeline-architecture`) decides the base `tracing`-crate subscriber pipeline this item's OTel layer plugs into; use the logging architecture that R58 establishes; compare direct OpenTelemetry instrumentation with a bridge from that architecture, and record any required change rather than assuming a specific logging crate.
- related (not a registry dependency): R69 (`web-framework-stack`) owns `web-extra-surface` and picks the framework this item's tracing spans instrument; treat the framework choice as open.
- related (not a registry dependency): R79 (`prometheus-metrics`) is the sibling metrics decision for the same web service; using OpenTelemetry and useful request metrics in the example is shared; coordinate compatible integration boundaries while each item retains its own decision scope.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what Rust crate(s), gated behind an `otel` Cargo feature layered beyond `web`, provide OpenTelemetry tracing integration for the web service, and what happens when tracing is unconfigured or the feature is disabled.
- HIGH: Preserve the named shared requirement: every web example demonstrates OpenTelemetry, with idiomatic libraries and instrumentation for its language. Compare instrumentation at the HTTP boundary, propagation through application work and an outbound request, and the export path. State the API/SDK maturity and version compatibility independently of the maturity of the OpenTelemetry standard.
- HIGH: Define a runnable endpoint acceptance check that starts with an incoming trace context, observes the related server and outbound spans at a collector, correlates the relevant logs, and verifies export/shutdown and unavailable-collector behavior. Coordinate with R58 and R79 so the example works as one system; separate proposed validation from executed evidence.
- HIGH: What are the current, standard OpenTelemetry Rust SDK/exporter crates and the `tracing`-integration bridge crate (candidates: `opentelemetry`, `opentelemetry_sdk`, `opentelemetry-otlp`, `tracing-opentelemetry`), and what is their version-compatibility matrix with each other and with the `tracing`/`tracing-subscriber` ecosystem?
- HIGH: Given Cargo feature-absence is compile-time (code behind an unenabled `otel` feature simply does not exist in the binary), what replaces py's runtime soft-degrade (F325) — is there still a runtime failure mode to guard (e.g. the feature is compiled in but no collector endpoint is configured), and how should that degrade instead of crash the service?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: How does `tracing-opentelemetry` compose as a layer atop a `tracing_subscriber::Registry`, and does adding it require restructuring how the base logging pipeline (owned by R58) is assembled, or is it a pure addition?
- MEDIUM: What exporter transport does the current ecosystem default to (OTLP over gRPC vs. HTTP), and what does that imply for the crate's async-runtime coupling and dependency footprint?
- LOW: What is the binary-size and compile-time cost of the OTel crate set, given they are feature-gated and only paid for when `otel` is enabled?

## Required evidence
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the py and ts precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library already named in this prompt is a research lead, not a closed shortlist. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + source link demonstrating adoption and why the project is a relevant, well-regarded reference |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Dominant choice
### Qualified shortlist
Up to five that passed every gate (fewer is a finding): name · role · 90-day downloads · all-time downloads · stars · last release · maintenance state · notable adopters · one-line trade-off.
### Excluded by gate
### Up-and-comers
### Fit for this template
CLI · library · web, separately.
### Recommendation
### Ranked runner-up
And the condition under which it wins.
### Tradeoffs
What the pick gives up versus each runner-up and why that cost is accepted.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
```

## Reasoning Summary
**Considering instrumentation options**

I'm exploring options for instrumentation in OpenTelemetry. I can consider a direct API/SKD approach or the tracing-opentelemetry bridge, which seems dominant. There are also options like axum-tracing-opentelemetry for framework-specific needs. I need to evaluate metrics from tower-otel-http and see how they relate to existing methods. I'm particularly curious about the latest versions, as it seems important to match `tracing-opentelemetry` with `opentelemetry`. I’ll need to investigate the current details further.

### Landscape

**Decision category:** optional distributed-tracing integration for a Rust web service: instrumentation facade → HTTP context propagation → trace SDK/processors → OTLP exporter → collector. The decision is not whether to adopt OpenTelemetry or Cargo feature layering; those are fixed. It is which Rust crates implement tracing inside the `otel` boundary and how every absent or failed telemetry state degrades safely.

#### Three-bin field map

| Bin | Candidates | Finding |
|---|---|---|
| Built-in or first-party toolchain | Cargo features; `tracing`; `tracing-subscriber::Registry` | Rust/Cargo provide the compile-time capability boundary, and `tracing` supplies the ecosystem-standard instrumentation facade, but neither provides an OpenTelemetry SDK or OTLP exporter. |
| Established industry standard | `opentelemetry`, `opentelemetry_sdk`, `opentelemetry-otlp`, `opentelemetry-http`, `tracing-opentelemetry`; framework middleware built on them | This is the dominant standards-based path. The official OpenTelemetry crates implement the API, SDK, propagation helpers, and OTLP export; `tracing-opentelemetry` adapts the existing `tracing` span graph into that SDK. The official project recommends `tracing` as the logging/instrumentation API for new Rust applications. [S1][S4][S5][S7] ([github.com](https://github.com/open-telemetry/opentelemetry-rust?utm_source=openai)) |
| Up-and-comer | `fastrace` plus `fastrace-opentelemetry`; `tracing-otel`; framework-specific helpers such as `axum-tracing-opentelemetry` | `fastrace` is a credible performance-oriented alternate instrumentation stack, while `tracing-otel` and framework helpers reduce setup code. They are poor owners of this template’s base architecture because R58 already establishes a `tracing` pipeline and R69 has not selected a framework. [S16][S17] ([docs.rs](https://docs.rs/crate/tracing-otel/latest?utm_source=openai)) |

#### Authority used

1. **OpenTelemetry Rust maintainers’ repository, release notes, migration guides, API docs, and maintained examples** are primary authorities for component maturity, supported Rust versions, transport defaults, processors, propagation, and shutdown. [S1–S4][S7–S9] ([github.com](https://github.com/open-telemetry/opentelemetry-rust?utm_source=openai))
2. **Tokio’s `tracing-opentelemetry` manifest and releases** are primary authorities for the bridge’s actual version constraints and integration API. [S5][S6] ([docs.rs](https://docs.rs/crate/tracing-opentelemetry/latest/source/Cargo.toml?utm_source=openai))
3. **Rust Release Team and Rust Forge** establish that stable Rust is currently 1.98, making the owner’s “stable minus two” floor Rust 1.96. [S10][S11] ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai))
4. **Rust-project manifests** provide stronger practice evidence than tutorials: current `crates.io` uses the official OpenTelemetry stack, and `rustup` has an optional OpenTelemetry sink. They are well-regarded because both are maintained under the Rust project. [S12][S13] ([github.com](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml?utm_source=openai))
5. Independent indexes were used only for discovery and qualitative ecosystem context, not to override primary documentation or select by download count. [S15][S17] ([rustio.net](https://rustio.net/crate/opentelemetry-otlp?utm_source=openai))

#### Practice evidence

| Project | Evidence | Weight |
|---|---|---|
| `rust-lang/crates.io` | Its current workspace pins `opentelemetry`, `opentelemetry_sdk`, and `opentelemetry-otlp` 0.33.0, demonstrating current Rust-project use of the official stack. Its displayed configuration is metrics-focused, so it is evidence for dependability of the official crates, not for the trace bridge specifically. [S12] ([github.com](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml?utm_source=openai)) | High authority; partial architectural match |
| `rust-lang/rustup` | Its manifest exposes an optional OpenTelemetry sink through a Cargo feature, supporting the compile-time optional-capability pattern. [S13] ([github.com](https://github.com/rust-lang/rustup/blob/master/Cargo.toml?utm_source=openai)) | High authority; CLI rather than web |
| `base/base` | Its current manifest uses the OpenTelemetry 0.32 line and disables default OTLP features, supporting an explicitly selected, minimal feature set. [S14] ([github.com](https://github.com/base/base/blob/main/Cargo.toml?utm_source=openai)) | Current implementation evidence |
| Official HTTP propagation example | The maintained OTel Rust example extracts request headers, creates server spans, and uses `opentelemetry-http` helpers. It uses direct OTel spans rather than the selected bridge, so the underlying propagation pattern is evidence, not a complete winner. [S8] ([github.com](https://github.com/open-telemetry/opentelemetry-rust/blob/main/examples/tracing-http-propagator/src/server.rs?utm_source=openai)) | High authority; architecture reference |

**Required-figure evidence limitation:** the mandatory crates.io and GitHub API URLs were attempted on September 26, 2026, but direct API retrieval was blocked by the research gateway. I have not substituted rounded figures from mirrors because spec §7.6 requires those exact endpoints. Consequently, exact downloads, stars, open-issue counts, and ten-issue response medians are marked `NR` below. This does not affect the version-compatibility finding, but those figures must be collected before the ledger entry is considered evidence-complete. The required API field definitions themselves were verified against the crates.io source. [S25] ([github.com](https://github.com/rust-lang/crates.io/blob/main/crates/crates_io_api_types/src/lib.rs?utm_source=openai))

### Principles and implementation

#### Shared requirement and agreement levels

| Level | Must agree across Python, TypeScript, and Rust | May vary by ecosystem |
|---|---|---|
| Capability | Every web example can demonstrate one distributed trace spanning inbound HTTP, application work, and an outbound request. | Framework middleware and instrumentation syntax. |
| Standard | W3C Trace Context propagation, OpenTelemetry trace semantics, and vendor-neutral OTLP export. | Language SDK package structure and OTLP client implementation. |
| Architectural pattern | Application/library code uses the language’s established instrumentation facade; a separately configured SDK/export layer connects it to OpenTelemetry. | Python decorators/context managers, JS instrumentation packages, or Rust `tracing` spans and subscriber layers. |
| Policy | Telemetry is never a service-correctness dependency. Missing packages/features, absent configuration, invalid configuration, collector outage, and shutdown-export errors do not prevent service start or change an otherwise successful HTTP response. | Python’s runtime import fallback, TypeScript package installation, and Rust’s compile-time feature exclusion. |
| Observable acceptance | The same incoming trace ID reaches the server and outbound spans; logs contain matching correlation identifiers; collector failure is visible but non-fatal; shutdown is bounded and attempts to flush. | Test harness, collector/backend, and log formatter. |

The commonality is therefore **capability + standards + architectural pattern + failure policy**, not agreement on a low-level package-loading mechanism. Python’s runtime `ModuleNotFoundError` fallback is idiomatic for an optional install extra. Rust’s idiomatic equivalent is an uncompiled Cargo feature plus a second, runtime configuration check when the feature is compiled. TypeScript currently lacks the web capability; that is a missing implementation, not evidence that the shared principle should be weakened.

The OpenTelemetry specification is more mature than its Rust tracing implementation: the project states that the overall specification is stable, while the current Rust trace API, trace SDK, and trace OTLP exporter remain Beta. This distinction matters because the standard is safe to align across repositories, while Rust crate APIs still need coordinated version updates. [S1][S20] ([github.com](https://github.com/open-telemetry/opentelemetry-rust/issues/1678?utm_source=openai))

#### Architectural alternatives

| Architecture | Advantages | Problems for this template | Verdict |
|---|---|---|---|
| Direct OpenTelemetry spans throughout application code | Exact OTel semantics; can use the newest 0.33 core line immediately; no bridge translation | Creates a second instrumentation model beside R58’s `tracing`; weakens local-log correlation; library APIs become coupled to an observability SDK; more context-plumbing code | Runner-up |
| `tracing` spans → `tracing-opentelemetry` layer → official OTel SDK/OTLP | One span/event model for local logs and distributed traces; additive subscriber layer; idiomatic `#[instrument]`/`.instrument()` usage; library remains exporter-agnostic | Bridge releases lag the OTel monorepo; some OTel-specific fields/status need explicit bridge conventions | **Selected** |
| Opinionated bootstrap crate such as `tracing-otel` | Very little setup code | Owns subscriber initialization, logging outputs, and policy already assigned to R58; hides feature selection and failure behavior | Excluded by architectural ownership |
| `fastrace` plus its OTel adapter | Focused low-overhead tracing implementation | Replaces rather than extends R58’s `tracing` architecture; duplicates logging context; performance evidence is not directly comparable to this workload | Excluded unless R58 changes |

No comparable benchmark was found that measures these alternatives under this template’s workload—one server span, application spans, outbound propagation, JSON logging, batch OTLP export, and collector failure. Therefore no “fastest” claim is used. The planned benchmark is specified under Validation.

#### Current compatibility matrix — September 26, 2026

| Integration line | Compatible OpenTelemetry line | `tracing` ecosystem | Status |
|---|---|---|---|
| `tracing-opentelemetry = "0.33"` | `opentelemetry = "0.32"` | `tracing >=0.1.35,<0.2`; `tracing-subscriber >=0.3.22,<0.4` | Current released bridge; selected |
| `tracing-opentelemetry = "0.32"` | OpenTelemetry 0.31 | `tracing` 0.1 / `tracing-subscriber` 0.3 | Previous compatible line |
| `tracing-opentelemetry = "0.31"` | OpenTelemetry 0.30 | `tracing` 0.1 / `tracing-subscriber` 0.3 | Previous compatible line |
| Direct OTel, no bridge | OpenTelemetry 0.33 | Independent of `tracing-opentelemetry` | Current official core, but creates two instrumentation systems |

The critical finding is that **equal-looking versions are not compatible versions**: `tracing-opentelemetry` 0.33.0 depends on `opentelemetry` 0.32.0, while the official OTel crates released 0.33.0 on September 18, 2026. Selecting OTel 0.33 alongside the current bridge would resolve two incompatible `opentelemetry` versions and produce type/context mismatches. [S5][S6][S23] ([docs.rs](https://docs.rs/crate/tracing-opentelemetry/latest/source/Cargo.toml?utm_source=openai))

#### Recommended full composition

1. **Compile-time boundary**
   - `otel` implies `web` and enables all five optional dependencies.
   - With `otel` disabled, no OpenTelemetry crate is present in the dependency graph or binary.
   - The web example itself remains gated only by `web`, satisfying the baseline requirement that the example not become optional.

2. **Runtime activation**
   - Treat tracing export as requested only when `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` or `OTEL_EXPORTER_OTLP_ENDPOINT` is set.
   - Respect `OTEL_SDK_DISABLED=true`.
   - Do not silently use the exporter’s standard implicit `localhost:4318` default in the template. Requiring an explicit endpoint prevents a build made with `otel` from continuously attempting an unintended local collector.
   - If endpoint variables are present in a binary built without `otel`, emit one warning that the configuration is ignored, then continue.

3. **Exporter and SDK**
   - Use OTLP over HTTP/protobuf, port 4318, with the blocking reqwest/rustls client.
   - Build a bounded batch span processor and configure a short exporter timeout.
   - Do not enable metrics or OTel log export in R78.
   - Do not enable experimental retry features by default; collector/agent deployment should provide retry and buffering beyond the process.

   Since OTel Rust 0.28, HTTP/protobuf plus the blocking client is the default transport direction, and the normal batch processor runs independently of an application async runtime. By contrast, `grpc-tonic` requires Tokio context for exporter creation and adds tonic-specific dependencies. [S2][S3][S4] ([github.com](https://github.com/open-telemetry/opentelemetry-rust/blob/main/docs/release_0.32.md?utm_source=openai))

4. **Subscriber layer**
   - Construct `tracing_opentelemetry::layer().with_tracer(tracer)`.
   - Add it as an `Option<Layer>` to the `tracing_subscriber::Registry` assembled by R58.
   - Do not initialize a second subscriber.
   - If R58 currently calls `.init()` internally with no extension point, it needs a narrow optional-layer hook; otherwise this is a pure addition.

5. **Inbound HTTP**
   - Extract `traceparent`/`tracestate` with `TraceContextPropagator` and `opentelemetry_http::HeaderExtractor`.
   - Construct a low-cardinality server span using the matched route template, not the raw URI.
   - Call `OpenTelemetrySpanExt::set_parent` **before** entering or instrumenting the span.
   - Instrument the request future rather than retaining an entered span guard across `.await`.
   - Record method, route, status, error, server address, and bridge-recognized server-span kind.

   Creating the span before entering it avoids the currently documented difficulty of changing the OTel parent of an already-entered `#[instrument]` span. [S7][S8][S18] ([docs.rs](https://docs.rs/crate/opentelemetry-http/latest/source/src/lib.rs?utm_source=openai))

6. **Application work and outbound HTTP**
   - Application/library functions use ordinary `tracing` spans and `#[instrument]`, with secrets and large payloads skipped.
   - The outbound client wrapper creates a client span, obtains its OTel context through `OpenTelemetrySpanExt::context`, injects it with `HeaderInjector`, and instruments the request future.
   - Client span names and attributes exclude query strings, credentials, and uncontrolled path-cardinality.

7. **Log correlation**
   - Predeclare `trace_id` and `span_id` fields on the request span.
   - After the OTel parent is set, read the span context and record those IDs.
   - R58’s JSON formatter must include current-span fields or explicit trace/span IDs on events.
   - R78 does **not** add `opentelemetry-appender-tracing`; exporting logs is outside this tracing-only decision.

8. **Shutdown**
   - A service-owned `TelemetryGuard` holds the `SdkTracerProvider`.
   - On graceful server termination, attempt `force_flush`, then bounded provider shutdown.
   - Flush or shutdown failure emits a warning but does not change an otherwise successful service exit status. The SDK exposes explicit force-flush and shutdown APIs. [S9] ([docs.rs](https://docs.rs/opentelemetry_sdk/latest/opentelemetry_sdk/trace/struct.SdkTracerProvider.html?utm_source=openai))

#### Failure-state contract

| State | Required behavior |
|---|---|
| `otel` feature disabled, no OTel environment | Start normally; no telemetry warning; no OTel dependencies. |
| `otel` disabled, OTel endpoint configured | Start normally; one warning that the binary lacks the feature. |
| `otel` enabled, endpoint absent | Install only R58’s base logging pipeline; one warning that OTel export is unconfigured. |
| `OTEL_SDK_DISABLED=true` | Disable quietly or at info level; no exporter. |
| Invalid endpoint/TLS/exporter configuration | Log one warning after the base subscriber is installed; omit the OTel layer; continue serving. |
| Collector unavailable after startup | Requests continue normally; batches time out or are dropped within bounded resources; internal exporter diagnostics are logged. |
| Queue full | Drop telemetry rather than blocking request handling; expose the condition through diagnostics. |
| Flush/shutdown error | Warn and exit normally after the configured shutdown bound. |

**BASELINE-REVIEW: F325 — optional observability must soft-degrade without becoming a service dependency — replace Python’s runtime import fallback with Rust’s compile-time feature exclusion plus runtime exporter activation/fallback; warn once and continue for absent feature, absent configuration, initialization failure, collector failure, and shutdown failure — Cargo’s native optional dependency boundary, the runtime-independent HTTP/batch architecture, and Python’s existing warning-not-crash behavior preserve the same policy while using ecosystem-appropriate mechanisms.**

This affects R78 only. It does not alter F304/R58’s feature boundary, choose R69’s framework, or enable R79’s metrics.

#### Observable acceptance criteria

A runnable test must prove:

1. An explicit incoming `traceparent` determines the server trace ID and parent span ID.
2. The server, internal-work, outbound client, and downstream server spans share that trace ID and have the expected parent chain.
3. The service JSON log for the request contains the same `trace_id` and the relevant current `span_id`.
4. The collector receives all completed spans after graceful shutdown.
5. Feature-disabled and runtime-unconfigured builds both serve successfully.
6. An unreachable collector does not change HTTP status, readiness, or service exit success.
7. Trace export and Prometheus metrics can coexist without duplicate request wrapping; R78 and R79 share route classification but own separate layers.

These are proposed acceptance checks; no repository build or collector test was executed during this research run.

### Dominant choice

**Dominant named crate:** `tracing-opentelemetry = "0.33"`.

**Required compatible support bundle:**

- `opentelemetry = "0.32"`
- `opentelemetry_sdk = "0.32"`
- `opentelemetry-otlp = "0.32"`
- `opentelemetry-http = "0.32"`
- `tracing-opentelemetry = "0.33"`

This is the only option that preserves R58’s single `tracing` instrumentation model, uses the official OpenTelemetry SDK and production-recommended OTLP exporter, remains framework-neutral for R69, and allows the exporter to be omitted or disabled without affecting the service.

### Qualified shortlist

`NR` means the exact mandatory API result was not retrievable; a rounded mirror value was deliberately not substituted.

| Name | Role | 90-day downloads | All-time downloads | Stars | Last non-yanked release | Maintenance | Notable evidence/adopters | Trade-off |
|---|---|---:|---:|---:|---|---|---|---|
| `tracing-opentelemetry >=0.33,<0.34` | Bridge from R58’s spans to OTel | NR | NR | NR | 0.33.0, 2026-05-18 | active | Maintained in Tokio organization; required by multiple framework integrations. [S5][S6] ([docs.rs](https://docs.rs/crate/tracing-opentelemetry/latest/source/Cargo.toml?utm_source=openai)) | Lags the official OTel monorepo by one compatibility line. |
| `opentelemetry >=0.32,<0.33` | API/context/propagation types | NR | NR | NR | Current upstream 0.33.0; selected line 0.32.x | active | Rust `crates.io`, `base/base`; official OTel implementation. [S1][S12][S14] ([github.com](https://github.com/open-telemetry/opentelemetry-rust?utm_source=openai)) | Selected version is intentionally one line behind latest. |
| `opentelemetry_sdk >=0.32,<0.33` | Tracer provider, processors, resources | NR | NR | NR | 0.33.0, 2026-09-18; selected resolves 0.32.1 | active | Rust `crates.io`; official maintained SDK. [S12][S23] ([github.com](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml?utm_source=openai)) | Adds batching, queues, resource configuration, and meaningful compile cost. |
| `opentelemetry-otlp >=0.32,<0.33` | OTLP/HTTP trace exporter | NR | NR | NR | Current upstream 0.33.0; selected line 0.32.x | active | `crates.io`, optional `rustup` sink, `base/base`; official production exporter. [S4][S12–S14] ([docs.rs](https://docs.rs/crate/opentelemetry-otlp/latest/source/src/lib.rs?utm_source=openai)) | Pulls protobuf plus an HTTP/TLS stack; feature selection is essential. |
| `opentelemetry-http >=0.32,<0.33` | Safe header extraction/injection helpers | NR | NR | NR | Current upstream 0.33.0; selected line 0.32.x | active | Used by the official maintained HTTP propagation example. [S7][S8] ([docs.rs](https://docs.rs/crate/opentelemetry-http/latest/source/src/lib.rs?utm_source=openai)) | Small extra crate; avoids bespoke header adapters. |

#### Fitness gates

| Gate | Result |
|---|---|
| License | Pass: official OTel crates are Apache-2.0; `tracing-opentelemetry` is MIT-compatible. |
| MSRV | Pass at direct-crate level: selected crates declare Rust 1.75, well below the current required floor of Rust 1.96. The exact resolved dependency tree still must be compiled with `cargo +1.96.0`. [S1][S5][S10][S11] ([github.com](https://github.com/open-telemetry/opentelemetry-rust?utm_source=openai)) |
| RustSec | Provisional pass: no package-specific open advisory was identified in the survey. `cargo audit` against the resolved lockfile is mandatory before merge because the RustSec package pages could not be retrieved directly. |
| Unsafe posture | The template integration requires no user-written `unsafe`. Network, TLS, and synchronization transitive dependencies may contain audited unsafe code; verify the resolved tree with `cargo geiger` if the project records unsafe counts. |
| Ubuntu/macOS | Architectural pass: HTTP/protobuf plus rustls avoids an application-level OpenSSL requirement. The template must execute both feature combinations on `ubuntu-latest` and `macos-latest`. Windows is supported upstream but is not an owner-required matrix target. |
| Default features/runtime | Pass with the recommended explicit feature set. No metrics/log signals; no `grpc-tonic`; no application Tokio-runtime coupling for the batch exporter. |
| Binary and compile cost | Medium-to-high when enabled, principally from SDK, protobuf, reqwest, rustls, and HTTP dependencies; zero OTel cost when `otel` is disabled. The official SDK package itself is substantial, and the OTLP stack has a broad dependency tree. [S15][S23] ([rustio.net](https://rustio.net/crate/opentelemetry-otlp?utm_source=openai)) |

**Maintenance evidence gap:** exact open-issue counts and median first-maintainer response for the latest ten issues are `NR` because the required GitHub Search API was inaccessible. Both repositories are nevertheless classified `active`: the OTel core released 0.33.0 on September 18, 2026, and the bridge released 0.33.0 on May 18, 2026—both within six months. [S6][S23] ([github.com](https://github.com/tokio-rs/tracing-opentelemetry/releases?utm_source=openai))

### Excluded by gate

1. **`opentelemetry* = "0.33"` plus `tracing-opentelemetry = "0.33"`**
   - **Failed gate:** version compatibility.
   - The bridge’s manifest requires OTel 0.32. Cargo can install both 0.32 and 0.33, but their contexts, tracers, and traits are different Rust types. [S5] ([docs.rs](https://docs.rs/crate/tracing-opentelemetry/latest/source/Cargo.toml?utm_source=openai))

2. **`tracing-otel = "0.33"` as the integration owner**
   - **Failed gate:** architectural ownership.
   - It is a current convenience layer, but its `logger` feature intentionally initializes tracing, metrics, optional OTel logs, console output, and file output. That overlaps R58 and R79 rather than plugging into them. [S16] ([docs.rs](https://docs.rs/crate/tracing-otel/latest?utm_source=openai))

3. **`fastrace` plus `fastrace-opentelemetry`**
   - **Failed gate:** consumed architecture.
   - It is an active, credible tracing system with an edition-2024/MSRV-compatible current release, but it replaces the R58 `tracing` pipeline rather than adding a layer. Its performance claims are not sufficient to override the single-pipeline principle without a representative benchmark. [S17] ([rustio.net](https://rustio.net/crate/fastrace?utm_source=openai))

4. **Framework-specific middleware as the mandatory R78 crate**
   - **Failed gate:** framework neutrality and ownership.
   - `axum-tracing-opentelemetry`, `tracing-actix-web`, and similar packages may become useful after R69 selects a framework, but making one the core dependency would silently decide R69.

5. **Jaeger- or Zipkin-specific exporters**
   - **Failed gate:** current authoritative guidance.
   - Current OTel Rust guidance directs applications toward OTLP; the 0.32 release deprecated the Zipkin exporter and Jaeger propagator in favor of OTLP and W3C Trace Context. [S2] ([github.com](https://github.com/open-telemetry/opentelemetry-rust/blob/main/docs/release_0.32.md?utm_source=openai))

### Up-and-comers

- **`fastrace` / `fastrace-opentelemetry`:** strongest alternative instrumentation architecture. It wins only if R58 is reopened and representative template benchmarks show that bridge overhead or allocation is unacceptable.
- **`tracing-otel`:** useful for small applications wanting one-call initialization. It should remain a reference for ergonomics, not become the template dependency because it owns too much policy.
- **Framework middleware:** once R69 chooses a framework, evaluate its current maintained request instrumentation middleware against the generic acceptance test. Such middleware may replace custom inbound boilerplate, but not the core SDK/export bundle.
- **Automatic outbound-client middleware:** similarly, a future R69-selected HTTP client may have a maintained propagation layer. It can be adopted behind the same abstraction if it emits the required client span and W3C headers without taking subscriber ownership.

### Fit for this template

**CLI**

- Ordinary CLI and library commands retain R58’s local structured logging only.
- The `otel` feature implies `web`; a non-server command does not initialize an exporter merely because the binary was compiled with the feature.
- CLI startup and exit are not delayed by collector discovery.

**Library**

- Library code depends only on `tracing`, not on OpenTelemetry SDK/exporter types.
- It emits semantic, low-cardinality spans and events but never installs a global subscriber, reads OTel environment variables, or owns shutdown.
- Consumers that do not use the template’s web binary can install another subscriber/exporter.

**Web service**

- The binary owns exporter configuration, subscriber composition, propagator setup, HTTP middleware, and shutdown.
- Incoming, application, and outbound spans use one `tracing` graph.
- Runtime configuration or collector failure cannot change endpoint correctness.
- R79 can attach metrics beside the tracing middleware, using the same matched-route classification but a separate metrics registry/export path.

### Recommendation

Adopt the following dependency ranges behind `otel`, using explicit features:

```toml
[features]
default = []
web = [
    # R69-owned web dependencies
]
otel = [
    "web",
    "dep:opentelemetry",
    "dep:opentelemetry_sdk",
    "dep:opentelemetry-otlp",
    "dep:opentelemetry-http",
    "dep:tracing-opentelemetry",
]

[dependencies]
opentelemetry = {
    version = "0.32",
    optional = true,
    default-features = false,
    features = ["trace"],
}

opentelemetry_sdk = {
    version = "0.32",
    optional = true,
    default-features = false,
    features = ["trace"],
}

opentelemetry-otlp = {
    version = "0.32",
    optional = true,
    default-features = false,
    features = [
        "trace",
        "http-proto",
        "reqwest-blocking-client",
        "reqwest-rustls",
        "internal-logs",
    ],
}

opentelemetry-http = {
    version = "0.32",
    optional = true,
    default-features = false,
}

tracing-opentelemetry = {
    version = "0.33",
    optional = true,
    default-features = false,
}
```

Use OTLP/HTTP protobuf to an explicitly configured endpoint, normally `http://collector:4318`. HTTP signal paths such as `/v1/traces` are appended according to exporter endpoint rules. Do not point the HTTP exporter at the default gRPC port 4317. [S4] ([docs.rs](https://docs.rs/opentelemetry-otlp/latest/src/opentelemetry_otlp/lib.rs.html?utm_source=openai))

Implement a feature-neutral service facade:

```rust
pub enum TelemetryState {
    Disabled(DisableReason),
    Enabled(TelemetryGuard),
}
```

Its external contract is:

- `prepare_otel(config) -> Result<Option<OtelParts>, TelemetryInitError>`
- R58 assembles its registry with the optional returned layer.
- After subscriber initialization, the binary logs any non-fatal initialization warning.
- `TelemetryGuard::shutdown(timeout)` attempts flush and shutdown but returns diagnostics, not a service-fatal error.
- The non-`otel` implementation contains no OTel imports and returns `Disabled(FeatureAbsent)`.

**Do not call `expect`, `unwrap`, or propagate an exporter error from the service’s startup result.** Only failures in the base logging or web-service initialization may remain startup-fatal.

### Ranked runner-up

1. **Direct OpenTelemetry 0.33 instrumentation**
   - Wins if R58 is changed away from `tracing`, or if a required feature exists only in OTel 0.33 and cannot wait for a compatible bridge release.
   - It should then be adopted consistently, not mixed ad hoc with `tracing` spans.

2. **Selected bridge stack with `grpc-tonic` instead of HTTP**
   - Wins if the mandated collector/backend accepts only OTLP/gRPC, or if the service already standardizes on tonic and accepts Tokio-coupled exporter creation and the larger transport graph.
   - It does not change the failure policy, propagation requirements, or subscriber architecture.

### Tradeoffs

| Compared with | What the recommendation gives up | Why accepted |
|---|---|---|
| Direct OTel 0.33 | Immediate access to the newest OTel Rust line and exact native OTel span APIs | One instrumentation graph and log correlation are more important for this template; reverify when the bridge updates. |
| `grpc-tonic` | Streaming gRPC transport and some backend-specific deployment conventions | HTTP/protobuf is the current default direction, is easier to test, and does not require application async-runtime coupling. |
| Opinionated bootstrap crates | Less initialization boilerplate | Explicit assembly preserves R58 ownership and makes every degrade path testable. |
| Framework-specific middleware | Potentially less HTTP instrumentation code | R69 remains open; the core decision must be framework-neutral. |
| Implicit localhost endpoint | Out-of-the-box export merely from compiling the feature | Explicit activation prevents surprise connection attempts and best preserves the Python soft-degrade principle. |
| Automatic retries | In-process retry resilience during collector outages | Bounded failure is safer for a general template; local collectors/agents should buffer and retry. |
| Feature-disabled propagation | A build without `otel` does not continue distributed trace headers | This is the expected cost of a truly absent capability; service behavior remains correct and dependency-free. |

### Parameters

`owns R78.otel-integration-crate = tracing-opentelemetry >=0.33,<0.34`

`owns R78.otel-official-stack = opentelemetry >=0.32,<0.33; opentelemetry_sdk >=0.32,<0.33; opentelemetry-otlp >=0.32,<0.33; opentelemetry-http >=0.32,<0.33`

`owns R78.otel-export-transport = OTLP over HTTP/protobuf, blocking reqwest client, rustls, explicit endpoint`

`owns R78.otel-runtime-policy = feature absent/unconfigured/init failure/collector failure/shutdown failure are non-fatal and diagnostically visible`

`owns R78.otel-propagation = W3C Trace Context on inbound and outbound HTTP`

`assumes R58.logging-pipeline-contract = one tracing_subscriber::Registry-based pipeline with an optional Layer extension point and JSON trace/span-ID correlation`

`assumes R69.web-extra-surface = selected framework exposes request headers, matched route, response status, middleware/future instrumentation, and an outbound HTTP client`

`assumes R79.prometheus-metrics = metrics remain outside the OTel crate features selected by R78; request route classification is shared without duplicate middleware`

`assumes rust-edition = 2024`

`assumes rust-version = 1.96 while stable Rust is 1.98; raised only under the owner’s minor-release policy`

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

No parameter conflict identified.

### Migration implications

1. **`Cargo.toml`**
   - Add the five optional dependencies and `otel = ["web", ...]`.
   - Keep the web example’s `required-features` as `["web"]`, not `["otel"]`.
   - Group the five dependencies for automated updates so incompatible lines are not upgraded independently.

2. **`src/telemetry.rs`**
   - Define the feature-neutral `TelemetryState`, disable reasons, configuration parsing, and lifecycle contract.
   - Provide `cfg(feature = "otel")` and `cfg(not(feature = "otel"))` implementations.

3. **`src/telemetry/otel.rs`**
   - Build resource, exporter, tracer provider, tracer, and bridge layer.
   - Set the Trace Context propagator.
   - Own provider flush/shutdown.
   - Convert all setup errors into `TelemetryInitError`; no panic paths.

4. **R58 logging assembly file**
   - Accept an optional OTel layer before calling `.init()`.
   - Ensure JSON output contains current-span fields or explicit `trace_id`/`span_id`.
   - Preserve independent filtering for local logs and exported spans where needed.

5. **`src/web/trace_context.rs`**
   - Centralize `HeaderExtractor`/`HeaderInjector`, parent assignment, ID recording, and outbound injection.
   - Keep framework-specific adapters thin.

6. **`src/web/middleware.rs`**
   - Create the server span after route matching where the framework permits.
   - Set remote parent before instrumenting the future.
   - Record response status and error outcome.

7. **Outbound client module**
   - Wrap the R69-selected client with client-span creation and context injection.
   - Ensure redirects and retries have documented span behavior.

8. **Server binary**
   - Parse telemetry activation before subscriber initialization.
   - Assemble one subscriber.
   - Hold the guard through server lifetime.
   - Invoke bounded telemetry shutdown after graceful web shutdown.

9. **Required web example**
   - Include `/demo` performing instrumented application work and calling `/downstream`.
   - Run without OTel under `--features web`.
   - Demonstrate distributed export under `--features web,otel`.

10. **Documentation**
    - Document feature build commands, endpoint variables, HTTP port 4318, non-fatal modes, sampling guidance, and collector troubleshooting.
    - Clearly state that compiling `otel` does not by itself activate export.

11. **CI and tests**
    - Add no-feature, `web`, and `web,otel` jobs.
    - Run both required feature combinations on Ubuntu and macOS.
    - Add a Linux collector integration job for the full trace assertion.

### Validation strategy

#### Executed during research

- Inspected current official manifests, release notes, migration guides, API documentation, maintained examples, Rust release data, and selected adopter manifests.
- Did **not** build `rs-launch-blueprint`, run a collector, inspect its dependency tree, or execute benchmarks because the repository was not supplied.
- Did **not** complete the mandated crates.io/GitHub numeric API audit because those direct endpoints were inaccessible to the research gateway.

#### Planned static and compile validation

```bash
rustup toolchain install 1.96.0

cargo +1.96.0 check \
  --locked \
  --all-targets \
  --no-default-features \
  --features web

cargo +1.96.0 check \
  --locked \
  --all-targets \
  --no-default-features \
  --features web,otel

cargo test \
  --locked \
  --all-targets \
  --no-default-features \
  --features web

cargo test \
  --locked \
  --all-targets \
  --no-default-features \
  --features web,otel

cargo clippy \
  --locked \
  --all-targets \
  --no-default-features \
  --features web,otel \
  -- -D warnings
```

Prove feature absence:

```bash
if cargo tree \
  --locked \
  --no-default-features \
  --features web \
  -e normal |
  grep -E '(^| )opentelemetry(_sdk|-otlp|-http)? |tracing-opentelemetry'
then
  echo "OpenTelemetry dependency leaked into base web feature" >&2
  exit 1
fi
```

Prove one compatible OTel line:

```bash
cargo tree \
  --locked \
  --no-default-features \
  --features web,otel \
  -i opentelemetry

cargo tree \
  --locked \
  --no-default-features \
  --features web,otel \
  -d
```

Expected: one `opentelemetry` 0.32 line, with `tracing-opentelemetry` 0.33; no OTel 0.33 duplicate.

Security and license:

```bash
cargo audit
cargo deny check advisories bans licenses sources
```

#### Planned end-to-end collector check

Run an OpenTelemetry Collector with:

- OTLP/HTTP receiver on `0.0.0.0:4318`;
- batch processor;
- deterministic file exporter for assertions.

Start the example:

```bash
export OTEL_SERVICE_NAME=rs-launch-blueprint
export OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318
export RUST_LOG=info

cargo run \
  --locked \
  --no-default-features \
  --features web,otel \
  --bin rs-launch-blueprint \
  -- serve \
  > target/service.jsonl 2>&1 &
server_pid=$!
```

Send a fixed remote parent:

```bash
trace_id=4bf92f3577b34da6a3ce929d0e0e4736
parent_id=00f067aa0ba902b7

curl --fail-with-body \
  -H "traceparent: 00-${trace_id}-${parent_id}-01" \
  http://127.0.0.1:3000/demo
```

The collector assertion must verify:

- `/demo` server span has trace ID `$trace_id`;
- its parent span ID is `$parent_id`;
- internal work span is its child;
- outbound client span is in the same trace;
- `/downstream` server span has the outbound client span as parent;
- server/client span kinds and HTTP route/status attributes are correct;
- no raw query string, authorization header, or request body is exported.

Log assertion:

```bash
jq -e \
  --arg trace_id "$trace_id" \
  'select(.trace_id == $trace_id and .message == "demo request completed")' \
  target/service.jsonl
```

Graceful shutdown:

```bash
kill -TERM "$server_pid"
wait "$server_pid"
test "$?" -eq 0
```

After shutdown, verify the final request spans appear in the collector file within the configured shutdown bound.

#### Planned soft-degrade checks

Feature disabled:

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318 \
cargo run \
  --no-default-features \
  --features web \
  --bin rs-launch-blueprint \
  -- serve
```

Expected: service starts, endpoint returns success, one “OTel configuration ignored; feature absent” warning.

Feature enabled but unconfigured:

```bash
env \
  -u OTEL_EXPORTER_OTLP_ENDPOINT \
  -u OTEL_EXPORTER_OTLP_TRACES_ENDPOINT \
  cargo run \
    --no-default-features \
    --features web,otel \
    --bin rs-launch-blueprint \
    -- serve
```

Expected: service starts, exactly one “OpenTelemetry disabled: no OTLP endpoint configured” warning, and no repeated connection errors.

Collector unavailable:

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:9 \
timeout 20s cargo run \
  --no-default-features \
  --features web,otel \
  --bin rs-launch-blueprint \
  -- serve
```

While running, call `/demo`. Expected:

- HTTP response remains successful;
- local JSON logs remain present;
- exporter failure is visible;
- memory remains bounded;
- SIGTERM completes within the configured shutdown timeout;
- process exit remains successful.

#### Planned representative cost measurement

Build and benchmark these configurations in release mode:

1. `web`;
2. `web,otel`, runtime export disabled;
3. `web,otel`, local collector, 100% sampling;
4. `web,otel`, unavailable collector.

Workload:

- 1 KiB response;
- one server span, two internal spans, one outbound client span;
- 100 concurrent connections;
- fixed one-minute warm-up and five-minute measurement;
- same machine and compiler.

Record:

- throughput;
- p50/p95/p99 latency;
- CPU and peak RSS;
- dropped-span/export-error count;
- clean-build and incremental-build time;
- stripped binary size.

Commands should include:

```bash
cargo build --release --timings --no-default-features --features web
cargo build --release --timings --no-default-features --features web,otel

cargo bloat --release --no-default-features --features web -n 50
cargo bloat --release --no-default-features --features web,otel -n 50
```

No absolute performance conclusion should be entered into the ledger until these like-for-like results exist.

### Confidence & re-verify trigger

**Confidence: high in the architectural pattern and failure policy; medium-high in the selected version line.**

The version confidence is not “high” because OpenTelemetry Rust 0.33.0 was released only eight days before this decision, on September 18, 2026, while the latest bridge still targets 0.32. [S5][S23] ([docs.rs](https://docs.rs/crate/tracing-opentelemetry/latest/source/Cargo.toml?utm_source=openai))

Re-verify when any of the following occurs:

1. `tracing-opentelemetry` releases a version compatible with OTel 0.33 or newer;
2. OTel Rust declares its trace API/SDK/exporter stable;
3. R58 stops using a `tracing_subscriber::Registry` pipeline or lacks an optional-layer extension point;
4. R69 selects a framework/client with maintained first-party OTel middleware;
5. R79 proposes sharing an OTel provider or enabling OTel metrics;
6. the selected OTLP HTTP client creates duplicate major reqwest/hyper/TLS stacks with R69’s client;
7. Rust stable advances enough that the owner’s MSRV floor changes;
8. `cargo audit`, `cargo deny`, Ubuntu CI, or macOS CI fails;
9. the mandatory crates.io/GitHub API metric audit materially changes the maintenance assessment.

Before final ledger merge, rerun the exact API figure collection and ten-issue responsiveness calculation. That missing numeric evidence is the principal remaining research gap.

### Sources

All web sources retrieved **September 26, 2026**.

- **[S1] OpenTelemetry Rust repository — component status, crate roles, MSRV, and `tracing` recommendation.**  
  `https://github.com/open-telemetry/opentelemetry-rust` ([github.com](https://github.com/open-telemetry/opentelemetry-rust?utm_source=openai))
- **[S2] OpenTelemetry Rust 0.32 release notes — maturity, exporter changes, and deprecations.**  
  `https://github.com/open-telemetry/opentelemetry-rust/blob/main/docs/release_0.32.md` ([github.com](https://github.com/open-telemetry/opentelemetry-rust/blob/main/docs/release_0.32.md?utm_source=openai))
- **[S3] OpenTelemetry Rust 0.28 migration — HTTP default and runtime-independent processors.**  
  `https://github.com/open-telemetry/opentelemetry-rust/blob/main/docs/migration_0.28.md` ([github.com](https://github.com/open-telemetry/opentelemetry-rust/blob/main/docs/migration_0.28.md?utm_source=openai))
- **[S4] `opentelemetry-otlp` current source documentation — transports, features, protocols, ports, and endpoints.**  
  `https://docs.rs/crate/opentelemetry-otlp/latest/source/src/lib.rs` ([docs.rs](https://docs.rs/crate/opentelemetry-otlp/latest/source/src/lib.rs?utm_source=openai))
- **[S5] `tracing-opentelemetry` 0.33.0 manifest — exact OTel/tracing/subscriber constraints and MSRV.**  
  `https://docs.rs/crate/tracing-opentelemetry/latest/source/Cargo.toml` ([docs.rs](https://docs.rs/crate/tracing-opentelemetry/latest/source/Cargo.toml?utm_source=openai))
- **[S6] `tracing-opentelemetry` releases.**  
  `https://github.com/tokio-rs/tracing-opentelemetry/releases` ([github.com](https://github.com/tokio-rs/tracing-opentelemetry/releases?utm_source=openai))
- **[S7] `opentelemetry-http` source — `HeaderExtractor` and `HeaderInjector`.**  
  `https://docs.rs/crate/opentelemetry-http/latest/source/src/lib.rs` ([docs.rs](https://docs.rs/crate/opentelemetry-http/latest/source/src/lib.rs?utm_source=openai))
- **[S8] Official OpenTelemetry Rust HTTP propagation server example.**  
  `https://github.com/open-telemetry/opentelemetry-rust/blob/main/examples/tracing-http-propagator/src/server.rs` ([github.com](https://github.com/open-telemetry/opentelemetry-rust/blob/main/examples/tracing-http-propagator/src/server.rs?utm_source=openai))
- **[S9] `SdkTracerProvider` API — force flush and provider lifecycle.**  
  `https://docs.rs/opentelemetry_sdk/latest/opentelemetry_sdk/trace/struct.SdkTracerProvider.html` ([docs.rs](https://docs.rs/opentelemetry_sdk/latest/opentelemetry_sdk/trace/struct.SdkTracerProvider.html?utm_source=openai))
- **[S10] Rust 1.98.0 release announcement.**  
  `https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/` ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai))
- **[S11] Rust Forge current release channels.**  
  `https://forge.rust-lang.org/` ([forge.rust-lang.org](https://forge.rust-lang.org/?utm_source=openai))
- **[S12] Current crates.io workspace manifest.**  
  `https://github.com/rust-lang/crates.io/blob/main/Cargo.toml` ([github.com](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml?utm_source=openai))
- **[S13] Current rustup manifest and optional OTel feature.**  
  `https://github.com/rust-lang/rustup/blob/master/Cargo.toml` ([github.com](https://github.com/rust-lang/rustup/blob/master/Cargo.toml?utm_source=openai))
- **[S14] Current `base/base` manifest using OTel 0.32.**  
  `https://github.com/base/base/blob/main/Cargo.toml` ([github.com](https://github.com/base/base/blob/main/Cargo.toml?utm_source=openai))
- **[S15] Secondary ecosystem context for `opentelemetry-otlp`; not substituted for mandatory crates.io figures.**  
  `https://rustio.net/crate/opentelemetry-otlp` ([rustio.net](https://rustio.net/crate/opentelemetry-otlp?utm_source=openai))
- **[S16] `tracing-otel` documentation and initialization scope.**  
  `https://docs.rs/crate/tracing-otel/latest` ([docs.rs](https://docs.rs/crate/tracing-otel/latest?utm_source=openai))
- **[S17] `fastrace` secondary maintenance/MSRV context.**  
  `https://rustio.net/crate/fastrace` ([rustio.net](https://rustio.net/crate/fastrace?utm_source=openai))
- **[S18] Open bridge issue concerning setting a parent on auto-entered instrumented spans.**  
  `https://github.com/tokio-rs/tracing-opentelemetry/issues/253` ([github.com](https://github.com/tokio-rs/tracing-opentelemetry/issues/253?utm_source=openai))
- **[S19] OpenTelemetry SDK changelog — timeout, batching, suppression, and runtime changes.**  
  `https://github.com/open-telemetry/opentelemetry-rust/blob/main/opentelemetry-sdk/CHANGELOG.md` ([github.com](https://github.com/open-telemetry/opentelemetry-rust/blob/main/opentelemetry-sdk/CHANGELOG.md?utm_source=openai))
- **[S20] Official OpenTelemetry Rust language status and instrumentation guidance.**  
  `https://opentelemetry.io/docs/languages/rust/`  
  `https://opentelemetry.io/docs/languages/rust/libraries/` ([opentelemetry.io](https://opentelemetry.io/docs/languages/rust/?utm_source=openai))
- **[S21] `tracing-opentelemetry` crate documentation — layer purpose.**  
  `https://docs.rs/tracing-opentelemetry/latest/tracing_opentelemetry/` ([docs.rs](https://docs.rs/tracing-opentelemetry/latest/i686-pc-windows-msvc/tracing_opentelemetry/?utm_source=openai))
- **[S23] `opentelemetry_sdk` 0.33.0 publication and package metadata.**  
  `https://docs.rs/crate/opentelemetry_sdk/0.33.0` ([docs.rs](https://docs.rs/crate/opentelemetry_sdk/0.33.0?utm_source=openai))
- **[S25] crates.io API response structure, including `downloads` and `recent_downloads`.**  
  `https://github.com/rust-lang/crates.io/blob/main/crates/crates_io_api_types/src/lib.rs` ([github.com](https://github.com/rust-lang/crates.io/blob/main/crates/crates_io_api_types/src/lib.rs?utm_source=openai))

**Mandatory numeric endpoints to rerun before ledger finalization:**

```text
GET https://crates.io/api/v1/crates/opentelemetry
GET https://crates.io/api/v1/crates/opentelemetry/versions
GET https://crates.io/api/v1/crates/opentelemetry_sdk
GET https://crates.io/api/v1/crates/opentelemetry_sdk/versions
GET https://crates.io/api/v1/crates/opentelemetry-otlp
GET https://crates.io/api/v1/crates/opentelemetry-otlp/versions
GET https://crates.io/api/v1/crates/opentelemetry-http
GET https://crates.io/api/v1/crates/opentelemetry-http/versions
GET https://crates.io/api/v1/crates/tracing-opentelemetry
GET https://crates.io/api/v1/crates/tracing-opentelemetry/versions

GET https://api.github.com/repos/open-telemetry/opentelemetry-rust
GET https://api.github.com/repos/tokio-rs/tracing-opentelemetry
GET https://api.github.com/search/issues?q=repo:open-telemetry/opentelemetry-rust+is:issue+is:open
GET https://api.github.com/search/issues?q=repo:tokio-rs/tracing-opentelemetry+is:issue+is:open
```

## Sources

- [GitHub - open-telemetry/opentelemetry-rust: The Rust OpenTelemetry implementation · GitHub](https://github.com/open-telemetry/opentelemetry-rust?utm_source=openai)
- [tracing-otel 0.33.2 - Docs.rs](https://docs.rs/crate/tracing-otel/latest?utm_source=openai)
- [tracing-opentelemetry 0.33.0 - Docs.rs](https://docs.rs/crate/tracing-opentelemetry/latest/source/Cargo.toml?utm_source=openai)
- [Announcing Rust 1.98.0 | Rust Blog](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai)
- [crates.io/Cargo.toml at main · rust-lang/crates.io · GitHub](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml?utm_source=openai)
- [opentelemetry-otlp - Health 71/100, Stats & Alternatives | rustio.net](https://rustio.net/crate/opentelemetry-otlp?utm_source=openai)
- [rustup/Cargo.toml at main · rust-lang/rustup · GitHub](https://github.com/rust-lang/rustup/blob/master/Cargo.toml?utm_source=openai)
- [base/Cargo.toml at main · base/base · GitHub](https://github.com/base/base/blob/main/Cargo.toml?utm_source=openai)
- [opentelemetry-rust/examples/tracing-http-propagator/src/server.rs at main · open-telemetry/opentelemetry-rust · GitHub](https://github.com/open-telemetry/opentelemetry-rust/blob/main/examples/tracing-http-propagator/src/server.rs?utm_source=openai)
- [crates.io/crates/crates_io_api_types/src/lib.rs at main · rust-lang/crates.io · GitHub](https://github.com/rust-lang/crates.io/blob/main/crates/crates_io_api_types/src/lib.rs?utm_source=openai)
- [Path to Stable Release: Roadmap · Issue #1678 · open-telemetry/opentelemetry-rust · GitHub](https://github.com/open-telemetry/opentelemetry-rust/issues/1678?utm_source=openai)
- [opentelemetry-rust/docs/release_0.32.md at main · open-telemetry/opentelemetry-rust · GitHub](https://github.com/open-telemetry/opentelemetry-rust/blob/main/docs/release_0.32.md?utm_source=openai)
- [opentelemetry-http 0.32.0 - Docs.rs](https://docs.rs/crate/opentelemetry-http/latest/source/src/lib.rs?utm_source=openai)
- [SdkTracerProvider in opentelemetry_sdk::trace - Rust](https://docs.rs/opentelemetry_sdk/latest/opentelemetry_sdk/trace/struct.SdkTracerProvider.html?utm_source=openai)
- [opentelemetry-otlp 0.32.0 - Docs.rs](https://docs.rs/crate/opentelemetry-otlp/latest/source/src/lib.rs?utm_source=openai)
- [Releases · tokio-rs/tracing-opentelemetry · GitHub](https://github.com/tokio-rs/tracing-opentelemetry/releases?utm_source=openai)
- [fastrace - Health 67/100, Stats & Alternatives | rustio.net](https://rustio.net/crate/fastrace?utm_source=openai)
- [lib.rs - source](https://docs.rs/opentelemetry-otlp/latest/src/opentelemetry_otlp/lib.rs.html?utm_source=openai)
- [opentelemetry-rust/docs/migration_0.28.md at main · open-telemetry/opentelemetry-rust · GitHub](https://github.com/open-telemetry/opentelemetry-rust/blob/main/docs/migration_0.28.md?utm_source=openai)
- [Overview - Rust Forge](https://forge.rust-lang.org/?utm_source=openai)
- [Unable to set parent context when using #\[instrument\] macro · Issue #253 · tokio-rs/tracing-opentelemetry · GitHub](https://github.com/tokio-rs/tracing-opentelemetry/issues/253?utm_source=openai)
- [opentelemetry-rust/opentelemetry-sdk/CHANGELOG.md at main · open-telemetry/opentelemetry-rust · GitHub](https://github.com/open-telemetry/opentelemetry-rust/blob/main/opentelemetry-sdk/CHANGELOG.md?utm_source=openai)
- [Rust | OpenTelemetry](https://opentelemetry.io/docs/languages/rust/?utm_source=openai)
- [tracing_opentelemetry - Rust](https://docs.rs/tracing-opentelemetry/latest/i686-pc-windows-msvc/tracing_opentelemetry/?utm_source=openai)
- [opentelemetry_sdk 0.33.0 - Docs.rs](https://docs.rs/crate/opentelemetry_sdk/0.33.0?utm_source=openai)