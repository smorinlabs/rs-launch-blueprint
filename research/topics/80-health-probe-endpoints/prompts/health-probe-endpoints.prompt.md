# Deep-research prompt — Health probe endpoints (R80, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: how `rs-launch-blueprint`'s web service implements its liveness (`/healthz`) endpoint reporting version and runtime info, and its readiness (`/readyz`) endpoint running the same diagnostics as the CLI's `doctor` command. Item kind: `bundle`. Value test: if this answer is wrong, the `/healthz` and `/readyz` route handlers, their response shape, and the diagnostics-sharing code path between the CLI and web front-ends all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py's web layer exposes two ops probes — a liveness endpoint that reports version and runtime info (the web analog of `--version`), and a readiness endpoint that reruns the same diagnostics as the CLI's `doctor` command, returning an RFC 9457 problem document with a 503 status on failure; ts has neither (no web service exists, F303). Evidence: py `src/py_launch_blueprint/web/app.py:153` — `@app.get("/healthz", tags=["ops"])` (F328); py `src/py_launch_blueprint/web/app.py:184` — `async def readyz(` returns 503 problem doc on failure, reusing `core/diagnostics.py`'s `run_diagnostics`, "one source of truth with the CLI" (F329); ts: none. Ledger rows: F328, F329 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); ops endpoints (`/healthz`, `/readyz`, `/metrics`) are unversioned by convention while business routes are version-prefixed (F308, `ADOPT` — a trivial URL-prefix convention, do not re-derive it, just apply it to the two endpoints this item designs); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing health-probe endpoints.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Again, taking the same principles, we need to find the appropriate implementation and best practices for both TypeScript and Rust. For individual research items, we found the best practices and architecture specifically for PyLaunch Blueprint. We'd like to have the same for TypeScript and Rust.

## Out of scope
- Whether the template adopts a web framework at all, and which one; R69 (`web-framework-stack`) owns `web-extra-surface` — this item does not pick a framework, it decides the two probe endpoints' behavior and describes how they attach to any candidate framework's router.
- The single RFC 9457 problem-document error envelope's shape and the domain-error-to-HTTP-status mapping used by `/readyz`'s 503 response; R70 (`http-problem-envelope`) owns F305/F306 — this item assumes that envelope exists and reuses it, it does not design it.
- Excluding `/healthz`/`/readyz` from access-log volume; R75 (`http-middleware-stack`) owns F320 — this item only designs the probe endpoints themselves, not the access-log middleware that excludes them.
- The container image's own `HEALTHCHECK` directive that probes `/healthz`; R51 (`container-image`) owns F336/F337 — this item decides what `/healthz` returns, not how the container invokes it.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R80
- owns:
- consumes:
- related (not a registry dependency): R69 (`web-framework-stack`) owns `web-extra-surface` and picks the framework these endpoints are routed through; treat the framework choice as open.
- related (not a registry dependency): R70 (`http-problem-envelope`) decides the problem-document envelope this item's `/readyz` 503 response reuses; assume some RFC 9457 envelope exists and design against it generically.
- related (not a registry dependency): R51 (`container-image`) consumes this item's `/healthz` shape for its container `HEALTHCHECK` directive (F337); do not redesign the container probe here, only note what `/healthz` returns for it to probe.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: how does `rs-launch-blueprint` implement its liveness endpoint (version + runtime info) and its readiness endpoint (reruns the CLI's diagnostics, 503 problem document on failure), and what crates/patterns are needed to share the diagnostics logic between the CLI and web front-ends.
- HIGH: What is the idiomatic Rust shape for a shared "diagnostics" function/type — analogous to py's `core/diagnostics.py`'s `run_diagnostics` — that both a CLI `doctor` command and a web `/readyz` handler call as one source of truth, given the port/adapter seam this shared logic sits behind is still open (R01)?
- HIGH: What version and runtime info does the liveness endpoint report (binary version, build metadata, uptime, Rust/toolchain version), and what crate(s) (if any) provide that info at compile time or runtime (candidates: `built`, `vergen`, `std::env!("CARGO_PKG_VERSION")` alone)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: Does readiness-check failure need any crate beyond what R70's problem-envelope and R69's framework already provide, or is `/readyz` purely a composition of existing pieces (diagnostics function + envelope + 503 status)?
- MEDIUM: Should liveness/readiness reporting use structured types (`serde`-derived response bodies) matching the OpenAPI-schema conventions the rest of the web service uses (owned by R71), or is a minimal, schema-agnostic response acceptable for ops-only endpoints?
- LOW: Do comparable Rust web-service templates or frameworks ship a first-class liveness/readiness pattern (e.g. a crate or framework extension specifically for Kubernetes-style probes) worth surveying for precedent?

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
