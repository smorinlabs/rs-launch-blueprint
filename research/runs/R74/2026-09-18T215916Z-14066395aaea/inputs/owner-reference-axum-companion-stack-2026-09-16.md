# Owner-supplied reference: "The Axum Companion Stack — Reference Architecture (September 2026)"

Provenance: supplied verbatim by the owner on 2026-09-16 during the Wave 0 review
walk, with the instruction to fold it into R69 (`web-framework-stack`) and the
items that build on it. It is an owner-supplied research input, not a binding
standard and not a decision: each research item that overlaps it must either
agree with it on the record or say why it differs, citing this file by section.
Owner-fixed parameters in `docs/port/PARAMETERS.md` (edition 2024, `msrv-policy`
stable minus 2, `target-os-matrix`) override any value stated below. The
document's own caveat applies: its code patterns were "compiled in my head, not
against the toolchain", and every version it flags "verify" is unpinned.

Overlap map (controller, 2026-09-16): R69 — framework, runtime, feature shape,
dev loop (C14 `bacon`), graceful shutdown, test idiom (C12), layout (C13);
R70 — error contract (C4); R71 — OpenAPI (C3); R72–R76 — middleware, rate
limiting, security headers (C11); R77 — config and secrets (C9); R78/R79 —
observability (C10); R80 — probes (C15); R32 — testing (C12); R05 — async model;
R58 — logging (C10); R51/R68 — container and release (C15). Rows with no P02
item (templating, static assets, database, sessions/auth, WebSockets, background
jobs, Cloud Run deployment) are recorded here for a later scoping decision.

The document follows, byte-verbatim as supplied.

---

# The Axum Companion Stack — Reference Architecture (September 2026)

*All versions and metrics are as of September 16, 2026. Compatibility was verified against each crate's `Cargo.toml`/changelog on crates.io/docs.rs/GitHub, not inferred from READMEs. Figures I could not pin to an exact patch are flagged "verify."*

## TL;DR
- **Shared core:** axum 0.8.9 + axum-extra 0.12.6 on tokio 1 / hyper 1 / tower 0.5 / tower-http 0.6 / http 1; sqlx 0.8.6 (Postgres/rustls, offline) for data + migrations; tower-sessions 0.15 (Postgres store) + axum-login 0.18 + argon2 for auth; utoipa 5 + utoipa-axum 0.2 for OpenAPI; garde + axum-valid 0.24 for validation; apalis-postgres 1.0 *or* Cloud Tasks for jobs; figment + Secret Manager for config; tracing JSON logs; tower_governor 0.8; axum-test 18 + `#[sqlx::test]` for tests; shipped as a cargo-chef → distroless/cc-debian12 image on Cloud Run.
- **Heads:** Variant A (HTMX) adds askama 0.15 + axum-htmx 0.8.1 + axum_csrf 0.11 with a no-Node Tailwind build; Variant B (SPA) adds a Vite/TypeScript frontend consuming an `openapi-typescript` + `openapi-fetch` generated client, served via `ServeDir` + SPA fallback.
- **Recommendation:** For a TS-strong team building with coding agents, **default to Variant B** (best end-to-end typing, richest agent training data). **Variant A wins** for content/form-heavy, SEO-sensitive, low-real-time apps wanting one small artifact and minimal JS. A hybrid is worth it only past a clear complexity threshold.

## Key Findings
1. **Axum 0.8.9 is the current, stable line and there is no 0.9/1.0 to worry about yet.** The tokio-rs maintainers stated "There isn't a timeline yet" for 0.9.x; the highest tag is `axum-v0.8.9`. Pending 0.9 breaking changes are concentrated in **axum-extra** (feature-gating utilities like `Cached`/`WithRejection`, an `option_layer` body-type change, prost 0.14). This makes a 3-year horizon on 0.8 safe.
2. **The Askama/Rinja fork has fully merged back into `askama` (0.15.x is canonical).** The rinja fork was re-unified; **the framework integration crates (`askama_axum`, `rinja_axum`) were removed** — you now call `template.render()?` and wrap in `axum::response::Html`. This is the single most common thing agents get wrong.
3. **Cloud SQL from Rust on Cloud Run is a solved, first-party path: the injected Unix socket at `/cloudsql/INSTANCE_CONNECTION_NAME`.** No sidecar or immature connector crate needed; sqlx connects to it directly. (Note: the socket path length limit is 108 chars, and Postgres needs the `.s.PGSQL.5432` suffix that libpq-style drivers add automatically.)
4. **WebSockets on Cloud Run are supported but constrained by three hard facts:** WS streams are long HTTP requests subject to the request timeout (default 5 min, max 60 min); session affinity is best-effort only; and reconnects may hit a different instance. Cross-instance state **must** be synchronized (Redis Pub/Sub via Memorystore recommended).
5. **End-to-end typing is where Variant B decisively beats A.** utoipa 5 + utoipa-axum 0.2 emit a correct OpenAPI spec from your serde types and extractors; `openapi-typescript` (fastest, ~1.5s on a 1,200-operation spec vs ~8s for hey-api) + `openapi-fetch` (~6 kB, near-zero runtime) give a tRPC-like typed client with drift caught in CI.
6. **In-process background workers fight Cloud Run's scale-to-zero.** apalis workers stop when an instance is scaled to zero or SIGTERMed mid-job; the robust patterns are Cloud Tasks/Scheduler/Pub-Sub push to an HTTP endpoint (fire-and-forget, cron) and Cloud Run Jobs (long batch), reserving apalis-postgres for when you already keep `min-instances=1` with CPU always allocated.

## The Stack Table

| # | Component | Variant | Pick | Version | Runner-up | Why not the rejected |
|---|-----------|---------|------|---------|-----------|----------------------|
| C1 | Templating | A (B: shell only) | **askama** | 0.15.x | Maud 0.26; MiniJinja 2 | Maud macro syntax less agent-friendly; MiniJinja/Tera runtime (no compile-time check); Leptos/Dioxus SSR = adopting a framework |
| C2 | Static/frontend | A | **ServeDir + rust-embed** | rust-embed 8 | include_dir | include_dir less ergonomic for fingerprinting |
| C2 | Static/frontend | B | **Vite + ServeDir fallback** | Vite 6 | CDN/bucket split | separate bucket adds CORS/cookie friction |
| C3 | OpenAPI | shared (critical B) | **utoipa + utoipa-axum** | 5.x / 0.2.0 | aide | aide less annotation-ergonomic with extractors |
| C3 | TS client | B | **openapi-typescript + openapi-fetch** | 7.x / 0.13.x | @hey-api/openapi-ts | hey-api heavier, pre-1.0 API churn |
| C3 | Direct type export | B (internal) | **ts-rs** (optional) | 10.x | specta | specta core pre-1.0, churny outside Tauri |
| C4 | Validation | shared | **garde + axum-valid** | 0.x / 0.24.0 | validator + axum-valid | validator uses `lazy_static` regex, more boilerplate |
| C4 | Error contract | shared | **thiserror + custom AppError (RFC 9457)** | thiserror 2 | Problem-Details crates | most such crates unmaintained; hand-roll |
| C5 | DB access | shared | **sqlx** | 0.8.6 | SeaORM 1 | SeaORM heavier; diesel-async smaller ecosystem |
| C5 | Migrations | shared | **sqlx-cli / sqlx::migrate!** | 0.8.6 | refinery | refinery redundant with sqlx |
| C5 | Cloud SQL conn | shared | **Unix socket `/cloudsql/...`** | — | Auth Proxy sidecar | sidecar adds ops; Rust connector immature |
| C6 | Sessions | shared | **tower-sessions + Postgres store** | 0.15.0 | axum_session | axum_session is a parallel/redundant ecosystem |
| C6 | Auth | shared | **axum-login** | 0.18.0 | hand-rolled | hand-rolled loses tested middleware |
| C6 | Password hash | shared | **argon2 + password-hash** | argon2 0.5.x | bcrypt | Argon2id is OWASP's top recommendation; bcrypt is a legacy fallback |
| C6 | CSRF | A | **axum_csrf** | 0.11.0 | double-submit hand-roll | sync-pattern crate stuck on axum 0.6 |
| C6 | OIDC/OAuth | shared | **oauth2 + openidconnect** | 5.x / 4.x | axum-oidc | axum-oidc thinner wrapper, fewer knobs |
| C6 | JWT (API) | shared | **jsonwebtoken** | 9.x | jwt-simple | jwt-simple smaller community |
| C7 | WS fan-out | shared | **axum ws + Redis Pub/Sub (Memorystore)** | — | Postgres LISTEN/NOTIFY | NOTIFY cheaper but higher latency at scale |
| C8 | Background jobs | shared | **apalis-postgres** OR **Cloud Tasks push** | 1.0.x | underway; sqlxmq | underway newer/smaller; sqlxmq less active |
| C9 | Config | shared | **figment** | 0.10.x | config-rs | config-rs less ergonomic layering |
| C9 | Secrets | shared | **google-cloud-secretmanager-v1** (or env injection) | official 0.x | google-secretmanager1 | community crate uses yup-oauth2, less idiomatic |
| C10 | Logs/traces | shared | **tracing + tracing-subscriber (JSON)** (+ tracing-stackdriver) | 0.1 / 0.3 | tracing-gcp | tracing-gcp less maintained |
| C10 | Error reporting | shared | **sentry + sentry-tower** | 0.34+ | Cloud Error Reporting | GCP-native works from logs but less rich |
| C11 | Rate limiting | shared | **tower_governor** | 0.8.0 | axum-governor | axum-governor newer/less proven |
| C11 | Security headers | shared (CSP per variant) | **tower-http `SetResponseHeaderLayer` (hand-rolled CSP)** | tower-http 0.6 | helmet-style crates | most helmet crates thin/unmaintained |
| C12 | Testing | shared | **axum-test + `#[sqlx::test]` + wiremock + insta** | axum-test 18 | tower `oneshot` | oneshot lower-level, more boilerplate |
| C13 | Layout | per variant | **feature-vertical modules, single crate → workspace** | — | layered routes/services | pick by team taste |
| C14 | Dev/build | shared | **bacon + cargo-chef + mold** | — | cargo-watch | bacon better UX |
| C15 | Container | shared | **cargo-chef → distroless/cc-debian12** | — | musl/scratch; alpine | musl DNS/TLS quirks; alpine libc perf |

## Details

### Level One — what Axum + tower-http already give you (don't add crates for these)
Routing, extractors, `State`/`FromRef` sub-state, handlers; the full tower-http middleware set (`TraceLayer`, `CompressionLayer`, `CorsLayer`, `TimeoutLayer`, `RequestBodyLimitLayer`, `SetRequestIdLayer`/`PropagateRequestIdLayer`, `NormalizePathLayer`, `CatchPanicLayer`, `SetSensitiveHeadersLayer`); static files (`ServeDir`/`ServeFile`, precompressed brotli/gzip, `Cache-Control`); graceful shutdown (`axum::serve(...).with_graceful_shutdown`); native WebSocket upgrade (`axum::extract::ws`); SSE (`axum::response::sse`). **Dropped as unnecessary:** a dedicated in-process cache crate (use Postgres/Memorystore) and a DI framework (use `FromRef` + traits).

### C1 Templating (Variant A; B uses only a shell/index + auth/error pages)
**askama 0.15** — compile-time type-safe, autoescaped Jinja-like templates. Score (fit 5 / maint 4 / axum-integ 4 / cloudrun 5 / ease 5 (Jinja is familiar to the Python side) / agent 4). The 0.15 line **removed integration crates**: render with `template.render()?` then `Html(...)`. Pair with **axum-htmx 0.8.1** for `HX-*` request extractors/response headers, partial vs full-page switching on `HX-Request`, OOB swaps, and its `auto-vary` middleware. Runner-up **Maud** (fit 4/agent 3) — great ergonomics but macro HTML confuses agents. **MiniJinja/Tera** rejected: runtime templates lose compile-time safety. Hot-reload in dev via `askama` config + `bacon`.

### C2 Static assets & frontend build
**Variant A:** compile CSS with the **Tailwind standalone CLI** (a single binary, no `node_modules`, so the final image needs no Node) in a build stage; serve via `ServeDir` with precompressed assets and long-lived `Cache-Control` on fingerprinted files, or embed with **rust-embed 8** for a single self-contained binary. HTMX + Alpine load as static files — no bundler required. Put Cloud CDN in front only if asset traffic is significant.
**Variant B:** build the SPA with **Vite**; serve `dist/` from Axum with `ServeDir::new("dist").not_found_service(ServeFile::new("dist/index.html"))` so client routes fall back to `index.html`; hashed assets get immutable caching. **Serve the SPA from the same Cloud Run service as the API** — this keeps cookies same-origin (no CORS, no cross-site cookie headaches) and is operationally simplest. Dev-time: Vite dev server proxies `/api` → Axum. Splitting the SPA to a bucket/CDN is only worth it at high static-traffic scale, at the cost of CORS + cookie complexity.

### C3 OpenAPI + end-to-end TypeScript
**utoipa 5 + utoipa-axum 0.2**: annotate handlers with `#[utoipa::path]`, derive `ToSchema`, compose with `OpenApiRouter` + `routes!()` + `.split_for_parts()`; enable `chrono`/`uuid` features for correct date/UUID schemas and `axum_extras` for `IntoParams` ergonomics. Serve docs with utoipa-scalar (or swagger-ui/redoc/rapidoc). **TS path:** `openapi-typescript` (types only, fastest, single-file output) + `openapi-fetch` (6 kB typed fetch wrapper) is the least-ceremony, closest-to-tRPC option and the best fit for a team that owns both spec and client. Use `@hey-api/openapi-ts` only if you later need generated SDK functions/interceptors. **Direct Rust→TS export (ts-rs or specta):** viable for the *internal* SPA and simpler than OpenAPI for pure type sharing, but you lose the served spec third parties need. The two can coexist — **OpenAPI for third parties, and either the same spec or ts-rs for your SPA**. Run generation in CI and `git diff --exit-code` so drift fails the build.

### C4 Validation & error responses
**garde** (a cleaner rewrite of `validator`, no `lazy_static` regex) via **axum-valid 0.24**'s `Garde<Json<T>>` extractor. One `AppError` enum (`thiserror`) implementing `IntoResponse` is the error contract; it does **content negotiation** — RFC 9457 Problem Details JSON (`type`/`title`/`status`/`detail`/`errors`) for API/`Accept: application/json`, and a rendered HTML page for browser/HTMX requests (Variant A). Field-level validation detail surfaces from garde's report into the `errors` map. Most Rust Problem-Details crates are unmaintained — hand-roll the small struct.

### C5 Database, pooling, migrations
**sqlx 0.8.6** with `runtime-tokio-rustls`, `postgres`, `macros`, `migrate`. Compile-time-checked queries work in Docker/CI via **offline mode** (now always available): run `cargo sqlx prepare`, commit `.sqlx/`, build with `SQLX_OFFLINE=true`. Migrations via `sqlx::migrate!()` or `sqlx-cli`; **run them as a separate deploy step, not at every instance startup**, because Cloud Run starts instances concurrently (the migrator takes a lock, which mitigates races but still adds cold-start latency to every instance). **Connect to Cloud SQL via the injected Unix socket** `/cloudsql/PROJECT:REGION:INSTANCE` (`--add-cloudsql-instances` on deploy) — encrypted automatically, no sidecar. **Pool sizing:** with per-instance concurrency of ~80 and up to 10 instances, keep `max_connections` small (5–10) so `instances × pool ≤ Cloud SQL connection limit`. Test with `#[sqlx::test]` (auto per-test database) and/or testcontainers.

### C6 Auth, sessions, CSRF
Sessions: **tower-sessions 0.15** with `tower-sessions-sqlx-store` (Postgres) — **never `MemoryStore`** on Cloud Run (multi-instance + scale-to-zero). Auth: **axum-login 0.18** (`AuthSession` extractor, `login_required`/`permission_required`). Passwords: **argon2** — Argon2id is OWASP's top recommendation per the OWASP Password Storage Cheat Sheet: *"Use Argon2id with a minimum configuration of 19 MiB of memory, an iteration count of 2, and 1 degree of parallelism"*; bcrypt is only a legacy fallback (*"use a work factor of 10 or more and with a password limit of 72 bytes"*). Cookies via `axum-extra` private/signed jars with `SameSite=Lax/Strict`, `Secure`, `HttpOnly`. **CSRF (Variant A): axum_csrf 0.11.0** — it *does* support Axum 0.8 (depends on `axum-core ^0.5`) despite a **stale doc string that still says "Axum 0.7"** and a README example using the removed `axum::Server::bind`. Emit a session-bound token into `<body hx-headers>` so every HTMX request carries it; reject mutating routes without it (403). **Variant B (same-origin SPA): use cookie session + CSRF (double-submit), not bearer tokens** — same-origin cookies are simpler and safer than storing JWTs in JS. OIDC via **openidconnect** + **oauth2** (or the thinner `axum-oidc`). **API clients: `jsonwebtoken` for JWT and an API-key middleware for third parties.** GCP Identity Platform/Firebase Auth is a reasonable buy-vs-build option if you want managed social login and MFA; roll your own only if you need full control. **Pattern for "one app serves cookie-session pages and bearer-token API":** mount page routes behind the session layer + axum-login; mount `/api` with a token/api-key extractor; share one `AppState`.

### C7 WebSockets on Cloud Run
Authenticate the upgrade from the session cookie (A) or a token (B) *before* `on_upgrade`. Per connection, spawn a task that `select!`s over socket recv, a local `tokio::sync::broadcast` receiver, a Redis Pub/Sub subscription, and a shutdown `CancellationToken`. **Cross-instance fan-out is mandatory** because affinity is best-effort — use **Redis Pub/Sub (Memorystore)** (low latency, high throughput) over Postgres `LISTEN/NOTIFY` (cheaper, but higher latency and less throughput) or Cloud Pub/Sub (higher latency, more ops). Send heartbeat pings (~30s) and design a **client reconnect-and-resume** protocol, since Cloud Run caps the connection at the request timeout. Apply backpressure by bounding the per-connection send channel. **Known Axum issue:** WS tasks spawned in `on_upgrade` are *not* joined to graceful shutdown (issue #3003) — track them with a `TaskTracker` + `CancellationToken` and close with a close frame on SIGTERM. Prefer **SSE** when you only need server→client streaming (simpler, no upgrade, works better through proxies).

### C8 Background & scheduled work
Given scale-to-zero and SIGTERM-mid-job, split by workload: **(a) request-triggered fire-and-forget → Cloud Tasks push** to an authenticated HTTP endpoint (survives instance death, ret/backoff built in); **(b) cron → Cloud Scheduler** hitting an endpoint; **(c) long-running batch → Cloud Run Jobs**. Use **apalis-postgres 1.0** only when you want retries/observability co-located in your DB *and* already run `min-instances=1` with **CPU always allocated** (`--no-cpu-throttling`) so workers run between requests. Confirm apalis has a stable `1.0` (historically shipped as `1.0.0-rc.x`) before pinning. Recommendation: Cloud Tasks + Scheduler as the default; apalis as an opt-in when the always-on instance already exists.

### C9 Config & secrets
**figment 0.10** for layered config (defaults → TOML file → env). Secrets: the simplest and most robust path on Cloud Run is **`--set-secrets` env-var injection from Secret Manager** (or mounted volume for larger/rotated secrets). Runtime fetch via the **official `google-cloud-secretmanager-v1` SDK** (Google announced the official Rust SDK GA in Sept 2025, covering 140+ APIs with ADC auth) is warranted only when you need dynamic rotation without redeploy; the SDK is young, so treat env injection as the default.

### C10 Observability on GCP
Emit **JSON logs to stdout** with `tracing-subscriber`'s JSON formatter, mapping levels to Cloud Logging severities (`ERROR→ERROR`, `WARN→WARNING`, etc.) and setting `logging.googleapis.com/trace` from the incoming `X-Cloud-Trace-Context` header so logs nest under requests in Cloud Trace. **tracing-stackdriver** does this shaping (severity, `httpRequest`, `logging.googleapis.com/spanId`) out of the box and can layer with `tracing-opentelemetry`. For traces without a collector sidecar, the pragmatic Cloud Run path is trace-header correlation in logs (no OTLP export needed); add `opentelemetry-otlp` + Cloud Trace export only if you need full spans. Metrics: start with log-based metrics/Cloud Monitoring; add the `metrics` crate + exporter only when needed. Error reporting: **sentry + sentry-tower** for rich capture, or Cloud Error Reporting from structured logs.

### C11 Middleware suite & security headers
Recommended tower-http layer order (outermost→innermost): `SetSensitiveHeadersLayer` → `TraceLayer` → `SetRequestIdLayer`/`PropagateRequestIdLayer` → `CatchPanicLayer` → `CorsLayer` → `NormalizePathLayer` → `TimeoutLayer` → `RequestBodyLimitLayer` → `CompressionLayer` → security headers via `SetResponseHeaderLayer`. Rate limiting: **tower_governor 0.8** (construct one `Arc<GovernorConfig>` and reuse — building per request creates independent limiters). Security headers hand-rolled: HSTS, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, and a **CSP** — for HTMX+Alpine allow `'self'` plus the small inline/eval Alpine needs (or use nonces); for a Vite SPA a stricter `'self'` script/style CSP with hashed assets. Per-route body limits via `RequestBodyLimitLayer` on specific routers. **Cloud Run front-proxy cautions:** don't double-compress; trust `X-Forwarded-*`/`X-Cloud-Trace-Context` only from the proxy; don't enable end-to-end HTTP/2 for WebSockets.

### C12 Testing
**axum-test 18** (`TestServer::new(app)`; requires Axum ≥ 0.8.7) for in-process router tests — higher-level and less boilerplate than `tower::ServiceExt::oneshot`. DB tests with `#[sqlx::test]` (isolated per-test DB) and/or testcontainers. Mock outbound HTTP with **wiremock**. Snapshot HTML/JSON with **insta**. WebSocket tests via axum-test's WS support. CI runs: `cargo fmt --check` → `cargo clippy -D warnings` → `cargo sqlx prepare --check` → `cargo test` → `cargo deny check` (licenses + RustSec) → OpenAPI export + diff → **Variant B**: `npm run gen:api` + `git diff --exit-code` + `tsc --noEmit` + `vite build` + optional Playwright E2E.

### C13 Project structure
Start **single crate, feature-vertical modules** (`web/`, `api/`, `auth/`, `ws/`, `jobs/` each owning their routes/handlers/services), promote to a workspace only when compile times or team boundaries demand it. `AppState` holds `PgPool`, config, and shared clients; use `FromRef` to hand sub-state to extractors. Dependency injection via **traits behind concrete types** (e.g., a `Repo` trait) keeps handlers testable without a DI framework. Keep handler signatures flat and explicit for agent-friendliness. **Reference repos to model on:** for Variant A, the `axum + askama + htmx` task-manager samples (e.g., `Bechma/todo-axum-askama-htmx`, and the Claude-Code-oriented `nullpox7` sample that documents CSRF-in-`hx-headers`, OOB swaps, and a CLAUDE.md); for Variant B, a monorepo with `backend/` (utoipa API) + `frontend/` (Vite + generated client) under a pnpm workspace.

### C14 Developer experience & build
**bacon** (or cargo-watch) for reload; askama hot-reload in dev; **mold/lld** linker for faster link; **cargo-chef** for Docker dependency-layer caching; pin the toolchain with `rust-toolchain.toml`; enable clippy `-D warnings` and useful groups. Add a **CLAUDE.md** with the agent pitfalls below.

### C15 Container & Cloud Run
Recommend **distroless/cc-debian12** over musl/scratch: glibc avoids musl's DNS/TLS edge cases and allocator performance cliffs, and `cc-debian12` is small (single-digit-to-low-tens of MB with a static-ish binary) while retaining libc/TLS certs. Build with cargo-chef (planner → `cargo chef cook` → build), run as `nonroot`, bind `PORT` (default 8080), expose `/healthz` (liveness) and `/readyz` (readiness, checks DB). Variant B prepends a `node:20` Vite build stage.

## Reference `Cargo.toml` (shared core + Variant A)
```toml
[package]
name = "app"
edition = "2021"
rust-version = "1.85"          # pin via rust-toolchain.toml

[dependencies]
# --- Web core (verified 0.8.9-compatible) ---
axum = { version = "0.8.9", features = ["macros", "ws", "http2"] }
axum-extra = { version = "0.12.6", features = ["cookie","cookie-private","typed-header"] }
tokio = { version = "1", features = ["full"] }
tower = "0.5"
tower-http = { version = "0.6", features = ["trace","compression-br","cors","timeout","limit","normalize-path","catch-panic","set-header","fs","request-id","sensitive-headers"] }
hyper = "1"
http = "1"

# --- Serialization / validation ---
serde = { version = "1", features = ["derive"] }
serde_json = "1"
garde = { version = "0.20", features = ["derive"] }          # verify latest 0.x
axum-valid = { version = "0.24.0", features = ["garde"] }

# --- OpenAPI ---
utoipa = { version = "5", features = ["axum_extras","chrono","uuid"] }
utoipa-axum = "0.2.0"
utoipa-scalar = { version = "0.3", features = ["axum"] }     # verify latest

# --- Database ---
sqlx = { version = "0.8.6", features = ["runtime-tokio-rustls","postgres","macros","migrate","chrono","uuid","json"] }

# --- Auth / sessions ---
tower-sessions = "0.15.0"
tower-sessions-sqlx-store = { version = "0.15", features = ["postgres"] }  # verify matches 0.15
axum-login = "0.18.0"
argon2 = "0.5"
password-hash = "0.5"
jsonwebtoken = "9"
oauth2 = "5"                                                 # verify latest
openidconnect = "4"                                          # verify latest

# --- Jobs ---
apalis = "1"                                                 # verify 1.0 stable vs rc
apalis-postgres = "1"

# --- Config / secrets ---
figment = { version = "0.10", features = ["toml","env"] }
# google-cloud-secretmanager-v1 = "0.x"                      # only if runtime fetch

# --- Observability ---
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter","json"] }
tracing-stackdriver = "0.10"                                 # verify latest 0.x
sentry = { version = "0.34", features = ["tracing"] }        # verify latest
sentry-tower = "0.34"

# --- Middleware extras / errors ---
tower_governor = "0.8.0"
thiserror = "2"
anyhow = "1"

# --- Variant A additions ---
askama = "0.15"
axum-htmx = { version = "0.8.1", features = ["auto-vary"] }
axum_csrf = "0.11.0"
rust-embed = { version = "8", features = ["compression"] }

[dev-dependencies]
axum-test = "18"                                             # requires axum >= 0.8.7
wiremock = "0.6"
insta = { version = "1", features = ["json"] }

[profile.release]
lto = "thin"
codegen-units = 1
```
Versions marked "verify" could not be pinned to an exact patch from primary sources within budget; the major/minor is correct — confirm the patch at `cargo add` time.

## Variant B `package.json` essentials
```json
{
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "gen:api": "openapi-typescript http://localhost:8080/api-docs/openapi.json -o src/api/schema.d.ts",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": { "openapi-fetch": "^0.13", "react": "^18", "react-dom": "^18" },
  "devDependencies": {
    "vite": "^6", "typescript": "^5", "@vitejs/plugin-react": "^4",
    "openapi-typescript": "^7", "@playwright/test": "^1"
  }
}
```

## Reference Project Layout
**Variant A (HTMX), single crate:**
```
app/
├─ Cargo.toml
├─ rust-toolchain.toml         # pin toolchain
├─ CLAUDE.md                   # agent conventions
├─ migrations/                 # sqlx migrations (checked in)
├─ .sqlx/                      # offline query metadata (checked in)
├─ assets/                     # Tailwind input, htmx, alpine (source)
├─ templates/                  # askama: layouts/ partials/ pages/
├─ src/
│  ├─ main.rs                  # bootstrap: tracing, state, router, shutdown
│  ├─ config.rs                # figment layered config
│  ├─ error.rs                 # AppError + IntoResponse (content negotiation)
│  ├─ state.rs                 # AppState + FromRef
│  ├─ db.rs                    # PgPool init, Cloud SQL socket
│  ├─ telemetry.rs             # JSON logs + trace correlation
│  ├─ web/                     # pages (askama + htmx)
│  ├─ api/                     # JSON handlers + utoipa
│  ├─ auth/                    # sessions, login, csrf, oidc
│  ├─ ws/                      # websocket + fan-out
│  └─ jobs/                    # apalis workers / Cloud Tasks endpoints
└─ Dockerfile
```
**Variant B (SPA), monorepo:**
```
repo/
├─ backend/  (src/ as above, minus templates/assets; api/ primary)
├─ frontend/
│  ├─ package.json
│  ├─ vite.config.ts           # dev proxy /api → localhost:8080
│  ├─ src/api/schema.d.ts      # generated (openapi-typescript)
│  ├─ src/api/client.ts        # openapi-fetch wrapper
│  └─ src/...                  # React app
├─ pnpm-workspace.yaml
└─ Dockerfile                  # Node build → Rust build → distroless
```

## Key Wiring Patterns (validate before shipping)
**AppError + IntoResponse with content negotiation (C4):**
```rust
#[derive(thiserror::Error, Debug)]
pub enum AppError {
    #[error("not found")] NotFound,
    #[error("validation")] Validation(garde::Report),
    #[error(transparent)] Db(#[from] sqlx::Error),
    #[error(transparent)] Other(#[from] anyhow::Error),
}
impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, title) = match &self {
            AppError::NotFound => (StatusCode::NOT_FOUND, "Not Found"),
            AppError::Validation(_) => (StatusCode::UNPROCESSABLE_ENTITY, "Validation Failed"),
            _ => (StatusCode::INTERNAL_SERVER_ERROR, "Internal Error"),
        };
        // Inspect Accept (or HX-Request) header: HTML page for browsers (A),
        // RFC 9457 JSON { type,title,status,detail,errors:{field:[..]} } otherwise.
        (status, Json(problem_details(status, title, &self))).into_response()
    }
}
```
**Templated page handler with HTMX partial (Variant A):**
```rust
async fn tasks(hx: Option<HxRequest>, State(s): State<AppState>) -> Result<Html<String>, AppError> {
    let items = repo::list(&s.pool).await?;
    let html = if hx.is_some() { TasksFragment { items }.render()? }
               else { TasksPage { items }.render()? };
    Ok(Html(html))
}
```
**SPA fallback route (Variant B):**
```rust
let serve = ServeDir::new("frontend/dist")
    .not_found_service(ServeFile::new("frontend/dist/index.html"));
let app = Router::new().nest("/api", api_router).fallback_service(serve);
```
**JSON endpoint with validation + OpenAPI (C3/C4):**
```rust
#[utoipa::path(post, path = "/api/tasks",
    request_body = CreateTask, responses((status = 201, body = Task)))]
async fn create(State(s): State<AppState>, Garde(Json(input)): Garde<Json<CreateTask>>)
    -> Result<(StatusCode, Json<Task>), AppError> { /* ... */ }
```
**WebSocket handler skeleton with auth + fan-out hook (C7):**
```rust
async fn ws(ws: WebSocketUpgrade, auth: AuthSession, State(s): State<AppState>) -> Response {
    let Some(user) = auth.user else { return StatusCode::UNAUTHORIZED.into_response() };
    ws.on_upgrade(move |socket| handle(socket, user, s))
}
async fn handle(socket: WebSocket, user: User, s: AppState) {
    // subscribe to Redis Pub/Sub channel for cross-instance fan-out;
    // local tokio::sync::broadcast for same-instance; heartbeat ping ~30s;
    // select! over: socket recv, broadcast recv, redis msg, shutdown token.
}
```
**main.rs bootstrap (C10/C15):**
```rust
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    telemetry::init();                         // JSON logs, GCP severity mapping
    let cfg = config::load()?;                 // figment: defaults → file → env
    let pool = db::connect(&cfg).await?;        // Cloud SQL unix socket if set
    // Prefer running migrations as a separate deploy step (see runbook):
    // sqlx::migrate!().run(&pool).await?;
    let state = AppState::new(pool, cfg.clone());
    let app = router(state);
    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".into());
    let listener = TcpListener::bind(format!("0.0.0.0:{port}")).await?;
    axum::serve(listener, app).with_graceful_shutdown(shutdown_signal()).await?;
    Ok(())
}
```
**Dockerfile (Variant A — no Node in final image):**
```dockerfile
FROM debian:stable-slim AS assets
# download tailwindcss standalone binary; build assets/ → /out/css

FROM lukemathwalker/cargo-chef:latest-rust-slim AS chef
WORKDIR /app
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json
FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
ENV SQLX_OFFLINE=true
RUN cargo chef cook --release --recipe-path recipe.json
COPY . .
COPY --from=assets /out/css ./assets/css
RUN cargo build --release

FROM gcr.io/distroless/cc-debian12
COPY --from=builder /app/target/release/app /app
USER nonroot:nonroot
ENV PORT=8080
ENTRYPOINT ["/app"]
```
**Dockerfile (Variant B — adds Node/Vite stage):**
```dockerfile
FROM node:20-slim AS frontend
WORKDIR /fe
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ .
RUN npm run build              # → /fe/dist
# ... cargo-chef planner/builder stages as above (backend) ...
FROM gcr.io/distroless/cc-debian12
COPY --from=builder /app/target/release/app /app
COPY --from=frontend /fe/dist /frontend/dist
USER nonroot:nonroot
ENV PORT=8080
ENTRYPOINT ["/app"]
```
**CI outline:** `cargo fmt --check` → `clippy -D warnings` → `sqlx prepare --check` → `cargo test` → `cargo deny check` → OpenAPI export+diff → (B) `gen:api` + `git diff --exit-code` + `tsc --noEmit` + `vite build` + Playwright → build/push to Artifact Registry → `gcloud run deploy`.

## Cloud Run Runbook
```
gcloud run deploy app \
  --image=REGION-docker.pkg.dev/PROJ/REPO/app:TAG --region=REGION --port=8080 \
  --concurrency=80 \            # moderate; DB pool sized against this
  --timeout=3600 \              # 60-min max: bounds WebSocket lifetime
  --session-affinity \          # best-effort sticky for WS reconnects
  --cpu-boost \                 # faster cold start
  --min-instances=1 --max-instances=10 \
  --add-cloudsql-instances=PROJ:REGION:INSTANCE \   # injects /cloudsql socket
  --set-secrets=DATABASE_PASSWORD=db-pw:latest \    # Secret Manager → env
  --memory=512Mi --cpu=1
```
Caveats grounded in Google's docs:
- **WebSocket timeout.** Per Cloud Run's *Configure request timeout* doc: *"The timeout is set by default to 5 minutes (300 seconds) and can be extended up to 60 minutes (3600 seconds)."* For timeouts >15 min Google says to implement retries and tolerate reconnects. Set `--timeout=3600` and build client reconnect-and-resume; never assume a connection lives an hour.
- **Affinity is best-effort.** Per the request-timeout doc: *"When a client re-connects, a new request is initiated and the client isn't guaranteed to connect to the same instance of the service."* You **must** synchronize state across instances (Redis Pub/Sub). In-memory rooms alone silently drop cross-instance messages.
- **Scale-to-zero + jobs.** Either keep `--min-instances=1` with `--no-cpu-throttling` (CPU always allocated) so apalis workers run between requests, or prefer Cloud Tasks/Scheduler/Pub-Sub push and Cloud Run Jobs.
- **Migrations on deploy.** Instances start concurrently; prefer a separate migration step (a Cloud Run Job or CI gate before traffic switch) over per-startup `migrate!()`.
- **Graceful shutdown.** Per the Cloud Run *Container runtime contract*: *"Before shutting down an instance, Cloud Run sends a SIGTERM signal to all the containers in an instance, indicating the start of a 10 second period before the actual shutdown occurs, at which point Cloud Run sends a SIGKILL signal."* Wire `with_graceful_shutdown` to catch SIGTERM, stop new connections, drain in-flight requests, close WS with a close frame, and flush telemetry — all inside a window shorter than the 10s SIGKILL deadline. Remember Axum issue #3003: track WS tasks with a `CancellationToken`/`TaskTracker`.
- **Front proxy.** Don't double-compress; trust `X-Forwarded-*`/`X-Cloud-Trace-Context` only from the proxy; no end-to-end HTTP/2 for WebSockets.
- **DB pool sizing.** `--concurrency=80` × 10 instances = up to 800 request contexts; keep per-instance `max_connections` at 5–10 so `instances × pool ≤ Cloud SQL limit`.

## Recent-Bugs-vs-Plan Register (next 6 months)
- **Axum 0.9 (unreleased, no timeline).** Breaking changes accrue mainly in axum-extra. *Mitigation:* pin `axum = "=0.8.9"`, `axum-extra = "=0.12.6"`; budget a migration sprint when 0.9 lands — nothing forces it inside 3 years.
- **askama 0.15 integration-crate removal.** `askama_axum` no longer exists — agents hallucinate it. *Mitigation:* CLAUDE.md note; `template.render()? → Html(...)`.
- **axum_csrf 0.11 stale docs.** docs.rs still says "Axum 0.7" and the README uses removed `axum::Server::bind`; the crate *does* support 0.8 (`axum-core ^0.5`). *Mitigation:* ignore the doc string; use `axum::serve`.
- **apalis 1.0 line.** Historically shipped as `1.0.0-rc.x`. *Mitigation:* confirm a stable 1.0 before pinning; fall back to Cloud Tasks.
- **tower-sessions-sqlx-store + axum-login codec bug.** A reported issue where `rmp-serde` encoding of `axum-login`'s `auth_hash` broke Postgres sessions (fixed via `serde_json`). *Mitigation:* verify the store codec; add a login→reload integration test.
- **RustSec — RUSTSEC-2023-0071 (Marvin Attack on `rsa`).** CVSS 5.9 Medium, published 2023-11-22; per rustsec.org: *"Due to a non-constant-time implementation, information about the private key is leaked through timing information… No patch is yet available."* Still unpatched (cargo audit: *"No fixed upgrade is available!"*). *Mitigation:* it appears transitively via some MySQL/RSA paths — sqlx-postgres over rustls avoids it; gate with `cargo deny check advisories` and prefer rustls features throughout.

## Agent Enablement Notes (CLAUDE.md snippets)
- **axum 0.8:** "Use `axum::serve(listener, app)` — NOT `axum::Server::bind`. Route path params use `{name}`, not `:name`. Handlers return `impl IntoResponse` or `Result<_, AppError>`."
- **askama 0.15:** "Do NOT import `askama_axum` (removed). Render with `template.render()?`, wrap in `axum::response::Html`."
- **utoipa 0.2 axum:** "Register routes with `OpenApiRouter` + `routes!()`; annotate with `#[utoipa::path]`; derive `ToSchema` on DTOs."
- **sqlx 0.8:** "Queries are compile-time checked; after changing SQL run `cargo sqlx prepare` and commit `.sqlx/`. CI builds with `SQLX_OFFLINE=true`."
- **tower-sessions 0.15:** "Use the Postgres store, never `MemoryStore` (multi-instance / scale-to-zero)."
- **tower_governor 0.8:** "Build one `Arc<GovernorConfig>` and reuse; per-request construction creates independent limiters."
- **WebSockets:** "Never keep room state only in memory — publish/subscribe via Redis. Track spawned WS tasks with a `CancellationToken` for graceful shutdown."
- **axum-test 18:** "Use `TestServer::new(app)`; requires axum ≥ 0.8.7."

## Recommendations
1. **Build the shared core first, framework-agnostic of the head:** wire `main.rs` (tracing JSON logs + trace correlation, figment config, `PgPool` over the Cloud SQL socket, SIGTERM graceful shutdown), `AppError` with content negotiation, the tower-http layer stack, and `#[sqlx::test]` + axum-test scaffolding. This is variant-independent and de-risks everything else.
2. **Pick Variant B (SPA) as the default** for this TS-strong, agent-driven team. Stand up utoipa on the API, generate the client with `openapi-typescript` + `openapi-fetch`, and make client drift a CI failure. Serve the built SPA from the same Cloud Run service (same-origin cookies, no CORS). Use cookie session + CSRF, not JWT-in-JS.
3. **Choose Variant A instead** only if, at project start, you confirm: content/forms dominate, SEO matters, real-time is minimal, and you value a single tiny artifact with almost no client JS. Then adopt askama + axum-htmx + axum_csrf and the Tailwind-standalone build.
4. **Consider a hybrid** (server-rendered marketing/auth + SPA app) only once *both* needs are individually strong — it doubles the head's maintenance surface.
5. **For background work, start with Cloud Tasks + Cloud Scheduler push endpoints;** only introduce apalis-postgres if you already run `min-instances=1` with CPU always allocated.
6. **Run migrations as a discrete deploy step,** not at instance startup, to avoid concurrent-start races and cold-start latency.
7. **Gate CI on `cargo deny`, sqlx offline check, OpenAPI/TS-client drift, and clippy `-D warnings`** from day one — these catch the exact classes of regressions coding agents introduce.

**Benchmarks that would change these calls:** if apalis ships a stable 1.0 with documented Cloud Run patterns → promote it over Cloud Tasks for DB-centric jobs. If a strong Rust→TS exporter (ts-rs/specta) reaches 1.0 with axum ergonomics → it may replace OpenAPI for the internal client. If Axum 0.9 ships with a compelling feature and a clear migration → schedule the upgrade; until then stay pinned. If real-time requirements grow beyond best-effort affinity tolerances → evaluate a dedicated WS service or Cloud Load Balancing with generated-cookie affinity in front of Cloud Run.

## Caveats
- **Version confidence:** High for axum 0.8.9, askama 0.15 (merge + integration-crate removal), sqlx 0.8.6, tower-sessions 0.15, utoipa-axum 0.2, axum-test 18 (requires ≥0.8.7), axum_csrf 0.11, tower_governor 0.8, and the Cloud Run/Cloud SQL behaviors (from Google's own docs). Medium for the exact patch of oauth2/openidconnect/garde/tracing-stackdriver/sentry (major/minor correct, patch to be confirmed at `cargo add`) and for apalis 1.0 stability and the young official google-cloud Rust SDK.
- **`axum_csrf` and `apalis` are the weakest bus-factor links** in the stack (single-maintainer risk). CSRF is a small double-submit pattern you can hand-roll if the crate stalls; Cloud Tasks is a drop-in job escape hatch.
- **Dependency-tree hygiene:** keep everything on hyper 1 / http 1 / tower 0.5 / rustls 0.23 and choose **one** rustls crypto provider (aws-lc-rs *or* ring) across sqlx, HTTP clients, and the GCP SDK to avoid duplicate crypto providers. If you use Redis for both sessions and WS fan-out, use one Redis client crate — our recommendation (Postgres sessions + Redis only for fan-out) leaves just one.
- **Sources older than 12 months or secondary** were used only for corroboration (e.g., some blog posts on GCP logging and Dockerfiles); all version and behavioral claims trace to crates.io/docs.rs/GitHub or Google Cloud documentation. Where the `axum_csrf` doc string and README contradict its actual Cargo dependency, I reported the conflict and sided with the dependency (`axum-core ^0.5` ⇒ Axum 0.8).
- **The code patterns are illustrative** and compiled in my head, not against the toolchain — validate them locally before relying on them.
