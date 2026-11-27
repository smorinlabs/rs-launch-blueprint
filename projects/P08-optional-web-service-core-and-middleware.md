# P08 — Optional web service core and middleware

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
- **Spec:** [RS implementation roadmap design](../docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md)
- **Plan:** [Rex serial chain contract](../docs/superpowers/plans/2026-11-27-rex-serial-chain-contract.md)
- **Depends on:** P07
- **Prior art:** [R69 web-framework-stack](../research/topics/69-web-framework-stack/DECISION.md)
- **Prior art:** [R70 http-problem-envelope](../research/topics/70-http-problem-envelope/DECISION.md)
- **Prior art:** [R75 http-middleware-stack](../research/topics/75-http-middleware-stack/DECISION.md)
- **Prior art:** [R80 health-probe-endpoints](../research/topics/80-health-probe-endpoints/DECISION.md)

**Status:** `[ ]` scoped, not started.

### Scope
Implement the optional `crates/web` package and `rslbp-serve` production binary behind the off-by-default `web = ["dep:rs-launch-blueprint-web"]` feature:
- `axum 0.8.9` + `tokio 1.53.1` (`rt-multi-thread`, `net`, `signal`, `macros`, `time`, `sync`) inside `crates/web`, bridging to synchronous `ProjectsService` via `tokio::task::spawn_blocking` (`R05`, `R69`), with `State` + `FromRef` and `tower 0.5.3` dev-only for `ServiceExt::oneshot`.
- `[[bin]] rslbp-serve` (`required-features = ["web"]`) carrying the org CLI Design Standard R4.1 core flags (`-h`/`--help`, `-V`/`--version`, `-v`, `-q`, `--config`, `--debug`) and R67 exit integers (`0`, `1`, `130` SIGINT, `143` SIGTERM), graceful shutdown drain, and `WebSettings::from_env()` reading `RSLBP_WEB_*` env vars (`R77`, `OV-04`).
- RFC 9457 `application/problem+json` error envelope (`R70`) mapped deterministically from `DomainError` / `ErrorCode`.
- `/v1/projects` versioned routes, first-party cursor pagination (`base64`, `R72`), compare-and-set `IdempotencyStore` port (`crates/core`) + `Idempotency-Key` replay middleware (`R73`), and owned rate-limiting middleware (`R74`).
- Fixed-order `tower-http 0.7.1` middleware stack (`R75`: request-id header `request-id` / log field `request_id`, W3C `traceparent` opaque passthrough, security headers, body size limit, timeout, panic catch, tracing request span) + CORS (`R76`, `OV-08`, exposing `request-id` and `allow`).
- `/healthz` and `/readyz` unversioned operational probes (`R80`, `OV-05`) with `AtomicBool` readiness latch flipped on shutdown signal.
- `just serve` and `bacon` (`3.25.0`) dev-watch recipe (`R69`).

### Out of scope
- `utoipa` OpenAPI snapshot, `oasdiff`, `openapi-to-rust`, `otel`, `metrics`, and `Dockerfile` (`P09`)
- GitHub Actions CI and container publishing workflows (`P10`–`P11`)

### Tests & Tasks
- [ ] [P08-TS01] Add `crates/web/tests/` `ServiceExt::oneshot` integration tests covering `/v1/projects` CRUD, RFC 9457 error envelopes, cursor pagination, `Idempotency-Key` replay/conflict, rate limiting, CORS preflight & exposed headers (`OV-08`), `WebSettings::from_env()` validation, `/healthz` & `/readyz` shutdown latch, and feature-off compile isolation (`R69`–`R77`, `R80`)
- [ ] [P08-T01] Implement `WebSettings::from_env()` (`R77`), `AppState` + `FromRef`, `build_router`, `shutdown_signal`, `serve_until`, and `src/bin/serve.rs` (`R69`)
- [ ] [P08-T02] Implement RFC 9457 `problem+json` response mapping (`R70`), `/v1/projects` handlers, and `base64` cursor pagination (`R72`)
- [ ] [P08-T03] Implement `IdempotencyStore` port (`crates/core`) + replay middleware (`R73`), rate-limiting middleware (`R74`), fixed-order `tower-http` middleware stack (`R75`), and CORS layer (`R76`, `OV-08`)
- [ ] [P08-T04] Implement `/healthz` and `/readyz` probes with shared synchronous diagnostics and readiness latch (`R80`, `OV-05`), plus `just serve` / `bacon.toml` dev recipes
- [ ] [P08-T05] Verify feature-off default build remains free of `axum`/`tokio`, and both feature-off and `--features web` test suites pass completely

### Deliverable
```bash
cargo nextest run --workspace
cargo nextest run --workspace --features web
just check
```

### Automated Verification
- `cargo tree --no-default-features` contains no `axum` or `tokio`
- `cargo nextest run --workspace --features web` passes all integration and middleware tests
- `just check` and `cargo deny --all-features check` exit 0

### Manual Verification
- Start `just serve`, curl `/healthz`, `/readyz`, and `/v1/projects`, and confirm `SIGINT` drains cleanly with exit 130
