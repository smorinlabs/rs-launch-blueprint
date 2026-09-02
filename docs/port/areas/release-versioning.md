# Area: release-versioning

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| id | feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|---|
| F063 | version source of truth | `pyproject.toml:23` — literal `[project] version`, release-please-managed | `package.json:3` — literal `version` field, release-please-managed | same | D-021(1) | py release-type is python, ts release-type is node; Cargo.toml's `[package] version` is the direct, uncontested Rust manifest field — no alternative to research |
| F064 | runtime version accessor | `src/py_launch_blueprint/__init__.py:24` — `importlib.metadata.version()` reads installed metadata | `src/version.ts:6` — imports `package.json` JSON, bundler inlines at build | different | D-021(2) | py resolves at runtime; ts resolves at build time |
| — | version consistency test suite | `tests/meta/test_version_consistency.py:56` — asserts pyproject == manifest == uv.lock == installed | `tests/version.test.ts:11` — asserts VERSION == package.json == lib re-export | same | — | py checks 4 sources incl. lockfile; ts checks 3; see testing-coverage (same test, cited there as test_version_consistency.py:58/version.test.ts:12) |
| F065 | lockfile version sync in release commit | `release-please-config.json:16` — extra-files jsonpath bumps `uv.lock` editable-root version | `.github/workflows/release-please.yml:27` — comment: pnpm-lock.yaml has no root version field, no sync needed | different | — | py lockfile encodes the version, ts pnpm lockfile does not; Cargo.lock does encode workspace-member versions, like uv.lock |
| F066 | changelog file generation | `release-please-config.json:22` — release-please writes `CHANGELOG.md` from commit history | `release-please-config.json:11` — release-please writes `CHANGELOG.md` from commit history | same | D-021(3) | — |
| F067 | changelog section type mapping (visible vs hidden) | `release-please-config.json:23` — feat/fix/perf/refactor/revert/deps visible, chore/docs/style/test/ci/build hidden | `release-please-config.json:12` — feat/fix/perf/docs/test/refactor visible, chore hidden | different | D-021(3) | ts surfaces docs/test/refactor sections that py hides |
| F068 | changelog file preamble | — | `CHANGELOG.md:5` — names Keep a Changelog and Semantic Versioning conventions | ts-only | — | py `CHANGELOG.md:1` is a bare `# Changelog` header with no description |
| F069 | release PR title customization | `release-please-config.json:4` — overrides pattern, adds "review and merge to ship to PyPI" | `release-please-config.json:8` — overrides pattern to `chore(release): publish v${version}` | same | — | wording differs; ts drops the registry-name suffix; the pattern (a customized PR title) is language-neutral release-please config, the exact wording is a content choice at execution time, not a research question |
| F070 | pre-1.0 semver bump strategy | — | `release-please-config.json:6` — `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` set true | ts-only | D-021(1) | ts is pre-1.0 (0.1.3); py is post-1.0 (2.4.2) |
| F071 | release-please bootstrap-sha pin | `release-please-config.json:3` — pins the commit release-please starts scanning from | — | py-only | — | — |
| F072 | release-please auth token mechanism | `.github/workflows/release-please.yml:45` — GitHub App token via create-github-app-token, PAT fallback, never GITHUB_TOKEN | `.github/workflows/release-please.yml:69` — same App-token-then-PAT-fallback pattern | same | D-021(1) | — |
| F073 | release trigger (push opens PR, merge tags) | `.github/workflows/release-please.yml:20` — push to `main` opens/updates the Release PR | `.github/workflows/release-please.yml:38` — push to `main` opens the Release PR, plus `workflow_dispatch` | same | D-021(1) | ts adds a manual `workflow_dispatch` re-trigger py lacks |
| F074 | publish workflow tag/version consistency guard | `.github/workflows/publish.yml:39` — tag reachable from main, tag == pyproject version | `.github/workflows/publish.yml:73` — tag reachable from main, tag == package.json == manifest | same | D-021(5), D-022(13) | ts checks a 3-way match, py checks a 2-way match |
| F075 | OIDC Trusted Publishing (no stored publish token) | `.github/workflows/publish.yml:86` — `uv publish --trusted-publishing always` under `id-token: write` | `.github/workflows/publish.yml:208` — `npm publish` under `id-token: write` | same | D-021(5) | — |
| F076 | staged publish to test registry before production | `.github/workflows/publish.yml:69` — `publish-testpypi` job runs before `publish-pypi` job | — | py-only | — | npm has no equivalent staging registry in this flow; OMIT — crates.io has no test/staging registry, `cargo publish --dry-run` never uploads |
| F077 | protected environment gate before publish | `.github/workflows/publish.yml:73` — `environment: testpypi` / `environment: pypi` | `.github/workflows/publish.yml:150` — `environment: npm`, required reviewers | same | D-021(5) | — |
| F078 | packed-artifact content guard in publish workflow | — | `.github/workflows/publish.yml:199` — fails the publish job if npm auto-corrects the `bin` field | ts-only | D-021(5) | — |
| — | local packaging validation recipe | — | `Justfile:276` — `pack-check`: build, publint, attw, `npm pack --dry-run`, install smoke test | ts-only | D-012(7) | — see packaging-distribution (same `pack-check` recipe reported there against its CI-wiring cadence) |
| F079 | release version-surface drift-check recipe | — | `Justfile:249` — `release-status`: compares package.json, manifest, latest `v*` tag | ts-only | D-021(1) | py has no equivalent recipe; low-stakes diagnostic mirroring F074's already-decided consistency check, nothing to research |
| F080 | CLI version-check recipe | `Justfile:360` — `version` recipe runs the installed `{{cmd}} --version` | `Justfile:234` — `version` recipe runs `node dist/cli.js --version` | same | — | citation corrected: ts's file is `Justfile` (capital J), not `justfile` — confirmed via `git ls-files` |
| F081 | release runbook / setup doc | `docs/RELEASE.md:6` — default flow, token setup, first-release cutover steps | `docs/maintainers-release.md:5` — one-time setup checklist plus routine flow | same | — | ts doc is marked "Stub — expanded in the docs slice" |
| F082 | documented opt-out from automated releases | `docs/RELEASE.md:19` — rename the workflow file, then hand-bump version and tag manually | — | py-only | — | — |

## Language-bound tools
- `uv publish` (py) — OIDC Trusted Publishing upload to TestPyPI/PyPI in `publish.yml`
- `npm publish` (ts) — OIDC Trusted Publishing upload to the npm registry in `publish.yml`, chosen over `pnpm publish` for OIDC reliability
- `importlib.metadata` (py) — stdlib runtime lookup of the installed package version
- `tsdown` (ts) — bundler that inlines `package.json`'s version into `src/version.ts` at build time
- `publint` / `@arethetypeswrong/cli` (ts) — packaging-surface validators run by the `pack-check` Justfile recipe

## Cross-area parameters
- `node-version-floor` — the publish workflow's npm-Trusted-Publishing prerequisite (npm >=11.5.1 bundled with Node 24) is set by the runtime/toolchain area, not decided here
- `package-manager-choice` — `publish.yml`'s use of `pnpm install`/`pnpm run build` before a plain `npm publish` depends on the package-manager tie-break decided elsewhere (D-035 per workflow comments)
- `build-tool-output-shape` — `version.ts` being inlined "by the bundler" depends on the build/packaging area's tool choice (tsdown, D-012)
- `commit-message-convention` — release-please's Conventional-Commits scan depends on the git-hooks/commitlint area enforcing that convention on `main`

## Files read
- py: `pyproject.toml`
- py: `release-please-config.json`
- py: `.release-please-manifest.json`
- py: `CHANGELOG.md`
- py: `.github/workflows/release-please.yml`
- py: `.github/workflows/publish.yml`
- py: `docs/RELEASE.md`
- py: `docs/source/about/design_decisions.md`
- py: `docs/adr/README.md`
- py: `docs/adr/0007-did-you-mean-stdlib-difflib.md` — no feature: opened only to confirm the ADR-05/06/07 numbering scheme referenced elsewhere is historical, not in this index
- py: `src/py_launch_blueprint/__init__.py`
- py: `src/py_launch_blueprint/cli/main.py` — no feature: grep confirmed `__version__` is echoed by `--version`, not independently cited
- py: `src/py_launch_blueprint/core/diagnostics.py` — no feature: grep confirmed `__version__` usage in diagnostics output, not independently cited
- py: `src/py_launch_blueprint/web/app.py` — no feature: grep confirmed `__version__` usage in web startup/health output, not independently cited
- py: `tests/meta/test_version_consistency.py`
- py: `Justfile`
- ts: `docs/port/TS_PORT_DECISIONS.md`
- ts: `docs/port/TS_PORT_RESEARCH.md` — no feature: corroborating context for D-021(1)'s pre-1.0 bump-strategy rationale, not itself cited
- ts: `package.json`
- ts: `release-please-config.json`
- ts: `.release-please-manifest.json`
- ts: `.github/workflows/release-please.yml`
- ts: `.github/workflows/publish.yml`
- ts: `src/version.ts`
- ts: `tests/version.test.ts`
- ts: `CHANGELOG.md`
- ts: `Justfile`
- ts: `docs/reference/versioning.md`
- ts: `docs/maintainers-release.md`
