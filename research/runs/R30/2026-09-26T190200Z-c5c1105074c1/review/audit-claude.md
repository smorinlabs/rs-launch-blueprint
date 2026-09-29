actor: audit-claude-R30-r1
model: claude-opus-5-5
family: anthropic
decision-sha256: bde05533efb747334a6f79755706c0ad964bb0e720adaa96d1c9a528c62ba45c
verdict: reject
unresolved-findings:
1. Cold-gate figure "6.11 s" is not in the cited evidence.
   - Claim: `DECISION.md:179` "the full gate costs 6.11 s cold … (`H2`)"; `DECISION.md:354` "`H2`: … 6.11 s cold once".
   - Evidence: `evidence/r30-wiring-cost.log:35` (case H2a) reads `units re-checked: 29  wall-clock: 6.12 s`. The value 6.11 appears in no committed log. The decision's own `## Empirical check` block (`DECISION.md:299`) quotes 6.12 s, so the document contradicts itself.
   - Repair: change both occurrences to 6.12 s.
2. Incremental range "0.18–0.26 s" is attributed to `H2`, but the H2 cases do not contain 0.18.
   - Claim: `DECISION.md:110` "`H2b`–`H2f`: … incremental 0.18–0.26 s"; the same range appears at `:152`, `:179` and `:354`.
   - Evidence: the H2 incremental wall-clocks are 0.26 s (H2d, `r30-wiring-cost.log:61`), 0.19 s (H2e, `:70`) and 0.26 s (H2f, `:82`). The only "0.18" in the log is a lefthook per-job time in case H3c (`:128`), not an H2 wall-clock.
   - Repair: change all four occurrences to 0.19–0.26 s.
3. The "real commit through the hook" range "0.26–0.56 s" is not in the cited evidence.
   - Claim: `DECISION.md:110` "`H3e`/`H3f`: a real commit through the installed hook takes 0.26–0.56 s"; `DECISION.md:180` "took 0.26–0.56 s (`H3e`, `H3f`)".
   - Evidence: `r30-wiring-cost.log:168` (H3e) reads `wall-clock: 0.50 s`, and `:184` (H3f) reads `wall-clock: 0.52 s`. Neither 0.26 nor 0.56 appears in either case.
   - Repair: change both occurrences to 0.50–0.52 s. The wording "under 0.6 s" at `:354` is consistent with the log and can stay.
4. The "clippy after the gate" figure "0.26 s" contradicts its cited case.
   - Claim: `DECISION.md:154` "clippy after the gate re-checks only the 4 workspace members, 0 dependencies, 0.26 s (`H4a`)".
   - Evidence: `r30-wiring-cost.log:200` (H4a) reads `units re-checked: 4  wall-clock: 0.40 s`; cargo's own line at `:199` reads `Finished … in 0.32s`.
   - Repair: change it to 0.40 s.

   Common cause: `DECISION.md:70` says a first pass was discarded and every log was re-run. These four prose figures look like values carried over from that discarded pass. None of them changes a conclusion. My fresh rerun measured 6.69 s cold, 0.23–0.34 s incremental, 0.41 s and 0.27 s for H3e/H3f, and 0.30 s for H4a, which has the same order of magnitude and is still sub-second. The pre-commit tier (F106) and the ranking of option B remain supported. The only defect is that the figures quoted as evidence must match the committed evidence. An alternative repair is to state these costs as "sub-second" with the log line cited, instead of quoting hundredths of a second.

# Empirical audit — R30 type-check-gate, DECISION.md revision 1

## Scope and method

- I verified the decision's hash before doing anything else. `shasum -a 256 DECISION.md` printed `bde05533…62ba45c`, which equals the expected value. I recomputed it again just before writing this file, and it was unchanged.
- Read: `DECISION.md` (focusing on `## Empirical check` and `## Engines`), `research/RUNBOOK.md` §5, and all 7 scripts under `review/evidence/`. I read no audit files, no raw reports and no snapshots.
- Host: macOS Darwin 25.4.0, arm64, 14 CPUs. `CARGO_HOME=/tmp/cargo-s14-R30-emp` (a private cargo home). The session's shared `CARGO_TARGET_DIR` was overridden inside each script, which exports `CARGO_TARGET_DIR="$WS/target"` in its own `mktemp -d` scratch directory.
- Toolchains, as printed by the fresh log headers, match the decision's table exactly:
  - cargo 1.96.0 (30a34c682) / rustc 1.96.0 (ac68faa20)
  - cargo 1.97.1 (c980f4866) / rustc 1.97.1 (8bab26f4f)
  - Homebrew cargo 1.98.1 (797e8a9bc) / rustc 1.98.1 (48a229cea), clippy 0.1.98
  - just 1.57.0, lefthook 2.1.14, git 2.50.1, gh 2.101.0
- Before running anything, I confirmed that every file each script writes is inside its `mktemp -d` scratch directory after the script's `cd`. The scripts write nothing to `evidence/`.

## Reruns

Working directory: `research/runs/R30/2026-09-26T190200Z-c5c1105074c1/review/evidence/`. I ran the scripts one after another, so the timing-sensitive scripts did not compete for CPU:

```
for s in lints scope severity suppression upstream-docs wiring-cost wiring-severity; do
  bash r30-$s.sh > /tmp/r30-audit/r30-$s.log 2>&1; echo "r30-$s.sh exit=$?"; done
```

| Script | Exit | PASS | FAIL | Skipped | Decision claims | `cmp` against committed log | Verdict-line comparison |
|---|---|---|---|---|---|---|---|
| `r30-lints.sh` | 0 | 14 | 0 | 0 | 14 / 0 | differ: char 33, line 1 | identical (29 lines) |
| `r30-scope.sh` | 0 | 20 | 0 | 0 | 20 / 0 | differ: char 33, line 1 | identical (41 lines) |
| `r30-severity.sh` | 0 | 17 | 0 | 0 | 17 / 0 | differ: char 36, line 1 | identical (52 lines) |
| `r30-suppression.sh` | 0 | 16 | 0 | 0 | 16 / 0 | differ: char 39, line 1 | identical (33 lines) |
| `r30-upstream-docs.sh` | 0 | 22 patterns found, 0 `MISSING` | 0 | 0 | 22 / 0 | differ: char 41, line 1 | identical (13 lines) |
| `r30-wiring-cost.sh` | 0 | 17 | 0 | 0 | 17 / 0 | differ: char 39, line 1 | identical (54 lines) |
| `r30-wiring-severity.sh` | 0 | 8 | 0 | 0 | 8 / 0 | differ: char 43, line 1 | identical (17 lines) |

Every script ends with `# summary: failures=0`. `r30-wiring-cost.log` contains three occurrences of "skip". All three are lefthook's own output, `(skip) no matching staged files`, inside case H3a, which passes. None of them is a skipped test.

**The first differing line is line 1 in every file: the run timestamp.** Example, `r30-scope.log`:

```
< # r30-scope.sh  run 2026-09-27T01:59:23Z  host Darwin arm64
> # r30-scope.sh  run 2026-09-27T03:42:22Z  host Darwin arm64
```

The remaining `diff` hunks fall into five classes. None of them is a verdict line:

- **Header values.** Line 2 holds `CARGO_HOME`: `/tmp/cargo-s9r-R30` in the committed logs and `/tmp/cargo-s14-R30-emp` in the reruns.
- **Timings.** Cargo's `Finished … in N.NNs` lines, the scripts' `wall-clock` values, and lefthook's `summary: (done in …)` and per-job times.
- **Ordering of parallel diagnostics.** Cargo prints the `(lib)` and `(lib test)` warning summaries in either order. The `(N duplicate)` suffix therefore moves between those two lines. One example is `supp` in `r30-suppression.log`, where the committed log reads `2 warnings (2 duplicates)` and the rerun reads `(1 duplicate)` on each line.
- **Scheduling-dependent lines.** The presence or position of `warning: build failed, waiting for other jobs to finish...` and of `error: could not compile …` varies. For example, `r30-scope.log:39` exists only in the committed log.
- **Reordered `Checking` lines.** Some `Checking app-web` and `Checking app-cli` lines appear in a different order.

`r30-upstream-docs.log` differs only in its line-1 timestamp. Every blob sha and quoted line number is byte-identical to the committed log.

**Verdict-line comparison.** For each log pair, I extracted every line matching `^(== |exit=|units re-checked|HEAD subject|blob |MISSING|# summary)` and stripped the `wall-clock` value. All 7 extracted sequences match line for line. The case labels, the exit codes, the "units re-checked" counts (the fingerprint evidence for W3 and H2) and the HEAD-subject checks for H3e and H3f all reproduce exactly.

The committed logs were not touched. Every `evidence/` file still has an mtime of Sep 26 18:59, and `cmp` shows that the committed logs differ from my `/tmp` copies.

## Figures re-derived at source

| Claim in DECISION.md | Source | Result |
|---|---|---|
| Case counts 20/17/16/14/17/8, and 22 patterns in 6 files | PASS counts in both log sets; the pattern lists in `r30-upstream-docs.sh` (5+2+4+2+2+7 = 22 patterns in 6 files) | match |
| S5: an `--all-features`-only gate exits 0, and the default-features gate exits 101 | `r30-scope.log`, fresh and committed | match |
| W1: `CARGO_BUILD_WARNINGS=deny` exits 0 on 1.96.0 and 101 on 1.97.1 | `r30-severity.log` | match |
| W3b: 0 units re-checked with exit 101; W3d (`RUSTFLAGS`): 2 units re-checked with exit 101 | `r30-severity.log` | match |
| X8b: a bare `#[expect]` is unfulfilled under `--all-features`, exit 101 | `r30-suppression.log` | match |
| L0a: `mismatched_lifetime_syntaxes` is on by default | `r30-lints.log` | match |
| Synthetic workspace: 4 members, 24 generated dependency crates, 8,664 lines, 29 units cold | `r30-wiring-cost.log:24`, `:219`, `:35` | match |
| H2b/H2c warm no-op 0.09 s; H2d 0.26 s | `r30-wiring-cost.log:42`, `:49`, `:61` | match (these are also the values quoted in the `## Empirical check` block) |
| H3e: commit refused, HEAD still `H2 edits` | `r30-wiring-cost.log:169-170` | match |
| 6.11 s cold; incremental 0.18–0.26 s; hook commit 0.26–0.56 s; H4a 0.26 s | `r30-wiring-cost.log:35`, `:61/70/82`, `:168/184`, `:200` | **mismatch**: findings 1–4 |

## Judgment

The execution truth holds. All 7 scripts rerun green on the stated toolchains. Every PASS/FAIL outcome, exit code and fingerprint count reproduces, and the upstream quotations still resolve to the same blobs and lines. The engine resolutions in `## Engines` that rest on executed cases are D1 (W1, W3), D3 (S5, S6), D4 (L0–L3), D7 (X8–X10) and D8 (L1c, X11, X12, S8, S9, W4). All of those cases reproduce.

The verdict is reject on evidence support alone. Four cost figures in `## Decision` and `## Engines` are attributed to named cases whose committed log lines contain different values. The fix is mechanical and changes no conclusion: replace each figure with the committed log's value (findings 1–4).
