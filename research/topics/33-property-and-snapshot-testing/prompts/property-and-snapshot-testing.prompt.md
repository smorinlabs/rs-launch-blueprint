# Deep-research prompt — Property-based and snapshot testing (R33, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates (with versions) for: whether `rs-launch-blueprint` adopts property-based (generative) testing for round-trip invariants and golden-snapshot testing for CLI `--help` output, and if so, which crates provide each. Item kind: `bundle`. Value test: if this answer is wrong, the `Cargo.toml` dev-dependencies, any property-test module, and any committed snapshot fixture files all get added, removed, or rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py has both a property-based test suite and a CLI golden-snapshot suite; ts has neither. Evidence: py `tests/core/test_properties.py:24` — Hypothesis `@given` round-trip tests (WL-013); ts: none. py `tests/cli/test_help_snapshots.py:36` — syrupy `assert result.output == snapshot` for every `--help` (WL-023); ts: none. Ledger rows: F122, F123 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `py-only` for both.
- Per-row evidence: F122 property-based testing — py `tests/core/test_properties.py:24` (Hypothesis `@given` round-trip tests, work label WL-013); ts: no `fast-check` or equivalent generative-testing use found. F123 CLI golden-snapshot testing — py `tests/cli/test_help_snapshots.py:36` (syrupy snapshot assertion for every `--help` invocation, work label WL-023); ts: no `.ambr`-equivalent or `toMatchSnapshot` use found in the ts test tree.
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` has no entry addressing why Hypothesis or syrupy were not carried over; D-019 (testing) is silent on both.

## Out of scope
- The base test runner and its execution-behavior configuration (tiering, ordering, timeouts, fixtures, marker taxonomy, parallelism, doc-tests, pre-push hook); R32 (`test-harness-and-execution`) owns F117/F118/F124/F125/F128-F132/F173 — this item decides only whether property-based and snapshot testing exist and which crates provide them, not the harness they run under.
- The mock/test-double library or HTTP-transport-mocking mechanism; R48 (`mocking-crates`) owns F119/F120.
- The coverage tool and its thresholds; R35 (`coverage-tooling`) owns F134-F138.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R33
- owns:
- consumes:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.
- related (not a registry dependency): R32 (`test-harness-and-execution`) decides the base runner and execution behavior these tests run under; this item's crates must run under whatever R32 picks, but does not decide it.

## Questions
Decision: whether `rs-launch-blueprint` adopts property-based (generative) testing for round-trip/invariant checks and golden-snapshot testing for CLI `--help` output, and which crate provides each.
- HIGH: Is `proptest` or `quickcheck` the dominant Rust property-based testing crate for expressing round-trip/invariant tests analogous to py's Hypothesis `@given` suite (F122) — what are their API ergonomics, shrinking behavior, and maintenance-state differences?
- HIGH: Is `insta` the dominant Rust snapshot-testing crate for CLI golden-file assertions analogous to py's syrupy (F123), and does it support asserting CLI `--help` output specifically (stdout capture, redaction of dynamic content)?
- MEDIUM: How does `insta`'s review workflow (`cargo insta review`) compare to syrupy's snapshot-update workflow (`--snapshot-update`) for contributor ergonomics and CI enforcement of unreviewed snapshot changes?
- MEDIUM: Does either candidate crate have a lighter-weight or more actively maintained alternative worth listing as a runner-up (e.g. `proptest` vs. `quickcheck`; `insta` vs. hand-rolled fixture comparison)?
- LOW: Should property-based and snapshot tests be gated behind a Cargo feature or test-target split, or run unconditionally as part of the default `cargo test` invocation?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`).

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
