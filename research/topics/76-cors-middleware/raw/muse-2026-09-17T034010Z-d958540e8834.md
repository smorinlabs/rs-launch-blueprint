# Raw research answer — R76 CORS middleware (crate, engine muse)

Engine: muse (Meta). Retrieval date for all live figures: 2026-09-25.

### Landscape

Category decided: the Rust CORS middleware crate for the template's web service, plus the trigger that installs it only when an origin allowlist is configured (py parity: empty allowlist = no CORS middleware at all).

Three-bin map of the Rust field:

- Built-in / first-party toolchain: no std or first-party CORS type exists. The closest first-party surface is each framework's own middleware extension point: axum (tokio-rs) `Router::layer` over tower `Layer`/`Service` (documented in the tokio-rs/axum `examples/cors` directory, present 2026-09-25); actix-web `App::wrap` middleware; Rocket fairings. Hand-rolling CORS headers on these points is possible but re-implements preflight/`Vary`/credentials semantics maintained upstream.
- Established industry standard: `tower-http` v0.7.1 `cors` module (`CorsLayer`, `AllowOrigin`) — the tower ecosystem's shared middleware set, used via axum's documented `examples/cors`; `actix-cors` v0.7.2 (`Cors` builder) — the actix organization's first-party CORS middleware in actix/actix-extras; `rocket_cors` v0.6.0 — the long-standing Rocket CORS fairing (lawliet89/rocket_cors).
- Up-and-comer: no credible CORS-specific up-and-comer found. The adjacent `rama` proxy framework ships its own CORS layer (mentioned by a contributor in tower-http#740, 2026-09-22), but it is a full proxy framework, not an adoptable CORS crate for this template. No candidate was shortlisted from familiarity alone; all three shortlisted crates come from the framework-ecosystem map above.

Authoritative sources and why each counts: crates.io API (maintainers' published metadata: downloads, versions, licenses, rust-version, dependency rows); docs.rs (rendered maintainer documentation, feature flags, dependency lists); GitHub API (stars/archived/pushed_at, search-issues open counts); the frameworks' own repositories (tokio-rs/axum `examples/cors` — the leading async framework's own documented CORS pattern; actix/actix-extras and lawliet89/rocket_cors sources for default semantics); rustsec.org package pages (advisory record); static.rust-lang.org stable channel manifest (MSRV floor math). A single blog post was used for no claim in this answer.

Practice evidence: axum's own `examples/cors` (tokio-rs/axum, the tokio team's flagship framework) demonstrates `tower_http::cors::CorsLayer` as the CORS mechanism. `tower-http` records 3,520 direct reverse dependencies (crates.io `reverse_dependencies` meta.total, 2026-09-25); `actix-cors` records 213. Adoption-breadth evidence (476M vs 21M all-time downloads) corroborates tower-http as the dominant CORS vehicle in current Rust practice. Well-regarded standing: tower-http is maintained under the tower-rs organization (the tower middleware ecosystem behind axum/hyper/tonic); actix-cors under the actix organization (actix-web's own org).

Fit over abstract best: the template needs py parity (py `web/app.py:136` `if settings.cors_origins:` — opt-in install, default off) inside a CLI + library + web-service template with R69's framework choice still open, R75's ordering contract still open, and R77's settings shape still open. Candidates are judged on runtime-configured allowlists, conditional installability, and framework-agnostic fit — not standalone popularity.

### Principles and implementation

Shared requirement (from py precedent, spec section 2, F322, verdict DIVERGENT): cross-origin HTTP access is opt-in via an explicit origin allowlist supplied by configuration; the default (empty allowlist) installs no CORS middleware at all, so the default service exposes no cross-origin surface. Source: py `src/py_launch_blueprint/web/app.py:136` (`if settings.cors_origins:`). ts has no web service (`docs/port/areas/web-service.md:100`), so there is nothing to reconcile with ts. Agreement level: capability + policy for the web crate — the capability (allowlist-gated cross-origin access) and the policy (default off; install only when the allowlist is non-empty) must agree; the concrete crate, builder names, and preflight defaults may vary per ecosystem. No BASELINE-REVIEW finding: the py precedent is retained, not challenged. No ledger change is proposed.

Essential behaviors: (1) the allowlist is supplied at runtime from configuration (not baked in at compile time); (2) an empty allowlist means the CORS layer is never constructed or registered — not merely configured to deny; (3) a non-empty allowlist installs exactly one CORS layer reflecting exactly those origins; (4) per-request behavior follows the Fetch standard (preflight handling, `Vary: Origin`, credentials rules) as implemented by the chosen crate.

Observable acceptance criteria: with an empty allowlist, responses to cross-origin requests and OPTIONS preflights carry no `Access-Control-Allow-Origin` header and no CORS `Vary` emitted by a CORS layer; with `["https://example.com"]` configured, a matching `Origin` request receives `Access-Control-Allow-Origin: https://example.com` and a preflight receives the allow headers, while a non-listed origin does not.

Architectural alternatives compared: (A) conditional layer-registration branch in the composition root (recommended) — `if !allowlist.is_empty() { stack = stack.with(cors_layer(allowlist)) }`, mirroring py's `if settings.cors_origins:` exactly; (B) optional-layer wrapper (always register a layer that internally no-ops when empty) — rejected: it keeps CORS code (and its `Vary`/preflight interception surface) on the default path, violating the "install-free default" policy; (C) hand-rolled CORS headers at the framework extension point — rejected: re-implements maintained preflight semantics with no compensating benefit. Libraries were evaluated after the pattern choice: `tower-http/cors` vs `actix-cors` vs `rocket_cors`, all three of which accept runtime-configured origin lists (`AllowOrigin::list`, `allowed_origin(&str)`/`allowed_origin_fn`, `AllowedOrigins::some_exact`), so no candidate forces a compile-time allowlist.

How the design preserves each principle: the conditional branch is the policy enforcement point (identical shape in py, rs-axum, and rs-actix), while the crate owns Fetch-standard mechanics. Ecosystem differences are confined to the mechanic layer: tower's immutable `Router::layer` reassignment vs actix's `App::wrap` vs py's `add_middleware` — three spellings of the same "register only when non-empty" pattern. No shared low-level value (crate name, builder API) is recommended across ecosystems: the crates differ because the frameworks differ, and the principle lives at capability + policy level. ts follow-on: if ts ever gains a web service, its Hono `cors()` registration should follow the same branch shape; this answer supplies that rationale without changing ts.

Maturity/dependability/performance/integration cost: `tower-http` 0.7.1 is active (released 2026-08-31, repo pushed 2026-09-19, 476M all-time downloads, `cors` feature adds zero extra dependencies); `actix-cors` 0.7.2 is active (released 2026-08-24, monorepo pushed 2026-09-25). CORS evaluation is a per-request header comparison — negligible cost in all candidates; no hot-path benchmark is warranted (workload = header checks on HTTP requests, not throughput-sensitive). Integration cost: one `if` branch plus one builder call in the composition root.

Minimal realistic example: a web-service composition root reading `cors_origins: Vec<String>` (value supplied by R77's settings shape), branching on `is_empty`, and building `CorsLayer::new().allow_origin(AllowOrigin::list(parsed))` (or `Cors::default()` + `allowed_origin` per entry under actix-web) only on the non-empty path. Executable acceptance check: integration tests asserting (a) no `Access-Control-Allow-Origin` on any response with an empty allowlist, (b) exact-origin reflection with a one-entry allowlist, (c) no reflection for a non-listed origin. Proposed, not executed (no commands run in this research pass).

### Dominant choice

`tower-http` v0.7.1, `cors` feature only (`default-features = false, features = ["cors"]`). Figures (crates.io API + GitHub API, 2026-09-25): all-time downloads 476,178,922; 90-day downloads 154,784,730; stars 918 (tower-rs/tower-http); archived false; pushed_at 2026-09-19T15:23:28Z; open issues 32 (search-issues total_count, never open_issues_count); last release 0.7.1 created 2026-08-31T14:49:25.697237Z, license MIT, rust-version 1.65. Maintenance state: active — fresh release, recent pushes, no open advisory affecting the recommended version. `unsafe` posture: `tower-http/src/cors/mod.rs` contains zero `unsafe` occurrences (source fetched 2026-09-25); full dependency-tree audit not run (gap, recorded not filled). Issue responsiveness: of the 6 non-PR issues in the 10 most recently created items, 4 have zero comments and 2 carry only reporter follow-ups (#740 created 2026-09-22, 3 reporter comments, no maintainer reply; #737 created 2026-09-16, 2 reporter comments, no maintainer reply) — no maintainer first-response observed in this window, so no median is computable; low signal either way on a high-volume middleware repo.

### Qualified shortlist

Up to five that passed every gate (two qualify; fewer is a finding):

- `tower-http` v0.7.1 · CORS layer for tower/axum stacks · 90-day 154,784,730 · all-time 476,178,922 · stars 918 · last release 2026-08-31 · active · notable adopters: axum's own documented `examples/cors` (tokio-rs/axum, the leading async framework's own reference) + 3,520 reverse dependencies · trade-off: the pick for any tower-based stack; unusable if R69 picks a non-tower framework.
- `actix-cors` v0.7.2 · CORS middleware for actix-web · 90-day 2,903,913 · all-time 21,237,320 · stars 890 (actix/actix-extras monorepo — figure covers the whole repo, not this crate alone) · last release 2026-08-24 · active · notable adopters: 213 reverse dependencies; first-party crate of the actix-web ecosystem · trade-off: required if R69 picks actix-web; actix-only, so narrower than tower-http.

### Excluded by gate

None of the shortlisted crates fails a fitness gate. `rocket_cors` is not gate-excluded but is not shortlisted: it passes gates 1–3/6 on paper yet loses on maintenance state (at-risk — no commit since 2023-11-20, issue #118 opened 2024-11-16 with zero comments, release 0.6.0 from 2023-11-18) and on fit (Rocket-only fairing; Rocket is not evidenced as a leading-framework candidate in this survey). Recorded here rather than silently dropped. Hand-rolled CORS headers excluded by design fit (duplicates maintained preflight semantics), not by gate.

### Up-and-comers

None qualified. The `rama` framework's own CORS layer (surfaced via a contributor comment in tower-http#740, 2026-09-22) is framework-internal, not an adoptable crate, and was not evaluated as a candidate. No standalone CORS-crate newcomer was found in this survey; the Rust CORS-crate field is consolidated around the three framework-paired incumbents.

### Fit for this template

CLI: inapplicable — no HTTP surface; no CORS dependency in the CLI crate. Library: inapplicable — CORS is a web-service composition-root concern, not library behavior. Web: direct fit — one optional dependency (`tower-http` with only the `cors` feature, or `actix-cors` if R69 picks actix-web) plus a conditional registration branch gated on the R77-supplied allowlist. Framework-agnostic until R69 resolves: the branch shape ports verbatim (`Router::layer` reassignment under axum/tower, `App::wrap` under actix-web). No conflict with R75's ordering contract (this item does not position the layer) or R77's settings shape (this item consumes "an allowlist value exists").

### Recommendation

Adopt `tower-http` version `0.7` with `default-features = false, features = ["cors"]`, installed behind a conditional registration branch in the web-service composition root: build and register the `CorsLayer` only when the configured origin allowlist is non-empty; the default (empty allowlist) registers nothing. Origin list construction is runtime (`AllowOrigin::list` over parsed `HeaderValue`s). This recommendation assumes R69 resolves to a tower-based framework (axum); if R69 picks actix-web, substitute `actix-cors` `0.7` with the same branch shape (see Ranked runner-up). Either branch satisfies py parity (`if settings.cors_origins:`) and the default-off policy.

### Ranked runner-up

`actix-cors` v0.7.2 (`version = "0.7"`). It wins if and only if R69 (`web-framework-stack`) selects actix-web, whose middleware model (`App::wrap`) cannot consume a tower `Layer`. Under that condition the same conditional branch applies: `if !allowlist.is_empty() { app = app.wrap(cors) }` with `Cors::default()` (restrictive defaults: no allowed origins, methods, or headers per `impl Default for Cors` in `actix-cors/src/builder.rs`) plus one `allowed_origin(&str)` call per entry — runtime-configured, no compile-time allowlist.

### Tradeoffs

What the pick gives up versus `actix-cors`: framework portability outside the tower ecosystem — accepted because the leading-framework evidence (axum's documented `examples/cors`, 476M vs 21M downloads, 3,520 vs 213 reverse dependencies) favors a tower-based stack, and the runner-up condition covers the actix-web outcome explicitly. What the pick gives up versus `rocket_cors`: nothing material — rocket_cors is Rocket-only, an order of magnitude less adopted (1,131,457 all-time downloads), and at-risk on maintenance; its only advantage (a Rocket-native fairing API) matters only if R69 picked Rocket, for which this survey found no leading-framework evidence. What the conditional-branch pattern gives up versus an always-installed layer: one `if` in the composition root and (under axum) a reassigned `Router` binding — accepted because always-installed violates the recorded default-off policy even when configured to deny (the layer still intercepts preflights and emits `Vary`).

### Parameters

- assumes web-framework-stack = (R69 undecided; recommendation valid for a tower-based winner, runner-up condition covers actix-web)
- assumes cors-allowlist-value = (exists via R77 web-env-settings; shape owned by R77, not this item)
- assumes middleware-ordering = (position owned by R75 http-middleware-stack; this item takes no position)
- No CONFLICT lines. No owned parameters (this item owns none per `## Couplings`).

### Migration implications

Template file-level changes (web crate only): add `tower-http = { version = "0.7", default-features = false, features = ["cors"] }` to the web crate's `Cargo.toml` (substitute `actix-cors = "0.7"` if R69 picks actix-web); in the composition root, add the conditional branch (`if !settings.cors_origins.is_empty()`) constructing the layer from the allowlist and registering it on the router/app builder; add integration tests for the three observable acceptances (no CORS headers when empty; exact reflection when configured; no reflection for non-listed origins). No CLI or library crate changes. No new config key is defined here — the allowlist value is R77's to shape.

### Validation strategy

Planned (not executed — no commands run in this research pass): (1) `cargo tree -p tower-http -e normal --no-default-features --features cors` asserting the minimal tree (bitflags, bytes, http, percent-encoding, pin-project-lite, tower-layer, tower-service per the 0.7.1 dependency rows; `cors = []` adds no optional deps); (2) `cargo build` of the web example on ubuntu-latest + macos-latest (gate 4); (3) `cargo deny`/audit run for advisories (expected: the two historical tower-http advisories RUSTSEC-2022-0043/RUSTSEC-2021-0135 show patched `>=0.2.1`, so 0.7.1 is unaffected); (4) example integration tests asserting the observable acceptance criteria above — expected: no `Access-Control-Allow-Origin` with empty allowlist, exact-origin reflection with a one-entry allowlist, denial for non-listed origins. MSRV check: crate rust-version 1.65 is below the 1.96 floor (stable 1.98.1 per the 2026-09-03 channel manifest minus 2), so the floor holds trivially for this dependency.

### Confidence & re-verify trigger

Medium-high. The dominant choice is strongly evidenced (leading-framework reference, 476M downloads, active maintenance, zero-dep `cors` feature, runtime allowlist, default-deny `AllowOrigin`); the residual uncertainty is R69's framework decision, handled by an explicit runner-up condition rather than a guess. Re-verify if: R69 picks a non-tower framework (adopt the runner-up); tower-http ships a 0.8/1.0 changing the `cors` API; an advisory is filed against tower-http ≥0.7; or 2027-03-25 passes without a release (active-state review).

### Sources

- Crate meta: GET https://crates.io/api/v1/crates/tower-http (downloads 476178922, recent_downloads 154784730, 2026-09-25)
- Versions: GET https://crates.io/api/v1/crates/tower-http/versions (0.7.1, 2026-08-31T14:49:25.697237Z, license MIT, rust_version 1.65, 2026-09-25)
- Deps: GET https://crates.io/api/v1/crates/tower-http/0.7.1/dependencies (7 normal required: bitflags/bytes/http/percent-encoding/pin-project-lite/tower-layer/tower-service; 16 optional; 2026-09-25)
- Repo: GET https://api.github.com/repos/tower-rs/tower-http (stars 918, archived false, pushed 2026-09-19T15:23:28Z, 2026-09-25)
- Open issues: GET https://api.github.com/search/issues?q=repo:tower-rs/tower-http+is:issue+is:open (total_count 32, 2026-09-25); recent window: #741 (2026-09-25, 0 comments), #740 (2026-09-22, 3 reporter-only comments), #737 (2026-09-16, 2 reporter-only comments), #732/#731/#701 (0 comments) — no maintainer first-response observed
- Advisories: https://rustsec.org/packages/tower-http.html (HTTP 200 listing RUSTSEC-2022-0043 + RUSTSEC-2021-0135, both patched >=0.2.1 per advisory pages, ServeDir Windows-path issues — 0.7.1 unaffected, 2026-09-25)
- Reverse deps: GET https://crates.io/api/v1/crates/tower-http/reverse_dependencies (meta.total 3520, 2026-09-25)
- Cargo features: https://raw.githubusercontent.com/tower-rs/tower-http/refs/heads/main/tower-http/Cargo.toml (default = [], cors = [], rust-version 1.65, 2026-09-25)
- CORS source: https://raw.githubusercontent.com/tower-rs/tower-http/refs/heads/main/tower-http/src/cors/mod.rs (0 unsafe occurrences; CorsLayer::new/permissive/very_permissive; allow_origin/allow_methods/allow_headers/allow_credentials/max_age/vary/expose_headers; 2026-09-25) and .../src/cors/allow_origin.rs (Default = empty List, i.e. default-deny, 2026-09-25)
- CI: https://api.github.com/repos/tower-rs/tower-http/contents/.github/workflows (CI.yml present) + CI.yml test-os matrix [macos-latest, windows-latest] with default ubuntu-latest job (2026-09-25)
- axum reference: GET https://api.github.com/repos/tokio-rs/axum/contents/examples (cors example present, 2026-09-25)
- Runner-up meta: GET https://crates.io/api/v1/crates/actix-cors (downloads 21237320, recent 2903913, 2026-09-25); versions (0.7.2, 2026-08-24T14:19:03.269184Z, MIT OR Apache-2.0, rust 1.88); GET https://api.github.com/repos/actix/actix-extras (stars 890, archived false, pushed 2026-09-25T15:03:32Z); open issues total_count 15 (whole monorepo); https://rustsec.org/packages/actix-cors.html (HTTP 404 = no advisory filed, 2026-09-25); reverse_dependencies meta.total 213; CI covers ubuntu-latest/macos-latest/windows-latest; builder source .../actix-cors/src/builder.rs (Default = restrictive, no allowed origins; allowed_origin(&str) runtime; permissive() explicit)
- Non-shortlisted: GET https://crates.io/api/v1/crates/rocket_cors (downloads 1131457, recent 80245, 2026-09-25); versions (0.6.0, 2023-11-18T08:11:42.572441Z, MIT/Apache-2.0, rust 1.69); GET https://api.github.com/repos/lawliet89/rocket_cors (stars 104, archived false, pushed 2023-11-20T00:42:55Z); open issues total_count 7 incl. #118 (2024-11-16, 0 comments); https://rustsec.org/packages/rocket_cors.html (404 = no advisory filed)
- Toolchain: https://static.rust-lang.org/dist/channel-rust-stable.toml (rustc 1.98.1, date 2026-09-03; MSRV floor 1.96, 2026-09-25)
- Gaps recorded, not filled: full dependency-tree unsafe/MSRV audit not run; LOW-question survey found no published Rust template naming conditional allowlist-gated CORS installation as a pattern (axum's cors example demonstrates the layer, not the conditional branch); docs.rs Cors struct prose fetch returned page chrome only, so actix-cors default semantics were verified from builder source instead.
