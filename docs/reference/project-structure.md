# Project Structure

This reference maps the top-level layout of `rs-launch-blueprint` and explains
the ownership boundary of every directory and configuration file.

## Workspace Crates

```text
Cargo.toml                  # Workspace root + root facade crate (`rs-launch-blueprint`)
Cargo.lock                  # Committed lockfile synchronized across all 4 packages
src/
  lib.rs                    # Curated public library barrel (`pub use`, R04)
  main.rs                   # `rslbp` CLI binary entrypoint (R49, R60, R67)
  bin/serve.rs              # Feature-gated `rslbp-serve` web binary (`--features web`, R69)
  composition.rs            # Composition root wiring concrete adapters to core ports (R01)
  http_adapter.rs           # Synchronous `ureq` adapter implementing `ProjectsPort` (R05)
  clipboard_adapter.rs      # `arboard` adapter + Linux selection daemon (R62)
  keychain.rs               # Optional OS keychain credential store (`--features keychain`, R56)
  telemetry.rs              # `tracing-subscriber` init, redacting formatters, file sink (R58, R59)
  otel.rs                   # Optional OpenTelemetry OTLP exporter (`--features otel`, R78)
  crash_sink.rs             # `0600` NDJSON unexpected-error crash sink (R67)
  internal.rs               # Private internal helpers verified unreachable by compile_fail doctests
crates/
  core/                     # `rs-launch-blueprint-core`: sync domain models, ports, config, secrets, errors
    clippy.toml             # Disallowed APIs preventing env/process/stdout bleed in core (R02)
  cli/                      # `rs-launch-blueprint-cli`: clap grammar, output, color, pager, prompter, rich rows
    build.rs                # Dependency-free compile-time target & rustc metadata (R60)
  web/                      # `rs-launch-blueprint-web`: optional Axum router, RFC 9457, OpenAPI, middleware
```

## Tests & Contract Suites

```text
tests/
  cli/                      # Built-binary CLI tests (`assert_cmd`, `predicates`, `insta` snapshots)
  workspace_edges.rs        # Crate DAG, `deny.toml`, and R02/R06 boundary verification
  ports_contract.rs         # Port substitutability contract tests (fake vs. adapter parity)
  http_adapter_boundary.rs  # `httpmock` boundary suite for `UreqProjectsAdapter`
  config_and_secrets_contract.rs  # R52–R57 config discovery, validation, and secret isolation
  error_contract.rs         # R67 append-only `ErrorCode::ALL`, exit mapping, crash sink
  telemetry_contract.rs     # R58–R59 redaction, reloadable levels, CLI/Service profiles, rotation
  web_serve_contract.rs     # R69 `rslbp-serve` binary flags, signals, and drain exits
  otel_contract.rs          # R78 OTel enabled/disabled paths and `trace_id` correlation
  properties.rs             # `proptest` generative invariant suite (R33)
  justfile_contract.rs      # R42 invocation discipline and Blaze fallback contract
  repo_hygiene.rs           # R29/R31/R37–R40/R43/R44 config consistency meta-tests
  workflows_contract.rs     # R08/R09/R11/R12/R13/R16–R20/R34/R86 workflow meta-tests
  release_contract.rs       # R22–R26/R50/R68/1a-A release and packaging contract tests
  community_contract.rs     # R45–R47 community files, PR template, and setup docs tests
  press_source.rs           # R15 `press-source.toml` <-> `cargo metadata` lockstep test
  docs_contract.rs          # R81/R82 mdBook, `SUMMARY.md`, dialect, and `lychee` contract tests
crates/web/tests/           # Optional web integration, OpenAPI snapshot, and R83 fuzzing tests
```

## Tooling, Security, Packaging & Docs Configuration

| File / Directory                                                           | Role                                                                                               |
| -------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `Makefile` / `Justfile`                                                    | Level 1 bootstrap (`rustup` + `just`) and Level 2 task runner (`R42`).                             |
| `rust-toolchain.toml`                                                      | Pinned Rust development toolchain (`channel`, `minimal`, `rustfmt`, `clippy`).                     |
| `rustfmt.toml`, `clippy.toml`, `deny.toml`                                 | Rust formatting, linting, and dependency-policy configs (`R27`, `R28`, `R02`).                     |
| `dprint.json`, `sgconfig.yml`, `rules/`                                    | Non-code Wasm formatter (`R29`) and `ast-grep` security rules (`R31`).                             |
| `lefthook.yml`, `committed*.toml`, `.gitmessage`                           | Git hooks and Conventional Commits configs (`R37`, `R38`).                                         |
| `.gitleaks.toml`, `.editorconfig`, `.yamllint`, `typos.toml`, `zizmor.yml` | Hygiene & security baselines (`R39`, `R40`, `R20`).                                                |
| `.config/nextest.toml`, `.cargo/audit.toml`, `bacon.toml`                  | Test runner, RustSec, and dev-watcher configs (`R32`, `R13`, `R69`).                               |
| `openapi/`, `openapi-to-rust.toml`, `Dockerfile`, `.dockerignore`          | Web OpenAPI contract, client gen, and container build (`R71`, `R84`, `R51`).                       |
| `release-please-config.json`, `dist-workspace.toml`, `ci/`                 | Automated releases, `cargo-dist`, and R26 packed-artifact baselines.                               |
| `press/`, `.claude/`, `.agents/`                                           | Template Press rules/stubs, canonical AI config (`AGENTS.md`), and bootstrap skill (`R15`, `R43`). |
| `book.toml`, `lychee.toml`, `docs/`                                        | mdBook 0.5.4 site config, `lychee` link-check config, and documentation corpus (`R81`, `R82`).     |
