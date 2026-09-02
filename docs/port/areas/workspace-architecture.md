# Area: workspace-architecture

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|
| Ports abstraction for the driven I/O seam | `src/py_launch_blueprint/core/ports.py:40` — `ProjectsRepository(Protocol)`, structurally satisfied by adapters | `src/router.ts:31` — `CliDeps` interface: individually typed I/O functions injected directly, no port+adapter split | different | — | py separates port (contract) from adapter (impl) from service (use-case); ts injects concrete function values straight into the CLI router |
| Composition root wiring a port to a concrete adapter | `src/py_launch_blueprint/composition.py:36` — `build_projects_service()` binds `PyApiProjectsRepository` to `ProjectsService` | `src/router.ts:55` — `realDeps()` builds production `CliDeps` directly (function values, no swappable backend) | different | — | py's root exists to swap a live adapter for a fake at one seam; ts's `realDeps()` has no alternate business-logic backend to swap, only test-time replacement of the same functions |
| Composition root importable only by front-ends, never by core | `pyproject.toml:334` — import-linter `forbidden` contract: `core` may not import `py_launch_blueprint.composition` (HEX-04) | — | py-only | — | prevents the composition root's concrete-adapter imports from creating a circular-import risk back into `core` |
| Core forbidden from importing the front-ends (inward-only dependency direction) | `pyproject.toml:323` — import-linter `forbidden` contract: `core` may not import `cli` or `web` (HEX-01) | — | py-only | — | ts has no core/front-end split to enforce; `cli.ts`/`router.ts` sit directly on `lib/` with no reverse-import rule needed |
| Front-ends (CLI, web) forbidden from importing each other | `pyproject.toml:329` — import-linter `independence` contract: `cli` and `web` are independent | — | py-only | — | ts ships only one front-end (the CLI), so there is no second front-end to isolate from |
| Core internal layering (domain models below services below adapters) | `pyproject.toml:340` — import-linter `layers` contract: `core.adapters` > `core.services` > `core.models` (HEX-01) | — | py-only | — | ts's `lib/` has no declared internal layer order between `api.ts`, `config.ts`, `errors.ts`, `format.ts` |
| Architectural boundaries enforced mechanically rather than by convention | `docs/adr/0017-hexagonal-core-and-boundary-enforcement.md:29` — decision to enforce ports-and-adapters boundaries with import-linter/tach/ruff/ty rather than review discipline | — | py-only | — | ts relies on code review and the port's decisions log; no CI/hook gate checks module-boundary violations |
| Framework-bleed guard, authoritative (core may not import CLI/web frameworks) | `pyproject.toml:349` — import-linter `forbidden` contract: `core` may not import `fastapi`, `click`, `uvicorn` (HEX-32) | — | py-only | — | graph-wide, runs at `just check` + pre-push per ADR-0018 |
| Framework-bleed guard, fast local mirror | `src/py_launch_blueprint/core/ruff.toml:13` — `ruff` `TID251` banned-api bans `click`/`fastapi`/`uvicorn` imports scoped to `core/`, at pre-commit speed | — | py-only | — | deliberately duplicates the import-linter contract above at a cheaper CI stage (design 0005 HEX-32) |
| Bounded-context module dependency graph, declared and checked | `tach.toml:19` — `[[modules]]` blocks declare `core`/`composition`/`cli`/`web` `depends_on` edges, checked by `tach check` (HEX-31) | — | py-only | — | one bounded context today, so it mostly restates the import-linter contracts; no `[[interfaces]]` strict-surface block configured yet |
| Adapter satisfies a port structurally, verified by the type checker | `pyproject.toml:253` — `ty` (`[tool.ty.rules]`) type-checks `core/`, verifying `PyApiProjectsRepository`/`InMemoryProjectsRepository` satisfy `ProjectsRepository` without inheritance (HEX-33) | — | py-only | — | ts's structural typing is a language default applied to `CliDeps`, not a chosen ports-verification step |
| Port absence-vs-failure contract (`None`/empty means absent; exception means transport broke) | `src/py_launch_blueprint/core/ports.py:47` — `get_project`/`resolve_workspace_gid` return `... | None`; `src/py_launch_blueprint/core/services/projects.py:56` — the service turns `None` into `ProjectNotFoundError` | `src/lib/api.ts:182` — `createApiClient`'s `getProjects` resolves the workspace and throws `NotFoundError` inline, in the same function that does the HTTP call | different | — | py splits "is it there" (adapter) from "is absence an error" (service, HEX-12); ts's single API-client function does both in one place |
| First-class in-memory/fake adapter shipped in the package (not test-only) | `src/py_launch_blueprint/core/adapters/in_memory.py:20` — `InMemoryProjectsRepository` ships in `core/adapters/`, used by both tests and demos (HEX-41) | — | py-only | — | ts's tests construct fake `CliDeps` values inline in `tests/*.test.ts`; no shipped fake lives under `src/` |
| Public library API surface, curated re-export list | `src/py_launch_blueprint/core/__init__.py:61` — `__all__` lists the package's public names, re-exported from `core/config.py`, `core/models.py`, etc. | `src/lib.ts:5` — root barrel file re-exports the stable public surface from `lib/api.ts`, `lib/config.ts`, `lib/errors.ts`, `lib/format.ts` | same | D-012 | both curate one file that is the only sanctioned import surface for consumers, cited "the only stable API surface" in `lib.ts:1-3` |
| Public-surface enforcement mechanism | `docs/design/0005-hexagonal-architecture-and-enforcement.md:298` — `__all__` "documents, it does not enforce" (HEX-34); nothing blocks a deep import of an internal module | `package.json:24` — `exports` map declares `.` as the only importable path (`types`+`default` to `dist/lib.js`); Node's module resolution refuses any other subpath | different | D-012 | py's convention is IDE/lint-visible only; ts's `exports` map is mechanically enforced by the Node/npm resolver at import time |
| Sync/async execution model for the I/O boundary | `src/py_launch_blueprint/core/adapters/py_api.py:38` — `import requests` (blocking); `src/py_launch_blueprint/web/routers/projects.py:25` — "Handlers are sync (``def``) because ``ProjectsService`` uses ``requests``; FastAPI runs them in its threadpool" | `src/router.ts:182` — `export async function runCli` and `src/lib/api.ts:108` — `async function request` wrap the injected `fetch`; the whole call chain from CLI entry to HTTP is `Promise`-based | different | — | py is sync end-to-end, with the web layer bridging into async FastAPI via its threadpool; ts is async end-to-end with no sync core to bridge |
| Web service as an optional, separately installed capability | `pyproject.toml:56` — `[project.optional-dependencies] web = ["fastapi>=0.110.0", "uvicorn[standard]>=0.29.0", ...]`, installed via `uv sync --extra web`; core/CLI stay dependency-free of it | — | py-only | — | ts has no web/HTTP-server capability at all (confirmed: no express/fastify/hono in `package.json`); a CLI-only install has nothing to opt out of |
| Web layer as a thin adapter reusing the CLI's data contract | `docs/adr/0013-web-service-best-practices.md:21` — the web layer "must stay a *thin adapter* over `py_launch_blueprint.core` (one data contract shared with the CLI)" | — | py-only | — | follows from having a web front-end at all; no ts counterpart exists to compare |
| Source code lives under a top-level `src/` directory | `pyproject.toml:141` — `module-root = "src"` ("src/ layout (Decision 1)") | `tsconfig.json:32` — `"include": ["src/**/*.ts", ...]` | same | — | both repos chose `src/`, rejecting a flat repo-root package layout |
| Package namespacing within `src/` | `pyproject.toml:139` — `module-name = "py_launch_blueprint"`, sources nested at `src/py_launch_blueprint/...` | `src/cli.ts:1` — source files sit directly under `src/`, no package-name subdirectory | different | — | py nests one more directory level (importable as `py_launch_blueprint.core...`); ts's flat files are the whole `src/` tree |

## Language-bound tools
- `import-linter` (py) — authoritative, graph-wide layer/independence/framework-bleed contracts (HEX-30)
- `tach` (py) — bounded-context module dependency graph + (future) strict public-interface checks (HEX-31)
- `ruff` TID251 (py) — fast pre-commit framework-bleed guard scoped to `core/` (HEX-32)
- `ty` (py) — verifies adapters structurally satisfy `Protocol` ports (HEX-33)
- `typing.Protocol` (py) — the port-definition mechanism itself
- `oxlint` (ts) — general lint gate; loads the `import` plugin but has no boundary/restricted-path rules configured
- Node module resolution / `package.json` `exports` (ts) — mechanically enforces the public-surface-only import contract

## Cross-area parameters
- `error-taxonomy-exit-codes` — the absence-vs-failure port contract (`None`→service raises vs. inline throw) feeds each language's error-to-exit-code mapping, decided elsewhere
- `http-transport-injection-seam` — both `ProjectsRepository`'s adapter and `CliDeps.fetchImpl` are the seam that a testing/CLI-vs-web area would inject fakes through

## Files read
- py: `docs/adr/0017-hexagonal-core-and-boundary-enforcement.md`
- py: `docs/adr/0018-hook-ci-parity-and-boundary-gate.md` — no feature: CI/hook parity mechanics, not module/package boundaries themselves (reaffirms HEX-30/31 already cited from 0017/pyproject.toml)
- py: `docs/adr/0013-web-service-best-practices.md`
- py: `docs/design/0005-hexagonal-architecture-and-enforcement.md`
- py: `pyproject.toml`
- py: `tach.toml`
- py: `src/py_launch_blueprint/core/ruff.toml`
- py: `src/py_launch_blueprint/__init__.py` — no feature: only exposes `__version__`, not the curated public surface (that is `core/__init__.py`)
- py: `src/py_launch_blueprint/core/__init__.py`
- py: `src/py_launch_blueprint/core/ports.py`
- py: `src/py_launch_blueprint/core/services/projects.py`
- py: `src/py_launch_blueprint/core/adapters/py_api.py`
- py: `src/py_launch_blueprint/core/adapters/in_memory.py`
- py: `src/py_launch_blueprint/composition.py`
- py: `src/py_launch_blueprint/web/deps.py`
- py: `src/py_launch_blueprint/web/routers/projects.py`
- py: `src/py_launch_blueprint/cli/commands/projects.py`
- ts: `docs/port/TS_PORT_DECISIONS.md`
- ts: `package.json`
- ts: `tsconfig.json`
- ts: `.oxlintrc.json` — no feature: confirms no import-boundary rules configured, supports several py-only rows
- ts: `src/lib.ts`
- ts: `src/cli.ts`
- ts: `src/router.ts`
- ts: `src/lib/adapters.ts`
- ts: `src/lib/api.ts`
- ts: `tests/` directory listing (`tests/*.test.ts` filenames only) — no feature: confirms no shipped in-package fake adapter, only inline test fakes
