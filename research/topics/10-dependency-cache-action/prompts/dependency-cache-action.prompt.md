# Deep-research prompt — Dependency cache action (R10, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate or GitHub Action (with a version range) for: the Rust-native equivalent of py's and ts's setup-action-integrated CI dependency caching — i.e., what mechanism caches Cargo's registry, git, and target artifacts across CI runs, since neither `dtolnay/rust-toolchain` nor any other single canonical Rust toolchain-setup action bundles caching the way `astral-sh/setup-uv` and `actions/setup-node` do. Item kind: `crate`. Value test: if this answer is wrong, the CI workflow's dependency-setup step gets rewritten and every job either loses build-time savings from cache reuse or picks a caching mechanism with a cache-key/eviction bug that silently serves stale dependencies.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): both repos get CI dependency caching "for free," built into the language-setup step itself, with no separate cache-management action to choose. py's `astral-sh/setup-uv` action caches `uv`'s resolved dependencies as part of the same step that installs the toolchain; ts's `actions/setup-node` action caches the package manager's store via its `cache: 'pnpm'` input, again with no separate step. Rust has no single canonical toolchain-setup action that bundles caching this way — `dtolnay/rust-toolchain` installs the toolchain only and does not cache; `Swatinem/rust-cache` and `actions/cache` are separate actions requiring their own selection — so unlike py and ts, this is a genuine research question with a Rust-specific answer, not a straight port. Evidence: py `.github/workflows/ci.yml:87` — `astral-sh/setup-uv@v8.3.2` (uv's own cache); ts `.github/workflows/ci.yml:69` — `actions/setup-node@v7` with `cache: 'pnpm'`. Ledger row: F036 (`docs/port/COMMONALITY.md`; parent: F035), verdict `COMMON → SUBSTITUTE`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): which tool provisions the Rust toolchain itself in CI (`dtolnay/rust-toolchain` or an alternative) and which package manager/toolchain-provisioner the template's local dev environment uses are R42's decision (`dev-toolchain-provisioning`, owns `package-manager-invocation`) — this item is scoped to the CI dependency-cache mechanism alone, assumed to sit alongside whatever toolchain-install step R42's answer (or the template's existing toolchain-setup step) produces. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-022(3) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "setup-node cache:npm is the unanimous org precedent (agent2linear, contributors-please) and simpler than hand-rolled actions/cache." ts reused its language-setup action's built-in cache rather than adding a separate caching action; the Rust ecosystem's lack of an equivalent built-in is exactly the gap this item must resolve without a same-shape source-repo precedent to copy.

## Out of scope
- Which tool provisions the Rust toolchain itself in CI, and the local dev-toolchain provisioner (rustup, mise, flox); R42 (`dev-toolchain-provisioning`) owns `package-manager-invocation` — this item assumes a toolchain-install step exists and decides only how its outputs get cached.
- Whether each CI check is its own job or a shared-job step, and how path-filtered skip-gating is applied; R11 (`ci-workflow-job-structure`) owns `ci-job-structure` — the caching mechanism this item picks must work regardless of R11's job topology.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R10
- owns:
- consumes:
- related (not a registry dependency): R42 (`dev-toolchain-provisioning`) owns `package-manager-invocation`, the toolchain-install step this item's cache action wraps; this item does not need R42's value to decide which cache action to use, only to know a toolchain-install step precedes it.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what caches Cargo's registry index, downloaded crate sources, and `target/` build artifacts across CI runs for `rs-launch-blueprint`.
- HIGH: Is `Swatinem/rust-cache` (a Rust-specific action with built-in cache-key heuristics tuned to Cargo's directory layout) or a hand-rolled `actions/cache` step (generic, requires manually declared cache paths and key logic) the better default for a template meant to be forked and modified?
- HIGH: What cache-key strategy avoids the two failure modes both approaches risk — a cache that never invalidates on a `Cargo.lock` change (stale-dependency risk) versus a cache that invalidates too eagerly and provides no build-time savings?
- MEDIUM: Does the chosen action's default behavior differ meaningfully across `ubuntu-latest` and `macos-latest` (the fixed `target-os-matrix`), e.g., in cache-size limits, restore-key fallback behavior, or save-on-failure semantics?
- LOW: Does the chosen action need to be paired with any additional configuration (e.g., `cache-on-failure`, workspace-aware key prefixes) to behave correctly in a multi-crate Cargo workspace, given R02 (`crate-boundary-enforcement`) may produce one?

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
