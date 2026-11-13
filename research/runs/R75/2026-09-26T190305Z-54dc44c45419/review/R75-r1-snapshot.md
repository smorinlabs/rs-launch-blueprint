# 2026-09-27 — R75 — http-middleware-stack (bundle, Deep) — decision (revision 1)

Revision 1: actor `synth-opus-2026-09-26T190305Z-54dc44c45419`, model `claude-opus-5-5`, family
anthropic. Item kind `bundle`, effort tier `deep`, engines Muse, Opus and Doxa (Muse substituted
for Codex under the `engine_overrides` pilot, extended to R75 by owner decision Q17.A:
`research/RUNBOOK.md:72-77` and the canonical prompt
`research/topics/75-http-middleware-stack/prompts/http-middleware-stack.prompt.md`, lines 26 and
76). Run directory `research/runs/R75/2026-09-26T190305Z-54dc44c45419`. Nothing has been
published for R75, so there is no `## Supersedes`.

**Record note: the run's prompt snapshot predates Q17.A.** The run's `inputs/prompt.md` (manifest
hash `a8b034e9…`) still reads `- engines: codex, opus, doxa` at line 26 and lacks the substitution
sentence at line 76, and `manifest.json` still lists `required_engines` as codex, opus and doxa.
`diff` against the canonical prompt shows **exactly those two lines** differ; every other line,
including every question, requirement and fitness gate, is byte-identical. The raw legs match the
canonical engines. RUNBOOK §3 ("Changed prompt … revalidate against current inputs") makes the
reconciliation of the snapshot the controller's before acceptance; this decision cites the
snapshot only for lines the two files share.

**Revision note (revision 1).** This is the first synthesis of R75. It reads the item prompt, the
run's `inputs/`, the four raw reports in full (`raw/muse.md`, `raw/opus.md`,
`raw/doxa-openai.normalized.md`, `raw/doxa-gemini.normalized.md`) and the one published
prerequisite decision, R69 revision 9 (`research/topics/69-web-framework-stack/DECISION.md`,
sha256 `d4507f5b2ca4201d9837caf013de16f30070cb3e2f5558eb66f7ded9dfd2c10d`, equal to
`inputs/prerequisites.json`). R58's decision is **missing** (`inputs/prerequisites.json`: R58
`decision: missing`), so `logging-pipeline-contract` is consumed as `—` and every behaviour this
decision needs from R58 is stated as an assumption under `## Parameters`. **Every empirical check
and every figure below was rerun fresh by this synthesis** (`## Empirical check`); no raw's probe
or figure is carried as evidence. Dates: the run was executed 2026-09-27 UTC, which is the evening
of 2026-09-26 in America/Los_Angeles; the evidence logs carry UTC timestamps.

**Independence and read scope.** The synthesizer produced none of the raw reports or evidence
checks, but it is the **same model and family as the opus raw leg** (`raw/opus.md:3`,
`claude-opus-5-5`): a fresh context, not a new model family. The judgment and empirical audits are
the cross-checks. Under this worker's read constraint the synthesizer did **not** open the py or ts
repositories, `docs/port/COMMONALITY.md`, or the owner-supplied reference
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`. Every py fact below comes
either from the prompt's verbatim quotations (primary, in-bounds) or from a leg's line-cited
reading, and the latter are labelled **inherited, not re-verified** wherever they bear on a choice.

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)`** for every
candidate, as R69 records it (`research/topics/69-web-framework-stack/DECISION.md:2210-2211`).
Licence strings are reported as metadata only, and nothing is excluded on licence.

## Decision

**Status: a proposal, to be validated in the implementation phase** (owner ruling 2026-09-10, as
R69 applies it). No template source exists yet. The Rust this synthesis compiled is a scratch probe
outside the repository (`## Empirical check`).

`rs-launch-blueprint`'s web service composes its HTTP middleware as **per-concern `tower` layers
on R69's `axum` 0.8.9 `Router`, applied by one function in a fixed outermost-to-innermost order**.
The stack adds **one crate, `tower-http` 0.7.1**, plus about 75 lines of template code (the header table and four functions):

| Member | Ledger rows | Mechanism | Version |
|---|---|---|---|
| Request id | F318 | `tower_http::request_id::SetRequestIdLayer::new(x-request-id, MakeRequestUuid)` at L1; a template `from_fn(echo_request_id)` at L3 that **overwrites** the response's `x-request-id` with the edge-selected id | `tower-http` **0.7.1**, feature `request-id` (brings `uuid` 1.26.1, `v4`) |
| Security headers | F321 | one `SetMultipleResponseHeadersLayer::<Response>::if_not_present(..)` at L2 with py's four values; a handler's own value wins | `tower-http` 0.7.1, feature `set-header` |
| Canonical access event | F319, F320 | a template `axum::middleware::from_fn(access_log)` at L5: one `INFO` event, message `http_request`, target `<crate>::http_access`, fields `request_id`, `method`, `route`, `path`, `status`, `duration_ms`, all on the event; events are skipped when the **matched route template** is in `ACCESS_LOG_EXCLUDED_ROUTES = ["/healthz", "/readyz", "/metrics"]` | `axum` 0.8.9 (R69) + `tracing` 0.1.44 (the facade, R58's to place) |
| Failure containment, so F319 holds on panics | F319 | `tower_http::catch_panic::CatchPanicLayer::new()` at L6 | `tower-http` 0.7.1, feature `catch-panic` |
| Per-request timeout (R69's hand-off) | — (no ledger row; R69 `DECISION.md:943-944`) | `tower_http::timeout::TimeoutLayer::with_status_code(StatusCode::REQUEST_TIMEOUT, d)` at L9; `d` is R77's environment variable | `tower-http` 0.7.1, feature `timeout` |
| Ordering contract | F317 | `apply_middleware(router, ..)` in `src/web/middleware.rs`, applied once, last, to the fully merged router, as chained `Router::layer` calls written innermost-first, with named slots for R73, R74, R76, R78 and R79 | code; no crate |
| Framework/server log fold-in | F327 | **no silencing step**: axum and hyper ship no access logger, axum's own output is `tracing` events, and `tracing`'s `log` fallback is inert once R58's subscriber is set; the one residual is the std default panic hook, handed to R58 | code; no crate |

**Settled ledger rows: F317, F318, F319, F320, F321, F327.**

**The ordering contract, outermost first** (the order a request meets the layers; the response
passes them in reverse):

| Slot | Layer | Owner | Why here |
|---|---|---|---|
| L1 | `SetRequestIdLayer` | R75 | The id exists before anything logs or short-circuits |
| L2 | security headers, `if_not_present` | R75 | Stamps every response an inner layer produces: 404, 405, 408, 429, preflight, panic-500 |
| L3 | `echo_request_id` (overwrite) | R75 | The response id always equals the id the access event and the handler's span carry |
| L4 | *slot* | R78 / R79 | Inside L1, so the id exists; outside L5, so the access event nests in the request trace |
| L5 | `access_log` | R75 | Outside every short-circuiting layer, so 404s, 408s, 429s, preflights and panics are each logged once |
| L6 | `CatchPanicLayer` | R75 | Turns a handler panic into a 500 that L1–L5 treat as a normal response |
| L7 | *slot*: CORS, when configured | R76 | Outside L8, so a cross-origin 429 carries `Access-Control-Allow-Origin` |
| L8 | *slot*: rate limit, when configured | R74 | Rejects before the timeout clock and before idempotency work |
| L9 | `TimeoutLayer` | R75 (value R77) | Bounds handler time, including idempotency replays |
| L10 | *slot*: idempotency | R73 | Innermost, next to the handler whose response it stores |

**Not selected** (reasons under `### Principles and implementation` and `## Engines`):
`tower_http::trace::TraceLayer` as the access log (ranked runner-up), stock
`PropagateRequestIdLayer` for the response echo, a local force-echo *layer type* (the `from_fn`
does the same in six lines), `SetResponseHeaderLayer::overriding` / the multiple-header
`overriding` constructor, four single-header layers, a route-level probe opt-out (merging an
unlogged probe router), a raw-path exclusion list, `tower::ServiceBuilder` as the production
spelling (runtime-identical, but it needs `tower` as a normal dependency), `tower-helmet` 0.3.0,
`axum-helmet` 1.0.2 / `helmet-core` 1.0.1, `tower-request-id` 0.3.0, `tower-default-headers`
0.2.3, `axum-tracing-opentelemetry` 0.39.1 (R78's field), an `EnvFilter` silencing step as the F327
mechanism, and framework-native stacks (Actix `Logger`/`DefaultHeaders`, Poem middleware), which
R69's axum choice makes moot.

**`BASELINE-REVIEW:` findings carried to the controller** (RUNBOOK §4; this decision moves no
ledger row). Each is the opus leg's line, re-derived here:

- `BASELINE-REVIEW: F317 — id/security-header layers outermost so short-circuits still carry them — keep that, and additionally fix the inner order CORS ⊃ rate-limit, so a cross-origin 429 carries Access-Control-Allow-Origin — evidence: py app.py:137-146 per raw/opus.md:391-396 (inherited, not re-verified); executed here as A09 (review/evidence/stack-acceptance.log).`
  **Adopted in this stack**, because the contract places R76 at L7 outside R74 at L8. The py
  change is a follow-on. Affected items: R74, R76, py.
- `BASELINE-REVIEW: F327 — the server's own output flows through the shared pipeline and no second access line exists — record F327 in rs as satisfied by construction rather than by a silencing step; the one plain-text residual, std's default panic hook, is handed to R58 — evidence: axum-0.8.9 src/serve/listener.rs:156 and src/serve/mod.rs:369; E3 F01-F03 and its panic-hook line (review/evidence/framework-log-foldin.log).`
  **Adopted.** Affected items: R58 (F263 split).
- `BASELINE-REVIEW: F321 — conservative security headers on every API response, handler value wins — add Content-Security-Policy: frame-ancestors 'none' and Cache-Control: no-store to py's four — evidence: OWASP REST Security Cheat Sheet §Security Headers per raw/opus.md:397-404 (inherited, not re-verified).`
  **Open for owner disposition.** This decision ships py's four values. Accepting the finding is
  a two-line addition to `security_header_values()`. `if_not_present` keeps R71's HTML docs route
  and R72/R80's cacheable routes able to set their own values. Affected items: R71, R72, R80, py.

re-verify: 2026-12-26, or earlier on any of — R58 publishing `logging-pipeline-contract` (field names, span flattening, per-target levels, panic hook); R73, R74 or R76 publishing a layer whose error type is not `Infallible` or which needs a slot other than L10, L8 or L7; R78 deciding whether its OTel span replaces the `request` span; R69 republishing its `web` feature list or its `tower` dev-only clause; the owner ruling on `BASELINE-REVIEW: F321`; a `tower-http` release above 0.7.1 or an `axum` 0.9 release; a RustSec advisory against `tower-http`, `tracing` or `uuid`; hyper stabilising its `tracing` cfg

### Principles and implementation

**The shared principle.** The six ledger rows state one engineering principle:

> Every HTTP response is attributable and hardened, and every request leaves exactly one
> bounded-cardinality structured record in the one shared log pipeline — including when a layer
> short-circuits the request.

The py precedent realizes it with Starlette middleware added "last = outermost"
(`inputs/prompt.md:8`, py `web/app.py:145`). ts has no web service (`inputs/prompt.md:8`), which is
**missing capability, not drift**: the same policies apply at the same agreement levels if ts ever
gains a server.

**Agreement level per row.** "Must agree" is the owner-level policy or behaviour; "may vary" is the
mechanism.

| Row | Must agree (level) | May vary | rs realization | Evidence |
|---|---|---|---|---|
| F317 | **Architectural pattern**: the id and header layers wrap everything that can short-circuit | how order is spelled in code | L1–L3 outside L5–L10 | A08–A12, N01 |
| F318 | **Capability + wire value**: accept inbound `x-request-id` or generate one; bind it to the log context; echo it on the response, the echoed value being the logged value | id format | `SetRequestIdLayer` + span + overwrite echo | A01–A03, A14, N03 |
| F319 | **Policy**: one `http_request` event per request with route template, status, `duration_ms` and request id, also on failure | emitting mechanism; field serialization (R58) | `from_fn(access_log)` at L5 + `CatchPanicLayer` at L6 | A01b, A06–A12, N02, N04 |
| F320 | **Policy**: `/healthz`, `/readyz`, `/metrics` produce no access event | raw path vs matched template | matched-template list | A04–A07 |
| F321 | **Policy**: py's four headers on every response; a handler-set value wins | the header set may be improved (owner) | `if_not_present` at L2 | A01, A04–A13, N05 |
| F327 | **Principle**: server output flows through the one pipeline; no second access line | framework-specific | nothing to silence; panic hook to R58 | E3 F01–F04 |

**Differences from py that preserve the principle**, each justified rather than accidental:

1. **Id format.** tower-http's `MakeRequestUuid` renders a hyphenated UUID v4 (36 characters);
   py renders `uuid4().hex` (32 characters) per `raw/muse.md:123` and `raw/opus.md:132`. Both are
   opaque UUID v4 values, and inbound ids are echoed verbatim either way (A02).
2. **Exclusion keyed on the matched route template, not the raw path.** The deciding case: with
   R79's `metrics` feature off, `/metrics` is not routed. A raw-path list, as py and the openai leg
   use, would silently suppress logging of those 404s. A template list logs them, because an
   unrouted request has no `MatchedPath` (A06, A07: `/nope` and `/healthz/` are logged once with
   no `route` field). Query strings cannot defeat either form (A05).
3. **Unmatched requests are logged with `route` absent**, as py logs `route=None`
   (`raw/muse.md:124`, inherited). The Rust route template comes from axum's `MatchedPath`, which is present
   when a `Router::layer` middleware runs (A01b), because `Router::layer` wraps each route *after*
   routing and also wraps the fallback (`axum-0.8.9/src/routing/mod.rs:311-316`).
4. **F327 needs no step.** py clears `uvicorn`'s handlers (`inputs/prompt.md:9`, py
   `web/logging.py:71`). axum and hyper ship no access logger, so there is nothing to clear
   (E3; see *Framework log fold-in* below).
5. **A handler panic is logged through `CatchPanicLayer` rather than a `try/except`.** Without the
   layer, the panic unwinds through the access layer and neither an event nor a response exists
   (N04).

**Is the layered-`Service` model the idiomatic analogue of `add_middleware`? Yes** (HIGH question
1). axum documents the same onion for `Router::layer`, "middleware being executed from bottom to
top" (`axum-0.8.9/src/docs/middleware.md:61-65`), and every leg agrees. **Which direction** (HIGH
question 2): chained `Router::layer(a).layer(b)` makes the **last** call outermost, like py;
`Router::layer(ServiceBuilder::new().layer(a).layer(b))` makes the **first** call outermost. The
contract is therefore stated as an outermost-first list, and the code carries that list as a doc
comment above its innermost-first calls. **The two spellings are runtime-identical** (N06
rebuilds the stack with `ServiceBuilder` and reproduces the 429 envelope, the single event and the
replay echo). The discriminator is ownership, not behaviour. R69's published value makes `tower`
"a dev-dependency only" (`DECISION.md:1586`), and only the chained spelling leaves that value
intact. The opus leg's compile-time argument for the chained form (crates.io PR 7443) is recorded
as its claim, not verified here.

**Ready-made versus hand-written** (HIGH question 1, second half). The ecosystem ships
ready-made layers for request ids, security headers, panic containment and timeouts, all in
`tower-http`. Two pieces are template code, each because a stock layer provably misses the
contract:

- **The response echo.** Stock `PropagateRequestIdLayer` keeps any `x-request-id` already on the
  response (`tower-http-0.7.1/src/request_id.rs:454-461`). py assigns
  (`response.headers["x-request-id"] = request_id`, quoted verbatim at `inputs/prompt.md:9`). In
  this stack one inner writer is plausible: R73's idempotency store replaying a stored response.
  N03 models a naive store and shows the stock layer echoing the *original* request's id while the
  access event logs the new one. The template's six-line `echo_request_id` overwrites instead, and
  A14 passes. (The replay stand-in is a hypothesis about a naive store, not R73's design; R73 is
  open, and the hand-off below lets it choose.)
- **The access event.** `TraceLayer`'s `OnResponse` callback cannot see the request, so `route`,
  `method`, `path` and `request_id` can live only on the *span*
  (`raw/doxa-openai.normalized.md:64`, `raw/opus.md:224-229`). Whether a sink renders span fields
  depends on R58's still-missing formatter. `from_fn(access_log)` puts every field on the event,
  which is also the design the Rust project's own registry service runs: crates.io applies
  `from_fn(log_request::log_requests)` immediately outside `CatchPanicLayer` (`src/middleware.rs`
  lines 47–48 at commit `30c4ed7f`, `review/evidence/practice-check.log`).

**Architectural alternatives compared before libraries.**

| Alternative | Verdict | Ground |
|---|---|---|
| A. Per-concern `tower` layers applied by one `apply_middleware`, chained `Router::layer` | **Chosen** | Each concern tested alone; order visible in one function; axum's documented model |
| B. The same layers via one `ServiceBuilder` | Equivalent at runtime (N06); not chosen | Needs `tower` promoted to a normal dependency, contradicting R69's published value |
| C. One monolithic hand-written middleware, as py's `RequestIDMiddleware` bundles id and log | Rejected | Positioning cannot vary per concern: the headers must sit outside the access log, and the id layer outside both |
| D. Access log as `route_layer` on an API sub-router, probes merged without it (muse, gemini) | **Rejected on evidence** | N02: it logs neither the 429 from an outer rate-limit layer, nor the preflight, nor the 404 |
| E. Framework registry (loco's `Vec<Box<dyn MiddlewareLayer>>`) | Rejected for fit | Dynamic dispatch and a registry for fewer than ten layers; R69 already rejected registry patterns (F331). Loco evidence is the opus leg's, inherited |
| F. OTel-first request span (`axum-tracing-opentelemetry`) | Out of scope | R78's; slot L4 is reserved for it |

**Minimal realistic example.** This is the executed probe's library, condensed; the header table
and the two functions are the whole of the template code R75 adds:

```rust
pub const X_REQUEST_ID: HeaderName = HeaderName::from_static("x-request-id");
pub const ACCESS_LOG_EXCLUDED_ROUTES: &[&str] = &["/healthz", "/readyz", "/metrics"];

pub fn security_headers() -> SetMultipleResponseHeadersLayer<Response> {
    SetMultipleResponseHeadersLayer::if_not_present(vec![
        (header::X_CONTENT_TYPE_OPTIONS, HeaderValue::from_static("nosniff")).into(),
        (header::X_FRAME_OPTIONS, HeaderValue::from_static("DENY")).into(),
        (header::REFERRER_POLICY, HeaderValue::from_static("no-referrer")).into(),
        (header::STRICT_TRANSPORT_SECURITY,
         HeaderValue::from_static("max-age=63072000; includeSubDomains")).into(),
    ])
}

pub async fn echo_request_id(req: Request, next: Next) -> Response {
    let id = req.extensions().get::<RequestId>().map(|id| id.header_value().clone());
    let mut res = next.run(req).await;
    if let Some(id) = id { res.headers_mut().insert(X_REQUEST_ID, id); }
    res
}

pub async fn access_log(req: Request, next: Next) -> Response {
    let route = req.extensions().get::<MatchedPath>().map(|m| m.as_str().to_owned());
    let excluded = route.as_deref().is_some_and(|r| ACCESS_LOG_EXCLUDED_ROUTES.contains(&r));
    let request_id = req.extensions().get::<RequestId>()
        .and_then(|id| id.header_value().to_str().ok()).unwrap_or_default().to_owned();
    let (method, path) = (req.method().clone(), req.uri().path().to_owned());
    let span = tracing::info_span!("request", request_id = %request_id);
    let start = Instant::now();
    let res = next.run(req).instrument(span.clone()).await;
    if !excluded {
        let _entered = span.enter();
        tracing::info!(target: "rs_launch_blueprint::http_access", request_id = %request_id,
            method = %method, route = route.as_deref(), path = %path,
            status = res.status().as_u16(),
            duration_ms = start.elapsed().as_secs_f64() * 1000.0, "http_request");
    }
    res
}

/// Outermost -> innermost: L1 SetRequestId, L2 security headers, L3 id echo, [L4 R78/R79],
/// L5 access log, L6 catch-panic, [L7 R76 CORS], [L8 R74 rate limit], L9 timeout,
/// [L10 R73 idempotency]. Written innermost-first: each `.layer()` wraps all before it.
pub fn apply_middleware(router: Router, settings: &WebSettings, slots: Slots) -> Router {
    let r = slots.idempotency(router);                                           // L10
    let r = r.layer(TimeoutLayer::with_status_code(
        StatusCode::REQUEST_TIMEOUT, settings.request_timeout));                // L9
    let r = slots.rate_limit(r);                                                 // L8
    let r = slots.cors(r);                                                       // L7
    r.layer(CatchPanicLayer::new())                                              // L6
        .layer(middleware::from_fn(access_log))                                  // L5
        // L4: R78 / R79
        .layer(middleware::from_fn(echo_request_id))                             // L3
        .layer(security_headers())                                               // L2
        .layer(SetRequestIdLayer::new(X_REQUEST_ID, MakeRequestUuid))            // L1
}
```

`WebSettings` and `Slots` are placeholders for R77's settings type and for however R73, R74 and
R76 expose their layers. A conditional slot is a plain `if` that returns the router unchanged,
so an absent layer leaves the rest of the order intact (the probe's closures do exactly that).

**Security-header semantics: `if_not_present`, on the py evidence available.** The opus leg
quotes py's mechanism as `response.headers.setdefault` at py `web/middleware.py:120`, pinned to
commit `b55b8c26` (`raw/opus.md:135`, `raw/opus.md:538`). This is **inherited, not re-verified**
by this synthesizer (read constraint), and it is named for the empirical auditor. The muse and
openai legs recommend `overriding` as an "edge invariant" (`raw/muse.md:174`,
`raw/doxa-openai.normalized.md:108`), but neither quotes py's mechanism. The prompt's word
"unconditionally" (`inputs/prompt.md:9`) is qualified in the same sentence as "including HSTS over
plain http in dev". It is about presence regardless of path, status or scheme, and `if_not_present`
at L2 meets that on every executed case (A01, A04–A12). `if_not_present` also lets R71's docs page
or a cacheable R72/R80 route set its own value (A13). If the auditor finds py overrides, the
switch is one constructor, and N05 shows its behaviour. The HSTS value
`max-age=63072000; includeSubDomains` is the value both legs that read py report
(`raw/muse.md:126`, `raw/opus.md:572`); it is likewise inherited, not re-verified.

**Framework log fold-in** (MEDIUM question 3). Under a real `axum::serve` listener with a global
subscriber recording every event at every level (E3):

- axum emitted **7 `TRACE` events, target `axum::serve`**, for four requests. They are connection
  lifecycle lines (`axum-0.8.9/src/serve/mod.rs:369`); its one `error!` is the accept-error path
  (`axum-0.8.9/src/serve/listener.rs:156`).
- **No event from any `axum`, `hyper` or `tower` target at `INFO` or above**, except the one
  `tower_http::catch_panic` `ERROR` for the panicking request (F02).
- **Zero `log` records** reached a counting `log` logger (F03). `tracing`'s `log` feature is on in
  this tree only through axum's default `tower-log` → `tower/log` (`probe-crate.log`), and it
  forwards to `log` only when no `tracing` subscriber is set.
- **hyper 1.11.1 emits nothing**: its enabled features are `default`, `http1` and `server`, with
  no `tracing` (`probe-crate.log`).
- **One plain-text line bypassed the pipeline**: the std default panic hook's
  `thread '…' panicked at …` line (`framework-log-foldin.log`). It is process-global, so it is
  R58's to route into `tracing`; the web side's only obligation is to keep axum's default
  `tracing` feature on, which R69's value already does.

So the answer to "does F327 depend on R69's pick" is **no, for any tower-based framework**. It
would for `actix-web`, whose `Logger` writes through `log` (`raw/doxa-openai.normalized.md:26`);
R69 settled axum. An `EnvFilter` cap on `hyper`/`axum`/`tower` targets, which muse and gemini
propose as the mechanism (`raw/muse.md:826-831`, `raw/doxa-gemini.normalized.md:69`), is not
needed to meet F327 today. It is recorded as a defence-in-depth request to R58's profile design,
not as a requirement.

**The owner-supplied reference's C11** (owner decision 11 requires a disposition per overlapping
row; R69 hands C11 to R75 at `DECISION.md:2197`). This synthesizer did not open the document. The
two orderings below are **as the opus leg quotes them** (`raw/opus.md:290-291`), and each was
re-executed here as N01:

| C11 row (as quoted) | Disposition | Executed ground |
|---|---|---|
| security headers via `SetResponseHeaderLayer`, placed after `CompressionLayer`, i.e. **innermost** | **Differ** | N01c/N01d: the 429 and the preflight return **without** `X-Frame-Options`; N01a shows the routed 200 still has it, so the failure is the order and not the layer |
| `SetSensitiveHeadersLayer → TraceLayer → SetRequestIdLayer/PropagateRequestIdLayer`, i.e. `TraceLayer` **outside** the id layer | **Differ** | N01b: the access span records `request_id = "-"` while the response carries a generated id. axum's own `examples/request-id` puts `set_x_request_id` first (`practice-check.log`, lines 36–49 of that file) |
| request-id pair from `tower-http`, "don't add crates for these" (Level One, per `raw/opus.md:288`) | Agree | L1 is that layer; L3 replaces the propagate half for the reason above |
| `CatchPanicLayer` inside the trace/log layer (per `raw/opus.md:292`) | Agree | L6 inside L5; A11 |
| `tower-http` 0.6 in the reference `Cargo.toml` (per `raw/opus.md:297`) | Differ on version | 0.7.1 is the newest non-yanked release (`figures.log`) |
| `SetSensitiveHeadersLayer`, `NormalizePathLayer`, `RequestBodyLimitLayer`, `CompressionLayer`, `tower_governor` | Not decided here | No R75 ledger row; they would sit between L6 and L10, or in R74's L8 slot for `tower_governor` |

**Landscape: the three-bin map.** *Built-in / first-party:* axum's `middleware::from_fn`,
`Router::layer`/`route_layer`, `MatchedPath`, `HandleErrorLayer`; `tower::Layer` and
`ServiceBuilder`; `tracing` spans and events. *Established industry standard:* `tower-http`
0.7.1 (`request_id`, `set_header`, `trace`, `catch_panic`, `timeout`, `cors`,
`sensitive_headers`); `tracing-subscriber` on the pipeline side (R58's). *Up-and-comers:*
`axum-helmet` 1.0.2 + `helmet-core` 1.0.1, `tower-helmet` 0.3.0, `tower-default-headers` 0.2.3,
`tower-request-id` 0.3.0, `axum-tracing-opentelemetry` 0.39.1, loco-rs's configurable stack.
Every candidate evaluated here comes from that map, which merges the muse and opus maps
(`raw/muse.md:22-38`, `raw/opus.md:46-50`). The openai and gemini maps name no candidate outside
it that survives R69's framework choice.

**Authorities, and why each counts.** The maintainers' own code at the pinned versions, read in
the private cargo home: `axum` 0.8.9, `tower-http` 0.7.1, `tracing` 0.1.44 and `hyper` 1.11.1. The
framework maintainers' reference examples: `tokio-rs/axum` `examples/request-id` and
`examples/graceful-shutdown`. The Rust project's production registry, `rust-lang/crates.io`, runs
`axum = "=0.8.9"` with `tower-http = "=0.7.1"` and the `catch-panic` and `timeout` features
(`practice-check.log`). crates.io's `recent_downloads`, GitHub's REST API and the RustSec database
are the prompt's named figure sources. OWASP's REST Security Cheat Sheet is cited only through the
opus leg (inherited).

**Figures** (`review/evidence/figures.log`, retrieved 2026-09-27T03:58Z; crates.io
`GET /api/v1/crates/<name>` and `/versions`, GitHub `repos/<o>/<r>` and
`search/issues?q=repo:<o>/<r>+is:issue+is:open`, `rustsec.org/packages/<name>.html`):

| Crate | 90-day | All-time | Newest non-yanked | Licence / `rust-version` | Stars · archived · pushed | Open issues | RustSec |
|---|---|---|---|---|---|---|---|
| `tower-http` | 155,129,876 | 479,026,426 | 0.7.1, 2026-08-31 | MIT / 1.65 | 918 · false · 2026-09-26 | 32 | RUSTSEC-2022-0043 patched `>=0.2.1`; RUSTSEC-2021-0135 withdrawn → **none open at 0.7.1** |
| `tracing` | 198,651,206 | 877,269,566 | 0.1.44, 2025-12-18 | MIT / 1.65.0 | 6,891 · false · 2026-05-30 | 628 (whole repository) | RUSTSEC-2023-0078 patched `>=0.1.40` → none open |
| `uuid` (via `request-id`) | 191,550,501 | 829,299,521 | 1.26.1, 2026-09-10 | Apache-2.0 OR MIT / 1.85.0 | 1,247 · false · 2026-09-10 | 10 | package page HTTP 404 → none |
| `tower` (dev-only, per R69) | 178,757,718 | 687,830,161 | 0.5.3, 2026-01-12 | MIT / 1.64.0 | 4,302 · false · 2026-06-22 | 69 | HTTP 404 → none |
| `tower-helmet` | 1,689 | 29,225 | 0.3.0, 2024-01-29 | MIT / null | — | — | — |
| `axum-helmet` | 25,465 | 79,665 | 1.0.2, 2026-05-26 | MIT / null | — | — | — |
| `helmet-core` | 27,724 | 86,648 | 1.0.1, 2026-05-26 | MIT / null | — | — | — |
| `tower-request-id` | 132,590 | 864,121 | 0.3.0, 2023-12-02 | MIT / null | — | — | — |

**Issue responsiveness** (the ten most recently opened issues; first comment by an `OWNER`,
`MEMBER` or `COLLABORATOR` who is not the author). `tower-rs/tower-http`: 2 of 10 answered, median
**0.1 days** over those two; 8 unanswered, 6 of them opened in the 30 days before retrieval. Offset
by five releases in 2026 and a push on the retrieval day, so maintenance state **`active`**.
`tokio-rs/tracing`: **0 of 10 answered**, last release 2025-12-18, which is past the six-month
investigate trigger. `tracing` is the facade every tokio-rs crate in this tree already uses, and
it is R58's crate to rate, so this decision records `stable-quiet` with that signal and hands the
rating to R58.

**Fitness gates for the crate members.** `tower-http` is the one crate this item adds; `uuid` and
its `getrandom`, `cfg-if` and `bitflags` chain arrive only through it (`probe-crate.log`, the
`--prune tower-http` delta: 5 packages, 58 in the normal tree versus 53 without).

| Gate | `tower-http` 0.7.1 | `uuid` 1.26.1 (transitive) | `tracing` 0.1.44 (facade) |
|---|---|---|---|
| 1 licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; MIT reported | inapplicable; `Apache-2.0 OR MIT` | inapplicable; MIT |
| 2 MSRV | declares 1.65 (`Cargo.toml:14`); the tree's highest declared `rust-version` is 1.85; **E1 passes on 1.96.0** | 1.85.0 | 1.65.0 |
| 3 advisories / `unsafe` | none open; `#![deny(unsafe_code)]` (`src/lib.rs:200`); its one `unsafe` site is a Windows-only `fs` test, not compiled here | none; 15 `unsafe` sites, no crate attribute | none open; 7 `unsafe` sites, no crate attribute |
| 4 OS | CI: stable/beta/nightly on ubuntu-latest, `test-os` on macos-latest and windows-latest, an MSRV job and `cargo hack --each-feature` (`.github/workflows/CI.yml` lines 58–93); E1–E3 executed on macOS arm64; **ubuntu-latest not executed here** | platform-neutral | platform-neutral |
| 5 default features / runtime | `default = []`; `request-id` → `uuid`; `set-header` → nothing; `catch-panic` → `tracing`, `futures-util/std`, `http-body`, `http-body-util`; `timeout` → `http-body`, `tokio/time`, already on in R69's tokio | `v4` only | `std`, `attributes` (axum's defaults) |
| 6 size / compile cost | low: 5 packages added | small | already in axum's tree |

The excluded comparators fail **gate 2 as evidenced**: `tower-helmet`, `axum-helmet`,
`helmet-core` and `tower-request-id` all publish `rust_version: null` (`figures.log`). None was
built on the 1.96 floor, so the exclusion rests on the undeclared value, not on an observed build
failure. They also lose on fit, which would stand without the gate. The helmet crates bundle a CSP
policy surface F321 does not ask for, `tower-helmet` has had no release since 2024-01-29, and
`tower-request-id` generates ULIDs beside py's UUIDs.

**Cross-repo agreement** (HIGH question 3). No shared low-level *value* is recommended except the
owner-level policy constants, which keep cross-service log queries uniform: the header name
`x-request-id`, the event message `http_request`, the probe list and the security-header set. py
carries two accidental drifts against current guidance, handed to the py follow-on: rate limit
outside CORS (`BASELINE-REVIEW: F317`), and the header set, pending the owner's F321 disposition.

**Hand-offs, one line each.**

- **R73.** Slot L10. Either strip `x-request-id` from stored responses or rely on L3's overwrite
  (N03, A14). The layer must satisfy `Router::layer`'s bounds (`Clone + Send + Sync + 'static`,
  error `Into<Infallible>`; `axum-0.8.9/src/routing/mod.rs:303-309`), with a fallible layer
  wrapped in `HandleErrorLayer` in the same slot.
- **R74.** Slot L8, same bounds. Shared quota state behind an `Arc`, because `Router::layer`
  clones the layer into every route.
- **R76.** Slot L7, same bounds. A09 and A10 prove the position with a real `CorsLayer`.
- **R77.** Names the request-timeout variable and its default. Datum: axum's
  `examples/graceful-shutdown` uses 10 s and crates.io uses 30 s, both with `REQUEST_TIMEOUT`
  (`practice-check.log`).
- **R70.** A timeout response is `Response::new(B::default())` with status 408
  (`tower-http-0.7.1/src/timeout/service.rs:145-146`), and a caught panic is a tower-http-built
  500 (`catch_panic.rs:351`). Neither is a problem document. Whether R70 re-maps them is R70's
  call; `RequestId` is in request extensions if R70 echoes the id.
- **R78 / R79.** Slot L4. R78 decides whether its OTel span replaces the `request` span.
- **R80.** `/healthz` and `/readyz` are excluded by template; a route R80 renames must be renamed
  in `ACCESS_LOG_EXCLUDED_ROUTES` too.
- **R58.** Owns the subscriber, the JSON field rendering of the event, the level policy for the
  `<crate>::http_access` target (it must stay visible at `INFO`), a panic hook that routes std's
  panic message into `tracing`, and optionally an `EnvFilter` cap on framework targets.
- **R69.** See `## Parameters`: `dep:tower-http` must join the `web` feature list.

**Migration implications.**

| File | Change |
|---|---|
| `Cargo.toml` | `tower-http = { version = "0.7.1", optional = true, default-features = false, features = ["request-id", "set-header", "catch-panic", "timeout"] }`; `dep:tower-http` in `web` (needs R69, see `## Parameters`); keep axum's default features (`tracing`, `tower-log`); `tower` stays dev-only; `tracing` placed by R58 |
| `src/web/middleware.rs` (new; the name R69 reserves, `DECISION.md:1424`) | `X_REQUEST_ID`, `ACCESS_LOG_EXCLUDED_ROUTES`, `security_header_values()`/`security_headers()`, `echo_request_id`, `access_log`, `apply_middleware` with the L1–L10 doc comment |
| `src/web/mod.rs` (R69's `build_router`) | call `apply_middleware` once, **last**, after every `merge`/`nest`, so no route escapes the stack |
| `src/web/cors.rs`, `rate_limit.rs`, `idempotency.rs` | R76, R74 and R73 expose a layer (or `None`) for slots L7, L8 and L10 |
| `tests/web_middleware.rs` (new; `#![cfg(feature = "web")]`) | the A01–A14 contract and the N01/N03/N04 negative controls, rewritten against the real router |
| `docs/` web section | the outermost-first contract, the exclusion list and the header set |

**Validation strategy.** *Executed* (this synthesis; `## Empirical check`): the whole contract on
the host toolchain and on the 1.96.0 floor, the six variants, and the real-listener fold-in.
*Planned* for P03: (1) the same tests in `tests/web_middleware.rs` on ubuntu-latest and
macos-latest via `cargo test --features web`; (2) an end-to-end check against the serve binary:
`curl -si -X OPTIONS -H 'Origin: https://app.example' -H 'Access-Control-Request-Method: GET'
http://127.0.0.1:$PORT/v1/projects` and `curl -si http://127.0.0.1:$PORT/healthz`, expecting
`x-request-id` and the four headers on both, exactly one `http_request` JSON line for the first
and none for the second; (3) with R73, R74 and R76's real layers in their slots, rerun A08–A10 and
A14; (4) after R58's panic hook lands, rerun E3 and expect no plain-text line.

**Confidence.** **High** for the layer model and its direction, the L1–L3 envelope, F327, and
the exclusion mechanism. **Medium-high** for the hand-written access event over `TraceLayer`,
because the choice turns on R58's formatter. **Medium** for slots L7, L8 and L10 until R76, R74 and
R73 publish.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes logging-pipeline-contract = —

**This item owns no parameter** (the prompt's `- owns:` is empty, `inputs/prompt.md:23`). The five
`assumes` lines are byte-identical to `inputs/PARAMETERS.md` and `inputs/parameters.json`
(`review/evidence/decision-shape-check.log`). **No `CONFLICT:` line is raised.**

**What this decision assumes of R58**, since `logging-pipeline-contract` is still `—` (RUNBOOK §1
requires a conditional answer to state its assumptions):

1. one global `tracing` subscriber, installed by the binary, never by the library;
2. flat event fields rendered, so `request_id`, `method`, `route`, `path`, `status` and
   `duration_ms` reach the sink with the event;
3. the `<crate>::http_access` target visible at `INFO` in the web profile;
4. a process-wide panic hook that emits the panic message as a `tracing` event and suppresses the
   std default stderr line.

If R58 publishes a formatter that always flattens the current span into each event, the
`TraceLayer` runner-up becomes viable; that is a re-verify trigger, not a conflict.

**`web-extra-surface` is not an `assumes` line**, because the prompt consumes only R58
(`inputs/prompt.md:24`, `inputs/parameters.json`). R69's value is followed in prose, as R69 and
R72 do for non-consumed values. **One integration note requires an R69 revision or a controller
ruling.** R69's published value writes the feature literally as `web = ["dep:axum", "dep:tokio"]`
(`DECISION.md:1586`), and this stack needs `"dep:tower-http"` in that list. The same value's
clause (4) already places "R72 to R76's middleware" inside the `web`-gated tree, so the addition
is within R69's stated intent. It is still a literal change to a registered value, which a
consumer may not make on its own (RUNBOOK §4). Every raw needs the same addition. The chained
`Router::layer` spelling is chosen so that the value's other clause, `tower` as a dev-dependency
only, stays intact.

## Empirical check

**Toolchain and OS.** macOS on Apple silicon (`Darwin arm64`). Host
`rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` / `cargo 1.98.1`; MSRV floor
`rustc 1.96.0 (ac68faa20 2026-05-25)` through `rustup run 1.96.0`, stable minus two minors.

**Working directory.** A scratch crate at `$TMPDIR/r75-synth-probe` (overridable with
`R75_PROBE_DIR`), materialized from heredocs by `review/evidence/probe-crate.sh`. It is outside the
repository, and **no Rust file was written into the repository**. The first run resolved and
downloaded from crates.io into the private `CARGO_HOME` this run was given; every later cargo
command runs `--offline --locked`. `Cargo.lock` sha256
`5e89a57d3a9d8513487aeee2fa4e2f07afde2eddc7c3584ae90c3be7b01d43cb`. Resolved: `axum` 0.8.9,
`tokio` 1.53.1, `tower-http` 0.7.1, `tower` 0.5.3 (dev), `tracing` 0.1.44, `uuid` 1.26.1,
`hyper` 1.11.1.

**Commands** (each run fresh by this synthesis, each shellchecked clean, each with its log):

```bash
bash review/evidence/probe-crate.sh          > review/evidence/probe-crate.log
bash review/evidence/stack-acceptance.sh     > review/evidence/stack-acceptance.log
bash review/evidence/negative-controls.sh    > review/evidence/negative-controls.log
bash review/evidence/framework-log-foldin.sh > review/evidence/framework-log-foldin.log
bash review/evidence/figures.sh              > review/evidence/figures.log
bash review/evidence/practice-check.sh       > review/evidence/practice-check.log
bash review/evidence/decision-shape-check.sh > review/evidence/decision-shape-check.log
```

Run from the run directory, `research/runs/R75/2026-09-26T190305Z-54dc44c45419`. `figures.sh` and
`practice-check.sh` go to the network (crates.io API, `gh api`, rustsec.org), so a rerun
re-observes rather than reproduces their numbers.

**Observed output.**

| Check | Script | Result |
|---|---|---|
| E0 resolution and version matrix | `probe-crate.sh` | resolves; 58 unique normal-tree packages, 5 only through `tower-http`; highest dependency `rust-version` 1.85; `hyper` features `default`, `http1`, `server`; `tracing`'s `log` feature via axum `tower-log` → `tower/log`; the only duplicates are the proc-macro `syn` 2 / 3 split |
| E1 the contract | `stack-acceptance.sh` | **15 pass, 0 fail on 1.98.1; 15 pass, 0 fail on 1.96.0** |
| E2 the variants | `negative-controls.sh` | **12 pass, 0 fail** (each asserts what the variant does, including its failures) |
| E3 F327 under a real listener | `framework-log-foldin.sh` | **4 pass, 0 fail**; tally `axum::serve` TRACE 7, `r75probe::http_access` INFO 3, `tower_http::catch_panic` ERROR 1; 0 `log` records; one std panic-hook stderr line |
| E4 figures | `figures.sh` | every endpoint answered; **0 gaps** |
| E5 practice and gate items | `practice-check.sh` | 6 upstream files read at their commit SHAs; `unsafe` census of 4 crates |
| E6 shape, parameters and citations | `decision-shape-check.sh` | **all pass, 0 fail**: H2 set equal to R69's, the five `assumes` lines byte-identical, every `raw/`, `inputs/` and R69 citation resolving, and the load-bearing ones matching their quoted text |

**E1, case by case** (`stack-acceptance.log`; `oneshot` against the composed router, stand-ins in
slots L7, L8 and L10):

| Case | Request | Observed |
|---|---|---|
| A01 / A01b | `GET /v1/projects/7` | 200; UUID v4 id; all four headers; one event with `route="/v1/projects/{id}"`, `status=200`, `method=GET`, `request_id` equal to the header |
| A02 | inbound `x-request-id: abc-123` | echoed; the event's `request_id` is `abc-123` |
| A03 | handler emits its own event | the handler event's span carries the request's id |
| A04 / A05 | `/healthz`, `/healthz?probe=1` | 200, 0 events, id and headers present |
| A06 / A07 | `/nope`, `/healthz/` | 404 through the fallback, 1 event each, no `route`, id and headers present |
| A08 | 429 from the L8 stand-in | id and headers present, 1 event |
| A09 | cross-origin 429 | `access-control-allow-origin: *` present |
| A10 | CORS preflight (real `CorsLayer`) | 200, id, headers and allow-origin present, 1 event |
| A11 | handler panic | 500, headers present, 1 event, 1 `tower_http::catch_panic` ERROR whose span id equals the response id |
| A12 | 5 s handler, 200 ms timeout | 408, headers present, 1 event, `duration_ms` 201.2 |
| A13 | handler sets `X-Frame-Options: SAMEORIGIN` | preserved; the other three present |
| A14 | L10 stand-in replays a response carrying `x-request-id: original-111` | the echoed id is the new request's UUID and equals the event's |

**E2, the variants** (`negative-controls.log`):

| Case | Variant | Observed |
|---|---|---|
| N01a–d | C11 order as the opus leg quotes it | routed 200 has `X-Frame-Options` (control); the access span's `request_id` is `"-"`; the 429 and the preflight have **no** `X-Frame-Options` |
| N02a–d | muse/gemini `route_layer` access log | routed 200 → 1 event; probe 0; **404 → 0, 429 → 0, preflight → 0**; the envelope still reaches the 429 and the probe |
| N03 | stock `PropagateRequestIdLayer` at L3 under a replay | response id `original-111`, event id a fresh UUID: they disagree |
| N04 | no `CatchPanicLayer` | the request task panics; **0** events and no response |
| N05 | multiple-header `overriding` | handler's `SAMEORIGIN` becomes `DENY` |
| N06 | the recommended stack spelled with `ServiceBuilder` | identical: 429 enveloped and logged once; replay id echoed and equal to the event's |

**What the executed checks do not establish** (the list P03 must validate):

| Claim | Status |
|---|---|
| ubuntu-latest | **Not executed.** `tower-http`'s own CI covers it; the template's CI (R11) must |
| R73, R74 and R76's real layers in L10, L8 and L7 | **Stand-ins only.** A09, A10 use a real `CorsLayer`; the 429 and the replay are stand-ins |
| R58's field rendering, level policy and panic hook | **Assumed** (`## Parameters`); E3's capture layer is a test double |
| py's `setdefault` at `web/middleware.py:120`, py's HSTS value, py's order at `web/app.py:137-146` | **Inherited from the legs, not re-verified** (read constraint) |
| The owner reference's C11 text | **Not read**; N01 is built from the opus leg's quotation |
| Performance | **Not benchmarked.** The openai leg's benchmark design (`raw/doxa-openai.normalized.md:218-229`) is the plan if a cost question arises |

## Engines

Three engines produced four reports. No leg raised a `CONFLICT:` line against a registered value.

| Leg | Identity | Shape | Stack | Access log | Headers | Echo | Spelling |
|---|---|---|---|---|---|---|---|
| **Muse** (Meta, substituted for Codex) | actor `research-muse-2026-09-26T190305Z-54dc44c45419` (`raw/muse.md:3`); **no model id recorded** (gap) | bundle, 5 members | `tower-http` 0.7.1 `request-id`/`trace`/`set-header` + `tower` promoted + `tracing` | `TraceLayer` as `route_layer`, innermost (slot 7) | 4 × `overriding` | stock `Propagate` | `ServiceBuilder` |
| **Opus** | `claude-opus-5-5`, fresh context (`raw/opus.md:3`) | bundle, 5 members | `tower-http` 0.7.1 `request-id`/`set-header`/`catch-panic`/`timeout` | hand-written `from_fn` at L5 | 1 × multiple `if_not_present` | stock `Propagate` | chained `Router::layer` |
| **Doxa · openai** | `gpt-5.6-sol`, operation `research-20260926-153945-bbf18efe73ce47bf`, response `resp_0d19448973cafcc0006ab849b19e1087d0b84156fa665fa951` (`operations/doxa.json`) | bundle, 4 members | `tower` + `tower-http` `request-id`/`set-header` + `tracing` + two local layers | local layer outside CORS; raw-path exclusion | 4 × `overriding` | local **force** layer | `ServiceBuilder` |
| **Doxa · gemini** | `deep-research-preview-04-2026`, operation `research-20260926-154054-a77c9b50d4384928` (`operations/doxa.json`) | bundle, 2 members | `tower` + `tower-http` | `TraceLayer` on `/api` routes; probes merged outside | `SetResponseHeaderLayer` | stock `Propagate` | `ServiceBuilder` |

The Doxa legs are two provider jobs under `doxa-research` 3.3.0 via `scripts/doxa_no_retry.py`,
one single-provider operation per leg (`operations/doxa.json`); they are two models, not one
engine. Both `.normalized.md` twins passed the shape validator with no changes
(`operations/doxa/normalization.json`).

**All four agree** on the load-bearing core: `tower-http` 0.7.1 for the request-id and header
layers, `SetRequestIdLayer` outermost, `x-request-id` with UUID v4, CORS outside rate limiting,
idempotency innermost, the probe list, and no framework access logger to install or clear under
axum.

**Disagreements, each resolved by evidence rather than by count.**

1. **Where the access log sits and what it is** (muse and gemini: `TraceLayer` innermost as a
   `route_layer`; opus and openai: a hand-written layer outside CORS and rate limiting). **Opus and
   openai, on N02.** Muse states that its slot-7 layer "sees every response from inner services
   including 429s" (`raw/muse.md:181-184`). N02b refutes that for any rate limiter applied through
   `Router::layer`, which is the only way R74's layer can sit outside the route: the 429 is
   produced outside the `route_layer`, so the access layer never runs. N02c shows the preflight and
   the 404 are also unlogged, which muse accepts as a "justified difference"
   (`raw/muse.md:130-136`) and which F319's "one event per request" does not allow. Between opus's
   `from_fn` and openai's local `Layer` type, the difference is packaging only; `from_fn` is
   axum-native and needs no production `tower` dependency.
2. **`TraceLayer` versus a hand-written event** (muse, gemini versus opus, openai). **Hand-written,
   on the field-placement argument** (`raw/opus.md:224-229`, `raw/doxa-openai.normalized.md:64`).
   `OnResponse` cannot see the request, so the route, method, path and id are span fields whose
   rendering depends on R58's missing formatter. The opus leg executed both variants passing; this
   synthesis executed the `TraceLayer` form only as a variant (N01, N02). `TraceLayer` stays the
   ranked runner-up, and R58's formatter is its re-verify trigger.
3. **Probe exclusion mechanism** (muse and gemini: route-level split; opus: template constant;
   openai: raw-path constant). **Template constant.** The route split fails N02 as above. Gemini's
   wording, probes "merged into the composition root *outside* of the tracing middleware
   boundaries" (`raw/doxa-gemini.normalized.md:53`), can also be read as putting probes outside the
   whole stack, which would strip their id and headers against F317 and F321; A04 shows the
   recommended stack keeps them. Between the two constants, the template form logs an *unrouted*
   probe path (A07), where a raw-path list would hide a 404 on `/metrics` whenever R79's feature is
   off. The openai leg's argument for a central, auditable list
   (`raw/doxa-openai.normalized.md:131`) holds equally for the template constant.
4. **Response echo: stock `PropagateRequestIdLayer` (muse, opus, gemini) versus a forcing layer
   (openai).** **Openai, on N03 and the source.** The stock layer does not overwrite
   (`tower-http-0.7.1/src/request_id.rs:454-461`; `raw/doxa-openai.normalized.md:95`); py assigns
   (`inputs/prompt.md:9`). N03 shows the mismatch under a replay; A14 shows the six-line overwrite
   fixing it. This overturns three legs' choice on an executed case, not on a vote.
5. **Security-header semantics: `overriding` (muse, openai) versus `if_not_present` (opus).**
   **`if_not_present`, on the one leg that quotes py's mechanism** (`raw/opus.md:538`, py
   `web/middleware.py:120`, `setdefault`). This is inherited, not re-verified, and named for the
   empirical auditor. Muse's and openai's "edge invariant" reading is a design preference that
   departs from the precedent without an owner requirement; the prompt's "unconditionally" is
   about presence (see `### Principles and implementation`). N05 and A13 document both behaviours,
   so the switch is one constructor if the auditor finds otherwise.
6. **One multiple-header layer (opus) versus four single-header layers (muse, openai).** **One
   layer.** The behaviour is identical. Openai's objection, that the multiple-header layer boxes
   heterogeneous producers (`raw/doxa-openai.normalized.md:108`, `:402`), applies to closures; four
   static `HeaderValue`s need none. `SetMultipleResponseHeadersLayer` is exported at
   `tower-http-0.7.1/src/set_header/response/mod.rs:174`, and its `if_not_present` constructor is at
   `multiple_headers.rs:69`. The opus leg's report that a probe first failed with the wrong type
   parameter (`raw/opus.md:587-589`) is worth a comment in the template; the parameter is the
   response type.
7. **Spelling: `ServiceBuilder` (muse, openai, gemini) versus chained `Router::layer` (opus).**
   **Chained**, on R69's published value, not on readability. N06 proves runtime equivalence, so
   the choice cannot change behaviour. Only the chained form leaves `tower` a dev-dependency, as
   R69's value states. Muse's migration line proposes promoting `tower` (`raw/muse.md:245`,
   `:978`) without raising the conflict that change implies.
8. **Panic containment and the per-request timeout** (opus only). **Adopted.** N04 shows F319
   fails on a panic without `CatchPanicLayer`; R69 hands the per-request timeout to R75
   (`DECISION.md:943-944`), and the other three legs leave that hand-off unanswered. The 408 status
   follows axum's own example and crates.io (`practice-check.log`).
9. **F327 mechanism** (muse, gemini: an `EnvFilter` cap; opus: satisfied by construction; openai:
   do not install a second access logger). **By construction, on E3.** No framework event reaches
   `INFO`, and no `log` record appears; the cap is not needed and is left to R58 as optional
   defence in depth. Muse's residual that "hyper's below-default logging claim rests on general
   hyper 1.x knowledge" (`raw/muse.md:909-911`) is closed by E0 and E3: hyper's `tracing` feature
   is off.

**`BASELINE-REVIEW:` lines the legs raised, each disposed.**

| Leg | Line | Disposition |
|---|---|---|
| opus | F317 CORS ⊃ rate limit (`raw/opus.md:391`) | **Carried, adopted in this stack** (A09) |
| opus | F327 satisfied by construction (`raw/opus.md:379`) | **Carried, adopted** (E3) |
| opus | F321 add two OWASP headers (`raw/opus.md:397`) | **Carried, open for owner disposition** |
| openai | F317 framework-conditional realization (`raw/doxa-openai.normalized.md:55`) | **Moot.** It is conditional on a non-tower R69 result; R69 chose axum |
| openai | F327 "do not install a second access logger" (`raw/doxa-openai.normalized.md:57`) | **Subsumed** by opus's F327 line, with which it agrees |
| gemini | six lines, F317–F321 and F327 (`raw/doxa-gemini.normalized.md:29`, `:39`, `:47`, `:55`, `:63`, `:71`) | **Not challenges.** Each restates the baseline and proposes no change to a row; none is propagated |
| muse | none (`raw/muse.md:238`) | — |

**Invalid parameter lines, disposed.** Gemini writes `owns web-middleware-stack = bundle(tower,
tower-http)` (`raw/doxa-gemini.normalized.md:223`). **Struck**: R75 owns no parameter and the
registry has no such row. Gemini also writes `assumes rust-version = 1.80`
(`raw/doxa-gemini.normalized.md:224`). **Struck**: the registry value is the stable-minus-two
policy, a 1.96 floor on the run date. Muse writes `assumes logging-pipeline-contract = pending` and
`assumes web-extra-surface` (`raw/muse.md:956-967`). They are **replaced** by the byte-identical
registry line and by the prose treatment under `## Parameters`.

**Figure differences.** Every figure above is this synthesis's retrieval. Opus's figures match
exactly. Muse's `tower-http` 90-day count (156,288,393) and all-time count (478,643,150) differ
slightly from this retrieval, consistent with a different retrieval moment
(`raw/muse.md:267-268`). Gemini's figures are approximate ("~3,000", "Median < 48 hours") and its
`tower` MSRV of 1.63 is wrong: crates.io says 1.64.0. The openai leg marks its figures
unverified (`raw/doxa-openai.normalized.md:31-38`). None of these differences moves a
recommendation.

**Gaps recorded.**

1. R58's `logging-pipeline-contract` is missing; four assumptions stand in for it.
2. ubuntu-latest was not executed.
3. py and the owner reference were not read by this synthesizer; four facts are inherited from
   the legs (the `setdefault` mechanism, the HSTS value, py's CORS/rate-limit order, and the C11
   text).
4. The muse leg records an actor but no model identifier.
5. R73, R74 and R76 are stand-ins in the probe.
6. The `tracing` maintenance signal (0 of 10 recent issues answered, no release for 9 months) is
   recorded and handed to R58, not rated here.
7. The LOW question: no published Rust template documents this exact convention as a named
   pattern. The nearest are axum's `examples/request-id` (read here) and loco's default middleware
   stack (the opus leg's reading, inherited). Recorded as an evidence gap, not a negative
   finding.
8. No benchmark was run; cost is stated qualitatively plus the 5-package delta.
9. The run's `inputs/prompt.md` and `manifest.json` predate owner decision Q17.A: two prompt
   lines name Codex where the canonical prompt names Muse (see the record note at the top). The
   controller reconciles the snapshot before acceptance.
