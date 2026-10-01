actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 8706d06dea3a4b75899193fbfb128364a57267994a3b9754b3ffc2e89ab07a39
verdict: approve
unresolved-findings: none

# R32 test-harness-and-execution — empirical audit of DECISION.md revision 1

**Seat.** Empirical auditor, a fresh Claude Opus 5.5 context (`claude-opus-5-5`). It is independent of the synthesizer and of the judgment auditor. It read `review/DECISION.md`, RUNBOOK §5 (`research/RUNBOOK.md:190-230`), RUNBOOK:73-76, the evidence scripts and fixture, and the R11 lines the decision cites. It did not read any `review/audit-*.md` file, any `research/topics/*/raw/` or any `Rxx-r*-snapshot.md`. It made no git write and no runner call, and it used no paid or submitting API.

**Scope judged.** Execution truth and evidence support only: do the committed checks rerun, and do they support the claims that cite them? The conflict and design judgment belong to the controller and the judgment seat.

**Result.** The decision hash matches the expected value. All 11 evidence scripts rerun green: **251 PASS, 0 FAIL, 0 skipped checks**. That total equals the decision's table (`DECISION.md:292`). Two logs are byte-identical to the committed ones. The other nine differ only in volatile tokens, and every `PASS`/`FAIL`/`RESULT` line is identical apart from a random process ID. Every figure re-derived at source reproduces. No finding survives. Five observations are recorded below; none of them blocks approval.

## Hash check

```
$ shasum -a 256 research/runs/R32/2026-09-26T190208Z-55160c36e3d0/review/DECISION.md
8706d06dea3a4b75899193fbfb128364a57267994a3b9754b3ffc2e89ab07a39  research/runs/R32/2026-09-26T190208Z-55160c36e3d0/review/DECISION.md
```

The recomputed hash matches the controller's expected hash.

## Host and environment

| Item | Value |
|---|---|
| OS | `Darwin 25.4.0 arm64` (macOS) |
| Toolchain | `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05)`; 1.96.0 through rustup for E7 |
| Private cargo home | `CARGO_HOME=/tmp/cargo-s22-R32-emp`, empty at start (no `bin/`) |
| Target base | `CARGO_TARGET_DIR=/tmp/cargo-s22-R32-emp-target` |
| Other tools | `lefthook` (`/opt/homebrew/bin`), `just` (mise shim), `shellcheck 0.11.0` |

## Rerun

**Working directory: two modes.**

- **Nine scripts ran from a copy.** `r32-install.sh` and `r32-sources.sh` write into `$HERE` (`snapshots/`, `r32-install.cargo-install.txt`). To keep `evidence/` untouched, all of `evidence/` was copied to `/tmp/r32-audit/evidence`. The nine fixture, install and source scripts ran from that copy.
- **Two scripts ran in place.** `r32-shape.sh` and `r32-citations.sh` resolve `RUN` and `ROOT` from `$0` and only read files. They ran in place from `review/evidence/`.

All fresh logs went to `/tmp/r32-audit/out/`. The repository root was the shell's working directory throughout.

```
cp -R research/runs/R32/2026-09-26T190208Z-55160c36e3d0/review/evidence /tmp/r32-audit/evidence
bash /tmp/r32-audit/evidence/r32-install.sh  > /tmp/r32-audit/out/r32-install.log 2>&1
for s in tiers timeout isolation parallel taxonomy msrv hook; do
  bash /tmp/r32-audit/evidence/r32-$s.sh > /tmp/r32-audit/out/r32-$s.log 2>&1; done
GITHUB_TOKEN=$(gh auth token) bash /tmp/r32-audit/evidence/r32-sources.sh > /tmp/r32-audit/out/r32-sources.log 2>&1
bash research/runs/R32/2026-09-26T190208Z-55160c36e3d0/review/evidence/r32-shape.sh     > /tmp/r32-audit/out/r32-shape.log 2>&1
bash research/runs/R32/2026-09-26T190208Z-55160c36e3d0/review/evidence/r32-citations.sh > /tmp/r32-audit/out/r32-citations.log 2>&1
```

**`lib.sh` loads.** It was sourced rather than executed, and it was not byte-compared:

```
$ bash -c '. /tmp/r32-audit/evidence/lib.sh && echo "lib.sh sourced OK: FIXTURE=$FIXTURE PASS=$PASS FAIL=$FAIL; type stage: $(type -t stage)"'
lib.sh sourced OK: FIXTURE=/tmp/r32-audit/evidence/fixture PASS=0 FAIL=0; type stage: function
```

### Per-script results

In this table, "cmp vs committed .log" is the byte comparison between the fresh log and the committed paired log. Where a pair differs, the column quotes its first differing line pair, with the committed line marked `<` and the fresh line marked `>`.

| Script | Exit | Fresh result line | Observed output (key lines) | cmp vs committed .log |
|---|---|---|---|---|
| `r32-install.sh` (E1) | 0 | `RESULT PASS=5 FAIL=0` | newest three non-yanked: `0.9.146 2026-09-21… 1.91`, `0.9.145 2026-09-16…`, `0.9.144`; `Installed package cargo-nextest v0.9.146`; `install step took 166s`; `cargo-nextest 0.9.146 (8af696ddc 2026-09-21)` | differs: `< …versions at 2026-09-27T03:36:20Z` / `> …versions at 2026-09-27T06:01:24Z`. The committed log also says "already installed"; this run compiled the tool from crates.io |
| `r32-tiers.sh` (E2) | 0 | `RESULT PASS=29 FAIL=0` | E2e `4 run, 4 passed, 2 skipped (slow, live)`; E2j and E2y2 `6 run, 6 passed, 2 skipped`; E2q broken doc example exits 101; E2r fallback `cli binary 4 passed, 2 ignored` | differs: the first pair is the scratch path and `CARGO_TARGET_DIR` (`…/r32-tiers.ZWUF7m; …cargo-s13-R32-target…` versus `…/r32-tiers.GbO4AS; …cargo-s22-R32-emp-target…`), then cold-cache `Downloaded`/`Compiling` lines and nextest run UUIDs |
| `r32-timeout.sh` (E3) | 0 | `RESULT PASS=22 FAIL=0` | `gemini-form run took 4.12s, exit 0` (only SLOW); `TIMEOUT [ 2.007s]`, `terminate-probe run took 2.19s, exit 100`; committed config `SLOW [> 30.000s]` then `TIMEOUT [ 60.006s]`, `default-profile run took 60.27s, exit 100`; ci profile `TIMEOUT [ 1.006s]`, exit 100 | differs: scratch path in the first pair, then run UUIDs. Its PASS lines differ only in the `sleep` marker's process ID (`sleep 50373` versus `sleep 44239`) |
| `r32-isolation.sh` (E4) | 0 | `RESULT PASS=12 FAIL=0` | E4b1–E4b3 the residue-dependent test fails on 3 of 3 nextest runs; E4f and E4g `#[serial]` does not exclude under nextest; E4h the test group makes both pass | differs: scratch path in the first pair, then compile lines, a run UUID and a libtest thread ID |
| `r32-parallel.sh` (E5) | 0 | `RESULT PASS=4 FAIL=0` | `minimum wall clock of 3 warm runs: cargo test 2.11s; cargo nextest run 1.18s; cargo nextest run -j 1 2.23s` | differs: scratch path in the first pair, then timings, run UUIDs and test completion order |
| `r32-taxonomy.sh` (E6) | 0 | `RESULT PASS=22 FAIL=0` | E6a–E6f class selection exact; E6g and E6g2 override match and its control; E6l and E6m `default-filter` versus `cargo test` | differs: scratch path in the first pair, then compile lines and run UUIDs |
| `r32-msrv.sh` (E7) | 0 | `RESULT PASS=6 FAIL=0` | on 1.96.0 `6 run, 6 passed, 2 skipped`; doc-test passes; E7f `predicates` 3.1.4 is a normal dependency of `assert_cmd` 2.2.2 | differs: scratch path in the first pair, then compile lines, a run UUID and test order |
| `r32-hook.sh` (E8) | 0 | `RESULT PASS=8 FAIL=0` | the job runs through `lefthook run pre-push` in a scratch git repository; unset prints the skip notice and exits 0; `=1` runs `4 tests run: 4 passed, 2 skipped` plus the doc-test; opted in with a failing test exits non-zero; not opted in exits 0 | differs: scratch path in the first pair, then compile lines and run UUIDs |
| `r32-sources.sh` (E9) | 0 | `RESULT PASS=23 FAIL=0` | every figure in the next section is identical to the committed log | differs **only in retrieval timestamps**: first differing line `< INFO 2026-09-27T03:39:53Z GET https://api.github.com/repos/nextest-rs/nextest/contents/site/src/docs/running.md?ref=cargo-nextest-0.9.146 …`. With timestamps and paths masked, the diff is empty |
| `r32-shape.sh` (E11) | 0 | `RESULT PASS=4 FAIL=0` | `OK: validation passed` for `raw/muse.md` and `raw/opus.md` (the script's output; this audit did not open `raw/`) | **identical** (`cmp` exit 0) |
| `r32-citations.sh` (E10) | 0 | `RESULT PASS=116 FAIL=0` | every citation, `assumes` line, prerequisite hash and H2 check passes | **identical** (`cmp` exit 0) |
| **Total** | | **PASS=251 FAIL=0** | no check was skipped | 2 identical; 9 differ in volatile tokens only |

**Verdict lines.** For all 11 scripts, `diff` of the `^(PASS|FAIL|RESULT)` lines between the committed and fresh logs is empty. The one exception is `r32-timeout.sh`: its E3g, E3l and E3s lines differ only in the random process ID of the `sleep` child.

**Masked diff.** A second `diff` masked scratch paths, durations, ISO timestamps, `sleep` process IDs and nextest run UUIDs. It left only three kinds of difference:

- cold-cache `Downloading`/`Compiling` lines, because the cargo home and target directory were fresh;
- nextest test completion order;
- the install step's fresh build versus "already installed".

No figure, count or exit code differs.

**shellcheck.** `DECISION.md:294` claims all eleven scripts and `lib.sh` are `shellcheck -x` clean. The rerun reproduces that result. `/opt/homebrew/bin/shellcheck -x lib.sh r32-*.sh` (ShellCheck 0.11.0), run in `/tmp/r32-audit/evidence`, exited 0 and printed nothing. The committed `shellcheck.log` is a wrapper-formatted `OK <file>` summary, so it is not byte-comparable; its outcome (12 files OK) matches.

**Evidence untouched.** The `review/evidence/` mtime is unchanged (`Sep 26 20:44`). No new file appeared under it; `r32-install.cargo-install.txt` and `snapshots/` were written only in the `/tmp` copy.

## Figures re-derived at source

| Claim in DECISION.md | Committed | Fresh re-derivation | Holds? |
|---|---|---|---|
| newest `cargo-nextest` 0.9.146 (2026-09-21), `rust_version` 1.91; 0.9.145 older (E1a–E1c) | yes | crates.io versions endpoint: same | yes |
| nextest provisioned from crates.io with no prebuilt host (`DECISION.md:256`) | log shows "already installed" | built from source into an empty `CARGO_HOME` in 166 s; `cargo-nextest 0.9.146 (8af696ddc 2026-09-21)` | yes, **now observed**, not only asserted |
| hang: `TIMEOUT [60.003s]`, 60.22 s wall clock, exit 100, child gone (E3h–E3l) | 60.003 s / 60.22 s | `TIMEOUT [60.006s]`, 60.27 s, exit 100, child gone | yes |
| E5: `cargo test` 2.21 s, nextest 1.30 s, `-j 1` 2.57 s | yes | 2.11 s, 1.18 s, 2.23 s; thresholds (≥ 1.9 s, < 1.6 s, ≥ 1.9 s) hold | yes; run-to-run variance only |
| downloads, stars, archived, open issues in `### Members` (`DECISION.md:192-194`) | yes | `cargo-nextest` 1,867,747 / 12,951,672, 3,303 stars, 76 issues; `assert_cmd` 17,910,361 / 86,407,589, 563 stars, 24 issues; `predicates` 41,338,519 / 230,472,045, 213 stars; none archived | yes, identical |
| RustSec: 404 for the four crates; control `time` 200 (E9n, E9o-*) | yes | same | yes |
| `.config/nextest.toml` byte-identical to the fixture, sha `e6ab4bed…` (`DECISION.md:88`) | — | the quoted TOML block equals `fixture/.config/nextest.toml` byte for byte; `SHA256SUMS-fixture` lists `e6ab4bedaa65…105524`; all 15 fixture hashes check OK (`shasum -a 256 -c` from `evidence/`) | yes |
| fixture `Cargo.lock` locks 25 packages besides the package (`DECISION.md:191`) | — | 26 `name =` entries, 25 excluding `rs-launch-blueprint` | yes |
| the `tests/cli/binary.rs` excerpt was executed (E2g) | — | the quoted function `binary_usage_error_exits_2_with_empty_stdout` is verbatim in `fixture/tests/cli/binary.rs`; the file also holds `binary_lists_projects` | yes (the block is labelled an excerpt, not a whole file) |
| every cited evidence ID exists | — | 94 distinct cited IDs; every one is a `PASS` line in a fresh log, except the group prefixes `E4b`, `E9m` and `E9o`, which cover E4b1–E4b3, E9m-* and E9o-* | yes |
| R11 citations: `DECISION.md:282` (R32 slot row), `:294` (the rustdoc part is `check`'s doc build step), `:320` (`cargo test` for both test steps), `:329` (R69 revision 10 moves the web tests to `crates/web/tests/`) | E10 PASS | read at source: each line carries the quoted substance | yes |
| Q17.A extends the Muse-for-Codex substitution to R32 (`research/RUNBOOK.md:73-76`) | — | RUNBOOK:73-76 lists R32 in the Q17.A wave (`muse+opus; plus doxa for Deep R32…`) | yes |

## Observations (not findings)

1. **"Byte-identical" Justfile and hook wording.** `DECISION.md:110` reads: "The `Justfile` recipes and the hook job — byte-identical to `fixture/Justfile` and `fixture/lefthook.yml`". The fixture files prepend comment lines that the quoted blocks omit:
   - `fixture/Justfile` starts with one extra line: `# Test recipes (R32). R42: cargo <sub> form, no runner prefix, no Cargo alias.`
   - `fixture/lefthook.yml` starts with two extra lines: `# Opt-in, default-skip pre-push full suite (R32, F173). The hook manager and` and `# this file's location are R37's; the job body is R32's.`

   Every recipe body and the job body match byte for byte (`cat -e`). Comments are inert in both formats, so what E6 and E8 executed is exactly what the decision recommends. The sentence's subject is the recipes and the job, so the claim holds as written. **Optional tidy-up:** in a later revision, add the comment lines to the quoted blocks, or say "the recipe and job bodies are byte-identical".
2. **Controller note (a), the engine swap.** The frozen `inputs/prompt.md` still lists `codex, opus, doxa`. The decision records the Muse substitution itself and cites Q17.A (`DECISION.md:307`, RUNBOOK:73-76). No check in this rerun failed because of the swap. **Repair, if the checker requires it:** the controller re-freezes the inputs and cites Q17.A.
3. **Operation records.** The Muse and Opus legs have no operation record in the run directory. The decision states this itself (`DECISION.md:302-303`). The G8 self-disclosure also stands: the synthesizer is the same model as the Opus leg (`claude-opus-5-5`), while RUNBOOK §2 names a fresh Fable context for synthesis. Both are for the controller.
4. **`serial_test` is now at 4.0.1.** The fresh `r32-sources.log` shows `serial_test` newest `4.0.1 2026-07-25 rust_version 1.93.1`. E4e–E4g tested Muse's 3.5.0 pin, and E9j cites the README at `v3.5.0`. The decision makes no claim about 4.x. Its rejection rests on nextest's documented model: in-process mutexes are unsupported under process-per-test (E9c, reproduced). The argument therefore stands. A 4.x recheck would only strengthen the Disagreement 3 record.
5. **Controller note (b), the `CONFLICT: R11` line.** The line (`DECISION.md:246`) rests on E3m (a hang is still running under `cargo test` after 15 s), E3n (`--ensure-time` is nightly-only), E9a (nextest runs no doc-tests) and E2s (`cargo test` runs them). All four reproduced. The line's proposed `check` steps were not run in a workflow, as the decision says (`DECISION.md:296`). Disposing of the line is the controller's business. The line is supported as evidence.

## Verdict

**approve.** Every committed check reruns green on this host (251 of 251 pass). The load-bearing figures re-derive at source. The recommended configuration, commands and version pins execute as the decision states (RUNBOOK §5). The decision's own gaps (G1–G8) accurately bound what the evidence does not establish. `unresolved-findings: none`.
