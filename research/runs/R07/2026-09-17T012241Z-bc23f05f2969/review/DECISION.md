# 2026-09-16 — R07 — Contributors-bot trigger cadence — DECISION (revision 4)

**What changed in revision 4, and why.** The H1 title line and nothing else:
`# R07 — Contributors-bot trigger cadence — DECISION (revision 3, 2026-09-15)`
becomes the date-first line above.
**Why:** `scripts/research_runner.py`'s `check_history` admits a revision of a
published decision only when an H1 or H3 heading that *begins* with a date sits
before the **first substring occurrence** of `## Supersedes`, and at revision 3
that first occurrence was the prose mention on line 99 — inside the revision-2
audit-finding list, 1,001 lines above the `## Supersedes` heading itself — so
the region the check inspected held no dated heading at all; a date-first H1 on
line 1 is before every mention, this note included.
**No other byte moved:** the recommendation, the evidence and its scripts and
logs, the `## Parameters` lines and the `## Supersedes` payload are
byte-identical to revision 3.

**What changed in revision 3, and why.** One thing, and it is a reversal: the
recommended `on:` block **loses** the monthly `schedule` backstop revision 2
added and is again revision 1's block — `push` to `main` with `paths-ignore` on
the two generated files, plus `workflow_dispatch`, and **no `schedule` key**.
**The owner directed the reversal**, on a fact revision 2 itself established.
`docs/planning/p02/owner-decisions.md`, section *"10. The Wave 0 review walk --
IN PROGRESS from 2026-09-14"*, row `W0-R07b`, records it:

> | W0-R07b | R07 backstop, re-put on a corrected fact | A revert to push-only |
> 2026-09-15 | → revision 3 | supersedes W0-R07: GitHub keeps one state per
> workflow file, so a `schedule` key exposes the whole file to the 60-idle-day /
> fork switch-off; the backstop was declined for converting a bounded lag into a
> silent-off state |

The ruling it supersedes is `W0-R07`, of the same day, in the same section — the
direction revision 2 implemented:

> | W0-R07 | R07 contributors-bot-trigger-cadence | A accept + add the monthly
> backstop | 2026-09-15 | `0b3dde8f…` → revision 2 | the decision's runner-up E
> condition (R21 settles on an expiring credential) was already met; owner
> directs the two-line backstop now |

`docs/port/OWNER-REVIEW.md`, section *"Wave 0 owner acceptances (recorded from
2026-09-14)"*, the `R07` row, carries both rulings together and re-binds the
owner's **accept** of revision 1 at sha256
`0b3dde8f9a15f22e60a01542065c53c122881e8c48bf3ee6c172ba5b70499346` (dated
2026-09-15) at revision 3: "W0-R07 option A directed a monthly backstop; W0-R07b
(same day) WITHDREW it after the controller's premise about GitHub's auto-disable
scope was found wrong — the workflow stays push + `workflow_dispatch`, no
`schedule`; revision 3 records the declined backstop and its reason; re-bound at
revision 3". The accepted block and the recommended block are once more the same
bytes, so the acceptance re-binds rather than being staled.

**The fact that reversed the direction is revision 2's own finding, and revision
3 keeps every byte of its evidence.** Revision 2 was commissioned with the
premise that the 60-idle-day auto-disable would apply "to the schedule half only"
and that "the push half survives it". It established that GitHub documents the
opposite: the REST `Workflow` schema gives a workflow **one** required `state`
field whose enum is `active | deleted | disabled_fork | disabled_inactivity |
disabled_manually`
(https://docs.github.com/en/rest/actions/workflows?apiVersion=2022-11-28,
retrieved 2026-09-16 UTC (2026-09-15 local) by this synthesizer, HTTP 200,
359,400 bytes; snapshot `review/evidence/r2-workflow-state-enum.json`), and the
disable-and-enable page defines the operation over the whole file — "Disabling a
workflow allows you to stop a workflow from being triggered without having to
delete the file from the repo" — with no trigger named and none excepted
(snapshot `review/evidence/r2-disable-and-enable-workflows.txt`, passage 0). A
workflow in `disabled_inactivity` or `disabled_fork` therefore fires on **no**
event, `push` and `workflow_dispatch` included. Both snapshots, both assertions
and the criterion revision 2 wrote from them (A7) are kept here — **restated as
the recorded reason the backstop is declined, not as a property of the
recommendation**, because a block with no `schedule` key is outside both rules
and has no A7 to observe. They are re-asserted by revision-3 check 4.

**Why that fact decided it.** Shown the corrected scope, the owner declined the
backstop: it would convert a **bounded lag** into a **silent-off state**, and the
silent-off state was this decision's own first ground for choosing push over
schedule at revision 1. The bounded lag is real and is now measured rather than
described: of the 134 post-guard push runs of py's identical `push` half, 12
concluded `failure` and 122 `success` (revision-2 check 6, recounted
independently at revision-3 check 3 from
`review/evidence/py-update-contributors-runs.json`); an unretried failure leaves
the list stale until the next qualifying merge or a manual run. The silent-off
state is the whole-workflow switch-off above, whose two preconditions — 60 days
with no repository activity in a public repository, and a fork of a public
repository — a public, forkable template is the artifact most exposed to.

**The expiring-credential trigger is answered by this reasoning, not by adding
the backstop.** Revision 1 ranked option E (this block plus a monthly backstop)
runner-up and wrote that it "wins if R21 settles F061 on a credential that can
expire or be revoked". R21 is published
(`research/topics/21-contributors-bot-credential-source/DECISION.md`) and settles
F061 on App credentials plus "a dedicated repository secret holding a
fine-grained PAT (Contents: write, Pull requests: write, Issues: write, single
repository, explicit expiry)", so the trigger **fired**. It was put to the owner
on that basis (W0-R07), implemented at revision 2, and then answered on the
corrected fact (W0-R07b): the answer to a credential that can expire is not a
scheduled retry that can switch the entire workflow off, because a scheduled
retry run made with an expired credential fails exactly as the push run did while
the `schedule` key it needs exposes the working trigger to a state nothing
retries. What the recommendation offers instead is what revision 1 already
carried and revision 3 restates: a failed push run is a red run on a merge
commit, `workflow_dispatch` is the one-command recovery, and the credential's own
expiry is R21's to monitor. The `re-verify:` line records the trigger as fired
and resolved, and the ranked runner-up below carries a new condition that
reflects what is now known.

**Two findings against revision 2, both closed here.**
`review/audit-codex.md` is the **empirical audit of revision 2** (actor
`audit-codex-2026-09-05T162400Z-58ba22bff8ca-r2`, model `gpt-5.6-terra`, family
openai, `verdict: reject`, citing sha256
`85beea991e84be1321b6b8cc55cd934c7049f621c38591394e2fa795234710a4`); the audit
that approved revision 1 is `review/audit-codex.r1.md`, and
`review/audit-fable.md` is revision 1's approving judgment audit. The revision-2
rejection's two findings:

1. **`## Supersedes` was not byte-verbatim.** Revision 2 wrapped the published
   revision-1 bytes in explanatory paragraphs and a four-backtick
   ````markdown` fence, so the section payload hashed to
   `1469280072fd615a85c1f883e42d8117d4ac7e79c832ec2aac1c48dee4de261d` rather
   than to the published `0b3dde8f…`. **Closed:** this revision's `## Supersedes`
   ends with the published file's 26,203 bytes reproduced **unfenced and
   unwrapped**, so that `tail -c 26203` of this decision is the published file
   byte for byte; revision-3 check 5 asserts that hash. The dated entries for
   revisions 2 and 3 precede the preserved bytes, which is the form R42 and R18
   use for the same section.
2. **The 31-day maximum was stated as a guarantee.** Revision 2 wrote that a
   failed or missed push run is retried "within 31 days" and that staleness is
   bounded at 31 days, where its check proved only the cron expression: GitHub
   documents that queued scheduled jobs "may be dropped" under high load, and a
   scheduled run made with an expired credential fails like any other.
   **Closed:** the backstop is not recommended, and everywhere the declined
   option is described this revision says a monthly cron schedules **one retry
   attempt a month** and claims no maximum staleness and no successful retry.

Three non-blocking observations from revision 1's judgment audit are also carried
or closed: O2 (py's 12-of-134 failure figure, retrieved but unreported at
revision 1) is now in the text twice; O6 (visibility does not "cut the same way"
for ts, which is private) keeps revision 2's correction; O3 (A5's second clause
was satisfied by construction and never executed) is closed — revision-3 check 2
executes it against the recommended fixture.

**What did not change.** The primary trigger and its `paths-ignore` guard, the
settled ledger row's identity (F026), every `- assumes` parameter line
(byte-identical to `docs/port/PARAMETERS.md`), the fitness-gate statements,
`BASELINE-REVIEW: none`, `CONFLICT:` none, and every figure and quotation
revisions 1 and 2 drew from their own empirical checks. Revision 1's scripts,
fixtures and logs under `review/empirical/` and `review/evidence/`, and revision
2's `review/empirical/r2/run-check-r2.sh` with its log
`review/evidence/r07-empirical-r2.log` and its two documentation snapshots, are
left **byte-identical**; revision 3 adds `review/empirical/r3/run-check-r3.sh`
and a new log rather than editing either.

**Where the document was changed, enumerated mechanically rather than by
reading.** Before editing, `/usr/bin/grep -niE` was run over the revision-2 file
for `schedule|cron|backstop|silent-off|auto-disab|60.day|disabled|runner-up|A6|A7|31 days|behavior 6|SELECTED|revision 2`,
restricted to lines 1-870 (everything above `## Supersedes`, whose payload is
frozen). It returned **211 lines**: 1 3 4 8 9 10 11 15 17 19 24 33 35 36 38 39 49
50 51 55 68 69 78 83 84 91 92 101 110 111 124 127 128 134 136 137 139 149 155 161
162 163 164 169 171 173 194 195 199 200 201 202 204 205 206 208 212 234 237 238
239 241 245 246 252 253 254 255 256 258 259 265 269 270 271 282 283 286 288 289
291 293 300 301 302 307 316 318 325 337 338 341 346 351 352 353 354 357 366 372
374 384 386 398 399 400 423 429 446 448 449 451 453 461 463 466 468 469 470 471
472 473 478 480 482 495 518 519 520 546 557 559 560 577 578 590 605 618 624 645
647 650 653 656 685 689 692 694 696 697 698 699 700 701 704 705 707 708 710 712
715 716 718 721 739 743 745 750 754 757 758 759 760 761 763 764 768 773 779 780
781 783 784 785 787 790 791 794 798 800 805 806 808 809 810 813 814 815 822 823
824 825 836 838 843 844 849 857 859 860 866. That list was the work queue; the
whole region above `## Supersedes` was rewritten from it rather than patched, and
the same search was re-run against this file afterwards to confirm that every
surviving occurrence describes either the recommendation (which has no
`schedule`) or the declined option (named as declined) and carries its
conditions. **Deliberately left byte-identical**, four regions: revision 1's
`## Empirical check` part 1, because that log is revision 1's and must stay as
the two approving audits read it; revision 2's `### Revision 2` subsection,
including its observed-output block — its check-6 assertion line still ends in
revision 2's own words about a 31-day bound, and it is quoted with an ellipsis
here as it was there, because the log is a record of what revision 2 ran and is
not edited after the fact; the `A`, `C` and `D` rows of the alternatives table;
and the four `- assumes` parameter lines. Two phrases changed meaning rather than
wording and are flagged where they appear: "no silent-off state" is again a
property of the recommendation, and "SELECTED" moves from row E back to row A.

**Revision history.**

| Revision | Date | What it did |
|---|---|---|
| 1 | 2026-09-08 | First synthesis. Recommended `push` + `paths-ignore` + `workflow_dispatch`, no `schedule`; ranked E (the same block plus a monthly backstop) runner-up with a stated winning condition. Approved by `review/audit-codex.r1.md` (empirical; actor `audit-codex-2026-09-05T162400Z-58ba22bff8ca`, model `gpt-5.6-terra`, family openai, `verdict: approve`) and by `review/audit-fable.md` (judgment; actor `audit-fable-2026-09-05T162400Z-58ba22bff8ca`, model `claude-fable-5-1`, family anthropic, `verdict: approve`), both citing sha256 `0b3dde8f9a15f22e60a01542065c53c122881e8c48bf3ee6c172ba5b70499346`. Published at `research/topics/07-contributors-bot-trigger-cadence/DECISION.md`, byte-identical. Accepted by the owner 2026-09-15 (W0-R07 option A). |
| 2 | 2026-09-15 | Added the owner-directed monthly `schedule` backstop (option E) to the recommended `on:` block and, against the brief it was given, established that GitHub keeps one `state` per workflow file, so the added key exposed the whole workflow — `push` half included — to the 60-idle-day and fork switch-offs. New evidence: `review/empirical/r2/run-check-r2.sh` → `review/evidence/r07-empirical-r2.log`, plus two documentation snapshots. Never published: `review/audit-codex.md` rejected it at sha256 `85beea99…` on two findings, and the owner withdrew the direction the same day (W0-R07b) once shown the corrected scope. |
| 3 | 2026-09-15 | This revision. Restores revision 1's `on:` block, essential behaviors and acceptance criteria as the recommendation, on owner ruling W0-R07b; keeps revision 2's auto-disable evidence, snapshots and criterion A7 as the recorded reason the backstop is declined; keeps the 12-of-134 failed-run figure, the visibility correction and option E's corrected silent-off cell; re-ranks E as runner-up on a new winning condition; closes both revision-2 audit findings. New evidence: `review/empirical/r3/run-check-r3.sh` → `review/evidence/r07-empirical-r3.log`. Supersedes the published revision 1, reproduced verbatim and unfenced at the end of `## Supersedes`. |
| 4 | 2026-09-16 | Title-line-only retitle, made so that `check_history` admits this revision: the H1 becomes date-first and the revision number becomes 4. Row 3 above, not this row, records the last substantive change — no recommendation, evidence, parameter line, script, log or `## Supersedes` byte differs from revision 3. |

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

**There is no `schedule` key, and its absence is now a decision taken twice.**
Revision 1 omitted it because `push` has no documented auto-disable rule while
`schedule` has two. Revision 2 added a monthly backstop on owner direction
(W0-R07) and established, in doing so, that the two rules attach to the **whole
workflow file** rather than to the scheduled trigger alone. On that corrected
fact the owner withdrew the direction (W0-R07b) and revision 3 removes the key
again. The declined option is not deleted from this record: it is ranked
runner-up below, with the evidence that decided against it and a new winning
condition.

This decision is a **proposal validated in the implementation phase** (owner
ruling, 2026-09-10). It records what the research found and what it recommends;
P03 builds `.github/workflows/update-contributors.yml` and P03's own CI proves
the recommendation. `## Engines` lists what P03 must validate. A decision that
does not survive implementation is revised against this recorded research, not
researched again from scratch.

Ledger rows settled: **F026** (`docs/port/COMMONALITY.md:32`, origin
`different`, verdict `DIVERGENT`) — value: push-on-change with a path filter
plus manual dispatch. F060 is retained unchanged and F061 stays with R21.

Cross-repo answer (owner review 2026-09-04: R07 harmonize = yes, class A
setting drift): one cadence for all three repositories, and it is this one.
py is unchanged, as it was under revision 1 and was not under revision 2. ts's
weekly cron is a justified-looking but unsupported departure: its own file header
at the pinned SHA (`cb1cbcb2e88b898e8c081b0abbfabc1630079c00`,
`.github/workflows/update-contributors.yml:33-39`) records that "neither the
source file nor contributors-please-action's own documented usage example runs
on a schedule", and the evidence below shows the noise it was avoiding is small
at a template's merge rate while the failure modes it took on are documented
and observed — and now also shows that those failure modes reach the whole file,
not the cron alone. Changing ts is follow-on work; this decision supplies the
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

**Essential behaviors (must agree in py, ts, rs).** These are revision 1's five,
restored:

1. Regeneration is automatic; no human has to remember to run it.
2. The result reaches `main` only through a reviewable PR (F060).
3. The workflow is loop-free: merging the bot's own PR must not start another
   bot run that opens another PR.
4. A maintainer can force a regeneration at any time without a code change.
5. The mechanism has no silent-off state in the repository shape this template
   ships as (public, forkable, often quiet).

**The sixth behavior revision 2 added, and why revision 3 does not carry it.**
Revision 2 wrote a behavior 6 — "a failed or missed regeneration is retried
without a human noticing it" — and made the monthly backstop its mechanism. It
is dropped, because the only mechanism available for it inside the `on:` block
is a `schedule` key, and that key costs behavior 5 for the whole file: the
retry would be bought by putting the trigger that does the work inside GitHub's
two automatic-disable rules. What replaces it is not silence about the failure
but the recovery revision 1 recorded and this revision quantifies: 12 of 134
post-guard push runs failed, each failure is a red run on a merge commit rather
than an absence, `workflow_dispatch` re-runs it in one command, and R21 owns the
expiry monitoring of the credential that makes such a failure more likely than
it was.

**What may vary.** Nothing in the `on:` block is language-bound; the action
reads git history on `ubuntu-latest`. The only repository-specific input that
cuts the same way for py, ts and rs is merge rate. **Visibility does not**, and
the sentence revision 1 wrote is corrected here rather than repeated: ts is
`private`, so neither auto-disable rule currently reaches it, while py and rs
are public (`gh api repos/smorinlabs/ts-launch-blueprint`, the revision-1
judgment audit's observation O6, confirmed against
`GET https://api.github.com/repos/smorinlabs/rs-launch-blueprint`, retrieved
2026-09-09 UTC). For ts the cross-repo recommendation therefore rests on the
README, the header concession, the observed delays and failures and the noise
figures, not on the silent-off rule. Adjacent lines of the same file that vary
by other decisions: credential inputs (R21), permission style (R08), action pin
style (R20), `runs-on` indirection (R09).

**Observable acceptance criteria.** These are revision 1's five, restored:

- A1 — merging a qualifying PR to `main` creates exactly one workflow run
  within seconds, with `event: push`, and one bot PR if the list changed.
- A2 — merging the bot PR (which touches only `CONTRIBUTORS.md` and
  `.contributors.jsonl`) creates zero runs.
- A3 — `gh workflow run update-contributors.yml` creates a run with
  `event: workflow_dispatch`.
- A4 — recognition latency is bounded by the merge, not by a clock, whenever a
  push run succeeds. (The trailing clause is revision 2's and is kept
  deliberately, beyond what this revision was asked to restore: with 12 failed
  runs in 134 recorded in this document, revision 1's unqualified wording would
  state the criterion more absolutely than the evidence supports.)
- A5 — `actionlint` accepts the file; the `paths-ignore` list equals the
  action's `output-file` and `state-file` inputs.

A1, A2 and A5 were verified in `## Empirical check` (A1 and A2 against the real
run history of py's production workflow, which runs the identical block; A5's
first clause with `actionlint` at revision 1 and again at revision 3, its second
clause executed for the first time at revision 2 and re-executed at revision 3
against the restored fixture, closing the revision-1 judgment audit's observation
O3). A3 and A4 are proposed checks for the first integration on a live
repository; they need R21's credential decision to be executable.

**Revision 2's A6 and A7 are not criteria of this recommendation, and this is
why.** A6 ("on the first day of each month a run appears with `event: schedule`")
has nothing to observe: there is no `schedule` key. A7 recorded that a workflow
in `disabled_inactivity` or `disabled_fork` reports one workflow-level `state`
and fires on **no** trigger until re-enabled, `push` and `workflow_dispatch`
included. That statement is still true of GitHub, is still asserted against the
retrieved snapshots (revision-3 check 4), and is **kept here as the reason the
backstop is declined** rather than as a behavior this recommendation must expect:
with no `schedule` key, neither `disabled_inactivity` nor `disabled_fork` has a
precondition this workflow can meet, so the criterion describes the option under
`Ranked runner-up`, not the recommendation. The one documented way this workflow
can still reach a disabled state is `disabled_manually` — a maintainer's own
deliberate act, recoverable by the same one step, and not a silent-off state.

**Architectural alternatives compared before any tool question.**

| Architecture | Authoritative signal | Latency | Loop guard | Silent-off state | Run volume |
|---|---|---|---|---|---|
| **A. Event-driven: `push` to `main` + `paths-ignore` + dispatch (py, action README) — SELECTED** | the merge | seconds | `paths-ignore` on the generated files | none documented | one short job per qualifying push |
| B. `push` without a path filter (`akhilmhdh/contributors-readme-action` README) | the merge | seconds | none: the bot merge re-fires the bot | none | A plus one per bot merge |
| C. Time-driven: weekly `schedule` + dispatch (ts) | the clock | up to 7 days plus queue delay | not needed | yes: auto-disabled after 60 days without activity in a public repo, disabled by default in forks | 52 per year regardless of activity |
| D. Daily `schedule` (`BobAnkh/add-contributors` README; action at-risk) | the clock | up to 1 day | not needed | yes, as C | 365 per year |
| E. Hybrid: A plus a monthly `schedule` backstop (`wow-actions/contributors-list` README shape) — directed at revision 2, **declined at revision 3**, ranked runner-up | merge, clock as retry | seconds | as A, on the `push` half; the `schedule` half needs none | **the whole workflow**, on `schedule`'s two rules, because `state` is one field of the workflow file and not one per trigger (revision 2's A7) | A plus 12 per year |
| F. Comment-driven (All Contributors bot) | a maintainer's comment | human | none | yes, silently unrecognized | on demand |
| G. `workflow_run` chained after CI | CI completion | after CI | as A | inherits CI's | as A plus a second failure surface |

Row E's *Silent-off state* cell is the one revision 2 corrected: revision 1 wrote
"backstop only" there, on the premise the push half survived the rules. Rows A,
C and D are left byte-identical — A is the architecture the recommendation is
built on and its row is accurate as written; C and D describe schedule-only
architectures, where the silent-off state was never in question.

Documented facts that separate them (GitHub, normative):

- Path filters exist only for `push`, `pull_request` and `pull_request_target`
  (workflow-syntax reference, section
  `on.<push|pull_request|pull_request_target>.<paths|paths-ignore>`,
  https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax,
  retrieved 2026-09-05 by Codex, 2026-09-09 by Opus). `actionlint` 1.7.12
  rejects `paths-ignore` under `schedule` (`## Empirical check`, step 3, and
  again as revision-2 check 3 against the hybrid block). The MEDIUM question is
  therefore settled: under a schedule a path filter is not moot, it is invalid;
  under a push trigger it is the loop guard the action's README requires in place
  of `[skip ci]`. Nothing is lost by the recommendation's omission of a schedule
  guard, because it has no schedule.
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
  retrieved 2026-09-09 by Opus, re-read 2026-09-09 UTC by the synthesizer and
  snapshotted 2026-09-16 UTC at revision 2; the page names no warning before
  disabling, and none is asserted here). Also: "The `schedule` event can be
  delayed during periods of high loads of GitHub Actions workflow runs. High load
  times include the start of every hour. If the load is sufficiently high enough,
  some queued jobs may be dropped."
  (https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows,
  retrieved 2026-09-05 by Codex, 2026-09-09 by Opus and by the synthesizer).
  Observed on ts: every one of 9 weekly runs started 1 h 01 min to 7 h 41 min
  after its 06:17 UTC slot (`## Empirical check`, step 5). The dropped-job
  sentence is why no cron, monthly or weekly, is described in this document as a
  staleness bound: it schedules an attempt.
- `rs-launch-blueprint` is `visibility: public`
  (`GET https://api.github.com/repos/smorinlabs/rs-launch-blueprint`,
  retrieved 2026-09-09 UTC), so the 60-day rule would apply to the target if the
  workflow carried a `schedule` key. ts is `private`, so its clean weekly history
  is evidence that the private-repo exemption works, not that a schedule is safe
  for a public template. (Revision 1 wrote that "the only repository-specific
  inputs are merge rate and visibility, and both cut the same way for py, ts and
  rs". Visibility does not, as the revision-1 judgment audit observed at O6.
  Corrected under **What may vary** rather than repeated.)
- **Disabling is a property of the workflow, not of one trigger.** The REST
  `Workflow` schema declares `state` as a required field whose enum is
  `["active","deleted","disabled_fork","disabled_inactivity","disabled_manually"]`
  (https://docs.github.com/en/rest/actions/workflows?apiVersion=2022-11-28,
  retrieved 2026-09-16 UTC (2026-09-15 local) by the synthesizer, HTTP 200,
  359,400 bytes; snapshot `review/evidence/r2-workflow-state-enum.json`,
  asserted in revision-2 check 5 and again in revision-3 check 4), and the
  disable-and-enable page says the same thing in words: "Disabling a workflow
  allows you to stop a workflow from being triggered without having to delete the
  file from the repo" (same retrieval, snapshot passage 0) — the object is the
  workflow, and no trigger is named or excepted. The documented recovery is one
  step — `gh workflow enable WORKFLOW`, or **Enable workflow** in the Actions
  sidebar (same page, snapshot passage 2). **This is the fact that decides
  between the recommendation and option E**, and it decides it twice over: it is
  why revision 2 could not claim what revision 1 claimed, and — once the owner
  saw it (W0-R07b) — why the `schedule` key is gone again and revision 1's claim
  is restored intact.

**Why the selected design preserves each principle.** (1) automatic: the merge
itself is the trigger. (2) PR-mediated: unchanged, F060. (3) loop-free: the
bot PR touches only the two generated files, so its merge matches every
`paths-ignore` pattern; verified on the 22 post-guard commits in py's production
history that touched only the generated files (20 bot merges, 2 hand edits),
with zero loop runs (step 5b). (4) on demand: `workflow_dispatch`,
kept unconditionally (LOW question). (5) no silent-off: `push` has no
documented auto-disable rule; `schedule` has two, and — this is what revision 2
established and what makes the ground stronger than revision 1 could state it —
those two rules act on the **workflow file**, so any block containing a
`schedule` key puts its `push` trigger inside them as well. A public template
that goes quiet for 60 days or is forked is the artifact most exposed to that,
and the recommended block stays outside it by having no `schedule` key at all.

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

**What the declined backstop would have bought, and what it would have cost.**
Bought: **12 scheduled attempts a year**, one on the first of each month at 06:17
UTC plus GitHub's queue delay, free on a public repository and each an idempotent
no-op when nothing changed. What those attempts would retry is measured on py's
history for the identical `push` half: of 134 post-guard push runs, 12 concluded
`failure` and 122 `success` (revision-2 check 6; recounted independently at
revision-3 check 3, which reproduces both figures). ts's scheduled history shows
retrying working from the other side: 3 of its 9 weekly runs concluded `failure`
(2026-07-13, 07-20, 07-27) and the cron retried through all three before
succeeding on 08-03. **Cost:** the `schedule` key the retry needs puts the whole
workflow file — `push` and `workflow_dispatch` included — inside
`disabled_inactivity` and `disabled_fork`. Stated at the width the evidence
supports: a monthly cron schedules one retry attempt a month; it is not a
staleness bound and not a guaranteed retry, because GitHub documents that queued
scheduled jobs may be dropped under high load and because a run made with an
expired credential fails exactly as the push run did. Weighed that way the
exchange is a bounded lag — stale until the next qualifying merge or one
`workflow_dispatch`, with a red run on the merge commit as the signal — against a
state in which nothing fires at all and no run is red because no run exists. The
owner's ruling W0-R07b takes the bounded lag.

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
Revision 3 leaves that sentence byte-identical, including gate 1. The owner's
licence ruling of 2026-09-12 (Q4 as superseded by Q7.B) strikes gate 1 from every
item's evaluation, but it changes nothing here: gate 1 already read
`inapplicable` on its own ground, which is that this item selects no crate, tool
or dependency of any kind — it changes three keys of one YAML block — so there is
no licence to be compatible or incompatible with. The row is recorded, not
deleted, as the ruling requires. Removing the `schedule` key retires no candidate
and so reopens no gate, exactly as adding it introduced none.

**Reference implementations.** The action's README usage block; py's pinned
workflow (`b08bccf`, `.github/workflows/update-contributors.yml`); the fixture
`review/empirical/r3/.github/workflows/update-contributors.yml` in this run,
which is the recommended `on:` block over the inherited F060 job body with the
lines owned by R21, R08, R20 and R09 marked, and which revision-3 check 1 asserts
is **byte-identical** to revision 1's fixture
`review/empirical/.github/workflows/update-contributors.yml` — that identity is
the mechanical proof that revision 1's block is restored rather than retyped.
Revision 2's fixture `review/empirical/r2/.github/workflows/update-contributors.yml`
is left byte-identical and is now the reference for the **declined** option E
shape, not for the recommendation; the `wow-actions/contributors-list` README is
where that shape came from and is a shape reference rather than a production
observation.

**Migration implications (file-level).** One file,
`.github/workflows/update-contributors.yml`: the `on:` block above; no
`schedule:` key. Revision 2 incurred one documentation obligation that revision 3
**retires**: because the recommended workflow is not a scheduled workflow, the
template's setup page does not have to tell every consumer that GitHub disables
this file by default in a fork and automatically after 60 idle days, nor how to
re-enable it. Declining the backstop buys that back. The `paths-ignore` list must
equal the action's `output-file` and `state-file` inputs (`CONTRIBUTORS.md`,
`.contributors.jsonl`, also in `.contributors.yml` per F209); a rename in R47 or
later must update both in one change, and A5 exists to catch drift. The
`commit-message` input must not carry `[skip ci]` (py `:39-44`; README
loop-protection note). No Justfile, Cargo, ruleset or required-check change: this
workflow reports no required status check, so it does not consume R11's
`ci-job-structure`.

**Ranked runner-up.** **E — this block plus the monthly backstop
`schedule: - cron: '17 6 1 * *'`** (minute 17 rather than the top of the hour,
per GitHub's documented high-load advice; monthly rather than weekly or daily,
for 12 scheduled attempts a year). It was revision 1's runner-up, was the
recommendation at revision 2 under owner direction W0-R07, and is declined at
revision 3 under W0-R07b. **Its winning condition is new, and it is no longer the
one revision 1 wrote.** Revision 1's condition — that R21 settles F061 on a
credential that can expire or be revoked — has **fired and is spent**: R21 settled
exactly that way, the owner was asked, and the answer on the corrected fact was
to decline. E now wins only if GitHub changes one of the two documented facts
this comparison rests on: **(i) the auto-disable rules change so that a scheduled
trigger no longer disables the whole workflow** — a per-trigger `state`, or an
explicit exemption of `push` and `workflow_dispatch` from
`disabled_inactivity`/`disabled_fork` — **or (ii) path filters become available
on `schedule`.** The two limbs are not equal and the record should say so: limb
(i) removes the cost that defeated E, so it alone would restore E's case; limb
(ii) removes the other documented asymmetry between the two halves (today the
guard is valid under `push` and a syntax error under `schedule`) and is recorded
as a reopening trigger rather than as sufficient on its own. Second runner-up:
C, ts's weekly schedule alone; it wins only under a hard per-run budget on a
private, metered instantiation, which no evidence here supports. D, F and G are
not ranked, for the reasons in the table and the `workflow_run` note.

**Tradeoffs accepted.** Versus E: no automatic retry of a failed push run — and
the number is 12 of 134 post-guard runs on py's identical block, not an abstract
risk. Accepted, on the owner's ruling W0-R07b and on the reasoning it cites: each
failure is visible as a red run on a merge commit rather than as an absence,
`workflow_dispatch` is the one-command recovery, R21 owns the expiry monitoring
of the credential that makes such a failure likelier than it was, and the retry E
offers would be bought by moving the whole file inside two automatic-disable
rules — trading a bounded lag for a state in which no trigger fires and nothing
is red. Also accepted: recognition waits for the next qualifying merge whenever a
push run fails, which is what A4's trailing clause records. Versus C: more runs
on a busy repo; accepted because at the template's expected pace it is fewer, and
the thing C risks is the mechanism ceasing to exist. Versus F: no
contribution-type attribution; not this item's to choose (F060 fixes the tool).

**BASELINE-REVIEW findings:** none. F060 is retained unchanged; no
`COMMON → REUSE` or `ADOPT` row is challenged.

re-verify: 2027-09-15, or earlier when GitHub changes the scheduled-workflow auto-disable rules so that a scheduled trigger no longer disables the whole workflow file — a per-trigger `state` in the REST `Workflow` schema, or an explicit exemption of `push` and `workflow_dispatch` — or extends path filters to `schedule`, these being the two limbs of the ranked runner-up's winning condition; when `smorinlabs/contributors-please-action` releases past v1.3.9 with a changed trigger example or loop-protection guidance; when R47 or a later decision renames either generated file; when the first live instantiation establishes whether "Use this template" disables scheduled workflows the way a fork does (Opus gap 5, still open, and now bearing only on the declined option); or when the template's merge rate to `main` exceeds roughly one qualifying merge per week. The revision-1 trigger "when R21 settles F061 on an expiring credential (revisit the monthly backstop)" **fired and is resolved**: R21 published on 2026-09-10 settling F061 on App credentials plus a fine-grained PAT with an explicit expiry, the owner directed the backstop on 2026-09-15 (W0-R07), and on the corrected auto-disable scope withdrew it the same day (W0-R07b), which is what this revision records.

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

This section has three parts, one per revision, and none of them edits an
earlier one. **Part 1**, from *Form used and why* to *Evidence files*, is
revision 1's check, reproduced unchanged; its script, fixtures and logs are
byte-identical to what the two approving audits read. **Part 2**, *Revision 2*,
is revision 2's check of the block revision 2 recommended; it is kept whole, and
two of its six checks are still load-bearing at revision 3 — check 5, the
documentation facts that decide the backstop's cost, and check 6, py's
post-guard push-run outcomes. **Part 3**, *Revision 3*, checks the block this
revision recommends: that it is byte-identical to revision 1's fixture, that
`actionlint` accepts it, that it contains **no `schedule` key**, that the two
documentation facts still read as revision 2 recorded them, and that
`## Supersedes` ends with the published revision-1 bytes.

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

**Status of this part at revision 3.** Everything from here to *Evidence files
added by revision 2* is revision 2's own record of its own check, kept whole and
unedited, including the observed-output block — its check-6 assertion line ends
in revision 2's wording about a 31-day bound, and it is quoted here with the same
ellipsis it carried there, because a saved log is a record of what was run and is
not rewritten afterwards. What the revision-2 check still establishes for
revision 3 is checks 5 and 6: the documentation facts that decide how a
`schedule` key interacts with GitHub's automatic disabling, which are the ground
on which the backstop is declined (revision-3 check 4 re-asserts them), and py's
post-guard push-run outcomes, which are the bounded lag revision 3 accepts
(revision-3 check 3 recounts them independently). Checks 1 to 4 validated the
block revision 2 recommended; that block is **not** the recommendation at
revision 3, and revision-3 checks 1 and 2 validate the restored one in its place.

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

### Revision 3

**What it checks and why it is a third script.** Revision 3 changes the `on:`
block back, so neither revision 1's `actionlint` result (which covered this block
but is revision 1's saved output) nor revision 2's (which covered a different
block) can be cited for the recommendation as it now stands. Rather than edit
either earlier script — which would break the claim that each saved log is that
script's output, a claim three audit passes have relied on — revision 3 adds
`review/empirical/r3/run-check-r3.sh` and a new log. Five checks: (1) the
recommended fixture is **byte-identical** to revision 1's and `actionlint`
accepts it with no diagnostic line; (2) the block's structure field by field,
including an explicit assertion that it carries **no `schedule` key**, that the
strings `cron` and `schedule` appear nowhere in the file (comments included, so
no commented-out backstop is left behind), that criterion A5's second clause
holds, and that the one key separating the recommendation from the declined
option E is `schedule`; (3) an independent recount of py's post-guard push-run
outcomes; (4) the two documentation facts that decided the decline, re-asserted
against revision 2's snapshots; (5) that `## Supersedes` ends with the published
revision-1 bytes, which is the finding `review/audit-codex.md` raised against
revision 2. Every check asserts on content, a failure counter becomes the exit
status, and `set -o pipefail` is set. The script is offline and fetches nothing.

**Toolchain and OS.** macOS 26.4 arm64; `rustc 1.98.0 (88d9e12ae 2026-08-18)
(Homebrew)`; `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)` (no Rust is
compiled; recorded per the role contract); **`actionlint` 1.7.12** (the same
version revisions 1 and 2 used); Python 3.14.7 with PyYAML 6.0.3; `act` absent,
so this is form (b) as before. Log timestamp `2026-09-16T04:27:32Z`, which is
2026-09-15 in this host's local time — the date this revision carries — and
2026-09-16 UTC, the date revision 2's retrievals and snapshots carry.

**Working directory.**
`research/runs/R07/2026-09-05T162400Z-58ba22bff8ca/review/empirical/r3/`

**Command.**

```sh
./run-check-r3.sh 2>&1 | tee ../../evidence/r07-empirical-r3.log   # exit 0
```

**Observed output (the assertion lines; the full log is the evidence file).**

```text
== 1. the recommended fixture is revision 1's, restored byte for byte, and actionlint accepts it ==
sha256 revision-3 fixture: ecee9ea674107e7470c4b31449e6642798a09d87c172264716f68a95f1721a15
sha256 revision-1 fixture: ecee9ea674107e7470c4b31449e6642798a09d87c172264716f68a95f1721a15
assert-ok: the revision-3 fixture is byte-identical to revision 1's fixture, so the block is restored and not retyped
exit: 0
assert-ok: actionlint accepts the push + workflow_dispatch block (A5 clause 1)
assert-ok: actionlint emitted no diagnostic line for the recommended block

== 2. structure of the recommended on: block, asserted field by field ==
assert-ok: set of on: keys == ['push', 'workflow_dispatch']
assert-ok: the recommended block carries NO `schedule` key, so neither disabled_inactivity nor disabled_fork has a precondition this workflow can meet (owner ruling W0-R07b)
assert-ok: on.push.branches == ['main']
assert-ok: on.push.paths-ignore == ['CONTRIBUTORS.md', '.contributors.jsonl']
assert-ok: on.workflow_dispatch == None
assert-ok: paths-ignore == {output-file, state-file} == ['.contributors.jsonl', 'CONTRIBUTORS.md']
assert-ok: keys option E adds to the recommendation == ['schedule']
assert-ok: keys the recommendation adds to option E == []
exit: 0
assert-ok: /usr/bin/grep: the string `cron` and the string `schedule` appear nowhere in the recommended fixture, comments included

== 3. the lag the declined backstop would have retried: py's post-guard push-run outcomes ==
post-guard push runs (same scoping as revision 1 step 5b): 134
conclusions: {"failure": 12, "success": 122}
ts scheduled runs for comparison: {"failure": 3, "success": 6}
assert-ok: 134 post-guard push runs, the figure revisions 1 and 2 cite
assert-ok: 12 of those 134 push runs concluded `failure` — the bounded lag revision 3 accepts on owner ruling W0-R07b: each is a red run on a merge commit, recoverable with one `workflow_dispatch`, and no scheduled retry attempt is claimed to bound it
exit: 0

== 4. the two documentation facts that decided the decline, re-asserted against revision 2's snapshots ==
assert-ok: /usr/bin/grep: snapshot carries the sentence defining what disabling does — stop the workflow from being TRIGGERED, no trigger named or excepted
assert-ok: /usr/bin/grep: snapshot carries the 60-day inactivity sentence
assert-ok: /usr/bin/grep: snapshot carries the fork-default sentence
assert-ok: /usr/bin/grep: snapshot carries the documented re-enable command
-- the REST Workflow schema's state field, printed from the snapshot --
["active", "deleted", "disabled_fork", "disabled_inactivity", "disabled_manually"]
assert-ok: `state` is ONE required field of the whole workflow file, whose enum carries disabled_fork and disabled_inactivity; there is no per-trigger state, so a `schedule` key would expose the push trigger to both rules. This is the fact the owner ruled on (W0-R07b) and the reason option E is declined rather than selected; the recommended block, having no `schedule` key, meets neither rule's precondition
exit: 0

== 5. ## Supersedes ends with the published revision-1 bytes (audit-codex.md finding 1) ==
published sha256:      0b3dde8f9a15f22e60a01542065c53c122881e8c48bf3ee6c172ba5b70499346  (26203 bytes)
tail -c 26203 of DECISION.md: 0b3dde8f9a15f22e60a01542065c53c122881e8c48bf3ee6c172ba5b70499346
assert-ok: the published file still hashes to the sha256 the owner acceptance and both revision-1 audits cite
assert-ok: the published file is 26203 bytes
assert-ok: the last 26203 bytes of this run's DECISION.md are the published revision 1, byte for byte and with nothing after them — unfenced and unwrapped, which is what revision 2 failed
assert-ok: /usr/bin/grep: DECISION.md carries the `## Supersedes` heading that opens those bytes

overall failed assertions: 0
RESULT: PASS
```

**Reproducibility, established by re-running rather than asserted.** The script
was re-run immediately after the log was saved and the two were diffed. Exactly
**one line** differs — the `date:` header. Nothing else moves, because every
input is a file in this repository: the two fixtures, the declined option's
fixture, the two documentation snapshots, the two run-history JSONs, this
decision and the published one. **The comparison rule is therefore: two runs of
this script agree when, after replacing the `date:` line with a placeholder, the
logs are byte-identical.** Under that rule the saved log and the re-run are
identical. One consequence is worth stating because check 5 reads this file:
edits anywhere above `## Supersedes` change the file's length but not its last
26,203 bytes, so check 5's hash is stable against any later revision that leaves
the preserved bytes alone.

**Falsifiability, also executed.** A check that cannot fail is not evidence, so
the script was run once against a deliberately broken copy of the fixture (the
declined backstop, `schedule: - cron: '17 6 1 * *'`, pasted back into the `on:`
block) in a scratch directory outside this repository. It reported `ASSERT-FAIL`
on the fixture-identity hash, on the key set, on the explicit no-`schedule`
assertion, on the `/usr/bin/grep` for `cron|schedule`, and on the option-E key
difference, and exited `RESULT: FAIL`. The broken copy was discarded and is not
part of the evidence; what it establishes is that the passing run is an
observation rather than a formality.

**What revision 3 does not prove.** The same limits revision 1 recorded, and they
are the limits of a block that is byte-identical to py's pinned block: the action
was not executed and no bot PR was opened, so A3 and A4 remain proposed checks
needing a live repository and R21's credential. What revision 3 *does* recover,
and revision 2 could not claim, is the revision-1 judgment audit's ground for
accepting a form (b) check on this item: the recommended block is once more
byte-identical to py's block at `b08bccf` (check 1 establishes identity with
revision 1's fixture, and that fixture's `on:` block is the one the audit
compared against py's pinned file), so py's 134 post-guard runs are GitHub's own
dispatcher executing the exact recommendation rather than a local model of it.
The auto-disable rules and the fork default remain documented and unreproduced —
no repository was left idle for 60 days and none was forked — but at revision 3
they bear on the declined option rather than on the recommendation. Whether "Use
this template" instantiation disables scheduled workflows the way a fork does is
still unestablished (Opus gap 5), and now matters only if option E is ever
revisited. No credential was created or used, no repository was created or
forked, no workflow was enabled or disabled, and the action was not run: revision
3 made **no** network requests at all.

**Evidence files added by revision 3** (revisions 1's and 2's are untouched):
`review/evidence/r07-empirical-r3.log` (full run). Fixture and script:
`review/empirical/r3/.github/workflows/update-contributors.yml` (a byte-identical
copy of revision 1's fixture), `review/empirical/r3/run-check-r3.sh`.

## Engines

- codex `raw/codex.md` (gpt-5.6-terra, 2026-09-05, sha256
  `fec48e36bb5a3183da6f2a133cdccc223fcaf722a49a3410e30fe1c45501af04`) —
  recommends weekly `schedule` (`17 9 * * 1`) plus `workflow_dispatch`, no
  push; runner-up py's push shape.
- opus `raw/opus.md` (claude-opus-5[1m], 2026-09-09, sha256
  `a2f5e9a652105d01d0256b1aa06390692282bedf6bce4823a7bf24224cc7dbfc`) —
  recommends `push` + `paths-ignore` + `workflow_dispatch`; runner-up the same
  plus a monthly backstop. **Revision 3 adopts Opus's recommendation**, as
  revision 1 did; Opus's runner-up, which revision 2 adopted on owner direction,
  is again the ranked runner-up and the raw's cron value `17 6 1 * *` is the
  value it would carry.

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
itself says so. Revision 2's finding strengthens (a) rather than weakening it:
the auto-disable rules act on the workflow file, so a schedule-carrying block
exposes its other triggers too.

**Disagreement 2 — the noise argument.** Codex: push stacks a run on every
merge. Opus: below one qualifying merge a week push is cheaper than weekly
cron. The synthesizer measured it: py ran 87 push runs in 2026-06 and 7 in
2026-08 against about 4.3 a month for a weekly cron. Codex is right for a
busy repository; Opus is right for the template's stated pace; the decision
weighs the schedule's silent-off state above either count. Revision 2 accepted
12 scheduled runs a year, and the auto-disable exposure with them, for the retry
they offered; revision 3 does not, on owner ruling W0-R07b, so the weighing is
again the one this disagreement records.

**Disagreement 3 — path filter under a schedule.** Codex: moot. Opus: invalid.
`actionlint` rejects it (step 3), settling for Opus. The question was operative
at revision 2, whose block had a `schedule` key for the filter to be wrongly
placed under, and the negative control was run against that block too
(revision-2 check 3, the same rejection). At revision 3 it is once more academic
for the recommendation and decisive for the runner-up: option E's guard can never
cover its scheduled half. (The revision-1 judgment audit observed at O4 that this
is less a disagreement than two readings of "moot" — Codex's block had no filter
to place. The observation stands; the executed answer is unaffected.)

**Disagreement 4 — cron minute.** Both raws independently choose minute 17 to
avoid the top of the hour; revisions 1 and 3 carry it into the runner-up's
backstop cron, and revision 2 carried it into the recommendation. ts's observed
delays show the offset does not remove queue delay, which is why no cron in this
document is described as a latency guarantee or a staleness bound.

**Agreements.** Both raws: keep `workflow_dispatch` unconditionally; crate
figures inapplicable to a pattern item; no `CONFLICT:`; no `BASELINE-REVIEW:`;
no fixed parameter affected.

**Uncertainty.** No Rust project surveyed runs any contributors bot, so there
is no Rust convention to defer to. The template's future merge rate is a
judgment; if it exceeds about one qualifying merge a week the volume argument
for C strengthens (re-verify trigger). Whether template instantiation disables
schedules like a fork is unconfirmed (Opus gap 5); revision 2 raised the stakes
of that gap because its recommendation was a scheduled workflow, and revision 3
lowers them again — with no `schedule` key the fork rule reaches no consumer's
copy of this workflow, so the gap bears only on the declined option. What is
**not** reduced is the strength of the fact underneath it: that a disabled
workflow suppresses every trigger is asserted from the REST schema's single
`state` field and from the disable-and-enable page's wording, which is strong
documentary evidence and not an observation (P03 item 4 below). Issue-responsiveness
medians for the surveyed actions were not computed by either raw; none is a
dependency of this template. Codex's retrieval dates are 2026-09-05, Opus's
2026-09-09 (UTC), the synthesizer's 2026-09-09 UTC at revision 1 and
2026-09-16 UTC at revision 2 — which is 2026-09-15 in this host's local time,
the date revisions 2 and 3 carry in their titles, and the two are named apart
wherever either appears rather than being rounded to one. Revision 3 retrieved
nothing new.

**What P03 must validate, listed here because every decision is a proposal the
implementation phase proves.** Items 1 to 3 are what revision 1 left open and
revision 3 restores unchanged; items 4 and 5 are revision 2's, kept because they
test the ground on which the backstop was declined rather than a property of the
recommendation. Revision 2's item about a scheduled run appearing on the first of
the month is dropped: there is no scheduled run to observe.

1. A3 — a `workflow_dispatch` run is created on demand. Needs a live repository
   and R21's credential.
2. A4 — recognition latency is bounded by the merge when a push run succeeds.
3. A1 and A2 against the template's own history rather than py's, once the
   template exists.
4. That a workflow in `disabled_inactivity` or `disabled_fork` really does
   suppress the `push` trigger — revision 2's A7, and the reason option E is
   declined. This decision asserts it from the REST schema's single `state`
   field, which is strong documentary evidence and is not an observation; the
   cheap version of the check is `gh workflow disable update-contributors.yml`
   in a sandbox repository followed by a qualifying push, which needs neither 60
   idle days nor a fork. If that check ever showed the `push` trigger surviving,
   limb (i) of the runner-up's winning condition would be satisfied and the
   backstop should be re-put to the owner.
5. Whether "Use this template" instantiation disables scheduled workflows the
   way a fork does (Opus gap 5). It does not affect the recommended workflow,
   which carries no schedule; it decides how the template must document any
   scheduled workflow another item adds, and it is a precondition for revisiting
   option E.

## Supersedes

**Revision 1, published 2026-09-08, sha256
`0b3dde8f9a15f22e60a01542065c53c122881e8c48bf3ee6c172ba5b70499346`, 26,203
bytes — the bytes the owner acceptance row, both revision-1 audits and this
run's publication receipt all cite.** This section exists because revision 2
reversed part of a published decision and revision 3 reverses that reversal, and
the approved spec permits a `## Supersedes` H2 for exactly that case. It is the
only H2 beyond `## Decision`, `## Parameters`, `## Empirical check` and
`## Engines`, and it sits last so those four stay in order before it, with
`re-verify:` still the final line of `## Decision`. The preserved entry below is
**unfenced and unwrapped**: the last 26,203 bytes of this file are the published
file byte for byte, with nothing after them, which revision-3 check 5 asserts by
hash. Revision 2 wrapped the same bytes in a four-backtick fence and explanatory
paragraphs, and `review/audit-codex.md` rejected it for exactly that; the fix is
this form, which `research/runs/R42/.../review/DECISION.md` and
`research/runs/R18/.../review/DECISION.md` also use. The quoted document's own
headings are historical text, not sections of this document.

**Revision 2 (2026-09-15, sha256
`85beea991e84be1321b6b8cc55cd934c7049f621c38591394e2fa795234710a4`, never
published).** It added the monthly `schedule` backstop to the recommended `on:`
block on owner direction W0-R07, and, against the premise it was commissioned
with, established that GitHub keeps one `state` per workflow file, so the added
key exposed the whole workflow — `push` half included — to
`disabled_inactivity` and `disabled_fork`. `review/audit-codex.md` rejected it on
two findings (the `## Supersedes` payload was not byte-verbatim; the 31-day
maximum was stated as a guarantee), and the owner withdrew the direction the same
day once shown the corrected scope. Its evidence survives it: the two
documentation snapshots, `review/empirical/r2/run-check-r2.sh` and
`review/evidence/r07-empirical-r2.log` are left byte-identical and are cited
above.

**Revision 3 (2026-09-15), this revision, on owner ruling W0-R07b.** It restores
the published revision 1's `on:` block, its five essential behaviors and its five
acceptance criteria as the recommendation, and keeps revision 2's auto-disable
evidence — the snapshots, the assertions and criterion A7 — as the recorded
reason the backstop is declined rather than as a property of the recommendation.
It also keeps revision 2's corrected facts: py's 12-of-134 failed post-guard push
runs, the correction that visibility does not cut the same way for ts, and option
E's corrected *Silent-off state* cell. Option E is ranked runner-up again on a
**new** winning condition — GitHub's auto-disable rules changing so that a
scheduled trigger no longer disables the whole workflow, or path filters becoming
available on `schedule` — because the condition revision 1 gave it (R21 settling
F061 on an expiring credential) has fired, been put to the owner, and been
answered by this reasoning rather than by adding the backstop. Both revision-2
audit findings are closed. This revision did not edit the preserved bytes below;
it hashed them, to confirm they are still the published file byte for byte.

The complete revision-1 entry follows, preserved verbatim.

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
