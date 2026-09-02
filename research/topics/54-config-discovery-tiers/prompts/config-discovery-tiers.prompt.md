# Deep-research prompt — Config discovery tiers (R54, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts py's layered config discovery (system → user → project, later wins, with a `--config` env-var alias) or ts's single default-user-path tier, and — if layered — what Rust crates/patterns implement the system-config-dir enumeration, the project-local upward search, and the env-var alias. Item kind: `bundle`. Value test: if this answer is wrong, the config-loading function's discovery-path list, the number of directories it searches, and whether a `PLBP_CONFIG`-style env var exists all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse — origin `py-only`, so treat cautiously): py separates config discovery into a layered chain — system config dirs → user config dir → project-local file, later wins — each layer merged, with `--config` overriding discovery entirely rather than adding a layer; ts has only a single per-user default path, no system or project tier. Evidence: py `src/py_launch_blueprint/core/config.py:134` — `layers = [*reversed(paths.system_config_files()), target, paths.project_config_file()]`; py `src/py_launch_blueprint/core/paths.py:108` — `def config_dirs() -> list[Path]:` (multi-dir, Windows `%PROGRAMDATA%` fallback); py `src/py_launch_blueprint/core/paths.py:184` — `def project_config_file(start: Path | None = None) -> Path:`; py `src/py_launch_blueprint/cli/options.py:107` — `envvar="PLBP_CONFIG",`; ts has none of these tiers or the env alias. Ledger rows F230, F231, F232, F234 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: `--config` replaces discovery entirely rather than adding a layer (F233, `COMMON → REUSE`, inherited as-is — both repos already agree, this is not part of this item's decision); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-017(1) and D-017(3) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — D-017(1) records the *canonical* config precedence as "`TOML <tool>_config.toml` under `$XDG_CONFIG_HOME/<tool>` with cli-standards R5.1 precedence (flags > TOOL_* env > project > user > system > defaults)," but D-017(3) shows ts's shipped `xdg-paths` module is a hand-rolled ~30-line resolver of only the per-user `$XDG_CONFIG_HOME`/`~/.config/<tool>` directory — ts's own decision record names the full chain as the target while its implementation realizes only the user tier. Treat this gap as live context for this item, not as settled.

## Out of scope
- Whether an unparsable discovered layer degrades to a warning versus a crash, and whether invalid individual values are dropped; R55 (`config-error-tolerance`) owns F235/F236/F238 — this item decides how many tiers exist and where they live, not how parse/validation failures in any tier are handled.
- Whether the config file may carry a secret/token; R56 (`config-secret-policy`) owns F239/F240/F245 — this item's discovery tiers are secret-policy-agnostic.
- The separate XDG data/state/cache directory set beyond config; R57 (`xdg-directory-set`) owns F249 — this item only concerns the config-discovery search path, not data/state/cache dirs.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R54
- owns:
- consumes: R67: error-taxonomy-exit-codes
- related (not a registry dependency): R55 (`config-error-tolerance`) decides how a missing/unparsable/invalid layer this item discovers is handled. R56 (`config-secret-policy`) decides whether any tier this item discovers may carry a token. R57 (`xdg-directory-set`) decides the broader XDG directory set beyond config.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: does `rs-launch-blueprint` adopt py's layered config discovery (system → user → project, later wins, with a `--config` env-var alias) or ts's single-tier default-user-path discovery, and — if layered — what implements the system-config-dir enumeration, the project-local upward search, and the env-var alias.
- HIGH: Is there a Rust crate (e.g. `directories`, `etcetera`, `xdg`) that already enumerates a platform's system-wide config directories (`$XDG_CONFIG_DIRS` on Linux and its equivalents) the way py's `paths.config_dirs()` does, or does this need hand-rolled logic (as ts's own `xdg-paths` module is, per D-017(3))?
- HIGH: Does adopting the full layered chain match cli-standards R5.1's own precedence order (flags > env > project > user > system > defaults), which ts's decision record (D-017(1)) cites as the target even though ts's shipped implementation only realizes the user tier — is there a reason a from-scratch Rust port should realize the full chain now rather than defer it as ts did?
- MEDIUM: What is the idiomatic Rust pattern for a project-local upward directory search (matching py's `project_config_file()` cwd-relative discovery) — a hand-rolled walk-up loop, or a crate?
- MEDIUM: Is the `--config` env-var alias (F234) a plain `clap` `env(...)` attribute, or does it need custom precedence logic interacting with the discovery layers?
- LOW: Do any published Rust CLI templates implement a multi-tier config discovery chain, for comparison?

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
