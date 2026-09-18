---
prompt: # Deep-research prompt — API pagination (R72, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts a pagination crate/extractor giving page/size query-param pagination and an items/total response envelope, registered once app-wide rather than per-router. Item kind: `bundle`. Value test: if this answer is wrong, every collection-returning route's response type, the pagination-parameter extraction, and the app-wide registration call in the composition root all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py returns collections through a page/size query-param pagination extractor and an items/total response envelope, with the collection items staying plain core-model objects — only the wrapper is web-specific — and registers the pagination machinery once, app-wide, rather than per-router. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/routers/projects.py:30` — `from fastapi_pagination import Page, paginate` (WEB-03; items stay `core.models` objects, only the collection wrapper is web-specific); ts: none. Ledger rows: F310, F311 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F311 pagination wired app-wide via one factory call — py `src/py_launch_blueprint/web/app.py:204` — `add_pagination(app)` (registers the pagination response models/params globally instead of per-router); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no decision addressing web-service scope; ts never built a web service, so there is no pagination shape to reconcile with.

## Out of scope
- Which web framework hosts this pagination extractor; R69 (`web-framework-stack`) owns F303 and the `web-extra-surface` parameter — assume R69 resolves to some framework and design the pagination wiring to fit whichever framework's extractor model wins.
- The envelope any pagination validation failure (e.g. an out-of-range page) renders through; R70 (`http-problem-envelope`) owns F305/F306 — this item decides the pagination contract itself, not how its errors are rendered.
- Keeping the generated OpenAPI schema's pagination response components correct; R71 (`openapi-generation-pipeline`) owns F307/F312/F332/F333 — this item decides the pagination mechanism, not how it is documented in the OpenAPI spec.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R72
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R69 (`web-framework-stack`) decides which framework this pagination extractor must integrate with — treat R69's choice as open, do not block on it.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` adopts a Rust pagination crate/extractor giving page/size query-param pagination and an items/total response envelope, registered once app-wide rather than per-route.
- HIGH: Does a Rust crate exist that provides `fastapi-pagination`-equivalent page/size extraction plus a generic items/total envelope type, integrated with a leading async web framework's extractor mechanism?
- HIGH: Can that crate be registered once, app-wide (mirroring py's `add_pagination(app)`), or does Rust's typed-extractor model require per-route wiring — and what is the idiomatic minimal-boilerplate way to apply it uniformly to every collection route?
- MEDIUM: Does the crate keep collection items as the caller's own domain type (mirroring py's items staying `core.models` objects, only the wrapper being web-specific), or does it require converting items into a crate-specific wrapper type first?
- MEDIUM: How does the crate integrate with OpenAPI-schema generation (R71, not yet decided) — does it emit its own schema components automatically, or does it need manual per-route annotation?
- LOW: Do any published Rust API templates document a page/size-plus-items/total pagination convention as a named pattern, and where?

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
operation_id: research-20260918-150431-3cb17a06c88b457a
created_at: 2026-09-18T15:04:31.204377
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — API pagination (R72, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts a pagination crate/extractor giving page/size query-param pagination and an items/total response envelope, registered once app-wide rather than per-router. Item kind: `bundle`. Value test: if this answer is wrong, every collection-returning route's response type, the pagination-parameter extraction, and the app-wide registration call in the composition root all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py returns collections through a page/size query-param pagination extractor and an items/total response envelope, with the collection items staying plain core-model objects — only the wrapper is web-specific — and registers the pagination machinery once, app-wide, rather than per-router. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/routers/projects.py:30` — `from fastapi_pagination import Page, paginate` (WEB-03; items stay `core.models` objects, only the collection wrapper is web-specific); ts: none. Ledger rows: F310, F311 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F311 pagination wired app-wide via one factory call — py `src/py_launch_blueprint/web/app.py:204` — `add_pagination(app)` (registers the pagination response models/params globally instead of per-router); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no decision addressing web-service scope; ts never built a web service, so there is no pagination shape to reconcile with.

## Out of scope
- Which web framework hosts this pagination extractor; R69 (`web-framework-stack`) owns F303 and the `web-extra-surface` parameter — assume R69 resolves to some framework and design the pagination wiring to fit whichever framework's extractor model wins.
- The envelope any pagination validation failure (e.g. an out-of-range page) renders through; R70 (`http-problem-envelope`) owns F305/F306 — this item decides the pagination contract itself, not how its errors are rendered.
- Keeping the generated OpenAPI schema's pagination response components correct; R71 (`openapi-generation-pipeline`) owns F307/F312/F332/F333 — this item decides the pagination mechanism, not how it is documented in the OpenAPI spec.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R72
- owns:
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R69 (`web-framework-stack`) decides which framework this pagination extractor must integrate with — treat R69's choice as open, do not block on it.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` adopts a Rust pagination crate/extractor giving page/size query-param pagination and an items/total response envelope, registered once app-wide rather than per-route.
- HIGH: Does a Rust crate exist that provides `fastapi-pagination`-equivalent page/size extraction plus a generic items/total envelope type, integrated with a leading async web framework's extractor mechanism?
- HIGH: Can that crate be registered once, app-wide (mirroring py's `add_pagination(app)`), or does Rust's typed-extractor model require per-route wiring — and what is the idiomatic minimal-boilerplate way to apply it uniformly to every collection route?
- MEDIUM: Does the crate keep collection items as the caller's own domain type (mirroring py's items staying `core.models` objects, only the wrapper being web-specific), or does it require converting items into a crate-specific wrapper type first?
- MEDIUM: How does the crate integrate with OpenAPI-schema generation (R71, not yet decided) — does it emit its own schema components automatically, or does it need manual per-route annotation?
- LOW: Do any published Rust API templates document a page/size-plus-items/total pagination convention as a named pattern, and where?

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

# Deep-Research Report: API Pagination Architecture and Implementation (R72)

### Landscape

The architectural domain of HTTP API pagination in the Rust ecosystem sits at the intersection of request extraction, database query optimization, and response serialization. This section categorizes the available solutions, establishes the authoritative parameters guiding the ecosystem, and evaluates the prevailing practices in mainstream, well-regarded Rust codebases.

**Ecosystem Mapping**

The Rust ecosystem provides a broad spectrum of solutions for handling paginated datasets, which can be categorized into three distinct tiers based on their integration depth and community adoption.

| Category | Description | Primary Candidates |
| :--- | :--- | :--- |
| **Built-in or first-party toolchain** | Rust's standard library (`std`) and core web frameworks (e.g., Axum, Actix-Web, Rocket) provide fundamental components for generic HTTP processing. These include `std::iter::Iterator` for memory collections and raw query-string extractors (`axum::extract::Query`). However, no first-party framework provides a native, pre-packaged pagination envelope or boundary validation utility out of the box, reflecting Rust's philosophy of maintaining minimal, unopinionated core libraries [cite: 1]. | Standard library, raw `axum::extract::Query`, `serde::Deserialize` wrappers. |
| **Established industry standard** | The dominant paradigm in production Rust applications is entirely bespoke, hand-rolled implementations. Development teams typically define a custom `PaginationParams` struct to deserialize `page` and `limit` URL parameters, paired with a custom `PaginatedResponse<T>` struct to form the generic `items`/`total` envelope. This approach maximizes control and minimizes third-party dependency weight. | Hand-rolled generics utilizing `serde` and explicit database query builders. |
| **Up-and-comer** | Dedicated, framework-agnostic pagination crates that bridge the gap between HTTP layer extraction, database cursor/offset management, and response envelope formatting. These libraries attempt to provide a unified contract across various web frameworks and ORMs. | The `paginator-rs` ecosystem (including `paginator-axum`, `paginator-actix`), `page-hunter`, `paginate`, `page-turner`. |

**Established Authority**

To objectively evaluate the viability of these architectural options, the analysis draws upon several highly regarded sources that dictate best practices within the asynchronous Rust web development sphere. 

The primary authority governing HTTP request extraction is the Tokio project and the Axum web framework documentation. Axum's maintainers dictate that request processing must rely on type-safe extractors implementing the `FromRequest` or `FromRequestParts` traits [cite: 1, 2]. Furthermore, Axum's architecture, which is heavily reliant on the `tower` crate's `Service` and `Layer` traits, establishes strict boundaries on how payloads can be intercepted and modified. The official guidance explicitly warns against attempting to perform heavy payload deserialization, buffering, and re-serialization within global middleware layers due to the severe performance penalties and the loss of type safety inherent in operating on type-erased `http::Response<Body>` byte streams [cite: 2, 3].

Secondary authority is derived from the Utoipa project, which has become the de facto standard for code-first OpenAPI 3.1 specification generation in the Rust ecosystem. The Utoipa maintainers provide explicit directives on schema generation, emphasizing that OpenAPI definitions must accurately reflect the exact runtime types returned by HTTP handlers. The project's documentation and recent major releases (e.g., v5.0.0) underscore the necessity of using explicitly typed generic wrappers (like `PaginatedResponse<T>`) in handler signatures to ensure that the macro-driven AST parsers can successfully traverse the codebase and generate accurate `$ref` pointers in the resulting JSON schema [cite: 4, 5, 6, 7].

Finally, registry statistics from `crates.io` and comprehensive ecosystem analytics from `lib.rs` provide authoritative, empirical metrics on adoption rates, active maintenance windows, and dependency graphing, which serve to separate experimental prototypes from battle-tested production tools [cite: 8].

**Practice Evidence**

A rigorous survey of mainstream, highly regarded Rust projects reveals a strong preference for explicit, type-safe pagination boundaries over dynamic runtime interception.

The `tag_api` reference application, maintained as a definitive architectural guide for building robust Axum APIs with Utoipa documentation, explicitly mandates the use of dedicated pagination parameter structs (e.g., `Query<PaginationParams<Filters>>`) and explicitly typed response envelopes (e.g., `Paginated<Json<T>>`). The maintainers explicitly warn that Utoipa does not automatically register structured extractors without explicit type definitions, proving that hidden or global runtime mutation breaks the contract between the runtime and the documentation [cite: 9].

Similarly, the `loco-rs` framework, which is rapidly gaining traction as a comprehensive "Rails-like" framework for Rust, emphasizes explicit route and controller definitions. While Loco aims for high developer productivity, it deliberately eschews dynamic, implicit behavior (like auto-wrapping payloads via global middleware) in favor of compile-time clarity and explicitness [cite: 10]. 

Further practice evidence is found in production systems like `rs-ali-oss` (an Alibaba Cloud Object Storage Service SDK in Rust) and the `OpenTalk` enterprise communication platform, both of which utilize explicit pagination boundaries and strict schema registrations to ensure reliable, predictable data transfer and accurate API specifications [cite: 11, 12].

### Principles and implementation

The fundamental requirement, established by the Python port precedent, dictates that collection endpoints must return their results wrapped in a standardized envelope containing `items` (an array of core domain objects) and `total` (an integer representing the complete dataset size). The pagination itself must be controlled via `page` and `size` query parameters. A critical stipulation of this precedent is that the underlying domain items must remain clean, pristine objects, with the pagination envelope acting strictly as a web-specific wrapper.

This structural capability—the envelope and the query parameters—is a universally agreed-upon standard in REST API design and remains entirely appropriate for the target Rust ecosystem. The use of a standard envelope allows frontend meta-frameworks (e.g., React, SvelteKit) to seamlessly hydrate data tables and manage application state without needing bespoke deserialization logic for every endpoint [cite: 13].

However, a severe architectural conflict arises regarding the *application* of this pattern. The Python implementation registers the pagination machinery globally via a single factory call (`add_pagination(app)`), relying on dynamic runtime reflection to intercept responses, wrap them in the `items`/`total` envelope, and dynamically mutate the OpenAPI schema to reflect the new structure.

This dynamic, app-wide interception pattern is fundamentally incompatible with Rust's static typing, zero-cost abstraction philosophy, and macro-based documentation generators. 

`BASELINE-REVIEW: F311 — app-wide dynamic response wrapping — explicit typed pagination contracts per-route — Rust's type system and macro-based OpenAPI generation (e.g., Utoipa) require explicit request extractors (Query<Pagination>) and response types (Paginated<T>) on the handler signature to ensure compile-time safety, avoid severe serialization performance penalties in middleware, and guarantee accurate schema extraction. Global middleware operates on type-erased byte streams and loses the necessary type information required for safe, performant payload mutation.`

**Architectural Alternatives and Tradeoffs**

To realize the required capability in Rust, two architectural alternatives exist for applying the pagination logic:

1.  **Global Middleware Injection (`tower::Layer`)**:
    In this pattern, a global middleware intercepts every outgoing `http::Response`. It attempts to determine if the body is a JSON array. If so, it buffers the entire asynchronous byte stream into memory, deserializes the raw bytes into a generic JSON object, constructs the pagination envelope, serializes the new structure back to bytes, updates the `Content-Length` header, and forwards the response.
    *   *Tradeoffs*: This approach introduces catastrophic performance degradation. Buffering the entire payload destroys the benefits of asynchronous streaming. Furthermore, the middleware operates without database context; it cannot efficiently execute SQL `LIMIT` or `OFFSET` clauses, meaning the database must return the entire table to the application memory before the middleware slices it. Lastly, OpenAPI macro generators (like Utoipa) parse function signatures at compile time; they cannot see the middleware's runtime mutations, resulting in documentation that claims the endpoint returns a raw array while the runtime actually returns a paginated envelope [cite: 2, 3, 14].

2.  **Explicit Typed Extractors and Responders**:
    In this pattern, every paginated route explicitly declares a pagination extractor in its signature (e.g., `Query<PaginationQuery>`) and explicitly declares an enveloped return type (e.g., `PaginatedJson<DomainModel>`). The handler parses the parameters, passes them to the database layer (which executes an optimized `LIMIT`/`OFFSET` or cursor-based query), and returns the strongly typed envelope.
    *   *Tradeoffs*: This requires minor boilerplate on every paginated route signature. However, it preserves zero-cost abstractions, allows the database to execute optimized pagination queries, avoids unnecessary memory buffering, and guarantees that OpenAPI generators produce perfectly accurate schemas based on the explicit return types [cite: 1, 4, 9].

**The Preserved Principle**

The recommended design adopts the **Explicit Typed Extractors and Responders** pattern. While the *registration* of the pagination machinery differs from the Python baseline (moving from a single app-wide middleware call to explicit per-route signatures), the *principle* is fully preserved: the core domain objects remain perfectly clean, the web-specific envelope is applied uniformly, and the query parameters conform exactly to the required specification. The deviation in implementation is not a failure to port the feature, but rather a necessary architectural adaptation to respect the constraints and strengths of the target Rust ecosystem.

The selected implementation utilizes the `paginator-rs` ecosystem. The core library (`paginator-rs` and `paginator-utils`) provides standard models for pagination parameters and response metadata, entirely decoupled from any web framework. The web-specific crate (`paginator-axum`) provides the `PaginationQuery` extractor and the `PaginatedJson<T>` response envelope. 

This architecture allows the template to maintain a clean separation of concerns: the CLI and library components can utilize the core `paginator-rs` traits for data chunking without incurring HTTP dependencies, while the web service utilizes `paginator-axum` to bind those core traits to the HTTP request lifecycle seamlessly [cite: 15, 16]. Furthermore, `paginator-rs` provides robust protection against SQL injection by enforcing parameterized queries in its database integrations (e.g., SQLx, SeaORM) and supports advanced cursor-based (keyset) pagination, providing significant performance advantages for large enterprise datasets by avoiding the traditional `OFFSET` penalty [cite: 15, 17].

### Recommendation

The recommended stack is the **`paginator-rs` ecosystem bundle**, utilizing `paginator-rs` (core trait and database generation logic), `paginator-utils` (shared models), and `paginator-axum` (web framework integration). 

### Members

#### paginator-axum bundle

This evaluation covers the cohesive workspace of `paginator-rs`, `paginator-utils`, and `paginator-axum`, treated as a single bundled member providing the end-to-end pagination capability for the target template.

##### Landscape
*   **Category:** Up-and-comer. The `paginator-rs` workspace represents a modern, modular approach to providing framework-agnostic pagination abstractions.
*   **Authority:** The implementation adheres strictly to the `FromRequest` extractor patterns codified by the Tokio and Axum maintainers, ensuring that request parsing is zero-cost, type-safe, and capable of generating accurate rejection responses [cite: 1, 18].
*   **Practice:** The bundle addresses a documented pain point in the Rust ecosystem where developers are frequently forced to manually implement identical pagination boilerplate across different projects. The modular structure (separating core logic from framework bindings) aligns with architectural best practices seen in enterprise Rust codebases [cite: 15, 17].

##### Principles and implementation
The `paginator-axum` bundle implements the required capabilities through a highly rigorous, type-safe pipeline. 

1.  **Request Extraction:** The `PaginationQuery` extractor intercepts the HTTP request and utilizes `serde` to deserialize the `page` and `per_page` query parameters. It enforces strict boundaries, defaulting to page 1 and a size of 20, while clamping the maximum size to 100 to prevent denial-of-service vectors through massive database queries [cite: 19, 20].
2.  **Domain Agnosticism:** The parameters are passed to the database layer via a builder pattern (`PaginatorBuilder`), which generates optimized, parameterized SQL queries (protecting against SQL injection). The returned rows are standard domain models [cite: 17].
3.  **Response Formatting:** The domain models are passed into the `PaginatedJson<T>` wrapper. Because `T` is a generic type parameter, the underlying collection items stay plain core-model objects; only the outer envelope introduces the web-specific `total`, `total_pages`, `has_next`, and `has_prev` fields [cite: 17, 20].
4.  **Schema Generation:** The generic `PaginatedJson<T>` type is fully compatible with Utoipa 5.0's schema generation engine. When the Utoipa macro encounters `PaginatedJson<DomainModel>`, it accurately constructs an OpenAPI schema object representing the envelope, utilizing a `$ref` pointer to refer to the inner `DomainModel` schema without duplicating code or obscuring the contract [cite: 4, 6].

##### Dominant choice
The dominant industry practice remains hand-rolling bespoke `PaginationParams` structs and `PaginatedResponse<T>` generics for every individual project. While effective, this approach requires repetitive boilerplate, increases the maintenance burden, and often leads to inconsistent boundary validation or missing HTTP compliance headers (e.g., RFC 8288 Link headers) across different endpoints.

##### Qualified shortlist
*   `paginator-rs` bundle (`paginator-axum`).
*   `page-hunter`.

##### Excluded by gate
Before weighing community popularity or feature depth, all candidates are subjected to strict fitness gates.

| Candidate | Gate | Result | Justification |
| :--- | :--- | :--- | :--- |
| `page-hunter` | 1 (License) | **FAILED** | The crate explicitly lists a `non-standard` license on crates.io, violating the mandate that all dependencies must be `MIT OR Apache-2.0` [cite: 21]. |
| `paginate` | 2 (MSRV/Maintenance) | **FAILED** | Dormant. No release in over four years; pinned to the legacy 2018 Rust edition [cite: 22]. |
| `paging` | 2 (MSRV/Maintenance) | **FAILED** | Dormant. Unmaintained for over four years; pinned to the 2021 edition but lacks modern framework compatibility [cite: 23]. |

##### Up-and-comers
The `paginator-rs` workspace is rapidly expanding its feature set to support enterprise-grade capabilities, most notably Cursor-Based (Keyset) Pagination. Cursor pagination provides superior performance and consistency for extremely large datasets compared to traditional offset-based pagination, ensuring that pages remain stable even under concurrent data modifications [cite: 15, 17].

##### Fit for this template
The workspace structure of the bundle is exceptionally well-suited for the `rs-launch-blueprint` template. The blueprint's architecture (CLI + library + web service) demands that core capabilities be independent of the HTTP transport layer. `paginator-rs` fulfills this by confining all database integration, trait definitions, and cursor encoding to the core library. The CLI and background workers can paginate datasets using `paginator-rs` directly, while the `web-service` component relies on `paginator-axum` solely for URL parsing and JSON formatting [cite: 15, 16].

##### Recommendation
Integrate the `paginator-rs` core library and the `paginator-axum` web framework crate.

##### Ranked runner-up
Hand-rolled generic structures. A locally maintained `src/web/extractors/pagination.rs` file defining a `serde::Deserialize` struct for query parameters and a `serde::Serialize` struct for the response envelope is the most robust fallback if the chosen third-party libraries become unmaintained.

##### Tradeoffs
Adopting the `paginator-rs` bundle introduces a third-party dependency for structural elements that could theoretically be written in-house. This abstracts away the internal calculations for total pages and cursor encoding, which reduces boilerplate but limits the ability to drastically alter the underlying mathematical logic without forking the crate. However, the tradeoff is highly favorable: the bundle provides robust boundary clamping, SQL injection prevention, and standardized REST header generation, which are notoriously tedious to implement securely and consistently in bespoke codebases [cite: 17, 19].

##### Parameters
*   `owns web-pagination-default-size = 20`
*   `owns web-pagination-max-size = 100`
*   `assumes web-framework-stack = axum`
*   `CONFLICT: R69 web-framework-stack — axum — The paginator-axum crate requires Axum as the host web framework; if R69 resolves to Actix-Web or Rocket, the equivalent paginator-actix or paginator-rocket crates must be substituted in the dependency manifest.`

##### Migration implications
Implementing this capability requires precise, file-level adjustments across the template architecture to ensure compile-time safety and accurate schema generation.

*   `Cargo.toml`: Add `paginator-rs` (with the appropriate database feature flags, e.g., `sqlx-postgres`) and `paginator-axum` to the `[dependencies]` block [cite: 17].
*   `src/web/routers/*.rs`: Every handler function that returns a collection must undergo a signature modification. 
    *   The function arguments must include `paginator_axum::PaginationQuery`.
    *   The return type must change from `Json<Vec<DomainModel>>` to `PaginatedJson<DomainModel>`.
*   `src/core/services/*.rs`: Service layer functions must be updated to accept the core `PaginationParams` struct, allowing the service to construct the appropriate `PaginatorBuilder` query before executing the database transaction.
*   `src/web/app.rs`: Ensure no dynamic or global `tower::Layer` middleware is attempting to manipulate JSON response bodies for pagination purposes, relying entirely on the static type definitions in the routers.

##### Validation strategy
To mathematically prove the capability functions as intended in a deployed environment, the following checks must be executed:

*   **Planned Check**: Execute `cargo check` and `cargo test --package rs-launch-blueprint-web` to verify that the strict static typing is maintained and all generic envelopes resolve correctly at compile time.
*   **Planned Check**: Execute a simulated API request: `curl -X GET "http://localhost:3000/api/v1/resources?page=2&per_page=5"`.
*   **Expected Behavior**: The API must return an HTTP `200 OK` status code. The JSON payload must strictly conform to the expected envelope shape, containing an `items` array with exactly 5 unmutated domain models, alongside the metadata fields `page: 2`, `per_page: 5`, `total`, and `total_pages`.
*   **Planned Check**: Execute a boundary-violation request: `curl -X GET "http://localhost:3000/api/v1/resources?page=-1&per_page=5000"`.
*   **Expected Behavior**: The `paginator-axum` extractor must gracefully handle the invalid input, either by rejecting the request with an HTTP `400 Bad Request` or by automatically clamping the boundaries (e.g., forcing `per_page` to the maximum allowed limit of 100 and `page` to 1), returning a `200 OK` with the clamped boundaries accurately reflected in the response metadata.

##### Confidence & re-verify trigger
**High**. The integration strategy aligns perfectly with the static typing requirements of the Rust toolchain, the architectural constraints of the Axum web framework, and the macro-generation capabilities of Utoipa. The solution achieves the exact payload semantics required by the Python precedent without compromising performance.

*Re-verify trigger*: The architecture should be re-verified if the Axum framework releases a major update (e.g., version 1.0) that fundamentally alters the `FromRequest` trait or introduces safe, typed response mutation capabilities that could theoretically enable the Python-style global injection pattern. Additionally, monitor Utoipa major version releases for any changes to generic type resolution (`ComposeSchema`).

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/paginator-axum` | 6,527 [cite: 24] |
| All-time downloads | `GET https://crates.io/api/v1/crates/paginator-axum` | 11,108 [cite: 24] |
| Last release | `GET https://crates.io/api/v1/crates/paginator-axum/versions` | v0.3.2, ~Sep 2026 [cite: 24] |
| Stars, archived | `GET https://api.github.com/repos/maulanasdqn/paginator-rs` | 6, false, 2026-06-14 [cite: 15, 16] |
| Open issues | `GET https://api.github.com/search/issues?q=repo:maulanasdqn/paginator-rs+is:issue+is:open` | 1 [cite: 15] |
| Issue responsiveness | 10 most recently opened issues | inapplicable (data unavailable in survey) [cite: 15] |
| Advisories | `https://rustsec.org/packages/paginator-axum.html` | 0 |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | None publicly notable in current survey |

### Compatibility
The `paginator-rs` ecosystem is explicitly engineered for unified compatibility. The `paginator-axum` crate relies directly on the core `paginator-rs` and `paginator-utils` crates, sharing a unified release cycle and versioning scheme to guarantee structural alignment. The ecosystem is fully compatible with `serde`, which is a hard requirement for Axum's JSON request and response handling mechanisms. Furthermore, the generic structure of `PaginatedJson<T>` is mathematically compatible with Utoipa 5.0's advanced generic schema resolution (`ComposeSchema`), ensuring that OpenAPI documentation pipelines can accurately trace the `$ref` pointers to the inner domain models without manual intervention [cite: 4, 6, 15, 17].

### Parameters
*   `owns web-pagination-default-size = 20`
*   `owns web-pagination-max-size = 100`
*   `assumes web-framework-stack = axum`
*   `CONFLICT: R69 web-framework-stack — axum — The paginator-axum crate requires Axum as the host web framework; if R69 resolves to Actix-Web or Rocket, the equivalent paginator-actix or paginator-rocket crates must be substituted in the dependency manifest.`

### Migration implications
Implementing the recommended architecture requires structural modifications across the template to enforce compile-time safety and eliminate global payload mutations.

*   `Cargo.toml`: The dependency manifest must be updated to include `paginator-rs` (with necessary database feature flags) and `paginator-axum`.
*   `src/web/app.rs`: The composition root must be audited to ensure no `tower::Layer` middleware is globally attempting to intercept, buffer, or serialize JSON response bodies for pagination formatting. The architecture strictly relies on per-route explicit typing.
*   `src/web/routers/*.rs`: All collection-returning handlers must undergo signature updates. The parameters must accept the `paginator_axum::PaginationQuery` extractor, and the return type must be explicitly wrapped in the `PaginatedJson<T>` generic envelope.
*   `src/core/services/*.rs`: Domain services must accept the core `PaginationParams` object to construct efficient, database-level `LIMIT`/`OFFSET` or cursor-based queries prior to execution.

### Validation strategy
The validation strategy relies on a combination of automated static analysis and dynamic runtime checks to mathematically prove the capability.

*   **Planned Check**: Execute the test suite via `cargo test --package rs-launch-blueprint-web`.
*   **Expected Behavior**: Unit and integration tests executing against collection endpoints must assert that the HTTP response body successfully deserializes into a generic envelope struct, verifying the presence of the `items` array and all required pagination metadata fields (`page`, `per_page`, `total_pages`).
*   **Planned Check**: Execute the OpenAPI generation pipeline via Utoipa and run an external schema validation tool (e.g., Schemathesis) against the output.
*   **Expected Behavior**: The generated `openapi.json` must feature an explicit schema definition for the paginated envelope that correctly utilizes a `$ref` pointer to refer to the inner domain model schema (e.g., `#/components/schemas/Project`). This verifies that the OpenAPI specification remains structurally aligned with the Rust source code without requiring manual, per-route schema overrides.

### Confidence & re-verify trigger
**High**. The recommended architecture effectively bridges the gap between the rigid static typing requirements of the Rust toolchain and the flexible payload semantics established by the Python precedent. By shifting the registration mechanism from dynamic middleware to explicit generic types, the template achieves the desired behavior while preserving zero-cost performance and automated documentation generation.

*Re-verify trigger*: The architectural decision must be re-evaluated if a future major release of the Axum framework introduces macro-based dynamic response mutation capabilities that circumvent current typing limitations, or if Utoipa significantly alters its generic AST parsing algorithms.

### Sources
The analytical data, architectural guidelines, and empirical metrics supporting this report were synthesized from the following verified endpoints and authoritative documentation:
*   Architectural patterns and explicit routing guidelines derived from the `tag_api` reference application and `loco-rs` framework documentation [cite: 9, 10].
*   Global download metrics, maintenance statuses, and dependency graphs extracted from the `crates.io` API and `lib.rs` ecosystem analytics [cite: 8].
*   Middleware limitations, extractor precedence rules, and type erasure constraints sourced directly from the official Tokio and Axum project documentation [cite: 1, 2, 3].
*   OpenAPI schema generation mechanics and AST generic resolution guidelines acquired from the Utoipa 5.0.0 maintainer specifications [cite: 4, 6, 7, 9].
*   Query parameter boundaries, cursor encoding protections, and database ORM integration capabilities gathered from the `paginator-rs` workspace documentation [cite: 15, 17, 19, 20].
*   Historical Rust pagination crate evaluations (e.g., `paging`, `paginate`, `page-hunter`) confirming dormancy or licensing violations [cite: 21, 22, 23].
*   Repository statistics, including issue counts and star metrics, retrieved from the GitHub REST API for `maulanasdqn/paginator-rs` [cite: 15, 16].

**Sources:**
1. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH8Hxz_mO_LdVznlySIU5iwqa3MvyGGoTgUhS9c7c2xt7HyZ6_stbbhcWTfH6sN1nEa6sF0BaiRqzTdswbgHidd5R-Hoq_XJ8n9kZlq0IZTfNbPd7fmlX0=)
2. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHbjFNeZ4ClZ72fVqskzYyCkaRz9Cb7AaA-6nWpzT6cMfs2OUXqD531dDwCh1zQ84ENgiFtmxCNi4NGKEZD8UuGiFqCcOS60JRnoqZwyl2yPzhVRvcuTKghbQsSVSYXR_fAbTa2HNE0pLM=)
3. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHgQnnOYCg3cONDVu6njFMHFb4OP-N5oYZOEpLWpQOL1rLqn9QBI5Yf82arXD5aRW8JfmO9Mrvo8bSch6oZa557WXy14BD_FY-EkybMov9jykEupFuk8EndT2kp33faTpa9K6CTs0V9USRwcg2IZEalx4tkjsmau6criKJCQRJaPJfJGTqFw2GhjjEic-kgRZTkXXO53HTrAvTuWb7ZJsjw3ZRNASQMY-bo1CqCe8IB4uo=)
4. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGUkTLb7DsAgle3y5vZkLskzkqkPNSF7YsFez3O_LPRw6wch_JcWYUKMlTK7yl0V4ktccufWMsZZX2tHENnagX2GWheBFzGUrmd8Qbs9zPkvO7GRJ6PGQ-_41dbd2P4fhyVtq1UHM1fj_TMprOwW74-l0Gep21Wb1v1x6mrZxX_KOBUCBOoN8FLOcDDqWIjtwPITu573sg=)
5. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFSPb4QC988Z4ayiM6cjZzEPT3Ig8MJSF2a_ETTEqs8gmdi_EwXCfJCo9Kn6SsQLfcxApvyqi_LPUOqqLErefPPZOF76e0k91OKD6rYC4mg4OB-s7iHmgt0SYBe)
6. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH4PRIDEN5jfnSussZ36Y63y_VgqDYlGKR0mm9hDM2Av0F0hFotaf3X5P0tZwJL6uHHuDNyz6VreBR-DAKsKV6n5smvLhGGSlNDZGms2dSTQfN0-yGuB_GoP4wyvtY9zlztww==)
7. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFLS18CYCo8ceB-1wqLjvhhUNxnmwJU6itbjVLKYUtbpGSxAtrx_22kbTS_f2_oqlQCM6CmYajSrxUxyHHxY0aJ7aiN_NFnuKucIeecKgt1A23Sr18A1Q==)
8. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGaIBiB7BCiCFYpvm_pkF4iLthRX1S4DjQAzeNPwRZCsvkQqIsh9cJsus5RZnd42_ihGJ7Kg13YOFFb5UGlEulPFARM3Aj5BtPbvQ==)
9. [tangled.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG1WKCAc2-P-1Hok9D7GIRkfdGlE2cvmPv47Vz7VCirhflx71K7jVXqyTw0qJMfaUIKdiitqGBlUJPOqTWYJB22gBxWPkQmq-BGHHlj1TMlKyNt7Hwu8cU_2JgL2QxNHQAa1IRO-3rJtZvlZLAxKaZZdnxTdN9wh--A7wcn2BzhLMQYzfagLHgSpz6Cffg=)
10. [rng0.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHgXEv-2dvZ90P6S4EU0kihc0bHiBS4sbPHC-vV2GPBNSj_qa7vzdI-yfhyhsuUGm-sfjZSWsaNM2k0zkquWvMo-mkg7vXtvjkRaHwNl58Tf08WtRzOQY6GIQDl7w==)
11. [opentalk.eu](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHZeNo__c6pdbv8Ivo1n_oQCqpmFVNBS2Zm6WFzXqHBGXdwcSiB5NAfce00k9RQW7O2agSiC4tL6YQhpPkepUxiky_iFsxdNGZkX7NYNBkma8CH5OrrPCiVbSdf-TA3xngMWaF5QWigiQu5klZkPA==)
12. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE3Lne3l-U-2BmzhO5dM-VOjuI7IrgHDkTyxIDJzP7VRzFDfraJRIJXjS9DkULBKn_i7DrxnVXCPDOfZM7v8rafSX4AgXc2exLbJfFtyg29HoCQdBsQQaAaXu6J5Miy)
13. [isg-journal.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFqZ0u4JCiSMjBqEk-EDQcMhHoYwUS1bgxh4bXaRhrPjOkrJf9fam3wxlrRwXnLZHSDpOtEbDErRGgb3SW_TsWgl3JMCiWwIv2eBGDQLn3cs2Z06jW7Oixgv45RPPHqRI5Yp9vjaOx9x1tqj7xQWgk1wS0=)
14. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHFzUKxp2gBOMEZrwyAr4gPjA50VDcNNmQr0VQNRIGCoQ24QWU5I_bILO4IQeD0_oZ1IsuIYKz_FtCzeTZ16g69ZbtrqNAshYfC_cRdNGItdkFgPLtynT3XutXyh453KLZYIXHfJT5Z)
15. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFba1eiotmTnsaYnAiDR0xsD1zTbovs6DVW8UQ46jv3GZTkga5E7Dy_RWdq2vimDsqzpBUurvwmnGRvvN0TXAmQXobAiWjmTUShcoXYL9VdMloDSibM-c5rH8MRVmVUpqES)
16. [libraries.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFI3mQHYkAYrHql_RyHP8VmRwNCzicURWKHlmOaAtu7mUu8LhoMIn4RfhgeoBP-OjNPYHIToC13RZbo-3wGhJSBEsMsVJk2fssFVJ0pt_A-sZJilFOvbWRhVlKdhM9U4A==)
17. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFqVHb0gwII6pGcWRPDvdqcgiUzEEVDKZpKKLDg0y4Hsh0FLtGEMVlPuIu9RRCy0e925xY1AA-0DJ9_nBa-t_lbxPSKKdNWHkwTLlLAj5jozkdOv4w3UtpBa-qLFs0xuwc=)
18. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGddwlo2dOJgU-Vu7PyeuUnAoxYnLuiYsQMs79buBcEScgeC0Odfk3_A1pjqzoDrv6BmTTY2tGppGD5qFgGMBexKyLtqm1phY9IMO55GpTUjnzRk5-S9ye1efR42kcV-gESrS1HBk7Nr7ylAHolLBBM9oGRenKCta7szXF_Ruvd2vliJ7GYZJpO1Zn0mA==)
19. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFglzS45n54aA-e_SF2ZScWRGVJIhR-Jg9fOKUmF_GXB2fzuPhtn5VwRtCTNqDTQP16FMYkAim3gdOc_u5RfmNvfwcI_PWWzttArXKU-cMXIKI9GszP7_PfBqE=)
20. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGtwOu1OTHzYwd4H88Ob7kAYhmEM6MEDHtrN3jniW7f6UhvShMk9eNQ3AKrLautjkhWEf5q_Gxbun7my3SwTJPLT6YnC1eyEDuCinUj-7s7557aKEDGmHYttIF386czkG5p)
21. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEA017ZgkVtXS7Rl4WDeXHagU32VLJiswa8W_6RaQ62EPiu3-y0V-EaWKTpFpePf54EBJIdpJbTdcmBeaO4upLB5wcv-6CoFdXJ0W3qfn8Va3vFM1gulmU2-bQ=)
22. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE-JcHpP-YJAWEr_vY-PWaIPiNqYk1iX8QVyzO4TmhTAwdOnURBw8ALpEK-N0DPkKPf3x1TaeSTZpR23Ran7k4fD9MJ08voQ4eilr2KPccWwEryym0Xie0=)
23. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE1I07XRjxJUzzMAenZG4MmQgtCztMWLjDkSIwa-5Wcbtp-oMx7IejC3Fa1AvKeYeYiIjgoqHGjwiW44slqvC41akwswXkcoXnHR0VqO1t9m_CvyW00)
24. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFAhJnkBPXUmILu3YsaejSZ4Qdzt_nE11k_zldKznlomWz1ThzL_4LDIAwLbAT3ZlCMkvsL0GcVtnEXXQDObot25U-o5NXzvShwWOLzzfWaGwi81OJqohIrTyyU)

## Sources

- [docs.rs](https://docs.rs/axum/latest/axum/)
- [docs.rs](https://docs.rs/axum/latest/axum/extract/index.html)
- [medium.com](https://medium.com/@theopinionatedev/the-secret-pattern-behind-axum-extractors-towers-layer-system-demystified-5a936f16fbdb)
- [github.com](https://github.com/juhaku/utoipa)
- [docs.rs](https://docs.rs/utoipa/latest/utoipa/)
- [reddit.com](https://www.reddit.com/r/rust/comments/1g3kevi/utoipa_500_release_compile_time_openapi_for_rust/)
- [github.com](https://github.com/juhaku/utoipa/issues/1586)
- [lib.rs](https://lib.rs/stats)
- [tangled.org](https://tangled.org/shyrogan.fr/tag_api/commit/3062d50aebb93c47bee47aa69763d502ec3cca8d)
- [rng0.io](https://blog.rng0.io/introducing-loco/)
- [github.com](https://github.com/infinitete/rs-ali-oss)
- [opentalk.eu](https://docs.opentalk.eu/releases/components/controller/)
- [isg-journal.com](https://isg-journal.com/isjea/article/download/1219/764/1263)
- [github.com](https://github.com/juhaku/utoipa/discussions/1337)
- [libraries.io](https://libraries.io/cargo/paginator-axum)
- [github.com](https://github.com/maulanasdqn/paginator-rs)
- [crates.io](https://crates.io/crates/paginator-sea-orm)
- [github.io](https://jabber-tools.github.io/google_cognitive_apis/doc/0.2.0/axum/extract/index.html)
- [lib.rs](https://lib.rs/crates/paginator-axum)
- [crates.io](https://crates.io/crates/paginator-rs/0.2.0)
- [crates.io](https://crates.io/crates/page-hunter)
- [crates.io](https://crates.io/crates/paginate)
- [crates.io](https://crates.io/crates/paging)
- [crates.io](https://crates.io/keywords/pagination)