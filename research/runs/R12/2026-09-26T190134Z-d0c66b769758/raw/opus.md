# R12 — Aggregate required-status check (pattern, Focused)

Engine: opus (`claude-opus-5-5`). Run: `research/runs/R12/2026-09-26T190134Z-d0c66b769758`. Every retrieval is dated **2026-09-26** unless stated otherwise. This leg read no other engine's report.

**Answer in one paragraph.** `rs-launch-blueprint` should add one aggregate job, `ci-ok`, to `.github/workflows/ci.yml`. It depends on every other job in that file, `plan` included. It runs under `if: ${{ always() }}` and passes only when every needed job ended `success` or `skipped`. Branch protection, preferably a repository ruleset, then requires that one context, and only when the GitHub Actions app (`integration_id` 15368) sets it. A static guard in R11's `workflow-lint` job fails CI when a `ci.yml` job is missing from `ci-ok`'s `needs:`. The aggregate is worth having even without skip-gating, because R11's `check` matrix already emits one context per runner and a template's branch-protection settings do not copy into generated repositories. R11's skip-gating makes the aggregate necessary rather than merely convenient: a failed `plan` skips every gated job, and a skipped job reports success.

### Landscape

**Category this item decides.** This is a *merge-gate topology* decision, not a crate choice. It decides how many status-check contexts the repository's branch protection names, and what computes the verdict those contexts carry. Every candidate is a GitHub-platform mechanism or a GitHub Action. None of them enters `Cargo.toml`. The Rust-specific content is the job graph R11 produces and the practice of Rust projects.

**Terms used below.**

- A **context** is the name under which a check run reports on a commit; branch protection requires contexts by that name. A matrix job reports one context per leg, for example `check (ubuntu-latest)`.
- An **aggregate job** is a job whose `needs:` lists other jobs and whose only work is to turn their results into one pass or fail.
- `needs.<job>.result` is one of `success`, `failure`, `cancelled` or `skipped` (GitHub `needs` context).
- **Source pinning** means configuring the required check to accept a status only from one GitHub App.

**Three-bin map of the field.**

| Bin | Candidates found | Evidence of the placement |
|---|---|---|
| Built-in / first-party (GitHub platform) | (a) list every job and matrix-leg context as a required check; (b) an in-workflow aggregate job using `needs:` plus `if: always()` and a result test, which is the pattern GitHub's own troubleshooting page prescribes ("Use `always()` with `needs` for required checks that depend on other jobs"); (c) the organization-ruleset rule **Require workflows to pass before merging**; (d) the `merge_group` trigger for merge-queue reporting | `github/docs@18945a31` pages cited under `### Sources` |
| Established industry standard | (e) a hand-rolled aggregate that tests `toJSON(needs)` with `jq`, used by `rust-lang/cargo`, `rust-lang/rust-analyzer`, `rust-lang/rust-clippy`, `rust-lang/rustup`, `astral-sh/uv` and `astral-sh/ruff`, and in a variant using `contains(needs.*.result, …)` by `clap-rs/clap`; (f) the maintained action `re-actors/alls-green`, established in the Python ecosystem (aiohttp, attrs, pip-tools, setuptools, PyCA and pytest, per its README) | workflow files and live rulesets fetched through the GitHub REST API; alls-green README |
| Up-and-comer | (g) check-run pollers that wait on *every* check on the commit, across workflow files: `poseidon/wait-for-status-checks`, `upsidr/merge-gatekeeper`, `lewagon/wait-on-check-action`; (h) a static completeness guard that asserts the aggregate's `needs:` covers every job in the file. I found no published tool for (h); I propose an inline one below | READMEs fetched through the GitHub REST API |

**Authorities used, and why each counts.**

| Source | Why it is authoritative |
|---|---|
| GitHub Docs, *Troubleshooting required status checks* (`github/docs@18945a31`) | The platform operator's own statement of how a skipped job, a skipped workflow and a failed dependency report to a required check. This single page decides most of this item. |
| GitHub Docs, *About protected branches*, *Available rules for rulesets*, *Status checks* reference, *Expressions*, and the `jobs.<job_id>.needs` section of the workflow syntax | Normative definitions: which conclusions count as passing, the expected-source (app) restriction, uniqueness of job names, and the semantics of `always()` versus `!cancelled()`. |
| Live repository rulesets and branch protection of Rust project repositories (`GET /repos/<o>/<r>/rules/branches/<b>` and `GET /repos/<o>/<r>/branches/<b>`) | Primary evidence of what the projects actually *require*, not only what their workflow files contain. `rust-lang/*` repositories are maintained by the Rust project's own teams, the most authoritative practice source in this ecosystem. |
| Actions run records of those repositories (`GET /repos/<o>/<r>/actions/runs/<id>/jobs`) | Primary evidence of how the aggregate job actually concluded in cancelled runs. Used to settle the `always()` versus `!cancelled()` question empirically. |
| `re-actors/alls-green` README, `action.yml` and source (maintainer documentation) | The maintained third-party implementation; its README documents the "aggregate is skipped when a dependency fails" trap from first-hand incident experience (Dependabot PRs auto-merged broken in aiohttp). |
| `actions/runner-images`, `images/ubuntu/Ubuntu2404-Readme.md` | The runner vendor's own inventory; establishes that `jq` 1.7 and `yq` 4.53.6 are preinstalled on `ubuntu-latest` (image 20260920.314.1). |
| `py-launch-blueprint` and `ts-launch-blueprint` at their task-pinned commits, plus their live branch settings | The source precedent (spec §2). Evidence, not a winner by default. |

**Practice evidence — mainstream, well-regarded Rust projects surveyed.** Workflow files were fetched from the default branch through `GET /repos/<o>/<r>/contents/<path>` at about 19:55Z. Stars, `pushed_at` and the head commit come from `GET /repos/<o>/<r>` and `GET /repos/<o>/<r>/commits/<branch>` at about 20:10Z. Required checks come from the two public branch-rule endpoints named above. "Not in `needs`" is computed by parsing the workflow with PyYAML and comparing the job set with the aggregate's `needs:` list. **App pinning is visible only for rulesets.** The public branch endpoint exposes classic-protection `contexts` but not the per-check `app_id`, which needs admin access. So for ruff, clap, tokio and bevy, whether the required check is pinned to an app is unknown, not absent.

| Project (stars; head at retrieval) | Aggregate job in the CI workflow | `if:` form; result rule | Jobs in the file but not in `needs` | What branch rules require |
|---|---|---|---|---|
| `rust-lang/cargo` (15,520; `07b80494920f`) | `conclusion`, 12 needs | `!cancelled()`; all `success` | `stale-label`, `check-version-bump` (label/bump helpers) | ruleset: `conclusion`, source app 15368 |
| `rust-lang/rust-analyzer` (16,876; `86493cee4d89`) | `conclusion`, 9 needs | `!cancelled()`; `success` or `skipped` | **`changes`** (the path detector) and `cancel-if-matrix-failed` | ruleset: `conclusion`, source app 15368 |
| `rust-lang/rust-clippy` (13,536; `072f108d4de4`) | `conclusion` in `clippy_mq.yml` (5 needs) and `clippy_pr.yml` (2) | `!cancelled()`; all `success` | none | ruleset: `conclusion`, `conclusion_changelog`, `conclusion_dev`, `conclusion_remark`, all app 15368. The four names indicate one aggregate per workflow file; I read two of those files |
| `rust-lang/rustup` (7,052; `b32adec5ab61`) | `conclusion`, 13 needs | `always()` | none | ruleset: `conclusion`, app 15368 |
| `astral-sh/uv` (90,199; `136ef9733078`) | `required-checks-passed` ("all required jobs passed"), 9 needs, **includes its detector `plan`** | `always() && github.ref != 'refs/heads/main'`; `success` or `skipped`, plus a label-conditional job table | 14 jobs deliberately non-required (publish, docker, bench, ecosystem) | ruleset: `all required jobs passed`, app 15368 |
| `astral-sh/ruff` (49,803; `e4dd9152790f`) | `required-checks-passed`, 13 needs, **includes its detector `determine_changes`** | same as uv | 18 jobs deliberately non-required (benchmarks, fuzz, ecosystem) | classic protection: `all required checks passed` |
| `clap-rs/clap` (16,725; `8ab46fe22b4a`) | `ci` (name `CI`), 11 needs | `always()`; step fails on `contains(…,'failure'\|'cancelled'\|'skipped')` | `coverage` | classic: `CI`, `Spell Check with Typos`, `Audit` — the aggregate plus one context per other workflow |
| `tokio-rs/tokio` (33,246; `facc6fc47eb2`) | none (46 jobs; the largest fan-in job `basics` needs 4) | — | — | classic: **46 individual contexts**, including matrix legs such as `test tokio full (macos-latest)` |
| `bevyengine/bevy` (48,401; `0f38358f573a`) | none | — | — | classic: **24 individual contexts** |
| `rust-lang/crates.io` (3,703; `067b45e1a15f`) | none; a `filter-jobs` detector gates jobs | — | — | ruleset: 5 individual contexts, app 15368 |
| `serde-rs/serde`, `BurntSushi/ripgrep`, `tokio-rs/axum`, `nextest-rs/nextest` | none | — | — | not queried |

The reading: **every Rust-project-team repository surveyed (cargo, rust-analyzer, clippy, rustup) and both Astral repositories require exactly one aggregate context per gating workflow.** The five that configure it through a ruleset (cargo, rust-analyzer, clippy, rustup, uv) pin it to the GitHub Actions app; ruff's classic-protection pinning is not publicly visible. The individual-listing projects (tokio, bevy, crates.io) are real and well maintained. Their lists were **in sync** when I checked (see the MEDIUM question below), so individual listing is a workable choice for a single repository with an attentive admin. It is not the choice of the Rust project's own teams. Popularity does not separate the two camps: bevy (48k stars) lists individually, and uv (90k) aggregates.

**Fit anchors.** The consumer is a template whose generated repositories do not inherit repository settings. The job graph is already fixed by R11 (`ci-job-structure`): an always-run `plan` detector, `hygiene`, a path-gated `workflow-lint`, a `check` matrix over `target-os-matrix`, `msrv-floor` and `install-smoke`. That graph yields **seven contexts** without an aggregate: `plan`, `hygiene`, `workflow-lint`, `check (ubuntu-latest)`, `check (macos-latest)`, `msrv-floor` and `install-smoke`.

### Principles and implementation

**Shared requirement, source and agreement level.**

| ID | Principle | Source | Agreement level across py / ts / rs |
|---|---|---|---|
| P1 | **Gate completeness.** Every check the project treats as blocking must block the merge when it fails, is cancelled, or never ran for an unexplained reason. | GitHub Docs troubleshooting table: "A job depends on a failed job — The dependent job is skipped and may not block merging" | **policy** — must agree in all three |
| P2 | **The blocking set lives in version control.** The set of blocking checks is defined in a reviewed file. The out-of-band repository setting reduces to a minimal, stable set of names. | py `docs/source/about/design_decisions.md:479-485` ("branch protection that doesn't need editing every time CI evolves"); alls-green README | **policy** — must agree; the file format may vary |
| P3 | **A skip passes only when a trusted decision caused it.** | R11 hand-over (R11 `DECISION.md:180,283`); GitHub: skipped reports Success | **policy** — must agree wherever skip-gating exists |
| P4 | **Source authenticity.** Only the CI app can satisfy the required context. | *About protected branches*: "Any person or integration with write permissions to a repository can set the state of any status check … you can select an app … as the expected source" | **policy** — must agree |
| P5 | **Merge-queue parity.** The same context reports on the queue's speculative merge. | GitHub reusable `merge-group-event-with-required-checks` | **capability** — must agree where a queue is used (F025, ADOPT) |

**What must agree and what may vary.** P1–P5 must agree across the three repositories. The threat and the platform are identical, and nothing about Python, TypeScript or Rust changes how GitHub evaluates a required check. The mechanism may vary: a bash loop, `jq`, or an action. The context name *should* agree (`ci-ok`) for a concrete reason. GitHub rulesets can require a status check at organization level, so one shared name lets one organization ruleset gate every blueprint repository. This is a convenience, not a correctness requirement, and I record it as a proposal.

**How py and ts realize the principles today, verified locally and from live settings.**

- **py** (`~/c/py-launch-blueprint` @ `b08bccfb55d05f15e46a83b52c5660b1881d19f5`) has `ci-ok` at `.github/workflows/ci.yml:268-295`. Its `needs:` covers every other job in the file, including the detector `changes`. It runs under `if: always()` and declares `permissions: {}`. It fails when any result is `failure` or `cancelled`, a deny-list. At HEAD `b55b8c26364cb0f42e56116e6780921976334751` the file has grown to ten needed jobs (`release-generation` and `shellcheck` were added), and `ci-ok` still covers all of them.
  - **Zero drift in 21 revisions.** I parsed every revision of `ci.yml` that contains `ci-ok` (21 commits, `7b520d3` on 2026-06-12 through `06d2582` on 2026-09-15). No revision had a job missing from `ci-ok`'s `needs:`. The in-repo list was kept in sync by review alone.
  - **"Single" in practice means one per workflow.** py's live protection on `main` requires **eight** contexts, all pinned to app 15368: `ci-ok`, `commitlint (humans)`, `actionlint`, `bandit`, `codespell`, `editorconfig-check`, `yamllint` and `press-verify`. `needs:` cannot cross workflow files, so the five `lint.yml` jobs are listed individually. That reintroduces, for `lint.yml`, the drift exposure `ci-ok` was built to remove.
  - **Individual listing has already failed py once.** py's own `docs/research/0004-template-press-dogfood-log.md:249-260` (PROBLEM-15) records that the documented context list included blueprint-only jobs that "do NOT exist in a generated repo". The log continues: "Using the list verbatim makes every fork PR permanently 'blocked' on contexts that never report — the exact trap hit on PR #428 of the blueprint itself." `docs/adr/0014-repo-simplification-batch.md:86-89` shows the matching cost from the other side: jobs had to keep their old names "so branch-protection required checks survive unchanged".
- **ts** (`~/c/ts-launch-blueprint` @ `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`) has a single job, `ci` (name `continuous-integration`), with a `node-version` matrix of `['24.x', '26.x']` (`.github/workflows/ci.yml:40-52`). It has **no `merge_group` trigger** (`ci.yml:30-34`). Two facts contradict the prompt's context.
  - **ts does have an aggregation problem.** The matrix emits two contexts, `continuous-integration (24.x)` and `continuous-integration (26.x)`, whose names change whenever the Node matrix moves, which D-027 schedules.
  - **ts requires no status check at all.** The prompt says ts's branch protection "presumably targets the one `ci` job directly". Live settings show otherwise: `GET /repos/smorinlabs/ts-launch-blueprint/branches/main/protection` returns `404 Branch not protected`. The only ruleset is the organization's `merge-methods: no squash` (`GET …/rulesets`), and `GET …/rules/branches/main` returns no `required_status_checks` rule. ts's CI is therefore advisory: a red CI does not block a merge.

This is **missing capability, not a justified ecosystem difference**. Nothing in TypeScript makes an unrequired CI appropriate.

BASELINE-REVIEW: F041 — gate completeness (P1) and the in-repo blocking set (P2) are platform-level policies that ts lacks, not a py-only nicety — reclassify ts's absence from "nothing to aggregate" to missing capability, and treat the harmonization as a py/ts follow-on — evidence: ts `ci.yml:40-52` emits two matrix contexts; ts `main` has no required status check (`GET /repos/smorinlabs/ts-launch-blueprint/branches/main/protection` → 404, no `required_status_checks` rule); ts has no `merge_group` trigger although F025 is ADOPT; py PROBLEM-15 shows individual listing breaking generated repositories.

This does not change the ledger or any other item. Affected rows: F041, and F025 for ts's missing `merge_group`. The recommendation below stays inside R12's scope.

**Architectural alternatives compared.** These are different architectures, not interchangeable libraries.

| Architecture | What branch protection names | Who defines the blocking set | Handles R11's failed-`plan` hazard | Crosses workflow files | Template portability |
|---|---|---|---|---|---|
| A. List each context | 7 contexts today, changing with `target-os-matrix` and every job rename | repository admin, out of band | only if `plan` is also listed — an easy omission | yes, by listing | poor: settings do not copy into generated repositories; PROBLEM-15 |
| **B. In-workflow aggregate (`ci-ok`)** | 1 per gating workflow | the reviewed `ci.yml` | yes, with `plan` in `needs:` | no — one aggregate per workflow file | good: one stable name |
| B′. Same, computed by `re-actors/alls-green` | 1 per gating workflow | the reviewed `ci.yml`, plus action inputs | yes | no | good |
| C. Check-run poller (`wait-for-status-checks`, `merge-gatekeeper`) | 1 | whatever happens to run on the commit | only if `plan`'s failure surfaces as a failed check — it does | **yes** | good, but it needs a token with `checks: read`, polls the API, and occupies a runner while waiting |
| D. Organization ruleset "Require workflows to pass" | a workflow, not a job | organization settings | yes | yes | organization-owned repositories only; configured "in your organization settings" |
| E. External merge bot (`bors` / merge queue reading the workflow conclusion) | bot status | bot configuration | yes | yes | heavy; the Rust compiler repository's model, out of proportion for a template |

B is complete, consumer-side, dependency-free and available on every plan. C is the only in-repository option that crosses workflow files. It trades a deterministic `needs:` graph for API polling and a token. D is the platform's cross-workflow answer, but it applies only to organization-owned repositories, and a template cannot assume its adopter's ownership.

**HIGH 1 — does the aggregate's value depend on R11?** It does not depend on skip-gating; skip-gating raises it from useful to necessary.

1. **Without any skip-gating it still pays.** R11's `check` is a matrix over `target-os-matrix`. Its contexts are `check (ubuntu-latest)` and `check (macos-latest)`, and they change when the owner-fixed matrix changes. py's design note gives exactly this reason: "required-check lists tied to individual matrix cells break whenever the matrix changes". ts shows it with a single job: one job, two contexts.
2. **The template argument is independent of R11.** Branch protection is repository state and is not produced when a repository is generated from a template. A generated repository's owner must enter the list by hand from documentation, and py PROBLEM-15 shows that such a list goes wrong. One name, `ci-ok`, is the smallest list that can be documented.
3. **With R11's skip-gating the aggregate is load-bearing.** R11 hands over this constraint (`DECISION.md:180`): "a failed `plan` must itself fail a required check … either `plan` is itself a required check, or … the aggregate includes `plan` in its `needs:` and treats `plan`'s `failure` or `cancelled` result as failure." Under architecture A that is one more name to remember. Under B it is structural: `plan` is in `needs:`, and `failure` fails the gate (truth-table row T3, executed).

**HIGH 2 — idiomatic mechanism, and the ways a hand-rolled expression passes silently.** The Rust-idiomatic form is a `jq` test over `toJSON(needs)`. `rust-lang/cargo`, rust-analyzer, clippy, uv and ruff all use it, and GitHub's docs describe the surrounding `needs:` plus `always()` shape. I executed four decision rules against nine cases:

| Case | Recommended: `length > 0 and all(.result == "success" or "skipped")` | py `ci-ok`: deny `failure`/`cancelled` | cargo: all `success` | naive: `!contains(…,'failure')` |
|---|---|---|---|---|
| T1 all success | PASS | PASS | PASS | PASS |
| T2 docs-only PR, gated jobs skipped | PASS | PASS | **FAIL** | PASS |
| T3 `plan` failed, gated jobs skipped | FAIL | FAIL | FAIL | FAIL |
| T4 `plan` cancelled, gated jobs skipped | FAIL | FAIL | FAIL | **PASS** |
| T5 one `check` leg failed | FAIL | FAIL | FAIL | FAIL |
| T6 `check` cancelled | FAIL | FAIL | FAIL | **PASS** |
| T7 `hygiene` failed | FAIL | FAIL | FAIL | FAIL |
| T8 an unrecognized result value | FAIL | **PASS** | FAIL | **PASS** |
| T9 empty `needs` | FAIL | **PASS** | **PASS** | **PASS** |

Four failure modes follow; each has a concrete remedy.

- **The aggregate itself is skipped.** Without `always()` (or `!cancelled()`), a failed dependency makes the aggregate `skipped`, and a skipped job "will report its status as 'Success'". `actionlint` 1.7.12 accepts that broken form: I removed the `if:` line from the fixture, and it still exited 0 (V2). So lint does not protect against this; the `if:` line and a review rule do.
- **A result not enumerated.** A deny-list passes T8, because anything it does not name passes. A positive allow-list (`success` or `skipped`) fails closed. The `contains(…,'failure')` idiom passes T4 and T6 because it forgets `cancelled`.
- **An empty or partial `needs:`.** `all()` over an empty set is true (T9), so the recommended rule adds `length > 0`. A job simply left out of `needs:` is invisible to *every* rule. That is not hypothetical: **rust-analyzer's `conclusion` omits its detector `changes`**, while `typescript` is gated on `needs.changes.outputs.typescript == 'true'`. A failed `changes` therefore skips `typescript`, and `conclusion` counts the skip as a pass — exactly the hazard R11 hands to R12. The remedy is the completeness guard below (V4, executed).
- **A spoofed status.** Anything with `statuses: write` can post a commit status named `ci-ok`. Pinning the required check to app 15368 closes that path. cargo, rust-analyzer, clippy, rustup, uv and crates.io all do so.

A maintained action (`re-actors/alls-green`) removes the need to write the `jq` line. It does not remove the two gaps that matter here: `needs:` completeness and the `if:` line are still hand-written (its README: "it is a must to have the job always run"). Its default semantics treat `skipped` as *failure* unless the job is listed in `allowed-skips`. That is stricter than necessary under R11, where `plan` is folded in and the detector fails closed. It would require naming `workflow-lint`, `check`, `msrv-floor` and `install-smoke` in a second list that must also be kept in sync. It is the runner-up, not the pick.

**`always()` or `!cancelled()`.** GitHub gives both. The expressions page recommends `!cancelled()` to "run a job or step regardless of its success or failure", and warns that `always()` may hang on "any task that could suffer from a critical failure, for example: getting sources". The required-checks troubleshooting page prescribes `always()` with `needs`. The feared hazard is that under `!cancelled()` a *cancelled* run leaves the aggregate `skipped`, which would count as green. **Public run records show it does not happen.** In 12 of 12 cancelled runs inspected (6 in cargo `main.yml`, 6 in rust-analyzer `ci.yaml`, 2 of them `merge_group`), the `conclusion` job concluded **`cancelled`**, which is not a passing conclusion, not `skipped`. Under `always()`, uv's and clap's aggregate *ran* in cancelled runs and judged the needed results: `success` when the cancelled job was outside `needs`, `failure` otherwise. **Both forms are safe.** I recommend `always()` for three reasons:

1. R11's R12 row already prescribes it.
2. It matches GitHub's required-check-specific guidance.
3. It matches py, which keeps cross-repo agreement.

The docs' hang warning does not apply, because `ci-ok` has no checkout, no network and a `timeout-minutes: 5` cap. The cost is a few seconds of runner time on every superseded run, which ends red rather than grey. `!cancelled()` is an accepted equivalent (see `### Tradeoffs`).

**HIGH 3 — principles and agreement across the three repositories.** Must agree: P1–P5 and the rule "fold every job, the detector included; pass only on `success` or `skipped`; require the aggregate alone per gating workflow; pin it to the Actions app". Justified variation: none in the principle, and only mechanism in the implementation. py's bash deny-list and rs's `jq` allow-list are two spellings of one rule; the allow-list is the fail-closed spelling. Accidental drift: ts lacks the capability entirely (BASELINE-REVIEW F041 above). py lists `lint.yml` jobs individually, which its own P2 argues against. Follow-on changes to py and ts, for which this answer supplies the rationale:

- **py:** switch the result test to the positive allow-list; add the completeness guard; fold `lint.yml`'s five jobs into a `lint-ok` aggregate or move them into `ci.yml`.
- **ts:** add required checks, add `merge_group`, and add a `ci-ok` over its matrix.

**MEDIUM — does individual listing drift in practice?** The evidence is mixed. I report both sides.

- **Not necessarily.** tokio's 46 required contexts and bevy's 24 were **all** reported on each project's most recently merged pull request (tokio PR #8458, head `fc283b11cd86`, 91 check runs; bevy PR #25707, head `84e857d27549`, 37 check runs). Neither list contained a stale entry. A single well-run repository can keep a long list in sync.
- **For a template it does drift.** py PROBLEM-15 is exactly this failure: documented contexts that do not exist in the generated repository, which blocks every pull request there. The same failure hit the blueprint's own PR #428.
- **The aggregate moves the list, it does not abolish it.** `ci-ok`'s `needs:` can drift too, as rust-analyzer shows. The difference is that it drifts *inside a reviewed file that a guard can check*. Branch-protection settings are admin-only state that no CI job can check without an admin token. py's 21-revision zero-drift record shows that the in-repo list stays in sync in practice.

**LOW — `merge_group`.** Nothing extra is needed in the aggregate. R11 already puts `merge_group` in `ci.yml`'s triggers and publishes `true` on every detector output for events other than `pull_request`, so nothing is skip-gated in the queue. `ci-ok` runs in the queue like any job. rust-analyzer's `merge_group` runs show its aggregate running there. Two conditions must hold:

- The queue's required check is the same context `ci-ok`.
- The name `ci-ok` must be unique across all workflow files. *About protected branches* warns: "make sure that job names are unique across all workflows. Using the same job name in multiple workflows can cause ambiguous status check results and block pull requests from being merged."

**Minimal realistic example.** The block below is the complete fixture I linted (`actionlint` 1.7.12 with `shellcheck` on `PATH`, exit 0; verification V1). Every job other than `ci-ok` is a skeleton of R11's graph with placeholder steps. R11 owns those jobs' real contents; R12 adds only the `ci-ok` job and the guard step inside `workflow-lint`. By R11's slot rule, the guard is a non-compiling check whose whole input, `.github/workflows/ci.yml`, is contained in the `workflows` key's pattern. It therefore belongs in `workflow-lint`, which runs whenever that file changes and on every push and `merge_group`.

<!-- r12-fixture-begin -->
```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]
  merge_group:
permissions: {}
concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.sha }}
  cancel-in-progress: true
jobs:
  plan:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    outputs:
      code: ${{ steps.detect.outputs.code }}
      web: ${{ steps.detect.outputs.web }}
      workflows: ${{ steps.detect.outputs.workflows }}
      docs: ${{ steps.detect.outputs.docs }}
    steps:
      - id: detect
        run: |
          for k in code web workflows docs; do echo "$k=true" >> "$GITHUB_OUTPUT"; done
  hygiene:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - run: echo "R11 hygiene steps"
  workflow-lint:
    needs: plan
    if: needs.plan.outputs.workflows == 'true'
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7
        with:
          persist-credentials: false
      - name: ci-ok folds in every other ci.yml job
        run: |
          set -euo pipefail
          yq -o=json '.jobs' .github/workflows/ci.yml | jq -e '
            (keys - ["ci-ok"]) as $jobs
            | (.["ci-ok"].needs | if type == "string" then [.] else . end) as $needs
            | if ($jobs - $needs) == [] and ($needs - $jobs) == [] then true
              else ("missing from ci-ok needs: \($jobs - $needs); unknown in needs: \($needs - $jobs)\n" | halt_error(1)) end' > /dev/null
  check:
    needs: plan
    if: needs.plan.outputs.code == 'true'
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    permissions:
      contents: read
    steps:
      - run: echo "R11 check steps"
  msrv-floor:
    needs: plan
    if: needs.plan.outputs.code == 'true'
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - run: echo "R11 msrv-floor steps"
  install-smoke:
    needs: plan
    if: needs.plan.outputs.code == 'true'
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - run: echo "R50 install-smoke steps"
  ci-ok:
    name: ci-ok
    needs: [plan, hygiene, workflow-lint, check, msrv-floor, install-smoke]
    if: ${{ always() }}
    runs-on: ubuntu-latest
    timeout-minutes: 5
    permissions: {}
    steps:
      - name: Fold every needed job's result into one required check
        env:
          NEEDS_JSON: ${{ toJSON(needs) }}
        run: |
          set -euo pipefail
          jq -r 'to_entries[] | "\(.key): \(.value.result)"' <<< "$NEEDS_JSON"
          if ! jq -e 'length > 0 and all(.[]; .result == "success" or .result == "skipped")' <<< "$NEEDS_JSON" > /dev/null; then
            echo "::error::ci-ok: a needed job ended failure or cancelled (or needs is empty)"
            exit 1
          fi
```
<!-- r12-fixture-end -->

How the example composes:

- `ci-ok` reads only `needs.<job>.result`, never `plan`'s outputs. R11's rule is that a consumer which opts out of skip propagation must read `plan`'s result.
- `ci-ok` carries no token (`permissions: {}`) and does no checkout.
- The guard adds no dependency: `yq` 4.53.6 and `jq` 1.7 ship on `ubuntu-latest`.
- A matrix job appears in `needs` as one entry, whose `result` is `failure` if any leg failed; `fail-fast: false` keeps the other legs reporting. alls-green's README confirms that per-leg results are not exposed.

**Executable acceptance check.** The check passes when all six hold:

1. `actionlint` accepts the file.
2. The guard exits 0 on the file.
3. The guard exits 1, naming the job, when a job is added, renamed or dropped from `needs:`.
4. The result rule yields the recommended column of the truth table above.
5. On GitHub, a forced `plan` failure leaves the pull request unmergeable.
6. A docs-only pull request is mergeable with the gated jobs `skipped`.

Items 1–4 were executed (V1–V4). Items 5–6 are proposed for P03 (V6–V7). See `### Validation strategy`.

### Dominant choice

**An in-workflow aggregate job, hand-rolled as a `jq` test over `toJSON(needs)`, required alone for its workflow and pinned to the GitHub Actions app.** It is dominant among the repositories maintained by the Rust project's own teams: cargo, rust-analyzer, clippy and rustup all require one `conclusion` context through a ruleset pinned to app 15368. It is dominant among the fastest-growing Rust tool repositories (uv, ruff). It is the form GitHub's troubleshooting page prescribes.

Two variations exist inside the dominant choice.

- **`if:` form.** `!cancelled()` is used by the rust-lang repositories; `always()` by rustup, uv, ruff, clap and py. Public run records show both safe (see `### Principles and implementation`).
- **Result rule.** All-`success` (cargo, clippy) fits workflows without skip-gating. `success`-or-`skipped` (rust-analyzer, uv, ruff, py) is required wherever jobs are conditionally skipped, which R11 does.

Individual listing is a real second practice (tokio, bevy, crates.io), not a fringe one. It is not dominant among projects whose CI uses a change detector, except crates.io.

### Options

| Option | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| **A. Aggregate job, hand-rolled `jq` allow-list (`success` or `skipped`), `plan` in `needs`, `always()`, completeness guard, source-pinned** | GitHub Docs *Troubleshooting required status checks*, "Use `always()` with `needs`" (`github/docs@18945a31`); cargo's inline rationale comment | rust-analyzer (same rule, `!cancelled()`), uv and ruff (same rule, `always()`, detector folded in); py (same rule as a bash deny-list) | GitHub Docs at `github/docs@18945a31`, committed 2026-09-25 |
| B. Aggregate job, all-`success` rule, `!cancelled()` | cargo `main.yml` comment ("ALL THE PREVIOUS JOBS NEED TO BE ADDED TO THE `needs` SECTION OF THIS JOB!") | `rust-lang/cargo`, `rust-lang/rust-clippy` | cargo `main.yml` @ `07b80494920f` |
| C. Aggregate job via `re-actors/alls-green` (`allowed-skips`, `allowed-failures`) | alls-green README and `action.yml` | aiohttp, attrs, pip-tools, setuptools, PyCA, pytest (per README; not independently verified) | alls-green `v1.3.0`, 2026-08-22 |
| D. Aggregate with `contains(needs.*.result, …)` in a step `if:` | community idiom | `clap-rs/clap` (tests failure, cancelled and skipped) | clap `ci.yml` @ `8ab46fe22b4a` |
| E. List every context individually | GitHub Docs *About protected branches* | `tokio-rs/tokio` (46), `bevyengine/bevy` (24), `rust-lang/crates.io` (5, ruleset, app-pinned); ts implicitly (it requires none) | *About protected branches* @ `18945a31` |
| F. Check-run poller across workflows | `poseidon/wait-for-status-checks` README ("polls the check runs for the head commit … until they all succeed or one fails"); `upsidr/merge-gatekeeper` README | not observed in any surveyed Rust project | wait-for-status-checks `v0.7.0`, 2026-07-29 |
| G. Organization ruleset "Require workflows to pass before merging" | *Available rules for rulesets* | organization-owned repositories only | *Available rules for rulesets* @ `18945a31` |

### Excluded by gate

The six fitness gates are written for crates in the template's dependency tree. Every candidate here is either a workflow pattern or a GitHub Action, and none enters `Cargo.toml`. The crate figures (crates.io downloads, RustSec pages, crate MSRV) are therefore **inapplicable**, because no crate exists to measure. The equivalent figures for the one third-party action on the shortlist are given instead.

**Option A (recommended, no third-party code) — passes; no gate excludes it.**

1. *License*: **inapplicable** — no third-party code. The snippet becomes the template's own `MIT OR Apache-2.0` content.
2. *MSRV*: **inapplicable** — no Rust is compiled; the job does not touch the toolchain.
3. *Advisories and `unsafe`*: **inapplicable** — no crate. Security posture: no checkout, `permissions: {}`, no secrets, and no expression interpolated into shell (results arrive through `env:`).
4. *OS*: runs on `ubuntu-latest` only. It needs no macOS leg, because it judges results rather than building; `jq` and `yq` are preinstalled on the Ubuntu 24.04 image. Windows is not needed.
5. *Default features and runtime coupling*: **inapplicable**; its only coupling is to GitHub's `needs` context.
6. *Binary size and compile time*: zero for the shipped artifacts. CI cost is one short job, observed at 3–4 seconds wall clock in uv's and clap's runs (`started_at` to `completed_at`), plus one `yq | jq` step in `workflow-lint`.

**Option C (`re-actors/alls-green`) — passes the gates; ranked runner-up.**

1. *License*: BSD-3-Clause (`GET /repos/re-actors/alls-green`, `license.spdx_id`). As a CI action it is executed, not distributed with the template's artifacts; BSD-3-Clause is in any case compatible with an `MIT OR Apache-2.0` project.
2. *MSRV*: **inapplicable** — a composite action running Python (`python -m normalize_needed_jobs_status`, `action.yml`), not a crate.
3. *Advisories*: no GitHub security advisory was checked for the repository — an evidence gap. `unsafe`: **inapplicable** (Python). It adds a third-party action, which R20's pinning policy must pin by SHA.
4. *OS*: a composite action needing Python 3 on the runner; `ubuntu-latest` ships Python 3.12.3.
5. *Coupling*: requires `jobs: ${{ toJSON(needs) }}` and the host job's `if: always()`. By default a skipped job counts as failure unless it is listed in `allowed-skips`.
6. *Size and compile*: zero for artifacts; a Python start-up in CI.
7. *Figures*: 173 stars; `archived: false`; `pushed_at` 2026-08-21T23:59:58Z; latest release `v1.3.0` on 2026-08-22T00:38:16Z; 7 open issues (`search/issues … is:open`, `total_count`).
8. *Responsiveness*: over the 10 most recently opened issues, 8 had a maintainer response, with a median of 0.36 days to the first maintainer comment. The 2 unanswered (#40, #30) were opened by a MEMBER, the maintainers' own tracking issues.
9. *Maintenance state*: **active**.

**Option F (pollers) — not excluded by a gate; rejected on design.**

- `poseidon/wait-for-status-checks`: MPL-2.0, 60 stars, `v0.7.0` 2026-07-29, 5 open issues.
- `upsidr/merge-gatekeeper`: MIT, 140 stars, last release `v1.2.1` on 2023-02-03 while `pushed_at` is 2026-09-25. No release in over three years is a trigger to investigate, and pushes continue, so I classify it **stable-quiet** rather than at-risk.
- `lewagon/wait-on-check-action`: MIT, 396 stars, `v1.9.1` 2026-08-09.

All three need a token with read access to checks, poll the API while holding a runner, and count every check on the commit rather than a reviewed set. Gate 5 applies in spirit: they couple the gate to API availability and token scope, which conflicts with R08's empty-permissions posture. MPL-2.0 would need review only if the code were vendored.

**Option G** is not a candidate the template can ship. It exists only in organization settings, and a template cannot assume its adopter is an organization.

**Options B, D and E** share Option A's gate answers exactly: each is a workflow pattern or a settings choice, no third-party code enters the template, and the only runner dependency is `jq` or GitHub's expression engine. Option E adds no job at all.

**Excluded outright: none.** No candidate fails a gate; B, D, E, F and G are ranked below A on design grounds under `### Tradeoffs`.

### Up-and-comers

- **Static completeness guards.** No maintained tool asserts that an aggregate's `needs:` covers its workflow. `actionlint` type-checks `needs:` references but, as V2 shows, accepts an aggregate missing `always()`. It does not compare the job set against the aggregate. zizmor (R20's tool) audits security rather than graph completeness. The inline `yq | jq` guard in the example fills the gap. A future `actionlint` or zizmor rule for either check would replace it.
- **Check-run pollers** (`wait-for-status-checks`, `merge-gatekeeper`) are the up-and-coming answer to cross-workflow gating. They become attractive if the template grows several gating workflows that cannot share one `ci.yml`.
- **Rulesets as the configuration surface.** Every rust-lang repository surveyed and uv configure the required check through a ruleset with `integration_id` 15368 rather than through classic protection. Rulesets can also be declared at organization level, which is where a shared `ci-ok` name pays off.

### Fit for this template

All three shapes share one `ci.yml` (R11), so the aggregate is identical for all of them. The shapes differ in which failure the aggregate must not hide.

- **CLI.** The CLI's installability is proven by `install-smoke` (R50), a gated job. A failed `plan` would skip it and, without an aggregate that folds in `plan`, report green: T3 is precisely the case of a CLI that no longer installs yet merges. `ci-ok` makes that impossible. The CLI's release workflow is a separate file (R68) that runs on tags, not on pull requests, so it is correctly outside `ci-ok`.
- **Library.** The library's contract is proven across `target-os-matrix` by the `check` matrix, plus `msrv-floor`. Listing individually would bake `check (ubuntu-latest)` and `check (macos-latest)` into settings, and the owner-fixed matrix or the F033 cross-product question (R11 re-verify list) can change those names. `ci-ok` folds the matrix into one entry. If R04's semver job arrives as its own job (R11 names that slot), the guard fails until it is added to `needs:`, so the library's API gate cannot be silently optional.
- **Web service.** The web surface is proven by `check`'s feature-on steps and `install-smoke`'s web leg, a *step* conditioned on the `web` output rather than a separate job. So no web-only context exists to list or to forget. The aggregate needs no web-specific handling. If a future web job (for example, R83 contract fuzzing inside `ci.yml`) is added, the guard forces it into `needs:`.

Against the py and ts precedent: rs matches py's architecture and fixes py's two weaknesses, the deny-list and the unguarded `needs:`. It supplies the capability ts lacks.

### Recommendation

Adopt **Option A**.

1. **Add `ci-ok` to `.github/workflows/ci.yml`**, exactly as in the example.
   - `name: ci-ok`, unique across all workflow files.
   - `needs:` lists every other job in the file, `plan` first.
   - `if: ${{ always() }}`, `timeout-minutes: 5`, `permissions: {}`, `runs-on: ubuntu-latest`, and no checkout.
   - One step that prints each needed result and fails unless `needs` is non-empty and every result is `success` or `skipped`.
2. **Add the completeness guard as a step of R11's `workflow-lint` job.** It fails when the job set of `ci.yml` minus `ci-ok` differs from `ci-ok`'s `needs:` in either direction.
3. **Require exactly `ci-ok` for `ci.yml`**, through a repository ruleset on the default branch, with `integration_id: 15368` (GitHub Actions) as the expected source. The template cannot set this, so it ships as documentation (see `### Migration implications`).
4. **One aggregate per gating workflow.** Any other workflow file whose checks must block merging, for example R17's secret scanner or R38's commit-message lint if they are required, gets either its own single-context requirement or its own `<name>-ok` aggregate. `needs:` cannot cross files, and this is clippy's four-`conclusion_*` pattern.
5. **Agreement across repositories.** Keep the context name `ci-ok` shared with py, and propose the same for ts, so one organization ruleset can require it everywhere.

This satisfies R11's hand-over in full:

- `plan` is in `needs:`.
- `failure` or `cancelled` of `plan` (or of any job) fails `ci-ok`.
- `skipped` passes only because R11's detector fails closed and `plan`'s own failure is folded in.
- `ci-ok` reads `needs.*.result`, never `plan`'s outputs.
- It carries `always()` as R11's row specifies.

### Ranked runner-up

**Option C — the same aggregate job computed by `re-actors/alls-green`**, with `allowed-skips: workflow-lint, check, msrv-floor, install-smoke`. It **wins** if any of these conditions arises:

1. The template acquires **non-voting jobs**, meaning jobs allowed to fail. Examples are a nightly-toolchain leg or an experimental job; `allowed-failures` expresses this declaratively, where the `jq` rule would need editing.
2. The owner wants **skips allowed only for named jobs**. That tightens P3 further: an ungated job that is somehow skipped would then fail, at the cost of a second list to keep in sync.
3. Several blueprint repositories want **one maintained implementation** rather than a copied line.

Second runner-up: **Option E, individual listing**. It wins only if R11 collapsed to one non-matrix job *and* the template could ship its ruleset as code into generated repositories. Neither holds.

### Tradeoffs

- **Versus C (alls-green).**
  - *Given up:* declarative allowed-failures and allowed-skips, a maintained implementation with its own tests, and nicer log output.
  - *Accepted because:* A adds no third-party action. That means no SHA pin to maintain under R20, no Python start-up, and no supply-chain surface in the job that gates every merge. The `jq` line is 1 line, the same form the rust-lang teams use. The completeness risk that matters, a job missing from `needs:`, is identical under both and is closed by the guard, not by the action.
- **Versus B (`!cancelled()`, all-`success`).**
  - *Given up:* `!cancelled()` saves a few runner-seconds on each superseded run, and leaves a grey `cancelled` rather than a red `failure` on stale commits.
  - *Accepted because:* R11's row prescribes `always()`, GitHub's required-check page prescribes it, and py uses it. The observed safety of `!cancelled()` (12 of 12 runs concluded `cancelled`) makes it an acceptable substitute, not a defect. The all-`success` rule is wrong for R11's graph, because a docs-only pull request would fail (T2).
- **Versus E (individual listing).**
  - *Given up:* the ability to require only a subset of jobs without editing `ci.yml` (tokio requires 46 of 91 check runs), and per-context visibility in the merge box. `ci-ok`'s log prints every result, which only partly compensates.
  - *Accepted because:* seven changing context names, admin-only state, and PROBLEM-15-class breakage in generated repositories cost more.
- **Versus F (poller).**
  - *Given up:* automatic coverage of checks in other workflow files.
  - *Accepted because:* a poller needs a read token, holds a runner while polling, depends on API availability, and gates on whatever ran rather than on a reviewed set. One stable context per gating workflow is cheaper.
- **Residual risk accepted.** A skip caused by a *wrong* detector decision (fail-open) still passes `ci-ok`. That risk is R11's to prevent, and R11 prevents it structurally with fail-closed skip-lists. The aggregate cannot distinguish a correct skip from an incorrect one.

### Parameters

This item owns no parameter. No `CONFLICT:` line: the recommendation fits every consumed value unchanged.

- assumes rust-edition = 2024
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes license = MIT OR Apache-2.0
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes ci-job-structure = one .github/workflows/ci.yml whose jobs are partitioned by whether a check compiles Rust, never by which check it is. Tier 0 is a single always-run detector job named plan on ubuntu-latest carrying no toolchain, no cache action and no target/ directory: after actions/checkout with fetch-depth 0 and persist-credentials false it runs one bash step under set -euo pipefail that computes git diff --no-ext-diff --no-textconv --no-renames --name-only from BASE_SHA to HEAD, so the path list includes the source side of every rename, with BASE_SHA read from github.event.pull_request.base.sha through the step env block, treats every file name as data and never evaluates it, and writes exactly four job outputs - code, web, workflows, docs - as the literal strings true or false and never as any other value, publishing true on all four for every event whose name is not pull_request so that pushes to main and merge-queue entries are never skip-gated. Every output that gates a required check fails closed, whether the check compiles or not, so a path nobody anticipated runs the gate rather than skipping it, and the body makes that structural - code and web start true and are set false only on affirmative proof that every changed path is skippable, a grep exit of 1, never on a match, an error or a test cut short, and workflows and docs likewise start true and are set false only on a grep exit of 1, and every path test reads the whole list from a here-string rather than through a pipeline whose early-exiting grep can end it under pipefail: code is the negation of a skip-list of paths that cannot affect a compile, a package or an installed artifact, with every entry of the package include allow-list R49 owns forced non-skippable because each of them is a packaging input, and with no skip-list entry allowed to match a file any package contains - so the Markdown entry matches only root-level files. Markdown under docs/ and .github/ISSUE_TEMPLATE/ stays skippable through those directory entries, and no entry matches anything under src/ or a member directory, because src/ is packaged and a workspace member that names no include list packages its whole directory; web is fail-closed too - every change that sets code also sets web, because the web member depends on the core member and the root package that hosts the serve binary depends on every member, and web is additionally set by any change under the web member's directory, so the paths R69 names are a subset of the rule rather than its whole; workflows gates only workflow-lint and its pattern contains the whole input of every check in that job by construction - the workflow files, the local actions they call, which live under .github/actions/, and the workflow linter's own config file; docs keys on the prose tree and gates no job in this file, because R82's link check is a step of hygiene, so it is kept only as a literal output that no check whose input another item declares may consume; and a fifth key is added only when some job would be skipped by it that code does not already skip, and is itself written as the negation of a skip-list, or, if it gates only a job that compiles nothing, as a pattern containing that job's whole input. Tier 1 is the checks that compile nothing, each its own cheap job carrying no cache step: hygiene, which deliberately has no needs edge so that a formatter failure still reports on a pull request whose compile tier is skipped, and which hosts every non-compiling check whose input no key contains, R29's non-code formatting slot and R20's two action-pin checks included, as is R82's link check, while R82's rustdoc part is the doc build step of check; and workflow-lint, gated on workflows, which hosts only checks whose whole input is the workflow tree. Tier 2 is the checks that compile: ONE job named check per entry of target-os-matrix through a strategy matrix over os alone with fail-fast false - never a matrix dimension over Cargo features, because the cache action keys on the job id and not on matrix values - running clippy with the feature off, clippy with the feature on, a no-default-features check of the facade, cargo test with the feature off scoped by -p to the non-web packages so the feature-off property is proven rather than assumed, cargo test over the workspace with the feature on, a build of the serve binary and a doc build, as ordered steps sharing one target/, every cargo command carrying --locked, where each cargo step runs under !cancelled() so that one failing step does not hide the results of the steps after it; plus msrv-floor, a separate single-runner job rather than a matrix leg of check because the floor needs only the declared-floor check Cargo's own CI guide shows rather than check's whole step list, verifying the declared rust-version on ubuntu-latest, which widens to every runner by substituting the matrix os expression into runs-on if the owner answers the open F033 cross-product question that way; plus install-smoke, R50's one ubuntu-latest job, whose web leg is a step conditioned on the web output. Every gated job consumes the detector through needs: plan and a POSITIVE predicate of the form needs.plan.outputs.KEY == 'true', never a negated one, and carrying no status function, so that the platform's implicit success() skips every gated job whenever plan fails or is skipped, under either polarity; the positive form is kept for consistency with R18, R86 and the dorny/paths-filter example, because the one remaining empty-key case, a misspelled output name, is caught by lint on the consumer side and by the detector cases on the producer side, and because a consumer that opts out of skip propagation with always() or !cancelled() must read plan's result, never plan's outputs, as its condition; actionlint type-checks the output name and the needs edge but does NOT reject the negated form, so that rule travels in prose to every consumer rather than being left to lint. A failed plan skips every gated job and skipped is a successful check status, so a failed plan must itself fail a required check; this file hands that constraint on without deciding how it is met: either plan is itself a required check, or an aggregate, if R12 chooses one, includes plan in its needs and treats a failure or cancelled result of plan as failure. ci.yml carries no trigger-level paths or paths-ignore filter of any kind, because a workflow skipped by path filtering leaves its checks Pending and blocks merging while a job skipped by a conditional reports Success; its triggers are pull_request and push restricted to main, plus merge_group so a queue's speculative merge still reports; it declares an empty workflow-level permissions map with a per-job re-grant whose scopes are R08's; and it declares workflow-level concurrency with cancel-in-progress true on a group keyed to the workflow plus the pull-request number, falling back to the commit sha when there is no pull request, so a force-push cancels the superseded pull-request run while consecutive pushes to main never cancel one another and keep populating the cache. This file holds no aggregate required-status job, which is R12's, and no release, secret-scanning, devcontainer or AI-review job, which are separate workflow files. Every further check arrives as a named slot under one rule: a check that compiles nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's key contains the whole input of every check in the job; a check that compiles what check already compiles is an ordered step of check; and a check needing its own toolchain, its own runner or a target/ it must not share becomes its own job with needs: plan and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner, where the budget arithmetic is the sum over cache-bearing job ids of that job id's runner count. Any single-job workflow file that compiles no Rust, R17's scanner included, lands on ubuntu-latest, because it neither shares nor claims a target/ cache entry and gains nothing from a second runner

### Migration implications

File-level changes in `rs-launch-blueprint`. No Rust code, `Cargo.toml` or `Cargo.lock` change.

| File | Change | Owner of the surrounding content |
|---|---|---|
| `.github/workflows/ci.yml` | add the `ci-ok` job (about 20 lines) exactly as in the example | R12; the rest of the file is R11's |
| `.github/workflows/ci.yml`, job `workflow-lint` | add the step `ci-ok folds in every other ci.yml job` (the `yq \| jq` guard) after checkout | step is R12's; job is R11's |
| repository setup documentation (the POST_INIT-equivalent page; file name owned by the docs items, R81) | a "Required checks" section. It names `ci-ok` as the only required context for `ci.yml`, source GitHub Actions (app 15368). It lists any other gating workflow's single context. It states that the list must name only checks that exist in the generated repository (py PROBLEM-15), and it gives the ruleset command below | R12 content; R81 placement |
| `CONTRIBUTING`-equivalent | one sentence: a new `ci.yml` job must be added to `ci-ok`'s `needs:`, and CI enforces this | R12 content |
| other workflow files (R17, R38, R13 and others) | each item that makes its workflow merge-blocking declares its one required context, or its own `<name>-ok` aggregate if it has several jobs | those items |

Ruleset command for the documentation (**proposed, not executed**, because it mutates live repository state):

```bash
gh api -X POST "repos/<owner>/<repo>/rulesets" --input - <<'JSON'
{
  "name": "main: required ci-ok",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "rules": [
    { "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [ { "context": "ci-ok", "integration_id": 15368 } ] } }
  ]
}
JSON
```

`<owner>/<repo>` is the generated repository's slug. `strict_required_status_checks_policy: false` mirrors py's live `strict: false`. Whether branches must be up to date is not this item's decision.

**py and ts follow-on (rationale only; no change made here).**

- **py:** change the `ci-ok` result test to the positive allow-list plus `length > 0`; add the guard; fold `lint.yml`'s five individually required jobs behind a `lint-ok` aggregate.
- **ts:** add required status checks at all; add `merge_group` (F025); add `ci-ok` over the `node-version` matrix.

### Validation strategy

Local checks run on macOS 26 (`Darwin 25.4.0`, arm64) with GNU bash 5.3.20, jq 1.8.2, PyYAML 6.0.3, actionlint 1.7.12 and shellcheck on `PATH`. No GitHub Actions job ran. Fixtures were passed through stdin or here-strings, not written into the repository.

| ID | Status | Command (working directory: repository root) | Expected | Observed |
|---|---|---|---|---|
| V1 | **executed** | `awk '/^<!-- r12-fixture-begin -->$/{f=1;next} /^<!-- r12-fixture-end -->$/{f=0} f' research/runs/R12/2026-09-26T190134Z-d0c66b769758/raw/opus.md \| sed '1d;$d' \| actionlint -` | exit 0 | exit 0, run against this file's 94-line fixture block (sha256 `fec9c59169fe4c5064b298dee36c76c29b9e9a0ac7f27117fa8df21c83e77742`) after the final edit; the V4 guard program also exits 0 on that block |
| V2 | **executed** | V1 with the line `    if: ${{ always() }}` deleted | a lint that caught the trap would exit 1 | **exit 0** — `actionlint` does not catch an aggregate missing `always()`; the `if:` line needs review, not lint |
| V3 | **executed** | the four result rules over T1–T9 via `jq -e` under `bash` (table in `### Principles and implementation`) | recommended rule passes only T1 and T2 | as expected; py's deny-list passes T8 and T9, cargo's fails T2, the naive rule passes T4, T6, T8 and T9 |
| V4 | **executed** | the guard's `jq` program, extracted from the fixture's `workflow-lint` step, over the fixture's job graph converted by PyYAML: G1 the fixture unchanged; G2 `semver-checks` added, `needs` not updated; G3 `plan` dropped from `needs`; G4 `check` renamed to `build` | G1 exit 0; G2–G4 exit 1 naming the jobs | G1 exit 0; G2 `missing from ci-ok needs: ["semver-checks"]` exit 1; G3 `missing … ["plan"]` exit 1; G4 `missing … ["build"]; unknown in needs: ["check"]` exit 1 |
| V5 | **executed** (public data) | `GET /repos/<o>/<r>/actions/workflows/<wf>/runs?status=cancelled` then `/actions/runs/<id>/jobs` | observe the aggregate's conclusion in cancelled runs | cargo 6 of 6 and rust-analyzer 6 of 6 (`!cancelled()`): `cancelled`; uv 6 runs (`always()`): ran, 4 `success` and 2 `failure`; clap 4 runs (`always()`): ran, 2 `success` and 2 `failure` |
| V6 | **planned (P03)** | on a throwaway pull request, make `plan` fail (for example, an unreachable `BASE_SHA`) | `plan` `failure`, gated jobs `skipped`, `ci-ok` `failure`, pull request unmergeable | — (R11 criterion 13) |
| V7 | **planned (P03)** | a docs-only pull request | gated jobs `skipped`, `ci-ok` `success`, mergeable | — |
| V8 | **planned (P03)** | cancel the head run of a pull request by hand | `ci-ok` concludes `failure` (under `always()`); the pull request stays unmergeable until a re-run | — |
| V9 | **planned (P03)** | enqueue the pull request in a merge queue | `ci.yml` runs on `merge_group`; `ci-ok` reports on the group commit; the queue merges | — |
| V10 | **planned (P03)** | post a commit status named `ci-ok` with state `success` using a personal token (`POST /repos/<o>/<r>/statuses/<sha>`) while a job fails | merge still blocked, because the ruleset pins app 15368 | — |
| V11 | **planned (P03)** | add a job to `ci.yml` without adding it to `needs:` | `workflow-lint` fails on the guard step | — (V4 is the local proxy) |

Distinction stated plainly: V1–V4 execute the proposed configuration's logic. `yq` was not available locally, so V4 used PyYAML for the YAML-to-JSON conversion and the identical `jq` program. The runner form uses `yq` 4.53.6 as shipped on `ubuntu-latest`. V5 is observed platform behavior in other projects, not a run of this configuration. V6–V11 need a GitHub repository with the ruleset, which does not exist yet.

### Confidence & re-verify trigger

**High confidence in the architecture (aggregate over individual listing) and in the result rule.** Four independent lines agree:

1. GitHub's own troubleshooting page.
2. The Rust project teams' live rulesets (four repositories, all single-aggregate, app-pinned).
3. py's 21-revision record together with its PROBLEM-15 failure under individual listing.
4. The executed truth table and guard tests.

**Medium confidence on `always()` versus `!cancelled()`.** Both are shown safe on public runs (V5), but on 22 runs only, and none of them was a hand-cancelled head run of an open pull request (V8 covers that). The choice follows R11's row and cross-repo agreement, not a proven difference.

**Evidence gaps.**

1. Whether tokio's and bevy's 46- and 24-entry lists *ever* drifted historically; I checked one merged pull request each, not their settings history, which is not public.
2. alls-green's adopter list is taken from its README and was not verified per adopter.
3. No GitHub security-advisory query was run for the three third-party actions.
4. R11's own fixture `ci.yml` is embedded in archive logs; I linted a skeleton of its graph rather than R11's fixture file.
5. Which checks serde, ripgrep, axum and nextest require was not queried.

**Re-verify triggers.**

1. **R11 publishes a new revision** that adds, renames or removes a `ci.yml` job, or changes the detector's name or failure semantics. The guard catches the job-set change mechanically; the R11 hand-over text needs re-reading.
2. **GitHub changes the required-status treatment of `skipped`** (for example, stops counting it as success), or adds a native "all jobs in workflow" requirement, or a `needs: '*'` wildcard. Either would replace or simplify Option A.
3. **`actionlint` or zizmor ships a rule** that checks aggregate completeness or a missing `always()`. The inline guard would then give way to the tool.
4. **A second gating workflow is added** to the template (R17, R38, R13 or R86 making its workflow merge-blocking). That reopens whether a poller (Option F) or a per-workflow aggregate is cheaper.
5. **The owner accepts `BASELINE-REVIEW: F041`**, which triggers the py and ts follow-on.
6. **P03's V6–V10 contradict this report**, especially V8: a hand-cancelled run leaving `ci-ok` green.
7. **Calendar: 6 months (by 2027-03-26).**

### Sources

Every URL below was retrieved on **2026-09-26**.

*GitHub platform documentation* — all fetched through `GET https://api.github.com/repos/github/docs/contents/<path>?ref=18945a31a4f2d97beb6c5c1a7479102e23c25727`; that commit is dated 2026-09-25T23:28:57Z.

- `content/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks.md`. Quoted: "Successful check statuses are `success`, `skipped`, and `neutral`." The skipped-checks table: "A job is skipped by a conditional — The job reports 'Success'"; "A job depends on a failed job — The dependent job is skipped and may not block merging — Use `always()` with `needs` for required checks that depend on other jobs"; a workflow skipped by path, branch or commit-message filtering leaves checks "Pending" and blocks merging. Also: "If a merge queue requires a GitHub Actions check, trigger the workflow with the `merge_group` event"; and "Required status check 'build' was not set by the expected GitHub App."
- `content/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches.md`. Line 31: "make sure that job names are unique across all workflows. Using the same job name in multiple workflows can cause ambiguous status check results". Line 95: required checks must be `successful`, `skipped` or `neutral`. Line 101: "Any person or integration with write permissions to a repository can set the state of any status check … you can select an app … as the expected source".
- `content/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets.md`. Lines 172–186: required status checks in rulesets, expected-source app, and organization-level status checks. Lines 270–282: "Require workflows to pass before merging", configured "in your organization settings". Merge-queue settings including "Status check timeout".
- `content/pull-requests/reference/status-checks.md`. `skipped`: "treated as a success for dependent checks"; GitHub Actions "generates checks, not commit statuses".
- `data/reusables/actions/workflows/skipped-job-status-checks-passing.md`: "A job that is skipped will report its status as 'Success'. It will not prevent a pull request from merging, even if it is a required check."
- `data/reusables/actions/merge-group-event-with-required-checks.md`: "you need to update the workflows to include the `merge_group` event … Otherwise, status checks will not be triggered when you add a pull request to a merge queue."
- `data/reusables/actions/jobs/section-using-jobs-in-a-workflow-needs.md`: "If a job fails or is skipped, all jobs that need it are skipped unless the jobs use a conditional expression that causes the job to continue … use the `always()` conditional expression". `needs` is "a string or array of strings", with no wildcard form.
- `content/actions/reference/workflows-and-actions/expressions.md`, lines 339–360. `always()` "returns `true`, even when canceled"; the warning to avoid `always` for tasks that could hang, and "use the recommended alternative: `if: ${{ !cancelled() }}`".
- GitHub Actions app identity: `GET https://api.github.com/apps/github-actions` returned `id` 15368, slug `github-actions`.
- Runner image: `GET https://api.github.com/repos/actions/runner-images/contents/images/ubuntu/Ubuntu2404-Readme.md` (repository head `ede07f8e4802`, 2026-09-25). Image Version 20260920.314.1; `jq 1.7`; `yq 4.53.6`; `Python 3.12.3`.

*Rust practice survey* — workflow files: `GET https://api.github.com/repos/<o>/<r>/contents/<path>` (raw media type), default branch, about 19:55Z:

- `rust-lang/cargo` `.github/workflows/main.yml` (`conclusion`, lines 23–54, including the rationale comment quoted above);
- `rust-lang/rust-analyzer` `.github/workflows/ci.yaml` (lines 1–2 header note; `conclusion` lines 333–361; `typescript` gated on `needs.changes.outputs.typescript`);
- `rust-lang/rust-clippy` `.github/workflows/clippy_mq.yml` (lines 249–266) and `clippy_pr.yml` (lines 117–136);
- `rust-lang/rustup` `.github/workflows/ci.yaml`;
- `clap-rs/clap` `.github/workflows/ci.yml` (lines 24–34);
- `astral-sh/uv` `.github/workflows/ci.yml` (lines 305–340);
- `astral-sh/ruff` `.github/workflows/ci.yaml` (lines 1485–1512);
- `tokio-rs/tokio` `.github/workflows/ci.yml`; `bevyengine/bevy` `.github/workflows/ci.yml`; `rust-lang/crates.io` `.github/workflows/ci.yml`; `rust-lang/rust` `.github/workflows/ci.yml`; `serde-rs/serde`, `BurntSushi/ripgrep`, `nextest-rs/nextest` `.github/workflows/ci.yml`; `tokio-rs/axum` `.github/workflows/CI.yml`.

*Rust practice survey* — figures and settings:

- Standing: `GET https://api.github.com/repos/<o>/<r>` (`stargazers_count`, `archived`, `pushed_at`) and `GET …/commits/<default-branch>` (head sha), about 20:10Z. Values are in the Landscape table.
- Required checks: `GET https://api.github.com/repos/<o>/<r>/rules/branches/<branch>` (ruleset `required_status_checks` with `integration_id`) and `GET …/branches/<branch>` (`protection.required_status_checks.contexts`), for cargo, rust-analyzer, rust-clippy, rustup, clap, uv, ruff, tokio, crates.io and bevy.
- List-sync check: tokio PR #8458 (head `fc283b11cd860fb5f4b81d0772b0e5b3dbea754c`, merged 2026-09-26T14:08:55Z) and bevy PR #25707 (head `84e857d2754930513fc157966a67ebbdef0bf17e`, merged 2026-09-16T18:48:13Z). Source: `GET …/pulls?state=closed&sort=updated`, then `GET …/commits/<sha>/check-runs` (paginated). Every required context was present among the check runs.
- Cancelled-run behavior: `GET …/actions/workflows/<wf>/runs?status=cancelled&per_page=6` and `GET …/actions/runs/<id>/jobs?filter=latest`. Runs inspected:
  - cargo: 36211359945, 36186119787, 36183904844, 36183506670, 36182034101, 36181539786;
  - rust-analyzer: 36102953267, 36071821206 (`merge_group`), 36071658769 (`merge_group`), 35702376247, 35658045721, 35468094730;
  - uv: 36257666283, 36256624640, 36218303754, 36207477490, 36205911380, 36187663294;
  - clap: 34995417752, 34881899239, 34880059495, 34734039186.

*Aggregator and poller actions*

- `re-actors/alls-green`: `GET https://api.github.com/repos/re-actors/alls-green` (173 stars, BSD-3-Clause, `archived` false, `pushed_at` 2026-08-21T23:59:58Z, default branch `unstable/v1`); `/releases/latest` (`v1.3.0`, 2026-08-22T00:38:16Z); `GET /search/issues?q=repo:re-actors/alls-green+is:issue+is:open` (`total_count` 7); `README.md`, `action.yml` and `src/normalize_needed_jobs_status.py` via `/contents`. Quoted: "in case when something fails, the `check` job's result is set to `skipped` and not `failed` as one would expect"; "it is a must to have the job always run, otherwise GitHub will make it `skipped` when any of the dependencies fail. In some contexts, `skipped` is interpreted as `success`"; the origin note that GitHub's auto-merge "merges Dependabot PRs that are broken despite having branch protection enabled in the aiohttp repository". Responsiveness: `GET …/issues?state=all&sort=created&direction=desc` and `…/issues/<n>/comments` for #40, #39, #35, #34, #32, #31, #30, #29, #28 and #26.
- `upsidr/merge-gatekeeper`: 140 stars, MIT, `pushed_at` 2026-09-25T05:37:20Z, latest release `v1.2.1` 2023-02-03T22:02:08Z, 20 open issues; README (mechanism: "check all other CI jobs that get kicked off").
- `poseidon/wait-for-status-checks`: 60 stars, MPL-2.0, `pushed_at` 2026-09-26T11:03:58Z, `v0.7.0` 2026-07-29T20:39:51Z, 5 open issues; README ("polls the check runs for the head commit of a Pull Request until they all succeed or one fails").
- `lewagon/wait-on-check-action`: 396 stars, MIT, `pushed_at` 2026-08-09T18:22:35Z, `v1.9.1` 2026-08-09T18:21:06Z, 19 open issues.

*Source repositories, ledger and consumed decision*

- `~/c/py-launch-blueprint` @ `b08bccfb55d05f15e46a83b52c5660b1881d19f5` (task pin): `.github/workflows/ci.yml:1-25` (header, triggers including `merge_group`, `permissions: {}`), `:264-295` (`ci-ok`); `docs/POST_INIT.md:158-167,270-290` (required-check guidance and the protection command); `docs/source/about/design_decisions.md:479-485`; `docs/research/0002-dev-tooling-wishlist.md:60,88,136` (WL-006, WL-019); `docs/research/0004-template-press-dogfood-log.md:237-260` (PROBLEM-15); `docs/adr/0014-repo-simplification-batch.md:84-93`. HEAD `b55b8c26364cb0f42e56116e6780921976334751` for the ten-job `ci-ok`. The history audit covered all 35 commits touching `ci.yml`, 21 of them containing `ci-ok`.
- `~/c/ts-launch-blueprint` @ `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`: `.github/workflows/ci.yml:28-52` (triggers without `merge_group`; single job `ci`, name `continuous-integration`, `node-version` matrix).
- Live settings, read with the owner's `gh` token: `GET /repos/smorinlabs/py-launch-blueprint/branches/main/protection` (8 contexts, each `app_id` 15368, `strict` false); `GET /repos/smorinlabs/ts-launch-blueprint/branches/main/protection` (`404 Branch not protected`); `GET /repos/smorinlabs/ts-launch-blueprint/rulesets` (only the organization ruleset `merge-methods: no squash`); `GET /repos/smorinlabs/ts-launch-blueprint/rules/branches/main` (no `required_status_checks` rule).
- `docs/port/COMMONALITY.md:31` (F025), `:44` (F038), `:46` (F040), `:47` (F041); `docs/port/areas/ci-workflows.md:37` (F041 detail).
- `research/topics/11-ci-workflow-job-structure/DECISION.md`: lines 100, 178, 180 and 283 (the R12 hand-over row), and line 320 (owned value); the value is also in `research/runs/R12/2026-09-26T190134Z-d0c66b769758/inputs/parameters.json`.
- `research/runs/R12/2026-09-26T190134Z-d0c66b769758/inputs/prompt.md` (identical to the topic prompt; verified with `diff`).

**Method notes.**

- Endpoints queried:
  - `https://api.github.com` only: `repos/<o>/<r>`, `/contents`, `/commits`, `/releases/latest`, `/issues`, `/issues/<n>/comments`, `/pulls`, `/commits/<sha>/check-runs`, `/actions/workflows/<wf>/runs`, `/actions/runs/<id>/jobs`, `/branches/<b>`, `/branches/<b>/protection`, `/rules/branches/<b>` and `/rulesets`;
  - `search/issues` and `search/code`;
  - `apps/github-actions`.
- crates.io and rustsec.org were not queried, because no crate is a candidate.
- Two `search/code` calls hit GitHub's secondary rate limit (HTTP 403). After that, known paths were fetched directly; core quota was never exhausted.
- The tool shell is zsh, which does not word-split unquoted variables. My first run of the py-rule emulation therefore mis-reported. Every table above comes from reruns under `bash`, which is what GitHub runners use.
- Fetched workflow files, READMEs and GitHub docs were cached as scratch copies under `/tmp/r12/`, outside the repository. That directory is scratch, not evidence of record; every figure above names its endpoint. No file in the repository other than this report was written.

**Could not verify.**

1. Whether tokio's and bevy's required-context lists drifted at any earlier time.
2. alls-green's claimed adopters, individually.
3. GitHub security advisories for the four actions named.
4. The behavior in V6–V11 on a live repository.
5. The required checks of serde, ripgrep, axum and nextest.
6. `rust-lang/rust`'s merge gating, which runs through an external merge bot. I did not analyze it beyond noting that its `ci.yml` has no aggregate job.
7. The fixture's `actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7` pin was copied from py HEAD's `publish-container.yml` and bevy's `ci.yml` (`# v7.0.1`). I did not resolve the `v7` tag to that commit here; R20's pinning rule governs the real value.
8. Whether ruff, clap, tokio and bevy pin their required checks to an app, because classic protection does not expose `app_id` publicly.
9. The contents of clippy's two workflow files behind `conclusion_changelog` and `conclusion_remark`.
