# R07 — Contributors-bot trigger cadence — DECISION (revision 2, 2026-09-15)

**What changed in revision 2, and why.** One thing: the recommended `on:` block
gains the monthly `schedule` backstop. **The owner directed it.**
`docs/port/OWNER-REVIEW.md`, section *"Wave 0 owner acceptances (recorded from
2026-09-14)"*, the `R07` row, records the direction in full:

> W0-R07 option A: push trigger accepted AND the owner directs revision 2 to add
> the monthly backstop `schedule: - cron: '17 6 1 * *'` (the decision's own
> runner-up condition was met when R21 settled on an expiring credential);
> re-bound at revision 2

The same row records the owner's **accept** of revision 1 at sha256
`0b3dde8f9a15f22e60a01542065c53c122881e8c48bf3ee6c172ba5b70499346`, dated
2026-09-15, and says the acceptance **re-binds at revision 2** rather than being
staled: the push trigger it accepted is unchanged, and what is added is the
option this decision itself ranked runner-up.

**The runner-up's own winning condition was met, which is why the direction is
this decision's own reasoning rather than an override of it.** Revision 1 wrote
that option E "wins if R21 settles F061 on a credential that can expire or be
revoked (App key or PAT rather than `secrets.GITHUB_TOKEN`)" and listed, among
its re-verify triggers, "when R21 settles F061 on an expiring credential
(revisit the monthly backstop)". R21 is now published
(`research/topics/21-contributors-bot-credential-source/DECISION.md`) and settles
F061 on **App credentials plus a fine-grained PAT with an explicit expiry** —
that decision's F061 table row reads "a dedicated repository secret holding a
fine-grained PAT (Contents: write, Pull requests: write, Issues: write, single
repository, explicit expiry)". Both halves of the condition are therefore
satisfied: the credential can expire, and it can be revoked. The trigger has
fired and is recorded as resolved on the `re-verify:` line below.

**One finding revision 2 had to establish before it could state the cost
honestly, and it contradicts a premise the revision was commissioned with.** The
brief for this revision said the 60-idle-day auto-disable would apply "to the
schedule half only" and that "the push half survives it". **That is not what
GitHub documents.** The REST `Workflow` schema gives a workflow **one** `state`
field, required, whose enum is `active | deleted | disabled_fork |
disabled_inactivity | disabled_manually`
(https://docs.github.com/en/rest/actions/workflows?apiVersion=2022-11-28,
retrieved 2026-09-16 UTC (2026-09-15 local) by this synthesizer, HTTP 200,
359,400 bytes; the schema is snapshotted at
`review/evidence/r2-workflow-state-enum.json` and asserted in
`## Empirical check`, revision-2 check 5). There is no per-trigger state, and
the disable-and-enable page defines the operation the same way: "Disabling a
workflow allows you to stop a workflow from being triggered without having to
delete the file from the repo" (snapshot passage 0, same check) — the workflow,
with no trigger named and none excepted. A workflow put into
`disabled_inactivity` or `disabled_fork` therefore fires on **no** event at all,
`push` and `workflow_dispatch` included, until a maintainer re-enables it. So adding the `schedule` key does not merely carry its
own silent-off exposure: it brings the whole workflow, push half included, inside
GitHub's automatic-disable rules, which revision 1's block was outside. Revision
2 implements the owner's direction and states that cost plainly rather than
writing the brief's premise as fact; `### Principles and implementation` records
it as an accepted tradeoff, behavior 5, criterion A7 and the tradeoffs paragraph
carry it, and `## Engines` lists what P03 must validate about it.

**What did not change.** The primary trigger, the loop guard and its placement,
the settled ledger row's identity (F026), every `- assumes` parameter line
(byte-identical), the fitness-gate statements, `BASELINE-REVIEW: none`,
`CONFLICT:` none, and every figure and quotation revision 1 drew from its own
empirical check. Revision 1's scripts, fixtures and logs under
`review/empirical/` and `review/evidence/` are left **byte-identical**; the
revision-2 check is a new script under `review/empirical/r2/` writing a new log.

**Where the block was changed, enumerated mechanically rather than by reading.**
Before editing, `/usr/bin/grep -niE` was run over the revision-1 file for
`schedule|cron|backstop`, for `silent-off|auto-disab|60 day|60-day|disabled`,
and for `runner-up`, and the union of those hits was the work queue: lines 10,
22-31, 33-34, 36-46, 59-67, 76-91, 97, 99-101, 106-115, 122-140, 142-150,
152-165, 188-192, 194-202, 204-213, 215-221, 226, 244-367 (`## Empirical check`,
extended not rewritten), 373-378 and 404-406. Every entry was edited or is named
here as deliberately left byte-identical, and the same searches were re-run
against this file afterwards to confirm that every surviving occurrence carries
its conditions. **Deliberately unchanged**, four of them: the `A`, `C` and `D`
rows of the alternatives table (`A` is still the architecture the recommendation
is built on and its row is accurate as written; `C` and `D` describe
schedule-only architectures, which are still not the recommendation); every line
of revision 1's `## Empirical check` observed output, because that log is
revision 1's and must stay as the two approving audits read it; the fitness-gate
sentence, for the reason under `### Principles and implementation`; and the four
`- assumes` parameter lines, which a diff against the published revision reports
as byte-identical. The two surviving uses of the phrase "no silent-off state"
are both historical — each says what revision 1 claimed and why revision 2
cannot.

**Revision history.**

| Revision | Date | What it did |
|---|---|---|
| 1 | 2026-09-08 | First synthesis. Recommended `push` + `paths-ignore` + `workflow_dispatch`, no `schedule`; ranked E (the same block plus a monthly backstop) runner-up with a stated winning condition. Approved by `review/audit-codex.md` (empirical; actor `audit-codex-2026-09-05T162400Z-58ba22bff8ca`, model `gpt-5.6-terra`, family openai, `verdict: approve`) and by `review/audit-fable.md` (judgment; actor `audit-fable-2026-09-05T162400Z-58ba22bff8ca`, model `claude-fable-5-1`, family anthropic, `verdict: approve`), both citing sha256 `0b3dde8f9a15f22e60a01542065c53c122881e8c48bf3ee6c172ba5b70499346`. Published at `research/topics/07-contributors-bot-trigger-cadence/DECISION.md`, byte-identical. Accepted by the owner 2026-09-15 (W0-R07 option A). |
| 2 | 2026-09-15 | This revision. Adds the owner-directed monthly `schedule` backstop (option E) to the recommended `on:` block, keeps the `paths-ignore` guard under `push` only, and records the auto-disable cost the addition brings. New evidence: `review/empirical/r2/run-check-r2.sh` → `review/evidence/r07-empirical-r2.log`. Supersedes the published revision 1, reproduced verbatim under `## Supersedes`. |

Item kind `pattern`, Focused tier. Scope: the `on:` block of the template's
`.github/workflows/update-contributors.yml` only. The bot tool and its wiring
are F060 (`COMMON → REUSE`, retained), the credential source is R21 (F061).

## Decision

**Push to the default branch, filtered by `paths-ignore` on the two generated
files, plus a monthly `schedule` backstop, plus `workflow_dispatch`.**

```yaml
on:
  push:
    branches: [main]
    paths-ignore:
      - CONTRIBUTORS.md
      - .contributors.jsonl
  schedule:
    - cron: '17 6 1 * *'
  workflow_dispatch:
```

The `push` half — the authoritative trigger, and the one the owner accepted at
revision 1 — is py-launch-blueprint's shape at the pinned SHA
(`b08bccfb55d05f15e46a83b52c5660b1881d19f5`,
`.github/workflows/update-contributors.yml:3-9`) and the inherited action's own
documented usage (`smorinlabs/contributors-please-action` README, usage block
and the `mode: pull-request` loop-protection note,
https://raw.githubusercontent.com/smorinlabs/contributors-please-action/main/README.md,
retrieved 2026-09-09 by Opus and re-read 2026-09-09 UTC by the synthesizer).

The `schedule` half is **not** taken from either source repository or from the
action's documentation, and this decision does not claim it is. ts's own file
header at its pin concedes that "neither the source file nor
contributors-please-action's own documented usage example runs on a schedule",
and that remains true of this cron too. The backstop rests on one thing only,
and it is the condition this decision itself wrote: R21 settled F061 on a
credential that can expire or be revoked, so a push run can fail on a merge
nobody watches, and the list then stays stale until the next qualifying merge.
The owner directed its addition on that basis — `docs/port/OWNER-REVIEW.md`,
section *"Wave 0 owner acceptances (recorded from 2026-09-14)"*, the `R07` row,
quoted in full in the revision note above. The cron values are the ones revision 1 already specified and
justified — minute 17 rather than the top of the hour, per GitHub's documented
high-load advice for `schedule`, and monthly rather than weekly or daily, which
bounds a missed or failed push run at 31 days (the longest calendar month) for
12 runs a year. `paths-ignore` stays under `push` alone; it is invalid under
`schedule` and unnecessary there, for the reasons under
`### Principles and implementation`.

Tool and version are not chosen here: the job body stays the F060 pattern
(`smorinlabs/contributors-please-action` v1.3.9, `mode: pull-request`).

This decision is a **proposal validated in the implementation phase** (owner
ruling, 2026-09-10). It records what the research found and what it recommends;
P03 builds `.github/workflows/update-contributors.yml` and P03's own CI proves
the recommendation. `## Engines` lists what P03 must validate, including every
claim about the scheduled half that no observation in this run reaches. A
decision that does not survive implementation is revised against this recorded
research, not researched again from scratch.

Ledger rows settled: **F026** (`docs/port/COMMONALITY.md:32`, origin
`different`, verdict `DIVERGENT`) — value: push-on-change with a path filter,
plus a monthly schedule as a retry backstop, plus manual dispatch. F060 is
retained unchanged and F061 stays with R21.

Cross-repo answer (owner review 2026-09-04: R07 harmonize = yes, class A
setting drift): one cadence for all three repositories, and it is this one.
Under revision 1 that value was byte-identical to py's block, so py needed no
change; under revision 2 **both** sources would change, py by gaining the
monthly `schedule` entry and ts by gaining the `push` trigger and the
`paths-ignore` guard while its weekly cron is replaced by the monthly one. ts's
weekly cron remains a justified-looking but unsupported departure **as a primary
trigger**: its own file header at the pinned SHA
(`cb1cbcb2e88b898e8c081b0abbfabc1630079c00`,
`.github/workflows/update-contributors.yml:33-39`) records that "neither the
source file nor contributors-please-action's own documented usage example runs
on a schedule", and the evidence below shows the noise it was avoiding is small
at a template's merge rate while the failure modes it took on are documented
and observed. What revision 2 concedes to ts's design is narrower than its
cadence: a clock-driven retry has value **behind** an event-driven trigger,
which is what the backstop is, not in place of one. Changing py or ts is
follow-on work; this decision supplies the rationale and makes no edit to
another item or the ledger.

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
   bot run that opens another PR. This binds the `push` half, where
   `paths-ignore` is the guard. The `schedule` half carries no loop risk at all
   and needs no guard, because a scheduled run is started by the clock and never
   by the bot's own push, so nothing the bot merges can re-fire it.
4. A maintainer can force a regeneration at any time without a code change.
5. Staleness is bounded, and every way the mechanism can stop is either absent or
   documented and recoverable. Revision 1 stated this behavior as "no silent-off
   state" and satisfied it by having no `schedule` key at all. Revision 2 cannot
   state it that way and does not: adding `schedule` brings the whole workflow
   inside GitHub's two automatic-disable rules for scheduled workflows, and the
   REST `Workflow` schema has one `state` per workflow rather than one per
   trigger, so a disabled workflow fires on no event (revision-2 check 5). What
   revision 2 requires instead is that the exposure be bounded, documented and
   recoverable — it is: the inactivity rule's own precondition is 60 days with no
   repository activity, the recovery is one documented step, and the template's
   setup documentation must name both. See "Why the selected design preserves
   each principle", point 5.
6. A failed or missed regeneration is retried without a human noticing it.
   Revision 1 had no mechanism for this and accepted its absence; the monthly
   backstop is that mechanism, and R21's expiring credential is why it is now
   required rather than optional.

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
- A4 — recognition latency is bounded by the merge, not by a clock, whenever a
  push run succeeds.
- A5 — `actionlint` accepts the file; the `paths-ignore` list equals the
  action's `output-file` and `state-file` inputs.
- A6 — on the first day of each month a run appears with `event: schedule`,
  after the 06:17 UTC slot and subject to GitHub's documented queue delay. Its
  purpose is the bound, not the latency: when a push run fails or never fires,
  the list is stale for at most 31 days rather than until the next qualifying
  merge. A6 also fixes the run count the schedule adds, which is 12 a year.
- A7 — after 60 days with no repository activity in a public copy, or in a fork
  of a public copy, `GET /repos/{owner}/{repo}/actions/workflows/update-contributors.yml`
  reports `state` = `disabled_inactivity` or `disabled_fork`, **and no trigger
  of this workflow fires until it is re-enabled** — `push` and
  `workflow_dispatch` included, because the schema carries one `state` per
  workflow and none per trigger. Re-enabling is `gh workflow enable
  update-contributors.yml`, or **Enable workflow** in the Actions sidebar. A7 is
  the criterion that records the cost of the backstop rather than a benefit of
  it, and it is stated as the behavior to expect and document, not as a
  behavior to prevent.

A1, A2 and A5 were verified in `## Empirical check` (A1 and A2 against the real
run history of py's production workflow, which runs the identical `push` half;
A5's first clause with `actionlint` at revision 1 and again at revision 2, its
second clause executed for the first time at revision 2, check 2). A6's syntax
and cron fields are verified at revision 2 (checks 1 and 2); its *runtime*
behavior is not, because no scheduled run of this block has ever executed
anywhere. A7 is documented, not reproduced: the two sentences and the `state`
enum are asserted against retrieved snapshots (revision-2 check 5), and no
repository was left idle for 60 days or forked to observe them. A3, A4, A6's
runtime half and A7 are proposed checks for the first integration on a live
repository; A3 and A4 additionally need R21's credential decision to be
executable.

**Architectural alternatives compared before any tool question.**

| Architecture | Authoritative signal | Latency | Loop guard | Silent-off state | Run volume |
|---|---|---|---|---|---|
| A. Event-driven: `push` to `main` + `paths-ignore` + dispatch (py, action README) | the merge | seconds | `paths-ignore` on the generated files | none documented | one short job per qualifying push |
| B. `push` without a path filter (`akhilmhdh/contributors-readme-action` README) | the merge | seconds | none: the bot merge re-fires the bot | none | A plus one per bot merge |
| C. Time-driven: weekly `schedule` + dispatch (ts) | the clock | up to 7 days plus queue delay | not needed | yes: auto-disabled after 60 days without activity in a public repo, disabled by default in forks | 52 per year regardless of activity |
| D. Daily `schedule` (`BobAnkh/add-contributors` README; action at-risk) | the clock | up to 1 day | not needed | yes, as C | 365 per year |
| **E. Hybrid: A plus a monthly `schedule` backstop (`wow-actions/contributors-list` README shape) — SELECTED at revision 2** | merge, clock as retry | seconds | as A, on the `push` half; the `schedule` half needs none | the whole workflow, on `schedule`'s two rules, bounded and recoverable (A7) | A plus 12 per year |
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
  README requires in place of `[skip ci]`. **This is why the recommended block
  keeps the guard under `push` only**, and revision 2 re-ran the check against
  its own block rather than inheriting revision 1's answer: moving the guard onto
  the new `schedule` entry of the recommended block is rejected by `actionlint`
  1.7.12 with `unexpected key "paths-ignore" for element of "schedule" section`
  (revision-2 check 3, the negative control). Nothing is lost by the omission,
  because a scheduled run is started by the clock rather than by the bot's own
  push, so it cannot be the second half of a loop; the guard exists to stop a
  push from re-firing a push, and there is no such path from the schedule.
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
  exemption works, not that a schedule is safe for a public template. (Revision
  1 wrote that "the only repository-specific inputs are merge rate and
  visibility, and both cut the same way for py, ts and rs". Visibility does not:
  ts is private and the two disable rules do not reach it, as the revision-1
  judgment audit observed at O6. Corrected here rather than repeated.)
- **Disabling is a property of the workflow, not of one trigger.** The REST
  `Workflow` schema declares `state` as a required field whose enum is
  `["active","deleted","disabled_fork","disabled_inactivity","disabled_manually"]`
  (https://docs.github.com/en/rest/actions/workflows?apiVersion=2022-11-28,
  retrieved 2026-09-16 UTC (2026-09-15 local) by the synthesizer, HTTP 200,
  359,400 bytes; snapshot `review/evidence/r2-workflow-state-enum.json`,
  asserted in revision-2 check 5), and the disable-and-enable page says the same
  thing in words: "Disabling a workflow allows you to stop a workflow from being
  triggered without having to delete the file from the repo" (same retrieval,
  snapshot passage 0) — the object is the workflow, and no trigger is named or
  excepted. So when either rule above fires on this workflow, the `push` trigger
  and `workflow_dispatch` stop with it. The
  documented recovery is one step — `gh workflow enable WORKFLOW`, or **Enable
  workflow** in the Actions sidebar (same page, snapshot passage 2). This fact is
  the reason revision 1 could claim the recommendation had no silent-off state
  and revision 2 cannot; it is not a reason to decline the owner's direction, and
  it is recorded as the direction's cost.

**Why the selected design preserves each principle.** (1) automatic: the merge
itself is the trigger. (2) PR-mediated: unchanged, F060. (3) loop-free: the
bot PR touches only the two generated files, so its merge matches every
`paths-ignore` pattern; verified on the 22 post-guard commits in py's production
history that touched only the generated files (20 bot merges, 2 hand edits),
with zero loop runs (step 5b). The added `schedule` entry cannot loop and needs
no guard: it is fired by the clock, not by the bot's own push, and the guard is
invalid there in any case (revision-2 check 3). (4) on demand:
`workflow_dispatch`, kept unconditionally (LOW question). (5) bounded staleness
with a documented stop, which is weaker than what revision 1 claimed and is the
price of (6). Revision 1's ground was that `push` has no documented auto-disable
rule while `schedule` has two, so a block with no `schedule` key had no
silent-off state at all. That ground is spent: with the `schedule` key present,
both rules attach to **this workflow**, and a disabled workflow fires on no
trigger, so the `push` half loses its exemption too. What remains true, and is
what behavior 5 now requires, is that the exposure is bounded and recoverable.
Its precondition is 60 days in which nothing at all happened in the repository —
an interval in which no push would have fired the workflow either — so the loss
is not months of silent staleness but the first push after the idle period, and
the recovery is one documented click or one `gh workflow enable`. The fork rule
is the sharper edge for a *template*, since every consumer's copy is the case it
describes; whether "Use this template" instantiation is treated as a fork for
this purpose is unconfirmed and stays an open gap (Opus gap 5, carried). Both
belong in the template's setup documentation, which is the mitigation this
decision asks P03 for. (6) retried: a failed or missed push run is re-attempted
within 31 days by the backstop, which is the behavior R21's expiring credential
made necessary, and which revision 1 had no way to provide.

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

**What the monthly backstop adds to that, and what it buys.** Exactly **12 runs
a year**, one on the first of each month at 06:17 UTC plus GitHub's queue delay,
independent of activity — roughly a quarter of a weekly cron's 52 and, at py's
August pace of 7 push runs a month, an increase of about one seventh. On a public
repository they are free under the same billing rules, and each is the same
idempotent no-op when nothing changed. What the 12 runs buy is measured on the
same history: of the 134 post-guard push runs of py's identical `push` half, 12
concluded `failure` and 122 `success` (revision-2 check 6, recounted from
`review/evidence/py-update-contributors-runs.json` under revision 1's own step-5b
scoping; the revision-1 judgment audit reported the same 12 at its observation
O2 and the figure was not carried into revision 1's text). Revision 1 accepted
those 12 qualitatively — "the failure is visible (a red run on a merge commit)"
— and that acceptance held only while the credential could not expire. It can
now, so an unattended failure is no longer certain to be transient, and the
backstop bounds how long one can persist at 31 days without anyone watching. ts's
scheduled history shows the retry pattern working from the other side: 3 of its 9
weekly runs concluded `failure` (2026-07-13, 07-20, 07-27) and the cron retried
through all three before succeeding on 08-03.

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
Revision 2 leaves that sentence byte-identical, including gate 1. The owner's
licence ruling of 2026-09-12 (Q4 as superseded by Q7.B) strikes gate 1 from every
item's evaluation, but it changes nothing here: gate 1 already read
`inapplicable` on its own ground, which is that this item selects no crate, tool
or dependency of any kind — it changes three keys of one YAML block — so there is
no licence to be compatible or incompatible with. The row is recorded, not
deleted, as the ruling requires. Adding the `schedule` key introduces no
candidate and so reopens no gate.

**Reference implementations.** For the `push` half: the action's README usage
block; py's pinned workflow (`b08bccf`,
`.github/workflows/update-contributors.yml`). For the hybrid shape as a whole:
the `wow-actions/contributors-list` README, which is where option E's shape came
from, and which is a shape reference rather than a production observation. The
fixture for the recommendation is
`review/empirical/r2/.github/workflows/update-contributors.yml` in this run —
the revision-2 `on:` block over the inherited F060 job body with the lines owned
by R21, R08, R20 and R09 marked. Revision 1's fixture
`review/empirical/.github/workflows/update-contributors.yml` is left
byte-identical and is now the reference for the `push` half alone.

**Migration implications (file-level).** One file,
`.github/workflows/update-contributors.yml`: the `on:` block above, with the
`schedule:` key carrying exactly one `cron` entry and no other key — a
`paths-ignore` under it is a syntax error, not a no-op. One documentation
obligation goes with it, and it is new at revision 2: the template's setup page
must tell a consumer that this workflow is now a scheduled workflow, that GitHub
therefore disables it by default in a fork of a public copy and automatically
after 60 days without repository activity in a public copy, that the disable
stops the `push` trigger too, and that **Enable workflow** or `gh workflow enable
update-contributors.yml` restores it (criterion A7). The `paths-ignore` list must
equal the action's `output-file` and `state-file` inputs (`CONTRIBUTORS.md`, `.contributors.jsonl`, also in
`.contributors.yml` per F209); a rename in R47 or later must update both in
one change, and A5 exists to catch drift. The `commit-message` input must not
carry `[skip ci]` (py `:39-44`; README loop-protection note). No Justfile,
Cargo, ruleset or required-check change: this workflow reports no required
status check, so it does not consume R11's `ci-job-structure`.

**Ranked runner-up.** Option E was revision 1's runner-up and is revision 2's
recommendation, so a new one is recorded here rather than "none". It is **A —
revision 1's own block, the recommendation with the `schedule` key dropped.** Its
winning condition is the exact reverse of the trigger that just fired: it wins if
F061 moves back to a credential that cannot expire or be revoked, because the
backstop's whole justification is the unattended failure an expiring credential
makes possible, and dropping the key restores the property revision 1 had and
revision 2 gives up — a workflow outside GitHub's scheduled-workflow
auto-disable rules, whose `push` trigger no fork default or 60-day rule can
switch off. It would also win if GitHub extended `disabled_fork` or
`disabled_inactivity` in a way that made the exposure unbounded or the recovery
non-obvious for a template's consumers. Second runner-up: C, ts's weekly
schedule alone; it wins only under a hard per-run budget on a private,
metered instantiation, which no evidence here supports. D, F and G are not
ranked, for the reasons in the table and the `workflow_run` note.

**Tradeoffs accepted.** Versus A, revision 1's block, and this is the one
revision 2 adds: the workflow becomes a scheduled workflow, so GitHub's two
automatic-disable rules now reach it, and because `state` is one field of the
whole workflow the `push` trigger is disabled with it (A7). Accepted, on the
owner's direction and on the reasoning the direction cites: the exposure is
bounded by its own 60-day-of-total-inactivity precondition, the recovery is one
documented step, the fork case is a documentation obligation rather than a
failure, and what is bought is the automatic retry of the 12-in-134 failed push
runs that R21's expiring credential turned from a transient nuisance into a
plausible silent stall. Also accepted: 12 extra runs a year, free on a public
repository. Versus C: more runs on a busy repo; accepted because at the
template's expected pace it is fewer, and the thing C risks is the mechanism
ceasing to exist. Versus F: no contribution-type attribution; not this item's to
choose (F060 fixes the tool).

**BASELINE-REVIEW findings:** none. F060 is retained unchanged; no
`COMMON → REUSE` or `ADOPT` row is challenged.

re-verify: 2027-09-15, or earlier when GitHub changes the scheduled-workflow auto-disable rules, changes the REST `Workflow` `state` enum so that disabling becomes per-trigger rather than per-workflow, or extends path filters to `schedule`; when `smorinlabs/contributors-please-action` releases past v1.3.9 with a changed trigger example or loop-protection guidance; when F061 moves off an expiring or revocable credential, which is the winning condition of the ranked runner-up and would reopen whether the backstop still earns its auto-disable exposure (the reverse of the revision-1 trigger "when R21 settles F061 on an expiring credential (revisit the monthly backstop)", which **fired and is resolved**: R21 published on 2026-09-10 settling F061 on App credentials plus a fine-grained PAT with an explicit expiry, the owner directed the backstop on 2026-09-15, and revision 2 adopts it); when R47 or a later decision renames either generated file; when the first live instantiation establishes whether "Use this template" disables scheduled workflows the way a fork does (Opus gap 5, still open); or when the template's merge rate to `main` exceeds roughly one qualifying merge per week.

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

This section has two parts. **Part 1**, from *Form used and why* to *Evidence
files*, is revision 1's check, reproduced unchanged; its script, fixtures and
logs are byte-identical to what the two approving audits read, and no sentence
in it has been edited. **Part 2**, *Revision 2*, is new and covers only what
revision 2 changed. Where the two disagree about nothing, they are simply about
different blocks: part 1's fixture has no `schedule` key, part 2's does.

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

### Revision 2

**What it checks and why it is a new script.** Revision 2 changes the `on:`
block, so revision 1's `actionlint` result no longer covers the recommendation.
Rather than edit revision 1's script — which would break the claim that its
saved log is that script's output, the claim two audits verified — revision 2
adds `review/empirical/r2/run-check-r2.sh` and a new log. Six checks: (1)
`actionlint` on the revision-2 block; (2) that block's `on:` structure asserted
field by field, including every cron field and criterion A5's second clause; (3)
the negative control; (4) that the control differs from the recommendation only
in where the guard sits; (5) the documentation facts that decide the
backstop's cost, asserted against retrieved snapshots; (6) a recount of py's
post-guard push-run outcomes, which is the figure the cost paragraph now cites.
Every check asserts on content, a failure counter becomes the exit status, and
`set -o pipefail` is set.

**Toolchain and OS.** macOS 26.4 arm64; `rustc 1.98.0 (88d9e12ae 2026-08-18)
(Homebrew)`; `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)` (no Rust is
compiled; recorded per the role contract); **`actionlint` 1.7.12** (the same
version revision 1 used; `actionlint --version` also reports "installed by
building from source, built with go1.26.1 compiler for darwin/arm64"); Python
3.14.7 with PyYAML 6.0.3; `act` absent, so this is form (b) as before. Log
timestamp `2026-09-16T02:50:51Z`, which is 2026-09-15 in this host's local time
— the date this revision carries — and 2026-09-16 UTC, the date used for every
retrieval and snapshot below.

**Working directory.**
`research/runs/R07/2026-09-05T162400Z-58ba22bff8ca/review/empirical/r2/`

**Command.**

```sh
./run-check-r2.sh 2>&1 | tee ../../evidence/r07-empirical-r2.log   # exit 0
```

**Observed output (the assertion lines; the full log is the evidence file).**

```text
== 1. actionlint on the revision-2 recommended workflow (expect exit 0 and no diagnostics) ==
exit: 0
assert-ok: actionlint accepts the push + schedule + workflow_dispatch block
assert-ok: actionlint emitted no diagnostic line for the recommended block

== 2. structure of the recommended on: block, asserted field by field ==
assert-ok: set of on: keys == ['push', 'schedule', 'workflow_dispatch']
assert-ok: on.push.branches == ['main']
assert-ok: on.push.paths-ignore == ['CONTRIBUTORS.md', '.contributors.jsonl']
assert-ok: on.schedule == [{'cron': '17 6 1 * *'}]
assert-ok: on.workflow_dispatch == None
assert-ok: keys of every on.schedule entry == ['cron']
assert-ok: paths-ignore == {output-file, state-file} == ['.contributors.jsonl', 'CONTRIBUTORS.md']
assert-ok: cron minute (not the top of the hour, per GitHub's high-load advice) == '17'
assert-ok: cron hour == '6'
assert-ok: cron day-of-month == '1'
assert-ok: cron month (every month) == '*'
assert-ok: cron day-of-week (unrestricted) == '*'
assert-ok: cron field count == 5
longest gap between two monthly runs, in days: 31 (the longest calendar month)

== 3. negative control: the same block with paths-ignore moved under schedule (expect non-zero) ==
alternatives/hybrid-paths-ignore-under-schedule.yml:13:7: unexpected key "paths-ignore" for element of "schedule" section. expected one of "cron", "timezone" [syntax-check]
exit: 1
assert-ok: actionlint rejects paths-ignore under schedule
assert-ok: rejection names the expected cause: unexpected key "paths-ignore" for element of "schedule" section

== 5. documentation snapshots: the two facts that decide the backstop's cost ==
assert-ok: /usr/bin/grep: snapshot carries the sentence defining what disabling does — stop the workflow from being TRIGGERED, no trigger named or excepted
assert-ok: /usr/bin/grep: snapshot carries the 60-day inactivity sentence
assert-ok: /usr/bin/grep: snapshot carries the fork-default sentence
assert-ok: /usr/bin/grep: snapshot carries the documented re-enable command
["active", "deleted", "disabled_fork", "disabled_inactivity", "disabled_manually"]
assert-ok: `state` is ONE required field of the whole workflow, whose enum carries disabled_fork and disabled_inactivity; there is no per-trigger state, and passage 0 defines disabling as stopping the workflow from being triggered without naming or excepting a trigger, so a workflow disabled by either rule fires on NO event, push and workflow_dispatch included

== 6. what the monthly backstop retries: py's post-guard push-run outcomes ==
post-guard push runs (same scoping as revision 1 step 5b): 134
conclusions: {"failure": 12, "success": 122}
ts scheduled runs for comparison: {"failure": 3, "success": 6}
assert-ok: 134 post-guard push runs, the figure revision 1 cites
assert-ok: 12 of those 134 push runs concluded `failure` ...

overall failed assertions: 0
RESULT: PASS
```

**Reproducibility, established by re-running rather than asserted.** The script
was re-run immediately after the log was saved and the two were diffed. Exactly
**one line** differs — the `date:` header, `2026-09-16T02:50:51Z` against
`2026-09-16T02:50:52Z`. Nothing else moves, because every input is a file in
this run directory: the two fixtures, the two documentation snapshots and the
two run-history JSONs. **The comparison rule is therefore: two runs of this
script agree when, after replacing the `date:` line with a placeholder, the logs
are byte-identical.** Under that rule the saved log and the re-run are identical.
This is a stronger claim than revision 1's log could make, and deliberately so:
revision 1's check queries the live GitHub REST API, so its output moves with
py's run history, whereas revision 2's reads snapshots.

**Falsifiability, also executed.** A check that cannot fail is not evidence, so
the script was run once against a deliberately broken copy of the fixture (the
cron changed from `'17 6 1 * *'` to `'0 6 * * 1'`, i.e. ts's weekly value) in a
scratch directory outside this repository. It reported `ASSERT-FAIL` on
`on.schedule`, on the minute, on the day-of-month and on the day-of-week, and
exited `RESULT: FAIL`. The broken copy was discarded and is not part of the
evidence; what it establishes is that the passing run is an observation rather
than a formality.

**What revision 2 does not prove, stated at the width the added key demands.**
The revision-1 judgment audit accepted the form (b) check on a specific ground:
the recommended block was byte-identical to py's pinned block, so py's 134
post-guard runs were GitHub's own dispatcher executing the exact
recommendation. **That ground now covers the `push` half only.** No scheduled
run of the recommended block has executed anywhere, at any cadence: the nearest
observation is ts's 9 *weekly* runs on a *private* repository, which shows that
a cron fires and retries and shows the documented queue delay, but says nothing
about a monthly cadence, nothing about the 60-day rule (ts is exempt as a private
repository) and nothing about the fork default. So A6's runtime behavior and all
of A7 are documented-and-asserted, not observed. Whether "Use this template"
instantiation disables scheduled workflows the way a fork does remains
unestablished (Opus gap 5). No credential was created or used, no repository was
created or forked, no workflow was enabled or disabled, and the action was not
run: revision 2 made exactly two network requests, the two `GET`s of
`docs.github.com` recorded with URL, HTTP status and byte count in the snapshot
headers, and the script itself makes none.

**Evidence files added by revision 2** (revision 1's are untouched):
`review/evidence/r07-empirical-r2.log` (full run),
`review/evidence/r2-workflow-state-enum.json` (the REST `Workflow` schema),
`review/evidence/r2-disable-and-enable-workflows.txt` (the three quoted passages).
Fixtures and script: `review/empirical/r2/.github/workflows/update-contributors.yml`,
`review/empirical/r2/alternatives/hybrid-paths-ignore-under-schedule.yml`,
`review/empirical/r2/run-check-r2.sh`.

## Engines

- codex `raw/codex.md` (gpt-5.6-terra, 2026-09-05, sha256
  `fec48e36bb5a3183da6f2a133cdccc223fcaf722a49a3410e30fe1c45501af04`) —
  recommends weekly `schedule` (`17 9 * * 1`) plus `workflow_dispatch`, no
  push; runner-up py's push shape.
- opus `raw/opus.md` (claude-opus-5[1m], 2026-09-09, sha256
  `a2f5e9a652105d01d0256b1aa06390692282bedf6bce4823a7bf24224cc7dbfc`) —
  recommends `push` + `paths-ignore` + `workflow_dispatch`; runner-up the same
  plus a monthly backstop. **Revision 2 adopts Opus's runner-up**, on the
  condition Opus itself attached to it and on the owner's direction; the raw's
  cron value `17 6 1 * *` is the value now recommended.

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
weighs the schedule's silent-off state above either count. Revision 2 does not
reverse that weighing — a schedule is still not the primary trigger — but it
does accept 12 scheduled runs a year, and with them the auto-disable exposure,
for the retry they provide.

**Disagreement 3 — path filter under a schedule.** Codex: moot. Opus: invalid.
`actionlint` rejects it (step 3), settling for Opus. Revision 2 makes this
operative rather than academic, because its block now has a `schedule` key for
the filter to be wrongly placed under; the negative control was therefore re-run
against the revision-2 block (revision-2 check 3) and rejects it the same way.
(The revision-1 judgment audit observed at O4 that this is less a disagreement
than two readings of "moot" — Codex's block had no filter to place. The
observation stands; the executed answer is unaffected.)

**Disagreement 4 — cron minute.** Both raws independently choose minute 17 to
avoid the top of the hour; revision 1 carried it into the runner-up's backstop
cron and revision 2 carries it into the recommendation. ts's observed delays
show the offset does not remove queue delay, which is why criterion A6 is
written as a bound on staleness rather than as a latency guarantee.

**Agreements.** Both raws: keep `workflow_dispatch` unconditionally; crate
figures inapplicable to a pattern item; no `CONFLICT:`; no `BASELINE-REVIEW:`;
no fixed parameter affected.

**Uncertainty.** No Rust project surveyed runs any contributors bot, so there
is no Rust convention to defer to. The template's future merge rate is a
judgment; if it exceeds about one qualifying merge a week the volume argument
for C strengthens (re-verify trigger). Whether template instantiation disables
schedules like a fork is unconfirmed (Opus gap 5) — and revision 2 raises the
stakes of that gap rather than settling it, because the recommendation is now a
scheduled workflow and the fork rule therefore reaches every consumer's copy if
instantiation counts as forking. Issue-responsiveness
medians for the surveyed actions were not computed by either raw; none is a
dependency of this template. Codex's retrieval dates are 2026-09-05, Opus's
2026-09-09 (UTC), the synthesizer's 2026-09-09 UTC at revision 1 and
2026-09-16 UTC at revision 2 — which is 2026-09-15 in this host's local time,
the date revision 2 carries in its title, and the two are named apart wherever
either appears rather than being rounded to one.

**What P03 must validate, listed here because every decision is a proposal the
implementation phase proves.** Items 1 to 3 are unchanged from what revision 1
left open; items 4 to 6 are new at revision 2 and all concern the `schedule`
half, none of which has ever executed.

1. A3 — a `workflow_dispatch` run is created on demand. Needs a live repository
   and R21's credential.
2. A4 — recognition latency is bounded by the merge when a push run succeeds.
3. A1 and A2 against the template's own history rather than py's, once the
   template exists.
4. A6 — a run with `event: schedule` appears on the first of the month, and the
   action is an idempotent no-op when the list has not changed. This is the
   first execution of a scheduled run of this block anywhere.
5. A7 — that a workflow in `disabled_inactivity` or `disabled_fork` really does
   suppress the `push` trigger. This decision asserts it from the REST schema's
   single `state` field, which is strong documentary evidence and is not an
   observation; the cheap version of the check is `gh workflow disable
   update-contributors.yml` in a sandbox repository followed by a qualifying
   push, which needs neither 60 idle days nor a fork.
6. Whether "Use this template" instantiation disables scheduled workflows the
   way a fork does (Opus gap 5). If it does, the template's setup documentation
   must tell every consumer to enable the workflow as a first step, and that
   sentence is P03's to write.

## Supersedes

The published revision this one replaces, reproduced verbatim and in full. It is the file `research/topics/07-contributors-bot-trigger-cadence/DECISION.md`, 26203 bytes, sha256 `0b3dde8f9a15f22e60a01542065c53c122881e8c48bf3ee6c172ba5b70499346` — the hash the owner acceptance row, both audits and this run's publication receipt all cite. It was approved by `review/audit-codex.md` (empirical; actor `audit-codex-2026-09-05T162400Z-58ba22bff8ca`, model `gpt-5.6-terra`, family openai, `verdict: approve`) and by `review/audit-fable.md` (judgment; actor `audit-fable-2026-09-05T162400Z-58ba22bff8ca`, model `claude-fable-5-1`, family anthropic, `verdict: approve`). It is quoted rather than summarised so that every sentence revision 2 edited can be read in its original wording — in particular the `on:` block without a `schedule` key, the five essential behaviors, the five acceptance criteria, the "no silent-off" ground and the ranked runner-up. The fence below is four backticks because the quoted file contains three-backtick fences of its own; it is presentation only, and no byte inside it is altered. The quoted document's own headings are historical text, not sections of this document.

````markdown
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
````
