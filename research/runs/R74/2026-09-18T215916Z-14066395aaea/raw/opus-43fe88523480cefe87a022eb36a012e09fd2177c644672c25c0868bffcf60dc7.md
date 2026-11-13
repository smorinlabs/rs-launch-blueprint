# R74 — rate-limiting middleware (bundle) — Opus raw report

### Landscape

**Category this item decides.** Per-client HTTP request admission control for the
optional `web` surface: a middleware that, when one configuration value is set,
rejects requests above a declared quota with `429 Too Many Requests` and an
accurate `Retry-After`, keeping its counters in this process's memory. Three
separable decisions live inside it — the *layer mechanism* (how the check is
attached to the router), the *algorithm* (what "above quota" means and what the
wait until the next admission is), and the *store* (where per-key state lives
and how it is bounded). They are the three members below.

**The three-bin map of the Rust field.** Every shortlisted candidate comes from
this map. Figures are from the endpoints listed in `### Sources`; all crates.io
and GitHub figures were retrieved 2026-09-18 unless a different date is given.

*Bin 1 — built-in or first-party toolchain.*

| Candidate | What it is | Why it is in this bin |
|---|---|---|
| `axum::middleware::from_fn_with_state` | axum 0.8.9's own function-to-`Layer` adapter | ships in `axum`, the framework R69 selected; tokio-rs org |
| `axum::extract::ConnectInfo<SocketAddr>` + `Router::into_make_service_with_connect_info` | axum 0.8.9's peer-address plumbing | same crate |
| `tower::limit::RateLimitLayer` (`tower` 0.5.3, feature `limit`) | tower-rs' own rate limiter | tower-rs org, the `Service` ecosystem's root crate; already in the non-dev tree through `axum` |
| `tower::limit::ConcurrencyLimitLayer` | in-flight cap, not a rate | same |
| `std::time::Instant` + `std::collections::HashMap` + `std::sync::Mutex` | the language's own clock, map and lock | Rust standard library |

*Bin 2 — established industry standard.*

| Candidate | 90-day dl | All-time dl | Newest non-yanked | Stars | Reverse deps |
|---|---|---|---|---|---|
| `governor` 0.10.4 | 15,807,822 | 77,790,474 | 0.10.4 (2025-12-16) | 938 | 483 |
| `tower_governor` 0.8.0 | 1,719,980 | 4,678,756 | 0.8.0 (2025-08-14) | 351 | 81 |
| `ratelimit` 2.0.0 | 871,302 | 21,729,663 | 2.0.0 (2026-04-21) | 2 (repo recreated 2026-03-20) | not collected |
| `leaky-bucket` 1.1.2 | 507,563 | 2,633,391 | 1.1.2 (2024-05-22) | not collected | not collected |

*Bin 3 — up-and-comers.*

| Candidate | 90-day dl | All-time dl | Newest non-yanked | Stars | Reverse deps |
|---|---|---|---|---|---|
| `axum-governor` 2.1.0 | 12,646 | 19,927 | 2.1.0 (2026-09-05) | 25 | 0 |
| `tower-resilience-ratelimiter` 0.13.0 | 6,320 | 14,763 | 0.13.0 (2026-08-21) | 104 (family repo) | not collected |
| `gcra` 0.6.0 | 358,352 | 2,162,768 | 0.6.0 (2024-08-01) | 9 | 0 |
| `axum_gcra` 0.1.1 | 66 | 7,595 | 0.1.1 (2024-08-11) | not collected | 0 |

Discovery was a crates.io keyword sweep (`rate-limit`, `rate limit tower`,
`governor`, `throttle`, `axum rate`, `tower-resilience`, `sliding window rate`,
25 results each, sorted by downloads, `https://crates.io/api/v1/crates?q=…`,
2026-09-18), not recall. Framework-bound siblings found and set aside as
out-of-framework (`actix-governor` 0.10.0, `salvo-rate-limiter` 0.96.0,
`rocket-governor` 0.2.0-rc.4, `surf-governor` 0.2.0) are evidence that
`governor` is the ecosystem's shared engine: four separate framework
communities wrapped the same crate.

**Authorities used, and why each is authoritative.**

| Source | Why it counts |
|---|---|
| RFC 6585 §4 (`https://www.rfc-editor.org/rfc/rfc6585.txt`, 2026-09-18) | the IETF standard that defines status 429 and says a response "MAY include a Retry-After header indicating how long to wait" |
| RFC 9110 §10.2.3 (`https://www.rfc-editor.org/rfc/rfc9110.txt`, 2026-09-18) | the current HTTP Semantics standard; defines `Retry-After = HTTP-date / delay-seconds` and `delay-seconds = 1*DIGIT`, "a non-negative decimal integer" |
| `draft-ietf-httpapi-ratelimit-headers-11`, 23 May 2026, Standards Track, expires 24 November 2026 (`https://www.ietf.org/archive/id/draft-ietf-httpapi-ratelimit-headers-11.txt`, 2026-09-18) | IETF HTTPAPI working-group output; defines the `RateLimit` and `RateLimit-Policy` structured fields. Still a draft, not an RFC |
| crates.io API and each crate's published `Cargo.toml` as unpacked into `~/.cargo/registry/src/` | the registry's own metadata and the exact bytes Cargo compiles; the only authority for a declared `rust-version`, a `[features]` map or a licence |
| GitHub REST (`repos/…`, `search/issues`, `contents/…`), authenticated | maintenance state, issue responsiveness, and the manifest at `master` rather than at the last release |
| RustSec advisory database (`https://rustsec.org/packages/<name>.html`) | the Rust Secure Code WG's own advisory index |
| The maintainers' own source and doc comments (read, not paraphrased) | the only authority for what a crate actually emits |
| `boinkor-net/governor`'s GCRA reference — Stapleton-Cordas, *Understanding Generic Cell Rate Limiting*, cited by `gcra` 0.6.0's own source (`src/gcra.rs:17`) | the algorithm description both crates implement |

A single blog post was treated as a lead: the GCRA explainer is cited because a
shipped crate's source cites it, not on its own standing.

**Well-regarded projects surveyed, with the evidence that they are well
regarded.** For `governor`, its 483 crates.io reverse dependencies include
`alloy-transport` 2.4.2 (the Ethereum Rust SDK), `librespot-core` 0.8.0 (the
open Spotify client library), `sc-rpc-server` 32.1.0 (Substrate/Polkadot's RPC
server), and `foundations` 5.10.2 (Cloudflare's published service foundation
library) — four independently notable, actively published projects, each
depending on `governor` from its own `Cargo.toml` as listed at
`https://crates.io/api/v1/crates/governor/reverse_dependencies` (2026-09-18).
For `tower_governor`, its 81 reverse dependencies include `iroh-dns-server`
1.2.0 (n0-computer's iroh), `snarkos-node-rest` 4.10.0 and `leo-lang` 4.4.4
(Aleo), `miden-node-utils` 0.16.0 (Polygon Miden), `taxy` 0.3.40 and
`pkarr-relay` 2.0.1. `gcra`, `axum-governor` and `axum_gcra` each have **zero**
reverse dependencies (same endpoint, 2026-09-18) — no published crate depends on
any of them.

**One well-regarded template was surveyed for the pattern rather than the
crate.** `loco-rs/loco` 1.1.0 (106,998 90-day downloads, 655,734 all-time;
`https://crates.io/api/v1/crates/loco-rs`, 2026-09-18) is the most prominent
opinionated Rust web-application template. Its middleware directory
(`https://api.github.com/repos/loco-rs/loco/contents/src/controller/middleware`,
2026-09-18) contains `catch_panic`, `compression`, `cors`, `etag`, `fallback`, `format`,
`limit_payload`, `logger`, `powered_by`, `remote_ip`, `request_id`,
`secure_headers`, `static_assets`, `static_assets_embedded` and `timeout` —
**and no rate limiter at all**. Its `MiddlewareLayer` trait declares `fn is_enabled(&self) -> bool`
(`src/controller/middleware/mod.rs:46,55`) and each middleware struct carries an
`enable: bool` whose default is `false` for most of them (`:85,:108,:117,:125,
:132,:139`). That is the answer to the LOW question, and it cuts two ways: the
*config-gated, off-by-default middleware registration pattern* is a named,
published Rust template pattern, while *rate limiting itself* is not a Rust
template staple.

### Principles and implementation

**The shared requirement, its source and its agreement level.** py wires one
app-wide rate limit that is inert until a single settings value is set, keyed by
the caller's remote address, rejecting excess with 429 rendered through the same
problem-document envelope as every other error, carrying headers computed from
the limiter's own state rather than guessed, and holding its counters in this
process's memory with the distributed-store swap documented and not built. The
pinned source is exact: `src/py_launch_blueprint/web/settings.py:70` declares
`rate_limit: str | None = None` with the comment "Default rate limit, e.g.
`100/minute` (`limits` notation). None (the default) disables rate limiting
entirely (WEB-22)"; `src/py_launch_blueprint/web/app.py:143` reads
`if settings.rate_limit:` and only then calls `_install_rate_limiting`;
`app.py:220` builds `Limiter(key_func=get_remote_address,
default_limits=[default_limit], headers_enabled=True)` with **no** `storage_uri`,
so slowapi's in-memory backend is the store (F316); `app.py:230-241` renders the
rejection through the shared `problem_response(...)` and then calls
`limiter._inject_headers(response, request.state.view_rate_limit)` under the
comment "Accurate X-RateLimit-* + Retry-After computed from the limit window
(the same call slowapi's default handler makes) — never a guess." All read
through the pin: `git -C ~/c/py-launch-blueprint show b08bccfb:<path>`,
2026-09-18. ts has no web service (`docs/port/areas/web-service.md:100`), so
there is no second precedent to reconcile.

The **agreement level is a capability plus a policy**, not a library: *the
service can refuse excess traffic per caller, this capability is off unless one
configuration value turns it on, the refusal is a standards-conformant 429 whose
`Retry-After` is derived from limiter state, and the state is single-instance by
design with a named swap point.* Nothing about `slowapi`, `limits`, GCRA or
token buckets is part of the agreement. What may vary: the algorithm, the map
type, the header set beyond `Retry-After`, and whether the check is a `tower`
`Layer` or a function.

**Essential behaviours and observable acceptance criteria.**

| # | Behaviour | Observable criterion |
|---|---|---|
| B1 | Off by default | With the setting unset, unbounded request counts all return 200 and no limiter state exists |
| B2 | One value turns it on | Setting exactly one environment variable, with no recompilation, makes the same binary reject |
| B3 | Correct admission | With quota `N/period`, the first `N` requests from one key are admitted and the `N+1`-th is refused |
| B4 | Per-key isolation | A second key is unaffected by the first key's exhaustion |
| B5 | Standards-conformant refusal | Status is 429 and `Retry-After` is a non-negative decimal integer (RFC 9110 §10.2.3) |
| B6 | Accurate `Retry-After` | The value is derived from limiter state, never a constant, and never earlier than the true next admission |
| B7 | In-memory, bounded, single-instance | State lives in this process, cannot grow without bound, and the distributed swap point is a named type |
| B8 | One envelope | The refusal renders through the service's single error representation (R70's), not a second ad-hoc body |

**Architectural alternatives compared before libraries.**

*A1 — a `tower::Layer`/`Service` pair (what `tower_governor` is).* The check
happens in `Service::call` before the inner service is cloned into a future. It
composes with `ServiceBuilder` and is reusable outside axum (tonic, hyper). Cost:
the rejection must be built as a raw `http::Response`, because a `Service`'s
error type is not axum's `IntoResponse`. To render through R70's envelope the
layer needs a `fn(GovernorError) -> Response` handler that *calls* the envelope
function; the rejection is never a value of R70's error enum.

*A2 — `axum::middleware::from_fn_with_state`.* An `async fn(State, Request,
Next) -> Result<Response, E>` where `E: IntoResponse`. axum wraps it into a
`Layer`, so it sits in the same `.layer()` stack R75 orders, and it is
indistinguishable from A1 from the outside. Its decisive advantage here is the
return type: the rejection is a *value of the web member's own error type*, so
whatever `IntoResponse` R70 lands on renders it by construction, with no
response rewriting and no second code path.

*A3 — a per-handler extractor or a `tower::Layer` applied per route.* Rejected:
F323's precedent is app-wide (`default_limits`), and a per-route quota surface is
a feature nobody asked for.

*A4 — push the limit out of the process (a reverse proxy, an API gateway, Cloud
Armor).* This is the genuinely different architecture, and it is the right one
in production at scale, because a per-instance in-memory limiter enforces
`quota × instances`, not `quota`. It is rejected *for this item* for the same
reason py rejected it: a template must demonstrate the shape in the artefact it
ships, and the operator who fronts the service with a gateway simply leaves the
variable unset. It belongs in the documentation beside the swap point.

**Does the shared pattern remain appropriate in Rust?** Yes, with one
substitution. py's gate is a truthy settings value read at app-construction
time; Rust's equivalent is `Option<T>` and conditional registration.
`axum::Router::layer` consumes and returns `Router`, so
`match policy { None => router, Some(p) => router.layer(…) }` compiles with no
`Either`, no `option_layer` and no boxing — verified by a compiled, passing test
(`conditional_registration_is_the_gate`). The alternative, a Cargo feature, is
**rejected on principle**: a feature moves the gate to compile time, so the
shipped binary would no longer *contain* a limiter that one variable turns on,
which is the behaviour F323 records. R69's `web` feature already gates whether
the whole web tree exists; a second compile-time gate inside it buys nothing and
loses the property.

**Why the ecosystem's dominant stack is not the recommendation.** `governor`
0.10.4 and `tower_governor` 0.8.0 are the obvious answers by adoption, and the
owner's reference architecture names `tower_governor` 0.8.0 at row C11. Both
**fail fitness gate 2**: neither declares `rust-version` in its published
`Cargo.toml` (`governor-0.10.4/Cargo.toml` has `edition = "2018"` and no
`rust-version`; `tower_governor-0.8.0/Cargo.toml` has `edition = "2021"` and
none), and `governor`'s manifest at `master` still declares none
(`https://api.github.com/repos/boinkor-net/governor/contents/governor/Cargo.toml`,
2026-09-18), so this is not a lag between the release and the repository. The
owner withdrew the lenient reading of that gate — "an unknown version is
insufficient to clear a bar the prompt says must be cleared"
(`docs/planning/p02/owner-decisions.md`, "Two things you should know") — and R69
applied the strict reading to exclude `warp`, `viz`, `pavex` and `tide`
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1494-1497`)
while limiting it to *candidates* rather than every transitive crate (`:2266-2267`).
Applying the same rule here excludes both.

Two further, independently measured findings support the same conclusion, so the
recommendation does not rest on the gate alone.

*Measured defect 1 — the refusal is 1 second early.* `tower_governor` computes
`wait_time` as `NotUntil::wait_time_from(now).as_secs()`
(`tower_governor-0.8.0/src/lib.rs:125-127` and `:293-295`), which **truncates**.
A compiled probe with `per_second(30).burst_size(2)` observed the third request
returning `429` with `retry-after: 29` and `x-ratelimit-after: 29` where the
true wait is 29.99…s: a client that obeys the header retries inside the window
and is refused again. The header is present — correcting a widely repeated claim
that the crate emits only `x-ratelimit-after`; `src/lib.rs:144` and `:313` insert
`retry-after` too — but its value is systematically low by up to one second and
can be `0`.

*Measured defect 2 — the default key extractor 500s under this template's test
idiom.* `PeerIpKeyExtractor` reads `ConnectInfo<SocketAddr>` from the request
extensions (`src/key_extractor.rs:163-168`) and returns
`GovernorError::UnableToExtractKey`, whose response is **`500 Internal Server
Error`** (`src/errors.rs:57-63`), when it is absent. R69's accepted decision uses
`axum::serve(listener, app)` in `serve_until`
(`.../R69/…/review/DECISION.md:1106`), which installs no `ConnectInfo`, and
R69's accepted test idiom is `tower::ServiceExt::oneshot`, which also installs
none. A compiled probe confirmed both halves: without `ConnectInfo` the layer
returns 500; with it, 429.

*Maintenance.* `benwis/tower-governor` is **at-risk** by the rubric, on a
concrete signal rather than on the release gap alone: no release since
2025-08-14 and `pushed_at` 2025-08-14 (13 months), 19 open issues, and **zero
maintainer responses across the ten most recently opened issues** — five of
those ten have no comment at all, and the only comment on issue 54 is from a
`CONTRIBUTOR`, not the maintainer (`api.github.com/repos/benwis/tower-governor/…`,
2026-09-18). `boinkor-net/governor` is **active** by contrast (938 stars, pushed
2026-08-24, median 1 day to first maintainer response across the three of seven
recent issues a maintainer answered) — it is excluded by the gate, not by
neglect.

**What is left once the gates are applied, and why the template owns the
layer.** Every remaining crate candidate fails on evidence, not on taste:
`tower-resilience-ratelimiter` 0.13.0 is a single global limiter with no key
extraction and hard-codes `retry_after: None` (`src/error.rs:97,105,117`), and
its own doc says "Could return 429 Too Many Requests in HTTP context"
(`src/lib.rs:146`) — the HTTP part is the caller's; `gcra` 0.6.0 has the right
shape but zero reverse dependencies, nine stars, one author, no release since
2024-08-01, and pins `dashmap` 5.5.3 and `thiserror` 1.x, two and one majors
behind; `axum-governor` 2.1.0 is the most standards-complete option on the map
(it emits `retry-after`, the draft's `RateLimit` structured field, and legacy
`x-ratelimit-*`; `src/headers.rs:46,93-95,117,124`) but has zero reverse
dependencies, 25 stars, twelve releases in twelve months, and a declared
`rust-version` of `1.95` — one minor below the 1.96 floor, less headroom than
the two minors on which R69 excluded `salvo` for MSRV-policy fit
(`.../R69/…/DECISION.md:1492`); and `axum_gcra` 0.1.1 declares no `rust-version`
at all.

So the template owns the layer. The behaviour is small: GCRA's entire per-key
state is one `Instant`, and the decision is two comparisons. The probe
implementation — parser, port trait, in-memory store, header computation,
`IntoResponse`, middleware and the registration helper, with doc comments — is
**162 lines** of `src/lib.rs`, compiles under `cargo clippy --all-targets
-D warnings` with no warnings, and adds **zero crates**: the non-dev dependency
tree of the probe is byte-identical to R69's accepted `axum` 0.8.9 + `tokio`
1.53.1 baseline (51 `cargo tree -e normal` lines in both; `diff` empty). By
contrast `tower_governor` 0.8.0 with `default-features = false, features =
["axum"]` adds **37** crates (87 vs 50 third-party tree entries in `cargo tree -e normal`) and with its default
features — which include `tonic` — adds **49**, dragging a gRPC stack (`tonic`
0.14.6, `h2`, `hyper-timeout`, `tokio-stream`, `base64`, `async-trait`, and both
`thiserror` 1.x and 2.x) into a web template that has no gRPC.

**Production usage and maintained reference examples.** The recommended
mechanism is not novel: `axum::middleware::from_fn_with_state` is axum's own
documented middleware adapter, exercised by axum's own examples, and
`loco-rs/loco` 1.1.0 demonstrates the config-gated, off-by-default registration
discipline in a published template with 106,998 90-day downloads. The algorithm
is the same GCRA that `governor` (77.8M all-time downloads, 483 dependents) and
`gcra` implement; this design differs from them in packaging, not in arithmetic.
The evidence gap is honest and stated: **no maintained reference implementation
exists for this exact composition**, because the crates that would be it are the
ones the gate excludes. The mitigation is that the composition is executable and
was executed — eight tests, listed under `### Validation strategy`.

**Representative performance, with the workload stated.** Workload: 1,000,000
admit-path `check` calls in total, split evenly across N OS threads, quota set
so nothing is ever refused, keys drawn round-robin from a fixed set, release
profile, no eviction exercised, aggregate throughput only (no latency
distribution). Machine: Apple M4 Pro, 14 cores, 48 GiB, macOS 26.4, arm64.
Instrumentation: `std::time::Instant` around the joined threads.

| Threads | Distinct keys | Recommended store (`Mutex<HashMap>`) | `governor` 0.10.4 keyed (`DashMap`) |
|---|---|---|---|
| 1 | 1 | 14,706,360 ops/s (68.0 ns/op) | 27,127,993 ops/s (36.9 ns/op) |
| 1 | 10,000 | 9,165,311 ops/s (109.1 ns/op) | 17,013,566 ops/s (58.8 ns/op) |
| 8 | 1 | 14,385,014 ops/s (69.5 ns/op) | 7,804,464 ops/s (128.1 ns/op) |
| 8 | 10,000 | 6,223,916 ops/s (160.7 ns/op) | 15,721,859 ops/s (63.6 ns/op) |

`governor` is roughly twice as fast single-threaded and about 2.5× faster at
eight threads over many keys; the recommended store was faster at eight threads
over one key, which is reported as observed and not explained. The conclusion
that matters is that the worst measured figure, 160.7 ns per check, is under
0.02% of a 1 ms request, so neither option is a throughput consideration for
this template. This is a same-machine, same-harness comparison of one code path;
it is not a benchmark of the two crates as deployed.

**Minimal realistic example.** `crates/web/src/rate_limit.rs` holds
`RateLimitPolicy` (a `NonZeroU32` burst and a `Duration` period, parsed from
py's `limits` notation `"<count>/<period>"`), a `RateLimitStore` port, the
shipped `InMemoryRateLimitStore` (a `Mutex<HashMap<RateLimitKey, Instant>>` with
a capacity), `retry_after_seconds`, the `RateLimited` rejection type, the
`rate_limit` middleware function, and `install_rate_limit(router, policy,
capacity)`. `build_router` calls `install_rate_limit` once. The executable
acceptance check is the eight-test suite under `### Validation strategy`; six of
the eight assert this design's behaviour and two record `tower_governor`'s, and
all eight were run, not proposed.

**Owner reference architecture — agree/differ, row by row.** Eight rows of
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` are
touched: **3 differ, 3 agree, 2 hand-offs**.

| Row | The document says | This item |
|---|---|---|
| C11 Rate limiting (line 70) | "**tower_governor**", version 0.8.0, runner-up `axum-governor` "newer/less proven" | **Differ, on measured and sourced ground**: `tower_governor` 0.8.0 declares no `rust-version` and fails fitness gate 2 under the owner's settled strict reading; its `Retry-After` is truncated (observed `29` where the true wait is 29.99…s); its default key extractor returns 500 under R69's `axum::serve` and `oneshot` paths; its maintainer has not pushed or answered an issue in 13 months. The runner-up assessment of `axum-governor` is confirmed for a different reason — zero reverse dependencies and a 1.95 MSRV with one minor of headroom |
| Shared core list (line 31) | "tower_governor 0.8" in the shared core | **Differ**, same ground |
| `Cargo.toml` block (line 185) | `tower_governor = "0.8.0"` | **Differ**, same ground; nothing is added to `crates/web`'s manifest |
| Agent gotcha (line 415) | "Build one `Arc<GovernorConfig>` and reuse; per-request construction creates independent limiters" | **Agree on the principle.** One limiter instance is built at router construction and shared by every request; `install_rate_limit` constructs the store once and moves it into the layer's state, so per-request construction is not expressible |
| Layer-order note (line 114) | rate limiting placed within the tower-http order | **Hand-off to R75** with constraints, below; this item does not decide the order |
| C4 Error contract (line 54) | "thiserror + custom AppError (RFC 9457)"; "most such crates unmaintained; hand-roll" | **Agree as a hand-off to R70.** The design's rejection is a value that R70's `IntoResponse` renders; the reasoning that carried C4 — the maintained option does not exist, so own the small type — is the same reasoning that carries this item |
| C12 Testing (line 72) | axum-test 18 preferred over `tower::ServiceExt::oneshot` | **Agree with R69's settled `oneshot` choice** and note that the `ConnectInfo` trap applies to both idioms: whichever harness is used must insert `ConnectInfo` to exercise per-key behaviour |
| `tower 0.5` in the shared core (line 140) | `tower = "0.5"` as a runtime dependency | **Agree, and it is already true**: `cargo metadata` shows `axum` 0.8.9 requiring `tower ^0.5.2` with `default-features = false, features = ["util"]` as a **normal** dependency, so `tower` 0.5.3 is in `crates/web`'s runtime tree through axum regardless. R69's "dev-dependency only" is about the *direct* declaration, and this recommendation adds no direct `tower` dependency and no crate to the tree |

**No `BASELINE-REVIEW:` finding is raised.** F316 and F323 record a principle
this design preserves exactly — wired, off by default, one variable, in-memory,
single-instance by design, accurate `Retry-After`. The departure is in the
library used to realise it, which is a `DIVERGENT` row's whole purpose, not a
challenge to the baseline.

**One ledger observation is handed to R75 rather than filed as a finding.**
F317's ledger note reads "middleware ordering is a contract (id/security-header
middleware outermost)" and cites `app.py:145 — app.add_middleware(SecurityHeadersMiddleware)`
"added last (outermost)". At the pin, `app.py:146` adds `RequestIDMiddleware`
*after* it, and Starlette's last `add_middleware` is the outermost, so the actual
outermost layer is the request-id middleware, not the security-header one. The
row belongs to R75; this is reported so R75 can check it, not changed here.

### Recommendation

Adopt a rate-limiting middleware that `rs-launch-blueprint` owns, composed of
three members and adding **no new crate** to `crates/web`: the layer mechanism is
`axum::middleware::from_fn_with_state` from the `axum` 0.8.9 R69 already selected,
keyed by `axum::extract::ConnectInfo<SocketAddr>`; the algorithm is GCRA over
`std::time::Instant`, whose whole per-key state is one theoretical-arrival-time
instant and which yields the exact next-admission instant that `Retry-After` is
the ceiling of; and the store is a capacity-bounded
`std::sync::Mutex<HashMap<RateLimitKey, Instant>>` behind a `RateLimitStore`
trait that is the named swap point for a distributed store. The whole capability
is gated by one optional setting — R77 names the variable, this item fixes its
grammar as py's `limits` notation, `"<count>/<period>"` — read once at router
construction, with the layer simply not registered when it is unset.
`tower_governor` 0.8.0 and `governor` 0.10.4, the ecosystem's dominant pair and
the owner reference's C11 pick, are excluded by fitness gate 2 and, independently,
by a measured one-second-early `Retry-After`, a 500 on the template's own serve
and test paths, and a 13-month-silent maintainer.

### Members

Three members: the layer mechanism (a crate member), the algorithm (a pattern
member) and the store (a pattern member). The two pattern members state
`inapplicable` against every crate-only figure, with the reason, rather than
omitting it.

#### axum 0.8.9 — `middleware::from_fn_with_state` with `extract::ConnectInfo<SocketAddr>`

##### Landscape

The layer-mechanism category: how the admission check is attached to the router
and how it obtains the caller's identity. Bin 1 (built-in/first-party):
`axum::middleware::from_fn` and `from_fn_with_state`, `axum::middleware::from_extractor`,
a hand-written `tower::Layer` + `tower::Service` pair, and `tower::limit::RateLimitLayer`
from `tower` 0.5.3 (already in the non-dev tree through axum). Bin 2 (established
standard): `tower_governor::GovernorLayer` 0.8.0 — the only widely adopted
purpose-built HTTP rate-limit layer in Rust, 1,719,980 90-day downloads and 81
reverse dependencies. Bin 3 (up-and-comers): `axum_governor::GovernorLayer`
(crate `axum-governor` 2.1.0, 12,646 90-day downloads, 0 reverse dependencies),
`axum_gcra`'s `RateLimitLayer` 0.1.1 (66 90-day downloads), and
`tower_resilience_ratelimiter::RateLimiterLayer` 0.13.0 (6,320 90-day downloads).
Authorities: axum's own published API and R69's accepted decision selecting axum
0.8.9 for `crates/web`; the crates' own source as unpacked in
`~/.cargo/registry/src/`; the GitHub REST endpoints named in `### Sources`.
Well-regarded projects surveyed for this member: the four `governor` dependents
named in the item-level `### Landscape` and, for `tower_governor`,
`iroh-dns-server` 1.2.0 and `snarkos-node-rest` 4.10.0 — all verified from the
crates.io reverse-dependencies endpoint, 2026-09-18.

##### Principles and implementation

The principle is that the rejection must be expressible in the same currency as
every other error the service produces, so that F305's "single envelope for
every non-2xx response" is preserved without a second rendering path. A
`tower::Service`'s response type is `http::Response<B>`, so a `Layer`-based
limiter can only *build a response*; an axum middleware function returning
`Result<Response, E> where E: IntoResponse` can *return an error value*. That
difference decides the member: with `from_fn_with_state` the 429 is a
`RateLimited` value, and whichever `IntoResponse` R70 lands on renders it, with
the rate-limit code owning only the `Retry-After` value. `from_fn_with_state`
also carries the shared limiter through axum's `State`, which is exactly the
owner reference's "build one and reuse" instruction (line 415) made
unexpressible-otherwise: the store is constructed once, in `install_rate_limit`,
and moved into the layer. The key comes from
`req.extensions().get::<ConnectInfo<SocketAddr>>()`, which is py's
`get_remote_address` (`app.py:220`) in Rust. Observable criteria: B1–B5 and B8
in the item-level table. Executed: a compiled probe returns 200, 200, 429 for a
`2/minute` quota and 200 for every one of 1,000 requests with the layer absent.

##### Dominant choice

`tower_governor::GovernorLayer` 0.8.0 is the dominant choice by adoption for a
purpose-built HTTP rate-limit layer: 1,719,980 90-day and 4,678,756 all-time
downloads (`https://crates.io/api/v1/crates/tower_governor`, 2026-09-18), 81
reverse dependencies including `iroh-dns-server` 1.2.0, `snarkos-node-rest`
4.10.0, `leo-lang` 4.4.4, `miden-node-utils` 0.16.0, `taxy` 0.3.40 and
`pkarr-relay` 2.0.1, 351 stars. It is the owner reference architecture's C11
pick. It is excluded below.

For the mechanism *within* the framework this template uses, the dominant choice
is `axum`'s own `middleware::from_fn_with_state`: 118,234,751 90-day and
475,506,585 all-time downloads for `axum` 0.8.9
(`https://crates.io/api/v1/crates/axum` and `/versions`, 2026-09-18), 8,598
reverse dependencies, 27,100 stars, `pushed_at` 2026-09-11, `archived: false`,
34 open issues, issue responsiveness median 0.41 days with 5 of 10 unanswered
over the window 2026-06-16 → 2026-09-07 (stars, push, issue and responsiveness
figures collected by R69 revision 10 on 2026-09-18 and cited rather than
re-collected; the download figures above are this run's own). Licence MIT,
declared `rust-version` 1.80. No RustSec advisory page exists for `axum`.
Maintenance: **active** (tokio-rs organisation, pushed within 7 days).

##### Qualified shortlist

1. `axum::middleware::from_fn_with_state` (axum 0.8.9) — passes every gate;
   recommended.
2. A hand-written `tower::Layer` + `tower::Service` pair over `tower` 0.5.3
   (MIT, `rust-version` 1.64.0, 174,797,631 90-day downloads,
   `https://crates.io/api/v1/crates/tower`, 2026-09-18) — passes every gate.
   Rejected on fit: it is strictly more code (a `poll_ready`/`call` pair, a
   pinned response future and a `Clone` dance) for a mechanism that must still
   build the rejection as a raw response rather than return R70's error type.
3. `axum::middleware::from_extractor` — passes every gate; rejected on fit
   because an extractor cannot see `Next` and therefore cannot be composed into
   the single ordered stack R75 owns.
4. `axum_governor::GovernorLayer` (crate `axum-governor` 2.1.0) — passes gates 1
   and 3, passes gate 2 on the letter (declared `rust-version` 1.95); see
   *Up-and-comers*.

##### Excluded by gate

| Candidate | Gate | Evidence |
|---|---|---|
| `tower_governor` 0.8.0 | **Gate 2** — MSRV | The published manifest declares `edition = "2021"` and **no `rust-version`** (`~/.cargo/registry/src/index.crates.io-…/tower_governor-0.8.0/Cargo.toml`, read 2026-09-18). Under the owner's settled strict reading (`docs/planning/p02/owner-decisions.md`) and R69's application of it (`…/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1494-1497`), an undeclared version fails. Gate 1 passes (`MIT OR Apache-2.0`); gate 3 passes (no RustSec page: `https://rustsec.org/packages/tower_governor.html` returns HTTP 404, 2026-09-18) |
| `axum_gcra` 0.1.1 | **Gate 2** — MSRV | No `rust_version` on the newest non-yanked version (`https://crates.io/api/v1/crates/axum_gcra/versions`, 2026-09-18). Also dormant on its own: released 2024-08-11, 66 90-day downloads, 0 reverse dependencies |
| `tower::limit::RateLimitLayer` (`tower` 0.5.3) | no gate failed | Excluded on **fit**, recorded here for completeness: it is a single global limiter with no key, and it applies back-pressure by delaying `poll_ready` rather than refusing, so it can produce neither a 429 nor a `Retry-After`. It cannot express B3, B4, B5 or B6 |
| `tower_resilience_ratelimiter::RateLimiterLayer` 0.13.0 | no gate failed | Passes gates 1 (`MIT OR Apache-2.0`) and 2 (`rust-version` 1.85.0) and 3 (no RustSec page). Excluded on **fit**: one global limiter per layer with no key extraction, and its error carries `retry_after: None` unconditionally (`src/error.rs:97,105,117`); its own documentation says a 429 "Could" be returned "in HTTP context" (`src/lib.rs:146`), i.e. by the caller. Cannot express B4 or B6 |

##### Up-and-comers

`axum-governor` 2.1.0 (canmi21) is the most interesting thing on this map and
the closest to a complete answer. It is `edition = "2024"`, `rust-version =
"1.95"`, MIT, released 2026-09-05, repo created 2025-09-03, 25 stars,
`pushed_at` 2026-09-08, `archived: false`, 0 open issues, 12,646 90-day
downloads, 19,927 all-time. Its eighteen modules include `headers.rs`, which
emits `retry-after`, the `draft-ietf-httpapi-ratelimit-headers` **`RateLimit`
structured field** (`"default";r=0;t=5`, `src/headers.rs:46,124`),
`RateLimit-Policy`, and the legacy `x-ratelimit-limit/-remaining/-reset`
(`:93-95`); `response.rs`, which offers a `BodyPreset` including a
`type`/`title`/`status`-shaped JSON body; and `gc.rs` for map eviction. It is
the only candidate on the whole map that implements the IETF draft.

It is not recommended, on three grounds. Its declared `rust-version` of 1.95 sits
**one** minor below the 1.96 floor; R69 excluded `salvo` for MSRV-policy fit at
**two** minors of headroom on the reasoning that "a project tracking the compiler
that closely can push a patch release past the floor between the template's minor
releases" (`…/R69/…/DECISION.md:1492`), and this is a strictly weaker position.
It has **zero** crates.io reverse dependencies and 25 stars, so there is no
practice evidence at all. And it depends on `governor`, the crate gate 2
excludes, so adopting it would place the excluded engine in the tree while
satisfying the gate on the wrapper — a distinction with no engineering substance,
which is stated rather than relied on. `tower-resilience` 0.13.0 (104 stars,
`pushed_at` 2026-09-13, 0 open issues, every recent issue opened and closed by
the maintainer himself) is a healthy young family but, as shown above, its
rate-limiter member is the wrong shape.

##### Fit for this template

The template is CLI + library + web service, where the web service is an
optional Cargo feature (R69's `web-extra-surface`) and the rate limiter is one
of roughly eight layers R75 will order. Three properties decide fit. First, the
mechanism must not add a crate to a feature whose whole selling point is that it
costs nothing when off — `from_fn_with_state` adds none, `tower_governor` adds
37 with `tonic` off and 49 with its defaults. Second, the rejection must render
through R70's single envelope; only the `Result<Response, E>` form does that by
construction. Third, it must work under R69's accepted `axum::serve(listener,
app)` and `tower::ServiceExt::oneshot` paths; `tower_governor`'s default key
extractor returns **500** under both unless `ConnectInfo` is installed, which
was observed, not inferred. Against py's precedent the fit is exact:
`from_fn_with_state` + `ConnectInfo` is `SlowAPIMiddleware` +
`get_remote_address`, and the conditional registration is `if settings.rate_limit:`
(`app.py:143`). Against ts there is nothing to fit — ts has no web service.

##### Recommendation

Use `axum::middleware::from_fn_with_state(state, rate_limit)` inside
`install_rate_limit`, with `RateLimitState(Arc<dyn RateLimitStore>)` as the
state. Take the key from `ConnectInfo<SocketAddr>` when present. When it is
absent, fall back to a single `RateLimitKey::Global` bucket **and warn exactly
once** through `std::sync::Once`, so the degradation is loud rather than silent;
failing closed with a 500 was considered and rejected, because a limiter that
turns a configuration slip into a total outage is worse than one that
over-restricts while saying so. This makes a hard requirement of R69's serve
path: when rate limiting can be enabled, `serve_until` must call
`axum::serve(listener, app.into_make_service_with_connect_info::<SocketAddr>())`
rather than `axum::serve(listener, app)` as written at `…/R69/…/DECISION.md:1106`.
That is a hand-off, not a `CONFLICT:` — R69's owned `web-extra-surface` value
names `serve_until` but fixes none of its arguments.

##### Ranked runner-up

1. `tower::Layer` + `tower::Service` written by hand over `tower` 0.5.3
   (already in the tree, MIT, `rust-version` 1.64.0). Take this if the limiter
   ever has to be reused outside axum. Cost: roughly triple the code and the
   loss of the `IntoResponse` composition with R70.
2. `tower_governor` 0.8.0 with `default-features = false, features = ["axum"]`,
   `use_headers()`, an `error_handler` that rebuilds the response through R70's
   envelope, a `Retry-After` recomputed as a ceiling, and a custom
   `KeyExtractor` that does not 500 when `ConnectInfo` is missing. Take this
   only if the owner waives gate 2. At that point four of the crate's behaviours
   are being overridden, and 37 crates are being added for the remainder.

##### Tradeoffs

Gained: zero added dependencies; the rejection is R70's error type; the
mechanism is axum's own documented API, so nothing here can be orphaned
independently of the framework R69 already bet on. Given up: the ecosystem's
network effects — bug reports, blog posts and agent training data all describe
`tower_governor`, so a contributor's first instinct will be a crate this
template does not use, which must be answered in a comment at the call site.
Also given up: reuse outside axum, since `from_fn_with_state` is axum-specific.
Risk accepted: the template owns the middleware's correctness, mitigated by the
six executed tests and by the smallness of the surface (162 lines including the
algorithm and store members).

##### Parameters

This member owns no parameter. It consumes `web-extra-surface` (the layer is a
module inside the gated web tree), `msrv-policy`, `rust-edition`,
`target-os-matrix` and `license`; the exact registry bytes are in the item-level
`### Parameters`. No `CONFLICT:` line.

##### Migration implications

`crates/web/src/rate_limit.rs` gains the middleware function and
`install_rate_limit`; `crates/web/src/lib.rs` gains `mod rate_limit;`;
`crates/web/src/…`'s `build_router` gains one `install_rate_limit(router,
settings.rate_limit, settings.rate_limit_capacity)` call; `crates/web`'s
`serve_until` changes its `axum::serve` argument to
`app.into_make_service_with_connect_info::<SocketAddr>()`; `crates/web/Cargo.toml`
gains `tracing = { version = "0.1.44", default-features = false, features =
["std"] }` for the warn-once, which adds **zero** packages to the resolved tree
(verified: `cargo tree -e normal` output identical with and without it once
default features are off). No other file and no new dependency.

##### Validation strategy

Executed on this machine, `cargo test` against axum 0.8.9 + tokio 1.53.1:
`off_by_default_is_the_absence_of_the_layer` (1,000 requests, all 200),
`conditional_registration_is_the_gate` (same call site, 50×200 with `None`;
200 then 429 with `Some("1/minute")`),
`third_request_is_429_with_an_accurate_retry_after`, and the two
`tower_governor` observation tests
(`without_connect_info_the_default_key_extractor_returns_500`,
`with_connect_info_the_third_request_is_429_and_carries_retry_after`). Planned
for P03, not run here: a test asserting that the rendered 429 body is R70's
envelope, which cannot be written until R70 publishes; and a test asserting the
serve path installs `ConnectInfo`, which needs a real listener rather than
`oneshot`.

##### Confidence & re-verify trigger

High on the mechanism, because it was compiled and exercised rather than read.
Medium-high on the exclusion of `tower_governor`, because it rests on a gate
reading rather than on a defect that cannot be worked around — though the two
measured defects are independent corroboration. Re-verify when `tower_governor`
or `governor` publishes a release declaring `rust-version` within the floor;
when axum publishes 0.9 (`middleware::from_fn_with_state` is stable API but the
`axum-serve` extraction discussed at `…/R69/…/DECISION.md:1067` moves the serve
call this member constrains); when R69 republishes; when R70 publishes its
error type; when R75 publishes the layer order; at the next `msrv-policy` floor
advance past 1.96; or by 2027-03-18, whichever comes first.

##### Sources

`https://crates.io/api/v1/crates/axum` and `/versions` (2026-09-18);
`https://crates.io/api/v1/crates/tower_governor`, `/versions` and
`/reverse_dependencies` (2026-09-18); `https://crates.io/api/v1/crates/axum-governor`
and `/versions` (2026-09-18); `https://crates.io/api/v1/crates/axum_gcra` and
`/versions` (2026-09-18); `https://crates.io/api/v1/crates/tower` and `/versions`
(2026-09-18); `https://crates.io/api/v1/crates/tower-resilience-ratelimiter` and
`/versions` (2026-09-18); `https://api.github.com/repos/benwis/tower-governor`,
`https://api.github.com/search/issues?q=repo:benwis/tower-governor+is:issue+is:open`,
`https://api.github.com/repos/benwis/tower-governor/issues` and
`/issues/{65,64,63,59,58,57,55,54,52,50}/comments` (2026-09-18);
`https://api.github.com/repos/canmi21/axum-governor` (2026-09-18);
`https://api.github.com/repos/joshrotenberg/tower-resilience` (2026-09-18);
`https://rustsec.org/packages/tower_governor.html` (HTTP 404, 2026-09-18);
unpacked crate sources under `~/.cargo/registry/src/index.crates.io-…/` for
`tower_governor-0.8.0` (`Cargo.toml`, `src/lib.rs`, `src/errors.rs`,
`src/governor.rs`, `src/key_extractor.rs`), `axum-governor-2.1.0`
(`Cargo.toml`, `src/headers.rs`, `src/response.rs`) and
`tower-resilience-ratelimiter-0.13.0` (`src/error.rs`, `src/lib.rs`), all read
2026-09-18; R69 revision 10 at
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` lines
1067, 1106, 1285-1288, 1492-1497, 2266-2267, 2310, 1791; py at the pin,
`git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/web/app.py`
lines 143-147 and 209-243.

#### GCRA over `std::time::Instant` — the admission algorithm

##### Landscape

The algorithm category: what "over quota" means and what the wait until the next
admission is. This is a **pattern member**; the candidates are algorithms, and
the crates that implement them are named only as evidence. Bin 1 (built-in /
first-party): none — Rust's standard library ships no rate-limiting algorithm;
`tower::limit::RateLimitLayer` implements a fixed-window counter over
`tokio::time`, which is the closest first-party thing. Bin 2 (established
industry standard): **GCRA** (the Generic Cell Rate Algorithm, ITU-T I.371 /
ATM Forum, reused for HTTP rate limiting), implemented by `governor` 0.10.4
(15.8M 90-day downloads, 483 dependents) and `gcra` 0.6.0; **token bucket**,
implemented by `ratelimit` 2.0.0 (871,302 90-day downloads) and
`leaky-bucket` 1.1.2 (507,563); **fixed window**, implemented by
`tower::limit::RateLimitLayer`; **sliding window**, implemented by
`tower-resilience-ratelimiter` 0.13.0 (its `WindowType` enum). Bin 3
(up-and-comers): nothing algorithmically new — every recent crate on the map
reimplements one of these four. Authorities: ITU-T's algorithm as described in
the reference `gcra` 0.6.0's own source cites (`src/gcra.rs:17`,
`https://blog.ian.stapletoncordas.co/2018/12/understanding-generic-cell-rate-limiting.html`);
RFC 9110 §10.2.3 for what the computed wait must be rendered as; the crates'
own source. Well-regarded projects surveyed: `governor`'s GCRA is what
`foundations` 5.10.2 (Cloudflare), `alloy-transport` 2.4.2, `librespot-core`
0.8.0 and `sc-rpc-server` 32.1.0 use, which is the strongest available evidence
that GCRA is the ecosystem's settled choice for this problem.

##### Principles and implementation

The principle behind py's `headers_enabled=True` and its "never a guess" comment
(`app.py:218-219,239-241`) is that the refusal must carry the limiter's own
knowledge of when the next request will succeed. An algorithm therefore
qualifies only if it can answer "when", not merely "no". GCRA answers it
exactly. Its entire state is one theoretical arrival time `tat`; with emission
interval `T = period / burst` and tolerance `tau = (burst - 1) * T`, a request at
`now` is admitted when `max(tat, now) <= now + tau`, and when it is refused the
next admission is at exactly `max(tat, now) - tau`. Token bucket answers it too
but needs two fields (level and last-refill) and a division per check; fixed
window answers it only as "the end of the window", which over-states the wait for
every request except the last; sliding-window-log answers it exactly but stores
one timestamp per request rather than one per key, which is unbounded in the
wrong dimension. GCRA is also the only one of the four whose state is a single
`Copy` value, which is what makes the store member a plain `HashMap` rather than
a structure. Observable criteria: B3, B4 and B6. Executed: with `2/minute`,
`T = 30s`, `tau = 30s`, the third request is refused and the computed next
admission is `now + 30s`, asserted exactly.

##### Dominant choice

GCRA, on adoption of its implementations rather than on theory: `governor`
0.10.4 has 15,807,822 90-day and 77,790,474 all-time downloads and 483 reverse
dependencies (`https://crates.io/api/v1/crates/governor` and
`/reverse_dependencies`, 2026-09-18), against 871,302 90-day downloads for the
token-bucket `ratelimit` 2.0.0 and 507,563 for `leaky-bucket` 1.1.2. Four
separate web-framework communities wrapped `governor` rather than writing their
own (`tower_governor`, `actix-governor` 0.10.0, `rocket-governor` 0.2.0-rc.4,
`surf-governor` 0.2.0), which is the clearest signal available that GCRA is the
default answer in this ecosystem. `governor`'s repository is **active**: 938
stars, `pushed_at` 2026-08-24, `archived: false`, 24 open issues, and a median
of **1 day** to the first maintainer (`COLLABORATOR`) response across the three
of the seven most recently opened issues that a maintainer answered — four of
the seven are unanswered (`api.github.com/repos/boinkor-net/governor`,
`/search/issues`, `/issues/{299,298,285,275,274,273,272}/comments`, 2026-09-18).

##### Qualified shortlist

1. **GCRA** — exact next-admission instant, one `Instant` of state per key,
   no division on the hot path. Recommended.
2. **Token bucket** — equivalent behaviour, two fields of state, and a refill
   computation per check. Rejected on fit, narrowly: it is not worse, it is
   bigger, and the crates that implement it (`ratelimit` 2.0.0,
   `leaky-bucket` 1.1.2) are unkeyed single buckets, so adopting one would still
   leave the keyed map to this template.
3. **Sliding window counter** — smooths the window boundary at the cost of two
   counters per key and an approximation in the reported wait. Rejected: the
   extra fidelity is invisible at a template's quota granularity.
4. **Fixed window counter** — simplest, but the reported wait is the window end
   for every refused request, which violates B6. Rejected.
5. **Sliding window log** — exact, but O(quota) memory per key. Rejected
   against B7.

##### Excluded by gate

No algorithm is excluded by a gate; gates 1–6 are crate properties and this is a
pattern member. The crate figures are `inapplicable` here for that reason and
are reported against the crates that implement each algorithm instead, in
*Dominant choice* and in the item-level `### Landscape`. Recorded for
completeness: the two crates that would have supplied GCRA to this template are
excluded on the layer-mechanism and store members respectively — `governor`
0.10.4 by **gate 2** (its published `Cargo.toml` declares `edition = "2018"` and
no `rust-version`, and the manifest at `master` still declares none,
`https://api.github.com/repos/boinkor-net/governor/contents/governor/Cargo.toml`,
2026-09-18), and `gcra` 0.6.0 on practice evidence (see the store member).
Implementing the arithmetic directly carries no gate exposure at all.

##### Up-and-comers

None. Every crate released in the last twelve months on this map —
`axum-governor` 2.1.0, `tower-resilience-ratelimiter` 0.13.0, `ratelimit` 2.0.0
— implements GCRA, a token bucket or a window counter; `axum-governor` delegates
its arithmetic to `governor`'s GCRA outright. There is no new algorithm to
consider, which is itself the finding: this category is settled, and the
open questions are packaging questions.

##### Fit for this template

The template's quota is one app-wide policy in py's `N/period` grammar, keyed by
peer address, with an accurate `Retry-After` as the visible contract. GCRA
delivers exactly that contract with one `Instant` per key and two comparisons
per request, and its refusal carries the exact next-admission instant that
`Retry-After` is the ceiling of — which is strictly better than the incumbent:
`tower_governor` 0.8.0 truncates the same GCRA answer with `Duration::as_secs()`
(`src/lib.rs:125-127`), and the probe observed `retry-after: 29` for a true wait
of 29.99…s. Against py, note one thing that could not be verified: slowapi's
`_inject_headers` computation was not read, because slowapi is a dependency of
the pinned repository rather than a file in it, so whether py truncates or
rounds is **unverified**. The ceiling here is this template's choice, argued
from RFC 9110 §10.2.3 ("a non-negative decimal integer") plus the observation
that a value below the true wait produces a guaranteed second refusal.

##### Recommendation

Implement GCRA directly over `std::time::Instant`, in the shape the probe
compiled: `emission_interval = period / burst`, `tolerance = emission_interval *
(burst - 1)`, `tat = max(stored, now)`; refuse with next admission at
`tat - tolerance` when `tat > now + tolerance`, otherwise store `tat +
emission_interval` and admit. Render `Retry-After` as
`ceil((next_allowed_at - now))` in whole seconds, floored at 1, never 0.
Parse the policy from py's `limits` notation `"<count>/<period>"` with
`period ∈ {second|sec|s, minute|min|m, hour|hr|h, day|d}`, rejecting a zero
count through `NonZeroU32` and an unknown period explicitly.

##### Ranked runner-up

1. Token bucket over `std::time::Instant`, same store, same middleware. Choose
   it only if a future requirement needs variable-cost requests, where a bucket
   level is more natural than a single arrival time.
2. `gcra` 0.6.0's `GcraState::check_and_modify_at`, which is this exact
   arithmetic behind a crate boundary (MIT, `rust-version` 1.80.0). Choose it if
   the owner would rather import the arithmetic than own it; see the store
   member for why it is not the recommendation.

##### Tradeoffs

Gained: an exact next-admission instant, one `Copy` value of state per key, no
allocation and no division on the hot path, and full control of the
`Retry-After` rounding that the incumbent gets wrong. Given up: the reassurance
of an ITU-standard algorithm implemented by someone else — mitigated by the fact
that GCRA's correctness is checkable by inspection in six lines and is asserted
by three of the executed tests. Risk accepted: an off-by-one in `tolerance`
silently changes the burst size by one; the probe found exactly this mistake
(`tau = burst * T` admits `burst + 1`) and the `2/minute` test now pins it.

##### Parameters

This member owns no parameter and consumes only the four owner-fixed ones and
`web-extra-surface`, which the item-level `### Parameters` records byte-exactly.
No `CONFLICT:` line. It does fix one value that R77 will name but not define:
the grammar of the rate-limit environment variable is py's `limits` notation,
one string, because F323 records that **one** environment variable enables the
capability — exposing a burst integer and a period integer would be two.

##### Migration implications

All of it lands in `crates/web/src/rate_limit.rs`: `RateLimitPolicy` with its
`FromStr`, `emission_interval`, `tolerance`, and `retry_after_seconds`. No other
file changes and no dependency is added.

##### Validation strategy

Executed: `third_request_is_429_with_an_accurate_retry_after` asserts
`retry-after == 30` exactly for a `2/minute` quota — not a range, so a
rounding or tolerance regression fails; `retry_after_is_never_zero` asserts
1 ms → 1, 0 → 1, 1500 ms → 2; `policy_grammar_matches_py_limits_notation`
asserts `"100/minute"` parses to `(100, 60s)` and that `"100"`, `"0/minute"` and
`"100/fortnight"` are all errors; `keys_are_isolated_and_the_store_is_bounded`
asserts a second key is admitted after the first is exhausted. Planned, not run:
a property test over random `(burst, period, arrival sequence)` asserting that
admissions in any window never exceed `burst` and that a client obeying
`Retry-After` is never refused twice in a row.

##### Confidence & re-verify trigger

High. The arithmetic is closed-form, and the executed tests pin the burst size,
the exact `Retry-After` value and the parser's rejections. The one
acknowledged unknown is py's own rounding, which is unverified. Re-verify when
`draft-ietf-httpapi-ratelimit-headers` becomes an RFC (the `RateLimit`
structured field would then be worth emitting alongside `Retry-After`), when R70
publishes an envelope that carries structured retry metadata, or by 2027-03-18.

##### Sources

RFC 9110 §10.2.3 (`https://www.rfc-editor.org/rfc/rfc9110.txt`, 2026-09-18);
RFC 6585 §4 (`https://www.rfc-editor.org/rfc/rfc6585.txt`, 2026-09-18);
`draft-ietf-httpapi-ratelimit-headers-11`, 23 May 2026
(`https://www.ietf.org/archive/id/draft-ietf-httpapi-ratelimit-headers-11.txt`
and `https://datatracker.ietf.org/api/v1/doc/document/?name__startswith=draft-ietf-httpapi-ratelimit-headers`,
both 2026-09-18); `https://crates.io/api/v1/crates/governor`, `/versions` and
`/reverse_dependencies` (2026-09-18); `https://crates.io/api/v1/crates/ratelimit`,
`/leaky-bucket`, `/gcra` with `/versions` (2026-09-18);
`https://api.github.com/repos/boinkor-net/governor`,
`https://api.github.com/search/issues?q=repo:boinkor-net/governor+is:issue+is:open`,
`/issues` and `/issues/{299,298,285,275,274,273,272}/comments` (2026-09-18);
`https://api.github.com/repos/boinkor-net/governor/contents/governor/Cargo.toml`
(2026-09-18); unpacked sources `gcra-0.6.0/src/gcra.rs`,
`governor-0.10.4/Cargo.toml` and `tower_governor-0.8.0/src/lib.rs`, all read
2026-09-18.

#### `Mutex<HashMap<RateLimitKey, Instant>>` behind a `RateLimitStore` port — the store

##### Landscape

The store category: where per-key state lives, how concurrent requests reach it,
how it is bounded, and what the documented swap point to a distributed store is.
A **pattern member**. Bin 1 (built-in / first-party):
`std::sync::Mutex<std::collections::HashMap<K, V>>` and
`std::sync::RwLock<HashMap<K, V>>`. Bin 2 (established industry standard):
`dashmap` 6.2.1 (the sharded concurrent map `governor` uses under its `dashmap`
feature), and `governor`'s own `keyed` state store built on it; `moka` and
`quick_cache` as TTL/eviction caches. Bin 3 (up-and-comers): `gcra` 0.6.0's
`RateLimiter<T>` (a `dashmap` 5.5.3 map with a `max_data_capacity` and
`prune_expired()`), and `axum-governor` 2.1.0's `gc.rs` eviction task.
Authorities: the Rust standard library documentation; the crates' own source;
`tower_governor`'s own README pattern of spawning an interval task that calls
`limiter.retain_recent()`, which is the ecosystem's acknowledgement that the
`governor` keyed store is otherwise unbounded. Well-regarded projects surveyed:
the same `governor` dependents — `foundations` 5.10.2 (Cloudflare),
`alloy-transport` 2.4.2, `sc-rpc-server` 32.1.0 — all of which inherit the
`dashmap`-backed keyed store.

##### Principles and implementation

Two principles meet here. F316's is that the store is **in-memory and
single-instance by design**, with the distributed swap documented and not built
— py realises it by constructing `Limiter(...)` with no `storage_uri`
(`app.py:220`) and documenting the Redis swap point the same way the idempotency
store does (`idempotency.py:91`). The template's own R01 principle is that a
substitutable dependency is a trait erased at the composition root. Putting them
together makes the swap point a **type, not a comment**: `trait RateLimitStore {
fn check(&self, key: &RateLimitKey, now: Instant) -> Result<(), Instant>; }`,
with `InMemoryRateLimitStore` as the shipped implementation and the middleware
holding `Arc<dyn RateLimitStore>`. A Redis-backed implementation is then a new
type, not a rewrite of the middleware — which is exactly what "documented swap
point" should mean in a language with traits. The second principle is that an
in-memory keyed limiter must be **bounded**, because its key space is attacker-
controlled: the store therefore carries a capacity, evicts every cell whose
arrival time is already past when it is full, and if it is still full admits the
untracked request. Observable criteria: B4, B7, and the item-level requirement
that the swap point be named.

##### Dominant choice

`dashmap`-backed sharded maps, as used by `governor` 0.10.4 — 15,807,822 90-day
downloads, 483 reverse dependencies including Cloudflare's `foundations` 5.10.2
(`https://crates.io/api/v1/crates/governor/reverse_dependencies`, 2026-09-18).
`dashmap` 6.2.1 itself carries one RustSec advisory, RUSTSEC-2022-0002
("Unsoundness in `dashmap` references"), **patched in >= 5.1.0**
(`https://rustsec.org/advisories/RUSTSEC-2022-0002.html`, 2026-09-18), so
neither `governor`'s 6.2.1 nor `gcra`'s 5.5.3 is affected; gate 3 is satisfied
by both. The dominant choice is not adopted, because adopting it means adopting
`governor` or `gcra`, and both are excluded below.

##### Qualified shortlist

1. `std::sync::Mutex<HashMap<RateLimitKey, Instant>>` with a capacity, behind
   `RateLimitStore`. No crate, no gate exposure, bounded by construction.
   Recommended.
2. `dashmap` 6.2.1 directly, behind the same trait. Passes gates 1–3
   (`MIT`; `rust_version` declared; the one advisory patched well below the
   resolved version). Rejected on fit: it adds a crate and 4 transitive
   packages to buy sharding this template's measured throughput does not need,
   and it does not bound itself.
3. `std::sync::RwLock<HashMap<…>>`. Rejected on fit: every admission **writes**,
   so a read-write lock degenerates to a mutex with more overhead.
4. `gcra` 0.6.0's `RateLimiter<T>` (capacity-bounded, `prune_expired()`). Passes
   every gate. Rejected on practice evidence; see *Up-and-comers*.

##### Excluded by gate

| Candidate | Gate | Evidence |
|---|---|---|
| `governor` 0.10.4's keyed state store | **Gate 2** — MSRV | `governor-0.10.4/Cargo.toml` declares `edition = "2018"` and **no `rust-version`** (read from `~/.cargo/registry/src/…/governor-0.10.4/Cargo.toml`, 2026-09-18); the manifest at `master` declares none either (`https://api.github.com/repos/boinkor-net/governor/contents/governor/Cargo.toml`, 2026-09-18), so this is a standing property and not release lag. Gate 1 passes (MIT, compatible with `MIT OR Apache-2.0`); gate 3 passes (no RustSec page for `governor`: HTTP 404, 2026-09-18) |
| `axum_gcra` 0.1.1's store | **Gate 2** — MSRV | No `rust_version` on the newest non-yanked version (`https://crates.io/api/v1/crates/axum_gcra/versions`, 2026-09-18) |

Gate-by-gate for the recommendation itself: **gate 1** licence —
`inapplicable`, no crate is added, and the code is the template's own under
`MIT OR Apache-2.0`; **gate 2** MSRV — the feature uses no API newer than
`std::sync::Once`, `Duration::div` and `HashMap::retain`, all stable long before
the 1.96 floor, and the resolved non-dev tree's highest declared `rust-version`
stays `axum` 0.8.9's **1.80**, identical to R69's accepted figure; **gate 3**
advisories and `unsafe` — no crate is added so no advisory is added, and the
template code contains **zero** `unsafe` (by contrast, taking `governor` would
add `quanta` 0.12.6, which reads the TSC, plus `zerocopy` 0.8.57, `parking_lot`
0.12.5, `rand` 0.9.5 and `getrandom` 0.3.4); **gate 4** platforms — `std::sync`,
`std::time::Instant` and `HashMap` are core std on both `ubuntu-latest` and
`macos-latest` (the tests were run on macOS 26.4 arm64; Windows is equally
supported though not required); **gate 5** default features and async-runtime
coupling — none, `check` is a synchronous function over `std::time::Instant`,
the `Mutex` guard is never held across an `await`, and nothing binds to tokio;
**gate 6** binary size and compile time — qualitatively nil, since the resolved
dependency tree is byte-identical to R69's baseline and the added code is one
module.

##### Up-and-comers

`gcra` 0.6.0 is the closest thing to an off-the-shelf version of this member:
`RateLimiter::new(max_data_capacity)`, a keyed `dashmap` map, `prune_expired()`,
and `GcraError::DeniedUntil { next_allowed_at: Instant }` — the exact instant
`Retry-After` needs. It clears every gate: `MIT`, `rust-version = "1.80.0"`, no
RustSec page (HTTP 404, 2026-09-18), no async-runtime coupling beyond an `async
fn check` that awaits nothing external, `rate-limiter` is a default feature
pulling `dashmap` and `rustc-hash`.

It is rejected on practice evidence and maintenance, both measured.
**Zero** crates.io reverse dependencies
(`https://crates.io/api/v1/crates/gcra/reverse_dependencies`, `total: 0`,
2026-09-18) — no published crate depends on it. Nine GitHub stars, repository
created 2022-06-12, `pushed_at` **2024-08-01** (25 months), two issues in its
entire history, both closed (`https://api.github.com/repos/lytefast/gcra-rs`,
2026-09-18). Its 358,352 90-day downloads therefore come from unpublished
consumers, and cannot be read as adoption by well-regarded projects. Its pinned
dependencies are stale by two majors (`dashmap` 5.5.3 against 6.2.1) and one
(`thiserror` 1.0.69 against 2.0.20). Maintenance verdict: **stable-quiet** — the
crate is small, complete and has no open issues, so "at-risk" would overstate
it, but a template whose lifetime is measured in years should not place a
single-author, zero-dependent, 25-month-quiet crate on its request path to save
forty lines.

##### Fit for this template

The workload is one app-wide policy over peer addresses in a single-instance
service, which is F316's own framing. Measured on Apple M4 Pro / macOS 26.4 /
arm64, release profile, 1,000,000 admit-path checks aggregate: 14,706,360 ops/s
single-threaded on one key, 9,165,311 on 10,000 keys, 14,385,014 at eight
threads on one key, 6,223,916 at eight threads on 10,000 keys — worst case 160.7
ns per check, under 0.02% of a 1 ms request. `governor`'s `dashmap`-backed store
measured about twice as fast single-threaded (36.9 ns vs 68.0) and about 2.5×
faster at eight threads over many keys (63.6 ns vs 160.7), and slower at eight
threads over one key (128.1 ns vs 69.5, reported as observed and not explained).
The comparison is a same-harness measurement of one code path with no eviction
exercised and no latency distribution; it is not a benchmark of either crate as
deployed. At this template's scale the difference does not reach the decision.
Against py the fit is exact — a process-local map with no `storage_uri` — and
this design adds the bound py's slowapi backend gets from entry expiry.

##### Recommendation

`InMemoryRateLimitStore { policy, capacity, cells: Mutex<HashMap<RateLimitKey,
Instant>> }` implementing `RateLimitStore`, held by the middleware as
`Arc<dyn RateLimitStore>`. Eviction is lazy and O(capacity): only when the map
is full and the key is new does it `retain(|_, tat| *tat > now)`, dropping every
cell whose arrival time has passed and which therefore carries no state. If the
map is still full afterwards, the request is **admitted** — the limiter fails
open. That is a deliberate security trade and is recorded as one: an attacker
with many source addresses can fill the map and disable limiting for new keys,
whereas failing closed would let the same attacker deny service to every new
client. A limiter must not become the outage. The mitigations are a capacity
large enough that this costs real resources (default 65,536 cells ≈ a few MiB),
and a saturation counter handed to R79 so the condition is observable rather
than silent. `RateLimitKey` is an enum — `Peer(IpAddr)` and `Global` — so the
degraded no-`ConnectInfo` path has a representable key rather than an error.

##### Ranked runner-up

1. `dashmap` 6.2.1 behind the same `RateLimitStore` trait. Take it if profiling
   ever shows the mutex is the bottleneck; because the trait is the seam, this
   is a new implementation rather than a rewrite. Cost: one direct dependency
   and four transitive packages, plus the bounding logic still to be written.
2. `gcra` 0.6.0's `RateLimiter<T>`, which supplies both this member and the
   algorithm member. Take it if the owner prefers an imported implementation to
   an owned one and accepts a zero-dependent, single-author crate.

##### Tradeoffs

Gained: bounded memory by construction; a swap point that is a compilable trait
rather than a paragraph; zero crates, so the web member's dependency tree,
advisory surface and MSRV figure are unchanged from R69's accepted baseline;
and no `unsafe` anywhere. Given up: sharded concurrency — one mutex serialises
all admissions, measured at 6.2M/s worst case, which is a ceiling that exists
even if it is far away. Risk accepted: a poisoned mutex; the probe uses
`.expect("poisoned")`, and P03 should decide whether a poisoned limiter fails
open with a warning instead of panicking, which is a decision this report leaves
open rather than settling from a probe.

##### Parameters

This member owns no parameter. The capacity is a second knob — R77 names
environment variables, and this item's position is that the capacity is **not**
the gate: the gate is the single policy variable F323 records, and the capacity
is an optional tuning variable with a default, exactly as py has
`idempotency_max_entries: int = 1024` beside its gate
(`settings.py:76-77`). Consumed parameters and their exact registry bytes are in
the item-level `### Parameters`. No `CONFLICT:` line.

##### Migration implications

`crates/web/src/rate_limit.rs` gains `RateLimitKey`, `RateLimitStore`,
`InMemoryRateLimitStore` and its `RateLimitStore` impl. R77 gains one optional
capacity setting with a default. R79 gains one counter name to expose
(limiter saturation) — handed off, not decided here. No dependency is added.

##### Validation strategy

Executed: `keys_are_isolated_and_the_store_is_bounded` asserts that exhausting
key A does not affect key B, that the map holds exactly one cell per key, and
that ten further distinct keys against a capacity of 3 leave the map at most 3
entries. `third_request_is_429_with_an_accurate_retry_after` asserts the store
holds exactly one cell after three requests from one key. The throughput figures
above were produced by a release-profile harness over 1,000,000 checks.
Planned, not run: a loom or concurrency-stress test asserting no admission is
lost or double-counted under contention; an eviction test that advances a fake
clock rather than relying on `Instant::now()`, which requires injecting the
clock — a small refactor this report recommends for P03 but did not make.

##### Confidence & re-verify trigger

High on the mechanics, which were executed. Medium on the fail-open capacity
policy, which is a judgement call the owner may prefer to invert and which is
stated explicitly so that it can be. Re-verify when R73 publishes, because its
idempotency cache is a second bounded in-memory store in the same member and the
two should share an eviction discipline even though F315 and F316 are separate
rows; when R77 publishes the settings surface; when R79 publishes the metric
names; if `governor` or `gcra` changes the facts above; or by 2027-03-18.

##### Sources

`https://crates.io/api/v1/crates/gcra`, `/versions` and `/reverse_dependencies`
(2026-09-18); `https://api.github.com/repos/lytefast/gcra-rs`,
`https://api.github.com/search/issues?q=repo:lytefast/gcra-rs+is:issue+is:open`
and `/issues` (2026-09-18); `https://crates.io/api/v1/crates/governor` and
`/reverse_dependencies` (2026-09-18);
`https://api.github.com/repos/boinkor-net/governor/contents/governor/Cargo.toml`
(2026-09-18); `https://rustsec.org/advisories/RUSTSEC-2022-0002.html` and
`https://rustsec.org/packages/dashmap.html` (2026-09-18);
`https://rustsec.org/packages/governor.html` and `/gcra.html` (both HTTP 404,
2026-09-18); unpacked sources `gcra-0.6.0/Cargo.toml`, `src/gcra.rs`,
`src/rate_limit.rs`, `src/rate_limiter/rate_limiter.rs`, and
`governor-0.10.4/Cargo.toml` (2026-09-18); py at the pin,
`git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/web/settings.py`
lines 68-77 and `:src/py_launch_blueprint/web/app.py` line 220.

### Compatibility

The proof is a **shared example repository that was built and run**, not an
argument. All three members were compiled together against the exact versions
R69's accepted decision names — `axum` 0.8.9 and `tokio` 1.53.1 with features
`rt-multi-thread, net, signal, macros, time, sync`, `tower` 0.5.3 as a
dev-dependency for `ServiceExt::oneshot`, `edition = "2024"`, `rust-version =
"1.96"` — on `rustc 1.98.0` with current stable at 1.98.1 (2026-09-03,
`https://static.rust-lang.org/dist/channel-rust-stable.toml`, 2026-09-18), so
the `msrv-policy` floor is 1.96. Result: `cargo test` 8 passed / 0 failed,
`cargo clippy --all-targets -- -D warnings` clean, `cargo fmt --check` clean.

The version matrix that matters here is the dependency tree, and it is the
strongest compatibility evidence available: `cargo tree -e normal` for the
three members composed is **byte-identical** to the same command over a bare
`axum` 0.8.9 + `tokio` 1.53.1 manifest — 51 lines in both, `diff` empty. Adding
`tracing = { version = "0.1.44", default-features = false, features = ["std"] }`
for the warn-once keeps it identical; declaring `tracing` with default features
instead would add `tracing-attributes` and `syn` (proc-macros, build-time only),
which is why the features are pinned off. The resolved tree's highest declared
`rust-version` is `axum` 0.8.9's **1.80**, the same figure R69 recorded
(`…/R69/…/DECISION.md:2265-2266`), and eight transitive packages declare none —
`httparse`, `matchit`, `mime`, `serde_urlencoded`, `smallvec`, `sync_wrapper`,
`tower-layer`, `tower-service` — which is R69's own accepted position that the
strict gate-2 reading applies to candidates, not to every transitive crate.

The contrasting matrix, measured the same way: `tower_governor` 0.8.0 with
`default-features = false, features = ["axum"]` resolves to 87 non-dev tree
entries against the baseline's 50, adding **37** including `governor` 0.10.4,
`dashmap` 6.2.1, `quanta` 0.12.6, `parking_lot` 0.12.5, `rand` 0.9.5,
`getrandom` 0.3.4, `zerocopy` 0.8.57 and **both** `thiserror` 1.0.69 and 2.0.20
(counted as distinct name-and-version entries; deduplicated by crate name the
figures are 83 and 33, because `hashbrown`, `syn`, `thiserror` and
`thiserror-impl` each appear twice); with its
default features, which include `tonic`, it resolves to 99 and adds **49**,
bringing
`tonic` 0.14.6, `h2` 0.4.19, `hyper-timeout` 0.5.2, `tokio-stream`, `tokio-util`,
`base64` and `async-trait` into a template with no gRPC. `tonic` 0.14.6 also
declares `rust-version = "1.88"`, which would raise the resolved-tree figure
from 1.80 to 1.88 — still inside the 1.96 floor, but eight minors of headroom
consumed for a feature nobody asked for.

Cross-member compatibility was also checked where it could fail: the algorithm
member returns `Result<(), Instant>` and the store member is the only thing that
constructs those instants, so a tolerance change cannot desynchronise them; the
layer member's `retry_after_seconds` is the only reader of that instant; and the
`RateLimitKey::Global` variant exists precisely so the layer member's degraded
path has a key the store member accepts. The one composition that is **not**
proven is the rendering of the 429 body through R70's envelope, because R70 has
not published; the probe's `IntoResponse` produces a placeholder body and
asserts only the status and the header.

### Parameters

This item owns no parameter. Consumed:
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files

**No `CONFLICT:` line is raised.** Nothing in this recommendation needs a
consumed value changed.

**Note beside the `web-extra-surface` line above.** Those are the live bytes of
the `docs/port/PARAMETERS.md` row, which still carries R69 revision 9's form and
names the web tree `src/web/` and the feature as `web = ["dep:axum",
"dep:tokio"]`. R69 **revision 10** is owner-accepted but unpublished
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791`,
under owner rulings W1-R02 and W0-R69c): the `web` feature on the root package
names the optional member `crates/web`, the web tree is `crates/web/src/`, the
integration tests are `crates/web/tests/` with no file-level
`#![cfg(feature = "web")]`, and `tower` 0.5.3 is `crates/web`'s dev-dependency
only. **This design uses the revision-10 paths** — `crates/web/src/rate_limit.rs`,
`crates/web/Cargo.toml`, `crates/web/tests/` — throughout. R69's republication
of that row is a re-verify trigger for this item. This is deliberately not a
`CONFLICT:`: the recommendation needs no change to R69's value, only its
published bytes to catch up.

**One consumed-value observation that is also not a `CONFLICT:`.** R69's
revision-10 `serve_until` calls `axum::serve(listener, app)`
(`…/R69/…/DECISION.md:1106`), which installs no `ConnectInfo<SocketAddr>`. With
rate limiting enabled that would make every caller share one quota bucket.
`serve_until` is named in R69's owned value but its arguments are not, so the
required change —
`axum::serve(listener, app.into_make_service_with_connect_info::<SocketAddr>())`
— is a hand-off to R69 and R75, not a change to the parameter's value.

**Two values this item fixes that other items name.** The rate-limit
environment variable's **grammar** is py's `limits` notation, one string,
`"<count>/<period>"` with `period ∈ {second|sec|s, minute|min|m, hour|hr|h,
day|d}`; R77 owns the variable's *name*, this item owns what a valid value
means, because F323 records that **one** variable enables the capability and two
integers would be two variables. The optional store **capacity** is a second,
defaulted tuning variable — not a gate — whose name is likewise R77's.

### Migration implications

File-level changes in the template, against R69 revision 10's `crates/web`
layout. Nothing outside `crates/web` changes, and the root `Cargo.toml` is
untouched.

| Path | Change |
|---|---|
| `crates/web/src/rate_limit.rs` | **New.** `RateLimitPolicy` + `FromStr` (py's `limits` grammar), `PolicyParseError`, `RateLimitKey`, the `RateLimitStore` port, `InMemoryRateLimitStore`, `RateLimitState`, `retry_after_seconds`, the `RateLimited` rejection with its `IntoResponse`, the `rate_limit` middleware function, and `install_rate_limit`. The probe's equivalent is 162 lines including doc comments |
| `crates/web/src/lib.rs` | One line: `mod rate_limit;` (or `pub(crate) mod`) |
| `crates/web/src/…` (`build_router`) | One line: `let router = install_rate_limit(router, settings.rate_limit, settings.rate_limit_capacity);`, placed where R75's order puts it |
| `crates/web/src/…` (`serve_until`) | `axum::serve(listener, app)` becomes `axum::serve(listener, app.into_make_service_with_connect_info::<SocketAddr>())`. **Required**, not optional: without it the limiter has no peer address. Hand-off to R69/R75 |
| `crates/web/Cargo.toml` | One line: `tracing = { version = "0.1.44", default-features = false, features = ["std"] }` for the warn-once. Adds **zero** packages to the resolved tree. R58 may supersede this declaration with its own `tracing` line; if so, this item needs none |
| `crates/web/src/settings.rs` (R77's file) | Two fields: `rate_limit: Option<RateLimitPolicy>` (default `None`) and `rate_limit_capacity: usize` (default 65,536). R77 owns the names and the env plumbing |
| `crates/web/tests/rate_limit.rs` | **New.** The six executed acceptance tests, plus the R70-envelope assertion once R70 publishes |
| `README.md` / `crates/web` module docs | The swap-point paragraph F316 requires: `RateLimitStore` is the seam, `InMemoryRateLimitStore` is single-instance by design, the enforced rate across N instances is `quota × N`, and an external gateway is the production answer at scale |

Deliberately unchanged: the root package's `web` feature (this adds no optional
dependency, so the feature's `dep:` list is untouched); `crates/core` (R05's
synchronous core holds no limiter state, and this design puts none there — the
store lives entirely in the web member); the CLI binary; `Cargo.lock` beyond
whatever R58's `tracing` line already does.

Ordering constraints handed to **R75**, which owns F317 and the final order, as
constraints rather than a decision. At the pin, py's layer order is readable
from `app.py:130-147` — Starlette applies the last `add_middleware` outermost,
giving outermost→innermost `RequestID → SecurityHeaders → RateLimit
(conditional) → CORS (conditional) → Idempotency → routes`. Three properties
follow and should survive whatever order R75 chooses: (1) the 429 must carry the
request-id and security headers, so the limiter sits **inside** those two; (2)
the 429 must not be produced after the idempotency cache has been consulted or
an idempotency key consumed, so the limiter sits **outside** R73's layer — a
rejected request must neither be cached nor burn a key; (3) py limits CORS
preflights (the limiter is outside CORS), which is a defensible choice R75 may
revisit. A fourth, this item's own: the limiter must sit inside whatever
installs `ConnectInfo`.

Handed to **R79**: two counter names, a rejected-request counter and a store-
saturation counter, both R79's to name and shape. Handed to **R70**: the
`RateLimited` value needs a variant or a `From` impl in R70's error enum, with
`Retry-After` surviving as a real header alongside whatever the problem document
carries. Handed to **R73**: F315 and F316 are separate rows and separate caches,
but they are two bounded in-memory maps in one crate and should share an
eviction and observability discipline.

### Validation strategy

**Executed on this machine**, 2026-09-18, `rustc 1.98.0` / `cargo 1.98.0`,
macOS 26.4 arm64, against `axum` 0.8.9 + `tokio` 1.53.1 + `tower` 0.5.3 (dev),
`edition = "2024"`, `rust-version = "1.96"`. Results: **8 passed, 0 failed**;
`cargo clippy --all-targets -- -D warnings` produced no diagnostic;
`cargo fmt --check` clean.

| # | Command / test | Asserts | Result |
|---|---|---|---|
| 1 | `cargo test off_by_default_is_the_absence_of_the_layer` | 1,000 requests to a router built without the layer all return 200 | pass |
| 2 | `cargo test conditional_registration_is_the_gate` | the same `install_rate_limit` call site yields 50×200 with `None`, and 200 then **429** with `Some("1/minute")` | pass |
| 3 | `cargo test third_request_is_429_with_an_accurate_retry_after` | with `2/minute`, requests 1–2 are 200, request 3 is **429** with `retry-after` exactly `30`, and the store holds exactly one cell | pass |
| 4 | `cargo test keys_are_isolated_and_the_store_is_bounded` | key B is admitted after key A is exhausted; ten further keys against capacity 3 leave `len() <= 3` | pass |
| 5 | `cargo test policy_grammar_matches_py_limits_notation` | `"100/minute"` → `(100, 60s)`; `"100"`, `"0/minute"`, `"100/fortnight"` all error | pass |
| 6 | `cargo test retry_after_is_never_zero` | 1 ms → 1, 0 → 1, 1500 ms → 2 (ceiling, floored at 1) | pass |
| 7 | `cargo test without_connect_info_the_default_key_extractor_returns_500` | `tower_governor` 0.8.0 under `oneshot` with no `ConnectInfo` returns **500**, not 429 | pass |
| 8 | `cargo test with_connect_info_the_third_request_is_429_and_carries_retry_after` | `tower_governor` 0.8.0 with `ConnectInfo` returns **429** with `retry-after: 29` and `x-ratelimit-after: 29` for a true wait of 29.99…s, and **no** `content-type` | pass |
| 9 | `cargo tree -e normal` on the recommended manifest vs a bare axum+tokio manifest, `diff`ed | identical, 51 lines each | pass (empty diff) |
| 10 | `cargo tree -e normal` with `tower_governor = { default-features = false, features = ["axum"] }` and with its defaults | 87 and 99 non-dev tree entries respectively against the baseline's 50 | observed |
| 11 | `cargo metadata` over the resolved non-dev tree | highest declared `rust-version` is `axum` 0.8.9's **1.80**; eight packages declare none | observed |
| 12 | release-profile harness, 1,000,000 admit-path checks across {1,8} threads × {1, 10,000} keys | the four throughput rows in the store member's *Fit* | measured |

**Planned for P03, not run here**, and labelled as proposals: a test asserting
the 429 body is R70's problem document (blocked on R70); a test over a real
`TcpListener` asserting the serve path installs `ConnectInfo` (blocked on R69's
serve-argument change); a property test over random `(burst, period, arrival
sequence)` asserting admissions never exceed `burst` in a window and that a
client obeying `Retry-After` is never refused twice consecutively; a
clock-injection refactor so eviction can be tested against a fake clock rather
than wall time; and a concurrency-stress or `loom` test for the store. The
`cargo audit` leg is inapplicable in the usual sense — no crate is added, so the
advisory surface is exactly R69's, which R69 already scanned to exit 0 against a
pinned advisory database (`…/R69/…/DECISION.md:2270-2276`).

### Confidence & re-verify trigger

**High** on the design and its behaviour: every claim about the recommendation
was compiled and executed, the `Retry-After` value is asserted exactly rather
than as a range, and the dependency-cost claim is a `diff` rather than a
description. **High** on the facts that exclude `tower_governor` and `governor`:
the absent `rust-version` was read from the published manifests and confirmed at
`master`, and the 500 and the `retry-after: 29` were observed in passing tests.
**Medium-high** on the *conclusion* that they are excluded, because that rests
on a gate reading rather than on an unworkable defect — the reading is the
owner's own settled one and R69 applied it to four framework candidates, but a
different owner ruling would change the answer for this item more than it
changed R69's. **Medium** on two judgement calls that are stated so they can be
inverted: failing open when the store is saturated, and falling back to a global
bucket with a warning rather than a 500 when `ConnectInfo` is missing.

Not verified, and recorded as gaps: slowapi's own `Retry-After` rounding, since
slowapi is a dependency of the pinned repository and not a file in it, so
whether py truncates or rounds is unknown and the ceiling is this template's
argued choice rather than a match to py; issue-responsiveness medians for
`gcra`, `ratelimit`, `axum-governor` and `tower-resilience`, where the issue
populations are too small (0–2 issues each) for a median to mean anything, and
the raw counts are reported instead; and reverse-dependency `Cargo.toml`
inspection for the `governor` adopters, which was taken from the crates.io
reverse-dependencies endpoint rather than by opening each project's manifest.

**Re-verify when** `tower_governor` or `governor` publishes a release declaring
a `rust-version` inside the floor, which would clear gate 2 and reopen the
comparison; when the owner rules differently on gate 2; when R69 republishes its
row with the `crates/web` paths, or changes `serve_until`'s `axum::serve`
argument; when R70 publishes the error envelope the 429 renders through; when
R75 publishes the layer order; when R77 publishes the settings surface and the
variable name; when R73 publishes, so the two in-memory stores can share an
eviction discipline; when `draft-ietf-httpapi-ratelimit-headers` becomes an RFC,
at which point emitting `RateLimit` and `RateLimit-Policy` beside `Retry-After`
becomes worth doing; when axum publishes 0.9; at the next `msrv-policy` floor
advance past 1.96; or by **2027-03-18**, whichever comes first.

### Sources

**Standards.** RFC 6585 §4, *429 Too Many Requests*
(`https://www.rfc-editor.org/rfc/rfc6585.txt`, retrieved 2026-09-18) — "The 429
status code indicates that the user has sent too many requests in a given amount
of time ('rate limiting')" and the response "MAY include a Retry-After header
indicating how long to wait before making a new request". RFC 9110 §10.2.3,
*Retry-After* (`https://www.rfc-editor.org/rfc/rfc9110.txt`, retrieved
2026-09-18) — `Retry-After = HTTP-date / delay-seconds`,
`delay-seconds = 1*DIGIT`, "a non-negative decimal integer, representing time in
seconds". `draft-ietf-httpapi-ratelimit-headers-11`, *RateLimit header fields
for HTTP*, Standards Track, dated **23 May 2026**, expires 24 November 2026
(`https://www.ietf.org/archive/id/draft-ietf-httpapi-ratelimit-headers-11.txt`
and `https://datatracker.ietf.org/api/v1/doc/document/?name__startswith=draft-ietf-httpapi-ratelimit-headers`,
both retrieved 2026-09-18) — defines `RateLimit` and `RateLimit-Policy`; still a
draft, which is why this recommendation emits `Retry-After` only.

**Registry and repository figures.** crates.io API for `governor`,
`tower_governor`, `axum`, `axum-governor`, `axum_gcra`, `gcra`, `ratelimit`,
`leaky-bucket`, `tower`, `tower-resilience-ratelimiter`, `loco-rs` — the crate
endpoint for `recent_downloads` and `downloads`, `/versions` for the newest
non-yanked `num`, `created_at`, `rust_version` and `license`, and
`/reverse_dependencies` for adopters; plus the search endpoint
`https://crates.io/api/v1/crates?q=…` for the landscape sweep; all retrieved
2026-09-18. GitHub REST for `boinkor-net/governor`, `benwis/tower-governor`,
`lytefast/gcra-rs`, `iopsystems/ratelimit`, `canmi21/axum-governor`,
`joshrotenberg/tower-resilience` and `loco-rs/loco` — `repos/<o>/<r>` for
`stargazers_count`, `archived`, `pushed_at` and `license`;
`search/issues?q=repo:<o>/<r>+is:issue+is:open` for `total_count` (never
`open_issues_count`); `repos/<o>/<r>/issues` and `/issues/<n>/comments` for
responsiveness; `repos/<o>/<r>/contents/<path>` for manifests and source at
`master`; all retrieved 2026-09-18, one request per 20 seconds.
`https://static.rust-lang.org/dist/channel-rust-stable.toml` (2026-09-18) for
current stable 1.98.1, released 2026-09-03, which sets the 1.96 floor.

**Advisories.** `https://rustsec.org/packages/<name>.html` for `governor`,
`tower_governor`, `gcra`, `ratelimit`, `axum-governor` — all HTTP **404**, i.e.
no advisory page exists — and `https://rustsec.org/packages/dashmap.html` →
`https://rustsec.org/advisories/RUSTSEC-2022-0002.html`, "Unsoundness in
`dashmap` references", **patched >= 5.1.0**, so neither `dashmap` 5.5.3 nor
6.2.1 is affected; all retrieved 2026-09-18.

**Crate source, read not recalled**, from
`~/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/`:
`tower_governor-0.8.0/{Cargo.toml,src/lib.rs,src/errors.rs,src/governor.rs,src/key_extractor.rs}`;
`governor-0.10.4/Cargo.toml`;
`gcra-0.6.0/{Cargo.toml,src/gcra.rs,src/rate_limit.rs,src/rate_limiter/rate_limiter.rs}`;
`axum-governor-2.1.0/{Cargo.toml,src/headers.rs,src/response.rs}`;
`tower-resilience-ratelimiter-0.13.0/{src/error.rs,src/lib.rs}`; all read
2026-09-18.

**Source repositories at the pin.**
`git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/web/settings.py`
(lines 68-77) and `:src/py_launch_blueprint/web/app.py` (lines 129-147, 209-243),
read 2026-09-18. ts contributes nothing: it has no web service
(`docs/port/areas/web-service.md:100`).

**Programme documents.** `docs/port/COMMONALITY.md` rows F316 (line 320) and
F323 (line 327), and F317 (line 321) for the hand-off;
`docs/port/areas/web-service.md` rows F316 (line 22), F317 (line 23), F323
(line 29); `docs/port/PARAMETERS.md` (the five consumed rows, quoted
byte-exactly); `docs/planning/p02/owner-decisions.md` §11 (the standing-input
ruling) and its "Two things you should know" section (the settled strict gate-2
reading); `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`
lines 31, 54, 70, 72, 114, 140, 185, 415;
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` lines
1067, 1106, 1285-1288, 1480-1498, 1554-1555, 1791, 2255-2276, 2310;
`docs/port/BASELINE-REVIEW.md` (checked for an F316/F323 row; there is none,
which is why no `BASELINE-REVIEW:` finding is filed).

**Method notes.** Figures came from the crates.io crate, versions,
reverse-dependencies and search endpoints, the GitHub REST repos, search/issues,
issues, issue-comments and contents endpoints, the RustSec package and advisory
pages, `https://static.rust-lang.org/dist/channel-rust-stable.toml`, the IETF
datatracker API and the RFC Editor text archive — each named above with its
retrieval date of 2026-09-18. GitHub requests were spaced 20 seconds apart. Load-
bearing behavioural claims were not read from documentation: six throwaway Cargo
probes under `$TMPDIR` established the dependency trees, the resolved MSRV, the
observed `tower_governor` responses, the recommended design's behaviour and the
throughput figures, and all were deleted after the run. **Could not be
verified:** slowapi's internal `Retry-After` rounding (not a file in the pinned
repository); issue-response medians for `gcra`, `ratelimit`, `axum-governor` and
`tower-resilience`, whose issue populations are 0–2 and too small for a median
(raw counts reported instead); per-project `Cargo.toml` inspection of the
`governor` adopters, taken from the reverse-dependencies endpoint instead;
`ratelimit`'s repository star count, which reads as 2 because
`iopsystems/ratelimit` was created 2026-03-20 and evidently does not carry the
crate's earlier history — the figure is reported as returned and not relied on.
The `tower-resilience` responsiveness figure is reported as "every one of the
ten most recent issues was opened and closed by the maintainer himself", which
is what the endpoint returned, rather than as a median. No Codex leg ran (owner
ruling W1-CODEX3, 2026-09-18); this report stands on its own evidence.
