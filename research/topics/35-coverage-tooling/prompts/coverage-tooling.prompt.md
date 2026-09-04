# Deep-research prompt — Coverage tooling (R35, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: `rs-launch-blueprint`'s code-coverage tool and its configuration — instrumentation scope and exclusions, where the coverage threshold is defined and what its values are, whether and how the threshold gates CI, and which report formats are produced. Item kind: `bundle`. Value test: if this answer is wrong, the coverage-tool dev-dependency, its config file or `Cargo.toml`/CI threshold declaration, the CI step that runs it, and the report-format flags all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): the two repos diverge on every axis. py wraps `coverage.py` via a pytest plugin, excludes nothing, defines its threshold in an external service config (Codecov), and that external service's check actually blocks the PR; it also emits three local report formats. ts uses its test runner's native V8 coverage provider, explicitly excludes two thin I/O-adapter files, defines stricter per-metric thresholds inside the test-runner config itself, and — although those thresholds are configured — the CI upload step that would enforce them is currently commented out (not enforced). Evidence: py `pyproject.toml:76` — `pytest-cov>=4.1.0` (wraps `coverage.py`); ts `package.json:53` — `@vitest/coverage-v8`. Ledger rows: F134, F135, F136, F137, F138 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F135 instrumentation scope and exclusions — py `Justfile:267` (`--cov=py_launch_blueprint`, no per-file omit list configured); ts `vitest.config.ts:10` (`include: ['src/**/*.ts']`), `vitest.config.ts:19` (`exclude` two thin I/O-adapter files). F136 threshold definition location and values — py `.codecov.yml:14` (`target: auto`, project), `.codecov.yml:18` (`target: 80%`, patch); ts `vitest.config.ts:20` (in-repo `thresholds`: 95/95/90/95 lines/functions/branches/statements). F137 coverage gate enforcement in CI — py `.github/workflows/ci.yml:193` (`codecov-action` uploads and the external Codecov check blocks the PR); ts `.github/workflows/ci.yml:95` (`run: just test`, no `--coverage`; the Codecov-upload step is commented out — thresholds configured but not currently enforced). F138 report output formats — py `Justfile:267` (`--cov-report=term-missing --cov-report=html --cov-report=xml`); ts: none (Vitest's default reporters, no explicit selection made).
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). One researched parameter this item consumes is still open (no `DECISION.md` yet): `ci-job-structure` (R11) — design the coverage step to fit whichever job structure R11 eventually picks; do not block on it.
- Prior decisions of the TypeScript port that explain the current shape: D-019(3) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — v8 provider, `coverage.include: ['src/**/*.ts']` (required in Vitest 4), thresholds lines 95 / functions 95 / branches 90 / statements 95 enforced in CI, only thin I/O-adapter/entry files excluded with explanatory comments, local fast loop stays coverage-free; D-022(1) — the CI workflow shape into which a coverage step would sit.

## Out of scope
- The base test runner and its execution-behavior configuration; R32 (`test-harness-and-execution`) owns F117/F118/F124/F125/F128-F132/F173 — this item's coverage tool must run under whatever runner R32 picks, but does not pick the runner.
- Where in the CI job graph the coverage-producing step sits and how it is path-filtered; R11 (`ci-workflow-job-structure`) owns `ci-job-structure` — this item decides the coverage tool and its own gate/threshold, not the job graph it lives in.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R35
- owns:
- consumes: R11: ci-job-structure
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.
- related (not a registry dependency): R32 (`test-harness-and-execution`) decides the base test runner this item's coverage tool instruments; this item does not re-decide the runner.

## Questions
Decision: what Rust coverage tool, instrumentation scope, threshold definition/values, CI gate, and report formats give `rs-launch-blueprint` parity with (and improve on) py's external-service-gated Codecov setup and ts's configured-but-unenforced Vitest thresholds.
- HIGH: Is `cargo-llvm-cov` or `cargo-tarpaulin` the dominant Rust coverage tool for a CLI + library + web workspace — what are their instrumentation mechanisms (LLVM source-based coverage vs. ptrace-based), accuracy, and CI-runtime-cost differences on `ubuntu-latest, macos-latest`?
- HIGH: Should the coverage threshold be enforced locally (a `cargo-llvm-cov` flag failing the command below a percentage) or via an external service (Codecov, as py does) — and if external, does it need a secret/token on a public template repo, or does `codecov-action`'s tokenless mode for public repos suffice?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`). Scope this to the shared, language-neutral part identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; the Rust-specific part is still answered for Rust alone.
- MEDIUM: What are idiomatic threshold values and instrumentation exclusions for this template's shape (CLI + library + web), and should thin I/O-adapter files be excluded the way ts explicitly excludes two files (F135)?
- MEDIUM: What report formats should the chosen tool emit locally vs. in CI (e.g. `lcov`, `html`, `json`, terminal summary) to match py's three-format local output (F138)?
- LOW: Does the chosen tool integrate with `cargo test --doc` (Rust's doc-test execution, decided by R32/F132) for combined coverage, or does doc-test coverage require separate handling?

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
