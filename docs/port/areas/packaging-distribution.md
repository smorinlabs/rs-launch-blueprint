# Area: packaging-distribution

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|
| build backend tool | `pyproject.toml:133` — `build-backend = "uv_build"` (PEP 517) | `tsdown.config.ts:8` — `defineConfig({...})` bundler config | same | D-012(1) | tsdown is tsup's designated successor per D-012(1) rationale |
| build entry-point declaration | `pyproject.toml:139` `pyproject.toml:141` — `module-name`/`module-root` point at one package root | `tsdown.config.ts:9` — `entry: ['src/cli.ts', 'src/lib.ts']` lists two explicit entries | different | D-012(1) | py's whole package is one build unit; ts bundles CLI and library as separate entries |
| distributable artifact types | `.github/workflows/ci.yml:216` — `uv build` produces sdist + wheel | `package.json:23` — `"type": "module"`, single ESM npm tarball | different | — | py ships two PyPI artifact formats; ts ships one npm package format |
| dual CJS/ESM vs ESM-only output | — | `tsdown.config.ts:10` — `format: 'esm'` (no CJS build) | ts-only | D-012(2) | Python packaging has no CJS/ESM axis |
| console-script / bin entry declaration | `pyproject.toml:120` — `plbp = "py_launch_blueprint.cli.main:cli"` (module:function ref) | `package.json:18` — `"ts-projects": "dist/cli.js"` (built file path) | different | D-012(3) | py references a callable; ts references a bundled output file |
| CLI executable invocation mechanism | `pyproject.toml:120` — build backend generates a wrapper script from the `[project.scripts]` entry | `tsdown.config.ts:3` — shebang in `src/cli.ts` is preserved by tsdown, output made executable | different | D-012(1) | wrapper-generation vs shebang-preservation |
| public library export surface declaration | — | `package.json:25` `package.json:29` — hand-authored exports map (`.` + `./package.json`), not tsdown's auto-generation | ts-only | D-012(3) | Python has no `exports`-map equivalent; the whole importable package is public |
| packaged-file whitelist mechanism | `pyproject.toml:139` `pyproject.toml:141` — `module-name`/`module-root` implicitly bounds wheel content | `package.json:20` `package.json:22` — explicit `"files": ["dist"]` array | different | D-012(3) | py's layout setting doubles as the content boundary; ts uses a dedicated whitelist field |
| runtime/build toolchain version pin file | `.python-version:1` — literal `3.12` | `.nvmrc:1` — literal `24` | same | D-011(3) | both are read by CI setup actions and local version managers |
| distribution-name vs entry-point-name divergence | `README.md:45` — `uvx --from py-launch-blueprint plbp` (needed since distribution name ≠ script name) | `package.json:2` `package.json:18` — name `ts-launch-blueprint` differs from bin `ts-projects`; no special flag needed | different | — | npm's global/bin install has no per-name lookup step the way uvx does |
| documented end-user install method | `README.md:45` — `uvx --from py-launch-blueprint plbp` or `pip install py-launch-blueprint && plbp` | — | py-only | — | ts's README documents only clone-and-build-from-source, not an npm install line |
| CI-wired build-and-install smoke test cadence | `.github/workflows/ci.yml:204` — `build-smoke` job runs on every code-touching PR | `Justfile:276` — `pack-check` recipe exists but is not invoked from `ci.yml` | different | — | py gates every PR on an install smoke test; ts's equivalent recipe is local-only |
| ephemeral wheel/sdist install-and-run smoke test | `.github/workflows/ci.yml:222` — `uvx --from "$(ls dist/*.whl)" plbp --version` | — | py-only | — | uvx installs the just-built artifact into a throwaway env and runs it |
| container image as a distribution artifact | `Dockerfile:6` — multi-stage `uv sync` build producing a runnable web-service image | — | py-only | — | tied to py's optional `web` extra; see `web-extra-surface` |

## Language-bound tools
- `uv_build` (py) — PEP 517 build backend that produces the sdist and wheel from `[tool.uv.build-backend]` config
- `tsdown` (ts) — rolldown-based bundler that produces the publishable `dist/` output (CLI + library, dts, sourcemaps)
- `uvx` (py) — pipx-style ephemeral tool runner used both for the documented end-user install command and the CI wheel/sdist smoke test
- `twine` (py) — validates built sdist/wheel metadata in the `build-smoke` CI job

## Cross-area parameters
- `package-manager-choice` — pnpm's self-pin/enforcement fields (`.npmrc`, `package.json`'s `packageManager`) are decided by the package-manager topic, not here; this area only consumes pnpm to run the build.
- `release-tooling-choice` — the publish workflow's registry auth (OIDC), staged TestPyPI step, and tag/version guard live in `publish.yml` but are decided by the release-versioning topic; this area covers only the build backend and artifact/entry-point surface that workflow packages.
- `node-version-floor` — `.nvmrc`'s value (`24`) reflects, but is not itself the source of, the runtime-floor decision (D-011(2)) that also sets the npm-CLI version needed for Trusted Publishing.
- `web-extra-surface` — whether a container-image artifact exists at all depends on whether the ported project carries an equivalent optional web surface, decided outside this area.

## Files read
- py: `pyproject.toml`
- py: `README.md`
- py: `Dockerfile`
- py: `.python-version`
- py: `.pypirc.template` — no feature: manual-publish token fallback belongs to the release-versioning topic
- py: `Justfile`
- py: `release-please-config.json` — no feature: version/changelog config belongs to the release-versioning topic
- py: `.release-please-manifest.json` — no feature: belongs to the release-versioning topic
- py: `.github/workflows/publish.yml` — no feature: registry auth/staging/tag-guard rows already covered by the release-versioning area
- py: `.github/workflows/ci.yml`
- py: `src/py_launch_blueprint/__init__.py` — no feature: confirmed `__version__` source, owned by the release-versioning topic
- py: `src/py_launch_blueprint/cli/main.py` — no feature: confirmed `--version` echoes `__version__`, not independently cited here

- ts: `package.json`
- ts: `tsdown.config.ts`
- ts: `.nvmrc`
- ts: `.npmrc` — no feature: pnpm self-pin/enforcement belongs to the `package-manager-choice` cross-area topic
- ts: `Justfile`
- ts: `README.md` — no feature: confirmed no documented npm-install line for end users
- ts: `src/cli.ts` — no feature: confirmed the shebang line the `tsdown.config.ts:3` comment describes
- ts: `src/version.ts` — no feature: version-accessor mechanism belongs to the release-versioning topic
- ts: `release-please-config.json` — no feature: belongs to the release-versioning topic
- ts: `.release-please-manifest.json` — no feature: belongs to the release-versioning topic
- ts: `.github/workflows/publish.yml` — no feature: registry auth/staging/tag-guard rows already covered by the release-versioning area
- ts: `.github/workflows/ci.yml` — no feature: confirmed `pack-check` is not invoked from this workflow
- ts: `docs/port/TS_PORT_DECISIONS.md`
