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
mode: deep_research
provider: openai
model: gpt-5.6-sol
operation_id: research-20260926-153440-8e85986f883b449c
created_at: 2026-09-26T15:34:40.333869
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives.
Organize findings clearly and highlight key insights.

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

## Reasoning Summary
**Researching test runners**

I'm looking into the current landscape of test runners for 2026 and considering the nextest base execution tool. I need to check if it supports a native per-test timeout and if the execution order can be randomized. I see there are some options like test priority and thread configurations, but I need to clarify their randomization capabilities. The `cargo-nextest` tool may not support randomization effectively, and I should verify the latest documentation for any updates on stability and features.

### Landscape

**Decision category:** Rust test execution and harness policy for a CLI + library + web-service workspace: runner, execution isolation, CLI test tiers, time bounds, fixture lifecycle, test taxonomy, concurrency, doctests, and local hook wiring. All linked web sources were retrieved **September 26, 2026**.

| Bin | Candidates found | Assessment for this template |
|---|---|---|
| **Built-in / first-party toolchain** | Cargo + `libtest`; `#[test]`; `#[ignore]`; `--test-threads`; Cargo integration tests; rustdoc doctests; `std::process::Command` and Cargo’s `CARGO_BIN_EXE_<name>` variables | Lowest dependency and compatibility risk. Cargo compiles and executes unit, integration, and documentation tests. It lacks a stable hard per-test timeout, while `libtest`’s seeded `--shuffle` remains unstable on Rust 1.98. ([doc.rust-lang.org](https://doc.rust-lang.org/rustc/tests/?utm_source=openai)) |
| **Established industry standard** | `cargo-nextest`; `assert_cmd`; `rstest` | `cargo-nextest` is the dominant supplemental runner: process-per-test isolation, hard timeouts, filters, profiles, resource controls, and CI partitioning. `assert_cmd` is a mature binary-test convenience layer; `rstest` is a mature explicit-fixture framework, but neither is necessary for this template’s minimal implementation. ([nexte.st](https://nexte.st/docs/features/slow-tests/?utm_source=openai)) |
| **Up-and-comer** | `test-r`; `cargo-maelstrom`; `rigtest`; `rustest`; `assay` | `test-r` most closely reproduces pytest-like tags, dependency injection, timeouts, and stable shuffle, but requires a custom harness and does not run doctests. Maelstrom currently fails the required macOS gate because its published Rust runner is Linux-focused. The others have useful ideas but materially less production evidence. ([test-r.vigoo.dev](https://test-r.vigoo.dev/)) |

**Authority used**

1. **Rust project documentation and tracking issues:** authoritative for Cargo/libtest behavior, doctests, ignored tests, parallel execution, and the unstable status of shuffle. ([doc.rust-lang.org](https://doc.rust-lang.org/rustc/tests/?utm_source=openai))
2. **Rust Release Team and Rust Forge:** authoritative for the current stable toolchain. Stable is Rust **1.98.1**, released September 3, 2026; therefore the owner’s current stable-minus-two MSRV is **1.96**. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/?utm_source=openai))
3. **Nextest maintainer documentation and repository:** authoritative for its execution model, timeouts, filtersets, profile behavior, platform support, version policy, and benchmarks. ([nexte.st](https://nexte.st/docs/features/slow-tests/?utm_source=openai))
4. **Maintainer documentation for alternatives:** `test-r`, `rstest`, `assert_cmd`, Maelstrom, and related custom harnesses. These establish capabilities but are not treated as independent evidence of broad adoption. ([test-r.vigoo.dev](https://test-r.vigoo.dev/))
5. **Rust annual survey:** compilation speed and artifact size remain material ecosystem concerns, supporting a preference for a prebuilt runner and avoiding unnecessary test proc-macro dependencies. ([raw.githubusercontent.com](https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2025/annual-survey/report/annual-survey-2025-report.pdf?utm_source=openai))

**Practice evidence**

- NVIDIA’s OpenShell repository pins a `cargo-nextest` release in its tool lock, providing current direct-adopter evidence for nextest in a modern Rust project. ([github.com](https://github.com/NVIDIA/OpenShell/blob/main/mise.lock?utm_source=openai))
- `test-r` documents Golem Cloud as a production adopter for its unit and integration tests; Golem is an actively maintained public Rust distributed-application platform. This proves that `test-r` is usable in production, but currently provides much narrower adoption evidence than nextest. ([test-r.vigoo.dev](https://test-r.vigoo.dev/))
- Nextest’s published benchmark corpus covers projects including Tokio, Reqwest, Meilisearch, mdBook, and Ring. These are compatibility and workload examples, not evidence that those projects use nextest in their own CI. ([nexte.st](https://www.nexte.st/docs/benchmarks/?utm_source=openai))
- The owner-supplied py and ts implementations demonstrate two different valid ecosystem realizations: pytest plugins and autouse fixture behavior in Python; two CLI tiers and an optional full-suite hook in TypeScript. They are evidence for the shared policy, not automatic Rust defaults.

**Fitness-gate result before popularity weighting**

| Candidate | Gate result |
|---|---|
| **`cargo-nextest 0.9.145`** | Conditional pass and recommendation. MIT OR Apache-2.0; build MSRV 1.91, below target 1.96; macOS and Linux release artifacts; no workspace async-runtime coupling because it is an external executable. Exact RustSec and API maintenance figures could not be retrieved in this run, so the advisory/maintenance gate must be rechecked mechanically before lock-in. ([github.com](https://github.com/nextest-rs/nextest?utm_source=openai)) |
| **Cargo/libtest only** | Passes dependency and platform gates, but fails the required execution-capability gate: no stable process-enforced per-test timeout and no stable seeded shuffle. ([doc.rust-lang.org](https://doc.rust-lang.org/rustc/tests/?utm_source=openai)) |
| **`test-r 3.0.12`** | Qualified up-and-comer, not selected. Apache-2.0 and edition 2024, but it replaces the built-in harness, does not support doctests, defaults to Tokio for async support, and has a documented interaction among capture, parallelism, and dependency injection. Its root workspace manifest does not establish the required `rust-version` policy. ([docs.rs](https://docs.rs/test-r/latest/test_r/?search=test_r)) |
| **`cargo-maelstrom`** | **Excluded by gate:** published Rust support is Linux-focused, so it does not satisfy required `macos-latest`. ([maelstrom-software.com](https://maelstrom-software.com/?utm_source=openai)) |
| **`assert_cmd 2.2.2`** | Compatible qualified add-on: MIT OR Apache-2.0 and `rust-version = 1.85`. Not selected because two small artifact smoke tests do not justify another abstraction layer. ([docs.rs](https://docs.rs/crate/assert_cmd/latest/source/Cargo.toml?utm_source=openai)) |
| **`rstest 0.27.0`** | Compatible qualified add-on for explicit fixtures, but not selected: explicit Rust builders/RAII are sufficient, and runner-enforced process timeout is stronger than a test-macro timeout for subprocess tests. ([docs.rs](https://docs.rs/crate/rstest/latest?utm_source=openai)) |

**Metric-collection caveat:** the required crates.io, GitHub API, and RustSec endpoints were requested on September 26, 2026, but were inaccessible to the research transport. Rounded GitHub UI figures are not substituted for the mandated exact fields. The exact endpoint audit appears under the `cargo-nextest` member. ([]())

---

### Principles and implementation

The shared requirement is:

> **Tests must produce bounded, reproducible confidence at both the injectable application seam and the shipped executable boundary, while keeping costly or externally coupled tests explicit and preserving one canonical full-suite command.**

The required cross-repository agreement is at the following levels:

| Feature | Shared engineering principle | Required agreement level | Rust realization |
|---|---|---|---|
| F117 runner | One canonical, automation-safe test entry point | **Policy/capability** | `cargo-nextest` for executable tests; Cargo/rustdoc separately for doctests |
| F118 CLI tiers | Test logic cheaply at the seam and minimally at the artifact boundary | **Architectural pattern** | In-process `run_cli` tests plus integration tests spawning `CARGO_BIN_EXE_rs-launch` |
| F124 ordering | Tests must not depend on prior tests or global residue | **Capability**, not identical mechanism | Nextest process-per-test isolation, unique RAII fixtures, serial and parallel runs; no mandatory custom shuffle harness |
| F125 timeout | A hung test must terminate and fail predictably | **Policy** | Nextest `slow-timeout = { period = "60s", terminate-after = 1 }` |
| F128 shared setup | Reusable setup and reliable teardown without hidden coupling | **Capability/architecture** | Explicit `tests/support` builders and RAII, not an implicit autouse hook |
| F129 organization | Tests must be discoverable and independently targetable | **Architectural pattern** | Domain top-level integration binaries with submodules |
| F130 slow/live | Costly and externally coupled tests are opt-in and named | **Policy** | Dedicated `slow`/`live` integration binaries, `#[ignore = "..."]`, and nextest filters |
| F131 parallelism | Both deterministic serial and concurrency-sensitive execution are available | **Capability** | Serial default profile; explicit `parallel` profile |
| F132 doctests | Rust documentation examples are executable API contracts | **Rust-specific policy** | Required `cargo test --workspace --doc` lane |
| F173 pre-push | Developers can request early full-suite feedback without mandatory hook latency | **Policy** | Optional hook, skipped unless `RS_LAUNCH_PREPUSH_TESTS=1` |

#### Architectural alternatives

**Cargo/libtest alone** is the least complex option and automatically includes doctests, but it does not provide stable hard per-test termination. Its stable test order is alphabetical; seeded shuffle remains behind `-Z unstable-options`. A macro timeout such as `rstest::timeout` can report a timeout but is a weaker boundary for tests that block an OS thread or leave child processes behind. ([doc.rust-lang.org](https://doc.rust-lang.org/rustc/tests/?utm_source=openai))

**Cargo-nextest** retains ordinary Rust `#[test]` functions and Cargo integration targets while changing execution to one test per process. It supplies runner-level timeout enforcement, process-tree termination on Unix, filters, profile-specific defaults, ignored-test selection, test groups, and optional sharding. It does not execute doctests and does not randomize same-priority tests: current same-priority order is lexicographic. ([nexte.st](https://nexte.st/docs/features/slow-tests/?utm_source=openai))

**`test-r`** offers literal tags, shared dependencies, stable shuffle, suite-level timeout declarations, and test-runner parallel controls. That is the closest low-level match to pytest. The cost is replacing the standard harness in every target, bringing default Tokio coupling, losing native doctest execution inside that harness, and accepting a documented capture/parallel/dependency-injection limitation. Its current production evidence does not justify making it the foundational harness for a general-purpose template. ([test-r.vigoo.dev](https://test-r.vigoo.dev/))

**Cargo-maelstrom** provides strong process and container isolation, but the currently published Rust path is Linux-oriented, making it ineligible for the owner-fixed Ubuntu + macOS matrix. ([maelstrom-software.com](https://maelstrom-software.com/?utm_source=openai))

#### Recommended execution configuration

```toml
# .config/nextest.toml
nextest-version = "0.9.145"

[profile.default]
# Fast, hermetic, deterministic local baseline.
default-filter = 'not (binary(=slow) | binary(=live))'
test-threads = 1
slow-timeout = { period = "60s", terminate-after = 1, grace-period = "5s" }

[profile.parallel]
inherits = "default"
test-threads = "num-cpus"

[profile.full]
# Authoritative hermetic suite: includes slow, still excludes live.
inherits = "parallel"
default-filter = 'not binary(=live)'
fail-fast = false

[profile.live]
# Explicit external-system suite.
inherits = "default"
default-filter = 'binary(=live)'
test-threads = 1
```

Nextest natively supports the timeout object, custom profiles, `test-threads`, and default filtersets. The 60-second value preserves the Python precedent; individual named overrides may be added only where a demonstrated test contract requires more time. ([nexte.st](https://nexte.st/docs/features/slow-tests/?utm_source=openai))

Canonical commands:

```sh
# Fast, hermetic, serial:
cargo nextest run

# Fast, hermetic, explicitly parallel:
cargo nextest run --profile parallel

# Full hermetic suite: slow tests included; live tests excluded:
cargo nextest run --profile full --run-ignored all

# Rust documentation examples:
cargo test --workspace --doc

# Live tests; scripts/test-live must also check the environment guard:
RS_LAUNCH_LIVE_TESTS=1 \
  cargo nextest run --profile live --run-ignored only
```

#### Test layout

```text
tests/
├── library.rs
├── library/
│   └── ...
├── cli.rs
├── cli/
│   ├── in_process.rs
│   └── process.rs
├── web.rs
├── web/
│   └── ...
├── meta.rs
├── meta/
│   └── ...
├── slow.rs
├── slow/
│   └── ...
├── live.rs
├── live/
│   └── ...
└── support/
    ├── mod.rs
    ├── app.rs
    └── sandbox.rs
```

Top-level files remain Cargo integration-test binaries. They include their submodules with explicit `#[path = "..."]` declarations where needed. This uses Rust’s compilation-unit semantics to make `binary(=slow)` and `binary(=live)` reliable nextest selectors while preserving the py repo’s domain-oriented discoverability rather than copying the ts repo’s flat layout.

`#[ignore]` is reserved by policy for tests in `slow.rs` and `live.rs`:

```rust
#[test]
#[ignore = "slow: run scripts/test-full"]
fn large_fixture_round_trip() {
    // ...
}

#[test]
#[ignore = "live: requires RS_LAUNCH_LIVE_TESTS=1"]
fn calls_real_service() {
    assert_eq!(std::env::var("RS_LAUNCH_LIVE_TESTS").as_deref(), Ok("1"));
    // ...
}
```

Nextest recommends default filters for very slow or specially resourced tests and distinguishes them from `#[ignore]`. Combining both is intentional defense-in-depth: filters supply the taxonomy, while `#[ignore]` prevents an accidental plain `cargo test` invocation from reaching slow/live tests. ([nexte.st](https://nexte.st/docs/selecting/?utm_source=openai))

#### Two-tier CLI pattern

```rust
// src/cli.rs
pub fn run_cli(
    args: impl IntoIterator<Item = std::ffi::OsString>,
    deps: &AppDeps,
    io: &mut CliIo,
) -> Result<std::process::ExitCode, CliError> {
    // Parse, dispatch, and write through injected dependencies and I/O.
}
```

```rust
// src/main.rs
fn main() -> std::process::ExitCode {
    let deps = AppDeps::production();
    let mut io = CliIo::stdio();

    rs_launch_blueprint::cli::run_cli(
        std::env::args_os(),
        &deps,
        &mut io,
    )
    .unwrap_or_else(|error| error.render_and_exit(&mut io))
}
```

```rust
// tests/cli/in_process.rs
#[test]
fn reports_validation_error_without_starting_a_process() {
    let mut fixture = crate::support::AppFixture::new();
    let status = run_cli(
        ["rs-launch", "serve", "--port", "invalid"].map(Into::into),
        fixture.deps(),
        fixture.io_mut(),
    )
    .expect("CLI result");

    assert_eq!(status, std::process::ExitCode::FAILURE);
    assert!(fixture.stderr().contains("invalid port"));
}
```

```rust
// tests/cli/process.rs
#[test]
fn installed_contract_exposes_help() {
    let output = std::process::Command::new(env!("CARGO_BIN_EXE_rs-launch"))
        .arg("--help")
        .output()
        .expect("spawn built rs-launch binary");

    assert!(output.status.success());
    assert!(String::from_utf8_lossy(&output.stdout).contains("Usage:"));
}
```

The subprocess tier uses Cargo’s resolved binary path rather than `cargo run` or `target/debug/...`. Cargo therefore owns freshness and output-directory selection; this remains compatible with any eventual R49 output-shape decision.

#### Shared fixture pattern

`tests/support` supplies explicit builders such as `AppFixture`, `Sandbox`, and `TestServer`. Each test constructs its own fixture; teardown occurs through `Drop`. The pattern forbids test setup that mutates parent-process current directory or process-global environment. Child-only environment variables belong on `std::process::Command`; filesystem state gets a unique namespace; servers bind port `0`.

Nextest’s process-per-test execution already prevents one test’s in-memory globals from leaking into the next test. Expensive suite-level setup scripts remain available, but should be introduced only for immutable or namespace-partitioned resources, because mutable shared services would reintroduce the coupling this design is intended to remove. ([github.com](https://github.com/nextest-rs/nextest/discussions/2879?utm_source=openai))

#### Performance and resource tradeoff

Nextest’s published warm-run benchmark used a 16-core/32-thread Ryzen 9 7950X, 64 GB RAM, Pop!_OS 22.04, Rust 1.66, excluded compilation and doctests, ran each command five times, and recorded the minimum of runs three through five. The nine listed workloads ranged from **1.37× to 3.38×** nextest speedup. This demonstrates workload-dependent potential, not an absolute prediction for `rs-launch-blueprint`. ([nexte.st](https://www.nexte.st/docs/benchmarks/?utm_source=openai))

The relevant template costs are:

- **Serial default:** lower instantaneous CPU/memory use and deterministic local feedback, but slower elapsed time.
- **Parallel profile:** better throughput once the test count grows, but higher process and memory pressure.
- **Process-per-test:** stronger cleanup and timeout enforcement, but process-start overhead for very small tests.
- **Prebuilt nextest executable:** no additional workspace compile cost; compiling nextest from source would be materially more expensive.
- **Windows:** supported but not required, and nextest warns that process creation may make it slower there. ([nexte.st](https://nexte.st/docs/installation/windows/?utm_source=openai))

#### Observable acceptance criteria

1. `cargo nextest list` lists neither `slow` nor `live` tests in the runnable default set.
2. `cargo nextest run --profile full --run-ignored all` runs ordinary and slow tests, but no live test.
3. A live test cannot run unless both the `live` profile and `RS_LAUNCH_LIVE_TESTS=1` are present.
4. A temporary timeout canary exceeds 60 seconds, is terminated by nextest, reports `TIMEOUT`, and returns non-zero.
5. The fast suite passes both serially and under `--profile parallel`.
6. CLI in-process tests can inject a fake dependency without launching a child process.
7. CLI process tests launch the Cargo-built executable without hard-coding a target directory.
8. Breaking a public rustdoc example makes `cargo test --workspace --doc` fail.
9. The installed pre-push hook exits successfully without invoking tests when the opt-in variable is unset.
10. With `RS_LAUNCH_PREPUSH_TESTS=1`, the hook runs exactly the same full-hermetic and doctest commands used by CI.
11. CI exercises the resulting commands on both `ubuntu-latest` and `macos-latest`, and on Rust 1.96 for the MSRV lane.

#### Baseline reviews

`BASELINE-REVIEW: F124 — order-independent tests — replace mandatory randomized scheduling with process-per-test isolation, unique explicit fixtures, and serial-plus-parallel execution; retain seeded shuffle as a re-verification trigger rather than adopting a custom harness now — nextest currently orders equal-priority tests lexicographically, stable libtest shuffle is still unstable, and test-r’s shuffle requires replacing the standard harness and separately restoring doctests.` ([nexte.st](https://nexte.st/docs/configuration/test-priorities/?utm_source=openai))

`BASELINE-REVIEW: F128 — reusable deterministic setup — replace literal autouse-global-fixture parity with explicit RAII fixture construction in Rust — nextest isolates each test in its own process, Rust has no stable first-party autouse fixture mechanism, and hidden global mutation would work against the injected-dependency architecture.` ([github.com](https://github.com/nextest-rs/nextest/discussions/2879?utm_source=openai))

These reviews do not propose silently changing py or ts. A follow-on cross-repository project may retain Python’s logger-reset fixture where same-process pytest execution requires it, retain TypeScript’s local factories, and adopt Rust’s explicit RAII setup; all three preserve the same isolation principle.

---

### Recommendation

Adopt this stack:

1. **Test execution:** `cargo-nextest 0.9.145`, installed as an exactly pinned external tool.
2. **Test definitions:** ordinary stable Rust `#[test]` functions and Cargo integration-test targets—no custom harness.
3. **Doctests:** mandatory separate `cargo test --workspace --doc`.
4. **CLI tests:** two tiers:
   - in-process calls to a public `run_cli` entry point with injected dependencies and I/O;
   - built-artifact smoke tests using `std::process::Command` and `env!("CARGO_BIN_EXE_rs-launch")`.
5. **Fixtures:** explicit `tests/support` builders and RAII teardown; no autouse fixture crate.
6. **Ordering:** no mandatory random-order crate or custom harness; rely on process isolation plus serial and parallel suite execution, with F124 explicitly under baseline review.
7. **Timeout:** 60-second nextest hard timeout for every test, with narrowly justified per-test overrides.
8. **Taxonomy:** dedicated ignored `slow` and `live` integration binaries selected by nextest filtersets.
9. **Parallelism:** serial default; opt-in `parallel` profile; full CI/pre-push suite explicitly selects parallel execution.
10. **Pre-push:** yes—checked-in, optional, default-skip hook running the full hermetic suite plus doctests; live tests remain separately opt-in.
11. **R32-owned Cargo dev-dependencies:** **none**. `assert_cmd` and `rstest` remain documented runner-ups, not baseline dependencies.

This is conditional only on the pre-merge advisory/API recheck recorded below.

---

### Members

#### cargo-nextest 0.9.145

##### Landscape

Cargo/libtest is the first-party baseline; nextest is the established supplemental runner; `test-r`, Maelstrom, and newer custom orchestrators are the emerging alternatives. Nextest is the only surveyed option that combines ordinary Rust tests, process-enforced timeout, filterable profiles, Linux/macOS support, and substantial current practice evidence without replacing the test harness. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/commands/cargo-test.html?utm_source=openai))

##### Principles and implementation

Nextest realizes bounded, isolated execution through one process per test. For Unix targets, timeout termination operates on a process group, allowing a stuck test and its spawned children to be terminated. Its filterset and profile model supports fast/full/live policies without test-framework-specific attributes. ([nexte.st](https://nexte.st/docs/features/slow-tests/?utm_source=openai))

It does **not** supply seeded random order. Same-priority tests currently run lexicographically. Partitioning is for CI sharding, not a substitute for shuffle. ([nexte.st](https://nexte.st/docs/configuration/test-priorities/?utm_source=openai))

##### Dominant choice

`cargo-nextest` is the dominant supplemental choice for this bundle because timeout, isolation, selection, concurrency, and future sharding are execution-runner concerns. Implementing these independently with test macros and shell timeouts would fragment configuration and weaken subprocess cleanup.

##### Qualified shortlist

1. **Cargo/libtest only:** strongest simplicity and first-party status, but insufficient timeout capability.
2. **`test-r 3.0.12`:** strongest literal pytest-feature parity, but custom-harness and doctest drawbacks.
3. **`rstest 0.27.0` on Cargo/libtest:** explicit fixtures and macro timeouts, but not equivalent to process-enforced termination.

##### Excluded by gate

- **Cargo-maelstrom:** fails required macOS gate. ([maelstrom-software.com](https://maelstrom-software.com/?utm_source=openai))
- **Nightly `cargo test -- --shuffle`:** fails stable-Rust constraint. ([github.com](https://github.com/rust-lang/rust/issues/89583))
- **Unpinned latest nextest:** fails reproducibility and MSRV policy because nextest documents that pre-1.0 patch releases may change build MSRV. ([github.com](https://github.com/nextest-rs/nextest?utm_source=openai))

##### Up-and-comers

`test-r` is the most relevant up-and-comer because it already implements tags, stable shuffle, dependency injection, suite properties, and timeouts. Reconsider it if its adoption broadens, it declares and tests an acceptable MSRV, it adds a first-class doctest story, and its capture/parallel/dependency-injection constraint is removed. ([test-r.vigoo.dev](https://test-r.vigoo.dev/))

##### Fit for this template

The CLI + library + web shape benefits from process isolation because artifact tests and listener-based web tests can spawn child processes or sockets. Filtersets map naturally to separate `slow` and `live` test binaries. Installing nextest as a prebuilt tool avoids adding dependencies to the generated application.

##### Recommendation

Pin **`cargo-nextest 0.9.145`**, released September 16, 2026. CI and developer bootstrap must verify `cargo nextest --version` and reject drift. ([github.com](https://github.com/nextest-rs/nextest/releases?utm_source=openai))

Use nextest for unit and integration execution, but not doctests:

```sh
cargo nextest run --profile full --run-ignored all
cargo test --workspace --doc
```

##### Ranked runner-up

Cargo/libtest alone, with external job-level timeouts, is the runner-up. It should be selected only if the owner relaxes the per-test timeout requirement; job-level timeout is not equivalent because one hung test consumes the whole test binary or job.

##### Tradeoffs

- Separate installation and version pin.
- Doctests require a second command.
- Test-per-process startup overhead can dominate very small suites.
- Suite-level mutable globals no longer behave as one shared process—which is desirable here but may surprise contributors.
- Literal random scheduling remains absent.
- The external tool adds supply-chain surface even though it is not linked into the application.

##### Parameters

- Assumes `ci-job-structure` remains unresolved; exposes commands without assigning jobs.
- Assumes `package-manager-invocation` remains unresolved; requires an exact `0.9.145` installation by whichever mechanism R42 selects.
- Assumes `build-tool-output-shape` remains unresolved; nextest delegates builds to Cargo.
- No conflict with R01 or R69.
- R35 must verify its eventual coverage tool’s nextest integration; R32 does not choose that integration.

##### Migration implications

- Add `.config/nextest.toml`.
- Pin nextest in the selected tool/bootstrap manifest.
- Replace the authoritative `cargo test` integration-test step with `cargo nextest run --profile full --run-ignored all`.
- Retain a separate Cargo doctest step.
- Document serial, parallel, full, slow, and live commands.

##### Validation strategy

**Planned, not executed in this research:**

```sh
cargo nextest --version
# Expected: cargo-nextest 0.9.145

cargo nextest run
# Expected: fast tests only, one at a time.

cargo nextest run --profile parallel
# Expected: same selected set and results, concurrent execution.

cargo nextest run --profile full --run-ignored all
# Expected: ordinary + slow, no live.

cargo nextest list --profile live --run-ignored only
# Expected: only tests from the live integration binary.
```

A temporary timeout canary must be configured to exceed the 60-second bound; expected result is `TIMEOUT`, non-zero status, and no surviving child process.

##### Confidence & re-verify trigger

**Confidence: high on functional fit; medium on completed maintenance gate.**

Reverify when:

- nextest 1.0 is released;
- nextest adds doctest or stable randomized-scheduling support;
- Rust issue #89583 closes with stabilization;
- the selected coverage tool cannot drive nextest;
- measured warm execution on this workspace shows process overhead outweighing the isolation benefits;
- exact API/RustSec checks below cannot be completed before implementation.

##### Sources

**Required figure audit**

| Figure | Required endpoint | Result on 2026-09-26 |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/cargo-nextest` → `crate.recent_downloads` | **EVIDENCE-GAP:** endpoint inaccessible; no estimate substituted. ([]()) |
| All-time downloads | same → `crate.downloads` | **EVIDENCE-GAP:** endpoint inaccessible. ([]()) |
| Last release | `GET https://crates.io/api/v1/crates/cargo-nextest/versions` | API inaccessible. GitHub release corroborates `0.9.145`, September 16, 2026, but this is not substituted for the required crates.io field. ([]()) |
| Stars, archived, pushed | `GET https://api.github.com/repos/nextest-rs/nextest` | **EVIDENCE-GAP:** API inaccessible. GitHub UI showed approximately 3.3k stars and did not mark the repository archived; rounded UI data is not accepted as the exact figure. ([]()) |
| Open issues | `GET https://api.github.com/search/issues?q=repo:nextest-rs/nextest+is:issue+is:open` | **EVIDENCE-GAP:** API inaccessible; UI count not substituted. ([]()) |
| Responsiveness | ten newest issues plus comment timelines | **EVIDENCE-GAP:** issue endpoint inaccessible; median and unanswered count not calculated. ([]()) |
| Advisories | `https://rustsec.org/packages/cargo-nextest.html` | **EVIDENCE-GAP:** endpoint inaccessible. Adoption is conditional on a clean recheck. ([]()) |
| Adopters | reverse dependencies plus project manifests | Reverse-dependency page requires JavaScript; direct evidence: NVIDIA OpenShell pins nextest in `mise.lock`. ([crates.io](https://crates.io/crates/cargo-nextest/reverse_dependencies)) |

**Maintenance classification:** **active**, based on release recency and current documentation/repository activity; exact API figures remain outstanding. ([github.com](https://github.com/nextest-rs/nextest?utm_source=openai))

**Unsafe posture:** external executable, not linked into generated binaries. No claim of an unsafe-free transitive tree is made; verify release attestations/checksums and the RustSec database before adoption. Nextest publishes release attestations and platform-specific assets. ([github.com](https://github.com/nextest-rs/nextest/releases?utm_source=openai))

---

#### Cargo/libtest doc-test lane — Rust 1.96 minimum, Rust 1.98.1 current

##### Landscape

Cargo/libtest is the built-in first-party testing foundation. It compiles the test binaries that nextest consumes and remains the authoritative rustdoc test executor because nextest does not run doctests. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/commands/cargo-test.html?utm_source=openai))

##### Principles and implementation

Rust documentation examples are part of the public library contract. The full gate must therefore execute `cargo test --workspace --doc` separately rather than assuming the nextest run covers them.

##### Dominant choice

Cargo/rustdoc is the only first-party and ecosystem-standard doctest executor. No additional crate should mediate this lane.

##### Qualified shortlist

A single `cargo test --workspace` command would run ordinary and documentation tests together, but would discard nextest’s process timeout, filters, and isolation. It is therefore a fallback, not the recommended composition.

##### Excluded by gate

Custom harnesses that do not support doctests cannot replace this member. `test-r` explicitly lists doctests as unsupported. ([test-r.vigoo.dev](https://test-r.vigoo.dev/))

##### Up-and-comers

None is warranted. Doctest execution is tightly coupled to rustdoc and the toolchain; a third-party replacement would add risk without solving an identified gap.

##### Fit for this template

The project includes a public library, so executable examples are materially useful. CLI-only examples may use `no_run` where execution is inappropriate, but library examples should normally compile and run.

##### Recommendation

Run:

```sh
cargo test --workspace --doc
```

using the same feature selection eventually established by the workspace’s feature policy. R32 does not assume `--all-features`.

##### Ranked runner-up

Run `cargo test --workspace` as the sole runner if nextest is removed. This is operationally simpler but fails R32’s timeout and execution-control recommendation.

##### Tradeoffs

- A second build/test command is visible in CI and hooks.
- Some test artifacts may be rebuilt or relinked.
- Doctests have different source-location and crate-wrapping semantics from normal integration tests.
- The clarity of an explicit docs lane outweighs the extra command.

##### Parameters

- Assumes `ci-job-structure = unresolved`; doctests may be a step or separate job.
- Assumes `package-manager-invocation = Cargo-native command, wrapped later if desired`.
- No dependency on R01, R49, or R69.

##### Migration implications

- Add at least one useful executable example to public library API documentation.
- Add the doctest command to the canonical full-suite script.
- Add the same command to CI and opt-in pre-push execution.
- Ensure examples do not depend on live credentials or mutable global environment.

##### Validation strategy

**Planned:**

1. Run `cargo test --workspace --doc`; expect success.
2. Temporarily change an asserted example result; expect failure.
3. Restore it and test on Rust 1.96, 1.98.1, Ubuntu, and macOS.
4. Confirm the pre-push script reaches this command only when opted in.

##### Confidence & re-verify trigger

**Confidence: very high.**

Reverify only if nextest gains first-class doctest support with equivalent reporting and timeout behavior, or rustdoc materially changes doctest execution semantics.

##### Sources

Crate download, release, repository, issue, responsiveness, and RustSec figures are **inapplicable**: this member is part of the Rust toolchain, not a separately selected crate.

- Cargo test documentation: `https://doc.rust-lang.org/cargo/commands/cargo-test.html`
- Rust test harness documentation: `https://doc.rust-lang.org/rustc/tests/`
- Current Rust releases: `https://blog.rust-lang.org/releases/`
- Rust Forge release state: `https://forge.rust-lang.org/`

---

#### Two-tier CLI and explicit RAII fixture pattern — standard library, no crate

##### Landscape

The built-in option is `std::process::Command`, Cargo’s built-binary environment variables, ordinary functions, and RAII. Established add-ons are `assert_cmd 2.2.2` for subprocess assertions and `rstest 0.27.0` for fixture injection. Up-and-comers such as `test-r`, `rustest`, `rigtest`, and `assay` provide increasingly framework-like fixture behavior. ([docs.rs](https://docs.rs/crate/assert_cmd/latest/source/Cargo.toml?utm_source=openai))

##### Principles and implementation

The shared architectural principle from ts is retained exactly: most CLI behavior is tested through an in-process entry point with injected dependencies, while a small subprocess tier proves that the built artifact starts, parses arguments, maps exit status, and writes to real stdout/stderr.

The Python autouse fixture is not copied literally. Its purpose—preventing cross-test global state—is realized through explicit fixture creation, scoped dependencies, and nextest process isolation.

##### Dominant choice

A thin binary over a public library entry point is the dominant Rust architecture. Tests should not call `main`, invoke `cargo run`, or duplicate command behavior in a test-only parser.

##### Qualified shortlist

- **`assert_cmd 2.2.2`:** add if the process tier grows beyond a few smoke tests or needs extensive stdin/predicate ergonomics. It declares Rust 1.85 and an MIT OR Apache-2.0 license. ([docs.rs](https://docs.rs/crate/assert_cmd/latest/source/Cargo.toml?utm_source=openai))
- **`rstest 0.27.0`:** add if fixture graphs become complex enough that explicit builders become repetitive. Its fixture functions remain explicit rather than autouse. ([docs.rs](https://docs.rs/crate/rstest/latest?utm_source=openai))

##### Excluded by gate

- `ctor`-style process initialization is excluded architecturally: setup becomes implicit, can affect production binaries if misconfigured, and fights process-per-test isolation.
- Global current-directory mutation is excluded because parallel execution makes it inherently race-prone.
- `serial_test` is not needed as a baseline dependency; tests requiring global serialization should first be redesigned around child-local environment, unique paths, and injected state.
- Snapshot/golden CLI frameworks are excluded because R33 owns that decision.

##### Up-and-comers

`test-r` and `rustest` provide pytest-like dependency graphs and global fixtures. They should be reconsidered only if the project develops expensive shared integration infrastructure that cannot be represented by explicit builders or nextest setup scripts. ([raw.githubusercontent.com](https://raw.githubusercontent.com/vigoo/test-r/master/book/src/advanced_features/dependency_injection.md))

##### Fit for this template

The template’s library shape already creates the seam needed by in-process CLI tests. The web-service shape benefits from the same `AppDeps` construction. The binary smoke tier remains independent of R49 because it asks Cargo for the executable path rather than assuming a target directory.

##### Recommendation

Use no R32-owned fixture or CLI-testing dependency initially.

Provide:

- `src/cli.rs::run_cli`;
- thin `src/main.rs`;
- `tests/support::AppFixture`;
- `tests/cli/in_process.rs`;
- `tests/cli/process.rs`;
- `std::process::Command` with `env!("CARGO_BIN_EXE_rs-launch")`.

Keep the process tier intentionally small: help, version, one successful command, one exit-code/error-path contract, and any packaging-sensitive behavior that cannot be tested in-process.

##### Ranked runner-up

Add:

```toml
[dev-dependencies]
assert_cmd = "2.2.2"
rstest = { version = "0.27.0", default-features = false }
```

only after measured repetition justifies them. `rstest`’s default async-timeout feature should not be enabled merely for timeouts because nextest already owns timeout enforcement.

##### Tradeoffs

- Standard-library assertions are more verbose than `assert_cmd`.
- Explicit fixture builders create some boilerplate.
- The benefit is zero R32 dev-dependency compile cost, transparent lifecycle, and no proc-macro coupling.
- Process tests remain slower than in-process tests and should not duplicate every CLI case.

##### Parameters

- Assumes `http-transport-injection-seam = unresolved but constructible through AppDeps`; no concrete transport or mock crate is selected.
- Assumes `build-tool-output-shape = unresolved`; the pattern uses Cargo’s executable path and does not hard-code output directories.
- Assumes `web-extra-surface = unresolved`; `tests/web.rs` can adopt the same fixture.
- No `CONFLICT` with R01, R49, or R69.

##### Migration implications

- Move command parsing and dispatch out of `main`.
- Make production dependency construction a separate function or constructor.
- Route stdout/stderr through an injectable `CliIo`.
- Add explicit test support modules.
- Eliminate tests that mutate global process state where a child-local or injected value is possible.

##### Validation strategy

**Planned:**

- In-process test supplies a failing fake dependency and verifies exit mapping without a child process.
- Process test runs `--help` and checks successful status.
- Process test supplies malformed input and checks the actual executable’s non-zero status.
- Rename or relocate `target`; tests must still locate the binary.
- Run the process tests through nextest’s timeout canary and confirm spawned children are removed.

##### Confidence & re-verify trigger

**Confidence: high.**

Add `assert_cmd` if the process tier grows beyond roughly four focused tests, requires streaming stdin, or develops repeated output/status boilerplate. Add a fixture crate only if explicit builders show measurable duplication or lifecycle bugs.

##### Sources

For the **selected standard-library pattern**, crate popularity and maintenance figures are **inapplicable**.

For qualified add-ons, the mandated exact metrics were not completed because their crates.io/GitHub/RustSec endpoints were inaccessible. This is an evidence gap, not a negative maintenance verdict. ([]())

- Cargo environment variables: `https://doc.rust-lang.org/cargo/reference/environment-variables.html`
- `assert_cmd 2.2.2` manifest: `https://docs.rs/crate/assert_cmd/latest/source/Cargo.toml`
- `rstest` documentation: `https://docs.rs/rstest/latest/rstest/`
- Rust fixture proposal/background: `https://github.com/rust-lang/rust/issues/117668`

---

#### Slow/live taxonomy and optional pre-push policy — repository pattern, no crate

##### Landscape

Built-in mechanisms are `#[ignore]`, test naming, shell scripts, and repository Git hooks. Nextest adds default filters and profiles. Framework alternatives include `test-r` tags; hook-manager alternatives include Lefthook or a Rust-specific hook installer.

##### Principles and implementation

The principle is **fast and hermetic by default, explicit access to cost or external systems, and no mandatory hidden developer latency**.

The taxonomy is deliberately small:

- **ordinary:** fast, hermetic, default;
- **slow:** hermetic but unsuitable for every edit/test cycle;
- **live:** depends on external credentials or a real network service.

A test cannot be both silently default and live. Quarantining flaky tests with `#[ignore]` is forbidden; ignored status is reserved for this taxonomy.

##### Dominant choice

Dedicated integration binaries combined with nextest filters are the dominant choice because they work without a custom tagging crate and make the categories visible in paths, test binary IDs, and commands.

##### Qualified shortlist

- `#[ignore]` plus substring filtering only: simpler but category matching is less reliable.
- `test-r` tags: richer and orthogonal, but require the custom harness.
- Lefthook: appropriate if R42 later adopts it as shared repository tooling; it should still call the canonical script rather than duplicate commands.

##### Excluded by gate

- Cargo feature-gating live tests is rejected as the baseline because it removes tests from discovery and mixes test policy into public feature resolution.
- Mandatory pre-push testing is rejected because hooks must not make commits or pushes depend on local machine capacity.
- Pre-push execution of live tests is rejected because credentials and network reachability are not universal.
- A hook that overwrites an existing `core.hooksPath` is rejected; installation must detect and refuse conflicting configuration.

##### Up-and-comers

`test-r` tags are the relevant future option if the taxonomy grows into several independent dimensions. Its current syntax can select and skip tags directly, including compound tag expressions. ([raw.githubusercontent.com](https://raw.githubusercontent.com/vigoo/test-r/master/book/src/advanced_features/tags.md))

##### Fit for this template

A CLI + web-service template is likely to gain real HTTP-service checks eventually, making an explicit live category valuable from the beginning. The separate slow category avoids conflating local resource cost with real external dependency.

##### Recommendation

Add canonical scripts:

```sh
# scripts/test-full
#!/bin/sh
set -eu

cargo nextest run --profile full --run-ignored all
cargo test --workspace --doc
```

```sh
# scripts/test-live
#!/bin/sh
set -eu

if [ "${RS_LAUNCH_LIVE_TESTS:-0}" != "1" ]; then
    echo "set RS_LAUNCH_LIVE_TESTS=1 to run live tests" >&2
    exit 2
fi

cargo nextest run --profile live --run-ignored only
```

Add an optional checked-in hook:

```sh
# .githooks/pre-push
#!/bin/sh
set -eu

if [ "${RS_LAUNCH_PREPUSH_TESTS:-0}" != "1" ]; then
    exit 0
fi

exec ./scripts/test-full
```

Hook installation is explicit:

```sh
git config core.hooksPath .githooks
```

The installer or setup task must first verify that `core.hooksPath` is absent or already equals `.githooks`.

##### Ranked runner-up

If R42 selects Lefthook for the Rust repository, express the same environment guard there and call `scripts/test-full`. The script remains the contract; the hook manager is replaceable wiring.

##### Tradeoffs

- `#[ignore]` is not intrinsically typed as slow or live; the file/binary convention supplies that type.
- Running the full suite requires `--run-ignored all`.
- Contributors must learn three named commands.
- The optional hook can still be slow, but only users who set the opt-in variable incur that cost.
- Live tests receive no automatic CI guarantee until R11 assigns them an appropriately credentialed lane.

##### Parameters

- Assumes `package-manager-invocation = unresolved`; scripts use Cargo-native commands and can later be wrapped.
- Assumes `ci-job-structure = unresolved`; R32 supplies the hermetic-full and live command boundaries.
- No need for R11 or R42 to change values.
- No conflicts.

##### Migration implications

- Add `tests/slow.rs` and `tests/live.rs`.
- Move tests into those files based on behavior, not historical location.
- Add ignore reasons containing `slow:` or `live:`.
- Add scripts and hook.
- Add contributor documentation describing installation and environment flags.
- Add a lint/meta-test that rejects ignored tests outside the two category binaries.

##### Validation strategy

**Planned:**

```sh
cargo nextest list
# Expected: slow/live excluded from runnable set.

cargo nextest list --profile full --run-ignored all
# Expected: slow included, live excluded.

cargo nextest list --profile live --run-ignored only
# Expected: live only.

env -u RS_LAUNCH_PREPUSH_TESTS .githooks/pre-push
# Expected: immediate success and no test output.

RS_LAUNCH_PREPUSH_TESTS=1 .githooks/pre-push
# Expected: full hermetic nextest suite, followed by doctests.
```

A meta-test should parse `cargo nextest list --message-format json` and fail if an ignored test belongs to a binary other than `slow` or `live`.

##### Confidence & re-verify trigger

**Confidence: high on policy, medium-high on hook mechanism.**

Reverify if R42 chooses an existing hook manager, if Windows becomes required, if the taxonomy needs orthogonal tags, or if live tests become part of a credentialed required CI lane.

##### Sources

All crate metrics are **inapplicable** because this member is a repository policy and script pattern.

- Nextest selecting/default filters: `https://nexte.st/docs/selecting/`
- Nextest filterset DSL: `https://nexte.st/docs/filtersets/`
- Nextest configuration reference: `https://nexte.st/docs/configuration/reference/`
- Rust ignored tests: `https://doc.rust-lang.org/rustc/tests/`
- `test-r` tags: `https://test-r.vigoo.dev/advanced_features/tags.html`

---

### Compatibility

There is no single public adopter proving this exact four-member bundle, so compatibility is established by the protocol and a required version matrix:

1. Nextest builds ordinary Cargo/libtest integration targets and invokes each discovered test separately. The CLI and fixture members remain ordinary Rust code, so they require no nextest-specific test attributes. ([nexte.st](https://nexte.st/docs/running/?utm_source=openai))
2. The built-binary test is a Cargo integration test and uses Cargo’s executable path, so it is discoverable by nextest without custom rebuild logic.
3. Doctests are intentionally outside nextest and are run by Cargo/rustdoc.
4. Profiles, filtersets, ignored-test selection, and process timeout are all supplied by the same pinned nextest release.
5. The scripts and hook call only the two canonical commands; they do not reinterpret test selection.

Required integration matrix:

| Toolchain | OS | Commands |
|---|---|---|
| Rust **1.96** | `ubuntu-latest` | fast serial, fast parallel, full hermetic, doctests |
| Rust **1.96** | `macos-latest` | full hermetic, doctests |
| Rust **1.98.1 stable** | `ubuntu-latest` | full hermetic, doctests, timeout contract |
| Rust **1.98.1 stable** | `macos-latest` | full hermetic, doctests, subprocess CLI contract |

`cargo-nextest 0.9.145` declares a build MSRV of Rust 1.91 in its current repository documentation, below the template’s current 1.96 MSRV. Exact pinning is important because the project permits MSRV movement within the 0.9 patch series. ([github.com](https://github.com/nextest-rs/nextest?utm_source=openai))

---

### Parameters

```text
owns test-runner = cargo-nextest 0.9.145, exact tool pin
owns cli-test-tiers = in-process run_cli tests + Cargo-built subprocess smoke tests
owns test-order-policy = deterministic process-isolated execution; no mandatory shuffle; BASELINE-REVIEW F124
owns per-test-timeout = 60 seconds, nextest process-enforced
owns shared-fixture-policy = explicit tests/support builders and RAII; no autouse fixture crate
owns test-file-organization = domain integration binaries plus submodules
owns slow-live-taxonomy = ignored slow/live binaries selected by nextest profiles
owns parallel-execution = serial default; opt-in parallel profile; full gate explicitly parallel
owns doc-test-policy = cargo test --workspace --doc is required
owns pre-push-policy = optional, default-skip, RS_LAUNCH_PREPUSH_TESTS=1, full hermetic + doctests
owns R32-dev-dependencies = none

assumes http-transport-injection-seam = unresolved; any R01 result must be constructible through injected AppDeps rather than global state
assumes ci-job-structure = unresolved; R32 exposes canonical full-hermetic, doctest, and live commands without placing them in jobs
assumes package-manager-invocation = unresolved; R42 must install and verify cargo-nextest 0.9.145
assumes build-tool-output-shape = unresolved; subprocess tests use Cargo-provided binary paths
assumes web-extra-surface = unresolved; tests/web.rs and the shared fixture can accommodate any R69 result

CONFLICT: none
```

---

### Migration implications

| File | Change |
|---|---|
| `Cargo.toml` | No R32 dev-dependencies. Preserve `edition = "2024"` and current `rust-version = "1.96"` under the fixed policy. Ensure the CLI has a named binary target. |
| `.config/nextest.toml` | Add pinned-version requirement, timeout, filters, and default/parallel/full/live profiles. |
| `src/lib.rs` | Export the CLI application seam. |
| `src/cli.rs` | Add `run_cli(args, deps, io)` or equivalent. |
| `src/main.rs` | Reduce to production dependency construction, stdio wiring, and exit mapping. |
| `tests/library.rs` | Library-level integration entry. |
| `tests/cli.rs` | Includes in-process and process submodules. |
| `tests/cli/in_process.rs` | Most CLI behavioral cases. |
| `tests/cli/process.rs` | Small built-binary contract tier. |
| `tests/web.rs` | Web/router/service tests, exact scope deferred to R69. |
| `tests/meta.rs` | Layout and ignored-test taxonomy assertions. |
| `tests/slow.rs` | Ignored hermetic slow tests. |
| `tests/live.rs` | Ignored external live tests with environment guard. |
| `tests/support/*` | Explicit reusable fixtures, unique sandboxes, dependency builders, optional per-test listener. |
| `scripts/test-full` | Full hermetic nextest suite followed by doctests. |
| `scripts/test-live` | Guarded live suite. |
| `.githooks/pre-push` | Optional default-skip full-suite hook. |
| CI workflow selected by R11 | Install/verify nextest 0.9.145 and call the canonical commands; placement and path filtering remain R11-owned. |
| Contributor documentation | Commands, hook installation, opt-in variables, category policy, timeout policy. |

No property-test, snapshot, mock-transport, freshness-lane, or coverage dependency is added by R32.

---

### Validation strategy

**Executed during this research**

- Reviewed current Rust/Cargo/libtest documentation and the open shuffle tracking issue.
- Reviewed nextest timeout, filtering, profile, scheduling, partitioning, platform, process-model, and benchmark documentation.
- Reviewed `test-r`, `rstest`, `assert_cmd`, Maelstrom, `rigtest`, `rustest`, and `assay` documentation.
- Confirmed current Rust stable as 1.98.1 and nextest’s latest GitHub release as 0.9.145.
- Did **not** build or execute an `rs-launch-blueprint` integration repository.
- Required crates.io/GitHub API/RustSec metric endpoints were attempted but not successfully retrieved.

**Planned implementation checks**

```sh
# 1. Exact tool version.
cargo nextest --version
# Expected: cargo-nextest 0.9.145
```

```sh
# 2. Fast serial baseline.
cargo nextest run
# Expected: ordinary tests only; no slow/live; test-threads = 1.
```

```sh
# 3. Explicit concurrency.
cargo nextest run --profile parallel
# Expected: identical selected test set and results under num-cpus execution.
```

```sh
# 4. Authoritative hermetic suite.
cargo nextest run --profile full --run-ignored all
# Expected: ordinary and slow tests; no live tests; all failures collected.
```

```sh
# 5. Documentation contract.
cargo test --workspace --doc
# Expected: all rustdoc examples pass.
```

```sh
# 6. Live guard.
./scripts/test-live
# Expected: exit 2 without the environment variable.

RS_LAUNCH_LIVE_TESTS=1 ./scripts/test-live
# Expected: only ignored live tests execute.
```

```sh
# 7. Hook default skip.
env -u RS_LAUNCH_PREPUSH_TESTS .githooks/pre-push
# Expected: immediate exit 0.
```

```sh
# 8. Hook opt-in.
RS_LAUNCH_PREPUSH_TESTS=1 .githooks/pre-push
# Expected: same full hermetic and doctest commands as CI.
```

**Timeout acceptance check**

Temporarily add a test that starts a child sleeping longer than 60 seconds. Run it through nextest and verify:

- result is `TIMEOUT`;
- command exits non-zero;
- elapsed time is the configured period plus at most the grace period and normal scheduling overhead;
- the child no longer exists after nextest exits.

**CLI-tier acceptance check**

- Introduce a fake injected dependency that can only be reached in-process; verify no child process is spawned.
- In the process tier, run `--help`, `--version`, one success path, and one error/exit-code path.
- Run with a non-default Cargo target directory; the process tier must still locate the binary.
- Remove or stale the prior binary, modify source, and rerun; Cargo/nextest must build the current artifact without custom staleness code.

**Taxonomy acceptance check**

Use `cargo nextest list --message-format json` in a meta-test or validation script to assert:

- no ignored test exists outside `slow` or `live`;
- default runnable set contains neither category;
- full contains slow and excludes live;
- live contains only live tests.

**Performance characterization—not a selection gate**

After the realistic example exists, perform warm-build measurements for:

1. `cargo nextest run`;
2. `cargo nextest run --profile parallel`;
3. `cargo nextest run --profile full --run-ignored all`.

Record wall, user, and system time plus peak resident memory using platform-appropriate `/usr/bin/time` on Ubuntu and macOS. State CPU count, test count, test-binary count, whether artifacts were warm, and the number of repetitions. Do not infer “fastest” from nextest’s published unlike workloads.

---

### Confidence & re-verify trigger

**Overall confidence: 0.84.**

- **0.92** that nextest + separate doctests is the best architectural fit.
- **0.90** that the two-tier CLI and explicit RAII-fixture design is appropriate.
- **0.82** that serial-default/parallel-opt-in is the right policy given the explicit F131 objective.
- **0.72** on final dependency fitness until the mandated exact API, issue-response, and RustSec checks are completed.
- **0.70** on the F124 baseline review because the owner may still prefer literal randomized scheduling despite the custom-harness cost.

Reverify when any of these occurs:

1. **Before implementation lock:** retrieve all required exact crates.io, GitHub API, issue-response, and RustSec fields.
2. **October 1, 2026:** Rust 1.99 is scheduled to become stable; stable-minus-two becomes Rust 1.97. Per owner policy, raise the template MSRV only in a minor release, not silently.
3. Nextest reaches 1.0 or changes its MSRV/versioning policy.
4. Nextest gains native doctest or seeded random-order support.
5. Rust issue #89583 stabilizes `libtest --shuffle`.
6. R01, R11, R42, R49, or R69 publishes a decision that invalidates an assumption above.
7. R35 selects a coverage tool without a supported nextest execution path.
8. The realistic suite’s measured process overhead is materially worse than Cargo/libtest on both Ubuntu and macOS.
9. The fixture graph grows enough that explicit builders become a demonstrated maintenance problem.
10. The slow/live taxonomy grows beyond two mostly exclusive categories.

---

### Sources

All web sources retrieved **September 26, 2026**.

| ID | Source | URL | Authority/use |
|---|---|---|---|
| S1 | Cargo test command | https://doc.rust-lang.org/cargo/commands/cargo-test.html | First-party Cargo test and doctest semantics |
| S2 | Rustc test harness | https://doc.rust-lang.org/rustc/tests/ | First-party test options, ignored tests, parallelism, shuffle status |
| S3 | Rust shuffle tracking issue #89583 | https://github.com/rust-lang/rust/issues/89583 | Official stabilization state |
| S4 | Rust Forge | https://forge.rust-lang.org/ | Current stable/beta/nightly versions |
| S5 | Rust release announcements | https://blog.rust-lang.org/releases/ | Current stable release dates |
| S6 | Nextest slow tests and timeouts | https://nexte.st/docs/features/slow-tests/ | Native timeout semantics and process termination |
| S7 | Nextest selecting tests | https://nexte.st/docs/selecting/ | Default filters and ignored-test policy |
| S8 | Nextest filterset DSL | https://nexte.st/docs/filtersets/ | Test/package/binary selectors |
| S9 | Nextest configuration reference | https://nexte.st/docs/configuration/reference/ | Profiles, threads, timeouts, filters |
| S10 | Nextest test priorities | https://nexte.st/docs/configuration/test-priorities/ | Current lexicographic ordering |
| S11 | Nextest partitioning | https://nexte.st/docs/ci-features/partitioning/ | Slice/hash sharding, not shuffle |
| S12 | Nextest process model | https://nexte.st/docs/design/how-it-works/ | Process-per-test architecture |
| S13 | Nextest benchmarks | https://nexte.st/docs/benchmarks/ | Workloads, hardware, commands, timings |
| S14 | Nextest release repository | https://github.com/nextest-rs/nextest/releases | Current exact release |
| S15 | Nextest repository | https://github.com/nextest-rs/nextest | License, MSRV policy, macOS support |
| S16 | Nextest release URLs | https://nexte.st/docs/installation/release-urls/ | Linux, macOS, and Windows artifacts |
| S17 | Nextest Windows notes | https://nexte.st/docs/installation/windows/ | Windows process-overhead caveat |
| S18 | Nextest setup scripts | https://nexte.st/docs/configuration/setup-scripts/ | Optional suite-level setup |
| S19 | `test-r` getting started | https://test-r.vigoo.dev/ | Harness replacement, doctest and capture limitations |
| S20 | `test-r` running tests | https://test-r.vigoo.dev/core_features/running_tests.html | Stable shuffle and parallel controls |
| S21 | `test-r` tags | https://raw.githubusercontent.com/vigoo/test-r/master/book/src/advanced_features/tags.md | Tag taxonomy and filtering |
| S22 | `test-r` per-test configuration | https://raw.githubusercontent.com/vigoo/test-r/master/book/src/advanced_features/per_test_configuration.md | Timeouts and sequential suites |
| S23 | `test-r` dependency injection | https://raw.githubusercontent.com/vigoo/test-r/master/book/src/advanced_features/dependency_injection.md | Shared dependency model |
| S24 | `test-r` sharing strategies | https://raw.githubusercontent.com/vigoo/test-r/master/book/src/advanced_features/dependency_sharing.md | Resource and parallelism tradeoffs |
| S25 | `rstest` | https://docs.rs/rstest/latest/rstest/ | Established fixture and timeout alternative |
| S26 | `assert_cmd 2.2.2` manifest | https://docs.rs/crate/assert_cmd/latest/source/Cargo.toml | Version, license, and MSRV |
| S27 | Maelstrom | https://maelstrom-software.com/ | Linux-focused alternative runner |
| S28 | Rust fixture proposal | https://github.com/rust-lang/rust/issues/117668 | Evidence that first-party fixtures remain unresolved |
| S29 | NVIDIA OpenShell nextest pin | https://github.com/NVIDIA/OpenShell/blob/main/mise.lock | Direct nextest adopter evidence |
| S30 | Golem Cloud GitHub organization | https://github.com/golemcloud/ | Direct context for documented `test-r` adopter |
| S31 | Rust 2025 annual survey | https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2025/annual-survey/report/annual-survey-2025-report.pdf | Ecosystem tooling and MSRV context |
| S32 | Cargo environment variables | https://doc.rust-lang.org/cargo/reference/environment-variables.html | Built-binary path contract |
| S33 | Required crates.io endpoint | https://crates.io/api/v1/crates/cargo-nextest | Exact download figures; retrieval failed |
| S34 | Required versions endpoint | https://crates.io/api/v1/crates/cargo-nextest/versions | Exact non-yanked release field; retrieval failed |
| S35 | Required GitHub repository endpoint | https://api.github.com/repos/nextest-rs/nextest | Exact stars/archive/push fields; retrieval failed |
| S36 | Required GitHub issue-search endpoint | https://api.github.com/search/issues?q=repo%3Anextest-rs%2Fnextest+is%3Aissue+is%3Aopen | Exact open-issue count; retrieval failed |
| S37 | Required RustSec endpoint | https://rustsec.org/packages/cargo-nextest.html | Advisory gate; retrieval failed |

**Owner-supplied, non-public evidence:** the cited py/ts repository paths, `docs/port/COMMONALITY.md`, `docs/port/PARAMETERS.md`, `docs/port/DIVERGENCE-ANALYSIS.md`, and `ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md` were supplied directly in the prompt and therefore have no public source URL.

## Sources

- [Tests - The rustc book](https://doc.rust-lang.org/rustc/tests/?utm_source=openai)
- [Slow tests and timeouts - cargo-nextest](https://nexte.st/docs/features/slow-tests/?utm_source=openai)
- [Getting started - test-r](https://test-r.vigoo.dev/)
- [The Rust Release Announcements](https://blog.rust-lang.org/releases/?utm_source=openai)
- [What is the oldest version of Rust you use for any development task?](https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2025/annual-survey/report/annual-survey-2025-report.pdf?utm_source=openai)
- [OpenShell/mise.lock at main · NVIDIA/OpenShell · GitHub](https://github.com/NVIDIA/OpenShell/blob/main/mise.lock?utm_source=openai)
- [Benchmarks - cargo-nextest](https://www.nexte.st/docs/benchmarks/?utm_source=openai)
- [GitHub - nextest-rs/nextest: A next-generation test runner for Rust. · GitHub](https://github.com/nextest-rs/nextest?utm_source=openai)
- [test_r - Rust](https://docs.rs/test-r/latest/test_r/?search=test_r)
- [Maelstrom Software](https://maelstrom-software.com/?utm_source=openai)
- [assert_cmd 2.2.2 - Docs.rs](https://docs.rs/crate/assert_cmd/latest/source/Cargo.toml?utm_source=openai)
- [rstest 0.27.0 - Docs.rs](https://docs.rs/crate/rstest/latest?utm_source=openai)
- [Selecting tests - cargo-nextest](https://nexte.st/docs/selecting/?utm_source=openai)
- [fresh process environment for each test? · nextest-rs nextest · Discussion #2879 · GitHub](https://github.com/nextest-rs/nextest/discussions/2879?utm_source=openai)
- [Windows - cargo-nextest](https://nexte.st/docs/installation/windows/?utm_source=openai)
- [Test priorities - cargo-nextest](https://nexte.st/docs/configuration/test-priorities/?utm_source=openai)
- [cargo test - The Cargo Book](https://doc.rust-lang.org/cargo/commands/cargo-test.html?utm_source=openai)
- [Tracking Issue for `shuffle` and `shuffle-seed` · Issue #89583 · rust-lang/rust · GitHub](https://github.com/rust-lang/rust/issues/89583)
- [Releases · nextest-rs/nextest · GitHub](https://github.com/nextest-rs/nextest/releases?utm_source=openai)
- [crates.io: Rust Package Registry](https://crates.io/crates/cargo-nextest/reverse_dependencies)
- [https://raw.githubusercontent.com/vigoo/test-r/master/book/src/advanced_features/dependency_injection.md](https://raw.githubusercontent.com/vigoo/test-r/master/book/src/advanced_features/dependency_injection.md)
- [https://raw.githubusercontent.com/vigoo/test-r/master/book/src/advanced_features/tags.md](https://raw.githubusercontent.com/vigoo/test-r/master/book/src/advanced_features/tags.md)
- [Running tests - cargo-nextest](https://nexte.st/docs/running/?utm_source=openai)