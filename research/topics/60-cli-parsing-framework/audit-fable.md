decision-sha256: 16d2db72028bc368e0f857e2a168d488d40dffdbea78b99b01519d02dd120651
actor: audit-fable-2026-09-05T183002Z-09f93cfc507c-r9
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

This audit binds revision 9 at the sha256 above, which I hashed from
`review/DECISION.md` before reading it. My round-8 report is archived
byte-identical at `review/audit-fable.r8.md` (sha256
`63224040bbc7c59042305e9aa6d906eb6e6fd2c98822029857bc0be69efc9c86`). Round 8
closed F4, F5, F6 and F7 and rejected on one finding, F8. **F8 is closed, in the
form I specified and with two things I did not ask for.** I found nothing else,
and I reproduced every measurement revision 9 records rather than reading its
summary.

## Principle and agreement level

Nothing at this level moved and nothing could have. `git diff --unified=0`
against revision 8 is **exactly three hunks**: the title, a 36-line revision
note, and a 67-line block inside `## Empirical check`. No principle row, no
agreement level, no rule citation, no acceptance criterion, no gate verdict, no
qualification, no `re-verify` trigger and no table figure is touched. The four
`assumes` lines are byte-identical to `docs/port/PARAMETERS.md`, which I
re-derived field by field rather than trusting the claim. The recommendation is
still `clap 4.6.6` with `derive`/`env`/`wrap_help` — three features — so the
`string` removal that round 8 confirmed as evidence-grounded stands unchanged
and the owner's pending re-ask is on exactly the point it was raised for.

## Design and evidence

**F8's repair is a measurement, and I repeated it.** My round-8 finding asked
for four things: rerun the superseded script against the final committed text,
record exit `2` and `FAILURES: 2`, replace the `C4k9` item with the reason that
check survives, and keep the falsified sentences in place and labelled.
Revision 9 does all four and adds two more.

Run against revision 9's own committed text,
`bash review/evidence/r60-preservation-diff-r7.sh` exits **`2`** with
`CHECKS RUN: 183   FAILURES: 2`. The two failures are the
`CHANGED    clap 4.6.6 pin and its four features (1 of 1 revision-1 line(s) no
longer verbatim)` preservation call and `C4h`, and `C4k9` prints
`PASS  C4k9 the unproven table says which rows are still unproven`. I compared
my own run line by line against the committed
`review/evidence/r60-preservation-diff-r7-against-r9.log`: **the 809-line body
is byte-identical to my output**, and the log's own trailer reads
`EXIT STATUS: 2`. Committing the exit status inside the log is the detail that
makes this record self-describing rather than dependent on a sentence elsewhere,
and it is the thing whose absence let revision 8's number drift.

**The mechanism is stated more precisely than my finding stated it, and every
clause of it is true.** Revision 9 says `C4k9` matches the literal
`U1–U7 are unproven and are P03's to prove` against the flattened whole
document, that the live preamble changed, that the document nonetheless quotes
the superseded sentence inside item 3 of the very paragraph reporting the rerun,
and that **this is the document's only full occurrence of the string**. I
counted: the literal occurs **exactly once** in revision 9, at `:2044`, inside
that item. So the check is satisfied by a quotation of the old wording and
cannot tell it from the live wording — which is the whole of F8's cause, stated
as a property rather than as an anecdote.

**The discrimination claim is the part I did not ask for and it is correct.**
Revision 9 names the two checks that *can* tell the two apart, both in
`r60-preservation-diff-r8.sh`: its own `C4k9`, whose expectation was updated to
the live sentence `U1–U7 and the new U9 are unproven and are P03's to prove`
(`:966-967`), and `C4o28`, which requires the labelled superseded record
`Revisions 1 through 7 said "U1–U7 are unproven"; that count is corrected`
(`:968-969`). I read both lines in the script and confirmed the live preamble is
at `:2354`. Between them the live wording and the labelled correction are both
pinned, so the class of defect F8 named is closed by a check rather than by a
promise — and revision 9 changes neither, which is right, because they already
hold.

**The second thing I did not ask for is the revision-8 script's own result
against this text, and it is accurate too.**
`bash review/evidence/r60-preservation-diff-r8.sh` on revision 9 exits **`1`**
with `CHECKS RUN: 239   FAILURES: 1`, failing `C4h` alone — the title. I ran it;
the 931-line body of `review/evidence/r60-preservation-diff-r8-against-r9.log`
is byte-identical to my output and its trailer reads `EXIT STATUS: 1`. That its
238 other checks pass is revision 9's scope evidence, and it is the strongest
form of "nothing else moved" this apparatus can produce: the script that pins
the feature set, the owner's ruling, the parameters, the gates, the acceptance
criteria and every preservation target from revisions 1 through 7 still passes
in full.

**Row E9's scope is restated correctly rather than left ambiguous.** Revision 9
says E9's `239/0` is the record of the revision-8 run and not a claim that those
bytes reappear against revision 9's text, and leaves
`r60-preservation-diff-r8.log` byte-identical because it is the artifact the
round-8 audits ran. That is the same rule this document has applied to every
superseded script since revision 6, and applying it to a log whose own numbers
have just been superseded is consistent rather than convenient.

**The falsified sentences are kept and labelled.** The revision-8 paragraph
stands verbatim under a heading that names it wrong in its third item and calls
out the "The number is taken from the run" sentence as false, with the measured
run immediately beneath. That is this document's standing discipline and the
reason its history is readable; it is also, as revision 9 observes, the same
discipline that defeated `C4k9`. Saying both things at once — the discipline is
right, and here is the check it broke — is the honest reading and revision 9
reaches it.

## Completeness

The four H2s are present and in order, `## Supersedes` is correctly absent, and
`re-verify:` is untouched. The two new logs are committed in the same commit as
the decision, both reproduce in place, and revision 9 states they were also run
from a clean `git archive HEAD` extraction. I verified the in-place halves of
both and the byte-identity of both log bodies against my own reruns; the clean
extraction is the round-9 empirical auditor's to repeat.

**The declared gap is not a finding, and the reasoning is worth recording
because the question was put directly.** The gap is that no committed check
asserts the presence of the two new logs, because `C5c` of
`r60-preservation-diff-r8.sh` enumerates the thirty-nine files that existed when
it was written and revision 9 issues no script of its own. Four things make this
acceptable rather than a defect.

First, it is **declared**, with its cause and its repair named — a later
revision that reissues the preservation script adds them to `C5c`. This
document's record on declared gaps is good: revision 7 declared that nothing
bound the round-6 report's bytes, my round-8 audit judged that disposition
correct, and revision 8 closed it the moment the controller archived that report.

Second, a presence assertion is the **weaker** guarantee here. `C5c` proves a
file exists; what matters for these two logs is that their content reproduces,
and it does — I reran both scripts and both log bodies matched mine exactly.
Anyone can repeat that without any check's permission.

Third, issuing an `-r9` preservation script solely to assert two filenames would
change that script's own recorded totals and force a fresh cascade of superseded
artifacts, which is precisely the cost this decision has twice declined to pay
for a similar bookkeeping gain — the fourth through seventh baselines are kept
out of `snapshots/MANIFEST.txt` for the same stated reason, a disposition two
audits have now accepted. Choosing the same way again is consistent, and the
alternative would enlarge a revision whose brief was one finding.

Fourth, and decisive for the question as asked: **the gap does not touch the
`string` removal.** That removal rests on `r60-feature-ground-r8.sh`, which has
its own row E15, is inside `C5c`'s thirty-nine files, and which I reran in round
8 at `28/0` with an empty diff. The owner's re-ask is on the three-feature set,
and every artifact behind it is asserted, reproducible and unchanged by revision
9. A decision heading to that re-ask is not weakened by two rerun logs whose
presence no check enumerates while their content reproduces on demand.

One observation, not a finding and not something revision 9 should act on. The
`C4k9` episode shows that a preservation check matching a literal sentence
against the flattened document cannot distinguish a live claim from a quotation
of a superseded one, and this document will keep generating such quotations
because its charter requires them. The revision-8 script already handles the one
instance; the general form — that every preservation expectation whose subject
is a sentence this document may later quote is vulnerable the same way — is
worth a sentence in whichever revision next reissues the apparatus. I raise it
as a note because no current claim rests on it and revision 9's brief was F8.

## Findings

None.

## Assessment

Approve. Revision 9 does exactly what round 8 asked, in the narrowest form that
could do it: three hunks, one finding, no recommendation touched, and the answer
is a measurement I reproduced rather than a restatement I was asked to believe.
Both committed logs are byte-identical to my independent reruns, the exit status
is recorded inside each log rather than only in prose, and the single-occurrence
claim that explains why `C4k9` survives is exactly true at `:2044`.

Two things lift this above a minimal repair. The decision found the checks that
discriminate the live wording from its quotation and named them, so the defect
is closed by an assertion rather than by an apology; and it reported the
revision-8 script's own result against this text, unasked, which is what makes
"nothing else moved" a measured claim — 238 of 239 checks passing, the one
failure being the title.

The declared gap is correctly scoped, correctly costed, and irrelevant to the
`string` removal the owner is being re-asked about. This item's substance was
settled at round 8; revision 9 settles the last statement about its own
evidence. Nothing on judgment now stands between it and publication except the
owner's answer on the three-feature set.
