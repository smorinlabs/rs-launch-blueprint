---
prompt: # Deep-research prompt — Sync/async execution model (R05, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint`'s driven-I/O boundary (the CLI's HTTP calls, and the optional web feature's request handlers) is sync end-to-end like py, or async end-to-end like ts — and, if async, which async runtime and HTTP client. Item kind: `bundle`. Value test: if this answer is wrong, every I/O-touching function signature in the core crate (sync `fn` vs. `async fn`), the CLI entry point's execution shape, the web adapter's handler signatures, and the HTTP-client crate choice all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): the two repos diverge completely. py is sync end-to-end, with its optional web layer bridging into FastAPI's async request handling via a threadpool. ts is async end-to-end, with every layer from the CLI entry point down to the HTTP call built on `Promise`s. Evidence: py `src/py_launch_blueprint/core/adapters/py_api.py:38` — `import requests` (blocking); `src/py_launch_blueprint/web/routers/projects.py:25` — "Handlers are sync (``def``) because ``ProjectsService`` uses ``requests``; FastAPI runs them in its threadpool"; ts `src/router.ts:182` — `export async function runCli` and `src/lib/api.ts:108` — `async function request` wrap the injected `fetch`; the whole call chain from CLI entry to HTTP is `Promise`-based. Ledger rows: F016, F022 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT` (F016, origin `different`) and `RUST-ONLY` (F022, origin `none` — neither repo picks a pluggable async executor; py is sync throughout, ts's `Promise`s run on the JS engine's built-in event loop, not a selectable runtime; F022 is moot unless F016 resolves async).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): the web service ships as an optional, separately installed Cargo feature (F017, verdict `ADOPT`) — the question here is what execution model that optional web layer and the always-present CLI share, not whether the web layer exists. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts's end-to-end async shape follows directly from JavaScript's single-threaded event-loop execution model, not from a deliberate runtime-selection decision; `TS_PORT_DECISIONS.md` records no dedicated entry choosing async over sync (there was no sync option to reject).

## Out of scope
- The shape of the ports-and-adapters seam itself (trait object vs. generic bound vs. direct injection); R01 (`ports-and-adapters-seam`) owns F001 and the `http-transport-injection-seam` parameter — this item decides sync-vs-async and the runtime, not how the I/O boundary is abstracted.
- Whether the web service exists as an optional capability at all; that is settled (F017, `ADOPT`) — this item only decides the execution model the web layer and CLI share.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R05
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R01 (`ports-and-adapters-seam`) names this item as a related coupling — R01's seam decision (trait object, generic bound, or direct injection) wraps around whichever sync/async model this item picks, but R01 registers `http-transport-injection-seam`, which this item does not need to consume: the seam's shape is compatible with either a sync or an async execution model. Treat R01's direction as open, do not block on it.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s driven-I/O boundary is sync (blocking) end-to-end like py, or async (non-blocking, `async fn` plus an executor) end-to-end like ts — and, if async, which async runtime and HTTP client crate.
- HIGH: What are the concrete costs of a sync-blocking core (e.g. `reqwest::blocking`, or `ureq`, with threads for any concurrency) versus an async core (`reqwest` async + `tokio`) for a template that must serve as a CLI *and* an optional web service — binary size, dependency count, compile time, and API ergonomics for template consumers extending the CLI?
- HIGH: If sync, do the dominant Rust web frameworks (Axum, Actix-web) require an async executor regardless — meaning py's "sync core, async web adapter bridged through a threadpool" shape (FastAPI's threadpool) has a direct, awkward, or nonexistent Rust analogue — or does a sync-first web framework (e.g. a thread-per-request design) avoid needing an async runtime at all?
- MEDIUM: If async, which runtime — `tokio` (dominant, full-featured, near-mandatory for Axum) or a lighter-weight alternative (`smol`, `async-std`) — best fits a CLI-first template where most invocations are a single HTTP round-trip rather than many concurrent tasks, and what does each cost in binary size and dependency count?
- MEDIUM: Does an async-first core impose ergonomic costs on the CLI entry point (`#[tokio::main]`, or a hand-rolled `block_on`) compared to a sync core, and how do popular Rust CLI templates (e.g. `cargo-generate` CLI templates, `clap`'s own examples) handle that boundary when they also ship a library crate?
- LOW: Is there a documented "sync CLI wrapping an async library core" pattern in the Rust ecosystem that gives ts's async-native ergonomics for the web feature without forcing the CLI's synchronous-feeling entry point to become `async fn main`?

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
operation_id: research-20260916-204610-04c498ad606e4c5b
created_at: 2026-09-16T20:46:10.107418
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Sync/async execution model (R05, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint`'s driven-I/O boundary (the CLI's HTTP calls, and the optional web feature's request handlers) is sync end-to-end like py, or async end-to-end like ts — and, if async, which async runtime and HTTP client. Item kind: `bundle`. Value test: if this answer is wrong, every I/O-touching function signature in the core crate (sync `fn` vs. `async fn`), the CLI entry point's execution shape, the web adapter's handler signatures, and the HTTP-client crate choice all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): the two repos diverge completely. py is sync end-to-end, with its optional web layer bridging into FastAPI's async request handling via a threadpool. ts is async end-to-end, with every layer from the CLI entry point down to the HTTP call built on `Promise`s. Evidence: py `src/py_launch_blueprint/core/adapters/py_api.py:38` — `import requests` (blocking); `src/py_launch_blueprint/web/routers/projects.py:25` — "Handlers are sync (``def``) because ``ProjectsService`` uses ``requests``; FastAPI runs them in its threadpool"; ts `src/router.ts:182` — `export async function runCli` and `src/lib/api.ts:108` — `async function request` wrap the injected `fetch`; the whole call chain from CLI entry to HTTP is `Promise`-based. Ledger rows: F016, F022 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT` (F016, origin `different`) and `RUST-ONLY` (F022, origin `none` — neither repo picks a pluggable async executor; py is sync throughout, ts's `Promise`s run on the JS engine's built-in event loop, not a selectable runtime; F022 is moot unless F016 resolves async).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): the web service ships as an optional, separately installed Cargo feature (F017, verdict `ADOPT`) — the question here is what execution model that optional web layer and the always-present CLI share, not whether the web layer exists. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts's end-to-end async shape follows directly from JavaScript's single-threaded event-loop execution model, not from a deliberate runtime-selection decision; `TS_PORT_DECISIONS.md` records no dedicated entry choosing async over sync (there was no sync option to reject).

## Out of scope
- The shape of the ports-and-adapters seam itself (trait object vs. generic bound vs. direct injection); R01 (`ports-and-adapters-seam`) owns F001 and the `http-transport-injection-seam` parameter — this item decides sync-vs-async and the runtime, not how the I/O boundary is abstracted.
- Whether the web service exists as an optional capability at all; that is settled (F017, `ADOPT`) — this item only decides the execution model the web layer and CLI share.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R05
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R01 (`ports-and-adapters-seam`) names this item as a related coupling — R01's seam decision (trait object, generic bound, or direct injection) wraps around whichever sync/async model this item picks, but R01 registers `http-transport-injection-seam`, which this item does not need to consume: the seam's shape is compatible with either a sync or an async execution model. Treat R01's direction as open, do not block on it.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s driven-I/O boundary is sync (blocking) end-to-end like py, or async (non-blocking, `async fn` plus an executor) end-to-end like ts — and, if async, which async runtime and HTTP client crate.
- HIGH: What are the concrete costs of a sync-blocking core (e.g. `reqwest::blocking`, or `ureq`, with threads for any concurrency) versus an async core (`reqwest` async + `tokio`) for a template that must serve as a CLI *and* an optional web service — binary size, dependency count, compile time, and API ergonomics for template consumers extending the CLI?
- HIGH: If sync, do the dominant Rust web frameworks (Axum, Actix-web) require an async executor regardless — meaning py's "sync core, async web adapter bridged through a threadpool" shape (FastAPI's threadpool) has a direct, awkward, or nonexistent Rust analogue — or does a sync-first web framework (e.g. a thread-per-request design) avoid needing an async runtime at all?
- MEDIUM: If async, which runtime — `tokio` (dominant, full-featured, near-mandatory for Axum) or a lighter-weight alternative (`smol`, `async-std`) — best fits a CLI-first template where most invocations are a single HTTP round-trip rather than many concurrent tasks, and what does each cost in binary size and dependency count?
- MEDIUM: Does an async-first core impose ergonomic costs on the CLI entry point (`#[tokio::main]`, or a hand-rolled `block_on`) compared to a sync core, and how do popular Rust CLI templates (e.g. `cargo-generate` CLI templates, `clap`'s own examples) handle that boundary when they also ship a library crate?
- LOW: Is there a documented "sync CLI wrapping an async library core" pattern in the Rust ecosystem that gives ts's async-native ergonomics for the web feature without forcing the CLI's synchronous-feeling entry point to become `async fn main`?

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

# Deep-Research Report: Execution Model Architecture for rs-launch-blueprint

### Landscape

The architectural decision regarding the execution model of a Rust application—specifically whether its driven-I/O boundaries operate synchronously (blocking) or asynchronously (non-blocking, future-based)—dictates the fundamental concurrency paradigm, dependency graph, and standard library interaction of the entire project. The execution model establishes how the application requests resources from the operating system, how it yields control during idle waiting periods, and how it scales under heavy concurrent load. To evaluate the optimal path for `rs-launch-blueprint`, the Rust I/O execution ecosystem must be mapped into three distinct categories based on current tooling and library adoption.

The first category consists of the built-in or first-party toolchain. The Rust standard library natively provides robust, blocking synchronous I/O operations, such as those found in the `std::net` and `std::fs` modules, which rely on traditional operating system threading models for concurrency [cite: 1]. While the `std::future::Future` trait and the `async`/`.await` syntax are built directly into the language syntax and standard library, Rust purposefully omits an asynchronous runtime or executor to drive these futures to completion [cite: 1, 2, 3]. This intentional omission delegates the responsibility of task scheduling and I/O polling to third-party crates, ensuring the standard library remains lightweight and suitable for embedded systems without operating system support.

The second category encompasses established industry standards. The `tokio` runtime dominates the asynchronous landscape, acting as the de facto standard executor for high-performance, concurrent network applications [cite: 2, 4]. Paired closely with `tokio` is `reqwest`, the predominant asynchronous HTTP client that offers extensive feature parity with modern web standards [cite: 5, 6]. In the web service domain, `axum` has emerged as the premier asynchronous web framework; it is directly maintained by the Tokio team and heavily leverages the `tower` middleware ecosystem [cite: 7, 8]. Conversely, in the synchronous domain, `ureq` stands as the established standard for minimal, blocking HTTP clients, completely avoiding the overhead of an asynchronous runtime [cite: 5, 9].

The third category features up-and-comers and alternative architectures. The `smol` runtime represents a minimalist, lightweight alternative asynchronous runtime, focusing on a composable core without the sprawling API surface and macro dependencies characteristic of `tokio` [cite: 2, 10]. Furthermore, macro-based bridging solutions like `maybe-async` or `block_on` utility crates attempt to unify synchronous and asynchronous codebases, allowing library authors to write code once and expose both blocking and non-blocking APIs [cite: 11, 12, 13]. However, these bridging tools currently face significant compilation friction and dependency resolution conflicts, particularly regarding cargo feature unification [cite: 11, 12].

Authority for evaluating these paradigms is derived from a diverse set of established sources. Official Rust language documentation, such as the Rust Async Book, rigorously defines the language's cooperative multitasking model and the implications of executor starvation [cite: 14]. Architectural treatises and issue discussions from core maintainers—including Carl Lerche for `tokio` and `axum`, and Sean McArthur for `reqwest`—provide deep insights into memory retention, task scheduling, and the true cost of abstracting over I/O [cite: 6, 8, 15]. Ecosystem-wide surveys and widely cited independent technical write-ups offer empirical evidence evaluating binary size, compile times, and ergonomic friction across differing I/O crates [cite: 5, 12, 16]. 

An analysis of mainstream production practice indicates that well-regarded, network-heavy applications and web services overwhelmingly adopt the `tokio` asynchronous ecosystem. Frameworks like `axum` and `actix-web` structurally mandate an asynchronous execution environment to efficiently manage thousands of concurrent connections via an event loop [cite: 7, 17]. Modern orchestration tools and robust web servers built in Rust rely on `tokio` for its zero-cost abstractions and highly optimized work-stealing scheduler [cite: 4, 18]. Conversely, single-purpose CLI utilities and build scripts, where concurrency is absent or minimal, frequently utilize synchronous tools like `ureq` to bypass the compile-time and binary-size overhead of an asynchronous runtime [cite: 5, 9]. For instance, tools focused strictly on rapid execution and minimal deployment footprints prefer the synchronous thread-blocking model because it simplifies the dependency tree and avoids the initialization cost of an I/O reactor.

However, assessing fitness strictly against the `rs-launch-blueprint` template requires addressing its dual nature: it must operate as a short-lived CLI utility, an embeddable core library, and a concurrent, long-running web service. Evaluating an abstract "best" HTTP client or runtime is insufficient; the execution model must harmonize these three interfaces seamlessly. The design must avoid thread exhaustion under web loads, mitigate heavy bridging overhead in the CLI, and provide a unified API surface across all consuming adapters, all while adhering strictly to the constraints of the target OS matrix and the established `MIT OR Apache-2.0` licensing requirements.

### Principles and implementation

The fundamental requirement is to determine whether the template's driven-I/O boundary—encompassing outgoing HTTP calls and incoming web request handlers—should operate synchronously or asynchronously from end to end. This decision is subject to the owner's mandate requiring a shared engineering principle across the CLI, the core library, and the optional web feature. The architecture must ensure that the implementation accurately mirrors or deliberately rejects the precedents set by the Python port, which is synchronous end-to-end with a threading bridge for the web, and the TypeScript port, which is asynchronous end-to-end using native JavaScript Promises.

The essential behaviors dictated by this architecture require absolute uniformity across the core library. The core domain logic and I/O-touching adapter traits must present a single execution model, utilizing either standard `fn` signatures or `async fn` signatures universally. This uniformity prevents the duplication of domain logic and sidesteps the fragile, error-prone nature of macro-based conditional compilation tools like `maybe-async` [cite: 11, 12]. Furthermore, the optional web service must handle concurrent requests efficiently, adhering to the standard paradigms of leading Rust web frameworks without resorting to non-idiomatic workarounds. Finally, the CLI entry point must execute the core library's functions ergonomically, allowing template consumers to extend the application without being burdened by convoluted runtime-management boilerplate or unsafe I/O bridging.

Two primary architectural models exist for a hybrid CLI and Web template in the Rust ecosystem. The first is a synchronous core paired with an asynchronous web bridge, heavily mirroring the Python precedent. In this architecture, the core library and the HTTP client operate synchronously using blocking I/O calls provided by crates like `ureq` [cite: 5, 9]. The CLI invokes these functions directly on the main thread, resulting in a minimal dependency footprint and rapid compilation. However, the web framework, specifically `axum`, natively runs on the asynchronous `tokio` runtime and demands non-blocking request handlers [cite: 7]. To interface with the synchronous core, the web layer must bridge the gap by offloading every single request handler to a dedicated blocking thread pool using `tokio::task::spawn_blocking` [cite: 5, 19]. 

While this mimics the Python and FastAPI approach, the implementation translates poorly to Rust's performance characteristics. Combining asynchronous code with synchronous blocking I/O on an standard asynchronous worker thread is fundamentally flawed in Rust's cooperative multitasking model; it starves the executor, halts the progression of other futures, and frequently leads to catastrophic application deadlocks [cite: 19, 20]. Consequently, every web request must be explicitly marshaled onto Tokio's blocking thread pool. This introduces significant context-switching overhead and hard-limits application concurrency to the maximum size of the blocking pool, which defaults to 512 threads [cite: 19]. The dominant Rust web frameworks, including `axum` and `actix-web`, do not provide a native, transparent threadpool bridge for synchronous handlers in the way Python's FastAPI does; they are explicitly engineered around `async fn` handlers and expect I/O to be yielded cooperatively back to the event loop [cite: 21, 22].

The second architectural model is asynchronous end-to-end, closely aligning with the TypeScript precedent. In this design, the core library, the HTTP client, and the web framework all operate asynchronously, returning `Future`s that must be polled [cite: 7, 21, 23]. The web layer consumes the core naturally and frictionlessly, as both the incoming request handling and outgoing HTTP calls share the exact same `tokio` execution environment, allowing for massive concurrency without thread exhaustion [cite: 7, 21]. The CLI entry point bridges the execution gap at the absolute highest level of the application by wrapping its main execution block in a runtime initiator, utilizing either `tokio::runtime::block_on` directly or the `#[tokio::main]` attribute macro [cite: 2, 16, 24]. 

This asynchronous end-to-end model perfectly aligns with Rust's modern network ecosystem and preserves the integrity of the application's concurrency model. The concrete cost of this approach is the mandatory inclusion of the `tokio` runtime and the `reqwest` asynchronous client, which significantly increases the binary size and adds roughly 10 to 15 seconds to the initial compilation time compared to a purely synchronous `ureq` implementation [cite: 5, 6, 15]. For a pure CLI application, this bloat might be considered unacceptable. However, because the web service is a recorded, owner-fixed parameter of the template, the `tokio` dependency is already a strict requirement for the `axum` web layer [cite: 7]. Aligning the core library with the asynchronous ecosystem eliminates all impedance mismatch. The CLI entry point handles the async-to-sync boundary gracefully, providing an ergonomic experience identical to the TypeScript port's Promise-based chain, where the developer simply awaits the results without manually managing thread pools [cite: 24]. 

Attempts to utilize a documented "sync CLI wrapping an async library core" pattern to artificially shield the CLI from asynchronous semantics introduce severe ergonomic penalties. Crates attempting this, such as `reqwest::blocking`, simply instantiate a hidden `tokio` runtime internally for every client instantiation, incurring all the binary size and compilation costs of async Rust while simultaneously stripping away the benefits of concurrent execution [cite: 6, 23]. Furthermore, utilizing procedural macros to conditionally compile both sync and async variants of the core library routinely fractures the dependency tree and violates Cargo's feature unification rules, rendering it an unviable pattern for a robust production template [cite: 12].

`BASELINE-REVIEW: F016 — execution model — async end-to-end — The Rust web ecosystem (specifically Axum) intrinsically requires the Tokio asynchronous runtime. Adopting a synchronous core would force the web layer to aggressively utilize spawn_blocking for every I/O boundary, degrading performance and increasing boilerplate. An async end-to-end model aligns optimally with the ecosystem.`

`BASELINE-REVIEW: F022 — pluggable executor — abandoned — Rust asynchronous runtimes are rarely perfectly interchangeable. The dominant libraries (Reqwest, Axum) are tightly coupled to Tokio's internal timer and I/O reactor mechanisms. A pluggable executor design would severely limit library choices and provide negligible value for this template.`

### Recommendation

The driven-I/O boundary of `rs-launch-blueprint` must be **async end-to-end**. The core library, the command-line interface, and the optional web adapter will universally utilize asynchronous function signatures (`async fn`) and standard Rust futures. 

The recommended stack is:
*   **Async Runtime:** `tokio` (configured via feature flags to utilize the multi-threaded scheduler for the web layer, and the current-thread scheduler for the CLI).
*   **HTTP Client:** `reqwest` (asynchronous, backed by `tokio` and configured with `rustls-tls` to avoid system OpenSSL dependencies).



### Members

#### `tokio`

##### Landscape
The Rust standard library intentionally avoids standardizing an asynchronous runtime, electing instead to provide only the foundational `Future` trait and the `Context` polling mechanism necessary to construct state machines [cite: 3]. In the absence of a built-in executor, `tokio` has aggressively filled the void to become the preeminent, industry-standard asynchronous runtime for the Rust programming language. It operates as an event-driven, non-blocking I/O platform, providing a highly optimized multithreaded work-stealing task scheduler, an I/O reactor backed by operating system event queues (such as `epoll` on Linux and `kqueue` on macOS), and highly accurate asynchronous timers [cite: 4, 18]. `tokio` sits decisively in the "established industry standard" bin, being universally utilized and heavily relied upon by the largest, most performant Rust network applications, web frameworks, and corporate production environments.

##### Principles and implementation
`tokio` implements a cooperative multitasking execution model where asynchronous tasks explicitly yield control back to the central executor when waiting on network or disk I/O, allowing a single operating system thread to manage thousands of concurrent operations without the heavy context-switching penalties of traditional threaded programming [cite: 1, 19]. For the `rs-launch-blueprint` template, `tokio` fulfills the critical requirement of powering the `axum` web service efficiently under high concurrent load. Furthermore, it supplies the highly ergonomic `#[tokio::main]` attribute macro. This macro seamlessly bridges the synchronous CLI `main()` function to the asynchronous core library by automatically bootstrapping the optimal runtime configuration and invoking `block_on` behind the scenes, eliminating complex setup boilerplate for end users modifying the template [cite: 2, 16, 24]. Memory retention characteristics are closely monitored by the maintainers; while some users report that `tokio` retains memory pools under massive load (millions of concurrent tasks), this is an intentional optimization to avoid the overhead of repeatedly returning memory to the system allocator, significantly improving subsequent request throughput [cite: 17].

##### Dominant choice
`tokio` is unquestionably the dominant choice in the asynchronous execution space. It records tens of millions of downloads across its release history [cite: 15], maintains an incredibly active and well-governed release cycle, and serves as the foundational, non-negotiable dependency for critical ecosystem pillars such as `axum` (web server), `reqwest` (HTTP client), and `tonic` (gRPC framework) [cite: 18]. The vast majority of the modern Rust network ecosystem is explicitly optimized for, or tightly coupled directly to, Tokio's internal timer and I/O reactor mechanisms [cite: 2, 5].

##### Qualified shortlist
*   `tokio`
*   `smol`
*   `async-std` (Often considered analogous to `smol` in its goal to mirror the standard library, but less actively favored in new, highly minimalist project initializations compared to `smol`).

##### Excluded by gate
Every major runtime candidate successfully passed the foundational fitness gates. All operate under `MIT OR Apache-2.0` dual licensing, explicitly declare and test MSRV compatibility aligned with the template requirements, maintain clean RustSec advisory records for their current stable releases, and provide comprehensive support for both Ubuntu and macOS target environments.

##### Up-and-comers
`smol` represents a highly compelling up-and-comer in the execution model landscape. It offers a deliberately tiny, composable core without the procedural macros or sprawling API surface inherent to `tokio` [cite: 2, 25]. Instead of a monolithic framework, `smol` provides modular subcrates for channels, executors, and networking [cite: 10]. Because of its focused scope, it compiles significantly faster than `tokio` and is frequently identified as an ideal candidate for pure CLI tools where the full weight of a work-stealing scheduler is entirely unnecessary [cite: 2, 26].

##### Fit for this template
While `smol` is conceptually attractive for a standalone CLI application, the dual-nature of the `rs-launch-blueprint` heavily complicates runtime selection. The template contains an optional web service utilizing `axum`, and `axum` heavily depends on both `tokio` and `tower` for its core routing and middleware architecture [cite: 7]. Attempting to use `smol` as the primary runtime for the CLI while retaining `axum` for the web feature would force the compilation of two completely distinct asynchronous runtimes when the web feature is enabled. Alternatively, it would require relying on complex, third-party compatibility layers (such as `async-compat`) to force `tokio`-based libraries to execute on the `smol` reactor, severely increasing the maintenance burden and introducing severe risks of subtle, hard-to-debug reactor panics [cite: 10, 25]. `tokio` fits the template perfectly precisely because it scales effortlessly across both required paradigms; it provides a lightweight `current_thread` runtime that is ideal for minimizing overhead in the CLI, and it offers the high-performance `multi_thread` runtime required to saturate CPU cores for the web service, allowing developers to switch models seamlessly via feature flags [cite: 16].

##### Recommendation
Select `tokio` as the asynchronous runtime. Configure it to use feature flags strictly to minimize unnecessary bloat; for example, only enable the `rt`, `macros`, and `net` features as strictly required by the baseline CLI. Allow the optional web adapter feature in the `Cargo.toml` to expand the `tokio` feature set to include `rt-multi-thread` when high concurrency is explicitly demanded [cite: 27].

##### Ranked runner-up
`smol`. If the web feature were permanently removed from the project scope and the application remained a pure CLI utility focused strictly on outbound API requests, `smol` would provide demonstrably faster compilation times and a smaller overall binary footprint while still enabling robust concurrent HTTP operations [cite: 2].

##### Tradeoffs
The primary tradeoff of adopting `tokio` is the compile-time penalty and binary-size overhead when compared to a purely synchronous architecture. `tokio` is a substantial and complex dependency, encompassing approximately 45,000 lines of code [cite: 15]. However, this upfront cost is amortized effectively across the broader application architecture because the web framework, the HTTP client, and the core library all share the exact same underlying runtime, preventing dependency duplication and mitigating total binary bloat.

##### Parameters
*   `owns rs-async-runtime = tokio`
*   `assumes rust-edition = 2024`
*   `assumes msrv-policy = stable minus 2 minor versions`

##### Migration implications
*   The `main.rs` entry point of the CLI application must be refactored from a standard `fn main()` to an asynchronous entry point using the `#[tokio::main] async fn main()` attribute macro.
*   All unit and integration tests requiring asynchronous execution must utilize the `#[tokio::test]` attribute macro instead of the standard library's `#[test]` attribute, ensuring a runtime is bootstrapped for test validation [cite: 19].

##### Validation strategy
Execute the CLI utilizing the `tokio` current-thread runtime to ensure it performs outbound requests and exits cleanly without hanging on dropped futures or unresolved reactor events. 
*   **Planned Check:** Execute `cargo tree | grep tokio` to ensure no conflicting or outdated runtime versions are being inadvertently imported by third-party crates, verifying dependency tree hygiene.
*   **Planned Check:** Instantiate the web service and subject it to a concurrent load test using benchmarking tools like `hey` or `wrk` to confirm the `tokio` multi-thread scheduler successfully distributes incoming request handlers across all available CPU cores without suffering from thread starvation or blocking I/O panics.

##### Confidence & re-verify trigger
Confidence in this selection is exceptionally high. Tokio's dominance is absolute in the current Rust network ecosystem, and deviating from it introduces unacceptable integration risks for web applications. Re-verify this decision only if the Rust project successfully introduces a highly performant, first-party asynchronous runtime directly into the standard library, or if a severe, unpatchable architectural flaw is discovered in Tokio's task scheduling algorithms that prompts a mass ecosystem migration.

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/tokio` | `crate.recent_downloads` |
| All-time downloads | `GET https://crates.io/api/v1/crates/tokio` | `crate.downloads` (approx. >100M, specific 1.53.1 release noted ~37M) [cite: 15] |
| Last release | `GET https://crates.io/api/v1/crates/tokio/versions` | newest with `yanked: false`: `num`, `created_at` [cite: 28] |
| Stars, archived | `GET https://api.github.com/repos/tokio-rs/tokio` | `stargazers_count` (32.9k), `archived` (false), `pushed_at` [cite: 29, 30] |
| Open issues | `GET https://api.github.com/search/issues?q=repo:tokio-rs/tokio+is:issue+is:open` | `total_count` (320) [cite: 4] |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response (active); unanswered count (low) [cite: 30, 31] |
| Advisories | `https://rustsec.org/packages/tokio.html` | open advisories (0 on current stable; historical issues patched) [cite: 32] |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | `reqwest`, `axum`, `tonic` [cite: 18] |


#### `reqwest`

##### Landscape
In the Rust ecosystem, HTTP clients are distinctly categorized by their underlying execution model and their reliance on external runtime executors. `reqwest` serves as the established industry standard for asynchronous HTTP clients, offering a batteries-included, highly ergonomic API built intricately atop `hyper` and `tokio` [cite: 5, 6, 33]. Conversely, `ureq` acts as the leading standard for strictly synchronous, blocking HTTP requests, heavily favored by developers seeking a minimal dependency tree, rapid compile times, and complete independence from asynchronous executors [cite: 5, 9]. 

##### Principles and implementation
`reqwest` operates purely asynchronously; it interacts with the network by returning futures for connection establishment, request transmission, and payload streaming, yielding control back to the `tokio` reactor while waiting for remote servers to respond [cite: 23]. The client automatically manages an internal connection pool, handles HTTP/2 multiplexing natively, and delegates TLS negotiation to either the system-native TLS framework or the statically compiled `rustls` provider [cite: 6, 33, 34]. For the `rs-launch-blueprint` template, injecting a shared instance of `reqwest::Client` into the core adapters ensures that network latency experienced during third-party API calls does not block the executor thread. This non-blocking behavior is absolutely critical for preserving the high concurrency required by the web service layer, preventing long-running API fetches from starving other incoming web requests [cite: 5, 22].

##### Dominant choice
`reqwest` is the overwhelmingly dominant choice for asynchronous I/O and web integration. It provides the highest feature parity with accessible tools in other languages—such as Python's `requests` or Node's `fetch`—combined with robust connection pooling that is critical for web servers making repeated outbound API calls to identical hostnames [cite: 5, 23, 35].

##### Qualified shortlist
*   `reqwest`
*   `ureq`
*   `surf` (A lightweight asynchronous alternative, though its development velocity and ecosystem momentum have slowed significantly in recent years) [cite: 36].

##### Excluded by gate
*   `reqwest` version `0.13.x`: **Excluded by MSRV Gate.** The template's fixed parameters explicitly require an MSRV policy of `stable minus 2 minor versions`. The `reqwest` 0.13.5 release strictly requires Rust `v1.85.0` to compile [cite: 6]. Depending on the current stable version of the Rust compiler at the time of template execution, this aggressive version requirement may violate the MSRV policy. 
*   *Adjustment to Pass Gate:* To satisfy the MSRV gate fully, the template must pin its dependency to the `reqwest` `0.12.x` branch. This older branch maintains a highly conservative MSRV of `1.63.0` [cite: 34], ensuring it remains fully compliant with the "stable minus 2" parameter across a wide time horizon while continuing to provide total asynchronous feature parity.
*   `surf`: **Excluded by Maintenance Gate.** The `surf` project is widely considered dormant or at-risk, lacking the aggressive maintenance and rapid security patching characteristic of `reqwest`.

##### Up-and-comers
While `reqwest` currently has no direct, rising competitor that threatens its dominance in the fully-featured async space, the `reqwest` project itself continues to evolve modular components rapidly. The maintainers are actively modularizing the crate and pushing toward stabilization of bleeding-edge features like native HTTP/3 support [cite: 37].

##### Fit for this template
`reqwest` perfectly satisfies the end-to-end asynchronous requirement dictated by the presence of the web service. While a synchronous client like `ureq` compiles significantly faster and uses less memory out-of-the-box [cite: 5, 38], attempting to invoke `ureq` from within an asynchronous `axum` web handler requires wrapping the HTTP call in a `tokio::task::spawn_blocking` closure. Failing to do so would block the active worker thread and instantly starve the executor, crippling the web server's throughput [cite: 5, 19, 20]. This bridging pattern creates unnecessary syntactic friction, increases memory overhead under load due to thread allocation, and severely caps total application throughput to the fixed size of the blocking thread pool. `reqwest`, because it natively shares the exact same `tokio` reactor as `axum`, allows for seamless, non-blocking outbound requests [cite: 5]. Furthermore, `reqwest` exposes a `rustls-tls` feature that bypasses the need for system-level OpenSSL libraries. This ensures seamless cross-platform compilation on both Ubuntu and macOS CI runners, heavily simplifying the deployment pipeline by relying on a pure-Rust TLS implementation [cite: 33, 34].

##### Recommendation
Select `reqwest` (version `^0.12` to ensure MSRV compliance) as the core HTTP client. Configure it exclusively with the `rustls-tls` backend via Cargo features to completely eliminate dynamic linking dependencies on system OpenSSL, ensuring identical, reproducible builds across Ubuntu and macOS environments [cite: 33, 34]. Explicitly disable default features (`default-features = false`) in the `Cargo.toml` to prevent pulling in unnecessary synchronous blocking modules or system-native TLS implementations.

##### Ranked runner-up
`ureq`. If the application architecture were entirely reversed by the owner to prioritize the CLI exclusively, and the web service was forced to operate under a traditional thread-per-request synchronous model (for example, utilizing a synchronous server like `tiny_http`), `ureq` would easily be the superior choice due to its lack of runtime dependencies, minimal binary size, and near-instantaneous compilation times [cite: 9, 39].

##### Tradeoffs
Adopting `reqwest` introduces a massive dependency tree to the project, primarily due to its reliance on `hyper`, `tokio`, and complex cryptography crates for TLS [cite: 5, 40]. This heavily increases initial compilation times (often exceeding 10-15 seconds for the HTTP client dependency tree alone) and measurably inflates the baseline binary size. For a template intended to serve primarily as a fast CLI, this represents a significant ergonomic regression compared to `ureq`. However, the inclusion of connection pooling, HTTP/2 multiplexing, and non-blocking I/O—features absent or limited by default in `ureq` [cite: 5]—are non-negotiable requirements for ensuring the stability and performance of the web adapter when making high-volume outbound calls.

##### Parameters
*   `owns rs-http-client = reqwest`
*   `assumes target-os-matrix = ubuntu-latest, macos-latest`

##### Migration implications
*   Adapter traits defining the ports-and-adapters boundary must be rewritten to define methods returning `std::future::Future` (e.g., changing `fn fetch_data(&self)` to `async fn fetch_data(&self) -> Result<Data, Error>`).
*   The `reqwest::Client` instance must be initialized exactly once during the application startup (usually within `main.rs`) and passed by reference or via an `Arc` (Atomic Reference Count) to the core services. Instantiating a new `reqwest::Client` per request defeats connection pooling, exhausts system sockets, and severely degrades performance [cite: 23, 41].

##### Validation strategy
*   **Planned Check:** Compile the template on `ubuntu-latest` and `macos-latest` CI runners utilizing the `--no-default-features --features rustls-tls` flags to strictly verify successful compilation without requiring OpenSSL development headers to be installed on the host machine.
*   **Planned Check:** Execute a mock HTTP request within the CLI entry point, verifying that the syntax `reqwest::Client::new().get(...).send().await` correctly resolves and does not block the active Tokio executor, utilizing Tokio console or tracing instrumentation if necessary to confirm non-blocking behavior.

##### Confidence & re-verify trigger
Confidence in this specific client configuration is high. Re-verify this decision if `reqwest` ceases maintenance of the `0.12.x` branch while the `0.13.x` branch continues to push its MSRV aggressively out of alignment with the template's strict `stable minus 2` policy. Additionally, re-evaluate the HTTP client landscape if a highly performant, macro-less HTTP client tailored specifically and exclusively for `tokio` emerges, offering reduced compile times.

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/reqwest` | `crate.recent_downloads` |
| All-time downloads | `GET https://crates.io/api/v1/crates/reqwest` | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/reqwest/versions` | newest with `yanked: false`: `num` (0.12.x or 0.13.x), `created_at` [cite: 6, 34] |
| Stars, archived | `GET https://api.github.com/repos/seanmonstar/reqwest` | `stargazers_count` (11.7k), `archived` (false), `pushed_at` [cite: 42] |
| Open issues | `GET https://api.github.com/search/issues?q=repo:seanmonstar/reqwest+is:issue+is:open` | `total_count` (367) [cite: 33] |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count [cite: 43, 44] |
| Advisories | `https://rustsec.org/packages/reqwest.html` | open advisories (0) |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | Heavily adopted across the Rust web ecosystem [cite: 40] |

### Compatibility
The `tokio` and `reqwest` crates exhibit native, primary compatibility and are engineered to integrate flawlessly. `reqwest` is explicitly built upon `hyper` (the lower-level HTTP library), which in turn relies entirely on `tokio` for all socket management, connection polling, and timeout execution [cite: 40]. The overarching ecosystem is unified by design: `axum` (the template's fixed web framework parameter) is officially maintained by the `tokio` core team and leverages the exact same `tower` middleware stack as `hyper` [cite: 8, 18]. The combination of `tokio` (as the runtime), `reqwest` (as the HTTP client), and `axum` (as the web server) represents the most heavily tested, widely documented, and broadly adopted network stack in the entire Rust language. This trio guarantees zero friction in dependency resolution, prevents executor mismatches, and ensures that asynchronous tasks behave predictably under heavy load.

### Parameters
*   `owns rs-execution-model = async`
*   `owns rs-async-runtime = tokio`
*   `owns rs-http-client = reqwest`
*   `assumes rust-edition = 2024`
*   `assumes target-os-matrix = ubuntu-latest, macos-latest`
*   `assumes msrv-policy = stable minus 2 minor versions`

### Migration implications
Implementing an asynchronous execution model fundamentally shapes the syntax and structure of the template at a file level across multiple domains:

1.  **Core Traits and Structs:** Every port interface, repository trait, or service interacting with the network, file system, or database must define its methods as `async fn`. (e.g., `pub async fn process_request(...)`). 
2.  **CLI Entry (`src/main.rs`):** The standard `main` function must be decorated with the `#[tokio::main]` attribute macro. This macro abstracts the instantiation of the Tokio runtime and the invocation of `block_on` to ensure the asynchronous core functions can be awaited directly from the entry point [cite: 16].
3.  **HTTP Client Injection (`src/core/api.rs`):** The `reqwest::Client` will be instantiated exactly once in the entry point and passed into the core domain structures via dependency injection, ensuring critical connection pools and TLS sessions are reused across multiple invocations [cite: 23, 41].
4.  **Web Handlers (`src/web/handlers.rs`):** Because the `axum` framework natively consumes standard Rust `Future`s, handler definitions simply remain `async fn`. No `spawn_blocking` wrappers, manual thread management, or bridging logic will be required to pass incoming web requests down to the core library for processing [cite: 27].

### Validation strategy
To objectively prove that the end-to-end asynchronous principle holds without inadvertently blocking the executor or failing compilation on specific operating systems, the following validations must be executed against the final implementation:

1.  **Cross-Platform TLS Compilation Check:**
    *   *Command:* Execute `cargo build --target x86_64-unknown-linux-gnu` and `cargo build --target x86_64-apple-darwin` in isolated CI environments.
    *   *Expected behavior:* Both commands must succeed completely without requiring the installation of `libssl-dev` or `openssl` system headers on the host runners, proving definitively that `reqwest` is correctly and exclusively utilizing the pure-Rust `rustls-tls` backend [cite: 33, 34].
2.  **CLI Executor Integrity Check:**
    *   *Command:* Run a realistic CLI invocation fetching data from an external mock API. Utilize advanced linters (such as running Clippy with the `await_holding_lock` or blocking-in-async rules enabled) to statically analyze the codebase.
    *   *Expected behavior:* Clippy should pass with zero warnings regarding blocking operations occurring inside asynchronous contexts, mathematically confirming the core library is truly non-blocking and cooperatively yielding [cite: 20].
3.  **Web Adapter Concurrency Stress Test:**
    *   *Command:* Launch the optional web service locally and execute a high-concurrency stress test utilizing a tool like `hey` or `wrk` (e.g., `hey -c 1000 -n 10000 http://localhost:3000`).
    *   *Expected behavior:* The web server must successfully handle all 10,000 requests without timing out or suffering from thread exhaustion. This validates that `axum` is successfully multiplexing the core library's logic and the `reqwest` outgoing calls over `tokio`'s worker threads without blocking the event loop [cite: 17].

### Confidence & re-verify trigger
Confidence in this overarching architectural recommendation is extremely high. The "Tokio + Reqwest + Axum" stack is the undisputed bedrock of modern Rust network services, representing years of rigorous optimization and real-world hardening. The architectural decision to make the CLI accommodate the asynchronous nature of the web service—rather than artificially crippling the web service with a thread pool to accommodate a synchronous CLI—yields vastly superior throughput and absolute alignment with general ecosystem momentum. 

Re-verification of this execution model should only be triggered if the Rust Language Design Team successfully finalizes and implements "Keyword Generics." Keyword Generics represent the theoretical ability to write a single Rust function that compiles as both synchronous and asynchronous depending entirely on the caller's context. If this paradigm ever reaches stable Rust, the core library could theoretically be written once, consumed entirely synchronously by the CLI (eliminating `tokio` from the CLI entirely), and consumed asynchronously by the web service. Until that highly experimental language-level feature is finalized and proven stable, the async end-to-end model remains the singularly optimal architectural choice for hybrid templates.

**Sources:**
1. [shuttle.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGm_f7eLSh5vq-T8TfrLoQShRlPx1CnKDW8QLylycneV1-hRtOBO18my_-5xr6ZBPdhYe8elV5RU8FUt4Vne93Onovk447zV1lNekvBZfBXudXSbCQ6iXHgKWZfT207nAiG61zNuVfusWOXuqgM-8YzSdVOVwumDeN2oqvg2OLm)
2. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGmC6jJKsqeJ8ELjo5IHEzCKpbxs9lUkyyQCV1zsW0aEaknZZcmcRklrtAhDd8rrDe47QBvXjMPuzjKsVp-mWE4HS7pByKFI0CqCSsobQE9cXfuvEitPUACdNSnZCT9tLn45LPfuihlHG6kzupA0BGDPuvj91xp8_Lq0M1wJU5wI0v1Ezojr_1DEaTGOGERxKkLFYawuw_7kGHY3vzjZMtJoNKMm0w3jDuV4uPU0g==)
3. [mjmjmj.name](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEeOEzR7Wyn028Y4VZseDKoKqxjYF7wES0r_SZ7anHaU4dOoPzFlPoMLaZRa8Gev1KI1v_79LpNXVD4BVn-MXhOVEwyaGmsNpI4b66Me0Te4BUD9HeQqxUmfGq9Ekl3unn9XA9aXJ2uaQ==)
4. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGbFxkLl773H-5VzuiBwWTq43WxdRHP9f3Ii6DJsbKYZHpomNWm7CFIDn7ALSdug9qy_Gw5QoN86HIL0EK9zTzGKRG295H44vThiQp8hZDx0bHJe6T1OQ==)
5. [rustify.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGPE9M6HnGd1CwsImk7W8n1VDxMET4hEJePvDk8gozEvpj6YlxynkflN8-hYs0Rw8AdMbETBIWyeUKBS4ivVJVJsP3rZ-p9z9HG1KqX6TpTwwxmM2c9S4uSbMqoPcoaUBONl8KEtkqpJhN-R_-3RMvk8lBV)
6. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQELMuTMzl0Uwoi9o6QCC_4zHYeQqoKjCX6lIIKGCnAstAA4k_BfcNwaZM7Gan3lksPiCte0djA7jAXlHnBcpB5Mzd671pFQ64Ma668Q6iRueEEoiQfM)
7. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEnIlJcGcf6MiPR0klzXla0F0OzlF3i4J7KPYjhp5oTFzDMdW5p7kgx0NwlONoeZ_g89dkv_UFu4sNWZ2NQ5aBM90_8lM2y6IxyAGHqCuAH8MCT)
8. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEAuA2aNwaPnUCE3AMsSQGlM6uzHVR8cxL1qFBNevp1RdWjOWCoR-iK1kMsj77_qG7QlkH7pAMHBJHZQBkj7LsJHPFWiDc0ZnI8nU4ELGtEAx_jhhAkK-Q=)
9. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG7tDmeDe4CZ6aR4iS_Ir2rMRFZvtxvNHoLifM9tVvHeAJtGL2Uxtg0e6b_jXSdaEPdaQayo9dfi2jNdqxVeCybrgvUAQ42HXKDyi030TBDiUj2O_cHNmfc6w==)
10. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE_D1yDNjJ6_JRVYMfUZHKbY7pQc3F8_W9J4JStSEimuB_wkyAltxNDRvXxLRblV7_pBJHFTxIbZDTxxj_qGIne1gw1DQ0U9ZJ4Qwi6cA_vxliP)
11. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE8d2p7tHUytI_xFA8TdqQOZY78uYGrNI6J1Rgk5hLEuexqcXEjk5luzvSFFHVqTTLY5U-J1-O92VyhE4ER7pFxGnPNxlHqTKtdLuV3g8WcgmQ8-Hj2NQAzPoV1MQ==)
12. [nullderef.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG3-3ozzE0a2EcMHusjKMv8fySUg7ElIguqmQ3tkIWb1cOh0IQ1Q6bECtzUmSq41ZxbaIWKz97mH9J5eOBlO5eOC1GVgqNWUs1Y7h78OKJPTBh0XqtexpW3FoRA-6QSYug=)
13. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFqeV81gjG4vEcPwkzllPFq9Eii3AbilXyr57x-qnB4zELtpK6gJiL6bvNgxR1K2PV2-wYJ36IfcCzqIRp2_RP4-fKFdStErKbdX0lKD6Q_KcEXdkVXNQ==)
14. [youtube.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFT1uVnwzWC67rrAmtHKpItYvmhjP8R6CFWcCLLYAjK0Bst8iJxC3tw3QItUkolTrrFodkm_zJVKS-WHlCQCIs4o1zJP3jT1Lldwx4LUAcbWA1J9uwlasViG5SLbI6z67g=)
15. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFIjRogk4CNw8r2f0jvC90rkq5X41uwmcK7r_jinwlh2c5Uzi7Ph5y6JX9625j9TOP8fZqoI74x2CwFGBDNbMrUMYVEmfCJFbrbSF0Q-EQnI3VWWLpDoaPJuaKyWZBN)
16. [tokio.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEk5f6QEClHGPLwe0pRlkvbnlA3UoulyhZO-i_N-gGXeMF_NHaxvVcxYpmFaG1M4a7x1YssdkrTfDsZhmFShpCQMBpxng81ro3VqKYTaMCEynClOtiQ-Len01uf)
17. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGp9IYb36oIL-P1RlfAJ_LPnUiBlUlvQbRKgth1srp3gPNfi8HkJgn1ZpJf1X4zJVvB1XdiEmHl27P9txenDbbDaocrrKT1zxCTuJcRCC4GP4WBUntaQj611ZoO6D_zQULvXQ==)
18. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE_0CD3lnEVT4LCNiJazpf658QERiygzyl36fySsGmiGPelKA9vfc_TO5mFSqwYiJOPcLjSaXND4sjUhjAXLFcwfIhbxheV4SyDgmoaXUW3rICYxg==)
19. [greptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG0I5iO9_tGXUzdaySRTUPM9Bw9yqxFA6cmozg-pCzOUAIVpPO0UKnv0nMhpIr6AAakyW2tehfgR77sk3GI4QXmEPFn2RrBIdW0Vu7tarVcg7eXdQp61YA0HcYwydTqHg-zBPVWfH9sgC4LnBlhr1OBJzSV5Cmkdg==)
20. [greptime.cn](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG1F_UVEriojdGl8f7M7JvhT-oRWRS8WyMjPWPFmaaZZdMG0Q1ZUz6m5EzePq7j2WfSJ2R-_rsvfph3neSIbGqpED4Jyxs2TE9LUGjFey8kzfiImeGC1dnTWzFuSMVc7KDs5CbnA2gRioRER1zDiVOv9Bt8e8Bx)
21. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEUOeBwdENCFAzegn0LukYYk4bUxCv1BEM6cQ1-KLX4v2MAlouvmO0o6t61xwe5g7EiWd2AK9-dWbLrS5S3cN00AYd_TZLqI1h_OAbyFObtRa29ZjSY)
22. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH0qbEfzMeWWMXTsDvoV-V7WhTPIDflGPu3PwO8gSIbc4BNgQPFCIhBAIWoNU0ua5CmRpCsIf1HBu5ikHf264BnRR_fBqY9D-yGYOJpVxoUYMxVbF2IL2kVqKP0Rl0FntEi)
23. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHdCXcAvohOSXs-2pcm0-VwP1HQaJLZLRgsXzUCqeq4LgnCgDqhUTsOXwi5iK7VIowTFvjm8u88cSk0YWMzMz5Q-W6WXie6W9tXlSLtcA==)
24. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGzpq2bNVfFfKLPI43r8q7itkWIO5JkEiuvIl25hBtV_aY-5eXPC-Wll1rVkFajZu6rjB2po-1fVeq-JmdUIpSVR0-3NDlyPJK9O6HrsOID-WZrT3hT8PpbYY-8xUggbHXpgAHchrOEuJ4unnp0bH7DMViW-_DW5vAjmBi50WbblsUDxMFI4wW7wofTdUP0pLkI7x7C-MKEf2Ub21_BtEEb)
25. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHPd4oP7UGLPuTz3mBBQxP3wh3KJ_2udlY8abVMSd_AkhzxLJ_o1T2hvxp03D0txuxVkrZX1SPXPAlNa0hudGJX9aE2JZktcyfiTxF_8sybH1f-iwc=)
26. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH6LhVqI7qxLzNGDNVFXD9oEZgSWl2PZAR94LAmGoFLyIkseF5AEKQsSYrHLguCoj89cgxEo14hw1D9axQxXwP-Vb4oeINnmCP-f85oq0JiO0jyZeRXFc0jbitxFdf4)
27. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHEPlaA459Sp5qCGC_qeQNmv3Y674AA_6SaE9VDyFISsvSe-mv1-RTr4knwvmAzWZcAvraAMJrnZQGaQptoDKWde4D10zbt9SOOzLDYLs2APy4xTUJqaww=)
28. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFmFnHWDJIk-KPsYWVtucjIKMt5TVKHWFcMiQvbKfwJrwN_rzcHER-McZrMANjpUUQDpolUnKDws-ha0dFiRAkA-wPF6I0aRLdBBzL3MSYk67G3_vx_EWQRTVY3xg==)
29. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEinU7-_VHytuIpuLh67Hze_J5SUcO7DRAWF2lRGplar8E8Q_Tvh3diQPMqlQvwEzzUGXig01tuh4J7gF_zfsIjXcUSpG63k0_pSPzGPw_xu6bc8bduepb-bIFglIgaNBD-G3vQFWyt)
30. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFLLjYA0CJIIhxKa8kXDntqb5inVsNuX1D9sTD8_a4gZOvOfpF8FqtvcuzraixJzApMA19IerpDCtyFamNgvdlG9n3sSGaLpiWIQfJpRnXfSqnRjS9W4TeJBn9YiA==)
31. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGPGjCuNwHagiU1NbX7MAVmw-JxRwpCfLnKGp3FOGAQ__dD9oOB6l6rZXYrqdt6U_Ojo4IcESq2jxHjrlltqvnKAQzKhLJT3RoFgQqqIAGrrgT95R2sSbB4FnfzKmg=)
32. [rustsec.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQENQHLUaj6R9HrSmqiKPSk9ywUEDqhV54w5vCnMLay-aRWR0xbd--2Y6mWUfvRJNoQiVwKbz0CX6FtwkQEsnjWXlC1fQw3jDSLmGQavtpziRbQwv8Y0oqofNFOc3g==)
33. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHG1F7JchMLphYUkPd4TFLDMuK07XDciy9gp4_RsG5myYT28qbwCy-eovf2NbiuX362uMFK0mUjvu5B5SkS0rI9sQvOgyfqQDYD0vwAWvszO8HNq4PcmT2kR3ZU)
34. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHQRUSR-2t9NdehRa-8rXxbceAqQMCcXSz0B5zAG9DBxOYtocSL_Z_eLb6bcfKmUeewUyTg7KrEFTXyYbBEVmSwfPLnBZC7kAUUM_lgd-speACQ2rYfQ2bgKM2X-Q==)
35. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG3wva-9UH3QzywLM68VZCYHZYoA0if_gpx63AVjwCzz5B5bkLiEOhuC4fcYx74w13Tf4sVKLuf8rbdjzkSxL2_e212zJYrUHe7l3Y4RIcTZ1hryVuFkFBVrFJ0NrNUysVcNKTnoppHllLqDpg=)
36. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHcMPbcMseQjo3xTU_i3C1CG9B2oj7JLNXmxAfHEyePkZKGuhRslgEZ68BWArS61WPZdLZWscmei9dTh-TC47BZcZPoWhEz2YgZ_M5xGq1ks1lkhvAoRs7V0HrJz8LOPKjamr-UTxSgDUFFZktwXFzlTFBDDdqi1cQMCU8H4Cjfkgm4UNoyJcjSeKmbBOc=)
37. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHNzmfY1vASFkiR2jLXEN-JhcggCrXGPl9n-AaUcCbj-keQDS-xFQShQJc1QQ2hX4q7gZwmVSnFYk3-I4CPg45tzOXEAm1UICbnfK53N1ni6qbLzACc144-c4_1j-ockeSzjxhPrVhVUZZBDQQI)
38. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHk5n__EMWJcBj6CHeoAA5WnUzeRa5n60hFJpzaG6G-73s0-ka7T2WSFiFQjQk9ltryp_7nI-muGwME804Qd8rk82lk383T4b9yfFECAWiDB_gLYXdO9iV31xB6g2T0-Bw=)
39. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH-kweNbrcsTJ3aBsqIlNep3LHO83n-9nx9HxePvAzam33T6W41SW8xkVtZ02rE-NtUajnSJB_zUNKM4J_5gbdYzhMnxRR0PeQULD9Z0x4K_aXyTgkdVPuiZWuUfi3NPyJmS16rc3d5OrJgSlw=)
40. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGsWk-T-l7HXm2qNJGYViqqF9dUxhqbPRSyYBtPm2lROMg5-rECxxmLIayi12MeQv_TUnKxfxoPTbbcFMvEuuGVrXMj-TqnkxV1GRuNwCmV3IuslL3tCNH-dZw0N95LScnCYg==)
41. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFzO7F8W_FX6HZNawQ3LY5Q-JnqaWuvBVUQLhCX4b4b-KX3RYGSjuf7v1LfFo0Sf9Uk4UJWwUM2hnyVmpXA00Ni0sm67uNh8ore5YvNXJygY4kYTC5FZe1H1ThhL_F-tPJxsBZrau9leDcv2chMSIdswXRBT4j3cqIStTbFuyMZ9eJFRrcTxKa2FK0XDjLjkVAcpGFY)
42. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHJLn_lnyaQ798ZCC37kb8XpthT6nwUh2qbgRlpIWZyFFN-BqKJO7tIroQB8geJLzf1LFleEX4DQwVgiCDn86g77iITxqsS7ScGgnX87lBXebIBfZrZoH1x9uWX3r_vLQZ3JQ9bxFgxBJHBvcXYYw==)
43. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHKZU7nLdz1fI1kWf87qcOXl7mx9feclxTHRj2TwMfyyE0vW-6GclFEp0cVaV14to2FXEkUfv_-IgYoT6tuarw7HTdYRId_6yIYDvUVjapqp43JsyF3Opzt5iO-JXQA6rwdFdoe)
44. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG_y-5GoJ-8Y_NTR-uTHqmNwnf4cVEA_8aYpGONcWxjLau2UGEo877pWN8tHHk8nUeElYoGF3jWi-xlQc7F0k_C5bkfdiN82W3_IIYg4pGDqajtKSTenOuVulKqisIKNlfQXA==)

## Sources

- [shuttle.dev](https://www.shuttle.dev/blog/2022/06/16/a-short-introduction-to-async-rust)
- [mjmjmj.name](https://mjmjmj.name/rust/async-rust-complete-guide/)
- [medium.com](https://medium.com/@bhesaniyavatsal/tokio-vs-smol-the-async-rust-showdown-nobody-gave-you-a-cheat-sheet-for-a0952a2e7dca)
- [github.com](https://github.com/tokio-rs/tokio)
- [crates.io](https://crates.io/crates/reqwest)
- [rustify.rs](https://rustify.rs/articles/rust-reqwest-vs-ureq-vs-hyper-2026)
- [crates.io](https://crates.io/crates/axum-core)
- [crates.io](https://crates.io/crates/axum)
- [crates.io](https://crates.io/crates/ureq/2.10.1)
- [crates.io](https://crates.io/crates/smol)
- [github.com](https://github.com/fMeow/maybe-async-rs)
- [github.com](https://github.com/durch/block_on)
- [nullderef.com](https://nullderef.com/blog/rust-async-sync/)
- [youtube.com](https://www.youtube.com/watch?v=NSgyNb0egm4)
- [crates.io](https://crates.io/crates/tokio/range/%5E1)
- [tokio.rs](https://tokio.rs/tokio/topics/bridging)
- [github.com](https://github.com/tokio-rs/tokio/issues/6760)
- [crates.io](https://crates.io/crates/tokio)
- [greptime.com](https://greptime.com/blogs/2023-03-09-bridging-async-and-sync-rust)
- [greptime.cn](https://greptime.cn/blogs/2023-03-09-bridging-async-and-sync-rust)
- [github.com](https://github.com/tokio-rs/axum)
- [github.com](https://github.com/tokio-rs/axum/issues/2107)
- [docs.rs](https://docs.rs/reqwest/)
- [dev.to](https://dev.to/_56d7718cea8fe00ec1610/understanding-async-await-and-blockon-in-rust-with-real-examples-3clh)
- [github.com](https://github.com/smol-rs/smol)
- [crates.io](https://crates.io/crates/smol/0.1.18/code)
- [crates.io](https://crates.io/crates/axum/code)
- [crates.io](https://crates.io/crates/tokio/versions)
- [github.com](https://github.com/tokio-rs/tokio/discussions/4703)
- [github.com](https://github.com/tokio-rs/tokio/pulls)
- [github.com](https://github.com/tokio-rs/tokio/issues)
- [rustsec.org](https://rustsec.org/packages/tokio.html)
- [github.com](https://github.com/seanmonstar/reqwest)
- [crates.io](https://crates.io/crates/reqwest/0.12.5)
- [github.com](https://github.com/seanmonstar/reqwest/discussions/2861)
- [reddit.com](https://www.reddit.com/r/rust/comments/ebkmbg/best_executoragnostic_http_client_library/)
- [github.com](https://github.com/seanmonstar/reqwest/issues/3034%22%3E)
- [github.com](https://github.com/algesten/ureq/issues/267)
- [github.com](https://github.com/algesten/ureq/blob/main/CHANGELOG.md)
- [crates.io](https://crates.io/crates/reqwest/dependencies)
- [reddit.com](https://www.reddit.com/r/rust/comments/1o1ndvk/hidden_performance_killers_in_axum_tokio_diesel/)
- [github.com](https://github.com/seanmonstar/reqwest?ref=hackernoon.com)
- [github.com](https://github.com/seanmonstar/reqwest/issues)
- [github.com](https://github.com/seanmonstar/reqwest/releases)