# Workspace Architecture

`rs-launch-blueprint` implements a **library-first hexagonal (ports-and-adapters)
architecture** enforced at compile time by a four-package Cargo workspace
(`R01`–`R06`, [ADR 0001 / `OV-18`](../adr/0001-library-first-workspace-topology.md)).

## Package Topology

```text
+--------------------+          +--------------------+
|     crates/cli     |          |     crates/web     |
| rs-launch-blueprint|          | rs-launch-blueprint|
|       -cli         |          |  -web (publish=no) |
| [[bin]] rslbp      |          | [[bin]] rslbp-serve|
| clap · clipboard   |          | axum · tokio       |
| crash_sink · logs  |          | idempotency · otel |
+---------+----------+          +---------+----------+
          |                               |
          +---------------+---------------+
                          v
        +-----------------------------------+
        |  rs-launch-blueprint (root [lib]) |
        |  src/lib.rs · src/composition.rs  |
        |  src/http_adapter.rs (opt: http)  |
        |  src/keychain.rs (opt: keychain)  |
        |  ZERO CLI, web, Tokio, or OTel    |
        +-----------------+-----------------+
                          |
                          v
        +-----------------------------------+
        |   crates/core (pure sync domain)  |
        |   rs-launch-blueprint-core        |
        |   ProjectsPort · ProjectsService  |
        |   ErrorCode · Token · Diagnostics |
        |   Paths & TOML config (opt:config)|
        +-----------------------------------+
```

Every arrow is a legal Cargo dependency; every forbidden direction is physically
impossible to compile:

- **`crates/core` (`rs-launch-blueprint-core`):** pure synchronous domain models
  (`Project`, `CreateProjectInput`, `ProjectQuery`), driven port trait
  (`ProjectsPort: Send + Sync`), generic application service
  (`ProjectsService<P>`), shipped `InMemoryProjectsPort` and `RecordingPort<P>`,
  `Token` / `CredentialStore`, `Diagnostics`, optional `config` feature (XDG
  `Paths`, layered TOML config, `FileCredentialStore`), and the transport-neutral
  `RSLB###` error catalog. Depends on **no** CLI framework, HTTP client or server,
  async runtime, clipboard, idempotency store, or `tracing-subscriber`.
- **Root standalone library (`rs-launch-blueprint`, `src/`):** `[lib]`-only crate
  published on crates.io (`default = ["http", "config"]`, optional `mock` and
  `keychain`). Wires synchronous `HttpProjectsPort` (`ureq` with caller-supplied
  `HeaderInjector` hook) and optional `KeychainCredentialStore`, and re-exports the
  curated public API in `src/lib.rs`. Carries **17** unique normal crates with
  `--no-default-features` and **56** with defaults (`74` with `--all-features`).
- **`crates/cli` (`rs-launch-blueprint-cli`):** published CLI crate owning
  `[[bin]] rslbp`, `Exit`, `clap` grammar, output renderers, color, pager,
  prompter, spinner, `ClipboardPort`/`ArboardClipboard`, `FileCrashSink`, and CLI
  `tracing-subscriber` + rotating file sink. Depends on `rs-launch-blueprint` —
  never on `crates/web`.
- **`crates/web` (`rs-launch-blueprint-web`, `publish = false`):** internal Axum
  - Tokio HTTP service owning `[[bin]] rslbp-serve`, RFC 9457 error responses,
    OpenAPI 3.1 (`utoipa`), `IdempotencyStore`, rate limiting, service telemetry,
    and optional `metrics` / `otel` features (injecting W3C `traceparent` into
    `HttpProjectsPort::with_header_injector`). Depends on `rs-launch-blueprint` —
    never on `crates/cli`.

## Driven-I/O Seam (`R01`, `R03`, `R05`)

1. **Dyn-compatible synchronous port:** `pub trait ProjectsPort: Send + Sync`
   exposes synchronous methods returning `Result<T, PortError>` or
   `Result<Option<T>, PortError>` with a blanket `impl<T: ProjectsPort + ?Sized> ProjectsPort for Arc<T>`.
2. **Absence vs. failure separation (`R03`):** `PortError` deliberately has no
   `NotFound` variant. HTTP `404` maps to `Ok(None)` in `HttpProjectsPort`,
   and `ProjectsService` translates `None` into `DomainError::NotFound`
   (`RSLB301`, CLI exit `3`, HTTP `404`).
3. **Sync library & CLI, async web (`R05`, `OV-18`):** `rs-launch-blueprint` pulls
   zero async runtime crates (**17** normal crates minimal, **56** default).
   Inside `crates/web`, Axum handlers invoke the synchronous
   `Arc<ErasedProjectsService>` inside `tokio::task::spawn_blocking`, preserving
   the active `tracing::Span`.

## Mechanical Boundary Enforcement (`R02`, `R04`, `R06`, `OV-18`)

Architectural rules are enforced by tools rather than prose:

- **Cargo DAG + `deny.toml`:** `cargo deny --workspace --all-features check`
  blocks CLI, web, and observability crates (`axum`, `tokio`, `tower-http`,
  `problem_details`, `utoipa`, `clap`, `inquire`, `indicatif`, `tabled`,
  `arboard`, `signal-hook`, `tracing-subscriber`, `anyhow`, `opentelemetry`)
  from entering `crates/core` or the standalone root library.
- **Per-crate `clippy.toml`:** root `clippy.toml` and `crates/core/clippy.toml`
  ban `std::process::exit`, `anyhow::Error`, `axum::Router`, `clap::Command`,
  and `tracing_subscriber::Registry` (`disallowed_methods` / `disallowed_types`).
- **Curated public API (`R04`):** root `Cargo.toml` denies `unreachable_pub`,
  `private_interfaces`, `private_bounds`, and `missing_docs`, backed by
  `compile_fail` doctests, `just lib-check`, and `cargo-semver-checks` on both
  `rs-launch-blueprint-core` and `rs-launch-blueprint` in PR CI and release publish.
- **Safe-code floor (`R06`):** `[workspace.lints.rust] unsafe_code = "forbid"`
  is inherited by every crate via `[lints] workspace = true`.
- **Contract tests:** `tests/workspace_edges.rs`, `tests/ports_contract.rs`, and
  `tests/http_adapter_boundary.rs` assert DAG topology, dependency allow-lists,
  source leak scans, `[lib]`-only root targets, and license parity on every test run.
