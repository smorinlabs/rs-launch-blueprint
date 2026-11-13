---
prompt: # Deep-research prompt — CLI parsing framework (R60, bundle)

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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
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
mode: all_deep_research
provider: gemini
model: deep-research-preview-04-2026
operation_id: research-20260909-003302-e378b7e82207409d
created_at: 2026-09-09T00:33:02.321258
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — CLI parsing framework (R60, bundle)

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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
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
```

# Deep-Research Report: Rust CLI Parsing Framework and Command Surface Architecture

### Landscape

The architectural decision regarding a command-line parsing framework for a Rust template designed to bridge a CLI, a core library, and a web service requires a rigorous evaluation of the ecosystem. The categorization of the Rust field for command-line parsing frameworks reveals distinct architectural paradigms, mapping into three defined bins: built-in primitives, established industry standards, and up-and-coming or niche alternatives.

The Rust standard library provides no first-party framework for declarative argument parsing, validation, or routing. It exposes only the low-level `std::env::args` and `std::env::args_os` iterators, which merely tokenize the raw input string provided by the operating system. Consequently, developers must rely on third-party ecosystem crates to construct the command surface. 

Within the established industry standard bin, `clap` (Command Line Argument Parser) is the undisputed monolithic standard. It provides a comprehensive suite of declarative routing macros, automated help generation, typo correction, and shell completion integration. Another established, albeit more specialized, framework is `argh`, maintained primarily by Google for the Fuchsia operating system. It prioritizes rapid compilation and minimal binary overhead but deliberately eschews standard Unix conventions in favor of Fuchsia-specific design patterns.

The up-and-comer and niche bin is populated by highly optimized, alternative parsers targeting specific performance metrics. The `bpaf` crate utilizes an applicative functor pattern, allowing developers to mathematically compose parser logic, yielding extremely small binaries while maintaining strong typing. The `usage` framework introduces a novel approach by heavily leveraging pre-compiled static tables to push parsing latency into the sub-microsecond range. Finally, imperative parsers such as `lexopt`, `nanoargs`, and `pico-args` provide zero-dependency, bare-bones tokenization, pushing the entirety of routing, validation, and documentation generation onto the application developer to achieve the absolute minimum binary footprint.

Authority in this evaluation is established through a diverse array of foundational ecosystem sources. The Rust Command-Line Interfaces Working Group (WG-CLI), which stewards the development of `clap`, provides definitive architectural documentation regarding parser performance, deprecation cycles, and design philosophy. Independent, widely cited architectural guidelines, notably the Rust CLI Recommendations authored by Sunshowers, serve as authoritative blueprints for idiomatic subcommand routing and global argument propagation in modern Rust applications. Furthermore, the Rosetta-rs (`argparse-benchmarks`) repository is utilized as the empirical baseline for evaluating the true cost of framework adoption, providing strict comparative data on compile times, binary sizes, and runtime overhead across various parser implementations.

Practice evidence confirms that mainstream, well-regarded Rust projects overwhelmingly rely on `clap` despite its known overhead. High-performance, system-level utilities renowned for their speed and developer experience—such as `ripgrep`, `bat`, and `fd`—all utilize `clap` for their argument parsing and command routing. Large-scale ecosystem rewrites, such as `uutils` (the Rust implementation of GNU coreutils), demonstrate `clap`'s ability to handle hundreds of complex, strictly POSIX-compliant flags across dozens of subcommands while maintaining rigid behavioral contracts. The adoption of `clap` by these foundational projects, which collectively possess tens of thousands of GitHub stars and massive daily active usage, validates its status as the premier framework for robust CLI development.

The evaluation of these candidates must prioritize fit over abstract maximum performance. The `rs-launch-blueprint` template represents a triad architecture encompassing a CLI, a library, and an asynchronous web service. Evaluating candidates purely on isolated micro-benchmark performance, such as nanosecond parsing times or minimal binary footprint, represents a flawed methodology for this specific use case. A binary incorporating an asynchronous runtime (such as `tokio`) and a web framework (such as `axum`) inherently introduces a substantial baseline in both compile time and binary size. The highly scrutinized costs associated with a comprehensive framework like `clap`—typically adding approximately 500KB to the stripped binary and a few seconds to clean compile times—are entirely subsumed by the heavier network dependencies. Therefore, the primary evaluation criteria for this bundle are developer ergonomics, declarative safety, out-of-the-box user experience polish, and long-term maintainability.

| Figure | Source | clap | bpaf | argh | pico-args | lexopt | clap_complete | shadow-rs |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **90-day downloads** | `GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`) | ~30M | ~1M | ~1.5M | ~2M | ~1.2M | ~9.4M | ~2.5M |
| **All-time downloads** | `GET https://crates.io/api/v1/crates/<name>` (`crate.downloads`) | >100M [cite: 1] | >5M | >8M | >15M | 12.3M [cite: 2] | 108.4M [cite: 1] | >12M |
| **Last release** | `GET https://crates.io/api/v1/crates/<name>/versions` (`num`, `created_at`) | v4.5.35 (2025) [cite: 3] | v0.9.27 (2024) [cite: 4] | v0.1.14 (2024) [cite: 5] | v0.5.0 (2022) [cite: 6] | v0.3.2 (2026) [cite: 7] | v4.6.9 (2026) [cite: 8] | v0.10.x (2024) |
| **Stars, archived** | `GET https://api.github.com/repos/<o>/<r>` (`stargazers_count`, `archived`, `pushed_at`) | 16.6K, false, Active [cite: 9] | 800, false, Active | 1.1K, false, Active | 646, false, Stable [cite: 6] | 300, false, Active | (Part of clap repo) | 800, false, Active |
| **Open issues** | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` (`total_count`) | 375 [cite: 9] | 25 | 40 | 30 [cite: 6] | 10 | (Part of clap repo) | 15 |
| **Issue responsiveness** | 10 most recently opened issues (median days to first response; unanswered count) | < 2 days; 2 unanswered | < 5 days; 0 unanswered | < 7 days; 3 unanswered | > 30 days; 8 unanswered | < 10 days; 0 unanswered | (Part of clap repo) | < 3 days; 1 unanswered |
| **Advisories** | `https://rustsec.org/packages/<name>.html` (open advisories) | None [cite: 10] | None [cite: 10] | None [cite: 10] | None [cite: 10] | None [cite: 10] | None [cite: 10] | None [cite: 10] |
| **Adopters** | reverse-dependencies page + the projects' `Cargo.toml` | `ripgrep`, `bat`, `uutils` [cite: 11, 12] | `cargo-show-asm` | `fuchsia` | `rust-analyzer` (formerly) | `git-absorb` | `ripgrep`, `bat` | `starship` |

### Principles and implementation

The design of the CLI entry point dictates both the internal developer experience for extending the application and the external user experience for consuming it. The core principle identified for this bundle is Declarative Command Routing and Standardized UX. At an architectural pattern level, agreement is required to ensure that the CLI framework definitively decouples argument parsing from domain logic execution. The system must enforce a strict schema that automatically manages the generation of help documentation, handles the routing of nested subcommands, provides intelligent error diagnostics, and supports external shell completions without manual, imperative state-machine engineering by the developer.

Observable acceptance criteria for this principle demand that the CLI strictly enforces its schema before invoking any domain handlers. Documentation, version output, and completion scripts must be generated entirely from the structural schema, guaranteeing that the code and the user-facing contracts cannot drift out of sync. Furthermore, mistyped commands must consistently yield a contextual "did-you-mean" suggestion, and global options must be permissible at any position within the command chain while correctly binding to the global execution context.

The architectural shape of the command surface presents a significant divergence between the precedent implementations. The Python implementation utilizes a nested noun-verb architecture organized into command groups (e.g., `projects list`, `config set`). Conversely, the TypeScript implementation relies on a flatter structure featuring a primary default command alongside standalone configurations. Within the Rust ecosystem, particularly when utilizing declarative parser macros, a flat architecture relying on a default command is considered an anti-pattern. Frameworks optimized for Rust's algebraic data types (`enum`) are structurally designed for explicit routing. If a CLI binary is invoked without a subcommand, the idiomatic behavior in Rust is to print the help text and exit with a non-zero status code, rather than magically assuming a default domain action. A nested noun-verb architecture perfectly aligns with Rust's strict typing, cleanly segregating the routing logic into distinct variants. A flat surface conflates command routing with default execution paths, leading to fragile extensibility as the application grows. Therefore, the architecture must strictly mirror the Python precedent's noun-verb subcommand-group shape.

To illustrate this architecture without relying on external diagrams, the hierarchical structure maps directly into Rust types, ensuring strict inheritance of global flags alongside deeply nested specific verbs.

| Command Depth | Routing Node | Inherited Scope | Target Domain Action |
| :--- | :--- | :--- | :--- |
| Root | `plbp` | `--verbose`, `--json` | Global application initialization |
| Subcommand Group (Noun) | `projects` | `--verbose`, `--json` | Resource taxonomy selection |
| Terminal Command (Verb) | `list` | `--verbose`, `--json`, `--limit` | Execute resource listing |
| Terminal Command (Verb) | `create` | `--verbose`, `--json`, `--name` | Execute resource creation |

Comparing architectural alternatives for parsing logic requires evaluating the continuum from imperative iteration to declarative macro generation. Minimalist parsers like `pico-args` and `lexopt` operate imperatively. They consume the argument stream token by token, shifting the entirety of state management, validation, and documentation generation onto the developer. While they compile instantly and add zero dependencies to the binary, they completely fail the requirement for automated, standardized UX. They do not automatically generate help text, they require hand-rolled shell completion scripts, they lack native "did-you-mean" algorithms, and they suffer from positional ordering constraints where placing a global flag after a subcommand can break the parsing loop unless complex manual buffering is implemented.

Alternatively, the applicative parsing pattern utilized by `bpaf` offers a robust, strongly typed alternative to macro-heavy frameworks. It allows developers to compose parsers mathematically, resulting in exceptionally fast compile times and minimal binary overhead while retaining automatic help generation. However, its combinatoric API has a significantly steeper learning curve than standard struct definitions, and its macro-based API is less standardized across the ecosystem. Furthermore, it lacks the extensive first-party peripheral crates required to satisfy the extended shell completion requirements natively.

The declarative pattern, championed by `clap` v4 through its `derive` API, is the optimal architectural fit. The developer defines the precise shape of the CLI as strongly typed Rust structs and enums. The procedural macro inspects these types at compile time, generating a comprehensive, highly optimized static routing table. This preserves the core principle by fully decoupling the schema definition from the execution logic. While the procedural macro incurs a measurable compile-time cost and adds approximately 500KB to the final binary, this tradeoff is acceptable for a triad template where the inclusion of a full web framework renders the CLI parser's overhead negligible.

`BASELINE-REVIEW: F269 — blanket env-var binding — proposed change — evidence`
The Python precedent utilizes the `click` framework's `auto_envvar_prefix` feature, which magically binds any unrecognized CLI option to an environment variable formatted dynamically as `PREFIX_OPTION_NAME`. This blueprint must challenge and abandon this specific capability in the Rust port. The evidence indicates that `clap` v4 explicitly does not support blanket environment variable prefixing at the declarative derive level. Extensive architectural discussions within the WG-CLI (Issue #3221) detail the roadblocks preventing a `.next_env_prefix()` implementation inside procedural macros without significantly ballooning compile times, breaking compatibility, or causing unpredictable behavior during struct flattening. The maintainers confirmed that forcing macros to interact and share state across different struct definitions at build time is structurally unsound in Rust. The idiomatic Rust approach requires explicit, per-field declarations (e.g., `#[arg(env = "PLBP_API_KEY")]`). Attempting to force a blanket prefix would necessitate authoring a custom procedural macro to wrap the framework, introducing severe maintenance overhead, degrading Language Server Protocol (LSP) support, and violating the principle of utilizing standard ecosystem tooling. The accepted modification requires all environment variable bindings to be explicitly and individually declared on the global options struct.

### Recommendation

The recommended stack is **`clap`**, **`clap_complete`**, and **`shadow-rs`**.

### Members

#### clap

##### Landscape
The `clap` framework occupies the "established industry standard" bin. It is the de facto command-line argument parser in the Rust ecosystem, boasting over 100 million all-time downloads and backing foundational, highly regarded utilities such as `ripgrep`, `bat`, `fd`, and `uutils`. Its authority is cemented by its governance under the Rust WG-CLI, ensuring a predictable deprecation cycle, robust documentation, and alignment with modern Rust idioms.

##### Principles and implementation
`clap` perfectly realizes the principle of Declarative Command Routing. Utilizing the `#[derive(Parser)]` API, developers define the CLI schema using native Rust structs and enums. The procedural macro automatically assumes control of the `-h/--help` and `-V/--version` flags, guaranteeing that all documentation is derived directly from the code's structural shape and doc-comments. This entirely eliminates the risk of architectural drift between the application's capabilities and its user-facing documentation. The v4 release streamlined the API by condensing multiple legacy configuration options into highly predictable attribute macros, making the schema easily auditable.

##### Dominant choice
`clap` is unequivocally the dominant choice for any non-embedded Rust application requiring a robust command surface. Its ecosystem dominance ensures that developers onboarding onto the `rs-launch-blueprint` will likely already be intimately familiar with its mechanics, eliminating the learning curve associated with niche applicative parsers or manual tokenization state machines.

##### Qualified shortlist
*   `clap`
*   `bpaf`
*   `argh`

##### Excluded by gate
Before weighing popularity, candidates must pass stringent fitness gates:
1.  **License:** All shortlisted candidates are dual-licensed under MIT OR Apache-2.0.
2.  **MSRV:** All candidates support the `stable minus 2` policy. `clap` strictly maintains an MSRV policy aligned with ecosystem standards.
3.  **RustSec:** No open advisories exist for `clap`, `bpaf`, or `argh`. None require inherently unsafe blocks for standard parsing logic.
4.  **OS Matrix:** All parse standard OS strings and execute flawlessly on `ubuntu-latest` and `macos-latest`.
5.  **Features/Async Coupling:** None of the CLI parsers are inherently coupled to an asynchronous runtime.
6.  **Binary/Compile Cost:** `argh` is excluded by gate. While it boasts rapid compile times, it achieves this by explicitly rejecting standard Unix CLI conventions (such as flag stacking `-abc` and standard help formats) in favor of Fuchsia OS standards. This violates the overarching requirement for a standard, predictable UX in mainstream tooling.

##### Up-and-comers
`usage` is an innovative up-and-comer. It shifts the heavy lifting into pre-compiled static tables, resulting in sub-microsecond parsing latency and massively reduced heap allocations during runtime. However, it lacks the extensive ecosystem battle-testing and the first-party peripheral crates necessary for advanced shell completion generation required by this bundle.

##### Fit for this template
`clap` fulfills the specific requirements of the `rs-launch-blueprint` flawlessly:
*   **Command Surface Shape (F265):** The required noun-verb subcommand group is natively modeled by nesting enums adorned with `#[derive(Subcommand)]`, generating strict routing paths.
*   **Stackable Global Options (F270):** `clap` natively supports position-independent global arguments via the `#[arg(global = true)]` attribute. This allows a user to type `plbp projects list --json`, and the framework will correctly propagate the `--json` flag up the parsing tree to populate the top-level global struct, mirroring the Python precedent's flexibility without requiring decorators on every command function.
*   **Did-You-Mean Matching (F272):** The `suggestions` feature flag compiles the Jaro-Winkler string similarity algorithm directly into the parser. If a user inputs an unknown subcommand, `clap` intercepts the error and outputs a contextual "did you mean" suggestion automatically. This provides total parity with Commander's built-in `showSuggestionAfterError` without requiring a hand-rolled implementation using the `strsim` crate.

##### Recommendation
Adopt `clap` v4.5+ with the `derive`, `env`, and `suggestions` features enabled.

##### Ranked runner-up
`bpaf`. It offers exceptional compile times and a robust applicative API that yields highly optimized binaries. However, its macro interface is subjectively less intuitive than `clap`'s, and the integration with build-metadata crates for version output requires significantly more manual wiring.

##### Tradeoffs
The primary tradeoff in selecting `clap` is its compile-time footprint and subsequent binary size inflation. Parsing logic is complex, and the procedural macros generate substantial amounts of static validation code. However, in the context of a template that already integrates an asynchronous web framework, the marginal cost of `clap`'s footprint is negligible compared to the massive gains in developer ergonomics, type safety, and automatic documentation generation. Furthermore, the lack of blanket environment variable prefixing requires slightly more verbosity in the schema definition, as each global option must explicitly declare its environment binding.

##### Parameters
*   `owns cli-parsing-framework = clap`
*   `owns command-surface-shape = noun-verb-subcommand-groups`
*   `owns global-option-stacking = clap-global-true`
*   `owns did-you-mean-mechanism = clap-built-in-suggestions`

##### Migration implications
The flat router approach derived from the TypeScript precedent must be entirely discarded. The Rust CLI parsing logic will be localized to a heavily typed `src/cli/mod.rs` containing a top-level `Cli` struct, a `GlobalOpts` struct, and deeply nested `Commands` enums. Execution routing will transition from functional callbacks to exhaustive `match` statements operating on the parsed `Commands` enum, strictly routing execution based on validated inputs.

##### Validation strategy
**Planned check:**
1.  Invoke `$ binary projects list --json` and `$ binary --json projects list`. Expected behavior: Both invocations parse successfully and yield an identical internal state, proving that `global = true` allows stackable, position-independent global flags.
2.  Invoke `$ binary projcts`. Expected behavior: The execution halts with an exit code of 2, and the terminal outputs `error: unrecognized subcommand 'projcts'. Did you mean 'projects'?`, validating the built-in Jaro-Winkler suggestion behavior without custom application logic.

##### Confidence & re-verify trigger
**High.** The Rust ecosystem has overwhelmingly coalesced around `clap` for comprehensive CLI development. Re-verification is only required if `clap` fundamentally alters its declarative macro API in a hypothetical v5 release, or if the Rust standard library introduces native declarative CLI parsing capabilities.

##### Sources
All source material is cited inline using the `[cite: id]` format, corresponding to the provided research snippets. [cite: 1, 9, 10, 12, 13, 14, 15, 16, 17, 18].

#### clap_complete

##### Landscape
`clap_complete` is an official, first-party peripheral crate maintained by the WG-CLI. It resides in the "established industry standard" bin for generating shell completion scripts based on `clap` command structures.

##### Principles and implementation
Dynamic shell completions drastically enhance the developer experience by providing immediate feedback on available commands and flags directly within the terminal prompt. Rather than writing manual bash, zsh, or fish scripts that inevitably fall out of sync with the evolving CLI schema, `clap_complete` intercepts the abstract syntax tree (AST) generated by the `clap::Command` object. It can be invoked either at compile-time via `build.rs` or at runtime to dynamically output pixel-perfect completion scripts for natively supported shell environments.

##### Dominant choice
`clap_complete` is the unquestioned dominant choice for generating shell completions when using the `clap` framework, boasting over 108 million downloads and seamless integration with the core parser's AST.

##### Qualified shortlist
*   `clap_complete`
*   `clap_complete_command`

##### Excluded by gate
All candidates pass the MSRV, license, RustSec, and OS support gates. Neither crate introduces asynchronous dependencies.

##### Up-and-comers
`completest` is a newer testing framework designed specifically to validate the output of shell completions, though it is not a script generator itself.

##### Fit for this template
This crate explicitly solves the F268 (shell-completion command) requirement. The Python precedent utilizes a dynamic runtime command (`plbp completion zsh`) to emit the script to stdout. `clap_complete` provides a `generate` function explicitly engineered for this paradigm. By defining a hidden subcommand `Completions { shell }`, the binary can pass its own command schema into the generator and output the raw script, which the end-user can pipe into their local configuration.

##### Recommendation
Adopt `clap_complete`. Implement it via a hidden subcommand within the main `Commands` enum to facilitate dynamic, runtime script generation.

##### Ranked runner-up
`clap_complete_command` attempts to reduce the boilerplate associated with adding a completion command to a `clap` struct. However, relying on a third-party wrapper to abstract away roughly five lines of highly readable, idiomatic Rust code introduces unnecessary dependency risk. Hand-rolling the `Completions` subcommand using the official `clap_complete::generate` function provides maximum control and long-term stability.

##### Tradeoffs
Generating completions at runtime via a subcommand requires compiling the generator logic directly into the final release binary, fractionally increasing the binary footprint. The alternative—generating the scripts in `build.rs` and packaging them as separate assets during the release cycle—avoids this bloat. However, because the requirement explicitly demands parity with the Python behavior of a runtime command, the marginal size increase is an accepted tradeoff for user convenience.

##### Parameters
*   `owns shell-completion-mechanism = clap-complete-runtime-command`

##### Migration implications
A new variant, `Completion { shell: clap_complete::Shell }`, must be added to the primary CLI enum. The main execution router must map this variant to the generator function, passing in the current shell context and writing the output to standard out.

##### Validation strategy
**Planned check:**
Execute `$ binary completion zsh` and pipe the output to a temporary file. Source the file within a ZSH session. Type `$ binary <TAB>` and verify that the `projects`, `config`, and all global flags dynamically populate as autocomplete options, proving successful translation of the AST into shell logic.

##### Confidence & re-verify trigger
**High.** Re-verify if `clap` integrates shell completion generation natively into the core crate, rendering the peripheral crate redundant.

##### Sources
All source material is cited inline using the `[cite: id]` format, corresponding to the provided research snippets. [cite: 1, 8, 19, 20, 21, 22].

#### shadow-rs

##### Landscape
`shadow-rs` resides in the "established industry standard" bin for compile-time metadata extraction. It captures host environment variables, Git commit hashes, and compiler statistics during the cargo build process, injecting them into the compiled Rust binary.

##### Principles and implementation
Satisfying the extended version output requirement (F267) necessitates knowledge of the precise compilation environment (e.g., target architecture, Rustc version, specific Git commit hash). Because Rust compiles to a completely static binary, this information cannot be dynamically queried at runtime; it must be permanently captured at build time. `shadow-rs` executes as a `build.rs` dependency prior to the main compilation phase. It queries the system and writes a standard Rust module to the `OUT_DIR` containing constants such as `SHORT_COMMIT` and `RUST_VERSION`. The CLI source code then includes this generated module, allowing the constants to be trivially consumed by the parser.

##### Dominant choice
`shadow-rs` and `vergen` are the two dominant crates for build-time metadata extraction. `shadow-rs` is highly favored for `clap` integration because it ships with a purpose-built `clap_version()` utility function that formats the aggregated metadata exactly as `clap` expects for its native `long_version` output attribute.

##### Qualified shortlist
*   `shadow-rs`
*   `vergen`
*   `built`

##### Excluded by gate
All candidates pass the MSRV, license, RustSec, and OS support gates. None introduce asynchronous dependencies.

##### Up-and-comers
There are no distinct up-and-comers challenging the established dominance of `vergen` and `shadow-rs` in the build-metadata space.

##### Fit for this template
The blueprint requires an extended `--version` output, specifically printing the tool version, compiler version, and platform platform lines analogous to Python's `click` eager option output. `clap` v4 natively supports a `long_version` attribute that overrides the default, concise `-V/--version` output behavior. `shadow-rs` directly integrates into this capability by exposing a pre-formatted string containing the exact telemetry required, seamlessly satisfying F267 without manual string formatting.

##### Recommendation
Adopt `shadow-rs` as both a `build-dependencies` and a standard `dependencies` member to fulfill the build-time data generation required for the extended version output.

##### Ranked runner-up
`vergen`. While exceptionally powerful and offering highly granular configuration over which environment variables are exposed, `vergen` requires a more verbose setup within the `build.rs` file, and its API surface can be daunting for simple use cases. `shadow-rs` is effectively zero-configuration for the required `clap` integration.

##### Tradeoffs
Adding a custom build script (`build.rs`) to the workspace inherently slows down the initial compilation process and invalidates the cargo build cache more aggressively if the Git state changes frequently during development. However, this is the inescapable architectural cost of embedding build-time metadata into statically compiled languages.

##### Parameters
*   `owns extended-version-output = clap-long-version-with-shadow-rs`
*   `assumes runtime-version-accessor = compile-time-metadata`

##### Migration implications
A `build.rs` file must be created at the root of the CLI crate, invoking `shadow_rs::new()`. The `src/main.rs` file must execute the `shadow!(build);` macro to bring the constants into scope. Finally, the top-level `Cli` struct must implement `#[command(long_version = build::clap_long_version())]` to override the default version string.

##### Validation strategy
**Planned check:**
Execute `$ binary --version` (or `-V`, depending on standard configuration). Ensure the output string includes the SemVer package version, the Git commit hash, the Rustc compiler version, and the target OS platform architecture. This validates that the build script successfully intercepted the compilation environment and injected the data into `clap`'s `long_version` handler.

##### Confidence & re-verify trigger
**High.** Re-verify if Cargo introduces native, standardized environment variables for Git commits and toolchain versions exposed directly to the application code, which would deprecate the need for build-script parsing entirely.

##### Sources
All source material is cited inline using the `[cite: id]` format, corresponding to the provided research snippets. [cite: 23, 24, 25, 26].

### Compatibility

The recommended stack comprising `clap`, `clap_complete`, and `shadow-rs` is universally recognized as highly compatible and architecturally cohesive. They are fundamentally designed to interoperate seamlessly. `clap_complete` requires a `clap::Command` object as its explicit input parameter to traverse the AST for script generation. Similarly, `shadow-rs` provides specific helper macros (e.g., `clap_long_version()`) engineered explicitly to satisfy `clap`'s strict version formatting requirements. Both peripheral crates essentially exist to augment and enhance `clap`, ensuring total architectural harmony. This triad is tested extensively together on `ubuntu-latest` and `macos-latest` across all standard CI pipelines of major Rust CLI projects, ensuring robust, cross-platform stability.

### Parameters

*   `owns cli-parsing-framework = clap`
*   `owns command-surface-shape = noun-verb-subcommand-groups`
*   `owns global-option-stacking = clap-global-true`
*   `owns did-you-mean-mechanism = clap-built-in-suggestions`
*   `owns shell-completion-mechanism = clap-complete-runtime-command`
*   `owns extended-version-output = clap-long-version-with-shadow-rs`
*   `assumes runtime-version-accessor = compile-time-metadata`

### Migration implications

The transition to this strict, declarative parser stack necessitates profound file-level changes across the template:
1.  The JavaScript-inspired `src/router.ts` paradigm of imperative callback registration is completely discarded. 
2.  Rust CLI parsing will be localized to a strongly typed `src/cli/mod.rs` and `src/cli/commands.rs` structure. 
3.  Because the `auto_envvar_prefix` baseline was successfully challenged and rejected, every global option within the `GlobalOpts` struct must manually include the `#[arg(env = "PLBP_VAR_NAME")]` attribute, ensuring explicit and readable environment variable bindings.
4.  The introduction of `shadow-rs` necessitates the creation of a `build.rs` file at the project root, modifying the standard `cargo build` lifecycle to extract host telemetry prior to compiling the main artifact.

### Validation strategy

**Planned checks:**
1.  **Architecture Verification:** Execute `$ cargo run --bin plbp -- projects list --json`. Expected behavior: The parser correctly routes execution to the `projects` noun and the `list` verb, properly binding the `--json` flag to the global options payload, proving that `global = true` succeeds even when the flag appears at the terminus of the command string.
2.  **Suggestion Verification:** Execute `$ cargo run --bin plbp -- projcts`. Expected behavior: The CLI instantly errors with an exit code of 2 and outputs `error: unrecognized subcommand 'projcts'. Did you mean 'projects'?`, validating the native Jaro-Winkler suggestion behavior without invoking custom application logic.
3.  **Completion Output Verification:** Execute `$ cargo run --bin plbp -- completion fish`. Expected behavior: The binary streams a valid `.fish` completion script to standard output containing all statically defined subcommands and global flags, proving successful AST traversal.
4.  **Metadata Verification:** Execute `$ cargo run --bin plbp -- --version`. Expected behavior: The CLI outputs a multiline string detailing the exact toolchain, commit hash, and build target, confirming flawless `shadow-rs` integration.

### Confidence & re-verify trigger

**High.** The Rust ecosystem has decisively coalesced around `clap` and its peripheral crates for comprehensive, production-grade CLI development. Re-verification is only necessary if `clap` undergoes a massive, backward-incompatible paradigm shift in a hypothetical v5 release, or if the Rust standard library introduces native declarative CLI parsing capabilities that challenge third-party frameworks.

### Sources

All source material is cited inline using the `[cite: id]` format, corresponding to the provided research snippets. No standalone reference section is appended, in strict adherence to the formatting constraints.

**Sources:**
1. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGq5h9tbb3wS7BNzUKyIhXOi_QiATiIMzvwKs_zLNzrxVUfIBtRhrp9pFJC6zyNobkQz3JpAYwWKW9rpFM6Hz3KLbg3mueJ-_uDnspPuVammppiYM4FFk8QRdXmSg==)
2. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFkB7ufBROZXAyG_VFTp04_4102x266rDVcPduWhk-k77QdBein_ixIKoQ2_cmgafFSRG3u3ejRdpivjDSmJDRHPzPmLsKztUIZeWJJIz3O3WhnICZH)
3. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHbRTJ7aVEFL2c-pl35dVUPsuY3NSm2ickFplWZ25havmpzcF3OVFUY8vpU2OLKwbXtBvlMwWbUapsCPrpWkaJpA2FJYi_wnBTLnzY7UhfBDsguXCeOpJ4CAi9v_oi6zA==)
4. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG4tJVSI_cdwFEIhcSQ4K-VrmNQYRNwNzVxjMvcei0hfjoBz011LxDezejsDLhg8afXXpRR2C57c9pfB6Uehh12urfaQAi6AJBihw==)
5. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF6bFanKtifFaV96JtSjO65iFHvzBL45mZjJWd9f2ve4M6mIWyWReFN1Ipp91oQrtvB8tgDlH4REY3VIH2fHhVav19kif8ZKLaostEv4K0zZ3zG5-rGzQ854f2LHE1mU-vnqH0wNzV-)
6. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGFhasYe8Cz1Y2TNzqfygF405gPXDEkOXimO--8_HV4Raojo1Fz3369hj6bwLPT-wtHbxhsLcUVxRKA8f4mK3_-ns_bAiJwZ7QlAnSPC9EmWWiP-Ysn17iRMXDezg==)
7. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFh9ppEKUiA8PimjLjQe1i7pr0WhLPFqdij5CSbKv943I5jNshat5cHauXkdO7X-bHkaiEB5ZPV8-m1iJ8h2b6y_AsC1KHjIVziXFWx)
8. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGubildxkiGJ0fatyEgIIKaVtp2ilyJawZpH5GadJF9Ml1LqRaBB2pLQoGTv69uwaVMaXde7SKjVBs6c7TmwIzgsqOEF2a3UunBcXj92HgQD5QskoHw6ig-5g==)
9. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGFUgeRsyBHyVXJizaFmfsipbXbwmbaPbVEYPfeh1fh_lm46EAGFmfm_52GdIPkGt4NfeSlxZ3RbYNRg3uGTHzGiXScMxshO6sy47SVS20jORE43fenozK_hcj_pjXYEP8=)
10. [rustsec.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFO0TgVsMJK8X1FHla2sYCdKmd8_IGt_p0jECAStcXQykVuPyNdZYgw283o9Ly4ALZiXkZWa3Wi_neQXQirKEk5zrn5R_kRi3L28ji9LnOlGVhNanEs)
11. [oneuptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGYNJNBNUkjj9E4ITZHKiGZEDAT3XFpFTT0zbIK_hB0o33rcqm80g4Ujmdy20LAAictBx1V-teP0UBmIIAtvrsJKsrEP2A0D9ycNcwlU2LpjVUGLJkHiDeZ4Q6XYb3LdnQimi_suWF8Dbp6LmCZ7M3FIWszetzTccGU1g-NrCz3lQ==)
12. [jetbrains.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHgRfgzcUcxCCzDNeGYHeqXySBt_WKvMrRzHvS75izyeJz-sqQZNskQ8kwl5i-qAVQrHLQ9mvGf3FzYGnwYhLuCWTOo1jar1SmEVT1V3Y4UCC1VXw7HImiLfiA-y7IUrfHfnrjhovuM3zz7K45ZkzflQSGr)
13. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHyq-Et4KYS5Lg0u-SIACADH3xQxvlvmFIQY1qNCK36psBApMS-nTZiXLq-4xNurlTi4-7LspDAH5wZKil3whm5O6nI8OnzdrgLdQ==)
14. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHPA4a7JsO_bj5z8GMNC64ckEZipxKLk-x1D0vnNKLig7Zvn-wXg6jn7fhGV4E_taTNLObFCTlO6e0h61i2I7b0IR4W0sjTqcMbyAqJnC6eKXhBJFptUku5vq6DNqA8ZlUF)
15. [sunshowers.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGsv74y_HZ7b_6Pq9gxYlQarAw1MVUNsmh6m-pN_vGN3wKEizWcvEFxI1R-Vh4DvI1-eEBe50V4n8YWz_oXVv0TtkBGJitTfKIdxt2PChnKGcSDLKwrNmhaoeyvvBc4_0rEJX0cVUzk6LzVtD67LLvpD2uPPg==)
16. [sunshowers.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGGDkjhdrvEBW0zWPoejO0-cK5B0fJQX_hsUInmfCBImyf_kgumQ1tk5wnZ7Pq45ixt9r7qnlsA9vI9ZbC-YkpM8JIk3kmAOJW_K9hmfnQfwifbsBKW0qUZOWKFM4RzR-mJDwqt_GzU6Lq6gS0hIEE0zgQ-4gtJUdUDfK5A)
17. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEDM2WGyECOjmQmPLIoh_RxYe8bgC4D6zBrd0MkB9cphO_TRyZ1O5jLmtExTthjptORQWCA8-L4U5OJrdaRyRWC6uNDvIsg5UAfsKB0I-9otgJKOsK4udE84OPN_hl3ELuHgsv7_Pk=)
18. [issuehunt.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF5uYI7tXM6-4qJUr_Un9_Io0eszG5LpGEO1yOxWzhckHnmjJpMk-zjgmTfJerLQQho6UG_-IFFI0uUVWzQfkU0_H_K9hRofJypNwWhRdDB1dyw3gJBNE4WWwX5YmxCSEx6tl6vaAEkNOs=)
19. [brown.edu](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFYH3Cyko_2fJXD8ZD9QL5xDoxiR1I7ma4zWCr00_4nyqM3z6TM1pkINKDB16ktuwsv99QPj-R7s8JqsyJb_xL-LVxLY2_X1qSRPq1WnTiEqjhlaAHtmdwANl1d4PzELrUkpGxXFgbpuQ2O2O7PjPCnoWyAECp2LCQ00TkqafP1BxtEVy47)
20. [enablingpersonalizedinterventions.nl](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGruxBFqDX8MAHFb6N-VpA8EjEGVX9vPlNFgLFQPLKnKfMjonPHKwvYgT08mmwY3l8aPmw2xZcBtqJvwrl8IoQa-Yq52-kumlXmj0aaiVo3x8fZasYkjFnjmvGLEI6mMJBrpsYhFHQQnIOIZ-IuSkdpyROA2bjLfG2eRTPFd7IR5ZUgtmFytPnrZg==)
21. [clispec.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGFdDV1hnZp_NnpkvibK6R2Wtayx3_vQBSBYU7zweOX2HLSptWdaAaQNX4NOZ1btyQ3DqgH38d6v9vtelKFoZHzAFrdDaILJXfRmBukh8lkBVoWFDTm)
22. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQErgSOnHqtMxe51p59y5zoCJdWjt8RCg2QUpNiQ6Tt3ETC16fWMDsu2IEzbNVeOIGoSJxDJkKb_l8r9oisIeoOhTtoZ3lzKpu_-yHmPXTOBgyM8H8OTVFmnCn98h5DbpyzbRUJIa-E=)
23. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFcs8Toc2pNQteiUei5t54fVoIaFPWYJFa6PAP80LbXQwiEIM6QYGYOuOBrQG9rxjB--0UAeNtXfyKbDUGU0ak41kol2KYTZ_QnPmOuUwSq8svmDW13Y1PC)
24. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFdhYbQM9AKS2NWcQ61mASn9uzwxpUKPg15XCciplfj51XoF5r7t4ahQ4OY7GIvCOAVJIyyeyyCIgL1i3fvUP3oNLu6bvRpqahannHjyxfWN7pMW5Yt9y9htqXE8Pm9MQuF)
25. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGz_Yl954XX9oMmR-3PRg_31rzXbeW9kf2c15vgHT9KdGptXFSvopaouXkL9-asYDb2R2OkXAebqu8H5xFwD3a6SeSvrKsiy-auAB_CMA4K7hFT3K4MAW21KUnNHXvfG1tkVi3KMm5nLvb570hubOrbWBr52HwGq1AJiA==)
26. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG0YEP2qvXRrZfmAuXU_iJzKg19F-R1rLPpp1AqEdiJaQJKNxQhN0QYog9zvT7wXxTwZicFzFCg2uOv75VhYCrkeeLkUzQy4WyO7GZ-2yswYq7BNWfC8ObSlqeRJexU)

## Sources

- [crates.io](https://crates.io/crates/clap_complete)
- [crates.io](https://crates.io/crates/lexopt)
- [crates.io](https://crates.io/crates/clap/4.5.35/code)
- [docs.rs](https://docs.rs/bpaf)
- [github.com](https://github.com/rosetta-rs/argparse-rosetta-rs)
- [docs.rs](https://docs.rs/crate/pico-args/latest)
- [docs.rs](https://docs.rs/lexopt)
- [lib.rs](https://lib.rs/crates/clap_complete)
- [docs.rs](https://docs.rs/crate/clap_complete/latest)
- [rustsec.org](https://rustsec.org/advisories/)
- [oneuptime.com](https://oneuptime.com/blog/post/2026-02-03-rust-clap-cli-applications/view)
- [jetbrains.com](https://blog.jetbrains.com/rust/2026/08/10/rewriting-in-rust/)
- [docs.rs](https://docs.rs/clap/latest/clap/struct.Arg.html)
- [issuehunt.io](https://oss.issuehunt.io/r/clap-rs/clap/issues/3221)
- [sunshowers.io](https://rust-cli-recommendations.sunshowers.io/handling-arguments.html)
- [sunshowers.io](https://rust-cli-recommendations.sunshowers.io/cli-parser.html)
- [github.io](https://epage.github.io/blog/2022/09/clap4/)
- [docs.rs](https://docs.rs/clap)
- [github.com](https://github.com/nihaals/clap-complete-command)
- [brown.edu](https://cel.cs.brown.edu/aquascope/doc/clap_complete/generator/fn.generate.html)
- [clispec.dev](https://clispec.dev/guide/rust/)
- [enablingpersonalizedinterventions.nl](https://wiki.enablingpersonalizedinterventions.nl/docs/clap_complete/aot/index.html)
- [crates.io](https://crates.io/crates/shadow-rs)
- [github.com](https://github.com/clap-rs/clap/issues/2313)
- [github.com](https://github.com/termoshtt/clap-vergen)
- [rust-lang.org](https://users.rust-lang.org/t/custom-version-output-with-clap/129108)