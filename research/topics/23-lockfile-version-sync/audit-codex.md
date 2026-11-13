decision-sha256: ea269dd6ac3342672f48e69e6c2cb2645c7f73d1e476e5306a20803d1a6598ed
actor: audit-codex-2026-09-05T160304Z-11020e4e7e38
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

- argv: `bash run-checks.sh`, the decision-recorded empirical command.
- cwd: `/private/tmp/r23-empirical-audit.5TsSYV/empirical-audit`, a fresh copy of `review/empirical` placed outside the run directory because the task permits writing only this audit and its evidence log.
- toolchain: `rustc 1.98.0`, `cargo 1.98.0`, Rust 1.96.0 and 1.91.1 toolchains, Node v26.5.0, and release-please 17.11.2 on Darwin 25.4.0 arm64.
- exit code: 0. Complete output: `review/evidence/audit-lockfile-version-sync.log` (717 lines; sha256 `59c7e82910bac02cb2315a6e7741d8fd17316d96125a8a972e609b35883460fb`).
- output comparison: behavioral match. Both runs report `summary: PASS=77 FAIL=0 RECORD=5` and `RESULT: PASS`, use release-please 17.11.2, and pass the same S2 through S9 assertions. The rerun is not byte-identical: it contains 17 additional lines from a sandbox-denied `mise` config-tracking warning and fresh-build compiler output.

## Findings

No unresolved findings.

- The stale-lock control is discriminating: S2 makes `Cargo.toml` 0.2.0 while leaving `Cargo.lock` 0.1.0, and both `cargo build --locked` and `cargo metadata --locked` exit 101. S4 then applies the native Rust strategy, updates `Cargo.toml` and `Cargo.lock`, and `cargo build --locked` succeeds.
- The updater claim is reproduced, not inferred from startup: S4 reports `Cargo.toml, Cargo.lock` and `Cargo.lock: updated by CargoLock`. S5a shows the natural generic-TOML JSONPath warning without changing the lock, while S5b needs the tagged-AST `.name.value` path.
- The required Light-tier inputs are present and internally consistent: `raw/codex.md` (sha256 `28cdcb7372736eae1acedf0f3121ac6721606704c0c11e02d9bb16dc537b306d`) recommends the same native updater, and `raw/evidence-terra.md` (sha256 `9ff54558250b49d10cc7c7fe01bcc7d848608b26475e016027a30823ffadacdb`) returns `sound` with no defects.
- Six cited primary sources were spot-checked with `curl`: Cargo documents that `--locked` exits on a lockfile-changing operation and that workspace packages share the root `Cargo.lock`; release-please's Rust strategy schedules `CargoLock`, its updater replaces matching package versions, its manifest guide documents `cargo-workspace` lockfile updates, and release-please-action v5.0.0 declares `release-please` `^17.6.0`.

## Assessment

Approve. The evidence proves the decision's central principle: a committed root `Cargo.lock` is part of the release transaction, and release-please's native `release-type: rust` updater changes it with the manifest in the release update. The decision correctly rejects a redundant `Cargo.lock` `extra-files` writer and labels the unexecuted GitHub end-to-end and Linux checks as planned rather than completed.
