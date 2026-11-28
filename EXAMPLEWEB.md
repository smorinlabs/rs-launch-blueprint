# `rslbp-serve` — Optional Web Service Walkthrough

`rslbp-serve` is the Axum HTTP counterpart of the `rslbp` CLI: a thin async web
adapter over the same synchronous `rs-launch-blueprint` standalone library crate
(`ProjectsPort`, `ProjectsService`, `Diagnostics`, `ErrorCode`), isolated in the
internal workspace crate `crates/web` (`publish = false`, `R69`, `OV-18`).

## Architecture & Cargo Features

| Package / Feature                            | Enables                                                                                                      |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `rs-launch-blueprint --no-default-features`  | Standalone minimal library (**17** normal crates; zero HTTP, TOML, CLI, Tokio, or Axum).                     |
| `rs-launch-blueprint` (default)              | Standalone library with `http` + `config` (**56** normal crates; zero CLI, Tokio, or Axum).                  |
| `rs-launch-blueprint-web` (default)          | `axum`, `tokio`, `tower-http`, `utoipa`, `problem_details`, `IdempotencyStore`, and `[[bin]] rslbp-serve`.   |
| `rs-launch-blueprint-web --features metrics` | Exposes Prometheus RED metrics on `GET /metrics` (`metrics` + `metrics-exporter-prometheus`).                |
| `rs-launch-blueprint-web --features otel`    | Exports OpenTelemetry OTLP traces when `RSLBP_WEB_OTEL_ENABLED=true` and injects outbound W3C `traceparent`. |

Handlers run synchronous `rs-launch-blueprint` port operations on Tokio's blocking pool
via `tokio::task::spawn_blocking` (`R05`), keeping the standalone library sync and
runtime-agnostic.

## Running Locally

```bash
just serve                                                        # Live-reload dev loop via bacon (bacon.toml)
just serve-once                                                   # Single foreground run via Cargo
cargo run -p rs-launch-blueprint-web --bin rslbp-serve            # Direct Cargo run (default 127.0.0.1:8000)
cargo run -p rs-launch-blueprint-web --all-features --bin rslbp-serve  # Run with metrics + otel compiled in
just docker-web                                                   # Build local multi-stage distroless image
```

Run the published GHCR container image (once released and made public per
[docs/RELEASE.md](docs/RELEASE.md)):

```bash
docker pull --platform linux/amd64 ghcr.io/smorinlabs/rs-launch-blueprint:latest
docker run --rm --platform linux/amd64 -p 127.0.0.1:8000:8000 \
  ghcr.io/smorinlabs/rs-launch-blueprint:latest
```

`rslbp-serve` accepts the minimal org CLI global core (`-h`/`--help`,
`-V`/`--version`, `-v`/`--verbose`, `-q`/`--quiet`, `--config`, `--debug`).
All service configuration flows through `RSLBP_WEB_*` environment variables and
exits with `0` (normal), `1` (I/O error), `2` (`RSLB203` invalid env setting),
`130` (`SIGINT` drain), or `143` (`SIGTERM` drain).

## Endpoints

| Method & Path              | Tag        | Description                                                                                                            |
| -------------------------- | ---------- | ---------------------------------------------------------------------------------------------------------------------- |
| `GET /healthz`             | `ops`      | Stateless liveness probe returning byte-stable `{status, version, os, arch}`.                                          |
| `GET /readyz`              | `ops`      | Readiness probe: checks shutdown latch, then runs redacted `core` diagnostics; `503` problem+json on failure or drain. |
| `GET /metrics`             | `ops`      | Prometheus RED metrics (`metrics` feature + `RSLBP_WEB_METRICS_ENABLED=true`).                                         |
| `GET /v1/projects`         | `projects` | Cursor-paginated project collection (`limit`, `cursor`, optional `workspace`).                                         |
| `POST /v1/projects`        | `projects` | Create a project (`201 Created` + `Location` header; supports `Idempotency-Key`).                                      |
| `GET /v1/projects/{id}`    | `projects` | Retrieve a single project (`200 OK` or `404` RFC 9457 problem document).                                               |
| `DELETE /v1/projects/{id}` | `projects` | Delete a single project (`204 No Content` or `404` problem document).                                                  |

Business routes live under `/v1` (`F308`); operational endpoints (`/healthz`,
`/readyz`, `/metrics`) are unversioned and excluded from noisy access logs.

## Configuration (`RSLBP_WEB_*`, `R77`)

All 19 service settings are parsed once at startup by `WebSettings::from_env()`
(`crates/web/src/settings.rs`). Invalid values fail fast at boot (`RSLB203`,
exit `2`). Exported-but-empty values are ignored.

| Environment Variable                      | Default                                        | Effect                                                                |
| ----------------------------------------- | ---------------------------------------------- | --------------------------------------------------------------------- |
| `RSLBP_WEB_HOST`                          | `127.0.0.1` (`0.0.0.0` in `Dockerfile`)        | Listen IPv4/IPv6 address.                                             |
| `RSLBP_WEB_PORT`                          | `8000`                                         | Listen TCP port (`0` selects an ephemeral OS port).                   |
| `RSLBP_WEB_ROOT_PATH`                     | _(empty)_                                      | Reverse-proxy prefix (e.g., `/api`; rejects version segments).        |
| `RSLBP_WEB_LOG_LEVEL`                     | `info`                                         | Service log level (`off\|error\|warn\|info\|debug\|trace`).           |
| `RSLBP_WEB_LOG_FORMAT`                    | `json`                                         | `json` or `console` (`auto` is rejected so containers stay stable).   |
| `RSLBP_WEB_CORS_ORIGINS`                  | _(empty)_                                      | Comma-separated `http(s)://host[:port]` origins; empty disables CORS. |
| `RSLBP_WEB_REQUEST_TIMEOUT_SECONDS`       | `30`                                           | End-to-end request timeout (`408` problem+json on expiry).            |
| `RSLBP_WEB_MAX_BODY_BYTES`                | `1048576` (1 MiB)                              | Max buffered request body cap (`413` problem+json if exceeded).       |
| `RSLBP_WEB_RATE_LIMIT_PER_IP`             | `10/second`                                    | Sustained per-IP token bucket rate (cannot be disabled).              |
| `RSLBP_WEB_RATE_LIMIT_PER_IP_BURST`       | `20`                                           | Burst ceiling paired with `RSLBP_WEB_RATE_LIMIT_PER_IP`.              |
| `RSLBP_WEB_RATE_LIMIT_MAX_ENTRIES`        | `10000`                                        | Bounded per-IP bucket cache size.                                     |
| `RSLBP_WEB_IDEMPOTENCY_TTL_SECONDS`       | `86400`                                        | Retention TTL for completed idempotency replay records.               |
| `RSLBP_WEB_IDEMPOTENCY_IN_FLIGHT_SECONDS` | `60`                                           | Expiry window for in-flight idempotency claims.                       |
| `RSLBP_WEB_IDEMPOTENCY_MAX_ENTRIES`       | `10000`                                        | Bounded in-memory idempotency store capacity.                         |
| `RSLBP_WEB_PROBLEM_BASE_URI`              | `https://problems.rs-launch-blueprint.invalid` | HTTPS base URI for RFC 9457 `type` fields (`about:blank` forbidden).  |
| `RSLBP_WEB_METRICS_ENABLED`               | `true`                                         | Mount `/metrics` when compiled with `--features metrics`.             |
| `RSLBP_WEB_OTEL_ENABLED`                  | `false`                                        | Enable OTLP trace export when compiled with `--features otel`.        |
| `RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS`     | `8`                                            | Total graceful drain window on `SIGTERM`/`SIGINT`.                    |
| `RSLBP_WEB_READINESS_PAUSE_SECONDS`       | `0`                                            | Pre-drain pause while `/readyz` returns `503` (must be `< shutdown`). |

Secrets follow the CLI rule: supply `RSLBP_TOKEN` via environment or dedicated
credentials store — never inside `RSLBP_WEB_*` or layered TOML config.

## Error Contract (RFC 9457 `application/problem+json`, `R70`)

Every non-2xx response — domain errors, extractor rejections, 404/405 fallbacks,
timeouts, body-cap refusals, rate limits, panics, and failing readiness probes —
emits `Content-Type: application/problem+json`:

```json
{
  "type": "https://problems.rs-launch-blueprint.invalid/resource-not-found",
  "title": "Not Found",
  "status": 404,
  "detail": "project 'missing' not found",
  "instance": "/v1/projects/missing",
  "code": "resource_not_found",
  "catalog_code": "RSLB301"
}
```

Invariant `W5`: **every `5xx` response redacts internal details** (`detail_is_public = false`)
and logs the underlying cause privately on stderr.

| `ErrorCode` (`R67`)                                   | HTTP Status | `code`                                           | Public `detail`? |
| ----------------------------------------------------- | ----------- | ------------------------------------------------ | ---------------- |
| `RSLB201`, `RSLB204`, `RSLB205`                       | `400`       | `invalid_request`, etc.                          | Yes              |
| `RSLB401`                                             | `401`       | `credentials_absent`                             | Yes              |
| `RSLB402`                                             | `401`       | `credentials_rejected`                           | No (redacted)    |
| `RSLB301`                                             | `404`       | `resource_not_found`                             | Yes              |
| `RSLB501`                                             | `409`       | `resource_conflict`                              | Yes              |
| `RSLB102`, `RSLB103`                                  | `502`       | `upstream_transport_error`, `upstream_api_error` | No               |
| `RSLB000`, `RSLB101`, `RSLB104`, `RSLB202`, `RSLB203` | `500`       | `internal_error`, `storage_io_error`, etc.       | No               |
| Extractor / schema validation                         | `422`       | `validation_error` (+ `errors[]` JSON Pointers)  | Yes              |
| Rate limited                                          | `429`       | `rate_limit_exceeded` (+ `Retry-After`)          | Yes              |
| Draining / failing `/readyz`                          | `503`       | `service_unavailable` (+ redacted `diagnostics`) | Yes              |

## Baked-In Middleware & Behaviors

- **Fixed-order `tower-http` stack (`R75`):** `request-id` generation/extraction
  -> security headers (`X-Content-Type-Options`, `X-Frame-Options`,
  `Referrer-Policy`, `Strict-Transport-Security`) -> `request-id` response echo
  -> W3C `traceparent` propagation -> structured access log (excluding
  `/healthz`, `/readyz`, `/metrics`) -> panic catch (`500`) -> conditional CORS
  (`R76`) -> per-IP rate limiting (`R74`) -> timeout (`408`) & body cap (`413`).
- **Cursor pagination (`R72`):** `GET /v1/projects?limit=20&cursor=<opaque>`
  returns `{"items": [...], "next_cursor": ..., "has_more": true|false}`.
- **Compare-and-set Idempotency (`R73`):** send `Idempotency-Key` on
  `POST /v1/projects`. Identical retries replay the cached `201` response with
  `Idempotency-Replayed: true`; concurrent in-flight duplicates return `409`;
  mismatched request bodies for the same key return `422`.
- **Observability (`R78`, `R79`):** W3C `traceparent` propagation is always active
  on HTTP requests; compile with `--features metrics` for `/metrics` and
  `--features otel` + `RSLBP_WEB_OTEL_ENABLED=true` + standard `OTEL_*` variables
  for OTLP trace export with `trace_id`/`span_id` log correlation.

## Curl Walkthrough

```bash
# Operational probes
curl -s http://127.0.0.1:8000/healthz | jq
curl -s http://127.0.0.1:8000/readyz | jq

# Create a project idempotently
curl -s -i -X POST http://127.0.0.1:8000/v1/projects \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: create-alpha-1" \
  -d '{"name":"Alpha","workspace":"Core"}'

# Replay with the same Idempotency-Key (returns cached 201 + Idempotency-Replayed: true)
curl -s -i -X POST http://127.0.0.1:8000/v1/projects \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: create-alpha-1" \
  -d '{"name":"Alpha","workspace":"Core"}'

# List projects with cursor pagination
curl -s "http://127.0.0.1:8000/v1/projects?limit=10" | jq

# Inspect an RFC 9457 problem document on 404
curl -s http://127.0.0.1:8000/v1/projects/does-not-exist | jq
```

## OpenAPI Contract & Typed Client Pipeline (`R71`, `R83`, `R84`)

The committed OpenAPI 3.1 snapshot at `openapi/openapi.json` is the reviewable
HTTP API contract:

1. **Snapshot drift guard (`R71`):** after changing any route or schema, run
   `just export-openapi` and commit `openapi/openapi.json`. `just check-openapi`
   fails immediately on drift.
2. **Breaking-change detection (`R71`):** `.github/workflows/api-contract.yml`
   and `just api-breaking` run pinned `oasdiff v1.32.1` against the base branch
   with `openapi/oasdiff-levels.txt` and `openapi/breaking-accepted.txt`.
3. **Contract fuzzing (`R83`):** `just test-contract` runs the `proptest`-driven
   OpenAPI contract fuzzer against live router dispatch (`crates/web/tests/contract_fuzz.rs`).
4. **Typed Rust client generation (`R84`, `OV-11`):** `just generate-client`
   (alias `just client-rust`) invokes pinned `openapi-to-rust 0.17.0` using
   `openapi-to-rust.toml` and writes a standalone async crate to `clients/rust/`.
