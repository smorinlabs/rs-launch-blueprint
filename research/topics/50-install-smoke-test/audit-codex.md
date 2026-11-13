# R50 revision 7 — empirical re-run audit

actor: audit-codex-2026-09-17T020715Z-b7ef95f12806-r7
model: gpt-6
family: openai
decision-sha256: 8bdacbc77c91f89dd720a4c139c48477237eed4c220b3709a342288b6e903cf9
verdict: approve
unresolved-findings: none

The decision hash was recomputed with `shasum -a 256` before reading or running evidence. The Q23 seat citation is the supplied point-in-time `research/EXECUTION.json` SHA-256 `fd746cb86e54`; this audit does not treat live-policy drift as a finding. Every retained evidence script was executed once from the repository root. Output files were written under `/tmp/r50-codex-r7.tk4PS1/`; no input, snapshot, or evidence file was edited. The supplied `CARGO_HOME=/tmp/cargo-s62-R50-evr` and `CARGO_TARGET_DIR=/tmp/cargo-s62-R50-evr-target` were not overridden by the audit commands.

| Script | Exit | Re-run output SHA-256 | Committed log SHA-256 | Byte comparison |
|---|---:|---|---|---|
| `r50-check.sh` | 12 | `b66ea6b333dfee3e3ba13fd1653fe82abe30217fd04ca1b0e6be16b1639cf12d` | `4cc2f81a41e01c4f35dcaa8c9f17295bb1331c34a3d31f1b1feddd2fbb7fbe21` | different |
| `r50-r2-archive-rerun.sh` | 3 | `6145c237ae7d4763556b2cd8d6738813575dfe6b075ee1c436740e207a537f31` | `508ee472ff9dab3c698232671794ccefb56d8fd352dd41c00eb126d55cb48e34` | different |
| `r50-r4-delta.sh` | 0 | `ae1a2a49d17757c9cabdbe64be91f48b1f9e420ceb22e484f21864e3b5ace5e7` | `ae1a2a49d17757c9cabdbe64be91f48b1f9e420ceb22e484f21864e3b5ace5e7` | identical (`cmp` 0) |

## Findings

- **OBS-1 — supplied Cargo target directory changes the first two reruns.** `r50-check.log` reports 12 failed assertions. The first is `FAIL optionC/package/crate-archive-exists`; its verification compile appears under `/tmp/cargo-s62-R50-evr-target/package/` instead of the script's expected `<SCRATCH>/ws/target/package/`. The missing expected archive path causes the subsequent extract/install failures. The archive wrapper confirms the archived inner script matches the working script (`bdd7bc3c3c0e7fb025b92382342403cd32250da074c150496537a90ad6d55a39`) and then reports that same inner result: 12 failures, followed by three wrapper count/status failures. This is the condition disclosed in `DECISION.md` under “O-1, and why `r50-check.sh` does not carry the unset”: “an environment the decision's stated conditions (recorded command, cwd, toolchain, clean environment) already exclude, and under which the script reproduces exactly.” The decision also says `r50-r4-delta.sh` “unsets `CARGO_TARGET_DIR` / `CARGO_BUILD_TARGET_DIR` up front”; its rerun exited 0 and matched the committed log byte for byte. The changed environment limits reproduction of the first two retained logs here; it does not contradict their stated clean-environment result or the recommendation.

## Revision 7 repair checks

- The revision note at `DECISION.md:25` quotes the accepted repair. The repaired paragraph at `DECISION.md:204-207` says “`:182`'s ts and inferred cells are not asserted by any retained script (phase L asserts only its harmonize cell, `r50-r4-delta.log:46`) and were read directly for revision 6.” `r50-r4-delta.sh:171` asserts `div/f222-harmonize-no` against `| no |` only; the byte-identical rerun has `PASS div/f222-harmonize-no` at line 46. `docs/port/DIVERGENCE-ANALYSIS.md:182` still has the quoted ts and inferred cells. No retained script asserts those two cells.
- The phase-L description at `DECISION.md:718-722` also limits the assertion to the harmonize cell. The phase-D table row at `:823` limits that phase to the first three records. The F222 disposition at `:948-950` names four records. The `OVERRIDE (OV-13)` clause at `:294-298` distinguishes the language-bound mechanism from the incorrect assertion that ts lacks an install-and-run step.
- The `re-verify:` record remains one physical line at `DECISION.md:560` with triggers `(1)` through `(13)`. The four `- assumes` lines remain at `:564-567`. The three evidence script SHA-256 values match the revision note: `r50-check.sh` `bdd7bc3c3c0e7fb025b92382342403cd32250da074c150496537a90ad6d55a39`, `r50-r2-archive-rerun.sh` `3df01af40c01c5f71253067858d52640cbd487ce58d27bc6c149a557cd1d5bd1`, and `r50-r4-delta.sh` `b2b9bfa3a7becde70d55d2797c0d0ac69a38e19389594096081b22fd042a4dc9`.

Zero BLOCKING findings. Under RUNBOOK §7.1, the verdict is `approve`.
