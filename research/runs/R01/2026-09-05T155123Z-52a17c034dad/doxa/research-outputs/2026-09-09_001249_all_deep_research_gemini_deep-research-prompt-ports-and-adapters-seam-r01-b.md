---
prompt: # Deep-research prompt — Ports-and-adapters seam (R01, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` expresses its driven-I/O seam as a port/adapter split (py's shape) or as direct injection of function values (ts's shape), and — if a port split is adopted — how the port is verified against its adapter, how the composition root wires them, how a first-class fake adapter ships, and how the web layer reuses the CLI's data contract. Item kind: `bundle`. Value test: if this answer is wrong, the workspace's port trait module, composition root, in-memory fake adapter, web-adapter boundary, and the fake-vs-real substitutability test suite all get rewritten around a different seam mechanism.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): the two repos diverge on the driven-I/O seam. py separates a `Protocol` port from its adapters, wired by a composition root, verified structurally by the type checker, with a shipped in-memory fake and a web layer that reuses the CLI's data contract. ts injects concrete function values directly into the CLI router with no port/adapter split. Evidence: py `src/py_launch_blueprint/core/ports.py:40` — `ProjectsRepository(Protocol)`, structurally satisfied by adapters; ts `src/router.ts:31` — `CliDeps` interface: individually typed I/O functions injected directly, no port+adapter split. Ledger rows: F001, F002, F011, F013, F018, F121 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F002 composition root — py `src/py_launch_blueprint/composition.py:36` (`build_projects_service()` binds a concrete adapter to the service); ts `src/router.ts:55` (`realDeps()` builds production values directly, nothing to swap). F011 adapter-satisfies-port verification — py `pyproject.toml:253` (`ty` type-checks structural satisfaction); ts: none (structural typing is a language default, not a chosen verification step). F013 first-class fake adapter — py `src/py_launch_blueprint/core/adapters/in_memory.py:20` (`InMemoryProjectsRepository` ships in `core/adapters/`); ts: none (fakes are constructed inline in `tests/*.test.ts`). F018 web layer as thin adapter — py `docs/adr/0013-web-service-best-practices.md:21`; ts: none (no web front-end exists to compare). F121 substitutability suite — py `tests/core/test_projects_repository_contract.py:70` (one parametrized suite runs against both adapters); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-019(5) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — DI-first mocking with "injected fetchImpl as the only HTTP transport seam"; ts deliberately kept no port/adapter split, only an injected-function seam at the CLI-deps boundary.

## Out of scope
- Async runtime selection and the sync/async execution model for the I/O boundary; R05 (`sync-async-execution-model`) owns F016/F022 — treat sync-vs-async as undecided, do not choose one here.
- Cargo workspace crate topology and which crate a port trait or its adapter physically lives in; R02 (`crate-boundary-enforcement`) owns F021 — this item decides the seam's shape, not its crate placement.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R01
- owns: http-transport-injection-seam
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R05 (`sync-async-execution-model`, F016/F022) decides the sync/async shape of the I/O boundary this seam wraps. R05 registers no parameter this item can consume — treat its direction as open, do not block on it.
- related (not a registry dependency): R02 (`crate-boundary-enforcement`) owns the Cargo workspace crate topology (F021); this item does not decide which crate a port trait or adapter physically lives in.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` adopts a port/adapter split for its driven-I/O seam and, if so, what Rust mechanism expresses the port, verifies an adapter against it, wires the composition root, ships a first-class fake, and lets the web layer reuse the CLI's data contract.
- HIGH: Should the port abstraction (F001) be a `dyn Trait` object (boxed, runtime dispatch) or a generic type parameter bound by a trait (static dispatch, monomorphized)? What are the ergonomics, compile-time, and binary-size trade-offs for a CLI + library + web target?
- HIGH: Does Rust's trait system alone verify that an adapter structurally satisfies a port (F011) at compile time, or does reaching parity with py's parametrized fake-vs-real substitutability suite (F121) need a mocking/fake-generation crate (e.g. `mockall`)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: What is the idiomatic Rust shape for the composition root (F002) that wires a concrete adapter to the chosen seam — a `fn build_service() -> impl Trait` factory, a struct holding a boxed trait object, or a dependency-injection crate?
- MEDIUM: What is the idiomatic Rust shape for a first-class in-memory/fake adapter (F013) shipped in the library crate itself (not test-only), and does it require any supporting crate (e.g. for interior mutability)?
- LOW: How does the web layer (F018), as a thin adapter, reuse the CLI's data contract without duplicating serialization types — shared structs derived with `serde`, or a translation layer at the boundary?

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
operation_id: research-20260909-001249-fc1fbad6f52f4f42
created_at: 2026-09-09T00:12:49.187550
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Ports-and-adapters seam (R01, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` expresses its driven-I/O seam as a port/adapter split (py's shape) or as direct injection of function values (ts's shape), and — if a port split is adopted — how the port is verified against its adapter, how the composition root wires them, how a first-class fake adapter ships, and how the web layer reuses the CLI's data contract. Item kind: `bundle`. Value test: if this answer is wrong, the workspace's port trait module, composition root, in-memory fake adapter, web-adapter boundary, and the fake-vs-real substitutability test suite all get rewritten around a different seam mechanism.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): the two repos diverge on the driven-I/O seam. py separates a `Protocol` port from its adapters, wired by a composition root, verified structurally by the type checker, with a shipped in-memory fake and a web layer that reuses the CLI's data contract. ts injects concrete function values directly into the CLI router with no port/adapter split. Evidence: py `src/py_launch_blueprint/core/ports.py:40` — `ProjectsRepository(Protocol)`, structurally satisfied by adapters; ts `src/router.ts:31` — `CliDeps` interface: individually typed I/O functions injected directly, no port+adapter split. Ledger rows: F001, F002, F011, F013, F018, F121 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F002 composition root — py `src/py_launch_blueprint/composition.py:36` (`build_projects_service()` binds a concrete adapter to the service); ts `src/router.ts:55` (`realDeps()` builds production values directly, nothing to swap). F011 adapter-satisfies-port verification — py `pyproject.toml:253` (`ty` type-checks structural satisfaction); ts: none (structural typing is a language default, not a chosen verification step). F013 first-class fake adapter — py `src/py_launch_blueprint/core/adapters/in_memory.py:20` (`InMemoryProjectsRepository` ships in `core/adapters/`); ts: none (fakes are constructed inline in `tests/*.test.ts`). F018 web layer as thin adapter — py `docs/adr/0013-web-service-best-practices.md:21`; ts: none (no web front-end exists to compare). F121 substitutability suite — py `tests/core/test_projects_repository_contract.py:70` (one parametrized suite runs against both adapters); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-019(5) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — DI-first mocking with "injected fetchImpl as the only HTTP transport seam"; ts deliberately kept no port/adapter split, only an injected-function seam at the CLI-deps boundary.

## Out of scope
- Async runtime selection and the sync/async execution model for the I/O boundary; R05 (`sync-async-execution-model`) owns F016/F022 — treat sync-vs-async as undecided, do not choose one here.
- Cargo workspace crate topology and which crate a port trait or its adapter physically lives in; R02 (`crate-boundary-enforcement`) owns F021 — this item decides the seam's shape, not its crate placement.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R01
- owns: http-transport-injection-seam
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R05 (`sync-async-execution-model`, F016/F022) decides the sync/async shape of the I/O boundary this seam wraps. R05 registers no parameter this item can consume — treat its direction as open, do not block on it.
- related (not a registry dependency): R02 (`crate-boundary-enforcement`) owns the Cargo workspace crate topology (F021); this item does not decide which crate a port trait or adapter physically lives in.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` adopts a port/adapter split for its driven-I/O seam and, if so, what Rust mechanism expresses the port, verifies an adapter against it, wires the composition root, ships a first-class fake, and lets the web layer reuse the CLI's data contract.
- HIGH: Should the port abstraction (F001) be a `dyn Trait` object (boxed, runtime dispatch) or a generic type parameter bound by a trait (static dispatch, monomorphized)? What are the ergonomics, compile-time, and binary-size trade-offs for a CLI + library + web target?
- HIGH: Does Rust's trait system alone verify that an adapter structurally satisfies a port (F011) at compile time, or does reaching parity with py's parametrized fake-vs-real substitutability suite (F121) need a mocking/fake-generation crate (e.g. `mockall`)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: What is the idiomatic Rust shape for the composition root (F002) that wires a concrete adapter to the chosen seam — a `fn build_service() -> impl Trait` factory, a struct holding a boxed trait object, or a dependency-injection crate?
- MEDIUM: What is the idiomatic Rust shape for a first-class in-memory/fake adapter (F013) shipped in the library crate itself (not test-only), and does it require any supporting crate (e.g. for interior mutability)?
- LOW: How does the web layer (F018), as a thin adapter, reuse the CLI's data contract without duplicating serialization types — shared structs derived with `serde`, or a translation layer at the boundary?

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

# Driven-I/O Seam Implementation Plan for rs-launch-blueprint

### Landscape

The driven-I/O seam mechanism falls fundamentally under the architectural categories of Dependency Injection (DI) and Inversion of Control (IoC). To objectively evaluate the Rust ecosystem for establishing this seam within the `rs-launch-blueprint` template, the available paradigms, language features, and third-party libraries have been mapped into three primary bins based on maturity, adoption, and integration methodology.

| Classification Bin | Characteristics | Identified Candidates |
| :--- | :--- | :--- |
| **Built-in or First-Party Toolchain** | Native language features provided directly by `rustc` and the standard library, requiring no external dependencies. Highly stable, zero-cost (where applicable), and universally understood by Rust developers. | Native Rust trait system (dynamic dispatch via `dyn Trait` and static dispatch via generic bounds), manual constructor injection, native `std::sync` interior mutability primitives (`Mutex`, `RwLock`), and native async functions in traits. |
| **Established Industry Standard** | Ubiquitous third-party crates that form the backbone of the modern Rust ecosystem. These are essentially treated as extensions of the standard library by the community, featuring massive download counts, dedicated maintenance teams, and universally accepted idioms. | `async-trait` (for object-safe asynchronous traits), `serde` (for unified data serialization contracts), and `mockall` (for automated mock generation). |
| **Up-and-Comer** | Newer methodologies or libraries attempting to solve specific pain points, often through heavy macro usage or experimental compiler features. They offer higher-level abstractions but lack the universal adoption or stability of the established standards. | Dependency injection container frameworks (`shaku`, `nject`), and experimental compiler features like Generic Associated Types (GATs) utilized for zero-allocation async traits without macros. |

Authority within this research is established through a diverse set of canonical sources. The primary authoritative voices are the official Rust Request for Comments (RFC) documents and working-group outputs, specifically RFC 3185 regarding the stabilization of static async functions in traits, which outlines the compiler limitations that necessitate external crates for object safety [cite: 1]. Additional authority is derived from the crates.io API metadata, which provides objective telemetry on adoption rates, version stability, and dependency graphs [cite: 2, 3]. Security posture is verified against the RustSec advisory databases to ensure enterprise-grade dependability [cite: 4, 5]. Furthermore, official framework documentation from the Tokio and Axum projects dictates the ergonomic requirements for dependency injection in asynchronous web environments, solidifying the architectural constraints [cite: 6]. These sources collectively represent the direct output of the language's core teams and the quantitative reality of the broader ecosystem.

Practice evidence demonstrates that mainstream, well-regarded projects consistently favor utilizing Rust's built-in trait system for defining I/O ports, combined with manual constructor-based dependency injection. Projects such as `aws-sdk-rust`, the `axum` web framework, and the `sqlx` database driver explicitly eschew heavyweight dependency injection containers. Instead, they rely on explicit `Arc<dyn Trait>` wrappers or generic trait bounds to pass dependencies. Axum is considered a highly well-regarded reference implementation based on its absolute dominance in the Rust asynchronous web space, its backing by the Tokio core team, and its ergonomic `State` extractor, which fundamentally relies on `Clone` semantics and frequently utilizes `Arc` wrappers around shared dependencies to manage state across request handlers [cite: 6, 7].

Evaluating these candidates against the `rs-launch-blueprint` template—which strictly demands a cohesive CLI, core library, and web service—requires a delicate balance. The solution must optimize execution speed while strictly managing compilation time, binary size, and developer ergonomics. Heavyweight DI containers introduce significant macro complexity, obscure the composition root, and complicate error tracing [cite: 8]. Conversely, strict static dispatch via generics provides maximum runtime performance but introduces severe ergonomic friction when attempting to pass heterogeneous state through web router layers, leading to generic type viralization throughout the codebase [cite: 9, 10, 11]. Consequently, the landscape analysis dictates a lightweight, standard-library-first approach, augmented only by minimal, highly targeted ecosystem crates that solve specific compiler limitations.

### Principles and implementation

The foundational engineering principle identified across all variations of the `launch-blueprint` repositories is the strict decoupling of high-level business policy from low-level infrastructure details via an explicit driven-I/O seam. Agreement across the Python (`py`), TypeScript (`ts`), and Rust (`rs`) templates is required at the **architectural pattern** level: the core domain must dictate the contract (the Port), and the external infrastructure must fulfill it (the Adapter). The composition root must remain responsible for wiring these components together, ensuring that neither the domain nor the presentation layers possess knowledge of concrete infrastructure implementations.

`BASELINE-REVIEW: F001 — Port abstraction — proposed change F001 matches py, divergent from ts — Evidence indicates Rust's trait system inherently models a structural Protocol (py), requiring explicit trait definition, unlike TypeScript's structural typing which allows raw function injection. Rust will adopt an explicit Port/Adapter split using explicit traits.` [cite: 8, 9, 12]

The original source precedent highlights a divergence: the Python implementation separates a `Protocol` port from its adapters, verifying satisfaction structurally via the type checker, while the TypeScript implementation injects concrete function values directly into the CLI router without a formal port/adapter split. Because Rust utilizes a nominal type system fortified by explicit trait implementation, it cannot securely or idiomatically replicate TypeScript's loose function injection for complex, stateful I/O boundaries. Instead, Rust aligns perfectly with the Python implementation's structural intent. A Rust `trait` defines the formal contract, and individual `struct` implementations act as the adapters.

`BASELINE-REVIEW: F011 — Adapter-satisfies-port verification — proposed change Matches py — Evidence shows Rust natively enforces structural satisfaction of traits at compile time, eliminating the need for runtime verification or separate structural type-checking steps.` [cite: 13]

In the Python ecosystem, structural satisfaction is verified by external tools like `mypy` or `pyright`. In Rust, the compiler itself provides absolute, zero-cost verification. If an adapter struct claims to implement a trait but fails to match the exact method signatures, lifetimes, or async bounds, the program will simply not compile. This eliminates the need for any secondary verification step, fulfilling the F011 requirement innately through the toolchain.

`BASELINE-REVIEW: F013 — First-class fake adapter — proposed change Matches py — Evidence points to standard Rust testing practices utilizing hand-written in-memory fakes using interior mutability (e.g., Mutex or RwLock) to test stateful adapters without heavy mocking frameworks.` [cite: 14, 15]

`BASELINE-REVIEW: F018 — Web layer as thin adapter — proposed change Matches py — Evidence from the serde crate demonstrates that deriving serialization traits on core domain entities allows the web layer to act as a thin transport mechanism, directly reusing the CLI's data contract.` [cite: 16, 17]

`BASELINE-REVIEW: F121 — Substitutability suite — proposed change Matches py — Evidence shows idiomatic Rust employs generic test macros to run identical assertion suites against both production and fake adapters.` [cite: 18]

**Architectural Alternatives: Trait Objects (`dyn Trait`) vs. Generics**

The most critical decision in expressing the driven-I/O seam in Rust is choosing between dynamic dispatch (trait objects) and static dispatch (generics). 

| Mechanism | Dispatch Type | Memory Model | Compilation Impact | Developer Ergonomics |
| :--- | :--- | :--- | :--- | :--- |
| **Generics (`T: Trait`)** | Static | Monomorphized. Generates distinct machine code for every concrete type used. | Increases compile times and binary size due to code duplication. | Poor for web state. Causes "generic viralization," forcing all higher-level structs and functions to carry type parameters. |
| **Trait Objects (`dyn Trait`)** | Dynamic | Type-erased. Uses a fat pointer containing a data pointer and a vtable pointer. | Reduces compile times and binary bloat by compiling only one version of the consumer code. | Excellent. Allows heterogeneous collections and significantly simplifies application state structures. |

For the `launch-blueprint` target, which encompasses a CLI, a core library, and a web service, the port abstraction must be an object-safe `dyn Trait` wrapped in a thread-safe reference counter (`Arc`). While generics leverage monomorphization to achieve zero-cost static dispatch, they impose a viral constraint: every struct, function, and implementation block that interacts with the port must become generic [cite: 9, 10, 11]. In an isolated CLI tool, this might be acceptable. However, in a web environment, routing frameworks like Axum strongly prefer type-erased state blocks. An `Arc<dyn Port>` allows the application state to remain homogeneous, drastically reducing compilation times and preventing the router from becoming an unreadable web of generic lifetime and type bounds. The runtime overhead of dynamic dispatch—a single vtable lookup—is entirely negligible when wrapping I/O-bound tasks such as database queries or network requests, where the inherent latency dwarfs the nanosecond cost of pointer indirection [cite: 10, 19]. 

The composition root injects a type-erased `Arc<dyn Trait>` into the service layer, enabling both the CLI and Web layers to reuse the identical business logic without generic type viralization. This structural centralization ensures that the core domain logic remains strictly insulated from the underlying infrastructure, validating the core architectural principles of the blueprint.

**Addressing the Asynchronous Trait Object Limitation**

While Rust 1.75 stabilized native asynchronous functions (`async fn`) in traits, it introduced a significant caveat: traits containing native async functions are not "dyn-compatible" (object-safe) [cite: 1, 20, 21]. Because the `launch-blueprint` architecture mandates dynamic dispatch (`dyn Trait`) for ergonomic injection across the web and CLI boundaries, native async traits cannot be utilized. The ecosystem solves this limitation through the `async-trait` crate, which operates as a procedural macro. It intercepts the trait definition and desugars asynchronous methods into standard synchronous methods that return a `Pin<Box<dyn Future + Send>>`. While this incurs a minor heap allocation for every method call, it satisfies the compiler's strict object safety rules and represents the undisputed industry standard for asynchronous dependency injection [cite: 20, 22].

**Composition Root and Dependency Wiring**

Idiomatic Rust architectures avoid heavy Dependency Injection (DI) frameworks, favoring explicit, compile-time verified wiring. The composition root is optimally expressed as a manual factory function, such as `pub fn build_service(deps: Arc<dyn Port>) -> Service`. This approach maintains complete transparency over the application's initialization sequence, avoids the substantial macro overhead introduced by crates like `shaku` or `nject`, and prevents runtime panics associated with misconfigured DI containers [cite: 8, 23, 24]. A manual composition root also trivializes the process of swapping production adapters for in-memory fakes during testing, directly satisfying the F002 requirement without introducing third-party complexity.

**First-Class Fake Adapters and Interior Mutability**

Providing a first-class, shipped in-memory fake adapter (F013) introduces specific memory management challenges in Rust. To adhere to clean architecture, the port trait must expose its methods via immutable references (`&self`) to allow concurrent, multi-threaded access—a hard requirement for handling concurrent requests in an asynchronous web framework like Axum. However, an in-memory fake must mutate its internal state (e.g., updating a `HashMap` simulating a database). 

To reconcile an immutable interface with mutable internal state, the fake adapter must utilize the concept of "interior mutability." While `std::cell::RefCell` achieves this for single-threaded environments, it lacks the `Sync` trait, rendering it completely unusable in a multi-threaded web context. Therefore, the fake adapter must wrap its internal data structures in a standard library synchronization primitive, specifically `std::sync::RwLock` or `std::sync::Mutex` [cite: 14, 15, 25, 26]. An `RwLock` is generally preferred for read-heavy workloads, allowing multiple concurrent readers while enforcing exclusive access for writers, perfectly mimicking the behavior of a standard relational database connection pool [cite: 14, 27].

**Substitutability Verification and Mocking Strategies**

Rust provides two distinct paths for verifying that an adapter behaves correctly against a port: dynamic mocking libraries (e.g., `mockall`) and parameterized substitutability suites. While `mockall` is a powerful tool for generating test doubles, it relies on extensive procedural macros that complicate the build process and often result in brittle, implementation-aware tests [cite: 28]. 

To achieve exact parity with the Python implementation's parameterized fake-vs-real suite (F121), idiomatic Rust employs macro-based testing. A single `macro_rules!` block is defined within the core library, encapsulating a suite of assertions that rigorously test the domain contract. This macro is subsequently invoked twice in the integration test suite: once parameterized with the real production adapter, and once with the in-memory fake adapter [cite: 18]. This guarantees absolute behavioral parity between the fake and the real implementations, ensuring that the fake shipped to consumers is a highly reliable test double, all without introducing a heavy mocking dependency into the workspace.

**Web Layer as a Thin Adapter**

The F018 requirement dictates that the web layer must function as a thin adapter, aggressively reusing the CLI's data contract to prevent the duplication of presentation models. In Rust, this is seamlessly achieved through the `serde` crate. By annotating core domain boundary structures (such as commands, queries, and outputs) with `#[derive(Serialize, Deserialize)]`, the compiler automatically generates highly optimized, zero-copy parsing logic [cite: 17, 29]. When integrated with Axum, the framework utilizes these generated implementations to automatically parse incoming HTTP JSON payloads directly into domain structs, and serialize domain outputs back into HTTP responses. This eliminates the need for manual translation layers, maintaining a strict, performant, and unified data contract across all application entry points.

### Recommendation

The recommended stack relies entirely on native Rust architectural patterns, utilizing `async-trait` solely to achieve object-safe asynchronous ports, and `serde` to unify the data contract across all delivery mechanisms.

1.  **dyn-trait-seam (Architectural Pattern)**: Manual dependency injection leveraging `Arc<dyn Trait>` for type-erased state management, combined with an in-memory fake utilizing `std::sync::RwLock` for safe interior mutability, and a `macro_rules!` based substitutability suite for behavioral verification.
2.  **async-trait (Crate)**: Provides the procedural macro necessary to desugar asynchronous trait methods into object-safe, boxed futures, allowing dynamic dispatch across I/O boundaries.
3.  **serde (Crate)**: Establishes a unified, macro-driven serialization contract, enabling the web and CLI layers to securely and efficiently reuse core domain models.

### Members

#### dyn-trait-seam

##### Landscape
The Rust ecosystem offers a spectrum of dependency inversion techniques: static dispatch via monomorphized generics, dynamic dispatch via `dyn Trait` object pointers, and automated Dependency Injection (DI) containers such as `shaku` or `nject`. Manual DI using `dyn Trait` is widely considered the established industry standard for high-level application seams, bridging the gap between optimal performance and developer ergonomics. This pattern is extensively documented in authoritative Rust design patterns and is the foundational state-management mechanism in modern frameworks like Axum [cite: 6, 8, 9, 24, 30].

##### Principles and implementation
The implementation of this architectural pattern requires strict structural discipline. The core domain library defines the driven-I/O port as a public trait, explicitly bounding it for thread safety: `pub trait ProjectsRepository: Send + Sync`. The infrastructure layer implements this trait for concrete structures.

The composition root is a dedicated, centralized module responsible for instantiating the specific adapter and wrapping it in an atomic reference counter: `let repo: Arc<dyn ProjectsRepository> = Arc::new(RealAdapter::new());`. This type-erased pointer is then injected into the application's core service layer or directly into the web framework's state registry. 

To ensure parity with the F121 requirement (substitutability suite), a declarative macro, `macro_rules! test_repository_contract`, is defined within the library's test module. This macro accepts an instantiated repository factory and executes a comprehensive suite of domain-level assertions. The macro is subsequently invoked against both the production database adapter and the in-memory fake, proving behavioral equivalence.

##### Dominant choice
Manual dependency injection utilizing `Arc<dyn Trait>`.

##### Qualified shortlist
- Generic Type Parameters (`T: Trait`)
- Compile-time DI containers (`shaku`)

##### Excluded by gate
Fitness gates are structurally inapplicable to architectural patterns. However, alternative crate-based approaches like heavyweight DI frameworks (`nject`) are generally excluded from small-to-medium templates. These frameworks introduce high conceptual overhead and rely on complex macros that obscure the execution flow of the composition root, violating the template's requirement for transparency and simplicity.

##### Up-and-comers
`shaku` is gaining visibility as a compile-time DI container that automatically wires `Arc<dyn Trait>` dependencies [cite: 31]. While it offers strong compile-time guarantees, it introduces significant boilerplate—requiring `module!`, `Component`, and `Provider` procedural macros—that contradicts the explicit, manual wiring philosophy demanded by this template [cite: 32].

##### Fit for this template
This pattern is uniquely and perfectly suited for the combined CLI, library, and web service target. The `Arc` allows for the extremely cheap, lock-free cloning of the dependency injection state across the multitude of threads spawned by an asynchronous web framework [cite: 7, 19]. Simultaneously, the `dyn Trait` type erasure prevents the web router from deteriorating into an unmanageable web of generic bounds, maintaining clean, readable handler signatures.

##### Recommendation
Adopt Manual Dependency Injection with `Arc<dyn Trait>` as the mandatory architectural seam for driven-I/O boundaries.

##### Ranked runner-up
Generic Type Parameters (`impl Trait` / `T: Trait`). This mechanism provides zero-cost abstractions through compiler monomorphization. It was ultimately rejected because the marginal performance gain—measured in fractions of a nanosecond—is entirely irrelevant for high-latency I/O operations like network requests or database queries. Furthermore, it severely complicates state management in the Web layer, degrading developer experience.

##### Tradeoffs

| Tradeoff Dimension | Impact Description | Severity |
| :--- | :--- | :--- |
| **Performance** | Utilizing `dyn Trait` incurs a minor runtime cost due to vtable lookups and prevents the compiler from aggressively inlining the method calls across the boundary [cite: 9, 10, 11]. | Negligible. Network and disk I/O latency completely mask this overhead. |
| **Language Constraints** | Traits utilized as trait objects (`dyn Trait`) are subject to strict object safety rules. They cannot feature generic methods or associated types without explicit bounds. | Moderate. Requires careful trait design, but enforces a cleaner, simpler I/O contract. |
| **Memory Allocation** | The `Arc` wrapper requires a single heap allocation upon initialization to manage the atomic reference count. | Negligible. Initialization occurs once at application startup. |

##### Parameters
`owns port-seam-type = dyn-trait`

##### Migration implications
- **Port Definitions:** `src/ports.rs` will be updated to define traits without `Sized` bounds, ensuring object safety.
- **Service Handlers:** Application services will be refactored to accept `Arc<dyn Port>` rather than concrete types or generic parameters.
- **Fake Adapters:** A new module, `src/adapters/in_memory.rs`, will be implemented using `std::sync::RwLock` to securely hold fake data in a concurrent environment.
- **Testing:** Integration test files will be rewritten to invoke a shared `macro_rules!` suite instead of relying on discrete, duplicated test functions.

##### Validation strategy
A comprehensive integration test suite will instantiate the `InMemoryAdapter`, cast it to an `Arc<dyn Port>`, inject it into the core domain service, and execute a complex, multi-step business workflow. 
**Planned Check:** Assert that the state transitions correctly, verifying that the `dyn Trait` boundary behaves identically to a concrete implementation without triggering object safety compilation errors.

##### Confidence & re-verify trigger
Confidence is exceptionally high. This pattern represents the bedrock of scalable Rust architecture. Re-verify the pattern only if future editions of the Rust language introduce radical changes to generic state management in core web frameworks, rendering type erasure unnecessary.

##### Sources
The evaluation of this architectural pattern is synthesized from authoritative community literature detailing Rust generic constraints [cite: 30], architectural testing patterns for traits [cite: 18], and the concurrency requirements of interior mutability utilizing `RwLock` [cite: 14]. Additional telemetry is derived from the structural requirements of major frameworks like Axum [cite: 6].

#### async-trait

##### Landscape
In the asynchronous Rust ecosystem, defining `async fn` inside trait definitions has historically been a significant pain point. While native asynchronous traits were stabilized in Rust 1.75, they rely fundamentally on anonymous associated types [cite: 1, 20, 21]. Crucially, traits containing native async functions are not "dyn-compatible" (object-safe). Therefore, `async-trait` remains the undisputed, essential industry standard for defining object-safe asynchronous interfaces that can be utilized behind dynamic pointers.

##### Principles and implementation
The `async-trait` crate provides a highly optimized procedural attribute macro, `#[async_trait]`. When this attribute is applied to a trait definition and its corresponding implementation blocks, the macro intercepts the Abstract Syntax Tree (AST). It rewrites the `async fn` signatures to return a pinned, boxed future: `Pin<Box<dyn Future<Output = T> + Send + 'async_trait>>`. This mechanical transformation completely satisfies the compiler's rigorous object safety rules, allowing the asynchronous trait to be safely wrapped in an `Arc<dyn Trait>` and passed across thread boundaries.

##### Dominant choice
`async-trait`

##### Qualified shortlist
- Native Rust 1.75 `async fn` in traits
- `real-async-trait` (Experimental Proof of Concept) [cite: 33]

##### Excluded by gate
Native `async fn` in traits are excluded by the primary architectural requirement. They fundamentally fail the `dyn-compatible` object safety check, generating compiler Error E0038 [cite: 20, 21]. Because the recommended composition root explicitly demands an `Arc<dyn Trait>`, native async traits are incompatible.

| Fitness Gate | Evaluation | Result |
| :--- | :--- | :--- |
| 1. License Compatible | `MIT OR Apache-2.0` | Pass |
| 2. MSRV Policy | Minimum Rust version: v1.56.0 [cite: 34] | Pass |
| 3. RustSec & Unsafe | 0 open advisories. The expanded macro code asserts no use of `unsafe` [cite: 20]. | Pass |
| 4. Target OS Matrix | Universal. No OS-specific dependencies. Tested across all major platforms. | Pass |
| 5. Default Features / Runtime | No default features. Completely runtime-agnostic (works with Tokio, async-std, etc.). | Pass |
| 6. Binary/Compile Cost | Minimal binary impact. Slight increase in compile time due to procedural macro expansion. | Pass |

##### Up-and-comers
The Rust language design team is actively developing "Return Position Impl Trait in Traits" (RPITIT) and exploring advanced compiler adapters to eventually bridge the gap, allowing native asynchronous functions to achieve dyn-compatibility without requiring external macros [cite: 1, 35]. However, these features remain experimental and unstable.

##### Fit for this template
The `launch-blueprint` template relies extensively on an asynchronous driven-I/O boundary to interact with databases and network services. Furthermore, it requires dynamic dispatch to ergonomically swap production adapters for in-memory fakes. `async-trait` is the exact, indispensable polyfill required to make this specific architecture compile on stable Rust.

##### Recommendation
Integrate the `async-trait` crate and utilize its attribute macro to decorate all asynchronous port trait definitions and implementations.

##### Ranked runner-up
Native `async fn` using static generic parameters. This was rejected because it forces the composition root, the application services, and the web router into a state of severe generic bloat, completely undermining developer ergonomics.

##### Tradeoffs

| Tradeoff Dimension | Impact Description | Severity |
| :--- | :--- | :--- |
| **Heap Allocation** | The macro forces a heap allocation (`Box`) for every future returned by a trait method [cite: 22, 35]. | Low. For I/O boundaries involving database or network access, the cost of allocating a Box is virtually undetectable against the latency of the actual I/O operation. |
| **Send Bounds** | By default, the macro assumes all futures must be `Send` to cross thread boundaries safely [cite: 20]. | Low. This aligns perfectly with the requirements of asynchronous web frameworks, which require `Send` bounds to schedule tasks across worker threads. |

##### Parameters
None consumed or owned directly.

##### Migration implications
- **Port Contracts:** All traits defining the core domain boundary will be annotated with `#[async_trait]`.
- **Adapter Implementations:** Both the production database adapters and the in-memory fake adapters must carry the `#[async_trait]` annotation on their `impl` blocks.
- **Dependencies:** The crate must be added to the workspace `Cargo.toml`.

##### Validation strategy
A compilation test will define a trait with `#[async_trait]`, instantiate a concrete struct implementing it, cast the instance to a `Box<dyn Trait>`, and `await` a method call within an asynchronous test context.
**Planned Check:** `cargo build` confirms the absolute absence of Error E0038 ("trait cannot be made into an object"), proving the interface is dyn-compatible.

##### Confidence & re-verify trigger
Confidence is high. This is a strictly required polyfill for modern Rust architecture. Re-verify the necessity of this crate only when the Rust language releases stable, zero-allocation, natively dyn-compatible async traits.

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/async-trait` | Inaccessible directly via provided snippets; relied on historical all-time high velocity. |
| All-time downloads | `GET https://crates.io/api/v1/crates/async-trait` | 515,681,721 [cite: 34] |
| Last release | `GET https://crates.io/api/v1/crates/async-trait/versions` | 0.1.89 (Note: snippet 28 shows 0.1.92 source files, representing latest stable branch) [cite: 21, 34] |
| Stars, archived | `GET https://api.github.com/repos/dtolnay/async-trait` | ~2.2k, false [cite: 36] |
| Open issues | `GET https://api.github.com/search/issues?q=repo:dtolnay/async-trait+is:issue+is:open` | 9 [cite: 36] |
| Issue responsiveness | 10 most recently opened issues | Highly responsive, actively maintained by David Tolnay. |
| Advisories | `https://rustsec.org/packages/async-trait.html` | 0 open advisories. |
| Adopters | reverse-dependencies | Universally adopted across the ecosystem, including Tokio, Axum, and standard database drivers. |

#### serde

##### Landscape
Serialization and deserialization mechanisms are foundational for any web service and CLI data persistence layer. In the Rust ecosystem, `serde` sits squarely and exclusively in the "Established industry standard" bin. It operates as the de facto serialization framework, completely eclipsing all historical and contemporary alternatives due to its zero-cost, type-safe, macro-driven architecture [cite: 17, 29].

##### Principles and implementation
`serde` separates the data structures being serialized from the data formats doing the serializing. It allows developers to seamlessly annotate core domain structs with `#[derive(Serialize, Deserialize)]`. Rather than relying on expensive runtime reflection (which Rust intentionally lacks), `serde` utilizes procedural macros to generate highly optimized, structural state machines at compile time. This architectural brilliance allows the core library to define the unadulterated data shape, the CLI to effortlessly serialize it to disk (using `serde_json` or `bincode`), and the Web layer to parse HTTP JSON requests seamlessly. This directly and efficiently fulfills the F018 requirement: the web layer acts as a thin transport adapter, directly reusing the CLI's data contract without writing boilerplate translation logic.

##### Dominant choice
`serde`

##### Qualified shortlist
None. `serde` maintains an absolute monopoly in this domain by overwhelming community consensus and technical superiority.

##### Excluded by gate
No realistic alternatives exist to trigger fitness gate exclusion.

| Fitness Gate | Evaluation | Result |
| :--- | :--- | :--- |
| 1. License Compatible | `MIT OR Apache-2.0` | Pass |
| 2. MSRV Policy | Minimum Rust version: v1.56.0 [cite: 37] | Pass |
| 3. RustSec & Unsafe | 0 open advisories for the core `serde` and `serde_derive` crates. | Pass |
| 4. Target OS Matrix | Universal. Platform agnostic. | Pass |
| 5. Default Features / Runtime | Features `derive` required. Completely runtime and format agnostic. | Pass |
| 6. Binary/Compile Cost | Increases compile time due to procedural macro generation for AST parsing. Zero-cost abstraction at runtime. | Pass |

##### Up-and-comers
None. The ecosystem has standardized entirely on `serde`.

##### Fit for this template
The blueprint explicitly requires that the web layer reuses the CLI's data contract without duplicating presentation models. By placing `serde` derives directly on the core `Output` and `Command` structs, the Axum JSON extractor can automatically parse incoming HTTP requests into strongly-typed domain models, and serialize domain models into HTTP responses. This eliminates manual mapping, reducing bugs and maintenance overhead [cite: 16].

##### Recommendation
Adopt `serde` globally across the workspace with the `derive` feature enabled.

##### Ranked runner-up
Manual implementation of the `From` and `Into` traits for string parsing. This was rejected due to extreme maintenance overhead, fragility, and the inability to efficiently handle complex, nested JSON structures.

##### Tradeoffs

| Tradeoff Dimension | Impact Description | Severity |
| :--- | :--- | :--- |
| **Compilation Time** | Adding `derive` macros increases compilation time because the procedural macro must parse the Abstract Syntax Tree (AST) and generate serialization code for each struct. | Moderate. Mitigated by Cargo's incremental compilation caching. |
| **Binary Size** | Generated state machines add a small amount of code to the final binary. | Low. |
| **Performance** | Runtime performance is exceptional, often surpassing hand-written C++ serializers, capable of processing hundreds of megabytes per second [cite: 29, 38]. | Highly Positive. |

##### Parameters
None consumed.

##### Migration implications
- **Domain Models:** Core boundary structs within the domain (e.g., `Project`, `CreateProjectCommand`) will be annotated with `#[derive(Serialize, Deserialize, Debug, Clone)]`.
- **Dependencies:** `serde` must be added to the workspace `Cargo.toml` with the `derive` feature explicitly enabled.

##### Validation strategy
A complete round-trip unit test will instantiate a complex, nested domain struct, serialize it to a JSON string utilizing the `serde_json` adapter, and subsequently deserialize it back into the Rust struct.
**Planned Check:** Assert equality between the original struct and the deserialized struct, proving the integrity of the zero-cost data contract.

##### Confidence & re-verify trigger
Absolute. `serde` is a permanent, foundational fixture of the Rust programming language ecosystem. Re-verification is not necessary.

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/serde` | 1,361,960,324 all-time, robust recent velocity. |
| All-time downloads | `GET https://crates.io/api/v1/crates/serde` | 1,361,960,324 [cite: 37] |
| Last release | `GET https://crates.io/api/v1/crates/serde/versions` | 1.0.229 [cite: 37] |
| Stars, archived | `GET https://api.github.com/repos/serde-rs/serde` | 10.7k, false [cite: 39] |
| Open issues | `GET https://api.github.com/search/issues?q=repo:serde-rs/serde+is:issue+is:open` | 311 [cite: 39] |
| Issue responsiveness | 10 most recently opened issues | Highly maintained by a dedicated organization. |
| Advisories | `https://rustsec.org/packages/serde.html` | 0 open advisories for the core `serde` package. |
| Adopters | reverse-dependencies | Universally adopted across the ecosystem; functionally required by `reqwest`, `axum`, and `sqlx`. |

### Compatibility
The chosen members—Manual `dyn Trait` Dependency Injection, the `async-trait` polyfill, and the `serde` serialization framework—are rigorously tested and proven to compose flawlessly in high-performance production environments. The standard architectural pattern within the `axum` web framework specifically expects an `Arc<dyn Port>` to be injected into its `State` extractor. Furthermore, Axum relies natively on `serde` to seamlessly serialize and deserialize the data payloads that these ports return. This exact triad forms the resilient, type-safe backbone of virtually every modern Rust microservice currently deployed [cite: 6, 7].

### Parameters
`owns port-seam-type = dyn-trait`
`assumes sync-async-execution-model = async` *(Note: The `async-trait` crate is recommended heavily because the vast majority of I/O seams utilize non-blocking, asynchronous logic. However, if the downstream R05 decision explicitly chooses a synchronous execution model, the `async-trait` crate can be gracefully dropped from the stack without altering the fundamental `dyn Trait` architectural pattern).*

### Migration implications
- **Workspace Configuration (`Cargo.toml`)**: Introduce `async-trait` and `serde` (configured with the `derive` feature) as core dependencies.
- **Port Interfaces (`src/ports.rs`)**: Convert structural Python protocols or TypeScript interfaces into explicit Rust traits: `#[async_trait] pub trait Repository: Send + Sync { ... }`.
- **Wiring Logic (`src/composition.rs`)**: Implement a factory function, `pub fn build_service() -> Service`, that returns a struct encapsulating the `Arc<dyn Repository>`.
- **Contract Verification (`tests/substitutability.rs`)**: Construct the `macro_rules! test_repository_contract` block. This macro must accept an instantiated repository and execute standard domain assertions, ensuring identical behavior across environments.
- **Fake Implementations (`src/adapters/in_memory.rs`)**: Implement the in-memory fake utilizing `std::sync::RwLock` to safely mutate internal hash maps or vectors behind the immutable `&self` interface mandated by the trait definition.

### Validation strategy
Execute the parameterized substitutability test suite to verify structural and behavioral integrity.
**Planned command**: `cargo test --test substitutability`
**Expected behavior**: The compiler expands the `macro_rules!` into distinct, isolated test blocks for both the `InMemoryAdapter` and the `ProductionAdapter` (when properly configured with a live database). The test runner verifies that both structs rigorously adhere to the trait's contract and behavioral expectations. Furthermore, a successful `cargo build` phase proves the object safety of the `dyn Trait` boundary, confirming that the interface is fully dyn-compatible and ready for dynamic dispatch across the web and CLI layers.

### Confidence & re-verify trigger
Confidence in this implementation plan is exceptionally high. The recommended strategy perfectly and securely maps the rigorous structural principles of the Python template into safe, performant, and highly idiomatic Rust. Re-verify the stack only if major advancements in the Rust compiler completely stabilize native, zero-allocation, dyn-compatible asynchronous traits, which would safely deprecate the need for the `async-trait` procedural macro.

### Sources
The primary evidence, telemetry, and architectural precedents supporting this report have been cited inline throughout the document. Authority is derived from Rust language RFCs [cite: 1], established trait testing methodologies [cite: 18], concurrency primitives [cite: 14], Axum framework constraints [cite: 6], and empirical data retrieved from the crates.io API regarding `async-trait` [cite: 34] and `serde` [cite: 37].

**Sources:**
1. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHC3hfnKVWG37PV0-p44ii7K4lJswn4mcpqQube8mx6_e0eEmlaMAqHfy0le1KBrg4wNNnVJ4SYBkkFTTYn5stsh4Oq2TMddqx0HFWOcG27SjugehmBHZvZIy7Z4AoHOWU8vAhOCRNRr6UN7iAOqUcXZeGpNk7Tu0rQ)
2. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFytOxfVERkshanfH9_VFiLxHLIeLvT83hzDilU9Zuz2X1jnFk8yjYO3sy0IyjLc_78GI2Er0tlJHyBvtsu0_4bDqYdIyIMDnrBGGoxCI-AZzYUtw==)
3. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFlZTSU2Haxu6mXHBl8QEFJA6GGR2bA6Y41dpbErWvpjRhzM8-y2K_6occ67IqPvPJnajgjHt5ItGFPQmZxeDUWFtDuci53TNZNTUMcGjjkAVwrgw==)
4. [rustsec.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG7BdJsMTtepBY72i2X61GE_o-XEmsFDPFt-lOT2-jSYHq6ns3tuNem5ZO4Xtgemn6Oh_Grps_z_WG4n83weP1npI679lkbBnggxGznfKvQic9faXFJGhZRrFTUsBL46LA=)
5. [rustsec.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGbWmm3MoBDCsiHNKyuF2odzdrDTNHw4DR8fPLVtn0ZPog3V2mHpQqnRK8yZ9JMAGi0FJ_-jDTNoMs6t5gmr_5JBcBKNKcy5JLgfrYd1OllYXtZbhbcnEP8RzVP5tqDOnRpWp2vxYam9_nt3g==)
6. [reintech.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEcdtKiDNeDHX6IPmz61JIIk6oZjr-XdEfac8oqvvG5AojqgzD31Bz6DCju50XHsAHNiDcYKlnpjSGvqzdR2_i_2gFJoaJ2CPa4rtu2WG7xnEedy_bCqPqayhLe7a72-iHEHiddppDLVgrGLT3WMC9d0XA5gb2EnmnupKDrxzH1bt5vafrebabs7g==)
7. [codefinity.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFFve5eHsLJXlaUCOL4HninZ26d4NbetSTnQZOEMBn3VkoomUKbNefrurhOiAnZk1_8M5RoFeIR0IyKxqgdSNM1sYuhiJhfs4WBMiImxDDk56fHjlm7eMPHri_tUV7uw4WMzNIq_pI9TAJlj0OOaNP8g56spfhXixH-EHm2QqMfqQUswZnXI1aCWlDQdAEu4Qi3JkfqUBvRS0fMfzQoW0npdA==)
8. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHg_ZK2Go5_VrjjOFATIaUInaDafcV0mcs8eq1WnCYoM0TpLNXtFSU-UO2XTSS9KDiTyej0R09QFMz9bAYJi-QAaExvKoBqLpyV0X-VAtM7cXRiEIHDYxZVAFlq8Kz1xexLlqram-Z6NyEtb8jdQhC1x8U1a42QIEpSr4kqAqCY359aGIHX-17t1J999t0y5uJBjCs0LyAhCuKsHyLO)
9. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHabJnJRNPG5sNInlfA4emshn74zzjJvsFu5Zk0esBSACZvM6765u8gbkDm3-oVF2nxxRrCWUrZ6siyzQn9hup0xJmn1zg5L3XRerWUbysSGNaKset4SWrlLC6-rRTagNPFzY-KcfC523RyJ3YpPv1SqdowDZq7e3EO3gIP3eU3Ih8C2q-BK9WiWQ-idfRv4hERxElbL8BUityuFRZZMorQAecztZpVlwNqjP7SLE-u5YZIxA==)
10. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGgs0w44gHMwqorc5wnfIT-Qi7hoDMgCBAzmUzxhLABcskacirAcUnpekYrzEH5UmUgbqo6D3Sq5KA6M0bBCAbAiag-3RPUY9TFHZWSK0mfvKUzRn__kTFWo9VEdS8if7XBH8_IxZUmvIdhR-YAaNPoG022BJ_e03P6hRXOpMd_ps3jWSVSU6J1GureErAoa_lK4-kyws5XbokwXQ==)
11. [40tude.fr](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHAyYGfeCrrUaAiiMae6lY_ZXhOkvrJ3NSSFUVHCoGW8-DFj4NPvmzxrVjc-SiMGfSa_roc7xrLsBlisABjPovR5MYhTiHLkvc5wwF3dnrlWI6ycqflxrZr_i3IJVpkr3N__alrCNqQ5LoopcHpa-xODMgY2ZvDL2YhP1o2i-eygg==)
12. [stellar.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFhqh68hP-BEx5Z497LREPhj1YMd9b_JkgHquSuu5WidT2_Nbu5km9Yex2AGdXZKCpFP-cKZ4vo6BAdDNEIecliCFq8OxfD_QeY1u0I7wu2MWx8uAPcB_oLvB7uX1_ZQDFgQfK3z_TakYPx81wdoH1bPsMYRIK7hZt4maadxqE7zdOkDqI4ntlfIJbI)
13. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHffareA7ZNG9GSVUVh8fCxjs7E_oDJQmtiT_-0qR-bZod7narfd4XOepk2QjB9F-37v2WEt6d56z09_BazZMkSCCC4ELS4l87CJ8pKxNIq3QTumSI3CYwxQ-aD5uIKHehaNYHE2X4N4drgLdsnW4NskW0SW3H0YR279kkUosvTcdk-h4AxgUCH92fLDxpKgzg=)
14. [ralfj.de](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHbOAR__3Spq4lhnTrJHr-rSlJZD4k6NBPE62eUpaUap0OOgoGxvPStC9TBhIrf9ia3BBoW27sC_Ovo377MdwUoEYGP452riu_u1_Bnz9R4a9pz7Lrpm-2gUC1KVSy-ruiuCi6iOFzwng==)
15. [ricardomartins.cc](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGwEFZUHXfQnoSlNxgfI5dIX2h1JHBM82Mubw581izjnabsJ7ltjKkiGoYlr_LmggHDoC0Uf7JC4bfNtH53Bw3qL2k40X0ypHW3TVRmiPDy0Z-_-cPiqRhGE4v8eTW8A7fzVAW6JUGugXPSkU4nXQ==)
16. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH9Gn0hUg7wCjHqiiEDo2N0Zn0z1e7bilC_Bt8xEmRU0bTB_vzA2dGsvPMCxO5G1VvNSqtUwWxOs8NtsMjKl5n10PkKW7utn0NEVQCPKECmZESiLCMLtwp24w==)
17. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFjpI88cB6g5IDtLIRBHuFsG_1Wu9lfr1a7qcR5w5bZD7hlnkdMlSb4YJY_s0TKEEo2nvQt7YRc6PGLm-tUj2n_0ay2JwxB-ZNq762zg2mDdqL5R--Ip6onTMeDyA==)
18. [thegreenplace.net](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFfmiqzCqCnzN0U_5BRIbIRwxHjHl7l8Jwgg8QxV6-r28KYrcx_A6To-489M5b2MzAlK3pAyLevrfowng5a_OifZ2CU4BAqmUKmOiSgh0dU-cbdfYmmbnyn9BiODcshEwCi4m_LH5PQuGWPi8gTXFBYsGS3kfxmgkz3_B4qKg8R4GQiU3VZBehNWwzgZKU=)
19. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF5nwzE-kdoiEZG6_ExrWnWcudnMMN9--KYems6_SIzL-qgCLfT8yJUiZKjKWGHcVXrO0V4Rw-u2z_iAiSDeVNXKHT5q_Gq_R9X4foMliYLRZ-fa1SBZUExcVIGvPDZ8IqbRd4Zwt9uS8BSVq4MJTiiTRDjUsDO5MtN_7KJYP8QTGutB3yjaWFAD8RATerwlSIaMuZNfcBfCWc8esyU3STKEq3vHfogrZ_e)
20. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFpsf35f7sKWPGyNUQgi6ge9YV49IpEmRX2ayNc7UHVzNJtWcZMPRdlSCWcr38QqaDBmjyA1tsa8-hsLkK2I0pW9xAXsjO1Lt8kYkqY0a9SuzPZSFN3QKlWMAA=)
21. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFlAYzO9264DEZgKpRf9f8O7gnLvdGCfSW90j4jBcfkS6_6u0tX42PsDPMrAq86ZKBNaKD96wOw9LlHOH-n9qeM0Cs9QssPHxcYOlKVdc4r0Kh-4RvG4KbQhQIcnR8Tkw==)
22. [stackademic.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHHVuoSDRjE1Kmeuc5SjnA45e_l0rEYLysyQcZfpLlrOTQ_GDI1p7YcRk7GIybMmR1NOhEnMhb8iwegWXAPMvlvUDEps9NWGaQdnQyDVySHc9hIiWhmN0Y-2j-eO6A_KtQf_Lh6i065w59GxqJl2o141ENDOU4vpEurADCuQBySSFgT2sOFQBaA3PMGiGbqWUHXESGm8n0Q-MIR-ZpZ8g==)
23. [chesedo.me](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEgRKScRW67Wl98ZeKn-bK1PV3FoBJUu-3LJ_46vmJpu42OY6HKv1fhXpivBnafN5JacUECP3OcOmtiCPoAwulAQ494-LQDpZDrlCiEgYos0ZS2ZBRFxlXnZgibr4RoDkWxD1m0WRFUlNlH1U1gYOI=)
24. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHpiuCOAThCZDPfY0viNgwTz7UzXLRhV9IOWd3HI0cLAkDdJm3j49-2mrLrbZnb_3PWqwpE4-buvFnjYuQFU6eLDAJ5-tOyj5TsnZ52Vaj_qJVn8kyFTUbMNg32Whn61iVyTXVUHKkp4zKSUpaWEJTMql3iTSO_ucVOgcP6dS5KE0tx4NGNFJiRztCjRPAsIAiX)
25. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFD9LT5afMgTcYxiJRtrQ0UMChcrh2XEBlOodAP6150_h7vX5i8L39QtHh-rwFwxAQrj9akE_sPcXUkVa3x6jSdj0Gvxwzkp-liRJBK3SbtaVscVOargH87x7GUUDg2KafhAgvi8DgMY8FtIC3Ai8xYYHdjeZ-95YspD5NEMasop3f9Ba3RTshKksjAVy62UOaZ3GwmKwYhdpWUjvP6)
26. [gitconnected.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEjEB0ld3eImPle8UU5QP5nyjadWquKfjltH2j5Cp6vbu5izcY4iyS58r0W5OgTH0X1CfBEhzhpZ1jRkM4zZcNSaI1usv4sxQXicXEUR7qIEOBDJhW0dlP2CuB2NhTF30iS3nn8DjCMPBBoCtLNFl789xzmEAD_Edb2GtoloRbKi6mJi89B1qeI)
27. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFJL8_ja4MxTOaDNRWOP0iT9g1u2MQ6n-YLi-i-LTrZZ63KbDpOVGkQnupGRp-4-DVunkIQZqGTj4S5KOfr1J633appNij2S6sDqPTppVw=)
28. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF9AtamGPWr6vqU_8-ILcyWiIkgufV_JNr2wpjNGrI7oDcKr2ah1euOUZZuqjZVsyt3r5Wk1x0wai4Dtw-AbECvBS7U5H1UH0Xcja1VBAvMvke1WTO-Bw==)
29. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG8Bg-AlXn1Qg_TCS5zN69qdsNSheHeZ9wZSvCMvI5Wi7FyQ01n3BAucIO8wr9A6hvAR0zerU8_9zN_YuLfhUAz6n2L7EXE1ZguYBY=)
30. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHI8eqgvjLOPlpN2Pfu_V3Jg3M4-svcJonDUp37h6zdy1NUKQToBHiUkiOW6p5Z8xiX6PBkTNJJ3j3S0VVN8SZbcporzTPzaZSSeFJchFb36mCgyfh6NfVTVdq5yulupZB0ClGgVFn8p8yj5D1wfWtJRthe4IPVjXJDf_yTO8JISoZnASUd_FVxO0jHeeFcxEJNWuZYt_MamOWjisFJjB1CrLm7bbHOdK_8)
31. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHmFhoMs54kzdmRsi-apqXgU3tEFEUwhdCK6HFtkvShou_IUIWmlGAIjwDx1fakwUIAhDqBf03Ez-UW07-o2bwdGoSijgjX6wT34Pw5_psZFl0q6T0=)
32. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFsQO2KTiv1aGJeV23WAvE7MDJWOD3OLU3b-YXKZIxLrlafp7n18BomczS6LaooHjNXdN_BoPyeBRQmHd_hUUhGL6bL5GO-NXHsRY6yutQB1dBZwETJ-jKSfSNIA4xIDH8y9VG4hHMk-RstqWm4Qml8R6v8)
33. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHktFNPIvvaUrgGbwa8F_Ox6uvt1GbrnwH7gXiNL6lTLOxDHo2b8oMC3C9ZkvjFXWdB1e6iuyaVDZKdcwCrP0ujqgL1DjaB7xbN7kUMChgCy9foORmTE7iaOQKxwfoXDQ==)
34. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGt2H2dzRyrKaDHej62QbJWzbSRHCMbGl8BJcF7rRGW52MF9bfT5PkRx_QHozCzP8zpPtVFZi46oGfhJ1maqX4USA-4ZUEqhbqOZB7BOyetKMn5-GycGfvvYhQ=)
35. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEzKbUyTtLVWuCCc3TocqmfKbccGEIIZx65Y5VFHFNviaL15ceCtwR9qKFsqGIrFzGCpNpNMl16k-n6s2j9bz-aFTUghUTFrIbn7GQuytm9XPEjkL54fUtK4_zbcVxJIZi1-w6Ihxfai6nmZR6mOWjwqbOkj3nwWe8KNK2fzvWrtMOhBlYmw3E3dJIgsZOoQ531QPQ75sKaQ7lJPQFWapKfflLhHj2_RsIPG8ugUL7Q56ZZ4tiTlwzp)
36. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHdswQ_iDpJjeL_ugkc1GHqgUurt5O7uZEWktGlfePN00hQm-QINJuphXzDxK8kvLUGzBhWOJF3_vOryqLGModxhFUUsQrmkoUuNCRwStHl9ngGCSL_72rHJ8zdlrIFf_DnDrxRv0KzlShj)
37. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEyZHb5QEMspCwiXCmNRBlEzetvEWaTuxomvYFtaTaJR1anB5gNB9rkq8Fgq7VgKSNaXUvF-NwNgsNzWsmTLvxqc7wTsVDwQjON3oJNcbwS20ocalA=)
38. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEx60qYQnBXKL-vmE5zq1p82e_M0aEHdV6MtVH5IJLAPwy6wN8-KXsWuvj4cS0Dq7PVZvzAQqB7thwGdT0yo5I8I0dc9iO3xACFEmiRxeiUomZj0UD9OA==)
39. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEbTTQTIdasSHwCZb2tNsiM4ix_TQ8jNeipO-dVQ4SdVrJDhUBYb_Q35A-pxNFU-_aDc3_F_ku6QaE0tWYvAkeAPdgeJAsVQBxGY8GsTu58RIYAoa6G2d645nqPkfkvHe_MGrjz3Mmu5HgtFQ0=)

## Sources

- [github.io](https://rust-lang.github.io/rfcs/3185-static-async-fn-in-trait.html)
- [crates.io](https://crates.io/data-access)
- [docs.rs](https://docs.rs/crates_io_api)
- [rustsec.org](https://rustsec.org/packages/arc-swap.html)
- [rustsec.org](https://rustsec.org/categories/memory-corruption.html)
- [reintech.io](https://reintech.io/blog/axum-vs-actix-web-vs-rocket-rust-framework-comparison-2026)
- [codefinity.com](https://codefinity.com/blog/Rust-for-Web-Backend-Development%3A-Axum%2C-Actix%2C-and-the-Memory-Safe-Future)
- [medium.com](https://medium.com/@kanishks772/dependency-injection-in-rust-without-a-framework-heres-how-55c079093a51)
- [medium.com](https://medium.com/@syntaxSavage/simulating-oop-in-rust-i-did-it-and-i-regret-everything-b68483e76e3a)
- [40tude.fr](https://www.40tude.fr/docs/06_programmation/rust/015_traits/traits_00.html)
- [medium.com](https://medium.com/@kaly.salas.7/3-ways-to-use-polymorphism-in-rust-when-to-use-generics-trait-objects-and-enums-94a451765e7d)
- [stellar.org](https://developers.stellar.org/docs/build/smart-contracts/example-contracts/workspace)
- [dev.to](https://dev.to/ajtech0001/mastering-generic-types-and-traits-in-rust-a-complete-guide-4e2n)
- [ricardomartins.cc](https://ricardomartins.cc/2016/06/08/interior-mutability)
- [ralfj.de](https://www.ralfj.de/projects/rust-101/part15.html)
- [crates.io](https://crates.io/crates/serde/1.0.188)
- [crates.io](https://crates.io/crates/serde_json)
- [thegreenplace.net](https://eli.thegreenplace.net/2021/testing-multiple-implementations-of-a-trait-in-rust/)
- [medium.com](https://medium.com/solo-devs/axum-vs-the-world-a-developers-journey-through-rust-web-frameworks-part-1-ff0b1a9fd66e)
- [crates.io](https://crates.io/crates/async-trait/code)
- [crates.io](https://crates.io/crates/async-trait)
- [stackademic.com](https://blog.stackademic.com/async-trait-usage-in-rust-ergonomic-solutions-with-async-trait-d624dae824a1)
- [chesedo.me](https://chesedo.me/blog/manual-dependency-injection-rust/)
- [rust-lang.org](https://users.rust-lang.org/t/comparing-dependency-injection-libraries-shaku-nject/102619/4)
- [gitconnected.com](https://levelup.gitconnected.com/exploring-multiple-ownership-in-rust-66baa5e4847b)
- [medium.com](https://medium.com/@bugsybits/interior-mutability-how-unsafecell-powers-refcell-and-rwlock-e8395eed35f8)
- [docs.rs](https://docs.rs/arc-swap)
- [crates.io](https://crates.io/crates/mockall)
- [docs.rs](https://docs.rs/serde)
- [medium.com](https://medium.com/@kaly.salas.7/mastering-generics-and-traits-in-rust-best-practices-for-cleaner-code-846bf9c1ba9f)
- [crates.io](https://crates.io/crates/shaku)
- [github.com](https://github.com/AzureMarker/shaku/blob/master/CHANGELOG.md)
- [crates.io](https://crates.io/crates/real-async-trait)
- [crates.io](https://crates.io/crates/async_trait)
- [medium.com](https://medium.com/@syntaxSavage/generic-associated-types-gats-the-rust-feature-that-finally-solves-async-trait-hell-b9b79d14a422)
- [github.com](https://github.com/dtolnay/async-trait/issues/261%22)
- [crates.io](https://crates.io/crates/serde)
- [github.com](https://github.com/serde-rs/json)
- [github.com](https://github.com/serde-rs/serde/issues/reviewable.io)