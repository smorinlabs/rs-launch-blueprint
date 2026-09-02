# Commonality ledger

Authoritative verdicts for every atomic feature of `py-launch-blueprint` (b08bccf) and `ts-launch-blueprint` (cb1cbcb), per `docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md` §2–§3. Evidence for each row is the matching `id` in `areas/<Area>.md`. A tool row names its pattern row with `parent: F###`; `REUSE` rows carry `rust-ok: yes` and `live: YYYY-MM`.

| ID | Feature | Area | Origin | Verdict | Item | Notes |
|---|---|---|---|---|---|---|
| F001 | Ports abstraction for the driven I/O seam | workspace-architecture | different | DIVERGENT | R01 | bundle; whether Rust adopts a port/adapter split at all — decides F002, F013, F018 |
| F002 | Composition root wiring a port to a concrete adapter | workspace-architecture | different | DIVERGENT | R01 | bundle; only exists if F001 adopts the port split |
| F003 | Composition root importable only by front-ends, never by core | workspace-architecture | py-only | DIVERGENT | R02 | bundle; boundary-enforcement mechanism for a Rust workspace |
| F004 | Core forbidden from importing the front-ends (inward-only dependency direction) | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F005 | Front-ends (CLI, web) forbidden from importing each other | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F006 | Core internal layering (domain models below services below adapters) | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F007 | Architectural boundaries enforced mechanically rather than by convention | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F008 | Framework-bleed guard, authoritative (core may not import CLI/web frameworks) | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F009 | Framework-bleed guard, fast local mirror | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F010 | Bounded-context module dependency graph, declared and checked | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F011 | Adapter satisfies a port structurally, verified by the type checker | workspace-architecture | py-only | DIVERGENT | R02 | bundle |
| F012 | Port absence-vs-failure contract | workspace-architecture | different | DIVERGENT | R03 | error-signaling convention at the port seam; feeds error-taxonomy-exit-codes owned elsewhere |
| F013 | First-class in-memory/fake adapter shipped in the package (not test-only) | workspace-architecture | py-only | DIVERGENT | R01 | bundle |
| F014 | Public library API surface, curated re-export list | workspace-architecture | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free convention, maps to `pub use` re-exports in `lib.rs` |
| F015 | Public-surface enforcement mechanism | workspace-architecture | different | DIVERGENT | R04 | whether Rust mechanically enforces the single-surface import contract (e.g. `pub(crate)` visibility) |
| F016 | Sync/async execution model for the I/O boundary | workspace-architecture | different | DIVERGENT | R05 | bundle; decides F022 |
| F017 | Web service as an optional, separately installed capability | workspace-architecture | py-only | ADOPT | — | direct Cargo-optional-feature analogue of py's optional-dependencies extra; nothing to choose |
| F018 | Web layer as a thin adapter reusing the CLI's data contract | workspace-architecture | py-only | DIVERGENT | R01 | bundle; follows from F001's ports decision |
| F019 | Source code lives under a top-level `src/` directory | workspace-architecture | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free convention, matches Cargo's default `src/` layout |
| F020 | Package namespacing within `src/` | workspace-architecture | different | DIVERGENT | R02 | bundle; resolved by whatever crate/module layout R02 picks |
| F021 | Cargo workspace crate topology (single crate vs. multi-crate members enforcing layer boundaries) | workspace-architecture | none | RUST-ONLY | R02 | bundle; the Rust enforcement mechanism for F003-F011, F020 is likely the workspace crate split itself |
| F022 | Async runtime selection for the async I/O boundary | workspace-architecture | none | RUST-ONLY | R05 | bundle; moot if F016 resolves sync |
| F023 | `unsafe` code policy (forbidden vs. permitted-with-justification) | workspace-architecture | none | RUST-ONLY | R06 | repo-wide safety-boundary decision, no precedent in either source |
| F024 | CI trigger: push and PR to main | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native GitHub Actions trigger syntax, no external tool |
| F025 | merge_group trigger so required checks report in the GitHub merge queue | ci-workflows | py-only | ADOPT | — | direct precedent, nothing to choose; GitHub's own merge_group event |
| F026 | Contributors-bot workflow trigger cadence | ci-workflows | different | DIVERGENT | R07 | push-on-change vs. weekly-cron cadence for the contributors-list bot workflow |
| F027 | CodeQL gated to public repos via a runtime visibility check | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-04; tool: actions/github-script v9.0.0 (github.com/actions/github-script, checked 2026-09-02) |
| F028 | Top-level deny-all permissions baseline with per-job least-privilege grants | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native GitHub Actions `permissions:` syntax, no external tool |
| F029 | Checkout credential-persistence hardening (persist-credentials: false) | ci-workflows | different | DIVERGENT | R08 | bundle; how broadly the hardening pattern applies (narrow, py's choice, vs. broad, ts's) |
| F030 | Contributors-bot workflow permission declaration style | ci-workflows | different | DIVERGENT | R08 | bundle; whether every workflow follows the deny-all-plus-re-grant pattern with no exceptions |
| F031 | Runner OS selection overridable via repo vars with self-hosted fallback | ci-workflows | py-only | DIVERGENT | R09 | bundle; whether Rust adopts the vars.RUNNER_*/Blacksmith self-hosted-runner indirection at all — decides F056, F057 |
| F032 | Multi-OS test matrix (ubuntu, macOS, windows) | ci-workflows | py-only | OMIT | — | excluded by the owner-fixed `target-os-matrix` parameter (ubuntu-latest, macos-latest only — no Windows), `docs/port/PARAMETERS.md` |
| F033 | Runtime-version matrix is a two-entry floor-plus-next set | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free CI-matrix convention, matrix values come from the fixed `msrv-policy` parameter |
| F034 | Matrix job uses fail-fast: false to surface every leg's failure | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native GitHub Actions matrix option, no external tool |
| F035 | Dependency caching integrated into the language-setup step (pattern) | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; pattern row (tool-free); the specific caching action is F036 |
| F036 | Dependency caching built into the language-setup action (tool) | ci-workflows | same | COMMON → SUBSTITUTE | R10 | parent: F035; py/ts each get caching free from their language-setup action, Rust has no single canonical equivalent |
| F037 | Package-manager install must run before the cache-aware setup step (ordering constraint) | ci-workflows | ts-only | OMIT | — | cargo/rustup need no separate package-manager pre-install step; no Rust analogue |
| F038 | Consolidated lint workflow (actionlint, yamllint, bandit, codespell, editorconfig-check) with path-filtered skip | ci-workflows | py-only | DIVERGENT | R11 | bundle; CI-owned workflow-file structure plus path-filtered skip-gating, not the five tools' own selection |
| F039 | Packed-artifact file-list assertion (only expected files ship) | ci-workflows | ts-only | DIVERGENT | R26 | bundle, decided together with F078 (release-versioning's packed-artifact content guard) as one publish-content-verification item; `cargo package --list`/`cargo publish --dry-run` is the plausible Rust analogue; whether/how to assert it in CI is a real choice |
| F040 | A changes-detector job skips heavy jobs on docs-only PRs | ci-workflows | py-only | DIVERGENT | R11 | bundle; same path-filtered skip-gating question as F038 |
| F041 | Single aggregate required-status-check job folding in all other job results | ci-workflows | py-only | DIVERGENT | R12 | whether Rust CI needs one required-status-check job vs. listing every job individually as required |
| F042 | Scheduled full-dependency-graph vulnerability audit | ci-workflows | py-only | DIVERGENT | R13 | bundle; one Rust SCA/vulnerability-scanning strategy (scheduled audit + manual on-demand tool + always-on intent) — decides F048, F049 |
| F043 | Large-file size guard on new files | ci-workflows | py-only | DIVERGENT | R14 | CI-level redundancy question, distinct tier from git-hooks-commit-hygiene's hook-level large-file check |
| F044 | Template drift/receipt guard workflows | ci-workflows | py-only | DIVERGENT | R15 | whether rs-launch-blueprint is itself a template-press-rebrandable template; ts (a same-family port) did not carry this forward either |
| F045 | CodeQL custom config file (query pack selection plus paths-ignore) | ci-workflows | py-only | DIVERGENT | R16 | whether Rust's CodeQL scan gets a custom query-pack/paths-ignore config or the tool default |
| F046 | Dependency-review PR gate | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-05; tool: actions/dependency-review-action v5.0.0 (github.com/actions/dependency-review-action, checked 2026-09-02); supports Cargo.lock ecosystem detection |
| F047 | Manual, environment-gated PR security scan (workflow_dispatch) | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free pattern (workflow_dispatch inputs + protected GitHub environment); the scan tool itself is F048 |
| F048 | Manual security-scan tool | ci-workflows | different | DIVERGENT | R13 | bundle |
| F049 | Always-on SCA audit as commented, uncomment-to-enable scaffolding inside the main CI workflow | ci-workflows | ts-only | DIVERGENT | R13 | bundle |
| F050 | Dedicated secret-scanning CI workflow | ci-workflows | py-only | DIVERGENT | R17 | distinct tool and tier from git-hooks-commit-hygiene's gitleaks pre-commit/pre-push hooks; not bundled with that area |
| F051 | AI-assisted PR code review workflow | ci-workflows | py-only | DIVERGENT | R18 | bundle; same claude-code-action family as F052, plausibly adopted or dropped together |
| F052 | AI assistant workflow triggered by @mention comments | ci-workflows | py-only | DIVERGENT | R18 | bundle |
| F053 | Dependabot ecosystems configured | ci-workflows | different | DIVERGENT | R19 | bundle; ecosystems and grouping are one Dependabot-config-shape decision |
| F054 | Dependabot update grouping strategy | ci-workflows | different | DIVERGENT | R19 | bundle |
| F055 | Third-party GitHub Action pinning policy | ci-workflows | different | DIVERGENT | R20 | major-tag pin (py) vs. full-SHA pin plus version comment (ts) for third-party actions |
| F056 | actionlint config: self-hosted runner labels declared | ci-workflows | py-only | DIVERGENT | R09 | bundle; only needed if F031's vars.RUNNER_*/Blacksmith indirection is adopted |
| F057 | actionlint config: RUNNER_* config-variables declared | ci-workflows | py-only | DIVERGENT | R09 | bundle |
| F058 | actionlint config: stale-metadata suppression scope for create-github-app-token | ci-workflows | different | DIVERGENT | R09 | bundle, decided together with F031/F056/F057 (R09's self-hosted-runner-indirection/actionlint-config bundle); contingent on release-versioning's release-please-auth choice (whether create-github-app-token is used at all) |
| F059 | Publish workflow triggered on a `v*` tag push | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native GitHub Actions tag-push trigger syntax, no external tool |
| F060 | Automated contributors-list bot-PR workflow | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-06; tool: smorinlabs/contributors-please-action v1.3.9 (github.com/smorinlabs/contributors-please-action, checked 2026-09-02); language-neutral, operates on git history |
| F061 | Contributors-bot credential source for the PAT fallback | ci-workflows | different | DIVERGENT | R21 | dedicated repo secret (py) vs. zero-extra-secret GITHUB_TOKEN (ts) |
| F062 | Difftree PR-comment workflow | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-09; tool: smorinlabs/difftree-action v0.7.2 (github.com/smorinlabs/difftree-action, checked 2026-09-02); byte-identical canonical template in both repos, language-neutral |
| F063 | version source of truth | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-04; tool: release-please (googleapis/release-please-action v5.0.0, checked 2026-09-02); Cargo.toml `[package] version` is the uncontested Rust manifest field |
| F064 | runtime version accessor | release-versioning | different | DIVERGENT | R22 | compile-time `env!("CARGO_PKG_VERSION")` (ts-like, build-time) vs. a runtime metadata lookup (py-like) |
| F065 | lockfile version sync in release commit | release-versioning | different | DIVERGENT | R23 | whether release-please's extra-files config must also bump Cargo.lock's workspace-member version entries |
| F066 | changelog file generation | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-04; tool: release-please |
| F067 | changelog section type mapping (visible vs hidden) | release-versioning | different | DIVERGENT | R24 | which Conventional-Commits types surface in CHANGELOG.md vs. stay hidden |
| F068 | changelog file preamble | release-versioning | ts-only | ADOPT | — | one-line boilerplate naming Keep a Changelog/SemVer, nothing to choose |
| F069 | release PR title customization | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-04; tool: release-please; exact wording is a content choice, not a research question |
| F070 | pre-1.0 semver bump strategy | release-versioning | ts-only | DIVERGENT | R25 | whether rs-launch-blueprint starts pre-1.0 (bump-minor-pre-major/bump-patch-for-minor-pre-major) or post-1.0 like py |
| F071 | release-please bootstrap-sha pin | release-versioning | py-only | ADOPT | — | mechanical: pin the commit release-please starts scanning from when first configured |
| F072 | release-please auth token mechanism | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-05; tool: actions/create-github-app-token v3.2.0 (github.com/actions/create-github-app-token, checked 2026-09-02) |
| F073 | release trigger (push opens PR, merge tags) | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-04; tool: release-please |
| F074 | publish workflow tag/version consistency guard | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free CI-script pattern (tag reachability plus manifest-version equality checks) |
| F075 | OIDC Trusted Publishing (no stored publish token) | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native GitHub OIDC (`id-token: write`) pattern; crates.io supports Trusted Publishing |
| F076 | staged publish to test registry before production | release-versioning | py-only | OMIT | — | crates.io has no test/staging registry; `cargo publish --dry-run` never uploads, so there is no Rust analogue to research |
| F077 | protected environment gate before publish | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native GitHub protected-environment feature, no external tool |
| F078 | packed-artifact content guard in publish workflow | release-versioning | ts-only | DIVERGENT | R26 | bundle, decided together with F039 (ci-workflows' packed-artifact file-list assertion) as one publish-content-verification item; whether Rust's publish workflow needs a guard against `cargo publish` silently altering package metadata |
| F079 | release version-surface drift-check recipe | release-versioning | ts-only | ADOPT | — | low-stakes diagnostic Justfile recipe mirroring F074's already-decided consistency check; nothing to research |
| F080 | CLI version-check recipe | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free Justfile-recipe convention |
| F081 | release runbook / setup doc | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free maintainer-doc convention |
| F082 | documented opt-out from automated releases | release-versioning | py-only | ADOPT | — | doc-only instructions, nothing to choose |
| F083 | one linter and one formatter run in CI and via the git-hook manager | lint-format | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free pattern (one linter + one formatter, wired to CI and the hook manager) |
| F084 | primary code formatter tool | lint-format | different | DIVERGENT | R27 | bundle; rustfmt is the near-certain tool, but its config surface (F087, F089, F091, F092) is the research question |
| F085 | primary code linter tool | lint-format | different | DIVERGENT | R28 | bundle; clippy is the near-certain tool, but its config surface (F086, F093, F094, F096) is the research question |
| F086 | linter rule-selection mechanism | lint-format | different | DIVERGENT | R28 | bundle |
| F087 | formatter max line width | lint-format | different | DIVERGENT | R27 | bundle |
| F088 | formatter quote style | lint-format | different | OMIT | — | Rust string literals are always double-quoted; no formatter option, no Rust analogue |
| F089 | formatter line-ending normalization | lint-format | different | DIVERGENT | R27 | bundle |
| F090 | formatter semicolon insertion | lint-format | ts-only | OMIT | — | Rust's grammar requires statement-terminating semicolons; not a formatter choice, no Rust analogue |
| F091 | formatter trailing-comma style | lint-format | ts-only | DIVERGENT | R27 | bundle |
| F092 | import-sorting ownership | lint-format | different | DIVERGENT | R27 | bundle |
| F093 | linter default autofix behavior | lint-format | different | DIVERGENT | R28 | bundle |
| F094 | per-context lint relaxation for test files | lint-format | different | DIVERGENT | R28 | bundle |
| F095 | per-file ignore for package `__init__.py` | lint-format | py-only | OMIT | — | Rust's `mod.rs`/`lib.rs` re-export surface has no equivalent unused-import exemption need |
| F096 | security-rule coverage via the linter | lint-format | different | DIVERGENT | R28 | bundle |
| F097 | TOML formatter as a separate tool | lint-format | py-only | DIVERGENT | R29 | bundle; Rust's own config files (Cargo.toml, rustfmt.toml) make TOML formatting directly relevant — decided jointly with F098/F099; confirmed ts has no TOML-specific Oxfmt setting and carries zero `.toml` files, so origin stays py-only |
| F098 | YAML formatting ownership | lint-format | different | DIVERGENT | R29 | bundle |
| F099 | JSON and Markdown formatting coverage | lint-format | ts-only | DIVERGENT | R29 | bundle |
| F100 | formatter/linter exclude-list configuration scope | lint-format | different | DIVERGENT | R27 | bundle, decided together with F084/F087/F089/F091/F092 (rustfmt's config surface); whether Rust shares one exclude list across rustfmt/clippy or keeps them per-tool |
| F101 | editor extension recommendation for lint/format | lint-format | different | DIVERGENT | R28 | bundle, decided together with F085/F086/F093/F094/F096 (clippy's config surface) and F109/F195/F196 (static-analysis/dev-experience-repo-hygiene's editor-tooling rows); rust-analyzer is the dominant editor-extension candidate once rustfmt/clippy are chosen |
| F102 | composite recipe bundling format/lint/typecheck/test | lint-format | different | DIVERGENT | R27 | bundle, decided together with F084/F087/F089/F091/F092 (rustfmt's config surface); whether Rust's `check`-style composite recipe includes a format-check step |
| F103 | lint/format tool version-pinning strategy | lint-format | different | DIVERGENT | R27 | bundle, decided together with F084/F087/F089/F091/F092 (rustfmt's config surface); rustfmt/clippy are rustup components pinned via `rust-toolchain.toml`, largely governed by the already-fixed `msrv-policy` parameter, not an independent Cargo-dependency version-pinning choice |
| F104 | pre-commit formatter hook mode (check vs. write) | lint-format | different | DIVERGENT | R27 | bundle, decided together with F084/F087/F089/F091/F092 (rustfmt's config surface); whether the Rust formatter hook blocks on unformatted code or auto-fixes and re-stages |
| F105 | primary type-checker tool | static-analysis | different | DIVERGENT | R30 | bundle; ty (py, CI-authoritative plus pre-push hook mirror) vs tsc (ts, sole CI/pre-commit/editor engine); rustc/cargo check is the Rust baseline, but whether a wrapper or stricter layer is adopted is the open question — decides F106-F108, F110-F113 |
| F106 | type-checker hook-tier placement | static-analysis | different | DIVERGENT | R30 | bundle; py deliberately excludes its type checker from pre-commit (pre-push only, full-tree scan judged too slow per-commit); ts runs it every commit |
| F107 | single type-checker engine serving both CI and the editor | static-analysis | ts-only | DIVERGENT | R30 | bundle |
| F108 | dedicated IDE-only type checker distinct from the CI-authoritative one | static-analysis | py-only | DIVERGENT | R30 | bundle |
| F109 | type-checker editor-extension recommendation | static-analysis | py-only | DIVERGENT | R28 | bundle, decided together with F101 (editor tooling: rust-analyzer + debugger) |
| F110 | type-checker opt-in quality-rule / strictness configuration | static-analysis | different | DIVERGENT | R30 | bundle |
| F111 | type-checker suppression-comment discipline | static-analysis | py-only | DIVERGENT | R30 | bundle |
| F112 | type-checker warning-vs-error severity tier | static-analysis | py-only | DIVERGENT | R30 | bundle |
| F113 | type-check gate scope: whether tests are included | static-analysis | different | DIVERGENT | R30 | bundle |
| F114 | dedicated AST-based security scanner beyond the linter's built-in security rules | static-analysis | py-only | DIVERGENT | R31 | bundle; whether Rust adopts a standalone security-focused static analyzer beyond clippy's built-in lints, distinct from lint-format's F096 (security-rule coverage via the linter itself) — decides F115 |
| F115 | security scanner hook-tier placement | static-analysis | py-only | DIVERGENT | R31 | bundle |
| F116 | architectural-boundary check hook-tier placement | static-analysis | py-only | DIVERGENT | R02 | bundle, decided together with F003-F011/F020/F021 (workspace-architecture's boundary-enforcement mechanism) — where in the hook pipeline the chosen mechanism's check runs |
| F117 | test runner tool | testing-coverage | different | DIVERGENT | R32 | bundle; pytest (py) vs Vitest (ts) — Rust's test harness and its execution-behavior configuration (tiering, mocking, fixtures, ordering, timeouts) is one decision — decides F118, F124, F125, F128-F132 |
| F118 | CLI test tiers (in-process vs. built-binary) | testing-coverage | different | DIVERGENT | R32 | bundle |
| F119 | mock/test-double library | testing-coverage | different | DIVERGENT | R48 | bundle, decided together with F120 (HTTP transport mocking mechanism) — a mock/test-double crate choice independent of the test-harness pick (R32) |
| F120 | HTTP transport mocking mechanism in tests | testing-coverage | different | DIVERGENT | R48 | bundle, decided together with F119 (mock/test-double library) — an HTTP-mock crate choice independent of the test-harness pick (R32) |
| F121 | port-contract substitutability suite (fake vs. real adapter parity) | testing-coverage | py-only | DIVERGENT | R01 | bundle, decided together with F001 (workspace-architecture's port/adapter split) — this test pattern only exists if R01 adopts ports |
| F122 | property-based (generative) testing | testing-coverage | py-only | DIVERGENT | R33 | bundle; whether Rust adopts a property-based testing crate (e.g. proptest) — decides F123 |
| F123 | CLI golden-snapshot testing | testing-coverage | py-only | DIVERGENT | R33 | bundle |
| F124 | randomized test execution order | testing-coverage | py-only | DIVERGENT | R32 | bundle |
| F125 | per-test timeout enforcement | testing-coverage | py-only | DIVERGENT | R32 | bundle |
| F126 | scheduled dependency-freshness canary run | testing-coverage | py-only | DIVERGENT | R34 | bundle; whether Rust runs a scheduled test pass against upgraded dependencies to catch breakage early — decides F127 |
| F127 | advisory alternate JS runtime test lane | testing-coverage | ts-only | DIVERGENT | R34 | bundle; Rust's analogue would be a non-blocking alternate-toolchain (e.g. nightly) test lane |
| F128 | shared cross-test fixture file (autouse setup) | testing-coverage | py-only | DIVERGENT | R32 | bundle |
| F129 | test file organization (subdirected vs. flat) | testing-coverage | different | DIVERGENT | R32 | bundle |
| F130 | opt-in test marker taxonomy (skip slow/live by default) | testing-coverage | py-only | DIVERGENT | R32 | bundle |
| F131 | opt-in parallel test execution flag | testing-coverage | py-only | DIVERGENT | R32 | bundle |
| F132 | Rust doc-test execution policy | testing-coverage | none | RUST-ONLY | R32 | bundle; `cargo test --doc` runs doc-comment examples by default and neither source repo has an analogous convention to port; whether Rust's CI-authoritative gate includes doc-tests is a Rust-only decision |
| F133 | test asserting the version stays single-sourced across manifests | testing-coverage | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free pattern (a hand-written test asserting manifest/accessor version equality); manifest set is Cargo.toml, plus Cargo.lock if R25 requires sync |
| F134 | coverage tool | testing-coverage | different | DIVERGENT | R35 | bundle; pytest-cov (py) vs @vitest/coverage-v8 (ts) — Rust's coverage tool and its configuration (scope, thresholds, gate, report formats) is one decision — decides F135-F138 |
| F135 | coverage instrumentation scope and exclusions | testing-coverage | different | DIVERGENT | R35 | bundle |
| F136 | coverage threshold definition location and values | testing-coverage | different | DIVERGENT | R35 | bundle |
| F137 | coverage gate enforcement in CI | testing-coverage | different | DIVERGENT | R35 | bundle |
| F138 | coverage report output formats | testing-coverage | py-only | DIVERGENT | R35 | bundle |
| F139 | OpenAPI contract snapshot test | testing-coverage | py-only | DIVERGENT | R36 | bundle; contingent on web-service adopting an optional web surface (cross-area `web-extra-surface`, not yet classified) — decides F140 |
| F140 | API contract fuzz-testing tool | testing-coverage | py-only | DIVERGENT | R36 | bundle |
| F141 | meta-tests validating tooling-config internal consistency | testing-coverage | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free pattern (a test suite guarding the repo's own config files); same pattern as F133 |
| F142 | git hook manager tool | git-hooks-commit-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-08; tool: lefthook (evilmartians/lefthook v2.1.12, checked 2026-09-02); language-neutral hook manager, identical usage in any repo |
| F143 | lefthook distribution/install mechanism | git-hooks-commit-hygiene | different | DIVERGENT | R37 | bundle; py's separate Bun-based installer script vs ts's pnpm devDependency — cargo does not manage non-crate binaries, so Rust has no analogous package-manager-scoped install path — decides F144, F174 |
| F144 | hook-wiring trigger mechanism | git-hooks-commit-hygiene | different | DIVERGENT | R37 | bundle |
| F145 | manual hook re-wire recipe | git-hooks-commit-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free Justfile-recipe convention |
| F146 | pre-commit stage jobs execute in parallel | git-hooks-commit-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native lefthook YAML option, same tool as F142 |
| F147 | hook staging tiering (fast staged checks at commit, slower full-tree checks deferred later) | git-hooks-commit-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free tiering philosophy; per-check placement is decided by each check's own item (e.g. F106 for the type checker, F115 for the security scanner) |
| F148 | commit-message linting enforced at commit-msg hook time (pattern) | git-hooks-commit-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; pattern row (tool-free); the specific linter tool is F149 |
| F149 | commit-msg linter tool | git-hooks-commit-hygiene | same | COMMON → SUBSTITUTE | R38 | parent: F148; commitlint is an npm package — even py (a Python project) pulls in Bun/Node solely to run it; whether Rust does the same or adopts a native alternative (e.g. committed, cocogitto) is the open question — decides F150-F157 |
| F150 | commit-msg hook invocation mechanism | git-hooks-commit-hygiene | different | DIVERGENT | R38 | bundle |
| F151 | commitlint base config | git-hooks-commit-hygiene | same | COMMON → SUBSTITUTE | R38 | parent: F148; bundle, decided together with F149 (commit-msg linter tool) |
| F152 | commit subject (header) max length override | git-hooks-commit-hygiene | ts-only | DIVERGENT | R38 | bundle |
| F153 | commit body max line-length override | git-hooks-commit-hygiene | different | DIVERGENT | R38 | bundle |
| F154 | commit footer max line-length override | git-hooks-commit-hygiene | py-only | DIVERGENT | R38 | bundle |
| F155 | commit type-enum restriction | git-hooks-commit-hygiene | ts-only | DIVERGENT | R38 | bundle |
| F156 | per-author relaxed commit-lint ruleset for bot PRs | git-hooks-commit-hygiene | py-only | DIVERGENT | R38 | bundle |
| F157 | commit-message linting re-run in CI (beyond the local hook) | git-hooks-commit-hygiene | py-only | DIVERGENT | R38 | bundle |
| F158 | commit-message template file | git-hooks-commit-hygiene | ts-only | ADOPT | — | commit-message template file is a doc-convenience artifact; its content tracks F155's type-enum pick, no ecosystem survey needed |
| F159 | commit-message template wired via git config | git-hooks-commit-hygiene | ts-only | ADOPT | — | `git config commit.template` is a native, language-neutral git mechanism — nothing Rust-specific to decide |
| F160 | commit-message template/commitlint type-list consistency, enforced by test | git-hooks-commit-hygiene | ts-only | ADOPT | — | same tool-free meta-test pattern already REUSE'd elsewhere in this batch (F133, F141); ts-only origin bars REUSE but the "nothing to research" shape is identical |
| F161 | lefthook config internal-consistency, enforced by test | git-hooks-commit-hygiene | ts-only | ADOPT | — | tool-free meta-test asserting `lefthook.yml` parses and carries its expected stage keys; content is independent of R37's install/wiring-mechanism outcome, unlike F162 (which depends on F100's exclude-list decision) — same shape as F160 |
| F162 | lefthook per-job exclude-list mirrors the linter/formatter ignore config, enforced by test | git-hooks-commit-hygiene | ts-only | DIVERGENT | R27 | bundle, decided together with F100 (lint-format's exclude-list configuration scope) — consistency-test pattern for hook config |
| F163 | staged secret-scanning hook | git-hooks-commit-hygiene | py-only | DIVERGENT | R39 | bundle; whether Rust adopts gitleaks (or an alternative) as a staged pre-commit secret scanner — decides F164-F166 |
| F164 | pre-push range secret-scanning hook | git-hooks-commit-hygiene | py-only | DIVERGENT | R39 | bundle |
| F165 | secret-scanner allowlist configuration | git-hooks-commit-hygiene | py-only | DIVERGENT | R39 | bundle |
| F166 | secret-scanner fingerprint suppression file | git-hooks-commit-hygiene | py-only | DIVERGENT | R39 | bundle |
| F167 | whitespace/EOL/format-validity hygiene linter (pre-commit) | git-hooks-commit-hygiene | py-only | DIVERGENT | R40 | bundle; Rust's auxiliary pre-commit hygiene/structural-validity tool stack beyond rustfmt/clippy — decides F168-F170 |
| F168 | YAML lint hook | git-hooks-commit-hygiene | py-only | DIVERGENT | R40 | bundle; distinct from YAML formatting (F098/R29) — structural/style linting, not reformatting |
| F169 | spell-check hook | git-hooks-commit-hygiene | py-only | DIVERGENT | R40 | bundle |
| F170 | GitHub Actions workflow syntax lint hook | git-hooks-commit-hygiene | py-only | DIVERGENT | R40 | bundle; whether actionlint runs at hook tier at all — its config content (self-hosted-runner labels, RUNNER_* vars, stale-metadata suppression) is R09's separate concern |
| F171 | dependency-manifest lockfile-freshness check hook | git-hooks-commit-hygiene | py-only | DIVERGENT | R41 | standalone; Rust's plausible analogue is a Cargo lockfile-freshness check, with no single canonical `--check`-style flag equivalent to `uv lock --check` |
| F172 | large-file size guard hook | git-hooks-commit-hygiene | different | DIVERGENT | R14 | bundle, decided together with F043 (ci-workflows' CI-tier large-file guard) — same large-file-guard-strategy decision, hook tier; py's 1 MB threshold plus assets-path exemption vs ts's 500 KB threshold with no exemption |
| F173 | full test-suite execution as a git hook | git-hooks-commit-hygiene | ts-only | DIVERGENT | R32 | bundle, decided together with F117 (testing-coverage's test-runner/execution-behavior bundle) — whether Rust also gates via an opt-in pre-push test-suite hook |
| F174 | CI job aggregating every hook-suite check for full-tree dual enforcement | git-hooks-commit-hygiene | ts-only | DIVERGENT | R37 | bundle; resolution target for ci-workflows' and lint-format's forward-referenced "full hook suite re-run against all files" primary-assignment rows |
| F175 | local recipe to re-run the pre-commit hook suite against the whole tree | git-hooks-commit-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free Justfile-recipe convention, same underlying lefthook invocation as F142 |
| F176 | task-runner tool | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-08; tool: just (casey/just v1.58.0, checked 2026-09-02); language-neutral task runner |
| F177 | recipe grouping via attributes | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native `just` syntax feature, same tool as F176 |
| F178 | recipe short aliases | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native `just` syntax feature, same tool as F176 |
| F179 | two-level bootstrap split (Makefile=toolchain, Justfile=dev tasks) | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free architectural convention |
| F180 | `make check` verifies base toolchain present | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; `make` is language-neutral; tool set checked differs per language (cargo/rustup for Rust) |
| F181 | `just check-deps` verifies full dev toolchain with per-tool remediation | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free `#!/usr/bin/env sh` script pattern, same tool as F176 |
| F182 | Level-2 setup gates on Level-1 bootstrap completion | dev-experience-repo-hygiene | py-only | ADOPT | — | mechanical wiring pattern (`setup:` depends on `make check` succeeding first), nothing to choose |
| F183 | per-tool binary installer recipes for tools outside the primary package manager | dev-experience-repo-hygiene | py-only | DIVERGENT | R42 | bundle; whether Rust needs Justfile installer recipes for non-cargo dev tools, or a declarative provisioner instead — decides F187-F189 |
| F184 | `make install-*` print-first command + separate `-force` variant | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free `make` recipe convention |
| F185 | dependency-free environment diagnostic recipe ("doctor" report) | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free `just` recipe convention, same tool as F176 |
| F186 | hook-toolchain readiness check (doctor for git-hook tools) | dev-experience-repo-hygiene | py-only | ADOPT | — | duplicates `check-deps`'s tool-presence-check UX for a narrower tool set; independent of which provisioner R42 resolves to — same shape as F182 |
| F187 | declarative toolchain-provisioner manifest: mise | dev-experience-repo-hygiene | py-only | DIVERGENT | R42 | bundle |
| F188 | declarative toolchain-provisioner manifest: flox | dev-experience-repo-hygiene | py-only | DIVERGENT | R42 | bundle |
| F189 | three toolchain provisioners kept in manual sync (native + mise + flox) | dev-experience-repo-hygiene | py-only | DIVERGENT | R42 | bundle |
| F190 | toolchain version pin-file convention | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; pattern reused; mechanism is `rust-version` in Cargo.toml per the fixed `msrv-policy` parameter (`docs/port/PARAMETERS.md`), no separate pin-file needed |
| F191 | cross-editor formatting baseline file | dev-experience-repo-hygiene | py-only | DIVERGENT | R40 | bundle, decided together with F167-F170 (git-hooks-commit-hygiene's auxiliary hygiene-tool stack) — the `.editorconfig` baseline and its enforcement are one decision |
| F192 | documented per-filetype `.editorconfig` exceptions | dev-experience-repo-hygiene | py-only | DIVERGENT | R40 | bundle |
| F193 | VS Code recommended-extensions list | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native VS Code `extensions.json` mechanism, tool-free; specific entries are decided by each relevant tool's own item (e.g. F109/F195 for rust-analyzer/debugger) |
| F194 | VS Code debug (`launch.json`) config for the CLI (pattern: committed debug configuration) | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; pattern row (tool-free); the debugger tool is F195 |
| F195 | VS Code debugger tool/extension for the CLI | dev-experience-repo-hygiene | same | COMMON → SUBSTITUTE | R28 | parent: F194; bundle, decided together with F101 (editor tooling: rust-analyzer + debugger) |
| F196 | committed `.vscode/settings.json` pinning the editor's language-service version | dev-experience-repo-hygiene | ts-only | DIVERGENT | R28 | bundle, decided together with F101 (editor tooling: rust-analyzer + debugger) |
| F197 | AI-agent instruction hub (single canonical file + thin per-tool import) | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free doc convention |
| F198 | vendor-specific AI-editor rule files (Cursor/Windsurf) | dev-experience-repo-hygiene | ts-only | DIVERGENT | R43 | bundle; whether rs-launch-blueprint adds AI-assistant repo furniture beyond the AGENTS.md hub — decides F199 |
| F199 | repo-welcome startup announcement | dev-experience-repo-hygiene | ts-only | DIVERGENT | R43 | bundle |
| F200 | devcontainer (base image, postCreate bootstrap, in-container VS Code config) | dev-experience-repo-hygiene | py-only | DIVERGENT | R44 | standalone |
| F201 | issue-template set structure (typed templates + blank-disabled config) | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native GitHub issue-template mechanism |
| F202 | issue-template label schema | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native GitHub issue-template mechanism, same as F201 |
| F203 | PR template pre-flight checklist | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native GitHub PR-template mechanism; checklist wording tracks each repo's own tool names |
| F204 | PR-comment bot re-review trigger block | dev-experience-repo-hygiene | py-only | DIVERGENT | R45 | standalone |
| F205 | FUNDING.yml | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native GitHub FUNDING.yml mechanism |
| F206 | root LICENSE file | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free LICENSE text; value is the fixed `license` parameter (MIT OR Apache-2.0), an owner override already recorded in `docs/port/PARAMETERS.md` — REUSE-and-log per the owner's rule, no separate research item warranted |
| F207 | per-file embedded license header | dev-experience-repo-hygiene | different | DIVERGENT | R46 | standalone; whether Rust source files carry a per-file license header, and what boilerplate, given the license fixed parameter is now dual MIT OR Apache-2.0 |
| F208 | CLA program (texts, FAQ, setup guide, hosted bot) | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; process/doc convention plus a hosted external bot, language-neutral |
| F209 | contributors-render config schema (`.contributors.yml` + `.contributors.jsonl` ledger) | dev-experience-repo-hygiene | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-06; tool: contributors-please, same tool as F060 (ci-workflows' contributors-bot workflow); config schema identical in both repos |
| F210 | local Justfile recipe's subcommand vs. the CI bot's action mode | dev-experience-repo-hygiene | different | DIVERGENT | R47 | standalone; a content pick (which contributors-please subcommand the local recipe invokes) forced DIVERGENT by origin `different` rather than a genuine open research question — flagging as a Phase-3.5 `narrow` disposition candidate, same class as F067/F101 |
| F211 | build backend/bundler produces the distributable package (pattern) | packaging-distribution | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; pattern row (tool-free); the specific backend/bundler tool is F212 |
| F212 | build backend/bundler tool | packaging-distribution | same | COMMON → SUBSTITUTE | R49 | parent: F211; uv_build (PEP 517 backend) and tsdown (rolldown bundler) are both language-bound third-party tools; Cargo is Rust's native build system with no separate backend/bundler crate needed — decides F213, F216, F218, F219 |
| F213 | build entry-point declaration | packaging-distribution | different | DIVERGENT | R49 | bundle; py's single package root vs ts's explicit two-entry list (CLI + library) — Rust's analogue is Cargo.toml's `[[bin]]`/`[lib]` target declarations |
| F214 | distributable artifact types | packaging-distribution | different | DIVERGENT | R68 | standalone; py ships sdist+wheel, ts ships one ESM npm tarball — `cargo publish` produces one `.crate` file; which release binary artifacts rs-launch-blueprint ships beyond that (crates.io-only; `cargo-dist` cross-compiled GitHub Release binaries; `cargo-binstall` metadata) is Phase 3 research |
| F215 | dual CJS/ESM vs ESM-only output | packaging-distribution | ts-only | OMIT | — | JS module-format duality (CommonJS vs ESM) has no Rust analogue; compiled crates have no module-resolution format to choose |
| F216 | console-script / bin entry declaration | packaging-distribution | different | DIVERGENT | R49 | bundle; py references a callable via `[project.scripts]`, ts references a built file path via `package.json` `bin` — Cargo's analogue is the `[[bin]]` `name` field, decided together with F212 |
| F217 | CLI executable invocation mechanism | packaging-distribution | different | OMIT | — | py generates a wrapper script from the entry-point callable; ts preserves a shebang and chmods the bundled output — `cargo build` produces a native compiled binary directly, with neither a wrapper-script step nor a shebang to preserve; no Rust analogue |
| F218 | packaged-file whitelist mechanism | packaging-distribution | different | DIVERGENT | R49 | bundle; py's layout setting implicitly bounds wheel content, ts uses an explicit `files` array — Cargo's analogue is the `include`/`exclude` fields in `[package]` (default: git-tracked files only) |
| F219 | distribution-name vs entry-point-name divergence | packaging-distribution | different | DIVERGENT | R49 | bundle; whether the crate/binary name matches, and whether `cargo install`/`cargo binstall` need any name-lookup flag analogous to `uvx --from` |
| F220 | documented end-user install method | packaging-distribution | py-only | ADOPT | — | follows F214 (R68) — the README install command tracks whichever artifacts ship; nothing separate to research |
| F221 | CI-wired build-and-install smoke test cadence | packaging-distribution | different | DIVERGENT | R50 | bundle; py gates every PR on an install smoke test, ts's equivalent recipe (`pack-check`) is local-only — decides F222 |
| F222 | ephemeral wheel/sdist install-and-run smoke test | packaging-distribution | py-only | DIVERGENT | R50 | bundle; `uvx`'s throwaway-env install-and-run pattern — Rust's plausible analogue is `cargo install --path . --root <tmp>` then running the binary; related to but distinct from R26's packed-artifact content guard (F039/F078, "does what's packaged match expectations" vs this row's "does the installed artifact run") — Task 10 may want to weigh a merge |
| F223 | container image as a distribution artifact | packaging-distribution | py-only | DIVERGENT | R51 | bundle; contingent on F017 (workspace-architecture, already ADOPTed: web service as an optional Cargo feature) — whether the optional web-service build also gets a Dockerfile/multi-stage image; decides F336, F337 (web-service's container build-layering and healthcheck facts) |

| F224 | config file format | config-env-logging | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; both standardize on TOML (a language-neutral format); the parse/write libraries are F225/F226 |
| F225 | TOML parse library | config-env-logging | different | DIVERGENT | R52 | bundle; py stdlib `tomllib` vs ts `smol-toml` — Rust's analogue is a TOML crate (e.g. `toml`, `basic-toml`); the shared format is F224, decided together with F226 |
| F226 | TOML write library | config-env-logging | different | DIVERGENT | R52 | bundle, decided together with F225 (py splits parse/write into two libraries; ts's smol-toml does both — whether the Rust crate also does both is part of the same crate-choice question) |
| F227 | config file naming convention (`<tool>_config.toml`) | config-env-logging | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free naming convention, tool name changes per port |
| F228 | config schema validation library | config-env-logging | different | DIVERGENT | R53 | pydantic (py) vs zod (ts) — Rust's analogue is `serde` (+ optionally a validation crate); origin is `different` (the area row names the two libraries directly), so this is a DIVERGENT row rather than a SUBSTITUTE child of F229, same shape as F014/F015's pattern/mechanism split in workspace-architecture |
| F229 | typed config schema with per-key validation | config-env-logging | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; pattern row (tool-free): both validate the parsed file against a typed schema before use; the validation library is F228; serde's typed deserialization preserves this same pattern, so this is a substitution in spirit, not an override |
| F230 | layered config discovery (system → user → project, later wins) | config-env-logging | py-only | DIVERGENT | R54 | bundle; whether Rust adopts py's multi-tier discovery (system/user/project, later wins) or ts's single default-user-path tier — decides F231, F232, F234 |
| F231 | system-wide config directory (`$XDG_CONFIG_DIRS`/`%PROGRAMDATA%`) | config-env-logging | py-only | DIVERGENT | R54 | bundle |
| F232 | project-local config file discovery (`./<tool>_config.toml`, dotfile preferred) | config-env-logging | py-only | DIVERGENT | R54 | bundle |
| F233 | `--config` flag replaces discovery entirely | config-env-logging | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free behavioral pattern: both treat an explicit `--config` path as a full override of discovery, not an additional layer |
| F234 | `--config` env-var alias | config-env-logging | py-only | DIVERGENT | R54 | bundle; an alternate way to supply the config path, same family as F230's discovery-tier question |
| F235 | explicit `--config` pointing at a missing file | config-env-logging | different | DIVERGENT | R55 | bundle; py tolerates a missing explicit path as an empty layer, ts throws (exit 2) — decides F236, F238 |
| F236 | unparsable *discovered* config layer degrades to a warning, not a crash | config-env-logging | py-only | DIVERGENT | R55 | bundle; only relevant if R54 adopts a discovered (non-explicit) config tier |
| F237 | unparsable *explicit* config file raises loudly | config-env-logging | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free behavioral pattern: both treat a corrupt file the user explicitly named/found as a hard configuration error |
| F238 | invalid config *values* (right TOML, wrong value) degrade to a warning and are dropped | config-env-logging | py-only | DIVERGENT | R55 | bundle; py drops the one bad key with a warning, ts's zod `safeParse` failure raises for the whole file — considered as an OVERRIDE candidate (serde's typed deserialization makes per-key drop-and-continue awkward) but this row's origin is `py-only`, not `same`, so OVERRIDE is not legal here; stays DIVERGENT |
| F239 | config file secrets rule | config-env-logging | different | DIVERGENT | R56 | bundle; py (ADR 0002) never reads a token from any config layer; ts allows the config file as the lowest-precedence token source — decides F240, F245 |
| F240 | token resolution precedence | config-env-logging | different | DIVERGENT | R56 | bundle; direct consequence of F239: py's two-tier flag>env chain vs ts's three-tier flag>env>file chain |
| F241 | token env var name | config-env-logging | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free naming convention, renamed per the port's naming scheme |
| F242 | empty-string env/flag token treated as unset | config-env-logging | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free behavioral pattern: both fall through to the next tier on an empty string |
| F243 | config file written with restrictive permissions | config-env-logging | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free POSIX 0600 convention, expressible identically via `std::fs` permission bits |
| F244 | Windows write-permission handling | config-env-logging | ts-only | OMIT | — | Windows-only branch; excluded by the owner-fixed `target-os-matrix` parameter (`docs/port/PARAMETERS.md`, ubuntu-latest/macos-latest only), so no Rust analogue to research |
| F245 | non-fatal warning for a loosely-permissioned on-disk config file | config-env-logging | ts-only | DIVERGENT | R56 | bundle; only meaningful if R56 adopts a config file that can carry a token, same as ts's F239 side |
| F246 | secret masking for display | config-env-logging | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free reveal-last-4 masking convention |
| F247 | XDG override mechanism (env var must be set, non-empty, absolute) | config-env-logging | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native XDG Base Directory convention (tool-free); py additionally requires absoluteness, a minor same-origin implementation nuance, not a verdict-changing difference |
| F248 | config directory default on Windows | config-env-logging | different | OMIT | — | Windows-only default-path branch; excluded by the owner-fixed `target-os-matrix` parameter (`docs/port/PARAMETERS.md`), so no Rust analogue to research |
| F249 | separate XDG-style data/state/cache directories beyond config | config-env-logging | py-only | DIVERGENT | R57 | standalone; whether Rust adopts the full XDG data/state/cache directory set beyond just config — contingent on whether a file log sink (R59) or a crash log (see cli-framework-ux) end up needing a state/cache path; Task 10 may want to weigh folding this into R59 |
| F250 | console log format auto-selects JSON vs. human text from TTY-ness | config-env-logging | py-only | DIVERGENT | R58 | bundle; whether Rust's console logging pipeline auto-selects a machine-readable vs. human format from TTY-ness — decides F251-F253, F262, F263; bundle, decided together with cli-framework-ux's verbosity-to-level ladder row (see F274) |
| F251 | structured (key/value) logging pipeline | config-env-logging | py-only | DIVERGENT | R58 | bundle |
| F252 | key-based secret redaction in log output | config-env-logging | py-only | DIVERGENT | R58 | bundle |
| F253 | trace/span correlation in logs (OpenTelemetry) | config-env-logging | py-only | DIVERGENT | R58 | bundle |
| F254 | explicit console log-level flag/env (`--log-level`/`PLBP_LOG_LEVEL`) | config-env-logging | py-only | DIVERGENT | R58 | bundle; whether Rust exposes a direct level-setting override alongside the verbosity ladder (cli-framework-ux's F274) |
| F255 | `[logging]` table in the config file (level/file/file_level/format defaults) | config-env-logging | py-only | DIVERGENT | R59 | bundle; whether Rust's config schema carries a `[logging]` section at all — decides F256-F261; most of this row's fields (file/file_level/format) are file-sink-specific |
| F256 | optional rotating file log sink | config-env-logging | py-only | DIVERGENT | R59 | bundle |
| F257 | file log sink rotation policy (size + backup count) | config-env-logging | py-only | DIVERGENT | R59 | bundle |
| F258 | file sink enable flag/env (`--log-file`/`PLBP_LOG_FILE`, default XDG state path) | config-env-logging | py-only | DIVERGENT | R59 | bundle |
| F259 | file sink path precedence (flag/env > config `logging.file` > off) | config-env-logging | py-only | DIVERGENT | R59 | bundle |
| F260 | file sink format override via env (`PLBP_LOG_FORMAT`, validated) | config-env-logging | py-only | DIVERGENT | R59 | bundle |
| F261 | file sink independent level from the console sink (dual-sink floor) | config-env-logging | py-only | DIVERGENT | R59 | bundle |
| F262 | logging reconfiguration only tears down handlers it owns (idempotent, host-safe) | config-env-logging | py-only | DIVERGENT | R58 | bundle; a design property of the console pipeline's own re-init behavior, decided together with F250-F253 |
| F263 | one shared logging pipeline expressed as per-front-end policy profiles | config-env-logging | py-only | DIVERGENT | R58 | bundle; depends on cross-area `web-extra-surface` (whether Rust carries a second front-end sharing the pipeline) as well as R58's own pipeline-architecture decision |

| F264 | CLI framework/parsing library | cli-framework-ux | different | DIVERGENT | R60 | click (py) vs commander (ts) — Rust's analogue is a CLI-parsing crate (e.g. `clap`); decides F265, F267-F270, F272 |
| F265 | Command surface shape: noun-verb subcommand groups vs. one default command | cli-framework-ux | different | DIVERGENT | R60 | bundle |
| F266 | `-V`/`--version` flag | cli-framework-ux | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free pattern (a `--version` flag exists); the parsing framework that provides it is F264 |
| F267 | Extended version output (runtime/platform info) | cli-framework-ux | py-only | DIVERGENT | R60 | bundle; whether rs-launch-blueprint's `--version` also prints extended (target-triple/rustc) info |
| F268 | Shell completion script generation command | cli-framework-ux | py-only | DIVERGENT | R60 | bundle; clap's `clap_complete` crate is the plausible framework-native answer, decided together with F264 |
| F269 | Blanket env-var binding for every global option | cli-framework-ux | py-only | DIVERGENT | R60 | bundle |
| F270 | Global options stackable on every (sub)command | cli-framework-ux | different | DIVERGENT | R60 | bundle; py's design lets flags land after the verb — an architectural property of whichever framework F264 picks |
| F271 | Did-you-mean suggestion on an unknown command | cli-framework-ux | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; pattern row (tool-free): a did-you-mean suggestion exists on both; the matching mechanism is F272 |
| F272 | Did-you-mean matching implementation | cli-framework-ux | different | DIVERGENT | R60 | bundle; stdlib `difflib` (py) vs Commander's built-in matcher (ts) — whether the chosen Rust framework provides this natively |
| F273 | Repeatable `-v`/`--verbose` flag | cli-framework-ux | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free pattern: both count repeated occurrences |
| F274 | Verbosity-to-log-level resolution ladder | cli-framework-ux | different | DIVERGENT | R58 | bundle, decided together with config-env-logging's console-logging-pipeline item (F250-F253, F254, F262, F263) — same underlying resolution chain (`--log-level`/env > `-q`/`-v` > config > default), cited from both areas' angles; kept as one cross-area item rather than two per §6.3's cross-topic-contradiction concern |
| F275 | `--no-input` flag disables interactive prompting | cli-framework-ux | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free pattern: a `--no-input` flag exists on both; py fails the command on it, ts selects every fetched result instead — a real behavioral fork logged here rather than silently inherited, per the governing rule |
| F276 | Interactive yes/no confirmation prompt for destructive actions | cli-framework-ux | py-only | DIVERGENT | R61 | bundle; whether Rust adopts an interactive-prompt crate (e.g. `dialoguer`) for confirm/guided-value/multi-select prompts — decides F279, F280 |
| F277 | `--dry-run` mutation-safety flag | cli-framework-ux | py-only | ADOPT | — | plain flag, independent of R61's prompt-crate choice |
| F278 | `-y`/`--yes` mutation-safety flag | cli-framework-ux | py-only | ADOPT | — | plain flag, independent of R61's prompt-crate choice |
| F279 | Interactive guided value prompt (config init) | cli-framework-ux | py-only | DIVERGENT | R61 | bundle |
| F280 | Interactive multi-select prompt over fetched results | cli-framework-ux | ts-only | DIVERGENT | R61 | bundle; `@inquirer/prompts` checkbox — same crate-choice question as F276's confirm/guided prompts |
| F281 | Clipboard-copy flag for command results | cli-framework-ux | ts-only | DIVERGENT | R62 | bundle; whether Rust adopts a clipboard-write crate (e.g. `arboard`) — decides F282 |
| F282 | Clipboard write with headless-degrade handling | cli-framework-ux | ts-only | DIVERGENT | R62 | bundle |
| F283 | Progress spinner during network fetch | cli-framework-ux | ts-only | DIVERGENT | R63 | standalone; whether Rust adopts a stderr spinner crate (e.g. `indicatif`) gated on TTY and absence of `CI` |
| F284 | Text-mode output paged through the user's pager | cli-framework-ux | py-only | DIVERGENT | R64 | bundle; whether Rust pages long text output through the user's pager — decides F285 |
| F285 | Pager command resolution precedence | cli-framework-ux | py-only | DIVERGENT | R64 | bundle |
| F286 | `--no-color` flag | cli-framework-ux | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free pattern: a `--no-color` flag exists on both |
| F287 | Color enablement precedence chain | cli-framework-ux | different | DIVERGENT | R65 | bundle; py chain flag > `NO_COLOR` env > config; ts chain flag > `NO_COLOR` > `FORCE_COLOR` > TTY — decides F288-F290 |
| F288 | `FORCE_COLOR` env var forces color on | cli-framework-ux | ts-only | DIVERGENT | R65 | bundle |
| F289 | Color gated once for both streams vs. per-stream on stderr only | cli-framework-ux | different | DIVERGENT | R65 | bundle |
| F290 | TTY detection mechanism gating interactive behavior | cli-framework-ux | different | DIVERGENT | R65 | bundle |
| F291 | Output-format choices | cli-framework-ux | different | DIVERGENT | R66 | bundle; py offers markdown, ts offers csv instead — decides F293 |
| F292 | `--json` shorthand flag | cli-framework-ux | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free pattern: both have a `--json` shortcut; ts declares an explicit conflict with `--format`, py resolves precedence in code — an implementation nuance within the same shared pattern |
| F293 | Result-to-file redirection flag | cli-framework-ux | different | DIVERGENT | R66 | bundle; naming collision between py's `--output-file`/`-o`/`--output` split and ts's single `--output` — part of the same output-surface-naming decision as F291 |
| F294 | JSON machine-readable error envelope on stderr | cli-framework-ux | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free pattern: both emit a JSON error envelope on stderr; its field content is F295/F296 |
| F295 | Error-envelope "code" field source | cli-framework-ux | different | DIVERGENT | R67 | bundle; py's stable append-only error-code catalog vs ts's transient exception-class-name code — the whole error/exit-code/signal-handling contract (cross-area `error-taxonomy-exit-codes`, owned by this area) — decides F296-F300, F302 |
| F296 | Structured `hint` field on an error, rendered separately from the message | cli-framework-ux | py-only | DIVERGENT | R67 | bundle |
| F297 | Exit-code taxonomy | cli-framework-ux | different | DIVERGENT | R67 | bundle |
| F298 | Process-interrupt (Ctrl-C) exit-code contract | cli-framework-ux | different | DIVERGENT | R67 | bundle |
| F299 | Interactive-prompt cancellation (^C mid-prompt) | cli-framework-ux | ts-only | DIVERGENT | R67 | bundle; contingent on R61 adopting an interactive-prompt crate at all |
| F300 | Broken-pipe (EPIPE) handling | cli-framework-ux | ts-only | DIVERGENT | R67 | bundle |
| F301 | Unexpected-error stack trace shown to the user only under verbose/debug | cli-framework-ux | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free pattern: both gate the stack trace on a verbose/debug flag |
| F302 | Unexpected errors persisted to a crash log file | cli-framework-ux | py-only | DIVERGENT | R67 | bundle; same fact as config-env-logging's forward-referenced crash-log row (`crash_path = paths.state_file("crash")`, `cli/options.py:143`) — owned here since it's part of this area's error/exit-code contract |
| F303 | web service exists at all | web-service | py-only | DIVERGENT | R69 | bundle; whether Rust adopts axum/actix-web/etc. — decides F330, F338, F339; distinct from F017 (workspace-architecture, already ADOPTed), which covers only whether the web service ships as an optional Cargo feature at all |
| F304 | tracing dependencies are a further, separate optional extra | web-service | py-only | ADOPT | — | Cargo feature flags natively support layering a second, narrower feature (`otel`) beyond `web`; same nothing-to-choose mechanism as F017 |
| F305 | single RFC 9457 error envelope for every non-2xx response | web-service | py-only | DIVERGENT | R70 | bundle; whether Rust adopts an RFC 9457 problem+json crate/pattern for every non-2xx response — decides F306 |
| F306 | domain-error-to-HTTP-status mapping table | web-service | py-only | DIVERGENT | R70 | bundle; depends on cli-framework-ux's error taxonomy (F295, R67) for which error variants exist, but the HTTP-status mapping itself is a web-only decision |
| F307 | OpenAPI schema is post-processed to match the runtime error shape | web-service | py-only | DIVERGENT | R71 | bundle; whether Rust's OpenAPI-generation crate (e.g. `utoipa`/`aide`) needs a post-processing step to keep the generated schema in sync with the actual error envelope — decides F312, F332, F333, F334, F335 |
| F308 | business routes are version-prefixed; ops endpoints are not | web-service | py-only | ADOPT | — | URL-prefix convention, trivial in any Rust router; nothing to choose |
| F309 | route deprecation signaling helper | web-service | py-only | ADOPT | — | RFC 8594 `Deprecation`/`Sunset` response headers are plain header-stamping, independent of the web framework picked |
| F310 | collection pagination via page/size query params and items/total envelope | web-service | py-only | DIVERGENT | R72 | bundle; whether Rust adopts a pagination crate/extractor for the page/size + items/total envelope — decides F311 |
| F311 | pagination is wired app-wide via one factory call | web-service | py-only | DIVERGENT | R72 | bundle |
| F312 | OpenAPI operation ids are curated as stable `tag-function` names | web-service | py-only | DIVERGENT | R71 | bundle |
| F313 | unsafe-method requests replay a cached response via `Idempotency-Key` | web-service | py-only | DIVERGENT | R73 | bundle; whether Rust adopts an idempotency-key replay middleware — decides F314, F315 |
| F314 | idempotency cache only stores successful (2xx) outcomes | web-service | py-only | DIVERGENT | R73 | bundle |
| F315 | idempotency cache store is in-memory, single-instance by design | web-service | py-only | DIVERGENT | R73 | bundle |
| F316 | rate-limit store is in-memory, single-instance by design | web-service | py-only | DIVERGENT | R74 | bundle, decided together with F323 (this area's rate-limiting env-var-gate decision) |
| F317 | middleware ordering is a contract (id/security-header middleware outermost) | web-service | py-only | DIVERGENT | R75 | bundle; whether Rust adopts a tower/tower-http middleware-layer stack for request-id, access-log, and security-header cross-cutting concerns, and in what order — decides F318, F319, F320, F321, F327 |
| F318 | request-id propagation through log context and response header | web-service | py-only | DIVERGENT | R75 | bundle |
| F319 | one canonical structured access-log event per request | web-service | py-only | DIVERGENT | R75 | bundle |
| F320 | probe endpoints are excluded from access-log volume | web-service | py-only | DIVERGENT | R75 | bundle |
| F321 | security response headers stamped on every response | web-service | py-only | DIVERGENT | R75 | bundle |
| F322 | CORS middleware installed only when an allowlist is configured | web-service | py-only | DIVERGENT | R76 | standalone; whether Rust adopts tower-http's `CorsLayer` (or similar), installed conditionally |
| F323 | rate limiting is wired but off by default, one env var enables it | web-service | py-only | DIVERGENT | R74 | bundle; whether Rust adopts a rate-limiting crate (e.g. `tower-governor`) wired off by default — decides F316 |
| F324 | typed env settings with an app-derived env-var prefix | web-service | py-only | DIVERGENT | R77 | standalone; whether Rust threads env-var-driven `WebSettings` through the framework's state/DI mechanism with a derived prefix |
| F325 | OpenTelemetry tracing is opt-in and soft-imported | web-service | py-only | DIVERGENT | R78 | standalone; whether Rust's optional OTel support is a compile-time Cargo feature gate rather than py's runtime soft-import degrade |
| F326 | Prometheus RED metrics exposed at /metrics, on by default | web-service | py-only | DIVERGENT | R79 | standalone; whether Rust adopts a metrics crate/exporter (e.g. `metrics` + `metrics-exporter-prometheus`) for RED metrics at `/metrics` |
| F327 | uvicorn's own loggers are folded into the shared logging pipeline | web-service | py-only | DIVERGENT | R75 | bundle; whether the chosen framework/server's own trace/access logs are folded into the shared `tracing` pipeline instead of double-logging |
| F328 | liveness endpoint reports version + runtime info | web-service | py-only | DIVERGENT | R80 | bundle; whether/how Rust's `/healthz` liveness endpoint reports version + runtime info — decides F329 |
| F329 | readiness endpoint runs the same diagnostics as the CLI doctor command | web-service | py-only | DIVERGENT | R80 | bundle |
| F330 | config loads once at startup, with a lazy-load fallback dependency | web-service | py-only | DIVERGENT | R69 | bundle; the framework's DI/extractor mechanism for threading already-loaded config into request handlers, with a lazy-load fallback for raw-ASGI-style callers |
| F331 | adding an API resource is one router import plus one registry entry | web-service | py-only | ADOPT | — | a registry-list extensibility pattern, language-neutral; nothing to research |
| F332 | committed OpenAPI snapshot is the reviewable API contract, staleness-tested | web-service | py-only | DIVERGENT | R71 | bundle |
| F333 | breaking-change detection against the base branch in CI | web-service | py-only | DIVERGENT | R71 | bundle; whether a Rust-ecosystem equivalent of `oasdiff` exists for OpenAPI breaking-change detection in CI |
| F334 | contract fuzzing generates cases for every documented operation | web-service | py-only | DIVERGENT | R71 | bundle; whether a Rust-ecosystem equivalent of `schemathesis` exists for OpenAPI-schema-driven contract fuzzing |
| F335 | typed client generation from the committed snapshot, never hand-written | web-service | py-only | DIVERGENT | R71 | bundle; whether a Rust-ecosystem equivalent of `openapi-python-client` exists for typed client generation from the committed snapshot |
| F336 | production container image is a non-root multi-stage build | web-service | py-only | DIVERGENT | R51 | bundle, cross-area with packaging-distribution's F223 (R51 — container image as a distribution artifact); this row adds the build-stage-layering fact from the web-service angle |
| F337 | container declares its own liveness healthcheck | web-service | py-only | DIVERGENT | R51 | bundle, cross-area with F223/R51; probes the `/healthz` endpoint decided at F328 |
| F338 | production entrypoint runs the ASGI server with settings-driven graceful shutdown | web-service | py-only | DIVERGENT | R69 | bundle |
| F339 | dev server recipe runs with auto-reload and pretty console logs | web-service | py-only | DIVERGENT | R69 | bundle; also needs a Rust file-watch/auto-rebuild tool (e.g. `cargo-watch`/`bacon`) for the dev-mode reload loop |
| F340 | importing the web package without the extra installed raises an actionable error | web-service | py-only | OMIT | — | Cargo feature gating is compile-time: code behind an unenabled `web` feature simply does not exist in the binary, so there is no runtime import-failure path to raise an actionable error from |
| F341 | docs delivery model | docs-system | different | DIVERGENT | R81 | bundle; whether rs-launch-blueprint ships a generated, hosted docs site (mdBook-style, py's shape) or a README-centric plain-markdown tree (ts's shape) — decides F343, F344, F345, F346, F351, F352, F353 |
| F342 | documentation information architecture | docs-system | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; the Diátaxis category set (about/tasks/tools/tutorials/reference/contributing) is a language-neutral information-architecture convention, independent of the generator R81 picks |
| F343 | markdown dialect | docs-system | different | DIVERGENT | R81 | bundle; mdBook's extended-CommonMark surface vs. plain CommonMark/GFM, downstream of R81's delivery-model pick |
| F344 | section navigation mechanism | docs-system | different | DIVERGENT | R81 | bundle; mdBook's `SUMMARY.md` vs. a plain bullet-list index, downstream of R81 |
| F345 | root-README vs. site-landing-page duplication | docs-system | different | DIVERGENT | R81 | bundle; duplication only exists if R81 adopts a separate hosted site |
| F346 | root README "documentation" pointer | docs-system | different | DIVERGENT | R81 | bundle; whether the README links to a hosted site or an in-repo tree follows R81 |
| F347 | documentation authoring guide (how to add a page) | docs-system | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; a contributor-facing "how to add a doc page" guide is a language-neutral pattern; its content mechanics (toctree/labels vs. relative links) are downstream of whatever R81 picks, not a separate decision |
| F348 | doc content correctness gate | docs-system | different | DIVERGENT | R82 | bundle; whether Rust adopts a link-checking tool/strategy (e.g. `lychee`) covering both internal and external links, and how it gates CI — decides F349, F350 |
| F349 | offline relative-link checker tool | docs-system | ts-only | DIVERGENT | R82 | bundle |
| F350 | external URL link-check | docs-system | py-only | DIVERGENT | R82 | bundle |
| F351 | local docs preview server (hot reload) | docs-system | py-only | DIVERGENT | R81 | bundle; `mdbook serve`'s built-in live reload is the plausible analogue, downstream of R81 |
| F352 | docs scaffold/init recipe | docs-system | py-only | DIVERGENT | R81 | bundle; `mdbook init`'s analogue, downstream of R81 |
| F353 | API reference doc generator | docs-system | different | DIVERGENT | R81 | bundle; whether `cargo doc`/rustdoc is CI-gated (`-D warnings` on broken intra-doc links) as part of the docs-correctness posture, and how it relates to whatever site R81 picks |
| F354 | ADR (Architecture Decision Record) system | docs-system | py-only | ADOPT | — | language-neutral process convention (a numbered decision-record directory); nothing Rust-specific to research |
| F355 | design-spec doc system | docs-system | py-only | ADOPT | — | language-neutral process convention, same shape as F354 |
| F356 | research doc system | docs-system | py-only | ADOPT | — | language-neutral process convention, same shape as F354 |
| F357 | internal-docs top-level orientation page | docs-system | py-only | ADOPT | — | doc-convenience artifact whose content tracks F354/F355/F356's adoption; nothing separate to research |
| F358 | documented (unshipped) future docs-site upgrade path | docs-system | ts-only | ADOPT | — | tracks R81's delivery-model decision; noting a future upgrade path (if any) is optional documentation color, not a separate research question |

## Override arguments
