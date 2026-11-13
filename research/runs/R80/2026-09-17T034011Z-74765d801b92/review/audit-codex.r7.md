actor: codex
model: gpt-6
family: openai
decision-sha256: 065dfba6cded1036b6c2a89acbc9ad71db0aa0dddcdb68a8e3a1da49b6ad1a85
execution-sha256-at-S79: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
verdict: approve
unresolved-findings: none

# R80 revision 7 — empirical re-run audit

This is the one Q23 empirical worker audit. `DECISION.md` matched the pinned SHA-256 before review and again before this file was written. I ran the unchanged scripts from a copy of `review/evidence/` at `/tmp/r80-codex-r7/evidence`, with all output under `/tmp/r80-codex-r7/`. The supplied private `CARGO_HOME` and `CARGO_TARGET_DIR` were used. The first probe run could not resolve crates.io in the restricted network; the unchanged probe passed with public network access and passed again with a warm Cargo cache. No input, snapshot, decision, evidence script, or committed log was written.

## Re-runs and byte comparisons

Each raw comparison below used file bytes against the named committed log. Counts are PASS/FAIL/SKIP. Assertion comparison includes every `PASS`, `FAIL`, and `SKIP` line and the final count. The four revision-7 edited scripts are `check-offline.sh`, `check-standard-r2.sh`, `check-standard-r3.sh`, and `check-standard-r4.sh` (`DECISION.md:33-49`, `DECISION.md:1114-1119`).

| Script or mode | Fresh count | Committed log | Raw bytes | Assertions |
|---|---:|---|---|---|
| `check-offline.sh` | 28/0/0 | `check-offline.log` | differ: UTC stamp | identical |
| `check-probe.sh`, warm cache | 13/0/0 | `check-probe.log` | differ: UTC stamp, temporary paths, Cargo target and timing | identical |
| `check-standard-r2.sh` | 42/0/0 | `check-standard-r2.log` | differ: UTC stamp, temporary paths, Cargo target and timing | identical |
| `check-standard-r3.sh` | 7/0/0 | `check-standard-r3.log` | differ: UTC stamp | identical |
| `check-standard-r4.sh` | 12/2/0 | `check-standard-r4.log` | differ: UTC stamp | identical |
| `check-live.sh --snapshots` | 9/0/0 | `check-live.r4-snapshots.log` | differ: UTC stamp | identical |
| `check-live.sh`, public fetch | 9/0/0 | `check-live.r4-fetch.log` | differ: UTC stamp and moving counters | identical |
| `shellcheck` on all six scripts | exit 0; 0 output bytes | `shellcheck-r7.log` | identical | identical |

The fresh snapshot log also has the same nine assertions as the original `check-live.log`; its raw difference is the `mode: snapshots` banner and UTC stamp. For the six non-fetch script logs, replacing only UTC stamps, temporary workspace paths, Cargo target paths, and Cargo durations makes each full log byte-identical to its committed counterpart. The fresh fetch log changes download and search counters only. These differences match the reproduction and live-counter disclosures at `DECISION.md:1340-1410`.

## Revision-7 checks

- The flag-day `- assumes web-extra-surface = ` value at `DECISION.md:1025` equals the `- owns web-extra-surface = ` value at `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1885` after their prefixes. The R69 decision hashes to `2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815`. The source line names `crates/web/Cargo.toml`, non-optional `axum` and `tokio`, `web = ["dep:rs-launch-blueprint-web"]`, and `crates/web/tests/`. The note beside the value cites that source at `DECISION.md:1037-1044`.
- `O3` uses the pinned R69 revision-11 line for `web-extra-surface` and the registry for the other six values (`check-offline.sh:98-159`); `O5` checks the pinned source line and treats the registry's earlier form as information (`check-offline.sh:179-201`). Both passed in the fresh log. `V6` reads line 1885 and passed (`check-standard-r4.sh:233-248`).
- The revision-7 title checks passed at `check-standard-r2.sh:285-288`, `check-standard-r3.sh:64-67`, and `check-standard-r4.sh:62-85`. The artifact digest checks `C1`, `R6`, and `V13` passed; `V1` also verified the revision-6 snapshot. The six-script ShellCheck run was empty and successful, matching `DECISION.md:39-45`.
- `V3` printed `migrations=2`, the first migration, then `KeyError: 'from'`; `V4` printed identical frozen and live prompt hashes of `584f099495ce31852dc7f29617c8dcc42e33b26450a5846464f23c011d3912d2` before failing. This reproduces the disclosed `12 PASS, 2 FAIL, 0 SKIP` at `DECISION.md:51-59` and `DECISION.md:1332-1335`. The `V3` reader and its one-migration expectation are at `check-standard-r4.sh:132-164`; `V4` depends on `V3`'s printed manifest hash at `check-standard-r4.sh:167-192`.

## Findings

1. **OBS — `V3` and `V4` fail on disclosed manifest drift.** The committed and fresh `check-standard-r4.log` assertion lines both record `FAIL V3`, `FAIL V4`, and `12 PASS, 2 FAIL, 0 SKIP`. Revision 7 explicitly quotes the second migration without `from`, the resulting `KeyError`, and `V4`'s dependence on the truncated `V3` output (`DECISION.md:51-59`). The frozen and live prompts remain byte-identical. This is a disclosed point-in-time drift observation under RUNBOOK §7.1 and §7.7, with no changed recommendation or load-bearing probe result.
2. **OBS — Raw logs contain reproducibility and live-counter differences outside assertions.** All eight fresh assertion sets match their committed logs. UTC stamps, temporary paths, Cargo target paths, and build timings explain the offline-log differences; the fresh live fetch changes moving counters. The decision discloses these classes and says fetch mode cannot reproduce byte-for-byte (`DECISION.md:1340-1410`).

There are zero BLOCKING findings. Under RUNBOOK §7.1, the verdict is `approve`.
