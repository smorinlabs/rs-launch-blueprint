actor: codex
model: gpt-6-sol
family: openai
session-thread-id: 01a0e3f7-954f-7851-ab16-218c046caf18
decision-sha256: 2ad574f88a1d5d20927a3225d0168ef1ee18c73480adf0734d5aa994d90863d1
verdict: approve
unresolved-findings:

1. **MECHANICAL — byte replay wording and recorded drift.** Claim: “Checks T, S, P, W, A, E, G and H are deterministic on this host” (`DECISION.md`, `## Empirical check`, Reproducibility). Evidence: `cmp` returned different for all 11 paired logs; the first differing lines for each pair are quoted below. The `PASS` and `SUMMARY` lines are byte-identical in every pair, and all 110 fresh assertions pass. Other differences are run-specific paths and times, test order, benchmark timings, non-blocking exit counts, and live download counters. **Repair:** say that the *assertion outcomes* are deterministic where claimed, not the complete log bytes. Add a dated replay note to `## Empirical check` with 11/11 non-identical byte comparisons, 110/110 matching assertion outcomes, and the changed dynamic values listed below. Preserve the paired evidence logs.
2. **MECHANICAL — scope of the per-file size claim.** Claim: “Every file ≤ limit” (`DECISION.md`, member 1 property table). Evidence: W03 proves this only for 78-byte records at a 4,096-byte limit. In the probe source, `RotatingFile::write` skips rotation when `self.size == 0` and writes the whole buffer (`r59-check/src/lib.rs:61-72`). An independent scratch probe wrote one 5,000-byte record at a 4,096-byte limit and observed `configured_limit=4096 written_record=5000 file_bytes=5000`. The decision already permits an overshoot of one record under “May vary”; this does not change the selected writer. **Repair:** change the table cell to “≤ 4,096 bytes for the tested 78-byte records; one record larger than the limit can exceed it.” State that the bound is conditional on record size, and add an oversized-record case with that expected behavior to the P03 validation list.

## Method and environment

I verified the decision SHA-256 before reading or executing anything else, then recomputed it before writing this audit; both results match the header. I read `research/RUNBOOK.md` section 5, the decision, the eleven check scripts, their helper, the probe source, and the paired logs. I did not read another audit, a topic `raw/` directory, or a review snapshot.

The first `r59-ansi.sh` attempt exited 99 before any assertion: Cargo reported `download of config.json failed` and `Could not resolve host: index.crates.io`. I interrupted the following `r59-bench.sh` attempt before it emitted a summary. Both attempts wrote only under `/tmp`; neither is counted as a completed check. I copied the existing cached registry into the private `CARGO_HOME=/tmp/cargo-s49-R59-emp`, verified `cargo metadata --locked --offline` exited 0, and reran the complete local suite with `CARGO_NET_OFFLINE=true`. `CARGO_TARGET_DIR` was under `/tmp`, so `cargo test` did not create a target tree in the repository. The live check made the script's read-only public HTTP queries with network permission. `shellcheck -x` over all twelve `.sh` files, including `r59-common.sh`, exited 0 with no output. The helper is not a check and is excluded from the totals.

Working directory: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`.

```bash
E=research/runs/R59/2026-09-26T190256Z-4c0fef2a9f93/review/evidence
AUDIT_TMP=/tmp/r59-codex-r2-01a0e3f7-954f-7851-ab16-218c046caf18
export CARGO_TARGET_DIR="$AUDIT_TMP/target" CARGO_NET_OFFLINE=true
# Each command below used its named script and wrote stdout and stderr to /tmp.
```

## Completed reruns

Each row gives the executed command, selected observed output from its fresh log, and pass/fail/skip totals. Every script exited 0. Full fresh logs and `diff -u` output are under `AUDIT_TMP`.

| Check | Command | Observed output | Pass/fail/skip |
|---|---|---|---|
| E | `"$E/r59-ansi.sh" > "$AUDIT_TMP/r59-ansi.log" 2>&1` | `esc_bytes=12` by default; `esc_bytes=0` with ANSI off; user escape text check `1/1` | 3/0/0 |
| D | `"$E/r59-bench.sh" > "$AUDIT_TMP/r59-bench.log" 2>&1` | Owned blocking `191/190/190` ms; `file-rotate` `189/189/189` ms; owned non-blocking emit `45/45/47` ms for 100,000 events | 3/0/0 |
| P | `"$E/r59-deps.sh" > "$AUDIT_TMP/r59-deps.log" 2>&1` | `file-rotate` has 11 unique normal packages including itself; `chrono` and `flate2` are direct | 5/0/0 |
| C | `"$E/r59-exit-durability.sh" > "$AUDIT_TMP/r59-exit-durability.log" 2>&1` | Owned and `file-rotate`: `1000 1000 1000` lines; live-guard non-blocking: `164 180 187`; dropped-guard: `1000 1000 1000` | 4/0/0 |
| A | `"$E/r59-floor.sh" > "$AUDIT_TMP/r59-floor.log" 2>&1` | `current=debug` with file, `warn` without; global WARN loses file debug; JSON `file_lines=2 file_json_lines=2` | 11/0/0 |
| L | `"$E/r59-live-figures.sh" > "$AUDIT_TMP/r59-live-figures.log" 2>&1` | Pinned newest versions unchanged; `file-rotate` 10-issue sample remains 7 answered, 3 unanswered, 1.9-day median; OS matrices and tracker states unchanged | 22/0/0 |
| H | `"$E/r59-msrv.sh" > "$AUDIT_TMP/r59-msrv.log" 2>&1` | `rustc 1.96.0`; locked release build exited 0; 8 library tests passed | 4/0/0 |
| G | `"$E/r59-precedence.sh" > "$AUDIT_TMP/r59-precedence.log" 2>&1` | `test result: ok. 8 passed; 0 failed` | 3/0/0 |
| S | `"$E/r59-source-reads.sh" > "$AUDIT_TMP/r59-source-reads.log" 2>&1` | Pinned `file-rotate` panic, `.ok()`, and size-trigger lines present; `tracing-subscriber` default `log_internal_errors: false` and conditional reporting present | 22/0/0 |
| T | `"$E/r59-toolchain.sh" > "$AUDIT_TMP/r59-toolchain.log" 2>&1` | `rustc 1.98.1`, `cargo 1.98.1`, macOS 26.4 on Darwin arm64; rustc 1.96.0 installed | 4/0/0 |
| W | `"$E/r59-writer-contract.sh" > "$AUDIT_TMP/r59-writer-contract.log" 2>&1` | Owned rotation has 0 partial records and a 4,056-byte maximum in W01–W05; `file-rotate` panics at the cited paths; reporting-on emits two diagnostics | 29/0/0 |

**Total: 11 completed scripts, 110 passed assertions, 0 failed, 0 skipped.**

## Byte comparisons

For each pair I ran `cmp -s "$E/r59-$c.log" "$AUDIT_TMP/r59-$c.log"` and `diff -u "$E/r59-$c.log" "$AUDIT_TMP/r59-$c.log" > "$AUDIT_TMP/r59-$c.diff"` on mismatch. All eleven `cmp` calls reported a difference. These are the **first differing lines** from each diff: `-` is the paired log; `+` is the fresh log.

| Check | Paired first differing line | Fresh first differing line |
|---|---|---|
| E / ansi | `-run (UTC): 2026-09-27T02:48:45Z` | `+run (UTC): 2026-09-27T17:47:52Z` |
| D / bench | `-run (UTC): 2026-09-27T02:48:46Z` | `+run (UTC): 2026-09-27T17:48:01Z` |
| P / deps | `-run (UTC): 2026-09-27T02:48:43Z` | `+run (UTC): 2026-09-27T17:48:03Z` |
| C / exit-durability | `-run (UTC): 2026-09-27T02:48:45Z` | `+run (UTC): 2026-09-27T17:48:03Z` |
| A / floor | `-run (UTC): 2026-09-27T02:48:44Z` | `+run (UTC): 2026-09-27T17:48:04Z` |
| L / live-figures | `-run (UTC): 2026-09-27T02:48:48Z` | `+run (UTC): 2026-09-27T17:48:15Z` |
| H / msrv | `-run (UTC): 2026-09-27T02:48:46Z` | `+run (UTC): 2026-09-27T17:48:04Z` |
| G / precedence | `-run (UTC): 2026-09-27T02:48:46Z` | `+run (UTC): 2026-09-27T17:48:19Z` |
| S / source-reads | `-run (UTC): 2026-09-27T02:48:43Z` | `+run (UTC): 2026-09-27T17:48:24Z` |
| T / toolchain | `-run (UTC): 2026-09-27T02:48:42Z` | `+run (UTC): 2026-09-27T17:48:24Z` |
| W / writer-contract | `-run (UTC): 2026-09-27T02:48:44Z` | `+run (UTC): 2026-09-27T17:48:25Z` |

I inspected every full diff. Additional changes were temporary Cargo paths and scratch paths; event timestamps in E and A; a different test print order in G; compile duration in H; process IDs in W; and the expected variable measurements in C, D, and L. In D, `cpu: Apple M4 Pro` became `cpu: arm64` because the script fell back to `uname -m`. C's live-guard count changed from `48 0 182` to `164 180 187`, still below 1,000 in every run. L's `tracing-subscriber` recent/all-time download counters changed from `146641301/627181762` to `147308191/627848048`; all eight newest versions, repository fields, CI matrices, issue sample, advisory statuses, and assertion lines remained the same. Extracting `PASS`, `FAIL`, and `SUMMARY` lines from each old/fresh pair and comparing those streams with `cmp` produced equality in all eleven pairs.

## Independent source and figure checks

- The fresh dependency tree has 11 unique normal packages for `file-rotate` and 15 for `tracing-subscriber`; the latter prints 17 tree lines because `serde` and `tracing-core` repeat as `(*)`. This confirms the revision-2 count repair.
- W's fresh file scans show the owned writer at 4,056 bytes maximum with zero partial records for 78-byte events; `BytesSurpassed` reaches 4,134 bytes with zero partial records; `Bytes` tears records. The pinned `file-rotate` source still has the `expect`, `.ok()`, and `assert!` sites printed by S. The fresh W run reproduced their effects.
- The pinned `tracing-subscriber` source still sets `log_internal_errors: false` by default and prints writer errors only when the flag is true. W reproduced zero diagnostics by default and two with `.log_internal_errors(true)`.
- The independent oversized-record probe used the same compiled `r59_check::RotatingFile` library, a scratch path, a 4,096-byte limit, and one 5,000-byte write. It exited 0 with a 5,000-byte file. This qualifies the size-bound wording as finding 2; the decision's explicit W01–W10 workload and one-record-overshoot allowance keep it mechanical.

The stated R58 dependency, Ubuntu CI gap, binary-level tests, and redaction test remain disclosed P03 or controller work. No rerun disproved the recommendation or a load-bearing observed result.
