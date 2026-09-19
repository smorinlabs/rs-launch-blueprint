# R73 — idempotency-middleware (bundle, Deep) — Opus raw research report

Engine: Claude Opus 5. Run `research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/`.
All retrieval dates are UTC. Every figure names the endpoint it came from. The
Codex leg is deferred under owner ruling W1-CODEX3 (2026-09-18); this report is
written to stand alone.

### Landscape

**The category this item decides.** Not "a cache". The category is *at-most-once
execution of an unsafe HTTP method under client retry*: a request-scoped
concurrency-control-and-replay mechanism whose visible contract is a request
header, four error statuses, and a durable-enough record of one completed
operation. The store is an implementation of that contract, not the contract.
Naming the category this way is what makes the three-bin map below come out the
way it does: the Rust field has no packaged answer to *the contract*, and a
crowded field of answers to *the store*.

**The three-bin map.**

| Bin | Candidates found | What the bin actually contains |
|---|---|---|
| Built-in / first-party toolchain | `axum` 0.8.9 `middleware::from_fn` / `from_fn_with_state`; `axum::body::to_bytes`; `http::HeaderMap` multi-value semantics; `std::sync::Mutex` + `std::collections::HashMap`; `tower-http` 0.6 layer set | axum gives the *shape* of a response-inspecting layer with state and no `tower` dependency line. `tower-http` has no idempotency layer: its published set is `Trace`, `Compression`, `Cors`, `Timeout`, `RequestBodyLimit`, `SetRequestId`/`PropagateRequestId`, `NormalizePath`, `CatchPanic`, `SetSensitiveHeaders`, `SetResponseHeader`, `ServeDir`/`ServeFile` (owner reference, *Level One*). |
| Established industry standard (as a *pattern*, not a crate) | Stripe's published idempotency contract; IETF `draft-ietf-httpapi-idempotency-key-header-07`; *Zero To Production in Rust* `src/idempotency/` (Postgres, actix-web); Adyen, Dwolla, WorldPay, Yandex, `http4s` (the draft's own Implementation Status register) | The pattern is standardised in practice and half-standardised on paper. No Rust crate implements it generically. |
| Up-and-comer (crates) | `axum-idempotent` 0.3.0; `actix-idempotent` 0.1.1; `sova-idempotency` 0.1.1; `minco-plugin-idempotency` 1.12.0; `kcode-kweb-idempotency` 0.1.1; `idempotent` 2.0.0; `bhatti/idempotency-rs` (unpublished sample) | Five of the six crates are framework- or product-bound. The largest, `axum-idempotent`, has 249 90-day downloads and 5 GitHub stars. |
| Up-and-comer (stores, for the swap-point member) | `moka` 0.12.16, `mini-moka` 0.10.3, `quick_cache` 0.7.0, `lru` 0.18.4, `hashlink` 0.12.2, `schnellru` 0.2.4 | A healthy, well-adopted field — for *caching*. None of them expresses an in-flight marker or a compare-and-set, which is the part this item cannot do without. |

Search endpoints: `GET https://crates.io/api/v1/crates?q=idempotency&per_page=30`,
`?q=idempotent`, `?q=idempotency+middleware`, `?q=axum+idempotency`,
`?q=tower+idempotency`, `?q=idempotency-key+header`, all retrieved
2026-09-18. Every candidate named above came off those six result pages plus the
owner reference document's own stack table; none came from familiarity.

**Authorities used, and why each is an authority.**

| Source | Why it counts | Retrieved |
|---|---|---|
| `draft-ietf-httpapi-idempotency-key-header-07`, `https://www.ietf.org/archive/id/draft-ietf-httpapi-idempotency-key-header-07.txt`, and its datatracker page `https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/` | IETF **httpapi** working-group output — the only cross-vendor specification of this header. Status matters and is reported honestly: revision **-07**, dated **October 2025**, *expired 18 April 2026* and shown by datatracker as "Expired & archived", intended status "(None)". It is the best available normative sketch, **not** an RFC. | 2026-09-18 |
| RFC 9110 §9.2.2, `https://www.rfc-editor.org/rfc/rfc9110.txt` | The HTTP semantics standard; defines which methods are idempotent by specification. | 2026-09-18 |
| Stripe API reference, `https://docs.stripe.com/api/idempotent_requests` | The maintainer's own documentation for the implementation the draft lists first, and the implementation py's source comment names. Primary, not secondhand. | 2026-09-18 |
| `LukeMathWalker/zero-to-production` `src/idempotency/{key,persistence,mod}.rs`, `https://raw.githubusercontent.com/LukeMathWalker/zero-to-production/main/src/idempotency/persistence.rs` | The companion repository of *Zero To Production in Rust*, the most widely recommended Rust backend text; **6,539 stars**, 585 forks, Apache-2.0, not archived (`GET https://api.github.com/repos/LukeMathWalker/zero-to-production`, 2026-09-18). Its chapter 11 is the canonical Rust treatment of this exact problem. | 2026-09-18 |
| tokio maintainers' documentation, `https://docs.rs/tokio/1.53.1/tokio/sync/struct.Mutex.html` | The runtime's own guidance on blocking-versus-async mutexes, which decides whether the store call needs `spawn_blocking`. | 2026-09-18 |
| Rust standard library documentation, `https://doc.rust-lang.org/std/hash/struct.DefaultHasher.html` | The language's own statement that `DefaultHasher` is not stable across releases — the reason a fingerprint needs a crate. | 2026-09-18 |
| RustSec advisory database, `https://rustsec.org/packages/<name>.html` and `https://rustsec.org/advisories/<id>.html` | The Rust Secure Code WG's own database; gate 3. | 2026-09-18 |
| Owner reference, `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` | A STANDING INPUT under `docs/planning/p02/owner-decisions.md` §11 — an owner-supplied research input, binding on process (agree or differ on the record), not on outcome. | in-repo |

A single blog post was treated as a lead throughout: `bhatti/idempotency-rs` and
the `axum-idempotent` README are read as *design evidence* and are cited as such,
never as authority.

**Practice evidence — what well-regarded Rust projects actually do.**

1. **Zero To Production in Rust** (6,539 stars; the figure is the evidence of
   standing, together with 585 forks and an Apache-2.0 licence — `GET
   https://api.github.com/repos/LukeMathWalker/zero-to-production`, 2026-09-18)
   **hand-rolls** it. `src/idempotency/key.rs` is a validating newtype
   (non-empty, `< 50` characters). `src/idempotency/persistence.rs` stores
   `response_status_code`, a `Vec<HeaderPairRecord { name: String, value: Vec<u8> }>`
   and `response_body` — the same entry shape py uses. `try_processing` returns
   `NextAction::{StartProcessing(Transaction), ReturnSavedResponse(HttpResponse)}`
   from an `INSERT … ON CONFLICT DO NOTHING`: a **compare-and-set**, not a `get`
   followed by an `insert`. Its cache key is `(user_id, idempotency_key)` —
   **principal-scoped**, not path-scoped. It is called *inside the handler*, not
   as a layer. Last push 2024-09-01: a book's companion repository, quiet by
   design, cited here for its design, not proposed as a dependency.
2. **`bhatti/idempotency-rs`** — "a sample idempotency middleware for Rust web
   services, following battle-tested patterns from Stripe and AWS"
   (`https://raw.githubusercontent.com/bhatti/idempotency-rs/main/README.md`,
   2026-09-18). It independently converges on client-driven keys with UUID-v4
   validation, **request fingerprinting to prevent key reuse with different
   payloads**, atomic lock acquisition, **409 Conflict for concurrent requests**,
   24-hour retention, and `sha2` for the fingerprint. It is 1 star, last pushed
   2025-10-13, pinned to axum 0.7 and edition 2021, and **is not published**:
   `GET https://crates.io/api/v1/crates/idempotency-rs` returns **404**
   (2026-09-18). Convergent design evidence; not a candidate.
3. **`axum-idempotent` 0.3.0** is the only crates.io answer with any adoption and
   its adoption is small (figures under *Members*). Its own README states the
   ceiling: "Both modes are best-effort. The middleware forwards a request
   without idempotency handling when the session or the store is unavailable,
   and two identical requests that arrive concurrently can both reach the
   handler. Treat it as a retry safety net, not as a guarantee that a handler
   runs at most once."
   (`https://static.crates.io/crates/axum-idempotent/axum-idempotent-0.3.0.crate`,
   `README.md`, 2026-09-18.)
4. **`moka`** is the ecosystem's well-regarded in-process cache: 36,349,838
   90-day downloads, 127,021,020 all-time (`GET
   https://crates.io/api/v1/crates/moka`, 2026-09-18), 2,686 stars, not archived
   (`GET https://api.github.com/repos/moka-rs/moka`, 2026-09-18). It is cited
   here because it is the right thing to beat, not because it is a candidate.

**Fit lens (step 4).** The template is CLI + library + optional web service with
**no database, no sessions, no authentication and no Redis**, and the web surface
is an off-by-default Cargo feature. That fit lens is what disqualifies the one
crate with adoption — it requires a cookie session layer — and what makes the
owner reference's *Level One* instruction ("**Dropped as unnecessary:** a
dedicated in-process cache crate") the correct instruction for the store.

### Principles and implementation

**The shared requirement.** A client that cannot tell whether its unsafe request
took effect must be able to repeat it without repeating the effect, and must be
able to distinguish "your first attempt already succeeded, here is its result"
from "your first attempt is still running" from "you reused a key for a different
operation" from "that failed, try again for real".

**Source of the requirement and the level at which agreement is required.**

| Clause | Source | Agreement level | Must agree | May vary |
|---|---|---|---|---|
| Unsafe-method retries carry a client-generated key and replay the first outcome (F313) | py `src/py_launch_blueprint/web/idempotency.py:20-31,43,97-121` at pin `b08bccfb`; draft-07 §2, §2.6; Stripe | **capability** | that a keyed retry does not re-execute | header spelling is fixed by the draft; everything else — layer or handler call, store shape — varies |
| Only outcomes that are safe to replay are stored (F314) | py `:139-147`; see the `BASELINE-REVIEW` below | **policy** | that a failure a client can usefully retry is *not* pinned for the key's lifetime | which statuses qualify, and whether the rule is an allow-list or a deny-list |
| The store is in-memory, single-instance by design, and documented as a swap point (F315) | py `:26-30,91` | **architectural pattern** | that the store sits behind a named seam so the swap is an adapter change | the data structure entirely |
| Concurrency, key validation, payload fingerprinting | draft-07 §2.4, §2.7, §5; ZTP `try_processing`; `idempotency-rs` | **standard** (the draft names the statuses) | 400 / 409 / 422 as the draft assigns them | the fingerprint algorithm; how the in-flight state is represented |

py's own module docstring concedes the gap this item should close: "Concurrent
duplicates (second request arriving before the first finishes) are **NOT**
single-flighted; that also needs the shared store"
(`idempotency.py:29-30`). That is a statement about py's *store*, and it is only
true of py's store. A `std::sync::Mutex` makes check-and-set atomic within one
process for free, and this template is single-instance **by design**, so the
Rust design can close the gap py left open without adding anything.

**Is the pattern still appropriate in the target ecosystem?** Yes, and it gets
*stronger*, for a reason specific to Rust: py's middleware must do
`self._store.get(...)` and later `self._store[key] = ...` as two separate
`await`-free steps inside one coroutine, and correctness rests on the GIL and on
the event loop not interleaving between them. In Rust the port method is one
synchronous call that holds one lock across the whole decision, so "is this key
free, and if so claim it" is a single operation by construction. The pattern
ports; the concurrency hole does not.

**BASELINE-REVIEW: F314 — the rule is right and its recorded justification is
factually wrong — replace the row's parenthetical "(Stripe semantics: errors are
meant to be retried for real, not replayed)" with a justification that does not
rest on Stripe, and record that neither Stripe nor the IETF draft supports a
2xx-only rule — evidence: Stripe's own API reference states "Stripe's
idempotency works by saving the resulting status code and body of the first
request made for any given idempotency key, **regardless of whether it succeeds
or fails**. Subsequent requests with the same key return the same result,
including `500` errors" (`https://docs.stripe.com/api/idempotent_requests`,
retrieved 2026-09-18), and `draft-ietf-httpapi-idempotency-key-header-07` §2.6
says the resource "SHOULD respond with the result of the previously completed
operation, **success or an error**"
(`https://www.ietf.org/archive/id/draft-ietf-httpapi-idempotency-key-header-07.txt`,
retrieved 2026-09-18); the py comment this row quotes is at
`src/py_launch_blueprint/web/idempotency.py:139-141` at pin `b08bccfb`; affected
items R73 (this item, which keeps the behaviour on different grounds) and R70
(whose replayed-error envelope question disappears under the corrected rule)**

The behaviour survives the correction. Stripe can replay a failure because its
idempotency layer sits *inside* its request lifecycle and knows whether endpoint
execution began — its documentation says exactly that: "We save results only
after the execution of an endpoint begins. If incoming parameters fail
validation, or the request conflicts with another request that's executing
concurrently, we don't save the idempotent result because no API endpoint
initiates the execution. You can retry these requests." A generic layer wrapping
`next.run(req)` has no such knowledge. It cannot tell a deterministic 500 from a
transient one, so replaying 5xx would pin a transient failure for the whole TTL
and leave the client with no way to make progress — the client would receive the
same 500 for 24 hours no matter what it did. Under a 24-hour default TTL that
trade is clearly the wrong way round, and the 2xx-only rule is the one a layer
can actually justify. **What changes is the argument, not the code.**

**Architectural alternatives compared before any library was chosen.**

| Alternative | What it is | Verdict |
|---|---|---|
| **A1 — layer over a driven store port (recommended)** | an axum middleware function; the port is a `crates/core` trait; the shipped adapter is in-memory | Chosen. The replay decision is one place, applies to every unsafe route without per-handler code, and the swap point is a trait, so Redis is a new adapter and not a middleware rewrite. Costs: the request body must be buffered to fingerprint it, and the layer cannot see whether the handler's side effect committed. |
| **A2 — in-handler call (Zero To Production's shape)** | `try_processing(...)` called at the top of each handler; the transaction is carried into the write | Rejected for this template, adopted in spirit. It is *better* where a database exists, because the idempotency row and the side effect commit in one transaction — atomicity a layer cannot offer. This template has no database and no transaction to join, so the exchange buys nothing and costs per-handler boilerplate on every unsafe route plus a per-handler chance to forget. Its `NextAction` enum is adopted directly as the port's return type. |
| **A3 — an extractor** | an axum extractor that yields a claimed key | Rejected: an extractor runs before the handler and cannot see the response, so the store-write half has nowhere to live. |
| **A4 — a `tower::Layer`/`Service` pair by hand** | implement `Layer` and `Service` explicitly | Rejected on cost, not on correctness. It requires naming `tower` as a dependency, which R69's accepted revision 10 declines (`tower 0.5.3` is `crates/web`'s dev-dependency only), and it replaces one readable `async fn` with a manual `Poll::Ready` state machine. `from_fn_with_state` produces a genuine `tower::Layer` without the dependency line — proved by the probe, which compiles and passes 13 router tests with no `tower` entry in `[dependencies]`. |
| **A5 — adopt `axum-idempotent`** | the one crate with adoption | Rejected on fit; see *Members*, member 1, *Ranked runner-up*. |

**The recommended design, clause by clause, and how each preserves a principle.**
Named `idempotency-replay/v1` so later items can refer to it in one phrase.

1. **Scope.** `POST`, `PUT`, `PATCH` only; every other method passes through
   untouched even when it carries the header. This mirrors py `:45,98` and is
   *deliberately wider than RFC 9110 §9.2.2*, which says "PUT, DELETE, and safe
   request methods are idempotent". `PUT` is idempotent by specification but not
   by every implementation, and a replayed `PUT` costs nothing; including it is
   py's choice and it is kept. No `BASELINE-REVIEW` is raised on F313 for this:
   the row's wording, "unsafe-method requests", is accurate about what the
   middleware does.
2. **The header is opt-in.** No key means no caching; the layer never *requires*
   the header. The draft's 400-for-missing-key applies only to "a documented
   idempotent operation requiring this header" (§2.7); making a specific route
   require it is a route-level decision R71 documents, not this layer's.
3. **Key validation before anything else.** Non-empty, at most **255** bytes
   (Stripe's published ceiling; the draft states no limit), visible ASCII. A
   violation is **400** and the handler never runs. This is draft §5's first
   best practice — "Always validate the key as per its published specification
   before processing any request" — and it is also R56's rule applied at the
   edge: an unvalidated header value must not be used as a map key.
4. **Cache key = `(method, path, query, idempotency-key)`** — py's `_CacheKey`
   shape at `:48-62,104-109`, kept verbatim including the query string, whose
   presence py justifies in a comment at `:101-103` and whose absence would let
   `/things?a=1` replay `/things?a=2`.
5. **The body is *not* part of the key; it is a fingerprint stored beside the
   entry.** This is the sharpest design point in the item and the answer to the
   MEDIUM key-derivation question. Folding a body hash *into the key* looks like
   the safe choice and is the opposite: a client that retries with a
   re-serialized body (different whitespace, different map ordering) would
   produce a different key and **re-execute the side effect** — it defeats the
   feature it appears to harden. Draft §2.4 puts the fingerprint beside the key,
   and §2.7 makes the mismatch an error rather than a new operation: **422**.
   `axum-idempotent`'s own README reaches the same conclusion from the other
   direction — its hashing mode "only recognises byte-identical repeats: a
   client that re-serializes its body between attempts produces a different key
   and reaches the handler again."
6. **The port is a compare-and-set, never a get-then-insert.**
   `begin(&CacheKey, &Fingerprint) -> Result<Begin, PortError>` with
   `Begin::{Fresh, InFlight, Replay(CachedResponse), Mismatch}`, plus
   `complete(&CacheKey, CachedResponse)` and `abandon(&CacheKey)`. `Begin` is
   ZTP's `NextAction` widened by the two states the draft names and ZTP does not
   implement. `Fresh` *claims* the key; the claim is the in-flight marker. This
   is what closes py's documented single-flight hole, and it is also what makes
   the seam honest: a Redis adapter implements `begin` with `SET key … NX`, a
   Postgres adapter with `INSERT … ON CONFLICT DO NOTHING`, and neither needs a
   different middleware.
7. **`Fresh` → 409 on a concurrent duplicate; `Mismatch` → 422.** Draft §2.7,
   both statuses quoted verbatim in *Sources*.
8. **Only a 2xx completes the entry. Every other outcome abandons the claim**,
   including a dropped future, which an `AbandonOnDrop` guard covers, and a
   process-level stall, which a **separate, much shorter in-flight TTL** covers.
   Without both, one panicking request pins a key for the full 24 hours and the
   client can never retry — the failure mode a naive "insert a marker" design
   ships with.
9. **Bounded on both sides.** An oversize request body with a key is **413**
   before the handler runs (the layer must read the body to fingerprint it and
   `axum::body::to_bytes` consumes it on overflow, so forwarding is not an
   option). A response whose size is unknown or over the cap **streams through
   uncached** rather than being buffered — checked through
   `axum::body::HttpBody::size_hint().upper()` before any buffering.
10. **Replays carry `Idempotency-Replayed: true`**, appended to a fresh copy of
    the stored header list so the marker never stacks across replays — py's
    `:116-121` bug-avoidance, kept and tested.
11. **Not built, and documented as such**: no distributed store, no
    cross-instance single-flight, and no principal in the key. The third is a
    *security* swap-point note, not a nicety: draft §5 warns that low-entropy
    keys let an attacker "determine other keys and use them to fetch existing
    idempotent cache entries, belonging to other clients", and prescribes "a
    unique composite key … combining the idempotency key sent by the client with
    other client specific attributes known only to the resource". ZTP does
    exactly that with `user_id`. This template has no authentication, so there is
    no principal to add; the requirement is recorded so that whoever adds
    authentication adds it to the key in the same change.

**Observable acceptance criteria.** Criteria 1–13 and S1–S9 were **executed** in
this run against a throwaway cargo workspace under `$TMPDIR` built on the exact
R69 pins (`axum =0.8.9`, `tokio =1.53.1`, `tower =0.5.3` dev-only); all 22
passed, `cargo clippy --all-targets -- -D warnings` is clean and the crate
carries `#![forbid(unsafe_code)]`. Criteria marked *proposed* are requirements on
a template that does not exist yet and are **not** results.

| # | Criterion | Status |
|---|---|---|
| 1 | A second `POST` with the same key returns the first response byte-for-byte, with `idempotency-replayed: true`, and the handler ran once | **Executed** (`w01`) |
| 2 | A 500 is not cached; the second attempt really re-executes and carries no replay marker | **Executed** (`w02`) |
| 3 | The same key with a different body is **422** and the handler does not run | **Executed** (`w03`) |
| 4 | The same key against a different query string executes independently | **Executed** (`w04`) |
| 5 | No key means no caching | **Executed** (`w05`) |
| 6 | A `GET` carrying the header passes through untouched | **Executed** (`w06`) |
| 7 | Two `Set-Cookie` values survive caching and replay, and the replay marker does not stack over three replays | **Executed** (`w07`) |
| 8 | An oversize request body with a key is **413** and the handler never runs | **Executed** (`w08`) |
| 9 | A response body with no known size streams through whole and is not cached | **Executed** (`w09`) |
| 10 | An empty key and a 256-byte key are both **400** before the handler | **Executed** (`w10`) |
| 11 | A duplicate arriving while the first is in flight is **409** and the handler does not run | **Executed** (`w11`) |
| 12 | An entry expires at its TTL and the handler runs again | **Executed** (`w12`) |
| 13 | A non-2xx releases the claim, so the next attempt is not 409 | **Executed** (`w13`) |
| 14 | The whole layer is absent when the `web` feature is off | *Proposed* — it lives in `crates/web`, which R69 revision 10 makes an optional member; R02 already executed the equivalent check (`B1`/`B2`) |
| 15 | The OpenAPI document names `Idempotency-Key`, `Idempotency-Replayed` and the 400/409/413/422 responses on every unsafe operation | *Proposed* — R71's, handed over below |

**Performance, stated with its workload.** Workload: `begin()` on a **hit**, the
hot path, against a store holding **1,024** entries, single-threaded, 10,000
iterations, `aarch64-apple-darwin`, rustc 1.98.0. Instrumentation:
`std::time::Instant` around the loop, reported as nanoseconds per operation.
Result: **159 ns/op** release, **1,595 ns/op** debug. This figure is load-bearing
and it is also a design correction the probe forced: a first implementation that
swept the whole map for expired entries on every call measured **477,159 ns/op**
in debug — 300× worse — because the sweep cloned 1,024 four-`String` keys per
request. Replacing the sweep with per-entry lazy expiry plus
least-recently-used eviction only on an insert into a full store produced the
159 ns figure. Two conclusions follow, and the second is why the number matters:
the O(n) work must sit on the insert-when-full path and not the hit path; and at
159 ns the store call is **called inline from the async layer, not through
`spawn_blocking`**, on the runtime maintainers' own advice — "Contrary to popular
belief, it is ok and often preferred to use the ordinary `Mutex` from the
standard library in asynchronous code" (`https://docs.rs/tokio/1.53.1/tokio/sync/struct.Mutex.html`,
2026-09-18). No figure is claimed for end-to-end request latency or throughput;
nothing in this run measured that, and inferring it from a microbenchmark would
be exactly the unlike-benchmark comparison the prompt forbids.

**Reference-architecture reconciliation** (owner reference
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`, standing
input under `docs/planning/p02/owner-decisions.md` §11). **The document contains
no idempotency row** — not in the stack table (C1–C15), not in C11's middleware
order, not in the reference `Cargo.toml`, not in the reference layout; a
case-insensitive search of the file for "idempot" returns nothing. That absence
is itself the first row of the tally, because C11 enumerates ten layers and this
is an eleventh.

| Reference row | What it says | R73 |
|---|---|---|
| *Level One* — "**Dropped as unnecessary:** a dedicated in-process cache crate (use Postgres/Memorystore)" | do not add a cache crate | **Agree**, and this row is the single strongest support for member 2. Measured: `moka` +14 crates, `mini-moka` +11, `quick_cache` +9, `lru` +5, `hashlink` +3, all for eviction that the adapter must wrap in its own state machine regardless. |
| *Level One* — tower-http's set is enough for the listed concerns | — | **Agree** on every listed concern, and **extend**: idempotency is not in that set and `tower-http` 0.6 ships no layer for it. |
| C11 — recommended layer order, ten layers | `SetSensitiveHeaders → Trace → SetRequestId/Propagate → CatchPanic → Cors → NormalizePath → Timeout → RequestBodyLimit → Compression → SetResponseHeader` | **Extend, do not contradict.** No named layer moves. The constraints for where an eleventh layer joins are handed to R75 under *Migration implications*; one of them (idempotency **inside** `CompressionLayer`) is a correctness constraint, not a preference. |
| C11 — rate limiting is `tower_governor` 0.8 | — | **No position.** R74's. The ordering *between* the two is proposed below, not fixed. |
| C4 — error contract: `thiserror` + a hand-rolled `AppError` (RFC 9457), "most such crates unmaintained; hand-roll" | — | **Agree**, and it lands on this item twice: every 400/409/413/422/503 body here is R70's envelope, not one invented here; and the draft's examples still cite RFC 7807, which RFC 9457 obsoletes, so R70's `application/problem+json` shape is the current one and the draft's is not. |
| C12 — testing: `axum-test` 18, "tower `oneshot` lower-level, more boilerplate" | — | **Differ**, on ground R69 already recorded: R69's accepted revision 10 selects `tower::ServiceExt::oneshot` with `tower` as a dev-dependency. The 13 router checks here ran on that idiom with no extra dependency. This item does not reopen the choice. |
| C13 — layout: single crate, feature-vertical modules | — | **Differ**, on ground R02 revision 1 already recorded (four-package workspace). This item places the port in `crates/core`, the layer in `crates/web`, and the adapter at the root package's composition root, which is R02's shape. |
| C9 — config: `figment` | — | **No position.** R77's. The TTL and capacity knobs are environment variables R77 names. |
| C5 / C6 / C8 — database, sessions and auth, background jobs | — | **Inapplicable, and decisive.** The template has none of them, which is precisely why the one crate with adoption is unusable: `axum-idempotent` requires `ruts::SessionLayer` inside `tower_cookies::CookieManagerLayer`. |

Tally: **agree 3, extend 1, differ 2 (both deferring to a sibling decision that
already recorded the ground), no position 2, inapplicable 1** — and one row that
does not exist, which is the reason this item exists.

### Recommendation

**Adopt `idempotency-replay/v1`: a hand-written `axum::middleware::from_fn_with_state`
layer in `crates/web/src/idempotency.rs`, over an `IdempotencyStore` driven port
in `crates/core` whose contract is a compare-and-set
(`begin`/`complete`/`abandon`) returning `Begin::{Fresh, InFlight, Replay, Mismatch}`,
with a `std`-only `InMemoryIdempotencyStore` production adapter (one
`std::sync::Mutex<HashMap<CacheKey, Slot>>`, lazy per-entry TTL, LRU eviction at
`max_entries`, a separate shorter in-flight deadline) constructed at the root
package's composition root and erased to `Arc<dyn IdempotencyStore>`, and `sha2`
0.11.0 (`default-features = false, features = ["alloc"]`) supplying the SHA-256
request-payload fingerprint. Cache key `(method, path, query, idempotency-key)`;
fingerprint compared, not keyed; 2xx-only completion; `Idempotency-Replayed: true`
on replays; 400 / 409 / 413 / 422 as the draft assigns them, bodied by R70's
envelope. No crate is adopted for the middleware and none for the store.**
Ledger rows settled: **F313, F314, F315** — py's pattern is preserved in each,
F314's behaviour on corrected grounds per the `BASELINE-REVIEW` above. The
verdict glyph each row carries is the synthesizer's to assign, not this
report's.

### Members

#### Idempotency replay layer

##### Landscape

Bin: **built-in / first-party toolchain** (`axum` 0.8.9's own
`middleware::from_fn_with_state`), with the up-and-comer bin supplying the
runner-up (`axum-idempotent` 0.3.0) and four framework-bound crates. The
established-standard bin supplies the *behaviour* (draft-07, Stripe, ZTP) but no
Rust code. There is no first-party or established-industry **crate** in this
category: `tower-http` 0.6's published layer set contains no idempotency layer,
and a search of crates.io across six query spellings (endpoints listed in the
report's top-level `### Landscape`) returned exactly six candidates, five of them
bound to a framework or a product.

##### Principles and implementation

The layer is where three principles become observable at once: the replay
decision is in exactly one place (F313), the store-write condition is an
explicit `if` on the status (F314), and the store is reached only through a trait
(F315). It must (a) see the request before the handler, to claim the key; (b) see
the response after, to store or abandon; (c) be able to *not* call the handler,
to serve a replay, a 409 or a 422; (d) hold shared state. `from_fn_with_state`
gives all four in one `async fn` signature —
`async fn idempotency(State(s): State<IdempotencyState>, req: Request, next: Next) -> Response`
— and returns a real `tower::Layer` (`FromFnLayer`), so it composes with every
`tower-http` layer R75 orders. Verified, not assumed: the probe declares no
`tower` dependency, compiles, and passes 13 router checks; `cargo tree -e normal`
shows `tower v0.5.3` arriving only through `axum v0.8.9`, so R69's dev-only
declaration is undisturbed.

Reference implementation composed end to end: the probe workspace, ~170 lines of
layer over ~200 lines of port and adapter, mirroring ZTP's module split
(`key` validation, `persistence` state machine, the caller) onto R02's crate
split. Behaviour verification is the 13 `oneshot` checks listed under criteria
1–13.

##### Dominant choice

**None exists.** This is the substantive answer to the HIGH question. No
published Rust crate implements `Idempotency-Key` request replay for a leading
async web framework in a form this template could adopt, and the field's best
work — Zero To Production — is itself hand-rolled. `axum::middleware::from_fn_with_state`
from **axum 0.8.9**, R69's accepted pin, is the dominant *mechanism*; figures for
axum are R69's and are not re-collected here (R69 revision 10,
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`). Two
facts about it were verified in this run rather than taken from R69: it requires
**no Cargo feature** (`https://docs.rs/axum/0.8.9/axum/middleware/fn.from_fn_with_state.html`,
2026-09-18, and the probe compiles with R69's exact feature list), and it needs
**no `tower` dependency line**.

##### Qualified shortlist

| Candidate | 90-day dl | All-time dl | Newest unyanked | Licence | `rust-version` | Stars / archived | Open issues |
|---|---|---|---|---|---|---|---|
| `axum-idempotent` 0.3.0 | **249** | 6,910 | 0.3.0, 2026-08-19 | MIT | 1.85.0 | **5** / no, pushed 2026-08-19 | **0** (and 0 ever) |
| `axum::middleware::from_fn_with_state` (axum 0.8.9) | R69's figures | R69's | R69's pin | MIT | R69's | R69's | R69's |
| `sova-idempotency` 0.1.1 | 58 | 58 | 0.1.1, 2026-08-09 | MIT | none declared | not collected — excluded by gate below | — |
| `actix-idempotent` 0.1.1 | 15 | 762 | 0.1.1, 2025-08-13 | MIT | 1.87.0 | not collected — excluded by gate below | — |

Endpoints: `GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`,
`crate.downloads`), `GET https://crates.io/api/v1/crates/<name>/versions`
(newest `yanked: false`), `GET https://api.github.com/repos/jimmielovell/axum-idempotent`
(`stargazers_count`, `archived`, `pushed_at`), `GET
https://api.github.com/search/issues?q=repo:jimmielovell/axum-idempotent+is:issue+is:open`
(`total_count`), all retrieved 2026-09-18. **Issue responsiveness:
`inapplicable`** for `axum-idempotent` — the repository has **zero issues, open
or closed, ever** (`…+is:issue` `total_count = 0`), so there is no first-response
interval to measure and no unanswered count. **Advisories:**
`https://rustsec.org/packages/axum-idempotent.html` → HTTP 404, i.e. no advisory
record; likewise `ruts`, its store dependency. **Maintenance state:**
`axum-idempotent` is **active** by the rubric — released 2026-08-19, repository
pushed the same day, not archived, no advisory, no maintainer notice — but
active at a scale of one maintainer, five stars and one fork.

##### Excluded by gate

| Candidate | Gate | Finding |
|---|---|---|
| `actix-idempotent` 0.1.1 | 5 (framework/runtime coupling) | Built for actix-web, which R69 did not select. Last release 2025-08-13 with 15 90-day downloads; a port would be a rewrite. |
| `sova-idempotency` 0.1.1 | 2 and 5 | No `rust-version` declared, so the MSRV policy's "declared as rust-version in Cargo.toml" clause cannot be satisfied; and it is "Inbound Idempotency-Key middleware for **Sova**", a framework this template does not use. 58 total downloads. |
| `minco-plugin-idempotency` 1.12.0, `kcode-kweb-idempotency` 0.1.1 | 5 | Plugins for the Minco and Kweb application frameworks respectively; neither is framework-agnostic. |
| `idempotent` 2.0.0 | scope | "Type-safe idempotency keys" — a key newtype, not middleware. 52 90-day downloads. Its idea (a validating newtype) is adopted; the crate is not needed for ~20 lines. |
| `bhatti/idempotency-rs` | 1, 2, 5 | Not published: `GET https://crates.io/api/v1/crates/idempotency-rs` → **404** (2026-09-18). Pinned to axum 0.7 and edition 2021, 1 star. Cited as design evidence only. |
| A hand-written `tower::Layer`/`Service` pair | 5 | Not unfit — it works — but it requires a `tower` dependency line R69's accepted revision declines, for no capability `from_fn_with_state` lacks. |

Gates 1, 3, 4 and 6 for the **recommended** mechanism: licence is axum's
(MIT, compatible with `MIT OR Apache-2.0`); no RustSec record for `axum`
(`https://rustsec.org/packages/axum.html` → 404); OS coverage is R69's, already
established for `ubuntu-latest, macos-latest`; and the mechanism adds **zero
crates and zero build time**, because it is a function in a dependency the
template already has. `unsafe` posture: the layer itself carries
`#![forbid(unsafe_code)]` — executed, the probe compiles under it.

##### Up-and-comers

`axum-idempotent` is the only one worth watching: it is the sole crate in this
space with non-trivial downloads and an active maintainer, and its 0.3.0
documentation is unusually honest about its own limits. Two things would have to
change before it fits: the store would have to stop being a *session* store, and
the 2xx rule would have to become expressible as a rule. Watch also for a
successor to the expired draft — if httpapi revives it toward an RFC, the status
assignments this design follows become normative rather than advisory.

##### Fit for this template

Decisive. The template is CLI + library + **optional** web service with no
database, no sessions, no cookies and no authentication. `axum-idempotent`
requires `ruts::SessionLayer` placed inside `tower_cookies::CookieManagerLayer`
(its README: "This middleware requires a session layer … For the
`IdempotentLayer` to access the session, it must be placed *inside* the
`SessionLayer`"). Adopting it therefore means adopting sessions and cookies —
two capabilities the owner reference lists under C6 and
`docs/planning/p02/owner-decisions.md` §11 explicitly records as **not decided
and not researched**. Measured integration cost: a workspace of
`axum 0.8.9 + tokio 1.53.1` resolves to **51** crates; adding
`axum-idempotent 0.3.0 + ruts 0.10.1 + tower-cookies 0.11.0` takes it to **100** —
**+48 crates**, including `chacha20`, `rand`, `base64` and `cookie` (cookie
signing), `bincode` + `virtue` + `unty` (session serialization), `time` and
`dashmap` (`cargo tree -e normal`, deduplicated, 2026-09-18). The recommended
design adds **8**, all for the fingerprint.

Two further fit failures, each fatal on its own. **(a) The 2xx rule cannot be
expressed.** `axum-idempotent` caches by a *deny-list* of statuses — `lib.rs:82-106`
documents sixteen ignored codes and `lib.rs:231-232` is
`if !config.ignored_res_status_codes.contains(&status_code)`. It therefore caches
201, 204, 3xx, 404, 409 and any status not enumerated. F314 asks for an
allow-list, and no amount of `ignore_response_status_code` calls turns a
deny-list into one: an unlisted future status would still be cached. The HIGH
question asks whether the crate "makes the 2xx-only rule an explicit, testable
condition rather than an incidental default" — the answer is no, it makes the
opposite rule the default. **(b) No single-flight and silent degradation.** Its
README: "two identical requests that arrive concurrently can both reach the
handler", and "the middleware forwards a request without idempotency handling
when the session or the store is unavailable". Both are the failure modes this
item exists to remove.

##### Recommendation

A hand-written layer, `crates/web/src/idempotency.rs`, installed as
`axum::middleware::from_fn_with_state(state, idempotency)`. Roughly 170 lines,
`#![forbid(unsafe_code)]`-clean, `clippy -D warnings`-clean, adding no crate.
Behaviour exactly as the eleven clauses under `### Principles and implementation`
state, all thirteen router criteria executed.

##### Ranked runner-up

1. **`axum-idempotent` 0.3.0** — if the template ever grows `ruts` sessions for
   another reason, and if the maintainer adds an allow-list mode and single-flight,
   it becomes a real option. Today it fails on fit for three independent reasons.
2. **A hand-written `tower::Layer`/`Service` pair** — the fallback if a future
   axum release changes `from_fn_with_state`'s signature or if the layer must
   run outside an axum `Router`. Same behaviour, more code, one dependency line.
3. **In-handler calls, ZTP-style** — the design to switch to *if* this template
   ever gains a database, because then the idempotency record and the side effect
   can commit in one transaction, which no layer can offer.

##### Tradeoffs

The layer buffers the request body to fingerprint it, so an unsafe request
carrying a key pays one full-body copy and one SHA-256 pass; requests without a
key pay nothing (the header check is the first branch). **A 2xx whose body is
streaming or exceeds `max_response_bytes` is a documented hole, and it is the
sharpest one:** that response streams through uncached (`w09`), the claim is
released by the drop guard, and a client retry therefore **re-executes the side
effect** — precisely what the layer exists to prevent — while the client sees a
normal 2xx both times and cannot tell. Two dispositions exist and this item does
not choose between them: require that any route opting into `Idempotency-Key`
return a bounded, non-streaming 2xx body (a documentation rule, R71's to state),
or store a body-less `Done` marker for such responses and answer retries **409**
rather than replaying (a behaviour change, and a deliberate departure from "only
successful outcomes are stored" since the marker holds no outcome). **P03's
call**, recorded here so it is a decision rather than an omission. It cannot know whether
the handler's side effect committed, which is why 2xx-only is the honest rule and
why a database-backed template should prefer A2. It sees only one process, so
`Idempotency-Key` is a single-instance guarantee — stated in the module
documentation exactly as py states it. And a hand-written layer is code this
repository owns and must maintain, against a crate that would be maintained
elsewhere; the trade is accepted because the crate's semantics are the wrong
ones and its transitive cost is 48 crates.

##### Parameters

This member owns no parameter and needs no consumed value changed. It is written
against `web-extra-surface` as R69 owns it; the registry bytes and the R69
revision-10 note are in the report-level `### Parameters` field. No `CONFLICT:`.

##### Migration implications

New file `crates/web/src/idempotency.rs` (layer, header constants, key
validation, fingerprint call, replay reconstruction, `AbandonOnDrop`). One
`mod idempotency;` line in `crates/web/src/lib.rs`. One
`.layer(axum::middleware::from_fn_with_state(idempotency_state, idempotency::idempotency))`
call inside `build_router`, at the position R75 fixes. One field on `AppState` or
a sibling state struct carrying `Arc<dyn IdempotencyStore>` and the three size
limits. New file `crates/web/tests/idempotency.rs` carrying criteria 1–13. No
change to the CLI binary, the core library outside member 2's port, or any
existing file beyond those two lines.

##### Validation strategy

`cargo test -p rs-launch-blueprint-web --features web --test idempotency` runs
criteria 1–13 through `tower::ServiceExt::oneshot` against a `Router` built by
`build_router`. **Executed in this run** against the probe workspace: 13 passed,
0 failed. `cargo clippy --all-targets -- -D warnings`: **executed**, clean.
*Proposed*: the same suite under `--no-default-features` to confirm the module
vanishes with the `web` feature, and an `insta` snapshot of the OpenAPI document
once R71 lands.

##### Confidence & re-verify trigger

**High** on the mechanism and the behaviour — every clause is executed, not
argued. **Medium** on "no crate exists": crates.io search is keyword-based and a
crate published under a name none of six queries matched would be missed.
Re-verify when axum publishes 0.9 (the `from_fn_with_state` signature is the
whole dependency); when `axum-idempotent` publishes a release that adds an
allow-list status rule *and* a store trait not tied to `ruts`; when the httpapi
working group revives `draft-ietf-httpapi-idempotency-key-header` past -07 or it
reaches RFC; when R69 republishes; when R75 publishes the ordering contract; or
by **2027-03-18**, whichever comes first.

##### Sources

- `https://static.crates.io/crates/axum-idempotent/axum-idempotent-0.3.0.crate` — the published crate, read as bytes: `Cargo.toml` (deps `axum 0.8.9`, `blake3 1.8.6`, `ruts 0.10.1`, `http-body-util`, `serde_bytes`, `tower-layer`, `tower-service`, `tracing`; feature `layered-store = ["ruts/layered-store"]`), `README.md`, `src/lib.rs:82-106,200-250`. Retrieved 2026-09-18.
- `GET https://crates.io/api/v1/crates/axum-idempotent`, `/versions`; `GET https://api.github.com/repos/jimmielovell/axum-idempotent`; `GET https://api.github.com/search/issues?q=repo:jimmielovell/axum-idempotent+is:issue+is:open` and `…+is:issue`. Retrieved 2026-09-18.
- `GET https://crates.io/api/v1/crates/ruts` — `default = ["axum", "bincode"]`, `redis-store = ["dep:fred"]`, `postgres-store = ["dep:sqlx"]`; 296 90-day downloads. Retrieved 2026-09-18.
- `https://docs.rs/axum/0.8.9/axum/middleware/fn.from_fn_with_state.html`. Retrieved 2026-09-18.
- `https://www.ietf.org/archive/id/draft-ietf-httpapi-idempotency-key-header-07.txt` §2.6, §2.7. Retrieved 2026-09-18.
- `https://raw.githubusercontent.com/LukeMathWalker/zero-to-production/main/src/idempotency/persistence.rs` (`try_processing`, `NextAction`), `/key.rs`. Retrieved 2026-09-18.
- py `src/py_launch_blueprint/web/idempotency.py:20-31,43-45,79-150` and `src/py_launch_blueprint/web/app.py:127-146` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`.
- R69 revision 10 (accepted, unpublished): `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791`.

#### Idempotency-key store port and in-memory adapter

##### Landscape

Two bins collide here. The **built-in** bin offers `std::sync::Mutex` +
`std::collections::HashMap`, which is what the owner reference's *Level One*
instruction points at. The **up-and-comer** bin offers a genuinely strong
caching field — `moka` (36.3M 90-day downloads), `lru` (89.6M), `hashlink`
(94.3M), `quick_cache` (7.1M), `mini-moka` (1.5M), `schnellru` (2.4M). There is
no **established-standard** answer, because the established standard for this
capability in the wider industry is *Redis*, which this item is explicitly
building a swap point toward rather than adopting. What the caching bin does not
contain is the thing this member actually needs: a compare-and-set with an
in-flight state. Every candidate in it would be wrapped in exactly the state
machine that, once written, no longer needs them.

##### Principles and implementation

F315's principle is not "use a cache"; it is "the store sits behind a named seam
so the distributed swap is an adapter change" — which is R01's pattern verbatim.
So this member is **a driven port with a fake and a production adapter**, and
saying so is the substance of the answer:

- **Port** (`crates/core`, R02's placement for ports): `pub trait IdempotencyStore: Send + Sync`
  with `begin`, `complete`, `abandon`. Dyn-compatible: no `async fn`, no generic
  methods, no associated consts, no non-receiver `Self` — R01's registered
  constraints, executed. A blanket `impl<T: IdempotencyStore + ?Sized> IdempotencyStore for Arc<T>`
  is present, so the composition root erases to `Arc<dyn IdempotencyStore>`
  exactly as it erases R01's `ProjectsPort`.
- **R03 reconciliation, checked rather than assumed.** R03's rule 1 governs a
  *read that addresses one resource by identity* and requires
  `Result<Option<T>, PortError>`. `begin` is not that read: it is a write that
  claims a key, and its four outcomes (`Fresh`, `InFlight`, `Replay`, `Mismatch`)
  are all *success*, not absence. Collapsing them to `Option` would destroy the
  distinction between "not present" and "present but claimed" — the distinction
  the 409 exists for. So `begin` returns `Result<Begin, PortError>` with a
  dedicated enum, R03 rule 2's `PortError` shape (`thiserror`-derived,
  `#[non_exhaustive]`, boxed causes, **no `NotFound` variant**) is followed
  exactly, and rule 1 is satisfied vacuously because this port exposes no
  by-identity read. R03 says so itself, in its own *Ranked runner-up* paragraph:
  "Rule 1 is scoped to reads for exactly that reason", the reason being that on a
  *mutation* — it names `delete(id)`, `update(id, …)` — "`Ok(None)` names nothing
  useful". `begin` is that kind of operation.
- **R03 rules 3–6, read and applied rather than skimmed.** Rule 3 (the adapter
  owns a per-operation absence rule, written as explicit `match` arms) and rule 6
  (the `compile_fail` doctest and R01's `assert_projects_port_contract`) both
  address an HTTP adapter's 404 handling and have no counterpart on a store with
  no remote and no absence-versus-failure ambiguity; rule 6's contract-function
  idea does carry over, and the nine store checks are that contract applied to
  both the fake and the production adapter. Rule 4 ("the use case is the only
  translation site … no front end constructs [a `DomainError`] from a port
  result") is respected by placing the `Begin` → HTTP-status mapping in the
  layer as *transport* mapping, not as a `DomainError` construction; the layer
  never builds a domain error, and the 400/409/413/422 bodies are R70's.
  **Rule 5 changes the adapter and is the one finding of this read.** Its
  `PortError`-to-catalogue table already carries a row for exactly this
  adapter's only failure mode — "`Unavailable { detail: String }` — R01's
  poisoned-`Mutex` case → `RSLB101` I/O (proposal)". So the shipped adapter
  **returns `Err(PortError::Unavailable { … })` when the lock is poisoned rather
  than panicking**, and the layer's 503 branch is where it surfaces. The probe
  used `.expect("store poisoned")` and therefore **did not execute this branch**;
  the recommendation departs from the probe on this one point, deliberately, on
  R03 rule 5's authority, and it is listed under *Validation strategy* as
  proposed rather than executed.
- **R05 reconciliation, measured rather than assumed.** The port is synchronous
  `fn`, so it satisfies R05's "no executor in the library crate" and the
  run's "an in-memory or file-backed store must not need a runtime" — executed:
  the nine store checks run under plain `#[test]` with no `#[tokio::test]` and no
  runtime in scope. Whether the *call site* wraps it in `spawn_blocking` is an
  adapter-by-adapter judgement, and the measurement decides it: **159 ns/op**
  release on a hit at 1,024 entries means the shipped adapter is called inline,
  on tokio's own published advice. A future Redis or file-backed adapter, whose
  critical section performs I/O, **must** be called through `spawn_blocking` —
  which is R05's rule applied, not contradicted. This is recorded as a coupling
  note for R05, not a `CONFLICT`: R05's value does not need to change.
- **Adapter** (root package's composition root, R02's placement for production
  adapters): one `Mutex<Inner>` where
  `Inner { slots: HashMap<CacheKey, Slot>, tick: u64 }` and
  `Slot::{InFlight { fingerprint, at, used }, Done { fingerprint, at, used, response } }`.
  Expiry is checked on the entry touched, never by sweeping. Eviction removes the
  minimum `used` only when an insert would exceed `max_entries`. `Done` entries
  use the long TTL; `InFlight` markers use a separate, much shorter one.
- **Injected clock.** `trait Clock: Send + Sync { fn now_millis(&self) -> u64 }`,
  production `SystemClock` over `Instant`, `TestClock` in tests. This is the
  difference between a TTL that is asserted and a TTL that is slept through; both
  TTL checks (`s04`, `s05`) assert the boundary at exactly one millisecond either
  side, which a sleep-based test cannot do.
- **Fake.** `AlwaysFreshStore` — always `Fresh`, never replays. It lets a web
  test exercise the non-idempotent path without reasoning about eviction, and it
  is the shape R48's mocking decision will point at.
- **Entry shape is the swap contract**, py's words at `:66-71`: status as `u16`,
  headers as raw `(name, Vec<u8>)` pairs rather than a map so multi-valued headers
  survive, body as bytes. Identical to ZTP's `HeaderPairRecord`. A Redis adapter
  serializes that struct; nothing else changes.

##### Dominant choice

**`std` only — `std::sync::Mutex<HashMap<CacheKey, Slot>>`, no crate.** Crate
figures are **`inapplicable`** for the dominant choice and the reason is stated
rather than omitted: the recommendation adds no crate, so
`crate.recent_downloads`, `crate.downloads`, last release, stars, open issues,
issue responsiveness, advisories and reverse-dependency adopters have no subject.
The gates that *do* apply were applied: licence — `std` ships under the
toolchain's own `MIT OR Apache-2.0`, compatible by construction; MSRV — nothing
used here postdates Rust 1.85 and the probe's manifest declares
`rust-version = "1.96"` with the whole tree resolving under Cargo's MSRV-aware
resolver; advisories — none possible; OS — `HashMap`, `Mutex` and `Instant` are
core `std`, exercised on `aarch64-apple-darwin` in this run and portable to
`ubuntu-latest` without conditional code; default features and runtime coupling —
none, no runtime, proved by the nine plain `#[test]` checks; binary size and
compile time — **zero added on both counts**, measured as a 0-crate delta.
`unsafe` posture: **none** — the adapter compiles under `#![forbid(unsafe_code)]`,
executed.

##### Qualified shortlist

Each of these was evaluated as the store's data structure. Figures from
`GET https://crates.io/api/v1/crates/<name>` and `/versions`, and
`GET https://api.github.com/repos/<o>/<r>` where collected; retrieved 2026-09-18.
The `Δ crates` column is measured: crates added to an
`axum 0.8.9 + tokio 1.53.1` workspace (51 crates) by `cargo tree -e normal`,
deduplicated.

| Candidate | 90-day dl | All-time dl | Newest unyanked | Licence | `rust-version` | Δ crates | Advisories |
|---|---|---|---|---|---|---|---|
| **`std` (recommended)** | inapplicable | inapplicable | inapplicable | `MIT OR Apache-2.0` | n/a | **0** | none possible |
| `hashlink` 0.12.2 | 94,297,121 | 335,935,112 | 0.12.2, 2026-09-07 | `MIT OR Apache-2.0` | 1.85 | **+3** (`hashlink`, `hashbrown` 0.17.1, `foldhash`) | none (`https://rustsec.org/packages/hashlink.html` → 404) |
| `lru` 0.18.4 | 89,563,659 | 348,874,557 | 0.18.4, 2026-09-03 | **MIT only** | 1.85.0 | **+5** | **two unsoundness advisories in 2026**, both patched at ≤ 0.18.2 |
| `quick_cache` 0.7.0 | 7,090,629 | 26,508,706 | 0.7.0, 2026-06-27 | MIT only | 1.85 | **+9** (pulls `parking_lot`) | none (404) |
| `moka` 0.12.16 (`sync`) | 36,349,838 | 127,021,020 | 0.12.16, 2026-08-09 | **`(MIT OR Apache-2.0) AND Apache-2.0`** | 1.71.1 | **+14** (`uuid`, `parking_lot`, three `crossbeam` crates, `getrandom`, `portable-atomic`, `tagptr`, …) | none (404) |
| `mini-moka` 0.10.3 | 1,525,770 | 8,338,138 | 0.10.3, **2024-01-08** | `MIT OR Apache-2.0` | 1.61 | **+11** (incl. `dashmap` 5.5.3 and a second, older `hashbrown` 0.14.5) | none (404) |
| `schnellru` 0.2.4 | 2,441,540 | 15,700,674 | 0.2.4, **2025-01-03** | `MIT/Apache-2.0` | 1.71.1 | not measured | none (404) |

Supporting repository figures where collected:
`moka-rs/moka` — 2,686 stars, not archived, pushed 2026-08-09, **59** open issues
(`GET https://api.github.com/repos/moka-rs/moka`,
`GET https://api.github.com/search/issues?q=repo:moka-rs/moka+is:issue+is:open`);
`djc/hashlink` — 139 stars, not archived, pushed 2026-09-07. **Maintenance
state:** `moka` **active**; `hashlink` **active** (released 2026-09-07 by a
maintainer of rustls and quinn); `lru` **active**; `quick_cache` **active**;
`mini-moka` **stable-quiet** — no release since 2024-01-08, which the rubric
makes a trigger to investigate rather than a verdict, and the investigation finds
no advisory, no maintainer notice and a still-building crate, but it does find a
pinned `dashmap` 5.5.3 and `hashbrown` 0.14.5 that would sit in the tree beside
the current ones; `schnellru` **stable-quiet** on the same reading.

**Issue responsiveness** is reported as **`inapplicable` for this member's
recommendation** (no crate). It was collected for the crate this bundle *does*
adopt, under member 3.

##### Excluded by gate

| Candidate | Gate | Finding |
|---|---|---|
| `lru` 0.18.4 | 3 (`unsafe` posture) — **noted, not disqualifying on the letter** | Both advisories are patched at the recommended version, so the gate's letter passes. It is recorded here because the *posture* is the finding: `lru` implements a hand-written doubly-linked list in `unsafe`, and in 2026 alone it shipped **RUSTSEC-2026-0002** ("`IterMut` violates Stacked Borrows by invalidating internal pointer", patched ≥ 0.16.3) and **RUSTSEC-2026-0253** ("Potential use-after-free due to lack of panic safety in `LruCache::pop()`", patched ≥ 0.18.2) — both `memory-corruption` category (`https://rustsec.org/advisories/RUSTSEC-2026-0002.html`, `…-0253.html`, 2026-09-18). A safe-Rust `HashMap` plus a `u64` counter has no such surface. Licence is also MIT-only, which is compatible but forgoes Apache-2.0's patent grant. |
| `moka` 0.12.16 | 1 (licence) — **noted** | `(MIT OR Apache-2.0) AND Apache-2.0`: the Caffeine-derived portion is Apache-2.0 unconditionally, so Apache-2.0's notice obligations attach whatever the template chooses. Compatible, not free of consequence. Excluded on fit, below, not on licence. |
| `mini-moka` 0.10.3 | 6 (tree cost) | +11 crates including a duplicate older `hashbrown` and `dashmap` 5.5.3, for a sync-only cache the adapter must still wrap. |
| Every cache crate | **fit** | The decisive gate, and it is the same one for all of them: **none expresses an in-flight marker or a compare-and-set.** `moka::sync::Cache::get` followed by `insert` is two operations with a window between them; closing that window needs the adapter's own `Mutex` and its own `Slot` enum — after which the cache supplies only eviction ordering, for between 3 and 14 crates. This is the owner reference's *Level One* instruction, reached independently and measured. |
| `tokio::sync::Mutex` | 5 | Rejected on the runtime maintainers' own advice; the guard is never held across an `.await` here, so the async mutex's only advantage does not apply and its cost would. |
| `parking_lot::Mutex` | 6 | +3 crates for a lock whose contended performance is irrelevant at 159 ns held. |

##### Up-and-comers

`foyer` and the hybrid in-memory/disk caches are the live area of the field, and
they are further from this member's need than `moka` is: this store must stay
bounded, in-process and losable on restart by design. The one genuine
up-and-comer for *this* problem is a Rust crate that packages the
`begin`/`complete`/`abandon` contract across backends — the shape
`bhatti/idempotency-rs` sketches and does not publish. If such a crate appears
and is maintained, the port declared here is exactly the seam it would slot into,
which is the point of declaring the port.

##### Fit for this template

The store is documented as a swap point and **not built out** — py's own framing
at `:26-30` and the ledger's at F315. Adding 3 to 14 crates to something the
template's own documentation tells the reader to replace is the wrong direction,
and a reader who is going to write a Redis adapter is served better by an adapter
they can read in one screen than by a cache crate's eviction semantics they must
reproduce. Defaults carried over from py `src/py_launch_blueprint/web/settings.py:71-73`:
TTL 86,400 s (which is also Stripe's published retention — "You can remove keys
from the system automatically after they're at least 24 hours old") and
`max_entries` 1,024. New here: the in-flight deadline, proposed at 30 s, which
exists because py has no in-flight state at all. Memory is bounded and stateable:
1,024 entries × (response body cap + fingerprint 32 B + key + headers).

##### Recommendation

`std` only. `pub trait IdempotencyStore: Send + Sync` in `crates/core` with
`begin`/`complete`/`abandon` and the `Begin` enum; `InMemoryIdempotencyStore`
over one `std::sync::Mutex`, lazy per-entry expiry, LRU eviction at capacity,
separate in-flight deadline, injected `Clock`; `AlwaysFreshStore` as the shipped
fake; blanket `Arc<T>` impl; erased to `Arc<dyn IdempotencyStore>` at the root
package's composition root. No crate.

##### Ranked runner-up

1. **`hashlink` 0.12.2** — if the eviction structure is ever wanted as a
   dependency, this is the one: `MIT OR Apache-2.0`, `rust-version = "1.85"`,
   **+3 crates**, 94.3M 90-day downloads, maintained by djc. It would replace the
   `HashMap` + `used` counter and nothing else; the `Slot` enum, the CAS and both
   TTLs stay.
2. **`moka` 0.12.16** — the choice if the store ever needs weighted entries, a
   TinyLFU admission policy, or per-entry expiry policies. +14 crates and an
   unconditional Apache-2.0 obligation.
3. **`quick_cache` 0.7.0** — lighter than `moka`, no TTL of its own, which is
   most of what would be wanted.

##### Tradeoffs

One global `Mutex` serializes every keyed unsafe request; at 159 ns held, and
with a single-instance design already assumed, that is not a bottleneck this
template can reach, but it is a real serialization point and it is stated rather
than hidden. Lazy expiry means an expired entry that nobody touches occupies a
slot until capacity evicts it — bounded by `max_entries`, exactly as py's
`OrderedDict` behaves, and the reason the alternative (sweeping) was rejected is
measured: 477,159 ns/op versus 1,595 ns/op in the same build. Hand-written LRU is
code to maintain; the counterweight is that it is safe Rust with no linked list,
against a crate whose own linked list produced two memory-corruption advisories
this year.

##### Parameters

Owns nothing; needs nothing changed. TTL, in-flight deadline and `max_entries`
are configuration, and under R69's accepted value "every service knob … stays an
environment variable named by R77", so they are **R77's names**, proposed and not
fixed below. `R54` (`config-discovery-tiers`) is therefore **inapplicable** to
this member: R54 governs the layered config *file* chain, and no value here
reaches a config file. No `CONFLICT:`.

##### Migration implications

New file `crates/core/src/idempotency.rs` — `CacheKey`, `Fingerprint`,
`CachedResponse`, `Begin`, `IdempotencyStore`, the blanket `Arc` impl, `Clock`,
`AlwaysFreshStore`. One `mod idempotency;` / `pub use` pair in
`crates/core/src/lib.rs`. New file at the root package's composition root holding
`InMemoryIdempotencyStore` and `SystemClock`, constructed once beside the existing
`ProjectsPort` adapter and erased to `Arc<dyn IdempotencyStore>`. New file
`crates/core/tests/idempotency_store.rs` carrying `s01`–`s09`. R02's
`tests/workspace_edges.rs` allow-list is **unchanged** — this member adds no
external dependency to `crates/core`.

##### Validation strategy

`cargo test -p rs-launch-blueprint-core --test idempotency_store` — nine checks,
plain `#[test]`, no runtime. **Executed**: `s01` fresh → in-flight → replay;
`s02` fingerprint mismatch; `s03` abandon releases; `s04` TTL boundary asserted at
±1 ms; `s05` in-flight deadline is separate and shorter; `s06` eviction removes
the least recently *used*, not the least recently written; `s07` keys are scoped
by method, path and query; `s08` 159 ns/op release, 1,595 ns/op debug at 1,024
entries; `s09` the blanket `Arc` impl satisfies the port and the erased handle is
`Send + Sync`. All nine passed. *Proposed*: the same suite on `ubuntu-latest` in
CI, which this run could not execute — everything here ran on
`aarch64-apple-darwin` only.

##### Confidence & re-verify trigger

**High.** The design is executed end to end and the one number that could have
changed the recommendation (store-call latency) was measured, and measured twice
after it forced a redesign. The residual risk is that a real deployment shows
lock contention this microbenchmark cannot, which is the stated gap. Re-verify
when a maintained crate publishes a `begin`/`complete`/`abandon`-shaped
idempotency store trait; when R01, R02, R03 or R05 publishes a decision differing
from the accepted revisions this is written against; when R77 publishes the env
names; if the template ever gains a database, at which point member 1's
alternative A2 and a transactional store become the better pair; or by
**2027-03-18**.

##### Sources

- py `src/py_launch_blueprint/web/idempotency.py:26-30,48-77,91,110-123,141-149` and `src/py_launch_blueprint/web/settings.py:71-73` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`.
- `https://raw.githubusercontent.com/LukeMathWalker/zero-to-production/main/src/idempotency/persistence.rs` — `HeaderPairRecord`, `try_processing`, `NextAction`. Retrieved 2026-09-18.
- `GET https://crates.io/api/v1/crates/{moka,mini-moka,lru,hashlink,quick_cache,schnellru}` and `/versions`. Retrieved 2026-09-18.
- `GET https://api.github.com/repos/moka-rs/moka`, `GET https://api.github.com/repos/djc/hashlink`, `GET https://api.github.com/search/issues?q=repo:moka-rs/moka+is:issue+is:open`. Retrieved 2026-09-18.
- `https://rustsec.org/advisories/RUSTSEC-2026-0002.html`, `https://rustsec.org/advisories/RUSTSEC-2026-0253.html`, and `https://rustsec.org/packages/{moka,hashlink,lru,quick_cache}.html`. Retrieved 2026-09-18.
- `https://docs.rs/tokio/1.53.1/tokio/sync/struct.Mutex.html` — "Contrary to popular belief, it is ok and often preferred to use the ordinary `Mutex` from the standard library in asynchronous code." Retrieved 2026-09-18.
- `https://docs.stripe.com/api/idempotent_requests` — 24-hour retention. Retrieved 2026-09-18.
- R01's registered `http-transport-injection-seam` value and R02 revision 1 (`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md`), R03 revision 1 (`research/runs/R03/2026-09-17T033527Z-cd9e6a9555b6/review/DECISION.md`, rules 1–2), R05 revision 2 (`research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md`).

#### Request-payload fingerprint

##### Landscape

Bin: **established industry standard** for the algorithm (SHA-256, FIPS 180-4)
and **built-in / first-party** for the library (`sha2` is a RustCrypto crate, the
Rust project's de facto cryptography organisation). The up-and-comer bin holds
the fast non-cryptographic hashes — `blake3`, `xxhash-rust`, `twox-hash`. There
is no *first-party toolchain* answer: `std::hash::DefaultHasher` exists and is
explicitly disqualified by its own documentation, quoted below.

##### Principles and implementation

Draft-07 §2.4 says an idempotency fingerprint "is generated from request payload
data by the resource" and lists "Checksum of the entire request payload" first.
Draft §2.7 turns a mismatch into 422. This member supplies that checksum, and
three properties decide which crate does it.

1. **It must be stable.** The fingerprint is stored in the entry, and py names
   the entry shape "the contract a future Redis-backed store must round-trip"
   (`:66-67`). A digest written by one process and compared by another — possibly
   a differently-versioned one, possibly not even written in Rust — must be the
   same bytes. `std::hash::DefaultHasher` fails this on the record: "The internal
   algorithm is not specified, and so it and its hashes should not be relied upon
   over releases" (`https://doc.rust-lang.org/std/hash/struct.DefaultHasher.html`,
   2026-09-18). That single sentence is why this member is a crate at all.
2. **It must not retain the plaintext.** Storing the request body verbatim for
   comparison would be simpler, exact and dependency-free — and it would keep any
   credential a request body carries in an in-process cache for 24 hours. **R56
   does not legislate cache retention**, and no sentence of it is quoted here as
   if it did: its three recorded principles are P1 "A secret is never carried in
   `argv`", P3 "The general-purpose config file is not a credential store" and P5
   "A secret is masked wherever it is displayed"
   (`research/runs/R56/2026-09-17T033528Z-785d25a9d608/review/DECISION.md:131,133,135`).
   The argument here is that P3's reasoning — a general-purpose store is not the
   right place for a credential — applies one step further out to a general-purpose
   response cache, and that draft §5's data-leak warning makes the concrete risk.
   The digest is the shape that removes the question: 32 bytes, reversible into
   nothing. Whether this becomes a fourth R56 principle is R56's to decide, not
   this item's; nothing here requires R56's value to change.
3. **Collision resistance is a defence-in-depth property here, not the primary
   control.** The primary control is key entropy: draft §5 asks for UUIDs. A
   non-cryptographic 64-bit digest would still return 422 to an attacker who does
   not know the original body's digest. SHA-256 is chosen for property 1, with
   property 3 as a free consequence — not the other way round.

Composition: `Sha256::new()`, `update(&body_bytes)`, `finalize().into()` into
`Fingerprint([u8; 32])` — three lines at one call site, exercised by `w03` (422
on mismatch) and by `w01`/`w12` (matching fingerprints replay).

##### Dominant choice

**`sha2` 0.11.0**, `default-features = false, features = ["alloc"]`. Adoption
figures: **257,841,822** 90-day downloads and **955,023,166** all-time (`GET
https://crates.io/api/v1/crates/sha2`, `crate.recent_downloads`,
`crate.downloads`, 2026-09-18) — top-tier for the whole registry. Newest unyanked
version **0.11.0**, `created_at` **2026-03-25T15:05:27Z** (`GET
https://crates.io/api/v1/crates/sha2/versions`). Licence **`MIT OR Apache-2.0`**.
`rust-version` **1.85**. Repository `RustCrypto/hashes`: **2,264** stars, not
archived, `pushed_at` **2026-09-15T06:42:47Z** (`GET
https://api.github.com/repos/RustCrypto/hashes`). Open issues **20** (`GET
https://api.github.com/search/issues?q=repo:RustCrypto/hashes+is:issue+is:open`,
`total_count`). **Issue responsiveness:** across the **10 most recently opened
issues** (#912, #909, #908, #907, #901, #891, #881, #878, #851, #848), eight
received a maintainer reply, all from `newpavlov`; **median time to first
maintainer response 0.06 days (~1.4 hours)**, range 0.00–13.76 days; **one
unanswered** (#912, opened 2026-08-27, still open with zero comments at
retrieval) and one maintainer-opened release-tracking issue with no comments
(#908) (`GET https://api.github.com/repos/RustCrypto/hashes/issues?state=all&sort=created&direction=desc&per_page=100`
plus `/issues/<n>/comments` for each, maintainer identified by
`author_association` ∈ {`OWNER`, `MEMBER`, `COLLABORATOR`} and not the issue
author; all retrieved 2026-09-18). **Advisories:**
`https://rustsec.org/packages/sha2.html` lists one, **RUSTSEC-2021-0100**
(AVX2 miscomputation), **patched ≥ 0.9.8** — so **no open advisory at 0.11.0**
(`https://rustsec.org/advisories/RUSTSEC-2021-0100.html`, 2026-09-18).
**Adopters:** **19,102** reverse dependencies, including `rsa`, `hmac`, `hkdf`,
`pbkdf2`, `ecdsa`, `ed25519-dalek`, `curve25519-dalek`, `spki`, `cookie` and
`brotli` (`GET https://crates.io/api/v1/crates/sha2/reverse_dependencies?per_page=12`,
`meta.total`, 2026-09-18) — the relevance is that this is the crate the Rust
cryptography ecosystem itself is built on, not merely a popular one.
**Maintenance state: active** — released within six months, repository pushed
three days before retrieval, no advisory, sub-two-hour median first response.

##### Qualified shortlist

| Candidate | 90-day dl | Newest unyanked | Licence | `rust-version` | Δ crates | Build script | Digest width |
|---|---|---|---|---|---|---|---|
| **`sha2` 0.11.0** | 257,841,822 | 0.11.0, 2026-03-25 | `MIT OR Apache-2.0` | **1.85** | **+8** | none | 256 bit |
| `blake3` 1.8.7 | 44,594,319 | 1.8.7, 2026-08-20 | `CC0-1.0 OR Apache-2.0 OR Apache-2.0 WITH LLVM-exception` | **none declared** | +4 | yes (`cc`, for assembly backends) | 256 bit |
| `twox-hash` 2.1.4 | 54,298,003 | 2.1.4, 2026-08-27 | **MIT only** | 1.81 | **+1** (zero transitive deps with defaults off) | none | 64 bit (XXH3) |
| `xxhash-rust` 0.8.18 | 30,064,867 | 0.8.18, 2026-07-21 | **BSL-1.0** | none declared | not measured | none | 64 bit |
| `std::hash::DefaultHasher` | n/a | n/a | toolchain | n/a | 0 | none | 64 bit, **unspecified algorithm** |

Endpoints: `GET https://crates.io/api/v1/crates/<name>` and `/versions`,
2026-09-18. `Δ crates` measured by `cargo tree -e normal` against the same
51-crate `axum + tokio` baseline, deduplicated, 2026-09-18.

##### Excluded by gate

| Candidate | Gate | Finding |
|---|---|---|
| `std::hash::DefaultHasher` | stability | "The internal algorithm is not specified, and so it and its hashes should not be relied upon over releases" — the fingerprint is part of an entry shape declared to be a cross-implementation contract, so an unspecified algorithm is disqualifying, not merely risky. |
| `blake3` 1.8.7 | **2 (MSRV declaration)** | `rust-version` is **not declared** in the published manifest (`GET https://crates.io/api/v1/crates/blake3/versions`, `rust_version: null`, 2026-09-18). The policy requires the MSRV be "declared as rust-version in Cargo.toml and tested in CI"; a dependency that declares none cannot be checked by Cargo's MSRV-aware resolver, so the tree's floor is unverifiable. Secondary, under gate 6: it carries a `cc` build script for its assembly backends and substantial `unsafe` SIMD, which is the correct trade for a crate whose purpose is throughput and the wrong one for hashing a request body once. |
| `twox-hash` 2.1.4 | 1 and fit | MIT-only (compatible, but no Apache-2.0 patent grant), and its default feature set pulls `rand`, so it needs `default-features = false`. Genuinely the cheapest option at **+1 crate** and it is the ranked runner-up rather than an exclusion; it loses on property 1 — XXH3 is specified, but far less universally implemented than SHA-256 across the languages a future store might be written in. |
| `xxhash-rust` 0.8.18 | 1 and 2 | BSL-1.0 introduces a third licence into a repository that has settled on `MIT OR Apache-2.0`, and no `rust-version` is declared. |
| Storing the request body verbatim | secret-retention (R56's P3 reasoning extended; draft §5) | Zero crates, exact comparison, no collision risk — and it retains any credential the body carries in an in-process cache for the whole TTL. Rejected on that ground, not on cost. R56 has no recorded rule about caches; see this member's *Principles and implementation*, point 2, for exactly how far its principles reach. |

Gates 4 and 6 for the recommendation: `sha2` has no platform-conditional
requirement for `ubuntu-latest` or `macos-latest` (its backends are runtime-detected
and it compiles on both; this run compiled it on `aarch64-apple-darwin`; Windows
is supported by RustCrypto but not required here). **Build cost, measured:** a
clean debug build of the 51-crate baseline took **12.27 s** wall / **30.59 s**
user CPU; the same workspace with `sha2` added took **11.92 s** wall / **33.84 s**
user CPU — **no wall-clock cost** on a parallel machine, **+3.25 s (+10.6 %)**
CPU (`/usr/bin/time -p cargo build` after `cargo clean`, 2026-09-18). Binary size
was not measured and no figure is claimed; the qualitative statement is that
eight small, `no_std`-capable crates with no build script add little, and that
statement is not a measurement. **`unsafe` posture, stated:** `sha2` 0.11.0
contains `unsafe` in its architecture-specific backends — 14 of 29 source files,
concentrated in `src/sha256/x86_sha.rs`, `src/sha512/x86_avx2.rs`,
`src/{sha256,sha512}/aarch64_*.rs`, the `wasm32_simd128` and `riscv_zknh` paths
— and none in the portable `soft` path beyond one `unroll` helper per digest
(`https://static.crates.io/crates/sha2/sha2-0.11.0.crate`, source read
2026-09-18). It does not set `#![forbid(unsafe_code)]`. This is expected of a
hash implementation with CPU-feature backends and it is the crate that
RUSTSEC-2021-0100 taught to test those backends; it is recorded rather than
waved past. The template's own crates keep `#![forbid(unsafe_code)]`, which was
executed.

##### Up-and-comers

Nothing in this category is moving in a way that would change the choice.
`blake3` remains the performance answer and would become the fit answer if it
declared a `rust-version`. Watch for RustCrypto's `hybrid-array` and `digest`
0.11 line settling, since the +8-crate figure is mostly those two and their
`typenum` dependency, and a future consolidation would shrink it.

##### Fit for this template

The fingerprint is computed once per keyed unsafe request over a body already
capped by `max_request_bytes`; throughput is irrelevant at that scale, which is
what removes `blake3`'s only advantage. What matters is that the digest is
specified, the licence is the repository's own dual licence, the MSRV is declared
and below the 1.96 floor, and the crate is one nearly every Rust dependency tree
already contains — so the +8 crates are very often +0 in a real consumer's
lockfile.

##### Recommendation

`sha2 = { version = "0.11.0", default-features = false, features = ["alloc"] }`
in `crates/web/Cargo.toml`. `default-features = false` drops the `oid` feature and
with it the `const-oid` dependency, which an X.509 object identifier is of no use
here; `alloc` is retained for `digest`'s allocating APIs. Exact version pinning
follows whatever R69's manifest convention settles; this run pinned `=0.11.0` for
reproducibility.

##### Ranked runner-up

1. **`twox-hash` 2.1.4** with `default-features = false, features = ["xxhash3_64"]`
   — **+1 crate**, zero transitive dependencies, no build script. The right
   choice if the +8-crate figure is judged too high for a template; the cost is
   MIT-only licensing and a digest less universally implemented outside Rust.
2. **`blake3` 1.8.7** — the right choice the day it declares a `rust-version`
   and if fingerprint throughput ever matters.
3. **Verbatim body comparison** — zero crates, exact, and rejected on R56 rather
   than on cost; it becomes acceptable only if the template ever guarantees that
   no request body carries a credential, which it cannot.

##### Tradeoffs

Eight crates and 3.25 s of CPU for 32 bytes is the whole cost, and it buys a
digest that a Redis adapter written in another language can reproduce. Choosing a
cryptographic hash also means the fingerprint is *not* reversible into the body,
which is the point under R56 but does mean an operator debugging a 422 sees two
digests rather than two payloads; logging either payload would be the R56
violation, so the digest is what should be logged.

##### Parameters

Owns nothing; needs nothing changed. `sha2` 0.11.0's `rust-version = "1.85"`
sits below the current `msrv-policy` floor of **1.96** (stable 1.98.1 as of
2026-09-18 per `https://static.rust-lang.org/dist/channel-rust-stable.toml`,
retrieved 2026-09-18, minus two minors), and its licence is exactly the
repository's `license` value. No `CONFLICT:`.

##### Migration implications

One line in `crates/web/Cargo.toml`. One `use sha2::{Digest, Sha256};` and one
three-line `fingerprint()` function in `crates/web/src/idempotency.rs`. The
`Fingerprint([u8; 32])` type itself lives in `crates/core` and depends on no
crate, so `crates/core` gains **no** dependency and R02's `crates/core`
external-dependency allow-list is unchanged. `deny.toml`'s `[bans]` wrapper list
gains no entry: `sha2` is a normal dependency of `crates/web`, which is permitted
to have them.

##### Validation strategy

**Executed**: `w03` proves that the same key with a different body returns 422
and the handler does not run; `w01` and `w12` prove that an identical body
produces an identical fingerprint across separate requests and separate `Bytes`
allocations, which is the property the 422 rule depends on. *Proposed*: a
`crates/core` test pinning the SHA-256 digest of a fixed payload to a literal, so
that a future change of hash crate is caught as a test failure rather than as a
silent cache miss after a rolling deploy — this is the check that makes property
1 enforceable, and it was not run here because the pinned literal belongs in the
template, not in a probe.

##### Confidence & re-verify trigger

**High** on the crate and every gate; **medium** on the choice of a cryptographic
over a non-cryptographic digest, where `twox-hash` is a defensible alternative
and the argument turns on cross-language reproducibility rather than on a
measurement. Re-verify when `sha2` publishes 0.12 or `digest` 0.12; when `blake3`
declares a `rust-version`; when RustSec publishes any advisory against `sha2`; at
the next `msrv-policy` floor advance past 1.96; or by **2027-03-18**.

##### Sources

- `GET https://crates.io/api/v1/crates/sha2`, `/versions`, `/reverse_dependencies?per_page=12`. Retrieved 2026-09-18.
- `GET https://api.github.com/repos/RustCrypto/hashes`; `GET https://api.github.com/search/issues?q=repo:RustCrypto/hashes+is:issue+is:open`; `GET https://api.github.com/repos/RustCrypto/hashes/issues?state=all&sort=created&direction=desc&per_page=100` and `/issues/{909,907,901,891,881,878,851,848}/comments`. Retrieved 2026-09-18.
- `https://rustsec.org/packages/sha2.html`, `https://rustsec.org/advisories/RUSTSEC-2021-0100.html`. Retrieved 2026-09-18.
- `https://static.crates.io/crates/sha2/sha2-0.11.0.crate` — source read for the `unsafe` posture. Retrieved 2026-09-18.
- `GET https://crates.io/api/v1/crates/{blake3,twox-hash,xxhash-rust}` and `/versions`. Retrieved 2026-09-18.
- `https://doc.rust-lang.org/std/hash/struct.DefaultHasher.html`. Retrieved 2026-09-18.
- `https://www.ietf.org/archive/id/draft-ietf-httpapi-idempotency-key-header-07.txt` §2.4, §5. Retrieved 2026-09-18.
- `https://static.rust-lang.org/dist/channel-rust-stable.toml` — stable 1.98.1 (48a229cea, 2026-09-01). Retrieved 2026-09-18.

### Compatibility

The three members were **built and tested together**, not argued to be
compatible. One throwaway cargo package under `$TMPDIR` (deleted after the run)
declared exactly:

```toml
[package]
edition = "2024"
rust-version = "1.96"

[dependencies]
axum = "=0.8.9"
tokio = { version = "=1.53.1", features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }
sha2 = { version = "=0.11.0", default-features = false, features = ["alloc"] }

[dev-dependencies]
tower = { version = "=0.5.3", features = ["util"] }
```

— R69 revision 10's exact pins and feature list for `axum` and `tokio`, `tower`
as a dev-dependency only, plus this bundle's one added crate. Results:

| Evidence | Result |
|---|---|
| Resolution | `cargo metadata` succeeded: "Locking **62** packages to latest **Rust 1.96** compatible versions". Cargo's MSRV-aware resolver held `matchit` at 0.8.4 with 0.8.6 available — i.e. the floor is not merely declared, it visibly constrained the resolution. |
| Build | `cargo build` clean; `cargo clippy --all-targets -- -D warnings` clean, with `#![forbid(unsafe_code)]` on the crate root. |
| Tests | **22 of 22 passed** — 9 store checks under plain `#[test]` (no runtime), 13 router checks under `#[tokio::test]` through `tower::ServiceExt::oneshot`. |
| Dependency shape | `cargo tree -e normal -i tower` shows `tower v0.5.3 ← axum v0.8.9 ← <this package>` — the only `tower` edge is axum's own, so R69's dev-only declaration is not violated by the recommended layer. |
| Advisory sweep on the assembled tree | `bytes` resolves to **1.12.1**, above RUSTSEC-2026-0007's `>= 1.11.1` patch line; `tokio` 1.53.1 is above RUSTSEC-2025-0023's `>= 1.44.2`; `sha2` 0.11.0 is above RUSTSEC-2021-0100's `>= 0.9.8`. No open advisory in the assembled tree. |
| Version matrix | One matrix cell, and it is the one that matters: R69's accepted pins. No other axum/tokio combination was tested and none is claimed to work. |

Shared adopter: none is claimed. `sha2` and `axum` share 19,102 and many
thousands of reverse dependencies respectively, but no single named project was
verified to combine these three at these versions in this arrangement, and
asserting one without checking would be exactly the unchecked claim this
programme forbids. The compatibility evidence here is the executed build, not an
appeal to a third party.

### Parameters

R73 **owns no parameter**: the prompt's `- owns:` line is empty and
`research/CLAUDE.md`'s R73 row shows no owned parameter. The prompt's
`- consumes:` line is also empty, so the four owner-fixed values are the assumed
set, following the precedent of the other empty-`consumes` items
(`research/topics/06-unsafe-code-policy/DECISION.md`, `## Parameters`). The four
lines below are quoted byte-for-byte from `docs/port/PARAMETERS.md`, which this
run's `inputs/PARAMETERS.md` snapshot matches exactly (verified by `diff`,
2026-09-18: identical).

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

**No `CONFLICT:` line.** Nothing in this recommendation requires a consumed
parameter to change. Each fixed value was applied rather than recited: edition
2024 is what the probe declared and built under, and the `let`-chain in the
adapter's eviction branch is an edition-2024 construct; the MSRV floor of **1.96**
(stable **1.98.1**, `https://static.rust-lang.org/dist/channel-rust-stable.toml`,
retrieved 2026-09-18, minus two minors) is what the probe declared, and Cargo's
MSRV-aware resolver visibly held `matchit` back to honour it — `sha2` 0.11.0
declares 1.85, `axum` and `tokio` are R69's already-gated pins, and **`blake3` was
excluded precisely because it declares no `rust-version`**; the licence gate
excluded `xxhash-rust` (BSL-1.0) from the dominant slot and is why `sha2`'s
`MIT OR Apache-2.0` beat `twox-hash`'s MIT-only; the OS matrix is honoured in that
nothing recommended is platform-conditional, with the executed-on-macOS-only gap
stated under *Validation strategy* rather than papered over.

**Researched values this design is written against, recorded in prose rather than
as `- assumes` lines** (because the prompt's `consumes:` line is empty and the
repository validator derives the assumed set from it):

- **`web-extra-surface` (R69).** The registry row at `docs/port/PARAMETERS.md`
  still carries revision 9's bytes, which place the web tree at
  `src/web/` — quoted verbatim for the clauses this design relies on: "the library
  module src/web/ containing AppState, build_router, the per-resource route
  modules, the handlers, shutdown_signal and serve_until"; "every later web layer
  - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware,
  R77's settings, R80's probes - as modules inside that same gated src/web/ tree";
  "tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process
  test idiom"; "every service knob such as host, port, log format and drain
  deadline stays an environment variable named by R77". **R69 revision 10 is
  owner-accepted and unpublished** (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`,
  owned value at line 1791; owner rulings W1-R02 and W0-R69c), and it moves that
  tree to the optional member **`crates/web`**, with `axum` and `tokio` declared
  non-optionally in `crates/web/Cargo.toml` and `tower` as `crates/web`'s
  dev-dependency. **This design uses the `crates/web` paths throughout.** R69's
  republication is a re-verify trigger on every member. This is not a `CONFLICT`:
  the recommendation needs no change to R69's value, only to its already-accepted
  paths.
- **`error-taxonomy-exit-codes` (R67, published).** Every error this layer
  produces — 400, 409, 413, 422, 503 — is an HTTP status, and R67's `Exit`
  taxonomy governs *process* exit codes, not HTTP ones, so no catalogue row is
  requested here. The *bodies* are R70's `application/problem+json` envelope; the
  probe's `problem()` helper is a stand-in and is labelled as one in the source.
- **`http-transport-injection-seam` (R01, published).** The port follows it
  clause for clause: `Send + Sync`, no `async fn`, no generic methods, blanket
  `impl for Arc<T>`, erased to `Arc<dyn IdempotencyStore>` at the composition
  root, fake injected as an implementor. Executed by check `s09`.

### Migration implications

File-level changes in the template, in the paths R69 revision 10 and R02
revision 1 establish.

| Path | Change |
|---|---|
| `crates/core/src/idempotency.rs` | **new** — `CacheKey`, `Fingerprint`, `CachedResponse`, `Begin`, `PortError` reuse, `trait IdempotencyStore`, blanket `impl for Arc<T>`, `trait Clock`, `AlwaysFreshStore` fake. No external dependency. |
| `crates/core/src/lib.rs` | `mod idempotency;` plus the `pub use` of the port and its types. |
| `crates/core/tests/idempotency_store.rs` | **new** — checks `s01`–`s09`, plain `#[test]`, no runtime. |
| `crates/web/src/idempotency.rs` | **new** — header constants, key validation, `fingerprint()`, the `from_fn_with_state` handler, replay reconstruction, `AbandonOnDrop`. |
| `crates/web/src/lib.rs` | `mod idempotency;` and one `.layer(axum::middleware::from_fn_with_state(...))` call inside `build_router`, at the index R75 fixes. |
| `crates/web/Cargo.toml` | one dependency line: `sha2 = { version = "0.11.0", default-features = false, features = ["alloc"] }`. |
| `crates/web/tests/idempotency.rs` | **new** — checks `w01`–`w13` through `tower::ServiceExt::oneshot`. |
| root package composition root | `InMemoryIdempotencyStore::new(ttl, in_flight_ttl, max_entries, Arc::new(SystemClock::default()))`, erased to `Arc<dyn IdempotencyStore>` and handed to `build_router` beside R01's `ProjectsService`. |
| `deny.toml`, `crates/core/clippy.toml`, `tests/workspace_edges.rs` | **unchanged** — no new `crates/core` dependency, no new banned type, no new intra-workspace edge. |

**Constraints handed to R75 (`http-middleware-stack`), which owns F317.** This
item does not fix the order; these are the constraints it must satisfy, each with
its reason, so R75 can place the layer without re-deriving them.

1. **Idempotency must sit *inside* `CompressionLayer`.** This is correctness, not
   taste: if compression runs inside, the cached entry stores an already-encoded
   body together with its `Content-Encoding`, and a replay to a client whose
   `Accept-Encoding` differs returns a body that client cannot decode.
2. **Inside `RequestBodyLimitLayer`.** The standard layer should reject an
   oversize body with its own 413 first; the idempotency cap is then a second,
   smaller ceiling that applies only to keyed requests.
3. **Inside `CatchPanicLayer` and `TimeoutLayer`.** Both work by dropping the
   inner future; the `AbandonOnDrop` guard releases the claim when that happens,
   and the in-flight deadline is the backstop if the process dies outright.
4. **Inside request-id and access-log layers.** A replayed response must carry a
   request id and be logged like any other response; a replay that never appears
   in the access log is an observability hole.
5. **Outside nothing in particular** — no layer needs to run inside it.
6. **Route scope.** Installed with `.layer` on the router that carries the unsafe
   routes, not `.route_layer`, so that a 405 from axum's own method router is not
   preceded by a claim.

**Coupling proposed to R74 (`rate-limiting-middleware`), not fixed.** Place rate
limiting **outside** idempotency. Two reasons: a 429 then never reaches this
layer, so a rate-limited request never creates a claim it must abandon — which
matches Stripe's stated behaviour that a request rejected before endpoint
execution "doesn't save the idempotent result"; and this layer buffers the
request body to fingerprint it, so a request that will be rejected should be
rejected before that copy is paid for. R74 owns the decision.

**Handed to R70 (`http-problem-envelope`).** Five bodies: **400** invalid or
missing-where-required key; **409** a request is outstanding for this key; **413**
request body too large to replay; **422** key already used with a different
payload; **503** store unavailable. Draft-07 §2.7 gives example `type`, `title`
and `detail` strings for the first three and cites RFC 7807, which RFC 9457
obsoletes; R70's envelope is the current shape and should be used, with a `Link:
<…>; rel="describedby"` header as an option the draft also offers. R70 also
inherits the question the corrected F314 raises and answers: **error responses
are never replayed**, so no envelope needs a replay marker.

**Handed to R71 (`openapi`).** Every unsafe-method operation documents an
optional `Idempotency-Key` request header (string, ≤ 255 characters, UUID v4
recommended per draft §2.2), an `Idempotency-Replayed` response header on 2xx,
and the 400/409/413/422 responses above. The header name is fixed by the draft
and is not a naming choice. R71 also inherits the bounded-body rule from member
1's *Tradeoffs*: an operation that advertises `Idempotency-Key` must return a
2xx body of known, bounded size, because a streaming or oversize 2xx is passed
through uncached and its retry re-executes — and that limitation belongs in the
published contract, not only in the source.

**Handed to R77 (`web-env-settings`), names proposed only.** Four knobs with py's
defaults where py has one: entry TTL **86,400 s** (py `settings.py:72`; also
Stripe's published retention), in-flight deadline **30 s** (new — py has no
in-flight state), `max_entries` **1,024** (py `settings.py:73`), and the request
and response body caps. R77 owns the spellings.

**Handed to R32 (`test-harness-and-execution`).** `s01`–`s09` are core unit tests
with no runtime; `w01`–`w13` are `crates/web` integration tests requiring the
`web` feature and a tokio runtime. The split is the tier boundary.

### Validation strategy

Everything below ran in this session against a throwaway workspace under
`$TMPDIR/r73work/probe`, on `aarch64-apple-darwin`, `rustc 1.98.0 (88d9e12ae
2026-08-18)`, against the manifest quoted under `### Compatibility`. The
directory was deleted after the run; the commands are given so the work is
reproducible, not so a reader can find the files.

**Executed — results, not intentions.**

| Command | Expected | Observed |
|---|---|---|
| `cargo metadata --format-version 1` | resolves under the 1.96 floor | "Locking 62 packages to latest Rust 1.96 compatible versions"; `matchit` held at 0.8.4 |
| `cargo build` | clean | clean |
| `cargo clippy --all-targets -- -D warnings` | clean, under `#![forbid(unsafe_code)]` | clean |
| `cargo test --test store` | 9 pass, no async runtime in scope | **9 passed, 0 failed** |
| `cargo test --test web` | 13 pass | **13 passed, 0 failed** |
| `cargo test --release --test store s08 -- --nocapture` | store call far below 1 ms | **159 ns/op**; the same check on the rejected sweep-every-call design measured **477,159 ns/op** debug versus **1,595 ns/op** for the recommended one |
| `cargo tree -e normal -i tower` | the only `tower` edge is axum's | `tower v0.5.3 ← axum v0.8.9 ← <package>` |
| `cargo tree -e normal` deltas | measured, not estimated | baseline 51; `+sha2` 59; `+hashlink` 54; `+lru` 56; `+quick_cache` 60; `+mini-moka` 62; `+moka` 65; `+axum-idempotent +ruts +tower-cookies` **100** |
| `cargo clean && /usr/bin/time -p cargo build`, with and without `sha2` | build cost stated | 12.27 s wall / 30.59 s user → 11.92 s wall / 33.84 s user |

The thirteen router checks are the acceptance criteria 1–13 table, one check per
criterion, each asserting both the status and the handler's execution count so
that "did not re-execute" is proved rather than inferred from a matching body.

**Proposed — not run, and marked as such.**

1. The same 22 checks on `ubuntu-latest`. This run executed on macOS only; the
   `target-os-matrix` gate is satisfied by the absence of platform-conditional
   code, not by an executed Linux run.
2. A `crates/core` test pinning the SHA-256 digest of a fixed payload to a byte
   literal, so a change of hash crate fails a test rather than silently
   invalidating every stored fingerprint across a rolling deploy.
3. `cargo build` with the `web` feature off, asserting the whole tree is absent —
   R02 revision 1 already executed the equivalent (`B1`/`B2`).
4. A loom or `cargo test -- --test-threads=N` concurrency check driving two real
   in-flight requests at one key through a live server, rather than seeding the
   marker by hand as `w11` does. `w11` proves the 409 branch; it does not prove
   the race is won atomically under real contention, and that distinction is
   stated rather than blurred.
5. An OpenAPI snapshot check once R71 lands.
6. A poisoned-`Mutex` check asserting that `begin` returns
   `Err(PortError::Unavailable { … })` rather than panicking, and that the layer
   turns it into 503. The probe used `.expect("store poisoned")`, so this branch
   is **recommended but not executed**; R03 rule 5's catalogue table is the
   authority for the variant and for its `RSLB101` mapping.
7. An oversize- or streaming-2xx check asserting whichever disposition P03 picks
   for the hole named in member 1's *Tradeoffs*. `w09` proves only the current
   pass-through behaviour.

### Confidence & re-verify trigger

**High** on the recommendation as a whole. Every behavioural clause is executed;
the one figure that could have changed the design was measured, and it did change
the design once before settling. **Medium** on two specific things, both stated
rather than buried: that no suitable crate exists (crates.io search is
keyword-based, six spellings were tried, and a crate named outside them would be
missed), and that SHA-256 rather than a 64-bit non-cryptographic digest is the
right fingerprint (the argument is cross-language reproducibility, not a
measurement). **Low-confidence and explicitly not claimed**: any statement about
end-to-end request latency or throughput under load, and any statement about
behaviour on `ubuntu-latest`.

Re-verify when **axum publishes 0.9**; when **R69 republishes** (the `crates/web`
paths this design uses are accepted-but-unpublished); when **R02, R03, R05, R56
or R70 publishes** a decision differing from the accepted revisions this is
written against; when **R74 or R75 publishes** an ordering that contradicts the
six constraints handed over above; when **`axum-idempotent`** publishes a release
that adds an allow-list status rule and a store trait not bound to `ruts`; when
the **httpapi working group revives `draft-ietf-httpapi-idempotency-key-header`
past -07** (it expired 2026-04-18) or it reaches RFC, since the 400/409/422
assignments this design follows would then become normative; when **RustSec**
publishes an advisory against `sha2`, `axum`, `tokio` or `bytes`; at the next
**`msrv-policy` floor advance past 1.96**; or by **2027-03-18**, whichever comes
first.

### Sources

**Standards and vendor documentation.** `draft-ietf-httpapi-idempotency-key-header-07`,
`https://www.ietf.org/archive/id/draft-ietf-httpapi-idempotency-key-header-07.txt`
and `https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/`
(retrieved 2026-09-18) — revision **-07**, October 2025, **expired 18 April 2026**,
"Expired & archived", intended status "(None)"; §2.2 uniqueness ("The idempotency
key MUST be unique and MUST NOT be reused with another request with a different
request payload"); §2.4 fingerprint ("Checksum of the entire request payload");
§2.6 enforcement ("SHOULD respond with the result of the previously completed
operation, success or an error"; "The request was retried before the original
request completed. The resource SHOULD respond with a resource conflict error");
§2.7 statuses (**400** missing, **422** "attempt to reuse an idempotency key with
a different request payload", **409** "retried, while the original request is
still being processed"); §4 Implementation Status (Stripe, Adyen, Dwolla,
Interledger, WorldPay, Yandex, http4s); §5 Security Considerations (low-entropy
keys and cross-client cache reads; "implement a unique composite key … combining
the idempotency key sent by the client with other client specific attributes
known only to the resource"). RFC 9110 §9.2.2,
`https://www.rfc-editor.org/rfc/rfc9110.txt` (2026-09-18) — "PUT, DELETE, and
safe request methods are idempotent". Stripe,
`https://docs.stripe.com/api/idempotent_requests` (2026-09-18) — replay
regardless of success or failure; 255-character keys; 24-hour retention;
parameter comparison; "Avoid using sensitive data … as idempotency keys"; results
saved only after endpoint execution begins.

**Source repositories at their pins.** py `b08bccfb55d05f15e46a83b52c5660b1881d19f5`:
`src/py_launch_blueprint/web/idempotency.py` (module docstring `:20-31`;
`IDEMPOTENCY_HEADER` `:43`; `_UNSAFE_METHODS` `:45`; `_CacheKey` `:48-62`;
`_Entry` `:65-77`; defaults `:82-91`; replay `:110-123`; the 2xx condition and
LRU trim `:139-149`), `src/py_launch_blueprint/web/app.py:127-146` (middleware
installation order), `src/py_launch_blueprint/web/settings.py:71-73`,
`tests/web/test_idempotency.py` (eight tests, whose names map one-to-one onto
criteria 1, 4, 5, 2, 7 and the LRU check). ts `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`:
none — `docs/port/areas/web-service.md:100` records "no decision entry addresses
web-service scope", so there is no TypeScript shape to reconcile with.

**Crate figures.** `GET https://crates.io/api/v1/crates/<name>` and
`/versions` for `axum-idempotent`, `actix-idempotent`, `sova-idempotency`,
`ruts`, `moka`, `mini-moka`, `lru`, `hashlink`, `quick_cache`, `schnellru`,
`sha2`, `blake3`, `twox-hash`, `xxhash-rust`, plus
`/reverse_dependencies?per_page=12` for `sha2`; crates.io search
`?q=<term>&per_page=30` for six terms; `https://static.crates.io/crates/<name>/<name>-<version>.crate`
for `axum-idempotent` 0.3.0 and `sha2` 0.11.0 (read as source, not summarised).
GitHub REST: `repos/jimmielovell/axum-idempotent`, `repos/LukeMathWalker/zero-to-production`,
`repos/bhatti/idempotency-rs`, `repos/RustCrypto/hashes`, `repos/moka-rs/moka`,
`repos/djc/hashlink`, `search/issues?q=repo:<o>/<r>+is:issue+is:open` for three
repositories, and `repos/RustCrypto/hashes/issues` plus eight `/comments` pages.
RustSec: `packages/{sha2,moka,hashlink,lru,quick_cache,blake3,twox-hash,axum-idempotent,ruts,axum,tokio,http-body-util,bytes}.html`
and `advisories/{RUSTSEC-2021-0100,RUSTSEC-2026-0002,RUSTSEC-2026-0253,RUSTSEC-2026-0007,RUSTSEC-2025-0023}.html`.
All retrieved **2026-09-18**.

**Maintainer documentation.** `https://docs.rs/axum/0.8.9/axum/middleware/fn.from_fn_with_state.html`;
`https://docs.rs/tokio/1.53.1/tokio/sync/struct.Mutex.html`;
`https://doc.rust-lang.org/std/hash/struct.DefaultHasher.html`;
`https://static.rust-lang.org/dist/channel-rust-stable.toml`. All 2026-09-18.

**In-repository inputs.** `docs/port/COMMONALITY.md:317-319` (F313, F314, F315,
`py-only`, `DIVERGENT`, R73) and `:307,320-321,327` (F303, F316, F317, F323 for
the coupling boundaries); `docs/port/PARAMETERS.md`;
`docs/port/areas/web-service.md:95-100`; `docs/port/README.md:67-72` (verdict
vocabulary); `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`;
`docs/planning/p02/owner-decisions.md:401-432` (§11, the standing-input ruling);
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` (revision
10, accepted and unpublished; owned value at line 1791);
`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md` (revision
1, the four-package workspace);
`research/runs/R03/2026-09-17T033527Z-cd9e6a9555b6/review/DECISION.md` (revision
1, rules 1–2); `research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md`
(revision 2, the synchronous model and the `spawn_blocking` bridge);
`research/runs/R56/2026-09-17T033528Z-785d25a9d608/review/DECISION.md` (revision
2, the secret policy); `research/runs/R54/2026-09-17T033527Z-8dfef31d60fc/review/DECISION.md`
(revision 3, recorded as inapplicable and why); `research/topics/06-unsafe-code-policy/DECISION.md`
(`## Parameters`, the empty-`consumes` precedent).

**Method notes.** Endpoints queried: the crates.io JSON API (`/crates`,
`/crates/<name>`, `/crates/<name>/versions`, `/crates/<name>/reverse_dependencies`,
and `static.crates.io` for two published `.crate` tarballs read as source); the
GitHub REST API through a keyring-authenticated `gh api`, never more than one
call per 20 seconds — the eight `issues/<n>/comments` fetches for the
responsiveness figure were run from a spaced background loop for that reason;
`rustsec.org` package and advisory pages; `ietf.org` and `datatracker.ietf.org`;
`rfc-editor.org`; `docs.stripe.com`; `docs.rs`; `doc.rust-lang.org`;
`static.rust-lang.org`; and `raw.githubusercontent.com` for three source files.
No personal email address and no token bytes appear in this report. **What I
could not verify:** (a) no execution on `ubuntu-latest` — every build, test and
measurement ran on `aarch64-apple-darwin` with `rustc 1.98.0` Homebrew, and the
`target-os-matrix` gate rests on the absence of platform-conditional code rather
than on an executed Linux run; (b) no shared adopter combining `axum` 0.8.9,
`tokio` 1.53.1 and `sha2` 0.11.0 in this arrangement was found, and none is
claimed — the compatibility evidence is the executed build; (c) issue
responsiveness for `moka`, `hashlink`, `lru` and `quick_cache` was not collected,
because the recommendation adds none of them and the GitHub call budget was spent
on the one crate the bundle does adopt; (d) no end-to-end latency or throughput
figure was produced, and the 159 ns/op microbenchmark is deliberately **not**
extrapolated to request-level performance; (e) `w11` seeds the in-flight marker
directly rather than racing two live requests, so the 409 branch is proved but
the atomicity of the race under real contention is not; (f) the Codex leg is
absent by owner ruling W1-CODEX3 (2026-09-18), so no second model family reviewed
this report, and the `BASELINE-REVIEW` on F314 in particular has had no
adversarial read.
