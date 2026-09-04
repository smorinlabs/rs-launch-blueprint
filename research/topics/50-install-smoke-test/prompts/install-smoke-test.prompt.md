# Deep-research prompt — Install smoke test (R50, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates/tools and reference pattern for: whether `rs-launch-blueprint`'s CI gates every PR on a build-and-install smoke test (py's pattern) or keeps an equivalent recipe local-only (ts's pattern), and what an ephemeral install-and-run smoke test looks like for a Cargo binary. Item kind: `bundle`. Value test: if this answer is wrong, the CI workflow's job list (whether a smoke-test job exists and runs on every PR) and the Justfile recipe implementing the install-and-run check both get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py gates every code-touching PR in CI on a `build-smoke` job that installs the just-built artifact into a throwaway environment and runs it; ts has an equivalent recipe (`pack-check`) but never wires it into CI, so it only runs locally/on-demand. Evidence: py `.github/workflows/ci.yml:204` — `build-smoke` job runs on every code-touching PR; ts `Justfile:276` — `pack-check` recipe exists but is not invoked from `ci.yml`. Ledger row: F221 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `different`.
- Per-row evidence for the rest of this bundle: F222 ephemeral wheel/sdist install-and-run smoke test — py `.github/workflows/ci.yml:222` — `uvx --from "$(ls dist/*.whl)" plbp --version`, installing the just-built artifact into a throwaway env via `uvx` and running it; ts: none (py-only; ts's `pack-check` recipe covers packed-content assertion, not an install-and-run step — see the Out-of-scope note below on how this differs from R26's scope).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): this row is deliberately distinct from R26 (`packed-artifact-content-guard`)'s F039/F078 packed-artifact content guard — confirmed separate at the Task 10 reconciliation (9c review endorsed): R26 verifies that what gets packaged matches expectations before publish, while this item verifies that the *installed* artifact actually runs; answering one does not settle the other. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` has no entry addressing why `pack-check` stayed CI-unwired; ts simply left it as a local-only recipe.

## Out of scope
- Whether the packaged artifact's file list matches expectations (packed-content assertion, e.g. `cargo package --list`); R26 (`packed-artifact-content-guard`) owns F039/F078 — this item verifies that the installed artifact runs, not that its packaged contents are correct; the Task 10 reconciliation confirmed these are separate questions.
- The build-target/entry-point declarations that produce the artifact under test (`[[bin]]`/`[lib]` in `Cargo.toml`); R49 (`build-target-declaration`) owns `build-tool-output-shape` — this item consumes whatever binary R49 produces, it does not decide how it is declared.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R50
- owns:
- consumes:
- related (not a registry dependency): R49 (`build-target-declaration`) owns `build-tool-output-shape`, the binary/library target names and layout this item's smoke test installs and runs; this item does not register a consumption of that parameter because its own test procedure does not vary by the target's exact name or path, only by whether a `[[bin]]` target exists.
- related (not a registry dependency): R26 (`packed-artifact-content-guard`) decides the separate packed-content-assertion question (F039/F078); this item's install-and-run check is complementary, not overlapping.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s build-and-install smoke test runs in CI on every code-touching PR (py's cadence) or stays a local-only Justfile recipe (ts's cadence), and what the Rust-native ephemeral install-and-run mechanism looks like.
- HIGH: What is the closest Rust analogue of `uvx`'s throwaway-environment install-and-run pattern (F222) — `cargo install --path . --root <tmp>` followed by running the installed binary, `cargo run --locked`, or something else — and does it genuinely exercise the same "would a fresh install actually work" question `uvx` answers for py?
- HIGH: Does gating every PR on this smoke test (py's cadence) cost meaningfully more CI time for a Rust build than for py's `uvx`-based install (given Rust's compile times vs. Python's interpreted install), and does that cost argue for ts's local-only cadence instead, or for keeping it in CI but only on a path-filtered subset of PRs?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: Should the smoke test assert anything beyond "the binary runs and exits 0 for `--version`" (py's check) — e.g. exercising the optional web-service feature's binary if `web-extra-surface` (R69) is adopted?
- LOW: Does the Justfile recipe implementing this check (whether or not CI-wired) belong to the difftree canonical recipe vocabulary already reused elsewhere in this template (F176–F178, `COMMON → REUSE`), and if so what recipe name/alias fits that vocabulary?

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
