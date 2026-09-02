# Area: dev-experience-repo-hygiene

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| id | feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|
| F176 | task-runner tool | `Justfile:1` — `just` recipes are the command surface | `Justfile:1` — `just` recipes are the command surface | same | D-024(1) | Near-1:1 port per D-024(1). |
| F177 | recipe grouping via attributes | `Justfile:93` — `[group('setup'), group('debug')]` above `check-deps` | `Justfile:73` — `[group('setup'), group('debug')]` above `check-deps` | same | D-024(1) | `just --list` renders recipes under these named groups. |
| F178 | recipe short aliases | `Justfile:105` — `alias c := check-deps` | `Justfile:86` — `alias c := check-deps` | same | D-024(1) | Both alias `check`/`build`/`format`/`lint`/`typecheck`/`test`. |
| F179 | two-level bootstrap split (Makefile=toolchain, Justfile=dev tasks) | `Makefile:43` — "This Makefile is Level 1 ONLY — the bootstrap" | `Makefile:1`, `Makefile:3` — "Bootstrap-only Makefile (D-024(2))"..."never wraps development tasks" | same | D-024(2) | Justfile `setup`/`install` is Level 2. |
| F180 | `make check` verifies base toolchain present | `Makefile:94` — checks `just`/`uv`, optional `docker` | `Makefile:47` — checks `just`/`node` | same | D-024(2) | Tool set differs (uv+docker vs node); pass/fail table pattern is identical. |
| F181 | `just check-deps` verifies full dev toolchain with per-tool remediation | `Justfile:94` — prints "RUN `make bootstrap`" / "RUN `just install-taplo`" per missing tool | `Justfile:74` — prints "RUN `make install-node`" per missing tool | same | D-024(1) | Both a `#!/usr/bin/env sh` script checking `command -v` per tool. |
| F182 | Level-2 setup gates on Level-1 bootstrap completion | `Justfile:111` — `setup:` runs `make --no-print-directory check` first and exits if it fails | — | py-only | — | ts's `@install: check-deps` (`Justfile:90`) has no equivalent gate back onto `make check`. |
| F183 | per-tool binary installer recipes for tools outside the primary package manager | `Justfile:159`, `Justfile:476`, `Justfile:482`, `Justfile:713` — `install-taplo`/`install-gitleaks`/`install-actionlint`/`install-yamlfmt`; the latter two shell out to `scripts/install-gitleaks.sh`/`scripts/install-actionlint.sh` | — | py-only | D-014(6), D-014(7) | ts folds taplo/yamlfmt into Oxfmt (D-014) and treats actionlint as advisory-only inside `check-deps` (`Justfile:83`), so no dedicated installer recipes or scripts remain; ts's only `scripts/` entry is `check-links.mjs` (a docs-link checker, unrelated). |
| F184 | `make install-*` print-first command + separate `-force` variant | `Makefile:158`, `Makefile:168` — `install-just` prints the command; `install-just-force` executes it | `Makefile:77`, `Makefile:86` — `install-just` prints the command; `install-just-force` executes it | same | D-024(2) | Same pattern for `install-uv`/`install-docker` (py) and `install-node`/`install-pnpm` (ts). |
| F185 | dependency-free environment diagnostic recipe ("doctor" report) | `Justfile:365` — `debug-info:` reports OS, tool versions (uv/ruff/git/just), CLI version, installed packages | `Justfile:325` — `debug-info:` reports OS, tool versions (node/pnpm/npm/git/just/bun), CLI version, installed packages | same | D-024(1) | Grouped `[group('debug')]`; no external dependency needed to run it. |
| F186 | hook-toolchain readiness check (doctor for git-hook tools) | `Makefile:130` — `hook-check:` verifies `lefthook gitleaks bun uv actionlint editorconfig-checker yamllint codespell` on PATH | — | py-only | — | ts has no equivalent Makefile/Justfile target auditing hook-tool presence separately from `check-deps`. |
| F187 | declarative toolchain-provisioner manifest: mise | `mise.toml:23` — `[tools]` pins `python`, `uv`, `ruff`, `taplo`, `gitleaks`, `just`, `bun`, `gh`, `lefthook`, `make`, `actionlint` | — | py-only | — | Provisioned via `mise install`; kept in sync with native installs and flox per `docs/adr/0005`. |
| F188 | declarative toolchain-provisioner manifest: flox | `.flox/env/manifest.toml:14` — `[install]` declares `python.pkg-path`, `uv.pkg-path`, etc. for the same 11-tool set | — | py-only | — | Provisioned via `flox activate`; `.flox/` is gitignored-lockfile, manifest committed. |
| F189 | three toolchain provisioners kept in manual sync (native + mise + flox) | `mise.toml:1` — header: "one of the project's three first-class dev environments... keep them in sync" | — | py-only | — | ts provisions only natively (Makefile/Justfile `install-*`); no mise/flox manifests exist. |
| F190 | toolchain version pin-file convention | `.python-version:1` — single bare value `3.12` | `.nvmrc:1` — single bare value `24` | same | D-011(3) | D-011(3): `.nvmrc` preserves the source's single-file pin-file discipline, chosen for the widest reader compatibility (nvm/fnm/mise/`actions/setup-node`). |
| F191 | cross-editor formatting baseline file | `.editorconfig:3` — `root = true`; charset/EOL/indent_style/indent_size defaults | — | py-only | — | ts has no `.editorconfig`; no row exists for it in the ts tree. |
| F192 | documented per-filetype `.editorconfig` exceptions | `.editorconfig:25`, `.editorconfig:31` — `[*.md]` keeps trailing whitespace (hard breaks); `[*.ambr]` keeps trailing whitespace (snapshot bytes) | — | py-only | — | Deliberate carve-outs from the root trim-trailing-whitespace rule, each with an inline rationale comment. |
| F193 | VS Code recommended-extensions list | `.vscode/extensions.json:2` — `"recommendations"` array: 11 ids incl. Python/Pylance/ruff, GitLens, GitHub PR/Actions | `.vscode/extensions.json:2` — `"recommendations"` array: 9 ids, Python/Pylance/ruff swapped for oxc.oxc-vscode | same | D-024(4) | D-024(4) describes dropping "the Python four" and keeping "8" cross-platform ids; the observed counts are 11 (py) and 9 (ts), 3 Python-specific ids swapped for 1 (oxc). |
| F194 | VS Code debug (`launch.json`) config for the CLI (pattern: committed debug configuration) | `.vscode/launch.json:6`, `.vscode/launch.json:8` — a `"type"`/`program`-or-`runtimeExecutable` launch config exists for the CLI | `.vscode/launch.json:6`, `.vscode/launch.json:8` — a `"type"`/`program`-or-`runtimeExecutable` launch config exists for the CLI | same | D-024(3) | Pattern row for the split below; the debugger tool implementing it differs per language runtime. |
| F195 | VS Code debugger tool/extension for the CLI | `.vscode/launch.json:6`, `.vscode/launch.json:8` — `"type": "python"`, `program` set to `src/py_launch_blueprint/cli/main.py` | `.vscode/launch.json:6`, `.vscode/launch.json:8` — `"type": "node"`, `runtimeExecutable: "tsx"` against `src/cli.ts` | same | D-024(3) | D-024(3): built-in `vscode-js-debug` replaces the Python debugger; bare + args + dist/ configs ported. |
| F196 | committed `.vscode/settings.json` pinning the editor's language-service version | — | `.vscode/settings.json:2` — `"typescript.tsdk": "node_modules/typescript/lib"` | ts-only | D-032 | D-032 permits exactly this one key as a narrow exception to the source's no-`settings.json` stance. |
| F197 | AI-agent instruction hub (single canonical file + thin per-tool import) | `AGENTS.md:1` (hub) + `CLAUDE.md:7` — `@AGENTS.md` import | `AGENTS.md:1` (hub) + `CLAUDE.md:3` — "See AGENTS.md for the full project charter" | same | D-024(5) | Both keep CLAUDE.md as a short command card that defers to AGENTS.md. |
| F198 | vendor-specific AI-editor rule files (Cursor/Windsurf) | — | `.cursor/rules/projectenv.mdc:9` — "read rules @AGENTS.md"; `.windsurf/rules/justfile-rules.md:2` — glob rule on `Justfile` | ts-only | D-024(5) | py dropped `.windsurfrules`/Cursor rules in commit `fc8d944` (pre-pin), consolidating into AGENTS.md only; ts keeps both as spokes pointing back to the hub. |
| F199 | repo-welcome startup announcement | — | `.claude/settings.json:2` — `"companyAnnouncements"` array with project summary + `just` command list | ts-only | D-024(6) | D-024(6): reused from the org's difftree `companyAnnouncements` convention; py's `.claude/settings.json` has no such key. |
| F200 | devcontainer (base image, postCreate bootstrap, in-container VS Code config) | `.devcontainer/devcontainer.json:4` — pinned `ghcr.io/astral-sh/uv:python3.12-bookworm-slim` image; `.devcontainer/post-create.sh:15` — runs `make bootstrap` then `just setup` | — | py-only | — | No `.devcontainer/` directory exists in ts and no `D-###` explains its omission. |
| F201 | issue-template set structure (typed templates + blank-disabled config) | `.github/ISSUE_TEMPLATE/config.yml:20` — `blank_issues_enabled: false` plus 2 contact links | `.github/ISSUE_TEMPLATE/config.yml:20` — `blank_issues_enabled: false` plus 2 contact links | same | — | Same 3 typed templates (`01-feature-request`, `02-documentation-request`, `03-bug-report`) plus `config.yml`. |
| F202 | issue-template label schema | `.github/ISSUE_TEMPLATE/01-feature-request.yml:23` — `labels: ["enhancement", "feature-request"]` | `.github/ISSUE_TEMPLATE/01-feature-request.yml:23` — `labels: ['enhancement', 'feature-request']` | same | — | Same fields (`markdown`/`dropdown` blocks, `id`, `label`, `description`, `options`, `validations`); ts's version is re-indented and single-quoted by Oxfmt's YAML formatting (D-014), which is why line counts differ (171 vs 157). |
| F203 | PR template pre-flight checklist | `.github/pull_request_template.md:102` — `- [ ] Ran &#96;just check&#96;...` checklist block | `.github/pull_request_template.md:109` — `- [ ] Commit messages follow [Conventional Commits]...` checklist block | same | D-024(1) | Same section shape; individual checklist wording tracks each repo's own tool names. |
| F204 | PR-comment bot re-review trigger block | `.github/pull_request_template.md:90` — "Review Trigger" section with `@coderabbitai review` / `@greptile-apps review` / `@cubic-dev-ai review` | — | py-only | — | Not carried into the ts PR template; ts relies on bots' auto-review-on-push only. |
| F205 | FUNDING.yml | `.github/FUNDING.yml:22` — `github: smorin` | `.github/FUNDING.yml:6` — `github: smorin` | same | D-024(12) | D-024(12): "Copy as-is... with header reduced to SPDX line". |
| F206 | root LICENSE file | `LICENSE:1` — `MIT License` | `LICENSE:1` — `MIT License` | same | D-024(7) | Both also declare `license` in their package manifest (`pyproject.toml` / `package.json:11`). |
| F207 | per-file embedded license header | `src/py_launch_blueprint/__init__.py:1` — full 18-line MIT header comment, present in 51 files | `.github/dependabot.yml:1` — legacy unconverted 18-line 2025 header, present in 12 config/workflow files; `.github/FUNDING.yml:1` — the 1 file converted to a 2-line SPDX comment | different | D-024(7) | D-024(7) intended replacing the header with a one-line SPDX comment everywhere; in the pinned ts commit that conversion landed only in FUNDING.yml — the other 12 originally-copied config/workflow files still carry the old unconverted header, and every `.ts` source file carries none. |
| F208 | CLA program (texts, FAQ, setup guide, hosted bot) | `.github/CONTRIBUTING.md:62` — links `docs/source/tools/cla-assistant.md` | `.github/CONTRIBUTING.md:18` — links `../docs/tools/cla-assistant.md` | same | D-024(8) | D-024(8): keep the full CLA program as-is; both ship `individual-cla`/`corporate-cla`/setup-guide docs. |
| F209 | contributors-render config schema (`.contributors.yml` + `.contributors.jsonl` ledger) | `.contributors.yml:7` — `state_file: .contributors.jsonl`, `in_place_marker_start`/`in_place_marker_end` | `.contributors.yml:9` — `state_file: .contributors.jsonl`, same `in_place` marker keys | same | D-024(9) | Identical `contributors-please` config schema in both repos. |
| F210 | local Justfile recipe's subcommand vs. the CI bot's action mode | `Justfile:462` — `update-contributors:` runs `npx contributors-please@1 init --non-interactive ...` | `Justfile:244` — `@contributors:` runs `pnpm dlx contributors-please render` | different | D-024(9) | Both CI workflows call the same `contributors-please-action` in `mode: pull-request` (py `.github/workflows/update-contributors.yml:38`; ts `.github/workflows/update-contributors.yml:81`). D-024(9)'s why-text calls py's local `init` recipe an "orphan" divergent from that CI behavior; ts's local `render` recipe reproduces the ledger-to-Markdown render step the action performs, rather than py's from-scratch bootstrap. |

## Language-bound tools
- `uv` (py) — Python dependency/venv manager checked by `check-deps`/`make check` and provisioned by mise/flox
- `pnpm` (ts) — package manager whose install `check-deps` verifies before `just install`
- `mise` (py) — declarative toolchain provisioner (`mise.toml`)
- `flox` (py) — declarative toolchain provisioner (`.flox/env/manifest.toml`)
- `tsx` (ts) — TypeScript runtime executable used by `.vscode/launch.json` debug configs
- `contributors-please` (py, ts) — CLI that renders `CONTRIBUTORS.md` from `.contributors.jsonl`, invoked directly from the Justfile in both repos

## Cross-area parameters
- `git-hooks-manager` — the `hook-check`/`check-deps` tool lists include `lefthook`/`gitleaks`/`commitlint`, whose manager choice (lefthook) is decided by the git-hooks topic (D-020), not here.
- `package-manager-invocation` — `just install`/`just contributors` invoke `pnpm`/`npx`; the underlying package-manager choice (D-011, D-035) belongs to a separate topic.
- `node-version-floor` — `.nvmrc`'s pinned value (`24`) is set by the runtime/toolchain decision (D-011(2)); this area only reports the pin-file convention that carries it.
- `python-version-floor` — `.python-version`'s pinned value (`3.12`) and `mise.toml`'s `python = "3.12"` are set by the same runtime-floor decision this area does not own the number for, only the file mechanism.

## Files read
- py: `Justfile`
- py: `Makefile`
- py: `mise.toml`
- py: `.flox/env/manifest.toml`
- py: `.flox/env.json` — no feature: env metadata only (schema/env-name bookkeeping), no hygiene-choosable content
- py: `.flox/.gitignore` — no feature: standard flox-generated ignore rules
- py: `.editorconfig`
- py: `.editorconfig-checker.json` — no feature: enforcement wiring already covered by git-hooks-commit-hygiene.md
- py: `.python-version`
- py: `.vscode/extensions.json`
- py: `.vscode/launch.json`
- py: `.devcontainer/devcontainer.json`
- py: `.devcontainer/post-create.sh`
- py: `.github/ISSUE_TEMPLATE/01-feature-request.yml`
- py: `.github/ISSUE_TEMPLATE/02-documentation-request.yml`
- py: `.github/ISSUE_TEMPLATE/03-bug-report.yml`
- py: `.github/ISSUE_TEMPLATE/config.yml`
- py: `.github/pull_request_template.md`
- py: `.github/FUNDING.yml`
- py: `.github/CONTRIBUTING.md`
- py: `LICENSE`
- py: `pyproject.toml` — no feature: only checked for `license` field cross-reference
- py: `CLAUDE.md`
- py: `AGENTS.md`
- py: `.claude/settings.json`
- py: `.contributors.yml`
- py: `CONTRIBUTORS.md`
- py: `.github/workflows/update-contributors.yml`
- py: `docs/source/tools/cla-assistant.md` — no feature: confirmed as the linked CLA doc, content owned by docs-system area
- py: `docs/adr/0005-mise-flox-first-class-toolchains.md`
- py: `docs/adr/0012-doctor-bundle-redact-at-collection.md` — no feature: describes the `plbp doctor` CLI product subcommand (a shipped-product feature), not a repo-hygiene tool for contributors
- ts: `Justfile`
- ts: `Makefile`
- ts: `.vscode/extensions.json`
- ts: `.vscode/launch.json`
- ts: `.vscode/settings.json`
- ts: `.cursor/rules/projectenv.mdc`
- ts: `.cursor/rules/doc-template.mdc` — no feature: a standalone doc-authoring template rule (required section list for `docs/**/*.md`), not part of the AGENTS.md-hub mechanism captured via projectenv.mdc
- ts: `.windsurf/rules/justfile-rules.md`
- ts: `.github/ISSUE_TEMPLATE/01-feature-request.yml`
- ts: `.github/ISSUE_TEMPLATE/02-documentation-request.yml`
- ts: `.github/ISSUE_TEMPLATE/03-bug-report.yml`
- ts: `.github/ISSUE_TEMPLATE/config.yml`
- ts: `.github/pull_request_template.md`
- ts: `.github/FUNDING.yml`
- ts: `.github/CONTRIBUTING.md`
- ts: `LICENSE`
- ts: `package.json`
- ts: `CLAUDE.md`
- ts: `AGENTS.md`
- ts: `.claude/settings.json`
- ts: `.contributors.yml`
- ts: `CONTRIBUTORS.md`
- ts: `.github/workflows/update-contributors.yml`
- ts: `docs/tools/cla-assistant.md` — no feature: confirmed as the linked CLA doc, content owned by docs-system area
- ts: `.nvmrc`
- ts: `.npmrc` — no feature: pnpm package-manager enforcement settings, owned by the package-manager-choice topic
- ts: `docs/port/TS_PORT_DECISIONS.md`
- ts: `docs/port/TS_EXISTING_REPO_REVIEW.md` — no feature: background research citation only, confirmed `doctor` hits refer to the CLI product subcommand, not repo tooling
