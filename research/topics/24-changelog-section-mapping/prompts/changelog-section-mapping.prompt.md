# Deep-research prompt — Changelog section type mapping (R24, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern (with a reference implementation) for: which Conventional-Commits types release-please surfaces as visible `CHANGELOG.md` sections versus hides entirely, choosing between py's narrower visible set (feat/fix/perf/refactor/revert/deps) and ts's broader one (feat/fix/perf/docs/test/refactor). Item kind: `pattern`. Value test: if this answer is wrong, `release-please-config.json`'s `changelog-sections` array gets rewritten and every future `CHANGELOG.md` entry's visibility changes accordingly.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): both repos configure release-please's `changelog-sections`, but disagree on which commit types are visible. Evidence: py `release-please-config.json:23` — feat/fix/perf/refactor/revert/deps visible, chore/docs/style/test/ci/build hidden; ts `release-please-config.json:12` — feat/fix/perf/docs/test/refactor visible, chore hidden. Ledger row F067 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, notes: "ts surfaces docs/test/refactor sections that py hides."
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-021(3) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "release-please-generated `CHANGELOG.md` with `changelog-sections` porting `cog.toml`'s mapping (feat/fix/perf/docs/test/refactor visible, chore hidden); git-cliff (v2.13.1) and cocogitto (v7.0.0) rejected on redundancy, not maturity" — release-please already owns bump+changelog+release-PR end-to-end in all org release repos, so a second changelog writer would create a competing authority.

## Out of scope
- The full Conventional-Commits type enum and the header/body/footer length limits enforced on commits — R38 (`commit-message-linter`) owns `commit-message-convention`; assume its type enum as a consumed parameter and map each of its types to visible/hidden here, do not re-derive the type list.
- Whether release-please itself (versus git-cliff or cocogitto) is the changelog-generation tool; ts's D-021(3) already answers that for the org's release-tooling pattern generally, and this template's release tool is inherited under spec §2 (ledger rows F063 and F066, `COMMON → REUSE`) — this item only maps commit types to sections within whatever tool is chosen.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R24
- owns:
- consumes: R38: commit-message-convention
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: for each Conventional-Commits type in `rs-launch-blueprint`'s commit-message convention, whether it appears as a visible `CHANGELOG.md` section or is hidden, and what release-please `changelog-sections` config expresses that mapping.
- HIGH: Given R38's consumed type enum, which types have no obvious py-or-ts precedent (if the enum differs from both sources' sets) and need a fresh visible/hidden call for this template specifically?
- HIGH: Does a Rust template's audience (library/CLI/web consumers reading the changelog to decide whether to upgrade) make `refactor` and `test` entries noise (py's stance) or useful signal (ts's stance), and does that differ from py/ts's own audience reasoning?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: Should `deps` (py visible, dependency-bump commits) be its own visible section for a Rust template, given `cargo update`/Dependabot-driven dependency-bump commits may be frequent and low-signal individually?
- MEDIUM: Does release-please's `changelog-sections` schema (current version) support any config this template should adopt beyond a flat visible/hidden split — e.g. custom section headings or per-type ordering — that neither py nor ts uses but would suit this template?
- LOW: Should `ci`/`build` commit types (hidden in py, not present as distinct ts categories) get an explicit hidden entry, or does release-please's default (any unmapped type is hidden) make an explicit entry redundant?

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
