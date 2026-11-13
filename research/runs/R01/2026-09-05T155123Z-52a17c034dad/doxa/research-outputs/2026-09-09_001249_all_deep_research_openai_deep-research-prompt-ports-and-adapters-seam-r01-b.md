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
provider: openai
model: gpt-5.6-sol
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

## Reasoning Summary
**Considering mockall members**

I'm thinking maybe I should have one member for `mockall`. The "Members" section should list each member from the recommended stack instead of just candidates. I’ll need to fill in details for each member with a qualified shortlist, which will help clarify things. Also, I'm wondering if it would make sense to group `serde` and `serde_json`. That might simplify the information a bit!

### Landscape

**Decision category:** dependency-inversion mechanism for a driven-I/O boundary in a Rust application that is simultaneously a public library, CLI, and web service.

**Source notation:** `[S#]` identifies an external source whose URL and retrieval date appear under `### Sources`; `[P#]` identifies owner-supplied repository evidence or fixed parameters. Externally verifiable claims also carry rendered citations.

#### Three-bin field map

| Bin | Candidates found | Disposition |
|---|---|---|
| **Built-in / first-party toolchain** | A nominal Rust `trait` with a generic `R: Port`; a `dyn Port` trait object in `Box`/`Arc`; injected `Fn`/function values; explicit constructors; `impl Trait`; enums for a finite runtime-selected adapter set; `Arc<Mutex<_>>`; `macro_rules!` or shared generic test functions | **Shortlist:** nominal trait + generic service. **Runner-up:** trait object at an explicit type-erasure boundary. Function injection is retained only for genuinely single-operation callbacks. |
| **Established industry standard** | Generic-first abstractions with optional type erasure, exemplified by Tower’s generic `Service` and `BoxService`; Serde for shared typed data contracts; Mockall for generated interaction mocks | **Adopt:** Serde. **Reference pattern:** Tower’s “generic first, box when necessary.” **Do not adopt:** Mockall for F011/F121 because it does not replace a real-vs-fake behavioral contract. |
| **Up-and-comer / narrower specialist** | Shaku compile-time DI; Faux struct mocking; architecture-specific crates such as `hexser` | Not selected. They add macros, framework policy, unsafe test machinery, or architecture-specific types without supplying a capability missing from stable Rust. Shaku remains a re-evaluation candidate if the dependency graph becomes substantially larger. |

Rust generics are monomorphized, while trait objects use runtime dynamic dispatch. The current Rust Reference also says dyn-compatible methods cannot be `async fn` or return an opaque `impl Trait`; that matters because R05 has not selected the execution model. [S1–S3] ([doc.rust-lang.org](https://doc.rust-lang.org/book/ch18-02-trait-objects.html))

Tower provides strong practice evidence for a **generic core plus optional explicit type erasure**: Tower’s `Service` is generic, `BoxService` erases a concrete service when needed, and Tower maintainers identify Hyper, Tonic, Warp, and Axum as major dependents. Tower’s own middleware guide avoids a boxed future where repeated allocation could matter. [S7–S9] ([docs.rs](https://docs.rs/tower/latest/tower/util/struct.BoxService.html))

Axum’s maintained `State` API demonstrates that a web adapter can hold a concrete, cloneable application state, normally sharing expensive state through `Arc`; it does not require a DI container or a boxed domain port. [S10] ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.State.html))

Serde is the established Rust mechanism for typed, format-independent serialization. Its maintainers show the same structs deriving `Serialize`/`Deserialize` and being encoded by a separate format crate. The current surveyed releases are `serde 1.0.229` and `serde_json 1.0.151`. [S11–S13] ([docs.rs](https://docs.rs/serde/latest/serde/?search=ser%3A%3ASerializer))

Mockall `0.15.0` is a capable generated-mock library, uses stable safe Rust, and declares MSRV 1.77. Its purpose is configurable interaction mocks, not proving that a shipped in-memory implementation and a production adapter obey the same behavioral contract. [S14] ([github.com](https://github.com/asomers/mockall))

Faux `0.1.13` targets concrete-struct mocking and states that it makes liberal use of unsafe Rust. Shaku `0.6.2` provides macro-based compile-time DI, normally resolving `Arc<dyn Interface>` values; its documented MSRV is 1.88 and its maintainer describes its foundation as stable with limited major changes planned. [S15–S16] ([docs.rs](https://docs.rs/faux/latest/faux/))

#### Authorities and why they count

| Authority | Why authoritative here |
|---|---|
| Rust Reference and The Rust Programming Language | First-party normative and explanatory sources for trait implementations, monomorphization, trait objects, and dyn compatibility. [S1–S3] |
| Cargo Book | First-party definition and behavior of `package.rust-version`. [S4] |
| 2025 State of Rust Survey and compiler-performance survey | Rust-project publications based on 7,156 and more than 3,700 respondents respectively; relevant because compile-time cost is one of the generic-vs-macro/container trade-offs. [S5–S6] ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/)) |
| Tower and Axum maintainers’ documentation | Maintained reference APIs from the Tokio ecosystem, with named major downstream adopters and production history. [S7–S10] |
| Serde, Mockall, Faux, and Shaku maintainers’ documentation | Primary sources for feature, MSRV, unsafe, default-feature, and intended-use claims about those candidates. [S11–S16] |
| crates.io, GitHub, and RustSec endpoints | Owner-mandated sources for release, popularity, issue, and advisory figures. [S18–S20] |

#### Practice evidence and evidence gap

The strongest current practice evidence supports Rust’s built-in trait/generic mechanisms and optional type erasure, not a framework-independent DI crate. Tower is a well-established compatibility abstraction used by several major networking projects, while Axum’s state model composes concrete state explicitly. [S7–S10] ([github.com](https://github.com/tower-rs/tower/issues/636))

No single mainstream repository was found that exactly combines all of F001, F002, F011, F013, F018, and F121 in the required CLI-plus-library-plus-web shape. The recommendation therefore composes maintained language and ecosystem patterns, and the exact bundle must be proven by the template’s integration suite.

#### Fitness gates before popularity

| Candidate | Gate assessment |
|---|---|
| **Rust trait + generic service + std composition/fake** | License and dependency MSRV are inapplicable because no external crate is added; stable Rust only; no unsafe required; OS-neutral; no features or runtime coupling; lowest added compile/dependency cost. **Pass.** |
| **`Arc<dyn Port>`** | Same built-in gate result, but current dyn compatibility constrains the signatures R05 may choose. **Passes gates; loses on fit.** |
| **Injected `Fn` values** | Same built-in gate result. **Passes gates; loses capability cohesion and reusable-contract ergonomics for a multi-operation repository.** |
| **Serde bundle** | Dual MIT/Apache licensing is verified; no async-runtime coupling; `derive` adds proc-macro compile cost. Exact MSRV-tree, RustSec, and platform checks must be executed on the fixed CI matrix before merge. **Recommended subject to mechanical gate execution.** [S11–S13] |
| **Mockall `0.15.0`** | Dual license, safe stable Rust, MSRV 1.77; proc-macro/dev-only cost. It supplies no required capability beyond the first-class fake and contract suite. **Not selected on fit.** [S14] |
| **Faux `0.1.13`** | MIT; unsafe posture is explicitly substantial; proc-macro cost; wrong abstraction target. **Not selected.** [S15] |
| **Shaku `0.6.2`** | Dual license, MSRV 1.88, default `thread_safe` and `derive` behavior; adds macros and `Arc<dyn>`-oriented container types. **Not selected on integration cost and R05 fit.** [S16] |

**Metric-collection limitation:** the mandated crates.io and GitHub API GETs were issued, but their minified response bodies did not render in this research environment; the RustSec package pages also failed to render. Exact download, exact star, `pushed_at`, search-API open-issue, and issue-response figures are therefore marked **not captured**, not guessed. The exact collection commands are mandatory under `### Validation strategy`. Popularity is not load-bearing here: the seam itself uses `std`, while Serde is selected for standard compatibility and maintained API fit. [S18–S20] ([github.com](https://github.com/rust-lang/crates.io/blob/main/crates/crates_io_api_types/src/lib.rs))

### Principles and implementation

#### Shared principle and agreement level

The shared principle is:

> **Business/application behavior must depend on an explicitly replaceable driven capability, production wiring must be centralized, and every supported adapter must be testable against the same observable contract. Inbound CLI and web adapters must invoke one transport-neutral application contract.**

This is derived from the owner-supplied Python and TypeScript evidence, but it does not make either repository’s syntax the predetermined winner. [P1]

| Requirement | Required agreement level | What must be observable |
|---|---|---|
| Replace driven I/O without rewriting application logic | **Capability** — must agree | A production adapter and a deterministic test implementation can be supplied to unchanged use-case code. |
| Production dependency graph is explicit | **Architectural policy** — must agree | Only a composition-root module or binary entrypoint constructs the live adapter. |
| Compile-time adapter/API conformance | **Capability** — must agree | An incompatible adapter fails checking before tests run. Structural versus nominal typing may vary by language. |
| Shipped first-class fake | **Architectural policy** for this template | Downstream users and examples can construct it without `cfg(test)` or a mock generator. |
| Real/fake substitutability | **Behavioral policy** — must agree | The same contract test bodies run against both implementations. |
| CLI/web contract reuse | **Architectural pattern** — must agree for repositories with both frontends | Both translate into application-owned request/response DTOs; neither frontend owns the shared contract. |
| Protocol, interface, trait, closures, static/dynamic dispatch | **Ecosystem mechanism** — may differ | Differences are allowed if all higher-level criteria hold. |
| Sync versus async method shape | **Not owned here** | R05 chooses it; R01 must not force the answer accidentally. |

#### Cross-repository interpretation

- **Python:** retaining a `Protocol` port, composition root, in-memory repository, and shared contract suite is appropriate because Python’s structural protocol checking naturally expresses compile-time-like adapter conformance without inheritance. [P1]
- **TypeScript:** the `CliDeps` object of injected functions is a justified ecosystem difference while the seam is essentially one HTTP transport callback and inline object-literal fakes remain simple. The missing reusable fake and contract suite become capability gaps if TypeScript gains multiple stateful adapters or a web frontend; they do not prove that function injection itself was wrong. [P1]
- **Rust:** a named trait is preferable because the seam is a grouped repository capability exposed through a public library and consumed by two inbound frontends. Static generic dispatch is preferable at baseline because it works with either R05 signature family and avoids forcing boxed futures or an async-trait compatibility crate. [S1–S3]

#### Baseline reviews

`BASELINE-REVIEW: F001 — replaceable driven I/O is the shared capability; identical Protocol/interface/trait syntax is not — adopt a nominal Rust trait with generic dispatch while allowing TypeScript’s function seam to remain until its capability surface grows — owner-supplied py/ts evidence, Rust trait rules, and Tower’s generic-first/type-erasure-later practice.` [P1][S1–S3][S7–S9] ([doc.rust-lang.org](https://doc.rust-lang.org/book/ch18-02-trait-objects.html))

`BASELINE-REVIEW: F011 — compile-time conformance, not structural typing itself, is the principle — Rust uses an explicit nominal impl checked by rustc; do not add a structural-verification or mock-generation crate — Rust Reference evidence.` [S1] ([doc.rust-lang.org](https://doc.rust-lang.org/reference/items/traits.html))

`BASELINE-REVIEW: F018 — the reusable data contract should be application-owned rather than CLI-owned — place request/response DTOs in the library-facing application contract and make both CLI and web thin translators — Serde’s format-independent model and Axum’s state/adapter model.` [S10–S13] ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.State.html))

`BASELINE-REVIEW: F121 — generated interaction mocks do not establish semantic substitutability — use one shared behavioral contract suite against the shipped fake and a hermetic instance of the production adapter; reserve Mockall for optional interaction-specific tests — Mockall’s documented purpose and Rust’s compile-time trait checking.` [S1][S14] ([github.com](https://github.com/asomers/mockall))

#### Architectural alternatives

| Alternative | Advantages | Costs in this template | Verdict |
|---|---|---|---|
| **`ProjectsService<R: ProjectsRepository>`** | Static dispatch; possible inlining; no port allocation; native sync or native async trait shape remains open; fake and real are ordinary types; finite adapter sets can use an enum | Generic type appears in APIs; monomorphization can add compile time and code copies | **Choose.** One live implementation is expected per production binary, so production monomorphization is bounded. |
| **`ProjectsService { repo: Arc<dyn ProjectsRepository> }`** | Simple concrete service type; runtime adapter switching; hides adapter type | Vtable dispatch; heap/refcount ownership; current dyn compatibility excludes native `async fn` and return-position `impl Trait`, thereby constraining R05 | **Runner-up.** Use only at a demonstrated runtime-heterogeneity boundary. |
| **Struct of injected functions/closures** | Excellent for clocks, random sources, one HTTP callback, or a tiny local seam | Repeated closure type parameters or boxing; fragments a multi-operation capability; no natural adapter identity; reusable contract fixtures become awkward | **Reject for the repository boundary.** |
| **DI crate/container** | Central registration and resolution for large graphs; framework integrations | New macros and vocabulary; more compile time; can obscure wiring; Shaku’s normal shape returns `Arc<dyn Interface>`, reintroducing the R05 constraint | **Reject for the initial template.** |

The Rust Book describes generic monomorphization as having no runtime abstraction cost, while trait objects introduce dynamic dispatch and inhibit some optimization. The 2025 surveys also show that compile/resource cost remains a real ecosystem concern, so adding proc-macro/container dependencies needs demonstrated value. [S2–S6] ([doc.rust-lang.org](https://doc.rust-lang.org/book/ch18-02-trait-objects.html))

This research found no directly comparable benchmark for a repository call in a CLI/library/web bundle. It therefore does **not** conclude that generic dispatch is “absolutely fastest.” Tower’s warning concerns repeated boxed futures in a deep per-request middleware stack, not this exact workload. [S8] ([github.com](https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md?plain=1))

#### F001: port mechanism

Use an ordinary, application-owned Rust trait:

```rust
pub trait ProjectsRepository {
    // R05 owns the execution form.
    //
    // Sync-shaped possibility:
    // fn list(&self, request: &ListProjectsRequest)
    //     -> Result<Vec<ProjectRecord>, RepositoryError>;
    //
    // Native-async-shaped possibility:
    // async fn list(&self, request: &ListProjectsRequest)
    //     -> Result<Vec<ProjectRecord>, RepositoryError>;
}
```

Use it through a generic application service:

```rust
#[derive(Debug)]
pub struct ProjectsService<R> {
    repository: R,
}

impl<R> ProjectsService<R> {
    pub const fn new(repository: R) -> Self {
        Self { repository }
    }

    pub const fn repository(&self) -> &R {
        &self.repository
    }
}

// The operation-bearing impl adds `R: ProjectsRepository`.
// Its method body follows the execution form selected by R05.
```

Do **not** put `Send + Sync + 'static` on the port solely because the web frontend needs them. Place those bounds on the web state/router construction. This lets a library consumer use a single-threaded adapter while the live and in-memory template adapters remain web-compatible.

Use a fixed application-facing `RepositoryError`, or translate adapter errors into an application error at the adapter boundary. An associated per-adapter error would make fake-vs-real behavior and frontend error mapping less substitutable.

#### Dyn versus generics for this target

The decisive fit point is not the cost of one virtual call. It is that current dyn compatibility rejects native async trait methods and opaque return types; choosing `dyn` now would partially choose R05’s representation. Generic dispatch does not. [S1] ([github.com](https://github.com/rust-lang/reference/blob/master/src/items/traits.md))

For expected production topology:

- the CLI binary monomorphizes the service for its one live adapter;
- the web binary does the same independently;
- the fake and live variants coexist primarily in test artifacts;
- a type alias hides the concrete live type from composition code.

Consequently, generic code-size growth is bounded unless one production binary instantiates many repository types. That is an inference from monomorphization mechanics, not a measured result. [S3]

If runtime configuration must select among a small finite set, prefer an enum adapter implementing the port. If adapters become plugin-defined or unbounded, introduce an explicit `Arc<dyn ProjectsRepository + Send + Sync>` wrapper at the composition edge and re-check compatibility with R05.

#### F011 and F121: type verification versus substitutability

Rust does not provide Python-style structural satisfaction here. It provides nominal conformance:

```rust
impl ProjectsRepository for HttpProjectsRepository {
    // rustc checks the complete implementation.
}

impl ProjectsRepository for InMemoryProjectsRepository {
    // same application-facing signatures and associated items.
}
```

A compile assertion makes F011 visible in the test suite:

```rust
fn assert_repository<T: ProjectsRepository>() {}

#[test]
fn adapters_implement_the_port() {
    assert_repository::<HttpProjectsRepository>();
    assert_repository::<InMemoryProjectsRepository>();
}
```

This proves signatures, associated types, bounds, and lifetimes. It cannot prove semantics.

F121 therefore needs a shared behavioral suite independent of Mockall:

```rust
// Schematic: R05 supplies sync/async execution details for fixture and calls.
macro_rules! projects_repository_contract {
    ($module:ident, $fixture:expr) => {
        mod $module {
            #[test]
            fn empty_repository_lists_no_projects() {
                let repository = ($fixture)();
                super::contract::empty_repository_lists_no_projects(repository);
            }

            #[test]
            fn created_projects_are_returned_by_list() {
                let repository = ($fixture)();
                super::contract::created_projects_are_returned_by_list(repository);
            }

            #[test]
            fn missing_projects_use_the_standard_not_found_error() {
                let repository = ($fixture)();
                super::contract::missing_projects_use_the_standard_not_found_error(repository);
            }
        }
    };
}
```

Invoke the same suite twice:

```rust
projects_repository_contract!(
    in_memory_repository,
    fixtures::fresh_in_memory_repository
);

projects_repository_contract!(
    http_repository,
    fixtures::fresh_http_repository_with_local_server
);
```

The production-adapter fixture should use a hermetic local server or other real protocol fixture so its HTTP serialization, status handling, and error translation are exercised. Replacing its client with a generated mock would test less of the adapter.

Mockall remains useful only for narrowly interaction-oriented tests such as “retry exactly twice,” where setting call expectations is the behavior under test. It is not part of the base stack. [S14] ([github.com](https://github.com/asomers/mockall))

#### F002: composition root

Use explicit constructors and a named live type alias:

```rust
pub type LiveProjectsRepository =
    HttpProjectsRepository<SelectedHttpClient>;

pub type LiveProjectsService =
    ProjectsService<LiveProjectsRepository>;

pub fn build_live_projects_service(
    settings: &Settings,
) -> Result<LiveProjectsService, BuildError> {
    let client = build_http_client(settings)?;
    let repository =
        HttpProjectsRepository::new(client, settings.projects_base_url.clone());

    Ok(ProjectsService::new(repository))
}
```

`SelectedHttpClient` is deliberately a placeholder: R01 owns the seam shape, not the HTTP/runtime selection. Passing a configured concrete client into the adapter constructor is allowed; exposing an injected raw `fetch` function as the application boundary is not.

Each binary remains the outer composition root:

```rust
fn cli_main(settings: Settings) -> Result<(), Error> {
    let service = build_live_projects_service(&settings)?;
    run_cli(service)
}

fn web_main(settings: Settings) -> Result<(), Error> {
    let service = build_live_projects_service(&settings)?;
    let state = WebState {
        projects: std::sync::Arc::new(service),
    };
    run_web(state)
}
```

Prefer a named concrete alias over a public `-> impl Trait` factory because the web state and diagnostics benefit from a nameable type. A binary-private `impl Trait` return remains acceptable where inference is sufficient. No DI crate is warranted for this graph.

#### F013: first-class fake

Ship the fake unconditionally in the library-visible API selected by R02, not under `cfg(test)`:

```rust
#[derive(Clone, Default)]
pub struct InMemoryProjectsRepository {
    state: std::sync::Arc<std::sync::Mutex<InMemoryState>>,
}

#[derive(Default)]
struct InMemoryState {
    projects: Vec<ProjectRecord>,
}

impl InMemoryProjectsRepository {
    pub fn seeded(
        projects: impl IntoIterator<Item = ProjectRecord>,
    ) -> Self {
        Self {
            state: std::sync::Arc::new(std::sync::Mutex::new(
                InMemoryState {
                    projects: projects.into_iter().collect(),
                },
            )),
        }
    }

    pub fn snapshot(&self) -> Vec<ProjectRecord> {
        self.state.lock().expect("fake state poisoned").projects.clone()
    }
}
```

Reasons for `Arc<Mutex<_>>`:

- it is dependency-free;
- clones share observable state;
- it supports `&self` repository methods;
- it is usable by both CLI tests and multithreaded web state;
- it does not force an async runtime.

If R05 chooses async methods, the fake must not hold the standard mutex guard across an `.await`. Its in-memory mutation should complete while the guard is held and release it before suspension. R05 may revise the interior primitive without changing the port/adapter policy.

Call it `InMemoryProjectsRepository`, not `MockProjectsRepository`: it is a small behavioral adapter, not an expectation engine. Document that it guarantees only the shared repository contract, not remote durability, transactions, timing, or concurrency behavior.

#### F018: shared CLI/web data contract

Use application-owned DTOs with Serde:

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ListProjectsRequest {
    #[serde(default)]
    pub owner: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProjectView {
    pub id: String,
    pub name: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ListProjectsResponse {
    pub projects: Vec<ProjectView>,
}
```

The CLI’s parser type remains CLI-specific and converts into `ListProjectsRequest`. The web adapter converts path/query/header data into the same request. Both receive `ListProjectsResponse`; the CLI renders it as text or JSON and the web adapter serializes it as its HTTP response.

Do not make the web crate depend on a CLI module, and do not annotate a single struct simultaneously with framework-specific CLI and web attributes. The shared type is an application DTO, not a `clap` argument struct, HTTP extractor, persistence record, or domain entity.

Where HTTP semantics differ—pagination envelopes, path IDs, headers, status metadata—the web adapter should use a thin transport type and `From`/`TryFrom` conversion. Reuse is appropriate only where semantics are intentionally identical.

#### Observable acceptance criteria

1. Removing or breaking either adapter’s `impl ProjectsRepository` causes `cargo check` to fail.
2. Application-service modules contain no concrete HTTP-client, web-framework, or CLI-parser dependency.
3. Only composition code names the production adapter type.
4. `InMemoryProjectsRepository` is public and constructible from an external integration test without test-only features.
5. The same named contract-test bodies run against the in-memory adapter and a hermetic production-adapter fixture.
6. Both adapters return the same application error variants for contract-defined cases.
7. CLI and web tests construct the same request DTO and consume the same response DTO.
8. JSON parity is semantic—deserialize and compare typed DTOs or `serde_json::Value`—rather than depending on object-key order.
9. The workspace checks and tests under the fixed MSRV policy on both `ubuntu-latest` and `macos-latest`.
10. No generated-mock or DI crate is required for the base example.

#### Representative performance plan

No performance result was executed during this research.

If re-verification is triggered, compare generic and dyn branches with:

- **In-memory workload:** 1,000,000 repository calls, ten returned records, one thread, release mode, `std::hint::black_box`, LTO both disabled and enabled.
- **Protocol workload:** 10,000 loopback calls through the production HTTP adapter and hermetic server.
- **Instrumentation:** elapsed time, p50/p95 latency, allocation count if the workspace’s profiling tooling supports it, maximum RSS, clean-build timing from `cargo build --timings`, and final CLI/web artifact bytes.
- **Configuration:** identical compiler, lockfile, features, target, and linker.
- **Decision rule:** do not change to dyn or retain generics based on unlike third-party benchmarks; change only if the template’s workload shows a material user-visible advantage.

### Recommendation

**Adopt a port/adapter split.**

One stack:

1. **Port and service:** stable Rust nominal `trait`, consumed as `ProjectsService<R: ProjectsRepository>` using static generic dispatch.
2. **Verification:** explicit `impl ProjectsRepository for Adapter`, plus compile assertions; no structural-typing or mock-generation crate.
3. **Composition:** manual constructors and a named `LiveProjectsService` type alias; one shared live service builder and binary-level outer roots; no DI crate.
4. **Fake:** public `InMemoryProjectsRepository` backed by `std::sync::Arc<Mutex<_>>`, shipped without `cfg(test)`.
5. **Substitutability:** one macro-generated or generic behavioral contract suite invoked for both in-memory and production adapters.
6. **Web/CLI contract:** application-owned request/response DTOs using `serde 1.0.229`; `serde_json 1.0.151` only in JSON-facing adapters and parity tests.
7. **Type erasure:** no `dyn` in the baseline port path. Add `Arc<dyn ProjectsRepository + Send + Sync>` only if runtime-unbounded adapter selection is later demonstrated and R05’s signature is dyn-compatible.
8. **Not selected:** Mockall `0.15.0`, Faux `0.1.13`, Shaku `0.6.2`, and architecture-specific port crates.

### Members

#### Rust trait port + generic application service

##### Landscape

Built-in candidates are a generic trait bound, a boxed/`Arc` trait object, injected `Fn` values, and an enum implementing the trait. The generic trait is the default; an enum is the finite-runtime-selection extension; `dyn` is the unbounded-runtime-selection extension.

##### Principles and implementation

The member realizes dependency inversion at a meaningful application capability rather than at the raw HTTP-call level. Rust requires an explicit implementation, so adapter conformance is nominal and compiler-verified rather than structural. [S1] ([doc.rust-lang.org](https://doc.rust-lang.org/reference/items/traits.html))

##### Dominant choice

`ProjectsService<R>` where `R: ProjectsRepository` on operation-bearing impl blocks.

This mirrors the generic-first design used by Tower, with type erasure available separately rather than embedded into every service value. [S7–S9] ([docs.rs](https://docs.rs/tower/latest/tower/util/struct.BoxService.html))

##### Qualified shortlist

1. Generic trait parameter.
2. Finite enum adapter implementing the same trait.
3. `Arc<dyn ProjectsRepository + Send + Sync>` at an explicit erasure boundary.
4. Injected function values only if the eventual port truly has one stateless operation.

##### Excluded by gate

Unstable trait aliases, specialization, nightly-only dyn/async mechanisms, or compiler plugins fail the stable-Rust gate.

No third-party port/hexagonal-architecture crate is needed. Such a crate would have to demonstrate compatible licensing, MSRV, RustSec, macOS CI, runtime independence, and lower integration cost before consideration.

##### Up-and-comers

Future stable support for dyn-dispatching native async trait methods could weaken the R05 objection to trait objects. It would not by itself prove that runtime dispatch is preferable; the graph and binary/compile measurements would still govern.

##### Fit for this template

1. **License:** no external dependency; Rust’s built-in mechanism.
2. **MSRV:** available under the fixed toolchain policy; no newer language feature is required.
3. **Advisories/unsafe:** no package advisory applies; the template implementation requires no unsafe.
4. **OS:** platform-neutral on Ubuntu and macOS; Windows also supported by the language mechanism.
5. **Features/runtime:** no feature or async-runtime coupling.
6. **Compile/binary:** monomorphizes per concrete adapter; no vtable or required allocation. Compile and binary growth are qualitative risks if many implementations are instantiated.

##### Recommendation

Use an ordinary trait with fixed application DTO and error types; make the application service generic; apply `Send + Sync + 'static` only where the web root requires them.

##### Ranked runner-up

`Arc<dyn ProjectsRepository + Send + Sync>` stored by a concrete `ProjectsService`.

Choose it only for runtime-unbounded adapter selection or if measured compile/binary duplication becomes material and R05 produces a dyn-compatible signature.

##### Tradeoffs

The generic design exposes a type parameter but preserves optimization and execution-model freedom. The dyn design hides the type but adds vtable/refcount ownership and currently constrains async-shaped trait methods. [S1–S3] ([doc.rust-lang.org](https://doc.rust-lang.org/book/ch18-02-trait-objects.html))

##### Parameters

- Rust edition: 2024.
- MSRV: owner policy, resolved and tested in CI.
- R05 execution shape: deliberately unassumed.
- Port methods must use application types rather than HTTP-client types.
- No dependency on R02’s physical crate layout.

##### Migration implications

Introduce a logical `ports::projects_repository` module; make service code generic over the trait; move concrete HTTP-client references into the adapter and composition code; remove a `CliDeps`-style collection of application-boundary closures if one has been sketched.

##### Validation strategy

Compile assertions cover both adapters. Scoped source checks reject `dyn ProjectsRepository`, `Box<dyn Fn...>`, or concrete HTTP-client names in application modules. The contract suite proves behavior separately.

##### Confidence & re-verify trigger

**High confidence.**

Re-verify if:

- R05 supplies stable dyn-compatible async methods without boxing;
- a single production binary must load third-party adapters dynamically;
- more than roughly a handful of concrete repository instantiations occur in one artifact;
- measured clean-build or artifact-size cost becomes material.

##### Sources

[S1], [S2], [S3], [S7], [S8], [S9], [S17].

#### Explicit composition root + in-memory adapter + shared contract suite

##### Landscape

Built-in choices are constructors/type aliases, `Arc`, `Mutex`, enums, generic test helpers, and `macro_rules!`. External alternatives surveyed were Shaku for DI, Mockall for trait mocks, and Faux for concrete-struct mocking.

##### Principles and implementation

The composition root is the only place allowed to know the live adapter graph. The fake is a normal adapter that shares the production port. Compile conformance and behavioral conformance are treated as separate checks.

##### Dominant choice

Manual constructor injection:

```text
configured HTTP client
        ↓
HttpProjectsRepository<Client>
        ↓
ProjectsService<HttpProjectsRepository<Client>>
        ↓
CLI owner or Arc<WebState>
```

No registry, service locator, reflection, or generated container is required.

##### Qualified shortlist

- Named concrete live type alias and explicit builder.
- Binary-private `-> impl UseCase` factory where the type never needs to be named.
- Enum-based live adapter when configuration selects from a finite built-in set.
- Mockall only as a future optional dev dependency for interaction-specific tests.

##### Excluded by gate

- Nightly/runtime-reflection DI mechanisms fail stable Rust.
- Nonselected crate candidates whose exact RustSec and macOS-CI checks were not captured are not eligible for addition until the mandatory validation script passes.
- Faux’s substantial unsafe test machinery is unnecessary for an ordinary trait implementation and does not improve F121. [S15] ([github.com](https://github.com/nrxus/faux))

##### Up-and-comers

Shaku is the most credible re-evaluation candidate if the template later demonstrates a large graph, scoped providers, interchangeable modules, or framework-wide registration needs. Its current API uses compile-time macros and commonly resolves `Arc<dyn Interface>`, so it is not neutral toward the chosen dispatch model. [S16] ([github.com](https://github.com/AzureMarker/shaku))

##### Fit for this template

1. **License:** std implementation adds no dependency.
2. **MSRV:** no feature newer than the fixed MSRV is needed.
3. **Advisories/unsafe:** no external package; safe code suffices.
4. **OS:** `Arc` and `Mutex` work on Ubuntu, macOS, and Windows.
5. **Features/runtime:** none; fake does not select an async runtime.
6. **Compile/binary:** very low added cost; unused fake code can be removed by normal linking.

##### Recommendation

- One shared `build_live_projects_service` factory.
- Binary-specific outer roots.
- Public `InMemoryProjectsRepository`.
- `Arc<Mutex<State>>` for clonable state.
- One shared contract macro or generic contract functions.
- Hermetic local protocol fixture for the real adapter invocation.
- No Mockall, Faux, or Shaku in the base template.

##### Ranked runner-up

Manual composition with a concrete service holding `Arc<dyn ProjectsRepository + Send + Sync>`.

This retains explicit wiring and first-class fake behavior, but is subordinate to the generic baseline because of R05.

##### Tradeoffs

`std::sync::Mutex` can poison after a panic and must never be held across an async suspension. Those properties are acceptable for a small deterministic fake if documented. A runtime-specific mutex would couple the fake to R05 and is therefore not selected here.

A shipped fake requires maintenance as the port evolves. That is intentional: failure to update it should be caught by compilation and the shared contract suite.

##### Parameters

- Fake is public and not test-feature-gated.
- Interior synchronization may be revised by R05 without changing the architectural decision.
- Physical crate placement remains R02-owned.
- Production protocol fixture and runtime come from their owning decisions.

##### Migration implications

Add the live builder, public in-memory adapter, fixture factory, contract-test module, and two suite invocations. Remove inline one-off fakes where they cover contract-defined behavior. Keep tiny local stubs only for behavior outside the first-class fake’s scope.

##### Validation strategy

- Compile both adapter impls.
- Run each contract test body against both fixtures.
- Verify the in-memory suite performs no network access.
- Verify the real suite exercises actual serialization and status/error mapping.
- Verify only composition code imports the live adapter.

##### Confidence & re-verify trigger

**High confidence for explicit composition and a shipped fake; medium-high for `Arc<Mutex<_>>` pending R05.**

Re-verify the synchronization primitive if R05 requires locks to span suspension, if the fake must model transactions, or if contention becomes part of the contract.

##### Sources

[S7], [S8], [S10], [S14], [S15], [S16], [S17].

#### `serde 1.0.229` + `serde_json 1.0.151`

##### Landscape

Serde is the established format-independent data-model layer. `serde_json` is the JSON format implementation. Manual serialization, untyped `serde_json::Value` throughout the application, or frontend-owned duplicate DTOs are the principal architectural alternatives.

##### Principles and implementation

The shared contract consists of application request/response structs. Serde derives serialization capabilities on those structs; each frontend remains responsible for parsing or rendering its own transport concerns. Serde’s own documentation separates data structures from format crates, matching this boundary. [S11–S13] ([docs.rs](https://docs.rs/serde/latest/serde/?search=ser%3A%3ASerializer))

##### Dominant choice

```toml
[workspace.dependencies]
serde = { version = "1.0.229", features = ["derive"] }
serde_json = "1.0.151"
```

`serde` belongs with shared DTOs. `serde_json` belongs only in JSON-facing CLI/web code and contract-parity tests, not in domain or repository-port signatures.

##### Qualified shortlist

1. Shared application DTOs directly deriving Serde.
2. Shared application DTOs plus web-specific envelope/query types converted with `From`/`TryFrom`.
3. Entirely separate web DTOs only if HTTP versioning semantics materially diverge.

##### Excluded by gate

No alternative serialization crate was promoted to the dependency shortlist. Replacing Serde would require evidence of equal integration with the selected web ecosystem, CLI JSON output, MSRV, maintenance, platform support, and downstream familiarity.

Using `serde_json::Value` as the main application contract is excluded by fit: the Serde JSON documentation notes that typed structures restore compiler assistance and avoid repetitive dynamic field handling. [S13] ([docs.rs](https://docs.rs/crate/serde_json/latest/source/README.md))

##### Up-and-comers

Schema-first/code-generated contracts may become appropriate if OpenAPI, multiple API versions, or external SDK generation becomes a primary requirement. They should generate or translate to application DTOs rather than own the domain model.

##### Fit for this template

1. **License:** both projects use MIT OR Apache-2.0. [S11][S13]
2. **MSRV:** must be proved with the exact lockfile under the owner’s stable-minus-two toolchain; no contrary requirement was found.
3. **Advisories/unsafe:** no open advisory was identified by the general search, but direct RustSec package pages did not render. Merge must be blocked on `cargo deny` or equivalent advisory output.
4. **OS:** data-only serialization is platform-independent; the exact lockfile is tested on Ubuntu and macOS.
5. **Features/runtime:** Serde uses `std` by default; enable `derive`; no async-runtime coupling. `serde_json` also introduces no runtime choice.
6. **Compile/binary:** derive macros add `serde_derive` and proc-macro compilation; runtime and artifact cost are low for the small DTO set. This cost is justified because both frontends and tests consume the same contract.

##### Recommendation

Use Serde on dedicated application DTOs. Do not serialize persistence records or internal domain entities merely to avoid a conversion. Use `serde_json` at JSON boundaries and in semantic parity tests.

##### Ranked runner-up

Separate web DTOs with explicit conversion to and from application DTOs.

Use this when HTTP compatibility, field naming, optionality, or versioning must evolve independently. Do not duplicate DTOs merely because the transports differ.

##### Tradeoffs

Directly deriving Serde makes serialization shape part of the DTO’s public contract. Renames and defaulting rules therefore need compatibility review. Separate transport DTOs add conversion code but isolate wire evolution.

##### Parameters

- `serde = 1.0.229`, feature `derive`.
- `serde_json = 1.0.151`, adapter/dev scope.
- Default `std` features retained.
- No async-runtime feature.
- Shared DTO ownership is architectural; R02 decides physical crate placement.

##### Migration implications

Move reusable request/response types out of CLI parsing modules. Add conversions from CLI arguments and web path/query/envelope types. Add JSON round-trip and frontend parity tests.

##### Validation strategy

- Serialize and deserialize every public DTO.
- Run golden or snapshot-like semantic tests without relying on map-key ordering.
- Compile the shared-contract module without CLI/web framework imports.
- Run exact MSRV, license, and advisory checks before merge.

##### Confidence & re-verify trigger

**High confidence in Serde as the contract mechanism; medium confidence in the exact patch pins until the mandated API and lockfile checks are rerun.**

Re-verify on any Serde MSRV increase, RustSec advisory, wire-contract versioning requirement, or evidence that direct derives are coupling domain and transport evolution.

##### Sources

[S11], [S12], [S13], [S18], [S19], [S20].

**Mandated live-API ledger, retrieval attempt 2026-09-09:**

| Figure | `serde` | `serde_json` | Mandated endpoint/status |
|---|---:|---:|---|
| 90-day downloads | **Not captured; not guessed** | **Not captured; not guessed** | `GET https://crates.io/api/v1/crates/serde`; `GET https://crates.io/api/v1/crates/serde_json` — response body did not render. |
| All-time downloads | **Not captured; not guessed** | **Not captured; not guessed** | Same endpoints and fields `crate.downloads`. |
| Newest non-yanked release | `1.0.229`, corroborated as released 2026-07-18; exact `created_at` not captured | `1.0.151`; exact `created_at` not captured | `GET .../<name>/versions`; corroboration [S12–S13]. |
| Stars, archived, pushed | **Not captured exactly** | **Not captured exactly** | `GET https://api.github.com/repos/serde-rs/serde`; `GET https://api.github.com/repos/serde-rs/json`. |
| Open issues | **Not captured through mandated search API** | **Not captured through mandated search API** | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`. |
| Issue responsiveness | **Not measured** | **Not measured** | Mandatory ten-newest-issues script below. |
| Advisories | **Direct page failed to render** | **Direct page failed to render** | `https://rustsec.org/packages/serde.html`; `https://rustsec.org/packages/serde_json.html`. |
| Adopters | **Mandated reverse-dependency/Cargo.toml sample not captured** | Same | Must be collected from crates.io reverse dependencies and adopter manifests before final dependency ledger approval. |
| Maintenance state | **Active**, based on a 2026 release and maintained repository; exact API fields pending | **Active**, based on current 1.0.151 documentation and maintained repository; exact API fields pending | Classification is provisional until API collection. |

### Compatibility

The Serde JSON `1.0.151` maintained example imports `serde::{Serialize, Deserialize}`, derives them on typed structs, and serializes/deserializes those structs with `serde_json`; this is a maintained shared example for the two crate members. [S13] ([docs.rs](https://docs.rs/crate/serde_json/latest/source/README.md))

Tower and Axum provide maintained references for the generic-service/type-erasure and concrete shared-state portions, but no upstream reference was found for this exact full bundle. Exact bundle compatibility must therefore be established by this matrix:

| OS | Toolchain | Edition | Members | Features | Required status |
|---|---|---:|---|---|---|
| `ubuntu-latest` | resolved stable-minus-two | 2024 | std generic port, std fake/root, Serde bundle | default + all workspace features | Check, Clippy, unit, contract, CLI/web parity |
| `macos-latest` | resolved stable-minus-two | 2024 | same | same | Same |
| `ubuntu-latest` | current stable | 2024 | same lockfile | same | Same |
| `macos-latest` | current stable | 2024 | same lockfile | same | Same |

For the 2026-09-09 implementation snapshot, the expected toolchains are stable 1.98 and MSRV 1.96, but CI must resolve and confirm those values rather than relying on this report.

### Parameters

`owns http-transport-injection-seam = application-level ProjectsRepository port expressed as a nominal Rust trait and consumed through a generic ProjectsService<R>; the live HTTP client is a concrete adapter constructor input, not an injected CLI/service function value`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

`assumes sync-async-execution-model = unresolved and owned by R05; no method execution syntax selected here`

`assumes crate-boundary-enforcement = unresolved and owned by R02; only logical modules are specified here`

`CONFLICT: none`

### Migration implications

The paths below are logical; R02 decides their physical crate placement.

1. **Port module**
   - Add `ports/projects_repository.rs`.
   - Define `ProjectsRepository` with application DTOs and application error types.
   - Add rustdoc covering semantic guarantees and explicitly excluded durability/timing guarantees.

2. **Application service**
   - Add or refactor `services/projects.rs`.
   - Introduce `ProjectsService<R>`.
   - Remove concrete HTTP types and injected transport functions from use-case signatures.

3. **Shared data contract**
   - Add `contracts/projects.rs`.
   - Move reusable request/response types out of CLI modules.
   - Derive Serde only on intentional application DTOs.

4. **Production adapter**
   - Add or refactor `adapters/http_projects_repository.rs`.
   - Implement `ProjectsRepository`.
   - Translate protocol/client errors to `RepositoryError`.
   - Accept the configured concrete HTTP client through its constructor.

5. **First-class in-memory adapter**
   - Add `adapters/in_memory_projects_repository.rs`.
   - Export it without `cfg(test)`.
   - Add seed, snapshot, and deterministic reset APIs.
   - Implement the same port.

6. **Composition**
   - Add `composition.rs` or equivalent application-root module.
   - Define `LiveProjectsRepository` and `LiveProjectsService` aliases.
   - Add `build_live_projects_service`.
   - Keep binary-specific CLI and web startup in their respective outer roots.

7. **CLI adapter**
   - Keep parser structs frontend-specific.
   - Convert arguments into application requests.
   - Render application responses; use `serde_json` only for JSON output.

8. **Web adapter**
   - Hold `Arc<LiveProjectsService>` in state.
   - Translate path/query/header/envelope types into application requests.
   - Serialize application responses or thin HTTP envelopes.

9. **Contract suite**
   - Add `tests/support/projects_repository_contract.rs`.
   - Invoke the same suite for in-memory and production fixtures.
   - Use a hermetic protocol fixture for the production adapter.

10. **Boundary and parity tests**
    - Add compile assertions for both adapter impls.
    - Add CLI/web semantic-contract parity tests.
    - Add checks preventing concrete adapter/framework imports in application modules.

11. **Documentation**
    - Record an ADR stating that agreement is at the dependency-inversion and substitutability-policy level, not at identical Python/TypeScript/Rust syntax.
    - Document when a future switch to `dyn` or a DI crate would be justified.

No Python or TypeScript source change is part of R01. Their follow-on rationale is: retain ecosystem-appropriate syntax, but close any future gap in first-class fakes, shared contracts, and reusable adapter contract tests.

### Validation strategy

**Executed during this research:** source and documentation review only. No Rust workspace was built, no benchmark was run, and the exact registry/GitHub metric bodies were not captured.

**Planned integration checks:**

```bash
# Resolve these from the current stable channel at implementation time.
rustup toolchain install 1.96.0
rustup toolchain install stable

cargo +1.96.0 fmt --all -- --check
cargo +1.96.0 check --workspace --all-targets --all-features
cargo +1.96.0 clippy --workspace --all-targets --all-features -- -D warnings
cargo +1.96.0 test --workspace --all-features
cargo +1.96.0 test --workspace --doc

cargo +stable check --workspace --all-targets --all-features
cargo +stable test --workspace --all-features
```

Expected: all commands pass on both `ubuntu-latest` and `macos-latest`.

Run the focused seam checks:

```bash
cargo test adapters_implement_the_port
cargo test projects_repository_contract
cargo test in_memory_repository
cargo test http_repository
cargo test cli_web_contract_parity
```

Expected:

- both adapter types satisfy the trait;
- every contract behavior runs against both fixtures;
- the fake suite is network-free;
- the real suite exercises the actual adapter protocol;
- CLI and web produce equal typed results and semantically equal JSON.

Check the dependency direction using paths assigned by R02:

```bash
rg -n 'HttpProjectsRepository|reqwest|hyper|axum|clap' <application-module-path>
rg -n 'dyn ProjectsRepository|Box<dyn ProjectsRepository>|Arc<dyn ProjectsRepository>' \
  <port-and-service-paths>
rg -n 'Box<dyn Fn|Arc<dyn Fn|impl Fn' <cli-and-service-dependency-paths>
```

Expected:

- no concrete protocol, CLI, or web framework name in application service/port modules;
- no baseline trait-object repository storage;
- no direct-function driven seam at the CLI/service boundary.

Check construction locality:

```bash
rg -n 'HttpProjectsRepository::new|build_http_client' .
```

Expected: matches only in the adapter’s own tests and composition-root code.

Check contract ownership:

```bash
rg -n 'derive\(.*Serialize.*Deserialize|derive\(.*Deserialize.*Serialize' \
  <shared-contract-path>
rg -n 'clap::|axum::|actix_web::|rocket::' <shared-contract-path>
```

Expected: Serde derives are present; frontend-framework imports are absent.

Collect exact dependency figures before ledger approval:

```bash
set -euo pipefail

for crate in serde serde_json mockall faux shaku; do
  echo "== $crate =="
  curl -fsSL "https://crates.io/api/v1/crates/$crate" |
    jq -r '[
      .crate.recent_downloads,
      .crate.downloads
    ] | @tsv'

  curl -fsSL "https://crates.io/api/v1/crates/$crate/versions" |
    jq -r '
      .versions
      | map(select(.yanked == false))
      | sort_by(.created_at)
      | last
      | [.num, .created_at]
      | @tsv
    '
done
```

Collect exact GitHub figures:

```bash
set -euo pipefail

for repo in \
  serde-rs/serde \
  serde-rs/json \
  asomers/mockall \
  nrxus/faux \
  AzureMarker/shaku
do
  echo "== $repo =="

  curl -fsSL "https://api.github.com/repos/$repo" |
    jq '{
      stargazers_count,
      archived,
      pushed_at
    }'

  curl -fsSG \
    --data-urlencode "q=repo:$repo is:issue is:open" \
    "https://api.github.com/search/issues" |
    jq '.total_count'
done
```

Issue responsiveness must be calculated from the ten most recently opened issues, treating a comment whose `author_association` is `OWNER`, `MEMBER`, or `COLLABORATOR` as a maintainer response. Record median elapsed days among answered issues and the unanswered count. Do not substitute `open_issues_count`.

Run policy gates using the workspace’s owner-approved tooling:

```bash
cargo deny check licenses advisories
cargo tree --workspace --all-features
```

Expected:

- no open RustSec advisory in the selected tree;
- every license satisfies workspace policy;
- the resolved dependency tree compiles under the fixed MSRV.

Capture qualitative cost:

```bash
cargo clean
cargo build --release --workspace --timings

wc -c target/release/<cli-binary>
wc -c target/release/<web-binary>
```

If a dyn re-evaluation is triggered, run the generic and dyn branches with identical lockfile, features, compiler, linker, optimization, LTO, fixture data, and process count. Report latency, throughput, allocations, RSS, clean-build timing, and artifact bytes; do not compare unrelated published benchmarks.

### Confidence & re-verify trigger

**Architecture confidence: high.** Stable Rust traits, explicit constructors, ordinary in-memory implementations, and shared behavioral tests directly realize the required capability without adding architectural dependencies.

**Dispatch confidence: high while R05 remains open.** Generic dispatch is the only candidate that does not accidentally force a dyn-compatible sync/async representation under current trait-object rules.

**Serde confidence: high for the mechanism, medium for exact patch pins.** Re-run registry, MSRV-tree, advisory, adopter, and platform evidence before merging the lockfile.

**Re-verify when any of these occurs:**

- R05 selects an execution shape whose ergonomics materially change generic versus dyn use.
- Stable Rust permits native async trait methods through trait objects without boxing or helper macros.
- One production binary needs unbounded runtime-loaded adapters.
- The live graph grows enough that explicit wiring becomes repetitive or error-prone.
- Clean-build timing or binary size exceeds the template’s accepted budget.
- The web contract needs independent public versioning.
- Serde or Serde JSON raises MSRV beyond the workspace policy.
- A RustSec advisory affects a selected version.
- The shipped fake cannot model a newly contract-required transactional or concurrency behavior.
- R02 places boundaries such that generic types would leak through an intentionally stable public facade.

### Sources

All external sources were retrieved **2026-09-09** unless otherwise stated.

- **[P1] Owner-supplied source precedent:**  
  `py-launch-blueprint/src/py_launch_blueprint/core/ports.py:40`  
  `py-launch-blueprint/src/py_launch_blueprint/composition.py:36`  
  `py-launch-blueprint/src/py_launch_blueprint/core/adapters/in_memory.py:20`  
  `py-launch-blueprint/tests/core/test_projects_repository_contract.py:70`  
  `ts-launch-blueprint/src/router.ts:31,55`  
  `ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`, D-019(5).

- **[P2] Owner-fixed parameters:**  
  `docs/port/PARAMETERS.md`, owner decision dated 2026-09-02.

- **[S1] Rust Reference — traits and dyn compatibility:**  
  `https://doc.rust-lang.org/reference/items/traits.html`  
  ([doc.rust-lang.org](https://doc.rust-lang.org/reference/items/traits.html))

- **[S2] The Rust Programming Language — trait objects:**  
  `https://doc.rust-lang.org/book/ch18-02-trait-objects.html`  
  ([doc.rust-lang.org](https://doc.rust-lang.org/book/ch18-02-trait-objects.html))

- **[S3] The Rust Programming Language — generics and monomorphization:**  
  `https://doc.rust-lang.org/book/ch10-01-syntax.html#performance-of-code-using-generics`  
  ([doc.rust-lang.org](https://doc.rust-lang.org/book/ch10-01-syntax.html))

- **[S4] Cargo Book — `rust-version`:**  
  `https://doc.rust-lang.org/cargo/reference/rust-version.html`  
  ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/rust-version.html))

- **[S5] Rust Survey Team — 2025 State of Rust Survey Results:**  
  `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`  
  ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))

- **[S6] Rust compiler performance survey 2025 results:**  
  `https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/`  
  ([blog.rust-lang.org](https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/))

- **[S7] Tower `BoxService`:**  
  `https://docs.rs/tower/latest/tower/util/struct.BoxService.html`  
  ([docs.rs](https://docs.rs/tower/latest/tower/util/struct.BoxService.html))

- **[S8] Tower maintained middleware guide:**  
  `https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md`  
  ([github.com](https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md?plain=1))

- **[S9] Tower production and adopter evidence:**  
  `https://github.com/tower-rs/tower/issues/636`  
  ([github.com](https://github.com/tower-rs/tower/issues/636))

- **[S10] Axum `State`:**  
  `https://docs.rs/axum/latest/axum/extract/struct.State.html`  
  ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.State.html))

- **[S11] Serde maintainers’ documentation and repository:**  
  `https://docs.rs/serde/latest/serde/`  
  `https://github.com/serde-rs/serde`  
  ([docs.rs](https://docs.rs/serde/latest/serde/?search=ser%3A%3ASerializer))

- **[S12] Serde current release corroboration:**  
  `https://deps.rs/crate/serde/latest`  
  `https://releasealert.dev/cratesio/serde`  
  ([deps.rs](https://deps.rs/crate/serde/latest))

- **[S13] Serde JSON `1.0.151` maintained README and example:**  
  `https://docs.rs/crate/serde_json/latest/source/README.md`  
  ([docs.rs](https://docs.rs/crate/serde_json/latest/source/README.md))

- **[S14] Mockall `0.15.0`:**  
  `https://github.com/asomers/mockall`  
  `https://docs.rs/mockall/latest/mockall/`  
  ([github.com](https://github.com/asomers/mockall))

- **[S15] Faux `0.1.13`:**  
  `https://github.com/nrxus/faux`  
  `https://docs.rs/faux/latest/faux/`  
  ([github.com](https://github.com/nrxus/faux))

- **[S16] Shaku `0.6.2`:**  
  `https://github.com/AzureMarker/shaku`  
  `https://docs.rs/shaku/latest/shaku/`  
  ([docs.rs](https://docs.rs/shaku/latest/shaku/))

- **[S17] Rust API Guidelines:**  
  `https://rust-lang.github.io/api-guidelines/`  
  `https://rust-lang.github.io/api-guidelines/dependability.html`  
  ([rust-lang.github.io](https://rust-lang.github.io/api-guidelines/dependability.html))

- **[S18] crates.io API schema and mandated endpoints:**  
  `https://crates.io/api/v1/crates/<name>`  
  `https://crates.io/api/v1/crates/<name>/versions`  
  `https://github.com/rust-lang/crates.io/blob/main/crates/crates_io_api_types/src/lib.rs`  
  ([github.com](https://github.com/rust-lang/crates.io/blob/main/crates/crates_io_api_types/src/lib.rs))

- **[S19] Mandated GitHub endpoints:**  
  `https://api.github.com/repos/<owner>/<repo>`  
  `https://api.github.com/search/issues?q=repo:<owner>/<repo>+is:issue+is:open`

- **[S20] RustSec package endpoints:**  
  `https://rustsec.org/packages/serde.html`  
  `https://rustsec.org/packages/serde_json.html`  
  `https://rustsec.org/packages/mockall.html`  
  `https://rustsec.org/packages/faux.html`  
  `https://rustsec.org/packages/shaku.html`  
  Direct retrieval failed; pre-merge machine verification is required. ([]())

## Sources

- [https://doc.rust-lang.org/book/ch18-02-trait-objects.html](https://doc.rust-lang.org/book/ch18-02-trait-objects.html)
- [https://docs.rs/tower/latest/tower/util/struct.BoxService.html](https://docs.rs/tower/latest/tower/util/struct.BoxService.html)
- [https://docs.rs/axum/latest/axum/extract/struct.State.html](https://docs.rs/axum/latest/axum/extract/struct.State.html)
- [https://docs.rs/serde/latest/serde/?search=ser%3A%3ASerializer](https://docs.rs/serde/latest/serde/?search=ser%3A%3ASerializer)
- [https://github.com/asomers/mockall](https://github.com/asomers/mockall)
- [https://docs.rs/faux/latest/faux/](https://docs.rs/faux/latest/faux/)
- [https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/)
- [https://github.com/tower-rs/tower/issues/636](https://github.com/tower-rs/tower/issues/636)
- [https://github.com/rust-lang/crates.io/blob/main/crates/crates_io_api_types/src/lib.rs](https://github.com/rust-lang/crates.io/blob/main/crates/crates_io_api_types/src/lib.rs)
- [https://doc.rust-lang.org/reference/items/traits.html](https://doc.rust-lang.org/reference/items/traits.html)
- [https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md?plain=1](https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md?plain=1)
- [https://github.com/rust-lang/reference/blob/master/src/items/traits.md](https://github.com/rust-lang/reference/blob/master/src/items/traits.md)
- [https://github.com/nrxus/faux](https://github.com/nrxus/faux)
- [https://github.com/AzureMarker/shaku](https://github.com/AzureMarker/shaku)
- [https://docs.rs/crate/serde_json/latest/source/README.md](https://docs.rs/crate/serde_json/latest/source/README.md)
- [https://doc.rust-lang.org/book/ch10-01-syntax.html](https://doc.rust-lang.org/book/ch10-01-syntax.html)
- [https://doc.rust-lang.org/cargo/reference/rust-version.html](https://doc.rust-lang.org/cargo/reference/rust-version.html)
- [https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/](https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/)
- [https://deps.rs/crate/serde/latest](https://deps.rs/crate/serde/latest)
- [https://docs.rs/shaku/latest/shaku/](https://docs.rs/shaku/latest/shaku/)
- [https://rust-lang.github.io/api-guidelines/dependability.html](https://rust-lang.github.io/api-guidelines/dependability.html)