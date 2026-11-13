decision-sha256: 4e0ae20af2cf39baeb60bc66e2890a54f35b6aacb38a0e8aeb75ca0f2ce08012
actor: audit-fable-2026-09-05T164358Z-eae89906c763-r6
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

This is the judgment audit of **revision 6**, a title-form repair of revision 5. The round-5 judgment audit is archived byte-identical at `review/audit-fable.r5.md` (sha256 `75ec635f92c11576e622e43f1694c8d86c607cd42162c421e609e368cc791daa`, binding `39a5e39c…`, verdict approve); the round-2 audit remains at `review/audit-fable.r2.md`. Revision 5 was approved by both audits and accepted by the owner but could not be republished, so the research question this round asks is narrow: does revision 6 change anything beyond what the publication gate forced, and are its consequent corrections true?

## Principle and agreement level

Untouched, and verifiably so rather than by assertion. The diff between revision 5 (`ef944e5~1`) and revision 6 (`ef944e5`) is three hunks totalling 11 insertions and 3 deletions, and no hunk reaches `## Decision`, `### Principles and implementation`, `## Parameters`, `## Engines` or the fenced payload. Principle A (F122) remains at **capability** level, Principle B (F123) at **policy plus one architectural property**, both sourced to py at pin `b08bccfb` through check 10. The `BASELINE-REVIEW:` and `CONFLICT:` handling, the cause-class D reading of the TypeScript absence, and both ledger rows are byte-identical to the text I approved in round 5. Nothing in this revision is a research act, so the round-5 findings on principle, design and evidence stand unchanged and are not re-litigated here.

## Design and evidence

**The selection is untouched.** `proptest` 1.11.0, `insta` 1.48.0 and `cargo-insta` 1.48, the A1–A4 and B1–B4 verdicts, the seven acceptance criteria, the six-by-three fitness-gate table with gate 1 `inapplicable` under the 2026-09-12 Q7.B ruling, the ratio table and its `moved=3 held=3 of 6` result, both evidence scripts and the saved log are all outside the diff.

**The diagnosis is correct, and I reproduced the failure rather than accepting the account of it.** `scripts/research_runner.py:323` builds `lines = outside_fences(text)`, splits their join at the **first substring occurrence** of `## Supersedes`, and requires `^#(?:##)? \d{4}-\d{2}-\d{2}` somewhere in the prefix. At revision 5 the first occurrence was the prose mention inside line 7, so the inspected region was the first six lines plus the opening of the seventh; revision 5's H1 was `# R33 property-and-snapshot-testing — decision (revision 5, 2026-09-15)`, which is not date-first, and the three dated `### 2026-09-13`/`### 2026-09-15` revision-log headings sit far below that first mention and so were never in the region. Running the real function confirms both halves: `check_history` raises `decision revision requires a dated current entry and ## Supersedes history` on the revision-5 bytes and **passes** on the revision-6 bytes. A date-first H1 on line 1 precedes every occurrence, including the two the new note itself introduces, so the repair is the minimal one that actually fixes the gate rather than a cosmetic retitle.

**The diff is exactly the four things claimed.** A word-level diff of the two corrected paragraphs shows the *only* changed tokens are numbers: `287`→`295`, `518`→`526`, `'288,517p'`→`'296,525p'`, `452,`→`460,`. Every other word in both paragraphs is unchanged. The remaining additions are the new H1, the revision-6 note, and the `### 2026-09-16 — revision 6` subsection. Eight inserted lines above the fenced payload, which is exactly the shift the corrections apply.

**Each corrected citation returns what the decision says it must — this was the check that could have failed, and it did not.**

- `sed -n '296,525p' review/DECISION.md | shasum -a 256` returns `1bf96b43e0198e07bccca2ca4ecf0d5a6a2afb939260d896b8eca4814757a068`, and a direct `diff` of that range against `research/topics/33-property-and-snapshot-testing/DECISION.md` is empty. The payload is still the published revision-2 bytes.
- Line 295 is the opening ` ```markdown ` fence and line 526 is the closing fence, so "the block runs from line 295 to line 526" is literally true; the file is 526 lines.
- `/usr/bin/grep -n '^## '` puts the active `## Empirical check` at 161 and the second at **460**, as the corrected sentence claims.

Correcting these rather than leaving them false was the right call and is the difference between a retitle and a defective one: a line-number citation that a reader can execute is a claim, and the eight-line shift would have falsified all four.

**The enumeration behind the corrections is complete, checked independently.** The subsection claims that searching revision 5's active region for the figures 287, 288, 452, 517 and 518 returned exactly lines 7 and 169. My own grep of revision 5's active region (lines 1–282, ending at the first `## Supersedes` substring) returns exactly those two lines and nothing else. In revision 6 no stale citation survives: the only occurrences of the old figures anywhere in the active region are at line 3 and line 289, and both are self-describing statements *about* the correction ("corrected from lines 287 and 518 to lines 295 and 526", "a search … for the figures 287, 288, 452, 517 and 518"), not claims about where anything now sits. The four self-locating figures the subsection sets aside are correctly set aside, verified one by one at revision-5 positions: L65 is the Principle B paragraph whose `line 36` and `line 7` cite py's `tests/cli/test_help_snapshots.py`; L179 is the tier-2 paragraph whose `sed -n '1,45p'` cites a fetched upstream manifest; L188 is the check-4b paragraph citing evidence-log lines 142 to 250; L271 carries the round-4 auditor's own `review/DECISION.md:427` words about revision 4. None is about this file, so none needed a shift.

## Completeness

- **Bound hash:** `4e0ae20af2cf39baeb60bc66e2890a54f35b6aacb38a0e8aeb75ca0f2ce08012`, the full revision-6 file, matching commit `ef944e5`.
- **Parameter lines:** all four `- assumes` lines (decision lines 150–153) reproduce `docs/port/PARAMETERS.md` rows 7–10 byte-for-byte and are outside the diff.
- **`check_history`:** passes on the run bytes against the published topic file, by execution, not inspection. Its second clause — that the prior published bytes survive verbatim after the first `\n## Supersedes` — is satisfied by the payload check above.
- **Header-field constraint:** no line outside a fence begins with a header-field name; the six fields appear exactly once each, in the header block.

Two disclosed scoping choices, both **acceptable, neither a finding**:

1. *The revision-6 subsection cites line 65, 179, 188 and 271 as revision-5 positions* (now 67, 181, 190 and 273), governed by the "of revision 5" clause on the first pair it enumerates. This is a dated `###` revision-log entry recording the search that produced the corrections, not a live claim in an active section — the distinction that revision 5 itself drew when it corrected a stale reference *in place with a note* inside a `###` subsection while correcting active text outright. Revision 6 applies the same rule and says so. Every cited position is factually true of the file it names, and I verified the +2 mapping for each. Faulting this would move the bar that revisions 4 and 5 were approved against; the round-4 defect was a live claim in an active section, which this is not.
2. *Line 5's preamble still describes revision 5's synthesizer and inputs.* The revision-6 note sits at line 3, **above** the preamble, and states that this revision changes the H1 and two dependent line-number citations "and nothing else"; the `### 2026-09-16 — revision 6` subsection repeats that no research content moves. A reader therefore meets the scope before the preamble. The preamble's audit list is stale in the way revision 5 documented at length and cannot escape — a decision is written before its own audit is filed — which I recorded as expected rather than defective in round 5. Rewriting the preamble would be a materially larger edit to a revision whose whole merit is that it changes as little as possible, and would carry its own risk of error.

For the same reason the earlier observation still holds and is still not a defect: `review/audit-codex.md` has moved on again, and `research/topics/33-property-and-snapshot-testing/acceptance.json` remains stale against this revision. The decision names the latter as the publisher's to regenerate, which is the correct boundary.

## Findings

None.

## Assessment

Revision 6 does what a publication-gate repair should do and no more. It fixes a real and reproducible blocker — I ran `check_history` and watched revision 5 fail with the stated error and revision 6 pass — with the smallest edit that clears it, and it does not treat the retitle as licence to revisit anything else. The part that distinguishes a careful repair from a careless one is the handling of the eight-line shift: four executable citations would have been falsified by it, and all four were corrected and now return exactly what they promise. The enumeration behind those corrections is complete by my own independent search, and the figures deliberately left alone are correctly identified as citations of other files. The payload still hashes to the published revision-2 bytes, the parameter lines are untouched, and the selection, principles, gates and evidence I approved at revision 5 are outside the diff in their entirety. Both disclosed scoping choices are consistent with the convention this item has applied since revision 4 and were disclosed rather than discovered. Revision 6 is fit to publish.
