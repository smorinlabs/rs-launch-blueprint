decision-sha256: 66d566a55330e2417a2e5227bcac64e3312fc56280db09d7b74a13425aa346c1
actor: audit-fable-2026-09-05T163616Z-1ab131aed82d-r2
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

The shared requirement is stated at line 41 as an outcome, not as a tool: the bot must open a pull
request whose required checks reach a conclusion without a maintainer intervening, from a credential
the owner provisions once, and must fail loudly when none is provisioned. That is the right altitude
for this item — it is falsifiable, and B1–B5 decompose it into behaviors each tied to a read artifact
rather than to a preference.

The agreement level is declared **policy** before the alternatives are compared, and the declaration
is argued rather than inherited: the mechanism is a YAML input and a repository secret, so no language
toolchain bears on it, and an ecosystem-specific divergence here would be accidental drift. Spec §2's
warning applies in the opposite direction from the usual case — the risk is not importing a shared
value without a fitness argument but inventing a Rust-specific difference where none exists — and
line 43 meets it by naming what must agree (the credential *class*: a user- or App-identity token,
never the ambient job token) and what may vary (secret name, App installation, cadence). Splitting
agreement at the class rather than at the literal string `CONTRIBUTORS_PLEASE_PAT` is the correct
width; it leaves R07, R08 and R20 their rows and claims none of them.

No `OVERRIDE (OV-nn)` is due and line 25 says why: F061 is `DIVERGENT`, so this selects between two
recorded source patterns rather than departing from a common one. F060 is consumed as it stands. That
reading matches `docs/port/COMMONALITY.md:66-67`.

The owner direction of 2026-09-04 ("model it on what PyLaunch Blueprint does", `docs/port/OWNER-REVIEW.md:63`)
is cited as a binding requirement and as one of three confidence supports, but it is not what excludes
O4 — and the decision proves this structurally by ranking O2, which is *not* py's shape, as the
runner-up and naming the condition under which it wins. Spec §2's rule that repository agreement is
evidence to investigate rather than an answer is respected in substance, not only in wording.

## Design and evidence

**The rejection of ts's shape is argued on mechanism, and on the stronger of its two mechanisms.**
Ground 1 (line 70) is GitHub's own documentation, retrieved twice in this run by two independent
pages (log cases 08 and 09): a `pull_request` event arising from a `GITHUB_TOKEN`-created or -updated
PR produces runs in an approval-required state, clearable only by a writer clicking **Approve workflows
to run**. For a bot whose purpose is unattended operation that converts every bot PR into a manual
step, which is exactly the failure of the shared requirement at line 41. Ground 2 (the B1 identity
lookup) is marked predicted. Line 73 then states that ground 1 alone excludes O4 and that the
recommendation does not depend on ground 2 — so the load-bearing argument is the documented one, and
the unproven one is decoration that is honestly labelled as such. The decision does not overstate
ground 1 either: it says explicitly that this is what GitHub documents, not what a run does.

Two corroborations sit at their correct, lower weight. The action's own `e2e.yml` configures `pat:`
only from dedicated secrets and never from `GITHUB_TOKEN` (case 06) — restated everywhere as
*configured*, never *exercised*, after disagreement 4 caught the Opus raw's stronger phrasing. And
GitHub's own remedy, quoted on the same page as ground 1, is "use a GitHub App installation access
token or a personal access token instead of `GITHUB_TOKEN`", which is precisely the recommended shape.
That quotation also disposes of the objection that the App path is itself an installation token and
should therefore be equally gated: GitHub distinguishes the two, and the decision follows GitHub
rather than reasoning from the category name.

**The fallback's value is argued on capability, and the "must be exercised" principle is applied to
the recommendation itself.** The sharpest test of this decision is whether the carried BASELINE-REVIEW
principle — a documented fallback must be functional and exercised before it is recorded as working —
is turned on the recommendation as well as on the ts shape. It is. Unproven item 2 records that
`CONTRIBUTORS_PLEASE_PAT` is set in neither source repository, so no green run evidences the
recommended fallback either; that is stated in the decision's own text with its provenance and with
the note that this run did not re-verify it. The observable acceptance criteria at line 57 and P03
validation items 1 and 6 are exactly the exercise the principle demands: `token-source` = `pat`,
`pr-opened` = `true`, a non-empty `pr-url`, no approval banner, and confirmation that the three
inferred fine-grained grants actually suffice — item 6 says in terms that those grants come from the
source workflows' `permissions:` blocks, not from an executed run. The decision therefore recommends
the fallback without recording it as working, which is the only treatment consistent with the line it
carries forward. Its value rests on capability (an App-less consumer has no path under O2) with an
explicit refusal to claim frequency, matching `raw/opus.md:124-128`. That is an honest argument at its
evidence's width, and the `re-verify` line names the owner ruling that would flip it to O2.

**The two corrections are weighed, not merely recorded.** Clause (3) is narrowed from "required checks
never report" to "do not report until a writer approves the runs", and the narrowing then *propagates*:
B3 is phrased as waiting behind approval, O4's ground 1 says explicitly it does not claim the checks
never report, and disagreement row 1 records that Opus quoted the general rule while omitting the
second exception bullet on the same page — settling in Codex's favour on retrieved evidence rather
than by splitting the difference. Clause (4) is narrowed to new repositories in a *personal* account,
and that narrowing propagates too: every "zero extra setup" passage is qualified per account type, the
organization case is left explicitly undetermined rather than assumed, and P03 item 5 asks the
follow-on question the narrowing raises — whether the setting constrains a PAT-authored PR at all, or
only a `GITHUB_TOKEN`-authored one, checked separately for the two account types. A decision that had
merely recorded the corrections would have left clause (3)'s and clause (4)'s original width live
somewhere in the prose; grepping for those passages finds them all qualified. Both corrections narrow
the width of the carried line without changing its direction, and line 31 says exactly that. Sending
the line to the owner unedited while annotating it is the runbook-correct division of labour: §4
reserves adjudication and ledger edits to the controller.

**Architectural alternatives were genuinely compared.** O1–O4 are compared before any tool is named,
each with a verdict and a reason, and the exclusions are earned: O3 is excluded as *redundant, not
broken*, with the reason that the action already mints its own installation token — a distinction a
weaker decision would have collapsed into "rejected". Checking the option inventories of both raws
against this table, every candidate either engine listed maps onto O1–O4 with none dropped: Codex's
three (dedicated PAT App-first, ambient token, App-only) are O1, O4, O2, and Opus's four are O1–O4
directly. The six fitness gates are answered per candidate with `inapplicable` plus a reason where a
crate gate cannot bind, as the prompt requires, and gate 3 substitutes a real security-posture analysis
rather than leaving the row empty. Popularity is explicitly disarmed: the action's star count of 0 is
reported and stated *not* to be authority, the citation resting on F060 instead.

**The collation episode is honest and durable, not deferred.** Revision 1 was rejected because it
called its log the full output of a script whose re-run produced something different. Revision 2 does
not assert the difference away: it establishes the cause by execution — the same unchanged script under
`LC_ALL=C` on this host reproduces the auditor's ordering exactly — and rules out the alternative
hypothesis the auditor allowed for, since both runs report the same URL, the same `HTTP 200`, the same
byte count and the same 28-entry set, so the page did not reorder. Both environments' locales are
labelled inferences from the ordering rather than retrieved facts, which is the correct epistemic
status and is unusual honesty about the limit of one's own evidence. The published rule is bounded to
two named sources of variation, the counted diff is 4 lines with none an observed value, and the
normalizer returns 0 across all three independently produced logs including the rejecting auditor's
own. Durability is the point of choosing the rule over regenerating the log: a regenerated log would
carry revision 2's collation and fail the next auditor whose shell differs, and line 7 says so. Line
175 then closes the loophole a normalizer could open, by declaring any difference outside those two
sources to be drift rather than noise. The r2 audit is the rule's first live test and it behaves as
designed: the page moved from 642032 to 644053 bytes, the normalizer reported that difference rather
than swallowing it, and the endpoint set and all 27 assertions were unchanged, so no observed value
the decision cites is disturbed. That is a rule working, not a problem postponed.

**The unproven 403 is treated correctly and carries no weight it has not earned.** Every
occurrence carries the qualification: lines 57, 65, 71, 100, 113, 192 and 207 read `(Q1, predicted)`,
line 45 is the full statement of Q1 itself, and line 214 reads `(Q1). Unproven.` at the head of the
unproven list, which is the same label in that list's own idiom. Q1 states the
qualification once in full at line 45 with the two verified facts it rests on, item 1 of the unproven
list names the observation that would convert it (Opus's check B, `GitHub token identity lookup failed:
403` in a sandbox step log), and line 214 says plainly that this is P03 work, not research-phase work.
Case 11 records the exclusions as executed refusals rather than as omissions. Per the programme's own
rule that P03 builds and proves the template, declining to run it is correct conduct, and the
recommendation is insulated from it by line 73.

## Completeness

All four required H2s are present and in order — `## Decision`, `## Parameters`, `## Empirical check`,
`## Engines` — with `### Principles and implementation` under the first and `re-verify:` at line 115
carrying a date plus six named events. `## Supersedes` is correctly absent: revision 1 was never
published and revision 2 is not a reversal, and the revision note says so rather than leaving the
absence to be inferred.

The four `assumes` lines are byte-identical to the live registry `docs/port/PARAMETERS.md` rows 7–10
and to `inputs/parameters.json`. I checked the live file rather than the run's snapshot, because four
owner items have resolved since the snapshot was taken: `docs/port/PARAMETERS.md` and
`inputs/PARAMETERS.md` now differ, but only in the `researched` rows for R01, R38, R42 and R67, which
this item neither owns nor consumes, and the four `fixed` rows are byte-identical across the two files
(sha256 `133fde867fec01ad281c112745213b21238d2320e825e23cfd035fe5d80724a5` over lines 7–10 of each).
The consumed values are therefore current. Line 126 explains how each bears on the item instead of listing them
inertly — including the non-obvious observation that `target-os-matrix` is exercised indirectly,
through the CI workflow the bot PR must trigger rather than through the bot job itself. The item owns
no parameter, consumes none, and raises no `CONFLICT:`; both raws agree (`raw/codex.md:69`,
`raw/opus.md:418`), so nothing is suppressed.

Both raw reports are identified by actor, model, family, transport and recomputed sha256; I recomputed
both and they match the filenames and `operations/*.json`. Focused tier required codex and opus; both
reported. The Opus `BASELINE-REVIEW: F061` line at line 29 is byte-for-byte identical to
`raw/opus.md:210` — I diffed them. Five engine disagreements are tabulated with the evidence that
settled each, and row 2 is left deliberately unresolved with that fact stated rather than papered over. Four unproven claims are
listed with what would prove each, and the fourth is recorded as an evidence gap rather than estimated
— the LOW question about adopter friction is answered by saying no dataset was found, which is the
correct answer to an unanswerable question.

Source dates are present and typed: four pages retrieved by this run with status and byte count, local
reads at three named pins, and carried-from-raw sources each labelled at its point of use with its
retrieval date and the statement that this run did not re-fetch them. The distinction between what this
run verified and what it carries on another engine's authority is maintained consistently, including
for the authenticated `gh api` retrievals it could not repeat.

The audit-codex rerun is consistent with this decision. It approves the same sha256 I read, its five
"no finding" sections test the revision-2 claims that revision 1 lacked, and its one live-page
difference is handled by the decision's own published rule rather than against it.

## Findings

None.

## Assessment

Approve. The decision recommends App credentials with a dedicated fine-grained PAT fallback on grounds
that survive removing every unproven claim: GitHub's documented approval-required treatment of
`GITHUB_TOKEN`-created bot PRs excludes the ts shape by itself, and the decision says so explicitly
rather than letting the predicted `403` carry weight it has not earned. The carried-forward principle
that a fallback must be exercised before it is called working is applied to the recommendation itself
— the recommended fallback has never run in either source repository, the decision says so, and it
sends the exercise to P03 as a named check with observable outputs rather than recording it as proven.
Revision 2's answer to the revision-1 rejection is the durable one of the two remedies offered: it
establishes the cause by execution, labels its inferences as inferences, publishes a bounded rule with
a runnable normalizer, and declares what the rule must *not* absorb — a boundary the second audit's
live-page byte-count change promptly tested and confirmed. The material is fit to publish.

One optional cross-reference tidy for the controller, which I did not raise as a finding because the
substance the controller needs is already in the decision's own text: line 37 says the Codex
`BASELINE-REVIEW: F061` line "is recorded in `## Engines`", and the codex bullet at line 198 records
its recommendation and its approval-required exclusion ground but does not say that Codex raised a
`BASELINE-REVIEW` line — unlike the opus bullet at line 199, which names its line explicitly. Line 37
itself tells the adjudicator that a second line exists, on what ground, and why it is not forwarded
separately, and `raw/codex.md:19` holds it verbatim, so nothing is lost; only the pointer is imprecise.
