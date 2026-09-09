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
provider: openai
model: gpt-5.6-sol
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

## Reasoning Summary
**Researching crate versions**

I need the exact versions for bundle members related to clap and build-data crates as of September 9, 2026. I’ll research current and latest versions from the crates APIs. It seems I might be able to use direct open URLs for the API endpoints to make the call more immediate. This should help me find what I need—let’s see how this goes!

### Landscape

**Research date:** September 9, 2026.

**Evidence-completeness warning:** the required crates.io endpoints were opened, but this research transport did not expose their single-line JSON bodies. I therefore do **not** invent `crate.recent_downloads` or `crate.downloads`. GitHub’s repository/search API bodies and the ten-issue response sample were also not extractable. Those cells are marked pending and the exact retrieval commands are included under **Validation strategy**. This prevents the popularity and responsiveness figures from silently influencing the decision without evidence. (`https://crates.io/api/v1/crates/clap`, retrieved 2026-09-09.) ([crates.io](https://crates.io/api/v1/crates/clap))

#### Three-bin map

| Bin | Candidates found | Landscape finding |
|---|---|---|
| **Built-in or first-party toolchain** | `std::env::args_os`; Cargo’s own CLI architecture | The standard library supplies argument tokens but not typed parsing, generated help, nested command routing, completion generation, environment binding, or suggestions. Cargo itself is implemented as a set of `clap` subcommands, so first-party production practice points outside `std` to `clap`. (`https://doc.crates.io/contrib/implementation/subcommands.html`, retrieved 2026-09-09.) ([doc.crates.io](https://doc.crates.io/contrib/implementation/subcommands.html)) |
| **Established industry standard** | `clap`; lightweight niches represented by `argh`, `lexopt`, and `pico-args` | The Rust CLI Working Group book calls `clap` the most popular Rust argument parser and specifically highlights subcommands, completion support, generated help, and suggested corrections. Rust’s official CLI landing page also demonstrates `clap`. (`https://rust-cli.github.io/book/tutorial/cli-args.html`; `https://rust-lang.org/what/cli/`, retrieved 2026-09-09.) ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/cli-args.html)) |
| **Up-and-comer / challenger** | `bpaf`, `xflags`, function-oriented wrappers; helper layers such as `clap_complete_command` | These are valid research leads, but their current release, MSRV, advisory, CI, and maintenance figures were not fully captured in this run. They are therefore not promoted into the qualified shortlist. `clap_complete_command` is a convenience layer, not an independent parser. (`https://docs.rs/bpaf/`; `https://docs.rs/xflags/`; retrieved 2026-09-09.) |

#### Authorities used and why they count

1. **Rust CLI Working Group publications** establish ecosystem guidance rather than individual preference. Its book explicitly recommends typed argument modeling and identifies `clap` as the popular full-featured choice. The working group’s stated role includes keeping core CLI crates healthy and coordinating argument-parsing practice. (`https://rust-cli.github.io/book/tutorial/cli-args.html`; `https://github.com/rust-cli/team`, retrieved 2026-09-09.) ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/cli-args.html))
2. **Rust project publications and source** establish toolchain practice. Cargo is documented as one binary composed from `clap` subcommands; the official Rust CLI page uses `clap`. (`https://doc.crates.io/contrib/implementation/subcommands.html`; `https://rust-lang.org/what/cli/`, retrieved 2026-09-09.) ([doc.crates.io](https://doc.crates.io/contrib/implementation/subcommands.html))
3. **Maintainer documentation** is authoritative for APIs, feature flags, design intent, and acknowledged trade-offs. `clap` explicitly targets polished errors, suggestions, completions, flexible migration, and resilient maintenance while acknowledging build-time and binary-size tension. (`https://docs.rs/clap/latest/clap/`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/))
4. **Production manifests** establish actual engineering practice. Cargo, uv, Ruff, and fd use `clap`; ripgrep uses `lexopt`, providing a credible lightweight counterexample rather than a clap-only sample. ([github.com](https://github.com/astral-sh/uv/blob/main/Cargo.toml))
5. **The annual Rust survey** was checked as an authority source, but the accessible 2025 results did not provide a parser-specific selection result; it is not used as a proxy vote. (`https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`, retrieved 2026-09-09.) ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))

#### Practice evidence

| Project | Parser evidence | Why it is a relevant reference |
|---|---|---|
| **Cargo** | Cargo’s contributor guide says the binary is composed of `clap` subcommands. | Official Rust toolchain, large nested command surface, long compatibility lifetime. ([doc.crates.io](https://doc.crates.io/contrib/implementation/subcommands.html)) |
| **uv** | Workspace dependency enables `clap` features `derive`, `env`, `string`, and `wrap_help`, plus `clap_complete_command`. | Current, production-oriented, cross-platform command suite with many nested domains; its repository describes it as stable and widely used in production. ([github.com](https://github.com/astral-sh/uv/blob/main/Cargo.toml)) |
| **Ruff** | Uses `clap` derive and `clap_complete_command`; its lockfile resolves `clap_builder` with `strsim`. | Current high-adoption Rust CLI with library-like internal architecture and generated completion support. ([github.com](https://github.com/astral-sh/ruff/blob/main/Cargo.toml)) |
| **fd** | Uses `clap` with suggestions/derive and `clap_complete`; documents runtime Bash/Zsh/Fish/PowerShell generation. | Maintained cross-platform CLI and direct reference for a completion-generation command. ([github.com](https://github.com/sharkdp/fd/blob/master/Cargo.toml)) |
| **ripgrep** | Resolves `lexopt 0.3.2`. | Strong evidence that a low-level parser is viable when a focused CLI accepts bespoke routing/help code; it is not evidence that such code is economical for a reusable template. ([github.com](https://github.com/BurntSushi/ripgrep/blob/master/Cargo.lock)) |

#### Fitness gates before popularity

| Candidate | Gate result |
|---|---|
| **`clap 4.6.6`** | **Provisional pass.** MIT OR Apache-2.0; no async runtime; current release; upstream CI badge; demonstrated on Linux/macOS/Windows by adopters. The resolved tree must still pass Rust `1.96.0`, `cargo deny`, and the unsafe audit in the target repository. Default features are `std`, color, help, usage, error context, and suggestions; this recommendation additionally needs `derive`, `env`, and `string`. Compile and binary cost are the highest in this shortlist, primarily because of derive and the broad UX machinery. (`https://docs.rs/crate/clap/4.6.6`; `https://docs.rs/crate/clap/4.6.6/features`; retrieved 2026-09-09.) ([docs.rs](https://docs.rs/crate/clap/latest)) |
| **`argh` family** | License/MSRV/advisory/CI evidence was not fully captured, so it does not clear the evidence gate. Its maintained `argh_complete 0.1.19` companion and maintainer description establish that it is derive-based and optimized for code size, but substantial policy code would still be needed for automatic environment prefixes, propagated globals, and suggestions. (`https://docs.rs/crate/argh_complete/0.1.19`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/crate/argh_complete/latest)) |
| **`lexopt 0.3.2`** | Strong production adopter and qualitatively low integration weight, but it fails this item’s capability gate: the template would own command-tree help, completion schema, environment policy, global propagation, and suggestion behavior. (`https://docs.rs/lexopt/0.3.2/`; ripgrep lockfile, retrieved 2026-09-09.) ([github.com](https://github.com/BurntSushi/ripgrep/blob/master/Cargo.lock)) |
| **`pico-args`** | Lightweight lead, but current maintenance, advisory, CI, and feature evidence was not completed. It is excluded by the evidence gate and by the amount of missing front-end behavior that would become application code. (`https://docs.rs/pico-args/`, retrieved 2026-09-09.) |
| **`bpaf`, `xflags`** | Not rejected on quality. They are excluded because the mandatory current figures and all five fitness gates were not completed in this run. (`https://docs.rs/bpaf/`; `https://docs.rs/xflags/`, retrieved 2026-09-09.) |
| **Hand parsing with `std`** | License/MSRV/advisory gates are inapplicable because it adds no crate, but it fails the essential capability gate and transfers nearly the entire bundle into locally maintained parser code. |

As of September 9, 2026, stable Rust is `1.98.1`; applying the fixed “stable minus two minor versions” policy gives a current template `rust-version` of `1.96.0`. (`https://blog.rust-lang.org/releases/`; `https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/`, retrieved 2026-09-09.) ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/))

### Principles and implementation

#### Shared requirement and agreement level

The shared principle is:

> **Expose one discoverable, typed, testable command contract while keeping parser mechanics at the CLI-adapter boundary and keeping repeated policy—global placement, environment names, version rendering, completions, and suggestions—derived from one canonical command graph.**

Agreement is required at these levels:

- **Capability:** nested domain commands, `-V`/`--version`, extended `--version`, Bash/Zsh/Fish generation, automatic environment bindings, global options at every command depth, and useful unknown-command suggestions.
- **Policy:** command-line values override environment values; environment values override defaults; every application-defined global long option has a predictable `PLBP_*` name; no business operation is silently selected by the root command.
- **Architectural pattern:** parser types belong to the CLI adapter and are translated into library/application-service requests. The library and web service must not expose `clap` types.
- **Not required to agree:** the crate used by Python, TypeScript, and Rust; Click-style callbacks versus clap actions; the exact fuzzy-distance function or threshold; build-script syntax; internal module names.

The Rust CLI Working Group’s typed-data guidance remains appropriate: derive a typed command model, but use `try_get_matches_from` rather than a process-exiting parse call so `run_cli(argv, deps, io)` remains testable. (`https://rust-cli.github.io/book/tutorial/cli-args.html`, retrieved 2026-09-09.) ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/cli-args.html))

#### Architectural alternatives

1. **Full-featured declarative parser:** `clap` derive owns the static grammar; a small builder post-pass owns dynamic policies. This minimizes hand-written user-facing parser behavior.
2. **Pure builder API:** makes dynamic environment/version mutation straightforward but produces a more verbose and less obviously typed command-module structure.
3. **Small derive parser:** `argh` lowers code-size pressure but leaves several required policies outside the framework.
4. **Low-level token parser:** `lexopt` or `pico-args` minimizes parser machinery but requires the template to maintain help, routing, suggestions, completion metadata, and global/env semantics.
5. **Hand router on `std::env::args_os`:** no dependency cost, maximum application-owned behavior and rewrite risk.

**Selected architecture:** a **hybrid derive-plus-builder pattern**. Derive defines noun/verb types and local arguments; one `command(build_info)` function then:

1. inserts R22’s version;
2. inserts build target/rustc metadata;
3. discovers application-defined `global = true` arguments;
4. assigns each its generated `PLBP_*` environment name;
5. returns the exact graph used for parsing, help, suggestions, and completion generation.

This is materially safer than either a pure derive declaration with repeated `env = ...` attributes or a separately maintained completion schema. `clap` exposes `CommandFactory`, `FromArgMatches`, `Command::mut_arg`, `Command::long_version`, and nested `Subcommand` derivation for this composition. (`https://docs.rs/clap/latest/clap/struct.Command.html`; `https://docs.rs/clap/latest/clap/_derive/`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/struct.Command.html))

#### Command surface

Adopt noun-to-verb groups:

```text
plbp projects list
plbp projects show <id>
plbp projects create ...
plbp config get <key>
plbp config set <key> <value>
plbp completion <bash|zsh|fish>
```

Do **not** make `projects` or `projects list` the root default. Bare `plbp`, bare `plbp projects`, and bare `plbp config` display the relevant help rather than executing a business action.

This costs a few additional enum/struct modules, but it preserves the root namespace for future domains and maps cleanly to reusable application services. A default command is appropriate for a focused single-operation program such as a search tool; it is not the stronger default for a template explicitly intended to grow across CLI, library, and web adapters. Cargo’s nested subcommand structure and uv’s large derive-based command suite support the scalable side of this trade-off, while ripgrep is the credible focused-tool counterexample. ([doc.crates.io](https://doc.crates.io/contrib/implementation/subcommands.html))

#### Extended version

Use clap’s built-in eager version action, not a callback:

- `-V` renders the short tool version.
- `--version` renders `Command::long_version`:

```text
plbp 0.1.0
rustc: rustc 1.98.1 (...)
target: aarch64-apple-darwin
host: aarch64-apple-darwin
profile: release
```

The application version comes from R22. R60 does not decide whether R22 obtains it from `env!("CARGO_PKG_VERSION")` or runtime metadata. Build target, host, profile, and compiler identity are supplied by a deterministic `build.rs` using Cargo’s `TARGET`, `HOST`, `PROFILE`, and `RUSTC` environment variables. No build timestamp, hostname, username, or source-tree path is included.

`Command::long_version` and `ArgAction::Version` provide the eager behavior; clap itself lists build-information generators as a supported way to populate `long_version`. (`https://docs.rs/clap/latest/clap/struct.Command.html`; `https://docs.rs/clap/latest/clap/enum.ArgAction.html`; `https://docs.rs/clap/latest/clap/`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/struct.Command.html))

#### Completion generation

Implement a root `completion` command using `clap_complete 4.6.9` and its AOT `generate` function. The public shell enum should expose exactly Bash, Zsh, and Fish for parity, even though the crate can support additional shells. Output goes to stdout and performs no installation or file writes.

The same `command(build_info)` function must be passed to `clap_complete`, ensuring that newly added options and commands automatically appear in completion output. fd provides a maintained production example of runtime generation for these shells. (`https://docs.rs/clap_complete/latest/clap_complete/`; `https://github.com/sharkdp/fd`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap_complete/latest/clap_complete/))

#### Blanket environment binding

Clap supports per-argument `Arg::env` and derive-side environment-name case conversion, but it does not provide Click’s root-level `auto_envvar_prefix`. Apply a single builder post-pass:

```rust
fn bind_global_env(mut cmd: clap::Command, prefix: &str) -> clap::Command {
    let bindings = cmd
        .get_arguments()
        .filter(|arg| arg.is_global_set())
        .filter_map(|arg| {
            let long = arg.get_long()?;
            let env = format!(
                "{prefix}_{}",
                long.replace('-', "_").to_ascii_uppercase()
            );
            Some((arg.get_id().clone(), env))
        })
        .collect::<Vec<_>>();

    for (id, env) in bindings {
        cmd = cmd.mut_arg(id, move |arg| {
            arg.env(env).hide_env_values(true)
        });
    }

    cmd
}
```

The `string` feature permits owned environment/version strings. A structural test must reject application-defined globals without a long name and reject two long names that normalize to the same environment variable. `rename_all_env` is not sufficient because it changes the case of declared environment names rather than creating a prefix policy. (`https://docs.rs/clap/latest/clap/_derive/`; `https://docs.rs/clap/latest/clap/struct.Command.html`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/_derive/))

#### Global options at every depth

Declare each application global once in a flattened `GlobalArgs` type and mark it `global = true`. Clap propagates such arguments into nested subcommands, so both forms parse identically:

```text
plbp --api-url https://example.test projects list
plbp projects list --api-url https://example.test
```

No option is redeclared on `projects`, `projects list`, `config`, or `completion`. Options selected later by R65 or R66 obtain the same behavior automatically when added to `GlobalArgs`; this item does not decide whether flags such as `--json` or color controls exist. (`https://docs.rs/clap/latest/clap/_derive/`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/_derive/))

#### Did-you-mean

Keep clap’s default `suggestions` feature enabled and do not add an application-level `strsim` dependency. The current clap builder tree resolves `strsim`, demonstrating that the matcher is framework-owned. The acceptance contract is semantic—near misses identify the intended command—not a fixed similarity algorithm or cutoff. This avoids locking the template to Python’s `difflib` threshold or to clap’s current private implementation. (`https://github.com/astral-sh/ruff/blob/main/Cargo.lock`; `https://docs.rs/clap/latest/clap/`, retrieved 2026-09-09.) ([github.com](https://github.com/astral-sh/ruff/blob/main/Cargo.lock))

#### Minimal realistic reference pattern

```toml
[package]
edition = "2024"
rust-version = "1.96"

[dependencies]
clap = { version = "4.6.6", features = ["derive", "env", "string"] }
clap_complete = "4.6.9"
```

```rust
use clap::{Args, Command, CommandFactory, FromArgMatches, Parser, Subcommand};
use clap_complete::aot::Shell;

#[derive(Debug, Parser)]
#[command(name = "plbp")]
pub struct Cli {
    #[command(flatten)]
    pub global: GlobalArgs,

    #[command(subcommand)]
    pub command: Option<RootCommand>,
}

#[derive(Debug, Args)]
pub struct GlobalArgs {
    #[arg(long, global = true)]
    pub api_url: Option<String>,

    #[arg(long, global = true)]
    pub verbose: bool,
}

#[derive(Debug, Subcommand)]
pub enum RootCommand {
    Projects(Projects),
    Config(Config),
    Completion {
        #[arg(value_enum)]
        shell: PublicShell,
    },
}

#[derive(Debug, Args)]
pub struct Projects {
    #[command(subcommand)]
    pub command: ProjectsCommand,
}

#[derive(Debug, Subcommand)]
pub enum ProjectsCommand {
    List,
    Show { id: String },
    Create { name: String },
}

#[derive(Debug, Args)]
pub struct Config {
    #[command(subcommand)]
    pub command: ConfigCommand,
}

#[derive(Debug, Subcommand)]
pub enum ConfigCommand {
    Get { key: String },
    Set { key: String, value: String },
}

#[derive(Clone, Debug, clap::ValueEnum)]
pub enum PublicShell {
    Bash,
    Zsh,
    Fish,
}

pub struct BuildInfo {
    pub version: String, // supplied by R22
    pub rustc: &'static str,
    pub target: &'static str,
    pub host: &'static str,
    pub profile: &'static str,
}

pub fn command(info: &BuildInfo) -> Command {
    let long = format!(
        "{}\nrustc: {}\ntarget: {}\nhost: {}\nprofile: {}",
        info.version, info.rustc, info.target, info.host, info.profile
    );

    bind_global_env(
        Cli::command()
            .version(info.version.clone())
            .long_version(long),
        "PLBP",
    )
}

pub fn parse_from<I, T>(
    argv: I,
    info: &BuildInfo,
) -> Result<Cli, clap::Error>
where
    I: IntoIterator<Item = T>,
    T: Into<std::ffi::OsString> + Clone,
{
    let mut matches = command(info).try_get_matches_from(argv)?;
    Cli::from_arg_matches_mut(&mut matches)
}
```

`completion` dispatch reconstructs `command(info)` and passes it to `clap_complete::aot::generate`. Business variants are then translated into requests for the library’s application services rather than handled inside the parser module.

#### Observable acceptance criteria

1. `plbp --help` lists `projects`, `config`, and `completion`; no business operation is marked as the default.
2. `plbp projects --help` and `plbp config --help` list their verbs.
3. `plbp -V` prints the short version; `plbp --version` also contains labeled `rustc`, `target`, `host`, and `profile` lines.
4. Each application-defined root global has exactly one generated `PLBP_*` environment name.
5. Explicit CLI input wins over an environment value, which wins over the declared default.
6. A global option parses before the noun, between noun and verb, and after the leaf verb.
7. `plbp completion bash|zsh|fish` emits syntactically valid shell code and includes newly added commands without a separate completion edit.
8. A near miss at both root and nested levels includes the intended command name; an unrelated token does not require a suggestion.
9. The CLI dependency does not appear in the core library’s public API and, where the repository is a workspace, is owned by the CLI adapter package.
10. The resolved tree builds on Rust `1.96.0`, stable Rust, `ubuntu-latest`, and `macos-latest`; licenses/advisories pass the repository policy.
11. No exact exit-code value is fixed here; R67 maps clap outcomes and errors to the final process contract.

#### Performance evaluation

No like-for-like benchmark was executed, so this answer does not call any candidate “fastest.” The relevant workload is a short-lived CLI with an approximately eight-leaf command tree, application globals, generated help, and one nested parse. Measure:

- clean and one-file incremental compilation;
- stripped release binary size;
- process startup plus `--help` and nested-command latency;
- in-process parse throughput for repeated `try_get_matches_from`;
- peak resident memory.

Use the same Rust toolchain, release profile, command graph, and machine for every candidate. Clap’s maintainers explicitly acknowledge the build-time and binary-size trade-off; argh explicitly optimizes for code size. For this template, integration and policy ownership outweigh an unmeasured parser-only size advantage, especially when clap is kept out of the library and web adapter dependency graphs. (`https://docs.rs/clap/latest/clap/`; `https://docs.rs/crate/argh_complete/0.1.19`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/))

#### Baseline review

`BASELINE-REVIEW: F265 — scalable, discoverable domain grammar — use noun→verb groups and no default business command, replacing the TypeScript default-projects/flat-config shape for Rust — Cargo and uv provide maintained evidence for scalable subcommand trees; ripgrep shows the flat/specialized countercase.`

`BASELINE-REVIEW: F267 — eager version is a capability, not a callback mechanism — use clap version/long_version actions rather than a Click-style callback — preserves early rendering and keeps version behavior in the canonical command graph.`

`BASELINE-REVIEW: F269 — uniform configuration-source policy — replace Click-specific auto_envvar_prefix with one clap Command post-pass deriving PLBP_* from every application global long name — clap’s documented env support is per argument and rename_all_env does not create a prefix.`

`BASELINE-REVIEW: F272 — framework-owned suggestion policy — replace application-owned difflib matching with clap’s built-in suggestions/private matcher — acceptance fixes the observable candidate, not clap’s private metric or threshold.`

### Recommendation

Adopt this stack:

1. **`clap 4.6.6`**, using **derive for the static command schema plus one builder post-pass** for runtime version metadata and automatic global environment names.
2. **`clap_complete 4.6.9`**, using `clap_complete::aot::generate` in a root `completion <bash|zsh|fish>` command.
3. **A standard Cargo/rustc `build.rs` metadata emitter**, not a third metadata crate, for compiler/target/host/profile fields. R22 remains the source of the application version.
4. **Noun→verb command groups with no default business command.**
5. **Framework-owned suggestions**, with no direct `strsim` dependency.
6. **A single flattened `GlobalArgs` declaration**, `global = true`, and automatic `PLBP_*` binding based on each global long name.

The decision is strong on architecture and feature fit, but dependency admission remains conditional on the unexecuted MSRV, RustSec, unsafe, and exact-metric checks below.

### Members

#### clap 4.6.6

##### Landscape

`clap` is the established standard: it is recommended by the Rust CLI Working Group tutorial, used in Rust’s official CLI example, and used by Cargo, uv, Ruff, and fd. Its current non-yanked release found in this survey is `4.6.6`, dated August 6, 2026. (`https://docs.rs/crate/clap/4.6.6`; `https://crates.io/api/v1/crates/clap/versions`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/crate/clap/latest))

| Required figure | Result | Required endpoint | Status |
|---|---:|---|---|
| 90-day downloads | **Pending exact extraction** | `https://crates.io/api/v1/crates/clap` → `crate.recent_downloads` | Endpoint opened 2026-09-09; body not rendered. |
| All-time downloads | **Pending exact extraction** | `https://crates.io/api/v1/crates/clap` → `crate.downloads` | Endpoint opened 2026-09-09; body not rendered. |
| Last release | `4.6.6`, 2026-08-06 | `https://crates.io/api/v1/crates/clap/versions` | Corroborated by docs.rs package history. ([docs.rs](https://docs.rs/crate/clap/latest)) |
| Stars | `16,681` observed through docs.rs repository metadata | `https://api.github.com/repos/clap-rs/clap` → `stargazers_count` | Required API body not captured; refresh before ledger entry. ([docs.rs](https://docs.rs/crate/clap/latest)) |
| Archived | No archive indication observed | same endpoint → `archived` | Exact boolean pending. |
| Pushed at | **Pending** | same endpoint → `pushed_at` | Not captured. |
| Open issues | `374` observed on GitHub | `https://api.github.com/search/issues?q=repo:clap-rs/clap+is:issue+is:open` → `total_count` | Search API body not captured. ([github.com](https://github.com/clap-rs/clap)) |
| Issue responsiveness | **Pending:** median and unanswered count not captured | ten newest issues and comments | Must be calculated before final ledger publication. |
| Advisories | No `clap` package entry surfaced in the RustSec package lookup | `https://rustsec.org/packages/clap.html` | Confirm with `cargo deny check advisories`. ([rustsec.org](https://rustsec.org/packages/)) |
| Maintenance state | **active** | Release and repository activity | Release within the last month of the research date; current CI badge and active monorepo. ([docs.rs](https://docs.rs/crate/clap/latest/source/README.md)) |

##### Principles and implementation

Use derive to keep the parser’s grammar congruent with Rust enum/module structure, then use `CommandFactory` and `Command::mut_arg` for policies that derive cannot express centrally. This keeps one command graph for parsing, help, suggestions, and completion. (`https://docs.rs/clap/latest/clap/_derive/`; `https://docs.rs/clap/latest/clap/struct.Command.html`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/_derive/))

##### Dominant choice

**Yes.** It is dominant by official guidance, first-party toolchain adoption, production adoption, and breadth of relevant capabilities—not merely familiarity or downloads. (`https://rust-cli.github.io/book/tutorial/cli-args.html`; `https://doc.crates.io/contrib/implementation/subcommands.html`, retrieved 2026-09-09.) ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/cli-args.html))

##### Qualified shortlist

1. `clap 4.6.6`.
2. `argh` plus `argh_complete 0.1.19`, conditional on fresh license/MSRV/advisory/CI checks.
3. `lexopt 0.3.2`, conditional on accepting a much larger locally maintained UX layer.

Only clap clears the capability fit without redefining most of this bundle as application code. ([docs.rs](https://docs.rs/crate/argh_complete/latest))

##### Excluded by gate

- `std::env::args_os`: fails required parser capabilities.
- `pico-args`: current gate evidence incomplete and too much required policy remains local.
- `bpaf`, `xflags`: current license/MSRV/advisory/CI/maintenance evidence was incomplete, so they fail the evidence gate rather than a quality judgment.
- A direct `strsim`-based router: duplicates framework functionality and makes F272 application-owned.

##### Up-and-comers

`bpaf` is the most relevant full-surface challenger to re-evaluate if clap’s compile/binary cost becomes measured—not assumed—to violate a template budget. `xflags` is relevant where macro-generated, repository-local grammars are preferred. Neither is selected without the mandatory current gate figures. (`https://docs.rs/bpaf/`; `https://docs.rs/xflags/`, retrieved 2026-09-09.)

##### Fit for this template

Clap’s breadth directly matches the expensive-to-rewrite areas: nested nouns/verbs, generated help, eager version handling, environment-backed values, globals propagated into subcommands, and suggestions. Its cost is isolated by keeping it in the CLI adapter rather than the library or web service. uv’s current manifest demonstrates the specific `derive`/`env`/`string` combination proposed here. (`https://github.com/astral-sh/uv/blob/main/Cargo.toml`, retrieved 2026-09-09.) ([github.com](https://github.com/astral-sh/uv/blob/main/Cargo.toml))

##### Recommendation

Use:

```toml
clap = { version = "4.6.6", features = ["derive", "env", "string"] }
```

Keep the committed lockfile on `4.6.6` initially. Defaults remain enabled; there is no async-runtime coupling. R65 may later configure color behavior without changing the parser architecture.

##### Ranked runner-up

**`argh` plus `argh_complete`.** It is the closest code-size-oriented derive alternative and has a maintained completion companion. It ranks below clap because environment-prefix policy, propagated globals, and did-you-mean behavior would still need additional local design and tests. (`https://docs.rs/crate/argh_complete/0.1.19`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/crate/argh_complete/latest))

##### Tradeoffs

- **Benefits:** strongest ecosystem precedent, typed derive surface, nested subcommands, mature help/errors, built-in suggestions, environment support, direct completion ecosystem, no async coupling.
- **Costs:** proc-macro compilation, broader transitive tree, larger binary than low-level parsers, and a nontrivial API surface.
- **Mitigation:** parser dependency owned only by the CLI adapter; no `wrap_help` or additional clap ecosystem crates unless separately justified; committed lockfile and MSRV CI.
- **Evidence gap:** no maintained adopter found that implements the exact automatic-prefix post-pass. That local pattern must be compile-tested rather than assumed.

##### Parameters

- `parser version = 4.6.6`
- `API style = derive schema + builder policy pass`
- `features = default + derive + env + string`
- `async coupling = none`
- `maintenance state = active`
- `current template rust-version = 1.96.0`
- `license compatibility = MIT OR Apache-2.0`

##### Migration implications

Create typed root, group, and verb types; replace any hand router and hand suggestion code; change the entry point from a process-exiting parse call to `try_get_matches_from`; centralize command construction in `cli::command(build_info)`; map parsed variants to library requests.

##### Validation strategy

Planned, not executed:

```bash
cargo +1.96.0 check --locked --all-targets
cargo +stable test --locked --all-targets
cargo deny check licenses advisories bans sources
cargo geiger --all-features
```

Add parser tests for global placement, CLI/env/default precedence, version eagerness, root and nested suggestions, and `Command::debug_assert()`.

##### Confidence & re-verify trigger

**High** on parser selection and hybrid architecture. **Medium** on the exact environment post-pass until compiled against `4.6.6`. Reverify on clap `5.x`, any MSRV change, a RustSec entry, a measured size/compile regression beyond the project budget, or a failure of the global-env introspection API.

##### Sources

- `https://docs.rs/crate/clap/4.6.6` — retrieved 2026-09-09. ([docs.rs](https://docs.rs/crate/clap/latest))
- `https://docs.rs/clap/latest/clap/` — retrieved 2026-09-09. ([docs.rs](https://docs.rs/clap/latest/clap/))
- `https://docs.rs/clap/latest/clap/_derive/` — retrieved 2026-09-09. ([docs.rs](https://docs.rs/clap/latest/clap/_derive/))
- `https://docs.rs/clap/latest/clap/struct.Command.html` — retrieved 2026-09-09. ([docs.rs](https://docs.rs/clap/latest/clap/struct.Command.html))
- `https://github.com/clap-rs/clap` — retrieved 2026-09-09. ([github.com](https://github.com/clap-rs/clap))
- `https://rust-cli.github.io/book/tutorial/cli-args.html` — retrieved 2026-09-09. ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/cli-args.html))
- Required figures: `https://crates.io/api/v1/crates/clap`, `https://crates.io/api/v1/crates/clap/versions`, `https://api.github.com/repos/clap-rs/clap`, `https://api.github.com/search/issues?q=repo:clap-rs/clap+is:issue+is:open` — attempted 2026-09-09.

#### clap_complete 4.6.9

##### Landscape

`clap_complete` is clap’s first-party companion in the same repository. The newest non-yanked version found is `4.6.9`, dated August 6, 2026. Its maintained documentation distinguishes runtime/AOT `generate` from compile-time generation. (`https://docs.rs/crate/clap_complete/4.6.9`; `https://docs.rs/clap_complete/latest/clap_complete/`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/crate/clap_complete/latest/builds))

| Required figure | Result | Required endpoint | Status |
|---|---:|---|---|
| 90-day downloads | **Pending exact extraction** | `https://crates.io/api/v1/crates/clap_complete` | API body not rendered. |
| All-time downloads | **Pending exact extraction** | same endpoint | API body not rendered. |
| Last release | `4.6.9`, 2026-08-06 | `https://crates.io/api/v1/crates/clap_complete/versions` | Corroborated by docs.rs. ([docs.rs](https://docs.rs/crate/clap_complete/latest/builds)) |
| Stars / archived / pushed | Shared `clap-rs/clap` repository; exact API fields pending | `https://api.github.com/repos/clap-rs/clap` | Same repository as clap. |
| Open issues | Shared repository; `374` observed, exact search-API refresh pending | GitHub search endpoint | ([github.com](https://github.com/clap-rs/clap)) |
| Issue responsiveness | **Pending** | ten newest repository issues | Shared tracker. |
| Advisories | No package entry surfaced in lookup | `https://rustsec.org/packages/clap_complete.html` | Confirm through resolved-tree audit. |
| Maintenance state | **active** | release history and same active monorepo | Current release within the last month. |

##### Principles and implementation

Completion scripts must be generated from the parser’s actual command graph. A separate static completion definition would violate the single-source-of-truth principle and drift whenever a global option or verb changes.

##### Dominant choice

Within the clap ecosystem, direct `clap_complete` is the dominant low-level completion generator. It is maintained in the same repository and used directly by fd. (`https://github.com/clap-rs/clap/tree/master/clap_complete`; `https://github.com/sharkdp/fd/blob/master/Cargo.toml`, retrieved 2026-09-09.) ([github.com](https://github.com/clap-rs/clap))

##### Qualified shortlist

1. `clap_complete 4.6.9`.
2. `clap_complete_command 0.6.1`, evidenced in current uv and Ruff manifests/locks.
3. Hand-maintained shell files generated during release builds.

The helper crate is convenient, but direct `clap_complete` gives the template exact control over the public three-shell enum and stdout-only command behavior. ([github.com](https://github.com/astral-sh/uv/blob/main/Cargo.toml))

##### Excluded by gate

- Shell-specific handwritten scripts: fail single-source-of-truth and maintenance criteria.
- Completion generated from a second builder: fails drift prevention.
- Build-time-only generation: does not meet the inherited runtime `completion` command capability.
- Third-party shell frameworks: unnecessary when the parser’s first-party companion provides the required generators.

##### Up-and-comers

`clap_complete` contains newer dynamic-completion work behind optional surfaces, but this item requires portable script generation matching the Python precedent. The stable AOT API is the selected surface. (`https://docs.rs/clap_complete/latest/clap_complete/`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap_complete/latest/clap_complete/))

##### Fit for this template

Runtime generation supports local development, package-manager recipes, and release pipelines without committing generated shell files. Restricting the public argument to Bash/Zsh/Fish preserves the inherited contract while leaving future shell additions non-breaking at the internal API level.

##### Recommendation

Use:

```toml
clap_complete = "4.6.9"
```

and:

```rust
clap_complete::aot::generate(shell, &mut command(info), "plbp", stdout);
```

Its default AOT surface has no async-runtime coupling. Optional dynamic-completion features are not enabled.

##### Ranked runner-up

**`clap_complete_command 0.6.1`.** It has strong current adopter evidence in uv and Ruff and reduces boilerplate. It ranks second because the direct crate is first-party, already small at the call site, and gives clearer control over which shells become public API. ([github.com](https://github.com/astral-sh/uv/blob/main/Cargo.toml))

##### Tradeoffs

- **Benefits:** same graph as parsing/help, first-party compatibility, stdout generation, broad shell support.
- **Costs:** linked into the CLI binary even though generation is infrequent; shell output can change on dependency updates.
- **Mitigation:** CLI-only dependency ownership, semantic assertions plus reviewed snapshots, and explicit version updates.

##### Parameters

- `completion crate version = 4.6.9`
- `mode = runtime AOT generation`
- `public shells = bash, zsh, fish`
- `destination = stdout`
- `installation side effects = none`
- `async coupling = none`
- `maintenance state = active`

##### Migration implications

Add `cli/completion.rs`; add the root `completion` variant; ensure it calls the canonical command factory rather than deriving a second graph; update packaging documentation to invoke the command when producing release artifacts.

##### Validation strategy

Planned, not executed:

```bash
plbp completion bash > /tmp/plbp.bash
bash -n /tmp/plbp.bash

plbp completion zsh > /tmp/_plbp
zsh -n /tmp/_plbp

plbp completion fish > /tmp/plbp.fish
fish -n /tmp/plbp.fish
```

Add assertions that each output names `plbp`, contains `projects`, `config`, and `completion`, and changes automatically when a fixture command is added to the parser graph.

##### Confidence & re-verify trigger

**High.** Reverify on a `clap_complete` major release, removal or stabilization changes around `aot`, shell-output regressions, or a decision to expose additional shells.

##### Sources

- `https://docs.rs/crate/clap_complete/4.6.9` — retrieved 2026-09-09. ([docs.rs](https://docs.rs/crate/clap_complete/latest/builds))
- `https://docs.rs/clap_complete/latest/clap_complete/` — retrieved 2026-09-09. ([docs.rs](https://docs.rs/clap_complete/latest/clap_complete/))
- `https://github.com/sharkdp/fd/blob/master/Cargo.toml` — retrieved 2026-09-09. ([github.com](https://github.com/sharkdp/fd/blob/master/Cargo.toml))
- `https://github.com/sharkdp/fd` — retrieved 2026-09-09. ([github.com](https://github.com/sharkdp/fd))
- Required figures: `https://crates.io/api/v1/crates/clap_complete`, `https://crates.io/api/v1/crates/clap_complete/versions`, and the shared clap GitHub endpoints — attempted 2026-09-09.

#### Cargo/rustc build-info emitter

##### Landscape

This member is an **architectural pattern**, not a crate, so crate download, release, star, issue, and advisory figures are **inapplicable**. The alternatives surveyed were:

- standard Cargo build-script environment plus `RUSTC --version`;
- `rustc_version`;
- `built`;
- `vergen` family;
- `shadow-rs`.

Clap’s own documentation identifies `shadow-rs` as a related project for generating `Command::long_version`. (`https://docs.rs/clap/latest/clap/`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/))

##### Principles and implementation

Only collect deterministic metadata required by F267:

- R22-provided application version;
- build compiler version;
- target triple;
- host triple;
- Cargo profile.

Do not collect build time, usernames, hostnames, paths, or dirty-tree status by default. This keeps version output reproducible and avoids adding a broad build-metadata dependency for four stable fields.

Cargo documents build-script and environment variables at `https://doc.rust-lang.org/cargo/reference/build-scripts.html` and `https://doc.rust-lang.org/cargo/reference/environment-variables.html` (retrieved 2026-09-09).

##### Dominant choice

For rich build attestations, a maintained metadata crate is conventional. For this narrow requirement, Cargo’s built-in build-script channel is the smallest sufficient pattern and avoids overlapping R22.

##### Qualified shortlist

1. Standard `build.rs` using `RUSTC`, `TARGET`, `HOST`, and `PROFILE`.
2. `shadow-rs`, because clap’s own documentation names it for `long_version`.
3. `vergen`, `built`, or `rustc_version` if future requirements exceed the narrow metadata contract.

The third-party alternatives are not dependency-admissible from this answer because their current mandatory crate figures and all fitness gates were not completed.

##### Excluded by gate

No metadata crate is rejected as unsafe or unmaintained here. They are excluded from the chosen stack by:

- incomplete current license/MSRV/advisory/CI figures;
- broader output and build dependency surface than F267 requires;
- overlap risk with R22.

##### Up-and-comers

Inapplicable. This is a standard toolchain pattern. Reopen the library survey only if richer provenance becomes an owner requirement.

##### Fit for this template

The build script is shared by neither the core library API nor the web runtime. It emits compile-time strings consumed only by the CLI’s `BuildInfo`. It works under native Linux/macOS builds and cross-compilation because Cargo separately exposes `HOST` and `TARGET`.

##### Recommendation

Use a dependency-free `build.rs`:

```rust
use std::{env, process::Command};

fn main() {
    let rustc = env::var_os("RUSTC").expect("Cargo sets RUSTC");
    let output = Command::new(rustc)
        .arg("--version")
        .output()
        .expect("run rustc --version");

    assert!(output.status.success());

    let rustc_version =
        String::from_utf8(output.stdout).expect("rustc version is UTF-8");
    let rustc_version = rustc_version.trim();

    println!("cargo::rustc-env=PLBP_BUILD_RUSTC={rustc_version}");
    println!(
        "cargo::rustc-env=PLBP_BUILD_TARGET={}",
        env::var("TARGET").expect("Cargo sets TARGET")
    );
    println!(
        "cargo::rustc-env=PLBP_BUILD_HOST={}",
        env::var("HOST").expect("Cargo sets HOST")
    );
    println!(
        "cargo::rustc-env=PLBP_BUILD_PROFILE={}",
        env::var("PROFILE").expect("Cargo sets PROFILE")
    );
}
```

R22’s accessor supplies the application version when `command(build_info)` is constructed.

##### Ranked runner-up

**`shadow-rs`**, because it is the companion named by clap’s maintainer documentation for `long_version`. Its exact September 2026 version and required fitness figures must be recollected before adoption. ([docs.rs](https://docs.rs/clap/latest/clap/))

##### Tradeoffs

- **Benefits:** no added dependency, deterministic output, minimal build work, no async or unsafe code.
- **Costs:** local parsing/error handling for one compiler invocation; less metadata breadth than dedicated crates.
- **Performance:** one `rustc --version` process per build-script execution. Exact clean-build latency and memory cost were not instrumented; measure with Cargo timings rather than assuming it is negligible.

##### Parameters

- `metadata provider = Cargo/rustc build.rs pattern`
- `application version source = R22`
- `fields = rustc, target, host, profile`
- `build timestamp = omitted`
- `git metadata = omitted unless R22 supplies it`
- `third-party crate version = inapplicable`
- `async coupling = none`
- `unsafe posture = no unsafe code in the pattern`

##### Migration implications

Add `build.rs`, `cli/version.rs`, and a `BuildInfo` constructor. Ensure the web service does not depend on version-rendering code unless it independently needs the same data.

##### Validation strategy

Planned, not executed:

```bash
cargo clean
cargo build --release
./target/release/plbp --version

cargo build --release --target "$(rustc -vV | sed -n 's/^host: //p')"
```

Assert that output contains the actual Cargo target and compiler version and excludes timestamps, user directories, and hostnames.

##### Confidence & re-verify trigger

**Medium-high.** Reverify if R22 requires runtime-only version discovery, signed provenance, git state, reproducible-build attestations, or more than the four selected fields. At that point, reopen `shadow-rs`, `vergen`, `built`, and `rustc_version` with complete current metrics.

##### Sources

- `https://doc.rust-lang.org/cargo/reference/build-scripts.html` — retrieved 2026-09-09.
- `https://doc.rust-lang.org/cargo/reference/environment-variables.html` — retrieved 2026-09-09.
- `https://docs.rs/clap/latest/clap/` — retrieved 2026-09-09. ([docs.rs](https://docs.rs/clap/latest/clap/))
- `https://doc.rust-lang.org/rustc/command-line-arguments.html` — retrieved 2026-09-09.

### Compatibility

| Member | Compatibility evidence |
|---|---|
| `clap 4.6.6` + `clap_complete 4.6.9` | They are maintained and released from the same `clap-rs/clap` monorepo. The `clap_complete 4.6.9` docs build succeeded, demonstrating a compatible resolved clap tree. (`https://github.com/clap-rs/clap`; `https://docs.rs/crate/clap_complete/4.6.9/builds`, retrieved 2026-09-09.) ([github.com](https://github.com/clap-rs/clap)) |
| Production composition | fd uses nearby `clap 4.6.x` and `clap_complete 4.6.x` releases together and exposes runtime completion generation. ([github.com](https://github.com/sharkdp/fd/blob/master/Cargo.toml)) |
| `clap` + dynamic version strings | uv enables clap’s `string` feature in a large current command suite. ([github.com](https://github.com/astral-sh/uv/blob/main/Cargo.toml)) |
| Built-in suggestions | Ruff’s resolved `clap_builder` tree includes `strsim`; no direct suggestion crate is needed in the application. ([github.com](https://github.com/astral-sh/ruff/blob/main/Cargo.lock)) |
| Build-info pattern | The generated strings are ordinary compile-time environment variables passed to `Command::version`/`long_version`; there is no runtime or dependency coupling to `clap_complete`. |

The exact recommended pair must still be proven in the target lockfile with:

```bash
cargo update -p clap --precise 4.6.6
cargo update -p clap_complete --precise 4.6.9
cargo +1.96.0 check --locked --all-targets
```

### Parameters

`owns cli-parsing-framework = clap 4.6.6, derive schema plus builder policy pass`

`owns command-surface = noun→verb subcommand groups; projects and config are groups; no default business command`

`owns extended-version = -V short version; --version eager extended version with R22 version plus rustc/target/host/profile`

`owns shell-completion-generation = clap_complete 4.6.9 runtime AOT generation through completion <bash|zsh|fish>`

`owns blanket-global-env-binding = PLBP_<UPPER_SNAKE_LONG_NAME>, generated by command-graph post-processing for every application-defined global`

`owns global-option-propagation = one flattened GlobalArgs declaration using clap global = true; valid at every nested position`

`owns did-you-mean-matching = clap built-in suggestions; private framework matcher, no application strsim dependency or fixed cutoff`

`assumes runtime-version-accessor = R22 output`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version and tested in CI`

`assumes current rust-version = 1.96.0 as of 2026-09-09`

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

No `CONFLICT:` is identified.

### Migration implications

Recommended file-level shape:

```text
Cargo.toml
Cargo.lock
build.rs

src/bin/plbp.rs
src/cli/mod.rs
src/cli/command.rs
src/cli/env.rs
src/cli/version.rs
src/cli/completion.rs
src/cli/global.rs

src/cli/commands/mod.rs
src/cli/commands/projects/mod.rs
src/cli/commands/projects/list.rs
src/cli/commands/projects/show.rs
src/cli/commands/projects/create.rs
src/cli/commands/config/mod.rs
src/cli/commands/config/get.rs
src/cli/commands/config/set.rs

tests/cli/help.rs
tests/cli/version.rs
tests/cli/completion.rs
tests/cli/env.rs
tests/cli/globals.rs
tests/cli/suggestions.rs
```

Changes:

1. **Cargo manifest:** add `clap 4.6.6` and `clap_complete 4.6.9`; declare `rust-version = "1.96"` for the current policy window; commit the lockfile.
2. **Dependency ownership:** keep both parser crates in a CLI adapter package if the template is a workspace. If it is one package, make them private implementation dependencies and ensure no public library signature mentions clap types.
3. **Entry point:** keep `main` thin. It constructs dependencies and IO adapters, calls `run_cli`, and delegates final exit mapping to R67.
4. **Command graph:** define one `command(build_info)` function. Parsing, help tests, suggestion tests, and completion generation all use it.
5. **Business dispatch:** convert parsed enums into library/application-service requests. Do not place network/database behavior in clap callbacks or `Args` implementations.
6. **Version:** add deterministic build metadata and pass R22’s version into the command builder.
7. **Environment:** remove per-option `env = "PLBP_*"` duplication; retain only `global = true`, long names, and value parsers in `GlobalArgs`.
8. **Suggestions:** remove hand-written edit-distance code and direct fuzzy-matching dependencies.
9. **Completion:** add a stdout-only root command and shell syntax tests.
10. **CI:** add MSRV and stable jobs on Ubuntu/macOS, plus shell packages needed to syntax-check generated output.
11. **No changes to R61–R67 or R85:** prompt, clipboard, spinner, pager, color precedence, output-format selection, error taxonomy, signal handling, and rich-row behavior remain separate decisions.

### Validation strategy

**Execution status:** these are proposed repository checks. No Rust compilation, shell-generation command, benchmark, or API metric script was executed in this response.

#### Dependency and fitness gates

```bash
rustup toolchain install 1.96.0

cargo +1.96.0 check --workspace --all-targets --locked
cargo +stable test --workspace --all-targets --locked

cargo deny check licenses advisories bans sources
cargo geiger --workspace --all-features
```

Expected:

- edition 2024 builds on `1.96.0`;
- dependency licenses satisfy policy;
- no open advisory affects the resolved tree;
- unsafe usage is reviewed and recorded rather than silently accepted.

#### Command grammar

```bash
plbp --help
plbp projects --help
plbp config --help
plbp projects list
plbp config get api-url
```

Expected:

- root lists `projects`, `config`, and `completion`;
- group help lists verbs;
- no bare invocation performs a business action.

Add `command(&build_info).debug_assert()` to a unit test.

#### Extended version

```bash
plbp -V
plbp --version
```

Expected:

- `-V` contains the tool version;
- `--version` additionally contains one line each for `rustc:`, `target:`, `host:`, and `profile:`;
- version parsing succeeds without a required subcommand;
- output contains no timestamp, home directory, username, or hostname.

#### Blanket environment policy

For each application-defined global, inspect the final command:

```rust
let cmd = command(&fixture_build_info());
for arg in cmd.get_arguments().filter(|arg| arg.is_global_set()) {
    assert!(arg.get_long().is_some());
    assert_eq!(
        arg.get_env().unwrap(),
        expected_plbp_name(arg.get_long().unwrap())
    );
}
```

Behavioral checks:

```bash
PLBP_API_URL=https://env.test plbp projects list
PLBP_API_URL=https://env.test \
  plbp --api-url https://cli.test projects list
```

Expected precedence:

```text
explicit CLI > PLBP_* environment > declared default
```

Also test normalization collisions and invalid environment values.

#### Global option placement

```bash
plbp --api-url https://example.test projects list
plbp projects --api-url https://example.test list
plbp projects list --api-url https://example.test
```

Expected: all three produce the same parsed `GlobalArgs`. Once R66 adds any output-format global, it must pass the same generic test without R60 naming that option.

#### Suggestions

```bash
plbp proyects list
plbp projects lits
plbp completely-unrelated-token
```

Expected:

- the first error names `projects`;
- the second names `list`;
- the third is an unknown-command error without requiring a misleading suggestion;
- tests assert candidate presence, not exact punctuation, color, threshold, or full snapshot;
- R67’s eventual error wrapper preserves clap’s suggestion text.

#### Completions

```bash
plbp completion bash > /tmp/plbp.bash
bash -n /tmp/plbp.bash

plbp completion zsh > /tmp/_plbp
zsh -n /tmp/_plbp

plbp completion fish > /tmp/plbp.fish
fish -n /tmp/plbp.fish
```

Expected: syntax success and presence of all root/group commands. Run on both required OSes, installing Fish in CI where necessary.

#### Performance experiment

Create equivalent clap, argh, and lexopt fixtures with:

- the same eight leaf commands;
- the same global and local options;
- the same release profile and Rust toolchain;
- no network or application-service work.

Measure:

```bash
cargo clean
/usr/bin/time -v cargo build --release
cargo build --timings

hyperfine --warmup 20 \
  './target/release/plbp --help' \
  './target/release/plbp projects list'

stat -c '%s' target/release/plbp      # Linux
stat -f '%z' target/release/plbp      # macOS
cargo bloat --release -n 30
```

Add a Criterion benchmark around repeated `try_get_matches_from` for parser-only throughput. Record clean build latency, incremental build latency, binary bytes, process latency, parser throughput, and peak RSS. Do not compare unlike feature sets.

#### Exact figure refresh

```bash
for crate in clap clap_complete; do
  curl -fsSL "https://crates.io/api/v1/crates/$crate" |
    jq '{recent_downloads: .crate.recent_downloads,
         downloads: .crate.downloads}'

  curl -fsSL "https://crates.io/api/v1/crates/$crate/versions" |
    jq '[.versions[] | select(.yanked == false)]
        | sort_by(.created_at) | last
        | {num, created_at}'
done

gh api repos/clap-rs/clap \
  --jq '{stargazers_count, archived, pushed_at}'

gh api search/issues \
  -f q='repo:clap-rs/clap is:issue is:open' \
  --jq '{total_count}'
```

For responsiveness, fetch the ten newest open or closed issues by creation date, then fetch comments and treat the first non-bot comment whose `author_association` is `OWNER`, `MEMBER`, or `COLLABORATOR` as the first maintainer response. Report the median elapsed days and unanswered count.

### Confidence & re-verify trigger

**Overall confidence: high on the architectural decision, medium-high on the exact implementation plan.**

High-confidence findings:

- `clap` is the Rust ecosystem standard for this capability set.
- A low-level parser would transfer too much rewrite-sensitive behavior into the template.
- Noun→verb groups fit a multi-adapter, multi-domain scaffold better than a default business command.
- `clap_complete` is the natural completion companion.
- Built-in suggestions are preferable to application-owned edit-distance policy.
- A derive schema plus builder post-pass is the cleanest way to preserve both typed modules and automatic environment/version policy.

Items requiring re-verification before the ledger is marked complete:

1. exact crates.io download figures;
2. exact GitHub repository fields and issue-response median;
3. resolved-tree MSRV on Rust `1.96.0`;
4. RustSec and unsafe audit;
5. compilation of the proposed `is_global_set`/`get_env`/owned-string post-pass against `clap 4.6.6`;
6. exact `-V` versus `--version` rendering;
7. Bash/Zsh/Fish syntax checks on Ubuntu and macOS.

Reopen R60 if:

- clap `5.x` changes global/env/suggestion semantics;
- a RustSec advisory affects the selected tree;
- measured compile or binary cost violates a documented project budget;
- R22 requires signed or runtime-only provenance;
- R65 or R66 needs a parser feature incompatible with the selected feature set;
- the MSRV gate fails on a permitted dependency update.

The requested multi-engine procedural check is not independently observable from this interface; do not mark that execution-policy step complete solely from this answer.

### Sources

All sources retrieved September 9, 2026.

- Rust CLI Working Group, argument parsing: `https://rust-cli.github.io/book/tutorial/cli-args.html`. ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/cli-args.html))
- Rust CLI Working Group charter: `https://github.com/rust-cli/team`. ([github.com](https://github.com/rust-cli/team))
- Official Rust CLI page: `https://rust-lang.org/what/cli/`. ([rust-lang.org](https://rust-lang.org/what/cli/))
- Cargo subcommand architecture: `https://doc.crates.io/contrib/implementation/subcommands.html`. ([doc.crates.io](https://doc.crates.io/contrib/implementation/subcommands.html))
- Clap package `4.6.6`: `https://docs.rs/crate/clap/4.6.6`. ([docs.rs](https://docs.rs/crate/clap/latest))
- Clap API and design goals: `https://docs.rs/clap/latest/clap/`. ([docs.rs](https://docs.rs/clap/latest/clap/))
- Clap derive reference: `https://docs.rs/clap/latest/clap/_derive/`. ([docs.rs](https://docs.rs/clap/latest/clap/_derive/))
- Clap `Command`: `https://docs.rs/clap/latest/clap/struct.Command.html`. ([docs.rs](https://docs.rs/clap/latest/clap/struct.Command.html))
- Clap `ArgAction`: `https://docs.rs/clap/latest/clap/enum.ArgAction.html`. ([docs.rs](https://docs.rs/clap/latest/clap/enum.ArgAction.html))
- Clap repository: `https://github.com/clap-rs/clap`. ([github.com](https://github.com/clap-rs/clap))
- Clap Complete `4.6.9`: `https://docs.rs/crate/clap_complete/4.6.9`. ([docs.rs](https://docs.rs/crate/clap_complete/latest/builds))
- Clap Complete API: `https://docs.rs/clap_complete/latest/clap_complete/`. ([docs.rs](https://docs.rs/clap_complete/latest/clap_complete/))
- argh completion family: `https://docs.rs/crate/argh_complete/0.1.19`. ([docs.rs](https://docs.rs/crate/argh_complete/latest))
- uv manifest: `https://github.com/astral-sh/uv/blob/main/Cargo.toml`. ([github.com](https://github.com/astral-sh/uv/blob/main/Cargo.toml))
- uv repository: `https://github.com/astral-sh/uv`. ([github.com](https://github.com/astral-sh/uv))
- Ruff manifest: `https://github.com/astral-sh/ruff/blob/main/Cargo.toml`. ([github.com](https://github.com/astral-sh/ruff/blob/main/Cargo.toml))
- Ruff lockfile: `https://github.com/astral-sh/ruff/blob/main/Cargo.lock`. ([github.com](https://github.com/astral-sh/ruff/blob/main/Cargo.lock))
- fd manifest: `https://github.com/sharkdp/fd/blob/master/Cargo.toml`. ([github.com](https://github.com/sharkdp/fd/blob/master/Cargo.toml))
- fd runtime completion documentation: `https://github.com/sharkdp/fd`. ([github.com](https://github.com/sharkdp/fd))
- ripgrep lockfile: `https://github.com/BurntSushi/ripgrep/blob/master/Cargo.lock`. ([github.com](https://github.com/BurntSushi/ripgrep/blob/master/Cargo.lock))
- ripgrep repository: `https://github.com/BurntSushi/ripgrep`. ([github.com](https://github.com/BurntSushi/ripgrep))
- Rust release announcements: `https://blog.rust-lang.org/releases/`. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))
- Rust `1.98.0` announcement: `https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/`. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/))
- Cargo build scripts: `https://doc.rust-lang.org/cargo/reference/build-scripts.html`.
- Cargo environment variables: `https://doc.rust-lang.org/cargo/reference/environment-variables.html`.
- RustSec package index: `https://rustsec.org/packages/`. ([rustsec.org](https://rustsec.org/packages/))
- Required crates.io endpoints: `https://crates.io/api/v1/crates/clap`, `https://crates.io/api/v1/crates/clap/versions`, `https://crates.io/api/v1/crates/clap_complete`, `https://crates.io/api/v1/crates/clap_complete/versions`.
- Required GitHub endpoints: `https://api.github.com/repos/clap-rs/clap`, `https://api.github.com/search/issues?q=repo:clap-rs/clap+is:issue+is:open`.

## Sources

- [https://crates.io/api/v1/crates/clap](https://crates.io/api/v1/crates/clap)
- [https://doc.crates.io/contrib/implementation/subcommands.html](https://doc.crates.io/contrib/implementation/subcommands.html)
- [https://rust-cli.github.io/book/tutorial/cli-args.html](https://rust-cli.github.io/book/tutorial/cli-args.html)
- [https://docs.rs/clap/latest/clap/](https://docs.rs/clap/latest/clap/)
- [https://github.com/astral-sh/uv/blob/main/Cargo.toml](https://github.com/astral-sh/uv/blob/main/Cargo.toml)
- [https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/)
- [https://github.com/astral-sh/ruff/blob/main/Cargo.toml](https://github.com/astral-sh/ruff/blob/main/Cargo.toml)
- [https://github.com/sharkdp/fd/blob/master/Cargo.toml](https://github.com/sharkdp/fd/blob/master/Cargo.toml)
- [https://github.com/BurntSushi/ripgrep/blob/master/Cargo.lock](https://github.com/BurntSushi/ripgrep/blob/master/Cargo.lock)
- [https://docs.rs/crate/clap/latest](https://docs.rs/crate/clap/latest)
- [https://docs.rs/crate/argh_complete/latest](https://docs.rs/crate/argh_complete/latest)
- [https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/)
- [https://docs.rs/clap/latest/clap/struct.Command.html](https://docs.rs/clap/latest/clap/struct.Command.html)
- [https://docs.rs/clap_complete/latest/clap_complete/](https://docs.rs/clap_complete/latest/clap_complete/)
- [https://docs.rs/clap/latest/clap/_derive/](https://docs.rs/clap/latest/clap/_derive/)
- [https://github.com/astral-sh/ruff/blob/main/Cargo.lock](https://github.com/astral-sh/ruff/blob/main/Cargo.lock)
- [https://github.com/clap-rs/clap](https://github.com/clap-rs/clap)
- [https://rustsec.org/packages/](https://rustsec.org/packages/)
- [https://docs.rs/crate/clap/latest/source/README.md](https://docs.rs/crate/clap/latest/source/README.md)
- [https://docs.rs/crate/clap_complete/latest/builds](https://docs.rs/crate/clap_complete/latest/builds)
- [https://github.com/sharkdp/fd](https://github.com/sharkdp/fd)
- [https://github.com/rust-cli/team](https://github.com/rust-cli/team)
- [https://rust-lang.org/what/cli/](https://rust-lang.org/what/cli/)
- [https://docs.rs/clap/latest/clap/enum.ArgAction.html](https://docs.rs/clap/latest/clap/enum.ArgAction.html)
- [https://github.com/astral-sh/uv](https://github.com/astral-sh/uv)
- [https://github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)
- [https://blog.rust-lang.org/releases/](https://blog.rust-lang.org/releases/)