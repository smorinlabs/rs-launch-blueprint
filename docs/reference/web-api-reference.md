# Web API Reference (`rslbp-serve`)

The optional HTTP service (`crates/web`, `[[bin]] rslbp-serve`) compiles only
when `--features web` (or `--all-features`) is passed (`R69`–`R80`, `R83`, `R84`).

## Binary Flags & Exit Codes (`R69`, `R67`)

`rslbp-serve` accepts only the minimal org CLI global core (`-h`/`--help`,
`-V`/`--version`, `-v`/`--verbose`, `-q`/`--quiet`, `--config`, `--debug`).
All service settings are supplied via `RSLBP_WEB_*` environment variables.

| Exit  | Cause                                           |
| ----- | ----------------------------------------------- |
| `0`   | Clean shutdown                                  |
| `1`   | Startup bind failure or runtime I/O error       |
| `2`   | Invalid `RSLBP_WEB_*` configuration (`RSLB203`) |
| `130` | Graceful drain completed after `SIGINT`         |
| `143` | Graceful drain completed after `SIGTERM`        |

## HTTP Endpoints & Operation IDs

The normative machine-readable schema lives in `openapi/openapi.json` (OpenAPI
3.1.0, generated from `utoipa` annotations and staleness-checked by
`just check-openapi`):

| Method   | Path                | Operation ID              | Success Status & Headers                             |
| -------- | ------------------- | ------------------------- | ---------------------------------------------------- |
| `GET`    | `/healthz`          | `ops-healthz`             | `200 OK`, `Cache-Control: no-cache`                  |
| `GET`    | `/readyz`           | `ops-readyz`              | `200 OK` (or `503` problem+json with `diagnostics`)  |
| `GET`    | `/metrics`          | _(metrics feature)_       | `200 OK`, Prometheus exposition text                 |
| `GET`    | `/v1/projects`      | `projects-list_projects`  | `200 OK`, `Cache-Control: private, no-cache`         |
| `POST`   | `/v1/projects`      | `projects-create_project` | `201 Created`, `Location`, `Cache-Control: no-store` |
| `GET`    | `/v1/projects/{id}` | `projects-get_project`    | `200 OK`, `Cache-Control: private, no-cache`         |
| `DELETE` | `/v1/projects/{id}` | `projects-delete_project` | `204 No Content`, `Cache-Control: no-store`          |

### Pagination Contract (`R72`)

`GET /v1/projects` accepts:

- `limit` (optional integer, `1..=100`, default `50`; out-of-range returns `422`)
- `cursor` (optional opaque URL-safe base64 token from previous `next_cursor`)
- `workspace` (optional filter string; duplicate parameter returns `400`)

Response envelope:

```json
{
  "items": [],
  "next_cursor": null,
  "has_more": false
}
```

### Idempotency Contract (`R73`)

`POST /v1/projects` accepts optional header `Idempotency-Key` (max 255 chars):

- First call stores the in-flight claim and persists `2xx` responses for
  `RSLBP_WEB_IDEMPOTENCY_TTL_SECONDS` (default `86400`).
- Identical retry replays the cached status and body with header
  `Idempotency-Replayed: true`.
- Concurrent duplicate while first request is still running returns `409 Conflict`.
- Same key with a different request payload returns `422 Unprocessable Entity`.

## Middleware Layer Order (`R75`, `R76`, `R74`)

Requests traverse layers in fixed outer-to-inner order:

1. `request-id` extraction or UUIDv4 generation (L1)
2. Security headers (`X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`,
   `Referrer-Policy: no-referrer`, `Strict-Transport-Security`, L2)
3. `request-id` echo onto every outgoing response (L3)
4. W3C `traceparent` extraction/propagation (L3b, active even without `--features otel`)
5. Sensitive request header redaction + structured access log event (L5, excluding `/healthz`, `/readyz`, `/metrics`)
6. Panic catch (`500` RFC 9457 problem+json, internal details redacted, L6)
7. Conditional CORS (`CorsLayer` installed only when `RSLBP_WEB_CORS_ORIGINS` is set, L7)
8. Per-IP GCRA rate limiter (`429` + `Retry-After`, L8)
9. End-to-end request timeout (`408`) and request body size cap (`413`, L9)
10. Route-scoped `Idempotency-Key` middleware on `POST /v1/projects`

## Environment Variables (`R77`)

All 19 variables share the compile-time `RSLBP_WEB_` prefix:
`RSLBP_WEB_HOST`, `RSLBP_WEB_PORT`, `RSLBP_WEB_ROOT_PATH`,
`RSLBP_WEB_LOG_LEVEL`, `RSLBP_WEB_LOG_FORMAT`, `RSLBP_WEB_CORS_ORIGINS`,
`RSLBP_WEB_REQUEST_TIMEOUT_SECONDS`, `RSLBP_WEB_MAX_BODY_BYTES`,
`RSLBP_WEB_RATE_LIMIT_PER_IP`, `RSLBP_WEB_RATE_LIMIT_PER_IP_BURST`,
`RSLBP_WEB_RATE_LIMIT_MAX_ENTRIES`, `RSLBP_WEB_IDEMPOTENCY_TTL_SECONDS`,
`RSLBP_WEB_IDEMPOTENCY_IN_FLIGHT_SECONDS`, `RSLBP_WEB_IDEMPOTENCY_MAX_ENTRIES`,
`RSLBP_WEB_PROBLEM_BASE_URI`, `RSLBP_WEB_METRICS_ENABLED`,
`RSLBP_WEB_OTEL_ENABLED`, `RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS`, and
`RSLBP_WEB_READINESS_PAUSE_SECONDS`.

## Contract & Client Recipes

```bash
just export-openapi     # Regenerate openapi/openapi.json from utoipa annotations
just check-openapi      # Fail if openapi/openapi.json drifted or violates F307/F312
just api-breaking       # Compare openapi/openapi.json against origin/main via oasdiff
just test-contract      # Run R83 OpenAPI 3.1 proptest contract fuzzer
just generate-client    # Generate standalone async Rust client into clients/rust/ (R84)
```

For full curl examples, environment defaults, and RFC 9457 error tables, see
`EXAMPLEWEB.md` at the repository root.
