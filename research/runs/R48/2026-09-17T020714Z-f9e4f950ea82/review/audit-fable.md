decision-sha256: dc1ef152a473cd0a3a3811489cd1a8c98867e9e4751d33dc79b9f2faaf499782
actor: audit-fable-2026-09-17T020714Z-f9e4f950ea82-r3
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

Unchanged and unchallenged. Revision 3 is prose-only and touches nothing in this section:
F119 and F120 remain capabilities sourced to `docs/port/areas/testing-coverage.md:9-10` and
`docs/port/DIVERGENCE-ANALYSIS.md:177-178`, the settled rows are the two this item owns at
`docs/port/COMMONALITY.md:125-126`, and the `BASELINE-REVIEW: F120` narrowing stands in the
form round 2 accepted, quoting R01's F121 row in full. Round 1 verified this ground line by
line and I re-confirmed by diff that revision 3 does not alter a character of it.

## Design and evidence

**JF-9 is closed, and closed at six locations rather than the five I named.** I asked that
the five places crediting check D01 with compiling **both** selected members' dependency
trees be corrected. Revision 3 corrects all five and finds a sixth I had not listed. I
enumerated every `D01` occurrence in the revision-3 text mechanically rather than by
reading, and checked each:

| Location | Revision-3 text | Correct |
|---|---|---|
| revision-2 note, JF-4 row (line 33) | "`httpmock`'s tree in the feature-off run (D01, G01) and `mockall`'s in the feature-on run (D02, G02)", with revision 2's wording quoted as corrected | yes |
| `## Parameters` prose (line 531) | the same split, same citations | yes |
| spike table, D01 row (line 621) | "**`httpmock`'s whole resolved dependency tree compiles**… It establishes **nothing about `mockall`'s tree**… D02 is the check that carries that", revision 2's wording quoted as superseded | yes |
| spike table, D02 row | amended to state that it carries `mockall`'s tree — a location I did not name | yes |
| engine item 7 (line 789) | D02/D03 carry `mockall`'s tree, "while D01 does the same for `httpmock`'s tree at the floor (re-confirmed and re-labelled by G01 and G02)" | yes |
| unproven table, "Both selected members' dependency trees" (line 814) | "**Proven, by two checks and not one**", each tree attributed to its own run, D05 cited from the other side, revision 2's attribution named superseded | yes |
| unproven table, `mockito` row (line 815) | "the way D01 does for `httpmock`'s and D02 for `mockall`'s" — the sixth location, found by the synthesizer's own sweep | yes |

**Leaving the mis-worded log line unedited, with a stated correction and a new asserting
check, is not merely acceptable — it is better than the repair I prescribed.** I wrote
"Re-run script 2 so the log carries the corrected line." Revision 3 declined and gave its
reason, and the reason is stronger than my instruction. `r48-r2-msrv-macos-spike.sh` and its
log are committed artifacts that two audits read and that `review/audit-fable.r2.md` quotes
verbatim; re-running the script would have rewritten the text my own round-2 finding quotes,
orphaning its evidence. The runbook's governing principle for a claim made outside a script
is to put the assertion **into** a script before citing it, and that is exactly what
`r48-r3-tree-msrv-relabel.sh` does: it re-runs script 2's same two commands on the same
probe crate and asserts the split directly, rather than asserting it in prose about an
unedited log.

The new check is well built, and in particular it asserts the negative that carries the
finding. G01 asserts the feature-off run exits 0 with 1 passing test, **1** `Compiling
httpmock v0.8.3` line, **0** `Compiling mockall v` lines and **0** `Compiling mockall_derive
v` lines, concluding that the run "establishes NOTHING about mockall's". G02 asserts the
feature-on run exits 0 with 2 passing tests, **1** `Compiling mockall v0.15.0` and **1**
`Compiling mockall_derive v0.15.0`. A zero-count assertion is what makes this falsifiable in
the direction that matters: if a future `mockall` ceased to be feature-gated, G01 would FAIL
rather than pass vacuously. G00 repeats the outside-the-repository guard and G03 runs
`shellcheck` over all four scripts. The log's own header carries the correction — it states
that it "supersedes the WORDING of the D01 PASS line in r48-r2-msrv-macos-spike.log", that
the log "is a committed artifact and is not edited", and that "its D02 and D05 lines were
correct as written".

The one consequence of this choice is disclosed rather than hidden: `r48-r3-archive-rerun.log`
necessarily reproduces the wrongly-worded D01 `PASS` line beside the correct G01 line,
because it re-runs all four scripts. A reader meeting the pair is told which is right in
three places — the revision-3 note's dedicated "JF-9, the log line" row, the D01 row of the
spike table, and the new log's own header. That is the right trade: an erratum that stays
visible beats a silent rewrite of an artifact two audits have already certified.

**JF-10 is closed at both locations, and the exclusion I directed was honoured.** `## Decision`
no longer carries "Nothing was built here and no Rust was compiled by either engine or by
this synthesis". It now separates the three cases precisely — the template was not built and
its recommendation is not implemented; neither engine compiled anything; "the only Rust this
synthesis compiled is the throwaway probe crate described under `## Empirical check`, built
outside this repository to close two gates and deleted afterwards" — and quotes the retired
sentence in place. The `httpmock` gate-6 cell no longer says "**No wall-clock figure: nothing
was compiled**"; it now says what its `mockall` neighbour said, and goes further by naming
the fact that made the old wording false: "the spike's appendix does print times for
compiling this tree, but they are times for a two-method probe crate, not for the template
… `httpmock`'s tree is the one thing the spike compiled three times". I confirmed by
enumeration that the `## Engines` sentence I explicitly protected — that the two raw reports
"both report that nothing was compiled" — is untouched, which is correct because it is true
of codex and opus.

**Nothing moves.** I checked this three ways rather than asserting it. The members table is
byte-identical across revisions 2 and 3, including both occurrences of the `mockall = {
version = "0.15.0", optional = true }` manifest shape. All five `- assumes` lines are
byte-identical to column 4 of the matching `docs/port/PARAMETERS.md` row, re-extracted and
string-compared, and unchanged from revisions 1 and 2. No gate disposition changes: the
diff touches no gate cell except the `httpmock` gate-6 wording under JF-10, and that cell's
verdict stays `passes`. No `CONFLICT:` line appears, none is owed, and the `BASELINE-REVIEW`
is untouched.

**The diff is only what is claimed.** Commit `894f965` touches four paths: `review/DECISION.md`
and three new evidence files (`r48-r3-tree-msrv-relabel.sh`, `r48-r3-tree-msrv-relabel.log`,
`r48-r3-archive-rerun.log`). I read every hunk of the decision diff, and each maps onto one
of four intentions and nothing else: the JF-9 attribution split at its six locations; the
JF-10 sentence retirements at their two; the three-to-four script count carried through the
`## Empirical check` prose and the commands table; and the revision-note and revision-history
paragraphs recording revision 2's sha256, its commit, and this round's outcome. No
substantive sentence changed that I did not trace to one of those. I also verified
byte-identity of every carried artifact against `894f965~1`: `r48-claims-check.sh`,
`r48-claims-check.log`, `r48-archive-rerun.log`, `r48-r2-msrv-macos-spike.sh` and `.log`,
`r48-r2-citations-check.sh` and `.log`, and `r48-r2-archive-rerun.log` are all unchanged.

## Completeness

**Structure.** The four required H2s in order, none added, no `## Supersedes`, one
`### Principles and implementation`, and the `re-verify:` line closing `## Decision`. The
revision-3 note sits above `## Decision` as front matter beside the revision-2 note, so the
required H2 set is intact and the audit history is readable in one place.

**`## Parameters`.** Five `- assumes` lines, no `- owns` against the prompt's empty `owns:`,
bare values with the bearing-on-the-decision prose after the list, all five byte-identical
to the registry.

**Empirical check.** Four scripts, 35 checks, 35 PASS, 0 FAIL, 0 SKIP, exit 0 each, with the
commands table naming each script, its result and its log. I verified the reproducibility
claim mechanically instead of by eye: extracting every `PASS`/`FAIL`/`SKIP`/`RESULT` line
from the four committed logs in script order and diffing that against the same lines from
`r48-r3-archive-rerun.log` produces an empty diff — 35 `PASS` lines and 4 `RESULT: all
checks passed (0 FAIL)` lines, identical and in order, so the clean-extraction rerun claim
holds exactly as stated. Check identifiers remain disjoint (`C01`–`C20`, `D00`–`D05`,
`E01`–`E05`, `G00`–`G03`). Script 4 sets `set -uo pipefail`, builds under `mktemp -d` outside
the repository, and asserts content rather than exit status alone. The E05/G03 relationship
is stated precisely rather than glossed — E05 covers the three scripts that existed in
revision 2 and G03 covers all four — which is the honest description of two checks written
at different times.

**One observation, recorded deliberately as an observation and not as a finding.** In the
reproducibility paragraph, one sentence still reads "no download counter, star count,
open-issue count or active repository's `pushed_at` literal is printed in any of the three
**scripts' output**" while its neighbours were carried to four. I checked script 4's
assertion lines: G00–G03 print grep counts and fixed strings and no volatile counter of any
kind, so the property the sentence asserts is true of the fourth script as well. The sentence
therefore under-enumerates; it does not misstate any script's output. That is the distinction
I applied to JF-10 and I am applying it consistently here rather than leniently: JF-10 was
blocking because `## Decision` asserted categorically that no Rust was compiled when Rust had
been compiled, which is false of the run; an enumeration that says "three" where the claim
also holds of a fourth is a numeral to tidy at publication, not a statement the evidence
contradicts. It is recorded here so the packager or any later revision can correct it, and it
does not hold up this decision.

**One thing I re-examined and am recording so it is not reopened.** The `mockall` gate-2 cell
at line 330 still cites "(D01, D02)" for "the whole resolved tree compiles and its test
passes at 1.96.0". Read against line 621's flat statement that D01 "establishes nothing about
`mockall`'s tree", that pairing looks at first like a seventh location the sweep missed. It
is not, on the cell's own verb: D01 is the invocation that performed the MSRV-aware
resolution — its output records "Locking 113 packages to latest Rust 1.96.0 compatible
versions", and D04 confirms `mockall 0.15.0` and `mockall_derive 0.15.0` are pinned in the
resolved lockfile — while D02 compiled what that resolution selected. Citing both for a
sentence about a resolved tree compiling is therefore accurate, and it is the form I endorsed
in round 2 and directed the synthesizer to copy. It stands.

## Findings

None. JF-9 and JF-10 are both closed, each at every location I enumerated and, in JF-9's
case, at one more the synthesizer found itself. I raise no new finding: the single item I
identified in this round is the under-enumerated script count recorded under
`## Completeness`, which asserts nothing the evidence contradicts and which I decline to
mint as a finding on the standard I applied in the two previous rounds.

## Assessment

Approve, and the four questions put to this round answered in turn.

*Are JF-9 and JF-10 closed as required?* Yes. JF-9 at six locations, each quoting revision
2's superseded wording so the sweep can be checked rather than trusted, with `httpmock`'s
tree attributed to the feature-off run (D01, G01) and `mockall`'s to the feature-on run
(D02, G02). JF-10 at both, with the protected `## Engines` sentence left standing as
directed.

*Is leaving the mis-worded log line unedited, with a stated correction and a new asserting
check, acceptable?* Yes, and it is the better repair. The revision-2 script and log are
artifacts two audits read and the round-2 audit quotes verbatim; editing them would orphan
that record. The programme's rule is that a claim must be asserted by a script before it is
cited, and `r48-r3-tree-msrv-relabel.sh` asserts the split directly — G01's **0** `Compiling
mockall v` lines is the falsifiable negative the finding needed. The one cost, that the
clean-extraction rerun reproduces the wrongly-worded line beside the correct one, is
disclosed in three places rather than left for a reader to trip over.

*Is the diff only what is claimed?* Yes. Four paths in commit `894f965`, every decision hunk
traceable to JF-9, JF-10, the three-to-four count sweep, or the revision-history paragraph,
and all eight carried scripts and logs byte-identical to `894f965~1`.

*Does anything move?* No. The three members, their versions and manifest shapes are
byte-identical; the five `- assumes` values are byte-identical to the registry; no gate
disposition, no `BASELINE-REVIEW`, no engine settlement changes. The recommendation has not
moved once across three revisions and two rejections, which is the outcome the audit
structure is meant to produce: the findings were about what the document claimed of its own
evidence, never about what it recommends.

On the shape of this item overall, since it is now approved after two rejections. Round 1
rejected on a gate read two ways inside one document, a gate closed on inferred evidence,
uncited figures and a mis-attributed check. Round 2 found all four repaired — one of them by
going out and observing the thing rather than by taking the cheap demotion that was
available — and rejected on two sentences that the revision's own new facts had falsified.
Round 3 repairs those and adds a check so the correction is executed rather than asserted.
That is convergence, not circling, and the item did not need a fourth round to reach it.

Procedural notes, carried for the record. No round-2 or round-3 empirical audit exists —
Codex is out of usage — so rounds 2 and 3 are judgment only, and scripts 2, 3 and 4 have not
been reproduced by another family; the round-1 empirical audit (`review/audit-codex.md`,
verdict `approve`) reproduced script 1 in two environments and independently re-derived the
crates.io, RustSec, GitHub and `c2pa-rs` facts from their primary endpoints, and that
factual base is unchanged. I read the four committed logs and the clean-extraction rerun and
ran none of them; the only commands I ran were reads, hashes, diffs and greps over committed
files. Round 2's audit is archived byte-identical at `review/audit-fable.r2.md`, sha256
`5a0d02481579beefe04d530d89fd7e670a749cd8edb4b543a348893c6f127977`; round 1's remains at
`review/audit-fable.r1.md`. I did not edit the decision.
