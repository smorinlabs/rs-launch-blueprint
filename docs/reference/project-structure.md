# Project Structure

This reference maps the top-level layout of `rs-launch-blueprint` and explains
the ownership boundary of every directory and configuration file under the
library-first workspace topology ([ADR 0001 / `OV-18`](../adr/0001-library-first-workspace-topology.md)).

## Workspace Crates

```text
Cargo.toml                  # Workspace root + standalone `[lib]`-only crate (`rs-launch-blueprint`)
Cargo.lock                  # Committed lockfile synchronized across all 4 packages
clippy.toml                 # Root library disallowed APIs (zero CLI/web/process exit)
src/
  lib.rs                    # Curated public library barrel (`pub use`, R04)
  composition.rs            # Pure library composition helpers (`in_memory_service`, `production_service`)
  http_adapter.rs           # Synchronous `ureq` adapter (`HttpProjectsPort`, `HeaderInjector`, opt `http`)
  keychain.rs               # Optional OS keychain credential store (`--features keychain`, R56)
  internal.rs               # Private internal helpers verified unreachable by compile_fail doctests
crates/
  core/                     # `rs-launch-blueprint-core`: sync domain models, ports, config (opt), secrets, errors
    README.md               # Crates.io package README
    LICENSE / LICENSE-MIT   # Packed dual-license copies (parity-checked with root)
    clippy.toml             # Disallowed APIs preventing env/process/CLI/web bleed in core (R02)
  cli/                      # `rs-launch-blueprint-cli`: `[[bin]] rslbp`, clap, output, color, pager, prompter,
                            #   clipboard (`arboard`), `Exit`, `FileCrashSink`, CLI telemetry + rotating file sink
    README.md               # Crates.io package README
    LICENSE / LICENSE-MIT   # Packed dual-license copies (parity-checked with root)
    clippy.toml             # CLI-crate Clippy configuration
    build.rs                # Dependency-free compile-time target & rustc metadata (R60)
  web/                      # `rs-launch-blueprint-web` (`publish = false`): `[[bin]] rslbp-serve`, Axum router,
                            #   RFC 9457, OpenAPI, middleware, `IdempotencyStore`, service telemetry, `metrics`, `otel`
    clippy.toml             # Web-crate Clippy configuration
```

## Tests & Contract Suites

```text
tests/
  workspace_edges.rs        # Crate DAG, allow-lists, source leak scans, license parity, R02/R06/OV-18 guards
  ports_contract.rs         # Port substitutability contract tests (fake vs. adapter parity)
  http_adapter_boundary.rs  # `httpmock` boundary + `HeaderInjector` suite for `HttpProjectsPort`
  config_and_secrets_contract.rs  # R52–R57 config discovery, validation, and secret isolation
  error_contract.rs         # R67 transport-neutral append-only `ErrorCode::ALL` and library error hints
  properties.rs             # `proptest` generative invariant suite for library models & config (R33)
  justfile_contract.rs      # R42 invocation discipline, `lib-check`, and Blaze fallback contract
  repo_hygiene.rs           # R29/R31/R37–R40/R43/R44 config consistency meta-tests
  workflows_contract.rs     # R08/R09/R11/R12/R13/R16–R20/R34/R86 workflow meta-tests
  release_contract.rs       # R22–R26/R50/R68/1a-A release and packaging contract tests
  community_contract.rs     # R45–R47 community files, PR template, and setup docs tests
  press_source.rs           # R15 `press-source.toml` <-> `cargo metadata` lockstep test
  docs_contract.rs          # R81/R82 mdBook, `SUMMARY.md`, dialect, and `lychee` contract tests
crates/cli/tests/           # CLI contract tests (`cli/`, `contracts.rs`, `help_snapshots.rs`, `telemetry_contract.rs`)
crates/web/tests/           # Web integration, OpenAPI snapshot, R83 fuzzing, `web_serve_contract.rs`, `otel_contract.rs`, `telemetry_contract.rs`
```

## Tooling, Security, Packaging & Docs Configuration

| File / Directory                                                           | Role                                                                                               |
| -------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `Makefile` / `Justfile`                                                    | Level 1 bootstrap (`rustup` + `just`) and Level 2 task runner (`R42`).                             |
| `rust-toolchain.toml`                                                      | Pinned Rust development toolchain (`channel`, `minimal`, `rustfmt`, `clippy`).                     |
| `rustfmt.toml`, `clippy.toml`, `deny.toml`                                 | Rust formatting, linting, and dependency-policy configs (`R27`, `R28`, `R02`, `OV-18`).            |
| `dprint.json`, `sgconfig.yml`, `rules/`                                    | Non-code Wasm formatter (`R29`) and `ast-grep` security rules (`R31`).                             |
| `lefthook.yml`, `committed*.toml`, `.gitmessage`                           | Git hooks and Conventional Commits configs (`R37`, `R38`).                                         |
| `.gitleaks.toml`, `.editorconfig`, `.yamllint`, `typos.toml`, `zizmor.yml` | Hygiene & security baselines (`R39`, `R40`, `R20`).                                                |
| `.config/nextest.toml`, `.cargo/audit.toml`, `bacon.toml`                  | Test runner, RustSec, and dev-watcher configs (`R32`, `R13`, `R69`).                               |
| `openapi/`, `openapi-to-rust.toml`, `Dockerfile`, `.dockerignore`          | Web OpenAPI contract, client gen, and container build (`R71`, `R84`, `R51`).                       |
| `release-please-config.json`, `dist-workspace.toml`, `ci/`                 | Automated releases, `cargo-dist`, and R26 packed-artifact baselines.                               |
| `press/`, `.claude/`, `.agents/`                                           | Template Press rules/stubs, canonical AI config (`AGENTS.md`), and bootstrap skill (`R15`, `R43`). |
| `book.toml`, `lychee.toml`, `docs/`                                        | mdBook 0.5.4 site config, `lychee` link-check config, and documentation corpus (`R81`, `R82`).     |
