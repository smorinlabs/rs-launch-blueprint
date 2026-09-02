# Area: git-hooks-commit-hygiene

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| id | feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|
| F142 | git hook manager tool | `lefthook.yml:68` — `pre-commit:` stage configured in lefthook's YAML schema | `lefthook.yml:9` — `pre-commit:` stage configured in lefthook's YAML schema | same | — | D-020(1) frames lefthook as replacing a `.pre-commit-config.yaml`/pre-commit-framework source, but py already runs lefthook at this pinned commit — no such file exists in py at b08bccf; both repos use the same manager now. |
| F143 | lefthook distribution/install mechanism | `scripts/install-lefthook.sh:13` (version pin), `scripts/install-lefthook.sh:35` — global `bun install -g lefthook@2.1.8`, pinned outside the package manager | `package.json:54` — `lefthook` listed as a `^2.1.10` devDependency, installed by `pnpm install` | different | D-020(1) | py's main package manager (uv) never installs lefthook; it goes through a separate Bun-based installer script. |
| F144 | hook-wiring trigger mechanism | `scripts/install-lefthook.sh:46` — `lefthook install` run explicitly inside `just setup`'s hook-toolchain step | `package.json:36` — `"prepare": "lefthook install"` auto-runs on every `pnpm install` | different | D-020(1) | ts wires hooks into the package manager's own lifecycle; py requires running the project's setup command. |
| F145 | manual hook re-wire recipe | `Justfile:349` — `hooks-install` recipe runs `lefthook install` | `Justfile:223` — `setup-hooks` recipe runs `pnpm exec lefthook install` | same | — | Both also expose an explicit just recipe as a fallback to the automatic/setup-time wiring. |
| F146 | pre-commit stage jobs execute in parallel | `lefthook.yml:69` — `parallel: true` under `pre-commit:` | `lefthook.yml:10` — `parallel: true` under `pre-commit:` | same | — | — |
| F147 | hook staging tiering (fast staged checks at commit, slower full-tree checks deferred later) | `lefthook.yml:11`,`lefthook.yml:12` — comment: "fast staged-scoped checks at pre-commit; slower full-tree checks at pre-push" | `lefthook.yml:70` — comment: tests run "at the push boundary, NOT per commit" to protect contributor DX | same | D-020(3), D-020(6) | Same tiering philosophy; which checks land in which tier differs per check (see F106 for type-check placement and F115 for security-scanner placement). |
| F148 | commit-message linting enforced at commit-msg hook time (pattern) | `lefthook.yml:62` — `commit-msg:` stage configured in lefthook's YAML schema | `lefthook.yml:63` — `commit-msg:` stage configured in lefthook's YAML schema | same | D-020(2) | Pattern row for the split below; the tool implementing it is commitlint in both repos. |
| F149 | commit-msg linter tool | `lefthook.yml:65` — `commit-msg:` job runs `bun ./node_modules/@commitlint/cli/cli.js` | `lefthook.yml:68` — `commit-msg:` job runs `pnpm exec commitlint` | same | D-020(2) | — |
| F150 | commit-msg hook invocation mechanism | `lefthook.yml:65` — explicit path through Bun (`bun ./node_modules/@commitlint/cli/cli.js --edit {1}`), avoiding PATH/script fallback | `lefthook.yml:68` — `pnpm exec commitlint --edit {1}` (package-manager-resolved binary) | different | — | py's own comments (`lefthook.yml:18-58`) document three prior silent-pass failure modes that motivated the explicit-path form; ts uses the plain package-manager-exec form. |
| F151 | commitlint base config | `commitlint.config.mjs:15` — `extends: ['@commitlint/config-conventional']` | `commitlint.config.mjs:26` — `extends: ['@commitlint/config-conventional']` | same | D-020(2) | Both layer repo-specific rule overrides on the same upstream config. |
| F152 | commit subject (header) max length override | — | `commitlint.config.mjs:29` — `'header-max-length': [2, 'always', 50]` | ts-only | D-020(2) | py never overrides `header-max-length` in `commitlint.config.mjs` (inherits config-conventional's 100-char default), unlike the 50/72 contract D-020(2) attributes to the source. |
| F153 | commit body max line-length override | `commitlint.config.mjs:17` — `'body-max-line-length': [2, 'always', 200]` | `commitlint.config.mjs:30` — `'body-max-line-length': [2, 'always', 72]` | different | D-020(2) | py raises the default cap (for doc URLs/permalinks); ts lowers it to a stricter 72-char wrap. |
| F154 | commit footer max line-length override | `commitlint.config.mjs:18` — `'footer-max-line-length': [2, 'always', 200]` | — | py-only | — | ts leaves `footer-max-line-length` at config-conventional's 100-char default. |
| F155 | commit type-enum restriction | — | `commitlint.config.mjs:28` — `'type-enum': [2, 'always', types]` using the explicit 11-entry `types` array (`feat`…`revert`, defined at `commitlint.config.mjs:11`) | ts-only | D-020(2) | py leaves `type-enum` at config-conventional's default type list (same 11 members ts lists explicitly); ts's explicit list is kept in lockstep with `.gitmessage` by a dedicated test, which py has no file to reconcile against. |
| F156 | per-author relaxed commit-lint ruleset for bot PRs | `commitlint.dependabot.config.mjs:16` — separate config disables `body-max-line-length`/`footer-max-line-length` for dependabot | — | py-only | — | Selected in CI by PR-author login, not applicable without ts's equivalent CI job. |
| F157 | commit-message linting re-run in CI (beyond the local hook) | `.github/workflows/commitlint.yml:45` — `wagoid/commitlint-github-action@v6.2.1` on every push/PR | — | py-only | — | ts enforces Conventional Commits only via the local `commit-msg` hook; `--no-verify` bypasses it with nothing in CI to catch it. |
| F158 | commit-message template file | — | `.gitmessage:1` — `<type>: <description>` template documenting the 50/72 contract and type list | ts-only | D-020(4) | D-020(4) describes "keeping" a source `.gitmessage`, but no such file exists in py at this pinned commit. |
| F159 | commit-message template wired via git config | — | `Justfile:224` — `setup-hooks` recipe runs `git config commit.template .gitmessage` | ts-only | D-020(4) | — |
| F160 | commit-message template/commitlint type-list consistency, enforced by test | — | `tests/repo-hygiene.test.ts:19` — asserts `.gitmessage`'s `# Types:` line equals `commitlintConfig`'s `type-enum` array | ts-only | D-020(4) | — |
| F161 | lefthook config internal-consistency, enforced by test | — | `tests/repo-hygiene.test.ts:46` — asserts `lefthook.yml` parses and carries `pre-commit`/`commit-msg` keys | ts-only | — | py has no meta-test reading `lefthook.yml` itself. |
| F162 | lefthook per-job exclude-list mirrors the linter/formatter ignore config, enforced by test | — | `tests/repo-hygiene.test.ts:81` — asserts `format`/`lint` job `exclude` sets equal `.oxfmtrc.json`/`.oxlintrc.json` `ignorePatterns` | ts-only | — | Guards against a tool exiting non-zero when every staged path it receives is ignore-listed. |
| F163 | staged secret-scanning hook | `lefthook.yml:73` — `gitleaks` job runs `scripts/check-gitleaks.sh --staged` on every commit | — | py-only | — | ts has no secret-scanning tool at any git-hook tier. |
| F164 | pre-push range secret-scanning hook | `lefthook.yml:156` — `gitleaks-range` job runs `scripts/check-gitleaks.sh --range`, scanning the about-to-be-pushed commit range | — | py-only | — | Catches secrets in commits that bypassed the staged hook (imported history, `--no-verify`). |
| F165 | secret-scanner allowlist configuration | `.gitleaks.toml:10` — `[allowlist]` narrows by path (docs/Markdown) and two named AWS example-key regexes | — | py-only | — | — |
| F166 | secret-scanner fingerprint suppression file | `.gitleaksignore:1` — per-finding fingerprint allowlist, empty at this commit | — | py-only | — | Distinct from the pattern/path allowlist in `.gitleaks.toml`. |
| F167 | whitespace/EOL/format-validity hygiene linter (pre-commit) | `lefthook.yml:82` — `editorconfig-checker` job runs `uv run ec -config .editorconfig-checker.json` on staged files | — | py-only | — | ts folds trailing-whitespace/EOF-newline fixing into the oxfmt formatter job instead of a separate validity linter (see F084). |
| F168 | YAML lint hook | `lefthook.yml:88` — `yamllint` job runs `uv run yamllint -c .yamllint {staged_files}` | — | py-only | — | Distinct from YAML formatting (owned by lint-format.md); this is structural/style linting, not reformatting. |
| F169 | spell-check hook | `lefthook.yml:102` — `codespell` job runs `uv run codespell --toml pyproject.toml {staged_files}` | — | py-only | — | — |
| F170 | GitHub Actions workflow syntax lint hook | `lefthook.yml:99` — `actionlint` job runs `actionlint {staged_files}` on staged workflow files | — | py-only | — | ts's Justfile only prints an optional-tool install hint for actionlint (`Justfile:83`); it is never wired into any hook or CI job. |
| F171 | dependency-manifest lockfile-freshness check hook | `lefthook.yml:131` — `uv-lock-check` job runs `uv lock --check` when `pyproject.toml`/`uv.lock` are staged | — | py-only | — | Catches an un-relocked dependency change before the push round-trip. |
| F172 | large-file size guard hook | `lefthook.yml:137`,`lefthook.yml:143` — `large-files` job rejects staged files over `1048576` bytes (1 MB), exempting `docs/assets/*` | `lefthook.yml:42` — `check-large-files` job rejects staged files over `512000` bytes (500 KB), no path exemption | different | D-020(6) | Different threshold (1 MB vs 500 KB) and py additionally carves out an assets-directory exemption ts does not have. |
| F173 | full test-suite execution as a git hook | — | `lefthook.yml:78` — `pre-push` `test` job runs `just test`, opt-in via `TS_PROJECTS_PREPUSH_TESTS=1`, default skip | ts-only | D-020(3) | D-020(3) frames this as *moving* the source's pytest-in-pre-commit hook to an opt-in pre-push hook, but py's `lefthook.yml` at this commit runs no general test-suite hook at either tier to move from (its narrower `openapi-snapshot` pre-push job runs one targeted test file only). |
| F174 | CI job aggregating every hook-suite check for full-tree dual enforcement | — | `.github/workflows/ci.yml:106` — `pnpm exec lefthook run pre-commit --all-files` step inside the `ci` job | ts-only | D-022(1) | py's hook↔CI parity is per-check instead (ADR 0018's table maps each tool to its own CI job, see `docs/adr/0018-hook-ci-parity-and-boundary-gate.md`); ts re-runs the literal hook suite as one CI step. |
| F175 | local recipe to re-run the pre-commit hook suite against the whole tree | `Justfile:353` — `hooks-run` recipe: `lefthook run pre-commit --all-files` | `Justfile:220` — inlined inside `ci` recipe: `pnpm exec lefthook run pre-commit --all-files` | same | — | Same underlying lefthook invocation; ts's is folded into its `just ci` recipe rather than exposed as its own aliased recipe. |

## Language-bound tools
- `lefthook` (py) — hook manager, installed globally via a Bun-based installer script
- `lefthook` (ts) — hook manager, installed as a pnpm devDependency
- `gitleaks` (py) — staged-diff and push-range secret scanner, run at pre-commit and pre-push
- `commitlint` (py) — commit-message linter, invoked at commit-msg via an explicit Bun-run binary path
- `commitlint` (ts) — commit-message linter, invoked at commit-msg via `pnpm exec`
- `wagoid/commitlint-github-action` (py) — GitHub Action re-running commitlint in CI, split by PR-author identity
- `editorconfig-checker` (py) — staged whitespace/EOL/format-validity linter, pre-commit hook
- `yamllint` (py) — staged YAML structural linter, pre-commit hook
- `codespell` (py) — staged spell-check linter, pre-commit hook
- `actionlint` (py) — staged GitHub Actions workflow syntax linter, pre-commit hook

## Cross-area parameters
- `package-manager-invocation` — the commit-msg hook's `bun`/`pnpm exec` prefix and the pre-commit `uv run`/`pnpm exec` prefixes on individual jobs follow the package-manager choice decided elsewhere.
- `ci-job-structure` — whether a check appears as its own CI job (py's per-tool `lint.yml`/`commitlint.yml` jobs) versus a step folded into one job (ts's single `ci` job) is decided by the CI topic (D-022), not here; this area only reports which checks exist and where they run locally.
- `web-extra-surface` — the narrow `openapi-snapshot` pre-push hook exists only because py carries an optional web surface; whether ts carries an equivalent is decided outside this area.

## Files read
- py: `lefthook.yml`
- py: `.gitignore`
- py: `.gitattributes` — no feature: file does not exist in this repo
- py: `commitlint.config.mjs`
- py: `commitlint.dependabot.config.mjs`
- py: `.gitmessage` — no feature: file does not exist in this repo
- py: `.gitlint` — no feature: file does not exist in this repo (no gitlint tool present at this commit)
- py: `.pre-commit-config.yaml` — no feature: file does not exist in this repo at this commit
- py: `.gitleaks.toml`
- py: `.gitleaksignore`
- py: `.editorconfig`
- py: `.yamllint`
- py: `scripts/check-gitleaks.sh`
- py: `scripts/install-lefthook.sh`
- py: `Justfile`
- py: `pyproject.toml` — no feature beyond the codespell config line cited; other sections owned by other areas
- py: `.github/workflows/ci.yml`
- py: `.github/workflows/lint.yml`
- py: `.github/workflows/commitlint.yml`
- py: `docs/adr/0018-hook-ci-parity-and-boundary-gate.md`
- py: `CODEOWNERS` — no feature: file does not exist in this repo (checked repo root and `.github/`)
- ts: `lefthook.yml`
- ts: `.gitignore`
- ts: `.gitattributes` — no feature: file does not exist in this repo
- ts: `commitlint.config.mjs`
- ts: `commitlint.config.d.mts`
- ts: `.gitmessage`
- ts: `package.json`
- ts: `Justfile`
- ts: `tests/repo-hygiene.test.ts`
- ts: `.github/workflows/ci.yml`
- ts: `docs/port/TS_PORT_DECISIONS.md`
- ts: `CODEOWNERS` — no feature: file does not exist in this repo (checked repo root and `.github/`)

