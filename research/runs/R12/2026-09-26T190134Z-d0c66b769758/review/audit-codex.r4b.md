actor: codex
model: gpt-6
family: openai
decision-sha256: 23e5a61fb9f3a228823803c71e1291fdc1629a7cd2686c945e5f9abe14d0d48c
execution-policy-sha256: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
verdict: approve
unresolved-findings: none

# R12 empirical audit — revision 4 re-run

**SUPERSEDES review/audit-codex.r4.md (blocked on evidence-sufficiency only, no contradiction — same DECISION rev, re-run under the standing evr rule).** The target `review/DECISION.md` matched the dispatched SHA-256 before the audit and again before this file was written. The earlier `.r4` audit remains untouched. This is the single Q23 empirical re-run; controller S1 owns triage.

## Reruns and complete log comparisons

All six committed evidence scripts ran from the repository root. Outputs went to `/tmp/r12-r4b-*.log`. `r12-sources.sh` was copied without edits, together with its fixture, manifest, and snapshots, into `/tmp/r12-r4b-sources/evidence/` before execution. Its fresh network reads and snapshot writes thus affected only `/tmp`; the committed evidence and run inputs were read-only. Read-only `git show` in `r12-verdict.sh`, `r12-ts.sh`, and `r12-sources.sh` was allowed under the standing evr rule. `cmp -s` compared each complete output with its committed `review/evidence/*.log` counterpart. `shellcheck` over all six scripts exited 0 and matched its empty committed log byte-for-byte.

| Script | Exit | Rerun result | Complete log vs committed |
|---|---:|---|---|
| `r12-inputs.sh` | 1 | `PASS=50 FAIL=2 SKIP=0` | identical |
| `r12-citations.sh` | 0 | `PASS=56 FAIL=0 SKIP=0` | identical |
| `r12-lint.sh` | 0 | `PASS=18 FAIL=0 SKIP=0` | identical |
| `r12-verdict.sh` | 0 | `PASS=43 FAIL=0 SKIP=0` | identical |
| `r12-ts.sh` | 0 | `PASS=8 FAIL=0 SKIP=0` | identical |
| `r12-sources.sh` | 1 | `PASS=56 FAIL=3 SKIP=0` | different; details below |

## Findings

- **E1 [OBS] — The disclosed 50/52 live-policy drift holds exactly.** `review/DECISION.md:32` says, “two checks of `r12-inputs.sh` fail, both on live-policy drift and on nothing this revision changed.” The rerun is byte-identical to the committed log: `FAIL I-policy -- policy drift`, `FAIL I-auditor-override -- R12 empirical seat differs`, and `RESULT PASS=50 FAIL=2 SKIP=0`. `I-override` still passes for `['muse', 'opus']`. Live `research/EXECUTION.json` hashes to the S79 pin above; frozen `inputs/EXECUTION.json` hashes to `acdcbfff5fa46a68cd0999147b294e41fa6c4d6c88428c9fc7c46cdedfabf137`. No re-pin is requested.
- **E2 [OBS] — Fresh cancelled-run samples changed the source log, without a green-gate counterexample.** The committed log says `RESULT PASS=59 FAIL=0 SKIP=0`; the fresh full rerun says `RESULT PASS=56 FAIL=3 SKIP=0`. Its three failures are `S-cancelled-r12-cancelled-cargo-1 -- conclusion=failure` and `S-cancelled-r12-cancelled-uv-2/3 -- conclusion=`. Cargo's sampled aggregate is non-green. Both uv API responses report `total_count: 0` and return no jobs, so they cannot test the aggregate's behavior. The other six cancelled-run assertions pass; the first uv sample's aggregate ran to `failure`. The source pins, star count, and Tokio sample also changed in the complete log; all other source assertions pass, including rulesets, required contexts, documentation, and snapshot integrity. `review/DECISION.md:146` explicitly bounds its nine-run claim to the earlier sample and leaves the cancelled dependency and hand-cancelled head cases to P03; this new sample weakens that empirical illustration but does not contradict the recommended `always()` rule or supply a passing required check after a failed gate. The decision's earlier 9/9 count is a point-in-time result, not the result of this rerun.
- **E3 [OBS] — The revision-note repairs and executable claims still hold.** The revised rule requires `merge_group` for other gating workflows (`review/DECISION.md:47,189-191`), and those lines condition R17 and R38 on becoming merge-blocking. The authorities distinguish the commits read from the programme pins (`review/DECISION.md:66`). Disagreement 7 quotes Opus's one-job claim and adjudicates it against the two-job ts file (`review/DECISION.md:313-317`); read-only `git show cb1cbcb2:.github/workflows/ci.yml` shows `bun-lane:` at line 141 and `continue-on-error: true` at line 144. `r12-citations.sh`, `r12-ts.sh`, `r12-lint.sh`, and `r12-verdict.sh` all reproduce their committed complete outputs, including the allow-list vectors T1–T9 and guard cases G1–G4.

## Verdict

`approve`: zero BLOCKING findings under RUNBOOK §7.1. E1–E3 are observations for S1 triage.
