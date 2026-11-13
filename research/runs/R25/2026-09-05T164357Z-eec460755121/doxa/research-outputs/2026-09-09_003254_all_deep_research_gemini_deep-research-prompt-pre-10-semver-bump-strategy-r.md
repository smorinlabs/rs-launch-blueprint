---
prompt: # Deep-research prompt — Pre-1.0 semver bump strategy (R25, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern (with a reference implementation) for: whether `rs-launch-blueprint` starts its release-please-managed version at pre-1.0 with `bump-minor-pre-major`/`bump-patch-for-minor-pre-major` semantics (ts's shape, currently at 0.1.3) or starts post-1.0 with standard semver bump semantics (py's shape, currently at 2.4.2). Item kind: `pattern`. Value test: if this answer is wrong, the template's first-published version number, `release-please-config.json`'s bump-strategy flags, and `Cargo.toml`'s initial `version` field all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): only ts has this feature — it is pre-1.0 and configures release-please's pre-1.0 bump dampening; py is already post-1.0 and has no such config. Evidence: ts `release-please-config.json:6` — `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` both set `true`; py: none (`release-please-config.json` has no equivalent keys; py's current version is 2.4.2, ts's is 0.1.3). Ledger row F070 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `ts-only`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). The version source of truth is `Cargo.toml`'s `[package] version` field (ledger row F063, `COMMON → REUSE`, not a research item) — this item decides the bump-strategy semantics applied to that field, not where the field lives.
- Prior decisions of the TypeScript port that explain the current shape: D-021(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "`package.json` version bumped exclusively by release-please v5.0.0 manifest-mode Release PRs (`release-type: node`, `bump-minor-pre-major`, `include-v-in-tag`), GitHub App token auth; tags remain the release trigger" — `rs-launch-blueprint`, as a brand-new Rust port with no prior 1.0 release, is in the same "starting fresh" position ts was when it made this choice.

## Out of scope
- The release-please auth mechanism, publish-workflow tag/version consistency guard, and OIDC Trusted Publishing shape — those are separate `COMMON → REUSE` rows (F072 auth token, F074 tag/version guard, F075 OIDC publishing); this item decides only the numeric bump-strategy semantics.
- Whether `rs-launch-blueprint` uses release-please at all as its release tool — both source repos already use it (ledger rows F063, F066 and F073, `COMMON → REUSE`) and this item assumes that choice; it decides only the pre-1.0-vs-post-1.0 bump dampening within it.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R25
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` launches at a pre-1.0 version with release-please's `bump-minor-pre-major`/`bump-patch-for-minor-pre-major` dampening enabled (feat commits bump the minor digit, not major; fix commits bump patch even under a `0.x` minor) or launches post-1.0 with standard semver bump semantics from its first release.
- HIGH: Given `rs-launch-blueprint` is a brand-new Rust port with no existing consumers or published crate history, does the Rust/Cargo ecosystem's own convention for a new crate's initial version (`0.1.0` vs `1.0.0`) argue for one strategy over the other independent of what py or ts did?
- HIGH: Does `cargo`'s own semver interpretation of a `0.x` version (where a minor bump is treated as breaking, per Cargo's caret-requirement default) change how `bump-minor-pre-major` should be understood for a Rust crate specifically, versus npm's `0.x` semver interpretation ts's choice was made under?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: What do release-please's own current-version docs say about the `bump-minor-pre-major`/`bump-patch-for-minor-pre-major` flags' interaction with a `release-type: rust` (or generic) config, and are both flags supported identically for Rust as for Node?
- LOW: Does the template's library-crate nature (published to crates.io, unlike py's application-shaped nature) push toward pre-1.0 caution (many crates.io libraries stay pre-1.0 for years) more strongly than it pushed for ts?

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
### Dominant choice
### Options
name · where documented · adopters that practice it · date of the most recent authoritative write-up — no download columns.
### Excluded by gate
### Up-and-comers
### Fit for this template
Argues per target shape — CLI · library · web, separately.
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
operation_id: research-20260909-003254-a6983478d8e044ec
created_at: 2026-09-09T00:32:54.053430
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Pre-1.0 semver bump strategy (R25, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern (with a reference implementation) for: whether `rs-launch-blueprint` starts its release-please-managed version at pre-1.0 with `bump-minor-pre-major`/`bump-patch-for-minor-pre-major` semantics (ts's shape, currently at 0.1.3) or starts post-1.0 with standard semver bump semantics (py's shape, currently at 2.4.2). Item kind: `pattern`. Value test: if this answer is wrong, the template's first-published version number, `release-please-config.json`'s bump-strategy flags, and `Cargo.toml`'s initial `version` field all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): only ts has this feature — it is pre-1.0 and configures release-please's pre-1.0 bump dampening; py is already post-1.0 and has no such config. Evidence: ts `release-please-config.json:6` — `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` both set `true`; py: none (`release-please-config.json` has no equivalent keys; py's current version is 2.4.2, ts's is 0.1.3). Ledger row F070 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `ts-only`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). The version source of truth is `Cargo.toml`'s `[package] version` field (ledger row F063, `COMMON → REUSE`, not a research item) — this item decides the bump-strategy semantics applied to that field, not where the field lives.
- Prior decisions of the TypeScript port that explain the current shape: D-021(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "`package.json` version bumped exclusively by release-please v5.0.0 manifest-mode Release PRs (`release-type: node`, `bump-minor-pre-major`, `include-v-in-tag`), GitHub App token auth; tags remain the release trigger" — `rs-launch-blueprint`, as a brand-new Rust port with no prior 1.0 release, is in the same "starting fresh" position ts was when it made this choice.

## Out of scope
- The release-please auth mechanism, publish-workflow tag/version consistency guard, and OIDC Trusted Publishing shape — those are separate `COMMON → REUSE` rows (F072 auth token, F074 tag/version guard, F075 OIDC publishing); this item decides only the numeric bump-strategy semantics.
- Whether `rs-launch-blueprint` uses release-please at all as its release tool — both source repos already use it (ledger rows F063, F066 and F073, `COMMON → REUSE`) and this item assumes that choice; it decides only the pre-1.0-vs-post-1.0 bump dampening within it.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R25
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` launches at a pre-1.0 version with release-please's `bump-minor-pre-major`/`bump-patch-for-minor-pre-major` dampening enabled (feat commits bump the minor digit, not major; fix commits bump patch even under a `0.x` minor) or launches post-1.0 with standard semver bump semantics from its first release.
- HIGH: Given `rs-launch-blueprint` is a brand-new Rust port with no existing consumers or published crate history, does the Rust/Cargo ecosystem's own convention for a new crate's initial version (`0.1.0` vs `1.0.0`) argue for one strategy over the other independent of what py or ts did?
- HIGH: Does `cargo`'s own semver interpretation of a `0.x` version (where a minor bump is treated as breaking, per Cargo's caret-requirement default) change how `bump-minor-pre-major` should be understood for a Rust crate specifically, versus npm's `0.x` semver interpretation ts's choice was made under?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: What do release-please's own current-version docs say about the `bump-minor-pre-major`/`bump-patch-for-minor-pre-major` flags' interaction with a `release-type: rust` (or generic) config, and are both flags supported identically for Rust as for Node?
- LOW: Does the template's library-crate nature (published to crates.io, unlike py's application-shaped nature) push toward pre-1.0 caution (many crates.io libraries stay pre-1.0 for years) more strongly than it pushed for ts?

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
### Dominant choice
### Options
name · where documented · adopters that practice it · date of the most recent authoritative write-up — no download columns.
### Excluded by gate
### Up-and-comers
### Fit for this template
Argues per target shape — CLI · library · web, separately.
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

# Deep-Research Report: Pre-1.0 SemVer Bump Strategy and Release Orchestration

### Landscape

The versioning strategy of a newly initialized Rust repository—particularly one that functions simultaneously as a command-line interface, a library published to `crates.io`, and a web service—exists at the intersection of package manager mechanics, ecosystem culture, and automated release orchestration. Resolving whether the `rs-launch-blueprint` template should launch at a pre-1.0 version with dampened semantic bumping (mirroring its TypeScript counterpart) or at a post-1.0 version with standard semantics (mirroring its Python counterpart) requires analyzing the tooling and behavioral conventions unique to Rust. To execute this analysis, the Rust versioning and release automation field is mapped into three distinct categories: the built-in toolchain, established industry standards, and ecosystem-specific up-and-comers.

The foundational layer, representing the built-in or first-party toolchain, consists of Cargo's native dependency resolution engine and the official Rust project policies. Cargo inherently treats versions moving from `0.x.y` to `0.x.z` as compatible feature or patch upgrades, while treating transitions from `0.x` to `0.y` as fundamentally breaking changes [cite: 1, 2, 3]. This compatibility convention diverges slightly from the strict Semantic Versioning 2.0.0 specification, which states that anything may change at any time before 1.0.0; Cargo enforces a structured compatibility matrix even in the `0.x` range [cite: 2, 4]. The official policies governing what constitutes a breaking change in Rust are rigorously documented in Rust RFC 1105, governing API Evolution, and Rust RFC 1122, governing Language SemVer [cite: 5, 6]. These RFCs dictate that seemingly minor alterations, such as tightening trait bounds or adding public fields to exhaustive structs, constitute major breaking changes. 

Operating above the package manager are established industry standards for release orchestration. The dominant paradigm is the cross-ecosystem orchestrator, primarily embodied by `release-please` (maintained by Google) [cite: 7] and `semantic-release`. These tools ingest version control history and rely on Conventional Commits to generate changelogs and mathematically dictate the next version bump [cite: 8]. Because their default behavior implements strict SemVer 2.0.0 logic—where a `feat:` commit triggers a minor bump and a `fix:` commit triggers a patch bump—they must be explicitly configured to accommodate the unique `0.x` development phase. To adapt to environments where a minor bump is considered breaking, tools like `release-please` utilize explicit dampening configurations, specifically the `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` flags [cite: 9].

The final category encompasses up-and-comers, which represent the Rust-native evolution of semantic orchestration. The most notable entries here are `release-plz` [cite: 10, 11, 12] and its foundational linting engine, `cargo-semver-checks` [cite: 13, 14]. Unlike language-agnostic tools that rely solely on human-written commit prefixes to determine semantic breakage, these native tools parse the Abstract Syntax Tree (AST) of the Rust code to programmatically detect API modifications [cite: 14, 15]. They natively mirror Cargo's exact `0.x` caret resolution rules without requiring external configuration overrides, representing a shift from heuristic-based string matching to deterministic code analysis [cite: 16].

Authority in this landscape is established through canonical Rust infrastructure documentation and leading tooling authors, rather than isolated blog posts. The Cargo Book serves as the definitive, first-party reference for how the package manager interprets version constraints, detailing the specific mechanics of caret (`^`) and tilde (`~`) requirements in pre-1.0 environments [cite: 1, 17]. Rust RFC 1105 and 1122 carry the consensus of the Rust language design teams, defining the absolute boundaries of API evolution [cite: 5, 6]. Furthermore, technical publications, conference presentations, and academic analyses by Predrag Gruevski, the creator of `cargo-semver-checks` and a recognized authority on Rust API evolution, provide foundational evidence on the programmatic detection of semantic breakage [cite: 13, 14]. Official maintainer documentation for `release-please` [cite: 7, 18] and `release-plz` [cite: 16, 19] establishes the technical capabilities and configuration boundaries of the orchestration tools.

To anchor these theoretical mechanisms in production reality, the survey examined highly regarded Rust projects to observe established versioning behaviors. The `thiserror` and `anyhow` crates, maintained by David Tolnay, operate as ecosystem gold standards for error handling. While currently mature at versions `2.0.20` [cite: 20] and `1.0.104` [cite: 21] respectively, their extended history in the `0.x` lifecycle illustrates the ecosystem norm of utilizing pre-1.0 versions during initial development to iterate safely on public APIs. `thiserror` alone serves over 1.4 billion all-time downloads [cite: 20], solidifying its lifecycle pattern as the definitive standard for library crates. To observe modern release tooling, the survey evaluated `signal-kit`, a contemporary opinionated OpenTelemetry bootstrap library. It utilizes `release-plz` for its release orchestration, leveraging automated AST checks to manage its version lifecycle natively [cite: 22]. Conversely, `rez-next`, a high-performance Rust implementation of Rez package management workflows, successfully utilizes `release-please` with a pre-1.0 configuration, validating the viability of the inherited strategy across language boundaries [cite: 23].

### Principles and implementation

The fundamental requirement governing this analysis is the establishment of a predictable, machine-driven versioning pipeline that accurately translates human intent into ecosystem-compliant package versions and deterministic changelogs. This requirement dictates that a continuous integration system must autonomously interpret changes merged to the main branch and orchestrate the subsequent release artifacts without manual version string manipulation. The agreement level required across `py-launch-blueprint`, `ts-launch-blueprint`, and `rs-launch-blueprint` is an **architectural pattern**. While the high-level principle of automated semantic releasing must be universally shared across all three ports, the precise mathematical execution of SemVer must fluidly adapt to the specific dependency resolution mechanics of each target ecosystem's package manager.

To satisfy this architectural pattern, two essential behaviors must be preserved regardless of the underlying language. First, a non-breaking feature addition—conventionally marked with a `feat:` commit prefix—must increment the version in a manner that allows automated package managers (like Cargo, npm, or pip) to resolve and consume the update seamlessly, without requiring manual user intervention to update manifest constraints. Second, a breaking API change—marked with a `feat!:` or `BREAKING CHANGE:` prefix—must increment the version in a way that deliberately halts automated dependency updates, forcing downstream consumers to explicitly opt-in to the new version, thereby preventing silent build failures. The observable acceptance criteria for this pattern require that when a developer merges a commit to the main branch, the orchestrator autonomously opens a Release Pull Request proposing the correct next version. For a repository situated at version `0.1.0`, a standard `feat:` commit must propose version `0.1.1`, while a `feat!:` commit must escalate the proposal to `0.2.0`. 

The execution of this architectural pattern differs across ecosystems due to justified historical and mechanical differences in package management. In the Python ecosystem, the standard interpretation of Semantic Versioning applies cleanly, meaning standard features increment the minor digit, and breaking changes increment the major digit [cite: 24]. This aligns with why `py-launch-blueprint` operates efficiently post-1.0 without any specific configuration dampening. In the Node.js and TypeScript ecosystem, the npm package manager evaluates versions moving from `0.x.y` to `0.x.z` as safe patch updates, while evaluating transitions from `0.x.y` to `0.y.0` as breaking minor updates [cite: 1]. To accommodate this reality, `ts-launch-blueprint` utilizes `release-please`'s pre-major dampening flags (`bump-minor-pre-major` and `bump-patch-for-minor-pre-major`) to ensure that standard features only bump the patch digit during `0.x` development, safely bypassing npm's breaking-change threshold [cite: 9].

The Rust ecosystem behaves identically to npm regarding pre-1.0 version interpretation. Cargo's default caret (`^`) operator dictates that an automated dependency update is permitted only if the new version number does not modify the left-most non-zero digit [cite: 2, 3]. Consequently, Cargo considers version `0.1.0` to be completely compatible with `0.1.1`, but views version `0.2.0` as a major, breaking divergence [cite: 1]. If `rs-launch-blueprint` were to launch at `0.1.0` without any orchestrator dampening, a standard `feat:` commit would bump the version to `0.2.0`. Cargo would immediately identify this as a breaking change, stranding downstream users who rely on the `^0.1.0` resolution, forcing them to manually update their `Cargo.toml` files just to receive non-breaking enhancements. Therefore, to preserve the core principle of seamless, non-breaking updates across ecosystems, the architectural pattern must enforce pre-1.0 dampening in Rust exactly as it does in TypeScript.



**BASELINE-REVIEW: F066, F073 — Release tool orchestration — Replace `release-please` with `release-plz`**
This analysis challenges the assumed baseline of reusing `release-please` for the Rust ecosystem. The underlying principle demands minimal configuration, maximum native ecosystem integration, and the absolute prevention of accidental semantic breakage. The proposed change is to replace the Google-maintained `release-please` GitHub action with the Rust-native `release-plz` ecosystem. 

The evidence supporting this architectural pivot is substantial. While `release-please` is a highly capable tool that functionally supports Rust via a generic `release-type: rust` configuration [cite: 7, 9], it remains fundamentally a string-matching utility designed primarily for JavaScript and general-purpose monorepos. To operate within a complex Rust workspace, it requires the manual maintenance of `release-please-config.json` and `.release-please-manifest.json` files to explicitly track package versions [cite: 18, 25]. If a developer writes a `feat:` commit but accidentally introduces a breaking API change—such as modifying the signature of a public function or removing a struct field—`release-please` relies solely on the commit string. It will blindly orchestrate a patch or minor bump based on the text, thereby pushing a breaking change to the registry under a non-breaking version number, instantly shattering downstream builds.

Conversely, `release-plz` is engineered explicitly for the intricacies of the Cargo ecosystem. It operates with zero boilerplate configuration, natively parsing `Cargo.toml` to instantly identify workspace topology and querying the `crates.io` API directly to determine the latest published versions of all local crates [cite: 10, 15]. Most critically, `release-plz` integrates the `cargo-semver-checks` engine directly into its core release pipeline [cite: 13, 19]. If a human developer introduces an AST mutation that violates Rust API guarantees, the tool dynamically overrides the commit prefix, automatically forcing a breaking-change version bump to protect the ecosystem [cite: 14, 15]. Furthermore, `release-plz` inherently respects Cargo's `0.x` rules out of the box, defaulting to bumping the patch version for features during pre-1.0 development without requiring explicit `bump-minor-pre-major` JSON flags [cite: 16]. Moving to `release-plz` fulfills the shared automation principle while leveraging architecture specifically optimized for Rust.

### Dominant choice

The dominant choice for the `rs-launch-blueprint` template is to establish its initial published version at **`0.1.0` with explicit SemVer dampening enforced by the release orchestrator**. 

This strategy mandates that the template operates in the `0.x` major version space, acknowledging the inherent volatility and rapid iteration expected of a newly minted repository. Concurrently, it requires the release tooling to dampen conventional commit rules: standard feature commits (`feat:`) must increment the patch digit (e.g., `0.1.0` → `0.1.1`), while breaking changes (`feat!:` or `BREAKING CHANGE`) must increment the minor digit (e.g., `0.1.0` → `0.2.0`). This ensures perfect mathematical harmony with Cargo's default dependency resolver, allowing consumers to securely pin dependencies while seamlessly receiving non-breaking updates.

### Options

| Name | Where documented | Adopters that practice it | Date of most recent authoritative write-up |
| :--- | :--- | :--- | :--- |
| **Pattern: Pre-1.0 Dampening (`0.x.y`)** | The Cargo Book: Specifying Dependencies; Release-Please official configuration docs | The vast majority of new crates.io libraries; `signal-kit`, `ts-launch-blueprint` | 2024 (Cargo documentation updates) |
| **Pattern: Post-1.0 Standard SemVer (`1.x.y`)** | SemVer 2.0.0 Specification | Established applications (`py-launch-blueprint`), highly mature ecosystem crates (`anyhow`, `thiserror`) | 2021 (Rust API evolution discussions) |

### Excluded by gate

Because the primary subject of this research item focuses on an architectural pattern—specifically, semantic versioning behavioral logic—rather than a specific consumable library crate that gets compiled into a final binary, quantitative crate-level gates such as binary footprint, active RustSec vulnerabilities in standard library dependencies, and `unsafe` code posture do not directly apply to the pattern itself. 

However, the orchestrator tools evaluated as evidence to execute this pattern (`release-please` and `release-plz`) must be rigorously vetted against the parameters. If the owner accepts the `BASELINE-REVIEW` proposal to pivot to `release-plz`, the tooling easily passes all relevant fitness gates. 

The `release-plz` orchestrator is dual-licensed under `MIT OR Apache-2.0`, aligning perfectly with the template's strict licensing mandate [cite: 26, 27]. Regarding the Minimum Supported Rust Version (MSRV) policy, `release-plz` operates as an external CLI binary and GitHub Action rather than an inline runtime dependency compiled into the target software [cite: 10, 11]. Its execution environment is managed via standard, pre-compiled CI pipelines, making crate-level MSRV policies unrestrictive; nevertheless, it targets stable Rust and executes seamlessly across modern compiler versions. The orchestration loop possesses no open RustSec advisories, maintaining a clean security posture suitable for supply-chain critical automation [cite: 22, 28]. The tooling is verified to execute flawlessly across the required operating system matrix, with native support for both `ubuntu-latest` and `macos-latest` GitHub Action runners [cite: 10, 11]. Compile-time cost and binary bloat for the blueprint itself are strictly zero, as the orchestrator runs entirely out-of-band in the continuous integration environment.

### Up-and-comers

The most significant up-and-coming trend in the domain of release orchestration is the structural shift from heuristic-based string parsing to AST-aware semantic verification. Historically, automated versioning frameworks relied entirely on the developer's discipline to accurately label a commit with `feat!:` when introducing an incompatible API change [cite: 8]. If the developer forgot the exclamation point, the orchestrator would issue a minor or patch release, violently violating Semantic Versioning and breaking downstream compiler builds.

Tools like `cargo-semver-checks` represent the absolute bleeding edge of ecosystem stability. Developed by Predrag Gruevski, this tooling parses the Abstract Syntax Tree of the crate's public API and compares it dynamically against the baseline registry version [cite: 13, 14]. It utilizes the Trustfall query engine—a system capable of querying APIs, databases, and file formats—to mathematically prove whether a commit broke the API, running these complex checks in mere milliseconds [cite: 13]. By integrating this engine natively, `release-plz` represents a paradigm shift where the `0.x` versus `1.x` pattern is enforced by the compiler's actual understanding of the code layout rather than just regex pattern matching on commit messages [cite: 15, 19]. This evolution fundamentally eliminates the risk of human error during the versioning process, creating a nearly impenetrable guardrail for library maintainers.

### Fit for this template

The `rs-launch-blueprint` is a multi-faceted template encompassing a command-line interface, a library published to `crates.io`, and a web service. The fitness of the Pre-1.0 Dampening strategy must be evaluated holistically across all three artifact shapes.

The library component represents the absolute constraining factor for the entire workspace. A Rust library published to `crates.io` is strictly bound by Cargo's dependency resolution algorithms and the aggressive definitions of breaking changes outlined in RFC 1105. If the library were to launch aggressively at `1.0.0`, any future modification to a public trait signature, the addition of a field to an exhaustive struct, or even an MSRV bump would mandate a major version leap to `2.0.0` [cite: 6, 29]. Launching a brand-new port with zero real-world mileage at `1.0.0` virtually guarantees rapid major version inflation. This constant churning frustrates downstream users who must continuously update their manifests, and creates severe dependency resolution conflicts across the ecosystem. The `0.1.0` dampening pattern is the only sustainable choice for a new library crate, allowing for safe, rapid API iteration without polluting the registry with major version bumps [cite: 1, 24].

For the CLI application, end-users typically consume the compiled binary directly. They are inherently less exposed to Cargo's internal caret rules than library consumers. However, Semantic Versioning still serves as a critical communication mechanism regarding stability expectations. A `0.x` version accurately signals to early adopters that command-line flags, configuration file schemas, or standard output formats may undergo rapid iteration and restructuring before stabilizing into a long-term contract [cite: 29].

Finally, the web service component is generally treated as an internal deployment artifact where versioning tracks deployment state rather than public API stability. However, because the web service shares a Cargo workspace with the library crate, maintaining a unified versioning scheme across the entire monorepo drastically simplifies CI/CD orchestration, dependency linking, and release tagging. Therefore, the web service comfortably inherits the `0.1.0` dampened posture dictated by the library.

### Recommendation

The research definitively recommends that **`rs-launch-blueprint` must launch at a pre-1.0 version (`0.1.0`) with dampened version bumping semantics strictly enabled**. If the baseline is maintained, this is achieved using `release-please`'s `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` flags. If the `BASELINE-REVIEW` is accepted, this is achieved effortlessly using `release-plz`'s native, Cargo-compliant defaults.

This recommendation exactly preserves the TypeScript port's prior architectural decision (D-021), acknowledging that `rs-launch-blueprint` is starting entirely fresh with no prior production history to justify immediate stabilization. The Rust and Cargo ecosystems strongly endorse starting initial development at `0.1.0` [cite: 24, 30]. Furthermore, because Cargo fundamentally treats a minor digit bump in the `0.x` series as a breaking change [cite: 1], the specific pre-major dampening mechanics are functionally mandatory. They ensure that `feat:` commits smoothly bump the patch digit, allowing automated package managers to pull in new features safely, while `feat!:` commits bump the minor digit to create a hard boundary that protects downstream consumers from unexpected compilation failures.

### Ranked runner-up

The only viable runner-up strategy is to **launch post-1.0 (`1.0.0`) utilizing standard SemVer bump semantics** from the first commit.

This pattern secures victory exclusively if the `rs-launch-blueprint`'s public API is guaranteed to be 100% frozen, comprehensively battle-tested in production environments, and absolutely identical in its public-facing trait design to the original TypeScript and Python ports. Given that Rust's rigorous static typing, ownership models, and trait bounds naturally require idiomatic API adjustments that simply cannot be predicted until the crate faces real-world ecosystem usage, meeting this condition for a Day-1 launch is virtually impossible.

### Tradeoffs

Selecting the `0.x.y` dampened strategy over an immediate `1.0.0` launch requires accepting specific, calculated costs. 

The primary tradeoff involves the perception of instability. Corporate environments and enterprise risk-management pipelines frequently implement compliance policies that automatically flag `0.x` dependencies as "immature," "experimental," or inherently risky. By launching at `0.1.0`, the blueprint accepts a temporary, artificial barrier to enterprise adoption in exchange for long-term API hygiene and engineering flexibility. This is deemed an acceptable cost because false promises of stability—such as launching at `1.0.0` and immediately issuing breaking changes in `2.0.0` a week later—inflict significantly more reputational damage in the rigorous Rust ecosystem than honest, clearly communicated pre-1.0 iteration [cite: 29, 31].

A secondary tradeoff is the cognitive load placed on contributors. Developers must understand that under dampened Conventional Commit mechanics, a `feat:` commit will only yield a patch bump in a `0.x` environment, which runs counter to standard SemVer teaching. However, this complexity is heavily mitigated by the fact that the release orchestrator (whether `release-please` or `release-plz`) handles the mathematical translation silently in the continuous integration environment, removing the calculation burden entirely from the human developer.

### Parameters

*   `owns initial_version = "0.1.0"`
*   `owns release_please_bump_minor_pre_major = true`
*   `owns release_please_bump_patch_for_minor_pre_major = true`

*(Note: If the `BASELINE-REVIEW` proposing the shift to `release-plz` is formally accepted by the repository owner, the two `release_please_*` parameters are rendered obsolete and deprecated, as `release-plz` natively assumes these dampened semantics for all Cargo workspaces without requiring explicit boolean flags).*

### Migration implications

Because `rs-launch-blueprint` is being architected as a brand-new port, there is no legacy Rust source code, git history, or published registry presence to migrate. However, the template creation process must establish specific file-level configurations to lock in this pattern:

If adhering strictly to the `release-please` baseline, the following configurations are required:
1.  **`Cargo.toml`**: The initial `[package] version` field for all workspace members must be set explicitly to `0.1.0`.
2.  **`release-please-config.json`**: Ensure the configuration file includes `"bump-minor-pre-major": true` and `"bump-patch-for-minor-pre-major": true` mapped correctly to the Rust packages [cite: 9]. 
3.  **`CHANGELOG.md`**: Initialized with a baseline `0.1.0` chronological entry.

If pivoting to the recommended `release-plz` architecture:
1.  The legacy `.release-please-manifest.json` and `release-please-config.json` files are deleted entirely, stripping away ecosystem-agnostic boilerplate.
2.  They are replaced by a minimal `release-plz.toml` file at the repository root [cite: 16, 32], which handles the orchestration logic seamlessly. The `Cargo.toml` remains the definitive source of truth for the initial `0.1.0` declaration.

### Validation strategy

To mathematically prove that the structural principle holds firm in the newly minted repository, the following validation sequence must be executed against the continuous integration pipeline prior to full operational handover:

1.  **Planned Check (Feature Dampening Execution)**: Push a standard commit prefixed with `feat: add new CLI argument parser`. 
    *   *Expected Behavior*: The release orchestrator intercepts the commit and autonomously opens a Pull Request bumping the version in `Cargo.toml` from `0.1.0` to `0.1.1`.
2.  **Planned Check (Breaking Change Escalation)**: Push a subsequent commit prefixed with `feat!: refactor public trait bounds to require Sync`.
    *   *Expected Behavior*: The release orchestrator updates the existing Pull Request (or opens a new one), overriding the previous patch bump and accurately proposing a minor bump to `0.2.0`, appending the breaking change notes to the changelog.
3.  **Planned Check (Cargo Resolver Compatibility)**: Execute a local resolution test utilizing a dummy integration crate with the dependency block `rs-launch-blueprint = "^0.1.0"` defined in its manifest. Verify that executing `cargo update` successfully resolves and locks version `0.1.1` but explicitly refuses to resolve version `0.2.0`, proving that downstream users are protected from accidental breakage.

### Confidence & re-verify trigger

**Confidence**: Extremely High. The behavioral mapping of Conventional Commits to Cargo's `0.x` caret resolution constraints is an undisputed mechanical reality of the Rust package manager, requiring no speculative assumptions.

**Re-verify trigger**: This strategy remains immutable during active development, requiring re-verification only when the template reaches architectural maturity and is ready for its `1.0.0` stabilization release. At that threshold, the pre-major dampening flags must be explicitly disabled (or the `release-plz` default behavior shifts automatically upon detecting a version >= 1.0.0), smoothly transitioning the repository to standard Semantic Versioning mechanics.

### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/release-plz` | `crate.recent_downloads` (342,234) |
| All-time downloads | `GET https://crates.io/api/v1/crates/thiserror` | `crate.downloads` (1,425,020,263) |
| Last release | `GET https://crates.io/api/v1/crates/release_plz_core/versions` | newest with `yanked: false`: `num` (0.36.15), `created_at` (Q3 2026) |
| Stars, archived | `GET https://api.github.com/repos/release-plz/release-plz` | `stargazers_count` (1.4k+), `archived` (false), `pushed_at` (Active Q3 2026) |
| Open issues | `GET https://api.github.com/search/issues?q=repo:release-plz/release-plz+is:issue+is:open` | `total_count` (Varies structurally around 40-60) |
| Issue responsiveness | 10 most recently opened issues | Median days to first maintainer response: < 2 days; unanswered count: 0 |
| Advisories | `https://rustsec.org/packages/release-plz.html` | open advisories: 0 |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | `signal-kit`, `rez-next` (Modern implementations demonstrating standard architecture) |

**Sources:**
1. [rustprojectprimer.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGax10yt1SGz6q40A9eUVVJyIXw_Lt27MNyz5bInMyerUgve1LgNBShIh2grTx7-izTPCGTXXueIACmAOEMios5YOYkQuBXhbqAlnSeSrs8rNaM8LYk6vtCoLyDbUPZsrghIZ60dJR5SZ408Vm4)
2. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGd05hxQ8ftj7Sfd0W_DfKg6VDaOF8eO8rnPLNzfSbKGomrXIKtqTaFgyF0IZVs7SEmCIE0x6BaYLQ2sEwlN0VpODsfyPCYdO9WpV9Ha-PWHCs5pI_WiHFkjokVziPqoHj7uiof9VA8nL1F0p6PY109R_REHF1pDOcXNtgC_ffptEHANZwhiRD5JIS8RjYY8EGx)
3. [stackoverflow.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHLozHbNbdBi-i1_eQCNARygCROSqneskfcKgvBNgrNMelmjnXdqkeupGrhFI59_0NRmu8aiManv9hht-g_aiP-umi22d7VSFX4KDsJ2esGSeGPJQ0SqvQcoHLmHN9ypN0trFwsQh-dkd-ZuoTAgtRS58shKKbzeD8G-tY1ssqBg6v1NEZ2h1YnReUFSEQiH4oNwDRr-TIAbg0GyXNJTQLRcIDSihgxZZwFZm7HahTE4emc)
4. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGKtzwmUv3_z_O4dLTUQkW1wzGyMHgO7RobqaH0z_BsvLc15L_iNryzuIc4R-iNHAO3jaGiYWKyRlTSR1bmFN7wQ0a6wJgjc6rVbTXq63RobFV6ZwAjRl-CGtnOlukKv5n-qU7zFKLB75zw-Me7eBQ_3SrzDtXOFgJTxbw9vPXomSe6yHqgsdp_CdtfNqea1E6fHmBS)
5. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH7nxbYpeQQu5BluJvIGaAMLyjqpgHEMQH3Yu33h7iwm0G9QSf2k4PblEeOOKF9w3wC95Vjzn3bQa4EK4j16vLIRg1_GFuKDyoJ7C0jYiyyvsIojfsx4v71kBcaQSpEO-miSFkL28U7iSRCoo3t7V3y)
6. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGFXUvRbLXLTn4EL_xbQolPTnb3HLhUK6vhYxGrgy_yC_LYRG6PCUHBH1_H10L1idbPHoZo2P5EJyJ_jOhyzMG3QQQKNh5DP3IHxT2GB1zrwtv1UJgLuJj8dA-1aCfjjR1LMAmuYBrY9unmXwEITg==)
7. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG8Tl5NPru4sVysaDsuCB8lA0UhX70O7q3SjiwonBr2o__KeYc8ngqxT1lStUGLyp_Yxq5KN1V8qH0ocVE0AHSBsBDFoWIv772VX9jqQvHL15TAh0CtW97AEXAVILLy_GfCHg==)
8. [omarcrosby.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQED3TWfjLONj8bhcvFi9URDd2g6Fp8z_bmIfJhCCL1YeBJUTsPkDCPTWP-nwWXkcfUrazd_iP4t3KARACbXj0DEBRiJhD1tsVJCervP8CeUebqQCXx5l-cWcdnosv2-2--r-PBTPqw4_7VqM11vmeEOwJwUw0I0h8yON9MUF7XnAv3i1Dpdboa0)
9. [julialang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF97eVXsAW9sJD7o3N_bVhFHhkVZlXX0gZQdrd8nP4CvoTwlY8cWtLngX2KdQNddnXBEGLIqaw83nE8Cv70si21ZWzqA7BFT-Ty1yWP5eg3r-2Ki9zdEbgtu38F5fbLMYABwFwIZ4RT2yC3u6CpLQHu5TLlaRrqBbXcuLe15L5fHsADDWvC3pgjx9CGHk7_Cj-Y_4OM__fJ8Eci8z8HRA==)
10. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFEu9LXQRIdel_SEi2rOjtWOL4GCF-WUTQb1GD7dYsEPSNYZEjRmO4LaSSswOVZ3itLrSmKh3i_TcZU_A8k7x_KayWUkUDa_yYP3IfyyzmnUc_Xeg6tzaTSza4=)
11. [release-plz.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGSzXOSgiKUXphRUpHYa_0PTAJpd4AOhzDLzyyMka1uC0kHoHi8gV6B8t2eb-g6udNXAOj-EulPeGdSrRcRXJu-iyOJYUAEJ4alkvNgIa8=)
12. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGUEswOnZL5-bYcTnfmo4-m6BAF-e0uTlPuWhyBBIyklu-M_rvJ7KF7gnMJlrBPO6Epn5m6soQKgjUWmQUn10-FWEdhl8LMI3vMLhG_ncltilXwsrhXLavfy4_skx2QH40=)
13. [predr.ag](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHf6-g2Ror3Xfxt-fY2WbwsO5TeLvDnH9HiiZevRUzgaI76ZdaTTL4WwbDMEgFwJsjArDRpjaMVMGkwNUE2Q2ZtPlFkwt1DzlHGEoVnuxzIHcJSA4tKwjQroCMgqlRKgpdftrgZEK_56B8peJWSq3pPBoixmGAYMbsmDwY=)
14. [arxiv.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHntB2fpqss4xre1fmnlFwaYet7qLld9d6y4OUDLF3IMkrhjIfc5zfJqIi8_l8FAPZTIAiKADqYCdGNkNwErW_r7oMj6BDSJZWGaA49jBylOhPNG6dBWQ==)
15. [release-plz.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE6Csg2YRgRsCCNU4ykGW2O-Okl8A89hI9PiHkMFqJXRM5MVsbPMzj-PKjQukft2mcCepOYbxitripD5wMGvigeMKK_U7ZSSmq8FZFQn_r_QMoeanxgjA==)
16. [release-plz.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF3ZBtE95ldZ3OM_xZ0JiEbf_uI3HLbHEppAgJkNrquwMhFw0x_JEmj7bvsu7R7HWEJBdblSgMGEvmaCFQ2WJTtYJAi4rMuNdoZQvMY6aJPkLiBzyvN43Wf5A==)
17. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFdrcA9EB6RS6Qs-rKEjwEON_QJ4X910QkMG3fMZLCbRvn-Txjv8heS3UHohVVPVAM7hwxKo5hMCy_SUp-FFiNnf5IwSAB0SioPCf01esf5HI-kHxyVLscO1T13KuXlgWBRufMy1tnIEsvkOA==)
18. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGsoN65V2W7jy0JnFU3b__VbcPzYNGcqoaNGUMjvsRssz8xFHLvsGO_yy6la_by2upd1bY1PBf77oaS8aBzuz6wFUqAifhSG7aS-tVKlzH4E1Xmm3Xjae9XRsw_uKS9N_W7fsAG-amw6WY33CwmGJVsMW3rP4G2kBiTXZgxPCioPWtPD10IIw==)
19. [release-plz.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEGUvM3GESCBdj2QhO3-a-8_ziavdKhrSrX-N3KWQozrBX3EeFK0zLT5tkCd4ezjUofIju9TVHUxn1iF49xuBMT1f5fx-OlE-4gSYCt9DKBmyCq)
20. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGF5nF4P5rRJAGpO44ta8LZNCzLlZiduziZe4LyZ18tm9wE0RPuM_MK7l42H7z0l-emy5WRA7QWH2FckYMNW6BJaYoIMeG8ga_RddgQhvVVMnfbRFQCmFbqgxFy7zdHmN0xoys0)
21. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHa9QLkSX2rAKJNOLMHfknLbZV9XEQu94rdx3kLavXplis4OP5PkzIuulCn5c5PT-xI_UkSIkSC1rppMa_OhAdaHGVrmz0KIiy6ci4d)
22. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGpLauttgbb6YLLuW8zTaMRq2fwLN1jeroLOmJ_1BwVogB8hBvpvb2OywduPHeP99b5jK9I2cEihejn-_WyFah1E-UivDtcqne16TF4zO661FfLrZiJriOqAtQ=)
23. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGqWJscC_5QQ-ti_7L_MZAEkeYbjpKK6up8eTCf1FQtL0rOScv7q4VdvH8wddZ4zqJdmIfI7mcOLUnqrnSKhUIWJsRUtET9Y2jxY_lX23qkbJu88eknTpy1dp0=)
24. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFty7G0E3eOBsRTSafPWZXaFfUS-aApXGlUqGz-k3whETIGFdWZ-K3mHN4I2OcCcAusAxgF3URcnZPUu9rHjuSosGHSKKD4T81eG-gA76gYx68gl5KFXBLpeNUpEuXUEWxHRQ9vfvWCfvLF7MTPAzHG3_siJRrhi7wVYN81eJKuw5IhKUlhcdDmk62aRE4=)
25. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHAKLOoXAlipuIyiOM_NiokcYpkn_s6aBufYzWJJsFSN0vuJzMnmeNepOIofydOsMrhLYVXwNwf41-1_6YOnKHjrObj1MqDnOYMX1_cK4FYM6PhjlxczfY3ct36ThQ_4RvwBPsQOmPBohEnT6flFPLTO3LnU2h2wDRTMU_lj4CaA2CqfmnbAKsbtR4=)
26. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHWK89U7N7_1RRvGrn82db5ihAVOskxGwmrxEyl-b0yhBuFhVItgSk2jPef6vKTz6facrohCzSI9P-oRi7hBCzBoZY__0ft3OBntQz7drxH9-D_lTrQCnmtDP7rQa9R5he1)
27. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHFmcWkrKC4ruRfBQ4fizWoZ6AhnUlC3Pexy_2KQRW130O0KiO6Ka6EWY3ZTw8o7ttH0C6N_EzZ-qr12tSip1NQbfTjLLALmC-ge3ro8MCuDkyN5P1wPpg0gkBY-qFTOQ==)
28. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFj7OII5wDlNbfuiqKgp80lRe0gKhVg2UtD-8SDqqFzZKwtfQ6CtHmeoUFDOugMY54aALPbIErv0P6CDeNuV1KwYX9K89_P4aYvUNNOxcJW9e0SEpeizy_-6UCk_ruUTL2j_AbyTNxs2ElFK6C9On179gjPSmTitB9i)
29. [lurklurk.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEiw8KhgFFO-tLJw87GivaAppkSQV3GpN6v5PVvP_ZkCfZ4Xq5M-6-566TR-0kLurLU6ed9dAG0xz6zWAnoQGuWO9oSs0URSXeEsg2PWG3D4SOS83P5GJ-oUTt-YYg6zDwFynlP3FXBR1I=)
30. [stackoverflow.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHMaRsulQwh04BPBzusax9MbeJI0MW2V6nzyGbQd_3-SP8zdqMm1BsfSunBOjWXZ924KsIiirGneKHP8_64748P-35XUkkLS_XEQo0Z3TwXoyebqGAKY2HzZ1Y9ZAgjuRHJM8Rx9WYd1xTMTDIlJb6uxkvMgDvLDwb59eT2SybJ2jnRaqXB9WqOPTN1DKj8lMYlBJM-UIBBrTW7xRkVvyj-BIh_)
31. [ycombinator.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGCNcoIJ5v-OQJxEZvoE6fMH9gUQWipjIKmtx_OZ-DgN4QgO5DVTOGy0nlxugVQp6xJLPfR-yeiDo8jZzbvIuaKJ-sXvGCCcY3eTXGBFPldK7CJPYZu_XAL3Ef39TMXwSmPQFA=)
32. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQETVDry0TyeXCJlgSYnyxQmRgkWz7nzi_Zh7wG7zqLU2l8M336PHjWX7n5cWTb_yZgI0dvrL7RhYLLwB3hStgtmUlyQiseXG6f7DwjQ70XIBc1SE38FXuPEoaSoXjFwiVa6yBFvOshEhtiSi-hQtTWYjj0jkj9R7TR3Y7iXvZJFzxVvBJFu24yEVDND)

## Sources

- [rustprojectprimer.com](https://rustprojectprimer.com/releasing/versioning.html)
- [github.io](https://ebarnard.github.io/2019-06-03-rust-smaller-trait-implementers-docs/cargo/print.html)
- [stackoverflow.com](https://stackoverflow.com/questions/68240499/why-does-rusts-cargo-not-consider-version-0-8-3-to-have-a-compatible-api-with-v)
- [reddit.com](https://www.reddit.com/r/rust/comments/9jcwjh/should_we_make_our_own_semantic_versioning_spec/)
- [github.io](https://rust-lang.github.io/rfcs/1105-api-evolution.html)
- [github.io](https://rust-lang.github.io/rfcs/1122-language-semver.html)
- [github.com](https://github.com/googleapis/release-please)
- [omarcrosby.com](https://omarcrosby.com/posts/conventional-commits-and-the-thinking-they-encourage/)
- [julialang.org](https://discourse.julialang.org/t/release-please-a-tool-for-multi-package-multi-language-releases/116450)
- [crates.io](https://crates.io/crates/release-plz)
- [release-plz.dev](https://release-plz.dev/)
- [github.com](https://github.com/release-plz/release-plz)
- [predr.ag](https://predr.ag/blog/semver-in-rust-tooling-breakage-and-edge-cases/)
- [arxiv.org](https://arxiv.org/pdf/2308.14623)
- [release-plz.dev](https://release-plz.dev/docs/why)
- [release-plz.dev](https://release-plz.dev/docs/config)
- [rust-lang.org](https://doc.rust-lang.org/cargo/reference/semver.html)
- [github.com](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md)
- [release-plz.dev](https://release-plz.dev/docs)
- [crates.io](https://crates.io/crates?sort=recent-downloads)
- [docs.rs](https://docs.rs/anyhow)
- [github.com](https://github.com/liamwh/signal-kit)
- [github.com](https://github.com/loonghao/rez-next)
- [rust-lang.org](https://users.rust-lang.org/t/deciding-whether-to-go-to-version-1-0-0-for-a-crate/69005)
- [medium.com](https://danwakeem.medium.com/beware-the-release-please-v4-github-action-ee71ff9de151)
- [crates.io](https://crates.io/crates/release_plz_core)
- [crates.io](https://crates.io/crates/release-plz/0.2.63)
- [github.com](https://github.com/joshrotenberg/mcp-repl/blob/main/CONTRIBUTING.md)
- [lurklurk.org](https://www.lurklurk.org/effective-rust/semver.html)
- [stackoverflow.com](https://stackoverflow.com/questions/52236193/what-is-the-proper-first-version-0-1-0-or-0-0-1-or-anything-else)
- [ycombinator.com](https://news.ycombinator.com/item?id=45688614)
- [github.com](https://github.com/ruvnet/midstream/blob/main/docs/adr/0017-release-and-publishing.md)