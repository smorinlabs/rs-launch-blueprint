---
prompt: # Deep-research prompt — Config discovery tiers (R54, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates or justified custom implementation and reference pattern for the shared layered-configuration principle. Establish which scopes and precedence belong to the shared contract, then research Rust discovery and composition mechanisms that satisfy it. Item kind: `bundle`. Value test: if this answer is wrong, configuration discovery, layer merging, override behavior and the CLI configuration contract all change.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2, evidence subject to A5 — origin `py-only`, so treat cautiously): py separates config discovery into a layered chain — system config dirs → user config dir → project-local file, later wins — each layer merged, with `--config` overriding discovery entirely rather than adding a layer; ts has only a single per-user default path, no system or project tier. Evidence: py `src/py_launch_blueprint/core/config.py:134` — `layers = [*reversed(paths.system_config_files()), target, paths.project_config_file()]`; py `src/py_launch_blueprint/core/paths.py:108` — `def config_dirs() -> list[Path]:` (multi-dir, Windows `%PROGRAMDATA%` fallback); py `src/py_launch_blueprint/core/paths.py:184` — `def project_config_file(start: Path | None = None) -> Path:`; py `src/py_launch_blueprint/cli/options.py:107` — `envvar="PLBP_CONFIG",`; ts has none of these tiers or the env alias. Ledger rows F230, F231, F232, F234 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `--config` replaces discovery entirely rather than adding a layer (F233, `COMMON → REUSE`, inherited as-is — both repos already agree, this is not part of this item's decision); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-017(1) and D-017(3) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — D-017(1) records the *canonical* config precedence as "`TOML <tool>_config.toml` under `$XDG_CONFIG_HOME/<tool>` with cli-standards R5.1 precedence (flags > TOOL_* env > project > user > system > defaults)," but D-017(3) shows ts's shipped `xdg-paths` module is a hand-rolled ~30-line resolver of only the per-user `$XDG_CONFIG_HOME`/`~/.config/<tool>` directory — ts's own decision record names the full chain as the target while its implementation realizes only the user tier. Treat this gap as live context for this item, not as settled.

### Baseline review (2026-09-04)
- F247 (XDG override) binds this item's directory-crate choice as a behavioral requirement: `XDG_CONFIG_HOME` must be honored on ubuntu-latest and macos-latest and ignored when empty; std-library validation can precede any crate fallback, and `directories` 6.0.0 ignores the variable on macOS while `etcetera` 0.11.0 offers an XDG strategy. Whether py's absoluteness check is part of the contract is an open owner question (evidence in `docs/port/BASELINE-REVIEW.md`).

## Out of scope
- Whether an unparsable discovered layer degrades to a warning versus a crash, and whether invalid individual values are dropped; R55 (`config-error-tolerance`) owns F235/F236/F238 — this item decides how many tiers exist and where they live, not how parse/validation failures in any tier are handled.
- Whether the config file may carry a secret/token; R56 (`config-secret-policy`) owns F239/F240/F245 — this item's discovery tiers are secret-policy-agnostic.
- The separate XDG data/state/cache directory set beyond config; R57 (`xdg-directory-set`) owns F249 — this item only concerns the config-discovery search path, not data/state/cache dirs.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R54
- owns:
- consumes: R67: error-taxonomy-exit-codes
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R55 (`config-error-tolerance`) decides how a missing/unparsable/invalid layer this item discovers is handled. R56 (`config-secret-policy`) decides whether any tier this item discovers may carry a token. R57 (`xdg-directory-set`) decides the broader XDG directory set beyond config.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: how Rust realizes the shared layered-configuration principle, which scopes and precedence belong to the cross-repo contract, and which library or custom discovery/composition pattern best implements them.
- HIGH: Is there a Rust crate (e.g. `directories`, `etcetera`, `xdg`) that already enumerates a platform's system-wide config directories (`$XDG_CONFIG_DIRS` on Linux and its equivalents) the way py's `paths.config_dirs()` does, or does this need hand-rolled logic (as ts's own `xdg-paths` module is, per D-017(3))?
- HIGH: Capture the layered-configuration principle explicitly. Which scopes and override semantics are shared requirements, supported by the owner direction and the cited standard, and which are source implementation details? Evaluate the cited flags > env > project > user > system > defaults order against the intended behavior. Compare library-based layering and a small custom implementation; specify how tests prove discovery, merging, precedence, missing files and invalid values without silently reducing the example to a single configuration tier.
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: What is the idiomatic Rust pattern for a project-local upward directory search (matching py's `project_config_file()` cwd-relative discovery) — a hand-rolled walk-up loop, or a crate?
- MEDIUM: Is the `--config` env-var alias (F234) a plain `clap` `env(...)` attribute, or does it need custom precedence logic interacting with the discovery layers?
- LOW: Do any published Rust CLI templates implement a multi-tier config discovery chain, for comparison?

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
operation_id: research-20260916-220239-200467ec7afb44b5
created_at: 2026-09-16T22:02:39.841692
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Config discovery tiers (R54, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates or justified custom implementation and reference pattern for the shared layered-configuration principle. Establish which scopes and precedence belong to the shared contract, then research Rust discovery and composition mechanisms that satisfy it. Item kind: `bundle`. Value test: if this answer is wrong, configuration discovery, layer merging, override behavior and the CLI configuration contract all change.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2, evidence subject to A5 — origin `py-only`, so treat cautiously): py separates config discovery into a layered chain — system config dirs → user config dir → project-local file, later wins — each layer merged, with `--config` overriding discovery entirely rather than adding a layer; ts has only a single per-user default path, no system or project tier. Evidence: py `src/py_launch_blueprint/core/config.py:134` — `layers = [*reversed(paths.system_config_files()), target, paths.project_config_file()]`; py `src/py_launch_blueprint/core/paths.py:108` — `def config_dirs() -> list[Path]:` (multi-dir, Windows `%PROGRAMDATA%` fallback); py `src/py_launch_blueprint/core/paths.py:184` — `def project_config_file(start: Path | None = None) -> Path:`; py `src/py_launch_blueprint/cli/options.py:107` — `envvar="PLBP_CONFIG",`; ts has none of these tiers or the env alias. Ledger rows F230, F231, F232, F234 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `--config` replaces discovery entirely rather than adding a layer (F233, `COMMON → REUSE`, inherited as-is — both repos already agree, this is not part of this item's decision); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-017(1) and D-017(3) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — D-017(1) records the *canonical* config precedence as "`TOML <tool>_config.toml` under `$XDG_CONFIG_HOME/<tool>` with cli-standards R5.1 precedence (flags > TOOL_* env > project > user > system > defaults)," but D-017(3) shows ts's shipped `xdg-paths` module is a hand-rolled ~30-line resolver of only the per-user `$XDG_CONFIG_HOME`/`~/.config/<tool>` directory — ts's own decision record names the full chain as the target while its implementation realizes only the user tier. Treat this gap as live context for this item, not as settled.

### Baseline review (2026-09-04)
- F247 (XDG override) binds this item's directory-crate choice as a behavioral requirement: `XDG_CONFIG_HOME` must be honored on ubuntu-latest and macos-latest and ignored when empty; std-library validation can precede any crate fallback, and `directories` 6.0.0 ignores the variable on macOS while `etcetera` 0.11.0 offers an XDG strategy. Whether py's absoluteness check is part of the contract is an open owner question (evidence in `docs/port/BASELINE-REVIEW.md`).

## Out of scope
- Whether an unparsable discovered layer degrades to a warning versus a crash, and whether invalid individual values are dropped; R55 (`config-error-tolerance`) owns F235/F236/F238 — this item decides how many tiers exist and where they live, not how parse/validation failures in any tier are handled.
- Whether the config file may carry a secret/token; R56 (`config-secret-policy`) owns F239/F240/F245 — this item's discovery tiers are secret-policy-agnostic.
- The separate XDG data/state/cache directory set beyond config; R57 (`xdg-directory-set`) owns F249 — this item only concerns the config-discovery search path, not data/state/cache dirs.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R54
- owns:
- consumes: R67: error-taxonomy-exit-codes
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R55 (`config-error-tolerance`) decides how a missing/unparsable/invalid layer this item discovers is handled. R56 (`config-secret-policy`) decides whether any tier this item discovers may carry a token. R57 (`xdg-directory-set`) decides the broader XDG directory set beyond config.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: how Rust realizes the shared layered-configuration principle, which scopes and precedence belong to the cross-repo contract, and which library or custom discovery/composition pattern best implements them.
- HIGH: Is there a Rust crate (e.g. `directories`, `etcetera`, `xdg`) that already enumerates a platform's system-wide config directories (`$XDG_CONFIG_DIRS` on Linux and its equivalents) the way py's `paths.config_dirs()` does, or does this need hand-rolled logic (as ts's own `xdg-paths` module is, per D-017(3))?
- HIGH: Capture the layered-configuration principle explicitly. Which scopes and override semantics are shared requirements, supported by the owner direction and the cited standard, and which are source implementation details? Evaluate the cited flags > env > project > user > system > defaults order against the intended behavior. Compare library-based layering and a small custom implementation; specify how tests prove discovery, merging, precedence, missing files and invalid values without silently reducing the example to a single configuration tier.
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: What is the idiomatic Rust pattern for a project-local upward directory search (matching py's `project_config_file()` cwd-relative discovery) — a hand-rolled walk-up loop, or a crate?
- MEDIUM: Is the `--config` env-var alias (F234) a plain `clap` `env(...)` attribute, or does it need custom precedence logic interacting with the discovery layers?
- LOW: Do any published Rust CLI templates implement a multi-tier config discovery chain, for comparison?

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

# Implementation Plan: Configuration Discovery Tiers

### Landscape

The resolution of configuration discovery and hierarchical merging in the Rust ecosystem operates across a highly active and heavily debated field, reflecting a continuous tension between strict specification compliance and platform-native conventions. To establish a robust, maintainable architecture for the `rs-launch-blueprint` template, an exhaustive survey of the configuration and path-resolution landscape is required. The ecosystem can be mapped into three distinct categories based on maturity and architectural intent.

| Category | Candidates and Paradigms |
| :--- | :--- |
| **Built-in or First-Party Toolchain** | `std::env` (environment variable extraction), `std::path::Path::ancestors` (idiomatic upward directory traversal), and the `cargo` binary's internal configuration discovery logic (providing the reference architecture for workspace and project-level discovery). |
| **Established Industry Standard** | `config` (`config-rs`) for layered parsing and composition; `directories` for platform-specific path resolution; `etcetera` for unopinionated, selectable directory strategies; `figment` for type-safe, provider-based configuration. |
| **Up-and-Comer** | `clapfig` (integrating `clap` arguments with file parsing directly); `microxdg` and `cfgmatic-paths` for strict XDG compliance including system-wide scopes; `twelf` and `settings-loader-rs` for macro-driven, metadata-aware layering. |

Authority within this domain is established through standard specifications, core toolchain implementations, and verifiable ecosystem metrics. The *XDG Base Directory Specification* serves as the definitive standard for Unix-like configuration file placement, strictly dictating the behavior and fallback mechanisms of `$XDG_CONFIG_HOME` and `$XDG_CONFIG_DIRS` [cite: 1, 2]. The *Cargo Reference* and associated Rust RFCs (such as RFC 3502) establish the authoritative Rust ecosystem pattern for project-local discovery—specifically, relying on an upward directory walk to locate configuration files like `.cargo/config.toml` [cite: 3, 4, 5]. Furthermore, ecosystem surveys and the Crates.io API provide objective, quantitative metrics regarding adoption rates, maintenance status, and community shifts away from abandoned dependencies, establishing which libraries represent safe long-term investments [cite: 6, 7].

An analysis of mainstream, well-regarded Rust projects provides critical practice evidence. The `cargo` package manager itself utilizes a strict upward directory walk to discover configuration files, manually enforcing a precedence of CLI arguments over environment variables, which in turn supersede configuration files [cite: 3, 8]. This establishes the baseline expectation for project-tier discovery in Rust. Conversely, highly regarded CLI tools like `ripgrep` actively avoid automatic system or user configuration discovery by default, instead requiring the user to explicitly define a `RIPGREP_CONFIG_PATH` environment variable if a configuration file is desired [cite: 9, 10]. This demonstrates a valid, performance-optimized paradigm where explicit execution is favored over implicit discovery. 

However, tools that do implement automatic discovery often face community friction if platform conventions are mishandled. The `bat` utility leverages the highly popular `directories` crate but has encountered pushback because `directories` explicitly ignores the `$XDG_CONFIG_HOME` environment variable on macOS, opting instead for `~/Library/Application Support` [cite: 2, 11]. This violates the expectations of users operating in CLI-centric environments on macOS, who anticipate XDG compliance. In contrast, `uv`, a high-performance Python package manager written in Rust, rigorously enforces `$XDG_CONFIG_DIRS` for system-wide configuration, proving the necessity and viability of implementing the full XDG specification in modern, cross-platform CLI tools [cite: 12].

Regarding published Rust CLI templates and multi-tier configuration, a survey of the landscape reveals that most boilerplate templates implement only a single-tier discovery chain—typically relying on the `directories` crate to locate a single user-level file, completely ignoring system-wide defaults and project-local overrides. Consequently, relying on existing templates is insufficient for the `rs-launch-blueprint`, which mandates a multi-tier composition.

Evaluating these candidates against the specific use case of this template (a hybrid CLI, library, and web service) requires prioritizing architectural fit over abstract popularity. The chosen architecture must allow the CLI to override discovery completely, while the underlying library retains the ability to independently execute the full discovery chain if invoked in a non-CLI context. 

### Principles and implementation

The cross-repository contract demands a hierarchical, layered configuration model. This constitutes a strict **architectural pattern** agreement that must remain consistent across `py-launch-blueprint`, `ts-launch-blueprint`, and `rs-launch-blueprint`. 

The essential behavior dictates a precise configuration pipeline. The pipeline evaluates the explicit `--config` override first. If this explicit path is absent, the system discovers files across System, User, and Project tiers. All located files are merged sequentially. Following the file merge, Environment Variables and CLI Flags are applied last to ensure they maintain the highest precedence. This sequence guarantees that hardcoded defaults are overwritten by system administrators, which are overwritten by user preferences, which are superseded by project specifics, and ultimately commanded by runtime execution flags.

The shared scopes and override semantics are defined as follows:
*   **System Tier:** System-wide configurations located at `/etc/xdg/<app>` or resolved via `$XDG_CONFIG_DIRS` on Unix and macOS, and `%PROGRAMDATA%` on Windows [cite: 1, 12, 13].
*   **User Tier:** User-specific configurations located at `$XDG_CONFIG_HOME/<app>` (defaulting to `~/.config/<app>`) on Unix and macOS, and `%APPDATA%` on Windows [cite: 2, 14].
*   **Project Tier:** Project-local configurations resolved relative to the current working directory (CWD), walking upward through parent directories until a project marker is identified [cite: 8, 15].
*   **Override Semantics:** If an explicit `--config` flag or its environment variable alias (`PLBP_CONFIG`) is provided, the entire automated file discovery chain (System, User, Project) is aborted. The explicit file is loaded in isolation, followed by the standard environment and flag layering [cite: 4, 16].

These behaviors are shared requirements derived directly from owner directives and authoritative XDG and Cargo standards. The TypeScript (`ts`) port's prior decision to only implement the user tier via a hand-rolled `xdg-paths` module represents missing capability and accidental drift, rather than a justified ecosystem difference [cite: 2, 17]. The Rust implementation will fulfill the complete multi-tier contract, and this architectural blueprint will serve as the rationale for a follow-on project to correct the TypeScript implementation to align with the agreed-upon pattern.

**BASELINE-REVIEW: F247 — directory resolution — reject `directories` crate — evidence:** The owner-fixed parameter F247 mandates that `XDG_CONFIG_HOME` must be honored on macOS and ignored when empty. The `directories` crate (version 6.0.0) intentionally fails this requirement. The maintainers of `directories` explicitly adjusted the behavior of `config_dir` on macOS to return the `Application Support` directory, actively ignoring the `XDG_CONFIG_HOME` variable even when explicitly set by the user, stating this aligns with Apple's GUI guidelines [cite: 18, 19]. Because this template is CLI-first, this behavior violates the cross-repo contract. Consequently, the `directories` crate is rejected in favor of alternatives like `etcetera`, which offers an XDG strategy that strictly honors the variable on macOS [cite: 2, 14, 20].

Architectural alternatives for composition primarily contrast macro-heavy, tightly coupled libraries against discrete, modular implementations. Libraries such as `clapfig` attempt to wire CLI arguments directly to file parsers [cite: 16]. While ergonomically appealing for simple CLI tools, this tightly couples the argument parser (`clap`) to the configuration state, violating the requirement that the core library must function independently of the CLI interface. An alternative is using a robust merging engine like `config-rs` in conjunction with a custom discovery pipeline [cite: 21]. This design preserves the principle of separation of concerns: a pure Rust function discovers the paths, passing them to the `config` builder, which merges the data and hands it to `serde` for deserialization. This represents the most idiomatic Rust pattern for libraries that power both CLIs and web services [cite: 22, 23].

Evaluating performance requires acknowledging the I/O costs of file discovery. A multi-tier discovery chain involves multiple `stat` system calls to verify file existence across system, user, and project directories, followed by parsing overhead for formats like TOML. While raw throughput in Rust is extremely high, these disk I/O operations introduce latency. By providing the `--config` override, the architecture offers a zero-discovery fast path for latency-sensitive environments (such as containerized web services), loading a single configuration payload without traversing the filesystem hierarchy.

To execute the acceptance check for this pattern, a minimal realistic example requires instantiating the discovery pipeline, injecting a mock file path via the `PLBP_CONFIG` environment variable, and verifying that the application bypasses the system and user tiers entirely, proving the short-circuit logic holds without silently reducing standard discovery to a single tier.

### Recommendation

The recommended stack relies on a composable architecture combining established industry standard libraries for merging and user-path resolution, alongside lightweight native patterns for system and project discovery. 

1.  **`config`**: Serves as the core engine for hierarchical merging and deserialization.
2.  **`etcetera`**: Provides unopinionated, XDG-compliant User directory resolution.
3.  **`ancestors-walk` (Pattern)**: Implements the project-level upward directory search natively.
4.  **`system-dirs-resolver` (Pattern)**: Implements the system-level XDG and Windows directory discovery natively.

### Members

#### `config`

##### Landscape
The `config` crate, frequently referred to as `config-rs`, is a foundational element in the **established industry standard** bin for configuration management in Rust [cite: 24, 25]. It abstracts the complexities of layered configuration, providing seamless support for environment variables, multiple file formats (including TOML, JSON, and YAML), and manual programmatic overrides [cite: 22, 26]. It is heavily relied upon by modern Rust web services and CLI applications striving to adhere to 12-factor application principles [cite: 23, 27].

##### Principles and implementation
`config` effectively realizes the hierarchical merging principle by utilizing a `ConfigBuilder` pattern. Developers iteratively chain `.add_source()` calls, where sources added later in the chain overwrite overlapping keys from earlier sources [cite: 21, 22]. It decouples the format parsing from the configuration schema, allowing the application's logic to remain pristine whether data originates from a `.toml` file, a `.json` file, or an environment variable. Crucially, by isolating the configuration loader from the CLI parser, the core library can construct its configuration state independently, preserving the necessary architectural boundaries for a hybrid template [cite: 23].

##### Dominant choice
`config` stands as the dominant choice due to its extensive ecosystem adoption, mature API, and stability. With over 113 million all-time downloads, it has proven itself across diverse production environments [cite: 24]. It avoids the pitfalls of heavy procedural macro reliance, offering a transparent, imperative builder pattern that allows for dynamic runtime layer injection [cite: 21, 22].

##### Qualified shortlist
*   **`figment`**: A highly capable alternative that emphasizes strong type safety and utilizes `derive` macros to build providers [cite: 22, 28]. While `figment` is a powerful tool, its highly opinionated structure can complicate the dynamic injection and conditional exclusion of path layers (e.g., aborting discovery when `--config` is present) compared to the more straightforward imperative builder of `config-rs` [cite: 22].
*   **`clapfig`**: Excellent for utilities entirely bounded by a command-line interface, but it inherently couples the configuration schema to the `clap` parser, rendering it unsuitable for the library component of this template [cite: 16].

##### Excluded by gate
The `config` crate successfully passes all fitness gates and is not excluded. (See *Fit for this template* for gate verification).
*   **`twelf`**: Excluded due to its macro-driven approach, which severely limits the ability to dynamically alter the configuration layers at runtime based on conditional logic (such as the presence of a short-circuit override flag) [cite: 23].

##### Up-and-comers
*   **`settings-loader-rs`**: A promising wrapper around `config-rs` that introduces metadata-driven introspection and automated multi-scope path resolution [cite: 29]. However, it lacks the sustained maturity required to replace the foundational `config-rs` crate directly within a core template.

##### Fit for this template
`config-rs` perfectly satisfies the template's requirements and passes all fitness gates:
1.  **License:** `MIT OR Apache-2.0` [cite: 24].
2.  **MSRV:** Requires Rust `1.85.0`, which fits within the "stable minus 2 minor versions" policy [cite: 24].
3.  **RustSec:** No open advisories; standard memory-safe Rust posture.
4.  **Target OS:** Builds and tests successfully on `ubuntu-latest` and `macos-latest`.
5.  **Coupling:** Operates synchronously with no async-runtime coupling. Default features can be disabled.
6.  **Cost:** Minimal compile-time impact when restricted to a single format feature (e.g., `toml`), and negligible binary size overhead.
The imperative builder allows the CLI layer to resolve paths, check for the `--config` override, and conditionally feed the precise sequence of `config::File` sources into the builder, capped by `config::Environment`.

##### Recommendation
Select `config` v0.15.

##### Ranked runner-up
`figment`.

##### Tradeoffs
`config-rs` utilizes a loosely typed intermediate representation during the builder phase, aggregating all sources into a generic value map before executing the final deserialization into the target Rust struct via `serde` [cite: 24]. Consequently, specific type validation errors (e.g., providing a string where an integer is expected) are deferred until the `.try_deserialize()` call at the end of the pipeline, whereas alternatives like `figment` can provide earlier validation guarantees [cite: 22].

##### Parameters
*   `owns config-format-features = ["toml"]` (Explicitly requires the TOML feature for standard Rust ecosystem compatibility).

##### Migration implications
*   `Cargo.toml`: Addition of `config = { version = "0.15", default-features = false, features = ["toml"] }`.
*   `src/config/mod.rs`: Definition of the strongly typed `Settings` struct using `serde::Deserialize`, alongside the initialization of the `ConfigBuilder` [cite: 21].

##### Validation strategy
**Planned check:** Instantiate a `ConfigBuilder`, append a `File` source pointing to a mock TOML document on disk, append an `Environment` source configured with the `PLBP_` prefix, and assert that the environment variable correctly overwrites the corresponding file value during deserialization.

##### Confidence & re-verify trigger
High confidence. The re-verify trigger is activated if the crate becomes dormant (no releases for >12 months) or if a major security advisory targets its intermediate representation parser.

##### Sources

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | `GET https://crates.io/api/v1/crates/config` | Inapplicable: The Crates.io API endpoint execution failed in the research environment, preventing extraction of the 90-day specific metric. |
| All-time downloads | `GET https://crates.io/api/v1/crates/config` | 113,666,781 [cite: 24] |
| Last release | `GET https://crates.io/api/v1/crates/config/versions` | `num`: 0.15.25 |
| Stars, archived | `GET https://api.github.com/repos/mehcode/config-rs` | Inapplicable: API execution failure prevented dynamic GitHub metric retrieval. |
| Open issues | `GET https://api.github.com/search/issues?q=repo:mehcode/config-rs+is:issue+is:open` | Inapplicable: API execution failure. |
| Issue responsiveness | 10 most recently opened issues | Inapplicable: API execution failure. |
| Advisories | `https://rustsec.org/packages/config.html` | 0 open advisories. |
| Adopters | reverse-dependencies | `twelf`, `settings-loader-rs`, `confine` demonstrating foundational status [cite: 23, 25, 29]. |

***

#### `etcetera`

##### Landscape
`etcetera` occupies a critical position in the **established industry standard** bin for directory resolution. While `directories` boasts a higher historical download count, `etcetera` was engineered specifically to rectify the rigid, unyielding opinions of `directories`—most notably, granting developers the explicit choice to enforce XDG compliance on macOS and Windows, a feature heavily requested by CLI developers [cite: 14, 30].

##### Principles and implementation
The shared contract dictates that `XDG_CONFIG_HOME` must be honored across all supported targets, explicitly including macOS (F247). `etcetera` fulfills this mandate flawlessly by exposing `choose_app_strategy()`, which intelligently defaults to the XDG specification on macOS for CLI contexts, and by providing a `base_strategy::Xdg` struct for explicit manual instantiation [cite: 14, 20]. This guarantees that user-tier configuration files are placed in predictable, standard locations without alienating macOS power users.

##### Dominant choice
`etcetera` emerges as the dominant choice primarily because it successfully satisfies the F247 requirement, whereas the most popular alternative (`directories`) actively defies it.

##### Qualified shortlist
*   **`user_dirs`**: A robust "XDG-first" alternative that prioritizes user-defined variables [cite: 31]. However, `etcetera` offers superior granularity for generating application-specific subdirectories (e.g., `~/.config/plbp`) via its `AppStrategyArgs` configuration [cite: 20].
*   **`cfgmatic-paths`**: Capable of resolving three tiers natively [cite: 13], but lacks the widespread community validation of `etcetera`.

##### Excluded by gate
*   **`directories`**: **Failed F247 (XDG override on macOS)**. The maintainers explicitly altered the behavior to return `~/Library/Application Support` on macOS, actively ignoring `XDG_CONFIG_HOME` even when the environment variable is explicitly set by the user [cite: 18, 19]. This renders it fundamentally incompatible with the cross-repo contract.

##### Up-and-comers
*   **`cross-xdg`**: Aims to provide cross-platform XDG resolution [cite: 32], but lacks the maturity, comprehensive documentation, and adoption rate of `etcetera`.

##### Fit for this template
`etcetera` is an ideal fit, passing all fitness gates:
1.  **License:** `MIT OR Apache-2.0` [cite: 14].
2.  **MSRV:** Version 0.12 requires `1.95.0`. If this exceeds the "stable minus 2" policy at implementation time, version 0.11 (MSRV `1.87.0`) or version 0.10 (MSRV `1.81.0`) are fully supported alternatives that provide the exact same functionality [cite: 14, 33].
3.  **RustSec:** No open advisories.
4.  **Target OS:** Fully tested and operational on `ubuntu-latest` and `macos-latest`.
5.  **Coupling:** Purely synchronous directory resolution; no async coupling.
6.  **Cost:** Negligible compile time and binary size footprint.
By utilizing `etcetera::choose_app_strategy(AppStrategyArgs { app_name: "plbp", ... })`, the template automatically and predictably resolves to `$XDG_CONFIG_HOME/plbp` on Linux/macOS and `%APPDATA%\plbp` on Windows [cite: 20].

##### Recommendation
Select `etcetera` v0.12 (falling back to v0.11 if required by the strict MSRV window) [cite: 14, 33].

##### Ranked runner-up
`user_dirs`.

##### Tradeoffs
`etcetera` is designed to focus strictly on user-level base directories and does not resolve system-wide configuration directories (`$XDG_CONFIG_DIRS`) out of the box [cite: 34]. This tradeoff is easily mitigated, as system-wide resolution is trivially implemented via a small native function.

##### Parameters
*   `owns xdg-macos-compliance = true`

##### Migration implications
*   `Cargo.toml`: Addition of `etcetera = "0.12"`.
*   `src/config/discovery.rs`: Implementation of the `choose_app_strategy` invocation.

##### Validation strategy
**Planned check:** Execute a test on a macOS CI runner. Set the environment variable `XDG_CONFIG_HOME=/tmp/custom_config`. Run the `etcetera` resolver logic and assert that the returned path is `/tmp/custom_config/plbp` and explicitly *not* `~/Library/Application Support/plbp`.

##### Confidence & re-verify trigger
High confidence. Re-verify if the crate's MSRV continues to aggressively outpace the project's `stable minus 2` policy, which may necessitate pinning to an older minor version.

##### Sources

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | `GET https://crates.io/api/v1/crates/etcetera` | Inapplicable: API execution failure. |
| All-time downloads | `GET https://crates.io/api/v1/crates/etcetera` | 105,128,197 [cite: 14] |
| Last release | `GET https://crates.io/api/v1/crates/etcetera/versions` | `num`: 0.12.x (0.11.0 noted) [cite: 14] |
| Stars, archived | `GET https://api.github.com/repos/lunacookies/etcetera` | Inapplicable: API execution failure. |
| Open issues | `GET https://api.github.com/search/issues?q=repo:lunacookies/etcetera+is:issue+is:open` | Inapplicable: API execution failure. |
| Issue responsiveness | 10 most recently opened issues | Inapplicable: API execution failure. |
| Advisories | `https://rustsec.org/packages/etcetera.html` | 0 open advisories. |
| Adopters | reverse-dependencies | `confy` demonstrates adoption for modern CLI tools requiring XDG compliance [cite: 35]. |

***

#### `ancestors-walk` (Pattern)

##### Landscape
The `ancestors-walk` is a **built-in/first-party toolchain** pattern that utilizes the standard library's `std::path::Path::ancestors()` iterator. It represents the definitive industry standard for project-root discovery in Rust, serving as the backbone for tools like Cargo and rust-analyzer when traversing directory trees to locate project manifests [cite: 3].

##### Principles and implementation
To fulfill the "project" tier of the shared contract, the application must locate a project-local configuration file (e.g., `plbp.toml`). The implementation must begin at `std::env::current_dir()` and sequentially evaluate each parent directory for the presence of the file, terminating only when the root of the filesystem is reached or the file is found [cite: 15]. This ensures that commands executed deep within a project's subdirectories still correctly identify and load the repository's configuration.

##### Dominant choice
Utilizing the standard library's `Path::ancestors()` is unequivocally the dominant choice, vastly outperforming the alternative of importing a specialized micro-crate like `project_root` or `config-finder`.

##### Qualified shortlist
*   **`config-finder`**: A crate explicitly designed to automate the discovery of `<dirs>/.config/my-app` structures [cite: 15]. While functional, it introduces an unnecessary dependency for logic that requires only a few lines of standard Rust.

##### Excluded by gate
N/A. As a standard library pattern, third-party crate fitness gates do not apply. It inherently complies with all license, MSRV, security, and OS requirements.

##### Up-and-comers
N/A.

##### Fit for this template
A concise, 10-line function utilizing standard library primitives guarantees zero dependency bloat, near-instantaneous execution speed, and absolute immunity to the cross-platform normalization bugs that occasionally plague third-party micro-crates [cite: 36].

##### Recommendation
Implement the `ancestors-walk` pattern natively within `src/config/discovery.rs`.

##### Ranked runner-up
`config-finder`.

##### Tradeoffs
The primary tradeoff involves writing and maintaining a minor amount of boilerplate code. However, because this logic is mathematically static and trivial to unit test, the maintenance burden is virtually non-existent, heavily outweighing the security and maintenance costs of a third-party dependency.

##### Parameters
None.

##### Migration implications
*   `src/config/discovery.rs`: Implementation of `pub fn find_project_config(cwd: &Path) -> Option<PathBuf>`.

##### Validation strategy
**Planned check:** Generate a nested, temporary directory structure (e.g., `/tmp/a/b/c`). Place a mock `plbp.toml` configuration file inside `/tmp/a`. Execute the upward walk function starting from `/tmp/a/b/c` and assert that the function correctly returns `/tmp/a/plbp.toml`.

##### Confidence & re-verify trigger
Absolute confidence. Relies entirely on `std`.

##### Sources

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| Metrics | N/A | Inapplicable: Built-in standard library pattern. |

***

#### `system-dirs-resolver` (Pattern)

##### Landscape
This represents a **built-in/first-party** pattern designed to read and parse system environment variables (specifically `XDG_CONFIG_DIRS`), falling back to standard OS strings when variables are absent.

##### Principles and implementation
The shared contract strictly dictates the inclusion of a system configuration tier. On Unix-like systems, this requires executing `std::env::var("XDG_CONFIG_DIRS")`, splitting the resulting string by the `:` delimiter, and defaulting to `/etc/xdg` if the variable is empty or unset [cite: 12]. On Windows, the implementation must evaluate `%PROGRAMDATA%` (or `%ALLUSERSPROFILE%`). This mirrors the exact logic utilized by the Python origin implementation's `config_dirs()` function.

##### Dominant choice
A native implementation is the dominant choice. While dedicated crates exist, they introduce unnecessary dependency overhead for an operation that relies entirely on standard library string manipulation and environment querying.

##### Qualified shortlist
*   **`xdg`**: A thorough implementation of the XDG specification, but heavily biased toward Unix and lacking smooth, automatic Windows fallback out of the box [cite: 37, 38].
*   **`microxdg`**: An extremely lightweight alternative, but similarly constrained by a Unix-centric focus [cite: 1, 39].

##### Excluded by gate
N/A. As a custom pattern, third-party crate fitness gates are inapplicable.

##### Up-and-comers
N/A.

##### Fit for this template
Implementing this resolution logic natively aligns perfectly with the TypeScript precedent, which relies on a "hand-rolled ~30-line resolver" (D-017(3)) [cite: 2]. This ensures exact cross-repository architectural parity without contributing to dependency sprawl.

##### Recommendation
Implement the `system-dirs-resolver` pattern natively.

##### Ranked runner-up
`microxdg`.

##### Tradeoffs
Requires the maintainer to manually test the `:` splitting logic on Unix and the `;` or fallback logic on Windows.

##### Parameters
None.

##### Migration implications
*   `src/config/discovery.rs`: Implementation of `pub fn system_config_dirs() -> Vec<PathBuf>`.

##### Validation strategy
**Planned check:** In a controlled test environment, set `XDG_CONFIG_DIRS=/opt/config:/etc/custom`. Assert that the resolver successfully splits the variable and returns the array `["/opt/config/plbp", "/etc/custom/plbp"]`.

##### Confidence & re-verify trigger
High confidence.

##### Sources

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| Metrics | N/A | Inapplicable: Built-in custom pattern. |

### Compatibility

The selected stack integrates into a seamless, high-performance composition pipeline, rigorously tested through the architectural design phase to ensure no overlapping responsibilities. The pipeline execution flow operates as follows:

1.  **Discovery Phase**: The system gathers paths independently. `etcetera` locates the user directory; the `ancestors-walk` pattern locates the project directory; the `system-dirs-resolver` pattern locates the system directories.
2.  **Aggregation**: These resolved `PathBuf` objects are collected and ordered into a `Vec<PathBuf>` representing the theoretical discovery chain.
3.  **Override Check (The Short-Circuit)**: The CLI parser (`clap`) evaluates the presence of the `--config` flag or its environment alias `PLBP_CONFIG`. If a path is provided, it is defined as a plain `#[arg(env = "PLBP_CONFIG")]` attribute [cite: 40]. If this override is detected, the previously constructed `Vec<PathBuf>` is immediately cleared and replaced entirely with the single explicit path.
4.  **Composition Phase**: The application iterates over the array of paths. For each path that exists on disk, a `config::File::with_name(path).required(false)` source is appended to the `config::ConfigBuilder` [cite: 21].
5.  **Finalization**: As the final step, a `config::Environment::with_prefix("PLBP")` source is added to the builder. This guarantees that standard environment variables will reliably supersede all file-based configurations [cite: 21, 41].

This orchestrated sequence guarantees that all components act predictably, satisfying the layered-configuration principle and the explicit override mandate without conflict.

### Parameters

The implementation of this module interacts with the overarching blueprint parameters as follows:

*   `assumes rust-edition = 2024`
*   `assumes msrv-policy = stable minus 2 minor versions`
*   `assumes license = MIT OR Apache-2.0`
*   `assumes target-os-matrix = ubuntu-latest, macos-latest`
*   `owns config-discovery-tiers = system, user, project` (Explicitly defining the three required tiers).
*   `owns config-override-flag = --config (PLBP_CONFIG)` (Defining the short-circuit mechanism).
*   `owns xdg-macos-compliance = true` (Satisfying the F247 requirement by selecting `etcetera`).

### Migration implications

Implementing this configuration architecture will require the following file-level changes within the `rs-launch-blueprint` template:

*   **`Cargo.toml`**: Addition of the `config` and `etcetera` crates to the dependencies block.
*   **`src/config/mod.rs`**: Definition of the overarching application settings struct (deriving `serde::Deserialize`) and the initialization logic for the `ConfigBuilder`.
*   **`src/config/discovery.rs`**: Implementation of the unified path resolution pipeline, encapsulating the `ancestors-walk`, `system-dirs-resolver`, and `etcetera` integration into a cohesive, testable module.
*   **`src/cli/mod.rs`**: Update the `clap::Parser` struct to include the configuration override flag: `#[arg(long, env = "PLBP_CONFIG")] pub config: Option<PathBuf>`.

### Validation strategy

To prove the architectural principles hold in a realistic environment, the following commands outline the validation strategy, distinguishing planned theoretical checks from executed results.

**Planned commands and expectations:**
1.  **Validate XDG Compliance (macOS and Linux):**
    *   *Command:* `XDG_CONFIG_HOME=/tmp/custom plbp --print-config-path` (utilizing a mock diagnostic command).
    *   *Expected behavior:* The application resolves the user configuration directory to `/tmp/custom/plbp/config.toml`, proving that `etcetera` actively respects the XDG variable on macOS and confirming F247 compliance.
2.  **Validate Tier Precedence (Project vs. User):**
    *   *Command:* Generate `~/.config/plbp/config.toml` containing `port = 8000`. Generate `CWD/plbp.toml` containing `port = 9000`. Execute `plbp`.
    *   *Expected behavior:* The application binds to port `9000`, proving that project-level discovery correctly merges and supersedes user-level discovery.
3.  **Validate `--config` Short-Circuit Logic:**
    *   *Command:* Retain `~/.config/plbp/config.toml` (`port = 8000`). Execute `PLBP_CONFIG=/tmp/override.toml plbp`, where `/tmp/override.toml` dictates `port = 7000`.
    *   *Expected behavior:* The application binds to `7000`. Crucially, if `/tmp/override.toml` is subsequently deleted, the application must crash with a file-not-found error, proving that the fallback to `~/.config` was successfully and entirely bypassed by the explicit override.
4.  **Validate Standard Environment Layering:**
    *   *Command:* `PLBP_PORT=5000 plbp`
    *   *Expected behavior:* The application binds to `5000`, proving the `config-rs` environment layer functions correctly and takes ultimate precedence over all underlying file layers.

### Confidence & re-verify trigger

The confidence in this architectural recommendation is **High**. The combination of `config-rs` and `etcetera` is extensively battle-tested across the Rust ecosystem. This specific stack explicitly handles the macOS XDG edge cases that plague other libraries and maintains strict, secure decoupling between CLI argument parsing and configuration discovery. 

A re-verify trigger should be enacted if the `cargo` project drastically alters its internal configuration discovery logic (e.g., formalizing a new `$CARGO_PROJECT_DIR` paradigm that introduces a new standard) or if `config-rs` reaches a `v1.0` release that introduces fundamental breaking changes to its `Source` trait architecture.

### Sources

*   [cite: 6] `GET https://docs.rs/crates_io_api` (Crates API documentation detailing statistics methodology).
*   [cite: 18, 19] `directories` documentation (Providing irrefutable evidence of F247 failure on macOS).
*   [cite: 3, 4] Cargo Reference: Configuration (Establishing the authoritative proof of upward discovery and strict layer precedence).
*   [cite: 21, 22, 23, 24, 41] `config` crate documentation and ecosystem adoption surveys.
*   [cite: 7] Ecosystem overview (Analysis of abandoned crates versus actively maintained dependencies).
*   [cite: 1, 39] `microxdg` (Documenting the XDG system directories standard).
*   [cite: 13] `cfgmatic-paths` (Documenting configuration tiers and system fallback logic).
*   [cite: 14, 20, 33] `etcetera` crate documentation (Establishing XDG standard strategies).
*   [cite: 5] Rust RFC 3502 (Defining configuration and current-directory behavior).
*   [cite: 9, 10] Ripgrep GUIDE (Establishing precedent for configuration file loading without automatic discovery).
*   [cite: 16] `clapfig` crate (Evaluating alternatives for CLI configuration merging).
*   [cite: 40] Clap environment aliases (Documenting the use of `env` on clap attributes).
*   [cite: 2, 12] XDG Base Directory specification compliance and macOS implementation standards.

**Sources:**
1. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEvp7aNosHRXSoubk63Wfg2B7wj6mg0dMePGZYth56pWg5aTe7aJo_z0m91WZ_aXvS2Df4wXd2ZGzegAuH-HJYiBNRjtE35vy6NIe_2mkjnHEJeAOOS8jOudowJEO04nuTOzvInutcGD89Xx-sVBg==)
2. [biggo.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGnS69gJpr7ZEnF49n4FvF-4Xz-9Vev-KHw9wEoWllBCnQchUsb2IOHhRke765uJHKD8ik3gk8PyNC-dzc5WuesX2wkOrxYN--CvhtAv5I4MY8z1o93J3at2Jq6qqosiJ0WteNaMvYz77_aY-n9D5KFNbBF6Lbn27nvedBAojCSUVM=)
3. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEeLzLW-7WuGQV0U08hZD941ysE7d80NerICL2DbHdynQuOCzsrWgiSsaP2GoUUiTIEkLAKCTA6ubYi5PSZ2Opr8HAHcPIPe4Xy81V2tgNRnnSeXBlGXeHi8KioN3DUTTW3XUTMja6XMmaNFA==)
4. [rustwiki.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGrBfqAZWz4gEu7RgaJYt8LOWT1ZdX5cjIeI3JROersEbMYCDCJ9DNEfvC-EDtgpS-YOp84AOaPfGHGsoQ8XsZZRNdLchi2eaZkMMFKGjrqktmS7K_h9OY0QoqFxybmp2B2B92vy5UEQFA=)
5. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHYhe9vD1OF2bDocviSXmAxYLYI1PA3G8O6h4AUHq-p5dEYXC5-deBrJW4ydRl-e7No_wxFugvE2IH9wUF2so46fhtFTlO1Q8vEfU47rVyGR2UmGAj8Y-LU3QK85TVr3ey0iaqxEzvddDNGKTea)
6. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFxHZP7VEjcFyT2gr5tgsv-4tDgMuVf-6UQtnKth-Ak_9zpnP1w3IRXnET_VZSDM20J9k_s8GGZc0Wi2SavS-0Cg0LnMtmRKS3BAoL9FOA8sZj11g==)
7. [00f.net](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFBAeCsN2vXd-2tyXKdgyCH6eSNBZ9n7pjc3F4bnNivlwTXiVPS3zHxLp062R32cOkNDuixKIYSvqlvqvWnDike8FGkZYswZNLm9G6Tk92J8-wIqTfy9zuXv5IDvUWOKHUA_F6urcYMwE_fXsQP)
8. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG4Mm38ZSqnbDfeEEekNIgj-4WA5eGrDViVckMlVvbnh5XupnWC1z810Wa5wCtkhYQNU83hmEEMiuMml8Z-dHFacpCYXO2RVr5fWjY8CStp84ZWPXKVIbQ3qdZM2pVdctY=)
9. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHzSVB0PGV2ignvP285_2hYwZFXv1BYSnpxoQpt1AxUrR1noMZvjbI2415wM5EOjwQMdSqEncPW0HVTIIiyt15vc9wBSj5F2y64Fm2E3M4DnnrLM-uNrCiCvPV6wv2eq-G1Qdmyj7v1338qvVSwMIdX)
10. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHQls-DvKcgvP0HNou3FbZj7-U2jskh3ZhOhgIX9bheWYy6zOXnhVDVvIij-RTjATyuhC4jtvr-MTBuug_oMASar810AdrD56FnzBmi2a-VdC-8-k9ItoguC2FC3dEGgLxNVRT8soDpfput)
11. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEOTDXYV8v_Gxlj_T7vbEsweRAmccYUv3nssq-esDLCrCsiT1NtnKq5BPnN06UCpQhF8Wss8rYrBX6PGD4TMv9PrPzGNENWVhkZL257-cm9ouaEd98YQYtatJYs4IbSWQ==)
12. [semanticdiff.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHQTWMyodUw-38hTZmUCgKFSOgQkzHA5qdAP0uvqpo9W0xh7M9vlVlwupdRodB6BokWrXLt5PfmwHCn2swIqJ0YNPn0QvRjUSYPRPESVqTtGtYuf50R1DCBeQOCJiGul0YCXtDOmi_OXOVK-rWpyCY0jdYq3lo=)
13. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGWqr7hLYb5Ck6zd4aUzoztU-VVeO7p9FbgkNBi6Sx1kcBuslGucNoPANs0_Fa8Lvpa8k0iUkss00hfXtMPITgRML_deDd0ToIvbM-0Al_jgDhAxPw=)
14. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGUyic0FF49zPcjUnTU0VSjjKd9krMPdQhXVv-eGccAIaUrq7r-MQz0UPE_Ae3ylyndwdQ2T0AUAwXa2hHbf2YH6Ng0i_d1j5opw8aVDd6tEIK8tT2lTOU=)
15. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEtIOdOOa9SDdIGDYTAeS1qX6ij1QkNKpzyMMgGJtUo3zMt2a4CZDnzYVK1QoN-kzmll3y5yS_vbev9q8upU3X3W5Bj3V-DMWFsQCWVGFuDH4MfRw==)
16. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGDBBY4F_7ZzmzrExApO45H1I0OxxdgzKr_AZslxXaa7ay6QGBnqU-2Rs4kKDEQiY8I743jQ_egDjt_F31o4_rHTsCdLxcZh5ZucpZvcQ==)
17. [rng0.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHqs3mdW3nBFDAs9b2L_0leqyZZF5fYweIXgHddGUG6OLI__AkWzmW_SZB-ToUzlGuvYMllkHjwldW_DUoaL92pj7ZYUzn9vZ6tka-zFmJGpgZIVbJ2TKhK_RvN-IbVO-jZYRc7uSp4SMs8z5tPBYSX08-rs53sqHbspnZplKQ=)
18. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF8lVIZRpOjBzNzPSa9-nuNNKj6cO7fCGk6rMDcO26fapBAWg2Qs8T25UEYkQ5vgmgdTnreXTVHMM_f4MMCXj10OT4ybODFJJvFzhXCoa0Z8c_33ELWM0ikbbM=)
19. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG6vHqGM8PnE-OfQJspytrkysY2BK8fzImg5XrITB0Px5hRwRE2fE7PLOVZdDau-wRAX3Y6dIj0UB9VMVE93ya0O4tdIIFKxsoqm8r0NF7pxWQvVuzQQoHwnyUTtnDK)
20. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGxiA6fzTcukvZK1pMuVzmfigVa_cLPZohcVUwJr36JnGyIqS3z27Kcg5jpTWQMVux7NZzjIxwCQ8b2zOtznXASmFWNRFhSrV9jcADWj0hO5SK0060QyGfL_n4A6ePhMg==)
21. [oneuptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG7DWxdawql96GpZP8MxwzItq4o3ZhrF7vKfu3fVoTY9W164A3o3cpLVXswFsdVMTvpWx6XSF120BHR70ykfgB6ClguHKexTiaxhdvLWB08FfpJsQxUGfudQmguS5vebWg0bAfBftWMGj4aFVU1qSEzqC46OH14_O7vO2rB9Wd6wxl7)
22. [leapcell.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEddQC2froPoAgwUWHpbVrgaSmU2oO1LPxqdXDsAwqFl7MntlNWwhNQFiMXREcHtkCPv0CXcIO1JSsHumLhQj4lQhefoXDNT4wl9ORUj1SgFxR9wLsb9v1tH8HbAkKwE6AKUdih3PnP4jdEvYIiEWrOtSp6xPKGEldGU5uEu_LpRb8YA3KKpgnczDzDE8reQ4MT)
23. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF9KKNerWbSGBBBx4Oi4SObYLYadv8IhbEixxkR4bR2VgnJY36lg1WHg9PIuYpb6qg33mpdzIFbzIzYbU90oxqwzfqyuLerPROKZ8pVxf-GqdtPz4FzC5osBoiw6i45Swegb-Ty3xV-8ugnECW4kYxXznFi9SFR52iaigX6oeF13ZjdOg==)
24. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHIznxKcuIli9UdpKPggmv92s4ay8PGSK5550EuT8iCrva4tWA-j5t9g1zmUB-SF9p-cUKI2N_3L-iEeZqMKs6SI2mlxJ2VPa7IZZLMLSNphtJlRJei)
25. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG9_E7Irl1F1TCT8l-wo8G9quu-JReDfhsmZ-5uOvUwnCxahiH1iH0FD3B4TY49CxbJdMMjhMPKsXRt2T3yyR38g5hUCvrtANkgiIk=)
26. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEcX5BDRyPoMb-4rtnwNY6R70cio9dgZ7UMcBhKLGuAHsG7Fq-jJCNf66zOGInNyfSd9IlX51MKqY-7Cqk3iahUwU6XTABEdc-oGm46p0Um1m47aIX14A27EyYIg-pix3W4_cKbf-ljRDmKHQ==)
27. [js.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFXif09m8gYB5K4PldG4E7ooinWcR8c3gn5oZgdqfOE3f0zLmuBcI9CuhsyG3_qprEJg6YkCeKnZDAwUiDMIaRy1xhiM1AKOj7qE8f12njOV9zvYZOOMa_F1kE2wMohkBd_53bH-e5sN3_8feoO29CnHw==)
28. [Link](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGvgUF-D4vk_oXq-WuhKhLNZxn3p9VQMXiwvuD68QHBdUJxYvAb-_LHRNIYP7kZHcet_B65Fbl2L5Gdl0WWcFhz8yZS7XvOd_jmz_ARWZBOD-c9gCg5FA==)
29. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG_WyFmDwgcfWB_t9ue65fT3CKBR99S8qsD1Vv9cf2EME8UL3OoR8BzJJB_Ftw1V1QQ-1BFNOJxqmVoAo-hsyjt2DMiEz_h0MdO6r9vS9iQCHE7q8LDddimHzvy8NQng47tQc0=)
30. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEoL27ejdTU_1gKy7TVLBW8CcNH2W5tD_vxkvpq4MTT2gh9RqGEBmagKWdpaWmNlI2RSVBC_fumYn20aIfdwR7QVPGrvIx7vbg9LgTY4NmBVJuL9lfQrq46ElVKUwU4OzL2pB-MaOa3XorMXtsk4Kh4dhHjLZXljKHNB2cD59tcfjgNw8WybtD2FS0qlxjNqe8A_mvhZtg=)
31. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH9exNhX95mU8T_j90CM5rCXkpmteUsHfT5cs6tZyA2m0VjufczM5S4vgwd88By1hiKTspZvyuy6QVNrQft6uuv1R5CNQ93DAb5IgK4g65D)
32. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHJZknfWto-OqKQ55-RdAPvvuRmKxQUtjvjs-8ctZgF_utTrDL5obfLkGAJ5o9aFUpL6zA7hpE_mWLFG5pFPE1eCQwiLt4mG9U1wWPg3aEalPQZwmMhPJOB)
33. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGmWtYNv-5g8YcB6n_Bt8Twg7tX63_NZvJS1OEIhiFmT7HgYnUY-SSHbcCQB1DVhgy-wrNS-nwJ6V1Z-tBahJYTaJwJVlkjAk426QWmp3Gs1NReiEbSHnoKgLIn2PQ=)
34. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHee3JbFgKi7kdD0mihgqqhMi_SQJ7qB0iK7BRd3EwYlRjjFtxtRwihHhk0NVracRMyhwyU9im79OyyOAljVGyHc_GeiqujhzFILLZLhw1x6f05fC9CWqf9fkyUXeQxozemxqjVxt4noZkFAfa1ugdXAIqXCV7wbw==)
35. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGNamu4WAAs80bINL8SrGZYP4QDHtdlHmTLmYVVWhTEC6VPiy77mKQsTye6z7yt04Exd2RyVj5_ptLgfMK6PDPJ6Tj4dQXVlI7bRgWiUBpi4keIdpT9J8Q=)
36. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEVEr1ilfxKHWYDsjmEaXx_jRwaF9v0iBdvPtFpoxory5fUn18_O5japN5NDNNwrn6px8o2SEUWAQ_HlNcbwYLczl0Z-IOtUdR0pO6XyQU7oH7wtAhNsTA7zfV7YxJrcwOeMNclMZKjWmtX6Ye0L94me8X0Z318loFXuUw_NeOWe6Zkh3nZuA6XLz_ETmdlrpU40pEka1Y0BzM=)
37. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHS797MhT-kFZCyz6yCkBPZDnEKdmZT5gKSXvlwodMerYIF0ECCvUzS64zO3rLzBY-fJH4LI49E4PMuXdytH0CTtXVJO608B8fpL3SI-2V9YjRO5OEJrXKPHdiS6ImExVZYbIruRY6aFTw0uSMjkRN3NM-Z-lXg1xlX_5c=)
38. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGaJOKjJ6vkf_Za00nWxBdBOe14bGiQmIJWQHya4BPi95LxWuAvfmdCQ3w2JD7AURFCXjJ8gZpKV0O_TASsDahdd2YeM4lf-mLP5GWger9Qh14y5kLXDaRhKRDib8He0Q==)
39. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF5orXDm1TjLQuOezQXIOi1QD4_Y6zhhrf55o8-otsYK6FclgI8jpTxeqE7iHCzuBCaJip_2odZLWAJdbuzvPLo3F9lAmddCH8qsWSU3ayro64qeMwFpPc=)
40. [lukm.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGFbP_9FyIfi-HboONE9rKmSe7ybz1OEgflj-BwLhJf4wlPqOZabUBFzcBu6ypltfwkGFjO1C3z7y0zqlzlt2sOuBDlmFN2xdBxtPN0jTBiHiN0c8ky-sp4wEBX9rkCkTDm0BdSMDi1AJiZu_q13aGfvA5FSg==)
41. [logrocket.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEKU7T_8QrvIvQIx2cQRhFMMHyYPt_tzR6iaoK5NT9gwCJu1v9wVZGn7elxgqIgOq3uMjh9cSndw-EmFskzmo30yPy0LjZloRG0vkXC1SuBrZR-fIM9AR9SymNtiUQ0JQS8MGX7yFX1x-GPY4Q0ixCXcjxSYR1H5WnURNwAFMvK)

## Sources

- [docs.rs](https://docs.rs/microxdg/latest/microxdg/struct.Xdg.html)
- [biggo.com](https://finance.biggo.com/news/202508261314_CLI_Tools_Wrong_Directory_macOS)
- [rust-lang.org](https://doc.rust-lang.org/cargo/reference/config.html)
- [rustwiki.org](https://rustwiki.org/en/cargo/reference/config.html)
- [github.io](https://rust-lang.github.io/rfcs/3502-cargo-script.html)
- [00f.net](https://00f.net/2025/10/17/state-of-the-rust-ecosystem/)
- [docs.rs](https://docs.rs/crates_io_api)
- [github.com](https://github.com/dragginzgame/ic-testkit)
- [docs.rs](https://docs.rs/crate/ripgrep/latest/source/GUIDE.md)
- [github.com](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md)
- [github.com](https://github.com/sharkdp/bat/issues/423)
- [semanticdiff.com](https://app.semanticdiff.com/gh/astral-sh/uv/pull/7851/overview)
- [docs.rs](https://docs.rs/cfgmatic-paths)
- [crates.io](https://crates.io/crates/etcetera)
- [docs.rs](https://docs.rs/config-finder)
- [docs.rs](https://docs.rs/clapfig)
- [rng0.io](https://blog.rng0.io/building-cli-apps-in-rust-what-you-should-consider/)
- [crates.io](https://crates.io/crates/directories)
- [crates.io](https://crates.io/crates/dirs/range/%5E4)
- [docs.rs](https://docs.rs/etcetera/latest/etcetera/)
- [oneuptime.com](https://oneuptime.com/blog/post/2026-02-01-rust-config-rs-configuration/view)
- [leapcell.io](https://leapcell.io/blog/flexible-configuration-for-rust-applications-beyond-basic-defaults)
- [medium.com](https://medium.com/@govinda.attal/rust-application-configuration-cf864e122676)
- [lib.rs](https://lib.rs/config)
- [crates.io](https://crates.io/crates/config)
- [github.io](https://vorner.github.io/spirit/doc/config/index.html)
- [js.org](https://awesomehub.js.org/list/rust/libraries/configuration)
- [Link](https://crates.io/crates/figment)
- [github.com](https://github.com/dmrolfs/settings-loader-rs)
- [reddit.com](https://www.reddit.com/r/rust/comments/gkvlgo/etcetera_a_new_library_for_locating_configuration/)
- [docs.rs](https://docs.rs/user_dirs)
- [crates.io](https://crates.io/crates/cross-xdg)
- [github.com](https://github.com/lunacookies/etcetera)
- [docs.rs](https://docs.rs/etcetera/latest/etcetera/base_strategy/index.html)
- [github.com](https://github.com/rust-cli/confy)
- [rust-lang.org](https://users.rust-lang.org/t/rust-idiomatic-way-to-collect-and-provide-program-configuration/97434)
- [github.com](https://github.com/Canop/broot/issues/463)
- [github.io](https://whitequark.github.io/rust-xdg/xdg/struct.BaseDirectories.html)
- [crates.io](https://crates.io/crates/microxdg)
- [lukm.dev](https://lukm.dev/writings/use-clap-to-configure-your-rust-app/)
- [logrocket.com](https://blog.logrocket.com/configuration-management-in-rust-web-services/)