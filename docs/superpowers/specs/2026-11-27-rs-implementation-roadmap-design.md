# RS Launch Blueprint — Implementation Roadmap, Parity Map & Blaze Accelerator Design

**Date:** 2026-11-27  
**Status:** Owner-approved (review gate accepted 2026-11-27)  
**Baseline:** `rs-launch-blueprint` at `d9e0e8a6` (`v0.2.0`), `py-launch-blueprint` at `855e102` (`v4.2.0`), `indexable-inc/blaze` at `v0.20261127.0`

---

## 1. Objective & Governing Principles

Build `rs-launch-blueprint` from its completed research baseline (`P01` `v0.1.0`, `P02` `v0.2.0`) to full feature parity with `py-launch-blueprint` (`v4.2.0`) using idiomatic Rust engineering designs grounded in the 85 audited `R##` research decisions (`research/CLAUDE.md`) and owner-locked parameters (`docs/port/PARAMETERS.md`).

Governing constraints inherited from `AGENTS.md`, `docs/port/README.md`, and owner review-gate rulings (2026-11-27):

- **Fixed parameters (`docs/port/PARAMETERS.md`):** Rust edition `2024`, MSRV `stable - 2` minor versions (declared in `rust-version`, tested in CI), target OS matrix `ubuntu-latest` + `macos-latest` (no Windows), dual license `MIT OR Apache-2.0`, root package `rs-launch-blueprint`, binaries `rslbp` and `rslbp-serve`.
- **Principles-first & auditable overrides:** Every phase implements the accepted `R##` decisions; any departure required by live implementation evidence or post-`b08bccf` owner decisions is recorded explicitly as an `OVERRIDE (OV-nn)` with argument and options.
- **Owner review-gate rulings (2026-11-27):**
  - **1a — GHCR container publishing (`publish-container.yml`):** **OVERRIDE `R51`** to add GHCR container publishing on stable releases alongside the checked-in CI-verified `Dockerfile`, achieving full parity with `py-launch-blueprint` `v4.2.0` (`PR #529`, `#606`).
  - **1b — Muse `audit-triage.yml`:** Include in `P10`, credential-preflight gated on `META_MUSE_CI_API_KEY`, matching `py-launch-blueprint` `P08` (`muse-spark-1.3-contributor`).
  - **1c — Anthropic OSS Scanner enrollment (`.oss-scanner/`):** Defer until post-`P13`.
  - **2 — Local accelerator (`indexable-inc/blaze`):** Adopt as an opt-in local edit-loop accelerator for the default CLI/core workspace with automatic Cargo fallback; Cargo remains authoritative for CI, MSRV, lint/format, coverage, and releases.
  - **3 — Execution model:** 12 sequential phases (`P02` closeout, `P03`, `P04`–`P13`) executed serially via Rex tabs inside the existing `rs-launch-blueprint` session using `agy --dangerously-skip-permissions`.

---

## 2. Feature Parity Map (`py-launch-blueprint` → `rs-launch-blueprint`)

### 2.1 The 13 Researched Areas (`360` `F###` rows, `85` `R##` items)

All 10 `OMIT` rows (`F037`, `F076`, `F088`, `F090`, `F095`, `F215`, `F217`, `F244`, `F248`, `F340`) are genuinely non-analogous in Rust. The remaining 350 rows (`95` `REUSE`/`ADOPT` + `255` researched across `R01`–`R86`, `R36` vacated) map across `P02`–`P13`:

| # | Area | `py-launch-blueprint` Reference | `rs-launch-blueprint` Native Design (`R##`) | Phase |
|---|---|---|---|---|
| 1 | **Workspace Architecture** | Single package with `core/`/`cli/`/`web/` split (`tach`, `import-linter`), `composition.py`, `Protocol` ports | **4-package Cargo root workspace** (`R02`, `OV-03`): root facade `rs-launch-blueprint` (`src/lib.rs`, `[[bin]] rslbp`, `[[bin]] rslbp-serve`, composition root, prod adapter) + `crates/core` + `crates/cli` + optional `crates/web`. Sync core (`R05`, `ureq`), async confined to `web`. `pub trait ProjectsPort: Send + Sync` (`R01`), `Result<Option<T>, PortError>` (`R03`), private modules + barrel + `cargo-semver-checks` (`R04`), workspace `unsafe_code = "forbid"` (`R06`), `cargo-deny` bans (`R02`). | `P04`, `P06` |
| 2 | **Dev Toolchain & Build** | `Makefile` (L1) + `Justfile` (L2), `uv` + `uv_build`, `[parallel]` check | Native origin-routed toolchain (`R42`): `rust-toolchain.toml` (`profile = "minimal"`, `components = ["rustfmt", "clippy"]`), `Makefile` (L1) + `Justfile` (L2, bare tool / `cargo <sub>` invocations), Cargo manifest targets (`R49`, `autobins = false`, explicit `[package] include`), `[parallel]` `just check` (py `P11`), **+ opt-in Blaze local accelerator** (§3). | `P04` |
| 3 | **Lint, Format & Static Analysis** | `ruff`, `ty`, `taplo`, `yamllint`, `bandit` | `rustfmt` (`rustfmt.toml`, 5 stable keys, `R27`), `clippy` workspace lints (`R28`), `cargo check` explicit `just typecheck` gate (`R30`), `dprint` 0.57.4 with 4 checksum-pinned Wasm plugins for TOML/YAML/JSON/MD (`R29`), `ast-grep` 0.45.3 with 5 template-owned self-tested security rules (`R31`). | `P04`, `P05` |
| 4 | **Git Hooks & Commit Hygiene** | `lefthook`, `commitlint`, `gitleaks`, large-file guard, lockfile freshness, `codespell`, shellcheck | `lefthook` 2.1.14 (`R37`), `committed` 1.1.11 (`R38`: 11 CC types, 50/72/72 soft-line, dependabot width exemption), `gitleaks` 8.30.1 pre-commit + pre-push (`R39`), POSIX `scripts/check-large-files.sh` (>1 MiB, `.gitattributes` `large-file-ok`, `R14`), `typos` + `.editorconfig` + auxiliary hooks (`R40`), conditional unlocked `Cargo.lock` freshness check (`R41`), `scripts/check-shell.sh`. | `P05` |
| 5 | **Dev Experience & AI Config** | `AGENTS.md`, `CLAUDE.md`, `.devcontainer/`, VS Code, `contributors-please` | `AGENTS.md` canonical + `CLAUDE.md`, no vendor rule dirs (`.cursor/`, `.windsurf/`), single `.claude/settings.json` `companyAnnouncements` (`R43`), image-only Debian Trixie Rust DevContainer pinned by digest (`R44`), no per-file license headers (`R46`), `contributors-please render` guarded recipe (`R47`), PR template with no bot `@`-mentions (`R45`). | `P05`, `P12` |
| 6 | **Config, Env, Secrets & Logging** | Layered TOML (`tomllib`/`tomlkit`), Pydantic, XDG dirs, redaction, `structlog` + rotating file sink | `toml` 1.1.6 (read) + `toml_edit` 0.25.15 (comment-preserving write, `R52`), `serde` derive + `Unvalidated`/`Valid` type-state (`R53`), 6-rung CLI Design Standard R5.1 precedence with ancestor `.rslbp/rslbp_config.toml` (`R54`), provenance-aware two-phase error tolerance (`R55`), secret policy prohibiting config-file tokens + `--token-file`/stdin/`RSLBP_TOKEN`/`0600 credentials.toml` + `secrecy`/`zeroize` + optional `keychain` (`R56`), `etcetera` 0.11.0 4-dir `Paths` (`R57`), `tracing` 0.1.44 + `tracing-subscriber` 0.3.23 owned redacting JSON/console formatters + `reload::Handle` (`OV-09`, `R58`), std-only `RotatingFile` CLI sink (`R59`). | `P06` |
| 7 | **CLI Framework & UX** | `plbp` (`typer` + `rich`), global flags, text/JSON/MD output, exit codes, prompts, pager, clipboard | `rslbp`: `clap` 4.6.6 derive (`derive`, `env`, `wrap_help`) + `clap_complete` + dependency-free `build.rs` (`R60`), `inquire` 0.9.4 behind `Prompter` trait (`OV-02`: declined confirm exits 0, `R61`), `--copy` via `arboard` 3.6.1 behind default-on `clipboard` feature (`R62`), `indicatif` 0.18 spinner (`R63`), `shlex` 2.0.1 2-tier pager (`R64`), `anstream`/`anstyle` 4-tier color chain (`R65`), `-o table\|json\|markdown\|name` + `--json` + `--output-file` with exact-pinned `tabled =0.22.0` (`R66`), capability-gated OSC-8 + relative time rich rows (`R85`), `error-contract/v1` (`RSLBxxx`, exit codes `0/1/2/3/4/5/130/143`, `thiserror` lib / `anyhow` bin, broken-pipe, crash sink, `R67`). | `P07` |
| 8 | **Testing & Coverage** | `pytest`, `hypothesis`, `syrupy`, built-CLI tests, `coverage.py`, weekly canary | `cargo-nextest` (`.config/nextest.toml`, 60s timeout, tier selectors, opt-in pre-push) + `cargo test --doc` + `assert_cmd`/`predicates` built-binary tests (`R32`), `proptest` 1.11.0 + `insta` 1.48.0 snapshots (`R33`), hand-written fakes + `RecordingPort<P>` + optional `mockall` 0.15.0 + `httpmock` 0.8.3 (`R48`), `cargo-llvm-cov` 0.9.1 + `llvm-tools-preview` (`R35`), weekly 3-leg `canary.yml` (`R34`). | `P07`, `P10` |
| 9 | **Web Service & API** | FastAPI (`--extra web` + `--extra otel`), RFC 9457, `/v1`, pagination, idempotency, rate-limit, CORS, Prometheus, OTel, OpenAPI snapshot + `oasdiff` + fuzzing + client gen, Dockerfile + GHCR | `axum` 0.8.9 + `tokio` 1.53.1 behind off-by-default `web = ["dep:rs-launch-blueprint-web"]` + `[[bin]] rslbp-serve` (`R69`, `bacon` 3.25.0 dev watcher), RFC 9457 `problem+json` (`R70`), `utoipa` 6.0.0 + `utoipa-axum` 0.3.0 OpenAPI snapshot + `oasdiff` (`R71`), first-party cursor pagination (`base64`, `R72`), compare-and-set `IdempotencyStore` (`R73`), owned rate limiter (`R74`), fixed-order `tower-http` 0.7.1 middleware stack (`R75`), CORS (`OV-08`, `R76`), `std::env` `RSLBP_WEB_*` settings (`OV-04`, `R77`), nested `otel` (`tracing-opentelemetry` 0.34 + OTel 0.33, `R78`) & `metrics` (`metrics` 0.24.6 + `metrics-exporter-prometheus` 0.18.3, `OV-07`, `R79`), `/healthz` + `/readyz` (`OV-05`, `R80`), R83 OpenAPI contract/proptest suite, `openapi-to-rust` 0.17.0 typed client gen (`OV-11`, `R84`), multi-stage `Dockerfile` + `.dockerignore` (`R51`) **+ GHCR `publish-container.yml` (owner override of `R51`, 2026-11-27)**. | `P08`, `P09`, `P11` |
| 10 | **CI & Security Workflows** | `ci.yml`, `lint.yml`, `dep-audit.yml`, `dependency-review.yml`, `codeql.yml`, `secret-scan.yml`, `commitlint.yml`, `large-file-guard.yml`, `api-contract.yml`, `claude*.yml`, `audit-triage.yml`, `dependabot.yml` | Plan-gated compile-tier `ci.yml` (`R11`): `plan` (fail-closed `code`/`web`/`workflows`/`docs` + release-please fast-path) → `hygiene`, `workflow-lint`, OS-matrix `check` (`ubuntu-latest`/`macos-latest`, `Swatinem/rust-cache` `R10`, feature-off/on + `--all-features`/OTel coverage), `msrv-floor`, `install-smoke` (`R50`), aggregate `ci-ok` (`R12`). Uniform `permissions: {}` (`R08`), literal runners (`R09`), full-SHA pinning + `zizmor` (`R20`), `dep-audit.yml` (`cargo-audit`/`cargo-deny`/OSV, `R13`), CodeQL config (`R16`), TruffleHog OSS CLI (`R17`), `claude-code-review.yml` + `claude.yml` (`R18`), Codex review + `/codex` (`R86`), **Muse `audit-triage.yml`** (owner decision `1b-A`), 2-entry `dependabot.yml` (`R19`), `contributors-please` (`R07`, `R21`). | `P10` |
| 11 | **Release & Packaging** | `release-please`, static version, PyPI OIDC publish, GHCR publish | `pub const VERSION: &str = env!("CARGO_PKG_VERSION")` (`R22`), `release-please` `release-type: rust` (`R23`), ordered 11-type changelog (`R24`), `0.1.0` pre-major dampening (`R25`), 4 first-party `.crate` content checks (`R26`), `cargo-dist` 0.33.0 follower-mode binaries (`x86_64-linux-gnu`, `x86_64-darwin`, `aarch64-darwin`, shell installer) + `[profile.release]` `lto = "fat"`, `codegen-units = 1` (`R68`), `publish-container.yml` (GHCR), `install-smoke` (`R50`). | `P11` |
| 12 | **Template Press & Bootstrap** | `template-press 4.1+`, `press/stubs/*`, `press-verify.yml`, `template-receipt-guard.yml`, `bootstrap-acceptance.yml`, global `new-python-project` skill | `template-press 4.1+` (`R15` + py `P07`), `press/press-rules.toml` (`keep_names = ["smorinlabs/difftree-action"]`), `press/stubs/*`, `press-verify.yml`, `template-receipt-guard.yml`, `bootstrap-acceptance.yml`, global + project-scoped `.claude/skills/new-rust-project/SKILL.md` (`.agents/skills/` symlink), `docs/PROJECT_SETUP.md`, `docs/POST_INIT.md`. | `P12` |
| 13 | **Documentation System** | Sphinx + MyST + ReadTheDocs + linkcheck | Single CommonMark/GFM `docs/` corpus rendered on GitHub **and** built with `mdbook` 0.5.4 to GitHub Pages (`R81`), `lychee` 0.24.2 internal PR + scheduled external link checks + `RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --all-features` (`R82`), `README.md`, `EXAMPLECLI.md`, `EXAMPLEWEB.md`. | `P13` |

### 2.2 Post-`b08bccf` `py-launch-blueprint` Delta (`b08bccf` → `855e102` `v4.2.0`)

| Addition in `py-launch-blueprint` | PRs / Project | Disposition | Phase |
|---|---|---|---|
| Difftree PR comment + `press` inheritance (`keep_names`) | `#618` | In `P03` + `P12` | `P03`, `P12` |
| Template Press `4.1+`, `press/stubs/*`, `docs/PROJECT_SETUP.md`, `bootstrap-acceptance.yml` | `P07`, `#530`, `#532`, `#607` | Adopted in `P12` | `P12` |
| Global + project-scoped bootstrap skill (`new-rust-project`) | `#616` | Adopted in `P12` | `P12` |
| OTel extra CI coverage (enabled & disabled paths) | `P10`, `#587` | Adopted in `P09`, `P10` | `P09`, `P10` |
| Parallel `just check` gate (`[parallel]`) | `P11`, `#611` | Adopted in `P04` | `P04` |
| Slim PR CI job count & release-please fast-path | `P12`, `#612`, `#614` | Adopted in `P10` (`R11`) | `P10` |
| ShellCheck CI + pre-commit | `#546` | Already in repo; folded into `P05`/`P10` | `P05`, `P10` |
| `.github/CODEOWNERS` | `#530+` | Adopted in `P12` | `P12` |
| GHCR container publishing (`publish-container.yml`) | `#529`, `#606` | **Approved OVERRIDE of `R51` (`1a-A`)** | `P09`, `P11` |
| Muse `audit-triage.yml` (`muse-spark-1.3-contributor`) | `P08`, `#556`, `#557`, `#578`, `#608` | **Approved (`1b-A`)** | `P10` |
| Anthropic OSS Scanner (`.oss-scanner/`) | `P09`, `#581` | **Deferred post-`P13` (`1c-A`)** | Deferred |

---

## 3. Empirical Feasibility Analysis: `indexable-inc/blaze` as Local Accelerator

Assessed against [`indexable-inc/blaze`](https://github.com/indexable-inc/blaze) `v0.20261127.0` (`nightly-2026-10-27`, Apache-2.0 OR MIT, installed locally on Apple Silicon macOS during preflight).

### 3.1 Architectural Properties & Boundaries

- **How v2 works:** Daemonless command-per-invocation compiler backed by a content-addressed on-disk store (`~/.blaze/v2`) shared across checkouts and git worktrees; per-function copy-and-patch JIT compilation + Blaze's own ELF/Mach-O linker; Wasmtime `wasm64` sandboxing for proc macros and pure-Rust build scripts.
- **Supported commands:** `blaze check`, `blaze test`, `blaze run`, `blaze build`, `blaze clean`, `blaze gc`, `blaze why`, `blaze inspect`, `blaze ci`.
- **Toolchain semantics:** Builds with its own pinned nightly (`nightly-2026-10-27`), ignoring `rust-toolchain.toml`, `rustup`, `RUSTUP_TOOLCHAIN`, and `RUSTC`, and does not enforce `rust-version` MSRV checks.
- **Platforms:** macOS Apple Silicon (`arm64`) and Linux (`x86-64` & `arm64`, glibc >= 2.34). Matches `rs-launch-blueprint`'s `ubuntu-latest` + `macos-latest` matrix (no Windows/Intel Mac). DevContainers require user namespaces, Landlock, or `--security-opt seccomp=unconfined`.

### 3.2 Compatibility Matrix vs. `rs-launch-blueprint` Crate Graph

| Surface | Key Crates / Tools | Status at `v0.20261127.0` | Policy |
|---|---|---|---|
| **Default workspace** (`rs-launch-blueprint`, `crates/core`, `crates/cli`, `rslbp` — feature-off) | Sync core (`R05`, ~38 deps): `clap`, `serde`, `toml`, `toml_edit`, `thiserror`, `anyhow`, `ureq`, `tracing`, `etcetera`, `secrecy`, `tabled`, `anstream`, `indicatif`, `inquire`, `shlex`, `arboard` | **Compatible target** (no known open Blaze blockers; empirically smoke-tested in `P04`, `P06`, `P07`) | **Primary Blaze accelerator target** |
| **`--features web`** (`crates/web`, `rslbp-serve`) | `axum`, `tokio`, `tower-http`, **`utoipa` / `utoipa-gen` (`R71`)** | **Blocked upstream by `indexable-inc/blaze#598`** (`utoipa-gen` fails MIR lowering with `UnresolvedMethod("collect")` on recursive `-> Result<impl Iterator<...>>`; `BLAZE_PROC_MACRO_WASM=0` does not bypass it) | Fallback to `cargo` / `bacon` until `#598` closes; re-probed in `P09` |
| **`--features metrics`** | **`metrics 0.24.6` + `metrics-exporter-prometheus 0.18.3` (`R79`)** | **Blocked upstream by `indexable-inc/blaze#1826`** (`mir: UnresolvedField` in `metrics-util` Registry handle closures on exact R79 versions) | Fallback to `cargo` until `#1826` closes; re-probed in `P09` |
| **`--features otel`** | `tracing-opentelemetry`, `opentelemetry*` | Upstream `#1826` reports OTel crates build, but our `otel` nests on `web` (`utoipa-gen`) | Fallback to `cargo` while `web` pulls `utoipa-gen` |
| **Lint, fmt, audit, coverage, MSRV, packaging, CI** | `clippy`, `rustfmt`, `cargo-deny`, `cargo-audit`, `cargo-nextest`, `cargo-llvm-cov`, `cargo-semver-checks`, `cargo package`, `cargo-dist` | Unsupported by Blaze by design | **Cargo-authoritative always** |

### 3.3 Integration Contract

1. **Opt-in only:** Never required by `make bootstrap`, `just setup`, `just check`, git hooks, or CI.
2. **`Justfile` recipes (`P04`+):**
   - `just blaze-check`, `just blaze-test`, `just blaze-run *args` — run `blaze` on default-workspace targets when `blaze` is on `PATH`; gracefully fall back to `cargo` with a one-line notice when `blaze` is absent.
   - `just blaze-status` — prints installed `blaze` version vs. `rust-toolchain.toml` and runs a live probe of default workspace vs. optional features (`web`/`metrics`) so contributors see immediately if `#598`/`#1826` close upstream.
   - `just install-blaze` — documents/invokes the official installer (`curl -fsSL https://ix.dev/blaze | sh`) with platform/nightly caveats.
3. **Coexistence:** `blaze` accelerates the default CLI/core edit-test loop (and shares its `~/.blaze/v2` store across git worktrees); `bacon` (`R69`) handles watch-mode clippy & `crates/web` loops; `cargo` remains the sole authoritative gate.

---

## 4. Phased Implementation Sequence (`P01`–`P13`)

| ID | Project | Status | Depends On |
|---|---|---|---|
| `P01` | Port research program | `[x]` Done (`v0.1.0`) | — |
| `P02` | Execute research program *(closeout)* | `[~]` Closeout | `P01` |
| `P03` | Install difftree-action PR comment workflow | `[ ]` Scoped | `P02` |
| `P04` | Workspace skeleton toolchain and Blaze accelerator | `[ ]` Scoped | `P03` |
| `P05` | Local quality gates hooks and devcontainer | `[ ]` Scoped | `P04` |
| `P06` | Core library ports config and logging | `[ ]` Scoped | `P05` |
| `P07` | CLI rslbp feature parity and test harness | `[ ]` Scoped | `P06` |
| `P08` | Optional web service core and middleware | `[ ]` Scoped | `P07` |
| `P09` | OpenAPI contracts observability and container image | `[ ]` Scoped | `P08` |
| `P10` | GitHub Actions CI security and AI workflows | `[ ]` Scoped | `P09` |
| `P11` | Release automation binary distribution and packaging | `[ ]` Scoped | `P10` |
| `P12` | Template Press bootstrap skill and community files | `[ ]` Scoped | `P11` |
| `P13` | Documentation corpus examples and final parity audit | `[ ]` Scoped | `P12` |
