decision-sha256: 039ef6db8b54659991c50eae1ff473c3ece5674cdf13e7a276212c8b545ac2c3
actor: audit-fable-r84-r6-2026-11-27
model: claude-opus-5-5
family: anthropic
verdict: approve
unresolved-findings: none

# R84 revision 6 judgment audit: R69 revision-11 flag-day touch-up

**Outcome.** Approve. Revision 6 is a pure flag-day touch-up. It leaves the recommendation, `OVERRIDE (OV-11)`, the principles, the agreement level and the evidence byte-identical. I found no BLOCKING contradiction under `research/RUNBOOK.md` §7.1 (Q23). The four findings below are non-blocking. They are recorded here and do not cost a round. This audit is read-only: no repository or draft file was edited.

## 1. Hash binding and supersession tail

| Check | Command / method | Result |
|---|---|---|
| Draft hash | `shasum -a 256 /tmp/p02-flagday/drafts/R84-DECISION.md` | `039ef6db8b54659991c50eae1ff473c3ece5674cdf13e7a276212c8b545ac2c3`. Matches the expected hash. |
| Prior published hash | `shasum -a 256 research/topics/84-openapi-typed-client-generation/DECISION.md` | `90cf41d91cde910e5bfb087131ec332697759e235ff41ea72ed90a371b12d2ab`. Matches the revision-5 hash cited in the revision-6 note (draft line 3). |
| Supersession tail | `tail -n +793` of the draft, then `cmp` against the published file | Byte-identical (`TAIL_MATCH`). The tail starts under `## Supersedes` (draft line 791) with the revision-5 H1. |
| Draft / prior sizes | `wc -l` | 1584 lines in the draft. 792 lines in the prior file. That is 790 lines of body, plus the heading and one blank line, plus the 792 lines of verbatim tail. |

## 2. Pure touch-up scope

`diff <(sed -n '1,790p' draft) prior` shows exactly six changed hunks. Each one maps to a declared change, (a) through (d), in the revision-6 note:

| Draft line | Change | Declared as |
|---|---|---|
| 1 | H1 date and revision marker set to `2026-11-27` / `revision 6` | Header |
| 3–5 | Revision-6 note added | Header |
| 83 | `` `## Supersedes` `` replaced by `the supersession section` | (d) |
| 371 | `re-verify:` line records that trigger 1 (R71 r4 publication) and trigger 2 (R69 republished as r11, sha256 `2806a1f0…1815`) fired on 2026-11-27, with no effect | (b) |
| 575 | `- assumes web-extra-surface` line replaced with R69 r11's live value | (a) |
| 577 | Prose note on `web-extra-surface` rewritten for revision 11 | (a) |

**The registry value is exact.** `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` hashes to `2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815`, and its H1 reads `revision 11`. I compared the value after `- owns web-extra-surface = ` on its line 1885 with the value after `- assumes web-extra-surface = ` on draft line 575. They are identical once the prefix is removed. The prose note cites `…/review/DECISION.md:1885`, which is correct.

**Nothing else changed.** The diff shows no change to any of these:

- the recommended mechanism: `openapi-to-rust` pinned at `0.17.0`, the `just client-rust` recipe, and its manifest
- `OVERRIDE (OV-11)`
- the `### Principles and implementation` section and the agreement level
- the check identifiers, evidence references, and pass/fail/skip counts
- the `## Empirical check` and `## Engines` sections

The statement that no script was rerun is sound. R84 consumes only the OpenAPI snapshot. R71 revision 4 keeps that snapshot at 3.1.0, so no evidence input changed.

## 3. Contradiction check (RUNBOOK §7.1, Q23)

Under §7.1, a finding is BLOCKING only if it changes the outcome, meaning it moves the recommendation, a load-bearing claim, or the sufficiency of the evidence behind either. No finding meets that bar. The web-layout change cannot move R84's outcome, for two reasons. The draft says so explicitly ("Nothing in this recommendation depends on which form is live"). It is also structurally true: R84 adds nothing to the web surface and reads only the generated snapshot. Raising no `CONFLICT:` line is therefore correct.

### Non-blocking findings (recorded, not rounded)

1. **Stale present-tense passage, draft lines 124–127 (observation, wording drift).** The passage reads: "R69 revision 10 is owner-accepted and unpublished … The `- assumes` line itself carries the live registry value, which is still revision 9's form." After change (a) this is no longer true. The passage sits inside the revision-1 "What this revision rests on" preamble, so a reader could take it as history. Even so, its present tense contradicts lines 575–577. It does not change the outcome. A suggested micro-repair under §7.5 would add "(as of revision 5; superseded by R69 revision 11 in revision 6)" or reword the passage in the past tense.
2. **Grammar defect from mechanical replacement (d), draft line 83 (wording polish).** The sentence now reads "there is no the supersession section." Suggested repair: "there is no supersession section."
3. **Trigger 2 text and AC10 status are not refreshed (observation).** Trigger 2 (line 345) still says "at revision 10". The `re-verify:` line already explains that revision 11 superseded it, so the meaning holds. AC10 (lines 405 and 1194) still reads "**Planned**, after R71 publishes (`acceptance-after: R71`)", even though the note says R71 revision 4 publishes in this commit. Under the Doxa wording, `acceptance-after` is an integration prerequisite that "does not replace research evidence or acceptance". So "Planned" is still accurate: the N1–N4 run against the real snapshot happens at integration. This is not a contradiction.
4. **Claim (c) is not visible in the DECISION bytes (observation).** The note says R84's `acceptance_after` "is re-bound to the R71 revision 4 publication in this commit". No hunk in the body diff carries that change, so it presumably lives in a sidecar file such as `acceptance.json` in the flag-day commit. That re-binding should be checked when the commit is assembled. It has no bearing on the decision text.

## Disposition

Approve. Every hash binding is verified, the supersession tail is verbatim, the scope is limited to the declared clauses (a) through (d), and the recommendation and evidence are unchanged. Findings 1 and 2 are optional approve-with-repair micro-repairs under §7.5. Findings 3 and 4 are recorded observations for the controller.