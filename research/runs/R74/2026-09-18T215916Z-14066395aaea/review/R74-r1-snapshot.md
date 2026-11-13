# 2026-09-18 — R74 — rate-limiting-middleware (bundle, Deep) — decision (revision 1)

**The shipped default moves from off to on, and this is the one thing to read first.**
The prompt asks whether the template adopts a rate limiter "off by default and enabled by
one env var", which is what py does (F323). On 2026-09-18 — after this item's prompt was
written and after its engines ran — the owner ruled that the organisation's REST API
Design Standard v2.0.0 binds this template's HTTP surface (`docs/port/OWNER-REVIEW.md`,
"2026-09-18 — the REST API Design Standard binds the HTTP surface (W2-REST)"). That
standard's **R11.2 is a MUST**: *"An API MUST apply rate limits and communicate exhaustion
via the published HTTP mechanism: `429 Too Many Requests` with `Retry-After`. This MUST is
a deliberate tightening of RFC 6585 §4's MAY — house policy over a published standard"*
(pinned blob, lines 1686–1688; check `R11.2`). R11.2 carries no §1.8 applicability switch,
and the switch vocabulary has no rate-limiting member (checks `S3a`, `S3b`), so it binds
unconditionally. A template that ships with limiting off is nonconformant with a MUST from
its first request, which §1.7 calls *"nonconformance regardless of the deviation's merits"*
(line 273). **This decision therefore moves the recommendation to conform rather than
recording an exception**, and files `BASELINE-REVIEW: F323` so the ledger row that records
py's off-by-default gate is not silently overridden. The conditional-registration mechanism
the prompt's HIGH question 2 asks about is still answered and still compiled — it is simply
no longer the shipped default.

Everything else the prompt asks for is preserved: one process-local store, single-instance
by design, with a named swap point (F316), and a `Retry-After` computed from limiter state.

**This decision is a proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what the research found and what it recommends; P03 builds the
template and its CI proves the recommendation. What P03 must validate is listed under
`## Engines`. A decision that does not survive implementation is revised against this
recorded research, not researched again from scratch.

## Decision

Adopt a rate-limiting middleware that `rs-launch-blueprint` **owns**, composed of three
members and adding **no crate** to `crates/web`:

| Member | Kind | What it is |
|---|---|---|
| Layer mechanism | crate (`axum` 0.8.9, already selected by R69) | `axum::middleware::from_fn_with_state`, keyed from `axum::extract::ConnectInfo<SocketAddr>` |
| Admission algorithm | pattern | GCRA over `std::time::Instant` — one theoretical-arrival-time instant per key, sustained rate and burst as independent parameters |
| Store | pattern | a capacity-bounded `std::sync::Mutex<HashMap<RateLimitKey, Instant>>` behind a `RateLimitStore` trait, which is the named swap point |

The layer is **always registered**. The posture is an unauthenticated per-IP sustained rate
with a burst, defaulting to **10 requests/second with a burst of 20**, configured through
R77's reserved family `RSLBP_WEB_RATE_LIMIT_*`, **no member of which can disable limiting**.
The refusal is `429` carrying `Retry-After` (a ceiling in whole seconds, floored at 1, never
`0`), `RateLimit` and `RateLimit-Policy` in the syntax of
`draft-ietf-httpapi-ratelimit-headers-11`, and a body rendered through R70's
`application/problem+json` envelope. No proprietary `x-ratelimit-*` header is emitted.

**Ledger rows this settles.** `F316` (rate-limit store is in-memory, single-instance by
design) — preserved exactly, and strengthened: the swap point becomes a compilable trait
rather than a paragraph. `F323` (rate limiting is wired but off by default, one env var
enables it) — the *wiring* and the *single configuration surface* are preserved; the
*off-by-default default* is not, and that departure is filed below as a
`BASELINE-REVIEW:` finding. `F317` (middleware ordering) is **R75's**; this item hands it
three ordering constraints and does not decide the order.

**The ecosystem's dominant pair is excluded, and not on taste.** `tower_governor` 0.8.0 and
`governor` 0.10.4 — the owner reference architecture's C11 pick (`inputs/owner-reference-axum-companion-stack-2026-09-16.md:70`)
— both declare **no `rust-version`**, in the published manifest and at `master`
(checks `D-rv tower_governor-0.8.0`, `D-rv governor-0.10.4`, `F2-rv`, `F6`), so both fail
fitness gate 2 under the strict reading the owner settled
(`docs/planning/p02/owner-decisions.md`, "Two things you should know", lines 452–462:
*"an unknown version is insufficient to clear a bar the prompt says must be cleared"*) and
that R69 revision 10 applied to `warp`, `viz`, `pavex` and `tide` (`:1494-1497`). Three
independently measured facts point the same way and are recorded so the exclusion does not
rest on the gate alone: `tower_governor`'s `Retry-After` is computed with
`Duration::as_secs()` and observed as `29` where the true wait is 29.99…s (checks `D2a`,
`B with_connect_info_…`); its default key extractor returns **500** under R69's own
`axum::serve(listener, app)` and `oneshot` paths (checks `D2d`, `D2e`,
`B without_connect_info_…`); and its 429 body is the bare string
`"Too Many Requests! Wait for {}s"` with no `content-type` (check `D2f`), which R5.12
does not carve out, because the carve-out names *"rate limiters … terminating before
application code"* (line 1023) and this one is application code. It also adds **37** crates
with `tonic` off and **49** with its defaults (checks `C3`, `C4`).

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.** py
wires one app-wide rate limit keyed by the caller's remote address, rejecting excess with
429 rendered through the same problem-document envelope as every other error, carrying
headers computed from the limiter's own state, and holding its counters in this process's
memory with the distributed-store swap documented and not built. The pinned source:
`src/py_launch_blueprint/web/settings.py:70` declares `rate_limit: str | None = None`;
`app.py:143` reads `if settings.rate_limit:` and only then calls `_install_rate_limiting`;
`app.py:220` builds `Limiter(key_func=get_remote_address, default_limits=[default_limit],
headers_enabled=True)` with **no** `storage_uri`, so slowapi's in-memory backend is the
store (F316); `app.py:230-241` renders the rejection through `problem_response(...)` and
then calls `limiter._inject_headers(...)` under the comment *"never a guess"*. Read through
the pin, `git -C ~/c/py-launch-blueprint show b08bccfb:<path>`, 2026-09-18. ts has no web
service (`docs/port/areas/web-service.md:7`), so there is no second precedent.

The **agreement level is a capability plus a policy**, not a library: *the service refuses
excess traffic per caller; the refusal is a standards-conformant 429 whose `Retry-After` is
derived from limiter state; the state is single-instance by design with a named swap point;
and the quota is configurable through one settings surface.* Nothing about `slowapi`,
`limits`, GCRA or token buckets is part of the agreement. What may vary: the algorithm, the
map type, the header set, and whether the check is a `tower` `Layer` or a function. **What
the binding standard removes from "may vary" is the default**: py's `None`-means-off is not
portable into a conformant template, which is the same conclusion R77 revision 2 reached
independently for the settings surface.

**Essential behaviours and observable acceptance criteria.**

| # | Behaviour | Observable criterion | Status |
|---|---|---|---|
| B1 | Limits apply as shipped | With no `RSLBP_WEB_RATE_LIMIT_*` variable set, a caller exceeding the default posture is refused | executed (`A the_shipped_default_posture_is_on_and_limits`) |
| B2 | One settings surface tunes it | Setting members of the reserved family, with no recompilation, changes the quota; no member turns it off | mechanism executed (`A conditional_registration_is_the_gate`); the env plumbing is R77's |
| B3 | Correct admission | With sustained `N/period` and burst `B`, the first `B` requests from one key are admitted and the `B+1`-th is refused | executed (`A third_request_…`, `A the_shipped_default_posture_…`) |
| B4 | Per-key isolation | A second key is unaffected by the first key's exhaustion | executed (`A keys_are_isolated_…`) |
| B5 | Standards-conformant refusal | Status is 429; `Retry-After` is a non-negative decimal integer (RFC 9110 §10.2.3) and is present on every 429 (R11.5) | executed (`A third_request_…`) |
| B6 | Accurate `Retry-After` | Derived from limiter state, never a constant, and never **earlier** than the true next admission | executed (`A retry_after_is_never_zero` asserts the ceiling: 29.99 s → 30) |
| B7 | In-memory, bounded, single-instance | State lives in this process, cannot grow without bound, and the swap point is a named type | executed (`A keys_are_isolated_and_the_store_is_bounded`) |
| B8 | One envelope | The refusal renders through the service's single error representation (R70's), not a second ad-hoc body | **proposed** — blocked on R70; the probe asserts status and headers against a placeholder body |
| B9 | Quota state advertised | `RateLimit` and `RateLimit-Policy` in draft-11 syntax accompany the 429 (R11.3, a SHOULD) | executed (`A third_request_…`, `A the_shipped_default_posture_…`) |

**Architectural alternatives, compared before libraries.**

*A1 — a `tower::Layer`/`Service` pair (what `tower_governor` is).* Composes with
`ServiceBuilder` and is reusable outside axum. Cost: a `Service`'s response type is
`http::Response<B>`, so the layer can only *build a response*; rendering through R70's
envelope needs a `fn(GovernorError) -> Response` handler that calls the envelope function,
and the rejection is never a value of R70's error type.

*A2 — `axum::middleware::from_fn_with_state`.* An `async fn(State, Request, Next) ->
Result<Response, E>` where `E: IntoResponse`. axum wraps it into a `Layer`, so it sits in
the same `.layer()` stack R75 orders. Its decisive advantage is the return type: the
rejection is a value of the web member's own error type, so R70's `IntoResponse` renders it
by construction. **Selected.**

*A3 — a per-handler extractor, or a `Layer` applied per route.* Rejected as the primary
mechanism: an extractor cannot see `Next` and so cannot be composed into the single ordered
stack R75 owns. A per-route *quota dimension* is a different question and is the subject of
`OVERRIDE (OV-17)` below.

*A4 — push the limit out of the process (reverse proxy, API gateway).* The genuinely
different architecture, and the right one at scale, because a per-instance in-memory
limiter enforces `quota × instances`, not `quota`. Rejected *for this item* for the reason
py rejected it: a template must demonstrate the shape in the artefact it ships. Under the
new default an operator who fronts the service with a gateway **raises** the per-IP rate
rather than removing the layer; disabling is deliberately not expressible, per R77
revision 2's Move 2 constraint 2.

**Does the shared pattern remain appropriate in Rust?** Yes, with two substitutions. py's
gate is a truthy settings value read at app-construction time; Rust's equivalent is
`Option<T>` and conditional registration, and `axum::Router::layer` consumes and returns
`Router`, so `match policy { None => router, Some(p) => router.layer(…) }` compiles with no
`Either`, no `option_layer` and no boxing — compiled and asserted
(`A conditional_registration_is_the_gate`). That is the answer to the prompt's HIGH
question 2, and it is recorded in full because `OVERRIDE (OV-17)`'s option list may restore
it. The second substitution is the default itself, argued above. A Cargo feature is
**rejected on principle** in either case: a feature moves the gate to compile time, so the
shipped binary would no longer *contain* a limiter that configuration tunes. R69's `web`
feature already gates whether the whole web tree exists; a second compile-time gate inside
it buys nothing.

**Why GCRA, and why not a fixed window.** The standard settles this better than adoption
figures do. R8.10's rate-limit axis default names *"per-principal sustained + token-bucket
burst"* (line 1397): sustained rate and burst are **two independent parameters**. GCRA
carries both exactly — emission interval `T = period / rate`, tolerance
`tau = (burst - 1) * T`, one `Instant` of state per key, two comparisons per request — and
on refusal it yields the exact next-admission instant that `Retry-After` is the ceiling of.
A fixed-window counter cannot express a burst separate from the rate at all, and admits up
to `2 × quota` across a window boundary. **This corrects the Opus report**, which rejected
fixed window on the ground that its reported wait "over-states the wait for every request
except the last": that is wrong. In a fixed window a refused caller genuinely cannot succeed
until the window rolls, so the window end *is* the exact next admission. The real defect is
the boundary burst, which is what the openai leg named and what R8.10's wording rules out.
Token bucket is behaviourally equivalent to GCRA and is rejected narrowly: two fields of
state and a refill computation per check, where GCRA needs one `Copy` value — which is what
makes the store a plain `HashMap` rather than a structure. Sliding-window log is exact but
`O(quota)` memory per key, which fails B7.

**Where the store lives, which no leg decided.** R05 revision 3 fixes a synchronous core
and confines async to the `web` feature, but says nothing about where web-layer state
lives, and the two nearest precedents disagree: R77 revision 1 puts `Arc<WebSettings>` in
`AppState` inside `crates/web`, while R73's report places its in-memory idempotency adapter
at *"root package's composition root, R02's placement for production adapters"*
(`research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/raw/opus.md:647`). This item follows
R73 and R01: `RateLimitStore` and `InMemoryRateLimitStore` are **declared** in
`crates/web/src/rate_limit.rs`, because the concern is transport-layer and touches no core
port, and the store is **constructed** at the root package's composition root, erased to
`Arc<dyn RateLimitStore>` and handed to `build_router` — which is R01's registered seam
(*"the composition root … erases the production adapter to `Arc<dyn ProjectsPort>`"*,
`research/topics/01-ports-and-adapters-seam/DECISION.md:138`) applied to a second
substitutable dependency. A settings value is data; a store is a substitutable dependency,
which is what the seam exists for. The check runs inline in the async middleware and is
never handed to `spawn_blocking`: it is 68–161 ns and holds a `Mutex` guard across no
`await`.

**Bounding, and the fail-open trade.** The key space is attacker-controlled, so the store
carries a capacity. When the map is full and the key is new it evicts every cell whose
arrival time has already passed; if it is still full the request is **admitted**. That is a
deliberate security trade and is recorded as one: an attacker with many source addresses
can fill the map and disable limiting for new keys, whereas failing closed would let the
same attacker deny service to every new client. A limiter must not become the outage. The
mitigations are a capacity large enough that this costs real resources (default 65,536
cells) and a saturation signal — see the R79 hand-off, which R79 revision 1 has already
declined by shape.

**Production usage and maintained reference examples.** `from_fn_with_state` is axum's own
documented middleware adapter. `loco-rs/loco` 1.1.0 (107,433 90-day downloads, snapshot
`cio-crate-loco-rs.json`) demonstrates config-gated middleware registration as a published
template pattern — and ships **no rate limiter at all**, which is the answer to the prompt's
LOW question: the config-gated-middleware pattern is named and published; *rate limiting
itself* is not a Rust template staple. The algorithm is the same GCRA that `governor`
(77,888,772 all-time downloads, 483 reverse dependencies) implements; this design differs
from it in packaging, not in arithmetic. **The evidence gap is stated plainly: no maintained
reference implementation exists for this exact composition**, because the crates that would
be it are the ones gate 2 excludes. The mitigation is that the composition is executable and
was executed — nine tests, 54 checks, listed under `## Empirical check`.

**The four crates that could have supplied this, and why none does.**

| Candidate | Gate 1 (licence) | Gate 2 (MSRV, floor 1.96) | Gate 3 | Disposition |
|---|---|---|---|---|
| `tower_governor` 0.8.0 | inapplicable — owner ruling 2026-09-12 (Q7.B) | **`null` at the release and no `rust-version` at `master` — FAIL** (`F2-rv`, `F6`) | no RustSec page, HTTP 404 (`F4`) | **Excluded by gate 2**; three measured defects corroborate |
| `governor` 0.10.4 | inapplicable — same ruling | **`null` at the release and at `master` — FAIL** | 404 | **Excluded by gate 2** |
| `axum-governor` 2.1.0 | inapplicable — same ruling | `1.95` — passes on the letter, **one** minor of headroom | 404 | Excluded on **MSRV-policy fit and practice evidence**: R69 excluded `salvo` at **two** minors of headroom (`:1492`); 0 reverse dependencies, 25 stars, repo created 2025-09-03 (`F3`, `F5i`, `F5j`); and it depends on `governor`, which gate 2 excludes |
| `tower-rate-limiter` 0.1.6 | inapplicable — same ruling | `1.96.0` — passes on the letter, **zero** minors of headroom (`E1`, `F6-control`) | 404 | Excluded on **practice evidence and algorithm**: 294 all-time downloads, 0 reverse dependencies, 7 stars, crate first published 2026-08-06 and repo created 2026-08-02 (`F2-dlall`, `F3`, `F5k`, `F5l`); its store is a **fixed window** (`E3`); it adds **18** crates including `moka` (`E5`, `E6`) |
| `gcra` 0.6.0 | inapplicable — same ruling | `1.80.0` — passes | 404 | Excluded on **practice evidence**: 0 reverse dependencies (`F3`), 9 stars, no release since 2024-08-01 (`F2-date`) |
| `axum_gcra` 0.1.1 | inapplicable — same ruling | **`null` — FAIL** (`F2-rv`) | 404 | **Excluded by gate 2**; also 60 90-day downloads and 0 reverse dependencies |
| `tower::limit::RateLimitLayer` (`tower` 0.5.3) | inapplicable — same ruling | `1.64.0` — passes | — | Excluded on **fit**: one global limiter with no key, applying back-pressure by delaying `poll_ready` rather than refusing, so it can produce neither a 429 nor a `Retry-After`. Cannot express B3, B4, B5 or B6 |

**Fitness gates 1 and 4–6 for the recommendation itself.** Gate 1 licence —
`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for
any dependency or tool`; no crate is added and the code is the template's own under
`MIT OR Apache-2.0`. Gate 4 platforms — `std::sync`, `std::time::Instant` and `HashMap` are
core `std` on both `ubuntu-latest` and `macos-latest`; the probe ran on macOS 26.4 arm64.
Gate 5 default features and async-runtime coupling — none; `check` is a synchronous function
over `std::time::Instant` and nothing binds to tokio. Gate 6 binary size and compile time —
qualitatively nil: the resolved non-dev package set is **identical** to R69's baseline,
50 packages in both, `diff` empty (`C0`, `C1`, `C5`, with `C5-control` establishing that the
diff can discriminate). Gate 3 advisories and `unsafe` — no crate is added, so the advisory
surface is exactly R69's, which R69 scanned to exit 0 against a pinned database
(`:2268-2276`); the template code contains **zero** `unsafe`, where taking `governor` would
add `quanta`, `parking_lot`, `getrandom` and `zerocopy` (`C6`).

**`BASELINE-REVIEW: F323 — rate limiting is wired but off by default, one env var enables
it — proposed change: the wiring and the single configuration surface stand; the
off-by-default default does not, and the Rust template ships limiting on — evidence:** the
org REST API Design Standard v2.0.0's R11.2 is a MUST with no applicability switch (pinned
blob lines 1686–1688; checks `R11.2`, `S3a`, `S3b`), made binding on this template's HTTP
surface by owner ruling W2-REST (2026-09-18); §1.7 line 273 makes an unrecorded deviation
from a MUST nonconformance regardless of merit; and R77 revision 2 (sha256
`46b2a05f40f6a3ea27b5fdef415c50adccd27ade5ed6fa94f83ed933503d7f68`) has already withdrawn
the single scalar `RSLBP_WEB_RATE_LIMIT` and reserved the family `RSLBP_WEB_RATE_LIMIT_*`
with the constraint that *"No member's default may disable rate limiting"*. Affected items:
R74 (this one) and R77 (already moved). **F323's row is not edited here** — the ledger
belongs to the controller.

### OVERRIDE (OV-17) — R8.10's rate-limit axis ships one dimension, not the full tiered posture

In the shape of the standard's §1.9 deviation note
(`- <rule ID> · <rule strength> · what differs · why · approver · date`, line 291):

> `R8.10` · MUST · The rate-limit axis default is a *"Multi-dimensional tiered posture,
> published: per-principal sustained + token-bucket burst (start ≈100 rps/account, 25
> rps/endpoint …); unauthenticated per-IP an order of magnitude lower; auth endpoints
> strictly stricter (start ≤5/min per IP+account); failed-auth budget; concurrency
> separate"* (line 1397). The template ships **one** of those dimensions — the
> unauthenticated per-IP sustained rate with a token-bucket burst, at 10/second and burst
> 20. The per-endpoint dimension is omitted; the per-principal, auth-endpoint and
> failed-auth dimensions are N/A-with-reason. · Because this surface has no
> authentication: R77's `WebSettings` *"declares no credential of any kind"*, and the
> template ships no login, no principal and no auth endpoint, so three of the five
> sub-dimensions have nothing to bind to; the fourth, per-endpoint, **could** apply and is
> omitted deliberately, to keep the template's quota surface one policy rather than a
> per-route configuration matrix nobody has asked for. Concurrency limiting is a separate
> mechanism (`tower::limit::ConcurrencyLimitLayer`) and is not this item's. · approver:
> pending owner review · date: 2026-09-18

**Argument.** R8.10's axis is written for a deployed API with authenticated principals and
a published quota page. This template is scaffolding: it ships one unauthenticated resource
and no identity. Adopting the axis default *in full* would require inventing an
authentication model in order to have a principal to meter, which is outside every item in
this wave and contradicts R56's and R77's settled positions. Adopting the *per-IP*
dimension is not a compromise — it is the one sub-dimension the standard names that this
surface can actually carry, and the standard itself prescribes its magnitude ("an order of
magnitude lower" than ≈100 rps/account), which is where 10/second comes from. The burst of
20 is this template's own starting choice — two seconds of sustained rate — and is not
derived from the standard, which supplies no burst figure. The dimension genuinely left on
the table is per-endpoint (25 rps/endpoint): it is expressible today, by keying on
`(IpAddr, MatchedPath)` instead of `IpAddr`, and it is omitted because a second quota
dimension doubles the configuration surface for a template with one resource. That is a
judgement, so it is recorded here to be inverted rather than buried.

**Options.**

1. **Ship one dimension and record this override** (recommended). Cost: the template is
   nonconformant-with-a-recorded-exception on R8.10 until an owner approves; an adopter
   adding authentication inherits an unmetered principal dimension. Benefit: the
   configuration surface is three variables, and the shipped posture is defensible without
   inventing an identity model.
2. **Ship two dimensions — per-IP and per-IP-per-endpoint.** Adds `(IpAddr, MatchedPath)`
   keying (axum's `MatchedPath` extractor, already in `axum` 0.8.9's default features per
   R69's accepted value) and two more family members at 25/second. Cost: two cells per
   caller per route instead of one, so the store's capacity argument changes shape; and a
   second `RateLimit-Policy` element on every 429. Benefit: closes the one omitted
   dimension, leaving only the auth dimensions as N/A-with-reason, which narrows the
   override to an N/A declaration rather than a flip.
3. **Adopt the axis default in full.** Requires a principal, an auth endpoint and a
   failed-auth budget. Cost: an authentication model this wave has not researched and that
   R56 and R77 have positively excluded from the surface. Rejected as out of scope, not on
   merit.
4. **Declare the whole axis N/A-with-reason.** Cost: dishonest — the per-IP dimension is
   not only applicable, it is what the template ships, so an N/A would misdescribe the
   artefact. Rejected.

### Conformance to the org REST API Design Standard v2.0.0 (W2-REST)

Pin: `https://github.com/smorinlabs/rest-standards`, commit
`0850d43e45d919ef5e37f7174c4212b46013c49f`, file blob
`71bd813c1cf61286586b4ee41ed83ff065e5c8d9`. Every line number below is asserted against a
committed snapshot of that blob by `review/evidence/r74-rest-conformance.sh`, which also
asserts the snapshot is byte-identical to the blob in the local clone (checks `P0a`–`P0d`).

| Rule | Line | Strength | What it requires | This design |
|---|---|---|---|---|
| `R11.2` | 1686 | MUST | *"An API MUST apply rate limits and communicate exhaustion via the published HTTP mechanism: `429 Too Many Requests` with `Retry-After`"* | **CONFORMS, and this is the rule that moved the recommendation.** Limits apply as shipped; no configuration member disables them; the refusal is 429 with `Retry-After` |
| `R11.3` | 1701 | SHOULD | *"An API SHOULD additionally advertise quota state using `RateLimit` and `RateLimit-Policy` in the syntax of `draft-ietf-httpapi-ratelimit-headers-11`"*, which line 1703 calls *"an unpublished Internet-Draft, not a standard"* | **CONFORMS.** Both fields are emitted; the pinned revision is cited wherever they are named, and neither is described as standards-compliant. Note honestly: the draft's `q`/`w` pair describes the **sustained rate only** — it has no field for the burst tolerance, which is documented in the API documentation instead |
| `R11.4` | 1707 | MUST | *"Any proprietary quota headers MUST be documented explicitly"* | **CONFORMS vacuously, by emitting none.** This is a second reason to reject `tower_governor`, which emits `x-ratelimit-after`, `x-ratelimit-limit`, `x-ratelimit-remaining` and `x-ratelimit-reset` (`D2c`) against line 362's *"No new `X-` names"* |
| `R11.5` | 1724 | MUST | *"`429` signals quota exhaustion … both MUST carry `Retry-After`"* | **CONFORMS.** Every 429 carries it; the value is floored at 1 so it is never absent and never `0` |
| `R5.12` | 1019 | MUST | every application-generated error response must be available as `application/problem+json`; the carve-out at line 1023 names *"rate limiters … terminating before application code"* | **CONFORMS through R70.** This limiter is application code, so the carve-out does not reach it. `tower_governor`'s bare-text 429 (`D2f`) would be nonconformant without an `error_handler` rewrite |
| `R5.13` | 1049 | MUST | a response-carried problem document MUST carry `type`, `title`, `status` and a stable `code` | **R70's**, and R70 revision 1 omits `type` by default. Recorded as a coupling below, not resolved here |
| `R5.14` | 1098 | MUST | *"RFC 7807 MUST NOT be cited — it is obsoleted by RFC 9457"* | **CONFORMS.** This decision cites RFC 9457. The gemini leg cited RFC 7807; recorded under `## Engines` |
| `R5.16` | 1114 | MUST | an API must publish a catalog of every problem `type`/`code` pair | **Raised, not settled.** R67 has no rate-limit row and R70 revision 1 says the gap *"is R74's to raise, not this item's"*. Raised below |
| `R12.2` | 1784 | MUST | *"Clients MUST honor `Retry-After`"* | **Bears on B6.** Because a conforming client obeys the header, a value below the true wait guarantees a second refusal — which is what `tower_governor`'s truncation produces and why this design uses a ceiling |
| `R8.10` | 1387 | MUST | five deployment-profile axes, each adopted or its flip recorded | **DEPARTS — `OVERRIDE (OV-17)` above** |
| `R1.8` | 229 | — | switch-scoped rules bind only while the switch is on; the vocabulary is `webhooks · async-operations · bulk-operations · streaming` (line 237) | **No rate-limiting switch exists** (checks `S3a`, `S3b`), which is why off-by-default could not have been an N/A-with-reason |
| `R1.10` | 352, 353, 362 | — | `Retry-After` mandatory on 429; `RateLimit`/`RateLimit-Policy` reserved for draft-11 syntax; no new `X-` names | **CONFORMS**; no reserved name is used for any other meaning and no `X-` name is minted |

### Hand-offs, couplings, and one gap this item raises

**R69 (`web-framework-stack`, revision 10, accepted-but-unpublished) — a hand-off, not a
`CONFLICT:`.** `ConnectInfo` is how the middleware gets a caller identity, and
`axum::serve(listener, app)` installs none. R69 revision 10 shows exactly that call inside
`serve_until` at `:1106`. Three facts decide the disposition, and all three were read rather
than assumed: R69's **owned** `web-extra-surface` value at `:1791` names `serve_until` only
as a member of the gated module and fixes none of its arguments; the whole of R69 revision
10 contains **zero** occurrences of `ConnectInfo` or `into_make_service`; and R69's
`re-verify:` line at `:1787` has no trigger that fires on this. So this is not a parameter
that needs changing — no `CONFLICT:` line is raised — but it is a **hard precondition on
P03**: `serve_until` must call
`axum::serve(listener, app.into_make_service_with_connect_info::<SocketAddr>())`. Under the
old off-by-default shape a missing `ConnectInfo` was a degraded opt-in; **under the new
default it means the shipped template meters every caller in the world through one 10/second
`Global` bucket.** The design still falls back to `RateLimitKey::Global` and warns exactly
once through `std::sync::Once` rather than returning 500 — a limiter that turns a wiring slip
into a total outage is worse than one that over-restricts while saying so — but the real
listener test is P03's first validation item, and this decision's `re-verify:` fires on R69
republishing.

**R70 (`http-problem-envelope`, revision 1, being researched in parallel) — coupling.** R70
builds one RFC 9457 document in `crates/web/src/problems.rs` via `problem_details` 0.10.0 as
`ProblemDetails<ProblemExt>`, and `WebError` carries
`headers: Vec<(HeaderName, HeaderValue)>` with a `with_header` builder whose `IntoResponse`
inserts them after the body is rendered (`:158-159`). That is the exact carrier this item
needs: the `RateLimited` value becomes a `WebError` variant carrying `retry-after`,
`ratelimit` and `ratelimit-policy` through `with_header`. Two things are **stated, not
decided here**: R70 omits `type` by default (`:52`) where R5.13 line 1049 requires it and
line 1075 bans `about:blank`, and R70 sets `code` to R67's `ErrorCode::as_str()` token
verbatim (`:57`), whose `RSLB` + three-digit grammar does not match R5.13's
`^[a-z][a-z0-9_]*$`. Both are R70's and R67's to reconcile; W2-REST states that *"Nothing
already accepted is reopened by this ruling"*, and R67 is published.

**The gap this item raises, as R70 asked it to.** There is **no catalog code for rate-limit
exhaustion**. R67's catalog is `RSLB` + three digits with the hundreds digit equal to the
process exit code, and its exit taxonomy (`0 1 2 3 4 5 130 143`) has no member for quota
exhaustion, so a new row has no obvious block. The standard's own example uses
`code: "rate_limit_exceeded"` with
`type: "https://problems.example.com/rate-limit-exceeded"` (lines 3205–3209, checks `E9a`–`E9c`).
**R67 owns the number and the block; this item states the requirement and does not invent
one.**

**R73 (`idempotency-middleware`, in parallel) — a decision this item makes, because R73
handed it over.** R73's report proposes placing rate limiting **outside** idempotency and
says *"R74 owns the decision"* (`raw/opus.md:1218-1224`). **Decided: the rate limiter sits
outside R73's layer.** R73's two reasons hold — a 429 then never creates an idempotency
claim it must abandon, and the idempotency layer buffers the request body to fingerprint it,
so a request that will be refused should be refused before that copy is paid for — and py
agrees at the pin: `app.py:131-145` adds `IdempotencyMiddleware` first and
`_install_rate_limiting` after it, and Starlette's last-added is outermost.

**R75 (`http-middleware-stack`, not yet researched) — three ordering constraints, handed
over.** R75 owns F317 and the final order. (1) The 429 must carry the request-id and
security headers, so the limiter sits **inside** those two. (2) The limiter sits **outside**
R73's idempotency layer, as decided above. (3) The limiter sits **inside** whatever installs
`ConnectInfo`. A fourth, handed over rather than decided: R80's `/healthz` and `/readyz` and
R79's `/metrics` must remain reachable when a caller is being throttled; R79 revision 1
already achieves this for `/metrics` by merging it *"after `route_layer` has been applied"*
(`:220-222`), and R80 records the same problem as *"an input to R75, not a decision for it"*
(`:524-531`). **This item deliberately does not add an exempt-paths configuration knob**: the
reachability of probe paths is a placement property, which is R75's, not a quota setting.
**One ledger observation for R75, verified rather than carried:** F317's note says
*"id/security-header middleware outermost"* and `docs/port/areas/web-service.md:23` cites
`app.py:145 — app.add_middleware(SecurityHeadersMiddleware)` as *"added last (outermost)"*.
At the pin, `app.py:146` adds `RequestIDMiddleware` *after* it, so the actual outermost layer
is the request-id middleware. Read directly this session:
`git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/web/app.py | sed -n '128,150p'`.
The row is R75's; this is reported so R75 can check it, not changed here.

**R77 (`web-env-settings`, revision 2) — the family membership this item owes it.** R77
revision 2 reserves the prefix `RSLBP_WEB_RATE_LIMIT_*`, states that *"R74 fixes which
members exist, their units and their values"*, and constrains the family with *"No member's
default may disable rate limiting"*. This item fixes **three** members:

| Variable | Type and grammar | Default | Why |
|---|---|---|---|
| `RSLBP_WEB_RATE_LIMIT_PER_IP` | py's `limits` notation, `"<count>/<period>"` with `period ∈ {second\|sec\|s, minute\|min\|m, hour\|hr\|h, day\|d}` | `10/second` | R8.10's unauthenticated per-IP dimension, *"an order of magnitude lower"* than the axis's ≈100 rps/account |
| `RSLBP_WEB_RATE_LIMIT_PER_IP_BURST` | positive integer | `20` | R8.10's *"token-bucket burst"*, which the sustained rate cannot carry. Two seconds of sustained rate; this template's choice, not the standard's |
| `RSLBP_WEB_RATE_LIMIT_MAX_ENTRIES` | positive integer | `65536` | the bounded store's cell capacity; named to match R73's `RSLBP_WEB_IDEMPOTENCY_MAX_ENTRIES` |

R77 infers *"at least four members"* from R8.10's four dimensions; three suffice **because**
`OVERRIDE (OV-17)` ships one dimension, and R77 anticipated exactly this: *"If R74 publishes
a posture that needs a different member set, the family prefix still holds and only the
membership moves."* Option 2 of the override would add two more. The `limits` grammar is
kept from py because F323 records a single string per dimension, and because R77's own rule
that *"an exported-but-empty variable is unset"* (`:194`) then means an empty
`RSLBP_WEB_RATE_LIMIT_PER_IP` falls back to `10/second` rather than to "off". A non-empty
invalid value is a startup error, never a silent disable.

**R79 (`prometheus-metrics`, revision 1) — a hand-off R79 has already declined by shape.**
The Opus report hands R79 two counter names, a rejected-request counter and a store-
saturation counter. R79 revision 1 ships exactly two instruments and says so as a position
— *"Two instruments, not three"* (`:36`) — and describes its own scope as *"deliberately
unlike R74's opt-in rate limiting"* (`:322`), a characterization this decision makes stale.
So the hand-off is **a request R79 has pre-emptively refused**, not a coupling this item may
assume. It is recorded as a re-verify trigger: without a saturation counter the fail-open
condition above is silent, which is the one place this design depends on an observability
decision it does not own.

**R02 revision 2 and R05 revision 3 (accepted-but-unpublished) — consumed as facts.** R02
fixes the four-package workspace, with `rs-launch-blueprint-web` at `crates/web/` and the
composition root and `rslbp-serve` binary in the root facade package; every path in this
decision is written against that layout. R05 fixes the synchronous core; the limiter touches
no core port and adds nothing to `crates/core`.

### Migration implications

File-level changes, against R02 revision 2's four-package workspace and R69 revision 10's
`crates/web` layout. Nothing outside `crates/web` and the root package's composition root
changes, and no dependency is added.

| Path | Change |
|---|---|
| `crates/web/src/rate_limit.rs` | **New.** `RateLimitPolicy` + `FromStr` + `with_burst`, `PolicyParseError`, `RateLimitKey`, the `RateLimitStore` port, `InMemoryRateLimitStore`, `RateLimitState`, `retry_after_seconds`, the `RateLimited` rejection, the `rate_limit` middleware function and `install_rate_limit` |
| `crates/web/src/lib.rs` | One line: `mod rate_limit;`; and `build_router` gains one `install_rate_limit(router, policy, store)` call, placed where R75's order puts it |
| root package's composition root | Constructs `InMemoryRateLimitStore` from the settings and erases it to `Arc<dyn RateLimitStore>`, beside R73's idempotency cache |
| `crates/web/src/lib.rs` (`serve_until`) | `axum::serve(listener, app)` becomes `axum::serve(listener, app.into_make_service_with_connect_info::<SocketAddr>())`. **Required**, not optional. Hand-off to R69/R75 |
| `crates/web/Cargo.toml` | One line: `tracing = { version = "0.1", default-features = false, features = ["std"] }` for the warn-once, which adds **zero** packages to the resolved set (check `C2`). R58 may supersede this declaration; if so this item needs none |
| R77's settings module | Three fields for the `RSLBP_WEB_RATE_LIMIT_*` family, with the defaults tabulated above. R77 owns the names and the env plumbing |
| `crates/web/tests/rate_limit.rs` | **New.** The seven executed acceptance tests, plus the R70-envelope assertion once R70 publishes |
| `README.md` / `crates/web` module docs | The swap-point paragraph F316 requires — `RateLimitStore` is the seam, `InMemoryRateLimitStore` is single-instance by design, the enforced rate across `N` instances is `quota × N`, and an external gateway is the production answer at scale — plus the API's conformance note carrying `OVERRIDE (OV-17)` and the published quota, which R11.4 and R8.10 both require to be written down |

re-verify: **2027-03-18**, or earlier on any of — the owner ruling on `OVERRIDE (OV-17)`, or declining it in favour of option 2, which adds the per-endpoint dimension and two family members; the owner ruling on the `BASELINE-REVIEW: F323` finding, where declining the move restores py's off-by-default gate and turns R11.2 into a second override this decision does not currently need; the org REST API Design Standard moving off blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9` or amending R1.7, R1.8, R5.12, R5.13, R5.16, R8.10, R11.2, R11.3, R11.4, R11.5 or R12.2; `tower_governor` or `governor` publishing a release that declares a `rust-version` within the floor, which clears gate 2 and reopens the comparison (checks `F2-rv`, `F6`); the owner revisiting the gate-2 strict reading; **R69** republishing, changing `serve_until`'s `axum::serve` argument, or moving `web-extra-surface`'s registry bytes from `src/web/` to `crates/web`; **R70** publishing the envelope this 429 renders through, or resolving its `type`-omission against R5.13; **R67** answering the rate-limit catalog-row request this decision raises; **R73** publishing, so the two bounded in-memory stores can share an eviction discipline; **R75** publishing the layer order and dispositioning the three constraints and the F317 outermost-layer observation above; **R77** publishing and fixing the `RSLBP_WEB_RATE_LIMIT_*` plumbing against the three members named here; **R79** publishing a saturation counter, without which this design's fail-open condition is unobservable; **R80** publishing and fixing whether probe reachability is a placement property or needs a configuration knob after all; `axum` publishing 0.9, which moves the `serve` call this design constrains; `draft-ietf-httpapi-ratelimit-headers` becoming an RFC, at which point R11.3's SHOULD stops resting on an unpublished draft; at the next `msrv-policy` floor advance past 1.96, which changes the headroom figures for `axum-governor` (1.95) and `tower-rate-limiter` (1.96.0); or P03 measuring the limiter on the real router and finding the single mutex or the 65,536-cell capacity wrong

## Parameters

This item owns no parameter: the prompt's `- owns:` line carries none, and `research/CLAUDE.md:79` records R74's `owns` column as `—`. Consumed:

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

**No `CONFLICT:` line is raised.** Nothing in this recommendation needs a consumed value
changed.

**Why there is no `- assumes web-extra-surface` line, and what this decision assumes
instead.** The prompt's `- consumes:` line is empty, so the parameter set is the four fixed
rows and nothing else. That is also the safer answer, because the parameter currently has
two different values: `docs/port/PARAMETERS.md:17` still carries R69 **revision 9**'s
`src/web/`, `dep:axum`/`dep:tokio` text, while R69 revision 10 — accepted but unpublished —
carries a different value at `:1791` naming `crates/web` and `dep:rs-launch-blueprint-web`,
and the two hash differently. The Opus report quotes the registry (revision 9) value on its
`- assumes` line while writing its file paths against revision 10; that inconsistency is
recorded under `## Engines`. **This decision assumes R69 revision 10's shape in prose**: an
additive, off-by-default Cargo feature named `web`, `axum` 0.8.9 and `tokio` 1.53.1 declared
inside `crates/web`, `tower` 0.5.3 as `crates/web`'s dev-dependency only for the
`ServiceExt::oneshot` idiom, and every later web layer — this one included — as a module
inside that gated tree. The `re-verify:` line fires when those bytes move.

The remaining parameters bear on this decision as follows. `msrv-policy` sets the floor at
**1.96** (current stable 1.98.1, checks `F1a`, `F1b`) and is the rule that excludes
`tower_governor` and `governor` and that reduces `axum-governor` and `tower-rate-limiter` to
one and zero minors of headroom. `rust-edition` `2024` is what the probe compiled under.
`target-os-matrix` is satisfied by `std` alone; the probe ran on macOS 26.4 arm64 and the
feature uses no platform-specific API. `license` is inapplicable to candidate selection under
the owner's 2026-09-12 ruling and applies only to this repository's own source.

## Empirical check

Toolchain: `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`, `cargo 1.98.0 (797e8a9bc
2026-08-05) (Homebrew)`, macOS 26.4, `Darwin arm64`; `grep (BSD grep, GNU compatible)
2.6.0-FreeBSD` at `/usr/bin/grep`; `shellcheck 0.11.0`; `jq-1.8.1`. Working directory for
every script: `research/runs/R74/2026-09-18T215916Z-14066395aaea/review/evidence/`. All four
scripts are `shellcheck`-clean and exit non-zero on any failure.

| Script | Checks | Result | Log |
|---|---|---|---|
| `r74-probe.sh` | 54 | 54 PASS, 0 FAIL, 0 SKIP | `review/evidence/r74-probe.log` |
| `r74-registry-figures.sh` | 88 | 88 PASS, 0 FAIL, 0 SKIP | `review/evidence/r74-registry-figures.log` |
| `r74-rest-conformance.sh` | 40 | 40 PASS, 0 FAIL, 0 SKIP | `review/evidence/r74-rest-conformance.log` |
| `r74-decision-shape.sh` | see its own summary line | run last, against this file as committed | `review/evidence/r74-decision-shape.log` |
| `r74-fetch-snapshots.sh` | — | the network fetcher; **no assertions, and its log is deliberately not reproducible** | `review/evidence/r74-fetch-snapshots.log` |

**Nothing being recommended was built.** `r74-probe.sh` writes four throwaway Cargo crates
into a directory it creates with `mktemp -d` under `$TMPDIR` and deletes on exit; no `.rs`
file, `Cargo.toml`, `Cargo.lock`, `src/` or `target/` exists anywhere under this run
directory, which `r74-decision-shape.sh` asserts. The probe is a verification of what the
raws claim, not a template scaffold.

**`r74-probe.sh` — 54 checks.** Section **D** reads the declared `rust-version` and `edition`
out of six published manifests unpacked under
`~/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/`, with `D-control` asserting the
reader finds `axum` 0.8.9's `1.80` so that `tower_governor`'s and `governor`'s `NONE` are a
real absence and not a broken reader. Section **D2** pins the seven `tower_governor` source
facts the two measured defects rest on, including one that **corrects a widely repeated
claim and the Opus report's own framing**: `src/lib.rs` inserts `retry-after` as well as
`x-ratelimit-after`, so the crate is not missing the standard header — its value is wrong.
Section **A** compiles the recommended design and runs **seven** tests: the shipped default
posture limits (21st request from one IP at 10/s burst 20 is 429 with a `retry-after` of 1–2
and `ratelimit-policy: "default";q=10;w=1`); a router built without the layer admits 1,000
requests; the same `install_rate_limit` call site yields 50×200 with `None` and 200-then-429
with `Some`; a `2/minute` quota refuses the third request with `retry-after` **exactly 30**
and leaves exactly one cell in the store; a second key is admitted after the first is
exhausted and ten further keys against a capacity of 3 leave at most 3 cells; the grammar
parses `100/minute` to rate 100 / burst 100 / 60 s, raises the burst to 250 independently
and rejects `100`, `0/minute` and `100/fortnight`; and the ceiling maps 1 ms → 1, 0 → 1,
1500 ms → 2 and 29.99 s → 30. `cargo clippy --all-targets -- -D warnings` produces no
diagnostic. Section **B** runs the two `tower_governor` observations: without `ConnectInfo`
the default key extractor returns **500**, and with it the third request is **429** carrying
`retry-after: 29` and `x-ratelimit-after: 29` for a true wait of 29.99…s, with **no**
`content-type`. Section **C** measures the dependency-set deltas. Section **E** establishes
what `tower-rate-limiter` 0.1.6 is.

**The counting rule for section C, because it decides the figures and because the first
attempt got it wrong.** `cargo tree -e normal` prints one line per *edge* and repeats a
shared subtree as `name vX.Y (*)`, so its raw line count is not a package count: a first run
of this script reported the baseline as 114 and the `tower_governor` delta as +73. The
figure used is the set of **distinct name-and-version entries** in the non-dev tree with the
probe's own root package removed — the rule the Opus report used. Under it the baseline is
**50**, the recommended design is **50** with a `diff` of the two sets empty (`C5`), adding
`tracing` with `default-features = false, features = ["std"]` is still **50** (`C2`),
`tower_governor` with `default-features = false, features = ["axum"]` is **87** (**+37**,
`C3`) and with its default features **99** (**+49**, `C4`). `C5-control` asserts that the
`tower_governor` set is *not* identical to the baseline, so `C5`'s empty diff cannot be
vacuous. `C1`, `C3` and `C4` therefore reproduce the Opus report's three figures exactly.

**`r74-registry-figures.sh` — 88 checks, and it touches no network.** Every crates.io,
GitHub and RustSec payload this decision cites was fetched once by `r74-fetch-snapshots.sh`
into `review/evidence/snapshots/`, and every assertion reads the snapshot.
`snapshots/MANIFEST.tsv` records each payload's endpoint and its UTC retrieval time; the
retrieval window is **2026-09-19T01:07:52Z – 2026-09-19T01:13:30Z**, i.e. 2026-09-18 local,
and the 37 rows are asserted (`S0a`, `S0b`). GitHub requests were made through
keyring-authenticated `gh api`, one per 20 seconds, enforced by a `sleep 20` before each
call; crates.io requests were one per second under the User-Agent
`rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)`. Every
`?`-bearing argument is quoted. The script asserts the floor derivation (`F1a`, `F1b`), nine
crates' 90-day and all-time downloads, newest non-yanked `num` and `created_at`,
`rust_version` and `license` (`F2-*`), six reverse-dependency totals (`F3`), six RustSec
404s against a **200** control on `dashmap` so the 404s cannot be a blanket network failure
(`F4`, `F4-control`), the maintenance figures (`F5a`–`F5m`), and the gate-2 reads **at
`master`** (`F6`) with `tower-rate-limiter`'s declared `1.96.0` at `master` as the control
that the decoder can find a version when one is present (`F6-control`). `F2-control` is the
same discipline for the registry read. `F5d`/`F5e` record both the `search/issues`
`total_count` of **19** that the prompt requires and the `open_issues_count` of **24** that it
forbids, so the difference is visible rather than asserted.

**`r74-rest-conformance.sh` — 40 checks.** It asserts that each of the twenty-one rule texts
this decision quotes appears **on the line the decision cites**, in a snapshot of the pinned
blob; that the snapshot is byte-identical to `git -C /Users/stevemorin/c/rest-standards
cat-file blob 71bd813c1cf61286586b4ee41ed83ff065e5c8d9`; that the commit's
`rest-api-standard.md` *is* that blob (`P0a`–`P0d`); that §11.2's block carries no
applicability-switch scoping and the §1.8 vocabulary has no rate-limiting member (`S3a`,
`S3b`); and that the standard's own 429 example carries `Retry-After: 30` and
`rate_limit_exceeded` (`E9a`–`E9c`). `P0-control` asserts that line 1 does **not** carry
R11.2's text, so the positional locator can fail. Eight of these line numbers were wrong on
the first run and were corrected against the snapshot rather than the assertions being
loosened.

**Reproducibility, stated per log rather than generically.** `r74-registry-figures.log` and
`r74-rest-conformance.log` were re-run and `diff`ed against the committed copies **after**
they were written: both are **byte-identical**, because both read committed snapshots and
touch no network. `r74-probe.log` is **not** byte-for-byte reproducible and the rule for
comparing across it is this: the 54 `PASS`/`FAIL`/`SKIP` lines, the `CHECKS RUN:` summary,
the `baseline=… design=… tracing=… tg_nodefault=… tg_default=…` line and the four toolchain
lines are byte-identical across reruns — verified by re-running and `diff`ing that subset —
while the `workdir:` line carries a fresh `mktemp` suffix and cargo's `Compiling …`,
`Finished …` and `finished in N.Ns` lines vary. `r74-fetch-snapshots.log` is **not**
reproducible by construction: re-running it re-fetches live counters and overwrites the
snapshots, which is how an auditor sees drift.

**Drift already observed, and the rule for reading it.** The Opus report's figures were
collected earlier the same day and several have moved: `governor` 90-day downloads
15,807,822 → **15,833,152**; `tower_governor` 1,719,980 → **1,711,259**; `axum_gcra` 66 →
**60**; `tower-resilience-ratelimiter` 6,320 → **6,279**. Every figure in this decision is
the snapshotted one. Download counters move daily and no conclusion here turns on a
difference of that size; the figures that decide anything — `rust_version`, reverse-dependency
totals, `archived`, `pushed_at` and release dates — did not move.

**`validate_answer_text(text, "bundle")` from `scripts/research_validation.py`**, run against
this file, returns **exactly one** diagnostic: `answer: H3 fields must be exactly in order:
Landscape | Principles and implementation | Recommendation | Members | …`. That validator
checks the **raw answer template**, not the `DECISION.md` shape the role contract mandates,
and the same single diagnostic is returned by the two accepted decisions
`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md` (revision 2) and
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` (revision 10), while
this run's `raw/opus.md` returns **zero**. `r74-decision-shape.sh` asserts all four of those
results, so the count is pinned and a stray `#####` heading or a missing H2 would change it.
Because this file has no `### Members` section, the validator's member-window rule
(`no ##### outside it`) is not reached, and this file contains no `#####` heading at all.
`bash scripts/check-research-tree.sh .` was run before committing.

**What could not be verified, and is carried rather than re-derived.** The Opus report's
throughput table (1,000,000 admit-path checks across {1,8} threads × {1, 10,000} keys,
14.7M–6.2M ops/s for the recommended store against 27.1M–7.8M for `governor`'s `DashMap`)
was **not** re-run: nothing in this decision turns on it beyond the claim that the worst
measured figure, 160.7 ns per check, is under 0.02% of a 1 ms request, and that claim
survives any plausible re-measurement. It is **carried**. Also carried, and labelled as such:
`governor`'s issue-responsiveness median of 1 day across the three of seven recent issues a
maintainer answered, and `tower_governor`'s zero maintainer responses across its ten most
recently opened issues — the `pushed_at` of 2025-08-14 and the 19 open issues are asserted
(`F5c`, `F5d`) but the per-issue comment walk was not repeated. Genuinely **unproven**:
slowapi's own `Retry-After` rounding, because slowapi is a dependency of the pinned
repository rather than a file in it, so whether py truncates or rounds is unknown and the
ceiling is this template's argued choice rather than a match to py; and issue-responsiveness
medians for `gcra`, `ratelimit`, `axum-governor`, `tower-resilience` and
`tower-rate-limiter`, whose issue populations are 0–3 and too small for a median, with the
raw counts reported instead. One endpoint failed and is recorded rather than omitted:
`search/issues?q=repo:nivek-ph/tower-rate-limiter+is:issue+is:open` returns HTTP **422**,
because the account was renamed; the repository endpoint resolves through the redirect and
reports `full_name: nivek3/tower-rate-limiter` (`F5m`).

## Engines

- opus `raw/opus.md` (Claude Opus 5, sha256 `43fe88523480cefe87a022eb36a012e09fd2177c644672c25c0868bffcf60dc7`)
- doxa `raw/doxa.md` — the three-provider report, operation `research-20260918-151845-96abb3c658eb437e`, with twins `raw/doxa.normalized.md`, `raw/doxa-openai.normalized.md` (`gpt-5.6-sol`), `raw/doxa-perplexity.normalized.md` (`sonar-deep-research`) and `raw/doxa-gemini.normalized.md` (`deep-research-preview-04-2026`). Per `doxa/normalization.json` the openai and gemini twins needed **no** changes; the perplexity twin needed **22 lossless heading repairs**, every one a letter-case fix (`### Principles and Implementation` → `### Principles and implementation` and the like), with `content_lines_missing_from_regrouped: 0` on all three
- codex — **absent.** The controller deferred the Codex leg under owner ruling **W1-CODEX3** (2026-09-18). A Deep-tier item's engine set is `codex, opus, doxa`; this item ran two of the three, and the disagreements below were settled on evidence executed by this synthesis rather than by a third opinion

**What P03 must validate, because this decision is a proposal and not an implementation.**
(1) That the 429 body is R70's problem document — blocked on R70 publishing; the probe
asserts status and headers against a placeholder body. (2) That the serve path installs
`ConnectInfo` — needs a real `TcpListener`, and is the **first** thing to check, because
without it the shipped default meters every caller through one bucket. (3) That the
limiter's placement in R75's final order satisfies the three constraints above and leaves
`/healthz`, `/readyz` and `/metrics` reachable under throttling. (4) A property test over
random `(rate, burst, period, arrival sequence)` asserting that admissions in any window
never exceed `burst` and that a client obeying `Retry-After` is never refused twice
consecutively. (5) A clock-injection refactor so eviction is tested against a fake clock
rather than wall time. (6) A concurrency-stress or `loom` test for the store. (7) Whether a
poisoned `Mutex` should fail open with a warning rather than panic — the probe uses
`.expect("poisoned")` and this decision deliberately leaves the question open. (8) Whether
65,536 cells and a single mutex hold on the real router.

**Disagreement 1 — the recommendation itself. Four legs, four answers; settled against
three of them on executed evidence.** Opus recommends a template-owned zero-crate GCRA
design. perplexity recommends `tower_governor` + `governor`. gemini recommends
`axum-governor` + `governor`. openai recommends `tower-rate-limiter` 0.1.6. **Opus is
right, and the other three fail on facts this synthesis executed rather than on judgement.**
`tower_governor` and `governor` declare no `rust-version` at the release *or* at `master`
(`F2-rv`, `F6`), which fails gate 2 under the reading the owner settled. `axum-governor`
declares `1.95`, one minor of headroom where R69 excluded `salvo` at two, and has **zero**
reverse dependencies against 25 stars (`F3`, `F5i`). `tower-rate-limiter` is real — it exists
at 0.1.6, is `MIT OR Apache-2.0`, edition 2024, `rust-version = "1.96.0"`, and has exactly
the architecture the openai leg describes — but it has **294 all-time downloads**, **zero**
reverse dependencies and **7** stars, its crate was first published **2026-08-06** and its
repository created **2026-08-02**, and it adds **18** crates including `moka` (`F2-dlall`,
`F3`, `F5k`, `F5l`, `E5`, `E6`). Under the prompt's practice-evidence requirement it has
none, which the openai leg states honestly itself: *"No well-regarded production adopter was
verified."*

**Disagreement 2 — the algorithm, where the openai leg corrects Opus and the standard
settles it.** Opus rejects a fixed window because its reported wait "over-states the wait for
every request except the last". That reasoning is **wrong**: in a fixed window a refused
caller genuinely cannot succeed until the window rolls, so the window end is the exact next
admission. The openai leg names the real defect — *"fixed-window boundary bursts"* — and the
binding standard decides it: R8.10's axis default is *"per-principal sustained +
token-bucket burst"*, two independent parameters that a fixed window cannot express. GCRA
can, and the probe now carries `rate` and `burst` as separate fields with the arithmetic
asserted (`A policy_grammar_matches_py_limits_notation` checks that raising the burst to 250
leaves the sustained rate at 100 and gives a 600 ms emission interval). `tower-rate-limiter`
0.1.6's own source says *"An asynchronous fixed-window rate-limit store"* (`E3`), so the
openai leg's pick fails the criterion the openai leg itself identified.

**Disagreement 3 — whether any candidate fails the MSRV gate.** gemini states *"None of the
shortlisted candidates failed the mandatory fitness gates concerning MSRV, licensing, or
operating system support."* That is **false and was executed**: `governor` and
`tower_governor` declare no `rust-version` at the release and at `master`, and `axum_gcra`
declares none at all (`F2-rv`, `F6`). gemini reports no crates.io or GitHub figure anywhere
in its report, so its gate table rests on nothing. gemini also cites **RFC 7807**, which the
binding standard's R5.14 (line 1098) forbids: *"RFC 7807 MUST NOT be cited — it is obsoleted
by RFC 9457."*

**Disagreement 4 — `tower_governor`'s `Retry-After`.** perplexity says the crate *"does not
explicitly document `Retry-After` computation"* and proposes a wrapper to add it; a widely
repeated claim holds that the crate emits only `x-ratelimit-after`. Both are **wrong in the
same direction**: `src/lib.rs` inserts `retry-after` at two sites (`D2b`). The real defect is
the value: `NotUntil::wait_time_from(now).as_secs()` truncates (`D2a`), and the compiled
probe observed `retry-after: 29` where the true wait is 29.99…s. Because R12.2 (line 1784)
makes honouring the header a client MUST, a value below the true wait guarantees a second
refusal. gemini's claim that `axum-governor` *"mathematically generates exact `Retry-After`
headers"* was not tested here — `axum-governor` delegates to the same `governor` arithmetic,
and it is excluded on other grounds — so it is left **unproven**.

**Disagreement 5 — the `ConnectInfo` 500.** Only Opus found it. Confirmed twice: in the
source, `PeerIpKeyExtractor::extract` is
`maybe_connect_info(req).ok_or(GovernorError::UnableToExtractKey)` and that error renders
`StatusCode::INTERNAL_SERVER_ERROR` (`D2d`, `D2e`); and in a compiled probe, which returns
500 without `ConnectInfo` and 429 with it. **New, and neither leg found it:** the owner's own
reference architecture has the same gap — it shows `axum::serve(listener, app)` at line 333
and contains **zero** occurrences of `ConnectInfo` or `into_make_service`, so its C11 pick
would 500 on every request as the document writes it.

**Disagreement 6 — the crate-count deltas.** Only Opus produced them. Reproduced exactly at
**+0**, **+37** and **+49** (`C1`, `C3`, `C4`) once the counting rule is fixed as distinct
name-and-version entries; the first attempt, counting raw `cargo tree` lines, produced +0,
+73 and +137 and is recorded above so the rule is visible rather than implied.

**Corrections this synthesis makes to the Opus report, beyond the disagreements.** (a) Its
`- assumes web-extra-surface` line quotes `docs/port/PARAMETERS.md`'s **revision-9** value
while its file paths are written against R69 revision 10's `crates/web` layout; this decision
carries no such line, because the prompt consumes no parameter, and states the two values'
divergence in `## Parameters`. (b) Its owner-reference row for line 114 says rate limiting is
"placed within the tower-http order". It is not: line 114's chain is ten named
`tower-http` layers and rate limiting appears in the *following sentence* with no position
given, so the document is **silent** on placement rather than prescriptive. (c) Its tally of
the eight touched rows as "3 differ / 3 agree / 2 hand-offs" is a defensible split only if
C4 is counted as a hand-off; re-checking each row gives **3 differ** (C11 line 70, the shared
core list line 31, the manifest line 185), **4 agree** (the reuse-one-limiter gotcha line
415, the C4 error contract line 54, the C12 test idiom line 72, `tower = "0.5"` line 140) and
**1 pure hand-off** (the layer-order note line 114), with C4 double-classified as
agree-and-hand-off. (d) Its hand-off of two counter names to R79 is stale: R79 revision 1
ships *"Two instruments, not three"* and describes this item as *"opt-in rate limiting"*, a
characterization this decision makes obsolete. (e) Its rejection of fixed window is wrong for
the reason given in Disagreement 2, though its conclusion stands. (f) It reports slowapi's
rounding as unverified, which this synthesis confirms and carries unchanged.

**Where the legs agree, which is worth recording.** All four legs independently reach the
same four structural conclusions: rate limiting must be a runtime decision rather than a
Cargo feature, because a compile-time gate would require two binaries; the store must sit
behind a swap seam rather than a comment; the 429 must render through the item's single
error envelope rather than a second ad-hoc body; and `tower::limit::RateLimitLayer` is the
wrong shape because it delays rather than refuses. Nothing in this decision departs from any
of those.

**Sources.** Standards: the org REST API Design Standard v2.0.0 at the pin above, cited by
rule and line throughout and asserted by `r74-rest-conformance.sh`; RFC 9110 §10.2.3
(`https://www.rfc-editor.org/rfc/rfc9110.txt`, 2026-09-18) for
`Retry-After = HTTP-date / delay-seconds`, `delay-seconds = 1*DIGIT`, *"a non-negative
decimal integer"*; RFC 6585 §4 (`https://www.rfc-editor.org/rfc/rfc6585.txt`, 2026-09-18) for
429, whose `Retry-After` MAY the org standard deliberately tightens to a MUST;
`draft-ietf-httpapi-ratelimit-headers-11`, 23 May 2026
(`https://www.ietf.org/archive/id/draft-ietf-httpapi-ratelimit-headers-11.txt`, 2026-09-18) —
an unpublished Internet-Draft, cited by its pinned revision and never described as a
standard. Registry, repository and advisory figures: the crates.io crate, versions and
reverse-dependencies endpoints, the GitHub REST repos, search/issues and contents endpoints,
`https://rustsec.org/packages/<name>.html`, and
`https://static.rust-lang.org/dist/channel-rust-stable.toml`, all retrieved
2026-09-19T01:07–01:13Z (2026-09-18 local) and snapshotted under
`review/evidence/snapshots/` with `MANIFEST.tsv` naming each endpoint. Crate source, read
not recalled, from `~/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/`:
`tower_governor-0.8.0/{Cargo.toml,src/lib.rs,src/errors.rs,src/key_extractor.rs}`,
`governor-0.10.4/Cargo.toml`, `gcra-0.6.0/Cargo.toml`, `axum-governor-2.1.0/Cargo.toml`,
`axum-0.8.9/Cargo.toml`, `tower-0.5.3/Cargo.toml` and
`tower-rate-limiter-0.1.6/{Cargo.toml,src/limiter/store.rs,src/limiter/response.rs}`, all
read 2026-09-18. Source repository at the pin:
`git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/web/app.py` lines
128–150, read directly this session; ts contributes nothing
(`docs/port/areas/web-service.md:7`). Programme documents: `docs/port/COMMONALITY.md` rows
F316 (line 320), F317 (321) and F323 (327); `docs/port/areas/web-service.md` rows F316 (22),
F317 (23), F323 (29); `docs/port/BASELINE-REVIEW.md`, which carries **no** row in the
F313–F328 band, because it adjudicates `COMMON → REUSE` and `ADOPT` rows and these three are
`DIVERGENT`; `docs/port/README.md` lines 61–73 for the verdict vocabulary;
`docs/port/OWNER-REVIEW.md` line 187 for W2-REST; `docs/planning/p02/owner-decisions.md` §11
(lines 401–432, the standing-input ruling naming R72–R76 in its overlap set) and lines
450–462 (the settled strict gate-2 reading);
`inputs/owner-reference-axum-companion-stack-2026-09-16.md` lines 31, 54, 70, 72, 114, 140,
185, 333, 415, 431; `docs/port/PARAMETERS.md` line 17;
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` lines 1067, 1106,
1492, 1494–1497, 1605, 1616, 1787, 1791, 2262–2276, 2408;
`research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md` (revision 2, sha256
`46b2a05f40f6a3ea27b5fdef415c50adccd27ade5ed6fa94f83ed933503d7f68`) lines 25, 194, 640–659,
763–781, 854;
`research/runs/R70/2026-09-17T034010Z-31ad2ef28df7/review/DECISION.md` lines 52, 57, 158–159,
266–267; `research/runs/R79/2026-09-17T034011Z-2e1043da0e00/review/DECISION.md` lines 36,
220–222, 322; `research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md` lines
524–531, 544–545; `research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/raw/opus.md` lines 647,
1218–1224; `research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md` lines
23–31; `research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md` lines 7, 31;
`research/topics/67-error-and-exit-code-contract/DECISION.md` line 383;
`research/topics/01-ports-and-adapters-seam/DECISION.md` line 138; `research/CLAUDE.md`
line 79.
