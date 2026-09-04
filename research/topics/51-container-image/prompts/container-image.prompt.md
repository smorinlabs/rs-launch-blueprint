# Deep-research prompt — Container image (R51, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of tools and reference pattern for: whether `rs-launch-blueprint` ships a container image as a distribution artifact for its optional web-service build, and if so, its multi-stage non-root build layering and its own liveness healthcheck. Item kind: `bundle`. Value test: if this answer is wrong, the presence and content of a `Dockerfile` (build stages, user, `HEALTHCHECK` instruction) in the template changes entirely.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py ships a container image as a distribution artifact, tied to its optional `web` install extra; ts has no web service at all and so no container image to compare. Evidence: py `Dockerfile:6` — multi-stage `uv sync` build producing a runnable web-service image; ts: none (no web/HTTP-server code, dependency, or test exists anywhere in the ts repo — `docs/port/areas/web-service.md` F303). Ledger row: F223 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, contingent on F017 (workspace-architecture, already `ADOPT`ed: web service as an optional Cargo feature).
- Per-row evidence for the rest of this bundle, cross-area with `docs/port/areas/web-service.md`: F336 production container image is a non-root multi-stage build — py `Dockerfile:13` — `uv sync --frozen --no-install-project --no-dev --extra web` then `Dockerfile:21` — `USER app`; ts: none. WEB-32 per that area's notes: lockfile-frozen, bytecode-compiled, dependency layer cached separately from source. F337 container declares its own liveness healthcheck — py `Dockerfile:29` — `HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \`; ts: none. That area's notes: probes `/healthz` via `urllib` since the slim base image has no `curl` (the `/healthz` endpoint itself is decided at F328, out of this item's scope).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): whether an optional web-service surface exists at all is already `ADOPT`ed (F017, `docs/port/COMMONALITY.md`) as the direct Cargo-optional-feature analogue of py's optional-dependencies `web` extra — this item does not re-decide whether a web feature exists, only whether it also gets a container image. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no container-image entry to carry forward.

## Out of scope
- Whether the template carries an optional web/API surface at all, and what that surface contains; R69 (`web-framework-stack`) owns `web-extra-surface` — this item's container image exists only if R69 resolves to shipping a web surface, and this item does not re-decide that surface's content.
- The `/healthz` liveness endpoint's own behavior (F328); that belongs to R80 (`health-probe-endpoints`) — this item only decides whether the container's `HEALTHCHECK` instruction probes it, not what the endpoint itself returns.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R51
- owns:
- consumes: R69: web-extra-surface
- related (not a registry dependency): R80 (`health-probe-endpoints`) decides the `/healthz` endpoint's own behavior; this item's container `HEALTHCHECK` instruction, if adopted, probes whatever endpoint R80 resolves to, but registers no dependency on it beyond that.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` ships a container image as a distribution artifact for its optional web-service build, and if so, what multi-stage non-root build layering and self-declared liveness healthcheck it uses — contingent on R69 (`web-extra-surface`) adopting a web/API surface at all.
- HIGH: What is the current-best-practice minimal, non-root, multi-stage Dockerfile pattern for a statically- or dynamically-linked Rust binary as of the research date — a `rust:<version>-slim` or `chef`/`cargo-chef`-based builder stage plus a `distroless`/`scratch`/`debian-slim` runtime stage — and does dependency-layer caching (py's `uv sync --frozen --no-install-project` pre-source-copy pattern) have a direct Cargo analogue (e.g. `cargo-chef`)?
- HIGH: Is `cargo-chef` (or an equivalent Docker-layer-caching tool for Rust builds) still actively maintained and the dominant approach for this pattern, or has a simpler multi-stage `COPY`-order trick superseded it?
- MEDIUM: What is the idiomatic `HEALTHCHECK` instruction for a Rust web-service image with no shell utilities in its runtime stage (py's `urllib`-via-Python workaround for a `curl`-less slim image) — does a minimal Rust runtime base need a bundled tool (e.g. `curl`, `wget`) added back, or a tiny statically-linked healthcheck binary?
- MEDIUM: Does the image need a non-root `USER` declaration analogous to py's `USER app` (F336), and what is the idiomatic way to create that user in a minimal Rust runtime base (e.g. `distroless:nonroot`'s built-in `nonroot` user vs. a manually created user in a `debian-slim` stage)?
- LOW: Should the image be built and published as part of this template's release workflow, or only documented as an optional Dockerfile a fork can build on demand, given `web-extra-surface` is itself an optional Cargo feature rather than the template's default build?

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
