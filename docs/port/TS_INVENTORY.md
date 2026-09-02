# ts-launch-blueprint inventory (derived from COMMONALITY.md — do not edit)

| ID | Feature | Area | Verdict | Item |
|---|---|---|---|---|
| F001 | Ports abstraction for the driven I/O seam | workspace-architecture | DIVERGENT | R01 |
| F002 | Composition root wiring a port to a concrete adapter | workspace-architecture | DIVERGENT | R01 |
| F012 | Port absence-vs-failure contract | workspace-architecture | DIVERGENT | R03 |
| F014 | Public library API surface, curated re-export list | workspace-architecture | COMMON → REUSE | — |
| F015 | Public-surface enforcement mechanism | workspace-architecture | DIVERGENT | R04 |
| F016 | Sync/async execution model for the I/O boundary | workspace-architecture | DIVERGENT | R05 |
| F019 | Source code lives under a top-level `src/` directory | workspace-architecture | COMMON → REUSE | — |
| F020 | Package namespacing within `src/` | workspace-architecture | DIVERGENT | R02 |
| F024 | CI trigger: push and PR to main | ci-workflows | COMMON → REUSE | — |
| F026 | Contributors-bot workflow trigger cadence | ci-workflows | DIVERGENT | R07 |
| F027 | CodeQL gated to public repos via a runtime visibility check | ci-workflows | COMMON → REUSE | — |
| F028 | Top-level deny-all permissions baseline with per-job least-privilege grants | ci-workflows | COMMON → REUSE | — |
| F029 | Checkout credential-persistence hardening (persist-credentials: false) | ci-workflows | DIVERGENT | R08 |
| F030 | Contributors-bot workflow permission declaration style | ci-workflows | DIVERGENT | R08 |
| F033 | Runtime-version matrix is a two-entry floor-plus-next set | ci-workflows | COMMON → REUSE | — |
| F034 | Matrix job uses fail-fast: false to surface every leg's failure | ci-workflows | COMMON → REUSE | — |
| F035 | Dependency caching integrated into the language-setup step (pattern) | ci-workflows | COMMON → REUSE | — |
| F036 | Dependency caching built into the language-setup action (tool) | ci-workflows | COMMON → SUBSTITUTE | R10 |
| F037 | Package-manager install must run before the cache-aware setup step (ordering constraint) | ci-workflows | OMIT | — |
| F039 | Packed-artifact file-list assertion (only expected files ship) | ci-workflows | DIVERGENT | R26 |
| F046 | Dependency-review PR gate | ci-workflows | COMMON → REUSE | — |
| F047 | Manual, environment-gated PR security scan (workflow_dispatch) | ci-workflows | COMMON → REUSE | — |
| F048 | Manual security-scan tool | ci-workflows | DIVERGENT | R13 |
| F049 | Always-on SCA audit as commented, uncomment-to-enable scaffolding inside the main CI workflow | ci-workflows | DIVERGENT | R13 |
| F053 | Dependabot ecosystems configured | ci-workflows | DIVERGENT | R19 |
| F054 | Dependabot update grouping strategy | ci-workflows | DIVERGENT | R19 |
| F055 | Third-party GitHub Action pinning policy | ci-workflows | DIVERGENT | R20 |
| F058 | actionlint config: stale-metadata suppression scope for create-github-app-token | ci-workflows | DIVERGENT | R09 |
| F059 | Publish workflow triggered on a `v*` tag push | ci-workflows | COMMON → REUSE | — |
| F060 | Automated contributors-list bot-PR workflow | ci-workflows | COMMON → REUSE | — |
| F061 | Contributors-bot credential source for the PAT fallback | ci-workflows | DIVERGENT | R21 |
| F062 | Difftree PR-comment workflow | ci-workflows | COMMON → REUSE | — |
| F063 | version source of truth | release-versioning | COMMON → REUSE | — |
| F064 | runtime version accessor | release-versioning | DIVERGENT | R22 |
| F065 | lockfile version sync in release commit | release-versioning | DIVERGENT | R23 |
| F066 | changelog file generation | release-versioning | COMMON → REUSE | — |
| F067 | changelog section type mapping (visible vs hidden) | release-versioning | DIVERGENT | R24 |
| F068 | changelog file preamble | release-versioning | ADOPT | — |
| F069 | release PR title customization | release-versioning | COMMON → REUSE | — |
| F070 | pre-1.0 semver bump strategy | release-versioning | DIVERGENT | R25 |
| F072 | release-please auth token mechanism | release-versioning | COMMON → REUSE | — |
| F073 | release trigger (push opens PR, merge tags) | release-versioning | COMMON → REUSE | — |
| F074 | publish workflow tag/version consistency guard | release-versioning | COMMON → REUSE | — |
| F075 | OIDC Trusted Publishing (no stored publish token) | release-versioning | COMMON → REUSE | — |
| F077 | protected environment gate before publish | release-versioning | COMMON → REUSE | — |
| F078 | packed-artifact content guard in publish workflow | release-versioning | DIVERGENT | R26 |
| F079 | release version-surface drift-check recipe | release-versioning | ADOPT | — |
| F080 | CLI version-check recipe | release-versioning | COMMON → REUSE | — |
| F081 | release runbook / setup doc | release-versioning | COMMON → REUSE | — |
| F083 | one linter and one formatter run in CI and via the git-hook manager | lint-format | COMMON → REUSE | — |
| F084 | primary code formatter tool | lint-format | DIVERGENT | R27 |
| F085 | primary code linter tool | lint-format | DIVERGENT | R28 |
| F086 | linter rule-selection mechanism | lint-format | DIVERGENT | R28 |
| F087 | formatter max line width | lint-format | DIVERGENT | R27 |
| F088 | formatter quote style | lint-format | OMIT | — |
| F089 | formatter line-ending normalization | lint-format | DIVERGENT | R27 |
| F090 | formatter semicolon insertion | lint-format | OMIT | — |
| F091 | formatter trailing-comma style | lint-format | DIVERGENT | R27 |
| F092 | import-sorting ownership | lint-format | DIVERGENT | R27 |
| F093 | linter default autofix behavior | lint-format | DIVERGENT | R28 |
| F094 | per-context lint relaxation for test files | lint-format | DIVERGENT | R28 |
| F096 | security-rule coverage via the linter | lint-format | DIVERGENT | R28 |
| F098 | YAML formatting ownership | lint-format | DIVERGENT | R29 |
| F099 | JSON and Markdown formatting coverage | lint-format | DIVERGENT | R29 |
| F100 | formatter/linter exclude-list configuration scope | lint-format | DIVERGENT | R27 |
| F101 | editor extension recommendation for lint/format | lint-format | DIVERGENT | R28 |
| F102 | composite recipe bundling format/lint/typecheck/test | lint-format | DIVERGENT | R27 |
| F103 | lint/format tool version-pinning strategy | lint-format | DIVERGENT | R27 |
| F104 | pre-commit formatter hook mode (check vs. write) | lint-format | DIVERGENT | R27 |
| F105 | primary type-checker tool | static-analysis | DIVERGENT | R30 |
| F106 | type-checker hook-tier placement | static-analysis | DIVERGENT | R30 |
| F107 | single type-checker engine serving both CI and the editor | static-analysis | DIVERGENT | R30 |
| F110 | type-checker opt-in quality-rule / strictness configuration | static-analysis | DIVERGENT | R30 |
| F113 | type-check gate scope: whether tests are included | static-analysis | DIVERGENT | R30 |
| F117 | test runner tool | testing-coverage | DIVERGENT | R32 |
| F118 | CLI test tiers (in-process vs. built-binary) | testing-coverage | DIVERGENT | R32 |
| F119 | mock/test-double library | testing-coverage | DIVERGENT | R48 |
| F120 | HTTP transport mocking mechanism in tests | testing-coverage | DIVERGENT | R48 |
| F127 | advisory alternate JS runtime test lane | testing-coverage | DIVERGENT | R34 |
| F129 | test file organization (subdirected vs. flat) | testing-coverage | DIVERGENT | R32 |
| F133 | test asserting the version stays single-sourced across manifests | testing-coverage | COMMON → REUSE | — |
| F134 | coverage tool | testing-coverage | DIVERGENT | R35 |
| F135 | coverage instrumentation scope and exclusions | testing-coverage | DIVERGENT | R35 |
| F136 | coverage threshold definition location and values | testing-coverage | DIVERGENT | R35 |
| F137 | coverage gate enforcement in CI | testing-coverage | DIVERGENT | R35 |
| F141 | meta-tests validating tooling-config internal consistency | testing-coverage | COMMON → REUSE | — |
| F142 | git hook manager tool | git-hooks-commit-hygiene | COMMON → REUSE | — |
| F143 | lefthook distribution/install mechanism | git-hooks-commit-hygiene | DIVERGENT | R37 |
| F144 | hook-wiring trigger mechanism | git-hooks-commit-hygiene | DIVERGENT | R37 |
| F145 | manual hook re-wire recipe | git-hooks-commit-hygiene | COMMON → REUSE | — |
| F146 | pre-commit stage jobs execute in parallel | git-hooks-commit-hygiene | COMMON → REUSE | — |
| F147 | hook staging tiering (fast staged checks at commit, slower full-tree checks deferred later) | git-hooks-commit-hygiene | COMMON → REUSE | — |
| F148 | commit-message linting enforced at commit-msg hook time (pattern) | git-hooks-commit-hygiene | COMMON → REUSE | — |
| F149 | commit-msg linter tool | git-hooks-commit-hygiene | COMMON → SUBSTITUTE | R38 |
| F150 | commit-msg hook invocation mechanism | git-hooks-commit-hygiene | DIVERGENT | R38 |
| F151 | commitlint base config | git-hooks-commit-hygiene | COMMON → SUBSTITUTE | R38 |
| F152 | commit subject (header) max length override | git-hooks-commit-hygiene | DIVERGENT | R38 |
| F153 | commit body max line-length override | git-hooks-commit-hygiene | DIVERGENT | R38 |
| F155 | commit type-enum restriction | git-hooks-commit-hygiene | DIVERGENT | R38 |
| F158 | commit-message template file | git-hooks-commit-hygiene | ADOPT | — |
| F159 | commit-message template wired via git config | git-hooks-commit-hygiene | ADOPT | — |
| F160 | commit-message template/commitlint type-list consistency, enforced by test | git-hooks-commit-hygiene | ADOPT | — |
| F161 | lefthook config internal-consistency, enforced by test | git-hooks-commit-hygiene | ADOPT | — |
| F162 | lefthook per-job exclude-list mirrors the linter/formatter ignore config, enforced by test | git-hooks-commit-hygiene | DIVERGENT | R27 |
| F172 | large-file size guard hook | git-hooks-commit-hygiene | DIVERGENT | R14 |
| F173 | full test-suite execution as a git hook | git-hooks-commit-hygiene | DIVERGENT | R32 |
| F174 | CI job aggregating every hook-suite check for full-tree dual enforcement | git-hooks-commit-hygiene | DIVERGENT | R37 |
| F175 | local recipe to re-run the pre-commit hook suite against the whole tree | git-hooks-commit-hygiene | COMMON → REUSE | — |
| F176 | task-runner tool | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F177 | recipe grouping via attributes | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F178 | recipe short aliases | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F179 | two-level bootstrap split (Makefile=toolchain, Justfile=dev tasks) | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F180 | `make check` verifies base toolchain present | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F181 | `just check-deps` verifies full dev toolchain with per-tool remediation | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F184 | `make install-*` print-first command + separate `-force` variant | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F185 | dependency-free environment diagnostic recipe ("doctor" report) | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F190 | toolchain version pin-file convention | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F193 | VS Code recommended-extensions list | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F194 | VS Code debug (`launch.json`) config for the CLI (pattern: committed debug configuration) | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F195 | VS Code debugger tool/extension for the CLI | dev-experience-repo-hygiene | COMMON → SUBSTITUTE | R28 |
| F196 | committed `.vscode/settings.json` pinning the editor's language-service version | dev-experience-repo-hygiene | DIVERGENT | R28 |
| F197 | AI-agent instruction hub (single canonical file + thin per-tool import) | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F198 | vendor-specific AI-editor rule files (Cursor/Windsurf) | dev-experience-repo-hygiene | DIVERGENT | R43 |
| F199 | repo-welcome startup announcement | dev-experience-repo-hygiene | DIVERGENT | R43 |
| F201 | issue-template set structure (typed templates + blank-disabled config) | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F202 | issue-template label schema | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F203 | PR template pre-flight checklist | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F205 | FUNDING.yml | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F206 | root LICENSE file | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F207 | per-file embedded license header | dev-experience-repo-hygiene | DIVERGENT | R46 |
| F208 | CLA program (texts, FAQ, setup guide, hosted bot) | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F209 | contributors-render config schema (`.contributors.yml` + `.contributors.jsonl` ledger) | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F210 | local Justfile recipe's subcommand vs. the CI bot's action mode | dev-experience-repo-hygiene | DIVERGENT | R47 |
| F211 | build backend/bundler produces the distributable package (pattern) | packaging-distribution | COMMON → REUSE | — |
| F212 | build backend/bundler tool | packaging-distribution | COMMON → SUBSTITUTE | R49 |
| F213 | build entry-point declaration | packaging-distribution | DIVERGENT | R49 |
| F214 | distributable artifact types | packaging-distribution | DIVERGENT | R68 |
| F215 | dual CJS/ESM vs ESM-only output | packaging-distribution | OMIT | — |
| F216 | console-script / bin entry declaration | packaging-distribution | DIVERGENT | R49 |
| F217 | CLI executable invocation mechanism | packaging-distribution | OMIT | — |
| F218 | packaged-file whitelist mechanism | packaging-distribution | DIVERGENT | R49 |
| F219 | distribution-name vs entry-point-name divergence | packaging-distribution | DIVERGENT | R49 |
| F221 | CI-wired build-and-install smoke test cadence | packaging-distribution | DIVERGENT | R50 |
| F224 | config file format | config-env-logging | COMMON → REUSE | — |
| F225 | TOML parse library | config-env-logging | DIVERGENT | R52 |
| F226 | TOML write library | config-env-logging | DIVERGENT | R52 |
| F227 | config file naming convention (`<tool>_config.toml`) | config-env-logging | COMMON → REUSE | — |
| F228 | config schema validation library | config-env-logging | DIVERGENT | R53 |
| F229 | typed config schema with per-key validation | config-env-logging | COMMON → REUSE | — |
| F233 | `--config` flag replaces discovery entirely | config-env-logging | COMMON → REUSE | — |
| F235 | explicit `--config` pointing at a missing file | config-env-logging | DIVERGENT | R55 |
| F237 | unparsable *explicit* config file raises loudly | config-env-logging | COMMON → REUSE | — |
| F239 | config file secrets rule | config-env-logging | DIVERGENT | R56 |
| F240 | token resolution precedence | config-env-logging | DIVERGENT | R56 |
| F241 | token env var name | config-env-logging | COMMON → REUSE | — |
| F242 | empty-string env/flag token treated as unset | config-env-logging | COMMON → REUSE | — |
| F243 | config file written with restrictive permissions | config-env-logging | COMMON → REUSE | — |
| F244 | Windows write-permission handling | config-env-logging | OMIT | — |
| F245 | non-fatal warning for a loosely-permissioned on-disk config file | config-env-logging | DIVERGENT | R56 |
| F246 | secret masking for display | config-env-logging | COMMON → REUSE | — |
| F247 | XDG override mechanism (env var must be set, non-empty, absolute) | config-env-logging | COMMON → REUSE | — |
| F248 | config directory default on Windows | config-env-logging | OMIT | — |
| F264 | CLI framework/parsing library | cli-framework-ux | DIVERGENT | R60 |
| F265 | Command surface shape: noun-verb subcommand groups vs. one default command | cli-framework-ux | DIVERGENT | R60 |
| F266 | `-V`/`--version` flag | cli-framework-ux | COMMON → REUSE | — |
| F270 | Global options stackable on every (sub)command | cli-framework-ux | DIVERGENT | R60 |
| F271 | Did-you-mean suggestion on an unknown command | cli-framework-ux | COMMON → REUSE | — |
| F272 | Did-you-mean matching implementation | cli-framework-ux | DIVERGENT | R60 |
| F273 | Repeatable `-v`/`--verbose` flag | cli-framework-ux | COMMON → REUSE | — |
| F274 | Verbosity-to-log-level resolution ladder | cli-framework-ux | DIVERGENT | R58 |
| F275 | `--no-input` flag disables interactive prompting | cli-framework-ux | COMMON → REUSE | — |
| F280 | Interactive multi-select prompt over fetched results | cli-framework-ux | DIVERGENT | R61 |
| F281 | Clipboard-copy flag for command results | cli-framework-ux | DIVERGENT | R62 |
| F282 | Clipboard write with headless-degrade handling | cli-framework-ux | DIVERGENT | R62 |
| F283 | Progress spinner during network fetch | cli-framework-ux | DIVERGENT | R63 |
| F286 | `--no-color` flag | cli-framework-ux | COMMON → REUSE | — |
| F287 | Color enablement precedence chain | cli-framework-ux | DIVERGENT | R65 |
| F288 | `FORCE_COLOR` env var forces color on | cli-framework-ux | DIVERGENT | R65 |
| F289 | Color gated once for both streams vs. per-stream on stderr only | cli-framework-ux | DIVERGENT | R65 |
| F290 | TTY detection mechanism gating interactive behavior | cli-framework-ux | DIVERGENT | R65 |
| F291 | Output-format choices | cli-framework-ux | DIVERGENT | R66 |
| F292 | `--json` shorthand flag | cli-framework-ux | COMMON → REUSE | — |
| F293 | Result-to-file redirection flag | cli-framework-ux | DIVERGENT | R66 |
| F294 | JSON machine-readable error envelope on stderr | cli-framework-ux | COMMON → REUSE | — |
| F295 | Error-envelope "code" field source | cli-framework-ux | DIVERGENT | R67 |
| F297 | Exit-code taxonomy | cli-framework-ux | DIVERGENT | R67 |
| F298 | Process-interrupt (Ctrl-C) exit-code contract | cli-framework-ux | DIVERGENT | R67 |
| F299 | Interactive-prompt cancellation (^C mid-prompt) | cli-framework-ux | DIVERGENT | R67 |
| F300 | Broken-pipe (EPIPE) handling | cli-framework-ux | DIVERGENT | R67 |
| F301 | Unexpected-error stack trace shown to the user only under verbose/debug | cli-framework-ux | COMMON → REUSE | — |
| F341 | docs delivery model | docs-system | DIVERGENT | R81 |
| F342 | documentation information architecture | docs-system | COMMON → REUSE | — |
| F343 | markdown dialect | docs-system | DIVERGENT | R81 |
| F344 | section navigation mechanism | docs-system | DIVERGENT | R81 |
| F345 | root-README vs. site-landing-page duplication | docs-system | DIVERGENT | R81 |
| F346 | root README "documentation" pointer | docs-system | DIVERGENT | R81 |
| F347 | documentation authoring guide (how to add a page) | docs-system | COMMON → REUSE | — |
| F348 | doc content correctness gate | docs-system | DIVERGENT | R82 |
| F349 | offline relative-link checker tool | docs-system | DIVERGENT | R82 |
| F353 | API reference doc generator | docs-system | DIVERGENT | R82 |
| F358 | documented (unshipped) future docs-site upgrade path | docs-system | ADOPT | — |
