decision-sha256: 3881eea70d59953cebd03ce150ea34e1d252580165da71a0531ab8d60dba3276
actor: audit-codex-2026-09-05T164358Z-eae89906c763-r4
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: empirical-check provenance is stale: the active decision identifies a different script, log, check roster, line count, and assertion count than the cited current files

## Rerun

- argv: `bash review/empirical/r33-checks.sh`
- cwd: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R33/2026-09-05T164358Z-eae89906c763`
- toolchain: local `rustc`/`cargo` reported by the rerun in its check 1; the check also fetched the current stable-channel manifest.
- exit code: `0`
- log path: `review/evidence/audit-property-and-snapshot-testing-r4.log`
- output matches the decision: **no**. The rerun has no failing `STATUS` or `ASSERT` record, and its ratio check 4b recomputes the documented moved/held result. However, the active decision's `## Empirical check` describes a script and saved log that are not the current cited files.

The saved-log comparator exited `1`. `review/evidence/audit-r4-rerun-vs-saved.diff` contains only the twelve `grep -n` line-number changes from `mitsuhiko/insta`'s live `tests.yml` in check 6. Both runs kept the asserted OS-matrix content and ended `failed assertions: 0`; this is the decision's documented tier-2 upstream drift, not an unresolved finding.

## Findings

1. **Active empirical provenance is false.** `review/DECISION.md:427` says the evidence came from script sha256 `4c868c76a7c9f3b364abc8f5c0d98268ed6b99d86c1091eabb9d12253e5ffcc7`, saved-log sha256 `33c4358489d43edf46b30e37f7a8f5ff465f99f22ea3058e99604d6d40115f6b`, sections 1 through 14, 583 lines, and 186 successful assertions. The cited current script is sha256 `3d5ebc79bcc5be2de78ac1c40346181da9f0b3268cb742c05ad692cb546a5433`; it contains check 4b and no check 14. The cited saved log is sha256 `286889981a60ab12e6d32d2681cc2f6581868b7fbc6e40efedb0de1e764504ac`, has 623 lines, and has 213 successful `STATUS`/`ASSERT` records. The checks were made with absolute-path `/usr/bin/grep`. Revision 4 must update the active `## Empirical check` identity, roster, and derived facts to describe the files it cites; otherwise it claims evidence its recorded command did not produce.

## Assessment

The requested ratio repair is sound: check 4b derives all twelve dated values from the two committed figure files and reports three ratios moved and three held at one decimal place. The active selection remains `proptest` 1.11.0, `insta` 1.48.0, and `cargo-insta` 1.48; the four active assumed-value payloads match the corresponding fixed values in `docs/port/PARAMETERS.md`. Gate 1 is correctly `inapplicable` under Q7.B and is not a finding. The fenced supersedes payload hashes to `1bf96b43e0198e07bccca2ca4ecf0d5a6a2afb939260d896b8eca4814757a068` and diffs cleanly against the published revision 2. Five independent `curl` citation spot checks passed in `review/evidence/audit-r4-citation-spot-checks-pass.log`.
