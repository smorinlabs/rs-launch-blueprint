# Deep-research prompt — OpenAPI generation pipeline (R71, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts an OpenAPI-generation crate with a schema post-processing step to match the runtime error envelope, curated stable operation ids, a committed OpenAPI snapshot tested for staleness, and CI breaking-change detection against the base branch. Item kind: `bundle`. Value test: if this answer is wrong, the OpenAPI-generation dependency, the schema post-processing step, the committed snapshot file and its staleness test, and the CI breaking-change-detection job all get rewritten — and R83's contract-fuzzing suite and R84's typed client generation, which both consume the committed snapshot, inherit a wrong contract.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py generates its OpenAPI schema from the framework, then post-processes it to keep the documented error shape in sync with its runtime problem+json envelope, curates stable per-route operation ids so generated-client method names don't churn, commits the resulting spec as the reviewable API contract with a staleness test, and runs CI breaking-change detection against the base branch whenever the spec changes. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/problems.py:104` — `original_openapi = app.openapi`, wrapped to rewrite 422 responses (WEB-01/WEB-04); ts: none. Ledger rows: F307, F312, F332, F333 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F312 curated stable operation ids — py `src/py_launch_blueprint/web/app.py:77` (`def _operation_id(route: APIRoute) -> str:`, WEB-04, keeps generated-client method names stable across schema regen); ts: none. F332 committed OpenAPI snapshot, staleness-tested — py `docs/api/openapi.json` (committed spec file), `tests/web/test_openapi_snapshot.py:30` (`generated["info"]["version"] = SNAPSHOT_VERSION` then compared, WEB-51), `Justfile:307` (`just export-openapi` regenerates it); ts: none. F333 breaking-change detection in CI — py `.github/workflows/api-contract.yml:44` (`uses: oasdiff/oasdiff-action/breaking@v0.1.6`, runs only when `docs/api/openapi.json` changes in a PR, WEB-51); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). Whether the breaking-change-detection job is its own workflow file (py's choice, `.github/workflows/api-contract.yml`) or a step folded into a shared CI job follows R11's `ci-job-structure` decision, not yet made — design this item's check as a tool invocation that either placement can host.
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no decision addressing web-service scope; ts never built a web service, so there is no OpenAPI pipeline to reconcile with.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): This one, I'd look at the principle of what Py Launch Blueprint is doing and if we should do the same at all.

## Out of scope
- The web framework itself and whether the web/API surface exists as a Cargo feature; R69 (`web-framework-stack`) owns F303 and the `web-extra-surface` parameter — assume R69 resolves to some OpenAPI-capable framework and design this pipeline to fit whichever framework wins.
- The error envelope's own shape and its domain-error-to-status mapping; R70 (`http-problem-envelope`) owns F305/F306 — this item only decides how the OpenAPI schema is kept in sync with whatever envelope R70 lands on.
- Whether the breaking-change-detection check is its own workflow file or a step folded into a shared CI job; R11 (`ci-workflow-job-structure`) owns `ci-job-structure` — this item decides which tool runs the check and what it checks, not its placement in CI topology.
- The typed client generated from this snapshot and its own contract-fuzzing suite; R84 (`openapi-typed-client-generation`) and R83 (`openapi-contract-fuzzing`) own those — this item only produces and gates the committed snapshot they each consume.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R71
- owns:
- consumes: R11: ci-job-structure; R69: web-extra-surface
- related (not a registry dependency): R70 (`http-problem-envelope`) decides the error envelope shape (F305/F306) that this item's schema post-processing (F307) must stay in sync with — treat R70's shape as open, do not block on it. R83 (`openapi-contract-fuzzing`) and R84 (`openapi-typed-client-generation`) each consume the committed snapshot this item produces (F332) — do not decide their scope here.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` adopts an OpenAPI-generation crate with a schema post-processing step to match the runtime error envelope, curated stable operation ids, a committed OpenAPI snapshot tested for staleness, and CI breaking-change detection against the base branch.
- HIGH: Which Rust OpenAPI-generation crate (e.g. `utoipa`, `aide`, `okapi`) integrates with the leading async web frameworks and supports post-generation schema rewriting, so a framework's default validation-error schema can be reshaped into whatever problem+json envelope R70 lands on (mirroring py's `original_openapi` wrap)?
- HIGH: What mechanism gives stable, curated operation ids (F312) — a crate-supported per-route override, a derive attribute, or a post-processing rewrite pass equivalent to py's `_operation_id()` — and does the same crate expose that hook?
- MEDIUM: What is the idiomatic Rust equivalent of a committed-snapshot staleness test (F332) — a test that regenerates the schema at test time and diffs it against a committed file — and what regenerates the schema (a `cargo` binary target, a build script, or a CLI subcommand invoked by a Justfile recipe mirroring py's `just export-openapi`)?
- MEDIUM: Does a Rust-ecosystem equivalent of `oasdiff` exist for OpenAPI breaking-change detection runnable as a GitHub Action, or does this pipeline need to invoke the same `oasdiff` binary py uses regardless of the schema's source language?
- LOW: Do any published Rust API-template repos document this generate-snapshot-diff pipeline as a named pattern, and where?

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
