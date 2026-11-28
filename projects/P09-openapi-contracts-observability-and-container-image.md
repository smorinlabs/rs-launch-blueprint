# P09 — OpenAPI contracts observability and container image

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
- **Spec:** [RS implementation roadmap design](../docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md)
- **Plan:** [Rex serial chain contract](../docs/superpowers/plans/2026-11-27-rex-serial-chain-contract.md)
- **Depends on:** P08
- **Prior art:** [R51 container-image](../research/topics/51-container-image/DECISION.md)
- **Prior art:** [R71 openapi-generation-pipeline](../research/topics/71-openapi-generation-pipeline/DECISION.md)
- **Prior art:** [R78 opentelemetry-integration](../research/topics/78-opentelemetry-integration/DECISION.md)
- **Prior art:** [R79 prometheus-metrics](../research/topics/79-prometheus-metrics/DECISION.md)

**Status:** `[x]` completed (2026-11-27).

### Scope
Complete the web service's API contract pipeline, nested observability features (`otel` and `metrics`), production `Dockerfile`, and Blaze re-probe:
- OpenAPI pipeline (`R71`, `R83`, `R84`): `utoipa 6.0.0` + `utoipa-axum 0.3.0` on `crates/web`, deterministic OpenAPI export helper + committed `openapi.json` snapshot + drift test, `oasdiff` breaking-change recipe, contract validation / proptest suite per `R83` disposition, and `just generate-client` using pinned `openapi-to-rust 0.17.0` (`R84`, `OV-11`).
- Nested `otel = ["web", ...]` feature (`R78` + py `P10` OTel coverage): `tracing-opentelemetry 0.34` + OpenTelemetry Rust `0.33`, self-redacting exporter attached to `src/telemetry.rs`'s extension slot, named `deny.toml` exception per `R58`/`R78`, plus tests exercising **both** `otel`-enabled and `otel`-disabled trace-correlation paths.
- Nested `metrics = ["web", ...]` feature (`R79`, `OV-07`): `metrics 0.24.6` + `metrics-exporter-prometheus 0.18.3` (`default-features = false`) rendering `/metrics` in Prometheus text exposition format.
- Production multi-stage `Dockerfile` + `.dockerignore` + `just docker-web` recipe (`R51`), prepared for GHCR container publishing (owner review-gate `OVERRIDE` `1a-A`, workflow wired in `P11`).
- Live Blaze compatibility re-probe (`just blaze-status`) testing `--features web`, `--features metrics`, and `--features otel` against the installed Blaze release to record current status of `indexable-inc/blaze#598` (`utoipa-gen`) and `#1826` (`metrics-exporter-prometheus`).

### Out of scope
- GitHub Actions CI workflows (`api-contract.yml`, `docker-web.yml`, `P10`) and GHCR release workflow (`publish-container.yml`, `P11`)

### Tests & Tasks
- [x] [P09-TS01] Add OpenAPI committed-snapshot drift test (`R71`), R83 contract/proptest suite, `otel`-enabled & `otel`-disabled trace-correlation tests (py `P10`), and `/metrics` Prometheus exposition tests (`R79`)
- [x] [P09-T01] Annotate `/v1` models and handlers with `utoipa`/`utoipa-axum`, commit `openapi.json`, and wire `just export-openapi`, `just check-openapi`, and `just generate-client` (`openapi-to-rust`, `R71`, `R84`)
- [x] [P09-T02] Implement nested `otel` feature (`tracing-opentelemetry` + self-redacting exporter, `R78`) and update `deny.toml` with the named `tracing-opentelemetry` exception
- [x] [P09-T03] Implement nested `metrics` feature (`metrics` + `metrics-exporter-prometheus`, `/metrics` route, `R79`, `OV-07`)
- [x] [P09-T04] Add production multi-stage `Dockerfile`, `.dockerignore`, and `just docker-web` recipe (`R51`, noting owner `1a-A` GHCR publishing override)
- [x] [P09-T05] Re-run `just blaze-status` against default, `--features web`, and `--features metrics` to record live `#598`/`#1826` status, and verify `--all-features` tests, OpenAPI snapshot, and Docker build pass
      2026-11-27: verified `just check`, `just check-openapi`, `just test-contract`, `cargo nextest run --workspace --all-features`, `cargo deny --all-features check`, live `/metrics` exposition + SIGTERM exit 143 on `rslbp-serve`, and `just blaze-status` on `blaze 0.20261127.0` (`#598` `utoipa-gen` and `#1826` `metrics-exporter-prometheus` resolved in isolated probes, `otel` crates pass isolated probe; workspace `blaze check` blocked by `utoipa-axum 0.3.0` `routes!` macro and CLI lacks `--features` so Cargo stays authoritative; Docker daemon unavailable locally, `Dockerfile`/`.dockerignore` verified by R51/1a-A static contract tests)

### Deliverable
```bash
cargo nextest run --workspace --all-features
just check-openapi
just blaze-status
```

### Automated Verification
- `cargo nextest run --workspace --all-features` passes (covering `web`, `otel`, and `metrics` tests)
- `just check-openapi` confirms zero drift against committed `openapi.json`
- `just check` and `cargo deny --all-features check` exit 0
- If Docker daemon is available locally, `just docker-web` builds cleanly and responds 200 on `/healthz`

### Manual Verification
- Inspect `openapi.json` and `/metrics` output for schema accuracy and RFC 9457 error responses
