---
prompt: # Deep-research prompt — Web framework stack (R69, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: which Rust async web framework and server fill the already-decided optional web feature, how validated configuration is made available to handlers and tests through an idiomatic lifecycle, how the production entrypoint runs the server with graceful shutdown, and how the dev-server recipe runs with auto-reload and readable console logs. Item kind: `bundle`. Value test: if this answer is wrong, the web crate's framework dependency, its Cargo feature-gate shape, the config-injection mechanism, `main`'s entrypoint, and the dev-serve Justfile recipe all get rewritten — and every consumer of the `web-extra-surface` parameter (R11's CI job structure, R32's test tiers, R37's hook wiring for the OpenAPI snapshot check, R51's container image, R58's logging pipeline profiles, and R71/R82/R83/R84's OpenAPI and docs gates) inherits a wrong assumption about what the web surface contains.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py ships a FastAPI web service under an optional install extra, composed by an app-factory function, with config threaded into handlers via FastAPI's dependency-injection mechanism and a lazy-load fallback for callers that bypass the lifespan, a production entrypoint that runs uvicorn with settings-driven graceful shutdown, and a dev-server Justfile recipe with auto-reload and human-readable console logs. ts has no web service at all. Evidence: py `src/py_launch_blueprint/web/app.py:102` — a FastAPI service under an optional install extra, `create_app()` wires settings, handlers, middleware, routers in one function; ts: none — no web/HTTP-server code, dependency, or test exists anywhere in the ts repo (`tests/api.test.ts` is an outbound API client, not a server). Ledger rows: F303, F330, F338, F339 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F330 config loads once at startup, with a lazy-load fallback — py `src/py_launch_blueprint/web/deps.py:37` (`def get_config(request: Request) -> Config:`, falls back to loading lazily for raw-ASGI callers such as schemathesis that bypass the lifespan); ts: none. F338 production entrypoint runs the ASGI server with settings-driven graceful shutdown — py `src/py_launch_blueprint/web/__main__.py:37` (`uvicorn.run(`) and `:42` (`timeout_graceful_shutdown=settings.graceful_shutdown_seconds,`; `python -m py_launch_blueprint.web`, no CLI flags, every knob is an env var); ts: none. F339 dev server recipe runs with auto-reload and pretty console logs — py `Justfile:291` (`serve host="127.0.0.1" port="8000":`; defaults `_LOG_FORMAT` to `console`, prod default is JSON — a dev/prod logging-profile split); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): whether the web service ships as an optional, separately built Cargo feature at all — `docs/port/COMMONALITY.md` row F017, area `workspace-architecture`, verdict `ADOPT`, no research item, "direct Cargo-optional-feature analogue of py's optional-dependencies extra; nothing to choose." This item decides only which framework and runtime fill that already-decided feature, and what its `web-extra-surface` contents are. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no web-service decision; ts never built a web/HTTP-server capability, so there is no ts shape to reconcile with.
- Current owner context (later clarification, 2026-09-04): FastAPI was selected for Python and Hono for TypeScript on ecosystem merits. The pinned TypeScript snapshot above predates that web direction; it is not evidence that Hono is implemented there. Research Rust on its own merits while preserving the shared web-example principles.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): We should look at Hono because that's what we've settled upon, and tRPC as the equivalent for the TypeScript repo should be added. We should copy the same architectural principles and patterns, and have equivalents for a base there. We need to find the equivalent for Rust as a specific research item.

### Baseline review (2026-09-04)
- F331 (router registry) was reclassified `DIVERGENT` under this item: compare native router composition before accepting a registry list, keeping explicit, straightforward resource registration as acceptance behavior. F304's optional OTel boundary belongs to R58's `logging-pipeline-contract` inside the `web` surface this item sets (evidence in `docs/port/BASELINE-REVIEW.md`).

## Out of scope
- The specific features layered on top of the chosen framework once it exists — the error envelope (R70 owns F305/F306), OpenAPI generation (R71 owns F307/F312/F332/F333), pagination (R72 owns F310/F311), idempotency replay (R73 owns F313-F315), rate limiting (R74 owns F316/F323), middleware ordering/request-id/access-log/security headers (R75 owns F317-F321/F327), CORS (R76 owns F322), typed env settings (R77 owns F324), OpenTelemetry (R78 owns F325), Prometheus metrics (R79 owns F326), health probe endpoints (R80 owns F328/F329), and the production container image (R51) — this item decides only the framework/server crate stack, the Cargo feature-gate shape, the config-injection mechanism, and the process entrypoint they all sit inside.
- Whether the web service ships as an optional Cargo feature at all; ledger row F017 (area `workspace-architecture`) already answered `ADOPT` with no research item — this item decides which framework fills that feature, not whether the feature exists.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R69
- owns: web-extra-surface
- consumes: R01: http-transport-injection-seam
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): `web-extra-surface`'s value (this item's `owns` parameter) is consumed by R11 (`ci-workflow-job-structure`, CI job and skip-gating structure), R32 (`test-harness-and-execution`, test tiers), R37 (`hook-manager-distribution`, hook wiring for the OpenAPI snapshot check), R51 (`container-image`), R58 (`logging-pipeline-architecture`, shared logging pipeline profiles), and R71/R82/R83/R84 (the OpenAPI and docs gates) — the Parameters field of this item's answer must state a value precise enough for all of them to consume directly: whether the surface exists as a named Cargo feature, that feature's name, and what crates/capabilities it gates. R01 (`ports-and-adapters-seam`) decides the driven-I/O seam's shape (F001, `http-transport-injection-seam`); this item's web adapter must wire through whichever shape R01 lands on — treat R01's choice as open, do not block on it.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: which Rust async web framework and server fill `rs-launch-blueprint`'s already-decided optional web feature, how that framework provides validated configuration to handlers and tests through an idiomatic lifecycle, how the production entrypoint runs the server with graceful shutdown, how the dev-server recipe provides auto-reload with readable console logs, and precisely what the `web-extra-surface` parameter's value is for its nine downstream consumers.
- HIGH: Compare the significant framework/server architectures found in the landscape on maturity, maintained production adoption, dependability, middleware composition, testability, and performance with representative JSON handling, validation, trace instrumentation and metrics enabled. State workload and benchmark limitations, and explain the best overall fit and the conditions under which a runner-up wins.
- HIGH: Specify a minimal realistic endpoint example using the selected stack and the R01 application boundary. It must support the shared OpenTelemetry and metrics requirements, typed input/error handling, configuration injection, and graceful shutdown. Coordinate the integration checks with R75/R78/R79; do not preselect their libraries.
- HIGH: Which Rust async web framework (`axum`, `actix-web`, `warp`, `poem`, etc.) best fits a CLI + library + web template that must later host OpenAPI generation (R71), typed settings (R77), tracing (R78), and metrics (R79) as separately decided layers — and what is its idiomatic mechanism for making validated configuration available to handlers and tests? Identify the requirement behind F330, then determine whether Python's lazy-startup fallback is needed in Rust or whether explicit application construction and state injection satisfy it better.
- HIGH: What is the Cargo feature-flag shape for the web surface — a single `web` feature mirroring py's install extra, or a nested set of features — and precisely what crates, modules, and binary/library targets does that feature gate? State this as the literal value the nine downstream consumers of `web-extra-surface` need.
- HIGH: What is the idiomatic production entrypoint (F338) — a `main` gated behind the `web` feature, calling the framework's own serve function with a graceful-shutdown signal handler (mirroring py's `timeout_graceful_shutdown`) — and does graceful shutdown need a crate beyond the framework/server itself (e.g. for OS signal handling)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: What is the idiomatic dev-server recipe (F339) — a `cargo-watch`/`bacon`-driven auto-rebuild-and-restart loop wired into a Justfile recipe, defaulting to human-readable console logging distinct from the production JSON profile?
- LOW: Does the framework choice constrain, or get constrained by, the driven-I/O seam's transport-injection shape (R01, `http-transport-injection-seam`, not yet decided) — does the web adapter need a specific seam shape (trait object vs. generic bound) to wire cleanly into the framework's handler signatures?

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
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
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
mode: all_deep_research
provider: perplexity
model: sonar-deep-research
operation_id: research-20260912-134041-a1150ec8a7594fa0
created_at: 2026-09-12T13:40:41.092422
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Web framework stack (R69, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: which Rust async web framework and server fill the already-decided optional web feature, how validated configuration is made available to handlers and tests through an idiomatic lifecycle, how the production entrypoint runs the server with graceful shutdown, and how the dev-server recipe runs with auto-reload and readable console logs. Item kind: `bundle`. Value test: if this answer is wrong, the web crate's framework dependency, its Cargo feature-gate shape, the config-injection mechanism, `main`'s entrypoint, and the dev-serve Justfile recipe all get rewritten — and every consumer of the `web-extra-surface` parameter (R11's CI job structure, R32's test tiers, R37's hook wiring for the OpenAPI snapshot check, R51's container image, R58's logging pipeline profiles, and R71/R82/R83/R84's OpenAPI and docs gates) inherits a wrong assumption about what the web surface contains.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py ships a FastAPI web service under an optional install extra, composed by an app-factory function, with config threaded into handlers via FastAPI's dependency-injection mechanism and a lazy-load fallback for callers that bypass the lifespan, a production entrypoint that runs uvicorn with settings-driven graceful shutdown, and a dev-server Justfile recipe with auto-reload and human-readable console logs. ts has no web service at all. Evidence: py `src/py_launch_blueprint/web/app.py:102` — a FastAPI service under an optional install extra, `create_app()` wires settings, handlers, middleware, routers in one function; ts: none — no web/HTTP-server code, dependency, or test exists anywhere in the ts repo (`tests/api.test.ts` is an outbound API client, not a server). Ledger rows: F303, F330, F338, F339 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F330 config loads once at startup, with a lazy-load fallback — py `src/py_launch_blueprint/web/deps.py:37` (`def get_config(request: Request) -> Config:`, falls back to loading lazily for raw-ASGI callers such as schemathesis that bypass the lifespan); ts: none. F338 production entrypoint runs the ASGI server with settings-driven graceful shutdown — py `src/py_launch_blueprint/web/__main__.py:37` (`uvicorn.run(`) and `:42` (`timeout_graceful_shutdown=settings.graceful_shutdown_seconds,`; `python -m py_launch_blueprint.web`, no CLI flags, every knob is an env var); ts: none. F339 dev server recipe runs with auto-reload and pretty console logs — py `Justfile:291` (`serve host="127.0.0.1" port="8000":`; defaults `_LOG_FORMAT` to `console`, prod default is JSON — a dev/prod logging-profile split); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): whether the web service ships as an optional, separately built Cargo feature at all — `docs/port/COMMONALITY.md` row F017, area `workspace-architecture`, verdict `ADOPT`, no research item, "direct Cargo-optional-feature analogue of py's optional-dependencies extra; nothing to choose." This item decides only which framework and runtime fill that already-decided feature, and what its `web-extra-surface` contents are. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no web-service decision; ts never built a web/HTTP-server capability, so there is no ts shape to reconcile with.
- Current owner context (later clarification, 2026-09-04): FastAPI was selected for Python and Hono for TypeScript on ecosystem merits. The pinned TypeScript snapshot above predates that web direction; it is not evidence that Hono is implemented there. Research Rust on its own merits while preserving the shared web-example principles.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): We should look at Hono because that's what we've settled upon, and tRPC as the equivalent for the TypeScript repo should be added. We should copy the same architectural principles and patterns, and have equivalents for a base there. We need to find the equivalent for Rust as a specific research item.

### Baseline review (2026-09-04)
- F331 (router registry) was reclassified `DIVERGENT` under this item: compare native router composition before accepting a registry list, keeping explicit, straightforward resource registration as acceptance behavior. F304's optional OTel boundary belongs to R58's `logging-pipeline-contract` inside the `web` surface this item sets (evidence in `docs/port/BASELINE-REVIEW.md`).

## Out of scope
- The specific features layered on top of the chosen framework once it exists — the error envelope (R70 owns F305/F306), OpenAPI generation (R71 owns F307/F312/F332/F333), pagination (R72 owns F310/F311), idempotency replay (R73 owns F313-F315), rate limiting (R74 owns F316/F323), middleware ordering/request-id/access-log/security headers (R75 owns F317-F321/F327), CORS (R76 owns F322), typed env settings (R77 owns F324), OpenTelemetry (R78 owns F325), Prometheus metrics (R79 owns F326), health probe endpoints (R80 owns F328/F329), and the production container image (R51) — this item decides only the framework/server crate stack, the Cargo feature-gate shape, the config-injection mechanism, and the process entrypoint they all sit inside.
- Whether the web service ships as an optional Cargo feature at all; ledger row F017 (area `workspace-architecture`) already answered `ADOPT` with no research item — this item decides which framework fills that feature, not whether the feature exists.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R69
- owns: web-extra-surface
- consumes: R01: http-transport-injection-seam
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): `web-extra-surface`'s value (this item's `owns` parameter) is consumed by R11 (`ci-workflow-job-structure`, CI job and skip-gating structure), R32 (`test-harness-and-execution`, test tiers), R37 (`hook-manager-distribution`, hook wiring for the OpenAPI snapshot check), R51 (`container-image`), R58 (`logging-pipeline-architecture`, shared logging pipeline profiles), and R71/R82/R83/R84 (the OpenAPI and docs gates) — the Parameters field of this item's answer must state a value precise enough for all of them to consume directly: whether the surface exists as a named Cargo feature, that feature's name, and what crates/capabilities it gates. R01 (`ports-and-adapters-seam`) decides the driven-I/O seam's shape (F001, `http-transport-injection-seam`); this item's web adapter must wire through whichever shape R01 lands on — treat R01's choice as open, do not block on it.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: which Rust async web framework and server fill `rs-launch-blueprint`'s already-decided optional web feature, how that framework provides validated configuration to handlers and tests through an idiomatic lifecycle, how the production entrypoint runs the server with graceful shutdown, how the dev-server recipe provides auto-reload with readable console logs, and precisely what the `web-extra-surface` parameter's value is for its nine downstream consumers.
- HIGH: Compare the significant framework/server architectures found in the landscape on maturity, maintained production adoption, dependability, middleware composition, testability, and performance with representative JSON handling, validation, trace instrumentation and metrics enabled. State workload and benchmark limitations, and explain the best overall fit and the conditions under which a runner-up wins.
- HIGH: Specify a minimal realistic endpoint example using the selected stack and the R01 application boundary. It must support the shared OpenTelemetry and metrics requirements, typed input/error handling, configuration injection, and graceful shutdown. Coordinate the integration checks with R75/R78/R79; do not preselect their libraries.
- HIGH: Which Rust async web framework (`axum`, `actix-web`, `warp`, `poem`, etc.) best fits a CLI + library + web template that must later host OpenAPI generation (R71), typed settings (R77), tracing (R78), and metrics (R79) as separately decided layers — and what is its idiomatic mechanism for making validated configuration available to handlers and tests? Identify the requirement behind F330, then determine whether Python's lazy-startup fallback is needed in Rust or whether explicit application construction and state injection satisfy it better.
- HIGH: What is the Cargo feature-flag shape for the web surface — a single `web` feature mirroring py's install extra, or a nested set of features — and precisely what crates, modules, and binary/library targets does that feature gate? State this as the literal value the nine downstream consumers of `web-extra-surface` need.
- HIGH: What is the idiomatic production entrypoint (F338) — a `main` gated behind the `web` feature, calling the framework's own serve function with a graceful-shutdown signal handler (mirroring py's `timeout_graceful_shutdown`) — and does graceful shutdown need a crate beyond the framework/server itself (e.g. for OS signal handling)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: What is the idiomatic dev-server recipe (F339) — a `cargo-watch`/`bacon`-driven auto-rebuild-and-restart loop wired into a Justfile recipe, defaulting to human-readable console logging distinct from the production JSON profile?
- LOW: Does the framework choice constrain, or get constrained by, the driven-I/O seam's transport-injection shape (R01, `http-transport-injection-seam`, not yet decided) — does the web adapter need a specific seam shape (trait object vs. generic bound) to wire cleanly into the framework's handler signatures?

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
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
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

# Rust Web Framework Stack for `rs-launch-blueprint` (R69, bundle)

This report concludes that the optional web surface of `rs-launch-blueprint` should be implemented as a Tokio-native Axum stack, exposed behind a single Cargo feature named `web`, with an Axum router constructed by an explicit app-factory function that takes already-validated configuration, shared with handlers and tests via Axum’s `State` extractor and simple test helpers.[11][17][20] The production entrypoint is an `#[tokio::main]` binary gated by the `web` feature, binding a `TcpListener` and serving the Axum router via `axum::serve` with `with_graceful_shutdown` wired to a Tokio-based signal future that listens for `SIGINT` and `SIGTERM`, wrapped in a timeout matching the configured graceful shutdown seconds.[18][19] The dev-server recipe is a Justfile target that runs `cargo watch` (or an equivalent watcher) to rebuild and restart the `web` binary with `--features web`, defaulting the logging profile to a human-readable console format distinct from production JSON, thus preserving the same dev/prod split seen in the FastAPI precedent.[1][18] The `web-extra-surface` parameter is therefore defined as a single `web` feature gating the Axum/Tokio/hyper/tower-http dependency stack, the web module tree, the `web` binary target, and all web-focused tests; this shape satisfies the shared principles of optionality, explicit configuration lifecycle, graceful shutdown, and dev-friendly auto-reload across the Python, TypeScript, and Rust templates, while leveraging Rust’s idiomatic patterns rather than copying Python’s lazy DI fallback verbatim.[2][3][14][20]

## Context and Landscape

### Landscape

The decision in R69 concerns a specific category in the Rust ecosystem: async HTTP server frameworks and their supporting server/runtime stack suitable for building a backend web service in a template that also ships as a CLI and a general-purpose library.[1][3][7] In Rust, this category spans both routing-focused libraries such as Axum, Actix-Web, Rocket, Warp, Poem, Salvo, and Tide, and lower-level HTTP libraries and async runtimes such as hyper and Tokio that underpin them.[1][3][7][11][12][16][20] To avoid privileging familiarity, we first map the landscape into three bins: built-in or first-party toolchain elements, established industry standards, and up-and-comers.

The built-in or first-party bin includes Tokio, hyper, and Axum in its modern form.[11][12][20] Tokio is the de facto standard asynchronous runtime for Rust, maintained by the Tokio project and widely adopted across networked applications; hyper is the foundational HTTP library built on Tokio and strongly recommended by its maintainers for HTTP client/server implementations; Axum is described by the Tokio team as an ergonomic, modular web framework built with `tokio`, `tower`, and `hyper`, and is effectively a first-party routing layer in the Tokio ecosystem.[12][20] These components form a baseline building block stack that many frameworks either use directly or wrap, and their status as first-party derives from direct stewardship by the Tokio and Rust infrastructure communities, extensive documentation, and integration into widely used libraries.[11][12][20]

The established industry standard bin contains Actix-Web, Rocket, and Warp.[1][3][4][7] Actix-Web is characterised in multiple independent comparisons as a powerful, extremely fast web framework built atop the Actix actor framework, consistently topping performance benchmarks such as TechEmpower when configured with JSON handling and high concurrency.[3][4][7][8] Rocket is an async backend web framework for Rust focusing on usability, security, extensibility, and speed; its maintainers emphasise developer ergonomics with macro-based routing and request guards, and the release of Rocket v0.5 brought stable Rust support and rebuilt async request handling using modern networking facilities.[2][3][9] Warp is built on top of hyper and Tokio, offering a composable, functional routing style and high performance; several surveys note Warp’s strong performance and use it as a reference point for lightweight async web applications.[1][4][7][12] These frameworks have high GitHub star counts, documented production usage, and sustained maintenance records, and are widely considered standard choices in Rust for web backends.[3][4][7][8][9][12]

The up-and-comer bin encompasses Poem, Salvo, and Tide.[1][7][10][16] Poem is described as a full-featured and easy-to-use web framework whose ecosystem includes `poem-openapi` for writing APIs that comply with OpenAPI 3 specifications and automatically generating documentation; its release history on lib.rs shows frequent updates through 2024 and 2025, indicating active development and maturation.[10] Salvo is marketed as a powerful web framework that can make work easier, offering first-class OpenAPI support with automatic generation, and is undergoing addition to curated lists like blessed.rs, signalling community recognition.[1][16] Tide, built on the async-std runtime, aims for simplicity and ergonomics, concentrating on async-first design with minimalism and pragmatism; although it lacks the same level of adopted status as Actix or Axum, it remains a recognised alternative for projects preferring async-std over Tokio.[1][7] These frameworks are promising but not yet the default choice in the majority of high-profile Rust backends.

Following the mandate to establish authority rather than assume it, the primary authoritative sources in this survey are official documentation and announcements from framework maintainers, widely cited comparative articles, and infrastructure project documentation.[1][2][3][4][5][7][8][9][10][11][12][14][15][16][19][20] For Axum, the Tokio blog announcement of axum 0.8, the crate documentation on crates.io, and the detailed docs.rs pages are authoritative because they are maintained by the project team and specify design intentions, feature sets, and integration points.[11][17][19][20] Rocket’s v0.5 release announcement and GitHub repository are authoritative for its async, stable-Rust support and ergonomic design; they come directly from the maintainers and document the architectural refactor to async networking.[2][9] Actix-Web’s crates.io page and recurring characterisation as extremely fast in multiple comparative articles are authoritative about its performance and actor-based architecture, reinforced by its long-term presence in benchmarks like TechEmpower.[3][4][7][8] Warp’s reliance on hyper and Tokio, coupled with documentation in tower-http examples, provides authoritative confirmation of its composable filter-based design and performance profile.[1][4][7][12][15] Poem and Salvo’s lib.rs and crates.io pages document their OpenAPI support and feature sets, and are maintained by their authors.[10][16] Finally, documentation about the crates.io API confirms Axum’s use in a real, high-traffic Rust infrastructure service, providing practice-based evidence with an authoritative origin in the Rust project itself.[14]

Practice evidence comes from surveying well-regarded Rust projects and seeing which frameworks they adopt. The most concrete example is crates.io itself, which uses Axum to implement its RESTful API for crate publication, metadata retrieval, search, and user management.[14] The DeepWiki documentation notes that the crates.io API is built using Axum and follows RESTful principles, and it lists numerous endpoints that support crate lifecycle operations such as publishing, metadata retrieval, owner listing, and version management; Axum routing and handlers thus power a core Rust ecosystem service with significant traffic and reliability demands.[14] This provides direct evidence that Axum is not only theoretically sound but battle-tested in production, aligning well with the template’s need for dependability. In the comparative landscape, multiple articles emphasise that Actix-Web, Rocket, and Axum are all production-ready, actively maintained, and have strong community support, while Actix-Web often appears as the fastest in raw throughput benchmarks and Axum close behind.[3][4][5][6][7] These articles assess learning curve, ecosystem maturity, performance, and production readiness, making them reasonable practice evidence when combined with official docs.

The fit question asks not which framework is universally “best,” but which best matches a template that is simultaneously a CLI, a library, and an optional web service, and must host layered concerns such as OpenAPI generation, typed settings, tracing, and metrics as separate decisions.[3][5][6] Comparative articles note that Axum’s modular, middleware-oriented design built on Tokio and Tower fits naturally into Rust’s async ecosystem, favouring composability and future-proof integration with observability tooling.[3][4][5][6][11][15][20] Actix-Web emphasises raw speed and a rich, actor-centric model that can introduce complexity for teams less familiar with Rust’s advanced features; Rocket prioritises developer ergonomics, macro-driven routing, and convention over configuration, sometimes trading a bit of throughput for simplicity.[3][4][5][6][7] Given the need for explicit, testable configuration injection, clear app-factory patterns, and straightforward integration with OpenTelemetry and metrics layers, Axum’s emphasis on modularity, Tower-based middleware, and Tokio-native async appears particularly well aligned, while Actix-Web remains a strong runner-up when extreme performance and actor integration are paramount.[3][5][6][15][20] This landscape framing sets the stage for principled selection in the context of the owner’s cross-language requirements and the specific shape of `rs-launch-blueprint`.

## Principles and Architecture

### Principles and implementation

The shared requirement behind R69 is to realise an optional web service capability that is architecturally consistent across the Python, TypeScript, and Rust templates, while respecting each ecosystem’s idioms and strengths.[1][2][3] In Python, the precedent is a FastAPI service shipped under an optional install extra, composed via an app-factory function that wires settings, handlers, middleware, and routers; configuration is threaded into handlers via FastAPI’s dependency-injection mechanism, with a lazy-load fallback for raw ASGI callers that bypass the lifespan, and production uses uvicorn with settings-driven graceful shutdown.[1] The dev server is invoked through a Justfile recipe that runs uvicorn with auto-reload and human-readable console logs, with a distinct JSON profile reserved for production.[1] In TypeScript, there is currently no implemented web service in the pinned snapshot, but later owner direction has chosen Hono and tRPC as preferred future directions, emphasising lightweight, composable routing and strong typing.[1] This bundle must therefore preserve principles at the level of architectural pattern and policy rather than concrete library identity.

The first principle is optionality: the web service must be an optional part of the template, activated by explicit configuration rather than always-on.[1] In Python, this is realised through an optional install extra; in Rust, the direct analogue is a Cargo feature that gates dependencies, modules, and binaries related to the web surface.[1] This principle is agreed at the architectural pattern level: the presence or absence of a web surface is a workspace architecture decision, and R69 must respect the pre-existing owner decision that this web service is optional and behind a feature, not a mandatory part of every build.[1] Observable acceptance criteria include the ability to build and run the CLI and library targets without pulling in any web-specific dependencies, and the ability to explicitly enable the `web` feature to compile and run the web server and its tests.

The second principle concerns configuration lifecycle and injection, encoded in ledger row F330.[1] The Python implementation loads configuration once at startup into a settings object, uses FastAPI’s DI system to make it available to handlers, and supports a lazy-load fallback in the DI function so that tests or tools that bypass the normal app lifespan can still obtain configuration by loading it on demand.[1] The essential behavior is that handlers run with validated configuration, that configuration is a single, coherent snapshot, and that both production and tests store and access it in a predictable manner. The observable acceptance criteria include: a single validation pass when the application or test harness starts; handlers receiving configuration via their framework’s idiomatic injection mechanism; and tests being able to provision configuration without invoking the full production runtime. While Python uses lazy DI fallback due to FastAPI’s DI handling and ASGI-specific bypass patterns, Rust offers a different set of idioms that often favor explicit shared state over runtime injection, and this is a key point of architectural adaptation.

A third principle, encoded in F338, relates to process management and graceful shutdown.[1] The Python implementation uses uvicorn’s support for graceful shutdown, supplying a timeout derived from settings (`graceful_shutdown_seconds`) and relying on uvicorn’s ASGI server to stop accepting new connections and wait for in-flight requests to complete before terminating.[1] The essential behavior is that the web server reacts to OS termination signals, stops accepting new work, and provides a bounded window for active requests to finish, avoiding both dropped connections and indefinite hangs. Acceptance criteria include: the presence of a graceful shutdown signal handler wired into the server serve loop; a configured timeout that bounds shutdown; and logging that makes the shutdown behavior observable in production and test runs. Rust frameworks support graceful shutdown through patterns such as providing a shutdown future to the server builder or using explicit signal handling plus `with_graceful_shutdown`, and these idioms must be used to match the behavior rather than replicate uvicorn’s exact API.

The fourth principle, F339, concerns the dev-server experience: auto-reload behavior and human-readable logs.[1] In Python, a Justfile recipe wraps uvicorn with auto-reload and a console log format, making development runs differ from production both in automatic code reloading and log structure.[1] The essential behavior is that developers can run a single command to start the web service in dev mode, see logs in a readable format, and have code changes applied without manual restarts. In Rust, there is no built-in auto-reload in common frameworks, but the ecosystem widely uses command-line tools such as `cargo watch` or `bacon` to monitor source changes and re-run `cargo run`. This pattern respects Rust’s compilation model while matching the principle of dev convenience.

Within these principles, some aspects must agree across languages, while others may vary. Agreement is required at the level of optionality (feature vs extra), app-factory composition (a single entry point that builds the app with configuration), graceful shutdown policy, and dev/prod logging separation. Variance is acceptable in the precise DI mechanism (FastAPI’s DI vs Axum’s `State` extractor), lazy fallback behavior (which may be replaced by explicit test harness construction in Rust), and the concrete auto-reload tool (uvicorn’s reload vs `cargo watch`). Architecturally, both FastAPI and Axum favor routing-centric handlers, explicit app assembly, and middleware composition, but Axum interacts with Rust’s type system and async runtime through distinct patterns, especially Tower-based middleware stacks and the absence of implicit DI.

It is therefore necessary to compare architectural alternatives across Rust frameworks before choosing libraries. Actix-Web’s actor model supports rich concurrency but requires careful understanding of Rust’s lifetime and ownership rules, and while its performance is top-tier, its middleware and injection patterns differ from those seen in FastAPI.[3][4][5][7][8] Rocket, with macro-based routing and request guards, strongly emphasizes developer ergonomics and “convention over configuration,” but much of its structure is built around compile-time code generation and attribute macros, which can be less transparent and harder to align with a template whose goal is to be a teaching and integration base.[2][3][6][9] Warp uses a composable filter pattern, leaning heavily into functional routing composition; while powerful, it may introduce cognitive overhead for teams seeking straightforward resource registration and explicit routers.[1][4][7][12] Poem and Salvo contribute strong OpenAPI support and ergonomic APIs, but they are less widely adopted and lack the direct first-party association with the Tokio stack that Axum enjoys.[1][7][10][16]

Axum’s architectural pattern complements the template’s needs: it focuses on ergonomics and modularity, uses builder-style routing composition that is transparent and explicit, integrates directly with Tokio and hyper, and employs Tower-compatible middleware layers that can later host tracing, metrics, and OpenAPI generation without locking in specific libraries at this stage.[3][5][11][15][17][20] The Axum docs highlight patterns for sharing state via the `State` extractor, request extensions, closure captures, or task-local variables, and recommend wrapping shared state in `Arc` so it can be cheaply cloned per request; this matches the principle of a single configuration snapshot shared across handlers and tests.[17] Axum’s serve API, combined with `with_graceful_shutdown`, directly supports graceful shutdown semantics when provided with a shutdown signal future, as documented in DeepWiki and StudyRaid examples.[18][19] This pattern allows us to implement OS signal handling and optional timeout at the `main` level, preserving the cross-language graceful shutdown principle while abiding by Rust idioms.

On configuration injection, a key architectural question is whether Rust requires a lazy-startup fallback akin to Python’s, or whether explicit application construction and state injection satisfy F330 better. In FastAPI, the DI system and ASGI integration mean that tools can invoke the app without the standard lifespan, leading to scenarios where configuration is not yet loaded; the lazy fallback defends against that by loading configuration on demand.[1] In Axum, there is no global DI container; instead, handlers receive state through `State` or other explicit mechanisms, and the recommended pattern is to construct the router with shared state and pass that to the server.[17][19] Tests that need configuration can either directly construct configuration objects or call an app-factory function identical to production, and tools that bypass the main lifespan typically use the router or service directly, which we can expose via library functions. Given this, it is more idiomatic and safer in Rust to require explicit configuration construction and injection rather than rely on a hidden lazy fallback; this approach enhances testability and type safety and avoids surprising runtime behaviors. This leads to a baseline review: 

> **BASELINE-REVIEW: F330 — configuration lifecycle — proposed change: replace Python-style lazy DI fallback with Rust-style explicit configuration construction and Axum `State` injection, while preserving the principle of a single validated configuration snapshot shared with handlers and tests — evidence: Axum’s recommended state-sharing patterns via `State` and `Arc`, crates.io’s use of an Axum-based API with explicit configuration wiring, and the general Rust ecosystem preference for explicit shared state over runtime DI magic.**[14][17][19]

The shared principle behind F330 thus evolves slightly: configuration must be loaded once and validated, shared explicitly with handlers and tests; lazy fallback is a Python-specific tactic to address ASGI bypass, not an architectural requirement across languages. For Rust, explicit construction and injection better satisfy the underlying goals.

On graceful shutdown (F338), the Axum pattern using `with_graceful_shutdown` and a shutdown signal future that listens to `SIGINT` and `SIGTERM` closely mirrors uvicorn’s semantics, with the tradeoff that we control the timeout ourselves using `tokio::time::timeout` rather than relying on a server parameter.[18][19] DeepWiki describes Axum’s graceful shutdown behavior as stopping new connections, waiting for in-flight requests, and terminating cleanly without dropping active connections once the shutdown signal future resolves.[19] StudyRaid examples show how to implement a shutdown signal using Tokio’s `signal::ctrl_c()` and Unix `signal(SignalKind::terminate())`, and how to integrate this into `axum::serve` with `with_graceful_shutdown`, optionally wrapped in a timeout.[18] This meets the cross-language principle of graceful shutdown and is sufficiently idiomatic in Rust to form the template’s production entrypoint pattern.

Finally, dev-server auto-reload and logging (F339) are realized through a combination of a Justfile recipe and external tooling. While the search results do not explicitly document `cargo watch` or `bacon`, their use is widespread in the Rust community, and the principle is to reuse `cargo run` with a watcher that re-invokes it when code changes. The template can define a Just recipe `serve-web` that invokes `cargo watch -x "run --features web --bin rs_launch_blueprint_web"` with environment variables such as `LOG_FORMAT=console` and `WEB_PORT=8000`, preserving the human-readable log format in dev and the JSON profile in production; this remains within the mandate to mirror the principles of FastAPI’s dev server while respecting ecosystem norms.

These principles and architectural considerations frame the choice of Axum as the dominant framework and define how configuration, graceful shutdown, and dev-server behavior will be designed in `rs-launch-blueprint`. The following sections delve into the concrete recommendation and the specific stack members.

## Concrete Recommendation

### Recommendation

The recommended stack for the `web-extra-surface` in `rs-launch-blueprint` is a Tokio-native Axum-based web service, backed by hyper and Tower, with tower-http available for HTTP-specific middleware composition, and a dev-server powered by a Justfile recipe that runs `cargo watch` to auto-rebuild and restart the web binary.[11][12][15][17][19][20] Axum serves as the HTTP routing and request-handling library, focusing on ergonomics and modularity, while Tokio provides the async runtime, and hyper functions as the underlying HTTP server library that Axum uses to handle HTTP/1.x and HTTP/2 connections.[11][12][20] Tower and tower-http offer the middleware model and HTTP-specific middleware building blocks that will later be used by R75, R78, and R79 for logging, tracing, metrics, and security headers, without committing to specific tracer or metrics crates at this stage.[15][20]

Cargo features will expose the web surface via a single feature named `web`, mirroring Python’s optional install extra but in Rust’s idiomatic feature-gate form.[1] When the `web` feature is enabled, the `web` module tree, the web binary target (e.g., `rs_launch_blueprint_web`), and all web-specific dependencies such as `axum`, `tokio`, `tower`, `tower-http`, and any configuration adapter used by R77 will be compiled and linked; when disabled, the CLI and library targets will build without these dependencies, ensuring optionality and minimizing compile-time and binary-size overhead for non-web consumers.[11][12][15][20] This shape also satisfies the acceptance needs of downstream consumers (R11, R32, R37, R51, R58, R71, R82, R83, R84) by providing a clear, declarative answer to which crates and capabilities are gated behind `web-extra-surface`.

Configuration will be injected into handlers and tests via Axum’s `State` extractor and a shared `Arc<AppConfig>` object created by a central `build_config()` function and passed into an app-factory `build_router(config: Arc<AppConfig>) -> Router` that constructs the Axum router.[17] Production `main` will call `build_config()` to validate configuration once, then construct the router and serve it using `axum::serve(listener, app).with_graceful_shutdown(shutdown_signal())`, where `shutdown_signal()` is an async function that waits for either `SIGINT` or `SIGTERM` using Tokio’s signal APIs, and the entire serve future will be wrapped in `tokio::time::timeout(Duration::from_secs(config.graceful_shutdown_seconds), ...)` to enforce a bounded graceful period.[18][19] Tests can either call `build_config()` or use a test-only helper such as `build_test_config()` to obtain configuration and construct routers, ensuring that both production and tests share the same configuration lifecycle and injection mechanism.

The dev-server recipe will be encoded in Justfile as, for example, `serve-web host="127.0.0.1" port="8000":`, which runs `LOG_FORMAT=console WEB_HOST={{host}} WEB_PORT={{port}} cargo watch -x 'run --features web --bin rs_launch_blueprint_web'`, mirroring the Python Justfile recipe’s auto-reload and console log defaults.[1] This ensures that development runs use the console logging profile and benefit from automatic rebuilds and restarts when code changes, while production uses a separate `web-prod` entrypoint (or simply `cargo run --features web --bin rs_launch_blueprint_web`) with JSON-formatted logs and without auto-reload.

The stack thus consists of Axum, Tokio, hyper, Tower/tower-http, and dev tooling in the form of `cargo watch` and Just. The dominant choice for the core framework is Axum, with Actix-Web as a ranked runner-up under specific performance-centric conditions, and Rocket, Warp, Poem, Salvo, and Tide as qualified or excluded options depending on licensing, MSRV, and architectural fit. The following Members section details each stack component’s landscape, principles, and fit for the template.

## Framework and Tooling Members

### Members

#### axum

##### Landscape

Axum occupies a distinctive position in the Rust web landscape as a routing and request-handling library built on Tokio, Tower, and hyper, emphasizing ergonomics and modularity.[11][20] The Tokio project’s announcement of axum 0.8 describes it explicitly as an ergonomic and modular web framework built with `tokio`, `tower`, and `hyper`, and notes that the release includes new major versions of `axum-core`, `axum-extra`, and `axum-macros`, indicating a structured and evolving ecosystem around the core crate.[20] The crates.io page concisely states that axum is an HTTP routing and request-handling library focused on ergonomics and modularity, positioning it as a layer above hyper and below high-level endpoints.[11] Axum is thus in the built-in/first-party bin in the landscape, drawing authority from its close association with the Tokio project and its use in infrastructure services.

Authoritative sources for Axum include its crates.io entry, docs.rs documentation, and the Tokio blog, all maintained by the Axum and Tokio teams.[11][17][19][20] These sources describe its high-level features: routing requests to handlers, extracting typed data from requests, handling responses, and composing middleware via Tower layers.[11][15][17][20] DeepWiki documentation on Axum’s graceful shutdown behavior provides an additional authoritative perspective on its serve API and shutdown semantics.[19] Together, these sources establish Axum’s design philosophy, feature set, and intended use in modern Rust backend development.

Practice evidence for Axum’s adoption includes the crates.io API implementation, which is built using Axum and follows RESTful principles for crate publication, metadata retrieval, search, and user management.[14] The DeepWiki description lists numerous endpoints exposed by the crates.io API, such as `GET /api/v1/crates` for search and list, `PUT /api/v1/crates/new` for publishing, and various endpoints for retrieving crate metadata and managing owners and versions; all are implemented with Axum, demonstrating its suitability for real-world, high-volume, multi-endpoint APIs.[14] Comparative articles also note that Axum is close behind Actix-Web in performance benchmarks and sometimes surpasses it, with memory efficiency highlighted as a strength.[3][4][5][6] One article characterizes Axum as the “balanced, future-proof choice” for building modern microservices, backed by the Tokio team and offering strong async performance and scaling characteristics.[6] This combination of authoritative docs and practice evidence supports Axum’s position as a mature, dependable choice for `rs-launch-blueprint`.

##### Principles and implementation

Axum aligns well with the shared principles of optional web capability, explicit configuration lifecycle, graceful shutdown, and dev/prod logging separation. Its design revolves around explicit router construction via `Router::new()` combined with routing methods such as `.route()` and nested routers, which naturally supports the app-factory pattern already used in the Python template’s FastAPI implementation.[1][17] An app-factory function in Axum can accept an `Arc<AppConfig>` and return a configured `Router`, which is then served by `axum::serve`. This approach ensures that configuration is loaded once and provided explicitly, satisfying F330’s underlying requirement in a way consistent with Rust idioms.[17]

Axum’s `State` extractor provides an idiomatic mechanism for making shared state, such as configuration, available to handlers.[17] The docs explain that sharing state with handlers is common, and the four main methods for doing so are using the `State` extractor, request extensions, closure captures, and task-local variables; the `State` extractor is the most natural fit for a configuration object.[17] The recommended pattern is to store shared state in an `Arc`, clone it when passing to handlers, and then destructure it in handler signatures via `State(state): State<Arc<AppConfig>>`, which gives handlers access to configuration with minimal overhead.[17] This pattern matches the template’s need for handlers and tests to share validated configuration and avoids global mutable state, preserving Rust’s safety guarantees.

On graceful shutdown, Axum’s `with_graceful_shutdown` method configures the server to stop accepting new connections and wait for existing ones to finish when a shutdown signal future completes.[19] DeepWiki explains that the method accepts any `Future<Output = ()>` that signals when shutdown should begin, and that once it completes, the server stops accepting new connections and waits for active ones to complete before terminating; this is exactly the semantics needed for F338.[19] StudyRaid examples show a typical shutdown signal implementation that listens for both `SIGINT` (via `signal::ctrl_c()`) and `SIGTERM` (on Unix) and uses `tokio::select!` to return when either arrives.[18] Integrating such a future with `axum::serve(...).with_graceful_shutdown(shutdown_signal())` and optionally wrapping the entire serve future in `tokio::time::timeout(Duration::from_secs(config.graceful_shutdown_seconds), ...)` mirrors uvicorn’s graceful shutdown behavior with a configurable timeout.[18][19]

Axum’s modularity and Tower-based middleware model are key to satisfying the cross-repo principles around observability and OpenAPI integration without pre-selecting specific libraries.[15][20] Tower-http provides a suite of HTTP-specific middleware examples built with Tower, such as key/value stores with HTTP APIs using Warp and other frameworks, demonstrating Tower’s suitability for instrumentation layers.[15] Because Axum is Tower-native, R75, R78, and R79 can later add tracing and metrics layers using Tower-compatible middleware, and R71 can integrate OpenAPI generation using libraries like `utoipa` or Axum-specific macros, without needing to modify R69’s base stack. This separation of concerns respects the research mandate and preserves the template’s role as a composable foundation.

In terms of performance, comparative articles report that Axum nearly matches Actix-Web in benchmarks and can surpass it in certain configurations, with memory usage often being the leanest among the three major frameworks.[3][4][5][6] While Actix-Web may deliver a few percentage points more throughput, especially in extreme high-concurrency scenarios, the difference is negligible for self-hosted applications handling under roughly 100k requests per second, and Axum’s ergonomics and integration with Tokio and Tower make it a better fit for the template’s balanced goals.[3][4][5][6] This performance profile aligns with the acceptance criteria: the template needs a dependable, scalable backend, not an absolute benchmark champion.

##### Dominant choice

Given the landscape and principles, Axum is the dominant choice for the `rs-launch-blueprint` web surface. It is a first-party component in the Tokio ecosystem, actively maintained, and used in high-profile production deployments such as crates.io.[11][14][20] Its routing style, builder-pattern router composition, and `State` extractor match the app-factory and configuration-sharing principles derived from FastAPI, while its Tower-based middleware model creates a natural integration path for future tracing, metrics, and OpenAPI layers.[15][17][20] Axum’s serve API and `with_graceful_shutdown` support graceful shutdown with OS signals and configurable timeouts, matching cross-language behavior.[18][19] Its performance is competitive, and its ergonomics reduce complexity compared to Actix-Web’s actor model and Rocket’s macro-heavy approach.[3][4][5][6][7]

##### Qualified shortlist

Actix-Web is the primary qualified shortlist candidate. It is described as a powerful, pragmatic, and extremely fast web framework built on the Actix actor framework, with strong support for HTTP/1.x and HTTP/2, streaming, WebSockets, and more.[3][4][7][8] Comparative articles highlight its top-tier performance and extensive feature set, positioning it as the framework for those who need raw speed and full control.[3][4][5][6][7][8] However, Actix-Web’s middleware model (service + transform) and actor-based internals can introduce complexity and make the learning curve steeper, especially for teams new to Rust’s advanced features.[3][5][6] For the template, which aims to be a broadly accessible base, this extra complexity is a tradeoff.

Rocket is another qualified option, focusing on usability and developer productivity through macro-based routing and request guards.[2][3][4][7][9] Rocket v0.5 introduced async support and stable Rust compatibility, making its technical foundation modern and robust.[2] Rocket’s ergonomics and conventions may be appealing for fast prototyping, but its heavy reliance on macros and code generation can obscure router composition patterns and complicate integration with Tower-based observability layers.

Warp, Poem, and Salvo are also in the shortlist. Warp’s composable filters provide a strong functional routing paradigm and high performance atop hyper and Tokio.[1][4][7][12] Poem and Salvo bring first-class OpenAPI support and easy-to-use APIs, with Poem offering `poem-openapi` as a dedicated OpenAPI integration path.[1][7][10][16] These frameworks are promising, but Axum’s first-party status and crates.io deployment make it a stronger base for the template.

##### Excluded by gate

None of the shortlisted frameworks are excluded by obvious license incompatibility; they are typically MIT or Apache-2.0 or similarly permissive, compatible with the template’s `MIT OR Apache-2.0` requirement.[1][2][3][4][7][8][9][10][11][16] However, for this report we cannot directly query RustSec or the GitHub APIs for active advisories, issue counts, or exact download counts; these metrics must be retrieved in follow-up validation using the specified endpoints. As of the documented sources, Axum, Actix-Web, Rocket, Warp, Poem, and Salvo all present as actively maintained, with recent releases and ongoing documentation updates.[1][2][3][4][7][8][9][10][11][16][20] Tide, relying on async-std, may be excluded from this template solely because the template otherwise relies on Tokio for async runtime, and mixing runtimes complicates integration.

##### Up-and-comers

Poem and Salvo are notable up-and-comers. Poem’s emphasis on full-featured yet easy-to-use APIs and its integration with OpenAPI via `poem-openapi` make it appealing for API-centric services needing auto-generated OpenAPI documentation.[1][10] Salvo’s powerful framework and first-class OpenAPI support similarly suit APIs where OpenAPI generation is central.[1][16] Both frameworks are being actively developed and added to curated lists like blessed.rs, indicating growing community recognition.[1][10][16] However, their adoption is less widespread than Axum’s, and they lack the direct first-party association with Tokio and Tower.

##### Fit for this template

Axum’s fit for `rs-launch-blueprint` is strong. It supports explicit router composition suitable for a registry that DIVERGENCE analysis has reclassified to favor clear resource registration over magic lists.[1][17] Its `State` extractor aligns with explicit configuration sharing, preserving F330’s principle while adapting away from Python’s lazy DI fallback.[17] Its serve API with `with_graceful_shutdown` provides graceful shutdown semantics consistent with F338.[18][19] Tower integration supports the layering of observability and OpenAPI capabilities as separate research items, with tower-http providing foundational HTTP middleware examples.[15][20] Axum is used in crates.io, proving its suitability for high-traffic, widely relied upon Rust services.[14] Its performance, ergonomics, and first-party status collectively make it a natural core for the template’s web surface.

##### Recommendation

Axum is recommended as the web framework for the `web-extra-surface` in `rs-launch-blueprint`. It should be used as the HTTP routing and request-handling library, with an app-factory function `build_router(config: Arc<AppConfig>) -> Router` that assembles the router with handlers, middleware, and routes, and with configuration shared via the `State` extractor.[11][17][20] This recommendation includes Axum as a direct dependency gated behind the `web` Cargo feature, paired with Tokio and hyper.

##### Ranked runner-up

Actix-Web is the ranked runner-up. It should be considered for alternative templates or future variants where raw throughput and actor-based integration are more critical than ergonomics, or where teams are already deeply familiar with Actix’s programming model.[3][4][5][6][7][8] In such contexts, Actix-Web’s performance and mature ecosystem make it an excellent choice, but for `rs-launch-blueprint`’s balance of accessibility, modularity, and first-party integration, Axum retains the lead.

##### Tradeoffs

Choosing Axum over Actix-Web trades a small amount of maximum throughput for improved ergonomics, integration with Tokio/Tower, and alignment with first-party infrastructure like crates.io.[3][4][5][6][14][20] Compared to Rocket, Axum trades some developer-facing magic for explicit router composition and clearer type-driven APIs, reducing hidden complexity in the template’s code.[2][3][4][6][9] Compared to Warp, Axum’s builder-style routes may be more familiar to developers than composable filters, and its `State` extractor provides a straightforward configuration injection pattern.[1][4][7][11][17] Axum’s compile-time cost is moderate, as it relies on explicit code rather than heavy macro expansion, but it is still a non-trivial addition to the template; gating it behind the `web` feature ensures that this cost is paid only when needed. Binary sizes remain reasonable for a typical web server, and Axum’s design is such that instrumentation and middleware can be composed without blowing up code size unnecessarily, though actual measurements must be captured in follow-up validation.

##### Parameters

For Axum’s role in the stack, the key parameters are:

`owns web-extra-surface` includes Axum as the routing and request-handling library gated behind the `web` feature. The web feature enables the Axum dependency, the `web` module tree where routers and handlers live, and the `web` binary target that calls `axum::serve` with a router built by `build_router(config: Arc<AppConfig>)`.[11][17]

Axum assumes the existence of a configuration type `AppConfig` defined by R77 and the `http-transport-injection-seam` defined by R01, but it does not constrain R01’s seam shape; handlers receive configuration via `State`, and application services can be passed via trait objects or generic bounds stored in state without violating Axum’s handler signatures.[17] Thus, no `CONFLICT` line is required for Axum regarding R01.

##### Migration implications

Adopting Axum requires the creation of a `web` module in the Rust template, containing an app-factory function that constructs an Axum router, and a `web` binary target whose `main` calls the app-factory and serves the router via Axum’s serve API. Existing CLI and library code need only minor adjustments to ensure the `web` feature is optional and that configuration types are shared; no existing files are rewritten except to add the `web` feature in `Cargo.toml` and possibly to extend configuration definitions. Tests must be added to exercise the Axum routes, using the same app-factory function and configuration, ensuring alignment with F330.

##### Validation strategy

Validation of Axum’s integration will involve building a minimal but realistic endpoint example and running tests and manual dev-server runs. The endpoint will accept typed JSON input, validate it, and return a response enriched with tracing and metrics hooks, while using configuration injected via `State` and supporting graceful shutdown. This is detailed in the global Validation Strategy section; in short, commands such as `cargo test --features web`, `cargo run --features web --bin rs_launch_blueprint_web`, and `just serve-web` will be used, with expected behavior including correct routing, configuration availability, graceful handling of `Ctrl+C`, and distinct dev/prod logging formats.[17][18][19]

##### Confidence & re-verify trigger

Confidence in Axum as the stack’s core is high, based on its first-party status, crates.io deployment, and documented ergonomics and modularity.[11][14][17][19][20] Re-verify triggers include major Axum version changes, Tokio runtime changes, new Rust edition releases affecting async behavior, and any RustSec advisories against Axum or its dependencies. Additionally, if downstream items R71, R78, or R79 discover that Axum’s middleware model materially constrains their choices in a way not anticipated here, the stack should be re-evaluated.

##### Sources

Axum’s selection and integration are based on its crates.io documentation, docs.rs guidance on state sharing, DeepWiki and StudyRaid documentation on graceful shutdown, and the Tokio blog announcement of axum 0.8, as well as practice evidence from the crates.io API implementation.[11][14][17][18][19][20]

#### tokio

##### Landscape

Tokio is the dominant async runtime in the Rust ecosystem, used by many major web frameworks and networked applications.[1][3][5][11][12][20] Comparative articles note that Actix-Web, Rocket, and Axum all use Tokio as their async runtime, with Axum being Tokio-native and Rocket relying on a custom runtime built on Tokio.[3][5] Tokio’s prominence places it firmly in the built-in/first-party bin. The Tokio blog and official documentation are authoritative sources describing Tokio as “a runtime for writing reliable network applications without compromising speed,” and they position Tokio as the default choice for async Rust projects.[1][20]

Practice evidence includes the fact that both Axum and Actix-Web are built on async Rust using Tokio, and that understanding async is crucial for using these frameworks effectively.[5] Warp also leverages Tokio as its runtime, and hyper is built on Tokio, further reinforcing Tokio’s centrality.[1][7][12] This consistent use across widely adopted frameworks and infrastructure libraries makes Tokio the natural runtime choice for the template.

##### Principles and implementation

Tokio’s role in the stack is to provide the async runtime for the web server and any other async tasks, such as OS signal handling and timeouts for graceful shutdown. Using `#[tokio::main]` for the `web` binary’s entrypoint follows Tokio’s recommended pattern, enabling an async `main` that can call `axum::serve`, listen for signals, and execute timeouts.[18][19][20] Tokio’s `signal::ctrl_c()` and Unix `signal(SignalKind::terminate())` functions are used in the shutdown signal implementation documented by StudyRaid and DeepWiki, making Tokio integral to graceful shutdown behavior.[18][19]

Tokio’s integration respects the template’s principles by providing cross-platform async behavior and consistent semantics for OS signals, timeouts, and concurrency. It supports the optional `web` feature by being included only when the `web` feature is enabled, thereby not impacting CLI or library builds that do not require async networking.

##### Dominant choice

Tokio is the dominant choice for async runtime. Alternatives such as async-std exist, but the template’s reliance on Axum, hyper, and Tower—all Tokio-centric—makes Tokio the natural and necessary provider.[1][7][11][12][15][20] Using async-std would complicate integration and conflict with Axum’s design, so Tokio is effectively mandatory.

##### Qualified shortlist

async-std and smol are in the qualified shortlist as alternative runtimes noted in Rust ecosystem surveys.[1] async-std is described as an async version of the Rust standard library, and smol as a small and fast async runtime.[1] However, they are generally used with frameworks built atop them (such as Tide), and mixing them with Tokio-native frameworks is discouraged.

##### Excluded by gate

For this template, async-std and smol are excluded by the gate of runtime alignment: Axum and hyper require Tokio, and using multiple runtimes in a single process is complex and unnecessary.[1][7][11][12] Tokio itself meets license and MSRV expectations, but precise metrics must be confirmed via follow-up API queries.

##### Up-and-comers

No major up-and-comer runtime competes with Tokio for the specific needs of Axum/hyper-based web services at this time, though smol represents an effort at smaller, more lightweight runtimes.

##### Fit for this template

Tokio fits perfectly: it is required by Axum, hyper, and Tower, and its signal and timeout APIs are central to implementing graceful shutdown and dev-server behavior. Its cross-platform support aligns with the template’s OS matrix of `ubuntu-latest` and `macos-latest`.[1][18][19][20]

##### Recommendation

Use Tokio as the async runtime for the web binary, with `#[tokio::main]` as the entrypoint macro, and rely on Tokio’s `signal` and `time` modules for graceful shutdown and shutdown timeouts.[18][19][20] Tokio is gated behind the `web` feature along with Axum and hyper.

##### Ranked runner-up

None; runtime alternatives are excluded by alignment gates.

##### Tradeoffs

The main tradeoff is that Tokio adds compile-time and binary-size overhead relative to a non-async server, but given the template’s async requirements and cross-language commitments, this is acceptable.

##### Parameters

Tokio is included in `web-extra-surface` as the async runtime. It assumes no specific shape for R01’s injection seam.

##### Migration implications

Introduce Tokio as a dependency gated by `web` and ensure that existing code compiles without Tokio when `web` is disabled.

##### Validation strategy

Use commands such as `cargo run --features web --bin rs_launch_blueprint_web` to verify that the async `main` runs, handles requests, and performs graceful shutdown via Tokio’s signal APIs.[18][19]

##### Confidence & re-verify trigger

High confidence; re-verify on Tokio major version changes or Rust edition updates.

##### Sources

Tokio’s role is documented via the Tokio blog, Rust workshop articles, and comparative framework analyses.[1][5][20]

#### hyper

##### Landscape

hyper is an HTTP library built on Tokio, described as “a protective and efficient HTTP library for all.”[12] Its crates.io page suggests that users wanting a higher-level framework may consider Axum or Warp, the latter taking a functional approach.[12] hyper is a foundational component in the built-in/first-party bin, serving as the underlying HTTP engine for frameworks like Axum and Warp.[1][4][7][11][12][20]

##### Principles and implementation

hyper is not used directly in the template’s code but underpins Axum’s serve behavior and HTTP capabilities, including HTTP/2 support and TLS handling via appropriate configuration.[3][4][7][12] Its presence ensures that the web server supports modern HTTP features and can integrate with tower-http middleware.

##### Dominant choice

hyper is the dominant HTTP library for the stack because Axum is built on it; no alternative is needed or recommended.

##### Qualified shortlist

No shortlist; hyper acts as a foundation rather than a competitor.

##### Excluded by gate

No exclusion; hyper meets license norms and is widely adopted.

##### Up-and-comers

None relevant for this template.

##### Fit for this template

hyper’s fit is implicit through Axum; its HTTP/2 and TLS capabilities align with future requirements for secure, modern APIs.[3][4][7][12]

##### Recommendation

Use hyper implicitly via Axum; do not wrap it directly in template code unless needed for specialised endpoints.

##### Ranked runner-up

None.

##### Tradeoffs

Using hyper via Axum avoids low-level HTTP complexities, trading some control for ergonomics.

##### Parameters

hyper is included transitively in `web-extra-surface` via the Axum dependency.

##### Migration implications

None beyond including Axum and its transitive dependencies.

##### Validation strategy

Verify HTTP behavior through Axum endpoints; hyper’s correctness is not validated directly.

##### Confidence & re-verify trigger

High confidence; re-verify on hyper major version changes.

##### Sources

hyper’s role and positioning are documented in its crates.io page and framework comparisons.[1][4][7][12]

#### tower-http

##### Landscape

tower-http is a crate providing HTTP-specific middleware built on Tower, and its examples include a key/value store with an HTTP API built with Warp.[15] It occupies the built-in/first-party bin as part of the Tower ecosystem and is relevant for building observability, security, and other middleware.[15][20]

##### Principles and implementation

tower-http aligns with the principle of modular observability and metrics layers by providing reusable middleware components such as logging, compression, and other HTTP behaviors, all implemented as Tower layers.[15] Although R75, R78, and R79 will choose specific tracing and metrics libraries, tower-http provides a natural base for composing these layers with Axum, allowing the template to define a middleware stack consistent with cross-language patterns.

##### Dominant choice

tower-http is the dominant tower-based HTTP middleware library for Axum and other Tower-based frameworks.

##### Qualified shortlist

Alternative middleware libraries exist, but tower-http’s first-party status and wide use make it preferred.

##### Excluded by gate

None; tower-http is compatible with Axum and Tokio.

##### Up-and-comers

None central to this template.

##### Fit for this template

tower-http fits by providing the middleware model needed for logging, tracing, and metrics, even if specific middleware pieces are chosen later.

##### Recommendation

Include tower-http as a dependency gated by `web`, and plan to use it in the middleware stack once R75, R78, and R79 define concrete layers.[15][20]

##### Ranked runner-up

None.

##### Tradeoffs

tower-http adds some compile-time overhead but simplifies middleware composition, a reasonable tradeoff for observability needs.

##### Parameters

tower-http is included in `web-extra-surface` as the HTTP middleware base.

##### Migration implications

Add tower-http to the dependencies and define a middleware stack in the web module; no changes to CLI or library.

##### Validation strategy

Use example endpoints with tower-http logging middleware to verify behavior in dev and prod modes.

##### Confidence & re-verify trigger

Medium-high confidence; re-verify when adding specific middleware layers.

##### Sources

tower-http’s use and examples come from its crates.io documentation.[15]

#### dev-tooling: Just + cargo-watch

##### Landscape

While not directly documented in the provided search results, Just is known as a command runner used in the Python template for dev-server recipes, and `cargo watch` is a widely used tool in the Rust ecosystem for auto-rebuilding and rerunning commands when source changes occur. The principle in F339 is to have a dev-server recipe in Just that runs the web service with auto-reload and console logs, mirroring FastAPI’s pattern.[1] These tools fall into the practice and ecosystem bin rather than the framework bin.

##### Principles and implementation

Just provides a declarative way to define recipes such as `serve-web`, making dev-server invocation straightforward. `cargo watch` monitors source files and executes commands like `cargo run` when they change. By combining them, the template can provide a dev-server recipe that compiles and runs the web binary with auto-reload behavior and console logging, without embedding dev-only behavior in the web code itself. This respects Rust’s compilation model and avoids runtime-based reload features.

##### Dominant choice

Just and `cargo watch` are the dominant choices for this pattern, matching the Python template’s use of Just and fulfilling the principle of auto-reload without adding web-specific dependencies.

##### Qualified shortlist

Alternative watchers such as `bacon` exist, but `cargo watch` is widely known and fits well.

##### Excluded by gate

None; these tools do not impact license or MSRV of the library code.

##### Up-and-comers

`bacon` and other build tools may evolve, but their choice does not affect the library stack.

##### Fit for this template

Just + `cargo watch` fit perfectly: they provide auto-reload and console logging, with the recipe controlling log format via environment variables.

##### Recommendation

Define a Justfile recipe `serve-web` that uses `cargo watch -x 'run --features web --bin rs_launch_blueprint_web'` with `LOG_FORMAT=console` and host/port parameters, mirroring FastAPI’s dev-server pattern.[1]

##### Ranked runner-up

Use `cargo run` without auto-reload for simpler scenarios.

##### Tradeoffs

Auto-reload introduces repeated compilation, which may be slower than Python’s reload, but this is inherent in Rust’s compilation model.

##### Parameters

The dev-server recipe is part of `web-extra-surface`’s behavior, though not a runtime dependency. It uses the `web` binary and log format environment variables.

##### Migration implications

Add Justfile entries and ensure they do not conflict with existing recipes.

##### Validation strategy

Run `just serve-web` during development and verify auto-reload and console log formatting.

##### Confidence & re-verify trigger

High confidence; re-verify if Just or `cargo watch` behavior changes or if the team prefers an alternative watcher.

##### Sources

The pattern is inferred from the Python Justfile behavior and general Rust practice; no direct citations from the provided search results.

## Compatibility and Parameters

### Compatibility

The members of the stack—Axum, Tokio, hyper, Tower/tower-http, and dev tooling—are tested together in practice via the crates.io API and other Axum-based projects documented in the ecosystem.[11][14][15][20] The crates.io API uses Axum on Tokio, with hyper as the underlying HTTP library, to provide RESTful endpoints for crate operations; this demonstrates that Axum, Tokio, and hyper function together in production.[14] Tower-http examples show a key/value store with an HTTP API built using Warp but leveraging Tower-based middleware, indicating that Tower and HTTP middleware integrate seamlessly with Tokio and hyper.[15] Axum’s docs and the Tokio blog further confirm that Axum is built on Tower and hyper, and that version 0.8 is designed for compatibility with current Tokio and hyper versions.[11][20]

Within the template, compatibility will be ensured by using consistent versions of Axum, Tokio, hyper, and tower-http in `Cargo.toml`, all gated by the `web` feature, and by validating that the web binary compiles and runs on both `ubuntu-latest` and `macos-latest`. The dev tooling `Just` and `cargo watch` operate outside the Rust build graph and will not affect library compatibility, but they will be tested by running the dev-server recipe and confirming that the web binary behaves correctly with auto-reload.

### Parameters

For R69, the key parameter it owns is `web-extra-surface`. Based on the analysis and recommendation, this parameter is defined as follows:

`owns web-extra-surface = Cargo feature "web" that gates:`

1. The inclusion of Axum, Tokio, hyper, Tower, and tower-http as dependencies in the `rs-launch-blueprint` workspace.[11][12][15][20] This ensures that these crates are only compiled when the `web` feature is enabled.
2. The `web` module tree in the Rust crate, including:
   - An app-factory function `build_router(config: Arc<AppConfig>) -> axum::Router`, which constructs the Axum router with handlers, middleware, and routes.
   - A configuration-sharing mechanism using Axum’s `State` extractor and an `Arc<AppConfig>` created by a configuration builder defined by R77.[17]
   - Middleware stack definitions that will later integrate logging, tracing, metrics, and OpenAPI, via Tower and tower-http layers.[15][20]
3. A binary target, e.g., `rs_launch_blueprint_web`, whose `main` function is gated behind the `web` feature and uses `#[tokio::main] async fn main()` to:
   - Call `build_config()` to load and validate configuration once.
   - Construct the router via `build_router(config.clone())`.
   - Bind a `TcpListener` to the configured host and port.
   - Call `axum::serve(listener, app).with_graceful_shutdown(shutdown_signal())`, where `shutdown_signal()` listens for OS signals via Tokio, and wrap this in a timeout based on `config.graceful_shutdown_seconds`, enforcing graceful shutdown consistent with F338.[18][19]
4. Web-specific tests in the Rust crate that:
   - Invoke `build_config()` or a test-specific configuration builder.
   - Construct routers via `build_router(config)` and test endpoints using Axum’s testing facilities or hyper-based clients.
   - Ensure configuration injection via `State` works correctly and that handlers behave as expected under configured scenarios.

The dev-server recipe in Justfile, while not a Cargo feature, is part of the behavioral envelope of `web-extra-surface` as consumed by downstream items. It is defined as:

- `serve-web host="127.0.0.1" port="8000":` running `LOG_FORMAT=console WEB_HOST={{host}} WEB_PORT={{port}} cargo watch -x 'run --features web --bin rs_launch_blueprint_web'`.

This ensures that `web-extra-surface` includes both runtime capabilities and dev tooling behaviors.

The consumed parameter from R01 is `http-transport-injection-seam`. R69 assumes `http-transport-injection-seam = a trait-based or generic interface that can be passed in configuration state or directly bound in handlers`, such that Axum handlers can call into application services abstracted over transport without constraining R01’s choice between trait objects and generic bounds.[17] No `CONFLICT` is recorded, as Axum’s handler signatures can accept any state accessible via `State`.

## Migration and Validation

### Migration implications

Implementing the recommended stack in `rs-launch-blueprint` involves a series of file-level changes and additions, carefully scoped to the `web` feature and web module. The core migration steps are:

1. Modify `Cargo.toml` to add a feature named `web`, listing `axum`, `tokio`, `hyper`, `tower`, and `tower-http` as optional dependencies enabled by this feature.[11][12][15][20] The `rust-version` field must be set to reflect the MSRV policy (“stable minus two minor versions”), and CI will need to test this configuration. Existing dependencies for the CLI and library targets remain unaffected.
2. Add a new binary target in `Cargo.toml` named `rs_launch_blueprint_web`, configured with `required-features = ["web"]` so that it only builds when the `web` feature is enabled. This binary’s main file (e.g., `src/bin/web.rs`) will contain the async `main` function and server setup.
3. Create a `src/web/mod.rs` module that defines:
   - The configuration type `AppConfig` or imports it from a shared config module defined by R77.
   - A `build_router(config: Arc<AppConfig>) -> Router` function that constructs the Axum router with handlers, middleware, and routes.
   - Handlers that use Axum’s `State` extractor to access `Arc<AppConfig>` and any other shared state needed for application services.[17]
   - Middleware stack setup using Tower and tower-http once R75, R78, and R79 define logging, tracing, and metrics layers.[15][20]
4. Implement the `rs_launch_blueprint_web` binary’s `main` function to:
   - Load configuration via `build_config()` (defined by R77), returning `AppConfig`.
   - Wrap configuration in `Arc` and call `build_router(config.clone())`.
   - Bind a `TcpListener` to `config.web_host` and `config.web_port`.
   - Construct a shutdown signal future `shutdown_signal()` using Tokio’s `signal::ctrl_c()` and `signal(SignalKind::terminate())`, as shown in StudyRaid’s example.[18]
   - Call `axum::serve(listener, app).with_graceful_shutdown(shutdown_signal())` and wrap the entire serve future in `tokio::time::timeout(Duration::from_secs(config.graceful_shutdown_seconds), ...)`, enforcing a shutdown timeout.[18][19]
5. Extend the Justfile to include the `serve-web` recipe as described, using `cargo watch` to provide auto-reload and defaulting `LOG_FORMAT` to `console`.[1] This recipe must reference the `rs_launch_blueprint_web` binary and enable the `web` feature.
6. Add tests under `tests/` or within `src/web/` that:
   - Construct configuration via `build_config()` or test-specific builders.
   - Build routers via `build_router(config)` and exercise endpoints with typed input, verifying that `State` injects configuration correctly.
   - Confirm that error handling and instrumentation hooks exist, even if actual tracing and metrics libraries are chosen later.

These changes are additive and do not require rewriting existing CLI or library code, except for minor adjustments to configuration definitions and `Cargo.toml` to accommodate the `web` feature. Migration must ensure that existing CI runs continue to work for non-web targets and that new CI jobs are added to test the `web` feature on `ubuntu-latest` and `macos-latest`.

### Validation strategy

Validation of the stack’s adherence to principles and correctness requires concrete commands and observable behaviors. The strategy consists of planned checks that future engineers will execute; this report can only specify them, not run them.

First, implement a minimal realistic endpoint example using Axum and the R01 application boundary. The endpoint should:

- Accept a JSON payload representing a resource, with fields such as `name` and `value`, using `serde::Deserialize`.
- Validate input using either manual checks or a validation library, producing typed error responses consistent with R70’s error envelope when that research is complete.
- Access configuration via `State<Arc<AppConfig>>`, using fields such as `max_value` or `feature_flags` to influence behavior.
- Emit tracing events and metrics via hooks or Tower middleware, without specifying concrete tracer or metrics crates yet; e.g., using placeholders or traits that R78 and R79 will flesh out.

A simplified code example (to be refined in implementation) could look like:

```rust
use std::sync::Arc;
use std::time::Duration;

use axum::{
    extract::State,
    routing::post,
    Router,
    Json,
};
use serde::Deserialize;
use tokio::net::TcpListener;
use tokio::signal::{self, unix::{signal, SignalKind}};
use tokio::time;

#[derive(Clone)]
struct AppConfig {
    host: String,
    port: u16,
    graceful_shutdown_seconds: u64,
    // other fields...
}

#[derive(Deserialize)]
struct CreateItemRequest {
    name: String,
    value: i32,
}

async fn create_item(
    State(config): State<Arc<AppConfig>>,
    Json(req): Json<CreateItemRequest>,
) -> Json<String> {
    // Example typed input validation
    if req.value < 0 {
        // Placeholder error handling; R70 will define envelope
        return Json(format!("invalid value: {}", req.value));
    }

    // Placeholder tracing/metrics hooks; R78/R79 will define concrete behavior
    // tracing::info!(name = %req.name, value = req.value, "creating item");

    Json(format!(
        "created item '{}' with value {} (host: {}, port: {})",
        req.name, req.value, config.host, config.port,
    ))
}

fn build_router(config: Arc<AppConfig>) -> Router {
    Router::new()
        .route("/items", post(create_item))
        .with_state(config)
}

async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c()
            .await
            .expect("Failed to install CTRL+C handler");
    };

    #[cfg(unix)]
    let sigterm = {
        let mut sigterm = signal(SignalKind::terminate())
            .expect("Failed to create SIGTERM handler");
        async move {
            sigterm.recv().await;
        }
    };

    #[cfg(not(unix))]
    let sigterm = async {};

    tokio::select! {
        _ = ctrl_c => {},
        _ = sigterm => {},
    }
}

#[tokio::main]
async fn main() {
    let config = Arc::new(AppConfig {
        host: "0.0.0.0".into(),
        port: 3000,
        graceful_shutdown_seconds: 30,
    });

    let router = build_router(config.clone());

    let addr = format!("{}:{}", config.host, config.port);
    let listener = TcpListener::bind(&addr)
        .await
        .expect("failed to bind");

    let server = axum::serve(listener, router)
        .with_graceful_shutdown(shutdown_signal());

    time::timeout(
        Duration::from_secs(config.graceful_shutdown_seconds),
        server,
    )
    .await
    .expect("Server timed out during shutdown");
}
```

This example demonstrates configuration injection via `State`, typed JSON handling, placeholder validation and instrumentation hooks, and graceful shutdown via a Tokio-based signal handler and timeout.[17][18][19] It is consistent with Axum’s documented patterns and adapts StudyRaid’s and DeepWiki’s graceful shutdown code.[17][18][19]

The validation commands and expected behaviors are:

1. `cargo build --features web`  
   - Expected: The project builds successfully with Axum, Tokio, hyper, and tower-http included, and the `rs_launch_blueprint_web` binary target is present.
2. `cargo run --features web --bin rs_launch_blueprint_web`  
   - Expected: The server starts, binds to `config.host:config.port`, prints startup logs in JSON format (prod profile), accepts requests to `/items`, and responds with the expected JSON; pressing `Ctrl+C` or sending `SIGTERM` triggers graceful shutdown, with the server stopping accepting new connections and waiting for in-flight requests until the timeout elapses.[18][19]
3. `just serve-web`  
   - Expected: The dev-server starts with console log formatting, uses `cargo watch` to rebuild and rerun when code changes, and exhibits the same endpoint behavior, with auto-reload confirmed by modifying handler code and seeing the changes reflected without manual restart.[1]
4. `cargo test --features web`  
   - Expected: Web-specific tests pass, confirming that handlers receive configuration via `State`, that typed input validation works, and that routers can be constructed in tests using the same app-factory function and configuration builder, satisfying F330’s principle of explicit configuration lifecycle.

Additionally, CI must be configured to run `cargo test --features web` and `cargo build --features web` on `ubuntu-latest` and `macos-latest` runners, ensuring cross-platform compatibility. Performance and resource usage will be observed qualitatively during dev and CI runs; more detailed benchmarks can be implemented later as part of R38 or other performance-focused items.

## Confidence and Sources

### Confidence & re-verify trigger

The confidence level in the Axum/Tokio/hyper/Tower stack and the associated configuration and shutdown patterns is high, based on multiple lines of evidence: Axum’s first-party status and official documentation, its deployment in crates.io’s API, comparative articles highlighting its performance and ergonomics, and documented graceful shutdown patterns using `with_graceful_shutdown` and Tokio signal handling.[11][14][17][18][19][20] The choice aligns with cross-language principles derived from FastAPI and the owner’s direction to copy architectural patterns rather than specific libraries, and it respects Rust idioms and ecosystem norms.

Re-verify triggers include:

- New major versions of Axum, Tokio, hyper, or tower-http, especially those that change APIs related to state sharing, serve behavior, or middleware composition.
- Rust edition changes that affect async behavior or introduce new best practices for web services.
- RustSec advisories against any of the core crates in the stack.
- Discoveries in downstream items (R71, R78, R79, R75) that Axum’s middleware model or configuration handling materially constrain their independent choices.
- Substantial shifts in Rust web framework practice, such as widespread adoption of a different framework for infrastructure services similar to crates.io.

Should such triggers occur, `rs-launch-blueprint`’s web surface should be re-evaluated in light of new evidence, potentially revisiting the choice of Axum or adjusting configuration and shutdown patterns.

### Sources

The analysis and recommendation in this report draw on the following sources, with retrieval dates assumed near the time of this writing:

- Rust Workshop article on choosing a Rust web framework, outlining async runtimes (Tokio, async-std, smol) and web frameworks (Axum, Actix-Web, Rocket, Salvo, Warp, Tide, Poem), and recommending the Tokio stack as a good starting point.[1]
- Rocket v0.5 release announcement, documenting Rocket as an async backend web framework focusing on usability, security, extensibility, and speed, and confirming stable Rust support and rebuilt async request handling.[2]
- Comparative article on self-hosted Rust web frameworks, analysing Actix-Web, Rocket, and Axum across performance, ergonomics, middleware support, and production readiness, and noting Axum’s modular, middleware-oriented design built on Tokio and Tower.[3]
- Dev.to comparison of Rust web frameworks, highlighting Actix-Web’s high performance, Rocket’s simplicity, Warp’s composability, Axum’s modern async design, and Poem’s minimalism.[4]
- CalmOps article comparing Axum and Actix-Web, emphasising their shared use of Tokio and contrasting learning curves, ecosystem support, type safety, performance, and production readiness.[5]
- Medium article urging developers to stop obsessing over benchmarks when choosing between Actix, Axum, and Rocket, characterising Axum as balanced and future-proof, Actix-Web as raw speed with full control, and Rocket as fast prototyping and smooth dev experience.[6]
- Medium comprehensive comparison of Rust web frameworks, describing Actix-Web, Rocket, Warp, and Tide, and noting performance benchmarks where Actix-Web leads, Warp performs well, and Rocket offers a balance between performance and ease of use.[7]
- crates.io pages for Actix-Web, Axum, hyper, tower-http, Salvo, and Poem, providing descriptions, feature sets, and hints about usage and integration.[8][10][11][12][15][16]
- Rocket’s GitHub repository, documenting its async web framework status and focus on usability, security, extensibility, and speed.[9]
- DeepWiki documentation for the crates.io API, confirming its implementation using Axum and listing RESTful endpoints for crate lifecycle operations.[14]
- Axum docs on state sharing and graceful shutdown (via DeepWiki and StudyRaid), detailing the use of `State` for shared state and `with_graceful_shutdown` for draining in-flight requests.[17][18][19]
- Tokio blog announcement of axum 0.8, stating Axum’s construction atop Tokio, Tower, and hyper, and emphasising ergonomics and modularity.[20]

These sources collectively ground the recommendation in authoritative documentation, practice evidence, and comparative analysis, satisfying the survey method requirements and supporting the chosen stack’s fit for `rs-launch-blueprint`.

## Sources

- [Available Web Frameworks](https://rustworkshop.co/2024/03/07/choosing-a-rust-web-framework/)
- [Rocket v0.5: Stable, Async, Sentinels, Streams, SSE, ...](https://rocket.rs/news/2023-11-17-version-0.5/)
- [Self-Hosted Rust Web Frameworks Compared: Actix-Web vs Rocket ...](https://www.pistack.xyz/posts/2026-07-13-rust-web-frameworks-actix-web-rocket-axum/)
- [Rust Web Frameworks Compared: Actix vs Axum vs Rocket](https://dev.to/leapcell/rust-web-frameworks-compared-actix-vs-axum-vs-rocket-4bad)
- [Building REST APIs with Axum and Actix-web - calmops.com](https://calmops.com/programming/rust/building-rest-apis-with-axum-and-actix-web/)
- [Rust Web Framework Showdown: Actix vs Axum vs Rocket — Stop ...](https://medium.com/@james.miller941/rust-web-framework-showdown-actix-vs-axum-vs-rocket-stop-obsessing-over-benchmarks-5e81cd60fe6e)
- [Rust Web Frameworks: A Comprehensive Comparison - Medium](https://medium.com/@rs4528090/rust-web-frameworks-a-comprehensive-comparison-58f94113f864)
- [actix-web - crates.io: Rust Package Registry](https://crates.io/crates/actix-web)
- [rwf2/Rocket: A web framework for Rust.](https://github.com/rwf2/Rocket)
- [Poem — server-side Rust // Lib.rs](https://lib.rs/crates/poem)
- [axum - crates.io: Rust Package Registry](https://crates.io/crates/axum)
- [hyper - crates.io: Rust Package Registry](https://crates.io/crates/hyper)
- [axum-token-auth - crates.io: Rust Package Registry](https://crates.io/crates/axum-token-auth)
- [API Reference | rust-lang/crates.io | DeepWiki](https://deepwiki.com/rust-lang/crates.io/4-api-reference)
- [tower-http - crates.io: Rust Package Registry](https://crates.io/crates/tower-http)
- [salvo - crates.io: Rust Package Registry](https://crates.io/crates/salvo)
- [axum - Rust](https://docs.rs/axum/latest/axum/)
- [Understand implementing graceful shutdown in Axum - StudyRaid](https://app.studyraid.com/en/read/15308/530952/implementing-graceful-shutdown-in-axum)
- [Graceful Shutdown | tokio-rs/axum | DeepWiki](https://deepwiki.com/tokio-rs/axum/14.2-graceful-shutdown)
- [Announcing axum 0.8.0 | Tokio - An asynchronous Rust runtime](https://tokio.rs/blog/2025-01-01-announcing-axum-0-8-0)

## Cost

Total: $0.9035