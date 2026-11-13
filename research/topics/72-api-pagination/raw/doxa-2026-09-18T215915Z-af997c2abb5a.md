# R72 — Doxa engine report (three providers, regrouped by template field)

Normalization record: Doxa operation research-20260918-150431-3cb17a06c88b457a (all_deep_research) returned one report per provider. This file regroups the three answer bodies under the prompt's template fields so the single-report shape check applies; within each field the three provider sections appear in the order OpenAI, Perplexity, Gemini, each introduced by a bold label, and under `### Members` every provider's members are kept with the provider name appended to the member heading. Every content line of each provider's answer body is preserved (the originals are the three saved files under the run's doxa/ directory; raw/doxa-<provider>.normalized.md hold the bodies individually). Headings that would fall outside the template are demoted to bold text so no heading outside the template remains; doxa/normalization.json lists every other adjustment.

**Provider preambles (text preceding each provider's first template field)**

**OpenAI (gpt-5.6-sol)**

**Reasoning Summary**
**Researching extensive metrics**

I need to conduct extensive research, ensuring I have exact headings and source URLs with retrieval dates. The current date is specified as September 18, 2026, which I must be careful to reference. Since the user mentioned September 4, 2026, I should focus my research accordingly. I need to use the web thoroughly, identifying pagination crates that can integrate with leading async web frameworks, especially something like Axum. Time to initiate broad search queries!

**Perplexity (sonar-deep-research)**

**R72: Pagination bundle for `rs-launch-blueprint`**

The pagination decision for `rs-launch-blueprint` sits at the intersection of cross‑language commonality, Rust’s typed web ecosystem, and the template’s three‑surface scope (CLI, library, web service). The Python port already establishes a precedent of page/size query‑parameter pagination with a generic items/total response envelope, wired once app‑wide via a single factory call, and keeping collection elements as pure domain objects with only the wrapper being web‑specific.[Context] The Rust ecosystem offers several pagination crates and architectural patterns, but none is a universal, first‑party analogue of FastAPI’s `fastapi-pagination`. Instead, we find a small cluster of multi‑framework libraries (notably the **paginator‑rs** family), framework‑specific extractors (such as **actix‑web‑pagination**), envelope‑focused primitives (such as **api_bones::pagination::PaginatedResponse**), and lower‑level pagination helpers (such as **use‑pagination** and **paging_stream**).[10][12][18][21][9] After surveying this landscape and weighing authority, practice, and fit, the recommendation is that `rs-launch-blueprint` should adopt a **pagination bundle centered on the `paginator-rs` ecosystem**, using its framework integration crate for whatever web framework R69 selects, and pairing that with a generic response envelope that preserves domain models. This bundle enables page/size query extraction via framework‑native extractors, a uniform items/total metadata contract, and app‑wide registration of pagination defaults and response behavior, thereby aligning Rust with the Python precedent while respecting Rust’s strongly typed, multi‑framework ecosystem.

**R72: API pagination decision**

**Gemini (deep-research-preview-04-2026)**

**Deep-Research Report: API Pagination Architecture and Implementation (R72)**

### Landscape

**OpenAI**

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

**Perplexity**

The category this item decides is **API pagination for Rust web services**, specifically the combination of query‑parameter extractors and response envelopes that every collection‑returning route will use. At a structural level, this landscape separates into three bins: Rust’s built‑in or first‑party toolchain support; **established industry standards** in the ecosystem; and **up‑and‑comers** that are gaining adoption but are not yet canonical.

In the **built‑in / first‑party toolchain** bin, Rust itself and the core web frameworks provide the foundational primitives but not a complete, FastAPI‑like pagination stack. The axum web framework, for example, exposes a `Query<T>` extractor that deserializes URL query strings into typed structs using `serde`, allowing developers to define a `Pagination` struct with `page` and `per_page` fields and have axum populate it automatically from query parameters like `?page=2&per_page=30`.[45] This mechanism is illustrated both in the official axum documentation and in community examples that define `Pagination` or `PaginationParams` structs and compute offsets for database queries based on page and per_page values.[16][16][45] Similarly, web frameworks such as Actix Web natively support extractors and application data registration, but leave pagination as a user‑space concern. The Actix ecosystem’s `actix-web-pagination` crate implements a `Pagination` extractor that integrates with Actix’s request handling model, but this crate is external rather than first‑party.[10][11][11]

The **established industry standard** bin comprises widely referenced pagination patterns and libraries that have clear evidence of production use and community endorsement. In the broader Rust ecosystem, the **crates.io Registry Web API** sets a de facto standard for query‑parameter pagination: the `/api/v1/crates` endpoint accepts `q`, `page`, and `per_page` parameters, returns a list of crates plus a `meta` object, and exposes fields such as `total` and `next_page` to indicate overall count and continuation.[19][41][42] This pattern—page/per_page query parameters coupled with an items list and total count metadata—is echoed in documentation aggregators like DeepWiki’s crates.io API reference and in scraping tooling such as Apify’s “Crates.io Scraper”, which explicitly supports modes that paginate across the full registry.[20][29][40] Another strong reference is the **Warp Enterprise Analytics API**, which exposes paginated users and events endpoints with `page` and `page_size` parameters, and returns both per‑page items and a `pagination` block containing `current_page`, `page_size`, `total_pages`, and `total_count`.[7] This shows that in practice, well‑regarded Rust services adopt page/size plus items/total patterns even when they define their own envelopes.

Within **industry‑standard pagination libraries**, several categories emerge. `actix-web-pagination` provides a `Pagination` extractor and a `PaginationConfig` that can be registered via `App::data` to configure default items per page across the application, such as `default_per_page(50)`.[10][11][10][10] SQL‑related crates like **sea‑orm** and **sqlx-paginated** treat pagination at the database query layer: SeaORM’s `Paginator` fetches pages of results using `LIMIT`/`OFFSET` and exposes helper methods such as `fetch_page` and `num_pages`.[47][13][13] SQLx‑paginated wraps SQLx with a dynamic query builder that supports pagination parameters (`page`, `page_size` with defaults and bounds), sorting, filtering, and date range parameters.[23][23][27] High‑profile services such as AWS adopt paginator abstractions in their Rust SDK: a general RFC describes modeling paginated data as a `Stream` of output shapes, with a generated `<OperationName>Paginator` struct in a `paginator` module and a `paginate()` method that exposes a `Stream` of results.[25][25] Service‑specific paginator implementations (for example, Panorama’s `ListApplicationInstanceNodeInstancesPaginator`) follow this pattern, flattening results across pages into an iterator or stream.[34][39][34] These references are authoritative because they are maintained by the Rust project ecosystem (crates.io), major infrastructure providers (AWS), and widely used database libraries (SeaORM, SQLx), all of which have strong adoption and rigorous documentation.

The **up‑and‑comer** bin contains libraries that aim to provide multi‑framework, ergonomic pagination support, often with more modern idioms and flexible metadata. The **paginator‑rs** ecosystem is a central example: its core crate describes itself as “a comprehensive, modular Rust pagination library with support for multiple databases and web frameworks,” emphasizing flexible page‑based and offset/limit pagination, ergonomics, performance, and maintainability.[12][12][12][35] Satellite crates include `paginator-utils` for reusable data structures,[35][35] and integration crates such as `paginator-axum` and `paginator-actix` that provide query extractors and JSON responders tailored to axum and Actix Web respectively.[24][31][15][15] The `paginator-axum` documentation describes a `PaginationQuery` extractor that parses query parameters including `page` and `per_page`, and a `PaginatedJson` responder that serializes responses and adds pagination headers according to RFC 8288.[15][15][38][15] Another up‑and‑comer is the **api_bones::pagination** module, which defines a generic `PaginatedResponse<T>` struct with fields `items: Vec<T>`, `total_count: u64`, `has_more: bool`, `limit: u64`, and `offset: u64`, and a constructor that sets `has_more` based on whether `offset + items.len() < total_count`.[9][9][9][9][9] This envelope type is explicitly designed for offset‑based paginated list endpoints and offers a flat JSON shape where items remain domain objects and metadata is centralized. It is complemented by a `CursorPagination` struct for cursor‑based pagination, with fields `has_more: bool` and `next_cursor: Option<String>`.[14][14] Finally, **use-pagination** offers “pagination primitives for RustUse,” including `PageNumber`, `PageSize`, `PageMarker`, `PageInfo`, and `PaginationDirection`, and explicitly states its scope as small validated types with stable display labels and conservative parsing, under MIT or Apache‑2.0 licensing.[18][18][18]

Authority in this landscape is **established**, not assumed, by triangulating multiple sources. The Rust project’s own documentation on crates.io’s API and pagination semantics is considered authoritative because it defines the canonical registry interface used by Cargo.[20][30][19][41][42] Web framework documentation (such as axum’s `Query` extractor docs) is authoritative for extractor behavior.[45] Major library documentation from SeaORM, AWS’s Rust SDK, and Warp’s APIs is authoritative because these projects have broad community usage, transparent version histories, and rigorous testing.[7][2][25][34][47] Independent write‑ups like RustFAQ’s guides on implementing pagination in Axum and MOS templates describing Rust REST APIs are practice‑oriented and well cited, but they are treated as leads rather than primary authority.[16][16][33] Likewise, blog posts on wrapping Axum and SQLx with a generic `PaginatedResult<T>` structure demonstrate realistic patterns but are not themselves canonical.[50]

Practice evidence involves surveying what **mainstream, well‑regarded Rust projects** actually do. The **crates.io** service uses page/per_page query parameters and returns items and total metadata along with a `next_page` link, demonstrating a production‑grade pattern that matches the template’s desired behavior.[19][41][42] **Warp**’s Enterprise Analytics API uses offset‑based pagination with page and page_size, and a `pagination` block containing current_page, page_size, total_pages, and total_count in every paginated response, thereby aligning with page/size plus items/total semantics.[7] **SeaORM** provides a `Paginator` abstraction that developers commonly wrap in higher‑level response envelopes like `ManyResponse<Model>`, which includes fields `data`, `count`, `total`, `page`, and `page_count`, illustrating how items remain domain objects while metadata is layered in a web‑specific wrapper.[26][26][26][47] The **Diesel** project’s advanced blog CLI example includes pagination code that computes offsets and exposes pagination to the CLI, again using page and page size semantics at the data layer.[36] AWS’s Rust SDK uses paginator abstractions extensively across services like Panorama, modeling pagination as streams of output shapes and letting clients consume paginated results via generated paginator types.[2][34][25][34] Finally, web application templates leveraging Axum and MongoDB or Actix Web show patterns where pagination structs are used to compute database offsets and wrapped in response envelopes with page/size and total metadata.[16][17][32][49][50] These projects are well regarded due to active maintenance, community adoption (evident from reverse dependencies and references), and their roles in significant ecosystems (database ORMs, official SDKs, registry services).

Fit is judged **relative to `rs-launch-blueprint`**, not in abstraction. The template must support a CLI and a library layer in addition to the web service, so any pagination solution must avoid tying core objects to web‑specific types. It must honor the owner’s parameters: Rust edition 2024, stable MSRV minus two minor versions, MIT or Apache‑2.0 licensing, and CI coverage for Ubuntu and macOS.[PARAMETERS] It must align with the Python port’s precedent of a generic pagination envelope and app‑wide pagination registration, while not over‑constraining R69’s choice of web framework. This points away from frameworks that bake pagination into monolithic types and toward **framework‑agnostic pagination primitives and envelopes** paired with **small per‑framework integration crates** that implement extractors and responders. Within this landscape, the **paginator‑rs ecosystem** and the **api_bones::pagination** envelope stand out as up‑and‑coming solutions tailored to multi‑framework use, while axum’s and Actix’s native extractors and configuration capabilities provide the foundation necessary to emulate FastAPI’s `add_pagination(app)` semantics.[10][15][9][45]

**Gemini**

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

**OpenAI**

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

**Perplexity**

The shared requirement arises from the **commonality mandate** across the Python and Rust ports. In Python, the FastAPI integration uses `fastapi-pagination` to apply page/size query parameters and a `Page[T]` response envelope app‑wide, via an `add_pagination(app)` call that registers pagination once and then allows each route to simply declare `Page[Model]` as the return type while keeping the items themselves as domain objects from `core.models`.[Context] The principle here is that pagination is a **cross‑cutting capability** governed at the architectural pattern level: every collection‑returning endpoint should share the same pagination contract, and this contract should be configured centrally, not per route. Agreement is required at the level of capability and pattern: page/size query semantics, items/total metadata envelope, and app‑wide registration. Detailed implementation choices (such as exact field names, cursor versus offset options, and HTTP header usage) may vary between ecosystems so long as they preserve the principle that pagination logic is not duplicated per route and does not contaminate core domain models.

The **essential behaviors** for the Rust template are, therefore, as follows. First, all list endpoints must accept **page** and **page_size** (or `per_page`) query parameters that can be parsed by the selected web framework’s extractor mechanism. Axum supports this via `Query<Pagination>` structs; community examples show `Pagination { page: usize, per_page: usize }` deserialized from query strings.[16][16][45] Actix Web supports extraction via **actix-web-pagination**’s `Pagination` extractor, which reads pagination parameters from HTTP requests and uses `PaginationConfig` to determine defaults such as items per page.[10][11][11][10] Second, responses must wrap items in a **generic envelope** that includes an items vector and total metadata, typically fields such as total_count, limit, and offset; `api_bones::pagination::PaginatedResponse<T>` demonstrates a canonical shape for this, with `items: Vec<T>`, `total_count: u64`, `has_more: bool`, `limit: u64`, and `offset: u64`.[9][9][9][9][9] Third, the pagination machinery—including default page sizes, maximum bounds, and possibly header conventions—should be registered or configured **once app‑wide**, analogous to FastAPI’s `add_pagination(app)`. This is achievable in Rust via application data or state: Actix’s example registers `Pagination::config().default_per_page(50)` via `App::data`, which then applies to all routes using the `Pagination` extractor.[10][11][10][10] The `paginator-axum` crate similarly suggests a central `PaginationParams` configuration that is applied via its extractors and responders.[15][15]

Observable **acceptance criteria** for this decision can be articulated as follows. Every collection‑returning endpoint in `rs-launch-blueprint` should have the same handler signature pattern: a domain‑specific query or filter and a **pagination parameter type**, with page/size validated and defaulted consistently. The response type should expose a generic **Paginated<T>** envelope with a `Vec<T>` and pagination metadata, where `T` is always a domain model object (for example, a `Project` from the core library), not a web wrapper.[9][9][26] Pagination defaults and constraints (such as maximum page_size) should be declared once at the composition root and reused automatically, rather than re‑specified per route. Finally, the bundle should support at least two pagination strategies—simple offset‑based page/size for bounded lists, and cursor‑based pagination where required—mirroring `api_bones`’ offset‑based `PaginatedResponse` and `CursorPagination` types.[14][14][9] These acceptance criteria are observable via API behavior, test coverage, and OpenAPI schema generation (which R71 will own).

Before choosing libraries, we must compare **architectural alternatives**. One alternative is a **manual pattern**: define a local `PaginationParams` struct for page/per_page, implement validation and offset computation, and declare a generic `Paginated<T>` struct in the template’s web layer, much like the RustFAQ guides and Axum+SQLx blog examples that define `PaginatedResponse<T>` and validate pagination constraints.[16][16][50] This approach minimizes dependencies but requires per‑project boilerplate and still leaves per‑route pagination wiring unless additional infrastructure is built. Another alternative is to adopt **framework‑specific pagination crates** such as `actix-web-pagination` and design the template around the chosen web framework. `actix-web-pagination` offers pagination extraction, configuration via `PaginationConfig`, and a reusable `Pagination` type, but it ties the template to Actix Web and lacks a generic envelope type, requiring an additional envelope layer.[10][11][11][10] A third alternative is to use **multi‑framework pagination ecosystems** such as `paginator-rs` combined with `paginator-axum` or `paginator-actix`, which provide unified pagination primitives, query extractors, and JSON responders that can be wired app‑wide across different technologies.[12][24][31][15][15] Finally, **database‑centric pagination tools** like SeaORM’s `Paginator` and `sqlx-paginated` treat pagination at the query builder level, which is valuable but insufficient for shaping the HTTP envelope and web‑level contract.[23][23][47][27]

The recommended design must preserve each principle while accommodating differences between ecosystems. The Python port’s `fastapi-pagination` relies on dynamic typing and runtime introspection; Rust cannot mirror this exactly due to generics and trait bounds. Instead, we can use a design where the **core pagination primitives and envelope types live in a library crate**, independent of any web framework, and the web service composes them with framework‑native extractors. Up‑and‑coming crates like `use-pagination` and `api_bones::pagination` are designed precisely for this purpose: they provide validated page numbers, page sizes, and response envelopes without coupling to any HTTP stack.[18][9][18] Multi‑framework ecosystems like `paginator-rs` extend this by adding framework‑specific query extractors and responders, which can be registered in the app’s composition root to emulate FastAPI’s `add_pagination(app)` behavior.[12][15][15] Production usage in newer projects demonstrates that this approach yields ergonomic, maintainable APIs; for example, using `PaginatedJson` responders and `PaginationQuery` extractors in axum reduces per‑route boilerplate and standardizes pagination semantics across endpoints.[15][15] Thus, the Rust ecosystem requires a slightly different shape—a combination of a core, framework‑agnostic pagination library and a thin framework‑specific integration crate—but this design continues to satisfy the shared principle of centralized pagination configuration and domain‑pure items.

From a **performance** and **integration cost** perspective, the bundle must not impose heavy binary‑size or compile‑time penalties relative to manual patterns. Core crates like `use-pagination` and `api_bones::pagination` are dependency‑light and largely consist of small structs and helper functions.[18][9][18] Multi‑framework ecosystems like `paginator-rs` are designed with performance and ergonomics in mind, and focus on flexible pagination rather than heavy runtime features.[12][12] Database‑centric pagination crates like `sqlx-paginated` and SeaORM’s `Paginator` may add compile‑time cost due to SQLx type checking and ORM abstractions, but these are necessary for database safety and are orthogonal to the HTTP envelope.[23][47][27] Integration cost is primarily in wiring: the bundle will require adding one or more pagination crates to `Cargo.toml`, defining a shared pagination configuration in the composition root, and updating route signatures to use pagination extractors and envelope types. These changes are well scoped and can be validated via integration tests and OpenAPI generation.

A minimal realistic **example** for acceptance would use axum as the web framework (for concreteness in R72, while R69 retains the right to choose differently). It would define a `PaginationQueryParams` type using `paginator-axum`’s query extractor, configure default `page` and `per_page` values at application startup, and implement a handler returning a `PaginatedResponse<Project>` envelope from `api_bones::pagination`, where `Project` is a domain model type. The handler would receive `PaginationQueryParams` via axum’s `Query` extractor, translate `page` and `per_page` into `limit` and `offset`, query the database via a paginator (either SeaORM’s `Paginator` or `sqlx-paginated`), and construct `PaginatedResponse<T>::new(items, total_count, &params)`.[16][23][9][47] An executable acceptance check would enforce that every collection route in the template uses the same pagination parameter type and envelope, that pagination metadata is consistent across endpoints, and that the composition root contains a single pagination configuration path. These checks are proposed and must be implemented in CI and integration tests; they are not yet executed.

Critically, this decision triggers a **baseline review**:  

**BASELINE-REVIEW: F311 — app-wide pagination wiring — proposed change: adopt a Rust pagination bundle combining `paginator-rs` and a generic PaginatedResponse envelope, registered once at the composition root — evidence: FastAPI’s `add_pagination(app)` pattern in Python, crates.io’s page/per_page plus total metadata contract, Warp’s pagination block, and the `paginator-rs` ecosystem’s multi‑framework design and `PaginationQuery`/`PaginatedJson` behavior.**[7][20][9][15]

**Gemini**

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

**OpenAI**

**Adopt `R72 Native Pagination Contract v1`: no external pagination crate.**

Stack:

- **R72-owned member:** local `web::pagination::{PaginationPolicy, PageParams, Page<T>}`.
- **Serialization substrate:** `serde 1.0.229`, expected to already be part of the web stack.
- **Extractor substrate:** the first-party query/custom-extractor API of whichever framework R69 selects.
- **Maintained executable reference:** `axum 0.8.9` with `Query<T>`/`FromRequestParts`; this is a reference spike, not an R69 decision.
- **New R72 dependencies:** none.

The contract is `page`/`size`, one-based pages, bounded strict validation, and a generic `Page<T>` containing unmodified domain objects under `items` and exact `total`. Pagination policy is constructed once in application state; each collection handler explicitly requests the reusable extractor.

**Perplexity**

The recommendation is that `rs-launch-blueprint` **does adopt a Rust pagination bundle** that provides page/size query‑parameter extraction and a generic items/total response envelope, registered once app‑wide. The dominant choice for this bundle is the **paginator‑rs ecosystem**, specifically:

1. The core `paginator-rs` crate for pagination primitives and metadata.[12][12][12]  
2. The `paginator-utils` crate for reusable data structures and pagination metadata sharing between the library and web layers.[35][35]  
3. The appropriate framework integration crate (such as `paginator-axum` or `paginator-actix`) for `rs-launch-blueprint`’s chosen web framework, providing a `PaginationQuery` extractor and `PaginatedJson` responder wired via a single configuration call in the composition root.[24][31][15][15]

Because none of these crates, in the evidence provided, defines a body envelope identical to FastAPI’s `Page[T]`, the bundle should be complemented by a **generic PaginatedResponse<T> envelope**, either using `api_bones::pagination::PaginatedResponse<T>` or an equivalent type implemented within `rs-launch-blueprint` that mirrors its shape.[9][9][9][9][9] This preserves the principle that items remain domain objects while metadata is web‑specific and layered in a wrapper.

Concretely, the web service in `rs-launch-blueprint` should define a `configure_pagination` function in its composition root, which registers `paginator-rs`’s pagination configuration and the integration crate’s extractors and responders once app‑wide. Routes will then declare a standard pagination parameter type (for example, `PaginationQueryParams` or `Pagination`) and return `PaginatedResponse<T>` where `T` is a domain type. This architecture matches Python’s pattern of app‑wide registration, domain‑pure items, and standardized pagination semantics, while using Rust’s idiomatic crates and typed extractor mechanisms.

**Gemini**

The recommended stack is the **`paginator-rs` ecosystem bundle**, utilizing `paginator-rs` (core trait and database generation logic), `paginator-utils` (shared models), and `paginator-axum` (web framework integration). 

### Members

**OpenAI**

#### Native typed pagination adapter v1 (OpenAI)

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

**Perplexity**

#### paginator-rs (Perplexity)

##### Landscape

`paginator-rs` is a **multi‑framework pagination library** that positions itself as a comprehensive, modular solution for pagination with support for multiple databases and web frameworks, emphasizing ergonomics, performance, and maintainability.[12][12][12][35] Its documentation highlights flexible pagination, including both page‑based and offset/limit modes, and its ecosystem includes associated crates like `paginator-utils`, `paginator-axum`, `paginator-actix`, and `paginator-rocket`.[24][31][35][35] The crate is listed on lib.rs with several releases, including version `0.2.2` dated December 25, 2025, and earlier versions such as `0.1.2` from May 7, 2025, indicating ongoing development and refinement.[12][12][12][35] This release history suggests an active project that has matured beyond an initial prototype and is iterating on features and compatibility.

Located in the **up‑and‑comer** bin, `paginator-rs` aims to standardize pagination behavior across different web frameworks and data stores. It is not a first‑party Rust project, but its cross‑framework focus and modular design have led to adoption in at least six other crates, according to reverse dependency information on lib.rs.[12][12][35] The ecosystem includes specific integration crates like `paginator-axum`, `paginator-actix`, and `paginator-rocket`, each providing bridge code between the core pagination logic and a specific web framework.[24][31][15][15] This modularity aligns well with `rs-launch-blueprint`’s need to stay agnostic to R69’s web framework choice while still having a clear pagination contract.

Authoritative sources for `paginator-rs` include its own documentation pages on lib.rs, which describe the crate’s features and design goals, and the documentation for its integration crates, which detail how query parameters are parsed and how JSON responses are shaped.[12][15][15][15] These sources are authoritative because they come directly from the crate maintainers, reflect the current public API, and are hosted on widely trusted documentation platforms such as docs.rs and lib.rs. Additional authority comes indirectly from the patterns described in the RustFAQ guides and Axum examples, which rely on similar concepts of page and per_page query parameters and paginated JSON responses.[16][16]

Mainstream practice evidence for `paginator-rs` is more limited than for long‑standing projects like SeaORM or AWS’s Rust SDK, but the ecosystem’s design closely mirrors the proven patterns from those projects. For example, its `PaginationQuery` extractor and `PaginatedJson` responder for axum echo the pattern of typed query extraction and standardized pagination envelopes found in manual Axum implementations and tools like `sqlx-paginated`.[23][15][15][50] The presence of integration crates for multiple frameworks suggests that developers have used `paginator-rs` in mixed environments and found value in a unified pagination contract.

##### Principles and implementation

The design of `paginator-rs` is explicitly aligned with the principle of **framework‑agnostic pagination**. Its core crate focuses on pagination primitives—such as page numbers, page sizes, and offset/limit computation—that can be used independent of any specific web framework or database.[12][12][35][35] This allows `rs-launch-blueprint`’s library layer to adopt the same pagination semantics as the web service, satisfying the template’s cross‑surface commonality requirement. The integration crates then implement the necessary adapter code to map HTTP query parameters and response bodies into these core primitives. For axum, the `paginator-axum` crate provides a `PaginationQuery` extractor that parses query parameters such as `page` and `per_page` and attaches additional fields like `sort_by` and `sort_direction`, and a `PaginatedJson` responder that wraps the data and adds pagination headers according to RFC 8288.[15][15][38][15] For Actix Web and Rocket, similar integration patterns are implied by the presence of `paginator-actix` and `paginator-rocket`.[24][31]

In terms of implementation, `paginator-rs` supports both **page‑based** and **offset/limit** pagination. This matches the duality observed in authoritative patterns from crates.io’s `/api/v1/crates` endpoint (page/per_page with meta.total and meta.next_page) and Warp’s offset‑based `users` and `events` endpoints (page/page_size with pagination metadata).[7][19][41][42] The core crate likely exposes types that represent pagination parameters (`PaginationParams`, `PageNumber`, `PageSize`) and metadata (`PaginatorResponseMeta`), although the exact type names must be verified against the crate’s documentation and source.[35][35] Integration crates take these primitives and implement framework‑specific traits: for example, axum’s extractors implement `FromRequestParts`, while responders implement `IntoResponse`.[45][15][15] This allows the pagination machinery to be plugged into the framework’s request handling pipeline and response serialization.

Crucially, `paginator-rs` enables **app‑wide registration** of pagination configuration. The `paginator-axum` documentation references a helper function `create_link_header` that constructs pagination `Link` headers based on a base URL, `PaginationParams`, and response metadata.[38] Configuring these parameters once at application startup ensures that pagination behavior (default page, per_page, maximum items per page, header patterns) is consistent across routes. Similarly, in `paginator-actix`, one can imagine configuration being registered as `App::data` or as a middleware that wraps all routes and applies pagination defaults; while the exact usage is not shown in the extracted documentation, the design parallels `actix-web-pagination`’s configuration pattern, which registers `Pagination::config().default_per_page(50)` app‑wide.[10][11][10][10]

From a principle perspective, `paginator-rs` aligns with `rs-launch-blueprint`’s requirements by separating **core pagination semantics** from **framework‑specific integration**, enabling domain models to remain untouched by web concerns, and allowing centralized configuration of pagination defaults. It extends the Python pattern by adding support for additional metadata (sort fields, filters, search queries) while still preserving page and per_page semantics.[15][15] The bundle’s adoption would include verifying that `PaginatedJson` supports wrapping arbitrary `T` items without requiring them to implement framework‑specific traits beyond `Serialize`, thereby keeping items as domain objects.

##### Dominant choice

Within the pagination library landscape, `paginator-rs` is the **dominant choice** for `rs-launch-blueprint` due to its multi‑framework support, focus on ergonomics, and explicit handling of both pagination parameters and response metadata. Alternative choices, such as `actix-web-pagination`, are more narrowly focused on a single framework and lack the cross‑surface capabilities required by the template.[10][11][11][10] Database‑centric tools like `sqlx-paginated` and SeaORM’s `Paginator` are essential for data access but do not address the full HTTP pagination contract.[23][23][47] Envelope‑focused libraries like `api_bones::pagination` provide generic response types but do not integrate directly with web frameworks.[9][9][9][9]

By adopting `paginator-rs`, `rs-launch-blueprint` can define a **single pagination contract** that applies to both the library and web layers, while allowing R69 to choose any of the supported web frameworks (axum, Actix Web, Rocket) without changing the core pagination semantics. The integration crates ensure that query extraction and response shaping are consistent, enabling the app‑wide registration pattern needed to mirror FastAPI’s `add_pagination(app)` behavior.

##### Qualified shortlist

The **qualified shortlist** for the pagination bundle includes:

1. `paginator-rs` plus integration crates (`paginator-axum`, `paginator-actix`, `paginator-rocket`).[12][24][31][15][15]  
2. `actix-web-pagination` as a framework‑specific extractor with app‑wide configuration for page/per_page.[10][11][11][10][10]  
3. `api_bones::pagination` as a generic items/total envelope type, potentially combined with native framework extractors.[9][9][9][9][9]  
4. `use-pagination` as a primitives crate for page numbers and sizes, used alongside manually implemented envelopes and framework extractors.[18][18][18]  

All of these candidates meet the fundamental requirement of supporting page and page_size semantics and providing either extraction or envelope primitives. However, only `paginator-rs` offers a multi‑framework solution with both parameters and metadata, making it the leading choice for a template that must remain agnostic to the web framework.

##### Excluded by gate

Several candidates are **excluded by fitness gates** or by incompatibility with `rs-launch-blueprint`’s requirements. Libraries with incompatible licenses (such as GPL‑3.0‑only), like **do-paginate**, are excluded because the template requires a license of MIT or Apache‑2.0.[8][8] Database‑specific or cursor‑only libraries that do not expose generic items/total envelopes are excluded because they cannot serve as the primary pagination contract. Any crate with an unpatched RustSec advisory, untested support for Ubuntu and macOS, or undocumented MSRV would be excluded pending further investigation; however, the available documentation does not expose specific advisories or platform limitations for the shortlisted candidates, leaving this gate as a future verification step rather than a current exclusion.

##### Up-and-comers

Beyond `paginator-rs`, the **up‑and‑comer** set includes `api_bones::pagination` and `use-pagination`. `api_bones::pagination::PaginatedResponse<T>` defines a flat JSON envelope with `items`, `total_count`, `has_more`, `limit`, and `offset`, and includes helper methods for constructing responses from items and query parameters.[9][9][9][9][9] This structure is highly aligned with the Python template’s use of FastAPI’s `Page[T]` wrapper; it keeps items as domain objects and centralizes pagination metadata in a web‑specific wrapper. `use-pagination` focuses on small, validated types such as `PageNumber`, `PageSize`, `PageMarker`, and `PageInfo`, and explicitly declares non‑goals like avoiding database integration and cursor encoding, making it a good fit for core library use.[18][18][18] These crates are promising additions to the pagination bundle but are not themselves full solutions; they must be paired with a framework‑specific extractor and/or response type.

##### Fit for this template

`paginator-rs` fits `rs-launch-blueprint` well because it offers **framework‑agnostic primitives**, supports multiple web frameworks, and focuses on ergonomics and maintainability—traits that are critical for a template intended to be reused across projects. Its support for both page‑based and offset/limit pagination allows the template to align with the owner’s commonality mandate while still supporting high‑throughput or infinite‑scroll use cases where cursor‑based pagination might be needed.[12][12][35] The presence of integration crates for axum, Actix Web, and Rocket makes it compatible with R69’s open decision space, and its combination with `api_bones::pagination` or a local envelope type ensures that items remain domain objects. The crate’s MIT license (as indicated in its documentation) is compatible with the template’s licensing requirements.[12][12][35]

##### Recommendation

The recommendation for this member is that `rs-launch-blueprint` **adopt `paginator-rs` as the core pagination crate**, and **pair it with the appropriate integration crate** for the web framework selected by R69, plus a generic `PaginatedResponse<T>` envelope type modeled on `api_bones::pagination::PaginatedResponse<T>`. This stack provides page/size extraction, items/total metadata, and app‑wide configuration. The exact versions should be pinned at integration time (for example, `paginator-rs = "0.2.2"` based on the December 25, 2025 release) and updated in minor releases according to the MSRV policy.[12][12][12][35]

##### Ranked runner-up

The **runner‑up** for this member is the combination of **`actix-web-pagination`** and a manually implemented `PaginatedResponse<T>` envelope. This pattern would be appropriate if R69 conclusively selects Actix Web as the framework. The `actix-web-pagination` crate provides a `Pagination` extractor and `PaginationConfig` that can be registered via `App::data` to set default items per page across the application.[10][11][11][10][10] A custom `PaginatedResponse<T>` struct could mirror `api_bones`’ shape, with fields like `items`, `total_count`, `has_more`, `limit`, and `offset`.[9][9] However, this runner‑up is less flexible than `paginator-rs` because it is tightly coupled to Actix and lacks a cross‑framework story.

##### Tradeoffs

The primary **tradeoff** in adopting `paginator-rs` is the **dependency and complexity cost** versus a manual pagination pattern. `paginator-rs` introduces additional types and configuration code that developers must learn, and its integration crates may add minor compile‑time overhead. However, this cost is offset by the reduction in per‑route boilerplate, the standardization of pagination semantics, and the ability to reuse pagination across frameworks and projects. Another tradeoff is the reliance on an up‑and‑comer rather than an industry standard; while `paginator-rs` appears actively maintained and designed for production, its long‑term stability must be monitored more closely than that of crates.io’s API or AWS’s paginator implementations. Finally, tying the template to `paginator-rs` may limit future choices if the ecosystem moves toward a different standard; this risk can be mitigated by abstracting pagination primitives behind a local module in `rs-launch-blueprint`.

##### Parameters

For this member, the bundle **assumes** that:

CONFLICT: R69 `web-framework-stack` — **needed value: one of `axum`, `actix-web`, or `rocket`** — **reason: `paginator-rs` currently provides integration crates only for these frameworks and must integrate with the chosen extractor model.**

Other parameters remain within the template’s constraints: Edition 2024, MSRV stable minus two minor versions (to be verified via crate documentation and CI), license MIT or Apache‑2.0 (as indicated for `paginator-rs`), and CI coverage for Ubuntu and macOS (to be confirmed via repository badges or documentation).[12][12][12][35]

##### Migration implications

Adopting `paginator-rs` requires specific **file‑level changes** in the template. The web service crate must add `paginator-rs` and the chosen integration crate (for example, `paginator-axum`) to `Cargo.toml`. A `pagination` module should be introduced in the library crate, exposing a shared `PaginationParams` type and a generic `PaginatedResponse<T>` envelope. The composition root (for example, `src/web/app.rs`) must call a `configure_pagination` function that registers pagination defaults and attaches the integration crate’s extractors and responders, analogous to Python’s `add_pagination(app)`.[10][15] Each collection‑returning route must update its handler signature to include the pagination parameter type and return the paginated envelope. Tests must be added to verify that pagination behaves consistently across endpoints, including validation of page/page_size bounds and the correctness of `has_more` and total_count metadata.

##### Validation strategy

The **validation strategy** for `paginator-rs` combines unit tests, integration tests, and manual verification. A minimal example in axum might look like this:

```rust
use axum::{extract::Query, routing::get, Router};
use serde::Deserialize;
use paginator_axum::PaginationQueryParams;
use api_bones::pagination::PaginatedResponse;

#[derive(Deserialize)]
struct ProjectFilter {
    owner_id: Option<String>,
}

async fn list_projects(
    Query(pagination): Query<PaginationQueryParams>,
    Query(filter): Query<ProjectFilter>,
) -> PaginatedResponse<Project> {
    let page = pagination.page();
    let per_page = pagination.per_page();
    let offset = (page - 1) * per_page;
    // Fetch items and total_count from the database using offset/per_page...
    let items: Vec<Project> = fetch_projects(offset, per_page, filter).await?;
    let total_count = count_projects(filter).await?;
    PaginatedResponse::new(items, total_count, &pagination.into_pagination_params())
}
```

This code would be accompanied by tests that send HTTP requests with different `page` and `per_page` values, verify that the response envelope contains the expected items and metadata, and confirm that pagination defaults are applied when parameters are omitted. Additional tests would exercise edge cases such as out‑of‑range page values and maximum page_size constraints, ensuring that errors are routed through R70’s HTTP problem envelope. These checks are proposed; implementing them and integrating them into CI is part of the acceptance‑after work for R72.

##### Confidence & re-verify trigger

Current **confidence** in `paginator-rs` as the core pagination member is moderate to high, based on its documented features, multi‑framework support, and alignment with the template’s principles. However, because it is an up‑and‑comer rather than a long‑established standard, we must define re‑verify triggers. These include: any breakage in `paginator-rs` on the template’s MSRV or target OSs; a significant change in the crate’s API or licensing; the emergence of a first‑party Rust or framework‑specific pagination standard that offers better fit; or an advisory detected via RustSec. If any of these triggers occur, R72 must be revisited, and alternative candidates (such as `actix-web-pagination` plus a generic envelope or a manual pattern based on `api_bones::pagination`) should be reevaluated.

##### Sources

Key sources for this member include lib.rs documentation for `paginator-rs` and its satellite crates, axum integration documentation for `paginator-axum`’s `PaginationQuery` and `PaginatedJson`, and RustFAQ examples of Axum pagination patterns.[12][15][15][15][16][16][35][35]

#### paginator-utils (Perplexity)

##### Landscape

`paginator-utils` is part of the `paginator-rs` ecosystem and focuses on **data structures** for pagination in Rust.[35][35] Its documentation describes it as a companion crate to `paginator-rs`, providing reusable types and metadata structures that can be shared across web frameworks and database layers.[35][35] It inherits the same modular, multi‑framework ethos and MIT licensing as the core crate.[12][35][35] This crate occupies the up‑and‑comer bin but is more specialized, serving as a building block rather than a standalone solution.

Authoritative sources include lib.rs documentation that lists `paginator-utils` as part of the `paginator-rs` family and describes it as offering “Flexible Pagination: Page-based and offset/limit pagination” with a focus on ergonomics and performance.[35][35] These sources are authoritative because they originate from the same maintainers and share version histories.

##### Principles and implementation

`paginator-utils` implements core pagination metadata types, likely including structures for page numbers, page sizes, total counts, and links. These types can be used both in the library layer and in the web service’s response envelopes, ensuring that pagination semantics are consistent across surfaces.[35][35] For example, a `PageInfo` type might encapsulate the current page, total pages, and items per page, similar to the `pagination` block used in Warp’s Enterprise Analytics API.[7] Using `paginator-utils` in the template’s library crate allows CLI commands to reuse the same pagination metadata as the web service without pulling in framework‑specific code.

Implementation details must be confirmed by inspecting the crate’s documentation and source. However, the design intent is clear: provide lightweight, dependency‑minimal types that can represent pagination metadata and be serialized into JSON or other formats as needed.[35][35] This supports the principle of keeping pagination logic out of core domain models while still making metadata easily available for UI rendering and API consumers.

##### Dominant choice

Within the landscape of pagination metadata crates, `paginator-utils` is the **dominant choice** for `rs-launch-blueprint` because it is tightly integrated with `paginator-rs` and designed for cross‑framework use. Other candidates, such as `use-pagination`, also provide pagination primitives but focus more on markers and directions than on full metadata structures.[18][18][18] `api_bones::pagination` focuses on full envelopes rather than metadata primitives.[9][9] Therefore, `paginator-utils` is the best fit for sharing pagination metadata between the template’s library and web layers.

##### Qualified shortlist

The qualified shortlist includes:

1. `paginator-utils` for metadata structures within the `paginator-rs` ecosystem.[35][35]  
2. `use-pagination` for validated page numbers, sizes, and markers.[18][18][18]  

Both crates can serve as metadata providers, but `paginator-utils` is preferred due to its integration with `paginator-rs`.

##### Excluded by gate

No specific candidates are excluded here, as all shortlisted crates are lightweight and designed for generic use. Licensing and MSRV must still be verified via crates.io and repository documentation.

##### Up-and-comers

`use-pagination` remains an up‑and‑comer in this space, offering small validated types under a dual MIT/Apache‑2.0 license.[18][18][18] It is a promising supplement for pagination metadata but not strictly necessary if `paginator-utils` suffices.

##### Fit for this template

`paginator-utils` fits the template well by providing **shared pagination metadata types** that can be used in the CLI and library layers without pulling in any web framework dependencies. This supports the owner’s requirement that pagination be a shared capability across surfaces and that domain models remain free of web concerns.

##### Recommendation

The recommendation is that `rs-launch-blueprint` **adopt `paginator-utils` alongside `paginator-rs`**, using its metadata types in the library crate and in response envelopes. Version pinning and MSRV verification should follow the same pattern as for `paginator-rs`.[35][35]

##### Ranked runner-up

`use-pagination` is the runner‑up, and may be adopted as a secondary dependency if its primitives offer better validation or ergonomics than those in `paginator-utils`.[18][18][18]

##### Tradeoffs

The tradeoff is minor: adopting `paginator-utils` introduces an additional dependency, but it significantly reduces the need to implement custom metadata types and validation logic. The risk of future change is shared with `paginator-rs`, and can be mitigated by wrapping these types in local abstractions.

##### Parameters

No new parameters are owned by this member beyond those inherited from `paginator-rs`. Licensing and MSRV must be verified.

##### Migration implications

Adding `paginator-utils` requires importing its metadata types in the template’s library crate and updating response envelopes to include them.

##### Validation strategy

Unit tests should verify that metadata types serialize correctly and that they integrate with response envelopes and OpenAPI generation (R71).

##### Confidence & re-verify trigger

Confidence is moderate; re‑verify triggers mirror those for `paginator-rs`.

##### Sources

Lib.rs documentation for `paginator-utils` and related ecosystem pages.[35][35]

#### paginator-axum (framework integration example) (Perplexity)

##### Landscape

`paginator-axum` is an integration crate in the `paginator-rs` ecosystem that provides **query extractors and JSON responders for Axum**.[15][15][15] Its documentation describes a `PaginationQuery` extractor that parses query parameters, including `page`, `per_page`, `sort_by`, `sort_direction`, `filter`, `search`, and `search_fields`.[15][15][15] It also defines a `PaginatedJson` responder that automatically serializes responses and adds pagination headers, including a `Link` header constructed via a helper function `create_link_header` based on a base URL, `PaginationParams`, and response metadata.[15][38][15]

This crate occupies the up‑and‑comer bin and exemplifies how pagination can be integrated with a leading async web framework’s extractor mechanism. Axum itself is widely regarded in the Rust community, and its `Query` extractor is used extensively in examples and practice.[16][16][45] `paginator-axum` builds on this foundation, making it a strong candidate for integration with `rs-launch-blueprint` if R69 selects Axum.

##### Principles and implementation

`paginator-axum` implements the principle of **centralized pagination configuration** by providing a `PaginationQuery` extractor that can be used in any route handler and by offering functions to create pagination headers that are consistent across endpoints.[15][15][38][15] The crate’s `PaginationQuery` extractor likely uses Axum’s `FromRequestParts` trait to parse query parameters, applying default values and validation logic defined in `PaginationParams`.[45][15][15] This ensures that every route using `PaginationQuery` receives validated page and per_page values without re‑implementing parsing code.

The `PaginatedJson` responder wraps response data and attaches pagination headers, which can include links to next and previous pages and other metadata. While the evidence does not show the exact body envelope type, the design suggests that items remain domain objects (for example, `Vec<Project>`) and that pagination metadata is conveyed via headers and possibly auxiliary fields.[15][15][15] If necessary, `rs-launch-blueprint` can layer a body envelope such as `PaginatedResponse<T>` on top of `PaginatedJson`, ensuring that items/total metadata is available in the response body while headers provide navigational affordances.

##### Dominant choice

If Axum is selected as the web framework, `paginator-axum` is the **dominant choice** for pagination integration because it directly addresses the requirement of FastAPI‑like pagination: page/size query‑parameter extraction, standard response behavior, and app‑wide configuration. Alternatives would require implementing custom extractors and responders using Axum’s primitives, which increases boilerplate and reduces reuse.[16][16][45]

##### Qualified shortlist

The qualified shortlist includes:

1. `paginator-axum` for Axum integration.[15][15][15]  
2. Native Axum `Query` extractors combined with custom pagination structs, as described in RustFAQ and Axum+SQLx examples.[16][16][50]  

##### Excluded by gate

No specific exclusion arises here; however, if R69 selects a different framework, `paginator-axum` becomes inapplicable and its role must be replaced by the corresponding integration crate (`paginator-actix`, `paginator-rocket`) or a framework‑specific extractor like `actix-web-pagination`.[10][24][31][10]

##### Up-and-comers

Other integration crates, such as `paginator-actix` and `paginator-rocket`, are up‑and‑comers and must be evaluated similarly if their frameworks are chosen.[24][31]

##### Fit for this template

`paginator-axum` fits `rs-launch-blueprint` well if Axum is chosen because it provides exactly the capabilities required: **page/size query extraction**, integration with Axum’s typed extractor model, and a responder that can be registered or configured app‑wide.[15][15][15][45] It enables the template to emulate Python’s `add_pagination(app)` behavior by centralizing pagination defaults and response behavior.

##### Recommendation

The recommendation is that `rs-launch-blueprint` **adopt `paginator-axum` for the Axum integration path**, and adopt analogous integration crates for other frameworks if they are chosen. This keeps the pagination bundle consistent while letting R69 decide the framework.

##### Ranked runner-up

Native Axum `Query` extractors plus a manual pagination struct are the runner‑up. This pattern is suitable for smaller projects but less ideal for a reusable template.[16][16][45][50]

##### Tradeoffs

The tradeoff is between dependency and convenience. `paginator-axum` adds a dependency but reduces per‑route boilerplate and standardizes pagination behavior. Using native Axum primitives gives more control but increases development time and risk of inconsistency.

##### Parameters

Assumes that R69 selects Axum as the web framework for the example path; otherwise, this member’s role is taken by other integration crates.

##### Migration implications

Adding `paginator-axum` requires updating route signatures to use `PaginationQuery` and returning `PaginatedJson` or a combined envelope type.

##### Validation strategy

Integration tests should verify that `PaginationQuery` properly parses query parameters, that defaults are applied correctly, and that `PaginatedJson` attaches appropriate headers and body metadata.[15][15][38][15]

##### Confidence & re-verify trigger

Confidence is moderate; re‑verify triggers include framework changes (R69) and any breaking changes in `paginator-axum`’s API or Axum’s extractor model.[45]

##### Sources

Documentation for `paginator-axum` and Axum’s `Query` extractor.[15][15][15][45]

**Gemini**

#### paginator-axum bundle (Gemini)

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

**OpenAI**

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

**Perplexity**

The members of the recommended bundle must be **tested together** to ensure compatibility. The `paginator-rs` ecosystem is designed explicitly for this: `paginator-utils` and integration crates like `paginator-axum` share core types and metadata.[12][35][35] The documentation for `paginator-axum` references `PaginationParams` and `PaginatorResponseMeta`, which likely originate from `paginator-rs` or `paginator-utils`.[15][38] This shared type system ensures that pagination parameters and metadata can be passed seamlessly from extractors to response envelopes.

A compatibility matrix can be inferred from the ecosystem’s design:

| Component           | Role                           | Compatibility evidence                          |
|---------------------|--------------------------------|-------------------------------------------------|
| `paginator-rs`      | Core primitives and metadata   | Shared types referenced by integration crates.[12][35][35] |
| `paginator-utils`   | Metadata structures            | Mentioned as part of paginator‑rs ecosystem.[35][35]       |
| `paginator-axum`    | Axum integration               | Uses core types and metadata in extractors and responders.[15][15][38][15] |

In addition, practice evidence from projects using Axum and SQLx together shows that pagination primitives can be combined with database paginators like SeaORM’s `Paginator` and SQLx’s `LIMIT/OFFSET` queries without conflict.[23][47][27][50] This indicates that the recommended bundle can coexist with R69’s database stack choices.

**Gemini**

The `paginator-rs` ecosystem is explicitly engineered for unified compatibility. The `paginator-axum` crate relies directly on the core `paginator-rs` and `paginator-utils` crates, sharing a unified release cycle and versioning scheme to guarantee structural alignment. The ecosystem is fully compatible with `serde`, which is a hard requirement for Axum's JSON request and response handling mechanisms. Furthermore, the generic structure of `PaginatedJson<T>` is mathematically compatible with Utoipa 5.0's advanced generic schema resolution (`ComposeSchema`), ensuring that OpenAPI documentation pipelines can accurately trace the `$ref` pointers to the inner domain models without manual intervention [cite: 4, 6, 15, 17].

### Parameters

**OpenAI**

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

**Perplexity**

For R72, the pagination decision **owns** the following parameters:

- owns `pagination_contract` = **page/size query parameters + items/total metadata envelope + optional cursor metadata**  
- owns `pagination_registration_pattern` = **single app‑wide configuration call in the composition root that wires pagination extractors and envelope behavior**

R72 **assumes** the following consumed parameters:

- assumes `web-framework-stack` (R69) = one of Axum, Actix Web, or Rocket, compatible with `paginator-rs` integration crates.[24][31][15]  
- assumes `http-problem-envelope` (R70) will handle pagination validation errors (e.g., out‑of‑range page values) consistently.  
- assumes `openapi-generation-pipeline` (R71) will document the pagination envelope and parameters based on the chosen types.

Any conflict with these assumptions is noted as:

CONFLICT: R69 `web-framework-stack` — **needed value: one of `axum`, `actix-web`, or `rocket`** — **reason: required for `paginator-rs` integration; other frameworks would require additional integration work or a different pagination bundle.**

**Gemini**

*   `owns web-pagination-default-size = 20`
*   `owns web-pagination-max-size = 100`
*   `assumes web-framework-stack = axum`
*   `CONFLICT: R69 web-framework-stack — axum — The paginator-axum crate requires Axum as the host web framework; if R69 resolves to Actix-Web or Rocket, the equivalent paginator-actix or paginator-rocket crates must be substituted in the dependency manifest.`

### Migration implications

**OpenAI**

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

**Perplexity**

Adopting the recommended pagination bundle has concrete **migration implications** for `rs-launch-blueprint`. The template must add `paginator-rs`, `paginator-utils`, and the chosen integration crate (for example, `paginator-axum`) as dependencies in `Cargo.toml`. A new `pagination` module should be introduced in the library crate, defining shared pagination parameter types and a generic `PaginatedResponse<T>` envelope modeled on `api_bones::pagination::PaginatedResponse<T>`.[9][9][9][9][9] The composition root in the web service must define and call a `configure_pagination` function that registers pagination defaults and attaches extractors and responders app‑wide, similar to Python’s `add_pagination(app)`.[10][15][15]

Every collection‑returning route must be updated to accept a pagination parameter type and return the paginated envelope. For example, routes that previously returned `Vec<Project>` should now return `PaginatedResponse<Project>` and compute `limit` and `offset` based on page and per_page. Tests and documentation must be updated to reflect the new pagination contract, including examples and OpenAPI schemas. Any existing manual pagination logic must be removed or refactored into the new pattern, avoiding duplication and inconsistency.

**Gemini**

Implementing the recommended architecture requires structural modifications across the template to enforce compile-time safety and eliminate global payload mutations.

*   `Cargo.toml`: The dependency manifest must be updated to include `paginator-rs` (with necessary database feature flags) and `paginator-axum`.
*   `src/web/app.rs`: The composition root must be audited to ensure no `tower::Layer` middleware is globally attempting to intercept, buffer, or serialize JSON response bodies for pagination formatting. The architecture strictly relies on per-route explicit typing.
*   `src/web/routers/*.rs`: All collection-returning handlers must undergo signature updates. The parameters must accept the `paginator_axum::PaginationQuery` extractor, and the return type must be explicitly wrapped in the `PaginatedJson<T>` generic envelope.
*   `src/core/services/*.rs`: Domain services must accept the core `PaginationParams` object to construct efficient, database-level `LIMIT`/`OFFSET` or cursor-based queries prior to execution.

### Validation strategy

**OpenAI**

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

**Perplexity**

The **validation strategy** for R72 involves both implementation and testing. At implementation time, a minimal example must be built using the chosen web framework, demonstrating:

1. A route that accepts page and per_page via a pagination extractor (for example, `PaginationQuery` in `paginator-axum` or `Pagination` in `actix-web-pagination`).[10][15][15][45]  
2. A database query that uses limit and offset computed from page/per_page, using a paginator (SeaORM’s `Paginator` or SQLx’s `LIMIT/OFFSET`).[23][47][27][50]  
3. A response envelope using `PaginatedResponse<T>` that includes items, total_count, has_more, limit, and offset, with correct metadata.[9][9][9][9]  

Tests should be written to send HTTP requests with different pagination parameters and verify:

- Correct parsing of page and per_page.  
- Correct computation of limit and offset.  
- Correct construction of the response envelope and metadata.  
- Consistent behavior across multiple routes.  

Commands such as `cargo test` and `cargo run` should be used to run unit and integration tests on both Ubuntu and macOS environments. Performance metrics (latency, throughput) should be measured using load testing tools for representative workloads, ensuring that pagination does not introduce excessive overhead.

These validation steps are **planned** and must be executed before R72 is considered fully accepted. They are not yet executed.

**Gemini**

The validation strategy relies on a combination of automated static analysis and dynamic runtime checks to mathematically prove the capability.

*   **Planned Check**: Execute the test suite via `cargo test --package rs-launch-blueprint-web`.
*   **Expected Behavior**: Unit and integration tests executing against collection endpoints must assert that the HTTP response body successfully deserializes into a generic envelope struct, verifying the presence of the `items` array and all required pagination metadata fields (`page`, `per_page`, `total_pages`).
*   **Planned Check**: Execute the OpenAPI generation pipeline via Utoipa and run an external schema validation tool (e.g., Schemathesis) against the output.
*   **Expected Behavior**: The generated `openapi.json` must feature an explicit schema definition for the paginated envelope that correctly utilizes a `$ref` pointer to refer to the inner domain model schema (e.g., `#/components/schemas/Project`). This verifies that the OpenAPI specification remains structurally aligned with the Rust source code without requiring manual, per-route schema overrides.

### Confidence & re-verify trigger

**OpenAI**

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

**Perplexity**

Overall **confidence** in the recommended pagination bundle is moderate to high, based on alignment with authoritative patterns, fit for the template, and the design of the `paginator-rs` ecosystem. However, several re‑verify triggers exist:

- A change in R69’s `web-framework-stack` selection that chooses a framework without existing `paginator-rs` integration.  
- Significant changes in `paginator-rs` or its integration crates, including licensing, MSRV, or API.  
- New authoritative guidance from the Rust project or major frameworks that establishes a different pagination standard.  
- Performance issues or integration problems discovered during validation.  

If any of these triggers occur, R72 must be revisited, and alternative bundles (such as `actix-web-pagination` plus a generic envelope or a manual pattern based on `api_bones::pagination`) must be reevaluated.

**Gemini**

**High**. The recommended architecture effectively bridges the gap between the rigid static typing requirements of the Rust toolchain and the flexible payload semantics established by the Python precedent. By shifting the registration mechanism from dynamic middleware to explicit generic types, the template achieves the desired behavior while preserving zero-cost performance and automated documentation generation.

*Re-verify trigger*: The architectural decision must be re-evaluated if a future major release of the Axum framework introduces macro-based dynamic response mutation capabilities that circumvent current typing limitations, or if Utoipa significantly alters its generic AST parsing algorithms.

### Sources

**OpenAI**

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

**Sources**

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

**Perplexity**

Key sources for this decision include:

- Crates.io and DeepWiki API references for `/api/v1/crates` pagination semantics.[20][19][41][42]  
- Warp Enterprise Analytics API documentation for offset‑based pagination and pagination metadata.[7]  
- Axum documentation for the `Query` extractor and community examples for pagination patterns.[16][16][45][50]  
- `paginator-rs` and related ecosystem documentation for multi‑framework pagination primitives and integration.[12][15][24][31][35][15][38][15][35]  
- `api_bones::pagination` documentation for generic `PaginatedResponse<T>` and `CursorPagination` envelope types.[9][9][9][14][9][9]  
- `use-pagination` documentation for validated pagination primitives.[18][18][18]  
- `actix-web-pagination` documentation for framework‑specific pagination extractors and configuration.[10][11][11][10][10]  
- SeaORM and SQLx‑paginated documentation for database‑level pagination patterns.[23][23][47][27]  
- AWS SDK for Rust paginator RFCs and service‑specific paginator implementations.[2][25][34][25][39][34]  

These sources collectively inform the landscape, principles, and recommendations for R72.

**Conclusion**

The R72 pagination decision determines whether `rs-launch-blueprint` will align its Rust web service with the Python port’s precedent of app‑wide page/size pagination and generic items/total envelopes. The Rust ecosystem does not offer a single, first‑party equivalent to FastAPI’s `fastapi-pagination`, but it does provide a rich landscape of libraries and patterns that can be composed into an effective bundle. Surveying this landscape reveals that multi‑framework ecosystems like `paginator-rs`, envelope‑focused crates like `api_bones::pagination`, and primitives like `use-pagination` together offer the building blocks needed to construct a centralized pagination contract that preserves domain purity and supports both web and library surfaces.

The recommended approach is to adopt the `paginator-rs` ecosystem as the core pagination bundle, pairing it with a generic `PaginatedResponse<T>` envelope and integrating it with the chosen web framework via its appropriate integration crate. This design honors the shared engineering principles of capability commonality, app‑wide registration, and domain‑pure items while respecting Rust’s typed, multi‑framework architecture. It also provides a clear path for validation, performance measurement, and future re‑verification if the ecosystem evolves.

By making this decision explicit and grounded in ecosystem research, `rs-launch-blueprint` can ensure that pagination is treated as a first‑class architectural concern, rather than an ad‑hoc implementation detail, and can provide a consistent, ergonomic experience to developers across languages and surfaces.

**Sources**

- [Working with list operations | Google Cloud Documentation](https://docs.cloud.google.com/rust/pagination)
- [Using paginated results in the AWS SDK for Rust](https://docs.aws.amazon.com/sdk-for-rust/latest/dg/paginating.html)
- [Pagination — Rust web dev library // Lib.rs](https://lib.rs/crates/pagination)
- [GitHub - JMTamayo/page-hunter: An extensible Rust-based library for managing and navigating through pages of data.](https://github.com/JMTamayo/page-hunter)
- [Pagination - Warp API Docs](https://warp-0a29c735.mintlify.app/pagination)
- [paginator-surrealdb — db interface for Rust // Lib.rs](https://lib.rs/crates/paginator-surrealdb)
- [Enterprise Analytics API - Warp docs](https://docs.warp.dev/enterprise/enterprise-features/analytics-api/)
- [do-paginate](https://lib.rs/crates/do-paginate)
- [PaginatedResponse in api_bones::pagination - Rust](https://docs.rs/api-bones/latest/api_bones/pagination/struct.PaginatedResponse.html)
- [actix-web-pagination 0.1.2](https://docs.rs/crate/actix-web-pagination/latest)
- [actix_web_pagination - Rust](https://docs.rs/actix-web-pagination)
- [paginator-rs](https://lib.rs/crates/paginator-rs)
- [sea-orm/src/executor/paginator.rs at master · SeaQL/sea-orm](https://github.com/SeaQL/sea-orm/blob/master/src/executor/paginator.rs)
- [CursorPagination in api_bones::pagination - Rust](https://docs.rs/api-bones/latest/api_bones/pagination/struct.CursorPagination.html)
- [Axum - paginator-rs](https://paginator-rs.msdqn.dev/web-frameworks/axum/)
- [🚀 Implement Pagination in Rust APIs with Axum](https://www.rustfaq.org/en/how-to-implement-pagination-in-rust-apis/)
- [How to Use Axum Web Framework for APIs - oneuptime.com](https://oneuptime.com/blog/post/2026-02-01-rust-axum-web-framework/view)
- [Crate use_pagination Copy item path](https://docs.rs/use-pagination/latest/use_pagination/)
- [crates.io API – Pacotes Rust, versões e downloads](https://dexbase.org/pt/apis/crates-io)
- [API Reference | rust-lang/crates.io | DeepWiki](https://deepwiki.com/rust-lang/crates.io/4-api-reference)
- [paging_stream - Rust](https://docs.rs/paging-stream/latest/paging_stream/)
- [leptos_pagination - Rust - Docs.rs](https://docs.rs/leptos-pagination/latest/leptos_pagination/)
- [sqlx-paginated](https://lib.rs/crates/sqlx-paginated)
- [paginator-actix](https://lib.rs/crates/paginator-actix)
- [RFC: Paginator Design · smithy-lang smithy-rs · Discussion #346](https://github.com/smithy-lang/smithy-rs/discussions/346)
- [rust-example-caster-api/libs/utils/src/pagination.rs at main · bkonkle/rust-example-caster-api](https://github.com/bkonkle/rust-example-caster-api/blob/main/libs/utils/src/pagination.rs)
- [GitHub - alexandrughinea/sqlx-paginated: A flexible, type-safe SQLx query builder for dynamic web APIs, offering seamless pagination, searching, filtering, and sorting.](https://github.com/alexandrughinea/sqlx-paginated)
- [crates.io](https://crates.io/api/openapi.json)
- [Crates.io Scraper — Rust Package Registry Data API](https://apify.com/logiover/crates-io-scraper)
- [crates.io — API Provider, Schemas](https://apis.io/providers/crates-io/)
- [paginator-rocket — server-side Rust // Lib.rs](https://lib.rs/crates/paginator-rocket)
- [GitHub - ndelvalle/rustapi: 🚀 RESTful Rust API Template / Boilerplate](https://github.com/ndelvalle/rustapi)
- [🚀 Master Pagination in Rust REST APIs with Axum](https://www.rustfaq.org/en/how-to-implement-pagination-in-rust-rest-api/)
- [aws_sdk_panorama/operation/list_application_instance_node_instances/paginator.rs](https://docs.rs/aws-sdk-panorama/latest/src/aws_sdk_panorama/operation/list_application_instance_node_instances/paginator.rs.html)
- [paginator-utils — data structures in Rust // Lib.rs](https://lib.rs/crates/paginator-utils)
- [diesel/examples/postgres/advanced-blog-cli/src/pagination.rs at master · diesel-rs/diesel](https://github.com/diesel-rs/diesel/blob/master/examples/postgres/advanced-blog-cli/src/pagination.rs)
- [PaginationQueryParams in paginator_axum - Rust - Docs.rs](https://docs.rs/paginator-axum/latest/paginator_axum/struct.PaginationQueryParams.html)
- [create_link_header in paginator_axum - Rust](https://docs.rs/paginator-axum/latest/paginator_axum/fn.create_link_header.html)
- [paginator.rs - source - Docs.rs](https://docs.rs/aws-sdk-proton/latest/src/aws_sdk_proton/operation/list_environment_account_connections/paginator.rs.html)
- [Crates Io Crates Api | APIs.io APIs](https://apis.io/apis/crates-io/crates-io-crates-api/)
- [crates.io API – Rust 软件包、版本与下载量](https://dexbase.org/zh/apis/crates-io)
- [crates.io API – Rust パッケージ、version、downloads](https://dexbase.org/ja/apis/crates-io)
- [paginator_axum - Rust](https://docs.rs/paginator-axum)
- [Module paginatorCopy item path](https://docs.rs/awaur/latest/awaur/paginator/index.html)
- [axum/extract/query.rs](https://docs.rs/axum/latest/src/axum/extract/query.rs.html)
- [Module paginatorsCopy item path](https://docs.rs/matrix-sdk/latest/matrix_sdk/paginators/index.html)
- [Paginator in sea_orm - Rust](https://docs.rs/sea-orm/latest/sea_orm/struct.Paginator.html)
- [SQLx Paginated (alexandrughinea ...](https://context7.com/alexandrughinea/sqlx-paginated)
- [GitHub - ddimaria/rust-actix-framework: Actix Web is a fast, powerful web framework for building web applications in Rust. This project aims to create ergonomic abstractions comparable to frameworks in other languages while attempting to maintain the performance benefits of Rust and Actix.](https://github.com/ddimaria/rust-actix-framework)
- [Rust的Axum+sqlx封装一个简单的分页查询函数](http://www.chenxutan.com/d/680.html)

**Cost**

Total: $1.1636

**Gemini**

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

**Sources**

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
