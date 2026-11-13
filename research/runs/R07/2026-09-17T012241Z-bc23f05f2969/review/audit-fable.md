decision-sha256: cb183382237157405fc09b00fd67a2f60475b52959df078f7fe2e830730dde27
actor: audit-fable-2026-09-05T162400Z-58ba22bff8ca-r4
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

This is the judgment audit of **revision 4**, a title-only revision made so that
`scripts/research_runner.py`'s `check_history` admits the decision for
publication. The round-3 audit of revision 3 (`a6193794…`) was archived
byte-identically to `review/audit-fable.r3.md` before this file was written;
`review/audit-fable.r1.md` still holds revision 1's. The substantive judgment of
this decision is round 3's and is not re-litigated here: this pass establishes
that revision 4 changes nothing round 3 approved, and that the reason given for
the change is true.

## Principle and agreement level

Unchanged, and verified unchanged rather than assumed. The full diff between
revision 3 and revision 4 (`git diff f15ccf8~1 f15ccf8`) touches one file and
consists of three hunks totalling **16 insertions and 1 deletion**: the H1 line
replaced, a thirteen-line revision note inserted beneath it, and one row
appended to the revision-history table. No other line of the document appears in
the diff. Every element the round-3 audit assessed — F060's principle and its
`policy/mechanism` agreement level from `docs/port/BASELINE-REVIEW.md:52`, the
F026 row at `docs/port/COMMONALITY.md:32`, the five essential behaviors, the
five acceptance criteria, *What may vary* and the ts visibility correction — is
outside the diff and therefore byte-identical.

## Design and evidence

**The recommendation and its evidence are untouched.** The `on:` block, the A-G
architecture table, the GitHub documentation quotations with their endpoints,
retrieval dates, HTTP statuses and byte counts, the two snapshots, the
12-of-134 and 134-run figures, the loop-guard result, `## Empirical check` in
all three parts, `## Engines` with both raws and the P03 list, and
`re-verify:` all lie outside the diff.

**The `## Supersedes` payload is still the published bytes.** `tail -c 26203` of
revision 4 hashes to `0b3dde8f9a15f22e60a01542065c53c122881e8c48bf3ee6c172ba5b70499346`
and diffs empty against
`research/topics/07-contributors-bot-trigger-cadence/DECISION.md`. The note's
claim that the payload did not move is therefore verified independently of the
diff: insertions above `## Supersedes` change the file's length but not its last
26,203 bytes, which is the property revision 3's check 5 was built on.

**The `- assumes` lines are unchanged and still byte-identical to
`docs/port/PARAMETERS.md`.** They sit at lines 574-577 (and, in the preserved
payload, 1397-1400), outside every diff hunk, and match rows 7-10 of
`docs/port/PARAMETERS.md` for `msrv-policy`, `rust-edition`,
`target-os-matrix` and `license`, as round 3 established.

**The note's stated mechanism is accurate in every particular**, checked by
reading `check_history` (`scripts/research_runner.py:323-331`) and by executing
it on both revisions:

- It splits on `"## Supersedes"` as a **substring**, not as a heading
  (`"\n".join(lines).split("## Supersedes", 1)[0]`), over the lines
  `outside_fences` returns — as the note says.
- It requires `(?m)^#(?:##)? \d{4}-\d{2}-\d{2}(?:\s|$)` in that region: an H1 or
  H3 heading that *begins* with a date — as the note says.
- At revision 3 the first substring occurrence was the prose mention on line 99,
  inside the revision-2 audit-finding list, and the `## Supersedes` heading was
  at line 1100 — **1,001 lines** below it, exactly the figure the note gives.
  Executing `check_history` on revision 3's bytes reproduces the region as 99
  lines with **no** dated heading and raises the documented error, "decision
  revision requires a dated current entry and ## Supersedes history".
- Executing it on revision 4's bytes against the published topic file returns
  **PASS**.

The second clause of `check_history` (line 330) is also satisfied and is worth
recording because it splits on `b"\n## Supersedes"`: the newline-anchored form
does not match the mid-line prose mentions, so the preserved-bytes test reads
the real payload region, where the published revision 1 is found verbatim.

**The H1 preserves the old title's words.** Old:
`# R07 — Contributors-bot trigger cadence — DECISION (revision 3, 2026-09-15)`.
New: `# 2026-09-16 — R07 — Contributors-bot trigger cadence — DECISION (revision 4)`.
The identifier `R07`, the item name *Contributors-bot trigger cadence*, the word
`DECISION` and the parenthesised revision marker all survive; the date moves
from inside the parentheses to the front, where the check requires it, and
advances to the day this revision was made, while the revision number advances
3 → 4. Nothing is dropped and nothing is renamed.

**The note does not overclaim.** It says "the H1 title line and nothing else",
then lists the note and the history row as the accompanying record, and the
history row itself points the reader away from itself — "Row 3 above, not this
row, records the last substantive change". That is the honest form for a
bookkeeping revision: it makes the revision auditable without inviting the
reader to treat it as a fourth substantive position.

## Completeness

Required fields are all present and unchanged apart from the two the revision
exists to change. The heading set is revision 3's with no addition or removal;
`re-verify:` is still the last line of `## Decision`; `## Supersedes` is still
last, with one heading occurrence and an unfenced, unwrapped payload; `owns:
none`, the four `- assumes` lines, `consumed researched parameters: none`, no
`CONFLICT:` line and `BASELINE-REVIEW findings: none` are all outside the diff.
The revision-history table now carries four rows, one per revision, each dated.

## Findings

**No unresolved finding.** No new observation. Round 3's three non-blocking
observations (O8, O9, O10 in `review/audit-fable.r3.md`) stand unchanged, since
none of them concerned the title line and none of the text they addressed moved.

## Assessment

Approve. Revision 4 is exactly what it says it is: a date-first H1, a note
explaining why, and one history row. The diff is 16 insertions and 1 deletion in
one file; the recommendation, every evidence citation, the parameter lines and
the `## Supersedes` payload are byte-identical to the revision 3 this auditor
approved and the owner accepted, with the payload independently re-hashed to the
published `0b3dde8f…`. The reason given for the change is true and was verified
against the code and by execution: `check_history` splits on the first
**substring** `## Supersedes`, which at revision 3 was a prose mention 1,001
lines above the heading, leaving a 99-line region with no dated heading; it
raises the documented error on revision 3's bytes and passes on revision 4's.
The new title preserves the old title's words. Nothing in this revision bears on
the substance of the decision, and the round-3 judgment stands.
