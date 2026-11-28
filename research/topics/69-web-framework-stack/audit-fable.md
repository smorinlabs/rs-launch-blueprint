decision-sha256: 2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815
actor: audit-fable-r69-r11-2026-11-27
model: claude-opus-5-5
family: anthropic
verdict: approve
unresolved-findings: none

# R69 revision 11: judgment audit (fable seat)

**Scope.** This audit reviews `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` at revision 11. It judges the revision against `research/RUNBOOK.md` §7, the round-economy rules from owner decision Q23. Under §7.1, a finding is BLOCKING only if it changes an outcome. Every check was read-only. No repository file was edited, no git write was made, no runner was invoked and no paid API was called.

## Hash and identity gate

| Artifact | Expected sha256 | Observed |
|---|---|---|
| `review/DECISION.md` (revision 11) | `2806a1f0…bc1815` | match |
| `review/R69-r10-snapshot.md` (owner-accepted revision 10) | `d34ab6e8…f7fce0a` | match |
| `research/topics/69-web-framework-stack/DECISION.md` (published revision 9) | `d4507f5b…c2c10d` | match |
| Last 2472 lines of revision 11, the preserved bytes below `## Supersedes` | `d4507f5b…c2c10d` | match |
| Last 2472 lines of the revision-10 snapshot | `d4507f5b…c2c10d` | match |

- `## Supersedes` is at line 2779 in revision 11 and was at line 2685 in revision 10. The section opens with a prose preamble, the line "The complete revision-9 entry follows, preserved verbatim.", and then the published file byte for byte. The preamble begins at line 2781. The published bytes begin at line 2785 and run to the end of the file.
- Line 1885 is the `- owns web-extra-surface = …` line. It is byte-identical to line 1791 of the revision-10 snapshot. The only change is its line number, which follows from the longer revision note.

## Scope of the revision-11 change

`diff R69-r10-snapshot.md DECISION.md` reports exactly three hunks, 116 changed lines in total:

1. **Lines 1–9 → 1–101.** This hunk holds the title change `(revision 10)` → `(revision 11)`, the new revision-11 note, and the revision-10 heading rewritten into retention form. The retention heading keeps the original heading text after "Its own heading recorded it as:".
2. **Lines 125–126 → 217–220.** The "on every run" sentence now names `supersession-check-r11.sh`. It also names the 309 rows of `review/CARRIED-FROM.md` and adds the `review/identities.json` qualification.
3. **Line 134 → 228.** The results-table row for `supersession-check-r10.sh` now scopes its 23/23 result to commit `c6b7d2b1`. It records exit 1 on any tree that holds a fresh audit and names the successor script.

Snapshot lines 10 onward match revision-11 lines 102 onward except at the two retained-note sites the revision-11 note lists. The diff touches nothing else, so none of the following changed:

- the recommendation;
- the owned value `web-extra-surface`;
- the five `- assumes` lines (`msrv-policy`, `rust-edition`, `target-os-matrix`, `license`, `http-transport-injection-seam`);
- the crates and pins `axum` 0.8.9, `tokio` 1.53.1, `tower` 0.5.3 and `bacon` 3.25.0, and their feature lists;
- the exclusions, the fitness-gate answers, the alternative rankings and the engine adjudications;
- the `re-verify:` line at line 1881.

Each of the 8 `review/evidence/*-r10*` files has exactly one commit in `git log`. Their bytes have therefore not changed, which matches the note's claim. The revision-11 artifacts are present:

- `supersession-check-r11.log` (2957 bytes);
- `supersession-check-r11-archive.diff` (1006 bytes);
- `supersession-check-r11-rerun.diff` (0 bytes).

## EF-1 repair against the finding's own repair text

`audit-claude.r10.md` raised EF-1 as its only finding: `supersession-check-r10.sh` exits 1 once fresh audits exist. Its prescribed repair maps onto the successor script as follows:

| Prescribed in EF-1 | Revision 11 |
|---|---|
| Build the S8 file set from the 309 rows of `CARRIED-FROM.md` | Done. `S8a` reports 309 rows. |
| S9 passes on a present audit that is byte-different from the round-9 copy | Done. `audit-fable.md` (`824870fc…`) differs from the round-9 copy (`d6a20bd6…`), so S9 passes. |
| Rerun in place and from an archive; record the results | Done. The rerun diff is empty. The archive diff differs only by S10a–S10c SKIP. |
| Update the results table, and the "on every run" sentence if the script still cannot honour it | Done. Both sites are edited and the edits are disclosed. |
| Allow an `-r10b`-style successor instead of an in-place edit | `-r11` successor. The revision-10 bytes are kept as the record. |

**Deviation, disclosed.** EF-1 expected the row-based set to keep `identities.json` out of the comparison. That file is itself one of the 309 rows, so the row-based set cannot exclude it. Revision 11 does not exclude it silently. It qualifies the sentence instead. That is the more honest option, and it is permitted by the clause "if the repaired script still cannot honour it".

## Empirical seat cross-check (`audit-codex.r11.md`, approve)

The empirical seat's audit binds `2806a1f0…`. It reproduces `supersession-check-r11.sh` with exit 0 and 23/23 checks on two runs, each byte-identical to the committed log. Its archive copy yields 20 passes, 0 failures and 3 skips, matching the committed archive diff. Each of its four observations is disclosed and fails the §7.1 outcome bar:

| Observation | What it found | Disclosed where | Why it is not BLOCKING |
|---|---|---|---|
| O1 | `owned-value-check-r10.sh` fails only `V1a`: the heading is expected at line 2685 and is now at 2779 | Revision-11 note, "a carried check this revision knowingly breaks" | Layout drift in a historical check. The note leaves the repair to the owner. No conclusion moves. |
| O2 | A future replacement of `identities.json` `audits.*` entries trips `S8c` (reproduced in `/tmp` only) | Revision-11 note, "What 'on every run' still cannot cover", and lines 218–220 | A known limit, stated in the decision. It is not a false claim. |
| O3 | `supersession-check-r10.sh` exits 1 with 16 passes and 7 failures. `owner-reference-check-r9.sh` now sees one prompt match. | Supersession at lines 23–49 and 228. W0-R69p drift. | A superseded script, plus point-in-time input drift. §7.7 bars re-pinning that drift. |
| O4 | `state-bound-check.sh` shows only a 1.98.0 → 1.98.1 toolchain line. A `bacon` cache miss blocks the offline rerun. | Environment differences | Neither disproves a committed result. The recommendation does not depend on them. |

## Published-file structure (`research/topics/69-web-framework-stack/DECISION.md`)

- **H2 headings, in order:**
  - `## Decision` (line 663);
  - `## Parameters` (line 1584);
  - `## Empirical check` (line 1632);
  - `## Engines` (line 2144).
- **`### Principles and implementation`:** appears exactly once.
- **`re-verify:`:** appears exactly once, at line 1582, in the Decision section. The published file is revision 9, so it has no `## Supersedes` of its own. In revision 11, the current entry's single `re-verify:` line (line 1881) sits above `## Supersedes` (line 2779). A second `re-verify:` line (line 4366) appears only inside the preserved revision-9 bytes.

## Judgment

The revision repairs EF-1 and nothing else. Every edit outside the new note is one of the two retained-note sites the note itself lists. The recommendation, the owned value, the assumptions and the evidence base are byte-stable. Both residual limits are disclosed: the broken `V1a` pin and the `identities.json` row. Neither changes an outcome, and §7.5 approve-with-repair would cover either.

No BLOCKING contradiction under §7 or Q23 exists. **Verdict: approve.**

Owner note, not a finding: repairing `owned-value-check-r10.sh` `V1a`, or retiring it, is still open, and the decision text hands that call to the owner.