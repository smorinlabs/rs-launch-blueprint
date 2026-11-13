# R35 — coverage-tooling (bundle) — Opus raw report

Run `research/runs/R35/2026-09-26T190217Z-be98e8907e97`, Opus seat (`claude-opus-5-5`), CLI run 2026-09-26. All retrieval dates are `2026-09-26` unless a different date is stated inline. Every crates.io figure comes from `GET https://crates.io/api/v1/crates/<name>` or `.../versions`; every GitHub figure from `GET https://api.github.com/repos/<o>/<r>` (and its `/readme`, `/contents/<path>`, `/issues/<n>/comments` sub-resources) or `GET https://api.github.com/search/issues` / `search/code`; every advisory figure from `https://rustsec.org/packages/<name>.html`. Maintainer documentation was read through the same GitHub API (`/readme`, `/contents/<path>`), not through other hosts, to stay inside this leg's endpoint allowance.

Source repositories were read at their current local heads: py-launch-blueprint `b55b8c2` (2026-09-22) and ts-launch-blueprint `e5100b4` (2026-09-15). **Evidence drift:** several line numbers in the prompt's `## Context` are stale at these heads. The current locations are: py `pyproject.toml:75` (`"pytest-cov>=4.1.0"`), py `Justfile:276-280` (the `coverage` recipe), py `.github/workflows/ci.yml:187-221` (coverage and upload steps), py `pyproject.toml:291-294` (`[tool.coverage.run] branch = true`), ts `.github/workflows/ci.yml:121-125` (the commented Codecov step). The facts the prompt states still hold; only the lines moved. This is drift, not a `BASELINE-REVIEW:`.

Reference stable toolchain for the MSRV gate: **Rust 1.98.1 (48a229cea 2026-09-01)**, read from the local toolchain (`rustc --version` on this host). The channel manifest was not fetched in this leg (endpoint allowance), so this is marked for re-verification. Under `msrv-policy` = "stable minus 2 minor versions", the template floor is **1.96**, and an installed tool must install and run with a toolchain ≤ 1.96.

**Nothing in this leg was executed against coverage tooling.** `cargo-llvm-cov`, `cargo-tarpaulin` and `grcov` are not installed on this host (`cargo llvm-cov --version` → `error: no such command: 'llvm-cov'`), and the `llvm-tools` rustup component is absent (`rustup component list --installed` lists `cargo`, `clippy`, `rust-analyzer`, `rust-docs`, `rust-std`, `rustc`, `rustfmt` only). Installing them would write outside the run directory and reach hosts outside the leg's endpoint allowance, so every command in `### Validation strategy` is a **planned** check, not an executed result.

### Landscape

**Category decided.** The code-coverage *collection mechanism* for a Cargo workspace (how execution counts are gathered), the *driver* that turns them into reports, the *threshold gate* that turns a percentage into a pass/fail exit status, and the *report formats*.

**Three-bin map of the Rust field.**

| Bin | Candidate | What it is |
|---|---|---|
| Built-in / first-party toolchain | `rustc -C instrument-coverage` + rustup component `llvm-tools-preview` (`llvm-profdata`, `llvm-cov`) | The Rust compiler's stable, LLVM source-based coverage instrumentation. It writes `.profraw` files; LLVM's tools merge and report them. No driver: the user orchestrates `RUSTFLAGS`, `LLVM_PROFILE_FILE`, merging and object lists by hand. |
| Established industry standard | `cargo-llvm-cov` (taiki-e) | Cargo subcommand driving `-C instrument-coverage` end to end: builds into a separate target dir, runs tests, merges, reports, gates. |
| Established industry standard | `cargo-tarpaulin` (xd009642) | Cargo subcommand with two engines: a ptrace breakpoint tracer (Linux x86_64 default) and an LLVM engine (default on macOS/Windows). Own config file (`tarpaulin.toml`). |
| Established (older, report-side) | `grcov` (Mozilla) | Aggregator that converts `.profraw`/gcov data into lcov/HTML/Cobertura/covdir; no test driver. |
| Up-and-comer (reporting surface, not a collector) | `actions/upload-code-coverage` (GitHub) | GitHub's own action to upload a Cobertura report into the pull request's code-quality surface; used by `clap`. 101 stars; no GitHub release object (`GET .../releases/latest` → 404), but clap pins its tag `v1.4.2`. |
| External services (gate location, not collectors) | Codecov (`codecov/codecov-action` v7.1.1, 2026-09-17), Coveralls | Hosted comparison and status checks against the base branch. |

No new *collector* has appeared in the Rust field since `cargo-llvm-cov`: the up-and-comer bin holds only a reporting surface. The Rust annual survey does not ask about coverage tooling; this is recorded as an authority gap, not filled by inference.

**Authoritative sources and why each counts.**
- *The rustc book, "Instrumentation-based Code Coverage"* (`rust-lang/rust` `src/doc/rustc/src/instrument-coverage.md`): the Rust project's own documentation of the stable flag. It names `llvm-tools-preview` as "the recommended path" for the LLVM tools, states their interface is "not currently subject to Rust's usual stability guarantees", and documents that doc-test coverage needs `-Z unstable-options --persist-doctests`.
- *rust-lang/rust tracking issues* #84605 (`#[coverage]` attribute, **open**), #79649 (branch coverage, **open**), #79417 (doctest line remapping, **open**): the compiler team's own status of the three features that decide exclusion, branch-metric and doc-test behavior on stable.
- *Maintainers' own documentation*: the `cargo-llvm-cov` README, `docs/cargo-llvm-cov-report.txt`, `src/context.rs` and `.github/workflows/ci.yml`; the `tarpaulin` README and CI workflow; the `codecov-action` README. Each is the primary statement of what the tool does and on which platforms it is tested.
- *RustSec advisory database*: the ecosystem's canonical vulnerability record.
- *crates.io and GitHub metadata* (figures in `#### cargo-llvm-cov`): adoption and maintenance evidence under the prompt's fixed rubric.

**Practice evidence — well-regarded projects surveyed.** I read every file under `.github/workflows/` of 28 projects through the GitHub contents API and searched for `llvm-cov`, `tarpaulin`, `grcov`, `codecov-action`, `fail-under` and `coveralls`. Standing is evidenced by stars (`stargazers_count`) and by being core ecosystem infrastructure.

| Project (stars) | Coverage in CI | Tool | Gate |
|---|---|---|---|
| `starship/starship` (60,051) | yes, `workflow.yml:164-250` | `cargo-llvm-cov` via `taiki-e/install-action`; toolchain installed with `--component llvm-tools-preview` | Codecov upload, token |
| `pola-rs/polars` (39,869) | yes, `test-coverage.yml:53-88` | `cargo-llvm-cov` (`clean --workspace`, then `report --lcov`) | external upload |
| `ratatui/ratatui` (22,749) | yes, `ci.yml:150-172` | `cargo-llvm-cov`, `components: llvm-tools`, stable | Codecov, `fail_ci_if_error: true` |
| `clap-rs/clap` (16,726) | yes, `ci.yml:268-290` | `cargo-tarpaulin --out xml` | `actions/upload-code-coverage` (GitHub-native) |
| `rust-bakery/nom` (10,473) | yes, `ci.yml:183-192` | `cargo-tarpaulin` | external upload |
| `cross-rs/cross` (8,323) | yes, `ci.yml:94…295` | `cargo-llvm-cov` via a local composite action | external upload |
| `rustls/rustls` (7,638) | yes, `build.yml:305-334` | `cargo-llvm-cov`, nightly + `components: llvm-tools` | Codecov, `fail_ci_if_error: false` |
| `getsentry/symbolicator` (443; Sentry production service) | yes, `ci.yml:177-187` | `cargo-llvm-cov --all-features --workspace --lcov` | Codecov |
| `BurntSushi/ripgrep`, `rust-lang/cargo`, `rust-lang/rustup`, `sharkdp/bat`, `eza-community/eza`, `tokio-rs/tokio`, `tokio-rs/tracing`, `tokio-rs/axum`, `hyperium/hyper`, `tower-rs/tower`, `seanmonstar/reqwest`, `launchbadge/sqlx`, `nushell/nushell`, `bytecodealliance/wasmtime`, `astral-sh/uv` | **no coverage step** | — | — |

Findings from the survey:
1. 8 of 28 projects run coverage in CI; 20 do not. Coverage is optional practice in Rust, not a universal norm.
2. Of the 8, **6 use `cargo-llvm-cov`** and 2 use `cargo-tarpaulin`. Every project that adopted coverage recently or rewrote its job (starship, ratatui, polars, rustls) uses `cargo-llvm-cov`.
3. **None of the 8 uses an in-repo `--fail-under` gate.** All 8 send reports to an external surface (Codecov, or GitHub's code-quality upload in clap). Practice evidence therefore does **not** support the in-repo gate recommended below; that recommendation rests on a template-specific argument (see `### Principles and implementation`), and this report says so rather than calling it idiomatic.
4. Wider signal, with a caveat: GitHub code search for workflow files containing `cargo-llvm-cov` returned `total_count` 10,976; for `cargo-tarpaulin`, 4,160 (`GET https://api.github.com/search/code?q=<term>+path:.github/workflows`). These are file-match counts that include forks and duplicate files, and tarpaulin is often written as `cargo tarpaulin`, so they indicate direction (about 2.6 : 1), not adoption share.

**Fit over abstract best.** The template is CLI + library + web service on `ubuntu-latest` and `macos-latest`, stable only, edition 2024. The candidates are judged against that and against the py precedent (external Codecov gate, three local report formats, branch coverage) and the ts precedent (in-repo thresholds, two commented exclusions, gate not wired in CI), in `### Principles and implementation` and per member.

### Principles and implementation

**Shared requirement.** Source: `docs/port/DIVERGENCE-ANALYSIS.md:147-152` (R35 rows F134–F138) and the prompt's decision question. The principle the py and ts repos share is: *test coverage is measured with the ecosystem's native instrumentation, over the shipped source only, and a declared numeric floor turns a coverage drop into a failing check; the developer can read which lines are uncovered.* Agreement level: **policy** (a floor exists, is declared in the repository's reviewed files, and fails a check) plus **capability** (line-level missing-coverage report locally; machine-readable report in CI). The tool, the metric names and the numeric values are ecosystem-specific and may vary.

What must agree across py, ts and rs:
- Native instrumentation for the language (F134, class B).
- Scope is the shipped source; test code is not counted (F135).
- A numeric floor exists and a CI job **fails** below it (F136/F137). ts violates this today: its thresholds are configured (`vitest.config.ts:20-25`) but CI runs `just test` without `--coverage` and the upload is commented out (`ts ci.yml:121-125`). py satisfies it only through Codecov: its own CI comment says "There is no fail_under and nothing else reads coverage.xml" (`py ci.yml:197-198`), so the gate is `.codecov.yml:11-18` evaluated by Codecov's service.
- A human-readable local report with missing lines, plus a browsable report (F138; py `Justfile:279`: `--cov-report=term-missing --cov-report=html --cov-report=xml`).
- The everyday test loop stays coverage-free (ts `docs/tools/vitest.md:89`; py `ci.yml:187-199` runs coverage on one cell only).

What may vary: the tool; metric names (LLVM reports lines, functions and regions on stable; no "statements", and branch coverage is nightly-only); numeric values; and whether a base-branch comparison (py's `target: auto`) exists.

**Essential behaviors and observable acceptance criteria.**
- AC1: `just coverage` on either OS in `target-os-matrix` runs the full non-doc test suite once under instrumentation and exits 0 on the template skeleton.
- AC2: removing a test so that line coverage falls below the floor makes `just coverage` exit non-zero, and the CI `coverage` job fails.
- AC3: the terminal output lists uncovered lines per file; `target/llvm-cov/html/index.html` exists; `target/llvm-cov/lcov.info` exists and contains `SF:` records for `src/` files only (no `tests/` paths).
- AC4: the threshold values appear in exactly one tracked file, and that file is the one CI executes.
- AC5: `just test` builds no instrumented artifacts (no `target/llvm-cov-target/`).

**Architectural alternatives compared before libraries.**

| Alternative | Gate location | Consequence for this template |
|---|---|---|
| A. In-repo gate: driver flags fail the command | reviewed repository file, CI job exit status | Works for every repository generated from the template with no account, secret or OIDC permission. Loses base-branch comparison and patch coverage. |
| B. External service gate (py) | Codecov YAML plus Codecov's status check | Gives no-regression (`target: auto`) and patch coverage. Every generated repository must register with Codecov and grant `id-token: write` (OIDC) or hold a token. Codecov's README states: "Tokenless uploading is unsupported. However, PRs made from forks to the upstream public repos will support tokenless" (`codecov-action` README, "Breaking Changes"); py uses `use_oidc: true` with `id-token: write` (`py ci.yml:169,212-221`). The gate is a service decision outside the repository. |
| C. Configured but not enforced (ts today) | test-runner config only | Violates the shared principle: the floor never fails anything in CI. Rejected as a target state. |
| D. Report-only (the majority of surveyed Rust projects) | none | No floor; the principle is not met. |

Recommendation: **A as the gate**, with B's upload available as an optional, non-gating add-on. Why A over the practice majority (B): a template's CI must pass on the first push of a freshly generated repository. B's gate requires an external account and a permission grant that R08 owns; A needs neither. py's own configuration already relies on OIDC plus a service-side setting, which is a setup step a template user must perform before the gate means anything. F136/F137 are recorded as **owner calls** (`DIVERGENCE-ANALYSIS.md:150-151`, class F); this report recommends A and ranks B second.

**Collector comparison (the library decision inside alternative A).**

| Property | `cargo-llvm-cov` 0.9.1 | `cargo-tarpaulin` 0.37.4 | `grcov` 0.10.7 | raw `-C instrument-coverage` |
|---|---|---|---|---|
| Mechanism | rustc `-C instrument-coverage` (LLVM source-based counters) on every OS | Linux x86_64 default: ptrace breakpoints; macOS/Windows default: LLVM engine (README:19-22) | converts existing `.profraw`; no driver | same counters, hand-driven |
| Same mechanism on `ubuntu-latest` and `macos-latest` | yes | **no** by default (ptrace vs LLVM); yes only with `--engine llvm` everywhere | n/a | yes |
| Threshold gate | `--fail-under-lines`, `--fail-under-functions`, `--fail-under-regions`, `--fail-uncovered-*` (report help `:92-110`) | `--fail-under <PERCENTAGE>` (line only, README:71) | none | none |
| Branch metric on stable | no (`--branch` unstable, #79649 open) | no (`-b, --branch … NOT IMPLEMENTED`, README:72) | n/a | no |
| Doc tests on stable | no (`--doctests` unstable, README:14, #2) | via `--doc`/`--run-types Doctests`; tarpaulin warns LLVM-engine doctests with `should_panic` report nothing (README:123-135) | n/a | no (needs `-Z unstable-options`) |
| Report formats | text, html, lcov, json, cobertura, codecov | Json, Stdout, Xml, Html, Lcov | lcov, html, cobertura, covdir | whatever `llvm-cov` prints |
| Separate instrumented target dir | yes, `<target>/llvm-cov-target` by default (`CARGO_LLVM_COV_TARGET_DIR`) | no by default | n/a | user's choice |
| Accuracy notes | precise line/region data (README:11) | ptrace: "may still contain minor inaccuracies", signals interfere (README:14-17, 114-119) | inherits collector | same as llvm-cov |

**Representative performance.** No benchmark was run in this leg. Stated qualitatively, with the configuration named: `cargo-llvm-cov` adds one additional full debug compile of the workspace (instrumented, into `target/llvm-cov-target/`) plus a test run whose counters cost little per executed region, plus an `llvm-profdata merge` and one `llvm-cov export/report` per requested format. Tarpaulin's ptrace engine stops the process at breakpoints and is known to be slower on test-heavy code; its LLVM engine should cost about the same as `cargo-llvm-cov`. These are architecture-derived expectations, not measurements. The CI-runtime difference on `ubuntu-latest` / `macos-latest` is an **evidence gap**; the planned check `V5` in `### Validation strategy` measures wall time for the recommended tool only.

**How the recommended design preserves each principle.**
- Native instrumentation: `cargo-llvm-cov` drives the compiler's own stable flag, the path the rustc book documents.
- Scope: `cargo-llvm-cov`'s default filename regex excludes `tests/`, `examples/`, `benches/`, `tests.rs` and `*_tests.rs`/`*-tests.rs`, the target dir, the registry and toolchains (README "Exclude file from coverage"). Nothing else is excluded by default (see F135 below).
- Floor fails a check: the thresholds are flags of `cargo llvm-cov report`, run by the `just coverage` recipe that the CI `coverage` job executes. One file holds the values (AC4). This fixes ts's configured-but-unenforced gap and removes py's dependency on a service.
- Missing-lines report: `--show-missing-lines` is the analogue of py's `term-missing`; `--html` of `--cov-report=html`; `--lcov` (or `--cobertura`) of `--cov-report=xml`.
- Coverage-free inner loop: `just test` runs uninstrumented `cargo test`; instrumented artifacts live only under `target/llvm-cov-target/`.

**F135 — exclusions.** On stable Rust the only exclusion mechanism is **file-level** `--ignore-filename-regex`. The item-level `#[coverage(off)]` attribute is nightly-only (#84605 open; README "Exclude code from coverage" pairs it with `cfg(coverage_nightly)`). ts excludes two thin I/O-adapter files because Vitest's in-process coverage cannot see its subprocess tier (`vitest.config.ts:11-19`). In Rust the situation differs: `cargo-llvm-cov` builds the `[[bin]]` target `rslbp` (R49) instrumented in the same run, and integration tests reach it through `CARGO_BIN_EXE_rslbp`, so the binary's `main.rs` should write its own `.profraw` when the subprocess tier executes it. **This is expected behavior, not verified in this leg**; planned check `V4` verifies it. Recommendation: ship **no** `--ignore-filename-regex` entries. Add one only when `V4`-style evidence shows a file cannot be reached by any test tier. Write it as a single Justfile variable with one comment per excluded file, which preserves ts's "explained exclusions only" convention. Do not use `cfg(coverage)` to compile code out of the measured build, because that changes the program under measurement.

**F136 — threshold values.** Proposed values: `--fail-under-lines 95`, `--fail-under-functions 95`, `--fail-under-regions 90`. Provenance: ts calls 95/95/90/95 "the org-standard" (`ts docs/tools/vitest.md:89`, `vitest.config.ts:1-2`). Its port research traces the values to one sibling TypeScript repository (`ts docs/port/TS_PORT_RESEARCH.md:1016`: "Adapt existing repo decision (claim-npm 95/95/90/95 v8 pattern)"). They are **not** a registered owner parameter (`docs/port/PARAMETERS.md` has none). The mapping is not metric-for-metric:
- `lines` → LLVM lines: same meaning.
- `functions` → LLVM functions: Rust counts closures and, with the default `-C instrument-coverage`, unused functions and generics as uncovered functions (rustc book `-C instrument-coverage=yes`), so 95 may be harder in Rust than in TypeScript. This is a re-verify trigger.
- `branches 90` → **regions 90**: regions are sub-line code regions, a closer proxy for py's `branch = true` than lines, but **not equivalent** to branch coverage. True branch coverage is nightly-only.
- `statements` has no LLVM analogue and is dropped.
py's model (project `target: auto` with `threshold: 1%`, patch `target: 80%`, `.codecov.yml:11-18`) has no in-repo equivalent in `cargo-llvm-cov`: it has no base-branch comparison. That capability is lost under alternative A and is the main thing the owner trades.

**F137 — enforcement.** The CI `coverage` job **blocks** by exit status. Whether the job is a *required* status check is R12's aggregate decision; this item only guarantees the job fails.

**F138 — report formats.** Locally: terminal summary with missing lines, HTML, and LCOV (three formats, matching py's three). In CI: the same recipe; the terminal summary goes to the job log and `target/llvm-cov/` is uploaded as a workflow artifact. `cargo-llvm-cov` writes one format per invocation. The recipe therefore runs the tests once with `--no-report` and derives each format with `cargo llvm-cov report`, which the README documents ("Merge coverages generated under different test conditions") and which accepts the gate flags (report help `:92-110`).

**LOW — doc tests.** On stable, doc tests are **not** covered: `--doctests` is unstable (README:14, "Known limitations"; rustc book "Including doc tests"; #79417 open). R32/F132's `cargo test --doc` still runs the doc tests uninstrumented in the `check` job. Coverage therefore counts unit, integration and subprocess tests only. This must be stated in the template docs so a reader does not treat doc-test-only code as tested.

**Minimal realistic example (proposed, not executed).**

```make
# Justfile (fragment) — tool installed via R42's install-tool recipe.
# Floors: the ts family values mapped to LLVM metrics (lines/functions/regions).
coverage_fail_under := "--fail-under-lines 95 --fail-under-functions 95 --fail-under-regions 90"
# Files no test tier can reach; each needs a one-line reason. Empty by default.
coverage_ignore := ""

# Instrumented test run -> HTML + LCOV + terminal summary with missing lines; gate last.
coverage:
    cargo llvm-cov clean --workspace
    cargo llvm-cov --no-report --locked --workspace --all-features
    cargo llvm-cov report --html
    cargo llvm-cov report --lcov --output-path target/llvm-cov/lcov.info
    cargo llvm-cov report --show-missing-lines {{coverage_fail_under}}
```

The reports are written before the gate line so they exist when the gate fails. If R32 selects nextest, the second line becomes `cargo llvm-cov nextest --no-report --locked --workspace --all-features`; nothing else changes. `--all-features` turns on the one feature the template declares: `web`, per R69's registered `web-extra-surface` (`docs/port/PARAMETERS.md:17`). If `coverage_ignore` is ever non-empty, each `report` line gains `--ignore-filename-regex '{{coverage_ignore}}'`.

```yaml
  coverage:
    needs: plan
    if: needs.plan.outputs.code == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha>        # pin per R20
        with:
          persist-credentials: false
      - run: rustup component add llvm-tools-preview
      # cache step per R11 (one more cache-bearing job id on ubuntu-latest)
      # tool install per R42: just install-tool over the cargo-llvm-cov@0.9.1 table row
      - run: just coverage
      - uses: actions/upload-artifact@<sha> # pin per R20
        if: ${{ !cancelled() }}
        with:
          name: coverage
          path: target/llvm-cov/
```

`permissions:` scopes for this job are R08's. The job needs no `id-token: write` because nothing is uploaded to a service.

**Executable acceptance check.** Proposed only: `V1`–`V6` in `### Validation strategy`. **No check was run in this leg.** The only executed observations are the environment probes in the preamble, plus one environment finding: on this host `cargo` resolves to Homebrew (`/opt/homebrew/bin/cargo`) ahead of rustup's proxy. Per `cargo-llvm-cov` `src/context.rs:182-186`, when the toolchain was not installed by rustup the tool bails with `failed to find llvm-tools-preview, please install llvm-tools-preview, or set LLVM_COV and LLVM_PROFDATA environment variables`. The template's contributor docs must say that `just coverage` needs rustup's `cargo` first on `PATH`, or explicit `LLVM_COV`/`LLVM_PROFDATA`.

**BASELINE-REVIEW:** none. No recorded baseline or registered parameter is challenged. The recommendation deliberately does **not** add `llvm-tools-preview` to R42's `rust-toolchain.toml` `components` list (R42 layer 1). It installs the component in the CI job and on first local use instead, so that every contributor does not download LLVM tools they never use.

### Recommendation

One stack: **`cargo-llvm-cov` 0.9.1** driving rustc's stable `-C instrument-coverage`, with the **`llvm-tools-preview`** rustup component supplying `llvm-profdata`/`llvm-cov`. Gate, scope and reports:
- **Gate:** an **in-repo gate** in one `just coverage` recipe: `--fail-under-lines 95 --fail-under-functions 95 --fail-under-regions 90`, applied by `cargo llvm-cov report`.
- **CI:** a dedicated `coverage` job (R11's coverage slot: `needs: plan`, `if: needs.plan.outputs.code == 'true'`, `ubuntu-latest`) that fails below the floor.
- **Scope:** `cargo-llvm-cov`'s default scope (workspace sources; `tests/`, `examples/`, `benches/` excluded) with **no** per-file exclusions by default.
- **Reports:** terminal summary with missing lines, HTML, and LCOV, both locally and as a CI artifact.
- **Doc tests:** not covered on stable; documented as such.
- **Optional:** Codecov upload is not part of the default template.

Two parts of this are recorded **owner decisions** that this research informs: gate location (F136) and block-versus-inert (F137). The recommendation above is the in-repo, blocking gate. The ranked runner-up for the gate is the py model: Codecov via `codecov/codecov-action` v7.1.1 with `use_oidc: true`. The ranked runner-up collector is `cargo-tarpaulin` 0.37.4 with `--engine llvm` forced on every OS.

### Members

#### cargo-llvm-cov

##### Landscape

Established-standard bin. It is the only driver in the field that wraps the compiler's first-party instrumentation end to end and gates on multiple metrics. Its peers are `cargo-tarpaulin` (established, dual engine), `grcov` (report-side aggregator), and the raw rustc flag (first-party, undriven).

##### Principles and implementation

It realises "native instrumentation, shipped-source scope, declared floor, missing-lines report" with a single tool on both OSes. `cargo llvm-cov` builds with `-C instrument-coverage` into `<target>/llvm-cov-target` (README "Environment variables"), sets `LLVM_PROFILE_FILE` for the run, merges `.profraw` with `llvm-profdata`, and reports with `llvm-cov`. It cleans stale instrumented artifacts by default and requires an explicit `cargo llvm-cov clean --workspace` when `--no-report` is used (README "Merge coverages…"). It has no config file: all settings are flags or environment variables (README "Environment variables" lists no threshold variable). That is why the template's single source for thresholds is the Justfile recipe.

##### Dominant choice

**Yes.**
- **Survey:** 6 of the 8 surveyed coverage-running projects use it, including every recent adopter.
- **Downloads:** 2.6 : 1 workflow-file ratio over tarpaulin (caveated), and 5.7× tarpaulin's 90-day downloads.
- **Figures** (endpoints as in the preamble, retrieved 2026-09-26):
  - 90-day downloads `crate.recent_downloads` = **1,696,594**; all-time `crate.downloads` = **7,999,538**.
  - Last release **0.9.1**, `created_at` 2026-09-06T16:20:49Z, not yanked; 4 releases since 2026-03-30.
  - License `Apache-2.0 OR MIT`; `rust_version` **1.87**.
  - GitHub `taiki-e/cargo-llvm-cov`: `stargazers_count` **1,469**, `archived` false, `pushed_at` 2026-09-06T16:20:44Z.
  - Open issues (`search/issues … is:issue is:open` `total_count`) **51**.
  - Issue responsiveness, 10 most recently opened issues (#492–#524): 6 received a first OWNER/MEMBER/COLLABORATOR comment, after 0.01, 0.05, 1.78, 2.40, 2.59 and 11.60 days. The **median over answered issues is 2.09 days**. 4 have no maintainer comment: #524, closed; #512, #498 and #492, open.
  - RustSec: `https://rustsec.org/packages/cargo-llvm-cov.html` returns HTTP 404, meaning no advisory has ever been filed: **0 open advisories**.
- **Maintenance state: `active`.**

##### Qualified shortlist

1. `cargo-llvm-cov` 0.9.1 — passes every gate (see below).
2. `cargo-tarpaulin` 0.37.4 — passes gates 1, 3, 4 and 5. Gate 2 is **undeclared**: no `rust-version` in its `Cargo.toml`; edition 2024 implies ≥ 1.85, so it is probably within 1.96 but unverified. Figures: 90-day **300,122**; all-time **3,048,047**; last release 0.37.4 at 2026-09-21T09:00:51Z; 8 releases since 2026-03-30; `MIT OR Apache-2.0`; `xd009642/tarpaulin` stars **3,021**, not archived, pushed 2026-09-21T15:44:32Z; open issues **30**. Responsiveness over #1838–#1894: 6 answered, median **0.32 days**; 4 without a maintainer comment (1 open, 3 closed). RustSec page returns 404: 0 advisories. State `active`. `unsafe`: its ptrace backend uses `nix` with `ptrace`/`signal` features (`Cargo.toml:65`), and code search finds `unsafe` in 9 Rust files.

Gate answers for `cargo-llvm-cov`:
1. **License:** `Apache-2.0 OR MIT` — compatible.
2. **MSRV:** `rust-version = "1.87"` for installation (`Cargo.toml`), ≤ 1.96 — pass. The README states it runs with Cargo 1.60+ once installed.
3. **Advisories:** 0; `#![forbid(unsafe_code)]` at `src/main.rs:3`.
4. **Platforms:** its CI (`.github/workflows/ci.yml:57-73`) tests `1.87`, stable and beta on `ubuntu-24.04` and nightly on `macos-latest` and Windows. **macOS is tested, but on nightly only**, which is a nuance, not a clean pass for "stable on macOS". Windows `x86_64/i686-pc-windows-msvc` is confirmed; `aarch64-pc-windows-msvc` is known not to work (README "Platform Support"). Windows is not required here.
5. **Features and runtime:** it is an installed binary, not a library dependency, so there are no default features to select in the template and no async-runtime coupling.
6. **Cost:** there is no binary-size cost to the shipped artifact. Compile-time cost is one extra instrumented debug build per coverage run; installation from prebuilt artifacts costs seconds (`[package.metadata.binstall]` points at GitHub release tarballs).

##### Excluded by gate

- `grcov` 0.10.7. License `MPL-2.0` (tool only, never linked; R42 records the owner's 2026-09-12 ruling that no licence check applies to tools, so this alone would not exclude it). It is excluded on **fit**, as a non-driver that needs hand-orchestration and has no gate flag, and on **maintenance**, as `at-risk`:
  - no release since 2026-03-03T18:28:46Z (over 6 months: the rubric trigger);
  - the concrete signal: 8 of the 10 most recently opened issues have no maintainer comment, and the 2 answered took 11.1 and 21.2 days (median 16.2 days).
  - Figures: 90-day **183,020**; all-time **2,608,927**; stars **1,368**; open issues **121**.
  - RustSec `RUSTSEC-2025-0005` (out-of-bounds write in `grcov::covdir::get_coverage`) is patched in `>0.8.20`, so there is no open advisory for 0.10.7.
- Raw `-C instrument-coverage` without a driver is not excluded by a gate. It fails fit: the rustc book's own recipe needs `jq`, a shell loop over test binaries and unstable flags for doc tests, which is the orchestration `cargo-llvm-cov` exists to provide.

##### Up-and-comers

No new collector. `actions/upload-code-coverage` (GitHub; 101 stars; no GitHub release object, tag `v1.4.2` pinned by `clap` at `ci.yml:286` with `permissions: code-quality: write` at `ci.yml:270`) is a new *reporting* surface. It consumes Cobertura, which `cargo-llvm-cov --cobertura` produces. Watch it as a possible first-party alternative to Codecov for the optional upload. It is not a gate today.

##### Fit for this template

- CLI: subprocess tests of `rslbp` should be covered, because the binary is built instrumented (verify with `V4`).
- Library: default scope covers `src/`.
- Web service: `--all-features` (equivalently `web`, R69's `web-extra-surface`) instruments the web surface, and handler tests through the in-process router count.
- Both OSes use the **same** mechanism, so a local macOS result and the CI ubuntu result measure the same thing. Tarpaulin cannot promise that without overriding its defaults.
- It honours `--locked` (R11's rule for every cargo command) and wraps nextest, so it does not pre-empt R32.
- R42's invocation parameter gives `cargo llvm-cov` (executable `cargo-llvm-cov`), installed through the generic `install-tool` recipe with `cargo binstall`. Its `[package.metadata.binstall]` stanza disables quick-install and points at its own GitHub releases.

##### Recommendation

Adopt `cargo-llvm-cov` **0.9.1**, invoked as `cargo llvm-cov` in the `just coverage` recipe shown in `### Principles and implementation`, with gate flags `--fail-under-lines 95 --fail-under-functions 95 --fail-under-regions 90` on the final `report` line.

##### Ranked runner-up

`cargo-tarpaulin` 0.37.4 with `--engine llvm` forced on both OSes and `--fail-under 95`. It ranks second because:
- its gate is line-only;
- its default engine differs between Linux (ptrace, x86_64 only) and macOS (LLVM), so it must be overridden to keep one mechanism;
- its MSRV is undeclared;
- its ptrace path carries `unsafe` and signal-interference caveats (README:114-119).
Its advantages: a `tarpaulin.toml` config file (a natural single source for settings) and doc-test runs through `--doc`.

##### Tradeoffs

- Gains: identical mechanism on both OSes; three gate metrics; an instrumented build isolated from `target/debug`; no `unsafe`; the majority recent choice.
- Costs:
  - no config file, so thresholds live in the Justfile, and CI must run `just`;
  - branch coverage and doc-test coverage need nightly;
  - macOS is tested upstream only on nightly;
  - the LLVM tools' interface is outside Rust's stability guarantees (rustc book), so a toolchain bump can break it (re-verify trigger);
  - `--lcov` shows only line coverage on Codecov (README "GitHub Actions and Codecov"), which matters only if the optional upload is enabled.

##### Parameters

Owns none. Uses `package-manager-invocation` (R42): invoked as `cargo llvm-cov`, installed through `install-tool` with `cargo binstall --locked --no-confirm cargo-llvm-cov@0.9.1`, presence-tested with `command -v cargo-llvm-cov`. Uses `ci-job-structure` (R11) through the coverage slot. Fixed: `msrv-policy` (install MSRV 1.87 ≤ floor 1.96), `license` (compatible tool licence), `target-os-matrix` (runs on both).

##### Migration implications

- `Justfile`: add the `coverage` recipe and the `coverage_fail_under` and `coverage_ignore` variables, and add `cargo-llvm-cov@0.9.1` to R42's tool table.
- `.github/workflows/ci.yml`: add the `coverage` job.
- `.gitignore`: nothing new, because `target/` is already ignored.
- `Cargo.toml`: **no change**. There is no dev-dependency (the prompt's "coverage-tool dev-dependency" does not map to Rust, where the tool is an installed binary), and no `[lints.rust] unexpected_cfgs` entry because the template does not use `cfg(coverage)`.

##### Validation strategy

`V1`–`V6` in `### Validation strategy`, planned. The member-specific core is `V2`: the negative control that the gate actually fails.

##### Confidence & re-verify trigger

- **Confidence: high** that it is the right collector, based on mechanism, platforms and practice.
- **Confidence: medium** on the 95/95/90 values: Rust's function metric counts closures and unused generics, and the template skeleton does not exist yet to measure.
- Re-verify when:
  - a 0.10 release changes flags;
  - #79649 (branch) or #2/#79417 (doc tests) stabilises, which would allow `--branch`/`--doctests` on stable;
  - a Rust release changes `llvm-tools` output;
  - `V1` shows the skeleton below any floor.

##### Sources

- `https://crates.io/api/v1/crates/cargo-llvm-cov` and `/versions` (2026-09-26)
- `https://api.github.com/repos/taiki-e/cargo-llvm-cov` (+ `/readme`, `/contents/src/main.rs`, `/contents/src/context.rs`, `/contents/Cargo.toml`, `/contents/.github/workflows/ci.yml`, `/contents/docs/cargo-llvm-cov-report.txt`) (2026-09-26)
- `https://api.github.com/search/issues?q=repo:taiki-e/cargo-llvm-cov+is:issue+is:open` and the 10 newest issues' `/comments` (2026-09-26)
- `https://rustsec.org/packages/cargo-llvm-cov.html` (404, 2026-09-26)
- `https://crates.io/api/v1/crates/cargo-tarpaulin`, `https://api.github.com/repos/xd009642/tarpaulin` (+ `/readme`, `/contents/Cargo.toml`, `/contents/.github/workflows/rust.yml`) (2026-09-26)
- `https://crates.io/api/v1/crates/grcov`, `https://api.github.com/repos/mozilla/grcov`, `https://rustsec.org/packages/grcov.html`, `https://rustsec.org/advisories/RUSTSEC-2025-0005.html` (2026-09-26)
- `https://api.github.com/search/code?q=cargo-llvm-cov+path:.github/workflows`, `…q=cargo-tarpaulin+path:.github/workflows` (2026-09-26)
- Adopter workflows via `https://api.github.com/repos/<o>/<r>/contents/.github/workflows/<file>` for the 28 projects in `### Landscape` (2026-09-26)
- `research/topics/42-dev-toolchain-provisioning/DECISION.md:22-34` (install and invocation rules)

#### llvm-tools-preview

##### Landscape

First-party toolchain bin: a rustup component that ships `llvm-profdata` and `llvm-cov` built against the same LLVM as `rustc`. Its alternatives are LLVM tools from the OS distribution or an LLVM install (rustc book "Installing LLVM coverage tools"), which must match rustc's LLVM version and be passed through `LLVM_COV`/`LLVM_PROFDATA`.

##### Principles and implementation

Coverage mapping data is LLVM-version-specific; the rustc book says the raw data needs tools "compatible" with the compiler's LLVM, and names this component "the recommended path". `cargo-llvm-cov` locates the tools through the active rustup toolchain. If the component is missing and the toolchain came from rustup, it offers to run `rustup component add llvm-tools-preview --toolchain <tc>`. `CARGO_LLVM_COV_SETUP=yes` answers without a prompt and `=no` fails (`src/context.rs:147-181`).

##### Dominant choice

Yes: it is the only first-party source, and every surveyed `cargo-llvm-cov` adopter installs it. ratatui and rustls use `components: llvm-tools`; starship uses `--component llvm-tools-preview`. Crate figures are **inapplicable**: this is a rustup component, not a crates.io crate, so downloads, crates.io releases, GitHub stars, issue responsiveness and reverse dependencies have no referent. Its maintenance follows the Rust release train (a component of every stable release).

##### Qualified shortlist

1. `llvm-tools-preview` via rustup: passes the gates below.
2. System LLVM through `LLVM_COV`/`LLVM_PROFDATA`: qualified only for non-rustup toolchains, such as this host's Homebrew `cargo`, and only when the system LLVM major version matches rustc's.

Gates for the component:
1. **License:** ships with the Rust distribution under the LLVM licence (Apache-2.0 WITH LLVM-exception); a tool that is never linked. Compatible.
2. **MSRV:** available on every stable toolchain including the 1.96 floor. The canonical name is `llvm-tools-preview` (the rustc book names it; the component is not stable). It can also be added as `llvm-tools` only because of a channel-manifest `[renames.llvm-tools]` entry that rust-lang/rust#119164 ("Manifest issue with \"preview\" components", **open**) reports as a bug; `cargo-llvm-cov` installs `llvm-tools-preview` and calls the short name "an upstream bug" (`src/context.rs:151-152`). Adopters use both spellings (ratatui and rustls `llvm-tools`, starship `llvm-tools-preview`). Pass.
3. **Advisories:** no RustSec entry applies (RustSec covers crates); `unsafe` posture is inapplicable (C++ LLVM tools).
4. **Platforms:** published for `x86_64-unknown-linux-gnu` and `aarch64-apple-darwin` with every stable release (observed indirectly: ratatui runs it on `ubuntu-latest`, starship on `macOS-latest`). Pass.
5. **Features and runtime:** none.
6. **Cost:** tens of MB download per toolchain, not measured in this leg; no effect on the shipped binary.

##### Excluded by gate

None excluded by a gate. Distribution LLVM is not excluded; it is only conditionally qualified, because an LLVM major-version mismatch with rustc produces unreadable profiles (rustc book).

##### Up-and-comers

None; this is the first-party channel. The change to watch is the resolution of rust-lang/rust#119164, which may make the short spelling `llvm-tools` stop working; the template uses `llvm-tools-preview` to be safe either way.

##### Fit for this template

It fits both OSes, and CI adds it with one `rustup component add` line in the `coverage` job. Locally, `cargo-llvm-cov` offers to add it on first use. Keeping it **out** of R42's `rust-toolchain.toml` `components` list means `just test`, `just check` and the other checks never download it. The only caveat is contributors whose `cargo` is not rustup's (this host's Homebrew case), who must put rustup's proxy first on `PATH` or set `LLVM_COV`/`LLVM_PROFDATA`.

##### Recommendation

Install with `rustup component add llvm-tools-preview` in the CI `coverage` job, against the toolchain `rust-toolchain.toml` selects. Presence-test it with `rustup component list --installed` per R42's rule for rustup components. Do not add it to `rust-toolchain.toml`.

##### Ranked runner-up

Add `"llvm-tools"` to `rust-toolchain.toml` `components`. That removes the first-use prompt, but it downloads LLVM tools for every contributor and every CI job, and it modifies R42's resolved layer 1. It would therefore need its own `BASELINE-REVIEW:`; it is not proposed here.

##### Tradeoffs

- On-demand install keeps other jobs and contributors lean, at the cost of a one-time interactive prompt locally, which `CARGO_LLVM_COV_SETUP=yes` removes.
- Tool interfaces are outside Rust's stability guarantee, so a toolchain upgrade can change output. The template pins the tool version through the toolchain and re-verifies on each channel bump (R27).

##### Parameters

Owns none. Assumes the `channel` chosen by R27 in `rust-toolchain.toml` (R42 layer 1). Fixed `target-os-matrix`: both OSes supported.

##### Migration implications

- `.github/workflows/ci.yml` `coverage` job: add one step, `rustup component add llvm-tools-preview`.
- Contributor docs (`CONTRIBUTING.md` or the test docs R32 owns): one paragraph saying that `just coverage` needs rustup's `cargo` on `PATH` and will offer to install the component.
- No change to `rust-toolchain.toml`.

##### Validation strategy

`V1` on a clean rustup toolchain without the component, with `CARGO_LLVM_COV_SETUP=yes`, must install the component and succeed. On a non-rustup `cargo`, it must fail with the `src/context.rs:184` message. Both are planned, not executed.

##### Confidence & re-verify trigger

- **Confidence: high.** It is the documented first-party path.
- Re-verify when rust-lang/rust#119164 closes (either spelling may change), when the component is stabilised under a new name, or when a stable release changes the tools' output format.

##### Sources

- `https://api.github.com/repos/rust-lang/rust/contents/src/doc/rustc/src/instrument-coverage.md` (sections "Installing LLVM coverage tools", "Including doc tests", "`-C instrument-coverage=<options>`") (2026-09-26)
- `https://api.github.com/repos/taiki-e/cargo-llvm-cov/contents/src/context.rs` (lines 144-186) (2026-09-26)
- Adopter workflows: `ratatui/ratatui` `.github/workflows/ci.yml:159-162`, `rustls/rustls` `.github/workflows/build.yml:315-318`, `starship/starship` `.github/workflows/workflow.yml:156-158` (2026-09-26)
- `research/topics/42-dev-toolchain-provisioning/DECISION.md:26` (layer 1, `rust-toolchain.toml` components)

### Compatibility

The two members are designed and tested together:
- **Maintainer's own CI:** `cargo-llvm-cov`'s CI installs toolchains `1.87`, stable, beta and nightly and runs the tool against the matching `llvm-tools-preview` (`.github/workflows/ci.yml:57-73`). The minimum, 1.87, is below the template floor of 1.96.
- **Maintainer's reference example:** its README "GitHub Actions and Codecov" shows `rustup update stable` + `taiki-e/install-action@cargo-llvm-cov` + `cargo llvm-cov --all-features --workspace --lcov`.
- **Shared adopters:** ratatui (`ci.yml:159-165`: `components: llvm-tools` plus `tool: cargo-llvm-cov`, on stable, `ubuntu-latest`), starship (`workflow.yml:156-167`: `--component llvm-tools-preview` plus `cargo-llvm-cov`, a matrix that includes `macOS-latest`), and rustls (`build.yml:315-323`, nightly) all run the pair.
- **Coupled items:**
  - R42: `cargo binstall` installs the pinned `cargo-llvm-cov@0.9.1` from its GitHub release through its `[package.metadata.binstall]` stanza.
  - R11: the `coverage` job is R11's pre-assigned slot (`research/topics/11-ci-workflow-job-structure/DECISION.md:291`).
  - R32: the recipe reads identically for `cargo test` and `cargo nextest`.

### Parameters

- owns: none (the Couplings block lists no owned parameter).
- assumes ci-job-structure = R11's registered value (`docs/port/PARAMETERS.md:12`). Its rule for a check "needing its own toolchain, its own runner or a target/ it must not share": it "becomes its own job with needs: plan and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner". Applied here through R11's coverage slot: job `coverage`, `needs: plan`, `if: needs.plan.outputs.code == 'true'`, `runs-on: ubuntu-latest`, every cargo command `--locked`, one more cache-bearing job id on `ubuntu-latest`.
- assumes package-manager-invocation = R42's registered value (`docs/port/PARAMETERS.md:14`): `cargo llvm-cov` for the `cargo-llvm-cov` executable; presence of the rustup component tested with `rustup component list --installed`, never `command -v`. This parameter is not listed in the prompt's Couplings; it is consumed through R42's resolved decision and recorded here for the synthesizer.
- assumes web-extra-surface = R69's registered value (`docs/port/PARAMETERS.md:17`): "one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets". Used only to justify `--all-features` in the coverage run; not in the prompt's Couplings.
- assumes rust-edition = 2024; msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI; license = MIT OR Apache-2.0; target-os-matrix = ubuntu-latest, macos-latest (fixed, `docs/port/PARAMETERS.md`).
- No `CONFLICT:` line. Running the coverage job on `ubuntu-latest` only is within R11's single-runner allowance for jobs with a stated reason: coverage measures the same source with the same mechanism on both OSes, and the `check` job already runs the tests on both.

### Migration implications

| File | Change |
|---|---|
| `Justfile` | Add a `coverage` recipe (clean → `--no-report` test run → `report --html` → `report --lcov --output-path target/llvm-cov/lcov.info` → `report --show-missing-lines` with the gate flags). Add variables `coverage_fail_under := "--fail-under-lines 95 --fail-under-functions 95 --fail-under-regions 90"` and `coverage_ignore := ""`. Add `cargo-llvm-cov@0.9.1` as a row of R42's tool table. `just test` stays uninstrumented. |
| `.github/workflows/ci.yml` | Add job `coverage` in R11's slot: checkout (R20 pin), `rustup component add llvm-tools-preview`, cache step (R11), tool install through R42's recipe, `just coverage`, `actions/upload-artifact` of `target/llvm-cov/` under `!cancelled()`. Scopes are R08's; no `id-token` needed. |
| `Cargo.toml` | No change. There is no dev-dependency, and no `check-cfg` entry because `cfg(coverage)` is not used. |
| `rust-toolchain.toml` | No change (see member `llvm-tools-preview`). |
| contributor / test docs (owned with R32) | State that doc tests are not counted on stable; that `just coverage` needs rustup's `cargo`; and where reports land (`target/llvm-cov/html/index.html`, `target/llvm-cov/lcov.info`). |
| `.codecov.yml` | Not created. If the owner picks the runner-up (external gate), add a `.codecov.yml` modelled on py's `status.project target: auto` / `patch target: 80%`, and an upload step with `use_oidc: true`, which needs R08 to grant `id-token: write` to that job. |
| follow-on (py, ts; not this repo) | ts: wire `just coverage` into CI so its configured 95/95/90/95 thresholds fail the job (principle: a floor must fail a check). py: optionally add an in-repo `--cov-fail-under`, so the floor survives without the service. Rationale only; changes are a follow-on project. |

### Validation strategy

All checks are **planned; none was executed in this leg** (see preamble). Toolchain: rustup stable (the floor 1.96 and current stable), `cargo-llvm-cov` 0.9.1, on `ubuntu-latest` and on `macos-latest` (or a local aarch64 macOS host with rustup's `cargo` first on `PATH`). Working directory: the generated template root.

- **V1 — positive run.** `CARGO_LLVM_COV_SETUP=yes just coverage`. Expected: exit 0. The terminal shows a per-file table with `Regions`, `Functions` and `Lines` columns and a `TOTAL` row at or above 90/95/95, plus a missing-lines listing. `target/llvm-cov/html/index.html` and `target/llvm-cov/lcov.info` exist.
- **V2 — gate negative control.** Add an untested `pub fn` of about 40 lines to the library (or temporarily raise `--fail-under-lines` to 100), then run `just coverage`. Expected: exit status 1 from the final `cargo llvm-cov report` line; the HTML and LCOV files are still written, because they come before the gate. Revert, and V1 passes again.
- **V3 — scope.** `grep '^SF:' target/llvm-cov/lcov.info`. Expected: only paths under `src/` (and member `src/` directories); no `tests/`, `benches/`, `examples/`, `~/.cargo/registry` or toolchain paths.
- **V4 — subprocess coverage of the binary (the F135 question).** After V1, `awk '/^SF:.*src\/main.rs$/,/^end_of_record/' target/llvm-cov/lcov.info | grep -c '^DA:[0-9]*,[1-9]'`. Expected: greater than 0, meaning lines of `main.rs` were executed by integration tests that spawn `CARGO_BIN_EXE_rslbp`. If it is 0, the subprocess tier is not instrumented. In that case, add `main.rs` to `coverage_ignore` with a comment (ts's convention), or run the tier through `cargo llvm-cov show-env` (README "Get coverage of external tests").
- **V5 — cost.** `time just coverage` versus `time cargo test --locked --workspace --all-features` from the same warm cache, on each runner. Record wall time and `du -sh target/llvm-cov-target`. This fills the performance gap; no claim is made before it runs.
- **V6 — CI wiring.** Push a branch with the V2 change. Expected: the `coverage` job fails, the `check` job passes, and the `coverage` artifact is uploaded. Push a docs-only change. Expected: `coverage` is skipped (`plan` outputs `code=false`).
- **V7 — inner loop stays clean.** `rm -rf target/llvm-cov-target && just test && test ! -d target/llvm-cov-target`. Expected: exit 0.

### Confidence & re-verify trigger

- **Collector choice (`cargo-llvm-cov` + `llvm-tools-preview`): high.** Grounds: the same first-party mechanism on both OSes; the only multi-metric gate; 6 of 8 surveyed adopters; active maintenance; no advisories; no `unsafe`.
- **Gate location and enforcement (in-repo, blocking): medium.** Practice favours external services (8 of 8 surveyed coverage users upload externally, 0 use `--fail-under`). The choice rests on the template argument and is an owner call (F136/F137).
- **Threshold values 95/95/90: medium-low** until V1 runs. They are inherited from one sibling TypeScript repository through ts. Rust's function metric is stricter, and regions only approximate branches.
- **Doc-test and branch limits: high.** Grounds: #79649, #84605 and #79417 are open, and the maintainer documents both limits.
- Re-verify triggers:
  - `cargo-llvm-cov` ≥ 0.10;
  - stabilisation of branch coverage, `#[coverage]` or doc-test coverage;
  - a stable release whose `llvm-tools` output changes;
  - V1 or V4 failing on the skeleton;
  - R32 choosing nextest (swap one recipe line);
  - R12 choosing the aggregate (decides whether `coverage` is required);
  - `actions/upload-code-coverage` publishing a GitHub release (reconsider the optional upload target);
  - the owner choosing the external gate.
- Date-based re-verify: 2027-03-26.

### Sources

Retrieved 2026-09-26 unless stated.
- crates.io API: `https://crates.io/api/v1/crates/cargo-llvm-cov`, `https://crates.io/api/v1/crates/cargo-llvm-cov/versions`, `https://crates.io/api/v1/crates/cargo-tarpaulin`, `https://crates.io/api/v1/crates/cargo-tarpaulin/versions`, `https://crates.io/api/v1/crates/grcov`, `https://crates.io/api/v1/crates/grcov/versions`.
- GitHub API, repositories: `https://api.github.com/repos/taiki-e/cargo-llvm-cov`, `https://api.github.com/repos/xd009642/tarpaulin`, `https://api.github.com/repos/mozilla/grcov`, `https://api.github.com/repos/codecov/codecov-action` (+ `/releases/latest` → v7.1.1, 2026-09-17), `https://api.github.com/repos/taiki-e/install-action` (+ `/releases/latest` → v2.87.21, 2026-09-26), `https://api.github.com/repos/actions/upload-code-coverage`.
- GitHub API, open issues: `https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for the three tools, codecov-action and install-action; responsiveness from `…&sort=created&order=desc&per_page=10` and `https://api.github.com/repos/<o>/<r>/issues/<n>/comments`.
- Maintainer documentation: `https://api.github.com/repos/taiki-e/cargo-llvm-cov/readme`, `/contents/docs/cargo-llvm-cov-report.txt`, `/contents/src/context.rs`, `/contents/src/main.rs`, `/contents/Cargo.toml`, `/contents/.github/workflows/ci.yml`; `https://api.github.com/repos/xd009642/tarpaulin/readme`, `/contents/Cargo.toml`, `/contents/.github/workflows/rust.yml`; `https://api.github.com/repos/codecov/codecov-action/readme`.
- Rust project: `https://api.github.com/repos/rust-lang/rust/contents/src/doc/rustc/src/instrument-coverage.md`; `https://api.github.com/repos/rust-lang/rust/issues/84605`, `/79649`, `/79417`, `/119164` (all `open`).
- RustSec: `https://rustsec.org/packages/cargo-llvm-cov.html` (404), `https://rustsec.org/packages/cargo-tarpaulin.html` (404), `https://rustsec.org/packages/grcov.html`, `https://rustsec.org/advisories/RUSTSEC-2025-0005.html`.
- Practice survey: `https://api.github.com/repos/<o>/<r>/contents/.github/workflows` and each file under it for the 28 projects in `### Landscape`; `https://api.github.com/search/code?q=cargo-llvm-cov+path:.github/workflows` and `…q=cargo-tarpaulin+path:.github/workflows`.
- Source repositories (local, read-only): py-launch-blueprint `b55b8c2`: `pyproject.toml:75,291-294`, `Justfile:276-285`, `.codecov.yml:1-30`, `.github/workflows/ci.yml:169,187-221`. ts-launch-blueprint `e5100b4`: `vitest.config.ts:1-29`, `package.json:35,53`, `.github/workflows/ci.yml:85-125`, `Justfile:174-177`, `docs/tools/vitest.md:89`, `docs/port/TS_PORT_RESEARCH.md:1016`.
- This repository: `docs/port/DIVERGENCE-ANALYSIS.md:147-152`, `docs/port/PARAMETERS.md:7,12,14`, `research/topics/11-ci-workflow-job-structure/DECISION.md:259,291`, `research/topics/42-dev-toolchain-provisioning/DECISION.md:22-34`, run inputs `research/runs/R35/2026-09-26T190217Z-be98e8907e97/inputs/` (prompt identical to the topic prompt; `prerequisites.json` pins R11's decision hash `410e88e5…`).
- Not fetched (endpoint allowance), recorded as gaps: the Rust stable channel manifest (local `rustc 1.98.1` used instead); the annual Rust survey (does not cover coverage tooling, so there is no authority from it); any measured CI-runtime comparison between tools.
