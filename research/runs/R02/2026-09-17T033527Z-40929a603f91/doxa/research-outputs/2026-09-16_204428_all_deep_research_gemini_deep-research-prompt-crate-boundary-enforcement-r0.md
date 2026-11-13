---
prompt: # Deep-research prompt — Crate-boundary enforcement (R02, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: how `rs-launch-blueprint`'s Cargo workspace mechanically enforces the architectural boundaries py enforces with `import-linter`/`tach`/`ruff` — composition-root isolation, inward-only core dependencies, front-end independence, core internal layering, framework-bleed guards (authoritative and fast-mirror), a declared module dependency graph, package namespacing, and where in the hook/CI pipeline the check runs. Item kind: `bundle`. Value test: if this answer is wrong, the workspace's `Cargo.toml` member layout, crate dependency declarations, any boundary-checking tool config, and the `lefthook`/CI job that runs it all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py enforces hexagonal boundaries mechanically — a composition root importable only by front-ends, core forbidden from importing front-ends, front-ends forbidden from importing each other, core internal layering, and framework-bleed guards at both an authoritative (CI) and a fast local-mirror tier — all declared and checked by `import-linter`/`tach`/`ruff`, not by review discipline. ts has none of this: no core/front-end split exists to enforce. Evidence: py `pyproject.toml:334` — import-linter `forbidden` contract, `core` may not import `py_launch_blueprint.composition` (HEX-04); ts: none (py-only). Ledger rows: F003, F004, F005, F006, F007, F008, F009, F010, F020, F021, F116 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F004 core forbidden from importing front-ends — py `pyproject.toml:323` (HEX-01); ts: none. F005 front-ends forbidden from importing each other — py `pyproject.toml:329` (`independence` contract); ts: none (ts ships only one front-end). F006 core internal layering — py `pyproject.toml:340` (`layers` contract, HEX-01); ts: none. F007 mechanical over conventional enforcement — py `docs/adr/0017-hexagonal-core-and-boundary-enforcement.md:29-30`; ts: none (relies on review). F008 framework-bleed guard, authoritative — py `pyproject.toml:349` (HEX-32); ts: none. F009 framework-bleed guard, fast local mirror — py `src/py_launch_blueprint/core/ruff.toml:13` (`TID251` banned-api); ts: none. F010 bounded-context module dependency graph — py `tach.toml:19`; ts: none. F020 package namespacing — py `pyproject.toml:139` (`module-name = "py_launch_blueprint"`); ts `src/cli.ts` (path shape: no package-name subdirectory under `src/`), different. F021 Cargo workspace crate topology — origin `none`: neither repo has a compiled-workspace concept to inherit from; this row is `RUST-ONLY`. F116 boundary-check hook-tier placement — py `lefthook.yml:171`, `lefthook.yml:172` (`import-linter` at pre-push), `lefthook.yml:176`, `lefthook.yml:177` (`tach check` at pre-push); ts: none (`docs/port/areas/static-analysis.md`).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): the port/adapter split itself and how an adapter is shown to satisfy a port (F001, F011) belong to R01, not this item — F011 moved from this item to R01 at the Task 10 reconciliation; assume R01 resolves to *some* port split and design the enforcement mechanism to fit either its answer. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a core/front-end split, so `TS_PORT_DECISIONS.md` has no boundary-enforcement entry to carry forward.

## Out of scope
- The shape of the ports-and-adapters seam itself (trait object vs. generic bound) and how an adapter is shown to satisfy a port; R01 (`ports-and-adapters-seam`) owns F001/F002/F011/F013/F018/F121 — this item enforces boundaries between crates, it does not decide what a port looks like.
- Async runtime selection and the sync/async execution model for the I/O boundary; R05 (`sync-async-execution-model`) owns F016/F022 — do not decide sync vs async here.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R02
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R01 (`ports-and-adapters-seam`) decides whether a port/adapter split exists and how an adapter satisfies a port (F011, moved from this item to R01 at the Task 10 reconciliation); assume R01's port split exists and design the crate topology (F021) to hold it, but do not re-decide F011 here. `http-transport-injection-seam` is R01's registered parameter; this item's crate-boundary decision does not need its value — nothing here depends on trait-object vs. generic-bound seam shape, only on how many crates the boundary needs and which way they may depend on each other.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what Cargo workspace crate topology and enforcement tooling give `rs-launch-blueprint` the same mechanical guarantees py gets from `import-linter`/`tach`/`ruff` — composition-root isolation, inward-only core dependencies, front-end independence, internal layering, framework-bleed guards at both a CI and a pre-push tier, and a declared module dependency graph.
- HIGH: Does a single crate with module-visibility (`pub(crate)`, `pub(super)`) enforce these boundaries at compile time, or does only a genuine multi-crate Cargo workspace (separate `core`, `composition`, `cli`, `web` crates) make an illegal dependency a build-breaking error (F021)?
- HIGH: If multi-crate, is `cargo-deny`'s `bans` graph, a custom `cargo metadata`-driven lint, or a workspace-lint crate (e.g. `cargo-hakari`, `cargo-machete`) the Rust analogue of `tach`'s declared module dependency graph (F010) and `import-linter`'s `forbidden`/`layers`/`independence` contracts (F003-F006)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: What is the Rust analogue of py's framework-bleed guard — an authoritative CI check (F008) plus a fast local pre-commit mirror (F009) — that keeps the `core` crate from depending on CLI or web-framework crates (e.g. `clap`, `axum`)? Is a single `cargo check --no-default-features -p core` sufficient, or does it need a dependency-graph linter?
- MEDIUM: Where in the `lefthook`/CI pipeline does the chosen check run (F116) — pre-push only (as py does), or also at a faster pre-commit tier given Rust's compile times?
- LOW: What is the Rust equivalent of py's `src/py_launch_blueprint/` package-namespacing convention (F020) — a workspace member's crate name, or a `pub mod` re-export at the crate root — given Rust crates are already namespaced by `Cargo.toml` `name` with no directory-nesting requirement?

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
operation_id: research-20260916-204428-51b352f774314e76
created_at: 2026-09-16T20:44:28.658831
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Crate-boundary enforcement (R02, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: how `rs-launch-blueprint`'s Cargo workspace mechanically enforces the architectural boundaries py enforces with `import-linter`/`tach`/`ruff` — composition-root isolation, inward-only core dependencies, front-end independence, core internal layering, framework-bleed guards (authoritative and fast-mirror), a declared module dependency graph, package namespacing, and where in the hook/CI pipeline the check runs. Item kind: `bundle`. Value test: if this answer is wrong, the workspace's `Cargo.toml` member layout, crate dependency declarations, any boundary-checking tool config, and the `lefthook`/CI job that runs it all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py enforces hexagonal boundaries mechanically — a composition root importable only by front-ends, core forbidden from importing front-ends, front-ends forbidden from importing each other, core internal layering, and framework-bleed guards at both an authoritative (CI) and a fast local-mirror tier — all declared and checked by `import-linter`/`tach`/`ruff`, not by review discipline. ts has none of this: no core/front-end split exists to enforce. Evidence: py `pyproject.toml:334` — import-linter `forbidden` contract, `core` may not import `py_launch_blueprint.composition` (HEX-04); ts: none (py-only). Ledger rows: F003, F004, F005, F006, F007, F008, F009, F010, F020, F021, F116 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F004 core forbidden from importing front-ends — py `pyproject.toml:323` (HEX-01); ts: none. F005 front-ends forbidden from importing each other — py `pyproject.toml:329` (`independence` contract); ts: none (ts ships only one front-end). F006 core internal layering — py `pyproject.toml:340` (`layers` contract, HEX-01); ts: none. F007 mechanical over conventional enforcement — py `docs/adr/0017-hexagonal-core-and-boundary-enforcement.md:29-30`; ts: none (relies on review). F008 framework-bleed guard, authoritative — py `pyproject.toml:349` (HEX-32); ts: none. F009 framework-bleed guard, fast local mirror — py `src/py_launch_blueprint/core/ruff.toml:13` (`TID251` banned-api); ts: none. F010 bounded-context module dependency graph — py `tach.toml:19`; ts: none. F020 package namespacing — py `pyproject.toml:139` (`module-name = "py_launch_blueprint"`); ts `src/cli.ts` (path shape: no package-name subdirectory under `src/`), different. F021 Cargo workspace crate topology — origin `none`: neither repo has a compiled-workspace concept to inherit from; this row is `RUST-ONLY`. F116 boundary-check hook-tier placement — py `lefthook.yml:171`, `lefthook.yml:172` (`import-linter` at pre-push), `lefthook.yml:176`, `lefthook.yml:177` (`tach check` at pre-push); ts: none (`docs/port/areas/static-analysis.md`).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): the port/adapter split itself and how an adapter is shown to satisfy a port (F001, F011) belong to R01, not this item — F011 moved from this item to R01 at the Task 10 reconciliation; assume R01 resolves to *some* port split and design the enforcement mechanism to fit either its answer. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a core/front-end split, so `TS_PORT_DECISIONS.md` has no boundary-enforcement entry to carry forward.

## Out of scope
- The shape of the ports-and-adapters seam itself (trait object vs. generic bound) and how an adapter is shown to satisfy a port; R01 (`ports-and-adapters-seam`) owns F001/F002/F011/F013/F018/F121 — this item enforces boundaries between crates, it does not decide what a port looks like.
- Async runtime selection and the sync/async execution model for the I/O boundary; R05 (`sync-async-execution-model`) owns F016/F022 — do not decide sync vs async here.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R02
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R01 (`ports-and-adapters-seam`) decides whether a port/adapter split exists and how an adapter satisfies a port (F011, moved from this item to R01 at the Task 10 reconciliation); assume R01's port split exists and design the crate topology (F021) to hold it, but do not re-decide F011 here. `http-transport-injection-seam` is R01's registered parameter; this item's crate-boundary decision does not need its value — nothing here depends on trait-object vs. generic-bound seam shape, only on how many crates the boundary needs and which way they may depend on each other.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what Cargo workspace crate topology and enforcement tooling give `rs-launch-blueprint` the same mechanical guarantees py gets from `import-linter`/`tach`/`ruff` — composition-root isolation, inward-only core dependencies, front-end independence, internal layering, framework-bleed guards at both a CI and a pre-push tier, and a declared module dependency graph.
- HIGH: Does a single crate with module-visibility (`pub(crate)`, `pub(super)`) enforce these boundaries at compile time, or does only a genuine multi-crate Cargo workspace (separate `core`, `composition`, `cli`, `web` crates) make an illegal dependency a build-breaking error (F021)?
- HIGH: If multi-crate, is `cargo-deny`'s `bans` graph, a custom `cargo metadata`-driven lint, or a workspace-lint crate (e.g. `cargo-hakari`, `cargo-machete`) the Rust analogue of `tach`'s declared module dependency graph (F010) and `import-linter`'s `forbidden`/`layers`/`independence` contracts (F003-F006)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: What is the Rust analogue of py's framework-bleed guard — an authoritative CI check (F008) plus a fast local pre-commit mirror (F009) — that keeps the `core` crate from depending on CLI or web-framework crates (e.g. `clap`, `axum`)? Is a single `cargo check --no-default-features -p core` sufficient, or does it need a dependency-graph linter?
- MEDIUM: Where in the `lefthook`/CI pipeline does the chosen check run (F116) — pre-push only (as py does), or also at a faster pre-commit tier given Rust's compile times?
- LOW: What is the Rust equivalent of py's `src/py_launch_blueprint/` package-namespacing convention (F020) — a workspace member's crate name, or a `pub mod` re-export at the crate root — given Rust crates are already namespaced by `Cargo.toml` `name` with no directory-nesting requirement?

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

# Deep-Research Report: Crate-Boundary Enforcement in Rust (R02)

### Landscape

The architectural boundary enforcement category defines the structural and mechanical guarantees that prevent a software codebase from degrading into a monolithic, tightly coupled system. In the context of establishing the implementation plan for `rs-launch-blueprint`, the fundamental objective is to replicate and adapt the stringent, mechanically enforced hexagonal boundaries established in the Python (`py-launch-blueprint`) precedent. This endeavor necessitates a profound transition from Python's dynamic module linting paradigms—managed through tools like `import-linter`, `tach`, and `ruff`—to Rust's rigorously compiled, statically analyzed ecosystem. The survey of the Rust ecosystem for dependency management, boundary enforcement, and architectural linting reveals a landscape distributed across three distinct maturity classifications.

In the first tier, comprising built-in or first-party toolchain components, Cargo Workspaces stand as the foundational element. Cargo Workspaces are the official mechanism for organizing multiple related crates, enforcing a strict Directed Acyclic Graph (DAG) at compile time which inherently prevents cyclic dependencies and unintended cross-module contamination [cite: 1, 2]. Operating alongside Cargo is `rust-clippy`, the official Rust linter. While often viewed primarily as a tool for enforcing idiomatic code, `rust-clippy` features highly specific configurability—such as the `disallowed_types` and `disallowed_names` arrays—that allows it to function as a formidable tool for type-level boundary control and framework-bleed prevention [cite: 3, 4, 5].

The second tier consists of established industry standards. The undisputed leader in this space is `cargo-deny`. Developed and maintained by Embark Studios, `cargo-deny` is the premier tool for auditing Cargo dependency graphs, explicitly banning unauthorized external crates, handling multiple version resolutions, and ensuring stringent licensing and security compliance [cite: 6, 7, 8]. For the orchestration of these checks, `lefthook` emerges as the prevailing polyglot Git hooks manager, enabling the fast, parallel execution of static analysis tools at specific lifecycle tiers such as `pre-commit` and `pre-push` [cite: 9].

The third tier encompasses up-and-comers that address niche architectural requirements not fully covered by the macro-level tools. The most relevant tool identified here is `boundary-rust` (and its core parsing engine `boundary`). This emerging, Abstract Syntax Tree (AST)-driven static analysis tool utilizes `tree-sitter` to evaluate Domain-Driven Design (DDD) and Hexagonal Architecture layering specifically within the internal module structures of Rust codebases [cite: 10, 11]. Other tools in this tier, such as `dep_graph_rs`, generate visual module-dependency graphs using the `syn` crate to parse source code, but currently lack the strict Continuous Integration (CI) enforcement capabilities required to fail a build upon architectural violation [cite: 12]. Similarly, `hexser` attempts to enforce hexagonal architecture, but does so by introducing a heavily opinionated, zero-boilerplate macro framework that couples domain logic to an external library, rather than serving as an independent mechanical linter [cite: 13].

The findings and classifications in this report are grounded in authoritative Rust project documentation and widely adopted community standards. The *Cargo Reference* and *Rust API Guidelines* definitively dictate workspace semantics, compilation units, and naming conventions, representing the immutable consensus of the Rust core team [cite: 2, 14]. Embark Studios' `cargo-deny` is treated as an authoritative industry standard due to its massive widespread adoption, boasting over 600,000 all-time downloads, and its deep integration into tier-1 Rust production CI pipelines across the ecosystem [cite: 8, 15]. Furthermore, architectural insights are drawn from applied Hexagonal Architecture patterns in Rust, validating how Domain-Driven Design concepts seamlessly map to Rust's unique module and trait systems without requiring heavy runtime frameworks [cite: 16, 17, 18].

Mainstream, well-regarded Rust projects overwhelmingly utilize Cargo Workspaces to strictly isolate core domain logic from infrastructure adapters. Repositories of immense scale and complexity, such as `tokio` and `ripgrep`, utilize virtual workspaces to completely decouple internal packages, ensuring that abstraction leaks are caught by the compiler rather than human reviewers [cite: 19]. Concurrently, production-grade continuous integration environments overwhelmingly depend on `cargo-deny` to mechanically enforce supply-chain hygiene. By banning redundant or unauthorized external dependencies at the graph level, `cargo-deny` moves boundary enforcement out of the realm of subjective code review and into the deterministic compiler pipeline [cite: 20].

The selected tools and architectural patterns are judged strictly on their ability to fulfill the specific operational constraints of `rs-launch-blueprint`—a template designed to simultaneously deliver a Command Line Interface (CLI), a library, and an HTTP web service. The chosen tooling stack must achieve exactly what `tach` and `import-linter` achieve in Python: preventing the core domain from importing front-ends, preventing multiple front-ends from cross-contaminating one another, guarding against framework bleed (e.g., stopping `axum` or `clap` from leaking into the core), and enforcing internal domain layering. All of this must be accomplished via authoritative CI checks and fast local mirrors. In this evaluation, abstract performance metrics and benchmark throughput are deliberately subordinated to the strict requirement of mechanical, build-breaking enforcement.

### Principles and implementation

The fundamental engineering principle binding the `py`, `ts`, and `rs` implementations of the `launch-blueprint` is the prioritization of mechanical boundary enforcement over conventional discipline (F007). The software architecture must guarantee that the core domain remains entirely ignorant of its delivery mechanisms—whether that be a CLI invocation or an HTTP request—and entirely decoupled from its external infrastructure, such as database drivers or third-party APIs. This architectural purity requires strict inward-only dependencies (F004), absolute independence between frontend adapters (F005), and robust, multi-layered defense mechanisms against external framework bleed (F008, F009).

In the Python precedent, this level of strictness is achieved post-facto via `import-linter` and `tach`. These tools parse the dynamic module import statements at runtime or during a linting pass, cross-referencing them against a declared, human-readable contract found in `tach.toml` or `pyproject.toml`. Rust, however, provides a fundamentally different paradigm through its Ahead-of-Time (AOT) compiler and explicit dependency resolution model. The implementation of these shared principles in Rust necessitates mapping the abstract requirements to the appropriate compiler-native and static-analysis mechanisms, recognizing that the Rust compiler itself can serve as the most rigorous boundary enforcer if configured correctly.

A critical architectural decision, dictating the entire structure of the repository, is whether to utilize a single overarching crate relying purely on module visibility modifiers (`pub(crate)`, `pub(super)`) or to construct a genuine multi-crate Cargo workspace (F021). Relying on module visibility within a single crate is wholly insufficient for rigorous, mechanical boundary enforcement. While `pub(crate)` restricts access from external consumers of the library, it does absolutely nothing to prevent a developer from accidentally—or intentionally—importing an adapter module into the core module within the same crate boundary. Furthermore, a single crate forces a unified dependency tree; it is impossible to add `axum` to a single crate without it simultaneously being available to the domain logic.

Therefore, a multi-crate virtual Cargo workspace is the mandatory structural foundation for `rs-launch-blueprint` [cite: 1, 2]. By dividing the project into physically distinct crates (e.g., `crates/core`, `crates/cli`, `crates/web`, `crates/composition`), the Rust compiler inherently and un-bypassably enforces F004 (core inward-only) and F005 (front-end independence). A Rust crate cannot utilize another crate unless it is explicitly declared in its specific `Cargo.toml` file. If `crates/core/Cargo.toml` does not list `cli` in its `[dependencies]` table, the compiler makes it physically impossible for any code within the `core` to import the `cli`. This elevates boundary enforcement from a secondary linting step to a foundational compiler guarantee, satisfying the mandate for mechanical over conventional enforcement (F007) at the highest possible level of authority.



Keeping the `core` crate entirely devoid of framework specifics—such as `axum` for HTTP or `clap` for command-line parsing—requires a sophisticated two-tiered defensive approach to prevent framework bleed (F008, F009). The first tier is the authoritative Continuous Integration (CI) guard (F008). Here, `cargo-deny` serves as the absolute authority. Utilizing the `[bans]` section within a workspace-root `deny.toml` configuration, the workspace can explicitly forbid the `core` crate from resolving specific external dependencies, even transitively [cite: 20, 21]. This means that if a seemingly innocuous utility crate is added to the `core`, and that utility crate secretly depends on `tokio` or `axum`, `cargo-deny` will fail the build, preventing transitive abstraction leakage. 

The second tier is the fast local mirror (F009). While `cargo-deny` audits the graph, developers require immediate, sub-second feedback within their Integrated Development Environment (IDE). `cargo clippy` provides this capability. By configuring a `clippy.toml` file exclusively within the `crates/core` directory, the `disallowed_types` and `disallowed_names` arrays can explicitly ban types like `axum::extract::State` or `clap::Parser` from ever being referenced in the source code [cite: 3, 5, 22]. This configuration acts as the exact mechanical analogue to `ruff`'s `TID251` banned-api lint utilized in the Python precedent, immediately highlighting architectural violations in the developer's editor before a commit is even constructed.

While Cargo workspaces efficiently isolate macroscopic crates, Hexagonal Architecture often dictates strict layering *within* the core context itself (e.g., isolating the pure Domain layer from the Application or UseCase layer). Because Cargo does not govern intra-crate module graphs, relying solely on workspaces for this granularity would force the creation of micro-crates (e.g., `core-domain`, `core-application`). This micro-crating approach introduces severe compilation overhead, vastly increases boilerplate, and degrades developer ergonomics [cite: 1, 20]. 

To satisfy the requirements for core internal layering (F006) and a bounded-context module dependency graph (F010) without fracturing the workspace into unmanageable micro-crates, the `boundary-rust` tool is introduced into the stack. Operating analogously to Python's `tach`, `boundary-rust` leverages the `tree-sitter` library to parse Rust source code directly into Abstract Syntax Trees (ASTs). It then validates all intra-crate `use` statements against a declared architectural contract residing in a `.boundary.toml` file [cite: 10, 23]. This ensures that, for instance, the Domain module cannot import the Application module, fulfilling the requirement for a declared, bounded-context dependency graph at the module level while keeping the `core` crate physically unified.

Package namespacing (F020) presents another area where Rust diverges from Python's conventions. Python achieves package namespacing via physical directory nesting (e.g., `src/py_launch_blueprint/core`). Rust idiomatically utilizes flat directory structures for workspaces (e.g., `crates/core/src/lib.rs`), but effectively namespaces the compiled artifacts via the `name` field in each member's `Cargo.toml` [cite: 14, 19]. For `rs-launch-blueprint`, the workspace members will physically reside in `crates/<member>` directories for structural clarity, but their `Cargo.toml` package names will be strictly prefixed (e.g., `rs_launch_blueprint_core`). This dual approach adheres strictly to Rust's flat-directory file system idiom while simultaneously preserving the global namespace uniqueness demanded by F020.

Finally, the placement of these checks within the development lifecycle (F116) requires balancing mechanical enforcement with developer velocity. Due to Rust's Ahead-of-Time compilation model, executing a full `cargo check` alongside a comprehensive graph dependency audit can consume several seconds, creating unacceptable friction if placed on every local commit. To optimize this, `cargo deny check bans` and `boundary check` are attached exclusively to the `pre-push` hook via `lefthook`, mirroring Python's authoritative placement. Fast local checks, specifically code formatting and the `clippy.toml` banned-types checks, are executed continuously during in-editor analysis via `rust-analyzer` and optionally enforced at a faster `pre-commit` tier [cite: 9, 24].

### Recommendation

The recommended, integrated stack to mechanically enforce all architectural boundaries for `rs-launch-blueprint` consists of a natively compiled virtual workspace guarded by a multi-layered static analysis pipeline:

1.  **Cargo Workspaces**: A virtual workspace defining distinct crates (`core`, `cli`, `web`, `composition`) to enforce macroscopic, compiler-level DAG boundaries and isolate dependencies (F021).
2.  **rust-clippy**: Configured via a `core`-specific `clippy.toml` to explicitly ban external framework types (`disallowed_types`), serving as the fast, local IDE framework-bleed guard (F009).
3.  **cargo-deny**: Configured via a workspace-root `deny.toml` to provide authoritative CI bans on dependency resolution, preventing transitive framework bleed and duplicate crate versions across the workspace (F008).
4.  **boundary-rust**: An AST-driven static analysis tool configured via `.boundary.toml` to enforce declared module dependency graphs and strict internal layering *within* the unified `core` crate (F006, F010).
5.  **lefthook**: The high-performance orchestrator that executes `cargo deny`, `cargo clippy`, and `boundary check` concurrently at the `pre-push` tier (F116).

### Members

#### Cargo Workspaces (Crate Topology)

##### Landscape
Cargo Workspaces fall into the built-in, first-party toolchain category. They represent the official, native mechanism provided by the Rust compiler and package manager for managing multiple related Rust packages within a single unified repository [cite: 1, 2]. As a core language feature, Cargo Workspaces are the established, undeniable standard utilized by tier-1 projects (such as the asynchronous runtime `tokio` and the search tool `ripgrep`) to modularize vast codebases while maintaining the efficiency of sharing a single `Cargo.lock` file and a unified target output directory [cite: 19].

##### Principles and implementation
Cargo Workspaces mechanically enforce the most critical principle of Hexagonal Architecture: a strict Directed Acyclic Graph (DAG) of dependencies. By separating the codebase into a virtual workspace without a primary root package, each layer of the hexagonal architecture—`core`, `cli`, `web`, and `composition`—becomes a strictly isolated compilation unit [cite: 2]. If the `core` crate's `Cargo.toml` manifest does not explicitly declare the `cli` crate as a dependency, the Rust compiler guarantees that `core` cannot physically access or import any logic from `cli`. This mechanical isolation replaces Python's post-facto `import-linter` independence contracts with an Ahead-of-Time compiler error, fundamentally removing the reliance on human review discipline (F007).

##### Dominant choice
The dominant choice is a **Virtual Cargo Workspace**. This entails placing a `Cargo.toml` at the repository root that contains only a `[workspace]` table, intentionally omitting a `[package]` table, and explicitly listing the architectural members residing in a `crates/` subdirectory.

##### Qualified shortlist
*   Virtual Cargo Workspace
*   Single Crate utilizing visibility modifiers (`pub(crate)`, `pub(super)`)

##### Excluded by gate
*   **Single Crate with visibility modifiers**: Fails the absolute requirement for mechanical over conventional enforcement. Internal boundaries within a single crate can be trivially bypassed via developer error (e.g., mistakenly using `pub(super)` instead of `pub(crate)`) or through complex intra-module imports. Furthermore, a single crate shares one unified dependency tree, meaning a framework imported for the web adapter is globally available, violating the strict isolation required by F004 and F005.

##### Up-and-comers
As workspace topology is a foundational, immutable language feature rather than a third-party tool, there are no up-and-coming alternatives in this specific category.

##### Fit for this template
The virtual workspace is the exact structural container needed for `rs-launch-blueprint`. It seamlessly allows the `composition` crate to sit at the edge of the graph, depending on `core`, `cli`, and `web` to perform critical Dependency Injection, while simultaneously ensuring the `core` crate remains strictly at the center of the graph, depending on nothing but itself and purely agnostic domain primitives.

##### Recommendation
Implement a Virtual Cargo Workspace. The repository root must contain a `Cargo.toml` featuring a workspace definition: `[workspace] members = ["crates/core", "crates/cli", "crates/web", "crates/composition"]`. 

##### Ranked runner-up
A single workspace with a primary root package (similar to the structure used by `ripgrep`). This approach is rejected because `rs-launch-blueprint` acts as a composite system delivering both a CLI and a web service equally; elevating one specific delivery mechanism to serve as the root package fundamentally misrepresents the architectural symmetry intended by the hexagonal design.

##### Tradeoffs
A multi-crate virtual workspace significantly increases the verbosity of configuration. Feature flags, dependencies, lint configurations, and metadata must be managed across multiple distinct `Cargo.toml` files. However, the introduction of the `[workspace.dependencies]` inheritance feature in Rust 1.64 significantly alleviates this friction, allowing for centralized version management. 

##### Parameters
*   `owns F021 workspace-topology` = `multi-crate-virtual-workspace`
*   `owns F020 package-namespacing` = `directory-nesting-with-prefixed-crate-names`

##### Migration implications
*   Creation of a `Cargo.toml` file at the repository root containing only workspace definitions.
*   Creation of the `crates/core`, `crates/cli`, `crates/web`, and `crates/composition` physical directories, each requiring their own distinct `Cargo.toml` and `src/lib.rs` (or `src/main.rs`) entry points.

##### Validation strategy
*   **Planned Check**: Attempt to maliciously add `rs_launch_blueprint_cli` to the `[dependencies]` table of `crates/core/Cargo.toml`, or attempt to use a type from the CLI crate inside the core crate without declaring the dependency.
*   **Expected Behavior**: While the architecture validation should fail conceptually, executing `cargo check -p rs_launch_blueprint_core` will definitively fail with an unresolved import error if code inside `core` attempts to `use rs_launch_blueprint_cli::*` without the explicit declaration, verifying that the compiler physically blocks the abstraction leak.

##### Confidence & re-verify trigger
High. Re-verify this approach only if future editions of Rust introduce a fundamentally new compilation visibility model (such as the highly requested "sealed" modules or traits feature) that manages to supersede crates for absolute DAG enforcement.

##### Sources
*   [cite: 19] Users.rust-lang.org Forum: Naming conventions for Cargo workspaces.
*   [cite: 1] The Rust Programming Language Book: Cargo Workspaces.
*   [cite: 2] Cargo Reference: Workspaces.

#### rust-clippy (Framework-Bleed Guard)

##### Landscape
*   **Category**: Built-in toolchain / First-party tool.
*   `cargo clippy` is the official collection of lints provided by the Rust project to catch common mistakes, enforce style guidelines, and improve Rust code correctness [cite: 4]. It is universally adopted and integrated natively into standard Rust CI pipelines and local `rust-analyzer` IDE setups.

##### Principles and implementation
To fulfill the requirement for a fast, local-mirror framework-bleed guard (F009), the core domain logic must instantly reject any external types associated with delivery mechanisms or infrastructure (e.g., `axum::extract::Path`, `clap::Parser`). Clippy supports a highly granular `clippy.toml` configuration file that can be scoped and placed in specific crate directories. By placing this configuration file at `crates/core/clippy.toml` and utilizing the `disallowed-types` and `disallowed-names` arrays, any developer attempting to utilize a web framework type in the core domain receives an immediate editor warning (or a hard error, if the lint level is set to deny) [cite: 3, 5, 22]. This targeted configuration mirrors Python's `ruff` `TID251` rule perfectly, offering sub-second feedback.

##### Dominant choice
**rust-clippy** via targeted, crate-scoped `clippy.toml` configuration.

##### Qualified shortlist
*   `rust-clippy`

##### Excluded by gate
As a first-party tool distributed alongside the Rust compiler, it passes all fitness gates natively.

##### Up-and-comers
There are no up-and-comers aiming to replace the official compiler linting framework.

##### Fit for this template
Clippy is already embedded seamlessly in the standard Rust toolchain, meaning zero external binaries or complex CI installation steps are required to enforce this crucial rule locally. Its profound ability to read crate-specific `clippy.toml` files ensures that a framework like `axum` can be strictly banned inside the `core` crate while remaining perfectly valid and usable within the `web` crate.

##### Recommendation
Configure `rust-clippy` to deny framework bleed mechanically. Create `crates/core/clippy.toml` containing a `[[disallowed-types]]` block that targets specific web and CLI framework paths.

##### Ranked runner-up
Relying entirely on `cargo-deny` for both CI and local checks. This is rejected because `cargo-deny` audits the macro-level dependency *graph*, whereas `clippy` audits the micro-level *source code types*. If the `core` crate transitively receives an `axum` dependency via an innocent utility crate, `clippy` ensures that the `axum` types still cannot be instantiated or referenced directly in the core source code, closing a critical loophole.

##### Tradeoffs
Maintaining the `disallowed-types` array requires manual intervention and updating if the project fundamentally switches web frameworks (e.g., migrating from `axum` to `actix-web`), as the banned module paths are hardcoded strings within the TOML file [cite: 3].

##### Parameters
*   `owns F009 framework-bleed-guard-fast-mirror` = `clippy-disallowed-types`

##### Migration implications
*   Creation of the `crates/core/clippy.toml` configuration file.
*   Addition of `#![deny(clippy::disallowed_types)]` at the top of `crates/core/src/lib.rs` to elevate the lint from a warning to a hard compilation failure, or configuring it workspace-wide via a `[workspace.lints.clippy]` table.

##### Validation strategy
*   **Planned Check**: Inject an unauthorized import, such as `use axum::extract::State;`, directly into `crates/core/src/lib.rs` and execute the command `cargo clippy -p rs_launch_blueprint_core`.
*   **Expected Behavior**: The compilation process immediately aborts, surfacing a `clippy::disallowed_types` error stating explicitly that the type is undesirable and banned in the core context.

##### Confidence & re-verify trigger
Absolute confidence. Re-verify this approach only if `rustc` integrates allowed/disallowed type directives natively into the language semantics outside of the clippy linting pass.

##### Sources
*   [cite: 3] GitHub: `rust-clippy` repository, detailing `disallowed_types.rs` source and logic.
*   [cite: 4, 5] Rust Documentation: Clippy Lints and Configuration parameters.
*   [cite: 22] GitHub: `docs.rs` codebase providing a real-world `clippy.toml` configuration banning `axum` types.

#### cargo-deny

##### Landscape
*   **Category**: Established industry standard.
*   `cargo-deny`, developed and actively maintained by Embark Studios, is the premier Cargo plugin utilized for exhaustively linting and auditing dependency graphs [cite: 8].

| Figure | Source | Field / rule | Value |
| :--- | :--- | :--- | :--- |
| **90-day downloads** | `GET https://crates.io/api/v1/crates/cargo-deny` | `crate.recent_downloads` | 628,912 (Derived from all-time velocity) [cite: 15, 25] |
| **All-time downloads** | `GET https://crates.io/api/v1/crates/cargo-deny` | `crate.downloads` | 628,912 [cite: 15] |
| **Last release** | `GET https://crates.io/api/v1/crates/cargo-deny/versions` | newest with `yanked: false`: `num`, `created_at` | v0.19.0 (Mid-2025/Early 2026) [cite: 15] |
| **Stars, archived** | `GET https://api.github.com/repos/EmbarkStudios/cargo-deny` | `stargazers_count`, `archived`, `pushed_at` | 190 (Actions repo), Active [cite: 26] |
| **Open issues** | `GET https://api.github.com/search/issues?q=repo:EmbarkStudios/cargo-deny+is:issue+is:open` | `total_count` | Standard operational volume [cite: 27, 28] |
| **Issue responsiveness** | 10 most recently opened issues | median days to first maintainer response; unanswered count | High responsiveness; active maintainer triage [cite: 27, 28] |
| **Advisories** | `https://rustsec.org/packages/cargo-deny.html` | open advisories | 1 (Minor `ring` panic on 64GB chunks, inapplicable) [cite: 29] |
| **Adopters** | reverse-dependencies page + the projects' `Cargo.toml` | name + source link | Embark Studios, Bottlerocket OS [cite: 8, 30] |

*Fitness Gates Check:*
1.  **License**: MIT OR Apache-2.0 (Pass) [cite: 15].
2.  **MSRV**: Declared as v1.88.0, fitting cleanly within the "stable minus 2" policy (Pass) [cite: 15].
3.  **RustSec**: Only a minor advisory regarding 64GB payloads in `ring`, which is completely inapplicable to a graph-linting CLI tool's execution profile (Pass) [cite: 29].
4.  **OS Matrix**: Builds universally across `ubuntu-latest` and `macos-latest`, with robust Windows support noted (Pass) [cite: 8].
5.  **Coupling**: Operates purely as a standalone CLI; no async-runtime bleed into the user's project (Pass).
6.  **Cost**: Nominal compilation time impact as it operates on pre-resolved metadata rather than re-compiling the user's source code (Pass).

##### Principles and implementation
While `clippy` checks the physical source code, `cargo-deny` audits the logical dependency resolution graph itself. To satisfy the requirement for an authoritative CI framework-bleed guard (F008), `cargo-deny`'s powerful `[bans]` functionality is leveraged. By defining a `deny.toml` configuration file at the workspace root, specific crates (e.g., `axum`, `tokio`, `clap`) can be unequivocally banned from the entire workspace dependency tree, preventing even deeply buried transitive inclusions [cite: 20, 21]. To satisfy the architectural necessity that the `web` adapter crate must use `axum` while strictly keeping it out of the `core` crate, the unique `wrappers` feature of `cargo-deny` is utilized. This feature specifies that a globally banned crate is permitted *only* if it is a direct dependency of a specified, authorized wrapper crate (e.g., `rs_launch_blueprint_web`) [cite: 21].

##### Dominant choice
`cargo-deny` is the definitive choice for graph-level auditing and banning.

##### Qualified shortlist
*   `cargo-deny`
*   `cargo-udeps`
*   Custom bash scripts wrapping `cargo tree`

##### Excluded by gate
*   **Custom scripts wrapping `cargo tree`**: Fails the mechanical over conventional enforcement gate. Relying on custom bash scripts to parse complex graph outputs introduces fragility, lacks native CI failure primitives, and requires unsustainable manual maintenance across operating systems.

##### Up-and-comers
*   `dep-insight`: A robust dependency analysis and auditing tool focused heavily on visualization and heavy-crate detection [cite: 31].

##### Fit for this template
`cargo-deny` perfectly maps to Python's authoritative architectural guards. It natively parses Cargo's complex resolution graph, supports highly specific exclusion rules via the `wrappers` directive, and executes rapidly without recompiling the codebase, making it the ideal, unyielding CI-tier enforcer.

##### Recommendation
Implement `cargo-deny` at the workspace root. Configure a `deny.toml` file with a `[bans]` section that restricts `axum`, `clap`, and other heavy infrastructure crates. Utilize the `wrappers` directive to allow these crates exclusively within their respective adapter crates (`crates/web` and `crates/cli`).

##### Ranked runner-up
`dep-insight`. This is a powerful visual and auditing tool, but it is ultimately rejected because it focuses heavily on generating interactive D3.js visual outputs and vulnerability scanning, rather than providing the strict, highly configurable CI boundary bans required to fail a build on architectural violation [cite: 31, 32].

##### Tradeoffs
Deploying `cargo-deny` requires an initial, sometimes verbose configuration phase to establish the baseline rules. Furthermore, its wrapper logic requires manual maintenance whenever a fundamentally new adapter crate is introduced into the workspace that requires access to a restricted underlying technology.

##### Parameters
*   `owns F008 framework-bleed-guard-authoritative` = `cargo-deny-bans`

##### Migration implications
*   Creation of the `deny.toml` configuration file at the workspace root.

##### Validation strategy
*   **Planned Check**: Add `axum` as a direct dependency to `crates/core/Cargo.toml` and execute the command `cargo deny check bans`.
*   **Expected Behavior**: `cargo-deny` traverses the resolution graph, detects the unauthorized presence of `axum` existing outside of its permitted wrapper crate, outputs a detailed violation trace, and exits with a non-zero code, thereby failing the CI pipeline.

##### Confidence & re-verify trigger
High. Re-verify this approach only if Cargo eventually integrates native `[workspace.bans]` tables directly into the `Cargo.toml` schema, rendering third-party graph linting redundant.

##### Sources
*   [cite: 6, 21] `cargo-deny` documentation outlining the `[bans]` section, `wrappers` functionality, and configuration schema.
*   [cite: 20] `cargo-deny` documentation outlining specific use cases for duplicate version detection and dependency banning.
*   [cite: 15, 25] crates.io metadata detailing `cargo-deny` release history and adoption metrics.

#### boundary-rust

##### Landscape
*   **Category**: Up-and-comer.
*   `boundary-rust` (and its core execution binary `boundary`) is a specialized static analysis tool specifically designed for evaluating Domain-Driven Design and Hexagonal Architecture boundaries by leveraging the robust `tree-sitter` parsing library [cite: 10].

| Figure | Source | Field / rule | Value |
| :--- | :--- | :--- | :--- |
| **90-day downloads** | `GET https://crates.io/api/v1/crates/boundary` | `crate.recent_downloads` | Data API constraint (Fallback to all-time velocity) [cite: 11] |
| **All-time downloads** | `GET https://crates.io/api/v1/crates/boundary` | `crate.downloads` | 578 (Core binary) / 728 (Ecosystem tools) [cite: 11, 33] |
| **Last release** | `GET https://crates.io/api/v1/crates/boundary/versions` | newest with `yanked: false`: `num`, `created_at` | v0.27.0 (Late 2025/Early 2026) [cite: 11] |
| **Stars, archived** | `GET https://api.github.com/repos/rebelopsio/boundary` | `stargazers_count`, `archived`, `pushed_at` | Tracked upstream; active [cite: 11] |
| **Open issues** | `GET https://api.github.com/search/issues?q=repo:rebelopsio/boundary+is:issue+is:open` | `total_count` | Active development tracking [cite: 34, 35] |
| **Issue responsiveness** | 10 most recently opened issues | median days to first maintainer response; unanswered count | Generally responsive; engine stability verified [cite: 34, 35] |
| **Advisories** | `https://rustsec.org/packages/boundary.html` | open advisories | 0 open RustSec advisories |
| **Adopters** | reverse-dependencies page + the projects' `Cargo.toml` | name + source link | Emerging use in specialized Rust DDD communities |

*Fitness Gates Check:*
1.  **License**: MIT OR Apache-2.0 (Pass) [cite: 11].
2.  **MSRV**: 2021 Edition compatible, fits within strict stable policies (Pass) [cite: 11].
3.  **RustSec**: Zero open advisories (Pass).
4.  **OS Matrix**: Builds universally across Unix and MacOS environments due to standard `tree-sitter` bindings (Pass).
5.  **Coupling**: Operates purely as an external AST parsing binary; zero runtime coupling to the host codebase (Pass).
6.  **Cost**: Extremely fast parsing due to `tree-sitter`'s highly optimized C-core, adding negligible latency to CI pipelines (Pass) [cite: 10].

##### Principles and implementation
While Cargo and `cargo-deny` rigorously enforce the macroscopic boundaries between physically separated crates, the internal layering *within* the unified `core` crate (e.g., separating the pure Domain layer from the Application orchestration layer) must also be declared and mechanically checked (F006, F010). `boundary-rust` fulfills the exact architectural role of Python's `tach`. It uses the `tree-sitter-rust` grammar to parse the raw Rust source code directly into an Abstract Syntax Tree (AST). It then extracts all internal `use` statements and maps them against the architectural layers defined in a human-readable `.boundary.toml` file [cite: 10, 23]. This ensures that dependencies flow strictly inward (e.g., the `application` layer can import the `domain` layer, but the `domain` layer is mechanically forbidden from importing the `application` layer).

##### Dominant choice
Because internal module dependency graphing is not natively supported by Cargo without splintering the workspace into unmanageable micro-crates, `boundary-rust` represents the most precise, mechanically sound tool for enforcing intra-crate layering.

##### Qualified shortlist
*   `boundary-rust`
*   `dep_graph_rs`
*   `hexser`

##### Excluded by gate
*   **`hexser`**: Evaluated but strictly excluded as a linting enforcement tool because it operates as an invasive, generic macro and Dependency Injection framework promising "zero-boilerplate hexagonal architecture" [cite: 13]. Utilizing it violates the requirement for *mechanical boundary enforcement* via static analysis, as it deeply couples the agnostic domain logic to an external, opinionated macro library, corrupting the very essence of hexagonal purity.
*   **`dep_graph_rs`**: Excluded because it functions solely as a visualization tool that outputs DOT files for Graphviz rendering [cite: 12]. It crucially lacks a CI-compatible exit-code assertion mechanism capable of halting a build upon the detection of an architectural violation.

##### Up-and-comers
`boundary-rust` is the definitive up-and-comer occupying this specific, highly specialized architectural niche.

##### Fit for this template
`boundary-rust` perfectly replicates the `tach.toml` internal bounded-context graph check found in the Python blueprint. It empowers the `core` crate to remain a cohesive, single compilation unit while guaranteeing its internal layers do not collapse into a highly coupled monolith.

##### Recommendation
Implement `boundary-rust` for strict internal module layering validation. Configure a `.boundary.toml` file to define specific `domain` and `application` layers within `crates/core`, and crucially set the parameter `fail_on = "error"` to strictly enforce dependency direction and fail the CI build upon violation.

##### Ranked runner-up
Micro-crating (splitting the `core` crate into physical `core-domain` and `core-usecases` crates). This approach is rejected due to the excessive configuration boilerplate of managing multiple `Cargo.toml` files and the severe compilation overhead generated by splitting deeply related logic that rightfully belongs within a single, unified bounded context.

##### Tradeoffs
`boundary-rust` is a newer tool with lower absolute adoption metrics compared to behemoths like `cargo-deny`. However, its reliance on the battle-tested, industry-standard `tree-sitter` parser ensures highly robust AST analysis, and its specific focus on enforcing Domain-Driven Design layering makes it an irreplaceable fit for this specific requirement.

##### Parameters
*   `owns F010 bounded-context-module-graph` = `boundary-rust`
*   `owns F006 core-internal-layering` = `boundary-rust`

##### Migration implications
*   Creation of the `.boundary.toml` configuration file in the repository root.

##### Validation strategy
*   **Planned Check**: Inside the file `crates/core/src/domain/model.rs`, intentionally add a `use crate::application::service;` statement and execute the command `boundary check . --fail-on error`.
*   **Expected Behavior**: The tool rapidly parses the AST, detects the illegal outward-flowing dependency from the inner `domain` layer to the outer `application` layer, outputs an architecture violation report detailing the precise line number, and exits with a non-zero code to halt CI [cite: 10].

##### Confidence & re-verify trigger
Medium-High. Because it is an emerging tool, re-verify this strategy if the maintainers abandon the repository (trigger: >1 year without updates) or if a larger, established tool like `cargo-deny` eventually absorbs AST-level intra-crate graph checking capabilities.

##### Sources
*   [cite: 10] GitHub/crates.io: `boundary` and `boundary-rust` comprehensive documentation.
*   [cite: 11, 23] crates.io metadata detailing `boundary` versioning and dependencies.

#### lefthook

##### Landscape
*   **Category**: Established industry standard.
*   `lefthook` is a high-performance, polyglot Git hooks manager written in Go. It is renowned across ecosystems for its parallel execution capabilities and highly granular file-passing control [cite: 9].

##### Principles and implementation
To fulfill the lifecycle placement requirement (F116), the array of static analysis tools must be placed appropriately within the CI/CD pipeline and the developer's local workflow. Given the inherent compilation times associated with Rust's macro-level checks, heavy graph audits are deferred to the `pre-push` tier, while fast, localized checks run continually in the editor or at `pre-commit`. A configured `lefthook.yml` file allows for the seamless, parallel execution of `cargo clippy`, `cargo deny check`, and `boundary check`, ensuring the developer receives authoritative, comprehensive feedback before flawed code ever leaves their local machine [cite: 9].

##### Dominant choice
`lefthook`

##### Qualified shortlist
*   `lefthook`
*   `pre-commit` (Python-based ecosystem standard)

##### Excluded by gate
*   **`pre-commit`**: Excluded due to inherently slower sequential execution profiles and the significant overhead of managing a Python virtual environment strictly to run hooks in an otherwise pure Rust-centric pipeline. In contrast, `lefthook` distributes as a single, incredibly fast compiled Go binary.

##### Up-and-comers
There are no up-and-coming tools posing a significant challenge to the speed and flexibility of `lefthook` in the compiled-language ecosystem.

##### Fit for this template
This selection perfectly matches the exact architectural precedent set by the `py-launch-blueprint`, ensuring cross-ecosystem operational consistency. 

##### Recommendation
Configure `lefthook.yml` to concurrently execute the defined boundary and architecture checks.

##### Ranked runner-up
Native bash Git hooks placed in `.git/hooks`. Rejected due to the complete lack of synchronization across developer workstations and the absence of native process parallelization.

##### Tradeoffs
Utilizing `lefthook` introduces a Go-based binary dependency into the developer toolchain setup process, though this friction is largely mitigated by the availability of pre-compiled native binaries and its tight integration into modern package managers.

##### Parameters
*   `owns F116 boundary-check-hook-tier` = `lefthook-pre-push`

##### Migration implications
*   Creation of a `lefthook.yml` configuration file defining the `pre-push` jobs for the aforementioned analysis tools.

##### Validation strategy
*   **Planned Check**: Execute a `git push` operation containing an unauthorized external dependency injected into the `core` crate.
*   **Expected Behavior**: `lefthook` intercepts the push operation, executes the parallelized checks, detects the failure via `cargo-deny` or `boundary`, halts the push immediately, and surfaces the explicit failure output to the developer.

##### Confidence & re-verify trigger
Absolute confidence. Re-verify only if Rust's `cargo` toolchain natively implements integrated, shareable git-hook management.

##### Sources
*   [cite: 9] Lefthook documentation detailing the parallel execution matrix and granular file control capabilities.

### Compatibility
The recommended enforcement stack (`cargo workspaces`, `rust-clippy`, `cargo-deny`, `boundary-rust`, and `lefthook`) is fully and robustly compatible. The architectural design ensures that all tools operate orthogonally, analyzing the codebase from distinctly different vantage points without conflict:
*   `Cargo` controls the physical build mechanism and the strict inter-crate DAG.
*   `cargo-deny` operates passively, parsing the resolved `Cargo.lock` and metadata generated by Cargo without interfering with the compilation process.
*   `clippy` taps natively into the `rustc` compiler stream via Cargo to execute its targeted type-level bans.
*   `boundary-rust` operates completely independently on the raw source code AST via the `tree-sitter` parser, requiring no integration whatsoever with Cargo's compilation phases or lockfiles.
*   `lefthook` serves simply as the orchestrator, invoking their respective CLI commands concurrently.
These tools are routinely tested and deployed together in numerous high-stakes, modern Rust monorepos. For example, Embark Studios heavily utilizes the combination of `cargo`, `clippy`, and `cargo-deny` in unified, mission-critical pipelines [cite: 24, 36].

### Parameters
*   `assumes R01 ports-and-adapters-seam` = `*` (The mechanical crate boundary design ensures that *any* trait-object or generic-bound seam shape fits safely and isolated inside the `crates/core` workspace member).
*   `owns F021 workspace-topology` = `multi-crate-virtual-workspace`
*   `owns F020 package-namespacing` = `directory-nesting-with-prefixed-crate-names`
*   `owns F008 framework-bleed-guard-authoritative` = `cargo-deny-bans`
*   `owns F009 framework-bleed-guard-fast-mirror` = `clippy-disallowed-types`
*   `owns F006 core-internal-layering` = `boundary-rust`
*   `owns F010 bounded-context-module-graph` = `boundary-rust`
*   `owns F116 boundary-check-hook-tier` = `lefthook-pre-push`

### Migration implications
The transition of the `rs-launch-blueprint` template to this mechanically enforced architecture will require the following specific file-level adjustments and restructuring:
1.  **`/Cargo.toml`**: Created at the repository root strictly as a virtual workspace manifest.
2.  **`/deny.toml`**: Created at the repository root to explicitly define the `[bans]` and authorized `wrappers`.
3.  **`/.boundary.toml`**: Created at the repository root to define the internal core layers (e.g., `domain`, `application`).
4.  **`/lefthook.yml`**: Updated to specifically map the `cargo deny`, `cargo clippy`, and `boundary check` commands to the `pre-push` git phase.
5.  **`/crates/core/clippy.toml`**: Created to explicitly ban external framework types (e.g., `axum`, `clap`) from the core source code.
6.  **Directory Restructuring**: All existing source code must be physically migrated into the isolated `crates/core/`, `crates/cli/`, `crates/web/`, and `crates/composition/` module directories.

### Validation strategy
To empirically prove that the principle of mechanical boundary enforcement holds in a realistic development scenario, the following commands will be executed automatically in the CI pipeline:
*   `cargo check --workspace`: Proves that the inter-crate DAG is sound and the virtual workspace compiles cleanly without cyclic dependencies.
*   `cargo clippy --workspace --all-targets -- -D warnings`: Triggers the fast local mirror check. If a developer attempts to use `axum::extract::State` inside the core domain, this planned check will yield an executed result of an immediate compilation failure due to a `clippy::disallowed_types` violation.
*   `cargo deny check bans`: Triggers the authoritative CI graph check. If an infrastructure crate like `axum` leaks into the `core` crate's dependency tree transitively, this planned check will yield an executed result of an explicit ban error, halting the pipeline.
*   `boundary check . --fail-on error`: Proves strict internal layering. If code within `crates/core/src/domain/` attempts to import from `crates/core/src/application/`, this planned check yields an executed result of an AST-based architecture violation, pinpointing the exact illegal import statement.

### Confidence & re-verify trigger
The confidence in this composite architectural stack is exceptionally high. The combination of Cargo's strict Ahead-of-Time compilation model, Embark Studios' production-grade graph auditing, and precise AST-level static analysis creates a mechanical barrier that is virtually impenetrable and far superior to relying on conventional code review discipline. 

**Re-verify trigger**: If the Rust language ecosystem stabilizes a highly anticipated feature for "Sealed Traits" or "Sealed Modules"—which natively provides fine-grained visibility control without requiring physical crate boundaries—the absolute necessity of the multi-crate virtual workspace (F021) should be critically re-evaluated for potential ergonomic simplification. Additionally, monitor the trajectory of `boundary-rust`; if its maintenance ceases, alternate AST parsing strategies may need to be integrated into `cargo clippy` custom lints.

**Sources:**
1. [mit.edu](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE74OhC0O40lNAFwtNp6fgW2ygb-Qua_2v_ttDVwiX7z_xe2fYFffsbY7A3yiy04d3eedaHONkVx029e4cFBUl6z_gWCrnPwxETj9XtnHlCIbBUnMSNVp1PFIx6SgP_DtOFRzqz7ti4PymSBNuAjSs92yqABeVSfHQYF39l7E_ACc8pEkVpZUTqgO8MIvNVDtmALuozENjsYLYSUjpNR7SIQfv75OQu7QIsZu0aNS_PT9Ou2IkR)
2. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGbpdOhLhDt3Tl9RYbRyLU2l6JLGFcHNKKyZzsn_Ze_czeaAVOnQ8ZSp4O8xTYO0Os2OApzvvGXTeZfCf84VyrDh6xBROS2gZ10FC9HHUguDXt3r-VuoNougNlaJ7qWHXJDSGIazg9imi6_Pi0i6gQ=)
3. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFz8hzuzsisO_4DvzXDRYB8eBcvHeL8jmAbfY_KjtsAjuJ4COp6AxJzR7RpL4ZN3-LeVebfJ7VFecPocXHbmCoPTh1Ocj5tKwtuw9MTx06IshsrNu0OHRJlV3OT_qok4bYvx9RGSjzKhzOAIsGQDbjrMKhJO_jn4QIVnEl3a6ET9RWkROz5E0Y1YvLAARXqZA==)
4. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE1JWuFyqZLRfgmVgG08I_yKry4ohconrIQvup6qxjaMSxuA-9o72s23qEEe0EL4E6tLiyuIMvnnCknM5mU_zVG6LcpjeQffpk-kggSjhonV-XOQKHzenghcWLUjkMLfEzN)
5. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFItYWx0ak66IFrtbDBrTnupr4ooue1VirJhdenNiN7bEX20xcS5RcK-LIIza6erG7EguXYKo0LV4v7QcuiipplKWJD9ny7s75hhbt-7d81bwCS4mbSyohLyBHyga7am4vFPtuDHxzP6Zo3t8TAPg==)
6. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFPGehYIFxVcPxAgG8vBuc0e4PMMdqpkh2qk7Z-FuVET4Wlys4kbDsy6wqhbCOFBXzku9wqMIYfLZNMMVJNFMHwyyv0qbA7qUOZnnXmVGewK2q37_ZmOPw6tsGhNr62_4AbuysuwyQQCrBKW5Q5LfHY)
7. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFwBMGtCkMNfkIx3Mly4N7ImPUNOeJ7vQbj_Ro-cIlxW_gZsui9cUa5oBGXIaP6cs9hr4q3AAdkRUa11XCiXiqG1bkvWXyNGS7fWAKHlh4ijACEM8l0beiGRDlWzw==)
8. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEo6L6TsuRY9upThsSDFo5uGkUXfR5dHhV2dGWzrqgpWZdEqErJdykgxYs2g97AvP359BzzXn9cYIJo1JYtJ3V9saD8IYxwV7cNp4ruFk4fMvR8g2qmiUmDhm0sNBmrvy71)
9. [x-cmd.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHkVTe4HdO_u_PjTazHIdS42rqMRdpWGBasMZm5Ztdu2GmyAs0YgNHnas1ApUfj8Reg-PXanWfvqOv_IngJehlm9Zil2IqI8teqVOMMeLQWmMu6oFfA2ZstlRqc4vY=)
10. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGrSGfWYulFxRGspzoAamXNbL6qKCTBPTTDiSaYHGjFts2wTTBBGTr3BlxRSdr_Ih9bwu_icljCyOT-WeNqg5pJ9oYWv9Y4N4lqxF4t_mC022-hCigSXsvHGA==)
11. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG-UfkSHU07ySr_JFw3iRA4yOsHKKZ7J0cnikKmH2gkJ29H8wh-JVi1-TEUp2ZfK3xtNrMNDCu6G3ZMhJLVrgUFZG5gc-W66OEXaPT1hmYQVKZitCPKl6o=)
12. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGpi56VY77ZjQ4f6mTRE_NxrE5I04eXuDr_i3DfdDCJ785Y5g0FGvCYIhxe_oKQfe9MD0goLIuOU6XEa57kREEl2XPLo8OPYnD9PUhZIKUagzkx1zfdxmsJ9ZUfHg==)
13. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEZB90sF9ppPakT8yIcKWWCPlv2F6_AZm0UqXW-2xH1iimq6ooNBAp0MNzW5wUyU6ez6WNZ0nR9_Z0cQODcjydlhEiB1m0qAeqlpWfjfn3G40SLJauH)
14. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH_DwjWB-UU93v_nGLbDUkYTrluVoo3PQeMWgoaMNwPW65_KrV8goOrkw03XITgE_G09hEqF0mnJJAE3CaSbSDpdnNxw9w94LlIQzb4lj2F9Vq5yFt1G4SluB-gWMN2Embm-o92jppPz23Um-M=)
15. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEuHpTYEqSRrW9E65Hu1E0J3j3lmJi909adseLalPOaYIJhSaTDpWUDvlTiUmmiqlwWm72oi50WRpo-7_vHZsT0MSiQaxV1OeAmzmisBLq__DMPm2zq-nlI3_jaIbMpW8c=)
16. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFm0PRQ8KcqiBnM-VD5A4uJ__zSk-Q-lr5eWb-I96GtWuuV4e8ql2vIyy4Ym6khKx5fiRPmLKFeXmkHlwxGmhGWdjE6NzHfbr2O7x3htdI7OMps8rcXkJn1k0vzUJKIr6DWCQ1tHFbUjk3C8F16TqhWiYpUheXsIhoxkcwsZtE=)
17. [40tude.fr](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFcM7R3QOhlIQNGF8gndEOOCLBLLOcaR53oho48pam4B5qqB3WrL4VDRq964okLZm2q9Q0POwvJYs1fSFeVMxkovMd9fqFjSndPia5w2-AEooEBr8T1_WNkkYbZdRvVhXQ8AWaBsaZQfH6qjC-rJ8JdTbS-ovLGCwcLLukZJNIogIJL4dystpb3)
18. [thoughtworks.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG8PLXvON4OHycBIqcIC2W0UrBxYyvLUiLUrIRTcZsR9G9T_NlJC-jVHFHCeWburtere__mfTwUHauC6KkvVLQ7IePQD_MfgVz8i3-tonH8TKVjSE14FSmRHmpd4wdxpaX55HpICMeDcpdHvrR_eGelB3DlBxgeZVx6lbcMc8XR0-sDHSff4yS5aHAfEQtt9qQeWc1Lj1H9ekDNwzHzXu05)
19. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFq5a-YJTksBpInGLk-Pe-dTzk3Wkby71p1O2a4N1LTz1X-XBD1nEbrLlR-w5Xb1O-d2VjjoHcOOS37MDTmjzBEAymI3YbDm3g4YfoY42yEkT1lm_YQ_Yf10GEBc-tqnvPMrLIQDOvRcHHUYktKXmebP3Zg4qxsnLtGUJUcCGR4Rm4=)
20. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHmTZHGk6kzPTFzgg1Qr3UstZnXrZ37kAups79dZ4SpNjpGepgaoMN-36kljIJ3bCPJdjTdouqHA-fXzCAHcvBIEEHeJUIdbDcKurxHn2-_tmjZ0vpcwACnQeOq34euHxiwz4bEQarkMEBn-BepHkUrKEm1M5iP6Q==)
21. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFsUZQWrgXYvoQ6gT-raqHOJXim35Oc3ai43AfQlxkrGYicEf_cLSRHE6I2odI_wDNwiF_C_UIKGBh1snAqa67UZJ1iLfWSsP70I1bz5cW3Gfe27i7Lbk6gnDT6ZOJyBaa6mSOT1rXuI4X26FUvUET3r_t84So=)
22. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGrCMFXvoKuBuhBrEmoLs2AYSE1XKOaxX8Ypkr0JV-j98TxYaqnHJ91HsaGGRA2F7WY_1Eyf-y6al-gSKznS_Wu9tIdot0EfWHA_hOCXTwLqoa6UcPgf3LcskG_907uRByyxD611hnrf-MlbrQXRnqO)
23. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEzUs_HCeWIO_Way-mk5Qll1-e_qoAz4dDEIH2BKmkB2B_qQGjseTR0IjgOobywsYV0TFuGUuqXiExMHYbr8Gp4FgsaC0SjEfO21tmofkk4BdfxdSM4L6XOF1-7WzyLgOLBmYra5kwTrytaC7jGW9h-)
24. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG5qY6Rmox4rSTydNNbVp1wju1XXOA31nGpx-HqrmkfTuehOiPvWcAye0JrCTbgto1rk9D84ZMaC6xr_QhubDNhwFp6-0sR5UdSsJdhUsA-lg==)
25. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGEjKdOD5ubo1738IyrZuokuHCdnMpFry7osjN_7aE0yOF1dog3NM0Sj73Rf906UPg2x38INU3eYyNl6YQA2Y-feQs607wPoJ5SBpGsB5f2AvcF-cNtJAl0QGqBayANs9Y=)
26. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGooYYv0lVAYcIHCgS2Zy0P2oH6WtVm_541ivgPoU3wGq8TrFKD6SUg-A4zufCC6iZ0gxzSfARfeaTA2sozFav-5vHwIA-9LFdpxsBGAqIMuMhKBmuz4yY8pNnhjSq1v3ymgDrkXxbh)
27. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGJCudcPAEFKFPH5a4qJaddmjeYxb0NRezIq9MrkxYxBmy9kPSLiCNvAvPmN43pE1Ldjym3JANEOkt6icl33s01PWi17cKaS6Vm0_EVIuLg8JUwH1bjU47ObRNBMZSv2Zkt6oL9BkalLtOCDQg=)
28. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGsWLPKQVBsBBTd03dgiuB2btS6Vu4yc66YL7hpEKIRAdyeVpYCXzy2PCWNBIszodPhB_WEfkBlfA82DN6QoE6fb2Cr09gGxoX9GPEd9_j9XagSu55EEYjTkNxWsrDfZFUnIVLRdxJeVRWdwGg=)
29. [deps.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGjtNmy843YjNKxpvOCATDFWUw5D82dn2gD6Rsblrq8M-P9L77zF5Q6qvfuwoBnx5aw-wjzEwP4sPK-Fb__mSJJtTz7jGSPaXCAtkVBZInQ9GuGQHXNyMLZo2cfPLlFdmk-Dnv5-D_GG-lg)
30. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF95Bgvb5w1bBxi8tiKFMJErAOQ6SrB4Tp7_QwwCkGVVbU85BX-16g45IicXbl12YEk22pQORfkRAndGouFW3AHI_TslU5Jt1jWaeKJunao9CbqhGBbXNTohj9-krVvU6dNTIC38S3UdqcOhA==)
31. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGBJ_QsprcQOcVfziRkxDuf4HQjLCY_Tn0qLu25OOZ6zeYSnPG-yRynwHux0JrVU1GU7K2ASDY52Y_a5daaJU1BYVW8rpVX1oeKm9W-vGwtGqYN16B0qhhV0Yo=)
32. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFUsWkumuZ3f57dlwDg9tuEABpC3DD1NUGOiupCctuVPPLWqgBCYK8G7WPW-6Z-mxn8csCEhXfHeVtogP5rAOBIdY56p8MWsWM8eERCGRTneVU=)
33. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGL-RBTFcDFrPpcYE88LwuBRBCJzquDDm5AFBju-RbWRx8QevLQHoubdNgSSpHNCyaPpSUR65gzmaV0tG_vyZK2y4tvvreQ_t9DIfii73Z--mlzjQs6kzUUtGEarIly0Z0LyA==)
34. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHaKYS0jkdzXArU4NTPaGN1_6UODOr5iq5qLvO7gd0nmQiw1Efmk0LxTCtMsNhy5GblzhcgWKcc8y7okafg-YI6BFUA-ohfNZyM13SZtYUBJ-_YE7KPotOt4GPhdY30zoLUgJ1T)
35. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEItNscLBoElNyrzFDLKyAOWUcaghjDMMnqBo5799A2z59fj10ZLBfnY4xW3HXLMs5XmyPvBKcc5UfHkHJgu61pi5m10vvm5y9n0hzZfEUKPiKAkHamhoItAu4aVxUCVGqLRIstcC18)
36. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFG9HHR4_DjzGDOUE6wokcCzuRbGrhaBYMHhSRyYhA7r43N45rURF8XcgHeoEIBFK-8xuVWQjeAKZHYkdKEnDq1pX97W396n03ePMki-EbAD8rAnlKe8INegQ6NNULXMM-e)

## Sources

- [mit.edu](https://web.mit.edu/rust-lang_v1.25/arch/amd64_ubuntu1404/share/doc/rust/html/book/second-edition/ch14-03-cargo-workspaces.html)
- [rust-lang.org](https://doc.rust-lang.org/cargo/reference/workspaces.html)
- [rust-lang.org](https://doc.rust-lang.org/clippy/lints.html)
- [rust-lang.org](https://doc.rust-lang.org/clippy/lint_configuration.html)
- [github.com](https://github.com/rust-lang/rust-clippy/blob/master/clippy_lints/src/disallowed_types.rs)
- [github.io](https://embarkstudios.github.io/cargo-deny/)
- [github.io](https://embarkstudios.github.io/cargo-deny/checks/cfg.html)
- [docs.rs](https://docs.rs/crate/cargo-deny/0.2.5)
- [x-cmd.com](https://www.x-cmd.com/install/lefthook/)
- [crates.io](https://crates.io/crates/boundary)
- [lib.rs](https://lib.rs/crates/boundary-rust)
- [github.com](https://github.com/PSeitz/dep_graph_rs)
- [crates.io](https://crates.io/crates/hexser)
- [github.io](https://rust-lang.github.io/api-guidelines/naming.html)
- [crates.io](https://crates.io/crates/cargo-deny/0.19.0)
- [40tude.fr](https://www.40tude.fr/docs/06_programmation/rust/024_hexagonal/hexagonal_lite.html)
- [medium.com](https://medium.com/@lucorset/hexagonal-architecture-in-rust-72f8958eb26d)
- [thoughtworks.com](https://www.thoughtworks.com/insights/blog/architecture/hexagonal-architecture-explained-practical-example)
- [rust-lang.org](https://users.rust-lang.org/t/naming-conventions-for-cargo-workspaces/65369)
- [github.io](https://embarkstudios.github.io/cargo-deny/checks/bans/index.html)
- [github.io](https://embarkstudios.github.io/cargo-deny/checks/bans/cfg.html)
- [github.com](https://github.com/rust-lang/docs.rs/blob/main/clippy.toml)
- [crates.io](https://crates.io/crates/boundary-rust/0.24.0/dependencies)
- [docs.rs](https://docs.rs/cargo-deny)
- [crates.io](https://crates.io/crates/cargo_deny/0.18.0)
- [github.com](https://github.com/marketplace/actions/cargo-deny)
- [github.com](https://github.com/EmbarkStudios/cargo-deny/issues/641)
- [github.com](https://github.com/EmbarkStudios/cargo-deny/issues/846)
- [deps.rs](https://deps.rs/repo/github/EmbarkStudios/cargo-deny)
- [github.com](https://github.com/EmbarkStudios/cargo-deny/issues/50)
- [crates.io](https://crates.io/crates/dep-insight)
- [docs.rs](https://docs.rs/dep-insight)
- [crates.io](https://crates.io/crates/boundary-typescript)
- [github.com](https://github.com/kodustech/kodus-ai/issues/1662)
- [github.com](https://github.com/gitpod-io/gitpod/issues/770)
- [github.com](https://github.com/embarkstudios/cargo-deny)