# Deep-research prompt — CI workflow job structure (R11, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern (with a reference implementation, no crate involved) for: whether `rs-launch-blueprint`'s CI checks each run as their own GitHub Actions job or as steps folded into one shared job, and how a path-filtered changes-detector job skips heavy jobs on docs-only pull requests. Item kind: `bundle`. Value test: if this answer is wrong, the template's `.github/workflows/ci.yml` job graph, its `needs:` edges, and any changes-detector job get restructured, and every other item that wires a check into CI (formatting, linting, typechecking, testing, coverage, docs gates) has to re-target a different job or step.

## Context
- Inherited pattern (spec §2, presumption of reuse): py and ts diverge on both axes of CI job structure. py splits checks into a dedicated `lint.yml` workflow with five separate jobs (actionlint, yamllint, bandit, codespell, editorconfig-check) gated by its own `lint-changes` job (lines 30-64) that path-filters which changed files trigger which jobs, plus a separate `changes` job in `ci.yml` (F040) that skips heavy jobs (`typecheck`, `import-boundaries`, `test`, `build-smoke`) on docs-only PRs. ts has no separate `lint.yml` at all — oxlint, oxfmt, and `tsc` are the only checks and they all run as steps inside the single `ci` job, with no changes-detector or path-filtered skip-gating anywhere. Evidence: py `.github/workflows/lint.yml:15` — five jobs, `lint-changes` (lines 30-64) gates actionlint/yamllint on changed paths; py `.github/workflows/ci.yml:32` — `changes` job (F040), consumed by `typecheck`, `import-boundaries`, `test`, `build-smoke`; ts: none for either row (py-only; ts's `.github/workflows/ci.yml` folds every check into one job with no skip-gating). Ledger rows: F038, F040 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: which specific tools populate each check (formatter, linter, typechecker, test runner, coverage, docs gates) is decided by their own items (e.g., R27 lint/format, R30 typecheck, R32 test harness, R35 coverage) — this item decides only the job-vs-step shape and skip-gating mechanism those checks are wired into, not which tool runs inside them. Whether an architectural-boundary-lint job (py's `import-boundaries`) exists in CI at all is R02's decision (`crate-boundary-enforcement`) — this item's job-structure answer must accommodate whatever R02 decides without deciding it here. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts's single-job `ci.yml` (D-022(1), "CI workflow shape... push/PR to main on ubuntu-latest; checkout@v6 + setup-node@v6; named just-recipe steps plus hook-suite run-all parity step") is a wholesale simplification with no decision record discussing job-splitting or path-filtered skip-gating as a considered alternative.

## Out of scope
- Which specific tool implements each check (formatter, linter, typechecker, test runner, coverage tool, docs gate); those are each their own item (e.g., R27, R28, R30, R32, R35, R71, R82) — this item decides only the job/step topology and skip-gating mechanism they are wired into.
- Whether an architectural-boundary-lint job exists in CI at all; R02 (`crate-boundary-enforcement`) owns that decision — this item's job-structure answer must be able to host such a job if R02 adds one, without deciding whether it exists.
- Whether a single aggregate required-status-check job folds in all other jobs' results; R12 (`aggregate-required-status-check`) owns F041 — this item decides what jobs exist, not how they are aggregated into one required check.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R11
- owns: ci-job-structure
- consumes: R69: web-extra-surface
- related (not a registry dependency): R02 (`crate-boundary-enforcement`) decides whether a crate-boundary/import-boundary-lint job exists in CI at all; this item's job-topology answer must have room for it either way. R12 (`aggregate-required-status-check`) consumes this item's `ci-job-structure` value to decide what an aggregate status-check job folds together.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s CI checks run as separate GitHub Actions jobs or as steps inside one shared job, and whether/how a path-filtered changes-detector job skips heavy jobs on docs-only pull requests.
- HIGH: Given Rust's compile times are typically longer than Python's or Node's per-check startup cost, does per-check job-splitting (py's shape, more parallelism, more redundant `cargo` setup/compile time per job) or a single shared job (ts's shape, one `cargo` setup, sequential steps) better fit a Rust CI workload — and does the answer depend on whether R10's dependency-cache action makes repeated setup cheap enough to erase the parallelism benefit?
- HIGH: Does `rs-launch-blueprint` need a path-filtered changes-detector job (py's `changes`/`lint-changes` jobs) to skip heavy jobs (build, test, docs) on docs-only PRs, or does Rust's typically-fast `cargo check`/`cargo clippy` on an unchanged crate make the skip-gating machinery not worth its own maintenance cost?
- MEDIUM: If the template later gains the optional web/API surface (R69's `web-extra-surface`), does the job structure need extra path-filtered skip-gating so PRs that touch only the CLI/library crates don't pay for web-surface-only checks (OpenAPI snapshot, docs-correctness gates) and vice versa?
- LOW: What is the idiomatic GitHub Actions mechanism for a changes-detector job — `dorny/paths-filter`, GitHub's native `on.push.paths`/`on.pull_request.paths` triggers, or a hand-rolled `git diff` step — and which best supports the conditional `needs:`-gating py's `changes` job demonstrates?

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
Commands that prove the choice landed.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
