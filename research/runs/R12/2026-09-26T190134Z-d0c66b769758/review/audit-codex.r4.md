actor: codex
model: gpt-6
family: openai
decision-sha256: 23e5a61fb9f3a228823803c71e1291fdc1629a7cd2686c945e5f9abe14d0d48c
verdict: blocked
unresolved-findings: E1

# R12 empirical audit — revision 4

The target `review/DECISION.md` matched the dispatched SHA-256 before any other read and matched again before this audit was written. `research/RUNBOOK.md` §7 applies: only outcome-changing findings are BLOCKING. No live-policy input was repinned, and I did not read `research/EXECUTION.json` directly.

## Reruns and full-output comparisons

`CARGO_HOME=/tmp/cargo-s73-R12-evr` and `CARGO_TARGET_DIR=/tmp/cargo-s73-R12-evr-target` were exported before the reruns. Combined stdout and stderr went to `/tmp/s73-R12-evr-<script>.log`. `cmp -s` compared each complete output against the corresponding committed log.

| Script | Exit | Result | Whole-log comparison |
|---|---:|---|---|
| `r12-inputs.sh` | 1 | `PASS=50 FAIL=2 SKIP=0` | byte-identical |
| `r12-citations.sh` | 0 | `PASS=56 FAIL=0 SKIP=0` | byte-identical |
| `r12-lint.sh` | 0 | `PASS=18 FAIL=0 SKIP=0` | byte-identical |
| `r12-verdict.sh` | — | not rerun | unavailable |
| `r12-ts.sh` | — | not rerun | unavailable |
| `r12-sources.sh` | — | not rerun | unavailable |

`shellcheck` on all six scripts exited 0 and produced a byte-identical empty output to `shellcheck.log`.

## Findings

- **E1 [BLOCKING] — Three load-bearing evidence scripts could not be rerun under this dispatch.** `r12-verdict.sh` and `r12-ts.sh` invoke `git`; `r12-sources.sh` invokes `git` and writes `snapshots/`, `snapshots/PROVENANCE.md`, and `SHA256SUMS` beside the committed script. The dispatch forbids every `git` subcommand and any in-repository write outside this audit file. The decision's evidence table claims `r12-verdict.sh` proves the recommended rule on T1–T9 and guard on G1–G4; `r12-ts.sh` proves the two-job and voting-set claims; `r12-sources.sh` proves the fresh external facts, including live protection and required-check settings. Their committed logs are available, but this worker cannot establish their current rerun results or byte-compare fresh outputs. This is an evidence-sufficiency gap for load-bearing claims, not evidence that those claims are false. The coordinator must resolve the execution constraints or disposition the gap under RUNBOOK §7.
- **E2 [OBS] — The revision-4 policy-drift disclosure holds exactly.** The full `r12-inputs.sh` rerun and committed log are byte-identical. Exactly two checks fail: `FAIL I-policy -- policy drift` and `FAIL I-auditor-override -- R12 empirical seat differs`, with a `KeyError: 'R12'` in the latter check. `I-override` passes for `['muse', 'opus']`. The `I-policy` byte comparison and `I-auditor-override` assertion remain present in the script; neither was relaxed. This is the disclosed live-policy drift under the no-repin rule, not a contradiction.
- **E3 [OBS] — The revision-4 repair citations and the checks available here hold.** `r12-citations.sh` reports `PASS=56 FAIL=0 SKIP=0`, including anchored checks for the Opus ts job-count lines, R17's missing `merge_group`, R38's trigger, and the programme source pins. The decision at lines 47, 66, 189–191, and 313–317 records the required `merge_group` condition for other gating workflows, qualifies R17 and R38 as future merge-blocking cases, distinguishes the commits read from programme pins, and adjudicates the two-job disagreement. `r12-lint.sh` reports `PASS=18 FAIL=0 SKIP=0`. Each of these three rerun outputs is byte-identical to its committed log.

## Verdict

`blocked` because E1 prevents the required independent re-execution of every evidence script. E2 and E3 are observations and do not themselves cost a round.
