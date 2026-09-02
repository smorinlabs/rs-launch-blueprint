# Deep-research prompt — Release binary artifacts (R68, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate/tool with a version range for: which distributable artifact types `rs-launch-blueprint` ships beyond the single `.crate` file `cargo publish` always produces — crates.io-only, `cargo-dist`-style cross-compiled GitHub Release binaries, `cargo-binstall` metadata, or some combination. Item kind: `crate`. Value test: if this answer is wrong, the release workflow's artifact-build/upload steps, any `cargo-dist`/`cargo-binstall` config file, and the README's documented install method all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py ships two PyPI artifact formats (sdist + wheel); ts ships one npm package format (a single ESM tarball). Neither maps directly onto Cargo, which produces exactly one `.crate` file per `cargo publish` regardless of how many distributable formats the source ecosystems used. Evidence: py `.github/workflows/ci.yml:216` — `uv build` produces sdist + wheel; ts `package.json:23` — `"type": "module"`, single ESM npm tarball. Ledger row: F214 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `different`.
- Already decided, do not re-open: the build backend/bundler tool question and the entry-point/bin/packaged-file-whitelist declarations that produce the artifact under discussion here belong to R49 (`build-target-declaration`), which owns `build-tool-output-shape` — this item decides only which distribution channels/artifact *types* beyond the base `.crate` file get built and shipped, not how the manifest declares its build targets. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts's single-npm-tarball choice has no `D-###` entry in `TS_PORT_DECISIONS.md` weighing alternate artifact types; it simply follows npm's one-package-format convention with no equivalent decision record to carry forward.

## Out of scope
- The Cargo manifest's build-target declarations (`[[bin]]`, `[lib]`, entry points, packaged-file whitelist) that produce the artifact this item distributes; R49 (`build-target-declaration`) owns `build-tool-output-shape` — this item consumes that shape as a given, it does not re-decide it.
- Whether a container image is a further distribution artifact for the optional web-service build; R51 (`container-image`) owns F223/F336/F337 — this item covers the CLI/library binary artifact question, not the container question.
- CI-wired or local install-and-run smoke testing of whichever artifact this item selects; R50 (`install-smoke-test`) owns F221/F222 — this item decides what gets shipped, not how it is smoke-tested.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R68
- owns:
- consumes: R49: build-tool-output-shape
- related (not a registry dependency): R51 (`container-image`) decides the separate question of whether a container image ships as an additional distribution artifact for the optional web-service build; that is orthogonal to this item's CLI/library binary-artifact question.
- related (not a registry dependency): R50 (`install-smoke-test`) decides how whichever artifact this item selects gets install-and-run tested; this item does not decide the test mechanism.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: which distributable artifact types `rs-launch-blueprint` ships beyond the single `.crate` file `cargo publish` always produces — crates.io-only (no additional artifacts), `cargo-dist`-style cross-compiled GitHub Release binaries for direct download/`cargo-binstall`, or a combination — given `build-tool-output-shape` (R49) fixes what the manifest declares as buildable.
- HIGH: Is `cargo-dist` (or its current successor/equivalent) still the dominant, actively-maintained tool for producing cross-compiled GitHub Release binaries plus installer scripts from a Cargo workspace, and does it integrate cleanly with the release-please-driven release flow already `COMMON → REUSE`d elsewhere in this template (F063–F077)?
- HIGH: Does `cargo-binstall` compatibility (pre-built-binary metadata that lets end users skip a source compile) require anything beyond what `cargo-dist`'s GitHub Release artifacts already provide, or is `cargo-binstall` support close to automatic once cross-compiled release binaries with a conventional naming scheme exist?
- MEDIUM: Given the fixed `target-os-matrix` (`ubuntu-latest, macos-latest`, no Windows), should released binaries mirror that same two-OS set, or does shipping a wider cross-compiled binary matrix (e.g. additional architectures within Linux/macOS) serve end users who are not also CI contributors?
- MEDIUM: What does crates.io-only distribution cost end users relative to a fork/template consumer's realistic install path — is `cargo install --locked <name>` (a source compile) an acceptable default given the template's target audience, or does a template specifically benefit from pre-built binaries that a from-scratch project might not need on day one?
- LOW: Does adding cross-compiled release binaries meaningfully increase the release workflow's CI time or complexity in a way that argues for deferring this to a documented "add when you fork this" opt-in rather than shipping it by default?

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

### Dominant choice
### Qualified shortlist
Up to five that passed every gate (fewer is a finding): name · role · 90-day downloads · all-time downloads · stars · last release · maintenance state · notable adopters · one-line trade-off.
### Excluded by gate
### Up-and-comers
### Fit for this template
CLI · library · web, separately.
### Recommendation
### Ranked runner-up
And the condition under which it wins.
### Tradeoffs
What the pick gives up versus each runner-up and why that cost is accepted.
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
