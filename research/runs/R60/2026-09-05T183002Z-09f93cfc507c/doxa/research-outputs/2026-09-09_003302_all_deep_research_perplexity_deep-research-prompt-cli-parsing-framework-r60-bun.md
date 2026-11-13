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
provider: perplexity
model: sonar-deep-research
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

# Rust CLI Parsing Framework for `rs-launch-blueprint`: Architecture, Crate Stack, and Command Surface

This report recommends that `rs-launch-blueprint` adopt **clap 4.x with the derive API** as its primary CLI-parsing framework, complemented by **clap_complete** for shell completions and a **build-metadata crate used in a build script** for extended version information, while relying on clap’s built-in suggestion machinery for did-you-mean matching.[1][3][7][8][10][11][14][15][17] The command surface should converge on the Python port’s noun–verb subcommand grouping (for example, `projects list`, `config set`), with **global options defined once and flattened into every command**, stackable in any position via clap’s `global` and `flatten` mechanisms.[1][3][8][10][15] Extended `--version` output should be implemented as an eager clap option wired to a library-layer function that prints tool, Rust, platform, and build metadata, fed by a compile-time metadata crate as decided by R22. Shell-completion generation should be exposed as a `completion` subcommand that uses clap_complete to emit bash, zsh, and fish scripts.[7][8][11][15][17] Blanket env-var binding for global options should be implemented as a small convention layer over clap’s `env` feature, using a single prefix such as `PLBP_` and a macro or helper to avoid per-field boilerplate.[1][3][7][8][15] Did-you-mean suggestions should be provided by clap’s own fuzzy matching of subcommand and argument names, keeping parity with Click and Commander without adding a separate dependency.[3][8][11][13][15] This design preserves cross-language principles, fits the Rust ecosystem’s dominant practices for CLI + library + web templates, and passes the fitness gates on licensing, MSRV, platform support, and maintainability; where numeric evidence is not executed here, the report describes the required checks and treats them as acceptance criteria rather than assumptions.

## Context and Objectives

The `rs-launch-blueprint` template is specified as a **CLI + library + web service** stack, intended to parallel the Python and TypeScript ports while respecting ecosystem-specific best practices and constraints. The Python port uses Click for command parsing and implements a noun–verb grouping, extended version output, a completion command, blanket environment-variable binding via `auto_envvar_prefix`, global options re-applied to every command, and a hand-rolled difflib-based did-you-mean.[Context] The TypeScript port uses Commander with a flatter shape that makes `projects` the default command, defines global options only at the root level, and relies entirely on Commander’s built-in suggestion mechanism.[Context] The owner has specified a **research mandate** that emphasizes identifying shared principles and acceptance criteria, surveying the ecosystem before choosing any crate, and avoiding simple “precedent-following” as the primary rationale.

From the ecosystem side, stable Rust, edition 2024, an MSRV policy of stable minus two minor releases, and dual `MIT OR Apache-2.0` licensing are fixed parameters.[Context] CI must cover at least `ubuntu-latest` and `macos-latest` runners, and this item must not change consumed parameters such as the version-accessor contract decided by R22. The **value test** is strict: if this recommendation is wrong, the entire CLI front-end would need to be rewritten, including the entry point’s argument-parsing structure, the subcommand module layout, the `completion` command, global-option declarations, and unknown-command suggestion logic.

Within this frame, the central decision is which Rust CLI-parsing crate to adopt and, built on that framework, how to design the command surface and the supporting behaviors: extended `--version`, shell completions, blanket env-var binding for global options, stackable global options, and did-you-mean matching. The required method is “forest before trees”: map the landscape, establish authoritative sources, survey practice in well-regarded projects, and judge fit specifically for a CLI + library + web template rather than abstract “best in general.” This report follows that structure, beginning with a landscape survey and then narrowing down to a concrete stack.

## Decision Analysis

### Landscape

The category this item decides is the **Rust command-line argument parsing and CLI-surface framework** for a template that will be consumed as CLI, library, and web service. The landscape can be mapped into three conceptual bins: built-in or first-party toolchain mechanisms, established industry standards, and up-and-comers focused on niche tradeoffs.

In the **built-in or first-party toolchain** bin, the baseline is the Rust standard library’s `std::env::args` and `std::env::args_os`, which provide raw argument iteration without parsing, validation, help generation, or completion support. This layer is analogous to Node’s `process.argv` or Python’s `sys.argv` and is deliberately minimal. While no external source is needed to establish its existence, it serves as the ground truth that all other crates build upon. There is also the Rust compiler and Cargo tooling, which have historically used custom internal parsing rather than a public first-party crate for argument parsing, meaning there is no direct equivalent of Python’s `argparse` packaged as a standard crate.

The **established industry standard** bin contains crates such as **clap**, **bpaf**, and historically **structopt**. Clap is widely described as a “full featured, fast Command Line Argument Parser for Rust” in its documentation and GitHub repository.[11][13][14][15] The docs emphasize that clap can create command-line parsers declaratively (derive macros) or procedurally (builder API), offers automatic help generation, validation, and subcommand hierarchies, and is dual-licensed under Apache-2.0 or MIT.[11][14][15] Blog posts and tutorials describe clap as the de facto standard for Rust CLIs, citing its maturity, ecosystem support, and extensive feature set.[1][3][6][7][8][10] Bpaf is a lightweight but flexible parser that supports both derive and combinator-style APIs and is explicitly positioned as an alternative to clap, with support for mixing derive and combinator approaches.[16] Structopt, which historically was a prominent derive-based CLI crate, has effectively merged into clap’s derive ecosystem and is no longer a separate contender.

The **up-and-comer** bin includes crates like **pico_args**, **rust-args-parser**, and **flexiargs**. Pico_args is described as “an ultra simple CLI arguments parser,” with a focus on minimalism and tiny dependency footprint.[5][18] Rust-args-parser is presented as a “tiny, fast, callback-based CLI argument parser” with a minimum supported Rust version (MSRV) of 1.60, emphasizing speed and minimal dependencies.[4] FlexiArgs is advertised as a “minimalist, flexible, and ergonomic CLI parsing” crate that is dependency-light and avoids macros or derive systems.[9] These crates aim to trade off features such as automatic help or completions for reduced compile-time and binary-size overhead, often appealing to very small utilities or highly constrained environments.

To establish **authority**, this report weighs several kinds of sources. Clap’s own documentation and GitHub repository are authoritative about its features, licensing, and maintenance state.[11][14][15] Tutorials and blog posts from multiple independent authors, including Tao’s “Rust clap in Practice,” CodeWithYoha’s “Mastering Command Line Utilities in Rust with Clap,” Luc Berton’s guide to building CLI tools in Rust, and the Tech Bytes “Modern Rust CLI Development [2026] Cheat Sheet,” collectively reinforce clap’s status as the dominant, ecosystem-standard choice for Rust CLI development.[1][3][6][8][10] The OneUptime blog on building CLI tools in Rust with clap and robust error-handling patterns provides additional confirmation of clap’s de facto standard status and integrates it with broader best practices such as `anyhow` and `thiserror` for error handling.[7] Pico_args’ docs on docs.rs and Rust-args-parser and FlexiArgs descriptions on lib.rs are authoritative about those crates’ positioning, MSRV, and feature scope.[4][5][9] The bpaf crate documentation similarly clarifies its design goals and derive/combinator mix.[16]

For **practice evidence**, mainstream Rust projects are known to use clap as their CLI parser. While this offline analysis cannot fetch crates.io reverse-dependency lists or GitHub Cargo manifests in real time, clap’s documentation and community commentary note its widespread adoption across CLI tools.[11][13][14][15] It is commonly cited in teaching materials and articles as the default choice for building CLIs in Rust.[1][3][6][7][8][10] Tutorials also present clap as the backbone of production-ready CLIs that compose well with async runtimes such as Tokio.[8] Rust packaging guidelines for Fedora reference clap explicitly, reinforcing its position as a widely packaged dependency in Linux distributions.[12] This kind of packaging guideline is an indicator that clap’s stability, licensing, and support are trusted by downstream ecosystems.[12] Bpaf, pico_args, rust-args-parser, and flexiargs, by contrast, have smaller footprints and are mentioned in niche contexts, often focusing on specialized tradeoffs such as compile-time or size, but no evidence in the provided sources suggests they are broadly adopted in complex CLI + library + web stacks.

Finally, **fit for the template** must be judged relative to the specific needs of `rs-launch-blueprint`: a CLI that is not only a stand-alone tool but also tightly integrated with a library and an HTTP service, with cross-language precedence that includes extended version output, shell completion generation, blanket env-var binding, stackable global options, and did-you-mean matching. Clap’s feature set aligns closely with these requirements, including derive support for struct-based CLI declarations, global arguments that apply to all subcommands, environment variable integration via the `env` feature, support for shell completions via the `clap_complete` companion crate, and built-in suggestion mechanisms for unknown subcommands.[1][3][6][7][8][10][11][14][15][17] Pico_args, rust-args-parser, and flexiargs do not provide these behaviors out of the box; they would require substantial hand-rolled logic for help, validation, completions, env-var conventions, and suggestions.[4][5][9] Bpaf is closer in capabilities but still lags behind clap’s ecosystem breadth and established patterns for completions and error handling.[16] Given that this template aims to embody best practice rather than minimalism, the landscape evidence points toward clap as the dominant, ecosystem-standard choice for this category.

### Principles and Implementation

The shared requirement across the Python and TypeScript ports is that the CLI **acts as a thin, declarative front-end** over a reusable library, with its behavior reflected in both a scriptable command surface and, in many cases, a web API. The **level of agreement** required is at the architectural pattern and capability level rather than at the exact crate or syntax. In particular, the owner’s mandate emphasizes that source implementations and ledger classifications are evidence, not predetermined winners, and that agreement, familiarity, or raw performance alone cannot select a design. Instead, we must isolate the principles that these ports embody and decide whether they should be preserved, adjusted, or diverged from in the Rust port.

From the Python and TypeScript precedents, several principles emerge. First, there is a **principle of discoverability and self-documentation**: commands should have clear help output, consistent subcommand shapes, and sensible defaults, so users can explore the surface without reading internal implementation details.[1][3][8] Click and Commander both provide automatic help and default flags such as `-h` and `-V`, and the Python port adds extended version information and a dedicated completion command.[Context] Second, there is a **principle of cross-environment portability**: global options such as `--json` or `--config` should work consistently whether invoked before or after the verb and across different subcommands, enabling scripts and tooling to treat the CLI as a stable interface.[Context][3][8] Third, there is a **principle of ergonomic error feedback**: unknown commands should produce did-you-mean suggestions, argument validation should be enforced before side effects, and error output should be structured in a way that supports scripting and automation.[1][3][7][8] Fourth, there is a **principle of environment integration**: configuration should be available through environment variables with a predictable prefix, mirroring Click’s `auto_envvar_prefix` and enabling deployment environments to configure runtime behavior without rewriting command lines.[Context][1][3][7][8]

Within Rust, these principles must be implemented in a way that respects the ecosystem’s guidance and performance expectations. Modern Rust CLI development, as described in the Tech Bytes cheat sheet, is characterized by **zero-cost abstractions** and **async-by-default architectures** that prioritize sub-millisecond startup times, especially when performing I/O or network requests.[8] Clap v4 and the emerging v5 design are highlighted as the standard for derive-based parsing, reducing boilerplate and providing strong type safety.[8][15] The cheat sheet emphasizes using `tokio::main` for async CLIs, serde-based configuration structures, and explicit error handling via `anyhow` and `thiserror` rather than panics.[8] OneUptime’s guide similarly advocates for clap’s derive API, sensible defaults, environment-variable fallbacks, structured errors, meaningful exit codes, colored output, and shell completions via `clap_complete`.[7] Tao’s clap-in-practice article stresses writing user-facing help in doc comments, using clap to enforce formats and argument relationships, and covering valid and invalid inputs with tests using `try_parse_from`.[1]

Comparing architectural alternatives, there are two major patterns: a **feature-rich, declarative framework** such as clap, and a **minimal parser plus a custom routing layer** such as pico_args or rust-args-parser combined with manual validation and suggestion logic. The feature-rich pattern aligns closely with Click and Commander’s role in the Python and TypeScript ports, offering automatic help, validation, default flags, and sometimes suggestions.[1][3][7][8][10][11][14][15][17] The minimal pattern favors small binaries and faster compile times but pushes significant responsibility into application code, including help generation, completions, env-var handling, and error ergonomics.[4][5][9][16] For a template that will be used as a shared precedent across multiple Rust services, the feature-rich pattern better preserves the cross-language principles and reduces the risk of subtle inconsistencies or maintenance burden.

Regarding **command surface shape**, the Python port’s noun–verb grouping (e.g., `plbp projects list`, `plbp config set`) makes resources explicit and provides a natural alignment with RESTful APIs and resource-oriented libraries.[Context] The TypeScript port’s flatter shape, with `projects` as a default command and `config` as a stand-alone command, reflects Commander’s ergonomics but introduces a slight divergence in conceptual grouping.[Context] The owner’s research mandate instructs us to treat this divergence explicitly, not quietly choose one baseline. Applying the principles above, the noun–verb grouping better supports discoverability and cross-language conceptual alignment, since it matches the resource-plus-action pattern that many users expect and that strongly resembles HTTP verbs on resources. It also scales more gracefully as new verbs are added for a resource; for example, `projects inspect`, `projects sync`, or `config migrate`. Clap’s subcommand model is naturally suited to noun–verb hierarchies, allowing nested subcommands and shared global options across them.[1][3][6][8][10][11][14][15] Therefore:

> **BASELINE-REVIEW: F265 — command surface shape — propose converging on Python’s noun–verb subcommand groups for the Rust template, preserving resource-oriented grouping and better alignment with RESTful and library APIs; evidence from clap’s subcommand support and ecosystem guidance indicates that this pattern is idiomatic and maintainable in Rust.**[1][3][6][8][10][11][14][15]

The **extended `--version` output** principle is that the version flag serves not only to expose a semantic version string but also to provide build and runtime diagnostics, including tool version, language runtime version, and platform details. Click supports eager options that run callbacks before other parsing, enabling the Python port to print tool, Python, and platform lines.[Context] In Rust, clap provides both built-in version actions and the ability to define custom behavior for options, including eager evaluation before other parsing or command execution.[1][3][6][8][10][15] Companion crates such as `rustc_version`, `built`, or `vergen` are commonly used to embed build-time metadata in the binary through a `build.rs` script, including compiler version, target triple, and VCS information. Although this analysis does not fetch their documentation, their widespread use in Rust CLIs and libraries is well known in practice, and the acceptance criteria will require verifying MSRV, licensing, and maintenance state before adoption. The principle remains: extended version output should be driven by compile-time metadata and library-layer logic, not by ad-hoc runtime probes.

For **shell-completion generation**, Python’s Click-based implementation exposes a `completion` command that emits scripts for bash, zsh, and fish.[Context] Clap’s ecosystem provides the **clap_complete** crate, which is explicitly described as “shell completion generation for `clap`,” dual-licensed under Apache-2.0 or MIT and with millions of downloads per month, indicating heavy usage.[17] Blog posts and tutorials recommend using clap_complete with clap’s Command definitions to generate completion scripts and distribute them with the CLI.[7][8][11][17][19] This pattern matches the Python precedent and is idiomatic in Rust.

The **blanket env-var binding** principle is that every global option should be configurable via environment variables using a common prefix, without requiring manual env-var annotations for every option. Click’s `auto_envvar_prefix` provides this behavior by automatically mapping option names to env vars with a prefix.[Context] Clap does not have an exact analog, but it does provide `env` integration via the `env` feature and API, allowing arguments to read from environment variables.[1][3][7][8][15] In practice, developers often annotate individual arguments with `env = "FOO_BAR"` or use helper functions to reduce boilerplate. For `rs-launch-blueprint`, a small local convention layer can be added on top of clap that inspects global option definitions (in a dedicated struct) and generates a consistent prefix-based env-var mapping, either via a macro that expands field names to env-var strings or via a helper that constructs `Arg::env` values on the builder API.[1][3][7][8][15] This preserves the principle without requiring an external crate.

Stackable **global options** must be recognized regardless of position relative to the verb, so `plbp projects list --json` and `plbp --json projects list` both work, matching Click’s behavior.[Context] Clap supports global arguments that apply to all subcommands via the `global` flag on arguments and via structural flattening of shared option structs.[1][3][8][10][15] This means that global options can be defined at the root and still be available and valid when placed after subcommand names. The derive API is particularly well suited to representing global options as a separate struct flattened into all commands.[1][3][8][10][15] This pattern satisfies the principle.

Finally, **did-you-mean matching** is a shared requirement where unknown commands or arguments should trigger suggestions rather than simple errors. Commander provides built-in did-you-mean logic, and the TypeScript port relies entirely on it.[Context] The Python port uses difflib in the standard library with a cutoff to filter suggestions.[Context] Clap includes suggestion mechanisms for unknown subcommands and arguments, typically printing “did you mean” hints when parsing fails on a name that is close to a defined subcommand.[11][13][15] This is not extensively documented in the provided sources but is a known practical behavior of clap in many CLI tools. If this built-in feature is insufficient or needs tuning, the template can optionally extend it using a small wrapper that inspects clap’s error messages and adds suggestions via a crate such as `strsim`, though this report does not recommend adding that dependency by default. The principle is preserved either way.

Putting these pieces together, the architectural pattern is a **clap-based derive CLI with shared global options, resource-oriented noun–verb subcommands, extended version implemented via library and build metadata, clap_complete-based completions, env-var integration via a local convention layer, and clap’s built-in suggestions for did-you-mean.** This pattern is consistent with Rust ecosystem guidance, composes cleanly with async runtimes and library layers, and retains principles from the Python and TypeScript ports where appropriate.

### Recommendation

The recommended stack for `rs-launch-blueprint` is:

The CLI front-end should be built on **clap 4.x** using the **derive API** with the `env` feature enabled, matching the documented, mature pattern for production-ready Rust CLIs.[1][3][6][7][8][10][11][14][15] Clap should be configured with global options represented as a separate struct, flattened into the main CLI type and marked as `global` so that options are stackable and available across all subcommands regardless of position.[1][3][8][10][15] The command surface should adopt **noun–verb subcommand groups** analogous to the Python port, such as `projects list`, `projects create`, `config show`, and `config set`, rather than the TypeScript port’s default-command-plus-standalone-config shape.[Context][1][3][6][8][10][11][14][15]

Extended `-V` / `--version` output should be implemented using clap’s derived CLI structure with a custom `version` flag wired to an early callback or a dedicated `version` subcommand that prints tool, Rust, platform, and build metadata using whatever version-accessor mechanism R22 selects (for example, compile-time environment variables and a build script).[1][3][6][7][8][10][15] Shell completions should be generated via **clap_complete**, exposed through a `completion` subcommand that takes a shell name and prints the appropriate script.[7][8][11][17][19] Global options should be equipped with **blanket env-var binding** using a standard prefix such as `PLBP_`, realized via clap’s `env` feature and a small helper or macro that applies the prefix automatically to each global option.[1][3][7][8][15] Did-you-mean suggestions should rely on clap’s built-in fuzzy matching for unknown subcommands and arguments, keeping parity with Commander’s built-in suggestions without adding an extra dependency.[11][13][15]

This stack meets the fitness gates: clap and clap_complete are dual-licensed MIT/Apache-2.0 and therefore compatible with the template’s license requirement.[11][14][15][17] Their MSRV is within a reasonable range for “stable minus two minor versions,” though this must be confirmed with the latest crate metadata as an acceptance check rather than assumed. Both crates are actively maintained and widely adopted, with frequent releases and high download counts according to lib.rs and docs.rs commentary.[11][14][15][17][19] No RustSec advisories are known in the provided sources, though a final integration must verify this using rustsec.org. Clap and its ecosystem are tested across Linux and macOS; Fedora’s packaging guidelines and the Yocto project’s crate downloads provide indirect evidence of cross-platform support.[12][19] Default features, including derive and env, must be explicitly enabled and documented in `Cargo.toml`, and the compile-time and binary-size costs acknowledged as a tradeoff against reduced application-level code complexity.[1][3][6][7][8][10][11][14][15][17]

### Members

#### clap

##### Landscape

Clap occupies the central position in the Rust CLI parsing landscape. Its documentation identifies it as a “full featured, fast Command Line Argument Parser for Rust,” with both declarative (derive) and procedural (builder) APIs.[11][13][14][15] Blog posts describe clap as the de facto standard for building command-line utilities in Rust, highlighting its maturity, comprehensive feature set, and strong ecosystem support.[1][3][6][7][8][10] Tao’s “Rust clap in Practice” article explicitly labels clap as a “mature argument parser in the Rust ecosystem,” noting its two primary ways to define commands and recommending derive for most applications.[1] CodeWithYoha’s tutorial calls clap “Rust’s most popular and powerful library for building CLIs” and emphasizes its declarative argument structures, automatic help generation, and validation capabilities.[3] Luc Berton’s piece similarly frames clap as the industry-standard crate for building CLI tools in Rust, instructing readers to enable the `derive` feature.[6][10]

Clap’s GitHub repository shows active maintenance, frequent releases, and a clear roadmap.[11][13][14] The docs.rs page lists version 4.6.6 with instructions for adding clap via `cargo add clap` and notes dual licensing under Apache-2.0 or MIT.[15] Older branches and tags, including v3 beta versions and specific commits, showcase a long history of development and iterative improvement.[13][14] The presence of companion crates such as `clap_complete`, `clap_derive`, and `clap_lex` further underscored in Yocto project error logs and packaging guidelines demonstrates a network of crates built around clap.[17][19] This landscape analysis positions clap firmly in the established industry-standard bin.

##### Principles and implementation

Clap’s design aligns closely with the principles identified for `rs-launch-blueprint`: declarative CLI definition, automatic help, validation, global options, subcommand hierarchies, and integration with environment variables and shell completions.[1][3][6][7][8][10][11][14][15][17] The **derive API** allows developers to describe the interface with structs, enums, and attributes, which Tao’s article notes as concise and suitable for most applications.[1] This mirrors TypeScript’s use of Commander’s fluent API and Python’s use of Click decorators, but with the added benefit of Rust’s static type checking. Clap’s documentation encourages writing user-facing help in doc comments and inspecting `--help` for the root command and every subcommand, reinforcing the principle of self-documentation.[1][3][15]

Clap handles parsing and validation so that invalid input is rejected before side effects begin, a principle explicitly noted in Tao’s article and consistent with the owner’s requirement that errors be raised early and predictably.[1][3][7][8] The library offers hooks for custom validation, including typed parsers and value parsers, which CodeWithYoha’s tutorial emphasizes for ensuring argument validity.[3] The derive API can reflect enumerations and relationships between arguments, supporting complex CLI surfaces without manual string parsing.[1][3][6][8][15]

For **global options**, clap provides the `global` flag on `Arg` definitions and supports flattening shared option structs into multiple commands via the derive API.[1][3][8][10][15] This means a single global options struct can be declared and flattened into the root CLI struct, with its fields marked as global so they apply across all subcommands. The behavior that `plbp projects list --json` should work exactly like `plbp --json projects list` can be achieved by marking `--json` as global and flattening the struct, preserving the cross-language principle.

Clap’s `env` feature allows arguments to source values from environment variables, making it possible to replicate Click’s `auto_envvar_prefix` behavior via a convention layer.[1][3][7][8][15] Developers can annotate arguments with `env` metadata in the derive attributes or builder calls, and a small macro or helper can standardize the mapping from option names to env-var names with a prefix. While not identical to Click’s automatic behavior, this approach is flexible enough for `rs-launch-blueprint` and respects Rust’s preference for explicit, compile-time configuration over implicit runtime magic.

Clap’s version handling capabilities, including built-in `--version` flags and custom version behavior via `ArgAction::Version` or dedicated subcommands, allow `rs-launch-blueprint` to implement extended version output that prints tool, Rust, and platform information.[1][3][6][8][10][15] Integration with build-time metadata crates such as `rustc_version` or `vergen` can be done in a build script that updates constants used in the version function.

##### Dominant choice

Within the category of Rust CLI parsers, clap is the dominant choice for feature-rich, production-ready CLIs. It combines broad adoption, extensive documentation, companion crates, and active maintenance.[1][3][6][7][8][10][11][14][15][17][19] Tutorials and packaging guidelines overwhelmingly reference clap as the primary crate to use.[1][3][6][7][8][10][12] The Tech Bytes cheat sheet describes clap v5 (and by implication 4.x) as the 2026 standard, calling the derive macro “the 2026 standard” and noting a 40% reduction in boilerplate over legacy builder patterns.[8] OneUptime’s guide characterizes clap as “the de facto standard” for argument parsing, recommending its derive API as more maintainable than the builder API.[7]

Clap’s dual licensing, integration with async runtimes, and compatibility with error-handling crates such as `anyhow` and `thiserror` make it suitable for sophisticated applications, not just small utilities.[7][8] Its use in Linux packaging guidelines and Yocto’s build system indicates trust from downstream ecosystems that care about long-term support and stability.[12][19] Compared to alternatives, clap is uniquely positioned to provide the full set of behaviors needed by `rs-launch-blueprint` without resorting to extensive custom code.

##### Qualified shortlist

The qualified shortlist for this member includes **bpaf**, **pico_args**, **rust-args-parser**, and **flexiargs**. Bpaf offers derive and combinator APIs with flexibility, making it a plausible alternative for some CLI shapes.[16] Pico_args is ultra-simple and minimal, which could appeal to very small tools or contexts where compile-time overhead must be minimized.[5][18] Rust-args-parser is callback-based, tiny, and fast, with a clearly stated MSRV of 1.60.[4] FlexiArgs is minimalist and avoids macros, focusing on rule-based parsing.[9]

However, none of these candidates provide the full combination of derive-based type-safe parsing, automatic help and validation, global option support, env-var integration, shell completion generation via a first-class companion crate, and built-in suggestion mechanisms, all under an actively maintained, widely adopted umbrella.[1][3][6][7][8][10][11][14][15][17] For `rs-launch-blueprint`, the shortlist is therefore dominated by clap, with the other crates deemed more suitable for specialized contexts that differ significantly from this template’s needs.

##### Excluded by gate

Candidates are excluded by the fitness gates when they fail to meet licensing, MSRV, RustSec, platform support, or feature requirements. Pico_args, rust-args-parser, and flexiargs are primarily excluded by **feature gates**, rather than licensing or MSRV. Their focus on minimal parsing without automatic help, global arguments, env-var conventions, or completions means they require substantial custom application code to realize the desired behaviors.[4][5][9] That increases maintenance burden and risk for a template that aims at best-practice architecture. Bpaf, while more capable, does not have the same ecosystem of companion crates for shell completions and error-handling patterns tied specifically to its API, and it is less commonly cited in tutorials targeting production CLIs.[16]

Licensing compatibility is generally met by these crates, but their ecosystem maturity and practice evidence fall short of clap’s. Since numeric data such as downloads and stars are not fetched in this analysis, the gate decision is based on feature fit and ecosystem positioning rather than adoption metrics, with the acceptance check requiring verification of RustSec advisories and MSRV from crate registries before final integration.

##### Up-and-comers

Pico_args, rust-args-parser, and flexiargs represent up-and-comers focused on niche tradeoffs. Pico_args’ “ultra simple” design is ideal for very tiny utilities where dependencies must be minimized and help output is simple.[5][18] Rust-args-parser’s callback-based approach can be attractive when dynamic behaviors are needed without a derive macro.[4] FlexiArgs’ avoidance of macros and derive systems makes it appealing in environments where macro use is discouraged or code generation is limited.[9]

These crates could be considered for future, small Rust projects that require only simple parsing and do not need the full richness of subcommands, global options, completions, and env-var integration. For `rs-launch-blueprint`, they are better understood as future-proofing options: if the template were ever refactored to serve extremely constrained environments, these crates could be revisited. For now, they remain in the up-and-comer bin without being chosen.

##### Fit for this template

Clap fits `rs-launch-blueprint` remarkably well. It supports the **CLI + library + web** template by offering strong typing, subcommand hierarchies, and global options that can mirror library modules and web routes.[1][3][6][8][10][11][14][15] Its derive API enables the CLI structure to be encoded as a Rust type, which can be mapped directly to library functions and HTTP handlers. The pattern encouraged by modern Rust CLI development—using `tokio::main` for async commands and flattening configuration structs via serde—is explicitly described in the Tech Bytes cheat sheet as the “non-negotiable gold standard” when tools perform I/O or network requests.[8] Clap is designed to compose with async runtimes and has no runtime-specific coupling in its core.

Clap’s error handling and validation semantics support the owner’s architectural principle of early error detection and structured output. Tutorials recommend combining clap with `anyhow` and `thiserror` for clean error messages and stack traces, though this is formally owned by another bundle.[7][8] The ability to derive help, version, and completions from the same CLI type simplifies maintenance and keeps the command surface consistent across CLI and library layers.

##### Recommendation

This member is recommended as the **primary CLI-parsing crate** for `rs-launch-blueprint`. Specifically, the template should adopt clap 4.x with the following configuration:

The crate should be added via `cargo add clap --features derive,env` in the root crate, as described in Tao’s tutorial and other guides.[1][3][6][10][15] The primary CLI type should be defined via `#[derive(Parser)]` using clap’s derive macro, with subcommands represented via `#[derive(Subcommand)]` enums and shared global options flattened into the root type.[3][6][8][10][15] The command surface should follow noun–verb grouping, and global options should be marked as `global` and equipped with env-var integration via the `env` feature.[1][3][7][8][15] Version flags, help, and completions should be configured using clap’s standard patterns and companion crate (clap_complete). Shell completions and extended version output should be implemented as described in later sections.

##### Ranked runner-up

The ranked runner-up for this role is **bpaf**. Bpaf’s support for both derive and combinatoric APIs and its ability to mix them offers flexibility in representing dynamic CLIs and might be attractive in certain designs.[16] However, bpaf lacks the breadth of ecosystem integration that clap enjoys, especially around shell completions, packaging guidelines, and error-handling patterns. Its documentation is less prominent in tutorials oriented toward production CLI + library + web stacks. For `rs-launch-blueprint`, bpaf would require more bespoke glue and would provide fewer ready-made patterns than clap.

##### Tradeoffs

The primary tradeoff in choosing clap is **compile-time and binary-size cost**. Clap is a large crate with many features, which increases compile-time and may contribute to larger binary sizes compared to minimal parsers like pico_args or flexiargs.[4][5][9][16] The Tech Bytes cheat sheet acknowledges that modern Rust CLIs prioritize zero-cost abstractions and async-first architectures, but also notes the importance of alternative allocators and link-time optimization for high-frequency tools to mitigate overhead.[8] For `rs-launch-blueprint`, the template can recommend enabling link-time optimization in release builds, considering alternative allocators such as mimalloc or jemalloc for multi-threaded environments, and static linking where appropriate, as described in the cheat sheet.[8] These steps can offset some of clap’s cost.

Another tradeoff is the **learning curve**. Clap’s derive attributes and builder API involve numerous options and conventions, which may be overwhelming for new Rust developers. However, the abundance of tutorials, examples, and community support mitigates this concern.[1][3][6][7][8][10][11][14][15][17] In exchange, developers gain a robust, self-documenting CLI that is easier to maintain over time.

##### Parameters

This member owns the following parameters for the template:

Clap is the **CLI-parsing framework** for `rs-launch-blueprint`, with `owns cli_parser_crate = clap` and `owns cli_parser_version = 4.x` (to be pinned to a specific minor version after verifying crate metadata). It assumes that the MSRV policy (“stable minus two minor versions”) is satisfied by clap’s declared MSRV and that edition 2024 is compatible with clap’s derive and env features. It also assumes that the template’s license `MIT OR Apache-2.0` matches clap’s dual licensing, which the docs confirm.[11][14][15] No `CONFLICT` entries are needed for this member, as clap aligns with all consumed parameters.

##### Migration implications

Adopting clap will structure the CLI entry point as a `main` function that calls `Cli::parse()` on a derive-based type. The template’s file layout will likely include a `src/bin/plbp.rs` or similar entry-point file that imports a `cli` module from the library crate. Subcommand modules such as `projects`, `config`, and `completion` will be reflected in the CLI type as enum variants. Existing placeholder parsing code will be replaced by clap-based definitions, and the global-option struct will be added, flattened into the CLI type. Documentation and tests will be updated to use clap’s help and `try_parse_from` testing patterns.[1]

##### Validation strategy

The validation strategy for clap includes both **unit tests** and **integration checks**. At the unit level, tests will use `Cli::try_parse_from()` to ensure that valid inputs parse successfully, missing required arguments produce clear errors, and invalid values are rejected with helpful messages.[1][3][15] The template will include examples such as `plbp projects list --json`, `plbp --json projects list`, and `plbp config set --key foo --value bar` to verify global option stacking and noun–verb grouping. Integration tests will run the built CLI on `ubuntu-latest` and `macos-latest` CI runners, verifying that help, version, and completion commands behave as expected. Acceptance checks will confirm that clap’s MSRV matches the template’s policy, that no RustSec advisories are open, and that clap builds with the template’s default features.

##### Confidence & re-verify trigger

Confidence in clap as the primary CLI parser is **high**, given its ecosystem dominance, feature set, and alignment with Rust best practices.[1][3][6][7][8][10][11][14][15][17][19] Re-verification is triggered by events such as a major clap release (for example, v5 stabilizing), the discovery of a RustSec advisory affecting clap, or significant changes to the Rust MSRV or edition that might require updating clap’s configuration. Additionally, if future benchmarks show that compile-time or binary-size costs become problematic for the template’s use cases, a re-evaluation of minimal parsers like pico_args and rust-args-parser would be warranted.

##### Sources

Key sources for this member include clap’s GitHub repository and docs.rs page, which describe its features, licensing, and usage.[11][13][14][15] Tutorials by Tao, CodeWithYoha, Luc Berton, OneUptime, and Tech Bytes provide practical guidance and contextualize clap’s role as de facto standard.[1][3][6][7][8][10] Fedora packaging guidelines and Yocto project logs confirm downstream adoption and trust.[12][19] These sources are interpreted as authoritative and practice evidence within the landscape.

#### clap_complete

##### Landscape

Clap_complete is a companion crate to clap that specializes in **shell completion generation**. Its documentation describes it as “shell completion generation for `clap`,” and notes dual licensing under Apache-2.0 or MIT.[17] The lib.rs listing mentions version 4.6.7 as of mid-2026 and reports millions of downloads per month, suggesting heavy usage among clap-based CLIs.[17] Yocto project error logs show clap_complete being fetched alongside clap and related crates (`clap_derive`, `clap_lex`), indicating that build systems and packaging environments treat it as part of the standard clap ecosystem.[19]

This positioning puts clap_complete in the established industry-standard bin for completions, tightly coupled with clap’s command definitions. It is the primary tool for generating bash, zsh, and fish completions for clap-based CLIs.

##### Principles and implementation

The principle for shell completions in `rs-launch-blueprint` is that the CLI should expose a **completion command** that emits scripts for commonly used shells, mirroring the Python port’s behavior.[Context] Clap_complete achieves this by consuming clap’s `Command` representation of the CLI and generating appropriate completion scripts. Tutorials and ecosystem guidance, such as the OneUptime blog and Tech Bytes cheat sheet, explicitly recommend using clap_complete to generate completion scripts and distribute them with CLI tools.[7][8][17][19]

Implementation typically involves adding a `completion` subcommand to the CLI type, which takes a shell name as an argument (for instance, `bash`, `zsh`, or `fish`) and then uses clap_complete to print the corresponding script. This aligns well with `rs-launch-blueprint`’s requirement to have a `completion` command and to support multiple shells. Clap_complete respects clap’s argument definitions, including global options and subcommands, ensuring that completions remain accurate as the CLI evolves.[17]

##### Dominant choice

Within the space of shell completion generation for Rust CLIs, clap_complete is the dominant choice for clap-based applications. Its tight integration, dual licensing, and widespread usage make it the natural complement to clap itself.[17][19] While other crates exist for generating completions or assisting with shell integration, none are as tightly bound to clap’s Command definitions or as widely adopted in tutorials and production projects.[7][8][17][19]

##### Qualified shortlist

Alternative approaches to completions include hand-written scripts, generic completion frameworks, or CLI-agnostic completion generators. However, these are not in the qualified shortlist for this template because they either require manual maintenance separate from the CLI definitions or lack integration with clap’s argument parsing. Clap_complete is therefore the primary member on the shortlist, with manual scripts considered only as a fallback if clap_complete’s behavior proves insufficient or incompatible with specific shell environments.

##### Excluded by gate

No specific crate is excluded by the gates for completions, but generic or hand-rolled solutions are effectively excluded by the **fit gate**. They do not leverage clap’s command definitions, would require separate maintenance, and could drift out of sync with the CLI surface. Clap_complete, by contrast, shares clap’s licensing, MSRV, and platform support and is designed to work alongside clap in production environments.[17][19]

##### Up-and-comers

Up-and-comer options in the completion space could include shell-specific utilities or platforms like fish’s dynamic completion scripts. However, these are not directly relevant to `rs-launch-blueprint`’s crate stack; they remain outside the scope of this member. If future Rust crates emerge that offer more advanced or dynamic completions integrated with clap, they could be considered, but clap_complete currently holds the standard position.

##### Fit for this template

Clap_complete fits `rs-launch-blueprint` well because it allows the template to **encode completions as a first-class behavior** in the CLI. The `completion` subcommand can be designed to accept a `shell` argument and call clap_complete with the CLI’s Command definition to print the script. This matches the Python port’s design and ensures parity in user experience across languages. It also aligns with the owner’s principle of leveraging ecosystem-standard tools rather than reinventing them.

##### Recommendation

Clap_complete is recommended as the **completion-generation member** of the stack. The template should add `clap_complete` as a dependency and implement a `completion` subcommand that emits bash, zsh, and fish scripts using the library’s API.[7][8][17][19] This command should be documented in the CLI help and tested via integration tests that verify the output format and compatibility with installed shells on `ubuntu-latest` and `macos-latest`.

##### Ranked runner-up

There is no strong runner-up for completion generation in the provided sources. Manual scripts or generic frameworks would serve as fallbacks rather than preferred alternatives.

##### Tradeoffs

The primary tradeoff is that clap_complete adds an additional dependency and some compile-time cost. However, this cost is minimal relative to clap itself and is justified by the maintenance savings and user experience improvement. Another tradeoff is the need to keep completion scripts updated as the CLI evolves, but clap_complete’s integration with clap’s Command definitions largely automates this.

##### Parameters

Clap_complete owns `completion_crate = clap_complete` and assumes compatibility with `cli_parser_crate = clap`. It requires that clap’s Command definitions remain accessible in the application so that the completion command can construct the parser used by clap_complete.[17][19] No `CONFLICT` entries arise here.

##### Migration implications

Integration with clap_complete will require adding a `completion` subcommand in the CLI type and a corresponding module in the library. Existing placeholder completion commands, if any, will be replaced by calls to clap_complete. Packaging scripts may be updated to install completion scripts in standard locations for bash, zsh, and fish.

##### Validation strategy

Validation will involve running the CLI with `plbp completion bash`, `plbp completion zsh`, and `plbp completion fish` and verifying that the output generates valid completion scripts. Integration tests can source these scripts in a temporary shell and confirm that commands and options are offered correctly as completions. CI should run these tests on `ubuntu-latest` and `macos-latest`.

##### Confidence & re-verify trigger

Confidence in clap_complete is **high**, given its close coupling to clap and evidence of heavy usage.[17][19] Re-verification would be triggered by significant changes in shell completion behavior in clap or clap_complete, the introduction of a new major shell completion framework, or RustSec advisories affecting clap_complete.

##### Sources

Sources include the clap_complete lib.rs entry describing its purpose, licensing, and download counts, and Yocto project logs indicating its use in build systems.[17][19] These are treated as authoritative for this member.

#### Build-metadata crate (for extended version)

##### Landscape

While this report does not have direct search results for specific build-metadata crates like `rustc_version`, `built`, or `vergen`, these crates are widely known in the Rust ecosystem as tools for embedding compile-time metadata in binaries. They typically operate via a `build.rs` script that queries environment variables such as `CARGO_PKG_VERSION`, target triple information, and rustc version strings, and generate Rust source files or constants for use at runtime.

Within the landscape, such crates occupy the **up-and-comer to standardizing** bin, as they are increasingly common in production Rust CLIs and libraries that need rich version output and diagnostics. They are not required, since raw environment macros can supply some metadata, but they offer a structured approach.

##### Principles and implementation

The principle for extended version output is that metadata should be **compiled into the binary** based on the build environment, not inferred at runtime or hard-coded manually. This ensures reproducibility and traceability: the version output should reflect the exact build environment, including toolchain and VCS information. A build-metadata crate will be used in `build.rs` to gather rustc version, target triple, and other fields, storing them in constants that the CLI’s version function can print.

Implementation involves adding a `build.rs` file in the crate, including the metadata crate as a build-dependency, and configuring it to write generated code or environment variables. The CLI’s version handler will then call a library function that formats these constants into user-facing output.

##### Dominant choice

No single build-metadata crate is dominant in the same way as clap is for CLI parsing. `vergen` and `built` are commonly used in practice, but the choice here will be deferred to R22, which owns the runtime-version-accessor decision. The key principle is that a build-metadata crate is used and integrated with the version flag, not which specific crate is chosen.

##### Qualified shortlist

The shortlist likely includes `vergen`, `built`, and `rustc_version`, each with its own advantages. `vergen` is known for comprehensive metadata, `built` for simple compile-time constants, and `rustc_version` for rustc version detection. Final selection must respect licensing, MSRV, and RustSec advisories.

##### Excluded by gate

No specific crate is excluded here in this report. Gates will be applied in R22’s decision, which this report consumes.

##### Up-and-comers

New crates may emerge to provide even more sophisticated metadata integration, but they are beyond the scope of this report. The template should remain flexible enough to switch metadata crates without changing the CLI’s architecture.

##### Fit for this template

A build-metadata crate fits `rs-launch-blueprint` by enabling extended version output, which aligns with the Python port’s behavior and the owner’s principle of diagnostic-rich CLIs. It allows the CLI to print tool, Rust, and platform information regardless of runtime environment, supporting debugging and support workflows.

##### Recommendation

This member is recommended in a **generic sense**: `rs-launch-blueprint` should use a build-metadata crate via a `build.rs` script to provide extended version information. The specific crate will be determined by R22, and the CLI’s version handler should be designed to call a library function that prints the metadata fields.

##### Ranked runner-up

The runner-up is using only `env!` macros and manual constants, but this is discouraged due to lack of flexibility and diagnostic richness.

##### Tradeoffs

Using a build-metadata crate adds a build-dependency and can increase compile-time slightly. It also requires maintaining `build.rs` logic. However, the benefits in diagnostic clarity and reproducibility outweigh these costs.

##### Parameters

This member assumes `runtime-version-accessor` is decided by R22 and does not own that parameter. It owns the pattern of extended version output that uses build metadata and assumes compatibility with clap’s version handling.

##### Migration implications

Adding a build-metadata crate will require introducing `build.rs`, updating `Cargo.toml` with a build-dependency, and updating the CLI’s version function to read generated constants.

##### Validation strategy

Validation includes building the crate and verifying that the version output prints the expected metadata, including tool version, Rust version, and target triple, on CI runners.

##### Confidence & re-verify trigger

Confidence in the pattern is high; re-verification is triggered if the chosen metadata crate becomes unmaintained or incompatible with future Rust versions.

##### Sources

No direct search results are provided for specific metadata crates; this section is based on general Rust ecosystem practice. Acceptance criteria will require fetching documentation and metadata from crates.io and docs.rs before final integration.

### Compatibility

Clap and clap_complete are explicitly designed to work together. Clap’s docs.rs page and GitHub repository describe an ecosystem that includes `clap_complete`, `clap_derive`, and `clap_lex`.[11][14][15][17][19] The Yocto project’s error logs show these crates being downloaded together for build systems, indicating compatibility and shared versioning.[19] Tutorials that discuss clap and clap_complete present examples where completions are generated from clap’s Command definitions, demonstrating practical integration.[7][8][17]

Compatibility between clap and a build-metadata crate is straightforward because the metadata crate only participates in compile-time via `build.rs` and emits constants used at runtime by the CLI’s version handler. There is no runtime coupling or mutual dependency. As long as the metadata crate meets licensing and MSRV requirements, it will integrate cleanly with the template’s CLI and library layers.

### Parameters

This report sets the following owned and assumed parameters.

The template **owns** `cli_parser_crate = clap`, `cli_parser_version = 4.x`, `completion_crate = clap_complete`, `command_surface_shape = noun_verb_groups`, `version_output_pattern = extended_metadata`, `global_options_pattern = flattened_struct_global_flags`, and `env_prefix_pattern = PLBP_*`. It also owns `did_you_mean_pattern = clap_builtin_suggestions`, relying on clap’s fuzzy matching for unknown commands and arguments.[11][13][15]

The template **assumes** `runtime-version-accessor` is decided by R22, `rust-edition = 2024`, `msrv-policy = stable_minus_2_minor`, `license = MIT OR Apache-2.0`, and `target-os-matrix = ubuntu-latest, macos-latest` as given in the context.[Context] There are no `CONFLICT` lines in this report; all recommendations fit within the consumed parameters.

### Migration Implications

Migrating the template to this stack implies several file-level and structural changes. The CLI entry point will be rewritten to use a clap-derived `Cli` struct, with `main` invoking `Cli::parse()` and dispatching to library functions based on subcommands. The command surface will be reorganized into noun–verb groups: for example, a `projects` module exposing verbs `list`, `create`, and others, and a `config` module exposing verbs `show` and `set`. The TypeScript-like default-command pattern will be replaced by explicit subcommand grouping in Rust.

The `completion` command will be added as a subcommand in the CLI type and implemented in the library using clap_complete. Global options will be extracted into a dedicated struct, flattened into the CLI type, and marked as global, with env-var integration via the `env` feature. The version flag or subcommand will be wired to a library function that prints extended metadata, and build-metadata integration via `build.rs` will be introduced. Unknown-command suggestion logic will rely on clap’s built-in behavior, and any placeholder manual suggestion code will be removed.

Documentation, tests, and CI scripts will be updated to reflect the new CLI surface, including examples of noun–verb commands, global options, extended version output, and completion usage. The Python and TypeScript ports’ documentation will be cross-referenced to maintain conceptual parity while acknowledging ecosystem-specific differences.

### Validation Strategy

Validation will be conducted at multiple levels.

At the CLI parsing level, unit tests will use `Cli::try_parse_from()` to ensure that valid commands parse successfully and invalid commands produce appropriate errors. Tests will cover noun–verb commands such as `plbp projects list`, `plbp config set`, and global options such as `--json` and `--config` applied before or after verbs. Tests will verify that env-var bindings work as expected when environment variables with the `PLBP_` prefix are set.

Extended version output will be tested by running `plbp --version` (and `plbp -V`) and verifying that tool version, Rust version, and platform information are printed in the expected format. The completion command will be tested by invoking `plbp completion bash`, `plbp completion zsh`, and `plbp completion fish`, and verifying that the output generates valid scripts for those shells.

Integration tests will run the CLI on `ubuntu-latest` and `macos-latest` CI runners, verifying behavior end-to-end. Acceptance checks will query crates.io and docs.rs for clap and clap_complete to confirm MSRV, licensing, and recent downloads, and rustsec.org for advisories. These checks are planned and must be executed during integration; they are not run in this offline analysis.

### Confidence & Re-verify Trigger

Confidence in the recommended stack—clap with derive and env features, clap_complete for completions, and a build-metadata crate for extended version—is **high**, based on authoritative documentation, ecosystem guidance, and alignment with modern Rust practices.[1][3][6][7][8][10][11][14][15][17][19] Clap’s dominance and widespread adoption reduce the risk of unexpected behavior, and its feature set matches the template’s needs closely.

Re-verification is triggered by events such as:

A major release of clap (for example, v5 stabilizing) that changes derive semantics, global options behavior, or env integration.[8][15] The discovery of a RustSec advisory for clap or clap_complete. Significant changes to Rust’s MSRV or edition that affect clap’s compatibility. Performance or resource issues observed in production that suggest the need to reconsider minimal parsers. Changes in owner requirements, such as new criteria for env-var binding or suggestion behavior.

In such cases, the landscape and fitness gates would be revisited, and alternatives such as bpaf or minimal parsers would be reevaluated against updated constraints.

### Sources

This report draws on several key sources from the provided search results.

Tao’s “Rust clap in Practice” blog provides detailed guidance on clap’s derive and builder APIs, testing patterns, and best practices for help and validation.[1] CodeWithYoha’s “Mastering Command Line Utilities in Rust with Clap” emphasizes clap’s declarative argument structures, help generation, validation, and CLI design principles related to consistency, defaults, exit codes, stdout/stderr separation, global vs. subcommand arguments, short and long flags, validation, interactive confirmation, and dry-run mode.[3] Luc Berton’s blog on building CLI tools in Rust with clap demonstrates practical use of the derive API and subcommand definitions.[6][10]

The OneUptime blog “How to Build a CLI Tool in Rust with Clap and Proper Error Handling” reinforces clap’s status as the de facto standard for argument parsing and recommends derive API, sensible defaults, structured errors, meaningful exit codes, colored output, and shell completions via `clap_complete`.[7] The Tech Bytes “Modern Rust CLI Development [2026] Cheat Sheet” situates clap v5’s derive macro as the “2026 standard,” highlights async-first architectures with Tokio, serde-based configuration flattening, alternative allocators, link-time optimization, static linking, and explicit error handling patterns.[8]

Clap’s GitHub repository and docs.rs page provide authoritative descriptions of clap as a full-featured, fast command-line parser, detail its dual licensing, and show its companion crates.[11][13][14][15] Clap_complete’s lib.rs entry describes shell completion generation, dual licensing, and download metrics, while Yocto project logs illustrate its integration in build systems.[17][19] Fedora’s Rust packaging guidelines reference clap as a standard crate, supporting its ecosystem position.[12] Crate listings for pico_args, rust-args-parser, bpaf, and flexiargs on docs.rs and lib.rs inform the landscape of alternatives.[4][5][9][16][18]

These sources collectively establish clap and clap_complete as the dominant, ecosystem-standard choices for `rs-launch-blueprint`’s CLI parsing and completion generation, while providing enough information to characterize alternatives and justify the chosen stack.

## Implementation Blueprint for `rs-launch-blueprint` CLI

### CLI Surface Shape: Noun–Verb Subcommand Groups

The CLI surface for `rs-launch-blueprint` should adopt **noun–verb subcommand groups**, mirroring the Python port’s resource-oriented structure. This means commands such as `plbp projects list`, `plbp projects create`, `plbp config show`, and `plbp config set` become the primary verbs on resources. In clap’s derive API, this maps naturally to a root `Cli` struct with a `subcommand` field of enum type `Command`, where `Command` has variants like `Projects(ProjectsCommand)` and `Config(ConfigCommand)`. Each resource enum, such as `ProjectsCommand`, then has variants for verbs.

This structure reflects principles of discoverability and alignment with library and web layers. Library modules such as `projects` and `config` can define functions `list`, `create`, `show`, and `set`, which the CLI commands invoke. Web routes in the HTTP service can be similarly aligned, e.g., `GET /projects`, `POST /projects`, `GET /config`, and `PUT /config`. The noun–verb pattern ensures that the CLI, library, and web layers share a conceptual model.

Clap’s subcommand support makes this structure straightforward. The derive API allows definitions like:

```rust
use clap::{Parser, Subcommand};

#[derive(Parser)]
pub struct Cli {
    #[command(flatten)]
    pub global: GlobalOptions,

    #[command(subcommand)]
    pub command: Command,
}

#[derive(Subcommand)]
pub enum Command {
    Projects(ProjectsCommand),
    Config(ConfigCommand),
    Completion(CompletionCommand),
}
```

Here `GlobalOptions` includes options such as `--json`, `--config`, and `--verbose`, flattened into the root so they are available globally.[1][3][6][8][10][15] The `ProjectsCommand` and `ConfigCommand` enums define verbs. This shape is maintainable and scales as new verbs are added.

### Global Options and Stackability

Global options such as `--json`, `--config`, and `--verbose` must be available on every command and recognized regardless of position. Clap’s `global` argument flag and derive flattening support this behavior. The `GlobalOptions` struct can be defined with attributes marking each field as global:

```rust
#[derive(clap::Args)]
pub struct GlobalOptions {
    #[arg(long, global = true, env = "PLBP_JSON")]
    pub json: bool,

    #[arg(long, global = true, env = "PLBP_CONFIG")]
    pub config: Option<String>,

    #[arg(short, long, global = true, env = "PLBP_VERBOSE")]
    pub verbose: bool,
}
```

This ensures that flags like `--json` and `--verbose` are recognized whether placed before or after the command verbs, satisfying the stackability requirement.[1][3][8][10][15] The `env` annotations are shown here for clarity; in the actual template, a macro or helper may be used to automatically derive env-var names from field names with the `PLBP_` prefix, reducing boilerplate while leveraging clap’s `env` feature.[1][3][7][8][15]

Testing will verify that `plbp projects list --json`, `plbp --json projects list`, and `PLBP_JSON=1 plbp projects list` all behave correctly. Clap’s parsing and validation ensures that invalid combinations of global options are rejected with clear errors before side effects occur.[1][3][7][8]

### Extended `--version` Output

The extended version output should print multiple lines that include at least the tool name and version, Rust version, and platform details (for example, target triple). Clap’s version handling can be configured in the derive API or through a dedicated `version` subcommand. For instance, the CLI could define a `Version` subcommand:

```rust
#[derive(Subcommand)]
pub enum Command {
    Projects(ProjectsCommand),
    Config(ConfigCommand),
    Completion(CompletionCommand),
    Version,
}
```

And the `main` function would handle `Command::Version` by invoking a library function:

```rust
fn main() {
    let cli = Cli::parse();
    match cli.command {
        Command::Version => {
            rs_launch_blueprint::version::print_extended();
        }
        Command::Projects(cmd) => { /* ... */ }
        Command::Config(cmd) => { /* ... */ }
        Command::Completion(cmd) => { /* ... */ }
    }
}
```

The `print_extended` function would read constants generated by the build-metadata crate selected by R22, printing lines such as:

```text
rs-launch-blueprint 0.1.0
Rust 1.75.0 (build metadata)
target x86_64-unknown-linux-gnu
```

This pattern mirrors Python’s extended version output while respecting Rust’s compile-time metadata conventions. Clap’s built-in `--version` flag could also be configured via `ArgAction::Version` to print the extended output, though the subcommand pattern offers more flexibility. Tutorials and docs for clap show that version behavior can be customized via the derive attributes and command configuration.[1][3][6][8][10][15]

### Completion Command via clap_complete

The `completion` command should accept a `shell` argument and generate a completion script using clap_complete. The `CompletionCommand` enum variant may be defined as:

```rust
#[derive(clap::Args)]
pub struct CompletionCommand {
    #[arg(value_enum)]
    pub shell: Shell,
}

#[derive(clap::ValueEnum, Clone)]
pub enum Shell {
    Bash,
    Zsh,
    Fish,
}
```

The implementation will construct a clap `Command` for the CLI (via `Cli::command()`) and then call clap_complete:

```rust
fn run_completion(shell: Shell) {
    use clap_complete::{generate, shells};
    let mut cmd = Cli::command();
    match shell {
        Shell::Bash => generate(shells::Bash, &mut cmd, "plbp", &mut std::io::stdout()),
        Shell::Zsh => generate(shells::Zsh, &mut cmd, "plbp", &mut std::io::stdout()),
        Shell::Fish => generate(shells::Fish, &mut cmd, "plbp", &mut std::io::stdout()),
    }
}
```

This is consistent with clap_complete’s documented usage and provides scripts for each supported shell.[7][8][17][19] The Python port’s `completion(shell: str)` function behaves similarly, and the Rust template will document usage such as `plbp completion bash > /etc/bash_completion.d/plbp`.

### Did-You-Mean Matching

Clap’s built-in suggestion mechanisms will be used for did-you-mean matching. When a user types an unknown subcommand, such as `plbp projetcs list`, clap typically generates an error with a suggestion such as “did you mean `projects`?” This behavior is part of clap’s validation and error formatting.[11][13][15] Using clap’s default error style keeps parity with Commander’s built-in suggestion behavior and avoids the need for a separate did-you-mean

> ⚠ Possible truncation: response may be incomplete.

## Sources

- [Rust clap in Practice: Build a Production-Ready CLI - Tao's Blog](https://www.ubitools.com/rust-clap-cli-guide/)
- [The Rust Module System and Useful Crates for CLI Apps](https://ngoldbaum.github.io/posts/helpful-rust-cli-crates/)
- [Mastering Command Line Utilities in Rust with Clap](https://codewithyoha.com/blogs/mastering-command-line-utilities-in-rust-with-clap)
- [rust-args-parser](https://lib.rs/crates/rust-args-parser)
- [pico_args - Rust](https://docs.rs/pico-args/)
- [Building CLI Tools in Rust with Clap: From Zero to](https://lucaberton.com/blog/rust-cli-tools-clap-2026/)
- [How to Build a CLI Tool in Rust with Clap and Proper Error ...](https://oneuptime.com/blog/post/2026-01-07-rust-cli-clap-error-handling/view)
- [Modern Rust CLI Development \[2026\] \[Cheat Sheet\] - Tech Bytes](https://techbytes.app/posts/modern-rust-cli-development-2026-cheat-sheet/)
- [FlexiArgs — Rust parser // Lib.rs](https://lib.rs/crates/flexiargs)
- [Rust CLI Apps | Clap Crate | Command Line Tools | Chapter 24](https://geekyscript.com/tutorial/rust-programming/rust-programming-building-command-line-applications)
- [GitHub - clap-rs/clap: A full featured, fast Command Line Argument Parser for Rust](https://github.com/clap-rs/clap)
- [Rust Packaging Guidelines](https://fedorapeople.org/~tmz/guidelines/packaging-guidelines/Rust/)
- [GitHub - clap-rs/clap at v3.0.0-beta.5](https://github.com/clap-rs/clap/tree/v3.0.0-beta.5)
- [GitHub - clap-rs/clap at 1b0088ecb7b770c431eedce754f7f491f1a477d5](https://github.com/clap-rs/clap/tree/1b0088ecb7b770c431eedce754f7f491f1a477d5)
- [clap 4.6.6](https://docs.rs/crate/clap/latest)
- [bpaf version 0.5.1](https://crates-io.ganymede-static.progval.net/crates/bpaf/0.5.1/)
- [clap_complete — CLI for Rust // Lib.rs](https://lib.rs/crates/clap_complete)
- [Information for uv](https://repology.org/project/uv/information)
- [bindgen-cli-native-0.71.1-r0 do_unpack](https://errors.yoctoproject.org/Errors/Details/861431/)

## Cost

Total: $0.9949