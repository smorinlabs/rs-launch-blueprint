# Deep-research prompt — Dev-toolchain provisioning (R42, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: how `rs-launch-blueprint` provisions the non-cargo developer-toolchain — whether it ships per-tool Justfile installer recipes, a declarative provisioner manifest (mise and/or flox) kept in sync with native installs, or relies on rustup/cargo alone — and how Justfile recipes and lefthook jobs then invoke each dev tool (a cargo subcommand vs. a provisioned binary on PATH). Item kind: `bundle`. Value test: if this answer is wrong, the Justfile's installer-recipe set, any `mise.toml`/`.flox/env/manifest.toml` equivalents (or their deliberate absence), and every Justfile recipe/lefthook job invocation line for a non-cargo-native tool all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py ships per-tool binary installer Justfile recipes for tools outside its primary package manager, plus two declarative toolchain-provisioner manifests (mise, flox) that must be kept in manual sync with the native install path. ts folds the tools those recipes installed into its single formatter and treats the remaining one as advisory-only, so it carries neither installer recipes nor a provisioner manifest. Evidence: py `Justfile:159`, `Justfile:476`, `Justfile:482`, `Justfile:713` — `install-taplo`/`install-gitleaks`/`install-actionlint`/`install-yamlfmt`, the latter two shelling out to `scripts/install-gitleaks.sh`/`scripts/install-actionlint.sh`; ts: none (folds taplo/yamlfmt into Oxfmt and treats actionlint as advisory-only inside `check-deps`, `Justfile:83`). Ledger rows: F183, F187, F188, F189 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F187 declarative toolchain-provisioner manifest, mise — py `mise.toml:23` (`[tools]` pins `python`, `uv`, `ruff`, `taplo`, `gitleaks`, `just`, `bun`, `gh`, `lefthook`, `make`, `actionlint`); ts: none. F188 declarative toolchain-provisioner manifest, flox — py `.flox/env/manifest.toml:14` (`[install]` declares the same 11-tool set via `pkg-path` entries); ts: none. F189 three provisioners kept in manual sync — py `mise.toml:1` (header: "one of the project's three first-class dev environments... keep them in sync"); ts: none (provisions only natively via Makefile/Justfile `install-*`, no mise/flox manifests exist).
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-014(6) and D-014(7) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — ts omits a taplo installer because Oxfmt already formats TOML, and omits a yamlfmt installer because Oxfmt already formats YAML; both eliminate the dedicated per-tool installer recipe and script py needed, rather than replacing it with an equivalent.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Against the existing solutions and follow a similar pattern

## Out of scope
- Which specific non-cargo dev tools this template needs beyond rustfmt/clippy (a secret scanner, a YAML linter, a spell checker, actionlint); R27–R29 (lint/format tool choices), R39 (`secret-scanning-hooks`), and R40 (`auxiliary-hygiene-hooks`) each own their own tool pick — this item decides how a chosen tool gets provisioned and invoked, not which tool is chosen.
- The hook manager's own distribution/install mechanism; R37 (`hook-manager-distribution`) owns F143/F144/F174 — lefthook's own install path is a separate provisioning question from the rest of the dev toolchain.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R42
- owns: package-manager-invocation
- consumes:
- related (not a registry dependency): R37 (`hook-manager-distribution`) decides how lefthook itself is installed (F143), a distribution question this item does not re-decide.
- related (not a registry dependency): R27, R28, R29, R32, R37, R40 each pick their own dev tool; this item's `package-manager-invocation` parameter tells their Justfile recipes and lefthook jobs how to invoke whatever tool they pick.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s dev-toolchain provisioning uses per-tool Justfile installer recipes (py's pattern) for non-cargo tools, a declarative provisioner manifest (mise and/or flox, kept in sync with native installs), or relies on rustup/cargo alone with no extra provisioning layer — and, whichever answer, whether Justfile recipes and lefthook jobs invoke a dev tool via a `cargo` subcommand or a provisioned binary on PATH.
- HIGH: Does rustup's component model (rustfmt, clippy) plus `cargo install`/`cargo-binstall` cover this template's toolchain needs well enough that no separate per-tool installer-recipe layer (F183) is needed, or does at least one non-cargo-native tool (e.g. a secret scanner, a spell checker) still require one?
- HIGH: Is a declarative provisioner (mise, flox, or both, F187/F188) common practice for Rust projects that also need non-Rust CLI tools, or does the Rust ecosystem's narrower non-cargo tool surface make a provisioner manifest unnecessary overhead compared to py's Python+Node+CLI tool mix?
- MEDIUM: If a provisioner is adopted, should the template keep two kept-in-sync manifests (mise and flox, py's three-provisioner pattern, F189) or converge on one, given Rust narrows the tool set that needs declaring?
- MEDIUM: What is the idiomatic Rust-template answer to `package-manager-invocation` — do Justfile recipes and lefthook jobs invoke rustfmt/clippy and any other tool via `cargo fmt`/`cargo clippy`-style subcommands, or via bare binaries expected on PATH?
- LOW: If per-tool installer recipes are kept for any tool, does each need its own shell script (as py's `scripts/install-gitleaks.sh`/`scripts/install-actionlint.sh` do) or can a single generic install-if-missing recipe serve every non-cargo tool?

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
