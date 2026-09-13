decision-sha256: 18769c3a522c94ee59c5635a338828781efa9c6bc8aa4e13ac9443a5773c5c2c
actor: audit-codex-2026-09-05T183002Z-09f93cfc507c-r2
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: revision-2 evidence scripts are not rerunnable after the revision is committed, contradicting the decision's byte-for-byte reproducibility claim

## Rerun

argv: `bash review/evidence/r60-standard-pin-r2.sh`; then `bash review/evidence/r60-preservation-diff-r2.sh`.
cwd: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R60/2026-09-05T183002Z-09f93cfc507c`.
toolchain: macOS. The supplied Linux command was attempted after `source $HOME/.cargo/env`, but the stopped `ubuntu` VM could not start because the sandbox denied Lima's unlink of `~/.lima/ubuntu/ha.stdout.log`; no Linux result is claimed.
exit code: standard-pin script `1`; preservation script `2`.
log path: `review/evidence/audit-cli-parsing-framework-r2.log`.
output match: no. Both scripts executed their deliberate negative controls correctly, and every substantive content check passed, but their lifecycle checks require revision 2 to remain an uncommitted worktree change. Revision 2 is now committed at `892954669e0073b2d9747a6e67068645f5cbf088`.

## Findings

1. Blocker — the decision claims at `review/DECISION.md:668-693` that both revision-2 logs are reproducible byte-for-byte. They are not reproducible from the published revision. `r60-standard-pin-r2.sh:190-193` requires `HEAD:.../DECISION.md` to equal the revision-1 blob `5ae06c37...`; current `HEAD` instead resolves that path to revision-2 blob `8c3c7c09...`, so C14a fails. `r60-preservation-diff-r2.sh:175-192` requires exactly six dirty paths and a dirty `DECISION.md`; both are false after the revision has been committed, so C5b/C5c fail. The script's C0 controls correctly prove the harness detects mismatches, so these are real failed checks rather than suppressed errors. Replace worktree-status assertions with comparisons between named revision-1 and revision-2 commits, then regenerate and rerun the evidence logs.

## Assessment

The repaired R1.3 content is otherwise correct at the pinned versions. The pin resolves version `1.4.14`, commit `fb30a591c267a7ec1130ba4cda679eaee494b9d7`, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, and SHA-256 `9fb05d3dfaa5ea11fbf66422e988b0ae8c050e22a39b9fc6dd9688734f02463f`; the cited blob lines contain the singular canonical noun, the undocumented/hidden-only plural allowance, and the help/docs prohibition. At `clap_builder 4.6.6`, `Command::alias` is documented as hidden from help and `Command::visible_alias` as visible. At `clap_derive 4.6.4`, a non-special `alias` attribute is rendered verbatim as `.alias("projects")`. AC9 asserts the three mandatory rule parts, and AC10 asserts the optional hidden-alias case. R67's decision body has no version, commit, blob, or content-hash pin; revision 1's corrected Decision Log lines are `:63`, `:65`, and `:69`, while `:70` is Exit codes. The preservation script's C2 independently found all 20 requested targets byte-identical, including the crate/features, lockfile/advisory rows, four `assumes` lines, and OV-01 argument. OV-01 remains requested, not granted, and R1.3 conformance is not filed as a second override.
