# Deep-research prompt — Aggregate required-status check (R12, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: whether `rs-launch-blueprint`'s CI needs a single aggregate job that folds every other job's result into one required status check (py's `ci-ok` pattern), or whether every individual job should instead be listed separately as a required check in the repository's branch-protection rules. Item kind: `pattern`. Value test: if this answer is wrong, either a required aggregate job (`needs.*.result`) gets added or removed from `ci.yml`, and the repository's branch-protection required-status-check list either points at one job name or has to be kept in sync with every individual job name whenever a job is added or removed.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py folds every other CI job's result into a single aggregate required-status-check job — `ci-ok` inspects `needs.*.result` for every job in the workflow and treats a `skipped` result (from py's path-filtered skip-gating, F040) as a pass, so branch protection only needs to require this one job rather than track every individual job by name. ts has no equivalent job; its single-job CI shape (F038/F040, R11) means there is nothing to aggregate — branch protection presumably targets the one `ci` job directly. Evidence: py `.github/workflows/ci.yml:268` — `ci-ok` job checks `needs.*.result`, treats skipped as pass; ts: none (py-only; ts's `.github/workflows/ci.yml` has one job, so no aggregation problem exists to solve). Ledger row: F041 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): how many jobs `rs-launch-blueprint`'s CI actually runs, and whether any of them can report `skipped` via path-filtered skip-gating, is R11's decision (`ci-workflow-job-structure`, owns `ci-job-structure`) — this item decides only whether to fold those jobs' results into one aggregate check, not what the jobs are. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts's `TS_PORT_DECISIONS.md` D-022 covers CI workflow shape (D-022(1)) but does not discuss required-status-check aggregation, because ts's single-job CI has nothing to aggregate.

## Out of scope
- How many jobs exist and whether any of them use path-filtered skip-gating (and can therefore report `skipped`); R11 (`ci-workflow-job-structure`) owns `ci-job-structure` — this item consumes that answer rather than deciding it.
- Which specific checks (formatter, linter, typechecker, tests, etc.) exist as jobs in the first place; those are each their own item — this item only decides how to aggregate whatever job set R11's answer produces.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R12
- owns:
- consumes: R11: ci-job-structure
- related (not a registry dependency): none beyond the consumed parameter.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` adds a single aggregate required-status-check job that folds in every other CI job's result, or requires each job individually in branch protection.
- HIGH: Does the value of an aggregate `ci-ok`-style job depend on R11's answer — specifically, does it only pay for itself when R11 adopts multi-job splitting with path-filtered skip-gating (where a `skipped` result must be treated as a pass), or is it still worth adding even under a single-job CI shape?
- HIGH: What is the idiomatic GitHub Actions mechanism for building such an aggregate job — a `needs: [...]` list plus a `${{ !contains(needs.*.result, 'failure') }}`-style expression (py's approach), or a maintained third-party action (e.g., an "all check" or "required-check" aggregator) that reduces the boilerplate and risk of a hand-rolled expression silently passing on a job that never ran?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: What is the failure mode of NOT having an aggregate job — does GitHub's branch-protection UI make it acceptably low-maintenance to list every individual job as required and keep that list in sync as jobs are added or removed, or does that list reliably drift out of sync in practice?
- LOW: If an aggregate job is adopted, does it also need to account for the `merge_group` trigger (F025, already established elsewhere in `ci-workflows`) so required checks still report correctly inside GitHub's merge queue?

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
