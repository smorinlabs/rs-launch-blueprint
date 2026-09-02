# Area: testing-coverage

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|
| test runner tool | `Justfile:260` — `uv run pytest {{options}}` via `just test` | `Justfile:144` — `pnpm exec vitest run {{options}}` via `just test` | different | D-019(1) | pytest replaced by Vitest 4, not a pytest-compatible runner. |
| CLI test tiers (in-process vs. built-binary) | `tests/cli/test_pylb.py:9` — single tier, Click `CliRunner` in-process only | `tests/cli-core.test.ts:11` — in-process `runCli(argv,deps)` tier; `tests/e2e.test.ts:94` — added subprocess tier spawning built `dist/cli.js` | different | D-019(4) | py has no subprocess/built-binary CLI test tier at all. |
| mock/test-double library | `tests/cli/test_pylb.py:6` — stdlib `unittest.mock` (`Mock`, `patch`) | `tests/cli.test.ts:12` — Vitest built-in `vi.fn`/`vi.mock` | different | D-019(5) | Same DI-and-spy pattern, framework-native tool differs. |
| HTTP transport mocking mechanism in tests | `tests/core/test_py_api_repository.py:104` — `@responses.activate` intercepts real HTTP calls | `tests/api.test.ts:27` — `fetchImpl` passed as a plain fake function, no interception library | different | D-019(5) | ts needs no HTTP-mock library because the transport is DI-injected; see cross-area `http-transport-injection-seam`. |
| port-contract substitutability suite (fake vs. real adapter parity) | `tests/core/test_projects_repository_contract.py:70` — `@pytest.fixture(params=["in_memory", "py_api"])` runs every test against both adapters (HEX-40) | — | py-only | — | No TS_PORT_DECISIONS entry addresses carrying this pattern over. |
| property-based (generative) testing | `tests/core/test_properties.py:24` — Hypothesis `@given` round-trip tests (WL-013) | — | py-only | — | No decision entry addresses omitting Hypothesis/fast-check. |
| CLI golden-snapshot testing | `tests/cli/test_help_snapshots.py:36` — syrupy `assert result.output == snapshot` for every `--help` (WL-023) | — | py-only | — | No `.ambr`-equivalent or `toMatchSnapshot` use found in ts tests. |
| randomized test execution order | `pyproject.toml:99` — `pytest-randomly` reorders every run with a replayable seed (WL-010) | — | py-only | — | Vitest has no built-in equivalent configured. |
| per-test timeout enforcement | `pyproject.toml:284` — `timeout = 60` (`pytest-timeout`, thread method, WL-009) | — | py-only | — | No custom `testTimeout` set in `vitest.config.ts`. |
| scheduled dependency-freshness canary run | `.github/workflows/canary.yml:16` — weekly cron; `.github/workflows/canary.yml:47` — `uv sync --upgrade` (WL-012) | — | py-only | — | ts has no `canary.yml` or equivalent scheduled workflow. |
| advisory alternate JS runtime test lane | — | `Justfile:169` — `bun run vitest run --exclude tests/e2e.test.ts`, non-gating (D-036) | ts-only | D-036 | Node stays the required runtime; Bun is a forward-compat signal only. |
| shared cross-test fixture file (autouse setup) | `tests/conftest.py:16` — `@pytest.fixture(autouse=True)` resets root logger for every test | — | py-only | D-019(5) | ts deliberately uses local factory helpers instead of a global setup file. |
| test file organization (subdirected vs. flat) | `Justfile:301` — `test-web` targets the `tests/web` subdir; suite also splits into `tests/{cli,core,meta}/` | `tests/api.test.ts:4` — flat `tests/*.test.ts`, no subdirectories | different | D-019(2) | py mirrors `src/` layer boundaries in subdirs; ts is 7 flat files. |
| opt-in test marker taxonomy (skip slow/live by default) | `pyproject.toml:277` — `markers = ["live: ...", "slow: ..."]`; `pyproject.toml:278` — `addopts` excludes both by default | — | py-only | — | No tag/marker system in the ts suite; tiering is by file (see CLI-tiers row). |
| opt-in parallel test execution flag | `pyproject.toml:97` — `pytest-xdist>=3.6`, `-n auto` opt-in (WL-008) | — | py-only | — | Vitest parallelizes test files by default; no equivalent opt-in flag exists to cite. |
| test asserting the version stays single-sourced across manifests | `tests/meta/test_version_consistency.py:58` — `pyproject.toml`/manifest/`uv.lock` versions must match | `tests/version.test.ts:12` — `VERSION` must equal `package.json`'s version | same | D-021(2) | Same self-consistency-guard pattern; manifest set differs per ecosystem. |
| coverage tool | `pyproject.toml:76` — `pytest-cov>=4.1.0` (wraps `coverage.py`) | `package.json:53` — `@vitest/coverage-v8` | different | D-019(1) | — |
| coverage instrumentation scope and exclusions | `Justfile:267` — `--cov=py_launch_blueprint`, no per-file omit list configured | `vitest.config.ts:10` — `include: ['src/**/*.ts']`; `vitest.config.ts:19` — `exclude` two thin I/O-adapter files | different | D-019(3) | ts explicitly excludes files it judges not unit-coverable; py excludes none. |
| coverage threshold definition location and values | `.codecov.yml:14` — `target: auto` (project); `.codecov.yml:18` — `target: 80%` (patch) | `vitest.config.ts:20` — in-repo `thresholds`: 95/95/90/95 lines/fn/branch/stmt | different | D-019(3) | py's gate lives in an external service config; ts's lives in the test-runner config itself. |
| coverage gate enforcement in CI | `.github/workflows/ci.yml:193` — `codecov-action` uploads and the external Codecov check blocks the PR | `.github/workflows/ci.yml:95` — `run: just test` (no `--coverage`); the Codecov-upload step is commented out | different | D-022(1) | ts's coverage thresholds are configured but not currently run or enforced in CI. |
| coverage report output formats | `Justfile:267` — `--cov-report=term-missing --cov-report=html --cov-report=xml` | — | py-only | — | ts's `test:coverage` script takes Vitest's default reporters with no explicit selection. |
| OpenAPI contract snapshot test | `tests/web/test_openapi_snapshot.py:19` — asserts the generated OpenAPI spec matches the committed `docs/api/openapi.json` (WEB-51) | — | py-only | — | Depends on cross-area `web-extra-surface`; ts carries no web/API surface to snapshot. |
| API contract fuzz-testing tool | `tests/web/test_contract.py:14` — `schemathesis` fuzzes routes from the OpenAPI schema (WEB-50) | — | py-only | — | Same `web-extra-surface` dependency as the row above. |
| meta-tests validating tooling-config internal consistency | `tests/meta/test_justfile.py:24` — asserts a Justfile recipe's shelled-out command stays correct | `tests/repo-hygiene.test.ts:34` — asserts commitlint/`.gitmessage` type lists stay consistent | same | — | Same pattern (a test suite that guards the repo's own config files), different scope per repo. |

## Language-bound tools
- `pytest` (py) — test runner, invoked via `just test`
- `pytest-cov` (py) — coverage collection plugin wrapping `coverage.py`
- `pytest-xdist` (py) — parallel worker execution, opt-in via `-n auto`
- `pytest-timeout` (py) — per-test timeout enforcement
- `pytest-randomly` (py) — randomized test ordering
- `hypothesis` (py) — property-based test generation
- `responses` (py) — HTTP call interception/mocking
- `syrupy` (py) — snapshot-testing plugin for CLI `--help` golden files
- `schemathesis` (py) — OpenAPI-schema-driven contract fuzzing
- `unittest.mock` (py) — stdlib mocking (`Mock`/`patch`)
- `vitest` (ts) — test runner and assertion/mock framework, invoked via `just test`
- `@vitest/coverage-v8` (ts) — coverage collection using V8's native coverage

## Cross-area parameters
- `http-transport-injection-seam` — both repos' `HTTP transport mocking mechanism in tests` row depends on the injected-fetch/adapter seam decided by the CLI-framework/architecture topic.
- `web-extra-surface` — the OpenAPI snapshot test and the schemathesis contract-fuzzing row exist only because py carries an optional web surface; whether ts carries an equivalent is decided outside this area.
- `ci-job-structure` — where the coverage-producing test step sits in the CI job graph (single matrix cell for py, single job for ts) is decided by the CI topic, not here.
- `build-tool-output-shape` — the ts e2e subprocess tier spawns `dist/cli.js`; that build output's location and shape are decided by the build/packaging area.

## Files read
- py: `pyproject.toml`
- py: `Justfile`
- py: `.codecov.yml`
- py: `docs/adr/0019-testing-strategy-and-tooling.md`
- py: `.github/workflows/ci.yml`
- py: `.github/workflows/canary.yml`
- py: `tests/conftest.py`
- py: `tests/cli/test_pylb.py`
- py: `tests/cli/test_output.py` — no feature: mocks a subprocess pager call, not a CLI subprocess test tier
- py: `tests/cli/test_help_snapshots.py`
- py: `tests/core/test_properties.py`
- py: `tests/core/test_projects_repository_contract.py`
- py: `tests/core/test_py_api_repository.py`
- py: `tests/web/test_openapi_snapshot.py`
- py: `tests/web/test_contract.py`
- py: `tests/test_guard.py` — no feature: subprocess-driven bash-script test, not a CLI test tier
- py: `tests/meta/test_justfile.py`
- py: `tests/meta/test_version_consistency.py`
- ts: `package.json`
- ts: `vitest.config.ts`
- ts: `Justfile`
- ts: `.github/workflows/ci.yml`
- ts: `tests/cli-core.test.ts`
- ts: `tests/e2e.test.ts`
- ts: `tests/cli.test.ts`
- ts: `tests/api.test.ts`
- ts: `tests/config.test.ts` — no feature: config-loading tests, already covered by other rows' citations
- ts: `tests/version.test.ts`
- ts: `tests/repo-hygiene.test.ts`
- ts: `docs/port/TS_PORT_DECISIONS.md`
