# Deep-research prompt — Property-based and snapshot testing (R33, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates (with versions) for: whether `rs-launch-blueprint` adopts property-based (generative) testing for round-trip invariants and golden-snapshot testing for CLI `--help` output, and if so, which crates provide each. Item kind: `bundle`. Value test: if this answer is wrong, the `Cargo.toml` dev-dependencies, any property-test module, and any committed snapshot fixture files all get added, removed, or rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py has both a property-based test suite and a CLI golden-snapshot suite; ts has neither. Evidence: py `tests/core/test_properties.py:24` — Hypothesis `@given` round-trip tests (WL-013); ts: none. py `tests/cli/test_help_snapshots.py:36` — syrupy `assert result.output == snapshot` for every `--help` (WL-023); ts: none. Ledger rows: F122, F123 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `py-only` for both.
- Per-row evidence: F122 property-based testing — py `tests/core/test_properties.py:24` (Hypothesis `@given` round-trip tests, work label WL-013); ts: no `fast-check` or equivalent generative-testing use found. F123 CLI golden-snapshot testing — py `tests/cli/test_help_snapshots.py:36` (syrupy snapshot assertion for every `--help` invocation, work label WL-023); ts: no `.ambr`-equivalent or `toMatchSnapshot` use found in the ts test tree.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
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
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: How does `insta`'s review workflow (`cargo insta review`) compare to syrupy's snapshot-update workflow (`--snapshot-update`) for contributor ergonomics and CI enforcement of unreviewed snapshot changes?
- MEDIUM: Does either candidate crate have a lighter-weight or more actively maintained alternative worth listing as a runner-up (e.g. `proptest` vs. `quickcheck`; `insta` vs. hand-rolled fixture comparison)?
- LOW: Should property-based and snapshot tests be gated behind a Cargo feature or test-target split, or run unconditionally as part of the default `cargo test` invocation?

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

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
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
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
