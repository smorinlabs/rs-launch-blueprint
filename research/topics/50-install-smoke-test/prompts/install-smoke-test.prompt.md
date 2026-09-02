# Deep-research prompt — Install smoke test (R50, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates/tools and reference pattern for: whether `rs-launch-blueprint`'s CI gates every PR on a build-and-install smoke test (py's pattern) or keeps an equivalent recipe local-only (ts's pattern), and what an ephemeral install-and-run smoke test looks like for a Cargo binary. Item kind: `bundle`. Value test: if this answer is wrong, the CI workflow's job list (whether a smoke-test job exists and runs on every PR) and the Justfile recipe implementing the install-and-run check both get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py gates every code-touching PR in CI on a `build-smoke` job that installs the just-built artifact into a throwaway environment and runs it; ts has an equivalent recipe (`pack-check`) but never wires it into CI, so it only runs locally/on-demand. Evidence: py `.github/workflows/ci.yml:204` — `build-smoke` job runs on every code-touching PR; ts `Justfile:276` — `pack-check` recipe exists but is not invoked from `ci.yml`. Ledger row: F221 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `different`.
- Per-row evidence for the rest of this bundle: F222 ephemeral wheel/sdist install-and-run smoke test — py `.github/workflows/ci.yml:222` — `uvx --from "$(ls dist/*.whl)" plbp --version`, installing the just-built artifact into a throwaway env via `uvx` and running it; ts: none (py-only; ts's `pack-check` recipe covers packed-content assertion, not an install-and-run step — see the Out-of-scope note below on how this differs from R26's scope).
- Already decided, do not re-open: this row is deliberately distinct from R26 (`packed-artifact-content-guard`)'s F039/F078 packed-artifact content guard — confirmed separate at the Task 10 reconciliation (9c review endorsed): R26 verifies that what gets packaged matches expectations before publish, while this item verifies that the *installed* artifact actually runs; answering one does not settle the other. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
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
- MEDIUM: Should the smoke test assert anything beyond "the binary runs and exits 0 for `--version`" (py's check) — e.g. exercising the optional web-service feature's binary if `web-extra-surface` (R69) is adopted?
- LOW: Does the Justfile recipe implementing this check (whether or not CI-wired) belong to the difftree canonical recipe vocabulary already reused elsewhere in this template (F176–F178, `COMMON → REUSE`), and if so what recipe name/alias fits that vocabulary?

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
