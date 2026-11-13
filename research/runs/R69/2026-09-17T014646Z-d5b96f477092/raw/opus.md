# R69 web-framework-stack — Opus raw report

Engine: Claude Opus 5, fresh context, 2026-09-12. Item kind `bundle`, Deep tier.
Every figure below carries its endpoint and retrieval date; every retrieval date in
this report is **2026-09-12** unless stated otherwise. Local toolchain used for the
executed checks: `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)` / `cargo 1.98.0`
on macOS 26.4 aarch64. Under `msrv-policy` (stable minus 2 minors) the floor today is
therefore **1.96**, and `cargo` reported `Locking 97 packages to latest Rust 1.96
compatible versions` for the probe described under `### Validation strategy`.

### Landscape

**Category this item decides.** The inbound-HTTP adapter stack for an optional web
surface in a CLI + library + web-service template: one async HTTP framework, the
server/runtime that accepts connections, the mechanism that hands validated
configuration and the R01 application service to handlers and tests, the process
entrypoint that runs and drains the server, and the dev-server loop. It does **not**
decide any layer listed under `## Out of scope` (R70–R80, R51, R71/R82/R83/R84).

**Three-bin map of the Rust field.**

| Bin | Members found | Why in this bin |
|---|---|---|
| Built-in / first-party toolchain | `std::net` + a hand-written HTTP loop; Cargo features and `[[bin]] required-features` (the feature-gate mechanism, no crate); `#[test]` + `tests/` (the harness the acceptance checks run in) | Shipped by the language/Cargo; no crate to select. `hyper` 1.11.1 (`hyperium/hyper`, the reference HTTP implementation nearly every candidate embeds) is first-party-adjacent, not std. |
| Established industry standard | `axum` 0.8.9, `actix-web` 4.15.0, `warp` 0.4.3, `rocket` 0.5.1, `poem` 3.1.12; substrate: `tokio` 1.53.1, `hyper` 1.11.1, `tower` 0.5.3 / `tower-http` 0.7.1 | Each has ≥5 M all-time crates.io downloads, a multi-year release history and named production users (figures under `#### axum` → `Sources`). |
| Up-and-comer | `salvo` 0.96.0, `ntex` 3.12.3, `xitca-web` 0.8.3, `viz` 0.11.0, `loco-rs` 1.1.0 (batteries-included, built *on* axum), `pavex` 0.2.10 (compile-time framework generator), `dropshot` 0.17.1 (Oxide Computer's API-first framework over hyper) | All < 1 M 90-day downloads; several < 100 k. `tide` 0.16.0 (last release 2021-01-29) is the field's dead end, kept in the map as a warning, not a candidate. |

Dev-reload sub-field (F339): `cargo-watch` 8.5.3 (established, now archived),
`watchexec-cli` 2.7.2 (its maintainer-designated successor), `bacon` 3.25.0
(up-and-comer TUI runner), `systemfd` 0.4.6 + `listenfd` 1.0.2 (socket hand-off,
used by axum's own `auto-reload` example).

**Authorities used, and why each is authoritative.**

1. **The Rust project's own production web service** — `rust-lang/crates.io` at commit
   `3df99c214d640090ab38aad14ae9c34289b0dec0` (`https://api.github.com/repos/rust-lang/crates.io/commits/main`).
   Authoritative because it is (a) run by the Rust project itself, (b) the only surveyed
   codebase with this template's exact shape (Cargo workspace: web service + workers +
   library crates, `edition = "2024"`, `license = "MIT OR Apache-2.0"`), and (c) R01
   already established it as this programme's reference implementation. Its root
   `Cargo.toml` pins `axum = { version = "=0.8.9", features = ["macros", "matched-path"] }`,
   `tokio = { version = "=1.53.1", features = ["net","signal","io-std","io-util","rt-multi-thread","macros","process"] }`,
   `tower = "=0.5.3"`, `tower-http = "=0.7.1"`, `hyper = "=1.11.1"`
   (`https://raw.githubusercontent.com/rust-lang/crates.io/3df99c214d640090ab38aad14ae9c34289b0dec0/Cargo.toml`).
2. **Maintainers' own published artifacts, read at a version or tag, never a branch** —
   the `.crate` tarballs `axum 0.8.9`, `tokio 1.53.1`, `actix-web 4.15.0`, `tower-http 0.7.1`,
   `watchexec-cli 2.7.2`, `bacon 3.25.0`, `cargo-watch 8.5.3`, `listenfd 1.0.2` from
   `https://crates.io/api/v1/crates/<name>/<version>/download`, and the axum repository at
   tag `axum-v0.8.9` (`https://api.github.com/repos/tokio-rs/axum/git/ref/tags/axum-v0.8.9`
   → `31872e2e543b9cbb0e671ca7d678448b38cfb4c7`). Authoritative because they are the exact
   bytes a consumer compiles, and because the published manifest is what the MSRV and
   licence gates are read against.
3. **crates.io and GitHub REST** for every population figure (endpoints in the table
   header under `### Sources`). Authoritative as the registry of record, not as judgement.
4. **RustSec** (`https://rustsec.org/packages/<name>.html`) plus an executed
   `cargo audit` 0.22.1 against the probe lockfile. Authoritative for advisories.
5. **The Rust project's 2025 State of Rust Survey results**
   (`https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`, 7,156
   responses collected 2025-11-17 → 2025-12-17), which reports that "resource usage (slow
   compile times and storage usage) is still up there" among non-trivial problems. Used
   only for that: the survey publishes no web-framework breakdown, so it is *not* cited
   as evidence of framework share.
6. **The py source at the programme pin** `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, read
   with `git -C ~/c/py-launch-blueprint show <pin>:<path>`, for every F303/F330/F331/F338/F339
   claim about the source implementation.

A note on what is *not* treated as an authority: no single blog post, no framework
comparison article, and no TechEmpower composite. The TechEmpower results payload could
not be retrieved today (the site bundle `assets/index-rdjV3uRt.js` references
`results/20250130184741`, but `https://www.techempower.com/benchmarks/data/results/20250130184741/results.json`
returned HTTP 404 and `https://tfb-status.techempower.com/` timed out after 20 s), so **no
throughput figure from it is cited anywhere in this report**.

**Well-regarded projects surveyed, with the evidence that they are well regarded.**

| Project | Stack | Evidence of standing |
|---|---|---|
| `rust-lang/crates.io` | axum 0.8.9 + tokio 1.53.1 + tower/tower-http + utoipa-axum | The Rust project's own crate registry; `stargazers_count` 3,690 and `archived: false` per R01's retrieval 2026-09-05; manifest read at sha `3df99c2` today. |
| `apollographql/router` | `axum = { version = "0.8.1", features = ["http2"] }` | Apollo's production GraphQL router, shipped commercially; manifest read at sha `e7b2b32b5c7183475ea874b58b9f0b7d01dc32d8` (`apollo-router/Cargo.toml`, lines 72 and 308). |
| `meilisearch/meilisearch` | `actix-web = "4.14.1"` (crates/meilisearch/Cargo.toml:22, sha `a955694df9f50771b3ceaf7896754cecfbaf165d`) | Widely deployed open-source search engine; cited here as the counterweight showing actix-web's production standing, not as a point against axum. |
| `tokio-rs/axum` itself | — | 27,095 stars, `archived: false`, `pushed_at` 2026-09-11 (`https://api.github.com/repos/tokio-rs/axum`); maintained inside the `tokio-rs` organisation alongside `tokio`, which is the substrate every candidate except `ntex`/`xitca-web` sits on. |

### Principles and implementation

**The shared requirement, its source and agreement level.** From `docs/port/COMMONALITY.md`
rows F303/F330/F331/F338/F339 (all `DIVERGENT`, origin `py-only`) and
`docs/port/DIVERGENCE-ANALYSIS.md` line 217 (`harmonize: partly` — *scope level only*):
the template ships an **optional** HTTP surface that is a thin adapter over the same core
library the CLI drives; it is composed by one explicit construction function; validated
configuration is available to handlers and to tests through that construction; the
production entrypoint runs the server and drains it on a termination signal; and one
developer command starts the service with human-readable logs, distinct from the
production JSON profile. The level at which agreement is required is **capability**
(py/ts/rs must each be able to expose the core library over HTTP without a mirror data
model), not mechanism. `docs/port/DIVERGENCE-ANALYSIS.md` line 60 carries exactly one
org-level question here — whether `ts-launch-blueprint` should also ship a web tier —
answered under *Cross-repo adjudication* below.

**Essential behaviors and observable acceptance criteria.** These are requirements on
P03's template. Criteria 1–5 were exercised in this run against a probe crate (see
`### Validation strategy`); criterion 6 is stated but not run.

1. **The surface is optional and costs nothing when off.** *Observable:* with no features,
   `cargo tree -e normal` lists no `axum`, `tokio`, `hyper` or `tower`, and
   `cargo build --bins` produces no serve binary. *Executed:* base tree = 13 packages;
   `target/debug/<serve-bin>` absent after `cargo clean && cargo build --bins`.
2. **The web handler reaches the same erased service the CLI reaches, over the same
   serialisable type, with no mirror struct** (R01 criterion 6). *Observable:* the handler's
   return type names the library's own `Project`, and a real HTTP GET against a bound
   listener decodes into the library's `Vec<Project>`. *Executed:* both the in-process
   (`tower::ServiceExt::oneshot`) and the real-listener test pass.
3. **Configuration and the service are injected by explicit construction, checked by the
   compiler.** *Observable:* `build_router(state: AppState) -> Router` is the only way to
   build the app; a handler asking for a substate the app never registered fails to
   compile rather than 500ing at request time. *Executed:* `Router<S>` requires
   `S: Clone + Send + Sync + 'static` (axum 0.8.9 `src/routing/mod.rs:138-141`), and
   substates are extracted through `FromRef` impls on `AppState`.
4. **The production entrypoint drains in-flight work on SIGINT/SIGTERM and gives up after
   a configured deadline.** *Observable:* the serve future is wrapped in a timeout whose
   value comes from settings. *Executed:* a test proved axum 0.8.9's
   `with_graceful_shutdown` does **not** bound the drain itself (see below), so the
   deadline must be explicit.
5. **The `web` feature is what CI, container and docs gates select.** *Observable:* one
   feature name gates module, binary target and tests together. *Executed:* the probe's
   `[[bin]] required-features = ["web"]` behaved as specified.
6. **One dev command serves with console-formatted logs.** *Not run* — it depends on
   R58's logging contract, which is unpublished.

**Architectural alternatives compared before any crate was weighed.**

| Alternative | Shape | Verdict |
|---|---|---|
| A. No framework: `hyper` 1.11.1 + hand-written routing | `service_fn` over `hyper_util::server::conn::auto` | Rejected. It buys nothing this template needs and pushes routing, extraction and response encoding into template code that R70–R80 would each have to re-solve. It is what the candidates embed anyway (`axum` depends on `hyper` 1.1.0+, `hyper-util` 0.1.3+ — `axum-0.8.9/Cargo.toml`). |
| B. Framework with a *compile-checked* state type (`axum`'s `Router<S>`/`State<S>`) | `build_router(state) -> Router` | **Chosen.** The missing-state failure mode is a type error, not a 500; every test constructs state the same way production does, which is precisely what removes the need for py's lazy fallback. |
| C. Framework with a *runtime* type-map for state (`actix-web`'s `web::Data<T>`, or axum's own `Extension`) | `App::new().app_data(Data::new(..))` | Rejected as the primary mechanism. actix-web's own documentation states: "If route data is not set for a handler, using `Data<T>` extractor would cause a `500 Internal Server Error`" (`actix-web-4.15.0/src/data.rs:39`). A template whose whole point is to be copied should not ship a wiring mistake class that only shows up under traffic. |
| D. Batteries-included framework (`loco-rs` 1.1.0, `pavex` 0.2.10) | scaffold-generating stack | Rejected. This repository *is* the template; a second opinionated template inside it would own decisions R70–R80 are already assigned. `loco-rs` is itself built on axum, so choosing axum keeps that door open. |
| E. Framework with its own runtime layer (`actix-web`/`actix-rt`, `ntex`) | `#[actix_web::main]` + per-worker current-thread runtimes | Ranked runner-up (actix-web), rejected for this template. It is production-proven and its `HttpServer::shutdown_timeout(sec)` is a closer literal analogue of py's `timeout_graceful_shutdown`, but the template's CLI, library and future adapters live in one tokio world and `actix-web` adds `actix-rt`/`actix-server` between them (`actix-web-4.15.0/Cargo.toml:291-297`). |

**Why the recommended design preserves each principle.** The optionality principle is
carried by a Cargo feature, which is the direct analogue of py's install extra (ledger row
F017, already `ADOPT`). The "thin adapter over one contract" principle is carried by
`AppState` holding `Arc<ErasedProjectsService>` — R01's exact erased type, unchanged — and
by handlers returning `Json<Vec<Project>>` of the library's own `serde`-derived type. The
"config available to handlers and tests" principle is carried by `FromRef` substates on one
`AppState`, which is stronger than py's dependency-injection graph because it is checked at
compile time. The "drain on signal" principle is carried by
`axum::serve(..).with_graceful_shutdown(shutdown_signal())` plus an explicit deadline. The
"one dev command" principle is carried by a Justfile recipe; the *auto-reload* half of F339
is where Rust genuinely differs (below).

**F330 — what the requirement actually is, and whether Rust needs the fallback.** py's
`get_config` (`src/py_launch_blueprint/web/deps.py:37`, read at pin `b08bccfb`) falls back
to `load_config()` when `request.app.state.config` is unset, with the comment "Falls back to
loading lazily when the lifespan hasn't run (raw ASGI callers like schemathesis that bypass
the lifespan)". The requirement behind it is *"every caller of the app object — production,
tests, contract fuzzers — sees a loaded configuration"*. The fallback exists because in
FastAPI the app object can be constructed and called without its lifespan ever running, so
the invariant is unenforceable at construction time. In Rust with axum it is enforceable:
`Router<S>` cannot be turned into a service until `with_state` has supplied `S`
(`axum-0.8.9/src/routing/mod.rs:408`), so `build_router(state)` makes a configuration-less
app unrepresentable. A fallback would be dead code that hides a wiring bug. **The Rust
template must not port the lazy fallback**; it ports the invariant instead. This is recorded
as a `BASELINE-REVIEW:` line below because it changes an essential behavior recorded for the
row, not because the row's `DIVERGENT` verdict is in doubt.

**F331 — native composition versus a registry list.** py registers resources by iterating a
module-level list: `for router in ROUTERS: app.include_router(router, prefix=V1_PREFIX)`
(`web/app.py`, pin `b08bccfb`) with `ROUTERS` defined in `web/routers/__init__.py`. The
prompt's baseline review asks that native composition be compared before a registry is
accepted, keeping "explicit, straightforward resource registration" as the acceptance
behavior. Evidence from the reference implementation: `rust-lang/crates.io` composes its
entire API by chained explicit calls inside one function —
`pub fn build_axum_router(state: AppState) -> Router<()>` with `.routes(routes!(..))` per
resource and a final `.fallback(..).with_state(state)`
(`src/router.rs`, sha `3df99c2`). No registry list, no loop. In axum the native operators are
`Router::merge` (same prefix) and `Router::nest` (sub-path), and a per-resource
`pub(crate) fn router() -> Router<AppState>` composes with one line at the call site:
`.nest("/v1", projects::router())`. **Recommendation: native composition in one
`build_router` function; no `ROUTERS` registry.** Adding a noun stays one import plus one
line, which satisfies the acceptance behavior with less machinery than a registry, and a
missing registration is visible at the composition site rather than in a separate list. Note
for R71/R72: axum 0.8 changed path-parameter syntax from `/:id` to `/{id}`, and the old form
*panics* rather than silently changing behavior (`axum-0.8.9/CHANGELOG.md:121-122`).

**F338 — the entrypoint, and what graceful shutdown needs beyond the framework.** The
mechanism is `axum::serve(listener, router).with_graceful_shutdown(signal)`, with the signal
future built from `tokio::signal::ctrl_c()` and, under `#[cfg(unix)]`,
`tokio::signal::unix::signal(SignalKind::terminate())`. This is exactly what both
maintained references do: axum's own `examples/graceful-shutdown/src/main.rs` at tag
`axum-v0.8.9`, and `rust-lang/crates.io`'s `src/bin/crates-io/server.rs` (sha `3df99c2`,
lines 82-84 and 92-105), which selects over SIGINT and SIGTERM. **No crate beyond
`tokio` is needed** — `tokio`'s `signal` feature covers both signals on Unix; no
`signal-hook`, `ctrlc` or similar.

What the framework does *not* give you is py's `timeout_graceful_shutdown`. axum's drain is
unbounded by construction: after the signal, `serve` stops accepting and then awaits
`close_tx.closed()` until every connection task ends (`axum-0.8.9/src/serve/mod.rs:296-304`).
I verified this rather than inferring it: with one in-flight request to a never-completing
route, the serve future had still not resolved 1.5 s after the shutdown signal
(`graceful_shutdown_has_no_drain_deadline_of_its_own`, passing). `rust-lang/crates.io`
accepts that unbounded drain. To mirror py's settings-driven window the template wraps the
serve future: `tokio::time::timeout(Duration::from_secs(cfg.graceful_shutdown_seconds), server)`,
treating `Err(Elapsed)` as "drain deadline exceeded" and exiting non-zero. axum's own example
solves the adjacent problem differently, with a per-request `tower_http::timeout::TimeoutLayer`
— that is R75's layer to decide, and the two are complementary, not alternatives.

**F339 — the dev-server recipe, and an honest problem with auto-reload.** py's recipe
(`Justfile:291`, pin `b08bccfb`) is `uv run --extra web uvicorn ... --reload
--timeout-graceful-shutdown 5` after defaulting `<APP>_WEB_LOG_FORMAT` to `console`. Two
halves: (a) a console-log default distinct from the production JSON profile, and (b)
auto-reload. Half (a) ports cleanly and cheaply — one env var exported in the recipe, whose
name and semantics belong to R58/R77, not to this item. Half (b) does not port cleanly, for
two reasons found in evidence rather than assumed:

- The tool axum's own `auto-reload` example prescribes — "cargo install cargo-watch systemfd"
  (`examples/auto-reload/README.md` at tag `axum-v0.8.9`) — is dead. `watchexec/cargo-watch`
  is `archived: true` with `pushed_at` 2025-01-14 (`https://api.github.com/repos/watchexec/cargo-watch`),
  its last release is 8.5.3 (2024-10-02), and its own README at tag `v8.5.3` says "Cargo Watch
  is on life support: it will not receive further updates" and "**I recommend Bacon or
  Watchexec instead.**" That is a maintainer's own notice, which the rubric treats as
  `dormant`.
- Each surviving candidate fails one gate as this programme reads them: `watchexec-cli` 2.7.2
  declares no `rust-version` in its published manifest (gate 2, strict reading settled
  2026-09-11), and `bacon` 3.25.0 is `AGPL-3.0` (gate 1).

So the recommendation splits F339: the **required** recipe is a plain
`cargo run --features web --bin <app>-serve` with the console-log env default, and
auto-reload is an **optional second recipe** that requires a watcher the contributor installs
themselves, with `watchexec` named as the tool. Recorded as a `BASELINE-REVIEW:` line. The
cost/benefit differs from Python in kind, not just degree: uvicorn's `--reload` re-imports
modules in well under a second, while the Rust loop is a full incremental rebuild and process
restart — measured at **9.28 s wall / 25.61 s user CPU for a clean debug build with the web
feature** on this machine, and seconds for an incremental one.

**Cross-repo adjudication** (changes to py and ts are a follow-on project; this supplies the
rationale). The principle "one core library, optionally exposed over HTTP by a thin adapter
that emits the library's own types" is a **capability-level** agreement. py realizes it with
FastAPI + uvicorn; rs realizes it with axum + tokio; ts realizes it **not at all** —
`TS_PORT_DECISIONS.md` records no web-service decision and the pinned ts snapshot
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00` contains no web/HTTP-server code, dependency or
test (`docs/port/areas/web-service.md`, F303). Per the owner's 2026-09-04 clarification Hono
was chosen for TypeScript on ecosystem merits, which is a direction, not an implementation in
that snapshot. **Adjudication: ts's missing web tier is an absent capability, not a justified
ecosystem difference** — nothing about TypeScript prevents a Hono adapter over the existing
`CliDeps`-injected core, and the owner has already named the framework. Proposed follow-on
(not this item's to execute): ts gains a Hono adapter exposing the same core contract behind
an optional entry point, preserving F018 at capability level. What must **not** be harmonized
is the mechanism: FastAPI's `Depends`, Hono's context bindings and axum's `State<S>` are three
ecosystem-appropriate realizations of the same injection principle, and no shared low-level
value (route naming, DI shape, server library) is recommended, because neither an explicit
owner requirement nor evidence of a shared tradeoff supports one.

**Baseline-review findings.**

BASELINE-REVIEW: F330 — validated configuration is available to every caller of the app object, including tests and contract fuzzers — drop py's lazy-load fallback in the Rust template and carry the invariant in the type system instead: `build_router(state: AppState) -> Router` is the only constructor, so an app without configuration cannot be built or called; affected items: R69 (this row), R77 (`web-env-settings`, which must expose a settings value the composition root constructs, not a lazily-loadable global), R83 (`openapi-contract-fuzzing`, whose fuzzer must construct the app the same way tests do rather than bypassing a lifespan) — evidence: py's fallback exists because a raw-ASGI caller can skip the lifespan (`src/py_launch_blueprint/web/deps.py:37` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`); axum 0.8.9 makes the equivalent state unrepresentable because `Router<S>` is not a service until `with_state` supplies `S` (`axum-0.8.9/src/routing/mod.rs:408`, published artifact), and this run's probe built and exercised the app through that single constructor in both the in-process and real-listener tests.

BASELINE-REVIEW: F339 — one developer command serves the app with human-readable logs distinct from the production profile — keep the console-log half unchanged and demote the auto-reload half to an optional recipe backed by a contributor-installed watcher, rather than adding a watcher to the template's required dev toolchain; affected items: R69 (this row), R42 (`package-manager-invocation`, which governs how the optional recipe invokes the watcher), R28 (`linter-and-editor-tooling`, if a shared "install the dev tools" list is published) — evidence: axum's own prescribed tool is archived and disclaimed by its maintainer (`https://api.github.com/repos/watchexec/cargo-watch` → `archived: true`, `pushed_at` 2025-01-14; README at tag `v8.5.3`: "on life support: it will not receive further updates ... I recommend Bacon or Watchexec instead"), its named successors each fail a gate as this programme reads them (`watchexec-cli` 2.7.2 declares no `rust-version` in its published manifest; `bacon` 3.25.0 is `AGPL-3.0`), and the reload benefit is structurally smaller in Rust because the loop is a full rebuild — 9.28 s wall / 25.61 s user CPU for a clean debug build with the web feature, measured in this run.

### Recommendation

**One stack: `axum` 0.8.9 on `tokio` 1.53.1, behind an off-by-default Cargo feature named
`web`, with one `AppState` injected by `axum::extract::State` and `FromRef`, a
feature-gated second binary target whose `main` runs `axum::serve(..).with_graceful_shutdown(..)`
inside a settings-driven `tokio::time::timeout`, native `Router` composition (no registry
list), and a `just serve` recipe that runs `cargo run` with a console-log env default plus an
optional watcher-backed `serve-watch` recipe.**

```toml
[features]
web = ["dep:axum", "dep:tokio"]

[dependencies]
axum  = { version = "0.8.9",  optional = true }                        # default features: form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing
tokio = { version = "1.53.1", optional = true, features = ["rt-multi-thread", "net", "signal", "macros", "time"] }

[dev-dependencies]
tower = "0.5.3"   # only for `ServiceExt::oneshot` in the in-process handler tests

[[bin]]
name = "<app>-serve"
required-features = ["web"]
```

### Members

#### axum

##### Landscape
Established-standard bin; the framework layer. Maintained in the `tokio-rs` organisation
alongside `tokio`, on the same `hyper` 1.x substrate every established candidate except
`ntex`/`xitca-web` uses.

##### Principles and implementation
Supplies routing, typed extraction, response encoding and — through `Router<S>`/`State<S>` —
the compile-checked state mechanism that F330's requirement needs. Composes middleware as
`tower::Layer`s, which is the substrate R75 will build on without this item preselecting any
layer.

##### Dominant choice
`axum` 0.8.9. 115,597,652 90-day and 466,002,347 all-time downloads
(`GET https://crates.io/api/v1/crates/axum` → `crate.recent_downloads`, `crate.downloads`),
8,583 reverse dependencies
(`GET https://crates.io/api/v1/crates/axum/reverse_dependencies?per_page=1` → `meta.total`),
27,095 stars, `archived: false`, `pushed_at` 2026-09-11
(`GET https://api.github.com/repos/tokio-rs/axum`), 34 open issues
(`GET https://api.github.com/search/issues?q=repo:tokio-rs/axum+is:issue+is:open` →
`total_count`). It leads the field on every population measure by an order of magnitude
(next-largest established candidate: `actix-web`, 10,372,543 90-day downloads).

##### Qualified shortlist
`actix-web` 4.15.0 — 10,372,543 / 80,771,779 downloads, 24,826 stars, pushed 2026-09-10, 148
open issues, `MIT OR Apache-2.0`, `rust-version = "1.88"`; passes every gate; production use
at `meilisearch/meilisearch` (`crates/meilisearch/Cargo.toml:22`, sha `a955694`). `poem`
3.1.12 — 705,783 / 5,673,682, 4,440 stars, pushed 2026-08-03, 179 open issues,
`MIT OR Apache-2.0`, `rust-version = "1.85"`; passes the licence and MSRV gates but is
`at-risk` (below). `salvo` 0.96.0 — 901,871 / 12,544,293, 4,435 stars, pushed 2026-09-08, 20
open issues, `rust-version = "1.94"`, licence field `Apache-2.0` on the published version.

##### Excluded by gate
Gate answers for the framework candidates, applied **before** popularity was weighed
(licence and `rust-version` from each crate's newest non-yanked version via
`GET https://crates.io/api/v1/crates/<name>/versions`, 2026-09-12):

| Candidate | 1 licence | 2 MSRV (floor 1.96) | 3 advisories / `unsafe` | 4 ubuntu + macOS | 5 default features / runtime | 6 build cost |
|---|---|---|---|---|---|---|
| `axum` 0.8.9 | `MIT` — compatible with distributing `MIT OR Apache-2.0`, no patent grant | `rust-version = "1.80"`; highest declared `rust-version` anywhere in the resolved `web` tree is axum's own 1.80 (measured, `cargo metadata`) — **pass** | RustSec page HTTP 404 (no advisory); `unsafe_code = "forbid"` in the published manifest's `[lints.rust]`; zero occurrences of `unsafe` in `src/` — **pass** | axum's own CI is `ubuntu-24.04` only, no macOS runner (`.github/workflows/CI.yml` at tag `axum-v0.8.9`) — **gap**, closed for this version by this run compiling and testing axum 0.8.9 + tokio 1.53.1 on macOS 26.4 aarch64 (and by tokio's CI, which runs ubuntu/macos/windows) | defaults `form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing`; `axum::serve` requires the `tokio` feature; couples to tokio only | +39 crates and +3.6 s wall / +18.5 s user CPU on a clean debug build (measured) |
| `actix-web` 4.15.0 | `MIT OR Apache-2.0` — **pass**, strictly better | `rust-version = "1.88"` — **pass** | RustSec lists only RUSTSEC-2018-0019 against 0.x; 4 `unsafe ` occurrences in `src/` — pass, posture stated | not separately verified this run — **unverified** | pulls `actix-rt` 2.6, `actix-server` 2.7, `actix-service` 2; documents "Full Tokio compatibility" and `#[actix_web::main] // or #[tokio::main]` | not measured this run |
| `poem` 3.1.12 | `MIT OR Apache-2.0` — pass | `rust-version = "1.85"` — pass | RustSec page HTTP 404 — pass; `unsafe` posture not inspected | not verified | tokio-based | not measured |
| `salvo` 0.96.0 | `Apache-2.0` on the published version — pass | `rust-version = "1.94"` — passes today, 2 minors of headroom | RustSec page HTTP 404 — pass | not verified | tokio-based | not measured |
| `warp` 0.4.3 | `MIT` — pass | **no `rust-version` declared — FAIL** | RUSTSEC-2022-0082 historic | not verified | tokio-based | not measured |
| `rocket` 0.5.1 | `MIT OR Apache-2.0` — pass | `rust-version = "1.64"` — pass | RustSec page not retrieved | not verified | tokio-based | not measured |
| `ntex` 3.12.3 | `MIT OR Apache-2.0` — pass | `rust-version = "1.88"` — pass | RustSec page HTTP 404 | not verified | own `ntex-rt` runtime abstraction | not measured |
| `xitca-web` 0.8.3 | `Apache-2.0` — pass | **`rust-version = "1.98"` = current stable, above the 1.96 floor — FAIL** | not inspected | not verified | tokio-based | not measured |
| `viz` 0.11.0, `tide` 0.16.0, `pavex` 0.2.10 | MIT / dual / Apache-2.0 — pass | **no `rust-version` declared — FAIL** | not inspected | not verified | — | — |

Exclusions that follow:
- `warp` 0.4.3 (2026-05-04) — **gate 2**: the published version declares no `rust-version`
  (`GET https://crates.io/api/v1/crates/warp/versions` → newest non-yanked, `rust_version: null`).
  Under the strict reading settled 2026-09-11 it cannot clear the MSRV gate. It also carries
  RUSTSEC-2022-0082 in its history (`https://rustsec.org/packages/warp.html`), patched in
  current versions.
- `viz` 0.11.0 and `tide` 0.16.0 — **gate 2**, same reason (`rust_version: null`); `tide`'s
  last release is 2021-01-29, which is dormant on its own.
- `pavex` 0.2.10 — **gate 2**, `rust_version: null`.
- `rocket` 0.5.1 — excluded on the **maintenance rubric, not on a gate** (it passes gate 1,
  `MIT OR Apache-2.0`, and gate 2, `rust-version = "1.64"`): last release 2024-05-23
  (28 months), `pushed_at` 2025-12-28 (`https://api.github.com/repos/rwf2/Rocket`); a release
  gap that long with a quiet repository is `at-risk`, which disqualifies it as a template's
  load-bearing dependency.
- `salvo` 0.96.0 — passes the gates but is **excluded on MSRV policy fit**: `rust-version = "1.94"`
  against today's floor of 1.96 leaves two minors of headroom, and a project that tracks the
  compiler that closely can push a patch release past the floor between the template's minor
  releases. Same reasoning R01 applied to `shaku`.
- `xitca-web` 0.8.3 — **gate 2 boundary**: `rust-version = "1.98"` equals current stable, i.e.
  above the 1.96 floor the template must compile on. Excluded.
- `ntex` 3.12.3 — passes gates 1–3 (`MIT OR Apache-2.0`, `rust-version = "1.88"`, no RustSec
  page) but is excluded on adoption and fit: 100,042 90-day downloads, 2,538 stars, and its own
  runtime abstraction (`ntex-rt`) on top of tokio/compio, which is a second runtime story for a
  template whose CLI and library already have one.

##### Up-and-comers
`loco-rs` 1.1.0 (109,887 / 649,453 downloads, `rust-version = "1.94"`, Apache-2.0) is a
Rails-shaped stack built **on axum** — choosing axum keeps it available to template users
without importing its opinions. `dropshot` 0.17.1 (128,545 / 849,737, `rust-version = "1.85"`,
Apache-2.0) is Oxide Computer's API-first framework with first-class OpenAPI generation; it is
well-engineered and single-org, and its OpenAPI strength is relevant to R71 but does not
outweigh axum's adoption or the ecosystem R70–R80 will draw on. `xitca-web` and `pavex` are
watch-list entries, both excluded by gate above.

##### Fit for this template
Best fit on four counts specific to CLI + library + web service. (1) The state mechanism is
compile-checked, so the template — which exists to be copied and edited — cannot ship a
wiring mistake that only appears at request time. (2) It is a library, not a framework
runtime: `Router` is a `tower::Service`, so an in-process test is
`router.oneshot(request)` with no server, no port and no async fixture — verified in this run.
(3) It adds no runtime of its own; the template's CLI, library and web surface share one
tokio. (4) The layers R70–R80 need already exist against axum in the same ecosystem
(`tower-http` 0.7.1 for timeouts/tracing/CORS, `utoipa-axum` for OpenAPI — both pinned
alongside axum in `rust-lang/crates.io`'s manifest), which is the single largest integration-cost
difference between axum and every other candidate.

##### Recommendation
`axum = { version = "0.8.9", optional = true }`, default features left on
(`form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing` —
`axum-0.8.9/Cargo.toml`). `json` is what `Json<T>` needs; `tokio` is what `axum::serve` needs
(`#[cfg(all(feature = "tokio", any(feature = "http1", feature = "http2")))]`,
`src/serve/mod.rs:236`); `tracing` emits axum's own spans into whatever subscriber R58
selects. Add `http2` only if a consumer needs it; it is off by default.

##### Ranked runner-up
`actix-web` 4.15.0. It wins if the owner weights (a) a built-in settings-driven drain window —
`HttpServer::shutdown_timeout(sec)`, default 30 s, "workers still alive after the timeout are
force dropped" (`actix-web-4.15.0/src/server.rs:424-433`) — above compile-checked state, or
(b) dual `MIT OR Apache-2.0` licensing of the framework crate itself above ecosystem
integration. Its cost is the `Data<T>` runtime failure mode and the `actix-rt`/`actix-server`
layer between the template and tokio.

##### Tradeoffs
`axum` is `MIT`-only, not dual-licensed — compatible with distributing an
`MIT OR Apache-2.0` project, but without Apache-2.0's explicit patent grant, which is the
owner's stated reason for the dual licence (`docs/port/PARAMETERS.md`). This is not
discriminating between candidates: `tokio` and `hyper` are also `MIT`-only, so **every**
Rust async web stack, `actix-web`'s included, has MIT-only crates at its base (measured: of
the 52 non-dev packages in the probe's `web` tree, 17 are MIT-only). Second tradeoff:
axum's last release is 0.8.9 (2026-04-14), five months ago, which the rubric makes a trigger
to investigate — investigation shows an active repository (`pushed_at` 2026-09-11), 34 open
issues, a median 0.41 days to first maintainer response over the 10 most recently opened
issues (5 of 10 still unanswered, window 2026-06-16 → 2026-09-07) and a normal patch cadence
on the 0.8 line (0.8.8 on 2025-12-20, 0.8.7 on 2025-11-14). Verdict **active**. Third: the
0.7 → 0.8 path-syntax break (`/:id` → `/{id}`) shows this crate does break APIs at minor
versions; the mitigation is the exact pin plus a `cargo update` gate, not avoidance.

##### Parameters
Contributes to `web-extra-surface`: `dep:axum` is one of the two crates the `web` feature
gates. Consumes nothing.

##### Migration implications
New `src/web/` module tree in the crate that hosts the binaries (placement is R02's):
`mod.rs` (`AppState`, `build_router`), `routes/projects.rs`, `routes/ops.rs`.

##### Validation strategy
Executed: `cargo test --features web` with an in-process `oneshot` test and a real-listener
test, both decoding into the library's `Vec<Project>` — 3 tests, 3 passed. Proposed for P03:
one `oneshot` test per route plus `cargo hack --each-feature check`.

##### Confidence & re-verify trigger
High. Re-verify if axum publishes 0.9 (a minor bump has broken routing syntax before), if its
declared `rust-version` rises above the floor, or if a RustSec advisory is opened against it.

##### Sources
`https://crates.io/api/v1/crates/axum` and `/versions` (2026-09-12);
`https://api.github.com/repos/tokio-rs/axum` (2026-09-12);
`https://api.github.com/search/issues?q=repo:tokio-rs/axum+is:issue+is:open` (2026-09-12);
`https://rustsec.org/packages/axum.html` → HTTP 404, which RustSec serves for a crate with no
advisory (2026-09-12); published artifact `axum 0.8.9` from
`https://crates.io/api/v1/crates/axum/0.8.9/download` (Cargo.toml, `src/serve/mod.rs`,
`src/routing/mod.rs`, `src/extract/state.rs`, `CHANGELOG.md`); repository at tag `axum-v0.8.9`
(`examples/graceful-shutdown/src/main.rs`, `examples/auto-reload/README.md`,
`.github/workflows/CI.yml`); `https://docs.rs/axum/0.8.9/axum/fn.serve.html` (HTTP 200,
2026-09-12); `https://raw.githubusercontent.com/rust-lang/crates.io/3df99c214d640090ab38aad14ae9c34289b0dec0/Cargo.toml`;
`https://raw.githubusercontent.com/apollographql/router/e7b2b32b5c7183475ea874b58b9f0b7d01dc32d8/apollo-router/Cargo.toml`.

#### tokio

##### Landscape
Established-standard bin, and the substrate under every shortlisted framework except
`ntex`/`xitca-web`. This member covers three roles the item must fill beyond routing: the
async runtime, the TCP listener `axum::serve` accepts on, and OS signal handling for
graceful shutdown.

##### Principles and implementation
F338's "settings-driven graceful shutdown" needs a process that (a) reacts to SIGINT and
SIGTERM, (b) stops accepting while draining, and (c) gives up after a deadline. tokio
supplies (a) via `tokio::signal`, axum supplies (b), and tokio supplies (c) via
`tokio::time::timeout`. No fourth crate is required.

##### Dominant choice
`tokio` 1.53.1 (2026-07-20). 223,873,368 90-day and 960,164,351 all-time downloads
(`GET https://crates.io/api/v1/crates/tokio`), 72,140 reverse dependencies
(`/reverse_dependencies?per_page=1` → `meta.total`), 33,132 stars, `archived: false`,
`pushed_at` 2026-09-12 (`GET https://api.github.com/repos/tokio-rs/tokio`), 316 open issues
(search API). Issue responsiveness over the 10 most recently opened issues: median 0.03 days
to first maintainer response, 3 unanswered (window 2026-08-27 → 2026-09-09). Maintenance
`active`.

##### Qualified shortlist
`async-std` 1.13.2 (10,221,871 / 92,377,314 downloads, crates.io `updated_at` 2025-08-15) and
`smol` are the only general alternatives. Neither is a real candidate here: `axum` depends on
`tokio` through `hyper-util`'s `tokio` feature (`axum-0.8.9/Cargo.toml`, `[features] tokio`),
so selecting axum selects tokio.

##### Excluded by gate
`async-std` — excluded on fit, not gate: choosing it would mean choosing a non-tokio
framework, and the framework member already resolved that. Gate answers for `tokio` 1.53.1:
(1) licence `MIT` — compatible, no patent grant, same posture as `axum`/`hyper`; (2)
`rust-version = "1.71"`, far inside the 1.96 floor — pass; (3) RustSec lists historic
advisories only (`RUSTSEC-2025-0023`, `RUSTSEC-2023-0001`, `RUSTSEC-2021-0072` and older,
`https://rustsec.org/packages/tokio.html`), and an executed `cargo audit` 0.22.1 against the
probe's lockfile — 98 crates, advisory database of 1,243 advisories — exited 0 with no
findings; `unsafe` is used pervasively and by design (1,066 occurrences of `unsafe ` in
`src/` of the published 1.53.1 artifact), which is inherent to a runtime and is why the
template's own `unsafe` policy (R06) applies to template code, not to this dependency; (4)
tokio's CI matrix is `ubuntu-latest`, `macos-latest`, `windows-latest`
(`.github/workflows/ci.yml` at tag `tokio-1.53.1`) — **pass, and it covers the gap in axum's
own CI**; (5) `default = []` — every feature is opted into explicitly
(`tokio-1.53.1/Cargo.toml`); (6) build cost is bundled into the +39-crate measurement under
`#### axum`.

##### Up-and-comers
None worth listing. `compio`, `monoio` and `glommio` are thread-per-core runtimes aimed at
workloads this template does not have, and none is supported by the recommended framework.

##### Fit for this template
The feature set is chosen, not inherited: `rt-multi-thread` (the server), `net` (the
listener), `signal` (SIGINT/SIGTERM), `macros` (`#[tokio::main]`), `time` (the drain
deadline). `rust-lang/crates.io` pins a nearly identical set —
`["net","signal","io-std","io-util","rt-multi-thread","macros","process"]` — for the same
reasons. Because `tokio` is optional and gated by `web`, a template user who never enables
the feature gets a CLI with no runtime at all, which is the measured 13-package base tree.

##### Recommendation
`tokio = { version = "1.53.1", optional = true, features = ["rt-multi-thread", "net", "signal", "macros", "time"] }`.
If R05 selects an async I/O seam, `rt-multi-thread` and `macros` move from the `web` feature
to the base dependency set and the feature list widens; that is R05's call, not this item's.

##### Ranked runner-up
None. Under axum there is no runner-up; under `actix-web` the equivalent member would be
`actix-rt` 2.6 on tokio.

##### Tradeoffs
`MIT`-only (see `#### axum` → `Tradeoffs`). Large `unsafe` surface by construction. It is the
single biggest contributor to the web feature's compile cost. Against that: it is the most
depended-upon crate in the ecosystem (72,140 reverse dependencies) and the one every
alternative in this report would also pull in.

##### Parameters
Contributes to `web-extra-surface`: `dep:tokio` is the second of the two crates the `web`
feature gates, with the feature list above.

##### Migration implications
`Cargo.toml` only, plus `src/bin/<app>-serve.rs`'s `#[tokio::main]`.

##### Validation strategy
Executed: the probe's `shutdown_signal()` compiled with `tokio::signal::ctrl_c()` and
`#[cfg(unix)] tokio::signal::unix::signal(SignalKind::terminate())`, and
`tokio::time::timeout` bounded the serve future in the passing drain test. Proposed for P03:
a CI test that sends SIGTERM to the running binary and asserts the process exits 0 within the
configured window.

##### Confidence & re-verify trigger
High. Re-verify on a tokio 2.0 announcement, on a RustSec advisory affecting 1.53.x, or if
R05 changes where tokio sits in the manifest.

##### Sources
`https://crates.io/api/v1/crates/tokio`, `/versions`, `/reverse_dependencies?per_page=1`
(2026-09-12); `https://api.github.com/repos/tokio-rs/tokio` and the issue search endpoint
(2026-09-12); `https://rustsec.org/packages/tokio.html` (2026-09-12); published artifact
`tokio 1.53.1`; `https://raw.githubusercontent.com/tokio-rs/tokio/tokio-1.53.1/.github/workflows/ci.yml`;
executed `cargo audit` 0.22.1 log in this run's scratch evidence.

#### Application-state injection (`State` + `FromRef` over one `AppState`)

##### Landscape
Pattern member; crate figures are `inapplicable` because the mechanism is supplied by the
already-counted `axum` crate and by `std::sync::Arc` — there is no separate crate to weigh.
Built-in/first-party bin: `Arc`, ordinary structs. Framework-supplied: `axum::extract::State`,
`axum::extract::FromRef`, `axum::Extension`. Rejected third-party bin: dependency-injection
containers, already excluded by R01 for the whole repository.

##### Principles and implementation
F330's requirement — every caller of the app sees validated configuration and the same
application service the CLI uses — is met by making the app object unconstructable without
them. One `#[derive(Clone)] pub struct AppState { config: Arc<WebConfig>, projects: Arc<ErasedProjectsService> }`
is passed to `build_router`, which ends in `.with_state(state)`. Handlers ask for exactly
the substate they need through `FromRef` impls:

```rust
#[derive(Clone)]
pub struct AppState { pub config: Arc<WebConfig>, pub projects: Arc<ErasedProjectsService> }
impl FromRef<AppState> for Arc<WebConfig> { fn from_ref(s: &AppState) -> Self { s.config.clone() } }
impl FromRef<AppState> for Arc<ErasedProjectsService> { fn from_ref(s: &AppState) -> Self { s.projects.clone() } }

async fn list_projects(
    State(svc): State<Arc<ErasedProjectsService>>,
    Query(q): Query<ProjectQuery>,
) -> Result<Json<Vec<Project>>, (StatusCode, String)> { /* ... */ }
```

##### Dominant choice
`State<S>` with `FromRef` substates. This is axum's own documented mechanism
(`axum-0.8.9/src/extract/state.rs:171-190`: "`State` only allows a single state type but you
can use `FromRef` to extract substates") and the shape `rust-lang/crates.io` uses
(`build_axum_router(state: AppState) -> Router<()>` ending in `.with_state(state)`,
`src/router.rs` at sha `3df99c2`).

##### Qualified shortlist
`Extension<T>` (a request-extension type map, axum's older mechanism —
`rust-lang/crates.io` still uses it for one value, `get(openapi::handler).layer(Extension(Arc::new(openapi)))`);
and a module-level `OnceLock<Config>` singleton.

##### Excluded by gate
Gates 1–6 are `inapplicable` to a pattern member: there is no crate, so there is no licence,
no declared `rust-version`, no advisory page, no CI matrix, no default-feature set and no
separable build cost. Excluded on fit instead: `Extension<T>` moves a wiring mistake from
compile time to request time (it rejects with 500 when the layer is absent), which is the same
failure class this item rejects `actix-web`'s `Data<T>` for; a `OnceLock` singleton makes two
differently-configured apps in one test binary impossible and reintroduces exactly the
global-state ambiguity py's lazy fallback exists to paper over.

##### Up-and-comers
None. Container crates (`shaku`, `dill`, `nject`, `teloc`) were surveyed and rejected
repository-wide by R01; nothing in the web layer changes that analysis.

##### Fit for this template
Two properties matter for a template. First, tests construct state exactly the way production
does — the probe's tests build `AppState` and call `build_router` with no server and no
lifespan, which is what removes py's fallback. Second, it composes with R01 without changing
it: holding `Arc<ErasedProjectsService>` satisfies axum's `S: Clone + Send + Sync + 'static`
bound (`axum-0.8.9/src/routing/mod.rs:138-141`) using only `Arc`'s unconditional `Clone`, so
`ProjectsService` itself needs no new derive and R01's published parameter value is unchanged.
I verified this specifically: the probe passes with `ProjectsService` **not** deriving `Clone`.
(The alternative — deriving `Clone` on `ProjectsService<P>` and storing the service by value —
also works but adds a `P: Clone` bound that library consumers would inherit.)

##### Recommendation
One `AppState` with `Arc`-held members, `FromRef` impls per substate,
`build_router(state) -> Router` as the only constructor, and **no lazy-load fallback**.
The typed settings struct itself (`WebConfig` above) is R77's to define; this item requires
only that the composition root constructs it and hands it in.

##### Ranked runner-up
`Extension<T>` for values that genuinely are optional and route-scoped — the pattern
`rust-lang/crates.io` reserves it for. It should never carry the config or the service.

##### Tradeoffs
`FromRef` costs one small impl per substate (or one `#[derive(FromRef)]` with axum's `macros`
feature). Handlers that need two substates take two `State` arguments. In exchange, a handler
referencing state the app never registered does not compile.

##### Parameters
Contributes to `web-extra-surface` (the `src/web/` module the feature gates contains
`AppState` and `build_router`). Consumes `http-transport-injection-seam` (R01) — see
`### Parameters`.

##### Migration implications
`src/web/mod.rs` (new): `AppState`, its `FromRef` impls, `build_router`.

##### Validation strategy
Executed: both handler tests obtain the service through `State` and return the library's own
`Project` type; the real-listener test decoded `Vec<Project>` from live HTTP. Proposed for
P03: a `compile_fail` doctest showing that a handler asking for an unregistered substate does
not compile.

##### Confidence & re-verify trigger
High for the mechanism; medium for the exact field set, which R77 (settings) and R58 (logging)
will refine. Re-verify if axum changes the `State`/`FromRef` API in 0.9.

##### Sources
`axum 0.8.9` published artifact (`src/extract/state.rs`, `src/routing/mod.rs`);
`actix-web 4.15.0` published artifact (`src/data.rs:39`);
`https://raw.githubusercontent.com/rust-lang/crates.io/3df99c214d640090ab38aad14ae9c34289b0dec0/src/router.rs`;
py at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5` (`src/py_launch_blueprint/web/deps.py:37`);
this run's executed probe.

#### Router composition (F331 — native, no registry list)

##### Landscape
Pattern member; crate figures `inapplicable` (no crate). The field of shapes: (a) py's
module-level registry list plus a loop; (b) native chained composition in one function; (c) a
registry of function pointers (`&[fn() -> Router<AppState>]`); (d) an inventory/linkme-style
link-time plugin registry.

##### Principles and implementation
The acceptance behavior the baseline review preserves is "explicit, straightforward resource
registration": adding a noun should be one obvious edit, and a forgotten registration should
be easy to see. Native composition satisfies it with `Router::nest` for sub-paths and
`Router::merge` for same-prefix merges, with one `pub(crate) fn router() -> Router<AppState>`
per resource module.

##### Dominant choice
Native composition. Evidence: `rust-lang/crates.io` registers ~30 resources by chained
explicit calls inside `build_axum_router` and keeps no registry list
(`src/router.rs`, sha `3df99c2`).

##### Qualified shortlist
A `const ROUTERS: &[fn() -> Router<AppState>]` slice iterated in `build_router` — the literal
translation of py's `ROUTERS`.

##### Excluded by gate
Gates `inapplicable` (pattern member, no crate). Excluded on fit: a function-pointer registry
adds an indirection that buys nothing in a language where the composition site is already one
line per resource, and a link-time registry (`inventory`, `linkme`) makes route registration
invisible in source order — unacceptable in a template whose readers are learning the layout.

##### Up-and-comers
`utoipa-axum`'s `routes!` macro, which registers a route and its OpenAPI operation together
(`rust-lang/crates.io` uses it). Named here only because it is the shape R71 will evaluate;
this item does not select it.

##### Fit for this template
A template optimises for legibility over extensibility machinery. `.nest("/v1", projects::router())`
plus the operational routes at the root reads top-to-bottom and mirrors py's URL layout
(`V1_PREFIX` for business routes, unversioned `/healthz` and `/readyz`), which keeps R80's
probe endpoints and R71's spec structure unsurprising.

##### Recommendation
One `pub fn build_router(state: AppState) -> Router` that nests a per-resource
`Router<AppState>` under `/v1`, registers operational routes at the root, and ends with
`.with_state(state)`. No registry list, no macro.

##### Ranked runner-up
The function-pointer slice, if the template ever ships enough resources that the composition
function becomes unreadable — a condition this template will not reach.

##### Tradeoffs
Adding a resource touches one more file than a registry would (the composition function
itself). That is the point: the edit is where the reader looks.

##### Parameters
Contributes to `web-extra-surface` (the gated module's shape).

##### Migration implications
`src/web/routes/projects.rs`, `src/web/routes/ops.rs`, each exposing `router()`; one
`.nest`/`.route` line each in `src/web/mod.rs`.

##### Validation strategy
Executed: the probe nests `/v1/projects` under a router built exactly this way, and the tests
hit `/v1/projects?name_contains=al` through it. Proposed: a route-inventory test asserting the
set of registered paths, which R71's OpenAPI snapshot will subsume.

##### Confidence & re-verify trigger
High. Re-verify if R71 selects an OpenAPI crate whose registration macro requires a different
composition shape.

##### Sources
`https://raw.githubusercontent.com/rust-lang/crates.io/3df99c214d640090ab38aad14ae9c34289b0dec0/src/router.rs`;
`axum 0.8.9` published artifact (`src/routing/mod.rs`, `CHANGELOG.md:121-122` for the 0.8 path
syntax change); py at pin `b08bccfb` (`src/py_launch_blueprint/web/app.py`,
`web/routers/__init__.py`).

#### `web` Cargo feature and target shape (the `web-extra-surface` value)

##### Landscape
Pattern member; crate figures `inapplicable` (Cargo features are a built-in mechanism, no
crate). Built-in/first-party bin: `[features]`, `dep:` syntax, `optional = true`,
`[[bin]] required-features`, `#[cfg(feature = "...")]`, `--features` / `--all-features` /
`cargo hack --each-feature`. There is no established-standard or up-and-comer bin: no crate
competes with Cargo's own feature system, which is why F017 recorded "nothing to choose"
about the feature's existence. This member decides its *shape*.

##### Principles and implementation
The principle is py's: the library and CLI always install; the web service is opt-in
(`pyproject.toml` `[project.optional-dependencies] web = [...]`, pin `b08bccfb`), and a
heavier opt-in (`otel`) nests beyond it. In Cargo the analogue is one additive feature that
gates the web dependencies, the web module, the serve binary and the web tests together, with
nested features for heavier opt-ins.

##### Dominant choice
A single `web` feature. Evidence that a single named feature is the idiomatic unit for an
optional surface: `rust-lang/crates.io`'s own `crates_io_github` crate gates its mock support
as `[features] mock = ["dep:mockall"]` (cited in R01's decision), and axum itself expresses
every optional capability the same way (`[features] http2 = [...]`, `macros = ["dep:axum-macros"]`).

##### Qualified shortlist
A nested set — `web = ["web-server", "web-openapi", ...]` — and a separate workspace crate
(`<app>-web`) instead of a feature.

##### Excluded by gate
Gates 1–6 `inapplicable` (no crate). Excluded on fit: (a) a nested feature set multiplies the
combinations CI must build (`cargo hack --each-feature` cost) for a surface that ships as one
unit, and none of the nine downstream consumers asks for finer granularity; (b) a separate
workspace crate is a real alternative but it is **R02's decision**, not this item's — R02
(`crate-boundary-enforcement`) owns crate boundaries, and this item's value is written so that
it survives either outcome (the feature lives on whichever crate hosts the binary targets).

##### Up-and-comers
None.

##### Fit for this template
The nine consumers need one name and a precise content list. A single `web` feature gives
R11 one CI job axis (`--features web`), R32 one test-tier selector, R37 one path predicate for
the OpenAPI snapshot hook, R51 one build flag for the container image, R58 one boundary for
the web logging profile, and R71/R82/R83/R84 one way to make the spec-generating binary exist.
Measured cost of the boundary: base build = 13 non-dev packages, `--features web` = 52; clean
debug build 5.69 s → 9.28 s wall (7.12 s → 25.61 s user CPU); release binary 2,001,600 bytes
(1,574,392 stripped).

##### Recommendation
```toml
[features]
web = ["dep:axum", "dep:tokio"]
# heavier opt-ins nest on top rather than widening `web`:
# otel    = ["web", ...]   # R78
# metrics = ["web", ...]   # R79

[[bin]]
name = "<app>-serve"
required-features = ["web"]
```
with `#[cfg(feature = "web")] pub mod web;` in the library root and
`#![cfg(feature = "web")]` at the top of each web integration test file.

##### Ranked runner-up
A separate `<app>-web` workspace crate, if R02 decides crate boundaries that way. The
parameter value below is written to hold under either.

##### Tradeoffs
One feature means a consumer cannot take the router without the server; nothing in the
downstream set wants that. Feature-gated modules need `cargo hack --each-feature` (or at
minimum a `--no-default-features` and a `--all-features` job) to keep both configurations
compiling — a CI cost R11 inherits.

##### Parameters
**Owns the value of `web-extra-surface`** — stated in full under `### Parameters`.

##### Migration implications
`Cargo.toml` (`[features]`, two optional dependencies, one `[[bin]]`), `src/lib.rs` (one
`#[cfg]`-gated `pub mod web;`), `tests/web_*.rs` (file-level `#![cfg]`).

##### Validation strategy
Executed: with the feature off, `cargo tree -e normal` showed no `axum`/`tokio`/`hyper`/`tower`
and `cargo clean && cargo build --bins` produced no serve binary; with it on, the binary built
and the gated tests ran. Proposed for P03: a CI job matrix of `--no-default-features` and
`--features web`, plus `cargo hack --each-feature check`.

##### Confidence & re-verify trigger
High for the shape; the **crate that hosts the feature** is contingent on R02. Re-verify when
R02 resolves, and when R78/R79 define their own features.

##### Sources
py `pyproject.toml` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`;
`docs/port/COMMONALITY.md` row F017; The Cargo Book, "Features"
(`https://doc.rust-lang.org/cargo/reference/features.html`, 2026-09-12) for `dep:`,
`optional`, and `required-features` semantics; this run's executed probe.

#### Production entrypoint and graceful shutdown (F338)

##### Landscape
Pattern member with one crate implication (`tokio`'s `signal` and `time` features, already
counted). Built-in/first-party bin: `std::process::ExitCode`, `#[cfg(unix)]`. Framework/runtime
bin: `axum::serve(..).with_graceful_shutdown(..)`, `tokio::signal`, `tokio::time::timeout`.
Third-party bin surveyed and not needed: `signal-hook` / `ctrlc` (OS signals), `hyper-util`'s
`GracefulShutdown` (lower-level equivalent used when driving hyper directly).

##### Principles and implementation
py's entrypoint is settings-only with no CLI flags: `uvicorn.run(..., host=settings.host,
port=settings.port, timeout_graceful_shutdown=settings.graceful_shutdown_seconds)`
(`src/py_launch_blueprint/web/__main__.py:37,42`, pin `b08bccfb`; the module docstring states
"Everything is settings-driven, no CLI flags"). The Rust analogue is a feature-gated binary
target whose `main` reads the typed settings, builds the state, binds the listener, serves with
a shutdown signal, and bounds the drain:

```rust
#[tokio::main]
async fn main() -> std::process::ExitCode {
    let cfg = WebConfig::from_env()?;                        // R77 owns this type
    let state = AppState { config: Arc::new(cfg.clone()), projects: Arc::new(production_service()) };  // R01's composition root
    let listener = tokio::net::TcpListener::bind((cfg.host.as_str(), cfg.port)).await?;
    let server = axum::serve(listener, build_router(state)).with_graceful_shutdown(shutdown_signal());
    match tokio::time::timeout(Duration::from_secs(cfg.graceful_shutdown_seconds), server).await { .. }
}
```

##### Dominant choice
`axum::serve(..).with_graceful_shutdown(shutdown_signal())` with a `tokio::signal`-built
signal future. Both maintained references do exactly this: axum's
`examples/graceful-shutdown/src/main.rs` at tag `axum-v0.8.9` (ctrl_c + `#[cfg(unix)]`
SIGTERM, selected with `tokio::select!`), and `rust-lang/crates.io`'s
`src/bin/crates-io/server.rs` at sha `3df99c2` (SIGINT + SIGTERM via
`tokio::signal::unix::signal`, lines 82-84 and 92-105).

##### Qualified shortlist
`actix-web`'s `HttpServer::shutdown_timeout(sec)` (default 30 s), which is the only surveyed
framework with the drain deadline built in; driving `hyper-util`'s `GracefulShutdown`
directly; installing `signal-hook` for signals.

##### Excluded by gate
Gates `inapplicable` for the pattern; the crates it would have added are excluded on fit:
`signal-hook`/`ctrlc` add a dependency for something `tokio`'s `signal` feature already does
on both target platforms, and `hyper-util`'s graceful API is the layer `axum::serve` exists to
wrap.

##### Up-and-comers
None.

##### Fit for this template
Three details matter and are all verified. (1) **The drain is unbounded unless you bound it.**
`WithGracefulShutdown` stops accepting on the signal, then awaits `close_tx.closed()` with no
deadline (`axum-0.8.9/src/serve/mod.rs:296-304`); this run's test held one request open on a
never-completing route and the serve future had not resolved 1.5 s after the signal
(`graceful_shutdown_has_no_drain_deadline_of_its_own`, passing). Wrapping the future in
`tokio::time::timeout(settings.graceful_shutdown_seconds, ..)` is therefore a template
addition, not a port of an existing axum feature — `rust-lang/crates.io` itself does not bound
it. (2) **Both signals are needed**: containers send SIGTERM (R51), terminals send SIGINT; the
`#[cfg(unix)]` split keeps the code compiling if the OS matrix ever widens. (3) The exit path
returns `ExitCode` from `main` rather than calling `process::exit`, which is what R67's
published error contract requires, and the drain-deadline branch is a failure exit.

##### Recommendation
A feature-gated `[[bin]]` (name `<app>-serve`) whose `main` is `#[tokio::main]`, builds state
through R01's composition root, serves with `with_graceful_shutdown`, and wraps the serve
future in `tokio::time::timeout(Duration::from_secs(settings.graceful_shutdown_seconds), ..)`.
No CLI flags on this binary — every knob is an environment variable, as in py; the CLI binary
keeps its own flags.

##### Ranked runner-up
A `serve` subcommand on the existing CLI binary instead of a second binary. Rejected as the
primary because it would put `tokio` and `axum` in the default CLI build unless the subcommand
were itself `#[cfg(feature = "web")]`-gated, and because py's shape
(`python -m py_launch_blueprint.web`, a separate entry point used by the Dockerfile) is the
behavior R51's container image expects. It becomes the better option only if the owner wants a
single shipped binary.

##### Tradeoffs
The drain deadline is our own code (about six lines) rather than a framework setting — the one
place `actix-web` is ergonomically ahead. Killing the serve future at the deadline drops
in-flight connections abruptly; the gentler complement is a per-request timeout layer, which is
R75's (axum's own example uses `tower_http::timeout::TimeoutLayer` for exactly this).

##### Parameters
Contributes to `web-extra-surface` (the gated `[[bin]]`). Consumes R77's settings type and
R01's composition root; both are named, neither is decided here.

##### Migration implications
`src/bin/<app>-serve.rs` (new), `src/web/mod.rs` (`shutdown_signal`), `Cargo.toml`
(`[[bin]] required-features`).

##### Validation strategy
Executed: the probe binary compiles only with `--features web`, and the drain-deadline
behavior was measured by the passing test above. Proposed for P03: a CI test that starts the
binary, issues a slow request, sends SIGTERM, and asserts both the response completion and the
process exit within the configured window.

##### Confidence & re-verify trigger
High. Re-verify if axum adds a built-in drain deadline (it would replace the timeout wrapper),
or if R67's exit-code contract changes what a drain-deadline failure must return.

##### Sources
py `src/py_launch_blueprint/web/__main__.py:37,42` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`;
`https://raw.githubusercontent.com/tokio-rs/axum/axum-v0.8.9/examples/graceful-shutdown/src/main.rs`;
`https://raw.githubusercontent.com/rust-lang/crates.io/3df99c214d640090ab38aad14ae9c34289b0dec0/src/bin/crates-io/server.rs`;
`axum 0.8.9` published artifact (`src/serve/mod.rs`); `actix-web 4.15.0` published artifact
(`src/server.rs:424-433`); this run's executed probe.

#### Dev-serve recipe and auto-reload (F339)

##### Landscape
Mixed member: the recipe is a pattern, the watcher is a crate-shipped binary. Built-in bin:
`cargo run` (rebuild-and-run on demand). Established bin: `cargo-watch` 8.5.3 —
**archived**. Up-and-comer / successor bin: `watchexec-cli` 2.7.2, `bacon` 3.25.0,
`systemfd` 0.4.6 + `listenfd` 1.0.2 (socket hand-off so connections survive a restart; this is
what axum's `auto-reload` example uses).

##### Principles and implementation
F339 has two halves (`Justfile:291`, pin `b08bccfb`): a console-log default distinct from the
production JSON profile, and auto-reload. The first is one exported environment variable in the
recipe; the variable's name, its values and the profile split belong to R58's
`logging-pipeline-contract` and R77's settings, so this item specifies only that the recipe
sets it and that its dev default differs from the production default. The second is discussed
in `### Principles and implementation` above and is demoted to an optional recipe.

##### Dominant choice
No dominant choice exists any more, which is itself the finding. The tool axum's own example
prescribes is archived: `watchexec/cargo-watch` has `archived: true`, `pushed_at` 2025-01-14
(`GET https://api.github.com/repos/watchexec/cargo-watch`), last release 8.5.3 (2024-10-02,
175,851 90-day / 1,969,451 all-time downloads), and its README at tag `v8.5.3` states "Cargo
Watch is on life support: it will not receive further updates" and "I recommend Bacon or
Watchexec instead." Maintenance verdict **dormant** by the rubric (a maintainer's own notice).

##### Qualified shortlist
`watchexec-cli` 2.7.2 (2026-09-06; 8,785 90-day / 659,887 all-time downloads; repository
`watchexec/watchexec` 7,180 stars, `pushed_at` 2026-09-07, 31 open issues, median 0.74 days to
first maintainer response with 3 of 10 unanswered; licence `Apache-2.0`) — the maintainer's own
designated successor, and the best functional fit (`watchexec -r -e rs -- cargo run ...` is a
restart-on-change loop with plain streamed output). `bacon` 3.25.0 (2026-08-23; 22,030 /
328,790 downloads; `Canop/bacon` 3,410 stars, `pushed_at` 2026-09-12, 47 open issues, median
0.02 days, 3 of 10 unanswered; `rust-version = "1.85"`, edition 2024) — actively maintained and
well liked, TUI-oriented.

##### Excluded by gate
- `watchexec-cli` 2.7.2 — **gate 2**: the published manifest declares no `rust-version`
  (verified in the extracted `watchexec-cli-2.7.2/Cargo.toml`; `GET https://crates.io/api/v1/crates/watchexec-cli/versions`
  reports `rust_version: null`). Under the strict reading settled 2026-09-11, a candidate that
  declares no version cannot clear the gate.
- `bacon` 3.25.0 — **gate 1**: licence `AGPL-3.0` (published manifest and
  `GET https://crates.io/api/v1/crates/bacon/versions`). It is not linked into the template and
  running it imposes nothing on the template's own code, but the gate asks for compatibility
  with `MIT OR Apache-2.0` and AGPL-3.0 is not compatible for combination or redistribution; a
  tool the template *requires* every contributor to install is the wrong place to spend that
  ambiguity.
- `cargo-watch` 8.5.3 — passes gates 1 (`CC0-1.0`) and 2 (`rust-version = "1.75.0"`) but is
  excluded on **maintenance**: archived repository plus the maintainer's own end-of-life notice.
- `listenfd` 1.0.2 — **gate 2**, no declared `rust-version`; `systemfd` 0.4.6 passes gates 1
  (`Apache-2.0`) and 2 (`rust-version = "1.64.0"`) but is pointless without a watcher and
  without `listenfd` in the binary.

##### Up-and-comers
`bacon` is the liveliest entry in this sub-field and would be the recommendation if the licence
gate were read as not applying to non-linked developer tooling. That reading is the owner's to
make, not this report's; it is listed as a re-verify trigger.

##### Fit for this template
The reload half is worth less in Rust than in Python and costs more: the loop is a full
incremental rebuild plus process restart (this run measured 9.28 s wall / 25.61 s user CPU for
a *clean* debug build of the web feature), against uvicorn's sub-second module reload. The
console-log half carries nearly all of F339's value and has no tooling cost at all. A template
should therefore guarantee the half it can, and document the half that depends on a tool the
contributor chooses.

##### Recommendation
Two recipes, following R42's published `package-manager-invocation` (bare executables on
PATH; no runner prefix):

```just
# Run the web service with dev-friendly console logs.
serve host="127.0.0.1" port="8000":
    #!/usr/bin/env bash
    set -euo pipefail
    # every knob is an env var, as in py's entrypoint; variable names owned by R77 (+R58 for the format)
    export <APP>_WEB_HOST="{{host}}" <APP>_WEB_PORT="{{port}}"
    export <APP>_WEB_LOG_FORMAT="${<APP>_WEB_LOG_FORMAT:-console}"
    exec cargo run --features web --bin <app>-serve

# Same, restarting on source changes. Requires `watchexec` on PATH (not part of the required dev toolchain).
serve-watch host="127.0.0.1" port="8000":
    watchexec --restart --exts rs,toml -- just serve {{host}} {{port}}
```
The `serve` recipe is the required one; `serve-watch` documents its prerequisite and fails with
a clear message if `watchexec` is absent.

##### Ranked runner-up
`bacon` as the watcher, if the owner rules that gate 1 does not reach non-linked developer
tools. It is the better-maintained of the two successors on every population measure except
stars.

##### Tradeoffs
The template ships less than py does here: no guaranteed reload loop. In exchange it ships no
archived tool, no AGPL dependency in its required toolchain, and no tool whose MSRV cannot be
verified. Contributors who want reload install one binary and get it.

##### Parameters
Contributes to `web-extra-surface` only indirectly (the recipe selects `--features web`).
Consumes `package-manager-invocation` (R42, published) and, when it lands,
`logging-pipeline-contract` (R58, open).

##### Migration implications
`Justfile` (two recipes). No `Cargo.toml` change, no `bacon.toml`, no watcher in any
provisioning list.

##### Validation strategy
Not executed — the recipe depends on R58's unpublished env-var contract. Proposed for P03:
`just serve` starts and answers `GET /healthz` with console-formatted logs on stderr, and
`just --list` shows both recipes.

##### Confidence & re-verify trigger
Medium — this is the one member where every candidate failed a gate and the answer is a
scope reduction. Re-verify if `watchexec-cli` declares a `rust-version` (it becomes the
recommendation immediately), if `bacon` relicenses, or if the owner rules on whether gate 1
and gate 2 reach non-linked developer tools.

##### Sources
py `Justfile:291` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`;
`https://api.github.com/repos/watchexec/cargo-watch`, `.../Canop/bacon`,
`.../watchexec/watchexec` (2026-09-12);
`https://raw.githubusercontent.com/watchexec/cargo-watch/v8.5.3/README.md`;
`https://crates.io/api/v1/crates/{cargo-watch,watchexec-cli,bacon,systemfd,listenfd}` and
`/versions` (2026-09-12); published artifacts `watchexec-cli 2.7.2`, `bacon 3.25.0`,
`cargo-watch 8.5.3`, `listenfd 1.0.2`;
`https://raw.githubusercontent.com/tokio-rs/axum/axum-v0.8.9/examples/auto-reload/README.md`;
`docs/port/PARAMETERS.md` (R42's published `package-manager-invocation`).

### Compatibility

The members are proven to work together three ways, two of them by direct observation.

1. **A shared adopter at the exact recommended versions.** `rust-lang/crates.io` at commit
   `3df99c214d640090ab38aad14ae9c34289b0dec0` pins `axum = "=0.8.9"`, `tokio = "=1.53.1"`,
   `tower = "=0.5.3"`, `tower-http = "=0.7.1"`, `hyper = "=1.11.1"` in one workspace with
   `edition = "2024"` and `license = "MIT OR Apache-2.0"` — the same two fixed parameters this
   template carries. It composes routes natively (`src/router.rs`), injects one `AppState` via
   `with_state`, and serves with `axum::serve(..).with_graceful_shutdown(..)` over SIGINT and
   SIGTERM (`src/bin/crates-io/server.rs`). Every member of this stack except the dev-serve
   recipe is exercised together in that one production service.
2. **A resolution and build probe executed in this run** (macOS 26.4 aarch64, rustc 1.98.0,
   2026-09-12). A scratch crate with `edition = "2024"`, `rust-version = "1.96"` and the
   recommended manifest resolved cleanly — `cargo` reported `Locking 97 packages to latest
   Rust 1.96 compatible versions` — and the highest declared `rust-version` anywhere in the
   resolved non-dev `web` tree is axum's own **1.80**, comfortably inside the floor. `cargo audit`
   0.22.1 (1,243 advisories) exited 0. Three integration tests passed, covering state injection,
   the library-type round trip over a real listener, and the drain behavior.
3. **A version matrix is unnecessary and would be misleading here**: `axum` 0.8.9 depends on
   `hyper` ≥1.1.0 and `hyper-util` ≥0.1.3 and pulls `tokio` through its own `tokio` feature, so
   the pairing is expressed by the resolver rather than by independent choices. The one
   cross-member constraint worth stating is that `axum::serve` exists only with axum's `tokio`
   feature plus `http1` or `http2` (`#[cfg(all(feature = "tokio", any(feature = "http1", feature = "http2")))]`,
   `axum-0.8.9/src/serve/mod.rs:236`); both are default-on.

Platform compatibility: axum's own CI runs on `ubuntu-24.04` only, with no macOS runner
(`.github/workflows/CI.yml` at tag `axum-v0.8.9`). tokio's CI covers `ubuntu-latest`,
`macos-latest` and `windows-latest` (`.github/workflows/ci.yml` at tag `tokio-1.53.1`). The
macOS gap for axum is closed for these versions, and only for these versions, by this run
compiling and testing the full stack on macOS 26.4 aarch64. The template's own CI on
`ubuntu-latest, macos-latest` re-establishes it continuously.

### Parameters

**owns `web-extra-surface`** = *the template ships an optional web and API surface behind a
single additive, off-by-default Cargo feature named `web`, declared on the crate that hosts the
binary targets (which crate that is belongs to R02 `crate-boundary-enforcement`). The feature
is exactly `web = ["dep:axum", "dep:tokio"]`, with `axum = { version = "0.8.9", optional = true }`
(default features: `form, http1, json, matched-path, original-uri, query, tokio, tower-log,
tracing`) and `tokio = { version = "1.53.1", optional = true, features = ["rt-multi-thread",
"net", "signal", "macros", "time"] }`; `tower = "0.5.3"` is a dev-dependency only, for the
`ServiceExt::oneshot` in-process test idiom.*

*The feature gates exactly four things, and nothing else:*
1. *the library module `src/web/` (`#[cfg(feature = "web")] pub mod web;`), containing
   `AppState`, `build_router`, the per-resource route modules, the handlers and
   `shutdown_signal`;*
2. *one additional binary target, `[[bin]] name = "<app>-serve", required-features = ["web"]` —
   the production entrypoint, environment-variable-driven with no CLI flags;*
3. *the web integration tests (file-level `#![cfg(feature = "web")]` under `tests/`);*
4. *every later web layer — R70's error envelope, R71's OpenAPI generation, R72–R76's
   middleware, R77's settings, R80's probes — as modules inside that same gated `src/web/`
   tree, so they are on when `web` is on and absent when it is off.*

*It does **not** gate the CLI binary, the core library, R01's port/adapter seam, `serde`, or
`serde_json`. Heavier opt-ins nest on top instead of widening it: R78's OpenTelemetry and
R79's Prometheus support are separate features that require `web` (`otel = ["web", ...]`,
`metrics = ["web", ...]`), mirroring py's `web` + `otel` extras.*

*Consumers therefore select the surface with `--features web` (or `--all-features`) and
detect it by that feature name; path-based skip-gating keys on `src/web/**`, the serve
binary's source file, and the web test files. Measured cost of turning it on, on macOS 26.4
aarch64 with rustc 1.98.0 on 2026-09-12: the non-dev dependency tree goes from 13 to 52
packages; a clean debug build goes from 5.69 s wall / 7.12 s user CPU to 9.28 s / 25.61 s; the
release serve binary is 2,001,600 bytes (1,574,392 stripped). With the feature off, no
`axum`, `tokio`, `hyper` or `tower` appears in the tree and no serve binary is produced.*

**assumes `http-transport-injection-seam`** = R01's published value, unchanged. The web
adapter holds R01's erased service in `AppState` as `Arc<ErasedProjectsService>` and returns
the library's own `serde`-derived contract types (`Json<Vec<Project>>`), with no mirror struct
and no second construction path. Verified in this run that this requires **no change to R01's
types**: `Arc<T>` is unconditionally `Clone`, which is all axum's `S: Clone + Send + Sync + 'static`
state bound needs, so `ProjectsService` does not have to derive `Clone` (the probe passes with
it not deriving `Clone`). If P03 prefers to store the service by value it must add
`#[derive(Clone)]` to `ProjectsService<P>`, which imposes a `P: Clone` bound on library
consumers — recorded as a P03 choice, not a change to the parameter.

**assumes `rust-edition`** = `2024`; **assumes `msrv-policy`** = stable minus 2 minors
(floor 1.96 today); **assumes `license`** = `MIT OR Apache-2.0`;
**assumes `target-os-matrix`** = `ubuntu-latest, macos-latest`; **assumes
`package-manager-invocation`** = R42's published value (the Justfile recipes invoke `cargo run`
as a Cargo built-in and `watchexec` as a bare executable on PATH, with no provisioner prefix).

**Open items this answer depends on but does not decide, and how it behaves either way:**
- **R05 `sync-async-execution-model` (open).** If the port stays synchronous, the handler wraps
  the call in `tokio::task::spawn_blocking` — the shape this run's probe compiled and tested.
  If R05 chooses an async port, the handler awaits it directly and R01's `async-trait` clause
  applies. Nothing in this stack changes either way; `tokio`'s `rt-multi-thread` is required in
  both cases. R05 is not a parameter, so this is a coupling, not a conflict.
- **R02 `crate-boundary-enforcement` (open).** Decides which crate carries the feature and the
  `src/web/` module. The value above is phrased to survive either a single-crate or a
  multi-crate layout.
- **R58 `logging-pipeline-contract` (open).** Owns the console/JSON profile split the dev
  recipe's environment variable selects, and the name of that variable.

**CONFLICT lines: none.** No recommendation here requires a consumed parameter to change.

### Migration implications

File-level changes in the template (crate placement per R02; `<app>` is the template's
binary name per R49's `build-tool-output-shape`):

| File | Change |
|---|---|
| `Cargo.toml` | `[features] web = ["dep:axum", "dep:tokio"]`; optional `axum` 0.8.9 and `tokio` 1.53.1 (features as above); `tower` 0.5.3 under `[dev-dependencies]`; `[[bin]] name = "<app>-serve", required-features = ["web"]` |
| `src/lib.rs` | one line: `#[cfg(feature = "web")] pub mod web;` |
| `src/web/mod.rs` (new) | `WebConfig` re-export (type owned by R77), `AppState` + its `FromRef` impls, `build_router(state) -> Router`, `shutdown_signal()` |
| `src/web/routes/projects.rs` (new) | `pub(crate) fn router() -> Router<AppState>` and the handlers, returning the library's contract types |
| `src/web/routes/ops.rs` (new) | `/healthz` now; `/readyz` and its payload are R80's |
| `src/bin/<app>-serve.rs` (new) | `#[tokio::main] async fn main() -> ExitCode` — settings, composition root, bind, `axum::serve(..).with_graceful_shutdown(..)` inside `tokio::time::timeout` |
| `tests/web_api.rs` (new) | `#![cfg(feature = "web")]`; the `oneshot` and real-listener tests |
| `Justfile` | `serve` (required) and `serve-watch` (optional, needs `watchexec` on PATH) |
| `.github/workflows/ci.yml` | a `--features web` axis and a `--no-default-features` build — shape owned by R11 |

Not created by this item: `problems.rs` (R70), `openapi.rs` (R71), `pagination.rs` (R72),
`idempotency.rs` (R73), `rate_limit.rs` (R74), `middleware.rs` (R75), `cors.rs` (R76),
`settings.rs` (R77), `telemetry.rs` (R78/R79), `Dockerfile` (R51).

### Validation strategy

**Executed in this run** (scratch crate, macOS 26.4 aarch64, `rustc 1.98.0`, 2026-09-12;
`edition = "2024"`, `rust-version = "1.96"`, `axum` 0.8.9, `tokio` 1.53.1, `serde` 1.0.229,
`serde_json` 1.0.151, plus `tower` 0.5.3 and `reqwest` 0.12.28 for the tests). The crate
reproduced R01's seam verbatim — `trait ProjectsPort: Send + Sync`, blanket `impl` for
`Arc<T>`, `ProjectsService<P>`, `ErasedProjectsService`, `InMemoryProjectsPort` over
`std::sync::Mutex<Vec<Project>>` — and put the web layer on top of it:

| Command | Expected | Observed |
|---|---|---|
| `cargo generate-lockfile` | resolves under the 1.96 floor | `Locking 97 packages to latest Rust 1.96 compatible versions` |
| `cargo tree -e normal` (no features) | no web crates | 13 packages; no `axum`, `tokio`, `hyper`, `tower` |
| `cargo tree -e normal --features web` | the web crates appear | 52 packages; highest declared `rust-version` in the tree is axum's 1.80 |
| `cargo clean && cargo build --bins` (no features) | no serve binary | `target/debug/webprobe-serve: No such file or directory` |
| `cargo clean && cargo build` / `... --features web --bins` | feature cost | 5.69 s real / 7.12 s user → 9.28 s real / 25.61 s user |
| `cargo build --release --features web --bins` | binary size | 11.59 s real / 52.85 s user; 2,001,600 bytes (1,574,392 stripped) |
| `cargo test --features web` | 3 passed | `oneshot_returns_library_types` ok; `real_listener_decodes_into_library_types` ok; `graceful_shutdown_has_no_drain_deadline_of_its_own` ok |
| `cargo audit` (0.22.1) | no advisories | exit 0, no findings, 1,243-advisory database |

One manifest difference between the probe and the recommendation, stated for completeness: the
probe declared `tower` inside the feature (`web = [..., "dep:tower"]`) while the recommendation
places it under `[dev-dependencies]`. The resolved tree and the 52-package count are identical
either way, because `axum` 0.8.9 already depends on `tower` 0.5 — its `tokio` feature enables
`tower/make` (`axum-0.8.9/Cargo.toml`), and `tower v0.5.3` appears in the probe's
`cargo tree -e normal --features web` output regardless.

What each test establishes: `oneshot_returns_library_types` — a handler reached through
`State<Arc<ErasedProjectsService>>` returns `Json<Vec<Project>>` of the library's own type and
decodes back into it, with no server and no mirror struct (R01 criterion 6, in-process half).
`real_listener_decodes_into_library_types` — the same over a real bound TCP listener and a real
HTTP client (R01 criterion 6, transport half). `graceful_shutdown_has_no_drain_deadline_of_its_own`
— with one request open on a never-completing route, the serve future had not resolved 1.5 s
after the shutdown signal fired, which is why the settings-driven `tokio::time::timeout` wrapper
is part of the recommendation. A second variant of the probe, run after the first, proved the
`Arc`-held service works with `ProjectsService` **not** deriving `Clone` — i.e. R01's types need
no modification.

**Proposed for P03, not run here:** a SIGTERM drain test against the built binary in CI; one
`oneshot` test per route; a `compile_fail` doctest for an unregistered substate;
`cargo hack --each-feature check` plus an MSRV job at the floor; `just serve` answering
`GET /healthz` with console-formatted logs (blocked on R58); and the OpenAPI snapshot staleness
check (R71/R37).

**Not measured, and deliberately so:** comparative throughput. No public benchmark measures
what the HIGH question asks for — JSON handling, validation, tracing and metrics all enabled —
and the TechEmpower payload could not be retrieved today (HTTP 404 on the results path the
site bundle references; `tfb-status.techempower.com` timed out after 20 s). TechEmpower's Rust
entries are in any case hand-tuned implementations written for the benchmark, not idiomatic
instrumented services, and every candidate here except `ntex`/`xitca-web` sits on the same
`tokio` + `hyper` I/O path, so a composite ranking would not discriminate between them on this
template's workload — where a single upstream API call through R01's port dominates any
framework overhead. The costs this template actually pays are the build-time, dependency-count
and binary-size figures measured above, and those are reported rather than inferred.

### Confidence & re-verify trigger

**High** for the framework, runtime, state-injection, router-composition, feature-shape and
entrypoint members: each rests on a published artifact read at an exact version, a maintained
reference implementation at a recorded commit, and an executed check on this machine.
**Medium** for the dev-serve member, where every watcher candidate failed a gate and the answer
is a deliberate scope reduction recorded as `BASELINE-REVIEW: F339`. **Medium** for the exact
field list of `AppState`, which R77 (settings) and R58 (logging) will refine.

Re-verify when any of these happens: axum publishes 0.9 (its 0.7→0.8 minor broke path syntax);
axum's or tokio's declared `rust-version` rises above the template's floor as stable advances;
a RustSec advisory opens against `axum`, `tokio`, `hyper` or `tower-http`; `watchexec-cli`
declares a `rust-version` (it becomes the dev-reload recommendation immediately) or `bacon`
relicenses; R02 decides crate boundaries; R05 decides sync versus async; R58 publishes the
logging contract; or the owner rules on whether the licence and MSRV gates reach non-linked
developer tools.

### Sources

Population figures — all retrieved **2026-09-12**, field rules per the prompt's table
(`crate.recent_downloads`, `crate.downloads`; newest non-yanked `num`/`created_at` from
`/versions`; `stargazers_count`/`archived`/`pushed_at` from the repos endpoint; open issues from
the search endpoint's `total_count`; reverse dependencies from `/reverse_dependencies?per_page=1`
→ `meta.total`):

| Crate | 90-day dl | All-time dl | Newest non-yanked | Stars / pushed / archived | Open issues | Licence | `rust-version` | Maintenance |
|---|---:|---:|---|---|---:|---|---|---|
| `axum` | 115,597,652 | 466,002,347 | 0.8.9 (2026-04-14) | 27,095 / 2026-09-11 / false | 34 | MIT | 1.80 | active |
| `tokio` | 223,873,368 | 960,164,351 | 1.53.1 (2026-07-20) | 33,132 / 2026-09-12 / false | 316 | MIT | 1.71 | active |
| `hyper` | 201,277,067 | 911,720,162 | 1.11.1 (2026-08-28) | 16,316 / 2026-09-11 / false | 191 | MIT | 1.63 | active (transitive) |
| `tower` | 170,786,749 | 655,554,296 | 0.5.3 (2026-01-12) | 4,293 / 2026-06-22 / false | 69 | MIT | 1.64.0 | active |
| `tower-http` | 144,860,804 | 449,508,805 | 0.7.1 (2026-08-31) | 910 / 2026-09-12 / false | 29 | MIT | 1.65 | active (R75's to select) |
| `actix-web` | 10,372,543 | 80,771,779 | 4.15.0 (2026-08-21) | 24,826 / 2026-09-10 / false | 148 | MIT OR Apache-2.0 | 1.88 | active |
| `warp` | 5,166,863 | 47,939,627 | 0.4.3 (2026-05-04) | 10,366 / 2026-07-28 / false | 178 | MIT | none | active; gate 2 fail |
| `rocket` | 1,552,793 | 13,239,049 | 0.5.1 (2024-05-23) | 25,782 / 2025-12-28 / false | 65 | MIT OR Apache-2.0 | 1.64 | at-risk |
| `salvo` | 901,871 | 12,544,293 | 0.96.0 (2026-08-27) | 4,435 / 2026-09-08 / false | 20 | Apache-2.0 | 1.94 | active |
| `poem` | 705,783 | 5,673,682 | 3.1.12 (2025-07-28) | 4,440 / 2026-08-03 / false | 179 | MIT OR Apache-2.0 | 1.85 | at-risk |
| `ntex` | 100,042 | 1,059,193 | 3.12.3 (2026-08-07) | 2,538 / 2026-09-12 / false | 3 | MIT OR Apache-2.0 | 1.88 | active |
| `loco-rs` | 109,887 | 649,453 | 1.1.0 (2026-08-16) | not retrieved | — | Apache-2.0 | 1.94 | active |
| `dropshot` | 128,545 | 849,737 | 0.17.1 (2026-06-02) | not retrieved | — | Apache-2.0 | 1.85 | active |
| `xitca-web` | 2,764 | 45,955 | 0.8.3 (2026-08-29) | not retrieved | — | Apache-2.0 | 1.98 | active; gate 2 fail |
| `pavex` | 2,401 | 95,133 | 0.2.10 (2025-11-10) | not retrieved | — | Apache-2.0 | none | active; gate 2 fail |
| `viz` | 5,486 | 215,707 | 0.11.0 (2025-11-17) | 5 / 2026-02-08 / false | 4 | MIT | none | at-risk; gate 2 fail |
| `tide` | 212,198 | 3,550,529 | 0.16.0 (2021-01-29) | not retrieved | — | MIT OR Apache-2.0 | none | dormant |
| `cargo-watch` | 175,851 | 1,969,451 | 8.5.3 (2024-10-02) | 2,861 / 2025-01-14 / **true** | 28 | CC0-1.0 | 1.75.0 | dormant (maintainer notice) |
| `watchexec-cli` | 8,785 | 659,887 | 2.7.2 (2026-09-06) | 7,180 / 2026-09-07 / false | 31 | Apache-2.0 | none | active; gate 2 fail |
| `bacon` | 22,030 | 328,790 | 3.25.0 (2026-08-23) | 3,410 / 2026-09-12 / false | 47 | AGPL-3.0 | 1.85 | active; gate 1 fail |
| `systemfd` | 2,042 | 66,055 | 0.4.6 (2025-01-19) | not retrieved | — | Apache-2.0 | 1.64.0 | stable-quiet |
| `listenfd` | 764,055 | 5,890,311 | 1.0.2 (2025-01-19) | not retrieved | — | Apache-2.0 | none | stable-quiet; gate 2 fail |
| `async-std` | 10,221,871 | 92,377,314 | 1.13.2 (crates.io `updated_at` 2025-08-15) | not retrieved | — | MIT OR Apache-2.0 | not read | out of scope (non-tokio) |

Reverse dependencies (`meta.total`, 2026-09-12): `tokio` 72,140; `axum` 8,583; `actix-web`
1,700; `rocket` 616; `warp` 606; `poem` 134; `salvo` 95.

Issue responsiveness — the 10 most recently opened issues per repository via
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue&sort=created&order=desc&per_page=10`,
first response by a user with `author_association` in OWNER/MEMBER/COLLABORATOR/CONTRIBUTOR
(bots and the issue author excluded), 2026-09-12: `tokio-rs/axum` median 0.41 days, 5 of 10
unanswered (window 2026-06-16 → 2026-09-07); `tokio-rs/tokio` 0.03 days, 3 unanswered;
`actix/actix-web` 2.48 days, 6 unanswered; `poem-web/poem` no maintainer response in any of the
10 (window 2025-12-16 → 2026-09-09) — the concrete signal behind its `at-risk` verdict, together
with a 13-month release gap; `salvo-rs/salvo` 0.01 days, 7 unanswered; `Canop/bacon` 0.02 days,
3 unanswered; `watchexec/watchexec` 0.74 days, 3 unanswered.

Advisories (`https://rustsec.org/packages/<name>.html`, 2026-09-12): HTTP 404 — RustSec's
response for a crate with no advisory — for `axum`, `tower`, `poem`, `salvo`, `bacon`,
`watchexec-cli`, `cargo-watch`. Historic-only listings for `tokio` (RUSTSEC-2025-0023 and older),
`hyper` (RUSTSEC-2022-0022 and older), `actix-web` (RUSTSEC-2018-0019, 0.x), `tower-http`
(RUSTSEC-2022-0043), `warp` (RUSTSEC-2022-0082). None applies to a recommended version, and the
executed `cargo audit` against the probe lockfile confirms it for the resolved set.

Primary documents read at an exact version or commit: published `.crate` artifacts of `axum`
0.8.9, `tokio` 1.53.1, `actix-web` 4.15.0, `tower-http` 0.7.1, `watchexec-cli` 2.7.2, `bacon`
3.25.0, `cargo-watch` 8.5.3, `listenfd` 1.0.2 (all from
`https://crates.io/api/v1/crates/<name>/<version>/download`); the axum repository at tag
`axum-v0.8.9` (commit `31872e2e543b9cbb0e671ca7d678448b38cfb4c7`) for
`examples/graceful-shutdown/src/main.rs`, `examples/auto-reload/README.md` and
`.github/workflows/CI.yml`; the tokio repository at tag `tokio-1.53.1` for
`.github/workflows/ci.yml`; `rust-lang/crates.io` at commit
`3df99c214d640090ab38aad14ae9c34289b0dec0` for `Cargo.toml`, `src/router.rs` and
`src/bin/crates-io/server.rs`; `apollographql/router` at commit
`e7b2b32b5c7183475ea874b58b9f0b7d01dc32d8` (`apollo-router/Cargo.toml`);
`meilisearch/meilisearch` at commit `a955694df9f50771b3ceaf7896754cecfbaf165d`
(`crates/meilisearch/Cargo.toml`); `watchexec/cargo-watch` at tag `v8.5.3` (`README.md`);
`https://docs.rs/axum/0.8.9/axum/fn.serve.html`;
`https://doc.rust-lang.org/cargo/reference/features.html`;
`https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`.

Programme documents: `research/topics/01-ports-and-adapters-seam/DECISION.md` (R01, accepted
2026-09-10); `docs/port/PARAMETERS.md`; `docs/port/COMMONALITY.md` rows F017, F303, F330, F331,
F338, F339; `docs/port/DIVERGENCE-ANALYSIS.md` lines 56, 60, 217; `docs/port/BASELINE-REVIEW.md`
(F331 reclassification). py source read exclusively through the programme pin
`b08bccfb55d05f15e46a83b52c5660b1881d19f5` with `git -C ~/c/py-launch-blueprint show <pin>:<path>`:
`src/py_launch_blueprint/web/app.py`, `web/deps.py`, `web/__main__.py`, `web/routers/__init__.py`,
`pyproject.toml`, `Justfile`. The ts repository was not read: the pinned snapshot
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00` contains no web-service code, dependency or test, a
fact taken from `docs/port/areas/web-service.md` and `docs/port/DIVERGENCE-ANALYSIS.md` line 217
rather than re-derived, and no claim in this report depends on ts source.

**Method notes.** Endpoints queried: `https://crates.io/api/v1/crates/<name>` (90-day and
all-time downloads, repository), `/versions` (newest non-yanked version, its `created_at`,
`rust_version` and `license` — the field the strict MSRV gate is read from),
`/reverse_dependencies?per_page=1` (adoption), `/<name>/<version>/download` (published
artifacts, read for manifests, `[lints]`, feature lists and `unsafe` posture);
`https://api.github.com/repos/<o>/<r>` (stars, `archived`, `pushed_at`, licence);
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` (open issue counts) and
the same endpoint sorted by creation for responsiveness; `https://rustsec.org/packages/<name>.html`;
`raw.githubusercontent.com` at recorded tags and commit SHAs for every adopter and example file;
`https://docs.rs/axum/0.8.9/axum/fn.serve.html`; `https://blog.rust-lang.org/`. Executed locally:
`cargo generate-lockfile`, `cargo tree`, `cargo metadata`, `cargo build` (debug and release,
timed), `cargo test`, `cargo audit` 0.22.1, all against a throwaway probe crate in this session's
scratch directory — a resolution and behavior probe, not template scaffolding; nothing was
written into the repository outside this file.

**Could not verify.** (1) TechEmpower throughput figures — the results payload was not
retrievable today (HTTP 404 at the path the site bundle references; `tfb-status.techempower.com`
timed out after 20 s), so no benchmark number appears in this report and the performance
question is answered structurally, with the limitation stated. (2) GitHub figures for
`loco-rs`, `dropshot`, `xitca-web`, `pavex`, `tide`, `systemfd`, `listenfd` and `async-std` were
not retrieved; only their crates.io figures are cited, and none of them is a recommended member.
(3) `unsafe` posture was inspected in the published source only for `axum` (`unsafe_code = "forbid"`
in `[lints.rust]`, zero `unsafe` occurrences in `src/`), `tokio` (1,066 occurrences, by design) and
`actix-web` (4 occurrences); for the remaining candidates it is unstated. (4) Platform gate 4 was
verified from CI configuration for `axum` (ubuntu only) and `tokio` (ubuntu/macos/windows) and by
this run's own macOS build and test; it was not verified for `actix-web`, `poem`, `salvo`, `ntex`
or `rocket`, which are not recommended. (5) The dev-serve recipe's console-log behavior could not
be exercised because R58's logging contract is unpublished. (6) The 2025 State of Rust Survey
publishes no web-framework or async-runtime breakdown in its results post, so no framework share
is claimed from it.
