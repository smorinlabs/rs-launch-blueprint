# Area: lint-format

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| id | feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|---|
| F083 | one linter and one formatter run in CI and via the git-hook manager | `Justfile:200` — ruff format/check run via just, lefthook, CI | `Justfile:102` — oxfmt/oxlint run via just, lefthook, CI | same | — | Pattern carried over; tool choice differs (see next two rows). |
| F084 | primary code formatter tool | `Justfile:203` — `ruff format` formats Python via `uv run` | `Justfile:105` — `oxfmt` formats TS/JS via `pnpm exec` | different | D-014(1) | Oxfmt is beta (0.59.0), exact-pinned per package.json; bundle — rustfmt's own config surface (F087, F089, F091, F092) is only worth researching once this row picks rustfmt |
| F085 | primary code linter tool | `Justfile:228` — `ruff check` lints Python via `uv run` | `Justfile:123` — `oxlint` lints TS/JS via `pnpm exec` | different | D-014(1) | Oxlint 1.x stable, caret-pinned; bundle — clippy's own config surface (F086, F093, F094, F096) is only worth researching once this row picks clippy |
| F086 | linter rule-selection mechanism | `pyproject.toml:150` — `lint.select` lists rule-category codes (E, F, I…) | `.oxlintrc.json:15` — `categories` + explicit `plugins`/`rules` lists | different | D-014(1) | Category+plugin model replaces ruff's flat code-prefix list; bundle with F085 |
| F087 | formatter max line width | `pyproject.toml:148` — `line-length = 88` | `.oxfmtrc.json:6` — `printWidth: 100` | different | D-014(2) | 88 is a Python norm; 100 reuses org Prettier/Biome precedent; bundle with F084 (rustfmt's `max_width`) |
| F088 | formatter quote style | `pyproject.toml:207` — `quote-style = "double"` | `.oxfmtrc.json:7` — `singleQuote: true` | different | D-014(2) | Opposite quote convention, not merely a value change; OMIT — Rust string literals are always double-quoted, no formatter option exists |
| F089 | formatter line-ending normalization | `pyproject.toml:209` — `line-ending = "auto"` (detects existing) | `.oxfmtrc.json:10` — `endOfLine: "lf"` (fixed) | different | D-014(2) | py auto-detects per file; ts fixes LF unconditionally; bundle with F084 (rustfmt's `newline_style`) |
| F090 | formatter semicolon insertion | — | `.oxfmtrc.json:8` — `semi: true` inserts statement-terminating semicolons | ts-only | D-014(2) | Python has no semicolon-terminated statements; OMIT — Rust's grammar requires statement-terminating semicolons, there is no formatter option because it is not optional |
| F091 | formatter trailing-comma style | — | `.oxfmtrc.json:9` — `trailingComma: "es5"` controls comma insertion | ts-only | D-014(2) | Ruff's formatter has no configurable trailing-comma option; bundle with F084 (rustfmt's `trailing_comma`) |
| F092 | import-sorting ownership | `pyproject.toml:153` — `"I"` isort selected as a lint rule | `.oxfmtrc.json:13` — `sortImports: true` is a formatter option | different | D-014(3) | Same intent (import order), owned by different tool category; bundle with F084 (rustfmt's `reorder_imports`/`imports_granularity`) |
| F093 | linter default autofix behavior | `pyproject.toml:177` — `fix = true` makes autofix the default | `Justfile:130` — `--fix` flag needed; `lint` runs check-only | different | — | py's `just lint` autofixes by default; ts's does not; bundle with F085 |
| F094 | per-context lint relaxation for test files | `pyproject.toml:195` — `per-file-ignores` for `"tests/*"` (S101, ANN…) | `.oxlintrc.json:52` — `overrides` files globs for `tests/**` | different | D-014(4) | Structural equivalent: per-file-ignores vs. overrides array; bundle with F085 (clippy's `#[allow]`/module-level lint config for test code) |
| F095 | per-file ignore for package `__init__.py` | `pyproject.toml:194` — `__init__.py` exempted from unused-import rule F401 | — | py-only | — | ts has no package `__init__.py` file concept; OMIT — Rust's `mod.rs`/`lib.rs` re-export surface has no equivalent unused-import exemption need |
| F096 | security-rule coverage via the linter | `pyproject.toml:161` — `"S"` selects flake8-bandit rule set | `.oxlintrc.json:35` — built-in rules (`no-eval` etc.), no bandit analog | different | D-014(5) | Coverage in ts is layered with a separate CodeQL workflow; bundle with F085 |
| F097 | TOML formatter as a separate tool | `.taplo.toml:23` — `taplo` formats/checks TOML, wired to hooks + CI | — | py-only | D-014(6) | No `.toml` files are tracked in the ts repo at all; ts's own D-014(6) omits taplo only because no `.toml` survived the port, not because Oxfmt was configured for it — verified: `.oxfmtrc.json` has no TOML-specific setting and ts carries zero `.toml` files, so origin stays py-only; bundle with F098/F099 — Rust's own config files (Cargo.toml, rustfmt.toml, etc.) make TOML formatting directly relevant, decided jointly with YAML/JSON/Markdown coverage |
| F098 | YAML formatting ownership | `.yamlfmt:1` — `yamlfmt` config exists; not wired to hooks/CI | `lefthook.yml:24` — `oxfmt` formats YAML, included in hook glob | different | D-014(7) | py's yamlfmt is configured but unenforced; ts's is enforced; bundle with F097/F099 |
| F099 | JSON and Markdown formatting coverage | — | `lefthook.yml:24` — `oxfmt` formats JSON/Markdown, included in hook glob | ts-only | D-014(7) | py has no formatter for these formats in this repo; bundle with F097/F098 |
| F100 | formatter/linter exclude-list configuration scope | `pyproject.toml:180` — one `[tool.ruff] exclude` shared by lint+format | `.oxlintrc.json:69` — separate `ignorePatterns` per tool config file | different | — | ts also sets `ignorePatterns` in `.oxfmtrc.json:17`; whether Rust shares one exclude list across rustfmt/clippy or keeps them per-tool |
| — | full hook suite re-run against all files | `Justfile:354` — `hooks-run` recipe exists; not called from CI | `.github/workflows/ci.yml:106` — `lefthook run pre-commit --all-files` runs in CI | different | D-022(1) | ts wires the recipe into CI as a dual-enforcement step; see F174 (same feature as ci-workflows' PA'd "Full pre-commit/lefthook hook suite re-run against all files inside CI") |
| F101 | editor extension recommendation for lint/format | `.vscode/extensions.json:5` — recommends `charliermarsh.ruff` | `.vscode/extensions.json:3` — recommends `oxc.oxc-vscode` | different | D-024(4) | Both are the sole lint/format extension in their list; low-stakes but origin `different` forces DIVERGENT rather than ADOPT per the verdict table |
| F102 | composite recipe bundling format/lint/typecheck/test | `Justfile:277` — `check` composite: lint (no format-check) + others | `Justfile:178` — `all` composite: format-check + lint + typecheck + test | different | D-024(1) | py's `check` composite omits a format-check step; ts's includes one |
| F103 | lint/format tool version-pinning strategy | `pyproject.toml:78` — `ruff>=0.1.0` floating range, pinned via `uv.lock` | `package.json:55` — `oxfmt` exact-pinned, `oxlint` caret range, `pnpm-lock.yaml` | different | D-014(1) | Oxfmt's beta status is why it alone is exact-pinned; Cargo.toml supports the same floating-range-vs-exact-pin choice |
| F104 | pre-commit formatter hook mode (check vs. write) | `lefthook.yml:114` — `ruff format --check` blocks the commit, no rewrite | `lefthook.yml:32` — `oxfmt` writes fixes; `stage_fixed: true` re-stages them | different | D-020(6) | py's hook fails on unformatted code; ts's fixes and proceeds |

## Language-bound tools
- `ruff` (py) — combined linter + formatter for Python, invoked via `ruff check`/`ruff format`
- `taplo` (py) — standalone TOML formatter/checker, wired into hooks/CI
- `yamlfmt` (py) — standalone YAML formatter, configured but not enforced in hooks/CI
- `oxlint` (ts) — linter for TypeScript/JavaScript
- `oxfmt` (ts) — formatter for TS/JS plus JSON/YAML/Markdown

## Cross-area parameters
- `package-manager-invocation` — Justfile recipes prefix tool calls with `uv run` (py) or `pnpm exec` (ts); the package-manager choice itself belongs to a separate topic.
- `git-hooks-manager` — lint/format run as staged-file jobs inside `lefthook.yml` in both repos; choosing lefthook over the source's pre-commit framework is decided by the git-hooks topic (D-020).
- `toml-file-survival` — whether the ts repo carries any `.toml` files at all (and so whether TOML formatting matters) followed from its release-tooling choice: release-please (`COMMONALITY.md` F063/F066, `COMMON → REUSE`) replaced the source's cog.toml, so ts carries no `.toml` file; for Rust the question is moot because `Cargo.toml` always exists (F097).
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
