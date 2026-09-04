# Deep-research prompt — Contributors-recipe mode (R47, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: which `contributors-please` subcommand `rs-launch-blueprint`'s local Justfile recipe invokes — a from-scratch bootstrap (`init`, py's pattern) or a ledger-to-Markdown render (`render`, ts's pattern) — relative to the CI bot workflow's own `pull-request` action mode. Item kind: `pattern`. Value test: if this answer is wrong, the local Justfile's contributors-update recipe body (which `contributors-please` subcommand it calls, and against what inputs) is rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): both repos wire the same CI bot workflow (`contributors-please-action` in `mode: pull-request`), but their local Justfile recipes diverge in which `contributors-please` subcommand they call. py's local recipe runs a from-scratch bootstrap subcommand; ts's local recipe runs a render subcommand that reproduces the ledger-to-Markdown step the CI action itself performs. Evidence: py `Justfile:462` — `update-contributors:` runs `npx contributors-please@1 init --non-interactive ...`; ts `Justfile:244` — `@contributors:` runs `pnpm dlx contributors-please render`. Ledger row: F210 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `different`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): the CI-side automated contributors-list bot-PR workflow itself (the `contributors-please-action` in `mode: pull-request`) is `COMMON → REUSE` (F060, `docs/port/COMMONALITY.md`), and the `.contributors.yml`/`.contributors.jsonl` config schema is also `COMMON → REUSE` (F209) — this item decides only the local recipe's subcommand choice, not the CI workflow or the config schema underneath it. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-024(9) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — replaced py's `update_contributors.py` script plus its divergent Justfile recipe with the org's own `contributors-please` package (npm) and `contributors-please-action`, giving the recipe and the CI workflow a single shared implementation rather than py's bespoke from-scratch bootstrap script; the why-text explicitly calls py's local `init` recipe an "orphan" divergent from the CI action's own behavior, while ts's local `render` recipe reproduces the same ledger-to-Markdown render step the CI action performs.

## Out of scope
- The CI bot workflow itself and the `.contributors.yml`/`.contributors.jsonl` config schema; both are already `COMMON → REUSE` (F060, F209) — this item decides only which subcommand the local Justfile recipe calls.
- The task-runner tool (`just`) and its recipe-grouping/alias conventions; those are already `COMMON → REUSE` (F176–F178) — this item is a content pick within one recipe, not a tooling choice.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R47
- owns:
- consumes:
- related (not a registry dependency): none — the CI-side workflow this recipe complements is already settled (F060, `COMMON → REUSE`), so this item has no other research item's output as an input.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s local `contributors-please` Justfile recipe runs a from-scratch bootstrap subcommand (py's `init`) or a ledger-render subcommand that mirrors the CI bot's own action mode (ts's `render`), given `contributors-please` is a `pnpm dlx`/`npx`-invoked npm package in both source repos regardless of which recipe mode wins.
- HIGH: As of the research date, what subcommands does the current `contributors-please` npm package expose, and does a `render` (or equivalently-named) subcommand still reproduce the exact ledger-to-Markdown step the `contributors-please-action`'s `pull-request` mode performs — confirming ts's D-024(9) rationale still holds?
- HIGH: Is there still no Rust-native or Cargo-installable equivalent to `contributors-please` (it remains an npm package invoked via a package-manager-runner, e.g. `npx`/`pnpm dlx`), meaning this template's local recipe must shell out to Node regardless of which subcommand it calls?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: Does a from-scratch bootstrap subcommand (py's `init`) serve any purpose a Rust template still needs — e.g. first-time `.contributors.jsonl` seeding — that a render-only recipe (ts's `render`) cannot cover, given `rs-launch-blueprint` starts from an empty history rather than porting an existing contributors ledger?
- LOW: Should the recipe's invocation mechanism (`npx contributors-please@1` vs. a package-manager-agnostic runner) itself be pinned to a version the way py's `@1` major-version pin does, or does that belong to a separate package-manager-invocation decision (R42, `package-manager-invocation`)?

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
