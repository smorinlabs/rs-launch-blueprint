# 2026-09-18 — R73 — idempotency-middleware (bundle, Deep) — decision (revision 1)

## Decision

**`rs-launch-blueprint` adopts `idempotency-replay/v1`: a hand-written
`axum::middleware::from_fn_with_state` layer in `crates/web/src/idempotency.rs`
over an `IdempotencyStore` driven port in `crates/core` whose contract is a
compare-and-set — `begin` / `complete` / `abandon`, returning
`Begin::{Fresh, InFlight, Replay(CachedResponse), Completed, Mismatch}` — with a
`std`-only `InMemoryIdempotencyStore` production adapter (one
`std::sync::Mutex<HashMap<CacheKey, Slot>>`, lazy per-entry expiry,
least-recently-used eviction at `max_entries`, a separate and much shorter
in-flight deadline, an injected `Clock`) constructed at the root package's
composition root and erased to `Arc<dyn IdempotencyStore>`, plus `sha2` 0.11.0
(`default-features = false, features = ["alloc"]`) supplying the SHA-256
request-payload fingerprint. Cache key `(method, path, query, idempotency-key)`;
the payload fingerprint is stored beside the entry and compared, never folded
into the key; only a 2xx completes an entry; replays carry
`Idempotency-Replayed: ?1`; 400 / 409 / 413 / 422 / 503 as the org REST API
Design Standard assigns them, bodied by R70's envelope. No crate is adopted for
the middleware and none for the store.**

**Ledger rows settled: F313, F314, F315** (`docs/port/COMMONALITY.md:317-319`,
all three `py-only` · `DIVERGENT` · R73). py's pattern is preserved in each. The
verdict glyph each row carries is the publisher's to write; nothing here edits
the ledger.

**This is a proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what the research found and what it recommends; P03
builds the template and its CI proves the recommendation. What P03 must validate
is listed under `## Engines`. A decision that does not survive implementation is
revised against this recorded research, not researched again from scratch.

**One stack — three members, one crate.**

| # | Member | What it is | Version |
|---|---|---|---|
| M1 | Replay layer | `axum::middleware::from_fn_with_state` in `crates/web/src/idempotency.rs` | template code; `axum` 0.8.9 is R69's pin, no new crate |
| M2 | Store port and in-memory adapter | `trait IdempotencyStore` in `crates/core`; `InMemoryIdempotencyStore` at the composition root; `AlwaysFreshStore` fake | template code, `std` only, **0** crates |
| M3 | Request-payload fingerprint | SHA-256 over the buffered request body | `sha2` **0.11.0**, `default-features = false`, `features = ["alloc"]`, **+8** crates |

### Principles and implementation

**The shared requirement.** A client that cannot tell whether its unsafe request
took effect must be able to repeat it without repeating the effect, and must be
able to tell "your first attempt already succeeded, here is its result" from
"your first attempt is still running" from "you reused a key for a different
operation" from "that failed, retry it for real".

**Source, agreement level, and what may vary.**

| Clause | Source | Agreement level | Must agree | May vary |
|---|---|---|---|---|
| Unsafe-method retries carry a client-generated key and replay the first outcome (F313) | py `src/py_launch_blueprint/web/idempotency.py:43,45` at pin `b08bccfb` (checks `S3-header`, `S3-methods`); org standard R3.9 (`rest-api-standard.md:651`) | **standard** — the org standard binds it | that a keyed retry does not re-execute | nothing in the header spelling; the layer-versus-handler placement and the store shape vary |
| Only outcomes safe to replay are stored (F314) | py `:141` (check `S3-2xx`) | **policy** | that a failure a client can usefully retry is not pinned for the key's lifetime | which statuses qualify; allow-list versus deny-list |
| The store is in-memory, single-instance, and documented as a swap point (F315) | py `:26-30,91` | **architectural pattern** | that the store sits behind a named seam so the swap is an adapter change | the data structure entirely |
| Key validation, payload fingerprint, concurrency statuses | org standard R3.9 (`:651-655`), R5.3 (`:939-942`) | **standard** | 400 / 409 / 422 as R5.3 assigns them | the fingerprint algorithm; how in-flight state is represented |

**The binding standard, and what changed because of it.** Owner ruling W2-REST
(2026-09-18) makes the org REST API Design Standard v2.0.0 binding on this
template's HTTP surface — `/Users/stevemorin/c/rest-standards/rest-api-standard.md`,
commit `0850d43e45d919ef5e37f7174c4212b46013c49f`, blob
`71bd813c1cf61286586b4ee41ed83ff065e5c8d9`, identity asserted by checks
`C0-commit`, `C0-blob`, `C0-bind`, `C0-version`. Its §3.4 is directly on point.
Every rule below was read at its line out of that blob and asserted by a check
that fails if the line moves, so a later revision of the standard cannot
silently invalidate a citation.

The rule that reorders the evidence is the one the raw reports did not have.
`rest-api-standard.md:347` reserves `Idempotency-Key` and states, of the IETF
draft this whole field cites: **"the IETF draft that standardized this shape
expired 2026-04-18; never cite it as a standard"** (check `C1-draft`), and §3.4
repeats it at `:673-675` (`C3-policy`, `C3-expired`, `C3-redact`). The Opus raw
derives its 400 / 409 / 422 assignments from draft-07 §2.7. **This decision does
not.** It derives them from R5.3 at `:939-942`, which reaches the same three
independently: 422 for "semantically invalid but well-formed requests", 409 for
"conflicts with current resource state", 400 for "malformed syntax" (checks
`C6-R5.3a`, `C6-R5.3b`, `C6-R5.3c`). The draft is retained as *evidence* that
the field converges on the same assignments — it does, at its `:311` and `:342`
(checks `S2-422`, `S2-409`) — and is never the authority. 413 comes from
RFC 9110's registered semantics through R5.2, which forbids anything
unregistered (`:934`, check `C6-R5.2`).

**Rule-by-rule conformance of `idempotency-replay/v1`.** Every row is a verdict,
not a summary.

| Rule | Line | What it requires | Verdict |
|---|---|---|---|
| R3.9 — accept a key | `:651` | MUST accept an idempotency key on non-idempotent state-changing requests | **CONFORMS.** `POST`, `PUT`, `PATCH` are in scope (`S3-methods`, `w06` proves `GET` passes through). The header is honoured when present; R3.9 says *accept*, not *require*. Requiring it on a named route is R71's documentation decision |
| R3.9 — header spelling | `:652` | carried in the `Idempotency-Key` request header | **CONFORMS.** Exactly that name (`C3-R3.9b`); it is also py's (`S3-header`) |
| R3.9 — fingerprint | `:653` | the server fingerprints the request payload | **CONFORMS.** SHA-256 over the buffered body, member M3 (`w03`) |
| R3.9 — replay | `:654` | replays the stored response for a genuine retry | **CONFORMS.** `w01` proves a byte-for-byte replay with the handler run once |
| R3.9 — reject mismatch | `:655` | rejects a reused key carrying a different payload | **CONFORMS.** 422 (`w03`, `s02`) |
| R3.9 — PUT exception | `:655-659` | naturally idempotent operations are exempt | **CONFORMS as a permitted superset.** The exception is a relaxation, so including `PUT` is legal (`C8-put`). py includes it; kept |
| R3.9 — retention floor | `:668-670` | the stated retention window MUST be at least 24 hours | **`OVERRIDE (OV-16)` below.** The stated window is 86,400 s, which meets the floor (`C8-retention`); the shipped single-instance store cannot guarantee it |
| §3.4 — streaming clause | `:671-673` | for a streaming request, "the stored response" means the terminal state | **N/A with reason.** The `streaming` applicability switch (§1.8, R1.6 at `:229`) is declared **off**: this template's web surface ships no streaming endpoint (R69's accepted surface lists none). Recorded per R1.6's N/A-with-reason discipline, which makes a bare "N/A" a deviation |
| §3.4 — draft citation ban | `:673-675` | the draft MUST NOT be cited as a standard | **CONFORMS.** The statuses are derived from R5.3; the draft is cited only as evidence, and always with its expiry (`S2-expiry`) |
| §3.4 — key redaction | `:675-677` | deployments needing keys out of intermediary logs MUST add header-redaction | **Handed to R75** as a constraint: `Idempotency-Key` belongs in `SetSensitiveHeadersLayer`'s set |
| R3.12.4 — dry-run | `:728` | a dry-run MUST NOT consume an `Idempotency-Key` | **CONFORMS, and this is a change from the raw.** The layer suppresses the claim when the reserved `dry_run` parameter (§1.10, `:335`; R1.9 at `:318`) is present. `w17` proves two dry-run calls neither replay nor conflict, and that the key is still free for the real call |
| R4.12 — structured fields | `:880` | new header fields SHOULD use RFC 9651 structured field types | **MOVED TO CONFORM.** py emits `Idempotency-Replayed: true` (`S3-replayed`), which is not an RFC 9651 Boolean. This decision emits **`?1`**. R4.12's exception covers a field that must match existing deployed syntax; a greenfield template has none, so the SHOULD binds and the cost of honouring it is one byte-string |
| R5.1 — status matches outcome | `:916-918` | a failed operation MUST NOT return 2xx | **CONFORMS.** Only a 2xx completes an entry, so no failure is ever stored as a replayable success (`w02`, `w13`) |
| R5.2 — registered statuses | `:934` | unregistered status codes MUST NOT be used | **CONFORMS.** 400, 409, 413, 422, 503 are all registered |
| R5.3 — 400 / 409 / 422 | `:939-942` | the three assignments | **CONFORMS.** 400 malformed key (`w10`), 409 in-flight or completed-unreplayable (`w11`, `w09`), 422 fingerprint mismatch (`w03`) |
| R5.6 — create carries Location | `:967` | a create MUST return 201 with `Location` | **CONFORMS, and the replay preserves it.** The entry stores raw header pairs, so `Location` survives; `w01` asserts the replayed `Location` equals the first response's |
| R5.12 / R5.13 — problem documents | `:1020`, `:1049` | error bodies are RFC 9457 problem documents with a required member set | **Deferred to R70** and flagged — see the coupling note below |
| R11.6 — document retryable classes | `:1743` | MUST document which failure classes are retryable | **CONFORMS.** The 2xx-only rule is exactly this documentation: every non-2xx this layer returns or forwards is retryable with the same key |
| R11.7 — `request-id` on every response | `:1752` | every response MUST carry the correlation header | **DEFECT FOUND AND FIXED.** The raw design replays the stored header list verbatim, which would replay the *first* request's `request-id` and `traceparent`. The adapter excludes correlation headers from the cached entry, so the live outer layer supplies them. `w16` proves the handler emits `request-id` and the replay does not carry the stale one |
| R1.8 — reservation discipline | `:312` | a reserved name keeps its registered meaning | **CONFORMS.** `Idempotency-Key` is used for exactly its registered meaning; `Idempotency-Replayed` is not a reserved name and no reserved synonym exists for it |
| R4.17 — CORS exposure | `:868` | standard-bound response headers MUST be listed in `Access-Control-Expose-Headers` | **Handed to R76** as a constraint: `Idempotency-Replayed` must appear there |

**`OVERRIDE (OV-16)` — a bounded, process-local store against R3.9's 24-hour
retention floor (F315).**

**Argument:** R3.9 at `rest-api-standard.md:668-670` states "The stated
retention window MUST be at least 24 hours." The recommended entry TTL is
86,400 s, so the *stated* window meets the floor exactly, and check
`C8-retention` asserts the floor's text. What the shipped adapter cannot do is
honour that statement under two conditions the design accepts by construction:
`max_entries` is 1,024, so the 1,025th distinct key evicts the
least-recently-used entry before its TTL expires (`s06` executes exactly that
eviction); and the store is process-local, so a restart loses every entry. F315
makes both deliberate — "in-memory, single-instance by design" is the ledger
row, and py's own module documentation frames the store as a Redis swap point
(`S3-singleflight` quotes the adjacent admission). Under R1.7 at `:271`,
"silent deviation from any rule strength is nonconformance regardless of the
deviation's merits", so the gap is recorded here in writing rather than left to
be discovered. It is a genuine gap, not a technicality: a client retrying after
23 hours on a busy instance may find its key evicted and its request
re-executed.

**Options:**

1. **Record the deviation and ship the bounded store (recommended).** Cost: the
   conformance note carries an R3.9 deviation for as long as the template runs
   single-instance; a retry after eviction or restart re-executes. Benefit:
   F315 is preserved exactly, zero crates, and the swap point is the documented
   remedy. The deviation disappears the day a distributed adapter lands, with no
   change to the layer or the port.
2. **Raise `max_entries` until eviction-before-TTL is improbable.** Cost: turns
   a bounded store into an unbounded one in practice — 24 hours of keys at any
   real rate is a memory-exhaustion surface, which is the failure R11.1's
   published-limits rule exists to prevent. Does nothing about restart. Does not
   remove the deviation, only makes it rarer and harder to reason about.
3. **Ship a durable adapter now (file-backed or Redis) so the floor is met.**
   Cost: contradicts F315 head-on, adds the dependency the prompt's own scope
   note excludes, and requires `spawn_blocking` at the call site because the
   critical section would perform I/O. Benefit: full conformance.
4. **Narrow the stated window to what the store can honour.** Cost: not
   available — R3.9's floor is a MUST at 24 hours, so stating less is a deeper
   deviation, not a smaller one.

**Recommendation: option 1**, with the deviation recorded in the API's
conformance note in the shape R1.7's template fixes at `:280-297`, and
`max_entries` and the TTL exposed as the environment knobs R77 names so an
operator can trade memory for retention knowingly.

**F314, and why no `BASELINE-REVIEW:` line appears in this decision.** The Opus
raw raises `BASELINE-REVIEW: F314` and the OpenAI Doxa leg raises one on the
same row proposing the opposite behaviour. **Neither label is legal, and the
disposition is to carry the finding without it.** `research/RUNBOOK.md:18-22`
scopes the process to the P02-T01 review of "every REUSE and ADOPT baseline";
F314 is this item's own `py-only` · `DIVERGENT` row
(`docs/port/COMMONALITY.md:318`), so a finding about it is the answer itself,
not a challenge to a settled baseline. R67 recorded exactly this trap and
refused to carry seven such lines
(`research/topics/67-error-and-exit-code-contract/DECISION.md:683-689`), and
R70 revision 1 declined on the identical ground for F305 and F306. Filing the
finding under a review label would ask the controller to adjudicate a row this
item already owns.

**The finding itself is correct and is carried here as F314's reasoning.** The
ledger row's parenthetical — "(Stripe semantics: errors are meant to be retried
for real, not replayed)" — is factually wrong about Stripe, and so is the py
comment it derives from at `idempotency.py:140` (`S3-stripe-comment`). Read at
source (`https://docs.stripe.com/api/idempotent_requests`, retrieved
2026-09-19): **"Stripe's idempotency works by saving the resulting status code
and body of the first request made for any given idempotency key, regardless of
whether it succeeds or fails"** (check `S1-replay-errors`). The expired draft
agrees, at its line 262: **"completed operation, success or an error"**
(`S2-replay`). So the 2xx-only rule is supported by *neither* authority the row
names, and two of the three Doxa providers assert the opposite of what Stripe
documents without quoting it. **Correcting the row's Notes is the controller's,
not this decision's** — this item may not edit the ledger — and it is requested
under `## Engines`.

**The behaviour survives the correction, on a ground a layer can actually
hold.** Stripe replays failures because its idempotency layer sits *inside* its
request lifecycle and knows whether endpoint execution began; its own page says
so: **"We save results only after the execution of an endpoint begins"**
(`S1-execution-gate`). A generic layer wrapping `next.run(req)` has no such
knowledge — it cannot separate a deterministic 500 from a transient one. Under
the recommended 86,400 s TTL, replaying 5xx would pin a transient failure for
24 hours and leave the client no way to make progress. R11.6 at `:1743` makes
the API document which failure classes are retryable, and "every non-2xx is
retryable with the same key" is a rule this layer can honour and state. **What
changed is the argument, not the code** — and that is also why the OpenAI leg's
`CompletedOutcome` proposal is declined: it needs the execution-started signal
that Stripe has and a `from_fn` layer does not.

**Architectural alternatives compared before any library was chosen.**

| Alternative | What it is | Verdict |
|---|---|---|
| **A1 — layer over a driven store port (recommended)** | an axum middleware function; the port is a `crates/core` trait; the shipped adapter is in-memory | **Chosen.** The replay decision lives in one place and covers every unsafe route with no per-handler code, and the swap point is a trait, so a distributed store is a new adapter rather than a middleware rewrite. Costs: the request body must be buffered to fingerprint it, and the layer cannot see whether the handler's side effect committed |
| **A2 — in-handler call (Zero To Production's shape)** | `try_processing(...)` at the top of each handler, the transaction carried into the write | **Rejected for this template, adopted in spirit.** It is *better* where a database exists, because the idempotency row and the side effect commit in one transaction — atomicity no layer can offer. This template has no database, so the exchange buys nothing and costs per-handler boilerplate plus a per-handler chance to forget. Its `NextAction` enum is adopted as the port's return type |
| **A3 — an extractor** | an axum extractor yielding a claimed key | **Rejected.** An extractor runs before the handler and cannot see the response, so the store-write half has nowhere to live |
| **A4 — a hand-written `tower::Layer`/`Service` pair** | implement `Layer` and `Service` explicitly | **Rejected on cost, not correctness.** It requires naming `tower` as a dependency, which R69's accepted revision 10 declines, and replaces one readable `async fn` with a manual `Poll::Ready` state machine. `from_fn_with_state` returns a genuine `tower::Layer` without the dependency line — executed: `cargo tree -e normal -i tower` shows the only edge is `tower v0.5.3 ← axum v0.8.9` (check `P2-tower-edge`) |
| **A5 — adopt `cratestack-axum` 0.12.0** | the best-adopted published implementation | **Rejected by gate 2 and on fit** — see *Dominant choice* below |
| **A6 — adopt `axum-idempotent` 0.3.0** | the only idempotency-dedicated crate with any adoption | **Rejected on fit** — see below |

**Dominant choice, corrected against the Opus leg.** The Opus raw states that
**"No published Rust crate implements `Idempotency-Key` request replay for a
leading async web framework in a form this template could adopt"** and rates
that claim *Medium* confidence because "crates.io search is keyword-based and a
crate published under a name none of six queries matched would be missed". **The
hedge fires: one was missed.** `cratestack-axum` **0.12.0** ships a complete
idempotency implementation — `src/idempotency/{layer,service,store,parse,headers,responses,complete,finish,stream_bypass}.rs`
plus its own op-resolvers and tests (checks `S4-cs-module`, `S4-cs-store`) — and
it is not a curiosity: **14,687** 90-day downloads and **15,173** all-time
against `axum-idempotent`'s **230** and **6,911**
(`GET https://crates.io/api/v1/crates/<name>`, `crate.recent_downloads`,
`crate.downloads`, retrieved **2026-09-19**; checks `E4-cratestack-exists`,
`E4-cratestack-adoption`). It converges on this decision's contract
independently — a `ReservationOutcome` compare-and-set, a payload hash beside
the key, 409 / 422 / 413, full header persistence with an in-source note that
persisting only `Content-Type` made a replayed `201 Created` lose its
`Location` — which is strong corroboration that the shape here is the field's
shape and not this template's invention.

**It is excluded by gate 2, on a fact rather than a preference:** its published
manifest declares **`rust-version = "1.98.0"`** (check `S4-cs-msrv`), above this
template's floor of **1.96** — stable **1.98.1** minus two minors,
`https://static.rust-lang.org/dist/channel-rust-stable.toml`. A dependency
declaring 1.98.0 raises the whole tree's floor above the `msrv-policy` value, so
the policy's "declared as rust-version in Cargo.toml and tested in CI" clause
cannot be satisfied. It is excluded **again on fit**, independently: it is a
schema-first API framework whose idempotency store is a SQL table
(`IDEMPOTENCY_TABLE_DDL`, re-exported from `cratestack-sql`), pulling
`cratestack-core`, `-exec`, `-sql`, `-codec-cbor`, `-codec-json`, `minicbor`,
`erased-serde`, `uuid`, `url` and `ipnet` — adopting it means adopting the
framework, and the template has no database for its store to use. Its `unsafe`
posture is `unsafe_code = "forbid"` (`S4-cs-forbid`), and
`https://rustsec.org/packages/cratestack-axum.html` returns 404 against a 200
control (`E5-control`). **So the honest answer to the HIGH question is not "no
crate exists" but "one does, and two independent gates exclude it".**

`axum-idempotent` 0.3.0 fails on fit for reasons the Opus raw states correctly
and this run re-verified at source: its README requires a session layer —
**"This middleware requires a session layer, such as `SessionLayer` from the
[ruts] crate. For the `IdempotentLayer` to access the session, it must be placed
*inside* the `SessionLayer`"** (check `S5-ai-session`) — so adopting it means
adopting sessions and cookies, two capabilities
`docs/planning/p02/owner-decisions.md` §11 records as not decided and not
researched. Measured transitive cost: an `axum 0.8.9 + tokio 1.53.1` workspace
is **51** packages; adding `axum-idempotent 0.3.0 + ruts 0.10.1 +
tower-cookies 0.11.0` takes it to **88**, **+37** (check `P6-axumidem`), against
the recommendation's **+8**.

**The recommended design, clause by clause.**

1. **Scope.** `POST`, `PUT`, `PATCH`; every other method passes through
   untouched even carrying the header (`w06`). Wider than RFC 9110 §9.2.2's
   idempotent set, which R3.9's exception permits (`C8-put`).
2. **The header is opt-in.** No key means no caching (`w05`).
3. **Key validation first.** Non-empty, at most **255** bytes — Stripe's
   published ceiling, read at source (`S1-key-length`) — visible ASCII, single
   value. A violation is **400** and the handler never runs (`w10`).
4. **Cache key `(method, path, query, idempotency-key)`** — py's `_CacheKey`
   shape including the query string, whose presence py justifies in a comment at
   `:101` (`S3-query`) and whose absence would let `/things?a=1` replay
   `/things?a=2` (`w04`, `s07`).
5. **The body is not part of the key; it is a fingerprint stored beside the
   entry.** Folding a body hash into the key looks safer and is the opposite: a
   client retrying with a re-serialized body would produce a different key and
   **re-execute the side effect**. R3.9 at `:653-655` puts the fingerprint
   beside the key and makes the mismatch a rejection, not a new operation
   (`w03`, `s02`).
6. **The port is a compare-and-set, never a get-then-insert.** `Fresh` *claims*
   the key; the claim is the in-flight marker. This closes the hole py documents
   and leaves open — "Concurrent duplicates … are NOT single-flighted"
   (`S3-singleflight`) — because a `std::sync::Mutex` makes check-and-set atomic
   within one process for free, and this template is single-instance by design.
   A Redis adapter implements `begin` with `SET key … NX`, a Postgres adapter
   with `INSERT … ON CONFLICT DO NOTHING`; neither needs a different layer.
7. **`InFlight` → 409, `Mismatch` → 422**, per R5.3 (`w11`, `w03`).
8. **Only a 2xx completes an entry; every other outcome abandons the claim**,
   including a dropped future, which an `AbandonOnDrop` guard covers, and a
   process-level stall, which the separate shorter in-flight deadline covers
   (`s05`). Without both, one panicking request pins a key for the whole TTL
   (`w13` proves a failure does not leave a stale claim).
9. **Bounded on both sides.** An oversize request body with a key is **413**
   before the handler runs, because `axum::body::to_bytes` consumes the body on
   overflow so forwarding is not an option (`w08`).
10. **An unknown-length or oversize 2xx records a completed-but-unreplayable
    marker and answers retries 409.** This is a **change from the Opus raw**,
    which streamed such a response through uncached, released the claim, and
    left the retry to re-execute the side effect — a hole its own *Tradeoffs*
    names as "the sharpest one" and hands to P03 as an open choice. Under R3.9
    at `:651-655` non-re-execution is the guarantee, so leaving it open is
    nonconformance, not a preference. The body still reaches the client whole
    (`w09` asserts `alphabeta`, `w09b` asserts 4,096 bytes) and the side effect
    happens exactly once.
11. **Replays carry `Idempotency-Replayed: ?1`**, appended to a fresh copy of
    the stored header list so the marker never stacks across replays — py's
    `:115-121` bug-avoidance, kept and tested over three consecutive replays
    (`w07`).
12. **Correlation headers are never stored.** `request-id`, `traceparent` and
    `tracestate` are excluded from the cached entry so a replay carries the live
    request's identity, per R11.7 and R11.8 (`w16`).
13. **A poisoned lock is `PortError::Unavailable`, surfaced as 503**, per R03
    rule 5's catalogue row, never a panic (`s10`, `w15`).
14. **Not built, and documented as such**: no distributed store, no
    cross-instance single-flight, and no principal in the key. The third is a
    security swap-point note: the draft's §5 warns that low-entropy keys let an
    attacker read other clients' cached entries and prescribes a composite key
    including client-specific attributes, which Zero To Production does with
    `user_id`. This template has no authentication, so there is no principal to
    add; the requirement is recorded so whoever adds authentication adds it to
    the key in the same change.

**R01, R02, R03, R05 reconciliation, checked rather than assumed.** The port is
`Send + Sync`, has no `async fn`, no generic methods, no associated consts and
no non-receiver `Self`, carries a blanket `impl<T: IdempotencyStore + ?Sized>
IdempotencyStore for Arc<T>`, and is erased to `Arc<dyn IdempotencyStore>` at
the composition root — R01's registered `http-transport-injection-seam` clause
for clause, executed by check `s09`. R02 revision 1's four-package workspace
places the port in `crates/core`, the layer in `crates/web` and the adapter at
the composition root. R03's rule 1 (`Result<Option<T>, PortError>`) governs a
read addressing one resource by identity; `begin` is a write that claims a key
and all four of its outcomes are *success*, so collapsing them to `Option` would
destroy the "not present" versus "present but claimed" distinction the 409
exists for — R03's own *Ranked runner-up* scopes rule 1 to reads for that
reason. Rule 2's `PortError` shape is followed exactly, with no `NotFound`
variant. R05's synchronous core holds: the store port is a synchronous `fn` and
the nine store checks run under plain `#[test]` with no runtime in scope (check
`P3-sync`). Whether the *call site* needs `spawn_blocking` is decided by
measurement, and at a sub-microsecond hit the shipped adapter is called inline,
on the tokio maintainers' own published advice; a future Redis or file-backed
adapter, whose critical section performs I/O, **must** go through
`spawn_blocking`, which is R05's rule applied rather than contradicted. None of
these needs a registered value changed, so no `CONFLICT:` line is raised.

**Owner-reference reconciliation** (`inputs/owner-reference-axum-companion-stack-2026-09-16.md`,
a standing input under `docs/planning/p02/owner-decisions.md` §11 — binding on
process, not outcome). The document contains **no idempotency row**: not in the
stack table, not in C11's middleware order, not in the reference `Cargo.toml`.
That absence is the first row of the tally, because C11 enumerates ten layers
and this is an eleventh. The Opus raw's tally is **agree 3 / extend 1 /
differ 2 / no position 2 / inapplicable 1**, and each was re-checked here:
*Level One*'s "Dropped as unnecessary: a dedicated in-process cache crate" —
**agree**, and now measured rather than argued (moka **+14**, mini-moka **+11**,
quick_cache **+9**, lru **+5**, hashlink **+3**, checks `P6-moka` through
`P6-hashlink`); tower-http's layer set is enough for its listed concerns —
**agree and extend**, since it ships no idempotency layer; C11's layer order —
**extend, contradict nothing**, with the constraints handed to R75 below;
C11's `tower_governor` — **no position**, R74's; C4's hand-rolled `AppError` —
**agree**, and it lands twice, because every status here is bodied by R70 and
because the draft's examples still cite RFC 7807, which R5.14 at `:1098` bans
(`C9-control`); C12's `axum-test` — **differ**, on the ground R69 revision 10
already recorded in selecting `tower::ServiceExt::oneshot`, which all 18 router
checks ran on; C13's single-crate layout — **differ**, on R02 revision 1's
ground; C9's `figment` — **no position**, R77's; C5/C6/C8's database, sessions
and background jobs — **inapplicable, and decisive**, since their absence is
exactly why `axum-idempotent` and `cratestack-axum` do not fit. The tally holds
unchanged.

**Observable acceptance criteria.** Twenty-eight were **executed** in this
synthesis against a re-derived probe under `$TMPDIR` on R69 revision 10's exact
pins; all 28 passed, `cargo clippy --all-targets -- -D warnings` is clean, and
the crate carries `#![forbid(unsafe_code)]`. Criteria marked *proposed* are
requirements on a template that does not exist yet and are not results.

| # | Criterion | Status |
|---|---|---|
| 1 | A second `POST` with the same key returns the first response byte-for-byte with `idempotency-replayed: ?1`, `Location` preserved, handler run once | **Executed** (`w01`) |
| 2 | A 500 is not cached; the second attempt re-executes and carries no replay marker | **Executed** (`w02`) |
| 3 | The same key with a different body is 422 and the handler does not run | **Executed** (`w03`) |
| 4 | The same key against a different query string executes independently | **Executed** (`w04`) |
| 5 | No key means no caching | **Executed** (`w05`) |
| 6 | A `GET` carrying the header passes through untouched | **Executed** (`w06`) |
| 7 | Two `Set-Cookie` values survive caching and replay; the marker does not stack over three replays | **Executed** (`w07`) |
| 8 | An oversize request body with a key is 413 and the handler never runs | **Executed** (`w08`) |
| 9 | An unknown-length 2xx streams through whole, is not replayed, and its retry is 409 rather than a re-execution | **Executed** (`w09`, `w09b`) |
| 10 | An empty key and a 256-byte key are both 400 before the handler | **Executed** (`w10`) |
| 11 | A duplicate arriving while the first is in flight is 409 and the handler does not run | **Executed** (`w11`) |
| 12 | An entry expires at its TTL and the handler runs again | **Executed** (`w12`) |
| 13 | A non-2xx releases the claim, so the next attempt is not 409 | **Executed** (`w13`) |
| 14 | Two genuinely concurrent live requests at one key execute the handler exactly once, one 2xx and one 409 | **Executed** (`w14`) — the raw report listed this as *not run* |
| 15 | A poisoned store is 503, not a panic | **Executed** (`w15`, `s10`) — the raw report listed this as *not run* |
| 16 | A replay does not carry the first request's `request-id` | **Executed** (`w16`) |
| 17 | A dry-run consumes no key | **Executed** (`w17`) |
| 18 | Store behaviour: claim, mismatch, abandon, TTL boundary at ±1 ms, separate in-flight deadline, LRU-by-use eviction, key scoping, hit-path cost, erased-handle contract | **Executed** (`s01`–`s09`) |
| 19 | The whole layer is absent when the `web` feature is off | *Proposed* — R02 revision 1 executed the equivalent (`B1`/`B2`) |
| 20 | The OpenAPI document names the header, the replay marker and the 400/409/413/422 responses on every unsafe operation | *Proposed* — R71's, handed over below |
| 21 | A `crates/core` test pins the SHA-256 digest of a fixed payload to a literal | *Proposed* — the check that makes the cross-implementation fingerprint contract enforceable; it belongs in the template, not a probe |
| 22 | The same suite on `ubuntu-latest` | *Proposed and unproven* — everything here ran on `aarch64-apple-darwin` |

**Performance, stated with its workload.** Workload: `begin()` on a hit, the hot
path, against a store holding **1,024** entries, single-threaded, 10,000
iterations after a 1,000-iteration warm-up, `aarch64-apple-darwin`,
`rustc 1.98.0 (88d9e12ae 2026-08-18)`. Instrumentation: `std::time::Instant`
around the loop, reported as nanoseconds per operation. Result: **275 ns/op** in
the committed log, and **179–373 ns/op** across seven runs on this machine, the
spread tracking concurrent build load rather than anything in the code. The Opus
raw reports **159 ns/op**. That figure is **not reproduced and is not asserted
equal** — this is a re-derivation, not that workspace — but every observed value
sits three orders of magnitude below one millisecond, which is the only thing
the number is load-bearing for: it decides that the shipped adapter is called
inline rather than through `spawn_blocking`, on the runtime maintainers' own
advice that the ordinary `std` mutex is often preferred in async code when the
guard is not held across an `.await`, which it never is here. **No figure is
claimed for end-to-end request latency or throughput**; nothing in this run
measured that, and inferring it from a microbenchmark is the unlike-benchmark
comparison the prompt forbids.

**Fitness gates.** Gate 1 (licence):
`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not
evaluated for any dependency or tool`. The values are recorded anyway because
other gates and the repository's own declared licence use them: `sha2` 0.11.0 is
`MIT OR Apache-2.0` (check `E2-sha2-license`), `std` ships under the toolchain's
own dual licence. Gate 2 (MSRV): `sha2` declares **1.85**, below the 1.96 floor
(`E2-sha2-msrv`); this gate is what excludes `cratestack-axum` at **1.98.0**
(`E3-cratestack-msrv`), `blake3` and `xxhash-rust`, both of which declare **no**
`rust-version` so the tree floor is unverifiable (`E3-blake3-msrv`,
`E3-xxhash-msrv`). Gate 3 (advisories, `unsafe` posture): `sha2`'s only RustSec
record is RUSTSEC-2021-0100, patched at ≥ 0.9.8, so 0.11.0 has none open
(`E5-sha2`), and `https://rustsec.org/packages/<name>.html` returns 404 for
`moka`, `hashlink`, `quick_cache`, `axum-idempotent`, `cratestack-axum` and
`axum` against a **200** control at `atty` (`E5-control`), so the 404s are real
absences and not a network failure; `sha2` contains `unsafe` in its
architecture-specific backends and does not set `#![forbid(unsafe_code)]`, which
is expected of a hash with CPU-feature backends and is recorded rather than
waved past, while the template's own crates keep `#![forbid(unsafe_code)]`
(executed, `P1-unsafe`). Gate 4 (OS matrix): nothing recommended is
platform-conditional; this run executed on macOS only and the Linux half is
carried as unproven. Gate 5 (default features, runtime coupling): `sha2` with
`default-features = false, features = ["alloc"]` drops the `oid` feature and its
`const-oid` dependency; the port has no runtime coupling, proved by the plain
`#[test]` store suite. Gate 6 (binary size, compile time): the store and layer
add **zero** crates, measured; `sha2` adds **+8** (`P6-sha2`). Binary size was
not measured and no figure is claimed.

re-verify: **2027-03-18**, or earlier on any of — the org REST API Design Standard moving off blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`, since every conformance verdict above is pinned to a line in that blob and checks `C1-*` through `C7-*` fail closed when a line moves; the owner disposing of `OVERRIDE (OV-16)`, whose refusal would force option 3 and a durable store; **axum** publishing 0.9, since `from_fn_with_state`'s signature is the whole mechanism; **R69** republishing, because the `crates/web` paths this design uses are accepted-but-unpublished at revision 10; **R70** publishing, since every 400/409/413/422/503 body here is its envelope and its revision 1 does not yet conform to R5.13 (below); **R02, R03, R05 or R56** publishing a decision differing from the accepted revisions this is written against; **R74 or R75** publishing an ordering that contradicts the six constraints handed over below; **R77** publishing the environment-variable names for the TTL, the in-flight deadline and `max_entries`; **`cratestack-axum`** declaring a `rust-version` at or below the template's floor, which would remove the gate-2 exclusion and reopen A5; **`axum-idempotent`** publishing a release with an allow-list status rule and a store trait not bound to `ruts`; the **httpapi** working group reviving `draft-ietf-httpapi-idempotency-key-header` past -07 or it reaching RFC, which would change its standing from evidence to normative; **RustSec** publishing an advisory against `sha2`, `axum`, `tokio` or `bytes`; or the next **`msrv-policy`** floor advance past 1.96

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

**R73 owns no parameter and consumes none.** The prompt's `- owns:` and
`- consumes:` lines are both empty and `research/CLAUDE.md`'s R73 row carries
`—` in its `owns` column, so the assumed set is exactly the four owner-fixed
values, following the precedent of the other empty-`consumes` items
(`research/topics/06-unsafe-code-policy/DECISION.md`, `## Parameters`). The four
lines above are byte-identical to `docs/port/PARAMETERS.md`; this run's
`inputs/PARAMETERS.md` snapshot is identical to the live registry, verified by
`diff` (check `D3-params`).

**No `CONFLICT:` line.** Nothing in this recommendation requires a consumed
parameter to change. Each fixed value was applied rather than recited. Edition
2024 is what the probe declared and built under, and the adapter's eviction
branch uses an edition-2024 `let`-chain. The MSRV floor of **1.96** — stable
**1.98.1** minus two minors — is what the probe declared, and Cargo's MSRV-aware
resolver honoured it visibly: `cargo metadata` reports "Locking 62 packages to
latest Rust 1.96 compatible versions" and holds `matchit` at 0.8.4 with a newer
release available. That floor is load-bearing twice over, because it is the gate
that excludes `cratestack-axum` and `blake3`. The OS matrix is honoured in that
nothing recommended is platform-conditional, with the macOS-only execution
stated as a gap rather than papered over. The `license` value is the repository's
own and is the reason `sha2`'s dual licence is preferred over `twox-hash`'s
MIT-only, a preference rather than a gate under the Q7.B ruling.

**Researched values this design is written against, recorded in prose rather
than as `- assumes` lines** — because the prompt's `consumes:` line is empty and
the packaging validator derives the assumed set from it, so adding a fifth line
would fail publication:

- **`web-extra-surface` (R69).** The registry row still carries revision 9's
  bytes, which place the web tree at `src/web/`. **R69 revision 10 is
  owner-accepted and unpublished**
  (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`, owned
  value at line **1791**), and it moves that tree to the optional member
  **`crates/web`**, with `axum` 0.8.9 and `tokio` 1.53.1 declared non-optionally
  in `crates/web/Cargo.toml` and `tower` 0.5.3 as that crate's dev-dependency
  only, for the `ServiceExt::oneshot` idiom. **This design uses the `crates/web`
  paths throughout**, and the probe declares exactly those pins (`P1-pin`,
  `P1-tower-dev`). This is not a `CONFLICT`: the recommendation needs no change
  to R69's value, only to paths it has already accepted. R69's republication is
  a re-verify trigger on every member.
- **`error-taxonomy-exit-codes` (R67, published).** Every error this layer
  produces is an HTTP status; R67's `Exit` taxonomy governs *process* exit
  codes, so no catalogue row is requested here. The one place R67 does reach is
  R03 rule 5's mapping of the poisoned-`Mutex` `PortError::Unavailable` to
  `RSLB101`, which check `s10` executes.
- **`http-transport-injection-seam` (R01, published).** Followed clause for
  clause; executed by check `s09`.

## Empirical check

Toolchain: `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`, `Darwin 25.4.0 arm64`
(`aarch64-apple-darwin`). Working directory for every script:
`research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/evidence/`. Four
scripts, **109 checks, 109 pass, 0 fail, 0 skip**, each exiting non-zero on any
failure.

| Script | Log | Checks | What it establishes |
|---|---|---|---|
| `r73-standard-conformance.sh` | `r73-standard-conformance.log` | **43** | Every org-standard rule this decision relies on, quoted at its line out of the pinned blob |
| `r73-probe.sh` | `r73-probe.log` | **26** | The design builds, lints clean and passes 28 behavioural checks; the measured hit-path cost and the seven dependency-tree deltas |
| `r73-sources.sh` | `r73-sources.log` | **23** | Stripe, the IETF draft, py at its pin, and two published crates, read at source |
| `r73-registry.sh` | `r73-registry.log` | **17** | crates.io, RustSec and GitHub figures, and the four claims the engine legs split on |

**What the probe is, stated plainly.** The Opus raw's probe workspace was
created under `$TMPDIR` and **deleted after that run** (`raw/opus.md:1081`,
`:1261-1262`), so no source survived to re-run. The probe under
`review/evidence/probe/` is a **re-derivation** written by this synthesis from
the raw report's prose clauses — roughly 700 lines of port, adapter, layer and
two test suites. Behavioural agreement is therefore evidence that the **design**
is executable and behaves as described; it is **not** a byte-level reproduction
of the raw report's run, and nothing here claims it is. `r73-probe.sh` copies
the source into a directory it creates under `$TMPDIR` and deletes on exit, so
no `target/` tree and no `Cargo.lock` reaches the repository.

**Executed results.**

| Command | Expected | Observed |
|---|---|---|
| `cargo metadata --format-version 1` | resolves under the declared 1.96 floor | "Locking 62 packages to latest Rust 1.96 compatible versions"; `matchit` held at 0.8.4 |
| `cargo build` | clean | clean (`P2-build`) |
| `cargo clippy --all-targets -- -D warnings` | clean under `#![forbid(unsafe_code)]` | clean (`P2-clippy`, `P1-unsafe`) |
| `cargo test --test store` | 10 pass, no async runtime in scope | **10 passed, 0 failed** (`P3-store`, `P3-sync`) |
| `cargo test --test web` | 18 pass | **18 passed, 0 failed** (`P4-web`) |
| `cargo test --release --test store s08` | hit path far below 1 ms | **275 ns/op** in the committed log; 179–373 ns/op across seven runs (`P5-bench`) |
| `cargo tree -e normal -i tower` | the only `tower` edge is axum's | `tower v0.5.3 ← axum v0.8.9 ← r73_probe` (`P2-tower-edge`) |
| `cargo tree -e normal` deltas | measured, not estimated | baseline **51**; `+sha2` 59 (**+8**); `+hashlink` 54 (+3); `+lru` 56 (+5); `+quick_cache` 60 (+9); `+mini-moka` 62 (+11); `+moka` 65 (+14); `+axum-idempotent +ruts +tower-cookies` **88** (**+37**) |

**Ecosystem figures**, every one from
`GET https://crates.io/api/v1/crates/<name>` reading `crate.recent_downloads`
and `crate.downloads`, with the newest unyanked version from the same response's
`versions` array, all retrieved **2026-09-19** (UTC). GitHub figures from
`gh api repos/<o>/<r>` through a keyring-authenticated call, never more than one
per 20 seconds. Advisories from `https://rustsec.org/packages/<name>.html`.

| Crate | 90-day | All-time | Newest unyanked | `rust-version` | Licence |
|---|---|---|---|---|---|
| `sha2` (**recommended**) | 257,569,817 | 956,117,098 | 0.11.0, 2026-03-25 | **1.85** | `MIT OR Apache-2.0` |
| `cratestack-axum` | 14,687 | 15,173 | 0.12.0, 2026-09-06 | **1.98.0** — excluded | MIT |
| `axum-idempotent` | 230 | 6,911 | 0.3.0, 2026-08-19 | 1.85.0 | MIT |
| `idempotent` | 59 | 144 | **2.0.0**, 2026-09-16 | 1.98.0 | MPL-2.0 |
| `use-idempotency` | 88 | 135 | 0.0.1, 2026-05-26 | 1.95.0 | `MIT OR Apache-2.0` |
| `moka` | 36,350,556 | 127,190,824 | 0.12.16, 2026-08-09 | 1.71.1 | `(MIT OR Apache-2.0) AND Apache-2.0` |
| `hashlink` | 94,153,538 | 336,327,371 | 0.12.2, 2026-09-07 | 1.85 | `MIT OR Apache-2.0` |
| `lru` | 89,463,264 | 349,269,295 | 0.18.4, 2026-09-03 | 1.85.0 | MIT |
| `blake3` | 44,485,979 | 184,054,587 | 1.8.7, 2026-08-20 | **not declared** — excluded | `CC0-1.0 OR Apache-2.0 OR …` |
| `twox-hash` | 54,271,286 | 245,026,097 | 2.1.4, 2026-08-27 | 1.81 | MIT |
| `tower` | 174,508,765 | 670,171,877 | 0.5.3, 2026-01-12 | 1.64.0 | MIT |

`RustCrypto/hashes`: **2,264** stars, not archived, `pushed_at`
2026-09-15T06:42:47Z. `jimmielovell/axum-idempotent`: **5** stars, not archived,
2026-08-19. `moka-rs/moka`: **2,686** stars, not archived, 2026-08-09.
**Maintenance state:** `sha2` **active** — released within six months, repository
pushed four days before retrieval, no open advisory, and not archived, which
check `E6-sha2-active` asserts rather than assumes.

**Reproduction, established by re-running rather than asserted.** Each of
`r73-standard-conformance.sh`, `r73-registry.sh` and `r73-sources.sh` was run a
second time and diffed against the committed log: **every line is identical
except the single `date_utc:` / `run_date_utc:` line**, which is the run's own
clock. That is the rule for comparing them. The three scripts read **committed
snapshots** under `review/evidence/snapshots/` rather than the live network, so
a download counter moving cannot change the log; `R73_REFRESH=1` is the only
mode that fetches, and it rewrites the snapshots. The crates.io snapshots are
**reductions** of the responses — the `crate` fields and the `versions` entries
the assertions read — and each carries a sidecar recording the endpoint, the
UTC retrieval time, and the **sha256 and byte count of the full response**, so
the reduction is auditable rather than silent. The Stripe snapshot is likewise a
compact extract of a 1.3 MB rendered page, with the full page's sha256 recorded.
`r73-probe.log` does **not** reproduce byte-for-byte and is not claimed to:
`date_utc`, the `mktemp` work directory, cargo's own timing lines, the test
execution order and the measured `ns_per_op` all vary run to run. What is stable
in it is every `PASS`/`FAIL` line, the check count, the eight dependency-tree
totals, and the `Locking 62 packages` line.

**Checks that cannot pass vacuously.** `E5-control` requires
`https://rustsec.org/packages/atty.html` to return **200** while the six
packages under test return 404, so the 404s cannot be a blanket network failure.
`C9-control` quotes an unrelated rule (R5.14) at its line, so a failure among
the relied-on quotations cannot be a general read failure of the snapshot.
`P3-sync` asserts both that no `#[tokio::test]` attribute is present **and** that
`#[test]` attributes are, so it cannot pass on an empty file. `P6-axumidem-raw`
is a deliberate inverted assertion: it **fails** if the raw report's +48 figure
*does* reproduce, so the decision cannot quietly keep a claim it has disowned.

**Not executed, and carried as unproven.**

1. **No `ubuntu-latest` run.** Every build, test and measurement ran on
   `aarch64-apple-darwin`. The `target-os-matrix` gate rests on the absence of
   platform-conditional code, not on an executed Linux run. P03's CI proves it.
2. **No end-to-end latency or throughput figure**, and the hit-path
   microbenchmark is deliberately not extrapolated to request-level performance.
3. **No binary-size measurement.** The qualitative statement that eight small
   `no_std`-capable crates with no build script add little is not a measurement.
4. **Issue responsiveness for `sha2` is carried from the Opus raw, not
   re-derived** — median 0.06 days to first maintainer response across the ten
   most recently opened issues, one unanswered. Re-deriving it costs ten-plus
   GitHub calls at 20-second spacing, and the figure does not move the
   recommendation. **Carried.**
5. **The OpenAI Doxa leg's claim that `moka` does not test macOS in upstream CI
   was not verified.** It is that leg's sole ground for excluding the store the
   other two legs recommend. This decision excludes `moka` on measured tree cost
   and on the compare-and-set fit argument instead, neither of which depends on
   the CI claim. **Unverified, and not relied on.**
6. **Lock contention under real load** is not measured; the single global mutex
   is a real serialization point and the microbenchmark cannot show it.
7. **No shared adopter** combining `axum` 0.8.9, `tokio` 1.53.1 and `sha2`
   0.11.0 in this arrangement was found, and none is claimed. The compatibility
   evidence is the executed build, not an appeal to a third party.

## Engines

- **opus** `raw/opus.md` — Claude Opus 5, sha256
  `a909a140a6d5664c04c0d5f996cd4b76e6f367d9520c4cac30d8fd44e38527ba`.
- **doxa** `raw/doxa.md` — the three-provider report, operation
  `research-20260918-151748-c3450952b9d24d59`, raw sha256
  `da3903244093c9be53f29d426ac20f6b9de835f67b5d47f5ee57b0ee3d7dc6f4`, with twins
  `raw/doxa.normalized.md` and `raw/doxa-{openai,perplexity,gemini}.normalized.md`.
  Per `doxa/normalization.json`, the providers are **openai** `gpt-5.6-sol`,
  **perplexity** `sonar-deep-research` and **gemini**
  `deep-research-preview-04-2026`; all three validated `OK` with zero content
  lines missing from the regrouped file.
- **codex** — **absent.** The Codex leg is deferred by owner ruling
  **W1-CODEX3** (2026-09-18), recorded by the controller in the run manifest
  (`remaining_budget`: "Codex leg deferred under W1-CODEX3"). The consequence is
  stated rather than hidden: **no second model family reviewed the Opus report**,
  and the three Doxa providers are a different family but were run from the same
  prompt without sight of the Opus text. The findings below partly compensate,
  because the Doxa legs disagree with the Opus leg on two substantive points and
  those disagreements were settled by execution.

**Disagreements, and the evidence that settled each.** Six were settled against
a leg; each names the check.

1. **"No published Rust crate implements this" (Opus) versus `cratestack-axum`
   (OpenAI leg) — settled against the Opus leg.** The crate exists at 0.12.0
   with a complete `src/idempotency/` module and **14,687** 90-day downloads
   (`E4-cratestack-exists`, `E4-cratestack-adoption`, `S4-cs-module`,
   `S4-cs-store`). The Opus leg's six-spelling crates.io search missed it, which
   its own *Medium* confidence rating anticipated. **The recommendation does not
   change**: gate 2 excludes it at `rust-version = "1.98.0"` against the 1.96
   floor (`S4-cs-msrv`), and fit excludes it independently. What changes is the
   answer to the HIGH question, which is now "one exists and two gates exclude
   it" rather than "none exists". The OpenAI leg deserves the credit and is the
   only leg that named it.
2. **The `axum-idempotent` stack's transitive cost — settled against the Opus
   leg.** It claims **+48** crates, total 100. Measured under the same method
   that reproduced all six other rows exactly — unique name-and-version pairs in
   the normal graph — the stack is **88**, **+37** (`P6-axumidem`,
   `P6-axumidem-raw`). Control `P6-axumidem-versions` confirms every package the
   raw named is present at the version it named, including `ruts v0.10.1`,
   `tower-cookies v0.11.0`, `dashmap`, `cookie`, `bincode` and `chacha20`, so
   the difference is a counting difference and not a different resolution. The
   argument survives at +37 against +8; the number is corrected.
3. **`BASELINE-REVIEW: F314` (Opus and OpenAI, in opposite directions) —
   settled against both labels.** F314 is this item's own `DIVERGENT` row, and
   the process is scoped to settled REUSE and ADOPT baselines
   (`research/RUNBOOK.md:18-22`), so neither line is legal. The Opus finding's
   *substance* is correct and is carried in `## Decision` as F314's own
   reasoning; the OpenAI leg's proposal to store every completed outcome is
   declined, because it needs the execution-started signal Stripe's own page
   says Stripe has (`S1-execution-gate`) and a `from_fn` layer does not.
4. **Whether 2xx-only is "Stripe semantics" (Perplexity and Gemini assert yes,
   unsourced; Opus and OpenAI assert no, sourced) — settled against Perplexity
   and Gemini at source.** Stripe's page states it saves the first result
   "regardless of whether it succeeds or fails" (`S1-replay-errors`) and the
   draft says "success or an error" (`S2-replay`). Perplexity cites the
   `cratestack` docs for the claim and Gemini cites no source at all. The
   ledger's F314 Notes repeat the same misattribution, and so does py's own
   comment (`S3-stripe-comment`).
5. **Gemini's claim that the `idempotent` crate was "entirely yanked from the
   registry", version 0.0.0 — settled against Gemini.** Version **2.0.0** is
   live and unyanked, published 2026-09-16, licensed MPL-2.0
   (`E4-idempotent-live`, `E4-idempotent-ver`). The Opus leg's reading was
   right. Gemini's report also cites `https://crates.io/svelte/crates/idempotent/0.0.0`,
   which is not a crates.io route.
6. **Perplexity's lead bundle member `use-idempotency` — settled against
   Perplexity.** It exists but has **135** all-time downloads and one release,
   0.0.1 from 2026-05-26 (`E4-use-idempotency`). Its own stated non-goals
   include "no request hashing", which the standard's R3.9 makes mandatory, so
   the bundle that leads with it has no owner for the fingerprint requirement at
   all.

**Two Doxa designs are nonconformant to the binding standard, which the legs
could not have known** — W2-REST post-dates their run. **Gemini's design has no
payload fingerprint whatsoever**; its cache key is `(header, method, path)` and
it never compares bodies, so it cannot "reject a reused key carrying a different
payload" as R3.9 at `:653-655` requires, and its own validation section claims a
test proving the composite key "prevents payload collisions" when the key
contains no payload. **Perplexity's store trait is `get` / `insert_success` /
`mark_conflict` with no in-flight state and no 409 anywhere in its report**, so
two concurrent retries both execute — the re-execution R3.9 forbids. **Where the
legs converge is worth recording too**: all four independently reach a
client-supplied key on `POST`/`PUT`/`PATCH`, a 2xx-gated write (three of four), a
replay marker header, and — in the two legs that address concurrency at all —
an atomic reserve-or-conflict primitive returning 409. The OpenAI leg reaches
this decision's port shape almost exactly, including the fingerprint-beside-key
rule stated as a bolded negative, and is the strongest of the three.

**One further correction this synthesis makes to the Opus raw, beyond the
three above.** Its design streams an unknown-length or oversize 2xx through
uncached and releases the claim, so a retry re-executes the side effect while
the client sees a normal 2xx twice; the raw names this "a documented hole … the
sharpest one" and hands the choice to P03. Under R3.9 that is not a choice a
decision may defer, so this decision picks the completed-but-unreplayable marker
and answers retries 409 (`w09`, `w09b`). Two further departures are recorded in
the conformance table rather than here: the replay marker's value moves to the
RFC 9651 Boolean `?1` per R4.12, and correlation headers are excluded from the
cached entry per R11.7 — the latter a defect in the raw's design, not a
preference, since replaying a stored header list verbatim replays the first
request's `request-id`.

**Couplings stated, not decided.**

- **R70 (`http-problem-envelope`) — flagged.** Five bodies are its: **400**
  invalid or duplicated key; **409** a request is outstanding for this key, or
  the completed outcome is unreplayable; **413** request body too large to
  fingerprint; **422** key already used with a different payload; **503** store
  unavailable. **R70 revision 1 does not conform to the standard that now binds
  it**: its envelope omits `type` by default and relies on `about:blank`
  (`research/runs/R70/2026-09-17T034010Z-31ad2ef28df7/review/DECISION.md`,
  envelope contract table), while R5.13 point 5 at `rest-api-standard.md:1049`
  requires `type` on every problem document and forbids `about:blank`. R70
  revision 1 predates W2-REST. This decision states the conflict and decides
  nothing about it. The corrected F314 also removes a question R70 inherited:
  **error responses are never replayed**, so no envelope needs a replay marker.
- **R75 (`http-middleware-stack`, owns F317, not yet researched) — six
  constraints, each with its reason.** (1) Idempotency must sit **inside**
  `CompressionLayer`: otherwise the entry stores an already-encoded body with
  its `Content-Encoding`, and a replay to a client with a different
  `Accept-Encoding` returns a body it cannot decode. This is correctness, not
  taste. (2) Inside `RequestBodyLimitLayer`, so the standard layer rejects an
  oversize body first and the idempotency cap is a second, smaller ceiling on
  keyed requests only. (3) Inside `CatchPanicLayer` and `TimeoutLayer`, both of
  which work by dropping the inner future, which `AbandonOnDrop` handles and the
  in-flight deadline backstops. (4) Inside the request-id and access-log layers,
  so a replayed response carries a live correlation id and is logged like any
  other — this is now load-bearing for R11.7 conformance, because the layer
  deliberately does not store one. (5) `Idempotency-Key` belongs in
  `SetSensitiveHeadersLayer`'s set, per §3.4 at `:675-677`. (6) Installed with
  `.layer` on the router carrying the unsafe routes, not `.route_layer`, so a
  405 from axum's own method router is not preceded by a claim.
- **R74 (`rate-limiting-middleware`) — proposed, not fixed.** Place rate
  limiting **outside** idempotency: a 429 then never reaches this layer, so a
  rate-limited request never creates a claim it must abandon, and the
  request-body copy this layer pays for is not spent on a request that will be
  rejected. R74 owns the decision.
- **R71 (`openapi`).** Every unsafe operation documents an optional
  `Idempotency-Key` request header (string, ≤ 255 bytes), the
  `Idempotency-Replayed` response header **with its RFC 9651 Boolean value
  `?1`**, and the 400/409/413/422 responses. R71 also inherits the bounded-body
  rule: an operation advertising the header should return a bounded,
  non-streaming 2xx, because an unbounded one is answered 409 on retry rather
  than replayed, and that belongs in the published contract.
- **R76 (`cors-middleware`).** `Idempotency-Replayed` must appear in
  `Access-Control-Expose-Headers`, per R4.17 at `:868`; without it a
  cross-origin browser client cannot read the marker at all.
- **R77 (`web-env-settings`) — names proposed only.** Four knobs, with py's
  defaults where py has one: entry TTL **86,400 s** (py `settings.py:72`, and
  also Stripe's published retention, `S1-retention`), in-flight deadline **30 s**
  (new — py has no in-flight state), `max_entries` **1,024** (py
  `settings.py:73`), and the request and response body caps. R77 owns the
  spellings. `OVERRIDE (OV-16)` makes the first and third operator-visible.
- **R72 (`pagination`) and R32 (`test-harness`).** R72 shares only the standard.
  For R32: `s01`–`s10` are core unit checks with no runtime; `w01`–`w17` are
  `crates/web` integration checks needing the `web` feature and a tokio runtime.
  That split is the tier boundary.

**What P03 must validate**, since every decision here is a proposal validated in
the implementation phase: the 28 behavioural checks re-run inside the real
template on **both** runners in `target-os-matrix`, the Linux half being the gap
this run could not close; that the layer and its tests vanish with the `web`
feature off; the pinned-digest test that makes the fingerprint a genuine
cross-implementation contract; the conformance note carrying `OVERRIDE (OV-16)`
and the R4.12 record in R1.7's template shape; the OpenAPI snapshot once R71
lands; and the layer's final position once R75 fixes the ordering, against the
six constraints above.

**Controller requests, since this item may not edit the ledger or the registry.**
(1) `docs/port/COMMONALITY.md:318`'s F314 Notes parenthetical — "(Stripe
semantics: errors are meant to be retried for real, not replayed)" — is
factually wrong about Stripe and should be corrected to a justification that
does not rest on Stripe; the evidence and the replacement ground are in
`## Decision`. This is filed as a request rather than as a `BASELINE-REVIEW:`
line, because F314 is this item's own `DIVERGENT` row. (2) `OVERRIDE (OV-16)`
needs an owner disposition; option 1 is recommended. (3) The R70 revision 1
`about:blank` conflict with R5.13 should reach R70 before it publishes.
