# 2026-09-27 — R74 — rate-limiting-middleware (bundle, Deep) — decision (revision 2)

Revision 1: 2026-09-18, sha256 `84c01ec019f9ba68b731b56ad846dece449ddecdf8fb6d548530f2dc1b4b3056`,
preserved byte for byte at `review/R74-r1-snapshot.md`. Revision 2: resynthesis worker on the
Opus seat, model `claude-opus-5-5`, CLI run 2026-09-27 (UTC). Item kind `bundle`, effort tier
`deep`, three engines: Muse, Opus and Doxa. No synthesizer produced any raw report. Nothing
has been published for R74, so there is no `## Supersedes`.

**Revision note (revision 2).** Both round-1 audits rejected revision 1: the judgment audit
(`review/audit-fable.md`, six findings, one blocking) and the empirical audit
(`review/audit-claude.md`, EA-1 to EA-5). **The recommendation does not move.** The one
blocking finding was that `## Engines` never represented the Muse leg. Muse is now represented
from its on-disk raw and adjudicated below; the runner has not yet registered it as collected. Muse disagrees with this decision's load-bearing
move, the shipped default, and on two design details. Each disagreement is settled against it
on the binding standard and on executed evidence (Disagreements 7 to 9). Every other finding is
mechanical, and each one's repair is listed here with where it lands.

| Finding | What was wrong | What revision 2 does |
|---|---|---|
| fable 1, JF-3/JF-9 (blocking) | `## Engines` named Codex as the absent leg; the required set is now `muse, opus, doxa`, and `raw/muse.md` was neither listed nor adjudicated | `## Engines` lists Muse in place of Codex, with the authority chain for the substitution, the raw's sha256 and its unregistered operation state. Disagreements 7 to 9 adjudicate Muse's off-by-default B1/B2 and its missing `BASELINE-REVIEW:`, its single-parameter GCRA and its one-variable settings shape; Disagreement 2 extends the fixed-window correction to Muse; the source readings in which Muse adds to revision 1 are verified (probe section F, registry checks `F3-adopter`) |
| fable 2, JF-4 | Section numbers used as rule IDs: `R1.8` for §1.8's rule, a nonexistent `R1.10`, R1.6 missing from `re-verify:` | The conformance table now reads `R1.6` (lines 229, 231, 237) and `R1.8` (line 312, with 352, 353, 362), and adds an `R1.7` row. R1.6 joins the `re-verify:` rule list. `r74-rest-conformance.sh` labels are renamed, the section headings and rule IDs are themselves asserted, and its log is regenerated (48 checks) |
| fable 3, JF-4 | R1.7's "regardless of the deviation's merits" was quoted as if it applied to every deviation | The opening paragraph and the `BASELINE-REVIEW:` evidence now state R1.7 in full: a deviation from a MUST is conformant only as a recorded, approved exception, and the "regardless of merits" clause is scoped to *silent* deviation. The decision chooses to conform rather than ask for an exception. Checks `R1.7b` to `R1.7e` assert lines 273–276 |
| fable 4 and claude EA-1, JF-8 | `r74-decision-shape.log` did not exist; the script failed 4 of 54 on brittle matchers | The four matchers are repaired (S1g one-line phrase, S2g anchored on the filing line, S4d excludes the negated form, S4f anchored on the migration-table row). The raw-answer validator section is removed, because that validator checks raw answers, not decisions; a comparison with a published topic decision's shape replaces it. The script was run last against this file and its log is recorded |
| fable 5, JF-4/JF-5 | R77, R79, R70 and R73 citations had drifted | Re-pinned to the current working copies by revision, sha256 and line: R77 revision 4, R79 revision 3, R70 revision 4, R73 revision 2, and R80 revision 3. The R70 coupling is rewritten as resolved by R70 revision 4. The R73 placement is worded as a constraint handed to R75 and agreed with R73, citing R73's decision. `r74-citations.sh` asserts every one of those lines and hashes |
| fable 6, JF-1 | "Always registered" was not reconciled with an `install_rate_limit` that took `Option` | The shipped signature is stated: `install_rate_limit(router, policy: RateLimitPolicy, store: Arc<dyn RateLimitStore>) -> Router`, with no `Option`. The `Option` form survives only as `install_rate_limit_conditional`, evidence for HIGH question 2 and for the F323 and OV-17 reversal options. B2 now points at a test of the shipped form, and the never-`None` settings invariant is handed to R77 |
| claude EA-2 | The probe needed a warm Cargo cache and read `$HOME/.cargo` whatever `CARGO_HOME` said | `r74-probe-r2.sh` derives the registry from `${CARGO_HOME:-$HOME/.cargo}` and fetches every probe crate in an explicit online section L before any `--offline` call |
| claude EA-3 | C-section counts were not pinned by a lockfile | Eight lockfiles are committed under `review/evidence/probe-locks/`, and every cargo call replays them with `--locked`. Their sha256 values are printed in the log |
| claude EA-4 | Toolchain drift broke the stated byte-identity subset | The probe ran on current stable (1.98.1), and `T1` asserts only that the toolchain is at or above the 1.96 floor. The comparison rule now excludes the toolchain lines, and was verified by a second replay |
| claude EA-5 | A fresh fetch failed 23 of 88 figures, including a new `axum-governor` release and two reverse-dependency totals | The snapshots were re-fetched into `snapshots-r2/` (2026-09-27T06:26–06:30Z). Every figure is re-recorded and asserted by `r74-registry-figures-r2.sh` (130 checks), whose section 7 records field by field what moved and what did not. `axum-governor` 2.1.2 (2026-09-26, `rust-version` 1.95) is the row's version now. "Did not move" is replaced by a dated statement |

**Inputs, re-frozen for revision 2.** The live topic prompt
`research/topics/74-rate-limiting-middleware/prompts/rate-limiting-middleware.prompt.md` is
byte-identical to this run's `inputs/prompt.md` (`diff` empty, 2026-09-27). Both carry
`- engines: muse, opus, doxa` (line 25) and the sentence *"This item substitutes Muse (Meta)
for Codex under the `engine_overrides` pilot; its mirrored `- engines:` line is
authoritative"* (line 71). `research/EXECUTION.json` lists R74's engines as `muse, opus,
doxa` in both its override table and its item row. The authority for the substitution is
recorded under `## Engines`.

**The shipped default moves from off to on, and this is the one thing to read first.**
The prompt asks whether the template adopts a rate limiter "off by default and enabled by
one env var", which is what py does (F323). On 2026-09-18 — after this item's prompt was
written — the owner ruled that the organisation's REST API Design Standard v2.0.0 binds this
template's HTTP surface (`docs/port/OWNER-REVIEW.md:187`, "2026-09-18 — the REST API Design
Standard binds the HTTP surface (W2-REST)"). That standard's **R11.2 is a MUST**: *"An API
MUST apply rate limits and communicate exhaustion via the published HTTP mechanism: `429
Too Many Requests` with `Retry-After`. This MUST is a deliberate tightening of RFC 6585 §4's
MAY — house policy over a published standard"* (pinned blob, lines 1686–1688; check `R11.2`).
R11.2 is scoped by no applicability switch under R1.6 (§1.8), and R1.6's switch vocabulary
has no rate-limiting member (checks `S3a`, `S3b`), so it binds unconditionally. Shipping
limiting off would therefore deviate from a MUST. Under R1.7 (§1.9, lines 271–276) such a
deviation is conformant only if it is *"recorded as an approved exception in the conformance
note"*; the clause *"regardless of the deviation's merits"* applies to *silent* deviation.
**This decision chooses to conform rather than ask for that exception**, and files
`BASELINE-REVIEW: F323` so the ledger row that records py's off-by-default gate is not
silently overridden. The conditional-registration mechanism the prompt's HIGH question 2
asks about is still answered and still compiled — as evidence, not as the shipped form.

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

The layer is **always registered**, and the shipped signature makes that structural rather
than a convention:

```rust
pub fn install_rate_limit(
    router: Router,
    policy: RateLimitPolicy,
    store: Arc<dyn RateLimitStore>,
) -> Router
```

There is no `Option` in it, so no configuration value can reach the router as "off" (check
`A-sig`). The posture is an unauthenticated per-IP sustained rate with a burst, defaulting to
**10 requests/second with a burst of 20**, configured through R77's reserved family
`RSLBP_WEB_RATE_LIMIT_*`, **no member of which can disable limiting**: an unset or
exported-but-empty value means the default posture, and a non-empty invalid value is a
startup error (`A settings_values_tune_but_never_disable`). The refusal is `429` carrying
`Retry-After` (a ceiling in whole seconds, floored at 1, never `0`), `RateLimit` and
`RateLimit-Policy` in the syntax of `draft-ietf-httpapi-ratelimit-headers-11`, and a body
rendered through R70's `application/problem+json` envelope. No proprietary `x-ratelimit-*`
header is emitted.

**Ledger rows this settles.** `F316` (rate-limit store is in-memory, single-instance by
design) — preserved exactly, and strengthened: the swap point becomes a compilable trait
rather than a paragraph. `F323` (rate limiting is wired but off by default, one env var
enables it) — the *wiring* and the *single configuration surface* are preserved; the
*off-by-default default* is not, and that departure is filed below as a
`BASELINE-REVIEW:` finding. `F317` (middleware ordering) is **R75's**; this item hands it
ordering constraints and does not decide the order.

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
with `tonic` off and **49** with its defaults (checks `C3`, `C4`, pinned by the committed
lockfiles).

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
the pin, `git -C ~/c/py-launch-blueprint show b08bccfb:<path>`. ts has no web service
(`docs/port/areas/web-service.md:7`), so there is no second precedent.

The **agreement level is a capability plus a policy**, not a library: *the service refuses
excess traffic per caller; the refusal is a standards-conformant 429 whose `Retry-After` is
derived from limiter state; the state is single-instance by design with a named swap point;
and the quota is configurable through one settings surface.* Nothing about `slowapi`,
`limits`, GCRA or token buckets is part of the agreement. What may vary: the algorithm, the
map type, the header set, and whether the check is a `tower` `Layer` or a function. **What
the binding standard removes from "may vary" is the default**: py's `None`-means-off is not
portable into a conformant template, which is the conclusion R77 revision 4 also records for
the settings surface (`research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md:948-949`).

**Essential behaviours and observable acceptance criteria.** Every "executed" test below runs
against the shipped `install_rate_limit`, except the two marked as evidence or control.

| # | Behaviour | Observable criterion | Status |
|---|---|---|---|
| B1 | Limits apply as shipped | With no `RSLBP_WEB_RATE_LIMIT_*` variable set, a caller exceeding the default posture is refused | executed (`A the_shipped_default_posture_is_on_and_limits`) |
| B2 | One settings surface tunes it | Setting members of the reserved family, with no recompilation, changes the quota; no value turns it off | executed on the shipped form (`A settings_values_tune_but_never_disable`); the env plumbing is R77's |
| B3 | Correct admission | With sustained `N/period` and burst `B`, the first `B` requests from one key are admitted and the `B+1`-th is refused; after the burst, admissions follow the sustained rate | executed (`A third_request_…`, `A the_shipped_default_posture_…`, `A rate_and_burst_are_independent_over_simulated_time`) |
| B4 | Per-key isolation | A second key is unaffected by the first key's exhaustion | executed (`A keys_are_isolated_…`) |
| B5 | Standards-conformant refusal | Status is 429; `Retry-After` is a non-negative decimal integer (RFC 9110 §10.2.3) and is present on every 429 (R11.5) | executed (`A third_request_…`) |
| B6 | Accurate `Retry-After` | Derived from limiter state, never a constant, and never **earlier** than the true next admission | executed (`A retry_after_is_never_zero` asserts the ceiling: 29.99 s → 30) |
| B7 | In-memory, bounded, single-instance | State lives in this process, cannot grow without bound, and the swap point is a named type | executed (`A keys_are_isolated_and_the_store_is_bounded`) |
| B8 | One envelope | The refusal renders through the service's single error representation (R70's), not a second ad-hoc body | **proposed** — blocked on R70 publishing; the probe asserts status and headers against a placeholder body |
| B9 | Quota state advertised | `RateLimit` and `RateLimit-Policy` in draft-11 syntax accompany the 429 (R11.3, a SHOULD) | executed (`A third_request_…`, `A the_shipped_default_posture_…`) |

The two tests that do not exercise the shipped form are labelled as such in the probe:
`A off_by_default_is_the_absence_of_the_layer` is a control (a router built without the
layer admits 1,000 requests, so the refusals above are the layer's doing), and
`A conditional_registration_is_the_gate` is the evidence for HIGH question 2.

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
rather than removing the layer. Disabling is deliberately not expressible: that goes one
step beyond R77 revision 4's constraint that *"No member's default may disable rate
limiting"* (`:948`), and it is this item's choice, made in the shipped signature above.

**Does the shared pattern remain appropriate in Rust?** Yes, with two substitutions. py's
gate is a truthy settings value read at app-construction time; Rust's equivalent is
`Option<T>` and conditional registration, and `axum::Router::layer` consumes and returns
`Router`, so `match policy { None => router, Some(p) => router.layer(…) }` compiles with no
`Either`, no `option_layer` and no boxing — compiled and asserted as
`install_rate_limit_conditional` (`A conditional_registration_is_the_gate`). That is the
answer to the prompt's HIGH question 2. It is recorded in full, and kept compiled, because
the reversal options of `BASELINE-REVIEW: F323` and `OVERRIDE (OV-17)` would restore it; it
is **not** the shipped form. The second substitution is the default itself, argued above. A
Cargo feature is **rejected on principle** in either case: a feature moves the gate to
compile time, so the shipped binary would no longer *contain* a limiter that configuration
tunes. R69's `web` feature already gates whether the whole web tree exists; a second
compile-time gate inside it buys nothing.

**Why GCRA with two parameters, and why not a fixed window.** The standard settles this
better than adoption figures do. R8.10's rate-limit axis default names *"per-principal
sustained + token-bucket burst"* (line 1397): sustained rate and burst are **two independent
parameters**. GCRA carries both exactly — emission interval `T = period / rate`, tolerance
`tau = (burst - 1) * T`, one `Instant` of state per key, two comparisons per request — and
on refusal it yields the exact next-admission instant that `Retry-After` is the ceiling of.
The two-parameter form is measured, not only argued: with one request per millisecond for
ten seconds and the clock injected, the shipped posture admits **120** (a burst of 20, then
10 per second), where a single-parameter GCRA whose interval is `period / burst` admits
**110** at "10/second" and **220** at "20/second"
(`A rate_and_burst_are_independent_over_simulated_time`). A fixed-window counter cannot
express a burst separate from the rate at all, and admits up to `2 × quota` across a window
boundary. **This corrects the Opus and Muse reports**, which reject fixed window on the
ground that its reported wait "over-states the wait for every request except the last":
that is wrong. In a fixed window a refused caller genuinely cannot succeed until the window
rolls, so the window end *is* the exact next admission. The real defect is the boundary
burst, which is what the openai leg named and what R8.10's wording rules out. Token bucket
is behaviourally equivalent to GCRA and is rejected narrowly: two fields of state and a
refill computation per check, where GCRA needs one `Copy` value — which is what makes the
store a plain `HashMap` rather than a structure. Sliding-window log is exact but
`O(quota)` memory per key, which fails B7.

**Where the store lives.** R05, accepted at revision 3, fixes a synchronous core and confines
async to the `web` feature (`docs/port/OWNER-ACCEPTANCES.md:75`), and says nothing about
where web-layer state lives. `RateLimitStore` and `InMemoryRateLimitStore` are **declared**
in `crates/web/src/rate_limit.rs`, because the key is a transport identity (the peer
address) that `crates/core` never sees. The store is **constructed** at the root package's
composition root, erased to `Arc<dyn RateLimitStore>` and handed to `build_router`. That is
R01's registered seam (*"the composition root … erases the production adapter to
`Arc<dyn ProjectsPort>`"*, `research/topics/01-ports-and-adapters-seam/DECISION.md:138`)
applied to a second substitutable dependency, and it is where R73 revision 2 constructs its
in-memory idempotency adapter (`research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/DECISION.md:30-33`).
R73 declares its *port* in `crates/core` (`:58`); this item does not follow it there, for the
transport-identity reason just given. A settings value is data; a store is a substitutable
dependency, which is what the seam exists for. The check runs inline in the async
middleware and is never handed to `spawn_blocking`: it is 68–161 ns (carried from the Opus
report, see `## Empirical check`) and holds a `Mutex` guard across no `await`.

**Bounding, and the fail-open trade.** The key space is attacker-controlled, so the store
carries a capacity. When the map is full and the key is new it evicts every cell whose
arrival time has already passed; if it is still full the request is **admitted**. That is a
deliberate security trade and is recorded as one: an attacker with many source addresses
can fill the map and disable limiting for new keys, whereas failing closed would let the
same attacker deny service to every new client. A limiter must not become the outage. The
mitigations are a capacity large enough that this costs real resources (default 65,536
cells) and a saturation signal — see the R79 hand-off, which R79 revision 3 still declines
by shape.

**Production usage and maintained reference examples.** `from_fn_with_state` is axum's own
documented middleware adapter. `loco-rs/loco` demonstrates config-gated middleware
registration as a published template pattern and ships **no rate limiter at all**, which is
the answer to the prompt's LOW question: the config-gated-middleware pattern is named and
published; *rate limiting itself* is not a Rust template staple. `loco-rs` is at 1.2.0 with
107,284 90-day downloads on 2026-09-27 (`F2-loco`); its middleware source was not re-read by
this synthesis (see `## Engines`, Muse's `is_enabled` claim). The algorithm is the same GCRA
that `governor` (79,753,999 all-time downloads and 489 reverse dependencies on 2026-09-27,
`F2-dlall`, `F3`) implements; this design differs from it in packaging, not in arithmetic.
**The evidence gap is stated plainly: no maintained reference implementation exists for
this exact composition**, because the crates that would be it are the ones gate 2 excludes.
The mitigation is that the composition is executable and was executed — nine design tests
and 87 checks, listed under `## Empirical check`.

**The crates that could have supplied this, and why none does.** Figures are the
2026-09-27 snapshots (`snapshots-r2/`); section 7 of `r74-registry-figures-r2.sh` records
what moved since 2026-09-19.

| Candidate | Gate 1 (licence) | Gate 2 (MSRV, floor 1.96) | Gate 3 | Disposition |
|---|---|---|---|---|
| `tower_governor` 0.8.0 | inapplicable — owner ruling 2026-09-12 (Q7.B) | **`null` at the release and no `rust-version` at `master` — FAIL** (`F2-rv`, `F6`) | no RustSec page, HTTP 404 (`F4`) | **Excluded by gate 2**; three measured defects corroborate |
| `governor` 0.10.4 | inapplicable — same ruling | **`null` at the release and at `master` — FAIL** | 404 | **Excluded by gate 2** |
| `axum-governor` 2.1.2 (2026-09-26; 2.1.0 was newest on 2026-09-19) | inapplicable — same ruling | `1.95` on 2.1.0, 2.1.1 and 2.1.2 — passes on the letter, **one** minor of headroom (`F2-ag`) | 404 | Excluded on **MSRV-policy fit and practice evidence**: R69 excluded `salvo` at **two** minors of headroom (`:1492`); 0 reverse dependencies, 26 stars, repo created 2025-09-03 (`F3`, `F5i`, `F5j`); it depends on `governor` 0.10, which gate 2 excludes (`F3a`, `F3b`); and its `Retry-After` is `wait.as_secs().max(1)`, the same truncation (`F3e`, `F3f`, read in 2.1.0) |
| `tower-rate-limiter` 0.1.6 | inapplicable — same ruling | `1.96.0` — passes on the letter, **zero** minors of headroom (`E1`, `F6-control`) | 404 | Excluded on **practice evidence and algorithm**: 296 all-time downloads, 0 reverse dependencies, 7 stars, crate first published 2026-08-06 and repo created 2026-08-02 (`F2-dlall`, `F3`, `F5k`, `F5l`); its store is a **fixed window** (`E3`); a key-extraction failure renders **500** (`F2a`, `F2b`); it adds **18** crates including `moka` (`E5`, `E6`) |
| `gcra` 0.6.0 | inapplicable — same ruling | `1.80.0` — passes | 404 | Excluded on **practice evidence**: 0 reverse dependencies (`F3`), 9 stars, no release since 2024-08-01 (`F2-date`) |
| `axum_gcra` 0.1.1 | inapplicable — same ruling | **`null` — FAIL** (`F2-rv`) | 404 | **Excluded by gate 2**; also 57 90-day downloads and 0 reverse dependencies |
| `tower-resilience-ratelimiter` 0.13.0 | inapplicable — same ruling | `1.85.0` — passes (`D-rv`, `F2-rv`) | — | Excluded on **fit**, as the Muse leg found: one global limiter per layer with no key, and its rate-limited error carries `retry_after: None`, leaving any 429 to the caller (`F4a`, `F4b`). Cannot express B4 or B6 |
| `tower::limit::RateLimitLayer` (`tower` 0.5.3) | inapplicable — same ruling | `1.64.0` — passes | — | Excluded on **fit**: one global limiter with no key, applying back-pressure by delaying `poll_ready` rather than refusing, so it can produce neither a 429 nor a `Retry-After`. Cannot express B3, B4, B5 or B6 |

**Fitness gates 1 and 4–6 for the recommendation itself.** Gate 1 licence —
inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool;
no crate is added and the code is the template's own under
`MIT OR Apache-2.0`. Gate 4 platforms — `std::sync`, `std::time::Instant` and `HashMap` are
core `std` on both `ubuntu-latest` and `macos-latest`; the probe ran on macOS 26.4 arm64.
Gate 5 default features and async-runtime coupling — none; `check` is a synchronous function
over `std::time::Instant` and nothing binds to tokio. Gate 6 binary size and compile time —
qualitatively nil: the resolved non-dev package set is **identical** to R69's baseline,
50 packages in both, `diff` empty (`C0`, `C1`, `C5`, with `C5-control` establishing that the
diff can discriminate), under committed lockfiles. Gate 3 advisories and `unsafe` — no crate
is added, so the advisory surface is exactly R69's, which R69 scanned to exit 0 against a
pinned database (`:2268-2276`); the template code contains **zero** `unsafe`, where taking
`governor` would add `quanta`, `parking_lot`, `getrandom` and `zerocopy` (`C6`).

**`BASELINE-REVIEW: F323 — rate limiting is wired but off by default, one env var enables
it — proposed change: the wiring and the single configuration surface stand; the
off-by-default default does not, and the Rust template ships limiting on — evidence:** the
org REST API Design Standard v2.0.0's R11.2 is a MUST scoped by no R1.6 applicability switch
(pinned blob lines 1686–1688 and 229–237; checks `R11.2`, `R1.6`, `S3a`, `S3b`), made
binding on this template's HTTP surface by owner ruling W2-REST (2026-09-18). Under R1.7
(lines 271–276) shipping it off would be conformant only as a recorded, owner-approved
exception, and this decision chooses to conform rather than to ask for one. R77 revision 4
(working copy, not accepted; sha256
`7e0cc569d88f884e4eb0829048536cf460962553f49dcded76bbe936ad92f884`) has already withdrawn the
single scalar `RSLBP_WEB_RATE_LIMIT` and reserved the family `RSLBP_WEB_RATE_LIMIT_*` with the
constraint that *"No member's default may disable rate limiting"* (`:935-949`). Affected
items: R74 (this one) and R77 (already moved). **F323's row is not edited here** — the
ledger belongs to the controller.

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
> authentication: R77's `WebSettings` *"declares no credential of any kind"* (R77
> revision 4, `:291`), and the template ships no login, no principal and no auth endpoint,
> so three of the five sub-dimensions have nothing to bind to; the fourth, per-endpoint,
> **could** apply and is omitted deliberately, to keep the template's quota surface one
> policy rather than a per-route configuration matrix nobody has asked for. Concurrency
> limiting is a separate mechanism (`tower::limit::ConcurrencyLimitLayer`) and is not this
> item's. · approver: pending owner review · date: 2026-09-18

**Argument.** R8.10's axis is written for a deployed API with authenticated principals and
a published quota page. This template is scaffolding: it ships one unauthenticated resource
and no identity. Adopting the axis default *in full* would require inventing an
authentication model in order to have a principal to meter, which is outside every item in
this wave and contradicts R56's and R77's positions. Adopting the *per-IP* dimension is not
a compromise — it is the one sub-dimension the standard names that this surface can actually
carry, and the standard itself prescribes its magnitude ("an order of magnitude lower" than
≈100 rps/account), which is where 10/second comes from. The burst of 20 is this template's
own starting choice — two seconds of sustained rate — and is not derived from the standard,
which supplies no burst figure. The dimension genuinely left on the table is per-endpoint
(25 rps/endpoint): it is expressible today, by keying on `(IpAddr, MatchedPath)` instead of
`IpAddr`, and it is omitted because a second quota dimension doubles the configuration
surface for a template with one resource. That is a judgement, so it is recorded here to be
inverted rather than buried.

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
Rule IDs are the standard's own (`**R1.6**` at line 229, `**R1.7 —` at 271, `**R1.8 —` at
312); section numbers are written with `§`.

| Rule | Line | Strength | What it requires | This design |
|---|---|---|---|---|
| `R11.2` | 1686 | MUST | *"An API MUST apply rate limits and communicate exhaustion via the published HTTP mechanism: `429 Too Many Requests` with `Retry-After`"* | **CONFORMS, and this is the rule that moved the recommendation.** Limits apply as shipped; no configuration member disables them; the refusal is 429 with `Retry-After` |
| `R11.3` | 1701 | SHOULD | *"An API SHOULD additionally advertise quota state using `RateLimit` and `RateLimit-Policy` in the syntax of `draft-ietf-httpapi-ratelimit-headers-11`"*, which line 1703 calls *"an unpublished Internet-Draft, not a standard"* | **CONFORMS.** Both fields are emitted, and the pinned draft revision is cited wherever they are named. Note honestly: the draft's `q`/`w` pair describes the **sustained rate only** — it has no field for the burst tolerance, which is documented in the API documentation instead |
| `R11.4` | 1707 | MUST | *"Any proprietary quota headers MUST be documented explicitly"* | **CONFORMS vacuously, by emitting none.** This is a further reason to reject `tower_governor`, which emits `x-ratelimit-after`, `x-ratelimit-limit`, `x-ratelimit-remaining` and `x-ratelimit-reset` (`D2c`), and `axum-governor`, which emits `x-ratelimit-limit` and its siblings (`F3d`), against line 362's *"No new `X-` names"* |
| `R11.5` | 1724 | MUST | *"`429` signals quota exhaustion … both MUST carry `Retry-After`"* | **CONFORMS.** Every 429 carries it; the value is floored at 1 so it is never absent and never `0` |
| `R5.12` | 1019 | MUST | every application-generated error response must be available as `application/problem+json`; the carve-out at line 1023 names *"rate limiters … terminating before application code"* | **CONFORMS through R70.** This limiter is application code, so the carve-out does not reach it. `tower_governor`'s bare-text 429 (`D2f`) would be nonconformant without an `error_handler` rewrite |
| `R5.13` | 1049 | MUST | a response-carried problem document MUST carry `type`, `title`, `status` and a stable `code` | **Resolved by R70 revision 4.** `type` is mandatory and never `about:blank` (R70 `:76`, `:181`), and `code` is a snake_case value R70 owns with R67's token beside it as `catalog_code` (`:77`, `:187`). The 429 inherits both once its catalog row exists (R5.16) |
| `R5.14` | 1098 | MUST | *"RFC 7807 MUST NOT be cited — it is obsoleted by RFC 9457"* | **CONFORMS.** This decision cites RFC 9457. The gemini leg cited RFC 7807; recorded under `## Engines` |
| `R5.16` | 1114 | MUST | an API must publish a catalog of every problem `type`/`code` pair | **Raised, not settled.** R67 has no rate-limit row, and R70 revision 4 records that the gap *"is R74's to raise, not this item's"* (`:552-557`). Raised below |
| `R12.2` | 1784 | MUST | *"Clients MUST honor `Retry-After`"* | **Bears on B6.** Because a conforming client obeys the header, a value below the true wait guarantees a second refusal — which is what `tower_governor`'s and `axum-governor`'s truncation produces and why this design uses a ceiling |
| `R8.10` | 1387 | MUST | five deployment-profile axes, each adopted or its flip recorded | **DEPARTS — `OVERRIDE (OV-17)` above** |
| `R1.6` | 229, 231, 237 | — | a rule scoped to an applicability switch binds only while the switch is on; the vocabulary is `webhooks · async-operations · bulk-operations · streaming` | **No rate-limiting switch exists** (checks `S3a`, `S3b`), which is why off-by-default could not have been an N/A-with-reason |
| `R1.7` | 271–276 | MUST | no silent deviation; a deviation from a MUST is conformant only as a recorded, approved exception | **CONFORMS.** The one deviation, from R8.10, is recorded as `OVERRIDE (OV-17)` in §1.9's shape; the departure from py's F323 is recorded as a `BASELINE-REVIEW:` finding rather than made silently |
| `R1.8` | 312 (352, 353, 362) | MUST NOT | reservation discipline: `Retry-After` mandatory on 429; `RateLimit`/`RateLimit-Policy` reserved for draft-11 syntax; no new `X-` names | **CONFORMS**; no reserved name is used for any other meaning and no `X-` name is minted |

### Hand-offs, couplings, and one gap this item raises

Every coupled decision cited here is pinned by revision, sha256 and line, as read at
2026-09-27T07:15Z (`r74-citations.sh`). None of R70, R73, R77, R79 or R80 is accepted; each
is a working copy that may still move. R77 and R79 were being edited by other sessions while
this revision was written: both files changed content after this revision first read them and
before 07:12Z (their modification times), without a revision bump, shifting R77's cited
lines by 6 and R79's by 24. The pins are of the bytes read at 07:15Z, so `r74-citations.sh` fails when either file moves again, and the
`re-verify:` line fires on either item publishing.

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

**R70 (`http-problem-envelope`, revision 4, sha256
`7a9345c67b42d504501e2039214fd42d9d31b69d61402c958c62c5bf7448a410`) — coupling, now resolved
on R70's side.** R70 builds one RFC 9457 document in `crates/web/src/problems.rs`, and
`WebError` carries `headers: Vec<(HeaderName, HeaderValue)>` with a `with_header` builder
whose `IntoResponse` inserts them after the body is rendered (`:343-345`). That is the exact
carrier this item needs: the `RateLimited` value becomes a `WebError` variant carrying
`retry-after`, `ratelimit` and `ratelimit-policy` through `with_header`. The two
standard-conformance questions revision 1 stated and left open are **resolved by R70
revision 4**: `type` is mandatory and never `about:blank` (move M-1, `:76`), and `code` is a
snake_case value R70 owns, with R67's `RSLB`-grammar token carried beside it as
`catalog_code` (move M-2, `:77`; field rows `:181`, `:187`). Nothing remains for this item
to state about either.

**The gap this item raises, as R70 asked it to.** There is **no catalog code for rate-limit
exhaustion**. R67's catalog is `RSLB` + three digits with the hundreds digit equal to the
process exit code, and its exit taxonomy (`0 1 2 3 4 5 130 143`) has no member for quota
exhaustion, so a new row has no obvious block. R70 revision 4's code table maps each existing
R67 row to its HTTP `code` and `type` (`:231`) and has no rate-limit row, and R70 records the
gap as this item's to raise (`:552-557`). The standard's own example uses
`code: "rate_limit_exceeded"` with
`type: "https://problems.example.com/rate-limit-exceeded"` (lines 3205–3209, checks `E9a`–`E9c`).
**R67 owns the number and the block, and R70 then owns the HTTP `code` and `type` for it;
this item states the requirement and invents neither.**

**R73 (`idempotency-middleware`, revision 2, sha256
`842d48f67a140cb46b9909ac5e09de729fd267660bdf4f106aaa82ac2d99915e`) — a placement constraint
handed to R75, agreed with R73.** R73's decision proposes placing rate limiting **outside**
idempotency and says *"R74 owns the decision"*
(`research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/DECISION.md:981-985`). This item
accepts that proposal as its ordering requirement, and hands it to R75 as constraint (2)
below; the prompt's out-of-scope list leaves the final placement in the stack to R75. R73's
two reasons hold — a 429 then never creates an idempotency claim it must abandon, and the
idempotency layer buffers the request body to fingerprint it, so a request that will be
refused should be refused before that copy is paid for — and py agrees at the pin:
`app.py:131-135` adds `IdempotencyMiddleware` first and `_install_rate_limiting` is added at
`:143-144`, after it, and Starlette's last-added is outermost.

**R75 (`http-middleware-stack`, not yet researched) — ordering constraints, handed over.**
R75 owns F317 and the final order. (1) The 429 must carry the request-id and security
headers, so the limiter sits **inside** those two. (2) The limiter sits **outside** R73's
idempotency layer, as agreed with R73 above. (3) The limiter sits **inside** whatever
installs `ConnectInfo`. (4) An observation the Muse leg adds, verified at the pin: py
registers CORS at `app.py:136-142` and the limiter after it, so py's limiter sits **outside**
CORS and meters preflight requests; the comment at `app.py:128-130` states that CORS
preflights and slowapi 429s both short-circuit. Whether the Rust stack keeps that is R75's
choice; this item records the py fact and takes no position. A fifth, handed over rather than
decided: R80's `/healthz` and `/readyz` and R79's `/metrics` must remain reachable when a
caller is being throttled. R79 revision 3 (sha256
`942ea9d2ce7dfefd1657eb261340c287d4b18437428ebc9ae78d76c35363bee1`) merges `/metrics` on a
router **after** `route_layer` has been applied, so its own RED layer does not measure it
(`:341-344`); the same merge-after-`route_layer` placement would exempt probe paths from this
limiter, but R79 also requires R75's request-id layer to use `.layer()` on the merged router
(`:688`), so which router the limiter attaches to is a placement R75 must decide. R80
revision 3 (sha256 `184d2b1714f8eb26a7b4df43b6020feb280662e85fcf3668a7fb0938d0d230c8`)
records the probe-reachability problem as *"an input to R75, not a decision for it"*
(`:760-761`). **This item deliberately does not add an exempt-paths configuration knob**: the
reachability of probe paths is a placement property, which is R75's, not a quota setting.
**One ledger observation for R75, verified rather than carried:** F317's note says
*"id/security-header middleware outermost"* and `docs/port/areas/web-service.md:23` cites
`app.py:145 — app.add_middleware(SecurityHeadersMiddleware)` as *"added last (outermost)"*.
At the pin, `app.py:146` adds `RequestIDMiddleware` *after* it, so the actual outermost layer
is the request-id middleware. Read directly this session:
`git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/web/app.py | sed -n '120,150p'`.
The row is R75's; this is reported so R75 can check it, not changed here.

**R77 (`web-env-settings`, revision 4, sha256
`7e0cc569d88f884e4eb0829048536cf460962553f49dcded76bbe936ad92f884`) — the family membership
this item owes it, and one invariant handed to it.** R77 revision 4 reserves the prefix
`RSLBP_WEB_RATE_LIMIT_*`, states that *"R74 fixes which members exist, their units and their
values"* (`:950`), sets no floor on the member count (*"The family's size is whatever R74
publishes; this item sets no floor"*, `:941`), and constrains the family with *"No member's
default may disable rate limiting"* (`:948`). This item fixes **three** members:

| Variable | Type and grammar | Default | Why |
|---|---|---|---|
| `RSLBP_WEB_RATE_LIMIT_PER_IP` | py's `limits` notation, `"<count>/<period>"` with `period ∈ {second\|sec\|s, minute\|min\|m, hour\|hr\|h, day\|d}` | `10/second` | R8.10's unauthenticated per-IP dimension, *"an order of magnitude lower"* than the axis's ≈100 rps/account |
| `RSLBP_WEB_RATE_LIMIT_PER_IP_BURST` | positive integer | `20` | R8.10's *"token-bucket burst"*, which the sustained rate cannot carry. Two seconds of sustained rate; this template's choice, not the standard's |
| `RSLBP_WEB_RATE_LIMIT_MAX_ENTRIES` | positive integer | `65536` | the bounded store's cell capacity; named to match `RSLBP_WEB_IDEMPOTENCY_MAX_ENTRIES` (R77 revision 4, `:759`) |

Three suffice **because** `OVERRIDE (OV-17)` ships one dimension; R77 anticipated a different
member set: *"If R74 publishes a posture that needs a different member set, the family
prefix still holds and only the membership moves"* (`:955-957`). Option 2 of the override
would add two more. The `limits` grammar is kept from py because F323 records a single
string per dimension. **The invariant handed to R77**, because the shipped signature takes a
`RateLimitPolicy` and not an `Option`: the settings value for each member maps to a value,
never to "off". R77's own rule that *"an exported-but-empty variable is unset"* (`:296`)
then means an empty `RSLBP_WEB_RATE_LIMIT_PER_IP` falls back to `10/second` rather than to
"off", and a non-empty invalid value (for example `off`) is a startup error, never a silent
disable. `policy_from_setting` in the probe is the executable statement of that invariant
(`A settings_values_tune_but_never_disable`); the environment plumbing that calls it is R77's.

**R79 (`prometheus-metrics`, revision 3) — a hand-off R79 still declines by shape.**
The Opus and Muse reports both hand R79 two counters, a rejected-request counter and a
store-saturation counter. R79 revision 3 ships exactly two instruments and says so as a
position — *"Two instruments, not three"* (`:178`) — and still describes this item as
*"R74's opt-in rate limiting, whose default is off"* (`:570-571`), a characterization this
decision makes stale. So the hand-off is **a request R79 has pre-emptively refused**, not a
coupling this item may assume. It is recorded as a re-verify trigger: without a saturation
counter the fail-open condition above is silent, which is the one place this design depends
on an observability decision it does not own.

**R02 and R05 (accepted-but-unpublished) — consumed as facts.** R02, accepted at revision 2
(`docs/port/OWNER-ACCEPTANCES.md:71`; the working copy is still revision 2, sha256
`9e8f8e8c11ffb9b383819b2de1b05eab71a32e3af358b75ea8475d48f3c9707f`), fixes the four-package
workspace, with `rs-launch-blueprint-web` at `crates/web/` and the composition root and
`rslbp-serve` binary in the root facade package (R02 `DECISION.md:23-29`); every path in this
decision is written against that layout. R05, accepted at revision 3 (`:75`), fixes the
synchronous core; the limiter touches no core port and adds nothing to `crates/core`. R05's
working copy has since moved to revision 5; this decision consumes the accepted revision's
ruling as `OWNER-ACCEPTANCES.md:75` records it.

### Migration implications

File-level changes, against R02 revision 2's four-package workspace and R69 revision 10's
`crates/web` layout. Nothing outside `crates/web` and the root package's composition root
changes, and no dependency is added.

| Path | Change |
|---|---|
| `crates/web/src/rate_limit.rs` | **New.** `RateLimitPolicy` + `FromStr` + `with_burst`, `PolicyParseError`, `RateLimitKey`, the `RateLimitStore` port, `InMemoryRateLimitStore`, `RateLimitState`, `retry_after_seconds`, the `RateLimited` rejection, the `rate_limit` middleware function, and `install_rate_limit(router, policy: RateLimitPolicy, store: Arc<dyn RateLimitStore>) -> Router`. `install_rate_limit_conditional` is **not** shipped |
| `crates/web/src/lib.rs` | One line: `mod rate_limit;`; and `build_router` gains one `install_rate_limit(router, policy, store)` call, placed where R75's order puts it |
| root package's composition root | Constructs `InMemoryRateLimitStore` from the settings and erases it to `Arc<dyn RateLimitStore>`, beside R73's idempotency adapter |
| `crates/web/src/lib.rs` (`serve_until`) | `axum::serve(listener, app)` becomes `axum::serve(listener, app.into_make_service_with_connect_info::<SocketAddr>())`. **Required**, not optional. Hand-off to R69/R75 |
| `crates/web/Cargo.toml` | One line: `tracing = { version = "0.1", default-features = false, features = ["std"] }` for the warn-once, which adds **zero** packages to the resolved set (check `C2`). R58 may supersede this declaration; if so this item needs none |
| R77's settings module | Three fields for the `RSLBP_WEB_RATE_LIMIT_*` family, with the defaults tabulated above, each parsed to a value and never to "off". R77 owns the names and the env plumbing |
| `crates/web/tests/rate_limit.rs` | **New.** The executed acceptance tests on the shipped form, plus the R70-envelope assertion once R70 publishes |
| `README.md` / `crates/web` module docs | The swap-point paragraph F316 requires — `RateLimitStore` is the seam, `InMemoryRateLimitStore` is single-instance by design, the enforced rate across `N` instances is `quota × N`, and an external gateway is the production answer at scale — plus the API's conformance note carrying `OVERRIDE (OV-17)` and the published quota, which R11.4 and R8.10 both require to be written down |

re-verify: **2027-03-18**, or earlier on any of — the owner ruling on `OVERRIDE (OV-17)`, or declining it in favour of option 2, which adds the per-endpoint dimension and two family members; the owner ruling on the `BASELINE-REVIEW: F323` finding, where declining the move restores py's off-by-default gate (the compiled `install_rate_limit_conditional` form) and would require R11.2's deviation to be recorded as an approved exception under R1.7; the org REST API Design Standard moving off blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9` or amending R1.6, R1.7, R1.8, R5.12, R5.13, R5.16, R8.10, R11.2, R11.3, R11.4, R11.5 or R12.2; `tower_governor` or `governor` publishing a release that declares a `rust-version` within the floor, which clears gate 2 and reopens the comparison (checks `F2-rv`, `F6`); `axum-governor` gaining reverse dependencies or a ceiling `Retry-After`; the owner revisiting the gate-2 strict reading; **R69** republishing, changing `serve_until`'s `axum::serve` argument, or moving `web-extra-surface`'s registry bytes from `src/web/` to `crates/web`; **R70** publishing the envelope this 429 renders through; **R67** answering the rate-limit catalog-row request this decision raises, and R70 then fixing its HTTP `code` and `type`; **R73** publishing, so the two bounded in-memory stores can share an eviction discipline; **R75** publishing the layer order and dispositioning the ordering constraints, the CORS observation and the F317 outermost-layer observation above; **R77** publishing and fixing the `RSLBP_WEB_RATE_LIMIT_*` plumbing against the three members and the never-"off" invariant named here; **R79** publishing a saturation counter, without which this design's fail-open condition is unobservable; **R80** publishing and fixing whether probe reachability is a placement property or needs a configuration knob after all; the controller registering the Muse leg with a sha256 other than the one under `## Engines`; `axum` publishing 0.9, which moves the `serve` call this design constrains; `draft-ietf-httpapi-ratelimit-headers` becoming an RFC, at which point R11.3's SHOULD stops resting on an unpublished draft; at the next `msrv-policy` floor advance past 1.96, which changes the headroom figures for `axum-governor` (1.95) and `tower-rate-limiter` (1.96.0); or P03 measuring the limiter on the real router and finding the single mutex or the 65,536-cell capacity wrong

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
`src/web/`, `dep:axum`/`dep:tokio` text (re-read 2026-09-27), while R69 revision 10 —
accepted but unpublished (`docs/port/OWNER-ACCEPTANCES.md:60`) — carries a different value at
`:1791` naming `crates/web` and `dep:rs-launch-blueprint-web`, and the two hash differently.
The Opus report quotes the registry (revision 9) value on its `- assumes` line while writing
its file paths against revision 10; that inconsistency is recorded under `## Engines`. **This
decision assumes R69 revision 10's shape in prose**: an additive, off-by-default Cargo feature
named `web`, `axum` 0.8.9 and `tokio` 1.53.1 declared inside `crates/web`, `tower` 0.5.3 as
`crates/web`'s dev-dependency only for the `ServiceExt::oneshot` idiom, and every later web
layer — this one included — as a module inside that gated tree. The `re-verify:` line fires
when those bytes move.

The remaining parameters bear on this decision as follows. `msrv-policy` sets the floor at
**1.96** (current stable 1.98.1 on 2026-09-27, checks `F1a`, `F1b`) and is the rule that
excludes `tower_governor` and `governor` and that reduces `axum-governor` and
`tower-rate-limiter` to one and zero minors of headroom. `rust-edition` `2024` is what the
probe compiled under. `target-os-matrix` is satisfied by `std` alone; the probe ran on macOS
26.4 arm64 and the feature uses no platform-specific API. `license` is inapplicable to
candidate selection under the owner's 2026-09-12 ruling and applies only to this repository's
own source.

## Empirical check

Toolchain: `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc
2026-08-05) (Homebrew)` — current stable on 2026-09-27 (`F1a`) — macOS 26.4, `Darwin arm64`;
`grep (BSD grep, GNU compatible) 2.6.0-FreeBSD` at `/usr/bin/grep`; `shellcheck 0.11.0`;
`jq-1.8.2`. `CARGO_HOME` was a private directory, empty when this revision started. Two
exploratory `cargo fetch` runs, made to read the Muse leg's cited sources, filled part of it
before the probe's recording run; section L fetched the rest. Working directory for every
script: `research/runs/R74/2026-09-18T215916Z-14066395aaea/review/evidence/`. Every script
below is `shellcheck`-clean and exits non-zero on any failure, except the fetcher, which
asserts nothing.

| Script | Checks | Result (2026-09-27) | Log |
|---|---|---|---|
| `r74-probe-r2.sh` | 87 | 87 PASS, 0 FAIL, 0 SKIP | `review/evidence/r74-probe-r2.log` |
| `r74-registry-figures-r2.sh` | 130 | 130 PASS, 0 FAIL, 0 SKIP | `review/evidence/r74-registry-figures-r2.log` |
| `r74-rest-conformance.sh` | 48 | 48 PASS, 0 FAIL, 0 SKIP | `review/evidence/r74-rest-conformance.log` |
| `r74-citations.sh` | 134 | 134 PASS, 0 FAIL, 0 SKIP | `review/evidence/r74-citations.log` |
| `r74-decision-shape.sh` | 96 | 96 PASS, 0 FAIL, 0 SKIP; run last, against this file | `review/evidence/r74-decision-shape.log` |
| `r74-fetch-snapshots.sh` | — | the network fetcher; **no assertions, and its log is deliberately not reproducible**. Revision 2's fetch wrote `snapshots-r2/` (39 payloads, 2026-09-27T06:26–06:30Z). This revision's first attempt ran it, before a usage limit stopped that attempt; it was not re-run, so the recorded snapshots are not overwritten. Its log ends with the full 39-row manifest, which matches `snapshots-r2/MANIFEST.tsv` (`S0a`–`S0d`) | `review/evidence/r74-fetch-snapshots-r2.log` |

**Carried unchanged from revision 1, and not cited for any revision-2 figure.**
`r74-registry-figures.sh` and its log assert the 2026-09-19 figures against `snapshots/`, and
still reproduce byte for byte (rerun 2026-09-27, `cmp` empty, 88 PASS); section 7 of the r2
script reads them as the drift baseline. `r74-probe.sh` and `r74-probe.log` are revision 1's
probe, superseded by `r74-probe-r2.sh` because of EA-2 to EA-4, and kept so the audits'
reruns stay reproducible. `r74-fetch-snapshots.log` is revision 1's fetch. The fetcher script
itself was edited for revision 2: its default target is now `snapshots-r2/`, so revision 1's
`snapshots/` is never overwritten, and it adds one 100-row reverse-dependency page for
`governor` and for `tower_governor`, for the adopters the Muse leg names.

**Nothing being recommended was built.** `r74-probe-r2.sh` writes eight throwaway Cargo
crates into a directory it creates with `mktemp -d` under `$TMPDIR` and deletes on exit. The
only files it keeps are the eight dependency lockfiles under `review/evidence/probe-locks/`,
named `<crate>.lock` so that no file named `Cargo.lock` exists. No `.rs` file, `Cargo.toml`,
`Cargo.lock`, `src/` or `target/` exists anywhere under this run directory, which
`r74-decision-shape.sh` asserts (`S5d`, `S5e`). The probe is a verification of what the raws
claim, not a template scaffold.

**`r74-probe-r2.sh` — 87 checks.**
- **L** (8): each probe crate is resolved from its committed lockfile under `--locked` and
  fetched online. This is the only network phase, so a cold, private `CARGO_HOME` works
  (EA-2). The registry path is `${CARGO_HOME:-$HOME/.cargo}/registry/src/…`. The log prints
  each lockfile's sha256.
- **T1**: the toolchain is at or above the 1.96 floor.
- **D** (15): the declared `rust-version` and `edition` of seven published manifests. The
  control `D-control` asserts the reader finds `axum` 0.8.9's `1.80`, so `tower_governor`'s
  and `governor`'s `NONE` is a real absence and not a broken reader.
- **D2** (7): the `tower_governor` source facts the two measured defects rest on. One of them
  **corrects a widely repeated claim**: `src/lib.rs` inserts `retry-after` as well as
  `x-ratelimit-after`, so the crate is not missing the standard header — its value is wrong.
- **A** (13): compiles the recommended design and runs **nine** tests, then the pass total,
  the signature check `A-sig`, its control, and `cargo clippy --all-targets -- -D warnings` with no
  diagnostic. Seven of the nine tests run on the shipped `install_rate_limit`:
  - The shipped default posture limits: the 21st request from one IP at 10/s burst 20 is 429
    with a `retry-after` of 1–2 and `ratelimit-policy: "default";q=10;w=1`.
  - A `2/minute` quota refuses the third request with `retry-after` **exactly 30** and leaves
    exactly one cell in the store.
  - A second key is admitted after the first is exhausted, and ten further keys against a
    capacity of 3 leave at most 3 cells.
  - Settings values tune but never disable: unset and `""` map to the default posture;
    `off` and `0/second` are errors; `1/minute` on the shipped call site refuses the second
    request.
  - Rate and burst are independent over simulated time: 120 against 110 and 220.
  - The grammar parses `100/minute` to rate 100 / burst 100 / 60 s, raises the burst to 250
    independently, and rejects `100`, `0/minute` and `100/fortnight`.
  - The ceiling maps 1 ms → 1, 0 → 1, 1500 ms → 2 and 29.99 s → 30.

  The remaining two are a control (a router without the layer admits 1,000 requests) and the
  HIGH-question-2 evidence (the `Option` form yields 50×200 with `None` and 200-then-429 with
  `Some`).
- **B** (3): the two `tower_governor` observations. Without `ConnectInfo` the default key
  extractor returns **500**. With it, the third request is **429** carrying
  `retry-after: 29` and `x-ratelimit-after: 29` for a true wait of 29.99…s, with **no**
  `content-type`.
- **C** (16): measures the dependency-set deltas.
- **E** (6): establishes what `tower-rate-limiter` 0.1.6 is.
- **F** (18): reads the source claims the Muse leg makes, each at the file and line Muse
  cites, plus `axum-governor`'s `Retry-After` arithmetic, with a positional control.

**The counting rule for section C, and the lockfiles that pin it.** `cargo tree -e normal`
prints one line per *edge* and repeats a shared subtree as `name vX.Y (*)`, so its raw line
count is not a package count: a first run of revision 1's script reported the baseline as 114
and the `tower_governor` delta as +73. The figure used is the set of **distinct
name-and-version entries** in the non-dev tree with the probe's own root package removed —
the rule the Opus report used. Under it the baseline is **50**, the recommended design is
**50** with a `diff` of the two sets empty (`C5`), adding `tracing` with
`default-features = false, features = ["std"]` is still **50** (`C2`), `tower_governor` with
`default-features = false, features = ["axum"]` is **87** (**+37**, `C3`) and with its
default features **99** (**+49**, `C4`). `C5-control` asserts that the `tower_governor` set
is *not* identical to the baseline, so `C5`'s empty diff cannot be vacuous. The transitive
sets were resolved once on 2026-09-27 (`R74_RECORD_LOCKS=1`) and every later run replays the
committed lockfiles with `--locked`, so these counts no longer depend on the day's resolution
(EA-3). The recording run and both replays gave the same five figures, which also match
revision 1's.

**`r74-registry-figures-r2.sh` — 130 checks, and it touches no network.** Every crates.io,
GitHub and RustSec payload this revision cites was fetched once by `r74-fetch-snapshots.sh`
into `review/evidence/snapshots-r2/`, and every assertion reads the snapshot.
`snapshots-r2/MANIFEST.tsv` records each payload's endpoint and its UTC retrieval time. The
retrieval window is **2026-09-27T06:26:22Z – 2026-09-27T06:30:16Z** (`S0c`, `S0d`) and the 39
rows are asserted (`S0a`). GitHub requests were made through keyring-authenticated `gh api`,
one per 20 seconds, enforced by a `sleep 20` before each call. crates.io requests were one
per second under the User-Agent
`rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)`. The
script asserts:
- the floor derivation (`F1a`, `F1b`);
- nine crates' 90-day and all-time downloads, newest non-yanked `num` and `created_at`,
  `rust_version` and `license` (`F2-*`), `axum-governor`'s three releases since 2026-09-05
  (`F2-ag`), and `loco-rs` (`F2-loco`);
- six reverse-dependency totals (`F3`), and the eight adopters the Muse leg names, found in
  the first 100 dependents of `governor` or `tower_governor`, with a negative control
  (`F3-adopter`);
- six RustSec 404s against a **200** control on `dashmap` (`F4`, `F4-control`);
- the maintenance figures (`F5a`–`F5n`), where `F5d`/`F5e` record both the `search/issues`
  `total_count` of **19** that the prompt requires and the `open_issues_count` of **24**
  that it forbids;
- the gate-2 reads **at `master`** (`F6`), with `F6-control`;
- in section 7, the drift from 2026-09-19 for every decision-bearing field (`DR-*`).

**Drift between 2026-09-19 and 2026-09-27, stated with dates.**
- **Moved:** `axum-governor` released 2.1.1 (2026-09-23) and 2.1.2 (2026-09-26), and both
  still declare `rust-version` 1.95, so its gate-2 disposition and its one minor of headroom
  are unchanged (`DR-rel`, `F2-ag`). Its repository's `pushed_at` moved to
  2026-09-26T08:06:45Z. `governor`'s reverse-dependency total moved from 483 to 489 and
  `tower_governor`'s from 81 to 82 (`DR-rev`). Neither moves a practice-evidence verdict,
  because neither crate is excluded on adoption. Download counters moved on every crate, and
  no conclusion turns on a difference of that size.
- **Did not move between the two retrievals:** the newest release and declared
  `rust_version` of the other eight crates, including the three `null`s that fail gate 2;
  the four zero reverse-dependency totals; `archived` on all four repositories;
  `tower-governor`'s `pushed_at` of 2025-08-14; all seven RustSec status lines; current
  stable; and the REST standard snapshot (`DR-*`).

**`r74-rest-conformance.sh` — 48 checks.** It asserts:
- each rule text this decision quotes appears **on the line the decision cites**, in a
  snapshot of the pinned blob;
- the section headings and rule IDs themselves: §1.8 carries `**R1.6**`, §1.9 carries
  `**R1.7 —`, and §1.10 carries `**R1.8 —` (`R1.6-sec`, `R1.7-sec`, `R1.8-sec`);
- R1.7's sentence in full across lines 273–276 (`R1.7b`–`R1.7e`);
- the snapshot is byte-identical to `git -C /Users/stevemorin/c/rest-standards cat-file blob
  71bd813c1cf61286586b4ee41ed83ff065e5c8d9`, and the commit's `rest-api-standard.md` *is*
  that blob (`P0a`–`P0d`);
- §11.2's block carries no applicability-switch scoping, and R1.6's vocabulary has no
  rate-limiting member (`S3a`, `S3b`);
- the standard's own 429 example carries `Retry-After: 30` and `rate_limit_exceeded`
  (`E9a`–`E9c`).

`P0-control` asserts that line 1 does **not** carry R11.2's text, so the positional locator
can fail. Revision 1's log (40 checks) carried the mislabelled IDs of audit finding 2. It is
regenerated here, and the only changes are the renamed labels and the eight added checks.

**`r74-citations.sh` — 134 checks.** Every cross-file citation this revision makes into
another item's decision or a programme document is asserted: the needle must appear on the
cited line, and each coupled decision's sha256 must equal the value this decision pins. A
coupled item that moves therefore fails the check rather than leaving a stale citation.

**`r74-decision-shape.sh` — 96 checks, run last.** It checks this decision's shape
against a published topic decision (`research/topics/53-config-schema-validation/DECISION.md`,
revision 2): the title grammar, the H2 set in order, the `- assumes` lines and the
revision-note preamble. It also checks the parameter lines' byte-identity with the live
registry, the override's §1.9 shape, the enumeration of mentions this revision owes, the
hygiene and no-scaffold rules, and the sibling logs' totals. It also runs
`scripts/check-answer-shape.sh` on `raw/muse.md` (`S8a`), because the Muse leg is represented
here from disk. Revision 1's section, which ran the raw-answer validator on this decision, is
removed: that validator checks raw answers, not decisions.

**Reproducibility, stated per log rather than generically.**
- **Byte-identical on rerun** (both read committed files and touch no network):
  `r74-registry-figures-r2.log`, `r74-rest-conformance.log`, `r74-citations.log` and
  `r74-decision-shape.log` were each rerun and compared with `cmp` after they were written.
- **`r74-probe-r2.log` is not byte-for-byte reproducible.** The comparison rule (EA-4) is:
  - Must be identical across reruns: the 87 `PASS`/`FAIL`/`SKIP` lines, the `CHECKS RUN:`
    summary, the `baseline=… design=… tracing=… tg_nodefault=… tg_default=…` line and the
    eight lockfile sha256 lines. That is 97 lines, verified by a second replay and `diff`.
  - Excluded by rule: the `toolchain:` and `cargo:` lines, which move with the installed
    toolchain; the `workdir:` line, which carries a fresh `mktemp` suffix; the `cargo home:`
    line; and cargo's `Compiling …`, `Finished …` and `finished in N.Ns` lines.
- **`r74-fetch-snapshots-r2.log` is not reproducible by construction.** Re-running the
  fetcher re-fetches live counters, which is how an auditor sees drift. To avoid overwriting
  the recorded snapshots, point it at a scratch directory with `R74_SNAP_DIR`.

**What could not be verified, and is carried rather than re-derived.**
- **The Opus report's throughput table** (1,000,000 admit-path checks across {1,8} threads ×
  {1, 10,000} keys, 14.7M–6.2M ops/s for the recommended store against 27.1M–7.8M for
  `governor`'s `DashMap`) was **not** re-run. Nothing in this decision turns on it beyond one
  claim: the worst measured figure, 160.7 ns per check, is under 0.02% of a 1 ms request.
  That claim survives any plausible re-measurement.
- **Issue-responsiveness figures**, labelled as carried: `governor`'s median of 1 day across
  the three of seven recent issues a maintainer answered, and `tower_governor`'s zero
  maintainer responses across its ten most recently opened issues. The `pushed_at` of
  2025-08-14 and the 19 open issues are asserted (`F5c`, `F5d`), but the per-issue comment
  walk was not repeated.
- **`loco-rs`'s middleware source** was not re-read.

Genuinely **unproven**:
- slowapi's own `Retry-After` rounding. slowapi is a dependency of the pinned repository
  rather than a file in it, so whether py truncates or rounds is unknown. The ceiling is this
  template's argued choice rather than a match to py.
- issue-responsiveness medians for `gcra`, `ratelimit`, `axum-governor`, `tower-resilience`
  and `tower-rate-limiter`. Their issue populations are 0–3, too small for a median, so the
  raw counts are reported instead.
- a cold-cache run of `r74-probe-r2.sh` in a fully empty `CARGO_HOME`. This environment
  forbids overriding `CARGO_HOME`, and the one private directory available had been partly
  filled by two exploratory `cargo fetch` runs before the recording run. Section L's
  cold-cache behaviour therefore rests on its construction: it runs `cargo fetch --locked` for
  every probe crate before any `--offline` call. It was not observed from empty. An auditor
  with a fresh `CARGO_HOME` closes this gap by running the script once.

One endpoint failed and is recorded rather than omitted:
`search/issues?q=repo:nivek-ph/tower-rate-limiter+is:issue+is:open` still returns HTTP
**422** because the account was renamed (`F5n`). The repository endpoint resolves through the
redirect and reports `full_name: nivek3/tower-rate-limiter` (`F5m`).

## Engines

- opus `raw/opus.md` (Claude Opus 5, sha256 `43fe88523480cefe87a022eb36a012e09fd2177c644672c25c0868bffcf60dc7`)
- doxa `raw/doxa.md` — the three-provider report, operation `research-20260918-151845-96abb3c658eb437e`, with twins `raw/doxa.normalized.md`, `raw/doxa-openai.normalized.md` (`gpt-5.6-sol`), `raw/doxa-perplexity.normalized.md` (`sonar-deep-research`) and `raw/doxa-gemini.normalized.md` (`deep-research-preview-04-2026`). Per `doxa/normalization.json` the openai and gemini twins needed **no** changes; the perplexity twin needed **22 lossless heading repairs**, every one a letter-case fix (`### Principles and Implementation` → `### Principles and implementation` and the like), with `content_lines_missing_from_regrouped: 0` on all three
- muse `raw/muse.md` (Muse (Meta), model `muse-spark`, sha256 `c3e018cfd5f7df4f4887d4c04d2464fbd0280e749a42d7a69e48a8684c2690dd`, 337 lines, request `e762efa45fe34c2db2a4efd1fa28f85c`). It passes `scripts/check-answer-shape.sh … bundle` (check `S8a`). Its operation in `operations/muse.json` and in `manifest.json` is still `"state": "submitting"`, so the leg is present on disk but **not yet registered as collected**. Registering it is the controller's job through the runner, which a synthesizer may not run. This decision represents and adjudicates the on-disk file, identified by the sha256 above, and its `re-verify:` fires if the leg is registered with any other sha256

**Why Muse and not Codex.** R74 is a Deep item, and the Deep default engine set is Codex, Opus
and Doxa. The authority chain for substituting Muse is:

1. **Q5.A** (2026-09-21) migrated this run. `manifest.json` records a migration event with
   `"from": "codex"`, `"to": "muse"`, `"reason": "muse bulk substitution (owner decision Q5.A
   2026-09-21)"`, and `required_engines: ["muse","opus","doxa"]`.
2. **Q9.B** then retired Codex from P02 entirely (`research/RUNBOOK.md:72-73`).
3. The live policy text is `research/RUNBOOK.md:70-76`, as revised under **Q17.A**
   (2026-09-27). It lists R74 in the Muse bulk set (`:71`), and Q17.A extends the same
   substitution to the next research wave.
4. `research/EXECUTION.json` mirrors that policy with `"R74": ["muse", "opus", "doxa"]`, and
   the prompt's `- engines:` line carries the same set (line 25).

Revision 1's Codex bullet, which cited the earlier deferral W1-CODEX3, is withdrawn.

**What P03 must validate, because this decision is a proposal and not an implementation.**
(1) That the 429 body is R70's problem document — blocked on R70 publishing; the probe
asserts status and headers against a placeholder body. (2) That the serve path installs
`ConnectInfo` — needs a real `TcpListener`, and is the **first** thing to check, because
without it the shipped default meters every caller through one bucket. (3) That the
limiter's placement in R75's final order satisfies the constraints above and leaves
`/healthz`, `/readyz` and `/metrics` reachable under throttling. (4) A property test over
random `(rate, burst, period, arrival sequence)` asserting that admissions in any window
never exceed `burst` plus the sustained allowance and that a client obeying `Retry-After` is
never refused twice consecutively. (5) A clock-injection refactor so eviction is tested
against a fake clock rather than wall time; `check` already takes `now`, which is how the
simulated-time test injects it. (6) A concurrency-stress or `loom` test for the store.
(7) Whether a poisoned `Mutex` should fail open with a warning rather than panic — the probe
uses `.expect("poisoned")` and this decision deliberately leaves the question open.
(8) Whether 65,536 cells and a single mutex hold on the real router.

**Disagreement 1 — the recommendation itself. Five reports, four answers; settled on executed
evidence.** Opus and Muse both recommend a template-owned zero-crate GCRA design
(`raw/muse.md:51`). perplexity recommends `tower_governor` + `governor`. gemini recommends
`axum-governor` + `governor`. openai recommends `tower-rate-limiter` 0.1.6. **Opus and Muse
are right on the design, and the other three fail on facts this synthesis executed rather
than on judgement.** `tower_governor` and `governor` declare no `rust-version` at the release
*or* at `master` (`F2-rv`, `F6`), which fails gate 2 under the reading the owner settled.
`axum-governor` declares `1.95` on 2.1.0, 2.1.1 and 2.1.2 (`F2-ag`), one minor of headroom
where R69 excluded `salvo` at two. It also has **zero** reverse dependencies against 26 stars
(`F3`, `F5i`), and it truncates `Retry-After` (`F3e`, `F3f`). `tower-rate-limiter` is real:
it exists at 0.1.6, is `MIT OR Apache-2.0`, edition 2024 and `rust-version = "1.96.0"`, and
has exactly the architecture the openai leg describes. But it has **296 all-time downloads**,
**zero** reverse dependencies and **7** stars; its crate was first published **2026-08-06**
and its repository created **2026-08-02**; and it adds **18** crates including `moka`
(`F2-dlall`, `F3`, `F5k`, `F5l`, `E5`, `E6`). Under the prompt's practice-evidence
requirement it has none, which the openai leg states honestly itself: *"No well-regarded
production adopter was verified."* Muse reaches the same verdict on it — "watch, do not
adopt" (`raw/muse.md:35`) — and adds that a key-extraction failure renders 500, which is
confirmed (`F2a`, `F2b`).

**Disagreement 2 — the algorithm, where the openai leg corrects Opus and Muse and the
standard settles it.** Opus rejects a fixed window because its reported wait "over-states the
wait for every request except the last", and Muse repeats the same reasoning three times
(`raw/muse.md:35`, `:138`, `:149`). That reasoning is **wrong**: in a fixed window a refused
caller genuinely cannot succeed until the window rolls, so the window end is the exact next
admission. The openai leg names the real defect — *"fixed-window boundary bursts"* — and the
binding standard decides it: R8.10's axis default is *"per-principal sustained +
token-bucket burst"*, two independent parameters that a fixed window cannot express. GCRA
can, and the probe carries `rate` and `burst` as separate fields with the arithmetic asserted
(`A policy_grammar_matches_py_limits_notation`: raising the burst to 250 leaves the sustained
rate at 100 and gives a 600 ms emission interval). `tower-rate-limiter` 0.1.6's own source
says *"An asynchronous fixed-window rate-limit store"* (`E3`), so the openai leg's pick fails
the criterion the openai leg itself identified. Both reports' conclusion (reject fixed window)
stands; their reason does not.

**Disagreement 3 — whether any candidate fails the MSRV gate.** gemini states *"None of the
shortlisted candidates failed the mandatory fitness gates concerning MSRV, licensing, or
operating system support."* That is **false and was executed**: `governor` and
`tower_governor` declare no `rust-version` at the release and at `master`, and `axum_gcra`
declares none at all (`F2-rv`, `F6`). gemini reports no crates.io or GitHub figure anywhere
in its report, so its gate table rests on nothing. gemini also cites **RFC 7807**, which the
binding standard's R5.14 (line 1098) forbids: *"RFC 7807 MUST NOT be cited — it is obsoleted
by RFC 9457."* Muse and Opus both apply gate 2 strictly and agree with this decision.

**Disagreement 4 — `Retry-After` in the governor-based crates.** perplexity says
`tower_governor` *"does not explicitly document `Retry-After` computation"* and proposes a
wrapper to add it; a widely repeated claim holds that the crate emits only
`x-ratelimit-after`. Both are **wrong in the same direction**: `src/lib.rs` inserts
`retry-after` at two sites (`D2b`, and at the lines Muse cites, `F1c`, `F1d`). The real defect
is the value: `NotUntil::wait_time_from(now).as_secs()` truncates (`D2a`, `F1a`, `F1b`), and
the compiled probe observed `retry-after: 29` where the true wait is 29.99…s. Because R12.2
(line 1784) makes honouring the header a client MUST, a value below the true wait guarantees a
second refusal. gemini's claim that `axum-governor` *"mathematically generates exact
`Retry-After` headers"*, which revision 1 left unproven, is now **refuted at source**:
`axum-governor` 2.1.0's `src/service.rs:496-497` computes `let delta = wait.as_secs(); let
retry_after = delta.max(1);`, the same truncation floored at 1 (`F3e`, `F3f`). Muse calls
`axum-governor` "the most standards-complete option" because it emits the draft's `RateLimit`
field (confirmed, `F3c`). That is true of its header *set*, but the same file also emits new
`x-ratelimit-*` names (`F3d`), and its `Retry-After` *value* has the defect this design
exists to avoid.

**Disagreement 5 — the `ConnectInfo` 500.** Opus found it and Muse confirms it at the same
source lines (`raw/muse.md:33`; `F1e`–`F1g`). Confirmed twice: in the source,
`PeerIpKeyExtractor::extract` is
`maybe_connect_info(req).ok_or(GovernorError::UnableToExtractKey)` and that error renders
`StatusCode::INTERNAL_SERVER_ERROR` (`D2d`, `D2e`); and in a compiled probe, which returns
500 without `ConnectInfo` and 429 with it. **Found by this synthesis and by no leg:** the
owner's own reference architecture has the same gap — it shows `axum::serve(listener, app)`
at line 333 and contains **zero** occurrences of `ConnectInfo` or `into_make_service`, so its
C11 pick would 500 on every request as the document writes it.

**Disagreement 6 — the crate-count deltas.** Only Opus produced them; Muse names the pulled
crates but gives no count (`raw/muse.md:37`). Reproduced exactly at **+0**, **+37** and
**+49** (`C1`, `C3`, `C4`) once the counting rule is fixed as distinct name-and-version
entries, and now pinned by committed lockfiles. Revision 1's first attempt, counting raw
`cargo tree` lines, produced +0, +73 and +137 and is recorded above so the rule is visible
rather than implied.

**Disagreement 7 — the shipped default, where Muse departs from this decision's
load-bearing move.** Muse's acceptance criteria are *"(B1) off by default — with the setting
unset, unbounded request counts all succeed and no limiter state exists"* and *"(B2) one value
turns it on"* (`raw/muse.md:25`). It recommends a layer *"simply not registered when unset"*
(`:51`) and states *"No `BASELINE-REVIEW:` finding is raised"* (`:47`). **Settled against
Muse, on the binding standard.**
- Muse answers the prompt as written. The prompt predates W2-REST and never mentions it,
  R11.2 or the REST standard, and neither does `raw/muse.md`: zero occurrences of each in
  both files (`r74-citations.sh`, `M0a`, `M0b`).
- W2-REST (`docs/port/OWNER-REVIEW.md:187`) binds the standard to this surface. R11.2 is a
  MUST with no R1.6 switch (`R11.2`, `S3a`, `S3b`). Under R1.7 an off-by-default template is
  therefore conformant only with a recorded, approved exception, which Muse neither records
  nor asks for.
- Once the default moves, py's F323 row no longer describes the Rust template. Muse's
  premise that the design *"preserves exactly"* F323's *"wired, off by default, one variable"*
  (`:47`) fails, and a `BASELINE-REVIEW:` finding is what the process requires in place of a
  silent departure.
- R77 revision 4 had already moved the same way independently (`:948-949`).

Muse's off-by-default mechanism is not discarded: it is the compiled
`install_rate_limit_conditional` form, and it is what declining `BASELINE-REVIEW: F323` would
restore.

**Disagreement 8 — GCRA's parameters, where Muse's arithmetic ties the interval to the
burst.** Muse specifies `emission_interval = period / burst` and `tolerance =
emission_interval · (burst − 1)`, with the policy parsed as one `"<count>/<period>"` string
(`raw/muse.md:138`, `:166`). That is a single-parameter GCRA: the count is both the
sustained rate and the burst. **Settled against Muse, on R8.10 and on an executed
measurement.** R8.10 names sustained rate and burst as two things (line 1397). With the clock
injected, one request per millisecond for ten seconds gives these admissions:

| Policy | Emission interval | Admitted in 10 s | What it means |
|---|---|---:|---|
| Two parameters: 10/second, burst 20 (the shipped posture) | 100 ms | **120** | a burst of 20, then 10 per second |
| Single parameter, `"10/second"` | 100 ms | **110** | a burst of only 10 |
| Single parameter, `"20/second"` | 50 ms | **220** | the sustained rate doubles to 20 per second |

No single-parameter value gives the shipped posture
(`A rate_and_burst_are_independent_over_simulated_time`). Muse's arithmetic is otherwise
the same as this design's, including the ceiling and floor rule for `Retry-After` and the
parser's rejections.

**Disagreement 9 — the settings shape.** Muse has R77 carry one optional policy variable
plus a capacity: `rate_limit: Option<RateLimitPolicy>` (default `None`) and
`rate_limit_capacity: usize` (`raw/muse.md:295`). It argues that the policy must be one
string because *"F323 records that **one** variable enables the capability"* (`:179`, `:250`).
**Settled against Muse by R77 revision 4 and by Disagreements 7 and 8.**
- R77 withdrew the single scalar and reserved the family `RSLBP_WEB_RATE_LIMIT_*`, whose
  membership R74 fixes (`:935-956`).
- With no off switch, "one variable enables it" has nothing left to enable.
- The burst needs its own member, because the sustained-rate string cannot carry it.

Muse's grammar for the per-IP member (py's `limits` notation) and its capacity default
(65,536) are adopted unchanged.

**Where Muse adds evidence that this decision adopts.**
- `tower-resilience-ratelimiter` 0.13.0 is a candidate revision 1 did not tabulate. Muse
  excludes it on fit, and that is confirmed at source (`F4a`, `F4b`, `D-rv`); it now has a
  row in the crate table.
- Muse's named adopters of `governor` and `tower_governor` are confirmed in the 2026-09-27
  dependents pages (`F3-adopter`), with minor version drift (for example `alloy-transport`
  2.5.0 where Muse gives 2.4.2). They show `governor` is a real, adopted engine; it is
  excluded on the gate, not on adoption.
- py's limiter sits outside CORS, and that is confirmed at the pin. It is handed to R75 as
  observation (4).
- Muse leaves the `tracing` declaration for the warn-once to R58 (`:116`). That agrees with
  this decision's conditional line.

**Not verified, and carried as Muse's own claims:**
- `loco-rs`'s `MiddlewareLayer::is_enabled` with `enable: bool` fields defaulting to `false`
  (`:19`). This synthesis did not read loco's source, and the claim bears only on the LOW
  question, which does not turn on it.
- The `dashmap` advisory RUSTSEC-2022-0002 being patched in 5.1.0 or later (`:209`). No crate
  is added, so it bears on nothing here.

Muse executed nothing (its gap G2, `:337`); every behavioural claim of Muse's that this
decision relies on was executed here.

**Corrections this synthesis makes to the Opus report, beyond the disagreements.**
(a) Its `- assumes web-extra-surface` line quotes `docs/port/PARAMETERS.md`'s
**revision-9** value while its file paths are written against R69 revision 10's `crates/web`
layout. This decision carries no such line, because the prompt consumes no parameter, and
states the two values' divergence in `## Parameters`.

(b) Its owner-reference row for line 114 says rate limiting is "placed within the tower-http
order". It is not: line 114's chain is ten named `tower-http` layers, and rate limiting
appears in the *following sentence* with no position given. The document is **silent** on
placement rather than prescriptive.

(c) Its tally of the eight touched rows as "3 differ / 3 agree / 2 hand-offs" is a defensible
split only if C4 is counted as a hand-off. Re-checking each row gives:
- **3 differ:** C11 line 70, the shared core list line 31, and the manifest line 185.
- **4 agree:** the reuse-one-limiter gotcha line 415, the C4 error contract line 54, the C12
  test idiom line 72, and `tower = "0.5"` line 140.
- **1 pure hand-off:** the layer-order note line 114.

C4 is double-classified as agree-and-hand-off. Muse's row-by-row classification
(`raw/muse.md:45`) agrees with this one.

(d) Its hand-off of two counter names to R79 is stale. R79 revision 3 ships *"Two
instruments, not three"* and still describes this item as *"opt-in rate limiting"*, a
characterization this decision makes obsolete.

(e) Its rejection of fixed window is wrong for the reason given in Disagreement 2, though its
conclusion stands.

(f) It reports slowapi's rounding as unverified. This synthesis, and Muse (its gap G4),
confirm that, and it is carried unchanged.

**Where the legs agree, which is worth recording.** All five reports independently reach the
same four structural conclusions:
- rate limiting must be a runtime decision rather than a Cargo feature, because a
  compile-time gate would require two binaries;
- the store must sit behind a swap seam rather than a comment;
- the 429 must render through the item's single error envelope rather than a second ad-hoc
  body;
- `tower::limit::RateLimitLayer` is the wrong shape, because it delays rather than refuses.

Nothing in this decision departs from any of those.

**Sources.**
- **Standards:**
  - the org REST API Design Standard v2.0.0 at the pin above, cited by rule and line
    throughout and asserted by `r74-rest-conformance.sh`;
  - RFC 9110 §10.2.3 (`https://www.rfc-editor.org/rfc/rfc9110.txt`, 2026-09-18) for
    `Retry-After = HTTP-date / delay-seconds`, `delay-seconds = 1*DIGIT`, *"a non-negative
    decimal integer"*;
  - RFC 6585 §4 (`https://www.rfc-editor.org/rfc/rfc6585.txt`, 2026-09-18) for 429, whose
    `Retry-After` MAY the org standard deliberately tightens to a MUST;
  - `draft-ietf-httpapi-ratelimit-headers-11`, 23 May 2026
    (`https://www.ietf.org/archive/id/draft-ietf-httpapi-ratelimit-headers-11.txt`,
    2026-09-18) — an unpublished Internet-Draft, cited by its pinned revision and never
    described as a standard.
- **Registry, repository and advisory figures:** the crates.io crate, versions and
  reverse-dependencies endpoints, the GitHub REST repos, search/issues and contents
  endpoints, `https://rustsec.org/packages/<name>.html`, and
  `https://static.rust-lang.org/dist/channel-rust-stable.toml`. All were retrieved
  2026-09-27T06:26–06:30Z and snapshotted under `review/evidence/snapshots-r2/`, with
  `MANIFEST.tsv` naming each endpoint. Revision 1's 2026-09-19 set under `snapshots/` is the
  drift baseline.
- **Crate source, read not recalled** — each crate's source as `cargo fetch` unpacks it under
  `${CARGO_HOME}/registry/src/index.crates.io-1949cf8c6b5b557f/`, all read 2026-09-27:
  - `tower_governor-0.8.0/{Cargo.toml,src/lib.rs,src/errors.rs,src/key_extractor.rs}`;
  - `governor-0.10.4/Cargo.toml` and `gcra-0.6.0/Cargo.toml`;
  - `axum-governor-2.1.0/{Cargo.toml,src/headers.rs,src/service.rs}`;
  - `axum-0.8.9/Cargo.toml` and `tower-0.5.3/Cargo.toml`;
  - `tower-rate-limiter-0.1.6/{Cargo.toml,src/limiter/store.rs,src/limiter/response.rs}`;
  - `tower-resilience-ratelimiter-0.13.0/{Cargo.toml,src/error.rs,src/lib.rs}`.
- **Source repository at the pin:**
  `git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/web/app.py` lines
  120–150, read directly this session. ts contributes nothing
  (`docs/port/areas/web-service.md:7`).
- **Programme documents:**
  - `docs/port/COMMONALITY.md` rows F316 (line 320), F317 (321) and F323 (327);
  - `docs/port/areas/web-service.md` rows F316 (22), F317 (23) and F323 (29);
  - `docs/port/BASELINE-REVIEW.md`, which carries **no** row in the F313–F328 band, because it
    adjudicates `COMMON → REUSE` and `ADOPT` rows and these three are `DIVERGENT`;
  - `docs/port/README.md` lines 61–73 for the verdict vocabulary;
  - `docs/port/OWNER-REVIEW.md` line 187 for W2-REST;
  - `docs/port/OWNER-ACCEPTANCES.md` lines 60, 71 and 75;
  - `docs/planning/p02/owner-decisions.md` §11 (lines 401–432, the standing-input ruling naming
    R72–R76 in its overlap set) and lines 452–462 (the settled strict gate-2 reading);
  - `research/RUNBOOK.md` lines 70–76;
  - `inputs/owner-reference-axum-companion-stack-2026-09-16.md` lines 31, 54, 70, 72, 114,
    140, 185, 333, 415 and 431;
  - `docs/port/PARAMETERS.md` line 17.
- **Other items' decisions:**
  - `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` (revision 10) lines
    1106, 1492, 1494–1497, 1787, 1791 and 2268–2276;
  - `research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md` (revision 4) lines
    291, 296, 759, 935–957;
  - `research/runs/R70/2026-09-17T034010Z-31ad2ef28df7/review/DECISION.md` (revision 4) lines
    76, 77, 181, 187, 231, 343–345 and 552–557;
  - `research/runs/R79/2026-09-17T034011Z-2e1043da0e00/review/DECISION.md` (revision 3) lines
    178, 341–344, 570–571 and 688;
  - `research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md` (revision 3) lines
    760–761;
  - `research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/DECISION.md` (revision 2) lines
    30–33, 58 and 981–985;
  - `research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md` (revision 2) lines
    23–29;
  - `research/topics/67-error-and-exit-code-contract/DECISION.md` line 383;
  - `research/topics/01-ports-and-adapters-seam/DECISION.md` line 138;
  - `research/CLAUDE.md` line 79.
