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
| F039 | Packed-artifact file-list assertion (only expected files ship) | ci-workflows | ts-only | DIVERGENT | R12 | `cargo package --list`/`cargo publish --dry-run` is the plausible Rust analogue; whether/how to assert it in CI is a real choice |
| F040 | A changes-detector job skips heavy jobs on docs-only PRs | ci-workflows | py-only | DIVERGENT | R11 | bundle; same path-filtered skip-gating question as F038 |
| F041 | Single aggregate required-status-check job folding in all other job results | ci-workflows | py-only | DIVERGENT | R13 | whether Rust CI needs one required-status-check job vs. listing every job individually as required |
| F042 | Scheduled full-dependency-graph vulnerability audit | ci-workflows | py-only | DIVERGENT | R14 | bundle; one Rust SCA/vulnerability-scanning strategy (scheduled audit + manual on-demand tool + always-on intent) — decides F048, F049 |
| F043 | Large-file size guard on new files | ci-workflows | py-only | DIVERGENT | R15 | CI-level redundancy question, distinct tier from git-hooks-commit-hygiene's hook-level large-file check |
| F044 | Template drift/receipt guard workflows | ci-workflows | py-only | DIVERGENT | R16 | whether rs-launch-blueprint is itself a template-press-rebrandable template; ts (a same-family port) did not carry this forward either |
| F045 | CodeQL custom config file (query pack selection plus paths-ignore) | ci-workflows | py-only | DIVERGENT | R17 | whether Rust's CodeQL scan gets a custom query-pack/paths-ignore config or the tool default |
| F046 | Dependency-review PR gate | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-05; tool: actions/dependency-review-action v5.0.0 (github.com/actions/dependency-review-action, checked 2026-09-02); supports Cargo.lock ecosystem detection |
| F047 | Manual, environment-gated PR security scan (workflow_dispatch) | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free pattern (workflow_dispatch inputs + protected GitHub environment); the scan tool itself is F048 |
| F048 | Manual security-scan tool | ci-workflows | different | DIVERGENT | R14 | bundle |
| F049 | Always-on SCA audit as commented, uncomment-to-enable scaffolding inside the main CI workflow | ci-workflows | ts-only | DIVERGENT | R14 | bundle |
| F050 | Dedicated secret-scanning CI workflow | ci-workflows | py-only | DIVERGENT | R18 | distinct tool and tier from git-hooks-commit-hygiene's gitleaks pre-commit/pre-push hooks; not bundled with that area |
| F051 | AI-assisted PR code review workflow | ci-workflows | py-only | DIVERGENT | R19 | bundle; same claude-code-action family as F052, plausibly adopted or dropped together |
| F052 | AI assistant workflow triggered by @mention comments | ci-workflows | py-only | DIVERGENT | R19 | bundle |
| F053 | Dependabot ecosystems configured | ci-workflows | different | DIVERGENT | R20 | bundle; ecosystems and grouping are one Dependabot-config-shape decision |
| F054 | Dependabot update grouping strategy | ci-workflows | different | DIVERGENT | R20 | bundle |
| F055 | Third-party GitHub Action pinning policy | ci-workflows | different | DIVERGENT | R21 | major-tag pin (py) vs. full-SHA pin plus version comment (ts) for third-party actions |
| F056 | actionlint config: self-hosted runner labels declared | ci-workflows | py-only | DIVERGENT | R09 | bundle; only needed if F031's vars.RUNNER_*/Blacksmith indirection is adopted |
| F057 | actionlint config: RUNNER_* config-variables declared | ci-workflows | py-only | DIVERGENT | R09 | bundle |
| F058 | actionlint config: stale-metadata suppression scope for create-github-app-token | ci-workflows | different | DIVERGENT | R22 | contingent on release-versioning's release-please-auth choice (whether create-github-app-token is used at all), but the suppression-scope call is CI's own actionlint-config decision |
| F059 | Publish workflow triggered on a `v*` tag push | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native GitHub Actions tag-push trigger syntax, no external tool |
| F060 | Automated contributors-list bot-PR workflow | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-06; tool: smorinlabs/contributors-please-action v1.3.9 (github.com/smorinlabs/contributors-please-action, checked 2026-09-02); language-neutral, operates on git history |
| F061 | Contributors-bot credential source for the PAT fallback | ci-workflows | different | DIVERGENT | R23 | dedicated repo secret (py) vs. zero-extra-secret GITHUB_TOKEN (ts) |
| F062 | Difftree PR-comment workflow | ci-workflows | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-09; tool: smorinlabs/difftree-action v0.7.2 (github.com/smorinlabs/difftree-action, checked 2026-09-02); byte-identical canonical template in both repos, language-neutral |
| F063 | version source of truth | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-04; tool: release-please (googleapis/release-please-action v5.0.0, checked 2026-09-02); Cargo.toml `[package] version` is the uncontested Rust manifest field |
| F064 | runtime version accessor | release-versioning | different | DIVERGENT | R24 | compile-time `env!("CARGO_PKG_VERSION")` (ts-like, build-time) vs. a runtime metadata lookup (py-like) |
| F065 | lockfile version sync in release commit | release-versioning | different | DIVERGENT | R25 | whether release-please's extra-files config must also bump Cargo.lock's workspace-member version entries |
| F066 | changelog file generation | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-04; tool: release-please |
| F067 | changelog section type mapping (visible vs hidden) | release-versioning | different | DIVERGENT | R26 | which Conventional-Commits types surface in CHANGELOG.md vs. stay hidden |
| F068 | changelog file preamble | release-versioning | ts-only | ADOPT | — | one-line boilerplate naming Keep a Changelog/SemVer, nothing to choose |
| F069 | release PR title customization | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-04; tool: release-please; exact wording is a content choice, not a research question |
| F070 | pre-1.0 semver bump strategy | release-versioning | ts-only | DIVERGENT | R27 | whether rs-launch-blueprint starts pre-1.0 (bump-minor-pre-major/bump-patch-for-minor-pre-major) or post-1.0 like py |
| F071 | release-please bootstrap-sha pin | release-versioning | py-only | ADOPT | — | mechanical: pin the commit release-please starts scanning from when first configured |
| F072 | release-please auth token mechanism | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-05; tool: actions/create-github-app-token v3.2.0 (github.com/actions/create-github-app-token, checked 2026-09-02) |
| F073 | release trigger (push opens PR, merge tags) | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-04; tool: release-please |
| F074 | publish workflow tag/version consistency guard | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free CI-script pattern (tag reachability plus manifest-version equality checks) |
| F075 | OIDC Trusted Publishing (no stored publish token) | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native GitHub OIDC (`id-token: write`) pattern; crates.io supports Trusted Publishing |
| F076 | staged publish to test registry before production | release-versioning | py-only | OMIT | — | crates.io has no test/staging registry; `cargo publish --dry-run` never uploads, so there is no Rust analogue to research |
| F077 | protected environment gate before publish | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; native GitHub protected-environment feature, no external tool |
| F078 | packed-artifact content guard in publish workflow | release-versioning | ts-only | DIVERGENT | R28 | whether Rust's publish workflow needs a guard against `cargo publish` silently altering package metadata |
| F079 | release version-surface drift-check recipe | release-versioning | ts-only | ADOPT | — | low-stakes diagnostic Justfile recipe mirroring F074's already-decided consistency check; nothing to research |
| F080 | CLI version-check recipe | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free Justfile-recipe convention |
| F081 | release runbook / setup doc | release-versioning | same | COMMON → REUSE | — | rust-ok: yes; live: n/a; tool-free maintainer-doc convention |
| F082 | documented opt-out from automated releases | release-versioning | py-only | ADOPT | — | doc-only instructions, nothing to choose |

## Override arguments
