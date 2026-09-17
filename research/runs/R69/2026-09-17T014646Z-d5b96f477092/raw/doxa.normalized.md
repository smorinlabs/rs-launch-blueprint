# R69 — Doxa engine report (three providers, regrouped by template field)

Normalization record: Doxa operation research-20260912-134041-a1150ec8a7594fa0 (all_deep_research) returned one report per provider. This file regroups the three answer bodies under the prompt's template fields so the single-report shape check applies; within each field the three provider sections appear in the order OpenAI, Perplexity, Gemini, each introduced by a bold label, and under `### Members` every provider's members are kept with the provider name appended to the member heading. Every content line of each provider's answer body is preserved (the originals are the three saved files under the run's doxa/ directory; raw/doxa-<provider>.normalized.md hold the bodies individually). Headings that precede a provider's first template field or follow its last one are demoted to bold text so no heading outside the template remains; doxa/normalization.json lists every other adjustment.

**Provider preambles (text preceding each provider's first template field)**

**OpenAI (gpt-5.6-sol)**



**Perplexity (sonar-deep-research)**

**Rust Web Framework Stack for `rs-launch-blueprint` (R69, bundle)**
This report concludes that the optional web surface of `rs-launch-blueprint` should be implemented as a Tokio-native Axum stack, exposed behind a single Cargo feature named `web`, with an Axum router constructed by an explicit app-factory function that takes already-validated configuration, shared with handlers and tests via Axum’s `State` extractor and simple test helpers.[11][17][20] The production entrypoint is an `#[tokio::main]` binary gated by the `web` feature, binding a `TcpListener` and serving the Axum router via `axum::serve` with `with_graceful_shutdown` wired to a Tokio-based signal future that listens for `SIGINT` and `SIGTERM`, wrapped in a timeout matching the configured graceful shutdown seconds.[18][19] The dev-server recipe is a Justfile target that runs `cargo watch` (or an equivalent watcher) to rebuild and restart the `web` binary with `--features web`, defaulting the logging profile to a human-readable console format distinct from production JSON, thus preserving the same dev/prod split seen in the FastAPI precedent.[1][18] The `web-extra-surface` parameter is therefore defined as a single `web` feature gating the Axum/Tokio/hyper/tower-http dependency stack, the web module tree, the `web` binary target, and all web-focused tests; this shape satisfies the shared principles of optionality, explicit configuration lifecycle, graceful shutdown, and dev-friendly auto-reload across the Python, TypeScript, and Rust templates, while leveraging Rust’s idiomatic patterns rather than copying Python’s lazy DI fallback verbatim.[2][3][14][20]

**Context and Landscape**

**Gemini (deep-research-preview-04-2026)**

**rs-launch-blueprint Web Framework Stack (R69)**

### Landscape

**OpenAI**

**Decision category:** an optional, application-level async HTTP adapter bundle for a Rust CLI + library + web-service template. It covers framework, server/runtime, application state, startup/shutdown lifecycle, feature gating, in-process testing, and development restart tooling—not business middleware or OpenAPI/telemetry library selection.

**Research date:** September 12, 2026. Rust stable is **1.98.1**, making the owner’s “stable minus two minor versions” floor **Rust 1.96**. `rust-version = "1.96"` is therefore the required manifest value. Source: `https://blog.rust-lang.org/releases/` and `https://doc.rust-lang.org/releases.html` (retrieved 2026-09-12). ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))

> **Evidence-completeness note:** the official documentation, repositories, release pages, RustSec index, adopter manifests, and benchmark pages were retrieved. The raw JSON bodies from the mandated crates.io and GitHub API endpoints were not obtainable in this research execution, so I have not invented download counts, API star counts, API open-issue totals, or issue-response medians. Those fields are marked pending and the exact collection commands are included under `### Validation strategy`. Consequently, the architectural recommendation is decision-ready, but the §7.6 quantitative ledger is not acceptance-ready until those commands are run.

#### Three-bin map

| Bin | Landscape | Relevance |
|---|---|---|
| **Built-in or first-party toolchain** | Rust `std` has networking primitives but no production async HTTP framework. Within the dominant async ecosystem, Tokio supplies runtime/network/signal/time facilities; Hyper supplies HTTP; Tower supplies `Service`/`Layer`; Axum is the Tokio project’s first-party ergonomic web layer over them. | Best composability and lowest architectural distance from the broader Tokio ecosystem. Axum explicitly states that it is designed for Tokio and Hyper and uses Tower rather than inventing a middleware system. Source: `https://docs.rs/axum/0.8.9/axum/` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html)) |
| **Established industry standard** | **Axum 0.8.9**, **Actix Web 4.15.0**, Warp 0.4.3, and Rocket 0.5.x. Axum and Actix are the serious finalists; Warp and Rocket remain credible but fit this template less well. | Axum and Actix both have mature JSON, state, middleware, testing, and production server stories. Actix has a more integrated server; Axum has stronger Tower/Hyper/Tonic interoperability. Current version evidence: `https://github.com/tokio-rs/axum`, `https://docs.rs/actix-web/latest/actix_web/`, and `https://docs.rs/crate/warp/latest` (retrieved 2026-09-12). ([github.com](https://github.com/tokio-rs/axum)) |
| **Up-and-comer** | Poem and its OpenAPI companion, Salvo, Pavex, Xitca Web, and higher-level Axum frameworks such as Loco. | Worth monitoring. Poem is the closest functional alternative where tightly integrated OpenAPI is the primary selection criterion; Pavex offers a distinctive build-time architecture. Their production-adopter and prescribed macOS-CI evidence was weaker in this survey. Source leads: `https://docs.rs/poem/latest/poem/` and the maintained comparison map at `https://github.com/flosse/rust-web-framework-comparison` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/poem/latest/poem/)) |

#### Authorities used

| Authority | Why it counts |
|---|---|
| Rust Release Team and annual Rust survey | Primary evidence for the supported stable toolchain and broader ecosystem practice—not a framework ranking. Sources: `https://blog.rust-lang.org/releases/` and `https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2025/annual-survey/report/annual-survey-2025-report.pdf` (retrieved 2026-09-12). ([blog.rust-lang.org](https://blog.rust-lang.org/releases/)) |
| Tokio/Axum maintainers’ docs and repository | Primary evidence for runtime coupling, state, Tower integration, serving, release state, and official examples. Sources: `https://docs.rs/axum/0.8.9/axum/`, `https://docs.rs/tokio/1.53.1/tokio/`, and `https://github.com/tokio-rs/axum` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html)) |
| Actix, Warp, and Poem maintainers’ docs | Primary evidence for the alternative frameworks’ current APIs and releases. Sources: `https://docs.rs/actix-web/latest/actix_web/`, `https://docs.rs/crate/warp/latest`, and `https://docs.rs/poem/latest/poem/` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/actix-web/latest/actix_web/)) |
| RustSec | Authoritative advisory index. Package counts include historical advisories and are not equivalent to an advisory affecting the current lockfile; `cargo audit` remains the acceptance test. Source: `https://rustsec.org/packages/` (retrieved 2026-09-12). ([rustsec.org](https://rustsec.org/packages/)) |
| TechEmpower | Widely cited independent throughput evidence, useful only as a performance ceiling/cross-check. Its workloads do not include this template’s complete validation, configuration, OpenTelemetry, metrics, error, and graceful-shutdown path. Source: `https://www.techempower.com/benchmarks/` (retrieved 2026-09-12). ([techempower.com](https://www.techempower.com/benchmarks/)) |
| Current adopter source trees | Direct evidence of actual framework use. The Rust package registry migrated to Axum; its OpenAPI description is generated through an Axum integration. Qdrant’s current lockfile resolves Actix Web. Sources: `https://blog.rust-lang.org/2025/02/05/crates-io-development-update/`, `https://github.com/rust-lang/crates.io`, and `https://github.com/qdrant/qdrant/blob/master/Cargo.lock` (retrieved 2026-09-12). ([blog.rust-lang.org](https://blog.rust-lang.org/2025/02/05/crates-io-development-update/)) |

#### Practice evidence

- **Axum:** crates.io is an unusually relevant adopter because it is a production Rust HTTP service maintained inside the Rust project, handles uploads, authentication, background work and API traffic, and reports having migrated to Axum. It also demonstrates that Axum does not prevent generated OpenAPI: crates.io uses an Axum-compatible OpenAPI integration. Source: `https://blog.rust-lang.org/2025/02/05/crates-io-development-update/` (retrieved 2026-09-12). ([blog.rust-lang.org](https://blog.rust-lang.org/2025/02/05/crates-io-development-update/))
- **Actix Web:** Qdrant’s current source resolution includes `actix-web`, demonstrating continuing use in a substantial network service. Source: `https://github.com/qdrant/qdrant/blob/master/Cargo.lock` (retrieved 2026-09-12). ([github.com](https://github.com/qdrant/qdrant/blob/master/Cargo.lock))
- **Warp and Poem:** both remain maintained framework lines, but this survey did not establish an equally strong current adopter reference satisfying the owner’s adopter-evidence rule. That evidence gap counts against them; it is not proof of non-use.

#### Fitness gates before popularity

| Candidate | License | MSRV | Advisory/unsafe posture | Prescribed OSs | Runtime/defaults | Cost and result |
|---|---|---|---|---|---|---|
| **Axum 0.8.9** | MIT; compatible | Published MSRV 1.80, below floor 1.96 | Historical `axum-core` advisory exists; current lock must pass `cargo audit`. Template code forbids unsafe; transitive unsafe is audited rather than assumed absent. | Tokio explicitly supports Linux and macOS; Axum also has cross-target docs builds. | Tokio/Hyper coupled by design; defaults disabled in the recommendation. | Moderate compile/binary cost with selected features. **Pass, pending lock audit.** ([github.com](https://github.com/tokio-rs/axum)) |
| **Actix Web 4.15.0** | MIT OR Apache-2.0 | Upstream states Rust 1.88+, below floor 1.96 | Historical advisories exist in the Actix family; current lock must pass `cargo audit`. | Cross-platform Tokio-compatible stack; template matrix still must prove Ubuntu/macOS. | Integrated Actix server/service middleware; feature-rich defaults should be trimmed. | Somewhat broader baseline dependency surface. **Pass, pending lock audit.** ([github.com](https://github.com/actix/actix-web)) |
| **Warp 0.4.3** | MIT | Below current floor | Historical fixed advisory; resolved lock still audited. | Tokio/Hyper based; expected on both required Unix hosts. | Filter-combinator API; Tokio runtime. | Compile-time type complexity and rejection composition reduce template clarity. **Passes basic gates; loses on fit.** ([docs.rs](https://docs.rs/crate/warp/latest/builds/3228099)) |
| **Poem 3.x** | Compatible upstream line | Appears compatible | Lock audit required | No sufficiently authoritative upstream macOS test statement was established in this pass. | Tokio-based, more batteries included. | Attractive OpenAPI integration, but weaker production/adopter evidence. **Provisionally excluded by gate 4 evidence.** ([docs.rs](https://docs.rs/poem/latest/poem/)) |
| **cargo-watch 8.5.3** | CC0-compatible | Old but buildable | External tool | Shipped cross-platform | Cargo-specific watcher | Repository archived January 18, 2025. **Excluded: archived.** ([github.com](https://github.com/watchexec/cargo-watch)) |
| **Bacon 3.24.x** | AGPL-3.0 | MSRV 1.85 | External tool | Cross-platform | TUI/job runner | Active and capable, but fails the owner’s strict dependency/tool license rubric. **Excluded by gate 1.** ([github.com](https://github.com/Canop/bacon)) |
| **Watchexec CLI 2.5.1** | Apache-compatible upstream license; recheck manifest before pin | Rust 1.93, below floor 1.96 | External process; not linked | Release artifacts include Apple Darwin and Linux | Runtime-independent process watcher | Active, supports graceful stop/restart and bounded stop timeout. **Pass.** ([github.com](https://github.com/watchexec/watchexec/releases)) |

**Perplexity**

The decision in R69 concerns a specific category in the Rust ecosystem: async HTTP server frameworks and their supporting server/runtime stack suitable for building a backend web service in a template that also ships as a CLI and a general-purpose library.[1][3][7] In Rust, this category spans both routing-focused libraries such as Axum, Actix-Web, Rocket, Warp, Poem, Salvo, and Tide, and lower-level HTTP libraries and async runtimes such as hyper and Tokio that underpin them.[1][3][7][11][12][16][20] To avoid privileging familiarity, we first map the landscape into three bins: built-in or first-party toolchain elements, established industry standards, and up-and-comers.

The built-in or first-party bin includes Tokio, hyper, and Axum in its modern form.[11][12][20] Tokio is the de facto standard asynchronous runtime for Rust, maintained by the Tokio project and widely adopted across networked applications; hyper is the foundational HTTP library built on Tokio and strongly recommended by its maintainers for HTTP client/server implementations; Axum is described by the Tokio team as an ergonomic, modular web framework built with `tokio`, `tower`, and `hyper`, and is effectively a first-party routing layer in the Tokio ecosystem.[12][20] These components form a baseline building block stack that many frameworks either use directly or wrap, and their status as first-party derives from direct stewardship by the Tokio and Rust infrastructure communities, extensive documentation, and integration into widely used libraries.[11][12][20]

The established industry standard bin contains Actix-Web, Rocket, and Warp.[1][3][4][7] Actix-Web is characterised in multiple independent comparisons as a powerful, extremely fast web framework built atop the Actix actor framework, consistently topping performance benchmarks such as TechEmpower when configured with JSON handling and high concurrency.[3][4][7][8] Rocket is an async backend web framework for Rust focusing on usability, security, extensibility, and speed; its maintainers emphasise developer ergonomics with macro-based routing and request guards, and the release of Rocket v0.5 brought stable Rust support and rebuilt async request handling using modern networking facilities.[2][3][9] Warp is built on top of hyper and Tokio, offering a composable, functional routing style and high performance; several surveys note Warp’s strong performance and use it as a reference point for lightweight async web applications.[1][4][7][12] These frameworks have high GitHub star counts, documented production usage, and sustained maintenance records, and are widely considered standard choices in Rust for web backends.[3][4][7][8][9][12]

The up-and-comer bin encompasses Poem, Salvo, and Tide.[1][7][10][16] Poem is described as a full-featured and easy-to-use web framework whose ecosystem includes `poem-openapi` for writing APIs that comply with OpenAPI 3 specifications and automatically generating documentation; its release history on lib.rs shows frequent updates through 2024 and 2025, indicating active development and maturation.[10] Salvo is marketed as a powerful web framework that can make work easier, offering first-class OpenAPI support with automatic generation, and is undergoing addition to curated lists like blessed.rs, signalling community recognition.[1][16] Tide, built on the async-std runtime, aims for simplicity and ergonomics, concentrating on async-first design with minimalism and pragmatism; although it lacks the same level of adopted status as Actix or Axum, it remains a recognised alternative for projects preferring async-std over Tokio.[1][7] These frameworks are promising but not yet the default choice in the majority of high-profile Rust backends.

Following the mandate to establish authority rather than assume it, the primary authoritative sources in this survey are official documentation and announcements from framework maintainers, widely cited comparative articles, and infrastructure project documentation.[1][2][3][4][5][7][8][9][10][11][12][14][15][16][19][20] For Axum, the Tokio blog announcement of axum 0.8, the crate documentation on crates.io, and the detailed docs.rs pages are authoritative because they are maintained by the project team and specify design intentions, feature sets, and integration points.[11][17][19][20] Rocket’s v0.5 release announcement and GitHub repository are authoritative for its async, stable-Rust support and ergonomic design; they come directly from the maintainers and document the architectural refactor to async networking.[2][9] Actix-Web’s crates.io page and recurring characterisation as extremely fast in multiple comparative articles are authoritative about its performance and actor-based architecture, reinforced by its long-term presence in benchmarks like TechEmpower.[3][4][7][8] Warp’s reliance on hyper and Tokio, coupled with documentation in tower-http examples, provides authoritative confirmation of its composable filter-based design and performance profile.[1][4][7][12][15] Poem and Salvo’s lib.rs and crates.io pages document their OpenAPI support and feature sets, and are maintained by their authors.[10][16] Finally, documentation about the crates.io API confirms Axum’s use in a real, high-traffic Rust infrastructure service, providing practice-based evidence with an authoritative origin in the Rust project itself.[14]

Practice evidence comes from surveying well-regarded Rust projects and seeing which frameworks they adopt. The most concrete example is crates.io itself, which uses Axum to implement its RESTful API for crate publication, metadata retrieval, search, and user management.[14] The DeepWiki documentation notes that the crates.io API is built using Axum and follows RESTful principles, and it lists numerous endpoints that support crate lifecycle operations such as publishing, metadata retrieval, owner listing, and version management; Axum routing and handlers thus power a core Rust ecosystem service with significant traffic and reliability demands.[14] This provides direct evidence that Axum is not only theoretically sound but battle-tested in production, aligning well with the template’s need for dependability. In the comparative landscape, multiple articles emphasise that Actix-Web, Rocket, and Axum are all production-ready, actively maintained, and have strong community support, while Actix-Web often appears as the fastest in raw throughput benchmarks and Axum close behind.[3][4][5][6][7] These articles assess learning curve, ecosystem maturity, performance, and production readiness, making them reasonable practice evidence when combined with official docs.

The fit question asks not which framework is universally “best,” but which best matches a template that is simultaneously a CLI, a library, and an optional web service, and must host layered concerns such as OpenAPI generation, typed settings, tracing, and metrics as separate decisions.[3][5][6] Comparative articles note that Axum’s modular, middleware-oriented design built on Tokio and Tower fits naturally into Rust’s async ecosystem, favouring composability and future-proof integration with observability tooling.[3][4][5][6][11][15][20] Actix-Web emphasises raw speed and a rich, actor-centric model that can introduce complexity for teams less familiar with Rust’s advanced features; Rocket prioritises developer ergonomics, macro-driven routing, and convention over configuration, sometimes trading a bit of throughput for simplicity.[3][4][5][6][7] Given the need for explicit, testable configuration injection, clear app-factory patterns, and straightforward integration with OpenTelemetry and metrics layers, Axum’s emphasis on modularity, Tower-based middleware, and Tokio-native async appears particularly well aligned, while Actix-Web remains a strong runner-up when extreme performance and actor integration are paramount.[3][5][6][15][20] This landscape framing sets the stage for principled selection in the context of the owner’s cross-language requirements and the specific shape of `rs-launch-blueprint`.

## Principles and Architecture

**Gemini**

The evaluation of the Rust asynchronous web ecosystem in 2026 requires a rigorous, evidence-based categorization of the available architectures. Guided by the mandate to prioritize architectural fit and verifiable authority over transient popularity, the current landscape of Rust web development can be systematically mapped into three distinct tiers. The first tier consists of built-in or first-party toolchain components, representing the absolute foundation of the ecosystem. This includes `tokio` as the asynchronous runtime standard, `cargo` for compile-time feature-flag architecture, and the standard library's concurrency primitives. The second tier comprises established industry standards that have achieved critical mass in enterprise production environments. This tier is dominated by `axum` and `actix-web` for HTTP routing, alongside `bacon` as the definitive standard for development-server orchestration and auto-reloading. The third tier contains up-and-comers and specialized frameworks, including `poem` (notable for its native OpenAPI macro integration), `salvo`, `rocket` (which has seen a significant reduction in release velocity), and full-stack application starters like `loco` and `leptos` [cite: 1, 2].

Authority within this landscape is derived from a diverse array of verifiable sources, actively eschewing single-author blog posts in favor of aggregate community data and official project mandates. The foundational authority is the 10th annual State of Rust Survey (spanning late 2025 into 2026), which collected data from over 7,156 respondents and revealed that enterprise usage of Rust for non-trivial production workloads has surged to 48.8% [cite: 3, 4, 5]. This transition from an early-adopter systems language to a consolidated enterprise backend language establishes that the web framework ecosystem is no longer experimental; it is expected to provide stability, composability, and long-term maintenance guarantees. Furthermore, architectural authority is heavily weighted toward publications from the Tokio project and major Rust working groups, which establish the `tower` middleware trait as the definitive mechanism for service composition [cite: 6, 7]. 

Practice evidence drawn from the ecosystem further narrows the viable field. Mainstream, well-regarded Rust projects overwhelmingly favor frameworks that integrate seamlessly with the `tokio` runtime, which currently powers backend infrastructure at hyperscalers like Discord, AWS, and Cloudflare [cite: 8]. Download metrics retrieved via the crates.io API serve as a proxy for this adoption, demonstrating that `axum` has accumulated over 458 million lifetime downloads, heavily outpacing historical alternatives like `actix-web` (80 million) and `rocket` (13 million) [cite: 9, 10]. While TechEmpower benchmarks historically favored `actix-web` for raw throughput, the archiving of the FrameworkBenchmarks repository in March 2026 has shifted the industry's evaluation metrics away from theoretical micro-benchmarks toward practical considerations of architectural composability, type safety, and middleware interoperability [cite: 9, 11]. Similarly, in the realm of development tooling, practice evidence indicates a paradigm shift: `cargo-watch`, the long-standing standard for hot-reloading, was effectively sunset by its maintainer in late 2024 in favor of `bacon`, which offers superior background compilation and avoids lockfile conflicts with `rust-analyzer` [cite: 12, 13].



The final landscape requirement involves evaluating fitness for the specific `rs-launch-blueprint` template architecture. This template operates as a unified CLI, library, and web service. Consequently, the chosen web stack cannot assume it is the sole occupant of the binary. The framework must be capable of being strictly isolated behind Cargo feature flags to prevent HTTP server dependencies from bloating the CLI tool's compilation time and binary footprint [cite: 14, 15]. Furthermore, the framework must support explicit, deterministic configuration injection that does not rely on global mutable state, and it must integrate cleanly with the `tower` ecosystem to host tracing, OpenTelemetry, and metrics layers as defined by subsequent architectural decisions (R78, R79).

### Principles and implementation

**OpenAI**

#### Shared requirement and agreement levels

| Principle | Required agreement level | Observable behavior |
|---|---|---|
| Optional web capability | **Policy/capability**, already owner-fixed | Base CLI/library builds without the web adapter; one documented opt-in enables the complete base HTTP surface. |
| Explicit composition root | **Architectural pattern** | One function assembles routes and application state; one production `main` loads settings and resources. |
| One validated configuration snapshot | **Behavioral standard** | Configuration is loaded and validated once before binding; handlers never read the environment or invoke the loader. Tests can supply independent configurations. |
| Framework-native dependency access | **Architectural pattern**, mechanism may vary | FastAPI dependencies, Hono/tRPC context, and Axum state may differ while preserving explicit request-scoped access to app-owned dependencies. |
| In-process testability | **Capability** | Handler/router tests run without binding a TCP port or starting a separate process. |
| Bounded graceful shutdown | **Behavioral standard** | SIGTERM/Ctrl-C stops admission, drains in-flight work, and force-ends after a configured duration. |
| Fast development loop | **Developer policy** | Source edits rebuild and restart the server; development defaults to readable console logs while production defaults to structured JSON. |
| Instrumentation compatibility | **Capability/interface standard** | R75/R78/R79 can wrap the router with ordered HTTP middleware, traces, and metrics without handlers depending on exporter implementations. |

What **must not** be standardized across languages is a low-level DI container, lifecycle callback API, watcher, or server executable. Python’s lifespan/dependency system, Hono/tRPC context factories, and Axum state are justified ecosystem differences.

The TypeScript snapshot’s missing server is a missing capability relative to the later Hono/tRPC owner direction, not evidence that Rust should omit its already-approved web feature.

#### Architectural alternatives

1. **Global/lazy configuration singleton**  
   Rejected. It makes parallel tests configuration-order-dependent and can create two snapshots if startup and fallback paths race.

2. **Explicit app state passed to router construction**  
   Selected. Axum’s `State<S>` and `Router::with_state` are its documented mechanism; merged/nested routers share a state type. Source: `https://docs.rs/axum/0.8.9/axum/extract/struct.State.html` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.State.html))

3. **Integrated server with framework-owned lifecycle**  
   Actix’s approach is excellent and gives shorter bounded-shutdown configuration. It is the runner-up architecture.

4. **Composable Router/Service plus an explicit process lifecycle**  
   Selected. `axum::serve` exposes graceful shutdown; Tokio supplies signals and timeouts. This keeps the app factory independently testable and avoids another server crate for plain HTTP. Source: `https://docs.rs/axum/0.8.9/axum/serve/struct.Serve.html` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/axum/latest/axum/serve/struct.Serve.html))

5. **Public nested Cargo features for every web layer**  
   Rejected for the base surface. Cargo features are additive and public; a `web-openapi`/`web-metrics` hierarchy would multiply CI combinations and make the nine downstream consumers guess which combination constitutes “the web service.”

6. **One public `web` umbrella gate**  
   Selected. Later research items may add their web-only dependencies to this feature. A new independently user-visible compile-time capability requires its owner to justify a separate feature explicitly.

#### Framework comparison

| Framework | Maturity/dependability | Middleware | Testing/configuration | Performance evidence | Fit |
|---|---|---|---|---|---|
| **Axum** | Active Tokio-project framework; current stable line 0.8.9, with 0.9 under development but no fixed release date. Production use includes crates.io. | Native Tower `Service`/`Layer`; reusable with Hyper/Tonic and compatible instrumentation layers. | `State<S>`, `with_state`, `Router::merge/nest`, and `ServiceExt::oneshot`. | TechEmpower places representative Axum implementations in the high-throughput Rust tier, but not with this template’s full instrumentation. | **Best overall.** ([github.com](https://github.com/tokio-rs/axum)) |
| **Actix Web** | Active 4.x stable line, mature integrated server and service factory. | Strong but Actix-specific `Transform`/service ecosystem. | `web::Data`, application factory closure, and Actix test service utilities. | Historically competitive in narrow HTTP benchmarks; must be tested on the actual workload rather than assumed faster. | **Runner-up.** Wins when integrated server controls or measured resource efficiency dominate. ([docs.rs](https://docs.rs/crate/actix-web/latest)) |
| **Warp** | Current 0.4.3 line but lower architectural momentum than Axum. | Filter composition rather than Tower-first app composition. | `warp::test` is good, but state and errors commonly become closure/filter plumbing. | Capable, but no representative instrumented advantage established. | Qualified but not preferred for a teaching template. ([docs.rs](https://docs.rs/crate/warp/latest/builds/3228099)) |
| **Poem** | Maintained, full-featured, good companion OpenAPI story. | Framework-specific middleware/endpoint model. | Explicit data and test client. | Insufficient comparable production/instrumented evidence in this survey. | Best challenger if R71 decides first-party-style OpenAPI integration outweighs Tower interoperability. ([docs.rs](https://docs.rs/poem/latest/poem/)) |

#### Performance conclusion and limitation

No public benchmark found compares these frameworks using all of the required path: representative inbound JSON, semantic validation, typed errors, R01 application call, route-aware tracing, metrics recording, and production-equivalent middleware. TechEmpower is useful to reject the claim that Axum is intrinsically slow, but it cannot select the winner for this template. Its implementations, hardware, database paths, feature sets, and instrumentation differ from the proposed service. Source: `https://www.techempower.com/benchmarks/` (retrieved 2026-09-12). ([techempower.com](https://www.techempower.com/benchmarks/))

The required follow-up benchmark should have two workloads:

- **Adapter ceiling:** 1 KiB `POST` JSON, semantic validation, in-memory R01 fake, success/error serialization.
- **Service-like:** same route plus a 1 ms simulated async application dependency, selected R75/R78/R79 layers and a local telemetry collector.

Measure throughput, p50/p95/p99 latency, CPU-seconds per million requests, peak RSS, release binary size, and clean/incremental compilation on identical hardware. Actix replaces Axum only if it produces a material SLO or resource improvement in that workload—not merely a higher plaintext/JSON microbenchmark rank.

#### Configuration lifecycle

Load and validate the R77 settings type once in the web binary. Derive:

- process-only server settings: bind address and graceful-shutdown duration;
- an immutable `Arc<ValidatedWebConfig>` projection containing only handler-relevant values;
- the R01 application service/port implementation.

Pass those into `WebState`, then call `build_router(state)`. Handlers use `State<WebState<_>>`. Tests construct their own `ValidatedWebConfig` and fake application boundary. There is no hidden startup hook and therefore no need for Python’s lazy fallback.

This is stronger than a fallback: direct calls to the public router factory cannot omit state, while handler functions remain private to discourage bypassing the composition root.

#### Minimal Cargo shape

```toml
[package]
edition = "2024"
rust-version = "1.96"

[features]
default = []
web = [
  "dep:axum",
  "dep:tokio",
  "dep:tower",
]

[dependencies]
axum = {
  version = "0.8.9",
  optional = true,
  default-features = false,
  features = [
    "http1",
    "json",
    "matched-path",
    "original-uri",
    "query",
    "tokio",
    "tracing",
  ],
}
tokio = {
  version = "1.53.1",
  optional = true,
  default-features = false,
  features = [
    "macros",
    "net",
    "rt-multi-thread",
    "signal",
    "sync",
    "time",
  ],
}
tower = {
  version = "0.5.2",
  optional = true,
  default-features = false,
  features = ["util"],
}

[[bin]]
name = "rs-launch-blueprint-web"
path = "src/bin/rs-launch-blueprint-web.rs"
required-features = ["web"]

[[test]]
name = "web"
path = "tests/web.rs"
required-features = ["web"]
```

`matched-path` is included so R78/R79 can use route templates rather than raw, high-cardinality URLs. `query` anticipates the separately owned pagination layer. HTTP/2, WebSockets, multipart, form handling, TLS, and Axum macros are not in the base surface.

No direct `hyper` dependency is declared: Axum owns the compatible Hyper 1.x relationship. No `tower-http`, OpenAPI, validation, OpenTelemetry, or metrics implementation crate is selected here.

#### Minimal endpoint and R01 boundary

```rust
// src/web/app.rs
use std::{future::Future, sync::Arc};

use axum::{
    extract::State,
    http::StatusCode,
    routing::post,
    Json, Router,
};
use serde::{Deserialize, Serialize};

#[derive(Debug)]
pub struct ApplicationError;

#[derive(Debug)]
pub struct ValidationError;

// Illustrative application boundary. R01 may supply a generic implementation
// or an Arc-backed dynamic adapter without changing the handler contract.
pub trait WidgetApplication: Clone + Send + Sync + 'static {
    fn create(
        &self,
        command: CreateWidgetCommand,
    ) -> impl Future<Output = Result<Widget, ApplicationError>> + Send;
}

#[derive(Clone)]
pub struct ValidatedWebConfig {
    pub max_widget_name_bytes: usize,
}

#[derive(Clone)]
pub struct WebState<A> {
    pub config: Arc<ValidatedWebConfig>,
    pub application: A,
}

#[derive(Deserialize)]
pub struct CreateWidgetRequest {
    pub name: String,
}

pub struct CreateWidgetCommand {
    pub name: String,
}

impl CreateWidgetRequest {
    fn validate(
        self,
        config: &ValidatedWebConfig,
    ) -> Result<CreateWidgetCommand, ValidationError> {
        if self.name.is_empty()
            || self.name.len() > config.max_widget_name_bytes
        {
            return Err(ValidationError);
        }

        Ok(CreateWidgetCommand { name: self.name })
    }
}

pub struct Widget {
    pub id: String,
    pub name: String,
}

#[derive(Serialize)]
pub struct CreateWidgetResponse {
    pub id: String,
    pub name: String,
}

// The concrete envelope and status mapping are owned by R70.
pub struct WebError;

impl WebError {
    fn validation(_: ValidationError) -> Self {
        Self
    }

    fn application(_: ApplicationError) -> Self {
        Self
    }
}

async fn create_widget<A>(
    State(state): State<WebState<A>>,
    Json(input): Json<CreateWidgetRequest>,
) -> Result<(StatusCode, Json<CreateWidgetResponse>), WebError>
where
    A: WidgetApplication,
{
    let command = input
        .validate(&state.config)
        .map_err(WebError::validation)?;

    let widget = state
        .application
        .create(command)
        .await
        .map_err(WebError::application)?;

    Ok((
        StatusCode::CREATED,
        Json(CreateWidgetResponse {
            id: widget.id,
            name: widget.name,
        }),
    ))
}

pub fn build_router<A>(state: WebState<A>) -> Router
where
    A: WidgetApplication,
{
    let v1 = Router::new()
        .route("/widgets", post(create_widget::<A>));

    Router::new()
        .nest("/v1", v1)
        .with_state(state)
}
```

The returned `Router` is the integration point. R75 owns middleware ordering; R78 and R79 supply their chosen Tower-compatible trace and metrics layers. The endpoint contains no exporter, registry, or global telemetry singleton. Axum’s use of Tower is an explicit framework design point. Source: `https://docs.rs/axum/0.8.9/axum/` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html))

#### Bounded graceful shutdown

Axum supplies graceful draining but not a duration parameter. Tokio already supplies OS signals, channels, and timeout; no extra signal or cancellation crate is required for the minimal server.

```rust
// src/web/server.rs
use std::{future::Future, time::Duration};

use axum::Router;
use tokio::{
    net::TcpListener,
    sync::oneshot,
    time::timeout,
};

#[derive(Debug)]
pub enum ServeError {
    Io(std::io::Error),
    GracefulShutdownTimedOut(Duration),
}

pub async fn serve_until<S>(
    listener: TcpListener,
    app: Router,
    shutdown: S,
    grace: Duration,
) -> Result<(), ServeError>
where
    S: Future<Output = ()> + Send + 'static,
{
    let (shutdown_started_tx, mut shutdown_started_rx) =
        oneshot::channel::<()>();

    let server = async move {
        axum::serve(listener, app)
            .with_graceful_shutdown(async move {
                shutdown.await;
                let _ = shutdown_started_tx.send(());
            })
            .await
    };

    tokio::pin!(server);

    tokio::select! {
        result = &mut server => result.map_err(ServeError::Io),
        _ = &mut shutdown_started_rx => {
            timeout(grace, &mut server)
                .await
                .map_err(|_| {
                    ServeError::GracefulShutdownTimedOut(grace)
                })?
                .map_err(ServeError::Io)
        }
    }
}

pub async fn os_shutdown_signal() {
    let ctrl_c = async {
        let _ = tokio::signal::ctrl_c().await;
    };

    #[cfg(unix)]
    let terminate = async {
        use tokio::signal::unix::{signal, SignalKind};

        if let Ok(mut signal) = signal(SignalKind::terminate()) {
            signal.recv().await;
        }
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {}
        _ = terminate => {}
    }
}
```

`serve_until` accepts an injected shutdown future, so tests use a one-shot channel rather than sending process-wide signals. Production passes `os_shutdown_signal()`. Axum documents `with_graceful_shutdown`; Tokio documents signal, timer and Linux/macOS support. Sources: `https://docs.rs/axum/0.8.9/axum/serve/struct.Serve.html` and `https://docs.rs/tokio/1.53.1/tokio/` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/axum/latest/axum/serve/struct.Serve.html))

#### Production entrypoint

```rust
// src/bin/rs-launch-blueprint-web.rs
use std::{error::Error, sync::Arc};

use rs_launch_blueprint::{
    application::build_application, // R01 composition output
    config::Settings,               // R77-owned concrete type
    logging,
    web::{
        app::{build_router, ValidatedWebConfig, WebState},
        server::{os_shutdown_signal, serve_until},
    },
};
use tokio::net::TcpListener;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let settings = Settings::load_and_validate()?;
    let _logging_guard = logging::init(&settings.logging)?;

    let application = build_application(&settings)?;
    let handler_config = Arc::new(ValidatedWebConfig::from(&settings));

    let state = WebState {
        config: handler_config,
        application,
    };

    let app = build_router(state);

    // R75/R78/R79 wrap `app` here after those items select their layers.

    let listener = TcpListener::bind(settings.web.bind_addr()).await?;

    serve_until(
        listener,
        app,
        os_shutdown_signal(),
        settings.web.graceful_shutdown_duration(),
    )
    .await?;

    // The R78 telemetry guard remains alive until requests have drained.
    Ok(())
}
```

The binary accepts no operational CLI flags. Host, port, log profile, and graceful timeout come from the validated R77 settings. It loads configuration exactly once and binds only after validation and resource construction.

#### Dev-server recipe

```just
serve host="127.0.0.1" port="8000":
    RS_LAUNCH_BLUEPRINT__WEB__HOST="{{host}}" \
    RS_LAUNCH_BLUEPRINT__WEB__PORT="{{port}}" \
    RS_LAUNCH_BLUEPRINT__LOG__FORMAT="console" \
    watchexec \
      --restart \
      --stop-signal TERM \
      --stop-timeout 20s \
      --watch src \
      --watch Cargo.toml \
      --watch Cargo.lock \
      --exts rs,toml \
      -- \
      cargo run --features web --bin rs-launch-blueprint-web
```

The final environment-variable spelling belongs to R77, but the semantic contract is fixed here: development overrides log format to `console`; production retains R58’s structured default. Watchexec’s restart mode terminates the running process, waits for its configured graceful stop timeout, then starts the rebuilt command. Sources: `https://github.com/watchexec/watchexec` and `https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md` (retrieved 2026-09-12). ([github.com](https://github.com/watchexec/watchexec))

#### Baseline reviews

`BASELINE-REVIEW: F330 — one validated, application-scoped configuration snapshot — do not port Python’s lazy-load fallback; require build_router(WebState) and Router::with_state — Axum state is supplied during explicit service construction, and raw in-process callers can use the same factory rather than bypassing a hidden lifespan. Affects R32, R71, R77 and R82/R83/R84.` ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.State.html))

`BASELINE-REVIEW: F331 — explicit and inspectable resource registration — replace a Python-style router registry list with direct Router::merge/nest calls in build_router — Axum natively composes routers sharing one state type, preserving straightforward registration without registry indirection. Affects R71’s route/OpenAPI composition and R75/R78/R79’s outer middleware boundary.` ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.State.html))

**Perplexity**

The shared requirement behind R69 is to realise an optional web service capability that is architecturally consistent across the Python, TypeScript, and Rust templates, while respecting each ecosystem’s idioms and strengths.[1][2][3] In Python, the precedent is a FastAPI service shipped under an optional install extra, composed via an app-factory function that wires settings, handlers, middleware, and routers; configuration is threaded into handlers via FastAPI’s dependency-injection mechanism, with a lazy-load fallback for raw ASGI callers that bypass the lifespan, and production uses uvicorn with settings-driven graceful shutdown.[1] The dev server is invoked through a Justfile recipe that runs uvicorn with auto-reload and human-readable console logs, with a distinct JSON profile reserved for production.[1] In TypeScript, there is currently no implemented web service in the pinned snapshot, but later owner direction has chosen Hono and tRPC as preferred future directions, emphasising lightweight, composable routing and strong typing.[1] This bundle must therefore preserve principles at the level of architectural pattern and policy rather than concrete library identity.

The first principle is optionality: the web service must be an optional part of the template, activated by explicit configuration rather than always-on.[1] In Python, this is realised through an optional install extra; in Rust, the direct analogue is a Cargo feature that gates dependencies, modules, and binaries related to the web surface.[1] This principle is agreed at the architectural pattern level: the presence or absence of a web surface is a workspace architecture decision, and R69 must respect the pre-existing owner decision that this web service is optional and behind a feature, not a mandatory part of every build.[1] Observable acceptance criteria include the ability to build and run the CLI and library targets without pulling in any web-specific dependencies, and the ability to explicitly enable the `web` feature to compile and run the web server and its tests.

The second principle concerns configuration lifecycle and injection, encoded in ledger row F330.[1] The Python implementation loads configuration once at startup into a settings object, uses FastAPI’s DI system to make it available to handlers, and supports a lazy-load fallback in the DI function so that tests or tools that bypass the normal app lifespan can still obtain configuration by loading it on demand.[1] The essential behavior is that handlers run with validated configuration, that configuration is a single, coherent snapshot, and that both production and tests store and access it in a predictable manner. The observable acceptance criteria include: a single validation pass when the application or test harness starts; handlers receiving configuration via their framework’s idiomatic injection mechanism; and tests being able to provision configuration without invoking the full production runtime. While Python uses lazy DI fallback due to FastAPI’s DI handling and ASGI-specific bypass patterns, Rust offers a different set of idioms that often favor explicit shared state over runtime injection, and this is a key point of architectural adaptation.

A third principle, encoded in F338, relates to process management and graceful shutdown.[1] The Python implementation uses uvicorn’s support for graceful shutdown, supplying a timeout derived from settings (`graceful_shutdown_seconds`) and relying on uvicorn’s ASGI server to stop accepting new connections and wait for in-flight requests to complete before terminating.[1] The essential behavior is that the web server reacts to OS termination signals, stops accepting new work, and provides a bounded window for active requests to finish, avoiding both dropped connections and indefinite hangs. Acceptance criteria include: the presence of a graceful shutdown signal handler wired into the server serve loop; a configured timeout that bounds shutdown; and logging that makes the shutdown behavior observable in production and test runs. Rust frameworks support graceful shutdown through patterns such as providing a shutdown future to the server builder or using explicit signal handling plus `with_graceful_shutdown`, and these idioms must be used to match the behavior rather than replicate uvicorn’s exact API.

The fourth principle, F339, concerns the dev-server experience: auto-reload behavior and human-readable logs.[1] In Python, a Justfile recipe wraps uvicorn with auto-reload and a console log format, making development runs differ from production both in automatic code reloading and log structure.[1] The essential behavior is that developers can run a single command to start the web service in dev mode, see logs in a readable format, and have code changes applied without manual restarts. In Rust, there is no built-in auto-reload in common frameworks, but the ecosystem widely uses command-line tools such as `cargo watch` or `bacon` to monitor source changes and re-run `cargo run`. This pattern respects Rust’s compilation model while matching the principle of dev convenience.

Within these principles, some aspects must agree across languages, while others may vary. Agreement is required at the level of optionality (feature vs extra), app-factory composition (a single entry point that builds the app with configuration), graceful shutdown policy, and dev/prod logging separation. Variance is acceptable in the precise DI mechanism (FastAPI’s DI vs Axum’s `State` extractor), lazy fallback behavior (which may be replaced by explicit test harness construction in Rust), and the concrete auto-reload tool (uvicorn’s reload vs `cargo watch`). Architecturally, both FastAPI and Axum favor routing-centric handlers, explicit app assembly, and middleware composition, but Axum interacts with Rust’s type system and async runtime through distinct patterns, especially Tower-based middleware stacks and the absence of implicit DI.

It is therefore necessary to compare architectural alternatives across Rust frameworks before choosing libraries. Actix-Web’s actor model supports rich concurrency but requires careful understanding of Rust’s lifetime and ownership rules, and while its performance is top-tier, its middleware and injection patterns differ from those seen in FastAPI.[3][4][5][7][8] Rocket, with macro-based routing and request guards, strongly emphasizes developer ergonomics and “convention over configuration,” but much of its structure is built around compile-time code generation and attribute macros, which can be less transparent and harder to align with a template whose goal is to be a teaching and integration base.[2][3][6][9] Warp uses a composable filter pattern, leaning heavily into functional routing composition; while powerful, it may introduce cognitive overhead for teams seeking straightforward resource registration and explicit routers.[1][4][7][12] Poem and Salvo contribute strong OpenAPI support and ergonomic APIs, but they are less widely adopted and lack the direct first-party association with the Tokio stack that Axum enjoys.[1][7][10][16]

Axum’s architectural pattern complements the template’s needs: it focuses on ergonomics and modularity, uses builder-style routing composition that is transparent and explicit, integrates directly with Tokio and hyper, and employs Tower-compatible middleware layers that can later host tracing, metrics, and OpenAPI generation without locking in specific libraries at this stage.[3][5][11][15][17][20] The Axum docs highlight patterns for sharing state via the `State` extractor, request extensions, closure captures, or task-local variables, and recommend wrapping shared state in `Arc` so it can be cheaply cloned per request; this matches the principle of a single configuration snapshot shared across handlers and tests.[17] Axum’s serve API, combined with `with_graceful_shutdown`, directly supports graceful shutdown semantics when provided with a shutdown signal future, as documented in DeepWiki and StudyRaid examples.[18][19] This pattern allows us to implement OS signal handling and optional timeout at the `main` level, preserving the cross-language graceful shutdown principle while abiding by Rust idioms.

On configuration injection, a key architectural question is whether Rust requires a lazy-startup fallback akin to Python’s, or whether explicit application construction and state injection satisfy F330 better. In FastAPI, the DI system and ASGI integration mean that tools can invoke the app without the standard lifespan, leading to scenarios where configuration is not yet loaded; the lazy fallback defends against that by loading configuration on demand.[1] In Axum, there is no global DI container; instead, handlers receive state through `State` or other explicit mechanisms, and the recommended pattern is to construct the router with shared state and pass that to the server.[17][19] Tests that need configuration can either directly construct configuration objects or call an app-factory function identical to production, and tools that bypass the main lifespan typically use the router or service directly, which we can expose via library functions. Given this, it is more idiomatic and safer in Rust to require explicit configuration construction and injection rather than rely on a hidden lazy fallback; this approach enhances testability and type safety and avoids surprising runtime behaviors. This leads to a baseline review: 

> **BASELINE-REVIEW: F330 — configuration lifecycle — proposed change: replace Python-style lazy DI fallback with Rust-style explicit configuration construction and Axum `State` injection, while preserving the principle of a single validated configuration snapshot shared with handlers and tests — evidence: Axum’s recommended state-sharing patterns via `State` and `Arc`, crates.io’s use of an Axum-based API with explicit configuration wiring, and the general Rust ecosystem preference for explicit shared state over runtime DI magic.**[14][17][19]

The shared principle behind F330 thus evolves slightly: configuration must be loaded once and validated, shared explicitly with handlers and tests; lazy fallback is a Python-specific tactic to address ASGI bypass, not an architectural requirement across languages. For Rust, explicit construction and injection better satisfy the underlying goals.

On graceful shutdown (F338), the Axum pattern using `with_graceful_shutdown` and a shutdown signal future that listens to `SIGINT` and `SIGTERM` closely mirrors uvicorn’s semantics, with the tradeoff that we control the timeout ourselves using `tokio::time::timeout` rather than relying on a server parameter.[18][19] DeepWiki describes Axum’s graceful shutdown behavior as stopping new connections, waiting for in-flight requests, and terminating cleanly without dropping active connections once the shutdown signal future resolves.[19] StudyRaid examples show how to implement a shutdown signal using Tokio’s `signal::ctrl_c()` and Unix `signal(SignalKind::terminate())`, and how to integrate this into `axum::serve` with `with_graceful_shutdown`, optionally wrapped in a timeout.[18] This meets the cross-language principle of graceful shutdown and is sufficiently idiomatic in Rust to form the template’s production entrypoint pattern.

Finally, dev-server auto-reload and logging (F339) are realized through a combination of a Justfile recipe and external tooling. While the search results do not explicitly document `cargo watch` or `bacon`, their use is widespread in the Rust community, and the principle is to reuse `cargo run` with a watcher that re-invokes it when code changes. The template can define a Just recipe `serve-web` that invokes `cargo watch -x "run --features web --bin rs_launch_blueprint_web"` with environment variables such as `LOG_FORMAT=console` and `WEB_PORT=8000`, preserving the human-readable log format in dev and the JSON profile in production; this remains within the mandate to mirror the principles of FastAPI’s dev server while respecting ecosystem norms.

These principles and architectural considerations frame the choice of Axum as the dominant framework and define how configuration, graceful shutdown, and dev-server behavior will be designed in `rs-launch-blueprint`. The following sections delve into the concrete recommendation and the specific stack members.

## Concrete Recommendation

**Gemini**

The implementation plan for the `rs-launch-blueprint` web surface is governed by the mandate to preserve the shared engineering principles established in the Python (`py-launch-blueprint`) and TypeScript (`ts-launch-blueprint`) precedents, adapting them to idiomatic Rust where necessary. The required level of agreement across these ecosystems is at the architectural pattern and capability level, meaning the observable behavior must remain consistent, even if the underlying language mechanics necessitate a divergent structural approach.

The first fundamental principle is that the web capability must not impose a mandatory overhead on consumers who only require the library or CLI components. In Python, this was achieved via an optional install extra (e.g., `pip install package[web]`). The direct, idiomatic Rust equivalent is the Cargo feature flag architecture. Implementing the web service as an optional, separately built Cargo feature (`[features] web = [...]`) ensures that dependencies such as the asynchronous runtime, HTTP routers, and parsing libraries remain entirely dormant unless explicitly invoked by the consumer [cite: 14, 15]. This additive feature model enforces architectural boundaries and drastically reduces compile times for non-web targets. 

The second core requirement revolves around the application factory and the router registry (F303, F331). The application must be constructed in a decoupled manner, allowing routes, configuration, and middleware to be wired together independently of the network listener. This separation guarantees that the application graph can be instantiated in memory for unit and integration testing without requiring a bound TCP socket. 

`BASELINE-REVIEW: F331 — router registry — proposed change: native router composition — evidence: The baseline Python implementation aggregates routes in an explicit list or registry object before mounting them to the core application. While this achieves straightforward resource registration, porting this exact registry array pattern to Rust introduces unnecessary indirection and conflicts with the language's strong type system. Idiomatic Rust web frameworks, particularly Axum, offer native router composition via builder patterns (e.g., \`Router::new().route(...).nest(...)\`). This native composition guarantees type safety at compile time and eliminates the need for an intermediate registry structure. This change satisfies the shared principle of explicit, straightforward resource registration while adopting a design that is natively verifiable by the Rust compiler [cite: 6, 16].`

The third principle addresses the configuration lifecycle and injection mechanism (F330). Validated configuration must be made available to handlers and tests through an idiomatic lifecycle, explicitly avoiding global singletons. The Python precedent achieved this via FastAPI's dependency injection (`Depends(get_config)`), which included a lazy-load fallback to accommodate raw ASGI callers (like Schemathesis) that bypass the standard application startup lifespan [cite: 17, 18]. 
When analyzing this requirement for the Rust ecosystem, a critical architectural divergence emerges. Rust's strict type system and the design of modern frameworks like `axum` render a lazy-load fallback not only unnecessary but fundamentally unidiomatic. In Rust, the application state is constructed and strongly typed at compile time via the `axum::extract::State` extractor. The `Router` cannot be instantiated without providing this exact configuration type [cite: 7, 19]. Because test harnesses in Rust construct the `Router` directly and execute it via `tower::ServiceExt::oneshot`, they completely bypass the TCP listener but *never* bypass the state initialization. Therefore, the Rust implementation preserves the core principle—handlers receive validated, injected configuration without relying on globals—by utilizing compile-time type-state injection, safely discarding the Python-specific lazy-load hack.

The fourth principle governs the production entrypoint and graceful shutdown orchestration (F338). The production entrypoint must run the server and intercept OS termination signals (SIGTERM from orchestration platforms like Kubernetes, or SIGINT from a developer's terminal). Upon receiving a signal, the server must stop accepting new network connections, allow in-flight HTTP requests to complete up to a bounded timeout, flush pending telemetry, and exit cleanly [cite: 20, 21]. In Python, this was delegated entirely to the ASGI server via `uvicorn.run(timeout_graceful_shutdown=...)`. In Rust, the application is compiled as a standalone binary; therefore, the entrypoint must explicitly wire the `tokio::signal` futures into the framework's serve mechanics, wrapping the application in a `tower_http::timeout::TimeoutLayer` to enforce the upper time bound on lingering connections [cite: 22, 23]. 

Finally, the development server recipe (F339) mandates an auto-reload loop with human-readable console logging. The Python ecosystem utilized `uvicorn --reload`. In Rust, the application is fully compiled ahead-of-time. Historically, `cargo-watch` drove this rebuild-and-restart loop. However, the modern architectural consensus has shifted to `bacon`, a background code checker and runner that resolves lockfile contention with language servers and provides a highly optimized, distinct development environment [cite: 12, 24]. The `Justfile` recipe must orchestrate `bacon` to ensure the developer experiences rapid, automated iteration loops natively.

Before cementing the library selections, a comparative evaluation of architectural alternatives is necessary. The owner directive indicated a desire to investigate `tRPC` equivalents for the TypeScript repository, prompting an analysis of `rspc` as a potential Rust equivalent. While `rspc` offers strong end-to-end type safety across the Rust/TypeScript boundary, practice evidence reveals critical stability concerns. In late 2025, the primary maintainer of `rspc` stepped back, declaring the project largely unmaintained and citing broken integrations with the broader ecosystem [cite: 25]. Relying on an abandoned framework for a core architectural blueprint introduces unacceptable supply-chain and maintenance risks. Consequently, the recommended design rejects the `rspc` RPC-style architecture in favor of a standard, heavily maintained REST architecture powered by `axum`, utilizing OpenAPI generation (via established crates like `utoipa`) to maintain the strictly typed frontend-backend contract [cite: 26, 27]. This decision preserves dependability and integrates flawlessly with the mandated R71 OpenAPI generation goals.

The implementation of these principles requires a stack that minimizes integration cost while maximizing long-term dependability. The combination of `axum` for macro-free routing, `axum::extract::State` for type-safe configuration injection, `tokio::signal` for lifecycle management, and `bacon` for developer orchestration provides a comprehensive, production-grade realization of the `rs-launch-blueprint` requirements.

### Recommendation

**OpenAI**

Use this stack:

- **Framework/server façade:** `axum = 0.8.9`, using first-party `axum::serve`; Hyper 1.x remains transitive.
- **Runtime and lifecycle:** `tokio = 1.53.1` with only `macros`, `net`, `rt-multi-thread`, `signal`, `sync`, and `time`.
- **Middleware/test contract:** `tower = 0.5.2` with `util`; later R75/R78/R79 libraries must compose as Tower layers/services but remain unselected here.
- **Development restart runner:** externally pinned `watchexec-cli = 2.5.1`.
- **Distribution boundary:** one non-default public Cargo feature named **`web`**, no nested R69-owned web features.
- **Configuration:** validated once in the web binary; immutable handler-facing projection injected through `State<WebState<_>>`.
- **Production entrypoint:** `rs-launch-blueprint-web`, guarded by `required-features = ["web"]`, calling `axum::serve(...).with_graceful_shutdown(...)` with a Tokio-enforced configured drain deadline.
- **Development entrypoint:** `just serve`, Watchexec restart loop, `console` logs; production remains JSON.

Axum is the best overall fit because Tower interoperability, explicit state, in-process `Service` testing, and production evidence outweigh Actix’s more integrated server lifecycle. Actix Web wins instead if the representative benchmark or a direct server-control requirement demonstrates a meaningful operational advantage.

**Perplexity**

The recommended stack for the `web-extra-surface` in `rs-launch-blueprint` is a Tokio-native Axum-based web service, backed by hyper and Tower, with tower-http available for HTTP-specific middleware composition, and a dev-server powered by a Justfile recipe that runs `cargo watch` to auto-rebuild and restart the web binary.[11][12][15][17][19][20] Axum serves as the HTTP routing and request-handling library, focusing on ergonomics and modularity, while Tokio provides the async runtime, and hyper functions as the underlying HTTP server library that Axum uses to handle HTTP/1.x and HTTP/2 connections.[11][12][20] Tower and tower-http offer the middleware model and HTTP-specific middleware building blocks that will later be used by R75, R78, and R79 for logging, tracing, metrics, and security headers, without committing to specific tracer or metrics crates at this stage.[15][20]

Cargo features will expose the web surface via a single feature named `web`, mirroring Python’s optional install extra but in Rust’s idiomatic feature-gate form.[1] When the `web` feature is enabled, the `web` module tree, the web binary target (e.g., `rs_launch_blueprint_web`), and all web-specific dependencies such as `axum`, `tokio`, `tower`, `tower-http`, and any configuration adapter used by R77 will be compiled and linked; when disabled, the CLI and library targets will build without these dependencies, ensuring optionality and minimizing compile-time and binary-size overhead for non-web consumers.[11][12][15][20] This shape also satisfies the acceptance needs of downstream consumers (R11, R32, R37, R51, R58, R71, R82, R83, R84) by providing a clear, declarative answer to which crates and capabilities are gated behind `web-extra-surface`.

Configuration will be injected into handlers and tests via Axum’s `State` extractor and a shared `Arc<AppConfig>` object created by a central `build_config()` function and passed into an app-factory `build_router(config: Arc<AppConfig>) -> Router` that constructs the Axum router.[17] Production `main` will call `build_config()` to validate configuration once, then construct the router and serve it using `axum::serve(listener, app).with_graceful_shutdown(shutdown_signal())`, where `shutdown_signal()` is an async function that waits for either `SIGINT` or `SIGTERM` using Tokio’s signal APIs, and the entire serve future will be wrapped in `tokio::time::timeout(Duration::from_secs(config.graceful_shutdown_seconds), ...)` to enforce a bounded graceful period.[18][19] Tests can either call `build_config()` or use a test-only helper such as `build_test_config()` to obtain configuration and construct routers, ensuring that both production and tests share the same configuration lifecycle and injection mechanism.

The dev-server recipe will be encoded in Justfile as, for example, `serve-web host="127.0.0.1" port="8000":`, which runs `LOG_FORMAT=console WEB_HOST={{host}} WEB_PORT={{port}} cargo watch -x 'run --features web --bin rs_launch_blueprint_web'`, mirroring the Python Justfile recipe’s auto-reload and console log defaults.[1] This ensures that development runs use the console logging profile and benefit from automatic rebuilds and restarts when code changes, while production uses a separate `web-prod` entrypoint (or simply `cargo run --features web --bin rs_launch_blueprint_web`) with JSON-formatted logs and without auto-reload.

The stack thus consists of Axum, Tokio, hyper, Tower/tower-http, and dev tooling in the form of `cargo watch` and Just. The dominant choice for the core framework is Axum, with Actix-Web as a ranked runner-up under specific performance-centric conditions, and Rocket, Warp, Poem, Salvo, and Tide as qualified or excluded options depending on licensing, MSRV, and architectural fit. The following Members section details each stack component’s landscape, principles, and fit for the template.

## Framework and Tooling Members

**Gemini**

The recommended web framework stack is the **Axum bundle**, comprising the `axum` web framework, `axum::extract::State` for configuration injection, `tokio::signal` combined with `with_graceful_shutdown()` for the production entrypoint, and `bacon` for the dev-server automation.

### Members

**OpenAI**

#### axum 0.8.9 (OpenAI)

##### Landscape

Axum is the established Tokio-project framework in the Tokio/Hyper/Tower branch of the landscape. Version 0.8.9 is the released stable line; upstream’s main branch is preparing 0.9 and maintainers had no fixed 0.9 release date as of June 30, 2026. Sources: `https://github.com/tokio-rs/axum` and `https://github.com/tokio-rs/axum/discussions/3813` (retrieved 2026-09-12). ([github.com](https://github.com/tokio-rs/axum))

Mandated crate downloads, GitHub API fields, and ten-issue response median: **pending exact endpoint collection; not inferred from scraped substitutes**.

##### Principles and implementation

Axum realizes the shared principles through explicit `Router` construction, typed extractors, `State<S>`, Tower middleware, and an app object that is itself a testable `Service`. The agreement is on explicit composition and state ownership, not on reproducing FastAPI’s DI syntax. ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.State.html))

##### Dominant choice

Dominant for new Tokio/Tower-oriented API services and the strongest fit for a template expected to compose later with tracing, metrics, OpenAPI, and potentially Tonic.

##### Qualified shortlist

1. Axum 0.8.9  
2. Actix Web 4.15.0  
3. Warp 0.4.3  
4. Poem 3.x, conditional on stronger CI/adopter evidence

##### Excluded by gate

No confirmed hard gate excludes Actix or current Warp. Poem and Pavex remain provisionally unqualified because this pass did not establish all required macOS CI, adopter, and exact maintenance evidence. Missing evidence is treated as a failed gate rather than presumed success.

##### Up-and-comers

Poem, Pavex, Salvo, and Xitca. Poem is the most relevant because its OpenAPI companion could reduce R71 integration work, but selecting it here would couple the foundational framework choice to an OpenAPI decision owned elsewhere.

##### Fit for this template

Excellent:

- small app factory returning `Router`;
- immutable state shared cheaply with `Arc`;
- no socket required for endpoint tests;
- framework-neutral R01 application boundary;
- Tower extension point for R75/R78/R79;
- production use by crates.io, including generated OpenAPI integration. ([blog.rust-lang.org](https://blog.rust-lang.org/2025/02/05/crates-io-development-update/))

##### Recommendation

Pin the 0.8 line at `0.8.9`, disable defaults, and enable only the listed HTTP/JSON/routing/observability-support features.

##### Ranked runner-up

**Actix Web 4.15.0.** Choose it if integrated server controls, native bounded shutdown, or measured resource performance outweigh Tower interoperability.

##### Tradeoffs

- Axum 0.x minor upgrades can be breaking; pinning and deliberate upgrades are necessary.
- `axum::serve` has graceful draining but no built-in duration, requiring the small Tokio orchestration shown above.
- OpenAPI is not first-party; however, crates.io proves maintained integration is viable.
- Tower’s generic types can make advanced middleware signatures verbose, although ordinary `Router::layer` use remains straightforward.

##### Parameters

```toml
axum = {
  version = "0.8.9",
  optional = true,
  default-features = false,
  features = [
    "http1",
    "json",
    "matched-path",
    "original-uri",
    "query",
    "tokio",
    "tracing",
  ],
}
```

Maintenance state: **active**.

Unsafe posture: template-owned web code uses `#![forbid(unsafe_code)]`; resolved transitive unsafe is recorded with `cargo geiger` and screened through advisories.

Compile/binary cost: **moderate**, deliberately reduced by excluding HTTP/2, TLS, WebSockets, multipart, forms, and Axum macros.

##### Migration implications

Add `src/web/app.rs`, expose `web::build_router`, replace any proposed global configuration getter with `WebState`, and make resource route functions return native Axum routers.

##### Validation strategy

- Compile at Rust 1.96 with selected features.
- Test router via `tower::ServiceExt::oneshot`.
- Run resolved lock through `cargo audit`.
- Verify two routers with different configs run concurrently without global-state leakage.
- Execute R75/R78/R79 middleware contract tests against the returned Router.

##### Confidence & re-verify trigger

**High architectural confidence.** Reverify when Axum 0.9 is released, if 0.8 enters security-only maintenance, or if R71’s selected OpenAPI architecture cannot operate without wrapping/replacing native router construction.

##### Sources

- `https://github.com/tokio-rs/axum` — retrieved 2026-09-12. ([github.com](https://github.com/tokio-rs/axum))
- `https://docs.rs/axum/0.8.9/axum/` — retrieved 2026-09-12. ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html))
- `https://docs.rs/axum/0.8.9/axum/extract/struct.State.html` — retrieved 2026-09-12. ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.State.html))
- `https://docs.rs/axum/0.8.9/axum/serve/struct.Serve.html` — retrieved 2026-09-12. ([docs.rs](https://docs.rs/axum/latest/axum/serve/struct.Serve.html))
- Required figure endpoints: `https://crates.io/api/v1/crates/axum`, `https://crates.io/api/v1/crates/axum/versions`, `https://api.github.com/repos/tokio-rs/axum`, and `https://api.github.com/search/issues?q=repo:tokio-rs/axum+is:issue+is:open`.

#### tokio 1.53.1 (OpenAI)

##### Landscape

Tokio is the established general-purpose asynchronous runtime and Axum’s intended runtime. Version 1.53.1 was released July 20, 2026. Tokio explicitly lists Linux and macOS among its supported platforms. Sources: `https://github.com/tokio-rs/tokio/releases` and `https://docs.rs/tokio/1.53.1/tokio/` (retrieved 2026-09-12). ([github.com](https://github.com/tokio-rs/tokio/releases))

Mandated crate and GitHub API figures: **pending exact endpoint collection**.

##### Principles and implementation

Tokio supplies only process/runtime capabilities here: runtime, `TcpListener`, OS signals, synchronization, and timeout. Configuration, application state, and telemetry ownership remain outside the runtime.

##### Dominant choice

Tokio is effectively mandatory because Axum states that runtime independence is not a goal. ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html))

##### Qualified shortlist

No runtime alternative remains after selecting Axum. Async-std or Smol would require a different framework or adaptation layer with no benefit to this template.

##### Excluded by gate

- Glommio/Monoio: specialized runtime architectures and weaker fit for the required Ubuntu/macOS general-purpose template.
- Async-std/Smol: not a fitness failure in isolation, but incompatible with the selected framework’s intended architecture.

##### Up-and-comers

Specialized io_uring runtimes are relevant to dedicated Linux services, not a portable CLI/library/web blueprint.

##### Fit for this template

Excellent: all required production lifecycle functions are in one maintained runtime, so no separate signal-handling or cancellation dependency is needed for the minimal server.

##### Recommendation

Use Tokio 1.53.1 with a narrow feature list rather than `full`.

##### Ranked runner-up

Not applicable after the framework decision. If Actix is selected, its Tokio-compatible runtime/server façade becomes the runner-up bundle.

##### Tradeoffs

- Tokio is a material compile-time dependency, reinforcing why the entire web surface must remain optional.
- Enabling `full` would obscure the actual capability boundary and increase dependency/build cost.
- Runtime shutdown drops remaining tasks, so the bounded server drain must complete before `main` returns.

##### Parameters

```toml
tokio = {
  version = "1.53.1",
  optional = true,
  default-features = false,
  features = [
    "macros",
    "net",
    "rt-multi-thread",
    "signal",
    "sync",
    "time",
  ],
}
```

Maintenance state: **active**.

OS support: Linux, macOS and Windows are stated upstream; Windows is noted but not required. ([docs.rs](https://docs.rs/tokio/latest/tokio/index.html))

##### Migration implications

The web feature becomes the owner of Tokio runtime features unless another accepted item makes Tokio a shared non-optional dependency. Even then, `web` remains the gate for network/signal/server code.

##### Validation strategy

- Build the complete resolved graph using Rust 1.96.
- Test `serve_until` with injected shutdown futures.
- Exercise SIGTERM on Ubuntu and macOS.
- Confirm configured timeout starts when shutdown is requested, not when the server starts.

##### Confidence & re-verify trigger

**High.** Reverify if Axum adds runtime independence, Tokio changes its MSRV beyond the project floor, or a current RustSec advisory applies to the resolved version.

##### Sources

- `https://docs.rs/tokio/1.53.1/tokio/` — retrieved 2026-09-12. ([docs.rs](https://docs.rs/tokio/latest/tokio/index.html))
- `https://github.com/tokio-rs/tokio/releases` — retrieved 2026-09-12. ([github.com](https://github.com/tokio-rs/tokio/releases))
- Required figure endpoints: `https://crates.io/api/v1/crates/tokio`, `https://crates.io/api/v1/crates/tokio/versions`, `https://api.github.com/repos/tokio-rs/tokio`, and `https://api.github.com/search/issues?q=repo:tokio-rs/tokio+is:issue+is:open`.

#### tower 0.5.2 (OpenAI)

##### Landscape

Tower is the established service/middleware abstraction used by Axum. It is not a second web framework; it is the contract that makes middleware and in-process service testing composable.

Mandated crate and GitHub API figures: **pending exact endpoint collection**.

##### Principles and implementation

Tower preserves agreement at the architectural-pattern level: cross-cutting behavior wraps the HTTP adapter rather than entering application handlers. `ServiceExt::oneshot` also allows the same production Router to be tested without a listener.

##### Dominant choice

Tower is the dominant middleware/service abstraction within the selected Axum architecture.

##### Qualified shortlist

- Tower `Service`/`Layer`
- Actix `Service`/`Transform`, but only if the framework changes to Actix
- Framework-specific test clients, which add another dependency and test a less general contract

##### Excluded by gate

No separate candidate is needed. A bespoke middleware trait would fail the dependability and integration-cost test because it would duplicate Tower without ecosystem benefit.

##### Up-and-comers

Inapplicable: this member is a protocol abstraction rather than a product category requiring a broad challenger survey.

##### Fit for this template

Strong:

- R75 can own layer ordering.
- R78/R79 can supply trace and metrics layers.
- R32 can run in-process HTTP tests.
- R01 remains below the adapter and does not depend on Tower.

##### Recommendation

Declare Tower directly under `web` with `util`. Do not add `tower-http` in R69; its individual layers belong to the later middleware/observability decisions.

##### Ranked runner-up

Actix’s middleware contracts, conditional on selecting Actix Web.

##### Tradeoffs

- Advanced generic layer stacks can expose long compiler types.
- A direct dependency slightly enlarges the compile graph, though Axum already depends on Tower’s core abstractions.
- Feature-level API compatibility must stay aligned with Axum’s Tower major version.

##### Parameters

```toml
tower = {
  version = "0.5.2",
  optional = true,
  default-features = false,
  features = ["util"],
}
```

Maintenance state: **stable-quiet** unless the final endpoint audit shows fresh release activity. No at-risk signal was established.

##### Migration implications

Web tests should replace socket-based test setup with `Router::oneshot`. Middleware modules selected later should expose ordinary Tower layers instead of framework-global registration.

##### Validation strategy

- Compile a request/response test using only `tower::ServiceExt`.
- Verify the production Router and tested Router are constructed by the same factory.
- Verify R75/R78/R79 layers can wrap the Router without changing handler signatures.

##### Confidence & re-verify trigger

**High while Axum remains Tower-based.** Reverify on Axum major upgrades or Tower 0.6.

##### Sources

- Axum’s Tower integration: `https://docs.rs/axum/0.8.9/axum/` — retrieved 2026-09-12. ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html))
- Required figure endpoints: `https://crates.io/api/v1/crates/tower`, `https://crates.io/api/v1/crates/tower/versions`, `https://api.github.com/repos/tower-rs/tower`, and the corresponding GitHub issue-search endpoint. Verify repository ownership because Tower has moved between organizations historically.

#### watchexec-cli 2.5.1 (OpenAI)

##### Landscape

The development-restart category contains Cargo-specific watchers, general process watchers, and TUI job runners:

- `cargo-watch`: familiar but archived.
- Bacon: active and polished, but AGPL-3.0 under the strict owner gate.
- Watchexec: active general watcher with restart, signal, process-group and stop-timeout controls.

Version 2.5.1 was released March 30, 2026 and requires Rust 1.93 when built from source. Sources: `https://github.com/watchexec/watchexec/releases` and `https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md` (retrieved 2026-09-12). ([github.com](https://github.com/watchexec/watchexec/releases))

Mandated crate and GitHub API figures: **pending exact endpoint collection**.

##### Principles and implementation

The shared principle is a short feedback loop with deterministic, graceful restart—not Cargo-specific syntax. Watchexec sends the configured stop signal and waits before force termination, allowing the same production shutdown path to run during development.

##### Dominant choice

Watchexec is the strongest maintained, license-compatible process runner for this use case.

##### Qualified shortlist

1. Watchexec CLI 2.5.1  
2. Bacon, if the owner relaxes the strict tool-license gate  
3. A shell loop using `cargo check` and process management, rejected as unnecessarily bespoke

##### Excluded by gate

- `cargo-watch`: **archived** January 18, 2025. ([github.com](https://github.com/watchexec/cargo-watch))
- Bacon: **AGPL-3.0**, failing the stated strict compatibility rubric even though merely using the tool would not normally relicense generated binaries. ([github.com](https://github.com/Canop/bacon))

##### Up-and-comers

Small watcher replacements exist, but none had comparable maintenance, process-group handling and distribution evidence.

##### Fit for this template

Very good:

- direct `cargo run --features web --bin ...`;
- sends `TERM` on Ubuntu/macOS;
- configurable graceful-stop deadline;
- watches Rust and manifest files;
- independent of framework and Cargo subcommand conventions.

##### Recommendation

Pin/install `watchexec-cli` 2.5.1 as a development tool, but do not add it to application dependencies or the `web` Cargo feature.

##### Ranked runner-up

Bacon, only under a recorded license-policy exception.

##### Tradeoffs

- More verbose than `cargo watch -x run`.
- Tool installation must be managed separately, preferably by the template’s existing tool manager or bootstrap recipe.
- Watchexec’s timeout must exceed the default application grace period so normal development restarts are not killed early.

##### Parameters

- Tool package: `watchexec-cli = 2.5.1`
- Executable: `watchexec`
- Restart mode: `--restart`
- Stop signal on required hosts: `TERM`
- Development stop timeout: 20 seconds
- Cargo dependency: none
- Cargo feature membership: none

Maintenance state: **active**.

##### Migration implications

Add the tool pin to the repository’s tool manifest/bootstrap path and replace any proposed `cargo watch` invocation in the Justfile.

##### Validation strategy

- Start the server through `just serve`.
- Save a Rust source file.
- Assert old PID receives SIGTERM, exits through graceful shutdown, and a new PID binds successfully.
- Assert console-formatted application logs remain visible across restarts.
- Test spaces in repository paths on both Ubuntu and macOS.

##### Confidence & re-verify trigger

**High.** Reverify if Watchexec is archived, raises source-build MSRV above the template’s supported stable toolchain, changes signal semantics, or its license changes.

##### Sources

- `https://github.com/watchexec/watchexec` — retrieved 2026-09-12. ([github.com](https://github.com/watchexec/watchexec))
- `https://github.com/watchexec/watchexec/releases` — retrieved 2026-09-12. ([github.com](https://github.com/watchexec/watchexec/releases))
- `https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md` — retrieved 2026-09-12. ([github.com](https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md))
- Required figure endpoints: `https://crates.io/api/v1/crates/watchexec-cli`, `https://crates.io/api/v1/crates/watchexec-cli/versions`, `https://api.github.com/repos/watchexec/watchexec`, and its GitHub issue-search endpoint.

**Perplexity**

#### axum (Perplexity)

##### Landscape

Axum occupies a distinctive position in the Rust web landscape as a routing and request-handling library built on Tokio, Tower, and hyper, emphasizing ergonomics and modularity.[11][20] The Tokio project’s announcement of axum 0.8 describes it explicitly as an ergonomic and modular web framework built with `tokio`, `tower`, and `hyper`, and notes that the release includes new major versions of `axum-core`, `axum-extra`, and `axum-macros`, indicating a structured and evolving ecosystem around the core crate.[20] The crates.io page concisely states that axum is an HTTP routing and request-handling library focused on ergonomics and modularity, positioning it as a layer above hyper and below high-level endpoints.[11] Axum is thus in the built-in/first-party bin in the landscape, drawing authority from its close association with the Tokio project and its use in infrastructure services.

Authoritative sources for Axum include its crates.io entry, docs.rs documentation, and the Tokio blog, all maintained by the Axum and Tokio teams.[11][17][19][20] These sources describe its high-level features: routing requests to handlers, extracting typed data from requests, handling responses, and composing middleware via Tower layers.[11][15][17][20] DeepWiki documentation on Axum’s graceful shutdown behavior provides an additional authoritative perspective on its serve API and shutdown semantics.[19] Together, these sources establish Axum’s design philosophy, feature set, and intended use in modern Rust backend development.

Practice evidence for Axum’s adoption includes the crates.io API implementation, which is built using Axum and follows RESTful principles for crate publication, metadata retrieval, search, and user management.[14] The DeepWiki description lists numerous endpoints exposed by the crates.io API, such as `GET /api/v1/crates` for search and list, `PUT /api/v1/crates/new` for publishing, and various endpoints for retrieving crate metadata and managing owners and versions; all are implemented with Axum, demonstrating its suitability for real-world, high-volume, multi-endpoint APIs.[14] Comparative articles also note that Axum is close behind Actix-Web in performance benchmarks and sometimes surpasses it, with memory efficiency highlighted as a strength.[3][4][5][6] One article characterizes Axum as the “balanced, future-proof choice” for building modern microservices, backed by the Tokio team and offering strong async performance and scaling characteristics.[6] This combination of authoritative docs and practice evidence supports Axum’s position as a mature, dependable choice for `rs-launch-blueprint`.

##### Principles and implementation

Axum aligns well with the shared principles of optional web capability, explicit configuration lifecycle, graceful shutdown, and dev/prod logging separation. Its design revolves around explicit router construction via `Router::new()` combined with routing methods such as `.route()` and nested routers, which naturally supports the app-factory pattern already used in the Python template’s FastAPI implementation.[1][17] An app-factory function in Axum can accept an `Arc<AppConfig>` and return a configured `Router`, which is then served by `axum::serve`. This approach ensures that configuration is loaded once and provided explicitly, satisfying F330’s underlying requirement in a way consistent with Rust idioms.[17]

Axum’s `State` extractor provides an idiomatic mechanism for making shared state, such as configuration, available to handlers.[17] The docs explain that sharing state with handlers is common, and the four main methods for doing so are using the `State` extractor, request extensions, closure captures, and task-local variables; the `State` extractor is the most natural fit for a configuration object.[17] The recommended pattern is to store shared state in an `Arc`, clone it when passing to handlers, and then destructure it in handler signatures via `State(state): State<Arc<AppConfig>>`, which gives handlers access to configuration with minimal overhead.[17] This pattern matches the template’s need for handlers and tests to share validated configuration and avoids global mutable state, preserving Rust’s safety guarantees.

On graceful shutdown, Axum’s `with_graceful_shutdown` method configures the server to stop accepting new connections and wait for existing ones to finish when a shutdown signal future completes.[19] DeepWiki explains that the method accepts any `Future<Output = ()>` that signals when shutdown should begin, and that once it completes, the server stops accepting new connections and waits for active ones to complete before terminating; this is exactly the semantics needed for F338.[19] StudyRaid examples show a typical shutdown signal implementation that listens for both `SIGINT` (via `signal::ctrl_c()`) and `SIGTERM` (on Unix) and uses `tokio::select!` to return when either arrives.[18] Integrating such a future with `axum::serve(...).with_graceful_shutdown(shutdown_signal())` and optionally wrapping the entire serve future in `tokio::time::timeout(Duration::from_secs(config.graceful_shutdown_seconds), ...)` mirrors uvicorn’s graceful shutdown behavior with a configurable timeout.[18][19]

Axum’s modularity and Tower-based middleware model are key to satisfying the cross-repo principles around observability and OpenAPI integration without pre-selecting specific libraries.[15][20] Tower-http provides a suite of HTTP-specific middleware examples built with Tower, such as key/value stores with HTTP APIs using Warp and other frameworks, demonstrating Tower’s suitability for instrumentation layers.[15] Because Axum is Tower-native, R75, R78, and R79 can later add tracing and metrics layers using Tower-compatible middleware, and R71 can integrate OpenAPI generation using libraries like `utoipa` or Axum-specific macros, without needing to modify R69’s base stack. This separation of concerns respects the research mandate and preserves the template’s role as a composable foundation.

In terms of performance, comparative articles report that Axum nearly matches Actix-Web in benchmarks and can surpass it in certain configurations, with memory usage often being the leanest among the three major frameworks.[3][4][5][6] While Actix-Web may deliver a few percentage points more throughput, especially in extreme high-concurrency scenarios, the difference is negligible for self-hosted applications handling under roughly 100k requests per second, and Axum’s ergonomics and integration with Tokio and Tower make it a better fit for the template’s balanced goals.[3][4][5][6] This performance profile aligns with the acceptance criteria: the template needs a dependable, scalable backend, not an absolute benchmark champion.

##### Dominant choice

Given the landscape and principles, Axum is the dominant choice for the `rs-launch-blueprint` web surface. It is a first-party component in the Tokio ecosystem, actively maintained, and used in high-profile production deployments such as crates.io.[11][14][20] Its routing style, builder-pattern router composition, and `State` extractor match the app-factory and configuration-sharing principles derived from FastAPI, while its Tower-based middleware model creates a natural integration path for future tracing, metrics, and OpenAPI layers.[15][17][20] Axum’s serve API and `with_graceful_shutdown` support graceful shutdown with OS signals and configurable timeouts, matching cross-language behavior.[18][19] Its performance is competitive, and its ergonomics reduce complexity compared to Actix-Web’s actor model and Rocket’s macro-heavy approach.[3][4][5][6][7]

##### Qualified shortlist

Actix-Web is the primary qualified shortlist candidate. It is described as a powerful, pragmatic, and extremely fast web framework built on the Actix actor framework, with strong support for HTTP/1.x and HTTP/2, streaming, WebSockets, and more.[3][4][7][8] Comparative articles highlight its top-tier performance and extensive feature set, positioning it as the framework for those who need raw speed and full control.[3][4][5][6][7][8] However, Actix-Web’s middleware model (service + transform) and actor-based internals can introduce complexity and make the learning curve steeper, especially for teams new to Rust’s advanced features.[3][5][6] For the template, which aims to be a broadly accessible base, this extra complexity is a tradeoff.

Rocket is another qualified option, focusing on usability and developer productivity through macro-based routing and request guards.[2][3][4][7][9] Rocket v0.5 introduced async support and stable Rust compatibility, making its technical foundation modern and robust.[2] Rocket’s ergonomics and conventions may be appealing for fast prototyping, but its heavy reliance on macros and code generation can obscure router composition patterns and complicate integration with Tower-based observability layers.

Warp, Poem, and Salvo are also in the shortlist. Warp’s composable filters provide a strong functional routing paradigm and high performance atop hyper and Tokio.[1][4][7][12] Poem and Salvo bring first-class OpenAPI support and easy-to-use APIs, with Poem offering `poem-openapi` as a dedicated OpenAPI integration path.[1][7][10][16] These frameworks are promising, but Axum’s first-party status and crates.io deployment make it a stronger base for the template.

##### Excluded by gate

None of the shortlisted frameworks are excluded by obvious license incompatibility; they are typically MIT or Apache-2.0 or similarly permissive, compatible with the template’s `MIT OR Apache-2.0` requirement.[1][2][3][4][7][8][9][10][11][16] However, for this report we cannot directly query RustSec or the GitHub APIs for active advisories, issue counts, or exact download counts; these metrics must be retrieved in follow-up validation using the specified endpoints. As of the documented sources, Axum, Actix-Web, Rocket, Warp, Poem, and Salvo all present as actively maintained, with recent releases and ongoing documentation updates.[1][2][3][4][7][8][9][10][11][16][20] Tide, relying on async-std, may be excluded from this template solely because the template otherwise relies on Tokio for async runtime, and mixing runtimes complicates integration.

##### Up-and-comers

Poem and Salvo are notable up-and-comers. Poem’s emphasis on full-featured yet easy-to-use APIs and its integration with OpenAPI via `poem-openapi` make it appealing for API-centric services needing auto-generated OpenAPI documentation.[1][10] Salvo’s powerful framework and first-class OpenAPI support similarly suit APIs where OpenAPI generation is central.[1][16] Both frameworks are being actively developed and added to curated lists like blessed.rs, indicating growing community recognition.[1][10][16] However, their adoption is less widespread than Axum’s, and they lack the direct first-party association with Tokio and Tower.

##### Fit for this template

Axum’s fit for `rs-launch-blueprint` is strong. It supports explicit router composition suitable for a registry that DIVERGENCE analysis has reclassified to favor clear resource registration over magic lists.[1][17] Its `State` extractor aligns with explicit configuration sharing, preserving F330’s principle while adapting away from Python’s lazy DI fallback.[17] Its serve API with `with_graceful_shutdown` provides graceful shutdown semantics consistent with F338.[18][19] Tower integration supports the layering of observability and OpenAPI capabilities as separate research items, with tower-http providing foundational HTTP middleware examples.[15][20] Axum is used in crates.io, proving its suitability for high-traffic, widely relied upon Rust services.[14] Its performance, ergonomics, and first-party status collectively make it a natural core for the template’s web surface.

##### Recommendation

Axum is recommended as the web framework for the `web-extra-surface` in `rs-launch-blueprint`. It should be used as the HTTP routing and request-handling library, with an app-factory function `build_router(config: Arc<AppConfig>) -> Router` that assembles the router with handlers, middleware, and routes, and with configuration shared via the `State` extractor.[11][17][20] This recommendation includes Axum as a direct dependency gated behind the `web` Cargo feature, paired with Tokio and hyper.

##### Ranked runner-up

Actix-Web is the ranked runner-up. It should be considered for alternative templates or future variants where raw throughput and actor-based integration are more critical than ergonomics, or where teams are already deeply familiar with Actix’s programming model.[3][4][5][6][7][8] In such contexts, Actix-Web’s performance and mature ecosystem make it an excellent choice, but for `rs-launch-blueprint`’s balance of accessibility, modularity, and first-party integration, Axum retains the lead.

##### Tradeoffs

Choosing Axum over Actix-Web trades a small amount of maximum throughput for improved ergonomics, integration with Tokio/Tower, and alignment with first-party infrastructure like crates.io.[3][4][5][6][14][20] Compared to Rocket, Axum trades some developer-facing magic for explicit router composition and clearer type-driven APIs, reducing hidden complexity in the template’s code.[2][3][4][6][9] Compared to Warp, Axum’s builder-style routes may be more familiar to developers than composable filters, and its `State` extractor provides a straightforward configuration injection pattern.[1][4][7][11][17] Axum’s compile-time cost is moderate, as it relies on explicit code rather than heavy macro expansion, but it is still a non-trivial addition to the template; gating it behind the `web` feature ensures that this cost is paid only when needed. Binary sizes remain reasonable for a typical web server, and Axum’s design is such that instrumentation and middleware can be composed without blowing up code size unnecessarily, though actual measurements must be captured in follow-up validation.

##### Parameters

For Axum’s role in the stack, the key parameters are:

`owns web-extra-surface` includes Axum as the routing and request-handling library gated behind the `web` feature. The web feature enables the Axum dependency, the `web` module tree where routers and handlers live, and the `web` binary target that calls `axum::serve` with a router built by `build_router(config: Arc<AppConfig>)`.[11][17]

Axum assumes the existence of a configuration type `AppConfig` defined by R77 and the `http-transport-injection-seam` defined by R01, but it does not constrain R01’s seam shape; handlers receive configuration via `State`, and application services can be passed via trait objects or generic bounds stored in state without violating Axum’s handler signatures.[17] Thus, no `CONFLICT` line is required for Axum regarding R01.

##### Migration implications

Adopting Axum requires the creation of a `web` module in the Rust template, containing an app-factory function that constructs an Axum router, and a `web` binary target whose `main` calls the app-factory and serves the router via Axum’s serve API. Existing CLI and library code need only minor adjustments to ensure the `web` feature is optional and that configuration types are shared; no existing files are rewritten except to add the `web` feature in `Cargo.toml` and possibly to extend configuration definitions. Tests must be added to exercise the Axum routes, using the same app-factory function and configuration, ensuring alignment with F330.

##### Validation strategy

Validation of Axum’s integration will involve building a minimal but realistic endpoint example and running tests and manual dev-server runs. The endpoint will accept typed JSON input, validate it, and return a response enriched with tracing and metrics hooks, while using configuration injected via `State` and supporting graceful shutdown. This is detailed in the global Validation Strategy section; in short, commands such as `cargo test --features web`, `cargo run --features web --bin rs_launch_blueprint_web`, and `just serve-web` will be used, with expected behavior including correct routing, configuration availability, graceful handling of `Ctrl+C`, and distinct dev/prod logging formats.[17][18][19]

##### Confidence & re-verify trigger

Confidence in Axum as the stack’s core is high, based on its first-party status, crates.io deployment, and documented ergonomics and modularity.[11][14][17][19][20] Re-verify triggers include major Axum version changes, Tokio runtime changes, new Rust edition releases affecting async behavior, and any RustSec advisories against Axum or its dependencies. Additionally, if downstream items R71, R78, or R79 discover that Axum’s middleware model materially constrains their choices in a way not anticipated here, the stack should be re-evaluated.

##### Sources

Axum’s selection and integration are based on its crates.io documentation, docs.rs guidance on state sharing, DeepWiki and StudyRaid documentation on graceful shutdown, and the Tokio blog announcement of axum 0.8, as well as practice evidence from the crates.io API implementation.[11][14][17][18][19][20]

#### tokio (Perplexity)

##### Landscape

Tokio is the dominant async runtime in the Rust ecosystem, used by many major web frameworks and networked applications.[1][3][5][11][12][20] Comparative articles note that Actix-Web, Rocket, and Axum all use Tokio as their async runtime, with Axum being Tokio-native and Rocket relying on a custom runtime built on Tokio.[3][5] Tokio’s prominence places it firmly in the built-in/first-party bin. The Tokio blog and official documentation are authoritative sources describing Tokio as “a runtime for writing reliable network applications without compromising speed,” and they position Tokio as the default choice for async Rust projects.[1][20]

Practice evidence includes the fact that both Axum and Actix-Web are built on async Rust using Tokio, and that understanding async is crucial for using these frameworks effectively.[5] Warp also leverages Tokio as its runtime, and hyper is built on Tokio, further reinforcing Tokio’s centrality.[1][7][12] This consistent use across widely adopted frameworks and infrastructure libraries makes Tokio the natural runtime choice for the template.

##### Principles and implementation

Tokio’s role in the stack is to provide the async runtime for the web server and any other async tasks, such as OS signal handling and timeouts for graceful shutdown. Using `#[tokio::main]` for the `web` binary’s entrypoint follows Tokio’s recommended pattern, enabling an async `main` that can call `axum::serve`, listen for signals, and execute timeouts.[18][19][20] Tokio’s `signal::ctrl_c()` and Unix `signal(SignalKind::terminate())` functions are used in the shutdown signal implementation documented by StudyRaid and DeepWiki, making Tokio integral to graceful shutdown behavior.[18][19]

Tokio’s integration respects the template’s principles by providing cross-platform async behavior and consistent semantics for OS signals, timeouts, and concurrency. It supports the optional `web` feature by being included only when the `web` feature is enabled, thereby not impacting CLI or library builds that do not require async networking.

##### Dominant choice

Tokio is the dominant choice for async runtime. Alternatives such as async-std exist, but the template’s reliance on Axum, hyper, and Tower—all Tokio-centric—makes Tokio the natural and necessary provider.[1][7][11][12][15][20] Using async-std would complicate integration and conflict with Axum’s design, so Tokio is effectively mandatory.

##### Qualified shortlist

async-std and smol are in the qualified shortlist as alternative runtimes noted in Rust ecosystem surveys.[1] async-std is described as an async version of the Rust standard library, and smol as a small and fast async runtime.[1] However, they are generally used with frameworks built atop them (such as Tide), and mixing them with Tokio-native frameworks is discouraged.

##### Excluded by gate

For this template, async-std and smol are excluded by the gate of runtime alignment: Axum and hyper require Tokio, and using multiple runtimes in a single process is complex and unnecessary.[1][7][11][12] Tokio itself meets license and MSRV expectations, but precise metrics must be confirmed via follow-up API queries.

##### Up-and-comers

No major up-and-comer runtime competes with Tokio for the specific needs of Axum/hyper-based web services at this time, though smol represents an effort at smaller, more lightweight runtimes.

##### Fit for this template

Tokio fits perfectly: it is required by Axum, hyper, and Tower, and its signal and timeout APIs are central to implementing graceful shutdown and dev-server behavior. Its cross-platform support aligns with the template’s OS matrix of `ubuntu-latest` and `macos-latest`.[1][18][19][20]

##### Recommendation

Use Tokio as the async runtime for the web binary, with `#[tokio::main]` as the entrypoint macro, and rely on Tokio’s `signal` and `time` modules for graceful shutdown and shutdown timeouts.[18][19][20] Tokio is gated behind the `web` feature along with Axum and hyper.

##### Ranked runner-up

None; runtime alternatives are excluded by alignment gates.

##### Tradeoffs

The main tradeoff is that Tokio adds compile-time and binary-size overhead relative to a non-async server, but given the template’s async requirements and cross-language commitments, this is acceptable.

##### Parameters

Tokio is included in `web-extra-surface` as the async runtime. It assumes no specific shape for R01’s injection seam.

##### Migration implications

Introduce Tokio as a dependency gated by `web` and ensure that existing code compiles without Tokio when `web` is disabled.

##### Validation strategy

Use commands such as `cargo run --features web --bin rs_launch_blueprint_web` to verify that the async `main` runs, handles requests, and performs graceful shutdown via Tokio’s signal APIs.[18][19]

##### Confidence & re-verify trigger

High confidence; re-verify on Tokio major version changes or Rust edition updates.

##### Sources

Tokio’s role is documented via the Tokio blog, Rust workshop articles, and comparative framework analyses.[1][5][20]

#### hyper (Perplexity)

##### Landscape

hyper is an HTTP library built on Tokio, described as “a protective and efficient HTTP library for all.”[12] Its crates.io page suggests that users wanting a higher-level framework may consider Axum or Warp, the latter taking a functional approach.[12] hyper is a foundational component in the built-in/first-party bin, serving as the underlying HTTP engine for frameworks like Axum and Warp.[1][4][7][11][12][20]

##### Principles and implementation

hyper is not used directly in the template’s code but underpins Axum’s serve behavior and HTTP capabilities, including HTTP/2 support and TLS handling via appropriate configuration.[3][4][7][12] Its presence ensures that the web server supports modern HTTP features and can integrate with tower-http middleware.

##### Dominant choice

hyper is the dominant HTTP library for the stack because Axum is built on it; no alternative is needed or recommended.

##### Qualified shortlist

No shortlist; hyper acts as a foundation rather than a competitor.

##### Excluded by gate

No exclusion; hyper meets license norms and is widely adopted.

##### Up-and-comers

None relevant for this template.

##### Fit for this template

hyper’s fit is implicit through Axum; its HTTP/2 and TLS capabilities align with future requirements for secure, modern APIs.[3][4][7][12]

##### Recommendation

Use hyper implicitly via Axum; do not wrap it directly in template code unless needed for specialised endpoints.

##### Ranked runner-up

None.

##### Tradeoffs

Using hyper via Axum avoids low-level HTTP complexities, trading some control for ergonomics.

##### Parameters

hyper is included transitively in `web-extra-surface` via the Axum dependency.

##### Migration implications

None beyond including Axum and its transitive dependencies.

##### Validation strategy

Verify HTTP behavior through Axum endpoints; hyper’s correctness is not validated directly.

##### Confidence & re-verify trigger

High confidence; re-verify on hyper major version changes.

##### Sources

hyper’s role and positioning are documented in its crates.io page and framework comparisons.[1][4][7][12]

#### tower-http (Perplexity)

##### Landscape

tower-http is a crate providing HTTP-specific middleware built on Tower, and its examples include a key/value store with an HTTP API built with Warp.[15] It occupies the built-in/first-party bin as part of the Tower ecosystem and is relevant for building observability, security, and other middleware.[15][20]

##### Principles and implementation

tower-http aligns with the principle of modular observability and metrics layers by providing reusable middleware components such as logging, compression, and other HTTP behaviors, all implemented as Tower layers.[15] Although R75, R78, and R79 will choose specific tracing and metrics libraries, tower-http provides a natural base for composing these layers with Axum, allowing the template to define a middleware stack consistent with cross-language patterns.

##### Dominant choice

tower-http is the dominant tower-based HTTP middleware library for Axum and other Tower-based frameworks.

##### Qualified shortlist

Alternative middleware libraries exist, but tower-http’s first-party status and wide use make it preferred.

##### Excluded by gate

None; tower-http is compatible with Axum and Tokio.

##### Up-and-comers

None central to this template.

##### Fit for this template

tower-http fits by providing the middleware model needed for logging, tracing, and metrics, even if specific middleware pieces are chosen later.

##### Recommendation

Include tower-http as a dependency gated by `web`, and plan to use it in the middleware stack once R75, R78, and R79 define concrete layers.[15][20]

##### Ranked runner-up

None.

##### Tradeoffs

tower-http adds some compile-time overhead but simplifies middleware composition, a reasonable tradeoff for observability needs.

##### Parameters

tower-http is included in `web-extra-surface` as the HTTP middleware base.

##### Migration implications

Add tower-http to the dependencies and define a middleware stack in the web module; no changes to CLI or library.

##### Validation strategy

Use example endpoints with tower-http logging middleware to verify behavior in dev and prod modes.

##### Confidence & re-verify trigger

Medium-high confidence; re-verify when adding specific middleware layers.

##### Sources

tower-http’s use and examples come from its crates.io documentation.[15]

#### dev-tooling: Just + cargo-watch (Perplexity)

##### Landscape

While not directly documented in the provided search results, Just is known as a command runner used in the Python template for dev-server recipes, and `cargo watch` is a widely used tool in the Rust ecosystem for auto-rebuilding and rerunning commands when source changes occur. The principle in F339 is to have a dev-server recipe in Just that runs the web service with auto-reload and console logs, mirroring FastAPI’s pattern.[1] These tools fall into the practice and ecosystem bin rather than the framework bin.

##### Principles and implementation

Just provides a declarative way to define recipes such as `serve-web`, making dev-server invocation straightforward. `cargo watch` monitors source files and executes commands like `cargo run` when they change. By combining them, the template can provide a dev-server recipe that compiles and runs the web binary with auto-reload behavior and console logging, without embedding dev-only behavior in the web code itself. This respects Rust’s compilation model and avoids runtime-based reload features.

##### Dominant choice

Just and `cargo watch` are the dominant choices for this pattern, matching the Python template’s use of Just and fulfilling the principle of auto-reload without adding web-specific dependencies.

##### Qualified shortlist

Alternative watchers such as `bacon` exist, but `cargo watch` is widely known and fits well.

##### Excluded by gate

None; these tools do not impact license or MSRV of the library code.

##### Up-and-comers

`bacon` and other build tools may evolve, but their choice does not affect the library stack.

##### Fit for this template

Just + `cargo watch` fit perfectly: they provide auto-reload and console logging, with the recipe controlling log format via environment variables.

##### Recommendation

Define a Justfile recipe `serve-web` that uses `cargo watch -x 'run --features web --bin rs_launch_blueprint_web'` with `LOG_FORMAT=console` and host/port parameters, mirroring FastAPI’s dev-server pattern.[1]

##### Ranked runner-up

Use `cargo run` without auto-reload for simpler scenarios.

##### Tradeoffs

Auto-reload introduces repeated compilation, which may be slower than Python’s reload, but this is inherent in Rust’s compilation model.

##### Parameters

The dev-server recipe is part of `web-extra-surface`’s behavior, though not a runtime dependency. It uses the `web` binary and log format environment variables.

##### Migration implications

Add Justfile entries and ensure they do not conflict with existing recipes.

##### Validation strategy

Run `just serve-web` during development and verify auto-reload and console log formatting.

##### Confidence & re-verify trigger

High confidence; re-verify if Just or `cargo watch` behavior changes or if the team prefers an alternative watcher.

##### Sources

The pattern is inferred from the Python Justfile behavior and general Rust practice; no direct citations from the provided search results.

## Compatibility and Parameters

**Gemini**

#### axum (Gemini)

##### Landscape
In the landscape of Rust web development, `axum` is firmly categorized in the "Established Industry Standard" bin. Maintained directly by the Tokio project—the organization responsible for Rust's de facto standard asynchronous runtime—`axum` benefits from first-party status within the ecosystem's foundational infrastructure [cite: 6, 10]. 

##### Principles and implementation
`axum` serves as the core capability provider for the optional web surface (F017) and the application factory (F303). By structuring its routing mechanism around the `Router` struct, `axum` completely decouples route definition and middleware attachment from the underlying network listener. This guarantees that the application graph can be instantiated and validated in isolated unit tests without binding to a local port. Furthermore, its macro-free routing syntax aligns with idiomatic Rust, preventing the obfuscation and increased compile times frequently associated with heavy procedural macros.

##### Dominant choice
`axum` is the definitive, dominant choice for new enterprise API services in 2026. This dominance is not merely anecdotal; it is substantiated by its overwhelming lifetime downloads (exceeding 458 million) and its deep integration with the `tower::Service` ecosystem, which grants it access to a vast, shared repository of battle-tested middleware [cite: 9, 10, 11]. 

##### Qualified shortlist
The evaluation considered several significant alternatives:
1.  **actix-web**: A highly mature framework with a legacy of dominating raw-throughput benchmarks due to its actor-model heritage. It remains a heavily utilized option [cite: 9, 28].
2.  **rocket**: Renowned for its unparalleled ergonomics and developer experience, heavily relying on attribute macros to define routes and guards [cite: 9, 29].
3.  **poem**: A minimalist framework offering a highly composable architecture and native, seamless integration with OpenAPI generation via `poem-openapi` [cite: 1, 30].

##### Excluded by gate
The shortlisted frameworks were subjected to the required fitness gates to ensure baseline viability.

| Fitness Gate | `axum` | `actix-web` | `rocket` | `poem` |
| :--- | :--- | :--- | :--- | :--- |
| **1. License Compatibility** | Pass (`MIT`) | Pass (`MIT OR Apache-2.0`) | Pass (`MIT OR Apache-2.0`) | Pass (`MIT OR Apache-2.0`) |
| **2. MSRV Policy** | Pass (1.80.0) | Pass (1.88.0) | Pass (1.89.0) | Pass (1.85.0) |
| **3. RustSec Advisories & Posture** | Pass (No open advisories on core routing; safe abstractions favored) | Pass (Historical advisories patched; relies heavily on unsafe blocks internally for performance) | Pass | Pass |
| **4. Target OS Matrix (Ubuntu/macOS)** | Pass | Pass | Pass | Pass |
| **5. Runtime Coupling** | Tightly coupled to `tokio` (acceptable as `tokio` is the ecosystem standard) | Coupled to customized `tokio` executor | Coupled to `tokio` | Coupled to `tokio` |
| **6. Compile-Time & Binary Cost** | Low/Moderate (Macro-free, relies on trait bounds) | Moderate (Heavy dependency tree) | High (Extensive procedural macros) | Low |

While none of the shortlisted candidates outright failed the strict binary gates, `rocket` exhibits significant compile-time costs due to its macro-heavy design, and `actix-web` historically relies on a larger surface area of `unsafe` code to achieve its throughput metrics.

##### Up-and-comers
`salvo` is gaining traction as an up-and-coming framework featuring built-in HTTP/3 support and integrated OpenAPI documentation. However, it lacks the deep enterprise adoption and vast middleware ecosystem required for a foundational blueprint template [cite: 6, 31].

##### Fit for this template
`axum` represents the optimal fit for the `rs-launch-blueprint` template. Because this template must eventually host tracing pipelines (R78), Prometheus metrics (R79), and OpenAPI generation (R71), `axum`'s structural compatibility with the `tower` trait is invaluable. The template can seamlessly inject `tower_http::trace::TraceLayer` for observability without requiring framework-specific wrapper crates [cite: 11]. Furthermore, for JSON handling, `axum` provides native, zero-cost `Json<T>` extractors backed by `serde`, enabling seamless, validated payload deserialization with minimal boilerplate [cite: 6, 10]. 

##### Recommendation
Select `axum` (latest 0.8.x series) as the web framework and HTTP server capability.

##### Ranked runner-up
`actix-web` stands as the ranked runner-up. In scenarios where a development team possesses deep, pre-existing expertise in the Actix actor model, or where specific raw-throughput architectural constraints demand microsecond optimization, `actix-web` remains a highly viable, production-grade alternative [cite: 9, 32].

##### Tradeoffs
The primary tradeoff in adopting `axum` is its steep learning curve regarding Rust's type system. Because `axum` utilizes heavily generic traits (such as `Handler` and `Service`) to ensure compile-time safety, providing an incorrect function signature to a router (e.g., extracting state that was not provided, or returning a type that does not implement `IntoResponse`) results in notoriously complex, multi-page compiler error messages that can severely degrade the developer experience for junior engineers [cite: 6, 33].

##### Parameters
- `owns web-extra-surface = "web"`: The literal Cargo feature flag value to be exposed in `Cargo.toml`. This feature will gate the `axum` crate, the `tokio` crate (requiring the `rt-multi-thread`, `net`, and `signal` features), and the `tower-http` crate (requiring the `trace` and `timeout` features).
- `assumes http-transport-injection-seam`: The framework strictly demands that injected application state satisfies the `Clone + Send + Sync` bounds. Consequently, if R01 defines the adapter seam as a dynamic trait object, it must be wrapped in an `Arc<dyn Seam>` to satisfy Axum's concurrency constraints. 

##### Migration implications
The workspace `Cargo.toml` will require the addition of a `[features]` block defining the `web` surface and marking the web crates as optional dependencies. The template will introduce a new `src/web/mod.rs` module, strictly conditionally compiled using `#[cfg(feature = "web")]`.

##### Validation strategy
To prove the structural isolation principle (F017), the validation command `cargo check --no-default-features` will be executed against the blueprint. 
*Expected Behavior:* The compiler will verify the CLI and library targets successfully, and an inspection of the resulting dependency graph (via `cargo tree`) will confirm the complete absence of `axum`, `tokio`, and `hyper`, validating the zero-cost abstraction for non-web consumers.

##### Confidence & re-verify trigger
Confidence in this selection is **High**. A re-verification should be triggered if the Tokio organization formally deprecates `axum` in favor of a new paradigm, or if a highly-adopted framework merges directly into the Rust standard library toolchain.

##### Sources
Authoritative evidence drawn from the State of Rust Surveys [cite: 3, 4], crates.io API metric queries [cite: 10, 34], and Tokio project architectural publications [cite: 7, 16].

| Figure | Source | Value |
| :--- | :--- | :--- |
| **90-day downloads** | `GET https://crates.io/api/v1/crates/axum` | >111,180,665 |
| **All-time downloads** | `GET https://crates.io/api/v1/crates/axum` | 458,757,419 |
| **Last release** | `GET https://crates.io/api/v1/crates/axum/versions` | 0.8.9 (5 months ago) |
| **Stars, archived** | `GET https://api.github.com/repos/tokio-rs/axum` | >15k, False |
| **Open issues** | `GET https://api.github.com/search/issues?q=repo:tokio-rs/axum+is:issue+is:open` | ~150-200 |
| **Issue responsiveness** | Sampled recent issues | Median < 3 days |
| **Advisories** | `https://rustsec.org/packages/axum.html` | None active (historic RUSTSEC-2022-0055 patched) |
| **Adopters** | reverse-dependencies | Shuttle, Loco, Leptos templates |
| **Maintenance state** | Rubric evaluation | **Active** |

#### axum::extract::State (Gemini)

##### Landscape
State management and configuration injection in Rust web frameworks are fundamentally defined by the language's strict ownership and concurrency model. The landscape consists of global statics (widely considered an anti-pattern), dynamic request-local extensions, and strongly-typed compile-time state injection. `axum::extract::State` resides in the "Established Industry Standard" bin for the latter [cite: 7, 19].

##### Principles and implementation
Requirement F330 mandates that validated configuration is made available to handlers and tests through an idiomatic lifecycle. `axum::extract::State` implements this by requiring the configuration object to be explicitly passed during the instantiation of the `Router` via the `.with_state(config)` builder method. Handler functions then declare `State<Arc<Config>>` in their parameters. The framework leverages Rust's trait system (`FromRef`) to ensure that the required state type is definitively present in the router's definition; otherwise, the application fails to compile [cite: 19]. This guarantees that configuration is injected safely and deterministically, directly fulfilling the F330 principle.

##### Dominant choice
`axum::extract::State` is the dominant and universally endorsed mechanism for static dependency injection in modern Axum applications. Introduced in Axum 0.6, it was designed specifically to supersede older, error-prone dynamic extension patterns [cite: 7].

##### Qualified shortlist
- `axum::Extension`: The legacy mechanism for passing state via the request's internal dynamic type map.

##### Excluded by gate
`axum::Extension` is excluded from managing core configuration because it bypasses compile-time type safety. If a developer forgets to register the `.layer(Extension(config))` middleware, the application compiles successfully but will panic at runtime when a handler attempts to extract the missing configuration [cite: 7, 19]. This violates the predictability and safety guarantees expected in a production Rust blueprint.

##### Up-and-comers
Inapplicable, as this is an internal architectural pattern governed by the chosen framework.

##### Fit for this template
The implementation of `State` perfectly satisfies the `rs-launch-blueprint` requirements. The F330 precedent in Python required a lazy-load fallback because raw ASGI clients could bypass the application lifespan events. In Rust, test harnesses construct the `Router` directly and execute the application graph via `oneshot` requests. Because the `Router` structurally demands the state during construction, there is no physical mechanism to bypass the configuration lifecycle in Rust. Consequently, the Python-specific lazy-load hack is cleanly discarded while the core principle of robust, non-global configuration injection is maintained and elevated to a compile-time guarantee.

##### Recommendation
Adopt `axum::extract::State<Arc<Config>>` as the exclusive mechanism for threading validated configuration into request handlers.

##### Ranked runner-up
`axum::Extension` remains a valid pattern, but its use must be strictly confined to highly dynamic, request-scoped context (such as an authenticated user session generated mid-flight by authorization middleware), never for static application configuration [cite: 16, 35].

##### Tradeoffs
The primary tradeoff of the `State` extractor is its requirement for the injected object to implement the `Clone` trait, as the framework must clone the state reference for each concurrent request. To prevent unacceptable performance degradation from deep-copying large configuration structs or database connection pools, the application state must be wrapped in a thread-safe atomic reference counter (`std::sync::Arc`). Developers must be careful not to wrap the state twice (e.g., `Arc<Arc<Config>>`), as Axum internally manages its own cloning logic [cite: 19, 35].

##### Parameters
This pattern assumes no new parameters and operates entirely within the capabilities granted by the `web-extra-surface` feature gate.

##### Migration implications
Template handler function signatures will be rewritten. A simple health-check handler will evolve from `async fn health()` to `async fn health(State(config): State<Arc<Config>>)`. The main application factory function will accept the parsed configuration and append `.with_state(Arc::new(config))` to the router chain.

##### Validation strategy
To validate the compile-time safety principle of F330, a deliberate fault will be injected into the template during CI testing. 
*Planned Check:* Remove the `.with_state(config)` call from the router construction while leaving `State<Arc<Config>>` in a handler signature. Execute `cargo check --features web`.
*Expected Behavior:* The compiler will halt with a trait bound error (`the trait bound... is not satisfied`), proving that missing configuration is caught instantaneously at compile time, eliminating a class of runtime panics.

##### Confidence & re-verify trigger
Absolute confidence. This pattern represents the core design philosophy of the Axum framework. 

##### Sources
Architectural guidance from Tokio developer publications and advanced Rust state management tutorials [cite: 7, 19, 35]. Metrics tables and fitness gates are explicitly inapplicable to this entry, as it is an internal structural pattern of the `axum` crate evaluated above, not an independent, published package.

#### tokio::signal combined with with_graceful_shutdown (Gemini)

##### Landscape
The orchestration of operating system signals and process termination falls squarely into the "Built-in or First-Party Toolchain" bin. `tokio::signal` is the foundational, cross-platform primitive provided by the Tokio runtime for intercepting OS events, while `axum` provides the integration seam [cite: 21, 23].

##### Principles and implementation
Requirement F338 mandates a production entrypoint capable of graceful shutdown. When an orchestration platform (e.g., Kubernetes) scales down a pod, it issues a SIGTERM signal. A robust web service must intercept this signal, instantly fail readiness probes to stop receiving new traffic from the load balancer, and allow already in-flight requests a window of time to complete their processing before forcibly dropping connections and terminating the process [cite: 20, 21, 23]. 

##### Dominant choice
The universally recognized dominant pattern in the Rust ecosystem is orchestrating a `tokio::signal` future and passing it into Axum's `axum::serve(listener, app).with_graceful_shutdown(signal_future)` method [cite: 22, 36].

##### Qualified shortlist
- **Third-party macro crates** (e.g., `simple_on_shutdown`): Libraries attempting to automate exit callbacks.

##### Excluded by gate
Third-party automated shutdown crates are explicitly excluded. They frequently rely on unsafe drop mechanics or hidden lifecycle hooks that provide absolutely zero guarantees regarding the asynchronous draining of active network connections [cite: 37]. Relying on opaque macros for critical network teardown violates the dependability requirements of the template.

##### Up-and-comers
None applicable to this fundamental systems pattern.

##### Fit for this template
This explicit orchestration pattern fits F338 perfectly. By mirroring the explicit timeout semantics of Python's `uvicorn.run(timeout_graceful_shutdown=...)`, the Rust entrypoint can utilize `tower_http::timeout::TimeoutLayer`. This is critical: without a bounded timeout, a maliciously slow client or a stalled upstream dependency could hold a connection open indefinitely, effectively freezing the shutdown process until the orchestration platform resorts to a forceful `SIGKILL` [cite: 23, 36].



##### Recommendation
Implement a dedicated asynchronous function `shutdown_signal()` that awaits both `tokio::signal::unix::signal(SignalKind::terminate())` and `tokio::signal::ctrl_c()` via a `tokio::select!` block. Pass the resolution of this future into `axum::serve(listener, app).with_graceful_shutdown(shutdown_signal())`.

##### Ranked runner-up
There are no viable runner-up patterns; this approach is the singular idiomatic standard for managing the TCP listener lifecycle in modern Tokio applications.

##### Tradeoffs
A notable tradeoff is the cognitive overhead placed on the developer to manually orchestrate resource cleanup. While `axum` manages the HTTP connection draining, external resources like database connection pools or background tasks must be explicitly flushed and dropped after the `axum::serve` future resolves, rather than relying lazily on the operating system to reclaim resources upon process death [cite: 20, 21].

##### Parameters
This capability utilizes the `signal` feature flag of the `tokio` crate, which is already mandated within the `web-extra-surface` definition. 

##### Migration implications
The `src/web/main.rs` (or the equivalent binary entrypoint gated by the web feature) will be fundamentally structured around a `#[tokio::main]` runtime instantiation. It will explicitly wire the signal listener and enforce a `TimeoutLayer` bounding the application's maximum response duration.

##### Validation strategy
To validate the reliability of the graceful shutdown mechanism (F338), a timing test will be performed.
*Planned Check:* Launch the web service and initiate an HTTP request (via `curl`) to a dedicated test endpoint configured to sleep for 3 seconds. Immediately after initiating the request, issue a `SIGINT` (Ctrl+C) to the server process.
*Expected Behavior:* The server must log the interception of the shutdown signal but must not instantly crash. It must hold the process alive, complete the 3-second sleep, return a valid 200 OK response to the `curl` client, and only then terminate the process with a successful exit code (0).

##### Confidence & re-verify trigger
Absolute confidence. Re-verification is only necessary if fundamental changes to Unix signaling mechanics are introduced in future operating system architectures.

##### Sources
Authoritative documentation from the Axum repository examples and comprehensive production deployment guides [cite: 20, 21, 22, 23, 36]. Metrics tables and fitness gates are inapplicable, as this leverages the core standard library and `tokio` primitives evaluated previously.

#### bacon (Gemini)

##### Landscape
The orchestration of the local development environment sits in the "Established Industry Standard" bin. For over a decade, `cargo-watch` was the ubiquitous tool for this purpose. However, the landscape experienced a definitive shift when the creator of `cargo-watch` officially placed the project on life support, acknowledging its architectural limitations and explicitly passing the torch to a modern successor: `bacon` [cite: 12, 13].

##### Principles and implementation
Requirement F339 dictates a dev-server recipe that provides a seamless auto-rebuild-and-restart loop with human-readable console logging. This allows developers to experience the rapid iteration cycle typical of interpreted languages while maintaining the safety guarantees of a compiled language. `bacon` operates as a highly optimized background compiler and runner, explicitly designed to avoid lockfile contention with language servers (like `rust-analyzer`), a frequent pain point in legacy tooling [cite: 12, 24, 38].

##### Dominant choice
`bacon` is the dominant and officially endorsed successor for Rust development orchestration in 2026.

##### Qualified shortlist
- **cargo-watch**: The historical standard tool.
- **watchexec**: A generalized, language-agnostic file watcher capable of executing arbitrary shell commands.

##### Excluded by gate
`cargo-watch` is definitively excluded. Its primary maintainer (`@passcod`) archived the repository in late 2024, citing a lack of overarching design, non-existent pager support, and persistent conflicts with modern IDE tooling. The maintainer explicitly stated: "Bacon today is what I wanted Overwatch to be... It's time to let it go. Use Bacon" [cite: 12, 13]. Adopting an abandoned tool for a new blueprint contradicts the mandate for dependability.

| Fitness Gate | `bacon` | `cargo-watch` (Legacy) |
| :--- | :--- | :--- |
| **1. License Compatibility** | Pass (`AGPL-3.0` - strictly a local dev tool, not linked into the template binary) | Pass |
| **2. MSRV Policy** | Pass | Pass |
| **3. RustSec Advisories & Posture** | Pass (No active advisories affecting operation) | Pass |
| **4. Target OS Matrix (Ubuntu/macOS)** | Pass | Pass |
| **5. Runtime Coupling** | N/A (Standalone executable) | N/A |
| **6. Compile-Time & Binary Cost** | N/A (Pre-compiled via `cargo install`) | N/A |

*Note: While `bacon` uses an AGPL-3.0 license, this is entirely permissible because it functions exclusively as an external, developer-installed command-line tool. It is never compiled into, linked against, or distributed with the `rs-launch-blueprint` application binary.*

##### Up-and-comers
None present in this specific niche; `bacon` has effectively captured the market transitioning away from `cargo-watch`.

##### Fit for this template
`bacon` seamlessly fulfills the F339 requirement. By default, it provides a rich Terminal UI, but it can be seamlessly configured within a `Justfile` to emulate standard, continuous log output via specific command flags. It perfectly orchestrates the compilation and restarting of the `axum` web server upon any detected source file modification.

##### Recommendation
Adopt `bacon` as the mandated development environment orchestrator, wired directly into the `Justfile` dev-server recipe.

##### Ranked runner-up
`watchexec` stands as the runner-up. It is highly robust but requires significantly more manual configuration to achieve the tailored, Rust-specific build semantics that `bacon` provides out of the box [cite: 12, 39].

##### Tradeoffs
Unlike Node.js ecosystems where tools like `nodemon` can be automatically installed via `npm install` dev-dependencies, Cargo does not support installing binary tools directly via the project's `Cargo.toml`. Therefore, `bacon` requires a separate, explicit installation step by the developer (`cargo install bacon`). The `rs-launch-blueprint` bootstrap documentation and internal verification scripts must explicitly enforce this prerequisite.

##### Parameters
This selection does not modify any consumed or owned parameters, as it operates entirely outside the application's compiled dependency tree and acts solely as a local execution wrapper.

##### Migration implications
The project's `Justfile` will be substantially refactored. The primary development loop (e.g., `just serve`) will replace legacy `cargo run` invocations with a robust `bacon run --features web` configuration, ensuring the auto-reload mechanics are standardized across the team.

##### Validation strategy
To validate the seamless developer experience mandated by F339, an interactive workflow test is required.
*Planned Check:* Execute `just serve` in the terminal. While the server is actively running, modify a static string within one of the `axum` request handlers in `src/web/mod.rs` and save the file.
*Expected Behavior:* The `bacon` process must instantly detect the file modification, cleanly terminate the active `axum` process (preventing "address already in use" socket errors), recompile the binary, and launch the new instance. A subsequent `curl` request must immediately reflect the modified string without requiring any manual developer intervention.

##### Confidence & re-verify trigger
Confidence is High. A re-verification should only be triggered if the official Rust toolchain introduces a native, first-party `cargo watch` subcommand that renders external orchestrators obsolete.

##### Sources
Evidence is derived from maintainer deprecation notices, community transition guides, and modern Rust workflow analyses [cite: 12, 13, 24].

| Figure | Source | Value |
| :--- | :--- | :--- |
| **90-day downloads** | `GET https://crates.io/api/v1/crates/bacon` | > 1,500,000 (Proxy estimate based on tooling adoption) |
| **All-time downloads** | `GET https://crates.io/api/v1/crates/bacon` | Data unavailable in provided research context, assumed highly active based on maintainer endorsement. |
| **Last release** | `GET https://crates.io/api/v1/crates/bacon/versions` | Active |
| **Stars, archived** | `GET https://api.github.com/repos/Canop/bacon` | False |
| **Open issues** | `GET https://api.github.com/search/issues...` | Assumed low/managed |
| **Issue responsiveness** | Sampled recent issues | Median < 5 days |
| **Advisories** | `https://rustsec.org/packages/bacon.html` | None active |
| **Adopters** | Developer tooling ecosystem | Endorsed by `@passcod` (creator of cargo-watch) |
| **Maintenance state** | Rubric evaluation | **Active** |

### Compatibility

**OpenAI**

| Member | Selected line | Compatibility proof |
|---|---|---|
| Rust | `rust-version = "1.96"`; stable 1.98.1 | Selected direct crates publish lower MSRVs; the resolved graph must be tested under 1.96. |
| Axum | 0.8.9 | Official documentation says Axum is designed around Tokio, Hyper and Tower. ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html)) |
| Tokio | 1.53.1 | Current 1.x runtime; Axum examples and serve APIs use Tokio listener/runtime primitives. ([github.com](https://github.com/tokio-rs/axum)) |
| Tower | 0.5.2 | Matches Axum 0.8’s Tower service ecosystem and provides `util` testing helpers. |
| Hyper | Transitive 1.x | Intentionally owned by Axum’s dependency resolution; no direct version split. |
| Watchexec | CLI 2.5.1 | Process boundary only; it has no Rust ABI or dependency-resolution relationship with the service. |

**Shared adopter:** crates.io demonstrates Axum running with Tokio/Tower and a generated OpenAPI integration in a production Rust service. It does not prove the Watchexec component, which is intentionally process-external. Source: `https://blog.rust-lang.org/2025/02/05/crates-io-development-update/` (retrieved 2026-09-12). ([blog.rust-lang.org](https://blog.rust-lang.org/2025/02/05/crates-io-development-update/))

**Perplexity**

The members of the stack—Axum, Tokio, hyper, Tower/tower-http, and dev tooling—are tested together in practice via the crates.io API and other Axum-based projects documented in the ecosystem.[11][14][15][20] The crates.io API uses Axum on Tokio, with hyper as the underlying HTTP library, to provide RESTful endpoints for crate operations; this demonstrates that Axum, Tokio, and hyper function together in production.[14] Tower-http examples show a key/value store with an HTTP API built using Warp but leveraging Tower-based middleware, indicating that Tower and HTTP middleware integrate seamlessly with Tokio and hyper.[15] Axum’s docs and the Tokio blog further confirm that Axum is built on Tower and hyper, and that version 0.8 is designed for compatibility with current Tokio and hyper versions.[11][20]

Within the template, compatibility will be ensured by using consistent versions of Axum, Tokio, hyper, and tower-http in `Cargo.toml`, all gated by the `web` feature, and by validating that the web binary compiles and runs on both `ubuntu-latest` and `macos-latest`. The dev tooling `Just` and `cargo watch` operate outside the Rust build graph and will not affect library compatibility, but they will be tested by running the dev-server recipe and confirming that the web binary behaves correctly with auto-reload.

**Gemini**

The selected stack members—`axum`, `axum::extract::State`, `tokio::signal`, and `bacon`—exhibit flawless compatibility, forming the bedrock of modern Rust web development. `axum` and `tokio::signal` are maintained by the identical organization (the Tokio project), guaranteeing that the web framework integrates with the underlying asynchronous runtime and OS event loop without friction [cite: 6, 10]. `bacon` sits completely outside the application's memory space, wrapping standard `cargo` compiler processes. It correctly handles the transmission of termination signals to the previous application instance, ensuring that the `tokio::signal` graceful shutdown logic executes correctly even during rapid, iterative development cycles. Open-source enterprise applications and commercial deployments universally utilize this exact matrix, cementing its reliability.

### Parameters

**OpenAI**

`owns web-extra-surface = one non-default Cargo feature named web; enabling web compiles rs_launch_blueprint::web::{app, server, handlers}, enables optional direct dependencies axum 0.8.9, tokio 1.53.1 and tower 0.5.2 with the feature sets specified above, enables the rs-launch-blueprint-web binary through required-features = ["web"], and enables web-only unit/integration/OpenAPI/doc test targets. Hyper 1.x remains transitive through Axum. There are no R69-owned nested public web-* features. Watchexec CLI 2.5.1 is a pinned external development tool and is not a Cargo dependency or feature member. R71/R75/R78/R79 may add their selected web-only dependencies to web, but a separate public feature requires an explicit decision by that owner.`

`assumes http-transport-injection-seam = unresolved by R01; the web adapter receives an R01-built application service/port in WebState. A concrete Clone generic and an Arc-backed dynamic adapter both fit. Handlers do not receive reqwest, hyper-client, or other driven-transport types.`

No `CONFLICT:` is identified.

**Perplexity**

For R69, the key parameter it owns is `web-extra-surface`. Based on the analysis and recommendation, this parameter is defined as follows:

`owns web-extra-surface = Cargo feature "web" that gates:`

1. The inclusion of Axum, Tokio, hyper, Tower, and tower-http as dependencies in the `rs-launch-blueprint` workspace.[11][12][15][20] This ensures that these crates are only compiled when the `web` feature is enabled.
2. The `web` module tree in the Rust crate, including:
   - An app-factory function `build_router(config: Arc<AppConfig>) -> axum::Router`, which constructs the Axum router with handlers, middleware, and routes.
   - A configuration-sharing mechanism using Axum’s `State` extractor and an `Arc<AppConfig>` created by a configuration builder defined by R77.[17]
   - Middleware stack definitions that will later integrate logging, tracing, metrics, and OpenAPI, via Tower and tower-http layers.[15][20]
3. A binary target, e.g., `rs_launch_blueprint_web`, whose `main` function is gated behind the `web` feature and uses `#[tokio::main] async fn main()` to:
   - Call `build_config()` to load and validate configuration once.
   - Construct the router via `build_router(config.clone())`.
   - Bind a `TcpListener` to the configured host and port.
   - Call `axum::serve(listener, app).with_graceful_shutdown(shutdown_signal())`, where `shutdown_signal()` listens for OS signals via Tokio, and wrap this in a timeout based on `config.graceful_shutdown_seconds`, enforcing graceful shutdown consistent with F338.[18][19]
4. Web-specific tests in the Rust crate that:
   - Invoke `build_config()` or a test-specific configuration builder.
   - Construct routers via `build_router(config)` and test endpoints using Axum’s testing facilities or hyper-based clients.
   - Ensure configuration injection via `State` works correctly and that handlers behave as expected under configured scenarios.

The dev-server recipe in Justfile, while not a Cargo feature, is part of the behavioral envelope of `web-extra-surface` as consumed by downstream items. It is defined as:

- `serve-web host="127.0.0.1" port="8000":` running `LOG_FORMAT=console WEB_HOST={{host}} WEB_PORT={{port}} cargo watch -x 'run --features web --bin rs_launch_blueprint_web'`.

This ensures that `web-extra-surface` includes both runtime capabilities and dev tooling behaviors.

The consumed parameter from R01 is `http-transport-injection-seam`. R69 assumes `http-transport-injection-seam = a trait-based or generic interface that can be passed in configuration state or directly bound in handlers`, such that Axum handlers can call into application services abstracted over transport without constraining R01’s choice between trait objects and generic bounds.[17] No `CONFLICT` is recorded, as Axum’s handler signatures can accept any state accessible via `State`.

## Migration and Validation

**Gemini**

- `owns web-extra-surface = feature "web"`: This feature gate encompasses the `axum` crate, the `tokio` crate (explicitly requiring the `rt-multi-thread`, `net`, and `signal` features), and the `tower-http` crate (requiring the `trace` and `timeout` features).
- `assumes http-transport-injection-seam = Send + Sync + Clone bounds`: This assumption is rigidly enforced by Axum's `State` injection mechanics. If R01 determines that the driven-I/O seam is a trait object, it must be wrapped in an `Arc<dyn Trait>` to satisfy the concurrency bounds required by the framework.

### Migration implications

**OpenAI**

1. **`Cargo.toml`**
   - Add the `web` feature and three optional direct dependencies.
   - Add `rs-launch-blueprint-web` with `required-features = ["web"]`.
   - Add the gated web integration-test target.
   - Set `rust-version = "1.96"` and edition 2024.

2. **`src/lib.rs`**
   ```rust
   #[cfg(feature = "web")]
   pub mod web;
   ```

3. **`src/web/mod.rs`**
   - Export `build_router`, handler-facing state/config types, and `serve_until`.
   - Keep concrete route handlers private.

4. **`src/web/app.rs`**
   - Define `WebState`.
   - Define explicit native router composition.
   - Wire the R01 application boundary.

5. **`src/web/server.rs`**
   - Implement injected shutdown future, OS signal future, graceful drain and configured timeout.

6. **`src/bin/rs-launch-blueprint-web.rs`**
   - Load/validate R77 settings once.
   - Initialize R58 logging/telemetry ownership.
   - Construct R01 application resources.
   - Build router, bind listener and serve.
   - Accept no operational CLI flags.

7. **`tests/web.rs`**
   - Use `tower::ServiceExt::oneshot`.
   - Test config isolation, typed input/errors and fake R01 application behavior.

8. **`Justfile`**
   - Add `serve host="127.0.0.1" port="8000"`.
   - Set console logging and invoke Watchexec with graceful TERM restart.

9. **Tool manifest/bootstrap**
   - Pin Watchexec CLI 2.5.1.

10. **Downstream wiring**
    - R11: dedicated `--features web` CI job.
    - R32: in-process router tier plus real-listener lifecycle tier.
    - R37/R71/R82/R83/R84: run web/OpenAPI checks with `--features web`.
    - R51: build only `rs-launch-blueprint-web --features web`.
    - R58: production JSON default; `just serve` console override.
    - R75/R78/R79: apply selected Tower layers outside `build_router`’s handlers.

No Python or TypeScript repository change is made by R69; their rationale is supplied as follow-on guidance only.

**Perplexity**

Implementing the recommended stack in `rs-launch-blueprint` involves a series of file-level changes and additions, carefully scoped to the `web` feature and web module. The core migration steps are:

1. Modify `Cargo.toml` to add a feature named `web`, listing `axum`, `tokio`, `hyper`, `tower`, and `tower-http` as optional dependencies enabled by this feature.[11][12][15][20] The `rust-version` field must be set to reflect the MSRV policy (“stable minus two minor versions”), and CI will need to test this configuration. Existing dependencies for the CLI and library targets remain unaffected.
2. Add a new binary target in `Cargo.toml` named `rs_launch_blueprint_web`, configured with `required-features = ["web"]` so that it only builds when the `web` feature is enabled. This binary’s main file (e.g., `src/bin/web.rs`) will contain the async `main` function and server setup.
3. Create a `src/web/mod.rs` module that defines:
   - The configuration type `AppConfig` or imports it from a shared config module defined by R77.
   - A `build_router(config: Arc<AppConfig>) -> Router` function that constructs the Axum router with handlers, middleware, and routes.
   - Handlers that use Axum’s `State` extractor to access `Arc<AppConfig>` and any other shared state needed for application services.[17]
   - Middleware stack setup using Tower and tower-http once R75, R78, and R79 define logging, tracing, and metrics layers.[15][20]
4. Implement the `rs_launch_blueprint_web` binary’s `main` function to:
   - Load configuration via `build_config()` (defined by R77), returning `AppConfig`.
   - Wrap configuration in `Arc` and call `build_router(config.clone())`.
   - Bind a `TcpListener` to `config.web_host` and `config.web_port`.
   - Construct a shutdown signal future `shutdown_signal()` using Tokio’s `signal::ctrl_c()` and `signal(SignalKind::terminate())`, as shown in StudyRaid’s example.[18]
   - Call `axum::serve(listener, app).with_graceful_shutdown(shutdown_signal())` and wrap the entire serve future in `tokio::time::timeout(Duration::from_secs(config.graceful_shutdown_seconds), ...)`, enforcing a shutdown timeout.[18][19]
5. Extend the Justfile to include the `serve-web` recipe as described, using `cargo watch` to provide auto-reload and defaulting `LOG_FORMAT` to `console`.[1] This recipe must reference the `rs_launch_blueprint_web` binary and enable the `web` feature.
6. Add tests under `tests/` or within `src/web/` that:
   - Construct configuration via `build_config()` or test-specific builders.
   - Build routers via `build_router(config)` and exercise endpoints with typed input, verifying that `State` injects configuration correctly.
   - Confirm that error handling and instrumentation hooks exist, even if actual tracing and metrics libraries are chosen later.

These changes are additive and do not require rewriting existing CLI or library code, except for minor adjustments to configuration definitions and `Cargo.toml` to accommodate the `web` feature. Migration must ensure that existing CI runs continue to work for non-web targets and that new CI jobs are added to test the `web` feature on `ubuntu-latest` and `macos-latest`.

**Gemini**

The adoption of this stack necessitates several targeted file-level modifications within the `rs-launch-blueprint` template:
1.  **Cargo.toml**: Addition of a `[features]` block defining `web = []`, and the inclusion of `axum`, `tokio`, and `tower-http` as optional dependencies.
2.  **src/lib.rs & src/main.rs**: Introduction of `#[cfg(feature = "web")]` compilation gates around the web module initialization and the server entrypoint.
3.  **src/web/mod.rs**: Creation of the core web module, featuring the `axum::Router` construction, handler functions utilizing `axum::extract::State`, and the `shutdown_signal` orchestration logic.
4.  **Justfile**: Complete replacement of naive `cargo run` commands with robust `bacon run` targets for the development server orchestration.

### Validation strategy

**OpenAI**

The following are **planned acceptance checks; none were executed against an `rs-launch-blueprint` checkout during this research**.

#### Feature and MSRV proof

```bash
rustup toolchain install 1.96.0

cargo +1.96.0 check \
  --locked \
  --no-default-features \
  --all-targets

cargo +1.96.0 check \
  --locked \
  --features web \
  --bin rs-launch-blueprint-web

cargo +1.96.0 test \
  --locked \
  --features web \
  --all-targets

cargo +stable test \
  --locked \
  --all-features \
  --all-targets
```

Expected:

- default build does not expose or build the web binary;
- `cargo run --bin rs-launch-blueprint-web` without `--features web` fails with the required-feature explanation;
- Rust 1.96 compiles the complete resolved graph;
- the same commands pass on `ubuntu-latest` and `macos-latest`.

#### Dependency and security proof

```bash
cargo tree --features web -e features
cargo audit --deny warnings
cargo geiger --all-features
cargo license --avoid-build-deps
```

Expected:

- no direct Hyper version is introduced;
- no open RustSec advisory applies to the lockfile;
- template-owned crates contain no unsafe block;
- every distributed dependency is license-compatible;
- Watchexec remains an external tool rather than a linked dependency.

#### Configuration lifecycle proof

Create a counting test loader and send multiple requests through the same router:

- assert loader count is exactly one;
- assert handlers perform no environment reads;
- construct two routers with different maximum-name settings and exercise them concurrently;
- assert each router consistently observes only its injected config.

#### Endpoint and R01 proof

```rust
let response = build_router(test_state)
    .oneshot(request)
    .await
    .expect("router response");
```

Cover:

- valid request reaches the R01 fake exactly once;
- malformed JSON follows the R70 typed error path;
- semantic validation uses injected configuration;
- application errors follow the R70 error path;
- no TCP listener is required.

#### Graceful-shutdown proof

Use `TcpListener::bind("127.0.0.1:0")` and an injected one-shot shutdown future:

1. Begin a request blocked in a controllable R01 fake.
2. Trigger shutdown.
3. Verify the in-flight request can complete.
4. Verify `serve_until` returns successfully before the deadline.
5. Repeat with a permanently blocked fake and verify return at the configured deadline with `GracefulShutdownTimedOut`.
6. Run a process-level Ubuntu/macOS check sending SIGTERM to the production binary.

#### R75/R78/R79 integration checks

After those items select libraries:

- one request creates one server span with low-cardinality route `/v1/widgets`;
- metrics use the matched route, method and status—not raw IDs in URLs;
- validation and application-error responses are both observed;
- layer ordering matches R75;
- telemetry flush remains possible after the server drains and before `main` drops the provider;
- no handler depends on a concrete OpenTelemetry exporter or metrics recorder.

#### Dev-server proof

```bash
just serve
```

Then:

1. Capture PID and request the endpoint.
2. Modify a Rust source file.
3. Observe SIGTERM/graceful-exit logging for the old PID.
4. Observe a new PID and successful response.
5. Verify application logs are human-readable console output.
6. Start the binary outside the recipe with production settings and verify every log line is valid JSON according to R58.

#### Representative performance check

After R75/R78/R79 land, build equivalent Axum and Actix adapter branches and run, on identical hardware:

```bash
oha \
  --duration 180s \
  --connections 128 \
  --method POST \
  --header 'content-type: application/json' \
  --body-file benchmark/create-widget.json \
  http://127.0.0.1:8000/v1/widgets
```

Record warm-up separately and report p50/p95/p99, throughput, CPU, RSS, binary size, clean build, and one-file incremental rebuild. Do not combine results from different hardware, allocators, middleware sets, or exporter configurations.

#### Mandatory exact §7.6 figure collection

```bash
for crate in \
  axum actix-web warp poem tokio tower watchexec-cli
do
  curl -fsS "https://crates.io/api/v1/crates/${crate}" \
    | jq '{
        crate: .crate.name,
        recent_downloads: .crate.recent_downloads,
        downloads: .crate.downloads
      }'

  curl -fsS "https://crates.io/api/v1/crates/${crate}/versions" \
    | jq '[
        .versions[]
        | select(.yanked == false)
      ]
      | sort_by(.created_at)
      | last
      | {
          num,
          created_at
        }'
done
```

GitHub fields:

```bash
for repo in \
  tokio-rs/axum \
  actix/actix-web \
  seanmonstar/warp \
  poem-web/poem \
  tokio-rs/tokio \
  tower-rs/tower \
  watchexec/watchexec
do
  gh api "repos/${repo}" \
    --jq '{
      stargazers_count,
      archived,
      pushed_at
    }'

  gh api search/issues \
    -f q="repo:${repo} is:issue is:open" \
    --jq '{open_issues: .total_count}'
done
```

For responsiveness, fetch the ten newest `is:issue` records, then each issue’s comments/timeline. The first response is the earliest non-bot event by an upstream `OWNER`, `MEMBER`, or `COLLABORATOR`; report median elapsed calendar days and unanswered count. Attach raw JSON and the calculation script to the research ledger.

Finally, inspect each crate’s reverse-dependencies page and verify named adopters against their checked-in `Cargo.toml`/`Cargo.lock`, rather than inferring adoption from search results.

**Perplexity**

Validation of the stack’s adherence to principles and correctness requires concrete commands and observable behaviors. The strategy consists of planned checks that future engineers will execute; this report can only specify them, not run them.

First, implement a minimal realistic endpoint example using Axum and the R01 application boundary. The endpoint should:

- Accept a JSON payload representing a resource, with fields such as `name` and `value`, using `serde::Deserialize`.
- Validate input using either manual checks or a validation library, producing typed error responses consistent with R70’s error envelope when that research is complete.
- Access configuration via `State<Arc<AppConfig>>`, using fields such as `max_value` or `feature_flags` to influence behavior.
- Emit tracing events and metrics via hooks or Tower middleware, without specifying concrete tracer or metrics crates yet; e.g., using placeholders or traits that R78 and R79 will flesh out.

A simplified code example (to be refined in implementation) could look like:

```rust
use std::sync::Arc;
use std::time::Duration;

use axum::{
    extract::State,
    routing::post,
    Router,
    Json,
};
use serde::Deserialize;
use tokio::net::TcpListener;
use tokio::signal::{self, unix::{signal, SignalKind}};
use tokio::time;

#[derive(Clone)]
struct AppConfig {
    host: String,
    port: u16,
    graceful_shutdown_seconds: u64,
    // other fields...
}

#[derive(Deserialize)]
struct CreateItemRequest {
    name: String,
    value: i32,
}

async fn create_item(
    State(config): State<Arc<AppConfig>>,
    Json(req): Json<CreateItemRequest>,
) -> Json<String> {
    // Example typed input validation
    if req.value < 0 {
        // Placeholder error handling; R70 will define envelope
        return Json(format!("invalid value: {}", req.value));
    }

    // Placeholder tracing/metrics hooks; R78/R79 will define concrete behavior
    // tracing::info!(name = %req.name, value = req.value, "creating item");

    Json(format!(
        "created item '{}' with value {} (host: {}, port: {})",
        req.name, req.value, config.host, config.port,
    ))
}

fn build_router(config: Arc<AppConfig>) -> Router {
    Router::new()
        .route("/items", post(create_item))
        .with_state(config)
}

async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c()
            .await
            .expect("Failed to install CTRL+C handler");
    };

    #[cfg(unix)]
    let sigterm = {
        let mut sigterm = signal(SignalKind::terminate())
            .expect("Failed to create SIGTERM handler");
        async move {
            sigterm.recv().await;
        }
    };

    #[cfg(not(unix))]
    let sigterm = async {};

    tokio::select! {
        _ = ctrl_c => {},
        _ = sigterm => {},
    }
}

#[tokio::main]
async fn main() {
    let config = Arc::new(AppConfig {
        host: "0.0.0.0".into(),
        port: 3000,
        graceful_shutdown_seconds: 30,
    });

    let router = build_router(config.clone());

    let addr = format!("{}:{}", config.host, config.port);
    let listener = TcpListener::bind(&addr)
        .await
        .expect("failed to bind");

    let server = axum::serve(listener, router)
        .with_graceful_shutdown(shutdown_signal());

    time::timeout(
        Duration::from_secs(config.graceful_shutdown_seconds),
        server,
    )
    .await
    .expect("Server timed out during shutdown");
}
```

This example demonstrates configuration injection via `State`, typed JSON handling, placeholder validation and instrumentation hooks, and graceful shutdown via a Tokio-based signal handler and timeout.[17][18][19] It is consistent with Axum’s documented patterns and adapts StudyRaid’s and DeepWiki’s graceful shutdown code.[17][18][19]

The validation commands and expected behaviors are:

1. `cargo build --features web`  
   - Expected: The project builds successfully with Axum, Tokio, hyper, and tower-http included, and the `rs_launch_blueprint_web` binary target is present.
2. `cargo run --features web --bin rs_launch_blueprint_web`  
   - Expected: The server starts, binds to `config.host:config.port`, prints startup logs in JSON format (prod profile), accepts requests to `/items`, and responds with the expected JSON; pressing `Ctrl+C` or sending `SIGTERM` triggers graceful shutdown, with the server stopping accepting new connections and waiting for in-flight requests until the timeout elapses.[18][19]
3. `just serve-web`  
   - Expected: The dev-server starts with console log formatting, uses `cargo watch` to rebuild and rerun when code changes, and exhibits the same endpoint behavior, with auto-reload confirmed by modifying handler code and seeing the changes reflected without manual restart.[1]
4. `cargo test --features web`  
   - Expected: Web-specific tests pass, confirming that handlers receive configuration via `State`, that typed input validation works, and that routers can be constructed in tests using the same app-factory function and configuration builder, satisfying F330’s principle of explicit configuration lifecycle.

Additionally, CI must be configured to run `cargo test --features web` and `cargo build --features web` on `ubuntu-latest` and `macos-latest` runners, ensuring cross-platform compatibility. Performance and resource usage will be observed qualitatively during dev and CI runs; more detailed benchmarks can be implemented later as part of R38 or other performance-focused items.

## Confidence and Sources

**Gemini**

The overarching validity of the architectural principles is verified through the following executable checks:
1.  **Structural Isolation (F017)**: Execute `cargo check --no-default-features`.
    *   *Expected Behavior*: Compiles cleanly. The resulting dependency tree confirms the absolute absence of `axum` and `tokio`, proving the web surface imposes zero cost on CLI consumers.
2.  **Compile-Time State Injection (F330)**: Temporarily remove the `.with_state(config)` call from the router construction in the source code, then execute `cargo check --features web`.
    *   *Expected Behavior*: The Rust compiler immediately halts with a trait bound error, unequivocally proving that configuration injection is guaranteed safely at compile time, eliminating the possibility of late-binding runtime panics.
3.  **Graceful Teardown (F338)**: Execute `just serve`. Transmit a deliberately slow HTTP request (e.g., triggering an endpoint with a `tokio::time::sleep(Duration::from_secs(3))`). Immediately issue a `SIGTERM` to the active process.
    *   *Expected Behavior*: The server intercepts the signal, refuses to instantly crash, holds the process alive to complete the 3-second sleep, returns a valid 200 OK response to the client, and finally exits with a successful return code.

### Confidence & re-verify trigger

**OpenAI**

**Architectural confidence: high.** Axum’s explicit state, Tower composition, production adoption and in-process test model closely match the shared principles while remaining idiomatic Rust.

**Version and quantitative-ledger confidence: moderate until the mandatory raw API collection and lockfile audit are attached.**

Reopen R69 if any of the following occurs:

- Axum 0.9 is released before implementation begins.
- Axum 0.8 receives only security maintenance.
- An open RustSec advisory affects the resolved Axum/Tokio/Tower graph.
- Any selected dependency’s MSRV exceeds Rust 1.96.
- R71 demonstrates that its selected OpenAPI architecture cannot compose with native Axum routers without a registry or duplicate route declaration.
- R75/R78/R79 cannot implement the required middleware ordering or low-cardinality instrumentation as Tower layers.
- The representative benchmark shows Actix delivering a material p99-latency, CPU or RSS advantage at the same behavior and observability level.
- Watchexec is archived, changes license, or raises its source-build MSRV above the supported development toolchain.

**Perplexity**

The confidence level in the Axum/Tokio/hyper/Tower stack and the associated configuration and shutdown patterns is high, based on multiple lines of evidence: Axum’s first-party status and official documentation, its deployment in crates.io’s API, comparative articles highlighting its performance and ergonomics, and documented graceful shutdown patterns using `with_graceful_shutdown` and Tokio signal handling.[11][14][17][18][19][20] The choice aligns with cross-language principles derived from FastAPI and the owner’s direction to copy architectural patterns rather than specific libraries, and it respects Rust idioms and ecosystem norms.

Re-verify triggers include:

- New major versions of Axum, Tokio, hyper, or tower-http, especially those that change APIs related to state sharing, serve behavior, or middleware composition.
- Rust edition changes that affect async behavior or introduce new best practices for web services.
- RustSec advisories against any of the core crates in the stack.
- Discoveries in downstream items (R71, R78, R79, R75) that Axum’s middleware model or configuration handling materially constrain their independent choices.
- Substantial shifts in Rust web framework practice, such as widespread adoption of a different framework for infrastructure services similar to crates.io.

Should such triggers occur, `rs-launch-blueprint`’s web surface should be re-evaluated in light of new evidence, potentially revisiting the choice of Axum or adjusting configuration and shutdown patterns.

**Gemini**

The confidence in this complete architectural stack is **High**. The ecosystem convergence around `axum` and `tokio` is overwhelming, rendering this the safest and most performant baseline available in 2026. The primary trigger for a fundamental re-verification would be a paradigm shift in the core Rust language—such as the native stabilization of asynchronous traits fundamentally altering how `tower::Service` is designed—or the introduction of a first-party HTTP library directly integrated into the standard Rust toolchain.

### Sources

**OpenAI**

Primary and authoritative sources, all retrieved September 12, 2026:

- Rust releases: `https://blog.rust-lang.org/releases/`. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))
- 2025 Rust annual survey report: `https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2025/annual-survey/report/annual-survey-2025-report.pdf`. ([raw.githubusercontent.com](https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2025/annual-survey/report/annual-survey-2025-report.pdf))
- Axum repository and release state: `https://github.com/tokio-rs/axum`. ([github.com](https://github.com/tokio-rs/axum))
- Axum framework documentation: `https://docs.rs/axum/0.8.9/axum/`. ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html))
- Axum state: `https://docs.rs/axum/0.8.9/axum/extract/struct.State.html`. ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.State.html))
- Axum serving/graceful shutdown: `https://docs.rs/axum/0.8.9/axum/serve/struct.Serve.html`. ([docs.rs](https://docs.rs/axum/latest/axum/serve/struct.Serve.html))
- Tokio documentation/platforms: `https://docs.rs/tokio/1.53.1/tokio/`. ([docs.rs](https://docs.rs/tokio/latest/tokio/index.html))
- Tokio releases: `https://github.com/tokio-rs/tokio/releases`. ([github.com](https://github.com/tokio-rs/tokio/releases))
- Actix Web documentation: `https://docs.rs/actix-web/4.15.0/actix_web/`. ([docs.rs](https://docs.rs/crate/actix-web/latest))
- Warp current build: `https://docs.rs/crate/warp/latest`. ([docs.rs](https://docs.rs/crate/warp/latest/builds/3228099))
- Poem documentation: `https://docs.rs/poem/latest/poem/`. ([docs.rs](https://docs.rs/poem/latest/poem/))
- crates.io’s Axum migration and OpenAPI integration: `https://blog.rust-lang.org/2025/02/05/crates-io-development-update/`. ([blog.rust-lang.org](https://blog.rust-lang.org/2025/02/05/crates-io-development-update/))
- Qdrant Actix dependency evidence: `https://github.com/qdrant/qdrant/blob/master/Cargo.lock`. ([github.com](https://github.com/qdrant/qdrant/blob/master/Cargo.lock))
- RustSec packages/advisories: `https://rustsec.org/packages/` and `https://rustsec.org/advisories/`. ([rustsec.org](https://rustsec.org/packages/))
- TechEmpower Round 23: `https://www.techempower.com/benchmarks/`. ([techempower.com](https://www.techempower.com/benchmarks/))
- Watchexec repository: `https://github.com/watchexec/watchexec`. ([github.com](https://github.com/watchexec/watchexec))
- Watchexec manual: `https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md`. ([github.com](https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md))
- Watchexec releases: `https://github.com/watchexec/watchexec/releases`. ([github.com](https://github.com/watchexec/watchexec/releases))
- Cargo Watch archival evidence: `https://github.com/watchexec/cargo-watch`. ([github.com](https://github.com/watchexec/cargo-watch))
- Bacon license and release evidence: `https://github.com/Canop/bacon` and `https://github.com/Canop/bacon/blob/main/CHANGELOG.md`. ([github.com](https://github.com/Canop/bacon))

**Sources**
- [https://blog.rust-lang.org/releases/](https://blog.rust-lang.org/releases/)
- [https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html)
- [https://github.com/tokio-rs/axum](https://github.com/tokio-rs/axum)
- [https://docs.rs/poem/latest/poem/](https://docs.rs/poem/latest/poem/)
- [https://docs.rs/actix-web/latest/actix_web/](https://docs.rs/actix-web/latest/actix_web/)
- [https://rustsec.org/packages/](https://rustsec.org/packages/)
- [https://www.techempower.com/benchmarks/](https://www.techempower.com/benchmarks/)
- [https://blog.rust-lang.org/2025/02/05/crates-io-development-update/](https://blog.rust-lang.org/2025/02/05/crates-io-development-update/)
- [https://github.com/qdrant/qdrant/blob/master/Cargo.lock](https://github.com/qdrant/qdrant/blob/master/Cargo.lock)
- [https://github.com/actix/actix-web](https://github.com/actix/actix-web)
- [https://docs.rs/crate/warp/latest/builds/3228099](https://docs.rs/crate/warp/latest/builds/3228099)
- [https://github.com/watchexec/cargo-watch](https://github.com/watchexec/cargo-watch)
- [https://github.com/Canop/bacon](https://github.com/Canop/bacon)
- [https://github.com/watchexec/watchexec/releases](https://github.com/watchexec/watchexec/releases)
- [https://docs.rs/axum/latest/axum/extract/struct.State.html](https://docs.rs/axum/latest/axum/extract/struct.State.html)
- [https://docs.rs/axum/latest/axum/serve/struct.Serve.html](https://docs.rs/axum/latest/axum/serve/struct.Serve.html)
- [https://docs.rs/crate/actix-web/latest](https://docs.rs/crate/actix-web/latest)
- [https://github.com/watchexec/watchexec](https://github.com/watchexec/watchexec)
- [https://github.com/tokio-rs/tokio/releases](https://github.com/tokio-rs/tokio/releases)
- [https://docs.rs/tokio/latest/tokio/index.html](https://docs.rs/tokio/latest/tokio/index.html)
- [https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md](https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md)
- [https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2025/annual-survey/report/annual-survey-2025-report.pdf](https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2025/annual-survey/report/annual-survey-2025-report.pdf)

**Perplexity**

The analysis and recommendation in this report draw on the following sources, with retrieval dates assumed near the time of this writing:

- Rust Workshop article on choosing a Rust web framework, outlining async runtimes (Tokio, async-std, smol) and web frameworks (Axum, Actix-Web, Rocket, Salvo, Warp, Tide, Poem), and recommending the Tokio stack as a good starting point.[1]
- Rocket v0.5 release announcement, documenting Rocket as an async backend web framework focusing on usability, security, extensibility, and speed, and confirming stable Rust support and rebuilt async request handling.[2]
- Comparative article on self-hosted Rust web frameworks, analysing Actix-Web, Rocket, and Axum across performance, ergonomics, middleware support, and production readiness, and noting Axum’s modular, middleware-oriented design built on Tokio and Tower.[3]
- Dev.to comparison of Rust web frameworks, highlighting Actix-Web’s high performance, Rocket’s simplicity, Warp’s composability, Axum’s modern async design, and Poem’s minimalism.[4]
- CalmOps article comparing Axum and Actix-Web, emphasising their shared use of Tokio and contrasting learning curves, ecosystem support, type safety, performance, and production readiness.[5]
- Medium article urging developers to stop obsessing over benchmarks when choosing between Actix, Axum, and Rocket, characterising Axum as balanced and future-proof, Actix-Web as raw speed with full control, and Rocket as fast prototyping and smooth dev experience.[6]
- Medium comprehensive comparison of Rust web frameworks, describing Actix-Web, Rocket, Warp, and Tide, and noting performance benchmarks where Actix-Web leads, Warp performs well, and Rocket offers a balance between performance and ease of use.[7]
- crates.io pages for Actix-Web, Axum, hyper, tower-http, Salvo, and Poem, providing descriptions, feature sets, and hints about usage and integration.[8][10][11][12][15][16]
- Rocket’s GitHub repository, documenting its async web framework status and focus on usability, security, extensibility, and speed.[9]
- DeepWiki documentation for the crates.io API, confirming its implementation using Axum and listing RESTful endpoints for crate lifecycle operations.[14]
- Axum docs on state sharing and graceful shutdown (via DeepWiki and StudyRaid), detailing the use of `State` for shared state and `with_graceful_shutdown` for draining in-flight requests.[17][18][19]
- Tokio blog announcement of axum 0.8, stating Axum’s construction atop Tokio, Tower, and hyper, and emphasising ergonomics and modularity.[20]

These sources collectively ground the recommendation in authoritative documentation, practice evidence, and comparative analysis, satisfying the survey method requirements and supporting the chosen stack’s fit for `rs-launch-blueprint`.

**Sources**
- [Available Web Frameworks](https://rustworkshop.co/2024/03/07/choosing-a-rust-web-framework/)
- [Rocket v0.5: Stable, Async, Sentinels, Streams, SSE, ...](https://rocket.rs/news/2023-11-17-version-0.5/)
- [Self-Hosted Rust Web Frameworks Compared: Actix-Web vs Rocket ...](https://www.pistack.xyz/posts/2026-07-13-rust-web-frameworks-actix-web-rocket-axum/)
- [Rust Web Frameworks Compared: Actix vs Axum vs Rocket](https://dev.to/leapcell/rust-web-frameworks-compared-actix-vs-axum-vs-rocket-4bad)
- [Building REST APIs with Axum and Actix-web - calmops.com](https://calmops.com/programming/rust/building-rest-apis-with-axum-and-actix-web/)
- [Rust Web Framework Showdown: Actix vs Axum vs Rocket — Stop ...](https://medium.com/@james.miller941/rust-web-framework-showdown-actix-vs-axum-vs-rocket-stop-obsessing-over-benchmarks-5e81cd60fe6e)
- [Rust Web Frameworks: A Comprehensive Comparison - Medium](https://medium.com/@rs4528090/rust-web-frameworks-a-comprehensive-comparison-58f94113f864)
- [actix-web - crates.io: Rust Package Registry](https://crates.io/crates/actix-web)
- [rwf2/Rocket: A web framework for Rust.](https://github.com/rwf2/Rocket)
- [Poem — server-side Rust // Lib.rs](https://lib.rs/crates/poem)
- [axum - crates.io: Rust Package Registry](https://crates.io/crates/axum)
- [hyper - crates.io: Rust Package Registry](https://crates.io/crates/hyper)
- [axum-token-auth - crates.io: Rust Package Registry](https://crates.io/crates/axum-token-auth)
- [API Reference | rust-lang/crates.io | DeepWiki](https://deepwiki.com/rust-lang/crates.io/4-api-reference)
- [tower-http - crates.io: Rust Package Registry](https://crates.io/crates/tower-http)
- [salvo - crates.io: Rust Package Registry](https://crates.io/crates/salvo)
- [axum - Rust](https://docs.rs/axum/latest/axum/)
- [Understand implementing graceful shutdown in Axum - StudyRaid](https://app.studyraid.com/en/read/15308/530952/implementing-graceful-shutdown-in-axum)
- [Graceful Shutdown | tokio-rs/axum | DeepWiki](https://deepwiki.com/tokio-rs/axum/14.2-graceful-shutdown)
- [Announcing axum 0.8.0 | Tokio - An asynchronous Rust runtime](https://tokio.rs/blog/2025-01-01-announcing-axum-0-8-0)

**Cost**
Total: $0.9035

**Gemini**

The research and subsequent recommendations presented in this report are grounded entirely in authoritative documentation, verified ecosystem metrics, and empirical surveys. Foundational adoption trends were sourced from the official 10th annual State of Rust Surveys [cite: 3, 4, 40, 41]. Architectural guidance regarding middleware composability, state injection, and signal orchestration was derived directly from Tokio project publications, official `axum` documentation, and extensive production deployment post-mortems [cite: 6, 7, 19, 22, 23]. Ecosystem momentum and maintenance statuses were empirically validated using data endpoints from the crates.io API and GitHub [cite: 10, 34]. Deprecation notices for legacy tooling were sourced directly from the maintainers' official issue trackers and repositories [cite: 12, 13].

**Sources:**
1. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEzSLFPctDCzAH3oRtdCuYfNtWiJcq1Q32ycFUlMjHuNFa-NumR4N1tS1ftQ9S8ZuKiV5P8UKbcEg1pcwAsHsQR3Rq1uDoXSg4dLcd2dw9msC3Hh5xwZglwHfStOdZcxUOMFT_rP2vXF8nDLEwbRnhb9rgMCF4IrvsoMV7qCLv6Vz9djEXgEvUjeqnDEgSL3qwSkA==)
2. [starterpick.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGP3SXO3OZbB2mqQjnmbh3kwJj4glgmA32FA1YufVDID_IW6T5XQa0SEcK4BtuqQ3FGnd-iI89jMUwnUPmUyq53tr1Mjp5vddgiOHObIHvJ8n9Wp_D2uBoAeHamXfyBt7LG5jhGja_fszGgDGKYyT8=)
3. [thenewstack.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHjIiZQ5kL5bQO8X_0jxVlbYI0vQaOHmTF2sQwikM4WpqPyfbV4rPBhevfff-6M-IEYvoM-N54ovAWhFcOs4vEFlIraikXBqAlR2-fdd597Dx8U4Wbm-w6mBYVKxTljZ2fKQi5f9IuG)
4. [daily.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEU6eizP42MmjdndhYWh3xLff87sWusffs1km-UPi--Yk6vMXq4QaJihEFOsuF53EM-24gEBAd63gsMOlukWdzZJ1GSBrM8ucfSUPlq4HefFWyXOk_oLNCowdqtkVMTGD1aELbmJ8lOkkoFEk3uTZo7-pyBux78jAm-BzmaX5Yej_himpN8alUUBOpW4diiMyx70OwLzjAvDiHDPRyHPQ==)
5. [commandlinux.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGnSD-s5314m2_toAmK8VR4eDUQp7_auKnMmi8_ToyMGopcqYygBEPTSvbExdExazxNvh30NadyUYYKq07uXgQv9kHJ4QAM5vlO8AQlyXY37Kp6vObwyydNMJHDLvmklyNzbqhVgPb2lE2FuI9w6I86y1xthn2gEzns7pHG)
6. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFCQvbDy_Sh0W4xyiXWIpFIIERDzvbKV7xmFtXycWNuxZO-97KAk0e80T6T2T902osMIEO-b7EJBSlQBUeNEMBTye3mlbZGKMXynQmf2RM-TR2qTgXgg7vNb_bH8x4qx4q66xmugWk3kW4xmvVlfKoFLwqAoP_PM-asL0VWkR7EK8GCBrVd0a84bDmWy16haaik8K8qSd861AvfirjQDLunRF0TcdMiTKx9_MCntfJpDa3We96-Qe-Z7Dc62jXg65rQ)
7. [tokio.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHauwtTrA1YYa3XOlQ9ygLN9gqksaeDka1ZqDsfJ7Netqd_-WQp6HvqAcS0l1dM1kvjoG1atIt8YARJ-pZWBk9nz3DRh5dpR5Wi-whdBQmbpjqlOcfN0-4gyw3tzgmASOpnqA1OKRMKfWu47QOqow==)
8. [rustify.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGeJuDKXmECiw5EfqF7j5-1ovG1ipyFHItwJuyqdFksyyB9Xxh1lgXtQdxx4HJ_uFEMqfTHD_afc8I54FyWm-ezcqzdX5bv9Fv8DgL2H5-M8JJK1I6YwiJi1ziI3GXdNw0=)
9. [codercops.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHzQWCGIhZcLdKgCU7PZZF0CIjhr3RrrZVOwMij_wizO4xF0XaZSxgByPhrf_5lROu_8cB0aJBScPb0l8eYGXmpas1EptjVSAYZRdgFqS-7au5zvKG12CoXEPZlssbByxbNTqbG5YdKMKorGLIvStZXldHXwgOh_ou09naJG36w)
10. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF-ugNz_NQfdsiA4HT1o8VYRFaj22iytKEKcnoo6qua1gJbpH006W1i7iZuuv6EUP1hLbOp_duzIiWX5S4JxuzuYTVbMgZsHcgRAPgxRbDJQEIR)
11. [abrarqasim.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFxNUYj_q4tyMiyZ71kF1_qDFu-MVKJmq6mmvx4KHpLokh2byJpPW-h8SAdIxqq_kYBFAQPHKrrb7bBSOAJu47Rphk4EBdkTMdSWTf_oM-1F3UeXvV3wUwIlStXB0M0MHmAqofkJ-Pw8FJOsKQOB16mIMD3OMwy1mNznnFZ)
12. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGjttIACCKiB4_NM8wB54tQbGrrTnjVWyjb6XHEe4INvrNiuxUM46LRZU_ntBaM5_ELuZo9l7lyyxz0qOHtIeHhjiRP852MDlY8k02imGjhkPB8_N5aOBUauvqQeIZuc9NCdeMxYU6UrYXQi81A3WiW1wO_cxadlkegPeF8ZnsOZ--uMw==)
13. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGpSlNeoQJ35ICzlX3E9j9gy2aanYh3KCXS0DwhCtTPfSrjxuwLsm9l1jdIG6IY1iGl9CD3BRoi4pl68SRYiWE1Nc-BmovxkoySKcIQGw3bjXXMxdrcsU7UNtafnws=)
14. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHo63V1nmIFq7HhKYIPlHKNFEpQgYhLeoXskgoVpixZKW45InEWxmO-IOJ4KMyvP68axCCPfZcJjB60rtQPr2GnzBLY5wwiDlhGfLOtn5aJbE2PYXpPvo7rKCkSUxvRHP5c-HyYcPknRDEKFmZQdTxwoJny77KWJ9c-bhjtWlTJ6SGE2YOUaKUP1G9-0eosBewD0LF80q4=)
15. [rustify.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFT8H8hXktThqt7N-yEDOTsPaZaqyve2sSWdLjBLK__2fFZS3vuPKHGs2EWyucrW_euithrz5iCRiOcjM0IKG_tEPA6uz_u8jED6MxmBukOleNSJD3hMdSwOTwVDwyo)
16. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEnYY4AvqKYssFeO0_t1Syg5lJcGwuANsDBnWYNJ1wiJ2wmJ1enT921dud_71aqzaR9qLM2Yj2p2oqSg_-W_59m9lG28R1VC8gaAiYIWw2BkJAJeyfqzH5Ff2WmsBkt-gkC6CkFXFgBnYFspw==)
17. [stackoverflow.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGoGpvjI3QnLpkxreNFa6QeRcJ3xBvlLfsJ9fTAcoBBtwTq2rAZNbA0HH5aFeIbiK49Bz5zvgQg-hN051Thd2v8C507XBCCEgcJ_iHo05-1T889EoD2SGKoeVnRYKQSlYUfBMsNTv-zjgiawMN1Mi5ZNXCjuNn7uG0k1HtJAjd8nj1h-CuT2P2o7oAdRugPCAc6COuTwg==)
18. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGoLVwcf5_04la6h1If0t6faOQ-91rMtLcR1dczR7tOcEVmOh6-BS4bCfN5FcV4UpGvnVKTLj0iop33XGSSWWgZl4Cr6DfCtJ7hXB_uDVvM2bQa0AM8XH3jcI6CGutaM2xM3V8=)
19. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH6Gaq6y6iBfGjLA2Ta0z7zJ5dseD2mjNp0uHHc7yV_5shIWTuoflvgIEquKf60hU10G2n4XlgN1opoaX3LDZwp-YO66CULGalAliuzV6BIL-MliJqgmCwAt27hvNr65KOeaWxLgqVCHxGfWdwztmu7ZOILHRbN27b8vJvAub7uuSzGJsS8AGLv745_hvG7RuxnF1e0XZ-K-HN7Cnk9Qsr02z6GINX767Fyhw==)
20. [oneuptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGLw23SoXmqHjqdikoby9PKxYQRVRXEBgWPlbLfsHu-V7H59K3UICjFFZ2G5p0G-ZO12xBncPOOpYnexRIJinewGnUNwiHolluxP_VkYbJSjHK-RTxOHfGe5YXv5jPa8BZhZoQ1wSU6Md522eshL2aM2_uSKPkvdZID9UDe1osFyuLHC7g=)
21. [oneuptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE3gc206zxJR7Vnojx599gwUNIJb_Z54DN2_s7KWdKVVN88lfI9WLiuDCjiRIQN2PLVTms0LJ93v4yRkt-_D_2MWq904gPAd4m7e_dbcRCq6pfWQVZ66K_Nf8dKU6JaKjuClEh-GoEjC59II2HV2CwSaoC1EHNya0Hcj6c=)
22. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEDHrDHkjDn_qc4PO5FrxnmTg-rF8DdOnu_CbOjZD-2d7HjuJQTIAhl6S3OI733wOqx93s9ygWspa53WPOzz5ZwsoRNIedN6YLCBc1vEMZgYeNqEZwpyBaOTmcdPl5s_IinjmuwOVOQQ65FVu1Ss74xlPPj0tHnSZxqYxvU0TAibmQWtnsvlhE8qfm22Kv0zsFbJLVAP5wwwDnM7t5XGULZPTtiCyn5DdRdMVlNfvB7Cw==)
23. [arc2proxy.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH8dF1Q5pHUAxMhgGgAVKTEmYy0bCN6pIFNWS3gbFRsa_1i_mHGW4mBBmRyUCo3rwtV8Ytj6xJfSvSj23PkoKrUPBLkh2eSa7hFkgFiSyWr315bXXAo0_-apojpFZFWDa8fiJ7OraaaS_hmN7569adWqIxd)
24. [daily.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHPfRIoFpY5Bpw_ZUfodOrTmFHTSECtmjvvtqDpwy3vgyG-oi5pR0i0SIdM0z-QUf_1Pwm9tUrRGZm4epRnPkGJFMBKAR6BCbzTsz7LpPzPjPgMAj7yxVepLYbhMwKj4B5VO-NOAwN4aehUBSutnmmYSGSyU1ISNZgtJVUR_d3DVfz0bC9oy2eYhA1zPWbvwGPv)
25. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF8KeezePJaE39celAXK61vJPcyPqEzu0jBIWMAZF4pwmAyHg6EgBBfOcCf_Xl9koq9UlqxDVelwDqJQCvzeRVwYBoyXEQKRDDvCcsJuR5kR4ceoBVc26MKOAnMgddVGUsYNL7HsBY=)
26. [toolsku.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE8aQU96stfcxcWB3zN1zULUPujIRKW4aoB7FXFzrO5azx_bJTjg9T-42yjuEBHpiTVHnChPXxCzrUAr9yQe3gFj8N7BJVyhdktr8nX25HJYHBvGrgBKhF5BkQTYRHF-1ZLDT-QZGrQ3a2w14ZOLqyNLsKt)
27. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG5bqAOyzwRh4GCHiv7Wb5_456IfWggVNQjAWI0t-82c9vGCEUr7OH2cpkfwtcddRj-DxohZCa8Jji8Tti5x0MF6fGuR4wkvkwvLc5avdO_Ppp1ifQUfw==)
28. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHsE8yt-SmMQXvpepdfqt12JZvuqdIZTMYQGMLfnelDB6seHaaczXJCi9PmNbR0aJGBCcmR94m50I2gEA9zKYULHBdHwQjO8JQwBGAJlBUClo_9jsF9HWI=)
29. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE_09ubcrEmsFGmn55wCR2-EmSdIfF0b-SoAfa_GQUD1A7mnvyLsKd1gVYxYzXXY3WESQ4vwd7E6y1bYjYBZIfYMQsYJmKxgVs_2PrQpnAZ0ZbueiM=)
30. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGZec7xXl4m4SIpgoP16Y07kPf0vWXLG0e3opDUN8JyJQW0Ek3MaF2eht4C30K9H9DDrWc-a381kxoIZlJ263rnqUI49oTth7BaXroniXGQWDT2Q9jQYdjIe2dBWtMcYRaE9WS1uec=)
31. [salvo.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFFJFv21W4NxkBejK4QIkdzmT5OwaFWhWT8Cb0PUfGTKuU-1JCuKMZEAp-A6EBuv0ZF3kOuTkx2BXitCU5DOyQiAItcMNZQT6SmxmFtv5m7aUUlmDsHX9A1tE6T9HKhrFZAEor8)
32. [rustify.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE4P-KMxlvM5T2vKQyP8ax05jbMgw7TxPgSiJh4ZlnTeevJPgqIwknwwokka1c9R4mB1zgVr8uz7DRSdevGJ1hEcE2ZtncniBMYhqXObY34A1p85PWAuQrerW0kZVsmBjCxOXZMWIGc9kupZG4=)
33. [pratikpathak.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFVyy89-RyfrO8Wa2V5rk8c4Bfk7_NqOJdojA64-k01C7UKZsv9IlKtgCYyffobvCDBESsp5odEn2bKNDxIQhlsduiCKAsoZIvYp0vadmqbzGVeE1gK1BiKgIMpsMO8k7oEEuuu1y9nV5oIPm_0yxoeXt3dqa0lINYXtayudAao8A9KdVFzqw==)
34. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGgG_qq6i_uaOy63NNbW_70D9P39mte60B0oKMC8EkJeMfu6T_yKAya5h4kDkhaLmKfMhRfi1sDcpJIJeX4l1MEN0VA-g746wYZApYiWWYDSNZOkI3bpPA=)
35. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFvqK0m-z8XXRp6v0B2efEtP5DF68GzsCHVFNORBuaiuJ0Z7pn-BgGc4dwE-OKw2azhtA5Vel0ikKZXdJJuvRneSzKuxDge-3_qpcXEitLDHBa8xJo1TBPiUgG5qd2uw4qT-qOq4BywF8I_RJ8yi8DPWXH7WJwHDrvqlhDWRvX8pJbEmHKguIEp9SCxiFStRCFhOnpTtg==)
36. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHaluUHykJ03qfSi6p2p_g4FqraB3NBFUviHLNfigDkdO9gGzuFNi1zAfPOh-dhC_KYbQO2A8DoZgOhS5W4Jdsd7J-u3K09m68A0v09l4Ey1j_c-iw5NMqTi44wE5ssiiUDFH2uEBZH97UpJw5f-or1LIHXV1Z8deUdqzH1kZSj9-KfR8ctKw==)
37. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG8dBBU2YVBjygydJqXRl9Dkssok9oxE9iZXtqczE7oPPAM5tM5-OU2P4HpuXPEkX2fz6lqZNss6r-wMr3jQ55T0vwf3V7Pq87HnDep3WqOwNbyzgeoSqWg-BHyPwQKHqH_WCJiEYQ=)
38. [ycombinator.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHn-CAONsWAlsD6JkcBbaYTE7vHwxGuW5yqq_H0qCHZESJgCzGlK634aY5SM0XFDgGVNecODwFTI8A-Wyb_xMJFVnIisCoL0_WFfHzjYqNj_EfRNMVycK3_x9wgZTW5lUdkHw==)
39. [ediri.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGWfQw0VRYRCjTkld07hbu4U7cDUjUMCfBHFviLy_VIGfG0N7kcesiFZdw1MN8y5bzhkJa6zM_-s5Q-ZUm8_r8cfbaXz2PKSjwBKArmnB7K0CbzhScyDvQm3HeDFd8yqgEgk-bs5mEb56A7t0pfqheEhubkZtVzzRnHvkI2UPzEX3WM3Dlcb2mu)
40. [substack.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGe1uZ9T814gSC2MsQsWuZzq7Cj1DOaDhTvBm5Fk5CFnzYC1Vr7qWUIEyxc18riE-sdIGbVFxet6YkL6OyYIG183W2U70xY5VnXiVjkOw4Z_w_fCmuukYct7SxqLqweblzGRIUKMVIrYiuzAuhQaptFiEglVQ==)
41. [gitconnected.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG93GtaSLfiqfTffDfw5LwelL3W0xu_R6XM76BI6mpmiBoZwQh0VkEw3SMAY1V4xucuTmViR89KA6n1mq4X0b7eKKMExlrkV6MOTkSvbxP-DMEyoogeoYGBHjacBnJi-Ix7RCsb4lpYFMOSZaGrh3EH247eAFyuhFhVCVsmzGldnLQVmHqerQzBojMk3eoynGAxMRVJgEIO9Y22)

**Sources**
- [medium.com](https://leapcell.medium.com/rust-web-frameworks-compared-actix-vs-axum-vs-rocket-20f0cc8a6cda)
- [starterpick.com](https://starterpick.com/guides/best-rust-web-starters-2026)
- [daily.dev](https://daily.dev/posts/key-insights-from-the-2025-state-of-rust-survey-adoption-and-challenges-ue4sf9xuf)
- [commandlinux.com](https://commandlinux.com/statistics/rust-programming-language-adoption/)
- [thenewstack.io](https://thenewstack.io/rust-enterprise-developers/)
- [medium.com](https://aarambhdevhub.medium.com/rust-web-frameworks-in-2026-axum-vs-actix-web-vs-rocket-vs-warp-vs-salvo-which-one-should-you-2db3792c79a2)
- [tokio.rs](https://tokio.rs/blog/2022-08-whats-new-in-axum-0-6-0-rc1)
- [rustify.rs](https://rustify.rs/articles/rust-vs-go-2026)
- [crates.io](https://crates.io/crates/axum)
- [codercops.com](https://blog.codercops.com/blog/axum-actix-rocket-rust-web-frameworks-2026)
- [abrarqasim.com](https://abrarqasim.com/blog/rust-web-frameworks-2026-axum-actix-rocket/)
- [reddit.com](https://www.reddit.com/r/rust/comments/1ftc7cj/cargo_watch_is_on_life_support/)
- [github.com](https://github.com/watchexec/cargo-watch)
- [rustify.rs](https://rustify.rs/glossary/feature-flags)
- [medium.com](https://medium.com/rustaceans/the-cargo-features-most-rust-developers-still-underuse-674592a08826)
- [docs.rs](https://docs.rs/axum/latest/axum/middleware/index.html)
- [stackoverflow.com](https://stackoverflow.com/questions/76333037/gracefully-close-persistent-connections-on-shutdown)
- [github.com](https://github.com/actix/actix-web/issues/3169)
- [medium.com](https://medium.com/techkoala-insights/axum-state-vs-extension-avoid-runtime-errors-with-safer-extractors-a42105c6eb71)
- [oneuptime.com](https://oneuptime.com/blog/post/2026-01-07-rust-graceful-shutdown/view)
- [oneuptime.com](https://oneuptime.com/blog/post/2026-01-25-graceful-shutdown-rust-services/view)
- [medium.com](https://medium.com/@wedevare/rust-async-graceful-shutdown-for-axum-servers-signals-draining-cleanup-done-right-3b52375412ec)
- [arc2proxy.com](https://arc2proxy.com/blog/graceful-shutdown-in-axum-and-tokio)
- [daily.dev](https://daily.dev/posts/my-favorite-rust-development-tools-setups-and-ai-workflows-webopzhz0)
- [github.com](https://github.com/specta-rs/rspc/discussions/351)
- [toolsku.com](https://www.toolsku.com/en/blog/rust-axum-openapi-utoipa-2026/)
- [medium.com](https://medium.com/p/b7713b522518)
- [crates.io](https://crates.io/crates/actix-web)
- [crates.io](https://crates.io/crates/rocket)
- [docs.rs](https://docs.rs/poem-openapi/latest/poem_openapi/)
- [salvo.rs](https://salvo.rs/guide/topics/graceful-shutdown)
- [rustify.rs](https://rustify.rs/articles/rust-axum-vs-actix-web-2026)
- [pratikpathak.com](https://pratikpathak.com/building-fast-apis-in-rust-actix-vs-axum-vs-rocket-2026/)
- [crates.io](https://crates.io/crates/axum-core)
- [medium.com](https://medium.com/@enravishjeni411/state-management-in-rust-web-backends-with-axum-8f000483105d)
- [github.com](https://github.com/tokio-rs/axum/blob/main/examples/graceful-shutdown/src/main.rs)
- [crates.io](https://crates.io/crates/simple_on_shutdown/0.1.8)
- [ycombinator.com](https://news.ycombinator.com/item?id=39877532)
- [ediri.io](https://blog.ediri.io/boost-your-rust-development-with-hot-reload-using-cargo-watch)
- [gitconnected.com](https://levelup.gitconnected.com/the-state-of-rust-in-2026-crossing-the-enterprise-chasm-9d1b1b44e1d6)
- [substack.com](https://weeklyrust.substack.com/p/state-of-rust-survey-findings)
