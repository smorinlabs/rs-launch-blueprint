decision-sha256: 9275faef261e14e012d18e1bbc568ee9bac4713207e01ac7a7da2a6e812227ce
actor: audit-codex-2026-09-05T164358Z-eae89906c763-r1
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: strict license fallback is not all-dependencies-dual; saved empirical check does not reproduce all cited checks

## Rerun

- argv: `bash review/empirical/r33-checks.sh`; cwd: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R33/2026-09-05T164358Z-eae89906c763`; toolchain: `rustc 1.98.0`, `cargo 1.98.0`, macOS arm64; exit code: `0`; complete output: `review/evidence/audit-property-and-snapshot-testing-r1.log`.
- I also ran the same saved script from the decision's declared repository cwd, with argv `bash research/runs/R33/2026-09-05T164358Z-eae89906c763/review/empirical/r33-checks.sh`; exit code: `0`. That makes check 12's relative ledger paths work, but does not repair check 11.
- The rerun does not fully match the cited evidence log. The saved script ends after check 12. It does not contain the recorded follow-ups 9b, 11b, or 13. Check 11 still queries `TS_PORT_DECISIONS.md` at the TypeScript repository root, which does not exist at the pin; the correct path is `docs/port/TS_PORT_DECISIONS.md`. The run-directory invocation also cannot find the repository-relative `docs/port/` files in check 12. The script exits zero because it does not enable `set -e` or `pipefail`.
- Linux rerun: `limactl` was callable, but its stopped `ubuntu` instance could not start from this sandbox: Lima was denied permission to unlink `/Users/stevemorin/.lima/ubuntu/ha.stdout.log`. The macOS reruns are complete in the evidence log.
- Direct citation spot checks returned HTTP 200 for the crates.io records for `insta` 1.48.0, `cargo-insta` 1.48.0, and `snapbox` 1.2.2; `https://insta.rs/docs/quickstart/`; and the cited Clap `StyledStr` documentation.

## Findings

### 1. Strict branch: `snapbox` is not an all-dependencies-dual substitute

`review/DECISION.md:35-41` says that, under a strict rule requiring every dependency at every depth to carry the dual expression, `snapbox` 1.2.2 replaces `insta`. That claim is false under the rule it states. The published `snapbox` 1.2.2 manifest has an unconditional `[dependencies.normalize-line-endings] version = "0.3.0"` entry. Both `GET https://crates.io/api/v1/crates/normalize-line-endings/0.3.0` and its published `Cargo.toml` report `Apache-2.0`, not `MIT OR Apache-2.0`.

This is independent of the unresolved R42 question. R42 does leave the separate-process developer-tool ruling open: its published decision says no owner ruling exists. The decision is also right that `insta` 1.48.0 and `cargo-insta` 1.48.0 are each Apache-2.0-only: the two crates.io records and each published package manifest agree. However, the decision promises a result under the strict branch and names `snapbox` as the clean result without checking its required dependency tree. The strict branch therefore has no proven snapshot stack. Revise it to leave that branch unresolved pending a resolved-tree licence audit, or select and prove a substitute that passes the stated rule.

### 2. The saved empirical check is not sufficient to reproduce the cited log

`review/DECISION.md:154` calls `bash review/empirical/r33-checks.sh` the re-runnable check and attributes checks 1 through 13 to its evidence log. `review/empirical/r33-checks.sh:114-131` proves the saved script only emits checks 1 through 12. It neither records nor invokes follow-ups 9b, 11b, and 13. Its check 11 has the wrong TypeScript path, so it cannot itself substantiate the claimed silence of `docs/port/TS_PORT_DECISIONS.md`; its printed `grep exit=0` is the successful `head` pipeline status after `git show` fails.

The corrected direct check at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` confirms the underlying TypeScript facts: `package.json` has Vitest and no `fast-check`; `pnpm-lock.yaml` resolves `@vitest/snapshot@4.1.10`; the capability-use search returns exit 1; and the correct `docs/port/TS_PORT_DECISIONS.md` has no matching rationale. Thus the decision's bounded conclusion, “portable, unadopted, unexplained,” is supported; “accidental” remains correctly labelled as an inference. The defect is reproducibility of the cited empirical check, not this conclusion.

## Assessment

The four `assumes` values byte-match `docs/port/PARAMETERS.md`: `msrv-policy`, `rust-edition`, `target-os-matrix`, and `license`. The decision also correctly records the dependency-tree MSRV floor as unproven and names a resolved-lockfile test that would prove it; that is not a finding.

Reject until the strict licence branch is made true or explicitly left unproven, and the saved empirical check is made capable of reproducing every cited check with failing subcommands propagated as failures.
