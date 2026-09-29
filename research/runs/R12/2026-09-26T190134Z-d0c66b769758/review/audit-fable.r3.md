actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: e755e0b2cd138ba5e304609fca005744888071bda2b7eb7ebe049c9e2d65258c
verdict: reject
unresolved-findings:
  1. F1 (JF-3, JF-4) — the Opus leg's factual claim about ts is not recorded or adjudicated, and the py/ts source commits are called "task-pinned" when they are not
  2. F2 (JF-5, JF-1) — the rule for other gating workflows omits the decision's own merge-queue condition (P5), although published R17 has no `merge_group` trigger; and line 180 contradicts the `re-verify:` line about whether R17 gates today

# Judgment audit — R12 aggregate-required-status-check, revision 3

**Target.** `research/runs/R12/2026-09-26T190134Z-d0c66b769758/review/DECISION.md`, revision 3. I recomputed its sha256 before reading it. The result, `e755e0b2…d65258c`, equals the expected hash.

**Scope.** This audit judges the decision's reasoning and fidelity. The separate empirical audit reruns the scripts; this audit spot-checked them and did not rerun them. It read no `review/audit-*.md` file and no `review/R12-r*-snapshot.md` file. It cites earlier rounds only through the decision's own revision notes.

**Inputs read.**
- The decision.
- `inputs/prompt.md`: sha256 `999cde07…`, byte-equal to the live topic prompt.
- `inputs/EXECUTION.json`: sha256 `acdcbfff…`, byte-equal to live `research/EXECUTION.json` and equal to the hash the decision states.
- `inputs/prerequisites.json`.
- `research/RUNBOOK.md` §2–§5.
- `raw/muse.md` and `raw/opus.md`, spot-read at every cited line.
- R11's `DECISION.md`; its sha256 `410e88e5…` and its `acceptance.json` sha256 `774f7649…` both match `prerequisites.json`.
- `docs/port/PARAMETERS.md`, `docs/port/COMMONALITY.md:31,47`, `docs/port/DIVERGENCE-ANALYSIS.md:91,251`, `docs/port/BASELINE-REVIEW.md:1-10` and `docs/planning/p02/baseline-samples.md:1-10`.
- R17's and R38's published `DECISION.md`.
- The evidence logs, `ci.candidate.yml`, and the local py and ts git objects.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** (F2) | Most cross-references hold. The check counts add up: 18 + 43 + 59 + 8 + 47 + 50 = 225, and the revision-2 base is 212. The star-count deltas match the practice table. The count "7 today" for architecture D equals `plan`, `hygiene`, `workflow-lint`, `check`×2, `msrv-floor` and `install-smoke`. Architecture D's ranking matches Disagreement 8. The one contradiction is between line 180 and the `re-verify:` line (line 201) about R17 — see F2. |
| JF-2 every question answered, every constraint honored | pass | HIGH 1 (does the value depend on R11): line 145. HIGH 2 (hand-rolled expression or third-party action): Disagreement 1, the architecture table, and the ranking of alls-green. HIGH 3 (cross-repo principles): lines 86–96 and 149–159. MEDIUM (drift without an aggregate): line 74, which covers tokio's in-sync list, PROBLEM-15 and rust-analyzer's drift. LOW (`merge_group`): line 141. The landscape has all three bins, the authorities, practice evidence and a per-shape fit (lines 49–82). Every fitness gate is answered or marked `inapplicable` with a reason (line 147). The out-of-scope rule is honored: no owner-Rust prior art is cited, and R11's job set is consumed, not decided. |
| JF-3 `## Engines` is faithful and adjudicates every disagreement | **fail** (F1) | Every other cited leg line was checked and matches its source. These include `raw/muse.md:30, 52, 56, 60, 76, 92-98, 102, 107, 113-121, 147` and `raw/opus.md:5, 50, 84, 130, 136, 248, 321, 343-347, 359-361, 381`. Muse's second ground is now quoted verbatim from `:60`, which repairs revision 2's F1. The factual ts disagreement between the legs, however, is never named — see F1. |
| JF-4 load-bearing claims trace to cited evidence | **fail** (F1, the pin label) | Spot-checked and passing: `DIVERGENCE-ANALYSIS.md:91` and `:251` quoted accurately; `COMMONALITY.md:31` (F025 `py-only \| ADOPT`) and `:47` (F041); `RUNBOOK.md:73-76` (Q17.A lists R12) and `:98-103` (the empirical-auditor override); R11 `DECISION.md:180` and `:283`. Live ts `…/branches/main/protection` still returns 404, re-queried read-only on 2026-09-27. py's `ci-ok` result loop is byte-identical between `b08bccf` and `b55b8c2`; only `needs:` grew from 8 to 10 jobs. The failing item is the "task-pinned commits" label at line 57 — see F1. |
| JF-5 couplings hand over owned choices without deciding them | **fail** (F2) | R04's membership is R12's to decide under R11 `DECISION.md:290`, and the decision handles it correctly. So are R20's pin form and R08's re-grant. The rule for other gating workflows (rule 4, line 38; line 180) omits the P5 condition R12 itself derives — see F2. |
| JF-6 `assumes` lines byte-identical to the live registry | pass | A script compared all five `assumes` values with the value column of `docs/port/PARAMETERS.md`: `ci-job-structure` (8,093 bytes), `msrv-policy`, `rust-edition`, `target-os-matrix` and `license`. All five are equal. Note: the registry read was the working tree, which holds R11's published row fill uncommitted. At `HEAD` that row is still `—`. |
| JF-7 no conflict with accepted or published prerequisite values | pass | `needs:` is exactly R11's six job ids. `plan` is folded in, which takes the aggregate branch of R11's either/or at `:180`. `ci-ok` reads `needs.plan.result` as `:283` requires. No `CONFLICT:` line is needed. Observation, not a finding: R11 `:283` prescribes `if: ${{ always() }}`, and R12 accepts `!cancelled()` as an equivalent. This is not a conflict, because the registered `ci-job-structure` text names both forms and R12's recommendation itself is `always()`. |
| JF-8 evidence scripts exist; claimed counts match the files | pass | All six scripts and their logs exist. Each log's `RESULT` line matches the decision's table: 18, 43, 59, 8, 47 and 50. `shellcheck.log` is empty. Log rows `V-rec-T8`/`T9` = FAIL, `V-py-T8`/`T9` = PASS, `V-naive-T4` = PASS and `V0-empty` match the T1–T9 table. `G1`–`G4` match the guard claims. `S-tokio-long` (46), `S-py-history` (21 revisions) and the nine `S-cancelled-*` outcomes match the prose. The `ci-ok` job in `ci.candidate.yml` matches rule 1 byte for byte in substance: the six-id `needs:`, `always()`, `timeout-minutes: 5`, `permissions: {}`, and the `length > 0 and all(...)` allow-list over `env`-passed `toJSON(needs)`. |
| JF-9 decision shape follows the published contract | pass | The H2s are `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`. No `## Supersedes` is needed, because nothing is published for R12. `### Principles and implementation` is present, the settled row F041 is stated, and a `re-verify:` line is present. `## Empirical check` records host, tool versions, commands, working directory and observed results. |
| JF-10 the recommendation follows from the evidence | pass | Four facts support one aggregate context: R11's multi-context, skip-gated graph; the executed T8/T9 gap in the deny-list; the live drift in rust-analyzer; and the universal app-pinned single aggregate in the surveyed rust-lang and Astral rulesets. Together they support the allow-list, the guard and the source pin. The confidence split in `## Engines` is proportionate. Neither finding would move the rs recommendation. |

Observation, not a finding: `raw/opus.md:381` labels individual listing "Option E", while the decision's E is the single-job shape. The decision quotes only Opus's condition, not the label, so nothing is misattributed.

## Findings

### F1 — JF-3 / JF-4: the Opus leg's ts claim is neither recorded nor adjudicated, and the source commits are mislabeled "task-pinned"

**Failed claims.**
- Line 280: "**Every disagreement below was adjudicated with fresh evidence; none was settled by picking a leg.**"
- Disagreement 7 (line 294) represents Opus only through "missing capability (Opus, `raw/opus.md:84`)".
- Line 57: "py and ts at their task-pinned commits plus their live settings (`S-py-*`, `S-ts-*` …)".

**Evidence.**
- The legs disagree on a fact. `raw/opus.md:78` says: "**ts** (`~/c/ts-launch-blueprint` @ `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`) has a single job, `ci` …". `raw/opus.md:545` repeats this ("single job `ci`"). Muse reports two jobs, `ci` and the advisory `bun-lane` (`raw/muse.md:30`, `:76`).
- Opus's claim is wrong at the very commit it read. `git show cb1cbcb2:.github/workflows/ci.yml` defines `bun-lane:` at line 141, with `continue-on-error: true` at line 144.
- The decision settles this fact silently through `T-ts-jobs2`. It never names the fact as a disagreement, and never records that the Opus leg carried the error. The decision's own revision-2 note says revision 1 "described ts as one job", but it does not trace that error to the leg that supplied it. Readers of `## Engines` therefore cannot see that Opus's missing-capability argument rested partly on a wrong job count, even though that argument's conclusion survives on the live 404.
- The pin label is wrong. The programme's pinned source trees are py `b08bccfb55d05f15e46a83b52c5660b1881d19f5` and ts `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` (`docs/port/BASELINE-REVIEW.md:7-8`, `docs/planning/p02/baseline-samples.md:6-8`). The decision reads py at `b55b8c2` and ts at `e5100b4`, which are later commits. Opus itself separated the pin from HEAD (`raw/opus.md:74`: py "@ `b08bccf…`" versus "At HEAD `b55b8c2…`").
- The substance survives the mislabel. py's `ci-ok` result loop is byte-identical at both commits; `b55b8c2` only adds `release-generation` and `shellcheck` to `needs:`. ts has the same two-job shape at both commits; the diff is 8 added lines. This is a provenance defect, not a wrong result.

**Repair.**
1. Add Opus's ts position, citing `raw/opus.md:78` and `:545`, to the position table or to Disagreement 7.
2. Name the job-count disagreement explicitly, and adjudicate it with `T-ts-jobs2` plus the `cb1cbcb2:141`/`:144` contradiction.
3. Replace "task-pinned commits" with the commits actually read. Cite the programme pins, and state that the evidence is unchanged between the pin and the commit read: the py loop is identical, and the ts job set is identical.

### F2 — JF-5 / JF-1: the rule for other gating workflows omits the decision's own P5 condition, and line 180 contradicts the `re-verify:` line

**Failed claims.**
- Rule 4 (line 38): "any other workflow whose checks must block merging declares its own single required context, or its own `<name>-ok` aggregate".
- Line 180: "R17's scanner, R38's commit-message lint, and any further gating workflow each declare one required context".

**Evidence.**
- The decision itself derives a necessary condition for any required context. Line 141 says: "Without the trigger, the required check never reports and every queue entry deadlocks at 'Expected'". The P5 row says parity "must agree wherever a merge queue is used". B6 and criterion 8 assume that rs uses a queue.
- The line-141 conditions are applied only to `ci.yml`. The handover to other gating workflows does not carry the `merge_group` requirement.
- R17 is `resolved` (`research/CLAUDE.md:23`). Its published `DECISION.md:93` ships `.github/workflows/secret-scan.yml` "triggered on `pull_request` and on `push` to `main`". A search of that file finds zero `merge_group` mentions.
- R17 expects to supply a required check: its `DECISION.md:165` rejects option A partly because it gives "no required status check for R12".
- So applying R12's rule 4 to R17 as published yields a required context that never reports in the merge queue — the deadlock line 141 describes. For contrast, R38 does carry the trigger (`DECISION.md:113`, `merge_group:   # required-check no-op inside the merge queue (F025)`).
- Line 180 and the `re-verify:` line are inconsistent. Line 180 treats R17 and R38 as gating workflows now. The `re-verify:` line (line 201) lists "a second gating workflow joining the template (R17, R38, R13 or R86 making its workflow merge-blocking)" as a *future* trigger that "reopens poller-vs-per-workflow-aggregate". A reader cannot tell whether that reopening condition has already fired.

**Repair.**
1. In rule 4 and in `### Consumers`, add P5 to the handover: each other gating workflow's required context must also trigger on `merge_group` (F025), or the queue deadlocks.
2. Record that published R17 lacks the trigger, and route that to the controller under RUNBOOK §4. Do not decide R17's triggers here.
3. Reconcile line 180 with the `re-verify:` line. Either say that R17 and R38 already gate, and state why the poller question stays closed, or reword line 180 as conditional on those items making their workflows merge-blocking.
