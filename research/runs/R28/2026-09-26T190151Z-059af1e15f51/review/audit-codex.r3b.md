# R28 revision 3 — empirical re-run audit

SUPERSEDES review/audit-codex.r3.md (blocked on evidence-sufficiency only, no contradiction — same DECISION rev, re-run under the standing evr rule).

actor: codex-empirical-r28-r3b
model: gpt-6
family: openai
decision-sha256: c607a34e01f36673d0be729a826ee10fdd5ed77c94a31dcde3726ab2cd7e8519
execution-pin-sha256: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
verdict: blocked
unresolved-findings:
- BLOCKING E1 — The current run inputs contradict the decision's snapshot-policy provenance claim; `r28-inputs.sh` reports three failed cases.

## Re-run and byte comparison

The decision hash matched before the first read and again before this file was written. I executed all nine unmodified scripts in `review/evidence/`, directing their output and full unified diffs to `/tmp/r28-r3b-*`. Cargo used the dispatched private `CARGO_HOME=/tmp/cargo-s79-r28-redo` and `CARGO_TARGET_DIR=/tmp/cargo-s79-r28-redo-target`. The autofix script created and removed its Git fixture inside its temporary scratch directory; it made no Git change to this repository. The source and live-figure scripts made read-only requests to their named endpoints. An initial network-restricted attempt could not reach those endpoints; the successful reruns below had network permission. An initial autofix attempt failed because Cargo could not bind a local TCP listener for locking; the successful rerun had that permission. Findings use the successful outputs.

| Script | Re-run result | Full-file byte comparison with committed log |
|---|---|---|
| `r28-lint-table.sh` | exit 0; 13 PASS | different: Cargo home, scratch path, build duration and one compiler target label; all case lines identical |
| `r28-test-relaxation.sh` | exit 0; 11 PASS | different: Cargo home, scratch path, scheduling warning and test duration; all case lines identical |
| `r28-autofix.sh` | exit 0; 5 PASS | different: Cargo home, scratch path, scratch commit and build duration; all case lines identical |
| `r28-floor.sh` | exit 0; 5 PASS | different: Cargo home, scratch path and build duration; all case lines identical |
| `r28-editor-config.sh` | exit 0; 6 PASS | different only in Cargo home; all case lines identical |
| `r28-sources.sh` | exit 0; 10 PASS | different only in retrieval timestamp; all pinned-source payload bytes and case lines identical |
| `r28-live-figures.sh` | exit 0; 7 PASS | different in retrieval timestamp and live stars, push times, issue count and download counts; all case lines identical |
| `r28-ruff-fix-default.sh` | exit 0; 2 PASS | different only in scratch path; all case lines identical |
| `r28-inputs.sh` | exit 1; 154 PASS, 3 FAIL | different in prompt and policy hashes and cases `I1-canon`, `I8-engines`, `I8-override`; remaining case outcomes match |

## Findings

- **BLOCKING E1 — snapshot-policy provenance contradicts the current run inputs.** The decision says, “`inputs/EXECUTION.json` lists R28 engines `codex, opus` and no R28 override” and labels the Muse leg “not authorized by the snapshot policy” (`review/DECISION.md:201`). Its revision note says the same provenance remains for the controller to resolve (`review/DECISION.md:5`), and `## Engines` makes acceptance depend on that status (`review/DECISION.md:205`). The rerun instead prints `FAIL I8-engines — R28 engines ['muse', 'opus'], tier focused` and `FAIL I8-override — no engine_overrides entry for R28`. The current `inputs/EXECUTION.json` has `engines: ["muse", "opus"]` **and** an R28 `engine_overrides` entry with the same values. Its SHA-256 is `fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c`, matching `manifest.json`'s current policy input hash and the stated S79 pin. The current `inputs/prompt.md:28,79` matches the canonical prompt at those lines; the script expects the old Q17.A difference and prints `FAIL I1-canon — canonical prompt differs from inputs/prompt.md only by the Q17.A edit (line 28 engines, line 79 Muse sentence)`. These are contradictions of the decision's load-bearing snapshot provenance claim, not drift of live `research/EXECUTION.json` against the S79 pin. The manifest still records `required_engines: ["codex", "opus"]`; this audit does not resolve that controller question.
- **OBS O1 — eight empirical scripts preserve their case outcomes.** Their 59 PASS lines are byte-identical to the committed logs. The full-file differences listed above are run-local or retrieval-time values. This confirms the decision's disclosure of scratch and retrieval drift (`review/DECISION.md:175,186-191`); the live figures have continued moving since those quoted retrievals.
- **OBS O2 — revision-note repairs are present and the unaffected citation checks pass.** The R30 hand-off appears at `review/DECISION.md:98,117`, its re-verification trigger at line 140, and the joint-leg statement at line 207. The CodeLLDB maintenance cell cites `raw/opus.md:691-695` and its `/releases` source at `raw/opus.md:916` on line 39. The revision-3 `r28-inputs.sh` rerun passes its raw-citation and I11 checks, including R30's open status. The three failed cases above keep the decision's claimed 157/157 result (`review/DECISION.md:173`) from reproducing against the current run inputs.
