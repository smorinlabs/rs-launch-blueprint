decision-sha256: a3c225f8e1d188a3d85298c85d518f9bff9fabb2987f8db69718175dfd59d173
actor: audit-codex-2026-09-05T163616Z-1ab131aed82d-r1
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: decision-cited evidence log is not reproduced by the saved script after timestamp normalization

## Rerun

- argv: `bash run-checks.sh`
- cwd: `research/runs/R21/2026-09-05T163616Z-1ab131aed82d/review/empirical`
- toolchain: the rerun log records `rustc 1.98.0`, `cargo 1.98.0`, `git 2.50.1`, `curl 8.7.1`, and `python3 3.14.7` on macOS. `limactl` was callable, but its `ubuntu` instance was stopped, so this deterministic read-only rerun used macOS rather than starting the VM.
- exit code: `0`; the rerun reports `summary: PASS=27 FAIL=0` and `RESULT: PASS`.
- log path: `review/evidence/audit-contributors-bot-credential-source-r1.log`
- output match: no. Removing only the volatile `date:` line still leaves one difference from `review/evidence/contributors-bot-credential-source.log`: case 07 prints `GET /user/{account_id}` before the package endpoints in the cited log, but after them in the rerun. The script's sorted endpoint list therefore did not reproduce the cited complete output, even though all assertions pass.

## Findings

### R21-A01 — decision-cited empirical log is not reproducible

**Impact:** The decision's `## Empirical check` identifies `review/evidence/contributors-bot-credential-source.log` as the full output of `bash run-checks.sh`. The independently generated output is not that log after normalizing the timestamp. The cited artifact therefore cannot serve as a reproducible record of the command's output.

**Evidence:** The saved script is unchanged at SHA-256 `3b8fd8ab6beec0e745ce2252d81fb2ca82343fd2531a8caa90850171419c6cc3`. It exited `0` and produced 27 passes in the audit log. A normalized diff moves only `GET /user/{account_id}` within the case-07 endpoint enumeration; it is nevertheless an output difference. The cited log has SHA-256 `76f2a4d4c3915de5c950b1073523b230550234f417c2833600f304f70363c362`; the rerun log has SHA-256 `164988714f542cb36814a6253d3bcd4ec2aa092d1a0eafbe7ef1cf2d789af6c2`.

**Required correction:** Regenerate the evidence cited by the decision from the saved script and revise/re-sign the decision against that artifact. If the public documentation's rendered ordering is intentionally treated as volatile, preserve a stable source snapshot or a normalized comparison rule in the decision; do not identify a nonmatching historical output as the command's complete reproduced log.

### Verified, not a finding

- The decision's correction to the inherited baseline-review clause (3) is accurate. An independent unauthenticated retrieval of `https://docs.github.com/en/actions/concepts/security/github_token` today states that a `GITHUB_TOKEN`-created or updated pull request creates `pull_request` workflow runs in an approval-required state and that a user with write access starts them by selecting **Approve workflows to run**. The decision does not overstate this as "never report".
- The decision's correction to clause (4) is accurate. An independent unauthenticated retrieval of `https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository` scopes the restrictive default to a new repository in a personal account and says that a new organization repository inherits its organization setting.
- The four `- assumes` values in `review/DECISION.md:113-116` equal the values in `docs/port/PARAMETERS.md:7-10` byte-for-byte: `msrv-policy`, `rust-edition`, `target-os-matrix`, and `license`.
- The predicted `403` from bare `GET /user` remains correctly labelled `(Q1, predicted)`. The decision states that no credential, app registration or installation, pull request, or token-authenticated endpoint call was used, and it names the P03 observation that would prove the prediction. This is correct handling of an unproven claim.

## Assessment

The substantive recommendation is supported at the width of its evidence: the decision distinguishes documented behavior from an executed workflow, preserves the `403` as unproven, and accurately narrows both GitHub documentation claims. The 27 saved checks also pass in the independent rerun. Approval nevertheless requires a reproducible cited empirical artifact. R21-A01 requires a decision and evidence refresh before this revision can be accepted.
