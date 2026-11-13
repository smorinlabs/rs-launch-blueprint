# R75 http-middleware-stack — Muse raw report (Deep tier, bundle kind)

Actor: `research-muse-2026-09-26T190305Z-54dc44c45419`. Retrieval date for
all figures: 2026-09-26. This report answers
`research/runs/R75/2026-09-26T190305Z-54dc44c45419/inputs/prompt.md` exactly.
Item kind: `bundle`. R69 has resolved since the prompt was written (axum
0.8.9 on tokio, tower layer model); the R69-conditional parts of this answer
collapse onto that choice and say so. R58 (`logging-pipeline-contract`) is
still missing; assumptions about the pipeline are marked as such.

### Landscape

Category decided: the web service's HTTP middleware/layer stack — request-id
propagation, one canonical structured access-log event per request with probe
exclusion, unconditional security response headers, a defined
outermost-to-innermost ordering, and folding the framework/server's own logs
into the shared tracing pipeline instead of double-logging.

Three-bin map of the Rust field (every shortlisted candidate comes from this
map):

- Built-in / first-party: `tower::ServiceBuilder` composition + axum 0.8.9
  `Router::layer` / `Router::route_layer` / `MethodRouter::layer` (the
  framework R69 selected; its own middleware guide teaches ordering and its
  docs examples apply `tower_http` layers directly, e.g. `TimeoutLayer`,
  `ValidateRequestHeaderLayer`). No first-party request-id, access-log, or
  security-header layer ships in axum or tower themselves.
- Established industry standard: `tower-http` 0.7.1 (`request_id`,
  `trace`, `set-header`, `propagate-header` modules) from the tower-rs
  organization; `tower` 0.5.3 (the `Layer`/`Service` traits and
  `ServiceBuilder`); `tracing` 0.1.44 + `tracing-subscriber` 0.3.23 (the
  event pipeline the access log emits into); `uuid` 1.26.1 (request-id
  generation, pulled transitively through `tower-http/request-id`, not a
  direct dependency).
- Up-and-comers: `tower-helmet` 0.3.0 (helmet-style bundled security
  headers, single maintainer, 5 stars, no release since 2024-01-29);
  hand-rolled per-concern layers via `axum::middleware::from_fn` or a
  bespoke `tower::Layer` impl (a pattern alternative, not a crate).

Authoritative sources used, and why each counts:

- axum 0.8.9, tower-http 0.7.1 / 0.6.11, tower 0.5.3, axum-core 0.5.6
  vendored sources in the local cargo registry
  (`~/.cargo/registry/src/*/`, read 2026-09-26): first-party maintainer
  documentation and implementation of the exact composition model,
  ordering semantics, and layer APIs this item recommends. Pinned
  versions, not the moving `main` branch.
- axum's own middleware guide (`src/docs/middleware.md`, "Ordering") and
  `src/docs/routing/route_layer.md`: the framework's normative statement
  of `Router::layer` (last added = outermost) vs `ServiceBuilder` (first
  added = outermost) ordering and of post-match `route_layer` semantics.
- crates.io API (`GET /api/v1/crates/<name>`, `/versions`,
  `/<version>/dependencies`, `/<version>` feature maps,
  `/reverse_dependencies`) for download, release, license, rust-version,
  dependency, and adopter figures (User-Agent
  `rs-launch-blueprint-research`, 2026-09-26; bare `curl` without a
  User-Agent returned empty bodies, retried with one).
- GitHub REST API via authenticated `gh api` (`repos/<o>/<r>`,
  `search/issues?q=repo:<o>/<r>+is:issue+is:open`) for stars, archived
  state, push dates, and open-issue counts; unauthenticated
  `api.github.com` returned HTTP 403 from this network.
- rustsec.org package and advisory pages (`/packages/<name>.html`,
  `/advisories/<id>.html`) for advisory state including patched-version
  ranges; HTTP 404 (the site's rendered search page) means no advisories
  recorded for that package.
- py blueprint source (`web/middleware.py`, `web/app.py:145`,
  `web/logging.py:71`) read from the local checkout
  `/Users/stevemorin/c/py-launch-blueprint`: the precedent this item
  generalizes, used as evidence per the research mandate, not as the
  winner.
- R69 `DECISION.md` (revision 9, accepted): the settled framework choice
  (axum 0.8.9, tokio 1.53.1, tower 0.5.3 as dev-dependency,
  `web-extra-surface` parameter) this stack composes onto.

Practice evidence (well-regarded projects, with why each counts):

- `tower-http` reverse dependencies (crates.io API, 2026-09-26, 3,527
  total): `axum-core` 0.5.6, `axum` 0.8.9 (both docs/dev-only couplings,
  verified in vendored `Cargo.toml` files — evidence of organizational
  co-evolution, not runtime adoption), `kube-client` 4.2.0 (the
  Kubernetes ecosystem's canonical Rust client, uses tower-http auth and
  timeout layers over `tower`/`hyper`), `reqwest` 0.13.5 (the de-facto
  Rust HTTP client). `tracing-subscriber` has 19,019 reverse dependents
  including `axum`, `hyper`, and `hyper-util`; `uuid` has 21,232
  including `tower-http` 0.7.1 itself.
- tokio-rs/tower-rs stewardship: `tower`, `tower-http`, `axum`, and
  `tracing` are maintained under the Tokio GitHub organizations by the
  same contributor community that ships the async runtime R69 selected;
  axum's documentation treats `tower_http` layers as the companion
  vocabulary (its guide and doc-tests name them).
- No published Rust web-service template found documents this exact
  six-row convention ("id/security-header outermost, structured access
  log, silenced framework logger") as one named pattern (LOW question):
  axum's own examples and the widely copied community templates each
  cover subsets (TraceLayer here, request-id there). Recorded as an
  evidence gap, not a negative finding — the pattern below is composed
  from first-party parts, each with maintainer documentation.

Fit framing for this template (CLI + library + web service): the web
service is R69's optional `web` feature over an in-memory port; every
layer below is `http` 1.x / `tower` 0.5 native (the same major versions
axum 0.8.9 builds on), compiles on stable 1.98.1, declares
`rust-version` at or below 1.85 (inside the stable-minus-two floor), and
adds no async-runtime coupling beyond the tokio R69 already requires.
The access log emits `tracing` events into the pipeline R58 owns rather
than inventing a second sink.

Transport note: all figures below come from the named endpoints except
issue-responsiveness medians, which need per-issue comment-author reads
(10+ calls per repo) and are recorded as gaps with 0-comment counts as
the honest partial signal. No docs.rs, no web search, no other network.

### Principles and implementation

Shared requirement and agreement levels (HIGH cross-repo question). Six
behaviors carry over from py; ts has no web service, which is a missing
capability, not drift — when ts gains one, the wire-level agreements
transfer and the mechanism will differ again, as it justifiably does
here:

| # | Principle (ledger rows) | Agreement level | Shared value | Justified Rust difference |
|---|---|---|---|---|
| P1 | Request-id propagation (F318) | Capability + wire value | Header name `x-request-id`; UUID v4 generation; incoming id preserved, echoed on the response | `MakeRequestUuid` renders hyphenated (`xxxxxxxx-...`) where py renders `.hex` (32 chars): both are UUID v4, parsers accept both, and echo preserves whatever arrived |
| P2 | One canonical access event per handled request (F319) | Architectural pattern + event shape | Field set: route template, status, duration, request id; exactly-once per handled request; bounded cardinality (never the raw path) | `TraceLayer` + custom `OnResponse`/`MakeSpan` instead of structlog middleware; unmatched 404s and CORS preflights emit no event (below), where py logs `route=None` |
| P3 | Probe exclusion (F320) | Policy | Excluded set `/healthz`, `/readyz`, `/metrics` (the last only when R79's feature is on) | Route-level opt-out (probe router merged without the layer) instead of a path frozenset: `TraceLayer` ships no path filter (verified module surface), and axum's `route_layer` makes the split structural |
| P4 | Security headers stamped unconditionally (F321) | Standard (exact values) | `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `Strict-Transport-Security: max-age=63072000; includeSubDomains`, including HSTS over plain http in dev | `SetResponseHeaderLayer::overriding` composition instead of a dict; same bytes on the wire |
| P5 | Id/security-header layers outermost incl. on early returns (F317) | Architectural pattern | Outermost-to-innermost contract below; CORS preflights and rate-limit 429s still carry request-id and security headers | Spelling: `ServiceBuilder` top-to-bottom (or `Router::layer` bottom-to-top) instead of Starlette add-last; plus the Set-outside-Propagate pair order the executed probe proved |
| P6 | Framework/server logs folded in, never double-logged (F327) | Policy | Exactly one request line per handled request in the shared pipeline; server lifecycle lines structured like every other event | There is no Rust analogue of uvicorn's access logger to silence — `axum::serve` emits no per-request lines (verified: no `tracing::info!/debug!`/`log::info!` in `axum-0.8.9/src/serve/`) — so the fold-in is "emit nothing of our own plus `EnvFilter` directives", owned with R58 |

P2 differences (unmatched 404s, CORS preflights) are justified, not
accidental: both lack a route template, and P2's own cardinality rule
forbids the only alternative identifier (the raw path). The 404-scan
visibility py gets from `route=None` lines moves to metrics (R79), which
is the bounded-cardinality tool for that job. F317/F318/F321 still hold
on those responses — the executed probe asserts request-id and security
headers on a 404.

Architectural alternatives compared before choosing libraries:

1. `tower` `Layer` composition (recommended): each concern is a
   `tower_http` layer composed once in `build_router`. First-party
   parts exist for every concern (HIGH question, first half: yes —
   `request_id`, `trace`, `set-header` are all maintained
   `tower-http` modules, no hand-rolled service needed; only the
   `OnResponse`/`MakeSpan` callbacks and the header value table are
   template code). Ordering is explicit and testable with
   `tower::ServiceExt::oneshot`, the same idiom R69 selected for
   handler tests.
2. `axum::middleware::from_fn` closures per concern: less machinery
   for one-offs, but each closure re-implements extension/header
   plumbing that `tower-http` already tests (e.g. the
   preserve-incoming-id branch), and ordering is implicit in closure
   nesting order. Rejected: more template code, weaker reuse, no
   advantage once `tower-http` is in the tree for CORS anyway (R76).
3. Framework-coupled middleware (e.g. an axum-only request-id
   extractor crate): rejected — no established candidate exists, and
   `tower` layers survive a framework change better than axum-bound
   helpers, which matters because R69's choice postdates this prompt.

Ordering contract (outermost to innermost on the request path; responses
flow back in reverse). Slots 4–6 are reserved for R76/R74/R73, whose
items decide behavior; this contract places them:

1. `SetRequestIdLayer` (`x-request-id`, `MakeRequestUuid`) — outermost.
   Preserves an incoming header, else generates UUID v4, and always
   inserts `RequestId` into request extensions
   (`tower-http-0.7.1/src/request_id.rs:105-113`).
2. `PropagateRequestIdLayer` (`x-request-id`) — immediately inside (1).
   It captures the id from request *headers* at call time
   (`request_id.rs:420-426`), so (1) must wrap outside it: with the
   pair inverted, generated ids are never echoed. The executed probe
   failed exactly this way before the fix and passes after.
3. Security headers — four `SetResponseHeaderLayer::overriding`
   layers (P4 values). `overriding` matches py's unconditional stamp;
   `if_not_present` would let a handler weaken the policy.
4. CORS layer (R76's `CorsLayer`, reserved slot) — outside rate
   limiting so preflights short-circuit cheaply; inside (1)–(3) so
   preflights carry request-id and security headers (F317).
5. Rate-limit layer (R74, reserved slot).
6. Idempotency layer (R73, reserved slot).
7. `TraceLayer` access log — as a `route_layer` on the non-probe
   router (post-match, so `MatchedPath` is available for the route
   field; probes merge without it per P3). Sees every response from
   inner services including 429s and replays; `OnFailure` covers the
   error path the way py's `except` branch covers the 500 path.
8. Handler.

Composition spelling (HIGH question, second half): with
`tower::ServiceBuilder`, declaration order is execution order — the
first `.layer()` is outermost (`ServiceBuilder::layer` wraps the inner
service each call, `tower-0.5.3/src/builder/mod.rs:126-132`, and axum's
guide endorses `ServiceBuilder` for multiple middleware). With chained
`Router::layer`, the last call is outermost (axum onion diagram,
`src/docs/middleware.md:61-115` — the same convention as Starlette's
`add_middleware`, where py adds `SecurityHeadersMiddleware` then
`RequestIDMiddleware` so the id layer is outermost). The contract above
is stated outermost-to-innermost precisely so both spellings implement
it without ambiguity; the recommendation uses one `ServiceBuilder` so
the code reads in contract order.

Minimal realistic example (`src/web/middleware.rs` + `build_router`,
elided to the composition; full header table and callbacks in
`Members`):

```rust
use tower::ServiceBuilder;
use tower_http::{request_id, set_header::SetResponseHeaderLayer, trace::TraceLayer};

let id = HeaderName::from_static("x-request-id");
let api = Router::new()
    .route("/projects", get(list))
    .route_layer(access_log_layer()); // TraceLayer + OnResponse, post-match
let probes = Router::new().route("/healthz", get(healthz)); // + /readyz
Router::new()
    .merge(probes)
    .merge(api)
    .layer(ServiceBuilder::new()          // top-to-bottom = outer-to-inner
        .layer(SetRequestIdLayer::new(id.clone(), MakeRequestUuid))
        .layer(PropagateRequestIdLayer::new(id))
        .layer(security_headers())        // four SetResponseHeaderLayer::overriding
        .layer(cors_layer)                // R76 (stub until decided)
        .layer(rate_limit_layer)          // R74 (stub until decided)
        .layer(idempotency_layer))        // R73 (stub until decided)
```

Executable acceptance check (executed in miniature; full form planned):
the `/tmp/r75probe` test `stack.rs` composes axum 0.8.9 +
tower-http 0.7.1 exactly as above (one header, `Merge` split,
`route_layer` TraceLayer with a counting `OnResponse`) and asserts:
incoming id preserved and echoed; generated id is a valid UUID v4;
security header present on 200, probe 200, and 404; exactly one access
event across the three requests (probe and 404 excluded). Result: 1
passed on stable 1.98.1, macOS arm64, offline build, 2026-09-26. The
full check (four headers, `http_request` event field assertions via a
`tracing` test subscriber, CORS-preflight and 429 header assertions
once R76/R74 land) is planned, not run — see `Validation strategy`.

No `BASELINE-REVIEW:` finding: the recorded baseline for F317–F321/F327
is the py behavior this answer preserves at the declared levels, and no
row needs reclassification.

### Recommendation

One stack: `tower-http` 0.7.1 (features `request-id`, `trace`,
`set-header`) + `tower` 0.5.3 (`ServiceBuilder`, promoted from R69's
dev-dependency to an optional `web` dependency) + `tracing` 0.1.44 (event
vocabulary; the subscriber stays R58's) over R69's axum 0.8.9 / tokio
1.53.1. `uuid` 1.26.1 arrives transitively via `tower-http/request-id`
(`v4`); no direct `uuid` dependency. The five members below are all
facets of this one stack: three ready-made layer pairs, one ordering
contract, one no-double-logging configuration. No member needs a bespoke
`tower::Service` implementation; template code is the header value
table, the `OnResponse`/`MakeSpan` callbacks, and the composition root.

### Members

#### request-id-propagation

##### Landscape

Concern: preserve-or-generate request id (F318), bind it for logging,
echo it on the response. Candidates from the three-bin map:
`tower-http` `request_id` module (established; `SetRequestIdLayer`,
`PropagateRequestIdLayer`, `MakeRequestId` trait, `MakeRequestUuid`),
hand-rolled `from_fn` middleware (pattern alternative), `uuid` direct
use inside bespoke code (same generation, none of the plumbing).
`tower-http` 0.7.1 figures (crates.io API, 2026-09-26): 478,643,150
all-time downloads, 156,288,393 recent (90-day); newest non-yanked
0.7.1 released 2026-08-31T14:49:25Z; MIT; declared `rust-version`
1.65. GitHub `tower-rs/tower-http` (`gh api`, 2026-09-26): 918 stars,
not archived, pushed 2026-09-26T12:33:00Z; 32 open issues (search API
`total_count`). Recent-issue sample (10 most recent, `gh api`
2026-09-26): 5 with zero comments, newest 2026-09-25; first-maintainer-
response median not computed (gap). Advisories
(`https://rustsec.org/packages/tower-http.html`, 2026-09-26):
RUSTSEC-2022-0043 (ServeDir Windows path validation, patched
`>=0.2.1`, windows-only) and withdrawn RUSTSEC-2021-0135 — no open
advisory at 0.7.1.

##### Principles and implementation

P1 (capability + wire value): incoming `x-request-id` preserved,
else UUID v4 generated; id present in log context and echoed on the
response, including on early returns. `SetRequestId` implements the
preserve-or-generate branch exactly like py (`request_id.rs:105-113`:
incoming header wins and is mirrored into extensions; else
`make_request_id` runs and both header and extension are set), and
`PropagateRequestId` echoes it (`request_id.rs:420-466`). The
hyphenated-vs-hex rendering difference is justified under P1 (both
UUID v4; echo preserves the wire form). Generation cost is one
`Uuid::new_v4` (CSPRNG fill) per id-less request — negligible next to
request handling; no benchmark run, no absolute claim.

##### Dominant choice

`tower-http` 0.7.1 `request-id` feature: `SetRequestIdLayer::new` +
`PropagateRequestIdLayer::new` with `MakeRequestUuid`, `x-request-id`
header name. Requested as `tower-http = { version = "0.7.1", features
= ["request-id", ...] }`; the feature pulls optional `uuid ^1`
(`v4`) and nothing else (`tower-http-0.7.1/Cargo.toml:226`).

##### Qualified shortlist

`tower-http` 0.6.11 (`request-id` also present, same API): a
like-for-like downgrade kept only if R76 or another consumer forces
0.6 unification — nothing currently does (axum/axum-core couple to
`tower-http` 0.6 only via `__private_docs`/dev-deps, verified in
vendored manifests). Hand-rolled `MakeRequestId` (e.g. ULID or
counter): same layer machinery, different generator; rejected as the
default because UUID v4 is P1's shared value.

##### Excluded by gate

None. The `request_id` alternatives considered fail on fit or
freshness, never on a fitness gate; every gate below is answered for
the dominant choice instead.

##### Up-and-comers

None in-crate: request-id generation outside `uuid` (e.g. `ulid`)
changes only the generator behind the same `MakeRequestId` trait and
buys nothing for P1. Not shortlisted.

##### Fit for this template

Exact: the module is `http` 1.x / `tower` 0.5 native (same majors as
axum 0.8.9), has no runtime coupling (pure header/extension
plumbing), and its `ServiceBuilderExt::{set_x_request_id,
propagate_x_request_id}` conveniences match R69's `ServiceBuilder`
test idiom. Fitness gates for `tower-http` 0.7.1: (1) MIT,
compatible. (2) Declared `rust-version` 1.65, inside the
stable-minus-two floor (R69 probes ran at declared 1.96). (3) No
open RustSec advisory at 0.7.1 (above); `unsafe` posture:
unverified from source in this leg (`.crate` bodies not inspected) —
gap for synthesis. (4) CI/OS: tower-rs runs ubuntu/macos/windows CI
per repo badges — unverified from this sandbox (GitHub web beyond
the API is out of scope); rust-version floor plus pure-Rust
header/extension code make OS-specific failure unlikely, recorded
as a residual check, not evidence. (5) Default features: `tower-http`
`default = []` (verified feature map; every module opt-in);
`request-id` adds only `uuid/v4`; no tokio coupling. (6)
Compile/binary cost: one small module plus `uuid`; qualitative: low.

##### Recommendation

`tower-http` 0.7.1, `request-id` feature, `SetRequestIdLayer` outside
`PropagateRequestIdLayer`, `x-request-id`, `MakeRequestUuid`.

##### Ranked runner-up

`tower-http` 0.6.11 with the identical configuration: same API, same
modules, older line. Loses on freshness (0.7.1 current since
2026-08-31, 0.6.11 superseded) with no compensating unification —
nothing in the default tree pins 0.6.

##### Tradeoffs

`uuid` enters the tree (transitive, `v4` + `getrandom`): small,
unavoidable for P1's shared UUID value, and already depended on by
`tower-http` 0.7.1 itself (revdep evidence). Hyphenated rendering
differs cosmetically from py's hex; regexes anchored to 32 hex chars
in cross-repo tooling would need the shared 36-char form — a
follow-on note for the py/ts alignment project, not this template.

##### Parameters

`assumes web-extra-surface` per R69's owned value (axum 0.8.9
optional, default features); no new parameter owned or consumed by
this member. No `CONFLICT:` line.

##### Migration implications

`Cargo.toml`: `tower-http = { version = "0.7.1", optional = true,
features = ["request-id", ...] }` under `web = [...,
"dep:tower-http", ...]`. `src/web/middleware.rs`: the two-layer pair
(nowhere else — one composition root). No CLI/library impact.

##### Validation strategy

Executed (miniature, `/tmp/r75probe`, stable 1.98.1, macOS arm64,
2026-09-26): incoming id echoed verbatim; generated id parses as
UUID v4; pair inversion (Propagate outside Set) demonstrably breaks
the echo and the contract order fixes it. Planned (full): incoming
`x-request-id` with mixed case preserved byte-for-byte; id present
in the `RequestId` extension for the access-log span; echo present
on CORS preflight and 429 once R76/R74 land.

##### Confidence & re-verify trigger

High. Re-verify if `tower-http` 0.8 changes the `request_id` module
or if R76/R74 force a 0.6-series unification.

##### Sources

crates.io API `tower-http` + `/versions` + `/0.7.1` feature map +
`/0.7.1/dependencies` (2026-09-26); `gh api repos/tower-rs/tower-http`
and `search/issues` (2026-09-26); rustsec.org `tower-http` package
page + RUSTSEC-2022-0043 advisory page (2026-09-26);
`tower-http-0.7.1/src/request_id.rs` (vendored); `/tmp/r75probe`
executed test (2026-09-26, probe kept outside the repo per runbook
scratch rules).

#### structured-access-log

##### Landscape

Concern: one canonical structured access event per handled request
with route template, status, duration, request id (F319), excluding
probes (F320). Candidates: `tower-http` `TraceLayer` with custom
`OnResponse`/`MakeSpan` (established; `trace` feature pulls
`tracing` + `http-body`), hand-written `tower` layer (pattern
alternative), `axum::middleware::from_fn` logging closure (pattern
alternative). `TraceLayer` hook surface verified in vendored source
(`trace/layer.rs`, `trace/on_response.rs:14-26`,
`trace/make_span.rs:11`, `trace/on_request.rs:12`): `on_response`
receives response + latency + span — exactly the F319 callback
shape. No path-filter knob exists anywhere in the `trace` module
(verified file list), forcing the exclusion decision to the router.
`tracing` 0.1.44 figures (crates.io API, 2026-09-26): 876,776,724
all-time, 200,225,369 recent; newest non-yanked 0.1.44 released
2025-12-18 (0.1.42 yanked); MIT; rust-version 1.65.0. GitHub
`tokio-rs/tracing`: 6,891 stars, not archived, pushed 2026-05-30;
628 open issues across the whole workspace (tracing,
tracing-subscriber, appender, mock). Recent-issue sample: 5 of 10
with zero comments; response median a gap. Advisory
RUSTSEC-2023-0078 (`Instrumented::into_inner` unsoundness) patched
`>=0.1.40` — clear at 0.1.44.

##### Principles and implementation

P2 (pattern + event shape) + P3 (policy): the event is emitted by a
custom `OnResponse` as `tracing::info!` with fields
`http_request`-equivalent (`route`, `status`, `duration_ms`,
`request_id`), inside a span built by a custom `MakeSpan` that
records the request id from the `RequestId` extension (available
because the access layer sits inside slot 1). Route template comes
from axum's `MatchedPath` (`axum-0.8.9/src/extract/matched_path.rs:
57`), which exists only after the route matches — hence the layer
applies as `route_layer` on the non-probe router, and hence P3's
route-level opt-out and P2's 404/preflight differences (argued in
`Principles and implementation`). MEDIUM questions answered:
tracing-integrated layer with custom callbacks (not hand-written);
exclusion by route-level opt-out (not a denylist parameter).

##### Dominant choice

`TraceLayer::new_for_http()` with template-owned `MakeSpan` (adds
`request_id` from extensions) and `OnResponse` (emits the single
`http_request` INFO event; `OnFailure` for the error path),
applied via `route_layer` to the API router only.

##### Qualified shortlist

Hand-written layer emitting the same event: full control over the
404/preflight edge (could log `route=None` like py), at the cost of
re-implementing span lifecycle `TraceLayer` already gets right.
Kept as the fallback if synthesis rejects the P2 differences.

##### Excluded by gate

None; gates answered for the dominant choice under `Fit`.

##### Up-and-comers

`tower-http` `metrics` module (a `TraceLayer`-adjacent recorder):
observes the same hooks for counters, not events — complementary
to R79, not an access-log replacement. Not shortlisted.

##### Fit for this template

Exact: `trace` feature adds only `tracing` (default-features off)
and `http-body`, both already in R69's tree shape; events flow into
R58's pipeline with no second sink. Gates for `tracing` 0.1.44:
(1) MIT. (2) rust-version 1.65.0, inside the floor. (3) No open
advisory (RUSTSEC-2023-0078 patched below 0.1.44); `unsafe`
unverified from source — gap. (4) OS CI unverified from sandbox
(same residual as above); `tracing` core is platform-agnostic.
(5) `tracing` default features retained (`std`, attributes off
unless needed); no runtime coupling. (6) Cost: one span + one event
per handled request; qualitative: low, and cheaper than py's
per-request structlog rendering it replaces.

##### Recommendation

`TraceLayer` + custom `MakeSpan`/`OnResponse` as `route_layer` on
the non-probe router; probes merged without it.

##### Ranked runner-up

Hand-written access-log layer with `route=None` fallback for
unmatched requests: wins exact py parity, loses on code owned and
on duplicating `TraceLayer`'s tested span lifecycle. Adopt only if
the P2 differences are rejected at synthesis.

##### Tradeoffs

Unmatched 404s and CORS preflights emit no access event (justified
under P2; metrics cover 404-scan visibility). `MatchedPath`
dependence ties the route field to axum routing — acceptable: R69
settled axum, and the fallback if routing ever changes is the
runner-up layer.

##### Parameters

`assumes logging-pipeline-contract` = pending (R58 unresolved; this
member assumes a `tracing`-subscriber pipeline with an INFO-visible
`http_request`-shaped event and per-front-end level profiles).
`assumes web-extra-surface` per R69. No `CONFLICT:` line.

##### Migration implications

`Cargo.toml`: `trace` added to the `tower-http` feature list;
`tracing = "0.1"` optional under `web`. `src/web/middleware.rs`:
`access_log_layer()` returning the configured `TraceLayer`;
`src/web/router.rs` (`build_router`): API/probe router split with
`route_layer` on the API side. R58's subscriber work is untouched
except the assumed event visibility.

##### Validation strategy

Executed (miniature, `/tmp/r75probe`, 2026-09-26): counting
`OnResponse` fired exactly once across an API 200, a probe 200, and
a 404 — proving single-event semantics and both exclusions.
Planned (full): `tracing` test-subscriber capture asserting one
`http_request` event with `route="/items"`, `status=200`,
`duration_ms>=0`, `request_id` equal to the echoed header; 429 and
replay responses still produce exactly one event each; default
axum/hyper/tower targets produce zero per-request lines
(`RUST_LOG=debug` negative assertion for P6).

##### Confidence & re-verify trigger

High on mechanism, medium on the P2 differences (a synthesis-level
call). Re-verify if R58's pipeline cannot render arbitrary event
fields, or if axum changes `MatchedPath`/ `route_layer` semantics.

##### Sources

crates.io API `tracing` + `/versions` (2026-09-26); `gh api
repos/tokio-rs/tracing` + `search/issues` (2026-09-26); rustsec.org
`tracing` + RUSTSEC-2023-0078 (2026-09-26);
`tower-http-0.7.1/src/trace/*.rs`, `axum-0.8.9/src/extract/
matched_path.rs`, `axum-0.8.9/src/docs/routing/route_layer.md`
(vendored); `/tmp/r75probe` executed test (2026-09-26).

#### security-response-headers

##### Landscape

Concern: stamp the four P4 headers unconditionally (F321). Candidates:
four `tower-http` `SetResponseHeaderLayer::overriding` layers
(established; `set-header` feature, zero extra dependencies),
`tower-helmet` 0.3.0 (up-and-comer; helmet-style bundle),
hand-rolled layer (pattern alternative). `tower-helmet` figures
(crates.io API, 2026-09-26): 29,225 all-time,
1,700 recent; newest non-yanked 0.3.0 released 2024-01-29; MIT; no
declared `rust-version`; deps `http ^1`, `tower-layer ^0.3`,
`tower-service ^0.3`, `futures`, `pin-project-lite`, `lazy_static`
(so http-1.x compatible). GitHub `atrox/tower-helmet`: 5 stars, not
archived, pushed 2025-11-24; 0 open issues. Rustsec: 404, no
advisories recorded. Maintenance: at-risk (no release in 32 months
— past the investigate trigger — plus single maintainer, 5 stars,
and undeclared MSRV against a policy that requires declared
`rust-version`).

##### Principles and implementation

P4 (standard): the exact four header values are the agreement; the
stamping mechanism is free. `SetResponseHeaderLayer::overriding`
sets unconditionally (verified constructors at
`set_header/response/single_header.rs:42-57`), matching py's
unconditional dict application including HSTS-over-http-in-dev. Four
instances compose in the `ServiceBuilder` with no bespoke code
beyond the value table. `tower-helmet` instead bundles its own
opinionated set (CSP builder etc.): more policy surface than F321
asks for, weaker maintenance, and its values would need auditing
against P4 line by line.

##### Dominant choice

Four `SetResponseHeaderLayer::overriding` layers with the P4 value
table, in slot 3 of the ordering contract.

##### Qualified shortlist

`tower-helmet` 0.3.0: the only published helmet-style crate found
(`axum-secure-headers`, `secure-headers`, and `helmet` do not exist
on crates.io — HTTP 404, 2026-09-26). Kept shortlisted rather than
excluded: it passes every gate it can be evaluated against, but
loses decisively on maintenance and on policy-surface fit.

##### Excluded by gate

None. (`tower-helmet`'s undeclared MSRV is unverifiable, not failed;
it loses on fit, recorded under `Ranked runner-up`.)

##### Up-and-comers

`tower-helmet` itself is the up-and-comer bin (above). No other
security-header crate surfaced in the map.

##### Fit for this template

Exact: `set-header` adds zero dependencies beyond
`tower-http` core (`Cargo.toml` feature is `[]`), no runtime
coupling, and the value table lives in template code where the
template's security review can see it. Gates reuse the
`tower-http` 0.7.1 answers (MIT; rust 1.65; no open advisory;
default-features empty; low cost) — no new crate enters the tree
for this member.

##### Recommendation

`SetResponseHeaderLayer::overriding` × 4 with the P4 table.

##### Ranked runner-up

`tower-helmet` 0.3.0: wins fewer lines of template code, loses on
at-risk maintenance (32 months stale, 5 stars, undeclared MSRV),
on unneeded policy surface (CSP etc. beyond F321), and on-values
audit burden. Revisit only if it gains active maintenance and a
declared `rust-version`.

##### Tradeoffs

Template owns four repetitive layer constructions (~12 lines) —
deliberate: the values are the audited artifact, and hiding them
behind a bundle crate would move the audit target without removing
it.

##### Parameters

None owned or consumed by this member beyond the stack-wide
`assumes web-extra-surface` (R69). No `CONFLICT:` line.

##### Migration implications

`Cargo.toml`: `set-header` added to the `tower-http` feature list.
`src/web/middleware.rs`: `security_headers()` returning the
composed layer (or the four layers inlined in the `ServiceBuilder`).
Security review reads the value table there.

##### Validation strategy

Executed (miniature, `/tmp/r75probe`, 2026-09-26):
`x-content-type-options: nosniff` asserted present on API 200,
probe 200, and 404 via `if_not_present` (proving slot-3
composition); `overriding` constructor verified present in source
but not executed — gap closed by the planned check. Planned
(full): all four P4 values asserted byte-for-byte on 200, 404,
CORS preflight, and 429; handler-set conflicting header
overridden (proving `overriding`, not `if_not_present`).

##### Confidence & re-verify trigger

High. Re-verify if the owner's header set changes (R76/R70 may add
values) or if a maintained helmet-style crate displaces the
hand table.

##### Sources

crates.io API `tower-helmet` + `/versions` +
`/0.3.0/dependencies` + 404 probes for `axum-secure-headers`,
`secure-headers`, `helmet` (2026-09-26); `gh api
repos/atrox/tower-helmet` + `search/issues` (2026-09-26);
rustsec.org `tower-helmet` 404 (2026-09-26);
`tower-http-0.7.1/src/set_header/response/single_header.rs`
(vendored); `/tmp/r75probe` executed test (2026-09-26).

#### layer-ordering-contract

##### Landscape

Concern: the defined outermost-to-innermost composition order with
id/security-header layers outermost (F317), stated unambiguously for
the winning composition model. This member is a composition rule, not
a crate: crate figures are inapplicable (no new dependency; the
machinery is `tower` 0.5.3 + axum's `Router::layer`, both already in
the R69 tree shape). `tower` 0.5.3 figures for the record (crates.io
API, 2026-09-26): 687,424,955 all-time, 180,236,988 recent; newest
non-yanked 0.5.3 released 2026-01-12; MIT; rust-version 1.64.0.
GitHub `tower-rs/tower`: 4,302 stars, not archived, pushed
2026-06-22; 69 open issues. Recent-issue sample: 6 of 10 with zero
comments; response median a gap. Rustsec: 404, no advisories
recorded. Maintenance: stable-quiet (0.5.x mature; no release in 8
months is the investigate trigger, answered by continued pushes,
massive adoption, and no open advisory).

##### Principles and implementation

P5 (architectural pattern): slots 1–7 as stated in `Principles and
implementation`, with R76/R74/R73 behavior items filling slots 4–6.
The ambiguity the HIGH question names is resolved by stating the
contract outermost-to-innermost and pinning both spellings:
`ServiceBuilder` top-to-bottom (`tower-0.5.3/src/builder/mod.rs:
126-132`; axum's guide recommends `ServiceBuilder` for multiple
middleware) and `Router::layer` bottom-to-top (axum onion diagram,
`src/docs/middleware.md:61-115`, same convention as Starlette's
`add_middleware`). The Set-outside-Propagate pair order is part of
the contract, proved by the executed probe (inversion drops
generated-id echo because capture reads request headers at call
time, `request_id.rs:420-426`).

##### Dominant choice

One `ServiceBuilder` in `build_router` listing slots 1–6 top-to-
bottom (code reads in contract order), plus the `route_layer`
access log (slot 7) on the API router.

##### Qualified shortlist

Chained `Router::layer` in reverse (innermost first): identical
runtime stack, harder to read against the contract, easier to get
wrong when R76/R74/R73 slots fill in. The probe used this spelling
successfully; kept as the fallback if `ServiceBuilder` type
complexity ever bites (it does not here — all layers are
`Clone + Send + Sync + 'static`).

##### Excluded by gate

Inapplicable: no candidate crate; nothing evaluated against the
crate gates.

##### Up-and-comers

None: composition models are settled (`tower` traits); novelty here
would be a different framework, which R69 foreclosed.

##### Fit for this template

Exact: uses only R69's settled machinery. Gates: inapplicable as a
crate member (no new dependency); the underlying `tower` 0.5.3 is
MIT, rust 1.64.0, advisory-free, and already accepted by R69 as a
dev-dependency — this member promotes it to an optional `web`
dependency for `ServiceBuilder` with no version change.

##### Recommendation

The slot 1–7 contract with the `ServiceBuilder` spelling.

##### Ranked runner-up

`Router::layer` chains: same stack, weaker readability of the
contract. Loses on reviewability only.

##### Tradeoffs

`ServiceBuilder` nesting produces long generic types in error
messages — a known tower ergonomic cost, mitigated by building the
stack in one commented function. No runtime cost either way
(monomorphized layers).

##### Parameters

None owned or consumed beyond stack-wide `assumes
web-extra-surface` (R69). No `CONFLICT:` line. Note for R76/R74/R73:
their layers must be `Layer<Route> + Clone + Send + Sync + 'static`
with infallible-into responses to sit in slots 4–6 — a constraint
on their designs, recorded here, not a conflict.

##### Migration implications

`Cargo.toml`: `tower = { version = "0.5.3", optional = true,
features = ["util"] }` promoted from dev-dependency to
`web`-gated dependency (keep the dev entry R69 added; cargo
unifies). `src/web/router.rs`: the single `ServiceBuilder`
composition with slot comments. No other files.

##### Validation strategy

Executed (miniature, `/tmp/r75probe`, 2026-09-26): slot-1–3
headers present on 200, probe 200, and fallback 404, proving
outermost placement wraps the fallback router too. Planned (full):
CORS preflight and forced-429 responses carry `x-request-id` and
all four P4 headers (F317's core assertion); layer-order
regression test fails if any slot is reordered (each layer stamps
a marker extension in a test-only build and the test asserts
marker order).

##### Confidence & re-verify trigger

High. Re-verify when R76/R74/R73 fill slots 4–6 (their layer types
must satisfy the bounds above) or if axum changes layer-wrapping
semantics.

##### Sources

`tower-0.5.3/src/builder/mod.rs` (vendored); axum 0.8.9
`src/docs/middleware.md` ordering section (vendored); crates.io API
`tower` + `/versions` (2026-09-26); `gh api repos/tower-rs/tower` +
`search/issues` (2026-09-26); rustsec.org `tower` 404 (2026-09-26);
`/tmp/r75probe` executed test (2026-09-26).

#### framework-log-fold-in

##### Landscape

Concern: the framework/server's own logs folded into the shared
`tracing` pipeline instead of double-logging (F327). This member is
a configuration finding, not a crate: crate figures are
inapplicable (no new dependency; the subscriber is R58's). Finding:
axum 0.8.9's server emits no per-request log lines — verified by
absence (no `tracing::info!`/`tracing::debug!`/`log::info!` in
`axum-0.8.9/src/serve/`, 2026-09-26), so there is no Rust analogue
of uvicorn's access logger to silence. `hyper` 1.x is likewise
quiet below `debug`/`trace` by construction (its protocol logging
goes through `tracing` spans at verbose levels; no per-request line
at default levels). `tracing-subscriber` 0.3.23 figures for the
record (crates.io API, 2026-09-26): 626,845,618 all-time,
147,886,240 recent; newest non-yanked 0.3.23 released 2026-03-13
(0.3.21 yanked); MIT; rust-version 1.65.0. Advisory
RUSTSEC-2025-0055 (ANSI escape injection via user input in logs)
patched `>=0.3.20` — clear at 0.3.23. GitHub signal shared with
`tokio-rs/tracing` (6,891 stars; 628 workspace-wide open issues).

##### Principles and implementation

P6 (policy): exactly one request line per handled request, emitted
by slot 7 into R58's pipeline; server lifecycle/framework lines
structured like every other event. Because the framework side
emits nothing at default levels, the fold-in has three parts, all
configuration: (a) do not add any framework access logger (there
is none to enable — the negative finding above); (b) route every
template layer through `tracing` (slots 1–3, 7 emit nothing except
slot 7's one event; `tower`/`tower-http` emit no per-request lines
at INFO); (c) R58's `EnvFilter` profile keeps `hyper`, `tower`,
and `axum` targets at INFO-or-quieter so a future verbose default
or a debug session cannot resurrect double lines. Part (c) is
R58's to own (profile side of the same integration point; F263's
ledger note splits it); this member states the web side's
requirement on that profile. MEDIUM question answered: no
silencing step keyed to the framework exists under R69's axum
choice; had R69 picked a chatty server, this member would have
owned its redirect.

##### Dominant choice

Emit-nothing + `EnvFilter` requirement: no framework logger
configured, slot-7 event as the only request line, and an R58
profile constraint (`hyper`/`tower`/`axum` at INFO max in the
structured profile, DEBUG visible only in the console profile).

##### Qualified shortlist

Explicit `tracing::dispatcher` per-request capture test as the
enforcement mechanism (a test, not a design alternative): kept as
the validation approach below rather than a design fork. No rival
design shortlisted — any alternative would add a line this member
exists to avoid.

##### Excluded by gate

Inapplicable: no candidate crate.

##### Up-and-comers

None.

##### Fit for this template

Exact: zero dependencies, zero code; the finding removes work
(the uvicorn-handler-clearing step has no Rust translation). Gates
for `tracing-subscriber` 0.3.23 (R58's crate, cited for the shared
record): (1) MIT. (2) rust-version 1.65.0, inside the floor. (3)
No open advisory (RUSTSEC-2025-0055 patched below 0.3.23). (4)–(6)
deferred to R58, which owns the subscriber selection.

##### Recommendation

Emit-nothing + the `EnvFilter` profile requirement on R58.

##### Ranked runner-up

None — no rival design; the only alternative is adding a
framework access line, which contradicts F327 outright.

##### Tradeoffs

A future axum/hyper/tower release could add default-level
per-request logging, silently reintroducing double lines. The
mitigation is the negative test in `Validation strategy` (fails
closed on any second line), plus the re-verify trigger below.

##### Parameters

`assumes logging-pipeline-contract` = pending (R58 unresolved;
required profile behavior stated above — if R58's contract cannot
express per-target levels, that raises `CONFLICT: R58
logging-pipeline-contract — per-target EnvFilter levels — F327
needs hyper/tower/axum capped`; no conflict raised today because
R58 is open, not decided-against). `assumes web-extra-surface`
per R69. No `CONFLICT:` line.

##### Migration implications

No template files for the finding itself. One test file gains the
negative test (`tests/web/access_log.rs`, see below). R58's
subscriber profile must record the per-target level requirement
when it lands — a cross-item note, not an edit by this item.

##### Validation strategy

Planned (not executed — needs R58's subscriber): with the
production subscriber active, drive one API request and assert the
captured stdout/stderr contains exactly one `http_request` event
and zero lines from `hyper`/`tower`/`axum` targets at INFO; repeat
with `RUST_LOG=debug` asserting still exactly one `http_request`
event (verbose framework lines permitted, second request lines
forbidden). Residual: hyper's below-default logging claim rests on
general hyper 1.x knowledge, not a vendored-source read in this
leg — the negative test closes it empirically at synthesis.

##### Confidence & re-verify trigger

Medium-high: the axum negative finding is verified in vendored
source; hyper's rests on the planned negative test. Re-verify on
every axum/hyper/tower minor bump (the negative test runs in CI)
and when R58's contract lands (confirm the profile requirement is
expressible).

##### Sources

`axum-0.8.9/src/serve/` (vendored, absence verified 2026-09-26);
crates.io API `tracing-subscriber` + `/versions` (2026-09-26);
rustsec.org `tracing-subscriber` + RUSTSEC-2025-0055 (2026-09-26);
R69 `DECISION.md` (axum default features incl. `tower-log`).

### Compatibility

Proof the members are tested together:

- Version matrix (all mutually compatible majors, verified in
  vendored manifests and the crates.io dependency endpoints,
  2026-09-26): axum 0.8.9 (`http ^1`, `tower ^0.5.2`, `tracing
  ^0.1` optional) + `tower-http` 0.7.1 (`http ^1`, `tower ^0.5`
  optional, `tracing ^0.1` optional default-off, `uuid ^1` optional
  `v4`) + `tower` 0.5.3 + `tracing` 0.1.44 + `uuid` 1.26.1 (via
  `request-id`) + tokio 1.53.1 (R69). One `http` 1.x, one `tower`
  0.5, one `tower-http` 0.7 in the tree — no duplication, because
  neither axum nor axum-core enables its `tower-http` 0.6
  dependency under default features (both gate it behind
  `__private_docs`; verified in vendored `Cargo.toml` files).
- Shared adopter: axum's own documentation applies `tower_http`
  layers (`TimeoutLayer`, `ValidateRequestHeaderLayer`,
  `TraceLayer` in examples) directly to `Router` — the framework
  and the middleware crate are developed and doc-tested together
  under tokio-rs/tower-rs stewardship.
- Executed composition: `/tmp/r75probe` builds axum 0.8.9 +
  `tower` 0.5.3 + `tower-http` 0.7.1 + `tracing` 0.1.44 offline and
  its test passes (stable 1.98.1, macOS arm64, 2026-09-26),
  composing slots 1–3 and 7 exactly as recommended. The Linux leg
  (`ubuntu-latest`) belongs to the template's CI (R11), as in R69.

### Parameters

- `assumes logging-pipeline-contract` = pending — R58 unresolved
  at research time; assumed: a `tracing`-subscriber pipeline that
  renders arbitrary INFO event fields and supports per-target
  level profiles (`EnvFilter`-shaped). If R58 cannot express
  per-target levels, F327 needs the conflict noted in the
  `framework-log-fold-in` member; no conflict raised today.
- `assumes web-extra-surface` = per R69's accepted owned value
  (one additive off-by-default `web` feature; axum 0.8.9 optional
  with default features; tokio 1.53.1 optional with
  `rt-multi-thread, net, signal, macros, time, sync`; `tower`
  0.5.3 currently dev-only, promoted by this item to an optional
  `web` dependency at the same version).
- Owns: none — this item owns no registry parameter.
- No `CONFLICT:` line.

### Migration implications

Template file changes (all under the `web` feature unless noted):

- `Cargo.toml`: `tower-http = { version = "0.7.1", optional =
  true, features = ["request-id", "trace", "set-header"] }`;
  `tower = { version = "0.5.3", optional = true, features =
  ["util"] }` (promoted from R69's dev-only entry; keep that entry
  — cargo unifies); `tracing = { version = "0.1", optional = true
  }`; extend R69's `web = ["dep:axum", "dep:tokio", ...]` with
  `"dep:tower-http"`, `"dep:tower"`, `"dep:tracing"`. (`uuid` stays
  transitive; `tracing-subscriber` stays R58's.)
- `src/web/middleware.rs` (new): `request_id_layers()` (the
  Set-outside-Propagate pair), `security_headers()` (four
  `overriding` layers), `access_log_layer()` (configured
  `TraceLayer`), each constructor documented with its slot number.
- `src/web/router.rs` (`build_router`, R69's constructor): the
  API/probe router split, `route_layer(access_log_layer())` on the
  API side, and the single `ServiceBuilder` with slots 1–6
  (R76/R74/R73 layers stubbed with `tower::layer::Identity`-style
  pass-throughs or `Option<Layer>` until those items land).
- `tests/web/middleware_stack.rs` (new, `web`-gated): header
  presence on 200/probe/404/preflight/429, single-`http_request`
  event capture, probe/404 exclusion, ordering regression markers,
  and the P6 negative test.
- No CLI, library-core, or CI changes beyond R69/R11's shape.

### Validation strategy

Commands proving the principle in a realistic example with the
recommended libraries (axum 0.8.9 + tower-http 0.7.1 + tower 0.5.3
+ tracing 0.1.44; `cargo test --features web` in the template):

1. `cargo build --offline` of the stack — executed in miniature
   (`/tmp/r75probe`, stable 1.98.1, 2026-09-26): compiles clean.
2. `oneshot` header assertions — executed in miniature: incoming
   id echoed, generated id parses as UUID v4, security header on
   200/probe/404, exactly one access event. Planned (full): all
   four P4 values byte-for-byte; `overriding` beats handler-set
   values; preflight + 429 carry id and all four headers.
3. `tracing` test-subscriber capture — planned: exactly one
   `http_request` event per handled request with `route` (template,
   never raw path), `status`, `duration_ms`, `request_id` matching
   the echoed header; 429/replay/500 paths each yield exactly one.
4. Negative P6 test — planned: zero per-request lines from
   `axum`/`hyper`/`tower` targets at INFO and at `RUST_LOG=debug`
   (one `http_request` event in both modes).
5. Ordering regression — planned: test-only marker extensions per
   slot asserting outermost-to-innermost order; fails on reorder.

Expected behavior: `cargo test --features web middleware_stack`
green; `RUST_LOG=debug` run shows framework chatter but still one
request event. Executed vs planned is marked per item above; the
full suite needs R58's subscriber and R76/R74/R73's layers.

### Confidence & re-verify trigger

Overall confidence: high on the stack selection (first-party
parts, settled majors, executed composition), medium on the two
P2 differences (a synthesis-level call with a documented
fallback). Re-verify: (a) when R58's contract lands — confirm
event-field rendering and per-target levels, else raise the noted
conflict; (b) when R76/R74/R73 fill slots 4–6 — confirm layer
bounds and preflight/429 header assertions; (c) on any
axum/hyper/tower/tower-http minor bump — rerun the negative P6
test; (d) if `tower-http` 0.8 or a maintained helmet crate
appears — reassess the runner-ups; (e) the Linux CI leg (R11)
covers `ubuntu-latest`, unexecuted here.

### Sources

Endpoints and artifacts (all retrieved/read 2026-09-26):

- `GET https://crates.io/api/v1/crates/tower-http`,
  `/tower-http/versions`, `/tower-http/0.7.1`,
  `/tower-http/0.6.11`, `/tower-http/0.7.1/dependencies`,
  `/tower-http/reverse_dependencies`,
  `/tower`, `/tower/versions`, `/tracing`, `/tracing/versions`,
  `/tracing-subscriber`, `/tracing-subscriber/versions`,
  `/uuid`, `/uuid/versions`, `/tower-helmet`,
  `/tower-helmet/versions`, `/tower-helmet/0.3.0/dependencies`,
  `/axum/0.8.9`, `/axum/0.8.9/dependencies`,
  `/axum-core`, `/axum-core/0.5.5/dependencies`, and 404 probes
  for `/axum-secure-headers`, `/secure-headers`, `/helmet`.
- `gh api repos/tower-rs/tower-http`, `repos/tower-rs/tower`,
  `repos/tokio-rs/tracing`, `repos/uuid-rs/uuid`,
  `repos/atrox/tower-helmet`, and `search/issues` open-issue
  counts + 10-most-recent samples for each.
- `https://rustsec.org/packages/{tower-http,tower,tracing,
  tracing-subscriber,uuid,tower-helmet}.html` and
  `/advisories/{RUSTSEC-2022-0043,RUSTSEC-2023-0078,
  RUSTSEC-2025-0055}.html`.
- Vendored sources: `tower-http-0.7.1` (`request_id.rs`,
  `trace/*.rs`, `set_header/response/single_header.rs`,
  `Cargo.toml`), `tower-http-0.6.11` (API comparison),
  `tower-0.5.3` (`builder/mod.rs`), `axum-0.8.9`
  (`docs/middleware.md`, `docs/routing/route_layer.md`,
  `extract/matched_path.rs`, `serve/`, `Cargo.toml`),
  `axum-core-0.5.6` (`Cargo.toml`).
- `/Users/stevemorin/c/py-launch-blueprint/src/py_launch_blueprint/
  web/{middleware.py,app.py,logging.py}` (precedent).
- R69 `research/topics/69-web-framework-stack/DECISION.md`
  (accepted framework choice).
- Executed probe `/tmp/r75probe` (crate + `tests/stack.rs`, 1
  passed, stable 1.98.1, macOS arm64, offline, 2026-09-26) — kept
  outside the repo as runbook scratch, available for re-run.


