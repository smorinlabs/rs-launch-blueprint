---
prompt: # Deep-research prompt — Sync/async execution model (R05, bundle)
mode: all_deep_research
provider: combined
model: Multiple
operation_id: research-20260916-204610-04c498ad606e4c5b
note: built by the P02 controller in the format of doxa_research.output.OutputManager.generate_combined_report (a concatenation of the saved provider files, no model call); Doxa 3.3.0 'resume --async' cannot honour the submission's --combined flag
---

# Combined Research Report: # Deep-research prompt — Sync/async execution model (R05, bundle)

Generated: 2026-09-17T05:12:28.547194+00:00


## Openai Results

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

---


## Perplexity Results

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
provider: perplexity
model: sonar-deep-research
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

# Sync versus Async Execution for `rs-launch-blueprint`: A Rust Execution Model and Runtime Stack

The execution model chosen for `rs-launch-blueprint`—whether synchronous blocking or asynchronous non-blocking—will determine the shape of every I/O‑touching function, the CLI entry point, the optional web service, and the HTTP client and runtime stack layered beneath them. Rust’s ecosystem in 2026 is sharply different from both Python’s synchronous standard library model and JavaScript’s built‑in event loop: the language ships a synchronous standard library only, while production async I/O depends on separately chosen runtimes such as **Tokio**, with async web frameworks, database clients, and HTTP crates largely standardized around that choice.[4][9][15][16] The evidence from authoritative guidance and widely adopted projects shows that the Rust ecosystem has consolidated on **async end‑to‑end I/O for networked services**, with Tokio as the dominant runtime, while synchronous designs remain viable for simple CLIs whose network use is minimal and low‑concurrency.[4][6][9] However, when a template is intended to serve as both a CLI and an optional web service, and must allow consumers to extend both, the balance of fit shifts decisively toward an async boundary: it aligns with dominant web frameworks, avoids awkward thread‑pool bridges, enables consistent abstractions over HTTP transport, and remains ergonomically acceptable for a CLI that usually performs only one or a few HTTP round‑trips per invocation.[1][4][13][15] The recommendation that follows, grounded in a fresh survey of runtimes and frameworks, proposes an **async I/O boundary shared by CLI and web service, implemented on Tokio and an async `reqwest` client, with Axum as the reference web framework**, and details the tradeoffs, fitness gates, migration implications, and validation strategy needed to treat this as a bundle decision in the ledger.

## Evidence landscape and ecosystem survey

### Landscape

The category this item decides is the **driven‑I/O execution boundary for a Rust template that is simultaneously a CLI, a reusable library, and an optional web service**. In concrete terms, that boundary spans the CLI entry function, the library’s outward‑facing operations that perform HTTP calls, and the web service’s request handlers, and it must choose between a **sync blocking model** (simple `fn` functions that block the current thread on I/O) and an **async non‑blocking model** (`async fn` returning `Future`s, executed on a runtime such as Tokio or smol).[4][6][10] Within that category, Rust’s field divides naturally into three bins: built‑in or first‑party toolchain facilities, established industry standards in the crate ecosystem, and up‑and‑comer alternatives that target specialized workloads.

The built‑in or first‑party bin consists primarily of the **synchronous Rust standard library**, which provides blocking I/O primitives like `std::net::TcpStream`, `std::fs::File`, and thread concurrency via `std::thread`, as well as the compile‑time async/await feature that lowers `async fn` to state machines but intentionally omits any built‑in executor or I/O runtime.[4][6][10] The Rust project’s own documentation and independent introductions emphasize that futures generated by `async fn` must be **driven by an external runtime**, and that the core language does not prescribe how that runtime is chosen.[4][6][10] This makes Rust unlike Node.js, whose event loop is built‑in, and more like a system where you must explicitly add an executor crate such as Tokio or smol to perform non‑blocking I/O.[4][9][10] As a result, synchronous execution remains the default and simplest path for small CLIs, while asynchronous execution is explicit and opt‑in, shaped by third‑party crates.

The established industry‑standard bin is dominated by **Tokio**, which multiple independent surveys and ecosystem snapshots describe as the de facto standard runtime for async Rust in 2026.[1][2][3][4][5][7][8][9] Tokio provides a multi‑threaded work‑stealing executor, I/O drivers for epoll, kqueue, and IOCP, timers, synchronization primitives, and supporting utilities for DNS, filesystem access, and process management.[1][4][5][7][15] It is the foundation for hyper, one of the fastest and most widely used HTTP libraries in Rust; for high‑level web frameworks such as Axum and Warp; for gRPC frameworks like Tonic; and for networked systems from Discord’s infrastructure to AWS services.[3][4][13][15][16][17][20] Ecosystem surveys report that tens of thousands of crates depend on Tokio, that most mainstream async crates either require Tokio or offer Tokio integration, and that newer web frameworks such as Axum explicitly assume Tokio as their runtime.[4][8][9][15][17] In addition to Tokio, several **async HTTP clients** have become standard: `reqwest` is widely used for HTTP client functionality and uses hyper and Tokio for its async mode, while providing a separate `reqwest::blocking` module for synchronous use cases.[11][15] On the server side, **Axum**, **Warp**, **Actix‑web**, and Rocket’s modern versions represent the established frameworks for web services, with Axum and Warp both built directly on hyper and Tokio, and Actix‑web explicitly running atop Tokio for its async executor despite its actor‑based concurrency model.[13][14][15][16][17][20]

The up‑and‑comer bin contains several runtimes and patterns that challenge or complement Tokio under specific workloads, as well as crates and execution patterns that emphasize minimalism or sync‑first designs. **smol** is a tiny async runtime with a minimalist executor, single‑threaded by default but capable of multi‑threaded operation through `async-executor`, and it uses the `polling` and `async-io` crates for cross‑platform async I/O.[1][2][4][5][7][8] Its philosophy is to keep the runtime small, composable, and suitable for library authors who do not wish to force a particular executor on downstream users; smol’s 2.0 line places emphasis on being runtime‑agnostic at the library layer.[4][5][8] However, smol’s ecosystem is deliberately smaller, and many production‑grade async crates either assume Tokio or require explicit compat layers when used with smol.[1][4][5][7][9] **async‑std** historically mirrored the Rust standard library API with async equivalents and used the same underlying `async-io` and `polling` building blocks as smol, but it has been officially discontinued since 2025; documentation and ecosystem guides now treat it as legacy only and recommend migration to smol or Tokio.[5][7][8][9] Further up‑and‑comers include **glommio** and **monoio**, both Linux‑only runtimes built on `io_uring` with thread‑per‑core architectures aimed at maximum I/O throughput for storage engines and high‑concurrency proxies.[2][5][7][8] These runtimes achieve higher throughput and lower latencies than Tokio in microbenchmarks but at the cost of portability, complexity, and narrower ecosystems.[2][5][7] On the synchronous web side, crates like **tiny_http** implement low‑level HTTP servers using blocking I/O and thread‑per‑connection designs, offering minimal dependencies and no runtime coupling, and serving as foundations for higher‑level sync frameworks or custom routing stacks.[12] Rocket historically offered a sync‑feeling API, but its modern versions rely on async under the hood and integrate with Tokio and hyper for HTTP transport.[14][15]

To establish authority, this survey draws on several types of sources. First, **maintainer documentation and ecosystem overviews** from Tokio, smol, and major web frameworks are authoritative regarding runtime assumptions, supported platforms, and intended usage patterns, captured here via independent write‑ups and documentation summaries.[1][2][3][4][5][7][13][14][15][16][17][20] Second, **independent comparisons and deep‑dive blog posts** from recognized Rust practitioners and technical writers provide analysis of runtime performance, tradeoffs, and ecosystem trends; these sources explicitly compare Tokio, async‑std, smol, glommio, and monoio in 2025–2026, and they discuss the discontinuation of async‑std and the dominance of Tokio with reference to crates.io dependency graphs.[1][2][3][4][5][7][8][9] Third, **practice evidence from well‑regarded projects** demonstrates what mainstream Rust users actually choose: hyper’s documentation states that it is built on Tokio for async I/O; Warp’s description emphasizes its use of hyper and Tokio; Actix‑web’s runtime module explicitly notes that it runs atop Tokio and provides re‑exports; Axum’s README shows its hyper/Tokio foundations and its use in production‑grade services; SeaORM’s example repository uses Axum with Tokio as the runtime for web services.[13][15][16][17][20] These projects are well regarded due to their adoption counts, frequent citations in tutorials and guides, and positions as foundational crates in the Rust web ecosystem.[4][9][13][15][16][17][20] Finally, **state‑of‑async surveys** and educational pieces provide the general guidance that domain logic should often remain synchronous, while async is used at boundaries for I/O and external services, which informs how we interpret the template’s requirements.[6][10]

Practice evidence shows that nearly all mainstream Rust web services in 2026 adopt **async runtimes**, almost always Tokio, and shape their handler signatures as `async fn` returning futures that are executed on Tokio’s multi‑threaded executor.[4][5][7][13][15][16][17][20] Axum, Warp, and Actix‑web all require a runtime and either depend directly on Tokio or provide compatibility layers that run on Tokio under the hood.[13][15][16][17] At the same time, synchronous HTTP clients and servers remain in use where ergonomics and minimal dependencies matter more than scalability: crates like `reqwest::blocking` and tiny_http are chosen for small CLIs and microservices that do not require high concurrency, and for environments where keeping the dependency graph small is a priority.[11][12] However, when projects combine a CLI and a web service and intend to share a core library between them, the evidence shows a strong tendency toward **async cores**, a single runtime choice, and consistent asynchronous APIs; examples include service frameworks whose CLI tools reuse the same async client library that the web service uses, and ORMs like SeaORM that offer async methods to be consumed both by background tasks and HTTP handlers.[4][7][20]

From this landscape and practice evidence, the shortlist of candidates for this decision emerges. For a **sync boundary**, the candidates are synchronous HTTP client crates such as `reqwest::blocking` and ureq, and synchronous web server crates such as tiny_http, possibly wrapped by thin routing libraries.[11][12] For an **async boundary**, the runtime candidates are primarily Tokio and smol, with glommio and monoio as specialized options unlikely to fit the portability and template use case, and async‑std is excluded as discontinued.[5][7][8][9] On the HTTP client side, async `reqwest` atop hyper and Tokio is the dominant choice, with some lower‑level options such as using hyper directly for advanced needs.[11][15] On the web framework side, Axum and Actix‑web stand out as well‑adopted, Tokio‑centric choices for RESTful services; Warp is a composable, filter‑based alternative slightly more opinionated than Axum, while Rocket is a full‑stack framework whose adoption is significant but whose design is less modular than Axum’s.[13][14][15][16][17][20] The bundle recommended later is drawn from these established standards, evaluated against the CLI + library + web service template rather than against abstract notions of “fastest runtime” or personal familiarity.

## Design principles and execution model

### Principles and implementation

The shared requirement that governs this decision comes from the owner’s research mandate and the recorded context of the Python and TypeScript ports. The mandate requires identifying the **shared engineering principle**, the **level at which agreement is required**, and **observable acceptance criteria**, and it explicitly states that agreement, familiarity, or maximum benchmark throughput alone cannot select a design.[Context] In this case, the principle is not “Rust must be async because TypeScript is” or “Rust should be sync because Python is,” but rather that **the driven‑I/O boundary between the CLI, library, and web service should present a consistent execution model that is idiomatic in Rust, aligns with mainstream practice, and minimizes friction for template consumers extending either side.**[4][6][9] The level at which agreement is required is architectural and pattern‑level: whether the template is sync‑first or async‑first at the boundary, which runtime is treated as a standard, and how HTTP I/O is integrated; individual library choices can vary as long as they conform to that pattern. Acceptance criteria include: avoiding divergent execution models between CLI and web service; meeting the owner’s MSRV and license policies; ensuring compatibility with `ubuntu-latest` and `macos-latest` CI targets; and providing an architecture that is readily understood and extended by Rust developers familiar with modern practice.[Context][4][6][8][9]

The Python and TypeScript precedents illustrate two contrasting architectural patterns. The Python port uses a **synchronous core** with the `requests` library performing blocking HTTP calls, and it bridges into FastAPI’s async web layer by running its sync handlers in FastAPI’s threadpool; FastAPI supports synchronous handlers by offloading them to threads, preserving a sync boundary in the core while exposing an async interface to the HTTP server.[Context] The TypeScript port, in contrast, is **async end‑to‑end**, with the CLI entry, library functions, and HTTP calls all built on Promises and the JavaScript engine’s event loop, and no explicit choice of runtime because the event loop is part of the host platform.[Context] Rust occupies a third position: it has a synchronous standard library like Python, but its async model is explicit and runtime‑driven, closer to TypeScript’s Promises in usage but with a choice of executor rather than a built‑in event loop.[4][6][10] This raises a key design question: should Rust mimic Python’s pattern, using sync HTTP libraries and threadpools or `spawn_blocking` to bridge into async web frameworks, or should it adopt an async boundary similar in spirit to TypeScript’s, with a single runtime driving both CLI and web service I/O?

Authoritative guidance on Rust async architecture suggests a nuanced principle: keep **domain logic synchronous** where possible and apply async only to I/O and external services; avoid mixing blocking I/O within async contexts; and choose a single runtime at the application layer, using runtime‑agnostic futures at the library layer for compatibility.[1][4][6] One widely cited analysis of async Rust emphasizes that async/await is a compile‑time transformation, not a runtime, and that futures and executors are separable: you can keep core business logic synchronous, encapsulate async I/O behind well‑defined interfaces, and choose Tokio or smol as an application‑level executor depending on your use case.[4][6][10] Crucially, multiple sources recommend that in 2026 **Tokio is the default choice unless there is a strong reason to avoid it**, due to its ecosystem dominance and production maturity, while smol and glommio are recommended only for specific constraints such as minimal binary size, embedded environments, or maximum I/O throughput on Linux.[2][3][4][5][7][8][9] These principles directly inform the execution model choice: the question is not whether all core logic must become async, but whether the I/O boundary shared by CLI and web will be async or sync, and which runtime will provide the executor for that boundary.

From an architectural standpoint, three alternatives need to be compared before selecting a library stack. The first alternative is a **sync‑first design** in which the CLI and library expose blocking functions, use synchronous HTTP clients such as `reqwest::blocking` or ureq, and, if an async web framework is adopted, bridge into it by running sync handlers in a threadpool or using runtime facilities like `spawn_blocking` to avoid blocking the executor.[11][12][13][14][16] This mirrors Python’s pattern with FastAPI: the core remains sync, and the web layer handles bridging.[Context] The second alternative is an **async‑at‑edges design** where the CLI entry point is `async fn main` wrapped in `#[tokio::main]` (or similar), HTTP‑touching functions in the core are async, and the web framework directly consumes async handlers, but domain logic inside the library remains synchronous and is invoked from async contexts via thin adapter methods; this is roughly analogous to TypeScript’s Promise‑based layering, but with explicit separation of domain and I/O code.[4][6][13][15][17][20] The third alternative is a **mixed design** where the CLI remains sync (blocking on a runtime via `block_on` or similar), while the web layer is fully async; the core exposes both sync and async variants of its I/O functions, or uses sync internally and wraps them in async shims for web usage.[6][11] Each alternative must be judged against the template’s goals: a single public execution model, ergonomic extension by consumers, compatibility with mainstream web frameworks, and respect for MSRV and portability constraints.

Evaluating these alternatives against practice evidence, the **sync‑first design** faces a significant friction in Rust. Major web frameworks such as Axum, Warp, and Actix‑web are async frameworks whose core abstractions—route handlers, middleware, and services—are expressed as `async fn` functions returning futures, and their APIs assume an async runtime driving non‑blocking I/O.[13][15][16][17] While some frameworks can wrap sync handlers in threads, this is not a first‑class pattern and often requires explicit use of `tokio::task::spawn_blocking` or similar mechanisms to avoid blocking the executor, which comes with additional complexity and potential performance pitfalls if overused.[4][6][16] Synchronous web frameworks like tiny_http exist, but they are deliberately low‑level, leaving routing, middleware, and application concerns to the caller, and they are not widely used as the default choice for RESTful services due to their lack of higher‑level ergonomics and integration with common crates such as Axum or Actix‑web.[12][13][15] This makes it difficult to build an optional web layer that is idiomatic and well‑integrated while remaining sync end‑to‑end; the pattern would be closer to a niche design than to mainstream Rust practice, and template consumers extending the web service would need to learn an atypical stack.

The **async‑at‑edges design**, by contrast, lines up closely with mainstream guidance and practice. Rust training materials and async surveys emphasize that the primary motivation for async is high‑concurrency I/O workloads—HTTP servers, databases, message queues—and they treat async Rust as the standard approach for such workloads.[6][10] Tokio‑based web frameworks expect async handlers and integrate deeply with other async crates, including database clients, message brokers, and HTTP clients such as reqwest.[4][13][15][16][17][20] In terms of CLI ergonomics, many modern Rust applications use an async runtime at their entry point via attributes like `#[tokio::main]`, even when the CLI performs only one or two HTTP calls per invocation, because this simplifies reuse of async clients and avoids forcing synchronous wrappers that would require separate APIs.[4][7][10] At the same time, domain logic can remain synchronous and testable independently; only the I/O boundary is async, which respects the guidance to keep domain code synchronous where possible.[6] This offers a coherent execution model across CLI and web service, uses established standards (Tokio, async reqwest, Axum), and provides template users with familiar patterns for extension.

The **mixed design** that retains a sync CLI while using an async web service is technically possible: the CLI can call into async library functions by blocking on a runtime using `tokio::runtime::Runtime::block_on` or by using `smol::block_on` in the smol ecosystem.[1][2][4][6] Some CLI templates and examples adopt this pattern to keep `fn main` synchronous while still reusing async clients underneath.[6][10] However, this approach introduces dual execution models: CLI consumers see synchronous APIs, while web consumers see async ones; template users adding new commands must decide whether to write sync or async wrappers; and the core library may need to offer both sync and async variants of its I/O functions or rely on `block_on`, which can be surprising and lead to accidental blocking inside async contexts if misused.[4][6] Given the owner’s mandate that agreement must be at the architectural pattern level and that divergence in execution models should be avoided, this mixed approach appears less aligned with the shared principle than an async boundary consistent across CLI and web.

Synthesizing these considerations, the shared requirement is thus: **`rs-launch-blueprint` should adopt a single, async I/O execution model at the driven boundary shared by the CLI and web service, using an established async runtime (Tokio) and HTTP client (async `reqwest`) that align with mainstream Rust web frameworks, while preserving synchronous domain logic behind ports‑and‑adapters seams and keeping the overall template ergonomic for CLI‑first usage.**[1][4][6][10][13][15][17][20] Observable acceptance criteria include: a CLI entry that can be written ergonomically with async; web handlers that are idiomatic in Axum or Actix‑web; HTTP transport abstractions that can be injected per R01’s seams; MSRV and license compliance; and the ability to compile and run on both Ubuntu and macOS using the same runtime stack.[Context][4][8][9][13][15][16][17][20]

Under this section, there is also a **baseline review** mandated when challenging an inherited item. The ledger notes F022 (`RUST-ONLY`) with verdict `RUST-ONLY` and origin “none,” indicating no prior decision on a pluggable async executor and treating runtime selection as moot unless F016 resolves async.[Context] The decision here necessarily challenges that implicit baseline by selecting a runtime and execution model. The appropriate record is:

> **BASELINE-REVIEW: F022 — async runtime selection policy — proposed change: treat Tokio as the default async runtime for application‑level I/O in `rs-launch-blueprint`, with runtime‑agnostic futures at the library seam where appropriate — evidence: ecosystem consolidation around Tokio, async‑std discontinuation, mainstream frameworks’ reliance on Tokio, and guidance recommending Tokio as default unless strong constraints favor alternatives.**[1][2][4][5][7][8][9][13][15][16][17]

This review makes runtime selection an explicit part of the Rust‑only ledger rather than a moot parameter, while respecting the owner’s requirement that such changes be reported rather than silently applied.

## Concrete recommendation and stack overview

### Recommendation

The recommended execution model for `rs-launch-blueprint` is that the **driven‑I/O boundary be async end‑to‑end**, in the sense that the CLI entry point, core library functions that perform HTTP I/O, and web service request handlers all expose asynchronous APIs and are executed on a shared async runtime. Specifically, the bundle stack is:

**Stack name:** `rs-launch-async-tokio-http`

**Stack members:** Tokio as the async runtime; async `reqwest` as the HTTP client; Axum as the reference web framework for the optional web service; hyper as the underlying HTTP implementation (pulled transitively by reqwest and Axum), treated as part of the Axum and reqwest stacks rather than a direct template dependency; and a pattern of synchronous domain logic encapsulated behind ports‑and‑adapters seams that present async methods at the outer boundary.[1][4][6][10][13][15][17][20]

Under this stack, the CLI’s `main` function is written as an `async fn` annotated with `#[tokio::main]`, which initializes Tokio’s multi‑threaded executor (or current‑thread variant if desired) and executes the async logic for parsing arguments, invoking core library methods, and performing HTTP calls via async reqwest.[1][4][5][7][9][10][11] The library crate exposes async functions for I/O‑touching operations—e.g. fetching project data from a remote API, creating resources, and performing other HTTP interactions—and synchronous functions or methods for pure domain operations that do not depend on I/O.[6][10] The optional web service feature uses Axum to define async request handlers that call into the same library async functions, relying on Axum’s integration with hyper and Tokio for routing, HTTP protocol handling, and concurrency.[13][15][17][20] Template consumers extending the CLI add new commands by writing async functions that call these library methods; template consumers extending the web service add new routes whose handlers are also async and reuse the same library APIs.

This stack is chosen over a sync‑first alternative for several reasons. First, it **aligns with mainstream Rust web practice**: Axum, Warp, and Actix‑web all expect async runtimes; hyper and reqwest’s async modes are built on Tokio; and ecosystem guidance treats Tokio as the standard runtime for async Rust in production in 2026.[1][2][3][4][5][7][8][9][13][15][16][17][20] Second, it **avoids awkward bridging patterns** between sync core and async web frameworks, which would require marking handlers as blocking, offloading them to threadpools, and carefully avoiding blocking inside async contexts; instead, the same async APIs serve both CLI and web layers, and synchronous domain logic is called from async contexts as needed.[6][13][15][16][17] Third, it maintains **portability and MSRV compatibility**: Tokio, reqwest, and Axum support Linux and macOS and are licensed under MIT or Apache‑2.0, and their MSRVs are within modern stable Rust ranges, consistent with the owner’s policy of “stable minus two minor versions.”[4][8][9][13][15][17][20] Fourth, the stack’s **binary size and compile‑time cost are acceptable** for a template, especially given that the optional web feature is gated behind a Cargo feature and that common CLI invocations involve only a single HTTP round‑trip; while Tokio adds more dependencies and code than smol or sync alternatives, independent benchmarks and analyses show that Tokios’s overhead is moderate and that smol’s performance advantage appears only in highly specialized pure I/O scenarios.[1][2][3][5][7][8]

Within this stack, each member must still pass fitness gates and be evaluated individually. The subsequent sections treat Tokio, async `reqwest`, and Axum as members, analyze their landscapes, principles, dominant choices, qualified shortlists, and tradeoffs, and confirm their fit for this template. Together, they constitute the **bundle** that R05 registers as the sync/async execution decision: it is not merely an abstract model, but a named set of crates and patterns that template code will adopt.

## Bundle members: detailed analysis

### Members

#### Tokio runtime

##### Landscape

Tokio sits at the center of Rust’s async ecosystem in 2026. It is an async runtime crate that provides a task scheduler, I/O drivers, timers, synchronization primitives, and utilities for building asynchronous applications, and it has become the **industry standard runtime** in the Rust ecosystem.[1][2][3][4][5][7][8][9] Unlike the Rust standard library, which offers blocking I/O, Tokio offers non‑blocking abstractions for sockets, filesystem operations, process management, and timing, all built on top of platform‑specific event mechanisms such as epoll on Linux, kqueue on macOS, and IOCP on Windows.[1][4][5][7] Its architecture is that of a multi‑threaded work‑stealing scheduler: each worker thread has a local task queue and can steal work from other queues when idle, while a global reactor drives I/O readiness events; Tokio also offers a current‑thread scheduler for single‑threaded use cases, useful in contexts such as WebAssembly or embedding.[1][4][5][7][9]

Authoritative sources on Tokio’s design and ecosystem role include maintainer documentation and independent runtime comparisons. Deep‑dive articles on Rust async runtimes describe Tokio as the “battle‑tested, most ecosystem support” option and note that it has become the **production standard** for Rust async programming.[3][4] Independent runtime comparisons conducted in 2026 state explicitly that “Tokio dominates—in 2026” and that most async crates, including `reqwest`, `sqlx`, Axum, and Tonic, require or integrate with Tokio.[2][4][9] Benchmarks comparing Tokio, async‑std, and smol show that Tokio’s multi‑threaded scheduler yields excellent throughput and low p99 latency for typical web workloads, with memory usage moderate relative to its rich feature set.[1][2][3][5][7] For example, one comparison reports that Tokio achieves around 1.2 million requests per second with p99 latency of 4.2 ms and memory usage of 85 MB on a 128‑core AMD EPYC machine, outperforming async‑std and approaching glommio’s more specialized io_uring‑based throughput.[2] Another comparison shows Tokio’s multi‑threaded echo server hitting 120,000 QPS with low median latency and reasonable memory per connection, only slightly behind smol’s ultra‑lightweight design.[1]

In practice evidence, Tokio is used by a large number of well‑regarded projects. hyper, the foundational async HTTP library for Rust, states that its async I/O runs entirely on Tokio, and that HTTP/2 framing is delegated to a separate `h2` crate, with request and response types handled by the `http` crate.[15] Warp is built on hyper and Tokio, and its documentation emphasizes that it relies on Tokio for async/await ergonomics and hyper for protocol handling.[13] Axum is an HTTP routing and request handling library that focuses on ergonomics and modularity, and it is built on hyper and Tokio; the Axum ecosystem description lists hyper and Tokio integration as key features.[15][17] Actix‑web, while built around its own actor system, explicitly runs on Tokio and provides re‑exports of Tokio types via `actix_web::rt`; its documentation notes that each server worker uses a single‑threaded runtime, but users can run Actix‑web under `#[tokio::main]` if they need Tokio’s work‑stealing functionality alongside Actix‑web.[16] These projects are widely cited in Rust web development tutorials and are recognized as well‑regarded frameworks due to their adoption, maintainer standing, and community references.[4][9][13][15][16][17][20]

Tokio also appears in ecosystem metrics: independent guides note that as of 2026, Tokio has on the order of tens of thousands of dependent crates and hundreds of millions of downloads per month, reflecting its central position.[4][8][9] A Japanese ecosystem article highlights that after the discontinuation of async‑std in March 2025, Rust’s async runtime landscape clearly became “Tokio one‑strong,” with crates.io dependency data showing more than twenty thousand crates depending on Tokio.[8] The same article notes that Tokio’s latest release as of March 2026 was v1.50, with an LTS branch 1.47.x supported through September 2026, illustrating active maintenance and long‑term support commitments.[8] Several runtime comparisons emphasize that most production crates require Tokio and that unless one has a specific reason to avoid it, Tokio should be used.[2][3][4][7][9]

Given this landscape, Tokio clearly occupies the **established industry standard** bin for async runtimes in Rust, with smol and glommio as up‑and‑comer or specialized options, and async‑std demoted to legacy status due to its discontinuation.[2][4][5][7][8][9]

##### Principles and implementation

Tokio’s implementation embodies several principles that align with the needs of `rs-launch-blueprint`. First, it is designed as a **general‑purpose async runtime for networking and I/O**, offering both high performance and a rich ecosystem, with explicit support for multi‑threaded parallelism through its work‑stealing scheduler.[1][2][4][5][7] This makes it suitable for web services that must handle multiple concurrent HTTP connections, background tasks, and timers, even if the initial template’s workload is modest. Second, Tokio is built with **portability and robustness** in mind: it supports Linux, macOS, and Windows, using appropriate system primitives (epoll, kqueue, IOCP), and it maintains stable APIs through its 1.x series, with deprecation and long‑term support policies consistent with production use.[4][5][8][9][15][16] Third, Tokio’s design acknowledges the need to keep domain logic synchronous and discourages blocking I/O inside async contexts, providing utilities such as `spawn_blocking` to isolate blocking work when necessary.[4][6] This aligns with the principle that `rs-launch-blueprint` should keep its domain logic synchronous while exposing async I/O at the boundary.

In terms of essential behaviors and acceptance criteria, Tokio must provide: reliable scheduling of async tasks; non‑blocking I/O primitives for HTTP, DNS, and filesystem operations; integration with higher‑level crates such as hyper, reqwest, Axum, and Actix‑web; and a straightforward entry point mechanism such as `#[tokio::main]` that can be applied to CLI main functions.[1][4][13][15][16][17][20] Observable behaviors include the ability to run the template on both Ubuntu and macOS, handling multiple concurrent HTTP requests in the web service without blocking, and performing single HTTP round‑trips in CLI invocations with acceptable latency and resource usage.[1][2][5][6][10][13][15][17][20]

Tokio also supports the architectural pattern recommended by several sources: **choose one runtime at the application layer, use futures abstractions at the library layer for compatibility, and avoid mixing multiple runtimes in the same application.**[1][4] Since most async crates in the ecosystem either require Tokio or provide Tokio integration, choosing Tokio as the runtime for `rs-launch-blueprint` ensures maximal compatibility with future extensions, including databases, message queues, and other services that template users may add.[3][4][5][7][9][13][15][16][17][20] For example, if template consumers later decide to integrate with `sqlx` for database access or `tonic` for gRPC, they will find that those crates already provide Tokio‑based async APIs.[4][7][15][20] This reduces future friction and aligns with the owner’s principle that agreement must be at the architectural level, not merely at the initial feature set.

##### Dominant choice

Within the async runtime category, Tokio is the **dominant choice** for general Rust applications, especially those involving web services, and this dominance is both ecosystem‑driven and architecturally justified.[1][2][3][4][5][7][8][9] Independent comparisons explicitly recommend starting with Tokio for most projects and note that ecosystem compatibility alone justifies it.[2][3][4] Guides that compare Tokio, async‑std, and smol state that “unless you have a specific reason to avoid Tokio, use Tokio,” citing its stability, download counts, and integration with key crates such as Axum, reqwest, and sqlx.[4][7][9] Benchmarks show that Tokio’s performance is excellent for typical web workloads, with throughput and latency within a few percent of smol and glommio in many scenarios, and sometimes surpassing them under complex workloads due to its sophisticated scheduler.[1][2][3][5][7]

For `rs-launch-blueprint`, which is a CLI + library + web service template, this dominance matters because **being on Tokio simplifies nearly every downstream integration**: whichever web framework is chosen, whichever HTTP client is used, and whichever future extension is considered, the likelihood that it supports Tokio is high.[4][5][7][9][13][15][16][17][20] A sync execution model, in contrast, would isolate the template from this ecosystem and require bridging layers whenever an async crate is introduced, increasing complexity and reducing alignment with mainstream practice. smol and glommio, while interesting, are not dominant for general applications; smol is more oriented toward library authors who wish to avoid forcing a runtime on users, and glommio is specialized for Linux‑only, maximum throughput workloads such as storage engines and proxies.[2][5][7][8]

##### Qualified shortlist

The qualified shortlist for async runtimes includes **Tokio** and **smol**, with **glommio** and **monoio** considered but generally excluded for this template due to portability and specialization constraints.[1][2][4][5][7][8] Tokio is qualified by its ecosystem dominance, portability, performance, and compatibility with key crates.[2][3][4][5][7][8][9][13][15][16][17][20] smol is qualified by its minimalism, runtime‑agnostic design at the library level, and smaller binary and compile‑time footprint, making it attractive for certain CLI‑only projects or embedded contexts.[1][2][4][5][7][8] glommio and monoio are qualified only for Linux‑only, high‑I/O throughput scenarios; while they offer impressive benchmarks for particular workloads, they do not align with the template’s portability requirements and broad use case across CLI and web service on Linux and macOS.[2][5][7][8]

##### Excluded by gate

**async‑std** is excluded by gate due to its discontinuation and maintenance status. Multiple sources report that async‑std was officially discontinued in March 2025, with the maintainers recommending migration to smol or Tokio.[5][7][8][9] Its README now carries a warning that the project is discontinued, and ecosystem guides treat it as legacy only, advising new projects not to adopt it.[8][9] This fails the maintenance fitness gate: using a discontinued crate would expose the template to unpatched issues, lack of support for new Rust features, and potential incompatibilities with modern dependencies. Additionally, async‑std’s architectural overlap with smol—sharing underlying executor components while maintaining separate implementations—makes smol a strictly better choice in the same design space.[5][7][8]

Similarly, **glommio** and **monoio** are excluded by gate for this template, not because they are flawed but because they do not satisfy the portability and simplicity requirements. They are Linux‑only runtimes built on io_uring, and while they excel in specific I/O‑bound benchmarks, they are not suited for a template that must run on both Ubuntu and macOS and serve a general audience.[2][5][7][8] Using them would violate the OS matrix constraint and complicate the template’s CI setup.

##### Up-and-comers

Smol, glommio, and monoio are the key up‑and‑comers. Smol’s second major version emphasizes a runtime‑agnostic design for library authors, with composite building blocks such as `polling`, `async-io`, and `async-executor` allowing fine‑grained composition.[1][2][4][5][7][8] Articles highlight smol’s small code size—on the order of 1,000–1,500 lines for the executor—and its minimal dependencies, making it attractive for binary size‑sensitive applications.[1][4][5][7][8] Benchmarks show that smol can outperform Tokio in pure I/O and timer scenarios, with lower memory usage and slightly better latencies in certain microbenchmarks, although the differences are small for typical web workloads.[1][2][3][5][7] glommio and monoio leverage io_uring to reduce syscalls and increase throughput; runtime comparisons note that glommio can reach 1.8 million requests per second with p99 latency around 1.2 ms in specific scenarios, at the cost of higher memory per thread and Linux‑only support.[2][5][7][8] These runtimes are important to acknowledge but are not suitable as the default for `rs-launch-blueprint`.

##### Fit for this template

For a CLI‑first template with an optional web service, Tokio’s fit is strong. Its default configuration provides a multi‑threaded executor that handles both CLI and web workloads well, and its current‑thread mode allows minimal overhead for CLIs that perform only single HTTP round‑trips and do not require multi‑threaded scheduling.[1][4][5][7][9] While Tokio introduces more dependencies and larger binary size than smol or sync alternatives, the template’s use of Cargo features to gate the web service ensures that CLI‑only consumers can choose a configuration that disables web features, reducing the dependency and binary footprint for those use cases.[4][5][7][8][9] The presence of `#[tokio::main]` in the CLI entry point is an ergonomic cost but is minor in practice; Rust developers familiar with async Rust are accustomed to such entry points, and even novices can follow documentation that explains the attribute’s role.[4][6][10] More importantly, Tokio’s integration with Axum, reqwest, and other key crates enables a coherent async stack for both CLI and web service, which better serves the template’s dual‑role nature than a sync‑only design.

##### Recommendation

Tokio is the **recommended async runtime** for `rs-launch-blueprint`. The template should depend on Tokio 1.x (e.g. around v1.50 or later, consistent with active support in 2026), configure it with appropriate features for networking and timing, and use `#[tokio::main]` for the CLI entry point.[4][8][9][13][15][16][17] Within the library and web service, async functions should assume Tokio as the executor and use its primitives indirectly via higher‑level crates (hyper, reqwest, Axum) rather than directly in most cases. smol is retained as a **runner‑up** consideration for scenarios where template consumers need a runtime‑agnostic library design or extremely small binaries, but the default stack for this template is Tokio.

##### Ranked runner-up

The ranked runner‑up is **smol**. For a hypothetical variant of `rs-launch-blueprint` targeting embedded systems, resource‑constrained devices, or environments where binary size and compile time are critical, smol’s minimalist design and smaller dependency graph could justify its use.[1][2][4][5][7][8] Smol’s single‑threaded default executor and composable building blocks make it attractive for library authors who wish to stay runtime‑agnostic, and its performance is competitive with Tokio in many scenarios.[1][2][3][5][7] However, smol lacks the breadth of ecosystem integrations that Tokio enjoys; many web frameworks and async crates either require Tokio or offer Tokio‑specific features, making smol a less suitable default for a template that must cover both CLI and web service use cases in the mainstream Rust ecosystem.[4][5][7][9]

##### Tradeoffs

The primary tradeoff in choosing Tokio over smol or a sync design is the **increase in binary size, dependency count, and compile time**. Runtime comparisons note that Tokio’s codebase is significantly larger than smol’s, with tens of thousands of lines of code and a correspondingly larger compile‑time footprint, whereas smol’s executor is on the order of 1,000–1,500 lines.[1][4][7][8] Benchmarks and qualitative assessments suggest that Tokio’s compile times are longer than smol’s and that its binary size is moderate rather than minimal, though both are acceptable for typical web services and CLIs.[1][3][4][5][7][8] Tokio’s work‑stealing scheduler also introduces some overhead under contention, whereas smol’s single‑threaded design has lower context switch costs.[1][5] On the other hand, Tokio provides a more refined scheduler for complex multi‑threaded scenarios, greater ecosystem compatibility, and richer feature sets, including built‑in DNS and process management utilities.[1][4][5][7][15]

From an ergonomic perspective, using Tokio requires the CLI entry point to be async, either via `#[tokio::main]` or manual runtime initialization, which differs from purely sync CLI templates that rely only on `fn main` and blocking I/O.[6][10] This can be seen as a minor inconvenience for template consumers, but it is offset by the clarity and consistency of async APIs across CLI and web service. The alternative—keeping the CLI sync and blocking on an async runtime—would complicate the core library’s API and risk confusing users about when and how to use async functions.[4][6] Thus, the tradeoff favors Tokio for this template.

##### Parameters

Tokio’s parameters relevant to this decision include its runtime configuration (multi‑threaded vs current‑thread), feature set (I/O, time, macros), MSRV, and platform support. For `rs-launch-blueprint`, the template should configure Tokio with a **multi‑threaded work‑stealing scheduler** for the web service, ensuring concurrency across HTTP connections, and may choose the current‑thread runtime for the CLI if resource usage is a concern.[1][4][5][7][9] The MSRV must match or be below the template’s MSRV policy of “stable minus two minor versions,” and Tokio’s own published MSRV should be checked via its documentation and Cargo metadata to ensure compatibility.[4][8][9] Tokio supports Linux and macOS, satisfying the CI OS matrix requirement.[4][5][8][9] The template should avoid deprecated Tokio components such as `tokio-fs`, which RustSec lists as unmaintained, and instead use maintained modules and crates for filesystem operations.[18]

In the Parameters section of the overall report, this member contributes to owned parameters such as `execution_model` and `async_runtime`, as detailed later.

##### Migration implications

For a project adopting Tokio, migration implications include changes to function signatures (from `fn` to `async fn` for I/O‑bound operations), addition of Tokio attributes to entry points, and potential refactoring to ensure that blocking operations are not performed inside async contexts. In `rs-launch-blueprint`, this means that the CLI’s `main` function must become an `async fn` annotated with `#[tokio::main]`, the core library’s HTTP‑touching functions must become async, and the web service’s request handlers must be async as well.[4][6][10][13][15][16][17][20] Existing synchronous logic can remain unchanged but must be invoked from async contexts with minimal adapters. Any previous assumption of a sync core must be revisited; however, since this template is new and Rust‑only, there is no existing Rust core to migrate, only alignment with Python and TypeScript patterns to consider.

##### Validation strategy

Tokio’s validation in this context involves building a **minimal realistic example** that uses the template’s stack and confirming that it behaves correctly under expected workloads. For example, an acceptance test would create a CLI command that performs an async HTTP GET via reqwest, a web route that performs the same GET and returns the result, and a domain function that processes data synchronously. The CLI and web service would be run concurrently on Ubuntu and macOS, verifying that Tokio handles both correctly and that latency and resource usage are acceptable for single and multiple concurrent requests.[1][2][5][6][10][11][13][15][17][20] Planned checks include: verifying Tokio’s MSRV via its `Cargo.toml` metadata; confirming its license compatibility (MIT or Apache‑2.0); checking RustSec for advisories; and ensuring that CI runs the example on both OS targets. These checks are proposed here and must be executed in the project’s CI setup; the present report relies on documentation and independent analyses rather than direct API calls to crates.io or GitHub.

##### Confidence & re-verify trigger

Confidence in Tokio as the runtime choice is high, given its ecosystem dominance, active maintenance, and alignment with mainstream practice.[1][2][3][4][5][7][8][9][13][15][16][17][20] Re‑verification triggers include: a significant shift in the Rust async ecosystem, such as widespread adoption of a new runtime; major advisories against Tokio affecting core functionality; or changes in the template’s OS matrix or MSRV that restrict Tokio’s compatibility. Additionally, if template consumers report substantial ergonomic issues with async CLI entry points, a review of the current‑thread runtime configuration or partial sync wrappers might be warranted, though such issues are unlikely given current practice.[4][6][10]

##### Sources

Key sources for Tokio’s analysis include independent runtime comparisons and ecosystem guides that detail Tokio’s architecture, performance, and ecosystem role.[1][2][3][4][5][7][8][9] Documentation from hyper, Warp, Axum, and Actix‑web confirms Tokio’s role as their async runtime.[13][15][16][17][20] RustSec’s advisory on `tokio-fs` highlights the need to avoid deprecated Tokio components.[18] General guidance on async Rust and domain logic informs the architectural principles.[6][10]

#### Async `reqwest` HTTP client

##### Landscape

`reqwest` is a widely used HTTP client crate in Rust’s ecosystem, offering both asynchronous and synchronous APIs. Its async mode builds atop hyper and Tokio, providing futures‑based methods such as `Client::get`, `Client::post`, and `Client::execute` that return futures and are executed on an async runtime; its synchronous mode is encapsulated in the `reqwest::blocking` module, which exposes similar APIs but blocks the current thread.[11][15] This duality makes `reqwest` a key candidate for both sync and async execution models, but in the context of an async boundary and Tokio runtime, its async mode is the primary focus.

Authoritative sources include `reqwest`’s own documentation and independent ecosystem descriptions. The `reqwest::blocking` docs state that the blocking `Client` will block the current thread, that it must not be executed within an async runtime (or it will panic when attempting to block), and that an async `reqwest::Client` should be used from async functions.[11] This warning underscores the need to keep blocking operations out of async contexts and supports the principle of a consistent async boundary. Independent descriptions of hyper note that hyper is the foundational HTTP implementation and that it is built on Tokio for async I/O, with separate client and server modules and a `Service` trait for handling requests.[15] Since reqwest uses hyper for its HTTP layer, it inherits hyper’s async architecture and runtime dependencies.[11][15]

Practice evidence shows that reqwest is widely adopted as the HTTP client of choice in Rust, particularly in combination with Tokio and hyper.[4][9][15] Many tutorials and examples for web services, CLIs that call HTTP APIs, and background tasks use reqwest’s async API, often with Tokio’s macros for entry points and tasks.[4][6][10][11] The crate’s popularity is reflected in the number of reverse dependencies and references in ecosystem guides; while specific download figures require calling crates.io’s API, the widespread mention of reqwest in tutorials and frameworks indicates its status as a well‑regarded project.[4][9][10][11][15]

##### Principles and implementation

Reqwest’s implementation aligns with several key principles. It provides a **high‑level, ergonomic HTTP client** for Rust, abstracting away low‑level details of hyper while offering convenient methods for building and executing requests.[11][15] Its async API uses futures and is designed to be run under an async runtime such as Tokio, with proper integration for connection pooling, TLS, redirects, and body streaming.[11][15] Its synchronous API is provided separately in `reqwest::blocking`, which deliberately does not depend on an async runtime and instead blocks the current thread for each operation.[11] This separation embodies the principle of clear boundaries: async code uses async clients and runs on an executor; sync code uses blocking clients and must not be run inside async contexts.

For `rs-launch-blueprint`, reqwest’s async API fits the recommended async execution boundary: CLI and web service code can use the same async client, passing configuration and authentication details as needed, and the core library can expose async methods that encapsulate reqwest calls while keeping domain logic synchronous.[6][10][11] Acceptance criteria include: the ability to perform HTTP requests asynchronously under Tokio; clear documentation and APIs for error handling, timeouts, and retries; and compatibility with both Ubuntu and macOS.[11][15] Reqwest’s explicit warning against using its blocking API inside async contexts also reinforces the template’s need to either commit to an async boundary or to carefully isolate blocking code if a sync design is chosen.[11]

##### Dominant choice

Within the Rust HTTP client ecosystem, reqwest is widely considered the **dominant high‑level client**, especially for projects that use Tokio and hyper.[4][9][10][11][15] While lower‑level clients and alternative crates exist, reqwest’s broad adoption, documentation, and integration with major async runtimes make it the natural choice for `rs-launch-blueprint`’s HTTP client component. Its dual async/sync design is an advantage, but in the context of an async boundary, its async API is the dominant choice.

##### Qualified shortlist

The qualified shortlist for HTTP clients includes async reqwest, `reqwest::blocking` for sync designs, and synchronous crates such as ureq and tiny_http for specialized scenarios.[11][12][15] For an async boundary, async reqwest is the clear choice; for a hypothetical sync boundary, `reqwest::blocking` or ureq could be considered. However, the template’s adoption of an async boundary tilts the shortlist toward async reqwest exclusively.

##### Excluded by gate

No specific HTTP client is excluded by maintenance gates in this analysis, though synchronous clients that rely on blocking semantics inside async contexts are effectively excluded by architectural gates when adopting an async boundary. The key warning is reqwest’s own note that blocking APIs must not be executed within an async runtime.[11]

##### Up-and-comers

Lower‑level HTTP clients and alternative crates, such as those built directly on hyper or using minimal dependencies, can be considered up‑and‑comers or specialized tools. However, none appear to challenge reqwest’s position as the dominant high‑level async HTTP client in the mainstream ecosystem.[4][9][11][15]

##### Fit for this template

For a CLI + web service template, async reqwest fits well. It provides a unified API for both CLI and web layers, allows shared configuration and authentication, and integrates seamlessly with Tokio and hyper.[11][15] Its ergonomics are suitable for template consumers, who can write async functions that perform HTTP requests and handle responses with familiar patterns such as builder methods and strongly typed bodies.[6][10][11] Using async reqwest avoids the need to maintain separate sync and async client stacks and aligns with the template’s async execution boundary.

##### Recommendation

Async reqwest is the **recommended HTTP client** for `rs-launch-blueprint`. The template should depend on reqwest’s async features, configure TLS and HTTP/2 support via its Cargo features, and expose core library methods that encapsulate reqwest calls as async functions.[11][15] Blocking APIs in `reqwest::blocking` should not be used in the template’s async contexts.

##### Ranked runner-up

For a hypothetical sync boundary variant, `reqwest::blocking` or ureq could serve as runner‑up clients, offering synchronous HTTP APIs for CLI‑only applications.[11][12] However, they are not chosen for the async boundary recommended here.

##### Tradeoffs

Using async reqwest introduces a dependency on hyper and Tokio, which increases the template’s dependency graph and binary size, similar to Tokio itself.[11][15] However, this tradeoff is acceptable given the template’s dual CLI + web nature and the benefits of using a mature, well‑supported HTTP client. The alternative—using a minimal client or writing custom HTTP code—would sacrifice ergonomics and reliability.

##### Parameters

Reqwest’s parameters include its feature set (TLS, HTTP/2, JSON support), integration with Tokio, and MSRV and license. The template should configure reqwest with features appropriate to its use case, such as JSON and TLS, and verify its MSRV and license compatibility in CI.

##### Migration implications

Adopting async reqwest requires library methods that perform HTTP to be async and requires the CLI and web service to await responses rather than receiving blocking results. This is a manageable migration implication, especially for a new template.

##### Validation strategy

Validation involves writing examples that perform HTTP GET and POST requests using async reqwest from both CLI and web service, verifying behavior on Ubuntu and macOS, and checking error handling and timeouts.[6][10][11][13][15][17][20] Planned checks include verifying reqwest’s MSRV and license.

##### Confidence & re-verify trigger

Confidence in async reqwest is high, given its widespread adoption and integration with Tokio and hyper.[4][9][10][11][15] Re‑verification would be triggered by major advisories, shifts in HTTP client preferences in the ecosystem, or changes in TLS or HTTP standards that require alternative clients.

##### Sources

Key sources include reqwest’s documentation and hyper’s ecosystem description.[11][15] General async guidance and runtime comparisons provide context for reqwest’s role.[4][6][10]

#### Axum web framework

##### Landscape

Axum is an HTTP routing and request handling library for Rust that focuses on ergonomics and modularity; it is built on hyper and Tokio and is widely used for web services in 2026.[15][17][20] Axum’s design centers on extracting typed data from requests, composing middleware, and defining async handlers that return responses, all expressed in idiomatic Rust with async/await syntax.[17] It is part of a broader ecosystem that includes hyper, tower, and other crates for HTTP and service composition.[15][17]

Authoritative sources include Axum’s README, hyper’s documentation, and example repositories such as SeaORM’s Axum example.[15][17][20] Axum’s README describes it as an HTTP routing and request handling library that focuses on ergonomics and modularity, with support for features such as path and query extraction, JSON handling, and middleware composition.[17] Hyper’s documentation notes that it is the foundational HTTP implementation for the Rust ecosystem, providing both client and server building blocks over HTTP/1.1 and HTTP/2, and that its async I/O runs entirely on Tokio, with HTTP/2 framing delegated to the `h2` crate.[15] SeaORM’s Axum example shows a practical composition of Axum, SeaORM, and Tokio in a web service, demonstrating how Axum is used in production‑grade stacks.[20]

Practice evidence shows that Axum is widely adopted and well regarded, with numerous tutorials and examples using it as the default choice for building RESTful web services in Rust.[4][9][15][17][20] Its modular design and focus on ergonomics make it particularly suitable for templates where clarity of code and ease of extension are important.

##### Principles and implementation

Axum’s implementation aligns with several key principles relevant to `rs-launch-blueprint`. It is **async‑first**, with handlers expressed as `async fn` and executed on an async runtime (Tokio) via hyper’s server APIs.[15][17] It is **modular and minimal** in the sense that it focuses on routing and request handling, leaving more complex concerns such as templating or ORM integration to other crates, which fits well with the template’s ports‑and‑adapters architecture.[17][20] It uses **strong typing** and pattern matching to extract request data, which encourages clear, safe code and aligns with Rust’s idioms.

For `rs-launch-blueprint`, Axum’s async handlers can call into the core library’s async methods that perform HTTP client operations via reqwest, and domain logic can remain synchronous inside those methods.[6][10][11][15][17][20] This respects the principle that domain logic should be synchronous while I/O is async at the boundary.

##### Dominant choice

Within Rust’s web framework ecosystem, Axum is one of the dominant choices for modern web services, alongside Warp and Actix‑web.[4][9][13][15][16][17][20] Its focus on ergonomics and modularity, combined with its minimalism relative to full‑stack frameworks like Rocket, makes it particularly suitable for a template intended to be extended by consumers.

##### Qualified shortlist

The qualified shortlist for web frameworks includes Axum, Actix‑web, Warp, and Rocket. Actix‑web is powerful and widely used but has a more complex actor model and is slightly heavier in its abstractions.[16] Warp is composable and filter‑based, built on hyper and Tokio, and is a strong alternative.[13][15] Rocket is a higher‑level framework with its own design choices.[14] For `rs-launch-blueprint`, Axum’s balance of ergonomics and modularity makes it the best fit.

##### Excluded by gate

No framework is excluded by maintenance gates here, though frameworks that do not support async or that rely on discontinued runtimes would be excluded. Axum, Actix‑web, and Warp all rely on maintained runtimes and crates.

##### Up-and-comers

Newer frameworks or higher‑level libraries built on Axum and hyper may emerge, but Axum itself is an up‑and‑comer that has already achieved mainstream status.

##### Fit for this template

Axum fits the template well by offering async handlers that integrate with Tokio, modular routing, and compatibility with ORMs and other libraries such as SeaORM.[15][17][20] Template consumers can extend the web service by adding new Axum routes and handlers that call into the core library, aligning with the async boundary model.

##### Recommendation

Axum is the **recommended web framework** for the optional web service feature of `rs-launch-blueprint`. The template should include Axum as an optional dependency under a Cargo feature and provide example routes and handlers that demonstrate integration with the core library and reqwest.[15][17][20]

##### Ranked runner-up

Warp and Actix‑web are runner‑ups, suitable for projects that prefer their specific abstractions (filter‑based routing or actor models).[13][16] However, Axum’s ergonomics and modularity make it the primary recommendation.

##### Tradeoffs

Axum’s tradeoffs include its reliance on async runtimes and hyper, which increase the dependency graph and require async handlers. For a template that already adopts an async boundary, these tradeoffs are acceptable.

##### Parameters

Axum’s parameters include versions, feature sets (WebSockets, JSON), and integration with hyper and tower. The template should configure Axum with features relevant to its routes and ensure compatibility with the chosen Tokio version.

##### Migration implications

Adopting Axum requires web handlers to be async and to follow Axum’s routing patterns. For a new template, this is simply a design choice, not a migration.

##### Validation strategy

Validation involves building an example web service with Axum, Tokio, and reqwest, running on Ubuntu and macOS, and verifying routing, request handling, and integration with the core library.[13][15][17][20]

##### Confidence & re-verify trigger

Confidence in Axum is high, given its adoption and integration with hyper and Tokio.[4][9][15][17][20] Re‑verification would be triggered by major ecosystem shifts or advisories.

##### Sources

Key sources include Axum’s README, hyper’s documentation, and SeaORM’s Axum example.[15][17][20]

## Cross‑component compatibility

### Compatibility

Proving that Tokio, async reqwest, and Axum are tested together requires examining shared adopters and example repositories. hyper’s documentation states that its async I/O runs entirely on Tokio and that it serves as the foundation for HTTP clients and servers, including reqwest’s transport layer.[15] Reqwest’s async client uses hyper for HTTP and requires an async runtime such as Tokio, aligning with hyper’s design.[11][15] Axum is built on hyper and Tokio, and its request handling and routing rely on hyper’s server and Tokio’s runtime.[15][17] SeaORM’s Axum example repository demonstrates a working composition of Axum, Tokio, and SeaORM, showing that this stack is tested and used in practice.[20] Actix‑web’s documentation, while focused on its own actors, acknowledges that it runs on Tokio and can be used under `#[tokio::main]`.\[16]

Together, these sources demonstrate that Tokio, async reqwest, and Axum are compatible and commonly used together in production stacks. For `rs-launch-blueprint`, this means that the recommended bundle stack is not speculative but reflects established combinations.

## Template parameters and ledger entries

### Parameters

For this coupling (R05), the following parameters are owned and assumed:

**Owned parameters:**

`owns execution_model = async_boundary_end_to_end`

This parameter records that the driven‑I/O boundary shared by CLI and web service uses an async execution model end‑to‑end, with `async fn` and futures at the boundary, while domain logic may remain synchronous behind ports‑and‑adapters seams.[4][6][10][13][15][17][20]

`owns async_runtime = tokio_1.x`

This parameter records that Tokio 1.x (e.g. v1.50 or later) is the chosen async runtime for the template’s application layer, with the understanding that future minor upgrades within the 1.x series may be adopted consistent with MSRV policy.[4][8][9][13][15][16][17][20]

`owns http_client = reqwest_async`

This parameter records that async reqwest is the HTTP client used at the driven boundary for both CLI and web service; the core library’s HTTP‑touching functions will use reqwest’s async APIs.[11][15]

`owns web_framework = axum_optional_feature`

This parameter records that Axum is the reference web framework for the optional web service feature, gated behind a Cargo feature and integrated with Tokio and hyper.[15][17][20]

**Assumed parameters:**

`assumes msrv_policy = stable_minus_two_minor` (owner‑provided)

`assumes rust_edition = 2024`

`assumes license_policy = MIT_OR_Apache-2.0`

`assumes target_os_matrix = ubuntu-latest, macos-latest`

These assumed parameters come from the owner’s specification and must be respected by the chosen stack.[Context][4][8][9][13][15][17][20]

There are no `CONFLICT:` lines, as the chosen async execution model and Tokio runtime fit within the existing parameters. The earlier baseline F022 is challenged via the `BASELINE-REVIEW` record rather than a parameter conflict.

## Migration implications for the template

### Migration implications

Although `rs-launch-blueprint` is a new Rust template, migration implications matter because the template must be coherent with Python and TypeScript ports and may evolve over time. Adopting an async boundary with Tokio, reqwest, and Axum implies several file‑level changes and patterns.

First, the CLI crate’s `main.rs` must define an `async fn main` annotated with `#[tokio::main]`, which initializes the Tokio runtime and drives the async execution of argument parsing and HTTP calls.[4][6][10][13][15][16][17][20] Instead of a purely synchronous `fn main`, the entry point will be async, and calls into the core library will be awaited. Template consumers extending the CLI must write async functions when adding new commands that perform I/O; pure computation‑only commands can remain synchronous but may still be called from async contexts.

Second, the core library crate must define **async functions for I/O‑touching operations** such as `async fn fetch_projects(...) -> Result<...>` and `async fn create_project(...) -> Result<...>`, which internally use async reqwest to perform HTTP calls.[6][10][11][15] Domain logic functions that perform pure computations or transformations remain synchronous and can be called from async functions without modification.[6] Ports‑and‑adapters seams defined by R01 can present async methods at the boundary while encapsulating synchronous domain logic inside.

Third, the optional web service feature must define **Axum routes and async handlers** that call into the core library’s async functions, using Tokio and hyper for concurrency and HTTP protocol handling.[13][15][17][20] For example, a route `GET /projects` would be handled by an async function that calls `fetch_projects` and returns a JSON response. Template consumers extending the web service add new routes and handlers in this style.

Fourth, any assumption of sync HTTP clients such as `reqwest::blocking` or ureq must be removed or relegated to specialized contexts where async execution is not required. Using `reqwest::blocking` inside Tokio’s runtime is explicitly warned against and must be avoided.[11] The template’s guidance and documentation must make clear that all I/O at the shared boundary is async and that blocking operations should be isolated via `spawn_blocking` only when necessary.

Finally, the template’s CI and documentation must reflect the async boundary. CI scripts must ensure that examples using Tokio, reqwest, and Axum compile and run on both Ubuntu and macOS; documentation must explain how to write async handlers and CLI commands; and patterns for testing async code must be documented, such as using Tokio’s test macros or manual runtime initialization in tests.[4][6][10][13][15][17][20]

These migration implications are manageable for a new template and align with mainstream Rust patterns.

## Validation and empirical acceptance

### Validation strategy

The empirical acceptance check for this decision must demonstrate that the chosen stack—Tokio, async reqwest, Axum—implements the shared principle and behaves as expected in realistic scenarios. The validation strategy includes several planned steps.

First, build a **minimal integrated example** within `rs-launch-blueprint` that includes a CLI command and a web route performing the same HTTP operation. For instance, define a core library function `async fn get_project(id: ProjectId) -> Result<Project>` that uses async reqwest to call an external API; create a CLI command `projects get` that invokes `get_project` and prints the result; and define an Axum route `GET /projects/:id` whose handler calls `get_project` and returns JSON.[6][10][11][13][15][17][20] Run the CLI and web service on Ubuntu and macOS under CI, verifying that both work, that latency is acceptable for single and concurrent requests, and that the behavior is consistent across CLI and web. This check demonstrates the shared async boundary and reuse of library code.

Second, perform **concurrency tests** for the web service, simulating multiple concurrent HTTP requests using tools such as `wrk` or `hey` and measuring throughput and latency. Compare results qualitatively against expectations drawn from runtime benchmarks: Tokio should handle thousands of concurrent connections with low p99 latency, and any overhead from using async reqwest and Axum should be manageable.[1][2][3][5][7][13][15][17][20] This confirms that the async stack can support realistic web workloads.

Third, verify **MSRV and platform compatibility** by building the template with the minimum supported Rust version (stable minus two minor versions) and running tests on both Ubuntu and macOS.[4][8][9] Ensure that Tokio, reqwest, and Axum declare MSRVs compatible with this policy and that no platform‑specific issues occur.

Fourth, check **license and security**: confirm that Tokio, reqwest, Axum, hyper, and their dependencies are licensed under MIT or Apache‑2.0; and review RustSec advisories for relevant crates, avoiding deprecated or unmaintained components such as `tokio-fs`.[18] This ensures compliance with the owner’s license policy and security fitness gate.

Fifth, validate **API ergonomics** by writing example extensions to the CLI and web service, demonstrating how template consumers can add new commands and routes using the async boundary. Gather feedback from internal or early adopters on the ease of use and clarity of the async model.

These checks are proposed and must be implemented in CI and documentation. The present report outlines them but does not execute them; their results will serve as empirical acceptance of the decision.

## Confidence and re‑verification

### Confidence & re-verify trigger

Confidence in the chosen async boundary and stack is high, based on ecosystem consolidation around Tokio, the dominance of async reqwest and Axum in web stacks, and guidance from authoritative sources recommending Tokio as the default runtime.[1][2][3][4][5][7][8][9][11][13][15][16][17][20] The decision aligns with mainstream practice, satisfies the template’s dual CLI + web nature, and respects the owner’s principles about architectural agreement and observable acceptance criteria.[Context][4][6][10]

Re‑verification triggers include:

1. **Ecosystem shifts**: if a new runtime or framework gains widespread adoption and challenges Tokio’s dominance—for example, a cross‑platform io_uring‑based runtime—then the template’s stack may need review.[2][5][7][8]
2. **Maintenance changes**: if Tokio, reqwest, or Axum slow down their maintenance, accumulate unaddressed advisories, or change their MSRVs in ways incompatible with the template’s policy, reevaluation is needed.[4][8][9][18]
3. **Performance or ergonomics issues**: if template consumers report significant performance problems (e.g. overhead for single‑request CLI invocations) or ergonomic pain with async entry points, alternative patterns such as current‑thread runtimes, mixed sync/async APIs, or partial sync wrappers may be considered.[4][6][10]
4. **Owner parameter changes**: changes to the target OS matrix, MSRV policy, or license constraints may necessitate revisiting runtime and framework choices.

Periodic re‑verification, aligned with major Rust releases or ecosystem surveys, would ensure that the bundle remains appropriate.

## Source overview and citation practice

### Sources

This report draws on a diverse set of sources to establish authority and practice evidence. Runtime comparisons and deep‑dive articles provide detailed analyses of Tokio, async‑std, smol, glommio, and monoio, including performance benchmarks, architectural descriptions, and ecosystem trends.[1][2][3][4][5][7][8] Ecosystem guides in multiple languages highlight the discontinuation of async‑std, the consolidation around Tokio, and the role of smol and monoio as alternatives.[5][7][8][9] Documentation for hyper, Warp, Axum, Actix‑web, and reqwest confirm their reliance on Tokio and hyper and describe their APIs and design philosophies.[11][13][14][15][16][17][20] RustSec advisories such as the one for `tokio-fs` inform maintenance and security considerations.[18] General guidance on async Rust and domain logic provides architectural principles for separating domain logic from I/O and choosing runtimes appropriately.[6][10] Synchronous HTTP crates such as tiny_http demonstrate sync‑first designs and thread‑per‑connection patterns.[12]

All claims in this report refer to these sources via inline citations, and any numerical benchmarks or version references are drawn from those sources rather than invented. Crate‑level metrics such as downloads, stars, and MSRV are acknowledged as important but are treated as planned checks for CI integration rather than exhaustively enumerated here; the report instead relies on the qualitative assessments of authoritative guides and practice evidence. This is consistent with the owner’s requirement that empirical acceptance checks be specified and that patterns be evaluated against both guidance and production practice.

## Conclusion

The choice between a synchronous and asynchronous execution model for `rs-launch-blueprint` is not a matter of copying Python or TypeScript’s patterns but of respecting Rust’s own ecosystem and architectural guidance. Rust’s standard library is synchronous, but its async model is explicit and runtime‑driven, and the ecosystem in 2026 has consolidated around Tokio, async reqwest, and async web frameworks such as Axum as the standard stack for networked applications.[1][2][3][4][5][7][8][9][11][13][15][16][17][20] While synchronous designs remain viable for simple CLIs, the template’s dual role as CLI and optional web service, combined with the owner’s requirement for a shared architectural principle and consistent execution model, favors an async boundary end‑to‑end.

By adopting Tokio as the async runtime, async reqwest as the HTTP client, and Axum as the reference web framework, `rs-launch-blueprint` aligns with mainstream Rust practice, avoids awkward threadpool bridges, and provides template consumers with ergonomic, well‑supported APIs for both CLI and web extension.[4][6][10][11][13][15][17][20] Domain logic remains synchronous behind ports‑and‑adapters seams, preserving testability and conceptual simplicity, while I/O at the driven boundary is async, executed on a single shared runtime. This design satisfies the owner’s MSRV, license, and OS matrix constraints, and it offers a clear path for empirical validation through integrated examples and CI checks.

The recommendation thus records a bundle decision: **async boundary end‑to‑end, Tokio runtime, async reqwest client, Axum web framework**, with explicit parameters and migration implications. It challenges the baseline F022 by making runtime selection a first‑class concern in the ledger and provides the evidence and acceptance strategy needed to treat this as a durable architectural choice.

## Sources

- [Rust Async Runtime Comparison in 2026: Tokio vs…](https://www.toolsku.com/en/blog/rust-async-runtime-comparison-2026/)
- [Rust Async Runtimes: Tokio vs async-std vs smol](https://lucaberton.com/blog/rust-async-runtimes-tokio-2026/)
- [Tokio vs async-std vs smol: Rust Async Runtime ...](https://reintech.io/blog/tokio-vs-async-std-vs-smol-rust-async-runtime-comparison-2026)
- [Rust Async Runtimes: Tokio vs async-std vs smol 2026](https://rustify.rs/articles/rust-async-runtimes-tokio-vs-async-std-2026)
- [Rust Async Runtimes Compared: tokio vs smol vs io_uring ... - MatterAI](https://www.matterai.so/guides/rust-networking-tokio-vs-async-std-vs-smol-for-async-network-programming)
- [The State of Async Rust: Runtimes](https://corrode.dev/blog/async/)
- [Lesson 8: Runtime Comparison — Tokio vs async-std vs smol vs glommio -](https://www.atharvapandey.com/post/rust/rust-runtime-comparison/)
- [async-std廃止後のRust非同期ランタイム選定：tokio・smol ...](https://qiita.com/0h-n0/items/280d275d970af0b7f451)
- [Rust Async Runtimes: Tokio, async-std, and smol for TypeScript Developers](https://rs4ts.dev/23-ecosystem/02-async-runtimes/)
- [Rust Programming Tutorial: 13 Steps Zero to CLI \[2026\] - Tech Insider](https://tech-insider.org/rust-programming-tutorial-cli-project-2026/)
- [reqwest::blocking - Rust - Docs.rs](https://docs.rs/reqwest/latest/reqwest/blocking/index.html)
- [tiny_http: A Minimal, Dependency-Light Rust HTTP Server](https://openapps.pro/packages/tiny-http)
- [Warp: Composable Rust Web Framework Built on Hyper](https://openapps.pro/packages/warp)
- [Overview - Rocket Web Framework](https://rocket.rs/guide/v0.5/overview/)
- [hyper: Low-Level HTTP/1 and HTTP/2 Library for Rust](https://openapps.pro/packages/hyper)
- [actix_web::rt - Rust - Docs.rs](https://docs.rs/actix-web/latest/actix_web/rt/index.html)
- [axum 0.8.9 - Docs.rs](https://docs.rs/crate/axum/latest/source/README.md)
- [Advisories for package 'tokio-fs'](https://rustsec.org/packages/tokio-fs.html)
- [Tealdeer User Manual](https://tealdeer-rs.github.io/tealdeer/usage.html)
- [sea-orm/examples/axum_example/src/main.rs at master](https://github.com/SeaQL/sea-orm/blob/master/examples/axum_example/src/main.rs)

## Cost

Total: $1.2196

---


## Gemini Results

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

---
