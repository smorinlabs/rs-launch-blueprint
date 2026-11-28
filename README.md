[![CI](https://github.com/smorinlabs/rs-launch-blueprint/actions/workflows/ci.yml/badge.svg)](https://github.com/smorinlabs/rs-launch-blueprint/actions/workflows/ci.yml)
[![Docs](https://github.com/smorinlabs/rs-launch-blueprint/actions/workflows/docs.yml/badge.svg)](https://github.com/smorinlabs/rs-launch-blueprint/actions/workflows/docs.yml)
[![License: MIT OR Apache-2.0](https://img.shields.io/badge/License-MIT%20OR%20Apache--2.0-blue.svg)](LICENSE)
[![Rust Edition: 2024](https://img.shields.io/badge/Rust%20Edition-2024-orange.svg)](Cargo.toml)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://www.conventionalcommits.org/)

# rs-launch-blueprint

The Rust sibling of [py-launch-blueprint](https://github.com/smorinlabs/py-launch-blueprint)
and [ts-launch-blueprint](https://github.com/smorinlabs/ts-launch-blueprint): a
production-ready Rust template for a **CLI (`rslbp`)**, **library (`rs_launch_blueprint`)**,
and **optional Axum web service (`rslbp-serve`)** with integrated architecture
enforcement, security gates, automated releases, and Template Press rebranding.

Every engineering choice is grounded in 85 audited research decisions (`R01`–`R86`)
and verified by contract tests across Linux (`ubuntu-latest`) and macOS
(`macos-latest`) on Rust Edition 2024.

## Features at a Glance

- **4-Crate Hexagonal Workspace:** root facade (`rs-launch-blueprint`, composition
  root, `rslbp` and optional `rslbp-serve` binaries), sync `crates/core` (`ProjectsPort`,
  `ProjectsService`, `ureq` adapter), `crates/cli`, and optional `crates/web`
  (`--features web`). Workspace-wide `unsafe_code = "forbid"`, `cargo-deny` bans,
  and `cargo-semver-checks` public-API guards.
- **Native Toolchain & Quality Gates:** two-level bootstrap (`Makefile` + `Justfile`),
  `rust-toolchain.toml`, `rustfmt`, `clippy`, strict `cargo check`, `dprint`
  (checksum-pinned Wasm plugins for TOML/JSON/YAML/Markdown), `ast-grep` security
  rules, `lefthook`, `committed`, `gitleaks`, `editorconfig-checker`, `ryl`,
  `typos`, `actionlint`, `zizmor`, ShellCheck, and `[parallel]` `just check`.
- **Production CLI (`rslbp`):** `clap` derive noun-verb grammar, `-o table|json|markdown|name`
  and `--output-file`, 6-rung TOML config discovery with `toml_edit` writes,
  3-tier secret policy (`--token-file` / `RSLBP_TOKEN` / `0600 credentials.toml` +
  optional `keychain`), `tracing` redacting logs + rotating file sink, pager,
  clipboard, spinner, rich OSC-8 rows, and append-only `RSLB###` error/exit taxonomy.
- **Optional Web Service (`rslbp-serve`):** Axum + Tokio behind off-by-default
  `--features web`, RFC 9457 `application/problem+json` errors, `/v1` routing,
  cursor pagination, `Idempotency-Key` replay, per-IP rate limiting, security headers,
  conditional CORS, `/healthz` + `/readyz`, optional Prometheus `/metrics` (`--features metrics`),
  optional OpenTelemetry OTLP tracing (`--features otel`), committed OpenAPI 3.1
  snapshot (`utoipa`) + `oasdiff` breaking-change CI + contract fuzzing +
  `openapi-to-rust` typed client generation, and a multi-stage distroless `Dockerfile`.
- **CI, Security & Releases:** plan-gated `ci.yml` with single required check
  `ci-ok`, MSRV floor job, install-smoke test, `cargo-llvm-cov` coverage floors,
  weekly dependency audit (`cargo-audit`, `cargo-deny`, OSV-Scanner), CodeQL,
  TruffleHog, weekly freshness canary, credential-preflighted Claude/Codex/Muse
  workflows, `release-please` (`release-type: rust`), `cargo-dist` pre-built CLI
  binaries, and GHCR container publishing.
- **AI-Ready & Template Press:** single canonical [AGENTS.md](AGENTS.md) hub
  (`CLAUDE.md` imports `@AGENTS.md`), zero vendor rule directories, pinned
  `template-press` rules + stubs, and the [`new-rust-project`](.claude/skills/new-rust-project/SKILL.md)
  bootstrap skill (symlinked under `.agents/skills/`).

## Quick Start

```bash
git clone https://github.com/smorinlabs/rs-launch-blueprint.git
cd rs-launch-blueprint
make bootstrap           # Level 1 — base toolchain (rustup + just); skip if installed
just setup               # Level 2 — pinned dev tools, rustup components, lefthook hooks
just check               # Run all read-only quality, security, lint, typecheck, and test gates
```

End-user CLI installation (once a release is published):

```bash
cargo binstall rs-launch-blueprint
# or via the cargo-dist shell installer attached to each GitHub Release:
curl --proto '=https' --tlsv1.2 -LsSf \
  https://github.com/smorinlabs/rs-launch-blueprint/releases/latest/download/rs-launch-blueprint-installer.sh | sh
# or compile from crates.io source:
cargo install --locked rs-launch-blueprint
```

## CLI (`rslbp`)

The [`rslbp` noun-verb CLI](EXAMPLECLI.md) demonstrates every command-line
convention baked into the blueprint: stackable global flags, `table|json|markdown|name`
output rendering, 6-rung TOML configuration, strict secret isolation, structured
redacting logs, interactive prompts, pager/clipboard integration, and the stable
`RSLB###` error and exit-code contract.

```bash
cargo run --bin rslbp -- --help
cargo run --bin rslbp -- diagnostics --json
cargo run --bin rslbp -- config init --dry-run --yes
```

## Optional Web Service (`rslbp-serve`)

Enable the off-by-default `web` feature to build and run the Axum REST service
over the same synchronous `crates/core` domain layer. See [EXAMPLEWEB.md](EXAMPLEWEB.md)
for the complete walkthrough (endpoints, `RSLBP_WEB_*` environment variables,
RFC 9457 error envelope, OpenAPI contract pipeline, and observability).

```bash
just serve                      # Auto-reloading dev loop via bacon (or `just serve-once`)
just check-openapi              # Verify zero drift against openapi/openapi.json
just docker-web                 # Build local multi-stage distroless container image
```

Stable GitHub releases publish `linux/amd64` container images to
`ghcr.io/smorinlabs/rs-launch-blueprint` (see [docs/RELEASE.md](docs/RELEASE.md)
for public-package visibility setup):

```bash
docker pull --platform linux/amd64 ghcr.io/smorinlabs/rs-launch-blueprint:latest
docker run --rm --platform linux/amd64 -p 127.0.0.1:8000:8000 \
  ghcr.io/smorinlabs/rs-launch-blueprint:latest
curl -s http://127.0.0.1:8000/healthz
```

## Opt-In Local Acceleration (`Blaze` & `bacon`)

The repository ships opt-in [`indexable-inc/blaze`](https://github.com/indexable-inc/blaze)
recipes (`just blaze-check`, `just blaze-test`, `just blaze-run`, `just blaze-status`,
`just install-blaze`) with automatic Cargo fallback when `blaze` is absent, plus
[`bacon`](https://dystroy.org/bacon/) live-reload (`bacon.toml`, `just serve`)
for `crates/web` and clippy edit loops.

- **Cargo remains sole authority** for CI, MSRV (`rust-version`), `clippy`,
  `rustfmt`, `cargo-deny`, coverage, packaging, and releases.
- **Live compatibility:** run `just blaze-status` to inspect your installed
  Blaze version and live probes (currently `blaze test -p rs-launch-blueprint-core`
  and `blaze build -p rs-launch-blueprint --bin rslbp` accelerate the core/CLI loop,
  while `crates/web` and `--features` stay on Cargo/bacon). See
  [Blaze Local Accelerator](docs/tools/blaze.md) for details.

## Starting a New Project from This Template

If you use Claude Code, Codex, or another agent that reads [AGENTS.md](AGENTS.md),
ask it to _"create a new Rust project from rs-launch-blueprint"_ — the
[`new-rust-project`](.claude/skills/new-rust-project/SKILL.md) skill walks
through `gh repo create --template`, identity collection, `press clean`,
`press rebrand --dry-run`, `press rebrand`, `press verify`, and full verification.
Humans can follow the same file as a copy-pasteable runbook, then complete the
one-time repository settings in [docs/PROJECT_SETUP.md](docs/PROJECT_SETUP.md).

## Documentation

Browse the complete in-repository documentation starting at
[docs/README.md](docs/README.md), or read the published site at
[smorinlabs.github.io/rs-launch-blueprint](https://smorinlabs.github.io/rs-launch-blueprint/).

## License

Dual-licensed under either **Apache License, Version 2.0** ([LICENSE](LICENSE))
or **MIT License** ([LICENSE-MIT](LICENSE-MIT)), at your option.
