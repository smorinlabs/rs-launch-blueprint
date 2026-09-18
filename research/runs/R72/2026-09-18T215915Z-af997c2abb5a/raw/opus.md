# R72 — api-pagination (bundle) — Opus research report

### Landscape

**The category this item decides.** The *collection contract* of the template's web
surface: the query parameters a client sends to walk a collection, the JSON body a
collection route returns, where the continuation state lives, and where in the
four-package workspace each of those three pieces is declared. It is a contract
decision first and a library decision second — the library question ("is there a
`fastapi-pagination` for Rust?") is answerable only once the contract is fixed,
because the candidate crates disagree with each other about the contract.

**The finding that reorders everything below, stated first.** The organization
publishes a released **REST API Design Standard, version 2.0.0**, whose §6
("Collections, pagination, filtering, and sorting") fixes the pagination contract
for a conforming HTTP API — and it fixes it as **`cursor` + `limit` in, `items` +
continuation out**, not as py's `page`/`size` + `items`/`total`. The standard is
the sibling of the org **CLI Design Standard**, which R67's published value already
treats as binding ("per the org CLI Design Standard R6.1, org-locked",
`docs/port/PARAMETERS.md`, `error-taxonomy-exit-codes` row) and which R69's accepted
revision 10 parses the serve binary's global core against ("the org CLI Design
Standard v1.4.14 R4.1 required global core",
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791`). The two
standards live in sibling repositories owned by the same organization
(`github.com/smorinlabs/rest-standards` and `/Users/stevemorin/c/cli-standards/cli-design-standard.md`),
and the REST standard's own R1.3 assigns `CLI-`-prefixed rule IDs to the CLI standard,
so each names the other. By that parity the REST standard binds the template's HTTP
surface exactly as the CLI standard binds its command line. **No P02 document names
it** — a search of `docs/` and of every published `DECISION.md` and run-directory
`review/DECISION.md` returned no reference (2026-09-18) — so this report does not
claim it is an already-recorded programme input. It states the parity argument, makes
the conformant design the recommendation, and carries py's shape as the ranked
runner-up should the owner rule the standard does not reach this template. The owner
question is named once here and once under *Confidence & re-verify trigger*.

Pinned source, since the standard has no public URL:
`/Users/stevemorin/c/rest-standards/rest-api-standard.md`, repository
`https://github.com/smorinlabs/rest-standards.git`, commit
`0850d43e45d919ef5e37f7174c4212b46013c49f` (committed 2026-09-05), no tag at HEAD,
file header `**Version 2.0.0**`, `CHANGELOG.md` dating 2.0.0 to 2026-08-12. Read
2026-09-18.

**The three-bin map of the Rust field.**

| Bin | Candidates found | What the bin actually contains |
|---|---|---|
| Built-in / first-party toolchain | `axum` 0.8.9's `extract::Query` and `extract::FromRequestParts`/`FromRef` (R69's selected framework, `query` in its default feature list); `serde` derive; a hand-written generic envelope struct; `base64` 0.23.1 for the opaque token | Everything the contract needs *except* range validation and an opaque-token codec. Verified by probe, not asserted — see *Validation strategy* |
| Established industry standard | **Empty for this category.** There is no widely adopted Rust pagination extractor crate. The nearest analogues are framework-*specific* first-party helpers inside larger products: `oxidecomputer/dropshot`'s `ResultsPage<T>`, `rust-lang/crates.io`'s own `src/controllers/helpers/pagination.rs`, `sea-orm`'s `Paginator`. None is a standalone reusable extractor | The absence is the answer to HIGH-1, and it is a positive finding rather than a search failure: a `fastapi-pagination` equivalent cannot exist in Rust's typed-response model in the form py has it (see *Principles and implementation*) |
| Up-and-comer | `paginator-rs` / `paginator-utils` / `paginator-axum` / `-actix` / `-rocket` / `-sqlx` / `-sea-orm` 0.4.0 (2026-09-07); `api-bones` 6.12.0 (2026-08-16); `axum-api-kit` 2.2.0 (2026-08-12); `sqlx-paginated` 0.6.2 (2026-08-17); `axum-valid` 0.25.0 (2026-06-30) for the range check; `page-turner` 1.0.0 (2024-01-15, client-side) | Every one of these is younger than two years in its current shape; three of the four families were first published in 2026. Each is dispositioned by name under *Excluded by gate* / *Ranked runner-up* in the members below |

Exhaustiveness check on the map: `GET https://crates.io/api/v1/crates/<name>` returned
`404` for `axum-pagination`, `axum_pagination`, `pagination-rs`, `cursor-pagination`
and `seek-pagination` (retrieved 2026-09-18). Full-text searches
`GET https://crates.io/api/v1/crates?q=<q>&per_page=25&sort=downloads` for
`pagination`, `paginate`, `cursor pagination`, `keyset`, `axum pagination`,
`cursor paginate axum`, `page size envelope` and `opaque cursor` (2026-09-18)
surfaced no candidate outside the table.

**Authoritative sources used, and why each counts.**

| Source | Why authoritative |
|---|---|
| Org **REST API Design Standard v2.0.0** §6, §1.7–§1.10, §11, §12, Appendices C/D/E (pinned sha above) | The organization's own released standard, versioned by an explicit Part II amendment rule, with a `CHANGELOG.md` and a 145-rule conformance checklist. It is the same artefact class R67 and R69 already bind to on the CLI side |
| `rust-lang/crates.io`, `src/controllers/helpers/pagination.rs` (732 lines, fetched from `raw.githubusercontent.com/rust-lang/crates.io/main/…`, 2026-09-18) | The Rust project's own registry service — a production Rust HTTP API maintained by the Rust infrastructure team. Not a blog post; the running code behind every `cargo` command |
| `oxidecomputer/dropshot` 0.17.1 (`docs.rs/dropshot/0.17.1/dropshot/struct.ResultsPage.html`, 2026-09-18) | Oxide Computer's production API framework, 1 202 stars, pushed 2026-09-18, the server framework behind a shipping hardware product's control plane |
| `axum` 0.8.9 source behavior, measured (probe below) | R69's accepted framework. Behavior read from execution, not from documentation |
| RustSec advisory database (`rustsec.org/packages/<name>.html`, and `rustsec/advisory-db` raw files) | The Rust Secure Code WG's registry; gate 3's authority |
| `py-launch-blueprint` at pin `b08bccfb`, and `fastapi-pagination` 0.15.15 as resolved in its `uv.lock` | The source precedent this item is measured against, read at the programme's pin |

A single maintainer's README is treated as a lead throughout; every figure below
carries its endpoint and retrieval date.

**Well-regarded projects surveyed, with the evidence that they are well regarded.**

- **`rust-lang/crates.io`** — the Rust project's registry. Its pagination helper
  supports both a legacy `?page=` mode and a `?seek=` opaque-token mode, with
  `const DEFAULT_PER_PAGE: i64 = 10` (line 21), `const MAX_PER_PAGE: i64 = 100`
  (line 22), a bot guard at `MAX_PAGE_BEFORE_SUSPECTED_BOT: u32 = 10` (line 20),
  and the token encoded as
  `general_purpose::URL_SAFE_NO_PAD.encode(serde_json::to_vec(&params)?)`
  (`fn encode_seek`, line 331–334). An over-maximum `per_page` is **rejected**, not
  clamped: `if per_page > MAX_PER_PAGE { … "cannot request more than {MAX_PER_PAGE} items" }`
  (lines 151–153); an undecodable token is `bad_request("invalid seek parameter")`
  (`impl RawSeekPayload::decode`). Regard evidence: it is the registry every figure
  in this report was fetched from.
- **`oxidecomputer/dropshot`** — 1 202 stars, `archived: false`, `pushed_at`
  `2026-09-18T12:52:59Z`, 58 open issues
  (`GET https://api.github.com/repos/oxidecomputer/dropshot`,
  `GET https://api.github.com/search/issues?q=repo:oxidecomputer/dropshot+is:issue+is:open`,
  retrieved 2026-09-18T22:22:10Z); 858 644 all-time / 128 982 recent downloads
  (`GET https://crates.io/api/v1/crates/dropshot`, 2026-09-18). Its
  `ResultsPage<ItemType> { next_page: Option<String>, items: Vec<ItemType> }` is
  generic over the caller's item type and its documentation says the page-selector
  function "accepts arguments aimed at supporting keyset pagination". Regard
  evidence: adoption, maintainer standing (Oxide Computer), and continuous pushes.
- **`py-launch-blueprint`** at pin `b08bccfb` — the source precedent, read through
  the pin as the role file requires.

**Fit over abstract best.** The template is CLI + library + web service with **no
database** (R02's `crates/core` external-dependency allow-list; R05's synchronous
port over `ureq`) and exactly one collection route, `GET /v1/projects`. That single
fact disqualifies the whole DB-coupled half of the field (`sea-orm::Paginator`,
`sqlx-paginated`, `paginator-sqlx`, `paginator-sea-orm`) on fit before any gate is
applied, and it also bounds what "correct pagination" can mean here — the collection
the service pages over is a `Vec<Project>` already materialized from one upstream
fetch. That limit is inherited from py and is stated honestly in
*Principles and implementation* rather than papered over.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is needed.**

py's principle, extracted from the code rather than from the ledger row: *a
collection route returns a uniform envelope whose items are the same core-model
objects every other surface renders, the pagination parameters have one name
everywhere, and the machinery is declared once rather than re-stated per route.*
Source evidence, all at pin `b08bccfb`:
`src/py_launch_blueprint/web/routers/projects.py:30` — `from fastapi_pagination import Page, paginate`;
line 204 of `src/py_launch_blueprint/web/app.py` — `add_pagination(app)`;
`docs/design/0002-web-api-conventions.md:29-32` — "**WEB-03 — collections paginate**
with fastapi-pagination's standard envelope: `page`/`size` query params,
`items/total/page/size/pages` body. Items remain `core.models` objects — the CLI and
API share one data contract; only the collection envelope is web-specific." `ts` has
no web service (`docs/port/areas/web-service.md:100`), so there is nothing to
reconcile with on that side; ledger rows F310 and F311 are `py-only · DIVERGENT`
(`docs/port/COMMONALITY.md:314-315`), which is why this item is free to select a
design rather than inherit one. `docs/port/BASELINE-REVIEW.md` carries no F310 or
F311 row, and correctly so: that file adjudicates `COMMON → REUSE` and `ADOPT` rows
only (`docs/port/README.md`, item 11). **No `BASELINE-REVIEW:` finding is emitted by
this item.**

**Agreement level.** Three distinct levels, and conflating them is the error this
item most needs to avoid:

| What | Level | May vary |
|---|---|---|
| A collection response is an object with the items and the continuation state, never a bare array; items are the caller's own domain type | **Capability + contract** — agreement required across py, ts and rs | nothing about the shape; the member *names* are a separate row |
| The parameter and member names (`cursor`/`limit`; `items`/`next_cursor`) | **Policy**, fixed by the org standard for rs; py chose `page`/`size`/`total` before the standard existed | nothing, once the standard binds |
| How the machinery is applied uniformly to every collection route | **Capability only** — "declared once, not restated per route" | the mechanism entirely: a Python framework registers a response-model factory app-wide; Rust cannot, and must not pretend to |

**What the org standard actually requires, separated by strength — because the
distinction is load-bearing and easy to overstate.**

| Rule | Strength | Text (abridged, quoted from the pinned file) |
|---|---|---|
| R6.1 | **MUST** | "Every collection response MUST return a top-level object carrying both the items and the continuation state — never a bare array" |
| R6.2 | **MUST** | "An empty collection returns `200 OK` with an empty items array — never `404 Not Found`" |
| R6.3 | **SHOULD** | "Pagination SHOULD use opaque, non-constructable cursors — offset pagination is incorrect under concurrent mutation." Exception: small or stable collections, or UI requiring jump-to-page, and only "where the contract documents the property claimed" |
| R6.4 | **MUST NOT** | "RFC 8288 `Link` headers MUST NOT be emitted for pagination — dual emission creates two places a cursor can live, which drift under maintenance" |
| R6.5 | **MUST** (naming, via R1.8) | "The pagination request parameters are `cursor` and `limit` (§1.10). Each collection MUST document its default and maximum `limit`" |
| R6.6 | **MUST** | "Every collection MUST document a total, stable default order, with ties broken by an immutable key (`id`)" |
| R11.1 | **MUST** | "An API MUST publish and enforce a maximum page size, expansion depth, and bulk item count" |
| R1.8 | **MUST** | "A conforming API MUST NOT use a reserved name for any purpose other than the meaning registered here, and when it offers the corresponding capability it MUST use the reserved name rather than a synonym" — §1.10 registers `cursor` ("Opaque pagination position") and `limit` ("Requested page size") |
| R12.5 | **MUST** (client side) | "Clients MUST treat cursors (R6.3) as opaque: never construct, modify, or persist them beyond their documented lifetime" |

**Two things the standard does *not* say, recorded so the recommendation is not
read as stronger than its source.** First, **`items` and `next_cursor` are not
reserved names.** §1.10's register contains `sort`, `fields`, `cursor`, `limit`,
`dry_run`, `stream`, `stream_position` and the bracket range filters — no response
body member. The member names appear only in Appendix C ("`items` + continuation
out"), Appendix D ("A shared collection envelope schema (`items` + continuation
member)") and the Appendix E worked example, all marked informative. This report
recommends `items` and `next_cursor` on R1.8's *same concept, same name* rationale
and on the worked example's usage, and says plainly that a different member name
would not violate a rule. Second, **the standard is silent on reject-versus-clamp**
for an over-maximum `limit`: `grep -n -i 'clamp'` over the pinned file returns
nothing, and R11.1 says only "publish and enforce". *Enforce* is therefore this
item's contract call, and it is made as **reject with `400`**, on two grounds — a
rejected request is observable and testable where a silent clamp is not, and
`rust-lang/crates.io` rejects (`"cannot request more than 100 items"`,
`pagination.rs:151-153`) rather than clamping.

**The architectural alternatives, compared before any library is named.**

| # | Architecture | Verdict |
|---|---|---|
| A | **Offset/page-size envelope with a total** (py's shape: `page`/`size` in, `items`/`total`/`page`/`size`/`pages` out) | **Ranked runner-up.** Correct only for a bounded or append-only collection, and R6.3 makes it a recorded deviation. Its `total` is the member that cannot be told the truth here — see the honesty paragraph below |
| B | **Keyset window behind an opaque cursor** (`cursor`/`limit` in, `items`/`next_cursor` out) | **Chosen.** Satisfies R6.3 outright with no appeal to its exception; needs no `total`, so it has no dishonest member; needs no port change |
| C | **Port takes a page request and returns a page** (true upstream pass-through) | **Not selected, and deliberately not raised as a conflict.** R03 revision 1's rule 1 fixes a collection read at `Result<Vec<T>, PortError>`; C would require revising an owner-accepted decision. It is recorded as the upgrade path and as an R01/R03 re-verify trigger, not proposed |
| D | **A tower layer that rewrites JSON array bodies into an envelope** | **Rejected on the record.** It is the only design that could be "registered once app-wide" the way `add_pagination(app)` is, and that is exactly why it must be named and refused: it operates on serialized bytes with no type information, so the handler's declared return type stops describing the wire, and R71's generated schema would document the pre-rewrite shape. It trades the one property Rust's model exists to provide for a cosmetic resemblance to Python |

**Answering HIGH-1 and HIGH-2 directly, because they are the item's two hinges.**

*HIGH-1 — does a `fastapi-pagination` equivalent exist?* **No.** The full-text and
exact-name sweeps above found one family that integrates with a web framework's
extractor (`paginator-axum` 0.4.0) and three that supply envelope types without one
(`api-bones`, `axum-api-kit`, `paginator-utils`). Not one of them supplies py's
combination of *extraction + envelope + app-wide registration*, and the two that
come closest fail this template on grounds stated per member below —
`paginator-axum` exports `create_link_header`, which R6.4 forbids outright, and
declares no `rust-version`; `api-bones` names its cursor parameter `after`, a
synonym for the reserved `cursor` that R1.8 forbids.

*HIGH-2 — can it be registered once, app-wide?* **The response envelope cannot be,
and the reason is structural rather than a gap in the ecosystem.** In FastAPI a
route's response model is a runtime value on the route object, so `add_pagination(app)`
can walk the route table and rewrite it. In axum a handler's response type is in its
signature and is resolved at compile time; nothing app-wide can change it without
giving up the type. **What can be registered once is the policy, not the type**: the
default and maximum `limit` live in one `PaginationLimits` value inside `AppState`,
reached through axum's `FromRef`, and one custom `FromRequestParts` extractor reads
them. Every collection handler then names two types — `Pagination` and
`Json<ListResponse<T>>` — and restates no constant, no parameter name and no bound.
That is the honest Rust analogue of F311: **one declaration site, not one call
site**, and a change to the limits is a one-line edit in the composition root rather
than a per-route sweep. This was compiled and executed, not reasoned about; see
*Validation strategy*.

*MEDIUM-3 — do items stay the caller's domain type?* **Yes, and this is the one
place where every candidate agrees with py.** `Page<T>` and `ListResponse<T>` are
generic over `T`; the probe serialized `Project` — a plain `serde` struct of the
library's own — with no wrapper type per item. `dropshot`'s `ResultsPage<ItemType>`
and `api-bones`' `CursorPaginatedResponse<T>` are generic in the same way. py's
WEB-03 property ("items remain `core.models` objects ... only the collection
envelope is web-specific") is preserved exactly, and R02's split makes it sharper
than py's: the item type and the window logic are in `crates/core`, and only the
wire encoding is in `crates/web`.

*MEDIUM-4 — OpenAPI integration.* Stated as a hand-off, not decided: R71
(`openapi-generation-pipeline`) is not yet researched. What R72 needs from it is
exactly Appendix D's row for R6.1/R6.5 — "A shared collection envelope schema
(`items` + continuation member); shared `cursor`/`limit` query parameters with
documented default and maximum" — which in the utoipa 5 vocabulary the owner
reference names at C3 means a `ToSchema` derive on `ListResponse<T>` (generic
schemas need a named instantiation per item type) and an `IntoParams` derive on the
query struct, both emitted from `crates/web`. R72 does not select the crate and does
not decide how the generic is named.

*LOW-5 — named, documented conventions in published Rust API templates.* The org
REST API Design Standard §6 is one, and it is the one that binds. Beyond it:
`dropshot`'s `ResultsPage` + `PaginationParams` is a named pattern in a published
framework's documentation; `rust-lang/crates.io`'s `?seek=` mode is a documented
convention in a production service's source. No general-purpose "Rust API template"
repository documents a page/size + items/total convention as a named pattern; the
sweep found none.

**The honesty paragraph, which the recommendation depends on.** The window this
template pages over is the `Vec<Project>` one upstream fetch already returned —
py's service signature is `def list_projects(self, workspace: str | None = None, limit: int = 200)`
(`src/py_launch_blueprint/core/services/projects.py:40-54`, pin `b08bccfb`). py
records the consequence in two places: the router docstring — "pages are sliced from
one upstream fetch (the service's default limit), so `total` reflects the fetched
window, not the upstream universe. True pass-through pagination needs cursor support
in `ProjectsService` — deferred" (`web/routers/projects.py`, pin `b08bccfb`) — and
`docs/design/0002-web-api-conventions.md:93-95`, "upstream pass-through pagination
(today `/v1/projects` slices pages from one upstream fetch, so `total` reflects that
window — fixing it properly means cursor support in `ProjectsService`)". The
recommended design **inherits that same window** and is correct *within* it: the
keyset seek is exact over the rows the service holds, and the probe demonstrates it
does not duplicate rows where an offset window does. What it does **not** claim is
pass-through pagination against the upstream API. Two things follow. First, the
absence of a `total` member is a feature and not an omission: py's `total` is the
member that cannot be told the truth here, and the chosen envelope simply does not
have one to lie with. Second, true pass-through remains the upgrade path, it requires
architecture C, and it is recorded as an R01/R03 re-verify trigger.

**R6.6's obligation, discharged concretely.** The documented total stable default
order is **ascending `Project::id`**, which is already the tiebreak key R6.6 names,
so no secondary key is needed. This is a requirement on P03's adapter and on the
shipped `InMemoryProjectsPort`, and the probe asserts the window logic against an
`id`-sorted slice.

**A hand-off, recorded and not decided: py's own API does not conform to this
standard.** `page`/`size` are synonyms for the reserved `limit`/`cursor` concepts
(R1.8), and the offset design is an R6.3 deviation with no documented bounded-collection
claim. Whether the three repositories should be harmonized on the standard is the
owner's question, not this item's; `docs/port/DIVERGENCE-ANALYSIS.md`'s `harmonize`
column is where it would be answered. R72 changes nothing in py.

**Observable acceptance criteria.** Criteria 1–9 were executed in this run against a
throwaway axum 0.8.9 workspace; 10–12 are requirements on a template that does not
yet exist and are **not results**.

| # | Criterion | Status |
|---|---|---|
| 1 | axum 0.8.9's own `Query<T>` accepts `limit=0` and `limit=101` with `200 OK`, proving it performs no range validation | **Verified** |
| 2 | axum 0.8.9's `Query` rejection for a type failure is `400` with `content-type: text/plain; charset=utf-8`, a shape that is neither RFC 9457 nor R67's envelope | **Verified** |
| 3 | A custom `FromRequestParts` extractor rejects `limit=0`, `limit=101` and a malformed `cursor` with `400` and a body the extractor chose | **Verified** |
| 4 | The success body is a top-level object with `items` and `next_cursor` (R6.1) | **Verified** |
| 5 | The last page carries `next_cursor: null` present rather than omitted | **Verified** |
| 6 | An empty collection is `200` with `"items": []` (R6.2) | **Verified** |
| 7 | No `Link` header is emitted on any response (R6.4) — asserted on every probe call | **Verified** |
| 8 | With no parameters the default `limit` (50) applies; `limit=100` returns 100 items (R6.5, R11.1) | **Verified** |
| 9 | Under an insert before the window boundary, the offset window duplicates a row and the keyset window does not (R6.3's claim) | **Verified** |
| 10 | The template's generated OpenAPI document declares shared `cursor`/`limit` parameters and one envelope schema | Not a result — R71's, stated as a hand-off |
| 11 | A conformance note exists for the web surface recording tier, switches and every deviation (R1.7, §1.9) | Not a result — a P03 deliverable |
| 12 | The documented default order (`id` ascending) holds for the production adapter, not only the in-memory fake | Not a result — P03's |

### Recommendation

**One stack: no pagination crate; a first-party cursor/limit contract conforming to
the org REST API Design Standard v2.0.0 §6, split across `crates/core` and
`crates/web`, with `base64` 0.23.1 as the single added dependency.**

Concretely, and this is the whole recommendation:

- **`crates/core`** declares `Limit` (a newtype whose only constructor enforces
  `1..=100`, with `DEFAULT = 50`), `PageRequest { after: Option<ProjectId>, limit: Limit }`,
  and `Page<T> { items: Vec<T>, next: Option<ProjectId> }`. `ProjectsService`
  gains `list_projects(&self, req: PageRequest) -> Result<Page<Project>, DomainError>`,
  which applies a keyset seek over the `Vec<Project>` the port returns. **`ProjectsPort`
  is unchanged** and still returns `Result<Vec<Project>, PortError>` per R03 rule 1.
  These are the pagination *types*, and R02 puts them in `core`.
- **`crates/web`** declares `PageQuery { cursor: Option<String>, limit: Option<u64> }`
  (reserved names only), the base64url cursor codec, `ListResponse<T> { items, next_cursor }`,
  `PaginationLimits` in `AppState` reached through `FromRef`, and one
  `impl<S> FromRequestParts<S> for Pagination` that reads the limits from state,
  rejects an out-of-range `limit` and an undecodable `cursor`, and hands the handler
  a validated `PageRequest`. These are the *HTTP encodings*, and R02 puts them in
  `web`.
- **`base64` 0.23.1** (`URL_SAFE_NO_PAD`) encodes and decodes the cursor — the same
  engine and alphabet `rust-lang/crates.io` uses for `?seek=`.
- **Nothing else.** No pagination crate, no validation crate, no `axum-extra`, no
  `Link` header, no tower layer, no `total`.

### Members

#### Request contract — reserved `cursor` and `limit` query parameters

##### Landscape

A *pattern* member: it decides two query-parameter names, their types, their
default and maximum, and what happens to an out-of-range value. The field splits
three ways. **Built-in:** axum 0.8.9's `extract::Query` deserializes a query string
into a `serde` struct and does nothing else. **Established standard:** the org REST
API Design Standard §1.10 and R6.5 reserve the names `cursor` and `limit`, and R11.1
requires a published, enforced maximum; outside the org, Stripe's `limit` +
`starting_after` is the pattern the industry converged on and GitHub's `?page=` +
`Link` headers is the counter-example R6.4 forbids. **Up-and-comers:** crate-supplied
parameter structs — `api-bones::pagination::CursorPaginationParams { limit, after }`,
`axum-api-kit::Pagination`, `paginator-utils::PaginationParams`.

##### Principles and implementation

The principle py realizes is *one name for the concept, everywhere, declared once*.
The org standard raises that from a convention to a reservation: R1.8 says a
conforming API "MUST use the reserved name rather than a synonym (same concept, same
name — everywhere)". So the parameters are `cursor` and `limit` — not `page`/`size`,
not `after`, not `offset`, not `per_page`. R6.5 adds a documentation obligation
("Each collection MUST document its default and maximum `limit`") and R11.1 an
enforcement obligation. The measured fact that decides the mechanism: **axum's
`Query` extractor performs no range validation.** `limit=0` and `limit=101` both
reached the handler with `200 OK` (probe, *Validation strategy*). Range enforcement
is therefore code this template writes, wherever it writes it.

##### Dominant choice

There is none to defer to. No crate in the field uses both reserved names: the
nearest, `api-bones` 6.12.0, uses `limit` + `after`. The dominant *practice* among
the well-regarded projects surveyed is a hand-written parameter struct validated by
the service's own code — `rust-lang/crates.io`'s `PaginationQueryParams { page, per_page, seek }`
with its own bounds checks, and `dropshot`'s `PaginationParams`.

##### Qualified shortlist

1. **A hand-written `PageQuery` plus a `Limit` newtype** whose only constructor
   enforces the bound. No dependency; the bound cannot be bypassed because no other
   constructor exists; the rejection value is this template's own type, so R70 can
   shape it.
2. **`axum-valid` 0.25.0 with `garde`** — `Garde<Query<PageQuery>>` moves the range
   into a `#[garde(range(min = 1, max = 100))]` attribute. Passes every applicable
   gate. Deferred rather than chosen: see *Ranked runner-up*.
3. **`api-bones` 6.12.0's `CursorPaginationParams`** — typed, validator-backed,
   framework-agnostic. Excluded on the reserved-name rule.

##### Excluded by gate

Gate 1 (licence) is **`inapplicable — owner ruling 2026-09-12 (Q7.B)`**: licence
compatibility is not evaluated for any dependency or tool
(`docs/planning/p02/owner-decisions.md:157-159`, quoting `docs/port/OWNER-REVIEW.md`).

| Candidate | Gate failed | Evidence |
|---|---|---|
| `paginator-utils` 0.4.0 | **Gate 2 (MSRV)** — declares no `rust-version` | `GET https://crates.io/api/v1/crates/paginator-utils/versions`, newest non-yanked `0.4.0` (2026-09-07), `rust_version: null`, `edition: "2021"` (2026-09-18). Under the strict reading the auditors established and the owner recorded (`docs/planning/p02/owner-decisions.md`, "Two things you should know" — "an unknown version is insufficient to clear a bar the prompt says must be cleared"), an undeclared MSRV is a failed gate, not a weighed unknown |
| `paginator-rs` 0.4.0, `paginator-axum` 0.4.0 | **Gate 2 (MSRV)** — same, `rust_version: null` | same endpoint, 2026-09-18 |
| `paginate` 1.1.11 | **Gate 2 (MSRV)** — `rust_version: null`, `edition: "2018"` | `GET https://crates.io/api/v1/crates/paginate/versions`, 2026-09-18 |
| `sqlx-paginated` 0.6.2 | **Gate 2 (MSRV)** — `rust_version: null` | `GET https://crates.io/api/v1/crates/sqlx-paginated/versions`, 2026-09-18 |

##### Up-and-comers

`api-bones` 6.12.0 is the genuinely interesting one and deserves its figures despite
the exclusion. `crate.downloads` 49 879, `crate.recent_downloads` 2 304, newest
non-yanked `6.12.0` published 2026-08-16, `rust_version` `1.85`, `edition` `2024`,
`license` `MIT`
(`GET https://crates.io/api/v1/crates/api-bones` and `/versions`, 2026-09-18).
`stargazers_count` **4**, `archived: false`, `pushed_at` `2026-09-18T21:06:24Z`,
open issues `total_count` **2**
(`GET https://api.github.com/repos/brefwiz/api-bones`,
`GET https://api.github.com/search/issues?q=repo:brefwiz/api-bones+is:issue+is:open`,
retrieved 2026-09-18T22:16:42Z). Issue responsiveness: the issues endpoint returned
no issue rows in the ten most recent items, so **median days to first maintainer
response could not be computed and the unanswered count is unverified** — recorded
as a gap, not inferred. `https://rustsec.org/packages/api-bones.html` returns `404`
(no advisory page, hence no open advisory; 2026-09-18). `unsafe` posture: not stated
in the crate's own documentation and not audited here — an open unknown.
Maintenance verdict: **at-risk**, on a concrete signal rather than on age — six major
versions (`6.7.1` through `6.12.0`, plus the whole `1.x`–`5.x` history) in the four
months since `created_at` `2026-04-20`, a churn rate that makes a pinned dependency
a recurring migration. Default features and async-runtime coupling: `default`
includes `validator`; `axum ^0.8` is optional; no runtime is pulled at default.
Compile and binary cost, qualitative: the manifest carries 24 optional normal
dependencies including `connectrpc`, `icalendar`, `rustls-native-certs` and
`opentelemetry` — small at default features, but the crate is a suite rather than a
library, and adopting one module means tracking the suite's release cadence.

`axum-api-kit` 2.2.0 — `crate.downloads` 3 584, `recent_downloads` 3 464, published
2026-08-12, `rust_version` `1.81`, `edition` `2021`, `license` `MIT`
(`GET https://crates.io/api/v1/crates/axum-api-kit`, `/versions`, 2026-09-18).
Passes gate 2. Excluded on fit, below.

##### Fit for this template

The template has one collection route. The question is not "which crate reduces the
most boilerplate" but "what does the second collection route cost". With a
hand-written `PageQuery` and a `Limit` newtype, it costs one added handler parameter
and zero new constants. With `api-bones` it costs the reserved-name violation, which
no amount of convenience buys back — `after` is a synonym for `cursor` and R1.8
forbids synonyms. With `axum-api-kit` it costs `data`/`total`/`limit`/`offset` as
the wire shape (`docs.rs/axum-api-kit/2.2.0/axum_api_kit/struct.ListResponse.html`,
2026-09-18), which is architecture A with non-standard member names. With
`axum-valid` it costs one more dependency for a bound that `Limit::new` already
makes unrepresentable.

##### Recommendation

`PageQuery { cursor: Option<String>, limit: Option<u64> }` in `crates/web`, plus
`Limit` in `crates/core` with `DEFAULT = 50`, `MAX = 100`, and `Limit::new(n) -> Result<Limit, LimitOutOfRange>`
as the only constructor. **Default 50 and maximum 100 are chosen, not invented:** 50
is exactly fastapi-pagination 0.15.15's default (`size: int = Query(50, ge=1, le=100)`,
`fastapi_pagination/default.py`, the version resolved in py's `uv.lock` at pin
`b08bccfb`), so the template's default page is the size py's clients already get;
100 is both that same crate's `le=100` ceiling and `rust-lang/crates.io`'s
`MAX_PER_PAGE: i64 = 100` (`pagination.rs:22`). An out-of-range `limit` is
**rejected with `400`, never clamped**.

##### Ranked runner-up

`axum-valid` 0.25.0 + `garde` 0.23. Figures: `crate.downloads` 453 696,
`crate.recent_downloads` 135 102, newest non-yanked `0.25.0` published 2026-06-30,
`rust_version` `1.88`, `edition` `2021`, `license` `MIT`, requires `axum ^0.8`
(`GET https://crates.io/api/v1/crates/axum-valid`, `/versions`, `/0.25.0/dependencies`,
2026-09-18). `stargazers_count` **165**, `archived: false`, `pushed_at`
`2026-06-30T10:40:44Z`, open issues `total_count` **5**
(`GET https://api.github.com/repos/gengteng/axum-valid` and the issue search,
2026-09-18T22:16:42Z). Issue responsiveness over the ten most recently opened
issues: `#40` (2026-02-14) and `#39` (2026-01-10) each have **0 comments** and are
open — **2 unanswered**; `#37` (2 comments), `#36` (1), `#35` (5) and `#33` (1) drew
replies, but the API's issue payload does not carry first-response timestamps, so
**the median days-to-first-maintainer-response is unverified** rather than estimated.
`https://rustsec.org/packages/axum-valid.html` returns `404` — no open advisory.
`unsafe` posture not stated by the crate and not audited here. Maintenance: **stable-quiet**
— the release cadence is roughly annual-major and the last release is under three
months old, so the six-month trigger is not reached. Gates 1 (inapplicable), 2
(1.88 ≤ 1.96), 3, 5 (no runtime coupling; `garde` is an optional feature) all pass;
gate 4 is **unverified** — no CI badge or platform list was read, and the crate was
not compiled here. **Why it is the runner-up and not the choice:** R69 revision 10
records the owner reference's C4 row (`garde` + `axum-valid`) as "**No P02 item;
pending owner scoping.** It reaches the handler signature R70 and R71 shape"
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:2400`).
Selecting a validation crate here would decide an unscoped row. The recommended
newtype needs none, so R72 does not force the question — and if the owner later
scopes C4 in, `Garde<Query<PageQuery>>` substitutes for the `Limit::new` call inside
the extractor without touching the wire contract. Note also that the owner reference
names `axum-valid 0.24.0`; `0.25.0` (2026-06-30) is the current line.

##### Tradeoffs

The newtype makes the bound a type-level invariant — a `Limit` value that is out of
range cannot be constructed anywhere in the workspace, including in tests — at the
cost of the bound being written in Rust rather than in an attribute, so it is not
mechanically extractable into an OpenAPI `maximum`. R71 must be told the number; the
mitigation is that `Limit::MAX` is a single `pub const` R71's annotation can name.
`axum-valid` would make the bound declarative and extractable at the cost of a
dependency and of deciding an unscoped owner row.

##### Parameters

No parameter is owned or changed by this member. No `CONFLICT:` line.

##### Migration implications

`crates/core/src/page.rs` (new) — `Limit`, `LimitOutOfRange`, `PageRequest`.
`crates/web/src/routes/projects.rs` — `PageQuery` and the handler signature.

##### Validation strategy

Executed: probe test `a_naive_query_rejections` (what axum does unaided) and
`b_custom_extractor_rejections` (what the recommendation does), plus
`e_limit_newtype_is_the_only_constructor`. Outputs quoted under the top-level
*Validation strategy*.

##### Confidence & re-verify trigger

High on the names and on the enforcement point (both are quoted rules plus an
executed probe); medium on the specific numbers 50 and 100, which are sourced but
are a contract choice the owner may prefer to set otherwise. Re-verify when the org
REST API Design Standard publishes past 2.0.0, if the owner scopes C4 in, or if
R77 names an environment knob for either number.

##### Sources

`/Users/stevemorin/c/rest-standards/rest-api-standard.md` at
`0850d43e45d919ef5e37f7174c4212b46013c49f` §1.10, R1.8, R6.5, R11.1 (read
2026-09-18) · `GET https://crates.io/api/v1/crates/{api-bones,axum-valid,axum-api-kit,paginator-rs,paginator-utils,paginator-axum,paginate,sqlx-paginated}`
and `/versions` (2026-09-18) ·
`GET https://api.github.com/repos/{brefwiz/api-bones,gengteng/axum-valid}` and
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`
(2026-09-18T22:16:42Z) · `https://rustsec.org/packages/{api-bones,axum-valid}.html`
(both `404`, 2026-09-18) · `docs.rs/api-bones/6.12.0/api_bones/pagination/struct.CursorPaginationParams.html`,
`docs.rs/axum-api-kit/2.2.0/axum_api_kit/struct.ListResponse.html` (2026-09-18) ·
`~/.cache/uv/wheels-v6/pypi/fastapi-pagination/0.15.15-py3-none-any/fastapi_pagination/default.py`
(the version pinned in py's `uv.lock` at `b08bccfb`) ·
`raw.githubusercontent.com/rust-lang/crates.io/main/src/controllers/helpers/pagination.rs:20-22,151-153`
(2026-09-18) · `docs/planning/p02/owner-decisions.md:157-159` (Q7.B) ·
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:2400`.

#### Response envelope — top-level `items` plus `next_cursor`

##### Landscape

A *pattern* member. **Built-in:** a `#[derive(Serialize)]` struct generic over the
item type, returned through `axum::Json`. **Established standard:** R6.1 (object,
never a bare array), R6.2 (empty collection is `200` + empty items array), R6.4
(continuation in the body, never a `Link` header), with `items` + `next_cursor` as
the shape Appendices C, D and E all use. **Up-and-comers:**
`api-bones::CursorPaginatedResponse<T> { data, pagination }`,
`axum-api-kit::ListResponse<T> { data, total, limit, offset }`,
`paginator-utils::PaginatorResponse`. Two first-party precedents sit outside the
crate market: `dropshot::ResultsPage<ItemType> { next_page: Option<String>, items: Vec<ItemType> }`
and `rust-lang/crates.io`'s `meta.next_page`.

##### Principles and implementation

py's WEB-03 property to preserve is that *the items are the core model and only the
wrapper is web-specific*. R02's four-package workspace lets that be enforced rather
than asserted: `Page<T>` is a `crates/core` type the service returns, and
`ListResponse<T>` is the `crates/web` type that encodes it — so a change to the wire
shape cannot reach the core, and `crates/core` never names an HTTP concept. R6.1's
reason for requiring an object is forward compatibility ("so that metadata can be
added without a breaking change"), which is exactly the property that lets a future
`total` or `has_more` be added additively if the upgrade path is taken.

##### Dominant choice

`items` + a continuation member, generic over the caller's type. It is what
`dropshot` ships, what the org standard's worked example emits, and what
`api-bones` and `axum-api-kit` ship modulo the member name (`data`).

##### Qualified shortlist

1. **A hand-written `ListResponse<T> { items: Vec<T>, next_cursor: Option<String> }`.**
2. **`api-bones::CursorPaginatedResponse<T> { data, pagination: CursorPagination }`**
   — `{"data": [...], "pagination": {"has_more": true, "next_cursor": "…"}}` per its
   own documentation.
3. **`axum-api-kit::ListResponse<T> { data, total, limit, offset }`.**

##### Excluded by gate

Gate 1 `inapplicable — owner ruling 2026-09-12 (Q7.B)`. `paginator-utils` 0.4.0 and
`paginate` 1.1.11 fail **gate 2** for the undeclared `rust-version` recorded in the
previous member. No candidate in this member fails gate 3 (no `rustsec.org` package
page exists for any of them; `404` for each, 2026-09-18).

##### Up-and-comers

`api-bones` and `axum-api-kit`, figures and maintenance verdicts in the previous
member (`api-bones` **at-risk** on major-version churn; `axum-api-kit` 3 584
downloads, two majors between 2026-07-22 and 2026-08-12, **at-risk** on the same
concrete signal). Neither is excluded by a gate; both are excluded on fit, below.

##### Fit for this template

`api-bones`' envelope nests the continuation under a `pagination` object and names
the array `data`; `axum-api-kit`'s is architecture A with `data`/`total`/`offset`.
Adopting either means the template's wire shape is that crate's, so a member rename
upstream is a breaking change to this template's API — for a struct with two fields
and one `From` impl. The measured cost of writing it is in the probe:
`ListResponse<T>` and its `from_page` constructor are eleven lines.

##### Recommendation

```rust
#[derive(Debug, Serialize, Deserialize)]
pub struct ListResponse<T> { pub items: Vec<T>, pub next_cursor: Option<String> }
```

in `crates/web`, built from `crates/core`'s `Page<T> { items: Vec<T>, next: Option<ProjectId> }`.
`next_cursor` is `Option<String>` and is **serialized as `null` on the last page, not
omitted** — `#[serde(skip_serializing_if)]` is deliberately not used, because the
standard's own streaming example emits `"next_cursor":null`
(`rest-api-standard.md:3274`) and a present-but-null member is what lets a client
distinguish "this API paginates and you are at the end" from "this API does not
paginate". Verified in the probe. **No `total` member**, for the reason given under
*Principles and implementation*.

##### Ranked runner-up

`api-bones` 6.12.0's `CursorPaginatedResponse<T>`, which is the only candidate whose
continuation semantics (opaque cursor, `has_more`) match the chosen architecture. It
would be adopted by renaming `data → items` and flattening `pagination`, at which
point nothing of the crate remains — which is itself the argument for the
hand-written struct.

##### Tradeoffs

Hand-writing the envelope means this template owns two field names and one `From`
impl forever, and gains: the member names are the standard's, a rename upstream
cannot break the API, `crates/web` keeps one fewer dependency, and R71 documents a
type this repository controls. The cost is that a second collection resource must
remember to use it — mitigated because there is exactly one generic type to reach
for and the extractor that produces its input is also shared.

##### Parameters

None owned or changed. No `CONFLICT:` line.

##### Migration implications

`crates/core/src/page.rs` — `Page<T>`. `crates/web/src/page.rs` (new) —
`ListResponse<T>` and `ListResponse::from_page`.

##### Validation strategy

Executed: probe test `c_envelope_bytes` — full page, last page, empty collection,
default limit, maximum limit, and the `Link`-header assertion on every call.

##### Confidence & re-verify trigger

High: the shape is a quoted MUST plus executed bytes. Medium on the member *names*,
which are informative in the standard rather than reserved. Re-verify if the
standard reserves response member names in a future version, or if R71's chosen
OpenAPI crate cannot name a generic schema instantiation.

##### Sources

`rest-api-standard.md` at `0850d43e…` R6.1, R6.2, R6.4, Appendix C, Appendix D,
Appendix E (lines 3030–3060), line 3274 (read 2026-09-18) ·
`docs.rs/dropshot/0.17.1/dropshot/struct.ResultsPage.html` (2026-09-18) ·
`GET https://api.github.com/repos/oxidecomputer/dropshot` and the issue search
(2026-09-18T22:22:10Z) · `GET https://crates.io/api/v1/crates/dropshot` (2026-09-18) ·
`docs.rs/api-bones/6.12.0/api_bones/pagination/struct.CursorPaginatedResponse.html`,
`docs.rs/axum-api-kit/2.2.0/axum_api_kit/struct.ListResponse.html` (2026-09-18) ·
py `docs/design/0002-web-api-conventions.md:29-32` at pin `b08bccfb`.

#### Opaque cursor codec — `base64` 0.23.1

##### Landscape

The one **crate** member. **Built-in:** `std` has no base64 or hex codec; a
hand-written hex encoder is ~12 lines. **Established standard:** `base64` is the
Rust ecosystem's de-facto codec, and `general_purpose::URL_SAFE_NO_PAD` is the
alphabet for query-parameter carriage (no `+`, `/` or `=` needing percent-encoding).
**Up-and-comers:** `data-encoding`, `base64ct`; and for the *signed*-cursor variant,
`api-bones`' `hmac` feature.

##### Principles and implementation

R6.3 requires cursors to be "opaque, non-constructable" and R12.5 places the
matching obligation on clients: "never construct, modify, or persist them beyond
their documented lifetime". **The standard does not mandate signing.** A search of
the pinned file for `hmac`, `tamper` and `signed cursor` finds HMAC only in §8's
webhook-signature material, never in §6 or §12; the §13.3 decision-log note
distinguishes `cursor` from `stream_position` precisely on the *contract* obligation
(R12.5) rather than on a cryptographic property. So base64url over an internal
position satisfies R6.3 as written, and HMAC signing is available hardening rather
than a requirement — worth recording because a reviewer may reasonably read
"non-constructable" as implying a signature.

##### Dominant choice

`base64`. `crate.downloads` **1 584 775 357**, `crate.recent_downloads`
**326 210 200**
(`GET https://crates.io/api/v1/crates/base64`, retrieved 2026-09-18). Newest
non-yanked version **`0.23.1`**, `created_at` **2026-08-04**, `license`
`MIT OR Apache-2.0`, `rust_version` **`1.71.0`**, `edition` `2021`, features
`alloc`, `default`, `simd-unsafe`, `std`
(`GET https://crates.io/api/v1/crates/base64/versions`, 2026-09-18).
`stargazers_count` **736**, `archived: false`, `pushed_at` `2026-08-18T23:08:58Z`,
open issues `total_count` **11**
(`GET https://api.github.com/repos/marshallpierce/rust-base64`,
`GET https://api.github.com/search/issues?q=repo:marshallpierce/rust-base64+is:issue+is:open`,
retrieved 2026-09-18T22:22:10Z). Issue responsiveness over the ten most recently
opened items: the endpoint returned two issues (`#309`, closed, 0 comments, opened
2026-08-04; `#307`, open, 1 comment, opened 2026-07-30), the rest of the window
being pull requests, so **1 unanswered of 2** and the **median days to first
maintainer response is unverified** — the payload carries no first-response
timestamp. Advisories: `https://rustsec.org/packages/base64.html` lists exactly one,
**RUSTSEC-2017-0004** (CVE-2017-1000430), an integer overflow in `encode_config_buf`,
`patched = [">= 0.5.2"]`
(`raw.githubusercontent.com/rustsec/advisory-db/main/crates/base64/RUSTSEC-2017-0004.md`,
2026-09-18) — **no open advisory against 0.23.1**. Maintenance: **active** —
`0.23.0` 2026-07-23, `0.23.1` 2026-08-04, last push 2026-08-18.

##### Qualified shortlist

1. **`base64` 0.23.1**, `URL_SAFE_NO_PAD`.
2. **A hand-written hex codec**, zero dependencies.
3. **`data-encoding`** — more alphabets, no advantage here.

##### Excluded by gate

None. Gate-by-gate for `base64` 0.23.1: **gate 1** `inapplicable — owner ruling
2026-09-12 (Q7.B)`; **gate 2** `rust_version` `1.71.0`, inside the `1.96` floor that
`msrv-policy` puts at stable (`1.98.0`, `rustc --version`, 2026-09-18) minus two
minors — and the probe's whole dependency tree compiled and its tests passed under
`rustup run 1.96.0`; **gate 3** no open advisory, and the `unsafe` posture is
stated: the default feature set is safe, with SIMD paths behind the explicitly named
opt-in `simd-unsafe`, which this template does not enable; **gate 4** verified on
macOS 26.4 aarch64 by the probe, and `ubuntu-latest` is **unverified here** — no
Linux runner was available in this run, so it rests on the crate's ubiquity rather
than on an execution (recorded as a gap); **gate 5** default features are `std` +
`alloc`, with **no async-runtime coupling of any kind**; **gate 6** cost measured,
not estimated — a clean build of a crate whose only dependency is `base64` 0.22
took **1.46 s wall / 0.54 s user CPU / 0.20 s sys** (`/usr/bin/time -p cargo build`,
macOS 26.4 aarch64, rustc 1.98.0, 2026-09-18), and `cargo tree -e normal` shows
`base64` has **zero transitive dependencies**, so binary-size impact is one small
codec and no new subtree.

##### Up-and-comers

`data-encoding` and `base64ct` were not shortlisted: neither offers anything this
use needs that `base64` lacks, and `base64ct`'s constant-time guarantee is for
secret material, which a pagination cursor is not.

##### Fit for this template

Two considerations pull opposite ways and both must be stated. **Against:** this
programme has repeatedly declined a crate for what `std` does in a few lines — R02
declined `guppy` because "the template's whole edge set is four rows and
`serde_json` parses them in twenty lines", and R01 added no crate at all. A hex
codec is twelve lines. **For:** `rust-lang/crates.io` — the closest possible
reference implementation, a production Rust service paginating with opaque tokens —
reaches for exactly this crate and exactly this alphabet
(`use base64::{Engine, engine::general_purpose}` at `pagination.rs:8`;
`general_purpose::URL_SAFE_NO_PAD.encode(...)` at line 332), and the cost measured
above is 1.46 s of clean build and no subtree. The wire form also differs: base64url
of an `id` is ~4/3 the bytes, hex is 2×. **The `for` side wins**, but narrowly, and
the alternative is carried as the runner-up so the owner can take the zero-dependency
route without re-researching.

##### Recommendation

`base64 = "0.23.1"` as a non-optional dependency of `crates/web` only (never of
`crates/core`, which must not learn the wire form), used through
`base64::engine::general_purpose::URL_SAFE_NO_PAD`. Encode the last item's
`ProjectId`; decode on the way in, and treat any decode failure as a rejected
request. Note the version: the owner reference does not mention `base64`, and the
current line is `0.23.1` (2026-08-04) rather than the long-lived `0.22.1`
(2024-04-30) — the probe compiled and passed against both.

##### Ranked runner-up

A hand-written lowercase-hex codec in `crates/web`, zero dependencies, ~12 lines
plus a round-trip test. Same opacity properties; twice the token length; one more
piece of code this repository owns. Selected over `base64` only if the owner
prefers the dependency count to the ecosystem convention.

##### Tradeoffs

One crate, zero transitive dependencies, 1.46 s of clean build and the same encoding
the Rust registry uses — against a hand-rolled twelve lines. Neither choice changes
the wire contract's shape, only the token's alphabet, so this is the one member that
can be revisited later without an API break, provided it is revisited before the
template ships (a token alphabet change *after* clients hold cursors is breaking).

##### Parameters

None owned or changed. No `CONFLICT:` line.

##### Migration implications

`crates/web/Cargo.toml` — one added line, `base64 = "0.23.1"`.
`crates/web/src/page.rs` — `encode_cursor` / `decode_cursor`.

##### Validation strategy

Executed: the whole probe was compiled and run against `base64` 0.22.1 and then
against `0.23.1`, and the full test set was re-run under `rustup run 1.96.0`
(`rustc 1.96.0 (ac68faa20 2026-05-25)`) — 5 passed, 0 failed. Compile cost measured
with `/usr/bin/time -p` on an isolated single-dependency crate.

##### Confidence & re-verify trigger

High. Re-verify at the next `msrv-policy` floor advance past 1.96, if a RustSec
advisory opens against the `0.23` line, or if the owner rules the template takes the
zero-dependency hex route.

##### Sources

`GET https://crates.io/api/v1/crates/base64` and `/versions` (2026-09-18) ·
`GET https://api.github.com/repos/marshallpierce/rust-base64` and the issue search
(2026-09-18T22:22:10Z) · `https://rustsec.org/packages/base64.html` and
`raw.githubusercontent.com/rustsec/advisory-db/main/crates/base64/RUSTSEC-2017-0004.md`
(2026-09-18) ·
`raw.githubusercontent.com/rust-lang/crates.io/main/src/controllers/helpers/pagination.rs:8,331-339`
(2026-09-18) · `rest-api-standard.md` at `0850d43e…` R6.3, R12.5, §13.3 decision-log
note (2026-09-18) · this run's probe logs.

#### Uniform application — one `FromRequestParts` extractor over `FromRef` state

##### Landscape

A *pattern* member, and the one that answers ledger row F311. **Built-in:** axum
0.8.9's `FromRequestParts` trait (which in the 0.8 line uses a native `async fn` in
trait — no `async-trait` attribute, confirmed by the probe compiling without one)
and `FromRef` for sub-state extraction, both named in R69's accepted value and in
the owner reference's C13 row. **Established standard:** none — no Rust framework
offers app-wide response-model registration, because no Rust framework can.
**Up-and-comers:** `paginator-axum` 0.4.0's `PaginationQuery` extractor is the only
crate-supplied axum pagination extractor found in the whole sweep.

##### Principles and implementation

F311's principle is *the pagination machinery is declared once, not restated per
route* — py realizes it as `add_pagination(app)` at `web/app.py:204`, a single
factory call that registers the response models and params globally. The mechanism
does not port, and the reason is the type system, not a missing library: FastAPI's
response model is a runtime attribute that a registration function can rewrite;
axum's is the handler's return type, fixed at compile time. Preserving the
*capability* while changing the mechanism means finding the thing that genuinely can
be declared once — and that is the **policy**, not the type. `PaginationLimits`
lives in `AppState`; `impl FromRef<AppState> for PaginationLimits` hands it to any
extractor; one `impl<S> FromRequestParts<S> for Pagination where PaginationLimits: FromRef<S>`
reads it, validates, and produces `PageRequest`. A second collection route writes
`Pagination(req): Pagination` in its signature and inherits the names, the default,
the maximum, the rejection behavior and the cursor codec. Changing the maximum is
one edit at the composition root.

##### Dominant choice

The custom-extractor-over-`FromRef`-state pattern. It is axum's own documented
extension point, it is what the owner reference's C13 row prescribes for shared
state ("`AppState` holds …; use `FromRef` to hand sub-state to extractors"), and it
is what R69's accepted `build_router(state) -> Router` shape already assumes.

##### Qualified shortlist

1. **A custom `FromRequestParts` extractor** reading limits from state.
2. **Plain `Query<PageQuery>` in every handler**, validating inline.
3. **`paginator-axum` 0.4.0's `PaginationQuery`**.
4. **A tower layer rewriting response bodies** — the only true app-wide option.

##### Excluded by gate

`paginator-axum` 0.4.0 fails **gate 2 (MSRV)**: `rust_version: null` on the newest
non-yanked version (`GET https://crates.io/api/v1/crates/paginator-axum/versions`,
`0.4.0` published 2026-09-07, 2026-09-18). Its figures, recorded because it is the
category's only real crate: `crate.downloads` 12 233, `crate.recent_downloads`
7 018, `license` `MIT`, `edition` `2021`; the family repository
`maulanasdqn/paginator-rs` has `stargazers_count` **6**, `archived: false`,
`pushed_at` `2026-09-07T09:48:53Z`, open issues `total_count` **0**, and of the four
issues ever opened all are closed, three of them by external users `MattDelac`
(2025-10-27) and `AspadaX` (2026-07-17) with 2–3 comments each — so the maintainer
does respond, and **0 unanswered**, median days-to-first-response still unverified
for lack of a first-response timestamp in the payload.
`https://rustsec.org/packages/paginator-axum.html` returns `404` — no open advisory.
Maintenance: **active** on cadence (`0.3.0` through `0.4.0` between 2026-09-01 and
2026-09-07) but the project is six-stars young. Gate 3 passes, gate 5 (axum
coupling, no independent runtime) passes, gate 6 not measured.

**A second, independent ground that would exclude it even if it declared an MSRV:**
its public surface is `PaginatedJson`, `PaginationQuery`, `PaginationQueryParams`
and **`create_link_header`** (`docs.rs/paginator-axum/0.4.0/paginator_axum/all.html`,
2026-09-18). Emitting RFC 8288 `Link` headers for pagination is precisely what R6.4
says a conforming API **MUST NOT** do. The crate is built around the convention the
org standard forbids.

##### Up-and-comers

`paginator-utils` 0.4.0 is the substrate under `paginator-axum` and is more capable
than its sibling suggests — it exports `Cursor`, `CursorDirection`, `CursorValue`,
`KeysetPlan`, `PaginationParams`, `PaginatorResponse`, `PaginatorResponseMeta`,
`Filter`/`FilterOperator`, `SearchParams` and an `IntoPaginationParams` trait
(`docs.rs/paginator-utils/0.4.0/paginator_utils/all.html`, 2026-09-18). It is the
closest thing in the ecosystem to a general keyset-pagination toolkit. It fails
gate 2 identically (`rust_version: null`), and it is worth naming as the crate to
re-examine first if the family ever declares an MSRV.

##### Fit for this template

The template has one collection route today and a `web` feature that is off by
default. Shortlist option 2 (inline validation in every handler) would work for one
route and silently rot at the second — it is the failure F311 exists to prevent.
Option 4 is refused on the record under *Principles and implementation*, architecture
D. Option 3 is excluded twice over. Option 1 costs about forty lines once, lives
inside `crates/web/src/` where R69's accepted value puts every later web layer, and
composes with R69's `build_router(state) -> Router` and R01's `AppState` without
touching either.

##### Recommendation

```rust
impl<S> FromRequestParts<S> for Pagination
where PaginationLimits: FromRef<S>, S: Send + Sync
{ type Rejection = /* R70's type */; async fn from_request_parts(..) -> .. }
```

with `PaginationLimits { default: Limit, max: u16 }` held in `AppState` and handed
out by `impl FromRef<AppState> for PaginationLimits`. The rejection type is a
**placeholder standing for R70's**: R72 owns the *contract* — that an out-of-range
`limit` and an undecodable `cursor` are rejected rather than clamped or ignored, at
the extractor rather than in the handler — and R70 owns the status code and body.
The probe used `400` with a two-key JSON body only to prove the extractor, not
axum's serde layer, chooses the outcome.

##### Ranked runner-up

Plain `Query<PageQuery>` plus a shared free function `fn validate(q: PageQuery, limits: PaginationLimits) -> Result<PageRequest, _>`
called at the top of each handler. Same types, same wire contract, one less trait
impl; loses the compile-time guarantee that a handler cannot forget to call it,
which is the whole of F311's principle.

##### Tradeoffs

The extractor puts the policy in one place and makes omission impossible, at the
cost of one trait impl whose `where` clause (`PaginationLimits: FromRef<S>`) a
contributor must understand before adding a route with a different state type. The
`FromRef` bound is also what keeps it testable: the probe's tests build `AppState`
directly and never start a server.

##### Parameters

None owned or changed. No `CONFLICT:` line.

##### Migration implications

`crates/web/src/page.rs` — `PaginationLimits`, `Pagination`, the `FromRequestParts`
impl. `crates/web/src/lib.rs` — `AppState` gains a `limits: PaginationLimits` field
and one `FromRef` impl.

##### Validation strategy

Executed: the extractor was compiled against axum 0.8.9 and exercised through
`tower::ServiceExt::oneshot` — R69's accepted in-process test idiom — for six
rejection cases and five success cases.

##### Confidence & re-verify trigger

High on the mechanism (compiled and executed at both 1.98.0 and the 1.96.0 floor).
Re-verify when axum publishes 0.9 (the `FromRequestParts` signature is the surface
most likely to move), when R70 publishes its rejection type, and when R69
republishes revision 10.

##### Sources

`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1405-1420,1602-1609,1791`
(2026-09-18) · `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`
§C13, "Level One" (2026-09-18) ·
`docs.rs/paginator-axum/0.4.0/paginator_axum/all.html`,
`docs.rs/paginator-utils/0.4.0/paginator_utils/all.html` (2026-09-18) ·
`GET https://crates.io/api/v1/crates/paginator-axum` and `/versions` (2026-09-18) ·
`GET https://api.github.com/repos/maulanasdqn/paginator-rs`, its open-issue search
and its ten most recent issues (2026-09-18T22:16:42Z) ·
`https://rustsec.org/packages/paginator-axum.html` (`404`, 2026-09-18) ·
`rest-api-standard.md` at `0850d43e…` R6.4 · this run's probe.

### Compatibility

The four members were not assembled from four independent sources and then hoped to
fit: **they were compiled and executed together as one crate.** The probe workspace
declares `axum = "=0.8.9"`, `tokio = "=1.53.1"` at R69's exact six features
(`rt-multi-thread`, `net`, `signal`, `macros`, `time`, `sync`), `serde` with
`derive`, `serde_json`, `base64 = "0.23.1"`, and `tower = "=0.5.3"` with `util` as a
dev-dependency for the `oneshot` idiom — i.e. R69's accepted member set plus the one
crate this item adds — at `edition = "2024"` and `rust-version = "1.96"`. It builds
clean and its five tests pass on **macOS 26.4 aarch64 at rustc 1.98.0** and again
under **`rustup run 1.96.0` (rustc 1.96.0, ac68faa20, 2026-05-25)**, the
`msrv-policy` floor. That is the version matrix, and it is executed rather than
asserted.

Shared adopter for the pattern half: **`rust-lang/crates.io`** runs base64url opaque
seek tokens, a published-and-enforced `MAX_PER_PAGE`, and reject-not-clamp on an
over-maximum page size in one production service — three of this bundle's four
members in one codebase, in the Rust project's own registry. Shared reference for
the envelope half: **`oxidecomputer/dropshot`**'s `ResultsPage<ItemType>` ships
`items` + an opaque continuation token, generic over the caller's type.

`ubuntu-latest` (`target-os-matrix`'s other runner) was **not** exercised: no Linux
machine was available in this run. Nothing in the stack is platform-sensitive —
`base64` is pure computation with no `std::os` surface, and `axum`/`tokio` are
already R69's verified members — but this is recorded as an execution gap, not
argued away.

### Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files
- assumes http-transport-injection-seam = trait-object port erased at the composition root: the driven-I/O contract is a dyn-compatible Rust trait (pub trait ProjectsPort: Send + Sync; no async fn, generic methods, associated consts or non-receiver Self) with a blanket impl for Arc<T>; the use case is generic over it (ProjectsService<P: ProjectsPort>); the composition root (plain functions, no DI container) erases the production adapter to Arc<dyn ProjectsPort> and hands the single ProjectsService<Arc<dyn ProjectsPort>> to the CLI and the web layer; fakes and test doubles are injected as any ProjectsPort implementor (the shipped InMemoryProjectsPort), never as injected function values and never by patching a transport; under an async R05 the trait keeps dyn compatibility with async-trait 0.1.92

**Two notes on the `web-extra-surface` value above, which is quoted at the registry's
live bytes as required and is therefore one revision behind.** First, **R69 revision
10 is owner-accepted and unpublished**
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791`, owner
rulings W1-R02 and W0-R69c): it names the optional member `crates/web` on the root
package's `web` feature, moves the route modules and handlers to `crates/web/src/`,
and puts the web integration tests in `crates/web/tests/` with no file-level
`#![cfg(feature = "web")]`. **Every path in this report uses revision 10's form** —
`crates/web/src/page.rs`, `crates/web/src/routes/projects.rs`,
`crates/web/Cargo.toml` — because that is the layout the design is written against.
The registry row still shows revision 9's `src/web/` form, and **R69's republication
is a re-verify trigger for this item**. This is deliberately *not* a `CONFLICT:`
line: nothing in this recommendation needs R69's value changed, only re-read once it
publishes. Second, the clause "every later web layer — … R72 to R76's middleware …
as modules inside that same gated `crates/web/src/` tree" is the clause this item's
`crates/web` half sits under; R72 is not middleware, but it is a later web layer and
the clause reaches it.

**No `CONFLICT:` line is raised.** The one that was checked for and did not
materialize: architecture C (a port that takes a page request) would need R03
revision 1's rule 1 changed, so the recommendation deliberately does not take it —
and in any case `R03` owns no registry parameter, so the appropriate instrument would
have been a request to revise an accepted decision rather than a `CONFLICT:` line.
R01's `http-transport-injection-seam` is consumed unchanged: the keyset window lives
in `ProjectsService`, which the parameter already places above the port.

**No `BASELINE-REVIEW:` finding is emitted.** F310 and F311 are `DIVERGENT`
(`docs/port/COMMONALITY.md:314-315`), and `docs/port/BASELINE-REVIEW.md` adjudicates
`COMMON → REUSE` and `ADOPT` rows only.

**Owner-reference reconciliation (owner decision 11, standing input).** The reference
document contains **no pagination row** — searches for `pagina`, `page_size`,
`cursor` and `limit/offset` over
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` return nothing
(2026-09-18). Five rows it does contain overlap this item:

| Row | Position |
|---|---|
| **Level One** — "what Axum + tower-http already give you (don't add crates for these): Routing, extractors, `State`/`FromRef` sub-state, handlers …" | **Agree.** The recommendation's uniform-application member is exactly this instruction taken literally: extraction and sub-state come from axum, and no crate is added for them |
| **C3 OpenAPI** — utoipa 5 + utoipa-axum 0.2, `IntoParams` via `axum_extras` | **Agree, as a hand-off.** R72 does not select the crate (R71's) and states only what it needs: a shared parameter pair and one envelope schema, per the standard's Appendix D row |
| **C4 Validation & error responses** — garde + axum-valid 0.24; hand-rolled RFC 9457 `AppError` | **Differ on the validation half, on sourced ground; agree on the hand-roll half.** R69 revision 10 records C4 as "No P02 item; pending owner scoping" (line 2400), so selecting `axum-valid` here would decide an unscoped row; the `Limit` newtype needs no validation crate. The document's own instinct to hand-roll rather than adopt a thin wrapper crate is the same instinct this item applies to the envelope. Note the version drift: the document says 0.24.0; 0.25.0 shipped 2026-06-30 |
| **C11 Middleware suite & security headers** | **Not applicable, stated rather than skipped.** Pagination is not middleware in the recommended design — architecture D would have made it middleware, and is refused. Nothing in C11's layer order changes |
| **C12 Testing** — axum-test 18 preferred over tower `oneshot` | **Agree with R69, not with the document, and this item does not re-rule.** R69's accepted value selects `tower` 0.5.3 `ServiceExt::oneshot` as the in-process idiom; this run's probe used that idiom so its evidence composes with R69's. Whether axum-test displaces it is R32's and R69's, not R72's |

Tally: **3 agree, 1 differ (with ground), 1 not applicable.**

### Migration implications

File-level changes in the template, written against R69 revision 10's layout:

| File | Change |
|---|---|
| `crates/core/src/page.rs` (new) | `Limit` (private `u16`, `DEFAULT = 50`, `MAX = 100`, `new()` the only constructor), `LimitOutOfRange`, `PageRequest { after: Option<ProjectId>, limit: Limit }`, `Page<T> { items: Vec<T>, next: Option<ProjectId> }`, and `keyset_window`. No HTTP vocabulary, no `base64`, no `axum` |
| `crates/core/src/lib.rs` | Private `mod page;` plus the `pub use` lines that put `Limit`, `PageRequest` and `Page` on the public surface — R04's root-barrel rule, which "now applies to both packages that carry a public surface" per R69 revision 10's note at line 1604. `#![deny(missing_docs)]` means each gets a doc comment |
| `crates/core/src/service.rs` | `ProjectsService::list_projects` gains a `PageRequest` argument and returns `Result<Page<Project>, DomainError>`; it calls the unchanged port, then `keyset_window`. The documented default order (`id` ascending) is asserted here |
| `crates/core/src/ports.rs` | **Unchanged.** `ProjectsPort::list_projects` still returns `Result<Vec<Project>, PortError>` (R03 rule 1) |
| `crates/core/src/adapters/in_memory.rs` | The shipped `InMemoryProjectsPort` must return rows in `id` order for R6.6 to hold in tests |
| `crates/web/Cargo.toml` | One added line: `base64 = "0.23.1"` |
| `crates/web/src/page.rs` (new) | `PageQuery`, `encode_cursor`/`decode_cursor`, `ListResponse<T>` + `from_page`, `PaginationLimits`, `Pagination`, and the `FromRequestParts` impl |
| `crates/web/src/lib.rs` | `AppState` gains `limits: PaginationLimits`; one `impl FromRef<AppState> for PaginationLimits` |
| `crates/web/src/routes/projects.rs` | `list_projects` gains `Pagination(req): Pagination` and returns `Json<ListResponse<Project>>` instead of `Json<Vec<Project>>` |
| `crates/web/tests/web_api.rs` | The nine executed criteria, ported to the template's router |
| `docs/` — a **conformance note** for the web surface (new) | R1.7 requires one: "An API deviates from this standard only in writing." Rendered from §1.9's template, declaring tier, the four switches (`webhooks`, `async-operations`, `bulk-operations`, `streaming`) each with an off-reason, and the R6.5 documentation obligation (default 50, maximum 100, order `id` ascending). Every angle-bracket placeholder replaced. **This is a P03 deliverable this item creates the need for**, and it is the artefact that makes the whole standard-conformance claim auditable rather than asserted |

Consumers of this item, stated so they are not lost: **R70** receives the contract
that an out-of-range `limit` and an undecodable `cursor` are *rejected at the
extractor*, and owns the status and body; **R71** receives the Appendix D
obligation (shared `cursor`/`limit` parameters with documented default and maximum,
one envelope schema) and must name `Limit::MAX` in the generated `maximum`; **R77**
owns the naming of any environment knob that would make the default or maximum
configurable, and **this item does not create one** — both are `pub const` values in
`crates/core`, which keeps them out of R53's schema-validation and R54's
discovery-tier scope entirely unless the owner asks for the knob.

### Validation strategy

**Executed.** A throwaway crate under `$TMPDIR` (created and deleted by this run;
nothing written outside the run directory) declaring `axum = "=0.8.9"`,
`tokio = "=1.53.1"`, `serde`, `serde_json`, `base64 = "0.23.1"`,
`tower = "=0.5.3"` (dev), `edition = "2024"`, `rust-version = "1.96"`. Commands:
`cargo build`, then `cargo test -- --nocapture --test-threads=1`, then the same
under `rustup run 1.96.0`. Result at both toolchains: **5 passed, 0 failed.**
Verbatim output, which is the evidence for criteria 1–9:

```
NAIVE  limit=abc                  -> 400 Bad Request ct=Some("text/plain; charset=utf-8") body="Failed to deserialize query string: limit: invalid digit found in string"
NAIVE  limit=-1                   -> 400 Bad Request ct=Some("text/plain; charset=utf-8") body="Failed to deserialize query string: limit: invalid digit found in string"
NAIVE  limit=99999999999999999999 -> 400 Bad Request ct=Some("text/plain; charset=utf-8") body="Failed to deserialize query string: limit: number too large to fit in target type"
NAIVE  limit=0                    -> 200 OK ct=Some("text/plain; charset=utf-8") body="PageQuery { cursor: None, limit: Some(0) }"
NAIVE  limit=101                  -> 200 OK ct=Some("text/plain; charset=utf-8") body="PageQuery { cursor: None, limit: Some(101) }"
CUSTOM limit=abc                  -> 400 Bad Request ct=Some("application/json") body={"code":"bad_query","detail":"Failed to deserialize query string: limit: invalid digit found in string"}
CUSTOM limit=0                    -> 400 Bad Request ct=Some("application/json") body={"code":"limit_out_of_range","detail":"limit 0 is outside 1..=100"}
CUSTOM limit=101                  -> 400 Bad Request ct=Some("application/json") body={"code":"limit_out_of_range","detail":"limit 101 is outside 1..=100"}
CUSTOM cursor=!!!not-base64!!!    -> 400 Bad Request ct=Some("application/json") body={"code":"bad_cursor","detail":"cursor is not a valid token"}
PAGE1  -> 200 OK ct=Some("application/json") body={"items":[{"id":"p000","name":"Project 0"},{"id":"p001","name":"Project 1"}],"next_cursor":"cDAwMQ"}
PAGE2  -> 200 OK body={"items":[{"id":"p002","name":"Project 2"}],"next_cursor":null}
EMPTY  -> 200 OK body={"items":[],"next_cursor":null}
DEFAULT-> items=50
MAX    -> 200 OK items=100
OFFSET seen = ["p000", "p001", "p002", "p002", "p003", "p004"]
KEYSET seen = ["p000", "p001", "p002", "p003", "p004", "p005"]
OFFSET duplicates=true  KEYSET duplicates=false
```

Read the three most load-bearing lines. `NAIVE limit=0` and `NAIVE limit=101`
returning **`200 OK`** is the measured proof that **axum 0.8.9's `Query` extractor
performs no range validation whatever** — it rejects only what `serde` cannot
deserialize, and it rejects that as `400 text/plain`, a shape that is neither
RFC 9457 nor R67's `{"error":{"code","message","hint"?}}`. That single fact is why
this item recommends a custom extractor rather than a bare `Query<T>`, and it is the
reason R11.1's "enforce" obligation cannot be delegated to the framework. The
`OFFSET`/`KEYSET` pair is R6.3's claim made empirical: with one row inserted before
the window boundary between the first and second request, the offset reader returns
`p002` **twice** and never sees `p005`, while the keyset reader returns each row
exactly once. The `PAGE2` line shows `"next_cursor":null` **present** on the last
page, and every probe call asserted that no `Link` header was emitted (R6.4).

Cost measurement, executed: a single-dependency crate over `base64` 0.22 built clean
in **1.46 s wall / 0.54 s user / 0.20 s sys** (`/usr/bin/time -p cargo build`,
macOS 26.4 aarch64, rustc 1.98.0), and `cargo tree -e normal` shows `base64` pulls
**no transitive dependency**; `cargo tree -e normal -i base64` against the full probe
confirms `base64` is not already in the axum-0.8.9-plus-tokio tree, so it is a
genuinely new direct dependency rather than a free one.

**Proposed, not executed** — for P03, stated separately so nothing here is read as a
result:

1. `cargo test -p rs-launch-blueprint-web --features web` running the nine criteria
   against the template's own router. Expected: identical statuses and bodies.
2. `cargo test -p rs-launch-blueprint-core` asserting that
   `ProjectsService::list_projects` over the shipped `InMemoryProjectsPort` returns
   rows in ascending `id` order and that page-boundary rows are neither skipped nor
   duplicated across two calls (R6.6).
3. A `compile_fail` doctest proving `Limit` cannot be constructed except through
   `Limit::new` — the type-level half of R11.1's "enforce".
4. A CI step asserting that no route emits a `Link` header, so R6.4 cannot regress
   when R75's middleware stack lands.
5. The same suite on `ubuntu-latest`, closing this run's platform gap.
6. `cargo build` with `web` off, asserting `base64` is absent from the default
   dependency tree.

### Confidence & re-verify trigger

**High** on: that no Rust crate provides py's extraction-plus-envelope-plus-app-wide-registration
combination (exhaustive sweep, five `404`s on exact names, every full-text hit
dispositioned); that axum's `Query` does not range-validate (executed); that the
keyset window is correct where the offset window is not (executed); that
`cursor`/`limit` are reserved and `Link` headers are forbidden (quoted MUST rules).

**Medium** on: the member names `items` and `next_cursor`, which are informative in
the standard rather than reserved; the numbers 50 and 100, which are sourced from
fastapi-pagination 0.15.15 and `rust-lang/crates.io` but remain a contract choice;
and `base64` over a hand-rolled hex codec, which the *Fit* section records as a
narrow call.

**The open owner question, stated once more because the recommendation turns on it.**
Does the org REST API Design Standard v2.0.0 bind this template's HTTP surface, as
the org CLI Design Standard binds its command line in R67 and R69? If **yes**, the
recommendation above stands as written and P03 owes a conformance note. If **no**,
the ranked fallback is the same first-party design with py's shape — `page`/`size`
in, `items`/`total`/`page`/`size`/`pages` out — which changes the two members'
wire names and the window logic but not the workspace split, not the extractor
pattern, and not the F311 answer. The question is the owner's because it is a scope
ruling about which org standards reach this programme, not a research question this
item can settle from evidence.

**Re-verify when:** R69 republishes revision 10 (the `crates/web` paths this design
is written against become registry bytes); R70 publishes its rejection type; R71 is
researched and fixes how a generic envelope schema is named; the org REST API Design
Standard publishes past 2.0.0 or reserves response-body member names; R02 publishes
and its `crates/core` external-dependency allow-list is fixed (`base64` must stay out
of it); R77 names an environment knob for the page-size defaults; axum publishes 0.9;
a RustSec advisory opens against `base64` 0.23; the `msrv-policy` floor advances past
1.96; or by **2027-03-18**, whichever comes first.

### Sources

**Standards and owner inputs.** Org REST API Design Standard **v2.0.0**,
`/Users/stevemorin/c/rest-standards/rest-api-standard.md`, repository
`https://github.com/smorinlabs/rest-standards.git`, commit
`0850d43e45d919ef5e37f7174c4212b46013c49f` (2026-09-05), no tag at HEAD — sections
§1.7 (R1.5 tiers), §1.8 (R1.6 switches), §1.9 (R1.7 no-silent-deviation and the
conformance-note template), §1.10 (R1.8 reservation discipline; the reserved query
parameters `cursor` and `limit`), §6 (R6.1–R6.10), §11 (R11.1), §12 (R12.5),
Appendix C, Appendix D, Appendix E lines 3030–3060, line 3274; `CHANGELOG.md`
(2.0.0 dated 2026-08-12); all read 2026-09-18 · org CLI Design Standard at
`/Users/stevemorin/c/cli-standards/cli-design-standard.md` (existence and sibling
relationship only) · `docs/planning/p02/owner-decisions.md` §11 (the standing-input
ruling), §5 / Q7.B (the licence-gate ruling), and the MSRV strict-reading note ·
`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` §§C3, C4,
C11, C12, C13 and "Level One".

**Programme records.** `docs/port/PARAMETERS.md` (all `assumes` rows, quoted at live
bytes) · `docs/port/COMMONALITY.md:307,309-316` (F303, F305–F307, F310–F312) ·
`docs/port/README.md` (verdict vocabulary; BASELINE-REVIEW's scope) ·
`research/topics/01-ports-and-adapters-seam/DECISION.md:13-17,117-120,138` ·
`research/topics/04-public-api-surface-enforcement/DECISION.md` (root-barrel rule) ·
`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md` (the
four-package workspace table) ·
`research/runs/R03/2026-09-17T033527Z-cd9e6a9555b6/review/DECISION.md` (rules 1–5) ·
`research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md` (synchronous
core; `spawn_blocking` bridge) ·
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1405-1420,1602-1609,1791,2400`.

**Source repositories at their pins.** `py-launch-blueprint` at
`b08bccfb55d05f15e46a83b52c5660b1881d19f5` —
`src/py_launch_blueprint/web/routers/projects.py` (line 30 import; the pagination
window docstring), `src/py_launch_blueprint/web/app.py:204`,
`src/py_launch_blueprint/core/services/projects.py:40-54`,
`docs/design/0002-web-api-conventions.md:29-32,88-95`, `uv.lock`
(`fastapi-pagination` 0.15.15). `ts-launch-blueprint` at
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00` — **not read**; it has no web service
(`docs/port/areas/web-service.md:100`), so there is no pagination code to cite.

**Crate figures** — all `GET https://crates.io/api/v1/crates/<name>` and
`/versions`, retrieved **2026-09-18**: `base64`, `api-bones`, `axum-valid`,
`axum-api-kit`, `paginator-rs`, `paginator-utils`, `paginator-axum`,
`sqlx-paginated`, `page-turner`, `paginate`, `dropshot`. Search endpoints
`GET https://crates.io/api/v1/crates?q=<q>&per_page=25&sort=downloads` for
`pagination`, `paginate`, `cursor pagination`, `keyset`, `axum pagination`,
`cursor paginate axum`, `page size envelope`, `opaque cursor`; exact-name probes
returning `404` for `axum-pagination`, `axum_pagination`, `pagination-rs`,
`cursor-pagination`, `seek-pagination`.

**GitHub figures** — `GET https://api.github.com/repos/<o>/<r>` and
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`, via
keyring-authenticated `gh api` at no more than one call per 20 s, retrieved
**2026-09-18T22:16:42Z** (`brefwiz/api-bones`, `maulanasdqn/paginator-rs`,
`alexandrughinea/sqlx-paginated`, `a1akris/page-turner`, `gengteng/axum-valid`) and
**2026-09-18T22:22:10Z** (`marshallpierce/rust-base64`, `oxidecomputer/dropshot`).

**Advisories** — `https://rustsec.org/packages/<name>.html` for `base64` (one
advisory, RUSTSEC-2017-0004), and `404` for `axum-valid`, `api-bones`,
`paginator-rs`, `paginator-axum`, `page-turner`, `sqlx-paginated`;
`raw.githubusercontent.com/rustsec/advisory-db/main/crates/base64/RUSTSEC-2017-0004.md`
(`patched = [">= 0.5.2"]`). All 2026-09-18.

**Practice evidence** —
`https://raw.githubusercontent.com/rust-lang/crates.io/main/src/controllers/helpers/pagination.rs`
(732 lines; lines 8, 20–22, 108–157, 197–234, 321–339), and
`https://docs.rs/dropshot/0.17.1/dropshot/struct.ResultsPage.html`;
`https://docs.rs/api-bones/6.12.0/api_bones/{all,pagination/index,pagination/struct.CursorPaginationParams,pagination/struct.CursorPaginatedResponse,pagination/struct.PaginationParams}.html`;
`https://docs.rs/paginator-axum/0.4.0/paginator_axum/all.html`;
`https://docs.rs/paginator-utils/0.4.0/paginator_utils/all.html`;
`https://docs.rs/axum-api-kit/2.2.0/axum_api_kit/{all,struct.ListResponse}.html`.
All 2026-09-18.

**Method notes.** Figures came from `GET https://crates.io/api/v1/crates/<name>`
(`crate.downloads`, `crate.recent_downloads`) and `/versions` (newest `yanked:false`:
`num`, `created_at`, `license`, `rust_version`, `edition`, `features`), from
`GET https://api.github.com/repos/<o>/<r>` (`stargazers_count`, `archived`,
`pushed_at`) and `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`
(`total_count`, never `open_issues_count` — the two differ for every repository
surveyed, e.g. `marshallpierce/rust-base64` reports `open_issues_count` 18 against a
search `total_count` of 11), and from `https://rustsec.org/packages/<name>.html`.
Empirical claims came from a throwaway `cargo` workspace created under a `$TMPDIR`
subdirectory and removed at the end of the run; its verbatim output is quoted above.
The `rustc` figures are `rustc 1.98.0 (88d9e12ae 2026-08-18)` as active stable and
`rustc 1.96.0 (ac68faa20 2026-05-25)` as the `msrv-policy` floor, both read on this
machine 2026-09-18. **What could not be verified, listed rather than glossed:** (1)
`ubuntu-latest` execution — no Linux runner was available, so gate 4 rests on macOS
plus each crate's ubiquity for the Linux half; (2) **median days to first maintainer
response** for every surveyed repository — the GitHub issues payload carries
`comments` counts and `created_at` but no first-response timestamp, and fetching
per-issue comment timelines would have meant roughly 60 further API calls at the
20-second floor, so the unanswered counts are reported and the medians are marked
unverified rather than estimated; (3) `unsafe` posture for `api-bones`, `axum-valid`
and the `paginator-*` family — read from documentation where stated, never audited
line by line, and stated as unknown where the crate says nothing; (4) issue rows for
`brefwiz/api-bones`, `alexandrughinea/sqlx-paginated` and `oxidecomputer/dropshot` —
the ten-most-recent window returned only pull requests for the first two and no rows
for the third, so their responsiveness is unverified; (5) compile and binary cost for
every excluded crate — measured only for `base64`, since a gate-failed candidate is
not compiled. Per the role file, the run directory's `raw/` was never listed and no
other engine's report was read.
