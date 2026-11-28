# P02 Closeout Verification Record (2026-11-27)

This record closes the remaining open tasks in [projects/P02-execute-research-program.md](../../../projects/P02-execute-research-program.md): `P02-T02` (R69 revision-11 atomic flag-day), `P02-T03` (`CONFLICT:` resolution), `P02-TS01` (empirical-check verification), `P02-TS02` (principle-to-design and `OV-nn` override audit), and offline regression test parity.

## 1. R69 Revision-11 Atomic Flag-Day (`P02-T02`)

Published R69 revision 11 (`2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815`, EF-1 evidence-only repair over owner-accepted revision 10 per `W1-R02` / `W0-R69c` / `Q3.A`) together with `docs/port/PARAMETERS.md` (`web-extra-surface` updated to `web = ["dep:rs-launch-blueprint-web"]`, `crates/web/src/`, `crates/web/tests/` without file-level `#![cfg(feature = "web")]`, `tower` 0.5.3 as `crates/web` dev-dependency, and `crates/web/**` skip-gating), all 12 `web-extra-surface` consumers, and all 21 indirect transitive prerequisite dependents (34 topics updated atomically).

### Published Decisions (13)

| Item | Rev | New `DECISION.md` SHA-256 | Synthesizer | Empirical Auditor | Judgment Auditor | Notes |
|---|---|---|---|---|---|---|
| R69 | 11 | `2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815` | `synth-opus-2026-09-12T204004Z-d02022bf6f42-r9` (carried EF-1) | `audit-codex-r69-r11-2026-09-27` (`gpt-6`, `openai`) | `audit-fable-r69-r11-2026-11-27` (`claude-opus-5-5`, `anthropic`) | Owner of `web-extra-surface`; `supersession-check-r11.log` staged; `OWNER-ACCEPTANCES.md` re-bound |
| R51 | 6 | `bbe83b8caba89078138ed6fc591bb7f1b25e463709cf14298ccfe6aa6e7b2465` | `synth-opus-2026-09-17T034010Z-8b2a46a3c21b-r5` | `codex` (`gpt-6`, `openai`) | `s1-controller` (`muse-spark`, `meta`) | Pre-audited run copy staged |
| R76 | 5 | `fd1647b8f46f66adb1817f6387f5b1a977cd58c76e32c319e839fe05deb84278` | `synth-opus-2026-09-17T034010Z-d958540e8834-r4` | `codex` (`gpt-6`, `openai`) | `s1-controller` (`muse-spark`, `meta`) | Pre-audited run copy staged |
| R77 | 6 | `dc17643915a6b915207154fa3d205712b5b242c4eea705a914809e60aa42aacc` | `synth-opus-2026-09-17T034011Z-5884fd6b6366-r5` | `codex` (`gpt-6`, `openai`) | `s1-controller` (`muse-spark`, `meta`) | Pre-audited run copy staged |
| R80 | 7 | `065dfba6cded1036b6c2a89acbc9ad71db0aa0dddcdb68a8e3a1da49b6ad1a85` | `synth-opus-2026-09-17T034011Z-74765d801b92-r6` | `codex` (`gpt-6`, `openai`) | `s1-controller` (`muse-spark`, `meta`) | Pre-audited run copy staged |
| R11 | 8 | `2018fcdb67d5e265b27ede87259bfb31fd67e0ded6d57a71ff206a1ab0c8e5e6` | `synth-claude-r11-r8-2026-11-27` (`claude-opus-5-5`) | `audit-claude-r11-r8-2026-11-27` (`claude-opus-5-5`, `anthropic` per override) | `audit-fable-r11-r8-2026-11-27` (`claude-opus-5-5`, `anthropic`) | `- owns ci-job-structure` byte-identical; notes R32 slot fill |
| R32 | 3 | `f85670a92cee8bc9777198cb4f6032cfe06460dba8e81df821c3b61a0fe740b9` | `synth-claude-r32-r3b-2026-11-27` (`claude-opus-5-5`) | `audit-codex-r32-r3b-2026-11-27` (`gpt-6-sol`, `openai`) | `audit-fable-r32-r3b-2026-11-27` (`claude-opus-5-5`, `anthropic`) | Discharges `CONFLICT: R11`; repairs Codex F1 (`--workspace --features web`, `crates/web/tests/web/main.rs`) backed by executed probe `evidence/2026-11-27-r32-r3-workspace-probe.log` |
| R37 | 5 | `b224198fb3f430a577aad5de13ba8657719a71c02499f0b4a5a57b91eb9f1775` | `synth-claude-r37-r5-2026-11-27` (`claude-opus-5-5`) | `audit-codex-r37-r5-2026-11-27` (`gpt-6-sol`, `openai`) | `audit-fable-r37-r5-2026-11-27` (`claude-opus-5-5`, `anthropic`) | Pure flag-day sync; no effect on lefthook wiring |
| R58 | 3 | `e88caffbb011db651b40a50c066e5e8a67d155a34fd2253b4c02c9058bedeb91` | `synth-claude-r58-r3-2026-11-27` (`claude-opus-5-5`) | `audit-codex-r58-r3-2026-11-27` (`gpt-6-sol`, `openai`) | `audit-fable-r58-r3-2026-11-27` (`claude-opus-5-5`, `anthropic`) | `- owns logging-pipeline-contract` byte-identical; matches existing `crates/web` design |
| R71 | 4 | `30d9f60c0091cfba6bccf356000e19e36ba2e572d0a437170eb1f7859e73a00a` | `synth-claude-r71-r4b-2026-11-27` (`claude-opus-5-5`) | `audit-codex-r71-r4b-2026-11-27` (`gpt-6-sol`, `openai`) | `audit-fable-r71-r4b-2026-11-27` (`claude-opus-5-5`, `anthropic`) | Discharges `CONFLICT: R69`; repairs Claude JF-1 (`crates/web/tests/openapi.rs`, `CARGO_MANIFEST_DIR` `SNAPSHOT`, `--workspace` regen, A13 scoped per R11) backed by executed probe `evidence/2026-11-27-r71-r4-workspace-probe.log` |
| R82 | 3 | `7b6fc03573bcf790ce5dc38faf5df92d589067433ae2350d13a2eb0ec94d31a0` | `synth-claude-r82-r3-2026-11-27` (`claude-opus-5-5`) | `audit-codex-r82-r3-2026-11-27` (`gpt-6-sol`, `openai`) | `audit-fable-r82-r3-2026-11-27` (`claude-opus-5-5`, `anthropic`) | Pure flag-day sync; `--all-features` rustdoc gate unchanged |
| R83 | 6 | `2a7101ed1cd59c707c04234b4e6dc6006c31b51fc982b84648798e0ca5fb5654` | `synth-claude-r83-r6-2026-11-27` (`claude-opus-5-5`) | `audit-codex-r83-r6-2026-11-27` (`gpt-6-sol`, `openai`) | `audit-fable-r83-r6-2026-11-27` (`claude-opus-5-5`, `anthropic`) | Pure flag-day sync + `acceptance_after.R71` re-bound to R71 r4 |
| R84 | 6 | `039ef6db8b54659991c50eae1ff473c3ece5674cdf13e7a276212c8b545ac2c3` | `synth-claude-r84-r6-2026-11-27` (`claude-opus-5-5`) | `audit-codex-r84-r6-2026-11-27` (`gpt-6-sol`, `openai`) | `audit-fable-r84-r6-2026-11-27` (`claude-opus-5-5`, `anthropic`) | Pure flag-day sync + `acceptance_after.R71` re-bound to R71 r4 |

### Transitive Prerequisite-Hash Updates (`acceptance.json` only, 21 items)

- `prerequisites.research.R69` updated (`7`): `R70`, `R72`, `R73`, `R74`, `R75`, `R78`, `R79`.
- `prerequisites.research.R11` updated (`13`): `R08`, `R09`, `R12`, `R13`, `R14`, `R27`, `R28`, `R29`, `R30`, `R31`, `R35`, `R39`, `R40`.
- `prerequisites.research.R58` updated (`3`, overlapping `R75`/`R78`): `R59`, `R75`, `R78`.

Post-flag-day checks:
- `bash scripts/check-research-tree.sh --require-owner-review` → `OK: research tree structure valid` (exit 0).
- `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_scan.py --todo` → `summary: done 85` (0 `REOPENED`).

## 2. `CONFLICT:` Resolution Ledger (`P02-T03`)

Every `CONFLICT:` line across all 85 published `DECISION.md` files is accounted for and discharged:

| Source Item | Target Parameter | Disposition | Evidence / Authority |
|---|---|---|---|
| `R02` | `R69 web-extra-surface` | **Discharged** | Owner rulings `W1-R02` (option 1) + `W0-R69c`; `R02` carries `**RESOLVED` paragraph; discharged on 2026-11-27 publication of R69 r11 into `docs/port/PARAMETERS.md`. |
| `R71` | `R69 web-extra-surface` | **Discharged** | Preserved verbatim in `R71` r4 with `**RESOLVED (2026-11-27)**`: under R69 r11 (`web = ["dep:rs-launch-blueprint-web"]`), `utoipa` 6.0.0 and `utoipa-axum` 0.3.0 are non-optional dependencies of `crates/web/Cargo.toml` per clause (4) (matching `execution-ledger.md` S81/S84 and owner-approved `2026-11-27-rs-implementation-roadmap-design.md` Area 9 / `P09`); no widening of the root feature array is needed and feature-off builds carry zero `utoipa` crates. |
| `R32` | `R11 ci-job-structure` | **Discharged** | Preserved verbatim in `R32` r3 with `**RESOLVED (2026-11-27)**`: ruled an R11 slot fill per R11's delegated R32 slot row (`R11 DECISION.md:282`) and owner-approved `2026-11-27-rs-implementation-roadmap-design.md` (Area 8 / `P07` / `P10`), running `cargo nextest run --locked --profile ci` (feature-off `-p` scoped + feature-on workspace), `cargo test --doc --locked --workspace --features web`, and R42-provisioned `cargo-nextest` as ordered steps inside `check` under `!cancelled()` sharing `check`'s `target/` (0 new jobs, 0 new cache-bearing job ids); `R11`'s registered `ci-job-structure` stays unchanged and `R11` r8 records the slot fill. |
| `R01` | `R05` (Codex raw only) | **Already disposed (non-conflict)** | Disposed inside published `R01`: R05 owns no registered parameter and resolved synchronous. |
| `R53`/`R55` | `R67 error-taxonomy-exit-codes` (Codex raw only) | **Already disposed (non-conflict)** | Disposed inside published `R55`: settled for Opus; no registry value change. |
| `R67` | `R57 state-directory` (Doxa raw only) | **Already disposed (non-conflict)** | Disposed inside published `R67`: R57 owns no parameter and published `Paths::state_dir()`. |
| `R72` | `R69 web-framework-stack` (Doxa raw only) | **Already disposed (non-conflict)** | Disposed inside published `R72`: malformed parameter name, already satisfied, void. |

## 3. Empirical-Check Verification (`P02-TS01`)

Programmatic audit across all 85 published topics (post-flag-day):
- **85 / 85** published `DECISION.md` files contain a non-empty `## Empirical check` section in the current entry (above `## Supersedes`).
- **85 / 85** `acceptance.json` records have `empirical.exit_code == 0`, non-empty `argv`, `cwd`, and `toolchain`, an existing committed `evidence/*.log` file (minimum log size 692 bytes, `R46`) whose SHA-256 equals `empirical.output_sha256`, and an approving empirical audit (`audit-codex.md` or `audit-claude.md` per `empirical_auditor_overrides`) whose identity equals `empirical.executed_by`.
- **Honest environment bounds:** Items whose verification requires unavailable host resources (GitHub-hosted Linux runners, Docker daemon in R51 reruns, `oasdiff` binary not on PATH in R71 while R71's other 7 scripts and the rev-4 workspace probe ran and passed, and `cargo-nextest` in R32's rev-3 Cargo 1.100.1 workspace-selection probe) disclose those exact boundaries in `## Empirical check` and carry concrete downstream acceptance criteria into `P04`–`P13`, per `research/RUNBOOK.md` §5.

## 4. Principle-to-Design & Override Audit (`P02-TS02`)

Programmatic and manual audit across all 85 published topics (post-flag-day):
- **85 / 85** published `DECISION.md` files contain a non-empty `### Principles and implementation` section mapping principles and agreement levels to native Rust mechanisms, mirrored in `acceptance.json["principles"]`, and backed by an approving `audit-fable.md` with `unresolved-findings: none`.
- **COMMONALITY.md ledger reversals owed:** **0**. `docs/port/COMMONALITY.md` contains **0** rows with verdict `COMMON → OVERRIDE (OV-nn)` (its sole text mention of `OVERRIDE` is line 242 `F238`, a `DIVERGENT` row explaining why `OVERRIDE` is illegal for `py-only` origin). Consequently, no raw report carries `### Override justified`, and zero ledger reversals are required.
- **Charter / standard `OV-01`..`OV-17` audit (all 17 allocated numbers accounted for):**

| ID | Item | Status | Verification Summary |
|---|---|---|---|
| `OV-01` | R60 | **Retired / refused** | Refused by owner ruling 2026-09-14 (`OWNER-ACCEPTANCES.md` R60 row); `clap` 4.6.6 derive adopted without override. |
| `OV-02` | R61 | **Active — verified** | Owner-accepted (`OWNER-ACCEPTANCES.md`, `W1-R61`); declined confirm exits 0 instead of 5; argument & options present; adopted in 2026-11-27 roadmap (`P07`). |
| `OV-03` | R02 | **Active — verified** | Owner-accepted (`W1-R02`, `OWNER-REVIEW.md`); 4-package Cargo workspace against F021; argument & options present; adopted in 2026-11-27 roadmap (`P04`). |
| `OV-04` | R77 | **Active — verified** | `std::env` `RSLBP_WEB_*` settings; argument & options present; adopted in 2026-11-27 roadmap (`P08`). |
| `OV-05` | R80 | **Active — verified** | `/healthz` + `/readyz` probe envelope; argument & options present; adopted in 2026-11-27 roadmap (`P08`). |
| `OV-06` | R70 | **Returned unused** | Declared unused in R70 (RFC 9457 satisfied without override). |
| `OV-07` | R79 | **Active — verified** | Prometheus `/metrics` format/stack override; argument & options present; adopted in 2026-11-27 roadmap (`P09`). |
| `OV-08` | R76 | **Active — verified** | CORS middleware deviation; argument & options present; adopted in 2026-11-27 roadmap (`P08`). |
| `OV-09` | R58 | **Active — verified** | Residual redaction gap against CLI Design Standard R5.6 (key-based masking + `SecretString`, non-sensitive field value unmasked); argument & options present; adopted in 2026-11-27 roadmap (`P06`). |
| `OV-10` | R72 | **Returned unused** | Declared unused in R72 (cursor pagination conforms to REST standard). |
| `OV-11` | R84 | **Active — verified** | `openapi-to-rust` 0.17.0 typed client generation; argument & options present; adopted in 2026-11-27 roadmap (`P09`). |
| `OV-12` | R84 | **Returned unused** | Unused second slot returned by R84. |
| `OV-13` | R50 | **Active — verified** | Install smoke test deviation (argument & options verified in R50 `DECISION.md`). |
| `OV-14` | R51 | **Active — verified** | Container image / GHCR publication deviation (note: 2026-11-27 roadmap Area 9 also records the owner's `1a-A` override adding GHCR `publish-container.yml` in `P09`/`P11`). |
| `OV-15` | R83 | **Returned unused** | Declared unused in R83. |
| `OV-16` | R73 | **Active — verified** | Idempotency store deviation (argument & options verified in R73 `DECISION.md`). |
| `OV-17` | R74 | **Active — verified** | Owned rate limiter deviation (argument & options verified in R74 `DECISION.md`). |

## 5. Regression Test Status

Fixed stale live-repo assumptions in `scripts/test-research-runner.py` (`reset_to_open()` helper resetting `R38` and transitive dependents inside temporary copies only) and `scripts/test-research-package.py` (resetting `R38`, `R22`, `R72`, `R49` and clearing synthetic auditor overrides in temporary copies only). All shell and Python regression suites pass cleanly without mutating committed research files.
