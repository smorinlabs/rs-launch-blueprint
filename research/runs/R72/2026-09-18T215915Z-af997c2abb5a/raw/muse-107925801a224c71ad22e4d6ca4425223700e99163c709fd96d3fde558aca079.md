# R72 api-pagination — Muse raw report (Deep tier, bundle kind)

Actor: `research-muse-2026-09-18T215915Z-af997c2abb5a`. Retrieval date for all
figures: 2026-09-19. This report answers
`research/runs/R72/2026-09-18T215915Z-af997c2abb5a/inputs/prompt.md` exactly.

### Landscape

Category decided: the HTTP collection-pagination contract of the template's web
service — request-side page-window parameters plus the response envelope — and
whether a third-party Rust crate provides it.

Three-bin map of the Rust field (every shortlisted candidate comes from this
map):

- Built-in / first-party: `axum::extract::Query` (generic query-string
  deserializer; its own documentation uses a `Pagination { page, per_page }`
  struct as the canonical example) + `axum::Json` + caller-owned serde structs.
  No first-party pagination crate or global pagination hook exists in axum.
- Established industry standard: none found. There is no dominant,
  widely-adopted Rust pagination crate. The closest to established is
  `paginate` 1.1.11 (102,809 all-time downloads), which is pure offset/length
  index math with zero dependencies, no serde support, no extractor, and no
  envelope — a different layer, not a web-pagination solution. Its last release
  was 2022-04-11.
- Up-and-comers: `paginator-axum` 0.4.0 + `paginator-utils` 0.4.0 (+
  `paginator-rs` 0.4.0 core) — the only axum-integrated extractor + envelope
  crate found (single maintainer, 6 stars, released 2026-09-07);
  `sqlx-paginated` 0.6.2 — a sqlx query builder with a paginated response type
  (25 stars, requires sqlx 0.9 + tokio); `api-paginate` 0.1.1 — offset/cursor
  types with optional serde and optional utoipa derives (0 stars, 28 total
  downloads, released 2026-09-12). Also surveyed and not shortlisted:
  `pagination` 0.3.0 (dormant since 2023-04-20, 5,430 downloads, no framework
  integration) and `mongodb-cursor-pagination` 0.3.2 (MongoDB-driver-bound,
  wrong layer for this template).

Authoritative sources used, and why each counts:

- axum 0.8.9 crate source, `src/extract/query.rs` (pinned, read from the local
  cargo cache `~/.cargo/registry/cache/*/axum-0.8.9.crate`): first-party
  maintainer documentation of the extractor mechanism this item must integrate
  with; the tokio-rs axum project is the framework R69 selected.
- rust-lang/crates.io `src/controllers/helpers/pagination.rs` (production
  source of the canonical Rust/axum public API service, fetched 2026-09-19):
  production practice evidence — hand-rolled `PaginationQueryParams` deriving
  `Deserialize`, axum `FromRequestParts`, and `utoipa::IntoParams`, with a
  generic `Paginated<T>` envelope.
- Org REST API Design Standard v2.0.0 (`rest-api-standard.md` at
  smorinlabs/rest-standards commit `0850d43e`, read via `git show`, no
  checkout): binding owner ruling W2-REST on this template's HTTP surface —
  rules R1.8 (line 312), R6.1–R6.6 (lines 1133–1208), R11.1 (line 1678).
- utoipa 5.5.0 `derive.IntoParams` documentation (docs.rs, fetched
  2026-09-19): maintainer documentation proving hand-rolled param structs get
  OpenAPI query-parameter generation via derive, with no per-route annotation.
- py blueprint source (`src/py_launch_blueprint/web/routers/projects.py:30`,
  `web/app.py:204`, `pyproject.toml:59`) read from the local checkout
  `/Users/stevemorin/c/py-launch-blueprint`: the precedent this item
  generalizes, used as evidence per the research mandate, not as the winner.
- crates.io API (`GET /api/v1/crates/<name>`, `/versions`,
  `/<version>/dependencies`, `/reverse_dependencies`) for download, release,
  license, dependency, and adopter figures; docs.rs item pages for API shapes;
  GitHub repository pages (via page fetch — the GitHub API was unreachable,
  see Transport note) for stars/forks/issues/commits; rustsec.org package
  pages (404 = no advisories recorded, calibrated against
  `https://rustsec.org/packages/rsa.html`, which renders RUSTSEC-2023-0071).

Transport note (commands recorded, failures honest): from this sandbox,
`curl https://crates.io/api/v1/...` succeeded (with retries);
`gh api repos/<o>/<r>` and `gh api search/issues` failed for all five
candidate repos with `context deadline exceeded`; `curl` to
`api.github.com`, `docs.rs`, `static.crates.io`, `index.crates.io`, and
`rustsec.org` failed with curl exit 28 (timeout). GitHub-sourced figures
below therefore come from repository/issue HTML pages fetched 2026-09-19
(stars, forks, open-issue counts, commit counts) rather than the
`stargazers_count` / search-`total_count` API fields, and issue-responsiveness
medians could not be computed — recorded as gaps per candidate. Crate
`.crate` sources could not be downloaded (`static.crates.io` blocked), so
`unsafe` posture and CI/OS badges are unverified except where stated.

Well-regarded projects surveyed, with the evidence that they are well
regarded:

- rust-lang/crates.io: the Rust project's own package registry and its
  reference production axum service. Hand-rolls pagination (see file above);
  uses no pagination crate. adopts `page`/`per_page`/`seek` params with
  `DEFAULT_PER_PAGE = 10`, `MAX_PER_PAGE = 100`, and utoipa `IntoParams`
  derives on the same struct that axum extracts.
- tokio-rs/axum examples and docs: the framework's own `Query` documentation
  teaches pagination as a caller-owned `Pagination` struct — the idiom the
  ecosystem copies (confirmed by web search: independent write-ups and
  templates repeat the `Query<Pagination>` shape, e.g.
  `https://github.com/tokio-rs/axum/blob/main/axum/src/docs/extract.md`).
- Published Rust API templates documenting a page-window + envelope
  convention (LOW question): `99minutos/template-agents-rust` (`AGENTS.md`
  documents `Pagination { page, limit }` + `GenericApiResponse::paginated(
  items, total, page, limit)`); `hendrixmar/rust-axum-seaorm-boilerplate`
  (page-based and cursor-based pagination); `coreapostrophe/axum-template`
  (success/error envelopes + generated OpenAPI). None is a neutral authority
  on its own; together they corroborate that page-window params plus an
  items/total-style envelope is the documented template convention, with no
  shared pagination crate among them.
- Adopter check via reverse dependencies (crates.io API, 2026-09-19):
  `paginate` has 1 dependent (`wanisabi` 0.1.6, a Wanikani API binding fork —
  not a reference); `paginator-axum` has 1 external dependent
  (`acton-service` 0.43.1, 2,137 downloads, self-described backend
  framework — minor, not a reference); `paginator-utils` has 8 dependents,
  all same-family sibling crates; `sqlx-paginated` and `api-paginate` have 0.
  No candidate has a well-regarded external adopter.

Fit framing for this template (CLI + library + web service): the web service
is an optional `web` feature over an in-memory port (R69/R01); there is no
database layer in P02 scope, so any sqlx/SeaORM-bound helper is the wrong
layer. The pagination contract must satisfy binding W2-REST rules (below),
fit axum's per-handler typed-extractor model (R69: axum 0.8.9), and stay
generatable into OpenAPI by R71's eventual pipeline.

### Principles and implementation

Shared requirement: every collection-returning route exposes a bounded,
stable, self-describing page window. Source: py precedent WEB-03
(`page`/`size` query params, `items`/`total` body) generalized through the
research mandate, now bound by owner ruling W2-REST, the org REST API Design
Standard v2.0.0. Agreement level: capability + standard — the wire contract
(param names, envelope shape, defaults/maxima, empty-page semantics) must
agree across all collection routes; the Rust mechanism realizing it
(crate vs owned types) may vary, and does vary here for ecosystem reasons.

Essential behaviors (must agree): (1) a top-level object carrying items plus
continuation state, never a bare array (R6.1, lines 1133–1135); the envelope
carries `items` plus continuation (standard example E.4, lines 3039–3059;
Appendix rows lines 2861, 2895); (2) empty collection or empty window returns
`200` with an empty items array, never `404` (R6.2, lines 1154–1155;
conformance case line 3414); (3) page size uses the reserved name `limit`
(R6.5, lines 1194–1196; reserved register lines 336–337; R1.8 MUST, line 312);
each collection documents its default and maximum `limit`, and the maximum
is published and enforced (R11.1, lines 1678–1679); (4) a total, stable
default order is documented, ties broken by an immutable key (R6.6, lines
1207–1208); (5) no RFC 8288 `Link` headers for pagination — state lives only
in the body (R6.4, lines 1180–1184). May vary: page-index vs cursor mechanics
(R6.3, lines 1170–1175, is SHOULD-strength with a documented exception for
small/stable collections and jump-to-page UIs — this template's example
collection claims the small-collection exception and documents it);
continuation member names beyond `items` (`total`, `page`, `total_pages`)
are not reserved by the standard, so py's `items`/`total` vocabulary is kept.

W2-REST reconciliation (binding, not optional): py spells the page size
`size`; the standard reserves that concept's name as `limit`, and R1.8
requires a conforming API to use the reserved name when it offers the
capability. The template therefore ships `page`/`limit`, not py's
`page`/`size`. The principle (bounded window params + items/total envelope +
one shared mechanism) is preserved; only the size parameter's spelling
changes, as the binding ruling requires. No `CONFLICT:` line is needed: no
registered parameter value changes.

Answers to the prompt's Questions rows:

- HIGH (fastapi-pagination-equivalent crate?): No. The only axum-integrated
  candidate, `paginator-axum` 0.4.0 (`PaginationQuery` extractor +
  `PaginatorResponse<T>` envelope), fails this template on three independent
  grounds: its wire names are `page`/`per_page`, and `per_page` violates
  binding R1.8+R6.5 (`limit` is reserved); it ships `create_link_header`, an
  RFC 8288 pagination Link-header helper whose output R6.4 MUST-NOTs; and at
  6 stars, one maintainer, 46 commits, 8–15% documented, no declared
  rust-version, no utoipa integration, and zero well-regarded adopters, it is
  far below template-dependency maturity. `sqlx-paginated` is a sqlx query
  builder (wrong layer — no DB in P02 scope). `paginate` is index math with
  no HTTP surface. `api-paginate` has the right shape but is 7 days old with
  0 stars, 0 adopters, and a stale optional `utoipa ^4`.
- HIGH (app-wide registration vs per-route?): Rust's typed-extractor model
  requires per-route use — axum has no global extractor-registration hook,
  and neither does `paginator-axum` (its `PaginationQuery` implements
  `FromRequestParts` and is taken as a per-handler argument, exactly like
  `Query`). py's `add_pagination(app)` exists because FastAPI patches route
  response models at runtime; axum resolves extractors per handler at compile
  time. The idiomatic minimal-boilerplate uniform application is one shared
  module (`src/web/pagination.rs`) exporting one params struct and one
  generic envelope used by every collection handler — uniformity by shared
  type, checked by the compiler rather than by a factory call. Ledger F311
  ("wired app-wide via one factory call") therefore has no Rust-native
  realization; its intent (uniformity) is preserved, its mechanism is not.
- MEDIUM (items stay the caller's domain type?): Yes under the recommended
  design: `Page<T>` is generic over the caller's `T` (mirroring py's items
  staying `core.models` objects), verified by the executed probe where
  `Project` serializes unchanged inside the envelope. `paginator-utils` also
  satisfies this (`PaginatorResponse<T> { data: Vec<T>, meta }`).
- MEDIUM (OpenAPI integration?): No evaluated crate emits schema components
  automatically (`paginator-*` has no utoipa feature or dependency;
  `sqlx-paginated` has none; `api-paginate` offers optional `utoipa ^4`
  derives — stale vs the 5.x line). The hand-rolled alternative needs no
  manual per-route annotation either: production precedent (crates.io
  `pagination.rs`) derives `utoipa::IntoParams` on the same struct axum
  extracts, and utoipa 5.5.0's `IntoParams` derive generates query parameters
  from struct fields automatically. R71 owns generation; this item only
  requires that the params struct be a plain serde struct derives can attach
  to — satisfied.
- LOW (published template conventions?): Yes — see Landscape: at least three
  published Rust API templates/boilerplates document a page-window +
  envelope convention, and axum's own documentation teaches
  `Query<Pagination>`. None shares a pagination crate; the convention is a
  named pattern, not a shared dependency.

Architectural alternatives compared before choosing libraries:

1. Adopt `paginator-axum` + `paginator-utils` (closest to
   "fastapi-pagination for axum"). Rejected: R1.8/R6.5 wire-name violation,
   R6.4-conflicting helper, immature, no OpenAPI integration, and no
   app-wide advantage (still per-route). Figures below.
2. Adopt `sqlx-paginated`. Rejected: decides the database layer to get
   pagination — sqlx 0.9 + tokio + chrono + derive macro for a template whose
   P02 web service has no database; no axum extractor; heaviest compile cost.
3. Adopt `paginate` for window math + owned HTTP types. Rejected as a bundle
   member: `Pages::new(total, per_page)` computes offset/length, but the
   template still owns 100% of the HTTP contract (params, envelope,
   validation, OpenAPI derives); the crate saves ~5 lines of arithmetic while
   adding a dormant (2022) dependency with an undeclared MSRV. The arithmetic
   (`start = (page-1)*limit`, `div_ceil`) stays inline and tested.
4. Template-owned params struct + generic envelope on the R69 stack, no new
   crate (recommended). ~60 lines in one module; full control of binding wire
   names; zero new dependencies; utoipa-derivable; proven by crates.io
   production practice and the executed probe.

Candidate figures (retrieved 2026-09-19; endpoints per spec §7.6 with the
Transport-note substitutions for GitHub-API fields):

| Candidate | 90-day dl (`crate.recent_downloads`) | All-time dl (`crate.downloads`) | Last release (newest `yanked:false`: `num`, `created_at`) | Stars / forks / open issues (repo page) | License | rust-version |
|---|---|---|---|---|---|---|
| `paginate` 1.1.11 | 9,578 | 102,809 | 1.1.11, 2022-04-11 | 17 / 2 / 2 (daniel-samson/paginate; 112 commits) | Apache-2.0 | none declared |
| `paginator-axum` 0.4.0 | 7,012 | 12,233 | 0.4.0, 2026-09-07 | 6 / 6 / 0 (maulanasdqn/paginator-rs; 46 commits) | MIT | none declared |
| `paginator-utils` 0.4.0 | 8,447 | 16,921 | 0.4.0, 2026-09-07 | same repo as above | MIT | none declared |
| `paginator-rs` 0.4.0 | 8,417 | 16,606 | 0.4.0, 2026-09-07 | same repo as above | MIT | none declared |
| `sqlx-paginated` 0.6.2 | 2,069 | 22,435 | 0.6.2, 2026-08-17 | 25 / 4 / 0 (alexandrughinea/sqlx-paginated; 41 commits; issues page shows "No results") | MIT | none declared |
| `api-paginate` 0.1.1 | 28 | 28 | 0.1.1, 2026-09-12 | 0 / 0 / 0 (WyattAu/paginate; 12 commits) | MIT OR Apache-2.0 | 1.85 |

Fitness gates, answered per candidate before popularity is weighed:

1. License compatible with `MIT OR Apache-2.0`: all pass (`paginate`
   Apache-2.0; `paginator-*` and `sqlx-paginated` MIT; `api-paginate`
   MIT OR Apache-2.0).
2. Crate and dependency-tree MSRV within the policy (floor ≈ 1.96; local
   stable is 1.98.0): only `api-paginate` declares `rust-version` (1.85 —
   below the floor, hence compatible in principle, but CI proof is
   unavailable: gap). All others declare no `rust-version`: unverifiable
   from metadata (gap); none is known to require a newer compiler, so no
   failure is recorded — but no pass is claimed either.
3. No open RustSec advisory; `unsafe` posture stated:
   `https://rustsec.org/packages/<name>.html` returns 404 (no advisories
   page) for `paginate`, `paginator-axum`, `paginator-utils`,
   `sqlx-paginated`, and `api-paginate`, calibrated against
   `.../rsa.html` rendering RUSTSEC-2023-0071 — all clean. `unsafe`:
   `api-paginate` declares `#![forbid(unsafe_code)]` (repo README);
   `paginate` is zero-dependency index math with `Send+Sync` auto traits
   and no unsafe in its documented API (source unread — gap);
   `paginator-*`/`sqlx-paginated` sources unread (crate download blocked —
   gap).
4. Builds and is tested on `ubuntu-latest, macos-latest`: unverified for all
   (CI badges/workflows not inspected — gap). All candidates are pure Rust
   over portable dependencies, so no OS-specific failure is expected, but
   that is an inference, not evidence.
5. Default features and async-runtime coupling stated (from
   `GET /api/v1/crates/<name>/<version>/dependencies`): `paginate`: no
   dependencies at all. `paginator-axum`: no own features; axum
   `default-features = false` with `json,query`; tokio is dev-only —
   no runtime coupling. `paginator-utils`/`paginator-rs`: serde/serde_json
   (+ base64 for utils) only. `sqlx-paginated`: no own features; couples
   tokio (normal) + sqlx 0.9 (postgres, sqlite, uuid, chrono, json) +
   chrono + tracing + a derive macro — the heaviest tree. `api-paginate`:
   zero required dependencies; optional serde (`serde_impl`, default) and
   optional `utoipa ^4` (`openapi`) — note the utoipa major is stale
   (5.x current, 5.5.0 released 2026-07-11).
6. Binary-size and compile-time cost, qualitative: `paginate` and
   `api-paginate` (without optionals) are negligible; `paginator-axum` is
   small and overlaps the stack (axum/serde/serde_json/http) plus
   async-trait/base64/form_urlencoded; `sqlx-paginated` is heavy (a second
   database framework in the tree).

No candidate fails a hard gate (1/3 pass everywhere; 2/4 are gaps, not
failures), so `Excluded by gate` records none and the rejections above are
on fitness for this template — recorded under each member's shortlist and
tradeoffs. Maintenance rubric: `paginate` stable-quiet trending dormant
(no release since 2022, but zero-dep math needs none — no at-risk signal, so
not `dormant` by the rubric); `paginator-*` active (released 12 days ago)
but brand-new and single-maintainer; `sqlx-paginated` active;
`api-paginate` active but 7 days old. Issue responsiveness: no medians
computed (GitHub API blocked — gap); open counts are 2 (`paginate`), 0
(`paginator-rs`, `sqlx-paginated`, `api-paginate`'s repos).

Minimal realistic example and executable acceptance check: the probe in
`### Validation strategy` (executed 2026-09-19: 3/3 tests pass on axum
0.8.9 + tokio 1.53.1 + tower 0.5.3, the exact R69 pins). Proposed template
checks not yet run are labeled planned. No `BASELINE-REVIEW:` finding: this
item challenges no recorded REUSE/ADOPT baseline — the prompt frames
adoption as open, and the `size`→`limit` spelling change is required by the
binding W2-REST ruling, recorded above, not a baseline challenge.

### Recommendation

One stack: no pagination crate is adopted. The template ships a
template-owned `src/web/pagination.rs` module with a `Pagination { page,
limit }` request struct (serde `Deserialize`; `page` defaults to 1 and
rejects 0 with `400`; `limit` defaults to 20 and is clamped to `1..=100`)
extracted per route via `axum::extract::Query` (axum 0.8.9, assumed from
R69), plus a generic `Page<T> { items, total, page, limit, total_pages }`
response envelope (serde `Serialize`) returned via `axum::Json`. Every
collection route uses these two types. The route documentation claims the
R6.3 small-collection exception, documents the stable default order with an
`id` tiebreak (R6.6), and documents the default and maximum `limit`
(R6.5/R11.1). When R71 lands, `utoipa::IntoParams` is derived on
`Pagination` and `utoipa::ToSchema` on `Page<T>` with no per-route
annotation (crates.io precedent).

### Members

#### page-window-params

##### Landscape

Request-side capability: parse and validate the page-window query
parameters. Map: first-party `axum::extract::Query` over an owned struct
(the axum-documented idiom); no established crate; up-and-comers
`paginator-axum::PaginationQuery` (per-route `FromRequestParts` extractor
over `page`/`per_page`/`cursor` + filters/search/sort) and
`api-paginate::PaginationParams` (7 days old). Authorities and practice
evidence: as in the top-level Landscape.

##### Principles and implementation

Must agree: the wire names (`page`, reserved `limit`), the defaults
(1 / 20), the enforced maximum (100), and `page = 0` → `400`
(validation-failure rendering itself is R70's; the rejection decision is
this item's). The params struct MUST be a plain serde struct so R71's
derives attach without per-route annotation. Uniformity across routes comes
from sharing this one type, not from a registration call — axum resolves
extractors per handler at compile time (`FromRequestParts`), and
`paginator-axum` works the same way, so no candidate offers an app-wide
mechanism to prefer.

##### Dominant choice

`axum::extract::Query<Pagination>` with a template-owned `Pagination`
struct (axum 0.8.9, assumed from R69; serde `Deserialize`). Dominant by
first-party standing (axum's own docs teach this shape), production
precedent (crates.io), zero new dependencies, and full control of the
binding wire names. Crate figures: inapplicable — this member adds no
crate; axum's figures belong to R69, which owns the framework decision.

##### Qualified shortlist

`paginator-axum::PaginationQuery` 0.4.0: passes hard gates (MIT, no
advisories) but is not selected — `per_page` wire name violates binding
R1.8+R6.5; 6 stars / single maintainer / 46 commits / 15.38% documented /
no rust-version / no utoipa integration; pulls async-trait + base64 +
form_urlencoded for no capability the template needs; and is still a
per-route extractor, so it buys nothing over `Query` on the F311
uniformity axis. `api-paginate::PaginationParams` 0.1.1: right shape
(offset + cursor types, optional utoipa) but 0.1.1, 7 days old, 0 stars,
0 adopters, optional `utoipa ^4` stale — re-verify candidate, not a
selection.

##### Excluded by gate

None. No evaluated params candidate fails license (gate 1) or advisory
(gate 3) gates; MSRV (gate 2) and OS-matrix (gate 4) evidence is
unavailable (gaps recorded above), which withholds a pass without
recording a failure. Rejections are on template fitness, recorded in
`Qualified shortlist` and `Tradeoffs`.

##### Up-and-comers

`api-paginate` (offset + cursor types, `#![forbid(unsafe_code)]`,
optional serde/utoipa, rust-version 1.85): the only candidate whose API
shape anticipates both R6.3 pagination styles and R71 OpenAPI derives.
Watch for a 1.0 with utoipa 5 support and external adopters; too young at
0.1.1 / 28 downloads to carry a template (re-verify trigger below).

##### Fit for this template

`Query<Pagination>` fits exactly: the R69 stack already contains axum with
the `query` feature and serde; the params are two integers with defaults
and a clamp (~25 lines); out-of-range values are decided here and rendered
by R70. `sqlx-paginated::FlatQueryParams` does not fit (deserializes into
a sqlx query builder — wrong layer, no DB in scope). `paginate` does not
fit (no HTTP surface at all).

##### Recommendation

`axum::extract::Query<Pagination>`, template-owned struct, no new crate.

##### Ranked runner-up

`paginator-axum::PaginationQuery`: the only runner-up with an axum
extractor. Ranked below solely because its wire names cannot satisfy
binding W2-REST rules and its maturity is far below the bar; if a future
1.x renames to `limit`, drops the Link-header helper, declares MSRV, and
gains utoipa support plus adopters, it becomes selectable.

##### Tradeoffs

Owned struct: template owns ~25 lines forever (trivial, stable API —
query params do not churn) in exchange for exact wire-name control, zero
dependency risk, and no maturity gamble. Crate: outsources ~25 lines to a
6-star 12-day-old crate while violating two binding MUST-level rules —
strictly worse on every axis except line count.

##### Parameters

Assumes `rust-edition = 2024`, `license = MIT OR Apache-2.0`,
`target-os-matrix = ubuntu-latest, macos-latest`, and R69's axum 0.8.9
with the `query` feature (related, not consumed — R69 owns
`web-extra-surface`; this member uses it as-is). No `CONFLICT:` lines.

##### Migration implications

New file `src/web/pagination.rs` (inside R69's gated `src/web/` tree, so
it is on when `web` is on and absent when off): `Pagination` struct +
`Default`/`clamp` constructors. Each collection handler adds one
`Query<Pagination>` argument. No `Cargo.toml` change (axum/serde already
required by the `web` feature).

##### Validation strategy

Executed probe (`/tmp/r72probe`, axum 0.8.9 + tokio 1.53.1 + tower 0.5.3,
`cargo test --offline`, 2026-09-19): `?page=2&limit=5` slices correctly;
bare `/projects` yields `(page, limit) = (1, 20)`; `limit=9999` clamps to
100; `page=99` returns 200 with empty items; `page=0` returns 400 — 3/3
pass. Planned (template): same assertions against the template's
`/projects` route plus a compile-fail lint that every collection handler
takes `Query<Pagination>` (by code review, not automation).

##### Confidence & re-verify trigger

High. Re-verify when any of: R69's published decision moves off axum;
R71 selects a non-utoipa generator that cannot derive params from a serde
struct; `api-paginate` ships a 1.x with utoipa 5 support and credible
adopters; or W2-REST amends the `limit` reservation.

##### Sources

axum 0.8.9 `src/extract/query.rs` (local cargo cache, pinned);
`https://docs.rs/paginator-axum/latest/paginator_axum/` (2026-09-19);
`https://docs.rs/paginator-axum/latest/paginator_axum/struct.PaginationQuery.html`
(2026-09-19); `https://docs.rs/paginator-utils/latest/paginator_utils/struct.PaginationParams.html`
(2026-09-19); `https://github.com/maulanasdqn/paginator-rs` (2026-09-19);
`https://github.com/WyattAu/paginate` (2026-09-19);
`GET https://crates.io/api/v1/crates/{paginator-axum,paginator-utils,api-paginate}`
+ `/versions` + `/<version>/dependencies` (2026-09-19);
`https://rustsec.org/packages/{paginator-axum,api-paginate}.html` → 404 =
clean, calibrated vs `.../rsa.html` (2026-09-19).

#### page-envelope

##### Landscape

Response-side capability: wrap a page of caller-owned items with the
continuation state. Map: first-party `axum::Json` over an owned generic
struct; no established crate; up-and-comers `paginator-utils::
PaginatorResponse<T> { data: Vec<T>, meta: PaginatorResponseMeta }` (with
`page/per_page/total/total_pages/has_next/has_prev/next_cursor/
prev_cursor`) and `api-paginate::{PaginatedResponse<T>, CursorResponse<T>}`.
`sqlx-paginated::PaginatedResponse` exists but is coupled to its query
builder. Authorities and practice evidence: as in the top-level Landscape.

##### Principles and implementation

Must agree: top-level object with `items` plus continuation (R6.1);
`200` + empty items for empty windows (R6.2); items serialize as the
caller's domain type with no wrapper-type conversion (py WEB-03
principle); the envelope MUST be a plain serde-generic struct so R71's
`ToSchema` derive attaches. `total`/`page`/`limit`/`total_pages` member
names are the template's choice (unreserved) and follow py's
`items`/`total` vocabulary. `PaginatorResponse`'s `data`+`meta` split is
conformant in shape (object + continuation) but renames py's `items` for
no gain and drags cursor/filter/search/sort machinery the template does
not need.

##### Dominant choice

Template-owned generic `Page<T> { items: Vec<T>, total: usize, page: u32,
limit: u32, total_pages: usize }` returned via `axum::Json` (axum 0.8.9 +
serde/serde_json, assumed from R69). Dominant by wire-name control
(`items` per the standard's example E.4; `total` per py precedent),
zero new dependencies, and derive-readiness for R71. Crate figures:
inapplicable — this member adds no crate.

##### Qualified shortlist

`paginator-utils::PaginatorResponse<T>` 0.4.0: passes hard gates (MIT, no
advisories; deps base64/serde/serde_json only) and keeps items generic,
but is not selected — `data`/`meta` naming abandons the `items` vocabulary
without cause; 8.11% documented; same 6-star single-maintainer 0.4.0
provenance; no utoipa integration; and its `meta` bakes in cursor/filter/
search/sort surface this template must not ship (R6.7/R6.8-style
capabilities are not decided and each needs its own documented contract).
`api-paginate`'s response types: same too-young verdict as its params
member. `sqlx-paginated::PaginatedResponse`: inseparable from the sqlx
builder — wrong layer.

##### Excluded by gate

None, for the same reason as the params member: gates 1 and 3 pass for
every evaluated envelope candidate; gates 2 and 4 are evidence gaps, not
failures. Rejections are on template fitness.

##### Up-and-comers

`api-paginate`'s `PaginatedResponse<T>` / `CursorResponse<T>`: the only
envelope design that already separates offset and cursor styles and
anticipates utoipa derives. Same re-verify trigger as the params member.

##### Fit for this template

`Page<T>` fits exactly: five serde fields, generic over the domain type
(the probe serializes `Project { id, name }` unchanged inside `items`),
`Json` already in the R69 feature set. `PaginatorResponse` does not fit
(naming + undecomposed scope + maturity). `paginate::Page
{ offset, length, start, end }` is not an HTTP envelope at all (no serde
impls) and does not fit.

##### Recommendation

Template-owned generic `Page<T>` via `axum::Json`, no new crate.

##### Ranked runner-up

`paginator-utils::PaginatorResponse<T>`: only ranked envelope crate that
is axum-adjacent and generic over `T`. Ranked below for naming,
undecomposed scope, maturity, and missing OpenAPI integration.

##### Tradeoffs

Owned envelope: ~15 lines owned forever (serialization shape is template
API surface — owning it is correct) in exchange for exact W2-REST/py
vocabulary and zero dependency risk. Crate: renames the contract's most
visible member, ships undecided filter/sort surface, and bets the
template's wire format on a 12-day-old crate.

##### Parameters

Assumes `rust-edition = 2024`, `license = MIT OR Apache-2.0`,
`target-os-matrix = ubuntu-latest, macos-latest`, and R69's axum 0.8.9
with the `json` feature (related, not consumed). No `CONFLICT:` lines.

##### Migration implications

Same new file `src/web/pagination.rs`: generic `Page<T>` struct +
`Page::new(items, total, page, limit)` constructor. Each collection
handler returns `Json<Page<DomainType>>`. No `Cargo.toml` change. The
OpenAPI snapshot (R71/R83) gains the envelope schema when derives land.

##### Validation strategy

Executed probe (same run as params member): envelope assertions
(`total == 23`, first item `id == 6` on page 2, `total_pages == 5`,
empty-items 200, clamped `limit` echoed) — 3/3 pass. Planned (template):
contract test asserting the `/projects` response shape
(`items/total/page/limit/total_pages`), the R6.2 empty-window case, and
`request-id`-style envelope stability across routes.

##### Confidence & re-verify trigger

High. Re-verify when any of: R69 moves off axum; R71 needs a
non-serde-generic envelope (unlikely — utoipa `ToSchema` derives on
generics); W2-REST reserves envelope member names beyond `items`; or
`api-paginate` 1.x matures as above.

##### Sources

`https://docs.rs/paginator-utils/latest/paginator_utils/` (2026-09-19);
`.../struct.PaginatorResponse.html` and
`.../struct.PaginatorResponseMeta.html` (2026-09-19);
`https://github.com/WyattAu/paginate` README (features list, 2026-09-19);
`GET https://crates.io/api/v1/crates/{paginate,paginator-utils,sqlx-paginated,api-paginate}`
+ `/versions` + `/<version>/dependencies` + `/reverse_dependencies`
(2026-09-19); `https://rustsec.org/packages/{paginate,paginator-utils,sqlx-paginated}.html`
→ 404 = clean (2026-09-19); rust-lang/crates.io
`src/controllers/helpers/pagination.rs` (`Paginated<T>`, 2026-09-19).

### Compatibility

Both members were executed together in one probe binary (`/tmp/r72probe`,
`cargo test --offline`, 2026-09-19, 3/3 pass) on exactly the R69-decided
pins — version matrix: axum 0.8.9, tokio 1.53.1, tower 0.5.3 (oneshot test
idiom), serde 1.0.228, serde_json 1.0.143+, http 1.5.0. `cargo tree
--offline -e normal` shows the probe adds zero packages beyond the R69
stack (axum, axum-core 0.5.6, hyper/util, tower, serde, serde_json,
form_urlencoded, http — all already required). No version conflict is
possible: the members introduce no new crates. Shared-adopter proof is
inapplicable (no new crates to co-adopt); the crates.io production
precedent demonstrates the same two halves (`PaginationQueryParams` +
`Paginated<T>`) composed in one service.

### Parameters

Assumes `rust-edition = 2024`.
Assumes `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`.
Assumes `target-os-matrix = ubuntu-latest, macos-latest`.
Assumes `license = MIT OR Apache-2.0`.
Related (not consumed — R69 owns `web-extra-surface`): this answer is
built on R69 revision 9 (2026-09-16): axum 0.8.9 with default features
(including `query`, `json`), tokio 1.53.1, tower 0.5.3 dev-only, behind
the off-by-default `web` feature; the pagination module lives in that
gated `src/web/` tree. No owned parameters. No `CONFLICT:` lines.

### Migration implications

- New: `src/web/pagination.rs` — `Pagination { page: u32, limit: u32 }`
  (`Deserialize`, defaults 1/20, `limit` clamped `1..=100`, `page == 0`
  rejected) and `Page<T> { items, total, page, limit, total_pages }`
  (`Serialize`, `T: Serialize`).
- New: `src/web/pagination.rs` unit/contract tests (defaults, clamp,
  slicing, empty-window 200, `page=0` 400) mirroring the executed probe.
- Edit: each collection handler (starting with the projects list route)
  takes `Query<Pagination>` and returns `Json<Page<Project>>`.
- Edit: route documentation strings claim the R6.3 small-collection
  exception and document the default order (`id` tiebreak) and the
  default/maximum `limit`.
- No `Cargo.toml` change (axum/serde/serde_json already in the `web`
  feature); no new feature; no app-wide registration call anywhere (there
  is nothing to register — F311's factory-call mechanism has no Rust
  realization by design).
- Later, when R71 lands: add `#[derive(utoipa::IntoParams)]` to
  `Pagination` and `#[derive(utoipa::ToSchema)]` to `Page<T>` + the domain
  item type (crates.io precedent:
  `#[from_request(via(axum::extract::Query))]`,
  `#[into_params(parameter_in = Query)]`).

### Validation strategy

Executed (2026-09-19, `/tmp/r72probe`, toolchain `rustc 1.98.0`,
`cargo test --offline`):

```text
running 3 tests
test tests::probe_page_slice ... ok
test tests::probe_empty_page_and_bad_page ... ok
test tests::probe_defaults_and_clamp ... ok

test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
```

The probe is a standalone axum 0.8.9 service with the recommended
`Pagination`/`Page<T>` types and a 23-item projects route, exercised via
`tower::ServiceExt::oneshot` (R69's test idiom). It proves: window
slicing (`?page=2&limit=5` → items 6–10, `total 23`, `total_pages 5`);
defaults (`/projects` → `page 1`, `limit 20`); R11.1 enforcement
(`limit=9999` → clamped to 100); R6.2 (`page=99` → 200 with
`items: []`, `total: 23`); and `page=0` → 400. Dependency proof:
`cargo tree --offline -e normal` shows no package beyond the R69 stack.

Planned (not run — template does not exist yet): replicate the probe's
assertions as the template's `src/web/` contract tests; add an OpenAPI
snapshot assertion for the envelope once R71's derives land; verify
`cargo build --offline` MSRV-floor behavior per the declared
`rust-version` in CI (gate 2/4 gaps above close only with real CI runs).

### Confidence & re-verify trigger

Confidence: high for the no-new-crate recommendation (binding wire-name
rules eliminate the only integrated crate; production precedent and an
executed probe support the owned pattern); medium for the exact
default/maximum (`20`/`100` — `100` follows crates.io's `MAX_PER_PAGE`,
`20` is judgment balancing py's `50` against crates.io's `10`).
Re-verify when: R69 moves off axum; R71 selects a generator incompatible
with serde-struct derives; W2-REST amends §6 or the `limit` reservation;
`api-paginate` reaches 1.x with utoipa 5 support and credible adopters;
or `paginator-axum` 1.x renames to `limit`, drops the Link helper,
declares MSRV, and gains adopters.

### Sources

- Prompt + run inputs: `research/runs/R72/2026-09-18T215915Z-af997c2abb5a/inputs/{prompt.md,prerequisites.json,parameters.json,owner-reference-axum-companion-stack-2026-09-16.md}`.
- Ledger: `docs/port/COMMONALITY.md` rows F310/F311 (lines 314–315).
- py precedent: `/Users/stevemorin/c/py-launch-blueprint/src/py_launch_blueprint/web/routers/projects.py:30`,
  `web/app.py:204`, `pyproject.toml:59`. ts absence:
  `docs/port/areas/web-service.md:90-110` + `/Users/stevemorin/c/ts-launch-blueprint/src`
  (no web module).
- R69 prerequisite: `research/topics/69-web-framework-stack/DECISION.md`
  revision 9 (2026-09-16): axum 0.8.9, tokio 1.53.1, tower 0.5.3, `web`
  feature. R60/R67 acceptances noted via `docs/port/OWNER-ACCEPTANCES.md`
  (context only).
- W2-REST: smorinlabs/rest-standards commit `0850d43e`,
  `rest-api-standard.md` via `git show` (no checkout): R1.8 line 312;
  R6.1–R6.6 lines 1133–1208; R11.1 line 1678; reserved register lines
  336–337; example E.4 lines 3039–3059; Appendix rows lines 2716–2718,
  2861, 2895; conformance case line 3414.
- axum 0.8.9 `src/extract/query.rs` (pinned source, local cargo cache).
- `https://docs.rs/paginate/latest/paginate/` and
  `.../struct.Page.html` (2026-09-19).
- `https://docs.rs/paginator-axum/latest/paginator_axum/` (+
  `struct.PaginationQuery.html`, `/crate/paginator-axum/latest/features`;
  2026-09-19).
- `https://docs.rs/paginator-utils/latest/paginator_utils/` (+
  `struct.PaginationParams.html`, `struct.PaginatorResponse.html`,
  `struct.PaginatorResponseMeta.html`; 2026-09-19).
- `https://docs.rs/sqlx-paginated/latest/sqlx_paginated/` (2026-09-19).
- `https://docs.rs/utoipa/latest/utoipa/derive.IntoParams.html` (utoipa
  5.5.0; 2026-09-19).
- `https://github.com/maulanasdqn/paginator-rs`,
  `https://github.com/alexandrughinea/sqlx-paginated` (+ `/issues`),
  `https://github.com/daniel-samson/paginate`,
  `https://github.com/WyattAu/paginate`,
  `https://github.com/rust-lang/crates.io/blob/main/src/controllers/helpers/pagination.rs`
  (all 2026-09-19).
- `GET https://crates.io/api/v1/crates/<name>` (+ `/versions`,
  `/<version>/dependencies`, `/reverse_dependencies`) for `paginate`,
  `paginator-axum`, `paginator-rs`, `paginator-utils`, `sqlx-paginated`,
  `api-paginate`, `pagination`, `acton-service`, `wanisabi` (2026-09-19).
- `https://rustsec.org/packages/{paginate,paginator-axum,paginator-utils,sqlx-paginated,api-paginate}.html`
  → 404 (no advisories), calibrated against `.../rsa.html` → 200 with
  RUSTSEC-2023-0071 (2026-09-19).
- Web search `rust axum REST API template pagination Query page per_page
  envelope example` (2026-09-19): axum `extract.md` Pagination example,
  `99minutos/template-agents-rust` Pagination pattern,
  `hendrixmar/rust-axum-seaorm-boilerplate`,
  `coreapostrophe/axum-template`.
- Executed probe: `/tmp/r72probe` (`cargo test --offline`, 3/3 pass,
  2026-09-19; toolchain rustc 1.98.0).
