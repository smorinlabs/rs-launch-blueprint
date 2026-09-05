decision-sha256: 3d313fbbabef1d10ff549861d583cb25dddf82f726b58d13f47aa48eb34fe419
actor: audit-codex-2026-09-05T151356Z-c46d732f98ed
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: F156 whole-commit bot exemption permits invalid commit types and contradicts the stated every-commit contract; the accepted >=1.1.11, <2.0.0 range conflicts with the exact 1.1.11 installation and CI pins and has no upgrade acceptance gate

## Rerun

- argv: `bash run-checks.sh`
- cwd: `review/empirical-audit`, a fresh copy of the recorded fixture whose copied `tools/` cache was deleted before the rerun.
- toolchain: `rustc 1.98.0`, `cargo 1.98.0`, `git 2.50.1`, macOS 26.4 on arm64.
- exit code: 0.
- log path: `review/evidence/audit-commit-message-linter.log`.
- output matches the decision's recorded result: yes. The forced provisioning installed `committed 1.1.11`; the runner reported `PASS=32 FAIL=0 RECORD=4` and `RESULT: PASS`.

## Findings

1. **Contract-breaking bot exception — decision change required.** `review/DECISION.md:27-29` says every commit that lands must meet one Conventional-Commits contract, including the declared type vocabulary. The selected `ignore_author_re = "(dependabot|renovate)"` does not relax only line widths. It skips every validation for matching authors. The decision itself records the implementation behavior at `review/DECISION.md:153`, and the rerun proves it with R3: a `dependabot[bot]` commit whose type is `wibble` exits 0. This is wider than the py precedent in `inputs/prompt.md`, which disables only the body and footer length rules for Dependabot. The decision must either remove the whole-commit exemption or specify and validate a bot path that continues to enforce grammar and the eleven-type enum while relaxing only the intended length checks.

2. **Version policy is internally inconsistent — decision change required.** `review/DECISION.md:7,13` calls `>=1.1.11, <2.0.0` an accepted range. However, `review/DECISION.md:146` requires the locally resolved binary to be exactly `1.1.11`, while the CI action is pinned to the v1.1.11 commit at `:21,110`. The empirical run exercises only 1.1.11 and the decision treats any later release as a re-verification trigger (`:166`). The record therefore has no executable acceptance condition for a 1.x upgrade. Set the accepted version to `=1.1.11`, or define the validation and pin-update procedure that makes a later 1.x release acceptable.

3. **Citation spot-check result.** Five cited upstream endpoints were checked with `curl`: the v1.1.11 package manifest, three tagged operational files (`.github/workflows/ci.yml`, `.pre-commit-hooks.yaml`, and `action/entrypoint.sh`), and the annotated tag object. They support the declared package version, three-OS matrix, hook arguments, action download behavior, and SHA pin. The crates.io endpoint returned HTTP 403 from this environment, so its figures were not independently refreshed. The RustSec page returned HTTP 404, matching the decision's recorded uncertainty rather than proving absence of advisories.

## Assessment

The fresh rerun demonstrates that `committed` 1.1.11 enforces the fixture's human-authored type, subject, body/footer, hook-bypass, and configuration-drift cases. It does not establish the decision's stronger claim that every landed commit obeys the same convention, because the intended CI bot path explicitly accepts a bad type. The broad version range is also not a pin that the documented hook and CI paths can execute. Resolve both findings before accepting this revision; the pending Doxa report remains separately disclosed under `## Engines`.
