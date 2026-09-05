# R01 — ports-and-adapters seam (bundle) — raw report

Actor: `research-opus-2026-09-05T155123Z-52a17c034dad`. Model: `claude-opus-5[1m]`.
Item kind: `bundle`. Tier: deep. Retrieval date for every figure and claim below: **2026-09-05**.

Toolchain facts this report is measured against, retrieved 2026-09-05:
current Rust stable is **1.98.1** (`version = "1.98.1 (48a229cea 2026-09-01)"`, `date = "2026-09-03"`,
`https://static.rust-lang.org/dist/channel-rust-stable.toml`), so the owner-fixed
`msrv-policy` ("stable minus 2 minor versions") puts this template's declared floor at
**1.96**. Every executed check below was run on macOS 15 / aarch64 (`darwin 25.4.0`) with
rustc 1.96.0, 1.97.1 and 1.98.0.

### Landscape

**Step 1 — the category and its three bins.** The category this item decides is *the
mechanism a Rust program uses to name its driven-I/O boundary, substitute an
implementation of it, and prove the substitute behaves like the real one.* In Rust this is
not a library category at all in its core; it is a language-feature category with a thin
ring of optional tooling around it.

| Bin | Candidates found |
|---|---|
| Built-in or first-party toolchain | `trait` declarations; `dyn Trait` trait objects; generic type parameters with trait bounds; `impl Trait`; `Arc`/`Box` smart pointers; `std::sync::Mutex` / `RwLock` for interior mutability behind `&self`; Cargo optional dependencies and features; the built-in `#[test]` harness and `tests/` integration targets; `rust-lang/impl-trait-utils` (`trait-variant`), published by the rust-lang GitHub organization |
| Established industry standard | `serde` (data contract); `mockall` (mock generation from a trait); `rstest` (fixture and case parametrization); `test-case` (case parametrization); `async-trait` (boxed-future desugaring that restores dyn compatibility for async ports); `parking_lot` (alternative locks) |
| Up-and-comer | `faux` (mocking without a trait); dependency-injection containers `shaku`, `dill`, `nject`; `trait-variant`'s not-yet-shipped dynamic-dispatch utilities |

No candidate below was shortlisted from familiarity: each one appears in the map above and
each was then measured against the fitness gates before any download figure was weighed.

**Step 2 — authorities used, and why each is authoritative.**

| Source | Why it is authoritative |
|---|---|
| The Rust Reference, "Dyn compatibility" (`https://doc.rust-lang.org/reference/items/traits.html`) | The normative language definition maintained by the Rust project; it states the rules that decide whether a port trait can be used as `dyn Port` at all |
| The Rust Book, ch. 10 "Performance of Code Using Generics" and ch. 18 "Using Trait Objects to Abstract over Shared Behavior" (`https://doc.rust-lang.org/book/ch10-01-syntax.html`, `.../ch18-02-trait-objects.html`) | The Rust project's official teaching text; the source of the monomorphization-versus-vtable cost model this item's HIGH question turns on |
| Rust API Guidelines, C-OBJECT (`https://rust-lang.github.io/api-guidelines/flexibility.html`) | Published by the Rust libraries team as the design checklist for public Rust APIs; it is the guideline that tells a library author to decide object-versus-generic use *when the trait is declared* |
| Rust Blog, "Announcing `async fn` and return-position `impl Trait` in traits" (`https://blog.rust-lang.org/2023/12/21/async-fn-rpit-in-traits/`) | A Rust project release announcement; the primary record that `async fn` in traits shipped in 1.75 and that such traits are not dyn compatible |
| 2025 State of Rust Survey results (`https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`) | The project's tenth annual survey; it "ran for 30 days (from November 17th to December, 17th 2025) and collected 7156 responses", and reports that "resource usage (slow compile times and storage usage) is still up there" among productivity limiters — the evidence for preferring a zero-dependency seam in a template |
| Maintainers' own documentation on docs.rs and each crate's `Cargo.toml` | Primary statements of a crate's licence, MSRV, feature set and dependency tree |
| `rust-lang/crates.io` source tree | Not a blog post: the Rust project's own production web service, whose code is the strongest available statement of how the Rust project itself builds a driven-I/O port |

A single blog post was treated as a lead only. Everything numeric below comes from the
endpoints in the prompt's evidence table.

**Step 3 — practice evidence from well-regarded, current projects.** Three projects were
read at source, chosen because each is both prominent and freshly maintained (figures from
`https://api.github.com/repos/<o>/<r>`, 2026-09-05):

- **`rust-lang/crates.io`** — 3,690 stars, `archived: false`, `pushed_at: 2026-09-05T14:34:30Z`.
  Well regarded because it *is* the crate registry, operated by the Rust project. It is also
  the closest structural match to this template's target shape: an edition-2024,
  `MIT OR Apache-2.0` Cargo workspace with a web service, background workers and library
  crates. Its driven-I/O ports are trait objects held by a composition root:
  `src/app.rs:35` declares `pub struct App` with `pub github: Arc<dyn GitHubClient>` (`:43`)
  and `pub oidc_key_stores: HashMap<String, Box<dyn OidcKeyStore>>` (`:54`); `src/app.rs:259`
  wraps it as `pub struct AppState(pub Arc<App>);` for the web layer; `src/worker/environment.rs:40-44`
  gives the worker the same set (`Box<dyn TeamRepo + Send + Sync>`, `Arc<dyn GitHubApp>`,
  `Arc<dyn GitHubClient>`, `Box<dyn DocsRsClient>`). The port crate ships its own double:
  `crates/crates_io_github/src/lib.rs:74-76` reads
  `#[cfg_attr(feature = "mock", mockall::automock)]` above `pub trait GitHubClient: Send + Sync`,
  with `pub struct RealGitHubClient` at `:170` and `impl GitHubClient for RealGitHubClient` at
  `:249`; `crates/crates_io_github/Cargo.toml` declares `[features] mock = ["dep:mockall"]`
  and `mockall = { version = "=0.15.0", optional = true }` as a **normal, optional**
  dependency, not a dev-dependency. `crates/crates_io_team_repo/src/lib.rs:9-11` repeats the
  shape exactly. `src/tests/util/test_app.rs:17-28` then imports `MockGitHubClient`,
  `MockTeamRepo`, `MockDocsRsClient`, `MockGitHubApp` and `MockOidcKeyStore` from those
  library crates.
- **`jj-vcs/jj`** — 31,409 stars, `archived: false`, `pushed_at: 2026-09-05T13:17:53Z`; a
  widely adopted new-generation VCS. `lib/src/backend.rs:746` declares
  `pub trait Backend: Any + Send + Sync + Debug`; `lib/src/store.rs:58` holds it as
  `backend: Box<dyn Backend>` inside `Store`, exposed at `:88` as `pub fn backend(&self) -> &dyn Backend`.
  `lib/testutils/src/lib.rs:237-257` ships `pub enum TestRepoBackend { Git, Simple, Test }` whose
  `init_backend` returns `Result<Box<dyn Backend>, BackendInitError>`, and
  `lib/testutils/src/test_backend.rs` is a **first-class fake backend shipped in a library
  crate**, not an inline test fixture. `lib/tests/test_commit_builder.rs:72-74` then runs one
  test body against two adapters:
  `#[test_case(TestRepoBackend::Simple ; "simple backend")]` / `#[test_case(TestRepoBackend::Git ; "git backend")]`
  above `fn test_initial(backend: TestRepoBackend)`. This is py's `F121` contract suite,
  built in Rust, in a project of that standing.
- **`mozilla/sccache`** — 7,648 stars, `archived: false`, `pushed_at: 2026-09-03T08:06:22Z`;
  maintained by Mozilla. `src/cache/cache.rs:75` declares `pub trait Storage: Send + Sync`
  with several cache backends behind it.

**Step 4 — fit, not abstract best.** The template is one Cargo workspace producing a CLI, a
library and a web service. That triple is what discriminates the candidates: a library
consumer wants a monomorphized, inlinable service; a web handler wants one state type that
is `Clone + Send + Sync + 'static` and does not carry a type parameter into every handler
signature; a CLI wants a single binary without a duplicated instantiation per adapter.
`rust-lang/crates.io` is the only surveyed project with exactly this shape, and it resolves
the tension by erasing at the composition root. That observation, verified by compiling it
(see `### Validation strategy`), is what selects the recommendation below rather than any
download count.

### Principles and implementation

**The shared requirement.** Stated at the level the ledger and `docs/port/DIVERGENCE-ANALYSIS.md`
support: *the core use case must be exercisable against a substitutable implementation of
its driven I/O, that substitute must be a shipped, first-class artifact rather than a
per-test improvisation, and one contract must be asserted against every implementation.*

**Source and agreement level.** `docs/port/DIVERGENCE-ANALYSIS.md:70-76` classes R01 as
cause class **F** (genuine design disagreement) with `harmonize: partly — see sub-rows`, and
the sub-rows split cleanly:

| Row | Subject | `harmonize` | Agreement level this report assigns |
|---|---|---|---|
| F001 | port abstraction | no | policy/mechanism — Rust decides alone |
| F002 | composition-root shape | no | policy/mechanism — Rust decides alone |
| F011 | adapter-satisfies-port verification | no | policy/mechanism — Rust decides alone |
| F013 | shipped first-class fake | yes | **capability/standard — must agree across py, ts, rs** |
| F018 | web layer as a thin adapter over one contract | yes | **capability/standard**, but see the scope note |
| F121 | one suite run against every adapter | yes | **capability/standard — must agree** |

So what must agree is a *capability*: a shipped double plus one contract exercised against
every implementation. What may vary is the *mechanism*: py's `Protocol`, ts's interface of
injected functions, and Rust's `trait` are three ecosystem-appropriate realizations of the
same capability, and nothing in the evidence makes one of them correct for all three.

**Essential behaviors and observable acceptance criteria.**

1. A named type declares the driven-I/O contract; the use case depends only on that name.
   *Observable:* the use-case module's imports contain no HTTP, filesystem or database type.
2. Production wiring happens in exactly one place. *Observable:* exactly one function
   constructs the production adapter; grepping for that adapter's constructor outside it
   returns nothing.
3. A substitute implementation is a public, shipped item of the library, buildable by a
   downstream consumer. *Observable:* a consumer crate can `use <lib>::InMemoryProjectsRepository;`
   without enabling `cfg(test)`.
4. Every implementation is mechanically proven to satisfy the contract before the code runs.
   *Observable:* an adapter that drops a method fails `cargo check`, not a test.
5. One assertion set runs against both the real adapter and the substitute.
   *Observable:* the suite body exists once in the source; `cargo test` reports it twice, once
   per adapter, with distinguishable test names.
6. The web front end serializes the same types the CLI renders. *Observable:* the response
   type in the web module is the library's type, not a per-layer copy; no second
   `#[derive(Serialize)]` struct mirrors it field-for-field.

**Is the shared architectural pattern still appropriate in Rust?** Yes, and more cheaply
than in either source ecosystem. py needs a `Protocol` plus a type checker (`ty`) to prove
satisfaction; Rust proves it with `impl Port for Adapter`, which the compiler rejects if a
method is missing or mistyped — a `cargo check` failure, not a separate gate. ts needs no
verification step because structural typing is a language default, and the same is true in
Rust in the opposite direction: satisfaction is *nominal* and therefore explicit.

**Architectural alternatives compared before any library was chosen.**

| Alternative | What it is | Why it was or was not chosen |
|---|---|---|
| A. No seam: concrete adapter called directly | The service constructs and calls its I/O type inline | Fails criteria 1, 3 and 5 outright. Rejected. |
| B. Injected function values (ts's `CliDeps` shape) | Each I/O operation is a `Box<dyn Fn(..) -> ..>` field | Works, and is honest about ts's precedent — but Rust closures capturing environment need explicit `Box`/`Arc` and lifetimes on every field, related operations lose their shared invariant, and a fake is a struct of closures with no place to keep state. Loses to C on ergonomics with no compensating gain. Rejected as the primary seam; see *Ranked runner-up* under the F001 member. |
| C. Trait port, generic bound only | `struct Service<P: Port>`, no trait objects anywhere | Best codegen, and correct for library users. But the type parameter propagates: every web handler, every router builder and the CLI command type gain `<P>`, and the binary carries one instantiation per adapter. |
| D. Trait port, trait object only | `struct Service { port: Arc<dyn Port> }` | One instantiation, one state type, trivially `Clone` for a web layer. Costs a vtable indirection and, per the Rust Book, "prevents the compiler from choosing to inline a method's code, which in turn prevents some optimizations". |
| **E. Trait port, generic service, erased at the composition root** | `struct Service<P: Port>` **plus** a blanket `impl<T: Port + ?Sized> Port for Arc<T>`, so the root builds `Service<Arc<dyn Port>>` | **Chosen.** Library consumers keep C's monomorphized `Service<RealAdapter>`; the CLI and the web layer share exactly one erased instantiation, as `rust-lang/crates.io` does with `Arc<dyn GitHubClient>` in `App` and `AppState`. Compiled and tested in this run. |
| F. Dependency-injection container (`shaku`, `dill`, `nject`) | A crate resolves the object graph from registrations | Solves a problem this template does not have — five ports and one root. Adoption is negligible (see the F002 member) and it adds a runtime resolution failure mode where Rust currently has a compile error. Rejected. |

**How the chosen design preserves each principle, and where an ecosystem needs a different
one.** The trait carries the contract (criterion 1); a single `build_projects_service`
function is the root (criterion 2); the fake is an ordinary `pub struct` in the library
(criterion 3); `impl Port for Adapter` is the verification (criterion 4); one generic
`assert_repository_contract<R: Port>` function is called once per adapter (criterion 5);
one `serde`-derived struct is what both front ends emit (criterion 6). py needs a different
mechanism for criterion 4 because `Protocol` satisfaction is structural and invisible until
a checker runs; ts needs a different mechanism for criteria 1 and 3 because it has no
nominal trait to hang a shipped fake off, and its D-019(5) decision to inject `fetchImpl`
directly is a defensible realization of the same capability in a structurally typed
language.

**Cross-repo adjudication (HIGH question, owner clarification 2026-09-04).** Changes to py
and ts are a follow-on project; this is their rationale.

- **F013 — ts has no shipped fake.** `docs/port/DIVERGENCE-ANALYSIS.md:74` records "no
  recorded reason (ts area notes describe the gap, no D-0nn)". With no decision behind it,
  this is **accidental drift, not a justified ecosystem difference**: nothing in TypeScript
  prevents exporting a `createInMemoryProjectsRepository()` from `src/`. Proposed follow-on
  for ts: promote one of the per-test fakes in `tests/*.test.ts` into an exported factory.
- **F121 — ts has no cross-implementation suite.** Same file, `:76`: "no recorded reason;
  consequence of F001's absence". Also **drift**, but *contingent*: the suite only has
  meaning once a second implementation exists, so it follows F013 rather than standing alone.
- **F018 — ts has no thin web adapter.** `:75` records the cause as "ts never built a web
  front-end, so there is nothing to compare, not a language limit". This is **not drift**;
  it is an absent capability whose scope question is already carried once, on R69
  (`docs/port/DIVERGENCE-ANALYSIS.md:41-44`). No follow-on is proposed here.
- **F001, F002, F011 — justified ecosystem differences.** `harmonize: no` on all three. py's
  `Protocol` + `ty` and ts's injected `CliDeps` are each idiomatic in their own type system;
  requiring one shared low-level mechanism would be a shared value with no supporting
  evidence, which the owner mandate forbids. The principle is preserved at the capability
  level instead.
- **No shared low-level value is recommended.** Neither an explicit owner requirement nor
  evidence of the same tradeoff in all three ecosystems supports one.

**BASELINE-REVIEW finding.**

BASELINE-REVIEW: F011 — an adapter is mechanically proven to satisfy its port before the code ships — restate the row's mechanism as *nominal* satisfaction enforced by `rustc` at `cargo check` time (`impl Port for Adapter`), not "structural satisfaction verified by a type checker", and record that Rust has no separate verification tool to select, so the row's acceptance criterion becomes a compile-failure demonstration rather than a checker configuration — evidence: py's row rests on `pyproject.toml:253` running `ty` as a distinct gate over a structurally satisfied `Protocol` (`docs/port/COMMONALITY.md`, R01/F011 row via `docs/port/DIVERGENCE-ANALYSIS.md:73`), whereas the Rust Reference defines trait implementation as an explicit `impl` item and defines dyn compatibility as a property checked by the compiler (`https://doc.rust-lang.org/reference/items/traits.html`, 2026-09-05), and this run observed `error[E0038]: the trait NativeAsyncPort is not dyn compatible` from `cargo build` on rustc 1.98.0 for a trait that violates those rules — a compiler diagnostic, with no tool in the loop. Affected items: R01 (this item, F011), R30 `type-check-gate` (which must not be scoped to include adapter-port conformance, because there is nothing left for it to check).

**Minimal realistic example and its acceptance check.** Specified, written and executed in
this run; the source is reproduced under `### Validation strategy`. It is a five-file library
containing the port trait, the blanket `Arc` impl, a production adapter, the shipped
in-memory fake, the generic service, the composition root, the generic contract suite, and
one `serde` struct, with an integration test target that runs the suite against two adapters
and asserts the erased port satisfies a web layer's state bounds. `cargo test` passes 5/5 on
rustc 1.96.0 (the declared MSRV floor), 1.97.1 and 1.98.0. Checks that were **executed** are
labeled as such below; checks proposed for the template's CI are labeled *proposed*.

### Recommendation

**One stack: a dyn-compatible Rust `trait` port with a generic service erased to
`Arc<dyn Port>` at a plain-function composition root, a hand-written in-memory fake shipped
in the library, a generic contract function run once per adapter, and `serde` 1.0.229 as the
single data contract the CLI and the web layer share. Exactly one new runtime dependency
(`serde`); no dependency at all is added for the seam, the root, the fake or the suite.**

Concretely, and with versions:

1. **Port (F001)** — `pub trait ProjectsRepository: Send + Sync` with no generic methods, no
   associated consts and `Self` only in receiver position, so it stays dyn compatible. Plus
   `impl<T: ProjectsRepository + ?Sized> ProjectsRepository for Arc<T>`. Language feature;
   no crate.
2. **Composition root (F002)** — `pub fn build_projects_service(repo: Arc<dyn ProjectsRepository>) -> ProjectsService<Arc<dyn ProjectsRepository>>`.
   Language feature; no crate. No DI container.
3. **Shipped fake (F013)** — `pub struct InMemoryProjectsRepository { rows: Mutex<Vec<Project>> }`
   in the library crate, public and not `#[cfg(test)]`. `std::sync::Mutex`; no crate.
4. **Verification and substitutability suite (F011, F121)** — `impl ProjectsRepository for X`
   is the verification; `pub fn assert_repository_contract<R: ProjectsRepository>(make: impl Fn(Vec<Project>) -> R)`
   is the suite, called once per adapter from `tests/`. Built-in `#[test]` harness; no crate.
   An optional, off-by-default `mock` Cargo feature may gate `#[cfg_attr(feature = "mock", mockall::automock)]`
   for interaction assertions — the mock-crate selection itself is R48's, not this item's.
5. **Shared data contract (F018)** — `serde` **1.0.229** with the `derive` feature; the same
   `#[derive(Serialize, Deserialize)]` structs the CLI renders are what the web layer returns.

**Conditional on R05 (`sync-async-execution-model`), which is open.** If R05 lands a **sync**
I/O boundary, the stack above is complete and adds nothing. If R05 lands an **async**
boundary, one crate must be added to keep the port dyn compatible: `async-trait` **0.1.92**
(2026-08-08), because native `async fn` in a trait produces an opaque return type and the
Rust Reference lists opaque return types as disqualifying for dyn compatibility. This run
observed that exact failure and its fix (see `### Validation strategy`). `rust-lang/crates.io`
takes the same route: `crates/crates_io_github/Cargo.toml` pins `async-trait = "=0.1.92"` for
its `GitHubClient` port. Everything else in the stack is unchanged by R05's direction. This
report does not choose sync or async.

### Members

#### Port abstraction (F001) — Rust trait, dyn-compatible, dual dispatch

##### Landscape

Category: how the driven-I/O contract is named. Bins — *built-in/first-party*: `trait` with
a generic bound (`P: Port`), `trait` behind `dyn Port`, and struct fields of boxed closures
(`Box<dyn Fn>`), the direct analogue of ts's injected-function seam; *established industry
standard*: none — no crate is needed or used to declare a port in Rust, which is itself the
finding; *up-and-comer*: `trait-variant` 0.1.3 (rust-lang org) for async trait variants, and
its announced-but-unshipped dynamic-dispatch utilities. Practice surveyed: `rust-lang/crates.io`
(`Arc<dyn GitHubClient>`, `src/app.rs:43`), `jj-vcs/jj` (`Box<dyn Backend>`, `lib/src/store.rs:58`),
`mozilla/sccache` (`pub trait Storage: Send + Sync`, `src/cache/cache.rs:75`) — all three name
the port as a trait and none uses a closure-field seam.

##### Principles and implementation

Principle: the use case depends on a name, not on a transport. Agreement level:
policy/mechanism, `harmonize: no` (`docs/port/DIVERGENCE-ANALYSIS.md:71`) — Rust decides
alone. The HIGH question asks `dyn` **or** generic; the evidence says the question is a false
binary, because the two are not mutually exclusive once the trait is declared dyn compatible
and a blanket `impl<T: Port + ?Sized> Port for Arc<T>` exists. The Rust API Guidelines make
the declaration-time decision the load-bearing one: "When designing a trait, decide early on
whether the trait will be used as an object or as a bound on generics"
(C-OBJECT, `https://rust-lang.github.io/api-guidelines/flexibility.html`, 2026-09-05). The
recommendation preserves both options by satisfying the Reference's dyn-compatibility rules:
supertraits dyn compatible, no `Self: Sized` supertrait, no associated constants, no
associated types with generics, and every dispatchable method free of type parameters,
non-receiver `Self`, and opaque return types
(`https://doc.rust-lang.org/reference/items/traits.html`, 2026-09-05).

##### Dominant choice

A plain `pub trait` is the dominant choice with no close second: every surveyed project uses
it, and no crate competes for the job. Within that, the dominant *dispatch* choice in
production Rust services is erasure at the boundary — `rust-lang/crates.io` stores
`Arc<dyn GitHubClient>` (`src/app.rs:43`), `Box<dyn OidcKeyStore>` (`:54`),
`Box<dyn TeamRepo + Send + Sync>` and `Box<dyn DocsRsClient>` (`src/worker/environment.rs:40-44`);
`jj-vcs/jj` stores `Box<dyn Backend>` (`lib/src/store.rs:58`).

##### Qualified shortlist

`inapplicable — no crate implements this member; it is a language feature.` The shortlist is
therefore of *designs*, all of which pass every gate because none adds a dependency:
(a) generic bound only; (b) `dyn` only; (c) generic service erased at the root (recommended);
(d) boxed-closure fields.

##### Excluded by gate

`inapplicable — no crate candidate exists for this member, so no candidate can fail a
licence, MSRV, advisory, platform, feature or build-cost gate.` For completeness the gates
are answered for the language feature itself: (1) licence — the feature is part of Rust,
`MIT OR Apache-2.0`, compatible; (2) MSRV — trait objects and generic bounds predate 1.0,
blanket impls over `?Sized` predate 1.0, so the 1.96 floor is met with margin, verified by
compiling the design on 1.96.0; (3) advisories — no crate, so no RustSec page can exist;
(4) platforms — no platform-specific code, executed on macOS aarch64, ubuntu-latest
*proposed*; (5) features and async coupling — none, except the R05 conditional stated in
`### Recommendation`; (6) build cost — see *Tradeoffs*.

##### Up-and-comers

`trait-variant` 0.1.3 (crates.io: 3,416,048 downloads in 90 days; 12,816,596 all-time;
newest non-yanked 0.1.3 of 2026-07-22; `MIT OR Apache-2.0`; `rust_version` 1.75;
`https://crates.io/api/v1/crates/trait-variant` and `/versions`, 2026-09-05.
GitHub `rust-lang/impl-trait-utils`: 134 stars, `archived: false`, `pushed_at: 2026-07-22`;
open issues 9 via `https://api.github.com/search/issues?q=repo:rust-lang/impl-trait-utils+is:issue+is:open`,
2026-09-05). Relevant only under an async R05. Its docs for 0.1.3 describe generating a
variant that "adds bounds to `async fn` and/or `-> impl Trait` return types" and contain no
`dyn` support (`https://docs.rs/trait-variant/latest/trait_variant/`, 2026-09-05), so the
capability the 2023 announcement anticipated has still not shipped. Watch, do not adopt.

##### Fit for this template

The CLI + library + web triple is what decides this. Generic-only (design a) forces `<P>`
into every web handler signature and every CLI command type, and duplicates the service in
the binary once per adapter. `dyn`-only (design b) gives library consumers a vtable call they
cannot opt out of. Design (c) gives each consumer the right thing: a library user writes
`ProjectsService::new(RealAdapter)` and gets a monomorphized, inlinable service; the CLI and
the web layer both use the single type `ProjectsService<Arc<dyn ProjectsRepository>>`, which
is `Clone`, `Send`, `Sync` and `'static` — the bounds a per-request web state must satisfy.
This run compiled all of that and asserted the web-state bounds explicitly with
`fn requires_web_state<S: Clone + Send + Sync + 'static>(_: S)`.

##### Recommendation

Declare `pub trait ProjectsRepository: Send + Sync` obeying the dyn-compatibility rules; add
`impl<T: ProjectsRepository + ?Sized> ProjectsRepository for Arc<T>`; make the service
`pub struct ProjectsService<R: ProjectsRepository>`; expose
`pub type ErasedProjectsService = ProjectsService<Arc<dyn ProjectsRepository>>` as the type
the CLI and web layers name. No crate, no version. Under an async R05, add `async-trait`
0.1.92 above the trait and its impls.

##### Ranked runner-up

1. **`dyn`-only** (`struct Service { port: Arc<dyn Port> }`) — the shape `jj` and `sccache`
   use. Choose it if the extra type parameter on `ProjectsService` proves to be documentation
   noise for template readers; the cost is a vtable call the library consumer cannot escape.
2. **Boxed-closure fields**, the direct Rust translation of ts's `CliDeps` (ts `src/router.ts:31`).
   Viable and honest to the ts precedent, but each field needs its own `Box<dyn Fn(..) -> .. + Send + Sync>`,
   related operations lose the invariant that they come from one backend, and a stateful fake
   has nowhere to live. Ranked below both trait designs.
3. **Generic-only** — best codegen, worst ergonomics for a web layer.

##### Tradeoffs

The vtable call at the erased boundary is one indirection per port method call, on a code
path that is about to perform I/O; against an HTTP round trip it is unmeasurable, and no
benchmark is offered because none would be honest at this granularity. What is measurable is
the *shape* cost: the Rust Book states that dynamic dispatch "prevents the compiler from
choosing to inline a method's code, which in turn prevents some optimizations"
(`https://doc.rust-lang.org/book/ch18-02-trait-objects.html`, 2026-09-05), while generics
"pay no runtime cost … The process of monomorphization makes Rust's generics extremely
efficient at runtime" (`https://doc.rust-lang.org/book/ch10-01-syntax.html`, 2026-09-05).
Design (c) keeps the second property where it matters (library consumers) and accepts the
first where it does not (behind I/O). Binary size and compile time: monomorphization
duplicates `ProjectsService`'s code once per adapter type actually instantiated; erasing at
the root means the shipped CLI binary contains exactly one instantiation, so design (c) is
*smaller* than design (a) for the binary and larger than design (b) by the one extra
generic instantiation the library's own tests create. No dependency is added, so there is no
dependency compile cost at all — the relevant comparison is that enabling the optional
`mock` feature in this run's probe raised clean debug build CPU from 7.62 s to 14.32 s
(see the F011/F121 member).

##### Parameters

`owns http-transport-injection-seam` — this member is the substantive content of that value;
the exact registry string is written once under the bundle-level `### Parameters`.
`assumes rust-edition = 2024` (the probe compiled under it); `assumes msrv-policy = stable
minus 2 minor versions …` (verified at 1.96.0); `assumes license = MIT OR Apache-2.0` (no
dependency introduced); `assumes target-os-matrix = ubuntu-latest, macos-latest` (macOS
executed, Ubuntu proposed). No `CONFLICT:` line.

##### Migration implications

Creates the port module (a `ports` module inside the core library; **which crate it lives in
is R02's decision, not this item's**) holding the trait, the blanket `Arc` impl and the
error type; creates an `adapters` module for the production implementation; changes the
service type to take `R: ProjectsRepository`. If R05 lands async, adds `async-trait` to the
core library's `[dependencies]` and `#[async_trait]` to the trait and each impl.

##### Validation strategy

*Executed in this run:* the trait, blanket impl, generic service and erased alias compile and
their tests pass on rustc 1.96.0, 1.97.1 and 1.98.0 (`cargo test`, 5 passed). Dyn
compatibility was additionally proven negatively: a port declared with native `async fn`
failed with `error[E0038]: the trait NativeAsyncPort is not dyn compatible … note: for a
trait to be dyn compatible it needs to allow building a vtable` on rustc 1.98.0, and the same
trait under `#[async_trait]` compiled. *Proposed for the template:* a `trybuild`- or
`compile_fail`-style doc test asserting that adding a generic method to the port breaks
`Arc<dyn ProjectsRepository>`, so the dyn-compatibility constraint is enforced rather than
documented.

##### Confidence & re-verify trigger

High. The mechanism is a stable language feature, the practice evidence is three current
projects read at source, and the design was compiled. Re-verify when R05 publishes its
sync/async decision (it changes whether `async-trait` joins the stack), when R02 publishes
crate topology (it changes where the module lives), or if `trait-variant` ships dynamic-
dispatch support, which would replace `async-trait` in the async branch.

##### Sources

`https://doc.rust-lang.org/reference/items/traits.html` (dyn-compatibility rules), 2026-09-05.
`https://rust-lang.github.io/api-guidelines/flexibility.html` (C-OBJECT), 2026-09-05.
`https://doc.rust-lang.org/book/ch18-02-trait-objects.html`, 2026-09-05.
`https://doc.rust-lang.org/book/ch10-01-syntax.html`, 2026-09-05.
`https://blog.rust-lang.org/2023/12/21/async-fn-rpit-in-traits/`, 2026-09-05.
`https://raw.githubusercontent.com/rust-lang/crates.io/main/src/app.rs`, `.../src/worker/environment.rs`, 2026-09-05.
`https://raw.githubusercontent.com/jj-vcs/jj/main/lib/src/backend.rs`, `.../lib/src/store.rs`, 2026-09-05.
`https://raw.githubusercontent.com/mozilla/sccache/main/src/cache/cache.rs`, 2026-09-05.
`https://crates.io/api/v1/crates/trait-variant`, `/versions`, `/reverse_dependencies`, 2026-09-05.
`https://api.github.com/repos/rust-lang/impl-trait-utils`, 2026-09-05.
`https://docs.rs/trait-variant/latest/trait_variant/`, 2026-09-05.
`https://static.rust-lang.org/dist/channel-rust-stable.toml`, 2026-09-05.

#### Composition root (F002) — plain factory function, no DI container

##### Landscape

Category: how the production adapter is bound to the use case, once. Bins —
*built-in/first-party*: a `pub fn` factory returning a concrete or erased service; a struct
holding the erased ports and constructed once in `main`; *established industry standard*:
none — Rust has no widely used DI container, which is the finding; *up-and-comer*: `shaku`
0.6.3, `dill` 0.17.0, `nject` 0.5.1, and the historical `teloc` 0.2.0. Practice surveyed:
`rust-lang/crates.io` builds `pub struct App` in `src/app.rs` and wraps it as
`pub struct AppState(pub Arc<App>)` at `:259`, with no container anywhere in the tree;
`jj-vcs/jj` constructs `Store` around a `Box<dyn Backend>` (`lib/src/store.rs:58,75`).

##### Principles and implementation

Principle: exactly one place decides which adapter is real, so every other module is
adapter-agnostic. Agreement level: policy/mechanism, `harmonize: no`
(`docs/port/DIVERGENCE-ANALYSIS.md:72`). py realizes it as `build_projects_service()`
(`src/py_launch_blueprint/composition.py:36`); ts's `realDeps()` (`src/router.ts:55`) is a
root in name with nothing to swap. The Rust realization keeps py's shape exactly — a factory
function — and the language supplies what py's runtime cannot: if a caller tries to reach
past the root and construct the service with a type that does not implement the port, it is
a compile error.

##### Dominant choice

A plain factory function plus a struct of erased ports. Evidenced, not asserted: the Rust
project's own registry service does exactly this, and the DI-container crates have
essentially no reverse dependencies (below), which is direct evidence that the Rust
ecosystem does not solve this problem with a library.

##### Qualified shortlist

`inapplicable for the recommendation — the recommended mechanism is a language feature and
adds no crate.` The crate alternatives were nonetheless measured so the "no container"
conclusion rests on figures rather than taste. All figures 2026-09-05, crates.io endpoints
`https://crates.io/api/v1/crates/<name>` and `/versions`, GitHub `https://api.github.com/repos/<o>/<r>`,
open issues `https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`.

| Crate | 90-day dl | All-time dl | Newest non-yanked | Reverse deps | Stars | Archived | pushed_at | Open issues | Licence | Declared MSRV |
|---|---:|---:|---|---:|---:|---|---|---:|---|---|
| `shaku` | 34,716 | 240,829 | 0.6.3 (2026-08-02) | 24 | 609 | false | 2026-08-09 | 6 | `MIT/Apache-2.0` | 1.88 |
| `dill` | 5,580 | 68,979 | 0.17.0 (2026-08-30) | 0 | 33 | false | 2026-08-30 | 2 | `MIT OR Apache-2.0` | none declared |
| `nject` | 4,824 | 27,660 | 0.5.1 (2026-06-29) | 0 | 90 | false | 2026-06-29 | 2 | `MIT` | 1.85 |
| `teloc` | 200 | 13,144 | 0.2.0 (2021-11-25) | 0 | 170 | false | 2024-08-03 | 14 | `MIT OR Apache-2.0` | none declared |

Maintenance by rubric: `shaku` **active** (release 2026-08-02, push 2026-08-09, 6 open
issues); `dill` **active** (release and push 2026-08-30) but effectively single-consumer —
0 reverse dependencies, 33 stars; `nject` **active** (release and push 2026-06-29), 0 reverse
dependencies; `teloc` **at-risk**, and the concrete signal is not the date alone but that the
last release (2021-11-25) predates the 2024 edition entirely and the repository has had no
push since 2024-08-03 while carrying 14 open issues.

##### Excluded by gate

- **`shaku` 0.6.3 — excluded by gate 2 (MSRV).** Its declared `rust_version` is **1.88**.
  That is inside the current floor of 1.96, so it does not fail today; it fails the *policy*,
  which requires the floor to be raised only in a minor release. A dependency that tracks
  recent compilers this closely can push a patch release past the template's floor at any
  time. Recorded as a gate concern rather than a hard failure, and it is moot because gate 6
  and fit exclude it anyway.
- **`teloc` 0.2.0 — excluded by gate 2 and gate 6.** No `rust-version` is declared at all, so
  the MSRV of the dependency tree cannot be established without building it, and the crate
  predates edition 2024.
- **`nject` 0.5.1 — excluded by gate 1 in the strict reading.** Licence is `MIT` alone. MIT is
  compatible with distributing an `MIT OR Apache-2.0` project, so this is not a blocking
  legal defect; it is recorded because an MIT-only dependency does not carry Apache-2.0's
  express patent grant, which is the stated reason the owner chose the dual licence
  (`docs/port/PARAMETERS.md`).
- **All four — excluded on fit, which is the decisive gate.** The template has one
  composition root and a handful of ports. A container converts a compile-time wiring error
  into a registration-time or resolution-time one, and adds a proc-macro to the build for a
  problem a ten-line function solves.

##### Up-and-comers

`dill` and `nject` are the live ones. `dill` is developed inside `kamu-data` and its 0
reverse dependencies say it is used by its own authors; `nject` is a compile-time injector
with 90 stars. Neither has adoption that would make it a defensible choice for a public
template. Re-examine only if a future item introduces a genuinely large object graph.

##### Fit for this template

A template is read as documentation. A reader who opens `composition.rs` and finds
`pub fn build_projects_service(repo: Arc<dyn ProjectsRepository>) -> ErasedProjectsService`
learns the whole wiring story in one line; a reader who finds a container's registration DSL
learns the container first. `rust-lang/crates.io` — a far larger service than this template —
still hand-writes `App` and `AppState`.

##### Recommendation

Two functions in one module: `pub fn build_projects_service(repo: Arc<dyn ProjectsRepository>) -> ErasedProjectsService`
for tests and callers that bring their own adapter, and `pub fn production_service() -> ErasedProjectsService`
that constructs the real adapter and calls the first. No crate, no version. The web layer's
state holds the value the same function returns; the framework itself is R69's decision and
is not chosen here.

##### Ranked runner-up

1. **A `struct AppContext` holding every erased port**, constructed once in `main` — the
   `rust-lang/crates.io` `App` shape. Adopt this the moment the template has more than about
   three ports; it is a mechanical refactor from the factory function, not a redesign.
2. **`shaku` 0.6.3** — the only DI crate with non-trivial adoption (24 reverse dependencies),
   should the owner explicitly want a container. Not recommended.

##### Tradeoffs

The factory function has one real cost: it must be updated by hand when a port is added, and
nothing forces a caller to use it — a determined caller can construct `ProjectsService::new`
directly with a real adapter. That is a documentation-and-review constraint, and the
mitigation is module visibility (`pub(crate)` on the production adapter's constructor), which
belongs to R02/R04. Against that: zero dependencies, zero build cost, zero runtime resolution
failure mode, and a wiring error is a compile error.

##### Parameters

No parameter is owned by this member. `assumes rust-edition = 2024`;
`assumes msrv-policy = stable minus 2 minor versions …`; `assumes license = MIT OR Apache-2.0`;
`assumes target-os-matrix = ubuntu-latest, macos-latest`. No `CONFLICT:` line.

##### Migration implications

Adds one `composition` module to the core library with the two functions above; `main.rs`
calls `production_service()` once and passes the result into the CLI dispatch; the web
feature's state constructor calls the same function. Nothing else in the template
constructs an adapter.

##### Validation strategy

*Executed in this run:* `build_projects_service` compiled and was exercised by
`service_accepts_concrete_and_erased_ports`, which builds the service both ways and asserts
both return the same row count; `data_contract_round_trips_for_the_web_layer` calls
`production_service()`. *Proposed for the template:* a CI grep (or a `clippy` disallowed-path
lint) asserting the production adapter's constructor appears exactly once outside its own
module, which is the observable form of acceptance criterion 2.

##### Confidence & re-verify trigger

High. Re-verify if R02 introduces a crate topology in which the root cannot see both the
adapter and the service without a dependency cycle, or if the port count grows past roughly
three, at which point runner-up 1 becomes the recommendation.

##### Sources

`https://raw.githubusercontent.com/rust-lang/crates.io/main/src/app.rs`, 2026-09-05.
`https://raw.githubusercontent.com/jj-vcs/jj/main/lib/src/store.rs`, 2026-09-05.
`https://crates.io/api/v1/crates/shaku`, `/dill`, `/nject`, `/teloc` and each `/versions` and `/reverse_dependencies`, 2026-09-05.
`https://api.github.com/repos/AzureMarker/shaku`, `.../kamu-data/dill-rs`, `.../nicolascotton/nject`, `.../p0lunin/teloc`, 2026-09-05.
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for the four repositories above, 2026-09-05.
`docs/port/PARAMETERS.md` (licence rationale), read 2026-09-05.

#### Shipped in-memory fake (F013) — std::sync::Mutex, no crate

##### Landscape

Category: what the substitutable implementation is made of, and where it ships. Bins —
*built-in/first-party*: `std::sync::Mutex`, `std::sync::RwLock`, `std::cell::RefCell` (single-
threaded only), `std::sync::atomic`; *established industry standard*: `parking_lot` 0.12.5 as
a lock replacement, `mockall` 0.15.0 for generated doubles; *up-and-comer*: `faux` 0.1.13,
which mocks a struct without requiring a trait. Practice surveyed: `jj-vcs/jj` ships
`lib/testutils/src/test_backend.rs` as a real crate artifact, and
`lib/testutils/src/lib.rs:237-257` selects among `Git`, `Simple` and `Test` backends;
`rust-lang/crates.io` ships generated doubles from the port crates themselves via
`[features] mock = ["dep:mockall"]` (`crates/crates_io_github/Cargo.toml`).

##### Principles and implementation

Principle: the double is a first-class shipped artifact, not a per-test improvisation —
`harmonize: yes`, agreement level **capability/standard**
(`docs/port/DIVERGENCE-ANALYSIS.md:74`). py realizes it as
`src/py_launch_blueprint/core/adapters/in_memory.py:20` (`InMemoryProjectsRepository` living
under `core/adapters/`); ts has no equivalent and no recorded reason, which this report
adjudicates as drift. The Rust realization must clear one obstacle py does not have: the port
method takes `&self`, so a stateful fake needs interior mutability. The MEDIUM question asks
whether that needs a crate. **It does not.** `std::sync::Mutex<Vec<Project>>` gives interior
mutability behind `&self` and satisfies the `Send + Sync` bound the port and any web state
require. This was compiled and tested in this run.

##### Dominant choice

Two shapes are both dominant and they answer different questions. A **hand-written stateful
fake** (jj's `test_backend.rs`) is dominant when the double must *behave* like the real thing
across a whole suite. A **generated mock** (`mockall::automock`, as in `crates_io_github`) is
dominant when a single test asserts an *interaction*. F013 and F121 together describe the
first: py's shipped `InMemoryProjectsRepository` holds state and the same contract suite runs
against it and the real adapter. A mock cannot do that, because a mock's behavior is
programmed per test.

##### Qualified shortlist

`std::sync::Mutex` (recommended, zero dependencies). Measured alternatives, all figures
2026-09-05 from `https://crates.io/api/v1/crates/<name>`, `/versions`,
`/reverse_dependencies`, `https://api.github.com/repos/<o>/<r>` and
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`:

| Crate | 90-day dl | All-time dl | Newest non-yanked | Reverse deps | Stars | Archived | pushed_at | Open issues | Licence | Declared MSRV |
|---|---:|---:|---|---:|---:|---|---|---:|---|---|
| `parking_lot` | 209,536,781 | 1,046,524,439 | 0.12.5 (2025-10-03) | 8,030 | 3,402 | false | 2026-08-28 | 62 | `MIT OR Apache-2.0` | 1.71 |
| `faux` | 115,464 | 1,867,608 | 0.1.13 (2025-09-27) | 8 | 484 | false | 2025-09-27 | 14 | `MIT` | 1.65 |

Maintenance by rubric: `parking_lot` **stable-quiet** — no release since 2025-10-03 (a trigger
to investigate, not a verdict), but `pushed_at` is 2026-08-28, it is not archived, and its
`lock_api` dependency requirement is `^0.4.14`
(`https://crates.io/api/v1/crates/parking_lot/0.12.5/dependencies`, 2026-09-05), which is well
past the fix for the one advisory in its tree. `faux` **at-risk** — the concrete signal is
that release and last push are the same day (2025-09-27), nearly a year ago, with 14 open
issues and 8 reverse dependencies.

##### Excluded by gate

- **`parking_lot` — not excluded, but not needed.** All six gates pass: (1) `MIT OR Apache-2.0`;
  (2) declared MSRV 1.71, inside 1.96; (3) `https://rustsec.org/packages/parking_lot.html`
  returns **HTTP 404** (no advisory page, so no advisory), and its dependency `lock_api` has
  one *informational* advisory, `RUSTSEC-2020-0070` "Unsoundness in lock_api"
  (`https://rustsec.org/packages/lock_api.html`, 2026-09-05), which the `^0.4.14` requirement
  already excludes; `unsafe` posture: `parking_lot` is a lock implementation and uses `unsafe`
  by construction, which is exactly why not adding it is preferable under R06's Rust-only
  unsafe policy; (4) pure Rust, no platform restriction stated; (5) default features, no async
  runtime coupling; (6) small, but nonzero. **Excluded on fit:** `std::sync::Mutex` is
  sufficient for a fake that guards a `Vec`, and a template should not teach a dependency for
  it.
- **`faux` 0.1.13 — excluded by gate 1 (strict reading) and on fit.** Licence is `MIT` alone
  (same patent-grant note as `nject`). On fit: `faux` exists to mock structs *without* a
  trait, which is the opposite of this item's design; once a port trait exists it has nothing
  to add over `mockall`.
- **`RefCell` — excluded on fit.** It is `!Sync`, so a `RefCell`-backed fake could not be
  placed behind `Arc<dyn ProjectsRepository>` or used as web state.

##### Up-and-comers

`faux` is the only up-and-comer in this slot and it is at-risk (above). Nothing else in the
mock/fake space has emerged with adoption worth tracking for this member; the mocking-crate
landscape proper is R48's item, and this report deliberately stops at "the seam does not
require one".

##### Fit for this template

The fake must be `pub` in the library crate, usable by a downstream consumer of the template
without `cfg(test)`, cheap enough to ship in the default build, and `Send + Sync` so the web
layer can hold it. A `Mutex<Vec<Project>>`-backed struct is all four with no dependency.
Under `rust-lang/crates.io`'s pattern a *generated* double is gated behind an optional
feature precisely because it costs a dependency; a hand-written fake costs nothing and can
ship unconditionally, which is closer to py's shape (`core/adapters/in_memory.py` is
unconditionally importable).

##### Recommendation

`pub struct InMemoryProjectsRepository { rows: std::sync::Mutex<Vec<Project>> }` with
`pub fn with_rows(rows: Vec<Project>) -> Self` and `#[derive(Debug, Default)]`, implementing
the port, shipped unconditionally in the core library beside the production adapter. No
crate, no version. Additionally, offer an **off-by-default** `mock` Cargo feature carrying
`#[cfg_attr(feature = "mock", mockall::automock)]` on the port, mirroring
`crates_io_github`'s `[features] mock = ["dep:mockall"]`, for interaction assertions — with
the crate selection itself deferred to R48.

##### Ranked runner-up

1. **`mockall` 0.15.0 behind an optional `mock` feature** — as a *supplement*, not a
   replacement; it cannot serve F121 (see the next member). Figures under that member.
2. **`parking_lot` 0.12.5** — swap in only if a future profile shows lock contention in the
   fake, which for a test double is implausible.
3. **`std::sync::RwLock`** — if a fake ever has a genuinely read-heavy concurrent workload.

##### Tradeoffs

`Mutex::lock` returns a `Result` that is `Err` only when a previous holder panicked, so the
fake must decide what a poisoned lock means; the probe maps it to the port's own error
variant (`PortError::Unavailable`), which keeps the fake honest about the port's failure
contract — though the failure contract itself is R03's item, not this one's. Shipping the
fake unconditionally adds a small amount of code to consumers' builds who never use it; the
alternative (a `fake`/`testing` Cargo feature) trades that for a consumer having to discover
and enable a feature, and against py's unconditional shape. Recommend unconditional, revisit
if the fake grows.

##### Parameters

No parameter is owned. `assumes rust-edition = 2024`; `assumes msrv-policy = stable minus 2
minor versions …` (`std::sync::Mutex` predates 1.0; verified at 1.96.0);
`assumes license = MIT OR Apache-2.0`; `assumes target-os-matrix = ubuntu-latest, macos-latest`.
No `CONFLICT:` line.

##### Migration implications

Adds one file to the core library's `adapters` module holding the fake, exported from the
crate root so consumers can name it. If the optional `mock` feature is adopted, adds a
`[features] mock = ["dep:mockall"]` entry and an optional dependency to that crate's
`Cargo.toml`, and one `#[cfg_attr]` line above the port trait.

##### Validation strategy

*Executed in this run:* `InMemoryProjectsRepository` compiled and passed
`in_memory_adapter_satisfies_contract` and `erased_adapter_satisfies_contract`; the
`Send + Sync + 'static` property was proven by moving `Arc<dyn ProjectsRepository>` into a
spawned `std::thread` and joining it. `cargo test --features mock` also passed 5/5 with
`mockall` 0.15.0 present, on rustc 1.96.0 and 1.98.0. *Proposed for the template:* a doc test
in the crate-root documentation that constructs the fake from a downstream-consumer
perspective, which is the observable form of acceptance criterion 3.

##### Confidence & re-verify trigger

High. Re-verify if R05 lands async (the fake's `Mutex` guard must not be held across an
`await`, which would need a restructure or an async-aware lock), if R03's absence-versus-
failure contract changes what the fake returns for "no rows", or if R48 selects a mocking
crate other than `mockall`, which changes only the optional feature's contents.

##### Sources

`https://raw.githubusercontent.com/jj-vcs/jj/main/lib/testutils/src/lib.rs`, 2026-09-05.
`https://api.github.com/repos/jj-vcs/jj/contents/lib/testutils/src` (lists `test_backend.rs`), 2026-09-05.
`https://raw.githubusercontent.com/rust-lang/crates.io/main/crates/crates_io_github/Cargo.toml`, 2026-09-05.
`https://crates.io/api/v1/crates/parking_lot`, `/versions`, `/reverse_dependencies`, `/0.12.5/dependencies`, 2026-09-05.
`https://crates.io/api/v1/crates/faux`, `/versions`, `/reverse_dependencies`, 2026-09-05.
`https://api.github.com/repos/Amanieu/parking_lot`, `.../nrxus/faux`, 2026-09-05.
`https://api.github.com/search/issues?q=repo:Amanieu/parking_lot+is:issue+is:open` and the `nrxus/faux` equivalent, 2026-09-05.
`https://rustsec.org/packages/parking_lot.html` (HTTP 404), `https://rustsec.org/packages/faux.html` (HTTP 404), `https://rustsec.org/packages/lock_api.html` (HTTP 200, `RUSTSEC-2020-0070`, INFO), 2026-09-05.
`docs/port/DIVERGENCE-ANALYSIS.md:74`, read 2026-09-05.

#### Adapter verification and substitutability suite (F011, F121) — compiler plus a generic contract function

##### Landscape

Category: how an implementation is proven to satisfy the port, and how one assertion set is
run against every implementation. Bins — *built-in/first-party*: the `impl Trait for Type`
item itself (verification), the built-in `#[test]` harness, `tests/` integration targets, and
a generic `fn` over the port bound (parametrization); *established industry standard*:
`rstest` 0.26.1, `test-case` 3.3.1, `mockall` 0.15.0; *up-and-comer*: nothing with adoption —
this space has consolidated. Practice surveyed: `jj-vcs/jj` parametrizes with `test-case`
(`lib/tests/test_commit_builder.rs:72-74`, and 8 files in the repository carry
`test_case(TestRepoBackend`); `rust-lang/crates.io` uses `mockall` for interaction doubles
(`Cargo.toml:137`, `mockall = "=0.15.0"`) and plain `#[test]`/`#[tokio::test]` functions
elsewhere.

##### Principles and implementation

Two principles share this member because in Rust they have the same answer.

*F011 — verification.* Principle: an adapter is mechanically proven to satisfy the port
before the code ships. Agreement level: policy/mechanism, `harmonize: no`
(`docs/port/DIVERGENCE-ANALYSIS.md:73`). **Rust's trait system verifies this at compile time
for free, and no crate or extra gate exists to select.** The HIGH question is answered `yes,
for free` — with one correction the ledger should record: py's `Protocol` satisfaction is
*structural* and needs `ty` to observe it; Rust's is *nominal* and the compiler rejects a
missing or mistyped method at `cargo check`. That correction is the `BASELINE-REVIEW:` line
under `### Principles and implementation`.

*F121 — substitutability.* Principle: one assertion set runs against every implementation.
Agreement level: **capability/standard**, `harmonize: yes`
(`docs/port/DIVERGENCE-ANALYSIS.md:76`). The second HIGH question asks whether reaching parity
with py's parametrized suite needs a mocking or fake-generation crate. **It does not, and a
mocking crate could not provide it.** A parametrized contract suite asserts that two
*behaviors* agree; `mockall` produces objects whose behavior is programmed per test, so a
mock has no behavior to check. The Rust-native answer is a generic function over the port
bound — `pub fn assert_repository_contract<R: ProjectsRepository>(make: impl Fn(Vec<Project>) -> R)` —
called once per adapter. Monomorphization instantiates it per adapter, the built-in harness
reports one test per call site, and no crate is involved.

##### Dominant choice

For verification: the `impl` item; there is no alternative. For the suite: among real
projects the dominant *published* form is a parametrization macro (`test-case` in `jj`,
`rstest` elsewhere), but both macros exist to vary *values*, and what this item needs to vary
is a *type*. A generic function does that natively and is what the built-in harness already
supports. Where the surveyed projects use a macro, it is because their backend selector is
itself a value (`jj`'s `TestRepoBackend` enum), which is a legitimate variant of the same
idea.

##### Qualified shortlist

Generic contract function (recommended, zero dependencies). Measured crate alternatives, all
figures 2026-09-05 from `https://crates.io/api/v1/crates/<name>` and `/versions`,
`/reverse_dependencies`, `https://api.github.com/repos/<o>/<r>`, and
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`:

| Crate | 90-day dl | All-time dl | Newest non-yanked | Reverse deps | Stars | Archived | pushed_at | Open issues | Licence | Declared MSRV |
|---|---:|---:|---|---:|---:|---|---|---:|---|---|
| `mockall` | 27,607,997 | 164,279,034 | 0.15.0 (2026-06-28) | 1,305 | 1,837 | false | 2026-09-02 | 51 | `MIT OR Apache-2.0` | 1.77.0 |
| `rstest` | 26,060,034 | 116,676,450 | 0.26.1 (2025-07-27) | 3,252 | 1,579 | false | 2026-03-26 | 68 | `MIT OR Apache-2.0` | 1.70.0 |
| `test-case` | 11,318,661 | 61,249,956 | 3.3.1 (2023-11-17) | 1,097 | 633 | false | 2024-05-12 | 25 | `MIT` | 1.63 |

Issue responsiveness, measured over the 10 most recently opened issues of each repository via
`https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc` plus each
issue's `/comments`, counting a first comment by an `OWNER`, `MEMBER` or `COLLABORATOR` other
than the reporter (2026-09-05):

- `asomers/mockall` — median **1.19 days**, **0 unanswered** of 10 (issues created 2025-10-02 to 2026-08-20).
- `la10736/rstest` — median **0.51 days**, **2 unanswered** of 10 (issues created 2025-08-10 to 2026-07-06).
- `test-case` was not sampled for responsiveness; its maintenance verdict is settled by dates alone.

Maintenance by rubric: `mockall` **active** (release 2026-06-28, push 2026-09-02, every
recent issue answered). `rstest` **stable-quiet** — no release since 2025-07-27 is a trigger,
and `pushed_at` 2026-03-26 is over five months old, but the maintainer answered 8 of the 10
most recent issues with a median of half a day, and this run compiled and ran `rstest` 0.26.1
under edition 2024 on rustc 1.98.0 successfully, so neither an `at-risk` signal nor a
`dormant` condition (unpatched advisory, broken build, maintainer notice) is present.
`test-case` **at-risk** — the concrete signal is a 2023-11-17 release with no repository push
since 2024-05-12 and 25 open issues, meaning it predates edition 2024 and has had no
maintenance through two years of compiler releases.

##### Excluded by gate

- **`test-case` 3.3.1 — excluded by gate 1 (strict reading) and by the maintenance rubric.**
  Licence `MIT` alone (patent-grant note as above), and `at-risk` per the signals just given.
  It is retained in this report only as the parametrization mechanism `jj` actually uses, which
  is evidence about the pattern, not a recommendation of the crate.
- **`mockall` 0.15.0 — passes every gate; excluded from the *recommended* stack on fit for
  F121.** Gates: (1) `MIT OR Apache-2.0`; (2) declared MSRV `1.77.0`, inside the 1.96 floor,
  and this run compiled it on 1.96.0; (3) `https://rustsec.org/packages/mockall.html` returns
  **HTTP 404** — no advisory; `unsafe` posture: `mockall` generates safe code and its runtime
  dependencies (`downcast`, `fragile`, `predicates`) are ordinary safe crates, but this was not
  audited line by line and is recorded as unverified detail; (4) its CI is `ubuntu-latest`
  only (`.github/workflows/ci.yml`, with an MSRV job in a `rust:1.77.0` container), so macOS
  is not covered by its own CI — this run compiled and ran it on macOS aarch64, and Ubuntu
  remains *proposed*; (5) default features, no async-runtime coupling in the default build;
  (6) build cost measured, see *Tradeoffs*. **Fit:** it generates mocks, not fakes, so it
  cannot supply F121; it belongs as an optional supplement and its selection is R48's.
- **`rstest` 0.26.1 — passes every gate; excluded from the recommended stack on fit.** Gates:
  (1) `MIT OR Apache-2.0`; (2) declared MSRV `1.70.0`; (3)
  `https://rustsec.org/packages/rstest.html` returns **HTTP 404** — no advisory; (4) compiled
  and ran on macOS aarch64 in this run, Ubuntu *proposed*; (5) it pulls `futures-util` and
  `futures-timer` by default for its async-test support, which is a coupling worth recording
  even though it does not select a runtime; (6) a proc-macro plus that futures tree.
  **Fit:** it varies values elegantly, but this item varies a type, which a generic function
  already does without a macro.

##### Up-and-comers

None with adoption. The relevant near-term change is not a new crate but a language feature:
if `#[test]`-adjacent custom test frameworks ever stabilize, a first-party parametrization
form could displace both macros. Nothing to adopt today.

##### Fit for this template

A template is judged partly on how little a reader must learn before the tests make sense. A
generic `assert_repository_contract` function is plain Rust: the reader sees the assertions
once and sees two `#[test]` functions calling it with different adapters, with names
(`in_memory_adapter_satisfies_contract`, `erased_adapter_satisfies_contract`) that appear
verbatim in `cargo test` output. Adding a proc-macro dev-dependency to achieve the same
output is the sort of avoidable build cost the 2025 State of Rust Survey identifies as a
standing pain point ("resource usage (slow compile times and storage usage) is still up
there", `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`, 2026-09-05).

##### Recommendation

Ship the contract suite as a public generic function in the library:
`pub fn assert_repository_contract<R: ProjectsRepository>(make: impl Fn(Vec<Project>) -> R)`,
holding every behavioral assertion once. Call it from `tests/` once per adapter — at minimum
the shipped in-memory fake and the production adapter. Verification of F011 needs nothing
beyond `impl ProjectsRepository for <Adapter>` and the existing `cargo check` in CI. Add
`mockall` 0.15.0 only behind the optional `mock` feature described in the previous member, and
only if R48 selects it.

##### Ranked runner-up

1. **`rstest` 0.26.1**, if the template's authors prefer one test function with
   `#[case::real(...)]` / `#[case::fake(...)]` arms over two call sites. Verified working in
   this run under edition 2024. Its case labels appear in test names
   (`t::contract::case_2_fake`), which is a genuine readability gain.
2. **`test-case` 3.3.1**, the mechanism `jj` uses. Ranked below `rstest` purely on maintenance.
3. **`mockall` 0.15.0**, for interaction assertions only — a different job, not a runner-up
   for the suite.

##### Tradeoffs

The generic function's cost is that the suite's assertions must be expressible without
knowing the adapter, which forces the port's contract to be genuinely behavioral — arguably a
benefit, and exactly what py's parametrized suite already demands. Its second cost is that a
failing assertion reports the line inside the shared function, so the failure message must
name the adapter; the probe does this with per-assertion messages. Measured build cost of the
alternative, on macOS aarch64 with rustc 1.98.0, clean `target/` each time: the probe built
its test targets in **4.41 s wall / 7.62 s user CPU** without `mockall` and **5.48 s wall /
14.32 s user CPU** with `--features mock` — user CPU roughly doubles, because `mockall` adds
13 crates including a **second** `syn` (2.0.119 alongside `serde`'s 3.0.5), `predicates`,
`predicates-tree`, `termtree`, `downcast` and `fragile` (`cargo tree --features mock`). That
is the concrete price of the optional feature, and the reason it must stay off by default.

##### Parameters

No parameter is owned. `assumes rust-edition = 2024`; `assumes msrv-policy = stable minus 2
minor versions …` (executed at 1.96.0, including with `mockall`);
`assumes license = MIT OR Apache-2.0`; `assumes target-os-matrix = ubuntu-latest, macos-latest`
(macOS executed; Ubuntu proposed). No `CONFLICT:` line. This member is the direct input to
R48's F120 row: **the recommended seam needs no HTTP-mocking crate**, because the transport is
behind an injected port, which is the same conclusion ts recorded as D-019(5)
(`docs/port/DIVERGENCE-ANALYSIS.md:178`).

##### Migration implications

Adds the contract function to the core library (a `testing` or `contract` module, exported
publicly so downstream template users can run it against their own adapters); adds one
integration test file under `tests/` with one `#[test]` per adapter. Adds nothing to
`[dev-dependencies]`. If the optional `mock` feature is adopted, adds a CI job that runs
`cargo test --features mock` so the feature does not rot.

##### Validation strategy

*Executed in this run:* `cargo test` ran the shared suite against two adapters and passed —
`in_memory_adapter_satisfies_contract ... ok` and `erased_adapter_satisfies_contract ... ok` —
on rustc 1.96.0, 1.97.1 and 1.98.0, and again with `--features mock` on 1.96.0 and 1.98.0.
The `rstest` runner-up was separately compiled and run under edition 2024 on rustc 1.98.0:
`test t::contract::case_2_fake ... ok`, 2 passed. *Proposed for the template:* a CI assertion
that the number of `assert_repository_contract` call sites equals the number of adapters, so
adding an adapter without adding a contract call fails the build; and, once R05 settles, an
async variant of the same suite.

##### Confidence & re-verify trigger

High for F011 (a language guarantee, demonstrated by an observed compiler error). High for
F121's mechanism; medium for the *runner-up ranking*, because `rstest`'s five-month release
gap could become an `at-risk` signal. Re-verify `rstest` if it has no release by 2027-03-01 or
if its `pushed_at` passes twelve months; re-verify `mockall` when R48 publishes; re-verify the
whole member when R05 settles sync versus async, and when R32 (`test-harness-and-execution`)
publishes, since it owns the test tiers this suite runs in.

##### Sources

`https://raw.githubusercontent.com/jj-vcs/jj/main/lib/tests/test_commit_builder.rs`, 2026-09-05.
`https://api.github.com/search/code?q=repo:jj-vcs/jj+%22test_case(TestRepoBackend%22` (`total_count: 8`), 2026-09-05.
`https://raw.githubusercontent.com/rust-lang/crates.io/main/Cargo.toml`, `.../src/tests/util/test_app.rs`, `.../crates/crates_io_github/src/lib.rs`, `.../crates/crates_io_team_repo/src/lib.rs`, 2026-09-05.
`https://crates.io/api/v1/crates/mockall`, `/rstest`, `/test-case` and each `/versions`, `/reverse_dependencies`, 2026-09-05.
`https://api.github.com/repos/asomers/mockall`, `.../la10736/rstest`, `.../frondeus/test-case`, 2026-09-05.
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for the three repositories above, 2026-09-05.
`https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc` plus per-issue `/comments`, for `asomers/mockall` and `la10736/rstest`, 2026-09-05.
`https://rustsec.org/packages/mockall.html`, `/rstest.html`, `/test-case.html` — all HTTP 404, 2026-09-05.
`https://raw.githubusercontent.com/asomers/mockall/master/.github/workflows/ci.yml`, 2026-09-05.
`https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`, 2026-09-05.
`https://doc.rust-lang.org/reference/items/traits.html`, 2026-09-05.

#### serde 1.0.229 — the one data contract shared by CLI and web (F018)

##### Landscape

Category: how the web layer reuses the CLI's data contract without duplicating types. Bins —
*built-in/first-party*: plain structs plus hand-written conversions (`From`/`Into`) at the
boundary — a translation layer; *established industry standard*: `serde` 1.0.229 with
`#[derive(Serialize, Deserialize)]` on one shared struct; *up-and-comer*: none with adoption —
`serde` has no live competitor for this job in a general-purpose template. Practice surveyed:
`rust-lang/crates.io` lists `serde = { version = "=1.0.229", features = ["derive"] }` in the
port crates themselves (`crates/crates_io_github/Cargo.toml`), so its domain types carry the
derive rather than being re-declared per layer.

##### Principles and implementation

Principle: one data contract, rendered by the CLI and serialized by the web layer, so the two
front ends cannot drift. Agreement level: **capability/standard**, `harmonize: yes`
(`docs/port/DIVERGENCE-ANALYSIS.md:75`), sourced from py `docs/adr/0013-web-service-best-practices.md:21`.
ts has no web tier at all, so its absence is not drift and no ts follow-on is proposed. The
LOW question asks shared `serde` structs versus a translation layer. The evidence favors
**shared structs with a translation layer held in reserve**: a template's value is showing
the simple thing working, and a boundary translation is a refactor a reader can perform when
the API contract and the domain type genuinely diverge (a version-stable public schema, field
redaction, or a pagination envelope). Note the boundary: the *output format surface* is R66's
item and the *HTTP problem envelope* is R70's; this member decides only that both front ends
name the same type.

##### Dominant choice

`serde` 1.0.229. Dominance is not asserted from familiarity: it has **120,056** reverse
dependencies on crates.io — the largest figure encountered in this survey by more than an
order of magnitude over every other candidate — and **295,688,106** downloads in the last 90
days (`https://crates.io/api/v1/crates/serde`, `/reverse_dependencies`, 2026-09-05).

##### Qualified shortlist

| Crate | 90-day dl | All-time dl | Newest non-yanked | Reverse deps | Stars | Archived | pushed_at | Open issues | Licence | Declared MSRV |
|---|---:|---:|---|---:|---:|---|---|---:|---|---|
| `serde` | 295,688,106 | 1,355,199,652 | 1.0.229 (2026-07-18) | 120,056 | 10,800 | false | 2026-08-25 | 318 | `MIT OR Apache-2.0` | 1.56 |
| `serde_json` | 299,793,085 | 1,259,356,567 | 1.0.151 (2026-07-20) | 98,621 | 5,635 | false | 2026-08-08 | 190 | `MIT OR Apache-2.0` | 1.71 |

Figures from `https://crates.io/api/v1/crates/<name>`, `/versions`, `/reverse_dependencies`
and `https://api.github.com/repos/serde-rs/<repo>`; open issues from
`https://api.github.com/search/issues?q=repo:serde-rs/<repo>+is:issue+is:open`; all 2026-09-05.
`serde_json` is listed because the probe used it to demonstrate round-tripping, **but the
concrete format crate is R66's decision, not this item's** — this member requires only the
data model, `serde` itself.

Issue responsiveness for `serde-rs/serde`, same method as the previous member: of the 10 most
recently opened issues (created 2026-07-08 to 2026-08-16), **0** received a first comment
from an `OWNER`, `MEMBER` or `COLLABORATOR`, so a median cannot be computed and the
unanswered count is 10. That figure alone would read badly, and it is misleading on its own:
3 of those 10 were **closed within 0–2 days** with no comment (`#3090` opened and closed
2026-07-25; `#3087` 2026-07-21 → 2026-07-22; `#3084` 2026-07-18 → 2026-07-20), which is this
maintainer's documented triage-by-close style rather than silence. Both figures are recorded;
neither is smoothed.

Maintenance by rubric: `serde` **active** — release 2026-07-18, `pushed_at` 2026-08-25, not
archived. `serde_json` **active** — release 2026-07-20, `pushed_at` 2026-08-08.

##### Excluded by gate

- **A per-layer duplicate struct (no shared type) — excluded on fit.** It is the failure mode
  F018 exists to prevent.
- **`serde` fails no gate.** (1) Licence `MIT OR Apache-2.0`, exactly the template's licence.
  (2) Declared `rust_version` **1.56**, far inside the 1.96 floor; compiled here on 1.96.0.
  (3) `https://rustsec.org/packages/serde.html` returns **HTTP 404** — no advisory page, so no
  open advisory; `unsafe` posture: `serde` and `serde_derive` are safe-Rust crates for the
  derive path used here, though the crate was not audited line by line and that detail is
  recorded as unverified. (4) Its own CI covers `ubuntu-latest` and `windows-latest` with an
  MSRV job at 1.56.0/1.60.0 and **no macOS runner**
  (`https://raw.githubusercontent.com/serde-rs/serde/master/.github/workflows/ci.yml`,
  2026-09-05); macOS is nevertheless covered empirically because this run compiled and tested
  `serde` 1.0.229 on macOS aarch64 under rustc 1.96.0, 1.97.1 and 1.98.0. Windows is noted,
  not required. (5) Default features: `std` on; the `derive` feature must be enabled
  explicitly and pulls the `serde_derive` proc macro. No async-runtime coupling. (6) Build
  cost: the derive is a proc macro, so it costs a `syn`/`quote`/`proc-macro2` tree; in this
  run's probe those crates plus `serde`, `serde_core`, `serde_json`, `memchr`, `itoa` and
  `zmij` built clean in 4.41 s wall / 7.62 s user CPU on macOS aarch64. Binary size impact is
  proportional to the number of derived types, which for this template is a handful.

##### Up-and-comers

None recommended. Nothing in the survey competes with `serde` for a template's data model;
alternative *formats* and *codecs* exist but they sit behind `serde`'s traits and belong to
R66 (`output-format-surface`) rather than here.

##### Fit for this template

The template must render the same rows as a table on a terminal and as a JSON body over HTTP.
Deriving `Serialize`/`Deserialize` on the one domain struct makes the web layer's handler a
genuinely thin adapter — it calls the same service and returns the same type — which is
precisely the F018 principle. `rust-lang/crates.io` puts the derive on the types inside its
port crates for the same reason. Because the web tier is optional in this template
(`docs/port/PARAMETERS.md`, `web-extra-surface`, owned by R69), `serde` must live in the core
library rather than the web crate, or the CLI would lose the contract when the feature is off.

##### Recommendation

`serde = { version = "1.0.229", features = ["derive"] }` as a **non-optional** dependency of
the core library; `#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]` on the
domain types the port returns; the web handler returns those types directly. Reserve a
translation layer (`From<Domain> for ApiV1Dto`) for the first field whose public API shape
must outlive the domain shape, and say so in the template's documentation rather than
building it up front. The concrete serializer crate and the response envelope are R66's and
R70's decisions.

##### Ranked runner-up

1. **Shared struct plus a thin `From` translation at the web boundary** — the design to adopt
   the moment the API needs schema stability independent of the domain type. Same crate, more
   code.
2. **Feature-gating the `serde` derives behind the web feature** — avoids the dependency for
   CLI-only consumers, but breaks the CLI's own JSON output and splits the contract. Not
   recommended.

##### Tradeoffs

`serde`'s derive is a proc macro and therefore a compile-time cost on every build, including
CLI-only builds; that is the price of one contract instead of two, and it is the cost
essentially every Rust CLI already pays. Deriving `Deserialize` on a type the template only
ever serializes is mild over-derivation, kept here because the contract suite round-trips the
type as its acceptance check. Coupling the domain type to a wire format is a real long-term
risk — it is why runner-up 1 exists — but paying for it before there is a second consumer is
speculative generality in a template meant to be read.

##### Parameters

No parameter is owned by this member. `assumes rust-edition = 2024`;
`assumes msrv-policy = stable minus 2 minor versions …` (`serde` declares 1.56, verified at
1.96.0); `assumes license = MIT OR Apache-2.0` (`serde` is dual-licensed identically);
`assumes target-os-matrix = ubuntu-latest, macos-latest` (macOS executed; Ubuntu proposed,
and `serde`'s own CI covers `ubuntu-latest`). `assumes web-extra-surface` is **not** consumed:
this member's recommendation holds whether or not R69 ships a web tier, because the derive
lives in the core library either way. No `CONFLICT:` line.

##### Migration implications

Adds `serde` with the `derive` feature to the core library's `[dependencies]` and derives on
the domain types the port returns. Adds nothing to the CLI or web crates beyond naming those
types. If R69 ships the web tier, its handler signatures reference the library's types
directly and declare no structs of their own.

##### Validation strategy

*Executed in this run:* `data_contract_round_trips_for_the_web_layer` serialized the value
returned by `production_service().search(..)` and deserialized it back to an equal value,
passing on rustc 1.96.0, 1.97.1 and 1.98.0. *Proposed for the template:* a snapshot test over
the serialized form so a field rename is visible in review (the snapshot tool is R33's
decision), and — once R69 exists — a test asserting the web handler's response type is the
library's type by construction.

##### Confidence & re-verify trigger

High. Re-verify when R69 publishes the web stack (its extractor and response types must
accept the library's `serde` types), when R66 publishes the output-format surface (it selects
the concrete serializer), and if `serde` raises its declared `rust_version` above the
template's floor.

##### Sources

`https://crates.io/api/v1/crates/serde`, `/versions`, `/reverse_dependencies`, 2026-09-05.
`https://crates.io/api/v1/crates/serde_json`, `/versions`, `/reverse_dependencies`, 2026-09-05.
`https://api.github.com/repos/serde-rs/serde`, `.../serde-rs/json`, 2026-09-05.
`https://api.github.com/search/issues?q=repo:serde-rs/serde+is:issue+is:open` and the `serde-rs/json` equivalent, 2026-09-05.
`https://api.github.com/repos/serde-rs/serde/issues?state=all&sort=created&direction=desc`, 2026-09-05.
`https://raw.githubusercontent.com/serde-rs/serde/master/.github/workflows/ci.yml`, 2026-09-05.
`https://rustsec.org/packages/serde.html`, `/serde_json.html` — HTTP 404, 2026-09-05.
`https://raw.githubusercontent.com/rust-lang/crates.io/main/crates/crates_io_github/Cargo.toml`, 2026-09-05.
`docs/port/DIVERGENCE-ANALYSIS.md:75`, `docs/port/PARAMETERS.md`, read 2026-09-05.

### Compatibility

The members are proven to work together three ways.

**1. Executed together in one crate (this run).** All five members were written into a single
package and compiled and tested as a unit — the trait port and blanket `Arc` impl, the
factory-function composition root, the `Mutex`-backed shipped fake, the generic contract
suite run against two adapters, and the `serde`-derived contract — with the optional
`mockall` feature exercised in a second pass. Result on macOS 15 / aarch64:

| Toolchain | Command | Result |
|---|---|---|
| rustc 1.96.0 (the declared MSRV floor) | `cargo test` | 5 passed, 0 failed |
| rustc 1.96.0 | `cargo test --features mock` | 5 passed, 0 failed |
| rustc 1.97.1 | `cargo test` | 5 passed, 0 failed |
| rustc 1.98.0 (current stable line) | `cargo test` | 5 passed, 0 failed |
| rustc 1.98.0 | `cargo test --features mock` | 5 passed, 0 failed |

The package declares `edition = "2024"`, `rust-version = "1.96"` and
`license = "MIT OR Apache-2.0"`, so the fixed parameters are exercised, not assumed.

**2. A shared adopter proves the same combination in production.** `rust-lang/crates.io` is a
single Cargo workspace that combines every member of this stack: trait ports
(`crates/crates_io_github/src/lib.rs:76`, `crates/crates_io_team_repo/src/lib.rs:11`), erased
storage in a composition root (`src/app.rs:35-54`, `:259`), first-class doubles shipped from
the port crates behind an optional feature
(`crates/crates_io_github/Cargo.toml`, `[features] mock = ["dep:mockall"]`), and `serde` on
the domain types — under `edition = "2024"` and `license = "MIT OR Apache-2.0"`, the same two
fixed parameters this template sets. `jj-vcs/jj` independently proves the fake-plus-suite half
of the combination (`lib/testutils/src/test_backend.rs` with
`lib/tests/test_commit_builder.rs:72-74`).

**3. Version matrix.** The only versioned member is `serde` 1.0.229 (2026-07-18), and the only
optional one is `mockall` 0.15.0 (2026-06-28); the remaining three members are language
features with no version. `serde` declares MSRV 1.56 and `mockall` 1.77.0, both inside the
1.96 floor, and the two were resolved together in one lockfile in the executed run with no
conflict. `mockall` does introduce a second `syn` major version (2.0.119) alongside `serde`'s
3.0.5 in the same tree — Cargo resolves this without error, and it is recorded as a build-cost
fact, not a compatibility failure.

### Parameters

`owns http-transport-injection-seam` = a dyn-compatible port trait, injected as a value, with the use case generic over the port and erased to a trait object at the composition root: the driven-I/O contract is a `pub trait Port: Send + Sync` obeying the Reference's dyn-compatibility rules; a blanket `impl<T: Port + ?Sized> Port for Arc<T>` lets one generic `Service<P: Port>` serve both dispatch styles; library consumers instantiate `Service<ConcreteAdapter>` (static dispatch), while the CLI and the optional web layer share the single erased instantiation `Service<Arc<dyn Port + Send + Sync>>`; adapters are constructed only in a plain composition-root function, with no dependency-injection container; if R05 selects an async I/O boundary, the trait carries `#[async_trait]` (`async-trait` 0.1.92) to remain dyn compatible, and nothing else in the seam changes

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` (fixed, owner; resolved to floor 1.96 against stable 1.98.1 on 2026-09-05, and executed at 1.96.0)
`assumes rust-edition = 2024` (fixed, owner; the executed probe declares it)
`assumes target-os-matrix = ubuntu-latest, macos-latest` (fixed, owner; macOS executed, Ubuntu proposed)
`assumes license = MIT OR Apache-2.0` (fixed, owner; every recommended and optional crate is dual-licensed identically)

No `CONFLICT:` line is required: the recommendation needs no registered value changed. For
the record, two adjacent items receive inputs rather than conflicts — R48 receives "the
recommended seam requires no HTTP-mocking crate" for its F120 row, and R30 receives the
`BASELINE-REVIEW: F011` finding that adapter-port conformance is a compiler guarantee and
must not be scoped into a type-check gate.

### Migration implications

File-level changes in the template, expressed against the core library crate whose *name and
placement in the workspace are R02's decision, not this item's*:

- **`src/core/ports.rs` (new)** — `pub trait ProjectsRepository: Send + Sync`, the port error
  type, and `impl<T: ProjectsRepository + ?Sized> ProjectsRepository for Arc<T>`. Under an
  async R05, adds `use async_trait::async_trait;` and `#[async_trait]`.
- **`src/core/adapters/http.rs` (new)** — the production adapter and `impl ProjectsRepository for HttpProjectsRepository`.
- **`src/core/adapters/in_memory.rs` (new)** — `pub struct InMemoryProjectsRepository` backed
  by `std::sync::Mutex<Vec<Project>>`, public and unconditional, plus its `impl`.
- **`src/core/service.rs` (new)** — `pub struct ProjectsService<R: ProjectsRepository>` and
  `pub type ErasedProjectsService = ProjectsService<Arc<dyn ProjectsRepository>>`.
- **`src/composition.rs` (new)** — `build_projects_service` and `production_service`; the only
  place the production adapter is constructed.
- **`src/core/contract.rs` (new)** — `pub fn assert_repository_contract<R: ProjectsRepository>(..)`
  holding every behavioral assertion once.
- **`src/lib.rs` (changed)** — re-export the port, the service, the erased alias, both
  adapters, the composition-root functions and the contract function, so the curated public
  surface carries them (the surface policy itself is R04's).
- **`tests/projects_repository_contract.rs` (new)** — one `#[test]` per adapter calling the
  contract function, plus the web-state bounds assertion.
- **`Cargo.toml` (changed)** — add `serde = { version = "1.0.229", features = ["derive"] }`;
  optionally add `[features] mock = ["dep:mockall"]` with `mockall = { version = "0.15.0", optional = true }`
  as a normal optional dependency; under an async R05 add `async-trait = "0.1.92"`.
- **CLI entry point (changed)** — calls `production_service()` once and passes the result into
  command dispatch; no command constructs an adapter.
- **Web feature, if R69 ships one (changed)** — its state holds the value
  `production_service()` returns; handlers return the library's `serde` types and declare none
  of their own.

### Validation strategy

The commands below were run in a scratch package outside the repository. The package source is
reproduced so the check can be re-executed independently; nothing was written into the
template.

Package manifest:

```toml
[package]
name = "seam_probe"
version = "0.1.0"
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"

[dependencies]
serde = { version = "1", features = ["derive"] }
serde_json = "1"
mockall = { version = "0.15", optional = true }

[features]
mock = ["dep:mockall"]
```

Library (abridged to the load-bearing items; every line below was compiled):

```rust
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Project { pub id: String, pub name: String }

#[cfg_attr(feature = "mock", mockall::automock)]
pub trait ProjectsRepository: Send + Sync {
    fn list(&self, query: &str) -> Result<Vec<Project>, PortError>;
}

impl<T: ProjectsRepository + ?Sized> ProjectsRepository for Arc<T> {
    fn list(&self, query: &str) -> Result<Vec<Project>, PortError> { (**self).list(query) }
}

#[derive(Debug, Default)]
pub struct InMemoryProjectsRepository { rows: Mutex<Vec<Project>> }

pub struct ProjectsService<R: ProjectsRepository> { repo: R }
pub type ErasedProjectsService = ProjectsService<Arc<dyn ProjectsRepository>>;

pub fn build_projects_service(repo: Arc<dyn ProjectsRepository>) -> ErasedProjectsService {
    ProjectsService::new(repo)
}

pub fn assert_repository_contract<R: ProjectsRepository>(make: impl Fn(Vec<Project>) -> R) {
    let repo = make(vec![
        Project { id: "1".into(), name: "alpha".into() },
        Project { id: "2".into(), name: "beta".into() },
    ]);
    assert_eq!(repo.list("alpha").unwrap().len(), 1, "matching query returns one row");
    assert_eq!(repo.list("zzz").unwrap(), vec![], "absence is an empty list, not an error");
}
```

Integration test (`tests/contract.rs`): one `#[test]` calling `assert_repository_contract` with
the fake, one calling it with the fake behind `Arc<dyn ProjectsRepository>`, one building the
service both statically and erased, one asserting
`fn requires_web_state<S: Clone + Send + Sync + 'static>(_: S)` accepts the erased port and
that it can be moved into a spawned thread, and one round-tripping the domain type through
`serde_json`.

**Executed — results observed in this run, macOS 15 / aarch64:**

```
$ rustup run 1.96.0 cargo test           # MSRV floor
test result: ok. 5 passed; 0 failed; 0 ignored
$ rustup run 1.96.0 cargo test --features mock
test result: ok. 5 passed; 0 failed; 0 ignored
$ rustup run 1.97.1 cargo test
test result: ok. 5 passed; 0 failed; 0 ignored
$ cargo test                              # rustc 1.98.0
test erased_adapter_satisfies_contract ... ok
test in_memory_adapter_satisfies_contract ... ok
test service_accepts_concrete_and_erased_ports ... ok
test erased_port_is_clonable_shared_state ... ok
test data_contract_round_trips_for_the_web_layer ... ok
test result: ok. 5 passed; 0 failed; 0 ignored
```

**Executed — the dyn-compatibility boundary, proving the R05 conditional rather than asserting
it.** A port declared with a native `async fn` and used as `Arc<dyn NativeAsyncPort>` failed to
compile on rustc 1.98.0:

```
error[E0038]: the trait `NativeAsyncPort` is not dyn compatible
 --> src/lib.rs:7:28
note: for a trait to be dyn compatible it needs to allow building a vtable
```

The identical trait under `#[async_trait]` (`async-trait` 0.1.92) compiled, and
`Arc<dyn BoxedAsyncPort>` was constructible.

**Executed — the runner-up.** `rstest` 0.26.1 under edition 2024 on rustc 1.98.0 ran one
contract body against two `Arc<dyn Port>` cases: `test t::contract::case_2_fake ... ok`,
2 passed.

**Executed — build cost.** Clean debug build of the test targets, macOS aarch64, rustc 1.98.0:
4.41 s wall / 7.62 s user CPU without `mockall`; 5.48 s wall / 14.32 s user CPU with
`--features mock`.

**Proposed for the template's CI (not run here):**

- `cargo test` on `ubuntu-latest` and `macos-latest` — only macOS was executed in this run.
- `cargo check` on the declared `rust-version` as the MSRV leg (executed locally at 1.96.0;
  the CI wiring is R11's).
- `cargo test --features mock`, if the optional feature is adopted, so it cannot rot.
- A `compile_fail` doc test proving that a generic method on the port breaks
  `Arc<dyn ProjectsRepository>`, turning the dyn-compatibility constraint into a gate.
- A check that `assert_repository_contract` has one call site per adapter.
- A single-call-site check on the production adapter's constructor.

No performance benchmark is offered. The only per-call difference between the recommended
design and its runner-ups is one vtable indirection on a path that performs I/O; a
microbenchmark of that, with no stated workload, configuration, instrumentation, latency or
throughput target, would be an unlike comparison of the kind the prompt forbids. The
resource costs that *are* measurable at this decision's granularity — MSRV, dependency count,
clean-build CPU, and number of monomorphized instantiations in the shipped binary — are
reported above with their conditions.

### Confidence & re-verify trigger

**High** on the seam mechanism, the composition-root shape, the fake, and the F011 answer:
each rests on the normative language reference plus three current, well-regarded projects read
at source, and the whole stack was compiled and tested at the declared MSRV floor.

**High** on the F121 answer (no mocking or fake-generation crate is required, and a mocking
crate could not supply it), executed.

**Medium** on two points, stated as uncertainty rather than smoothed over: (a) the
*ranked runner-up* order in the contract-suite member, because `rstest`'s five-month push gap
and thirteen-month release gap could become an `at-risk` signal even though it currently
builds and its maintainer answers issues within half a day; (b) the F018 recommendation to
share `serde` structs rather than translate at the boundary, because R69 has not yet defined
the web surface and a framework with strong extractor requirements could change the calculus.

**Re-verify triggers.**

- **R05 (`sync-async-execution-model`) publishes** — decides whether `async-trait` 0.1.92 joins
  the stack. This is the single largest open dependency on this answer.
- **R02 (`crate-boundary-enforcement`) publishes** — decides which crate the port module lives
  in; the design is unaffected, the file paths in `### Migration implications` are not.
- **R48 (`mocking-crates`) publishes** — decides the contents of the optional `mock` feature.
- **R69 (`web-framework-stack`) publishes** — confirms that the selected framework accepts
  `Arc<dyn Port>`-bearing state and the library's `serde` types.
- **R66 / R70 publish** — decide the serializer and the error envelope over this contract.
- **Calendar:** re-check `rstest` if it has no release by **2027-03-01**; re-check the whole
  member set at the next `msrv-policy` floor advance (each new Rust stable moves the floor).
- **Event:** if `trait-variant` ships dynamic-dispatch utilities, revisit the async branch.

### Sources

Language and project authorities, all retrieved 2026-09-05:
`https://doc.rust-lang.org/reference/items/traits.html`;
`https://doc.rust-lang.org/book/ch18-02-trait-objects.html`;
`https://doc.rust-lang.org/book/ch10-01-syntax.html`;
`https://rust-lang.github.io/api-guidelines/flexibility.html`;
`https://blog.rust-lang.org/2023/12/21/async-fn-rpit-in-traits/`;
`https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`;
`https://static.rust-lang.org/dist/channel-rust-stable.toml`;
`https://docs.rs/trait-variant/latest/trait_variant/`.

Practice evidence read at source, all 2026-09-05:
`https://raw.githubusercontent.com/rust-lang/crates.io/main/src/app.rs`;
`.../main/src/worker/environment.rs`; `.../main/src/tests/util/test_app.rs`;
`.../main/Cargo.toml`; `.../main/crates/crates_io_github/Cargo.toml`;
`.../main/crates/crates_io_github/src/lib.rs`; `.../main/crates/crates_io_team_repo/Cargo.toml`;
`.../main/crates/crates_io_team_repo/src/lib.rs`;
`https://raw.githubusercontent.com/jj-vcs/jj/main/lib/src/backend.rs`;
`.../main/lib/src/store.rs`; `.../main/lib/testutils/src/lib.rs`;
`.../main/lib/tests/test_commit_builder.rs`;
`https://api.github.com/repos/jj-vcs/jj/contents/lib/testutils/src`;
`https://raw.githubusercontent.com/mozilla/sccache/main/src/cache/cache.rs`;
`https://raw.githubusercontent.com/serde-rs/serde/master/.github/workflows/ci.yml`;
`https://raw.githubusercontent.com/asomers/mockall/master/.github/workflows/ci.yml`;
`https://api.github.com/search/code?q=repo:jj-vcs/jj+%22test_case(TestRepoBackend%22`.

Figure endpoints, all 2026-09-05 — 90-day downloads (`crate.recent_downloads`), all-time
downloads (`crate.downloads`) and repository/licence from
`https://crates.io/api/v1/crates/<name>`; last release (newest `yanked: false` `num` and
`created_at`) and declared `rust_version` from the same response's `versions`; adopter counts
from `https://crates.io/api/v1/crates/<name>/reverse_dependencies`; stars, `archived` and
`pushed_at` from `https://api.github.com/repos/<o>/<r>`; open issues from
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` (`total_count`, never
`open_issues_count`); issue responsiveness from
`https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc` plus each
issue's `/comments`; advisories from `https://rustsec.org/packages/<name>.html`. Crates
measured: `serde`, `serde_json`, `mockall`, `rstest`, `test-case`, `parking_lot`, `faux`,
`shaku`, `dill`, `nject`, `teloc`, `async-trait`, `trait-variant`, `lock_api`,
`parking_lot/0.12.5/dependencies`.

Repository context read, 2026-09-05: `docs/port/DIVERGENCE-ANALYSIS.md` (lines 40-76, 178,
239-244), `docs/port/PARAMETERS.md`, `docs/port/README.md`, `docs/port/BASELINE-REVIEW.md`,
`research/RUNBOOK.md`, `research/CLAUDE.md`.

**Method notes.** Every download, release, star, `archived`, `pushed_at`, open-issue and
responsiveness figure in this report was fetched live on 2026-09-05 from the endpoints named
immediately above — `https://crates.io/api/v1/crates/<name>` and its `/versions`,
`/reverse_dependencies` and `/<version>/dependencies` sub-resources via `curl -sS` with a
`User-Agent` header; `https://api.github.com/repos/<o>/<r>`,
`https://api.github.com/search/issues`, `https://api.github.com/search/code` and
`https://api.github.com/repos/<o>/<r>/issues` (plus per-issue `/comments`) via the
authenticated GitHub REST CLI; `https://rustsec.org/packages/<name>.html` via `curl -sS` with
the HTTP status recorded. Advisory checks are reported as observed HTTP status: `serde`,
`serde_json`, `rstest`, `mockall`, `test-case`, `parking_lot`, `shaku`, `nject`, `dill`,
`faux`, `teloc` and `async-trait` all returned **404** (RustSec publishes no page for a
package with no advisory); `lock_api` returned **200** with one INFO advisory,
`RUSTSEC-2020-0070`, which `parking_lot` 0.12.5's `lock_api ^0.4.14` requirement already
excludes. **What could not be verified, stated plainly:** (1) nothing was executed on
`ubuntu-latest` — every executed result in this report is macOS 15 / aarch64, so the
`target-os-matrix` gate is half-satisfied empirically and half by the crates' own CI, which
covers Linux for `serde`, `serde_json`, `mockall` and `rstest` but *not* macOS for `serde` or
`mockall`; (2) `unsafe` posture for `serde`, `mockall`, `rstest` and their dependency trees is
reported from crate documentation and general knowledge of those crates, not from a
line-by-line audit or a `cargo-geiger` run; (3) `test-case`'s issue responsiveness was not
sampled, only its release and push dates; (4) `https://crates.io/api/v1/crates/<name>` was the
sole source for licence strings, which are the crate authors' declarations, not an SPDX
verification of the shipped licence files; (5) no `cargo-bloat` or comparable binary-size
measurement was taken, so the binary-size statements are qualitative and rest on the Rust
Book's monomorphization description plus the instantiation counts of the compiled design;
(6) the `codex` engine's report exists in this run directory and was deliberately not opened,
per the research-worker role contract.
