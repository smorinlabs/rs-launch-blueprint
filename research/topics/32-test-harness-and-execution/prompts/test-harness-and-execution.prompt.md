# Deep-research prompt — Test harness and execution behavior (R32, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: what test runner `rs-launch-blueprint` uses and how it configures execution behavior — CLI test tiers (in-process vs. built-binary), randomized execution order, per-test timeout enforcement, a shared cross-test fixture/setup mechanism, test file organization, an opt-in slow/live test-marker taxonomy, an opt-in parallel-execution flag, Rust's built-in doc-test execution, and whether the full suite also runs as an opt-in pre-push git hook. Item kind: `bundle`. Value test: if this answer is wrong, the workspace's `tests/` directory layout, `Cargo.toml` dev-dependencies, the CI test step, and any pre-push hook wiring all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): the two repos diverge. py runs pytest with a rich plugin stack — randomized order, per-test timeout, opt-in parallelism, an opt-in slow/live marker taxonomy, and an autouse global fixture — against one CLI test tier (in-process `CliRunner`). ts runs Vitest with none of those plugins, local per-file factory helpers instead of a global fixture, flat (non-subdirected) test files, and two CLI test tiers: in-process plus a subprocess tier spawning the built binary; ts also adds an opt-in, default-skip pre-push hook that runs the full suite. Evidence: py `Justfile:260` — `uv run pytest {{options}}` via `just test`; ts `Justfile:144` — `pnpm exec vitest run {{options}}` via `just test`. Ledger rows: F117, F118, F124, F125, F128, F129, F130, F131, F132, F173 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT` (F132 individually is `RUST-ONLY`: neither repo has a doc-test-execution convention).
- Per-row evidence for the rest of this bundle: F118 CLI test tiers — py `tests/cli/test_pylb.py:9` (single tier, in-process `CliRunner` only); ts `tests/cli-core.test.ts:11` (in-process `runCli(argv,deps)` tier) and `tests/e2e.test.ts:94` (added subprocess tier spawning built `dist/cli.js`). F124 randomized execution order — py `pyproject.toml:99` (`pytest-randomly`); ts: none. F125 per-test timeout — py `pyproject.toml:284` (`timeout = 60`, `pytest-timeout`, thread method); ts: none. F128 shared cross-test fixture — py `tests/conftest.py:16` (`@pytest.fixture(autouse=True)` resets the root logger for every test); ts: none (deliberately uses local factory helpers instead of a global setup file). F129 test file organization — py `Justfile:301` (`test-web` targets the `tests/web` subdir; suite also splits into `tests/{cli,core,meta}/`); ts `tests/api.test.ts:4` (flat `tests/*.test.ts`, no subdirectories). F130 opt-in slow/live marker taxonomy — py `pyproject.toml:277` (`markers = ["live: ...", "slow: ..."]`), `pyproject.toml:278` (`addopts` excludes both by default); ts: none (tiering is by file, not by marker). F131 opt-in parallel execution — py `pyproject.toml:97` (`pytest-xdist>=3.6`, `-n auto` opt-in); ts: none (Vitest parallelizes test files by default, no opt-in flag to cite). F132 Rust doc-test policy — neither repo has an analogous convention; `cargo test --doc` runs doc-comment examples by default, `RUST-ONLY`. F173 opt-in pre-push full-suite hook — py: none; ts `lefthook.yml:78` (`pre-push` `test` job runs `just test`, opt-in via `TS_PROJECTS_PREPUSH_TESTS=1`, default skip).
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). Five researched parameters this item consumes are still open (no `DECISION.md` yet): `http-transport-injection-seam` (R01), `ci-job-structure` (R11), `package-manager-invocation` (R42), `build-tool-output-shape` (R49), `web-extra-surface` (R69) — design the harness to fit whichever value each eventually takes; do not block on them and do not guess their answers.
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
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.
- related (not a registry dependency): R48 (`mocking-crates`) owns the mock/test-double and HTTP-transport-mocking crate pick (F119/F120) — coordinate on the shape of test doubles the harness expects but do not choose the crate. R33 (`property-and-snapshot-testing`, F122/F123), R34 (`scheduled-freshness-lanes`, F126/F127), and R35 (`coverage-tooling`, F134-F138) each own an adjacent testing-coverage decision this item must not re-open.

## Questions
Decision: what Rust test runner and execution-behavior configuration (CLI test tiers, ordering, per-test timeouts, shared fixtures, file organization, an opt-in slow/live marker taxonomy, opt-in parallelism, doc-test policy, and an optional pre-push full-suite hook) gives `rs-launch-blueprint` parity with py's pytest-plugin stack and ts's two-tier CLI approach.
- HIGH: Is `cargo test` (the built-in runner) or `cargo-nextest` the base test-execution tool, and does `cargo-nextest` provide per-test timeout enforcement (F125) and randomized/partitioned execution order (F124) natively, or does either require additional configuration or crates?
- HIGH: What is the idiomatic Rust equivalent of ts's two-tier CLI testing (F118) — in-process tests calling the CLI's entry function directly with injected dependencies, plus an `integration/`-style tier that spawns the built binary once its output shape is known?
- MEDIUM: What is the idiomatic Rust mechanism for an opt-in "skip slow/live tests by default" marker taxonomy (F130) — `#[ignore]` plus `--ignored`, a `cfg`-gated feature, or a crate providing test tags/filters (e.g. `rstest`, `test-case`)?
- MEDIUM: Does reaching parity with py's autouse global fixture (F128) or opt-in parallel-execution flag (F131) need a supporting crate (e.g. `serial_test`, `cargo-nextest`'s partitioning), given `cargo test` already runs test binaries in parallel by default?
- LOW: Should the CI-authoritative gate include `cargo test --doc` (F132), and should Rust add its own opt-in, default-skip pre-push full-suite hook (F173) mirroring ts's `TS_PROJECTS_PREPUSH_TESTS=1` pattern?

## Required evidence
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
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + link; "well-known" = nameable without lookup |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Recommendation
One stack.
### Members
The full `crate` field set for each member.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the choice landed.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
