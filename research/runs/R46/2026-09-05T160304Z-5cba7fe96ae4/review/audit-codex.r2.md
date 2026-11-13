decision-sha256: 1876815914f38dff33fa096348c8e2f5088b949ad8360a0c2947934d9088bfcd
actor: audit-codex-2026-09-05T160304Z-5cba7fe96ae4-r2
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: F1: the operational acceptance sequence does not verify every workspace package resolves license = MIT OR Apache-2.0

## Rerun

I ran the recorded Ubuntu-stable invocation from `review/empirical`: `limactl shell ubuntu -- bash -lc 'cd /Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R46/2026-09-05T160304Z-5cba7fe96ae4/review/empirical && R46_WORK=/tmp/r46-audit-codex-20260908-r2 bash run-checks-v2.sh'`. The VM reported Ubuntu on aarch64, Rust/Cargo 1.98.1, GNU Awk 5.3.2, Bash 5.2.37, and jq 1.8.1. The runner exited 0, with `summary: PASS=77 FAIL=0` and `RESULT: PASS`; that output matches the decision's recorded revision-2 result. The complete rerun, inverse controls, and five curl citation spot checks are in [audit-per-file-license-header-r2.log](evidence/audit-per-file-license-header-r2.log).

## Findings

### F1 — `acceptance-v2.sh` does not enforce the all-package Cargo-metadata invariant

`review/DECISION.md:7` requires every member to inherit or directly declare `license = "MIT OR Apache-2.0"`, and `:47` states that every workspace package resolves that value. The recommended operational sequence in `review/empirical/acceptance-v2.sh:8-9` checks only the root `Cargo.toml` line, then discards `cargo metadata` output. The all-package `jq` predicate exists only in the empirical runner's S5 fixture test (`review/empirical/run-checks-v2.sh:157-160`); it is absent from the acceptance sequence that the decision tells the implementation to adopt.

The evidence log's successful inverse control copied the fixture, changed only `crates/r46-web/Cargo.toml` to `license = "GPL-3.0-only"` and the fixture assertion to that same value, while leaving the root manifest at `MIT OR Apache-2.0`. `acceptance-v2.sh` exited 0 and `cargo metadata` reported `r46-web license=GPL-3.0-only`. The source-header controls, tests, and packaging therefore do not independently establish the required metadata invariant.

Add an all-package metadata assertion to `acceptance-v2.sh`, for example `cargo metadata --no-deps --format-version 1 | jq -e '[.packages | length > 0 and all(.license == "MIT OR Apache-2.0")] | all' >/dev/null`, and add a whole-sequence inverse control for a divergent member manifest. Re-run that control before acceptance.

The five citation spot checks succeeded: Cargo's manifest reference and the Rust API Guidelines contained the dual expression; SPDX Learn contained `SPDX-License-Identifier`; the REUSE specification contained `SPDX-FileCopyrightText`; and Apache's license text contained its terms heading. Those citations support the narrow syntax and convention claims, but they do not repair F1.

## Assessment

Revision 2 repairs revision 1's header-detector mismatch: the full Linux fixture now rejects the prior counterexamples, and the stated leading-comment contract matches the checker. However, the decision makes the package-wide manifest expression an essential behavior while its adopted acceptance sequence does not verify it. The decision must add that invariant and its inverse control before acceptance.
