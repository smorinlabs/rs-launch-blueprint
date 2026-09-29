actor: audit-claude-R35-r1
model: claude-opus-5-5
family: anthropic
decision-sha256: e597d5f70f1c4e0bb051c4cdc1da277f5b9f2cac73e5d9d4c628f81ba2ef160f
verdict: approve
unresolved-findings: none

# R35 coverage-tooling — empirical audit of DECISION.md revision 1

**Scope.** Execution truth and evidence support only. This audit reran all six evidence scripts, byte-compared each fresh log with the committed log, and re-derived the load-bearing figures at their sources. It did not judge the recommendation's merit. Before any other step, `shasum -a 256 review/DECISION.md` printed `e597d5f70f1c4e0bb051c4cdc1da277f5b9f2cac73e5d9d4c628f81ba2ef160f`, which matches the expected hash.

## Method

- **Host.** `Darwin 25.4.0 arm64`, on 2026-09-27 UTC (2026-09-26 Pacific). rustup toolchains present: `stable`, `1.91.1`, `1.93.0` (with `llvm-tools`), `1.96` / `1.96.0`, `1.97.1`. Homebrew `cargo 1.98.1`. The private cargo home was `CARGO_HOME=/tmp/cargo-s14-R35-emp`. It started empty, so `r35-install.sh` built the tool from crates.io into it.
- **No writes to `evidence/`.** `r35-install.sh` writes `snapshots/`, and `r35-sources.sh` writes `snapshots/sources/` and `SHA256SUMS-sources`, all relative to the script's own directory. To protect the committed evidence, the run directory, `scripts/`, and the R11 prerequisite `DECISION.md` were copied to `/tmp/r35-emp-audit/repo/` (same relative layout). Before any script ran, `diff -r` against the real run directory reported no differences. Every script ran from that copy, and its stdout+stderr went to `/tmp/r35-emp-audit/out/<script>.log`.
- **Proof that `evidence/` was not written.** The whole R35 run directory is untracked (`git status --porcelain -- research/runs/R35/` prints `?? research/runs/R35/`), so git status cannot show whether a file changed. File modification times show it instead. The reruns started at 2026-09-26 20:51 Pacific. After they finished, `find review/evidence -newermt '2026-09-26 19:30' | wc -l` printed `0` for all 65 files, and every file kept its original Sep 26 18:57–19:24 modification time.
- **Comparison.** For each script: `cmp` of the fresh log against the committed `review/evidence/<script>.log`, then `diff` on any mismatch.

## Reruns

Each command was `bash /tmp/r35-emp-audit/repo/research/runs/R35/2026-09-26T190217Z-be98e8907e97/review/evidence/<script> > /tmp/r35-emp-audit/out/<log> 2>&1`, run in this order:

| Script | Exit | Fresh totals | Committed totals | `cmp` | What differs (from `diff`) |
|---|---|---|---|---|---|
| `r35-install.sh` | 0 | PASS=8 FAIL=0 SKIP=0 | PASS=8 FAIL=0 | differ: char 27, line 1 | volatile only: `date_utc`; the `CARGO_HOME` path (`/tmp/cargo-s9-R35` → `/tmp/cargo-s14-R35-emp`); build seconds (`47s`/`46.31s` → `53s`/`52.43s`). The regenerated README and `Cargo.toml` snapshots are byte-identical to the committed ones. |
| `r35-coverage.sh` | 0 | PASS=29 FAIL=0 SKIP=0 | PASS=29 FAIL=0 | differ: char 27, line 1 | volatile only: `date_utc`; the `mktemp` fixture path (`tmp.3hRcE8HAhd` → `tmp.vOoM7FG3jD`, lines 7 and 63); wall clock `C2a` `12s`→`15s` and `C3a` `13s`→`14s`; per-test `finished in` times; one `INFO neg: test result` line moved from line 56 to line 57 (the order in which test binaries print). All coverage figures are identical. |
| `r35-flags.sh` | 0 | PASS=29 FAIL=0 SKIP=0 | PASS=29 FAIL=0 | differ: char 27, line 1 | `date_utc` only (line 1). Lines 2 onward are byte-identical. |
| `r35-toolchain.sh` | 0 | PASS=7 FAIL=0 SKIP=0 | PASS=7 FAIL=0 | differ: char 27, line 1 | `date_utc` only. |
| `r35-sources.sh` (live) | 0 | PASS=25 FAIL=0 SKIP=0 | PASS=25 FAIL=0 | differ: char 27, line 1 | `date_utc` only. Every live figure matches the committed log. Three regenerated snapshot bodies (`crate-cargo-llvm-cov.json`, `crate-cargo-tarpaulin.json`, `crate-grcov.json`) have new digests, but the fields the script extracts from them are unchanged. The committed `SHA256SUMS-sources` matches the committed snapshots. |
| `r35-inputs.sh` | 0 | PASS=109 FAIL=0 SKIP=0 | PASS=109 FAIL=0 | differ: char 27, line 1 | line 1 only: `date_utc` and `root=` (the /tmp copy instead of the repository path). |
| **total** | | **PASS=207 FAIL=0 SKIP=0** | **PASS=207 FAIL=0** | | |

The fresh totals equal the `## Empirical check` table row by row, including its total, PASS=207 FAIL=0. No script failed, and no fresh log contains a `FAIL ` or `SKIP` line.

The first differing line of each log, quoted from `diff <committed> <fresh>` (`<` is the committed log, `>` is the fresh log):

```
r35-install.log    < INFO date_utc=2026-09-27T01:57:33Z host=Darwin 25.4.0 arm64
                   > INFO date_utc=2026-09-27T03:51:55Z host=Darwin 25.4.0 arm64
r35-coverage.log   < INFO date_utc=2026-09-27T02:12:30Z host=Darwin 25.4.0 arm64
                   > INFO date_utc=2026-09-27T03:52:59Z host=Darwin 25.4.0 arm64
r35-flags.log      < INFO date_utc=2026-09-27T02:06:05Z | rustc 1.93.0 (254b59607 2026-01-19) | cargo-llvm-cov 0.9.1
                   > INFO date_utc=2026-09-27T03:53:51Z | rustc 1.93.0 (254b59607 2026-01-19) | cargo-llvm-cov 0.9.1
r35-toolchain.log  < INFO date_utc=2026-09-27T02:24:35Z
                   > INFO date_utc=2026-09-27T03:53:55Z
r35-sources.log    < INFO date_utc=2026-09-27T01:59:27Z
                   > INFO date_utc=2026-09-27T03:54:07Z
r35-inputs.log     < INFO date_utc=2026-09-27T02:17:42Z root=/Users/stevemorin/c/rs-launch-blueprint-p02-plan
                   > INFO date_utc=2026-09-27T03:54:56Z root=/tmp/r35-emp-audit/repo
```

For `r35-flags.log`, `r35-toolchain.log`, `r35-sources.log` and `r35-inputs.log`, this line-1 pair is the entire diff.

## Load-bearing figures re-derived at source

| Claim in DECISION.md | Re-derived evidence | Holds |
|---|---|---|
| The intact fixture passes 95/95/90 with lines 100 %, functions 100 %, regions 96.97 % (`C3a`) | fresh `r35-coverage.log`: `TOTAL … 96.97% … 100.00% … 100.00%`; `intact fixture totals: lines=100 functions=100 regions=96.96969696969698` | yes |
| Without the SIGINT test: lines 81.71, functions 89.47, regions 75.76; 95/95/90 fails and lines-80 passes; 13 of 18 serve-binary lines are unexecuted (`C8a`–`C8c`) | fresh log: `lines=81.70731707317071 functions=89.47368421052632 regions=75.75757575757575`; `95/95/90 gate exit=1; lines-80 gate exit=0`; `rslbp-serve.rs executed_lines=5 unexecuted_lines=13` | yes |
| One unused generic takes functions from 100 % to exactly 95 % in a 20-function workspace (`C7a`, `C7b`) | fresh log: `functions=95`; `FNDA:0` for `describe`; the intact TOTAL shows 19 functions, so the generic makes 19 of 20 | yes |
| Without `--workspace`, `report` silently drops the member (`C4e`) | fresh log: the TOTAL without `--workspace` is 12 functions and 60 lines, against 19 and 82 with it | yes |
| The negative control fails the gate after the reports are written (`C6a`, `C6b`, `C6d`) | fresh log: `just coverage exit=1`; missing lines `crates/core/src/lib.rs: 48-68, 70, 72`; the `C6b` check compares report mtimes with the pre-change copy of the source file | yes |
| Doc tests and branch coverage are rejected on stable; `--lcov --html` together are rejected (`F4a`, `F4b`, `F5`, `F6a`) | fresh `r35-flags.log` PASS lines for the same IDs, on `rustc 1.93.0 (254b59607 2026-01-19)` | yes |
| The `T2` and `T3` error messages quoted in `#### llvm-tools-preview` | fresh `r35-toolchain.log` prints both messages verbatim; the Homebrew binary reports `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)` | yes |
| Builds on the 1.96 floor; `rust-version` 1.87, `Apache-2.0 OR MIT`, `#![forbid(unsafe_code)]` at `src/main.rs:3` (`I1`, `I5`–`I7`) | fresh `r35-install.log`, from a new build on `rustc 1.96.1 (31fca3adb 2026-06-26)` into an empty `CARGO_HOME` | yes |
| 90-day downloads 1,682,448 vs 295,600, ratio 5.69; grcov 8 of 10 unanswered with a 16.16-day median; cargo-llvm-cov 6 answered with a 2.09-day median; RustSec 404s; tracking issues #84605, #79649, #79417 and #119164 all open; codecov-action v7.1.1 released 2026-09-17 | fresh live `r35-sources.log`, identical to the committed log apart from `date_utc` | yes |
| cargo-llvm-cov's CI tests `1.87`, stable and beta on `ubuntu-24.04`, and macOS on nightly only (`cargo-llvm-cov-ci.yml:57-73`) | snapshot lines 57–71, plus `runs-on: ${{ matrix.os \|\| 'ubuntu-24.04' }}` | yes |
| README lines 14, 618 and 917 (doc tests need nightly; `aarch64-pc-windows-msvc` does not work; doc-test support is unstable) | read directly from the packaged-README snapshot, which the fresh install reproduced byte-identically | yes |
| The ubuntu budget: 3 (R11) + 1 (R04) + 1 (coverage) = 5, under "roughly six" | R11 `DECISION.md:407` "against this design's 3 and 4"; `:290` R04 is one more cache-bearing id; `:291` the R35 slot; `:278` "roughly six cache-bearing job ids per runner" | yes |
| Raw-report hashes, line counts, shape results; 43 distinct `S_*` placeholders on 26 lines of the Muse report; `operations/` empty | `shasum -a 256`: `583d7df2…1c638` and `6884140…1cfd`; `wc -l` 225 and 456; `check-answer-shape.sh … bundle` prints `OK: validation passed` for both; `grep -o '\bS_[A-Z0-9_]+' \| sort -u \| wc -l` = 43 and `grep -c` = 26; `ls operations \| wc -l` = 0 | yes |
| `## Engines` identity: Muse header line 1 is `# R35 — coverage-tooling (bundle) — Muse raw report`, with no model identifier anywhere; Opus header line 3 names `claude-opus-5-5` | `sed -n 1p raw/muse.md` and `sed -n 3p raw/opus.md` print exactly the quoted text. `grep -n -i -E 'claude\|gpt\|opus\|sonnet\|model' raw/muse.md` matches only lines 3, 146, 218 and 225, and none of them is a model identifier (a sibling `raw/opus-…` path, and the words "model" and "opus" in prose). | yes |
| All six scripts are `shellcheck` 0.11.0 clean at default severity, with three `SC2016` directives (two in `r35-flags.sh`, one in `r35-inputs.sh`) | a fresh run of `/opt/homebrew/bin/shellcheck` (version 0.11.0) on each script exits 0 with no output; `grep -c 'shellcheck disable'` counts 2 in `r35-flags.sh`, 1 in `r35-inputs.sh` and 0 in the other four | yes |
| Current stable is 1.98, so the floor is 1.96 (the `I0` label) | `gh api repos/rust-lang/rust/releases/latest` returns `1.98.1 2026-09-03T13:14:07Z`. This host's rustup `stable` alias is stale (`rustc 1.94.0`), which does not bear on the claim. | yes |
| "This exact recipe was executed" | the five `coverage:` commands and the `coverage_fail_under` value in the DECISION's fenced block are identical to the fixture `Justfile` written by `r35-coverage.sh` | yes (see observation 1) |

## Observations (non-blocking, no repair required)

1. **Recipe comments differ.** The DECISION's fenced recipe has one extra comment line: `# Every report line carries --workspace: …`. Another comment also differs slightly ("so the reports exist" in the DECISION, "so reports exist" in the fixture). Every command and the threshold variable are byte-identical to what executed, so the claim "this exact recipe was executed" holds for everything that runs.
2. **Evidence that cannot be rerun.** "Earlier runs in the same session recorded 12 s / 12 s, 17 s / 29 s and 17 s / 16 s" has no committed log. The DECISION uses it only to support "same order of magnitude", not a comparison. This rerun measured 15 s / 14 s, which is consistent with that claim.
3. **Disclosed gaps, confirmed.** No GitHub-hosted runner ran anything; the recipe ran only on 1.93.0; tarpaulin and grcov were never executed; 25 of the 28 practice-survey rows were not re-read. The DECISION states each gap in `## Empirical check`, and this audit found no claim that goes beyond them.

## Conclusion

All 6 scripts exit 0 and reproduce PASS=207 FAIL=0. Every fresh log differs from its committed log only in volatile fields: timestamps, temporary paths, wall-clock seconds, the private `CARGO_HOME` name, and the print order of one test-binary result. Every load-bearing figure checked at its source matches the DECISION. Verdict: **approve**.
