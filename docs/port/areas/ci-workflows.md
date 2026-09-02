# Area: ci-workflows

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| id | feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|---|
| F024 | CI trigger: push and PR to main | `.github/workflows/ci.yml:12` — push/pull_request branches [main] | `.github/workflows/ci.yml:30` — push/pull_request branches [main] | same | — | |
| F025 | merge_group trigger so required checks report in the GitHub merge queue | `.github/workflows/ci.yml:19` — merge_group: on ci.yml; also `.github/workflows/lint.yml:21`, `.github/workflows/commitlint.yml:21` | — | py-only | — | ts has no merge queue trigger anywhere in .github/workflows |
| — | release-please: manual re-trigger via workflow_dispatch | — | `.github/workflows/release-please.yml:38` — workflow_dispatch alongside push | ts-only | — | py's release-please.yml:18-20 has only the push trigger; see F073 |
| F026 | Contributors-bot workflow trigger cadence | `.github/workflows/update-contributors.yml:3` — push to main with paths-ignore, plus workflow_dispatch | `.github/workflows/update-contributors.yml:49` — weekly cron schedule plus workflow_dispatch | different | — | ts deliberately diverges from the push trigger to avoid stacking noise on top of CI/CodeQL/dependency-review |
| F027 | CodeQL gated to public repos via a runtime visibility check | `.github/workflows/codeql.yml:30` — repository-visibility job using actions/github-script, analyze needs it | `.github/workflows/codeql.yml:48` — same repository-visibility job pattern | same | D-022(4) | GitHub Code Security is unavailable on unlicensed private repos in both |
| F028 | Top-level deny-all permissions baseline with per-job least-privilege grants | `.github/workflows/ci.yml:21` — `permissions: {}` then job re-grants (e.g. `.github/workflows/ci.yml:35`) | `.github/workflows/ci.yml:37` — `permissions: {}` then job re-grants (e.g. `.github/workflows/ci.yml:43`) | same | D-022(10) | Applied to most gating/security workflows in both; dependency-review.yml and difftree-pr-comment.yml skip the deny-all wrapper in both repos |
| F029 | Checkout credential-persistence hardening (persist-credentials: false) | `.github/workflows/difftree-pr-comment.yml:55` — only on the shared difftree template | `.github/workflows/ci.yml:57` — applied broadly (also codeql.yml:101-102, publish.yml:51-52, dependency-review.yml:57-58, manual-pr-security-scan.yml:67-68) | different | D-022(9) | Comments in ts label this the "zizmor artipacked" mitigation |
| F030 | Contributors-bot workflow permission declaration style | `.github/workflows/update-contributors.yml:11` — explicit contents/pull-requests/issues write at top level, no deny-all | `.github/workflows/update-contributors.yml:56` — deny-all `permissions: {}` at top, job re-grants the same three scopes | different | D-022(10) | |
| F031 | Runner OS selection overridable via repo vars with self-hosted fallback | `.github/workflows/ci.yml:34` — `runs-on` falls back to vars.RUNNER_UBUNTU or else 'ubuntu-latest', repeated fleet-wide; `.github/actionlint.yaml:56` declares the Blacksmith labels and RUNNER_* config-variables | — | py-only | — | Used in nearly every py workflow job (17 of 21 workflow files reference vars.RUNNER_*); ts hardcodes `ubuntu-latest` everywhere |
| F032 | Multi-OS test matrix (ubuntu, macOS, windows) | `.github/workflows/ci.yml:140` — test job runs on ubuntu/macos/windows | — | py-only | — | ts's ci.yml matrix (line 51) varies only node-version, always on ubuntu-latest; OMIT — Windows is excluded by the owner-fixed `target-os-matrix` parameter (`docs/port/PARAMETERS.md`), so this row has no Rust analogue to research |
| F033 | Runtime-version matrix is a two-entry floor-plus-next set | `.github/workflows/ci.yml:156` — `python-version: ["3.12", "3.13"]` | `.github/workflows/ci.yml:51` — `node-version: ['24.x', '26.x']` | same | D-027 | ts's matrix values were adjudicated in D-027 to mirror this floor+next intent |
| F034 | Matrix job uses fail-fast: false to surface every leg's failure | `.github/workflows/ci.yml:153` — test job | `.github/workflows/ci.yml:47` — ci job; also `.github/workflows/codeql.yml:86` | same | — | |
| F035 | Dependency caching integrated into the language-setup step (pattern) | `.github/workflows/ci.yml:87` — `astral-sh/setup-uv@v8.3.2` (uv's own cache) | `.github/workflows/ci.yml:69` — `actions/setup-node@v7` with `cache: 'pnpm'` | same | D-022(3) | split from the prior single row: this row is the pattern (CI dependency install is cached without a separate cache-management step); the specific action is F036 |
| F036 | Dependency caching built into the language-setup action (tool) | `.github/workflows/ci.yml:87` — `astral-sh/setup-uv@v8.3.2` (uv's own cache) | `.github/workflows/ci.yml:69` — `actions/setup-node@v7` with `cache: 'pnpm'` | same | D-022(3) | split from F035; py/ts each get caching for free from their language-setup action — Rust has no single canonical equivalent (`dtolnay/rust-toolchain` does not cache; `Swatinem/rust-cache`/`actions/cache` are separate choices), so the specific mechanism is a research question |
| F037 | Package-manager install must run before the cache-aware setup step (ordering constraint) | — | `.github/workflows/ci.yml:64` — pnpm/action-setup placed before setup-node so cache:'pnpm' can find the store | ts-only | D-035 | py's uv install (astral-sh/setup-uv) is self-contained and has no equivalent ordering note; citation corrected from ci.yml:60 (a comment line) to :64 (the `uses:` step); OMIT — cargo/rustup need no separate package-manager pre-install step, so this ordering constraint has no Rust analogue |
| — | Linter run as a CI gate | `.github/workflows/ci.yml:90` — `uv run --no-sync ruff check .` | `.github/workflows/ci.yml:88` — `just lint` (oxlint) | same | D-014 | CI merely runs the linter chosen elsewhere; see F085 |
| — | Formatter check run as a CI gate | `.github/workflows/ci.yml:92` — `uv run --no-sync ruff format --check .` | `.github/workflows/ci.yml:85` — `just format-check` (oxfmt) | same | D-014 | CI merely runs the formatter chosen elsewhere; see F084 |
| — | Typecheck run as a CI gate | `.github/workflows/ci.yml:96` — dedicated `typecheck` job, gated on the changes detector, runs `ty check` | `.github/workflows/ci.yml:91` — `just typecheck` step inside the single `ci` job (tsc --noEmit) | same | D-015 | py isolates typecheck as its own job; ts folds it into one job with no changes-gate; CI merely runs the typechecker chosen elsewhere; see F105 |
| — | Architectural boundary lint (import-linter + tach) as a CI gate | `.github/workflows/ci.yml:118` — `import-boundaries` job runs `lint-imports` then `tach check` | — | py-only | — | No import/module-boundary CI gate exists in ts's ci.yml; the boundary-enforcement mechanism itself is workspace-architecture's decision; see F007 |
| — | TOML formatting checked as a separate CI job | `.github/workflows/ci.yml:246` — `toml-format` job runs `taplo check` | — | py-only | D-014 | D-014 drops taplo from the TS toolchain; oxfmt covers TS-side formatting instead; whether Rust formats TOML at all is lint-format's decision; see F097 |
| F038 | Consolidated lint workflow (actionlint, yamllint, bandit, codespell, editorconfig-check) with path-filtered skip | `.github/workflows/lint.yml:15` — five jobs, `lint-changes` (lines 30-64) gates actionlint/yamllint on changed paths | — | py-only | — | ts has no separate lint.yml; oxlint/oxfmt/tsc are the only checks and they run inside ci.yml; bundle — the CI-owned fact here is workflow-file structure plus path-filtered skip-gating, not the five individual tools' selection |
| — | Full pre-commit/lefthook hook suite re-run against all files inside CI | — | `.github/workflows/ci.yml:105` — `pnpm exec lefthook run pre-commit --all-files` | ts-only | D-022(1) | py's ci.yml has no equivalent step; py's Justfile has no `pre-commit-run` recipe either; see F174 |
| — | Commit-message linting as a required CI check, split by human vs dependabot author | `.github/workflows/commitlint.yml:30` — `commitlint-humans` and `commitlint-dependabot` jobs, routed on `pull_request.user.login` | — | py-only | — | ts relies solely on lefthook's local commit-msg hook (commitlint.config.mjs); no CI workflow lints PR commit messages; see F157 |
| — | Unit tests run as a CI gate | `.github/workflows/ci.yml:177` — pytest steps (with/without coverage) inside the `test` matrix job | `.github/workflows/ci.yml:94` — `just test` (vitest) | same | D-019 | CI merely runs the test suite chosen elsewhere; see F117 |
| — | Coverage upload to Codecov | `.github/workflows/ci.yml:189` — active `codecov/codecov-action@v7.0.0` with OIDC (`use_oidc: true`) on one matrix cell | `.github/workflows/ci.yml:113` — commented-out scaffold only, not enabled | different | — | see F137 |
| — | Packaged-artifact build-and-install smoke test | `.github/workflows/ci.yml:204` — `build-smoke` job: `uv build`, `twine check`, install wheel and sdist, run the CLI | — | py-only | — | see F221 |
| F039 | Packed-artifact file-list assertion (only expected files ship) | — | `.github/workflows/publish.yml:112` — `npm pack --dry-run --json` parsed to assert dist/-plus-whitelist contents | ts-only | D-035 | Runs at publish time, not in ci.yml; `cargo package --list`/`cargo publish --dry-run` is the plausible Rust analogue, but whether/how to assert it in CI is a real choice |
| — | Docs build validated with warnings-as-errors as a PR gate | `.github/workflows/ci.yml:230` — `docs` job runs `sphinx-build -W -b html` | — | py-only | — | see F348 |
| — | Docs link-check | `.github/workflows/dep-audit.yml:53` — `docs-linkcheck` job (Sphinx linkcheck), weekly scheduled, non-gating | `.github/workflows/ci.yml:97` — `just docs-check` step (`node scripts/check-links.mjs`), runs per-PR inside ci.yml | different | D-023(5) | py's link-check never blocks a PR; ts's does; see F349 and F350 |
| F040 | A changes-detector job skips heavy jobs on docs-only PRs | `.github/workflows/ci.yml:32` — `changes` job (WL-019); consumed by `typecheck`, `import-boundaries`, `test`, `build-smoke` | — | py-only | — | bundle — same path-filtered skip-gating question as F038 |
| F041 | Single aggregate required-status-check job folding in all other job results | `.github/workflows/ci.yml:268` — `ci-ok` job checks `needs.*.result`, treats skipped as pass | — | py-only | — | |
| — | Advisory, non-blocking alternate-runtime test lane inside the CI workflow | — | `.github/workflows/ci.yml:141` — `bun-lane` job, `continue-on-error: true`, runs Vitest under Bun excluding the e2e tier | ts-only | D-036 | see F127 |
| — | Scheduled "canary" run against freshly re-resolved (unpinned) dependencies | `.github/workflows/canary.yml:12` — weekly, `uv sync --upgrade`, full test suite, never gates a PR | — | py-only | — | see F126 (same dependency-freshness canary, cited there as canary.yml:16/:47) |
| F042 | Scheduled full-dependency-graph vulnerability audit | `.github/workflows/dep-audit.yml:13` — weekly `pip-audit --strict` against the exported locked graph | — | py-only | — | bundle with F048/F049 — one Rust SCA/vulnerability-scanning strategy (scheduled audit + manual on-demand tool + always-on intent) is a single decision, not three; ts has no scheduled audit workflow, only the per-PR dependency-review gate and the commented `pnpm audit` scaffold (F049) |
| F043 | Large-file size guard on new files | `.github/workflows/large-file-guard.yml:4` — rejects new files over 1 MB outside `docs/assets/` | — | py-only | — | Distinct from git-hooks-commit-hygiene's hook-tier large-file check (different tier: CI-level workflow vs. pre-commit hook); whether Rust needs CI-level redundancy on top of a hook is this area's own call |
| — | OpenAPI breaking-change gate (oasdiff against the base branch's snapshot) | `.github/workflows/api-contract.yml:1` — `oasdiff/oasdiff-action/breaking@v0.1.6` on `docs/api/openapi.json` changes | — | py-only | — | see F333 |
| F044 | Template drift/receipt guard workflows | `.github/workflows/press-verify.yml:10` (hermetic self-press check) and `.github/workflows/template-receipt-guard.yml:6` (rejects a committed press receipt) | — | py-only | — | py-launch-blueprint is a `template-press`-rebrandable template; no equivalent concept found in ts (ts's own port decisions carry no D-0xx adopting it either) |
| F045 | CodeQL custom config file (query pack selection plus paths-ignore) | `.github/codeql/codeql-config.yml:11` — `security-extended` queries, ignores `tests/**` and `docs/**`; referenced from `.github/workflows/codeql.yml:63` | — | py-only | — | ts's CodeQL Init step (`.github/workflows/codeql.yml:105`) has no `config-file:` input |
| F046 | Dependency-review PR gate | `.github/workflows/dependency-review.yml:48` — `actions/dependency-review-action@v5`, `comment-summary-in-pr: always` | `.github/workflows/dependency-review.yml:50` — `actions/dependency-review-action@a1d282b…` (v5.0.0, SHA-pinned), same option | same | D-022(5) | |
| F047 | Manual, environment-gated PR security scan (workflow_dispatch) | `.github/workflows/manual-pr-security-scan.yml:25` — `pr_number` input; `.github/workflows/manual-pr-security-scan.yml:29` — `reviewer` input; `.github/workflows/manual-pr-security-scan.yml:39` — `environment: security-review` | `.github/workflows/manual-pr-security-scan.yml:39` — `pr_number` input; `.github/workflows/manual-pr-security-scan.yml:43` — `reviewer` input; `.github/workflows/manual-pr-security-scan.yml:56` — `environment: security-review` | same | D-022(6) | |
| F048 | Manual security-scan tool | `.github/workflows/manual-pr-security-scan.yml:49` — `pyupio/safety-action@v1` with `secrets.SAFETY_API_KEY` | `.github/workflows/manual-pr-security-scan.yml:74` — `google/osv-scanner-action@9a49870…` (v2.3.8), no API key | different | D-022(6) | bundle with F042/F049 — one Rust SCA/vulnerability-scanning strategy (scheduled audit + manual on-demand tool + always-on intent) is a single decision, not three |
| F049 | Always-on SCA audit as commented, uncomment-to-enable scaffolding inside the main CI workflow | — | `.github/workflows/ci.yml:119` — commented `pnpm audit --audit-level high` step with a same-repo fork guard | ts-only | D-022(7) | py's ci.yml has no such commented block; py's SCA-equivalent (pip-audit) is a live scheduled job instead (dep-audit.yml); bundle with F042/F048 |
| F050 | Dedicated secret-scanning CI workflow | `.github/workflows/secret-scan.yml:1` — TruffleHog, `--only-verified`, diff-scan on PR / full scan on push | — | py-only | — | ts has no CI secret-scan workflow; distinct tool and tier from git-hooks-commit-hygiene's gitleaks pre-commit/pre-push hooks (different tool, different tier) — not bundled with that area |
| F051 | AI-assisted PR code review workflow | `.github/workflows/claude-code-review.yml:1` — `anthropics/claude-code-action@v1.0.175` on PR open/sync, skips bot-authored/bot-sent PRs | — | py-only | — | bundle with F052 — same claude-code-action family, plausibly adopted or dropped together |
| F052 | AI assistant workflow triggered by @mention comments | `.github/workflows/claude.yml:1` — triggers on issue/PR-review comments and issues containing `@claude` | — | py-only | — | bundle with F051 |
| F053 | Dependabot ecosystems configured | `.github/dependabot.yml:14` — `uv`, `github-actions`, `npm` (Bun-related deps only) | `.github/dependabot.yml:28` — `github-actions`, `npm` (covers pnpm lockfile) | different | D-022(8), D-035 | pnpm keeps Dependabot's ecosystem id `npm`; bundle with F054 — ecosystems and grouping are one Dependabot-config-shape decision |
| F054 | Dependabot update grouping strategy | `.github/dependabot.yml:28` — named groups (runtime, dev-tools, lint-and-format, test) plus 5-day cooldown, labels, and a commit-message prefix contract | `.github/dependabot.yml:34` — a single minor/patch update-type group per ecosystem, no cooldown/labels/commit-message customization | different | D-022(8) | bundle with F053 |
| F055 | Third-party GitHub Action pinning policy | `.github/workflows/update-contributors.yml:27` — `smorinlabs/contributors-please-action@v1.3.9` (floating major-version tag) | `.github/workflows/update-contributors.yml:74` — `smorinlabs/contributors-please-action@3c6dbff9…` (full SHA + version comment) | different | D-022(9) | Official `actions/*`/`github/*` actions stay major-tag-pinned in both; ts additionally SHA-pins third-party actions |
| F056 | actionlint config: self-hosted runner labels declared | `.github/actionlint.yaml:56` — `self-hosted-runner.labels` lists the three Blacksmith labels so `[runner-label]` passes | — | py-only | — | split from the prior single row (bundled two distinct actionlint-config facts); bundle with F031/F057 — only needed if the vars.RUNNER_*/Blacksmith indirection (F031) is adopted |
| F057 | actionlint config: RUNNER_* config-variables declared | `.github/actionlint.yaml:62` — `config-variables` lists RUNNER_UBUNTU, RUNNER_MACOS, RUNNER_WINDOWS so actionlint's variable-usage check passes | — | py-only | — | split from the prior single row; bundle with F031/F056 |
| F058 | actionlint config: stale-metadata suppression scope for create-github-app-token | `.github/actionlint.yaml:67` — scoped only to `release-please.yml` | `.github/actionlint.yaml:11` — scoped to both `release-please.yml` and `publish.yml` | different | — | ts's publish.yml does not actually invoke `create-github-app-token`, so that half of its suppression list has no matching workflow step; contingent on release-versioning's auth-mechanism choice (whether Rust uses create-github-app-token at all), but the suppression-scope question is CI's own actionlint-config call |
| — | Release-please automated release-PR workflow | `.github/workflows/release-please.yml:16` — push to main, `googleapis/release-please-action@v5.0.0` | `.github/workflows/release-please.yml:34` — push to main (+workflow_dispatch), `googleapis/release-please-action@45996ed1…` (v5.0.0, SHA-pinned) | same | D-021 | see F073 |
| — | Release-please auth: minted GitHub App token with PAT fallback, no GITHUB_TOKEN fallback | `.github/workflows/release-please.yml:42` — `create-github-app-token@v3` if the client-id secret is set, else `RELEASE_PLEASE_APP_TOKEN` | `.github/workflows/release-please.yml:66` — identical two-tier fallback | same | D-021 | GITHUB_TOKEN is deliberately excluded because it cannot trigger downstream workflows; see F072 |
| F059 | Publish workflow triggered on a `v*` tag push | `.github/workflows/publish.yml:6` | `.github/workflows/publish.yml:29` | same | D-021 | workflow trigger is CI-owned even though the publish content itself is release-versioning's |
| — | Tag/version consistency verification before publishing | `.github/workflows/publish.yml:39` — tag reachable from main, then tag equals `pyproject.toml` version | `.github/workflows/publish.yml:73` — tag reachable from main, then tag equals `package.json` and the release-please manifest version | same | D-021(5), D-022(13) | ts checks two version sources (package.json and the manifest), py checks one (pyproject.toml); see F074 |
| — | Publish pipeline staging | `.github/workflows/publish.yml:16` — sequential `build` then `publish-testpypi` then `publish-pypi`, each its own environment, no human-approval gate declared | `.github/workflows/publish.yml:39` — a cheap unprivileged `verify` job feeding a single `npm` environment `publish` job that requires human approval | different | D-021, D-035 | see F076 and F077 |
| — | OIDC Trusted Publishing (no long-lived registry secret) | `.github/workflows/publish.yml:74` — `id-token: write`, `uv publish --trusted-publishing always` | `.github/workflows/publish.yml:151` — `id-token: write`, `npm publish` under the OIDC-authenticated npm environment | same | D-035 | ts installs/builds with pnpm but publishes with the npm CLI because pnpm 10's OIDC publish has an open bug; see F075 |
| F060 | Automated contributors-list bot-PR workflow | `.github/workflows/update-contributors.yml:17` — `smorinlabs/contributors-please-action@v1.3.9`, `mode: pull-request` | `.github/workflows/update-contributors.yml:59` — same action and mode, plus `bootstrap: 'true'` | same | D-022(11) | |
| F061 | Contributors-bot credential source for the PAT fallback | `.github/workflows/update-contributors.yml:34` — `secrets.CONTRIBUTORS_PLEASE_PAT` | `.github/workflows/update-contributors.yml:80` — `secrets.GITHUB_TOKEN` | different | D-022(11) | ts's choice lets the template work with zero extra repo secrets configured |
| F062 | Difftree PR-comment workflow | `.github/workflows/difftree-pr-comment.yml:1` | `.github/workflows/difftree-pr-comment.yml:1` | same | — | Byte-identical canonical template from smorinlabs/difftree-action in both repos |

## Language-bound tools
- `ruff` (py) — combined linter and formatter run as separate CI steps/job
- `ty` (py) — typechecker run as its own CI job
- `taplo` (py) — TOML formatter checked in its own CI job
- `import-linter` (py) — architectural import-boundary lint in CI
- `tach` (py) — module-boundary check in CI, paired with import-linter
- `bandit` (py) — security linter, one of lint.yml's parallel jobs
- `pytest` / `pytest-cov` / `pytest-xdist` (py) — test runner and coverage producer in the test matrix job
- `sphinx-build` (py) — docs HTML build (warnings-as-errors) and docs linkcheck
- `twine` (py) — dist metadata check in build-smoke
- `pip-audit` (py) — scheduled dependency vulnerability audit
- `uv` (py) — dependency sync/build/publish tool invoked in nearly every job
- `oxlint` (ts) — linter run via `just lint`
- `oxfmt` (ts) — formatter run via `just format-check`
- `tsc` (ts) — typechecker run via `just typecheck`
- `vitest` (ts) — test runner, both under Node (`just test`) and under Bun (bun-lane)
- `lefthook` (ts) — hook manager whose full suite is re-run in CI (`lefthook run pre-commit --all-files`)
- `pnpm` (ts) — package manager; installs, caches, and (verify job) packs the publish artifact
- `bun` (ts) — advisory, non-gating alternate test runtime in ci.yml's bun-lane job

## Cross-area parameters
- `python-version-floor` — the CI test matrix's Python versions are set by the same floor/next decision the runtime/toolchain area owns (D-011/D-027)
- `node-version-floor` — the CI matrix's Node versions (`24.x`/`26.x`) are set by the runtime-topic decision (D-011(2)), not decided within CI workflows itself
- `package-manager-choice` — CI's install/cache steps (pnpm vs uv) depend on the package-manager decision owned by the toolchain area (D-035)
- `web-extra-surface` — the docs job, build-smoke, and api-contract.yml's OpenAPI gate depend on whether the ported project carries an equivalent optional web/API surface, decided outside this area
- `release-tooling-choice` — publish.yml and release-please.yml's shape depends on the release/versioning topic's tool selection (D-021), which this area only consumes

## Files read
- py: `.github/workflows/ci.yml`
- py: `.github/workflows/codeql.yml`
- py: `.github/codeql/codeql-config.yml`
- py: `.github/workflows/dependency-review.yml`
- py: `.github/workflows/manual-pr-security-scan.yml`
- py: `.github/workflows/publish.yml`
- py: `.github/workflows/release-please.yml`
- py: `.github/workflows/update-contributors.yml`
- py: `.github/workflows/difftree-pr-comment.yml`
- py: `.github/dependabot.yml`
- py: `.github/actionlint.yaml`
- py: `.github/workflows/canary.yml`
- py: `.github/workflows/claude-code-review.yml`
- py: `.github/workflows/claude.yml`
- py: `.github/workflows/commitlint.yml`
- py: `.github/workflows/dep-audit.yml`
- py: `.github/workflows/large-file-guard.yml`
- py: `.github/workflows/lint.yml`
- py: `.github/workflows/press-verify.yml`
- py: `.github/workflows/secret-scan.yml`
- py: `.github/workflows/template-receipt-guard.yml`
- py: `.github/workflows/api-contract.yml`
- py: `Justfile` — no feature: grepped for `ci`/`check`/`pre-commit-run` recipes to confirm py's CI has no lefthook-suite-replay step; found none
- ts: `.github/workflows/ci.yml`
- ts: `.github/workflows/codeql.yml`
- ts: `.github/workflows/dependency-review.yml`
- ts: `.github/workflows/manual-pr-security-scan.yml`
- ts: `.github/workflows/publish.yml`
- ts: `.github/workflows/release-please.yml`
- ts: `.github/workflows/update-contributors.yml`
- ts: `.github/workflows/difftree-pr-comment.yml`
- ts: `.github/dependabot.yml`
- ts: `.github/actionlint.yaml`
- ts: `Justfile` — no feature: grepped for `commitlint`/`docs-check` recipes to confirm ts has no CI-level commitlint check and to locate the docs-check recipe cited above
- ts: `docs/port/TS_PORT_DECISIONS.md` — no table row directly: read for D-021/D-022/D-027/D-035/D-036 context cited throughout the `ts-decisions` column
