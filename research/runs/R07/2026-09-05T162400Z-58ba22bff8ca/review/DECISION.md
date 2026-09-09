# R07 — Contributors-bot trigger cadence — DECISION

Item kind `pattern`, Focused tier. Scope: the `on:` block of the template's
`.github/workflows/update-contributors.yml` only. The bot tool and its wiring
are F060 (`COMMON → REUSE`, retained), the credential source is R21 (F061).

## Decision

**Push to the default branch, filtered by `paths-ignore` on the two generated
files, plus `workflow_dispatch`. No `schedule`.**

```yaml
on:
  push:
    branches: [main]
    paths-ignore:
      - CONTRIBUTORS.md
      - .contributors.jsonl
  workflow_dispatch:
```

This is py-launch-blueprint's shape at the pinned SHA
(`b08bccfb55d05f15e46a83b52c5660b1881d19f5`,
`.github/workflows/update-contributors.yml:3-9`) and the inherited action's own
documented usage (`smorinlabs/contributors-please-action` README, usage block
and the `mode: pull-request` loop-protection note,
https://raw.githubusercontent.com/smorinlabs/contributors-please-action/main/README.md,
retrieved 2026-09-09 by Opus and re-read 2026-09-09 UTC by the synthesizer).
Tool and version are not chosen here: the job body stays the F060 pattern
(`smorinlabs/contributors-please-action` v1.3.9, `mode: pull-request`).

Ledger rows settled: **F026** (`docs/port/COMMONALITY.md:32`, origin
`different`, verdict `DIVERGENT`) — value: push-on-change with a path filter
plus manual dispatch. F060 is retained unchanged and F061 stays with R21.

Cross-repo answer (owner review 2026-09-04: R07 harmonize = yes, class A
setting drift): one cadence for all three repositories, and it is this one.
py is unchanged. ts's weekly cron is a justified-looking but unsupported
departure: its own file header at the pinned SHA
(`cb1cbcb2e88b898e8c081b0abbfabc1630079c00`,
`.github/workflows/update-contributors.yml:33-39`) records that "neither the
source file nor contributors-please-action's own documented usage example runs
on a schedule", and the evidence below shows the noise it was avoiding is small
at a template's merge rate while the failure modes it took on are documented
and observed. Changing ts is follow-on work; this decision supplies the
rationale and makes no edit to another item or the ledger.

### Principles and implementation

**Shared requirement, source, agreement level.** F060's principle
(`docs/port/BASELINE-REVIEW.md:52`, classified *retained*): the contributors
list is regenerated automatically by a bot that opens a pull request rather
than committing to `main`. Agreement level recorded there: policy/mechanism
(the tool is fixed). F026 records the one part that did not agree, the trigger.
The owner asked (harmonize = yes) whether one trigger value should serve all
three repos; the evidence supports the same tradeoff in all three ecosystems,
so a shared value is recommended rather than a per-repo difference.

**Essential behaviors (must agree in py, ts, rs).**

1. Regeneration is automatic; no human has to remember to run it.
2. The result reaches `main` only through a reviewable PR (F060).
3. The workflow is loop-free: merging the bot's own PR must not start another
   bot run that opens another PR.
4. A maintainer can force a regeneration at any time without a code change.
5. The mechanism has no silent-off state in the repository shape this template
   ships as (public, forkable, often quiet).

**What may vary.** Nothing in the `on:` block is language-bound; the action
reads git history on `ubuntu-latest`. The only repository-specific inputs are
merge rate and visibility, and both cut the same way for py, ts and rs (see
the run-volume figures below). Adjacent lines of the same file that vary by
other decisions: credential inputs (R21), permission style (R08), action pin
style (R20), `runs-on` indirection (R09).

**Observable acceptance criteria.**

- A1 — merging a qualifying PR to `main` creates exactly one workflow run
  within seconds, with `event: push`, and one bot PR if the list changed.
- A2 — merging the bot PR (which touches only `CONTRIBUTORS.md` and
  `.contributors.jsonl`) creates zero runs.
- A3 — `gh workflow run update-contributors.yml` creates a run with
  `event: workflow_dispatch`.
- A4 — recognition latency is bounded by the merge, not by a clock.
- A5 — `actionlint` accepts the file; the `paths-ignore` list equals the
  action's `output-file` and `state-file` inputs.

A1, A2 and A5 were verified in `## Empirical check` (A1 and A2 against the
real run history of py's production workflow; A5 with `actionlint`). A3 and
A4 are proposed checks for the first integration on a live repository; they
need R21's credential decision to be executable.

**Architectural alternatives compared before any tool question.**

| Architecture | Authoritative signal | Latency | Loop guard | Silent-off state | Run volume |
|---|---|---|---|---|---|
| A. Event-driven: `push` to `main` + `paths-ignore` + dispatch (py, action README) | the merge | seconds | `paths-ignore` on the generated files | none documented | one short job per qualifying push |
| B. `push` without a path filter (`akhilmhdh/contributors-readme-action` README) | the merge | seconds | none: the bot merge re-fires the bot | none | A plus one per bot merge |
| C. Time-driven: weekly `schedule` + dispatch (ts) | the clock | up to 7 days plus queue delay | not needed | yes: auto-disabled after 60 days without activity in a public repo, disabled by default in forks | 52 per year regardless of activity |
| D. Daily `schedule` (`BobAnkh/add-contributors` README; action at-risk) | the clock | up to 1 day | not needed | yes, as C | 365 per year |
| E. Hybrid: A plus a monthly `schedule` backstop (`wow-actions/contributors-list` README shape) | merge, clock as retry | seconds | as A | backstop only | A plus 12 per year |
| F. Comment-driven (All Contributors bot) | a maintainer's comment | human | none | yes, silently unrecognized | on demand |
| G. `workflow_run` chained after CI | CI completion | after CI | as A | inherits CI's | as A plus a second failure surface |

Documented facts that separate them (GitHub, normative):

- Path filters exist only for `push`, `pull_request` and `pull_request_target`
  (workflow-syntax reference, section
  `on.<push|pull_request|pull_request_target>.<paths|paths-ignore>`,
  https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax,
  retrieved 2026-09-05 by Codex, 2026-09-09 by Opus). `actionlint` 1.7.12
  rejects `paths-ignore` under `schedule` (`## Empirical check`, step 3). The
  MEDIUM question is therefore settled: under a schedule a path filter is not
  moot, it is invalid; under a push trigger it is the loop guard the action's
  README requires in place of `[skip ci]`.
- `paths-ignore` semantics: "When all the path names match patterns in
  `paths-ignore`, the workflow will not run. If any path names do not match
  patterns in `paths-ignore`, even if some path names match the patterns, the
  workflow will run." (same page). GitHub evaluates this over the whole push
  (`before..after`), which the run history confirms: with a merge queue, PRs
  landing seconds apart share one push and one run.
- Scheduled workflows: "In a public repository, scheduled workflows are
  automatically disabled when no repository activity has occurred in 60 days"
  and "When a public repository is forked, scheduled workflows are disabled by
  default"
  (https://docs.github.com/en/actions/how-tos/manage-workflow-runs/disable-and-enable-workflows,
  retrieved 2026-09-09 by Opus, re-read 2026-09-09 UTC by the synthesizer; the
  page names no warning before disabling, and none is asserted here). Also:
  "The `schedule` event can be delayed during periods of high loads of GitHub
  Actions workflow runs. High load times include the start of every hour. If
  the load is sufficiently high enough, some queued jobs may be dropped."
  (https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows,
  retrieved 2026-09-05 by Codex, 2026-09-09 by Opus and by the synthesizer).
  Observed on ts: every one of 9 weekly runs started 1 h 01 min to 7 h 41 min
  after its 06:17 UTC slot (`## Empirical check`, step 5).
- `rs-launch-blueprint` is `visibility: public`
  (`GET https://api.github.com/repos/smorinlabs/rs-launch-blueprint`,
  retrieved 2026-09-09 UTC), so the 60-day rule applies to the target. ts is
  `private`, so its clean weekly history is evidence that the private-repo
  exemption works, not that a schedule is safe for a public template.

**Why the selected design preserves each principle.** (1) automatic: the merge
itself is the trigger. (2) PR-mediated: unchanged, F060. (3) loop-free: the
bot PR touches only the two generated files, so its merge matches every
`paths-ignore` pattern; verified on the 22 post-guard commits in py's production
history that touched only the generated files (20 bot merges, 2 hand edits),
with zero loop runs (step 5b). (4) on demand: `workflow_dispatch`,
kept unconditionally (LOW question). (5) no silent-off: `push` has no
documented auto-disable rule; `schedule` has two, and a public template that
goes quiet for 60 days or is forked is the artifact most exposed to them.

**Run volume, with the real figures (HIGH question).** py's push-triggered
workflow, retained history 2025-11-16 to 2026-09-07: `push` runs per month
2026-06: 87, 2026-07: 31, 2026-08: 7, 2026-09 (to the 7th): 3
(`review/evidence/py-update-contributors-runs.json`). A weekly cron is about
4.3 runs per month regardless of activity. At py's June pace the push trigger
costs roughly 20 times a weekly cron; at its August and September pace it costs
about the same or less. The prompt describes the template as lower-frequency
than either source, so for the template the push trigger is the cheaper of the
two in absolute runs, and each run is one shallow checkout plus one Node
action step, free on public repositories under GitHub's Actions billing rules
(https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions,
retrieved 2026-09-09 by Opus). Codex's noise concern is real on a busy repo
and is answered, not dismissed: the runs are idempotent no-ops when nothing
changed, and the alternative's failure mode is not noise but absence.

**Fit per shape.** The `on:` block is a repository property, so the decision is
shape-invariant. CLI: no interaction; one short job beside the per-push CI. 
Library: release-please commits to `main` touch files other than the two
ignored ones, so a release commit also refreshes the list at no extra
configuration. Web service (optional feature per `web-extra-surface`): no
interaction; the workflow never builds or starts the service.

**Practice evidence and its limit.** Opus listed `.github/workflows` for
twelve widely adopted Rust projects (`rust-lang/cargo`, `tokio-rs/tokio`,
`clap-rs/clap`, `BurntSushi/ripgrep`, `sharkdp/bat`, `astral-sh/ruff`,
`astral-sh/uv`, `starship/starship`, `helix-editor/helix`, `nushell/nushell`,
`tauri-apps/tauri`, `meilisearch/meilisearch`;
`GET https://api.github.com/repos/<o>/<r>/contents/.github/workflows`,
retrieved 2026-09-09): none runs a contributors-list bot in either cadence.
Rust practice therefore cannot decide this item; the decision rests on
GitHub's documented semantics, the tool author's documentation, and the
source repositories' production behavior. Fitness gates 1 to 6 are
`inapplicable` to a workflow trigger (no crate, no Rust code, no license,
MSRV, RustSec, features or binary); gate 4 is satisfied identically by every
option because the job runs on one `ubuntu-latest` runner in both sources.

**Reference implementations.** The action's README usage block; py's pinned
workflow (`b08bccf`, `.github/workflows/update-contributors.yml`); the fixture
`review/empirical/.github/workflows/update-contributors.yml` in this run,
which is the recommended `on:` block over the inherited F060 job body with the
lines owned by R21, R08, R20 and R09 marked.

**Migration implications (file-level).** One file,
`.github/workflows/update-contributors.yml`: the `on:` block above; no
`schedule:` key. The `paths-ignore` list must equal the action's `output-file`
and `state-file` inputs (`CONTRIBUTORS.md`, `.contributors.jsonl`, also in
`.contributors.yml` per F209); a rename in R47 or later must update both in
one change, and A5 exists to catch drift. The `commit-message` input must not
carry `[skip ci]` (py `:39-44`; README loop-protection note). No Justfile,
Cargo, ruleset or required-check change: this workflow reports no required
status check, so it does not consume R11's `ci-job-structure`.

**Ranked runner-up.** E, the recommendation plus a monthly backstop
`schedule: - cron: '17 6 1 * *'` (minute 17, not on the hour, per GitHub's
load advice; monthly bounds a missed push run at 31 days for 12 runs a year).
It wins if R21 settles F061 on a credential that can expire or be revoked
(App key or PAT rather than `secrets.GITHUB_TOKEN`), because then a push run
can fail on a merge nobody watches and stay stale until the next qualifying
merge; ts's history shows a cron retrying through three consecutive failures
(2026-07-13, 07-20, 07-27) before succeeding. Second runner-up: C, ts's weekly
schedule alone; it wins only under a hard per-run budget on a private,
metered instantiation, which no evidence here supports.

**Tradeoffs accepted.** Versus E: no automatic retry of a failed push run;
accepted because the failure is visible (a red run on a merge commit),
`workflow_dispatch` is the recovery path, and the backstop is a two-line
addition if R21 creates the expiry risk. Versus C: more runs on a busy repo;
accepted because at the template's expected pace it is fewer, and the thing C
risks is the mechanism ceasing to exist. Versus F: no contribution-type
attribution; not this item's to choose (F060 fixes the tool).

**BASELINE-REVIEW findings:** none. F060 is retained unchanged; no
`COMMON → REUSE` or `ADOPT` row is challenged.

re-verify: 2027-09-08, or earlier when GitHub changes the scheduled-workflow auto-disable rules or extends path filters to `schedule`; when `smorinlabs/contributors-please-action` releases past v1.3.9 with a changed trigger example or loop-protection guidance; when R21 settles F061 on an expiring credential (revisit the monthly backstop); when R47 or a later decision renames either generated file; or when the template's merge rate to `main` exceeds roughly one qualifying merge per week.

## Parameters

- owns: none. The prompt's `- owns:` line is empty and
  `docs/port/PARAMETERS.md` names no parameter owned by R07.
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- consumed researched parameters: none (`- consumes:` is empty). The
  `paths-ignore` here is a loop guard on a non-CI automation workflow, not a
  skip-gate on a required check, so it does not consume or constrain R11's
  `ci-job-structure`.
- No `CONFLICT:` line. Neither raw raised one; the recommendation touches no
  fixed parameter (it compiles no Rust, adds no dependency, and runs on one
  `ubuntu-latest` job outside the test matrix).

## Empirical check

**Form used and why.** Form (b) of the task's acceptable forms: `act` is not
installed (`command -v act` empty), so the recommended workflow was validated
with a real tool (`actionlint` 1.7.12), its `paths-ignore` filter was
evaluated by an executed script against the real first-parent history of both
pinned source repositories, and the result was cross-checked against the real
GitHub Actions run history of both sources' `update-contributors.yml` (REST
via `gh api`, pages 20 s apart). The last part is real events, which is the
spirit of form (a).

**Toolchain and OS.** macOS 26.4 arm64; `rustc 1.98.0 (88d9e12ae 2026-08-18)
(Homebrew)`; `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)` (no Rust is
compiled; recorded per the role contract); `actionlint 1.7.12`; Python 3.14.7
with PyYAML 6.0.3; `gh version 2.98.0`. Log timestamp 2026-09-09T06:43:42Z.

**Working directory.**
`research/runs/R07/2026-09-05T162400Z-58ba22bff8ca/review/empirical/`

**Command.**

```sh
./run-check.sh 2>&1 | tee ../evidence/r07-empirical.log   # exit 0
```

`run-check.sh` runs, in order: (1) `actionlint .github/workflows/update-contributors.yml`;
(2) `actionlint alternatives/schedule-only.yml`; (3) `actionlint alternatives/schedule-with-paths-ignore.yml`;
(4) `paths_filter.py` over py `b08bccf` and ts `cb1cbcb`; (5) `real_runs.py`
(REST run history of both sources); (5b) `analyze_runs.py` (push-range model);
(5c) `gh api repos/smorinlabs/py-launch-blueprint/rules/branches/main`;
(6) the pinned `on:` blocks quoted from both trees.

**Observed output (excerpts; full log in the evidence file).**

```text
== 1. actionlint on the recommended workflow (expect exit 0) ==
exit: 0
== 2. actionlint on the ts-shape alternative, schedule + dispatch (expect exit 0: syntax does not decide the item) ==
exit: 0
== 3. actionlint on the negative fixture, paths-ignore under schedule (expect non-zero) ==
alternatives/schedule-with-paths-ignore.yml:8:7: unexpected key "paths-ignore" for element of "schedule" section. expected one of "cron", "timezone" [syntax-check]
exit: 1
== 4. paths-ignore filter evaluated against real first-parent commits ==
-- py-launch-blueprint @ b08bccfb55d05f15e46a83b52c5660b1881d19f5, full history --
first-parent commits evaluated: 381
verdict counts: {"EMPTY-DIFF": 4, "RUN": 353, "SKIP": 24}
  SKIP       8d6ae873c6 2026-07-22 files=2 ignored=2 Merge pull request #498 from smorinlabs/contributors-please/update
  SKIP       411d316f7b 2026-07-16 files=2 ignored=2 docs: update contributors (#457)
  ... (24 SKIP rows: 20 bot merges, 2 `fix(contributors): restore ...` hand edits of CONTRIBUTORS.md alone, 2 pre-guard `chore: update contributors list`)
-- ts-launch-blueprint @ cb1cbcb2e88b898e8c081b0abbfabc1630079c00, full history --
first-parent commits evaluated: 61
verdict counts: {"RUN": 61}
== 5. cross-check against real GitHub Actions run history (REST, pages 20 s apart) ==
retained runs: 203 by event: {"pull_request": 46, "push": 154, "workflow_dispatch": 3}
retained window: 2025-11-16T16:52:48Z .. 2026-09-07T06:58:02Z
A2: SKIP commits in git history: 24; with a push run in production: 5
A1: ... RUN verdicts: 241; with a matching push run: 147; without: 94   <- naive per-commit model, superseded by 5b
== ts-launch-blueprint: schedule-triggered history (REST) ==
retained runs: 9 by event: {"schedule": 9}
  2026-07-13T09:49:11Z failure  delay=3:32:11 (weekday=Mon)
  2026-07-20T09:35:52Z failure  delay=3:18:52 (weekday=Mon)
  2026-07-27T10:11:02Z failure  delay=3:54:02 (weekday=Mon)
  2026-08-03T10:07:32Z success  delay=3:50:32 (weekday=Mon)
  2026-08-10T08:06:34Z success  delay=1:49:34 (weekday=Mon)
  2026-08-17T07:18:04Z success  delay=1:01:04 (weekday=Mon)
  2026-08-24T07:30:31Z success  delay=1:13:31 (weekday=Mon)
  2026-08-31T13:58:35Z success  delay=7:41:35 (weekday=Mon)
  2026-09-07T12:40:41Z success  delay=6:23:41 (weekday=Mon)
== 5b. push-range model of the same run history (merge-queue batching) ==
push runs with head on the pinned first-parent line: 153 of 154
before the guard (40aa691910, 2026-05-27T23:45:38Z): bot-only commits that fired a push run: 2
after the guard: first-parent commits 162, push runs 134, commits after the last run 0
runs whose push range holds more than one commit (batched merges): 23
A2': runs whose whole push range is ignored files only: 0 (expected 0)
bot-only commits after the guard: 22; as a run head: 3 (each shares its push with a non-ignored commit, listed):
  e780c9956c docs: update contributors (#343) <- pushed with 954de95ce6 chore(main): release 1.1.4 (#345)
  8b36143c78 docs: update contributors (#352) <- pushed with a3008ebd88 chore(main): release 1.1.5 (#353)
  2a44d9b08e Merge pull request #497 from smorinlabs/contributors-please/update <- pushed with 6b2680966d Merge pull request #495 from smorinlabs/fix/commitlint-via-mise
A1': qualifying commits not inside any run's range: 0 (expected 0; ...)
== 5c. why pushes are batched: rules on py main (REST, 1 call) ==
["code_scanning","copilot_code_review","deletion","merge_queue","non_fast_forward","pull_request"]
overall status: 0
```

**Reading.** Step 3 is the executed form of the MEDIUM answer: a path filter
under `schedule` is a syntax error, not a no-op. Step 4 shows what the
recommended filter does on real history: every bot merge in py (20 of them at
the pin) and two hand edits that touched only `CONTRIBUTORS.md` are skipped;
every other commit runs; ts has no bot-only commit on `main`, so all 61 run.
Step 5's naive per-commit comparison showed 5 apparent leaks and 94 apparent
missing runs; step 5b explains both with GitHub's actual semantics (the filter
is evaluated over the whole push) plus py's merge queue (step 5c): 23 pushes
carried more than one merge, 2 of the 5 leaks predate the guard's arrival on
`main` (they are the loop running unguarded, which the guard was added to
stop), and the other 3 bot commits landed 11 to 14 s after a release-please or
feature merge inside the same push. After the guard: 134 runs for 162
first-parent commits, zero runs whose push contained only ignored files (A2
held for all 22 generated-files-only commits: 20 bot merges, 2 hand edits),
zero qualifying commits outside a run's range (A1). The ts history shows the documented schedule delay in practice, three
consecutive failures retried weekly, and zero `workflow_dispatch` runs in the
workflow's life, so the manual escape hatch was never used there.

**What this does not prove.** The action was not executed and no bot PR was
opened: that needs a live repository and R21's credential decision (proposed
checks A3 and A4). The 60-day auto-disable and the fork default are documented
rules, not reproduced here; ts is private and so not subject to the first, and
no evidence was gathered on whether "Use this template" instantiation behaves
like a fork (Opus's stated gap, left open). `paths_filter.py` is a
reimplementation of GitHub's documented rule; its verdicts were cross-checked
against production run history rather than against GitHub's evaluator
directly. The run history is live data retrieved after the pin (runs to
2026-09-07); 1 of 154 push runs has a head after the pinned SHA and was
excluded. A1' is structurally weak (push ranges partition the history), so the
A1 evidence is the count of 134 runs against 162 commits and 23 batched
pushes, not A1' alone.

**Evidence files.** `review/evidence/r07-empirical.log` (full run),
`review/evidence/py-paths-verdicts.json`, `review/evidence/ts-paths-verdicts.json`,
`review/evidence/py-update-contributors-runs.json` (203 runs),
`review/evidence/ts-update-contributors-runs.json` (9 runs). Fixture and
scripts: `review/empirical/.github/workflows/update-contributors.yml`,
`review/empirical/alternatives/*.yml`, `review/empirical/paths_filter.py`,
`review/empirical/real_runs.py`, `review/empirical/analyze_runs.py`,
`review/empirical/run-check.sh`.

## Engines

- codex `raw/codex.md` (gpt-5.6-terra, 2026-09-05, sha256
  `fec48e36bb5a3183da6f2a133cdccc223fcaf722a49a3410e30fe1c45501af04`) —
  recommends weekly `schedule` (`17 9 * * 1`) plus `workflow_dispatch`, no
  push; runner-up py's push shape.
- opus `raw/opus.md` (claude-opus-5[1m], 2026-09-09, sha256
  `a2f5e9a652105d01d0256b1aa06390692282bedf6bce4823a7bf24224cc7dbfc`) —
  recommends `push` + `paths-ignore` + `workflow_dispatch`; runner-up the same
  plus a monthly backstop.

**Disagreement 1 — primary trigger (the decision).** Settled for Opus by
evidence Codex did not engage: (a) GitHub's documented auto-disable of
scheduled workflows in public repositories after 60 days without activity and
in forks, re-read by the synthesizer, applicable because `rs-launch-blueprint`
is public; (b) the inherited action's README documents push + `paths-ignore`
and ships no scheduled example (Codex did not read the README); (c) ts's own
header conceding the departure (Codex could not fetch the ts file, HTTP 404,
and relied on the area note); (d) the production run history: the guard held
on all 22 post-guard generated-files-only commits (20 bot merges, 2 hand
edits), and ts's cron ran 1 to 7.7 hours late every
week. Codex's stated strengths, GitHub event semantics and the `serde-rs/serde`
daily-cron CI, are accurate but do not bear on a contributors task; Codex
itself says so.

**Disagreement 2 — the noise argument.** Codex: push stacks a run on every
merge. Opus: below one qualifying merge a week push is cheaper than weekly
cron. The synthesizer measured it: py ran 87 push runs in 2026-06 and 7 in
2026-08 against about 4.3 a month for a weekly cron. Codex is right for a
busy repository; Opus is right for the template's stated pace; the decision
weighs the schedule's silent-off state above either count.

**Disagreement 3 — path filter under a schedule.** Codex: moot. Opus: invalid.
`actionlint` rejects it (step 3), settling for Opus.

**Disagreement 4 — cron minute.** Both raws independently choose minute 17 to
avoid the top of the hour; carried into the runner-up's backstop cron. ts's
observed delays show the offset does not remove queue delay.

**Agreements.** Both raws: keep `workflow_dispatch` unconditionally; crate
figures inapplicable to a pattern item; no `CONFLICT:`; no `BASELINE-REVIEW:`;
no fixed parameter affected.

**Uncertainty.** No Rust project surveyed runs any contributors bot, so there
is no Rust convention to defer to. The template's future merge rate is a
judgment; if it exceeds about one qualifying merge a week the volume argument
for C strengthens (re-verify trigger). Whether template instantiation disables
schedules like a fork is unconfirmed (Opus gap 5). Issue-responsiveness
medians for the surveyed actions were not computed by either raw; none is a
dependency of this template. Codex's retrieval dates are 2026-09-05, Opus's
2026-09-09 (UTC), the synthesizer's 2026-09-09 UTC.
