# Area: static-analysis

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|
| primary type-checker tool | `Justfile:237` — `uv run --extra web ty check {{py_package_path}}/` | `Justfile:137` — `pnpm run typecheck`; `package.json:33` — `"typecheck": "tsc --noEmit"` | different | D-015(1) | ty replaces the source's mypy as the CI-authoritative checker. |
| type-checker hook-tier placement | `lefthook.yml:166` `lefthook.yml:167` — `ty` runs at `pre-push` only (full-tree scan judged too slow per-commit, ADR-0018) | `lefthook.yml:60` `lefthook.yml:61` — `tsc --noEmit` runs at `pre-commit`, every commit | different | D-020(6) | py deliberately keeps its type checker out of pre-commit; ts deliberately puts it in. |
| single type-checker engine serving both CI and the editor | — | `tsconfig.json:30` — `noEmit: true`, one config typechecks CI and the editor language service; `.vscode/settings.json:2` — `typescript.tsdk` pins the editor to the workspace `typescript` package so both stay on the same engine | ts-only | D-015(2), D-032 | py's structural counterpart is a second, IDE-only checker (next row), not a single-engine design. |
| dedicated IDE-only type checker distinct from the CI-authoritative one | `pyproject.toml:214` `pyproject.toml:218` — `[tool.pyright]` `typeCheckingMode = "strict"`, drives the editor extension and ad-hoc runs; not invoked in CI | — | py-only | D-015(2) | ts's D-015(2) explicitly omits this second-engine pattern, closed instead by the tsdk pin above. |
| type-checker editor-extension recommendation | `.vscode/extensions.json:4` — `ms-python.vscode-pylance` recommended for the IDE-only pyright checker | — | py-only | — | ts's TypeScript language service ships built into VS Code; no extension is recommended for it. |
| type-checker opt-in quality-rule / strictness configuration | `pyproject.toml:254` `pyproject.toml:258` — `[tool.ty.rules]` promotes named rules (`ambiguous-protocol-member`, `ineffective-final`, …) to `error` atop ty's default-error core | `tsconfig.json:11` `tsconfig.json:18` — `strict: true` plus an explicit flag union (`noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, …) | different | D-013(2) | ty is rule-based (named opt-ins); tsc is flag-based (boolean strictness knobs). |
| type-checker suppression-comment discipline | `pyproject.toml:255` `pyproject.toml:256` `pyproject.toml:257` — `blanket-ignore-comment`/`invalid-ignore-comment`/`ignore-comment-unknown-rule` all `= "error"`: every `# ty: ignore` must name its rule | — | py-only | — | ts has no configured `@ts-expect-error`/`@ts-ignore` linting convention. |
| type-checker warning-vs-error severity tier | `pyproject.toml:263` — `[tool.ty.terminal]` `error-on-warning = false`: warnings (e.g. a `deprecated` use) inform without failing the gate | — | py-only | — | `tsc --noEmit` has no separate warning tier; every diagnostic it reports fails the gate. |
| type-check gate scope: whether tests are included | `Justfile:237` `lefthook.yml:167` — `ty check {{py_package_path}}/` / `ty check src/py_launch_blueprint/`, scoped to `src/` only; `tests/` is excluded from the CI-authoritative gate | `tsconfig.json:32` — `"include"` lists `src/**/*.ts` and `tests/**/*.ts` together | different | D-013(4) | D-013(4) frames this as fixing "under-checking of tests"; py's `tests/` coverage exists only in the non-gating pyright config (`pyproject.toml:215`). |
| dead-code detection: unused imports, variables, and arguments | `pyproject.toml:152` — `"F"` selects the pyflakes rule family (covers unused imports/variables) | `.oxlintrc.json:23` `.oxlintrc.json:30` — `no-unused-vars` with `argsIgnorePattern`/`varsIgnorePattern`/`caughtErrorsIgnorePattern` set to `"^_"` | different | D-013(2), D-015(2) | D-013(2) delegates unused-code detection to the T04 linter rather than tsconfig; py's is a rule-category default with no configured ignore-prefix. |
| type-annotation-presence enforcement via the linter | `pyproject.toml:162` — `"ANN"` selects flake8-annotations, enforcing annotation *presence* (not just correctness) | — | py-only | — | ts's structural typing makes explicit annotations optional; no linter rule mandates them. |
| dedicated AST-based security scanner beyond the linter's built-in security rules | `.github/workflows/lint.yml:114` — `uv run --no-sync bandit -r src/py_launch_blueprint/ -c pyproject.toml`; `pyproject.toml:267` — `[tool.bandit]` `exclude_dirs`/`skips` config | — | py-only | D-014(5) | D-014(5) records that ts has no bandit-equivalent tool; its security coverage is oxlint built-ins plus CodeQL only. |
| security scanner hook-tier placement | `lefthook.yml:160` `lefthook.yml:161` — `bandit` runs at `pre-push` (full-tree scan, too slow per-commit — same tier rationale as `ty`) | — | py-only | — | No ts hook runs a dedicated security scanner; ts has none to place. |
| architectural-boundary check hook-tier placement | `lefthook.yml:171` `lefthook.yml:172` — `import-linter` (`lint-imports`) at `pre-push`; `lefthook.yml:176` `lefthook.yml:177` — `tach check` at `pre-push`, both added per ADR-0018 as a local mirror of the CI `import-boundaries` job | — | py-only | — | ts has no architectural-boundary tool at any tier (see the workspace-architecture area for the boundary-enforcement mechanism itself). |

## Language-bound tools
- `ty` (py) — CI-authoritative type checker, also run as a pre-push hook mirror
- `pyright` (py) — IDE-only second type checker (Pylance extension), strict mode, not run in CI
- `bandit` (py) — dedicated AST-based security scanner, run at pre-push and in a separate CI job
- `ruff` (py) — supplies dead-code (`F`) and annotation-presence (`ANN`) diagnostics as linter rule families
- `tsc` (ts) — sole type checker, serving both CI/pre-commit and the editor via one `tsconfig.json`
- `oxlint` (ts) — supplies dead-code detection (`no-unused-vars`) as a linter rule; carries no annotation-presence or security-scanner equivalent

## Cross-area parameters
- `git-hooks-manager` — the pre-commit/pre-push tier split for type-checking and security scanning is expressed inside `lefthook.yml`, whose manager choice (lefthook) is decided by the git-hooks topic (D-020)
- `ci-job-structure` — whether the type checker, boundary checks, and bandit run as their own CI job versus a folded-in step is decided by the CI topic (D-022)
- `python-version-floor` — `[tool.ty.environment]`'s `python-version = "3.12"` (`pyproject.toml:251`) pins ty's target version to the floor set by the runtime/toolchain area, not decided here
- `node-version-floor` — `tsconfig.json`'s `target: "ES2022"` (`tsconfig.json:5`) is gated on a future Node-floor bump owned by the runtime/toolchain area, not decided here

## Files read
- py: `pyproject.toml`
- py: `Justfile`
- py: `lefthook.yml`
- py: `.vscode/extensions.json`
- py: `.github/workflows/lint.yml`
- py: `docs/adr/0018-hook-ci-parity-and-boundary-gate.md`
- py: `pyrightconfig.json` — no feature: file no longer exists at b08bccf, folded into `pyproject.toml`'s `[tool.pyright]` (confirmed via `git log --all -- pyrightconfig.json`)
- ts: `tsconfig.json`
- ts: `.oxlintrc.json`
- ts: `Justfile`
- ts: `lefthook.yml`
- ts: `package.json`
- ts: `.vscode/settings.json`
- ts: `.vscode/extensions.json` — no feature: no type-checker or security-scanner extension listed, supports the py-only extension-recommendation row
- ts: `docs/port/TS_PORT_DECISIONS.md`
- ts: `docs/port/TS_PORT_INDEX.md` — no feature: read for mypy/pyright pre-port history context only, not cited as a row (`b08bccf`'s live gate is ty, confirmed separately)
