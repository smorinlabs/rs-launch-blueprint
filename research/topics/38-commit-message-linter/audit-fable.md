decision-sha256: c2e9b6e1f1cf096b640ecd2925c8f79010bf7e875a9ce91d18a1d3ad84b3ce24
actor: audit-fable-2026-09-05T151356Z-c46d732f98ed-r9
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

This audit was produced by a fresh context that wrote none of this item's raw
reports, none of its nine decision revisions, none of the empirical audits and
none of the earlier judgment audits. I bound the decision at sha256
`c2e9b6e1f1cf096b640ecd2925c8f79010bf7e875a9ce91d18a1d3ad84b3ce24`, computed
with `shasum -a 256` over `review/DECISION.md`; that is the hash given in my
task, the hash `review/audit-codex.md` binds, and the hash of the file as
committed at `HEAD` (`git show HEAD:…/review/DECISION.md | shasum -a 256`
returns the same value, so the audited bytes are the committed bytes).

**Scope of this round, stated so a reader knows what I re-derived and what I
carried.** Revision 9 differs from revision 8 in five single-line hunks — 1, 3,
250, 259 and 294 — which I measured myself with `git diff -U0 08f1a9c HEAD --
review/DECISION.md` rather than accepting from the revision note. Hunks 1 and 3
are the title and the preamble; 250 is the third-evaluation paragraph inside
`## Empirical check`; 259 is the revision-notes bullet and 294 one sentence of
the uncertainty paragraph, both inside `## Engines`. `## Decision` (lines 5-190)
and `## Parameters` (lines 191-199) contain **no hunk at all**, so every
judgment the revision-7 judgment audit (`review/audit-fable.r7.md`) recorded
against those sections — the agreement level and the `BASELINE-REVIEW.md:75` and
`DIVERGENCE-ANALYSIS.md:155,159` rows behind it, the five essential behaviors as
binding exclusion criteria, the three-way architecture comparison, the
`conventional_commits_linter` exclusion's five clauses each landing on an
executed row, the six fitness gates, the ledger rows and the acceptance criteria
— stands against byte-identical text. I did not re-read the five raw reports,
`inputs/prompt.md`, `docs/port/PARAMETERS.md` beyond line 13, or the
`BASELINE-REVIEW.md` rows, because the text those readings certified has not
moved; I concentrated on the four questions this round actually puts: whether
the round-7 rejection is closed, whether `## Supersedes` is intact, whether the
revision's prose matches the evidence it newly cites, and whether the
recommendation moved since the owner's acceptance.

**The agreement level is unchanged and remains correctly read.** The decision
states **capability/standard** on `docs/port/BASELINE-REVIEW.md:75` (F148,
retained) with `docs/port/DIVERGENCE-ANALYSIS.md:155` classing the tool row B
(`harmonize: partly`) and the value rows A (`harmonize: yes`) — so the
*contract* binds across py, ts and rs while the *program* may differ. Agreement
among the five reports is cited as corroboration, never as the ground. Nothing
in revision 9 touches this.

## Design and evidence

**The recommendation did not move, and that is measured, not asserted.** The
absence of any diff hunk inside `## Decision` and `## Parameters` is the direct
proof: the pick (`committed` 1.1.11, exact pin), the hook-plus-CI placement, all
nine ledger rows F149-F157, the two derived `ADOPT` values F158/F160, all six
gate results including gate 1's `inapplicable`, every acceptance criterion, the
runner-up ranking and the `re-verify:` line are byte-identical to the revision
the owner accepted. I separately confirmed the owned parameter against the live
registry rather than against revision 8: the `- owns commit-message-convention`
value at line 193 and the value cell of `docs/port/PARAMETERS.md:13` are **508
bytes each and byte-identical** (`diff` produced no output), so the registry has
not drifted underneath the byte-identity claim.

**What revision 9 newly claims, and whether the evidence carries it.** The
change is confined to evidence about reproducibility. I checked each load-bearing
number against the artifact rather than the prose:

- The carried artifact. `review/evidence/rev6-evaluate.sh` is **14,374 bytes**
  and hashes to `cf9ffcb2b84383c2fc797a86539612e3aaeff22753384f68d04cc2204eb501fa`,
  exactly as the decision states. `git ls-files -s` shows it tracked at mode
  `100644` — the decision's "committed at mode 644 so nothing runs it" — and its
  tracked blob id *is* `a6e6641ea13c7e4b173cf7e0932fd682f794b28d`, the revision-6
  blob the decision says it was extracted from, so the carried copy and the
  history object are the same bytes rather than merely equal-hashing copies.
- The new comparator's two runs. `review/evidence/r38-crossrun-compare-r9.log`
  carries 106 `PASS`, 0 `FAIL`, 0 `SKIP`, `failed assertions: 0`,
  `skipped assertions: 0`; the archive log carries 105 `PASS`, 0 `FAIL`, 1
  `SKIP`, `failed assertions: 0`, `skipped assertions: 1`, and names the skip in
  its own closing block as `r6/carried-copy-is-the-committed-blob`. Both match
  the decision's figures, and the skip is the single Git-dependent assertion the
  decision says it is.
- The post-commit rerun. `diff r38-crossrun-compare-r9-archive.log
  r38-crossrun-compare-r9-archive-postcommit.log` produces no output — the two
  files are byte-identical, which is what "reruns unchanged after the commit"
  requires.
- The old comparator's two exits, which the decision now states rather than
  assumes. `r38-crossrun-compare-r7-in-repository-r9.log`: 102 `PASS`, 0 `FAIL`,
  `failed assertions: 0`. `r38-crossrun-compare-r7-in-archive.log`: 99 `PASS`,
  `failed assertions: 3`, and the three named failures are exactly the three the
  decision names — `r6/blob-recovered (expected 0, got 128)`,
  `r6/blob-is-the-evaluation-script` and `r6/used-the-absolute-path`. So the
  revision-8 empirical auditor's finding is reproduced in the evidence rather
  than paraphrased away.
- The self-containment claim. The decision says the comparator "never opens
  `review/DECISION.md` or any log of its own". `grep -n 'DECISION.md'
  r38-crossrun-compare-r9.sh` returns three hits, all of them non-reads: two
  comment lines (16, 141) and one `echo` of a failure message (697). The claim
  holds as stated.
- The cited Git objects all exist: commits `43e82ca7…` (the extraction the
  archive run was taken from), `b9cccb6d…` (the revision-9 text) and `9684a585…`
  (the self-reference repair), and blob `a6e6641e…`.
- The precedent. The decision says it "repairs the defect the way R17 revision 6
  repaired the identical one (`research/runs/R17/2026-09-05T163018Z-d7ade3a111f8/review/DECISION.md:29`)".
  I read that line: it describes a revision-2 copy committed beside the script as
  an evidence artifact with its digest asserted, paths resolved from `dirname
  "$0"` and never from git, and "exactly one assertion still needs Git history,
  and it is named as such" — the same three-part shape, applied here. The
  citation is precise, not decorative.

**The scope claim is verified against the tree as well as the file.**
`git diff --stat 08f1a9c HEAD` over the whole run directory shows `DECISION.md`
changed by 10 lines (the five hunks) and **no modification to any pre-existing
evidence artifact**: `evaluate.sh`, its cited evaluation log, the revision-7
comparator `r38-crossrun-compare.sh` and its log `r38-crossrun-compare.log` are
untouched, and everything else in the diff is an addition — the new comparator,
the carried script, the five new logs, and the audit artifacts. The decision's
"both left byte-identical as history" is therefore true of the working tree, not
only of the prose.

**The revision-8 finding is quoted accurately.** The decision's `## Engines` note
reproduces it verbatim from `review/audit-codex.r8.md`'s `unresolved-findings`
field: "The revision-7 cross-run comparator cannot reproduce from a clean git
archive HEAD extraction: it requires the revision-6 Git blob
a6e6641ea13c7e4b173cf7e0932fd682f794b28d, which an archive deliberately lacks,
and exits 1 with three failed assertions". I compared the two strings; they
agree word for word.

**The repair is a repair, not a weakening — and the decision says so in the
falsifiable direction.** The temptation in this class of fix is to delete the
assertion that cannot run in an archive. This one keeps four content assertions
about the revision-6 form running in **both** modes (`r6/carried-copy-readable`,
`r6/carried-copy-is-the-evaluation-script`, `r6/used-the-absolute-path`, and the
digest assertion), gates only the Git-object comparison, and states that the gate
"prints `SKIP` by name and is counted a skip, never a pass". The archive log
bears that out: one skip, named, with the count reported separately from the
pass count. The empirical audit's controlled mutation — which I did not repeat,
because it belongs to that role — shows the digest assertion failing in both
modes, so the gated assertion masks nothing.

**The class-F correction is the rubric used against the decision's own
interest.** Revision 7 recorded that class F (the live-figures block) had never
been observed to vary. Revision 9's hunk at line 294 records that it *did* vary
between 2026-09-13 and 2026-09-15 and calls that "the rule working, not a
failure", while still declining to claim the class is guaranteed to appear. A
document under pressure to look clean would have left the earlier sentence
standing.

**The audit-codex rerun is consistent with the decision.**
`review/audit-codex.md` binds the same sha, verdict approve, findings none, and
its history-invariant log records the same five hunk positions I measured
independently, plus `decision-section-byte-identical`,
`parameters-section-byte-identical`, `supersedes-published-byte-identical` and
`five-parameter-lines-unchanged`. Its `audit-r9-repository-vs-cited.diff`,
`audit-r9-archive-vs-cited.diff` and `audit-r9-archive-postcommit-vs-audit.diff`
are all zero bytes. Nothing in it contradicts the decision text.

## Completeness

**Required fields.** `## Decision`, `## Parameters`, `## Empirical check`,
`## Engines` in order, with `## Supersedes` last as the spec permits for a
reversal of a published exclusion, and `re-verify:` still the final line of
`## Decision`.

**Parameters.** One `- owns` line and four `- assumes` lines (`msrv-policy`,
`rust-edition`, `target-os-matrix`, `license`), `Consumed parameters: none`. The
owned value is byte-identical to the registry as measured above.

**Fitness gates.** All six present for `committed` 1.1.11 with evidence columns.
Gate 1 is recorded `inapplicable` with the owner's ruling of 2026-09-12 named
and the reason for keeping the row rather than deleting it. I confirmed the
ruling exists and reaches this far: `docs/planning/p02/execution-ledger.md:505`
records "OWNER RULING Q7.B, 2026-09-12: the licence check is void ENTIRELY …
Gate 1 is struck from every item's evaluation", and
`docs/port/OWNER-REVIEW.md:47` carries it verbatim. Per that ruling and my
task's instruction, the `AGPL-3.0` fact recorded for the excluded candidate is
correctly a recorded fact weighed in no gate, and I raise no licence finding.

**Owner acceptance and its citations.** The decision states the owner accepted
revision 8 on 2026-09-15 as `W0-R38` option A at sha256 `7e88ba81…`, citing
`docs/planning/p02/owner-decisions.md:356` and `docs/port/OWNER-REVIEW.md:139`.
Line 356 of the first file is the `W0-R38` row at that hash today. The second
citation needs a word: `docs/port/OWNER-REVIEW.md:139` held the R38 acceptance
row at commit `b9cccb6d…`, the commit carrying revision 9 — I checked with `git
show b9cccb6:docs/port/OWNER-REVIEW.md` — and the row has since moved to line 154
as other items were accepted into the same table. That is live-file drift after
the fact, not a defective citation, and it is not a finding.

**Supersedes — intact, and measured rather than accepted.** I extracted the
payload (line 308 to end of file), measured **82,801 bytes** with sha256
`97da7f169f26fce8f9b43c3d6c2eb0971b991f45b0d00ae2a91c5ddc3cbe4437`, and ran
`diff` against `research/topics/38-commit-message-linter/DECISION.md`: **no
differences**. The published file is the same 82,801 bytes at the same hash. The
section's own header states that size and that hash, so the document's claim
about its own payload is exact. This is the check that matters most for a
revision of a published decision, and it passes byte-for-byte.

**`BASELINE-REVIEW:` and `CONFLICT:` handling** is unchanged from the text the
revision-7 judgment audit certified (no hunk in `## Decision`; the `## Engines`
disposition of the Codex line is outside both changed hunks), and the open text
observation to name the twelve Doxa `BASELINE-REVIEW:` lines remains correctly
listed as open.

## Findings

Unresolved findings: **none**. Neither entry below is blocking: neither changes a
ground, a gate, a parameter value, a ledger row, an acceptance criterion or a
piece of evidence, and neither misdirects a reader to the wrong revision's
content. Both are recorded so the controller and a future revision can see they
were weighed rather than missed.

**JF-1 — the forward-looking archiving clause for the judgment auditor names a
launch that never happened, while the parallel clause for the empirical auditor
was updated to fact.** The decision's preamble (line 3) and its `## Engines`
revision note (line 259) both say of the revision-7 judgment audit:

> read at `review/audit-fable.md` and expected to be archived as
> `review/audit-fable.r7.md` when the controller launches the revision-8
> judgment audit

*The problem.* No revision-8 judgment audit was ever launched: revision 8 was
accepted by the owner and rejected by the revision-8 **empirical** auditor, and
the next judgment audit is this one, for revision 9 — the archiving the clause
predicts is the one I performed at the start of this round. Revision 9 rewrote
the sibling clause for the empirical auditor from its forward-looking form into
the past tense it had earned ("which the controller archived as
`review/audit-codex.r7.md` when it launched the revision-8 audit"), and left this
one unadjusted, which is the same asymmetry the revision-7 judgment audit
rejected revision 7 for.

*Why it is not blocking, stated explicitly because the standard matters.* The
defect that rejected revision 4 and revision 7 was a citation that sends a reader
to a path holding a **different revision's report** with no redirect — "still
under its live name", where a reader opening `review/audit-fable.md` would take
the revision-7 audit for the revision-5 one. Here the sentence carries the exact
repair the revision-7 judgment audit prescribed, naming the archive path
`review/audit-fable.r7.md`, and that path is correct: it is where the revision-7
judgment audit now lives. A reader is directed to the right bytes. What is wrong
is only the scheduling clause naming which launch triggered the move, and the
decision's own neighbouring text states the real pattern correctly (the
revision-5 audit "archived under that name when it launched the revision-7
judgment audit" — i.e. at the next judgment audit, whichever revision it serves).

*What would resolve it.* One clause, touching nothing else: replace "when the
controller launches the revision-8 judgment audit" with "when the controller
launched the revision-9 judgment audit", and move the clause to the past tense as
the empirical sibling already is.

**JF-2 — one of the three invocation forms claimed for the comparator is
uncorroborated by the empirical audit.** Line 250 states:

> The repair landed at commit `9684a5851c71f87bd0392ec09d97aba733f98139`, and
> all three invocation forms were then run against an extraction taken at that
> commit: absolute path with the working directory set to `/`, the previously
> breaking relative form from inside `review/evidence`, and the in-place run from
> the run directory. Each exited **0** and each `diff` against the log this
> decision cites … produced no output, which is why no fourth log is carried.

*The problem.* The revision-9 empirical audit exercised two of those three forms
— the in-place run from the run directory and the `cd / && bash
<temporary-directory>/…/r38-crossrun-compare-r9.sh` archive run — and I found no
execution of the third, the relative `bash r38-crossrun-compare-r9.sh` from
inside `review/evidence`, anywhere in `review/audit-codex-r9-transcript.txt`
(every match for `cd …review/evidence` in that transcript is a quotation of this
decision's own sentence, not a command). That third form is the one the
`9684a585` repair exists for, so the claim that it now passes rests on the
synthesizer's word. The commit itself is real and inspectable (7 insertions, 2
deletions, to that script alone), and the decision's reason for carrying no
fourth log — the outputs were byte-identical to the cited ones — is internally
coherent.

*Why it is not blocking.* The two forms the audit contract actually needs are the
two that were independently reproduced: the in-place run and the clean-archive
run. The third is a convenience invocation whose failure mode was a self-check
assertion reading its own file, not a change to any measured result.

*What would resolve it.* Either the empirical auditor runs that third form once
and records its exit and empty diff, or the decision narrows the sentence to the
two forms an auditor has reproduced and records the third as unverified here.

**Observations carried forward, not re-opened.** Observations 1, 2, 3, 5, 6, 7
and 8 from the revision-5 judgment audit, and the `(?i)` source-read and
263-repository code-search observations from the revision-7 judgment audit,
remain open and are correctly listed as open in `## Engines`. Each would change
text that two auditors approved on a question this revision's scope does not
touch.

## Assessment

Revision 9 is a narrow, correct repair of a real evidence defect, and its
narrowness is demonstrated rather than claimed: five single-line hunks at 1, 3,
250, 259 and 294, with `## Decision`, `## Parameters` and the `## Supersedes`
payload untouched, measured by diff against the accepted revision 8 rather than
accepted from the revision note.

The finding it adopts was genuine — the revision-7 comparator reached into the
Git object database for blob `a6e6641e…`, which a `git archive HEAD` extraction
deliberately lacks — and the repair is the right shape: carry the object as a
committed artifact, assert its digest and byte count before reading it, resolve
every path from the script's own location, and gate the one remaining
history-dependent assertion as a named `SKIP` rather than deleting it or letting
it pass vacuously. Every figure the new passage states — 14,374 bytes,
`cf9ffcb2…`, 106/106/0, 105/1, the identical post-commit log, the old
comparator's 0-in-repository and 1-with-three-failures-in-archive — I checked
against the artifact, and every one matched. The precedent it cites (R17
revision 6) is the same repair applied to the same defect, and the citation lands
on the line that describes it.

**The revision-7 rejection is closed.** That audit rejected on this clause of
revision 7: the revision-5 judgment audit was cited as "`review/audit-fable.md`
… **still under its live name**", which is the destination the role contract
fixes for every judgment audit, so the citation attributed a revision-7 report to
revision 5. Revision 9 carries the repaired text, made in revision 8 and
unchanged here: the revision-5 judgment audit is now cited as
"`review/audit-fable.r5.md` … which the controller archived under that name when
it launched the revision-7 judgment audit", in both the preamble and the
`## Engines` note. The path is the archived one, the attribution is right, and
the remaining imprecision is the scheduling clause recorded as JF-1, which
misnames a launch without misdirecting a reader.

**`## Supersedes` is intact**: 82,801 bytes, sha256 `97da7f16…`, byte-for-byte
identical to the published `research/topics/38-commit-message-linter/DECISION.md`,
which is the property a revision of a published decision most needs to hold and
most easily loses.

**The recommendation did not move.** `## Decision` and `## Parameters` carry no
diff hunk against revision 8, the sha the owner's acceptance binds
(`7e88ba81…`), and the owned parameter value is still byte-identical to
`docs/port/PARAMETERS.md:13` at 508 bytes. The owner's acceptance re-binds at
this revision on the terms the acceptance record itself states — a revision that
changes only reasoning or evidence re-binds; one that moves the recommendation
re-asks. **The owner is not re-asked.**

I approve. No finding is blocking, and the `unresolved-findings` field is `none`
because neither JF entry requires a change to any ground, gate, value or piece of
evidence in the decision.
