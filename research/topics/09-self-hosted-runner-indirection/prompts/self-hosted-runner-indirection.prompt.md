# Deep-research prompt — Self-hosted runner indirection (R09, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern (with a reference implementation, no crate involved) for: whether `rs-launch-blueprint`'s CI jobs select their runner via a repo-variable indirection with a self-hosted-runner fallback (py's `vars.RUNNER_*`/Blacksmith pattern), and, if adopted, what `actionlint` configuration (self-hosted runner labels, `RUNNER_*` config-variables, and the `create-github-app-token` stale-metadata suppression scope) that indirection requires. Item kind: `bundle`. Value test: if this answer is wrong, every job's `runs-on:` line across the template's workflow files gets rewritten between a hardcoded `ubuntu-latest`/`macos-latest` and a `vars.RUNNER_*`-driven expression, and `.github/actionlint.yaml` either carries dead configuration or is missing required declarations.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py selects each job's runner OS through a repo-variable indirection that falls back to a public GitHub-hosted runner — `runs-on` resolves to `vars.RUNNER_UBUNTU` (a self-hosted Blacksmith label) or else `'ubuntu-latest'` — repeated across nearly every workflow file, with `.github/actionlint.yaml` declaring the Blacksmith self-hosted-runner labels and the `RUNNER_*` config-variables so `actionlint` accepts the syntax. ts hardcodes `ubuntu-latest` (or the equivalent OS literal) everywhere and has no self-hosted-runner concept, and correspondingly no matching `actionlint.yaml` entries. Evidence: py `.github/workflows/ci.yml:34` — `runs-on` falls back to `vars.RUNNER_UBUNTU` or else `'ubuntu-latest'`, repeated fleet-wide; py `.github/actionlint.yaml:56` — declares the Blacksmith labels and `RUNNER_*` config-variables; py `.github/actionlint.yaml:56` — `self-hosted-runner.labels` (F056); py `.github/actionlint.yaml:62` — `config-variables` lists `RUNNER_UBUNTU`, `RUNNER_MACOS`, `RUNNER_WINDOWS` (F057); py `.github/actionlint.yaml:67` — stale-metadata suppression scoped only to `release-please.yml` (F058); ts `.github/actionlint.yaml:11` — same suppression scoped to both `release-please.yml` and `publish.yml`, though ts's `publish.yml` does not actually invoke `create-github-app-token` (F058, different). ts: none of F031/F056/F057 (py-only; ts hardcodes runner OS everywhere, `.github/workflows/ci.yml`). Ledger rows: F031, F056, F057, F058 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `target-os-matrix` = `ubuntu-latest, macos-latest` is fixed (`docs/port/PARAMETERS.md`, owner-decided 2026-09-02) — every runner this item's answer produces, self-hosted or not, must ultimately resolve to one of these two OS families; this item decides only whether an indirection/fallback layer sits in front of that fixed matrix, not the matrix itself. The `create-github-app-token` auth mechanism itself is inherited as-is (F072, `docs/port/COMMONALITY.md`, `COMMON → REUSE`) — this item decides only which workflow files' `actionlint.yaml` suppression entries reference it, not whether the template uses it. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-022(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "Org CI shape (review Synthesis #8) applied to the source workflow's dual-enforcement structure; Blacksmith explicitly not reused for a public template." ts deliberately rejected the Blacksmith/self-hosted-runner indirection specifically because the org's Synthesis review judged it inappropriate for a public template repository, not because the pattern itself was found deficient.

## Out of scope
- The fixed `target-os-matrix` value itself (`ubuntu-latest, macos-latest`); already decided by the owner (`docs/port/PARAMETERS.md`) — this item does not reopen which OS families CI targets, only whether a variable-driven fallback layer sits in front of them.
- Which specific jobs exist and the overall CI job/workflow-file structure; R11 (`ci-workflow-job-structure`) owns `ci-job-structure` — this item's `runs-on:` pattern applies uniformly to whatever jobs R11's answer produces.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R09
- owns:
- consumes:
- related (not a registry dependency): R11 (`ci-workflow-job-structure`) decides how many jobs exist per workflow; each such job needs this item's `runs-on:` pattern repeated, but the pattern's shape does not depend on the job count.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` adopts a repo-variable-driven runner-selection indirection with a self-hosted-runner fallback, or hardcodes GitHub-hosted runner labels directly, and — if adopted — what `actionlint.yaml` configuration that choice requires.
- HIGH: Given ts's org-level rationale that Blacksmith/self-hosted indirection is inappropriate for a public template repository (D-022(1)), does that rationale apply equally to `rs-launch-blueprint`, or does a Rust CI workload's longer build times change the cost-benefit case for self-hosted runners enough to revisit it?
- HIGH: If the indirection is rejected (hardcoded `runs-on:` labels, ts's shape), does `.github/actionlint.yaml` need any self-hosted-runner-related configuration at all, or does it shrink to zero entries for F056/F057?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: If the indirection is adopted, what is the idiomatic `actionlint.yaml` shape for declaring self-hosted-runner labels (F056) and the corresponding `RUNNER_*` config-variables (F057) for a Rust template with no established Blacksmith-equivalent precedent of its own?
- LOW: Does the `create-github-app-token` stale-metadata suppression scope (F058) need to cover just `release-please.yml` (py's narrower scope) or also `publish.yml` (ts's broader scope, even though ts's `publish.yml` does not actually invoke the action) — and which scope matches whichever workflows `rs-launch-blueprint`'s release/publish pipeline actually uses the action in?

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
