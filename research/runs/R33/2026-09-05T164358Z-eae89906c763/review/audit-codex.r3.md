decision-sha256: 6318afe33322d3400ea5c0b4dfcd6190581b823f4e7f8dddcd45a34bee37f8f5
actor: audit-codex-2026-09-05T164358Z-eae89906c763-r3
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: ratio-stability claim is false at one decimal place

## Rerun

- argv: `bash review/empirical/r33-checks.sh`; cwd: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R33/2026-09-05T164358Z-eae89906c763`; toolchain: `rustc 1.98.0`, `cargo 1.98.0`, macOS 26.4 arm64; exit code: `0`. Complete output: `review/evidence/audit-property-and-snapshot-testing-r3.log` (sha256 `6342b5217b2e9c2ce9c3c31ad6ad46edfc14b0f90a06f02b3bbaab982431dfed`). It emits checks 1--13 plus 9b and 11b, has 147 `STATUS OK`/`ASSERT OK` lines, no failure line, and ends `failed assertions: 0`.
- The rerun matches revision 3's saved log after excluding its 15 timestamps and the six volatile check-4 counter lines: `review/evidence/audit-r3-vs-saved-r3.diff` is empty. It also matches the actual revision-2 published log, `research/topics/33-property-and-snapshot-testing/evidence/2026-09-05T164358Z-eae89906c763-property-and-snapshot-testing.log` (sha256 `33c4358489d43edf46b30e37f7a8f5ff465f99f22ea3058e99604d6d40115f6b`), after excising check 14 and applying the same exclusions: `review/evidence/audit-r3-vs-published-r2.diff` is empty.
- No active citation names a missing section. The active decision mentions checks 1--13, 9b, and 11b only; its two `check 14` mentions expressly record retirement. The six categories of struck material do enumerate eleven locations: member-table dagger group, footnote, licence section, two ledger caveats, check 14, CI-reason clause, re-verify clause, engine-disagreement clause, unproven row 10, and closing uncertainty.
- Six direct source spot-checks passed with `curl` and content assertions: `review/evidence/audit-r3-citation-spot-checks.log` (sha256 `3825e6de7adaa216e3a560e6271eff217558934f6a3619be00614cf9846b8e83`).

## Findings

1. The claimed one-decimal ratio stability is false. `review/DECISION.md:98` says the ratios "did not move" at one decimal while also saying `insta`/`snapbox` shifted from 8.3x to 8.2x; `review/DECISION.md:161` repeats that four ratios are unchanged. Recalculation from the named published revision-2 log to the revision-3 saved log finds `insta`/`snapbox` downloads 8.3 -> 8.2, reverse dependencies 28.1 -> 28.2, and `insta`/`expect-test` reverse dependencies 14.0 -> 14.1. Only the download ratios for `insta`/`expect-test` (3.6 -> 3.6) and `proptest`/`quickcheck` (4.4 -> 4.4), plus `proptest`/`quickcheck` reverse dependencies (6.8 -> 6.8), remain unchanged at one decimal. The decision must correct the statement or name a defensible, narrower set of ratios.

## Assessment

The licence ruling is applied correctly: gate 1 is recorded as inapplicable with the owner's reason, and its deletion of terminal check 14 leaves all active check citations intact. The script remains failure-sensitive (`set -o pipefail`, content assertions, and failure-count exit status), the rerun succeeds, and both required log diffs reproduce. The eleven-location enumeration is accurate under the decision's six-kind grouping. However, the adoption-figure conclusion asserts a falsified numerical result; the recommendation may be unchanged, but the decision must repair that evidence claim before acceptance.
