decision-sha256: 4329ce48b428b70cab0bea32e71bb725471faac2c88356f3b0fa9b005fc5772e
actor: audit-fable-2026-09-05T183003Z-c02279aa76ae-r5
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

Unchanged from revision 4 and carried, not re-argued. I established that
mechanically rather than by re-reading: `git cat-file blob ec356a0d…` (the
revision-4 blob, sha256 `ebcbe236…`) diffed against the live file produces
**exactly four hunks**, and all four sit in the revision note, the check-16/17
disclosure paragraphs, check 17's table row, and the revision-4 history entry.
Nothing in `## Decision`, `### Principles and implementation`, `## Parameters`,
the fitness gates, `## Engines` or `## Uncertainty` moves by a byte. So the
shared requirement — one Markdown file per topic in a purpose-organized tree, a
contributor-maintained navigation index, exactly one README entry point — is
still stated at **architectural pattern** level, which is what
`docs/port/BASELINE-REVIEW.md:129` records for F347; both `BASELINE-REVIEW:`
lines, the `CONFLICT:`-free gate-5 finding, and the correctly absent
`## Supersedes` (R81 is `open` in `research/CLAUDE.md`) are the same text round 4
cleared. Check 19 asserts all of this as 37 byte-identical regions, and every one
of them passes in my own run.

## Design and evidence

**Press 1 — J4 is closed exactly. Every assertion the decision names is the
assertion that printed in a run I made myself.** I cloned this repository
(`git clone --local --no-hardlinks`) into a scratch directory at
`research/p02-execution`, confirmed the clone's `DECISION.md` carries the bound
sha256, and ran all three scripts from the run directory inside that clone.
Nothing in the working repository was written: `git status --porcelain --
research/runs/R81` in the live checkout shows only the six pre-existing staged
additions and no modification under `review/evidence/snapshots/`.

| Script, run by me against revision 5 | Exit | `PASS` | `FAIL` | `failed assertions:` | Decision's claim |
|---|---:|---:|---:|---:|---|
| `docs-delivery-claims.sh` | 1 | 152 (119 in checks 1–15, 33 in check 16) | 2 | 1 | matches, count for count |
| `docs-delivery-claims-r4.sh` | 1 | 99 (86 in check 17, 13 in check 18) | 2 | 1 | matches |
| `docs-delivery-claims-r5.sh` | 0 | 126 (110 in check 19, 16 in check 20) | 0 | 0 | matches |

The two `FAIL` lines the decision quotes verbatim for the old script are the two
lines my run printed, to the column:
`FAIL  region marker not found: unproven entry 3 (unsafe posture)      r2=True r3=False`
and `FAIL  revision-3 untouched-region diff                           expected=0 actual=1`.
`ASSERT hunk_count_is_17=True` prints and passes, exactly as the decision now
says and contrary to what revision 4 said. The r4 script's failures are the title
and the region-and-text wrapper, and its hunk gate also still passes at 17 — the
decision calls that out as the thing "an author writing this paragraph by
construction would have predicted" wrongly, which is the J4 lesson applied rather
than restated. `docs-delivery-claims-r5.sh` exits 0; I ran it twice and both
outputs are byte-identical to each other and to the recorded
`review/evidence/docs-delivery-claims-r5.log` (`4b021db2…`), which with the
empirical auditor's three reruns makes five independent reproductions.

The disclosure's supporting numbers hold where they can be checked. Row 19's
counts are the run's counts: 37 regions byte-identical, 46 texts present, 15
absent, `title names revision 5`, `no ## Supersedes`, `ASSERT
r5_hunk_count_is_4=True`. Row 17's counts are the recorded revision-4 log's
counts (26 / 8 / 34 / 11, check 18 over seven artifacts). The citation at lines
994–996 is real: the sentence "The old script's revision-2 hunk-count assertion
still passes at 17; the changed-region assertion is the direct failure" is at
`review/audit-codex.r4.md:17` — that file was `review/audit-codex.md` when
revision 5 was written, which is the path convention this document uses
throughout.

The replaced citation is the sharper improvement. Revision 4 had rested the
snapshot claim on the r4 empirical audit, which states "No command wrote to the
shared `review/evidence/snapshots/` directory" — and that is wrong: rerunning the
old script in my clone modified `github-creating-diagrams.html`,
`mpl-2.0-faq.html` and `n_github-diagrams.txt`, the three files revision 5 now
names in its own voice. Check 19 asserts the mis-citation absent. A revision that
drops a convenient citation from its approving auditor because its own run
contradicts it is doing the thing J4 asked for.

*Observation, not a finding — check 20's inventory undercounts itself.* Row 1077
and line 965 say check 20 hashes **nine** artifacts, "check 18's seven … plus
`docs-delivery-claims-r4.sh` and `docs-delivery-claims-r4.log`", and both places
say "the three auditors' logs". The check hashes **ten**, and there are four
auditors' logs: `audit-docs-delivery-model-r4.log` (sha256 `2ca46e18…`,
byte-identical to `docs-delivery-claims-r4.log`) is asserted and unnamed. This is
the residue of the authoring habit J4 named, but it lands on an inventory line
rather than on a failure attribution and it errs **conservatively** — the check
preserves one artifact more than the decision claims, so no reader is misled
about the strength of anything, and no cited fact rests on the count. Every other
count I checked matched its log. Two words at publication ("ten", "four"). I
route it to the consolidation below rather than spend a revision on it.

**Press 3 — everything round 4 cleared, re-confirmed.** The strongest form of
this confirmation is the four-hunk diff above: the shipped-site notice rule, gap
4, the six-gate block with gate 5's install-line resolution and gate 1's
`inapplicable` line, ground 2's narrowed confidence statement, the runner-up
comparison and `## Uncertainty` are byte-identical to the text round 4 examined
on the merits, and check 19 asserts each as a named region. I also re-took the
two figures that do not live inside the decision: check 12 printed
`six F342 categories: total .md files 35` and `total bytes 171225` in my live
rerun, and check 10's parameter round-trip printed an empty diff — I confirmed
the four `- assumes` lines (`DECISION.md:775-778`) against
`docs/port/PARAMETERS.md:7-10` directly, and all four values, `license = MIT OR
Apache-2.0` included, are byte-identical to the `fixed` rows. `review/audit-codex.md`
is the revision-5 audit, binds the same sha256, approves with no unresolved
findings, and its reported figures (152/2/1, 99/2/1, 126/0/0 across three reruns)
are my figures.

## Completeness

Every runbook H2 is present and in order; `## Supersedes` correctly absent. The
unproven list, "What P03 must validate" and the source dates are the revision-4
text, unchanged — including the correct posture that this decision must not
implement its own recommendation, and records what would prove each claim
instead.

**Press 2 — the history has not become the document, but a consolidation is
warranted at publication.** What is asserted about this recommendation's evidence
today is recoverable, and correct, in three layers: checks 1–15 still pass
individually (my run: 119 `PASS`, 0 `FAIL` among them) inside a script whose
whole-file exit is 1 because of check 16 alone; checks 16 and 17 are history,
each preserved by sha256 and each with its current failure disclosed from a run;
and checks 19 and 20 are the only assertions that exit 0 today, carrying forward
every region 16 and 17 asserted plus the hashes of both retired scripts and their
logs. Nothing is lost and nothing is overstated — which is why this is an
observation and not a finding.

The cost is that the reader assembles that from three tables, twenty rows and
roughly 110 lines of prose, and that row 16 still shows `Exit | 0` with no in-row
annotation, where row 17 carries "Recorded as run against **revision 4**". At
publication, one short "current assertion status" paragraph — checks 19 and 20
are live and exit 0; checks 1–15's facts stand, gated by a script that now exits
1 on check 16 alone; checks 16, 17 and 18 are preserved history, hash-asserted —
would let a reader see the live state without reading the chain. The same
paragraph is the natural home for the row-20 count repair. Neither is a defect in
what revision 5 claims.

For completeness on the `ASSERT` convention: the r5 log's four `@@` lines are
printed and gated by the count assertion that follows them, exactly as check 7's
grep listing is gated by the counts that follow it under revision 3's own stated
convention, so "every line of that log is content-asserted" reads within that
convention and the log reproduces byte-for-byte regardless.

## Findings

None.

## Assessment

**The recommendation follows from the evidence, and the owner can accept this
revision.** The chain is untouched since revision 3: the owner ruling left the
question open by striking a tiebreaker the decision itself had disowned; checks 5
and 6 establish that mdBook 0.5 costs the raw-source reader nothing, which is the
ground carrying most weight and which does not depend on the practice sample;
check 12 measures the six-category corpus the owner already fixed; check 14
supplies the capability a bullet list cannot. Ship the generator at medium
confidence, with the scope limit stated in the same breath and a one-commit
reversal, remains a defensible design call marked as the one call no source makes
for it.

J4 — the only finding standing against revision 4 — is closed exactly and in the
right way. The decision now names the assertions that actually printed, records
the re-anchoring of unproven entry 3 in both the prose and check 17's own row,
drops the false causal clause and the overstated "carries every region assertion
check 16 made", discloses check 17's own failure from a run rather than from
construction (including the hunk gate that did *not* move, against expectation),
and replaces a citation its own auditor got wrong with an observation it made
itself. It did all of that without editing a preserved script, a preserved log,
or one byte of the recommendation. The two residual imprecisions I found are an
inventory undercount that errs toward understatement and a presentational
consolidation worth doing once, at publication; neither is a claim the evidence
fails to support, so neither is an unresolved finding and the verdict is approve.
