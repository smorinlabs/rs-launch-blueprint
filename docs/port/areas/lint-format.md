# Area: lint-format

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|
| one linter and one formatter run in CI and via the git-hook manager | `Justfile:200` — ruff format/check run via just, lefthook, CI | `Justfile:102` — oxfmt/oxlint run via just, lefthook, CI | same | — | Pattern carried over; tool choice differs (see next two rows). |
| primary code formatter tool | `Justfile:203` — `ruff format` formats Python via `uv run` | `Justfile:105` — `oxfmt` formats TS/JS via `pnpm exec` | different | D-014(1) | Oxfmt is beta (0.59.0), exact-pinned per package.json. |
| primary code linter tool | `Justfile:228` — `ruff check` lints Python via `uv run` | `Justfile:123` — `oxlint` lints TS/JS via `pnpm exec` | different | D-014(1) | Oxlint 1.x stable, caret-pinned. |
| linter rule-selection mechanism | `pyproject.toml:150` — `lint.select` lists rule-category codes (E, F, I…) | `.oxlintrc.json:15` — `categories` + explicit `plugins`/`rules` lists | different | D-014(1) | Category+plugin model replaces ruff's flat code-prefix list. |
| formatter max line width | `pyproject.toml:148` — `line-length = 88` | `.oxfmtrc.json:6` — `printWidth: 100` | different | D-014(2) | 88 is a Python norm; 100 reuses org Prettier/Biome precedent. |
| formatter quote style | `pyproject.toml:207` — `quote-style = "double"` | `.oxfmtrc.json:7` — `singleQuote: true` | different | D-014(2) | Opposite quote convention, not merely a value change. |
| formatter line-ending normalization | `pyproject.toml:209` — `line-ending = "auto"` (detects existing) | `.oxfmtrc.json:10` — `endOfLine: "lf"` (fixed) | different | D-014(2) | py auto-detects per file; ts fixes LF unconditionally. |
| formatter semicolon insertion | — | `.oxfmtrc.json:8` — `semi: true` inserts statement-terminating semicolons | ts-only | D-014(2) | Python has no semicolon-terminated statements. |
| formatter trailing-comma style | — | `.oxfmtrc.json:9` — `trailingComma: "es5"` controls comma insertion | ts-only | D-014(2) | Ruff's formatter has no configurable trailing-comma option. |
| import-sorting ownership | `pyproject.toml:153` — `"I"` isort selected as a lint rule | `.oxfmtrc.json:13` — `sortImports: true` is a formatter option | different | D-014(3) | Same intent (import order), owned by different tool category. |
| linter default autofix behavior | `pyproject.toml:177` — `fix = true` makes autofix the default | `Justfile:130` — `--fix` flag needed; `lint` runs check-only | different | — | py's `just lint` autofixes by default; ts's does not. |
| per-context lint relaxation for test files | `pyproject.toml:195` — `per-file-ignores` for `"tests/*"` (S101, ANN…) | `.oxlintrc.json:52` — `overrides` files globs for `tests/**` | different | D-014(4) | Structural equivalent: per-file-ignores vs. overrides array. |
| per-file ignore for package `__init__.py` | `pyproject.toml:194` — `__init__.py` exempted from unused-import rule F401 | — | py-only | — | ts has no package `__init__.py` file concept. |
| security-rule coverage via the linter | `pyproject.toml:161` — `"S"` selects flake8-bandit rule set | `.oxlintrc.json:35` — built-in rules (`no-eval` etc.), no bandit analog | different | D-014(5) | Coverage in ts is layered with a separate CodeQL workflow. |
| TOML formatter as a separate tool | `.taplo.toml:23` — `taplo` formats/checks TOML, wired to hooks + CI | — | py-only | D-014(6) | No `.toml` files are tracked in the ts repo at all. |
| YAML formatting ownership | `.yamlfmt:1` — `yamlfmt` config exists; not wired to hooks/CI | `lefthook.yml:24` — `oxfmt` formats YAML, included in hook glob | different | D-014(7) | py's yamlfmt is configured but unenforced; ts's is enforced. |
| JSON and Markdown formatting coverage | — | `lefthook.yml:24` — `oxfmt` formats JSON/Markdown, included in hook glob | ts-only | D-014(7) | py has no formatter for these formats in this repo. |
| formatter/linter exclude-list configuration scope | `pyproject.toml:180` — one `[tool.ruff] exclude` shared by lint+format | `.oxlintrc.json:69` — separate `ignorePatterns` per tool config file | different | — | ts also sets `ignorePatterns` in `.oxfmtrc.json:17`. |
| full hook suite re-run against all files | `Justfile:354` — `hooks-run` recipe exists; not called from CI | `.github/workflows/ci.yml:106` — `lefthook run pre-commit --all-files` runs in CI | different | D-022(1) | ts wires the recipe into CI as a dual-enforcement step. |
| editor extension recommendation for lint/format | `.vscode/extensions.json:5` — recommends `charliermarsh.ruff` | `.vscode/extensions.json:3` — recommends `oxc.oxc-vscode` | different | D-024(4) | Both are the sole lint/format extension in their list. |
| composite recipe bundling format/lint/typecheck/test | `Justfile:277` — `check` composite: lint (no format-check) + others | `Justfile:178` — `all` composite: format-check + lint + typecheck + test | different | D-024(1) | py's `check` composite omits a format-check step; ts's includes one. |
| lint/format tool version-pinning strategy | `pyproject.toml:78` — `ruff>=0.1.0` floating range, pinned via `uv.lock` | `package.json:55` — `oxfmt` exact-pinned, `oxlint` caret range, `pnpm-lock.yaml` | different | D-014(1) | Oxfmt's beta status is why it alone is exact-pinned. |
| pre-commit formatter hook mode (check vs. write) | `lefthook.yml:114` — `ruff format --check` blocks the commit, no rewrite | `lefthook.yml:32` — `oxfmt` writes fixes; `stage_fixed: true` re-stages them | different | D-020(6) | py's hook fails on unformatted code; ts's fixes and proceeds. |

## Language-bound tools
- `ruff` (py) — combined linter + formatter for Python, invoked via `ruff check`/`ruff format`
- `taplo` (py) — standalone TOML formatter/checker, wired into hooks/CI
- `yamlfmt` (py) — standalone YAML formatter, configured but not enforced in hooks/CI
- `oxlint` (ts) — linter for TypeScript/JavaScript
- `oxfmt` (ts) — formatter for TS/JS plus JSON/YAML/Markdown

## Cross-area parameters
- `package-manager-invocation` — Justfile recipes prefix tool calls with `uv run` (py) or `pnpm exec` (ts); the package-manager choice itself belongs to a separate topic.
- `git-hooks-manager` — lint/format run as staged-file jobs inside `lefthook.yml` in both repos; choosing lefthook over the source's pre-commit framework is decided by the git-hooks topic (D-020).
- `toml-file-survival` — whether the ts repo carries any `.toml` files at all (and so whether TOML formatting matters) is a consequence of the release-tooling topic's cog.toml keep/drop decision.
- `ci-job-structure` — py splits lint checks across two workflow files (`ci.yml`, `lint.yml`); ts runs them as sequential steps inside one job; overall workflow layout is decided by the CI topic (D-022).

## Files read
- py: `pyproject.toml`
- py: `Justfile`
- py: `lefthook.yml`
- py: `.taplo.toml`
- py: `.yamlfmt`
- py: `.github/workflows/ci.yml`
- py: `.github/workflows/lint.yml` — no feature: covers yamllint/actionlint/codespell/editorconfig-checker, outside this area's code lint/format scope
- py: `.vscode/extensions.json`
- ts: `.oxfmtrc.json`
- ts: `.oxlintrc.json`
- ts: `Justfile`
- ts: `lefthook.yml`
- ts: `package.json`
- ts: `.github/workflows/ci.yml`
- ts: `.vscode/extensions.json`
- ts: `docs/port/TS_PORT_DECISIONS.md`
