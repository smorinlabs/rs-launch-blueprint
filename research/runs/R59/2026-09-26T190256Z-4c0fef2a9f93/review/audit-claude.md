actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 15211fc070b2a29943b7a4cda6de6bdfae6b58a684dfca78a4c4c5f62c966d79
verdict: approve
unresolved-findings: none

# R59 file-log-sink — empirical audit of DECISION.md revision 1

Seat: empirical auditor, fresh context, independent of the synthesizer and the judgment auditor.
Scope: execution truth and evidence support only. I read `review/DECISION.md` (in full),
`research/RUNBOOK.md` §5, the evidence scripts and probe crate, the run's `inputs/` and
`manifest.json` lines the decision cites, and the published crate sources in the private cargo
home. I did not read any `review/audit-*.md`, any `raw/` report, or any `R*-snapshot.md`.

## Identity

- `shasum -a 256 research/runs/R59/2026-09-26T190256Z-4c0fef2a9f93/review/DECISION.md`
  → `15211fc070b2a29943b7a4cda6de6bdfae6b58a684dfca78a4c4c5f62c966d79`. It matches the expected
  hash, so this audit binds to revision 1 at that hash.
- Run on 2026-09-27 05:47–05:49 UTC (2026-09-26 Pacific). Host: `Darwin 25.4.0 arm64`, Apple
  M4 Pro. `rustc 1.98.1` (Homebrew) plus `rustc 1.96.0` (rustup) for check H. `shellcheck`
  0.11.0. `CARGO_HOME=/tmp/cargo-s22-R59-emp` (private).

## Rerun

Working directory: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. Every check was run cold
into a target directory of my own, with output to `/tmp`, never into `evidence/`:

```bash
E=research/runs/R59/2026-09-26T190256Z-4c0fef2a9f93/review/evidence
export CARGO_TARGET_DIR=/tmp/r59-audit-claude/target
bash "$E/r59-<c>.sh" > /tmp/r59-audit-claude/r59-<c>.log 2>&1   # then: cmp "$E/r59-<c>.log" /tmp/r59-audit-claude/r59-<c>.log
```

| Script | rc | Fresh `SUMMARY` | Decision's count | `cmp` vs paired `.log` | Differences (all volatile) |
|---|---|---|---|---|---|
| `r59-toolchain.sh` | 0 | 4 checks, 0 failed, 0 skipped | 4/4 | differ, line 2 | `run (UTC)` line only |
| `r59-source-reads.sh` | 0 | 22 checks, 0 failed, 0 skipped | 22/22 | differ, line 2 | `run (UTC)`; registry path `/tmp/cargo-s13-R59/…` → `/tmp/cargo-s22-R59-emp/…` in the three `##` headers |
| `r59-deps.sh` | 0 | 5 checks, 0 failed, 0 skipped | 5/5 | differ, line 2 | `run (UTC)` line only |
| `r59-writer-contract.sh` | 0 | 29 checks, 0 failed, 0 skipped | 29/29 | differ, line 2 | `run (UTC)`; `CARGO_TARGET_DIR`; `mktemp` dir (`tmp.1oHtGOxX2S` → `tmp.bDmktRDuyz`); panic thread IDs and registry path. Panic sites are identical: `file-rotate-0.8.0/src/lib.rs:425:56`, `:553:9`, `:554:9` (×5) |
| `r59-floor.sh` | 0 | 11 checks, 0 failed, 0 skipped | 11/11 | differ, line 2 | `run (UTC)`; `CARGO_TARGET_DIR`; JSON `timestamp` values only |
| `r59-ansi.sh` | 0 | 3 checks, 0 failed, 0 skipped | 3/3 | differ, line 2 | `run (UTC)`; `CARGO_TARGET_DIR`; event timestamps inside `file_text=` only. Escape-byte structure identical |
| `r59-exit-durability.sh` | 0 | 4 checks, 0 failed, 0 skipped | 4/4 | differ, line 2 | `run (UTC)`; `CARGO_TARGET_DIR`; `nonblocking: … runs 1/2/3 = 48 0 182` → `= 0 128 0` (still < 1,000 in every run, which is all that is asserted) |
| `r59-precedence.sh` | 0 | 3 checks, 0 failed, 0 skipped | 3/3 | differ, line 2 | `run (UTC)`; `CARGO_TARGET_DIR`; `cargo test` print order of `p1`/`p3`/`p6` (parallel test harness). All 8 tests `ok` |
| `r59-msrv.sh` | 0 | 4 checks, 0 failed, 0 skipped | 4/4 | differ, line 2 | `run (UTC)`; cold target adds `Compiling r59-check v0.0.0 (…)` and `Finished … in 19.52s` versus `0.10s` |
| `r59-bench.sh` | 0 | 3 checks, 0 failed, 0 skipped | 3/3 | differ, line 2 | `run (UTC)`; `CARGO_TARGET_DIR`; timings (below) |
| `r59-live-figures.sh` | 0 | 22 checks, 0 failed, 0 skipped | 22/22 | differ, line 2 | `run (UTC)` line only — every live counter, CI matrix, tracker state and the responsiveness table reproduced byte-for-byte |

**Totals: 11 scripts, 110 assertions, 110 passed, 0 failed, 0 skipped.** This equals the
decision's "11 checks, 110 assertions, 0 failed, 0 skipped" (`DECISION.md:557`). No `FATAL`
line appeared; every build used `--locked`, and the `Cargo.lock sha256:` line printed by
`build_probe` is identical in every fresh log, so the committed lockfile was honoured unchanged.

**Helper.** `r59-common.sh` is not a check and was not byte-compared. Sourced under bash
(`bash -c 'source "$E/r59-common.sh"'`) it loads: `CRATE` resolves to `…/evidence/r59-check`,
`FAILS=0`, `CHECKS=0`, and `build_probe`, `check`, `field`, `finish` and `header` are defined.
A first attempt sourced it from the tool's zsh shell and printed
`r59-common.sh:15: BASH_SOURCE[0]: parameter not set`, resolving `CRATE` to the repo root; that
is expected for a bash-only helper (every check is a `#!/usr/bin/env bash` script), not a defect.

**`shellcheck -x "$E"/*.sh`** over the 12 scripts: rc 0, no output. Matches `DECISION.md:556`.

**Bench (check D), fresh versus committed** (ms per 100,000 events, 3 runs):

| Writer | Committed | Fresh |
|---|---|---|
| owned, blocking | 195 / 198 / 322 | 372 / 287 / 208 |
| `file-rotate` `BytesSurpassed`, blocking | 200 / 192 / 193 | 214 / 252 / 253 |
| owned + `non_blocking`, emit (total) | 46 / 46 / 46 (152 / 149 / 149) | 59 / 51 / 122 (286 / 815 / 353) |

The fresh run supports the decision's actual claim (`DECISION.md:438-440`, D8): the two blocking
writers overlap run to run at roughly 2–4 µs per event, so performance does not discriminate, and
D1 does not rest on it. Opus's 420–576 ms for `file-rotate` again did not reproduce.

## Load-bearing figures re-derived at source

| Claim in the decision | Source re-read | Result |
|---|---|---|
| `file-rotate` 0.8.0 `expect`/`.ok()`/`assert!` at `src/lib.rs:425, 446, 485, 553-554` | `sed -n` on the registry copy | 425 `….expect("create dir")`; 446 `….expect("create dir")`; 485 `self.file = open_options.open(&self.basepath).ok();`; 553 `assert!(old_path.exists());`; 554 `assert!(!new_path.exists());` — match |
| `fmt_layer.rs:752` default `false`, `:362` doc "Defaults to true", `:1051` gated print | `tracing-subscriber-0.3.23/src/fmt/fmt_layer.rs` | 362 `/// Defaults to true.`; 752 `log_internal_errors: false,`; 1051 `if self.log_internal_errors {` — match |
| `unsafe`: 26 lines, 28 tokens, 6 files (S18–S20) | `/usr/bin/grep -rn -w` / `-ow` / `-rl` over `src/` | 26 / 28 / 6 files (`reload.rs`, `fmt/mod.rs`, `fmt/fmt_layer.rs`, `layer/layered.rs`, `layer/mod.rs`, `filter/layer_filters/mod.rs`) — match |
| `tracing-appender` 0.2.5 rotates by time only (S15, S16) | `rolling.rs` | `enum RotationKind { Minutely, Hourly, Daily, Weekly, Never }`; five `pub const` at 501–509; no size field (only `max_files`) — match |
| `tracing-subscriber` `rust-version` 1.65.0 (S14); none for `file-rotate` (S09) | both `Cargo.toml` | `rust-version = "1.65.0"`; `file-rotate` declares none — match |
| `file-rotate` responsiveness median 1.9 days, 7 answered / 3 unanswered (`r59-live-figures.log:65`) | per-issue lines 55–64, recomputed | answered days 0, 0.1, 0.3, 1.9, 2.6, 10.4, 32 → median 1.9; line 65 is the `sample=10 answered=7 unanswered=3 …=1.9` line — match; reproduced live today |
| Owned writer "61 lines of code … excluding comments, blank lines and tests" | `src/lib.rs` | 61 non-blank, non-comment lines in `lib.rs:9-78` (the `RotatingFile` struct and both `impl` blocks); see observation 5 |
| Owned writer trigger and 4,056-byte ceiling (W03) | `lib.rs:63` | `self.size + len >= self.max_bytes` rotates before the write: 52 × 78 = 4,056 < 4,096 and 4,134 ≥ 4,096 — consistent |
| Input citations | `inputs/PARAMETERS.md:16-18`, `inputs/prerequisites.json:1-6`, `inputs/prompt.md:8, 11, 15, 20-21, 27, 31-37, 56`, `inputs/EXECUTION.json:635-640`, `manifest.json:27-30`, `research/RUNBOOK.md:71-75`, R53 `DECISION.md:45-49`, R64 `DECISION.md:21` | Each resolves to the quoted content: `logging-pipeline-contract` = `—`; R58 `"decision": "missing"`; R67's `ExitCode`/no `process::exit`/"all streams are flushed b[efore exit]", `RSLB101` → 1 and `RSLB203` → 2; R69's "R4.1 required global core and nothing beyond it" and "log format … stays an environment variable named by R77"; `codex`,`opus` engines; Q17.A naming R59; Q7.B licence ruling; `RSLB_PAGER` |

## Observations (not findings)

1. **Reproducibility note is incomplete.** `DECISION.md:573-575` says T, S, P, W, A, E, G and H
   are deterministic and that rerun differences are only "timestamps in A and E, the CARGO paths,
   and the `run (UTC)` line". The rerun also differs in G (`cargo test` output order), W
   (`mktemp` paths and panic thread IDs) and H (a `Compiling …` line on a cold target). No
   assertion depends on those bytes, and every asserted fact reproduced. Suggested wording repair:
   "also varies: test print order in G, `mktemp` paths and thread IDs in W, and the compile line
   in H on a cold target".
2. **Engine seat (controller note a).** `inputs/EXECUTION.json:635-640` and `manifest.json:27-30`
   still require `codex, opus`, while the working-tree `research/RUNBOOK.md:71-75` records Q17.A
   (2026-09-27) extending the Muse substitution to R59. The decision discloses this itself
   (`DECISION.md:605-618`, gap 9). Repair: controller re-freezes inputs + cites Q17.A. Not a
   failure of the synthesis. Note that `research/RUNBOOK.md` is modified in the working tree.
3. **R58 conditional (controller note b).** The decision states it is not acceptable until R58
   lands (`DECISION.md:9-14`), registers `assumes logging-pipeline-contract = —`, lists a
   five-part working assumption and a `log`-facade fallback. The empirical evidence (A01–A09)
   supports the per-layer-filter constraint it places on R58. Controller/owner business.
4. **Controller note c** (tower-http 0.6.11 versus 0.7.x) concerns R78/R75; it does not arise in
   R59.
5. **The "61 lines" figure** is correct only for `lib.rs:9-78` (writer only, excluding the four
   `use` lines and the resolver); the non-test file outside tests is 79 such lines. No script
   asserts this count. The phrasing "in the probe's `src/lib.rs`" is loose but the figure is
   right for the writer, which is what it describes.
6. **Evidence is not committed.** `git status --porcelain research/runs/R59` → `?? research/runs/R59/`.
   The paired logs, the probe crate and the decision are working-tree files; this audit's hash
   binds to the working-tree bytes. My reruns wrote nothing under `evidence/` (the listing and
   untracked state are unchanged afterward).
7. **Not proven, as the decision itself states** (`DECISION.md:580-588`): nothing ran on
   `ubuntu-latest`; no binary-level test; AC7; real two-process rotation (modeled in-process);
   `logroller` and `flexi_logger` behavior; the `0o700` mode is set (`lib.rs:37`) but not
   asserted. These are disclosed gaps, not unsupported claims.
