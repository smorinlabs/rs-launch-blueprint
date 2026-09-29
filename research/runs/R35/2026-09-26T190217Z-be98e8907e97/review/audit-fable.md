# R35 coverage-tooling — judgment audit of DECISION.md revision 1

actor: audit-fable-R35-r1
model: claude-opus-5-5
family: anthropic
decision-sha256: e597d5f70f1c4e0bb051c4cdc1da277f5b9f2cac73e5d9d4c628f81ba2ef160f
verdict: reject
unresolved-findings:
1. JF-2 / JF-3: the accuracy sub-question is unanswered, and both engines' positions on it are dropped.
   - **Failed claim.** Prompt HIGH Q1 (`inputs/prompt.md:31`) asks for the collectors' "instrumentation mechanisms (LLVM source-based coverage vs. ptrace-based), accuracy, and CI-runtime-cost differences". The decision's collector comparison (`DECISION.md:117-126`) has rows for mechanism, gate flags, branch, doc tests, build isolation, MSRV and `unsafe`, but no accuracy row. A search of the whole decision for `accura|precis` finds nothing. `## Engines` does not list accuracy among the agreements or the disagreements D1–D13.
   - **Evidence.** Both legs answered the question:
     - `raw/opus.md:99` has an "Accuracy notes" row: `cargo-llvm-cov` gives "precise line/region data (README:11)"; tarpaulin's ptrace engine "may still contain minor inaccuracies", and "signals interfere (README:14-17, 114-119)".
     - `raw/muse.md:37` and `raw/muse.md:96` state that the LLVM counters give "source-accurate regions/branches".
   - **Why this bears on the recommendation.** The decision's F135 recommendation depends on a subprocess test that sends `SIGINT` to the serve binary (`C5c`; `C8a` shows that 13 of 18 lines go unexecuted without it). The Opus leg's note says signals interfere with the ptrace engine, which is `cargo-tarpaulin`'s default on Linux x86_64. That is exactly where the ranked runner-up's fitness differs, and the decision never states it. (Runtime cost is correctly declared an evidence gap at `DECISION.md:128`. Only accuracy is silently missing.)
   - **Repair.** Add an "Accuracy" row to the collector comparison table:
     - `cargo-llvm-cov`: compiler-inserted region counters (`raw/opus.md:99`, `raw/muse.md:37`).
     - `cargo-tarpaulin`: ptrace "may still contain minor inaccuracies", and signals interfere (`raw/opus.md:99`, marked "not re-read").
     - `grcov`: inherits its collector.
     
     Then add one sentence under the runner-up (`DECISION.md:163`) or the D-table: the signal-driven entry-path test is a further reason the ptrace default is unfit here, and `--engine llvm` is required. Record accuracy as an agreement of both legs in `## Engines`.
2. JF-4: the Compatibility citation does not support the claim it carries.
   - **Failed claim.** `DECISION.md:191` says: "`cargo-llvm-cov`'s CI installs `llvm-tools-preview` on `1.87`, stable, beta and nightly (`review/evidence/snapshots/sources/cargo-llvm-cov-ci.yml:57-73`)".
   - **Evidence.**
     - Lines 57-73 of the snapshot contain only the toolchain matrix and `runs-on: ${{ matrix.os || 'ubuntu-24.04' }}`.
     - A search of the whole snapshot for `llvm-tools|component` returns no match. No step installs the component. Toolchains arrive through `taiki-e/install-action` with `tool: rust@${{ matrix.rust }}`.
     - `r35-sources.log` check `S11a` asserts only that "cargo-llvm-cov's own CI names a macOS runner".
     - The underlying pairing is still a sound inference: the "Test cargo llvm-cov nextest" step at snapshot lines 90-99 cannot run without the component on every matrix leg. The stated mechanism ("installs") is what has no source.
   - **Repair.** Reword the sentence as: "`cargo-llvm-cov`'s CI runs `cargo llvm-cov nextest` (which requires the component) on `1.87`, stable and beta on `ubuntu-24.04`, and on nightly on `macos-latest` (`cargo-llvm-cov-ci.yml:57-73` for the matrix, `:90-99` for the step)". Drop "installs", or cite the mechanism that provides the component.

## Scope and method

This audit judges reasoning and fidelity. It does not judge execution; the separate empirical audit reruns the scripts. I verified the decision's hash with `shasum -a 256` before reading anything else, and it matched the expected value.

I read the following files:

- the decision in full;
- `inputs/prompt.md`;
- `research/RUNBOOK.md`;
- both raw reports: I checked their hashes and spot-checked about 70 cited lines;
- `manifest.json`, `inputs/prerequisites.json`, `inputs/PARAMETERS.md` and `inputs/EXECUTION.json`;
- the live registry `docs/port/PARAMETERS.md`;
- the prerequisite R11 `DECISION.md` at lines 82, 86, 278, 283, 290, 291 and 407, plus its hash;
- the published decisions R11, R42 and R53, for shape comparison only;
- all six evidence logs and the `cargo-llvm-cov` CI and README snapshots.

I did not read any `review/audit-*.md` file or `review/R*-snapshot.md` file, and I made no git writes, runner calls or network calls.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | pass | <ul><li>Every `report` line carries `--workspace`, both in the recipe and in the claims.</li><li>The function counts agree: the intact fixture has 19 functions; adding the uninstantiated generic makes 20, which gives exactly 95 % (`C7b`). This matches "a single unused generic in a 20-function workspace".</li><li>The recorded timings (12 s and 13 s) match `C2a` and `C3a`.</li><li>F137's requirement-versus-mechanism split matches the R12 coupling row and D13.</li><li>The disagreement table lists D13 before D12. That is cosmetic; all of D1–D13 are present.</li></ul> |
| JF-2 prompt questions and constraints | **fail** | <ul><li>Answered:<ul><li>Q1 (dominance and mechanism; runtime cost declared as a gap);</li><li>Q2 (tokenless Codecov is unsupported except for pull requests from forks to public repositories, `S9a`, README line 49);</li><li>Q3 (the principle and its agreement level);</li><li>Q4 (values and exclusions);</li><li>Q5 (report formats, local and CI);</li><li>Q6 (doc tests).</li></ul></li><li>Constraints honoured: stable only; both OSes (macOS executed, Linux left to P03, and the ubuntu-only job is justified); endpoints and retrieval dates recorded.</li><li>The **accuracy** part of Q1 is not answered. See finding 1.</li></ul> |
| JF-3 Engines fidelity and adjudication | **fail** | <ul><li>D1–D13 match the raw reports at the cited lines. Checked: `muse.md:51` (the `--doc` claim), `:88`, `:104`, `:133`, `:154`, `:158`, `:174`, `:178`, `:199`; `opus.md:5`, `:7`, `:86`, `:92-96`, `:106`, `:110-123`, `:135-143`, `:167-169`, `:219`, `:223-229` (grcov really is under `##### Excluded by gate`), `:276`, `:397-399`.</li><li>Each disagreement is settled with an executed check.</li><li>The identity and seat caveats are honest. The run's `inputs/EXECUTION.json` has no R35 override, so the decision could not resolve the Muse-for-Codex substitution.</li><li>Omission: both legs' accuracy positions (`opus.md:99`; `muse.md:37`, `:96`) are neither represented nor adjudicated. See finding 1.</li></ul> |
| JF-4 load-bearing claims trace to sources | **fail** | <ul><li>Spot-checks that pass:<ul><li>`S1b`: 1,682,448 / 295,600 = 5.69;</li><li>`S4`: 1,469 stars and 51 open issues; tarpaulin 3,021 stars and 30 open issues;</li><li>`S5a`: grcov has 2 answered and 8 unanswered issues, median 16.16 days;</li><li>`S5b`: `cargo-llvm-cov` has 6 answered and 4 unanswered issues, median 2.09 days;</li><li>`S8a` and `S8c`: rustc book line 125;</li><li>`S9a`: codecov-action README line 49;</li><li>`S10`: ratatui, starship and clap carry 0 `fail-under` gates;</li><li>`C8b` and `C8c`: without the `SIGINT` test the totals are lines 81.71, functions 89.47 and regions 75.76; the 95/95/90 floor exits 1 and the lines-80 floor exits 0;</li><li>`C3a`: 100 / 100 / 96.97;</li><li>`C4e`: without `--workspace`, the TOTAL row omits `crates/core`;</li><li>`F4a` and `F4b`: `-Z` is rejected on stable;</li><li>`F6a`: `--html` may not be used together with `--lcov`;</li><li>`T2` and `T3`: the error messages quoted verbatim;</li><li>`I5`: `rust-version = "1.87"`;</li><li>R11 lines 82, 86, 278, 283 and 291. The budget arithmetic is 3 (`:407`) + R04 (`:290`) + coverage = 5, under "roughly six" (`:278`).</li></ul></li><li>Failure: the Compatibility citation at line 191. See finding 2.</li></ul> |
| JF-5 couplings hand over owned choices | pass | <ul><li>R11: the `coverage` slot is used as R11 assigned it (`R11:291`).</li><li>R12 keeps the required-check mechanism.</li><li>R32 keeps the runner, the test tier and where unit tests live.</li><li>R42 keeps how CI installs `just` and `cargo-llvm-cov`; R42's `rust-toolchain.toml` is left unchanged.</li><li>R20 and R08 keep action pins and `permissions:`.</li><li>R69 keeps the `web` feature.</li></ul>None of these choices is decided here. |
| JF-6 `assumes` lines byte-identical to the live registry | pass | I parsed the value column of `docs/port/PARAMETERS.md` (working tree) and of `inputs/PARAMETERS.md`. All five `- assumes` lines are MATCH in both: `msrv-policy`, `rust-edition`, `target-os-matrix`, `license`, `ci-job-structure`. `r35-inputs.log` `X9` agrees. No `owns` line is expected (`prompt.md:20`). |
| JF-7 no conflict with accepted or published prerequisite values | pass | <ul><li>R11 `DECISION.md` sha256 `410e88e5…418c` and `acceptance.json` sha256 `774f7649…eac1` equal `inputs/prerequisites.json`.</li><li>R42's `package-manager-invocation` is used as prose and is consistent: `cargo llvm-cov`, and `rustup component list --installed`.</li><li>R69's `web-extra-surface` row contains "--features web or --all-features" in both the snapshot and the live registry.</li><li>The cache-bearing job count stays within R11's ceiling.</li></ul> |
| JF-8 evidence scripts exist and counts match | pass | <ul><li>All six scripts and their logs are present.</li><li>The `SUMMARY` lines give install 8, coverage 29, flags 29, toolchain 7, sources 25 and inputs 109, for a total of 207 PASS and 0 FAIL. This equals the table at `DECISION.md:273-281`.</li><li>`X3`: 43 distinct `S_*` tokens on 26 lines. I re-counted this independently.</li><li>`shellcheck.log` is present.</li></ul> |
| JF-9 decision shape | pass | <ul><li>The H2s appear in the order `## Decision`, `## Parameters`, `## Empirical check`, `## Engines`, with no `## Supersedes` (this is a first revision).</li><li>`### Principles and implementation` and a `re-verify:` line are inside `## Decision`.</li><li>The settled F-rows F134–F138 are listed.</li><li>This matches RUNBOOK §5 and the published R11, R42 and R53 layouts.</li></ul> |
| JF-10 recommendation follows from the evidence | pass | <ul><li>The collector (one mechanism on both OSes, three gate metrics, 6 of 8 surveyed coverage users) and the component follow from the evidence.</li><li>95/95/90 is offered as a Medium-confidence proposal on the owner's F136 call, with the functions-metric risk measured (`C7b`) and a P03 re-verify trigger.</li><li>The in-repo gate is honestly labelled a template argument that practice does not support.</li></ul> |

## Observations (non-blocking; not findings)

- **The tool sets `cfg(coverage)` by default.** `r35-flags.log` prints `info: cargo-llvm-cov currently setting cfg(coverage); you can opt-out it by passing --no-cfg-coverage`. The decision says "`cfg(coverage)` is not used, because it changes the program under measurement" (`DECISION.md:130`), and "no `cfg(coverage)`" (`:210`). Both statements are true of the template's own source. However, the tool sets that cfg on every crate it builds, so any crate that tests it is measured in a changed form. The decision should acknowledge this, or add `--no-cfg-coverage` to the recipe if the rationale is meant literally.
- **A maintained in-repo gate exists in the decision's own snapshot.** The maintainer's own CI uses in-repo gates: `--fail-under-lines 50` at snapshot lines 96-99 and `--fail-under-lines 70` at lines 103-109. The statement "Practice therefore does not support an in-repo gate" (`DECISION.md:78`) is accurate for the 28 surveyed projects. For the prompt's "cite a maintained reference implementation, or state the evidence gap", this is the closest available reference, although it is a self-test of the tool rather than a project policy.
- **Earlier timing runs are not in the committed logs.** The figures "12 s / 12 s, 17 s / 29 s and 17 s / 16 s" (`DECISION.md:128`) do not appear in any committed log. They are not load-bearing, because the decision disclaims any comparison.
- **The live RUNBOOK now authorises the engine substitution.** `research/RUNBOOK.md:73-76` records Q17.A, which extends the muse+opus substitution to R35. This resolves the controller question the decision left open at `DECISION.md:294`. It is not a defect, because the run's input snapshot predates it.
- **The registry value JF-6 relies on is uncommitted.** Row 12 of `docs/port/PARAMETERS.md` (`ci-job-structure`) holds its published value only in the working tree; HEAD shows `—`. JF-6 passes against the live tree. The controller should make sure that row is committed before acceptance.
