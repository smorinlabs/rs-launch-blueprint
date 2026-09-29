# R03 revision 2 empirical audit

actor: codex empirical re-run worker
model: gpt-6-sol
family: openai
decision-sha256: 560d421be9c7046053ae62b4aab3fd4d6acab53640db4d48be9af9367f1ebf8e
verdict: approve
unresolved-findings: none

## Re-execution

I verified the decision hash before reading or running evidence. I ran all three evidence scripts with `CARGO_HOME=/tmp/cargo-s73-R03-evr` and `CARGO_TARGET_DIR=/tmp/cargo-s73-R03-evr-target`. Outputs and scratch files stayed under `/tmp/r03-evr`; the contract script ran at its repository path, while copies of the probe and practice scripts ran under `/tmp` because those scripts write support files beside themselves. I compared each complete rerun log against its committed log with `cmp` and `diff -u`.

| Script | Exit | Whole-log comparison | Result |
|---|---:|---|---|
| `r03-contract.sh` | 0 | Diff contains one added `< <` / `> >` row pair in the registry-difference section | All checks passed |
| `r03-probe.sh` | 0 | Byte-identical | All checks passed |
| `r03-practice.sh` | 3 | Only the three repository visibility answers, three cited URL answers, their assertions, and final result differ | Three live URL checks could not get an answer; snapshot checks passed |

## Findings

- **OBS-1 (OBS):** The contract rerun prints one more unrelated registry-difference pair than the committed log. The repaired assertion at `r03-contract.sh:149-150` still reports zero changed consumed or fixed rows, and all five byte-identity assertions pass. This is the later-row drift that revision 2's §1.3 and `## Parameters` allow. The current stdout therefore differs from the committed log, while the repaired decision makes no exact-one-row claim.
- **OBS-2 (OBS):** The practice rerun could not reach GitHub through `gh` or `curl`. The committed log records three `.private = false` answers and three HTTP 200 answers; the rerun records three `.private = (no answer)` answers and three `(no answer)` URL statuses, causing three failed live URL assertions. No returned visibility value or HTTP status contradicts the decision's dated 2026-09-17 observation. The snapshot-based practice assertions passed.

## Revision 2 repair checks

- EA-1 holds: `r03-contract.sh:207` double-quotes the apostrophe-containing pattern. Both the committed and rerun logs contain R01's `117:` context line and no `grep:` error. A separate rerun wrote zero bytes to stderr, and its stdout was byte-identical to the combined-output rerun. The `## Empirical check` section names the `2>&1` recording.
- EA-2 holds: `r03-contract.sh:149-150` rejects changes to any consumed or fixed row. The five value comparisons remain present and pass. Revision 2's §1.3 and `## Parameters` describe only those rows' stability and permit changes to other rows.

There are zero BLOCKING findings under `research/RUNBOOK.md` §7.1: the observed differences do not move the recommendation, a load-bearing claim, or the evidence sufficiency for either.
