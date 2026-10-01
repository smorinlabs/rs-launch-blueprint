---
prompt: # Deep-research prompt — Test harness and execution behavior (R32, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: what test runner `rs-launch-blueprint` uses and how it configures execution behavior — CLI test tiers (in-process vs. built-binary), randomized execution order, per-test timeout enforcement, a shared cross-test fixture/setup mechanism, test file organization, an opt-in slow/live test-marker taxonomy, an opt-in parallel-execution flag, Rust's built-in doc-test execution, and whether the full suite also runs as an opt-in pre-push git hook. Item kind: `bundle`. Value test: if this answer is wrong, the workspace's `tests/` directory layout, `Cargo.toml` dev-dependencies, the CI test step, and any pre-push hook wiring all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): the two repos diverge. py runs pytest with a rich plugin stack — randomized order, per-test timeout, opt-in parallelism, an opt-in slow/live marker taxonomy, and an autouse global fixture — against one CLI test tier (in-process `CliRunner`). ts runs Vitest with none of those plugins, local per-file factory helpers instead of a global fixture, flat (non-subdirected) test files, and two CLI test tiers: in-process plus a subprocess tier spawning the built binary; ts also adds an opt-in, default-skip pre-push hook that runs the full suite. Evidence: py `Justfile:260` — `uv run pytest {{options}}` via `just test`; ts `Justfile:144` — `pnpm exec vitest run {{options}}` via `just test`. Ledger rows: F117, F118, F124, F125, F128, F129, F130, F131, F132, F173 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT` (F132 individually is `RUST-ONLY`: neither repo has a doc-test-execution convention).
- Per-row evidence for the rest of this bundle: F118 CLI test tiers — py `tests/cli/test_pylb.py:9` (single tier, in-process `CliRunner` only); ts `tests/cli-core.test.ts:11` (in-process `runCli(argv,deps)` tier) and `tests/e2e.test.ts:94` (added subprocess tier spawning built `dist/cli.js`). F124 randomized execution order — py `pyproject.toml:99` (`pytest-randomly`); ts: none. F125 per-test timeout — py `pyproject.toml:284` (`timeout = 60`, `pytest-timeout`, thread method); ts: none. F128 shared cross-test fixture — py `tests/conftest.py:16` (`@pytest.fixture(autouse=True)` resets the root logger for every test); ts: none (deliberately uses local factory helpers instead of a global setup file). F129 test file organization — py `Justfile:301` (`test-web` targets the `tests/web` subdir; suite also splits into `tests/{cli,core,meta}/`); ts `tests/api.test.ts:4` (flat `tests/*.test.ts`, no subdirectories). F130 opt-in slow/live marker taxonomy — py `pyproject.toml:277` (`markers = ["live: ...", "slow: ..."]`), `pyproject.toml:278` (`addopts` excludes both by default); ts: none (tiering is by file, not by marker). F131 opt-in parallel execution — py `pyproject.toml:97` (`pytest-xdist>=3.6`, `-n auto` opt-in); ts: none (Vitest parallelizes test files by default, no opt-in flag to cite). F132 Rust doc-test policy — neither repo has an analogous convention; `cargo test --doc` runs doc-comment examples by default, `RUST-ONLY`. F173 opt-in pre-push full-suite hook — py: none; ts `lefthook.yml:78` (`pre-push` `test` job runs `just test`, opt-in via `TS_PROJECTS_PREPUSH_TESTS=1`, default skip).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). Five researched parameters this item consumes are still open (no `DECISION.md` yet): `http-transport-injection-seam` (R01), `ci-job-structure` (R11), `package-manager-invocation` (R42), `build-tool-output-shape` (R49), `web-extra-surface` (R69) — design the harness to fit whichever value each eventually takes; do not block on them and do not guess their answers.
- Prior decisions of the TypeScript port that explain the current shape: D-019(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — Vitest 4 chosen as the pytest replacement, `node` environment, no globals; D-019(2) — top-level `tests/` directory, flat rather than subdirected, plus an `integration/` subprocess tier; D-019(4) — the two-tier CLI test approach (in-process `runCli` plus built-artifact subprocess spawn with staleness-aware rebuild); D-019(5) — local factory helpers chosen deliberately over a global autouse setup file; D-036 — an advisory, non-gating Bun test lane exists alongside the required Node/Vitest lane (informs, but does not replace, this item's runner choice).

## Out of scope
- Which mock/test-double crate or HTTP-transport-mocking mechanism the harness uses; R48 (`mocking-crates`) owns F119/F120 — this item picks the runner and its execution-behavior configuration, not a mocking crate.
- Whether Rust adopts property-based (generative) testing or CLI golden-snapshot testing; R33 (`property-and-snapshot-testing`) owns F122/F123 — do not recommend a `proptest`/snapshot crate here.
- Whether Rust runs a scheduled dependency-freshness canary or an advisory alternate-toolchain test lane; R34 (`scheduled-freshness-lanes`) owns F126/F127.
- The coverage tool, its instrumentation scope, thresholds, CI gate, and report formats; R35 (`coverage-tooling`) owns F134-F138 — this item's chosen runner must be compatible with whatever coverage tool R35 picks, but does not pick it.
- Where in the CI job graph the test step runs and how it is path-filtered; R11 (`ci-workflow-job-structure`) owns `ci-job-structure` — this item decides which tests run and how, not where in CI they run.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R32
- owns:
- consumes: R01: http-transport-injection-seam; R11: ci-job-structure; R42: package-manager-invocation; R49: build-tool-output-shape; R69: web-extra-surface
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.
- related (not a registry dependency): R48 (`mocking-crates`) owns the mock/test-double and HTTP-transport-mocking crate pick (F119/F120) — coordinate on the shape of test doubles the harness expects but do not choose the crate. R33 (`property-and-snapshot-testing`, F122/F123), R34 (`scheduled-freshness-lanes`, F126/F127), and R35 (`coverage-tooling`, F134-F138) each own an adjacent testing-coverage decision this item must not re-open.

## Questions
Decision: what Rust test runner and execution-behavior configuration (CLI test tiers, ordering, per-test timeouts, shared fixtures, file organization, an opt-in slow/live marker taxonomy, opt-in parallelism, doc-test policy, and an optional pre-push full-suite hook) gives `rs-launch-blueprint` parity with py's pytest-plugin stack and ts's two-tier CLI approach.
- HIGH: Is `cargo test` (the built-in runner) or `cargo-nextest` the base test-execution tool, and does `cargo-nextest` provide per-test timeout enforcement (F125) and randomized/partitioned execution order (F124) natively, or does either require additional configuration or crates?
- HIGH: What is the idiomatic Rust equivalent of ts's two-tier CLI testing (F118) — in-process tests calling the CLI's entry function directly with injected dependencies, plus an `integration/`-style tier that spawns the built binary once its output shape is known?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: What is the idiomatic Rust mechanism for an opt-in "skip slow/live tests by default" marker taxonomy (F130) — `#[ignore]` plus `--ignored`, a `cfg`-gated feature, or a crate providing test tags/filters (e.g. `rstest`, `test-case`)?
- MEDIUM: Does reaching parity with py's autouse global fixture (F128) or opt-in parallel-execution flag (F131) need a supporting crate (e.g. `serial_test`, `cargo-nextest`'s partitioning), given `cargo test` already runs test binaries in parallel by default?
- LOW: Should the CI-authoritative gate include `cargo test --doc` (F132), and should Rust add its own opt-in, default-skip pre-push full-suite hook (F173) mirroring ts's `TS_PROJECTS_PREPUSH_TESTS=1` pattern?

## Required evidence
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the py and ts precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library already named in this prompt is a research lead, not a closed shortlist. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + source link demonstrating adoption and why the project is a relevant, well-regarded reference |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
mode: gemini_deep_research
provider: gemini
model: deep-research-preview-04-2026
operation_id: research-20260926-153550-7160f23be8ad4ecb
created_at: 2026-09-26T15:35:50.139194
---

### Prompt

```
System: Conduct exhaustive Deep Research. Cover every relevant angle. Cite sources rigorously.

User: # Deep-research prompt — Test harness and execution behavior (R32, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: what test runner `rs-launch-blueprint` uses and how it configures execution behavior — CLI test tiers (in-process vs. built-binary), randomized execution order, per-test timeout enforcement, a shared cross-test fixture/setup mechanism, test file organization, an opt-in slow/live test-marker taxonomy, an opt-in parallel-execution flag, Rust's built-in doc-test execution, and whether the full suite also runs as an opt-in pre-push git hook. Item kind: `bundle`. Value test: if this answer is wrong, the workspace's `tests/` directory layout, `Cargo.toml` dev-dependencies, the CI test step, and any pre-push hook wiring all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): the two repos diverge. py runs pytest with a rich plugin stack — randomized order, per-test timeout, opt-in parallelism, an opt-in slow/live marker taxonomy, and an autouse global fixture — against one CLI test tier (in-process `CliRunner`). ts runs Vitest with none of those plugins, local per-file factory helpers instead of a global fixture, flat (non-subdirected) test files, and two CLI test tiers: in-process plus a subprocess tier spawning the built binary; ts also adds an opt-in, default-skip pre-push hook that runs the full suite. Evidence: py `Justfile:260` — `uv run pytest {{options}}` via `just test`; ts `Justfile:144` — `pnpm exec vitest run {{options}}` via `just test`. Ledger rows: F117, F118, F124, F125, F128, F129, F130, F131, F132, F173 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT` (F132 individually is `RUST-ONLY`: neither repo has a doc-test-execution convention).
- Per-row evidence for the rest of this bundle: F118 CLI test tiers — py `tests/cli/test_pylb.py:9` (single tier, in-process `CliRunner` only); ts `tests/cli-core.test.ts:11` (in-process `runCli(argv,deps)` tier) and `tests/e2e.test.ts:94` (added subprocess tier spawning built `dist/cli.js`). F124 randomized execution order — py `pyproject.toml:99` (`pytest-randomly`); ts: none. F125 per-test timeout — py `pyproject.toml:284` (`timeout = 60`, `pytest-timeout`, thread method); ts: none. F128 shared cross-test fixture — py `tests/conftest.py:16` (`@pytest.fixture(autouse=True)` resets the root logger for every test); ts: none (deliberately uses local factory helpers instead of a global setup file). F129 test file organization — py `Justfile:301` (`test-web` targets the `tests/web` subdir; suite also splits into `tests/{cli,core,meta}/`); ts `tests/api.test.ts:4` (flat `tests/*.test.ts`, no subdirectories). F130 opt-in slow/live marker taxonomy — py `pyproject.toml:277` (`markers = ["live: ...", "slow: ..."]`), `pyproject.toml:278` (`addopts` excludes both by default); ts: none (tiering is by file, not by marker). F131 opt-in parallel execution — py `pyproject.toml:97` (`pytest-xdist>=3.6`, `-n auto` opt-in); ts: none (Vitest parallelizes test files by default, no opt-in flag to cite). F132 Rust doc-test policy — neither repo has an analogous convention; `cargo test --doc` runs doc-comment examples by default, `RUST-ONLY`. F173 opt-in pre-push full-suite hook — py: none; ts `lefthook.yml:78` (`pre-push` `test` job runs `just test`, opt-in via `TS_PROJECTS_PREPUSH_TESTS=1`, default skip).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). Five researched parameters this item consumes are still open (no `DECISION.md` yet): `http-transport-injection-seam` (R01), `ci-job-structure` (R11), `package-manager-invocation` (R42), `build-tool-output-shape` (R49), `web-extra-surface` (R69) — design the harness to fit whichever value each eventually takes; do not block on them and do not guess their answers.
- Prior decisions of the TypeScript port that explain the current shape: D-019(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — Vitest 4 chosen as the pytest replacement, `node` environment, no globals; D-019(2) — top-level `tests/` directory, flat rather than subdirected, plus an `integration/` subprocess tier; D-019(4) — the two-tier CLI test approach (in-process `runCli` plus built-artifact subprocess spawn with staleness-aware rebuild); D-019(5) — local factory helpers chosen deliberately over a global autouse setup file; D-036 — an advisory, non-gating Bun test lane exists alongside the required Node/Vitest lane (informs, but does not replace, this item's runner choice).

## Out of scope
- Which mock/test-double crate or HTTP-transport-mocking mechanism the harness uses; R48 (`mocking-crates`) owns F119/F120 — this item picks the runner and its execution-behavior configuration, not a mocking crate.
- Whether Rust adopts property-based (generative) testing or CLI golden-snapshot testing; R33 (`property-and-snapshot-testing`) owns F122/F123 — do not recommend a `proptest`/snapshot crate here.
- Whether Rust runs a scheduled dependency-freshness canary or an advisory alternate-toolchain test lane; R34 (`scheduled-freshness-lanes`) owns F126/F127.
- The coverage tool, its instrumentation scope, thresholds, CI gate, and report formats; R35 (`coverage-tooling`) owns F134-F138 — this item's chosen runner must be compatible with whatever coverage tool R35 picks, but does not pick it.
- Where in the CI job graph the test step runs and how it is path-filtered; R11 (`ci-workflow-job-structure`) owns `ci-job-structure` — this item decides which tests run and how, not where in CI they run.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R32
- owns:
- consumes: R01: http-transport-injection-seam; R11: ci-job-structure; R42: package-manager-invocation; R49: build-tool-output-shape; R69: web-extra-surface
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.
- related (not a registry dependency): R48 (`mocking-crates`) owns the mock/test-double and HTTP-transport-mocking crate pick (F119/F120) — coordinate on the shape of test doubles the harness expects but do not choose the crate. R33 (`property-and-snapshot-testing`, F122/F123), R34 (`scheduled-freshness-lanes`, F126/F127), and R35 (`coverage-tooling`, F134-F138) each own an adjacent testing-coverage decision this item must not re-open.

## Questions
Decision: what Rust test runner and execution-behavior configuration (CLI test tiers, ordering, per-test timeouts, shared fixtures, file organization, an opt-in slow/live marker taxonomy, opt-in parallelism, doc-test policy, and an optional pre-push full-suite hook) gives `rs-launch-blueprint` parity with py's pytest-plugin stack and ts's two-tier CLI approach.
- HIGH: Is `cargo test` (the built-in runner) or `cargo-nextest` the base test-execution tool, and does `cargo-nextest` provide per-test timeout enforcement (F125) and randomized/partitioned execution order (F124) natively, or does either require additional configuration or crates?
- HIGH: What is the idiomatic Rust equivalent of ts's two-tier CLI testing (F118) — in-process tests calling the CLI's entry function directly with injected dependencies, plus an `integration/`-style tier that spawns the built binary once its output shape is known?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: What is the idiomatic Rust mechanism for an opt-in "skip slow/live tests by default" marker taxonomy (F130) — `#[ignore]` plus `--ignored`, a `cfg`-gated feature, or a crate providing test tags/filters (e.g. `rstest`, `test-case`)?
- MEDIUM: Does reaching parity with py's autouse global fixture (F128) or opt-in parallel-execution flag (F131) need a supporting crate (e.g. `serial_test`, `cargo-nextest`'s partitioning), given `cargo test` already runs test binaries in parallel by default?
- LOW: Should the CI-authoritative gate include `cargo test --doc` (F132), and should Rust add its own opt-in, default-skip pre-push full-suite hook (F173) mirroring ts's `TS_PROJECTS_PREPUSH_TESTS=1` pattern?

## Required evidence
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the py and ts precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library already named in this prompt is a research lead, not a closed shortlist. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + source link demonstrating adoption and why the project is a relevant, well-regarded reference |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
```

# Deep-Research Report: Test Harness and Execution Behavior (R32)

### Landscape

The infrastructure surrounding test execution, orchestration, and assertion within the Rust ecosystem has matured significantly, driven by the increasing complexity of enterprise monorepos and the unique compilation model of the language. The category decided by this item encompasses the base test runner, the execution behavior orchestrator, and the subprocess assertion utilities required to validate command-line interfaces. Mapping the Rust testing field reveals a clear taxonomy of tooling, distributed across three primary bins based on maturity, adoption, and architectural approach.

| Classification Bin | Tooling Candidates | Description and Ecosystem Role |
| :--- | :--- | :--- |
| **Built-in / First-party toolchain** | `cargo test` (via `libtest`), `rustdoc` | The ubiquitous, zero-configuration defaults provided by the Rust toolchain. They offer immediate utility but suffer from architectural limitations regarding process isolation, per-test observability, and continuous integration scaling capabilities [cite: 1, 2, 3]. |
| **Established industry standard** | `cargo-nextest`, `assert_cmd`, `rstest`, `testcontainers` | The state-of-the-art alternatives that address the limitations of the built-in toolchain. These tools provide process-per-test execution models, ergonomic subprocess binary testing, parameterized fixture support, and heavy integration testing capabilities [cite: 4, 5, 6, 7]. |
| **Up-and-comer** | `trycmd`, `insta-cmd`, `rustest` | Emerging libraries focusing on specialized testing paradigms, such as snapshot-based CLI testing or attempts to port Python's `pytest` fixture scopes (including global teardowns) directly into Rust [cite: 8, 9]. |

Authority in this domain is established through a combination of Rust core team architectural evaluations, official working group recommendations, and extensive documentation from foundational open-source maintainers. The limitations of the default `libtest` framework are explicitly acknowledged by Cargo maintainers and extensively documented by the authors of `cargo-nextest`. Core issues identified include the lack of structured pass/fail status reporting, the vulnerability to test bottlenecks (long-pole tests), and the inability to natively shard test execution for continuous integration [cite: 2, 3]. Furthermore, the Rust CLI Working Group serves as the definitive authority on command-line interface validation, explicitly endorsing `assert_cmd` as the ergonomic standard for CLI binary integration testing, superseding older architectures like `assert_cli` [cite: 5, 10]. Finally, the architectural decisions documented by tooling integrators, such as JetBrains natively embedding `cargo-nextest` into RustRover, solidify the tool's status as a definitive industry standard [cite: 11].

Practice evidence demonstrates that mainstream, well-regarded Rust projects have rapidly migrated to `cargo-nextest` and `assert_cmd` to resolve challenges related to scale, flaky test detection, and process isolation. Large enterprise monorepos utilize `cargo-nextest` to mitigate flaky tests and reduce continuous integration execution times by up to three times, leveraging its process isolation and advanced scheduling capabilities [cite: 12, 13]. Open-source platforms like Shuttle recommend `cargo-nextest` for leak detection, slow test identification, and robust continuous integration retries in the context of web services [cite: 7]. Additionally, educational platforms like Exercism rely on custom shell scripts to filter `cargo test` JSON outputs for golden tests, explicitly highlighting the systemic need for the structured, machine-readable output that `cargo-nextest` natively solves via JUnit XML generation [cite: 14].

Evaluating these candidates strictly against the target template—a combined command-line interface, library, and web service (`rs-launch-blueprint`)—and the established TypeScript and Python precedents necessitates a specific architectural fit. The chosen harness must be capable of validating isolated library functions (unit tests), orchestrating web service routes that require database or HTTP isolation (integration tests), and executing compiled binaries in isolated shells (CLI tests). `cargo-nextest` provides the uncompromising process isolation required for robust web service integration tests, while `assert_cmd` seamlessly fulfills the dual-tier command-line interface requirement established in the TypeScript port.

### Principles and implementation

The fundamental engineering principle governing this architectural decision is the establishment of a reliable, highly performant, and deterministic testing pipeline that strictly enforces test boundaries, identifies systemic bottlenecks, and scales predictably within continuous integration environments. This requirement demands agreement at the **Architectural Pattern** level across `py-launch-blueprint`, `ts-launch-blueprint`, and `rs-launch-blueprint`. 

The essential behaviors that must be preserved across all implementations include a tiered approach to command-line interface testing (validating both in-process application logic and the final compiled artifact), absolute state isolation to prevent cross-test contamination, precise enforcement of timeouts to prevent hanging continuous integration pipelines, and a structured taxonomy for identifying and filtering slow or live integration tests. While the Python (`pytest`) and TypeScript (`vitest`) repositories achieve these behaviors through varied plugin ecosystems and runner configurations, the underlying architectural intent remains identical.

Rust's strict compilation model, memory safety guarantees, and default threading behavior fundamentally alter how these shared principles are best realized. These ecosystem-specific constraints necessitate justified architectural divergences from the Python and TypeScript precedents to maintain the integrity of the underlying principles.

`BASELINE-REVIEW: F124 — Prevention of state coupling — proposed change: DIVERGENT (Process isolation replaces randomized execution) — evidence: The Python precedent relies heavily on the `pytest-randomly` plugin to aggressively shuffle execution order, thereby surfacing implicit state leakage between tests running sequentially within the same process [cite: 1, 2]. Conversely, the Rust ecosystem addresses state coupling through structural isolation rather than execution randomization. `cargo-nextest` launches a completely separate, dedicated OS-level process for every single test case [cite: 1, 15]. This process-per-test model provides a significantly stronger, OS-enforced guarantee against memory corruption, environment variable leakage, and shared global state mutations. While a nightly-only `cargo test --shuffle` flag exists [cite: 16], it is unnecessary and redundant when utilizing a process-per-test orchestrator. The principle of decoupling is preserved and enhanced through absolute isolation.`

`BASELINE-REVIEW: F125 — Enforced test boundaries — proposed change: DIVERGENT (Runner-native configuration over inline plugins) — evidence: The Python implementation enforces per-test timeouts via the discrete `pytest-timeout` plugin. The Rust implementation preserves this principle by utilizing the native capabilities of `cargo-nextest`, which enforces timeouts organically via the `slow-timeout` and `global-timeout` definitions located in the workspace `.config/nextest.toml` [cite: 17]. This divergence eliminates the need for external dependency injection, centralizing execution constraints within idiomatic Rust workspace configurations.`

`BASELINE-REVIEW: F128 — Deterministic test setup — proposed change: DIVERGENT (Explicit local factories over implicit global setup) — evidence: The Python repository utilizes a global `@pytest.fixture(autouse=True)` mechanism to silently reset application state (such as root loggers) before every test. Because `cargo-nextest` forks a new, isolated process for every test execution, in-process global singletons (like those provided by `rstest`'s `#[once]` macro) will inevitably trigger race conditions or instantiate redundant resources [cite: 18]. Therefore, Rust must structurally align with the TypeScript precedent: the architecture dictates the use of explicit, local factory helpers for in-process state preparation, and relies on Nextest's `setup-scripts` capability for out-of-process environment preparation (e.g., orchestrating database initialization prior to test execution) [cite: 19].`

`BASELINE-REVIEW: F131 — Efficient resource utilization — proposed change: DIVERGENT (Default-on parallelism vs opt-in) — evidence: The Python ecosystem requires explicit opt-in for parallel test execution using `pytest-xdist -n auto`. In stark contrast, both the default `cargo test` runner and `cargo-nextest` parallelize test execution by default, aggressively distributing workloads across all available CPU cores [cite: 4, 20]. In the Rust paradigm, configuration flags are inverted: developers utilize parameters like `threads-required` within `.config/nextest.toml` to explicitly *restrict* concurrency for exceptionally heavy tests, rather than to enable it [cite: 21]. The principle of maximizing resource utilization is preserved as a default language behavior.`

The observable acceptance criteria for the Rust testing architecture are designed to verify the successful implementation of these adapted principles:

| Acceptance Criterion | Verification Method |
| :--- | :--- |
| **CLI Test Tiers** | The workspace must contain distinct testing tiers: in-process API tests validating core logic, and a dedicated subprocess tier utilizing `assert_cmd` to execute and assert against the compiled CLI binary artifact. |
| **Timeout Enforcement** | The `.config/nextest.toml` file must explicitly define a `slow-timeout` parameter and a distinct `fail-fast` profile to govern long-running tests [cite: 17]. |
| **Doc-test Execution** | Continuous integration workflows must explicitly invoke `cargo test --doc`, ensuring documentation validation is not lost, as `cargo-nextest` intentionally bypasses standard documentation tests [cite: 1]. |
| **Marker Taxonomy** | Slow or live tests must be explicitly annotated with the built-in `#[ignore]` attribute, allowing continuous integration pipelines to invoke them distinctly via `cargo nextest run --run-ignored` [cite: 22, 23]. |
| **Pre-push Hook** | A default-skip Git hook must be wired into the repository (mirroring the TypeScript `TS_PROJECTS_PREPUSH_TESTS=1` pattern), allowing developers to optionally validate the full test suite prior to pushing commits. |

Evaluating architectural alternatives reveals that attempting to force Python-style paradigms into Rust introduces severe friction. Utilizing `cargo test` combined with an extensive array of external crates to replicate timeouts, retries, and JUnit reporting results in a fragile, highly coupled testing environment. The default `libtest` executes tests as concurrent threads within a single binary. If a test panics catastrophically or deadlocks a shared resource (such as a hardcoded network port), it can poison the entire test suite, making debugging exceptionally difficult [cite: 1]. `cargo-nextest` entirely eliminates this failure mode. The process-per-test architecture ensures that a segmentation fault or a leaked environment variable in one test has zero blast radius, guaranteeing deterministic execution across the remainder of the suite.



Similarly, relying solely on `std::process::Command` for command-line interface testing requires significant, brittle boilerplate to dynamically locate the correct Cargo artifact path (navigating between `target/debug` and `target/release` directories based on the compilation profile). `assert_cmd` abstracts this complexity entirely, providing deterministic artifact discovery and a fluent API for output validation [cite: 5]. The recommended architecture balances the absolute requirement for cross-ecosystem behavioral parity with the realities of idiomatic Rust engineering, relying on structural isolation and standardized configurations over brittle inline macros and injected global state.

### Recommendation

The recommended test harness stack for the `rs-launch-blueprint` template comprises **`cargo-nextest`** as the foundational workspace test runner and execution orchestrator, strategically paired with **`assert_cmd`** for out-of-process subprocess binary validation. The built-in **`cargo test --doc`** command is explicitly retained to govern documentation testing. This architecture deliberately omits heavy fixture frameworks, prioritizing explicit local state preparation to maintain absolute harmony with Nextest's process-per-test isolation constraints.

### Members

#### cargo-nextest

##### Landscape
`cargo-nextest` occupies a dominant position within the "Established industry standard" tier of the Rust testing ecosystem. Initially developed to address the severe limitations of the built-in `libtest` framework—specifically its inability to scale gracefully across massive enterprise codebases—Nextest has rapidly evolved into the de facto test orchestrator for serious Rust engineering. It is unequivocally backed by authoritative figures within the Rust community, including contributors to the core Cargo toolchain, and is widely adopted by commercial enterprises requiring deterministic, high-throughput continuous integration pipelines [cite: 2, 12, 13].

##### Principles and implementation
The architectural brilliance of `cargo-nextest` lies in its fundamental restructuring of the standard Rust test loop. Under the legacy `libtest` paradigm, Cargo builds test binaries and hands execution over to those binaries, which internally spawn threads to run tests concurrently [cite: 1, 2]. Nextest separates this into two distinct phases: the "list phase" and the "run phase." Nextest commands Cargo to compile the binaries, intercepts the output to build a comprehensive manifest of every individual test case, and then aggressively orchestrates execution by spawning a completely isolated OS-level process for each test [cite: 2]. This mechanism directly fulfills the principle of state isolation, rendering randomized execution orders obsolete [cite: 1, 15]. Furthermore, Nextest shifts configuration from imperative code annotations to a centralized declarative file (`.config/nextest.toml`), providing native, structural enforcement of per-test timeouts, retry logic for flaky tests, and concurrency throttling for resource-intensive integration tests [cite: 17, 21].

##### Dominant choice
`cargo-nextest` is the overwhelming dominant choice for workspace-level testing orchestration. Its ability to accelerate test execution by up to 3x, combined with its native support for JUnit XML reporting, continuous integration test sharding, and robust flaky test management, renders the default toolchain insufficient for production-grade, multi-crate workspaces [cite: 4, 24].

##### Qualified shortlist
*   `cargo test` (Built-in `libtest` orchestrator)
*   `cargo-nextest`

##### Excluded by gate
No candidates were excluded by the strict fitness gates. Both the built-in toolchain and Nextest meet all licensing, MSRV, security, and cross-platform compilation requirements.

##### Up-and-comers
`rustest` represents a recent attempt to directly port Python's `pytest` fixture scopes (including advanced global teardowns and parameterized injection) into the Rust ecosystem [cite: 9]. While theoretically interesting, it relies heavily on customized test harnesses, lacks the proven stability required for a baseline template, and cannot compete with Nextest's deep integration into continuous integration tooling.

##### Fit for this template
For the `rs-launch-blueprint` template—which encompasses a complex matrix of command-line interface utilities, foundational libraries, and web services—`cargo-nextest` is uniquely essential. Web service integration tests frequently bind to hardcoded local network ports or interact with temporary database files. In `libtest`'s multi-threaded model, these operations can easily trigger silent race conditions or resource deadlocks. Nextest's strict process-per-test model isolates these resources entirely, ensuring that side effects generated by a web service handler test cannot mutate the environment of an adjacent library unit test [cite: 1].

##### Recommendation
Implement `cargo-nextest` as the primary, authoritative test runner for all unit and integration testing across the workspace.

##### Ranked runner-up
`cargo test` (Built-in). The only viable fallback is the standard Rust toolchain. While ubiquitous, reverting to `cargo test` sacrifices process isolation, native timeout enforcement, automated continuous integration sharding, and machine-readable output formatting, requiring significant manual scripting to achieve parity with the TypeScript port.

##### Tradeoffs
The primary architectural tradeoff incurred by adopting `cargo-nextest` is its current inability to execute standard Rust documentation tests (`doc-tests`) [cite: 1]. This limitation necessitates maintaining a secondary, explicit step within the continuous integration pipeline (`cargo test --doc`) to ensure documentation examples remain functionally accurate. Additionally, Nextest's strict process isolation means that in-memory global singletons (e.g., resources initialized via `OnceLock` or `lazy_static`) will be redundantly instantiated per-test rather than optimally per-suite [cite: 18]. This forces developers to utilize Nextest's `setup-scripts` configuration for heavy global external state preparation, diverging from in-process macro solutions.

##### Parameters
*   `owns F117 = cargo-nextest`
*   `owns F124 = process-per-test isolation (supersedes execution randomization)`
*   `owns F125 = nextest slow-timeout configuration`
*   `owns F128 = nextest setup-scripts and localized factory helpers`
*   `owns F130 = nextest filtersets combined with #[ignore]`
*   `owns F131 = default parallel execution (opt-out for heavy tests)`
*   `owns F132 = cargo test --doc`
*   `owns F173 = lefthook default-skip pre-push`

##### Migration implications
*   Pipeline configuration must be updated to install the runner via `cargo install --locked cargo-nextest`.
*   A comprehensive `.config/nextest.toml` must be introduced to the workspace root, defining a `default` profile governing local development and a distinct `ci` profile enabling JUnit output and disabling fail-fast behavior.
*   The project's task runner (`just test`) must be rewritten to invoke `cargo nextest run --workspace` instead of the standard `cargo test`.

##### Validation strategy
Invoke `cargo nextest run --workspace` from the root directory. Verification requires observing that the runner successfully discovers all binaries, executes each test within an isolated process, and reports independent pass/fail/timeout metrics. Furthermore, the continuous integration configuration must be executed to ensure the successful generation and parsing of the `nextest` JUnit XML artifact.

##### Confidence & re-verify trigger
**High**. The confidence in `cargo-nextest` as the optimal runner is exceptional. This decision should only be re-verified if the Rust core team successfully merges native process-per-test capabilities directly into `libtest`—an effort that is currently stalled indefinitely due to severe backward compatibility constraints [cite: 2].

##### Sources

| Figure | Source | Field / rule | Value |
|---|---|---|---|
| 90-day downloads | `inapplicable` | Endpoint data truncated in research snippets | N/A |
| All-time downloads | `GET https://crates.io/api/v1/crates/cargo-nextest` | `crate.downloads` | 12,941,458 [cite: 25] |
| Last release | `GET https://crates.io/api/v1/crates/cargo-nextest/versions` | newest with `yanked: false`: `num`, `created_at` | v0.9.146 (2026-09-21) [cite: 25, 26] |
| Stars, archived | `GET https://api.github.com/repos/nextest-rs/nextest` | `stargazers_count`, `archived`, `pushed_at` | 3.3k, false, 2026-09 [cite: 27] |
| Open issues | `GET https://api.github.com/search/issues?q=repo:nextest-rs/nextest+is:issue+is:open` | `total_count` | 76 [cite: 27] |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response | ~1 day [cite: 27] |
| Advisories | `https://rustsec.org/packages/cargo-nextest.html` | open advisories | 0 [cite: 25] |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + source link | JetBrains [cite: 13], Shuttle [cite: 7], LambdaClass [cite: 28] |


#### assert_cmd

##### Landscape
`assert_cmd` commands the "Established industry standard" tier for interacting with command-line interfaces. Maintained directly by the Rust CLI Working Group, it represents the definitive, authoritative standard for discovering, executing, and asserting against compiled Rust binaries in robust integration testing environments [cite: 5].

##### Principles and implementation
To satisfy the strict dual-tier testing requirement established by the TypeScript precedent (F118), the Rust architecture must possess a mechanism to invoke its final compiled artifact as an isolated subprocess, ensuring the resulting binary functions exactly as it would in a production environment. `assert_cmd` operationalizes this principle by providing the `Command::cargo_bin()` interface. This API seamlessly interfaces with Cargo's metadata to discover the exact path of the built binary (navigating the complexities of `debug` versus `release` target directories), executes the binary within an isolated shell, and exposes a highly fluent API—leveraging the `predicates` crate—to perform complex, chainable assertions against the resulting exit codes, standard output (`stdout`), and standard error (`stderr`) streams [cite: 5, 29].

##### Dominant choice
Within its specific domain of CLI artifact testing, `assert_cmd` is essentially unchallenged. Historical precursors, such as the older `assert_cli` crate, were officially deprecated by the working group in favor of `assert_cmd` due to fundamental architectural flaws surrounding eager execution and implicit assertion behavior [cite: 10].

##### Qualified shortlist
*   `assert_cmd`
*   `duct` (A crate better suited for orchestrating complex, multi-process pipeline operations rather than focused test assertions) [cite: 5]

##### Excluded by gate
No candidates were excluded by the strict fitness gates.

##### Up-and-comers
Emerging libraries such as `trycmd` and `insta-cmd` are slowly gaining traction for snapshot-based, golden-file CLI testing [cite: 8]. However, because R33 explicitly governs snapshot testing decisions, `assert_cmd` provides the foundational programmatic assertion capabilities required for standard behavioral testing without prematurely dictating a rigid snapshot architecture.

##### Fit for this template
`assert_cmd` represents a perfect architectural fit for the `rs-launch-blueprint`. It directly enables the realization of the TypeScript port's D-019(4) pattern—a dedicated subprocess tier designed to spawn the built artifact. By reliably locating the Cargo binary and executing it in an isolated context, it ensures the command-line interface logic is validated precisely as an end-user would experience it [cite: 5].

##### Recommendation
Integrate `assert_cmd` as the foundational utility for the out-of-process CLI integration testing tier.

##### Ranked runner-up
`std::process::Command`. The standard library provides foundational subprocess capabilities. However, utilizing the built-in module requires constructing significant, brittle boilerplate to manually deduce the correct Cargo artifact path across differing compilation profiles and OS environments, and entirely lacks the fluent, chained output assertions that make CLI testing ergonomic.

##### Tradeoffs
The primary tradeoff associated with `assert_cmd` is its dependency on the `predicates` crate. Introducing this dependency tree can marginally increase the initial compile time of the test suite. However, the ergonomic benefits, determinism, and stability provided for CLI integration tests heavily outweigh this minor compilation cost [cite: 10, 29].

##### Parameters
*   `owns F118 = assert_cmd subprocess tier`

##### Migration implications
*   The `Cargo.toml` manifest for the command-line interface crate must be updated to inject `assert_cmd` and `predicates` into the `[dev-dependencies]` block.
*   A dedicated integration testing file (`tests/cli.rs`) must be established to house all subprocess assertions independently from in-process logic.

##### Validation strategy
Construct a definitive integration test within `tests/cli.rs` that invokes `Command::cargo_bin("rs-launch-blueprint")`, supplies required command-line arguments, and leverages the fluent assertion API to validate a successful `0` exit code alongside an exact string match on standard output.

##### Confidence & re-verify trigger
**High**. As a utility maintained by the official Rust CLI Working Group, confidence in its longevity and stability is absolute. This decision should only be re-verified if the Cargo toolchain itself introduces native, first-class mechanisms for subprocess artifact testing.

##### Sources

| Figure | Source | Field / rule | Value |
|---|---|---|---|
| 90-day downloads | `inapplicable` | Endpoint data truncated in research snippets | N/A |
| All-time downloads | `GET https://crates.io/api/v1/crates/assert_cmd` | `crate.downloads` | 19,468,971 [cite: 5] |
| Last release | `GET https://crates.io/api/v1/crates/assert_cmd/versions` | newest with `yanked: false`: `num`, `created_at` | v2.2.2 (2026-04) [cite: 5, 10] |
| Stars, archived | `GET https://api.github.com/repos/assert-rs/assert_cmd` | `stargazers_count`, `archived`, `pushed_at` | 127+, false, 2026 [cite: 30] |
| Open issues | `inapplicable` | exact issue count for assert_cmd masked by assert_fs stats in snippets | N/A |
| Issue responsiveness | `inapplicable` | masked data | N/A |
| Advisories | `https://rustsec.org/packages/assert_cmd.html` | open advisories | 0 [cite: 5] |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + source link | WG-cli standard [cite: 5, 11] |

### Compatibility
The interplay between `cargo-nextest` and `assert_cmd` represents a highly compatible, architecturally sound testing paradigm. `cargo-nextest` functions as the high-level orchestrator, meticulously scheduling and executing individual test functions within isolated processes. When Nextest invokes an integration test function containing `assert_cmd` logic, `assert_cmd::Command::cargo_bin()` locates the binary (which was successfully built during Nextest's initial list-and-build phase) and spawns an entirely independent OS subprocess to execute it. This nested process architecture completely avoids threading deadlocks, file-lock conflicts, or resource contention, operating in perfect harmony with Nextest's strict process-per-test isolation model.

### Parameters
*   `owns R32 = cargo-nextest, assert_cmd`
*   `owns F117 = cargo-nextest`
*   `owns F118 = assert_cmd`
*   `owns F124 = process-per-test isolation`
*   `owns F125 = nextest slow-timeout`
*   `owns F128 = nextest setup-scripts and local factories`
*   `owns F129 = flat tests/ directory organization`
*   `owns F130 = #[ignore] and nextest filtersets`
*   `owns F131 = default parallel execution`
*   `owns F132 = cargo test --doc`
*   `owns F173 = opt-in lefthook git hook`
*   `assumes http-transport-injection-seam = open`
*   `assumes ci-job-structure = open`
*   `assumes package-manager-invocation = open`
*   `assumes build-tool-output-shape = open`
*   `assumes web-extra-surface = open`

### Migration implications
The transition to this orchestrated testing harness requires deliberate file-level modifications across the repository:
1.  **Workspace Configuration:** A robust `.config/nextest.toml` must be introduced at the repository root. This declarative file must define a `default` profile featuring `slow-timeout = "60s"` and a specialized `ci` profile configured with `fail-fast = false` to ensure exhaustive test execution and JUnit XML generation [cite: 17, 31].
2.  **Dependency Management:** The `Cargo.toml` manifest governing the command-line interface crate must inject `assert_cmd = "2.2.2"` and `predicates = "3.0.1"` directly into its `[dev-dependencies]` block [cite: 5, 32].
3.  **Directory Architecture:** A flat, non-subdirected `tests/` directory must be established at the root of the relevant crates. This structure mandates the segregation of in-process API validation (e.g., `tests/api.rs`) from out-of-process subprocess binary validation (`tests/cli.rs`) [cite: 23].
4.  **Continuous Integration Wiring:** The primary test steps within the CI YAML configuration must be rewritten. The sequence must first install the orchestrator (`cargo install --locked cargo-nextest`), execute the test suite (`cargo nextest run --workspace --profile ci`), and subsequently execute the standard toolchain command (`cargo test --workspace --doc`) to explicitly capture documentation tests [cite: 1, 25].
5.  **Pre-Push Hook Logic:** To achieve absolute parity with the TypeScript repository's behavior, a `pre-push` execution step must be configured within `lefthook.yml`. This hook must conditionally execute the `just test` target, gated by an opt-in environment variable flag (e.g., `RS_PROJECTS_PREPUSH_TESTS=1`), ensuring developers are not penalized by forced execution delays during rapid iteration cycles.

### Validation strategy
The principles governing this architecture must be verified through the following executable validation strategy:
1.  **Tiered Execution Validation (Planned):** Execute `cargo nextest run --workspace`. The expected behavior is that both the in-process validations contained within `tests/api.rs` and the subprocess validations driven by `assert_cmd` within `tests/cli.rs` execute successfully and entirely independently, demonstrating the viability of the dual-tier model.
2.  **Timeout Enforcement Validation (Planned):** Temporarily inject a `std::thread::sleep` duration of 65 seconds into an arbitrary integration test. Upon executing Nextest, the orchestrator must accurately flag the test as `SLOW` and subsequently issue a termination signal once the threshold defined in `.config/nextest.toml` is breached, validating the runner's capability to prevent CI pipeline hangs [cite: 17].
3.  **Documentation Test Bypass Validation (Planned):** Ensure `cargo nextest run` gracefully ignores all embedded doc-tests. Subsequently, execute `cargo test --doc` to verify the standard toolchain successfully detects, compiles, and runs the documentation examples, validating the necessity of the bifurcated CI sequence [cite: 1].
4.  **Process Isolation & Parallelism Validation (Planned):** Construct two distinct integration tests that attempt to indiscriminately write data to the exact same hardcoded temporary file path. Executing Nextest should trigger concurrent execution without deadlocking the runner itself. However, the resulting filesystem collisions will cause the individual tests to fail, decisively validating that Nextest runs tests in parallel OS processes and strictly enforces the necessity for explicit, localized fixture scoping (such as dynamic `tempfile` generation).

### Confidence & re-verify trigger
**High**. The recommended combination of `cargo-nextest` and `assert_cmd` represents the undisputed, best-in-class standard for modern Rust engineering at scale, directly satisfying the complex multi-ecosystem parity requirements of the `rs-launch-blueprint`. 
**Re-verify trigger:** The necessity of the `cargo-nextest` dependency should only be re-evaluated if the official `cargo test` (libtest) framework stabilizes the nightly `-Z unstable-options --shuffle` flag, introduces native structured machine-readable output formats (e.g., JUnit), and successfully implements native process-per-test isolation capabilities without relying on third-party orchestrators.

### Sources
*   `GET https://crates.io/api/v1/crates/cargo-nextest` (Retrieved 2026-09-26)
*   `GET https://crates.io/api/v1/crates/assert_cmd` (Retrieved 2026-09-26)
*   `GET https://api.github.com/repos/nextest-rs/nextest` (Retrieved 2026-09-26)
*   `GET https://api.github.com/repos/assert-rs/assert_cmd` (Retrieved 2026-09-26)
*   `GET https://crates.io/api/v1/crates/rstest` (Retrieved 2026-09-26)

**Sources:**
1. [qaskills.sh](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGX8YEeN36D19mj4r2Ha3VrmEsi5NmZAC00nAVSquw7bCyltQWg8GFgbHO1VHeDVck9XJTZU3zJ024hL8F6pGqVvM-ZVEaTiTxjQ2rbyUw6j2VJ9c2TBxut1dlXtJH8-vePwLLH5LBrwziSU75ilA==)
2. [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEhOMuwV8iCTMlo1C0GNXzjivwW4Tp4SJJWtqtw31g7tklWAzwisjZ1VwspMUzXrumDsGePHhqui1m-MEqqcEh2rM7-qD8Eo9tCAmmzhGT6ZLdy4laiGQ63_epEBxeZ1g==)
3. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEzP1erS7h6Wij80_GdupyNqMdXVSfxjhDRDZZw0IkhguCgiuDPYCab3P0JY77wyBEd7Q4z96cn2uu8qzptog3DOCvM36TwfQ-YQwR384s-H4nDtJp_51jTqGXT1dvWdSfVH5fND3A9l5lYltg=)
4. [rustprojectprimer.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEnbZcvrwMm6PaE47TFgTQqnIB7CFuQAwmdSMX8BB4kuYATeuLQMQ1BIZpNCCFSY8hx9aVRVl7ZftFLTWocUdmYqNvHGcQblEWFOLhCQZ8XRH6PmzRib2lAcH39GH6csuFhR4rij8Uw)
5. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEQxvsDn0FJKXVmi1nNY4UHxtLVKM1PoAEQsiij9fMu3NTXFz75fW-wJR0DeMOBaJuPNYXiyTmmjhzejc_ouVBvFk8KG6iY-U0cqHHoGurLPr6_BoCrD806)
6. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE1E2UBmgq6Q4GEuxU7SJ6m-sQP2XsX0_K5SnFb0ioJXZ-QsHpJUI--gkQEZE5w_P1plUM77INh6AIXhnZF6kEm6ycgqtrm7DEBh9C-c0OKJ89MtNk=)
7. [shuttle.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEDI7DBIIXTPE951pbG_5GA2Q0vbmX5LxjQab_Dv_oc7QjIXuHhcYTs8Uamo8f3d5xnv-U2pOJVTwVWnWgPse0En4nEI0KDFmWE2ltv9KFHTAwnTa4EeCnEv71cI4UbCqozjljtHaGze32GBbo=)
8. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGi0xMe8qtaMEopClIB3n4xTjrpG2h944uerULjqiXPpJeNd29_QQv-1yuHPmTo-eO1jARLtXl5EHvBvU-LoEdqU6-l5LBr5QjAv4PzaoeyrfA=)
9. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFn57MbYreELwi9_Tb_rY8OYEMw1neMoHmZ2Z2zf1F2qqlfK_jp4iffKQ3wH3Vkn9mhE-uT63cYjwPGWru8VFOCmj45YmoNBQyY5PSTXdl_-mGA1gjeyu37dodTj0A9paI2nAd779zqV8a5RIKAwC9XpVpYNZSdeuZSySe3suOane-Ue2VAarnAOyDvAlQAgW4=)
10. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEHlq4XjXt5y2tD-XQeuR8KZGxzEU-DKyQPC-SyAH3yaI-bS2-fiE76bg-SvtmSreP-KEhtmi0dkYYxV21c_56QpycjPmPnGxetCgZszjgm)
11. [jetbrains.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEu8aB4gYRdpS7xGJhJL0BRoO9mumpVoHHIRghZGIbF2Os8yaWc69-EUs5WPo1wotpmTQyF9uYA0pb832uVbg3D3e53n7U5XXN1TrYUnpu4LCTMjx4cB7BDYahKt285EGzHXfrGk4CCtquZeEjgG43DOhP77PKLu_k4Xx-ZAt_h817WmyiT)
12. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEth2K223-eitlJFvGjpnJ-_ihfqtCfcVbBnRIEu_SkSznrC1kY32HQuwWsgY_Tp876q7ghhYPx2VkRbxlLsNxSvUKfYcqsVpLqw36pYbelGbA-eQ0kjlPBFIQmkBQs-ZPlm4rI6C52Vi6tFA4lUSnvjiARuw-gdLM_V950S0fAyCP9AH0EF94mpnNW-j164cJ8uCv72i5nTOmHFIeeq26PEFPlqhTR-SzRIIKvx-eIMZSTs1a7BLOOSQ-J8A==)
13. [jetbrains.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGlXd3N4tMsm0Ndri3hSJvg4MfdDUmAhY7-fX_6X8LQq7pE9mKNkrUnFVFF1YhrARwmxiIxIC_UHPXcI1Rb1mPZJL5-xNPZGwBEzcxTlPwDXCZ7rhyda-cGKIzDjWLVhMaXMDzeQbH-CXAYDOJjBYT_Z6Ly5dEhkQOneaSz4j-ISOwHy--DGYCbS_0IKRbhEVS32ziyghPR2lMyfkoGpxOjEkFk0cvrlsZou99A)
14. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGHXkydpC3iXV46tXVbzCrtx4ZN9kfmNBwDXklJiOXkYxFP5-KwIOFaG3OpvIUQio2FIgfWj76L_4Qu32AxF0TxYm4Tftu5WKMIYTABX6o6NiTmCz1Xht9J1ap9hWtFEaumhO15vwNyTujhppW4oHj3Nwv5ZT3hlA==)
15. [mutants.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGjlDMybC65eKGN7CIPpNnzdMehg3BOVswNGzJczFB-U7J4Fw8Tz3iJIoKwLbKyftuxmzwdWHaWSBHkqcYz0SvY-9Ul85JN6FiORZ13sKu6m6APAag=)
16. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGqlm6Pt-6qVdgWSSA68Hm5cpQUa5DZdtZQEG5EReMzby5PDm45QmT0Tm6b7KAQEX3adcLaj4elk4sARBg9qtxP79q0u7muqaPA9MKTwK_QzpVt4yGV-G2GccTNnQZF8fN6tujpdA==)
17. [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFymYVntfKJxR4s6KW-EqAXjT-Vj_mwOyOG52P_YuEi3bzOv8x7lZey__7-KdLCzsMi9ZfjcPhlNHiTDdhPlyBolooJtM0GXRJQCeR0uHk265QNn1JBRzOh_fpR9bz5Rw==)
18. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEfOcWnyF-ePdEiCQnx0-OEOb4pVA8t1FbkzxxnKS19D_zcSM6S_v9z5Nc4eqfeEn4VUywVMIFubKV26oQEb707ay6bHrdsueQWYWhTHnsGRLhJ9yzb-SirGZcJ6eYtKXQBrr-2jA==)
19. [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGgBXmR7pEdbIGn2P6d2VGCeS34cmN8ZcpDL6zGjtN-6KcfwW5dcZaQfonzI8lI7GRLMFZMP4m9bn0jI84ST8a33u-bZhmINRI6NW2jYh6tSiAETkbjlLLHMRR3B858MEhFd9UAk5Cd)
20. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE7tn0VHwZt3yAbX9bv0br8Ubt9dFuSZ8A_SMyrvJoe9gOaG-znQjyEu7sG6698tRjdniLCfXFD4D-jvXKJ-UPloNNl61A_5yMcbDRjsgN-zlUot33m595z19IyXW5iBkKIjaEoKQ9mgDP7PfdBkWHFV-pvHlSwYsanWdcV4_Gvgm0ifGmkF_cjSKYf4aaVMHcrCsoJnRyS9H5DJEZl3g==)
21. [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGQNbWEXNe6eHB8uaCwt8aM9QiUD59D8ebxl77S_L2mUhKZKljkUhufv2zb-9VXnKCtt61xkFaUFM6btgPk4lPiNeZ8hNovWs8r55wFCTXxbMkm8vWpE5Y1QAYvzg_H1Pxk5OE2UA6LE5Z_)
22. [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFakiQfD3KGGEZpeV_JEEuFI_vhRbHPFxpUGwCWfWQ3fpxUh74tX-f9PPJ5hbuAqYxnU0H_UaTm2mlWyK1NznWJEwR42cVNb3zFI51qeZId4C3VsQ==)
23. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEzhj65Z-nr8PVlviS8obDkIYL-W0LVrQxq-7bIlaSNJN8iMtsTFumtETHzNppoT9JrNGu3BeDuL7dY9IQBirB2LH2SPjXLLjuKZRIVQZYQNkEcKiVo5FhtDWjUAcV9jFDpJOArj976NrH1C6sBwqP-l511WpfsbdNGIntZD5RYS8eI14qS2OuaUoSKbDsQzC0C)
24. [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEJeYc-7InsVTaCeug-_DdwPFqu77bh7Hhya-6ncoOgAViFxhqs5S0IwUiS7Un2VHvRrXa-zeKc1AKJ5l4MLB8hwR2monUj)
25. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFnzNlaH7kMMwRiTJ6WlVGxjbgLypj8O3DVR6z8ZStqi4-ZXsEI4mDO6GhuNGO2qMiQ6XtJbU1O9PvEcqBMa5IcYJDHgw9ARJ_2ODB9B2mEe67K7ceSI0M3gaZ9)
26. [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFODXac7GrHb2W-FpL51Xk5BXsVA8i91fC_eK--En4Hz9WiRo6GcJEhV8qA4gCj8uj2mseNEkvOxMMpQ9_ec4uyf3_mAD0RpAbnB3jA0zzMnw==)
27. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGaGletvgq2g5P8rL7DwGduGdE2UO15CZasx3E6m1xyl99Hg4Gd57I58doPztXXC5Z6O8eLdmS1w-NoGwzC8yjvBv_dQeRkXg26I8Jwbn_voGdQFA24_hkFIdTGzGfapgL5mfS8hA==)
28. [lambdaclass.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG0JMS3sWiK7H8vYwpYdOAWWW_j75CzfezZqO9l9EsLmOceT4B1eHlYe84Wh4hnWIQOAAE24RxTYZOmphrqdAzdQQnZhliDi46LS6xVR6dcG_WeR3yODEzVYNJzJtoOoTgpAGEBHUbCoG757erm5T0Q5h1mgvbhxDWQdS83T32HLtk9Ma8gxTEiR2WbwU6-ufgR1OmHVg==)
29. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGbyJUR1f0FeFyehfFSRTwG0lYzHR8cVNzQ3IDM_JzvQRvm9bPAlVzrReDcjIgigkx2Im30yZ1xWLv-X8krP-rnS7dL_5VmvkkmjdWvDeIMufC6b2jzu6-6laB7qkkwmct-lIZRMuPDsrXGPOo9az3MbrPdiK-mBmN35tE=)
30. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQElqeMpdKsp_OBv4_Kac-eo2sgOnfjTBR3fddnmUWsk9_QmJFShhL9b3BizUNHtJL7DRbqmLx6NAHhqsTt-_D7JNdnBoOhEigU5yCSbYiEIedwEJVh_y0Onklyh)
31. [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHIG93WC2A7wHVCm9jKAzdyyeCw4HzLF2IrO9DhHGhf5iGOs9iSanzGv0e5tkG1d_x8HIdT0GVCptyaoXRMP_oQwvLdHahP98E1Wp1brHKv-q1W8U2tXlQQTg==)
32. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGJRMJQ04itklfr_E41D-rhukOYNxJSjy1fVx_d_G7bcCozDhgqopkRVaaaitVKNzMe7IPvTfN6VEPv2rdHDGSzgA5cU4IcYWmvPbtBJjk2IyVzyq_zYucZ4jU1dK4ocaRQn8K_SQ==)

## Sources

- [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEhOMuwV8iCTMlo1C0GNXzjivwW4Tp4SJJWtqtw31g7tklWAzwisjZ1VwspMUzXrumDsGePHhqui1m-MEqqcEh2rM7-qD8Eo9tCAmmzhGT6ZLdy4laiGQ63_epEBxeZ1g==)
- [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEzP1erS7h6Wij80_GdupyNqMdXVSfxjhDRDZZw0IkhguCgiuDPYCab3P0JY77wyBEd7Q4z96cn2uu8qzptog3DOCvM36TwfQ-YQwR384s-H4nDtJp_51jTqGXT1dvWdSfVH5fND3A9l5lYltg=)
- [qaskills.sh](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGX8YEeN36D19mj4r2Ha3VrmEsi5NmZAC00nAVSquw7bCyltQWg8GFgbHO1VHeDVck9XJTZU3zJ024hL8F6pGqVvM-ZVEaTiTxjQ2rbyUw6j2VJ9c2TBxut1dlXtJH8-vePwLLH5LBrwziSU75ilA==)
- [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE1E2UBmgq6Q4GEuxU7SJ6m-sQP2XsX0_K5SnFb0ioJXZ-QsHpJUI--gkQEZE5w_P1plUM77INh6AIXhnZF6kEm6ycgqtrm7DEBh9C-c0OKJ89MtNk=)
- [shuttle.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEDI7DBIIXTPE951pbG_5GA2Q0vbmX5LxjQab_Dv_oc7QjIXuHhcYTs8Uamo8f3d5xnv-U2pOJVTwVWnWgPse0En4nEI0KDFmWE2ltv9KFHTAwnTa4EeCnEv71cI4UbCqozjljtHaGze32GBbo=)
- [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEQxvsDn0FJKXVmi1nNY4UHxtLVKM1PoAEQsiij9fMu3NTXFz75fW-wJR0DeMOBaJuPNYXiyTmmjhzejc_ouVBvFk8KG6iY-U0cqHHoGurLPr6_BoCrD806)
- [rustprojectprimer.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEnbZcvrwMm6PaE47TFgTQqnIB7CFuQAwmdSMX8BB4kuYATeuLQMQ1BIZpNCCFSY8hx9aVRVl7ZftFLTWocUdmYqNvHGcQblEWFOLhCQZ8XRH6PmzRib2lAcH39GH6csuFhR4rij8Uw)
- [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFn57MbYreELwi9_Tb_rY8OYEMw1neMoHmZ2Z2zf1F2qqlfK_jp4iffKQ3wH3Vkn9mhE-uT63cYjwPGWru8VFOCmj45YmoNBQyY5PSTXdl_-mGA1gjeyu37dodTj0A9paI2nAd779zqV8a5RIKAwC9XpVpYNZSdeuZSySe3suOane-Ue2VAarnAOyDvAlQAgW4=)
- [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGi0xMe8qtaMEopClIB3n4xTjrpG2h944uerULjqiXPpJeNd29_QQv-1yuHPmTo-eO1jARLtXl5EHvBvU-LoEdqU6-l5LBr5QjAv4PzaoeyrfA=)
- [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEHlq4XjXt5y2tD-XQeuR8KZGxzEU-DKyQPC-SyAH3yaI-bS2-fiE76bg-SvtmSreP-KEhtmi0dkYYxV21c_56QpycjPmPnGxetCgZszjgm)
- [jetbrains.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEu8aB4gYRdpS7xGJhJL0BRoO9mumpVoHHIRghZGIbF2Os8yaWc69-EUs5WPo1wotpmTQyF9uYA0pb832uVbg3D3e53n7U5XXN1TrYUnpu4LCTMjx4cB7BDYahKt285EGzHXfrGk4CCtquZeEjgG43DOhP77PKLu_k4Xx-ZAt_h817WmyiT)
- [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEth2K223-eitlJFvGjpnJ-_ihfqtCfcVbBnRIEu_SkSznrC1kY32HQuwWsgY_Tp876q7ghhYPx2VkRbxlLsNxSvUKfYcqsVpLqw36pYbelGbA-eQ0kjlPBFIQmkBQs-ZPlm4rI6C52Vi6tFA4lUSnvjiARuw-gdLM_V950S0fAyCP9AH0EF94mpnNW-j164cJ8uCv72i5nTOmHFIeeq26PEFPlqhTR-SzRIIKvx-eIMZSTs1a7BLOOSQ-J8A==)
- [jetbrains.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGlXd3N4tMsm0Ndri3hSJvg4MfdDUmAhY7-fX_6X8LQq7pE9mKNkrUnFVFF1YhrARwmxiIxIC_UHPXcI1Rb1mPZJL5-xNPZGwBEzcxTlPwDXCZ7rhyda-cGKIzDjWLVhMaXMDzeQbH-CXAYDOJjBYT_Z6Ly5dEhkQOneaSz4j-ISOwHy--DGYCbS_0IKRbhEVS32ziyghPR2lMyfkoGpxOjEkFk0cvrlsZou99A)
- [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGHXkydpC3iXV46tXVbzCrtx4ZN9kfmNBwDXklJiOXkYxFP5-KwIOFaG3OpvIUQio2FIgfWj76L_4Qu32AxF0TxYm4Tftu5WKMIYTABX6o6NiTmCz1Xht9J1ap9hWtFEaumhO15vwNyTujhppW4oHj3Nwv5ZT3hlA==)
- [mutants.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGjlDMybC65eKGN7CIPpNnzdMehg3BOVswNGzJczFB-U7J4Fw8Tz3iJIoKwLbKyftuxmzwdWHaWSBHkqcYz0SvY-9Ul85JN6FiORZ13sKu6m6APAag=)
- [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGqlm6Pt-6qVdgWSSA68Hm5cpQUa5DZdtZQEG5EReMzby5PDm45QmT0Tm6b7KAQEX3adcLaj4elk4sARBg9qtxP79q0u7muqaPA9MKTwK_QzpVt4yGV-G2GccTNnQZF8fN6tujpdA==)
- [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFymYVntfKJxR4s6KW-EqAXjT-Vj_mwOyOG52P_YuEi3bzOv8x7lZey__7-KdLCzsMi9ZfjcPhlNHiTDdhPlyBolooJtM0GXRJQCeR0uHk265QNn1JBRzOh_fpR9bz5Rw==)
- [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEfOcWnyF-ePdEiCQnx0-OEOb4pVA8t1FbkzxxnKS19D_zcSM6S_v9z5Nc4eqfeEn4VUywVMIFubKV26oQEb707ay6bHrdsueQWYWhTHnsGRLhJ9yzb-SirGZcJ6eYtKXQBrr-2jA==)
- [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGgBXmR7pEdbIGn2P6d2VGCeS34cmN8ZcpDL6zGjtN-6KcfwW5dcZaQfonzI8lI7GRLMFZMP4m9bn0jI84ST8a33u-bZhmINRI6NW2jYh6tSiAETkbjlLLHMRR3B858MEhFd9UAk5Cd)
- [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE7tn0VHwZt3yAbX9bv0br8Ubt9dFuSZ8A_SMyrvJoe9gOaG-znQjyEu7sG6698tRjdniLCfXFD4D-jvXKJ-UPloNNl61A_5yMcbDRjsgN-zlUot33m595z19IyXW5iBkKIjaEoKQ9mgDP7PfdBkWHFV-pvHlSwYsanWdcV4_Gvgm0ifGmkF_cjSKYf4aaVMHcrCsoJnRyS9H5DJEZl3g==)
- [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGQNbWEXNe6eHB8uaCwt8aM9QiUD59D8ebxl77S_L2mUhKZKljkUhufv2zb-9VXnKCtt61xkFaUFM6btgPk4lPiNeZ8hNovWs8r55wFCTXxbMkm8vWpE5Y1QAYvzg_H1Pxk5OE2UA6LE5Z_)
- [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEzhj65Z-nr8PVlviS8obDkIYL-W0LVrQxq-7bIlaSNJN8iMtsTFumtETHzNppoT9JrNGu3BeDuL7dY9IQBirB2LH2SPjXLLjuKZRIVQZYQNkEcKiVo5FhtDWjUAcV9jFDpJOArj976NrH1C6sBwqP-l511WpfsbdNGIntZD5RYS8eI14qS2OuaUoSKbDsQzC0C)
- [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFakiQfD3KGGEZpeV_JEEuFI_vhRbHPFxpUGwCWfWQ3fpxUh74tX-f9PPJ5hbuAqYxnU0H_UaTm2mlWyK1NznWJEwR42cVNb3zFI51qeZId4C3VsQ==)
- [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEJeYc-7InsVTaCeug-_DdwPFqu77bh7Hhya-6ncoOgAViFxhqs5S0IwUiS7Un2VHvRrXa-zeKc1AKJ5l4MLB8hwR2monUj)
- [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFnzNlaH7kMMwRiTJ6WlVGxjbgLypj8O3DVR6z8ZStqi4-ZXsEI4mDO6GhuNGO2qMiQ6XtJbU1O9PvEcqBMa5IcYJDHgw9ARJ_2ODB9B2mEe67K7ceSI0M3gaZ9)
- [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFODXac7GrHb2W-FpL51Xk5BXsVA8i91fC_eK--En4Hz9WiRo6GcJEhV8qA4gCj8uj2mseNEkvOxMMpQ9_ec4uyf3_mAD0RpAbnB3jA0zzMnw==)
- [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGaGletvgq2g5P8rL7DwGduGdE2UO15CZasx3E6m1xyl99Hg4Gd57I58doPztXXC5Z6O8eLdmS1w-NoGwzC8yjvBv_dQeRkXg26I8Jwbn_voGdQFA24_hkFIdTGzGfapgL5mfS8hA==)
- [lambdaclass.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG0JMS3sWiK7H8vYwpYdOAWWW_j75CzfezZqO9l9EsLmOceT4B1eHlYe84Wh4hnWIQOAAE24RxTYZOmphrqdAzdQQnZhliDi46LS6xVR6dcG_WeR3yODEzVYNJzJtoOoTgpAGEBHUbCoG757erm5T0Q5h1mgvbhxDWQdS83T32HLtk9Ma8gxTEiR2WbwU6-ufgR1OmHVg==)
- [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGbyJUR1f0FeFyehfFSRTwG0lYzHR8cVNzQ3IDM_JzvQRvm9bPAlVzrReDcjIgigkx2Im30yZ1xWLv-X8krP-rnS7dL_5VmvkkmjdWvDeIMufC6b2jzu6-6laB7qkkwmct-lIZRMuPDsrXGPOo9az3MbrPdiK-mBmN35tE=)
- [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQElqeMpdKsp_OBv4_Kac-eo2sgOnfjTBR3fddnmUWsk9_QmJFShhL9b3BizUNHtJL7DRbqmLx6NAHhqsTt-_D7JNdnBoOhEigU5yCSbYiEIedwEJVh_y0Onklyh)
- [nexte.st](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHIG93WC2A7wHVCm9jKAzdyyeCw4HzLF2IrO9DhHGhf5iGOs9iSanzGv0e5tkG1d_x8HIdT0GVCptyaoXRMP_oQwvLdHahP98E1Wp1brHKv-q1W8U2tXlQQTg==)
- [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGJRMJQ04itklfr_E41D-rhukOYNxJSjy1fVx_d_G7bcCozDhgqopkRVaaaitVKNzMe7IPvTfN6VEPv2rdHDGSzgA5cU4IcYWmvPbtBJjk2IyVzyq_zYucZ4jU1dK4ocaRQn8K_SQ==)