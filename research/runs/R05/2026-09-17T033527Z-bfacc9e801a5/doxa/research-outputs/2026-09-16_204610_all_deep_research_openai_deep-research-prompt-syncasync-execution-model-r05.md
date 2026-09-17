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
provider: openai
model: gpt-5.6-sol
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

## Reasoning Summary
**Deciding candidate landscape**

I’m looking into the candidate landscape for different frameworks and clients. For synchronous options, I’ve considered reqwest and ureq, with async frameworks like axum and actix-web. I might also explore Rocket, tiny_http, or Rouille with thread pooling. For async runtimes, there’s tokio, async-std, and smol, so I need to check cross-platform options. As for HTTP clients, I’m thinking reqwest, hyper, and new options. I should verify the latest versions for everything too, including if they're current or future releases. It’s time to make some tool calls!

### Landscape

**Evidence convention.** All cited sources and raw URLs below were retrieved on **September 17, 2026**. Proposed code, commands, thresholds, and expected outcomes are explicitly marked as planned rather than executed. The exact crates.io download snapshots and most GitHub issue-response snapshots did not render successfully during this research session; those fields are marked `NOT CAPTURED` rather than replaced with rounded website figures.

**Category decided:** application-level I/O execution architecture: blocking versus non-blocking call chains, executor selection, HTTP client, and web-handler integration.

| Bin | Field map | Candidates carried forward |
|---|---|---|
| **Built-in / first-party toolchain** | Rust supplies `Future`, `async fn`, threads, blocking sockets, and language-level async support, but the standard library does not supply an async executor or a high-level HTTPS client/server. The Rust project continues to treat async ergonomics as an ecosystem-facing project area. ([github.com](https://github.com/rust-lang/rfcs/blob/master/text/3764-Project-Goals-2025h1.md)) | Blocking `std::thread`/`std::net`; an ecosystem executor is required for practical async networking. |
| **Established industry standard** | **Tokio 1.53.1**, **reqwest 0.13.5**, **Axum 0.8.9**; Actix-web 4.14.0 as another established async web framework; **ureq 3.4.2** as the principal blocking HTTP-client alternative; async-std 1.13.2 as an established alternative runtime. Tokio is identified as the dominant production runtime by the Rust ecosystem tools catalogue, and maintained Reqwest and Axum examples both use it. ([rust.dev](https://rust.dev/tools)) | Tokio/reqwest/Axum; Tokio/reqwest/Actix-web; ureq with a synchronous server. |
| **Up-and-comer / specialist** | **smol 2.0.2** is a credible small-runtime alternative. Other runtime and web-framework leads were not advanced because a complete client-plus-web bundle did not clear the evidence gates in this run. ([docs.rs](https://docs.rs/crate/smol/latest)) | smol only if the HTTP client and web server change with it; not as a second executor beside Tokio. |

#### Fitness before popularity

| Candidate architecture | License | MSRV/tree | RustSec | Ubuntu/macOS | Defaults/runtime coupling | Cost | Gate result |
|---|---|---|---|---|---|---|---|
| **Tokio + async reqwest + Axum** | Compatible: Tokio/Axum are MIT; Reqwest is MIT or Apache-2.0. ([github.com](https://github.com/tokio-rs/axum)) | Direct crates are below the current project MSRV of Rust 1.96; Axum documents MSRV 1.80. The resolved tree still requires an executable Rust-1.96 check. ([github.com](https://github.com/tokio-rs/axum)) | Conditional pass: historical Tokio advisories exist, so the selected lockfile must produce zero applicable advisories. ([rustsec.org](https://rustsec.org/packages/tokio.html)) | Architecture is cross-platform; final proof is the required two-OS CI matrix. | One Tokio executor. Reqwest’s native async example and Axum’s server examples are Tokio-based. | Medium/heavy base CLI; web feature adds Axum/Tower but not a second runtime. | **Qualified, subject to lockfile gates.** |
| **Tokio + async reqwest + Actix-web** | Compatible. | Expected to pass; must be checked on the lockfile. | Conditional on audit. | Cross-platform target. | Actix-web’s own blocking bridge runs on Tokio. ([docs.rs](https://docs.rs/actix-web/latest/actix_web/rt/task/fn.spawn_blocking.html)) | Similar runtime/client cost; different framework surface. | **Qualified runner-up web adapter.** |
| **ureq + synchronous web server** | ureq is a maintained blocking-client candidate. | Full bundle not established because the synchronous server candidate’s current MSRV/CI/advisory evidence was incomplete. | Incomplete. | Incomplete for the complete bundle. | No async runtime required if the server is also synchronous. | Lowest expected dependency/runtime cost. | **Architecturally viable, evidence-gated.** |
| **Blocking core + Axum/Actix bridge** | Components can pass. | Components can pass. | Conditional on audit. | Cross-platform. | Requires explicit `spawn_blocking`/`web::block`; Reqwest says its blocking API must not execute directly inside an async runtime. ([docs.rs](https://docs.rs/actix-web/latest/actix_web/rt/task/fn.spawn_blocking.html)) | Pays for the async web runtime and a blocking pool, often while retaining much of Reqwest’s async internals. | **Rejected as an architectural pattern.** |
| **smol plus Reqwest/Axum** | Runtime itself is a candidate. | Not the problem. | Must audit. | Must verify. | Would retain or reintroduce Tokio for the chosen client/web stack, producing two executors or compatibility layers. | Runtime-only savings do not imply bundle savings. | **Rejected for this bundle.** |

#### Authority used

- **Rust project material:** official async project goals and survey-derived server-use context establish that async is an ecosystem architecture concern, not merely a library benchmark contest. ([github.com](https://github.com/rust-lang/rfcs/blob/master/text/3764-Project-Goals-2025h1.md))
- **Maintainer documentation:** Tokio runtime/bridging documentation, Reqwest’s async and blocking contracts, Axum’s maintained examples and MSRV/safety policy, and Actix-web’s blocking bridge are authoritative for integration semantics. ([docs.rs](https://docs.rs/actix-web/latest/actix_web/rt/task/fn.spawn_blocking.html))
- **RustSec:** package pages are authoritative for known advisories; a lockfile audit remains necessary because a package page includes historical as well as currently applicable entries. ([rustsec.org](https://rustsec.org/packages/tokio.html))
- **Registry and repository APIs:** crates.io and GitHub API endpoints are the mandated sources for release, download, and repository figures. One current GitHub API snapshot was captured for Tokio; incomplete fields are not replaced by UI approximations. ([api.github.com](https://api.github.com/repos/tokio-rs/tokio))
- **Independent empirical evidence:** an RSpotify comparison measured blocking ureq and async Reqwest builds, binaries, and request timing. Its author explicitly describes the comparison as rough, so it is directional evidence rather than a current absolute benchmark. ([nullderef.com](https://nullderef.com/blog/web-api-client/))
- **Independent synthesis:** Corrode’s async-Rust survey reaches the pragmatic conclusion that Tokio and Reqwest are the safest mainstream choices when async is needed. It supports, but does not decide, the recommendation. ([corrode.dev](https://corrode.dev/blog/async/))

#### Practice evidence

- **crates.io itself**, the official Rust registry, currently pins Axum 0.8.9 and Tokio 1.53.1 in its production manifest. That is strong maintained-reference evidence for the runtime/server pair. ([github.com](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml))
- **Chromium’s Rust vendoring tooling** uses `reqwest::blocking::Client`. This is relevant counter-evidence: blocking Reqwest remains sensible for a CLI/tooling context that does not also need an async web request path. It does not establish fit for this dual CLI/web template. ([chromium.googlesource.com](https://chromium.googlesource.com/chromium/src/%2B/HEAD/tools/crates/gnrt/vendor.rs))
- **Axum’s maintained Todo example** uses `#[tokio::main]`, async handlers, and Tower middleware, demonstrating the recommended web composition. ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs))
- **Reqwest’s maintained README** presents Tokio as the native async execution environment and exposes both async and blocking clients. ([docs.rs](https://docs.rs/crate/reqwest/latest/source/README.md))
- **Kreuzberg 4.3.2** declares both Reqwest 0.13 and optional Axum 0.8, providing a published coexistence example; it is compatibility evidence, not a popularity-based selector. ([cloudfront-app.crates.io](https://cloudfront-app.crates.io/crates/kreuzberg/4.3.2/dependencies))

### Principles and implementation

#### Shared requirement and agreement level

The common principle behind both source ports is:

> **Keep one execution model through the driven-I/O call chain, and confine any adaptation to a process or framework composition root.**

Python realizes that principle with a blocking core and a web-edge thread-pool bridge. TypeScript realizes it with Promises throughout. For Rust, agreement is required at the **architectural-policy level**, because this choice controls public function signatures and cancellation/concurrency semantics.

**Must agree:**

1. Every operation that can perform outbound HTTP I/O is asynchronous.
2. CLI orchestration awaits the same application service called by the web adapter.
3. Web handlers are native async handlers.
4. Each process owns one Tokio runtime.
5. The primary HTTP path contains no `reqwest::blocking`, `ureq`, `spawn_blocking`, or `block_in_place`.
6. A single reusable `reqwest::Client` is constructed at composition time and shared.
7. Blocking third-party APIs, if later required, are isolated explicitly and are not allowed to redefine the main execution model.

**May vary:**

- Pure parsing, validation, formatting, and domain transformations remain ordinary synchronous `fn`.
- The CLI runtime uses Tokio’s current-thread scheduler; the web binary uses the multi-thread scheduler.
- R01 may represent the async port with native `async fn`, a generic future, a boxed future, or another object-safe form.
- Axum is the maintained reference adapter. Replacing it with Actix-web would not change the R05 execution decision because Actix-web is also async and Tokio-based.
- TLS roots, proxy behavior, compression, and similar Reqwest features may be tuned after measurement.

#### Architectural alternatives

| Pattern | CLI | Web service | Consequences |
|---|---|---|---|
| **Sync throughout: ureq + synchronous server** | Simplest signatures and tests; no executor startup. | Synchronous handler threads may call the core directly. | Best potential compile/binary footprint; each blocked upstream call occupies an OS thread; less alignment with mainstream Rust server middleware. |
| **Sync core + async Axum/Actix adapter** | Simple CLI. | Every core call must be wrapped in `spawn_blocking` or equivalent. | Direct analogue of the Python bridge exists, but it is explicit and awkward. Blocking work cannot generally be aborted once started, can delay runtime shutdown, needs `'static + Send` ownership, and requires bounded-pool policy. ([docs.rs](https://docs.rs/actix-web/latest/actix_web/rt/task/fn.spawn_blocking.html)) |
| **Async throughout: Tokio + Reqwest + async handlers** | One runtime entry and `.await` propagation. | Native framework path; no thread-pool adaptation around HTTP. | Larger base CLI, but one cancellation/concurrency model, direct connection pooling, and no per-handler bridge. |
| **Alternative async runtime** | Runtime itself may be smaller. | Mainstream Reqwest/Axum integration still points to Tokio. | To obtain real savings, the runtime, client, and web framework must all change together; otherwise the bundle becomes larger and less coherent. |

Reqwest explicitly warns that its blocking client must not be called inside an async runtime and recommends wrapping transitive blocking calls in `spawn_blocking`. Tokio and Actix document that such work occupies blocking-pool threads, queues when capacity is reached, cannot generally be aborted once running, and can prolong shutdown. That makes the Python-style bridge technically available but materially more visible than FastAPI’s automatic handling. ([docs.rs](https://docs.rs/actix-web/latest/actix_web/rt/task/fn.spawn_blocking.html))

A fully synchronous web stack can avoid an executor altogether, so the answer is not “Rust web services always require async.” The narrower conclusion is that **the dominant maintained web path represented by Axum and Actix-web is async and Tokio-shaped**. Choosing synchronous web execution would therefore be a deliberate whole-stack fork, not a small optimization to the same adapter.

#### Concrete cost evidence

A historical RSpotify experiment reported these whole-project results:

| Variant | Debug compilation | Release compilation | Release binary | Stripped binary | Measured operation |
|---|---:|---:|---:|---:|---:|
| Blocking ureq | 38.5 s | 55.9 s | 7.3 MB | 2.6 MB | 503.6 ms/iteration |
| Async Reqwest | 51.014 s | 86.594 s | 8.5 MB | 4.0 MB | 432.49 ms/iteration |

The benchmark did not hold all implementation details constant and predates the selected 2026 versions. It therefore supports only the directional conclusion that Reqwest plus Tokio commonly costs compile time and binary size while potentially improving concurrent or network-bound execution; it cannot establish current absolute deltas. ([nullderef.com](https://nullderef.com/blog/web-api-client/))

Tokio 1.53.1’s docs.rs package page reports 4.72 MB of crate source and a 17-second docs.rs build, while Reqwest 0.13.5 reports 760.44 kB of crate source. Those are **not** application binary-size or clean-build measurements and should not be used as such. ([docs.rs](https://docs.rs/crate/tokio/latest))

For this template:

- **Default CLI cost:** Tokio, Reqwest, Hyper-family HTTP machinery, and TLS are present even for a single round trip.
- **Web-feature delta:** Axum/Tower dependencies are optional, but Tokio is already present.
- **Sync ureq alternative:** likely smaller and faster to compile; this is the strongest argument for sync.
- **Reqwest blocking alternative:** does not obtain the full ureq advantage and then requires a blocking bridge when the web feature is enabled.
- **Async benefit:** primarily architectural consistency and web scalability, not faster execution of one isolated CLI request.

#### Runtime choice

Tokio is selected because the **whole bundle**, not the runtime in isolation, converges on it:

- Reqwest’s maintained native async example uses Tokio.
- Axum’s maintained examples use Tokio.
- Actix-web’s blocking bridge itself is backed by Tokio.
- crates.io deploys Tokio and Axum together.
- Tokio provides current-thread and multi-thread scheduler flavors, so the CLI does not need to start a worker thread per CPU merely to perform one request. ([github.com](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml))

A smol runtime may be attractive in isolation, but combining it with Reqwest/Axum would either retain Tokio transitively or require replacing both the client and web framework. That creates a less standard bundle with no demonstrated template-level size win.

#### CLI ergonomics

The recommended CLI entry point is:

```rust
#[tokio::main(flavor = "current_thread")]
async fn main() -> std::process::ExitCode {
    rs_launch_blueprint::cli::run().await
}
```

The ergonomic cost is one async entry point and `.await` propagation through I/O-touching commands. CLI parsing and pure command dispatch can remain synchronous.

There is also a documented synchronous-shell pattern:

```rust
fn main() -> std::process::ExitCode {
    let runtime = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .expect("Tokio runtime");

    runtime.block_on(rs_launch_blueprint::cli::run())
}
```

Tokio documents `Runtime::block_on` and notes that most applications instead use `#[tokio::main]`. This wrapper is acceptable if a conventional `fn main()` is desired; it does **not** justify adding a duplicate synchronous library API. ([docs.rs](https://docs.rs/tokio/latest/tokio/runtime/struct.Handle.html?search=Option%3CT%3E%2C+%28T+-%3E+U%29+-%3E+Option%3CU%3E))

Clap and Cargo template conventions do not provide an authoritative CLI+library+web execution policy. No maintained official Clap or cargo-generate example was found that resolves this exact three-surface problem, so template frequency was not used as a selector.

#### Minimal reference composition

```toml
[package]
edition = "2024"
rust-version = "1.96"

[features]
default = []
web = [
    "dep:axum",
    "tokio/net",
    "tokio/signal",
    "tokio/rt-multi-thread",
]

[dependencies]
tokio = { version = "1.53.1", features = ["macros", "rt"] }
reqwest = { version = "0.13.5", features = ["json"] }
axum = { version = "0.8.9", optional = true, features = ["json"] }
serde = { version = "1", features = ["derive"] }

[[bin]]
name = "rs-launch-blueprint-web"
path = "src/bin/web.rs"
required-features = ["web"]
```

Reqwest 0.13 documents rustls as its default TLS path, with native TLS available as an alternative. Keeping defaults plus `json` is the lowest-risk initial template configuration; feature trimming should follow current bundle measurements rather than guesses. ([docs.rs](https://docs.rs/crate/reqwest/latest/source/README.md))

```rust
pub struct ProjectsApi {
    client: reqwest::Client,
    base_url: reqwest::Url,
}

impl ProjectsApi {
    pub async fn list_projects(&self) -> Result<Vec<Project>, ApiError> {
        let response = self
            .client
            .get(self.base_url.join("projects")?)
            .send()
            .await?
            .error_for_status()?;

        Ok(response.json().await?)
    }
}

// R01 decides how this service is abstracted or injected.
pub async fn execute_list_projects(
    projects: &ProjectsService,
) -> Result<Vec<Project>, AppError> {
    projects.list().await
}
```

```rust
// src/main.rs
#[tokio::main(flavor = "current_thread")]
async fn main() -> std::process::ExitCode {
    cli::run().await
}
```

```rust
// src/bin/web.rs
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    web::serve().await
}
```

```rust
async fn list_projects(
    axum::extract::State(app): axum::extract::State<AppState>,
) -> Result<axum::Json<Vec<Project>>, WebError> {
    Ok(axum::Json(app.projects.list().await?))
}
```

#### Observable acceptance criteria

1. Both CLI and web call the same async application-service method.
2. The default CLI binary uses a current-thread Tokio runtime.
3. The optional web binary uses Tokio multi-thread execution and async handlers.
4. No production HTTP path contains `reqwest::blocking`, `ureq`, `spawn_blocking`, or `block_in_place`.
5. Axum is absent from the default dependency graph.
6. Only one Tokio major is present in each resolved graph.
7. Dropping/cancelling a web request releases the awaited application future without waiting for a blocking-pool job to finish.
8. A delayed upstream request does not prevent an independent Tokio heartbeat task from running.
9. The lockfile passes Rust 1.96, RustSec, license, and Ubuntu/macOS checks.
10. Clean-build time, unique normal/build dependency count, stripped binary size, maximum RSS, thread count, and p50/p95/p99 latency are recorded for async, sync-ureq, and sync-bridge prototypes before implementation closes R05.

`BASELINE-REVIEW: F016 — execution-model coherence at the driven-I/O boundary — resolve Rust to async end-to-end instead of preserving py’s blocking-core/thread-pool bridge — Reqwest forbids direct blocking-client use in an async runtime, while Tokio’s required bridge is explicit, non-abortable once running, and can delay shutdown; the dominant Rust web adapters are async.`

`BASELINE-REVIEW: F022 — one executor selected at each process composition root — set Tokio 1.53.1, current-thread for the CLI binary and multi-thread for the optional web binary — maintained Reqwest and Axum examples compose on Tokio, Actix-web’s bridge uses Tokio, and crates.io deploys Tokio with Axum.`

These are proposed ledger changes. F016/F022 should remain as recorded until owner approval updates `docs/port/COMMONALITY.md`.

### Recommendation

**Adopt an async driven-I/O boundary end-to-end.**

- **Runtime:** Tokio **1.53.1**
- **HTTP client:** Reqwest **0.13.5**, async `Client`, reused for the lifetime of the application
- **Reference web adapter:** Axum **0.8.9**, optional under the existing `web` feature
- **CLI entry:** `#[tokio::main(flavor = "current_thread")] async fn main`
- **Web entry:** a separate feature-gated binary with `#[tokio::main]`
- **Core/application signatures:** `async fn` wherever outbound I/O may occur
- **Web handlers:** native `async fn` that await the same service methods
- **Policy:** no blocking HTTP client or blocking-pool bridge in the primary path

This accepts a measurable CLI build/binary tax to avoid maintaining two execution semantics and to make the optional web service a native consumer of the core.

### Members

#### Tokio 1.53.1

##### Landscape

Tokio is the established runtime choice. smol 2.0.2 is the leading lighter-runtime alternative; async-std 1.13.2 remains an established alternative. Neither provides a better complete Reqwest-plus-mainstream-web bundle without changing more than the runtime. ([rust.dev](https://rust.dev/tools))

| Required figure | Snapshot on 2026-09-17 |
|---|---|
| 90-day downloads | `NOT CAPTURED`; required endpoint: `GET https://crates.io/api/v1/crates/tokio`, field `crate.recent_downloads` |
| All-time downloads | `NOT CAPTURED`; same endpoint, field `crate.downloads` |
| Last release | **1.53.1** confirmed by docs.rs; exact `created_at` from the non-yanked versions endpoint was not captured. ([docs.rs](https://docs.rs/crate/tokio/latest)) |
| Stars | **33,164**, from the mandated repository API. ([api.github.com](https://api.github.com/repos/tokio-rs/tokio)) |
| Archived | **false**, same endpoint. ([api.github.com](https://api.github.com/repos/tokio-rs/tokio)) |
| Pushed at | **2026-09-16T10:40:29Z**, same endpoint. ([api.github.com](https://api.github.com/repos/tokio-rs/tokio)) |
| Open issues | `NOT CAPTURED`; the repository metadata’s combined issues/PR field was intentionally not substituted for the required search endpoint. |
| Issue responsiveness | `NOT COMPUTED`; applicable evidence gap: ten newest issues and maintainer-association review are still required. |
| Advisories | RustSec lists historical Tokio advisories, including a 2025 soundness notice; applicability must be resolved by auditing the selected lockfile. ([rustsec.org](https://rustsec.org/packages/tokio.html)) |
| Adopter | crates.io pins Tokio 1.53.1 with Axum 0.8.9. ([github.com](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml)) |
| Maintenance state | **active**: current release documentation and a repository push one day before retrieval. ([docs.rs](https://docs.rs/crate/tokio/latest)) |

##### Principles and implementation

Tokio realizes the one-executor policy while supporting different scheduler flavors at separate composition roots. The CLI can remain single-thread scheduled; the web process can use work-stealing multi-thread execution. Tokio also supplies the explicit boundary for exceptional blocking APIs, but that boundary is not used for HTTP. ([github.com](https://github.com/tokio-rs/tokio))

##### Dominant choice

Tokio is the dominant complete-stack choice because Reqwest, Axum, Actix-web, Tower, Hyper, and many service-oriented crates integrate directly with it. Selection is based on bundle compatibility, not solely its repository popularity. ([rust.dev](https://rust.dev/tools))

##### Qualified shortlist

| Gate | Tokio 1.53.1 |
|---|---|
| License | Pass: MIT. |
| MSRV | Provisional pass against Rust 1.96; prove the complete lockfile under that toolchain. |
| Advisories | Conditional pass only after `cargo audit`/`cargo deny`. Historical advisories mean “latest” is not sufficient evidence. |
| Unsafe posture | Low-level runtime implementation may use unsafe/platform primitives; no unsafe API is required by this template. Record `cargo geiger` output for the full tree. |
| OS | Expected pass on Linux/macOS; prove in the template’s required CI. |
| Features/coupling | Base: `macros`, `rt`; web adds `net`, `signal`, `rt-multi-thread`. |
| Build cost | Medium: runtime, macros, reactor, and platform dependencies are present in the default CLI graph. |

##### Excluded by gate

- Any runtime whose complete runtime/client/web bundle cannot pass Rust 1.96, zero-applicable-advisory, Ubuntu, and macOS checks.
- A “smol plus Tokio-based Reqwest/Axum” bundle is excluded because it violates the one-executor principle.
- Runtime-only benchmark winners are excluded unless the full dependency graph is also measured.

##### Up-and-comers

**smol 2.0.2** is the strongest lighter-runtime lead. It should be reconsidered only if a maintained high-level HTTP client and web adapter form a coherent, single-runtime bundle with comparable CI, security, and middleware evidence. ([docs.rs](https://docs.rs/crate/smol/latest))

##### Fit for this template

Tokio is a good fit because the template has two different process workloads:

- CLI: one or a few I/O operations, suited to current-thread scheduling.
- Web: multiple overlapping requests, suited to the multi-thread scheduler.
- Library: async functions need not expose Tokio-specific types even though the production adapter requires a Tokio context.

##### Recommendation

Use:

```toml
tokio = { version = "1.53.1", features = ["macros", "rt"] }

[features]
web = [
    "tokio/net",
    "tokio/signal",
    "tokio/rt-multi-thread",
]
```

Commit a lockfile for binaries and refresh patch versions only after the same gates pass.

##### Ranked runner-up

**smol 2.0.2**, but only as part of a wholesale runtime/client/server replacement. It is not a drop-in runner-up for this bundle.

##### Tradeoffs

- Adds executor/reactor code to a CLI that may make one request.
- Introduces async-specific debugging and testing concepts.
- `spawn_blocking` remains available but is non-abortable after start and can prolong shutdown; its existence should not normalize blocking HTTP. ([docs.rs](https://docs.rs/actix-web/latest/actix_web/rt/task/fn.spawn_blocking.html))
- Current-thread scheduling limits runtime thread overhead but does not eliminate compile or binary cost.

##### Parameters

- `runtime = tokio@1.53.1`
- `cli-scheduler = current-thread`
- `web-scheduler = multi-thread`
- `runtime-count-per-process = 1`
- `blocking-http-on-runtime = forbidden`

##### Migration implications

- Add Tokio to the always-present dependencies.
- Make CLI orchestration async.
- Add a Tokio macro or explicit runtime builder to each binary.
- Feature-gate multi-thread, network-listener, and signal features with `web`.
- Convert I/O tests to async tests.
- Do not expose Tokio-specific synchronization types from the domain layer unless separately justified.

##### Validation strategy

Planned:

```bash
cargo tree -d
cargo tree -i tokio
cargo +1.96.0 check --workspace --all-targets
cargo +1.96.0 check --workspace --all-targets --features web
cargo test --workspace
cargo test --workspace --features web
```

Expected:

- Exactly one Tokio major.
- Default CLI compiles without Axum or `rt-multi-thread`.
- Web graph enables the additional runtime features.
- A heartbeat task continues while 256 delayed HTTP requests are pending.

##### Confidence & re-verify trigger

**High architectural confidence; medium evidence-completeness confidence.**

Reverify if:

- Axum 0.9 becomes stable;
- Reqwest gains a maintained runtime-independent native connector;
- Tokio raises MSRV beyond the project policy;
- the measured stripped CLI delta exceeds the owner’s size budget;
- any lockfile audit reports an applicable advisory;
- a coherent smol-based bundle demonstrates materially better total cost.

##### Sources

Retrieved **2026-09-17**:

- `https://docs.rs/crate/tokio/latest` ([docs.rs](https://docs.rs/crate/tokio/latest))
- `https://github.com/tokio-rs/tokio` ([github.com](https://github.com/tokio-rs/tokio))
- `https://api.github.com/repos/tokio-rs/tokio` ([api.github.com](https://api.github.com/repos/tokio-rs/tokio))
- `https://docs.rs/tokio/latest/tokio/runtime/struct.Runtime.html` ([docs.rs](https://docs.rs/tokio/latest/tokio/runtime/struct.Runtime.html))
- `https://docs.rs/tokio/latest/tokio/runtime/struct.Handle.html` ([docs.rs](https://docs.rs/tokio/latest/tokio/runtime/struct.Handle.html?search=Option%3CT%3E%2C+%28T+-%3E+U%29+-%3E+Option%3CU%3E))
- `https://rustsec.org/packages/tokio.html` ([rustsec.org](https://rustsec.org/packages/tokio.html))
- Required uncaptured endpoints:
  - `https://crates.io/api/v1/crates/tokio`
  - `https://crates.io/api/v1/crates/tokio/versions`
  - `https://api.github.com/search/issues?q=repo:tokio-rs/tokio+is:issue+is:open`

#### Reqwest 0.13.5

##### Landscape

Reqwest is the established high-level client with async and blocking APIs. Ureq 3.4.2 is the strongest blocking alternative; Hyper is the lower-level protocol/client toolkit and would require the template to own more TLS, connector, redirect, JSON, and error behavior. ([github.com](https://github.com/seanmonstar/reqwest?_sp=44baacb4-ca03-4c24-b2da-9681ed77e01f))

| Required figure | Snapshot on 2026-09-17 |
|---|---|
| 90-day downloads | `NOT CAPTURED`; endpoint `GET https://crates.io/api/v1/crates/reqwest` |
| All-time downloads | `NOT CAPTURED`; same endpoint |
| Last release | **0.13.5** confirmed by docs.rs; exact non-yanked `created_at` not captured. ([docs.rs](https://docs.rs/crate/reqwest/latest)) |
| Source package size | **760.44 kB** on docs.rs; not application binary size. ([docs.rs](https://docs.rs/crate/reqwest/latest)) |
| Stars/archived/pushed | `NOT CAPTURED` from the mandated GitHub repository API; rounded UI values were not substituted. |
| Open issues | `NOT CAPTURED` from the mandated issue-search API. |
| Issue responsiveness | `NOT COMPUTED`; applicable evidence gap. |
| Advisories | No direct package result was captured; zero applicable direct and transitive advisories must be demonstrated against the lockfile. |
| Adopter | Chromium’s `gnrt` uses the blocking API; the maintained Reqwest example uses the async client with Tokio. ([chromium.googlesource.com](https://chromium.googlesource.com/chromium/src/%2B/HEAD/tools/crates/gnrt/vendor.rs)) |
| Maintenance state | **active**: 0.13.5 is the current docs.rs release. ([docs.rs](https://docs.rs/crate/reqwest/latest)) |

##### Principles and implementation

Reqwest implements the application’s outbound HTTP boundary. Its async client preserves cancellation and non-blocking composition with web handlers. The client must be built once and reused so connection pooling survives across service calls.

The blocking module is explicitly unsuitable for direct execution inside an async runtime and may panic if used there. That contract makes it a poor core API when the same service is called from Axum. ([docs.rs](https://docs.rs/reqwest/latest/reqwest/blocking/))

##### Dominant choice

Reqwest is the dominant high-level async choice because it supplies:

- async and blocking APIs;
- JSON, multipart, redirects, proxies, TLS, and WebAssembly support;
- a maintained Tokio composition;
- a substantially higher-level API than Hyper. ([docs.rs](https://docs.rs/crate/reqwest/latest/source/README.md))

Popularity is confirmatory only; the decisive factor is that the selected web stack already requires asynchronous composition.

##### Qualified shortlist

| Gate | Reqwest 0.13.5 |
|---|---|
| License | Pass: MIT or Apache-2.0. |
| MSRV | Provisional pass against Rust 1.96; verify the resolved TLS, Hyper, and URL trees. |
| Advisories | Conditional on zero findings from lockfile audit. |
| Unsafe posture | No unsafe API is exposed by the template; TLS and low-level networking dependencies must be included in `cargo geiger` and advisory review. |
| OS | Rustls-default path is appropriate for Ubuntu and macOS; native TLS remains optional. ([github.com](https://github.com/seanmonstar/reqwest?_sp=44baacb4-ca03-4c24-b2da-9681ed77e01f)) |
| Defaults/coupling | Native async use requires a Tokio environment; defaults provide rustls, while `json` is explicitly enabled. |
| Build cost | Medium/heavy: high-level HTTP, TLS, protocol, encoding, and Tokio integration. |

##### Excluded by gate

- **Reqwest blocking mode** is excluded from the production core because it fails the execution-model acceptance criterion, even though the crate itself remains qualified.
- Any lock resolving an affected TLS, Hyper, HTTP/2, or platform dependency is excluded until upgraded or configured safely.
- Alternative clients lacking current MSRV, two-OS CI, advisory, and maintained-adopter evidence are evidence-gated.

##### Up-and-comers

No up-and-coming client demonstrated a better complete fit than Reqwest in this survey. Hyper is established but lower-level; ureq is established and intentionally synchronous rather than a new async replacement.

##### Fit for this template

Reqwest’s cost is least defensible for the one-request CLI in isolation and most defensible for the combined CLI/library/web product:

- it avoids two client implementations;
- the web path can await it directly;
- a shared `Client` provides pooling;
- extending the CLI with parallel requests does not require redesign;
- HTTP cancellation is represented by dropping futures rather than managing blocking threads.

##### Recommendation

Use:

```toml
reqwest = { version = "0.13.5", features = ["json"] }
```

Construct one client:

```rust
let client = reqwest::Client::builder()
    .timeout(std::time::Duration::from_secs(30))
    .user_agent(concat!(
        env!("CARGO_PKG_NAME"),
        "/",
        env!("CARGO_PKG_VERSION")
    ))
    .build()?;
```

Do not use convenience functions that construct a fresh client for every service operation.

##### Ranked runner-up

**ureq 3.4.2**, but only if the owner changes the complete architecture to synchronous CLI, core, and web execution. It is not recommended behind Axum’s handlers. ([docs.rs](https://docs.rs/crate/ureq/latest))

##### Tradeoffs

- Larger compile graph and binary than a deliberately small blocking client.
- Runtime startup is paid on short CLI invocations.
- Async signatures propagate into every I/O-touching extension point.
- In exchange, the web adapter avoids blocking-pool ownership, cancellation, queueing, and shutdown problems.
- A historical whole-project comparison measured a 4.0 MB stripped async-Reqwest binary versus 2.6 MB with blocking ureq, but the result is too old and uncontrolled to use as a current budget. ([nullderef.com](https://nullderef.com/blog/web-api-client/))

##### Parameters

- `http-client = reqwest@0.13.5`
- `http-client-api = async`
- `client-lifetime = application-scoped`
- `tls-baseline = reqwest default rustls path`
- `json = enabled`
- `blocking-feature = forbidden in production`

##### Migration implications

- Replace blocking `.send()?` calls with `.send().await?`.
- Await body decoding.
- Construct and inject one `Client`.
- Propagate async through the service and CLI router.
- Remove any blocking-client-specific `Read` handling.
- Add explicit timeout, status mapping, and user-agent policy.
- Update mocks to supply async responses according to the R01 seam.

##### Validation strategy

Planned:

```bash
rg -n 'reqwest::blocking|ureq::|blocking::Client' src crates
cargo tree -i reqwest
cargo audit
cargo deny check
cargo geiger --all-features
```

Behavioral test:

1. Start a local delayed Axum upstream.
2. Make 256 overlapping service calls through one client.
3. Assert all complete and that an independent Tokio heartbeat keeps advancing.
4. Abort half of the request tasks and assert the mock server’s active-request counter returns to zero within a bounded interval.
5. Verify connection reuse using server-side accepted-connection instrumentation.

##### Confidence & re-verify trigger

**High architectural confidence; medium metric confidence.**

Reverify on:

- Reqwest 0.14 or 1.0;
- a change in default TLS features;
- an applicable RustSec advisory;
- an MSRV increase;
- a measured CLI size/build regression outside the owner’s budget;
- a maintained smaller async client with equivalent protocol, TLS, proxy, JSON, CI, and adoption evidence.

##### Sources

Retrieved **2026-09-17**:

- `https://docs.rs/crate/reqwest/latest` ([docs.rs](https://docs.rs/crate/reqwest/latest))
- `https://github.com/seanmonstar/reqwest` ([github.com](https://github.com/seanmonstar/reqwest?_sp=44baacb4-ca03-4c24-b2da-9681ed77e01f))
- `https://docs.rs/reqwest/latest/reqwest/blocking/` ([docs.rs](https://docs.rs/reqwest/latest/reqwest/blocking/))
- `https://chromium.googlesource.com/chromium/src/+/HEAD/tools/crates/gnrt/vendor.rs` ([chromium.googlesource.com](https://chromium.googlesource.com/chromium/src/%2B/HEAD/tools/crates/gnrt/vendor.rs))
- `https://nullderef.com/blog/web-api-client/` ([nullderef.com](https://nullderef.com/blog/web-api-client/))
- Required uncaptured endpoints:
  - `https://crates.io/api/v1/crates/reqwest`
  - `https://crates.io/api/v1/crates/reqwest/versions`
  - `https://api.github.com/repos/seanmonstar/reqwest`
  - `https://api.github.com/search/issues?q=repo:seanmonstar/reqwest+is:issue+is:open`
  - `https://rustsec.org/packages/reqwest.html`

#### Axum 0.8.9

##### Landscape

Axum and Actix-web are the established async web candidates. Axum is the better reference for this item because it is maintained by the Tokio organization, uses Tower services, and directly demonstrates ordinary async handler functions. Actix-web 4.14.0 is the qualified runner-up and leads to the same R05 runtime decision. ([github.com](https://github.com/tokio-rs/axum))

Synchronous frameworks such as Rouille and lower-level servers such as tiny_http establish that an executor-free web service is possible, but their current complete fitness evidence was not captured, so they are not approved bundle members here.

| Required figure | Snapshot on 2026-09-17 |
|---|---|
| 90-day downloads | `NOT CAPTURED`; endpoint `GET https://crates.io/api/v1/crates/axum` |
| All-time downloads | `NOT CAPTURED`; same endpoint |
| Last release | **0.8.9** confirmed by docs.rs and the crates.io production manifest; exact non-yanked `created_at` not captured. ([github.com](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml)) |
| Stars/archived/pushed | `NOT CAPTURED` from the exact repository API; rounded GitHub UI figures were not substituted. |
| Open issues | `NOT CAPTURED` from the mandated issue-search endpoint. |
| Issue responsiveness | `NOT COMPUTED`; applicable evidence gap. |
| Advisories | No direct package snapshot was captured; zero applicable direct/transitive advisories must be proven from the lockfile. |
| Adopter | crates.io pins Axum 0.8.9 with Tokio 1.53.1. ([github.com](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml)) |
| Maintenance state | **active**: the project maintains the 0.8 release branch while developing 0.9. ([github.com](https://github.com/tokio-rs/axum)) |

##### Principles and implementation

Axum preserves the execution principle by making request handlers futures that can await the same service calls used by the CLI. It uses Tower’s service/middleware model rather than requiring a separate application-specific middleware abstraction. ([github.com](https://github.com/tokio-rs/axum))

It does not automatically convert an arbitrary blocking core into an appropriately bounded, cancellable operation. Such calls need an explicit Tokio blocking boundary, with the documented non-abortability and shutdown consequences.

##### Dominant choice

Axum is the dominant reference for new Tokio-native services because:

- it is maintained within the Tokio organization;
- its examples use Tokio directly;
- it composes with Tower middleware;
- it forbids unsafe code;
- it documents MSRV 1.80;
- crates.io itself deploys it. ([github.com](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml))

##### Qualified shortlist

| Gate | Axum 0.8.9 |
|---|---|
| License | Pass: MIT. |
| MSRV | Pass directly: documented as Rust 1.80, below the template’s Rust 1.96. Dependency tree still requires verification. ([github.com](https://github.com/tokio-rs/axum)) |
| Advisories | Conditional on lockfile audit. |
| Unsafe posture | Strong: Axum documents `#![forbid(unsafe_code)]`; transitive Hyper/Tokio/TLS code still requires tree-level review. ([github.com](https://github.com/tokio-rs/axum)) |
| OS | Framework is platform-neutral over Tokio/Hyper; final proof is Ubuntu/macOS CI. |
| Defaults/coupling | Tokio-native server path; optional dependency under `web`. |
| Build cost | Medium feature delta: Axum, Tower, routing, extractors, and server dependencies; absent from default graph. |

##### Excluded by gate

- A synchronous server candidate is excluded from recommendation until its current release, MSRV, advisory, unsafe, and Ubuntu/macOS CI evidence is captured.
- A blocking-core Axum adapter is excluded by the architectural acceptance gate.
- Any framework that introduces a second executor is excluded.

##### Up-and-comers

Poem and Salvo are relevant research leads, but neither was advanced because the required current maintenance and full gate evidence was incomplete. Their existence does not change the runtime conclusion unless they produce a non-Tokio complete bundle with a material measured advantage.

##### Fit for this template

Axum is a good reference because the web capability is optional:

- no Axum code enters the default CLI graph;
- its state extractor can hold the same service/client graph as the CLI;
- handler signatures show the intended async boundary clearly;
- Tower layers provide timeouts, tracing, concurrency limits, and load shedding without wrapping the core in a thread pool.

##### Recommendation

Use Axum 0.8.9 as the R05 reference adapter:

```toml
axum = { version = "0.8.9", optional = true, features = ["json"] }
```

Keep it behind:

```toml
[features]
web = ["dep:axum", "tokio/net", "tokio/signal", "tokio/rt-multi-thread"]
```

This is a reference implementation, not a silent claim that R05 owns every future web-framework choice.

##### Ranked runner-up

**Actix-web 4.14.0.** It remains async and uses Tokio internally, so replacing Axum with Actix-web would preserve the R05 recommendation while changing handler/extractor and middleware APIs. ([docs.rs](https://docs.rs/actix-web/latest/actix_web/rt/task/fn.spawn_blocking.html))

##### Tradeoffs

- Adds framework and Tower compile cost when `web` is enabled.
- Strongly aligns the adapter with Tokio.
- Axum 0.9 is under development, so a near-term migration may be needed.
- In return, the adapter is thin: handlers await the application service directly and do not own a blocking-pool policy.

##### Parameters

- `reference-web-adapter = axum@0.8.9`
- `web-dependency = optional`
- `web-handler-model = async`
- `web-runtime = existing Tokio runtime`
- `blocking-core-bridge = forbidden`
- `framework-selection-ownership = reference only; defer if another item owns the final framework`

##### Migration implications

- Add `src/bin/web.rs` with `required-features = ["web"]`.
- Change handler functions from synchronous wrappers to `async fn`.
- Remove Python-derived comments about framework-managed thread pools.
- Put the shared application state and reusable Reqwest client in Axum state.
- Add request timeout, tracing, and concurrency layers at the adapter.
- Add graceful shutdown using Tokio signals.
- Keep HTTP serialization/status mapping in the adapter rather than the domain.

##### Validation strategy

Planned:

```bash
cargo check --no-default-features
cargo check --features web --bin rs-launch-blueprint-web
cargo test --features web
cargo tree --no-default-features | grep -E 'axum|tower' && exit 1 || true
```

Integration test:

1. Bind an ephemeral Tokio listener.
2. Start Axum with application state containing one Reqwest client.
3. Call the public route.
4. Verify it invokes the same service used by the CLI.
5. Cancel selected client requests.
6. Assert no Tokio worker is blocked by outbound HTTP.
7. Run under both `ubuntu-latest` and `macos-latest`.

##### Confidence & re-verify trigger

**Medium-high confidence as the reference adapter.**

Reverify when:

- Axum 0.9 is released;
- another registry item owns the final web-framework selection;
- crates.io or another authoritative adopter migrates to a materially different stack;
- a security/MSRV issue affects the selected release;
- the feature-enabled binary exceeds the owner’s size or build-time budget.

##### Sources

Retrieved **2026-09-17**:

- `https://docs.rs/crate/axum/latest` ([docs.rs](https://docs.rs/crate/axum/latest))
- `https://github.com/tokio-rs/axum` ([github.com](https://github.com/tokio-rs/axum))
- `https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs` ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs))
- `https://github.com/rust-lang/crates.io/blob/main/Cargo.toml` ([github.com](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml))
- `https://docs.rs/actix-web/latest/actix_web/rt/task/fn.spawn_blocking.html` ([docs.rs](https://docs.rs/actix-web/latest/actix_web/rt/task/fn.spawn_blocking.html))
- Required uncaptured endpoints:
  - `https://crates.io/api/v1/crates/axum`
  - `https://crates.io/api/v1/crates/axum/versions`
  - `https://api.github.com/repos/tokio-rs/axum`
  - `https://api.github.com/search/issues?q=repo:tokio-rs/axum+is:issue+is:open`
  - `https://rustsec.org/packages/axum.html`

### Compatibility

The proposed version matrix is:

| Member | Version | Compatibility evidence |
|---|---:|---|
| Tokio | 1.53.1 | crates.io currently pins this release with Axum 0.8.9. ([github.com](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml)) |
| Reqwest | 0.13.5 | Maintained example declares Reqwest 0.13 with Tokio 1. ([docs.rs](https://docs.rs/crate/reqwest/latest/source/README.md)) |
| Axum | 0.8.9 | Maintained examples use Tokio; crates.io pins Axum 0.8.9 and Tokio 1.53.1 together. ([github.com](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml)) |

Additional shared-adopter evidence: Kreuzberg 4.3.2 declares Reqwest 0.13 and optional Axum 0.8 in one published dependency graph. ([cloudfront-app.crates.io](https://cloudfront-app.crates.io/crates/kreuzberg/4.3.2/dependencies))

**Evidence limit:** a clean build of the exact three-member lockfile was not executed in this response. Compatibility is therefore source-supported but still requires the planned Rust-1.96, current-stable, Ubuntu, and macOS matrix before merge.

### Parameters

```text
owns driven-io-execution-model = async-end-to-end
owns async-runtime = tokio@1.53.1
owns http-client = reqwest@0.13.5 async Client
owns cli-runtime-entry = Tokio current-thread runtime
owns web-handler-execution-model = native async handlers
owns blocking-http-policy = forbidden in production I/O paths

assumes web-feature = optional Cargo feature (F017 ADOPT)
assumes rust-edition = 2024
assumes rust-version = 1.96.0 as the 2026-09-17 evaluation of stable-minus-2
assumes msrv-raise-policy = minor-release-only
assumes license = MIT OR Apache-2.0
assumes target-os-matrix = ubuntu-latest, macos-latest
assumes ports-and-adapters-seam = unresolved by R01

CONFLICT: none
```

Axum 0.8.9 is the reference implementation used to prove the execution model. If another item owns final framework selection, it may substitute Actix-web without changing these owned R05 parameters.

### Migration implications

| File/area | Required change |
|---|---|
| `Cargo.toml` | Add Tokio and Reqwest; add optional Axum; define `web`; declare `rust-version = "1.96"`; add required-feature web binary. |
| `Cargo.lock` | Regenerate and commit for binaries; audit under both minimum and current stable toolchains. |
| `src/lib.rs` | Re-export application API without exposing runtime-specific types unnecessarily. |
| Core application/service modules | Change every outbound-I/O-touching operation from `fn` to `async fn`; keep pure transformations synchronous. |
| HTTP adapter | Replace blocking request calls with a reusable async `reqwest::Client`; await send and body decoding; add timeout/status mapping. |
| CLI router/orchestrator | Change `run_cli` and I/O command branches to async; await application services. |
| `src/main.rs` | Add current-thread Tokio entry point. |
| `src/bin/web.rs` | Add optional multi-thread Tokio web process. |
| Web routers/handlers | Use native async handlers and await the same services as the CLI; remove thread-pool-bridge commentary. |
| Application state | Construct one client/service graph per process; clone cheap handles into handlers. |
| Tests | Use async tests for I/O paths; add a local delayed upstream and cancellation instrumentation. |
| CI | Test default and `web` graphs on Ubuntu and macOS, on Rust 1.96 and current stable. |
| Security/licensing | Add lockfile advisory, license, source, and unsafe-tree checks. |
| `docs/port/COMMONALITY.md` | After owner acceptance only, record the F016 and F022 decisions and evidence; do not edit silently. |
| `docs/port/PARAMETERS.md` | Record R05-owned parameter values after approval. |

R01 remains responsible for whether the async port is a generic bound, object-safe boxed future, native async trait, or direct injection.

### Validation strategy

**Executed during research:** source survey only.

**Not executed:** compilation, tests, local benchmark, crates.io metric script, GitHub issue-response calculation, `cargo audit`, `cargo deny`, or `cargo geiger`.

#### 1. MSRV, feature, and OS proof

```bash
rustup toolchain install 1.96.0
rustup toolchain install stable

cargo +1.96.0 check --workspace --all-targets --locked
cargo +1.96.0 check --workspace --all-targets --locked --features web
cargo +1.96.0 test  --workspace --locked
cargo +1.96.0 test  --workspace --locked --features web

cargo +stable check --workspace --all-targets --locked
cargo +stable check --workspace --all-targets --locked --features web
cargo +stable test  --workspace --locked --all-features

cargo +stable fmt --all -- --check
cargo +stable clippy --workspace --all-targets --all-features -- -D warnings
```

Run the same matrix on `ubuntu-latest` and `macos-latest`.

**Expected:** every command succeeds; no dependency requires a compiler newer than Rust 1.96.

#### 2. Execution-model proof

```bash
rg -n \
  'reqwest::blocking|ureq::|spawn_blocking|block_in_place|std::thread::spawn' \
  src crates
```

**Expected:** no match in the production outbound-HTTP path. Approved isolated blocking integrations, if any, must be documented separately.

```bash
cargo tree -d
cargo tree -i tokio
cargo tree --no-default-features | grep -E '(^| )axum |(^| )tower '
```

**Expected:**

- one Tokio major;
- no second executor;
- no Axum/Tower server dependencies in the default graph.

#### 3. Security, license, and unsafe posture

```bash
cargo audit
cargo deny check advisories
cargo deny check licenses
cargo deny check sources
cargo geiger --all-features
```

**Expected:**

- zero applicable open advisories;
- all dependency licenses accepted by policy;
- registry/git sources conform to policy;
- unsafe usage is recorded and reviewed, with Axum itself remaining unsafe-free.

#### 4. Realistic behavior test

Create a test upstream that:

- returns a 4 KiB JSON response;
- supports a configurable 100 ms delay;
- increments an active-request counter on entry;
- decrements through a drop guard;
- records accepted TCP connections;
- emits tracing spans for request start, cancellation, and completion.

Test:

```bash
cargo test --test execution_model -- --nocapture
cargo test --features web --test web_round_trip -- --nocapture
```

**Expected:**

- CLI and web invoke the same async service.
- One shared Reqwest client reuses connections.
- A 10 ms heartbeat task keeps running while upstream calls await.
- Cancelling request tasks causes the active-request counter to return to zero within the test timeout.
- No blocking-pool job is needed for HTTP.

#### 5. Comparative cost experiment

Maintain three temporary, behavior-equivalent prototypes:

1. `tokio + async reqwest + axum`
2. `ureq + synchronous server`
3. `blocking core + axum + spawn_blocking`

Use identical:

- JSON request/response schema;
- TLS policy;
- release profile;
- target triple;
- 4 KiB payload;
- 100 ms upstream delay;
- timeout;
- logging disabled for load tests.

Measure clean and incremental builds:

```bash
hyperfine --warmup 1 \
  --prepare 'cargo clean' \
  'cargo build --release --locked --bin rs-launch-blueprint'

cargo build --release --timings
cargo bloat --release --crates
cargo tree -e normal,build --prefix none | sort -u | wc -l
```

Measure binary size:

```bash
cp target/release/rs-launch-blueprint /tmp/rs-launch-blueprint
strip /tmp/rs-launch-blueprint

# Linux
stat -c '%s' /tmp/rs-launch-blueprint

# macOS
stat -f '%z' /tmp/rs-launch-blueprint
```

Measure CLI cold starts:

```bash
hyperfine --runs 100 \
  './target/release/rs-launch-blueprint projects list'
```

Measure web load:

```bash
oha -z 30s -c 1   http://127.0.0.1:3000/projects
oha -z 30s -c 32  http://127.0.0.1:3000/projects
oha -z 30s -c 256 http://127.0.0.1:3000/projects
```

Capture:

- p50, p95, p99;
- requests/second;
- CPU time;
- maximum RSS;
- OS-thread count;
- voluntary/involuntary context switches;
- active upstream calls;
- blocking-pool queue depth where observable.

**Expected qualitative result:** ureq/sync should win some build and size measurements; the async design should avoid thread-per-outstanding-request behavior and should preserve heartbeat/cancellation behavior under concurrency. No absolute throughput winner should be declared unless the same workload, configuration, hardware, and instrumentation are used.

#### 6. Required ecosystem-figure script

Before the dependency ledger is finalized, capture:

```bash
curl -fsSL https://crates.io/api/v1/crates/tokio
curl -fsSL https://crates.io/api/v1/crates/tokio/versions
curl -fsSL https://crates.io/api/v1/crates/reqwest
curl -fsSL https://crates.io/api/v1/crates/reqwest/versions
curl -fsSL https://crates.io/api/v1/crates/axum
curl -fsSL https://crates.io/api/v1/crates/axum/versions
```

For each repository:

```bash
gh api repos/OWNER/REPO
gh api 'search/issues?q=repo:OWNER/REPO+is:issue+is:open'
gh api \
  'search/issues?q=repo:OWNER/REPO+is:issue&sort=created&order=desc&per_page=10'
```

For the ten-issue sample, inspect comments/timeline events and count the first response from an `OWNER`, `MEMBER`, or `COLLABORATOR`; report median elapsed days and unanswered count.

### Confidence & re-verify trigger

**Decision confidence: high.** The strongest fit is an async core because the optional web capability is owner-fixed and the mainstream Rust web adapters are already async. A blocking core would either force the whole product onto a less-standard synchronous web stack or create an explicit, non-cancellable blocking bridge.

**Version confidence: medium-high.** Tokio 1.53.1, Reqwest 0.13.5, and Axum 0.8.9 were current on September 17, 2026, but all three are active projects and Axum 0.9 is already under development. ([docs.rs](https://docs.rs/crate/tokio/latest))

**Evidence-completeness confidence: medium.** Exact mandated download counts, most repository API snapshots, open-issue counts, and ten-issue responsiveness medians remain uncaptured. These gaps do not change the execution-model reasoning, but they **must block final ledger closure and dependency pin approval**.

Re-run the decision if any of the following occurs:

- Axum 0.9 or Reqwest 0.14/1.0 is released;
- the implementation date is more than 90 days after September 17, 2026;
- an applicable RustSec advisory appears;
- any selected dependency exceeds Rust 1.96 under the current policy evaluation;
- the async CLI exceeds the owner’s binary/build budget in the specified like-for-like benchmark;
- a synchronous server candidate clears every gate and the web workload is explicitly bounded to low concurrency;
- a non-Tokio bundle provides maintained client, web, middleware, two-OS CI, security, and adoption evidence with materially lower measured total cost;
- R01 chooses a seam form that exposes an unforeseen async object-safety constraint.

### Sources

All retrieved **2026-09-17**.

#### Authoritative architecture and API sources

- Rust async project goals: `https://github.com/rust-lang/rfcs/blob/master/text/3764-Project-Goals-2025h1.md` ([github.com](https://github.com/rust-lang/rfcs/blob/master/text/3764-Project-Goals-2025h1.md))
- Rust ecosystem tools map: `https://rust.dev/tools` ([rust.dev](https://rust.dev/tools))
- Tokio repository: `https://github.com/tokio-rs/tokio` ([github.com](https://github.com/tokio-rs/tokio))
- Tokio runtime: `https://docs.rs/tokio/latest/tokio/runtime/struct.Runtime.html` ([docs.rs](https://docs.rs/tokio/latest/tokio/runtime/struct.Runtime.html))
- Tokio sync bridge: `https://docs.rs/tokio/latest/tokio/runtime/struct.Handle.html` ([docs.rs](https://docs.rs/tokio/latest/tokio/runtime/struct.Handle.html?search=Option%3CT%3E%2C+%28T+-%3E+U%29+-%3E+Option%3CU%3E))
- Reqwest repository/README: `https://github.com/seanmonstar/reqwest` ([github.com](https://github.com/seanmonstar/reqwest?_sp=44baacb4-ca03-4c24-b2da-9681ed77e01f))
- Reqwest blocking contract: `https://docs.rs/reqwest/latest/reqwest/blocking/` ([docs.rs](https://docs.rs/reqwest/latest/reqwest/blocking/))
- Axum repository: `https://github.com/tokio-rs/axum` ([github.com](https://github.com/tokio-rs/axum))
- Axum maintained Todo example: `https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs` ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs))
- Actix/Tokio blocking bridge: `https://docs.rs/actix-web/latest/actix_web/rt/task/fn.spawn_blocking.html` ([docs.rs](https://docs.rs/actix-web/latest/actix_web/rt/task/fn.spawn_blocking.html))

#### Version sources

- Tokio 1.53.1: `https://docs.rs/crate/tokio/latest` ([docs.rs](https://docs.rs/crate/tokio/latest))
- Reqwest 0.13.5: `https://docs.rs/crate/reqwest/latest` ([docs.rs](https://docs.rs/crate/reqwest/latest))
- Axum 0.8.9: `https://docs.rs/crate/axum/latest` ([docs.rs](https://docs.rs/crate/axum/latest))
- Ureq 3.4.2: `https://docs.rs/crate/ureq/latest` ([docs.rs](https://docs.rs/crate/ureq/latest))
- smol 2.0.2: `https://docs.rs/crate/smol/latest` ([docs.rs](https://docs.rs/crate/smol/latest))
- async-std 1.13.2: `https://docs.rs/crate/async-std/latest` ([docs.rs](https://docs.rs/crate/async-std/latest))

#### Security and practice sources

- Tokio RustSec package page: `https://rustsec.org/packages/tokio.html` ([rustsec.org](https://rustsec.org/packages/tokio.html))
- RustSec advisory index: `https://rustsec.org/advisories/` ([rustsec.org](https://rustsec.org/advisories/))
- crates.io production manifest: `https://github.com/rust-lang/crates.io/blob/main/Cargo.toml` ([github.com](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml))
- Chromium Reqwest blocking use: `https://chromium.googlesource.com/chromium/src/+/HEAD/tools/crates/gnrt/vendor.rs` ([chromium.googlesource.com](https://chromium.googlesource.com/chromium/src/%2B/HEAD/tools/crates/gnrt/vendor.rs))
- Published Axum/Reqwest coexistence: `https://cloudfront-app.crates.io/crates/kreuzberg/4.3.2/dependencies` ([cloudfront-app.crates.io](https://cloudfront-app.crates.io/crates/kreuzberg/4.3.2/dependencies))

#### Independent performance and synthesis

- RSpotify client/build comparison: `https://nullderef.com/blog/web-api-client/` ([nullderef.com](https://nullderef.com/blog/web-api-client/))
- Async-Rust ecosystem synthesis: `https://corrode.dev/blog/async/` ([corrode.dev](https://corrode.dev/blog/async/))
- Historical client/server binary-size benchmark repository: `https://github.com/OSSystems/web-client-server-binary-size-benchmark-rs` ([github.com](https://github.com/OSSystems/web-client-server-binary-size-benchmark-rs))

#### Exact metric endpoints requiring pre-merge capture

```text
https://crates.io/api/v1/crates/tokio
https://crates.io/api/v1/crates/tokio/versions
https://crates.io/api/v1/crates/reqwest
https://crates.io/api/v1/crates/reqwest/versions
https://crates.io/api/v1/crates/axum
https://crates.io/api/v1/crates/axum/versions

https://api.github.com/repos/tokio-rs/tokio
https://api.github.com/repos/seanmonstar/reqwest
https://api.github.com/repos/tokio-rs/axum

https://api.github.com/search/issues?q=repo:tokio-rs/tokio+is:issue+is:open
https://api.github.com/search/issues?q=repo:seanmonstar/reqwest+is:issue+is:open
https://api.github.com/search/issues?q=repo:tokio-rs/axum+is:issue+is:open
```

## Sources

- [https://github.com/rust-lang/rfcs/blob/master/text/3764-Project-Goals-2025h1.md](https://github.com/rust-lang/rfcs/blob/master/text/3764-Project-Goals-2025h1.md)
- [https://rust.dev/tools](https://rust.dev/tools)
- [https://docs.rs/crate/smol/latest](https://docs.rs/crate/smol/latest)
- [https://github.com/tokio-rs/axum](https://github.com/tokio-rs/axum)
- [https://rustsec.org/packages/tokio.html](https://rustsec.org/packages/tokio.html)
- [https://docs.rs/actix-web/latest/actix_web/rt/task/fn.spawn_blocking.html](https://docs.rs/actix-web/latest/actix_web/rt/task/fn.spawn_blocking.html)
- [https://api.github.com/repos/tokio-rs/tokio](https://api.github.com/repos/tokio-rs/tokio)
- [https://nullderef.com/blog/web-api-client/](https://nullderef.com/blog/web-api-client/)
- [https://corrode.dev/blog/async/](https://corrode.dev/blog/async/)
- [https://github.com/rust-lang/crates.io/blob/main/Cargo.toml](https://github.com/rust-lang/crates.io/blob/main/Cargo.toml)
- [https://chromium.googlesource.com/chromium/src/%2B/HEAD/tools/crates/gnrt/vendor.rs](https://chromium.googlesource.com/chromium/src/%2B/HEAD/tools/crates/gnrt/vendor.rs)
- [https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs)
- [https://docs.rs/crate/reqwest/latest/source/README.md](https://docs.rs/crate/reqwest/latest/source/README.md)
- [https://cloudfront-app.crates.io/crates/kreuzberg/4.3.2/dependencies](https://cloudfront-app.crates.io/crates/kreuzberg/4.3.2/dependencies)
- [https://docs.rs/crate/tokio/latest](https://docs.rs/crate/tokio/latest)
- [https://docs.rs/tokio/latest/tokio/runtime/struct.Handle.html?search=Option%3CT%3E%2C+%28T+-%3E+U%29+-%3E+Option%3CU%3E](https://docs.rs/tokio/latest/tokio/runtime/struct.Handle.html?search=Option%3CT%3E%2C+%28T+-%3E+U%29+-%3E+Option%3CU%3E)
- [https://github.com/tokio-rs/tokio](https://github.com/tokio-rs/tokio)
- [https://docs.rs/tokio/latest/tokio/runtime/struct.Runtime.html](https://docs.rs/tokio/latest/tokio/runtime/struct.Runtime.html)
- [https://github.com/seanmonstar/reqwest?_sp=44baacb4-ca03-4c24-b2da-9681ed77e01f](https://github.com/seanmonstar/reqwest?_sp=44baacb4-ca03-4c24-b2da-9681ed77e01f)
- [https://docs.rs/crate/reqwest/latest](https://docs.rs/crate/reqwest/latest)
- [https://docs.rs/reqwest/latest/reqwest/blocking/](https://docs.rs/reqwest/latest/reqwest/blocking/)
- [https://docs.rs/crate/ureq/latest](https://docs.rs/crate/ureq/latest)
- [https://docs.rs/crate/axum/latest](https://docs.rs/crate/axum/latest)
- [https://docs.rs/crate/async-std/latest](https://docs.rs/crate/async-std/latest)
- [https://rustsec.org/advisories/](https://rustsec.org/advisories/)
- [https://github.com/OSSystems/web-client-server-binary-size-benchmark-rs](https://github.com/OSSystems/web-client-server-binary-size-benchmark-rs)