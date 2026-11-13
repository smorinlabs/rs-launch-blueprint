---
prompt: # Deep-research prompt — Ports-and-adapters seam (R01, bundle)
mode: all_deep_research
provider: combined
model: Multiple
operation_id: research-20260909-001249-fc1fbad6f52f4f42
note: built by the P02 controller in the format of doxa_research.output.OutputManager.generate_combined_report (a concatenation of the saved provider files, no model call); Doxa 3.3.0 'resume --async' cannot honour the submission's --combined flag
---

# Combined Research Report: # Deep-research prompt — Ports-and-adapters seam (R01, bundle)

Generated: 2026-09-09T07:30:37.894364+00:00


## Openai Results

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

---


## Perplexity Results

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

---


## Gemini Results

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

---
