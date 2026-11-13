# R72: Pagination bundle for `rs-launch-blueprint`

The pagination decision for `rs-launch-blueprint` sits at the intersection of cross‑language commonality, Rust’s typed web ecosystem, and the template’s three‑surface scope (CLI, library, web service). The Python port already establishes a precedent of page/size query‑parameter pagination with a generic items/total response envelope, wired once app‑wide via a single factory call, and keeping collection elements as pure domain objects with only the wrapper being web‑specific.[Context] The Rust ecosystem offers several pagination crates and architectural patterns, but none is a universal, first‑party analogue of FastAPI’s `fastapi-pagination`. Instead, we find a small cluster of multi‑framework libraries (notably the **paginator‑rs** family), framework‑specific extractors (such as **actix‑web‑pagination**), envelope‑focused primitives (such as **api_bones::pagination::PaginatedResponse**), and lower‑level pagination helpers (such as **use‑pagination** and **paging_stream**).[10][12][18][21][9] After surveying this landscape and weighing authority, practice, and fit, the recommendation is that `rs-launch-blueprint` should adopt a **pagination bundle centered on the `paginator-rs` ecosystem**, using its framework integration crate for whatever web framework R69 selects, and pairing that with a generic response envelope that preserves domain models. This bundle enables page/size query extraction via framework‑native extractors, a uniform items/total metadata contract, and app‑wide registration of pagination defaults and response behavior, thereby aligning Rust with the Python precedent while respecting Rust’s strongly typed, multi‑framework ecosystem.

## R72: API pagination decision

### Landscape

The category this item decides is **API pagination for Rust web services**, specifically the combination of query‑parameter extractors and response envelopes that every collection‑returning route will use. At a structural level, this landscape separates into three bins: Rust’s built‑in or first‑party toolchain support; **established industry standards** in the ecosystem; and **up‑and‑comers** that are gaining adoption but are not yet canonical.

In the **built‑in / first‑party toolchain** bin, Rust itself and the core web frameworks provide the foundational primitives but not a complete, FastAPI‑like pagination stack. The axum web framework, for example, exposes a `Query<T>` extractor that deserializes URL query strings into typed structs using `serde`, allowing developers to define a `Pagination` struct with `page` and `per_page` fields and have axum populate it automatically from query parameters like `?page=2&per_page=30`.[45] This mechanism is illustrated both in the official axum documentation and in community examples that define `Pagination` or `PaginationParams` structs and compute offsets for database queries based on page and per_page values.[16][16][45] Similarly, web frameworks such as Actix Web natively support extractors and application data registration, but leave pagination as a user‑space concern. The Actix ecosystem’s `actix-web-pagination` crate implements a `Pagination` extractor that integrates with Actix’s request handling model, but this crate is external rather than first‑party.[10][11][11]

The **established industry standard** bin comprises widely referenced pagination patterns and libraries that have clear evidence of production use and community endorsement. In the broader Rust ecosystem, the **crates.io Registry Web API** sets a de facto standard for query‑parameter pagination: the `/api/v1/crates` endpoint accepts `q`, `page`, and `per_page` parameters, returns a list of crates plus a `meta` object, and exposes fields such as `total` and `next_page` to indicate overall count and continuation.[19][41][42] This pattern—page/per_page query parameters coupled with an items list and total count metadata—is echoed in documentation aggregators like DeepWiki’s crates.io API reference and in scraping tooling such as Apify’s “Crates.io Scraper”, which explicitly supports modes that paginate across the full registry.[20][29][40] Another strong reference is the **Warp Enterprise Analytics API**, which exposes paginated users and events endpoints with `page` and `page_size` parameters, and returns both per‑page items and a `pagination` block containing `current_page`, `page_size`, `total_pages`, and `total_count`.[7] This shows that in practice, well‑regarded Rust services adopt page/size plus items/total patterns even when they define their own envelopes.

Within **industry‑standard pagination libraries**, several categories emerge. `actix-web-pagination` provides a `Pagination` extractor and a `PaginationConfig` that can be registered via `App::data` to configure default items per page across the application, such as `default_per_page(50)`.[10][11][10][10] SQL‑related crates like **sea‑orm** and **sqlx-paginated** treat pagination at the database query layer: SeaORM’s `Paginator` fetches pages of results using `LIMIT`/`OFFSET` and exposes helper methods such as `fetch_page` and `num_pages`.[47][13][13] SQLx‑paginated wraps SQLx with a dynamic query builder that supports pagination parameters (`page`, `page_size` with defaults and bounds), sorting, filtering, and date range parameters.[23][23][27] High‑profile services such as AWS adopt paginator abstractions in their Rust SDK: a general RFC describes modeling paginated data as a `Stream` of output shapes, with a generated `<OperationName>Paginator` struct in a `paginator` module and a `paginate()` method that exposes a `Stream` of results.[25][25] Service‑specific paginator implementations (for example, Panorama’s `ListApplicationInstanceNodeInstancesPaginator`) follow this pattern, flattening results across pages into an iterator or stream.[34][39][34] These references are authoritative because they are maintained by the Rust project ecosystem (crates.io), major infrastructure providers (AWS), and widely used database libraries (SeaORM, SQLx), all of which have strong adoption and rigorous documentation.

The **up‑and‑comer** bin contains libraries that aim to provide multi‑framework, ergonomic pagination support, often with more modern idioms and flexible metadata. The **paginator‑rs** ecosystem is a central example: its core crate describes itself as “a comprehensive, modular Rust pagination library with support for multiple databases and web frameworks,” emphasizing flexible page‑based and offset/limit pagination, ergonomics, performance, and maintainability.[12][12][12][35] Satellite crates include `paginator-utils` for reusable data structures,[35][35] and integration crates such as `paginator-axum` and `paginator-actix` that provide query extractors and JSON responders tailored to axum and Actix Web respectively.[24][31][15][15] The `paginator-axum` documentation describes a `PaginationQuery` extractor that parses query parameters including `page` and `per_page`, and a `PaginatedJson` responder that serializes responses and adds pagination headers according to RFC 8288.[15][15][38][15] Another up‑and‑comer is the **api_bones::pagination** module, which defines a generic `PaginatedResponse<T>` struct with fields `items: Vec<T>`, `total_count: u64`, `has_more: bool`, `limit: u64`, and `offset: u64`, and a constructor that sets `has_more` based on whether `offset + items.len() < total_count`.[9][9][9][9][9] This envelope type is explicitly designed for offset‑based paginated list endpoints and offers a flat JSON shape where items remain domain objects and metadata is centralized. It is complemented by a `CursorPagination` struct for cursor‑based pagination, with fields `has_more: bool` and `next_cursor: Option<String>`.[14][14] Finally, **use-pagination** offers “pagination primitives for RustUse,” including `PageNumber`, `PageSize`, `PageMarker`, `PageInfo`, and `PaginationDirection`, and explicitly states its scope as small validated types with stable display labels and conservative parsing, under MIT or Apache‑2.0 licensing.[18][18][18]

Authority in this landscape is **established**, not assumed, by triangulating multiple sources. The Rust project’s own documentation on crates.io’s API and pagination semantics is considered authoritative because it defines the canonical registry interface used by Cargo.[20][30][19][41][42] Web framework documentation (such as axum’s `Query` extractor docs) is authoritative for extractor behavior.[45] Major library documentation from SeaORM, AWS’s Rust SDK, and Warp’s APIs is authoritative because these projects have broad community usage, transparent version histories, and rigorous testing.[7][2][25][34][47] Independent write‑ups like RustFAQ’s guides on implementing pagination in Axum and MOS templates describing Rust REST APIs are practice‑oriented and well cited, but they are treated as leads rather than primary authority.[16][16][33] Likewise, blog posts on wrapping Axum and SQLx with a generic `PaginatedResult<T>` structure demonstrate realistic patterns but are not themselves canonical.[50]

Practice evidence involves surveying what **mainstream, well‑regarded Rust projects** actually do. The **crates.io** service uses page/per_page query parameters and returns items and total metadata along with a `next_page` link, demonstrating a production‑grade pattern that matches the template’s desired behavior.[19][41][42] **Warp**’s Enterprise Analytics API uses offset‑based pagination with page and page_size, and a `pagination` block containing current_page, page_size, total_pages, and total_count in every paginated response, thereby aligning with page/size plus items/total semantics.[7] **SeaORM** provides a `Paginator` abstraction that developers commonly wrap in higher‑level response envelopes like `ManyResponse<Model>`, which includes fields `data`, `count`, `total`, `page`, and `page_count`, illustrating how items remain domain objects while metadata is layered in a web‑specific wrapper.[26][26][26][47] The **Diesel** project’s advanced blog CLI example includes pagination code that computes offsets and exposes pagination to the CLI, again using page and page size semantics at the data layer.[36] AWS’s Rust SDK uses paginator abstractions extensively across services like Panorama, modeling pagination as streams of output shapes and letting clients consume paginated results via generated paginator types.[2][34][25][34] Finally, web application templates leveraging Axum and MongoDB or Actix Web show patterns where pagination structs are used to compute database offsets and wrapped in response envelopes with page/size and total metadata.[16][17][32][49][50] These projects are well regarded due to active maintenance, community adoption (evident from reverse dependencies and references), and their roles in significant ecosystems (database ORMs, official SDKs, registry services).

Fit is judged **relative to `rs-launch-blueprint`**, not in abstraction. The template must support a CLI and a library layer in addition to the web service, so any pagination solution must avoid tying core objects to web‑specific types. It must honor the owner’s parameters: Rust edition 2024, stable MSRV minus two minor versions, MIT or Apache‑2.0 licensing, and CI coverage for Ubuntu and macOS.[PARAMETERS] It must align with the Python port’s precedent of a generic pagination envelope and app‑wide pagination registration, while not over‑constraining R69’s choice of web framework. This points away from frameworks that bake pagination into monolithic types and toward **framework‑agnostic pagination primitives and envelopes** paired with **small per‑framework integration crates** that implement extractors and responders. Within this landscape, the **paginator‑rs ecosystem** and the **api_bones::pagination** envelope stand out as up‑and‑coming solutions tailored to multi‑framework use, while axum’s and Actix’s native extractors and configuration capabilities provide the foundation necessary to emulate FastAPI’s `add_pagination(app)` semantics.[10][15][9][45]

### Principles and implementation

The shared requirement arises from the **commonality mandate** across the Python and Rust ports. In Python, the FastAPI integration uses `fastapi-pagination` to apply page/size query parameters and a `Page[T]` response envelope app‑wide, via an `add_pagination(app)` call that registers pagination once and then allows each route to simply declare `Page[Model]` as the return type while keeping the items themselves as domain objects from `core.models`.[Context] The principle here is that pagination is a **cross‑cutting capability** governed at the architectural pattern level: every collection‑returning endpoint should share the same pagination contract, and this contract should be configured centrally, not per route. Agreement is required at the level of capability and pattern: page/size query semantics, items/total metadata envelope, and app‑wide registration. Detailed implementation choices (such as exact field names, cursor versus offset options, and HTTP header usage) may vary between ecosystems so long as they preserve the principle that pagination logic is not duplicated per route and does not contaminate core domain models.

The **essential behaviors** for the Rust template are, therefore, as follows. First, all list endpoints must accept **page** and **page_size** (or `per_page`) query parameters that can be parsed by the selected web framework’s extractor mechanism. Axum supports this via `Query<Pagination>` structs; community examples show `Pagination { page: usize, per_page: usize }` deserialized from query strings.[16][16][45] Actix Web supports extraction via **actix-web-pagination**’s `Pagination` extractor, which reads pagination parameters from HTTP requests and uses `PaginationConfig` to determine defaults such as items per page.[10][11][11][10] Second, responses must wrap items in a **generic envelope** that includes an items vector and total metadata, typically fields such as total_count, limit, and offset; `api_bones::pagination::PaginatedResponse<T>` demonstrates a canonical shape for this, with `items: Vec<T>`, `total_count: u64`, `has_more: bool`, `limit: u64`, and `offset: u64`.[9][9][9][9][9] Third, the pagination machinery—including default page sizes, maximum bounds, and possibly header conventions—should be registered or configured **once app‑wide**, analogous to FastAPI’s `add_pagination(app)`. This is achievable in Rust via application data or state: Actix’s example registers `Pagination::config().default_per_page(50)` via `App::data`, which then applies to all routes using the `Pagination` extractor.[10][11][10][10] The `paginator-axum` crate similarly suggests a central `PaginationParams` configuration that is applied via its extractors and responders.[15][15]

Observable **acceptance criteria** for this decision can be articulated as follows. Every collection‑returning endpoint in `rs-launch-blueprint` should have the same handler signature pattern: a domain‑specific query or filter and a **pagination parameter type**, with page/size validated and defaulted consistently. The response type should expose a generic **Paginated<T>** envelope with a `Vec<T>` and pagination metadata, where `T` is always a domain model object (for example, a `Project` from the core library), not a web wrapper.[9][9][26] Pagination defaults and constraints (such as maximum page_size) should be declared once at the composition root and reused automatically, rather than re‑specified per route. Finally, the bundle should support at least two pagination strategies—simple offset‑based page/size for bounded lists, and cursor‑based pagination where required—mirroring `api_bones`’ offset‑based `PaginatedResponse` and `CursorPagination` types.[14][14][9] These acceptance criteria are observable via API behavior, test coverage, and OpenAPI schema generation (which R71 will own).

Before choosing libraries, we must compare **architectural alternatives**. One alternative is a **manual pattern**: define a local `PaginationParams` struct for page/per_page, implement validation and offset computation, and declare a generic `Paginated<T>` struct in the template’s web layer, much like the RustFAQ guides and Axum+SQLx blog examples that define `PaginatedResponse<T>` and validate pagination constraints.[16][16][50] This approach minimizes dependencies but requires per‑project boilerplate and still leaves per‑route pagination wiring unless additional infrastructure is built. Another alternative is to adopt **framework‑specific pagination crates** such as `actix-web-pagination` and design the template around the chosen web framework. `actix-web-pagination` offers pagination extraction, configuration via `PaginationConfig`, and a reusable `Pagination` type, but it ties the template to Actix Web and lacks a generic envelope type, requiring an additional envelope layer.[10][11][11][10] A third alternative is to use **multi‑framework pagination ecosystems** such as `paginator-rs` combined with `paginator-axum` or `paginator-actix`, which provide unified pagination primitives, query extractors, and JSON responders that can be wired app‑wide across different technologies.[12][24][31][15][15] Finally, **database‑centric pagination tools** like SeaORM’s `Paginator` and `sqlx-paginated` treat pagination at the query builder level, which is valuable but insufficient for shaping the HTTP envelope and web‑level contract.[23][23][47][27]

The recommended design must preserve each principle while accommodating differences between ecosystems. The Python port’s `fastapi-pagination` relies on dynamic typing and runtime introspection; Rust cannot mirror this exactly due to generics and trait bounds. Instead, we can use a design where the **core pagination primitives and envelope types live in a library crate**, independent of any web framework, and the web service composes them with framework‑native extractors. Up‑and‑coming crates like `use-pagination` and `api_bones::pagination` are designed precisely for this purpose: they provide validated page numbers, page sizes, and response envelopes without coupling to any HTTP stack.[18][9][18] Multi‑framework ecosystems like `paginator-rs` extend this by adding framework‑specific query extractors and responders, which can be registered in the app’s composition root to emulate FastAPI’s `add_pagination(app)` behavior.[12][15][15] Production usage in newer projects demonstrates that this approach yields ergonomic, maintainable APIs; for example, using `PaginatedJson` responders and `PaginationQuery` extractors in axum reduces per‑route boilerplate and standardizes pagination semantics across endpoints.[15][15] Thus, the Rust ecosystem requires a slightly different shape—a combination of a core, framework‑agnostic pagination library and a thin framework‑specific integration crate—but this design continues to satisfy the shared principle of centralized pagination configuration and domain‑pure items.

From a **performance** and **integration cost** perspective, the bundle must not impose heavy binary‑size or compile‑time penalties relative to manual patterns. Core crates like `use-pagination` and `api_bones::pagination` are dependency‑light and largely consist of small structs and helper functions.[18][9][18] Multi‑framework ecosystems like `paginator-rs` are designed with performance and ergonomics in mind, and focus on flexible pagination rather than heavy runtime features.[12][12] Database‑centric pagination crates like `sqlx-paginated` and SeaORM’s `Paginator` may add compile‑time cost due to SQLx type checking and ORM abstractions, but these are necessary for database safety and are orthogonal to the HTTP envelope.[23][47][27] Integration cost is primarily in wiring: the bundle will require adding one or more pagination crates to `Cargo.toml`, defining a shared pagination configuration in the composition root, and updating route signatures to use pagination extractors and envelope types. These changes are well scoped and can be validated via integration tests and OpenAPI generation.

A minimal realistic **example** for acceptance would use axum as the web framework (for concreteness in R72, while R69 retains the right to choose differently). It would define a `PaginationQueryParams` type using `paginator-axum`’s query extractor, configure default `page` and `per_page` values at application startup, and implement a handler returning a `PaginatedResponse<Project>` envelope from `api_bones::pagination`, where `Project` is a domain model type. The handler would receive `PaginationQueryParams` via axum’s `Query` extractor, translate `page` and `per_page` into `limit` and `offset`, query the database via a paginator (either SeaORM’s `Paginator` or `sqlx-paginated`), and construct `PaginatedResponse<T>::new(items, total_count, &params)`.[16][23][9][47] An executable acceptance check would enforce that every collection route in the template uses the same pagination parameter type and envelope, that pagination metadata is consistent across endpoints, and that the composition root contains a single pagination configuration path. These checks are proposed and must be implemented in CI and integration tests; they are not yet executed.

Critically, this decision triggers a **baseline review**:  

**BASELINE-REVIEW: F311 — app-wide pagination wiring — proposed change: adopt a Rust pagination bundle combining `paginator-rs` and a generic PaginatedResponse envelope, registered once at the composition root — evidence: FastAPI’s `add_pagination(app)` pattern in Python, crates.io’s page/per_page plus total metadata contract, Warp’s pagination block, and the `paginator-rs` ecosystem’s multi‑framework design and `PaginationQuery`/`PaginatedJson` behavior.**[7][20][9][15]

### Recommendation

The recommendation is that `rs-launch-blueprint` **does adopt a Rust pagination bundle** that provides page/size query‑parameter extraction and a generic items/total response envelope, registered once app‑wide. The dominant choice for this bundle is the **paginator‑rs ecosystem**, specifically:

1. The core `paginator-rs` crate for pagination primitives and metadata.[12][12][12]  
2. The `paginator-utils` crate for reusable data structures and pagination metadata sharing between the library and web layers.[35][35]  
3. The appropriate framework integration crate (such as `paginator-axum` or `paginator-actix`) for `rs-launch-blueprint`’s chosen web framework, providing a `PaginationQuery` extractor and `PaginatedJson` responder wired via a single configuration call in the composition root.[24][31][15][15]

Because none of these crates, in the evidence provided, defines a body envelope identical to FastAPI’s `Page[T]`, the bundle should be complemented by a **generic PaginatedResponse<T> envelope**, either using `api_bones::pagination::PaginatedResponse<T>` or an equivalent type implemented within `rs-launch-blueprint` that mirrors its shape.[9][9][9][9][9] This preserves the principle that items remain domain objects while metadata is web‑specific and layered in a wrapper.

Concretely, the web service in `rs-launch-blueprint` should define a `configure_pagination` function in its composition root, which registers `paginator-rs`’s pagination configuration and the integration crate’s extractors and responders once app‑wide. Routes will then declare a standard pagination parameter type (for example, `PaginationQueryParams` or `Pagination`) and return `PaginatedResponse<T>` where `T` is a domain type. This architecture matches Python’s pattern of app‑wide registration, domain‑pure items, and standardized pagination semantics, while using Rust’s idiomatic crates and typed extractor mechanisms.

### Members

#### paginator-rs

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

#### paginator-utils

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

#### paginator-axum (framework integration example)

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

### Compatibility

The members of the recommended bundle must be **tested together** to ensure compatibility. The `paginator-rs` ecosystem is designed explicitly for this: `paginator-utils` and integration crates like `paginator-axum` share core types and metadata.[12][35][35] The documentation for `paginator-axum` references `PaginationParams` and `PaginatorResponseMeta`, which likely originate from `paginator-rs` or `paginator-utils`.[15][38] This shared type system ensures that pagination parameters and metadata can be passed seamlessly from extractors to response envelopes.

A compatibility matrix can be inferred from the ecosystem’s design:

| Component           | Role                           | Compatibility evidence                          |
|---------------------|--------------------------------|-------------------------------------------------|
| `paginator-rs`      | Core primitives and metadata   | Shared types referenced by integration crates.[12][35][35] |
| `paginator-utils`   | Metadata structures            | Mentioned as part of paginator‑rs ecosystem.[35][35]       |
| `paginator-axum`    | Axum integration               | Uses core types and metadata in extractors and responders.[15][15][38][15] |

In addition, practice evidence from projects using Axum and SQLx together shows that pagination primitives can be combined with database paginators like SeaORM’s `Paginator` and SQLx’s `LIMIT/OFFSET` queries without conflict.[23][47][27][50] This indicates that the recommended bundle can coexist with R69’s database stack choices.

### Parameters

For R72, the pagination decision **owns** the following parameters:

- owns `pagination_contract` = **page/size query parameters + items/total metadata envelope + optional cursor metadata**  
- owns `pagination_registration_pattern` = **single app‑wide configuration call in the composition root that wires pagination extractors and envelope behavior**

R72 **assumes** the following consumed parameters:

- assumes `web-framework-stack` (R69) = one of Axum, Actix Web, or Rocket, compatible with `paginator-rs` integration crates.[24][31][15]  
- assumes `http-problem-envelope` (R70) will handle pagination validation errors (e.g., out‑of‑range page values) consistently.  
- assumes `openapi-generation-pipeline` (R71) will document the pagination envelope and parameters based on the chosen types.

Any conflict with these assumptions is noted as:

CONFLICT: R69 `web-framework-stack` — **needed value: one of `axum`, `actix-web`, or `rocket`** — **reason: required for `paginator-rs` integration; other frameworks would require additional integration work or a different pagination bundle.**

### Migration implications

Adopting the recommended pagination bundle has concrete **migration implications** for `rs-launch-blueprint`. The template must add `paginator-rs`, `paginator-utils`, and the chosen integration crate (for example, `paginator-axum`) as dependencies in `Cargo.toml`. A new `pagination` module should be introduced in the library crate, defining shared pagination parameter types and a generic `PaginatedResponse<T>` envelope modeled on `api_bones::pagination::PaginatedResponse<T>`.[9][9][9][9][9] The composition root in the web service must define and call a `configure_pagination` function that registers pagination defaults and attaches extractors and responders app‑wide, similar to Python’s `add_pagination(app)`.[10][15][15]

Every collection‑returning route must be updated to accept a pagination parameter type and return the paginated envelope. For example, routes that previously returned `Vec<Project>` should now return `PaginatedResponse<Project>` and compute `limit` and `offset` based on page and per_page. Tests and documentation must be updated to reflect the new pagination contract, including examples and OpenAPI schemas. Any existing manual pagination logic must be removed or refactored into the new pattern, avoiding duplication and inconsistency.

### Validation strategy

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

### Confidence & re-verify trigger

Overall **confidence** in the recommended pagination bundle is moderate to high, based on alignment with authoritative patterns, fit for the template, and the design of the `paginator-rs` ecosystem. However, several re‑verify triggers exist:

- A change in R69’s `web-framework-stack` selection that chooses a framework without existing `paginator-rs` integration.  
- Significant changes in `paginator-rs` or its integration crates, including licensing, MSRV, or API.  
- New authoritative guidance from the Rust project or major frameworks that establishes a different pagination standard.  
- Performance issues or integration problems discovered during validation.  

If any of these triggers occur, R72 must be revisited, and alternative bundles (such as `actix-web-pagination` plus a generic envelope or a manual pattern based on `api_bones::pagination`) must be reevaluated.

### Sources

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

## Conclusion

The R72 pagination decision determines whether `rs-launch-blueprint` will align its Rust web service with the Python port’s precedent of app‑wide page/size pagination and generic items/total envelopes. The Rust ecosystem does not offer a single, first‑party equivalent to FastAPI’s `fastapi-pagination`, but it does provide a rich landscape of libraries and patterns that can be composed into an effective bundle. Surveying this landscape reveals that multi‑framework ecosystems like `paginator-rs`, envelope‑focused crates like `api_bones::pagination`, and primitives like `use-pagination` together offer the building blocks needed to construct a centralized pagination contract that preserves domain purity and supports both web and library surfaces.

The recommended approach is to adopt the `paginator-rs` ecosystem as the core pagination bundle, pairing it with a generic `PaginatedResponse<T>` envelope and integrating it with the chosen web framework via its appropriate integration crate. This design honors the shared engineering principles of capability commonality, app‑wide registration, and domain‑pure items while respecting Rust’s typed, multi‑framework architecture. It also provides a clear path for validation, performance measurement, and future re‑verification if the ecosystem evolves.

By making this decision explicit and grounded in ecosystem research, `rs-launch-blueprint` can ensure that pagination is treated as a first‑class architectural concern, rather than an ad‑hoc implementation detail, and can provide a consistent, ergonomic experience to developers across languages and surfaces.

## Sources

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

## Cost

Total: $1.1636
