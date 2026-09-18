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
provider: openai
model: gpt-5.6-sol
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

## Reasoning Summary
**Researching extensive metrics**

I need to conduct extensive research, ensuring I have exact headings and source URLs with retrieval dates. The current date is specified as September 18, 2026, which I must be careful to reference. Since the user mentioned September 4, 2026, I should focus my research accordingly. I need to use the web thoroughly, identifying pagination crates that can integrate with leading async web frameworks, especially something like Axum. Time to initiate broad search queries!

### Landscape

**Retrieval convention:** all web sources were retrieved on **September 18, 2026**. Source keys resolve to URLs under `### Sources`. Owner-supplied repository paths are marked `O1`–`O4`.

**Decision category:** HTTP collection-pagination contract, request-boundary extraction, and application composition policy. This is not primarily a database-pagination or web-framework decision.

#### Three-bin ecosystem map

| Bin | Candidates found | Assessment for R72 |
|---|---|---|
| **Built-in / first-party toolchain** | The selected framework’s generic query extractor, Serde-derived local DTOs, and a small local custom extractor when application state is needed. Axum provides `Query<T>` and `FromRequestParts`; Actix Web similarly treats extractors as handler arguments. | Best architectural fit. It preserves framework-native typing, adds no pagination-specific dependency, and can keep the generic response wrapper inside the web crate. [S6, S7; retrieved 2026-09-18] ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.Query.html)) |
| **Established industry pattern** | A reusable, application-owned query type plus generic `Page<T>`/`PaginatedResponse<T>` DTO, named in each collection handler. There is no surveyed cross-framework Rust equivalent of FastAPI’s runtime `add_pagination(app)` registry. | This is the dominant pattern visible in framework documentation and examples, although field names vary. Axum’s maintained todo example defines pagination locally and extracts it through the handler signature; Loco documents its own `Pagination Response` rather than relying on a universal crate. [S8, S15; retrieved 2026-09-18] ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs)) |
| **Up-and-comers** | `paginator-rs`/`paginator-axum` 0.4.0; `page-hunter` 0.7.0; `axum-api-kit` 1.0.0; `autumn-web` 0.7.0. | Each realizes part of the capability, but none matches all of `page`/`size`, generic `items`/`total`, framework independence, strict validation, one app-level policy, and the mandatory fitness gates. [S11–S14; retrieved 2026-09-18] ([docs.rs](https://docs.rs/crate/paginator-axum/0.4.0/source/README.md)) |

#### Candidate capability map

| Candidate | Query contract | Response contract | Typed framework integration | App-wide registration | Domain items remain `T` | OpenAPI |
|---|---|---|---|---|---|---|
| `paginator-rs` + `paginator-axum` 0.4.0 | `page` + `per_page` | `data` + nested `meta.total` and other metadata | Yes, Axum `PaginationQuery` extractor | No; extractor appears in each handler | Yes, generic response over `T` | No maintained OpenAPI integration documented in the surveyed 0.4.0 examples |
| `page-hunter` 0.7.0 | No HTTP extractor | `items`, `page`, `size`, `total`, and navigation metadata | No | No | Yes | Optional `utoipa` schema support |
| `axum-api-kit` 1.0.0 | `limit` + `offset` | `data`, `total`, `limit`, `offset` | Yes, Axum extractor | No | Yes | Optional Utoipa `IntoParams` support |
| `autumn-web` 0.7.0 | `page` + `size` | `content`, `total_elements`, and metadata | Yes, as part of the entire Autumn framework | No separate registration | Yes | Integrated into Autumn’s own OpenAPI system |
| Local native adapter | `page` + `size` | Exact project-owned `Page<T>` | Implemented against whichever framework R69 selects | Policy configured once in app state; no per-router installation | Yes | Adapter added after R71 chooses the schema pipeline |

The closest all-in-one candidate is `paginator-axum`, but it deliberately exposes a different wire contract: `page`/`per_page` and `{data, meta:{total,...}}`. `page-hunter` comes closest to the desired generic response DTO, but it supplies neither HTTP extraction nor application registration and its examples use zero-based page indexes. `autumn-web` has a close capability but selecting it would improperly decide R69 and would pull in an entire convention-over-configuration framework. [S11–S14; retrieved 2026-09-18] ([docs.rs](https://docs.rs/crate/paginator-axum/0.4.0/source/README.md))

#### Authority and practice evidence

- The Rust release team and Cargo documentation are authoritative for the current stable release, Edition 2024 resolver behavior, and `rust-version`. Stable is Rust **1.98.1**, so the owner’s N-2 policy currently resolves to **Rust 1.96**. Cargo explicitly recommends declaring and verifying `rust-version`, and Edition 2024 enables the Rust-version-aware resolver. [S1–S3; retrieved 2026-09-18] ([blog.rust-lang.org](https://blog.rust-lang.org/releases/latest/))
- The Rust API Guidelines are authored largely by the Rust library team. Their relevant principles are to validate inputs, represent invariants with types, use generics where appropriate, and avoid unstable public dependencies in stable APIs. These directly favor a validated `PageParams` type and generic `Page<T>`. [S4; retrieved 2026-09-18] ([rust-lang.github.io](https://rust-lang.github.io/api-guidelines/dependability.html))
- Axum and Actix Web maintainer documentation is authoritative for their extractor models. Both make extraction part of the handler’s typed signature rather than a runtime response-model registry. [S6, S7; retrieved 2026-09-18] ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.Query.html))
- The 2025 State of Rust survey reports that stable Rust is the normal toolchain and that compile time and storage use remain prominent productivity concerns. The compiler-performance survey identifies reducing dependencies and enabled features among the most commonly used build-performance improvements. That weighs against adding a broad pagination dependency for a small boundary contract. [S5; retrieved 2026-09-18] ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))
- The canonical crates.io service is a strong production reference because it is operated by the Rust project. It migrated to Axum and generates OpenAPI with Utoipa, showing that framework-native extractors and derived schemas compose in a substantial service, although its pagination contract is not evidence for the exact R72 wire shape. [S9; retrieved 2026-09-18] ([blog.rust-lang.org](https://blog.rust-lang.org/2025/02/05/crates-io-development-update/))
- Axum’s own maintained todo example defines a local pagination query DTO and puts `Query<Pagination>` in the collection handler. This is the clearest maintained reference implementation for the underlying architectural pattern. [S8; retrieved 2026-09-18] ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs))

#### Required figure audit

The prescribed crates.io, GitHub API, RustSec, and reverse-dependency endpoints were requested on September 18, 2026, but the research transport rejected the raw API responses. Therefore, **no endpoint-derived download, release timestamp, `pushed_at`, archived, issue-responsiveness, advisory, or adopter figure is asserted or used to rank candidates**. GitHub HTML and docs.rs exposed some non-admissible summary numbers, but those were intentionally not substituted for the owner-mandated endpoints.

| Candidate | Required endpoints | Result |
|---|---|---|
| `paginator-rs` | `GET https://crates.io/api/v1/crates/paginator-rs`; `/versions`; `GET https://api.github.com/repos/maulanasdqn/paginator-rs`; GitHub issue search; `https://rustsec.org/packages/paginator-rs.html`; crates.io reverse dependencies | Endpoint values unavailable; popularity and responsiveness not weighed |
| `paginator-axum` | Corresponding crates.io endpoints; same GitHub repository and issue endpoints; RustSec package page; reverse dependencies | Endpoint values unavailable |
| `page-hunter` | `GET https://crates.io/api/v1/crates/page-hunter`; `/versions`; `GET https://api.github.com/repos/JMTamayo/page-hunter`; GitHub issue search; RustSec package page; reverse dependencies | Endpoint values unavailable |

This is a material evidence gap, but it does not change the recommendation because both external shortlists fail capability or mandatory fitness verification before popularity is considered.

### Principles and implementation

#### Shared requirement and agreement level

The shared principle is:

> **Every collection endpoint exposes one bounded, validated pagination contract; returns a generic web-only envelope containing unmodified domain items; and derives all defaults and limits from one application-level policy.**

Agreement is required at four different levels:

1. **Capability:** every collection route is paginated.
2. **Wire standard:** query parameters are `page` and `size`; pages are one-based; the response is a generic `Page<T>` whose required fields include `items` and `total`.
3. **Architectural pattern:** domain models remain domain models. Only `Page<T>` and the HTTP extractor belong to the web boundary.
4. **Policy:** defaults, maximum size, overflow handling, and zero-value validation are defined once and tested uniformly.

The following may vary with R69 or R71 without violating R72:

- The framework trait implementing extraction.
- The JSON responder wrapper, such as `Json<Page<T>>`.
- The OpenAPI derive or route annotation.
- How pagination failures are translated to the R70 problem envelope.
- How the repository executes count and page queries.

This separation follows Rust’s guidance to validate at boundaries, encode invariants in types, and use generic APIs while keeping public dependency exposure controlled. [S4; retrieved 2026-09-18] ([rust-lang.github.io](https://rust-lang.github.io/api-guidelines/dependability.html))

#### Architectural alternatives

**Alternative A — global pagination middleware**

A Tower/Actix middleware could parse `page` and `size` on every request, insert a value into request extensions, and be layered once at the application root. It superficially resembles `add_pagination(app)`, but it is a poor semantic fit:

- It executes on non-collection routes.
- A malformed pagination query could affect `/health` or single-resource routes.
- Pagination becomes less visible in handler signatures.
- Route-oriented OpenAPI generators cannot reliably infer parameters from generic middleware.
- Resource-specific filter query objects still need per-route extraction.

Reject this alternative.

**Alternative B — dedicated pagination crate**

This reduces local code but fixes the template’s public wire contract to a young crate’s types and naming. The surveyed crates either use a different contract, lack extraction, select an entire framework, or cannot satisfy the required MSRV/security/platform evidence. `paginator-axum` demonstrates that a Rust integration still places a typed extractor in every collection handler rather than registering it globally. [S11–S14; retrieved 2026-09-18] ([docs.rs](https://docs.rs/crate/paginator-axum/0.4.0/source/README.md))

Reject this alternative for the initial template.

**Alternative C — raw `Query<PageQuery>` in every route**

This is idiomatic and is the pattern in Axum’s official example, but raw DTO fields can be accessed before validation, and resolving defaults or limits may be repeated across handlers. [S6, S8; retrieved 2026-09-18] ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.Query.html))

Keep this as the simplest fallback, but prefer one reusable validated extractor.

**Alternative D — local validated extractor plus generic response**

Implement the contract in `web::pagination`, adapt it to the R69 framework’s extractor trait, and read one `PaginationPolicy` from application state. Every collection handler names one reusable extractor argument; no router installs layers or response models.

Choose this alternative.

#### Reference design

The pure types are framework-independent:

```rust
// src/web/pagination.rs

use serde::{Deserialize, Serialize};
use std::num::NonZeroU32;

#[derive(Debug, Clone, Copy)]
pub struct PaginationPolicy {
    default_size: NonZeroU32,
    max_size: NonZeroU32,
}

#[derive(Debug, Deserialize)]
struct RawPageQuery {
    page: Option<u32>,
    size: Option<u32>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PageParams {
    page: NonZeroU32,
    size: NonZeroU32,
}

impl PageParams {
    pub fn page(self) -> u32 {
        self.page.get()
    }

    pub fn size(self) -> u32 {
        self.size.get()
    }

    pub fn limit(self) -> u64 {
        u64::from(self.size.get())
    }

    pub fn offset(self) -> Option<u64> {
        u64::from(self.page.get() - 1)
            .checked_mul(u64::from(self.size.get()))
    }
}

#[derive(Debug, Serialize)]
pub struct Page<T> {
    items: Vec<T>,
    total: u64,
    page: u32,
    size: u32,
    pages: u64,
}

impl<T> Page<T> {
    pub fn new(items: Vec<T>, total: u64, params: PageParams) -> Self {
        let size = u64::from(params.size());
        let pages = total.div_ceil(size);

        Self {
            items,
            total,
            page: params.page(),
            size: params.size(),
            pages,
        }
    }
}
```

Proposed validation semantics:

- Missing `page` becomes `1`.
- Missing `size` uses the single application policy.
- `page=0`, `size=0`, malformed integers, size above the configured maximum, and offset overflow are rejected.
- A one-based page beyond the last page returns an empty `items` array while preserving `total`, `page`, `size`, and `pages`; it is not itself a pagination-validation error.
- Unknown query keys are ignored so resource-specific filter and sort parameters can coexist.
- Values above the maximum are rejected rather than silently clamped, following Rust’s validate-input guidance. [S4; retrieved 2026-09-18] ([rust-lang.github.io](https://rust-lang.github.io/api-guidelines/dependability.html))

A representative Axum adapter—illustrative only until R69 resolves—would implement `FromRequestParts` for `PageParams`, use `Query<RawPageQuery>` internally, obtain `PaginationPolicy` through application state, and return an R70-compatible rejection. The Actix equivalent would implement `FromRequest`. Both frameworks’ documented models support this design. [S6, S7; retrieved 2026-09-18] ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.Query.html))

A collection handler then contains one pagination argument:

```rust
async fn list_projects(
    page: PageParams,
    app: FrameworkState<AppState>,
) -> Result<FrameworkJson<Page<Project>>, ApiError> {
    let window = page
        .offset()
        .map(|offset| ListWindow {
            offset,
            limit: page.limit(),
        })
        .ok_or(ApiError::pagination_overflow())?;

    let (items, total) = app.projects.list(window).await?;

    Ok(FrameworkJson(Page::new(items, total, page)))
}
```

`Project` is not converted into a pagination-crate model. `Vec<Project>` moves directly into `Page<Project>`, satisfying the Python precedent that only the collection envelope is web-specific.

The composition root has one policy value:

```rust
let state = AppState {
    pagination: PaginationPolicy::new(DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE)?,
    projects,
    // ...
};

let app = build_routes().with_state(state);
```

There is no `add_pagination`, router extension, or per-router layer.

#### OpenAPI boundary

R71 should attach its selected schema derive to `Page<T>` and a documentation-only query-parameter type to `PageParams`. This likely requires per-operation parameter discovery or annotation because route-oriented Rust schema generators derive operations from typed handlers, not from a global runtime registry. `page-hunter`’s optional Utoipa support and `axum-api-kit`’s `IntoParams` derive show that schema support can be attached to generic response and parameter types without changing domain items. [S12, S14; retrieved 2026-09-18] ([github.com](https://github.com/JMTamayo/page-hunter))

#### Observable acceptance criteria

1. `GET /projects?page=2&size=2` invokes the repository with the expected bounded window.
2. Its JSON body is a `Page<Project>` containing `items`, `total`, `page`, `size`, and `pages`.
3. Each object in `items` is serialized directly from `Project`; no crate-specific item wrapper appears.
4. `page=0`, `size=0`, malformed values, oversize requests, and offset overflow fail before repository invocation.
5. `/health?page=bad&size=bad` remains successful, proving pagination was not implemented as indiscriminate global middleware.
6. All collection handlers contain the same reusable extractor and return the same generic envelope.
7. Pagination policy construction occurs once in the composition root; router modules contain no pagination installation call.
8. The pure contract and selected framework adapter pass Rust 1.96 and current stable on Ubuntu and macOS.
9. After R71, each collection operation contains `page` and `size` query parameters and a schema for the concrete `Page<Model>` response.

#### Baseline challenge

`BASELINE-REVIEW: F311 — principle: one uniform pagination contract and policy — proposed change: replace the mandatory add_pagination-equivalent runtime registration call with one composition-root PaginationPolicy value plus a reusable typed extractor named by each collection handler; forbid per-router pagination layers — affected: R72/F311 and the future R69/R71 adapters; F310 remains unchanged — evidence: Axum and Actix bind extraction through handler arguments, and paginator-axum’s own integration likewise uses PaginationQuery in each handler rather than an app registry.` [S6, S7, S11; retrieved 2026-09-18] ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.Query.html))

#### Performance evidence and limits

No comparable pagination-extractor benchmarks were published by the shortlisted candidates, so no absolute throughput ranking is justified. The proposed local adapter and crate extractors perform the same basic work: parse a short query string, validate small integers, and serialize `Vec<T>`. The dominant route cost is ordinarily data access and producing an exact `total`; `paginator-rs` explicitly offers disabling the total count as a performance option, which cannot be used while R72 requires an exact `total`. [S11; retrieved 2026-09-18] ([docs.rs](https://docs.rs/crate/paginator-axum/0.4.0/source/README.md))

The empirical comparison must therefore use a single workload and database configuration:

- 10,000 seeded projects.
- Page sizes 1, 20, 50, and configured maximum.
- Shallow pages and a page whose offset is near the end.
- Instrument HTTP p50/p95/p99 latency, requests/second, repository query count, count-query duration, process RSS, and response bytes.
- Compare only the local extractor against an equivalent crate extractor while using the same repository implementation and count strategy.
- Record clean build, incremental rebuild, release binary size, and dependency count because Rust’s surveys identify dependency and compile costs as relevant productivity concerns. [S5; retrieved 2026-09-18] ([blog.rust-lang.org](https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/))

No integration or performance command was run during this research response; all checks below are proposed acceptance work.

### Recommendation

**Adopt `R72 Native Pagination Contract v1`: no external pagination crate.**

Stack:

- **R72-owned member:** local `web::pagination::{PaginationPolicy, PageParams, Page<T>}`.
- **Serialization substrate:** `serde 1.0.229`, expected to already be part of the web stack.
- **Extractor substrate:** the first-party query/custom-extractor API of whichever framework R69 selects.
- **Maintained executable reference:** `axum 0.8.9` with `Query<T>`/`FromRequestParts`; this is a reference spike, not an R69 decision.
- **New R72 dependencies:** none.

The contract is `page`/`size`, one-based pages, bounded strict validation, and a generic `Page<T>` containing unmodified domain objects under `items` and exact `total`. Pagination policy is constructed once in application state; each collection handler explicitly requests the reusable extractor.

### Members

#### Native typed pagination adapter v1

##### Landscape

This member is an application-owned architectural pattern, not a published crate. Crate download, release, GitHub, RustSec-package, issue-responsiveness, and reverse-dependency figures are therefore **inapplicable**. Its underlying mechanism is the generic query and custom-extractor facility supplied by the R69 framework. Axum and Actix Web both document that mechanism as part of handler typing. [S6, S7; retrieved 2026-09-18] ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.Query.html))

Maintenance state: **active**, because the adapter is maintained and released with `rs-launch-blueprint` itself.

##### Principles and implementation

The member owns only web-boundary concerns:

- Deserializing `page` and `size`.
- Applying the one application policy.
- Converting page/size to a checked datastore window.
- Constructing and serializing `Page<T>`.
- Exposing schema hooks for R71.

It does not own domain models, repository technology, database SQL, R70 errors, or R71’s schema generator.

The type should use private fields, validated constructors, `NonZeroU32` internally, checked multiplication for offsets, `u64` for total counts, and `#![forbid(unsafe_code)]` in the relevant template crate. These choices follow the Rust API Guidelines’ validation, custom-type, future-proofing, and generic-API principles. [S4; retrieved 2026-09-18] ([rust-lang.github.io](https://rust-lang.github.io/api-guidelines/dependability.html))

##### Dominant choice

The dominant surveyed approach is **framework-native query extraction plus application-owned pagination DTOs**, rather than a universal pagination plugin. Axum’s maintained example demonstrates the direct form; Loco and other opinionated frameworks then add their own named response conventions on top. [S8, S15; retrieved 2026-09-18] ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs))

##### Qualified shortlist

Only the local native adapter qualifies for the current recommendation:

1. **License:** covered by the template’s `MIT OR Apache-2.0`.
2. **MSRV:** compiled in the template, whose current N-2 MSRV is Rust 1.96 and whose root manifest declares `rust-version`.
3. **Advisories and unsafe:** no new dependency or package advisory surface; local code can forbid unsafe.
4. **Platforms:** contains no OS-specific APIs and is required to run in both Ubuntu and macOS CI; Windows is expected to work but is not an acceptance platform.
5. **Features/runtime:** no feature flags and no independent async runtime coupling; only the R69 adapter depends on the framework.
6. **Compile/binary cost:** qualitatively negligible relative to a web framework—plain structs, Serde derives, checked integer arithmetic, and generic serialization.

The qualification remains conditional on the proposed Rust 1.96 and two-OS integration run.

##### Excluded by gate

**`paginator-rs` + `paginator-axum` 0.4.0 — active, excluded**

- License: passes; published Axum manifest declares MIT.
- MSRV: fails the owner’s verification gate because the published `paginator-axum` manifest has no `rust-version`; no N-2 CI evidence was verified.
- Advisories/unsafe: RustSec and unsafe posture could not be verified through the required endpoints.
- Platforms: no verified macOS CI evidence was obtained.
- Features/runtime: Axum default features are disabled and `json`/`query` are enabled; it is specifically coupled to Axum 0.8 and also depends on `async-trait`, `form_urlencoded`, `serde_json`, `paginator-rs`, and `paginator-utils`.
- Compile/binary cost: moderate compared with local DTOs because multiple pagination crates and broader sorting/filtering/cursor machinery enter the graph.
- Capability mismatch: uses `page`/`per_page` and `{data, meta}` rather than the required `page`/`size` and `items`/`total`.
- Registration mismatch: handlers explicitly request `PaginationQuery`; there is no `add_pagination(app)` equivalent. [S11; retrieved 2026-09-18] ([docs.rs](https://docs.rs/crate/paginator-axum/0.4.0/source/Cargo.toml))

**`page-hunter` 0.7.0 — active, excluded**

- License, MSRV, advisory, unsafe, and two-OS evidence could not all be verified through the mandatory endpoints, so it cannot pass the gates.
- It has optional `serde`, `utoipa`, and `sqlx` features; default-feature behavior was not established from the retrieved evidence.
- Core-only compile cost should be qualitatively small, while enabling SQLx makes it materially heavier.
- Its `Page<T>` closely matches the desired response and preserves caller-owned `T`.
- It supplies no HTTP extractor or app registration.
- Its examples use zero-based page numbers, conflicting with the recommended one-based contract.
- Its strong construction rules require page-shape consistency, which adds useful invariants but also couples DTO construction to assumptions such as full non-final pages. [S12; retrieved 2026-09-18] ([github.com](https://github.com/JMTamayo/page-hunter))

**`autumn-web` 0.7.0 — active, excluded**

- It is a complete Axum/Diesel/Maud-style framework and therefore crosses R69’s ownership boundary.
- It uses `page`/`size`, but serializes `content` and `total_elements`, not `items` and `total`.
- Its extractor intentionally defaults malformed values rather than rejecting them.
- The 0.7.0 docs.rs build failed, and its published source surface is far larger than the required pagination capability.
- Adopting it for pagination alone would impose disproportionate compile, binary, and integration cost. [S13; retrieved 2026-09-18] ([docs.rs](https://docs.rs/crate/autumn-web/latest))

**`axum-api-kit` 1.0.0 — active, excluded**

- It integrates cleanly with Axum and can derive Utoipa query parameters.
- Its public contract is `limit`/`offset` and `{data,total,limit,offset}`.
- It is consequently a replacement contract rather than an implementation of the R72 contract.
- It also couples R72 to Axum before R69 has decided the framework. [S14; retrieved 2026-09-18] ([docs.rs](https://docs.rs/axum-api-kit/latest/src/axum_api_kit/pagination.rs.html))

##### Up-and-comers

- `page-hunter` is the most relevant response-model project because it already has generic `items`/`total` and optional Utoipa support.
- `paginator-rs` is the most ambitious ecosystem bundle because it covers multiple frameworks, databases, offset pagination, cursor pagination, sorting, filtering, and search.
- `autumn-web` demonstrates that an opinionated Rust framework can ship a built-in page/size extractor and generic response.
- `axum-api-kit` demonstrates a small Axum-specific extractor plus generic response and OpenAPI parameter derives.

They should be re-evaluated if one publishes an exact `page`/`size` and `items`/`total` adapter, declares/test its MSRV, demonstrates Ubuntu and macOS CI, and gains production adopters. [S11–S14; retrieved 2026-09-18] ([docs.rs](https://docs.rs/crate/paginator-axum/0.4.0/source/README.md))

##### Fit for this template

The local adapter preserves the CLI/library/web-service shape:

- The core library exposes `Project` and application-level list-window types without depending on a web framework.
- The web service owns query parsing and `Page<Project>`.
- The CLI may call the same application service with a limit/offset window without importing the web envelope.
- R69 can replace the framework without changing the wire contract or collection response type.
- R71 can replace the OpenAPI generator without changing domain models.
- R70 can replace error rendering without changing successful pagination.

##### Recommendation

Implement `PaginationPolicy`, validated `PageParams`, and generic `Page<T>` locally. Put policy in the root `AppState` exactly once. Implement the framework adapter after R69 is resolved. Require `PageParams` explicitly in every collection handler, but prohibit pagination middleware or setup calls in individual routers.

##### Ranked runner-up

**`page-hunter 0.7.0` plus the selected framework’s native query extractor** is the runner-up because its generic response fields are closest to the target and it offers optional Utoipa support.

It should not be selected until:

1. One-based paging can be guaranteed without an adapter that negates its value.
2. License, `rust-version`, N-2 CI, unsafe posture, RustSec status, and Ubuntu/macOS builds are verified.
3. A maintained production adopter is identified.
4. Its response validation rules are proven compatible with empty and concurrently changing collections.
5. The framework extractor still has to be implemented locally, making the net code reduction measurable.

##### Tradeoffs

**Advantages**

- Exact control over a high-value public contract.
- No external pagination-specific dependency or public type.
- No framework choice leaked into the library crate.
- No per-item conversion.
- Strict, testable boundary validation.
- Minimal compile-time and binary-size impact.
- Straightforward OpenAPI adaptation after R71.

**Costs**

- Approximately one small module plus framework-adapter and contract tests must be maintained.
- OpenAPI generators may require an explicit parameter annotation for the custom extractor.
- Route authors must include `PageParams` in every collection handler; Rust’s typed model does not make pagination inputs disappear through global registration.
- Changing field names or paging semantics remains an API migration owned by the template rather than outsourced to a crate.

##### Parameters

Member contract:

```text
query.page = one-based positive integer; default 1
query.size = positive integer; one application-wide default and maximum
response.type = Page<T>
response.required-fields = items, total, page, size, pages
total.type = u64
page.type = u32
size.type = u32
pages.type = u64
oversize-policy = reject
page-beyond-last-policy = successful empty items page
policy-location = root application state
router-registration = forbidden
unsafe = forbidden
```

Proposed compatibility defaults are `size=50` and `max_size=100`; these should become binding only after a golden comparison against the pinned Python service confirms its current contract.

##### Migration implications

- Add `src/web/pagination.rs`.
- Export it from `src/web/mod.rs`.
- Add `PaginationPolicy` to `AppState`.
- Construct that policy once in `src/web/app.rs`.
- Change each collection handler to accept `PageParams`.
- Change each collection response to `Page<DomainType>`.
- Keep repository/service return values as domain objects plus a total, not `Page<T>`.
- Add HTTP, serialization, and compile-fail or constructor-invariant tests.

##### Validation strategy

The member is accepted only after:

- Pure contract tests run on Rust 1.96 and current stable.
- The R69 adapter is tested using an in-memory service.
- Ubuntu and macOS jobs pass.
- HTTP tests prove strict validation and exact response JSON.
- A non-collection route proves no global query middleware is active.
- `cargo deny` passes for the complete selected dependency graph.
- R71’s generated schema contains the parameters and generic response.

These are planned checks; none was executed during this research response.

##### Confidence & re-verify trigger

**Confidence: high on architecture, medium on ecosystem exclusion.**

The architecture follows first-party extractor models and avoids coupling R72 to R69 or R71. Confidence is reduced because the required quantitative crate endpoints were unavailable and no complete local integration was run.

Re-verify when:

- R69 selects the actual framework.
- R71 selects the OpenAPI pipeline.
- The Python dependency version and exact default/maximum values are pinned.
- A dedicated pagination crate reaches 1.0 or documents the exact R72 contract.
- Any shortlisted crate publishes verifiable N-2 and macOS CI.
- Rust stable advances: under the fixed policy, the declared MSRV must move only in a minor template release.

##### Sources

Primary member evidence: S2–S8 and S11–S15, all retrieved September 18, 2026.

### Compatibility

There is no new external R72 crate to prove against another pagination package. Compatibility is instead between ordinary Serde DTOs and the selected framework’s first-party extraction and JSON-response types.

The maintained Axum todo example provides a shared reference composition: Serde-derived query and domain structs, `Query<Pagination>` in the handler, and a JSON response. The current Axum documentation identifies version 0.8.9 and documents generic `Query<T>` extraction. Serde’s current documentation identifies version 1.0.229. [S6, S8, S16; retrieved 2026-09-18] ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.Query.html))

Reference validation matrix:

| Layer | Version/policy | Status |
|---|---|---|
| Rust edition | 2024 | Owner-fixed |
| Current stable | 1.98.1 | Confirmed from Rust release team |
| Current N-2 MSRV | 1.96 | Derived from owner policy |
| Serde reference | 1.0.229 with `derive` | Current documented release |
| Axum reference adapter | 0.8.9 | Representative only; R69 remains open |
| Ubuntu | `ubuntu-latest` | Planned CI |
| macOS | `macos-latest` | Planned CI |
| Windows | Expected for pure types; not required | Not an acceptance platform |

The exact `rs-launch-blueprint` combination has **not yet been compiled**. Acceptance is contingent on the matrix commands below.

### Parameters

```text
owns: none declared in the R72 registry entry

assumes rust-edition = 2024
assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
assumes current rust-version = 1.96
assumes license = MIT OR Apache-2.0
assumes target-os-matrix = ubuntu-latest, macos-latest
assumes R69 web-framework-stack = a framework with typed query/custom-extractor support; no concrete framework value consumed
assumes R70 http-problem-envelope = selected independently
assumes R71 openapi-generation-pipeline = selected independently

CONFLICT: none
```

Rust 1.98.1 was current on September 18, 2026, making 1.96 the current N-2 baseline. Edition 2024’s resolver is Rust-version-aware, but the MSRV job remains necessary because Cargo’s resolver cannot substitute for compiling and testing the complete feature set. [S1–S3; retrieved 2026-09-18] ([blog.rust-lang.org](https://blog.rust-lang.org/releases/latest/))

### Migration implications

1. **`Cargo.toml`**
   - Do not add `paginator-*`, `page-hunter`, or another pagination dependency.
   - Ensure the web package has Serde derive support through the shared dependency table.
   - Declare `edition = "2024"` and current `rust-version = "1.96"`.
   - Keep `resolver = "3"` explicit in a virtual workspace if necessary.

2. **`src/web/pagination.rs`**
   - Add `PaginationPolicy`.
   - Add private raw query DTO.
   - Add validated `PageParams`.
   - Add checked `limit()` and `offset()`.
   - Add generic `Page<T>`.
   - Add unit tests for defaults, zero values, maximum size, overflow, empty totals, and page-count arithmetic.

3. **R69-specific web adapter**
   - Implement the selected framework’s request-parts/request extractor.
   - Obtain `PaginationPolicy` from shared application state.
   - Map failures into an intermediate rejection consumed by R70.
   - Add the R71 parameter/schema derive only after R71 resolves.

4. **`src/web/app.rs`**
   - Construct `PaginationPolicy` once.
   - Store it in `AppState` or the framework’s equivalent application data.
   - Do not add pagination middleware.
   - Do not expose `add_pagination` or router installation APIs.

5. **`src/web/routers/projects.rs` and every collection router**
   - Add one `PageParams` handler argument.
   - Convert it to an application-layer `ListWindow`.
   - Return `Page<Project>`.
   - Remove direct `Vec<Project>` collection responses.
   - Keep `Project` unchanged.

6. **Application and repository layer**
   - Accept a framework-neutral window such as `{offset, limit}`.
   - Return domain items and exact total.
   - Do not return or import the web `Page<T>` type.

7. **Tests**
   - Add `tests/http_pagination.rs`.
   - Add a route inventory test or lint-like source check ensuring all collection routes use the standard types.
   - Add a composition-root test proving one policy instance and no router-local pagination setup.
   - Add OpenAPI golden checks after R71.

### Validation strategy

**Executed during research:** documentation, source-manifest, framework-example, and candidate-API inspection only.

**Not executed:** compilation, tests, benchmarks, security scans, binary analysis, or live HTTP requests.

#### MSRV and stable validation

```bash
rustup toolchain install 1.96.0
rustup update stable

cargo +1.96.0 check --workspace --all-targets --all-features
cargo +1.96.0 test  --workspace --all-targets --all-features

cargo +stable check --workspace --all-targets --all-features
cargo +stable test  --workspace --all-targets --all-features
cargo +stable clippy --workspace --all-targets --all-features -- -D warnings
cargo +stable fmt --all --check
```

Expected: all commands succeed on both `ubuntu-latest` and `macos-latest`.

#### Dependency and safety validation

```bash
cargo tree --workspace --all-features
cargo deny check advisories bans licenses sources
cargo geiger --all-features
```

Expected:

- No pagination-specific dependency appears.
- No open advisory in the complete tree.
- License policy passes.
- The local web-pagination module contains no unsafe code.
- Any transitive unsafe is documented at the broader stack decision that owns it.

#### Contract unit tests

```bash
cargo test -p rs-launch-blueprint-web pagination::
```

Expected test cases:

- Missing query → page 1 and configured default size.
- `page=2&size=25` → offset 25, limit 25.
- `page=0`, `size=0`, non-numeric values, and size above maximum → rejection.
- Offset multiplication overflow → rejection before service invocation.
- `total=0` → `pages=0`.
- `total=51,size=50` → `pages=2`.
- `Page<Project>` serializes project fields directly inside `items`.

#### HTTP acceptance test

```bash
cargo test -p rs-launch-blueprint-web --test http_pagination
```

Representative assertions:

```bash
curl -fsS 'http://127.0.0.1:3000/projects?page=2&size=2' |
  jq -e '
    .page == 2 and
    .size == 2 and
    .total == 5 and
    .pages == 3 and
    (.items | length) == 2 and
    (.items[0] | has("id"))
  '
```

Expected: success with the exact standard envelope.

```bash
test "$(curl -sS -o /tmp/body -w '%{http_code}' \
  'http://127.0.0.1:3000/projects?page=0&size=20')" = 400
```

Expected: the R70-selected validation status and problem envelope; repository call count remains zero.

```bash
curl -fsS 'http://127.0.0.1:3000/health?page=bad&size=bad'
```

Expected: health remains successful, proving no indiscriminate global pagination middleware.

#### Uniformity checks

```bash
rg -n 'PageParams' src/web/routers
rg -n 'Page<' src/web/routers
rg -n 'PaginationPolicy' src/web
rg -n 'add_pagination|PaginationLayer|pagination_layer' src/web
```

Expected:

- Every collection route contains `PageParams` and `Page<...>`.
- `PaginationPolicy` is constructed in the composition root and read by the adapter.
- No router-local registration or global parsing middleware exists.

A stronger long-term check should use a route inventory generated by R69/R71 rather than relying only on text search.

#### Performance and resource check

```bash
cargo build --release --timings
cargo bloat --release -p rs-launch-blueprint-web --crates

oha -z 60s -c 64 \
  'http://127.0.0.1:3000/projects?page=1&size=50'

oha -z 60s -c 64 \
  'http://127.0.0.1:3000/projects?page=190&size=50'
```

Instrument:

- p50/p95/p99 response latency.
- Throughput.
- Count-query and page-query duration.
- Queries per request.
- Response bytes.
- Linux maximum RSS with `/usr/bin/time -v`.
- macOS maximum RSS with `/usr/bin/time -l`.
- Clean and one-file incremental build duration.
- Release binary size.

Run the same repository and dataset for any future crate comparison. Do not compare unlike database engines, page sizes, build profiles, or tracing configurations.

#### OpenAPI acceptance after R71

```bash
cargo test -p rs-launch-blueprint-web --test openapi_pagination
```

Expected for every collection operation:

- Query parameters named `page` and `size`.
- Correct minimum/default/maximum values.
- A concrete response schema equivalent to `Page<Project>`.
- `items` references the ordinary `Project` schema.
- No duplicate response components caused by router-level registration.

### Confidence & re-verify trigger

**Overall confidence: 0.82.**

- **0.92** that Rust’s typed-extractor model favors an explicit reusable handler extractor over a FastAPI-style global registry.
- **0.90** that a local generic envelope best preserves the library/web boundary.
- **0.75** that no external candidate should be adopted now, reduced by unavailable endpoint-derived maintenance and adoption figures.
- **0.65** on the proposed default size and maximum until compared against the pinned Python dependency.
- **0.60** on OpenAPI ergonomics until R71 chooses its generator.

Mandatory re-verification triggers:

1. R69 selects a framework without an application-state-aware custom extractor.
2. R71 selects an OpenAPI generator that cannot describe the custom extractor or generic response without route duplication.
3. The pinned Python route reveals different defaults, indexing, or response metadata.
4. A pagination crate publishes an exact contract with `rust-version`, N-2 CI, macOS CI, RustSec clearance, and credible production adopters.
5. The template’s minor release advances the N-2 MSRV.
6. Exact crates.io/GitHub/RustSec endpoint collection becomes available; rerun the quantitative candidate audit before final ledger closure.

### Sources

- **O1 — Python route precedent:** `src/py_launch_blueprint/web/routers/projects.py:30`, supplied in the owner prompt.
- **O2 — Python app registration:** `src/py_launch_blueprint/web/app.py:204`, supplied in the owner prompt.
- **O3 — Commonality ledger:** `docs/port/COMMONALITY.md`, F310/F311, supplied in the owner prompt.
- **O4 — Fixed parameters:** `docs/port/PARAMETERS.md`, owner-decided September 2, 2026, supplied in the owner prompt.

- **S1 — Rust current release and release notes:**  
  `https://blog.rust-lang.org/releases/latest/`  
  `https://doc.rust-lang.org/releases.html`  
  Retrieved 2026-09-18. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/latest/))

- **S2 — Cargo `rust-version`:**  
  `https://doc.rust-lang.org/cargo/reference/rust-version.html`  
  Retrieved 2026-09-18. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/rust-version.html))

- **S3 — Edition 2024 Rust-version-aware resolver:**  
  `https://doc.rust-lang.org/edition-guide/rust-2024/cargo-resolver.html`  
  `https://doc.rust-lang.org/cargo/reference/resolver.html`  
  Retrieved 2026-09-18. ([doc.rust-lang.org](https://doc.rust-lang.org/edition-guide/rust-2024/cargo-resolver.html))

- **S4 — Rust API Guidelines:**  
  `https://rust-lang.github.io/api-guidelines/dependability.html`  
  `https://rust-lang.github.io/api-guidelines/checklist.html`  
  `https://rust-lang.github.io/api-guidelines/necessities.html`  
  Retrieved 2026-09-18. ([rust-lang.github.io](https://rust-lang.github.io/api-guidelines/dependability.html))

- **S5 — Rust surveys:**  
  `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`  
  `https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/`  
  Retrieved 2026-09-18. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))

- **S6 — Axum query extractor:**  
  `https://docs.rs/axum/latest/axum/extract/struct.Query.html`  
  Retrieved 2026-09-18. ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.Query.html))

- **S7 — Actix Web extractors:**  
  `https://actix.rs/docs/extractors/`  
  Retrieved 2026-09-18. ([actix.rs](https://actix.rs/docs/extractors/))

- **S8 — Official Axum todo pagination example:**  
  `https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs`  
  Retrieved 2026-09-18. ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs))

- **S9 — crates.io Axum and Utoipa production usage:**  
  `https://blog.rust-lang.org/2025/02/05/crates-io-development-update/`  
  Retrieved 2026-09-18. ([blog.rust-lang.org](https://blog.rust-lang.org/2025/02/05/crates-io-development-update/))

- **S10 — Axum project:**  
  `https://github.com/tokio-rs/axum`  
  Retrieved 2026-09-18. ([github.com](https://github.com/tokio-rs/axum))

- **S11 — `paginator-rs` / `paginator-axum` 0.4.0:**  
  `https://docs.rs/crate/paginator-axum/0.4.0/source/README.md`  
  `https://docs.rs/crate/paginator-axum/0.4.0/source/Cargo.toml`  
  `https://github.com/maulanasdqn/paginator-rs`  
  Retrieved 2026-09-18. ([docs.rs](https://docs.rs/crate/paginator-axum/0.4.0/source/Cargo.toml))

- **S12 — `page-hunter` 0.7.0:**  
  `https://docs.rs/page-hunter`  
  `https://github.com/JMTamayo/page-hunter`  
  Retrieved 2026-09-18. ([docs.rs](https://docs.rs/page-hunter))

- **S13 — `autumn-web` pagination and 0.7.0 package:**  
  `https://docs.rs/autumn-web/latest/src/autumn_web/pagination.rs.html`  
  `https://docs.rs/crate/autumn-web/latest`  
  Retrieved 2026-09-18. ([docs.rs](https://docs.rs/autumn-web/latest/src/autumn_web/pagination.rs.html))

- **S14 — `axum-api-kit` pagination:**  
  `https://docs.rs/axum-api-kit/latest/src/axum_api_kit/pagination.rs.html`  
  `https://docs.rs/crate/axum-api-kit/1.0.0/source/README.md`  
  Retrieved 2026-09-18. ([docs.rs](https://docs.rs/axum-api-kit/latest/src/axum_api_kit/pagination.rs.html))

- **S15 — Loco pagination response convention:**  
  `https://loco.rs/docs/extras/upgrades/`  
  Retrieved 2026-09-18. ([loco.rs](https://loco.rs/docs/extras/upgrades/))

- **S16 — Serde 1.0.229:**  
  `https://docs.rs/serde/latest/serde/`  
  Retrieved 2026-09-18. ([docs.rs](https://docs.rs/serde/latest/serde/))

## Sources

- [https://docs.rs/axum/latest/axum/extract/struct.Query.html](https://docs.rs/axum/latest/axum/extract/struct.Query.html)
- [https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs)
- [https://docs.rs/crate/paginator-axum/0.4.0/source/README.md](https://docs.rs/crate/paginator-axum/0.4.0/source/README.md)
- [https://blog.rust-lang.org/releases/latest/](https://blog.rust-lang.org/releases/latest/)
- [https://rust-lang.github.io/api-guidelines/dependability.html](https://rust-lang.github.io/api-guidelines/dependability.html)
- [https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/)
- [https://blog.rust-lang.org/2025/02/05/crates-io-development-update/](https://blog.rust-lang.org/2025/02/05/crates-io-development-update/)
- [https://github.com/JMTamayo/page-hunter](https://github.com/JMTamayo/page-hunter)
- [https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/](https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/)
- [https://docs.rs/crate/paginator-axum/0.4.0/source/Cargo.toml](https://docs.rs/crate/paginator-axum/0.4.0/source/Cargo.toml)
- [https://docs.rs/crate/autumn-web/latest](https://docs.rs/crate/autumn-web/latest)
- [https://docs.rs/axum-api-kit/latest/src/axum_api_kit/pagination.rs.html](https://docs.rs/axum-api-kit/latest/src/axum_api_kit/pagination.rs.html)
- [https://doc.rust-lang.org/cargo/reference/rust-version.html](https://doc.rust-lang.org/cargo/reference/rust-version.html)
- [https://doc.rust-lang.org/edition-guide/rust-2024/cargo-resolver.html](https://doc.rust-lang.org/edition-guide/rust-2024/cargo-resolver.html)
- [https://actix.rs/docs/extractors/](https://actix.rs/docs/extractors/)
- [https://github.com/tokio-rs/axum](https://github.com/tokio-rs/axum)
- [https://docs.rs/page-hunter](https://docs.rs/page-hunter)
- [https://docs.rs/autumn-web/latest/src/autumn_web/pagination.rs.html](https://docs.rs/autumn-web/latest/src/autumn_web/pagination.rs.html)
- [https://loco.rs/docs/extras/upgrades/](https://loco.rs/docs/extras/upgrades/)
- [https://docs.rs/serde/latest/serde/](https://docs.rs/serde/latest/serde/)