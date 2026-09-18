# 2026-09-18 — R70 — http-problem-envelope (bundle, Focused) — decision (revision 1)

## Decision

**`rs-launch-blueprint`'s optional `web` surface renders every non-2xx response —
domain failure, router miss, extractor rejection and blocking-bridge panic alike —
as one RFC 9457 `application/problem+json` document, built in
`crates/web/src/problems.rs` by `problem_details` 0.10.0
(`features = ["axum", "json"]`) typed as `ProblemDetails<ProblemExt>`, where
`ProblemExt` carries R67's catalog token as the RFC 9457 extension member `code`
and an optional `errors` field report. A domain failure's status comes from a free
`pub const fn http_status(ErrorCode) -> StatusCode` proved total by a test that
iterates `ErrorCode::ALL`; a framework failure keeps the status axum already
computed and carries a catalog token as its identity. The funnel is wired at
axum's four extension points — `impl IntoResponse for WebError`,
`Router::fallback`, `Router::method_not_allowed_fallback`, and newtype extractors
whose `type Rejection = WebError` — adding no Cargo feature, no `macros` feature,
and no crate beyond `problem_details` and its one transitive addition
`http-serde`.**

**Ledger rows settled.** **F305** "single RFC 9457 error envelope for every
non-2xx response" (`docs/port/COMMONALITY.md:309`, `py-only` · `DIVERGENT`) and
**F306** "domain-error-to-HTTP-status mapping table" (`:310`, `py-only` ·
`DIVERGENT`). No `BASELINE-REVIEW:` line is raised: both rows are this item's own
`DIVERGENT` rows, not settled `COMMON → REUSE` or `ADOPT` rows, and R67 recorded
the trap of filing an answer under a review label
(`research/topics/67-error-and-exit-code-contract/DECISION.md:683-689`).

**This is a proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what the research found and what it recommends; P03 builds
the template and its CI proves the recommendation. What P03 must validate is
listed under `## Engines`. A decision that does not survive implementation is
revised against this recorded research, not researched again from scratch.

**One stack — four members, one crate.**

| # | Member | What it is | Version |
|---|---|---|---|
| M1 | `problem_details` | the RFC 9457 document type and its axum `IntoResponse`, reached only from `crates/web/src/problems.rs` | **0.10.0**, `features = ["axum", "json"]` |
| M2 | Envelope contract `problem+json/v1` | the exact member set, media type and omission rules of the body | repository-owned contract, append-only |
| M3 | Domain-code-to-status table | `pub const fn http_status(ErrorCode) -> StatusCode` plus `NOT_REQUEST_REACHABLE` and a coverage test over `ErrorCode::ALL` | template code, no crate |
| M4 | Framework error funnel | `IntoResponse` + `fallback` + `method_not_allowed_fallback` + newtype extractors with `type Rejection = WebError` | template code, no crate |

M2, M3 and M4 are crate-agnostic: substituting a hand-rolled document struct for
M1 changes none of them. That is the escape hatch, and it is the answer to M1's
one real risk (below).

### The envelope contract — `problem+json/v1`

| Member | Source | Rule |
|---|---|---|
| `type` | RFC 9457 §3.1.1 | **omitted** by default. §3.1.1: "When this member is not present, its value is assumed to be `about:blank`", so omission is conformant (`registry.log`, section 5). Set to `<docs base>/<code>` only where a project publishes error documentation |
| `status` | RFC 9457 §3.1.2 | the numeric status, always present, always equal to the response's own status line |
| `title` | RFC 9457 §3.1.3 | `StatusCode::canonical_reason()` — the analogue of py's `HTTPStatus(status_code).phrase` |
| `detail` | RFC 9457 §3.1.4 | present only when a public message exists; replaced by a fixed generic string when the W5 rule withholds it; never `null` |
| `instance` | RFC 9457 §3.1.5 | the request path, matching py's `instance=request.url.path` |
| `code` | RFC 9457 §3.2 extension | **always present.** R67's `ErrorCode::as_str()` token verbatim; the only machine identity |
| `errors` | RFC 9457 §3.2 extension | `BTreeMap<String, Vec<String>>`, omitted when absent; field name → messages. `BTreeMap` rather than `HashMap` so member order is deterministic and R71's snapshot is stable |

Media type `application/problem+json`, taken from
`JsonProblemDetails::CONTENT_TYPE` so the string exists once (verified in the
vendored 0.10.0 copy, `probe.log` section 6). Two omission rules, both inherited
from py and both enforced by serde rather than by convention: every optional
member carries `#[serde(skip_serializing_if = "Option::is_none")]` (py's
`exclude_none=True`), and no member is ever serialized as `null` — the same rule
R67 states for `hint`. The contract is **append-only**: a member may be added;
none may be removed, renamed or retyped without a new contract name.

Three consequences are deliberate rules rather than defaults:

1. **`code` is an extension member, not `type`.** RFC 9457 §3.2 provides for
   extension members explicitly and names an `errors` extension by example
   (`registry.log`, section 5), and the crate flattens a typed extension struct
   into the top-level object, so `code` is a sibling of `title` and `status` on
   the wire. The result is **one identity string across both surfaces**: `rslbp`
   prints `RSLB301` on stderr and the serve binary returns `"code":"RSLB301"` in
   the body. This is the direct answer to the question R69 revision 10 handed
   this item (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1396-1399`).
2. **`hint` is not an HTTP member.** R67 defines `hint` as a CLI remediation line
   "rendered as its own line in human output". Its HTTP analogue is documentation
   behind `type`, not a body member. This item adds exactly two extension members,
   `code` and `errors`, and no more.
3. **py's explicit `"type": "about:blank"` is not carried.** Two members cannot
   both be the identity, and §3.1.1 makes omission mean the same thing.

### The domain-code-to-HTTP-status table

Every row is a **proposal** for P03; the *mechanism* is what this decision
verifies. The keys are R67's seventeen published catalog rows.

| R67 code | Meaning | HTTP | Ground |
|---|---|---|---|
| `RSLB301` | resource not found | **404** | py maps `ProjectNotFoundError`/`WorkspaceNotFoundError` to 404; R03 revision 1 states the same edge from the other side — "The web handler maps the same absence to HTTP 404 with no second translation site … R70 owns the status table" (`research/runs/R03/2026-09-17T033527Z-cd9e6a9555b6/review/DECISION.md:168`) |
| `RSLB401` | credentials absent | **401** | py maps `AuthError` to 401 |
| `RSLB402` | credentials rejected | **401**, not 403 | RFC 9110 §15.5.2: "If the request included authentication credentials, then the 401 response indicates that authorization has been refused for those credentials." §15.5.4 reserves 403 for credentials the server "considers them insufficient to grant access" — an *authorization* failure R67's catalog does not yet name. Both sentences re-fetched and asserted (`registry.log`, section 6) |
| `RSLB501` | conflict / precondition failed | **409** | R67's exit 5 is "conflict/precondition failed" |
| `RSLB201` | usage/parse | **400** when a *domain* error raises it; **the framework's own status** (422 / 400 / 415) when a rejection raises it | the request extractor is the HTTP analogue of the CLI parser; see the two-status-sources rule below |
| `RSLB102`, `RSLB103` | transport, remote-API failure | **502** | py maps `APIError` to `HTTP_502_BAD_GATEWAY` |
| `RSLB000`, `RSLB101`, `RSLB104`, `RSLB202`, `RSLB203`, `RSLB204` | unexpected, I/O, config layer unreadable, config unparsable, config value invalid, secret via prohibited channel | **500** | py maps `ConfigError` to 500 and its `Exception` catch-all to 500. The config codes are 500 and never 4xx because in the web binary they describe *this process's own* configuration — a startup failure, not a request failure |
| `RSLB205`, `RSLB901`, `RSLB902`, `RSLB903` | prompting unavailable, SIGINT, SIGTERM, prompt interrupted | **500**, and listed in `NOT_REQUEST_REACHABLE` | no HTTP request can raise them; they get a row so the table is total and a named constant so the intent is recorded rather than buried in a catch-all |

**Two status sources, and why that is not a defect.** py has three
(`ERROR_STATUS.get(type(exc), 500)` for domain errors, `exc.status_code` passed
through for `StarletteHTTPException`, a hardcoded 422 for
`RequestValidationError`). This design has two: the table for a domain failure,
and `WebError::framework(status, code)` for a failure whose status the framework
already computed. Keeping axum's status is what preserves the 422-versus-400-
versus-415 distinction axum has already made — information a single table row
would discard.

**The mechanism, and why it is not a `match`, a trait method or a derive.**
`ErrorCode` is `#[non_exhaustive]` and lives in another crate, so a match in
`crates/web` **cannot** be exhaustive and needs a `_ =>` arm. R67 anticipated
exactly this consumer and supplied the compensation: "R70's status table is
coverage-tested by iterating `ErrorCode::ALL` and asserting every member maps, so
totality is enforced by a failing test instead of by the compiler"
(`research/topics/67-error-and-exit-code-contract/DECISION.md:148-153`; resolution
at `:653-662`). This decision adopts that unchanged and **verified it in both
directions**: with the enum in the same crate the `_` arm drew
`warning: unreachable pattern … no value can reach this`; with the enum behind a
crate boundary the identical arm compiled silently (`probe.log`, section 5). A
trait method on the domain type was rejected on layering — it would put
`http::StatusCode` in `crates/core`, which `crates/cli` also depends on under R02's
topology. A derive was rejected on R67's own ground: "A variant rename is a
compiler-checked, silent refactor in Rust — which is exactly why a derived code is
dangerous" (`…/67-…/DECISION.md:135`).

### The funnel, and the two header obligations it must not drop

| py source | py handler | Rust analogue | Mechanism |
|---|---|---|---|
| `PyError` | `handle_py_error` | a handler returning `Err(WebError)` | `impl IntoResponse for WebError` |
| `StarletteHTTPException` | `handle_http_exception` | a router-level miss | `Router::fallback` (404) and `Router::method_not_allowed_fallback` (405) |
| `RequestValidationError` | `handle_validation_error` | an extractor rejection | a newtype extractor whose `type Rejection = WebError`, preserving `rejection.status()` and `rejection.body_text()` |
| bare `Exception` | `handle_unexpected_error` | a panic in R05's blocking bridge | `tokio::task::JoinError` → `RSLB000`/500 |

The hook that reshapes the framework's own validation body is the extractor's
associated `Rejection` type — about ten lines per input extractor family
(`Json`, `Query`, `Path`), and **no `macros` feature**, which matters because
R69's owned `web-extra-surface` value does not enable it and this item does not
own that value. `#[derive(FromRequest)]` would give the same behaviour in fewer
lines and becomes the recommendation the moment R69 enables `macros` for another
reason. `axum_extra::extract::WithRejection` was not taken: it adds a crate, it
changes the handler signature, and R69 records `axum-extra` as an open hand-off
(`…/R69/…/review/DECISION.md:214`).

Two RFC 9110 obligations survive the envelope, and both were executed rather than
assumed:

- **`Allow` on a 405.** RFC 9110 §15.5.6: "The origin server MUST generate an
  Allow header field in a 405 response containing a list of the target resource's
  currently supported methods." axum sets it before the fallback renders and it is
  still present after `method_not_allowed_fallback` replaces the body — asserted
  as `Allow: GET,HEAD` on a `DELETE` against a `GET`-only route.
- **`WWW-Authenticate` on a 401.** RFC 9110 §15.5.2: "The server generating a 401
  response MUST send a WWW-Authenticate header field (Section 11.6.1) containing
  at least one challenge." `WebError` carries `headers: Vec<(HeaderName, HeaderValue)>`
  with a `with_header` builder, and `IntoResponse` inserts them after the body is
  rendered. **The challenge string itself is not this item's** — no P02 item
  selects an authentication scheme — so this item supplies the mechanism and
  records the obligation for whichever item lands auth.

### Judgements carrying the weight

Separated so a reviewer can accept or reject them independently.

| # | What is decided | Force | Ground |
|---|---|---|---|
| J1 | RFC 9457 rather than a house shape | **Recommended, and checked against a counter-example** | The RFC is an IETF Proposed Standard on the IETF stream with both media types IANA-registered citing `[RFC9457]` (`registry.log`, section 5); ISRG's `divviup/janus` declares `http-api-problem = "0.60.0"` in its workspace manifest (re-fetched, `registry.log` section 7). Against: Oxide's `dropshot` ships a bespoke `HttpErrorResponseBody { request_id, error_code, message }` and no problem+json (re-fetched, same section). Its three ideas map onto this design without contradiction — its `error_code` is this design's `code`, its `message` this design's `detail`; the disagreement is about the wrapper, not about what a client needs |
| J2 | Take `problem_details` 0.10.0 rather than hand-roll the ~50-line struct | **Recommended, and the closest call in this decision** | Measured: one added crate in the resolved tree (`http-serde` v2.1.1 — executed as a tree diff against a control member with the identical dependencies minus `problem_details`, `probe.log` section 4); declared `rust-version = "1.85"` against a 1.96 floor; `#![forbid(unsafe_code)]`; no RustSec page; a `utoipa` `ToSchema` derive already on the struct for R71. Against: **bus factor 1** — 10 stars, 1 subscriber, 1 maintainer. Answered structurally, not verbally: the crate is named only from `crates/web/src/problems.rs`, so the replacement is a struct behind an unchanged module surface |
| J3 | `code` as an extension member, not identity in `type` | **Recommended** | One identity string across the CLI's stderr envelope and the HTTP body; a `type` URI would make a client parse a string to recover R67's token, and the token would exist in two spellings |
| J4 | The table is a free `const fn` over `ErrorCode`, not an inline `match` in `into_response` | **Recommended, on testability** | A table inside a response method cannot be called by a test iterating `ErrorCode::ALL` without building a `Response` per code. The three coverage tests here are plain `#[test]` functions with no runtime, no router and no request |
| J5 | No content negotiation; JSON only | **Recommended, on scope** | R69's accepted surface has no templating, static assets or HTML route, and R69 revision 10 records templating as having "No P02 item; pending owner scoping". Adding negotiation would settle a scoping question this item does not own. `impl IntoResponse for WebError` is the single place a later item adds it |
| J6 | The individual status rows | **Proposals the owner may revise without touching anything verified** | Calibrated against py's five mappings and R67's exit semantics. The fourteen executed criteria prove one envelope can cover domain, router, extractor and panic failures at these versions on a supported OS; they do not prove that `RSLB102` should be 502 rather than 504 |

**W5 — the disclosure rule, and the real opposition it resolves.** The config
items require the *opposite* of redaction for a terminal user (R55's "the warning
names the file and the key"; the org CLI Design Standard's R7.6 "name the
offending input in quotes"). Over HTTP a server-side path or config key **is** an
internal disclosure. The rule that satisfies both is not a compromise: the full
message is produced exactly as the CLI items require and written to the log, and
`detail_is_public(code)` decides whether that same text reaches the client.
`WebError::log_detail()` exists for that split. The mechanical enforcement is a
test — **no code whose status is 5xx may be marked detail-public** — executed here
as AC3.

### Corrections to `raw/opus.md`

This decision is synthesized from **one** engine (the Codex leg is deferred under
owner ruling W1-CODEX3), so every load-bearing claim was re-checked at source.
Three things were found wrong or unreproducible; everything else reproduced.

| # | The report's claim | What the source says | Effect |
|---|---|---|---|
| C1 | The envelope table cites **§3.1.2 for `title`** and **§3.1.3 for `status`** (`raw/opus.md:735-736`) | RFC 9457 numbers them the other way round: §3.1.2 is `"status"` and §3.1.3 is `"title"`. Asserted line-by-line for all five members (`registry.log`, section 5) | **Corrected above.** No behavioural effect — the member names and rules are unchanged |
| C2 | "R69 records `axum-extra` as an open hand-off (`…/R69/…:2342`)" | Line 2342 of R69 revision 10 is about the `bacon` dev watcher. The `axum-extra` hand-off is at **`:214`** (Disagreement 3, row 10); R69's own change table at `:97` is what carries the stale `2342` | **Corrected above** to `:214`. The substance — `axum-extra` is R69's open hand-off — is confirmed |
| C3 | "exactly one: `http-serde` 2.1.1 … (executed: `cargo tree -p problem_details --edges normal`)" | True, and now proved a stronger way. `cargo tree -p problem_details` shows that crate's own subtree, which cannot by itself show what is *added* to a tree that already has axum. The check here diffs the resolved trees of two workspace members differing only in `problem_details` | **Method strengthened, conclusion unchanged**: `http-serde v2.1.1` and `problem_details v0.10.0`, nothing else |

Two smaller notes, neither a correction: the report renders
`problem_details` 0.10.0's `created_at` as `2026-08-16T14:36:14Z` where crates.io
returns `2026-08-16T14:36:14.921547Z` (truncation, not error); and the probe here
emits `"instance":"/upstream"` on the 502 where the report's captured body has no
`instance` — a difference in how the two probes wired one handler, not in the
contract, which makes `instance` optional.

**What reproduced exactly.** Every registry figure the decision rests on, on the
same UTC day: 90-day downloads 38,904; all-time 142,723; newest non-yanked 0.10.0
at 2026-08-16; `rust_version` 1.85; 10 stars, 1 subscriber, 1 open issue; repository
pushed 2026-09-12T12:31:02Z; `http-api-problem` and `http-problem` declaring
`rust_version` on **zero** published versions; `http-problem` 0.3.0 requiring
`http ^0.2.8` and `axum ^0.6`; RustSec 404 for all five crates and 200 for `http`
with both 2019 advisories patched in `>= 0.1.20`; upstream CI ubuntu-only with a
1.85 MSRV job. And all four response bodies the report captured came back
**byte-identical from an independently written probe**, down to the 422's
`"… invalid type: integer \`42\`, expected a string at line 1 column 11"`.

### Couplings

- **R67 `error-and-exit-code-contract`** (published, sha256 `16947ab1…`) — consumed.
  This item maps R67's seventeen catalog rows onto statuses and carries
  `ErrorCode::as_str()` verbatim as `code`. **No `CONFLICT:` is raised**, and the
  pressure point is named rather than hidden: R67's catalog, written for a CLI, has
  no code meaning "the client's request body failed validation". The resolution is
  py's own structure — a framework rejection keeps axum's status and carries
  `RSLB201` — so `RSLB201` names one thing ("the caller's input was not usable")
  while 422, 400 and 415 distinguish *how*. Asking R67 to append
  `RSLB206 request payload invalid` is a legitimate future append against an
  append-only catalog and would cost one table row and no redesign; it is recorded
  as a documented option and a re-verify trigger, not as a needed change.
- **R69 `web-framework-stack`** (owner-accepted at revision 10, unpublished) —
  related, not a registry dependency. It fixes axum 0.8.9, tokio 1.53.1 and tower
  0.5.3, names `problems.rs` as this item's file (`…:1615`), and hands this item the
  `code` question answered at J3. See `## Parameters` for why it is not an
  `- assumes` line and what its republication changes.
- **R03 `port-absence-vs-failure-contract`** (revision 1, sha256 `610e3338…`) —
  absence is `Ok(None)` and the use case constructs `DomainError::NotFound`; this
  item's 404 row is the HTTP half of R03's AC10, which R03 explicitly assigns here.
- **R02 `crate-boundary-enforcement`** (revision 2, sha256 `9e8f8e8c…`) — the
  four-package workspace with `crates/web` depending on `core` only (`:29`) is why
  the table and the `ProblemSource` trait live in `crates/web` and not in `core`.
- **R05 `sync-async-execution-model`** (revision 3, sha256 `3ca4b81a…`) — the
  synchronous core reached through `tokio::task::spawn_blocking` is why
  `JoinError` is a funnel source and why AC11 exists.
- **R71 `openapi-generation-pipeline`** (not researched) — must document this
  envelope. Recorded affordance, not a decision for R71:
  `problem_details` carries `#[cfg_attr(feature = "utoipa", derive(utoipa::ToSchema))]`
  with `schema(inline)` on the extensions field (vendored 0.10.0
  `src/problem_details.rs:117,170`, both asserted here).
- **R75 `http-middleware-stack`** (not researched) — the one gap in W3's coverage.
  Middleware-originated errors and panics outside the blocking bridge are R75's
  and were not exercised. The rule R75 inherits: any layer added to the stack must
  render its own rejection through `WebError`, and the enforcement is a route-walk
  test that also asserts the RFC 9110 header obligations, because a layer can strip
  a header as easily as a body.
- **Being researched in parallel; stated as couplings, decided here only where
  this item owns the answer.** Their raw reports all assume this envelope and none
  contradicts it: **R80** wants `/readyz`'s 503 to reuse it and names a
  `diagnostics` extension member as its requirement on this item
  (`research/runs/R80/2026-09-17T034011Z-74765d801b92/raw/opus.md:356`) — a third
  extension member is R80's to justify, and this contract's append-only rule
  permits it; **R72** hands this item a pagination rejection type and records that
  axum's `Query` rejection today is `text/plain` and "neither RFC 9457 nor R67's
  envelope" (`…/R72/…/raw/opus.md:277,903-905`); **R73** hands over five bodies
  (400 / 409 / 413 / 422 / 503) and notes the IETF idempotency draft still cites
  RFC 7807, which RFC 9457 obsoletes (`…/R73/…/raw/opus.md:1226-1232`); **R74**
  renders its 429 through this envelope and has **no catalog code** — R67 has no
  rate-limit row, and that gap is R74's to raise, not this item's
  (`…/R74/…/raw/opus.md:146,407`); **R76** records this item as unaffected by CORS
  (`…/R76/…/raw/opus.md:706`).
- **C4 validation ownership is unresolved and is deliberately left to the owner.**
  R69 revision 10 records C4 validation as "No P02 item; pending owner scoping"
  (`…/R69/…:2400`); R53 revision 2 says the opposite — "if the web surface wants
  request validation, that is R69/R70's decision and `garde` is a live candidate
  there". Both are owner-accepted and unpublished. This decision takes no position:
  `errors` is defined producer-agnostically, so whichever reading wins, a chosen
  validator's field report fills the same member through the same
  `type Rejection = WebError` hook, with no redesign.

### Principles and implementation

**The shared requirement.** A caller must be able to handle *any* failure of this
service without knowing which layer produced it: one media type, one member set,
one place to read the machine identity. The source is py, which states the
requirement in its own module docstring — "EVERY non-2xx response body is an
``application/problem+json`` document with the same shape, including FastAPI's own
422 validation errors and bare ``HTTPException``s"
(`py src/py_launch_blueprint/web/problems.py` at pin `b08bccfb`) — implemented by
four handlers registered in `install_problem_handlers`. ts contributes nothing: it
has no web service, no dependency and no decision entry
(`docs/port/areas/web-service.md:98-100`). The verdict is `DIVERGENT` on a
one-sided precedent, which is why the research mandate (spec §2, owner amendment
A5) rather than the precedent decides the Rust shape.

**Agreement levels — what must agree and what may vary.**

| # | Principle | Agreement level | Must agree | May vary |
|---|---|---|---|---|
| W1 | Every non-2xx response carries one media type and one member set | **standard** (RFC 9457) | `application/problem+json`; the RFC's member names for the members present | whether absent members are omitted or spelled out |
| W2 | Every non-2xx response carries the failure's stable machine identity | **standard, shared with R67** | the identity is R67's `RSLB` catalog token, the same string the CLI prints | which member carries it |
| W3 | Every layer's failure — domain, framework, extractor, panic — goes through one funnel | **architectural pattern** | that no code path can emit a non-2xx body that bypassed the funnel | how many extension points the ecosystem needs to reach that |
| W4 | A domain failure's HTTP status is a reviewable table, not scattered literals | **architectural pattern** | one place, total over the published catalog, tested | `match`, trait method, or derive |
| W5 | A failure message never discloses server internals to a client | **policy** | which classes are withheld, and that the full text is still logged | the wording of the substitute |

W1, W2 and W5 are inherited from py; W3 and W4 restate py's structure so a Rust
implementation can be judged against them rather than against FastAPI's mechanics.
W4 is also **stronger than py**: py's `ERROR_STATUS: dict[type[PyError], int]` has
no completeness test, so a new `PyError` subclass silently falls to
`ERROR_STATUS.get(type(exc), 500)`.

**Observable acceptance criteria.** Fourteen were reported as executed by
`raw/opus.md`; all fourteen were **re-run here** by an independently written probe,
with two additions, and all sixteen pass. AC1 every member of `ErrorCode::ALL`
maps to a 4xx or 5xx; AC2 every `NOT_REQUEST_REACHABLE` code maps to 500 and the
list is its declared length; AC3 no 5xx code is detail-public; AC4 a domain error
renders 404 problem+json with `code`, `title`, `detail`, `instance` and **no**
`errors`; AC5 an upstream failure returns 502 with the detail replaced and neither
the upstream host nor the token anywhere in the body; AC6 `Router::fallback`
renders the envelope with `instance`; AC7 `method_not_allowed_fallback` renders it
at 405; AC8 an extractor data error renders 422 with the field detail under
`errors.body`; AC9 a JSON syntax error keeps axum's 400; AC10 a missing content
type keeps axum's 415; AC11 a panic inside `spawn_blocking` becomes `RSLB000`/500,
still enveloped, detail withheld; AC12 a 2xx response is untouched; AC13 the 405
still carries `Allow`; AC14 the 401 carries `WWW-Authenticate` *and* the envelope.
The two additions: AC15 a `Path` rejection funnels through the same hook, proving
the mechanism is per-extractor-family and not `Json`-specific; AC16 a walk over
twelve requests asserting every failing one answers `application/problem+json` and
every 2xx does not.

**Architectural alternatives, compared before any library was chosen.**

| Alt | Shape | Verdict |
|---|---|---|
| **B1** | **One RFC 9457 envelope for every non-2xx, `code` as an extension member, status from a table keyed on R67's `ErrorCode`** | **Chosen.** The only shape that preserves W1–W5 and keeps one identity string across the CLI's stderr envelope and the HTTP body |
| B2 | Mirror R67's CLI envelope verbatim over HTTP: `{"error":{"code","message","hint"?}}` | Rejected. Not RFC 9457, so W1 fails and R71 publishes a house schema; and it reuses a *stderr process* contract as a *wire* contract, which R69 revision 10 warns is a different thing (`…/R69/…:1393-1394`: "R67's envelope is the CLI process's stderr contract, not an HTTP response body") |
| B3 | RFC 9457 with the identity in `type` only | Rejected as the *sole* mechanism (J3); kept as an optional addition where a project publishes error documentation |
| B4 | Per-handler ad-hoc bodies, no single funnel | Rejected. It is what a framework gives for free and is exactly the defect py's module exists to prevent; W3 fails by construction |
| B5 | Content-negotiated envelope: problem+json for `Accept: application/json`, HTML otherwise (the owner reference's C4) | Rejected for this template (J5) |
| B6 | Map the status inside `into_response` with an inline `match` (the owner reference's wiring block) | Rejected (J4) |

**Is the shared pattern still appropriate in Rust?** The check is not rhetorical.
Against: the first-party tier offers no help — the vendored sources of `axum`
0.8.9, `axum-core` 0.5.6, `tower` 0.5.3 and `hyper` 1.11.1 contain **zero**
case-insensitive matches for `problem+json` (asserted, `probe.log` section 6) — and
Rust's most visible single-org HTTP framework ships a bespoke body. For: an IETF
Proposed Standard with registered media types; a well-regarded Rust service at
ISRG using it; a template whose purpose is to be copied, where a documented
standard beats a house shape; and R71 must publish a schema for the error body
either way, so a standard shape is the one a generated client already understands.
**Keep the pattern.**

**The landscape, and the one fact that decides how to weigh it.** The category has
four RFC 9457 crates and **no dominant one**: the largest by all-time downloads
(`http-api-problem`, 62 stars) has had no release since 2025-01-06 and declares no
`rust_version`; the most actively maintained (`problem_details`) has 10 stars.
There is not enough adoption in this category to discriminate, which is why the
fitness gates and the executed check carry the decision rather than popularity.

**Fitness gates, per candidate, before popularity.**

| Gate | `problem_details` 0.10.0 (recommended) | `problemdetails` 0.7.0 (runner-up) |
|---|---|---|
| 1 — licence | `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool` | same ruling, same disposition |
| 2 — MSRV | **Pass.** Declares `rust-version = "1.85"`; current stable is 1.98 (`channel-rust-stable.toml`, `date = "2026-09-03"`), so the floor is 1.96 and 1.85 ≤ 1.96. Executed: the probe declared `rust-version = "1.96"`, Cargo reported `Locking 56 packages to latest Rust 1.96 compatible versions`, **and the whole workspace compiled and its sixteen tests ran under rustc 1.96.0** | **Pass.** Declares `rust-version = "1.85.1"` |
| 3 — advisories and `unsafe` | **Pass.** `https://rustsec.org/packages/problem_details.html` returns 404, as does `http-serde`; `#![forbid(unsafe_code)]` at `src/lib.rs`, so the compiler rejects `unsafe` outright | **Pass.** RustSec 404 |
| 4 — OS matrix | **Pass, with the gap recorded.** Upstream CI is `ubuntu-latest` for every job and has **no macOS runner**; macOS is covered here by execution instead — macOS 26.4, `aarch64-apple-darwin`, sixteen tests passing. Windows: untested, not required | not separately executed |
| 5 — default features, runtime coupling | **Pass.** Defaults `["serde", "json"]`; this template adds `axum` and keeps them. **No async-runtime coupling** — the crate names no runtime, and its axum dependency is `{ version = "0.8", default-features = false, features = ["json"] }`, so it does not widen R69's owned feature list (asserted from the crates.io dependency endpoint) | pulls `serde_json/preserve_order`, dragging `indexmap` in for a property this envelope does not need |
| 6 — binary size, compile cost | **Pass.** Adds exactly one crate to a tree that already has axum, serde and serde_json: `http-serde` v2.1.1, whose only dependencies are `http` and `serde` (executed tree diff). All of it sits behind R69's optional member, so none reaches a default build | comparable |

**Excluded by gate.** `http-api-problem` 0.60.0 — **fails gate 2**: zero of its
published versions declare `rust_version` (asserted). Recorded against the
exclusion because it is the strongest candidate on every other axis: the highest
adoption in the category, in production at ISRG, `axum-core ^0.5.0` current for
axum 0.8, no advisory. Its maintenance rubric is **stable-quiet**, not at-risk — 20
months without a release is a trigger to investigate, and the investigation found
no advisory, no archive flag, no maintainer notice and current dependencies.
`http-problem` 0.3.0 — **fails gate 2** and is **at-risk** on a retrieved signal:
its manifest requires `http ^0.2.8` and `axum ^0.6` against this template's `http`
1.5.0 and axum 0.8.9, so it cannot enter the tree without a second, incompatible
`http` major. `rfc7807` 0.0.1 — fails gate 2, 17 all-time downloads, no repository
field, so gates 3, 4 and 6 cannot be evaluated at all.

**Maintenance state.** `problem_details`: **active** — release 0.10.0 on
2026-08-16, repository pushed 2026-09-12, one open issue, CI that denies warnings,
runs clippy, builds every feature in isolation with `cargo hack`, pins an MSRV job
at 1.85 and dry-runs `cargo publish`. Issue responsiveness rests on **three**
issues, because the repository has only three non-PR issues in its whole history;
the rubric's ten-item window is mostly pull requests. That is stated rather than
padded.

**The evidence gap, named rather than softened.** There is **no well-regarded
public adopter** of `problem_details`, and no public repository was found pairing
it with axum 0.8.9. Its two reverse dependents are not reference projects. The
category's one genuinely well-regarded adopter — ISRG's `divviup/janus` — uses the
*excluded* crate. The compensating evidence is the executed probe plus the crate's
own dev-dependency suite, which tests against `axum` 0.8 and `utoipa-axum` 0.2 —
the exact pairings R69 and R71 need.

**Performance.** No latency or throughput figure is claimed and none was measured.
The envelope is a single `serde_json` serialization of a struct with at most seven
members, on a path taken only by failing requests, behind the same `Json` writer
axum uses for success bodies. A throughput comparison between this and a
hand-rolled struct would be measuring `serde_json`, not this decision.

**The owner reference, row by row.** The document is a standing input that binds
process, not outcome (`docs/planning/p02/owner-decisions.md` §11: "an
owner-supplied research input, not a binding standard and not a pre-decision");
owner-fixed parameters override any value it states. The report tallies **3 agree,
2 agree-with-additions, 7 differ**; each cited line was re-read and the tally
holds. The seven differs and what each rests on:

| Reference row | Verdict | Ground |
|---|---|---|
| `:54`, `:93` — "most such crates unmaintained; hand-roll the small struct" | **differ** | The *premise* fails for the current field, on figures re-fetched 2026-09-18: `problem_details` 0.10.0 released 2026-08-16 and its repository pushed 2026-09-12. It holds for `http-api-problem` (2025-01-06) and `http-problem` (2023), which are the two this decision excludes anyway. The reference's instinct is preserved as the escape hatch |
| `:93` — content negotiation, "a rendered HTML page for browser/HTMX requests" | **differ** | J5; R69's accepted surface has no templating or HTML route, and R69 records templating as having no P02 item |
| `:274-283` — status and title from an inline `match &self` inside `into_response` | **differ** | J4; the table is a separate `const fn` the coverage test calls directly |
| `:271` — `#[error(transparent)] Other(#[from] anyhow::Error)` in the web error type | **differ** | R67's layering rule is explicit: "`anyhow` … in binary crates only; the library crate must not depend on `anyhow`". `crates/web` is a library. The unexpected path is `RSLB000`/500 with the cause logged |
| `:186` — `thiserror = "2"` in the web manifest | **differ** | `thiserror` stays where R67 put it, the library crate; `crates/web`'s error type is a struct with no derive macro and needs none |
| `:270` — `Db(#[from] sqlx::Error)` | **differ (not applicable)** | No database in this template; databases are in the reference's own "no P02 item" set |
| `:238` — layout `src/error.rs` | **differ** | `crates/web/src/problems.rs`, the path R69 revision 10 already assigns to this item (`…:1615`) |

And the row this decision explicitly does **not** rule on: `:53`'s
"garde + axum-valid 0.24" validation stack — see the C4 coupling above.

**Minimal realistic example.** `crates/web/src/problems.rs` plus two lines in
`build_router` and one `impl ProblemSource` in the core crate. Its executable
acceptance check is the sixteen criteria in `## Empirical check`; what they prove
and what they do not is stated there.

**The trigger set, and which member of it is the binding one.** Nine events would
send a reader back to part of this decision, and they are recorded where they
belong rather than piled into one line: R69 republishing `web-extra-surface` moves
the file paths only (`## Parameters`); R71 selecting an OpenAPI generator, R75
publishing its layer stack, R80 justifying a third extension member and the owner
settling C4 validation each land in `### Couplings`; a RustSec advisory against
`problem_details` or `http-serde`, `http-api-problem` publishing a version that
declares `rust-version`, and an axum minor release changing a rejection's default
status are each noted at the gate or criterion they would move. **Only two events
move the recommendation itself**: R67 appending a request-validation catalog row,
which would shift the 422 identity off `RSLB201`; and `problem_details` falling
dormant, which would make the hand-rolled struct the member. Those two are the
binding trigger.

re-verify: R67 appends a request-validation catalog row, or problem_details goes 12 months from 2026-09-12 with no release or repository push

## Parameters

This item registers no parameter of its own: the prompt's `- owns:` line is empty,
so there is no `owns` line. The five lines below are the four `fixed` registry rows
plus the one row the prompt's `- consumes:` line names, which is the complete set
the acceptance grammar allows.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.

**No `CONFLICT:` line.** The recommendation needs no consumed value changed. The
one place pressure could have produced a conflict — R67's catalog having no code
meaning "the client's request body was invalid" — is resolved inside this item by
taking the framework's own status for a framework rejection while carrying
`RSLB201` as its identity, which is py's own three-source structure. An append of a
dedicated request-validation code remains available to R67 later and would cost one
table row.

**`web-extra-surface` is deliberately not an `- assumes` line.** The prompt's
Couplings declare `- consumes: R67: error-taxonomy-exit-codes` and place R69 under
`- related (not a registry dependency)`, and the packaging validator computes the
expected `assumes` set as exactly the `fixed` rows plus the prompt's consumed rows.
R05 revision 3 records the same reasoning in the same situation.

**R69's value nonetheless binds this design, and the binding is stated rather than
hidden.** The `web-extra-surface` row in `docs/port/PARAMETERS.md` is one revision
behind its owner-accepted value: it still reads `web = ["dep:axum", "dep:tokio"]`
with the gated tree at `src/web/`, the tests at `tests/` and skip-gating on
`src/web/**`. **R69 revision 10** (sha256 `d34ab6e8…`, the `- owns web-extra-surface`
line at `:1791`, owner-accepted W0-R69c, not yet published) replaces that with
`web = ["dep:rs-launch-blueprint-web"]`, `axum 0.8.9` and `tokio 1.53.1` declared
non-optionally inside `crates/web/Cargo.toml`, the gated tree at `crates/web/src/`,
the web tests at `crates/web/tests/` and skip-gating on `crates/web/**`. **Every
path in this decision uses revision 10's form**, and the probe workspace was built
in revision 10's topology. **This is not a conflict**: R69's change is already
ruled and in flight, and this recommendation is unaffected by which mechanism
lands, because the envelope, the table and the funnel all sit inside the gated tree
wherever that tree sits. R69's republication is a re-verify trigger for the file
paths in the migration list and for nothing else.

**Two other owner-accepted, unpublished values bind this design and are likewise
not `- assumes` lines**, because neither registers a parameter this item consumes:
R02 revision 2 (sha256 `9e8f8e8c…`) fixes the four-package workspace and
`crates/web` "Depends on `core` only" (`:29`); R05 revision 3 (sha256 `3ca4b81a…`)
fixes the synchronous core reached through `tokio::task::spawn_blocking`.

**Migration implications, at R69 revision 10's paths.** Nothing outside
`crates/web` changes except one trait impl.

| Path | Change |
|---|---|
| `crates/web/Cargo.toml` | one `[dependencies]` line: `problem_details = { version = "0.10.0", features = ["axum", "json"] }`. No `optional = true` — the whole member is already optional at the root |
| `crates/web/src/problems.rs` | **new**, and the only file that names `problem_details`. `ProblemExt`, `pub type Problem`, `pub trait ProblemSource`, `pub struct WebError` with its builders and `log_detail`, `impl IntoResponse for WebError`, `pub const fn http_status`, `pub const fn detail_is_public`, `pub const NOT_REQUEST_REACHABLE`, `From<JsonRejection>`/`From<PathRejection>`/`From<QueryRejection>`, `ProblemJson<T>`/`ProblemPath<T>`/`ProblemQuery<T>`, `not_found`, `method_not_allowed`, `join_error_to_web_error`, and the `headers` field with its `with_header` builder that RFC 9110's `WWW-Authenticate` obligation requires |
| `crates/web/src/lib.rs` | `mod problems;` plus re-exports, and two lines in `build_router`: `.fallback(problems::not_found)` and `.method_not_allowed_fallback(problems::method_not_allowed)` |
| `crates/web/src/routes/*.rs` | handler return types become `Result<Json<T>, WebError>`; input extractors become the `Problem*` newtypes; the `spawn_blocking` join result maps through `join_error_to_web_error` |
| `crates/core/src/error.rs` | one `impl ProblemSource for <domain error>` — about six lines, **the only change outside `crates/web`**. If a strict reading of R02's "depends on `core` only" is preferred, the impl moves into `crates/web`, since the trait is defined there |
| `crates/web/tests/problems.rs` | **new**: the sixteen criteria below, retargeted at R67's real catalog |
| `docs/` | one page documenting the envelope, its members and the status table — owned by R81, listed so the obligation is visible |

Not created by this item: `openapi.rs` (R71), the middleware stack and its
rejection rendering (R75), `/readyz`'s failure payload (R80), and a validator with
its `errors` report (ownership unresolved, above).

## Empirical check

**Verification, not implementation.** Nothing here builds the template. The probe
is a throwaway two-crate workspace created under `$TMPDIR` and deleted on exit,
whose only purpose is to decide whether what the single raw report asserts is true.

**Toolchain and host.** macOS 26.4, `aarch64-apple-darwin`.
`rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`, and `rustc 1.96.0 (ac68faa20
2026-05-25)` via `rustup run 1.96.0` for the MSRV-floor build.
`grep (BSD grep, GNU compatible) 2.6.0-FreeBSD` at `/usr/bin/grep`,
`curl 8.7.1`, `Python 3.14.7`, `ShellCheck 0.11.0`. All runs 2026-09-18 UTC.
Working directory for every command:
`research/runs/R70/2026-09-17T034010Z-31ad2ef28df7/review/evidence/`.

| Script | Command | Result | Log |
|---|---|---|---|
| `registry.sh` | `./registry.sh > registry.log 2>&1` | **PASS 65, FAIL 0, SKIP 0, exit 0** | `review/evidence/registry.log`, moving counters in `review/evidence/registry-figures.log` |
| `probe.sh` | `./probe.sh > probe.log 2>&1` | **PASS 33, FAIL 0, SKIP 0, exit 0** | `review/evidence/probe.log` |
| `archive-check.sh` | `./archive-check.sh > archive-check.log 2>&1` | **PASS 11, FAIL 0, SKIP 0, exit 0** | `review/evidence/archive-check.log`, with the reruns at `registry-archive.log` and `probe-archive.log` |

All three are `set -euo pipefail` with `set -o pipefail` restated, assert on
content rather than on exit status, count PASS/FAIL/SKIP, sum them and exit
non-zero on any FAIL. All three are `shellcheck` 0.11.0 clean. No script contains a
personal email address or a token; the `User-Agent` sent to crates.io is the
repository URL `https://github.com/smorinlabs/rs-launch-blueprint`. GitHub REST is
reached through keyring-authenticated `gh api` at no more than one call per 20 s.

**`registry.sh` — 65 checks re-verifying the published record.** crates.io
`/crates/<name>`, `/versions`, `/<v>/dependencies` for `problem_details`,
`problemdetails`, `http-api-problem`, `http-problem` and `rfc7807`;
`static.rust-lang.org`'s stable channel manifest, from which the 1.96 floor is
re-derived rather than assumed; `rustsec.org/packages/<name>.html` for five crates
plus the two `http` advisories read from `advisory-db`; RFC 9457 at the datatracker
(`std_level`, `stream`, `title`) and at the RFC Editor, where every load-bearing
sentence is matched **after collapsing whitespace**, because the RFC body is
hard-wrapped and a line-oriented `grep` cannot see a sentence that spans a break;
the IANA `application` media-types registry; RFC 9110's two `MUST` sentences and
the 401-versus-403 pair, with the three section headings pinned at the exact line
numbers `raw/opus.md` cites (7548, 7569, 7601 — all three correct); and five
`gh api` reads covering the repository's archived flag, its open-issue count,
`divviup/janus`'s manifest, `oxidecomputer/dropshot`'s error type and the crate's
own CI workflow.

**`probe.sh` — 33 checks, of which the sixteen acceptance criteria are one.** It
writes a three-member workspace under `$TMPDIR` (`r70core` holding a 17-row
stand-in for R67's catalog with `ALL` and `as_str`; `r70web` holding the envelope,
the table and the funnel; `r70ctl`, a control member with the identical
dependencies **minus** `problem_details`), then:

1. builds and tests the workspace under **rustc 1.96.0** — this closes the
   report's own stated gap (1) — with `Locking 56 packages to latest Rust 1.96
   compatible versions` asserted, and `16 passed; 0 failed`;
2. builds and tests it under the host stable toolchain, asserting `16 passed;
   0 failed` **and that the build emits no `warning:` at all**;
3. runs a `dump` example that prints four response bodies and asserts each one
   against the literal `raw/opus.md` captured, plus that no body carries a `type`
   member and none carries a `null`;
4. diffs the resolved trees of `r70web` and `r70ctl` and asserts the added set is
   exactly `http-serde v2.1.1 problem_details v0.10.0`, that axum resolves to
   0.8.9 and tokio to 1.53.1, and that `problem_details` is named from
   `problems.rs` and nowhere else;
5. proves the `#[non_exhaustive]` claim **in both directions** — a purpose-built
   single-crate build whose `_` arm draws `unreachable pattern … no value can
   reach this`, against the cross-crate build where the identical arm draws
   nothing;
6. asserts eleven source facts in the vendored crates at their exact cited lines —
   `#![forbid(unsafe_code)]`, `CONTENT_TYPE`, the two `utoipa` attributes at
   `problem_details.rs:117,170`, the three axum rejection statuses at
   `rejection.rs:11,23,34`, `Router::fallback` at `routing/mod.rs:345`,
   `method_not_allowed_fallback` at `:374`, and that **no** crate in the framework
   tree mentions `problem+json`.

The four bodies, captured verbatim by this run:

```
GET /projects/demo -> 404 Not Found application/problem+json
{"status":404,"title":"Not Found","detail":"project 'demo' not found","instance":"/projects/demo","code":"RSLB301"}
GET /upstream -> 502 Bad Gateway application/problem+json
{"status":502,"title":"Bad Gateway","detail":"An unexpected error occurred.","instance":"/upstream","code":"RSLB103"}
POST /projects -> 422 Unprocessable Entity application/problem+json
{"status":422,"title":"Unprocessable Entity","detail":"Request validation failed.","code":"RSLB201","errors":{"body":["Failed to deserialize the JSON body into the target type: name: invalid type: integer `42`, expected a string at line 1 column 11"]}}
DELETE /ok -> 405 Method Not Allowed application/problem+json
{"status":405,"title":"Method Not Allowed","detail":"This method is not allowed for this path.","code":"RSLB201"}
```

The `/upstream` handler's domain message is
`GET https://api.example.com/x?token=s3cret failed: 500`; AC5 asserts that neither
`s3cret` nor `api.example.com` occurs anywhere in the response body, and neither
does. That is the executed form of py's SEC-4 rule.

**Reproduction, stated as a claim that can be kept.** `archive-check.sh` extracts
`git archive HEAD` into a clean `$TMPDIR` tree — asserting first that the worktree
marker exists (a worktree's `.git` is a **file**, tested with `-e`, not `-d`) and
that the extraction contains no nested repository — runs both scripts *there*, and
diffs their output against the committed logs. It passes 11 of 11: both scripts
exit 0 from the extraction; `registry.log` and `registry-archive.log` are
**identical below the three-line banner** (line 2 carries the run date); and
`probe.log` and `probe-archive.log` **agree on every one of the 33 verdicts and on
every captured body**, compared line-for-line rather than asserted. The probe log's
banner does move — it carries the run timestamp and the scratch directory's random
suffix — and the resolver's `Locking 56 packages` line is printed only against a
cold registry, which is why the probe comparison is over the verdict and body lines
rather than over the whole file; the rule is stated in the script beside the check
that applies it. The moving registry counters — download totals, star count,
`pushed_at`, the open-issue total — are deliberately kept out of the diffed log and
written to `registry-figures.log`, which is a dated snapshot and is **not** claimed
to reproduce. This paragraph is written after running the comparison, not before:
the first attempt **failed**, because the committed `registry.log` predated a fix to
one RFC 9110 phrase; the log was regenerated and the comparison re-run.

**What these checks do not prove, and is therefore left for P03.**

- **No Linux execution.** Everything here ran on macOS. `problem_details`'s
  upstream CI covers `ubuntu-latest` and does not cover macOS, so the two halves of
  `target-os-matrix` are covered by different evidence.
- **No feature-off tree.** The probe has no Cargo feature, so "the crate is absent
  from a default build" is inherited from R69's and R05's measurements, not
  re-measured here.
- **No route-walk over a real router.** AC16 walks twelve hand-listed requests, not
  an enumeration of `build_router`'s routes. The mechanical form of W3 is a P03
  test.
- **No `cargo-deny` run.** Advisories were verified by RustSec page and
  `advisory-db` raw file, not by R13's tool, which is not yet wired.
- **No middleware-originated error.** Those are R75's.

## Engines

`opus raw/opus.md` — Claude Opus 5, sha256
`82538638b5f54017c22853eb9e52e6d4e6c71b78e35fad8ed6ea68be3fefe39e`, written
2026-09-18, shape-checked against the bundle template with four `####` members.

**The Codex leg is absent by the controller's deferral under owner ruling
W1-CODEX3 (2026-09-18)** — the Codex account is at its usage limit and the ruling
is to proceed without it. This item's policy tier is Focused, whose engines are
`codex` and `opus`, so **this decision is synthesized from a single engine and
there are no inter-engine disagreements to settle.** That is a real weakening of
the evidence: nothing here was independently checked by a different model family
before synthesis. The compensation is that the synthesizer re-verified every
load-bearing claim at source rather than carrying it — 65 registry checks and 33
probe checks, listed above — and the three things that came back wrong are
tabled under `### Corrections to raw/opus.md`.

**Re-verified by this synthesis** (claim → where it was checked): every crates.io
figure and every gate-2 exclusion; the RustSec posture of all five crates; the
`#![forbid(unsafe_code)]` posture; the 1.96 MSRV floor, re-derived from the live
stable channel; RFC 9457's standards status, its IANA registration, its
`about:blank` rule, its extension-member clause and the true numbering of §3.1.1
to §3.1.5; RFC 9110's `Allow` and `WWW-Authenticate` `MUST`s and the
401-versus-403 pair; `divviup/janus`'s and `oxidecomputer/dropshot`'s current
sources; the crate's ubuntu-only CI and its 1.85 MSRV job; the absence of
problem-details support anywhere in the framework tree; the cited line numbers in
the vendored `problem_details` and `axum` sources; the cross-crate
`#[non_exhaustive]` behaviour, in both directions; the dependency cost, by tree
diff against a control member; and all fourteen acceptance criteria, re-run from
an independently written probe, plus two additions — and **better than the report
on one axis**, because the suite also compiled and ran at the 1.96 MSRV floor,
which the report explicitly could not do.

**Carried from the report without independent re-verification**, each with what
would prove it:

| Carried claim | What would prove it |
|---|---|
| py's `problems.py` at pin `b08bccfb` — the docstring, the four handlers, `ERROR_STATUS`, the SEC-4 comment | reading `py src/py_launch_blueprint/web/problems.py` through the pin in the py checkout, which is outside this repository and therefore outside a `git archive` rerun |
| Issue-responsiveness medians (4.49 d median, zero unanswered, over three issues) | re-reading the `/issues` and `/issues/{n}/comments` endpoints; the open-issue **count** was re-fetched here, the medians were not |
| The report's own compile-cost figures (0.75 s dev build, 224,880-byte debug rlib) | a timed `cargo clean -p && cargo build -p`; this synthesis measured the dependency *count* instead, which is the figure the decision actually uses |
| That `explicit-error-http`, `problem-details-mapper` and `zekurix-server` are the only reverse dependents | re-reading the `reverse_dependencies` endpoint; the adopter *gap* is what the decision relies on, and that is stated as a gap either way |

**Unproven, and left for P03 to prove in the real template.** The five items under
"What these checks do not prove" above, and specifically: `cargo build --features
web` and `cargo test --features web` against the real crate; `cargo tree -i
problem_details` with `web` off, showing the crate absent from the default tree; a
route-walk test issuing a malformed request to every route in `build_router` and
asserting the content type **and** the RFC 9110 header obligations; the same suite
on `ubuntu-latest`; `cargo deny check advisories` once R13's tool is wired; and a
snapshot test over one body per distinct status so an accidental member rename
fails a test rather than a client.

**Where the evidence is incomplete, stated plainly.** Confidence is **high** that
the envelope-plus-table-plus-funnel design is correct and implementable at R69's
pinned versions on macOS at both 1.96 and 1.98 — that is executed, not argued.
Confidence is **medium-high** on `problem_details` as the document type: six gates
cleared, one of them by execution rather than by upstream CI, with the residual
risk concentrated and named — one maintainer, 10 stars, 1 subscriber, no
well-regarded public adopter — and mitigated structurally by the containment rule
rather than verbally. Confidence is **medium** on the individual status rows, which
are proposals, and **medium** on the funnel's completeness, because
middleware-originated errors belong to R75 and were not exercised. The single
question this decision deliberately leaves to the owner is who owns C4 validation.
