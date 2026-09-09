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
provider: perplexity
model: sonar-deep-research
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

# Trait-Based Ports and Adapters for `rs-launch-blueprint`: Generics, Trait Objects, and a Verified Driven-I/O Seam

The driven‑I/O seam for `rs-launch-blueprint` should be expressed as a trait-based port and adapter split that follows hexagonal architecture and the Dependency Inversion Principle, with static dispatch via generics inside the core library, trait objects at application and test boundaries, and an explicitly shipped in‑memory fake adapter that is verified against the real adapter by a shared contract test suite. Rust’s trait system provides nominal compile‑time verification that each adapter satisfies the port, while a generic contract test function exercised against both fake and real adapters achieves behavioural substitutability on par with the Python blueprint’s parametrized tests, without requiring a mocking crate such as `mockall` for this specific purpose.[2][3][4][7][18] The composition root for the CLI and web service is best modeled as ordinary construction‑time wiring via free functions or small “builder” structs that instantiate concrete adapters and inject them into generic services, following Rust’s idiomatic explicit DI style rather than a container framework.[3][4][18] For the web layer, a framework such as `axum` can be used as a thin adapter over the same application service and data contract used by the CLI, with shared request and response types defined as `serde`‑derived structs in the library crate so that both front‑ends serialize and deserialize the same shapes without duplication.[10][11][13][14][16] Cross‑ecosystem, the shared requirement across Python, TypeScript, and Rust is the engineering principle of dependency inversion and ports‑and‑adapters rather than the exact language mechanism: `rs-launch-blueprint` should adopt traits as ports with DI via generics and trait objects, thereby realizing the same principle in a way that is idiomatic for Rust while explaining why TypeScript’s function‑injection seam remains a justified variation for that ecosystem.[2][3][4][10][13][18]

## Landscape

### Category and ecosystem mapping

The decision for `rs-launch-blueprint` concerns the category of “driven‑I/O injection seam” and how it is expressed architecturally and in code. At a conceptual level, this category sits within hexagonal or ports‑and‑adapters architecture and within Rust’s idiomatic patterns for dependency inversion and dependency injection.[3][4][6][10][13][18] Concretely, it touches several technical sub‑fields: Rust’s trait system and generics for compile‑time polymorphism, trait objects for runtime polymorphism, patterns and libraries for dependency injection, testing frameworks and mocking tools for verifying substitutability, and web frameworks and serialization crates for the web adapter layer that reuses CLI data contracts.[1][2][3][4][5][7][8][9][10][11][13][14][16][18]

Within the Rust ecosystem, this category can be mapped into three bins. The built‑in or first‑party toolchain bin is dominated by the language’s own trait system, generics, and trait objects, together with standard library traits such as `Read` and `Write` that already function as ports over I/O devices.[1][3][4][9][17][18] These language constructs and traits are essential because they provide compile‑time checked abstractions without any external dependencies and embody Rust’s approach to polymorphism and dependency inversion. The second bin, established industry standards, includes hexagonal architecture and clean architecture patterns expressed via traits and generics, widely adopted web frameworks such as `axum` and `actix-web`, serialization with `serde`, and testing and mocking utilities such as `mockall`.[3][4][6][7][10][11][13][14][16][19][20] These are widely referenced in documentation, tutorials, and real production systems, and they provide a practical foundation for building CLI, library, and web services that are decoupled from infrastructure. The third bin, up‑and‑comers, includes specialized architecture libraries like `hexser`, which aim to formalize hexagonal architecture in Rust with a rich set of traits and types for ports and adapters and graph validation, but have more limited adoption compared with simpler trait‑based patterns.[6][13]

This mapping provides the “forest before trees” view required by the survey method. The core choice of whether to express the seam via a port/adapter split or via direct function injection is located in the built‑in and standard patterns bin, and only secondarily involves specific crates. Rust’s traits and generics are the primary mechanisms, while web frameworks, serialization crates, and optional mocking libraries are secondary tools that must fit this primary architectural decision.[1][2][3][4][8][9][17][18]

### Authoritative sources and why they count

Several types of sources provide authoritative guidance for this decision. Documentation from the Rust project itself, including “The Rust Programming Language” book chapter on trait objects, is authoritative regarding how traits, generics, and dynamic dispatch work, what monomorphization means, and what trade‑offs arise between static and dynamic dispatch.[1][9][17] The language documentation describes trait objects as values that carry both a pointer to a concrete instance and a pointer to a vtable describing how to call its methods at runtime, and explicitly contrasts static dispatch via generics with dynamic dispatch via trait objects, noting the extra runtime cost and loss of inlining for dynamic dispatch.[1][9] This information is foundational because it determines how ports expressed as traits can be used with generics and trait objects and how that affects performance, binary size, and flexibility.

Independent write‑ups and training materials from experienced Rust practitioners also count as authoritative, especially when they focus on patterns rather than idiosyncratic code. The Software Patterns Lexicon’s chapter on dependency injection via traits and generics explains how Rust uses traits to describe required behaviour, generics for compile‑time polymorphism, and trait objects for runtime polymorphism, and it emphasizes that dependency injection in Rust is “ordinary construction‑time composition” rather than framework magic.[3] This is authoritative for architectural style because it captures a widely accepted view of Rust DI: traits defined on the consumer side, generics for core logic, trait objects at application boundaries, and explicit ownership and borrowing to make lifetimes and sharing honest.[3][4][18] Tutorials such as CodeSignal’s course on effective dependency management in Rust reinforce this view with concrete examples, showing how a `Car` struct can depend on an `Engine` trait and how both generics and trait objects can be used for dependency injection, explaining the performance and flexibility trade‑offs.[2]

Write‑ups focusing specifically on dependency inversion in Rust, such as Antonio Díaz’s blog and Rusty Yellow Pages’ explanation of traits and polymorphism for DI, further build an authoritative picture.[4][5] They show how traits embody abstraction, how `Box<dyn Trait>` or `Arc<dyn Trait>` can be used when heap allocation or shared ownership is needed, and they highlight the choice between generics and trait objects for static versus dynamic dispatch.[4][5] Mastering Object‑Oriented Design in Rust, an in‑depth book, emphasizes that Rust forces architecture to be explicit by requiring the programmer to choose between static and dynamic dispatch and to model ownership and borrowing explicitly; it describes traits as behavioural contracts that support interface‑based design without inheritance and identifies trait‑based DI via generics or `Arc<dyn Trait>` as idiomatic.[18] These sources are authoritative because they synthesize language features into architectural guidance rather than focusing on a single crate.

For web architecture and ports‑and‑adapters, blog posts and example repositories implementing hexagonal architecture in Rust, such as Cogs and Levers’ “Hexagonal Architecture in Rust” and codemountains’ axum DDD explicit architecture, provide concrete reference implementations.[13][14][16] They demonstrate domain crates that define entities and traits as ports, adapter crates that implement those traits with infrastructure, and driver layers such as HTTP servers built with axum that call into the domain via ports.[11][13][14][16] These examples are authoritative practice evidence because they are complete applications that embody the port/adapter pattern with Rust traits.

Mocking tools like `mockall` are documented on docs.rs and GitHub with usage examples showing how to generate mock structs from traits or concrete types and how to set expectations, making them authoritative for mocking and test double patterns.[7] Although mocking is not strictly necessary for structural verification of port‑adapter satisfaction, the documentation explains how to use `#[automock]` and manual `mock!` declarations to build flexible mocks that integrate with trait‑based design.[7] Similarly, the documentation of `hexser` on docs.rs describes its design for hexagonal architecture, with traits for ports and adapters and automatic graph construction, making it authoritative for more explicit architectural enforcement in Rust.[6]

The axum and actix‑web GitHub repositories and documentation are authoritative for web frameworks, particularly for understanding how they separate routing and handlers from persistence layers and how they encourage clean architecture by keeping web framework code out of domain modules.[11][16][19][20] Axum’s focus on ergonomics and modularity, its examples illustrating state injection and use of traits for abstracting over dependencies, and its adoption by clean architecture scaffolds such as `clean-axum` provide strong evidence for how to build web adapters that call into trait‑based ports.[11][16]

### Practice evidence: what well-regarded projects do

The practice evidence strongly supports trait‑based ports and adapter separation in Rust. Cogs and Levers’ “Hexagonal Architecture in Rust” describes a multi‑crate architecture where the domain crate defines entities and traits as ports, such as `Repository` and `UseCase`, the adapters crate implements those traits with concrete infrastructure types, and the HTTP crate uses axum to expose an HTTP API that calls into the domain via the ports.[13] This project demonstrates that traits are used as ports, that concrete systems implement these traits as adapters, and that test fixtures and mock repositories are provided to exercise the domain logic independently of infrastructure.[13] It also highlights that the domain crate has no dependency on axum or other infrastructure code, which is a strong realization of the dependency inversion principle in Rust.[13]

The axum DDD explicit architecture repository by codemountains reinforces this pattern.[14][15] It splits the application into four workspaces: a driver layer for controllers, an app layer for use cases, a kernel layer for domain, and an adapter layer for infrastructure.[14][15] The kernel layer defines repository traits, while the adapter layer implements those traits, and the app layer coordinates use cases using the traits.[14][15] The driver layer uses axum to expose routes and call into the app layer. This structure demonstrates the port/adapter split explicitly and uses Rust traits as the mechanism. It also shows that upper layers can call lower ones but not vice versa, enforcing dependency inversion across the stack.[14][15] This is directly analogous to the Python blueprint’s separation of `ProjectsRepository` protocol from adapters and composition root wiring, but expressed in Rust idioms.

The `clean-axum` scaffold further shows how web framework logic can be kept out of domain and persistence layers by separating API routing from persistence logic.[16] It emphasizes that the web framework should be replaceable and that modules should not include any specific API web framework logic, which aligns with ports‑and‑adapters and DI principles.[16] In this project, application services depend on abstractions rather than concrete persistence implementations, and axum handlers integrate with those abstractions. This provides strong evidence that the recommended seam mechanism for rs‑launch‑blueprint should reflect this style.

On the I/O and trait side, standard library traits like `Read` and `Write` illustrate Rust’s own ports‑and‑adapters pattern.[17] The `Read` trait defines a single required method `read` and many provided methods such as `read_to_string`, and concrete types such as `File` implement `Read`.[17] Buffered readers like `BufReader` wrap these and provide additional convenience. This demonstrates that traits can define capabilities and that concrete I/O types implement them, with adapters like `BufReader` and `Cursor` providing specific behaviours.[17] This pattern is directly analogous to defining a port trait such as `ProjectsRepository` or `HttpClient` and implementing it in multiple adapters.

Testing practice evidence comes from `mockall`, which shows that most traits can be mocked automatically with `#[automock]` and that mocks can be used as test doubles in unit tests.[7] This demonstrates that trait‑based design integrates well with testing patterns that require fakes or mocks, although it does not mandate using `mockall` for every port. The Python blueprint’s approach of shipping a first‑class in‑memory adapter and running a parametrized contract test suite against both it and the real adapter is very close to what Rust practitioners recommend when using traits and generics for DI.[3][4][10][13][18] The Rust DI write‑ups explicitly state that traits are defined on the consumer side and that generics or trait objects are used to inject dependencies at construction time, which maps directly to the composition root patterns in Python and TypeScript.[3][4][18]

Finally, the documentation and examples of axum show that the framework encourages modularity and separation of concerns in HTTP routing and request handling, which aligns well with building a thin web adapter layer that calls into the same trait‑based services used by the CLI.[11][16] Axum examples demonstrate how to attach application state to the router, often using an `Arc` to share services, and how to derive `serde` types for request and response bodies, which is exactly the mechanism needed for sharing CLI data contracts.[11][16]

### Fit for a CLI + library + web service template

The landscape and practice evidence must be evaluated against the specific shape of `rs-launch-blueprint`, which is explicitly a CLI, a library, and a web service. This shape demands an architecture where the core library can be used both by the CLI and by the web server, and where driven‑I/O, especially HTTP and storage, can be swapped between real and fake implementations for testing and alternative deployments.

For the core library, the fit is strongest with static DI via generics and traits. Rust’s generics enable monomorphization, where the compiler generates specialized versions of functions for each concrete type used, providing zero‑cost abstractions and the highest performance.[1][2][8][9][18] Inside the library, where types are known at compile time and the focus is on correctness and performance, generics with trait bounds are idiomatic. Traits serve as ports, and functions or structs use generic parameters such as `R: ProjectsRepository` to depend on the port. This pattern matches both the DI guidance from Rust patterns sources and the practice in hexagonal architecture examples.[3][4][10][13][14][18]

At the application boundaries—the CLI binary and the web server—the fit is stronger with trait objects and dynamic dispatch for convenience and runtime flexibility.[1][2][3][4][8][9][18] The DI writings and hexagonal architecture examples recommend using `Box<dyn Trait>` or `Arc<dyn Trait>` where type erasure is needed, where adapters may be selected at runtime, or where passing around generic types would be cumbersome.[2][3][4][5][18] In a CLI, this allows the composition root to decide whether to instantiate a real or fake adapter based on configuration or test harness, and to inject it into a non‑generic top‑level command dispatcher. In a web server built with axum, it allows the router state to carry an `Arc<dyn ProjectsRepository>` or `Arc<dyn HttpClientPort>`, which can be shared among handlers without propagating generic parameters through all route definitions.[11][13][14][16] This is a good fit for the `rs-launch-blueprint` stack.

Function injection without a port trait, as used deliberately in the TypeScript blueprint, fits TypeScript’s ecosystem where structural typing and function values are idiomatic and where a single HTTP transport seam is the main dependency injected into CLI handlers.[2] In Rust, however, this pattern is less idiomatic and more fragile, because function pointers alone lack the expressivity of trait‑based behaviour and are harder to extend to multi‑method ports or to share ownership semantics. The Rust DI literature emphasizes traits as contracts and discourages relying solely on function injection in place of traits for complex domain behaviours.[3][4][18] Therefore, the port/adapter split via traits is a better fit for Rust, and the function injection pattern remains a justified ecosystem‑specific variation in TypeScript rather than a shared architecture at the implementation level.

Taken together, the landscape, authority, and practice evidence point to a trait‑based port and adapter split with static DI via generics in the core library and dynamic dispatch via trait objects at application boundaries, with explicit composition roots for CLI and web, and shared `serde`-derived data contract types across both front‑ends. This yields a seam mechanism that fits the CLI + library + web shape and preserves the cross‑ecosystem principle of dependency inversion and ports‑and‑adapters while expressing it in Rust’s idioms.

## Principles and implementation

### Shared requirement, agreement level, and essential behaviours

The shared engineering requirement across Python, TypeScript, and Rust for this item is the principle of **dependency inversion with a driven‑I/O seam expressed as ports and adapters**, together with behavioural substitutability between real and fake implementations.[2][3][4][10][13][18] The owner’s direction describes that the Python blueprint separates a `ProjectsRepository` protocol from its adapters, wired by a composition root, verified structurally by the type checker, with a shipped in‑memory fake and a web layer that reuses the CLI’s data contract. The TypeScript blueprint injects concrete function values directly into the CLI router without a distinct port/adapter split, but still defines an interface `CliDeps` that describes the injected functions, thus preserving an abstract seam albeit at a finer granularity.[2]

The agreement level, according to the research mandate, is at the level of architectural pattern and engineering principle rather than exact mechanism. That means that all three ecosystems must agree on the presence of a driven‑I/O seam, on dependency inversion in the sense that core logic depends on abstractions rather than concrete infrastructure, and on substitutability between real and fake implementations verified by a shared contract test suite. However, they may vary in how the seam is expressed in language constructs and in the granularity of abstraction, provided these differences are justified by ecosystem characteristics and maintain the principle.[2][3][4][10][13][18]

Essential behaviours therefore include the following. First, core services must depend on an abstract port rather than on specific I/O or HTTP libraries, meaning that `ProjectsService` in Rust depends on a trait such as `ProjectsRepository` or `HttpClientPort`, not on `reqwest` or a concrete file store.[2][3][4][10][13][18] Second, one or more adapters must implement this port, including at least one real adapter and one in‑memory or fake adapter shipped as first‑class code in the library crate, not merely inline tests.[4][5][10][13][18] Third, a composition root must exist that wires the chosen adapter to the port for each runtime, such as CLI and web, and does so in a way that allows swapping the adapter for tests or alternative configurations without changing the core logic.[2][3][4][10][13][14][18] Fourth, a shared contract test suite must run against both adapters and assert behavioural equivalence as far as the port is concerned, supporting substitutability and detecting divergence when one adapter fails to respect the port’s semantics.[10][13][18] Fifth, the web layer must reuse the same data contract as the CLI, meaning that request and response shapes are defined once in the library and used both as CLI DTOs and as web serialization types with `serde`.[10][11][13][14][16]

Observable acceptance criteria follow from these behaviours. It should be possible to compile and run the library with either the real or the fake adapter without changing core service or CLI/web handler code, other than in composition root wiring.[3][4][10][13][14][18] The Rust compiler should reject any adapter that declares it implements the port trait but does not satisfy its method signatures, providing structural verification at compile time via nominal typing.[1][3][4][9][18] The contract test suite should be parameterized over the port trait and should be executable with either adapter, producing the same outcomes in terms of visible behaviour, and failing when adapters diverge.[10][13][18] The CLI and web front‑ends should be able to reuse the same data structures for input and output, and their integration tests should confirm that the CLI and web API present consistent behaviour for the same operations.

### Architectural alternatives: port/adapter vs function injection

Before choosing a Rust implementation, it is necessary to compare the primary architectural alternatives: a port/adapter split expressed as traits versus direct injection of function values without a port trait, as practiced in the TypeScript blueprint. The Python blueprint’s approach is clearly aligned with hexagonal architecture and ports‑and‑adapters: a protocol defines the port, concrete adapters implement it, the composition root wires them, and a web adapter reuses the CLI’s data contract.[10][13] The TypeScript approach is DI‑first, but chooses granular function injection while omitting a separate port type, relying on TypeScript’s structural typing to treat the `CliDeps` interface as a contract for the injected functions.[2]

In Rust, the function injection pattern could theoretically be replicated by passing closures or function pointers into services and CLI handlers, where each dependency is a function rather than a trait implementation. However, this pattern becomes unwieldy when the dependency’s behaviour consists of multiple closely related operations, such as listing, creating, updating, and deleting projects, or performing HTTP requests with shared configuration and error handling. It also complicates shared tests, because each function would need its own test contract and the notion of substitutability would have to be expressed separately for each capability rather than for a cohesive port.[3][4][18]

Rust’s trait system, on the other hand, provides a natural way to express cohesive behaviour as a port. A trait can define the methods required for a repository or HTTP client, and types implementing the trait must provide all methods with the correct signatures. The DI literature and practice evidence in Rust strongly encourage this trait‑based abstraction, describing traits as behavioural contracts and recommending that consumer code define traits as “ports” while infrastructure code provides “adapters” implementing those traits.[3][4][6][10][13][18] Hexagonal architecture examples in Rust, such as banker‑style projects and axum DDD scaffolds, show the practicality of this approach.[13][14][16]

Given this, the port/adapter split is more idiomatic in Rust, and expressing the seam as traits with DI via generics or trait objects aligns with both language design and architectural patterns. Function injection remains a valuable technique for very small seams, such as injecting a single HTTP transport function in TypeScript, but in Rust the weight of evidence points towards a trait‑based port being the right abstraction level for a driven‑I/O seam that will be shared between CLI, library, and web service.

### Generics vs trait objects for the port abstraction

Within trait‑based ports, the key question is whether the port abstraction for F001 should be expressed primarily via generics with trait bounds (static dispatch) or via trait objects (dynamic dispatch). The Rust book and multiple independent write‑ups explain the distinction clearly.[1][2][8][9] When generic code is used, the compiler performs monomorphization: it looks at all the places where a generic function is called and instantiates specialized versions of that function for each concrete type used, effectively erasing the generics and producing direct calls with static dispatch.[1][8][9] This provides maximum performance and allows inlining, but it means that each instantiation has its own copy of code and that generic types are homogeneous: a `Vec<T>` uses a single concrete `T`.[1][8][9]

Trait objects, indicated by `dyn Trait`, are different. They involve dynamic dispatch, where the compiler cannot know at compile time which concrete method implementation will be called. Instead, it builds a vtable that maps trait methods to concrete implementations and at runtime uses this vtable to dispatch the calls, incurring an indirection cost and preventing some inlining.[1][8][9] Trait objects allow heterogeneity: a `Vec<Box<dyn Trait>>` can store different concrete types implementing the same trait.[1][8][9] They also enable type erasure, where consumer code need not know the concrete types, only that they implement the trait.

The DI sources and hexagonal architecture examples converge on a rule of thumb: use generics and static dispatch inside libraries and core logic, and use trait objects and dynamic dispatch at application boundaries where runtime configurability and type erasure are valuable.[1][2][3][4][5][8][9][18] This guidance is especially relevant for a CLI + library + web target. Inside the core library, services and domain logic should be generic over the port trait. For example, a `ProjectsService<R: ProjectsRepository>` struct can be defined, and its methods can be monomorphized for each concrete implementation used.[3][4][18] This yields best performance and type safety at the core, where the set of adapters is relatively small and known at compile time.

At the CLI and web boundaries, convenience and runtime flexibility become more important. The composition root may need to choose at runtime whether to use the real adapter or the in‑memory fake, based on configuration or test harness. The web framework may need to store shared application state in a type that is easily passed around and not parameterized by generics, especially for router state or middleware.[11][13][14][16] In such places, using trait objects like `Arc<dyn ProjectsRepository>` or `Arc<dyn HttpClientPort + Send + Sync>` allows the application to treat any adapter uniformly, swap them at runtime, and avoid propagating generic parameters, at the cost of a small runtime overhead.[2][3][4][5][18]

For `rs-launch-blueprint`, the best trade‑off is therefore a hybrid. The port abstraction itself is a trait. The core library’s services are generic over this trait, using static dispatch and monomorphization, achieving zero‑cost abstraction. The composition root, CLI main, and web server modules inject concrete adapters either into generic services or wrap them into trait objects for runtime use. The web server’s router state can carry trait objects, while internal application services remain generic. This hybrid approach is also advocated by DI sources, which urge using generics inside libraries and trait objects at application edges.[3][4][18]

### Adapter verification: trait system vs mocking crate

The next high‑priority question is how to verify that an adapter satisfies the port at compile time and behaviourally, and whether a mocking or fake generation crate such as `mockall` is needed to reach parity with the Python blueprint’s parametrized fake‑vs‑real substitutability suite. Rust’s trait system provides nominal typing: a type explicitly declares that it implements a trait by an `impl Trait for Type` block, and the compiler checks that all required methods are provided with correct signatures.[1][9][18] This is stronger than Python’s structural typing via protocols because it is explicit and enforced at compile time without separate tooling.[1][9]

Structural verification that a concrete adapter satisfies the port is thus inherent in Rust’s trait system. If a developer attempts to declare `impl ProjectsRepository for FileProjectsRepository` but omits a required method or uses an incompatible signature, the compiler will fail, and the build will not succeed. This satisfies F011’s requirement for adapter‑satisfies‑port verification at the type level, in a way that is even stricter than Python’s `typing.Protocol` structural checks.[1][3][4][9][18]

Behavioural verification, however, requires tests. The Python blueprint uses a parametrized contract test suite that runs against both the real and the in‑memory adapter, asserting that they present the same behaviour in terms of the port. In Rust, a directly analogous pattern can be implemented without relying on `mockall` or similar crates. A generic test function can be defined that takes any `impl ProjectsRepository` and exercises the port’s methods, asserting expected behaviours. That test function can then be instantiated with different adapters and run as part of the test suite. For example:

```rust
pub trait ProjectsRepository {
    fn list_projects(&self) -> Result<Vec<Project>, RepoError>;
    fn add_project(&mut self, project: Project) -> Result<(), RepoError>;
    // More methods as needed
}

fn projects_repository_contract<R: ProjectsRepository>(mut repo: R) {
    // create project
    let p = Project { name: "example".to_string() };
    repo.add_project(p.clone()).unwrap();

    // list projects
    let projects = repo.list_projects().unwrap();
    assert!(projects.iter().any(|q| q.name == p.name));

    // additional behavioural assertions
}
```

In tests, this contract function can be called with the in‑memory adapter and the real adapter:

```rust
#[test]
fn in_memory_adapter_satisfies_contract() {
    let repo = InMemoryProjectsRepository::new();
    projects_repository_contract(repo);
}

#[test]
fn file_adapter_satisfies_contract() {
    let repo = FileProjectsRepository::new(temp_dir());
    projects_repository_contract(repo);
}
```

This pattern leverages generic functions and trait bounds, and does not require any mocking library.[3][4][18] It achieves behavioural parity with the Python blueprint’s contract tests, and ensures that any adapter used in production passes the same behavioural tests.

Mocking crates like `mockall` are valuable for other types of tests, particularly when the dependency is complex or when test expectations must be set dynamically or per call.[7] `Mockall` can generate mock struct types from traits via `#[automock]`, allowing tests to specify expectations on method calls, arguments, and return values.[7] However, for F011 and F121, which focus on verifying adapter satisfaction of a port and fake‑vs‑real substitutability, the simpler pattern of a shipped in‑memory adapter and a generic contract test suite is sufficient. Rust’s trait system already enforces structural correctness, and the contract tests enforce behavioural equivalence. Using `mockall` would add complexity and is not needed to reach parity with Python’s approach for this particular seam mechanism.[3][4][7][10][13][18]

### Composition root: idiomatic Rust shape

The composition root is the module or function where concrete adapters are instantiated and wired to ports and services. In Python, this appears as `build_projects_service()` binding a concrete adapter to the service. In TypeScript, `realDeps()` builds production values directly and injects them into CLI routers. Rust DI literature emphasizes that DI is not a framework feature but ordinary construction‑time composition using traits and generics.[3][4][18] That literature recommends defining traits at the consumer side, using generics for static DI, and trait objects or `Arc`/`Box` when sharing or indirection is needed.[3][4][18]

The idiomatic Rust shape for a composition root is therefore a function or a small module that constructs the graph of dependencies from the outside inward. For example, there can be a function `build_projects_service()` that returns a service generic over the repository trait but already bound to a concrete adapter:

```rust
pub fn build_projects_service() -> ProjectsService<FileProjectsRepository> {
    let adapter = FileProjectsRepository::new(default_path());
    ProjectsService::new(adapter)
}
```

Alternatively, the function can return a trait object, yielding a non‑generic service type that holds an `Arc<dyn ProjectsRepository>`:

```rust
pub struct ProjectsService {
    repo: Arc<dyn ProjectsRepository + Send + Sync>,
}

pub fn build_projects_service() -> ProjectsService {
    let adapter = Arc::new(FileProjectsRepository::new(default_path()));
    ProjectsService::new(adapter)
}
```

The DI patterns references recommend generics inside libraries and trait objects at application boundaries.[3][4][18] For `rs-launch-blueprint`, the library crate can define `ProjectsService<R: ProjectsRepository>`, while the binary crates (CLI and web) can define composition functions that instantiate `ProjectsService<FileProjectsRepository>` or `ProjectsService<InMemoryProjectsRepository>` or wrap those into trait objects for sharing. This avoids introducing any DI framework and keeps DI explicit and simple, as recommended by Rust patterns and hexagonal architecture examples.[3][4][10][13][18]

The composition root in the CLI crate can be a function `build_cli_app()` that sets up the command parser, constructs the real adapter, and injects it into the commands. The composition root in the web crate can be a function `build_router()` that constructs the service and adapter and injects them into axum handlers via router state. Both roots follow the same pattern: they depend on traits, they instantiate adapters, and they wire the graph explicitly.

### First-class in-memory adapter and supporting mechanisms

Shipping a first‑class fake or in‑memory adapter in the library crate is essential to meet F013 and to reach parity with Python’s approach, where an in‑memory `ProjectsRepository` is implemented in `core/adapters` and used in both tests and documentation.[10][13] Rust DI literature and dependency inversion write‑ups explicitly note that in‑memory adapters are a common pattern to enable tests and to decouple domain logic from infrastructure.[3][4][5][10][13][18]

In Rust, an in‑memory fake adapter can be implemented as a struct that holds in‑memory state, such as a `Vec<Project>` for projects. The trait port can be defined to accept `&mut self` for methods that mutate state, allowing the adapter to use ordinary mutable fields without interior mutability. If the trait must be usable behind shared references or `Arc`, methods may need to take `&self`, in which case interior mutability via `Mutex` or `RwLock` from the standard library or `parking_lot` could be used; however, these are standard concurrency primitives rather than specialized crates.[3][4][5][17][18]

For the blueprint, a simple synchronous trait with `&mut self` methods is sufficient and avoids extra complexity pending R05’s decision on async and concurrency. The in‑memory adapter can then be implemented as:

```rust
pub struct InMemoryProjectsRepository {
    projects: Vec<Project>,
}

impl InMemoryProjectsRepository {
    pub fn new() -> Self {
        Self { projects: Vec::new() }
    }
}

impl ProjectsRepository for InMemoryProjectsRepository {
    fn list_projects(&self) -> Result<Vec<Project>, RepoError> {
        Ok(self.projects.clone())
    }

    fn add_project(&mut self, project: Project) -> Result<(), RepoError> {
        self.projects.push(project);
        Ok(())
    }

    // more methods as required
}
```

This adapter lives in the library crate’s `adapters` module and is exported as a first‑class type, usable by tests, CLI, and web modules. It serves as a fake implementation that satisfies the port trait and can be used both for unit tests and for teaching examples. No supporting crate is needed beyond the standard library. If future requirements demand shared ownership and concurrency, the adapter can be wrapped in `Arc<Mutex<InMemoryProjectsRepository>>` or similar, again with standard tooling.[3][4][5][17][18]

Shipping this adapter, rather than keeping fakes inline only in tests, ensures that the seam mechanism is stable, documented, and reusable. It also allows the contract test suite to be written once and executed against both the in‑memory adapter and any real adapters, verifying substitutability.[10][13][18]

### Web layer reuse of CLI data contract

Finally, the web layer must reuse the CLI’s data contract without duplicating serialization types. Hexagonal and clean architecture examples in Rust show that traits and domain types are defined in core crates and reused across driver layers such as CLI and web.[10][13][14][16] Axum’s examples and documentation demonstrate that request and response bodies are typically modeled using `serde`‑derived structs, and that handlers can return `Json<T>` where `T` implements `Serialize`.[11][16] This provides a natural mechanism for reusing data contracts.

In `rs-launch-blueprint`, domain types such as `Project` and DTO types such as `CreateProjectRequest` and `ProjectSummary` can be defined in the library crate, derived with `serde::Serialize` and `serde::Deserialize`. CLI commands can use these types for reading and writing JSON or for printing structured output, while web handlers can use them for parsing request bodies and constructing response payloads. Axum’s router can be defined with handlers that accept `Json<CreateProjectRequest>` and return `Json<ProjectSummary>`, while CLI functions can call services that return `ProjectSummary` and print them or serialize them as JSON.[11][16]

This arrangement avoids duplication and ensures that the CLI and web layers present consistent behaviour. It also preserves the dependency inversion principle, because the core library depends neither on axum nor on CLI argument parsing; it defines only the domain and DTO types and traits as ports, while the CLI and web adapters sit on top. Hexagonal architecture examples in Rust explicitly highlight this separation, noting that the domain crate has no dependencies on web frameworks and that adapters implement the domain’s ports while translating external inputs into domain types.[10][13][14][16]

In summary, using `serde`‑derived shared types and web frameworks like axum that integrate with `serde` is the idiomatic way in Rust to reuse CLI data contracts in the web layer without duplication, and this approach fits the blueprint’s requirements and cross‑ecosystem principle.

## Recommendation

The recommended seam mechanism for `rs-launch-blueprint` is a **trait‑based port and adapter split implemented with static DI via generics inside the library and trait objects at application boundaries, with a first‑class in‑memory adapter, a generic port contract test suite, and shared `serde`‑derived types for data contracts across CLI and web.** The port abstraction (F001) is a Rust `trait` whose methods describe the driven‑I/O capabilities required by the core library, such as repository operations or HTTP client behaviour. Core application services are generic over this trait, using monomorphization and static dispatch for performance and type safety. The composition roots for CLI and web instantiate concrete adapters and inject them either as generic parameters into services or as trait objects wrapped in `Arc` for sharing, following Rust’s DI patterns.[2][3][4][10][13][18]

Adapter structural verification (F011) is provided by the Rust trait system itself: any adapter must declare `impl PortTrait for AdapterType` and will be checked at compile time for signature correctness.[1][3][9][18] Behavioural substitutability (F121) is achieved by a generic contract test suite that takes `impl PortTrait` and exercises its methods, with tests instantiated for both the in‑memory adapter and any real adapters, ensuring that they exhibit consistent semantics.[10][13][18] A mocking crate such as `mockall` is not required for this verification, though it may be used for other tests that need dynamic expectations.[7]

The composition root (F002) is implemented as ordinary construction‑time functions in the CLI and web crates, such as `build_projects_service()` or `build_router()`, that create adapters and services and wire them together. These functions may use generics when convenient or trait objects when runtime selection or shared state across handlers is needed.[3][4][10][13][14][18] No DI container crate is recommended; explicit wiring is idiomatic and avoids hidden complexity.

A first‑class in‑memory adapter (F013) is shipped in the library crate, implemented as a struct with in‑memory state such as a `Vec<Project>` and an `impl PortTrait for InMemoryAdapter`. It requires no special supporting crates beyond the standard library. If concurrency or shared ownership is needed, wrappers such as `Arc<Mutex<InMemoryAdapter>>` can be used. This adapter is exported for use in tests, CLI, and web, and is documented as part of the public API.[3][4][5][10][13][18]

The web layer (F018) uses a framework such as axum to define routes and handlers that act as thin adapters over the core services and ports. These handlers accept and return shared DTO types from the library crate, derived with `serde` for serialization. CLI commands also use these DTOs. This ensures that the CLI and web share the same data contract without duplication, and that web framework logic is kept out of the domain and service modules.[10][11][13][14][16]

Cross‑ecosystem, this recommendation preserves the shared principle of dependency inversion and ports‑and‑adapters while acknowledging that TypeScript uses function injection due to its language idioms, and thus the agreement level is at the architectural pattern rather than at the seam expression mechanism. Python and Rust share a trait/protocol‑based port abstraction, while TypeScript retains its DI‑first function seam. There is no baseline change requiring a `BASELINE-REVIEW` entry for F001, F002, F011, F013, F018, or F121; rather, the recommendation formalizes Rust’s implementation of the established principle.

The recommended stack of crates and patterns therefore consists of Rust’s built‑in trait and generics system for ports and DI, `serde` for data contract serialization, axum as the reference web framework for the web adapter, and `mockall` as an optional test crate for advanced mocking scenarios. Hexagonal architecture libraries such as `hexser` are treated as up‑and‑comers and are not part of the default stack, because simpler trait‑based patterns already satisfy the blueprint’s needs.[3][4][6][7][10][11][13][14][16][18]

## Members

### #### Trait-based Port and Static DI Pattern

##### Landscape

The trait‑based port and static DI pattern is not a crate but a language‑level and architectural pattern built on Rust’s traits and generics. It belongs firmly in the “built‑in or first‑party toolchain” bin of the landscape. The Rust book’s chapter on trait objects and generic traits provides the foundational description of how traits can be used with generics for static dispatch and with trait objects for dynamic dispatch.[1][9] It explains monomorphization, static dispatch, and dynamic dispatch, and notes the performance and flexibility trade‑offs.[1][9] Rust training materials, such as Ferrous Systems’ slides on I/O traits, illustrate how traits like `Read` and `Write` function as ports over I/O devices, with concrete types implementing them and buffered adapters adding behaviour.[17] These show the core pattern of traits as behavioural contracts.

Independent pattern write‑ups such as the Software Patterns Lexicon’s chapter on dependency injection via traits and generics and Rusty Yellow Pages’ explanation of dependency injection via traits and generics provide a detailed landscape view.[3][4] They explain that DI in Rust is explicit composition using traits, generics, trait objects, and ownership/borrowing. They emphasize that traits are defined on the consumer side, often called “ports,” and infrastructure code provides “adapters.”[3][4][6][10][13][18] They also advocate generics for compile‑time polymorphism, noting its performance benefits and the potential for code bloat if overused, and trait objects for runtime polymorphism and heterogeneous collections.[2][3][4][5][18]

Hexagonal architecture examples in Rust, such as the banker‑core and axum DDD explicit architecture repositories, situate this pattern firmly in the “established industry standard” bin for architecture. They define traits as ports in domain crates and implement those traits in adapters crates, demonstrating the practical application of trait‑based ports and static DI.[10][13][14][16] Together, these sources show that trait‑based ports and generics are the dominant architectural pattern for dependency inversion and DI in Rust.

##### Principles and implementation

The trait‑based port and static DI pattern embodies the principle that core logic should depend on abstractions rather than concrete implementations and that those abstractions should be expressed as behaviour‑defining contracts. In Rust, traits serve this role. For `rs-launch-blueprint`, a port trait such as `ProjectsRepository` or `HttpClientPort` would define methods for listing, creating, updating, and deleting projects or performing HTTP requests. Core services would be generic over this trait, such as `ProjectsService<R: ProjectsRepository>`. Methods on these services would call trait methods on the generic parameter, and the compiler would monomorphize these calls for each concrete adapter used.[1][3][4][9][18]

This pattern supports static DI. Construction functions in the library or in binary crates take concrete types that implement the port trait as generic parameters and instantiate services with those types. For example, a `ProjectsService<FileProjectsRepository>` can be constructed by passing a `FileProjectsRepository` into the service’s `new` function. The code remains generic inside, but all calls to `ProjectsRepository` methods are resolved at compile time, resulting in direct calls to the concrete type’s implementations.[1][3][4][8][9][18]

Implementation of this pattern in `rs-launch-blueprint` involves defining port traits in the library crate under a `ports` module. For each port, at least one real adapter and one in‑memory adapter are implemented in `adapters` modules. Services are defined as generic structs or functions bound by trait constraints. The pattern is complemented by contract tests defined as generic functions over trait bounds and by composition root functions that construct services with concrete adapters. The trait system ensures structural correctness of adapters, and monomorphization ensures performance.

##### Dominant choice

This trait‑based port and static DI pattern is the dominant choice in Rust for dependency inversion and DI, as evidenced by multiple authoritative sources and practice examples. The DI pattern write‑ups explicitly state that static DI via traits and generics is usually the default choice in Rust, especially inside libraries.[3][4][18] Hexagonal architecture implementations such as banker‑style projects and axum DDD scaffolds define traits for repositories and use cases and implement them with generics in domain services.[10][13][14][16] The Rust I/O traits themselves exemplify this pattern, with traits like `Read` and concrete types like `File` and `BufReader` implementing them.[17]

Given this dominance, there is no competing pattern at the same level of maturity and adoption for core library DI in Rust. Function injection is possible but not idiomatic for complex domain behaviour, and DI frameworks are rare and generally unnecessary.[3][4][18] Therefore, the trait‑based port and static DI pattern is the dominant choice for F001 and F002 inside the `rs-launch-blueprint` library.

##### Qualified shortlist

A qualified shortlist of patterns would include function injection of closures or function pointers into services as a lightweight alternative, and the use of specialized architecture libraries like `hexser` that formalize ports and adapters with additional tooling.[2][6][18] Function injection is attractive for very small seams, such as injecting a single `fetch` function, but becomes unwieldy for multi‑method ports. It also does not map as cleanly to hexagonal architecture patterns.[3][4][18] `Hexser` defines traits such as `Repository`, `UseCase`, and `Adapter` and provides automatic graph construction and intent inference, but introduces a heavier dependency and additional complexity.[6] For a blueprint template, these alternatives are less suitable than the straightforward trait‑based pattern.

##### Excluded by gate

No language feature or pattern fails the fitness gates in the same way that crates can, but function injection as the sole seam mechanism is excluded by the architectural gate: it does not provide a cohesive port abstraction, complicates substitutability tests, and diverges from Rust’s idiomatic patterns as captured by authoritative sources.[2][3][4][18] Similarly, relying entirely on `hexser` for ports and adapters is excluded by the simplicity gate for a blueprint: it introduces a specialized framework with its own traits and types, which may not be necessary for a starter template and could raise integration costs.[6][13]

##### Up-and-comers

The trait‑based port pattern is not an up‑and‑comer; it is established. However, explicit architecture libraries like `hexser` are up‑and‑comers in the sense that they wrap trait‑based patterns into higher‑level tooling.[6] `Hexser` provides traits for entities, repositories, and adapters, and aims to validate architectural graphs and enforce hexagonal constraints.[6] It may be considered in future iterations where stronger architectural validation is desired, but it is not part of the initial recommendation.

##### Fit for this template

For a CLI + library + web template, the trait‑based port and static DI pattern is an excellent fit. The library crate can define port traits and generic services, the CLI crate can instantiate services with concrete adapters using generics or trait objects, and the web crate can do the same. Static DI ensures high performance and type safety in the core library, while dynamic dispatch via trait objects at boundaries can be layered on top where needed. Hexagonal architecture examples in Rust confirm that this pattern works well for multi‑crate, multi‑front‑end systems.[10][13][14][16][18]

##### Recommendation

The recommendation is to adopt the trait‑based port and static DI pattern as the primary mechanism for expressing the driven‑I/O seam in `rs-launch-blueprint`. Port traits are defined in the library, services are generic over those traits, and composition roots instantiate concrete adapters via generics.

##### Ranked runner-up

The ranked runner‑up pattern is explicit architecture via `hexser`. It could be employed to formalize ports and adapters and to enforce architectural constraints, but is not recommended for the default template due to its added complexity and narrower adoption.[6][13]

##### Tradeoffs

The trade‑offs of the trait‑based port and static DI pattern include potential code bloat due to monomorphization when services are instantiated for many concrete types, and the need to manage trait bounds explicitly in function signatures and type definitions.[2][3][4][18] However, these trade‑offs are acceptable and widely managed in practice. The benefits include zero‑cost abstraction, strong type safety, and alignment with Rust’s language design.

##### Parameters

This member does not own or consume any explicit parameters beyond the overall rust edition and MSRV policy. It assumes that `rs-launch-blueprint` is built with Rust 2024 edition and stable minus two minor versions MSRV, consistent with the owner’s parameters. There is no conflict with R02 or R05.

##### Migration implications

Adopting this pattern implies adding a `ports` module to the library crate, defining traits for driven‑I/O, and converting any direct concrete dependencies in services into generic parameters subject to trait bounds. CLI and web crates must adjust their construction functions to provide concrete adapters implementing these traits.

##### Validation strategy

Validation involves writing a small example where a trait port, an in‑memory adapter, and a real adapter are defined, and a generic service uses the port. Running `cargo test` must succeed and show that both adapters satisfy the contract tests without any changes to the service code. This serves as acceptance for the pattern.

##### Confidence & re-verify trigger

Confidence in this pattern is high because it is deeply rooted in Rust’s design and practice. Re‑verification should occur if the Rust language introduces new mechanisms for DI or if the ecosystem converges on a different architectural pattern. Monitoring DI and architecture guidance and major framework practice is sufficient.

##### Sources

Key sources include the Rust book’s trait object chapter, DI pattern write‑ups, I/O trait documentation, and hexagonal architecture examples.[1][3][4][6][9][10][13][17][18]

### #### Trait Objects at Application Boundaries

##### Landscape

Trait objects are a built‑in language feature that enables dynamic dispatch in Rust.[1][8][9] They belong to the first‑party toolchain bin but represent a different dispatch mode compared to generics. The Rust book explains that trait objects point to both an instance of a type implementing a specified trait and a vtable used to look up trait methods at runtime.[9] It contrasts static dispatch via monomorphization with dynamic dispatch via trait objects and notes the runtime overhead and loss of inlining for dynamic dispatch.[1][9]

Independent articles such as Pratik Dhanave’s explanation of trait objects and dynamic dispatch and Daniel Di Dio Balsamo’s comparison of trait objects and generics provide authoritative discussion of patterns and trade‑offs.[1][8] They explain that generics are homogeneous and allow maximum performance, while trait objects are heterogeneous and flexible, enabling collections of different types implementing the same trait and runtime‑chosen behaviour.[1][8] DI pattern write‑ups also emphasize trait objects at application boundaries for runtime polymorphism and type erasure.[2][3][4][18]

In practice, trait objects are used widely in web and application code to store services and dependencies behind a common interface and to enable runtime selection. Examples from hexagonal architecture in Rust show routers and handlers depending on trait object ports rather than generic types when sharing state across threads and modules.[10][13][14][16]

##### Principles and implementation

The principle behind using trait objects at application boundaries is that interfaces should remain stable while concrete implementations may vary at runtime. In a CLI or web application, configuration and test harnesses may select different adapters at startup. Trait objects enable this by allowing a single type like `Arc<dyn ProjectsRepository>` to be used in application state, with different concrete types behind it.[1][2][3][4][5][8][9][18]

Implementation in `rs-launch-blueprint` involves defining trait ports and using trait objects in composition roots and router state. For the CLI, a main function or composition root can create either a real adapter or the in‑memory adapter and wrap it in a trait object:

```rust
pub fn build_cli_service(use_fake: bool) -> ProjectsService {
    let repo: Arc<dyn ProjectsRepository + Send + Sync> = if use_fake {
        Arc::new(InMemoryProjectsRepository::new())
    } else {
        Arc::new(FileProjectsRepository::new(default_path()))
    };
    ProjectsService::new(repo)
}
```

For the web server, axum’s `Router` can be built with application state containing a trait object:

```rust
#[derive(Clone)]
pub struct AppState {
    pub projects_service: Arc<ProjectsService>,
}

pub fn build_router(state: AppState) -> Router {
    Router::new()
        .route("/projects", get(list_projects))
        .with_state(state)
}
```

Handlers then receive `State<AppState>` and call methods on `projects_service`, which internally depends on a trait object port.[11][13][14][16]

This pattern ensures that application code for CLI and web deals with stable interfaces, while the choice of adapter remains configurable and easily testable.

##### Dominant choice

Trait objects are the dominant choice for runtime polymorphism and type erasure at application boundaries in Rust, as indicated by DI patterns and practice examples.[2][3][4][18] Alternatives such as enums representing specific adapter types exist but require updating the enum whenever new adapters are added, reducing extensibility. Trait objects allow new adapters to be added without changing application code, provided they implement the trait.

##### Qualified shortlist

A qualified shortlist of alternatives includes using enums of adapter types and matching on them to perform operations, or using generics with explicit type parameters throughout application code. Enums are simpler but less extensible and require more boilerplate. Generics provide static dispatch but complicate router state and CLI command wiring, as generic parameters must be propagated everywhere.[3][4][18] For a blueprint template, trait objects strike the best balance.

##### Excluded by gate

No trait object pattern fails fitness gates because it is a language feature. However, using enums instead of trait objects is excluded by the extensibility gate: it clashes with the desire to add new adapters without modifying core application code.

##### Up-and-comers

There are no up‑and‑comer features directly competing with trait objects for dynamic dispatch; they are core to Rust’s design.

##### Fit for this template

Trait objects fit a CLI + library + web template well, enabling runtime configuration of adapters and shared application state in web frameworks. They integrate naturally with `Arc` and other sharing mechanisms and align with axum’s pattern of attaching state to routers.[3][4][11][13][14][16][18]

##### Recommendation

The recommendation is to use trait objects at application boundaries in `rs-launch-blueprint` where runtime selection of adapters and shared state across handlers is needed, while keeping core services generic over traits.

##### Ranked runner-up

Generic services with explicit type parameters used throughout CLI and web code are a runner‑up but are more cumbersome and less flexible.

##### Tradeoffs

The trade‑offs include a small runtime overhead due to vtable lookups and reduced opportunities for inlining and optimization compared to static dispatch.[1][8][9] However, for application boundaries and typical CLI and web workloads, this overhead is acceptable and rarely dominates performance. Dynamic dispatch also reduces binary size compared to monomorphization when many adapter types are used, because only one version of code is generated.[1][8][9]

##### Parameters

This member assumes no constraints from R05 other than that runtime selection of adapters remains desirable. It respects the MSRV policy because trait objects are a stable language feature.

##### Migration implications

Introducing trait objects implies that services may need to accept `Arc<dyn PortTrait>` instead of generic parameters in some modules. CLI and web code must be adapted accordingly.

##### Validation strategy

Validation involves writing a small example where configuration toggles between real and fake adapters, both wrapped as trait objects, and verifying that CLI commands and web endpoints behave correctly under each configuration.

##### Confidence & re-verify trigger

Confidence is high. Re‑verification should occur if future Rust versions introduce alternative mechanisms for type erasure or if performance analysis shows dynamic dispatch overhead becoming bottleneck in specific contexts.

##### Sources

Sources include the Rust book, trait object articles, and DI pattern write‑ups.[1][2][3][4][8][9][18]

### #### In-Memory Fake Adapter

##### Landscape

The in‑memory fake adapter is a pattern rather than a crate. It belongs to the pattern bin for test doubles and hexagonal architecture. Hexagonal architecture descriptions emphasize driven adapters that implement ports and driven ports that abstract external systems.[10] In‑memory adapters are common driven adapters for testing and for simple scenarios where no real infrastructure is needed.[10][13][18] DI pattern articles and dependency inversion write‑ups in Rust note that in‑memory implementations are useful for tests and for decoupling the domain from infrastructure, often pointing out that these can be shipped as first‑class types in core crates.[3][4][5][10][13][18]

Mocking tools like `mockall` provide another approach to test doubles, but they generate mocks rather than implementing actual in‑memory behaviour.[7] This difference is important: in‑memory adapters are real implementations of the port with specific behaviour (for example, storing data in a `Vec`), while mocks are programmable test doubles with expectations and canned responses.[3][4][7][18] Both exist in the landscape but serve different roles.

##### Principles and implementation

The principle of shipping an in‑memory fake adapter is to provide a real, deterministic implementation of the port that does not depend on external systems and is suitable for both tests and for documentation examples. In Rust, this means implementing the port trait on a struct that holds in‑memory state, such as a vector. For `ProjectsRepository`, this struct can hold a `Vec<Project>` and implement methods to push and retrieve projects, as shown earlier.

The implementation details include choosing appropriate ownership and mutability semantics. For synchronous operations in tests and CLI, methods can take `&mut self` and operate on a mutable vector. For more complex concurrency needs, methods could operate under `Mutex` or `RwLock`. However, given that R05’s sync/async shape is undecided and the blueprint aims for a simple seam, a synchronous in‑memory adapter is sufficient.

The adapter must satisfy the port trait structurally and semantically. Structural satisfaction is guaranteed by the trait system; semantic satisfaction is ensured by running the contract test suite against the adapter.[1][3][4][9][10][13][18] This suite must check that operations behave in a way consistent with the port’s documented semantics, such as preserving insertion order and handling errors.

##### Dominant choice

In‑memory adapters are the dominant choice in hexagonal architectures and DI patterns for testable ports, as they provide real behaviour without depending on infrastructure.[3][4][10][13][18] Generated mocks are a complementary pattern but not a replacement in terms of semantics, as they often serve different test scenarios.

##### Qualified shortlist

The qualified shortlist includes using `mockall` to generate mocks of the port trait instead of implementing an in‑memory adapter. `Mockall` can create a mock struct that satisfies the trait, allowing tests to set expectations and responses.[7] This is powerful for certain tests but does not provide a default, well‑documented behaviour implementation useful for documentation and examples. Therefore, mocks are complementary rather than primary.

##### Excluded by gate

No pattern is excluded outright, but relying solely on mocks and not implementing an in‑memory adapter is excluded by the documentation and substitution gate: it would make it harder to illustrate behaviour and to have a stable fake implementation usable in CLI and web for demonstration purposes.

##### Up-and-comers

There are no notable up‑and‑comer patterns beyond in‑memory adapters and mocks for this specific seam; both are stable and widely used.

##### Fit for this template

An in‑memory adapter fits the CLI + library + web template very well. It can be used in CLI tests, web integration tests, and examples. It allows running the application entirely in memory, without real persistence, which is useful for acceptance tests and ephemeral contexts.

##### Recommendation

The recommendation is to implement an in‑memory adapter for each major port in the library crate, starting with the driven‑I/O port that R01 owns, and to export it as part of the public API.

##### Ranked runner-up

Using `mockall` to generate mocks for the port trait is a runner‑up, suitable for unit tests but not as a replacement for a shipped in‑memory adapter.

##### Tradeoffs

Trade‑offs include maintaining the in‑memory adapter as the port evolves and ensuring that its behaviour remains consistent with the real adapter. However, the contract test suite can mitigate divergence.

##### Parameters

No explicit parameters beyond MSRV and edition are consumed. The pattern assumes synchronous operations; any change to async shape decided by R05 may require revisiting the adapter’s implementation.

##### Migration implications

Adding an in‑memory adapter implies creating an `adapters::in_memory` module in the library crate and updating tests and composition roots to use it where appropriate.

##### Validation strategy

Validation involves running the contract test suite against the in‑memory adapter and ensuring that CLI and web examples using it behave correctly in a mode where no external persistence is configured.

##### Confidence & re-verify trigger

Confidence is high. Re‑verification should occur when the port trait changes or when new driven‑I/O capabilities are added, ensuring that the in‑memory adapter and contract tests remain aligned.

##### Sources

Sources include DI and dependency inversion write‑ups and hexagonal architecture examples.[3][4][5][10][13][18]

### #### Serde-based Shared Data Contract

##### Landscape

`Serde` is an established industry standard for serialization and deserialization in Rust. While not directly cited in the search results, its integration with web frameworks like axum is widely understood, and axum examples demonstrate deriving `Serialize` and `Deserialize` on types used as JSON bodies.[11][16] Hexagonal architecture examples also assume or use serialization traits for DTOs.[10][13][14][16] Thus, `serde` belongs in the established standard bin for data contracts.

The Rust API guidelines recommend using standard traits like `From`, `AsRef`, and `AsMut` for conversions and implementing `std::error::Error` for error types, which implies that data and error types in libraries should be designed to interoperate with standard traits.[12] This is consistent with using `serde` for serialization, as it complements Rust’s trait‑heavy design.

##### Principles and implementation

The principle of using `serde` for shared data contracts is that the same struct definitions can be used for CLI input/output and web request/response bodies, eliminating duplication and ensuring consistency.[10][11][13][14][16] In `rs-launch-blueprint`, DTO types such as `CreateProjectRequest` and `ProjectSummary` should be defined in the library crate and derived with `serde::Serialize` and `serde::Deserialize`. CLI code can parse JSON input into `CreateProjectRequest` and serialize responses as `ProjectSummary`, while axum handlers can accept and return `Json<T>` where `T` is one of these DTOs.[11][16]

Implementation involves adding `serde` and `serde_json` as dependencies to the library crate, enabling derive macros via `serde`’s `derive` feature, and annotating DTO types with `#[derive(Serialize, Deserialize)]`. Error types can implement `std::error::Error`, `Display`, and optionally `Serialize` for debugging or external reporting, as per Rust API guidelines.[12] Web adapters built with axum can then use these types directly in handlers.

##### Dominant choice

`Serde` is the dominant choice for serialization in Rust, and its integration with axum and other web frameworks makes it the clear choice for shared data contracts in this template.[11][16] Alternative serialization crates exist but are less widely adopted for JSON APIs.

##### Qualified shortlist

Qualified alternatives include using manual serialization via `std::fmt::Display` and `FromStr` for simple types or using different serialization crates for non‑JSON formats. However, for a CLI + web blueprint where JSON APIs are typical, `serde` is superior.

##### Excluded by gate

No alternative fails the fitness gates outright, but manual serialization is excluded by the maintainability gate for complex DTOs.

##### Up-and-comers

No notable up‑and‑comer serialization frameworks challenge `serde` for this use case within the evidence provided.

##### Fit for this template

`Serde` fits perfectly: it supports CLI and web serialization, integrates with axum for `Json<T>` payloads, and supports error serialization if needed.[11][12][16]

##### Recommendation

The recommendation is to adopt `serde` and `serde_json` for shared DTOs and data contracts between CLI and web in `rs-launch-blueprint`.

##### Ranked runner-up

Manual serialization for trivial DTOs is a runner‑up but not appropriate for a general template.

##### Tradeoffs

Trade‑offs include compile‑time cost for derive macros and binary size due to `serde`’s code, but these are widely accepted and manageable.

##### Parameters

This member assumes JSON as the default data format; if future requirements mandate different formats, additional crates may be needed.

##### Migration implications

Adding `serde` requires updating `Cargo.toml` and annotating DTO types with derive macros. CLI and web code must be updated to use `serde` types.

##### Validation strategy

Validation involves writing integration tests where CLI commands and web endpoints exchange JSON and ensuring that both use the same DTO types and produce consistent behavior.

##### Confidence & re-verify trigger

Confidence is high. Re‑verification is needed only if the ecosystem moves away from `serde` for JSON APIs.

##### Sources

Sources include axum documentation and Rust API guidelines.[11][12][16]

### #### Axum Web Adapter Layer

##### Landscape

Axum is an established industry‑standard web framework in Rust focused on ergonomics and modularity. Its GitHub repository describes it as an HTTP routing and request‑handling library and provides examples of usage.[11] The `clean-axum` scaffold demonstrates axum’s use in clean architecture, separating API routers from persistence layers and emphasizing that the web framework should be replaceable.[16] Axum is actively maintained, widely referenced in Rust web development, and used in hexagonal architectures.[13][14][16]

Actix‑web is another dominant web framework, described as pragmatic and extremely fast.[19][20] It is maintained under the Actix organization and is widely used. Both frameworks belong in the established standard bin for web services.

##### Principles and implementation

The principle behind using axum for the web adapter layer is that web framework code should be kept in driver crates, while domain logic and ports reside in core crates, and that handlers should be thin adapters translating HTTP requests into domain operations.[10][11][13][14][16] Axum fits this principle by allowing routers and handlers to be defined with minimal boilerplate and by integrating with `serde`

## Sources

- [Trait Objects and Dynamic Dispatch - Pratik Dhanave](https://pratikdhanave.com/blog/posts/rust-12-trait-objects.html)
- [Effective Dependency Management in Rust](https://codesignal.com/learn/courses/clean-code-with-multiple-structs-and-enums/lessons/effective-dependency-management-in-rust)
- [Dependency Injection via Traits and Generics in Rust](https://softwarepatternslexicon.com/rust/creational-design-patterns-in-rust/dependency-injection-via-traits-and-generics/)
- [Rust - Dependency injection via traits/generics - Rusty ...](https://rustyyellowpages.dev/concepts/traits-polymorphism/dependency-injection-via-traits.html)
- [Dependency inversion in Rust - Antonio Díaz](https://www.antoniodiaz.me/en/blog/dependency-inversion-in-rust-6)
- [hexser - Rust](https://docs.rs/hexser/latest/hexser/)
- [mockall - Rust](https://docs.rs/mockall/latest/mockall/)
- [Rust: Trait objects vs generics](https://dev.to/daniel_di_dio_balsamo/rust-trait-objects-vs-generics-3p11)
- [Using Trait Objects That Allow for Values of Different Types](http://rust-lang.github.io/book/ch18-02-trait-objects.html)
- [Hexagonal architecture, test doubles, and traits - n14n.dev](https://n14n.dev/articles/2023/testing-part-2/)
- [GitHub - tokio-rs/axum: HTTP routing and request-handling library ...](https://github.com/tokio-rs/axum)
- [Interoperability - Rust API Guidelines](https://rust-lang.github.io/api-guidelines/interoperability.html)
- [Hexagonal Architecture in Rust · Cogs and Levers](http://tuttlem.github.io/2025/08/31/hexagonal-architecture-in-rust.html)
- [codemountains/axum-ddd-explicit-architecture: An ...](https://github.com/codemountains/axum-ddd-explicit-architecture)
- [axum-ddd-explicit-architecture/README.md at main · codemountains/axum-ddd-explicit-architecture](https://github.com/codemountains/axum-ddd-explicit-architecture/blob/main/README.md)
- [kigawas/clean-axum: Axum scaffold with clean architecture](https://github.com/kigawas/clean-axum/)
- [Rust I/O Traits - Rust Training Slides by Ferrous Systems](https://rust-training.ferrous-systems.com/v1.10.0/book/io)
- [Mastering_Object_Oriented_Design_in_Rust.pdf](https://simplifycpp.org/books/rust/Mastering_Object_Oriented_Design_in_Rust.pdf)
- [Actix](https://github.com/orgs/actix/repositories)
- [Actix](https://github.com/actix)

## Cost

Total: $0.6498