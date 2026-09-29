# Raw research answer — R70 HTTP problem envelope (bundle, engine muse)

Engine: muse (Meta). Retrieval date for all live figures: 2026-09-25.

### Landscape

Category decided: web-service error-response contract — the envelope type for every non-2xx response plus the domain-error-to-HTTP-status mapping mechanism.

Three-bin map of the Rust field:

- Built-in / first-party toolchain: no std or first-party RFC 9457 envelope type exists. The closest first-party surface is the framework's error-handling extension point itself: axum (tokio-rs) `IntoResponse` + `Fallback`/`HandleErrorLayer` + extractor rejections (axum repo examples `error-handling`, `customize-extractor-error`, `global-404-handler`, all present 2026-09-25). Std contributes only `std::error::Error` and `Display`.
- Established industry standard: `http-api-problem` v0.60.0 (RFC 7807/9457 `application/problem+json` type with optional `axum`, `actix-web`, `warp`, `salvo`, `tide`, `hyper`, `rocket` integrations) — 627,039 all-time / 53,396 recent downloads; `thiserror` v2.0.21 as the de-facto domain-error derive (1,509,629,457 all-time downloads) behind any hand-rolled status-mapping trait. `http` crate `StatusCode` as the status vocabulary.
- Up-and-comer: `problemdetails` v0.7.0 (MIT, rust-version 1.85.1, `axum` + `poem` features) — 48,464 all-time / 9,684 recent downloads; `http-api-problem-derive` companion derive macro.

Shortlisted candidates come from this map: `http-api-problem` (envelope crate), hand-rolled status-mapping trait + `match` (pattern member), `problemdetails` (runner-up), `http-api-problem-derive` (considered, not recommended).

Authoritative sources and why each counts: RFC 9457 (https://www.rfc-editor.org/rfc/rfc9457.html, HTTP 200 on 2026-09-25) — the normative envelope standard, obsoletes RFC 7807 keeping `application/problem+json`; axum repository and examples (tokio-rs team publication, the leading async framework's own documented error-handling pattern); docs.rs + crates.io API (maintainers' own published metadata: versions, licenses, features, rust-version); GitHub API (stars/archived/pushed_at/open-issue counts); RustSec package pages (advisory record; both candidate pages return HTTP 404, i.e. no advisory ever filed).

Practice evidence: axum's own examples (`error-handling`: anyhow/thiserror domain errors rendered via `IntoResponse`; `customize-extractor-error`: reshaping `Json` rejections; `global-404-handler`: fallback for framework 404s — all in tokio-rs/axum, the tokio team's flagship framework, 485,420,454 all-time axum downloads). `http-api-problem` records 8 direct reverse dependencies on crates.io (meta.total via reverse_dependencies endpoint, 2026-09-25); parent crate names not resolved (gap — endpoint rows carry version ids, not parent names; recorded after one attempt, not retried further). No published Rust template found that names a "one envelope for every non-2xx response" policy verbatim (LOW-question gap, stated not filled).

Fit over abstract best: the template needs py parity (py `web/problems.py:52` PROBLEM_CONTENT_TYPE on all handlers + `web/problems.py:57` ERROR_STATUS table, WEB-01) inside a CLI + library + web-service template, framework-agnostic until R69 resolves, and generic over R67's undecided error taxonomy. Judged on that fit, not on standalone popularity.

### Principles and implementation

Shared requirement (from py precedent, spec section 2, F305/F306, verdict DIVERGENT): every non-2xx HTTP response — domain errors, bare framework errors, and framework validation errors alike — renders as one RFC 9457 `application/problem+json` envelope; domain error types map to HTTP statuses through one typed lookup. Source: py `src/py_launch_blueprint/web/problems.py:52,57`. ts has no web service (`docs/port/areas/web-service.md:100`), so there is nothing to reconcile. Agreement level: architectural pattern + policy for the web crate (the envelope contract and the single-mapping-table rule must agree; the concrete enum shape may vary once R67 resolves). No BASELINE-REVIEW finding: the py precedent is retained, not challenged.

Essential behaviors: (1) uniform `Content-Type: application/problem+json` on all 4xx/5xx; (2) one constructor path so handlers cannot emit bare JSON errors; (3) framework 404/405 routed through the same envelope via the framework's fallback/catch-all hook; (4) extractor/validation rejections (the FastAPI-422 analogue) reshaped into the envelope; (5) status lookup total over the domain error type (exhaustive `match`, no default arm hiding new variants).

Observable acceptance criteria: GET unknown route returns 404 with problem+json body; invalid JSON body returns 4xx problem+json (not the framework default shape); each domain error variant returns its mapped status with `title`/`status`/`detail` fields; `Content-Type` is exactly `application/problem+json` on all of them; adding a domain variant without a mapping fails to compile (exhaustive match).

Architectural alternatives compared: (A) envelope crate + framework adapter + trait mapping (recommended) — smallest hand-rolled surface, keeps RFC field semantics maintained upstream; (B) fully hand-rolled problem struct — full control, but re-implements and re-tracks RFC field semantics and every framework integration; (C) framework-native error JSON (e.g. axum's default rejection bodies) — rejected: violates the single-envelope principle and py parity. Libraries evaluated after the pattern choice: `http-api-problem` vs `problemdetails` vs hand-rolled struct; `match`-in-`IntoResponse` vs per-variant trait method vs `http-api-problem-derive`.

How the design preserves each principle: the `http-api-problem` `HttpApiProblem` type owns RFC field semantics; a thin `web::problems` module owns the `into_problem()` constructor and the exhaustive status `match` (the ERROR_STATUS analogue); framework hooks (fallback, rejection map, error layer) all funnel into that one constructor, so the "single envelope" policy holds regardless of which framework R69 picks. Ecosystem difference from py: Python maps via `dict[type, int]` at runtime; Rust maps via an exhaustive `match` at compile time, which additionally enforces totality — a stricter realization of the same principle.

Maturity/dependability/performance/integration cost: `http-api-problem` 0.60.0 is stable-quiet (2025-01-06 release; repo not archived; axum integration via still-current `axum-core ^0.5`); `problemdetails` 0.7.0 is fresh (2026-04-23) but an order of magnitude less adopted. Error-path serialization cost is negligible either way (no hot-path benchmark warranted; workload = error responses only). Integration cost: one small module plus three framework hook registrations.

Minimal realistic example: axum router with (1) a domain error enum implementing the status trait, (2) `fallback(handler_404)` returning the envelope, (3) `Json` extractor rejection mapped to 422-envelope, (4) a route returning `Result<Json<_>, AppError>` where `AppError: IntoResponse` builds the envelope. Executable acceptance check: `cargo test` asserting status + content-type + `title`/`status` fields for a 404, a 422, and one domain error each. Proposed, not executed (no commands run in this research pass).

### Recommendation

One stack: adopt the single RFC 9457 `application/problem+json` envelope for every non-2xx response (F305/F306 = yes), composed of member `http-api-problem` v0.60.0 (envelope type + framework `IntoResponse` integration) and member `status-mapping` (hand-rolled exhaustive status-mapping trait + `match` in the web crate, generic over R67's taxonomy).

### Members

#### http-api-problem

##### Landscape

Envelope-type crate bin: established standard. `http-api-problem` 0.60.0 vs up-and-comer `problemdetails` 0.7.0 vs hand-rolled struct. Built-in bin is empty (no std/first-party problem type). Authority: RFC 9457 (normative), crates.io/docs.rs metadata, GitHub repo state, axum's documented `IntoResponse` extension point.

##### Principles and implementation

Carries the F305 half: a maintained, RFC-shaped `application/problem+json` body type so the template never hand-rolls field semantics. Integrates at the framework's error extension point via the optional `axum` feature (`axum-core ^0.5.0`, still the current axum-core line under axum 0.8.9, so no version conflict). Framework 404/405 and validation rejections are NOT covered by the crate alone — they need the thin adapter in the web crate (fallback + rejection mapping funnelling into one constructor). Note: crate documentation is written against RFC 7807; the wire contract (`application/problem+json`, `type`/`title`/`status`/`detail`) is identical under RFC 9457, so no incompatibility; 9457-specific `type`-URI conventions are a template-side choice.

##### Dominant choice

`http-api-problem` v0.60.0 (created 2025-01-06T18:20:07.392199Z; license Apache-2.0/MIT per version detail; features include `axum`, `actix-web`, `warp`, `salvo`, `tide`, `hyper`, `rocket-okapi`, `api-error`, `json-schema`). Figures (crates.io API + GitHub API, 2026-09-25): all-time downloads 627,039; 90-day downloads 53,396; stars 62; archived false; pushed_at 2025-01-06T18:16:29Z; open issues 3 (search-issues total_count, never open_issues_count). Maintenance state: stable-quiet — the >6-month-release trigger was investigated: no RustSec page (HTTP 404 = no advisory filed), no known build breakage on current stable, optional deps on current majors, repo not archived. `unsafe` posture: none declared by the crate's pure data-type core (gap: full dependency-tree audit not run; tree is http/serde/serde_json + optional framework glue).

##### Qualified shortlist

`problemdetails` v0.7.0 (created 2026-04-23T10:59:26.949163Z; license MIT; rust-version 1.85.1; features `axum`, `poem`): all-time 48,464 / 90-day 9,684 downloads; stars 10; archived false; pushed_at 2026-04-23T10:59:30Z; open issues 3. Passes gates but loses on adoption depth (13x fewer all-time downloads) and narrower framework optionality (axum/poem only vs R69 still open). Kept as ranked runner-up.

##### Excluded by gate

None of the envelope-crate candidates fails a fitness gate. Fully hand-rolled envelope struct excluded by design fit (duplicates maintained RFC semantics), not by gate.

##### Up-and-comers

`problemdetails` (above) is the up-and-comer to watch; `http-api-problem-derive` (companion derive for status mapping) tracked under the status-mapping member.

##### Fit for this template

Framework-agnostic core with per-framework optional features fits R69-open exactly: enable the winning framework's feature without changing envelope code. `serde`/`serde_json`-based body composes with the OpenAPI pipeline (R71 documents the shape; sync owned by R71). MSRV: crate declares no rust-version (None); core deps (`http ^1.2`, `serde ^1`, `serde_json ^1`) build on current stable; empirical MSRV check planned in Validation strategy. OS: pure-Rust + serde, no platform-specific code; CI badge check is a gap (repo CI file not inspected). Default features: `default` feature exists; recommended enablement = `default-features = false, features = ["axum"]` (or R69 winner), keeping the tree minimal. Binary/compile cost: one small serde type + one framework glue impl; negligible.

##### Recommendation

Use `http-api-problem` v0.60.0 as the envelope type, with only the R69-winning framework feature enabled.

##### Ranked runner-up

`problemdetails` v0.7.0 — prefer if a future release shows broader framework support and the template values the freshest release over adoption depth.

##### Tradeoffs

Adoption + framework breadth (`http-api-problem`) vs recency + declared rust-version (`problemdetails`). Narrow `unsafe`/audit visibility on both (small single-maintainer crates; `http-api-problem` 62 stars / `problemdetails` 10 stars). Neither crate covers framework 404/validation reshaping — that adapter is hand-rolled either way (see status-mapping member and Compatibility).

##### Parameters

Member-level: assumes web-framework-stack = (R69 undecided; member works with any of axum/actix-web/warp/salvo/tide via its optional features). No CONFLICT.

##### Migration implications

Add `http-api-problem = { version = "0.60.0", default-features = false, features = ["axum"] }` (feature name follows R69) to the web crate's `Cargo.toml`; add `web::problems` module constructing `HttpApiProblem` values; register fallback + rejection mapping + error layer per framework.

##### Validation strategy

Planned (not executed): `cargo tree -p http-api-problem -e normal --features axum` (assert minimal tree); `cargo build` on ubuntu-latest + macos-latest (gate 4); `cargo deny`/audit run for advisories; example test asserting `Content-Type: application/problem+json` on 404/422/domain-error responses. Expected: all green, identical envelope shape across the three paths.

##### Confidence & re-verify trigger

Medium-high. Re-verify if: R69 picks a framework the crate does not support; a new major changes the `axum` feature's axum-core bound; an advisory is filed; or 2027-03-25 passes without a release (stable-quiet review).

##### Sources

- RFC 9457: https://www.rfc-editor.org/rfc/rfc9457.html (200, 2026-09-25)
- Crate meta: GET https://crates.io/api/v1/crates/http-api-problem (downloads 627039, recent_downloads 53396, 2026-09-25)
- Versions: GET https://crates.io/api/v1/crates/http-api-problem/versions (0.60.0, 2025-01-06T18:20:07.392199Z, license Apache-2.0/MIT, 2026-09-25)
- Deps: GET https://crates.io/api/v1/crates/http-api-problem/0.60.0/dependencies (http/serde/serde_json + optional glue, 2026-09-25)
- Repo: GET https://api.github.com/repos/chridou/http-api-problem (stars 62, archived false, pushed 2025-01-06T18:16:29Z, 2026-09-25)
- Open issues: GET https://api.github.com/search/issues?q=repo:chridou/http-api-problem+is:issue+is:open (total_count 3, 2026-09-25); open-issue list: #56 (2025-03-18, 0 comments), #51 (2024-07-06, 1 comment), #46 (2023-04-23, 0 comments) — responsiveness: 2 of 3 unanswered, low-traffic repo
- Advisories: https://rustsec.org/packages/http-api-problem.html (HTTP 404 = no advisory filed, 2026-09-25)
- Reverse deps: GET https://crates.io/api/v1/crates/http-api-problem/reverse_dependencies (meta.total 8, 2026-09-25; parent names unresolved — gap)
- Runner-up meta: GET https://crates.io/api/v1/crates/problemdetails (downloads 48464, recent 9684, 2026-09-25); versions (0.7.0, 2026-04-23T10:59:26.949163Z, MIT, rust 1.85.1); GET https://api.github.com/repos/sazzer/problemdetails (stars 10, archived false, pushed 2026-04-23T10:59:30Z); open issues total_count 3; https://rustsec.org/packages/problemdetails.html (404 = no advisory filed)
- axum context: GET https://crates.io/api/v1/crates/axum (downloads 485420454, recent 120343002; 0.8.9, rust 1.80, MIT, 2026-09-25); GET https://api.github.com/repos/tokio-rs/axum/contents/examples (error-handling, customize-extractor-error, global-404-handler present, 2026-09-25)

#### status-mapping

##### Landscape

Mapping-mechanism bin: no established crate owns "domain-error-to-status table" as a standalone component — the field is (a) hand-rolled exhaustive `match` in `IntoResponse`, (b) per-variant trait method `fn status_code(&self) -> StatusCode`, (c) `http-api-problem-derive` macro. Crate figures are inapplicable to this member (it is a template-owned pattern module, not a dependency); the reason is recorded here per the tier guidance rather than omitted. Authority: axum's `error-handling` example (thiserror/anyhow + `IntoResponse`), Rust exhaustiveness checking (compiler-enforced totality), py ERROR_STATUS dict as the precedent being ported.

##### Principles and implementation

Carries the F306 half: one total mapping from domain error to HTTP status, the Rust analogue of py `ERROR_STATUS: dict[type[PyError], int]`, designed generic over R67's undecided taxonomy: a small trait (e.g. `fn status_code(&self) -> StatusCode`) implemented for whatever error type R67 defines, with the body an exhaustive `match` over variants (no wildcard arm), invoked from the single `IntoResponse` impl that builds the envelope. HIGH-Q2 verdict: trait method as the seam + `match` as the table. The derive macro is rejected (see Tradeoffs). MEDIUM-Q4 verdict: yes — generic today (`impl HttpStatus for R67Error` once R67 resolves), no redesign. MEDIUM validation-hook verdict: yes — extractor/validation rejections must be intercepted (axum: custom rejection mapper for `Json`/`Query`/`Path` rejections; other frameworks: their documented rejection/middleware hook) and routed into the same constructor; 404/405 via fallback/catch-all.

##### Dominant choice

Hand-rolled `HttpStatus` trait + exhaustive `match`, template-owned in `web::problems`. No version, no downloads, no repo: inapplicable (pattern member). Practice backing: the axum `error-handling` example's `AppError`/`IntoResponse` shape (tokio-rs/axum, 2026-09-25) and the `thiserror` ecosystem convention (thiserror 2.0.21, 2026-09-23, rust 1.77, 1,509,629,457 all-time downloads) of enum errors with per-variant behavior.

##### Qualified shortlist

Per-variant inherent `status_code()` methods without a shared trait — workable for one enum but untestable generically and harder to wire to R67's type; kept as fallback if the R67 shape resists a trait impl (e.g. foreign type needing newtype).

##### Excluded by gate

`http-api-problem-derive`: not gate-failed, but excluded by fit — macro-generated mapping hides the table from readers and couples the template to a companion macro's release line for what is a ~15-line match. Runtime `HashMap<TypeId, StatusCode>` (literal ERROR_STATUS port): excluded by fit — discards exhaustiveness checking, the strictest available realization of the totality principle.

##### Up-and-comers

None: the mechanism space is stable (trait + match); watch R67's taxonomy shape, not new crates.

##### Fit for this template

Total fit: zero new dependencies (uses `http::StatusCode` already in the tree via the web framework), compiles against any R67 enum via one trait impl, exhaustive `match` turns "forgotten variant" into a compile error (stronger than py's dict), identical shape under any R69 framework (only the hook registration differs). License/MSRV/OS gates: inapplicable — first-party template code under the template's own `MIT OR Apache-2.0`, edition 2024, stable Rust. Async coupling: none. Binary/compile cost: nil.

##### Recommendation

Implement `HttpStatus` trait + exhaustive `match` in the web crate; wire `impl HttpStatus for <R67 type>` once R67 resolves.

##### Ranked runner-up

Per-variant inherent methods (no trait) if R67's type cannot take the trait impl directly.

##### Tradeoffs

Explicitness (every variant visible in one match) vs brevity (derive). Chosen: explicitness — the mapping table is a reviewed contract surface, and the compiler enforces totality for free.

##### Parameters

Member-level: assumes error-taxonomy-exit-codes = (R67 undecided; assumed as any error type the template can implement the status trait for). No CONFLICT.

##### Migration implications

New file `web::problems` (trait + `IntoResponse` impl + fallback + rejection mapper + constructor); no `Cargo.toml` addition beyond the envelope member; one `impl` block added when R67 resolves.

##### Validation strategy

Planned (not executed): `cargo test -p <web-crate> problems::` covering every domain variant's status, 404 fallback shape, and invalid-body 422 shape; `cargo clippy -- -D warnings` to forbid wildcard arms drifting in; compile-fail coverage by exhaustiveness (add-variant-without-arm breaks the build). Expected: all variants mapped, all non-2xx share the envelope.

##### Confidence & re-verify trigger

High on mechanism, medium on R67 wiring (taxonomy unseen). Re-verify when R67 resolves: confirm the trait impl fits the concrete enum without a newtype or redesign.

##### Sources

- axum examples index: GET https://api.github.com/repos/tokio-rs/axum/contents/examples (anyhow-error-response, customize-extractor-error, error-handling, global-404-handler present, 2026-09-25)
- thiserror context: GET https://crates.io/api/v1/crates/thiserror (downloads 1509629457, recent 376544738; 2.0.21 created 2026-09-23T20:24:07.771104Z, rust 1.77, 2026-09-25)
- py precedent: py `src/py_launch_blueprint/web/problems.py:52,57` (prompt-cited, not re-fetched)
- No standalone mapping-table crate found (negative result, one landscape pass, 2026-09-25)

### Compatibility

Members compose by construction: the status-mapping member calls the envelope member's constructor (`HttpApiProblem` build + `IntoResponse`) from every path (domain errors, fallback 404/405, validation rejections). Shared-adopter proof: both members target the same framework extension point the `http-api-problem` `axum` feature implements (`axum-core ^0.5`, compatible with axum 0.8.9 per version bounds, checked 2026-09-25). Version matrix: `http-api-problem 0.60.0` + `axum-core ^0.5` (via its `axum` feature) + template-owned `web::problems` (no version). No shared-example repository exists for the exact pairing (gap); the planned example in Validation strategy closes it at synthesis/acceptance time.

### Parameters

assumes error-taxonomy-exit-codes = (R67 undecided; design is generic over any error type implementing the status-mapping trait)
assumes web-framework-stack = (R69 undecided; envelope works with any supported framework via optional features)
assumes rust-edition = 2024
assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
assumes license = MIT OR Apache-2.0
assumes target-os-matrix = ubuntu-latest, macos-latest

### Migration implications

- `Cargo.toml` (web crate): add `http-api-problem 0.60.0` with `default-features = false` + R69 winner's feature.
- New `web::problems` module: `HttpStatus` trait, exhaustive `status_code()` match, `into_problem()` constructor, `IntoResponse` impl, 404/405 fallback, extractor-rejection mapper.
- Routes: return `Result<_, AppError>`; register fallback + rejection mapping at router build.
- R71 input: envelope field list (`type`, `title`, `status`, `detail`, `instance`) handed to the OpenAPI sync step (sync itself owned by R71).
- R67 wiring: one `impl HttpStatus for <R67 error type>` block once R67 resolves.

### Validation strategy

Planned commands (none executed in this pass):

- `cargo build -p <web-crate> --locked` on ubuntu-latest and macos-latest — expected: clean build, proving gate 4 and the axum-core bound.
- `cargo tree -p http-api-problem -e normal --features <r69-feature>` — expected: http/serde/serde_json + one framework glue only.
- `cargo test -p <web-crate> problems` — expected: 404, 422-invalid-body, and each domain variant return `Content-Type: application/problem+json` with correct `status`/`title`; unknown route never returns a bare framework body.
- Negative check: temporarily add an unmapped domain variant — expected: compile error from the non-exhaustive match, proving totality.
- `cargo deny check advisories bans licenses` (or `cargo audit`) — expected: no advisory, licenses within MIT OR Apache-2.0.

### Confidence & re-verify trigger

Overall: medium-high. Envelope-crate choice is evidence-backed (adoption + framework breadth + quiet-stable maintenance); mapping mechanism is high-confidence (idiomatic, compiler-enforced); R67/R69 wiring is assumed-generic and must be confirmed at integration. Re-verify on: R67 taxonomy resolution, R69 framework choice, any `http-api-problem` major release or advisory, or 2027-03-25.

### Sources

All live figures retrieved 2026-09-25 via the endpoints in the member Sources fields above (crates.io API, GitHub API, rustsec.org, rfc-editor.org). Recorded gaps: (1) reverse-dependency parent names unresolved (one attempt); (2) `http-api-problem` repo CI badge / platform list not inspected; (3) full dependency-tree `unsafe`/MSRV audit not run — covered by planned checks; (4) no published "one envelope" template write-up found (LOW question answered as negative result); (5) no executed commands in this pass — all checks are planned and distinguished as such.
