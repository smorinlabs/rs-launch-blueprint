### Landscape

**Retrieval date:** September 18, 2026, for all external sources and fallback figures below. The Python/TypeScript precedent and repository paths are owner-provided evidence and were not independently fetched.

**Decision category:** application-level HTTP admission control: a keyed rate-limit policy implemented as middleware, controlled at runtime, with truthful deployment scope and an actionable rejection contract.

**Three-bin ecosystem map**

| Bin | Candidates found | Assessment |
|---|---|---|
| Built-in or first-party toolchain | `tower::limit::RateLimitLayer` 0.5.3 | Mature first-party service-level throttling, but it controls service readiness rather than producing keyed HTTP 429 responses. It has no per-client store, response factory, or `Retry-After` contract, so it is not the capability required here. ([docs.rs](https://docs.rs/tower/latest/tower/limit/rate/struct.RateLimit.html)) |
| Established industry standard | `governor` 0.10.4; `tower_governor` 0.8.0; framework-specific `actix-governor` | `governor` is the established in-memory GCRA engine. `tower_governor` is the established Tower adapter, supports keyed/global limits and custom error responses, and is used with Axum, Hyper and Tonic. Its current package manifest does not declare `rust-version`, and its default `Retry-After` path uses `Duration::as_secs()`, which truncates fractional seconds. ([docs.rs](https://docs.rs/governor/latest/governor/)) |
| Up-and-comer | `tower-rate-limiter` 0.1.6; `axum-governor` 2.1.0; FlowShield 0.2; `rune-axum-ratelimit` | `tower-rate-limiter` is unusually close to the required architecture: Tower-first, explicit `MemoryStore`, a `Store` trait, Redis implementation, custom response factory, fixed-window reset metadata, edition 2024 and Rust 1.96. Its weakness is ecosystem age and near-zero verified adoption. `axum-governor` is richer but binds R74 to Axum before R69 resolves. FlowShield still describes its public facade as pre-stabilization/design work. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6)) |

**Authority used**

- The Rust Forge and official release announcements establish that stable Rust is 1.98.1, making the owner’s “stable minus two minor versions” floor Rust 1.96.0. Cargo’s documentation is authoritative for `rust-version` semantics. ([forge.rust-lang.org](https://forge.rust-lang.org/))
- Tower and Axum maintainer documentation is authoritative for middleware architecture: Axum deliberately uses Tower rather than a bespoke middleware system, and Tower models wrappers as `Layer`/`Service` components. ([github.com](https://github.com/tokio-rs/axum/blob/main/axum/src/docs/middleware.md))
- RFC 6585 is normative for HTTP 429, while RFC 9110 defines `Retry-After` and its integral `delay-seconds` representation. ([rfc-editor.org](https://www.rfc-editor.org/rfc/rfc9110.html))
- Candidate manifests, API documentation, source, examples and repository activity are primary sources for implementation behavior. RustSec is the advisory authority, although the complete dependency-tree audit remains an executable integration check. ([github.com](https://github.com/nivek3/tower-rate-limiter/blob/main/Cargo.toml))
- Current project `Cargo.toml` files were weighted more highly than blogs for practice evidence. Meta’s Buck2 and Restate currently use Tower 0.5, supporting Tower as a mainstream service abstraction; this does not by itself validate any particular rate-limiter adapter. ([github.com](https://github.com/facebook/buck2/blob/main/shim/third-party/rust/Cargo.toml))

**Fitness gates before popularity**

| Candidate | License | MSRV | Advisories / unsafe | Ubuntu + macOS | Features/runtime | Build cost | Result |
|---|---|---|---|---|---|---|---|
| `tower-rate-limiter` 0.1.6 | Pass: `MIT OR Apache-2.0` | Crate-level pass: edition 2024, `rust-version = 1.96.0`, pinned 1.96 toolchain. Full resolved tree must still be checked on 1.96. | No matching RustSec package page was retrieved; full-tree `cargo deny` and unsafe scan were not run. Conditional. | Repository has active Actions, but the retrieved evidence did not expose its OS matrix. Template CI on both required OSes is mandatory. | Default is `memory`, implemented through optional synchronous Moka; Redis and Tokio/Smol coupling are optional. | Medium: adds Moka and client-IP extraction code but no network client or async runtime for the selected feature set. | **Conditional pass; only candidate matching capability, declared MSRV and swap seam.** ([github.com](https://github.com/nivek3/tower-rate-limiter/blob/main/Cargo.toml)) |
| `tower_governor` 0.8.0 | Pass | **Fail:** no `rust-version` in current package manifest. | Direct advisory check incomplete; unsafe policy not documented in retrieved evidence. | Not proven from retrieved evidence. | Default features enable both Axum and Tonic; `default-features = false` reduces cost. | Medium/high with defaults; medium without. | **Excluded by required MSRV evidence gate.** ([github.com](https://github.com/benwis/tower-governor/blob/main/Cargo.toml)) |
| `governor` 0.10.4 plus local Tower layer | Pass: MIT | Dependency MSRV not fully verified. | Direct advisory/tree check incomplete. | Not fully verified. | In-memory engine; no web runtime required, but the application would own the HTTP adapter. | Low engine cost, high local implementation/maintenance cost. | **Qualified architecture, not selected.** ([docs.rs](https://docs.rs/governor/latest/governor/)) |
| `axum-governor` 2.1.0 | Pass: MIT | Not verified from retrieved manifest evidence. | Direct advisory/tree check incomplete. | Not verified. | Axum 0.8, Tower 0.5, Tokio; defaults include DashMap, tracing and JSON. | Medium/high. | **Excluded from unconditional selection because R69 is open and the crate is Axum-specific.** ([docs.rs](https://docs.rs/crate/axum-governor/latest)) |
| Tower built-in limiter | Pass | Pass relative to floor | First-party posture | Tower project is mature and cross-platform | Tower `limit` feature | Low if Tower is already present | **Excluded by capability gate:** no keyed store or HTTP rejection contract. ([docs.rs](https://docs.rs/tower/latest/tower/limit/rate/struct.RateLimit.html)) |

**Practice evidence**

- `tower_governor` has the strongest direct adapter precedent: current repository pages show 351 stars and examples for Axum, Hyper and Tonic; Helix and Tangled manifests demonstrate use in real projects. The Axum discussion archive also repeatedly points users to it. ([github.com](https://github.com/benwis/tower-governor))
- `governor` is the strongest algorithm-engine precedent, with 938 GitHub stars and multiple framework adapters built around it. ([github.com](https://github.com/boinkor-net/governor))
- `tower-rate-limiter` currently has six stars, three forks and one open issue. No well-regarded production adopter was verified. Its recommendation therefore rests on architectural fit and executable verification, not popularity. ([github.com](https://github.com/nivek-ph/tower-rate-limiter))
- Published Rust templates surveyed did not establish an exact “absent env var means no limiter layer” standard. Gerust discusses optional rate-limiter generation, and Awesome Axum lists templates with Redis-backed limiting, but neither supplies the complete required pattern. This is an evidence gap rather than evidence against the pattern. ([reddit.com](https://www.reddit.com/r/rust/comments/1h77a9w))

**Required figure acquisition status**

The mandated crates.io and GitHub API endpoints were attempted, but direct API responses were unavailable through the research transport. I have not substituted estimates. HTML/docs fallbacks are identified below; exact API figures remain a pre-ledger-close evidence task.

| Candidate | Latest release fallback | GitHub HTML fallback | 90-day / all-time downloads | `archived`, `pushed_at` | Issue responsiveness | Maintenance state |
|---|---:|---:|---|---|---|---|
| `tower-rate-limiter` | 0.1.6; exact API `created_at` not retrieved | 6 stars, 1 open issue | Not retrieved | Not retrieved; repository has no archived banner | Not retrieved | `active` |
| `tower_governor` | 0.8.0, released August 14, 2025 | 351 stars, 19 open issues | Not retrieved | Not retrieved | Not retrieved | `stable-quiet`; no dormancy criterion proven |
| `governor` | 0.10.4 | 938 stars, 24 open issues | Not retrieved from required API | Not retrieved | Not retrieved | `stable-quiet` |
| `axum-governor` | 2.1.0, released September 5, 2026 | 25 stars in docs.rs metadata, 0 open issues | Not retrieved | Not retrieved | Fewer than ten visible open issues; median still not computed | `active` |

Release and repository fallbacks are supported by the maintainers’ current docs and repository pages. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6))

### Principles and implementation

**Shared engineering principle**

The owner-provided Python precedent expresses four linked principles:

1. **Operator intent:** an unused template must not unexpectedly reject traffic.
2. **Truthful scope:** a process-local limiter must not imply cluster-wide enforcement.
3. **Actionable rejection:** a client must know how long to back off.
4. **Replaceable state:** scaling to multiple replicas must have a named store boundary rather than requiring the HTTP behavior to be rewritten.

Agreement is therefore required at the **architectural-pattern and observable-behavior level**, not at exact crate, web framework, algorithm, env-var spelling, key extractor or problem-document type.

**Must agree**

- The same web binary runs with and without rate limiting.
- An absent or empty single runtime setting means no limiter layer is registered.
- A valid non-empty setting constructs exactly one shared process-local store and one app-wide layer at startup.
- The first request over quota returns 429.
- Its `Retry-After` is calculated from the rejected key’s remaining reset duration, not copied from the configured full window.
- The store is documented as per-process; two replicas intentionally maintain independent quotas.
- The eventual distributed swap occurs in one constructor through the crate’s `Store` seam.
- The 429 response is produced through an R70-compatible response factory.

**May vary**

- Fixed window versus GCRA/token bucket.
- Exact env name and string grammar.
- Peer-IP versus authenticated-principal key.
- R75 placement.
- R70 problem fields.
- Optional successful-response rate-limit fields.

**Architectural alternatives**

| Alternative | Advantages | Why not selected |
|---|---|---|
| Reverse proxy/API gateway only | Best place for shared, pre-application protection; can shield all replicas | Does not provide the self-contained, one-setting template behavior or guaranteed R70 problem response. It may supplement this layer later. |
| Tower built-in `RateLimitLayer` | First-party and low incremental cost | Implements readiness/backpressure, not keyed 429 admission control. |
| `tower_governor`/GCRA | Mature adapter and smoother burst behavior | Missing declared MSRV; no first-class distributed-store seam; default retry calculation truncates with `as_secs()` and must be replaced. |
| Direct `governor` plus local Tower adapter | Mature engine and complete response control | The template would own the most failure-prone middleware, cleanup, extraction and future backend integration code. |
| Store-pluggable fixed-window Tower middleware | Exact Memory/Redis seam, straightforward reset time, framework-neutral within Tower | Young crate and fixed-window boundary bursts. |
| Fully hand-written fixed-window middleware | No young dependency | Recreates concurrency, eviction, key extraction, response and timing logic with a larger rewrite surface. |

**Selected implementation**

Use `tower-rate-limiter` 0.1.6 with only its `memory` feature. Its public pattern explicitly injects `MemoryStore`, documents it as process-local, offers Redis/custom stores through the same builder, supports custom responses, and has generic Tower plus Axum examples. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6/source/README.md))

Do **not** add a Cargo feature named `rate-limit`. Cargo features are compile-time dependency selection; operational enablement must remain a runtime decision so one already-built binary can be started in either mode. Compile the memory implementation into the web service and conditionally register the layer from `Option<RateLimitSpec>`.

Recommended setting:

```text
RS_LAUNCH_RATE_LIMIT=<requests>/<window>
```

Examples:

```text
# absent or empty: disabled
RS_LAUNCH_RATE_LIMIT=100/60s
RS_LAUNCH_RATE_LIMIT=5/1m
```

A non-empty invalid value is a startup configuration error; it must not silently disable the protection.

Recommended dependency:

```toml
[dependencies]
tower-rate-limiter = {
    version = "=0.1.6",
    default-features = false,
    features = ["memory"],
}
```

The exact pin contains pre-1.0 API and MSRV movement. It belongs in the web-service crate, not the reusable public library crate.

The startup composition is:

```rust
let rate_limit = settings
    .rate_limit
    .as_ref()
    .map(|spec| {
        RateLimitLayer::builder(IpKeyExtractor::new())
            .policy_name("public-http")
            .limit(spec.requests)
            .window(spec.window)
            .with_store(MemoryStore::new())
            .response_factory(problem_response_factory.clone())
            .build()
    })
    .transpose()?;

let app = ServiceBuilder::new()
    .option_layer(rate_limit)
    .service(app);
```

The builder calls above follow the crate’s documented API. Registration may instead be an `if let Some(layer)` branch if R69’s framework preserves one router type across conditional `.layer(...)` calls. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6))

Use the peer socket address as the safe initial key. Forwarded client-IP headers must not become authoritative unless R69 or deployment configuration establishes a trusted-proxy boundary; the crate itself warns that header-derived identity is safe only when the proxy removes or overwrites accepted headers. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6/source/README.md))

**429 and R70 integration**

The crate’s builder accepts a custom `ResponseFactory`, and exposes structured `ResponseReason` and `Usage` types. R74 should therefore generate the 429 directly through a small adapter calling R70’s reusable problem-response constructor. It should not depend on an outer handler-error interceptor: the limiter short-circuits with a normal HTTP response before a handler error exists. ([docs.rs](https://docs.rs/tower-rate-limiter/latest/tower_rate_limiter/limiter/index.html))

The exact variant names are intentionally deferred until R70’s body type is known, but the core computation is fixed:

```rust
fn retry_after_seconds(reset_after: Duration) -> u64 {
    reset_after
        .as_secs()
        .saturating_add(u64::from(reset_after.subsec_nanos() != 0))
        .max(1)
}
```

The response factory must:

1. obtain the denied policy’s `reset_after` from the crate’s returned usage;
2. compute the integral delay by ceiling, as above;
3. call the R70 problem constructor with status 429;
4. set `Retry-After` to that same integer;
5. return the response directly.

Ceiling is required because HTTP delay-seconds is integral. Flooring a 1.2-second wait to `1` tells the client to retry before admission is possible; ceiling overstates by less than one second but never understates the current reset duration. RFC 6585 permits `Retry-After` on 429, and RFC 9110 defines the header representation. ([rfc-editor.org](https://www.rfc-editor.org/rfc/rfc9110.html))

`tower-rate-limiter` advertises a default 429 with `Retry-After`, but the recommendation does not rely on undocumented rounding behavior. The custom factory plus a contract test is part of the selected bundle. ([github.com](https://github.com/nivek-ph/tower-rate-limiter))

**Performance evaluation**

The selected memory path performs no network I/O and does not require Tokio through its normal selected features; the manifest uses synchronous Moka for `MemoryStore`. Its expected cost is key extraction, policy resolution and an in-process cache operation. This should be characterized rather than compared against unrelated Redis or algorithm benchmarks. ([github.com](https://github.com/nivek3/tower-rate-limiter/blob/main/Cargo.toml))

The upstream repository includes a Docker Compose benchmark harness with an isolated benchmark server, optional `wrk` generator, raw outputs and summaries, but no trustworthy published result was available to use as a selection claim. ([github.com](https://github.com/nivek-ph/tower-rate-limiter))

The template benchmark should compare disabled versus enabled memory limiting using the same release binary and:

- a no-op/204 route;
- 1, 32 and 256 concurrent connections;
- one hot key and 10,000-key cardinality;
- an all-admitted quota and a mostly-rejected quota;
- 60-second measured runs after warm-up;
- request throughput, p50/p95/p99 latency, CPU, RSS, allocation rate and store cardinality;
- compile timings and release-binary delta.

No absolute-fastest claim is made.

**Algorithm tradeoff**

A fixed window can admit nearly twice the nominal count across a window boundary. For example, 100 requests immediately before reset and 100 immediately after reset can all succeed. That is acceptable for this optional template guard because it keeps `Retry-After` and the distributed-store seam simple. A future requirement for strict smoothing is a re-verification trigger for a GCRA/token-bucket design, not a silent library substitution.

**Observable acceptance criteria**

- Absent/empty `RS_LAUNCH_RATE_LIMIT`: layer absent; repeated requests are not rate-limited.
- `RS_LAUNCH_RATE_LIMIT=2/2s`: first two requests for a key succeed, third is 429.
- The third response has one decimal-integer `Retry-After`, greater than zero and no greater than the remaining configured window.
- Waiting the advertised number of seconds allows a subsequent request, barring a concurrent request for the same key.
- A synthetic 1.000000001-second reset encodes as `2`, proving ceiling rather than truncation.
- Invalid non-empty config terminates startup with a configuration error.
- Two separately started processes have independent counters.
- After R70 integration, 429 has `application/problem+json` and retains the R74-computed header.
- The dependency tree builds and tests under Rust 1.96.0 and current stable on both required OSes.
- The selected dependency tree passes advisory/license checks; its unsafe footprint is recorded.
- A high-cardinality test demonstrates a bounded store or blocks adoption until an explicit capacity can be configured.

`BASELINE-REVIEW: F323 — Retry-After must never direct a client to retry before the limiter can admit it — require an application-owned ceil-to-seconds helper and contract test instead of inheriting a crate default — RFC 9110 permits integral delay-seconds, while tower_governor 0.8.0 derives its header through Duration::as_secs() truncation. Affects R74’s response adapter only; R70 retains ownership of the problem envelope.` ([rfc-editor.org](https://www.rfc-editor.org/rfc/rfc9110.html))

### Recommendation

**ADOPT, subject to the pre-merge fitness checks below.**

One stack:

- **Middleware/store:** `tower-rate-limiter = "=0.1.6"`, `default-features = false`, `features = ["memory"]`.
- **Service model:** Tower 0.5-compatible layer registration supplied by R69.
- **Runtime gate:** optional `RS_LAUNCH_RATE_LIMIT`; absent/empty means disabled.
- **Store:** one application-wide `tower_rate_limiter::MemoryStore`, explicitly documented as process-local and single-instance-by-design.
- **Key:** authoritative peer `SocketAddr` initially; no untrusted forwarded-header fallback.
- **429 path:** custom `ResponseFactory` calling R70’s reusable problem constructor.
- **`Retry-After`:** application-owned ceiling of the rejected usage’s remaining reset duration.
- **Future distributed swap:** replace only `.with_store(MemoryStore::new())` with the crate’s Redis or another `Store`; do not change config gating or HTTP behavior.
- **No runtime enablement feature flag.**

This chooses architectural fit over the more popular governor adapter while containing the young-crate risk through an exact version pin, a local response adapter and executable acceptance tests.

### Members

#### tower-rate-limiter 0.1.6

##### Landscape

`tower-rate-limiter` is an active but early Tower-first fixed-window middleware. It exposes explicit Memory, Redis and custom Store implementations, custom keys and responses, and optional Axum integration. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6))

Required figures, retrieved September 18, 2026:

| Figure | Value | Required source |
|---|---|---|
| 90-day downloads | **Not retrieved**; do not substitute an estimate | `GET https://crates.io/api/v1/crates/tower-rate-limiter` → `crate.recent_downloads` |
| All-time downloads | **Not retrieved** | same endpoint → `crate.downloads` |
| Last release | `0.1.6`; exact `created_at` not retrieved | `GET https://crates.io/api/v1/crates/tower-rate-limiter/versions`; docs.rs independently confirms 0.1.6. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6)) |
| Stars | API value not retrieved; GitHub HTML fallback: **6** | `GET https://api.github.com/repos/nivek3/tower-rate-limiter`; fallback repository page. ([github.com](https://github.com/nivek-ph/tower-rate-limiter)) |
| Archived | API value not retrieved; no archived banner visible | same endpoint |
| `pushed_at` | Not retrieved | same endpoint |
| Open issues | API value not retrieved; GitHub HTML fallback: **1** | `GET https://api.github.com/search/issues?q=repo:nivek3/tower-rate-limiter+is:issue+is:open`; fallback repository page. ([github.com](https://github.com/nivek-ph/tower-rate-limiter)) |
| Issue responsiveness | Not retrieved; median and unanswered count remain required | Ten most recently opened non-PR issues plus first OWNER/MEMBER/COLLABORATOR response |
| Advisories | No matching package page was retrieved; full-tree audit not run | RustSec package index plus `cargo deny check advisories`. ([rustsec.org](https://rustsec.org/packages/)) |
| Adopters | No relevant production adopter verified | crates.io reverse dependencies plus adopter `Cargo.toml` |
| Maintenance state | **active** | Current 0.1.6 package, 42 commits, two open PRs and one open issue. ([github.com](https://github.com/nivek-ph/tower-rate-limiter)) |

##### Principles and implementation

This member realizes the central pattern rather than merely supplying an algorithm:

- `MemoryStore` makes process-local scope explicit.
- `Store` and `RedisStore` provide the named scale-out seam.
- `ResponseFactory`, `ResponseReason` and `Usage` provide an adapter point for R70 and accurate reset-based backoff.
- Generic Tower support prevents an unnecessary hard dependency on Axum.
- Fixed-window behavior aligns naturally with a `<requests>/<window>` setting. ([docs.rs](https://docs.rs/tower-rate-limiter/latest/tower_rate_limiter/limiter/index.html))

##### Dominant choice

The ecosystem incumbent is `governor` with `tower_governor`, not this crate. The incumbent has substantially more community history and adoption. It loses this decision because its Tower adapter does not meet the owner’s declared-MSRV evidence gate and does not offer an equivalent distributed Store seam. ([github.com](https://github.com/boinkor-net/governor))

##### Qualified shortlist

1. `tower-rate-limiter` 0.1.6 — best architectural fit; low maturity.
2. `tower_governor` 0.8.0 — mature Tower adapter; blocked by MSRV declaration and retry rounding.
3. `governor` 0.10.4 plus a local layer — mature engine; excessive application-owned HTTP/store code.
4. `axum-governor` 2.1.0 — strong if R69 selects Axum; premature framework coupling today.

##### Excluded by gate

- **Tower built-in limiter:** capability failure—no keyed HTTP rejection/store abstraction. ([docs.rs](https://docs.rs/tower/latest/tower/limit/rate/struct.RateLimit.html))
- **`tower_governor` 0.8.0:** no `rust-version` declaration in its current manifest; default retry path truncates duration. ([github.com](https://github.com/benwis/tower-governor/blob/main/Cargo.toml))
- **`governor` plus custom layer:** dependency-tree MSRV and OS evidence incomplete, and it moves middleware correctness into template-owned code.
- **`axum-governor` 2.1.0:** unconditional selection would pre-decide R69; its defaults also bring Axum, Tokio, DashMap, tracing and JSON. ([docs.rs](https://docs.rs/crate/axum-governor/latest))
- **FlowShield:** its facade still describes the public API as being built and pre-stabilization; insufficient production evidence for this high-rewrite-cost decision. ([docs.rs](https://docs.rs/flowshield/latest/flowshield/index.html))

##### Up-and-comers

`axum-governor` is the strongest alternate up-and-comer, with stacked policies, per-tier overrides, background GC, custom bodies and a problem+json preset. It should be reconsidered only if R69 definitively selects Axum and a distributed-store swap ceases to be required. ([docs.rs](https://docs.rs/crate/axum-governor/latest))

FlowShield has a more ambitious bounded/sharded memory design and separate Redis backend, but its own facade documentation describes an unfinished public API. ([docs.rs](https://docs.rs/flowshield/latest/flowshield/index.html))

##### Fit for this template

**Fit: high functionally, medium overall.**

- CLI and reusable library remain unaffected because the dependency belongs only to the web-service crate.
- Runtime gating avoids separate artifacts.
- The memory-only feature has no normal Tokio dependency.
- Tower compatibility fits Axum/Hyper/Tonic-style R69 outcomes.
- The explicit store boundary matches the Python precedent better than governor’s embedded in-memory state.
- Its small community and unverified adopter base require stronger local tests than a mature dependency would.

##### Recommendation

```toml
tower-rate-limiter = {
    version = "=0.1.6",
    default-features = false,
    features = ["memory"],
}
```

Construct `MemoryStore` exactly once during web application startup. Do not place it in request state in a way that rebuilds or independently clones limiter state per route.

Keep the third-party types behind:

```text
src/web/rate_limit.rs
```

Only that module should import `tower_rate_limiter`; settings, handlers and the public library should depend on application-owned `RateLimitSpec` and response helpers.

##### Ranked runner-up

**`tower_governor` 0.8.0 with `default-features = false` and a custom error handler.**

It is the runner-up because it is proven across multiple Tower hosts and uses mature GCRA behavior. It becomes selectable only if it:

1. declares an MSRV compatible with the template floor;
2. is tested in the required OS matrix;
3. passes the advisory/unsafe checks; and
4. replaces its truncating retry calculation with the same application-owned ceiling helper.

Its current custom error-handler facility is sufficient to reach an R70 response constructor. ([docs.rs](https://docs.rs/crate/tower_governor/latest))

##### Tradeoffs

- Fixed windows permit boundary bursts; GCRA is smoother.
- The crate is 0.1.x and may make relatively rapid API changes.
- Moka increases compile time and binary size relative to a small hand-written map.
- Exact pinning requires deliberate dependency updates.
- Store failure semantics become more significant if Redis is adopted later.
- Upstream OS, unsafe and full dependency-MSRV evidence was incomplete in this research run.
- In return, the design avoids local implementation of concurrency, reset accounting, client-IP extraction and distributed-store plumbing.

##### Parameters

```text
package version = =0.1.6
default-features = false
features = ["memory"]
runtime gate = RS_LAUNCH_RATE_LIMIT
default runtime value = absent / disabled
store type = tower_rate_limiter::MemoryStore
algorithm = fixed window
deployment scope = one process
```

No member-level conflict with owner-fixed parameters is known.

##### Migration implications

- Add the dependency only to the web-service package.
- Add an application-owned `RateLimitSpec` parser.
- Add the layer/store constructor and R70 response adapter.
- Replace any direct crate imports in `app.rs` with one `rate_limit::build(...)` call.
- Add a commented example to `.env.example`; do not assign a default.
- Document that replica count multiplies effective quota.
- Pin the exact package until its API and MSRV policy mature.

##### Validation strategy

Planned, not executed:

```bash
cargo +1.96.0 check --locked --workspace --all-targets
cargo +1.96.0 test  --locked --workspace
cargo +stable check --locked --workspace --all-targets
cargo +stable test  --locked --workspace

cargo deny check advisories licenses bans sources
cargo geiger --workspace --no-default-features --features memory
```

Run the first four commands on both `ubuntu-latest` and `macos-latest`.

Crate-specific contract tests must cover:

```text
Duration::ZERO       -> 1
1 nanosecond          -> 1
1 second              -> 1
1 second + 1 ns       -> 2
1500 milliseconds     -> 2
```

Use a fake `Store` or response reason to make these tests deterministic, then run a separate real-`MemoryStore` integration test.

##### Confidence & re-verify trigger

**Confidence: medium.** Architectural fit is high; maturity and metric completeness are not.

Re-verify if:

- R69 chooses a non-Tower framework;
- R70 cannot expose a reusable response/problem constructor;
- any version newer than 0.1.6 is proposed;
- stable Rust advances and the template floor changes;
- an advisory appears in this tree;
- the crate fails macOS or Rust 1.96;
- its default/custom response path overwrites the application’s calculated header;
- the memory store cannot be explicitly bounded;
- multi-instance deployment becomes a default supported topology;
- a smoothed/token-bucket policy becomes an owner requirement.

##### Sources

- Current package manifest, feature set, license, edition, MSRV and dependencies. ([github.com](https://github.com/nivek3/tower-rate-limiter/blob/main/Cargo.toml))
- Pinned 1.96 toolchain. ([github.com](https://github.com/nivek3/tower-rate-limiter/blob/main/rust-toolchain.toml))
- Maintainer README, store choices, proxy warning and examples. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6/source/README.md))
- `ResponseFactory`, `ResponseReason`, `MemoryStore` and `Usage` API documentation. ([docs.rs](https://docs.rs/tower-rate-limiter/0.1.6/tower_rate_limiter/trait.ResponseFactory.html))
- Benchmark harness evidence. ([github.com](https://github.com/nivek-ph/tower-rate-limiter))
- Repository activity fallback. ([github.com](https://github.com/nivek-ph/tower-rate-limiter))

### Compatibility

The selected member is a single direct crate, but its maintained repository proves the relevant version family together:

- `tower-rate-limiter` 0.1.6 directly uses `tower-layer` 0.3 and `tower-service` 0.3.
- Its dev matrix uses Tower 0.5 and Axum 0.8.
- Published examples include generic Tower memory, dynamic quotas, Axum memory, trusted-proxy extraction and Axum Redis.
- The memory feature is independent of Redis runtime features; Redis can later select Tokio or Smol explicitly. ([github.com](https://github.com/nivek3/tower-rate-limiter/blob/main/Cargo.toml))

That is adequate compatibility evidence for a Tower 0.5/Axum 0.8 R69 outcome. It is not proof for a future Tower major version or a non-Tower framework.

### Parameters

```text
owns none

assumes rust-edition = 2024
assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
assumes license = MIT OR Apache-2.0
assumes target-os-matrix = ubuntu-latest, macos-latest

assumes R69 web-framework-stack = exposes Tower 0.5 Layer/Service compatibility or supplies a thin adapter
assumes R70 http-problem-envelope = exposes a reusable problem-response constructor usable outside handlers
assumes R75 http-middleware-stack = assigns the final ordering position
```

No `CONFLICT:` is currently required. If R69 selects a web framework without a Tower-compatible service boundary, R74 must be reopened rather than silently importing Axum or changing R69.

### Migration implications

Proposed file-level changes:

```text
Cargo.toml
  Add exact, memory-only tower-rate-limiter dependency to web package.

src/web/settings.rs
  Add rate_limit: Option<RateLimitSpec>.
  Map RS_LAUNCH_RATE_LIMIT absent/empty to None.
  Reject malformed non-empty values during startup.

src/web/rate_limit.rs
  Add RateLimitSpec and parser.
  Add retry_after_seconds(Duration).
  Build one MemoryStore and RateLimitLayer.
  Add custom R70-compatible ResponseFactory.
  Keep every tower_rate_limiter import in this module.

src/web/app.rs
  Call rate_limit::build(...).
  Register the returned optional layer conditionally.
  Do not construct limiter state per route or request.

src/web/problem.rs or R70-selected module
  Expose a reusable problem-response constructor.
  Do not move Retry-After computation into the generic problem module.

.env.example
  Add only a commented example:
  # RS_LAUNCH_RATE_LIMIT=100/60s

docs/configuration.md
  Document syntax, absent default and startup validation.

docs/operations/rate-limiting.md
  State explicitly:
  - process-local counters;
  - replicas do not share quotas;
  - effective aggregate quota grows with replica count;
  - MemoryStore is the intended initial implementation;
  - the constructor is the future Redis/custom Store swap point;
  - forwarded headers require a trusted proxy.

tests/web_rate_limit.rs
  Add disabled, enabled, invalid-config, retry rounding, expiry,
  independent-process and problem-envelope tests.

.github/workflows/ci.yml
  Exercise stable and 1.96.0 on ubuntu-latest and macos-latest.
```

No CLI or public-library API needs to expose the third-party crate.

### Validation strategy

**Execution status:** no commands below were run against `rs-launch-blueprint`; they are proposed acceptance checks.

**1. Close the missing ecosystem figures**

```bash
curl -fsS \
  -H 'User-Agent: rs-launch-blueprint-research/1' \
  https://crates.io/api/v1/crates/tower-rate-limiter |
jq '.crate | {recent_downloads, downloads}'

curl -fsS \
  -H 'User-Agent: rs-launch-blueprint-research/1' \
  https://crates.io/api/v1/crates/tower-rate-limiter/versions |
jq '[.versions[] | select(.yanked == false)]
    | sort_by(.created_at)
    | last
    | {num, created_at}'

gh api repos/nivek3/tower-rate-limiter \
  --jq '{stargazers_count, archived, pushed_at}'

gh api search/issues \
  -f q='repo:nivek3/tower-rate-limiter is:issue is:open' \
  --jq '{total_count}'
```

For responsiveness, retrieve the ten most recently opened non-PR issues, find the first comment whose `author_association` is `OWNER`, `MEMBER` or `COLLABORATOR`, then report median elapsed days and unanswered count. Store the raw JSON with the research artifact.

**2. Dependency and platform gates**

```bash
cargo +1.96.0 check --locked --workspace --all-targets
cargo +1.96.0 test  --locked --workspace
cargo +stable check --locked --workspace --all-targets
cargo +stable test  --locked --workspace

cargo tree -e features
cargo deny check advisories licenses bans sources
cargo geiger --workspace
```

Expected: every command succeeds on `ubuntu-latest` and `macos-latest`; the resolved tree contains no dependency requiring Rust newer than 1.96.0; no incompatible license or open advisory exists; unsafe usage is recorded and reviewed.

**3. Same-binary runtime gate**

Build once:

```bash
cargo build --locked --bin <web-bin>
```

Run without the setting:

```bash
env -u RS_LAUNCH_RATE_LIMIT \
  target/debug/<web-bin>
```

Expected: the service starts, no rate-limit-enabled startup event is emitted, and repeated requests remain non-429.

Run the same artifact with:

```bash
RS_LAUNCH_RATE_LIMIT=2/2s \
  target/debug/<web-bin>
```

Expected for one client key:

```text
request 1 -> non-429
request 2 -> non-429
request 3 -> 429
Retry-After -> decimal integer in 1..=2
```

After sleeping for the advertised value, the next request must succeed unless another request consumed the quota.

**4. Invalid setting**

```bash
RS_LAUNCH_RATE_LIMIT=garbage \
  target/debug/<web-bin>
```

Expected: non-zero startup exit and a configuration diagnostic naming `RS_LAUNCH_RATE_LIMIT`; it must not start with limiting disabled.

**5. Accurate header unit contract**

```rust
assert_eq!(retry_after_seconds(Duration::ZERO), 1);
assert_eq!(retry_after_seconds(Duration::from_nanos(1)), 1);
assert_eq!(retry_after_seconds(Duration::from_secs(1)), 1);
assert_eq!(
    retry_after_seconds(Duration::from_secs(1) + Duration::from_nanos(1)),
    2
);
assert_eq!(retry_after_seconds(Duration::from_millis(1500)), 2);
```

Use a fake store/decision with `reset_after = 1500ms`; expected final response is 429 with `Retry-After: 2`. This catches both static-window responses and `as_secs()` truncation.

**6. R70 integration**

Expected after R70 lands:

```text
status = 429
Content-Type = application/problem+json
Retry-After = value produced by R74 helper
body = R70-selected problem shape
```

The test must invoke the composed service rather than directly testing the factory, proving short-circuit responses still pass through the required response finalization.

**7. Single-instance-by-design proof**

Start process A and process B on separate ports with the same `2/60s` setting:

1. consume A’s two requests;
2. verify A’s third request is 429;
3. verify B’s first request still succeeds.

This is an acceptance criterion, not a defect: it proves the documentation accurately describes local state.

**8. Cardinality/resource test**

Generate at least 100,000 distinct peer keys. Record store cardinality, RSS and post-expiry reclamation. Do not merge if the selected construction permits unbounded growth without an explicit capacity or eviction policy.

**9. Representative performance characterization**

Compare disabled and enabled runs of the same release binary:

```text
duration:          60 seconds after warm-up
concurrency:       1, 32, 256
key distributions: one hot key; 10,000 uniformly distributed keys
policies:          all admitted; approximately 95% rejected
route:             no-op 204 response
measure:           req/s, p50/p95/p99, CPU, RSS, allocations, store size
```

Also compare:

```bash
cargo clean
cargo build --release --timings
cargo bloat --release --bin <web-bin> --crates
```

No candidate should be declared “fastest” from the result; the purpose is to quantify the selected memory layer’s cost under this template’s workload.

### Confidence & re-verify trigger

**Overall confidence: medium.**

- **High confidence:** runtime conditional registration is preferable to a behavior feature flag; explicit process-local state and reset-based 429 responses preserve the source principles.
- **High confidence:** Tower’s middleware model is appropriate if R69 selects Axum or another Tower host.
- **Medium confidence:** `tower-rate-limiter` is the best current architectural fit.
- **Low-to-medium confidence:** its ecosystem maturity, exact download/adopter figures, upstream OS matrix and full dependency safety/MSRV posture.

The recommendation becomes implementation-ready only after the required API figures and planned fitness commands are recorded.

Reopen R74 if any of these occur:

- R69 selects a non-Tower framework.
- R70 cannot be called from middleware short-circuit code.
- `tower-rate-limiter` 0.1.6 fails Rust 1.96, macOS, advisory, license, unsafe or cardinality checks.
- A new crate release changes `Store`, `Usage`, `ResponseFactory`, reset semantics, MSRV or default features.
- An advisory affects the selected tree.
- Multi-replica shared quotas become a default requirement.
- Fixed-window boundary bursts are no longer acceptable.
- A maintained, substantially adopted Tower middleware provides the same explicit Memory/Redis seam and stronger evidence.

### Sources

All retrieved September 18, 2026.

- Rust stable release and schedule: Rust Forge and official release archive. ([forge.rust-lang.org](https://forge.rust-lang.org/))
- Cargo `rust-version` guidance. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/rust-version.html))
- Tower architecture, MSRV and repository standing. ([tower-rs.github.io](https://tower-rs.github.io/tower/tower/))
- Axum’s first-party Tower middleware model. ([github.com](https://github.com/tokio-rs/axum/blob/main/axum/src/docs/middleware.md))
- Tower built-in rate limiter and its service-level semantics. ([docs.rs](https://docs.rs/tower/latest/tower/limit/rate/struct.RateLimit.html))
- `tower-rate-limiter` package, manifest, examples, stores and repository. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6))
- `tower-rate-limiter` response/store API. ([docs.rs](https://docs.rs/tower-rate-limiter/0.1.6/tower_rate_limiter/trait.ResponseFactory.html))
- `tower-rate-limiter` benchmark harness. ([github.com](https://github.com/nivek-ph/tower-rate-limiter))
- `tower_governor` package, manifest, error customization and retry implementation. ([docs.rs](https://docs.rs/crate/tower_governor/latest))
- `governor` engine and repository. ([docs.rs](https://docs.rs/governor/latest/governor/))
- `axum-governor` package and feature set. ([docs.rs](https://docs.rs/crate/axum-governor/latest))
- FlowShield’s current maturity and storage architecture. ([docs.rs](https://docs.rs/flowshield/latest/flowshield/index.html))
- Practice evidence from Buck2, Restate, Helix and Tangled manifests. ([github.com](https://github.com/facebook/buck2/blob/main/shim/third-party/rust/Cargo.toml))
- RFC 6585 HTTP 429 and RFC 9110 `Retry-After`. ([rfc-editor.org](https://www.rfc-editor.org/rfc/rfc9110.html))
- RustSec package index. ([rustsec.org](https://rustsec.org/packages/))

## Sources

- [https://docs.rs/tower/latest/tower/limit/rate/struct.RateLimit.html](https://docs.rs/tower/latest/tower/limit/rate/struct.RateLimit.html)
- [https://docs.rs/governor/latest/governor/](https://docs.rs/governor/latest/governor/)
- [https://docs.rs/crate/tower-rate-limiter/0.1.6](https://docs.rs/crate/tower-rate-limiter/0.1.6)
- [https://forge.rust-lang.org/](https://forge.rust-lang.org/)
- [https://github.com/tokio-rs/axum/blob/main/axum/src/docs/middleware.md](https://github.com/tokio-rs/axum/blob/main/axum/src/docs/middleware.md)
- [https://www.rfc-editor.org/rfc/rfc9110.html](https://www.rfc-editor.org/rfc/rfc9110.html)
- [https://github.com/nivek3/tower-rate-limiter/blob/main/Cargo.toml](https://github.com/nivek3/tower-rate-limiter/blob/main/Cargo.toml)
- [https://github.com/facebook/buck2/blob/main/shim/third-party/rust/Cargo.toml](https://github.com/facebook/buck2/blob/main/shim/third-party/rust/Cargo.toml)
- [https://github.com/benwis/tower-governor/blob/main/Cargo.toml](https://github.com/benwis/tower-governor/blob/main/Cargo.toml)
- [https://docs.rs/crate/axum-governor/latest](https://docs.rs/crate/axum-governor/latest)
- [https://github.com/benwis/tower-governor](https://github.com/benwis/tower-governor)
- [https://github.com/boinkor-net/governor](https://github.com/boinkor-net/governor)
- [https://github.com/nivek-ph/tower-rate-limiter](https://github.com/nivek-ph/tower-rate-limiter)
- [https://www.reddit.com/r/rust/comments/1h77a9w](https://www.reddit.com/r/rust/comments/1h77a9w)
- [https://docs.rs/crate/tower-rate-limiter/0.1.6/source/README.md](https://docs.rs/crate/tower-rate-limiter/0.1.6/source/README.md)
- [https://docs.rs/tower-rate-limiter/latest/tower_rate_limiter/limiter/index.html](https://docs.rs/tower-rate-limiter/latest/tower_rate_limiter/limiter/index.html)
- [https://rustsec.org/packages/](https://rustsec.org/packages/)
- [https://docs.rs/flowshield/latest/flowshield/index.html](https://docs.rs/flowshield/latest/flowshield/index.html)
- [https://docs.rs/crate/tower_governor/latest](https://docs.rs/crate/tower_governor/latest)
- [https://github.com/nivek3/tower-rate-limiter/blob/main/rust-toolchain.toml](https://github.com/nivek3/tower-rate-limiter/blob/main/rust-toolchain.toml)
- [https://docs.rs/tower-rate-limiter/0.1.6/tower_rate_limiter/trait.ResponseFactory.html](https://docs.rs/tower-rate-limiter/0.1.6/tower_rate_limiter/trait.ResponseFactory.html)
- [https://doc.rust-lang.org/cargo/reference/rust-version.html](https://doc.rust-lang.org/cargo/reference/rust-version.html)
- [https://tower-rs.github.io/tower/tower/](https://tower-rs.github.io/tower/tower/)
