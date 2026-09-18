# R76 — cors-middleware — Opus research report

Item `R76` (`cors-middleware`), kind `crate`, Wave 2, FOCUSED tier. Engine: Claude
Opus 5, run `research/runs/R76/2026-09-17T034010Z-d958540e8834/`. Every figure below
was retrieved on **2026-09-18** (UTC) from the endpoint named beside it. The Codex leg
for this item is deferred under owner ruling W1-CODEX3 (2026-09-18), so this report is
written to stand alone.

### Landscape

**The category this item decides.** Not "a CORS library" in the abstract. The decision
is: *which artifact supplies the Fetch-standard CORS response algorithm to the HTTP
service R69 fixed (axum 0.8.9 over tokio 1.53.1), and by what mechanism is that artifact
kept out of the request path when the operator has configured no allowed origins.* CORS
is a browser-enforced protocol defined by the WHATWG Fetch Standard §3.2 "CORS protocol"
(`https://fetch.spec.whatwg.org/#http-cors-protocol`, retrieved 2026-09-18); the server's
whole job is to emit `Access-Control-Allow-*` headers and to answer preflight `OPTIONS`
requests. That makes the category **an HTTP middleware layer**, and in the axum world a
middleware layer is a `tower::Layer` — `tower_layer::Layer` + `tower_service::Service`,
the two crates every axum middleware composes through.

**Three-bin map of the Rust field.**

| Bin | Candidates found | Note |
|---|---|---|
| **Built-in / first-party toolchain** | `tower-http` `cors` feature (`tower_http::cors::CorsLayer`), maintained in `tower-rs/tower-http` — the same GitHub organisation as `tower` itself, which axum's own `Cargo.toml` and examples depend on | axum ships **no** CORS of its own; the maintainers' own example (`tokio-rs/axum`, `examples/cors/Cargo.toml`, `tower-http = { version = "0.6.1", features = ["cors"] }`, retrieved 2026-09-18) reaches for `tower-http` |
| **Established industry standard (framework-bound)** | `actix-cors` 0.7.2 (Actix Web), `rocket_cors` 0.6.0 (Rocket), `salvo-cors` 0.96.0 (Salvo), `ntex-cors` 4.0.0 (ntex), `iron-cors` 0.8.0 / `corsware` 0.2.0 (Iron, both legacy), `routerify-cors` 3.0.0 (Routerify), `trillium-cors` 0.1.0 (Trillium) | each is bound to a framework other than the one R69 fixed; none exposes a `tower::Layer` |
| **Up-and-comer** | `tower-http-cors-config` 0.1.3 (deserializable config types *for* `tower_http::cors`), `axum_cors` 0.1.8, `axum-stack` 0.2.0, `bunner_cors_rs` 0.1.2, `blazingly-middleware` 0.2.2, `corx-core`/`corx-server` 0.2.0 (a CORS *forwarding proxy*, a different problem) | all four-to-five-figure-or-smaller download counts; see `### Up-and-comers` |

Enumeration method, so the map is not recall: `GET https://crates.io/api/v1/crates?q=cors&per_page=40`
(1,452 matches, first 40 read) and `GET https://crates.io/api/v1/crates?keyword=cors&per_page=30&sort=downloads`
(36 crates carry the `cors` keyword, all 30 read), both retrieved 2026-09-18 with a
`User-Agent` header. `tower-http` does not appear in either list because its name does
not contain "cors" and it does not carry the keyword; it was reached from the axum side
(axum's own example) and confirmed by `GET https://crates.io/api/v1/crates/tower-http`.

**Two architectural alternatives, not libraries, that belong on the map.** (1) A
hand-rolled layer via `axum::middleware::from_fn`, adding no dependency and
reimplementing the Fetch preflight algorithm. (2) Not needing CORS at all by serving
every browser asset same-origin — the owner reference's Variant B recommendation
("Serve the SPA from the same Cloud Run service as the API — this keeps cookies
same-origin (no CORS…)", `inputs/owner-reference-axum-companion-stack-2026-09-16.md`
line 87). Both are evaluated in `### Principles and implementation`.

**Authorities used, and why each counts.**

| Source | Why authoritative |
|---|---|
| WHATWG Fetch Standard, "CORS protocol" (`https://fetch.spec.whatwg.org/#http-cors-protocol`) | the normative definition of the protocol; every implementation here is measured against it |
| `tokio-rs/axum` repository, `examples/cors/src/main.rs` and its `Cargo.toml` (raw.githubusercontent.com, `main`) | the framework maintainers' own worked example of how CORS attaches to an axum `Router` — maintainer documentation, not a third-party blog |
| `tower-rs/tower-http` source at the published 0.7.1 artifact (`src/cors/mod.rs`, `src/cors/allow_origin.rs`, `src/cors/vary.rs`, `Cargo.toml`), read from the local registry checkout of the crate this run resolved | the shipped implementation; every behavioural claim below was read from it and then executed |
| `tower-rs/tower-http` `CHANGELOG.md` (`main`) | the maintainers' own record of what 0.7.0 and 0.7.1 changed, used to decide the 0.6-versus-0.7 question |
| RustSec Advisory Database (`https://rustsec.org/packages/tower-http.html` and `crates/tower-http/RUSTSEC-2022-0043.md`) | the Rust Secure Code Working Group's database — the ecosystem's advisory authority |
| `rust-lang/crates.io` `Cargo.toml` | the Rust project's own production web service; what it pins is direct evidence of what the Rust project considers shippable |
| Starlette 1.3.1 `starlette/middleware/cors.py` (the exact version `py-launch-blueprint` locks at pin `b08bccfb`, `uv.lock:2528-2529`) | the source implementation whose behaviour this item must preserve the principle of |
| `loco-rs/loco` `src/controller/middleware/cors.rs`, `src/controller/middleware/mod.rs`, `src/controller/app_routes.rs` | a 9,152-star Rust web framework that documents config-gated middleware installation as a named pattern |

**Well-regarded projects surveyed, with the evidence that they are well regarded.**
`GET https://crates.io/api/v1/crates/tower-http/reverse_dependencies?per_page=25`
(retrieved 2026-09-18) reports **3,486** reverse dependencies; the first page names
`reqwest`, `axum`, `axum-core`, `axum-extra`, `kube-client`, `octocrab`, `mdbook`,
`tonic-web`, `console-subscriber`, `wasmer-wasix`, `aws-smithy-http-server`,
`dioxus-fullstack`, `leptos_axum`, `libsql` and `teloxide`. Three of those activate the
`cors` feature specifically, and the manifest line was read rather than asserted:

- `tokio-rs/console` (4,598 stars, `GET https://api.github.com/repos/tokio-rs/console`,
  `archived: false`, `pushed_at 2026-08-08T01:38:29Z`) —
  `console-subscriber/Cargo.toml:65`: `tower-http = { version = "0.6.6", features = ["cors"] }`.
  Well regarded as the Tokio project's own diagnostics tool.
- `tonic-web` (repository `hyperium/tonic`, which now resolves to `grpc/grpc-rust`,
  12,477 stars, `GET https://api.github.com/repos/hyperium/tonic`) —
  `tonic-web/Cargo.toml:31`: `tower-http = { version = "0.6", features = ["cors"] }`.
  Well regarded as the gRPC organisation's Rust implementation; gRPC-Web *requires* CORS,
  so this is a load-bearing use rather than a convenience.
- `rust-lang/crates.io` — `Cargo.toml:170`:
  `tower-http = { version = "=0.7.1", features = ["add-extension", "fs", "catch-panic", "timeout", "compression-full"] }`.
  It does not use the `cors` feature (crates.io is same-origin), but it is the strongest
  available evidence that **tower-http 0.7.1 is in production** at the Rust project itself.
- `loco-rs/loco` 1.1.0 (9,152 stars, `GET https://api.github.com/repos/loco-rs/loco`,
  `archived: false`, `pushed_at 2026-09-16T08:07:59Z`; 90-day downloads 106,998,
  all-time 655,734, `GET https://crates.io/api/v1/crates/loco-rs`) —
  `loco-rs/Cargo.toml:218` pins `tower-http = { version = "0.6.8", features = [...] }` and
  `src/controller/middleware/cors.rs` builds a `tower_http::cors::CorsLayer` from
  deserialized config.

All figures retrieved 2026-09-18.

### Principles and implementation

**The shared requirement, its source, and its agreement level.** The principle is
*risky cross-origin relaxation is opt-in, and when it is not opted into it is absent from
the request path.* Its source is `py-launch-blueprint` at pin `b08bccfb`, stated three
times in three registers:

- Mechanism — `py: src/py_launch_blueprint/web/app.py:136`: `if settings.cors_origins:`
  guards the single `app.add_middleware(CORSMiddleware, allow_origins=settings.cors_origins,
  allow_methods=["*"], allow_headers=["*"])` call at `:137-141`.
- Configuration — `py: src/py_launch_blueprint/web/settings.py:60-62`:
  `#: CORS allowlist. Empty (the default) means the CORS middleware is not installed at
  all — cross-origin browser calls are opt-in (WEB-23).` with `cors_origins: list[str] = []`.
- Policy — `py: docs/adr/0013-web-service-best-practices.md:40-41`: "Risky features (CORS,
  rate limiting, tracing) are wired but **off by default**; one env var enables each," and
  `py: docs/design/0002-web-api-conventions.md:61-62`: "CORS middleware is only installed
  when `PLBP_WEB_CORS_ORIGINS` is non-empty."

`ts-launch-blueprint` at pin `cb1cbcb2` has no web service to reconcile with:
`git ls-tree -r --name-only cb1cbcb2` filtered for `web|cors|hono|server` returns **no
files**, and `docs/port/areas/web-service.md:100` records "ts: `package.json` — no
feature: no web/HTTP-framework dependency present". Ledger row `F322`
(`docs/port/COMMONALITY.md:326`) is therefore `py-only` / `DIVERGENT`.

**The agreement level is the policy, not the mechanism.** What all three repositories
must agree on is the observable: *with no allowlist configured, a cross-origin browser
request to the service receives no `Access-Control-Allow-Origin` header, and the service
behaves exactly as if no CORS code existed.* What may vary is everything below that: the
class name, the header set, the default `max-age`, and — critically — the *language
construct* that expresses "not installed". Python expresses it by not calling
`add_middleware`; Rust expresses it by not calling `Router::layer`. These are the same
policy in two type systems, not a shared low-level value. No shared low-level value is
recommended here, because none is an owner requirement and the evidence does not support
the same tradeoff in both ecosystems: Starlette's and tower-http's *defaults differ*
(table below), so a shared constant would be wrong in one of them.

**Observable acceptance criteria.** Numbered so `### Validation strategy` can bind each
to an executed check.

1. With the allowlist empty, a `GET` carrying `Origin: https://evil.example` returns no
   `access-control-allow-origin` **and no `vary`** header.
2. With the allowlist empty, an `OPTIONS` preflight to a `GET`-only route returns
   `405 Method Not Allowed` — the service's behaviour without any CORS code.
3. With the allowlist holding `https://app.example`, a `GET` from that origin echoes
   `access-control-allow-origin: https://app.example`.
4. With that allowlist, a `GET` from a different origin receives no
   `access-control-allow-origin`.
5. With that allowlist, an `OPTIONS` preflight on a `GET`-only route returns `200` and
   the handler is not invoked.
6. A syntactically invalid origin string fails at construction, before the listener binds.

**Architectural alternatives compared before any library was chosen.**

| # | Alternative | Verdict and the ground for it |
|---|---|---|
| **A** | `tower_http::cors::CorsLayer` installed by a plain `if !origins.is_empty()` branch in the composition root | **Selected.** Criteria 1–6 all executed green (checks `A`–`H`, `Q1`–`Q3`, `P1`–`P5`, `R1`). Adds two crates to R69's accepted graph. No new dependency is needed for the conditionality itself, because `axum::Router::layer` returns `Router<S>` — the same type — so re-binding inside an `if` type-checks |
| **B** | `CorsLayer` installed unconditionally, configured with an empty allowlist when none is set | **Rejected on measured behaviour, not on taste.** Installing the layer with an empty allowlist is *not* observationally equivalent to not installing it. Check `Q3`: every response gains `vary: origin`, and an `OPTIONS` request on a `GET`-only route stops being `405` and becomes `200` with an empty body. Check `Q2` shows a bare `CorsLayer::new()` does the same. The cause is in the source: `tower-http-0.7.1/src/cors/mod.rs:715` short-circuits on `parts.method == Method::OPTIONS` **regardless of the allowlist**, and `:710` emits the `Vary` header on every response. B therefore fails acceptance criteria 1 and 2 |
| **C** | A conditional-layer *wrapper*: `tower::util::option_layer(Option<CorsLayer>)` or `axum_extra::middleware::option_layer` | **Rejected on cost with no benefit.** `tower::util::option_layer` exists at `tower-0.5.3/src/util/mod.rs:1067` but is behind tower's `util` feature (`tower-0.5.3/Cargo.toml:151-156`), so using it promotes `tower` from *dev-dependency only* — the value R69 fixed — to a normal dependency of `crates/web`. `axum_extra::middleware::option_layer` exists (`https://docs.rs/axum-extra/0.12.6/axum_extra/middleware/fn.option_layer.html` returned HTTP 200, retrieved 2026-09-18) but adds `axum-extra`, which R69's accepted surface does not contain. Both exist to solve a *type* problem — two branches producing different service types — that `Router::layer` does not have. The owner reference itself flags `option_layer` as carrying a pending axum-extra 0.9 body-type break (`inputs/owner-reference-axum-companion-stack-2026-09-16.md`, Key Findings 1) |
| **D** | Hand-roll the layer with `axum::middleware::from_fn` | **Rejected.** It saves two crates (`tower-http`, `bitflags`; check `T1`) and costs a from-scratch implementation of origin matching, the preflight short-circuit, `Vary` correctness, `max-age`, and the credentials/wildcard interaction — security-relevant code a *template* should not ship hand-written. tower-http encodes the last of those as a runtime assertion (`src/cors/mod.rs:820-830`, `ensure_usable_cors_rules`), which is exactly the sort of trap a hand-rolled version reproduces by accident |
| **E** | Terminate CORS at a reverse proxy or API gateway | **Rejected on fit.** The template must be runnable with `cargo run` and testable in-process through `ServiceExt::oneshot` (R69's test idiom). A gateway-only policy is untestable at that seam and unavailable to a template user who has no gateway |
| **F** | Serve browser assets same-origin so CORS is never required (owner reference, line 87) | **Not applicable, and agreed with where it applies.** R69's `web-extra-surface` contains no static-asset or SPA head: the gated tree is `AppState`, `build_router`, route modules, handlers, `shutdown_signal` and `serve_until`. An API-only surface consumed by a browser front end on another origin is precisely the case CORS exists for. Recorded as agreement in principle, out of scope in fact |
| **G** | A loco-style middleware registry: a `MiddlewareLayer` trait with `is_enabled()`, filtered before application | **Rejected as disproportionate here; handed to R75.** `loco-rs/loco` does exactly this (`src/controller/middleware/mod.rs:55-57` defines `fn is_enabled(&self) -> bool`; `src/controller/app_routes.rs:264-269` applies `.filter(\|m\| m.is_enabled())`; `src/controller/middleware/cors.rs` implements it with a serde `enable: bool`). It is the right shape for loco's **ten-plus** independently switchable middlewares. This template has one conditional layer today. If R75's stack lands with three or more independently gated layers, this becomes the right refactor and R75 owns that call |

**Why the recommended design preserves each principle.** *Opt-in relaxation* is preserved
because the default `Vec<HeaderValue>` is empty and the `if` never fires, leaving the
router byte-identical to a build with no CORS code (check `Q1` versus check `A`).
*Absence, not a permissive default*, is preserved because the layer is not merely
configured restrictively — it is not in the stack at all, which alternative B cannot
claim. *Fail loudly at boot* (py's `settings.py:24-25`, "Validation happens at
construction, so a misconfigured deployment fails loudly at boot instead of silently at
request time") is preserved because `HeaderValue` parsing of each configured origin
happens while the router is built, before the listener binds (check `H`).

**Where a different ecosystem needs a different design.** Python's `add_middleware` takes
a class and kwargs, so py's conditional is a statement. Rust's layer is a value with a
type, so the natural Rust form is a re-binding `if` over a `Router` — which works only
because `Router::layer` is type-preserving. Had it not been, C's `option_layer` would have
been forced. TypeScript, if a web surface is ever added there, would face the same choice
in Hono's `app.use()` form and should take the same policy (skip the `use` call) rather
than installing a permissive-but-empty middleware; that is the follow-on project's
rationale, not a change made here.

**Maturity, dependability, performance and integration cost.** Maturity: `tower-http` has
39 published versions since 2018, 33 non-yanked, and is maintained in the `tower-rs`
organisation alongside `tower` itself. Dependability: `#![deny(unsafe_code)]`
(`tower-http-0.7.1/src/lib.rs:200`); the only `unsafe` block in the crate is a
Windows-only test helper carrying an explicit `#[allow(unsafe_code)]`
(`src/services/fs/serve_dir/tests.rs:1233-1246`), outside the `cors` module and outside
any shipped code path for this feature set. Representative performance: this item adds a
per-request `HeaderMap` construction and, on a matched CORS request, up to four header
insertions (`src/cors/mod.rs:703-739`); the preflight path *avoids* calling the inner
service entirely (check `R1`: handler invocation count `0`). No latency or throughput
benchmark was run and none is claimed — the honest statement is that the layer's cost is
a handful of header operations per request with no allocation of a request body and no
I/O, and that when the allowlist is empty the layer is absent so the cost is exactly zero.
Integration cost, measured rather than estimated (checks `T1`, `T2`): two crates added,
`+4.1 s` of clean release build and `+149,056` stripped bytes on the probe.

**No `BASELINE-REVIEW:` finding is raised.** `F322` is a `DIVERGENT` row, not a
`COMMON → REUSE` or `ADOPT` baseline; nothing in it is an inherited mechanism this item
must adjudicate, and this report does not challenge its classification, its verdict, or
its `py-only` origin.

**Reconciliation with the owner-supplied reference architecture** (standing input,
`docs/planning/p02/owner-decisions.md` §11; file
`inputs/owner-reference-axum-companion-stack-2026-09-16.md`), row by row for the rows this
item touches:

| Reference row | Position | Ground |
|---|---|---|
| "Level One — what Axum + tower-http already give you (don't add crates for these)", listing `CorsLayer` among them (line 80) | **Agree** | This item adds no CORS crate beyond `tower-http`, and the enumeration found no maintained tower-native alternative to add |
| The single `tower-http` dependency line with `"cors"` in its feature list (line 141) | **Agree on the feature, differ on the version** | The feature name is right and this item contributes exactly `"cors"`. The version is stale: the reference says `tower-http 0.6`, but 0.7.0 shipped **2026-06-15** and 0.7.1 on **2026-08-31** (`GET https://crates.io/api/v1/crates/tower-http/versions`), both *before* the reference's own 2026-09-16 date, and `rust-lang/crates.io` pins `=0.7.1` in production. The `cors` module's only change across 0.7.0 is "`cors`: relax the `Vary` header defaults (#674)" — non-breaking for this use; every `**breaking**` entry in the 0.7.0 changelog is in `compression`, `follow-redirect`, `fs`, `trace`/`classify`, `services`, or the removal of the no-op `tokio`/`async-compression` features |
| The recommended layer order placing `CorsLayer` between `CatchPanicLayer` and `NormalizePathLayer` (line 114) | **Differ on the *unconditional* framing; position itself is R75's, not this item's** | The reference lists `CorsLayer` as an always-present member of the stack. This item installs it only when the allowlist is non-empty, on the ground measured in check `Q3`: an always-installed layer changes `OPTIONS` from `405` to `200` and adds `vary: origin` to every response even with nothing allowed, which contradicts `F322`'s recorded intent. Where in the order it sits **when present** is R75's (`F317`) and is not decided here; py places request-id and security headers outermost precisely so preflight short-circuits still carry them (`py: src/py_launch_blueprint/web/app.py:126-129`, `py: docs/adr/0013-web-service-best-practices.md:48-50`), which is a fact R75 should consume |
| Variant B's "serve the SPA from the same Cloud Run service … no CORS" (lines 49, 87, 421) | **Agree in principle; not applicable to R69's surface** | See alternative F above |

Tally: **2 agree, 1 agree-with-a-measured-version-difference, 1 differ, 1 agree-but-not-applicable.**

**How py's defaults differ from tower-http's**, read from Starlette 1.3.1 — the version
`py-launch-blueprint` locks at pin `b08bccfb` (`uv.lock:2528-2529`) — at
`https://raw.githubusercontent.com/encode/starlette/1.3.1/starlette/middleware/cors.py`,
retrieved 2026-09-18, against `tower-http-0.7.1/src/cors/`:

| Behaviour | py (Starlette 1.3.1 as py configures it) | tower-http 0.7.1 `CorsLayer` | Consequence for matching py exactly |
|---|---|---|---|
| Allowed origins | explicit list from settings | `AllowOrigin::list(iter)` at `allow_origin.rs:55`, runtime iterator | equivalent; no change needed |
| Allowed methods | `["*"]`, expanded to the enumerated `ALL_METHODS` tuple (`cors.py:11`, `:28-29`) | `Any` → the literal `*` | cosmetically different header, same permission |
| Allowed headers | `["*"]`, mirrored back from the request | `Any` → the literal `*` | same permission |
| Credentials | `allow_credentials: bool = False` (`cors.py:22`) | off unless `.allow_credentials(true)`; combining it with `Any` **panics** via `ensure_usable_cors_rules` (`mod.rs:820-830`) | agree on the default; the panic is a trap to document, and loco converts it to a config error (`loco/src/controller/middleware/cors.rs:155-172`) |
| `Access-Control-Max-Age` | `max_age: int = 600` — always emitted (`cors.py:26`, `:56`) | no default; header absent unless `.max_age(...)` | **to match py exactly, call `.max_age(Duration::from_secs(600))`.** Otherwise browsers re-preflight every request |
| `Vary` on a simple response | added only when the origin is allowed (`cors.py:177-179`, `allow_explicit_origin` calls `add_vary_header("Origin")`) | `vary: origin` on every response while the layer is installed (`mod.rs:710`; check `Q3`) | a justified ecosystem difference: tower-http is the more cache-correct of the two. Do not chase parity here |
| Preflight trigger | `method == "OPTIONS" and "access-control-request-method" in headers` (`cors.py:91`) | **any** `OPTIONS` request (`mod.rs:715`) | the reason alternative B fails criterion 2 |
| Disallowed preflight | `400` with a `Disallowed CORS <reasons>` body (`cors.py:143-148`) | `200` with the CORS headers simply absent | a justified difference: both are spec-legal, since the browser enforces the policy; py's is more informative, tower-http's is more minimal. Not worth reimplementing |

The one default worth importing is `max_age = 600 s`; the rest are justified ecosystem
differences that preserve the principle.

**Minimal realistic example** (the shape P03 writes, using R69 revision 10's paths):

```rust
// crates/web/src/cors.rs
use axum::Router;
use http::HeaderValue;
use std::time::Duration;
use tower_http::cors::{Any, CorsLayer};

/// Install the CORS layer only when an origin allowlist is configured.
/// An empty allowlist (the default) leaves the router byte-identical to a
/// build with no CORS code: no layer, no `Vary`, and `OPTIONS` on a GET-only
/// route still answers 405.
pub fn apply_cors(router: Router, allowed_origins: &[HeaderValue]) -> Router {
    if allowed_origins.is_empty() {
        return router;
    }
    router.layer(
        CorsLayer::new()
            .allow_origin(allowed_origins.to_vec())
            .allow_methods(Any)
            .allow_headers(Any)
            .max_age(Duration::from_secs(600)),
    )
}
```

The full composition is: R77 parses the environment variable into a possibly-empty
`Vec<HeaderValue>` (an invalid entry is a boot failure, `RSLB203` → exit `2`); the
composition root in `crates/web/src/` calls `apply_cors` while assembling the router
inside `build_router`; R75 decides where the call sits relative to the request-id,
security-header and access-log layers. Behaviour is verified by the in-process
`ServiceExt::oneshot` idiom R69 fixed, which is why `tower` stays a dev-dependency.

### Dominant choice

**`tower-http` with the `cors` feature — `tower_http::cors::CorsLayer`.** It is dominant
in the strict sense that the axum/tower middleware model admits no maintained
alternative. The enumeration of all 36 `cors`-keyword crates and the first 40 of 1,452
name matches on crates.io (both retrieved 2026-09-18) produced **no** second crate that
exposes a `tower::Layer` implementing the Fetch CORS protocol and clears the fitness
gates; every other serious candidate is bound to a different framework's middleware API.
Its position is corroborated from three independent directions: axum's own maintained
example depends on it (`tokio-rs/axum`, `examples/cors/Cargo.toml`), the Tokio project's
own `console-subscriber` and the gRPC organisation's `tonic-web` both activate exactly
this feature, and it carries **149,725,960** 90-day downloads against **462,114,603**
all-time (`GET https://crates.io/api/v1/crates/tower-http`, retrieved 2026-09-18).

### Qualified shortlist

**One candidate passed every gate, and that is itself the finding.** The prompt allows up
to five; the category genuinely contains one, because "a CORS middleware for axum" and "a
CORS middleware for tower" are the same artifact and only `tower-http` supplies it.

| name | role | 90-day downloads | all-time downloads | stars | last release | maintenance state | notable adopters | one-line trade-off |
|---|---|---|---|---|---|---|---|---|
| `tower-http` (`cors` feature) | the `tower::Layer` implementing the Fetch CORS protocol for any `tower`/`hyper`/axum service | **149,725,960** | **462,114,603** | **913** (`tower-rs/tower-http`) | **0.7.1**, `2026-08-31T14:49:25.697237Z` | **active** — released 18 days before retrieval, `pushed_at 2026-09-13T22:53:22Z`, `archived: false` | `tokio-rs/console` (`console-subscriber/Cargo.toml:65`, `features = ["cors"]`), `tonic-web` (`Cargo.toml:31`, `features = ["cors"]`), `loco-rs/loco` (`loco-rs/Cargo.toml:218`), `rust-lang/crates.io` (`Cargo.toml:170`, `=0.7.1`), `wasmer-wasix` | you take a kitchen-sink middleware crate (35 features) for one of them, and the crate is MIT-only rather than the dual `MIT OR Apache-2.0` this repository publishes under |

Figure endpoints: downloads from `GET https://crates.io/api/v1/crates/tower-http`
(`crate.recent_downloads`, `crate.downloads`); release from
`GET https://crates.io/api/v1/crates/tower-http/versions` (newest with `yanked: false`);
stars, `archived` and `pushed_at` from `GET https://api.github.com/repos/tower-rs/tower-http`.
All retrieved 2026-09-18.

**Open issues: 30** — `GET https://api.github.com/search/issues?q=repo:tower-rs/tower-http+is:issue+is:open`,
`total_count`, retrieved 2026-09-18. (The repository's `open_issues_count` field reads 37;
it is not used, per the prompt's rule, because it counts pull requests.)

**Issue responsiveness**, from the 10 most recently opened issues
(`GET https://api.github.com/repos/tower-rs/tower-http/issues?state=all&sort=created&direction=desc&per_page=100`,
non-PR items, cross-referenced against
`GET https://api.github.com/repos/tower-rs/tower-http/issues/comments?sort=created&direction=desc&per_page=100`,
both retrieved 2026-09-18): issues `#737, #736, #732, #731, #725, #713, #702, #701, #676, #668`.
Two carry a maintainer comment — `#713` answered by `jlizen` **3 minutes** after opening
and `#702` by `seanmonstar` **4 h 41 m** after opening, so **0 days** for both, and the
median over the answered subset is **0 days**. The remaining eight carry no maintainer
comment; four of those (`#736`, `#725`, `#676`, `#668`) were nonetheless closed, and two
(`#725`, `#668`) were opened by a maintainer. **Unanswered count: 8 of 10 by comment, 4 of
10 if closure without comment is counted as a response.** The median across all ten is
undefined for that reason and is reported as the two figures rather than invented. This is
a quiet-but-live triage pattern, not a stalled one: it does not reach the rubric's
`at-risk` bar, which requires a concrete signal.

### Excluded by gate

Each entry names the exact ground. Gate numbers refer to the prompt's fitness gates.

- **`axum_cors` 0.1.8** — *fails gate 2 and gate 1.* `rust_version` is `null`
  (`GET https://crates.io/api/v1/crates/axum_cors/versions`, retrieved 2026-09-18), and
  under the owner's withdrawn-then-corrected reading recorded in
  `docs/planning/p02/owner-decisions.md` ("an unknown version is insufficient to clear a
  bar the prompt says must be cleared") an undeclared MSRV is a **failure**, not merely
  unproven. Gate 1: its license is `MulanPSL-2.0`, not a member of the permissive set this
  repository's `MIT OR Apache-2.0` is assembled from, and it would need a licence review no
  other candidate needs. Corroborating context, not itself a gate: 161 90-day downloads,
  10,672 all-time, and its declared `repository` is `https://github.com/webc-site/npm.git`
  — a repository literally named `npm` carrying **0** stars
  (`GET https://api.github.com/repos/webc-site/npm`, retrieved 2026-09-18).
- **`tower-http-cors-config` 0.1.3** — *fails gate 2.* `rust_version` is `null`
  (`GET https://crates.io/api/v1/crates/tower-http-cors-config/versions`). Also not an
  alternative: it supplies `serde`-deserializable config *types for* `tower_http::cors`,
  so it presupposes the recommendation rather than competing with it. Last release
  **2025-09-17**, exactly 12 months before retrieval, and
  `GET https://api.github.com/repos/tomharmon/tower-http-cors-config` reports **2** stars,
  `pushed_at 2025-09-17T03:47:44Z` — past the six-month investigate trigger; investigated,
  and with no unpatched advisory and no maintainer notice the rubric places it at
  **stable-quiet**, not `dormant`. It fails gate 2 regardless.
- **`actix-cors` 0.7.2** — *excluded on fit, and it is fair to say so plainly: it passes
  gates 1, 2, 3 and 6.* License `MIT OR Apache-2.0`; `rust_version` 1.88, inside the
  `msrv-policy` floor of 1.96; no RustSec page (`https://rustsec.org/packages/actix-cors.html`
  returns **404** while the control `https://rustsec.org/packages/atty.html` returns **200**,
  both retrieved 2026-09-18); 2,843,244 90-day and 20,974,423 all-time downloads. It fails
  **gate 5** as a disqualifier in this template's context — its runtime coupling is
  `actix-web`/`actix-rt`, a second HTTP stack and a second executor beside the `axum
  0.8.9` + `tokio 1.53.1` R69 fixed — and it fails the survey method's step 4, fit. It is
  the right answer for an Actix Web service and the wrong answer here.
- **`rocket_cors` 0.6.0** (78,837 90-day / 1,124,663 all-time), **`salvo-cors` 0.96.0**
  (606,998 / 7,413,858), **`ntex-cors` 4.0.0** (10,347 / 74,114), **`routerify-cors` 3.0.0**
  (708 / 26,738), **`trillium-cors` 0.1.0** (45 / 45) — *all excluded on gate 5 and fit,*
  for the same reason as `actix-cors`: each implements a different framework's middleware
  trait, so adopting one means adopting that framework. Figures from
  `GET https://crates.io/api/v1/crates?keyword=cors&per_page=30&sort=downloads`, retrieved
  2026-09-18.
- **`iron-cors` 0.8.0** (4,959 / 107,693) and **`corsware` 0.2.0** (301 / 14,585) —
  *excluded on gate 5 and fit,* plus they target Iron, a framework whose last release
  predates the async ecosystem entirely.
- **`corx-core` / `corx-server` 0.2.0** — *excluded on scope.* They implement a CORS
  *forwarding proxy* (a standalone process that adds CORS headers to a third-party
  upstream), which is a different artifact from a layer inside this service.

**Gate results for the recommended candidate, stated in full.**

1. **License — pass with a note.** `tower-http` 0.7.1 is `MIT`
   (`GET https://crates.io/api/v1/crates/tower-http/versions`), not the dual
   `MIT OR Apache-2.0` this repository publishes under. MIT is compatible: it imposes only
   attribution, and a `MIT OR Apache-2.0` crate may depend on an MIT crate without
   restricting either of its own offered licences. The note is that consumers who chose
   this repository's Apache-2.0 arm for its patent grant do not get that grant from
   `tower-http`. No alternative improves on this, since no other tower-native
   implementation exists.
2. **MSRV — pass, with the tree measured, not assumed.** `tower-http` 0.7.1 declares
   `rust-version = 1.65`. The gate applies to the dependency tree, so the tree was
   resolved and read: `cargo metadata --format-version 1 --all-features` on a probe
   pinning `axum =0.8.9`, `tokio =1.53.1`, `tower-http 0.7.1 (features = ["cors"])`
   resolves **57** packages, **48** of which declare a `rust-version`; the maximum among
   the dependencies is **1.80** (`axum` 0.8.9), comfortably inside the floor of **1.96**
   (`rustc 1.98.0 (88d9e12ae 2026-08-18)` minus two minors, per `msrv-policy`). Nine
   packages declare no `rust-version` — `httparse 1.10.1`, `matchit 0.8.4`, `mime 0.3.17`,
   `serde_urlencoded 0.7.1`, `smallvec 1.16.1`, `sync_wrapper 1.0.2`, `tower-layer 0.3.3`,
   `tower-service 0.3.3`, `wasi 0.11.1`. **None of those nine is introduced by this item.**
   A differential resolution (check `T1`) of the same manifest with and without the
   `tower-http` line shows the *entire* delta is **two** packages: `tower-http 0.7.1`
   (`rust-version 1.65`) and `bitflags 2.13.2` (`rust-version 1.56.0`), both declaring.
   The nine undeclared packages arrive with `axum` and `tokio`, which R69 already accepted;
   this report records them so the fact is not lost, and does not re-litigate R69.
3. **Advisories and `unsafe` — pass.** `https://rustsec.org/packages/tower-http.html`
   returns **200** (control: `https://rustsec.org/packages/atty.html` also 200) and lists
   two entries: `RUSTSEC-2021-0135`, marked **withdrawn**, and `RUSTSEC-2022-0043`, whose
   advisory file (`https://raw.githubusercontent.com/rustsec/advisory-db/main/crates/tower-http/RUSTSEC-2022-0043.md`)
   declares `patched = [">= 0.2.1", ">= 0.1.3, < 0.2.0"]`, `os = ["windows"]`, and affects
   `tower_http::services::fs::ServeDir` — a different feature, on an operating system
   outside `target-os-matrix`, patched four major-minor lines before 0.7.1. **Zero open
   advisories.** `unsafe` posture: `#![deny(unsafe_code)]` at
   `tower-http-0.7.1/src/lib.rs:200`; the crate's only `unsafe` block is a Windows-only
   test helper at `src/services/fs/serve_dir/tests.rs:1246` under an explicit
   `#[allow(unsafe_code)]`. The `cors` module contains none.
4. **OS coverage — pass.** `tower-rs/tower-http` `.github/workflows/CI.yml` (retrieved
   2026-09-18) runs its main `test` job on `ubuntu-latest` across `stable`, `beta` and
   `nightly` (lines 57-69), plus a `test-os` job with `os: [macos-latest, windows-latest]`
   (lines 74-81) and a `test-msrv` job pinned to `dtolnay/rust-toolchain@1.65` (line 105).
   Both members of `target-os-matrix` are covered upstream, and Windows — not required — is
   covered too.
5. **Default features and runtime coupling — pass, stated.** `default = []`
   (`tower-http-0.7.1/Cargo.toml:161`): the crate has **no** default features, so the
   dependency line must name `cors` explicitly and nothing else is pulled in. `cors = []`
   (`:117`): the feature activates no optional dependency at all. **No async-runtime
   coupling:** `cargo tree -e normal -p tower-http --depth 1` on the probe lists exactly
   `bitflags`, `bytes`, `http`, `percent-encoding`, `pin-project-lite`, `tower-layer`,
   `tower-service` — no `tokio`, which `tower-http` pulls only for `fs`, `timeout` and the
   `compression-*` features. The layer is executor-agnostic; it runs under whatever runtime
   R69's `tokio` provides.
6. **Binary size and compile time — pass, measured rather than asserted.** Check `T2`, on
   macOS 26.4 `arm64` with `rustc 1.98.0`: two otherwise identical probe binaries, one with
   the `tower-http`/`cors` dependency and the conditional layer and one without, each built
   from a removed `target/` directory. Clean `cargo build --release`: **14.1 s → 18.2 s**
   (`+4.1 s`). Stripped binary: **746,808 → 895,864 bytes** (`+149,056 B`). The absolute
   deltas are the meaningful figures; the percentages (`+29 %`, `+20 %`) are inflated
   because the probes contain almost no other code, and should not be carried forward as
   the template's expected percentage cost.

### Up-and-comers

Named, with figures, and none recommended. All from
`GET https://crates.io/api/v1/crates?keyword=cors&per_page=30&sort=downloads` and
`GET https://crates.io/api/v1/crates?q=cors&per_page=40`, retrieved 2026-09-18.

- **`tower-http-cors-config` 0.1.3** — 1,255 90-day / 5,192 all-time, last release
  2025-09-17, 2 GitHub stars. The most *interesting* of the group, because it addresses the
  real adjacent problem: turning deserialized configuration into a `CorsLayer`. It fails
  gate 2 today (no `rust-version`) and is a two-star single-maintainer crate; the twenty
  lines it replaces are not worth a supply-chain edge. **Watch, do not adopt** — if R77's
  settings shape grows beyond a `Vec<HeaderValue>`, revisit it.
- **`axum_cors` 0.1.8** — 161 / 10,672, released 2026-06-18, `MulanPSL-2.0`, no declared
  MSRV, repository field pointing at a 0-star repository named `npm`. Excluded above.
- **`axum-stack` 0.2.0** — 68 / 68, a grab-bag ("shutdown, CORS, request ID, health
  routes") that would pull one opinionated bundle across four of this programme's
  independent research items (R75, R76, R80). Wrong granularity for a template that is
  deciding those separately.
- **`bunner_cors_rs` 0.1.2** (22 / 842), **`blazingly-middleware` 0.2.2** (216 / 216),
  **`toxi-middleware` 3.1.0** (96 / 96), **`volter-middleware` 0.1.0** (67 / 67),
  **`rok-guard` 0.6.0** (47 / 65), **`churust-cors` 0.3.3** (165 / 165),
  **`sova-cors` 0.1.1** (62 / 62), **`apollo-cors` 0.3.0** (86 / 98) — each belongs to a
  young framework of its own with two- or three-digit download counts. None is a candidate
  for a template that must still build in three years.
- **Genuinely new in the incumbent, and worth flagging to R75 rather than to this item:**
  `tower-http` 0.7.0 added a **`csrf`** feature — "porting the cross-origin protection
  scheme introduced in Go 1.25", using `Sec-Fetch-Site`, an `Origin` allow-list and an
  `Origin`/`Host` fallback with no per-request token state (`tower-http` `CHANGELOG.md`,
  0.7.0 "Added", `#699`). It is adjacent to this item — it also consumes an origin
  allow-list — but CSRF is a different threat model and no P02 item owns it. Recorded as an
  observation, not a recommendation.

### Fit for this template

- **CLI** — **no effect, and that is the point.** R05 revision 2 fixes a synchronous core
  and a CLI binary with no executor in its default dependency tree
  (`research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md`, Decision). Under
  R69 revision 10 (owner-accepted, unpublished) `tower-http` is a dependency of the
  optional `crates/web` member only, so `cargo build` of the CLI never resolves, downloads
  or compiles it. Check `T1` measures the consequence from the other side: the two crates
  this item adds are added to the **web** graph, not to the root's.
- **Library** — **no effect.** R02 revision 1
  (`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md`) fixes a
  four-package workspace in which `crates/web` depends on `core` and `core` depends on
  neither. The CORS layer is an HTTP-transport concern and lives entirely on the far side
  of R01's port; `crates/core`'s external-dependency allow-list is untouched, so the
  `tests/workspace_edges.rs` guard R02 specifies keeps passing without amendment.
- **Web** — **this is the whole surface it touches.** One module in the gated tree, one
  call in `build_router`, one dependency line in `crates/web/Cargo.toml`, one environment
  variable named by R77, and the six acceptance criteria above exercised through the
  in-process `ServiceExt::oneshot` idiom R69 fixed — which is also why `tower` stays a
  dev-dependency: the *tests* need `tower`, the CORS layer does not.

### Recommendation

**Adopt `tower-http` with the `cors` feature, and install `tower_http::cors::CorsLayer`
from a plain conditional branch in the composition root that fires only when the
configured origin allowlist is non-empty.**

Concretely, as a dependency of `crates/web` (non-optional there, because R69 revision 10
makes the whole member optional):

```toml
# crates/web/Cargo.toml
[dependencies]
tower-http = { version = "0.7.1", default-features = false, features = ["cors"] }
```

`default-features = false` is written for explicitness, not necessity: `tower-http`'s
`default = []` already (`tower-http-0.7.1/Cargo.toml:161`). The caret requirement, rather
than `rust-lang/crates.io`'s `=0.7.1`, is deliberate — `crates/web` is a *published
library* under R02's four-package workspace, and an exact pin in a library propagates a
resolution constraint to every downstream consumer. R75 owns the final feature list on
this one dependency line; this item contributes exactly `"cors"`.

And the wiring, mirroring `py: src/py_launch_blueprint/web/app.py:136`:

```rust
let mut app = build_router(state);
if !settings.cors_origins.is_empty() {
    app = app.layer(
        CorsLayer::new()
            .allow_origin(settings.cors_origins.clone())
            .allow_methods(Any)
            .allow_headers(Any)
            .max_age(Duration::from_secs(600)),
    );
}
```

Three points make this the recommendation rather than a preference:

1. **The allowlist is runtime-configured, not compile-time.** `AllowOrigin::list<I>(origins: I)`
   takes an ordinary iterator of `HeaderValue` (`tower-http-0.7.1/src/cors/allow_origin.rs:55`),
   alongside `exact`, `predicate`, `async_predicate`, `mirror_request` and `any` (`:32-105`).
   A `Vec<HeaderValue>` parsed from the environment at boot is exactly what the API expects.
   This answers the first HIGH question: **runtime**, unambiguously.
2. **The conditional needs no wrapper crate.** `axum::Router::layer` returns `Router<S>` —
   the same type it was called on — so `app = app.layer(...)` inside an `if` compiles
   (check `A`, executed). That is the whole reason alternative C's `option_layer`, and the
   dependency promotion it forces on `tower`, is unnecessary. This answers the second HIGH
   question: **a conditional layer-registration branch in the composition root**, on the
   sourced ground that the wrapper's only benefit — unifying two service types — is a
   problem `Router::layer` does not have.
3. **The conditional is behaviourally load-bearing, not stylistic.** Checks `Q1`/`Q2`/`Q3`
   measured the three states side by side. Installing the layer with an empty allowlist
   adds `vary: origin` to every response and converts `OPTIONS` on a `GET`-only route from
   `405` to `200`. Only *not installing it* reproduces py's "empty list = no CORS
   middleware at all."

**Paths.** The module is `crates/web/src/cors.rs` and the dependency line is in
`crates/web/Cargo.toml`, per R69 revision 10 — see `### Parameters` for the standing of
that value against the live registry row.

### Ranked runner-up

**`tower_http::cors::CorsLayer` installed unconditionally, configured with an empty
allowlist when none is set** (alternative B) — the same crate, the other installation
policy. It is ranked first among the rejected because it is the only alternative that
keeps the recommended crate, adds no dependency, and removes a branch from the composition
root; its cost is precisely the two observables measured in check `Q3`.

**The condition under which it wins:** if the owner or R75 decides that `Vary: Origin` on
every response is *desirable* (it is the more cache-correct behaviour, and a
CDN-fronted deployment arguably wants it unconditionally) **and** that answering `200` to
every `OPTIONS` request is acceptable — or if R75's stack ends up installing a layer that
already handles `OPTIONS`, making the second difference moot. In that world the branch
buys nothing and `F322`'s "not installed at all" should be re-read as "installed but
allowing nothing", which is a change to the ledger's recorded intent and belongs to the
owner, not to this item.

**Second runner-up, for completeness:** `tower::util::option_layer` (alternative C). It
wins only if R75's stack acquires several independently optional layers whose presence must
be decided in one uniform place *and* `tower` has already become a normal dependency of
`crates/web` for some other reason — at which point loco's `is_enabled()` registry
(alternative G) is probably the better shape anyway.

### Tradeoffs

**Versus the runner-up (unconditional installation with an empty allowlist).** Given up: a
branch-free composition root, and one fewer thing for a template reader to understand. Also
given up: `Vary: Origin` on every response, which is genuinely the more cache-correct
default. The cost is accepted because `F322`'s recorded principle is *absence*, not
*permissive-but-empty*, and because the `OPTIONS` change is not cosmetic — a service that
answers `200 OK` with an empty body to `OPTIONS /v1/projects` when nobody configured CORS
is reporting something untrue about itself. One `if` is a proportionate price.

**Versus `tower::util::option_layer` / `axum_extra::middleware::option_layer`.** Given up:
a uniform, declarative way to express "maybe this layer" that would compose well if more
optional layers appear. The cost is accepted because today there is exactly one, and paying
for it means either promoting `tower` out of the dev-dependency slot R69 fixed or adding
`axum-extra` — a dependency change to an owner-accepted value, bought for zero behavioural
gain.

**Versus a hand-rolled `axum::middleware::from_fn`.** Given up: two crates
(`tower-http 0.7.1`, `bitflags 2.13.2`), 4.1 s of clean release build, and ~149 kB of
stripped binary — all measured, all small. The cost is accepted because the thing being
bought is a spec-conformant, 913-star, RustSec-clean, `deny(unsafe_code)` implementation of
a browser security protocol, used in production by the Tokio project, the gRPC
organisation and the Rust project's own registry. A template that hand-rolls CORS teaches
every one of its users to hand-roll CORS.

**Versus `actix-cors` and the other framework-bound crates.** Given up: nothing this
template can use. Choosing one means choosing its framework, which R69 already decided
against on its own evidence.

**Versus a same-origin deployment that needs no CORS at all.** Given up: the simplest
possible answer. It is not available, because R69's `web-extra-surface` ships an API with
no front end attached to it; a browser client, if there is one, is necessarily elsewhere.

**Accepted residual risks, named rather than hidden.** (a) The `MIT`-only licence means the
Apache-2.0 patent grant this repository offers is not backed by this dependency. (b)
`tower-http` is a 35-feature crate and this item uses one; a future advisory against an
unused module would still show up in `cargo audit` output and need triage. (c)
`CorsLayer` *panics* if `allow_credentials(true)` is combined with any wildcard
(`src/cors/mod.rs:820-830`); the recommended configuration never sets credentials, but if
R77 ever exposes that knob, the panic must be converted to a boot-time error the way loco
does (`loco/src/controller/middleware/cors.rs:155-172`).

### Parameters

This item **owns no parameter** — `docs/port/PARAMETERS.md` contains no row owned by R76,
and the prompt's `## Couplings` block records `- owns:` empty. The registry's `researched`
rows keep their current owners unchanged.

Consumed values, quoted byte-identically from the live `docs/port/PARAMETERS.md` rows:

- assumes rust-edition = 2024
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.

**Standing of the `web-extra-surface` line.** The bytes above are the registry's, which
still carry R69 **revision 9**'s form — the gated tree at `src/web/`, `web = ["dep:axum",
"dep:tokio"]`, and `tower` as the declaring package's dev-dependency. R69 **revision 10**
is owner-accepted but unpublished
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`, its
`- owns web-extra-surface` line at line 1791; owner ruling W1-R02/W0-R69c), and it moves
the web tree into the optional workspace member `crates/web`: `web = ["dep:rs-launch-blueprint-web"]`
on the root package, `axum 0.8.9` and `tokio 1.53.1` declared **non-optionally** inside
`crates/web/Cargo.toml`, `tower 0.5.3` as `crates/web`'s dev-dependency, the gated tree
reading `crates/web/src/`, tests in `crates/web/tests/` with no file-level
`#![cfg(feature = "web")]`, and skip-gating keyed on `crates/web/**`. **This report's
design uses revision 10's paths**: the module is `crates/web/src/cors.rs` and the
dependency line goes in `crates/web/Cargo.toml`, declared non-optionally because the
member itself is what the feature makes optional. R69's republication is recorded as a
re-verify trigger below. This is deliberately **not** a `CONFLICT:` — nothing in this
recommendation needs R69's value changed; it needs only the paths R69 has already
accepted.

**Why `error-taxonomy-exit-codes` is consumed.** The recommendation makes origin parsing a
boot-time failure (acceptance criterion 6), mirroring py's "invalid config fails at boot"
(`py: src/py_launch_blueprint/web/settings.py:24-25`). Under R67's accepted taxonomy an
unparseable allowlist entry is `RSLB203` — "config value invalid" — mapping to exit code
**2**. This item consumes that mapping; it neither adds a catalog row nor asks for one.

**Coupling statements, not parameters.**

- **R77 (`web-env-settings`, F324)** owns the environment-variable name and the parse. This
  item consumes only "a possibly-empty ordered collection of allowed origins reaches the
  composition root". The Rust-native shape it wants is `Vec<HeaderValue>` — parsed once at
  boot so that criterion 6 holds — and R77 is free to choose any shape that yields it.
  py's variable is `PLBP_WEB_CORS_ORIGINS`, a JSON list
  (`py: src/py_launch_blueprint/web/settings.py:29`,
  `py: docs/source/web/index.md:43` — "JSON list; empty = CORS middleware not installed").
  Naming is R77's, not this item's to fix.
- **R75 (`http-middleware-stack`, F317)** owns where this layer sits when present, and owns
  the aggregate feature list on `crates/web`'s single `tower-http` dependency line. This
  item contributes exactly `"cors"` and states one fact R75 should consume: because the
  CORS preflight short-circuits without calling the inner service (check `R1`, handler
  invocations `0`), any layer that must stamp preflight responses — request id, security
  headers — has to sit **outside** it, which is py's recorded ordering contract
  (`py: src/py_launch_blueprint/web/app.py:126-129`;
  `py: docs/adr/0013-web-service-best-practices.md:48-50`).
- **R70 (`http-problem-envelope`)** is unaffected: a CORS decision produces no error
  envelope. A disallowed origin yields a `200` with the header absent, not a problem
  document.

No `CONFLICT:` line is raised by this report.

### Migration implications

File-level changes in the template, using R69 revision 10's paths.

| File | Change |
|---|---|
| `crates/web/Cargo.toml` | add one line to `[dependencies]`: `tower-http = { version = "0.7.1", default-features = false, features = ["cors"] }`. Non-optional, because the member is what the root's `web` feature gates. R75 may extend the `features` array; it must not remove `"cors"` |
| `Cargo.lock` | two new entries — `tower-http 0.7.1` and `bitflags 2.13.2` (check `T1`). Nothing else moves |
| `crates/web/src/cors.rs` | **new**, ~25 lines: the `apply_cors(router, allowed_origins) -> Router` function shown in `### Principles and implementation`, with the doc comment that states the empty-allowlist contract |
| `crates/web/src/lib.rs` | one `mod cors;` declaration in the gated tree |
| `crates/web/src/` composition root (R69's `build_router`) | one call site. Whether it is `apply_cors(router, &settings.cors_origins)` or an inlined `if` is P03's taste; the branch itself is the decision |
| R77's settings type | one field carrying the allowlist. Named and typed by R77; this item states only that it must reach the composition root as a possibly-empty ordered collection of `HeaderValue` and must fail at boot on an unparseable entry |
| `crates/web/tests/` | one new integration test file carrying acceptance criteria 1–6, written against the `ServiceExt::oneshot` idiom, needing no new dev-dependency — `tower` with `util` is already `crates/web`'s dev-dependency per R69 |
| Documentation | one row in whatever environment-variable table the template ships, stating that an empty allowlist means the middleware is not installed. py's analogue is `docs/source/web/index.md:43` |
| CI | none. Path-based skip-gating already keys on `crates/web/**` per R69 revision 10; no new job, no new tool, no new runner |

**Not changed:** the root package's `Cargo.toml`, `crates/core`, `crates/cli`, R01's port,
R02's `tests/workspace_edges.rs` external-dependency allow-list, and the CLI binary's
dependency graph.

### Validation strategy

**Executed in this run.** A throwaway probe was created under a subdirectory of `$TMPDIR`
with `cargo new --vcs none` (so no nested Git repository was created), built with
`rustc 1.98.0 (88d9e12ae 2026-08-18)` on macOS 26.4 `arm64`, and deleted afterwards. The
manifest declared `edition = "2024"`, `rust-version = "1.96"`, `axum = "=0.8.9"`,
`tokio = "=1.53.1"` with R69's feature list, `tower-http = { version = "0.7.1", features = ["cors"] }`,
and `tower = { version = "=0.5.3", features = ["util"] }` as a **dev-dependency only**.
All checks passed.

| Check | What it ran | Result | Criterion |
|---|---|---|---|
| `A` | `Router::new().route(...)` then `if !origins.is_empty() { app = app.layer(cors) }` | compiles; with an empty slice the response to `GET` + `Origin: https://evil.example` is `200` with headers `{content-length, content-type}` only — **no `access-control-allow-origin`, no `vary`** | 1 |
| `Q1` | same router, `OPTIONS /a` + `Origin` + `Access-Control-Request-Method: GET` on a `GET`-only route | `405`, headers `{allow: GET,HEAD, content-length: 0}` | 2 |
| `Q2` | bare `CorsLayer::new()` installed unconditionally | `GET` → `200` **+ `vary: origin`**; `OPTIONS` → **`200`**, not `405` | falsifies alternative B |
| `Q3` | `CorsLayer::new().allow_origin(Vec::<HeaderValue>::new()).allow_methods(Any).allow_headers(Any)` — the literal py shape with an empty list | `GET` → `200` **+ `vary: origin`**; `OPTIONS` → **`200`** with `access-control-allow-headers: *`, `access-control-allow-methods: *` | falsifies alternative B |
| `C` | allowlist `["https://app.example"]`, `GET` from that origin | `access-control-allow-origin: https://app.example` | 3 |
| `D` | same allowlist, `GET` from `https://evil.example` | no `access-control-allow-origin` (`vary: origin` present) | 4 |
| `E` | same allowlist, preflight `OPTIONS` on a `GET`-only route via `Router::layer` | `200` with `access-control-allow-origin/methods/headers` | 5 |
| `R1` | same, with an `AtomicUsize` counter inside the handler | `status=200 OK handler_hits=0` — the preflight short-circuits before the handler | 5 |
| `P2` / `P3` | preflight to a **non-existent** path, via `.layer()` versus `.route_layer()` | `.layer()` → `200` with only the CORS headers; `.route_layer()` → **`404` with no CORS headers** | why `.layer()` is the right call |
| `H` | `"not a header\n".parse::<HeaderValue>()` | `Err` — an invalid origin cannot reach the layer | 6 |
| `T1` | `cargo metadata --format-version 1 --all-features` on the manifest with and without the `tower-http` line, package sets diffed | delta is exactly `tower-http 0.7.1` and `bitflags 2.13.2`; 57 versus 55 packages | gates 2, 6 |
| `T2` | `rm -rf target && cargo build --release` on both probes, then `strip -x` | 14.1 s → 18.2 s; 746,808 → 895,864 bytes | gate 6 |

An incidental measurement worth recording because it would otherwise look like a defect:
on a **matched** path, the preflight `200` also carries `allow: GET,HEAD`. That header is
axum's, not tower-http's — `tower-http-0.7.1/src/cors/mod.rs:805-815` builds the preflight
response as `Response::new(B::default())` and swaps in only the CORS headers, and check
`P2` (unmatched path) confirms the bare result. Check `R1` proves the handler is still not
invoked. It is cosmetic.

**Planned for P03, not run here** (they need the template, which does not yet exist):

```bash
# 1. The default build never resolves the CORS crate.
cargo tree -p rs-launch-blueprint -e normal | grep -q tower-http && exit 1

# 2. The web member builds with the feature on, on both runners.
cargo build --features web --locked

# 3. The six acceptance criteria, as ordinary integration tests.
cargo test --features web --locked -p rs-launch-blueprint-web cors

# 4. The MSRV gate, over the tree the feature pulls in.
cargo +1.96 check --features web --locked

# 5. No open advisory in the resolved graph.
cargo deny --all-features check advisories
```

Expected behaviour: (1) exits 0 because `tower-http` is behind the optional member; (2)
succeeds on `ubuntu-latest` and `macos-latest`; (3) all six criteria green, with the
empty-allowlist cases asserting the **absence** of `access-control-allow-origin` *and* of
`vary`, and asserting `405` on an unconfigured preflight — the assertion that fails if
anyone ever "simplifies" the branch away; (4) succeeds, since the measured tree maximum is
1.80; (5) exits 0, since the only tower-http advisory is Windows-only, `fs`-only and
patched since 0.2.1.

### Confidence & re-verify trigger

**Confidence: high on the crate, high on the mechanism, medium on the version choice.**

High on the crate because the enumeration was exhaustive over crates.io's `cors` keyword
and the first 40 name matches, three independent well-regarded projects were shown
activating this exact feature by reading their manifest lines, and the framework's own
maintainers document the idiom in their own example. High on the mechanism because the
alternative was not argued away but **measured away**: checks `Q1`/`Q2`/`Q3` show that
installing with an empty allowlist changes two observables. Medium on the version because
`0.7.1` is 18 days old at retrieval and the owner's reference architecture says `0.6`; the
mitigations are that the `cors` module's only 0.7 change is a non-breaking `Vary`
relaxation, that every `**breaking**` 0.7.0 entry is in a module this item does not use,
and that `rust-lang/crates.io` already pins `=0.7.1` in production. If R75's feature list
lands on `trace`, `follow-redirect` or the `compression-*` family, R75 must read those
breaking entries itself rather than inheriting this item's confidence.

**Known evidence gaps, stated rather than papered over.** No published Rust web-service
*template* was found that documents allowlist-gated CORS installation as a named,
reusable pattern with that name. The closest and strongest analogue is a framework, not a
template: `loco-rs/loco` 1.1.0 implements a `MiddlewareLayer` trait whose `is_enabled()`
gates registration (`src/controller/middleware/mod.rs:55-57`), applies it as
`.filter(|m| m.is_enabled())` (`src/controller/app_routes.rs:264-269`), and exposes
`enable: bool` on the CORS config (`src/controller/middleware/cors.rs`). That answers the
LOW question affirmatively for a 9,152-star framework and negatively for templates. No
latency or throughput benchmark was run for the layer, and none is cited from elsewhere.

**Re-verify when any of the following occurs, or by 2027-03-18, whichever comes first:**

- **R69 (`web-framework-stack`) republishes** its `web-extra-surface` value — this report's
  `crates/web/src/cors.rs` and `crates/web/Cargo.toml` paths come from revision 10, which
  is accepted but unpublished; a published value that differs moves every file path in
  `### Migration implications`.
- **R75 (`http-middleware-stack`) publishes**, since it fixes the aggregate `tower-http`
  feature list and this layer's ordering, and must independently read the 0.7.0 breaking
  changes for whichever features it adds.
- **R77 (`web-env-settings`) publishes**, fixing the variable name and the parsed type this
  item consumes as "a possibly-empty `Vec<HeaderValue>`".
- **R02 (`crate-boundary-enforcement`) publishes** a topology other than the four-package
  workspace this design is written against.
- `GET https://crates.io/api/v1/crates/tower-http/versions` shows a newest non-yanked
  `num` outside `0.7.x` — a `0.8` would need its changelog read for `cors` changes.
- `https://rustsec.org/packages/tower-http.html` acquires a third entry, or
  `RUSTSEC-2022-0043`'s `patched` range changes (control:
  `https://rustsec.org/packages/atty.html` must still return 200, so a 404 means the site
  changed, not that the advisory cleared).
- `GET https://api.github.com/repos/tower-rs/tower-http` reports `archived: true`, or
  `pushed_at` falls more than twelve months behind — the rubric's investigate trigger.
- axum publishes `0.9`, which would re-open whether `Router::layer` is still type-preserving
  — the single fact the conditional branch rests on.
- The owner or R75 rules that unconditional `Vary: Origin` and a `200` answer to every
  `OPTIONS` are desirable, which is the stated condition under which the ranked runner-up
  wins.
- `msrv-policy`'s floor advances past **1.96**, which is the number gate 2 was evaluated
  against here.

### Sources

**Pinned source repositories** (read through the pin, never the working tree).
`py-launch-blueprint` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`:
`src/py_launch_blueprint/web/app.py:126-141` (the middleware block and the
`if settings.cors_origins:` guard at `:136`);
`src/py_launch_blueprint/web/settings.py:24-29` and `:60-62` (boot-time validation, the
`PLBP_WEB_CORS_ORIGINS` JSON-list form, the `cors_origins: list[str] = []` default and its
comment); `tests/web/test_app.py:112-126` (`test_cors_off_by_default`,
`test_cors_enabled_via_settings`) and `:232-246`
(`test_cors_preflight_gets_request_id_and_security_headers`);
`tests/web/test_settings.py:26` and `:35-39`; `docs/adr/0013-web-service-best-practices.md:40-41`
and `:48-50`; `docs/design/0002-web-api-conventions.md:61-62`; `docs/source/web/index.md:43`;
`uv.lock:2528-2529` (`starlette` 1.3.1) and `:479-481` (`fastapi` 0.136.3).
`ts-launch-blueprint` at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`:
`git ls-tree -r --name-only cb1cbcb2` filtered for `web|cors|hono|server` returns no files
— there is no web service and no CORS shape to reconcile with.

**Programme documents.** `docs/port/COMMONALITY.md:326` (row `F322`);
`docs/port/areas/web-service.md:28` and `:100`; `docs/port/PARAMETERS.md` (all six consumed
rows, quoted byte-identically above); `docs/port/README.md` (verdict vocabulary);
`docs/planning/p02/owner-decisions.md` §11 (the reference architecture as a standing input)
and its "Two things you should know" section (the strict reading of the MSRV gate applied
in `### Excluded by gate`);
`inputs/owner-reference-axum-companion-stack-2026-09-16.md` lines 31, 49, 80, 87, 114, 141
and 420-421; `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`
(revision 10, `- owns web-extra-surface` at line 1791);
`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md` (revision 1, the
four-package workspace and its `crates/web` member);
`research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md` (revision 2,
synchronous core with `spawn_blocking` in the handlers).
`docs/port/BASELINE-REVIEW.md` was searched for `F322` and `R76`; neither appears, which is
consistent with `F322` being a `DIVERGENT` row rather than an inherited baseline.

**Registry and forge endpoints** (all retrieved **2026-09-18**, UTC).
`GET https://crates.io/api/v1/crates?q=cors&per_page=40`;
`GET https://crates.io/api/v1/crates?keyword=cors&per_page=30&sort=downloads`;
`GET https://crates.io/api/v1/crates/tower-http`;
`GET https://crates.io/api/v1/crates/tower-http/versions`;
`GET https://crates.io/api/v1/crates/tower-http/reverse_dependencies?per_page=25`;
`GET https://crates.io/api/v1/crates/axum_cors` and `/versions`;
`GET https://crates.io/api/v1/crates/tower-http-cors-config` and `/versions`;
`GET https://crates.io/api/v1/crates/actix-cors` and `/versions`;
`GET https://crates.io/api/v1/crates/loco-rs` and `/versions`;
`GET https://api.github.com/repos/tower-rs/tower-http`;
`GET https://api.github.com/search/issues?q=repo:tower-rs/tower-http+is:issue+is:open`;
`GET https://api.github.com/repos/tower-rs/tower-http/issues?state=all&sort=created&direction=desc&per_page=100`;
`GET https://api.github.com/repos/tower-rs/tower-http/issues/comments?sort=created&direction=desc&per_page=100`;
`GET https://api.github.com/repos/tokio-rs/axum`;
`GET https://api.github.com/repos/tokio-rs/console`;
`GET https://api.github.com/repos/hyperium/tonic` (redirects to `grpc/grpc-rust`);
`GET https://api.github.com/repos/loco-rs/loco`;
`GET https://api.github.com/repos/webc-site/npm`;
`GET https://api.github.com/repos/tomharmon/tower-http-cors-config`;
`GET https://api.github.com/repos/loco-rs/loco/contents/{Cargo.toml,src/controller/middleware/cors.rs,src/controller/middleware/mod.rs,src/controller/app_routes.rs,src/boot.rs}`;
`https://rustsec.org/packages/tower-http.html`, `.../actix-cors.html` (404),
`.../tower.html` (404), `.../axum.html` (404), `.../atty.html` (200, the control);
`https://raw.githubusercontent.com/rustsec/advisory-db/main/crates/tower-http/RUSTSEC-2022-0043.md`;
`https://raw.githubusercontent.com/tower-rs/tower-http/main/tower-http/CHANGELOG.md`;
`https://raw.githubusercontent.com/tower-rs/tower-http/main/.github/workflows/CI.yml`;
`https://raw.githubusercontent.com/tokio-rs/axum/main/examples/cors/src/main.rs` and
`.../examples/cors/Cargo.toml`;
`https://raw.githubusercontent.com/tokio-rs/console/main/console-subscriber/Cargo.toml`;
`https://raw.githubusercontent.com/hyperium/tonic/master/tonic-web/Cargo.toml`;
`https://raw.githubusercontent.com/rust-lang/crates.io/main/Cargo.toml`;
`https://raw.githubusercontent.com/encode/starlette/1.3.1/starlette/middleware/cors.py`;
`https://docs.rs/axum-extra/0.12.6/axum_extra/middleware/fn.option_layer.html` (HTTP 200);
`https://fetch.spec.whatwg.org/#http-cors-protocol` (cited as the normative definition).

**Source read from resolved artifacts** (the exact crates this run's lockfile selected,
read from the local Cargo registry checkout): `tower-http-0.7.1/Cargo.toml:67-161`
(`default = []`, `cors = []`); `tower-http-0.7.1/src/lib.rs:200` (`#![deny(unsafe_code)]`);
`tower-http-0.7.1/src/cors/mod.rs:1-47` (module docs), `:109-139`
(`CorsLayer::new`/`permissive`), `:450-479` (`vary`, `update_vary_header` — the #674
relaxation), `:699-741` (`Service::call`, the `OPTIONS` short-circuit at `:715`), `:805-815`
(the preflight response), `:820-830` (`ensure_usable_cors_rules`), `:851-857`
(`preflight_request_headers`); `tower-http-0.7.1/src/cors/allow_origin.rs:32-105`;
`tower-http-0.7.1/src/cors/vary.rs:40-44`;
`tower-http-0.7.1/src/services/fs/serve_dir/tests.rs:1233-1246` (the sole `unsafe`);
`tower-0.5.3/src/util/mod.rs:1067` (`option_layer`) and `tower-0.5.3/Cargo.toml:151-156`
(the `util` feature).

**Method notes.** Figures came from the endpoints listed above and nowhere else; no number
in this report was recalled. crates.io was queried with `curl -sS` carrying a `User-Agent`
header; GitHub through the keyring-authenticated `gh api`, with at least 20 seconds between
calls; RustSec by `curl` with the `atty` control confirming the site was serving 200s for
crates that do have advisories. Behavioural claims were executed, not inferred: a probe
crate created with `cargo new --vcs none` under a subdirectory of `$TMPDIR` (removed after
the run, and no nested Git repository created at any point) pinned `axum =0.8.9`,
`tokio =1.53.1`, `tower-http 0.7.1 (features = ["cors"])` and `tower =0.5.3` as a
dev-dependency, and ran the twelve checks tabulated in `### Validation strategy` on
`rustc 1.98.0` / macOS 26.4 `arm64`. **What could not be verified:** no latency or
throughput measurement of the layer was attempted, so no performance figure is claimed
beyond the compile-time and binary-size deltas of checks `T1` and `T2`, which were measured
on a near-empty probe and whose percentage form should not be carried forward. The
issue-responsiveness median is reported as two figures rather than one because eight of the
ten most recent issues carry no maintainer comment and four of those were closed without
one, so a single median would be an invention. Whether `RUSTSEC-2022-0043` is ever reported
against 0.7.1 by `cargo audit` was not executed — the advisory's own `patched` range was
read instead. Windows behaviour was not exercised; `target-os-matrix` does not include it
and the only Windows-specific code in `tower-http` is in the `fs` feature this item does not
enable. The Codex research leg for this item is deferred under owner ruling W1-CODEX3, so no
second engine's findings were available to cross-check these figures against.
