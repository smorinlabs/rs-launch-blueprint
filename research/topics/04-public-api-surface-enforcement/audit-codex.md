decision-sha256: 0d4f2e60e994439d9261f5169c3fd28e5e76077dacd089d999a51fb67a5f6c5d
actor: audit-codex-2026-09-05T162359Z-3c50443de1e8
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

I copied the recorded fixture to a fresh temporary `review/empirical-audit/` directory, ran the decision's three commands from that directory, saved their complete combined output to `review/evidence/audit-public-api-surface-enforcement.log`, then removed the temporary fixture. The source fixture and decision were not edited.

| Leg | argv | cwd | toolchain | exit | Result |
|---|---|---|---|---:|---|
| macOS stable | `bash run-checks.sh` | fresh `review/empirical-audit/` | rustc 1.98.0; cargo 1.98.0; bundled `cargo-semver-checks 0.50.0` | 0 | `PASS=11 FAIL=0` |
| macOS MSRV | `TOOLCHAIN=1.96.0 RUN_TOOLS=0 WORK_DIR=/private/tmp/r04-audit-msrv-work CARGO_TARGET_DIR=/private/tmp/r04-audit-msrv-target bash run-checks.sh` | fresh `review/empirical-audit/` | rustc 1.96.0; cargo 1.96.0 | 0 | `PASS=8 FAIL=0` |
| Linux stable | `limactl shell ubuntu -- bash -lc 'cd <fresh fixture> && WORK_DIR=/tmp/r04-audit-work CARGO_TARGET_DIR=/tmp/r04-audit-target bash run-checks.sh'` | Lima `ubuntu`, fresh mounted fixture | rustc 1.98.1; cargo 1.98.1; bundled `cargo-semver-checks 0.50.0` | 0 | `PASS=11 FAIL=0` |

The observed outputs match the decision's empirical-check table: cases 01--11 passed on both stable legs, cases 01--08 passed on the MSRV leg, and all three aggregate exits were zero. The complete evidence is [`audit-public-api-surface-enforcement.log`](evidence/audit-public-api-surface-enforcement.log).

## Findings

1. No decision-changing finding. The rerun directly proves the recommended reachability and lint claims: a downstream deep import failed with `E0603` (case 03); unreachable `pub` failed under the explicit deny lint and succeeded without it (cases 04--05); a crate-private type in a public signature failed (case 06); and `#[doc(hidden)]` plus `#[macro_export]` remained reachable (case 08). These are discriminating positive and inverse controls, not merely a successful import.
2. The stable-lane gate executes with the claimed pinned binary version on both OSes. Removing `Widget::id` produced `inherent_method_missing` and exit 100 (case 09); adding a method passed with exit 0 (case 10). The decision accurately records the latter as the accepted residual addition-detection gap rather than claiming full surface snapshots.
3. The `publish = false` topology warning is supported: case 11 failed to prepare the public package because `rs_publish_demo_internal` was not found in the crates.io index. It is correctly limited to an internal member in a published crate's dependency graph.
4. I spot-checked six cited sources with `curl` on 2026-09-05. The Rust Reference states the public-ancestor-module rule; the allowed-lint list contains `unreachable_pub` and `missing_docs`; the warn-lint list contains `private_interfaces` and `private_bounds`; the action metadata exposes `rust-toolchain`, `baseline-rev`, `baseline-root`, `feature-group`, and `features`; the `cargo-public-api` README requires a recent installed nightly for rustdoc JSON; and the cited `cargo-semver-checks` source sets `RUSTC_BOOTSTRAP=1`. These checks support the stated gates and configuration. The GitHub release-asset API returned HTTP 403 during an additional unauthenticated check, but the executed binaries independently reported `cargo-semver-checks 0.50.0`.

## Assessment

The decision does not overclaim its empirical evidence. Rust visibility plus the denied lints establishes the non-bypassable private-module boundary for normal external consumers, while the doctests and separate consumer check exercise that boundary. `cargo-semver-checks` is appropriately described as a stable breaking-change gate, not an addition detector, and the nightly-dependent `cargo-public-api` remains a conditional runner-up. The proposed GitHub Actions job is explicitly planned rather than represented as executed. Approve.
