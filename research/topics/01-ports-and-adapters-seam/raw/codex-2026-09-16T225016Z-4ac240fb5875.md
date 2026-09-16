### Landscape

**Decision category.** R01 decides the driven-I/O boundary: the application calls a capability contract while CLI and web entry points select its concrete implementation. This is not a choice of HTTP client, async runtime, or Cargo topology; those are R05 and R02 respectively. The source record establishes a real architectural split: Python has a `Protocol` port, a composition root, a shipped in-memory adapter, and a shared adapter contract suite, whereas TypeScript injects an object of typed functions into its router. The record explicitly says that no decision log explains F001, F002, F013, or F121, so neither source shape is a presumed winner. [Local divergence analysis](../../../../docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-05, R01/F001–F121).

| Bin | Candidates found | Role in this decision |
|---|---|---|
| Built-in / first-party | Rust trait plus explicit `impl`; generic `P: ProjectsPort`; `Arc<dyn ProjectsPort + Send + Sync>`; `BTreeMap` and `RwLock`; `#[derive]` | The language natively supplies both static and dynamic polymorphism, synchronization, and compiler checking. The Rust Reference says a `dyn` object is a pointer-plus-vtable form of a dyn-compatible trait, and that generic trait bounds remain available for static checking. [Trait objects](https://doc.rust-lang.org/stable/reference/types/trait-object.html) and [traits / dyn compatibility](https://doc.rust-lang.org/reference/items/traits.html) (retrieved 2026-09-05). |
| Established industry standard | `serde` 1.0.229 and `serde_json` 1.0.151 | Serde is the conventional shared Rust data-model and serialization layer; it lets the library own request/response structs while front ends render them differently. Serde documents the data-model contract and framework-independent serialization approach. [Serde overview](https://serde.rs/) (retrieved 2026-09-05). |
| Up-and-comer / specialized | `mockall` 0.15.0; `shaku` 0.6.3 | Mockall generates mocks for expectation-heavy unit tests; Shaku is compile-time DI. They are useful leads, not prerequisites for a two-adapter seam. [Mockall docs](https://docs.rs/mockall/latest/mockall/) and [Shaku docs](https://docs.rs/shaku/latest/shaku/) (retrieved 2026-09-05). |

**Authorities and practice evidence.** The Rust Reference is the language specification, so it governs dyn compatibility and trait-object constraints; the Rust standard-library documentation describes the dispatch and code-size tradeoff; Serde’s maintained project documentation defines its data model. The Rust Project’s 2024 survey is authoritative ecosystem context, but it does not select an architecture; its 7,310 completed responses are not evidence that a crate is appropriate for this template. [Rust `dyn` keyword](https://doc.rust-lang.org/std/keyword.dyn.html) and [2024 State of Rust survey](https://blog.rust-lang.org/2025/02/13/2024-State-Of-Rust-Survey-results/) (retrieved 2026-09-05).

Practice is weighted toward maintained, broadly adopted projects rather than a benchmark. `serde` and `serde_json` are maintained by the Serde project and have 1,355,199,652 and 1,259,356,567 all-time crates.io downloads respectively; their GitHub repositories have 10,800 and 5,635 stars. Those figures demonstrate broad ecosystem use, not a performance result. `mockall` has 164,279,034 downloads and 1,837 stars; Shaku has 240,829 downloads and 609 stars. The applicable endpoints and retrieval date are recorded in the member entries. No benchmark was used because this decision has no representative workload yet and a microbenchmark would not decide application-bound HTTP latency.

### Principles and implementation

**Shared requirement and agreement level.** The cross-repository principle is *replaceable driven I/O with one business contract and hermetic verification*. Agreement is required at the architectural-pattern level: application use cases must depend on a named capability, one production adapter must be composed at the outer edge, a supported in-memory adapter must exist, and every adapter must pass the same behavior suite. Agreement is not required at the low-level mechanism: Python can use structural `Protocol`, TypeScript can use an injected function record where that remains clear, and Rust should use an explicit trait implementation. The Python and TypeScript evidence is source evidence, not proof of a common library choice. [Local source inventory](../../../../docs/port/areas/workspace-architecture.md) and [local testing inventory](../../../../docs/port/areas/testing-coverage.md) (retrieved 2026-09-05, F001/F002/F011/F013/F018/F121).

**Recommended Rust pattern.** Define a small role-specific, dyn-compatible trait such as `ProjectsPort: Send + Sync`; make every fallible method return the error vocabulary R03/R05 eventually decide. At the application-service boundary store `Arc<dyn ProjectsPort>`. At local test boundaries retain a generic helper, `fn projects_contract<P: ProjectsPort>(port: &P)`, so both production and in-memory adapters are compiled and run through identical examples. Rust validates the nominal `impl ProjectsPort for HttpProjectsAdapter` at compile time; an `assert_port::<HttpProjectsAdapter>()` helper makes that obligation visible in a unit test. Unlike Python, Rust does not infer structural conformance from matching method names: an explicit `impl` is intentional and compiler-checked. [Rust traits](https://doc.rust-lang.org/stable/std/keyword.trait.html) and [Rust trait objects](https://doc.rust-lang.org/stable/reference/types/trait-object.html) (retrieved 2026-09-05).

This selects trait-object dispatch for the long-lived application boundary, not generic propagation throughout all front ends. A trait object has an indirect call and usually prevents inlining, while generic bounds can monomorphize and duplicate code for every adapter; the standard library documents both tradeoffs. The template has one live adapter, one first-class fake, and potentially concurrent web handlers, so stable type erasure at the composition root is more valuable than a non-demonstrated micro-optimization. Tests still use generic contract functions, preserving static checking where it has no public type-shape cost. [Rust `dyn` trade-offs](https://doc.rust-lang.org/std/keyword.dyn.html) (retrieved 2026-09-05).

R05 remains a hard boundary: native `async fn` trait methods are not dyn-compatible, so this report does not select `async_trait`, boxed futures, or a runtime. R05 must either preserve object safety through its chosen method representation or record a coordinated change to this `Arc<dyn ProjectsPort>` boundary. [Dyn-compatibility restrictions](https://doc.rust-lang.org/reference/items/traits.html#dyn-compatibility) (retrieved 2026-09-05).

The composition root is a plain outer-layer factory, for example `fn build_application(config: &Config) -> Application`, which constructs `HttpProjectsAdapter`, erases it to `Arc<dyn ProjectsPort>`, then gives `Application` to either CLI or web startup. A DI container makes the construction graph less inspectable without adding a needed runtime capability. The first-class fake is `InMemoryProjectsAdapter`, exported as supported library API, backed by `BTreeMap` plus `RwLock` only if the chosen service calls require concurrent mutation. A builder plus immutable map is preferable when mutation is unnecessary. `std` supplies both choices; no interior-mutability crate is required. [Rust synchronization primitives](https://doc.rust-lang.org/std/sync/) (retrieved 2026-09-05).

For F018, library-owned request, result, and error-facing data-transfer structs derive `serde::Serialize` and `serde::Deserialize`; the CLI formats the same result and the web adapter serializes it. The web layer may add HTTP-only extraction, status, and problem-envelope translation, but it must not redefine the application DTO. This preserves one data contract while respecting that an HTTP response is not identical to terminal presentation. [Serde data model](https://serde.rs/data-model.html) (retrieved 2026-09-05).

**Minimal realistic example and acceptance criteria.** An `Application` constructed with `Arc<dyn ProjectsPort>` serves `projects get acme`; `HttpProjectsAdapter` obtains `acme` from the transport determined by R05, and `InMemoryProjectsAdapter` returns the same seeded project. The CLI renders `ProjectView`; the web route serializes that same `ProjectView`. Acceptance is observable when (1) `cargo test` compiles both explicit trait implementations, (2) one generic contract suite passes against both adapters, (3) the CLI and web tests compare the same library value, and (4) a compile-fail or ordinary compilation test rejects an adapter that omits a required trait method. These are proposed integration checks, not completed template tests.

**Executed narrow probe.** On 2026-09-05, this worker compiled and ran an Edition-2024 Rust 1.98.0 probe containing `ProjectsPort: Send + Sync`, `Arc<dyn ProjectsPort>`, `InMemory` backed by `RwLock<BTreeMap<…>>`, `assert_port::<InMemory>()`, and a generic contract function. It exited successfully. This proves only language-level composition on the local toolchain; it does not prove the future async representation, HTTP adapter, web framework, MSRV, or an external crate dependency tree.

**BASELINE-REVIEW: F001/F002/F011/F013/F018/F121 — replaceable driven I/O with a shared behavior contract — adopt a Rust trait-object application boundary plus generic contract tests, rather than copying Python’s structural `Protocol` or TypeScript’s ungrouped function record — evidence: Rust’s native traits explicitly encode a contract; dyn-compatible traits enable late binding; and the local ledger identifies the intended cross-adapter behaviors, while no source decision establishes either previous mechanism as universally fit.** [Rust Reference](https://doc.rust-lang.org/reference/items/traits.html) and [local R01 analysis](../../../../docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-05).

### Recommendation

Adopt one stack: **Rust standard library traits + `Arc`/optional `RwLock`; `serde` 1.0.229; `serde_json` 1.0.151; no DI or mocking crate in the base template.** Define role-specific, dyn-compatible port traits and compose production adapters into `Arc<dyn Port + Send + Sync>` at a plain factory function. Ship a hand-written `InMemory…Adapter`; use generic contract-test helpers over `P: Port`; derive Serde on library DTOs. Keep `mockall` as an opt-in, test-only exception for an interaction assertion that a fake cannot express. Do not add Shaku. Version availability and MSRV evidence are below. [Rust trait-object documentation](https://doc.rust-lang.org/stable/reference/types/trait-object.html) and [Serde documentation](https://serde.rs/) (retrieved 2026-09-05).

### Members

#### Rust standard-library port pattern

##### Landscape

Built-in candidate: explicit traits, generic bounds, trait objects, `Arc`, `BTreeMap`, and `RwLock`. No package, download, release, GitHub, RustSec, or responder figure applies because these are Rust toolchain components rather than crates. [Rust traits](https://doc.rust-lang.org/stable/std/keyword.trait.html) (retrieved 2026-09-05).

##### Principles and implementation

Use a trait for a capability, not a broad “repository” grab-bag; keep it dyn-compatible and add `Send + Sync` only when the selected web/runtime model needs cross-thread sharing. Explicit `impl` blocks are the compiler-checked satisfaction proof. The Reference forbids `async fn`, generic methods, `Self` returns, and certain associated items in a dyn-compatible trait, which is why R05 must shape asynchronous methods carefully. [Dyn compatibility](https://doc.rust-lang.org/reference/items/traits.html#dyn-compatibility) (retrieved 2026-09-05).

##### Dominant choice

`Arc<dyn ProjectsPort + Send + Sync>` in `Application`; `P: ProjectsPort` in contract-test helpers; `InMemoryProjectsAdapter` implemented using `std` collections and synchronization. [Rust trait object layout](https://doc.rust-lang.org/stable/reference/types/trait-object.html) (retrieved 2026-09-05).

##### Qualified shortlist

`Application<P: ProjectsPort>` with static dispatch is qualified for a single front-end or a performance-measured hot loop; an injected record of closures is qualified for a very small boundary. Both preserve injection, but neither provides the recommended stable, named application boundary for CLI plus web. [Rust generic trait bounds](https://doc.rust-lang.org/reference/items/traits.html) (retrieved 2026-09-05).

##### Excluded by gate

No external dependency-injection container is selected. This is an integration-cost exclusion, not a license, MSRV, advisory, OS, or unsafe-code failure: a plain factory already makes the graph explicit. `shaku` is considered separately below. [Shaku documentation](https://docs.rs/shaku/latest/shaku/) (retrieved 2026-09-05).

##### Up-and-comers

Closure records and compile-time DI frameworks can reduce local boilerplate, but they do not supply a capability-level cross-adapter contract by themselves. Their relevance is therefore secondary to an explicit trait. [Rust trait documentation](https://doc.rust-lang.org/stable/std/keyword.trait.html) (retrieved 2026-09-05).

##### Fit for this template

License, crate-tree MSRV, RustSec, downloads, release, GitHub, issues, and advisories are inapplicable: this member is the Rust standard library. `unsafe` posture is safe Rust only in the proposed code. Ubuntu and macOS are supported by the Rust toolchain; CI must still test the owner-fixed matrix. Compile-time cost is negligible; trait-object binary cost is one allocation/reference-counted handle plus indirect calls, while generic use can increase code size per implementation. [Rust `dyn` trade-offs](https://doc.rust-lang.org/std/keyword.dyn.html) (retrieved 2026-09-05).

##### Recommendation

Use the standard library only for the seam and fake storage.

##### Ranked runner-up

Generic `Application<P: ProjectsPort>` is runner-up when R05 or R02 makes a single concrete service graph demonstrably simpler.

##### Tradeoffs

The selected object form trades an indirect call and no inlining for one non-generic application type shared by CLI and web. Generic dispatch removes that indirection but spreads type parameters and can duplicate code per adapter. [Rust `dyn` keyword](https://doc.rust-lang.org/std/keyword.dyn.html) (retrieved 2026-09-05).

##### Parameters

Owns `http-transport-injection-seam = role-specific dyn-compatible trait object at the long-lived application boundary; generic trait-bound helpers for tests`. Assumes `rust-edition = 2024`, `msrv-policy = stable minus 2 minor versions`, `target-os-matrix = ubuntu-latest, macos-latest`, and `license = MIT OR Apache-2.0`. `CONFLICT: R05 sync-async execution model — native async trait methods are not dyn-compatible — R05 must select an object-safe representation or explicitly coordinate a seam change.` [Parameters registry](../../../../docs/port/PARAMETERS.md) and [Rust dyn compatibility](https://doc.rust-lang.org/reference/items/traits.html#dyn-compatibility) (retrieved 2026-09-05).

##### Migration implications

Planned files: `src/ports/projects.rs` defines the trait; `src/adapters/http_projects.rs` and `src/adapters/in_memory_projects.rs` implement it; `src/application.rs` owns `Arc<dyn ProjectsPort>`; `src/composition.rs` constructs the live graph; `tests/projects_port_contract.rs` holds generic contract cases. R02 decides the final crate locations. [Local R01/R02 boundary note](../../../../docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-05).

##### Validation strategy

Planned: `cargo test --workspace --locked` must run the generic contract suite for both adapters; `cargo clippy --workspace --all-targets -- -D warnings` must compile the explicit `impl` blocks; macOS and Ubuntu CI run the same commands. Executed only: the narrow Rust 1.98.0 standard-library probe described above.

##### Confidence & re-verify trigger

High for synchronous object-safe methods; re-verify when R05 chooses asynchronous method signatures or R02 changes ownership/topology. [Rust dyn compatibility](https://doc.rust-lang.org/reference/items/traits.html#dyn-compatibility) (retrieved 2026-09-05).

##### Sources

[Rust Reference: traits](https://doc.rust-lang.org/reference/items/traits.html), [Rust Reference: trait objects](https://doc.rust-lang.org/stable/reference/types/trait-object.html), and [Rust standard-library `dyn` documentation](https://doc.rust-lang.org/std/keyword.dyn.html) (all retrieved 2026-09-05).

#### serde and serde_json

##### Landscape

`serde` supplies derives and a data model; `serde_json` supplies the JSON format implementation. They are established standards, not web-framework selections. [Serde overview](https://serde.rs/) (retrieved 2026-09-05).

##### Principles and implementation

Derive Serde on library-owned `ProjectView`, command input, and public error-envelope payload types; make CLI formatting and web JSON two adapters over those values. Do not derive HTTP status or framework extractors into the core types. [Serde data model](https://serde.rs/data-model.html) (retrieved 2026-09-05).

##### Dominant choice

`serde` 1.0.229 and `serde_json` 1.0.151, with default features reviewed when the web stack is selected. [Serde crate endpoint](https://crates.io/api/v1/crates/serde/versions) and [serde_json crate endpoint](https://crates.io/api/v1/crates/serde_json/versions) (retrieved 2026-09-05).

##### Qualified shortlist

Hand-written JSON or a web-framework-local response type can work for private endpoints, but they duplicate F018’s contract and have no advantage for a library intended to be shared by CLI and web. [Serde overview](https://serde.rs/) (retrieved 2026-09-05).

##### Excluded by gate

None. License is `MIT OR Apache-2.0`; declared crate MSRVs are Rust 1.56 for Serde 1.0.229 and Rust 1.71 for serde_json 1.0.151, both below the owner policy’s moving stable-minus-two floor at retrieval. The RustSec per-package URLs specified by the prompt returned HTTP 404, so a fresh `cargo audit` against the resolved lockfile remains a mandatory re-verification rather than an invented “no advisories” result. [Serde versions](https://crates.io/api/v1/crates/serde/versions), [serde_json versions](https://crates.io/api/v1/crates/serde_json/versions), and [RustSec advisory index](https://rustsec.org/advisories/) (retrieved 2026-09-05).

##### Up-and-comers

No up-and-comer is needed: serialization is a supporting contract mechanism, not the seam itself.

##### Fit for this template

`serde`: 1,355,199,652 all-time and 295,688,106 90-day downloads from `GET https://crates.io/api/v1/crates/serde`; newest non-yanked release 1.0.229, created 2026-07-18, from `GET https://crates.io/api/v1/crates/serde/versions`. GitHub: 10,800 stars, not archived, pushed 2026-08-25, from `GET https://api.github.com/repos/serde-rs/serde`; 318 open issues from `GET https://api.github.com/search/issues?q=repo:serde-rs/serde+is:issue+is:open`. `serde_json`: 1,259,356,567 all-time and 299,793,085 90-day downloads from `GET https://crates.io/api/v1/crates/serde_json`; newest non-yanked release 1.0.151, created 2026-07-20, from `GET https://crates.io/api/v1/crates/serde_json/versions`; GitHub has 5,635 stars, is not archived, and was pushed 2026-08-08 from `GET https://api.github.com/repos/serde-rs/json`. All figures retrieved 2026-09-05. The anonymous GitHub API rate limit prevented complete search totals and 10-issue maintainer-response medians for `serde_json`; Serde’s ten newest issue records had nine without comments and one with a comment, so no valid median maintainer response could be calculated without inspecting author associations. Both crates are active by recent release/repository activity. Default features, dependency trees, binary size, compile time, safe/unsafe posture, and Ubuntu/macOS build must be recorded from the final lockfile and CI; the expected impact is modest derive/format compilation, not runtime transport cost. [Crates.io Serde](https://crates.io/api/v1/crates/serde), [Crates.io serde_json](https://crates.io/api/v1/crates/serde_json), [Serde GitHub](https://api.github.com/repos/serde-rs/serde), and [JSON GitHub](https://api.github.com/repos/serde-rs/json) (retrieved 2026-09-05).

##### Recommendation

Use both as the shared DTO and JSON-format layer; keep framework adapters outside the DTO module.

##### Ranked runner-up

Framework-owned serializers are runner-up only if R69 proves the web API is not a public library contract.

##### Tradeoffs

Serde derives reduce duplicated transformations but expose a public serialization shape that needs compatibility discipline. A web-only translation layer isolates HTTP evolution but repeats mapping code. [Serde data model](https://serde.rs/data-model.html) (retrieved 2026-09-05).

##### Parameters

Assumes `http-transport-injection-seam` provides library-owned results. No R01 parameter is owned by either crate. No conflict.

##### Migration implications

Add derives to library DTOs and use `serde_json` in web integration tests; do not make CLI formatting depend on HTTP types. [Serde overview](https://serde.rs/) (retrieved 2026-09-05).

##### Validation strategy

Planned: construct a `ProjectView`, render it through the CLI formatter, serialize it with `serde_json`, deserialize it, and assert equality; run `cargo audit --locked` after generating the lockfile. No Serde dependency was compiled in this run.

##### Confidence & re-verify trigger

Medium-high. Re-verify latest release, resolved dependency MSRV, advisories, default features, and the public DTO compatibility policy when R69 chooses the web framework.

##### Sources

[Serde](https://serde.rs/), [Serde crate API](https://crates.io/api/v1/crates/serde), [Serde versions API](https://crates.io/api/v1/crates/serde/versions), [serde_json crate API](https://crates.io/api/v1/crates/serde_json), [serde_json versions API](https://crates.io/api/v1/crates/serde_json/versions), and [RustSec advisories](https://rustsec.org/advisories/) (all retrieved 2026-09-05).

#### mockall

##### Landscape

Mockall is an established specialized mock generator and is relevant because the prompt names it; it is not a substitute for an adapter contract suite. [Mockall documentation](https://docs.rs/mockall/latest/mockall/) (retrieved 2026-09-05).

##### Principles and implementation

Expectation mocks verify interactions; the required F121 suite verifies observable behavior across adapters. A hand-written in-memory adapter proves the latter and ships as usable library infrastructure, while a generated mock proves neither by itself. [Local F121 evidence](../../../../docs/port/areas/testing-coverage.md) (retrieved 2026-09-05).

##### Dominant choice

Do not add Mockall to the base stack.

##### Qualified shortlist

Allow a test-only `mockall` dev-dependency only for a narrow negative-path interaction test that cannot be stated with the in-memory fake.

##### Excluded by gate

Excluded from the base template for integration and compile-time cost, not for a failed license or MSRV gate. Version 0.15.0 declares `MIT OR Apache-2.0` and Rust 1.77, compatible with the fixed license and currently below the moving MSRV floor. The prompt-mandated RustSec package page returned HTTP 404; lockfile audit is required before opt-in use. [Mockall versions API](https://crates.io/api/v1/crates/mockall/versions) and [RustSec advisories](https://rustsec.org/advisories/) (retrieved 2026-09-05).

##### Up-and-comers

Mockall remains a viable specialized tool, not an architecture.

##### Fit for this template

164,279,034 all-time and 27,607,997 90-day downloads from `GET https://crates.io/api/v1/crates/mockall`; newest non-yanked release 0.15.0 created 2026-06-28 from `GET https://crates.io/api/v1/crates/mockall/versions`; 1,837 stars, not archived, and pushed 2026-09-02 from `GET https://api.github.com/repos/asomers/mockall`; 51 open issues from `GET https://api.github.com/search/issues?q=repo:asomers/mockall+is:issue+is:open`, all retrieved 2026-09-05. The anonymous search endpoint subsequently returned HTTP 403, so no reproducible maintainer-response median is reported; the newest-issues endpoint did return ten issue records, all with at least one comment except none is not sufficient to identify a maintainer. The crate is active by release and push dates. Its macro/proc-macro dependency tree adds compile work; binary impact is test-only. Safe/unsafe posture and OS proof require the resolved dependency tree and Ubuntu/macOS CI. [Mockall crate API](https://crates.io/api/v1/crates/mockall) and [Mockall GitHub](https://api.github.com/repos/asomers/mockall) (retrieved 2026-09-05).

##### Recommendation

Omit from base dependencies; permit a documented test-only exception later.

##### Ranked runner-up

Mockall is the runner-up only for interaction-centric tests.

##### Tradeoffs

It reduces mock boilerplate but duplicates a fake’s role poorly and increases macro compilation. The hand-written fake is clearer as a product-supported demonstration adapter.

##### Parameters

Assumes the R01 trait seam. No owned parameter; no conflict.

##### Migration implications

None now. If later approved, add it only under `[dev-dependencies]` and retain the generic fake-vs-real contract suite.

##### Validation strategy

Planned only: pin the selected version, run `cargo audit --locked`, `cargo test --workspace --locked`, and the owner OS matrix. No Mockall code ran in this report.

##### Confidence & re-verify trigger

Medium for exclusion. Reconsider only when a concrete interaction cannot be asserted through a fake or observable result.

##### Sources

[Mockall docs](https://docs.rs/mockall/latest/mockall/), [crate API](https://crates.io/api/v1/crates/mockall), [versions API](https://crates.io/api/v1/crates/mockall/versions), [GitHub API](https://api.github.com/repos/asomers/mockall), and [RustSec](https://rustsec.org/advisories/) (all retrieved 2026-09-05).

#### shaku

##### Landscape

Shaku is a compile-time DI framework and is the relevant container alternative to the recommended plain composition root. [Shaku docs](https://docs.rs/shaku/latest/shaku/) (retrieved 2026-09-05).

##### Principles and implementation

It can wire components but does not remove the need to choose, expose, and behaviorally test a port. The plain factory is smaller and makes the dependency direction visible to readers. [Shaku docs](https://docs.rs/shaku/latest/shaku/) (retrieved 2026-09-05).

##### Dominant choice

No Shaku.

##### Qualified shortlist

Shaku is qualified only if a future application has a demonstrably large configuration-dependent graph that plain constructors make error-prone.

##### Excluded by gate

Excluded for poor fit and maturity evidence, not a known hard gate failure: 0.6.3 declares `MIT/Apache-2.0` and Rust 1.88, which are compatible. Its RustSec package URL returned HTTP 404, so it cannot be declared advisory-clear without a future lockfile audit. [Shaku versions API](https://crates.io/api/v1/crates/shaku/versions) and [RustSec advisories](https://rustsec.org/advisories/) (retrieved 2026-09-05).

##### Up-and-comers

Shaku is the up-and-comer container candidate, with a much smaller adoption signal than Serde.

##### Fit for this template

240,829 all-time and 34,716 90-day downloads from `GET https://crates.io/api/v1/crates/shaku`; newest non-yanked release 0.6.3 created 2026-08-02 from `GET https://crates.io/api/v1/crates/shaku/versions`; 609 stars, not archived, and pushed 2026-08-09 from `GET https://api.github.com/repos/AzureMarker/shaku`, retrieved 2026-09-05. GitHub’s anonymous search query was rate-limited (HTTP 403), so open-issue count and a ten-issue maintainer-response median are unverified; the issue listing showed the newest issue opened 2025-02-13 and older open issues, which is insufficient to call it at-risk under the prompt rubric. Maintenance classification: active by recent release/repository push, with a re-verification trigger for support responsiveness. Default feature choices, dependency-tree MSRV, unsafe posture, binary/compile cost, and Ubuntu/macOS build require a lockfile and CI; macro-based DI adds compile complexity. [Shaku crate API](https://crates.io/api/v1/crates/shaku) and [Shaku GitHub](https://api.github.com/repos/AzureMarker/shaku) (retrieved 2026-09-05).

##### Recommendation

Exclude; use a plain composition-root factory.

##### Ranked runner-up

Shaku is the ranked runner-up to a factory only after measured graph complexity justifies it.

##### Tradeoffs

It centralizes wiring but hides ordinary construction behind macros and does not eliminate explicit trait contracts or contract testing.

##### Parameters

Assumes the owned seam but owns none. No conflict.

##### Migration implications

None. Keep composition construction in an outer module; R02 decides its crate.

##### Validation strategy

Planned only if reconsidered: resolve and audit the lockfile, inspect generated DI API, compile the example on Ubuntu/macOS, and compare error messages and startup wiring against the factory.

##### Confidence & re-verify trigger

High for excluding it from this small template; reconsider if the composition graph becomes large enough to make constructor wiring materially unsafe or opaque.

##### Sources

[Shaku docs](https://docs.rs/shaku/latest/shaku/), [crate API](https://crates.io/api/v1/crates/shaku), [versions API](https://crates.io/api/v1/crates/shaku/versions), [GitHub API](https://api.github.com/repos/AzureMarker/shaku), and [RustSec](https://rustsec.org/advisories/) (all retrieved 2026-09-05).

### Compatibility

The recommended members compose without a DI or mocking crate: the standard-library port owns `ProjectView`; `serde` derives its reusable data-model conversion; `serde_json` serializes it at the web boundary. The executed standard-library probe proved the trait-object plus generic-contract half together, but no Cargo project has yet resolved Serde versions with the selected web stack. Compatibility with an async adapter is contingent on R05 preserving dyn compatibility. [Rust dyn compatibility](https://doc.rust-lang.org/reference/items/traits.html#dyn-compatibility) and [Serde](https://serde.rs/) (retrieved 2026-09-05).

### Parameters

owns `http-transport-injection-seam = named, role-specific dyn-compatible Rust trait injected as Arc<dyn Port + Send + Sync> at the application boundary; generic P: Port helpers for contract tests`.

assumes `rust-edition = 2024`; `msrv-policy = stable minus 2 minor versions, raised only in a minor release`; `license = MIT OR Apache-2.0`; `target-os-matrix = ubuntu-latest, macos-latest`.

CONFLICT: R05 sync-async execution model — native `async fn` in traits cannot be dynamically dispatched — R05 must choose an object-safe async representation or coordinate replacement of the object boundary. [Parameter registry](../../../../docs/port/PARAMETERS.md) and [Rust Reference](https://doc.rust-lang.org/reference/items/traits.html#dyn-compatibility) (retrieved 2026-09-05).

### Migration implications

Create the planned port, application, adapter, composition, and generic contract-test files named in the standard-library member. Export `InMemoryProjectsAdapter` as supported library API. Have CLI and web invoke `Application` and consume library DTOs; prohibit either entry point from constructing the other. Do not select crate topology, HTTP client, async runtime, web framework, error envelope, or mocking policy beyond this seam; those remain R02, R05, R69, R70, and R48. [Research index](../../../../research/CLAUDE.md) and [local R01 analysis](../../../../docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-05).

### Validation strategy

Planned integration commands after R02/R05 create the workspace:

```text
cargo test --workspace --locked
cargo clippy --workspace --all-targets -- -D warnings
cargo audit --locked
```

Expected behavior: the generic port contract executes unchanged for `InMemoryProjectsAdapter` and the real adapter test double; CLI and web tests assert the same `ProjectView` value; CI runs all commands on `ubuntu-latest` and `macos-latest`. The `cargo audit` result must replace the unverified RustSec package-page results. Executed result: only the isolated Rust 1.98.0 standard-library probe passed; no template, Serde, web, real HTTP, MSRV-floor, or cross-OS test has run. [Cargo Audit](https://github.com/rustsec/rustsec/tree/main/cargo-audit) and [Rust traits](https://doc.rust-lang.org/reference/items/traits.html) (retrieved 2026-09-05).

### Confidence & re-verify trigger

Confidence is medium-high for the seam architecture and medium for the exact dependency versions. Re-verify before decision publication when R05 selects async signatures, R02 chooses crate topology, R69 selects the web framework, or a lockfile exists; refresh crates.io releases, GitHub maintenance and responsiveness, RustSec/audit output, resolved MSRV, feature flags, compile size, and both CI operating systems. [R01 prompt constraints](inputs/prompt.md) (retrieved 2026-09-05).

### Sources

Primary language sources: [Rust Reference: traits](https://doc.rust-lang.org/reference/items/traits.html), [Rust Reference: trait objects](https://doc.rust-lang.org/stable/reference/types/trait-object.html), and [Rust `dyn` keyword](https://doc.rust-lang.org/std/keyword.dyn.html). Ecosystem sources: [Serde](https://serde.rs/), [Mockall](https://docs.rs/mockall/latest/mockall/), [Shaku](https://docs.rs/shaku/latest/shaku/), [crates.io Serde](https://crates.io/api/v1/crates/serde), [crates.io serde_json](https://crates.io/api/v1/crates/serde_json), [crates.io Mockall](https://crates.io/api/v1/crates/mockall), [crates.io Shaku](https://crates.io/api/v1/crates/shaku), [RustSec advisories](https://rustsec.org/advisories/), and the [2024 State of Rust survey](https://blog.rust-lang.org/2025/02/13/2024-State-Of-Rust-Survey-results/). Local source evidence: [R01 source inventory](../../../../docs/port/areas/workspace-architecture.md), [F121 test inventory](../../../../docs/port/areas/testing-coverage.md), [R01 divergence analysis](../../../../docs/port/DIVERGENCE-ANALYSIS.md), and [parameter registry](../../../../docs/port/PARAMETERS.md). All sources retrieved 2026-09-05.

Method notes: queried `GET https://crates.io/api/v1/crates/{serde,serde_json,mockall,shaku}` and `/versions`; `GET https://api.github.com/repos/{serde-rs/serde,serde-rs/json,asomers/mockall,AzureMarker/shaku}`; and the prescribed GitHub issue-search endpoints. The unauthenticated GitHub search limit prevented some open-issue and responder calculations. The prescribed `https://rustsec.org/packages/<name>.html` URLs returned HTTP 404, so this report does not invent advisory clearance; `cargo audit --locked` is required once a lockfile exists.
