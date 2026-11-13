### Landscape

This item selects a GitHub Actions event policy for a contributors-list pull-request workflow. It does not select a Rust crate: the inherited `smorinlabs/contributors-please-action` action is outside R07. Therefore crate download, release, RustSec, MSRV, dependency-tree, `unsafe`, feature, binary-size, and compile-time figures are **inapplicable** to every candidate. The policy adds no Rust dependency and does not execute Rust code; its operating-system fitness is GitHub-hosted workflow compatibility, not a crate platform claim.

| Field bin | Candidates found | Why they are candidates |
|---|---|---|
| Built-in or first-party toolchain | `push` with `branches` and `paths-ignore`; `schedule`; `workflow_dispatch` | GitHub Actions documents all three as native workflow events and filters. [GitHub Actions workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), retrieved 2026-09-05. |
| Established industry standard | Scheduled, non-gating maintenance automation with an on-demand manual override | This separates a freshness task from merge validation, while an operator can run it immediately. GitHub Actions documents `schedule` and `workflow_dispatch`; the TypeScript precedent implements this combination. [GitHub Actions events](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#schedule), retrieved 2026-09-05; [pinned source ledger](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/ci-workflows.md), retrieved 2026-09-05. |
| Up-and-comer | An external scheduler or a separate `workflow_run` dispatcher that starts this workflow after CI | These add a service or a second workflow without reducing the contributors action's work. No Rust-specific advantage or maintained reference implementation was found; exclude them from the shortlist. GitHub documents `workflow_run` as a separate event, not a cadence primitive. [GitHub Actions events](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#workflow_run), retrieved 2026-09-05. |

The authorities are GitHub's Actions reference, which defines the event semantics; the pinned py and ts workflow evidence, which establishes the actual alternatives; and a maintained Rust project workflow, which establishes that `schedule` plus `workflow_dispatch` is ordinary GitHub Actions practice in a prominent Rust project. `serde-rs/serde` is a relevant production Rust reference: its GitHub endpoint reported 10,800 stars, `archived: false`, and `pushed_at: 2026-08-25T03:53:14Z`; its CI workflow has both `workflow_dispatch` and a daily cron. The stars and maintenance figures come from [the repository endpoint](https://api.github.com/repos/serde-rs/serde), retrieved 2026-09-05; the workflow evidence comes from [Serde CI](https://github.com/serde-rs/serde/blob/master/.github/workflows/ci.yml), retrieved 2026-09-05. Serde's workflow is evidence that the mechanism is established, not evidence that a contributors task should run daily.

The source precedents are materially different. The pinned Python workflow uses `push` to `main`, ignores `CONTRIBUTORS.md` and `.contributors.jsonl`, and retains `workflow_dispatch`. [Python workflow at `b08bccf`](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccf/.github/workflows/update-contributors.yml), retrieved 2026-09-05. The locally pinned survey records that the TypeScript workflow at `cb1cbcb` uses a weekly cron and `workflow_dispatch` to avoid stacking non-critical work on CI, CodeQL, and dependency review. [CI-workflow survey, F026](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/ci-workflows.md), retrieved 2026-09-05. The unauthenticated raw TypeScript URL returned HTTP 404 on 2026-09-05, so its exact YAML was not independently fetched in this run.

### Principles and implementation

The shared requirement is capability-level: keep the contributors list accurate through an idempotent bot-created pull request, and give a maintainer an out-of-cycle invocation. The inherited action and `mode: pull-request` behavior are F060, not R07's decision. [CI-workflow survey, F060](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/ci-workflows.md), retrieved 2026-09-05. The cadence is a policy-level choice because py and ts intentionally diverge; it need not agree at the event level across all three repositories. [F026 ledger row](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/COMMONALITY.md), retrieved 2026-09-05.

Essential behaviors are: one automatic reconciliation run per week; a manual run at any time; no automatic run for every ordinary merge; and the inherited action proposes its result as a PR rather than pushing directly. Observable acceptance criteria are: the workflow's `on` block contains exactly one weekly `schedule` cron and `workflow_dispatch`, contains no `push`, and an authorized manual dispatch creates or updates the bot PR when contributor state is stale. GitHub documents that schedule events run from the default-branch workflow and may be delayed during high load, which makes the manual escape hatch a requirement rather than a convenience. [GitHub Actions schedule event](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#schedule), retrieved 2026-09-05.

The architectural alternatives are a merge-coupled push trigger, a time-coupled scheduled trigger, both triggers, and no automatic trigger. A scheduled workflow is appropriate in Rust because the calculation is repository metadata maintenance, not a CLI, library, or web-service runtime function. It has no Rust runtime, async-runtime, MSRV, license, or target-OS coupling. Its hosted runner executes independently of the template's Ubuntu/macOS product CI matrix; Windows support is not applicable to this policy. [Owner fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md), retrieved 2026-09-05.

The minimal realistic implementation is a standalone `.github/workflows/update-contributors.yml` with `schedule: - cron: '17 9 * * 1'` and `workflow_dispatch:`. Minute 17 avoids the top-of-hour load period that GitHub identifies for schedule delays. Preserve F060's existing job, bot PR mode, and idempotent branch synchronization unchanged. The proposed acceptance check is described under `Validation strategy`; no template workflow exists yet, so no end-to-end dispatch was executed in this run. [GitHub Actions schedule event](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#schedule), retrieved 2026-09-05.

No `BASELINE-REVIEW:` line is emitted. F026 already records a divergence, and this recommendation selects one documented precedent without challenging the inherited F060 bot pattern.

### Dominant choice

Use a weekly scheduled GitHub Actions run at `17 09:00 UTC` every Monday, expressed as `17 9 * * 1`, plus `workflow_dispatch`; omit `push` and `paths-ignore`. The schedule is intentionally weekly because a contributors list is a low-urgency documentation artifact and this template is expected to have a lower merge rate than a production application. Manual dispatch gives immediate recognition when it is needed. GitHub's schedule event uses POSIX cron in UTC, and the TypeScript precedent supplies the directly comparable weekly design. [GitHub Actions schedule event](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#schedule), retrieved 2026-09-05; [CI-workflow survey, F026](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/ci-workflows.md), retrieved 2026-09-05.

### Options

| Name | Where documented | Adopters that practice it | Date of most recent authoritative write-up |
|---|---|---|---|
| Weekly `schedule` plus `workflow_dispatch` | [GitHub Actions schedule](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#schedule) | ts-launch-blueprint for this exact bot pattern; Serde uses schedule plus manual dispatch for CI freshness coverage. [F026](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/ci-workflows.md); [Serde CI](https://github.com/serde-rs/serde/blob/master/.github/workflows/ci.yml), retrieved 2026-09-05 | GitHub documentation retrieved 2026-09-05 |
| `push` to `main` plus `paths-ignore` and `workflow_dispatch` | [GitHub Actions path filters](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpushpull_requestpull_request_targetpathspaths-ignore) | py-launch-blueprint uses it for this exact bot workflow. [Python workflow at `b08bccf`](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccf/.github/workflows/update-contributors.yml), retrieved 2026-09-05 | GitHub documentation retrieved 2026-09-05 |
| Both weekly schedule and push | [GitHub Actions multiple events](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#using-multiple-events) | No directly comparable, maintained contributors-bot reference was verified | GitHub documentation retrieved 2026-09-05 |
| Manual dispatch only | [GitHub Actions workflow dispatch](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#workflow_dispatch) | Both source workflows retain manual dispatch as an override, not as their sole automatic policy. [F026](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/ci-workflows.md), retrieved 2026-09-05 | GitHub documentation retrieved 2026-09-05 |

### Excluded by gate

No crate candidate exists, so the crate-specific license, MSRV, RustSec, `unsafe`, feature, runner-OS, binary-size, and compile-time gates are inapplicable rather than passed. The external-scheduler and `workflow_run` alternatives are excluded by integration fitness: they add a service or another workflow without solving a documented deficiency in native `schedule` plus `workflow_dispatch`. [GitHub Actions events](https://docs.github.com/en/actions/reference/events-that-trigger-workflows), retrieved 2026-09-05.

The inherited `smorinlabs/contributors-please-action` is not an R07 candidate. Its GitHub endpoint reported MIT licensing, `archived: false`, and `pushed_at: 2026-09-01T22:51:20Z`; these figures are contextual only and do not select cadence. [Action repository endpoint](https://api.github.com/repos/smorinlabs/contributors-please-action), retrieved 2026-09-05. The same endpoint search returned one open issue; the sole issue had no comments, so a meaningful ten-issue median first-maintainer-response metric could not be calculated. [Open-issue search endpoint](https://api.github.com/search/issues?q=repo%3Asmorinlabs%2Fcontributors-please-action%2Bis%3Aissue%2Bis%3Aopen), retrieved 2026-09-05.

### Up-and-comers

An external scheduler or a `workflow_run`-based dispatcher is an up-and-comer only in the sense that it is an available composition pattern, not a fit recommendation. Neither is Rust-native, and neither improves the contributor action's correctness, latency, or runner compatibility over direct native scheduling. No appropriate Rust reference implementation was verified. [GitHub Actions `workflow_run`](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#workflow_run), retrieved 2026-09-05.

### Fit for this template

**CLI.** The CLI package does not participate in contributor-list generation. A weekly metadata workflow prevents documentation-only maintenance from consuming a hosted runner after every CLI merge. [F026](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/ci-workflows.md), retrieved 2026-09-05.

**Library.** Library users receive the same contributor recognition without the bot PR becoming a merge-time dependency or adding a Cargo dependency to the public library. The policy therefore has no license, MSRV, feature, `unsafe`, binary-size, or compile-time impact. [Owner fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md), retrieved 2026-09-05.

**Web service.** The web-service example is also unaffected at runtime. The weekly PR updates repository documentation only; it does not start, deploy, or change the web service. Keeping it separate from per-push CI, CodeQL, and dependency review avoids making web-service merges wait behind a non-release-critical task. [F026](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/ci-workflows.md), retrieved 2026-09-05.

### Recommendation

Adopt the scheduled policy: retain `workflow_dispatch`, add one weekly `schedule` event with cron `17 9 * * 1`, and remove the `push` trigger and its `paths-ignore` list. A path filter only filters push or pull-request events; it has no semantic role once automation is time-based. GitHub documents that `paths-ignore` applies to `push`, `pull_request`, and `pull_request_target`, while schedules are defined by cron. [GitHub Actions path filters](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpushpull_requestpull_request_targetpathspaths-ignore), retrieved 2026-09-05; [GitHub Actions schedule](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#schedule), retrieved 2026-09-05.

### Ranked runner-up

The runner-up is `push` to `main` with the Python `paths-ignore` exclusions plus `workflow_dispatch`. It wins only if the template is intentionally operated as a high-frequency collaboration hub where contributors must appear in `CONTRIBUTORS.md` before the next weekly slot and maintainers cannot or will not use manual dispatch. [Python workflow at `b08bccf`](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccf/.github/workflows/update-contributors.yml), retrieved 2026-09-05.

### Tradeoffs

The recommended policy gives up automatic recognition latency of at most seven days relative to push-triggering. That cost is accepted because manual dispatch provides an immediate, authorized recovery path. It also accepts GitHub's documented possibility of schedule delay; selecting minute 17 reduces, but cannot eliminate, top-of-hour contention. [GitHub Actions schedule](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#schedule), retrieved 2026-09-05.

Compared with the push runner-up, it avoids one bot workflow run and potential bot-PR update attempt after every eligible merge. Compared with both triggers, it avoids redundant runs while retaining the same weekly freshness bound. Compared with manual-only, it guarantees eventual maintenance without relying on a person to remember it. [F026](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/ci-workflows.md), retrieved 2026-09-05.

### Parameters

R07 owns no registered parameter.

R07 consumes no registered parameter.

The applicable fixed constraints are `rust-edition = 2024`, `msrv-policy = stable minus 2 minor versions`, `license = MIT OR Apache-2.0`, and `target-os-matrix = ubuntu-latest, macos-latest`; this workflow policy does not change or require a different value for any of them. [Parameters registry](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md), retrieved 2026-09-05.

No `CONFLICT:` line is emitted.

### Migration implications

Create the template workflow file `.github/workflows/update-contributors.yml` with the inherited F060 job content. Its `on` block must contain only the following automatic/manual triggers:

```yaml
on:
  schedule:
    - cron: '17 9 * * 1'
  workflow_dispatch:
```

Do not add `push`, `branches`, or `paths-ignore`; the latter two are only meaningful for the omitted push event. Preserve the F060 action invocation, `mode: pull-request`, output and state files, and the credential placeholder for R21 to decide. [F060 and F061 survey rows](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/ci-workflows.md), retrieved 2026-09-05.

### Validation strategy

The following are planned checks, not executed results; the Rust template and its workflow file do not yet exist.

```sh
actionlint .github/workflows/update-contributors.yml
```

Expected result: `actionlint`, the GitHub Actions workflow linter, exits zero and accepts the YAML event syntax.

```sh
test "$(yq -r '.on.schedule[0].cron' .github/workflows/update-contributors.yml)" = '17 9 * * 1'
test "$(yq -r 'has("on") and .on.workflow_dispatch == null' .github/workflows/update-contributors.yml)" = true
! yq -e '.on.push' .github/workflows/update-contributors.yml
```

Expected result: the exact weekly cron and `workflow_dispatch` are present, and `push` is absent. The second command treats an empty YAML mapping as GitHub's manual-dispatch event representation.

```sh
gh workflow run update-contributors.yml
gh run watch
```

Expected result: an authorized maintainer dispatch creates or updates one contributor bot PR when the contributor state is stale; a second dispatch without new eligible commits creates no duplicate PR. This check requires the R21 credential decision and a GitHub repository, so it was not executed here.

### Confidence & re-verify trigger

Confidence is high for the event syntax and the policy fit: the decision uses only documented GitHub Actions events, the direct py/ts divergence, and a maintained Rust-project example of scheduled plus manual workflow operation. Confidence is medium for the exact Monday `09:17 UTC` slot because it is a practical non-top-of-hour selection, not an empirically measured contributor-activity peak. [GitHub Actions schedule](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#schedule), retrieved 2026-09-05; [F026](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/ci-workflows.md), retrieved 2026-09-05.

Re-verify before implementation if GitHub changes scheduled-workflow delivery semantics, if the template is expected to receive frequent externally visible contributor additions that cannot wait for manual dispatch, if R21 changes the bot's ability to create PRs on a schedule, or if the project changes its source-of-truth policy for generated contributors content.

### Sources

- [GitHub Actions events that trigger workflows](https://docs.github.com/en/actions/reference/events-that-trigger-workflows), retrieved 2026-09-05.
- [GitHub Actions workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), retrieved 2026-09-05.
- [Python pinned contributors workflow](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccf/.github/workflows/update-contributors.yml), retrieved 2026-09-05.
- [Rust port CI-workflow survey](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/ci-workflows.md), retrieved 2026-09-05.
- [Serde CI workflow](https://github.com/serde-rs/serde/blob/master/.github/workflows/ci.yml), retrieved 2026-09-05.
- [Serde repository endpoint](https://api.github.com/repos/serde-rs/serde), retrieved 2026-09-05.
- [Contributors action repository endpoint](https://api.github.com/repos/smorinlabs/contributors-please-action), retrieved 2026-09-05.

Method notes: queried GitHub Actions documentation; `GET https://api.github.com/repos/serde-rs/serde`; `GET https://api.github.com/search/issues?q=repo:serde-rs/serde+is:issue+is:open`; `GET https://api.github.com/repos/smorinlabs/contributors-please-action`; `GET https://api.github.com/search/issues?q=repo:smorinlabs/contributors-please-action+is:issue+is:open`; and the pinned Python raw workflow URL. Crates.io `/crates/<name>` and `/versions`, docs.rs, and RustSec package endpoints were not queried because R07 is a pattern with no crate candidates. The direct raw TypeScript source URL at `cb1cbcb` returned HTTP 404 anonymously; the bound prompt and local F026 survey were used for that precedent. No GitHub workflow dispatch or template acceptance check was executed.
