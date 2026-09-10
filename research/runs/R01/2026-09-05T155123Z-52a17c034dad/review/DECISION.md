R01 ports-and-adapters-seam (bundle, Deep) — decision. Synthesizer: fresh Claude Fable context (`claude-fable-5-1`), 2026-09-09; run `research/runs/R01/2026-09-05T155123Z-52a17c034dad`; first revision, no `## Supersedes`.

## Decision

`rs-launch-blueprint` **adopts a port/adapter split** for its driven-I/O seam, expressed with the Rust standard library plus one runtime dependency:

| Member | Ledger row | Mechanism | Version |
|---|---|---|---|
| Port abstraction | F001 | a dyn-compatible `pub trait ProjectsPort: Send + Sync` (no `async fn`, generic methods, associated consts or non-receiver `Self`) plus a blanket `impl<T: ProjectsPort + ?Sized> ProjectsPort for Arc<T>`; the use case is `ProjectsService<P: ProjectsPort>`; the alias `ErasedProjectsService = ProjectsService<Arc<dyn ProjectsPort>>` is the one instantiation the CLI and the web layer share | language feature, no crate |
| Composition root | F002 | two plain functions — `build_projects_service(port: Arc<dyn ProjectsPort>)` for callers that bring their own adapter and `production_service(..)`, the only place the production adapter is constructed; no dependency-injection container | language feature, no crate |
| Adapter-satisfies-port verification | F011 | the explicit `impl ProjectsPort for Adapter` item; rustc rejects a missing or mistyped method at `cargo check` (E0046) and a non-dyn-compatible port at the erasure site (E0038); no tool to select | compiler |
| Shipped first-class fake | F013 | `pub struct InMemoryProjectsPort { rows: std::sync::Mutex<Vec<Project>> }`, public, unconditional (no `cfg(test)`, no feature) | `std::sync::Mutex`, no crate |
| Substitutability suite | F121 | one generic `pub fn assert_projects_port_contract<P: ProjectsPort>(label, make)` holding every behavioral assertion once, called from `tests/` once per adapter; no parametrization or mocking crate | built-in `#[test]` harness |
| Shared data contract for the web layer | F018 | `#[derive(Serialize, Deserialize)]` on the library-owned `Project` and `ProjectQuery`; the CLI renders and the web handler returns those exact types; a `From` translation layer is held in reserve, not built | `serde` **1.0.229** (`derive` feature); `serde_json` **1.0.151** only at JSON boundaries (the serializer choice itself is R66's) |

Conditional and optional members, not in the base stack:

- **`async-trait` 0.1.92** (2026-08-08) joins the stack **only if R05 selects an async I/O boundary**: a native `async fn` in the port makes it not dyn compatible (E0038, observed by the opus report on rustc 1.98.0), and `#[async_trait]` restores dyn compatibility with no other change to the seam. `rust-lang/crates.io` pins `async-trait = "=0.1.92"` for its `GitHubClient` port for the same reason. This decision does not choose sync or async.
- **`mockall` 0.15.0** may be offered behind an off-by-default `mock` Cargo feature (`[features] mock = ["dep:mockall"]`, the `crates_io_github` pattern) for interaction assertions a fake cannot express. It cannot serve F121 (a mock's behavior is programmed per test, so there is nothing to compare) and the crate selection is R48's.

Not selected: a dependency-injection container (`shaku` 0.6.3, `dill` 0.17.0, `nject` 0.5.1, `teloc` 0.2.0), struct mocking without a trait (`faux` 0.1.13), an architecture framework (`hexser`), lock replacements (`parking_lot` 0.12.5), value-parametrization macros for the suite (`rstest` 0.26.1, `test-case` 3.3.1), and ts's boxed-closure seam (`Box<dyn Fn>` fields) — reasons under *Architecture alternatives* and *Excluded by gate* below.

Settled ledger rows: **F001, F002, F011, F013, F018, F121**.

### Principles and implementation

**Shared requirement.** The core use case must depend on a named driven-I/O contract, be exercisable against a substitutable implementation of it, that substitute must be a shipped first-class artifact rather than a per-test improvisation, one contract must be asserted against every implementation, and every inbound front end (CLI, web) must call one transport-neutral application contract and emit one shared data contract.

**Source and agreement level.** `docs/port/DIVERGENCE-ANALYSIS.md` (R01 sub-rows, cause class F "genuine design disagreement", `harmonize: partly`) splits the bundle:

| Row | Subject | `harmonize` | Agreement level |
|---|---|---|---|
| F001 | port abstraction | no | mechanism — Rust decides alone |
| F002 | composition-root shape | no | mechanism — Rust decides alone |
| F011 | adapter-satisfies-port verification | no | mechanism — Rust decides alone |
| F013 | shipped first-class fake | yes | **capability — must agree across py, ts, rs** |
| F018 | web layer as a thin adapter over one contract | yes | **capability — must agree where a web tier exists** |
| F121 | one suite against every adapter | yes | **capability — must agree** |

What must agree is the capability (a shipped double, one contract run against every implementation, one data contract for both front ends). What may vary is the mechanism: py's structural `Protocol` verified by `ty` (`src/py_launch_blueprint/core/ports.py:40`, `pyproject.toml:253`), ts's injected `CliDeps` function record (`src/router.ts:31`, D-019(5)), and Rust's nominal trait are three ecosystem-appropriate realizations. No shared low-level value is recommended: neither an explicit owner requirement nor evidence of the same tradeoff in all three ecosystems supports one. All five engines agree on this framing.

**Essential behaviors and observable acceptance criteria** (each was executed in the fixture under `## Empirical check`):

1. The use case depends on a name, not a transport. *Observable:* `src/service.rs` imports only `contract` and `ports`; no HTTP, filesystem or framework type.
2. Production wiring happens in exactly one place. *Observable:* `HttpProjectsPort::new` is called only in `src/composition.rs` (`production_service`).
3. The substitute is a public, shipped library item. *Observable:* `tests/port_contract.rs` uses `seam_fixture::InMemoryProjectsPort` without `cfg(test)` or a feature.
4. Every implementation is mechanically proven to satisfy the contract before code runs. *Observable:* an adapter that omits `get` fails `cargo check` with `error[E0046]: not all trait items implemented, missing: get` (`review/evidence/compile-fail-reasons.log`); the `compile_fail` doctest in `src/lib.rs` guards it.
5. One assertion set runs against every implementation. *Observable:* `assert_projects_port_contract` exists once; `cargo test` reports it three times — `in_memory_adapter_satisfies_contract`, `erased_in_memory_adapter_satisfies_contract`, `http_adapter_against_live_listener_satisfies_contract`.
6. The web front end serializes the types the CLI renders. *Observable:* the handler in `src/web.rs` returns `Json<Vec<Project>>` and `Json<Option<Project>>` from `contract.rs`; no mirror struct exists; a raw HTTP GET against a bound listener decodes into the library's `Vec<Project>` and equals the CLI's output (`review/evidence/macos-stable-1.98.0-cargo-test.log`, `cargo run -- --in-memory alpha`).

**Is the shared pattern still appropriate in Rust?** Yes, and cheaper than in either source: py needs a `Protocol` plus a checker to prove satisfaction, ts has nothing to prove because structural typing is a language default, and Rust proves satisfaction nominally with the `impl` item at `cargo check` with no tool in the loop. The port trait also gives ts's missing pieces (a shipped fake, a cross-adapter suite) a natural home.

**Architecture alternatives compared** (before any crate was weighed):

| Alternative | Shape | Verdict and reason |
|---|---|---|
| A. No seam | service calls the concrete adapter inline | Rejected: fails criteria 1, 3, 5. |
| B. Injected function values (ts's `CliDeps`) | `Box<dyn Fn(..) -> .. + Send + Sync>` fields | Rejected as the primary seam: each field needs its own boxing and bounds, related operations lose the invariant that they share one backend, a stateful fake has nowhere to live, and the F121 suite would need one contract per function. Codex, opus, openai and perplexity independently reach this verdict. |
| C. Trait port, generic bound only | `ProjectsService<P: ProjectsPort>` with no trait object anywhere | Correct for library consumers, but `<P>` propagates into every web handler signature and CLI command type and the binary carries one instantiation per adapter. Openai's recommendation; its stated reason is to avoid pre-empting R05 — answered by the `async-trait` route (design E keeps generic consumers untouched). |
| D. Trait port, trait object only | `ProjectsService { port: Arc<dyn ProjectsPort> }` | Codex's and gemini's recommendation; the `jj`/`sccache` shape. One instantiation, one state type. Costs library consumers a vtable call they cannot opt out of. Ranked first runner-up. |
| **E. Trait port, generic service, erased at the composition root** | `ProjectsService<P>` plus blanket `impl ProjectsPort for Arc<T>`; the root builds `ProjectsService<Arc<dyn ProjectsPort>>` | **Chosen.** Library consumers get C's monomorphized service; CLI and web share D's single erased state type; the trait is declared dyn compatible once, which the Rust API Guidelines (C-OBJECT) say is the load-bearing decision. Opus's and (in prose) perplexity's recommendation; executed on 1.96.0 and 1.98.x on two OSes. |
| F. DI container (`shaku`, `dill`, `nject`, `teloc`) | a crate resolves the object graph | Rejected by all five engines: five ports and one root is not the problem containers solve; a wiring error becomes a registration/resolution-time failure where Rust has a compile error; adoption is negligible (figures below). |

**Why the chosen design preserves each principle.** The trait carries the contract (1); `production_service` is the root (2); `InMemoryProjectsPort` is an ordinary `pub struct` in the library (3); `impl ProjectsPort for X` is the verification and `compile_fail` doctests guard both it and dyn compatibility (4); one generic contract function is called once per adapter (5); one `serde`-derived struct is what both front ends emit (6). The vtable indirection at the erased boundary sits on a path that performs I/O; no benchmark is offered because none would be honest at this granularity (the prompt forbids inferring an absolute fastest option from unlike benchmarks). What is measurable — dependency count, MSRV of the tree, clean-build time, instantiation count — is reported under `## Empirical check`.

**Dispatch and the `Send + Sync` placement.** `Send + Sync` are supertraits of the port (opus, codex, gemini; `rust-lang/crates.io` `pub trait GitHubClient: Send + Sync`, `mozilla/sccache` `pub trait Storage: Send + Sync`, `jj-vcs/jj` `pub trait Backend: Any + Send + Sync + Debug`). Openai's alternative — leave the port unbounded and bound at the web state — keeps a single-threaded adapter possible for library consumers; recorded as a variation to adopt if such a consumer ever appears, not chosen because every shipped adapter must be shareable by the erased web state anyway.

**Fake's interior mutability.** `std::sync::Mutex<Vec<Project>>` (opus, openai). `RwLock` (codex, gemini) is an equivalent std choice for a read-heavy fake; `&mut self` port methods (perplexity's sketch) are incompatible with sharing one adapter behind `Arc<dyn ProjectsPort>` and are not adopted. A poisoned lock maps to the port's error vocabulary (`PortError::Unavailable`), never a panic. Under an async R05 the guard must not be held across an `.await`; the fake's mutation completes while the guard is held.

**Suite mechanism.** A generic function over the port bound is what F121 needs because the thing that varies is a *type*; `rstest`/`test-case` vary *values* and `jj` uses `test-case` only because its backend selector is a value (`TestRepoBackend` enum). Openai's and gemini's `macro_rules!` suite is an acceptable variant when per-case test names are wanted; the generic function is chosen because it is plain Rust with no macro to read. Failure messages carry the adapter `label`, so a shared assertion still names which adapter broke.

**Cross-repo adjudication** (changes to py and ts are a follow-on project; this is their rationale): F013 in ts is accidental drift, not a justified difference (no `D-0nn`; nothing in TypeScript prevents exporting an in-memory factory) — proposed follow-on: promote one per-test fake in `tests/*.test.ts` into an exported factory. F121 in ts is contingent drift that follows F013. F018 in ts is an absent capability (no web tier), carried once on R69, not drift. F001/F002/F011 are justified ecosystem differences (`harmonize: no`). ts's D-019(5) ("injected `fetchImpl` as the only HTTP transport seam") remains defensible in a structurally typed language and gives R48 the same conclusion this decision gives: **the recommended seam needs no HTTP-mocking crate** because the transport sits behind an injected port.

**Baseline review.** The six rows are `DIVERGENT` research rows, so the lines the raws labelled `BASELINE-REVIEW` for F001/F002/F013/F018/F121 are this decision itself, not challenges to a retained REUSE/ADOPT baseline. One finding changes ledger wording and another item's scope and is carried in the required form:

BASELINE-REVIEW: F011 — an adapter is mechanically proven to satisfy its port before the code ships — restate the row's mechanism as nominal satisfaction enforced by `rustc` at `cargo check` (`impl Port for Adapter`), not "structural satisfaction verified by the type checker", and record that Rust has no separate verification tool to select, so the acceptance criterion becomes a compile-failure demonstration; affected items: R01 (this row) and R30 `type-check-gate`, which must not scope adapter-port conformance into a checker gate — evidence: py's row rests on `pyproject.toml:253` running `ty` over a structural `Protocol`; the Rust Reference defines trait implementation as an explicit `impl` item and dyn compatibility as a compiler-checked property (`https://doc.rust-lang.org/reference/items/traits.html`, 2026-09-05); this run observed `error[E0046]: not all trait items implemented, missing: get` and `error[E0038]: the trait NotDynCompatible is not dyn compatible` from `cargo check` on rustc 1.98.0 (`review/evidence/compile-fail-reasons.log`), and the opus report observed the same E0038 for a native `async fn` port.

**Reference implementations** (read at source by the opus report, 2026-09-05; figures from `https://api.github.com/repos/<o>/<r>`):

- `rust-lang/crates.io` (3,690 stars, `archived: false`, `pushed_at` 2026-09-05; edition 2024, `MIT OR Apache-2.0`, a Cargo workspace with web service, workers and library crates — the only surveyed project with this template's shape): `src/app.rs:43` `pub github: Arc<dyn GitHubClient>`, `:54` `Box<dyn OidcKeyStore>`, `:259` `pub struct AppState(pub Arc<App>)`; `crates/crates_io_github/src/lib.rs:74-76` `#[cfg_attr(feature = "mock", mockall::automock)] pub trait GitHubClient: Send + Sync`, `:170` `RealGitHubClient`, `:249` its `impl`; `crates/crates_io_github/Cargo.toml` `[features] mock = ["dep:mockall"]`, `mockall = { version = "=0.15.0", optional = true }`, `async-trait = "=0.1.92"`, `serde = { version = "=1.0.229", features = ["derive"] }`.
- `jj-vcs/jj` (31,409 stars, pushed 2026-09-05): `lib/src/backend.rs:746` `pub trait Backend: Any + Send + Sync + Debug`; `lib/src/store.rs:58` `backend: Box<dyn Backend>`; `lib/testutils/src/test_backend.rs` a first-class fake shipped in a library crate; `lib/tests/test_commit_builder.rs:72-74` one test body run against two backends.
- `mozilla/sccache` (7,648 stars, pushed 2026-09-03): `src/cache/cache.rs:75` `pub trait Storage: Send + Sync`.
- Tower's generic `Service` plus `BoxService` erasure (openai, `https://docs.rs/tower/latest/tower/util/struct.BoxService.html`, 2026-09-09) is the same "generic first, erase at the boundary" pattern; axum's `State` (`https://docs.rs/axum/latest/axum/extract/struct.State.html`, 2026-09-09) documents that a web adapter holds a concrete `Clone` state, typically `Arc`-shared, with no container.

**Members — landscape, gates and figures.** Landscape bins (union of the five reports): *built-in/first-party* — `trait`, `dyn Trait`, generic bounds, `impl Trait`, `Arc`/`Box`, `std::sync::Mutex`/`RwLock`, Cargo features, the `#[test]` harness, `rust-lang/impl-trait-utils` (`trait-variant` 0.1.3, no `dyn` support yet — watch, do not adopt); *established standard* — `serde`, `serde_json`, `async-trait`, `mockall`, `rstest`, `test-case`, `parking_lot`; *up-and-comer* — `shaku`, `dill`, `nject`, `teloc`, `faux`, `hexser`. Authorities: the Rust Reference (dyn compatibility rules), the Rust Book ch. 10 and ch. 18 (monomorphization versus vtable), the Rust API Guidelines C-OBJECT, the 2023 `async fn` in traits announcement, the 2025 State of Rust survey (7,156 responses; compile-time cost remains a top productivity limiter, the reason a zero-dependency seam is preferred), maintainers' own docs and manifests, and the Rust project's own `crates.io` source.

Fitness gates for the language-feature members (F001, F002, F011, F013, F121) are `inapplicable` — no crate exists to fail a licence, MSRV, advisory, platform, feature or build-cost gate; for the record the features predate Rust 1.0, use safe code only, and were executed on both target OSes at 1.96.0 and 1.98.x. Crate members and measured alternatives (crates.io `crate.recent_downloads` / `crate.downloads`, newest non-yanked `num`/`created_at`, GitHub `stargazers_count`/`archived`/`pushed_at`, search-API open issues; all from the codex and opus reports, retrieved 2026-09-05; RustSec `packages/<name>.html` returned HTTP 404 for every crate below, which RustSec uses for "no advisory"; the fixture's `cargo audit` result below is the executed check):

| Crate | Role | 90-day dl | All-time dl | Newest | Stars / pushed | Open issues | Licence | Declared MSRV | Maintenance |
|---|---|---:|---:|---|---|---:|---|---|---|
| `serde` | member (F018) | 295,688,106 | 1,355,199,652 | 1.0.229 (2026-07-18) | 10,800 / 2026-08-25 | 318 | MIT OR Apache-2.0 | 1.56 | active (120,056 reverse deps) |
| `serde_json` | JSON boundary (R66 decides the serializer) | 299,793,085 | 1,259,356,567 | 1.0.151 (2026-07-20) | 5,635 / 2026-08-08 | 190 | MIT OR Apache-2.0 | 1.71 | active |
| `async-trait` | conditional on async R05 | not captured | 515,681,721 (gemini snippet, 2026-09-09) | 0.1.92 (2026-08-08, opus) | ~2.2k / — (gemini) | 9 (gemini) | MIT OR Apache-2.0 | 1.56 (gemini) | active; figures partly uncaptured, see `## Engines` |
| `mockall` | optional `mock` feature (R48) | 27,607,997 | 164,279,034 | 0.15.0 (2026-06-28) | 1,837 / 2026-09-02 | 51 | MIT OR Apache-2.0 | 1.77.0 | active (median first response 1.19 days, 0 of 10 unanswered) |
| `rstest` | suite runner-up | 26,060,034 | 116,676,450 | 0.26.1 (2025-07-27) | 1,579 / 2026-03-26 | 68 | MIT OR Apache-2.0 | 1.70.0 | stable-quiet (median 0.51 days, 2 of 10 unanswered) |
| `test-case` | `jj`'s mechanism | 11,318,661 | 61,249,956 | 3.3.1 (2023-11-17) | 633 / 2024-05-12 | 25 | MIT | 1.63 | at-risk (no push through two years of releases) |
| `parking_lot` | lock alternative | 209,536,781 | 1,046,524,439 | 0.12.5 (2025-10-03) | 3,402 / 2026-08-28 | 62 | MIT OR Apache-2.0 | 1.71 | stable-quiet; uses `unsafe` by construction |
| `faux` | struct mocking | 115,464 | 1,867,608 | 0.1.13 (2025-09-27) | 484 / 2025-09-27 | 14 | MIT | 1.65 | at-risk; "liberal use of unsafe" per its docs |
| `shaku` | DI container | 34,716 | 240,829 | 0.6.3 (2026-08-02) | 609 / 2026-08-09 | 6 | MIT/Apache-2.0 | 1.88 | active; 24 reverse deps |
| `dill` | DI container | 5,580 | 68,979 | 0.17.0 (2026-08-30) | 33 / 2026-08-30 | 2 | MIT OR Apache-2.0 | none | active; 0 reverse deps |
| `nject` | DI container | 4,824 | 27,660 | 0.5.1 (2026-06-29) | 90 / 2026-06-29 | 2 | MIT | 1.85 | active; 0 reverse deps |
| `teloc` | DI container | 200 | 13,144 | 0.2.0 (2021-11-25) | 170 / 2024-08-03 | 14 | MIT OR Apache-2.0 | none | at-risk |
| `trait-variant` | async variant generator | 3,416,048 | 12,816,596 | 0.1.3 (2026-07-22) | 134 / 2026-07-22 | 9 | MIT OR Apache-2.0 | 1.75 | active; no `dyn` support shipped |

*Excluded by gate.* `shaku` — declared MSRV 1.88 is inside the 1.96 floor today but tracks recent compilers closely enough to push a patch release past the floor between minor releases, a policy concern; excluded decisively on fit. `teloc` — no `rust-version`, predates edition 2024 (gates 2 and 6). `nject`, `faux`, `test-case` — `MIT` alone is compatible with distributing an `MIT OR Apache-2.0` project but lacks Apache-2.0's patent grant, the owner's stated reason for the dual licence (`docs/port/PARAMETERS.md`); each is also excluded on fit or maintenance. `parking_lot`, `rstest`, `mockall` pass every gate and are excluded from the base stack on fit only. `serde` fails no gate: licence identical to the template's; MSRV 1.56; default `std`, `derive` enabled explicitly, no async-runtime coupling; its own CI covers `ubuntu-latest` and `windows-latest` but not macOS — covered here empirically on macOS 26.4 aarch64 at 1.96.0 and 1.98.0; build cost is one proc-macro tree (`serde_derive`, `syn` 3.0.5, `quote`, `proc-macro2`), measured by the opus probe at 4.41 s wall / 7.62 s user CPU for a clean serde-only test build on macOS aarch64; `unsafe` posture reported from documentation, not a line-by-line audit.

**Compatibility.** Proven three ways: (1) all members compiled and tested together in one package (`review/empirical/seam_fixture`) on rustc 1.96.0 and 1.98.0 (macOS aarch64) and 1.96.0 and 1.98.1 (Ubuntu aarch64), with `serde` 1.0.229 and `serde_json` 1.0.151 resolved in one lockfile whose highest declared `rust-version` is 1.80 (`review/evidence/dependency-msrv-license.log`); (2) `rust-lang/crates.io` combines every member in production under edition 2024 and `MIT OR Apache-2.0`; (3) the opus probe resolved `serde` 1.0.229 with `mockall` 0.15.0 and, separately, `async-trait` 0.1.92 without conflict (`mockall` adds a second `syn` major, a build-cost fact, not a conflict).

**Migration implications** (file-level, against the core library crate; the crate's name and workspace placement are R02's decision):

- `src/core/ports.rs` (new) — `pub trait ProjectsPort: Send + Sync`, the port error type (vocabulary R67's, absence shape R03's), the blanket `Arc<T>` impl; under an async R05, `#[async_trait]`.
- `src/core/adapters/http.rs` (new) — the production adapter and its `impl`; the HTTP client and runtime it wraps are other items' decisions.
- `src/core/adapters/in_memory.rs` (new) — `pub struct InMemoryProjectsPort` over `std::sync::Mutex<Vec<Project>>`, public and unconditional.
- `src/core/service.rs` (new) — `pub struct ProjectsService<P: ProjectsPort>` and `pub type ErasedProjectsService`.
- `src/composition.rs` (new) — `build_projects_service` and `production_service`; the only constructor call site of the production adapter.
- `src/core/contract.rs` (new) — the `serde`-derived request and response types; `src/core/testing.rs` (new) — `assert_projects_port_contract`, exported so downstream template users can run it against their own adapters.
- `src/lib.rs` (changed) — re-export the port, service, erased alias, both adapters, the composition functions and the contract function (the public-surface policy is R04's).
- `tests/projects_port_contract.rs` (new) — one `#[test]` per adapter plus the web-state bounds assertion; `tests/web_request_path.rs` (new, once R69 ships the web tier) — a real request against a bound listener decoding into the library's type.
- `Cargo.toml` (changed) — `serde = { version = "1.0.229", features = ["derive"] }` in the core library (non-optional, so the CLI keeps the contract when the web feature is off); optionally `[features] mock = ["dep:mockall"]`; under an async R05 `async-trait = "0.1.92"`.
- CLI entry point (changed) — calls `production_service(..)` once; no command constructs an adapter. Web feature (if R69 ships it) — its state holds the value `production_service(..)` returns; handlers return the library's types and declare none of their own.

**Validation strategy.** *Executed in this run:* everything under `## Empirical check`. *Proposed for the template's CI (wiring is R11's, tiers are R32's):* `cargo test --workspace --locked` on `ubuntu-latest` and `macos-latest`; a `cargo check` leg on the declared `rust-version`; `cargo clippy --workspace --all-targets -- -D warnings`; `cargo audit` on the lockfile; `cargo test --features mock` if the optional feature is adopted; a check that `assert_projects_port_contract` has one call site per adapter and that the production adapter's constructor appears exactly once outside its module; a snapshot of the serialized contract (tool is R33's).

**Confidence.** High on the seam mechanism, the composition root, the fake, the verification answer and the suite (normative reference plus three current projects read at source plus execution at the MSRV floor on both OSes). Medium on sharing `serde` structs rather than translating at the boundary until R69 defines the web surface, and on the exact `serde`/`serde_json` patch pins, which must be re-resolved when the template's lockfile is created.

**Sources.** Language and project authorities, retrieved 2026-09-05 (opus, codex) and 2026-09-09 (openai): `https://doc.rust-lang.org/reference/items/traits.html`; `https://doc.rust-lang.org/stable/reference/types/trait-object.html`; `https://doc.rust-lang.org/std/keyword.dyn.html`; `https://doc.rust-lang.org/book/ch18-02-trait-objects.html`; `https://doc.rust-lang.org/book/ch10-01-syntax.html`; `https://rust-lang.github.io/api-guidelines/flexibility.html`; `https://blog.rust-lang.org/2023/12/21/async-fn-rpit-in-traits/`; `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`; `https://static.rust-lang.org/dist/channel-rust-stable.toml` (stable 1.98.1 on 2026-09-05, so the floor is 1.96); `https://serde.rs/`, `https://serde.rs/data-model.html`; `https://docs.rs/tower/latest/tower/util/struct.BoxService.html`; `https://docs.rs/axum/latest/axum/extract/struct.State.html`; `https://docs.rs/mockall/latest/mockall/`; `https://docs.rs/shaku/latest/shaku/`; `https://docs.rs/trait-variant/latest/trait_variant/`. Practice evidence read at source, 2026-09-05: `https://raw.githubusercontent.com/rust-lang/crates.io/main/src/app.rs`, `.../src/worker/environment.rs`, `.../src/tests/util/test_app.rs`, `.../Cargo.toml`, `.../crates/crates_io_github/Cargo.toml`, `.../crates/crates_io_github/src/lib.rs`, `.../crates/crates_io_team_repo/src/lib.rs`; `https://raw.githubusercontent.com/jj-vcs/jj/main/lib/src/backend.rs`, `.../lib/src/store.rs`, `.../lib/testutils/src/lib.rs`, `.../lib/tests/test_commit_builder.rs`; `https://raw.githubusercontent.com/mozilla/sccache/main/src/cache/cache.rs`; `https://raw.githubusercontent.com/serde-rs/serde/master/.github/workflows/ci.yml`; `https://raw.githubusercontent.com/asomers/mockall/master/.github/workflows/ci.yml`. Figure endpoints, 2026-09-05: `https://crates.io/api/v1/crates/<name>` (+`/versions`, `/reverse_dependencies`) for `serde`, `serde_json`, `mockall`, `rstest`, `test-case`, `parking_lot`, `faux`, `shaku`, `dill`, `nject`, `teloc`, `async-trait`, `trait-variant`; `https://api.github.com/repos/<o>/<r>` and `https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for the matching repositories; `https://rustsec.org/packages/<name>.html` (HTTP 404 for all of the above; `lock_api` HTTP 200 with informational `RUSTSEC-2020-0070`, excluded by `parking_lot` 0.12.5's `^0.4.14` requirement). Repository context: `docs/port/DIVERGENCE-ANALYSIS.md` (R01 rows, analyst notes), `docs/port/COMMONALITY.md` (F001, F002, F011, F013, F018, F121), `docs/port/PARAMETERS.md`, `docs/port/areas/workspace-architecture.md`, `docs/port/areas/testing-coverage.md`, `ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md` D-019(5).

re-verify: when R05 (sync-async-execution-model) publishes, at the next msrv-policy floor advance past 1.96, or by 2027-03-01, whichever comes first

## Parameters

- owns http-transport-injection-seam = trait-object port erased at the composition root: the driven-I/O contract is a dyn-compatible Rust trait (pub trait ProjectsPort: Send + Sync; no async fn, generic methods, associated consts or non-receiver Self) with a blanket impl for Arc<T>; the use case is generic over it (ProjectsService<P: ProjectsPort>); the composition root (plain functions, no DI container) erases the production adapter to Arc<dyn ProjectsPort> and hands the single ProjectsService<Arc<dyn ProjectsPort>> to the CLI and the web layer; fakes and test doubles are injected as any ProjectsPort implementor (the shipped InMemoryProjectsPort), never as injected function values and never by patching a transport; under an async R05 the trait keeps dyn compatibility with async-trait 0.1.92
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

Consumed parameters: none (`- consumes:` is empty). The fixed values were exercised, not assumed: the fixture declares `edition = "2024"`, `rust-version = "1.96"` (stable 1.98.1 minus two on 2026-09-05) and `license = "MIT OR Apache-2.0"`, and ran on both target operating systems.

No `CONFLICT:` line is raised by this decision. The codex report (`raw/codex.md`, `### Parameters`) wrote, verbatim:

> CONFLICT: R05 sync-async execution model — native `async fn` in traits cannot be dynamically dispatched — R05 must choose an object-safe async representation or coordinate replacement of the object boundary.

This is not a registry conflict under `research/RUNBOOK.md` §4: R05 registers no parameter and the line names no registered value to change, so nothing is reopened. The coupling it describes is real and is resolved inside this decision: the port stays dyn compatible under either R05 outcome (sync: unchanged; async: `#[async_trait]`, the route `rust-lang/crates.io` takes and the opus report executed). R05's `- related` coupling is recorded in the prompt and is the first re-verify trigger.

Inputs to other items, not conflicts: R48 receives "the recommended seam needs no HTTP-mocking crate" for F120 and the optional `mock` feature shape; R30 receives the `BASELINE-REVIEW: F011` finding above; R69 receives that the web state type is `ProjectsService<Arc<dyn ProjectsPort>>` (`Clone + Send + Sync + 'static`) and that handlers return the library's `serde` types; R32 receives the three-call-site contract-suite shape.

## Empirical check

**Fixture.** `review/empirical/seam_fixture/` — a `cargo new --lib` package (`edition = "2024"`, `rust-version = "1.96"`, `license = "MIT OR Apache-2.0"`) implementing the recommended seam end to end for one port: `src/ports.rs` (trait + blanket `Arc<T>` impl), `src/service.rs` (generic service + erased alias), `src/composition.rs` (root), `src/adapters/in_memory.rs` (shipped fake, `std::sync::Mutex`), `src/adapters/http.rs` (the "real" adapter: a fixture-only `std::net::TcpStream` HTTP/1.1 GET, so no HTTP-client crate is selected), `src/contract.rs` (`serde`-derived `Project`, `ProjectQuery`), `src/testing.rs` (generic contract suite), `src/web.rs` (thin web adapter; `axum` 0.8 is the fixture's stand-in framework — the framework is R69's decision — and the port is called synchronously from the handler, so the fixture does not decide R05), `src/main.rs` (`seam-cli`, the CLI front end printing the same `Project` values as JSON). Tests: `tests/port_contract.rs` (the suite against the in-memory fake, the fake behind `Arc<dyn ProjectsPort>`, and `HttpProjectsPort` against a live listener served by the fixture's own web adapter; static-versus-erased equality; web-state bounds and cross-thread use), `tests/web_request_path.rs` (a raw HTTP GET to `127.0.0.1:<port>/projects?q=alpha` and `/project?id=..` decoded into the library's `Vec<Project>` / `Option<Project>`), `tests/contract_round_trip.rs` (`serde_json` round trip and field names), and four doctests in `src/lib.rs` (two positive twins, two `compile_fail` negatives: an adapter omitting `get`, a port with a generic method erased to `Arc<dyn _>`). `Cargo.lock` was generated once by cargo 1.98.0 with the edition-2024 MSRV-aware resolver ("Locking 52 packages to latest Rust 1.96 compatible versions"; it chose `matchit` 0.8.4 over 0.8.6) and every leg ran `--locked`. Resolved members: `serde` 1.0.229, `serde_json` 1.0.151, `axum` 0.8.9, `tokio` 1.53.1, `hyper` 1.11.1; the highest declared `rust-version` in the tree is 1.80.

**Toolchains and OS.**

| Leg | OS | `rustc -vV` release / host | cargo | Working directory |
|---|---|---|---|---|
| 1 | macOS 26.4, arm64 (host) | 1.98.0 (88d9e12ae 2026-08-18, Homebrew) / aarch64-apple-darwin | 1.98.0 | `research/runs/R01/2026-09-05T155123Z-52a17c034dad/review/empirical/seam_fixture` |
| 2 | macOS 26.4, arm64 (host) | 1.96.0 (ac68faa20 2026-05-25) / aarch64-apple-darwin | 1.96.0 | same |
| 3 | Ubuntu 25.10, aarch64, kernel 6.17.0-41-generic (Lima VM `ubuntu`) | 1.98.1 (48a229cea 2026-09-01) / aarch64-unknown-linux-gnu | 1.98.1 | `/home/stevemorin.guest/r01-seam-fixture` (VM-local copy; the host mount is read-only) |
| 4 | same VM | 1.96.0 (ac68faa20 2026-05-25) / aarch64-unknown-linux-gnu | 1.96.0 | same VM-local copy |

The VM is aarch64 while GitHub's `ubuntu-latest` runners are x86_64; the fixture has no architecture-specific code, but the x86_64 leg is not executed here. Leg 3's stable is 1.98.1 (rustup) versus the host's 1.98.0 (Homebrew); both are the current stable line.

**Commands and exit status** (full transcripts in `review/evidence/`):

| Leg | Command | Exit | Result | Log |
|---|---|---|---|---|
| 1 | `cargo clean && cargo test --locked && cargo run --locked --quiet -- --in-memory alpha` | 0 / 0 / 0 | 12 passed, 0 failed (2 + 5 + 1 integration, 2 doc, 2 compile-fail doc); clean build + test 23.96 s wall, 42.93 s user | `macos-stable-1.98.0-cargo-test.log` |
| 2 | `export PATH="$(rustup run 1.96.0 rustc --print sysroot)/bin:$PATH"; cargo clean && cargo test --locked && cargo run --locked --quiet -- --in-memory alpha` (`cargo +1.96.0` exits 101 on this host: Homebrew's cargo shadows rustup's `+toolchain` syntax, recorded in the log) | 0 / 0 / 0 | 12 passed, 0 failed; 20.41 s wall | `macos-msrv-1.96.0-cargo-test.log` |
| 3 | `limactl shell ubuntu -- bash -lc 'source $HOME/.cargo/env; rsync -a --exclude target/ <mount>/seam_fixture/ $HOME/r01-seam-fixture/; cd $HOME/r01-seam-fixture; cargo test --locked; cargo run --locked --quiet -- --in-memory alpha'` | 0 / 0 | 12 passed, 0 failed; 15.88 s wall | `linux-stable-1.98.1-cargo-test.log` |
| 4 | same VM copy: `cargo +1.96.0 clean && cargo +1.96.0 test --locked && cargo +1.96.0 run --locked --quiet -- --in-memory alpha` | 0 / 0 / 0 | 12 passed, 0 failed; 11.18 s wall | `linux-msrv-1.96.0-cargo-test.log` |
| gate | `cargo fmt --check`; `cargo clippy --locked --all-targets -- -D warnings` (leg 1 toolchain) | 0 / 0 | no warnings | `macos-stable-clippy-fmt.log` |
| gate | `cargo audit` (cargo-audit 0.22.1, advisory-db 1,243 advisories, 53 crate dependencies scanned) | 0 | no vulnerabilities reported | `cargo-audit.log` |
| gate | `cargo metadata --locked` name/version/rust-version/license table; `cargo tree --locked --edges normal` | 0 / 0 | highest declared MSRV 1.80 (`axum` 0.8.9); every licence is permissive (MIT, Apache-2.0, BSD-3-Clause, BSL-1.0, Unlicense, Unicode-3.0 and their combinations), none copyleft | `dependency-msrv-license.log` |
| gate | the two `compile_fail` bodies checked as a path-dependent scratch crate so the error codes are visible | 101 / 101 | `error[E0046]: not all trait items implemented, missing: get`; `error[E0038]: the trait NotDynCompatible is not dyn compatible` | `compile-fail-reasons.log` |

**Observed output** (leg 1, `cargo test --locked`, abridged to the test harness lines; `Compiling` lines removed):

```text
$ cargo test --locked
    Finished `test` profile [unoptimized + debuginfo] target(s) in 21.38s
     Running tests/contract_round_trip.rs (target/debug/deps/contract_round_trip-2e90e63b26e58fdc)
running 2 tests
test query_round_trips_including_the_absent_filter ... ok
test project_round_trips_and_keeps_its_field_names ... ok
test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/port_contract.rs (target/debug/deps/port_contract-019c9b83271b9511)
running 5 tests
test service_accepts_concrete_and_erased_ports ... ok
test erased_service_is_clonable_shared_state ... ok
test in_memory_adapter_satisfies_contract ... ok
test erased_in_memory_adapter_satisfies_contract ... ok
test http_adapter_against_live_listener_satisfies_contract ... ok
test result: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
     Running tests/web_request_path.rs (target/debug/deps/web_request_path-c9d6f1cf90d8976d)
running 1 test
test web_adapter_serves_the_shared_contract_over_a_live_listener ... ok
test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
   Doc-tests seam_fixture
running 2 tests
test src/lib.rs - (line 17) ... ok
test src/lib.rs - (line 44) ... ok
test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
running 2 tests
test src/lib.rs - (line 54) - compile fail ... ok
test src/lib.rs - (line 30) - compile fail ... ok
test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.05s
cargo test --locked  42.93s user 7.88s system 212% cpu 23.960 total
exit=0
$ cargo run --locked --quiet -- --in-memory alpha
[
  {
    "id": "1",
    "name": "alpha"
  },
  {
    "id": "3",
    "name": "alphabet"
  }
]
exit=0
```

The CLI output above is byte-for-byte the value `tests/web_request_path.rs` decodes from the HTTP body of `GET /projects?q=alpha` (both are the service's `search` result sorted by `id`), which is the F018 acceptance criterion. `lib.rs` and `main.rs` unit-test targets run 0 tests and are omitted from the excerpt; the four legs report identical test sets. Build trees were removed after the run (`cargo clean`; the VM copy deleted); the fixture keeps `Cargo.lock` and a `.gitignore` for `/target`.

**What the check does not prove.** No x86_64 execution; no async port (the R05-conditional `async-trait` route rests on the opus report's executed observation, not on this fixture); no measurement of the vtable indirection (deliberately, see `### Principles and implementation`); `unsafe` posture of the dependency tree from documentation, not `cargo-geiger`.

## Engines

- codex `raw/codex.md` — gpt-5.6-terra (sha256 `2e63259d939bcbc2cbc73f6b888220594cd1c5c134970364da1a1f28477a3758`), bundle shape OK. Recommends `Arc<dyn Port + Send + Sync>` at the application boundary with generic helpers for tests, a plain factory, `RwLock<BTreeMap>` fake, `serde` 1.0.229 / `serde_json` 1.0.151, no `mockall`/`shaku`; executed a std-only 1.98.0 probe; raised one `BASELINE-REVIEW` (all six rows) and one `CONFLICT: R05` line.
- opus `raw/opus.md` — claude-opus-5[1m] (sha256 `7c6608dd410523340051e9b1942b99921b2c09c1002c0b81e2185dfcb377c4fc`), bundle shape OK. Recommends design E (generic service, blanket `Arc<T>` impl, erased at the root), `Mutex<Vec>` fake, generic contract function, `serde` 1.0.229, optional `mock` feature, `async-trait` 0.1.92 only under an async R05; executed 5/5 tests on 1.96.0, 1.97.1 and 1.98.0 (macOS) plus the E0038 negative; raised `BASELINE-REVIEW: F011`; no `CONFLICT`.
- doxa (one engine, three provider bodies from operation `research-20260909-001249-fc1fbad6f52f4f42`; `raw/doxa.normalized.md` is the same three bodies regrouped per field):
  - `raw/doxa-openai.normalized.md` — OpenAI gpt-5.6-sol, shape OK. Recommends generic-only dispatch (`ProjectsService<R>`, no `dyn` in the baseline), named live type aliases, `Arc<Mutex>` fake, `macro_rules!` suite, `serde` 1.0.229 / `serde_json` 1.0.151, nothing else; four `BASELINE-REVIEW` lines (F001, F011, F018, F121); `CONFLICT: none`. Its own ledger records every crates.io/GitHub/RustSec figure as "not captured; not guessed".
  - `raw/doxa-gemini.normalized.md` — Gemini deep-research-preview-04-2026, shape OK. Recommends `Arc<dyn Trait>` manual DI, `RwLock` fake, `macro_rules!` suite, `serde`, and `async-trait` as a base member while assuming `sync-async-execution-model = async`, which the prompt places out of scope; values a parameter named `port-seam-type` instead of the owned `http-transport-injection-seam`; cites `async-trait` 0.1.89 (superseded by 0.1.92) and serde at 10.7k stars; most inline citations are Vertex redirect URLs whose resolved list is at the foot of the file.
  - `raw/doxa-perplexity.normalized.md` — Perplexity sonar-deep-research, shape FAIL (recorded in `doxa/normalization.json`): the model stopped inside its fifth member "Axum Web Adapter Layer" after two fields and the top-level `Compatibility`, `Parameters`, `Migration implications`, `Validation strategy` and `Confidence & re-verify trigger` fields are absent. What it contains agrees with the decision: trait port, generics inside the library, trait objects at the CLI/web boundaries, shipped in-memory adapter, generic contract function, `serde` DTOs, no `mockall` for F011/F121, `hexser` as an up-and-comer not adopted; its fake sketch uses `&mut self` methods, which this decision does not adopt. It carries no crate figures.

**Disagreements and what settled them.**

1. *Dispatch shape* — dyn-only (codex, gemini) versus generic-only (openai) versus generic-with-erasure-at-the-root (opus, perplexity). Settled for design E by executed evidence (opus's probe at three toolchains; this fixture at two toolchains on two OSes, including the `service_accepts_concrete_and_erased_ports` equality) and by practice (`crates.io` `Arc<dyn GitHubClient>` in `App`/`AppState`, `jj` `Box<dyn Backend>`, `sccache`); design E gives openai's generic consumers and codex's/gemini's single web state type at once. Openai's core objection — that `dyn` pre-empts R05 — is answered by the executed `async-trait` route, not dismissed.
2. *`Send + Sync` placement* — supertraits (codex, opus, gemini, all three surveyed projects) versus bounds at the web state only (openai). Supertraits chosen; openai's variation recorded for a single-threaded library consumer, none of which exists in the template.
3. *R05 coupling* — codex's `CONFLICT`, opus's conditional `async-trait`, openai's "avoid `dyn` so nothing is pre-empted", gemini's "assume async". Settled by opus's executed observation (native `async fn` port → E0038; the same trait under `#[async_trait]` compiles and erases) and by `crates.io`'s `async-trait = "=0.1.92"` pin; codex's line is reproduced under `## Parameters` and adjudicated as not a registry conflict; gemini's assumption is rejected as out of scope.
4. *Fake's interior mutability* — `Mutex` (opus, openai) versus `RwLock` (codex, gemini) versus `&mut self` (perplexity). `Mutex` chosen as the simplest std primitive that keeps the fake `Send + Sync`; `RwLock` is an equivalent variant; `&mut self` is incompatible with sharing behind `Arc<dyn ProjectsPort>`.
5. *Suite mechanism* — generic function (codex, opus, perplexity) versus `macro_rules!` (openai, gemini). Generic function chosen and executed (three call sites, one body); the macro form is an acceptable variant for per-case names.
6. *Web framework as a bundle member* — gemini and perplexity name `axum`; codex, opus and openai defer to R69. Deferred to R69; `axum` 0.8.9 appears in the fixture only as the stand-in that proves the erased state bounds and the shared-type response over a live listener.
7. *`mockall`* — every engine keeps it out of the base stack; opus and openai differ only on whether to pre-wire an optional `mock` feature. Recorded as optional; selection is R48's.
8. *Crate figures* — openai captured none, gemini's are partly stale, perplexity has none; codex's and opus's 2026-09-05 figures agree with each other where they overlap (`serde`, `serde_json`, `mockall`, `shaku`) and are the figures used. `async-trait`'s figures remain partly uncaptured (only version/date from opus and an all-time download count from gemini's snippet); it is a conditional member, so this gap does not affect the base stack.

**Uncertainty and coverage.** Every required top-level field and every member field is supported by at least the codex, opus and openai reports plus the fixture; Perplexity's missing fields and truncated fifth member leave **no field or member unsupported**, and no supplementary Perplexity run is needed for this decision. Remaining uncertainty: no x86_64 execution (the VM is aarch64); `unsafe` posture of `serde`/`serde_json` and the fixture's `axum`/`tokio` tree from documentation only; RustSec clearance rests on `cargo audit` of the fixture lockfile because the per-package RustSec pages returned 404 for every engine; the F018 shared-struct choice is medium confidence until R69 defines the web surface.
