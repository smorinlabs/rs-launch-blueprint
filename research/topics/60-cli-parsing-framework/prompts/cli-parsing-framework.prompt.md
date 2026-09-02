# Deep-research prompt — CLI parsing framework (R60, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: which Rust CLI-parsing crate `rs-launch-blueprint` adopts, and — built on that framework — the shape of its command surface (noun-verb subcommand groups vs. one default command), its extended `--version` output, its shell-completion generation, its blanket env-var binding for every global option, its stackable global options, and its did-you-mean matching implementation. Item kind: `bundle`. Value test: if this answer is wrong, the CLI entry point's argument-parsing structure, its subcommand module layout, the `completion` command, the global-option declarations, and the unknown-command suggestion logic all get rewritten across the entire CLI front-end.

## Context
- Inherited pattern (spec §2, presumption of reuse): py and ts diverge on the parsing framework itself. py uses `click`; ts uses Commander. Evidence: py `src/py_launch_blueprint/cli/main.py:29` — `import click`; ts `src/router.ts:13` — `import { Command, CommanderError } from 'commander';`. Ledger rows: F264, F265, F267, F268, F269, F270, F272 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F265 command surface shape — py `src/py_launch_blueprint/cli/commands/__init__.py:26` (`COMMAND_GROUPS = [projects_group, config_group]`, each with its own verbs); ts `src/commands/projects.ts:70` (`.command('projects', { isDefault: true })`; `config` is a flat command, not a group). F267 extended version output — py `src/py_launch_blueprint/cli/main.py:52` (prints tool, Python, and platform lines); ts: none (ts's `--version` prints only the version string). F268 shell-completion command — py `src/py_launch_blueprint/cli/main.py:89` (`def completion(shell: str) -> None:` emits bash/zsh/fish completion); ts: none. F269 blanket env-var binding — py `src/py_launch_blueprint/cli/main.py:66` (`"auto_envvar_prefix": APP_NAME.upper(),` — click resolves any unlisted option from `PLBP_*`); ts: none. F270 global options stackable on every (sub)command — py `src/py_launch_blueprint/cli/options.py:232` (decorator reapplies `_GLOBAL_OPTIONS` on each command function, so a flag lands after the verb); ts `src/router.ts:125` (options declared once on the root `program` object only). F272 did-you-mean matching implementation — py `src/py_launch_blueprint/cli/groups.py:48` (`matches = difflib.get_close_matches(` stdlib, cutoff 0.6); ts `src/router.ts:120` (same call as F271's row; matching logic is internal to Commander, no app code).
- Already decided, do not re-open: that a `-V`/`--version` flag exists (F266) and that an unknown command produces a did-you-mean suggestion (F271) are both inherited as-is (`COMMON → REUSE`); this item decides which crate provides them and F272's matching mechanism, not whether either exists. Target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-016(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — a four-way tie-break (Commander vs. oclif vs. `node:util parseArgs` plus a hand-rolled router) picked Commander v15 for being both an in-org shipped precedent and spec-sanctioned with full `click` parity (choices, auto-help, `-V`/`-h` defaults, built-in did-you-mean), wrapped in a `runCli(argv, deps) -> exit code` DI shape; D-016(8) — Commander's built-in `showSuggestionAfterError` supersedes a hand-rolled did-you-mean, kept "on" by default with no extra dependency.

## Out of scope
- Whether an interactive confirmation, guided-value, or multi-select prompt exists and which crate provides it; R61 (`interactive-prompts`) owns that bundle — this item's framework choice only needs to compose with whatever R61 selects.
- Clipboard-copy support for command results; R62 (`clipboard-integration`) owns F281/F282.
- A progress spinner during network fetches; R63 (`progress-spinner`) owns F283.
- Paging long text output through the user's pager; R64 (`pager-integration`) owns F284/F285.
- Color enablement precedence and TTY detection; R65 (`color-enablement-chain`) owns F287-F290.
- Output-format choices and the file-redirection flag; R66 (`output-format-surface`) owns F291/F293.
- The error-envelope code field, exit-code taxonomy, and signal-handling contract; R67 (`error-and-exit-code-contract`) owns `error-taxonomy-exit-codes`.
- Rich-only terminal presentation niceties (OSC-8 hyperlinks, relative timestamps) layered on top of table rows; R85 (`rich-terminal-row-niceties`) owns F359.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R60
- owns:
- consumes:
- related (not a registry dependency): R22 (`runtime-version-accessor`, ledger row F064) decides whether `rs-launch-blueprint` reads its version at compile time (`env!("CARGO_PKG_VERSION")`) or via a runtime metadata lookup; this item's extended `--version` output (F267) prints whatever build metadata R22's answer makes available, but does not decide where that metadata comes from.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: which Rust CLI-parsing crate `rs-launch-blueprint` adopts, and — built on that framework — what shape its command surface, extended `--version` output, shell-completion generation, blanket env-var binding, stackable global options, and did-you-mean matching take.
- HIGH: Is `clap` (derive or builder API) the dominant, ecosystem-standard choice for a CLI + library + web Rust template, or do lighter alternatives (e.g. `argh`, `lexopt`, `pico-args`) offer a meaningfully better fit given clap's compile-time and binary-size cost is a documented criticism?
- HIGH: Should the command surface mirror py's noun-verb subcommand-group shape (`projects list`, `config set`) or ts's flatter default-command-plus-standalone-config shape (F265), and does the chosen crate make one shape meaningfully cheaper to implement and maintain than the other?
- MEDIUM: Does the chosen crate support an eager `--version` callback that can print extended runtime/platform info (target triple, rustc version) the way py's `click` eager option does (F267), and what companion crate (e.g. `rustc_version`, `built`, `vergen`) supplies that build-time data?
- MEDIUM: Does the chosen crate ship (or have a companion crate for) shell-completion-script generation for bash/zsh/fish matching py's `completion` command (F268), and does it support blanket env-var binding for every global option without hand-declaring each one, matching py's `auto_envvar_prefix` (F269)?
- MEDIUM: Does the chosen crate natively support global options that stack on every (sub)command regardless of position — py's `plbp projects list --json` working with `--json` after the verb (F270) — or does that require declaring the same option on every subcommand?
- LOW: Does the chosen crate provide built-in did-you-mean suggestion matching (F272, the way Commander does out of the box per D-016(8)) that can replace a hand-rolled `difflib`-style implementation, or does it need a companion crate (e.g. `strsim`)?

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
