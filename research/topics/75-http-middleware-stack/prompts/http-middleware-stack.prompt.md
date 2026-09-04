# Deep-research prompt — HTTP middleware stack (R75, bundle)

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
- consumes:
- related (not a registry dependency): R69 (`web-framework-stack`) decides which framework/server this middleware stack runs on and which layer/middleware model it exposes — treat R69's choice as open, do not block on it. R58 (`logging-pipeline-architecture`) owns F263, the pipeline-profile side of the same web-logger integration point this item's F327 addresses from the framework side; see F263's ledger note for the split.
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

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
The full `crate` field set for each member.
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
