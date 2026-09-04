# Deep-research prompt — Devcontainer environment (R44, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: whether `rs-launch-blueprint` ships a VS Code devcontainer (base image, `postCreate` bootstrap script, in-container VS Code config) and, if so, what it contains. Item kind: `pattern`. Value test: if this answer is wrong, the presence and content of `.devcontainer/devcontainer.json` and `.devcontainer/post-create.sh` in the template change entirely.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py ships a devcontainer with a pinned base image and a `postCreate` bootstrap script that runs the repo's own two-level setup; ts carries no devcontainer at all and no TS_PORT_DECISIONS.md entry explains the omission. Evidence: py `.devcontainer/devcontainer.json:4` — pinned `ghcr.io/astral-sh/uv:python3.12-bookworm-slim` image; `.devcontainer/post-create.sh:15` — runs `make bootstrap` then `just setup`; ts: none (no `.devcontainer/` directory exists in ts and no `D-###` explains its omission). Ledger row: F200 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): the two-level bootstrap split (`make check`/`make bootstrap` at Level 1, `just setup` at Level 2) is `COMMON → REUSE` (F179/F180/F181/F182, `docs/port/COMMONALITY.md`) — if a devcontainer is adopted, its `postCreate` step reuses that existing bootstrap chain rather than inventing a parallel one. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` has no entry addressing the devcontainer omission; the ts port simply never carried it forward.

## Out of scope
- The base bootstrap-script content itself (`make check`/`make bootstrap`, `just setup`) beyond how a devcontainer's `postCreate` step invokes it — that chain is already `COMMON → REUSE` (F179–F182); this item decides only whether a devcontainer exists and what container-specific config (base image, in-container VS Code settings) it adds on top.
- Rust toolchain provisioning outside a container context (mise/flox/native installer recipes); R42 (`dev-toolchain-provisioning`) owns F183/F187–F189 — this item only asks whether the *container's* base image already carries the needed Rust toolchain.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R44
- owns:
- consumes:
- related (not a registry dependency): R42 (`dev-toolchain-provisioning`) decides the repo's general non-cargo toolchain-provisioning mechanism; if a devcontainer is adopted, its base image and `postCreate` step should be consistent with whatever R42 resolves to, but this item does not consume a registered parameter from R42 to do so.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` ships a VS Code devcontainer at all, and if so, what base image, `postCreate` bootstrap step, and in-container VS Code config it carries.
- HIGH: Is there a canonical, actively maintained Rust-toolchain devcontainer base image (analogous to py's pinned `ghcr.io/astral-sh/uv:python3.12-bookworm-slim`) — e.g. an official `rust` devcontainer feature/image, or a `rustup`-based Debian/Ubuntu image — that reaches the fixed MSRV policy and target-OS-equivalent tooling?
- HIGH: Does a Rust CLI+library+web template benefit meaningfully from a devcontainer given cargo/rustup already provide a largely self-contained, cross-platform toolchain — or is the container's main value narrower (e.g. only for contributors on unsupported host OSes, or for the optional web-service's system dependencies)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: If adopted, does the `postCreate` step simply invoke the template's own `make bootstrap`/`just setup` chain (matching py's pattern), or does a Rust-specific step (e.g. `rustup component add`, warming the `~/.cargo` registry cache) need to run first?
- MEDIUM: What in-container VS Code configuration (extensions, settings) does the devcontainer pin beyond the repo's own committed `.vscode/extensions.json` (F193, `COMMON → REUSE`) — does rust-analyzer's devcontainer feature need any additional container-specific setting?
- LOW: Does the devcontainer need to differ for the optional web-service target (e.g. exposing a port for local `cargo run --features web`), or is one devcontainer definition sufficient for all three target shapes (CLI, library, web)?

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
### Dominant choice
### Options
name · where documented · adopters that practice it · date of the most recent authoritative write-up — no download columns.
### Excluded by gate
### Up-and-comers
### Fit for this template
Argues per target shape — CLI · library · web, separately.
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
