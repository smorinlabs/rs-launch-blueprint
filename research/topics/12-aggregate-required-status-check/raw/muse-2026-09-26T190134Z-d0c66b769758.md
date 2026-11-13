# R12 — Aggregate required-status check (pattern) — raw report

Actor id: `research-muse-2026-09-26T190134Z-d0c66b769758`. Engine: muse. Item kind: `pattern`.
Resolved model: Muse Spark (Meta), as resolved in this session.
Every figure below carries its endpoint and a retrieval date of **2026-09-26**; every claim carries a source and the same retrieval date unless stated otherwise.

Item kind is `pattern`, so the prompt's crate figure table is `inapplicable` to the decision itself: the candidates are a workflow-file job shape, a branch-protection convention, and one composite GitHub Action. None is a Rust crate, so `crate.recent_downloads`, `crate.downloads`, `/versions`, and `rustsec.org/packages/<name>.html` have no value to read for any of them. GitHub repository figures (`stargazers_count`, `archived`, `pushed_at`, open-issue counts, responsiveness) are collected below for the third-party action and for the well-regarded projects surveyed, because those do have GitHub repositories. The 2025 State of Rust Survey is likewise `inapplicable`: its published findings cover language features, compile times, community and hiring, with no question or finding about CI required-status aggregation, so it contributes no weight to this item.

### Landscape

**Category this item decides.** How `rs-launch-blueprint`'s CI answers one platform question: which check name(s) branch protection requires before a pull request may merge — one aggregate job that folds every other job's result into a single verdict, or each job listed individually.

**Three-bin map of the field.** There is no Rust-specific field here; the field is GitHub Actions workflow mechanics, which are language-independent. The bins below therefore map platform primitives, established aggregation patterns, and newer platform features.

*Bin 1 — built-in or first-party platform mechanics.* `jobs.<job_id>.needs` with the `needs.*.result` array (`success` | `failure` | `cancelled` | `skipped` per job); job-level `if: ${{ always() }}` to opt out of skip propagation; `join(needs.*.result, ' ')` plus a shell loop as the verdict device; branch protection's required-status-check list and its successor Rulesets; the `merge_group` trigger for merge-queue entries. Every primitive the recommendation uses is in this bin.

*Bin 2 — established industry patterns.* (a) The hardened hand-rolled aggregate: `needs:` over every required job, `if: always()`, explicit inspection of each result, `skipped` treated as a pass and `failure`/`cancelled` as a fail — what py-launch-blueprint's `ci-ok` does. (b) The naive aggregate: `needs:` over every job with no status function and an unconditional succeeding step — what hyper's `ci-pass` does. (c) Per-job required checks with no aggregate job at all — what tokio does across 40+ jobs. (d) The maintained third-party aggregator `re-actors/alls-green`: a composite action taking `toJSON(needs)` with `allowed-failures` / `allowed-skips` inputs.

*Bin 3 — up-and-comers.* GitHub Rulesets as the branch-protection successor (same required-check semantics, new settings surface); organization-level required workflows (Enterprise-gated, inapplicable to a public template); any future platform change to how a `skipped` result satisfies a required check.

**Authoritative sources used, and why each counts.** (1) R11's accepted platform evidence — `research/topics/11-ci-workflow-job-structure/evidence/2026-09-18T215915Z-7fbece2a29a7-r11-platform-docs.r2-rerun.log`, read locally 2026-09-26: checks P1b (a job skipped by a conditional reports SUCCESS), P1c (skipped is one of the three successful check statuses), P2a (a failed or skipped dependency skips its dependents unless they opt out), and P2b (the platform's own "use `always()` with `needs`" instruction for an aggregate required check). This counts because it is already-accepted, hash-pinned vendor documentation for exactly the behaviors this item depends on. Network for this leg was constrained to the topic's named endpoints, so the underlying GitHub Docs pages were not re-fetched; the vendor sources are cited below as the pages R11 snapshotted. (2) The GitHub Docs pages themselves: required-status-check troubleshooting, the `needs` reference including the `needs` context, branch-protection settings, merge-queue management, and Rulesets — maintainer-authoritative for platform behavior. (3) Maintainers' own workflow files and action sources, read at pinned SHAs or local commits: py's `ci.yml` (local commit `b55b8c2`), ts's `ci.yml` (local commit `e5100b4`), hyper's `CI.yml` (blob sha `5d625ae140141d653099b55739a0d00d3a08c067`), tokio's `ci.yml` (blob sha `4223db720445cdd057bab0635ce44fc67714bd28`), and `re-actors/alls-green` sources at branch `unstable/v1` — authoritative for what each project actually practises and what the action actually computes. (4) `actionlint` 1.7.12 and `shellcheck`, used as instruments, not authorities.

**Practice evidence — well-regarded projects surveyed, with the evidence that they are well regarded.**

| Project | Evidence it is well regarded (`GET https://api.github.com/repos/<o>/<r>`, 2026-09-26) | What it practises (source, retrieved 2026-09-26) |
|---|---|---|
| `tokio-rs/tokio` | 33,246 stars, `archived: false`, `pushed_at 2026-09-26T15:24:17Z`; the de-facto Rust async runtime | `.github/workflows/ci.yml` (1,483 lines): 40+ jobs, no aggregate job, no `always()` anywhere — every job is individually addressable as a required check |
| `hyperium/hyper` | 16,333 stars, `archived: false`, `pushed_at 2026-09-26T02:29:09Z`; the HTTP implementation under `reqwest` and `axum` | `.github/workflows/CI.yml:15-33`: naive aggregate `ci-pass` ("CI is green") with a 14-job `needs:` list, no `if:`, single step `run: exit 0` |
| `py-launch-blueprint` (source precedent) | The py half of this port programme; local commit `b55b8c2` | `.github/workflows/ci.yml:305-334`: hardened aggregate `ci-ok` — 10-job `needs:` including the `changes` detector, `if: always()`, `permissions: {}`, shell loop failing on `failure`/`cancelled` and passing `skipped`; file header (lines 6-7) names it "the single required status for branch protection (skipped jobs count as ok)" |
| `ts-launch-blueprint` (source precedent) | The ts half of this port programme; local commit `e5100b4` | `.github/workflows/ci.yml` (196 lines): two jobs, `ci` (matrixed) and advisory `bun-lane` with `continue-on-error: true`; no aggregate job — nothing to aggregate |
| `re-actors/alls-green` (third-party candidate) | 173 stars, `archived: false`, `pushed_at 2026-08-21T23:59:58Z`, license `BSD-3-Clause`; by Sviatoslav Sydorenko (`@webknjaz`, CPython/aiohttp-adjacent maintainer standing); open issues `total_count` 7 (`GET https://api.github.com/search/issues?q=repo:re-actors/alls-green+is:issue+is:open`, 2026-09-26; direct listing returned 8 rows, search-index lag) | Composite action: `action.yml` takes `jobs: ${{ toJSON(needs) }}` plus `allowed-failures` / `allowed-skips`; verdict computed by `src/job_outcome.py` + `src/normalize_needed_jobs_status.py`. Maintenance state `active`: pushed within 6 weeks of retrieval, 7 of 8 open issues have a maintainer reply (median 0.45 days to first maintainer response; the one unanswered, #40, is owner self-notes with 0 comments) |

### Principles and implementation

**The shared requirement.** No change merges unless every quality gate that applied to it passed; a gate that legitimately did not apply to a change must not block it; a gate that failed, was cancelled, or never produced a verdict must block it. Source: py's header comment ("`ci-ok` is the single required status for branch protection (skipped jobs count as ok)") and body (fail on `failure`/`cancelled`, pass on `skipped`), read locally 2026-09-26; R11's accepted handover ("a failed `plan` must itself fail a required check", `research/topics/11-ci-workflow-job-structure/DECISION.md:283`).

**Agreement level.** Capability plus policy, not mechanism. P1 (capability): the merge gate is complete — every applicable required verdict feeds the merge decision. P2 (policy): `skipped` on a legitimately inapplicable gate counts as a pass. P3 (policy, fail-closed): `failure`, `cancelled`, or a missing verdict on any required gate — including the detector whose failure skips everything downstream — blocks the merge. The job name, the verdict device (shell loop vs expression vs action), and whether aggregation exists at all may vary per repository; P1–P3 may not.

**Essential behaviors, with observable acceptance criteria.**

| # | Behavior | Observable acceptance criterion |
|---|---|---|
| B1 | One stable check name gates the merge | Branch protection / ruleset requires exactly one CI check name; renaming or adding a job never requires a settings change |
| B2 | A legitimately skipped gate does not block | A docs-only pull request shows the aggregate green while gated jobs report skipped |
| B3 | Any failed gate blocks | One failing job turns the aggregate red and the pull request unmergeable |
| B4 | A cancelled run blocks rather than passing silently | A cancelled run leaves the aggregate non-green |
| B5 | A failed detector blocks | A forced `plan` failure leaves the pull request unmergeable (R11 criterion 13, handed to this item) |
| B6 | Merge-queue entries report | A `merge_group` run produces a green aggregate on success, never a stuck "Expected" |

**Compared architectural alternatives (not just candidate libraries).**

- **A. Hardened hand-rolled aggregate (py's `ci-ok` shape).** `needs:` over every required job including the detector, `if: always()`, explicit per-result inspection, `skipped` as pass, `failure`/`cancelled` as fail. Satisfies B1–B6. The `always()` is load-bearing: without it, P2a skips the aggregate whenever any dependency fails, and P1b/P1c turn that skip into a successful required status — a false green. The detector's membership in `needs:` is what satisfies B5, exactly as R11's handover prescribes.
- **B. Naive aggregate (hyper's `ci-pass` shape).** `needs:` only, unconditional succeeding step. Satisfies B1 and B2 but fails B3–B5 open: any dependency failure or cancellation skips the aggregate (P2a), and the skip reads as success (P1c). hyper's own file (lines 15–33, no `if:`) is the reference implementation of this failure mode. It is not a different tradeoff; it is alternative A with the load-bearing part removed.
- **C. Third-party aggregator (`re-actors/alls-green`).** Same topology as A with the verdict computed by maintained Python. Its own README documents the P2a/P1c trap ("it is a must to have the job always run, otherwise GitHub will make it `skipped`... `skipped` is interpreted as `success`"). Decisive against it here: its verdict matrix (`src/job_outcome.py`, `ACCEPTABLE_RESULTS`) accepts only `success` for a `REQUIRED` job — a skipped gate fails the aggregate unless that job is named in `allowed-skips`. Under R11's accepted design, `skipped` is the normal docs-only outcome for four gated jobs, so adopting this action means maintaining a second list (every skippable job in `allowed-skips`) that must stay in sync with the `needs:` list — the same drift problem the aggregate exists to remove, moved one level down. It also adds a third-party supply-chain entry (pinning form is R20's) and a Python runtime dependency to a job that otherwise needs only shell.
- **D. Per-job required checks, no aggregate (tokio's shape).** Satisfies B3–B5 (each gate speaks for itself; a failed detector fails its own required check) and B2 (skipped gates report success individually). Fails B1: every job add, rename, or removal needs an admin-privileged branch-protection edit, matrix legs expand per-runner check names, and a new job is silently non-gating until someone with admin rights adds it. tokio absorbs this with a large maintainer team and 40+ jobs; a template copied by downstream users cannot assume that staffing.
- **E. Single job, nothing to aggregate (ts's shape).** The required check is the one `ci` job; ts's second job is advisory (`continue-on-error: true`) and correctly excluded from gating. This is the right answer for a single-job workflow and would have been this item's answer had R11 chosen single-job. R11 revision 7 chose six job ids with skip-gating (accepted 2026-09-23), so E is not available to rs — the HIGH question about R11-dependence is answered by that fact, not in the abstract.

**Fitness gates, answered before popularity is weighed.** (1) License: `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`, the same ruling R11 records; `alls-green`'s `BSD-3-Clause` is a figure, not a gate result. (2) MSRV: `inapplicable` — a workflow file, a shell loop, and a composite Python action have no `rust-version`. (3) RustSec / `unsafe`: `inapplicable` — no crate enters any dependency tree; RustSec does not cover GitHub Actions. (4) OS matrix: passes in adapted form — the aggregate needs only a GHA-hosted runner with bash, true of both `ubuntu-latest` and `macos-latest`; the recommendation pins it to `ubuntu-latest` (cheapest, no toolchain, no cache, matching `plan`). (5) Default features / async-runtime coupling: `inapplicable` — nothing is linked into the template. (6) Binary size / compile time: `inapplicable` to the template artifact; CI cost is one ~10-second runner job per run.

**Cross-ecosystem realization (the HIGH cross-repo question).** P1–P3 hold in all three repositories; the mechanism differs only where structure forces it. py realizes them with hardened `ci-ok` over a multi-job skip-gated workflow. rs should realize them the same way, over R11's six job ids — same platform, same skip-gating design, same hardened form; even the job name `ci-ok` is shared, a low-level value justified by identical tradeoffs in both ecosystems (same vendor, same verdict semantics, cross-repo recognizability at zero cost). ts realizes P1 trivially — its one required job *is* the aggregate — and P2/P3 vacuously, since it has no skip-gating and no detector; its advisory second lane is correctly non-voting. ts's lack of an aggregate is therefore a justified structural difference, not drift and not a missing capability: there is nothing to fold. If ts ever promotes a second job to required, P1 requires it to adopt the aggregate (alternative A, not B). No `BASELINE-REVIEW:` finding: F041 is this item's own `DIVERGENT` row, appointed to be decided here, not an inherited baseline.

**Minimal realistic example.** The candidate file lints and behaves as specified; its full text and executed results are under `### Validation strategy`. In `ci.yml` it is one job (~30 lines): `needs:` over `plan`, `hygiene`, `workflow-lint`, `check`, `msrv-floor`, `install-smoke`; `if: always()`; `permissions: {}`; one step joining `needs.*.result` and failing on `failure`/`cancelled`.

### Dominant choice

The field has no single dominant mechanism — the two most-cited Rust projects split: tokio (33,246 stars) requires each of 40+ jobs individually with no aggregate, while hyper (16,333 stars) aggregates naively. The dominant *correct* form, and the one matching this template's skip-gating design, is the hardened hand-rolled aggregate: py's `ci-ok` in this programme, and the shape `re-actors/alls-green`'s own README prescribes (`if: always()` plus per-result inspection, with an explicit warning that the naive form fails open). The naive aggregate's flaw is not a matter of opinion: it composes two accepted platform facts (P2a skip propagation, P1b/P1c skipped-as-success) into a false green on every dependency failure.

### Options

| Option | Where documented | Adopters that practise it | Most recent authoritative write-up |
|---|---|---|---|
| Hardened hand-rolled aggregate (`needs` + `always()` + result loop, `skipped` as pass) | py `.github/workflows/ci.yml:305-334` at local commit `b55b8c2`; R11 handover row (`DECISION.md:283`) | py-launch-blueprint (`ci-ok`); prescribed-by-documentation in `re-actors/alls-green` README ("Gotchas"/"Important" section) | py `ci.yml` header comment at `b55b8c2`, retrieved 2026-09-26 |
| Naive aggregate (`needs` only, unconditional success step) | hyper `.github/workflows/CI.yml:15-33` (blob `5d625ae…`) | hyper (`ci-pass`) | hyper `CI.yml` at `master`, retrieved 2026-09-26 |
| Third-party aggregator action | `re-actors/alls-green` README + `action.yml` + `src/job_outcome.py` at `unstable/v1` | Consumers of `re-actors/alls-green@release/v1` (173 stars, retrieved 2026-09-26) | README "Usage"/"Options" at `unstable/v1`, retrieved 2026-09-26 |
| Per-job required checks, no aggregate | tokio `.github/workflows/ci.yml` (blob `4223db7…`, 1,483 lines, no `always()`) | tokio (40+ individually required jobs) | tokio `ci.yml` at `master`, retrieved 2026-09-26 |
| Single required job, nothing to aggregate | ts `.github/workflows/ci.yml` at local commit `e5100b4` (196 lines; `ci` + advisory `bun-lane`) | ts-launch-blueprint | ts `ci.yml` at `e5100b4`, retrieved 2026-09-26 |

### Excluded by gate

**Naive aggregate (alternative B) — excluded, but by this item's own fail-closed requirement rather than a fitness gate.** Composing P2a with P1b/P1c: any dependency failure or cancellation skips the aggregate, and the skip satisfies the required check. It therefore fails B3, B4 and B5 open while appearing to gate. `actionlint` 1.7.12 exits 0 on the naive shape (executed negative control, `### Validation strategy`), so lint does not catch it; only the `always()`-plus-inspection rule does. hyper's `ci-pass` remains a valid reference for the topology (one job, full `needs:` list) but not for the verdict device.

No candidate is excluded by a fitness gate: gates 1–3, 5 and 6 are `inapplicable` as shown above, and gate 4 passes for every candidate. `re-actors/alls-green` in particular is `active`, not `at-risk` or `dormant` (pushed 2026-08-21, 7-of-8 responsiveness, no archival); it loses on fit (C's `allowed-skips` second-list problem), not on gates.

### Up-and-comers

1. **GitHub Rulesets** ([about-rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rules-for-a-repository/about-rulesets)) — the branch-protection successor. Required-status semantics carry over, so a `ci-ok` aggregate works identically under both surfaces; the settings-migration chore is the only cost. Watch for Ruleset-only features (e.g. required workflows at lower tiers) that could obsolete the hand-rolled job.
2. **Organization / required workflows** — a platform-native "run this workflow and require it" device. Currently Enterprise-gated and inapplicable to a public template; re-check if it reaches Team/free tiers.
3. **A platform change to skipped-required-check semantics** — the load-bearing assumption under P2 and R11's whole skipping design. R11 already carries this as a re-verify trigger; it is repeated here because inverting it flips this recommendation (a `skipped`-blocks world needs `allowed-skips`-style explicitness, i.e. alternative C's semantics, everywhere).

### Fit for this template

The template is one repository presenting three shapes, but this item decides a property of the repository's CI file, not of any shape — the same `ci.yml` gates all three. The per-shape argument is therefore about which jobs each shape exercises and whether the aggregate covers them.

**CLI.** The CLI is built and tested by `check` (build of the serve binary, workspace tests) and installed by `install-smoke`; all are in the aggregate's `needs:`, so a broken CLI binary fails `ci-ok` (B3, executed in the truth table). No CLI-specific aggregation is needed.

**Library.** The library surface is exercised by `check`'s clippy/test/doc steps and, once placed, R04's semver job and R35's coverage job — each of which joins the aggregate's `needs:` as a named slot (R11's slot rule; R04's placement row names R12 as deciding its aggregate membership). The aggregate is what keeps each such addition from needing a branch-protection edit (B1); that is the mechanism by which B1 pays for itself repeatedly over the template's lifetime.

**Web service.** The web surface is optional and feature-gated (`web-extra-surface`, R69), exercised by `check`'s feature-on steps and `install-smoke`'s web leg (a step conditioned on the `web` output). Under R11's accepted design `web` is fail-closed (every change that sets `code` also sets `web`), so web-affecting changes always run the web-exercising steps and their failures reach `ci-ok`; docs-only changes skip them and `ci-ok` still passes (B2). No web-specific aggregate branch is needed — the feature-on/feature-off matrix is inside `check`, and the platform folds matrix legs into one per-job result.

### Recommendation

Adopt the pattern **`always-on aggregate required check`**: one job named `ci-ok` in `.github/workflows/ci.yml`, branch protection (or its Ruleset successor) requiring exactly `ci-ok` and nothing else.

- `runs-on: ubuntu-latest`, no toolchain, no cache step, `permissions: {}` (no API calls, so no R08 re-grant needed).
- `needs:` over every required job id in the file: `plan`, `hygiene`, `workflow-lint`, `check`, `msrv-floor`, `install-smoke` — including `plan`, per R11's handover, so a failed detector fails `ci-ok` (B5). Every future required job (R04's semver job, a possible R35 coverage job, further R11 slots) joins this list when it lands.
- `if: always()` — the load-bearing line; without it the job is alternative B.
- One step: `env: RESULTS: ${{ join(needs.*.result, ' ') }}`, then the py-verbatim loop — fail on `failure` or `cancelled`, pass on `success` or `skipped`.
- No `merge_group`-specific logic: the job inherits `ci.yml`'s triggers (which include `merge_group` per R11), and `plan` publishes all-`true` on non-`pull_request` events, so queue entries run every gate and report through `ci-ok` (B6). py's own comment documents the failure mode this avoids: without the trigger, "the ci-ok required check never reports and every queue entry deadlocks at Expected" (py `ci.yml:16-19`).
- Matrix legs need no special handling: the platform folds `check`'s per-OS legs into one job result, so one `needs:` entry covers both runners.

**Reference implementation.** py's `ci-ok` (py `.github/workflows/ci.yml:305-334` at local commit `b55b8c2`), adapted only in the `needs:` list (R11's six job ids instead of py's ten). Plus the minimal end-to-end shape built and executed for this report, reproduced under `### Validation strategy`.

### Ranked runner-up

**Per-job required checks with no aggregate (alternative D, tokio's shape).**

**The condition under which it wins:** the owner decides that per-gate granularity in the branch-protection settings is worth the admin coupling — i.e. the same hands that edit `ci.yml` always hold branch-protection admin, the job set is stable enough that the list rarely changes, and downstream template forks are expected to keep admin discipline. tokio proves this works at scale (40+ jobs) with a large maintainer team. It also wins automatically if the platform ever reports aggregate results unusably (e.g. required-check UI stops surfacing which dependency failed — today the PR checks list still shows every job individually, so this is hypothetical). It is the only runner-up that satisfies B3–B5 without trusting a verdict device of our own.

### Tradeoffs

**Versus per-job required checks (ranked runner-up).** The aggregate gives up per-gate blocking granularity at the settings level: branch protection sees one name, and a red `ci-ok` requires opening the run to find which job failed (mitigated: the PR checks list still shows every job's own status; nothing is hidden, only the blocking bit moves). It introduces its own drift mode: a new required job that lands without joining `needs:` is silently non-gating — the exact failure the aggregate removes from settings reappears in YAML. Why accepted: the YAML list lives in the same file as the jobs, editable in the same pull request by the same author with no admin rights, while the settings list needs a privileged second step in a different surface; R11's slot rule ("a check needing its own toolchain/runner/`target/` becomes its own job") gives every future addition a named moment at which the `needs:` update is reviewed. The runner-up's drift is silent *and* privileged; the aggregate's drift is silent but unprivileged and co-located.

**Versus `re-actors/alls-green` (alternative C).** The recommendation gives up a maintained abstraction (named allow-lists, per-job verdict table in the log, structured outputs) for a six-line shell loop owned by the template. Why accepted: the abstraction's default semantics (`REQUIRED` = `success` only) fight R11's accepted skip-gating design and force an `allowed-skips` list that duplicates `needs:`; it adds a third-party supply-chain entry and a Python runtime to a job that needs neither; and py's in-programme precedent proves the hand-rolled form is reviewable and sufficient.

**Versus the naive aggregate (alternative B).** The recommendation gives up three-line brevity (`needs:` + `exit 0`) for `always()` plus an explicit loop. Why accepted: the short form fails open on every dependency failure (P2a + P1c), which is the one outcome an aggregate exists to prevent. There is no setting in which B is acceptable as the required check.

**Versus doing nothing under a single-job shape (alternative E).** Not available: R11 revision 7 (accepted 2026-09-23) settled six job ids with skip-gating. Had R11 chosen single-job, E would have been this item's answer at zero lines — the aggregate's entire value is conditional on multi-job CI, which is now decided fact.

### Parameters

R12 owns no registered parameter — `research/CLAUDE.md`'s `owns` column for R12 is `—`, and `docs/port/PARAMETERS.md` lists no `researched` row owned by R12. No `owns <param> = <value>` lines.

- `assumes ci-job-structure = <R11 revision 7 accepted value: one ci.yml, plan-gated compile-tier CI with job ids plan, hygiene, workflow-lint, check (matrix over os), msrv-floor, install-smoke; positive predicates; triggers pull_request + push to main + merge_group; no trigger-level path filter; full text in inputs/parameters.json of this run>` — the aggregate's `needs:` list is exactly R11's job-id set, and the skipped-as-pass verdict exists only because R11 skip-gates. The handover constraint ("either `plan` is itself a required check, or the aggregate includes `plan` in its `needs:` and treats `failure`/`cancelled` as failure") is met via the second option.
- `assumes rust-edition = 2024` — no Rust code is added; nothing to be edition-sensitive to.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — the aggregate is workflow YAML plus POSIX shell; it has no toolchain and cannot raise the floor.
- `assumes license = MIT OR Apache-2.0` — nothing enters the template's dependency or license tree.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` — the aggregate runs on `ubuntu-latest` only (no toolchain, no cache, nothing OS-specific); both matrix legs of `check` fold into its verdict through the platform's per-job result.

No `CONFLICT:` lines. The recommendation needs no registered value changed; it takes the aggregate branch of R11's explicitly offered either/or.

### Migration implications

File-level changes in the template.

- **`.github/workflows/ci.yml`** — gains one job, `ci-ok` (~30 lines, as in `### Validation strategy`): `needs:` over the six R11 job ids, `if: always()`, `permissions: {}`, one verdict step. No other job is modified. Each future required job (R04's semver job first) adds one line to `needs:` when it lands.
- **Branch protection / ruleset (repository settings, not a file)** — the required-status-check list becomes exactly `ci-ok`. Every individual job name is removed from the list. P03 performs this cutover and verifies B1–B6 live.
- **`CONTRIBUTING.md` (or the template's contributor doc)** — one paragraph: a new required job must join `ci-ok`'s `needs:` in the same pull request (the aggregate's drift mode); `skipped` is a passing verdict for legitimately inapplicable gates; never remove `if: always()`.
- **Files *not* added:** no third-party action reference, no `allowed-skips` list, no per-job settings documentation, no nightly or extra toolchain.

### Validation strategy

Toolchain and OS for everything below: `actionlint 1.7.12` (same version R11 used), `shellcheck`, `bash`, macOS `aarch64-apple-darwin`, 2026-09-26. Fixtures live outside the deliverable (scratch probe files, not committed) because this leg writes exactly one file; their content is reproduced here.

**Executed check 1 — the candidate shape lints.** A minimal workflow with R11's six job ids (gated jobs behind `needs: plan` + positive predicates, `merge_group` trigger present) plus the recommended `ci-ok` job: `actionlint` exits 0 with zero diagnostics. Expected: clean lint. **Observed as expected.**

**Executed check 2 — the verdict truth table.** The `ci-ok` step body replicated verbatim against seven synthetic `needs.*.result` vectors: all-success → exit 0; docs-only vector (`success success skipped skipped skipped skipped`) → exit 0 (B2); single skip → exit 0; one `failure` → exit 1 (B3); detector-failed vector (`failure success skipped skipped skipped skipped`, the R11 failed-`plan` shape) → exit 1 (B5); all-`cancelled` → exit 1 (B4); failure-mixed-with-skips → exit 1. 7 of 7 as expected, and the probe script itself is `shellcheck`-clean. **Observed as expected.**

**Executed check 3 — negative control: the naive shape also lints.** The same fixture with the hyper-style aggregate (no `if:`, single `run: exit 0` step): `actionlint` exits 0 with zero diagnostics. Expected per the exclusion argument: lint cannot distinguish alternative A from alternative B, so the `always()`-plus-inspection rule must travel in prose and review. **Observed as expected.**

**Executed check 4 — third-party verdict semantics, by source read.** `re-actors/alls-green` `src/job_outcome.py` at `unstable/v1`: `REQUIRED: frozenset({'success'})` — a skipped required job fails the aggregate unless allow-listed. Expected (README-implied): confirmed at the code level. This is the evidence behind alternative C's rejection. **Observed as expected.**

**Planned, not executed (P03 live-PR checks, each with expected behavior).**

- Docs-only pull request: gated jobs report skipped, `ci-ok` green, merge allowed (B2).
- One failing job (e.g. forced clippy failure in `check`): `ci-ok` red, pull request unmergeable (B3).
- Forced `plan` failure (unreachable `BASE_SHA`): every gated job skips, `ci-ok` red, pull request unmergeable — R11 criterion 13 (B5).
- Cancelled run: `ci-ok` non-green (B4).
- `merge_group` entry: full run, `ci-ok` reports, no stuck "Expected" (B6).
- Settings cutover: branch protection requires exactly `ci-ok`; a job rename with no settings change still gates (B1).

Not executed because no CI run exists for this template yet — same standing as R11's P03 list, which these extend.

### Confidence & re-verify trigger

**High confidence** that the template needs an aggregate (the R11-dependence question). R11 revision 7 is accepted fact: six job ids, four of them routinely `skipped` on docs-only pull requests. Under that shape the aggregate removes a privileged settings-sync chore per job change; under single-job it would be pure overhead. Both branches are evidenced (py/ts precedent, R11 accepted value).

**High confidence** on the hardened form over the naive form. The naive form's fail-open path composes two accepted platform facts (P2a, P1b/P1c) with no missing link, and the negative control shows lint will not save a template author from it. The `always()`-plus-inspection rule is additionally prescribed by the third-party action's own README.

**Medium-high confidence** on hand-rolled over `re-actors/alls-green`. The `allowed-skips` second-list argument is structural (read at the code level), and the supply-chain minimization matches R11's hand-rolled-detector precedent; but the action is genuinely maintained (`active`, 0.45-day median response), so a future version with skipped-as-pass defaults would reopen the comparison.

**Medium confidence** on the exact long-run `needs:` membership. The six R11 ids are settled; each future slot (R04 semver, possible R35 coverage job, further R11 slots) must join the list, and that discipline is prose, not machinery.

**Re-verify triggers.**

1. GitHub changes the required-status behavior of a `skipped` job — inverts P2 and reopens C-vs-A (shared with R11's trigger list).
2. R11 publishes a new revision changing its job-id set — the `needs:` list must match it exactly.
3. R04, R13, R32 or R35 lands a new required job — it must join `needs:` in the same change.
4. Rulesets gain a required-workflow or native-aggregation feature at non-Enterprise tiers — alternative A could become platform-native.
5. `re-actors/alls-green` changes `REQUIRED` semantics to accept `skipped`, or is archived / gains an advisory — reopens or closes alternative C.
6. P03's live checks (criterion 13 especially) contradict any B1–B6 expectation.

Calendar re-verify: **2027-03-26** (six months), or immediately on any trigger above.

### Sources

Source repositories, local pins. py-launch-blueprint at `b55b8c2` (`.github/workflows/ci.yml`, `ci-ok` at lines 305–334, merge-queue comment at lines 16–19, header at lines 6–7); ts-launch-blueprint at `e5100b4` (`.github/workflows/ci.yml`, 196 lines). Both read locally 2026-09-26.

| # | Claim | Source | Retrieved |
|---|---|---|---|
| S1 | `re-actors/alls-green`: 173 stars, `archived: false`, `pushed_at 2026-08-21T23:59:58Z`, `BSD-3-Clause`, default branch `unstable/v1` | `GET https://api.github.com/repos/re-actors/alls-green` | 2026-09-26 |
| S2 | `alls-green` open issues `total_count` 7 (direct listing 8 rows; search-index lag noted) | `GET https://api.github.com/search/issues?q=repo:re-actors/alls-green+is:issue+is:open` + `GET …/issues?state=open&per_page=10&sort=created&direction=desc` | 2026-09-26 |
| S3 | `alls-green` responsiveness: 7 of 8 with maintainer reply, median 0.45 days; #40 unanswered (owner self-notes) | `GET https://api.github.com/repos/re-actors/alls-green/issues/<n>/comments?per_page=5` for n in 40, 36, 35, 34, 30, 28, 26, 21 | 2026-09-26 |
| S4 | `alls-green` usage, `always()` requirement, allow-list options | `GET https://api.github.com/repos/re-actors/alls-green/contents/README.md?ref=unstable/v1` | 2026-09-26 |
| S5 | `alls-green` composite action inputs (`jobs`, `allowed-failures`, `allowed-skips`) | `GET https://api.github.com/repos/re-actors/alls-green/contents/action.yml?ref=unstable/v1` | 2026-09-26 |
| S6 | `alls-green` verdict matrix: `REQUIRED` accepts only `success` | `GET …/contents/src/job_outcome.py?ref=unstable/v1` (+ `normalize_needed_jobs_status.py`) | 2026-09-26 |
| S7 | hyper: 16,333 stars, `archived: false`, `pushed_at 2026-09-26T02:29:09Z`; naive `ci-pass` at `CI.yml:15-33` (blob `5d625ae…`) | `GET https://api.github.com/repos/hyperium/hyper` + `GET …/contents/.github/workflows/CI.yml?ref=master` | 2026-09-26 |
| S8 | tokio: 33,246 stars, `archived: false`, `pushed_at 2026-09-26T15:24:17Z`; `ci.yml` 1,483 lines (blob `4223db7…`), 40+ jobs, no `always()` | `GET https://api.github.com/repos/tokio-rs/tokio` + `GET …/contents/.github/workflows/ci.yml?ref=master` | 2026-09-26 |
| S9 | Skipped-by-conditional reports SUCCESS; skipped is a successful check status; failed/skipped deps skip dependents; `always()`-with-`needs` vendor instruction | R11 accepted evidence `research/topics/11-ci-workflow-job-structure/evidence/2026-09-18T215915Z-7fbece2a29a7-r11-platform-docs.r2-rerun.log` (P1b, P1c, P2a, P2b), read locally | 2026-09-26 |
| S10 | R11 handover: failed `plan` must fail a required check; aggregate must include `plan` and treat `failure`/`cancelled` as failure; criterion 13 | `research/topics/11-ci-workflow-job-structure/DECISION.md:180,283` + `:251` (criterion 13), read locally | 2026-09-26 |
| S11 | F041 (`Single aggregate required-status-check job…`, `DIVERGENT`, `Item: R12`) | `docs/port/COMMONALITY.md:47`, read locally | 2026-09-26 |
| S12 | Licence gate `inapplicable` per owner ruling 2026-09-12 (Q7.B) | As recorded in R11 `DECISION.md:256`, read locally | 2026-09-26 |
| S13 | Candidate shape: `actionlint` 1.7.12 exit 0; naive shape: `actionlint` exit 0 (negative control); verdict truth table 7/7; probe `shellcheck`-clean | Executed on this host (fixtures in scratch, reproduced under `### Validation strategy`) | 2026-09-26 |

Vendor documentation pages underlying S9 (as snapshotted by R11 from `github/docs`; not re-fetched on this leg): required-status-check troubleshooting, the `needs` workflow-syntax reference, the `needs` context reference, protected-branch settings, merge-queue management, and Rulesets ([about-rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rules-for-a-repository/about-rulesets)).
