decision-sha256: 2018fcdb67d5e265b27ede87259bfb31fd67e0ded6d57a71ff206a1ab0c8e5e6
actor: audit-claude-r11-r8-2026-11-27
model: claude-opus-5-5
family: anthropic
verdict: approve
unresolved-findings: none

# R11 revision 8: empirical audit (claude seat)

**Scope.** This audit covers the R11 revision-8 flag-day touch-up in `/tmp/p02-flagday/drafts/R11-DECISION.md`. Revision 8 re-derives the `assumes web-extra-surface` line from R69 revision 11. All checks were read-only. No repository file was edited. The only scratch outputs are `/tmp/r11h.md`, the draft's head above the supersession heading, and an in-memory comparison.

## Results

| # | Check | Method | Result |
|---|---|---|---|
| 1 | Draft hash | `shasum -a 256` on the draft | `2018fcdb67d5e265b27ede87259bfb31fd67e0ded6d57a71ff206a1ab0c8e5e6`, which matches the expected value. **Pass** |
| 2 | Head structure | Split the draft at the first `\n\n## Supersedes\n\n` (exactly 1 occurrence) and scanned the head. | The H2 headings, in order, are `## Decision` (line 89), `## Parameters` (323), `## Empirical check` (351) and `## Engines` (390). There is exactly 1 `### Principles and implementation` (line 153) and exactly 1 line starting `re-verify:`. The string `## Supersedes` occurs 0 times in the head. **Pass** |
| 3 | `owns ci-job-structure` value | Python string equality between the value after `- owns ci-job-structure = ` and column 4 of the `ci-job-structure` row in `docs/port/PARAMETERS.md` (line 12). | The two are equal byte for byte. **Pass** |
| 4 | `assumes web-extra-surface` value | Python string equality between the value after `- assumes web-extra-surface = ` and the value after `- owns web-extra-surface = ` on line 1885 of `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`. | The two are equal byte for byte. **Pass** |
| 5 | Supersession tail | Compared every byte after `\n\n## Supersedes\n\n` with `research/topics/11-ci-workflow-job-structure/DECISION.md`. | Both are 139,946 bytes and identical. That file hashes to `410e88e5195a08def126037e9c451988633b1e48437ac82edca0a08c7a62418c`, the revision-7 hash the revision note cites. The published file has no supersession heading of its own, so the whole of revision 7 is carried verbatim. **Pass** |
| 6 | Recommendation, fixtures and evidence unchanged | `diff` between published revision 7 and the draft head (461 lines). | There are exactly 6 hunks, listed below. **Pass** |

## Check 6: the diff hunks

Every hunk matches what the revision note declares:

| Hunk (rev 7 → rev 8) | Content | Declared? |
|---|---|---|
| `1c1` | Title moves from revision 7 to revision 8, dated 2026-11-27 | Yes ("beyond the heading") |
| `2a3,7` | Adds the revision-8 note and its "Nothing else moves" paragraph | Yes |
| `80c85` | Provenance line: the backticked supersession-heading token is reworded as "the supersession section" | Yes (change 4) |
| `316c321` | `re-verify:` records that the R69 revision-11 trigger fired and was re-derived | Yes (change 3) |
| `325c330` | The `assumes web-extra-surface` line now carries R69 revision 11's bytes, as verified in check 4 | Yes (change 1) |
| `329c334` | The note the `assumes web-extra-surface` line requires is rewritten for revision 11 | Yes (change 2) |

No hunk touches the `## Decision` recommendation text, the six job ids, the tiers, the detector body, any `needs:` edge or job condition, the `owns ci-job-structure` line, the `## Empirical check` fixture cases or results, or the `## Engines` section. `git status` shows no modifications under `research/runs/R11`, `research/topics/11-ci-workflow-job-structure` or `docs/port/PARAMETERS.md`, so the carried evidence files are unchanged on disk.

## Non-blocking editorial observation (does not block approval)

- **Where:** the draft's line 85, inside the revision-7 provenance paragraph.
- **What:** the mechanical reword produced "Nothing has been published for R11, so there is no the supersession section." That sentence has a stray "the". Read at revision 8, it also says no supersession section exists, while the draft now contains one.
- **Why it does not block:** the sentence describes the state when revision 7 was written, and that was true then. It does not affect any parameter, structural gate or byte-match property. A wording such as "so revision 7 had no supersession section" would be clearer.
- **If fixed:** the edit would change the decision-sha256, so the audit would have to be rerun.

## Conclusion

All six requested empirical checks pass. Revision 8 changes exactly the five things it declares, plus the heading. The recommendation, fixtures and carried evidence results are byte-identical to revision 7.