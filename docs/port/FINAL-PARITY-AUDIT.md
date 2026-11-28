# Final End-to-End Parity Audit (`rs-launch-blueprint` vs. `py-launch-blueprint` `v4.2.0`)

**Date:** 2026-11-28  
**Scope:** Full 360-row `docs/port/COMMONALITY.md` ledger + 85 audited `R##` research decisions (`R01`–`R86`, `R36` vacated) + all 11 post-`b08bccf` `py-launch-blueprint` `v4.2.0` delta items + Blaze local accelerator status + final human GitHub setup checklist (`docs/PROJECT_SETUP.md`).  
**Automated verifier:** `python3 scripts/check-parity-audit.py` (enforced by `tests/parity_audit.rs`).

## Executive Summary

| Audit Dimension | Result | Notes |
| --- | --- | --- |
| `COMMONALITY.md` feature ledger | **360 / 360 accounted for** | **350 `IMPLEMENTED`** across `P03`–`P13`, **10 `OMITTED (non-analogous)`** (`F037`, `F076`, `F088`, `F090`, `F095`, `F215`, `F217`, `F244`, `F248`, `F340`) |
| Researched decisions (`research/CLAUDE.md`) | **85 / 85 implemented** | All `R01`–`R86` (`R36` vacated) resolved in `P02` and realized in `P03`–`P13` |
| Post-`b08bccf` `py-launch-blueprint` `v4.2.0` delta | **11 / 11 accounted for** | 10 implemented (including approved `1a-A` GHCR OVERRIDE of `R51` and `1b-A` Muse `audit-triage.yml`); 1 explicitly deferred (`1c-A` Anthropic OSS Scanner post-`P13`) |
| Local acceleration (`Blaze` + `bacon`) | **Verified & opt-in** | `blaze test -p rs-launch-blueprint-core` and `blaze build -p rs-launch-blueprint --bin rslbp` pass; Cargo remains sole authority; `bacon` handles `crates/web` watch loops |
| Template Press (`template-press 5.0.0`) | **Verified end-to-end** | `press verify` passes with 0 surviving leaks; stamped child passes `just check`, `just check-packaging`, `mdbook build`, `lychee --offline`, CLI `--version`, and `/healthz` |
| Gaps discovered & closed during P13 audit | **5 / 5 closed in P13** | `.github/FUNDING.yml` (`F205`), CLA docs (`F208`), `just version` (`F080`), `just release-status` (`F079`), RFC 9745/8594 `deprecation_headers` (`F309`) |

## Post-`b08bccf` `py-launch-blueprint` `v4.2.0` Delta Audit

Every post-`b08bccf` enhancement from `docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md` §2.2 is verified below:

| # | `py-launch-blueprint` Addition | Ruling / Phase | Status | Implementation Evidence |
| --- | --- | --- | --- | --- |
| 1 | Difftree PR comment + `press` inheritance (`keep_names`) | `P03`, `P12` | **IMPLEMENTED** | `.github/workflows/difftree-pr-comment.yml`, `press/press-rules.toml` (`keep_names = ["smorinlabs/difftree-action", ...]`), `tests/bootstrap_acceptance.rs` |
| 2 | Template Press `4.1+`/`5.0`, `press/stubs/*`, `docs/PROJECT_SETUP.md`, `bootstrap-acceptance.yml` | `P12` | **IMPLEMENTED** | `press/requirements.txt` (`template-press==5.0.0`), `press/press-rules.toml`, `press/stubs/*`, `docs/PROJECT_SETUP.md`, `.github/workflows/bootstrap-acceptance.yml` |
| 3 | Global + project-scoped bootstrap skill (`new-rust-project`) | `P12` | **IMPLEMENTED** | `.claude/skills/new-rust-project/{SKILL.md,README.md}`, `.agents/skills/new-rust-project` symlink, `docs/skills/new-rust-project.md` |
| 4 | OTel extra CI coverage (enabled & disabled paths) | `P09`, `P10` | **IMPLEMENTED** | `src/otel.rs`, `tests/otel_contract.rs`, `.github/workflows/ci.yml` (runs both `--features web` without OTel and `--all-features` with OTel) |
| 5 | Parallel `just check` gate (`[parallel]`) | `P04` | **IMPLEMENTED** | `Justfile` (`[parallel] @check:`), `tests/justfile_contract.rs` |
| 6 | Slim PR CI job count & `release-please` fast-path | `P10` (`R11`) | **IMPLEMENTED** | `.github/workflows/ci.yml` (`plan` `release_only` fast path), `tests/workflows_contract.rs` |
| 7 | ShellCheck CI + pre-commit | `P05`, `P10` | **IMPLEMENTED** | `scripts/check-shell.sh`, `scripts/test-check-shell.sh`, `lefthook.yml`, `.github/workflows/ci.yml` (`hygiene`) |
| 8 | `.github/CODEOWNERS` | `P12` | **IMPLEMENTED** | `.github/CODEOWNERS`, `tests/community_contract.rs` |
| 9 | GHCR container publishing (`publish-container.yml`) | Owner `1a-A` OVERRIDE of `R51` (`P11`) | **IMPLEMENTED** | `.github/workflows/publish-container.yml`, `scripts/publish_container.py`, `docs/RELEASE.md`, `tests/release_contract.rs` |
| 10 | Muse `audit-triage.yml` (`muse-spark-1.3-contributor`) | Owner `1b-A` (`P10`) | **IMPLEMENTED** | `.github/workflows/audit-triage.yml`, `.github/muse-audit-triage/*`, `.github/scripts/muse_audit_triage.py`, `tests/workflows_contract.rs` |
| 11 | Anthropic OSS Scanner (`.oss-scanner/`) | Owner `1c-A` | **DEFERRED** | Explicitly deferred until post-`P13` per owner review-gate ruling `1c-A` (2026-11-27) |

## Research Program Coverage (`R01`–`R86`)

All **85 / 85** resolved research items (`R36` vacated in `P01`) are implemented and verified:

| ID | Slug | Phase | Implementation Evidence |
| --- | --- | --- | --- |
| R01 | `ports-and-adapters-seam` | P06 | `crates/core/src/ports.rs`, `crates/core/src/service.rs`, `src/composition.rs`, `tests/ports_contract.rs` |
| R02 | `crate-boundary-enforcement` | P04 | `Cargo.toml`, `deny.toml`, `crates/core/clippy.toml`, `tests/workspace_edges.rs` (`OV-03`) |
| R03 | `port-absence-vs-failure-contract` | P06 | `crates/core/src/error.rs`, `crates/core/src/service.rs`, `src/http_adapter.rs`, `tests/ports_contract.rs` |
| R04 | `public-api-surface-enforcement` | P04/P11 | `Cargo.toml` (`unreachable_pub`/`private_interfaces`/`private_bounds`/`missing_docs`), `src/lib.rs`, `.github/workflows/publish.yml` (`cargo-semver-checks`) |
| R05 | `sync-async-execution-model` | P06/P08 | `src/http_adapter.rs` (`ureq`), `crates/web/src/routes/projects.rs` (`spawn_blocking`), `tests/http_adapter_boundary.rs` |
| R06 | `unsafe-code-policy` | P04 | `Cargo.toml` (`[workspace.lints.rust] unsafe_code = "forbid"`), `tests/workspace_edges.rs` |
| R07 | `contributors-bot-trigger-cadence` | P12 | `.github/workflows/update-contributors.yml`, `tests/bootstrap_acceptance.rs` |
| R08 | `workflow-permission-hardening` | P10 | `scripts/check-workflow-permissions.sh`, `.github/workflows/*.yml`, `zizmor.yml`, `tests/workflows_contract.rs` |
| R09 | `self-hosted-runner-indirection` | P10 | `.github/workflows/*.yml` (literal `ubuntu-latest`/`macos-latest`), `.github/actionlint.yaml`, `tests/workflows_contract.rs` |
| R10 | `dependency-cache-action` | P10 | `.github/workflows/ci.yml` (`Swatinem/rust-cache@6323deb...` with `ImageOS`, `v1-rslbp`) |
| R11 | `ci-workflow-job-structure` | P10 | `.github/workflows/ci.yml` (fail-closed `plan`, `hygiene`, `workflow-lint`, OS-matrix `check`, `msrv-floor`, `install-smoke`, `coverage`), `tests/workflows_contract.rs` |
| R12 | `aggregate-required-status-check` | P10 | `.github/workflows/ci.yml` (`ci-ok` aggregate + `workflow-lint` completeness check), `tests/workflows_contract.rs` |
| R13 | `dependency-vulnerability-scanning` | P10 | `.github/workflows/dep-audit.yml`, `.github/workflows/manual-pr-security-scan.yml`, `.cargo/audit.toml`, `ci.yml` SCA scaffold |
| R14 | `large-file-guard-strategy` | P05/P10 | `scripts/check-large-files.sh`, `scripts/test-check-large-files.sh`, `.gitattributes`, `lefthook.yml`, `.github/workflows/large-file-guard.yml` |
| R15 | `template-drift-receipt-guard` | P12 | `press/press-rules.toml`, `press/press-source.toml`, `press/requirements.txt`, `press/stubs/*`, `.github/workflows/press-verify.yml`, `.github/workflows/template-receipt-guard.yml`, `tests/bootstrap_acceptance.rs` |
| R16 | `codeql-config-customization` | P10 | `.github/workflows/codeql.yml`, `.github/codeql/codeql-config.yml`, `tests/workflows_contract.rs` |
| R17 | `secret-scanning-ci-workflow` | P10 | `.github/workflows/secret-scan.yml` (cosign-verified TruffleHog CLI `v3.97.4`), `tests/workflows_contract.rs` |
| R18 | `ai-assisted-review-workflows` | P10 | `.github/workflows/claude-code-review.yml`, `.github/workflows/claude.yml`, `.claude/commands/review-pr.md`, `tests/workflows_contract.rs` |
| R19 | `dependabot-config-shape` | P10 | `.github/dependabot.yml` (2 entries: `cargo` + `github-actions`, 5-day cooldown), `zizmor.yml`, `tests/workflows_contract.rs` |
| R20 | `third-party-action-pinning-policy` | P10 | `zizmor.yml`, `scripts/check-action-pin-comments.sh`, `.github/workflows/*.yml`, `tests/workflows_contract.rs` |
| R21 | `contributors-bot-credential-source` | P12 | `.github/workflows/update-contributors.yml` (App primary, `CONTRIBUTORS_PLEASE_PAT` fallback), `tests/bootstrap_acceptance.rs` |
| R22 | `runtime-version-accessor` | P06/P11 | `crates/core/src/metadata.rs` (`pub const VERSION`), `src/lib.rs`, `tests/release_contract.rs` |
| R23 | `lockfile-version-sync` | P11 | `release-please-config.json` (`release-type: rust`), `.github/workflows/release-please.yml`, `tests/release_contract.rs` |
| R24 | `changelog-section-mapping` | P11 | `release-please-config.json` (ordered 11-type changelog sections), `tests/release_contract.rs` |
| R25 | `semver-bump-strategy` | P11 | `release-please-config.json` (`bump-minor-pre-major`, `bump-patch-for-minor-pre-major`), `.release-please-manifest.json`, `Cargo.toml` (`0.1.0`) |
| R26 | `packed-artifact-content-guard` | P11 | `scripts/check-packed-artifacts.sh`, `ci/expected-packed-files/*`, `ci/expected-packaged-targets/*`, `.github/workflows/publish.yml`, `tests/release_contract.rs` |
| R27 | `formatter-config-surface` | P04/P05 | `rustfmt.toml`, `rust-toolchain.toml`, `Justfile` (`format`/`format-check`), `lefthook.yml`, `.github/workflows/ci.yml` |
| R28 | `linter-and-editor-tooling` | P04/P05 | `Cargo.toml` (`[workspace.lints.clippy]`), `clippy.toml`, `Justfile` (`lint`/`lint-fix`), `.vscode/settings.json`, `.vscode/extensions.json`, `.vscode/launch.json` |
| R29 | `non-code-file-formatting` | P05 | `dprint.json` (4 SHA-256 Wasm plugins), `Justfile` (`format-files`/`check-files`), `lefthook.yml`, `.github/workflows/ci.yml`, `tests/repo_hygiene.rs` |
| R30 | `type-check-gate` | P04/P10 | `Cargo.toml` (`rust_2018_idioms`), `Justfile` (`typecheck`), `.github/workflows/ci.yml` |
| R31 | `standalone-security-analyzer` | P05 | `sgconfig.yml`, `rules/*.yml`, `rules/tests/*`, `scripts/test-security-rules.sh`, `Justfile` (`security`), `lefthook.yml`, `.github/workflows/ci.yml` |
| R32 | `test-harness-and-execution` | P07/P10 | `.config/nextest.toml`, `Justfile` (`test`/`test-slow`/`test-live`/`test-all`), `lefthook.yml`, `tests/cli/*`, `.github/workflows/ci.yml` |
| R33 | `property-and-snapshot-testing` | P07 | `Cargo.toml` (`proptest`, `insta`), `tests/properties.rs`, `tests/cli/*` |
| R34 | `scheduled-freshness-lanes` | P10 | `.github/workflows/canary.yml` (weekly 3-leg freshness canary + single-issue report), `tests/workflows_contract.rs` |
| R35 | `coverage-tooling` | P07/P10 | `Justfile` (`coverage`, `coverage_fail_under`), `.github/workflows/ci.yml` (`coverage` job + artifact upload) |
| R37 | `hook-manager-distribution` | P05 | `lefthook.yml` (`min_version: 2.1.14`, `tags: [compiles]`), `Justfile` (`hooks-install`/`hooks-run`), `tests/repo_hygiene.rs` |
| R38 | `commit-message-linter` | P05/P10 | `committed.toml`, `committed.bot.toml`, `scripts/test-committed.sh`, `lefthook.yml`, `.github/workflows/commitlint.yml`, `tests/repo_hygiene.rs` |
| R39 | `secret-scanning-hooks` | P05 | `.gitleaks.toml`, `.gitleaksignore`, `lefthook.yml` (pre-commit + pre-push), `tests/repo_hygiene.rs` |
| R40 | `auxiliary-hygiene-hooks` | P05 | `.editorconfig`, `.editorconfig-checker.json`, `.yamllint`, `typos.toml`, `Justfile` (`check-hygiene`), `lefthook.yml`, `.github/workflows/ci.yml` |
| R41 | `lockfile-freshness-check` | P05 | `scripts/check-cargo-lock.sh`, `scripts/test-check-cargo-lock.sh`, `lefthook.yml`, `Justfile` (`check-lockfile`) |
| R42 | `dev-toolchain-provisioning` | P04 | `Makefile`, `Justfile` (single tool table, bare/`cargo <sub>` invocations, zero provisioner prefixes), `tests/justfile_contract.rs` |
| R43 | `ai-assistant-repo-furniture` | P05 | `AGENTS.md`, `CLAUDE.md`, `.claude/settings.json` (`companyAnnouncements`), zero `.cursor/`/`.windsurf/`/`.devin/`, `tests/repo_hygiene.rs` |
| R44 | `devcontainer-environment` | P05 | `.devcontainer/devcontainer.json` (digest-pinned Trixie Rust image), `.devcontainer/post-create.sh`, `tests/repo_hygiene.rs` |
| R45 | `pr-comment-bot-trigger-block` | P12 | `.github/pull_request_template.md`, `.github/CONTRIBUTING.md`, `tests/community_contract.rs` |
| R46 | `per-file-license-header` | P04/P12 | `Cargo.toml` (`license = "MIT OR Apache-2.0"`), `LICENSE`, `LICENSE-MIT`, zero per-file headers, `tests/community_contract.rs` |
| R47 | `contributors-recipe-mode` | P12 | `Justfile` (`update-contributors` guarded `render`/`init`), `tests/community_contract.rs` |
| R48 | `mocking-crates` | P06/P07 | `crates/core/src/ports.rs` (`InMemoryProjectsPort`, `RecordingPort`, optional `mockall`), `tests/http_adapter_boundary.rs` (`httpmock`) |
| R49 | `build-target-declaration` | P04 | `Cargo.toml` (`autobins = false`, `[lib]`, `[[bin]] rslbp`, explicit `[package] include`), `crates/*/Cargo.toml` |
| R50 | `install-smoke-test` | P07/P10 | `Justfile` (`install-check`), `.github/workflows/ci.yml` (`install-smoke` default + web legs, `OV-13`) |
| R51 | `container-image` | P09/P11 | `Dockerfile`, `.dockerignore`, `.github/workflows/docker-web.yml`, `.github/workflows/publish-container.yml` (`OV-14` + owner `1a-A` GHCR override) |
| R52 | `toml-crate` | P06 | `crates/core/src/config/loader.rs` (`toml`), `crates/core/src/config/writer.rs` (`toml_edit`), `tests/config_and_secrets_contract.rs` |
| R53 | `config-schema-validation` | P06 | `crates/core/src/config/schema.rs`, `crates/core/src/config/validate.rs` (`UnvalidatedConfig`/`ValidConfig`), `tests/config_and_secrets_contract.rs` |
| R54 | `config-discovery-tiers` | P06 | `crates/core/src/config/discovery.rs` (6-rung precedence + ancestor `.rslbp/rslbp_config.toml`), `tests/config_and_secrets_contract.rs` |
| R55 | `config-error-tolerance` | P06 | `crates/core/src/config/loader.rs` (provenance-aware two-phase tolerance), `tests/config_and_secrets_contract.rs` |
| R56 | `config-secret-policy` | P06 | `crates/core/src/secrets.rs` (`secrecy`/`zeroize`, 3-tier resolution, `RSLB204`), `src/keychain.rs` (`--features keychain`), `tests/config_and_secrets_contract.rs` |
| R57 | `xdg-directory-set` | P06 | `crates/core/src/paths.rs` (`etcetera 0.11.0` 4-dir `Paths`), `tests/config_and_secrets_contract.rs` |
| R58 | `logging-pipeline-architecture` | P06 | `src/telemetry.rs` (`tracing` + `tracing-subscriber`, owned redacting formatters, `reload::Handle`, CLI/Service profiles, `OV-09`), `tests/telemetry_contract.rs` |
| R59 | `file-log-sink` | P06 | `src/telemetry.rs` (std-only `0600` `RotatingFile` sink, independent level/format), `tests/telemetry_contract.rs` |
| R60 | `cli-parsing-framework` | P07 | `crates/cli/src/args.rs` (`clap 4.6.6` derive, `clap_complete`), `crates/cli/build.rs`, `tests/cli/*` (`OV-01` retired) |
| R61 | `interactive-prompts` | P07 | `crates/cli/src/prompter.rs` (`inquire 0.9.4`, `Prompter` trait, `OV-02` declined confirm exits 0), `tests/cli/*` |
| R62 | `clipboard-integration` | P07 | `crates/core/src/clipboard.rs`, `src/clipboard_adapter.rs` (`arboard`, default-on `clipboard` feature, Linux daemon), `tests/cli/*` |
| R63 | `progress-spinner` | P07 | `crates/cli/src/spinner.rs` (`indicatif 0.18`, 3-input suppression predicate) |
| R64 | `pager-integration` | P07 | `crates/cli/src/pager.rs` (`shlex 2.0.1`, `RSLBP_PAGER` > `PAGER` > `less -FRX`) |
| R65 | `color-enablement-chain` | P07 | `crates/cli/src/color.rs` (`anstream`/`anstyle`, 4-tier precedence chain) |
| R66 | `output-format-surface` | P07 | `crates/cli/src/output.rs` (`table\|json\|markdown\|name`, `--output-file`, `--no-clobber`, exact `tabled =0.22.0`) |
| R67 | `error-and-exit-code-contract` | P06/P07 | `crates/core/src/error.rs` (`ErrorCode::ALL`, `Exit`, `ErrorEnvelope`), `src/crash_sink.rs`, `tests/error_contract.rs` |
| R68 | `release-binary-artifacts` | P11 | `dist-workspace.toml` (`cargo-dist 0.33.0` follower mode), `Cargo.toml` (`[profile.release]` fat LTO + cu=1), `.github/workflows/release.yml`, `tests/release_contract.rs` |
| R69 | `web-framework-stack` | P08 | `crates/web/src/server.rs`, `src/bin/serve.rs`, `Cargo.toml` (`web = ["dep:rs-launch-blueprint-web"]`), `bacon.toml`, `Justfile` (`serve`), `tests/web_serve_contract.rs` |
| R70 | `http-problem-envelope` | P08 | `crates/web/src/problems.rs` (RFC 9457 `problem_details`, `W5` 5xx redaction, `problem_catalog`), `crates/web/tests/*` |
| R71 | `openapi-generation-pipeline` | P09 | `crates/web/src/openapi.rs` (`utoipa` + `utoipa-axum`), `openapi/openapi.json`, `openapi/oasdiff-levels.txt`, `.github/workflows/api-contract.yml`, `Justfile` (`export-openapi`/`check-openapi`/`api-breaking`) |
| R72 | `api-pagination` | P08 | `crates/web/src/pagination.rs` (first-party URL-safe base64 cursor pagination) |
| R73 | `idempotency-middleware` | P08 | `crates/core/src/idempotency.rs`, `crates/web/src/idempotency.rs` (CAS idempotency store, `409`/`422`/`Idempotency-Replayed`, `OV-16`) |
| R74 | `rate-limiting-middleware` | P08 | `crates/web/src/rate_limit.rs` (bounded per-IP GCRA rate limiter, `429` + `Retry-After`, `OV-17`) |
| R75 | `http-middleware-stack` | P08 | `crates/web/src/middleware.rs` (L1–L9 fixed-order `tower-http` stack, probe exclusion, `traceparent`, security headers) |
| R76 | `cors-middleware` | P08 | `crates/web/src/cors.rs` (conditional `CorsLayer` mounted only when `RSLBP_WEB_CORS_ORIGINS` is set, `OV-08`) |
| R77 | `web-env-settings` | P08 | `crates/web/src/settings.rs` (`std::env` `WebSettings`, 19 `RSLBP_WEB_*` vars, `OV-04`) |
| R78 | `opentelemetry-integration` | P09 | `src/otel.rs` (`--features otel`, `tracing-opentelemetry`, OTLP HTTP exporter), `tests/otel_contract.rs`, `.github/workflows/ci.yml` |
| R79 | `prometheus-metrics` | P09 | `crates/web/src/metrics.rs` (`--features metrics`, Prometheus `/metrics` RED metrics, `OV-07`) |
| R80 | `health-probe-endpoints` | P08 | `crates/web/src/routes/ops.rs` (byte-stable `/healthz` + latch/redacted `/readyz`, `OV-05`) |
| R81 | `docs-delivery-model` | P13 | `book.toml`, `docs/SUMMARY.md`, `docs/README.md`, `.github/workflows/docs.yml`, `Justfile` (`docs-build`/`docs-dev`/`docs-init`/`docs-clean`), `tests/docs_contract.rs` |
| R82 | `docs-correctness-gate` | P13 | `lychee.toml`, `.github/workflows/ci.yml` (`hygiene` offline lychee + `check` strict rustdoc), `.github/workflows/canary.yml` (`docs-external-links`), `Justfile` (`docs-check`/`docs-api`), `tests/docs_contract.rs` |
| R83 | `openapi-contract-fuzzing` | P09 | `crates/web/tests/contract_fuzz.rs` (`proptest` OpenAPI 3.1 contract fuzzer), `Justfile` (`test-contract`) |
| R84 | `openapi-typed-client-generation` | P09 | `openapi-to-rust.toml`, `Justfile` (`generate-client` / `client-rust` using `openapi-to-rust 0.17.0`, `OV-11`) |
| R85 | `rich-terminal-row-niceties` | P07 | `crates/cli/src/rich.rs` (capability-gated OSC-8 hyperlinks + relative timestamps) |
| R86 | `codex-assisted-review-workflows` | P10 | `.github/workflows/codex-code-review.yml`, `.github/workflows/codex.yml`, `.github/codex/*.md`, `tests/workflows_contract.rs` |

## Blaze Local Accelerator Status

Empirically verified on `blaze 0.20261127.0` (`nightly-2026-10-27`) against pinned `rust-toolchain.toml` (`1.100.1`):

| Probe / Surface | Live Result (`2026-11-28`) | Policy |
| --- | --- | --- |
| `blaze test -p rs-launch-blueprint-core` | **PASS** (4/4 unit tests + kept cache results) | Active fast core edit-test accelerator |
| `blaze build -p rs-launch-blueprint --bin rslbp` | **PASS** (593 ms JIT build) | Active fast CLI binary accelerator |
| Workspace `blaze check` / `blaze test` | **Blocked** (`utoipa-axum 0.3.0` `routes!` macro in `crates/web`) | Automatic Cargo fallback; Cargo authoritative |
| `--features web` / `metrics` / `otel` | **Unsupported by CLI** (`blaze` rejects `--features`) | Use `cargo` / `bacon` (`just serve`) |
| Fallback when `blaze` absent from `PATH` | **PASS** (verified by `tests/justfile_contract.rs`) | Opt-in only; never required by CI or hooks |

Full details and live re-probe instructions live in `docs/tools/blaze.md` and `just blaze-status`.

## Final Human GitHub Setup Checklist

All automation-safe repository files are merged and verified. The remaining **one-time human-only GitHub & registry settings** are consolidated in [`docs/PROJECT_SETUP.md`](../PROJECT_SETUP.md):

1. **Branch protection / ruleset on `main`:** require pull requests, require status checks `ci-ok` and `press-verify`, disable squash merges (`allow_squash_merge=false`).
2. **GitHub Pages (`R81`):** set **Settings -> Pages -> Build and deployment -> Source** to **GitHub Actions** (`has_pages` is currently `false`; `.github/workflows/docs.yml` skips deploy with an actionable notice until enabled, then publishes to `https://smorinlabs.github.io/rs-launch-blueprint/`).
3. **Code Scanning (`R16`):** disable GitHub's built-in Code Scanning Default Setup (`code-scanning/default-setup` -> `not-configured`) so `.github/workflows/codeql.yml` uploads SARIF cleanly, and enable Dependabot alerts & security updates.
4. **Release Please credentials (`R23`):** configure GitHub App secrets `RELEASE_PLEASE_CLIENT_ID` + `RELEASE_PLEASE_PRIVATE_KEY` (or fallback `RELEASE_PLEASE_APP_TOKEN`).
5. **crates.io environments & Trusted Publishing (`R26`, `F075`):** create GitHub Environments `crates-io` and `security-review`, perform initial publish of the 4 workspace crates, register Trusted Publishing for `.github/workflows/publish.yml`, and set `CRATES_IO_TRUSTED_PUBLISHING=true`.
6. **GHCR container visibility (`1a-A`):** after the first stable release pushes `ghcr.io/smorinlabs/rs-launch-blueprint`, switch package visibility to **Public** and rerun `publish-container.yml` to verify anonymous pull and `:latest`.
7. **Optional AI & Contributors secrets:** provision `ANTHROPIC_API_KEY` / OIDC federation (Claude), `OPENAI_API_KEY` (Codex), `META_MUSE_CI_API_KEY` (Muse audit triage), and `CONTRIBUTORS_PLEASE_CLIENT_ID` + `CONTRIBUTORS_PLEASE_PRIVATE_KEY` (or `CONTRIBUTORS_PLEASE_PAT`) as desired.

## Full 360-Row `COMMONALITY.md` Parity Ledger

Every single row from `docs/port/COMMONALITY.md` (`F001`–`F362`, excluding vacated `F139`/`F140`) is audited below:

| ID | Area | Verdict | Item | Status | Verification Evidence |
| --- | --- | --- | --- | --- | --- |
| F001 | workspace-architecture | DIVERGENT | R01 | IMPLEMENTED | (P06, R01) `crates/core/src/ports.rs`, `crates/core/src/service.rs`, `src/composition.rs`, `tests/ports_contract.rs` |
| F002 | workspace-architecture | DIVERGENT | R01 | IMPLEMENTED | (P06, R01) `crates/core/src/ports.rs`, `crates/core/src/service.rs`, `src/composition.rs`, `tests/ports_contract.rs` |
| F003 | workspace-architecture | DIVERGENT | R02 | IMPLEMENTED | (P04, R02) `Cargo.toml`, `deny.toml`, `crates/core/clippy.toml`, `tests/workspace_edges.rs` (`OV-03`) |
| F004 | workspace-architecture | DIVERGENT | R02 | IMPLEMENTED | (P04, R02) `Cargo.toml`, `deny.toml`, `crates/core/clippy.toml`, `tests/workspace_edges.rs` (`OV-03`) |
| F005 | workspace-architecture | DIVERGENT | R02 | IMPLEMENTED | (P04, R02) `Cargo.toml`, `deny.toml`, `crates/core/clippy.toml`, `tests/workspace_edges.rs` (`OV-03`) |
| F006 | workspace-architecture | DIVERGENT | R02 | IMPLEMENTED | (P04, R02) `Cargo.toml`, `deny.toml`, `crates/core/clippy.toml`, `tests/workspace_edges.rs` (`OV-03`) |
| F007 | workspace-architecture | DIVERGENT | R02 | IMPLEMENTED | (P04, R02) `Cargo.toml`, `deny.toml`, `crates/core/clippy.toml`, `tests/workspace_edges.rs` (`OV-03`) |
| F008 | workspace-architecture | DIVERGENT | R02 | IMPLEMENTED | (P04, R02) `Cargo.toml`, `deny.toml`, `crates/core/clippy.toml`, `tests/workspace_edges.rs` (`OV-03`) |
| F009 | workspace-architecture | DIVERGENT | R02 | IMPLEMENTED | (P04, R02) `Cargo.toml`, `deny.toml`, `crates/core/clippy.toml`, `tests/workspace_edges.rs` (`OV-03`) |
| F010 | workspace-architecture | DIVERGENT | R02 | IMPLEMENTED | (P04, R02) `Cargo.toml`, `deny.toml`, `crates/core/clippy.toml`, `tests/workspace_edges.rs` (`OV-03`) |
| F011 | workspace-architecture | DIVERGENT | R01 | IMPLEMENTED | (P06, R01) `crates/core/src/ports.rs`, `crates/core/src/service.rs`, `src/composition.rs`, `tests/ports_contract.rs` |
| F012 | workspace-architecture | DIVERGENT | R03 | IMPLEMENTED | (P06, R03) `crates/core/src/error.rs`, `crates/core/src/service.rs`, `src/http_adapter.rs`, `tests/ports_contract.rs` |
| F013 | workspace-architecture | DIVERGENT | R01 | IMPLEMENTED | (P06, R01) `crates/core/src/ports.rs`, `crates/core/src/service.rs`, `src/composition.rs`, `tests/ports_contract.rs` |
| F014 | workspace-architecture | COMMON → REUSE | — | IMPLEMENTED | `src/lib.rs`, `crates/core/src/lib.rs`, `crates/cli/src/lib.rs`, `crates/web/src/lib.rs` (curated `pub use` barrels) |
| F015 | workspace-architecture | DIVERGENT | R04 | IMPLEMENTED | (P04/P11, R04) `Cargo.toml` (`unreachable_pub`/`private_interfaces`/`private_bounds`/`missing_docs`), `src/lib.rs`, `.github/workflows/publish.yml` (`cargo-semver-checks`) |
| F016 | workspace-architecture | DIVERGENT | R05 | IMPLEMENTED | (P06/P08, R05) `src/http_adapter.rs` (`ureq`), `crates/web/src/routes/projects.rs` (`spawn_blocking`), `tests/http_adapter_boundary.rs` |
| F017 | workspace-architecture | ADOPT | — | IMPLEMENTED | `Cargo.toml` (`web = ["dep:rs-launch-blueprint-web"]`, off by default) |
| F018 | workspace-architecture | DIVERGENT | R01 | IMPLEMENTED | (P06, R01) `crates/core/src/ports.rs`, `crates/core/src/service.rs`, `src/composition.rs`, `tests/ports_contract.rs` |
| F019 | workspace-architecture | COMMON → REUSE | — | IMPLEMENTED | `src/` root crate layout + `crates/*/src/` workspace members |
| F020 | workspace-architecture | DIVERGENT | R02 | IMPLEMENTED | (P04, R02) `Cargo.toml`, `deny.toml`, `crates/core/clippy.toml`, `tests/workspace_edges.rs` (`OV-03`) |
| F021 | workspace-architecture | RUST-ONLY | R02 | IMPLEMENTED | (P04, R02) `Cargo.toml`, `deny.toml`, `crates/core/clippy.toml`, `tests/workspace_edges.rs` (`OV-03`) |
| F022 | workspace-architecture | RUST-ONLY | R05 | IMPLEMENTED | (P06/P08, R05) `src/http_adapter.rs` (`ureq`), `crates/web/src/routes/projects.rs` (`spawn_blocking`), `tests/http_adapter_boundary.rs` |
| F023 | workspace-architecture | RUST-ONLY | R06 | IMPLEMENTED | (P04, R06) `Cargo.toml` (`[workspace.lints.rust] unsafe_code = "forbid"`), `tests/workspace_edges.rs` |
| F024 | ci-workflows | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/ci.yml` (`on: push/pull_request branches: [main]`) |
| F025 | ci-workflows | ADOPT | — | IMPLEMENTED | `.github/workflows/ci.yml` (`on: merge_group:`), `.github/workflows/commitlint.yml` |
| F026 | ci-workflows | DIVERGENT | R07 | IMPLEMENTED | (P12, R07) `.github/workflows/update-contributors.yml`, `tests/bootstrap_acceptance.rs` |
| F027 | ci-workflows | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/codeql.yml` (`repository-visibility` preflight job via `actions/github-script@v9`) |
| F028 | ci-workflows | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/*.yml` (column-0 `permissions: {}` + per-job grants), `scripts/check-workflow-permissions.sh` |
| F029 | ci-workflows | DIVERGENT | R08 | IMPLEMENTED | (P10, R08) `scripts/check-workflow-permissions.sh`, `.github/workflows/*.yml`, `zizmor.yml`, `tests/workflows_contract.rs` |
| F030 | ci-workflows | DIVERGENT | R08 | IMPLEMENTED | (P10, R08) `scripts/check-workflow-permissions.sh`, `.github/workflows/*.yml`, `zizmor.yml`, `tests/workflows_contract.rs` |
| F031 | ci-workflows | DIVERGENT | R09 | IMPLEMENTED | (P10, R09) `.github/workflows/*.yml` (literal `ubuntu-latest`/`macos-latest`), `.github/actionlint.yaml`, `tests/workflows_contract.rs` |
| F032 | ci-workflows | ADOPT | — | IMPLEMENTED | `.github/workflows/ci.yml` (`matrix.os: [ubuntu-latest, macos-latest]` per owner-fixed `target-os-matrix`) |
| F033 | ci-workflows | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/ci.yml` (`msrv-floor` job testing `rust-version = "1.98"` alongside pinned stable in `check`) |
| F034 | ci-workflows | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/ci.yml` (`strategy.fail-fast: false`), `.github/workflows/canary.yml` |
| F035 | ci-workflows | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/ci.yml` (`Swatinem/rust-cache` caching `$CARGO_HOME` and `target/` per R10) |
| F036 | ci-workflows | COMMON → SUBSTITUTE | R10 | IMPLEMENTED | (P10, R10) `.github/workflows/ci.yml` (`Swatinem/rust-cache@6323deb...` with `ImageOS`, `v1-rslbp`) |
| F037 | ci-workflows | OMIT | — | OMITTED (non-analogous) | Non-analogous in Rust: `cargo`/`rustup` require no separate package-manager pre-install ordering step before cache setup. |
| F038 | ci-workflows | DIVERGENT | R11 | IMPLEMENTED | (P10, R11) `.github/workflows/ci.yml` (fail-closed `plan`, `hygiene`, `workflow-lint`, OS-matrix `check`, `msrv-floor`, `install-smoke`, `coverage`), `tests/workflows_contract.rs` |
| F039 | ci-workflows | DIVERGENT | R26 | IMPLEMENTED | (P11, R26) `scripts/check-packed-artifacts.sh`, `ci/expected-packed-files/*`, `ci/expected-packaged-targets/*`, `.github/workflows/publish.yml`, `tests/release_contract.rs` |
| F040 | ci-workflows | DIVERGENT | R11 | IMPLEMENTED | (P10, R11) `.github/workflows/ci.yml` (fail-closed `plan`, `hygiene`, `workflow-lint`, OS-matrix `check`, `msrv-floor`, `install-smoke`, `coverage`), `tests/workflows_contract.rs` |
| F041 | ci-workflows | DIVERGENT | R12 | IMPLEMENTED | (P10, R12) `.github/workflows/ci.yml` (`ci-ok` aggregate + `workflow-lint` completeness check), `tests/workflows_contract.rs` |
| F042 | ci-workflows | DIVERGENT | R13 | IMPLEMENTED | (P10, R13) `.github/workflows/dep-audit.yml`, `.github/workflows/manual-pr-security-scan.yml`, `.cargo/audit.toml`, `ci.yml` SCA scaffold |
| F043 | ci-workflows | DIVERGENT | R14 | IMPLEMENTED | (P05/P10, R14) `scripts/check-large-files.sh`, `scripts/test-check-large-files.sh`, `.gitattributes`, `lefthook.yml`, `.github/workflows/large-file-guard.yml` |
| F044 | ci-workflows | DIVERGENT | R15 | IMPLEMENTED | (P12, R15) `press/press-rules.toml`, `press/press-source.toml`, `press/requirements.txt`, `press/stubs/*`, `.github/workflows/press-verify.yml`, `.github/workflows/template-receipt-guard.yml`, `tests/bootstrap_acceptance.rs` |
| F045 | ci-workflows | DIVERGENT | R16 | IMPLEMENTED | (P10, R16) `.github/workflows/codeql.yml`, `.github/codeql/codeql-config.yml`, `tests/workflows_contract.rs` |
| F046 | ci-workflows | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/dependency-review.yml` (`actions/dependency-review-action@v5.0.0`) |
| F047 | ci-workflows | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/manual-pr-security-scan.yml` (`workflow_dispatch`, `security-review` environment) |
| F048 | ci-workflows | DIVERGENT | R13 | IMPLEMENTED | (P10, R13) `.github/workflows/dep-audit.yml`, `.github/workflows/manual-pr-security-scan.yml`, `.cargo/audit.toml`, `ci.yml` SCA scaffold |
| F049 | ci-workflows | DIVERGENT | R13 | IMPLEMENTED | (P10, R13) `.github/workflows/dep-audit.yml`, `.github/workflows/manual-pr-security-scan.yml`, `.cargo/audit.toml`, `ci.yml` SCA scaffold |
| F050 | ci-workflows | DIVERGENT | R17 | IMPLEMENTED | (P10, R17) `.github/workflows/secret-scan.yml` (cosign-verified TruffleHog CLI `v3.97.4`), `tests/workflows_contract.rs` |
| F051 | ci-workflows | DIVERGENT | R18 | IMPLEMENTED | (P10, R18) `.github/workflows/claude-code-review.yml`, `.github/workflows/claude.yml`, `.claude/commands/review-pr.md`, `tests/workflows_contract.rs` |
| F052 | ci-workflows | DIVERGENT | R18 | IMPLEMENTED | (P10, R18) `.github/workflows/claude-code-review.yml`, `.github/workflows/claude.yml`, `.claude/commands/review-pr.md`, `tests/workflows_contract.rs` |
| F053 | ci-workflows | DIVERGENT | R19 | IMPLEMENTED | (P10, R19) `.github/dependabot.yml` (2 entries: `cargo` + `github-actions`, 5-day cooldown), `zizmor.yml`, `tests/workflows_contract.rs` |
| F054 | ci-workflows | DIVERGENT | R19 | IMPLEMENTED | (P10, R19) `.github/dependabot.yml` (2 entries: `cargo` + `github-actions`, 5-day cooldown), `zizmor.yml`, `tests/workflows_contract.rs` |
| F055 | ci-workflows | DIVERGENT | R20 | IMPLEMENTED | (P10, R20) `zizmor.yml`, `scripts/check-action-pin-comments.sh`, `.github/workflows/*.yml`, `tests/workflows_contract.rs` |
| F056 | ci-workflows | DIVERGENT | R09 | IMPLEMENTED | (P10, R09) `.github/workflows/*.yml` (literal `ubuntu-latest`/`macos-latest`), `.github/actionlint.yaml`, `tests/workflows_contract.rs` |
| F057 | ci-workflows | DIVERGENT | R09 | IMPLEMENTED | (P10, R09) `.github/workflows/*.yml` (literal `ubuntu-latest`/`macos-latest`), `.github/actionlint.yaml`, `tests/workflows_contract.rs` |
| F058 | ci-workflows | DIVERGENT | R09 | IMPLEMENTED | (P10, R09) `.github/workflows/*.yml` (literal `ubuntu-latest`/`macos-latest`), `.github/actionlint.yaml`, `tests/workflows_contract.rs` |
| F059 | ci-workflows | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/publish.yml` and `.github/workflows/release.yml` (`on: push: tags: ['v*']`) |
| F060 | ci-workflows | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/update-contributors.yml` (`smorinlabs/contributors-please-action`) |
| F061 | ci-workflows | DIVERGENT | R21 | IMPLEMENTED | (P12, R21) `.github/workflows/update-contributors.yml` (App primary, `CONTRIBUTORS_PLEASE_PAT` fallback), `tests/bootstrap_acceptance.rs` |
| F062 | ci-workflows | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/difftree-pr-comment.yml` (`smorinlabs/difftree-action@v0`, P03) |
| F063 | release-versioning | COMMON → REUSE | — | IMPLEMENTED | `Cargo.toml` and `crates/*/Cargo.toml` (`[package] version = "0.1.0"`), `.release-please-manifest.json` |
| F064 | release-versioning | DIVERGENT | R22 | IMPLEMENTED | (P06/P11, R22) `crates/core/src/metadata.rs` (`pub const VERSION`), `src/lib.rs`, `tests/release_contract.rs` |
| F065 | release-versioning | DIVERGENT | R23 | IMPLEMENTED | (P11, R23) `release-please-config.json` (`release-type: rust`), `.github/workflows/release-please.yml`, `tests/release_contract.rs` |
| F066 | release-versioning | COMMON → REUSE | — | IMPLEMENTED | `CHANGELOG.md`, `release-please-config.json`, `.github/workflows/release-please.yml` |
| F067 | release-versioning | DIVERGENT | R24 | IMPLEMENTED | (P11, R24) `release-please-config.json` (ordered 11-type changelog sections), `tests/release_contract.rs` |
| F068 | release-versioning | ADOPT | — | IMPLEMENTED | `CHANGELOG.md` (Keep a Changelog / release-please header), `press/press-rules.toml` reset stub |
| F069 | release-versioning | COMMON → REUSE | — | IMPLEMENTED | `release-please-config.json` (`pull-request-title-pattern`) |
| F070 | release-versioning | DIVERGENT | R25 | IMPLEMENTED | (P11, R25) `release-please-config.json` (`bump-minor-pre-major`, `bump-patch-for-minor-pre-major`), `.release-please-manifest.json`, `Cargo.toml` (`0.1.0`) |
| F071 | release-versioning | ADOPT | — | IMPLEMENTED | `docs/RELEASE.md` (First-Release Bootstrap Notes documenting `bootstrap-sha` cutover vs. clean stamped children) |
| F072 | release-versioning | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/release-please.yml` (`actions/create-github-app-token@v3` with PAT fallback) |
| F073 | release-versioning | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/release-please.yml` (push to `main` opens Release PR; merging tags `vX.Y.Z`) |
| F074 | release-versioning | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/publish.yml` (`verify` job tag-ancestry and 4-manifest version lockstep guard) |
| F075 | release-versioning | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/publish.yml` (`id-token: write`, `rust-lang/crates-io-auth-action`, `CRATES_IO_TRUSTED_PUBLISHING`) |
| F076 | release-versioning | OMIT | — | OMITTED (non-analogous) | Non-analogous in Rust: crates.io has no staging/TestPyPI registry (`cargo publish --dry-run` validates locally without upload). |
| F077 | release-versioning | COMMON → REUSE | — | IMPLEMENTED | `.github/workflows/publish.yml` (`environment: name: crates-io`), `docs/PROJECT_SETUP.md` |
| F078 | release-versioning | DIVERGENT | R26 | IMPLEMENTED | (P11, R26) `scripts/check-packed-artifacts.sh`, `ci/expected-packed-files/*`, `ci/expected-packaged-targets/*`, `.github/workflows/publish.yml`, `tests/release_contract.rs` |
| F079 | release-versioning | ADOPT | — | IMPLEMENTED | `Justfile` (`release-status` recipe comparing workspace `Cargo.toml` manifests, `.release-please-manifest.json`, and latest `v*` tag) |
| F080 | release-versioning | COMMON → REUSE | — | IMPLEMENTED | `Justfile` (`version` recipe running compiled `rslbp --version`) |
| F081 | release-versioning | COMMON → REUSE | — | IMPLEMENTED | `docs/RELEASE.md` (complete end-to-end release, crates.io, `cargo-dist`, and GHCR runbook) |
| F082 | release-versioning | ADOPT | — | IMPLEMENTED | `docs/RELEASE.md` (`Opting Out (Downstream Projects)` section) |
| F083 | lint-format | COMMON → REUSE | — | IMPLEMENTED | `Cargo.toml` + `rustfmt.toml` (`clippy` + `rustfmt` wired in `lefthook.yml`, `Justfile`, and `.github/workflows/ci.yml`) |
| F084 | lint-format | DIVERGENT | R27 | IMPLEMENTED | (P04/P05, R27) `rustfmt.toml`, `rust-toolchain.toml`, `Justfile` (`format`/`format-check`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F085 | lint-format | DIVERGENT | R28 | IMPLEMENTED | (P04/P05, R28) `Cargo.toml` (`[workspace.lints.clippy]`), `clippy.toml`, `Justfile` (`lint`/`lint-fix`), `.vscode/settings.json`, `.vscode/extensions.json`, `.vscode/launch.json` |
| F086 | lint-format | DIVERGENT | R28 | IMPLEMENTED | (P04/P05, R28) `Cargo.toml` (`[workspace.lints.clippy]`), `clippy.toml`, `Justfile` (`lint`/`lint-fix`), `.vscode/settings.json`, `.vscode/extensions.json`, `.vscode/launch.json` |
| F087 | lint-format | DIVERGENT | R27 | IMPLEMENTED | (P04/P05, R27) `rustfmt.toml`, `rust-toolchain.toml`, `Justfile` (`format`/`format-check`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F088 | lint-format | OMIT | — | OMITTED (non-analogous) | Non-analogous in Rust: string literals are always double-quoted by language grammar (no formatter quote-style choice). |
| F089 | lint-format | DIVERGENT | R27 | IMPLEMENTED | (P04/P05, R27) `rustfmt.toml`, `rust-toolchain.toml`, `Justfile` (`format`/`format-check`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F090 | lint-format | OMIT | — | OMITTED (non-analogous) | Non-analogous in Rust: statement-terminating semicolons are required by Rust grammar (not a formatter option). |
| F091 | lint-format | DIVERGENT | R27 | IMPLEMENTED | (P04/P05, R27) `rustfmt.toml`, `rust-toolchain.toml`, `Justfile` (`format`/`format-check`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F092 | lint-format | DIVERGENT | R27 | IMPLEMENTED | (P04/P05, R27) `rustfmt.toml`, `rust-toolchain.toml`, `Justfile` (`format`/`format-check`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F093 | lint-format | DIVERGENT | R28 | IMPLEMENTED | (P04/P05, R28) `Cargo.toml` (`[workspace.lints.clippy]`), `clippy.toml`, `Justfile` (`lint`/`lint-fix`), `.vscode/settings.json`, `.vscode/extensions.json`, `.vscode/launch.json` |
| F094 | lint-format | DIVERGENT | R28 | IMPLEMENTED | (P04/P05, R28) `Cargo.toml` (`[workspace.lints.clippy]`), `clippy.toml`, `Justfile` (`lint`/`lint-fix`), `.vscode/settings.json`, `.vscode/extensions.json`, `.vscode/launch.json` |
| F095 | lint-format | OMIT | — | OMITTED (non-analogous) | Non-analogous in Rust: `lib.rs`/`mod.rs` `pub use` re-exports require no Python `__init__.py` unused-import exemption. |
| F096 | lint-format | DIVERGENT | R28 | IMPLEMENTED | (P04/P05, R28) `Cargo.toml` (`[workspace.lints.clippy]`), `clippy.toml`, `Justfile` (`lint`/`lint-fix`), `.vscode/settings.json`, `.vscode/extensions.json`, `.vscode/launch.json` |
| F097 | lint-format | DIVERGENT | R29 | IMPLEMENTED | (P05, R29) `dprint.json` (4 SHA-256 Wasm plugins), `Justfile` (`format-files`/`check-files`), `lefthook.yml`, `.github/workflows/ci.yml`, `tests/repo_hygiene.rs` |
| F098 | lint-format | DIVERGENT | R29 | IMPLEMENTED | (P05, R29) `dprint.json` (4 SHA-256 Wasm plugins), `Justfile` (`format-files`/`check-files`), `lefthook.yml`, `.github/workflows/ci.yml`, `tests/repo_hygiene.rs` |
| F099 | lint-format | DIVERGENT | R29 | IMPLEMENTED | (P05, R29) `dprint.json` (4 SHA-256 Wasm plugins), `Justfile` (`format-files`/`check-files`), `lefthook.yml`, `.github/workflows/ci.yml`, `tests/repo_hygiene.rs` |
| F100 | lint-format | DIVERGENT | R27 | IMPLEMENTED | (P04/P05, R27) `rustfmt.toml`, `rust-toolchain.toml`, `Justfile` (`format`/`format-check`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F101 | lint-format | DIVERGENT | R28 | IMPLEMENTED | (P04/P05, R28) `Cargo.toml` (`[workspace.lints.clippy]`), `clippy.toml`, `Justfile` (`lint`/`lint-fix`), `.vscode/settings.json`, `.vscode/extensions.json`, `.vscode/launch.json` |
| F102 | lint-format | DIVERGENT | R27 | IMPLEMENTED | (P04/P05, R27) `rustfmt.toml`, `rust-toolchain.toml`, `Justfile` (`format`/`format-check`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F103 | lint-format | DIVERGENT | R27 | IMPLEMENTED | (P04/P05, R27) `rustfmt.toml`, `rust-toolchain.toml`, `Justfile` (`format`/`format-check`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F104 | lint-format | DIVERGENT | R27 | IMPLEMENTED | (P04/P05, R27) `rustfmt.toml`, `rust-toolchain.toml`, `Justfile` (`format`/`format-check`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F105 | static-analysis | DIVERGENT | R30 | IMPLEMENTED | (P04/P10, R30) `Cargo.toml` (`rust_2018_idioms`), `Justfile` (`typecheck`), `.github/workflows/ci.yml` |
| F106 | static-analysis | DIVERGENT | R30 | IMPLEMENTED | (P04/P10, R30) `Cargo.toml` (`rust_2018_idioms`), `Justfile` (`typecheck`), `.github/workflows/ci.yml` |
| F107 | static-analysis | DIVERGENT | R30 | IMPLEMENTED | (P04/P10, R30) `Cargo.toml` (`rust_2018_idioms`), `Justfile` (`typecheck`), `.github/workflows/ci.yml` |
| F108 | static-analysis | DIVERGENT | R30 | IMPLEMENTED | (P04/P10, R30) `Cargo.toml` (`rust_2018_idioms`), `Justfile` (`typecheck`), `.github/workflows/ci.yml` |
| F109 | static-analysis | DIVERGENT | R28 | IMPLEMENTED | (P04/P05, R28) `Cargo.toml` (`[workspace.lints.clippy]`), `clippy.toml`, `Justfile` (`lint`/`lint-fix`), `.vscode/settings.json`, `.vscode/extensions.json`, `.vscode/launch.json` |
| F110 | static-analysis | DIVERGENT | R30 | IMPLEMENTED | (P04/P10, R30) `Cargo.toml` (`rust_2018_idioms`), `Justfile` (`typecheck`), `.github/workflows/ci.yml` |
| F111 | static-analysis | DIVERGENT | R30 | IMPLEMENTED | (P04/P10, R30) `Cargo.toml` (`rust_2018_idioms`), `Justfile` (`typecheck`), `.github/workflows/ci.yml` |
| F112 | static-analysis | DIVERGENT | R30 | IMPLEMENTED | (P04/P10, R30) `Cargo.toml` (`rust_2018_idioms`), `Justfile` (`typecheck`), `.github/workflows/ci.yml` |
| F113 | static-analysis | DIVERGENT | R30 | IMPLEMENTED | (P04/P10, R30) `Cargo.toml` (`rust_2018_idioms`), `Justfile` (`typecheck`), `.github/workflows/ci.yml` |
| F114 | static-analysis | DIVERGENT | R31 | IMPLEMENTED | (P05, R31) `sgconfig.yml`, `rules/*.yml`, `rules/tests/*`, `scripts/test-security-rules.sh`, `Justfile` (`security`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F115 | static-analysis | DIVERGENT | R31 | IMPLEMENTED | (P05, R31) `sgconfig.yml`, `rules/*.yml`, `rules/tests/*`, `scripts/test-security-rules.sh`, `Justfile` (`security`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F116 | static-analysis | DIVERGENT | R02 | IMPLEMENTED | (P04, R02) `Cargo.toml`, `deny.toml`, `crates/core/clippy.toml`, `tests/workspace_edges.rs` (`OV-03`) |
| F117 | testing-coverage | DIVERGENT | R32 | IMPLEMENTED | (P07/P10, R32) `.config/nextest.toml`, `Justfile` (`test`/`test-slow`/`test-live`/`test-all`), `lefthook.yml`, `tests/cli/*`, `.github/workflows/ci.yml` |
| F118 | testing-coverage | DIVERGENT | R32 | IMPLEMENTED | (P07/P10, R32) `.config/nextest.toml`, `Justfile` (`test`/`test-slow`/`test-live`/`test-all`), `lefthook.yml`, `tests/cli/*`, `.github/workflows/ci.yml` |
| F119 | testing-coverage | DIVERGENT | R48 | IMPLEMENTED | (P06/P07, R48) `crates/core/src/ports.rs` (`InMemoryProjectsPort`, `RecordingPort`, optional `mockall`), `tests/http_adapter_boundary.rs` (`httpmock`) |
| F120 | testing-coverage | DIVERGENT | R48 | IMPLEMENTED | (P06/P07, R48) `crates/core/src/ports.rs` (`InMemoryProjectsPort`, `RecordingPort`, optional `mockall`), `tests/http_adapter_boundary.rs` (`httpmock`) |
| F121 | testing-coverage | DIVERGENT | R01 | IMPLEMENTED | (P06, R01) `crates/core/src/ports.rs`, `crates/core/src/service.rs`, `src/composition.rs`, `tests/ports_contract.rs` |
| F122 | testing-coverage | DIVERGENT | R33 | IMPLEMENTED | (P07, R33) `Cargo.toml` (`proptest`, `insta`), `tests/properties.rs`, `tests/cli/*` |
| F123 | testing-coverage | DIVERGENT | R33 | IMPLEMENTED | (P07, R33) `Cargo.toml` (`proptest`, `insta`), `tests/properties.rs`, `tests/cli/*` |
| F124 | testing-coverage | DIVERGENT | R32 | IMPLEMENTED | (P07/P10, R32) `.config/nextest.toml`, `Justfile` (`test`/`test-slow`/`test-live`/`test-all`), `lefthook.yml`, `tests/cli/*`, `.github/workflows/ci.yml` |
| F125 | testing-coverage | DIVERGENT | R32 | IMPLEMENTED | (P07/P10, R32) `.config/nextest.toml`, `Justfile` (`test`/`test-slow`/`test-live`/`test-all`), `lefthook.yml`, `tests/cli/*`, `.github/workflows/ci.yml` |
| F126 | testing-coverage | DIVERGENT | R34 | IMPLEMENTED | (P10, R34) `.github/workflows/canary.yml` (weekly 3-leg freshness canary + single-issue report), `tests/workflows_contract.rs` |
| F127 | testing-coverage | DIVERGENT | R34 | IMPLEMENTED | (P10, R34) `.github/workflows/canary.yml` (weekly 3-leg freshness canary + single-issue report), `tests/workflows_contract.rs` |
| F128 | testing-coverage | DIVERGENT | R32 | IMPLEMENTED | (P07/P10, R32) `.config/nextest.toml`, `Justfile` (`test`/`test-slow`/`test-live`/`test-all`), `lefthook.yml`, `tests/cli/*`, `.github/workflows/ci.yml` |
| F129 | testing-coverage | DIVERGENT | R32 | IMPLEMENTED | (P07/P10, R32) `.config/nextest.toml`, `Justfile` (`test`/`test-slow`/`test-live`/`test-all`), `lefthook.yml`, `tests/cli/*`, `.github/workflows/ci.yml` |
| F130 | testing-coverage | DIVERGENT | R32 | IMPLEMENTED | (P07/P10, R32) `.config/nextest.toml`, `Justfile` (`test`/`test-slow`/`test-live`/`test-all`), `lefthook.yml`, `tests/cli/*`, `.github/workflows/ci.yml` |
| F131 | testing-coverage | DIVERGENT | R32 | IMPLEMENTED | (P07/P10, R32) `.config/nextest.toml`, `Justfile` (`test`/`test-slow`/`test-live`/`test-all`), `lefthook.yml`, `tests/cli/*`, `.github/workflows/ci.yml` |
| F132 | testing-coverage | RUST-ONLY | R32 | IMPLEMENTED | (P07/P10, R32) `.config/nextest.toml`, `Justfile` (`test`/`test-slow`/`test-live`/`test-all`), `lefthook.yml`, `tests/cli/*`, `.github/workflows/ci.yml` |
| F133 | testing-coverage | COMMON → REUSE | — | IMPLEMENTED | `tests/release_contract.rs` (version single-sourcing across all 4 `Cargo.toml` manifests, `Cargo.lock`, `.release-please-manifest.json`, and `VERSION`) |
| F134 | testing-coverage | DIVERGENT | R35 | IMPLEMENTED | (P07/P10, R35) `Justfile` (`coverage`, `coverage_fail_under`), `.github/workflows/ci.yml` (`coverage` job + artifact upload) |
| F135 | testing-coverage | DIVERGENT | R35 | IMPLEMENTED | (P07/P10, R35) `Justfile` (`coverage`, `coverage_fail_under`), `.github/workflows/ci.yml` (`coverage` job + artifact upload) |
| F136 | testing-coverage | DIVERGENT | R35 | IMPLEMENTED | (P07/P10, R35) `Justfile` (`coverage`, `coverage_fail_under`), `.github/workflows/ci.yml` (`coverage` job + artifact upload) |
| F137 | testing-coverage | DIVERGENT | R35 | IMPLEMENTED | (P07/P10, R35) `Justfile` (`coverage`, `coverage_fail_under`), `.github/workflows/ci.yml` (`coverage` job + artifact upload) |
| F138 | testing-coverage | DIVERGENT | R35 | IMPLEMENTED | (P07/P10, R35) `Justfile` (`coverage`, `coverage_fail_under`), `.github/workflows/ci.yml` (`coverage` job + artifact upload) |
| F141 | testing-coverage | COMMON → REUSE | — | IMPLEMENTED | `tests/repo_hygiene.rs`, `tests/justfile_contract.rs`, `tests/workflows_contract.rs`, `tests/docs_contract.rs` |
| F142 | git-hooks-commit-hygiene | COMMON → REUSE | — | IMPLEMENTED | `lefthook.yml` (`lefthook 2.1.14`), `Justfile` (`hooks-install`/`hooks-run`) |
| F143 | git-hooks-commit-hygiene | DIVERGENT | R37 | IMPLEMENTED | (P05, R37) `lefthook.yml` (`min_version: 2.1.14`, `tags: [compiles]`), `Justfile` (`hooks-install`/`hooks-run`), `tests/repo_hygiene.rs` |
| F144 | git-hooks-commit-hygiene | DIVERGENT | R37 | IMPLEMENTED | (P05, R37) `lefthook.yml` (`min_version: 2.1.14`, `tags: [compiles]`), `Justfile` (`hooks-install`/`hooks-run`), `tests/repo_hygiene.rs` |
| F145 | git-hooks-commit-hygiene | COMMON → REUSE | — | IMPLEMENTED | `Justfile` (`hooks-install` recipe re-wiring `lefthook` and `.gitmessage`) |
| F146 | git-hooks-commit-hygiene | COMMON → REUSE | — | IMPLEMENTED | `lefthook.yml` (`pre-commit: parallel: true`) |
| F147 | git-hooks-commit-hygiene | COMMON → REUSE | — | IMPLEMENTED | `lefthook.yml` (fast staged checks in `pre-commit`, `tags: [compiles]` and unpushed checks in `pre-push`) |
| F148 | git-hooks-commit-hygiene | COMMON → REUSE | — | IMPLEMENTED | `lefthook.yml` (`commit-msg:` hook invoking `committed`), `.github/workflows/commitlint.yml` |
| F149 | git-hooks-commit-hygiene | COMMON → SUBSTITUTE | R38 | IMPLEMENTED | (P05/P10, R38) `committed.toml`, `committed.bot.toml`, `scripts/test-committed.sh`, `lefthook.yml`, `.github/workflows/commitlint.yml`, `tests/repo_hygiene.rs` |
| F150 | git-hooks-commit-hygiene | DIVERGENT | R38 | IMPLEMENTED | (P05/P10, R38) `committed.toml`, `committed.bot.toml`, `scripts/test-committed.sh`, `lefthook.yml`, `.github/workflows/commitlint.yml`, `tests/repo_hygiene.rs` |
| F151 | git-hooks-commit-hygiene | COMMON → SUBSTITUTE | R38 | IMPLEMENTED | (P05/P10, R38) `committed.toml`, `committed.bot.toml`, `scripts/test-committed.sh`, `lefthook.yml`, `.github/workflows/commitlint.yml`, `tests/repo_hygiene.rs` |
| F152 | git-hooks-commit-hygiene | DIVERGENT | R38 | IMPLEMENTED | (P05/P10, R38) `committed.toml`, `committed.bot.toml`, `scripts/test-committed.sh`, `lefthook.yml`, `.github/workflows/commitlint.yml`, `tests/repo_hygiene.rs` |
| F153 | git-hooks-commit-hygiene | DIVERGENT | R38 | IMPLEMENTED | (P05/P10, R38) `committed.toml`, `committed.bot.toml`, `scripts/test-committed.sh`, `lefthook.yml`, `.github/workflows/commitlint.yml`, `tests/repo_hygiene.rs` |
| F154 | git-hooks-commit-hygiene | DIVERGENT | R38 | IMPLEMENTED | (P05/P10, R38) `committed.toml`, `committed.bot.toml`, `scripts/test-committed.sh`, `lefthook.yml`, `.github/workflows/commitlint.yml`, `tests/repo_hygiene.rs` |
| F155 | git-hooks-commit-hygiene | DIVERGENT | R38 | IMPLEMENTED | (P05/P10, R38) `committed.toml`, `committed.bot.toml`, `scripts/test-committed.sh`, `lefthook.yml`, `.github/workflows/commitlint.yml`, `tests/repo_hygiene.rs` |
| F156 | git-hooks-commit-hygiene | DIVERGENT | R38 | IMPLEMENTED | (P05/P10, R38) `committed.toml`, `committed.bot.toml`, `scripts/test-committed.sh`, `lefthook.yml`, `.github/workflows/commitlint.yml`, `tests/repo_hygiene.rs` |
| F157 | git-hooks-commit-hygiene | DIVERGENT | R38 | IMPLEMENTED | (P05/P10, R38) `committed.toml`, `committed.bot.toml`, `scripts/test-committed.sh`, `lefthook.yml`, `.github/workflows/commitlint.yml`, `tests/repo_hygiene.rs` |
| F158 | git-hooks-commit-hygiene | ADOPT | — | IMPLEMENTED | `.gitmessage` (comment-only Conventional Commits template with 11 types and 50/72 caps) |
| F159 | git-hooks-commit-hygiene | ADOPT | — | IMPLEMENTED | `Justfile` (`hooks-install` executes `git config commit.template .gitmessage`) |
| F160 | git-hooks-commit-hygiene | ADOPT | — | IMPLEMENTED | `tests/repo_hygiene.rs` (`committed_configs_and_gitmessage_share_one_convention_f160`) |
| F161 | git-hooks-commit-hygiene | ADOPT | — | IMPLEMENTED | `tests/repo_hygiene.rs` (`lefthook_config_satisfies_r37_and_f161` + `lefthook validate`) |
| F162 | git-hooks-commit-hygiene | DIVERGENT | R27 | IMPLEMENTED | (P04/P05, R27) `rustfmt.toml`, `rust-toolchain.toml`, `Justfile` (`format`/`format-check`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F163 | git-hooks-commit-hygiene | DIVERGENT | R39 | IMPLEMENTED | (P05, R39) `.gitleaks.toml`, `.gitleaksignore`, `lefthook.yml` (pre-commit + pre-push), `tests/repo_hygiene.rs` |
| F164 | git-hooks-commit-hygiene | DIVERGENT | R39 | IMPLEMENTED | (P05, R39) `.gitleaks.toml`, `.gitleaksignore`, `lefthook.yml` (pre-commit + pre-push), `tests/repo_hygiene.rs` |
| F165 | git-hooks-commit-hygiene | DIVERGENT | R39 | IMPLEMENTED | (P05, R39) `.gitleaks.toml`, `.gitleaksignore`, `lefthook.yml` (pre-commit + pre-push), `tests/repo_hygiene.rs` |
| F166 | git-hooks-commit-hygiene | DIVERGENT | R39 | IMPLEMENTED | (P05, R39) `.gitleaks.toml`, `.gitleaksignore`, `lefthook.yml` (pre-commit + pre-push), `tests/repo_hygiene.rs` |
| F167 | git-hooks-commit-hygiene | DIVERGENT | R40 | IMPLEMENTED | (P05, R40) `.editorconfig`, `.editorconfig-checker.json`, `.yamllint`, `typos.toml`, `Justfile` (`check-hygiene`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F168 | git-hooks-commit-hygiene | DIVERGENT | R40 | IMPLEMENTED | (P05, R40) `.editorconfig`, `.editorconfig-checker.json`, `.yamllint`, `typos.toml`, `Justfile` (`check-hygiene`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F169 | git-hooks-commit-hygiene | DIVERGENT | R40 | IMPLEMENTED | (P05, R40) `.editorconfig`, `.editorconfig-checker.json`, `.yamllint`, `typos.toml`, `Justfile` (`check-hygiene`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F170 | git-hooks-commit-hygiene | DIVERGENT | R40 | IMPLEMENTED | (P05, R40) `.editorconfig`, `.editorconfig-checker.json`, `.yamllint`, `typos.toml`, `Justfile` (`check-hygiene`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F171 | git-hooks-commit-hygiene | DIVERGENT | R41 | IMPLEMENTED | (P05, R41) `scripts/check-cargo-lock.sh`, `scripts/test-check-cargo-lock.sh`, `lefthook.yml`, `Justfile` (`check-lockfile`) |
| F172 | git-hooks-commit-hygiene | DIVERGENT | R14 | IMPLEMENTED | (P05/P10, R14) `scripts/check-large-files.sh`, `scripts/test-check-large-files.sh`, `.gitattributes`, `lefthook.yml`, `.github/workflows/large-file-guard.yml` |
| F173 | git-hooks-commit-hygiene | DIVERGENT | R32 | IMPLEMENTED | (P07/P10, R32) `.config/nextest.toml`, `Justfile` (`test`/`test-slow`/`test-live`/`test-all`), `lefthook.yml`, `tests/cli/*`, `.github/workflows/ci.yml` |
| F174 | git-hooks-commit-hygiene | DIVERGENT | R37 | IMPLEMENTED | (P05, R37) `lefthook.yml` (`min_version: 2.1.14`, `tags: [compiles]`), `Justfile` (`hooks-install`/`hooks-run`), `tests/repo_hygiene.rs` |
| F175 | git-hooks-commit-hygiene | COMMON → REUSE | — | IMPLEMENTED | `Justfile` (`hooks-run` running `lefthook run pre-commit --all-files --no-auto-install`) |
| F176 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `Justfile` (`just 1.58.0` task runner) |
| F177 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `Justfile` (`[group(...)]` attributes on every recipe) |
| F178 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `Justfile` (short aliases `c`, `f`, `l`, `tc`, `t`, `ca`, `client-rust`, `contributors`) |
| F179 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `Makefile` (Level 1 `rustup` + `just`) + `Justfile` (Level 2 tasks), `AGENTS.md` |
| F180 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `Makefile` (`check:` target verifying `rustup`, `cargo`, `just`, plus optional `blaze` status) |
| F181 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `Justfile` (`check-deps` recipe verifying `rustup` components and all pinned tools with fix commands) |
| F182 | dev-experience-repo-hygiene | ADOPT | — | IMPLEMENTED | `Justfile` (`setup` invokes `make --no-print-directory check` before Level-2 installation) |
| F183 | dev-experience-repo-hygiene | DIVERGENT | R42 | IMPLEMENTED | (P04, R42) `Makefile`, `Justfile` (single tool table, bare/`cargo <sub>` invocations, zero provisioner prefixes), `tests/justfile_contract.rs` |
| F184 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `Makefile` (`install-rust`/`install-rust-force` and `install-just`/`install-just-force`) |
| F185 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `Justfile` (`debug-info` dependency-free environment diagnostic recipe) |
| F186 | dev-experience-repo-hygiene | ADOPT | — | IMPLEMENTED | `Makefile` (`hook-check:`) and `Justfile` (`hook-check`), report-only readiness doctor |
| F187 | dev-experience-repo-hygiene | DIVERGENT | R42 | IMPLEMENTED | (P04, R42) `Makefile`, `Justfile` (single tool table, bare/`cargo <sub>` invocations, zero provisioner prefixes), `tests/justfile_contract.rs` |
| F188 | dev-experience-repo-hygiene | DIVERGENT | R42 | IMPLEMENTED | (P04, R42) `Makefile`, `Justfile` (single tool table, bare/`cargo <sub>` invocations, zero provisioner prefixes), `tests/justfile_contract.rs` |
| F189 | dev-experience-repo-hygiene | DIVERGENT | R42 | IMPLEMENTED | (P04, R42) `Makefile`, `Justfile` (single tool table, bare/`cargo <sub>` invocations, zero provisioner prefixes), `tests/justfile_contract.rs` |
| F190 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `rust-toolchain.toml` (pins `channel = "1.100.1"`, `profile = "minimal"`, `rustfmt`/`clippy` components) |
| F191 | dev-experience-repo-hygiene | DIVERGENT | R40 | IMPLEMENTED | (P05, R40) `.editorconfig`, `.editorconfig-checker.json`, `.yamllint`, `typos.toml`, `Justfile` (`check-hygiene`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F192 | dev-experience-repo-hygiene | DIVERGENT | R40 | IMPLEMENTED | (P05, R40) `.editorconfig`, `.editorconfig-checker.json`, `.yamllint`, `typos.toml`, `Justfile` (`check-hygiene`), `lefthook.yml`, `.github/workflows/ci.yml` |
| F193 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `.vscode/extensions.json` (`rust-lang.rust-analyzer`, `vadimcn.vscode-lldb`, etc.) |
| F194 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `.vscode/launch.json` (committed LLDB debug profile for `rslbp`) |
| F195 | dev-experience-repo-hygiene | COMMON → SUBSTITUTE | R28 | IMPLEMENTED | (P04/P05, R28) `Cargo.toml` (`[workspace.lints.clippy]`), `clippy.toml`, `Justfile` (`lint`/`lint-fix`), `.vscode/settings.json`, `.vscode/extensions.json`, `.vscode/launch.json` |
| F196 | dev-experience-repo-hygiene | DIVERGENT | R28 | IMPLEMENTED | (P04/P05, R28) `Cargo.toml` (`[workspace.lints.clippy]`), `clippy.toml`, `Justfile` (`lint`/`lint-fix`), `.vscode/settings.json`, `.vscode/extensions.json`, `.vscode/launch.json` |
| F197 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `AGENTS.md` canonical hub + thin `CLAUDE.md` (`@AGENTS.md`), verified by `tests/repo_hygiene.rs` |
| F198 | dev-experience-repo-hygiene | DIVERGENT | R43 | IMPLEMENTED | (P05, R43) `AGENTS.md`, `CLAUDE.md`, `.claude/settings.json` (`companyAnnouncements`), zero `.cursor/`/`.windsurf/`/`.devin/`, `tests/repo_hygiene.rs` |
| F199 | dev-experience-repo-hygiene | DIVERGENT | R43 | IMPLEMENTED | (P05, R43) `AGENTS.md`, `CLAUDE.md`, `.claude/settings.json` (`companyAnnouncements`), zero `.cursor/`/`.windsurf/`/`.devin/`, `tests/repo_hygiene.rs` |
| F200 | dev-experience-repo-hygiene | DIVERGENT | R44 | IMPLEMENTED | (P05, R44) `.devcontainer/devcontainer.json` (digest-pinned Trixie Rust image), `.devcontainer/post-create.sh`, `tests/repo_hygiene.rs` |
| F201 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `.github/ISSUE_TEMPLATE/{bug,feature,docs}.yml` + `.github/ISSUE_TEMPLATE/config.yml` (`blank_issues_enabled: false`) |
| F202 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `.github/ISSUE_TEMPLATE/{bug,feature,docs}.yml` label schema, verified by `tests/community_contract.rs` |
| F203 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `.github/pull_request_template.md` pre-flight checklist referencing `just check` |
| F204 | dev-experience-repo-hygiene | DIVERGENT | R45 | IMPLEMENTED | (P12, R45) `.github/pull_request_template.md`, `.github/CONTRIBUTING.md`, `tests/community_contract.rs` |
| F205 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `.github/FUNDING.yml` (`github: smorin`) |
| F206 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `LICENSE` (Apache-2.0) + `LICENSE-MIT` (MIT) paired with `Cargo.toml` `license = "MIT OR Apache-2.0"` |
| F207 | dev-experience-repo-hygiene | DIVERGENT | R46 | IMPLEMENTED | (P04/P12, R46) `Cargo.toml` (`license = "MIT OR Apache-2.0"`), `LICENSE`, `LICENSE-MIT`, zero per-file headers, `tests/community_contract.rs` |
| F208 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `docs/contributing/cla-faq.md`, `docs/contributing/cla/{individual-cla,corporate-cla,cla-setup-guide}.md`, `docs/tools/cla-assistant.md` |
| F209 | dev-experience-repo-hygiene | COMMON → REUSE | — | IMPLEMENTED | `.contributors.yml`, `CONTRIBUTORS.md`, `tests/bootstrap_acceptance.rs` |
| F210 | dev-experience-repo-hygiene | DIVERGENT | R47 | IMPLEMENTED | (P12, R47) `Justfile` (`update-contributors` guarded `render`/`init`), `tests/community_contract.rs` |
| F211 | packaging-distribution | COMMON → REUSE | — | IMPLEMENTED | `Cargo.toml` + `crates/*/Cargo.toml` (Cargo native manifest build/package backend per R49) |
| F212 | packaging-distribution | COMMON → SUBSTITUTE | R49 | IMPLEMENTED | (P04, R49) `Cargo.toml` (`autobins = false`, `[lib]`, `[[bin]] rslbp`, explicit `[package] include`), `crates/*/Cargo.toml` |
| F213 | packaging-distribution | DIVERGENT | R49 | IMPLEMENTED | (P04, R49) `Cargo.toml` (`autobins = false`, `[lib]`, `[[bin]] rslbp`, explicit `[package] include`), `crates/*/Cargo.toml` |
| F214 | packaging-distribution | DIVERGENT | R68 | IMPLEMENTED | (P11, R68) `dist-workspace.toml` (`cargo-dist 0.33.0` follower mode), `Cargo.toml` (`[profile.release]` fat LTO + cu=1), `.github/workflows/release.yml`, `tests/release_contract.rs` |
| F215 | packaging-distribution | OMIT | — | OMITTED (non-analogous) | Non-analogous in Rust: compiled native crates have no JavaScript CJS/ESM module-format duality. |
| F216 | packaging-distribution | DIVERGENT | R49 | IMPLEMENTED | (P04, R49) `Cargo.toml` (`autobins = false`, `[lib]`, `[[bin]] rslbp`, explicit `[package] include`), `crates/*/Cargo.toml` |
| F217 | packaging-distribution | OMIT | — | OMITTED (non-analogous) | Non-analogous in Rust: `cargo build` emits native compiled executables directly with no wrapper script or shebang. |
| F218 | packaging-distribution | DIVERGENT | R49 | IMPLEMENTED | (P04, R49) `Cargo.toml` (`autobins = false`, `[lib]`, `[[bin]] rslbp`, explicit `[package] include`), `crates/*/Cargo.toml` |
| F219 | packaging-distribution | DIVERGENT | R49 | IMPLEMENTED | (P04, R49) `Cargo.toml` (`autobins = false`, `[lib]`, `[[bin]] rslbp`, explicit `[package] include`), `crates/*/Cargo.toml` |
| F220 | packaging-distribution | ADOPT | — | IMPLEMENTED | `README.md` and `docs/RELEASE.md` (`cargo binstall`, shell installer, `cargo install --locked`) |
| F221 | packaging-distribution | DIVERGENT | R50 | IMPLEMENTED | (P07/P10, R50) `Justfile` (`install-check`), `.github/workflows/ci.yml` (`install-smoke` default + web legs, `OV-13`) |
| F222 | packaging-distribution | DIVERGENT | R50 | IMPLEMENTED | (P07/P10, R50) `Justfile` (`install-check`), `.github/workflows/ci.yml` (`install-smoke` default + web legs, `OV-13`) |
| F223 | packaging-distribution | DIVERGENT | R51 | IMPLEMENTED | (P09/P11, R51) `Dockerfile`, `.dockerignore`, `.github/workflows/docker-web.yml`, `.github/workflows/publish-container.yml` (`OV-14` + owner `1a-A` GHCR override) |
| F224 | config-env-logging | COMMON → REUSE | — | IMPLEMENTED | `crates/core/src/config/` (TOML configuration format across all layers) |
| F225 | config-env-logging | DIVERGENT | R52 | IMPLEMENTED | (P06, R52) `crates/core/src/config/loader.rs` (`toml`), `crates/core/src/config/writer.rs` (`toml_edit`), `tests/config_and_secrets_contract.rs` |
| F226 | config-env-logging | DIVERGENT | R52 | IMPLEMENTED | (P06, R52) `crates/core/src/config/loader.rs` (`toml`), `crates/core/src/config/writer.rs` (`toml_edit`), `tests/config_and_secrets_contract.rs` |
| F227 | config-env-logging | COMMON → REUSE | — | IMPLEMENTED | `crates/core/src/paths.rs` (`CONFIG_FILE_NAME = "rslbp_config.toml"`) |
| F228 | config-env-logging | DIVERGENT | R53 | IMPLEMENTED | (P06, R53) `crates/core/src/config/schema.rs`, `crates/core/src/config/validate.rs` (`UnvalidatedConfig`/`ValidConfig`), `tests/config_and_secrets_contract.rs` |
| F229 | config-env-logging | COMMON → REUSE | — | IMPLEMENTED | `crates/core/src/config/schema.rs`, `crates/core/src/config/validate.rs` (typed schema + per-key semantic checks) |
| F230 | config-env-logging | DIVERGENT | R54 | IMPLEMENTED | (P06, R54) `crates/core/src/config/discovery.rs` (6-rung precedence + ancestor `.rslbp/rslbp_config.toml`), `tests/config_and_secrets_contract.rs` |
| F231 | config-env-logging | DIVERGENT | R54 | IMPLEMENTED | (P06, R54) `crates/core/src/config/discovery.rs` (6-rung precedence + ancestor `.rslbp/rslbp_config.toml`), `tests/config_and_secrets_contract.rs` |
| F232 | config-env-logging | DIVERGENT | R54 | IMPLEMENTED | (P06, R54) `crates/core/src/config/discovery.rs` (6-rung precedence + ancestor `.rslbp/rslbp_config.toml`), `tests/config_and_secrets_contract.rs` |
| F233 | config-env-logging | COMMON → REUSE | — | IMPLEMENTED | `crates/core/src/config/loader.rs`, `crates/cli/src/args.rs` (`--config` replaces discovery entirely) |
| F234 | config-env-logging | DIVERGENT | R54 | IMPLEMENTED | (P06, R54) `crates/core/src/config/discovery.rs` (6-rung precedence + ancestor `.rslbp/rslbp_config.toml`), `tests/config_and_secrets_contract.rs` |
| F235 | config-env-logging | DIVERGENT | R55 | IMPLEMENTED | (P06, R55) `crates/core/src/config/loader.rs` (provenance-aware two-phase tolerance), `tests/config_and_secrets_contract.rs` |
| F236 | config-env-logging | DIVERGENT | R55 | IMPLEMENTED | (P06, R55) `crates/core/src/config/loader.rs` (provenance-aware two-phase tolerance), `tests/config_and_secrets_contract.rs` |
| F237 | config-env-logging | COMMON → REUSE | — | IMPLEMENTED | `crates/core/src/config/loader.rs` (unparsable explicit config fails with `RSLB202` exit 2) |
| F238 | config-env-logging | DIVERGENT | R55 | IMPLEMENTED | (P06, R55) `crates/core/src/config/loader.rs` (provenance-aware two-phase tolerance), `tests/config_and_secrets_contract.rs` |
| F239 | config-env-logging | DIVERGENT | R56 | IMPLEMENTED | (P06, R56) `crates/core/src/secrets.rs` (`secrecy`/`zeroize`, 3-tier resolution, `RSLB204`), `src/keychain.rs` (`--features keychain`), `tests/config_and_secrets_contract.rs` |
| F240 | config-env-logging | DIVERGENT | R56 | IMPLEMENTED | (P06, R56) `crates/core/src/secrets.rs` (`secrecy`/`zeroize`, 3-tier resolution, `RSLB204`), `src/keychain.rs` (`--features keychain`), `tests/config_and_secrets_contract.rs` |
| F241 | config-env-logging | COMMON → REUSE | — | IMPLEMENTED | `crates/core/src/secrets.rs` (`TOKEN_ENV_VAR = "RSLBP_TOKEN"`) |
| F242 | config-env-logging | COMMON → REUSE | — | IMPLEMENTED | `crates/core/src/secrets.rs` (empty `RSLBP_TOKEN` treated as unset and falls through) |
| F243 | config-env-logging | COMMON → REUSE | — | IMPLEMENTED | `crates/core/src/secrets.rs` (`write_atomic_0600`: `O_CREAT` mode `0600` + fsync + same-dir atomic rename) |
| F244 | config-env-logging | OMIT | — | OMITTED (non-analogous) | Non-analogous under fixed `target-os-matrix = ubuntu-latest, macos-latest` (Windows intentionally excluded). |
| F245 | config-env-logging | DIVERGENT | R56 | IMPLEMENTED | (P06, R56) `crates/core/src/secrets.rs` (`secrecy`/`zeroize`, 3-tier resolution, `RSLB204`), `src/keychain.rs` (`--features keychain`), `tests/config_and_secrets_contract.rs` |
| F246 | config-env-logging | COMMON → REUSE | — | IMPLEMENTED | `crates/core/src/secrets.rs` (`Token::masked`: `***<last4>` for length >= 8, `***` otherwise) |
| F247 | config-env-logging | COMMON → REUSE | — | IMPLEMENTED | `crates/core/src/paths.rs`, `crates/core/src/config/discovery.rs` (XDG env overrides honored on Linux & macOS) |
| F248 | config-env-logging | OMIT | — | OMITTED (non-analogous) | Non-analogous under fixed `target-os-matrix = ubuntu-latest, macos-latest` (Windows default config path excluded). |
| F249 | config-env-logging | DIVERGENT | R57 | IMPLEMENTED | (P06, R57) `crates/core/src/paths.rs` (`etcetera 0.11.0` 4-dir `Paths`), `tests/config_and_secrets_contract.rs` |
| F250 | config-env-logging | DIVERGENT | R58 | IMPLEMENTED | (P06, R58) `src/telemetry.rs` (`tracing` + `tracing-subscriber`, owned redacting formatters, `reload::Handle`, CLI/Service profiles, `OV-09`), `tests/telemetry_contract.rs` |
| F251 | config-env-logging | DIVERGENT | R58 | IMPLEMENTED | (P06, R58) `src/telemetry.rs` (`tracing` + `tracing-subscriber`, owned redacting formatters, `reload::Handle`, CLI/Service profiles, `OV-09`), `tests/telemetry_contract.rs` |
| F252 | config-env-logging | DIVERGENT | R58 | IMPLEMENTED | (P06, R58) `src/telemetry.rs` (`tracing` + `tracing-subscriber`, owned redacting formatters, `reload::Handle`, CLI/Service profiles, `OV-09`), `tests/telemetry_contract.rs` |
| F253 | config-env-logging | DIVERGENT | R58 | IMPLEMENTED | (P06, R58) `src/telemetry.rs` (`tracing` + `tracing-subscriber`, owned redacting formatters, `reload::Handle`, CLI/Service profiles, `OV-09`), `tests/telemetry_contract.rs` |
| F254 | config-env-logging | DIVERGENT | R58 | IMPLEMENTED | (P06, R58) `src/telemetry.rs` (`tracing` + `tracing-subscriber`, owned redacting formatters, `reload::Handle`, CLI/Service profiles, `OV-09`), `tests/telemetry_contract.rs` |
| F255 | config-env-logging | DIVERGENT | R59 | IMPLEMENTED | (P06, R59) `src/telemetry.rs` (std-only `0600` `RotatingFile` sink, independent level/format), `tests/telemetry_contract.rs` |
| F256 | config-env-logging | DIVERGENT | R59 | IMPLEMENTED | (P06, R59) `src/telemetry.rs` (std-only `0600` `RotatingFile` sink, independent level/format), `tests/telemetry_contract.rs` |
| F257 | config-env-logging | DIVERGENT | R59 | IMPLEMENTED | (P06, R59) `src/telemetry.rs` (std-only `0600` `RotatingFile` sink, independent level/format), `tests/telemetry_contract.rs` |
| F258 | config-env-logging | DIVERGENT | R59 | IMPLEMENTED | (P06, R59) `src/telemetry.rs` (std-only `0600` `RotatingFile` sink, independent level/format), `tests/telemetry_contract.rs` |
| F259 | config-env-logging | DIVERGENT | R59 | IMPLEMENTED | (P06, R59) `src/telemetry.rs` (std-only `0600` `RotatingFile` sink, independent level/format), `tests/telemetry_contract.rs` |
| F260 | config-env-logging | DIVERGENT | R59 | IMPLEMENTED | (P06, R59) `src/telemetry.rs` (std-only `0600` `RotatingFile` sink, independent level/format), `tests/telemetry_contract.rs` |
| F261 | config-env-logging | DIVERGENT | R59 | IMPLEMENTED | (P06, R59) `src/telemetry.rs` (std-only `0600` `RotatingFile` sink, independent level/format), `tests/telemetry_contract.rs` |
| F262 | config-env-logging | DIVERGENT | R58 | IMPLEMENTED | (P06, R58) `src/telemetry.rs` (`tracing` + `tracing-subscriber`, owned redacting formatters, `reload::Handle`, CLI/Service profiles, `OV-09`), `tests/telemetry_contract.rs` |
| F263 | config-env-logging | DIVERGENT | R58 | IMPLEMENTED | (P06, R58) `src/telemetry.rs` (`tracing` + `tracing-subscriber`, owned redacting formatters, `reload::Handle`, CLI/Service profiles, `OV-09`), `tests/telemetry_contract.rs` |
| F264 | cli-framework-ux | DIVERGENT | R60 | IMPLEMENTED | (P07, R60) `crates/cli/src/args.rs` (`clap 4.6.6` derive, `clap_complete`), `crates/cli/build.rs`, `tests/cli/*` (`OV-01` retired) |
| F265 | cli-framework-ux | DIVERGENT | R60 | IMPLEMENTED | (P07, R60) `crates/cli/src/args.rs` (`clap 4.6.6` derive, `clap_complete`), `crates/cli/build.rs`, `tests/cli/*` (`OV-01` retired) |
| F266 | cli-framework-ux | COMMON → REUSE | — | IMPLEMENTED | `crates/cli/src/args.rs` (`-V`/`--version` -> `rslbp <semver>`, exit 0) |
| F267 | cli-framework-ux | DIVERGENT | R60 | IMPLEMENTED | (P07, R60) `crates/cli/src/args.rs` (`clap 4.6.6` derive, `clap_complete`), `crates/cli/build.rs`, `tests/cli/*` (`OV-01` retired) |
| F268 | cli-framework-ux | DIVERGENT | R60 | IMPLEMENTED | (P07, R60) `crates/cli/src/args.rs` (`clap 4.6.6` derive, `clap_complete`), `crates/cli/build.rs`, `tests/cli/*` (`OV-01` retired) |
| F269 | cli-framework-ux | DIVERGENT | R60 | IMPLEMENTED | (P07, R60) `crates/cli/src/args.rs` (`clap 4.6.6` derive, `clap_complete`), `crates/cli/build.rs`, `tests/cli/*` (`OV-01` retired) |
| F270 | cli-framework-ux | DIVERGENT | R60 | IMPLEMENTED | (P07, R60) `crates/cli/src/args.rs` (`clap 4.6.6` derive, `clap_complete`), `crates/cli/build.rs`, `tests/cli/*` (`OV-01` retired) |
| F271 | cli-framework-ux | COMMON → REUSE | — | IMPLEMENTED | `crates/cli/src/args.rs` (`clap` built-in command/flag did-you-mean suggestions) |
| F272 | cli-framework-ux | DIVERGENT | R60 | IMPLEMENTED | (P07, R60) `crates/cli/src/args.rs` (`clap 4.6.6` derive, `clap_complete`), `crates/cli/build.rs`, `tests/cli/*` (`OV-01` retired) |
| F273 | cli-framework-ux | COMMON → REUSE | — | IMPLEMENTED | `crates/cli/src/args.rs` (`-v`/`--verbose` `ArgAction::Count`) |
| F274 | cli-framework-ux | DIVERGENT | R58 | IMPLEMENTED | (P06, R58) `src/telemetry.rs` (`tracing` + `tracing-subscriber`, owned redacting formatters, `reload::Handle`, CLI/Service profiles, `OV-09`), `tests/telemetry_contract.rs` |
| F275 | cli-framework-ux | COMMON → REUSE | — | IMPLEMENTED | `crates/cli/src/args.rs` (`--no-input` global flag disabling interactive prompts) |
| F276 | cli-framework-ux | DIVERGENT | R61 | IMPLEMENTED | (P07, R61) `crates/cli/src/prompter.rs` (`inquire 0.9.4`, `Prompter` trait, `OV-02` declined confirm exits 0), `tests/cli/*` |
| F277 | cli-framework-ux | ADOPT | — | IMPLEMENTED | `crates/cli/src/args.rs` (`--dry-run` on `project create`, `project delete`, `config set`, `config init`) |
| F278 | cli-framework-ux | ADOPT | — | IMPLEMENTED | `crates/cli/src/args.rs` (`-y`/`--yes` on `project delete`, `config set`, `config init`) |
| F279 | cli-framework-ux | DIVERGENT | R61 | IMPLEMENTED | (P07, R61) `crates/cli/src/prompter.rs` (`inquire 0.9.4`, `Prompter` trait, `OV-02` declined confirm exits 0), `tests/cli/*` |
| F280 | cli-framework-ux | DIVERGENT | R61 | IMPLEMENTED | (P07, R61) `crates/cli/src/prompter.rs` (`inquire 0.9.4`, `Prompter` trait, `OV-02` declined confirm exits 0), `tests/cli/*` |
| F281 | cli-framework-ux | DIVERGENT | R62 | IMPLEMENTED | (P07, R62) `crates/core/src/clipboard.rs`, `src/clipboard_adapter.rs` (`arboard`, default-on `clipboard` feature, Linux daemon), `tests/cli/*` |
| F282 | cli-framework-ux | DIVERGENT | R62 | IMPLEMENTED | (P07, R62) `crates/core/src/clipboard.rs`, `src/clipboard_adapter.rs` (`arboard`, default-on `clipboard` feature, Linux daemon), `tests/cli/*` |
| F283 | cli-framework-ux | DIVERGENT | R63 | IMPLEMENTED | (P07, R63) `crates/cli/src/spinner.rs` (`indicatif 0.18`, 3-input suppression predicate) |
| F284 | cli-framework-ux | DIVERGENT | R64 | IMPLEMENTED | (P07, R64) `crates/cli/src/pager.rs` (`shlex 2.0.1`, `RSLBP_PAGER` > `PAGER` > `less -FRX`) |
| F285 | cli-framework-ux | DIVERGENT | R64 | IMPLEMENTED | (P07, R64) `crates/cli/src/pager.rs` (`shlex 2.0.1`, `RSLBP_PAGER` > `PAGER` > `less -FRX`) |
| F286 | cli-framework-ux | COMMON → REUSE | — | IMPLEMENTED | `crates/cli/src/args.rs`, `crates/cli/src/color.rs` (`--no-color` global flag) |
| F287 | cli-framework-ux | DIVERGENT | R65 | IMPLEMENTED | (P07, R65) `crates/cli/src/color.rs` (`anstream`/`anstyle`, 4-tier precedence chain) |
| F288 | cli-framework-ux | DIVERGENT | R65 | IMPLEMENTED | (P07, R65) `crates/cli/src/color.rs` (`anstream`/`anstyle`, 4-tier precedence chain) |
| F289 | cli-framework-ux | DIVERGENT | R65 | IMPLEMENTED | (P07, R65) `crates/cli/src/color.rs` (`anstream`/`anstyle`, 4-tier precedence chain) |
| F290 | cli-framework-ux | DIVERGENT | R65 | IMPLEMENTED | (P07, R65) `crates/cli/src/color.rs` (`anstream`/`anstyle`, 4-tier precedence chain) |
| F291 | cli-framework-ux | DIVERGENT | R66 | IMPLEMENTED | (P07, R66) `crates/cli/src/output.rs` (`table\|json\|markdown\|name`, `--output-file`, `--no-clobber`, exact `tabled =0.22.0`) |
| F292 | cli-framework-ux | COMMON → REUSE | — | IMPLEMENTED | `crates/cli/src/args.rs` (`--json` global shorthand flag) |
| F293 | cli-framework-ux | DIVERGENT | R66 | IMPLEMENTED | (P07, R66) `crates/cli/src/output.rs` (`table\|json\|markdown\|name`, `--output-file`, `--no-clobber`, exact `tabled =0.22.0`) |
| F294 | cli-framework-ux | COMMON → REUSE | — | IMPLEMENTED | `crates/core/src/error.rs` (`ErrorEnvelope`), `src/main.rs` (stderr JSON envelope) |
| F295 | cli-framework-ux | DIVERGENT | R67 | IMPLEMENTED | (P06/P07, R67) `crates/core/src/error.rs` (`ErrorCode::ALL`, `Exit`, `ErrorEnvelope`), `src/crash_sink.rs`, `tests/error_contract.rs` |
| F296 | cli-framework-ux | DIVERGENT | R67 | IMPLEMENTED | (P06/P07, R67) `crates/core/src/error.rs` (`ErrorCode::ALL`, `Exit`, `ErrorEnvelope`), `src/crash_sink.rs`, `tests/error_contract.rs` |
| F297 | cli-framework-ux | DIVERGENT | R67 | IMPLEMENTED | (P06/P07, R67) `crates/core/src/error.rs` (`ErrorCode::ALL`, `Exit`, `ErrorEnvelope`), `src/crash_sink.rs`, `tests/error_contract.rs` |
| F298 | cli-framework-ux | DIVERGENT | R67 | IMPLEMENTED | (P06/P07, R67) `crates/core/src/error.rs` (`ErrorCode::ALL`, `Exit`, `ErrorEnvelope`), `src/crash_sink.rs`, `tests/error_contract.rs` |
| F299 | cli-framework-ux | DIVERGENT | R67 | IMPLEMENTED | (P06/P07, R67) `crates/core/src/error.rs` (`ErrorCode::ALL`, `Exit`, `ErrorEnvelope`), `src/crash_sink.rs`, `tests/error_contract.rs` |
| F300 | cli-framework-ux | DIVERGENT | R67 | IMPLEMENTED | (P06/P07, R67) `crates/core/src/error.rs` (`ErrorCode::ALL`, `Exit`, `ErrorEnvelope`), `src/crash_sink.rs`, `tests/error_contract.rs` |
| F301 | cli-framework-ux | COMMON → REUSE | — | IMPLEMENTED | `src/main.rs`, `src/crash_sink.rs` (debug/verbose diagnostic detail gated on `--debug`/`-v` while crash sink records NDJSON) |
| F302 | cli-framework-ux | DIVERGENT | R67 | IMPLEMENTED | (P06/P07, R67) `crates/core/src/error.rs` (`ErrorCode::ALL`, `Exit`, `ErrorEnvelope`), `src/crash_sink.rs`, `tests/error_contract.rs` |
| F303 | web-service | DIVERGENT | R69 | IMPLEMENTED | (P08, R69) `crates/web/src/server.rs`, `src/bin/serve.rs`, `Cargo.toml` (`web = ["dep:rs-launch-blueprint-web"]`), `bacon.toml`, `Justfile` (`serve`), `tests/web_serve_contract.rs` |
| F304 | web-service | DIVERGENT | R58 | IMPLEMENTED | (P06, R58) `src/telemetry.rs` (`tracing` + `tracing-subscriber`, owned redacting formatters, `reload::Handle`, CLI/Service profiles, `OV-09`), `tests/telemetry_contract.rs` |
| F305 | web-service | DIVERGENT | R70 | IMPLEMENTED | (P08, R70) `crates/web/src/problems.rs` (RFC 9457 `problem_details`, `W5` 5xx redaction, `problem_catalog`), `crates/web/tests/*` |
| F306 | web-service | DIVERGENT | R70 | IMPLEMENTED | (P08, R70) `crates/web/src/problems.rs` (RFC 9457 `problem_details`, `W5` 5xx redaction, `problem_catalog`), `crates/web/tests/*` |
| F307 | web-service | DIVERGENT | R71 | IMPLEMENTED | (P09, R71) `crates/web/src/openapi.rs` (`utoipa` + `utoipa-axum`), `openapi/openapi.json`, `openapi/oasdiff-levels.txt`, `.github/workflows/api-contract.yml`, `Justfile` (`export-openapi`/`check-openapi`/`api-breaking`) |
| F308 | web-service | ADOPT | — | IMPLEMENTED | `crates/web/src/routes/projects.rs` (`/v1/projects`), `crates/web/src/routes/ops.rs` (`/healthz`, `/readyz`) |
| F309 | web-service | ADOPT | — | IMPLEMENTED | `crates/web/src/middleware.rs` (`DEPRECATION_HEADER`, `SUNSET_HEADER`, `deprecation_headers` RFC 9745 + RFC 8594 helper + unit test) |
| F310 | web-service | DIVERGENT | R72 | IMPLEMENTED | (P08, R72) `crates/web/src/pagination.rs` (first-party URL-safe base64 cursor pagination) |
| F311 | web-service | DIVERGENT | R72 | IMPLEMENTED | (P08, R72) `crates/web/src/pagination.rs` (first-party URL-safe base64 cursor pagination) |
| F312 | web-service | DIVERGENT | R71 | IMPLEMENTED | (P09, R71) `crates/web/src/openapi.rs` (`utoipa` + `utoipa-axum`), `openapi/openapi.json`, `openapi/oasdiff-levels.txt`, `.github/workflows/api-contract.yml`, `Justfile` (`export-openapi`/`check-openapi`/`api-breaking`) |
| F313 | web-service | DIVERGENT | R73 | IMPLEMENTED | (P08, R73) `crates/core/src/idempotency.rs`, `crates/web/src/idempotency.rs` (CAS idempotency store, `409`/`422`/`Idempotency-Replayed`, `OV-16`) |
| F314 | web-service | DIVERGENT | R73 | IMPLEMENTED | (P08, R73) `crates/core/src/idempotency.rs`, `crates/web/src/idempotency.rs` (CAS idempotency store, `409`/`422`/`Idempotency-Replayed`, `OV-16`) |
| F315 | web-service | DIVERGENT | R73 | IMPLEMENTED | (P08, R73) `crates/core/src/idempotency.rs`, `crates/web/src/idempotency.rs` (CAS idempotency store, `409`/`422`/`Idempotency-Replayed`, `OV-16`) |
| F316 | web-service | DIVERGENT | R74 | IMPLEMENTED | (P08, R74) `crates/web/src/rate_limit.rs` (bounded per-IP GCRA rate limiter, `429` + `Retry-After`, `OV-17`) |
| F317 | web-service | DIVERGENT | R75 | IMPLEMENTED | (P08, R75) `crates/web/src/middleware.rs` (L1–L9 fixed-order `tower-http` stack, probe exclusion, `traceparent`, security headers) |
| F318 | web-service | DIVERGENT | R75 | IMPLEMENTED | (P08, R75) `crates/web/src/middleware.rs` (L1–L9 fixed-order `tower-http` stack, probe exclusion, `traceparent`, security headers) |
| F319 | web-service | DIVERGENT | R75 | IMPLEMENTED | (P08, R75) `crates/web/src/middleware.rs` (L1–L9 fixed-order `tower-http` stack, probe exclusion, `traceparent`, security headers) |
| F320 | web-service | DIVERGENT | R75 | IMPLEMENTED | (P08, R75) `crates/web/src/middleware.rs` (L1–L9 fixed-order `tower-http` stack, probe exclusion, `traceparent`, security headers) |
| F321 | web-service | DIVERGENT | R75 | IMPLEMENTED | (P08, R75) `crates/web/src/middleware.rs` (L1–L9 fixed-order `tower-http` stack, probe exclusion, `traceparent`, security headers) |
| F322 | web-service | DIVERGENT | R76 | IMPLEMENTED | (P08, R76) `crates/web/src/cors.rs` (conditional `CorsLayer` mounted only when `RSLBP_WEB_CORS_ORIGINS` is set, `OV-08`) |
| F323 | web-service | DIVERGENT | R74 | IMPLEMENTED | (P08, R74) `crates/web/src/rate_limit.rs` (bounded per-IP GCRA rate limiter, `429` + `Retry-After`, `OV-17`) |
| F324 | web-service | DIVERGENT | R77 | IMPLEMENTED | (P08, R77) `crates/web/src/settings.rs` (`std::env` `WebSettings`, 19 `RSLBP_WEB_*` vars, `OV-04`) |
| F325 | web-service | DIVERGENT | R78 | IMPLEMENTED | (P09, R78) `src/otel.rs` (`--features otel`, `tracing-opentelemetry`, OTLP HTTP exporter), `tests/otel_contract.rs`, `.github/workflows/ci.yml` |
| F326 | web-service | DIVERGENT | R79 | IMPLEMENTED | (P09, R79) `crates/web/src/metrics.rs` (`--features metrics`, Prometheus `/metrics` RED metrics, `OV-07`) |
| F327 | web-service | DIVERGENT | R75 | IMPLEMENTED | (P08, R75) `crates/web/src/middleware.rs` (L1–L9 fixed-order `tower-http` stack, probe exclusion, `traceparent`, security headers) |
| F328 | web-service | DIVERGENT | R80 | IMPLEMENTED | (P08, R80) `crates/web/src/routes/ops.rs` (byte-stable `/healthz` + latch/redacted `/readyz`, `OV-05`) |
| F329 | web-service | DIVERGENT | R80 | IMPLEMENTED | (P08, R80) `crates/web/src/routes/ops.rs` (byte-stable `/healthz` + latch/redacted `/readyz`, `OV-05`) |
| F330 | web-service | DIVERGENT | R69 | IMPLEMENTED | (P08, R69) `crates/web/src/server.rs`, `src/bin/serve.rs`, `Cargo.toml` (`web = ["dep:rs-launch-blueprint-web"]`), `bacon.toml`, `Justfile` (`serve`), `tests/web_serve_contract.rs` |
| F331 | web-service | DIVERGENT | R69 | IMPLEMENTED | (P08, R69) `crates/web/src/server.rs`, `src/bin/serve.rs`, `Cargo.toml` (`web = ["dep:rs-launch-blueprint-web"]`), `bacon.toml`, `Justfile` (`serve`), `tests/web_serve_contract.rs` |
| F332 | web-service | DIVERGENT | R71 | IMPLEMENTED | (P09, R71) `crates/web/src/openapi.rs` (`utoipa` + `utoipa-axum`), `openapi/openapi.json`, `openapi/oasdiff-levels.txt`, `.github/workflows/api-contract.yml`, `Justfile` (`export-openapi`/`check-openapi`/`api-breaking`) |
| F333 | web-service | DIVERGENT | R71 | IMPLEMENTED | (P09, R71) `crates/web/src/openapi.rs` (`utoipa` + `utoipa-axum`), `openapi/openapi.json`, `openapi/oasdiff-levels.txt`, `.github/workflows/api-contract.yml`, `Justfile` (`export-openapi`/`check-openapi`/`api-breaking`) |
| F334 | web-service | DIVERGENT | R83 | IMPLEMENTED | (P09, R83) `crates/web/tests/contract_fuzz.rs` (`proptest` OpenAPI 3.1 contract fuzzer), `Justfile` (`test-contract`) |
| F335 | web-service | DIVERGENT | R84 | IMPLEMENTED | (P09, R84) `openapi-to-rust.toml`, `Justfile` (`generate-client` / `client-rust` using `openapi-to-rust 0.17.0`, `OV-11`) |
| F336 | web-service | DIVERGENT | R51 | IMPLEMENTED | (P09/P11, R51) `Dockerfile`, `.dockerignore`, `.github/workflows/docker-web.yml`, `.github/workflows/publish-container.yml` (`OV-14` + owner `1a-A` GHCR override) |
| F337 | web-service | DIVERGENT | R51 | IMPLEMENTED | (P09/P11, R51) `Dockerfile`, `.dockerignore`, `.github/workflows/docker-web.yml`, `.github/workflows/publish-container.yml` (`OV-14` + owner `1a-A` GHCR override) |
| F338 | web-service | DIVERGENT | R69 | IMPLEMENTED | (P08, R69) `crates/web/src/server.rs`, `src/bin/serve.rs`, `Cargo.toml` (`web = ["dep:rs-launch-blueprint-web"]`), `bacon.toml`, `Justfile` (`serve`), `tests/web_serve_contract.rs` |
| F339 | web-service | DIVERGENT | R69 | IMPLEMENTED | (P08, R69) `crates/web/src/server.rs`, `src/bin/serve.rs`, `Cargo.toml` (`web = ["dep:rs-launch-blueprint-web"]`), `bacon.toml`, `Justfile` (`serve`), `tests/web_serve_contract.rs` |
| F340 | web-service | OMIT | — | OMITTED (non-analogous) | Non-analogous in Rust: Cargo `--features web` is a compile-time gate; disabled code does not compile into the binary. |
| F341 | docs-system | DIVERGENT | R81 | IMPLEMENTED | (P13, R81) `book.toml`, `docs/SUMMARY.md`, `docs/README.md`, `.github/workflows/docs.yml`, `Justfile` (`docs-build`/`docs-dev`/`docs-init`/`docs-clean`), `tests/docs_contract.rs` |
| F342 | docs-system | COMMON → REUSE | — | IMPLEMENTED | `docs/{about,tutorials,tasks,reference,tools,contributing}/` (all 6 Diátaxis categories in `docs/SUMMARY.md`) |
| F343 | docs-system | DIVERGENT | R81 | IMPLEMENTED | (P13, R81) `book.toml`, `docs/SUMMARY.md`, `docs/README.md`, `.github/workflows/docs.yml`, `Justfile` (`docs-build`/`docs-dev`/`docs-init`/`docs-clean`), `tests/docs_contract.rs` |
| F344 | docs-system | DIVERGENT | R81 | IMPLEMENTED | (P13, R81) `book.toml`, `docs/SUMMARY.md`, `docs/README.md`, `.github/workflows/docs.yml`, `Justfile` (`docs-build`/`docs-dev`/`docs-init`/`docs-clean`), `tests/docs_contract.rs` |
| F345 | docs-system | DIVERGENT | R81 | IMPLEMENTED | (P13, R81) `book.toml`, `docs/SUMMARY.md`, `docs/README.md`, `.github/workflows/docs.yml`, `Justfile` (`docs-build`/`docs-dev`/`docs-init`/`docs-clean`), `tests/docs_contract.rs` |
| F346 | docs-system | DIVERGENT | R81 | IMPLEMENTED | (P13, R81) `book.toml`, `docs/SUMMARY.md`, `docs/README.md`, `.github/workflows/docs.yml`, `Justfile` (`docs-build`/`docs-dev`/`docs-init`/`docs-clean`), `tests/docs_contract.rs` |
| F347 | docs-system | COMMON → REUSE | — | IMPLEMENTED | `docs/docs.md` (documentation authoring guide, dialect rules, and verification commands) |
| F348 | docs-system | DIVERGENT | R82 | IMPLEMENTED | (P13, R82) `lychee.toml`, `.github/workflows/ci.yml` (`hygiene` offline lychee + `check` strict rustdoc), `.github/workflows/canary.yml` (`docs-external-links`), `Justfile` (`docs-check`/`docs-api`), `tests/docs_contract.rs` |
| F349 | docs-system | DIVERGENT | R82 | IMPLEMENTED | (P13, R82) `lychee.toml`, `.github/workflows/ci.yml` (`hygiene` offline lychee + `check` strict rustdoc), `.github/workflows/canary.yml` (`docs-external-links`), `Justfile` (`docs-check`/`docs-api`), `tests/docs_contract.rs` |
| F350 | docs-system | DIVERGENT | R82 | IMPLEMENTED | (P13, R82) `lychee.toml`, `.github/workflows/ci.yml` (`hygiene` offline lychee + `check` strict rustdoc), `.github/workflows/canary.yml` (`docs-external-links`), `Justfile` (`docs-check`/`docs-api`), `tests/docs_contract.rs` |
| F351 | docs-system | DIVERGENT | R81 | IMPLEMENTED | (P13, R81) `book.toml`, `docs/SUMMARY.md`, `docs/README.md`, `.github/workflows/docs.yml`, `Justfile` (`docs-build`/`docs-dev`/`docs-init`/`docs-clean`), `tests/docs_contract.rs` |
| F352 | docs-system | DIVERGENT | R81 | IMPLEMENTED | (P13, R81) `book.toml`, `docs/SUMMARY.md`, `docs/README.md`, `.github/workflows/docs.yml`, `Justfile` (`docs-build`/`docs-dev`/`docs-init`/`docs-clean`), `tests/docs_contract.rs` |
| F353 | docs-system | DIVERGENT | R82 | IMPLEMENTED | (P13, R82) `lychee.toml`, `.github/workflows/ci.yml` (`hygiene` offline lychee + `check` strict rustdoc), `.github/workflows/canary.yml` (`docs-external-links`), `Justfile` (`docs-check`/`docs-api`), `tests/docs_contract.rs` |
| F354 | docs-system | ADOPT | — | IMPLEMENTED | `docs/adr/README.md`, `docs/adr/template.md` |
| F355 | docs-system | ADOPT | — | IMPLEMENTED | `docs/design/README.md` |
| F356 | docs-system | ADOPT | — | IMPLEMENTED | `docs/research/README.md` |
| F357 | docs-system | ADOPT | — | IMPLEMENTED | `docs/README.md` (orientation map explaining corpus + `adr/`/`design/`/`research/` bucket split in mdBook) |
| F358 | docs-system | ADOPT | — | IMPLEMENTED | `docs/docs.md` (`Future Upgrade Path (F358)` documenting versioned/i18n/interactive migration trigger) |
| F359 | cli-framework-ux | DIVERGENT | R85 | IMPLEMENTED | (P07, R85) `crates/cli/src/rich.rs` (capability-gated OSC-8 hyperlinks + relative timestamps) |
| F360 | cli-framework-ux | DIVERGENT | R61 | IMPLEMENTED | (P07, R61) `crates/cli/src/prompter.rs` (`inquire 0.9.4`, `Prompter` trait, `OV-02` declined confirm exits 0), `tests/cli/*` |
| F361 | ci-workflows | RUST-ONLY | R86 | IMPLEMENTED | (P10, R86) `.github/workflows/codex-code-review.yml`, `.github/workflows/codex.yml`, `.github/codex/*.md`, `tests/workflows_contract.rs` |
| F362 | ci-workflows | RUST-ONLY | R86 | IMPLEMENTED | (P10, R86) `.github/workflows/codex-code-review.yml`, `.github/workflows/codex.yml`, `.github/codex/*.md`, `tests/workflows_contract.rs` |
