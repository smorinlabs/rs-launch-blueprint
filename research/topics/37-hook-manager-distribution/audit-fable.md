decision-sha256: b224198fb3f430a577aad5de13ba8657719a71c02499f0b4a5a57b91eb9f1775
actor: audit-fable-r37-r5-2026-11-27
model: claude-opus-5-5
family: anthropic
verdict: approve
unresolved-findings: none

# R37 revision 5 — independent judgment audit (audit-fable seat)

**Result.** Revision 5 is approved. It is a pure flag-day touch-up for R69 revision 11. The recommendation, the principles, the agreement level and the evidence are byte-identical to revision 4. The supersession tail reproduces the published revision 4 verbatim. No finding meets the BLOCKING bar of `research/RUNBOOK.md` §7.1 (owner decision Q23). One MECHANICAL wording observation is recorded below; under Q23 it is not rounded.

This audit was read-only. No repository file was edited.

## Check 1 — Hash and supersession tail

| Check | Command or method | Result |
|---|---|---|
| Draft sha256 | `shasum -a 256 /tmp/p02-flagday/drafts/R37-DECISION.md` | `b224198fb3f430a577aad5de13ba8657719a71c02499f0b4a5a57b91eb9f1775`, which matches the expected value |
| Prior published sha256 | `shasum -a 256 research/topics/37-hook-manager-distribution/DECISION.md` | `b172133d641c90157f3fb562281981e118cfd7397a382d23f209a56aec520c73`, which matches the revision-4 hash cited in the revision-5 note |
| Supersession tail | draft lines 529–1056 compared with `cmp` against the prior published file | `TAIL_EQUAL`: byte-identical, 528 lines |
| Heading | draft line 527 | `## Supersedes`, followed by one blank line, then the revision-4 H1 |

## Check 2 — Revision 5 changes only what the flag-day requires

I diffed the draft body (lines 4–525) against the full revision-4 file. The diff has exactly the hunks below, and nothing else differs.

| Hunk (draft line) | Change | In flag-day scope? |
|---|---|---|
| 1–3 | New H1 `… decision (revision 5)` and the revision-5 note | Yes: the required header and note |
| 55 | The backticked supersession heading token becomes "the supersession section" | Yes: an assembler rule that keeps the heading literal unique outside the tail |
| 294 (`re-verify:`) | Adds one trigger clause: a later R69 revision that, unlike revision 11, puts a web-specific check into a lefthook stage or a non-Rust runtime into the template | Yes: an additive trigger, with no change to any existing trigger |
| 309 (`- assumes web-extra-surface`) | Replaced with the R69 revision-11 value | Yes. The line equals `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1885` byte-for-byte, with `owns` changed to `assumes` (`cmp` reported `R69_VALUE_EQUAL`). That source file hashes to `2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815`, the revision-11 hash cited in the note |
| 312 ("How each consumed value is applied") | Same text as before, plus a paragraph on the move to the member crate | Yes. See the judgment below |

These sections have no diff against revision 4:
- `## Decision`, including the candidate `lefthook.yml` and the `Justfile` fragment (`_lefthook-pin`, `hooks-install`, F145, F175).
- Ledger rows F143, F144, F174 and F186.
- `## Empirical check`, all evidence line citations, `## Engines`, and the V1–V7 table.

All other `assumes` lines are unchanged: `msrv-policy`, `rust-edition`, `target-os-matrix`, `license`, `ci-job-structure` and `package-manager-invocation`. The note says that no script was rerun, and that matches the body: no cited log line moved.

**Judgment on the claim that the change has no effect.** The claim holds on independent grounds:
- **Acquisition.** lefthook is a release binary that contributors install through R42 layer 4. It is not a Cargo dependency, so changing `web = ["dep:axum", "dep:tokio"]` to `web = ["dep:rs-launch-blueprint-web"]` cannot reach it through the feature graph.
- **Wiring.** No job in the candidate `lefthook.yml` is specific to the web code or reads a web path. The pre-commit suite and `--all-files` re-run cover the whole tree whichever way the web code is laid out.
- **CI step.** The `hygiene` re-run has no `needs` edge and does not read `plan`'s `web` output. Only R11's detector consumes the new `crates/web/**` path, and R11's revision of `ci-job-structure` already sets `web` for any change under the web member's directory (draft line 307).

The new `re-verify:` clause names the exact condition that would overturn this conclusion, which is the right trigger.

## Check 3 — No BLOCKING contradiction (§7, Q23)

- **Recommendation, load-bearing claims, evidence sufficiency.** None moves. The `web-extra-surface` value changed, but no R37 conclusion rests on that value's former `src/web/**` form or its former `dep:` list. Therefore no §7.1 BLOCKING finding exists.
- **Cross-item consistency.** Revision 5 consumes R69 revision 11 exactly as published. Its `ci-job-structure` line already describes the web member (`crates/web`) and fail-closed `web` gating, so R37 does not contradict R11. R37 adds no duplicate owner claim on the value: it carries `assumes`, never `owns`.
- **Round economy.** This is not a fix round. No new finding, ledger decision or grant is introduced. §7.2's round cap is not engaged.

## Recorded observations (non-blocking)

- **MECHANICAL: line 55 wording.** The mechanical token rewrite left an ungrammatical sentence: "Nothing has been published for R37, so there is no the supersession section." The sentence is also stale because revision 4 is now published, though it sits inside revision 4's own carried-forward actor paragraph. Under Q23 §7.1 this is wording polish: it is recorded, not rounded. If the controller wants to fix it, §7.5 allows an exact find/replace micro-repair, for example `there is no the supersession section` → `there was then no supersession section`. Such a repair would re-bind this approval under §7.5.
- **Observation: `## Supersedes` token count.** The token appears twice: at line 527, the real heading, and at line 583, inside the verbatim revision-4 tail. The second occurrence is required by the verbatim-tail rule and is not a defect.