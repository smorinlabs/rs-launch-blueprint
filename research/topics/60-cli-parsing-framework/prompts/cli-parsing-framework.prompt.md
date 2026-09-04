# Deep-research prompt — CLI parsing framework (R60, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: which Rust CLI-parsing crate `rs-launch-blueprint` adopts, and — built on that framework — the shape of its command surface (noun-verb subcommand groups vs. one default command), its extended `--version` output, its shell-completion generation, its blanket env-var binding for every global option, its stackable global options, and its did-you-mean matching implementation. Item kind: `bundle`. Value test: if this answer is wrong, the CLI entry point's argument-parsing structure, its subcommand module layout, the `completion` command, the global-option declarations, and the unknown-command suggestion logic all get rewritten across the entire CLI front-end.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py and ts diverge on the parsing framework itself. py uses `click`; ts uses Commander. Evidence: py `src/py_launch_blueprint/cli/main.py:29` — `import click`; ts `src/router.ts:13` — `import { Command, CommanderError } from 'commander';`. Ledger rows: F264, F265, F267, F268, F269, F270, F272 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F265 command surface shape — py `src/py_launch_blueprint/cli/commands/__init__.py:26` (`COMMAND_GROUPS = [projects_group, config_group]`, each with its own verbs); ts `src/commands/projects.ts:70` (`.command('projects', { isDefault: true })`; `config` is a flat command, not a group). F267 extended version output — py `src/py_launch_blueprint/cli/main.py:52` (prints tool, Python, and platform lines); ts: none (ts's `--version` prints only the version string). F268 shell-completion command — py `src/py_launch_blueprint/cli/main.py:89` (`def completion(shell: str) -> None:` emits bash/zsh/fish completion); ts: none. F269 blanket env-var binding — py `src/py_launch_blueprint/cli/main.py:66` (`"auto_envvar_prefix": APP_NAME.upper(),` — click resolves any unlisted option from `PLBP_*`); ts: none. F270 global options stackable on every (sub)command — py `src/py_launch_blueprint/cli/options.py:232` (decorator reapplies `_GLOBAL_OPTIONS` on each command function, so a flag lands after the verb); ts `src/router.ts:125` (options declared once on the root `program` object only). F272 did-you-mean matching implementation — py `src/py_launch_blueprint/cli/groups.py:48` (`matches = difflib.get_close_matches(` stdlib, cutoff 0.6); ts `src/router.ts:120` (same call as F271's row; matching logic is internal to Commander, no app code).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): that a `-V`/`--version` flag exists (F266) and that an unknown command produces a did-you-mean suggestion (F271) are both inherited as-is (`COMMON → REUSE`); this item decides which crate provides them and F272's matching mechanism, not whether either exists. Target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
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
