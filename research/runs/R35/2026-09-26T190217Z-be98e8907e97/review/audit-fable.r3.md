actor: fable-judgment-auditor-R35-r3
model: claude-opus-5-5
family: anthropic
decision-sha256: e247adb5d35e6076cebe58db9603d0909f56617aed03fb6a99c34c37c7800540
verdict: reject
unresolved-findings:
1. JF2-1: the decision never scopes its cross-repo principle to `docs/port/DIVERGENCE-ANALYSIS.md`. It then asserts, as a must-agree cross-repo policy and as "this item's requirement", the two rows that the analysis records as unresolved class-F owner calls with harmonize `no`. Details and repair are under `## Findings`.

# R35 coverage-tooling — judgment audit of DECISION.md revision 3

**Scope.** This audit judges reasoning and fidelity only. The empirical audit reruns the scripts separately.

**Target.** `research/runs/R35/2026-09-26T190217Z-be98e8907e97/review/DECISION.md`. Its recomputed `shasum -a 256` is `e247adb5d35e6076cebe58db9603d0909f56617aed03fb6a99c34c37c7800540`, which equals the expected hash.

**Read.**
- The decision in full.
- `inputs/prompt.md`, `inputs/prerequisites.json`, `inputs/parameters.json`, `inputs/PARAMETERS.md` and `manifest.json`.
- `research/RUNBOOK.md` §2, §4 and §5.
- `raw/muse.md` and `raw/opus.md`, at every line the decision cites for a leg position.
- The prerequisite `research/topics/11-ci-workflow-job-structure/DECISION.md`, at every line the decision cites.
- The live `docs/port/PARAMETERS.md`, `docs/port/DIVERGENCE-ANALYSIS.md:147-152` and `research/EXECUTION.json`.
- The evidence logs, scripts and snapshots under `review/evidence/`, spot-checked.

No `review/audit-*.md` file and no `review/R35-r*-snapshot.md` file was opened. No git write, runner command, paid API call or submitting API call was made.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** (part of JF2-1) | Most claims agree across sections: the recipe, the F-row table, the members, `## Engines` and Confidence use the same values, versions and check IDs. One tension remains. The F137 row (`:64`) and D13 (`:325`) call blocking "this item's requirement", while Confidence (`:330`) says of the same in-repo failing gate that "it is the owner's call". The F136 *values* row is labeled "a proposal on the owner call F136 carries (class F)" (`:63`). F136 *location* and F137 *enforcement* carry no such label. |
| JF-2 prompt questions and constraints | **fail** (JF2-1) | The six questions are answered: Q1 (collector table `:121-131`, including the Accuracy row; the runtime comparison is honestly declared a gap at `:133`), Q2 (`:110-117`, tokenless fact `S9a`), Q3 (`:84-98`), Q4 (`:135-154`), Q5 (F138 row, D7) and Q6 (`:222`). Honored constraints: stable only, the edition and MSRV floor (`I1`, `I5`), both OSes (proposed for Linux, stated at `:295`), sources and retrieval dates (`:228-243`), no owner prior art, no runner decision (R32) and no job-graph decision (R11). **Not honored:** `inputs/prompt.md:33` says "Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`". The decision cites that file zero times, while each raw leg cites it three times (`raw/opus.md:59`, `raw/muse.md:25`). |
| JF-3 `## Engines` fidelity and adjudication | pass | Every cited leg position was read at source, and each matches. Muse `:37` gives compiler-inserted counters and says ptrace is "less accurate on optimized/inlined code". Muse makes no unix-signal claim: every `signal` in it means adoption evidence, which is `X14`. Opus `:99` gives ptrace "may still contain minor inaccuracies" and "signals interfere". Muse `:51` says "Doc-tests are included via the tool's `--doc` flag (S_DOC_NOTE)". Muse `:133` and `:158` hold the lines-80 gate and the required-check claim. Opus `:119` says blocking is R12's. Opus `:138-140` has `report` lines without `--workspace`. Opus `:35` and `:51` give 28 projects surveyed, 8 running coverage, and a 6/2 split. Each of D1–D13 is settled with an executed check or a snapshot line. D5 correctly reclassifies Opus's gate-less grcov exclusion. The r2 finding JF3-1 is repaired: each leg's accuracy point is attributed to that leg (`:308`). |
| JF-4 load-bearing claims trace | pass | Spot-checked items: the C3a TOTAL line (`r35-coverage.log:30`: regions 96.97 %, functions 100 %, lines 100 %); C8b/C8c figures 81.71/89.47/75.76 (`:73`); serve binary 5 executed / 13 unexecuted without SIGINT (`:74`) and 18/0 with it (`:53`); main.rs 10/0 (`:49`). tarpaulin README 0.37.4 lines 14, 19-21, 73, 113-119 and 123 say what is quoted. codecov-action README line 49 says "Tokenless uploading is unsupported" with the fork exception. The rustc book snapshot line 125 has "recommended path" and "not currently subject to Rust's usual stability guarantees". The cargo-llvm-cov README lines 14, 618 and 917 match. The maintainer CI `:57-73` shows `1.87`/stable/beta on `ubuntu-24.04` and nightly on `macos-latest`, and `:90-99` shows the `cargo llvm-cov nextest` step. The three adopter workflows contain what `S10` claims: clap installs and runs `cargo tarpaulin` at `:280-283`. The r2 finding JF4-1 is repaired: the runner-up bullet (`:168`) now rests `--engine llvm` on runner parity, not on the signal hazard, and cites `--forward` as the default. |
| JF-5 couplings | pass | The coverage job fills R11's pre-assigned slot exactly: `needs: plan`, a positive `code == 'true'` predicate and one more cache-bearing id (R11 `DECISION.md:291`). The ubuntu budget arithmetic 3 + R04 + coverage = 5, against "roughly six", matches R11 `:278`, `:290` and `:407`. Items handed over rather than decided: the required-check mechanism to R12, the runner, test tiers and unit-test location to R32, tool installation to R42, pins and permissions to R20/R08, and the cache step to R10/R11. The one exception is the class-F content covered by JF2-1, which concerns owner calls, not another item's owned choice. |
| JF-6 assumes lines vs live registry | pass | All five `- assumes` lines are byte-identical to the value cell of the matching row in the live working-tree `docs/port/PARAMETERS.md`, and to `inputs/parameters.json` (checked by exact string comparison). R11's `- owns ci-job-structure` value equals the registry cell. No `owns` line exists, consistent with `inputs/prompt.md:20`. The R42 and R69 rows read as prose are unchanged between `inputs/PARAMETERS.md` and the live registry, and are paraphrased faithfully. |
| JF-7 prerequisite values | pass | `prerequisites.json` pins R11 decision `410e88e5…` and acceptance `774f7649…`. Both equal the live files' sha256. The design uses no value that R11 fixes differently. The licence-gate ruling (`:82`) and the "proposal validated in the implementation phase" status (`:86`) are cited at the correct R11 lines. |
| JF-8 evidence scripts and counts | pass | Every cited log has its script: install, coverage, flags, toolchain, sources, tarpaulin and inputs. `SUMMARY` lines give 8 + 29 + 29 + 7 + 25 + 7 + 128 = **233 PASS, 0 FAIL**, matching the table at `:289`. The five rerun logs each match their committed PASS counts. The live figures quoted at `:162-164` (1,682,448 / 295,600 → 5.69; 8,002,951; 1,469 stars; 51 open issues; llvm-cov 6 answered with a 2.09-day median; grcov 2/8 with a 16.16-day median) all appear verbatim in `r35-sources.log:2-46`. |
| JF-9 decision shape | pass | The H2 headings are `## Decision` (containing the recommendation, version, F-rows, `### Principles and implementation` and `re-verify:` at `:243`), `## Parameters`, `## Empirical check` and `## Engines`. There is no `## Supersedes`, which is correct because nothing is published. This matches RUNBOOK §5. Both members carry every answer-template field. |
| JF-10 recommendation follows from evidence | pass | The collector choice, the `--workspace` correction, the three-format structure, the stable doc-test limit and the no-exclusion stance each follow from executed checks (C4d/C4e, F6a/F6b, F4a/F4b, C5a/C5c/C8a). 95/95/90 over lines-80 follows from the C8b/C8c discriminator, with the functions-metric risk measured (C7b) and confidence set to Medium. The in-repo gate is openly a template argument against the practice majority. The *recommendation* stands. The finding concerns how its class-F parts are labeled. |

## Findings

### JF2-1 — the prompt's scoping document is ignored, and class-F owner calls are presented as settled cross-repo requirements

**Failed claims (quoted).**
- `DECISION.md:64`, F137 row: "the `coverage` job **fails** below the floor, and that failure **must block merging** — this item's requirement".
- `DECISION.md:94`, "Must agree across py, ts, rs" table: "a numeric floor exists, and a CI check that blocks merging **fails** below it (F136, F137)".
- `DECISION.md:325`, D13: "**split**: the requirement is this item's, the mechanism R12's".
- `DECISION.md:86`, where the principle is sourced: "Both legs state this requirement in substance (`raw/muse.md:33`, `raw/opus.md:59`)". No citation of the scoping document appears anywhere in the file.

**Evidence.**
- `inputs/prompt.md:33` gives this instruction: "Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`." A search of `DECISION.md` for `DIVERGENCE` returns 0 matches. Both raw legs cite the file.
- `docs/port/DIVERGENCE-ANALYSIS.md:150` classes F136 as **F**, harmonize **no**: "owner call on whether to depend on an external service".
- `docs/port/DIVERGENCE-ANALYSIS.md:151` classes F137 as **F**, harmonize **no**: "should Rust's coverage gate actually block CI (like py) or ship as inert/uncomment-to-enable scaffolding (like ts)".
- `docs/port/DIVERGENCE-ANALYSIS.md:281` adds: "presented as a live owner call, not a research-answerable question".
- The decision labels only the F136 *values* as "a proposal on the owner call F136 carries (class F)" (`:63`, `:141`).
- The decision's own Confidence line says of the in-repo failing gate "it is the owner's call" (`:330`). That contradicts `:64` and `:325`.

**Consequence.** The owner reads a harmonize-`no`, class-F question as already settled: "must agree across py, ts, rs" and "this item's requirement". The follow-on row for ts and py at `:220` inherits that framing. The recommendation itself may well be right. Its status is misstated relative to the analysis the prompt made binding.

**Repair (prose only; no evidence changes, the recommendation does not move).**
1. In `### Principles and implementation`, cite `docs/port/DIVERGENCE-ANALYSIS.md:147-152`. State the classes it assigns: F134 B, F135 A with harmonize yes, F136 F with harmonize no, F137 F with harmonize no, F138 A with harmonize yes. Scope the "must agree / may vary" table to that principle.
2. Relabel F136 *location* (`:63`) and F137 *enforcement* (`:64`, D13 at `:325`) the way the F136 values already are: a proposal on class-F owner calls. The in-repo gate is the recommendation, and blocking is proposed for the owner's F137 disposition, with the mechanism R12's.
3. In the "Must agree" table (`:94`), either move the F136/F137 row to a "proposed shared policy, pending owner disposition (analysis: class F, harmonize `no`)" label, or record a `BASELINE-REVIEW: F136/F137 — …` line if the decision means to challenge the analysis's harmonize-`no` classification. The decision currently says "this decision raises none" (`:67`).

## Notes (not findings)

- **Codex seat held by Muse.** `## Engines` (`:304`) defers the question of whether substituting Muse for Codex is authorised for R35. The working-tree `research/EXECUTION.json` now lists R35 engines `["muse", "opus"]`, and `research/RUNBOOK.md` §2 records owner decision Q17.A (2026-09-27), which extends the substitution to R35. Both changes are uncommitted and postdate the run's manifest. The deferral is honest. The controller can now close the question.
- **Fixture exit code.** The fixture's serve binary exits 0 after its SIGINT drain. R69's registry row specifies 130. R69 is not an R35 prerequisite, and LLVM's profile writer runs on any normal exit from `main`. The entry-path coverage claim therefore holds as written.
- **Line counts for the serve binary.** The `llvm-cov` text report counts 20 lines for `src/bin/rslbp-serve.rs` (`r35-coverage.log:25`). The decision's "18 of 18" comes from the LCOV-derived count (`:53`). Each figure traces to its own log line.
