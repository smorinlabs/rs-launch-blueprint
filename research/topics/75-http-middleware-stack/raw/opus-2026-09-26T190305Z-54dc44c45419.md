# R75 http-middleware-stack — Opus raw report

Engine: Claude Opus 5.5 (`claude-opus-5-5`), fresh context, CLI run 2026-09-26. Item kind `bundle`,
Deep tier. This leg read only the item prompt, the run's `inputs/`, the R69 decision it depends on,
the owner-supplied reference document, the two source repositories and primary upstream sources. It
did not open any other engine's report.

**Retrieval date.** Every figure and every upstream file below was retrieved on **2026-09-26**
(America/Los_Angeles). The probe's log timestamps read `2026-09-27T01:2x Z` because they are UTC.

**Endpoints used.** `https://crates.io/api/v1/crates/<name>`, `.../versions`, `.../dependencies`,
`.../reverse_dependencies`, `https://static.crates.io/crates/<name>/<name>-<ver>.crate` (published
source), `https://api.github.com/repos/<o>/<r>` and its `/contents`, `/commits` and
`/search/issues` endpoints (authenticated `gh api`, REST), and `https://rustsec.org/packages/<name>.html`.
Two sources outside that set are cited but were **not** retrieved in this run; each is labelled
where it is used.

**Toolchain.** `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` / `cargo 1.98.1`, and
`rustc 1.96.0 (ac68faa20 2026-05-25)` through rustup, on macOS aarch64. Under `msrv-policy`
("stable minus 2 minor versions") the floor today is **1.96**.

**Executed evidence.** A scratch probe crate at `/tmp/r75/probe`, outside this repository and not
committed, ran the acceptance check described under `### Validation strategy`. Its file hashes are
recorded there so that a later run can reproduce it byte-for-byte. Every check in this report is
labelled either **executed** (run in this leg, with its observed output) or **proposed** (not run).

### Landscape

**The category this item decides.** This item decides the *HTTP middleware composition* of the
template's web service. It covers four concerns and one contract:

- request-id propagation;
- one canonical structured access-log event per request, with probe routes excluded;
- unconditional security response headers;
- a stated outermost-to-innermost order, with the id and security-header layers outermost;
- folding the framework's and server's own log output into the shared `tracing` pipeline.

R69 has already fixed the framework: `axum` 0.8.9 on `tokio` 1.53.1, behind an off-by-default
`web` feature (`research/topics/69-web-framework-stack/DECISION.md:1586`). The question is
therefore which layer model, which crates and which order fit **axum's `tower` layer model**.
R69's own wording hands `tower-http` to this item:
"`tower-http` (R75's to select)" (`DECISION.md:694`).

**Three-bin map.**

| Bin | Candidates found | Role |
|---|---|---|
| Built-in / first-party toolchain | `axum::middleware::from_fn` and `from_fn_with_state` (axum first-party); `axum::Router::layer` / `route_layer`; `axum::extract::MatchedPath`; `axum::error_handling::HandleErrorLayer`; `tower::ServiceBuilder` and `tower::Layer` (the tokio-rs/tower-rs substrate axum is built on); `tracing` macros and spans (tokio-rs, the de-facto facade); `std::panic::set_hook` | composition mechanism, route template, hand-written layers, log facade |
| Established industry standard | `tower-http` 0.7.1: `request_id::{SetRequestIdLayer, PropagateRequestIdLayer, MakeRequestUuid}`, `set_header::response::{SetResponseHeaderLayer, SetMultipleResponseHeadersLayer}`, `trace::TraceLayer`, `catch_panic::CatchPanicLayer`, `timeout::TimeoutLayer`, `cors::CorsLayer`, `sensitive_headers`; `tracing-subscriber` (pipeline side, R58's) | ready-made layers for every concern except the probe-route exclusion policy |
| Up-and-comer | `axum-helmet` 1.0.2 + `helmet-core` 1.0.1 (helmet.js port, 1.0 in 2026-05); `axum-tracing-opentelemetry` 0.39.1 (OTel-first request span; R78's field); `tower-request-id` 0.3.0 (ULID ids; quiet since 2023); `tower-helmet` 0.3.0; `tower-default-headers` 0.2.3; loco-rs's configurable middleware stack (a framework on axum, not a crate one adopts piecemeal) | alternatives for single concerns |

Every candidate evaluated under `### Members` comes from this map.

**Authoritative sources, and why each counts.**

| Source | Why it is authoritative | Used for |
|---|---|---|
| axum 0.8.9 published source, `src/docs/middleware.md` "Ordering", `src/routing/mod.rs:303-317`, `src/serve/*.rs`, `src/macros.rs` (static.crates.io, 2026-09-26) | The framework maintainers' own documentation and code at the version R69 fixed | Layer direction; `Router::layer` covers the fallback; axum's own log emissions |
| tower-http 0.7.1 published source and `CHANGELOG.md` (static.crates.io, 2026-09-26) | The maintainers' code at the current version | Exact semantics of request-id, set-header, trace, catch-panic and timeout |
| tokio-rs/axum `examples/request-id/src/main.rs` at `bc8d4912435204a4a073cea70355ae0328d263fe` (api.github.com, 2026-09-26) | The framework maintainers' reference example | Canonical `set_x_request_id` → `TraceLayer` → `propagate_x_request_id` order |
| tracing 0.1.44 published source, `src/span.rs:1244-1261` | Maintainers' code | `Span::none()` versus a disabled span |
| rust-lang/crates.io `src/middleware.rs` and `src/middleware/log_request.rs` at `067b45e1a15fc1b97f7321792b86bdf8d6371d7c` (api.github.com, 2026-09-26) | The Rust project's own production registry service, running axum and `tower-http` `=0.7.1` | Production precedent for a hand-written access-log layer and hand-written common headers |
| OWASP Cheat Sheet Series, `cheatsheets/REST_Security_Cheat_Sheet.md` §"Security Headers" at `c04039adbe6f727a2198b3a3ea634fec98ac068a` (api.github.com, 2026-09-26) | The widely cited industry security baseline for REST APIs | The header set, and a `BASELINE-REVIEW` for F321 |
| RustSec advisory database package pages (rustsec.org, 2026-09-26) | The Rust Secure Code working group's advisory database | Gate 3 |
| RFC 6797 §8.1 (HSTS over insecure transport), `https://www.rfc-editor.org/rfc/rfc6797#section-8.1`, **not retrieved in this run** (endpoint outside the allowed set) | IETF standard | Why HSTS over plain http in development is harmless |
| WHATWG Fetch Standard, "CORS check", `https://fetch.spec.whatwg.org/#cors-check`, **not retrieved in this run** | The browser standard | Why a 429 without CORS headers is unreadable to a cross-origin script |
| Owner-supplied reference, `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` §C11 and §"Level One" | An owner-supplied input, not an authority (its own header says so); owner decision 11 requires every overlapping item to agree on the record or give a ground | Reconciliation, under `### Principles and implementation` |

**Well-regarded projects surveyed, with the evidence that they are well regarded.**

| Project | Evidence of standing | What it uses (source) |
|---|---|---|
| rust-lang/crates.io | The Rust project's package registry; 3,703 stars; pushed 2026-09-27T00:24Z (`GET https://api.github.com/repos/rust-lang/crates.io`) | `tower-http = { version = "=0.7.1", features = ["add-extension", "fs", "catch-panic", "timeout", "compression-full"] }` (`Cargo.toml:168`); a hand-written `from_fn(log_request::log_requests)` access log carrying `MatchedPath`, `request_id`, status and duration (`src/middleware/log_request.rs`); a hand-written `common_headers` layer setting HSTS, `nosniff`, `X-Frame-Options` (`src/middleware/common_headers.rs:38-50`); `ServiceBuilder` stacks applied through `Router::layer` (`src/middleware.rs:41-92`) |
| tokio-rs/axum examples | The framework maintainers' own examples | `examples/request-id`: `ServiceBuilder::new().set_x_request_id(MakeRequestUuid).layer(TraceLayer...make_span_with(... info_span!("http_request", request_id)...)).propagate_x_request_id()` |
| loco-rs/loco | Rails-style framework on axum; 9,266 stars; pushed 2026-09-24 (`GET https://api.github.com/repos/loco-rs/loco`) | `default_middleware_stack` (`src/controller/middleware/mod.rs:76-170` at `9f7e021e9fe68275a9a7e1ab3e7dd25c483d2bd8`) with `request_id`, `logger`, `secure_headers`, `catch_panic`, `cors`, `timeout` middleware; its doc comment states "a middleware **later** in the `Vec` runs **earlier** in request processing (tower is LIFO)" |
| vectordotdev/vector | Datadog's observability pipeline | `tower-http = { version = "0.4.4", default-features = false, features = ["compression-full", "decompression-full", "trace"] }` (`Cargo.toml:355`) — evidence of `trace` adoption, on an old line |

**Reverse dependencies.** `tower-http` has **3,531** reverse dependencies
(`GET https://crates.io/api/v1/crates/tower-http/reverse_dependencies`, `meta.total`).
`axum-helmet` has **2**.

**Figures table (per the prompt's `## Required evidence`).**

| Crate | 90-day downloads | All-time | Last non-yanked release | License / `rust-version` | Stars · archived · pushed | Open issues (search) | RustSec |
|---|---|---|---|---|---|---|---|
| `tower-http` | 155,129,876 | 479,026,426 | 0.7.1, 2026-08-31 | MIT / 1.65 | 918 · false · 2026-09-26 | 32 | RUSTSEC-2022-0043 (the `fs` feature on Windows paths; patched long before 0.7; `fs` is not selected here), RUSTSEC-2021-0135 (withdrawn) → **no open advisory** |
| `tracing` (facade; R58's pipeline) | 198,651,206 | 877,269,566 | 0.1.44, 2025-12-18 | MIT / 1.65.0 | 6,891 · false · 2026-05-30 (tokio-rs/tracing) | 628 (whole repository) | RUSTSEC-2023-0078, patched in 0.1.40 → no open advisory |
| `uuid` (transitive via `request-id`) | 191,550,501 | 829,299,521 | 1.26.1, 2026-09-10 | Apache-2.0 OR MIT / 1.85.0 | 1,247 · false · 2026-09-10 | 10 | no package page (HTTP 404) → none |
| `axum-helmet` | 25,465 | 79,665 | 1.0.2, 2026-05-26 | MIT / not declared | 23 · false · 2026-08-01 (danielkov/rust-helmet) | 0 | 404 → none |
| `helmet-core` | 27,724 | 86,648 | 1.0.1, 2026-05-26 | MIT / not declared | same repository | 0 | 404 → none |
| `tower-helmet` | 1,689 | 29,225 | 0.3.0, 2024-01-29 | MIT / not declared | 5 · false · 2025-11-24 (Atrox/tower-helmet) | 0 | 404 → none |
| `tower-request-id` | 132,590 | 864,121 | 0.3.0, 2023-12-02 | MIT / not declared | 33 · false · 2023-12-02 (imbolc/tower-request-id) | 1 | 404 → none |
| `tower-default-headers` | 1,659 | 17,727 | 0.2.3, 2025-11-28 | MIT / not declared | GitLab; not measured | not measured | none listed |
| `axum-tracing-opentelemetry` | 2,386,325 | 16,371,187 | 0.39.1, 2026-08-30 | CC0-1.0 / 1.91.0 | 249 · false · 2026-09-23 | 7 | 404 → none |

Endpoints: download and release columns from `GET https://crates.io/api/v1/crates/<name>` fields
`crate.recent_downloads`, `crate.downloads`, and the newest `versions[]` entry with `yanked: false`
(`num`, `created_at`, `license`, `rust_version`). Stars, archived and pushed from
`GET https://api.github.com/repos/<o>/<r>`. Open issues from
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` → `total_count`.
RustSec from `https://rustsec.org/packages/<name>.html`. `axum` 0.8.9 figures are R69's and are not
re-fetched here; `tower` 0.5.3 is 178,757,718 / 687,830,161, MIT, `rust-version` 1.64.0.

**Issue responsiveness, `tower-rs/tower-http`.** Method: the 10 most recently opened issues
(`search/issues?q=repo:tower-rs/tower-http+is:issue&sort=created&order=desc&per_page=10`). For each,
the first comment whose `author_association` is `OWNER`, `MEMBER` or `COLLABORATOR` and whose
author is not the issue's author. Result: **2 of 10 received a maintainer comment**, #713 after
0.0 days and #702 after 0.2 days, so the **median is 0.1 days over the answered pair**. **8 of 10
have no maintainer comment**: #741, #740, #737, #736, #732, #731, #725 and #701. Two of those
eight are closed: #736, and #725, which a `MEMBER` opened. Six of the eight were opened in the 30
days before retrieval. This is a weak comment-responsiveness signal. It is offset by the release
cadence: five releases in 2026 (0.6.9 on 05-05, 0.6.10 on 05-06, 0.6.11 on 05-18, 0.7.0 on 06-15,
0.7.1 on 08-31) and a push on the retrieval day. **Maintenance state: `active`.**

### Principles and implementation

**Shared requirement and its source.** The source precedent is py-launch-blueprint at
`b55b8c26364cb0f42e56116e6780921976334751` (2026-09-22), read directly for this report. ts has no
web service (`docs/port/areas/web-service.md:100`; `ts: package.json — no web/HTTP-framework
dependency present`). The six ledger rows state one engineering principle:

> Every HTTP response is attributable and hardened, and every request leaves exactly one
> bounded-cardinality structured record in the one shared log pipeline. This holds even when a
> layer short-circuits the request.

**Agreement level, per row.** "Must agree" is the owner-level policy or behaviour. "May vary" is
the mechanism.

| Row | Must agree (level) | May vary | py evidence |
|---|---|---|---|
| F317 order | **Architectural pattern**: id and security-header layers wrap everything that can short-circuit (CORS preflight, 429, panic, timeout) | How order is expressed in code | `web/app.py:127-146` — comment "added inside-out: the last add_middleware runs first", `add_middleware(SecurityHeadersMiddleware)` then `add_middleware(RequestIDMiddleware)` |
| F318 request id | **Capability + policy**: accept the inbound `x-request-id` or generate one; bind it to the log context; echo it on the response | Id format (py `uuid4().hex`, 32 hex digits; tower-http `Uuid::new_v4()` hyphenated) | `web/middleware.py:72-73, 82` |
| F319 access event | **Policy**: one `http_request` event per request with method, route **template**, path, status, `duration_ms`, request id; logged even when the handler fails (as a 500) | Emitting mechanism; field serialization belongs to R58 | `web/middleware.py:75-83, 87-108` |
| F320 probe exclusion | **Policy**: `/healthz`, `/readyz`, `/metrics` produce no access event | Match on the raw path (py) versus the matched route template | `web/middleware.py:47-51, 89-90` |
| F321 security headers | **Policy**: stamped on every response; a handler-set value wins (`setdefault`) | Header set may be improved (see `BASELINE-REVIEW: F321`) | `web/middleware.py:56-61, 119-120` |
| F327 server logs | **Principle**: the server's own output flows through the shared pipeline, and no second access line exists | The mechanism is inherently framework-specific | `web/logging.py:61-73` — `uvicorn`/`uvicorn.error` handlers cleared and propagated; `uvicorn.access` cleared with `propagate = False` |

**Is the shared architectural pattern still appropriate in Rust? Yes, and the Rust analogue is
exact.** py's `add_middleware` stack is an onion in which *the last added runs first*. axum
documents the same onion for `Router::layer`: "each new layer wraps all previous layers … First
`layer_three` receives the request" (axum 0.8.9 `src/docs/middleware.md:61-116`). So a
layered-`Service` composition, with each concern as its own `tower::Layer` in a defined order, is
the idiomatic analogue (**HIGH question 1**).

**Direction must be stated, because the two axum idioms run in opposite directions**
(**HIGH question 2**):

- chained `Router::layer(a).layer(b).layer(c)` runs **bottom to top**: `c` is outermost, like py;
- `Router::layer(ServiceBuilder::new().layer(a).layer(b).layer(c))` runs **top to bottom**: `a` is
  outermost (`middleware.md:118-150`, "`ServiceBuilder` works by composing all layers into one
  such that they run top to bottom").

This report states the contract as an **outermost → innermost list** and implements it with chained
`Router::layer` calls written innermost-first. That chained form keeps py's "last added is outermost" rule,
and it needs no production `tower` dependency (R69 made `tower` dev-only). The contract list, a
comment in code and an executed test pin the order, so it cannot drift silently.

**Why `Router::layer` and not an outer wrap of the finished `Router`.** axum 0.8.9's
`Router::layer` applies the layer to the path router, the fallback router **and** the catch-all
fallback (`src/routing/mod.rs:311-316`). So 404s and 405s pass through the stack. Because the layer
wraps each route *after* routing, `MatchedPath` is present in request extensions when the access
layer runs. An outer wrap around the whole `Router` service would run before routing and could not
see the route template. **Executed:** the `not-found` case logged `route` absent (null) with status
404, and every matched case logged `route = "/v1/projects/{id}"` (see `### Validation strategy`).

**Ready-made versus hand-rolled** (**HIGH question 1**, second half):

| Concern | Ready-made in the ecosystem? | Chosen |
|---|---|---|
| Request id | **Yes**: `tower-http` `SetRequestIdLayer` accepts an inbound id or calls `MakeRequestId`, and stores `RequestId` in request extensions (`request_id.rs:330-343`). `PropagateRequestIdLayer` copies it to the response unless the response already has one (`request_id.rs:405-465`) | ready-made |
| Security headers | **Yes**: `tower-http` `SetMultipleResponseHeadersLayer::if_not_present` (added 0.6.11; `Clone` for any body since 0.7.1). One layer; py's `setdefault` semantics exactly | ready-made |
| Access event with probe exclusion | **Partly**: `TraceLayer` gives a span and `on_response`, but `on_response` cannot see the request, so exclusion needs the `Span::none()` trick, and route and id live only on the span | **hand-written** `axum::middleware::from_fn` (≈35 lines), with `TraceLayer` as the executed runner-up |
| Panic → 500 | **Yes**: `tower-http` `CatchPanicLayer`; emits `tracing::error!("Service panicked: …")` (`catch_panic.rs:341-345`) | ready-made |
| Per-request timeout (handed from R69, `DECISION.md:943-944`) | **Yes**: `tower-http` `TimeoutLayer::with_status_code` (the `new` constructor is deprecated since 0.6.7, `timeout/service.rs:29`) | ready-made |
| Server-log fold-in | Nothing to install. axum and hyper ship no access logger (see Member 5) | pattern |

**Architectural alternatives compared before choosing libraries.**

1. **Per-concern tower layers composed by `Router::layer`** (recommended). Each concern is testable
   alone. The order is visible in one function. It matches axum's documented model and the
   maintainers' `request-id` example.
2. **One monolithic hand-written middleware**, the way py's `RequestIDMiddleware` does id and access
   log together. Fewer types, but it bundles three concerns. Positioning then cannot vary per
   concern, for example keeping headers outside the access log. Rejected. The access log alone is
   hand-written; id and headers use ready-made layers.
3. **Framework-level stack configuration** (loco's `Vec<Box<dyn MiddlewareLayer>>` with
   `insert_before`/`insert_after`). This is excellent for a framework, but it adds dynamic dispatch
   and a registry for a template with fewer than 10 layers. Rejected for fit; it is also R69's
   rejected registry pattern (F331).
4. **OTel-first instrumentation** (`axum-tracing-opentelemetry` as the request span). It fits R78
   rather than this item. The ordering contract leaves an explicit R78/R79 slot.

**The recommended ordering contract** (**HIGH question 2**). Layers are listed outermost first,
which is the order a request meets them:

| # | Layer | Owner | Why here |
|---|---|---|---|
| L1 | `SetRequestIdLayer::new(x-request-id, MakeRequestUuid)` | R75 | The id must exist before anything logs or can short-circuit |
| L2 | `SetMultipleResponseHeadersLayer::if_not_present(SECURITY_HEADERS)` | R75 | Stamps every response any inner layer produces (429, preflight, 408, panic-500) |
| L3 | `PropagateRequestIdLayer::new(x-request-id)` | R75 | Echoes the id on every inner response |
| L4 | *slot:* R78 OTel request span / R79 metrics | R78, R79 | Inside L1, so the id exists; outside L5, so the access event nests in the trace |
| L5 | `from_fn(access_log)`: the one `http_request` event, probe routes excluded | R75 | Outside every short-circuiting layer, so 429s, preflights, timeouts and panics are each logged once |
| L6 | `CatchPanicLayer::new()` | R75 | Turns a handler panic into a 500 that L1–L5 then treat as a normal response |
| L7 | *slot:* `CorsLayer`, only when configured | R76 | Outside L8, so 429s carry `Access-Control-Allow-Origin` (see `BASELINE-REVIEW: F317`) |
| L8 | *slot:* rate limit, only when configured | R74 | Rejects before any work |
| L9 | `TimeoutLayer::with_status_code(408, <duration>)` | R75 (value named by R77) | Bounds handler time; outside idempotency, so replays are bounded too (R73 to confirm) |
| L10 | *slot:* idempotency | R73 | Innermost, closest to the handler whose response it stores |
| — | routes / handlers | R69, R70-R72 | — |

**Constraints the contract imposes on R73, R74 and R76** (from `src/routing/mod.rs:303-309`):

- Every slot layer must satisfy `Router::layer`'s bounds: `Clone + Send + Sync + 'static`, and a
  service error of `Into<Infallible>`.
- A fallible layer is wrapped with `axum::error_handling::HandleErrorLayer` in the same slot. The
  wrapper does not create a new position in the order.
- Conditional slots (L7, L8) are applied with a plain `if`/rebinding, so an absent layer leaves the
  order of the rest unchanged. No `option_layer` or `Either` dependency is needed.
- Shared state, such as the idempotency store or a rate-limit quota, must sit behind an `Arc`:
  `Router::layer` clones the layer into every route (`routing/mod.rs:312-315`).

**Why the access-log layer is hand-written** (**MEDIUM question 1**). Both designs were built and
both passed all nine acceptance cases (executed). The discriminator is **where the fields land**.

- With `TraceLayer`, `route`, `path`, `method` and `request_id` are *span* fields. The event itself
  carries only `status` and `duration_ms`. Whether a sink sees them depends on the formatter's
  span handling: `tracing-subscriber`'s JSON `with_current_span`, or an OTel log bridge. That
  handling is **R58's undecided** pipeline (`inputs/prerequisites.json`: R58 decision `missing`).
- With `from_fn`, every field is on the event. The canonical record is complete under any
  formatter, like py's one `log.info("http_request", …)`.

It is also the design crates.io runs in production (`src/middleware/log_request.rs`: one `event!`
with `MatchedPath`, `request_id`, `status_code`, duration). The `TraceLayer` variant additionally
needs `on_request(())`, `on_body_chunk(())`, `on_eos(())` and `on_failure(())`: its defaults emit
a DEBUG request event, a DEBUG response event and an ERROR failure event. It also needs the
`Span::none()` exclusion trick. That trick is correct, because `Span::is_none()` is
`is_disabled() && meta.is_none()` (`tracing` `src/span.rs:1259-1261`), so a span merely filtered
out by level is not mistaken for an exclusion. But the trick is non-obvious.

**Probe exclusion** (**MEDIUM question 2**). A policy constant,
`ACCESS_LOG_EXCLUDED_ROUTES: &[&str] = &["/healthz", "/readyz", "/metrics"]`, is matched against
the **matched route template**, not the raw path. So `/healthz/` or `/healthz?x=1` cannot evade or
spoof the list, and a 404 on an unknown path is still logged. That is a deliberate
mechanism difference from py, which compares `request.url.path`. The *policy* is unchanged: probe
routes produce no access event, but they **still** receive the request id and security headers
(executed: `probe` case, 0 events, header present). A route-level opt-out, meaning a separate
un-logged probe router merged in, was considered and rejected. The access layer must wrap CORS
and rate limiting to log 429s and preflights, so a per-router opt-out would split the stack in two.
It would also make R80's probes depend on the merge order.

**One event, and what happens on failure.** L5 emits exactly one `http_request` event per
non-probe request. Two other records can accompany it:

- On a handler panic, `CatchPanicLayer` emits one separate ERROR event, `target =
  "tower_http::catch_panic"`, inside the request span, so it carries `request_id`. This mirrors
  py, where the 500 problem handler logs the traceback and the access line is emitted separately.
- The **Rust standard library's default panic hook** also prints a plain-text
  `thread '…' panicked at …` line to stderr. That line bypasses the pipeline, so it is the one
  real residual double-log. Executed: observed in the probe's captured stderr. It is handed to R58
  under Member 5.

**Framework and server log fold-in** (**MEDIUM question 3**). This is detailed in Member 5 and
`BASELINE-REVIEW: F327`. In short: axum 0.8.9's own output is `tracing` events: `error!("accept
error: {e}")` at `serve/listener.rs:156`, and `trace!` connection lifecycle at
`serve/mod.rs:278-408`. Those events exist only under the `tracing` feature, which R69's owned value
enables. hyper 1.11.1 emits nothing in this build: its `tracing` feature is off, and it additionally needs
the `hyper_unstable_tracing` cfg. Neither ships an access logger. So in Rust there is no
analogue of uvicorn's access line to silence. The fold-in is automatic once R58 installs the global
subscriber. It does **not** depend on R69's pick among `tower`-based frameworks, but it would for
`actix-web`, whose `middleware::Logger` writes through the `log` crate.

**Cross-repo principles** (**HIGH question 3**):

| Ecosystem | State | Classification | Justified difference / follow-on |
|---|---|---|---|
| py | All six behaviours present. Rate limit sits outside CORS, so 429s lack CORS headers. The header set lacks CSP `frame-ancestors`. Exclusion matches the raw path | Reference, with two accidental drifts against current guidance | Follow-on: move `SlowAPIMiddleware` inside CORS; add the two OWASP headers (`BASELINE-REVIEW: F317`, `F321`) |
| ts | No web service | **Missing capability, not drift**; ts has no server (`TS_PORT_DECISIONS.md` records no web decision) | None until ts gains a server. If it does, the same six policies apply at the same levels (for example, Fastify `onRequest`/`onResponse` hooks with `genReqId`). That is an unexamined lead, not researched here |
| rs | This report | Native design | Differences that preserve the principle: id format (hyphenated UUID); exclusion keyed on the route template; F327 needs no silencing step; the access event is logged even on panic through `CatchPanicLayer` rather than `try/except` |

No shared low-level *value* is recommended across ecosystems except the policy constants, which are
owner-level: the header name `x-request-id`, the event name `http_request`, the probe-route list
and the security-header set. Keeping them identical makes cross-service log queries and
header checks uniform.

**Owner-supplied reference (owner decision 11), §C11 and §"Level One", reconciled row by row.**

| Reference row | Disposition | Ground |
|---|---|---|
| "Level One — `SetRequestIdLayer`/`PropagateRequestIdLayer` … don't add crates for these" | **Agree** | Member 1 is exactly that pair |
| C11: security headers "hand-rolled" via `SetResponseHeaderLayer` | **Agree on the family; differ on the type**: one `SetMultipleResponseHeadersLayer::if_not_present` (0.6.11+) instead of four single-header layers | Same crate. One layer, one position, py's `setdefault` semantics |
| C11 order: `… → CompressionLayer → security headers via SetResponseHeaderLayer`, which places security headers **innermost** | **Differ** | That order contradicts F317 and this item's Decision. **Executed negative control** (`tests/negative_control.rs`): with headers innermost, the 429 and the CORS preflight both returned **without** `X-Frame-Options` |
| C11 order: `SetSensitiveHeadersLayer → TraceLayer → SetRequestIdLayer/PropagateRequestIdLayer`, which places `TraceLayer` **outside** the id layer | **Differ** | The span is created before the id exists. **Executed:** in the same negative control, the access span recorded `"request_id":"-"` for both requests. axum's own `request-id` example puts `set_x_request_id` first |
| C11: `CatchPanicLayer` inside `TraceLayer` | **Agree** (L6 inside L5) | Panics are logged as 500s, executed |
| C11: `SetSensitiveHeadersLayer` outermost | **Not adopted here; no conflict** | It redacts headers from `TraceLayer`/`Debug` output. The recommended access event logs no headers. Revisit if R78 or R58 log request headers |
| C11: `CorsLayer`, `TimeoutLayer` position | **Agree** that CORS sits outside the timeout, and adopt the timeout in L9 | — |
| C11: `NormalizePathLayer`, `RequestBodyLimitLayer`, `CompressionLayer` | **Hand-off: not decided here** | No ledger row in this item. They would sit between L6 and L10 if another item adopts them |
| C11: rate limiting `tower_governor` 0.8 | **Hand-off to R74** | L8 slot |
| TL;DR and reference `Cargo.toml`: `tower-http 0.6` | **Differ on version** | The current line is 0.7.1 (2026-08-31). 0.6 → 0.7 breaking changes touch `compression`, `follow-redirect`, `trace`/`classify` gRPC types and removed no-op features (`CHANGELOG.md` 0.7.0). None of them touches the four features selected here |

**Maturity, dependability, performance and integration cost.**

- **Maturity and dependability:** `tower-http` is maintained under the tower-rs organisation
  alongside `tower`, and it is the crate crates.io pins to `=0.7.1`. It carries
  `#![deny(unsafe_code)]` (`src/lib.rs:200`). Its CI tests stable, beta and nightly on
  ubuntu-latest, `macos-latest` and `windows-latest`, plus an MSRV job and `cargo hack check
  --each-feature` (`.github/workflows/CI.yml:18-92`, default branch, 2026-09-26).
- **Performance:** not benchmarked. Each layer is a header-map insert or an `Arc` clone per
  request. No unlike-benchmark claim is made. One real cost does exist: long `ServiceBuilder` type
  chains can explode compile time. crates.io split its stack for that reason (`src/middleware.rs:34-39`,
  citing rust-lang/crates.io PR 7443). Chained `Router::layer` calls box each layer into `Route`,
  which avoids a single giant type.
- **Integration cost:** one optional dependency, `tower-http`, with four features. The resolver adds
  **5 packages** to the normal-dependency tree: 58 unique packages with it versus 53 without
  (`cargo tree -e normal --prefix none | sort -u | wc -l`, probe manifest, executed). A clean
  `cargo build --release` of the probe library took `real 12.82 s` on this machine (Apple silicon,
  `/usr/bin/time -p`, executed). That is a single data point, not a benchmark.

**Minimal realistic example.** This is the recommended design, condensed from the executed probe;
the handlers are stubs:

```rust
pub const X_REQUEST_ID: HeaderName = HeaderName::from_static("x-request-id");
pub const ACCESS_LOG_EXCLUDED_ROUTES: &[&str] = &["/healthz", "/readyz", "/metrics"];

fn security_headers() -> SetMultipleResponseHeadersLayer<Response> {
    SetMultipleResponseHeadersLayer::if_not_present(vec![
        (header::X_CONTENT_TYPE_OPTIONS, HeaderValue::from_static("nosniff")).into(),
        (header::X_FRAME_OPTIONS, HeaderValue::from_static("DENY")).into(),
        (header::REFERRER_POLICY, HeaderValue::from_static("no-referrer")).into(),
        (header::STRICT_TRANSPORT_SECURITY,
         HeaderValue::from_static("max-age=63072000; includeSubDomains")).into(),
    ])
}

pub async fn access_log(req: Request, next: Next) -> Response {
    let route = req.extensions().get::<MatchedPath>().map(|m| m.as_str().to_owned());
    let excluded = route.as_deref().is_some_and(|r| ACCESS_LOG_EXCLUDED_ROUTES.contains(&r));
    let request_id = req.extensions().get::<RequestId>()
        .and_then(|id| id.header_value().to_str().ok()).unwrap_or_default().to_owned();
    let (method, path) = (req.method().clone(), req.uri().path().to_owned());
    let span = tracing::info_span!("request", request_id = %request_id);
    let start = std::time::Instant::now();
    let res = next.run(req).instrument(span.clone()).await;
    if !excluded {
        span.in_scope(|| tracing::info!(
            request_id = %request_id, method = %method, route = route.as_deref(),
            path = %path, status = res.status().as_u16(),
            duration_ms = start.elapsed().as_secs_f64() * 1000.0, "http_request"));
    }
    res
}

/// Outermost → innermost: L1 id · L2 headers · L3 propagate · [L4 R78/R79] · L5 access log ·
/// L6 catch-panic · [L7 R76 CORS] · [L8 R74 rate limit] · L9 timeout · [L10 R73 idempotency].
/// Written innermost-first: each `.layer()` wraps everything above it (axum "Ordering").
pub fn apply_middleware(router: Router, cors: Option<CorsLayer>) -> Router {
    let r = router.layer(TimeoutLayer::with_status_code(StatusCode::REQUEST_TIMEOUT, TIMEOUT));
    // [L8: R74 rate limit, when configured]
    let r = match cors { Some(c) => r.layer(c), None => r };
    r.layer(CatchPanicLayer::new())
        .layer(middleware::from_fn(access_log))
        // [L4: R78/R79]
        .layer(PropagateRequestIdLayer::new(X_REQUEST_ID))
        .layer(security_headers())
        .layer(SetRequestIdLayer::new(X_REQUEST_ID, MakeRequestUuid))
}
```

**Executable acceptance check.** It is described fully under `### Validation strategy`. It was
**executed** against axum 0.8.9 and tower-http 0.7.1 on rustc 1.98.1 and 1.96.0 (macOS). Three
tests passed:

- 2 acceptance tests, one per access-log variant, each covering 9 cases;
- 1 negative control.

Ubuntu was **not** executed in this leg.

**BASELINE-REVIEW findings.**

- `BASELINE-REVIEW: F327 — the server's own output flows through the shared pipeline and no second
  access line exists — in rs, record F327 as satisfied by construction rather than by a silencing
  step: axum/hyper ship no access logger, axum's own diagnostics are tracing events under its
  tracing feature, and tracing's log feature (enabled via axum tower-log → tower log) forwards to
  the log crate only when no tracing subscriber is set; the one residual plain-text emitter is
  std's default panic hook, handed to R58 — evidence: axum 0.8.9 src/serve/listener.rs:156,
  src/serve/mod.rs:278-408, src/macros.rs:70-95; hyper 1.11.1 src/trace.rs:5-9 (tracing needs
  --cfg hyper_unstable_tracing; feature off in the tree); tracing 0.1.44 src/lib.rs:647-660;
  probe cargo tree -e features -i tracing; probe
  stderr "thread '…' panicked at src/lib.rs:84:51" beside the structured tower_http::catch_panic
  ERROR event.` Affected items: R58 (`logging-pipeline-architecture`, F263 split), and R69 only
  in that its `tracing` default feature must stay on.
- `BASELINE-REVIEW: F317 — id/security-header layers outermost so short-circuits still carry them
  — keep that, and additionally fix the inner order CORS ⊃ rate-limit (py has SlowAPIMiddleware
  outside CORSMiddleware, so its 429s carry no Access-Control-Allow-Origin and a browser script
  sees a CORS failure instead of a 429; preflights are also charged against the quota) — evidence:
  py src/py_launch_blueprint/web/app.py:137-146 at b55b8c26; WHATWG Fetch "CORS check" (not
  retrieved this run).` Affected items: R74, R76, and the py follow-on.
- `BASELINE-REVIEW: F321 — conservative security headers on every API response, handler value
  wins — add Content-Security-Policy: frame-ancestors 'none' and Cache-Control: no-store to py's
  four (OWASP lists both among headers that "should be included in all API responses that may be
  consumed by browser clients"); if_not_present keeps HTML docs routes (R71) and cacheable routes
  (R72/R80) able to override — evidence: OWASP REST_Security_Cheat_Sheet.md §Security Headers at
  c04039ad, lines 185-194; py web/middleware.py:56-61.` Affected items: R71, R72, R80, and the py
  follow-on. Adopting it is an owner call. The member below ships py's four and lists the two
  additions as a one-line change.

### Recommendation

**One stack, on R69's axum 0.8.9 and tokio 1.53.1:**

- **`tower-http` 0.7.1**, optional under the `web` feature, `default-features = false`, features
  `["request-id", "set-header", "catch-panic", "timeout"]`. It provides:
  - `SetRequestIdLayer` + `PropagateRequestIdLayer` with `MakeRequestUuid` (L1, L3);
  - `SetMultipleResponseHeadersLayer::if_not_present` for security headers (L2);
  - `CatchPanicLayer` (L6);
  - `TimeoutLayer::with_status_code(408, …)` (L9).
- **A hand-written `axum::middleware::from_fn(access_log)`** (L5). It emits the one `http_request`
  event with every field on the event. It excludes `ACCESS_LOG_EXCLUDED_ROUTES` by matched route
  template, and it opens the `request` span that carries `request_id` into handler events.
- **The ordering contract L1–L10**, implemented as chained `Router::layer` calls in one
  `apply_middleware` function in `src/web/middleware.rs`. It is applied to the fully composed
  router, and it keeps named slots for R73, R74, R76, R78 and R79.
- **No framework-log silencing step (F327).** The fold-in is axum's `tracing` feature, which is on
  in R69's owned value, plus R58's subscriber. The residual std panic-hook line goes to R58.
- **`tracing` 0.1.44** as the event facade. It is assumed from R58, not owned here.

### Members

#### tower-http request-id layers (`SetRequestIdLayer` + `PropagateRequestIdLayer` + `MakeRequestUuid`)

##### Landscape
Candidates:
- built-in: a hand-written `from_fn` reading or generating the header;
- established: `tower-http` `request-id` feature;
- up-and-comer / quiet: `tower-request-id` 0.3.0, which generates ULIDs and was last released
  2023-12-02;
- adjacent: `axum-tracing-opentelemetry`, which derives ids from the trace context (R78's field).

**Crate figures:** this member is the `tower-http` crate; its row in the `### Landscape` figures
table applies (0.7.1, 155,129,876 downloads in 90 days, MIT, `rust-version` 1.65, no open advisory,
`active`). The transitive `uuid` 1.26.1 row is in the same table.

##### Principles and implementation
F318 requires three things: accept the inbound `x-request-id` or generate one; bind it to the log
context; echo it on the response. `SetRequestIdLayer` does the first two halves. When the header is
present it stores it as the `RequestId` extension. Otherwise it calls `MakeRequestId`, then inserts
both the header and the extension (`request_id.rs:330-343`). `PropagateRequestIdLayer` copies the
id from the request onto the response unless the response already has one (`request_id.rs:442-465`).
Binding to the log context is done by L5, which reads the `RequestId` extension into the `request`
span and the event. This is the axum maintainers' own composition (`examples/request-id`), with
L2 placed between the two request-id layers.

##### Dominant choice
`tower-http` `request-id`: 155,129,876 downloads in 90 days, and the feature axum's example uses.
`tower-request-id` has 132,590 downloads in 90 days, about 0.09 % of `tower-http`.

##### Qualified shortlist
`tower-http` 0.7.1 `request-id`. Gates:
1. MIT.
2. `rust-version` 1.65; the probe tree compiled and passed on 1.96.0 (executed).
3. No open RustSec advisory; `#![deny(unsafe_code)]`.
4. CI on ubuntu-latest, macos-latest and windows-latest.
5. `default = []`; the feature adds `uuid` (`v4`); no async-runtime coupling in this module (it
   only needs `http` and `tower`).
6. Small: it adds `uuid` and `getrandom` to the tree.

A hand-written `from_fn` also passes every gate trivially, but it duplicates a maintained layer.

##### Excluded by gate
`tower-request-id` 0.3.0 fails **gate 2 as evidenced**: it declares no `rust-version`, and it was
not built in this run. It was also not re-verified on the 1.96 floor. It would additionally put a
second id format (ULID) beside py's, and it duplicates `tower-http`.

##### Up-and-comers
None credible for this concern. Id handling has consolidated on `tower-http`.

##### Fit for this template
Strong. There is no extra crate beyond `tower-http`, and the header name is a `const`. The
`RequestId` extension is readable by R70's problem envelope, if R70 wants to echo the id in
problem documents, and by R78's span.

##### Recommendation
`tower-http` 0.7.1, feature `request-id`:
- `SetRequestIdLayer::new(HeaderName::from_static("x-request-id"), MakeRequestUuid)` at L1;
- `PropagateRequestIdLayer::new(…)` at L3.

##### Ranked runner-up
A hand-written `from_fn` that reads or generates the id and echoes it. It is viable only if
inbound-id validation (see Tradeoffs) becomes required and the owner wants it in one place.

##### Tradeoffs
- **Inbound ids are trusted as-is**, as in py. `http::HeaderValue` cannot contain CR or LF, so a
  client cannot inject a newline into a log line. Length is bounded only by hyper's header limits.
  A hardening option is a tiny `map_request` before L1 that drops non-conforming inbound values,
  for example values longer than 128 bytes or outside `[A-Za-z0-9._-]`. It is **proposed, not
  recommended by default**: py does not do it, and it would change F318's accept-inbound policy.
- The id format differs from py: hyphenated UUID v4 (36 characters) versus py's `uuid4().hex`
  (32 characters). Both are opaque, and the difference is a mechanism, not a policy.

##### Parameters
No owned parameter. It uses the policy constant `x-request-id`, the same as py.

##### Migration implications
- `Cargo.toml`: add `tower-http` with `request-id`.
- `src/web/middleware.rs`: the `X_REQUEST_ID` const, L1 and L3.

##### Validation strategy
Executed:
- every one of the 9 cases returned `x-request-id`;
- the `inbound-id` case echoed `abc-123`, and the event's `request_id` equalled the header;
- a generated id appeared on the 429, the preflight, the 408 and the panic-500.

##### Confidence & re-verify trigger
High. Re-verify on a `tower-http` 0.8 release, or if R78 decides that the trace id supersedes
`x-request-id`.

##### Sources
- tower-http 0.7.1 `src/request_id.rs` (static.crates.io, 2026-09-26);
- tokio-rs/axum `examples/request-id/src/main.rs` @`bc8d4912`;
- py `web/middleware.py:72-82` @`b55b8c26`;
- crates.io API figures as in `### Landscape`.

#### tower-http security-header layer (`SetMultipleResponseHeadersLayer::if_not_present`)

##### Landscape
Candidates:
- built-in: a hand-written `from_fn` or `map_response`, which crates.io uses
  (`common_headers.rs`);
- established: `tower-http` `set-header`, either `SetResponseHeaderLayer`, one layer per header, or
  `SetMultipleResponseHeadersLayer`, one layer, since 0.6.11;
- up-and-comers: `axum-helmet` 1.0.2 with `helmet-core` 1.0.1 (a helmet.js port), `tower-helmet`
  0.3.0, `tower-default-headers` 0.2.3.

**Crate figures:** this member is the `tower-http` crate; its row in the `### Landscape` figures
table applies. The comparator crates' rows are in the same table.

##### Principles and implementation
F321 requires the headers on every response, with a handler-set value winning
(`response.headers.setdefault`, py `middleware.py:120`). `if_not_present` is that exact semantic.
Placing the layer at L2, outside every short-circuiting layer, makes it unconditional in fact, not
just in intent.

##### Dominant choice
The `tower-http` `set-header` feature. The owner reference's C11 names the same family, and
crates.io uses the hand-written equivalent.

##### Qualified shortlist
1. `tower-http` 0.7.1 `set-header`: same gates as Member 1; the feature adds **no** dependency
   (`set-header = []`).
2. A hand-written `from_fn`: passes every gate, but it is more code for the same behaviour.

##### Excluded by gate
`axum-helmet` 1.0.2, `helmet-core` 1.0.1, `tower-helmet` 0.3.0 and `tower-default-headers` 0.2.3
are **excluded on gate 2 as evidenced**. None declares a `rust-version` (crates.io `rust_version:
null`), and none was built on the 1.96 floor in this run. `tower-helmet` additionally depends on
`lazy_static` and was last released 2024-01-29.

##### Up-and-comers
`axum-helmet`/`helmet-core` 1.0 (2026-05-26): 25,465 downloads in 90 days, 23 stars, 2 reverse
dependencies. It is worth watching if the template grows HTML pages that need helmet's CSP
builder. That would be the owner reference's Variant A, which has no P02 item.

##### Fit for this template
Strong. There is one layer, one position and no new dependency. The header set is a
`vec![…]` literal that mirrors py's `SECURITY_HEADERS` dict.

##### Recommendation
L2 = `SetMultipleResponseHeadersLayer::<Response>::if_not_present(vec![…])` with py's four headers:

- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Referrer-Policy: no-referrer`
- `Strict-Transport-Security: max-age=63072000; includeSubDomains`

If the owner accepts `BASELINE-REVIEW: F321`, append `Content-Security-Policy: frame-ancestors 'none'`
and `Cache-Control: no-store`.

##### Ranked runner-up
Four `SetResponseHeaderLayer::if_not_present` layers. The behaviour is identical, but the type
chain is four times longer, which matters for compile time (crates.io PR 7443).

##### Tradeoffs
- HSTS is sent over plain http in development, as py does. Browsers must ignore it on insecure
  transport (RFC 6797 §8.1, not retrieved this run), so it is harmless.
- `if_not_present` lets a handler weaken a header; `overriding` would forbid that, but it breaks
  legitimate per-route values such as a docs page's own CSP. py chose `setdefault`, and this report
  keeps it.
- The type parameter is the **response** type: `SetMultipleResponseHeadersLayer<Response>`. The
  first probe build failed with `SetMultipleResponseHeadersLayer<HeaderValue>` (E0277, executed).
  That is a real pitfall to document in the template.

##### Parameters
No owned parameter. It uses the policy constant: the header set above.

##### Migration implications
- `Cargo.toml`: add the `set-header` feature.
- `src/web/middleware.rs`: `fn security_headers()` and L2.

##### Validation strategy
All executed:
- all four headers appeared on all 9 cases, including 404, 429, preflight, 408 and panic-500;
- on `/framed`, the handler's `X-Frame-Options: SAMEORIGIN` survived, which proves
  `if_not_present`;
- the negative control, with headers innermost, returned the 429 and the preflight **without**
  them.

##### Confidence & re-verify trigger
High. Re-verify when the owner decides `BASELINE-REVIEW: F321`, or if R71 serves HTML docs that
need their own CSP.

##### Sources
- tower-http 0.7.1 `src/set_header/response/multiple_headers.rs` and `CHANGELOG.md` (0.6.11, 0.7.0,
  0.7.1 entries);
- OWASP `REST_Security_Cheat_Sheet.md` @`c04039ad` lines 181-203;
- crates.io `src/middleware/common_headers.rs` @`067b45e1`;
- py `web/middleware.py:53-61, 111-120`;
- owner reference §C11.

#### Access-log layer (hand-written `axum::middleware::from_fn(access_log)`)

##### Landscape
Candidates:
- built-in: `axum::middleware::from_fn` (axum first-party);
- established: `tower-http` `TraceLayer` with custom `make_span_with` and `on_response`;
- up-and-comers: `axum-tracing-opentelemetry` (OTel-shaped request spans; R78's) and
  `tower-http`'s new `on-early-drop` (0.7.0) for client-disconnect visibility.

**Crate figures:** the recommended design is a hand-written function, so crate figures do not
apply to it. It uses `axum` (figures are R69's), `tracing` (row in the `### Landscape` table) and
`tower-http`'s `RequestId` type (row in the same table). The runner-up `TraceLayer` is `tower-http`
feature `trace`, covered by that row.

##### Principles and implementation
F319 asks for one wide event per request, with the route template, status and `duration_ms`,
logged even on failure. F320 asks for no event for probe routes. The `from_fn` layer reads
`MatchedPath` and `RequestId` from request extensions. It opens a `request` span, which is the log
context for handler events, runs the inner stack instrumented by that span, and emits one
`tracing::info!(…, "http_request")` with every field on the event. Placement at L5 puts it outside
CORS, rate limiting, timeout and catch-panic, and inside the id and header layers.

##### Dominant choice
`TraceLayer` is the ecosystem's dominant *request-tracing* layer; axum's examples use it. For a
*canonical access line*, the Rust project's own service, crates.io, uses a hand-written `from_fn`
(`log_request.rs`).

##### Qualified shortlist
1. Hand-written `from_fn`: axum first-party; no new crate; passes every gate by construction.
2. `tower-http` `TraceLayer` (feature `trace`, which adds `tracing` and `http-body`): same gates as
   Member 1.

Both variants were executed and passed.

##### Excluded by gate
None. `axum-tracing-opentelemetry` (CC0-1.0, which is compatible; `rust-version` 1.91.0) passes the
gates but is **out of scope by fit**. It is an OTel span layer, which is R78's decision, and it
would sit in slot L4.

##### Up-and-comers
`tower-http` `on_early_drop` (0.7.0): `OnEarlyDropLayer` makes client disconnects observable. It
could later feed a `dropped = true` field. It is not needed for F319.

##### Fit for this template
Strong:
- the fields are independent of R58's still-open formatter choice;
- it reads like py's `_log_access`;
- the exclusion is a plain `contains`;
- it needs no extra feature.

The cost is about 35 lines of template code that the template owns.

##### Recommendation
`from_fn(access_log)` at L5, with:
- `ACCESS_LOG_EXCLUDED_ROUTES = ["/healthz", "/readyz", "/metrics"]`, matched on `MatchedPath`;
- event name `http_request`;
- fields `request_id`, `method`, `route` (absent when unmatched), `path`, `status`, `duration_ms`.

Field key names and their JSON shape are **R58's** to confirm.

##### Ranked runner-up
`TraceLayer::new_for_http().make_span_with(access_span).on_request(()).on_response(access_event).on_body_chunk(()).on_eos(()).on_failure(())`,
where `access_span` returns `Span::none()` for excluded routes and `access_event` returns early on
`span.is_none()`. It was executed and passes. It loses because `route`, `path`, `method` and
`request_id` are span fields, not event fields. It moves ahead if R58 fixes a formatter that always
flattens the current span into each event.

##### Tradeoffs
- `duration_ms` is measured to the response *head*, as py's `call_next` is. Body-streaming time is
  excluded.
- Probe requests get no `request` span context in the runner-up, but they do in the recommended
  design, where only the event is skipped.
- Excluding by route template means an unrouted `/healthz/` produces a logged 404, and that is
  intended.

##### Parameters
No owned parameter. The item fixes policy constants: the event name and the exclusion list.
`CONFLICT` lines: none.

##### Migration implications
- `src/web/middleware.rs`: `access_log`, `ACCESS_LOG_EXCLUDED_ROUTES`.
- `Cargo.toml`: `tracing` as a direct dependency (assumed from R58).

##### Validation strategy
Executed, with both variants:
- exactly 1 `http_request` event for each of `ok`, `inbound-id`, `not-found` (404), `throttled-429`,
  `cors-preflight`, `panic-500`, `timeout-408` and `handler-override`;
- 0 events for `/healthz`;
- the event's `status` equals the response status, and `request_id` equals the `x-request-id`
  header;
- `route` is `"/v1/projects/{id}"` on matched requests and absent on the 404.

##### Confidence & re-verify trigger
Medium-high. Re-verify when R58 publishes its formatter and field-naming contract; that may flip
the choice to `TraceLayer`. Also re-verify when R78 decides whether its span replaces the `request`
span.

##### Sources
- axum 0.8.9 `src/docs/middleware.md`;
- `extract::MatchedPath`, `routing/mod.rs:303-317`;
- tower-http 0.7.1 `src/trace/*`;
- tracing 0.1.44 `src/span.rs:1244-1261`;
- crates.io `src/middleware/log_request.rs` @`067b45e1`;
- py `web/middleware.py:47-51, 64-108`.

#### Composition-order contract (pattern: L1–L10 via chained `Router::layer`, with `CatchPanicLayer` and `TimeoutLayer`)

##### Landscape
Ways to express order:
- chained `Router::layer`, where the last call is outermost: axum's documented default, loco's
  "tower is LIFO" stack;
- `ServiceBuilder`, where the first call is outermost: axum's recommended grouping, crates.io's
  split stacks;
- a framework registry: loco's `insert_before`/`insert_after`.

The two crates in this member, `CatchPanicLayer` and `TimeoutLayer`, are from `tower-http`.
**Crate figures:** as `tower-http` in `### Landscape`. **Pattern fields:** crate figures do not
apply to the ordering itself, which is code in the template.

##### Principles and implementation
F317 requires id and header layers outermost, so every short-circuit carries them. The contract
table under `### Principles and implementation` is the normative statement. `apply_middleware` is
its only implementation, and it is applied once to the fully composed router, after R69's
`build_router` merges and nests.

##### Dominant choice
Per-concern tower layers applied through `Router::layer`, which is universal among axum services.
Either expression is used: chained calls or `ServiceBuilder`.

##### Qualified shortlist
1. Chained `Router::layer` calls: no production `tower` dependency, which respects R69's
   "`tower` … is a dev-dependency only"; py-identical "last added is outermost".
2. `ServiceBuilder`: reads top-down, but it needs `tower` promoted from dev-dependency to optional
   dependency, and it produces one large type (compile-time risk; crates.io PR 7443).

`CatchPanicLayer` (feature `catch-panic`: `tracing`, `futures-util/std`, `http-body`,
`http-body-util`) and `TimeoutLayer` (feature `timeout`: `http-body`, `tokio/time`, which is
already on in R69's tokio features) pass the same gates as Member 1.

##### Excluded by gate
Pattern member: gates 1–6 are **inapplicable** to the ordering itself, because it is template code
with no crate. They were applied to its two crates above, and both pass.

##### Up-and-comers
None. loco's configurable stack is a framework feature, not an adoptable crate.

##### Fit for this template
Strong. The contract is one function of about 15 lines. Slots are named for R73, R74, R76, R78 and
R79, and conditional slots use plain `if`, so there is no `option_layer` dependency.

##### Recommendation
The contract is fixed as L1 `SetRequestId` → L2 security headers → L3 `PropagateRequestId` →
[L4 R78/R79] → L5 access log → L6 `CatchPanicLayer` → [L7 R76 CORS] → [L8 R74 rate limit] → L9
`TimeoutLayer::with_status_code(StatusCode::REQUEST_TIMEOUT, <duration>)` → [L10 R73 idempotency].

It is written innermost-first as chained `Router::layer` calls, with a doc comment stating the
outermost-first list. The timeout duration is a service knob, so R77 names its environment variable.
crates.io uses 30 s (`src/middleware.rs:87-90`).

##### Ranked runner-up
The same order expressed as `Router::layer(ServiceBuilder::new()…)`, top-down. It is chosen only if
R69 promotes `tower` to a normal dependency for another reason.

##### Tradeoffs
- Innermost-first code order is less readable than a top-down list. The doc comment and the
  negative-control test compensate.
- Per-route cloning (`routing/mod.rs:312-315`) means stateful slot layers must share state
  through an `Arc`.
- The CORS-outside-rate-limit order departs from py; see `BASELINE-REVIEW: F317`.

##### Parameters
No owned parameter. It assumes R77 will name the timeout-duration variable. It adds no `CONFLICT`.

##### Migration implications
- `src/web/middleware.rs`: `apply_middleware`.
- `src/web/mod.rs` / `build_router`: call `apply_middleware` last.
- `Cargo.toml`: add the `catch-panic` and `timeout` features.

##### Validation strategy
Executed:
- `throttled-429` (a stand-in L8 `from_fn` returning 429), `cors-preflight` (a real `CorsLayer` at
  L7), `timeout-408` (200 ms `TimeoutLayer` against a 5 s handler) and `panic-500` each carried the
  id, all four headers and exactly one access event;
- the negative control in the C11 order lost the headers on the 429 and the preflight, and lost the
  id from the span.

##### Confidence & re-verify trigger
High for L1–L6 and L9. Medium for slot positions L7, L8 and L10 until R73, R74 and R76 publish.
Re-verify when any of those items picks a layer whose error type is not `Infallible`.

##### Sources
- axum 0.8.9 `src/docs/middleware.md:61-150`, `src/routing/mod.rs:303-317`;
- tower-http 0.7.1 `src/catch_panic.rs:341-345`, `src/timeout/service.rs:29-35`;
- loco `src/controller/middleware/mod.rs:76-190` @`9f7e021e`;
- crates.io `src/middleware.rs` @`067b45e1`;
- py `web/app.py:127-146`;
- R69 `DECISION.md:943-944, 1586`.

#### Framework/server log fold-in (pattern, F327)

##### Landscape
- Built-in: axum's `tracing` feature, which is default-on and inside R69's owned feature list;
  `std::panic::set_hook`.
- Established: `tracing-subscriber`'s `tracing-log` bridge (`LogTracer`) for dependencies that log
  through the `log` crate; this belongs to R58's pipeline.
- Up-and-comer: panic-to-tracing hook crates, such as `tracing-panic`, which was not evaluated in
  this run.

**Pattern fields:** this member adds no crate, so crate figures do not apply.

##### Principles and implementation
Under F327, the server's own output flows through the one pipeline and no second access line
exists. In py that took an explicit step: clearing `uvicorn`/`uvicorn.error` handlers and dropping
`uvicorn.access` (`web/logging.py:61-73`). In this stack:

- axum's own output is `tracing` events: `serve/listener.rs:156` `error!("accept error: {e}")`,
  and `serve/mod.rs:278-408` `trace!` connection lifecycle, compiled in only under the `tracing`
  feature (`src/macros.rs:70-95`);
- hyper 1.11.1 (the version in the probe lock) emits nothing here: its `tracing` feature is off
  in this tree (`cargo tree -e features -i hyper` shows only `default`, `http1`, `server`), and even
  when on it also needs `RUSTFLAGS='--cfg hyper_unstable_tracing'` (hyper `src/trace.rs:5-9`,
  `src/lib.rs:84-89`);
- neither ships an access logger;
- `tower-http` layers emit `tracing` events (`catch_panic`).

So there is nothing to silence or redirect. The events reach whatever global subscriber R58
installs.

The `log` crate is in the probe tree **only** as `tracing`'s optional backend. It is enabled
through axum's `tower-log` default feature, which turns on `tower`'s `log` feature, which turns on
`tracing`'s `log` feature (executed: `cargo tree -e features -i tracing`). In that mode, `tracing`
emits a `log` record only "if no `tracing` `Subscriber` is active"; only `log-always` emits both
(tracing 0.1.44 `src/lib.rs:647-660`, `src/macros.rs:3301, 3324`; `log-always` is not enabled in
the tree). So there is no double emission once R58's subscriber is set.

##### Dominant choice
Rely on `tracing`-native emission. It is the norm across tokio-rs crates; crates.io and loco
install no framework-log adapters.

##### Qualified shortlist
1. No-op fold-in: keep axum's `tracing` feature on; R58's subscriber receives everything.
2. Additionally, R58's `tracing-log` bridge, if any future dependency logs through `log`.

##### Excluded by gate
Inapplicable: no crate is adopted. The one gap, the std panic hook, is handed to R58 rather than
solved by a crate here.

##### Up-and-comers
A process-wide panic hook that emits a `tracing` event and suppresses the default stderr line. It
is R58's to select, because the hook is process-global and also affects the CLI.

##### Fit for this template
Exact. There is no step for template users to forget. The only web-side obligation is to keep
axum's `tracing` feature enabled, which R69 already does.

##### Recommendation
Record F327 in Rust as **satisfied by construction** (see `BASELINE-REVIEW: F327`):
- no uvicorn-style handler clearing;
- keep `axum` default features, including `tracing` and `tower-log`, as R69 fixed them;
- ask R58 for a web-profile `EnvFilter` default, and for a panic hook that routes the std
  panic message into `tracing` so a handler panic yields one structured ERROR event, not a second
  plain-text line.

##### Ranked runner-up
A web-side `std::panic::set_hook` installed by the serve binary. It works, but it is
process-global state owned by R58's pipeline, so it is rejected for ownership.

##### Tradeoffs
If R69 ever switched to `actix-web`, this member would change: `actix-web`'s `middleware::Logger`
emits through `log`, and the access line would then need an explicit disable. With the tower-based
stack R69 chose, it does not depend on the framework choice (MEDIUM question 3).

##### Parameters
No owned parameter. It assumes `logging-pipeline-contract = —`, which is unresolved (see
`### Parameters`).

##### Migration implications
None in `src/web/` beyond keeping axum defaults. The panic hook lands in R58's pipeline module.

##### Validation strategy
Executed: `panic-500` produced one structured ERROR event (`"target":"tower_http::catch_panic"`,
`"message":"Service panicked: boom"`, span `request_id` present) **and** one plain-text stderr line
`thread 'middleware_stack_contract' … panicked at src/lib.rs:84:51: boom`. The second line is the
residual. Proposed, after R58 lands: rerun and assert that stderr contains no non-JSON line.

##### Confidence & re-verify trigger
High for axum/hyper emission facts at 0.8.9 and 1.x. Re-verify on an axum 0.9 release, or if hyper
stabilises its `tracing` cfg.

##### Sources
- axum 0.8.9 `src/serve/listener.rs:156`, `src/serve/mod.rs:278-408`, `src/macros.rs:70-95`,
  `Cargo.toml` (`tower-log`, `tracing` features);
- tracing 0.1.44 `src/lib.rs:647-660`, `src/macros.rs:3301, 3324`; hyper 1.11.1 `src/trace.rs:5-9`,
  `src/lib.rs:84-89`, `Cargo.toml` (`tracing` feature);
- the probe's `cargo tree -e features -i tracing`;
- py `web/logging.py:61-73`.

### Compatibility

**Shared example and shared adopter:**

- **rust-lang/crates.io** runs axum with `tower-http = "=0.7.1"` (`Cargo.toml:168`), using
  `CatchPanicLayer` and `TimeoutLayer::with_status_code`, together with a hand-written `from_fn`
  access log and hand-written headers (`src/middleware.rs` @`067b45e1`). That is the same crate at
  the same version, in the same roles as Members 3 and 4.
- **tokio-rs/axum `examples/request-id`** composes `SetRequestId`, `TraceLayer` and
  `PropagateRequestId` on axum's main branch.

**Version matrix, executed.** One `Cargo.lock` resolved `axum` 0.8.9, `tokio` 1.53.1, `tower-http`
0.7.1, `tower` 0.5.3 (dev), `tracing` 0.1.44, `tracing-subscriber` 0.3.23 (dev) and `uuid` 1.26.1
("Locking 81 packages to latest Rust 1.96 compatible versions"). All tests passed on rustc
**1.98.1** and **1.96.0**, on macOS aarch64. The highest `rust-version` declared by any dependency
in the tree is **1.85** (`uuid` 1.26.1, `getrandom` 0.4.3, `hyper-util` 0.1.21), well within the
1.96 floor.

**Not executed:** ubuntu-latest. `tower-http`'s own CI covers ubuntu-latest and `macos-latest`
(`.github/workflows/CI.yml`).

### Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes logging-pipeline-contract = —

**Owned parameters:** none. The prompt's `owns:` coupling is empty.

**CONFLICT lines:** none.

**Integration notes. These are not CONFLICT lines, because R75 does not consume the parameter.**

1. R69's owned `web-extra-surface` writes `web = ["dep:axum", "dep:tokio"]`. This stack needs
   `dep:tower-http` in that list. That is consistent with clause (4) of the same value, "every later
   web layer — … R72 to R76's middleware — as modules inside that same gated `src/web/` tree".
2. `tower` stays dev-only under the recommended chained-`layer` form.
3. `logging-pipeline-contract` is unresolved (`inputs/prerequisites.json`: R58 `decision: missing`,
   `acceptance: missing`). The event's field keys, the JSON shape, the level policy and the panic
   hook are R58's. This stack emits `tracing` events and assumes nothing else.

### Migration implications

| File | Change |
|---|---|
| `Cargo.toml` | Add `tower-http = { version = "0.7.1", optional = true, default-features = false, features = ["request-id", "set-header", "catch-panic", "timeout"] }`. Add `dep:tower-http` to the `web` feature (a request to R69). `tracing` is a direct dependency via R58. Keep `axum` default features (`tracing`, `tower-log`) |
| `src/web/middleware.rs` (new; R69 already reserves the name, `DECISION.md:1424`) | `X_REQUEST_ID`, `ACCESS_LOG_EXCLUDED_ROUTES`, `security_headers()`, `access_log`, `apply_middleware(router, cors, …)` with the L1–L10 doc comment |
| `src/web/mod.rs` (R69's `build_router`) | Call `apply_middleware` once, last, on the fully merged and nested router |
| `src/web/cors.rs`, `rate_limit.rs`, `idempotency.rs` (R76, R74, R73) | Expose a layer value that `apply_middleware` places in slots L7, L8 and L10 |
| `tests/web_middleware.rs` (new; `#![cfg(feature = "web")]`) | The acceptance and negative-control tests below |
| `docs/` (web section) | State the outermost → innermost contract, the exclusion list and the header set |

### Validation strategy

**Executed in this leg** (scratch crate `/tmp/r75/probe`, not committed). File sha256 values:

| File | sha256 |
|---|---|
| `src/lib.rs` (183 lines) | `1e2a5b43ff4a5834176c58c7d217a922bd933ab50505a767bf373918e0f60afb` |
| `tests/acceptance.rs` | `199c9b6da4ea876be7bcd5d803af057da27bf914ea807e69c7aa5b2a99563e86` |
| `tests/negative_control.rs` | `684469da29c475b8199207e8d5b9b211cd3ced0032baf2a4a4b8710aabcfdfcd` |
| `Cargo.lock` | `b7057901bee43b9c82f199bdb8299e3a13882b2238a1a3f1ab1dbb70812a2275` |

```bash
cd /tmp/r75/probe
cargo test --test acceptance -- --nocapture --test-threads=1   # rustc 1.98.1
rustup run 1.96.0 cargo test --tests                          # MSRV floor
cargo test --test negative_control -- --nocapture
```

Observed: `test result: ok. 2 passed` for acceptance, with one test per access-log variant, and
`ok. 1 passed` for the negative control, on both toolchains. Each variant sends 9 requests through
`tower::ServiceExt::oneshot`, R69's test idiom. For each request it asserts the status, the
presence of `x-request-id`, all four security headers (with the handler value winning on
`/framed`) and the count of `http_request` events captured from a JSON `tracing-subscriber`.

| Case | Status | Access events | Notes |
|---|---|---|---|
| `ok` `GET /v1/projects/7` | 200 | 1 | `route="/v1/projects/{id}"` |
| `inbound-id` | 200 | 1 | header and event `request_id` = `abc-123` |
| `probe` `GET /healthz` | 200 | **0** | id and headers still present |
| `not-found` `GET /nope` | 404 | 1 | `route` absent |
| `throttled-429` (L8 stand-in) | 429 | 1 | id and headers present |
| `cors-preflight` `OPTIONS` with `Origin` | 200 | 1 | id and headers present |
| `panic-500` | 500 | 1 | plus one `tower_http::catch_panic` ERROR event and the std stderr line |
| `timeout-408` (200 ms vs 5 s) | 408 | 1 | `duration_ms` ≈ 202 |
| `handler-override` `/framed` | 200 | 1 | `X-Frame-Options: SAMEORIGIN` preserved |

Negative control, in the owner reference's C11 order: the 429 and the preflight had
`x-frame-options=None`, and both access spans recorded `"request_id":"-"`.

**Planned, not executed:**

1. The same tests in the template's `tests/web_middleware.rs` on the CI matrix, ubuntu-latest and
   macos-latest, via `cargo test --features web`.
2. An end-to-end check against the real serve binary:
   `curl -si -H 'Origin: https://app.example' -X OPTIONS http://127.0.0.1:$PORT/v1/…` and
   `curl -si http://127.0.0.1:$PORT/healthz`. Expect `x-request-id` and the four headers on both
   responses, one `http_request` JSON line on stdout for the first, none for the second, and no
   non-JSON line on stdout or stderr after R58's panic hook lands.
3. With R74 and R76's real layers in slots L7 and L8, rerun `throttled-429` and assert that
   `Access-Control-Allow-Origin` is present on the 429 (`BASELINE-REVIEW: F317`).

### Confidence & re-verify trigger

**Confidence: high** for:
- the layer model and its direction;
- Members 1, 2 and 4;
- the F327 finding (source-read and executed).

**Medium-high** for choosing the hand-written access log over `TraceLayer`, because that choice
hinges on R58's formatter. **Medium** for slot positions L7, L8 and L10 until R73, R74 and R76
publish.

**re-verify:** any of the following:
- when R58 publishes `logging-pipeline-contract`, specifically the field naming, the span
  flattening and the panic hook;
- when R73, R74 or R76 publish a layer whose error type is not `Infallible`, or which needs a
  different slot;
- when R78 decides whether its OTel span replaces the `request` span;
- on a `tower-http` 0.8 or `axum` 0.9 release;
- when the owner rules on `BASELINE-REVIEW: F321`.

### Sources

All retrieved 2026-09-26 unless marked otherwise.

- axum 0.8.9 published crate: `https://static.crates.io/crates/axum/axum-0.8.9.crate` —
  `src/docs/middleware.md`, `src/routing/mod.rs`, `src/serve/listener.rs`, `src/serve/mod.rs`,
  `src/macros.rs`, `Cargo.toml`.
- tower-http 0.7.1 published crate: `https://static.crates.io/crates/tower-http/tower-http-0.7.1.crate`
  — `CHANGELOG.md`, `Cargo.toml`, `src/lib.rs`, `src/request_id.rs`, `src/set_header/response/*`,
  `src/trace/*`, `src/catch_panic.rs`, `src/timeout/service.rs`, `src/on_early_drop/mod.rs`.
- tracing 0.1.44 published crate: `https://static.crates.io/crates/tracing/tracing-0.1.44.crate` —
  `src/span.rs`, `src/lib.rs`, `src/macros.rs`, `Cargo.toml`.
- hyper 1.11.1 published crate: `https://static.crates.io/crates/hyper/hyper-1.11.1.crate` —
  `Cargo.toml`, `src/lib.rs`, `src/trace.rs`.
- crates.io API: `https://crates.io/api/v1/crates/{tower-http,tower,axum,tracing,tracing-subscriber,uuid,helmet-core,axum-helmet,tower-helmet,tower-request-id,axum-tracing-opentelemetry,tower-default-headers}`;
  `.../{axum-helmet/1.0.2,helmet-core/1.0.1,tower-helmet/0.3.0,tower-request-id/0.3.0,tower-default-headers/0.2.3}/dependencies`;
  `.../{tower-http,axum-helmet}/reverse_dependencies`.
- GitHub REST: `https://api.github.com/repos/{tower-rs/tower-http,tokio-rs/tracing,uuid-rs/uuid,danielkov/rust-helmet,atrox/tower-helmet,imbolc/tower-request-id,davidB/tracing-opentelemetry-instrumentation-sdk,tower-rs/tower,rust-lang/crates.io,loco-rs/loco}`;
  `search/issues?q=repo:<o>/<r>+is:issue+is:open`;
  tower-http issue comments for #741, #740, #737, #736, #732, #731, #725, #713, #702 and #701;
  `tower-rs/tower-http/contents/.github/workflows/CI.yml`.
- rust-lang/crates.io @`067b45e1a15fc1b97f7321792b86bdf8d6371d7c`: `Cargo.toml`,
  `src/middleware.rs`, `src/middleware/log_request.rs`, `src/middleware/common_headers.rs`.
- vectordotdev/vector `Cargo.toml` (default branch): the `tower-http` line.
- tokio-rs/axum @`bc8d4912435204a4a073cea70355ae0328d263fe`: `examples/request-id/src/main.rs`,
  and the `examples/` listing.
- loco-rs/loco @`9f7e021e9fe68275a9a7e1ab3e7dd25c483d2bd8`: `src/controller/middleware/mod.rs`.
- OWASP/CheatSheetSeries @`c04039adbe6f727a2198b3a3ea634fec98ac068a`:
  `cheatsheets/REST_Security_Cheat_Sheet.md`.
- RustSec: `https://rustsec.org/packages/{tower-http,tracing,tracing-subscriber}.html` (HTTP 200);
  `tower`, `uuid`, `axum`, `axum-helmet`, `helmet-core`, `tower-helmet`, `tower-request-id` and
  `axum-tracing-opentelemetry` (HTTP 404, no advisories).
- py-launch-blueprint @`b55b8c26364cb0f42e56116e6780921976334751` (local checkout):
  `src/py_launch_blueprint/web/middleware.py`, `web/app.py`, `web/logging.py`, `web/telemetry.py`.
- This repository: `research/topics/69-web-framework-stack/DECISION.md` (revision 9);
  `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`;
  `docs/port/areas/web-service.md`;
  `research/runs/R75/2026-09-26T190305Z-54dc44c45419/inputs/{prompt.md,prerequisites.json,parameters.json}`.
- Not retrieved in this run, cited from the standards bodies:
  RFC 6797 §8.1 (`https://www.rfc-editor.org/rfc/rfc6797#section-8.1`);
  WHATWG Fetch "CORS check" (`https://fetch.spec.whatwg.org/#cors-check`).

**Gaps recorded:**

1. R58's `logging-pipeline-contract` is unresolved, so the field keys, the span flattening and the
   panic hook are assumed rather than consumed.
2. The ubuntu-latest run was not executed.
3. The comparator crates (`axum-helmet`, `tower-helmet`, `tower-request-id`) were not built on the
   1.96 floor, so their gate-2 exclusions rest on undeclared `rust-version`, not on an observed
   failure.
4. Issue responsiveness was computed for `tower-http` only.
5. RFC 6797 and the Fetch standard were cited, not retrieved.
6. No published Rust template names this exact convention as a pattern (LOW question). The nearest
   equivalents are loco's documented default middleware stack (request_id, logger, secure_headers,
   with "tower is LIFO" ordering) and axum's `request-id` example. The survey was limited to these
   repositories, crates.io and vector.
7. No performance benchmark was run; only the qualitative per-layer cost and one release-build time
   are stated.
