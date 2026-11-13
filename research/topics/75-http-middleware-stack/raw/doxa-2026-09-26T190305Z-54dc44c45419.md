### Landscape

**Retrieval date:** September 26, 2026.  
**Decision category:** inbound HTTP **edge-envelope middleware and request observability**: request correlation, invariant response headers, canonical access logging, middleware ordering, and framework-log integration.

#### Three-bin ecosystem map

| Bin | Candidates found | Assessment for this template |
|---|---|---|
| **Built-in or first-party toolchain** | Rust `std` provides neither an async HTTP server nor an HTTP middleware stack. Framework-native options include Actix Web’s `Transform` middleware and Poem’s `Middleware`/`Endpoint` system. | There is no Rust-language-standard solution. Framework-native middleware can realize the principles but couples R75 directly to R69. The Rust Async Book explicitly describes runtimes and higher-level networking facilities as ecosystem choices. ([Async Book](https://rust-lang.github.io/async-book/08_ecosystem/00_chapter.html), retrieved 2026-09-26.) ([rust-lang.github.io](https://rust-lang.github.io/async-book/08_ecosystem/00_chapter.html)) |
| **Established ecosystem standard** | `tower` Service/Layer composition; `tower-http` request-ID and response-header middleware; `tracing`; Actix Web native middleware. | `tower` + `tower-http` + `tracing` is the strongest framework-portable choice within the Tokio/HTTP 1.x ecosystem. Tower’s purpose is composable networking middleware, and Axum explicitly uses Tower rather than inventing a middleware system. ([Tower case study](https://rust-lang.github.io/async-fundamentals-initiative/evaluation/case-studies/tower.html), [Axum architecture](https://github.com/tokio-rs/axum), retrieved 2026-09-26.) ([rust-lang.github.io](https://rust-lang.github.io/async-fundamentals-initiative/evaluation/case-studies/tower.html)) |
| **Up-and-comer / specialist** | `rust-helmet`, `tower-http-tracing`, `axum-trace-id`, OpenTelemetry-specific Axum layers, framework bundles. | Useful for broader security-policy management or telemetry export, but they duplicate capabilities, narrow framework choice, or lack the maturity/evidence of Tower’s core stack. `axum-trace-id`, for example, is tied to older Axum/Tower generations. ([axum-trace-id](https://lib.rs/crates/axum-trace-id), [tower-http-tracing](https://docs.rs/tower-http-tracing/latest/tower_http_tracing/), retrieved 2026-09-26.) ([lib.rs](https://lib.rs/crates/axum-trace-id)) |

#### Authority used

- **Rust Project publications:** the Async Book establishes that this is an ecosystem, not standard-library, decision. The Rust async-fundamentals Tower case study describes `Service` and `Layer` as the composition mechanism. These are authoritative for language/toolchain boundaries and the intended abstraction. ([Async Book](https://rust-lang.github.io/async-book/08_ecosystem/00_chapter.html), [Tower case study](https://rust-lang.github.io/async-fundamentals-initiative/evaluation/case-studies/tower.html), retrieved 2026-09-26.) ([rust-lang.github.io](https://rust-lang.github.io/async-book/08_ecosystem/00_chapter.html))
- **Maintainer documentation and source:** Tower, Tower HTTP, Tracing, Axum, Actix Web, and Poem documentation define actual ordering and middleware behavior. These are authoritative for API semantics. ([Axum middleware ordering](https://docs.rs/axum/latest/axum/middleware/), [Tower HTTP request ID](https://docs.rs/tower-http/latest/tower_http/request_id/), [Actix middleware](https://actix.rs/docs/middleware/), [Poem middleware](https://docs.rs/poem/latest/poem/middleware/), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/axum/latest/axum/middleware/))
- **Maintained reference implementations:** Axum’s official tracing example uses `tower_http::TraceLayer`, route templates, and `tracing`. Tower HTTP itself maintains Axum, Warp, and Tonic examples. ([Axum tracing example](https://github.com/tokio-rs/axum/blob/main/examples/tracing-aka-logging/src/main.rs), [tower-http repository](https://github.com/tower-rs/tower-http), retrieved 2026-09-26.) ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/tracing-aka-logging/src/main.rs))
- **Community survey:** the State of Rust survey is useful evidence that async complexity and tooling cost remain material, but it does not identify a middleware winner; therefore it is contextual rather than selection evidence. ([2024 State of Rust Survey](https://blog.rust-lang.org/2025/02/13/2024-State-Of-Rust-Survey-results/), retrieved 2026-09-26.) ([blog.rust-lang.org](https://blog.rust-lang.org/2025/02/13/2024-State-Of-Rust-Survey-results/))
- **Security evidence:** RustSec package pages were checked for recommended crate members where retrievable. ([tower-http RustSec](https://rustsec.org/packages/tower-http.html), [tracing RustSec](https://rustsec.org/packages/tracing.html), retrieved 2026-09-26.) ([rustsec.org](https://rustsec.org/packages/tower-http.html))

#### Practice evidence

1. **Axum** is maintained under `tokio-rs`, explicitly delegates middleware to Tower, and maintains a tracing example combining route templates, `TraceLayer`, and `tracing`. This is directly representative of a modern Rust HTTP service. ([Axum repository](https://github.com/tokio-rs/axum), [tracing example](https://github.com/tokio-rs/axum/blob/main/examples/tracing-aka-logging/src/main.rs), retrieved 2026-09-26.) ([github.com](https://github.com/tokio-rs/axum))
2. **Cargo**, a Rust Project tool, uses `tracing` for its diagnostics, supporting `tracing` as the shared instrumentation vocabulary rather than a web-only logger. ([Cargo Contributor Guide](https://doc.crates.io/contrib/implementation/debugging.html), retrieved 2026-09-26.) ([doc.crates.io](https://doc.crates.io/contrib/implementation/debugging.html))
3. **Actix Web** has a mature competing architecture: reverse-registration middleware, an opt-in access `Logger`, path exclusions, and default-header middleware. Its `Logger` writes through `log`, and `DefaultHeaders` deliberately does not override an existing value; therefore those exact built-ins do not meet this bundle’s structured-single-event and unconditional-header semantics without customization. ([Actix middleware](https://actix.rs/docs/middleware/), [Actix Logger](https://docs.rs/actix-web/latest/actix_web/middleware/struct.Logger.html), retrieved 2026-09-26.) ([actix.rs](https://actix.rs/docs/middleware/))
4. **Poem** ships request-ID, propagation, set-header, and tracing middleware and also exposes Tower compatibility. It is a credible R69-specific alternative, but does not improve the cross-framework case over Tower itself. ([Poem middleware](https://docs.rs/poem/latest/poem/middleware/), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/poem/latest/poem/middleware/index.html))

#### Required-figure evidence exception

The required direct crates.io and GitHub API endpoints were attempted on September 26, 2026, but the execution environment would not return their JSON. Therefore:

- exact 90-day and all-time downloads;
- GitHub API stars, `archived`, and `pushed_at`;
- GitHub search-API open-issue totals; and
- median first-maintainer-response time over the ten newest issues

are marked **unverified**, not replaced with UI approximations or third-party values. Latest versions were independently confirmed from Docs.rs, and `tower-http`’s latest release was cross-checked against its release listing. This gap must be closed before acceptance; commands are provided under `### Validation strategy`.

### Principles and implementation

#### Shared requirement and agreement level

| Feature | Shared engineering principle | Required agreement level | Rust realization |
|---|---|---|---|
| **F317** | Edge invariants must surround every middleware that can return early. | **Architectural pattern** | One explicitly ordered composition root; request-ID/security envelope outside CORS, rate limiting, idempotency, and handlers. |
| **F318** | Every application response is correlated to the request that produced it; request-scoped logs carry the same correlation ID. | **Capability plus protocol policy** | `x-request-id`, preserve supplied value or generate one, bind it to a request span, echo it on the response. |
| **F319** | Exactly one authoritative request-completion record exists. | **Capability and event-schema policy** | One `INFO` `http_request` event containing method, route template, status, duration, and request ID. |
| **F320** | High-frequency probe traffic must not dominate request logs. | **Policy** | Central exact-path exclusion list: `/healthz`, `/readyz`, `/metrics`. |
| **F321** | Security response headers are edge invariants, not handler conventions. | **Policy** | Outer overriding response-header layers; apply to preflights, 429s, 404s, and normal/error responses. |
| **F327** | Framework diagnostics and application logs share one structured pipeline, while only one component owns access logging. | **Architectural pattern and policy** | Emit through `tracing`; do not install a framework access logger; bridge `log` only when R69 requires it. |

What must agree across repositories is the **observable behavior and envelope architecture**, not middleware class names, logger internals, or framework APIs. Python’s ASGI middleware and Rust’s Tower layers are justified ecosystem differences. TypeScript currently has no web service; that is presently inapplicable, but omitting these capabilities from a future TS web service would be a missing capability rather than a justified divergence.

**BASELINE-REVIEW: F317 — crate-level middleware composition is framework-coupled, while the shared requirement is an architectural ordering contract — proposed change: record agreement at architectural-pattern level and condition the Tower crate realization on a Tower-compatible R69 result; if R69 chooses Actix, preserve the same order and acceptance criteria using Actix `Transform` middleware rather than forcing `tower-http` — affected items R69/R75/R73/R74/R76 — evidence: Axum uses Tower, Actix uses reverse-registration `Transform`, and Poem has a separate native model with Tower compatibility.** ([Axum](https://github.com/tokio-rs/axum), [Actix middleware](https://actix.rs/docs/middleware/), [Poem middleware](https://docs.rs/poem/latest/poem/middleware/), retrieved 2026-09-26.) ([github.com](https://github.com/tokio-rs/axum))

**BASELINE-REVIEW: F327 — clearing or redirecting named server logger handlers is a Python/uvicorn mechanism, not the shared principle — proposed change: state the Rust requirement as “do not install or enable a second request-access logger; route framework diagnostics into the global `tracing` subscriber” — affected items R58/R69/R75 — evidence: Axum’s request tracing is opt-in, whereas Actix’s access `Logger` is also explicitly installed and emits through `log`.** ([Axum tracing example](https://github.com/tokio-rs/axum/blob/main/examples/tracing-aka-logging/src/main.rs), [Actix Logger](https://docs.rs/actix-web/latest/actix_web/middleware/struct.Logger.html), retrieved 2026-09-26.) ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/tracing-aka-logging/src/main.rs))

#### Architectural alternatives

| Alternative | Result |
|---|---|
| **One all-in-one custom middleware** | Rejected. It hides ordering, couples unrelated policies, and makes request-ID/header/access-log behavior harder to test independently. |
| **Only `tower_http::TraceLayer` with custom callbacks** | Ranked runner-up. It is maintained and flexible, but `OnResponse` receives the response, duration, and span—not the original request—so a central raw-path exclusion and a flat event containing request fields become dependent on span conventions and subscriber formatting. ([`OnResponse`](https://docs.rs/tower-http/latest/tower_http/trace/trait.OnResponse.html), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/tower-http/latest/src/tower_http/trace/on_response.rs.html)) |
| **Tower composition plus ready-made ID/header layers and one small local access layer** | **Chosen.** It minimizes custom code while keeping the event schema, path exclusion, route-template adapter, and exact-one-event property explicit. |
| **Framework-native Logger/DefaultHeaders bundle** | Qualified only if R69 chooses that framework. Actix’s built-ins do not meet overriding security-header semantics or the shared structured pipeline without customization. |

#### Required outermost-to-innermost order

Use a **single `tower::ServiceBuilder`**, for which declaration order is request execution order. Repeated `Router::layer` calls have the opposite visual behavior, so the template should prohibit repeated composition-root calls and centralize the stack. ([Axum ordering documentation](https://docs.rs/axum/latest/axum/middleware/), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/axum/latest/axum/middleware/))

```text
REQUEST
  1. SetRequestIdLayer                         outermost request mutation
  2. ForceRequestIdResponseLayer               local; unconditional response echo
  3. Security header: HSTS                     overriding
  4. Security header: Referrer-Policy          overriding
  5. Security header: X-Frame-Options          overriding
  6. Security header: X-Content-Type-Options   overriding
  7. CanonicalAccessLogLayer                   local span + one completion event
  8. CORS layer                                R76
  9. Rate-limit layer                          R74
 10. Idempotency layer                         R73
 11. Error-to-response boundary and router
RESPONSE
```

The response traverses that list in reverse. Consequently:

- a CORS preflight returned at layer 8 passes through the access layer, all security layers, and request-ID echo;
- a rate-limit 429 returned at layer 9 does the same;
- CORS is outside rate limiting, so browser-visible 429 responses can retain appropriate CORS metadata;
- rate limiting is shown outside idempotency as the default composition, but R73/R74 may revisit only their relative inner order; neither may move outside layer 7 without reopening R75.

The stock `SetRequestIdLayer` preserves an inbound ID and creates one when absent. Tower HTTP also has `PropagateRequestIdLayer`, but its documentation states that it does not overwrite an existing response header. Python’s assignment semantics are stricter, so the recommendation uses a small local response layer that captures the selected request ID and unconditionally inserts it into the response. ([Tower HTTP request-ID source](https://docs.rs/tower-http/latest/src/tower_http/request_id.rs.html), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/tower-http/latest/src/tower_http/request_id.rs.html))

#### Security-header implementation

Use four `SetResponseHeaderLayer::overriding` instances. The `overriding` mode removes any downstream value and replaces it, which is the required behavior for an edge-owned invariant. ([SetResponseHeaderLayer](https://docs.rs/tower-http/latest/tower_http/set_header/response/struct.SetResponseHeaderLayer.html), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/tower-http/latest/tower_http/set_header/response/struct.SetResponseHeaderLayer.html))

Port the owner-approved Python `SECURITY_HEADERS` values byte-for-byte:

- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Referrer-Policy: no-referrer`
- `Strict-Transport-Security: <the F321 owner-approved value>`

Do not substitute `if_not_present`: that would allow handlers or inner middleware to weaken the policy. A multi-header Tower HTTP layer now exists, but its documentation notes boxing/dynamic dispatch for heterogeneous producers; four fixed single-header layers use older, simpler semantics and keep the values independently testable. ([Tower HTTP multiple headers](https://docs.rs/tower-http/latest/tower_http/set_header/response/), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/tower-http/latest/tower_http/set_header/response/))

“Unconditional” means every **application-generated HTTP response**. Transport failures and panics that produce no response cannot carry headers. Any timeout, panic catcher, or error mapper selected by R69 must therefore remain inside this envelope.

#### Canonical access event

The local `CanonicalAccessLogLayer` should:

1. run after request-ID selection;
2. resolve the framework’s low-cardinality route template;
3. create a request span containing `request_id`, `method`, and `route`;
4. instrument the inner service future so application logs inherit that context;
5. measure elapsed time with `Instant`;
6. on response completion, emit exactly one `INFO` event named `http_request`;
7. include flat fields `request_id`, `method`, `route`, `status`, and `duration_ms`;
8. omit only that completion event when `request.uri().path()` is in the central exclusion list;
9. still create the request span for probes, so any unexpected probe-handler diagnostics retain the request ID;
10. never log request/response bodies, authorization headers, cookies, or arbitrary headers.

Logging occurs when the response future resolves, not when a streaming body reaches end-of-stream. That mirrors the Python middleware’s application-response duration and avoids a second “body completed” access event.

The route-template resolver is the only R69-specific adapter. For Axum, use `MatchedPath`, which Axum explicitly exposes to middleware and demonstrates with `TraceLayer`; apply the stack after routes and an explicit fallback have been installed. ([Axum `MatchedPath`](https://docs.rs/axum/latest/src/axum/extract/matched_path.rs.html), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/axum/latest/src/axum/extract/matched_path.rs.html))

A central denylist is preferred over route-level opt-out because it is auditable in one location and cannot silently disappear when a probe route is moved or rebuilt:

```rust
pub const ACCESS_LOG_EXCLUDED_PATHS: &[&str] =
    &["/healthz", "/readyz", "/metrics"];
```

Match `Uri::path()`, so query strings do not defeat exclusion. `/healthz/` remains distinct unless explicitly listed.

#### Framework/server log integration

| R69 result | F327 action |
|---|---|
| **Axum/Hyper or another tracing-native Tower server** | Do not install a second `TraceLayer` with default request/response events. Keep framework lifecycle, rejection, and connection diagnostics flowing through the R58 subscriber. There is no uvicorn-style access handler to clear. |
| **Poem with Tower compatibility** | Disable Poem’s duplicate `Tracing`/`RequestId` middleware when this bundle owns those concerns; retain other diagnostics in the shared subscriber. |
| **Actix Web** | Do not install `actix_web::middleware::Logger`. Bridge remaining `log` records once through the R58-owned `tracing_log::LogTracer` or equivalent; do not initialize `env_logger` alongside the tracing subscriber. `tracing-actix-web` is a qualified span adapter, but the middleware realization must be rewritten into Actix’s native model. ([TracingLogger](https://docs.rs/tracing-actix-web/latest/tracing_actix_web/struct.TracingLogger.html), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/tracing-actix-web/latest/tracing_actix_web/struct.TracingLogger.html)) |

#### Minimal realistic dependency set

```toml
[package]
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"

[dependencies]
tower = { version = "0.5.3", default-features = false, features = ["util"] }
tower-http = {
  version = "0.7.1",
  default-features = false,
  features = ["request-id", "set-header"],
}
tracing = { version = "0.1.44", default-features = false, features = ["std"] }
```

`tower` 0.5.3, `tower-http` 0.7.1, and `tracing` 0.1.44 were the current Docs.rs releases retrieved September 26, 2026. ([tower 0.5.3](https://docs.rs/crate/tower/latest), [tower-http 0.7.1](https://docs.rs/crate/tower-http/latest), [tracing 0.1.44](https://docs.rs/crate/tracing/latest), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/crate/tower/latest))

#### Composition-root reference pattern

```rust
let middleware = ServiceBuilder::new()
    // Outermost request invariant.
    .layer(SetRequestIdLayer::x_request_id(MakeRequestUuid))

    // Outermost response invariants.
    .layer(ForceRequestIdResponseLayer::x_request_id())
    .layer(SetResponseHeaderLayer::overriding(HSTS, hsts_value))
    .layer(SetResponseHeaderLayer::overriding(
        HeaderName::from_static("referrer-policy"),
        HeaderValue::from_static("no-referrer"),
    ))
    .layer(SetResponseHeaderLayer::overriding(
        HeaderName::from_static("x-frame-options"),
        HeaderValue::from_static("DENY"),
    ))
    .layer(SetResponseHeaderLayer::overriding(
        HeaderName::from_static("x-content-type-options"),
        HeaderValue::from_static("nosniff"),
    ))

    // One structured request-completion event.
    .layer(CanonicalAccessLogLayer::new(
        route_template_resolver,
        ACCESS_LOG_EXCLUDED_PATHS,
    ))

    // Early-returning policy middleware remains inside the envelope.
    .layer(cors_layer)          // R76
    .layer(rate_limit_layer)    // R74
    .layer(idempotency_layer);  // R73
```

This is a reference pattern; concrete layer types for R73/R74/R76 and the route resolver remain owned by those decisions.

#### Observable acceptance criteria

- Supplied `x-request-id` is preserved and echoed; absent ID becomes a valid generated UUID and is echoed.
- All application events emitted while handling the request carry the same request ID through the tracing span.
- A CORS preflight and a rate-limit 429 contain the request-ID and all four security headers.
- Downstream attempts to alter a security header or response request ID are overwritten by the edge envelope.
- Every completed non-probe request emits exactly one `http_request` event.
- `/healthz`, `/readyz`, and `/metrics`, including query strings, emit zero `http_request` events.
- The canonical event contains method, route template where available, status, duration in milliseconds, and request ID.
- 404 and mapped 5xx responses also emit one event and carry the envelope headers.
- No default `tower_http::trace` start/finish events, Actix access line, or second canonical access event appears.
- Framework lifecycle and error diagnostics remain structured through R58.

#### Performance evaluation

No “fastest” claim is made. The representative benchmark should compare a bare R69 service against the full stack using:

- 1 KiB JSON response;
- route `/items/{id}`;
- 128 concurrent connections;
- 30-second steady-state run;
- one run with access logging filtered out and one with JSON events written to a non-blocking sink;
- p50/p95/p99 latency, throughput, CPU, peak RSS, output bytes/request, clean build time, incremental build time, and release binary size.

The expected cost centers are UUID generation for requests without IDs, one span and one structured event per logged request, and log serialization/I/O. Fixed header insertion and exact comparison against three probe paths should be secondary. Selection must be reconsidered only if the realistic benchmark shows the local layer—not log I/O—dominates latency or resource use.

### Recommendation

Adopt the named **Tower edge-envelope stack**:

1. **`tower` 0.5.3** — one `ServiceBuilder` composition root.
2. **`tower-http` 0.7.1** with only `request-id` and `set-header` features:
   - `SetRequestIdLayer::x_request_id(MakeRequestUuid)`;
   - four `SetResponseHeaderLayer::overriding` layers.
3. **Local `ForceRequestIdResponseLayer`** — unconditional `x-request-id` response echo, because the stock propagator intentionally does not overwrite an existing response value.
4. **Local `CanonicalAccessLogLayer`** — request span, exact central probe exclusion, and one flat `tracing` completion event.
5. **`tracing` 0.1.44** — instrumentation vocabulary consumed by the R58-owned subscriber.
6. **No framework access logger** — framework diagnostics flow through the shared tracing pipeline; only the local access layer owns `http_request`.

Fixed order:

```text
Set request ID
→ force response request ID
→ four overriding security headers
→ canonical access log
→ CORS
→ rate limit
→ idempotency
→ error-mapped router/handlers
```

This is the recommendation if R69 selects a Tower-compatible framework. A non-Tower R69 winner is an explicit re-verification trigger, not permission to weaken the principles.

### Members

#### tower 0.5.3

##### Landscape

`tower` is the established ecosystem abstraction for composable request/response services. The Rust async-fundamentals initiative describes Tower’s core use case as constructing middleware stacks from `Service` and `Layer`. ([Tower case study](https://rust-lang.github.io/async-fundamentals-initiative/evaluation/case-studies/tower.html), retrieved 2026-09-26.) ([rust-lang.github.io](https://rust-lang.github.io/async-fundamentals-initiative/evaluation/case-studies/tower.html))

Maintenance state: **active**. Docs.rs reported 0.5.3 as current, and the repository showed ongoing 2026 issue and pull-request activity. ([Docs.rs](https://docs.rs/crate/tower/latest), [repository](https://github.com/tower-rs/tower), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/crate/tower/latest))

##### Principles and implementation

Tower preserves F317 by making the service stack explicit and independently testable. A single `ServiceBuilder` executes layers top-to-bottom on requests, avoiding the reverse-order surprise caused by repeated framework `.layer(...)` calls. ([Axum middleware ordering](https://docs.rs/axum/latest/axum/middleware/), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/axum/latest/axum/middleware/))

##### Dominant choice

`tower` 0.5.3 is the dominant choice for a Tower-compatible R69 result because it is framework-neutral at the `http::Request`/`Response` service boundary and is already the middleware foundation of Axum. ([Axum repository](https://github.com/tokio-rs/axum), retrieved 2026-09-26.) ([github.com](https://github.com/tokio-rs/axum))

##### Qualified shortlist

- Actix Web’s `Service`/`Transform` architecture if R69 selects Actix.
- Poem’s native middleware, possibly through its `TowerLayerCompatExt`, if R69 selects Poem.
- Direct framework middleware functions for very small local layers, while retaining the same ordering contract.

([Actix middleware](https://actix.rs/docs/middleware/), [Poem middleware](https://docs.rs/poem/latest/poem/middleware/), retrieved 2026-09-26.) ([actix.rs](https://actix.rs/docs/middleware/))

##### Excluded by gate

- **Tower 0.4:** excluded for a new template because current Axum/Tower ecosystem integration is on the Tower 0.5 family.
- **A framework-global singleton middleware with hidden registration order:** fails the explicit-order architectural gate.
- **A Tower recommendation after R69 selects an incompatible framework:** fails compatibility and must trigger re-research rather than an adapter pile-up.

##### Up-and-comers

The Rust async-fundamentals initiative explores a future Tower API using async functions in traits, but it is design work rather than a released replacement. Do not target unreleased abstractions. ([Tower AFIT case study](https://rust-lang.github.io/async-fundamentals-initiative/evaluation/case-studies/tower.html), retrieved 2026-09-26.) ([rust-lang.github.io](https://rust-lang.github.io/async-fundamentals-initiative/evaluation/case-studies/tower.html))

##### Fit for this template

1. **License:** MIT; compatible with `MIT OR Apache-2.0`. ([Repository](https://github.com/tower-rs/tower), retrieved 2026-09-26.) ([github.com](https://github.com/tower-rs/tower))
2. **MSRV:** Tower 0.5 records an MSRV of Rust 1.64, below the template’s September 2026 stable-minus-two floor. Full dependency-tree verification remains mandatory. ([Tower repository activity](https://github.com/tower-rs/tower/pulls), retrieved 2026-09-26.) ([github.com](https://github.com/tower-rs/tower/pulls))
3. **Advisories / unsafe:** no project-written unsafe is needed. The direct RustSec page was not usable in this run; `cargo audit` and `cargo geiger` must close the dependency-tree gate.
4. **OS:** selected APIs are not OS-specific; actual acceptance requires Ubuntu and macOS CI. Windows is expected to work but is not an owner-required matrix target.
5. **Features/runtime:** use `default-features = false, features = ["util"]`. This avoids Tower’s legacy logging default and does not itself choose an async runtime. ([Cargo.toml](https://github.com/tower-rs/tower/blob/master/tower/Cargo.toml), retrieved 2026-09-26.) ([github.com](https://github.com/tower-rs/tower/blob/master/tower/Cargo.toml))
6. **Compile/binary cost:** moderate generic-monomorphization cost; contain the full type in the composition root and do not expose it in library public APIs.

##### Recommendation

Use:

```toml
tower = { version = "0.5.3", default-features = false, features = ["util"] }
```

Commit `Cargo.lock` for the CLI/service binary while retaining a normal semver requirement in the library manifest.

##### Ranked runner-up

The selected framework’s native middleware composition, with an explicit order test. It is acceptable only if R69 is non-Tower.

##### Tradeoffs

Tower’s main cost is type complexity and sometimes difficult compiler errors. The benefit is a typed, independently testable stack shared across routers, clients, and other services. Keep the stack private to `web::app` and expose ordinary functions or boxed services at module boundaries where necessary.

##### Parameters

- `version = 0.5.3`
- `default-features = false`
- `features = ["util"]`
- `runtime coupling = none for selected features`
- `maintenance state = active`

##### Migration implications

Add the direct dependency, replace repeated framework `.layer(...)` calls with one `ServiceBuilder`, and add an architecture test/comment fixing declaration order as request outermost-to-innermost.

##### Validation strategy

Planned:

```bash
cargo tree -e features -i tower
cargo +1.96.0 check --workspace --all-targets
cargo test --test web_middleware_contract
```

The contract test must prove actual execution order with marker layers, not merely inspect source order.

##### Confidence & re-verify trigger

**High** for a Tower-compatible R69 winner. Re-verify if Tower 0.6 is released, Tower raises its MSRV above the template floor, a RustSec advisory opens, or R69 selects a non-Tower framework.

##### Sources

- [Tower 0.5.3 Docs.rs](https://docs.rs/crate/tower/latest), retrieved 2026-09-26. ([docs.rs](https://docs.rs/crate/tower/latest))
- [Tower repository](https://github.com/tower-rs/tower), retrieved 2026-09-26. ([github.com](https://github.com/tower-rs/tower))
- [Tower Cargo.toml](https://github.com/tower-rs/tower/blob/master/tower/Cargo.toml), retrieved 2026-09-26. ([github.com](https://github.com/tower-rs/tower/blob/master/tower/Cargo.toml))
- [Rust Tower case study](https://rust-lang.github.io/async-fundamentals-initiative/evaluation/case-studies/tower.html), retrieved 2026-09-26. ([rust-lang.github.io](https://rust-lang.github.io/async-fundamentals-initiative/evaluation/case-studies/tower.html))
- Required figure endpoints, to re-run:
  - `GET https://crates.io/api/v1/crates/tower`
  - `GET https://crates.io/api/v1/crates/tower/versions`
  - `GET https://api.github.com/repos/tower-rs/tower`
  - `GET https://api.github.com/search/issues?q=repo:tower-rs/tower+is:issue+is:open`
- Exact downloads, GitHub figures, and issue-response median: **unverified in this run**.

#### tower-http 0.7.1

##### Landscape

`tower-http` is the established HTTP-specific Tower middleware collection. It uses `http` types and documents compatibility with frameworks and libraries using that interface. ([tower-http repository](https://github.com/tower-rs/tower-http), retrieved 2026-09-26.) ([github.com](https://github.com/tower-rs/tower-http))

Maintenance state: **active**. Version 0.7.1 was current and released on August 31, 2026. ([Docs.rs](https://docs.rs/crate/tower-http/latest), [release listing](https://releasealert.dev/cratesio/tower-http), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/crate/tower-http/latest))

##### Principles and implementation

Use Tower HTTP only for concerns where its semantics exactly match:

- inbound request-ID preservation/generation;
- fixed overriding security response headers.

Do not force its generic tracing middleware to own the canonical event when a local layer can express the exact schema and exclusion policy more directly.

##### Dominant choice

- `SetRequestIdLayer::x_request_id(MakeRequestUuid)` for F318’s request-side behavior.
- `SetResponseHeaderLayer::overriding` for F321.
- Do **not** use `PropagateRequestIdLayer` as the sole strict echo mechanism because it intentionally preserves an existing response value rather than overriding it. ([Request-ID source](https://docs.rs/tower-http/latest/src/tower_http/request_id.rs.html), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/tower-http/latest/src/tower_http/request_id.rs.html))

##### Qualified shortlist

- Stock `PropagateRequestIdLayer` if the project weakens the contract to “`x-request-id` is reserved and inner code never writes it.”
- `TraceLayer` with custom `make_span_with`/`on_response` if R58 guarantees span-field flattening and path exclusion is implemented elsewhere.
- Poem’s built-in RequestId/PropagateHeader/SetHeader if R69 selects Poem.
- A broader security-policy crate such as Rust Helmet if future requirements expand to CSP, Permissions-Policy, or other configurable browser controls.

##### Excluded by gate

- **Actix `DefaultHeaders`:** fails the unconditional override requirement because it leaves existing values unchanged. ([Actix middleware](https://actix.rs/docs/middleware/), retrieved 2026-09-26.) ([actix.rs](https://actix.rs/docs/middleware/))
- **`axum-trace-id`:** old Axum/Tower coupling and weak current-practice evidence.
- **Enabling `tower-http = { features = ["full"] }`:** fails compile-time and dependency-minimization fit; only two features are needed.
- **Default `TraceLayer` request and response events:** fails exactly-one canonical event if left enabled alongside the local access layer.

##### Up-and-comers

The new multiple-response-header API reduces stack verbosity, but it introduces boxed heterogeneous producers. It is not necessary for four static values and is newer than the single-header API. ([Multiple response headers](https://docs.rs/tower-http/latest/tower_http/set_header/response/), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/tower-http/latest/tower_http/set_header/response/))

##### Fit for this template

1. **License:** MIT; compatible. ([Repository](https://github.com/tower-rs/tower-http), retrieved 2026-09-26.) ([github.com](https://github.com/tower-rs/tower-http))
2. **MSRV:** documented as Rust 1.65, below the template floor. ([Repository README](https://github.com/tower-rs/tower-http), retrieved 2026-09-26.) ([github.com](https://github.com/tower-rs/tower-http))
3. **Advisories / unsafe:** no open direct package advisory was displayed on the retrieved RustSec package page; the resolved lockfile still requires `cargo audit`. Local code requires no unsafe. ([RustSec](https://rustsec.org/packages/tower-http.html), retrieved 2026-09-26.) ([rustsec.org](https://rustsec.org/packages/tower-http.html))
4. **OS:** selected header/request-ID modules are platform-neutral; close the gate with Ubuntu and macOS CI.
5. **Features/runtime:** `default-features = false`, `features = ["request-id", "set-header"]`; these selected modules do not impose Tokio runtime use. ([Cargo.toml](https://github.com/tower-rs/tower-http/blob/main/tower-http/Cargo.toml), retrieved 2026-09-26.) ([github.com](https://github.com/tower-rs/tower-http/blob/master/tower-http/Cargo.toml))
6. **Compile/binary cost:** low-to-moderate with only two features; UUID generation adds its supporting dependency path.

##### Recommendation

```toml
tower-http = {
  version = "0.7.1",
  default-features = false,
  features = ["request-id", "set-header"],
}
```

Use the ready-made setter/generator and fixed-header layers; retain local ownership of strict response echo and access logging.

##### Ranked runner-up

Use stock `SetRequestIdLayer` + `PropagateRequestIdLayer` + `TraceLayer` with custom callbacks. It has less project code but weaker exact response-override semantics and a less direct path-exclusion/event-schema implementation.

##### Tradeoffs

The recommendation adds two small local middleware types instead of using every stock helper. That additional code is justified by observable contract differences, not stylistic preference. The local layers should remain small, dependency-free, and heavily contract-tested.

##### Parameters

- `version = 0.7.1`
- `default-features = false`
- `features = ["request-id", "set-header"]`
- `request header = x-request-id`
- `request ID generator = MakeRequestUuid`
- `security-header mode = overriding`
- `maintenance state = active`

##### Migration implications

Add a `security_headers()` composition helper, replace ad hoc handler header insertion, and prohibit handler ownership of `x-request-id` or the four edge security headers.

##### Validation strategy

Planned:

```bash
cargo tree -e features -i tower-http
cargo test --test web_middleware_contract request_id
cargo test --test web_middleware_contract security_headers
cargo audit
```

Add an adversarial test in which an inner handler writes a different request ID and weaker security headers; the final response must contain the edge-selected ID and owner-approved security values.

##### Confidence & re-verify trigger

**High** for the selected modules. Re-verify on a Tower HTTP minor version, changed propagation semantics, an advisory, or an MSRV increase.

##### Sources

- [tower-http 0.7.1 Docs.rs](https://docs.rs/crate/tower-http/latest), retrieved 2026-09-26. ([docs.rs](https://docs.rs/crate/tower-http/latest))
- [Request-ID module and source](https://docs.rs/tower-http/latest/src/tower_http/request_id.rs.html), retrieved 2026-09-26. ([docs.rs](https://docs.rs/tower-http/latest/src/tower_http/request_id.rs.html))
- [SetResponseHeaderLayer](https://docs.rs/tower-http/latest/tower_http/set_header/response/struct.SetResponseHeaderLayer.html), retrieved 2026-09-26. ([docs.rs](https://docs.rs/tower-http/latest/tower_http/set_header/response/struct.SetResponseHeaderLayer.html))
- [RustSec package page](https://rustsec.org/packages/tower-http.html), retrieved 2026-09-26. ([rustsec.org](https://rustsec.org/packages/tower-http.html))
- Required figure endpoints, to re-run:
  - `GET https://crates.io/api/v1/crates/tower-http`
  - `GET https://crates.io/api/v1/crates/tower-http/versions`
  - `GET https://api.github.com/repos/tower-rs/tower-http`
  - `GET https://api.github.com/search/issues?q=repo:tower-rs/tower-http+is:issue+is:open`
- Exact downloads, GitHub figures, and issue-response median: **unverified in this run**.

#### Local HTTP contract layers

##### Landscape

This member is an architectural pattern implemented in the template, not a published crate:

- `ForceRequestIdResponseLayer`
- `CanonicalAccessLogLayer`
- an R69-specific `RouteTemplateResolver`

Crate download and release figures are **inapplicable** because this is project code.

##### Principles and implementation

The local code exists only where stock semantics do not exactly meet F318–F320:

- unconditional response request-ID insertion;
- one event with a fixed schema;
- central raw-path exclusion;
- route-template extraction;
- request-scoped tracing context without duplicate request events.

Keep the two concerns in separate layer types so order remains visible.

##### Dominant choice

A small tracing-native middleware implemented with the winning framework’s supported middleware helper:

- Axum: `middleware::from_fn` or a Tower `Layer`;
- generic Tower framework: a local `Layer`/`Service`;
- Poem/Actix: native equivalent if selected by R69.

The public contract should be framework-neutral even if the adapter is not.

##### Qualified shortlist

`tower_http::TraceLayer` with a custom response callback. It is maintained and already measures response latency, but its response callback lacks the original request, making the exact flat event and exclusion policy less direct. ([Trace service source](https://docs.rs/tower-http/latest/src/tower_http/trace/service.rs.html), [`OnResponse`](https://docs.rs/tower-http/latest/tower_http/trace/trait.OnResponse.html), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/tower-http/latest/src/tower_http/trace/service.rs.html))

##### Excluded by gate

- **Route annotations as the only probe opt-out:** fails central-policy auditability.
- **Returning `Span::none()` for probes in the only request-context layer:** suppresses request-ID context for any probe-handler diagnostics.
- **A second start event plus response event:** fails exactly-one canonical event.
- **Body/header logging:** fails security and bounded-volume fit.
- **A custom subscriber that interprets span closure as access logging:** couples F319 to R58 internals and makes exactly-once behavior harder to prove.

##### Up-and-comers

OpenTelemetry semantic HTTP layers may eventually standardize more of the event/route mapping, but exporter-specific instrumentation is not needed to meet this bundle and would couple R75 to a telemetry backend.

##### Fit for this template

1. **License:** inherits `MIT OR Apache-2.0`.
2. **MSRV:** must compile at the template’s `rust-version`; use stable Rust only.
3. **Advisories / unsafe:** no additional dependency or unsafe code is required.
4. **OS:** identical source on Ubuntu and macOS; Windows should work but is not required.
5. **Features/runtime:** no feature flags; uses the runtime chosen by R69 only through the inner service.
6. **Compile/binary cost:** small. Avoid a new general-purpose dependency; if a generic Service future requires boxing, measure it against the framework helper implementation before choosing.

##### Recommendation

Implement both layers in `src/web/middleware/` with private fields and constructors. Expose only the exclusion constant and a stack-building function from the web module.

The access event target should be unique, for example:

```text
target = "rs_launch_blueprint::http_access"
message = "http_request"
```

That gives R58 a precise filter and makes duplicate detection executable.

##### Ranked runner-up

A single customized `tower_http::TraceLayer`, provided R58 serializes all parent-span fields and a separate request-context layer preserves request IDs for excluded probes.

##### Tradeoffs

Project-owned middleware must be maintained and tested. In return, the template owns the exact behavior that would otherwise be scattered across framework conventions, subscriber formatting, and stock middleware edge cases.

##### Parameters

- `excluded_paths = ["/healthz", "/readyz", "/metrics"]`
- `event message = "http_request"`
- `event level = INFO`
- `event target = "rs_launch_blueprint::http_access"`
- `duration semantic = time to application response, not body EOS`
- `route semantic = matched route template; absent/null for unmatched fallback`
- `response request-ID mode = overwrite`
- `unsafe = forbidden`

##### Migration implications

Create:

```text
src/web/middleware/mod.rs
src/web/middleware/request_id.rs
src/web/middleware/access_log.rs
src/web/middleware/security_headers.rs
```

The composition root imports constructors, not implementation details.

##### Validation strategy

Unit-test each layer using an in-memory service. Integration-test concurrency and captured JSON logs. Use a test subscriber with an in-memory writer and assert event counts and fields rather than snapshotting human-formatted output.

##### Confidence & re-verify trigger

**High** in the pattern; **medium-high** in the final concrete implementation until R69 supplies its route-template and middleware APIs. Re-verify if the selected framework cannot expose the matched route before early-return policy middleware.

##### Sources

- [Tower `Service`/`Layer` case study](https://rust-lang.github.io/async-fundamentals-initiative/evaluation/case-studies/tower.html), retrieved 2026-09-26. ([rust-lang.github.io](https://rust-lang.github.io/async-fundamentals-initiative/evaluation/case-studies/tower.html))
- [Axum `MatchedPath`](https://docs.rs/axum/latest/src/axum/extract/matched_path.rs.html), retrieved 2026-09-26. ([docs.rs](https://docs.rs/axum/latest/src/axum/extract/matched_path.rs.html))
- [Tower HTTP trace callback source](https://docs.rs/tower-http/latest/src/tower_http/trace/service.rs.html), retrieved 2026-09-26. ([docs.rs](https://docs.rs/tower-http/latest/src/tower_http/trace/service.rs.html))
- Crate figures, repository figures, reverse dependencies, advisories, and issue responsiveness: **inapplicable; local pattern rather than external crate**.

#### tracing 0.1.44

##### Landscape

`tracing` is the established structured diagnostics and request-context vocabulary in the Tokio ecosystem. Its original design explicitly targets scoped structured events in asynchronous systems and Tower-level request instrumentation. ([Tracing design issue](https://github.com/tokio-rs/tokio/issues/561), retrieved 2026-09-26.) ([github.com](https://github.com/tokio-rs/tokio/issues/561))

Maintenance state: **stable-quiet** for the `tracing` instrumentation crate. Version 0.1.44 was current and released December 18, 2025; the broader repository remains active. ([Docs.rs](https://docs.rs/crate/tracing/latest), [changelog](https://docs.rs/crate/tracing/0.1.44/source/CHANGELOG.md), retrieved 2026-09-26.) ([docs.rs](https://docs.rs/crate/tracing/latest))

##### Principles and implementation

Use `tracing` for both:

- the request span that binds request ID and route context to inner diagnostics;
- the one canonical `http_request` event.

The library crate emits events but never installs a global subscriber. The CLI/web binary initializes the R58-owned subscriber once.

##### Dominant choice

`tracing` 0.1.44 is the dominant choice because Axum and Tower HTTP already integrate with it, and Rust Project tooling such as Cargo also uses it. ([Axum example](https://github.com/tokio-rs/axum/blob/main/examples/tracing-aka-logging/src/main.rs), [Cargo diagnostics](https://doc.crates.io/contrib/implementation/debugging.html), retrieved 2026-09-26.) ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/tracing-aka-logging/src/main.rs))

##### Qualified shortlist

- `log` with a tracing bridge for dependencies that have not migrated.
- `slog` for an existing codebase already standardized on it.
- OpenTelemetry exporters layered under `tracing` by R58.

None offers a reason to replace `tracing` as the application instrumentation API here.

##### Excluded by gate

- **Parallel `env_logger` and tracing-subscriber initialization:** fails F327 by creating separate pipelines and possible duplicate records.
- **Framework-specific plain-text access logging:** fails structured canonical event requirements.
- **Direct OpenTelemetry API calls in middleware:** improperly couples the web edge to an export backend owned by R58.

##### Up-and-comers

OpenTelemetry’s Rust ecosystem continues to evolve, but even its design discussions recognize `tracing` as a prominent instrumentation API. Export should remain an R58 subscriber-layer concern rather than an R75 middleware dependency. ([OpenTelemetry discussion](https://github.com/open-telemetry/opentelemetry-rust/issues/1571), retrieved 2026-09-26.) ([github.com](https://github.com/open-telemetry/opentelemetry-rust/issues/1571?timeline_page=1))

##### Fit for this template

1. **License:** MIT; compatible. ([Repository](https://github.com/tokio-rs/tracing), retrieved 2026-09-26.) ([github.com](https://github.com/tokio-rs/tracing))
2. **MSRV:** declared below the template’s September 2026 floor; verify the resolved tree under Rust 1.96. ([Cargo.toml](https://github.com/tokio-rs/tracing/blob/master/tracing/Cargo.toml), retrieved 2026-09-26.) ([github.com](https://github.com/tokio-rs/tracing/blob/master/tracing/Cargo.toml))
3. **Advisories / unsafe:** no open package advisory was displayed on the retrieved RustSec page. The local layer requires no unsafe. ([RustSec](https://rustsec.org/packages/tracing.html), retrieved 2026-09-26.) ([rustsec.org](https://rustsec.org/packages/tracing.html))
4. **OS:** platform-neutral API; verify Ubuntu and macOS in template CI.
5. **Features/runtime:** use `default-features = false, features = ["std"]`; no runtime coupling and no attribute macro is required.
6. **Compile/binary cost:** low for macros and core event dispatch; actual log-format/export cost belongs to R58.

##### Recommendation

```toml
tracing = { version = "0.1.44", default-features = false, features = ["std"] }
```

Do not add a second subscriber or formatter in the web module.

##### Ranked runner-up

The `log` facade bridged into tracing. It is appropriate only for an R69 dependency that emits `log` records and should not become the application API.

##### Tradeoffs

Correct output depends on R58 configuring one global subscriber and retaining structured fields. Filters can suppress the canonical access event; production policy must therefore explicitly enable the access target at `INFO`.

##### Parameters

- `version = 0.1.44`
- `default-features = false`
- `features = ["std"]`
- `access target minimum level = INFO`
- `subscriber ownership = R58`
- `log bridge ownership = R58`
- `maintenance state = stable-quiet`

##### Migration implications

Replace web-local logger calls with `tracing` fields, add a request span to the local access layer, and remove any web-specific subscriber initialization.

##### Validation strategy

Capture JSON events in tests and assert typed fields. Start the complete service with the R58 configuration and verify that framework lifecycle events and the canonical access event share one output format and destination.

##### Confidence & re-verify trigger

**High** for the instrumentation API. Re-verify if R58 selects a non-tracing pipeline contract, `tracing` 0.2 is released, the access target is filtered below `INFO`, or a RustSec advisory opens.

##### Sources

- [tracing 0.1.44 Docs.rs](https://docs.rs/crate/tracing/latest), retrieved 2026-09-26. ([docs.rs](https://docs.rs/crate/tracing/latest))
- [tracing 0.1.44 changelog](https://docs.rs/crate/tracing/0.1.44/source/CHANGELOG.md), retrieved 2026-09-26. ([docs.rs](https://docs.rs/crate/tracing/0.1.44/source/CHANGELOG.md))
- [tracing repository](https://github.com/tokio-rs/tracing), retrieved 2026-09-26. ([github.com](https://github.com/tokio-rs/tracing))
- [RustSec package page](https://rustsec.org/packages/tracing.html), retrieved 2026-09-26. ([rustsec.org](https://rustsec.org/packages/tracing.html))
- Required figure endpoints, to re-run:
  - `GET https://crates.io/api/v1/crates/tracing`
  - `GET https://crates.io/api/v1/crates/tracing/versions`
  - `GET https://api.github.com/repos/tokio-rs/tracing`
  - `GET https://api.github.com/search/issues?q=repo:tokio-rs/tracing+is:issue+is:open`
- Exact downloads, GitHub figures, and issue-response median: **unverified in this run**.

### Compatibility

| Member | Selected version | Compatibility evidence |
|---|---:|---|
| `tower` | 0.5.3 | Current Tower 0.5 release; Axum’s released line uses Tower as its middleware foundation. |
| `tower-http` | 0.7.1 | Current release; Cargo metadata and maintained examples target the Tower/HTTP 1.x ecosystem. |
| `tracing` | 0.1.44 | Tower HTTP and Axum instrumentation use the tracing 0.1 family. |
| Local layers | workspace version | Depend only on `tower`, HTTP types supplied by R69, and `tracing`. |

The maintained Axum tracing example is the shared reference: it uses Axum’s Tower middleware surface, `tower_http::TraceLayer`, route templates, and `tracing` together. The recommendation substitutes a small local access layer for `TraceLayer`’s default request logging but remains on the same tested service and instrumentation interfaces. ([Axum tracing example](https://github.com/tokio-rs/axum/blob/main/examples/tracing-aka-logging/src/main.rs), retrieved 2026-09-26.) ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/tracing-aka-logging/src/main.rs))

Compatibility is strongest if R69 selects an HTTP 1.x, Tower 0.5 framework such as the current Axum release line. If R69 selects Actix, the **principles and order remain accepted**, but this exact crate composition does not; R75 must be re-materialized using Actix native middleware.

The three selected external crates have declared MSRVs substantially below the proposed September 2026 project floor of Rust 1.96. The complete R69/R73/R74/R76 dependency tree still must be compiled under that toolchain before acceptance.

### Parameters

```text
owns (none) = n/a

assumes R58: logging-pipeline-contract =
  one global tracing subscriber;
  structured event fields preserved;
  INFO enabled for rs_launch_blueprint::http_access;
  optional log-to-tracing bridge initialized once when required;
  no second web-specific formatter or sink

assumes rust-edition = 2024
assumes msrv-policy =
  stable minus 2 minor versions, raised only in a minor release,
  declared as rust-version and tested in CI
assumes rust-version-at-retrieval = 1.96.0
assumes license = MIT OR Apache-2.0
assumes target-os-matrix = ubuntu-latest, macos-latest

integration assumption, not a registry dependency:
  R69 exposes a Tower 0.5 Service/Layer surface

CONFLICT: none
```

The Rust version floor must be recalculated on the actual merge date rather than copied indefinitely from this report.

### Migration implications

1. **`Cargo.toml`**
   - Add the three dependencies and minimal feature sets.
   - Set `edition = "2024"`, owner-approved `rust-version`, and `license`.
   - Do not enable `tower-http/full`.

2. **`src/web/app.rs` or composition root**
   - Build all routes and the fallback first.
   - Apply exactly one `ServiceBuilder`.
   - Include an order comment and link to the architecture document.
   - Do not scatter `.layer(...)` calls across route modules.

3. **`src/web/middleware/request_id.rs`**
   - Wrap `SetRequestIdLayer`.
   - Implement unconditional response echo.
   - Treat `x-request-id` as an edge-owned/reserved header.

4. **`src/web/middleware/security_headers.rs`**
   - Define the four owner-approved values.
   - Build four overriding response-header layers.

5. **`src/web/middleware/access_log.rs`**
   - Define the immutable exclusion list.
   - Add the R69 route-template resolver.
   - Create the request span and emit one flat completion event.

6. **`src/observability.rs` or R58 integration**
   - Ensure the access target is enabled at `INFO`.
   - Install any `log` bridge once.
   - Remove `env_logger`, framework access logger, or default `TraceLayer` request events.

7. **`tests/web_middleware_contract.rs`**
   - Add black-box ordering, header, request-ID, access-event, probe-exclusion, 404, 429, preflight, and duplicate-log tests.

8. **`docs/architecture/http-middleware.md`**
   - Document request order and reverse response order.
   - State ownership boundaries with R58/R69/R73/R74/R76.
   - Record the two `BASELINE-REVIEW` findings.

9. **Python and TypeScript**
   - No code changes in this item.
   - Follow-on harmonization should document the shared capability/pattern agreement. TypeScript remains inapplicable until it gains a web service.

### Validation strategy

All checks below are **planned**, not executed in this research run because the target repository and resolved R69/R73/R74/R76 implementations were not available.

#### Functional contract matrix

| Test | Expected result |
|---|---|
| Request supplies `x-request-id: client-123` | Response contains exactly `client-123`; request span and access event use `client-123`. |
| Request omits ID | Response and event contain the same generated UUID. |
| Inner handler writes a different response ID | Outer layer overwrites it with the selected request ID. |
| Inner handler writes weaker security headers | Final response contains owner-approved edge values. |
| Normal 200 | Exactly one `http_request` event. |
| Mapped 500 | Exactly one event and full response envelope. |
| 404 fallback | Exactly one event; route field absent/sentinel according to the documented schema. |
| CORS preflight | Request ID and all security headers present; exactly one event unless path is excluded. |
| Rate-limit 429 | Request ID and all security headers present; exactly one event. |
| `/healthz`, `/readyz`, `/metrics` | No `http_request` event. |
| `/healthz?full=1` | No `http_request` event. |
| `/healthz/` | Logged unless separately listed. |
| Concurrent requests | No request-ID/context cross-contamination. |
| Framework logs | Structured in the same pipeline, but no framework access-line duplicate. |

#### Planned Rust commands

```bash
cargo fmt --check

cargo clippy \
  --workspace \
  --all-targets \
  --all-features \
  -- -D warnings

cargo test --workspace
cargo test --test web_middleware_contract

# MSRV acceptance
cargo +1.96.0 check --workspace --all-targets
cargo +1.96.0 test --workspace

# Dependency/security checks
cargo audit
cargo deny check
cargo tree -e features
cargo tree -d

# Cost reporting
cargo build --release
cargo build --timings
cargo bloat --release --crates
cargo llvm-lines --release
```

Run the check/test suite on:

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest]
```

#### Planned black-box log check

Start the server with JSON output redirected to a file:

```bash
RUST_LOG='info,rs_launch_blueprint::http_access=info' \
  cargo run --bin rs-launch-blueprint-server \
  >service.jsonl 2>&1
```

Exercise it:

```bash
curl -si -H 'x-request-id: client-123' \
  http://127.0.0.1:8080/items/42

curl -si -X OPTIONS \
  -H 'origin: https://example.test' \
  -H 'access-control-request-method: GET' \
  http://127.0.0.1:8080/items/42

curl -si http://127.0.0.1:8080/test/rate-limited

curl -si http://127.0.0.1:8080/healthz
curl -si http://127.0.0.1:8080/readyz
curl -si http://127.0.0.1:8080/metrics
```

Verify:

```bash
jq -e '
  select(.target == "rs_launch_blueprint::http_access")
  | select(.fields.message == "http_request")
' service.jsonl

test "$(jq -c '
  select(
    .target == "rs_launch_blueprint::http_access"
    and .fields.request_id == "client-123"
  )
' service.jsonl | wc -l)" -eq 1

test "$(jq -c '
  select(
    .target == "rs_launch_blueprint::http_access"
    and (
      .fields.path == "/healthz"
      or .fields.path == "/readyz"
      or .fields.path == "/metrics"
    )
  )
' service.jsonl | wc -l)" -eq 0

! grep -Eq \
  'tower_http::trace::on_(request|response)|actix_web::middleware::logger' \
  service.jsonl
```

Adjust the `jq` object path to the exact R58 JSON profile; the semantic assertions must not change.

#### Planned performance check

```bash
oha -z 30s -c 128 \
  http://127.0.0.1:8080/items/42
```

Run four builds:

1. bare R69 route;
2. request ID + security only;
3. full stack with access target filtered out;
4. full stack with access JSON written to a non-blocking sink.

Record p50/p95/p99 latency, requests/second, CPU, RSS, bytes logged/request, binary size, and build timings. Do not compare these results to unrelated framework benchmarks.

#### Required evidence refresh commands

```bash
for crate in tower tower-http tracing; do
  curl -fsSL "https://crates.io/api/v1/crates/$crate" \
    | jq '.crate | {
        name: .id,
        recent_downloads,
        downloads
      }'

  curl -fsSL "https://crates.io/api/v1/crates/$crate/versions" \
    | jq '
        [.versions[] | select(.yanked == false)]
        | sort_by(.created_at)
        | last
        | {num, created_at}
      '
done

gh api repos/tower-rs/tower \
  --jq '{stargazers_count, archived, pushed_at}'

gh api repos/tower-rs/tower-http \
  --jq '{stargazers_count, archived, pushed_at}'

gh api repos/tokio-rs/tracing \
  --jq '{stargazers_count, archived, pushed_at}'

gh api 'search/issues?q=repo:tower-rs/tower+is:issue+is:open' \
  --jq '.total_count'

gh api 'search/issues?q=repo:tower-rs/tower-http+is:issue+is:open' \
  --jq '.total_count'

gh api 'search/issues?q=repo:tokio-rs/tracing+is:issue+is:open' \
  --jq '.total_count'
```

A small script should then fetch the ten most recently opened issues per repository, distinguish maintainer responses using repository permissions/organization membership, and calculate median days to first response plus unanswered count.

### Confidence & re-verify trigger

**Overall confidence: medium-high.**

- **High confidence:** shared principles, Tower ordering semantics, use of overriding security-header layers, one canonical completion event, central probe exclusion, and no duplicate framework access logger.
- **Medium-high confidence:** exact crate bundle, conditional on a Tower-compatible R69 result.
- **Evidence limitation:** mandated current download/GitHub/issue-responsiveness figures could not be retrieved from their required APIs in this run. Popularity was therefore not used as a tie-breaker.

Re-verify before merge when any of the following occurs:

1. R69 selects Actix or another non-Tower framework.
2. Tower 0.6, Tower HTTP 0.8, or Tracing 0.2 is released.
3. Any selected crate raises MSRV above the project’s stable-minus-two floor.
4. `cargo audit` or RustSec reports an open advisory in the resolved tree.
5. R58 does not provide one global structured tracing subscriber or filters the access target below `INFO`.
6. R73/R74/R76 require a position outside the access/security/request-ID envelope.
7. The owner changes the security-header policy or probe paths.
8. The realistic benchmark attributes unacceptable latency/resource cost to the local layer rather than log serialization.
9. The required crates.io/GitHub figures and issue-responsiveness sample have not been refreshed within 30 days of decision acceptance.

### Sources

All sources retrieved September 26, 2026 unless otherwise noted.

- Owner-provided precedent and ledger evidence: F317, F318, F319, F320, F321, F327; `docs/port/COMMONALITY.md`; `docs/port/PARAMETERS.md`; `docs/port/OWNER-REVIEW.md`.
- [Rust Async Book — ecosystem](https://rust-lang.github.io/async-book/08_ecosystem/00_chapter.html). ([rust-lang.github.io](https://rust-lang.github.io/async-book/08_ecosystem/00_chapter.html))
- [Rust async-fundamentals Tower case study](https://rust-lang.github.io/async-fundamentals-initiative/evaluation/case-studies/tower.html). ([rust-lang.github.io](https://rust-lang.github.io/async-fundamentals-initiative/evaluation/case-studies/tower.html))
- [2024 State of Rust Survey results](https://blog.rust-lang.org/2025/02/13/2024-State-Of-Rust-Survey-results/). ([blog.rust-lang.org](https://blog.rust-lang.org/2025/02/13/2024-State-Of-Rust-Survey-results/))
- [Tower 0.5.3](https://docs.rs/crate/tower/latest). ([docs.rs](https://docs.rs/crate/tower/latest))
- [Tower repository](https://github.com/tower-rs/tower). ([github.com](https://github.com/tower-rs/tower))
- [Tower HTTP 0.7.1](https://docs.rs/crate/tower-http/latest). ([docs.rs](https://docs.rs/crate/tower-http/latest))
- [Tower HTTP request-ID source](https://docs.rs/tower-http/latest/src/tower_http/request_id.rs.html). ([docs.rs](https://docs.rs/tower-http/latest/src/tower_http/request_id.rs.html))
- [Tower HTTP response-header layer](https://docs.rs/tower-http/latest/tower_http/set_header/response/struct.SetResponseHeaderLayer.html). ([docs.rs](https://docs.rs/tower-http/latest/tower_http/set_header/response/struct.SetResponseHeaderLayer.html))
- [Tower HTTP trace service](https://docs.rs/tower-http/latest/src/tower_http/trace/service.rs.html). ([docs.rs](https://docs.rs/tower-http/latest/src/tower_http/trace/service.rs.html))
- [Tracing 0.1.44](https://docs.rs/crate/tracing/latest). ([docs.rs](https://docs.rs/crate/tracing/latest))
- [Tracing repository](https://github.com/tokio-rs/tracing). ([github.com](https://github.com/tokio-rs/tracing))
- [Axum middleware ordering](https://docs.rs/axum/latest/axum/middleware/). ([docs.rs](https://docs.rs/axum/latest/axum/middleware/))
- [Axum tracing example](https://github.com/tokio-rs/axum/blob/main/examples/tracing-aka-logging/src/main.rs). ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/tracing-aka-logging/src/main.rs))
- [Axum `MatchedPath`](https://docs.rs/axum/latest/src/axum/extract/matched_path.rs.html). ([docs.rs](https://docs.rs/axum/latest/src/axum/extract/matched_path.rs.html))
- [Actix Web middleware](https://actix.rs/docs/middleware/). ([actix.rs](https://actix.rs/docs/middleware/))
- [Actix Web Logger](https://docs.rs/actix-web/latest/actix_web/middleware/struct.Logger.html). ([docs.rs](https://docs.rs/actix-web/latest/actix_web/middleware/struct.Logger.html))
- [Poem middleware](https://docs.rs/poem/latest/poem/middleware/). ([docs.rs](https://docs.rs/poem/latest/poem/middleware/index.html))
- [tracing-actix-web `TracingLogger`](https://docs.rs/tracing-actix-web/latest/tracing_actix_web/struct.TracingLogger.html). ([docs.rs](https://docs.rs/tracing-actix-web/latest/tracing_actix_web/struct.TracingLogger.html))
- [Cargo tracing diagnostics](https://doc.crates.io/contrib/implementation/debugging.html). ([doc.crates.io](https://doc.crates.io/contrib/implementation/debugging.html))
- [RustSec: tower-http](https://rustsec.org/packages/tower-http.html). ([rustsec.org](https://rustsec.org/packages/tower-http.html))
- [RustSec: tracing](https://rustsec.org/packages/tracing.html). ([rustsec.org](https://rustsec.org/packages/tracing.html))

## Sources

- [The Async Ecosystem - Asynchronous Programming in Rust](https://rust-lang.github.io/async-book/08_ecosystem/00_chapter.html)
- [Tower - async fn fundamentals initiative](https://rust-lang.github.io/async-fundamentals-initiative/evaluation/case-studies/tower.html)
- [axum-trace-id — server-side Rust // Lib.rs](https://lib.rs/crates/axum-trace-id)
- [axum::middleware - Rust](https://docs.rs/axum/latest/axum/middleware/)
- [axum/examples/tracing-aka-logging/src/main.rs at main · tokio-rs/axum · GitHub](https://github.com/tokio-rs/axum/blob/main/examples/tracing-aka-logging/src/main.rs)
- [2024 State of Rust Survey Results | Rust Blog](https://blog.rust-lang.org/2025/02/13/2024-State-Of-Rust-Survey-results/)
- [Advisories for package 'tower-http' › RustSec Advisory Database](https://rustsec.org/packages/tower-http.html)
- [GitHub - tokio-rs/axum: HTTP routing and request-handling library for Rust that focuses on ergonomics and modularity · GitHub](https://github.com/tokio-rs/axum)
- [Debugging - Cargo Contributor Guide](https://doc.crates.io/contrib/implementation/debugging.html)
- [Middleware | Actix Web](https://actix.rs/docs/middleware/)
- [poem::middleware - Rust](https://docs.rs/poem/latest/poem/middleware/index.html)
- [on_response.rs - source](https://docs.rs/tower-http/latest/src/tower_http/trace/on_response.rs.html)
- [request_id.rs - source](https://docs.rs/tower-http/latest/src/tower_http/request_id.rs.html)
- [SetResponseHeaderLayer in tower_http::set_header::response - Rust](https://docs.rs/tower-http/latest/tower_http/set_header/response/struct.SetResponseHeaderLayer.html)
- [tower_http::set_header::response - Rust](https://docs.rs/tower-http/latest/tower_http/set_header/response/)
- [matched_path.rs - source](https://docs.rs/axum/latest/src/axum/extract/matched_path.rs.html)
- [TracingLogger in tracing_actix_web - Rust](https://docs.rs/tracing-actix-web/latest/tracing_actix_web/struct.TracingLogger.html)
- [tower 0.5.3 - Docs.rs](https://docs.rs/crate/tower/latest)
- [GitHub - tower-rs/tower: async fn(Request) -&gt; Result&lt;Response, Error&gt; · GitHub](https://github.com/tower-rs/tower)
- [Pull requests · tower-rs/tower · GitHub](https://github.com/tower-rs/tower/pulls)
- [tower/tower/Cargo.toml at master · tower-rs/tower · GitHub](https://github.com/tower-rs/tower/blob/master/tower/Cargo.toml)
- [GitHub - tower-rs/tower-http: HTTP specific Tower utilities. · GitHub](https://github.com/tower-rs/tower-http)
- [tower-http 0.7.1 - Docs.rs](https://docs.rs/crate/tower-http/latest)
- [tower-http/tower-http/Cargo.toml at main · tower-rs/tower-http · GitHub](https://github.com/tower-rs/tower-http/blob/master/tower-http/Cargo.toml)
- [service.rs - source](https://docs.rs/tower-http/latest/src/tower_http/trace/service.rs.html)
- [Tokio Trace: A scoped, structured, logging system · Issue #561 · tokio-rs/tokio · GitHub](https://github.com/tokio-rs/tokio/issues/561)
- [tracing 0.1.44 - Docs.rs](https://docs.rs/crate/tracing/latest)
- [OpenTelemetry Tracing API vs Tokio-Tracing API for Distributed Tracing · Issue #1571 · open-telemetry/opentelemetry-rust · GitHub](https://github.com/open-telemetry/opentelemetry-rust/issues/1571?timeline_page=1)
- [GitHub - tokio-rs/tracing: Application level tracing for Rust. · GitHub](https://github.com/tokio-rs/tracing)
- [tracing/tracing/Cargo.toml at master · tokio-rs/tracing · GitHub](https://github.com/tokio-rs/tracing/blob/master/tracing/Cargo.toml)
- [Advisories for package 'tracing' › RustSec Advisory Database](https://rustsec.org/packages/tracing.html)
- [tracing 0.1.44 - Docs.rs](https://docs.rs/crate/tracing/0.1.44/source/CHANGELOG.md)
- [Logger in actix_web::middleware - Rust](https://docs.rs/actix-web/latest/actix_web/middleware/struct.Logger.html)
