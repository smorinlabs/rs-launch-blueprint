# Deep-research prompt — Dependabot config shape (R19, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of `dependabot.yml` configuration conventions (with the `cargo` ecosystem's current option set) for: which package ecosystems `rs-launch-blueprint`'s Dependabot config declares and what update-grouping strategy it applies, choosing between py's richer named-groups-plus-cooldown-plus-labels shape and ts's single minor/patch group per ecosystem. Item kind: `bundle`. Value test: if this answer is wrong, `.github/dependabot.yml`'s ecosystem list and its `groups`/`cooldown`/`labels`/commit-message-prefix keys all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): both repos configure Dependabot, but diverge on ecosystems and grouping richness. Evidence: py `.github/dependabot.yml:14` — ecosystems `uv`, `github-actions`, `npm` (Bun-related deps only); ts `.github/dependabot.yml:28` — ecosystems `github-actions`, `npm` (covers the pnpm lockfile, since Dependabot's ecosystem id for pnpm stays `npm`). Ledger row F053, verdict `DIVERGENT`. py `.github/dependabot.yml:28` — named groups (runtime, dev-tools, lint-and-format, test) plus a 5-day cooldown, labels, and a commit-message prefix contract; ts `.github/dependabot.yml:34` — a single minor/patch update-type group per ecosystem, no cooldown/labels/commit-message customization. Ledger row F054, verdict `DIVERGENT`. Both rows are one Dependabot-config-shape decision (`docs/port/COMMONALITY.md` notes: "ecosystems and grouping are one Dependabot-config-shape decision").
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-022(8) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "Dependabot via `.github/dependabot.yml` with `github-actions` + JS package ecosystems (`npm` key covers npm/pnpm/yarn; `bun` key if Bun wins), weekly, grouped minor/patch; Renovate documented as alternative only", chosen for GitHub-native zero-infrastructure automation that works from a single committed file for template consumers.

## Out of scope
- Whether a competing dependency-update bot (e.g. Renovate) should replace Dependabot entirely; both source repos use Dependabot, so the bot itself is inherited under spec §2 (no ledger row re-opens the choice; F053/F054 configure it), and D-022(8) explicitly considered and rejected Renovate for ts — this item configures Dependabot, it does not re-open the bot-choice question.
- The scheduled full-dependency-graph vulnerability audit and the manual on-demand SCA scan tool; those are bundled into R13 (`dependency-vulnerability-scanning`)'s separate vulnerability-scanning decision, not this config-shape item.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R19
- owns:
- consumes:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: which package ecosystems `rs-launch-blueprint`'s `dependabot.yml` declares (at minimum `cargo` and `github-actions`) and whether its update-grouping strategy follows py's named-groups-plus-cooldown-plus-labels shape or ts's single minor/patch group per ecosystem.
- HIGH: Does Dependabot's `cargo` ecosystem support the same grouping keys (`groups`, update-type filters) and the `cooldown` key that py's `uv`-ecosystem config uses, at Dependabot's current schema version?
- HIGH: For a template repository (not a long-lived application), does py's richer grouping (four named groups: runtime, dev-tools, lint-and-format, test) reduce PR noise meaningfully over ts's single minor/patch group, or is the added config complexity not worth it for a template's smaller Rust dependency surface?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: Should the config also declare an ecosystem entry for the CI workflow files themselves (`github-actions`), and does that ecosystem's grouping need any Rust-specific adjustment versus py/ts's shared `github-actions` config?
- MEDIUM: Does py's 5-day cooldown and commit-message-prefix contract have a direct Dependabot-schema equivalent that a Cargo-ecosystem config can reuse unchanged?
- LOW: What labels (if any) should Dependabot apply to opened PRs, and does that choice depend on any label taxonomy already established elsewhere in the template's CI/lint conventions?

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
