actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: d8c64f7c36663f0c92dcc83cc444a56f203f6c4f52d3fff2a64de9f611cfd2e7
verdict: approve
unresolved-findings: none

# R02 revision 3 — directed verification of the round-2 repairs (judgment side)

**Scope.** This audit verifies only the eight repairs that the round-2 audits enumerated (`EA-1`–`EA-6` in `review/audit-claude.md`, `JF-5` and `JF-6` in `review/audit-fable.md`) and their knock-on edits. It does not look for new findings. Anything outside those repairs is recorded under *Observations* and is not a dispute. The audit read scripts, logs and snapshots and recomputed sha256 values. It reran no script; the empirical seat covers execution.

**Hash gate.** `shasum -a 256 review/DECISION.md` → `283c6dd0…a1d3`, which equals the target, so the audit proceeded. `review/R02-r2-snapshot.md` hashes to `9e8f8e8c…707f`, which is revision 2's sha as bound by both round-2 audits. The diff below is therefore taken against the audited text.

## Diff review: the recommendation and parameters are unmoved

`diff R02-r2-snapshot.md DECISION.md` produces 15 hunks. Every hunk lands on an enumerated site: line 1, lines 3–16, and lines 28, 213, 231, 236, 239, 241, 243–244, 248–249, 252, 258–260, 266, 277, 279 and 297. No hunk touches:

- `## Decision`'s recommendation, topology, mechanisms, rankings or tiers;
- the `OVERRIDE (OV-03)` section;
- the `CONFLICT:` or `re-verify:` lines;
- the four `- assumes` lines.

Therefore the recommendation, `OVERRIDE (OV-03)` and every parameter value are byte-identical to revision 2. The recorded log agrees: `R2-8e`, `R2-8h`, `R2-8i` and `R2-6b` pass.

## Per-repair confirmation

| Repair | Site checked | Result |
|---|---|---|
| **EA-1** | `r02-check-r2.sh` lines 411–438 classify each hit. A path under `docs/port/*` counts as an owner record. Any other hit must have zero `^#+ .*OV-03` heading lines and zero `OV-03` lines lacking `R02` or `taken`; otherwise it is counted as `UNCLASSIFIED` and fails. Line 440: `R2-9b` now asserts only that the two `docs/port/` paths are present; its message carries no count. DECISION line 248 contains "At commit `542ad225` (2026-09-27), four files name it" and states the rule. Line 241 quotes revision 2's byte-identical sentence as *Superseded wording* and gives the reason. `r02-check-r2.log` ends `CHECKS RUN: 66 FAILURES: 0 SKIPPED: 0`, so the script exits 0 by its last line. It lists 4 references, each classified. | **Confirmed** |
| **EA-2** | Lines 451 and 458 read `'^#+ .*OVERRIDE \(OV-03\)'` and `'^#+ .*OVERRIDE \(OV-02\)'`. The log records `R2-9d == 0` and `R2-9e` with 1 control hit. DECISION line 248's `R2-9d`/`R2-9e` sentences say "by a heading at any level, backticks tolerated" and describe the control. | **Confirmed** |
| **EA-3** | `newest_asof` is at line 107: newest non-yanked version with `created_at[:10] <= RETRIEVED`, and it prints nothing if the payload is paginated. `versions_snapshot` is called at line 234. `EF4-*` is asserted at line 238. Today's newest version prints as `VOLATILE (not asserted)`. I recomputed the as-of values from the five `snapshots/crates-io-*-versions.json` files; each has `next_page` null: 0.23.1, 0.1.0, 0.2.0, 0.6.0, 0.18.0. For `guppy`, 0.19.1 (2026-09-24) and 0.19.0 (2026-09-19) are the newer versions. The log matches: 5 PASS lines, and `guppy newest version today=0.19.1`. DECISION line 277 contains "each the newest non-yanked version with `created_at` on or before 2026-09-17" and "`guppy` has since published 0.19.0 and 0.19.1". | **Confirmed** |
| **EA-4** | `unset CARGO_TARGET_DIR` is at line 22. `absent()` starts at line 49; its `[ ! -s "$file" ]` test at line 52 FAILs on empty input. The B4 gate block starts at line 293 (`b4_ls=0`, the `ls` exit status). Its condition is at line 299: the check FAILs unless `ls` succeeded and `rslbp` is listed with `-x`. Only then is `absent` called, at line 304. The probe log shows `CHECKS RUN: 26 FAILURES: 0`, with both B4 halves PASS. DECISION line 266 describes the gate and the `unset`. | **Confirmed** |
| **EA-5** | DECISION line 277 reads "about 13 times (one order of magnitude above) the 190". The ratio is 2426/190 = 12.77, so the wording holds. | **Confirmed** |
| **EA-6** | Probe lines 79–81 print the `cargo`, `rustc` and `clippy` version lines as `VOLATILE (not asserted)`. Probe log lines 3–5 read 1.98.1. DECISION line 231 contains "The results hold on 1.98.1" and says the `cargo-deny` log is still 1.98.0. Line 259's filter names "the `cargo`/`rustc`/`clippy` version lines". Line 260's filter "also names the `cargo` version line". | **Confirmed** |
| **JF-5** | DECISION line 297 reads "names R01 eight times across three lines" and cites `R2-2f`, `R2-2f2`, `R2-2g` and `R2-2h`. The log has `R2-2f == 8` (occurrences) and `R2-2f2`: 3 lines. | **Confirmed** |
| **JF-6** | DECISION line 213 now says checks `R2-5a`–`R2-5j` do not test exhaustiveness. It cites the owner row `W0-R69c` and R69's revision-10 judgment audit. `docs/planning/p02/owner-decisions.md:398` reads "the six W1-R02 substitutions only (judgment approve at revision 10, 20 hunks all classified)" and is bound to `d34ab6e8…`. R69's `review/audit-fable.md` binds `decision-sha256: d34ab6e8…7fce0a` with `verdict: approve`. Its section (b) states the new owned value is the old one "with exactly the six ruled substitutions" and that "nothing else moved". I recomputed the R69 run file's sha: `d34ab6e8…7fce0a`. | **Confirmed** |

**Knock-ons.** All are present and consistent:

- The title (line 1) and `R2-8a` both read revision 3, 2026-09-27.
- The revision note (lines 3–16) and history line 28 list exactly the eight repairs and the re-record consequences.
- Row 236 says `exit 1`, `FAILURES: 1`, with the failure being `EF6a`. The recorded log agrees: `FAIL EF6a … got 4`, summary `35/1/0`.
- Row 239 says `exit 0`, 66/0/0.
- Lines 243–244 read "Three revision-1 checks". Row 249 adds `S7-r02-ecosystem-figures.log`, which is stale because the re-recorded log's summary reads `FAILURES: 1`.
- Line 252 is consistent with the rest of the decision.
- Repro rows 258–260 are consistent. Line 279's description of `R2-7`, `R2-8a` and `R2-9` matches the script.
- Recomputed shas of the four re-pinned artifacts equal the `R2-7a`, `R2-7b`, `R2-7e` and `R2-7f` values (probe.sh `c9e9e6aa…`, figures.sh `cafb5b92…`, probe.log `21a99b14…`, figures.log `61151711…`). The four revision-1 artifacts equal `R2-7c`, `R2-7d`, `R2-7g` and `R2-7h`.

## Observations (not disputes)

1. **R77 drifted after the recording.** The working-tree R77 file `research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md` now titles itself revision 5. Its mtime is 2026-09-27 12:40, after the r3 logs were written at 12:27. It has `OV-03` lines at 1353 and 1387 ("`OV-01`/`OV-02`/`OV-03` controls count", "the `OV-01`/`OV-02`/`OV-03` file counts") that name neither `R02` nor `taken`. Under `R2-9a`'s line-level rule, a rerun against this working tree would mark R77 `UNCLASSIFIED` and fail. The recorded claim is bound to the `542ad225` extraction, so the repair holds as written. However, the rule is brittle to prose that lists OV numbers as census controls. The empirical seat and the controller should rerun against the committed tree at the time of binding.
2. **Stale headers in `r02-check-r2.sh`.** The script's `note` headers still say "revision-2 shape" (R2-8) and "the two revision-1 checks" (R2-9), and its header comment still describes revision 2. This is cosmetic and asserts nothing.
3. **DECISION line 252 names only two edited scripts.** It says revision 3 "edited `r02-workspace-probe.sh` and `r02-ecosystem-figures.sh`". It omits `r02-check-r2.sh`, which is not pinned by `R2-7`, so the statement is accurate in context. Line 28 names all three scripts.

## S1 adjudication (2026-09-28, Q23)

- File verdict was approve and stays approve. `decision-sha256` re-bound 283c6dd0e9d2 -> d8c64f7c3666 across the S1-attested micro-repairs below (S60 OBS-LEFT: :166 now-false census claim, :315/:320 stale toolchain scope); S1 verified by diff that no other byte changed. Original approval transfers under the Q23 verdict-transfer rule.
- S1 repairs (three clauses):

```diff
- outside this item returns **0** files, and the same search
+ outside this item returns **0** files at pin `542ad225`, and the same search
(at :166; EF6a census was recorded at the pin, figures disclose live-tree growth)
- Every executed result here is macOS arm64 at 1.98.0 only.
+ Every executed result here is macOS arm64 at 1.98.0 (probe re-executed at 1.98.1, 26/0).
(at :315; S60 evidence: probe 26/0)
- - Every compile, clippy and metadata result is macOS 26.4 arm64 at `rustc`/`cargo` 1.98.0. Nothing [...]
+ - Every compile, clippy and metadata result is macOS 26.4 arm64 at `rustc`/`cargo` 1.98.0, except the probe re-execution at 1.98.1 (26/0). Nothing [...]
(at :320; same probe record)
(the only byte changes r3-prerepair -> r3-final)
```
