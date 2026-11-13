# R35 revision 4 empirical audit

actor: codex-empirical-r35-r4
model: gpt-6
family: openai
decision-sha256: d026820ce72b25429e5520d67b6e1a89d310b8bfbb57cc6486e40a472496eef7
verdict: approve
unresolved-findings: none

## Re-execution

The decision hash was verified before reading or executing evidence. All seven evidence scripts were run in the foreground with `CARGO_HOME=/tmp/cargo-s73-R35-evr` and `CARGO_TARGET_DIR=/tmp/cargo-s73-R35-evr-target`; outputs and mutable source snapshots were kept under `/tmp`. The install was retried after sandbox DNS resolution failed; the network-enabled retry passed. No repository evidence was changed.

| Script | Committed revision 4 reference | This rerun | Whole-output comparison |
|---|---:|---:|---|
| `r35-install.sh` | 8/0 | 8/0 | timestamp, private Cargo path, build duration |
| `r35-coverage.sh` | 29/0 | 29/0 | timestamp, fixture path and file-list order, test/build durations |
| `r35-flags.sh` | 29/0 | 29/0 | timestamp |
| `r35-toolchain.sh` | 7/0 | 7/0 | timestamp |
| `r35-sources.sh` | 25/0 (`rerun-r4/r35-sources.log`) | 25/0 | timestamp and missing issue-detail `INFO` lines caused by `tee` error; all remaining lines match |
| `r35-tarpaulin.sh` | 8/0 | 8/0 | timestamp |
| `r35-inputs.sh` | 128/0 | 128/0 | timestamp |
| **Total** | **234/0** | **234/0** | |

`cmp` found each complete log unequal; whole-log unified diffs identified the differences above. The decision's disclosed timestamp, scratch-path, duration, and rolling-count drift remains non-outcome-changing. Relative to the committed revision 4 source log, the live figures and all PASS/FAIL lines match. The installed 0.9.1 packaged README and the tarpaulin 0.37.4 README are byte-identical to their committed snapshots.

## Revision 4 repairs

- `S2a` passed: newest non-yanked `cargo-tarpaulin` is 0.37.5, created 2026-09-27, with no declared `rust_version`. The decision's qualified shortlist and ranked runner-up use 0.37.5.
- `S12h` passed: the README at tag 0.37.5 is byte-identical to the committed 0.37.4 README. The signal and engine statements cited from it still apply.
- `X7a` and `X7` passed: revision notes run 1 through 4 and the title says revision 4. The revision 4 prose at decision lines 88–109 and D13 at line 338 marks F136/F137 as class-F owner calls and the merge-blocking recommendation as a proposal.

## Findings

- **OBS-1 (OBS):** The coverage log's fixture file list has a different directory-enumeration order, beyond the decision's stated timestamp, scratch-path, and duration drift. The listed files and all 29 checks match; no load-bearing claim changes.
- **OBS-2 (OBS):** In this sandbox, `r35-sources.sh` printed `tee: /dev/stderr: Operation not permitted` twice and omitted the issue-detail `INFO` lines. `S5a` and `S5b` still passed with the committed answered, unanswered, and median values; all 25 checks passed. A repeat with a terminal produced the same sandbox error.
