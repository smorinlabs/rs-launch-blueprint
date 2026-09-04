# Area: web-service

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| id | feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|---|
| F303 | web service exists at all | `src/py_launch_blueprint/web/app.py:102` — a FastAPI service under an optional install extra | — | py-only | — | No web/HTTP-server code, dependency, or test exists anywhere in the ts repo; `tests/api.test.ts` is an *outbound* API client, not a server. |
| — | web service ships behind an optional install extra | `pyproject.toml:56` — `web = [` under `[project.optional-dependencies]` | — | py-only | — | Bundles FastAPI, uvicorn, pydantic-settings, fastapi-pagination, slowapi, prometheus-fastapi-instrumentator in one extra; see F017 |
| F304 | tracing dependencies are a further, separate optional extra | `pyproject.toml:64` — `otel = [` — a second extras group beyond `web` | — | py-only | — | Keeps `pip install ...[web]` lean; OTel packages only pulled in when tracing is wanted. |
| — | app-factory composition pattern | `src/py_launch_blueprint/web/app.py:102` — `create_app()` wires settings, handlers, middleware, routers in one function | — | py-only | — | Mirrors the CLI's `cli/main.py` composition root; see F002 |
| F305 | single RFC 9457 error envelope for every non-2xx response | `src/py_launch_blueprint/web/problems.py:52` — `PROBLEM_CONTENT_TYPE = "application/problem+json"` applied to all error handlers | — | py-only | — | Covers domain errors, bare `HTTPException`s, and FastAPI's own 422s alike (WEB-01). |
| F306 | domain-error-to-HTTP-status mapping table | `src/py_launch_blueprint/web/problems.py:57` — `ERROR_STATUS: dict[type[PyError], int]` | — | py-only | — | Depends on `error-taxonomy-exit-codes` (the `PyError`/exit-code hierarchy decided in the CLI area) for which classes exist to map. |
| F307 | OpenAPI schema is post-processed to match the runtime error shape | `src/py_launch_blueprint/web/problems.py:104` — `original_openapi = app.openapi`, wrapped to rewrite 422 responses | — | py-only | — | Prevents generated clients from parsing FastAPI's default (unused) validation-error shape (WEB-01/WEB-04). |
| F308 | business routes are version-prefixed; ops endpoints are not | `src/py_launch_blueprint/web/versioning.py:42` — `V1_PREFIX = "/v1"` | — | py-only | — | `/healthz`, `/readyz`, `/metrics` stay unversioned; a breaking change means a new `/v2` tree (WEB-02). |
| F309 | route deprecation signaling helper | `src/py_launch_blueprint/web/versioning.py:45` — `def deprecation_headers(` stamps `Deprecation`/`Sunset` headers | — | py-only | — | RFC 8594; paired with OpenAPI's own `deprecated` flag on the route. |
| F310 | collection pagination via page/size query params and items/total envelope | `src/py_launch_blueprint/web/routers/projects.py:30` — `from fastapi_pagination import Page, paginate` | — | py-only | — | WEB-03; items stay `core.models` objects, only the collection wrapper is web-specific. |
| F311 | pagination is wired app-wide via one factory call | `src/py_launch_blueprint/web/app.py:204` — `add_pagination(app)` | — | py-only | — | Registers the pagination response models/params globally instead of per-router. |
| F312 | OpenAPI operation ids are curated as stable `tag-function` names | `src/py_launch_blueprint/web/app.py:77` — `def _operation_id(route: APIRoute) -> str:` | — | py-only | — | WEB-04; keeps generated-client method names stable across schema regen. |
| F313 | unsafe-method requests replay a cached response via `Idempotency-Key` | `src/py_launch_blueprint/web/idempotency.py:43` — `IDEMPOTENCY_HEADER = "idempotency-key"` on POST/PUT/PATCH | — | py-only | — | WEB-05; replayed responses carry `Idempotency-Replayed: true`. |
| F314 | idempotency cache only stores successful (2xx) outcomes | `src/py_launch_blueprint/web/idempotency.py:141` — `if 200 <= response.status_code < 300:` | — | py-only | — | Stripe semantics: errors are meant to be retried for real, not replayed. |
| F315 | idempotency cache store is in-memory, single-instance by design | `src/py_launch_blueprint/web/idempotency.py:91` — `self._store: OrderedDict[_CacheKey, _Entry] = OrderedDict()` | — | py-only | — | Documented as a Redis-swap point before scaling to multiple instances; not built. |
| F316 | rate-limit store is in-memory, single-instance by design | `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` with no `storage_uri` set, so slowapi defaults to its in-memory backend | — | py-only | — | Same Redis-swap-point documentation as the idempotency store (`idempotency.py:91`); not built. |
| F317 | middleware ordering is a contract (id/security-header middleware outermost) | `src/py_launch_blueprint/web/app.py:145` — `app.add_middleware(SecurityHeadersMiddleware)` added last (outermost) | — | py-only | — | So CORS preflights and rate-limit 429s still carry request-id and security headers. |
| F318 | request-id propagation through log context and response header | `src/py_launch_blueprint/web/middleware.py:72` — reads `x-request-id` or generates one, binds it to log context | — | py-only | — | Echoed back via `src/py_launch_blueprint/web/middleware.py:82` — `response.headers["x-request-id"] = request_id`. |
| F319 | one canonical structured access-log event per request | `src/py_launch_blueprint/web/middleware.py:95` — `log.info("http_request", ...)` with route template, status, duration_ms | — | py-only | — | WEB-12; replaces uvicorn's plain-text access line. |
| F320 | probe endpoints are excluded from access-log volume | `src/py_launch_blueprint/web/middleware.py:49` — `ACCESS_LOG_EXCLUDED_PATHS: frozenset[str]` | — | py-only | — | `/healthz`, `/readyz`, `/metrics` would otherwise dominate log volume. |
| F321 | security response headers stamped on every response | `src/py_launch_blueprint/web/middleware.py:56` — `SECURITY_HEADERS: dict[str, str] = {` (nosniff, DENY, no-referrer, HSTS) | — | py-only | — | WEB-23; set unconditionally, including HSTS over plain http in dev. |
| F322 | CORS middleware installed only when an allowlist is configured | `src/py_launch_blueprint/web/app.py:136` — `if settings.cors_origins:` | — | py-only | — | Cross-origin calls are opt-in; empty list (the default) means no CORS middleware at all. |
| F323 | rate limiting is wired but off by default, one env var enables it | `src/py_launch_blueprint/web/settings.py:70` — `rate_limit: str &#124; None = None` gates `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` | — | py-only | — | WEB-22; 429s render as problem documents with accurate `Retry-After`. |
| F324 | typed env settings with an app-derived env-var prefix | `src/py_launch_blueprint/web/settings.py:38` — `ENV_PREFIX: str = f"{APP_NAME.upper()}_WEB_"` | — | py-only | — | WEB-30; pydantic-settings, so a fork's rename keeps the prefix correct. |
| F325 | OpenTelemetry tracing is opt-in and soft-imported | `src/py_launch_blueprint/web/telemetry.py:71` — `except ModuleNotFoundError:` degrades to a warning, not a crash | — | py-only | — | WEB-10; absence of the `otel` extra never breaks the service. |
| F326 | Prometheus RED metrics exposed at /metrics, on by default | `src/py_launch_blueprint/web/telemetry.py:48` — `.expose(app, endpoint="/metrics", include_in_schema=False)` | — | py-only | — | WEB-11; excluded from its own measurements and from the OpenAPI schema. |
| F327 | uvicorn's own loggers are folded into the shared logging pipeline | `src/py_launch_blueprint/web/logging.py:71` — `access_logger = logging.getLogger("uvicorn.access")` handlers cleared | — | py-only | — | Server lifecycle lines come out structured like every other event; access logging is silenced in favor of the canonical event. |
| F328 | liveness endpoint reports version + runtime info | `src/py_launch_blueprint/web/app.py:153` — `@app.get("/healthz", tags=["ops"])` | — | py-only | — | The web analog of `--version`. |
| F329 | readiness endpoint runs the same diagnostics as the CLI doctor command | `src/py_launch_blueprint/web/app.py:184` — `async def readyz(` returns 503 problem doc on failure | — | py-only | — | Reuses `core/diagnostics.py`'s `run_diagnostics`, one source of truth with the CLI. |
| F330 | config loads once at startup, with a lazy-load fallback dependency | `src/py_launch_blueprint/web/deps.py:37` — `def get_config(request: Request) -> Config:` | — | py-only | — | Falls back to loading lazily for raw-ASGI callers (e.g. schemathesis) that bypass the lifespan. |
| — | web routes return the same core model objects the CLI renders | `src/py_launch_blueprint/web/routers/projects.py:32` — `from py_launch_blueprint.core.models import Project` | — | py-only | — | One shared data contract between the API and the CLI; the web layer stays a thin adapter; see F018 |
| F331 | adding an API resource is one router import plus one registry entry | `src/py_launch_blueprint/web/routers/__init__.py:30` — `ROUTERS: list[APIRouter] = [projects_router]` | — | py-only | — | Mirrors the CLI's `cli/commands/__init__.py` registration pattern. |
| F332 | committed OpenAPI snapshot is the reviewable API contract, staleness-tested | `docs/api/openapi.json` — committed spec file, checked by `tests/web/test_openapi_snapshot.py:30` — `generated["info"]["version"] = SNAPSHOT_VERSION` then compared | — | py-only | — | WEB-51; `just export-openapi` (`Justfile:307`) regenerates it. |
| F333 | breaking-change detection against the base branch in CI | `.github/workflows/api-contract.yml:44` — `uses: oasdiff/oasdiff-action/breaking@v0.1.6` | — | py-only | — | WEB-51; runs only when `docs/api/openapi.json` changes in a PR. |
| F334 | contract fuzzing generates cases for every documented operation | `tests/web/test_contract.py:30` — `case.call_and_validate(checks=(not_a_server_error,))` | — | py-only | — | WEB-50; schemathesis, marked `slow` so the default `pytest` run skips it. |
| F335 | typed client generation from the committed snapshot, never hand-written | `Justfile:312` — `uvx openapi-python-client generate --path docs/api/openapi.json ...` | — | py-only | — | WEB-60. |
| F336 | production container image is a non-root multi-stage build | `Dockerfile:13` — `uv sync --frozen --no-install-project --no-dev --extra web` then `Dockerfile:21` — `USER app` | — | py-only | — | WEB-32; lockfile-frozen, bytecode-compiled, dependency layer cached separately from source. |
| F337 | container declares its own liveness healthcheck | `Dockerfile:29` — `HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \` | — | py-only | — | Probes `/healthz` via `urllib` since the slim base image has no `curl`. |
| F338 | production entrypoint runs the ASGI server with settings-driven graceful shutdown | `src/py_launch_blueprint/web/__main__.py:37` — `uvicorn.run(` using `src/py_launch_blueprint/web/__main__.py:42` — `timeout_graceful_shutdown=settings.graceful_shutdown_seconds,` | — | py-only | — | WEB-31; `python -m py_launch_blueprint.web`, no CLI flags — every knob is an env var. |
| F339 | dev server recipe runs with auto-reload and pretty console logs | `Justfile:291` — `serve host="127.0.0.1" port="8000":` | — | py-only | — | Defaults `_LOG_FORMAT` to `console` (prod default is JSON) — dev/prod logging-profile split. |
| — | web test suite (incl. slow contract fuzzing) is a separate opt-in command | `Justfile:300` — `@test-web *options:` | — | py-only | — | Keeps the default `just test`/`pytest` run fast; CI and this recipe both opt into the `slow` marker; see F130 |
| F340 | importing the web package without the extra installed raises an actionable error | `src/py_launch_blueprint/web/__init__.py:49` — `if exc.name and exc.name.split(".")[0] in {"fastapi", "starlette"}:` | — | py-only | — | Reports the exact `pip install '...[web]'` / `uv sync --extra web` fix instead of a bare `ModuleNotFoundError`. |

## Language-bound tools
- `fastapi` (py) — the web framework: routing, dependency injection, OpenAPI generation
- `uvicorn` (py) — the ASGI server that runs the app, dev-reload and production alike
- `pydantic-settings` (py) — typed, env-var-driven `WebSettings` (WEB-30)
- `fastapi-pagination` (py) — the `page`/`size` collection-pagination envelope (WEB-03)
- `slowapi` (py) — app-wide rate limiting, off by default (WEB-22)
- `prometheus-fastapi-instrumentator` (py) — RED metrics at `/metrics` (WEB-11)
- `opentelemetry-sdk` / `opentelemetry-instrumentation-fastapi` (py) — opt-in distributed tracing behind the `otel` extra (WEB-10)
- `schemathesis` (py) — OpenAPI-schema-driven contract fuzzing (WEB-50)
- `oasdiff` (py) — breaking-change detection between OpenAPI snapshots, run as a GitHub Action
- `openapi-python-client` (py) — typed Python client generation from the committed snapshot (WEB-60)
- `httpx` (py) — FastAPI `TestClient` transport for the web test suite

## Cross-area parameters
- `error-taxonomy-exit-codes` — the `ERROR_STATUS` domain-error-to-HTTP-status table mirrors the `PyError`/`ExitCode` hierarchy decided in the CLI area; this area only adds the HTTP mapping on top.
- `python-version-floor` — the Dockerfile's `python:3.12-slim-bookworm` runtime stage and the `uv:python3.12-bookworm-slim` builder stage follow the Python-version floor set by the runtime/toolchain area, not decided here.
- `ci-job-structure` — whether the breaking-change gate is its own workflow file (`api-contract.yml`, py's choice) versus a step folded into a shared job follows the CI topic's overall job layout, not decided in this area.

## Files read
- py: `docs/adr/0013-web-service-best-practices.md`
- py: `docs/design/0002-web-api-conventions.md`
- py: `docs/source/web/index.md`
- py: `pyproject.toml`
- py: `src/py_launch_blueprint/web/__init__.py`
- py: `src/py_launch_blueprint/web/app.py`
- py: `src/py_launch_blueprint/web/deps.py`
- py: `src/py_launch_blueprint/web/idempotency.py`
- py: `src/py_launch_blueprint/web/logging.py`
- py: `src/py_launch_blueprint/web/middleware.py`
- py: `src/py_launch_blueprint/web/problems.py`
- py: `src/py_launch_blueprint/web/settings.py`
- py: `src/py_launch_blueprint/web/telemetry.py`
- py: `src/py_launch_blueprint/web/versioning.py`
- py: `src/py_launch_blueprint/web/__main__.py`
- py: `src/py_launch_blueprint/web/routers/__init__.py`
- py: `src/py_launch_blueprint/web/routers/projects.py`
- py: `tests/web/test_contract.py`
- py: `tests/web/test_openapi_snapshot.py`
- py: `tests/web/conftest.py` — no feature: fixture wiring only, no new WEB-numbered convention beyond what app.py/settings.py already cover
- py: `tests/web/test_app.py` — no feature: exercises rows already cited from app.py/problems.py, no new citable behavior
- py: `tests/web/test_idempotency.py` — no feature: exercises the idempotency.py row already cited
- py: `tests/web/test_logging.py` — no feature: exercises the logging.py row already cited
- py: `tests/web/test_settings.py` — no feature: exercises the settings.py row already cited
- py: `tests/web/test_versioning.py` — no feature: exercises the versioning.py row already cited
- py: `Justfile`
- py: `Dockerfile`
- py: `.github/workflows/api-contract.yml`
- py: `docs/api/openapi.json` — no feature: the committed artifact itself, cited from the snapshot-staleness row; contains no new decisions to report
- ts: `package.json` — no feature: no web/HTTP-framework dependency present
- ts: `tests/api.test.ts` — no feature: an outbound API-client test (mocked `fetchImpl`), not a web server
- ts: `docs/port/TS_PORT_DECISIONS.md` — no feature: no decision entry addresses web-service scope; the module is absent and unindexed in TS_PORT_INDEX.md
