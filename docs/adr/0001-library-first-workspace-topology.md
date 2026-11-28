# ADR 0001 — Library-First Workspace Topology (`OVERRIDE (OV-18)`)

- **Status:** Accepted
- **Date:** 2026-11-28
- **Related:** [Workspace Architecture](../about/architecture.md), [Design Decisions](../about/design-decisions.md), [Library Reference](../reference/library-reference.md)

## Context

In the initial P04–P13 port of `rs-launch-blueprint` (`R02` / `OV-03`, `R49`, `R69`), the root
package `rs-launch-blueprint` combined three responsibilities into a single Cargo manifest:

1. The public Rust library facade (`src/lib.rs`).
2. The `rslbp` CLI binary (`src/main.rs`) with an unconditional normal dependency on
   `crates/cli` (`clap`, `inquire`, `indicatif`, `tabled`, `anstream`, `shlex`), plus `arboard`,
   `anyhow`, `signal-hook`, and `tracing-subscriber`.
3. The optional `rslbp-serve` web binary (`src/bin/serve.rs`) gated behind `--features web`
   plus `metrics` and `otel` features.

Because Cargo resolves all non-optional `[dependencies]` of a package regardless of whether a
downstream caller only imports its `[lib]`, any Rust library consumer running
`cargo add rs-launch-blueprint` inherited **160** transitive normal dependencies (and **150** even
with `default-features = false`), including `clap`, `inquire`, `indicatif`, `tabled`, `arboard`,
`anyhow`, `signal-hook`, and `tracing-subscriber`. In addition, CLI and web concepts (POSIX
`Exit`, `ClipboardPort`, `IdempotencyStore`, `ServiceLogFormat`, `WorkspaceInfo::web_enabled`,
and CLI flag hints) had leaked into `crates/core`.

Rust ecosystem best practice (for example `ripgrep` / `grep-*`, `ruff`, `uv`, `cargo-nextest`,
and `insta`) expects the primary library crate to carry zero binary, terminal, HTTP-server, or
global-subscriber dependencies so downstream crates can depend on it cleanly.

## Decision

Record **`OVERRIDE (OV-18)`** superseding the root-binary-host part of `R02` / `OV-03`, `R49`,
`R58`, `R62`, `R67`, `R69`, `R73`, and `R78` with a **Library-First Workspace Topology**:

**Argument:** Downstream Rust consumers expect `cargo add rs-launch-blueprint` to provide a
clean, standalone, runtime-agnostic library without pulling terminal UI crates, `clap`,
`anyhow`, `tracing-subscriber`, or web-server plumbing. Making the root package `[lib]`-only
and moving binary entrypoints and front-end adapters into `crates/cli` and `crates/web` drops
minimal library transitive dependencies from **150 to 17 (-89%)** and default library
dependencies from **160 to 56 (-65%)**, while preserving every CLI, web, OTel, container,
release, and Template Press capability intact.

**Options:**

- **Option A1 (Chosen — Library-First Root Crate):** Root `rs-launch-blueprint` is `[lib]`-only
  (`default = ["http", "config"]`, optional `mock` and `keychain`) and depends only on
  `crates/core`. `crates/cli` (`rs-launch-blueprint-cli`) depends on the root library and owns
  `[[bin]] rslbp`, `Exit`, `ClipboardPort`/`ArboardClipboard`, `FileCrashSink`, and CLI
  telemetry/rotating logs. `crates/web` (`rs-launch-blueprint-web`, `publish = false`) depends
  on the root library and owns `[[bin]] rslbp-serve`, `IdempotencyStore`, `ServiceLogFormat`,
  service telemetry, and optional `metrics` / `otel` (wiring W3C `traceparent` into
  `HttpProjectsPort::with_header_injector`).
- **Option A2 (Rejected — Separate `crates/sdk` Library Crate):** Keeps `[[bin]] rslbp` in the
  root package and publishes the library under a secondary name (`rs-launch-blueprint-sdk`).
  Rejected because `cargo add <repo_name>` would still pull CLI crates and surprise library
  callers.
- **Option B (Rejected — Keep Root Hybrid Crate with Optional `cli` Feature):** Marks `crates/cli`
  and `rslbp` as `required-features = ["cli"]` enabled by default. Rejected because
  `cargo add rs-launch-blueprint` still activates `default = ["cli"]` unless every caller passes
  `--no-default-features`, and `cargo install` breaks if `cli` is not in `default`.

### Mechanical Enforcement

1. **Cargo DAG:** `crates/core` -> `rs-launch-blueprint` (root `[lib]`) <- `crates/cli` and
   `crates/web`. Root `[workspace] default-members = [".", "crates/core", "crates/cli"]` keeps
   `cargo run --bin rslbp` working from the workspace root.
2. **`deny.toml` (`cargo deny --workspace --all-features check`):** Bans `axum`, `tokio`,
   `tower-http`, `problem_details`, `utoipa`, `clap`, `clap_complete`, `inquire`, `indicatif`,
   `tabled`, `arboard`, `signal-hook`, `tracing-subscriber`, `anyhow`, and `opentelemetry`
   outside their authorized front-end crates.
3. **Per-crate `clippy.toml`:** Root `clippy.toml` and `crates/core/clippy.toml` ban
   `std::process::exit`, `anyhow::Error`, `axum::Router`, `clap::Command`, and
   `tracing_subscriber::Registry`.
4. **Contract tests (`tests/workspace_edges.rs`):** Enforce exact DAG edges, root normal
   dependency allow-list, `cargo tree` zero-CLI/web checks across `--no-default-features` /
   default / `--all-features`, source scans over `crates/core/src/` and `src/`, `[lib]`-only
   root metadata, `crates/web` `publish = false`, and license-file parity across published
   crates.
5. **Downstream consumer smoke (`just lib-check` + CI `install-smoke`) & SemVer (`ci.yml` +
   `publish.yml`):** Unpacks packed `.crate` archives outside the workspace and verifies both
   default and `--no-default-features` external consumers plus private-module compile failure,
   while `cargo-semver-checks` verifies both `rs-launch-blueprint-core` and
   `rs-launch-blueprint` on PRs and release tags.

## Consequences

- **Positive:**
  - Measured normal dependency count for `rs-launch-blueprint`: **17** with
    `--no-default-features`, **56** with default (`http`, `config`), **74** with
    `--all-features` (down from 150 / 160 / 214+).
  - Every published crate (`rs-launch-blueprint-core`, `rs-launch-blueprint`,
    `rs-launch-blueprint-cli`) ships complete crates.io metadata (`README.md`, `LICENSE`,
    `LICENSE-MIT`, `keywords`, `categories`, `homepage`, `[package.metadata.docs.rs]`).
  - Downstream projects that want a **library-only** repository can drop `crates/cli` and/or
    `crates/web` cleanly without touching `src/` or `crates/core/`.
- **Trade-offs / Risks:**
  - `cargo install --locked` and `cargo binstall` target `rs-launch-blueprint-cli` rather than
    the root library crate name (documented across `README.md` and `docs/RELEASE.md`).
  - `crates/web` is marked `publish = false` and distributed as a GHCR container image rather
    than published to crates.io; teams wanting a reusable web router crate can flip
    `publish = true` and add its `ci/expected-packed-*` baseline.
