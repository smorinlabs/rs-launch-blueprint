decision-sha256: 2018fcdb67d5e265b27ede87259bfb31fd67e0ded6d57a71ff206a1ab0c8e5e6
actor: audit-fable-r11-r8-2026-11-27
model: claude-opus-5-5
family: anthropic
verdict: approve
unresolved-findings: none

# R11 revision 8: judgment audit (audit-fable seat)

**Scope.** This audit covers the R69 revision-11 flag-day touch-up of R11 `ci-workflow-job-structure`. The target is the draft `/tmp/p02-flagday/drafts/R11-DECISION.md`, 920 lines. It is checked against the published revision 7 at `research/topics/11-ci-workflow-job-structure/DECISION.md`, 456 lines. The audit was read-only and edited no repository files.

**Result.** I approve. The draft is a pure flag-day touch-up. It has no BLOCKING finding under `research/RUNBOOK.md` §7.1 (Q23). There are three non-blocking observations, O1 to O3 below. Under §7.1 they are recorded, not given a round.

## 1. Identity and supersession tail

| Check | Command or method | Observed | Result |
|---|---|---|---|
| Draft hash | `shasum -a 256` on the draft | `2018fcdb67d5e265b27ede87259bfb31fd67e0ded6d57a71ff206a1ab0c8e5e6` | equals the expected hash |
| Prior published hash | `shasum -a 256` on the published R11 `DECISION.md` | `410e88e5195a08def126037e9c451988633b1e48437ac82edca0a08c7a62418c` | equals the revision-7 hash cited in the revision-8 note |
| Supersession tail | `tail -n 456 <draft> \| cmp - <published>` | no output; `TAIL_MATCH` | revision 7 is appended verbatim |
| Supersession heading count | `grep -c '^## Supersedes'` | 1, at draft line 463 | exactly one heading, directly above the preserved revision 7 |

The preserved revision 7 brings its own H2s (`## Decision`, `## Parameters`, `## Empirical check`, `## Engines`) below line 463. §4 requires the prior entry to be kept verbatim, so this is expected.

## 2. Pure flag-day touch-up

I diffed the draft's first 462 lines (the new body) against revision 7. Every changed hunk falls into one of the enumerated changes:

| Diff hunk | Change | In the revision-8 enumeration |
|---|---|---|
| line 1 | H1 changes to `2026-11-27 … (revision 8)` | the heading, named as outside the five |
| new lines 3–7 | revision-8 note inserted | the note itself |
| line 80 → line 85 | provenance token reworded to "the supersession section" | change 4 (see O1) |
| line 316 → line 321 | `re-verify:` R69 trigger: "R69 revision 11 published 2026-11-27 (fired and re-derived here; …)". The other triggers are byte-identical. | change 3 |
| line 325 → line 330 | `- assumes web-extra-surface` replaced | change 1 |
| line 329 → line 334 | the parameters note rewritten | change 2 |
| after line 456 | one blank line before the supersession section | layout only |

**Lines that stay unchanged.** The diff has no hunk in any of the following, so each is byte-identical to revision 7:

- the recommendation;
- `### Principles and implementation`;
- the slot table, including the R32 row at revision-7 line 282 (draft line 287);
- the `- owns ci-job-structure` line (draft line 325 equals revision-7 line 320);
- `## Empirical check`, which leaves the evidence and fixture citations unmoved;
- `## Engines`, including the agreement level and the confidence paragraph.

**The `assumes` line matches R69 revision 11.** `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` hashes to `2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815`. Its H1 reads "revision 11". I took its line 1885, replaced `- owns ` with `- assumes `, and compared it to draft line 330 with `cmp`. The output was `ASSUMES_MATCH`, a byte-for-byte match. That line carries:

- `web = ["dep:rs-launch-blueprint-web"]` on the root package;
- `crates/web/src/` and `crates/web/tests/`;
- `path-based skip-gating keys on crates/web/**`.

The worktree's `docs/port/PARAMETERS.md` still carries the revision-9 row (`src/web/**`). That is consistent with the note's claim that the registry row publishes "in this same flag-day commit". It is not drift in this draft.

**The new layout fits the existing fixture.** Revision 7 already kept the fixture off `^src/web/`. It used the fail-closed `web` rule: `web` follows `code`, plus any change under the web member's directory (`R3-D2`). R69 revision 11's `crates/web/**` keys are therefore a subset of the existing rule. The updated note says exactly this. The claim that the trigger "fired and is discharged here, with no change to the graph" is accurate.

**R32 discharge.** I checked three sources:

- `research/topics/32-test-harness-and-execution/DECISION.md:255` holds the `CONFLICT: R11 ci-job-structure` line. That line itself cites R11's slot row at `DECISION.md:282` and invites a slot-fill disposition.
- R11's line 282 delegates to R32 "the tier names inside `check`'s test steps". It rules that a tier becomes its own job only with a different toolchain, a different runner, or a `target/` it must not share. Otherwise the tier is an ordered step of `check`.
- `docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md` has status "Owner-approved (review gate accepted 2026-11-27)". Its Area 8 row names `cargo-nextest` plus `cargo test --doc` for `P07` and `P10`. Its Area 10 row keeps R11's plan-gated `check`.

The fill adds nextest, the doc-test step and the R42-provisioned `cargo-nextest` install as ordered `!cancelled()` steps inside `check`. They share `target/` and add 0 jobs and 0 cache-bearing job ids. The draft records this correctly as a slot fill under the R32 row, with no change to `ci-job-structure`.

## 3. Contradictions (RUNBOOK §7, Q23)

I found no BLOCKING contradiction. No finding below moves the recommendation, a load-bearing claim, or the sufficiency of the evidence.

## Observations (non-blocking, recorded per §7.1)

- **O1: stale and ungrammatical provenance sentence (wording).** Draft line 85 now reads: "Nothing has been published for R11, so there is no the supersession section."
  - The sentence is ungrammatical ("no the").
  - In revision 8 it is also false. Revision 7 was published, and the supersession section exists at line 463.
  - The cause is the assembler's mechanical replacement of the heading token (step f in `prompt-r11-synth.txt`).
  - The sentence describes revision 7's own provenance, and nothing depends on it.
  - Suggested §7.5 micro-repair: replace "Nothing has been published for R11, so there is no the supersession section." with "At revision 7 nothing had been published for R11, so revision 7 carried no supersession section."
- **O2: the `owns` line still names `cargo test`, while R32 fills the step with nextest.**
  - The byte-identical `- owns ci-job-structure` line still says "cargo test with the feature off … cargo test over the workspace". After the R32 revision-3 slot fill, those two steps run as `cargo nextest run --locked --profile ci`.
  - Line 282 explicitly delegates the tier and runner inside `check`'s test steps to R32. The topology, job ids and cache budget do not move. So this is not outcome-changing.
  - A reader of the `owns` line alone could still misread the step runner. If the line is ever re-touched, the wording could say "test steps whose runner R32 fills".
- **O3: layout (cosmetic).** There are two blank lines between the revision-8 note and the revision-7 note (draft lines 7–8). There is also one extra blank line before the supersession section. Neither line carries content.

## Verdict

**Approve, with no unresolved findings.** O1 is the only item worth an optional §7.5 micro-repair. If the controller applies it, this audit's `decision-sha256` must be re-bound to the repaired bytes under §7.5.