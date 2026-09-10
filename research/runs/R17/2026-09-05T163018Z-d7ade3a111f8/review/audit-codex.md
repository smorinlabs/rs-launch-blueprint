decision-sha256: 6c0a240e6d12b8858422031921612d790735ced3305e8ea16038547dc0666033
actor: audit-codex-2026-09-05T163018Z-d7ade3a111f8-r1
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: F1: the recorded provenance assertion 07a does not rerun; gh attestation verify exits 1 because no valid Sigstore verifier can be initialized

## Rerun

I copied `review/empirical/run-checks.sh`, the recorded check script, byte-for-byte to `/private/tmp/r17-audit-r1-clean.*/run-checks.sh` (SHA-256 `bb9e1d4a40e12f34c106a44d6e7f5cdf02fe4b1825f048226d96297b618b9e18`) and ran that copy without edits from `/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R17/2026-09-05T163018Z-d7ade3a111f8`.

argv: `/private/tmp/r17-audit-r1-clean.*/run-checks.sh`
cwd: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R17/2026-09-05T163018Z-d7ade3a111f8`
toolchain: macOS arm64; `rustc 1.98.0`; `cargo 1.98.0`; `gh 2.98.0`; `curl 8.7.1`
exit code: `1`
log path: `review/evidence/audit-secret-scanning-ci-workflow-r1.log`
output matches the decision: no. The script emitted all 23 checks that the decision attributes to it, but its summary is `PASS=22 FAIL=1`, not the recorded `PASS=23 FAIL=0`.

The requested Linux VM path was attempted first. `/opt/homebrew/bin/limactl` was callable, but `limactl start ubuntu` failed before a guest command could run because the host sandbox denied unlinking Lima's `ha.stdout.log`. The macOS rerun above is therefore the only completed rerun.

## Findings

### F1 — reject: the provenance claim is wider than the current rerun supports

Evidence: assertion `07a-slsa-provenance-verifies` in the audit log records `expected=0 actual=1`. The independently repeated `gh attestation verify` invocation also exited `1` and reported that no valid Sigstore verifier could be initialized. The release archive still has the digest recorded by the decision, and assertion `07b` confirms that the binary runs, but neither fact proves the decision's claim that `gh attestation verify` passes.

Impact: Part 2 says P03 must verify the downloaded release's provenance. `review/DECISION.md` presents that as executed evidence in its decision, empirical-check table, packaging comparison, and P03 test list. The recorded check no longer establishes the required install-gate behavior.

Required correction: revise the decision to mark this provenance result unproven until the exact verifier failure is resolved and a clean rerun passes, or record the environment prerequisite and an independently reproducible successful verifier command. Do not retain an executed-pass claim based on the previous log.

### Confirmed — the equal-base-and-head finding is correctly narrowed

At TruffleHog Action tag `v3.95.9`, the rerun reproduces the guard and its enclosing condition: the guard compares equal base and head values, while the enclosing branch runs only when either supplied value is non-empty. The action's alternative branch derives its range from the event. The evidence therefore supports the decision's narrow conclusion: the guard is about a supplied range, not an inherent requirement for a diff/full split. The saved script also executes Kingfisher full-history scanning without `--since-commit`; it finds the deleted fixture blob and exits `200` in assertions `09a` and `09b`. This does not execute a TruffleHog full-history workflow, but it is sufficient for the stated action-control-flow conclusion at the named tag.

### Confirmed — the verified-only gate rule is reproduced

Assertions `08a` through `08d` pass. With a non-live fixture, `--only-valid` produces a JSON `findings` array of length `0`, while the process exits `200` and the human-readable summary retains one pre-filter finding. The decision's rule to test exit `205` specifically or the JSON findings array, and never merely a non-zero exit or the pretty summary, follows from the executed result.

### Confirmed — the live-credential exit code is deliberately unproven

The script's section 10 states that exit `205` was not exercised because doing so requires a genuinely live credential. The decision marks the same claim as proposed rather than executed and assigns the check to P03. This is correct for a research-phase decision.

### Confirmed — parameter and log safety checks

The four `assumes` values in `review/DECISION.md` match `inputs/PARAMETERS.md` byte-for-byte: `msrv-policy`, `rust-edition`, `target-os-matrix`, and `license`. There are no extra assumed parameters. The generated audit log contains zero matches for four value-bearing credential patterns: GitHub-token, AWS-access-key, Slack-token, and long assigned secret-value forms. No secret-shaped value was added during this audit.

### Citation spot checks

Six cited endpoints returned HTTP `200` during curl checks: the TruffleHog Action definition at `v3.95.9`; Kingfisher `v2.2.0` usage documentation; Kingfisher `v2.2.0` manifest; Kingfisher's `v2.2.0` release endpoint; the Kingfisher repository endpoint; and the GitHub Actions runner issue cited for the macOS container-runtime constraint. The GitHub Docs secret-scanning page timed out from this environment, so this audit does not treat that one fetch as refreshed evidence.

## Assessment

Reject revision 1 until F1 is corrected. The decision correctly narrows the TruffleHog range guard, correctly derives the Kingfisher gate rule from the executed non-live fixture, correctly keeps the live-credential check unproven, preserves the shared parameters exactly, and keeps the audit log free of secret-shaped values. However, the decision claims a successful provenance verification that its own saved script now fails to reproduce. That discrepancy is material because the selected installation path requires that verification.
