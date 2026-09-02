# Deep-research prompt — Aggregate required-status check (R12, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: whether `rs-launch-blueprint`'s CI needs a single aggregate job that folds every other job's result into one required status check (py's `ci-ok` pattern), or whether every individual job should instead be listed separately as a required check in the repository's branch-protection rules. Item kind: `pattern`. Value test: if this answer is wrong, either a required aggregate job (`needs.*.result`) gets added or removed from `ci.yml`, and the repository's branch-protection required-status-check list either points at one job name or has to be kept in sync with every individual job name whenever a job is added or removed.

## Context
- Inherited pattern (spec §2, presumption of reuse): py folds every other CI job's result into a single aggregate required-status-check job — `ci-ok` inspects `needs.*.result` for every job in the workflow and treats a `skipped` result (from py's path-filtered skip-gating, F040) as a pass, so branch protection only needs to require this one job rather than track every individual job by name. ts has no equivalent job; its single-job CI shape (F038/F040, R11) means there is nothing to aggregate — branch protection presumably targets the one `ci` job directly. Evidence: py `.github/workflows/ci.yml:268` — `ci-ok` job checks `needs.*.result`, treats skipped as pass; ts: none (py-only; ts's `.github/workflows/ci.yml` has one job, so no aggregation problem exists to solve). Ledger row: F041 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: how many jobs `rs-launch-blueprint`'s CI actually runs, and whether any of them can report `skipped` via path-filtered skip-gating, is R11's decision (`ci-workflow-job-structure`, owns `ci-job-structure`) — this item decides only whether to fold those jobs' results into one aggregate check, not what the jobs are. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
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
- MEDIUM: What is the failure mode of NOT having an aggregate job — does GitHub's branch-protection UI make it acceptably low-maintenance to list every individual job as required and keep that list in sync as jobs are added or removed, or does that list reliably drift out of sync in practice?
- LOW: If an aggregate job is adopted, does it also need to account for the `merge_group` trigger (F025, already established elsewhere in `ci-workflows`) so required checks still report correctly inside GitHub's merge queue?

## Required evidence
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
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + link; "well-known" = nameable without lookup |

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

### Options
name · where documented · adopters that practice it · date of the most recent authoritative write-up
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
Commands that prove the choice landed.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
