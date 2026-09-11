# Open owner decisions — P02 research programme

Purpose: this is the list of things the programme cannot decide for itself. Each
entry states what is being asked, quotes the evidence that creates the question,
gives the options with their consequences, recommends one, and says exactly what
response settles it.

Everything else has been researched. Nothing here is waiting on more research,
with one exception that is named as such (decision 3).

Status as of 2026-09-10. Fourteen items are published. The programme is
`research/CLAUDE.md`; the narrative record is `docs/planning/p02/execution-ledger.md`.

## What is blocked, and by what

| Decision | Blocks | Cost of leaving it open |
|---|---|---|
| 1. Wave 0 review gate | all 52 unadmitted items | the programme stops when Wave 0 finishes |
| 2. R69 early admission | 19 items directly, 33 transitively | the largest dependency cluster stays idle |
| 3. R66 paid providers | one item's evidence base | R66 decides on three reports instead of five |
| 4. R18 residual acceptance | nothing in P02 | P03 ships two files that nothing may enable |
| 5. Licence gate reach | one item, not three (corrected) | P03 uses the slower install backend |
| 6. R25 prompt correction | nothing | a defective prompt stays on the record |
| 7. Baseline-review questions | nothing yet; several are inputs to unadmitted items | later items research around them |
| 8. Model substitution acknowledgment | nothing | an approval record stays incomplete |
| 9. CLI standard, and one waiver under it | two items, one already published | R60 cites it as R67 does, and needs a waiver recorded |

Decisions 4 through 9 block no research. They can be answered at any time. Only
1, 2 and 3 change what happens next.

## 1. The Wave 0 review gate

**What is being asked.** You set a gate: no Wave 1 item is admitted until you
review the Wave 0 keystones. Wave 0 is close to finishing. The question is what
review actually satisfies the gate.

**Evidence.** You said, when the programme started, that you wanted to review
key research and key recommendations to make sure we agree before going on. R01
is the only item with recorded acceptance. Thirteen further items are published
and unreviewed, and eighteen are still in the loop.

**Options.**

- **(a) Review the published keystones, then admit Wave 1 as a whole.** You read
  the decisions that later items consume as inputs. Cost: your reading time,
  concentrated once. Consequence: Wave 1 opens fully.
- **(b) Review a named subset now and admit Wave 1 in stages.** Cheaper per
  sitting, but the gate recurs and the programme pauses each time it does.
- **(c) Drop the gate and admit Wave 1 on publication.** Fastest. Consequence: a
  wrong keystone propagates into dependent items before you see it, and the
  revision cost lands on the dependents rather than on the keystone.

**Recommendation: (a).** The published decisions are audited twice each and the
audits reject far more often than they approve, so the marginal value of your
review is highest on the recommendations themselves rather than on their
evidence. Reviewing once, in a block, costs less of your attention than a gate
that recurs.

**Response that settles it.** Either "review these, then admit Wave 1", naming
the items, or "drop the gate".

## 2. R69, and whether it starts before the gate lifts

**What is being asked.** Whether to admit one item, `web-framework-stack`, ahead
of the gate.

**Evidence.** From `docs/planning/p02/item-graph.json`, recomputed 2026-09-10:
R69 is a prerequisite of 19 items directly and 33 transitively, and its own
prerequisite list is exactly one item, R01, which you have already accepted. It
is the largest single unblocking in the programme and it needs nothing that is
not already settled.

**Options.**

- **(a) Admit R69 now.** The 33-item cluster starts moving while Wave 0 finishes.
  Consequence: if your later review changes R01, R69 is revised against recorded
  research rather than researched again.
- **(b) Hold it until the gate lifts.** No risk, and the cluster stays idle for
  as long as decision 1 takes.

**Recommendation: (a).** It consumes only the item you have already accepted, so
admitting it does not pre-empt anything you have not seen.

**Response that settles it.** "Admit R69" or "hold it".

## 3. R66's paid orphan

**What is being asked.** Whether to spend again on two research providers for
one item.

**Evidence.** R66's three-provider operation
`research-20260909-003306-9390be364d324b9d` failed part-way. The OpenAI job
completed and was recovered read-only; Perplexity refused its submission against
a concurrency limit; Gemini was never attempted. The item has its Codex report
and, as of today, an Opus report in progress. So R66's Deep-tier evidence base is
one paid engine instead of three.

**Options.**

- **(a) Re-approve the Perplexity and Gemini subset.** Estimated USD 1.30 to 7.
  Consequence: R66 gets the evidence base its tier calls for.
- **(b) Accept the single-provider result.** No spend. Consequence: the decision
  records that two of its three required engines are missing, and the audits will
  hold it to a narrower claim.

**Recommendation, revised 2026-09-10 after R66's Opus report landed: (b),
accept.** When this entry was written the item had one paid report and the
recommendation was to re-spend. It now has three substantive reports, and more
importantly the strongest finding on the item did not come from provider breadth
at all. It came from reading commits and a design record in the pinned sources:
the TypeScript repository's flag shape is a faithful port of the pre-rewrite
Python command-line interface, and the Python repository's own design record
directed the rename before it could spread. So what the divergence analysis
recorded as an adjudicated divergence is stale-port drift. Two further providers
would add breadth on ecosystem practice, which is not where this item turned.
Spend if you want the tier honoured for its own sake; the evidence does not
require it.

**Response that settles it.** "Re-run Perplexity and Gemini for R66" or "accept
one provider".

## 4. R18's residual risk

**What is being asked.** Whether you accept a named, bounded, unremovable
security exposure. R18 is published and its recommendation is deliberately
conditional on your answer.

**Evidence, quoted from the published decision.** The exposure is a

> residual prompt-injection exposure of a **write-capable assistant lane on a
> public repository, reachable from text an OWNER, MEMBER or COLLABORATOR
> writes** — because a trusted author routinely quotes untrusted content
> (pasting an issue body, a fork pull request's diff, a stack trace) into a
> comment, and neither the prefilter nor any action-side check distinguishes a
> trusted author's own words from untrusted text that author pasted.

The decision states the exposure is bounded by six named controls and

> **not eliminated**. Whether a bounded, unremovable exposure on a write-capable
> lane is acceptable is an owner risk judgement, not an engineering-fitness one,
> and this decision does not have that judgement on record.

It also records that the review lane cannot be assumed safer: the token scope it
receives is chosen server-side and is not readable from any source the research
could reach, so the decision instructs treating it as write-capable until proven
otherwise.

**Options.**

- **(a) Accept.** P03 may enable the workflows, subject to proving two named
  unproven behaviours first. Consequence: you own the residual.
- **(b) Withhold.** The two workflow files are deleted and a documented opt-in
  recipe ships instead. Consequence: adopters who want the capability wire it
  themselves, and the residual becomes theirs.
- **(c) Say nothing.** The files ship inert. Functionally identical to (b) today,
  because nothing runs either way, but it leaves the question live in P03.

**Recommendation: (b) for the template, with (a) available for this repository
alone if you want the capability here.** The template is copied by people who
will not read the fixture headers. The residual is acceptable to own on a
repository you watch; it is harder to justify shipping into repositories you do
not.

**Response that settles it.** "Accept the R18 residual", "withhold it", or
"withhold for the template, accept for this repository".

## 5. The licence gate's reach

**What is being asked.** Whether the fixed `license` fitness gate reaches a
developer tool that runs as a separate process and is never linked into the
template's artifact.

**Evidence, quoted from the published decision.** The fast install backend,
`cargo-binstall`, declares `GPL-3.0-only`. The decision says:

> Under the plain reading `cargo-binstall` **fails gate 1** and is excluded,
> which is codex's position. `raw/opus.md` argues it should pass because the tool
> is executed as a separate process and never linked into the template's
> artifact, citing the FSF's mere-aggregation position. **That argument is
> recorded, not adopted:** whether gate 1 covers separate-process developer tools
> is an owner ruling, and no owner ruling exists.

The decision therefore chose the backend that is clean under either reading, and
recorded what changes if you rule otherwise: substituting the fast backend edits
one line of the recipe body and no invocation anywhere.

**Options.**

- **(a) Rule that the gate does not reach separate-process developer tools.**
  P03 uses the fast backend. Consequence: the ruling applies programme-wide, not
  just here.
- **(b) Rule that it does.** The current recommendation stands unchanged and
  contributors pay in compile time.
- **(c) Leave it, and use the licence-clean prebuilt alternative if compile time
  proves unacceptable.** The decision names one.

**CORRECTION, 2026-09-11: this reaches fewer items than I told you.** I
reported that three items depend on this ruling and that the strict branch
leaves no proven snapshot testing stack. R33's judgment auditor established that
R33 does **not** depend on your ruling at all. Its recommended crates carry
`Apache-2.0`, which is one arm of the fixed `license` value, so they pass on the
registry's own wording without the contested never-linked argument. The
no-stack outcome belongs to a **third, stricter reading** that no one has
adopted, under which every dependency at every depth would have to carry the
dual expression. That reading is not on the table unless you put it there.

R81 is in the same position and its own audit will confirm or correct that. So
the ruling's real reach is R42's install backend, which carries `GPL-3.0-only`
and genuinely is excluded under the plain reading, plus any future item that
recommends a copyleft tool. That is a narrower and more answerable question than
the one I put to you, and I should have checked the licence values against the
registry's own wording before widening it.

**Recommendation: (b), with (c) as the escape hatch.** A programme-wide licence
ruling made to speed up one install step is a large lever for a small gain, and
(c) gets most of the speed without the ruling.

**Response that settles it.** "Gate 1 does not reach separate-process tools",
"it does", or "leave it".

## 6. R25's defective binding prompt

**What is being asked.** Whether to correct a prompt that was already used.

**Evidence.** R25's binding prompt glosses two release-please flags as "feat
commits bump the minor digit, not major; fix commits bump patch even under a 0.x
minor". The tool's own schema at the pinned version says the opposite: one flag
makes a *breaking* change bump the minor digit, the other makes a *feature* bump
the patch digit. Two engines and one audit established this independently against
the source. The defect is in the prompt file alone; an earlier ledger entry also
blamed the commonality file, and that was wrong — its row names the two flags and
glosses neither, and never did.

**Options.**

- **(a) Correct the prompt.** Future readers see the right thing. Consequence:
  R25's acceptance record continues to cite the prompt hash it actually ran
  against, so the record and the file will differ by design.
- **(b) Leave it.** The decision is the correction of record. Consequence: anyone
  reading the prompt without the decision is misled.

**Recommendation: (a).** The hash mismatch is explainable in one line; a wrong
prompt is a trap.

**Response that settles it.** "Correct the R25 prompt" or "leave it".

## 7. The baseline-review questions

**What is being asked.** Nine questions consolidated at
`docs/port/BASELINE-REVIEW.md`, each with options and a recommendation already
written. Eight are fully open. One, the ninth, is half-answered: R67 answered the
ownership half and declined the rest, and the acceptance criteria remain open with
two competing capture proposals.

One of the nine, the sixth, has already been acted on in a published decision:
R20 recorded the vendor-canonical exemption as a path-scoped ignore. That is the
recommendation the baseline review made, so ratifying it costs nothing.

**Recommendation.** Take them as a block and accept the written recommendations
except where you disagree. They were written with the options and consequences
already laid out.

**Response that settles it.** "Accept the baseline-review recommendations", with
any exceptions named.

## 8. The model substitution acknowledgment

**What is being asked.** The approval record asked you to acknowledge that one
provider's deep-research model was substituted. It was never recorded.

**Recommendation.** Acknowledge it. Nothing depends on it, but the approval
record is incomplete without it.

**Response that settles it.** "Acknowledged".

## 9. Whether your CLI Design Standard binds this port

**What is being asked.** To confirm, not to decide. R60 flagged as an owner call
whether the organisation's CLI Design Standard at
`/Users/stevemorin/c/cli-standards/cli-design-standard.md` governs this template.

**Evidence.** It is already load-bearing in a published decision. R67 read the
standard on 2026-09-09, adjudicated one of its rules as a requirement that is
org-locked, and quoted its exit-code table verbatim as the contract this template
adopts. R60 reaches the same document independently for command ordering and
completion behaviour, and its report notes the TypeScript repository had already
reconciled onto it.

**Options.**

- **(a) Confirm it binds.** Nothing changes. R60 cites it the way R67 already
  does, and future items do the same.
- **(b) Say it does not bind.** R67 is reopened along with R60, because R67's
  exit-code contract rests on it.

**Recommendation: (a).** This is a confirmation of something two independent
items found and one published decision already relies on. Denying it costs a
resolved item.

**A waiver rides with this answer.** R60 recorded the programme's first
override, `OV-01`: its recommendation deviates from the standard's rule on
extended version output, so the tool would print target and compiler lines the
rule does not call for. The decision records the argument and three options as
the charter requires, and it cannot grant itself the waiver, because the
standard's own conformance clause reserves that to you. If the standard binds,
this needs a yes or a no.

**Recommendation on the waiver: grant it.** The rule it deviates from is a
should, not a must, and extended version output is what a Rust command-line tool
is expected to print. Refusing costs nothing either, since the decision names
the conforming alternative.

**Response that settles both.** "The CLI standard binds, and OV-01 is waived",
or either half negated.

## Retired from this list

Two items previously carried here are not owner decisions.

**The OpenTelemetry clause.** The approved plan says the required web example
uses OpenTelemetry and that feature selection must not make it optional. That is
a constraint on the template P03 builds, not an instruction to build an
observability example during research, so it does not conflict with the
research-only ruling. The baseline review reaches the same conclusion, recording
that its own finding on the subject is "coordination of existing research, not
permission to relax OpenTelemetry".

**Whether you have an Anthropic organisation.** This was a live question while
R18 proposed workload identity federation as a mitigation. Revision 3 withdrew
that mitigation and revision 4 folded what remained into decision 4 above. It
survives only as a fact you supply when answering that one.

## Two things you should know, which are not decisions

**A gate reading I ruled on was overturned by the auditors, which is the
outcome the process is for.** Two items applied the minimum-supported-Rust-version
fitness gate differently. I ruled provisionally that a candidate which declares
no version is unproven rather than failed, weighed against it but not excluding,
and put that ruling to both items' auditors. Both argued independently for the
strict reading and they are right: the gate quotes the policy in full, and the
instruction that follows says a failed gate excludes the candidate, so an
unknown version is insufficient to clear a bar the prompt says must be cleared.
The ruling is withdrawn. One item's exclusions stand; the other must switch to
the runner-up it already recorded. No decision was published under the wrong
reading.



**R41 ran to eight audit rounds** against a runbook limit of five. It published.
The limit exists to stop an item circling; R41 was converging, not circling, and
the rounds are recorded.

**R25 is at its fifth revision.** Four consecutive audits rejected it for the
same defect shape — a supporting sentence stated more absolutely than its
evidence — and never for its recommendation, which has not changed once. The
contract has been amended to require the revision sweep be done by search rather
than by re-reading, which is the specific failure each time. If revision 5 is
rejected, the item comes to you for adjudication rather than a sixth round.
