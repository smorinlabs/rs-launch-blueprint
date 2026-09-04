# py-launch-blueprint inventory (derived from COMMONALITY.md — do not edit)

| ID | Feature | Area | Verdict | Item |
|---|---|---|---|---|
| F001 | Ports abstraction for the driven I/O seam | workspace-architecture | DIVERGENT | R01 |
| F002 | Composition root wiring a port to a concrete adapter | workspace-architecture | DIVERGENT | R01 |
| F003 | Composition root importable only by front-ends, never by core | workspace-architecture | DIVERGENT | R02 |
| F004 | Core forbidden from importing the front-ends (inward-only dependency direction) | workspace-architecture | DIVERGENT | R02 |
| F005 | Front-ends (CLI, web) forbidden from importing each other | workspace-architecture | DIVERGENT | R02 |
| F006 | Core internal layering (domain models below services below adapters) | workspace-architecture | DIVERGENT | R02 |
| F007 | Architectural boundaries enforced mechanically rather than by convention | workspace-architecture | DIVERGENT | R02 |
| F008 | Framework-bleed guard, authoritative (core may not import CLI/web frameworks) | workspace-architecture | DIVERGENT | R02 |
| F009 | Framework-bleed guard, fast local mirror | workspace-architecture | DIVERGENT | R02 |
| F010 | Bounded-context module dependency graph, declared and checked | workspace-architecture | DIVERGENT | R02 |
| F011 | Adapter satisfies a port structurally, verified by the type checker | workspace-architecture | DIVERGENT | R01 |
| F012 | Port absence-vs-failure contract | workspace-architecture | DIVERGENT | R03 |
| F013 | First-class in-memory/fake adapter shipped in the package (not test-only) | workspace-architecture | DIVERGENT | R01 |
| F014 | Public library API surface, curated re-export list | workspace-architecture | COMMON → REUSE | — |
| F015 | Public-surface enforcement mechanism | workspace-architecture | DIVERGENT | R04 |
| F016 | Sync/async execution model for the I/O boundary | workspace-architecture | DIVERGENT | R05 |
| F017 | Web service as an optional, separately installed capability | workspace-architecture | ADOPT | — |
| F018 | Web layer as a thin adapter reusing the CLI's data contract | workspace-architecture | DIVERGENT | R01 |
| F019 | Source code lives under a top-level `src/` directory | workspace-architecture | COMMON → REUSE | — |
| F020 | Package namespacing within `src/` | workspace-architecture | DIVERGENT | R02 |
| F024 | CI trigger: push and PR to main | ci-workflows | COMMON → REUSE | — |
| F025 | merge_group trigger so required checks report in the GitHub merge queue | ci-workflows | ADOPT | — |
| F026 | Contributors-bot workflow trigger cadence | ci-workflows | DIVERGENT | R07 |
| F027 | CodeQL gated to public repos via a runtime visibility check | ci-workflows | COMMON → REUSE | — |
| F028 | Top-level deny-all permissions baseline with per-job least-privilege grants | ci-workflows | COMMON → REUSE | — |
| F029 | Checkout credential-persistence hardening (persist-credentials: false) | ci-workflows | DIVERGENT | R08 |
| F030 | Contributors-bot workflow permission declaration style | ci-workflows | DIVERGENT | R08 |
| F031 | Runner OS selection overridable via repo vars with self-hosted fallback | ci-workflows | DIVERGENT | R09 |
| F032 | Multi-OS test matrix (ubuntu, macOS, windows) | ci-workflows | ADOPT | — |
| F033 | Runtime-version matrix is a two-entry floor-plus-next set | ci-workflows | COMMON → REUSE | — |
| F034 | Matrix job uses fail-fast: false to surface every leg's failure | ci-workflows | COMMON → REUSE | — |
| F035 | Dependency caching integrated into the language-setup step (pattern) | ci-workflows | COMMON → REUSE | — |
| F036 | Dependency caching built into the language-setup action (tool) | ci-workflows | COMMON → SUBSTITUTE | R10 |
| F038 | Consolidated lint workflow (actionlint, yamllint, bandit, codespell, editorconfig-check) with path-filtered skip | ci-workflows | DIVERGENT | R11 |
| F040 | A changes-detector job skips heavy jobs on docs-only PRs | ci-workflows | DIVERGENT | R11 |
| F041 | Single aggregate required-status-check job folding in all other job results | ci-workflows | DIVERGENT | R12 |
| F042 | Scheduled full-dependency-graph vulnerability audit | ci-workflows | DIVERGENT | R13 |
| F043 | Large-file size guard on new files | ci-workflows | DIVERGENT | R14 |
| F044 | Template drift/receipt guard workflows | ci-workflows | DIVERGENT | R15 |
| F045 | CodeQL custom config file (query pack selection plus paths-ignore) | ci-workflows | DIVERGENT | R16 |
| F046 | Dependency-review PR gate | ci-workflows | COMMON → REUSE | — |
| F047 | Manual, environment-gated PR security scan (workflow_dispatch) | ci-workflows | COMMON → REUSE | — |
| F048 | Manual security-scan tool | ci-workflows | DIVERGENT | R13 |
| F050 | Dedicated secret-scanning CI workflow | ci-workflows | DIVERGENT | R17 |
| F051 | AI-assisted PR code review workflow | ci-workflows | DIVERGENT | R18 |
| F052 | AI assistant workflow triggered by @mention comments | ci-workflows | DIVERGENT | R18 |
| F053 | Dependabot ecosystems configured | ci-workflows | DIVERGENT | R19 |
| F054 | Dependabot update grouping strategy | ci-workflows | DIVERGENT | R19 |
| F055 | Third-party GitHub Action pinning policy | ci-workflows | DIVERGENT | R20 |
| F056 | actionlint config: self-hosted runner labels declared | ci-workflows | DIVERGENT | R09 |
| F057 | actionlint config: RUNNER_* config-variables declared | ci-workflows | DIVERGENT | R09 |
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
| F069 | release PR title customization | release-versioning | COMMON → REUSE | — |
| F071 | release-please bootstrap-sha pin | release-versioning | ADOPT | — |
| F072 | release-please auth token mechanism | release-versioning | COMMON → REUSE | — |
| F073 | release trigger (push opens PR, merge tags) | release-versioning | COMMON → REUSE | — |
| F074 | publish workflow tag/version consistency guard | release-versioning | COMMON → REUSE | — |
| F075 | OIDC Trusted Publishing (no stored publish token) | release-versioning | COMMON → REUSE | — |
| F076 | staged publish to test registry before production | release-versioning | OMIT | — |
| F077 | protected environment gate before publish | release-versioning | COMMON → REUSE | — |
| F080 | CLI version-check recipe | release-versioning | COMMON → REUSE | — |
| F081 | release runbook / setup doc | release-versioning | COMMON → REUSE | — |
| F082 | documented opt-out from automated releases | release-versioning | ADOPT | — |
| F083 | one linter and one formatter run in CI and via the git-hook manager | lint-format | COMMON → REUSE | — |
| F084 | primary code formatter tool | lint-format | DIVERGENT | R27 |
| F085 | primary code linter tool | lint-format | DIVERGENT | R28 |
| F086 | linter rule-selection mechanism | lint-format | DIVERGENT | R28 |
| F087 | formatter max line width | lint-format | DIVERGENT | R27 |
| F088 | formatter quote style | lint-format | OMIT | — |
| F089 | formatter line-ending normalization | lint-format | DIVERGENT | R27 |
| F092 | import-sorting ownership | lint-format | DIVERGENT | R27 |
| F093 | linter default autofix behavior | lint-format | DIVERGENT | R28 |
| F094 | per-context lint relaxation for test files | lint-format | DIVERGENT | R28 |
| F095 | per-file ignore for package `__init__.py` | lint-format | OMIT | — |
| F096 | security-rule coverage via the linter | lint-format | DIVERGENT | R28 |
| F097 | TOML formatter as a separate tool | lint-format | DIVERGENT | R29 |
| F098 | YAML formatting ownership | lint-format | DIVERGENT | R29 |
| F100 | formatter/linter exclude-list configuration scope | lint-format | DIVERGENT | R27 |
| F101 | editor extension recommendation for lint/format | lint-format | DIVERGENT | R28 |
| F102 | composite recipe bundling format/lint/typecheck/test | lint-format | DIVERGENT | R27 |
| F103 | lint/format tool version-pinning strategy | lint-format | DIVERGENT | R27 |
| F104 | pre-commit formatter hook mode (check vs. write) | lint-format | DIVERGENT | R27 |
| F105 | primary type-checker tool | static-analysis | DIVERGENT | R30 |
| F106 | type-checker hook-tier placement | static-analysis | DIVERGENT | R30 |
| F108 | dedicated IDE-only type checker distinct from the CI-authoritative one | static-analysis | DIVERGENT | R30 |
| F109 | type-checker editor-extension recommendation | static-analysis | DIVERGENT | R28 |
| F110 | type-checker opt-in quality-rule / strictness configuration | static-analysis | DIVERGENT | R30 |
| F111 | type-checker suppression-comment discipline | static-analysis | DIVERGENT | R30 |
| F112 | type-checker warning-vs-error severity tier | static-analysis | DIVERGENT | R30 |
| F113 | type-check gate scope: whether tests are included | static-analysis | DIVERGENT | R30 |
| F114 | dedicated AST-based security scanner beyond the linter's built-in security rules | static-analysis | DIVERGENT | R31 |
| F115 | security scanner hook-tier placement | static-analysis | DIVERGENT | R31 |
| F116 | architectural-boundary check hook-tier placement | static-analysis | DIVERGENT | R02 |
| F117 | test runner tool | testing-coverage | DIVERGENT | R32 |
| F118 | CLI test tiers (in-process vs. built-binary) | testing-coverage | DIVERGENT | R32 |
| F119 | mock/test-double library | testing-coverage | DIVERGENT | R48 |
| F120 | HTTP transport mocking mechanism in tests | testing-coverage | DIVERGENT | R48 |
| F121 | port-contract substitutability suite (fake vs. real adapter parity) | testing-coverage | DIVERGENT | R01 |
| F122 | property-based (generative) testing | testing-coverage | DIVERGENT | R33 |
| F123 | CLI golden-snapshot testing | testing-coverage | DIVERGENT | R33 |
| F124 | randomized test execution order | testing-coverage | DIVERGENT | R32 |
| F125 | per-test timeout enforcement | testing-coverage | DIVERGENT | R32 |
| F126 | scheduled dependency-freshness canary run | testing-coverage | DIVERGENT | R34 |
| F128 | shared cross-test fixture file (autouse setup) | testing-coverage | DIVERGENT | R32 |
| F129 | test file organization (subdirected vs. flat) | testing-coverage | DIVERGENT | R32 |
| F130 | opt-in test marker taxonomy (skip slow/live by default) | testing-coverage | DIVERGENT | R32 |
| F131 | opt-in parallel test execution flag | testing-coverage | DIVERGENT | R32 |
| F133 | test asserting the version stays single-sourced across manifests | testing-coverage | COMMON → REUSE | — |
| F134 | coverage tool | testing-coverage | DIVERGENT | R35 |
| F135 | coverage instrumentation scope and exclusions | testing-coverage | DIVERGENT | R35 |
| F136 | coverage threshold definition location and values | testing-coverage | DIVERGENT | R35 |
| F137 | coverage gate enforcement in CI | testing-coverage | DIVERGENT | R35 |
| F138 | coverage report output formats | testing-coverage | DIVERGENT | R35 |
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
| F153 | commit body max line-length override | git-hooks-commit-hygiene | DIVERGENT | R38 |
| F154 | commit footer max line-length override | git-hooks-commit-hygiene | DIVERGENT | R38 |
| F156 | per-author relaxed commit-lint ruleset for bot PRs | git-hooks-commit-hygiene | DIVERGENT | R38 |
| F157 | commit-message linting re-run in CI (beyond the local hook) | git-hooks-commit-hygiene | DIVERGENT | R38 |
| F163 | staged secret-scanning hook | git-hooks-commit-hygiene | DIVERGENT | R39 |
| F164 | pre-push range secret-scanning hook | git-hooks-commit-hygiene | DIVERGENT | R39 |
| F165 | secret-scanner allowlist configuration | git-hooks-commit-hygiene | DIVERGENT | R39 |
| F166 | secret-scanner fingerprint suppression file | git-hooks-commit-hygiene | DIVERGENT | R39 |
| F167 | whitespace/EOL/format-validity hygiene linter (pre-commit) | git-hooks-commit-hygiene | DIVERGENT | R40 |
| F168 | YAML lint hook | git-hooks-commit-hygiene | DIVERGENT | R40 |
| F169 | spell-check hook | git-hooks-commit-hygiene | DIVERGENT | R40 |
| F170 | GitHub Actions workflow syntax lint hook | git-hooks-commit-hygiene | DIVERGENT | R40 |
| F171 | dependency-manifest lockfile-freshness check hook | git-hooks-commit-hygiene | DIVERGENT | R41 |
| F172 | large-file size guard hook | git-hooks-commit-hygiene | DIVERGENT | R14 |
| F175 | local recipe to re-run the pre-commit hook suite against the whole tree | git-hooks-commit-hygiene | COMMON → REUSE | — |
| F176 | task-runner tool | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F177 | recipe grouping via attributes | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F178 | recipe short aliases | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F179 | two-level bootstrap split (Makefile=toolchain, Justfile=dev tasks) | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F180 | `make check` verifies base toolchain present | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F181 | `just check-deps` verifies full dev toolchain with per-tool remediation | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F182 | Level-2 setup gates on Level-1 bootstrap completion | dev-experience-repo-hygiene | ADOPT | — |
| F183 | per-tool binary installer recipes for tools outside the primary package manager | dev-experience-repo-hygiene | DIVERGENT | R42 |
| F184 | `make install-*` print-first command + separate `-force` variant | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F185 | dependency-free environment diagnostic recipe ("doctor" report) | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F186 | hook-toolchain readiness check (doctor for git-hook tools) | dev-experience-repo-hygiene | ADOPT | — |
| F187 | declarative toolchain-provisioner manifest: mise | dev-experience-repo-hygiene | DIVERGENT | R42 |
| F188 | declarative toolchain-provisioner manifest: flox | dev-experience-repo-hygiene | DIVERGENT | R42 |
| F189 | three toolchain provisioners kept in manual sync (native + mise + flox) | dev-experience-repo-hygiene | DIVERGENT | R42 |
| F190 | toolchain version pin-file convention | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F191 | cross-editor formatting baseline file | dev-experience-repo-hygiene | DIVERGENT | R40 |
| F192 | documented per-filetype `.editorconfig` exceptions | dev-experience-repo-hygiene | DIVERGENT | R40 |
| F193 | VS Code recommended-extensions list | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F194 | VS Code debug (`launch.json`) config for the CLI (pattern: committed debug configuration) | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F195 | VS Code debugger tool/extension for the CLI | dev-experience-repo-hygiene | COMMON → SUBSTITUTE | R28 |
| F197 | AI-agent instruction hub (single canonical file + thin per-tool import) | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F200 | devcontainer (base image, postCreate bootstrap, in-container VS Code config) | dev-experience-repo-hygiene | DIVERGENT | R44 |
| F201 | issue-template set structure (typed templates + blank-disabled config) | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F202 | issue-template label schema | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F203 | PR template pre-flight checklist | dev-experience-repo-hygiene | COMMON → REUSE | — |
| F204 | PR-comment bot re-review trigger block | dev-experience-repo-hygiene | DIVERGENT | R45 |
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
| F216 | console-script / bin entry declaration | packaging-distribution | DIVERGENT | R49 |
| F217 | CLI executable invocation mechanism | packaging-distribution | OMIT | — |
| F218 | packaged-file whitelist mechanism | packaging-distribution | DIVERGENT | R49 |
| F219 | distribution-name vs entry-point-name divergence | packaging-distribution | DIVERGENT | R49 |
| F220 | documented end-user install method | packaging-distribution | ADOPT | — |
| F221 | CI-wired build-and-install smoke test cadence | packaging-distribution | DIVERGENT | R50 |
| F222 | ephemeral wheel/sdist install-and-run smoke test | packaging-distribution | DIVERGENT | R50 |
| F223 | container image as a distribution artifact | packaging-distribution | DIVERGENT | R51 |
| F224 | config file format | config-env-logging | COMMON → REUSE | — |
| F225 | TOML parse library | config-env-logging | DIVERGENT | R52 |
| F226 | TOML write library | config-env-logging | DIVERGENT | R52 |
| F227 | config file naming convention (`<tool>_config.toml`) | config-env-logging | COMMON → REUSE | — |
| F228 | config schema validation library | config-env-logging | DIVERGENT | R53 |
| F229 | typed config schema with per-key validation | config-env-logging | COMMON → REUSE | — |
| F230 | layered config discovery (system → user → project, later wins) | config-env-logging | DIVERGENT | R54 |
| F231 | system-wide config directory (`$XDG_CONFIG_DIRS`/`%PROGRAMDATA%`) | config-env-logging | DIVERGENT | R54 |
| F232 | project-local config file discovery (`./<tool>_config.toml`, dotfile preferred) | config-env-logging | DIVERGENT | R54 |
| F233 | `--config` flag replaces discovery entirely | config-env-logging | COMMON → REUSE | — |
| F234 | `--config` env-var alias | config-env-logging | DIVERGENT | R54 |
| F235 | explicit `--config` pointing at a missing file | config-env-logging | DIVERGENT | R55 |
| F236 | unparsable *discovered* config layer degrades to a warning, not a crash | config-env-logging | DIVERGENT | R55 |
| F237 | unparsable *explicit* config file raises loudly | config-env-logging | COMMON → REUSE | — |
| F238 | invalid config *values* (right TOML, wrong value) degrade to a warning and are dropped | config-env-logging | DIVERGENT | R55 |
| F239 | config file secrets rule | config-env-logging | DIVERGENT | R56 |
| F240 | token resolution precedence | config-env-logging | DIVERGENT | R56 |
| F241 | token env var name | config-env-logging | COMMON → REUSE | — |
| F242 | empty-string env/flag token treated as unset | config-env-logging | COMMON → REUSE | — |
| F243 | config file written with restrictive permissions | config-env-logging | COMMON → REUSE | — |
| F246 | secret masking for display | config-env-logging | COMMON → REUSE | — |
| F247 | XDG override mechanism (env var must be set, non-empty, absolute) | config-env-logging | COMMON → REUSE | — |
| F248 | config directory default on Windows | config-env-logging | OMIT | — |
| F249 | separate XDG-style data/state/cache directories beyond config | config-env-logging | DIVERGENT | R57 |
| F250 | console log format auto-selects JSON vs. human text from TTY-ness | config-env-logging | DIVERGENT | R58 |
| F251 | structured (key/value) logging pipeline | config-env-logging | DIVERGENT | R58 |
| F252 | key-based secret redaction in log output | config-env-logging | DIVERGENT | R58 |
| F253 | trace/span correlation in logs (OpenTelemetry) | config-env-logging | DIVERGENT | R58 |
| F254 | explicit console log-level flag/env (`--log-level`/`PLBP_LOG_LEVEL`) | config-env-logging | DIVERGENT | R58 |
| F255 | `[logging]` table in the config file (level/file/file_level/format defaults) | config-env-logging | DIVERGENT | R59 |
| F256 | optional rotating file log sink | config-env-logging | DIVERGENT | R59 |
| F257 | file log sink rotation policy (size + backup count) | config-env-logging | DIVERGENT | R59 |
| F258 | file sink enable flag/env (`--log-file`/`PLBP_LOG_FILE`, default XDG state path) | config-env-logging | DIVERGENT | R59 |
| F259 | file sink path precedence (flag/env > config `logging.file` > off) | config-env-logging | DIVERGENT | R59 |
| F260 | file sink format override via env (`PLBP_LOG_FORMAT`, validated) | config-env-logging | DIVERGENT | R59 |
| F261 | file sink independent level from the console sink (dual-sink floor) | config-env-logging | DIVERGENT | R59 |
| F262 | logging reconfiguration only tears down handlers it owns (idempotent, host-safe) | config-env-logging | DIVERGENT | R58 |
| F263 | one shared logging pipeline expressed as per-front-end policy profiles | config-env-logging | DIVERGENT | R58 |
| F264 | CLI framework/parsing library | cli-framework-ux | DIVERGENT | R60 |
| F265 | Command surface shape: noun-verb subcommand groups vs. one default command | cli-framework-ux | DIVERGENT | R60 |
| F266 | `-V`/`--version` flag | cli-framework-ux | COMMON → REUSE | — |
| F267 | Extended version output (runtime/platform info) | cli-framework-ux | DIVERGENT | R60 |
| F268 | Shell completion script generation command | cli-framework-ux | DIVERGENT | R60 |
| F269 | Blanket env-var binding for every global option | cli-framework-ux | DIVERGENT | R60 |
| F270 | Global options stackable on every (sub)command | cli-framework-ux | DIVERGENT | R60 |
| F271 | Did-you-mean suggestion on an unknown command | cli-framework-ux | COMMON → REUSE | — |
| F272 | Did-you-mean matching implementation | cli-framework-ux | DIVERGENT | R60 |
| F273 | Repeatable `-v`/`--verbose` flag | cli-framework-ux | COMMON → REUSE | — |
| F274 | Verbosity-to-log-level resolution ladder | cli-framework-ux | DIVERGENT | R58 |
| F275 | `--no-input` flag disables interactive prompting | cli-framework-ux | COMMON → REUSE | — |
| F276 | Interactive yes/no confirmation prompt for destructive actions | cli-framework-ux | DIVERGENT | R61 |
| F277 | `--dry-run` mutation-safety flag | cli-framework-ux | ADOPT | — |
| F278 | `-y`/`--yes` mutation-safety flag | cli-framework-ux | ADOPT | — |
| F279 | Interactive guided value prompt (config init) | cli-framework-ux | DIVERGENT | R61 |
| F284 | Text-mode output paged through the user's pager | cli-framework-ux | DIVERGENT | R64 |
| F285 | Pager command resolution precedence | cli-framework-ux | DIVERGENT | R64 |
| F286 | `--no-color` flag | cli-framework-ux | COMMON → REUSE | — |
| F287 | Color enablement precedence chain | cli-framework-ux | DIVERGENT | R65 |
| F289 | Color gated once for both streams vs. per-stream on stderr only | cli-framework-ux | DIVERGENT | R65 |
| F290 | TTY detection mechanism gating interactive behavior | cli-framework-ux | DIVERGENT | R65 |
| F291 | Output-format choices | cli-framework-ux | DIVERGENT | R66 |
| F292 | `--json` shorthand flag | cli-framework-ux | COMMON → REUSE | — |
| F293 | Result-to-file redirection flag | cli-framework-ux | DIVERGENT | R66 |
| F294 | JSON machine-readable error envelope on stderr | cli-framework-ux | COMMON → REUSE | — |
| F295 | Error-envelope "code" field source | cli-framework-ux | DIVERGENT | R67 |
| F296 | Structured `hint` field on an error, rendered separately from the message | cli-framework-ux | DIVERGENT | R67 |
| F297 | Exit-code taxonomy | cli-framework-ux | DIVERGENT | R67 |
| F298 | Process-interrupt (Ctrl-C) exit-code contract | cli-framework-ux | DIVERGENT | R67 |
| F301 | Unexpected-error stack trace shown to the user only under verbose/debug | cli-framework-ux | COMMON → REUSE | — |
| F302 | Unexpected errors persisted to a crash log file | cli-framework-ux | DIVERGENT | R67 |
| F303 | web service exists at all | web-service | DIVERGENT | R69 |
| F304 | tracing dependencies are a further, separate optional extra | web-service | ADOPT | — |
| F305 | single RFC 9457 error envelope for every non-2xx response | web-service | DIVERGENT | R70 |
| F306 | domain-error-to-HTTP-status mapping table | web-service | DIVERGENT | R70 |
| F307 | OpenAPI schema is post-processed to match the runtime error shape | web-service | DIVERGENT | R71 |
| F308 | business routes are version-prefixed; ops endpoints are not | web-service | ADOPT | — |
| F309 | route deprecation signaling helper | web-service | ADOPT | — |
| F310 | collection pagination via page/size query params and items/total envelope | web-service | DIVERGENT | R72 |
| F311 | pagination is wired app-wide via one factory call | web-service | DIVERGENT | R72 |
| F312 | OpenAPI operation ids are curated as stable `tag-function` names | web-service | DIVERGENT | R71 |
| F313 | unsafe-method requests replay a cached response via `Idempotency-Key` | web-service | DIVERGENT | R73 |
| F314 | idempotency cache only stores successful (2xx) outcomes | web-service | DIVERGENT | R73 |
| F315 | idempotency cache store is in-memory, single-instance by design | web-service | DIVERGENT | R73 |
| F316 | rate-limit store is in-memory, single-instance by design | web-service | DIVERGENT | R74 |
| F317 | middleware ordering is a contract (id/security-header middleware outermost) | web-service | DIVERGENT | R75 |
| F318 | request-id propagation through log context and response header | web-service | DIVERGENT | R75 |
| F319 | one canonical structured access-log event per request | web-service | DIVERGENT | R75 |
| F320 | probe endpoints are excluded from access-log volume | web-service | DIVERGENT | R75 |
| F321 | security response headers stamped on every response | web-service | DIVERGENT | R75 |
| F322 | CORS middleware installed only when an allowlist is configured | web-service | DIVERGENT | R76 |
| F323 | rate limiting is wired but off by default, one env var enables it | web-service | DIVERGENT | R74 |
| F324 | typed env settings with an app-derived env-var prefix | web-service | DIVERGENT | R77 |
| F325 | OpenTelemetry tracing is opt-in and soft-imported | web-service | DIVERGENT | R78 |
| F326 | Prometheus RED metrics exposed at /metrics, on by default | web-service | DIVERGENT | R79 |
| F327 | uvicorn's own loggers are folded into the shared logging pipeline | web-service | DIVERGENT | R75 |
| F328 | liveness endpoint reports version + runtime info | web-service | DIVERGENT | R80 |
| F329 | readiness endpoint runs the same diagnostics as the CLI doctor command | web-service | DIVERGENT | R80 |
| F330 | config loads once at startup, with a lazy-load fallback dependency | web-service | DIVERGENT | R69 |
| F331 | adding an API resource is one router import plus one registry entry | web-service | ADOPT | — |
| F332 | committed OpenAPI snapshot is the reviewable API contract, staleness-tested | web-service | DIVERGENT | R71 |
| F333 | breaking-change detection against the base branch in CI | web-service | DIVERGENT | R71 |
| F334 | contract fuzzing generates cases for every documented operation | web-service | DIVERGENT | R83 |
| F335 | typed client generation from the committed snapshot, never hand-written | web-service | DIVERGENT | R84 |
| F336 | production container image is a non-root multi-stage build | web-service | DIVERGENT | R51 |
| F337 | container declares its own liveness healthcheck | web-service | DIVERGENT | R51 |
| F338 | production entrypoint runs the ASGI server with settings-driven graceful shutdown | web-service | DIVERGENT | R69 |
| F339 | dev server recipe runs with auto-reload and pretty console logs | web-service | DIVERGENT | R69 |
| F340 | importing the web package without the extra installed raises an actionable error | web-service | OMIT | — |
| F341 | docs delivery model | docs-system | DIVERGENT | R81 |
| F342 | documentation information architecture | docs-system | COMMON → REUSE | — |
| F343 | markdown dialect | docs-system | DIVERGENT | R81 |
| F344 | section navigation mechanism | docs-system | DIVERGENT | R81 |
| F345 | root-README vs. site-landing-page duplication | docs-system | DIVERGENT | R81 |
| F346 | root README "documentation" pointer | docs-system | DIVERGENT | R81 |
| F347 | documentation authoring guide (how to add a page) | docs-system | COMMON → REUSE | — |
| F348 | doc content correctness gate | docs-system | DIVERGENT | R82 |
| F350 | external URL link-check | docs-system | DIVERGENT | R82 |
| F351 | local docs preview server (hot reload) | docs-system | DIVERGENT | R81 |
| F352 | docs scaffold/init recipe | docs-system | DIVERGENT | R81 |
| F353 | API reference doc generator | docs-system | DIVERGENT | R82 |
| F354 | ADR (Architecture Decision Record) system | docs-system | ADOPT | — |
| F355 | design-spec doc system | docs-system | ADOPT | — |
| F356 | research doc system | docs-system | ADOPT | — |
| F357 | internal-docs top-level orientation page | docs-system | ADOPT | — |
| F359 | Rich-only table row variant for terminal presentation (OSC-8 hyperlinks, relative timestamps) | cli-framework-ux | DIVERGENT | R85 |
| F360 | `--no-input` behavior when a prompt would have been shown | cli-framework-ux | DIVERGENT | R61 |
