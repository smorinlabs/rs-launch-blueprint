actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: bb55cf4acbc9ce3ab4fb9ea7b0d969c2a86a77253640b52df1690a792155d4c2
verdict: reject
unresolved-findings:
  1. JF-3/JF-4 — Codex's thin→fat build-time figures are mislabelled as a baseline→recommended comparison, and the adjudication of the lto disagreement rests on that mislabel.
  2. JF-2 — the prompt's per-build incremental wall-time requirement is unmet for 10 of 12 rows, and the gap is not disclosed.
  3. JF-1 — the `## Empirical check` description of `decision-self-check.sh` is stale: it says the script asserts revision 2 and omits the r2-snapshot assertion.

# R68 release-binary-artifacts — judgment audit of revision 3 (fable)

**Scope.** This audit judges the decision's reasoning and fidelity. It does not judge execution; the empirical audit reruns the scripts.
**Target.** `research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md`, revision 3.
`shasum -a 256` gives `bb55cf4acbc9ce3ab4fb9ea7b0d969c2a86a77253640b52df1690a792155d4c2`, which matches the expected hash.
**Read.** The decision; `inputs/prompt.md`; `research/RUNBOOK.md` §4–§5; `raw/codex.md`, `raw/opus.md`, `raw/doxa-{openai,perplexity,gemini}.normalized.md` and `raw/doxa.md` (grep spot-checks); `inputs/prerequisites.json`; `research/topics/49-build-target-declaration/DECISION.md`; `research/topics/67-error-and-exit-code-contract/DECISION.md`; `docs/port/PARAMETERS.md` (working tree and `HEAD`); `docs/port/COMMONALITY.md`; the owner reference in `inputs/`; and the `review/evidence/` scripts and logs.
**Not read, per the audit contract.** No `review/audit-*.md` file and no `review/R68-r*-snapshot.md` file was opened. The two snapshots were hashed only.
**Model.** `claude-opus-5-5`. Date: 2026-09-26 (Pacific).

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** | See Finding 3. The rest is consistent. The threshold margins at decision lines 569–573 (4.5, 4.0, 3.7 and 7.9 pp) follow from the table. "Roughly a third" of the reduction (line 155) is 8.5 of 24.5 pp. The seven `dist-workspace.toml` settings (line 304) match the seven dist rows of the Subject A table. |
| JF-2 prompt questions and constraints | **fail** | See Finding 2. Every question under both subjects is answered. The Cargo Book citation, retrieval date, inheritance rule and override precedence are now present (lines 127–145). Gate 1 is recorded as `inapplicable` with Q7.B named. The reference row is dispositioned by section. The Linux/x86_64 measurement gap is disclosed (lines 763–771). |
| JF-3 engine fidelity and adjudication | **fail** | See Finding 1. Everything else I spot-checked is faithful. Codex's positions at lines 604–609 match `raw/codex.md` lines 273–317 and 338–346: dist 0.32.0 and `>=0.32.0, <0.33.0`, four targets, thin + cu1 + `strip = "symbols"`, `[profile.dist] inherits`, binstall only after the smoke, crates.io-only as runner-up, and "active with a backlog caveat". Opus's figures match `raw/opus.md` lines 463–476 to within 1.0 pp (thin + cu1 is −16.7% there against −16.0% here). "roughly doubles" is at `raw/opus.md:510`. The 3-of-18 census is at `raw/opus.md:94`. The 10-of-10 figure is at `raw/opus.md:221`. The Doxa attributions are sourced: Gemini's `cargo-zigbuild` (gemini line 92), `rustc 1.81.0` and 36.2 MB (lines 105 and 110); Perplexity's "0.32.0 changelog … delete `[profile.dist]`" (line 103); OpenAI's four targets and explicit `strip`/`panic` (lines 93 and 245–248); and "not executed" from both OpenAI and Perplexity. |
| JF-4 load-bearing claims trace | **fail** | Finding 1 is a claim that does not trace. Spot-checks that pass: sizes 1 994 032, 1 675 728 and 1 504 528 (`profile-probe.r2.log:33,41,43`); BACKTRACE rows 4/4/0/2/5 frames and exit codes 101/134 (`:86–90`); the `at ./src/` count of 2 → 0 (`:98`); `ubuntu-latest` = 0 in `github.rs` (`artifact-sources.log:42`); 23 assets (`:91`); binstall `SUPPORT.md` lines 148 and 124 (`:131,134`); F072, F214 and F220 at `COMMONALITY.md:78,218,224`; the owner reference's `lto = "thin"` and `codegen-units = 1` (lines 201–202), its `edition = "2021"` and `rust-version = "1.85"` (lines 132–133), and its "compiled in my head" caveat (line 435). R67's exit taxonomy lists 0, 1, 2, 3, 4, 5, 130 and 143, so the claim that "neither [101 nor 134] is in R67's taxonomy" holds. R67 R7.7's flush requirement exists (R67 lines 93 and 123). **Unverifiable under this audit's read prohibition:** the 2.0 pp figure (line 558) and the ~2.4× figure (line 705) are sourced only to `review/audit-claude.r*.md`, so I did not check them. |
| JF-5 couplings | pass, with a remark | Items handed off: to R51 (the container profile coupling), to R50 (the `--debug` smoke test does not exercise this profile), to R22 (the version encoded in archive names), and to R49 (its A4 re-verify trigger fires). Each hand-off states the event and leaves the choice to the owning item. R49's text is quoted correctly. **Remark:** the cited R49 line ranges are about one line off. The A4 winning condition is at R49 lines 889–891 (cited as 889–890). The re-verify trigger is at lines 1041–1046 (cited as 1042–1047). The prerequisite R49 decision hashes to `86b7f925…`, which equals `inputs/prerequisites.json`. |
| JF-6 `assumes` lines byte-identical | pass | I compared the value cell of all five `- assumes` lines with the fourth column of the corresponding `docs/port/PARAMETERS.md` row. The comparison script parses the table cells. All five are equal in both the working tree and `HEAD`. The decision writes no `- owns` line, and the prompt's `- owns:` line is empty. |
| JF-7 no conflict with accepted prerequisite values | pass | Nothing contradicts R49's `build-tool-output-shape` (`[lib]`, `[[bin]] rslbp`, `include` allow-list, `target/` layout). The "no build-orchestration crate" clause is examined at lines 355–364 and reasonably held not to reach a host executable. The decision's use of R67 and R69 matches their registry values. |
| JF-8 evidence scripts and counts | pass | All three scripts exist, and each log ends `RESULT: PASS`. `decision-self-check.r3.log` has 27 `ASSERT ok` lines, matching the 27 claimed. The snapshot hashes match the revision note: r1 is `070b7ae1…` and r2 is `72bd7972…`. Both raw hashes match: Codex `297219ed…` at 48 183 bytes, and Opus `b75fa7ab…`. Opus has 15 H3 sections, as claimed. Codex's operation record (`gpt-5.6-terra`, `codex-cli-0.155.1`, submitted 2026-09-20, collected 2026-09-21, `succeeded`) matches decision lines 596–600. |
| JF-9 decision shape | pass | The H2 sections are `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`, in that order, with no `## Supersedes` (RUNBOOK §5). `### Principles and implementation` sits under `## Decision`, and the `re-verify:` line is present. **Remark:** the title date 2026-09-27 is the UTC date. The Pacific date is 2026-09-26. |
| JF-10 recommendation follows from the evidence | pass | The Subject A pick, the runner-up ranking and each Subject B key follow from the measured deltas and backtraces. Finding 1 weakens the stated cost basis of `lto = "fat"` against `"thin"`. It does not reverse it: the log's own marginal clean cost (18 s → 25 s) and Codex's 2.6× edit-rebuild cost both remain compatible with the once-per-release argument. That argument must be made on correctly labelled figures, however. |

## Findings

### Finding 1 — JF-3 / JF-4: Codex's build-time figures are mislabelled in the key lto adjudication

**Failed claim.** Disagreement 1 (lines 623–626) says: *"Codex nevertheless recommends `thin` … citing clean 28.22 s → 47.39 s (~1.7×) … Weighed explicitly: the 1.7× clean-build ratio falls inside this decision's measured 1.3–1.9× spread, so it adds no new cost information"*.
Disagreement 9 (lines 703–704) says: *"Codex's stand-in measured 28.22 s → 47.39 s (~1.7×), inside that spread"*. The spread in question is the baseline → recommended clean-build cost.

**Evidence.** In `raw/codex.md`, lines 588–589 and 311, 28.22 s → 47.39 s and 7.35 s → 18.99 s are **thin + cu1 → fat + cu1**. That is the marginal cost of departing from the owner reference. It is not a baseline → recommended figure.
Codex's actual baseline → fat + cu1 figures are 29.04 s → 47.39 s (1.63×) clean and 1.15 s → 18.99 s (16.5×) edit (`raw/codex.md`, Cargo release defaults row).
The decision's 1.3–1.9× spread (lines 493–505) is also baseline → recommended.
The two ratios therefore measure different quantities, and "adds no new cost information" does not follow. Codex's figure is the only marginal thin → fat cost the decision engages with.
This item's own marginal clean figure exists but is never presented: `profile-probe.r2.log:42,44` shows `thin+cu1 … 18 s` and `fat+cu1 … 25 s`.
This disagreement is the one where the decision departs from the owner reference and from four of the five engine positions: three Doxa providers and Codex.

**Repair.** Label Codex's 28.22 → 47.39 and 7.35 → 18.99 figures as thin + cu1 → fat + cu1 in Disagreement 1. Delete "adds no new cost information". Set Codex's marginal ratios (about 1.7× clean, about 2.6× edit) beside this item's own marginal clean figure from `profile-probe.r2.log` (18 s → 25 s). Weigh those marginal costs against the 8.5 pp size gain.
In Disagreement 9, either cite Codex's actual baseline → fat + cu1 figure (29.04 s → 47.39 s, about 1.6×) or drop Codex from that comparison.
No measurement needs to change.

### Finding 2 — JF-2: per-build incremental wall time is missing and the gap is undisclosed

**Failed claim.** The prompt (line 59) requires, "once per setting under test, … record per build: … clean and incremental build wall time". The decision presents its measurement as answering that requirement, and it lists its evidence gaps under *"What is unproven"* (lines 742–793). That list does not mention this gap.

**Evidence.** `profile-probe.r2.log:102–104` rebuilds only two profiles, `baseline` and `fat+cu1 (recommended)`. No incremental figure exists for the other ten rows. In particular, none exists for thin + cu1, the owner reference's row, which is the one alternative the decision argues against on build-time grounds.
The only thin + cu1 incremental measurement on record is Codex's 7.35 s (`raw/codex.md:588`).
Per-row clean times do exist in the log (lines 34–56).

**Repair.** Add an entry under *"What is unproven"*. It should state that incremental wall time was recorded for the baseline and recommended profiles only, not per setting as the prompt requires. It should also state that Codex's 7.35 s → 18.99 s is the only thin + cu1 → fat + cu1 incremental measurement on record.
Re-measuring is optional and is the empirical auditor's concern. Disclosure is the minimum repair.

### Finding 3 — JF-1: the self-check description is stale

**Failed claim.** Lines 427–429 describe `decision-self-check.sh` as *"the check an auditor should run first: it asserts … that the title names revision 2, that `review/R68-r1-snapshot.md` hashes to the audited revision-1 digest, …"*.

**Evidence.** The script now asserts that the title names **revision 3** (`decision-self-check.sh:62–63`). It also asserts the r2 snapshot digest (`:73–81`). The decision's own lines 409–412 say the same thing. The paragraph at lines 427–429 therefore contradicts both the script and the decision, and it describes the first check it tells an auditor to run.

**Repair.** Change "names revision 2" to "names revision 3", and add the revision-2 snapshot assertion to the list. The self-check log will then need re-running, because the decision's byte count changes.

## Verdict

**Reject.** The recommendation itself is well evidenced, and none of the findings moves it. However, Finding 1 is a factual misreading inside the adjudication of the decision's central departure from the owner reference. Findings 2 and 3 are, respectively, an undisclosed unmet prompt requirement and a stale statement. Under RUNBOOK §5, acceptance requires no unresolved findings. All three repairs are prose-only.
