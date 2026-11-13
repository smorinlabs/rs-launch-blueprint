### Landscape

Category: the optional Rust HTTP-service surface needs a framework, an async runtime/server lifecycle, and a development restart command.  The first-party/toolchain bin is Cargo features plus Tokio's runtime and signal APIs; the established-standard bin is axum, actix-web, and warp; the up-and-comer bin is poem and the actively released `watchexec-cli` development executable.  This is a fit comparison for a CLI + library + web adapter, not a claim that any framework is best in general.  Cargo is authoritative for feature semantics, axum and Tokio are authoritative for their APIs, and the Rust project documentation is authoritative for the language toolchain; maintained-project source is practice evidence.  ([Cargo features](https://doc.rust-lang.org/cargo/reference/features.html), [axum API](https://docs.rs/axum/0.8.9/axum/), [Tokio guide](https://tokio.rs/tokio/topics/shutdown), retrieved 2026-09-12.)

| Candidate | 90-day / all-time downloads | latest non-yanked release | stars / archived / pushed | open issues | gate result before popularity |
|---|---:|---|---|---|---|
| `axum` | 115,597,652 / 466,002,347 | 0.8.9, 2026-04-14, MSRV 1.80 | 27,095 / false / 2026-09-11 | 34 | provisional pass: MIT; direct MSRV declared; Tokio-coupled server; full resolved-tree and RustSec check still required |
| `actix-web` | 10,372,543 / 80,771,779 | 4.15.0, 2026-08-21, MSRV 1.88 | 24,826 / false / 2026-09-10 | 148 | provisional pass: MIT OR Apache-2.0; direct MSRV declared; separate Actix runtime ecosystem |
| `warp` | 5,166,863 / 47,939,627 | 0.4.3, 2026-05-04, MSRV unspecified | 10,366 / false / 2026-07-28 | 178 | excluded by gate: no declared crate MSRV, so the fixed MSRV policy cannot be demonstrated |
| `poem` | 705,783 / 5,673,682 | 3.1.12, 2025-07-28, MSRV 1.85 | 4,440 / false / 2026-08-03 | 179 | qualified runner-up only: compatible license and declared MSRV; smaller practice base and older release require re-verification |

Each number in the table is from the stated endpoint, retrieved 2026-09-12: [axum crate](https://crates.io/api/v1/crates/axum), [axum versions](https://crates.io/api/v1/crates/axum/versions), [axum repository](https://api.github.com/repos/tokio-rs/axum), [axum issues](https://api.github.com/search/issues?q=repo:tokio-rs/axum+is:issue+is:open), [actix-web crate](https://crates.io/api/v1/crates/actix-web), [actix-web versions](https://crates.io/api/v1/crates/actix-web/versions), [actix-web repository](https://api.github.com/repos/actix/actix-web), [actix-web issues](https://api.github.com/search/issues?q=repo:actix/actix-web+is:issue+is:open), [warp crate](https://crates.io/api/v1/crates/warp), [warp versions](https://crates.io/api/v1/crates/warp/versions), [warp repository](https://api.github.com/repos/seanmonstar/warp), [warp issues](https://api.github.com/search/issues?q=repo:seanmonstar/warp+is:issue+is:open), [poem crate](https://crates.io/api/v1/crates/poem), [poem versions](https://crates.io/api/v1/crates/poem/versions), [poem repository](https://api.github.com/repos/poem-web/poem), and [poem issues](https://api.github.com/search/issues?q=repo:poem-web/poem+is:issue+is:open).

Well-regarded practice evidence is the Tokio project itself: axum is maintained under `tokio-rs`, exposes a Tower-compatible `Router`, and its repository publishes the graceful-shutdown example used below.  This establishes a maintained reference example, not an adoption count.  ([axum repository](https://github.com/tokio-rs/axum), [official graceful-shutdown example](https://github.com/tokio-rs/axum/blob/main/examples/graceful-shutdown/src/main.rs), retrieved 2026-09-12.)  The response-time metric was not computed: GitHub's ten newest open entries include pull requests and GitHub API pagination, while the required maintainer-attribution calculation needs comment/event sampling; do not treat the issue total as responsiveness.  ([Axum issue-list endpoint](https://api.github.com/repos/tokio-rs/axum/issues?state=open&sort=created&direction=desc&per_page=10), retrieved 2026-09-12.)

### Principles and implementation

The cross-repository agreement level is capability plus architectural pattern: all three templates must expose the same optional web-service example, keep the HTTP layer a thin adapter over the library, construct an application explicitly, inject already validated configuration and services, drain on process termination, and give developers an auto-restarting console-oriented command.  Python realizes that with a FastAPI factory/lifespan/DI and Uvicorn; the pinned TypeScript tree has no server, while the owner decision requires the later TypeScript web tier to use the same principles through Hono and tRPC rather than the same mechanism.  ([pinned Python `app.py`](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/src/py_launch_blueprint/web/app.py), [pinned Python `deps.py`](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/src/py_launch_blueprint/web/deps.py), [R69 owner record](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/OWNER-REVIEW.md), retrieved 2026-09-12.)

For Rust, define `WebState { config: Arc<ValidatedWebConfig>, projects: ProjectsService<Arc<dyn ProjectsPort>> }` at the composition root, then call `build_web_app(state) -> Router`; each handler extracts `State<WebState>` and typed request data.  This has the F330 outcome—one validated configuration instance is available to every handler and tests—without Python's lazy fallback: an axum request cannot reach a handler without a constructed `Router`, and tests construct explicit state with R01's in-memory fake.  `Router::merge`/`nest` compose domain routers in the one visible application-construction function, so resource registration remains explicit without a Python-style global registry.  ([axum `State`](https://docs.rs/axum/0.8.9/axum/extract/struct.State.html), [axum `Router`](https://docs.rs/axum/0.8.9/axum/struct.Router.html), [R01 parameter](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md), retrieved 2026-09-12.)

Minimal proposed, not executed, composition: a `GET /v1/projects` handler extracts `State(state)`, calls `state.projects`, converts the R67 domain result through R70's future error mapper, and returns typed JSON; the outer router later receives R75's middleware stack, R78's trace bridge, and R79's metrics layer.  Bind a `tokio::net::TcpListener`, call `axum::serve(listener, app).with_graceful_shutdown(shutdown_signal())`, and make `shutdown_signal` select Ctrl-C and Unix SIGTERM; Tokio supplies both signal APIs, while axum supplies the draining server future.  A duration bound is a separate R75/R51 policy: axum drains outstanding requests but its own example adds a timeout layer to prevent a request from waiting indefinitely.  ([official axum graceful-shutdown example](https://github.com/tokio-rs/axum/blob/main/examples/graceful-shutdown/src/main.rs), [Tokio shutdown guide](https://tokio.rs/tokio/topics/shutdown), [Tokio signal module](https://docs.rs/tokio/1.53.1/tokio/signal/index.html), retrieved 2026-09-12.)

No normalized benchmark was run or found for the required workload—representative JSON, validation, tracing, metrics, latency, throughput, and resource cost together—so no throughput ranking is used.  Axum's lower integration cost comes from native `State`, Router/Tower composition, and its Tokio server path; actix-web wins only if a later measured workload or a required library specifically favors Actix's runtime/middleware ecosystem.  ([axum `State`](https://docs.rs/axum/0.8.9/axum/extract/struct.State.html), [actix-web documentation](https://docs.rs/actix-web/4.15.0/actix_web/), retrieved 2026-09-12.)

BASELINE-REVIEW: F331 — make adding a resource straightforward and explicit — compose per-resource axum `Router` values with `merge`/`nest` in `build_web_app`, rather than freezing a global router-list registry — Python's list is FastAPI-specific while axum documents native router composition ([pinned Python routers](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/src/py_launch_blueprint/web/routers/__init__.py), [axum Router](https://docs.rs/axum/0.8.9/axum/struct.Router.html), retrieved 2026-09-12).

Observable acceptance criteria: `cargo test --features web` constructs `WebState` with a fake port and proves a route uses that exact config; an integration process receives SIGTERM while one bounded request completes and then exits; the dev command restarts after a source edit and produces console-formatted logs.  These are proposed P03/R32/R75/R78/R79 checks, not checks executed in this research run.  ([axum testing guidance](https://docs.rs/axum/0.8.9/axum/index.html#testing), [official graceful-shutdown example](https://github.com/tokio-rs/axum/blob/main/examples/graceful-shutdown/src/main.rs), retrieved 2026-09-12.)

### Recommendation

Use `axum` 0.8.9 over Tokio 1.53.1 for the `web` feature, explicit `WebState` injection, `axum::serve` plus Tokio signal handling for production, and externally installed `watchexec-cli` 2.7.2 for the Justfile dev restart recipe.  Make the development tool non-member runtime tooling because it is not linked into the template; its package lacks a declared MSRV, so installation must be re-verified before P03.  ([axum versions](https://crates.io/api/v1/crates/axum/versions), [Tokio versions](https://crates.io/api/v1/crates/tokio/versions), [watchexec-cli versions](https://crates.io/api/v1/crates/watchexec-cli/versions), retrieved 2026-09-12.)

### Members

#### axum

##### Landscape

`axum` is the selected established framework: version 0.8.9 has 115,597,652 recent and 466,002,347 all-time downloads, was released 2026-04-14, and its repository reports 27,095 stars, `archived: false`, a 2026-09-11 push, and 34 open issues.  ([crate](https://crates.io/api/v1/crates/axum), [versions](https://crates.io/api/v1/crates/axum/versions), [repository](https://api.github.com/repos/tokio-rs/axum), [issues](https://api.github.com/search/issues?q=repo:tokio-rs/axum+is:issue+is:open), retrieved 2026-09-12.)

##### Principles and implementation

Use `Router`, `State`, typed extractors, and `IntoResponse` at the HTTP edge, retaining R01's library-owned port and R70's future error contract outside framework types.  ([axum API](https://docs.rs/axum/0.8.9/axum/), retrieved 2026-09-12.)

##### Dominant choice

Axum is dominant here because its documented state extraction and Tokio-native serve path directly express the app-factory, test injection, and shutdown requirements.  ([axum `State`](https://docs.rs/axum/0.8.9/axum/extract/struct.State.html), [axum serve](https://docs.rs/axum/0.8.9/axum/fn.serve.html), retrieved 2026-09-12.)

##### Qualified shortlist

`actix-web` 4.15.0 and `poem` 3.1.12 remain qualified architectural alternatives, subject to full dependency-tree and RustSec verification.  ([actix-web versions](https://crates.io/api/v1/crates/actix-web/versions), [poem versions](https://crates.io/api/v1/crates/poem/versions), retrieved 2026-09-12.)

##### Excluded by gate

`warp` is excluded because its newest non-yanked version reports no `rust_version`; the direct MSRV gate is therefore not demonstrable.  ([warp versions](https://crates.io/api/v1/crates/warp/versions), retrieved 2026-09-12.)

##### Up-and-comers

`poem` is the mapped up-and-comer; it is not selected because the measured adoption indicators are markedly smaller and no workload-specific advantage was established.  ([poem crate](https://crates.io/api/v1/crates/poem), [poem repository](https://api.github.com/repos/poem-web/poem), retrieved 2026-09-12.)

##### Fit for this template

Axum keeps the CLI/library independent because handlers receive an already-composed state rather than creating transport or configuration dependencies themselves.  ([axum `State`](https://docs.rs/axum/0.8.9/axum/extract/struct.State.html), retrieved 2026-09-12.)

##### Recommendation

Select `axum = { version = "0.8.9", optional = true, default-features = false, features = ["http1", "json", "tokio"] }`; re-resolve exact features after R71/R75/R78/R79 choose their integrations.  ([axum feature manifest](https://github.com/tokio-rs/axum/blob/main/axum/Cargo.toml), retrieved 2026-09-12.)

##### Ranked runner-up

Rank `actix-web` first runner-up when an evidence-backed dependency requires Actix-specific middleware or runtime behavior.  ([actix-web documentation](https://docs.rs/actix-web/4.15.0/actix_web/), retrieved 2026-09-12.)

##### Tradeoffs

Axum couples the server feature to Tokio and Tower service composition; that is a deliberate integration cost, while its generic types can increase compile diagnostics and compile time relative to a minimal HTTP library.  Binary size and full compile-time cost are unmeasured and must be measured on the future lockfile.  ([axum feature manifest](https://github.com/tokio-rs/axum/blob/main/axum/Cargo.toml), retrieved 2026-09-12.)

##### Parameters

`web` gates axum's HTTP router, typed extraction, JSON handling, and serving API; it does not decide R58's `otel` feature or R71/R75/R79 integration crates.  ([Cargo optional dependencies](https://doc.rust-lang.org/cargo/reference/features.html#optional-dependencies), retrieved 2026-09-12.)

##### Migration implications

P03 would add a feature-gated `web` module and a feature-required web binary target; no files were created in this research run.  ([Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html), retrieved 2026-09-12.)

##### Validation strategy

Planned: build and test the web feature on Ubuntu and macOS, construct a Router with fake `WebState`, and make an in-process request; no validation was executed.  ([axum testing guidance](https://docs.rs/axum/0.8.9/axum/index.html#testing), retrieved 2026-09-12.)

##### Confidence & re-verify trigger

Medium confidence; re-verify on any axum minor release, lockfile/MSRV failure, RustSec advisory, or a benchmark showing the required instrumented workload favors Actix.  ([axum versions](https://crates.io/api/v1/crates/axum/versions), retrieved 2026-09-12.)

##### Sources

Maintenance rubric: `active` from current release and repository push; issue-response median and open RustSec advisory count are unverified because this run did not complete maintainer-response sampling and `https://rustsec.org/packages/axum.html` returned HTTP 404.  ([axum versions](https://crates.io/api/v1/crates/axum/versions), [repository](https://api.github.com/repos/tokio-rs/axum), [RustSec endpoint](https://rustsec.org/packages/axum.html), retrieved 2026-09-12.)

#### tokio

##### Landscape

`tokio` 1.53.1 has 223,873,368 recent and 960,164,351 all-time downloads, was released 2026-07-20 with MSRV 1.71, and its repository reports 33,132 stars, `archived: false`, and a 2026-09-12 push.  ([crate](https://crates.io/api/v1/crates/tokio), [versions](https://crates.io/api/v1/crates/tokio/versions), [repository](https://api.github.com/repos/tokio-rs/tokio), retrieved 2026-09-12.)

##### Principles and implementation

Tokio supplies the multi-thread runtime, listener, Ctrl-C, and Unix SIGTERM primitives used by the graceful-shutdown boundary.  ([Tokio signal](https://docs.rs/tokio/1.53.1/tokio/signal/index.html), [Tokio shutdown guide](https://tokio.rs/tokio/topics/shutdown), retrieved 2026-09-12.)

##### Dominant choice

Tokio is the necessary runtime companion because axum's documented server example binds a Tokio listener and uses Tokio signals.  ([official example](https://github.com/tokio-rs/axum/blob/main/examples/graceful-shutdown/src/main.rs), retrieved 2026-09-12.)

##### Qualified shortlist

No alternate runtime is qualified with axum for this recommendation; selecting one would change the selected framework's documented server path.  ([axum feature manifest](https://github.com/tokio-rs/axum/blob/main/axum/Cargo.toml), retrieved 2026-09-12.)

##### Excluded by gate

Inapplicable: this member is the selected runtime, not a framework candidate; its direct license and MSRV are compatible, but the future resolved dependency tree remains unverified.  ([Tokio versions](https://crates.io/api/v1/crates/tokio/versions), retrieved 2026-09-12.)

##### Up-and-comers

Inapplicable: an up-and-comer runtime is outside this stack's framework decision.  ([official example](https://github.com/tokio-rs/axum/blob/main/examples/graceful-shutdown/src/main.rs), retrieved 2026-09-12.)

##### Fit for this template

The runtime stays inside `web`, keeping default CLI/library builds free of the server runtime.  ([Cargo optional dependencies](https://doc.rust-lang.org/cargo/reference/features.html#optional-dependencies), retrieved 2026-09-12.)

##### Recommendation

Select `tokio = { version = "1.53.1", optional = true, default-features = false, features = ["macros", "rt-multi-thread", "net", "signal"] }`.  ([Tokio manifest](https://github.com/tokio-rs/tokio/blob/master/tokio/Cargo.toml), retrieved 2026-09-12.)

##### Ranked runner-up

Inapplicable: no runner-up is proposed because it would invalidate the axum server lifecycle selected above.  ([axum feature manifest](https://github.com/tokio-rs/axum/blob/main/axum/Cargo.toml), retrieved 2026-09-12.)

##### Tradeoffs

Tokio adds runtime and signal dependencies to the feature build; startup, binary-size, and compile-time impact are unmeasured until the future feature lockfile exists.  ([Tokio manifest](https://github.com/tokio-rs/tokio/blob/master/tokio/Cargo.toml), retrieved 2026-09-12.)

##### Parameters

The `signal` feature is required for Ctrl-C and SIGTERM handling; `net` is required for `TcpListener`; `macros` and `rt-multi-thread` support the proposed binary entrypoint.  ([Tokio manifest](https://github.com/tokio-rs/tokio/blob/master/tokio/Cargo.toml), retrieved 2026-09-12.)

##### Migration implications

P03 would place `#[tokio::main]` only in the feature-required web binary, not in the reusable library.  ([Tokio `main` macro](https://docs.rs/tokio/1.53.1/tokio/attr.main.html), retrieved 2026-09-12.)

##### Validation strategy

Planned: send SIGTERM to the feature-built process during a bounded route and assert listener stop plus successful drain; no process test was run.  ([official example](https://github.com/tokio-rs/axum/blob/main/examples/graceful-shutdown/src/main.rs), retrieved 2026-09-12.)

##### Confidence & re-verify trigger

Medium confidence; re-verify after a Tokio feature change, a target-matrix failure, an advisory, or an R05 decision that changes the application execution model.  ([Tokio versions](https://crates.io/api/v1/crates/tokio/versions), retrieved 2026-09-12.)

##### Sources

Maintenance rubric: `active` from release and repository push; the GitHub search endpoint returned HTTP 403 during this run, so Tokio open-issue count and response metric are unverified, and the RustSec package-page result was not reliably parseable.  ([Tokio versions](https://crates.io/api/v1/crates/tokio/versions), [repository](https://api.github.com/repos/tokio-rs/tokio), [issues endpoint](https://api.github.com/search/issues?q=repo:tokio-rs/tokio+is:issue+is:open), [RustSec endpoint](https://rustsec.org/packages/tokio.html), retrieved 2026-09-12.)

#### watchexec-cli

##### Landscape

`watchexec-cli` 2.7.2 has 8,785 recent and 659,887 all-time downloads, was released 2026-09-06, and its source repository reports 7,180 stars, `archived: false`, and a 2026-09-07 push.  ([crate](https://crates.io/api/v1/crates/watchexec-cli), [versions](https://crates.io/api/v1/crates/watchexec-cli/versions), [repository](https://api.github.com/repos/watchexec/watchexec), retrieved 2026-09-12.)

##### Principles and implementation

It supplies a restart-on-change executable for the development recipe without becoming a shipped dependency or deciding production logging.  ([watchexec documentation](https://watchexec.github.io/docs/), retrieved 2026-09-12.)

##### Dominant choice

Use `watchexec --restart -- cargo run --features web --bin <web-binary>` in the future Justfile, after setting R58's development console-log environment value.  ([watchexec documentation](https://watchexec.github.io/docs/), [pinned Python serve recipe](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/Justfile), retrieved 2026-09-12.)

##### Qualified shortlist

`cargo-watch` is a functional historical alternative but not qualified because its repository is archived; `bacon` is not qualified because its latest crate license is AGPL-3.0.  ([cargo-watch repository](https://api.github.com/repos/watchexec/cargo-watch), [bacon versions](https://crates.io/api/v1/crates/bacon/versions), retrieved 2026-09-12.)

##### Excluded by gate

`cargo-watch` is excluded by maintenance state (`archived: true`); `bacon` is excluded by the repository's compatible-license gate; `watchexec-cli` itself has unspecified `rust_version`, so it is an external dev-tool recommendation pending explicit MSRV installation verification, not a compiled template member.  ([cargo-watch repository](https://api.github.com/repos/watchexec/cargo-watch), [bacon versions](https://crates.io/api/v1/crates/bacon/versions), [watchexec-cli versions](https://crates.io/api/v1/crates/watchexec-cli/versions), retrieved 2026-09-12.)

##### Up-and-comers

`watchexec-cli` is the selected up-and-comer because it is currently released and unarchived; its lower download count means this is not a popularity-led choice.  ([watchexec-cli crate](https://crates.io/api/v1/crates/watchexec-cli), [watchexec repository](https://api.github.com/repos/watchexec/watchexec), retrieved 2026-09-12.)

##### Fit for this template

The executable preserves the required auto-rebuild/restart behavior while the Justfile controls human-readable logs through R58 rather than hard-coding a tracing subscriber.  ([watchexec documentation](https://watchexec.github.io/docs/), retrieved 2026-09-12.)

##### Recommendation

Recommend externally installed `watchexec-cli` 2.7.2, invoked as `watchexec`; it is not a Cargo dependency and does not expand the `web` feature surface.  ([watchexec-cli versions](https://crates.io/api/v1/crates/watchexec-cli/versions), retrieved 2026-09-12.)

##### Ranked runner-up

No runner-up passes all recorded checks: cargo-watch is archived and bacon's license is incompatible.  ([cargo-watch repository](https://api.github.com/repos/watchexec/cargo-watch), [bacon versions](https://crates.io/api/v1/crates/bacon/versions), retrieved 2026-09-12.)

##### Tradeoffs

The tool is an additional developer installation and its crate metadata does not declare an MSRV; binary size, compilation cost, and Ubuntu/macOS CI coverage are unverified.  ([watchexec-cli versions](https://crates.io/api/v1/crates/watchexec-cli/versions), retrieved 2026-09-12.)

##### Parameters

Inapplicable to `web-extra-surface`: it is a development executable outside Cargo feature resolution.  ([Cargo features](https://doc.rust-lang.org/cargo/reference/features.html), retrieved 2026-09-12.)

##### Migration implications

P03 would add a documented Justfile `serve` recipe and provision/check `watchexec` according to R42; no Justfile or provisioning file was created here.  ([R42 parameter](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md), retrieved 2026-09-12.)

##### Validation strategy

Planned: edit a route source file, observe one restart, request the endpoint, and inspect console-format logs on both required OS runners; no command was run.  ([watchexec documentation](https://watchexec.github.io/docs/), retrieved 2026-09-12.)

##### Confidence & re-verify trigger

Low-to-medium confidence because MSRV and target CI evidence were not located; re-verify before P03 and replace it if the installer cannot support the project MSRV on Ubuntu and macOS.  ([watchexec-cli versions](https://crates.io/api/v1/crates/watchexec-cli/versions), retrieved 2026-09-12.)

##### Sources

Maintenance rubric: `active` from a 2026-09-06 release and 2026-09-07 repository push; open-issue count, response median, advisories, unsafe posture, and platform CI are unverified because GitHub search throttled and the package metadata does not provide the remaining checks.  ([watchexec-cli versions](https://crates.io/api/v1/crates/watchexec-cli/versions), [repository](https://api.github.com/repos/watchexec/watchexec), [issues endpoint](https://api.github.com/search/issues?q=repo:watchexec/watchexec+is:issue+is:open), [RustSec endpoint](https://rustsec.org/packages/watchexec-cli.html), retrieved 2026-09-12.)

### Compatibility

Axum's own maintained example combines `axum::serve`, a Tokio `TcpListener`, and Tokio signal handling, proving the selected framework/runtime lifecycle is a supported combination; `watchexec-cli` remains outside that compiled combination.  ([official axum graceful-shutdown example](https://github.com/tokio-rs/axum/blob/main/examples/graceful-shutdown/src/main.rs), retrieved 2026-09-12.)

### Parameters

`owns web-extra-surface = named Cargo feature web; gates optional dependencies axum 0.8.9 and tokio 1.53.1 with axum http1/json/tokio and Tokio macros/rt-multi-thread/net/signal capabilities; gates the web adapter module, its feature-required server binary, web integration tests, and later web-only OpenAPI/middleware/metrics layers; does not gate the external watchexec executable; nested otel remains owned by R58.`  ([Cargo optional dependencies](https://doc.rust-lang.org/cargo/reference/features.html#optional-dependencies), [axum manifest](https://github.com/tokio-rs/axum/blob/main/axum/Cargo.toml), [Tokio manifest](https://github.com/tokio-rs/tokio/blob/master/tokio/Cargo.toml), retrieved 2026-09-12.)

`assumes http-transport-injection-seam = R01's resolved `ProjectsService<Arc<dyn ProjectsPort>>` is created once at composition and embedded in `WebState`; handlers do not select the port shape.`  ([parameter registry](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md), retrieved 2026-09-12.)

### Migration implications

Proposed P03 changes, not performed: `Cargo.toml` receives optional `axum`/`tokio` dependencies and a `web` feature; `src/web/mod.rs` owns `WebState` and `build_web_app`; `src/web/routes/*.rs` exposes per-resource routers; `src/bin/<web-binary>.rs` is feature-required and installs graceful shutdown; `Justfile` gains `serve` calling `watchexec`; and `tests/web/*` receives state-injection and process-drain coverage.  The exact package/binary name and target placement await R49; R58/R71/R75/R78/R79 own the later layer dependencies.  ([Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html), [axum Router](https://docs.rs/axum/0.8.9/axum/struct.Router.html), retrieved 2026-09-12.)

### Validation strategy

Planned commands after P03: `cargo test --features web`; `cargo build --features web --bin <web-binary>`; run `<web-binary>`, issue one JSON request using a fake-backed state in test, send SIGTERM during a bounded handler, and verify the process stops accepting work only after the handler completes; then invoke `watchexec --restart -- cargo run --features web --bin <web-binary>` and edit a route to observe restart plus console logs.  Expected outcomes are one injected config instance, one fake port call, a drained shutdown, and a development restart; none of these checks was executed because no Rust template exists.  ([official axum graceful-shutdown example](https://github.com/tokio-rs/axum/blob/main/examples/graceful-shutdown/src/main.rs), [watchexec documentation](https://watchexec.github.io/docs/), retrieved 2026-09-12.)

### Confidence & re-verify trigger

Recommendation confidence is medium for axum/Tokio architecture and low-to-medium for the development executable.  Re-verify all versions, RustSec pages, direct and resolved MSRV, unsafe posture, Ubuntu/macOS support, issue responsiveness, binary-size/compile-time measurements, and the instrumented JSON workload before implementation or if any selected crate makes a breaking release.  ([axum versions](https://crates.io/api/v1/crates/axum/versions), [Tokio versions](https://crates.io/api/v1/crates/tokio/versions), [watchexec-cli versions](https://crates.io/api/v1/crates/watchexec-cli/versions), retrieved 2026-09-12.)

### Sources

Method notes: queried crates.io crate and `/versions` endpoints for axum, actix-web, warp, poem, tokio, cargo-watch, bacon, watchexec, and watchexec-cli; GitHub repository and required search-issues endpoints; RustSec package pages; docs.rs; Cargo documentation; Tokio documentation; and maintained source examples, all retrieved 2026-09-12.  Pinned source precedent was read only through py `b08bccfb55d05f15e46a83b52c5660b1881d19f5` and ts `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`; the pinned TypeScript tree has only outbound `src/lib/api.ts`/`tests/api.test.ts`, not a server.  Unverified: full resolved dependency-tree MSRV, RustSec advisory counts where pages failed or were not parseable, unsafe posture, CI platform evidence, issue-response medians, watchexec-cli declared MSRV, and all proposed integration/benchmark measurements.  ([pinned Python source](https://github.com/smorinlabs/py-launch-blueprint/tree/b08bccfb55d05f15e46a83b52c5660b1881d19f5), [Cargo features](https://doc.rust-lang.org/cargo/reference/features.html), retrieved 2026-09-12.)
