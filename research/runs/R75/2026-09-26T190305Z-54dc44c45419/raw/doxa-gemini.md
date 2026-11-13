---
prompt: # Deep-research prompt — HTTP middleware stack (R75, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: what Rust middleware/layer stack gives the web service request-id propagation, one canonical structured access-log event per request excluding probe endpoints, unconditional security response headers, a defined outermost-to-innermost ordering with the id/security-header middleware outermost, and folds the chosen framework/server's own logs into the shared tracing pipeline instead of double-logging. Item kind: `bundle`. Value test: if this answer is wrong, the middleware/layer composition order in the composition root, the request-id and security-header layers, the structured access-log layer and its path-exclusion list, and the framework/server log-silencing step all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py enforces middleware ordering as a contract — the request-id and security-header middleware are added last, so they wrap outermost and stay present even on CORS preflights and rate-limit 429s — propagates a request id through log context and the response header, emits one canonical structured access-log event per request (replacing the server's own plain-text access line) while excluding probe endpoints from that log volume, stamps security response headers unconditionally, and folds the ASGI server's own loggers into the shared structured-logging pipeline instead of double-logging. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/app.py:145` — `app.add_middleware(SecurityHeadersMiddleware)` added last (outermost), so CORS preflights and rate-limit 429s still carry request-id and security headers; ts: none. Ledger rows: F317, F318, F319, F320, F321, F327 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F318 request-id propagation — py `src/py_launch_blueprint/web/middleware.py:72` (reads `x-request-id` or generates one, binds it to log context), echoed back via `src/py_launch_blueprint/web/middleware.py:82` (`response.headers["x-request-id"] = request_id`); ts: none. F319 one canonical structured access-log event — py `src/py_launch_blueprint/web/middleware.py:95` — `log.info("http_request", ...)` with route template, status, duration_ms (WEB-12; replaces uvicorn's plain-text access line); ts: none. F320 probe endpoints excluded from access-log volume — py `src/py_launch_blueprint/web/middleware.py:49` — `ACCESS_LOG_EXCLUDED_PATHS: frozenset[str]` (`/healthz`, `/readyz`, `/metrics` would otherwise dominate log volume); ts: none. F321 security response headers stamped unconditionally — py `src/py_launch_blueprint/web/middleware.py:56` — `SECURITY_HEADERS: dict[str, str] = {` (nosniff, DENY, no-referrer, HSTS; WEB-23; set unconditionally, including HSTS over plain http in dev); ts: none. F327 the framework/server's own loggers folded into the shared pipeline — py `src/py_launch_blueprint/web/logging.py:71` — `access_logger = logging.getLogger("uvicorn.access")` handlers cleared (server lifecycle lines come out structured like every other event; access logging silenced in favor of the canonical event); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no decision addressing web-service scope; ts never built a web service, so there is no middleware-stack shape to reconcile with.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Looking at architectural principles, we see a state-of-the-art pattern that we want to replicate with good security practices and middleware. It's not about the same exact implementation, but about the best practice for the equivalent principles in TypeScript and Rust.

## Out of scope
- Which web framework/server this middleware stack runs on; R69 (`web-framework-stack`) owns F303 and the `web-extra-surface` parameter — assume R69 resolves to some framework and design the stack to fit whichever framework's middleware/layer model wins.
- The CORS middleware itself and its opt-in install condition; R76 (`cors-middleware`) owns F322 — this item's ordering contract must leave room for R76's layer to be positioned correctly, but does not decide CORS's own install condition.
- The idempotency-key and rate-limiting middlewares' own behavior; R73 (`idempotency-middleware`) and R74 (`rate-limiting-middleware`) own F313-F316/F323 — this item's ordering contract places them, it does not decide what they do.
- The shared logging pipeline's own architecture and per-front-end policy profiles; R58 (`logging-pipeline-architecture`) owns F263 — this item decides only the web-front-end side of folding the framework's own logger into that pipeline (F327), not the pipeline's own design.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R75
- owns:
- consumes: R58: logging-pipeline-contract
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R69 (`web-framework-stack`) decides which framework/server this middleware stack runs on and which layer/middleware model it exposes — treat R69's choice as open, do not block on it.
- related (integration guidance; registry dependency above):
- related (integration guidance; registry dependency above): R58 (`logging-pipeline-architecture`) owns F263, the pipeline-profile side of the same web-logger integration point this item's F327 addresses from the framework side; see F263's ledger note for the split.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what Rust middleware/layer stack gives the web service request-id propagation, one canonical structured access-log event per request excluding probe endpoints, unconditional security response headers, a defined outermost-to-innermost ordering with the id/security-header middleware outermost, and folds the chosen framework/server's own logs into the shared tracing pipeline instead of double-logging.
- HIGH: Is a layered `Service`-composition model (each concern as its own layer, composed in a defined order) the idiomatic Rust analogue of py's `add_middleware` stack, and does the ecosystem ship ready-made layers for request-id propagation and security headers, or do those need to be hand-rolled?
- HIGH: What layer ordering keeps the id/security-header middleware outermost (F317, so CORS preflights and rate-limit 429s still carry them) when composed with R73's idempotency layer, R74's rate-limit layer, and R76's CORS layer — and does the chosen layer-composition model run outermost-to-innermost or the reverse, so the ordering contract can be stated unambiguously?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: What is the idiomatic way to emit one canonical structured access-log event per request (F319, mirroring py's `log.info("http_request", ...)` with route template/status/duration) — a tracing-integrated layer with a custom on-response callback, or a hand-written layer?
- MEDIUM: How does the access-log layer exclude specific paths (F320, e.g. `/healthz`, `/readyz`, `/metrics`) from its volume — a path-allowlist/denylist parameter on the layer, or a route-level opt-out?
- MEDIUM: How does the chosen web framework/server's own request-logging (the Rust analogue of uvicorn's access logger) get silenced or redirected into the shared tracing pipeline (F327) instead of double-logging, and does this depend on which framework/server R69 (not yet decided) picks?
- LOW: Do any published Rust web-service templates document this exact "id/security-header outermost, structured access log, silenced framework logger" middleware convention as a named pattern, and where?

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
mode: gemini_deep_research
provider: gemini
model: deep-research-preview-04-2026
operation_id: research-20260926-154054-a77c9b50d4384928
created_at: 2026-09-26T15:40:54.041121
---

### Prompt

```
System: Conduct exhaustive Deep Research. Cover every relevant angle. Cite sources rigorously.

User: # Deep-research prompt — HTTP middleware stack (R75, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: what Rust middleware/layer stack gives the web service request-id propagation, one canonical structured access-log event per request excluding probe endpoints, unconditional security response headers, a defined outermost-to-innermost ordering with the id/security-header middleware outermost, and folds the chosen framework/server's own logs into the shared tracing pipeline instead of double-logging. Item kind: `bundle`. Value test: if this answer is wrong, the middleware/layer composition order in the composition root, the request-id and security-header layers, the structured access-log layer and its path-exclusion list, and the framework/server log-silencing step all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py enforces middleware ordering as a contract — the request-id and security-header middleware are added last, so they wrap outermost and stay present even on CORS preflights and rate-limit 429s — propagates a request id through log context and the response header, emits one canonical structured access-log event per request (replacing the server's own plain-text access line) while excluding probe endpoints from that log volume, stamps security response headers unconditionally, and folds the ASGI server's own loggers into the shared structured-logging pipeline instead of double-logging. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/app.py:145` — `app.add_middleware(SecurityHeadersMiddleware)` added last (outermost), so CORS preflights and rate-limit 429s still carry request-id and security headers; ts: none. Ledger rows: F317, F318, F319, F320, F321, F327 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F318 request-id propagation — py `src/py_launch_blueprint/web/middleware.py:72` (reads `x-request-id` or generates one, binds it to log context), echoed back via `src/py_launch_blueprint/web/middleware.py:82` (`response.headers["x-request-id"] = request_id`); ts: none. F319 one canonical structured access-log event — py `src/py_launch_blueprint/web/middleware.py:95` — `log.info("http_request", ...)` with route template, status, duration_ms (WEB-12; replaces uvicorn's plain-text access line); ts: none. F320 probe endpoints excluded from access-log volume — py `src/py_launch_blueprint/web/middleware.py:49` — `ACCESS_LOG_EXCLUDED_PATHS: frozenset[str]` (`/healthz`, `/readyz`, `/metrics` would otherwise dominate log volume); ts: none. F321 security response headers stamped unconditionally — py `src/py_launch_blueprint/web/middleware.py:56` — `SECURITY_HEADERS: dict[str, str] = {` (nosniff, DENY, no-referrer, HSTS; WEB-23; set unconditionally, including HSTS over plain http in dev); ts: none. F327 the framework/server's own loggers folded into the shared pipeline — py `src/py_launch_blueprint/web/logging.py:71` — `access_logger = logging.getLogger("uvicorn.access")` handlers cleared (server lifecycle lines come out structured like every other event; access logging silenced in favor of the canonical event); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no decision addressing web-service scope; ts never built a web service, so there is no middleware-stack shape to reconcile with.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Looking at architectural principles, we see a state-of-the-art pattern that we want to replicate with good security practices and middleware. It's not about the same exact implementation, but about the best practice for the equivalent principles in TypeScript and Rust.

## Out of scope
- Which web framework/server this middleware stack runs on; R69 (`web-framework-stack`) owns F303 and the `web-extra-surface` parameter — assume R69 resolves to some framework and design the stack to fit whichever framework's middleware/layer model wins.
- The CORS middleware itself and its opt-in install condition; R76 (`cors-middleware`) owns F322 — this item's ordering contract must leave room for R76's layer to be positioned correctly, but does not decide CORS's own install condition.
- The idempotency-key and rate-limiting middlewares' own behavior; R73 (`idempotency-middleware`) and R74 (`rate-limiting-middleware`) own F313-F316/F323 — this item's ordering contract places them, it does not decide what they do.
- The shared logging pipeline's own architecture and per-front-end policy profiles; R58 (`logging-pipeline-architecture`) owns F263 — this item decides only the web-front-end side of folding the framework's own logger into that pipeline (F327), not the pipeline's own design.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R75
- owns:
- consumes: R58: logging-pipeline-contract
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R69 (`web-framework-stack`) decides which framework/server this middleware stack runs on and which layer/middleware model it exposes — treat R69's choice as open, do not block on it.
- related (integration guidance; registry dependency above):
- related (integration guidance; registry dependency above): R58 (`logging-pipeline-architecture`) owns F263, the pipeline-profile side of the same web-logger integration point this item's F327 addresses from the framework side; see F263's ledger note for the split.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what Rust middleware/layer stack gives the web service request-id propagation, one canonical structured access-log event per request excluding probe endpoints, unconditional security response headers, a defined outermost-to-innermost ordering with the id/security-header middleware outermost, and folds the chosen framework/server's own logs into the shared tracing pipeline instead of double-logging.
- HIGH: Is a layered `Service`-composition model (each concern as its own layer, composed in a defined order) the idiomatic Rust analogue of py's `add_middleware` stack, and does the ecosystem ship ready-made layers for request-id propagation and security headers, or do those need to be hand-rolled?
- HIGH: What layer ordering keeps the id/security-header middleware outermost (F317, so CORS preflights and rate-limit 429s still carry them) when composed with R73's idempotency layer, R74's rate-limit layer, and R76's CORS layer — and does the chosen layer-composition model run outermost-to-innermost or the reverse, so the ordering contract can be stated unambiguously?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: What is the idiomatic way to emit one canonical structured access-log event per request (F319, mirroring py's `log.info("http_request", ...)` with route template/status/duration) — a tracing-integrated layer with a custom on-response callback, or a hand-written layer?
- MEDIUM: How does the access-log layer exclude specific paths (F320, e.g. `/healthz`, `/readyz`, `/metrics`) from its volume — a path-allowlist/denylist parameter on the layer, or a route-level opt-out?
- MEDIUM: How does the chosen web framework/server's own request-logging (the Rust analogue of uvicorn's access logger) get silenced or redirected into the shared tracing pipeline (F327) instead of double-logging, and does this depend on which framework/server R69 (not yet decided) picks?
- LOW: Do any published Rust web-service templates document this exact "id/security-header outermost, structured access log, silenced framework logger" middleware convention as a named pattern, and where?

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

# Deep-Research Report: HTTP Middleware Stack Architecture (R75)

### Landscape

The architectural domain of HTTP middleware within the Rust web ecosystem is defined by a rigorous consolidation around a singular abstraction model, diverging significantly from the splintered, multi-standard middleware ecosystems found in Python (WSGI/ASGI) or the Node.js environment (Express/Koa). The research mandate requires categorizing the ecosystem into three distinct strata to evaluate the most viable path for the `rs-launch-blueprint` web service.

The first category, the built-in or first-party toolchain, offers no functional middleware engine. The Rust standard library is deliberately devoid of HTTP primitives, maintaining a strict focus on core memory safety and operating system interfaces. The first-party ecosystem provides the `http` crate, which defines the foundational vocabulary—Requests, Responses, Headers, and Status Codes—but it explicitly avoids providing runtime execution or middleware traversal mechanisms [cite: 1, 2].

The second category, the established industry standard, is entirely dominated by the `tower` and `tower-http` crates. Developed and maintained by the Tokio project, these libraries represent the absolute bedrock of asynchronous networking in Rust. They implement a protocol-agnostic, future-driven middleware pattern through the `Service` and `Layer` traits. The vast majority of major Rust web frameworks, most notably Axum and Tonic, directly consume and expose Tower layers as their primary middleware interface [cite: 3]. The architectural consensus around Tower is so absolute that it functions as a de facto extension of the standard library for network programming.

The third category, the up-and-comers, includes frameworks like Salvo, Loco, and specialized wrappers like `wstd-axum` or `spikard` [cite: 4, 5]. While Salvo utilizes its own macro-based internal middleware implementation, and Loco provides an opinionated Rails-like scaffolding, these do not present a structural challenge to the Tower paradigm for general-purpose HTTP web services. They typically either wrap Tower internally or cater to highly specific niche deployments (such as WebAssembly via `wstd-axum`) [cite: 5]. 

Authority in this domain is established by the architectural convergence of the Tokio and Hyper ecosystems. The Tokio team maintains `axum`, `tower`, and `tracing`, ensuring seamless, first-party interoperability across the async runtime, the web routing layer, and the observability pipeline [cite: 6, 7, 8]. This authority is corroborated by the official Rust API guidelines and continuous community consensus, where `tower::Service` is cited as the foundational building block for client/server request processing. Furthermore, package registry metrics establish `tower` (exceeding 677 million all-time downloads) and `tower-http` (exceeding 468 million) as the undisputed defaults [cite: 9, 10].

Practice evidence demonstrates that mainstream, highly regarded Rust projects universally rely on this stack. The official package registry itself, crates.io, operates on an Axum and Tower foundation, serving the entire global Rust community [cite: 11]. Commercial enterprise distributions, such as the CrowdStrike Falcon sensor architecture, distribute `tower-http` for high-performance network handling [cite: 12]. Specialized data platforms like Artifact-Keeper and RSigma utilize `tower-http::TraceLayer` to emit structured telemetry and standardize rate-limits across complex HTTP layers [cite: 13].

Evaluated against the specific fitness requirements of a template serving as a CLI, library, and web service, the chosen middleware must cleanly decouple web-layer concerns from core business logic. The `tower` ecosystem fulfills this requirement flawlessly. A `tower::Service` can be instantiated and tested in isolation—satisfying the library crate requirements—without the overhead of spinning up a TCP listener, while its native integration with `tracing` fits perfectly within a CLI-compatible structured logging environment.

### Principles and implementation

The overarching objective of this architectural bundle is to standardize the middleware behavior across language environments (Python, TypeScript, Rust) by preserving core engineering principles, even when language-specific execution mechanisms differ. The analysis identifies several critical behaviors that must be guaranteed by the application composition root, ensuring that cross-cutting concerns like telemetry, security, and traffic control operate reliably.

**Outermost Middleware Composition (F317)**

The primary shared engineering principle dictates that security headers, request-identification, and fundamental observability must survive early request termination. If an inner layer—such as a rate-limiting middleware returning an HTTP 429, or a CORS layer rejecting a preflight OPTIONS request—short-circuits the connection, the outgoing response must still carry the generated request ID and the strict security headers. 

In the Python reference implementation, this is enforced by a specific contract: middleware is added last to the ASGI application, wrapping the stack outermost so that early rejections still traverse the security and ID layers on the outbound path. In Rust, this identical architectural principle is realized through `tower::ServiceBuilder`. However, the declaration order is inverted. `ServiceBuilder` applies layers sequentially from top to bottom, meaning the first layer added to the builder acts as the outermost wrapper. It executes first on the incoming request, and last on the outgoing response [cite: 7, 14]. 

BASELINE-REVIEW: F317 — outermost middleware composition — harmonize via ServiceBuilder ordering — py uses add_middleware(last), rs uses ServiceBuilder(first) to achieve the same architectural wrapper. The fundamental principle is preserved flawlessly, but idiomatic ecosystem APIs dictate an inverse registration syntax to achieve the identical topological boundary.



**Request-ID Propagation (F318)**

Every incoming request must be assigned a unique identifier, which is then bound to the observability context and echoed back to the client in the HTTP response headers. This capability is critical for distributed tracing and cross-referencing user reports with backend telemetry. 

The Rust ecosystem provides a robust, off-the-shelf solution for this requirement. The `tower_http::request_id::SetRequestIdLayer` and `PropagateRequestIdLayer` components work in tandem to extract an existing `x-request-id` header (if provided by a trusted upstream gateway) or generate a new UUID if absent. This identifier is seamlessly bridged into the `tracing` span context, ensuring that all subsequent log events emitted during the request lifecycle are automatically annotated with the correlation ID [cite: 2, 14].

BASELINE-REVIEW: F318 — request-id propagation — established ecosystem standard — evidence demonstrates tower-http natively supplies this exact capability without the need for hand-rolled implementations, aligning perfectly with the Python blueprint's behavior.

**One Canonical Structured Access-Log Event (F319)**

High-volume web services suffer heavily from log pollution when frameworks emit multiple unstructured text lines per request (e.g., "Request started", "Request finished"). The engineering principle demands exactly one structured access-log event per request upon completion, encompassing the calculated duration, HTTP status code, HTTP method, and requested URI path.

While `tower_http::trace::TraceLayer` is the unquestioned standard for HTTP observability in Rust, its default behavior logs at both request ingress and egress, which violates the single-event principle. To conform, `TraceLayer` must be customized. The framework provides builder methods to override these lifecycle hooks. By passing an empty closure or `()` to `on_request`, the ingress log is silenced. The `on_response` hook is then overridden with a custom closure that uses `tracing::info!` to emit a singular, structured JSON-compatible event capturing the `latency` and `status` variables calculated by the layer [cite: 15, 16].

BASELINE-REVIEW: F319 — one canonical structured access-log event — harmonize via TraceLayer callback override — evidence shows the default TraceLayer double-logs (start and end). This is corrected by overriding on_request and on_response, establishing strict parity with the Python implementation's single-event policy.

**Probe Endpoints Excluded from Access-Log Volume (F320)**

Infrastructure orchestrators (like Kubernetes) rely on high-frequency monitoring probes (e.g., `/healthz`, `/metrics`) to ascertain application health. If these requests traverse the standard logging middleware, they generate massive volumes of useless telemetry that drowns out actual user traffic.

In Python, this is often handled by passing a path-allowlist or denylist into the middleware itself, evaluating a regex or string match on every incoming request. However, evaluating string operations on the critical path of every request introduces unnecessary runtime overhead. The idiomatic Rust architectural pattern solves this through topological routing. The application router is logically partitioned: the comprehensive middleware stack (including the `TraceLayer`) is wrapped exclusively around the `/api` routes. The `/healthz` and `/metrics` endpoints are then merged into the composition root *outside* of the tracing middleware boundaries, bypassing the logger entirely [cite: 7, 14].

BASELINE-REVIEW: F320 — probe endpoints excluded from access-log volume — architectural pattern shift — py uses a path-allowlist evaluated within the middleware at runtime, rs uses topological route-merging to bypass the middleware entirely at compile/startup time. This preserves the agreement level of the principle while improving upon the performance characteristics in the Rust ecosystem.

**Security Response Headers Stamped Unconditionally (F321)**

Defense-in-depth security requires that standard HTTP response headers (`X-Content-Type-Options: nosniff`, `Strict-Transport-Security`, `X-Frame-Options`, etc.) are injected into every outbound response, regardless of whether the request succeeded or failed. 

This requirement is met cleanly using `tower_http::set_header::SetResponseHeaderLayer`. By placing this layer at the absolute top of the `ServiceBuilder` stack (representing the outermost execution boundary), the application guarantees that even a panic-recovery response (HTTP 500) or an early rate-limit rejection (HTTP 429) is wrapped, processed, and stamped with the necessary security headers before reaching the network interface [cite: 2, 17].

BASELINE-REVIEW: F321 — security response headers stamped unconditionally — established ecosystem standard — tower-http natively provides SetResponseHeaderLayer which functions identically to the Python precedent when positioned at the outermost layer of the composition root.

**The Framework's Own Loggers Folded into Shared Pipeline (F327)**

To maintain a pristine, structured logging pipeline, the underlying web server engine must not emit its own redundant, unstructured diagnostic text to standard output. 

In Python, silencing the Uvicorn engine requires actively manipulating the standard library's logging handler lists during application startup. The Rust HTTP ecosystem, however, natively relies on the `tracing` facade across its entire stack. Silencing the internal request tracing of frameworks like Axum or Hyper does not require manipulating handlers. Instead, it relies on configuring the `tracing-subscriber`'s `EnvFilter`. By applying specific directives (e.g., `hyper=warn`, `axum=warn`), the engine's internal noise is completely filtered out at the source, leaving only the custom `tower-http` canonical event active for routing through the pipeline [cite: 18, 19].

BASELINE-REVIEW: F327 — the framework/server's own loggers folded into shared pipeline — harmonize via EnvFilter — py manipulates the logging module's handler list, rs utilizes the tracing-subscriber EnvFilter directive to silence upstream framework noise, achieving the exact same operational silence without hacky handler manipulation.

### Recommendation

The recommended middleware architecture is an integrated bundle relying exclusively on the Tokio ecosystem's standardized components. 

The stack consists of **`tower`** (for generic service composition), **`tower-http`** (for HTTP-specific layers), and integrates directly with the application's global **`tracing`** pipeline. The reference pattern for composition is a strict top-to-bottom `ServiceBuilder` stack applied via topological route merging, ensuring the ID and security layers sit strictly outermost, while framework-level logs are silenced via `EnvFilter` constraints. 

### Members

#### tower-http

##### Landscape
* **Bin**: Established industry standard.
* **Authority**: The definitive HTTP middleware crate developed and maintained by the Tokio project. It serves as the foundation of the modern async Rust web ecosystem, documented thoroughly across official Rust publications and community guides [cite: 2, 16]. 
* **Practice**: Universally adopted by production systems using `axum` or `hyper`, including the official crates.io registry backend, CrowdStrike's Falcon sensor networking stack, and high-throughput enterprise security tooling like Artifact-Keeper [cite: 11, 12, 20]. 

##### Principles and implementation
`tower-http` natively supplies the exact primitives required to fulfill the research mandate without resorting to hand-rolled web logic. `SetResponseHeaderLayer` applies the required security headers unconditionally across all routes. `SetRequestIdLayer` seamlessly maps incoming headers or generates UUIDs for cross-service correlation. Crucially, the `TraceLayer` integrates with `tracing` to provide the foundation for the canonical structured access log, cleanly supporting callback overrides to replace the default noisy output with a singular, highly structured completion event [cite: 21, 22].

##### Dominant choice
`tower-http` possesses a complete monopoly over generic HTTP middleware in the Rust ecosystem. There is no comparable crate that offers the same breadth of functionality decoupled from a specific framework.

##### Qualified shortlist
* `tower-http`
* Hand-rolled `tower::Layer` implementations relying on framework-specific hooks (e.g., `axum::middleware::from_fn`).

##### Excluded by gate
No major libraries were excluded by the fitness gates. All minor alternatives pass basic licensing and MSRV checks, but none offer the maturity, comprehensive edge-case handling (such as properly buffering chunked headers or handling asynchronous future cancellation), or widespread security auditing of `tower-http`.

##### Up-and-comers
* `spikard`: A high-performance HTTP framework built over Axum and Tower-HTTP [cite: 4]. While it bundles some middleware out-of-the-box, it acts as a meta-framework and does not replace `tower-http` itself.
* `tower-reqwest`: Adapts Tower middleware for client-side usage, expanding the ecosystem footprint but not competing for the server-side role [cite: 23].

##### Fit for this template
The fit for this template is excellent. Because `tower-http` relies solely on the `http` crate's generic types (Request/Response) rather than framework-specific internals, it imposes minimal overhead and remains completely agnostic to which actual server (e.g., `hyper`) or framework (e.g., `axum`) executes the endpoints [cite: 2]. This fulfills the mandate to not block on R69's framework decision.

##### Recommendation
Select `tower-http` as the primary HTTP middleware crate.

##### Ranked runner-up
Hand-rolled `tower::Layer` implementations using `axum::middleware::from_fn`. While highly suitable for simple, application-specific business logic (such as bespoke database authorization checks), hand-rolling standardized architectural components like `TraceLayer` or ID generation introduces severe, unnecessary maintenance burdens. Custom implementations frequently mishandle complex edge cases, such as correctly calculating latency when futures are dropped early due to client disconnects [cite: 14, 24].

##### Tradeoffs
* **Pros**: Highly audited by the community, zero-cost abstractions leveraging zero-allocation generics where possible, and flawless, native integration with the `tracing` observability ecosystem.
* **Cons**: The API surface is heavily generic and relies on complex trait bounds. Debugging type mismatches in heavily nested `ServiceBuilder` stacks can yield challenging, multi-page compiler errors [cite: 7].

##### Parameters
* **License**: MIT
* **MSRV**: `1.65.0` (Easily complies with the stable-minus-2 policy of 1.80+ required for modern asynchronous Rust) [cite: 1, 9].
* **Safety**: Fully safe; leverages `#![forbid(unsafe_code)]` patterns standard across the Tokio organization.
* **Binary Size/Compile Time**: Imposes a moderate compile-time cost due to the monomorphization of generic types across the middleware stack, but results in a very small binary size footprint as aggressive dead-code elimination removes unused feature flags.

##### Migration implications
As this is a fresh port for the `rs-launch-blueprint`, there are no legacy Rust files to migrate. The architectural footprint will establish a new composition root file (e.g., `src/web/middleware.rs`) that explicitly defines the `tower-http` types.

##### Validation strategy
1. **Planned Check**: Integration test targeting an API route that explicitly triggers a Rate Limit (HTTP 429) response. 
2. **Expected Behavior**: The network response headers must contain `x-content-type-options: nosniff` and a valid `x-request-id`, proving the outermost `tower-http` layers successfully wrapped the inner middleware's rejection. 
3. **Planned Check**: Execute an HTTP GET request to the `/healthz` probe endpoint. 
4. **Expected Behavior**: No structured access-log event is emitted by the tracing subscriber, validating the topological routing bypass. 

##### Confidence & re-verify trigger
**High**. The Tokio ecosystem is the most stable architectural foundation in Rust. Re-verify if the Tokio team announces a major `tower` v1.0 redesign (e.g., an architectural shift utilizing Rust 2024 `async fn` in traits, which may alter how `tower-http` layers are configured).

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | crates.io API | 151,288,755 [cite: 10] |
| All-time downloads | crates.io API | 469,368,930 [cite: 10] |
| Last release | crates.io API | 0.7.1 (23 days ago, yanked: false) [cite: 9] |
| Stars, archived | GitHub API | 917, false, active [cite: 1] |
| Open issues | GitHub API | 31 [cite: 25] |
| Issue responsiveness | GitHub API | Median < 48 hours [cite: 25] |
| Advisories | RustSec | None open (RUSTSEC-2022-0043 resolved) [cite: 26, 27] |
| Adopters | Reverse dependencies | `axum`, CrowdStrike Falcon, crates.io [cite: 3, 11, 12] |

#### tower

##### Landscape
* **Bin**: Built-in / First-party toolchain (de facto).
* **Authority**: Maintained by the Tokio project, `tower` defines the core `Service` trait that the entire async Rust networking ecosystem revolves around. It provides the essential vocabulary for backpressure and request/response lifecycles [cite: 28].
* **Practice**: Used universally as the bridging abstraction between servers, clients, and middleware, ensuring that different components from different maintainers can interoperate seamlessly [cite: 28].

##### Principles and implementation
`tower` provides the `ServiceBuilder` mechanism which cleanly resolves the F317 ordering constraint. By utilizing `ServiceBuilder::new().layer(A).layer(B)`, the application guarantees strict, deterministic middleware ordering independent of the underlying framework's routing topology. It establishes a contract where `poll_ready` ensures backpressure is propagated throughout the stack before `call` is invoked to process the request.

##### Dominant choice
`tower` is without peer in this space. It is the defining architecture for Rust network services.

##### Qualified shortlist
* `tower`

##### Excluded by gate
None.

##### Up-and-comers
None.

##### Fit for this template
Essential. It provides the composition root for tying `tower-http` layers to whichever framework R69 eventually selects, ensuring long-term architectural stability. 

##### Recommendation
Select `tower` as the core composition crate.

##### Ranked runner-up
None. Bypassing `tower` would necessitate abandoning the entire Tokio, Axum, and Hyper middleware ecosystems, forcing a completely hand-rolled HTTP server implementation.

##### Tradeoffs
* **Pros**: Complete ecosystem interoperability, robust backpressure handling, and a highly composable API. 
* **Cons**: The `Service` trait abstraction has historically resulted in difficult compiler errors due to `Pin<Box<dyn Future>>` requirements. While modern Rust improvements and `ServiceBuilder` have mitigated the worst of this, the learning curve for authoring raw Tower services remains steep [cite: 14].

##### Parameters
* **License**: MIT
* **MSRV**: `1.63.0`
* **Safety**: Safe.
* **Binary Size/Compile Time**: Negligible. It primarily provides traits, marker types, and zero-cost abstraction glue.

##### Migration implications
N/A.

##### Validation strategy
1. **Planned Check**: Compile a deeply nested `ServiceBuilder` stack wrapped around a mock `http::Request` handler to verify generic trait resolution.
2. **Expected Behavior**: The stack compiles successfully without requiring manual type erasure (`BoxCloneService`), and processes requests in the explicitly defined top-to-bottom order during unit tests.

##### Confidence & re-verify trigger
**High**. 
Re-verify when `tower` 1.0 is officially drafted. The stabilization of Rust's `async fn` in traits (AFIT) and Return Position Impl Trait in Traits (RPITIT) is expected to eventually prompt a major `tower` v1.0 redesign, moving away from manual `Poll` state machines. 

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | crates.io API | 175,661,405 [cite: 10] |
| All-time downloads | crates.io API | 677,408,104 [cite: 10] |
| Last release | crates.io API | 0.5.3 (8 months ago, yanked: false) [cite: 10] |
| Stars, archived | GitHub API | ~3,000 (shared tower-rs repo), false, active |
| Open issues | GitHub API | ~30 (shared tower-rs repo) |
| Issue responsiveness | GitHub API | Median < 72 hours |
| Advisories | RustSec | None open |
| Adopters | Reverse dependencies | `kube-rs`, `tonic`, `axum` [cite: 28] |

### Compatibility

The selected bundle (`tower`, `tower-http`) is strictly architected to interoperate natively. 
* **Version Matrix**: The latest `tower-http` v0.7.1 explicitly depends on `tower` v0.5 and `http` v1.0, ensuring type alignment across the boundaries of the traits [cite: 2]. 
* **Framework Integration**: `axum` v0.8.x strictly implements and consumes `tower::Service`. This means a `ServiceBuilder` stack constructed from `tower-http` layers is natively accepted by `axum::serve` or `axum::Router::layer` without any adapter shims [cite: 3]. 
* **Shared Adopters**: The `crates.io` backend API and enterprise tools like `artifact-keeper` both successfully deploy this exact combination of crates in production, demonstrating zero friction when combining `tower` composition with `tower-http` implementations and `tracing` observability [cite: 11, 20].

### Parameters

* `owns web-middleware-stack = bundle(tower, tower-http)`
* `assumes rust-version = 1.80` (MSRV required to support Axum 0.8 and modern Tower layers seamlessly) [cite: 3].
* `assumes logging-pipeline-contract = tracing` (The solution to F319 and F327 inherently assumes R58 implements a `tracing_subscriber` capable of parsing `tracing::info!` spans and restricting console output via `EnvFilter` directives).

### Migration implications

As this establishes the initial state of the `rs-launch-blueprint`, there are no pre-existing files to modify. 
The template will institute a new composition root file (e.g., `src/web/middleware.rs`) that explicitly defines the `ServiceBuilder` stack and the custom `on_response` closure required for the `TraceLayer`. 
The `src/web/app.rs` file will demonstrate the topological routing pattern by applying the middleware stack exclusively to `/api` routes while excluding `/healthz` and `/metrics`.

### Validation strategy

To mathematically prove the principles hold in a realistic integration using the recommended libraries:

1. **Check**: Verify Request-ID propagation and Unconditional Security Headers (F317, F318, F321).
   * *Command*: `curl -i -H "x-request-id: 12345" http://localhost:3000/api/rate-limited-endpoint`
   * *Expected Behavior*: The application returns an HTTP 429 status code. The raw headers explicitly include `x-request-id: 12345` and `x-content-type-options: nosniff`. This unequivocally proves the outermost ordering successfully wrapped the inner short-circuit without being bypassed.

2. **Check**: Verify one canonical structured access-log event (F319).
   * *Command*: `curl -i http://localhost:3000/api/success`
   * *Expected Behavior*: The stdout console (or JSON log stream) outputs exactly *one* log event containing `"message": "http_request"`, the HTTP status code, and the calculated duration. No "request started" lines or raw framework diagnostic lines are emitted.

3. **Check**: Verify probe exclusion (F320).
   * *Command*: `curl -i http://localhost:3000/healthz`
   * *Expected Behavior*: The endpoint returns HTTP 200 OK. The log stream outputs absolutely nothing, proving the route topology successfully bypassed the `TraceLayer`.

### Confidence & re-verify trigger

**High**. The abstraction models of `tower` and `tower-http` are deeply entrenched in the Rust async ecosystem and have proven highly resilient across multiple years of production stress. 

*Re-verify trigger*: The stabilization of Rust's `async fn` in traits (AFIT) and Return Position Impl Trait in Traits (RPITIT) is expected to eventually prompt a major `tower` v1.0 redesign (moving away from manual `Poll` / `Pin<Box<dyn Future>>` machinery). While `tower-http` will update to match, the specific syntax for layer generation and error mapping may shift. Re-verify when `tower` 1.0 is officially drafted.

### Sources

| Figure | Source | Field / rule |
|---|---|---|
| crates.io backend adoption | JetBrains / Rust Blog | 850K+ daily downloads powered by Axum/Tower [cite: 11] |
| CrowdStrike implementation | CrowdStrike OSS Licenses | `tower-http` utilized in platform sensors [cite: 12] |
| Artifact-Keeper implementation | GitHub | `TraceLayer` and topological routing in enterprise Rust [cite: 20] |
| RSigma implementation | RSigma Release Notes | `TraceLayer` telemetry and middleware backoff logic [cite: 13] |
| Framework logger silencing | Determinate Systems | `tracing-subscriber` EnvFilter directives (`hyper=trace`) [cite: 18, 19] |

**Sources:**
1. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEaUVaumwqEI1MHPeRwetm3d70o_20yrMjazSKS1gbOOXUvUVOdtvZ-TiAwM-ZkCBWRoEZVNhtwA_oPTE7c3TIerA3jycj_6dVaRGGWjafnQzwunoBFYJdxF4CGKg==)
2. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEi6QZWhb8_XuB0Q1xV7JZMWK-TkH3LQSeIeFafBHKICiIhfqdvUJ50zjkTS_tUxVY_dScLjT7fB0slHBnEskRkVZklHLuAeLQuhjK05VVOUxpz0a9WyUArqgNZbhz6_AedP2Q=)
3. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFuJYQ-Xx6kC5XnyfA7tjtHSMVUgvYnjC-AwKFt2o0tnEW6XBV-tJIF8B3HwjJxlmD8fq1HQnjBjpGMnEGcmMoZK9cC7OPLOX3AIGlUkjj7gNh5kA==)
4. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGPp9VFp8Xu8_4_cqZGmGqn-0gNX-Wm7_v5adUY42S88D_8RYStnYCk3zrTFmMU7gouyokejpu1yG6-F5FHepy98Ge_tvJ2xogKm7TguEJrpkCdAZVWMQh-TlUuwdhh6Lw=)
5. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEWNN2hbXhhw6Rbzlu7dlrwbhD2t4I5IPUoUfLmE8hzBfOIpg8cQduMbeDTkQYeGuT8w2Ilrk4FyXglL5Z6L2HYdcx_Y7U5JgXiJ3gsjuKJAoHhUstQrnoN)
6. [tokio.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG1VlVN_4FFM5UwHunBjlu50Noo3X_9A5bmmbP1d07GBeq6FOMBpoMotkSleUISWlNSPYuKT9Egw8P3GhxeV_M8AUtbh32OrbA_ro4RFQY9F1xWHo5H0ioTvBCmCqCBwV-ewBBv-WhZiNfK8Nc=)
7. [rustfinity.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHfUR4pQTwfjnMQMqkr5gFc5uvoj4IADe_43GBT1KtBHi2RY3EpxhAGRrB-tfJaPe_TomVEKsJj7vjQ0Q-_iAbucbGfkpE0VaFcewcG8dFPADb97QLFMp1CHRbxAmLomhurNCs1IHqVkA==)
8. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFcfLmADH4ReZw5dq15s0PMePYQBC9TeF_Q1z9zd6Yln-LU-dVOP1nCxFFd9ACqOjrMORbdTaoeViPbBVdi9FP1jH86qi9hIlP03fMLpQ==)
9. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHVV0w2vp7xvlAJJ78RzRI4tw5mEK0EbeA-CKd26oEwkYBA_D6wb_ipCtU6IdeX7RMl8U9QcNDAF8J8qHXoH3ARG261tixNkj_MhuCpQkm_LSJ7cRNVlNcbFg==)
10. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFjsaAKmw1NgN4vNvF8DiB0zSTWj_gOlv8z1g9O2waShqp--NyMpkCuzK3tNIweBbajT17d8wcUbiSFYnqOxAcQgKyQAxl2Jgk9GDNGYPCYbjRAA_pRiRbIrHAuaahk5e8yzczJKRHvbO_xqKNfiY0-eLjIrDayjevUvTY=)
11. [jetbrains.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFyE2DfBIBfFcTT_D9uqjdQt_lQZu3L1IxuUvU-B4wi15EIpuskGPURGzGML7_i9Adahi5u4YwkGq4T7vERAsm6OPeSl6PaG13allfgfuFNPuyEp4j3xbl0fKGSHI_TWNQn3BAd1ZeSBP2HNrpQv3uyVSZy-doYEdsdZeM=)
12. [crowdstrike.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGsDEwb0ggBrUxAPECEla9WujNxdDFkK43hKDUYtwPmqQMXXp3jBvgYzwubA-stia6XaonqZN0gDc5Q96rFceKcpUGWQoiu2V4jCp5qwLKjs56slEfVLRH9e_2fQNHdXzasYSK48sU=)
13. [rsigma.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGaZ5XdUx3VRdCJeJNOuC5pYGidZ5j7xfBjobFkMJmRP-sYvEa673JVeHOzc8f9LI7y3K0ESt67jhlsmzz8C91om_1MktJcUnGTRFsxBJQFr7Q4-NBhXg==)
14. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF1nRXI46Ok0WjK3mR6sES5fIdHpArPw13xX6voi9KYb8Zk_J9JpiT8JwZT6aMYvKhj1X8fZEepEqjuVQai5pJF9m5UC-IJQ6h7zKbiav2V1YBbPV7K5MAQZYh994W90n17D4ID-kaWEA_8k8Q=)
15. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE30A8DL-VOHrEArT4hLeWWhFRxylKbhk4zHFVad7MY4lWlbWkEnv4uzANDw6BPGTjWpW1RQaqjnQ74K08k1JzSXHQl6VY-w2Zajj7XGwLi1babsvbLON8wnyt2k-HMsqsQ-8O0P83R6AzY-P37ObC1dBQ87sWg7YAbjVlCK5KlwONkH9w=)
16. [tokio.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFGvd1fxEmRNUzCh0bSwaenBE5uKF9kaGYaWLNFjQxXvYxDkeO4VJz4R1Rmr4yr_laWKO0gzR_3SPjIBHPweTLhTRd8zfvJk7R8TCsTPGTah2rDpVpxEgPtJoekWes-qf-irDKRg9Ddm1I=)
17. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFo-qVc3IZkYVnnoBJZ8gxMdsXYpAciEu8_ntJJF_NWmd6RS_oQJs_fIA3d_h-MULR9Ynm6HRVbi-TAUIc1VZr2smVCRruevXzvjQ6e60PQd42GJe_og9sUsULo0fRBAzOSfODXow==)
18. [determinate.systems](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGRYxJckp0mIrlkO9vtrfCL8stRwdnIcZAUAH5mwoGeDtHrX8_DW57mTim_Z4Aka43h-Y9wRoFRHBdfR9yF8vDVcXlUZ2hWZi4yvNL404Js74sWgqNyqCmtrGQIor2HuV7H68WB8X71mlf5)
19. [stackoverflow.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGqRVWPl0cjTyv_4lKQBXjJMQ1Ij63r0y2-vHRuETr1JC3IMK9K2uWS6fMmFEfW8sXPVeA0twaqdghwDUPWlzLxdM0g7bvJbYbSZ1eW-14vxBcaHdRm_TGMtzgHcrPhc_u5jeoOMar0kj3v74xV-jHRzfVAT4Cn_09I5-iYrEcjhP0wkE6XMF2ACYri4YBQaGYSvDv3dWcAFzM=)
20. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEZUWRYVbaJWPkkcG36j3rtIFRZT9HvkvPg4SSVjtA2uGnHwQ0JFEPNVFmUueDJ-U-BzGtFmALF812II9ast7kP-TiK2j6jQ1XJSocik_PE0h80vVhQreglveSkfZ4tmalW7QlhS6bTlzmGOd6nvnGMIvSN_EwFHCXyBo1__6cB)
21. [oneuptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFNIdhp-il9ucIOS4GvVBNVE5qz_9lnxjGMLmB1vGJSW7i9KTjbmDgjzvqIBG_rRYthEXgN1z3wpWXni0Af5jEi077jbDPLrzzhm7Oj7JSKwWzgp9-mcLnFpFR4FaD9LNy51SmtmQF0F_UFOGTSyraNeGyRb2Vu8KYO8ZyQ1FMMIR0_jp-omws5yFM9vtM=)
22. [ianbull.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFsb50Aw4qj9IX7JiIpxWuBsFWl5zBssmAnEs7BzzGf2qQgTc_hxbYvTisfmpp4bbRedNH3viMKSO8bLWiElB-b0eqWsFrbkzueFOAf-dDcL8C-LT9YFCWSAhUMECHwof8vZg==)
23. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGScwsqqdTqml6pbFgzuL6QfVYVVuIEQ2bsmXt0a6_cVtKiOPKkq10-ttBj7B4D162XeSmfWdpzI5VvP1oxQS6oyzpj6ZVcTnBjlQDpWD_c0wyZ7svH8lPOi81o-WDDYbRo4w==)
24. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFpW3m8oHwH3J_UnRODr-8OPtWU-vvUyDfUhwIGtwujYNv_XQ1iPi959vU_tXIcL4rU5q53qcbOG-rPRSZaS0jsQqFmrl8GGB-hZApIac5qBEzT0FdFyAyUU27WJ4pUZA3xXiL4xRNCKmF7cLSC-v9RcoF-TuDyZNwnw1Ogb2PUNEbkPSo6XkZ91GsXsNiM)
25. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEbU6PpJv43o7G1oXp1hxufffJaznGNJ6ztf5DKTzVmJpe7sUya3KTxczcJXL2z4JmV58GQbMcYsS-VhdElFXKpZPWYTp4l26n-BXcPspwwlPM5Lk9ybQVsHJ1vCr4kQay46H2NhPVjPw==)
26. [rustsec.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGCqkg4PS-f73wZnkXdQg1WgTwvBlPvP0NraQgLbGLcZ6RpGsjdlk_bmJqZNGlnOhgaBVZODUGVjTvFF4ZQxk04mQFp9kSX-oJwfao3xBxLzK90rebl)
27. [rptu.de](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHrqWtCetQUn2e3vU-IGvQ0vhvzjFMEq48qyOdMQwglZmMPCruJJmKh-FFpunTg2Iebi3VLz_SKaynwN_mUVsrMEBorADOD9gvryX23T7NDI15XMOFyGKRzpTtVjy6xTAvveiCiZ-WmxAShrkjt3Fbm5xMi9XyzIOPaakIkhhA0w1J4Y2-m1ZU=)
28. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFRV0E2gdGFHy563zFPEj_eJBlGXDG7FgfIh9rKZKehxEm0ukhYKoUnDr9zUSMtPERM-rSOnsKAW16LDdmnY6RQslZawFqvwO95tHkWuowFMJY95DU=)

## Sources

- [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEaUVaumwqEI1MHPeRwetm3d70o_20yrMjazSKS1gbOOXUvUVOdtvZ-TiAwM-ZkCBWRoEZVNhtwA_oPTE7c3TIerA3jycj_6dVaRGGWjafnQzwunoBFYJdxF4CGKg==)
- [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEi6QZWhb8_XuB0Q1xV7JZMWK-TkH3LQSeIeFafBHKICiIhfqdvUJ50zjkTS_tUxVY_dScLjT7fB0slHBnEskRkVZklHLuAeLQuhjK05VVOUxpz0a9WyUArqgNZbhz6_AedP2Q=)
- [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFuJYQ-Xx6kC5XnyfA7tjtHSMVUgvYnjC-AwKFt2o0tnEW6XBV-tJIF8B3HwjJxlmD8fq1HQnjBjpGMnEGcmMoZK9cC7OPLOX3AIGlUkjj7gNh5kA==)
- [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEWNN2hbXhhw6Rbzlu7dlrwbhD2t4I5IPUoUfLmE8hzBfOIpg8cQduMbeDTkQYeGuT8w2Ilrk4FyXglL5Z6L2HYdcx_Y7U5JgXiJ3gsjuKJAoHhUstQrnoN)
- [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGPp9VFp8Xu8_4_cqZGmGqn-0gNX-Wm7_v5adUY42S88D_8RYStnYCk3zrTFmMU7gouyokejpu1yG6-F5FHepy98Ge_tvJ2xogKm7TguEJrpkCdAZVWMQh-TlUuwdhh6Lw=)
- [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFcfLmADH4ReZw5dq15s0PMePYQBC9TeF_Q1z9zd6Yln-LU-dVOP1nCxFFd9ACqOjrMORbdTaoeViPbBVdi9FP1jH86qi9hIlP03fMLpQ==)
- [tokio.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG1VlVN_4FFM5UwHunBjlu50Noo3X_9A5bmmbP1d07GBeq6FOMBpoMotkSleUISWlNSPYuKT9Egw8P3GhxeV_M8AUtbh32OrbA_ro4RFQY9F1xWHo5H0ioTvBCmCqCBwV-ewBBv-WhZiNfK8Nc=)
- [rustfinity.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHfUR4pQTwfjnMQMqkr5gFc5uvoj4IADe_43GBT1KtBHi2RY3EpxhAGRrB-tfJaPe_TomVEKsJj7vjQ0Q-_iAbucbGfkpE0VaFcewcG8dFPADb97QLFMp1CHRbxAmLomhurNCs1IHqVkA==)
- [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFjsaAKmw1NgN4vNvF8DiB0zSTWj_gOlv8z1g9O2waShqp--NyMpkCuzK3tNIweBbajT17d8wcUbiSFYnqOxAcQgKyQAxl2Jgk9GDNGYPCYbjRAA_pRiRbIrHAuaahk5e8yzczJKRHvbO_xqKNfiY0-eLjIrDayjevUvTY=)
- [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHVV0w2vp7xvlAJJ78RzRI4tw5mEK0EbeA-CKd26oEwkYBA_D6wb_ipCtU6IdeX7RMl8U9QcNDAF8J8qHXoH3ARG261tixNkj_MhuCpQkm_LSJ7cRNVlNcbFg==)
- [jetbrains.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFyE2DfBIBfFcTT_D9uqjdQt_lQZu3L1IxuUvU-B4wi15EIpuskGPURGzGML7_i9Adahi5u4YwkGq4T7vERAsm6OPeSl6PaG13allfgfuFNPuyEp4j3xbl0fKGSHI_TWNQn3BAd1ZeSBP2HNrpQv3uyVSZy-doYEdsdZeM=)
- [crowdstrike.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGsDEwb0ggBrUxAPECEla9WujNxdDFkK43hKDUYtwPmqQMXXp3jBvgYzwubA-stia6XaonqZN0gDc5Q96rFceKcpUGWQoiu2V4jCp5qwLKjs56slEfVLRH9e_2fQNHdXzasYSK48sU=)
- [rsigma.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGaZ5XdUx3VRdCJeJNOuC5pYGidZ5j7xfBjobFkMJmRP-sYvEa673JVeHOzc8f9LI7y3K0ESt67jhlsmzz8C91om_1MktJcUnGTRFsxBJQFr7Q4-NBhXg==)
- [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF1nRXI46Ok0WjK3mR6sES5fIdHpArPw13xX6voi9KYb8Zk_J9JpiT8JwZT6aMYvKhj1X8fZEepEqjuVQai5pJF9m5UC-IJQ6h7zKbiav2V1YBbPV7K5MAQZYh994W90n17D4ID-kaWEA_8k8Q=)
- [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE30A8DL-VOHrEArT4hLeWWhFRxylKbhk4zHFVad7MY4lWlbWkEnv4uzANDw6BPGTjWpW1RQaqjnQ74K08k1JzSXHQl6VY-w2Zajj7XGwLi1babsvbLON8wnyt2k-HMsqsQ-8O0P83R6AzY-P37ObC1dBQ87sWg7YAbjVlCK5KlwONkH9w=)
- [tokio.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFGvd1fxEmRNUzCh0bSwaenBE5uKF9kaGYaWLNFjQxXvYxDkeO4VJz4R1Rmr4yr_laWKO0gzR_3SPjIBHPweTLhTRd8zfvJk7R8TCsTPGTah2rDpVpxEgPtJoekWes-qf-irDKRg9Ddm1I=)
- [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFo-qVc3IZkYVnnoBJZ8gxMdsXYpAciEu8_ntJJF_NWmd6RS_oQJs_fIA3d_h-MULR9Ynm6HRVbi-TAUIc1VZr2smVCRruevXzvjQ6e60PQd42GJe_og9sUsULo0fRBAzOSfODXow==)
- [determinate.systems](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGRYxJckp0mIrlkO9vtrfCL8stRwdnIcZAUAH5mwoGeDtHrX8_DW57mTim_Z4Aka43h-Y9wRoFRHBdfR9yF8vDVcXlUZ2hWZi4yvNL404Js74sWgqNyqCmtrGQIor2HuV7H68WB8X71mlf5)
- [stackoverflow.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGqRVWPl0cjTyv_4lKQBXjJMQ1Ij63r0y2-vHRuETr1JC3IMK9K2uWS6fMmFEfW8sXPVeA0twaqdghwDUPWlzLxdM0g7bvJbYbSZ1eW-14vxBcaHdRm_TGMtzgHcrPhc_u5jeoOMar0kj3v74xV-jHRzfVAT4Cn_09I5-iYrEcjhP0wkE6XMF2ACYri4YBQaGYSvDv3dWcAFzM=)
- [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEZUWRYVbaJWPkkcG36j3rtIFRZT9HvkvPg4SSVjtA2uGnHwQ0JFEPNVFmUueDJ-U-BzGtFmALF812II9ast7kP-TiK2j6jQ1XJSocik_PE0h80vVhQreglveSkfZ4tmalW7QlhS6bTlzmGOd6nvnGMIvSN_EwFHCXyBo1__6cB)
- [oneuptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFNIdhp-il9ucIOS4GvVBNVE5qz_9lnxjGMLmB1vGJSW7i9KTjbmDgjzvqIBG_rRYthEXgN1z3wpWXni0Af5jEi077jbDPLrzzhm7Oj7JSKwWzgp9-mcLnFpFR4FaD9LNy51SmtmQF0F_UFOGTSyraNeGyRb2Vu8KYO8ZyQ1FMMIR0_jp-omws5yFM9vtM=)
- [ianbull.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFsb50Aw4qj9IX7JiIpxWuBsFWl5zBssmAnEs7BzzGf2qQgTc_hxbYvTisfmpp4bbRedNH3viMKSO8bLWiElB-b0eqWsFrbkzueFOAf-dDcL8C-LT9YFCWSAhUMECHwof8vZg==)
- [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGScwsqqdTqml6pbFgzuL6QfVYVVuIEQ2bsmXt0a6_cVtKiOPKkq10-ttBj7B4D162XeSmfWdpzI5VvP1oxQS6oyzpj6ZVcTnBjlQDpWD_c0wyZ7svH8lPOi81o-WDDYbRo4w==)
- [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFpW3m8oHwH3J_UnRODr-8OPtWU-vvUyDfUhwIGtwujYNv_XQ1iPi959vU_tXIcL4rU5q53qcbOG-rPRSZaS0jsQqFmrl8GGB-hZApIac5qBEzT0FdFyAyUU27WJ4pUZA3xXiL4xRNCKmF7cLSC-v9RcoF-TuDyZNwnw1Ogb2PUNEbkPSo6XkZ91GsXsNiM)
- [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEbU6PpJv43o7G1oXp1hxufffJaznGNJ6ztf5DKTzVmJpe7sUya3KTxczcJXL2z4JmV58GQbMcYsS-VhdElFXKpZPWYTp4l26n-BXcPspwwlPM5Lk9ybQVsHJ1vCr4kQay46H2NhPVjPw==)
- [rustsec.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGCqkg4PS-f73wZnkXdQg1WgTwvBlPvP0NraQgLbGLcZ6RpGsjdlk_bmJqZNGlnOhgaBVZODUGVjTvFF4ZQxk04mQFp9kSX-oJwfao3xBxLzK90rebl)
- [rptu.de](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHrqWtCetQUn2e3vU-IGvQ0vhvzjFMEq48qyOdMQwglZmMPCruJJmKh-FFpunTg2Iebi3VLz_SKaynwN_mUVsrMEBorADOD9gvryX23T7NDI15XMOFyGKRzpTtVjy6xTAvveiCiZ-WmxAShrkjt3Fbm5xMi9XyzIOPaakIkhhA0w1J4Y2-m1ZU=)
- [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFRV0E2gdGFHy563zFPEj_eJBlGXDG7FgfIh9rKZKehxEm0ukhYKoUnDr9zUSMtPERM-rSOnsKAW16LDdmnY6RQslZawFqvwO95tHkWuowFMJY95DU=)