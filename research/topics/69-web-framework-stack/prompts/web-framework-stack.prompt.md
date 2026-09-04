# Deep-research prompt — Web framework stack (R69, bundle)

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

## Out of scope
- The specific features layered on top of the chosen framework once it exists — the error envelope (R70 owns F305/F306), OpenAPI generation (R71 owns F307/F312/F332/F333), pagination (R72 owns F310/F311), idempotency replay (R73 owns F313-F315), rate limiting (R74 owns F316/F323), middleware ordering/request-id/access-log/security headers (R75 owns F317-F321/F327), CORS (R76 owns F322), typed env settings (R77 owns F324), OpenTelemetry (R78 owns F325), Prometheus metrics (R79 owns F326), health probe endpoints (R80 owns F328/F329), and the production container image (R51) — this item decides only the framework/server crate stack, the Cargo feature-gate shape, the config-injection mechanism, and the process entrypoint they all sit inside.
- Whether the web service ships as an optional Cargo feature at all; ledger row F017 (area `workspace-architecture`) already answered `ADOPT` with no research item — this item decides which framework fills that feature, not whether the feature exists.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R69
- owns: web-extra-surface
- consumes: R01: http-transport-injection-seam
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
