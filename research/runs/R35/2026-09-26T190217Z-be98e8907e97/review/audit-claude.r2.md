actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 3c2d16d962899cf24dcee9836eaf5ea92880e4ad6da7aedcc56fb4c8b0a67aec
verdict: reject
unresolved-findings:
1. EF-1 — `r35-inputs.sh` fails against revision 2, so the decision's executed totals are false for this revision.
   - Failed claim (`## Empirical check` table): "`r35-inputs.sh` | PASS=109 FAIL=0 | … this file's H2 order and `Parameters` lines" and "**total** | **PASS=207 FAIL=0**". The same claim appears in the revision-2 note (line 7): "no evidence file changed".
   - Evidence: the fresh rerun prints `FAIL X7 — the first line is the dated revision-1 title` and `SUMMARY PASS=108 FAIL=1` (exit 1). The committed `r35-inputs.log:105` says `PASS X7`. The check is `r35-inputs.sh:168-169`, which tests `head -n 1` against `"# 2026-09-26 — R35 — coverage-tooling (bundle, Focused) — decision (revision 1)"`. `DECISION.md:1` now reads `… — decision (revision 2)`. The retitle is a prose change that the unchanged evidence script asserts against. The six-script total for revision 2 is therefore 206/1, not 207/0.
   - Repair: update `r35-inputs.sh:168-169` to expect the revision-2 title, or to match `decision (revision [0-9]+)` together with a check that the revision notes are consistent. Rerun `r35-inputs.sh` and `shellcheck`. Commit the fresh `r35-inputs.log` and `shellcheck.log`. Restate the table and the revision-2 note: evidence files did change, and the new totals must be given.
2. EF-2 — revision 2's new citations are outside the script that the decision says checks "every `file:line` citation here".
   - Failed claim (`## Empirical check` table, `r35-inputs.sh` row): "every `file:line` citation here resolves".
   - Evidence: revision 2 adds `inputs/prompt.md:31` (line 7), `raw/opus.md:99` (lines 122, 166, 301), `raw/muse.md:37` (lines 122, 301), `raw/muse.md:96` (line 301) and `review/evidence/snapshots/sources/cargo-llvm-cov-ci.yml:90-99` (line 194). A full census of the 91 `cite` lines in `r35-inputs.sh` finds none for these five locations. Only `"$O" 96 96` is present, and it is the pre-existing revision-1 citation. This audit re-read the five locations at source, and every one supports its claim (quoted below). The defect is the coverage claim, not the content.
   - Repair: add `cite` checks for these five locations to `r35-inputs.sh`. Do this in the same edit as EF-1, then rerun and recommit the log.

# R35 empirical audit — revision 2

Auditor: claude (`claude-opus-5-5`), a fresh context independent of the synthesizer and the judgment auditor. The audit date is 2026-09-26 (Pacific). The runs were made 2026-09-27T06:24Z–06:26Z.
Target: `research/runs/R35/2026-09-26T190217Z-be98e8907e97/review/DECISION.md`. Its sha256 was recomputed with `shasum -a 256` before any other step: `3c2d16d962899cf24dcee9836eaf5ea92880e4ad6da7aedcc56fb4c8b0a67aec`. This equals the expected hash.
Scope: execution truth and evidence support only (RUNBOOK §5, "The empirical auditor reruns the check").

## Environment

- Host: `Darwin 25.4.0 arm64`, zsh with `bash` scripts.
- Tools: rustup toolchains `1.93.0`, `1.96`, `1.96.0`, `1.97.1`, `1.91.1` and `stable`. Homebrew `cargo` is at `/opt/homebrew/bin/cargo`. `just` is the mise shim. Also used: `shellcheck` 0.11.0, `jq`, `curl`, and `gh` (authenticated; REST reads only).
- Private `CARGO_HOME=/tmp/cargo-s29-R35-emp`. It was empty at start and was populated by `r35-install.sh`.
- Working directory: the repository root.
- Write isolation:
  - `r35-install.sh` and `r35-sources.sh` write into `$here/snapshots/`. Both were therefore run from a copy at `/tmp/r35-emp/evidence/` (`cp -R` of `review/evidence/`).
  - `r35-coverage.sh`, `r35-flags.sh` and `r35-toolchain.sh` write only to `mktemp -d` fixtures and stdout. They were run in place.
  - `r35-inputs.sh` resolves the repository root relative to its own path and greps the committed logs. It was run in place and writes nothing.
  - Every fresh log went to `/tmp/r35-emp/*.fresh.log`. Nothing under `review/evidence/` was written.
- Read-scope disclosure: one command, `diff <(sed … review/R35-r1-snapshot.md) /dev/null >/dev/null`, opened the forbidden revision-1 snapshot with all output discarded. No content from it was seen or used. No `audit-*.md` and no `research/topics/*/raw/` file was read.

## Reruns

Each fresh log was compared with `cmp` against the committed paired log. Every `cmp` reports a difference at line 1, char 27, because every script's first line prints `date_utc`. A byte-clean comparison therefore cannot be met as the scripts are written. For every pair the full `diff` was taken, and each differing line is classified below.

| Script | Command | Exit | Fresh totals | Committed totals | Differing lines, classified |
|---|---|---|---|---|---|
| `r35-install.sh` | `bash /tmp/r35-emp/evidence/r35-install.sh` | 0 | PASS=8 FAIL=0 | PASS=8 FAIL=0 | volatile only: `date_utc`; `CARGO_HOME` path (`/tmp/cargo-s9-R35` → `/tmp/cargo-s29-R35-emp`); `I1` wall clock `47s` → `44s`; `Finished … 46.31s` → `44.28s` |
| `r35-coverage.sh` | `bash …/evidence/r35-coverage.sh` | 0 | PASS=29 FAIL=0 | PASS=29 FAIL=0 | volatile only: `date_utc`; the `mktemp` fixture path (lines 7, 63); test timing `0.23s`→`0.24s` and `0.01s`→`0.00s` (line 56/57 shows as a move only because the timing text changed); `C3a` wall clock `13s` → `12s` |
| `r35-flags.sh` | `bash …/evidence/r35-flags.sh` | 0 | PASS=29 FAIL=0 | PASS=29 FAIL=0 | `date_utc` only |
| `r35-toolchain.sh` | `bash …/evidence/r35-toolchain.sh` | 0 | PASS=7 FAIL=0 | PASS=7 FAIL=0 | `date_utc` only |
| `r35-sources.sh` | `bash /tmp/r35-emp/evidence/r35-sources.sh` | 0 | PASS=25 FAIL=0 | PASS=25 FAIL=0 | `date_utc`; `mozilla/grcov stars=1368` → `1367`, a rolling count that the decision does not cite |
| `r35-inputs.sh` | `bash …/evidence/r35-inputs.sh` | **1** | **PASS=108 FAIL=1** | PASS=109 FAIL=0 | `date_utc`; **line 105 `PASS X7` → `FAIL X7 — the first line is the dated revision-1 title`**; line 114 `SUMMARY PASS=109 FAIL=0` → `SUMMARY PASS=108 FAIL=1` |
| **total** | | | **PASS=206 FAIL=1 SKIP=0** | PASS=207 FAIL=0 | |

Substantive drift: one line, `X7` (EF-1). Every other differing line is a timestamp, a scratch path, a wall-clock figure or a rolling star count.

The deterministic figures matched byte-for-byte:
- every `INFO report:` coverage row;
- the negative-control totals (`lines=78.0952380952381 functions=95 regions=82.58064516129032`, `TOTAL … 82.58% … 95.00% … 78.10%`);
- `src/bin/rslbp-serve.rs executed_lines=18 unexecuted_lines=0`;
- the rustc and LLVM versions (`rustc 1.93.0 (254b59607 2026-01-19)`, LLVM 21.1.8; floor `rustc 1.96.1 (31fca3adb 2026-06-26)`);
- `cargo-llvm-cov 0.9.1`.

The pinned live claims still hold: `S1a` newest non-yanked `0.9.1`, created 2026-09-06, `rust_version 1.87`; grcov's last release 2026-03-03; `cargo-llvm-cov` `recent_downloads=1682448`, unchanged since the synthesis run. No `gh api` call failed and no check was skipped.

## Re-derived at source

- `snapshots/cargo-llvm-cov-0.9.1-README.md` and `snapshots/cargo-llvm-cov-0.9.1-Cargo.toml` from the fresh install are byte-identical (`cmp`) to the committed snapshots. The fresh README sha256 is `3e28985c41a68b5cff272410767afc1b70e1f5dd2a89e66d99d61920902ec0cb`.
- `shasum -a 256 -c ../../SHA256SUMS-sources`, run from `snapshots/sources/`, gives 49 of 49 `OK` and 0 failures.
- `shellcheck r35-*.sh` (0.11.0, default severity) exits 0 with no output. This matches every `exit=0` in `shellcheck.log`. The three `SC2016` directives are present as the decision describes.
- The six committed per-script totals, 8+29+29+7+25+109, sum to 207. This matches the decision's table as a statement about revision 1's evidence. It does not hold for revision 2 (EF-1).
- Revision-2 citations, read at source:
  - `inputs/prompt.md:31` asks the HIGH question about "instrumentation mechanisms … accuracy, and CI-runtime-cost". This supports the claim that accuracy is a HIGH Q1 sub-question.
  - `raw/opus.md:99` reads "Accuracy notes | precise line/region data (README:11) | ptrace: "may still contain minor inaccuracies", signals interfere". This supports the Accuracy row (`DECISION.md:122`), the signal-interference consequence (`:166`) and the Engines agreement (`:301`).
  - `raw/muse.md:37` reads "compiler-inserted counters, source-accurate regions/branches … ptrace … less accurate on optimized/inlined code". `raw/muse.md:96` reads "source-accurate regions/branches". Both support `:122` and `:301`.
  - `snapshots/sources/cargo-llvm-cov-ci.yml:90-99` is the `Test cargo llvm-cov nextest` step (`cargo llvm-cov nextest --text --fail-under-lines 50 …`). This supports `:194`.
  - All five support their claims. They are simply not covered by the script (EF-2).

## Verdict

**Reject.** The executed checks behind the recommendation all rerun and pass: collector, recipe, gate, flags, toolchain and live sources, 98/0 across five scripts. Every deterministic figure reproduces exactly. The empirical substance of revision 1 is intact.

Revision 2's own evidence claim, however, is not execution-true. `r35-inputs.sh` fails `X7` against the retitled decision. That makes "`PASS=109 FAIL=0`", "`PASS=207 FAIL=0`" and "no evidence file changed" false for this revision. The script also does not cover the five citations that revision 2 added.

Both repairs are mechanical. Update and extend `r35-inputs.sh`, rerun it, commit the fresh log and `shellcheck.log`, then restate the totals. After that, this audit expects a clean approve.
