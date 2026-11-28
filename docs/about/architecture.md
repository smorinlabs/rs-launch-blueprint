# Workspace Architecture

`rs-launch-blueprint` implements a **hexagonal (ports-and-adapters)
architecture** enforced at compile time by a four-package Cargo workspace
(`R01`–`R06`, `OV-03`).

## Package Topology

```text
+--------------------------------------+
|    rs-launch-blueprint (root crate)  |
|  src/lib.rs · src/composition.rs     |
|  src/http_adapter.rs · telemetry.rs  |
|  [[bin]] rslbp · [[bin]] rslbp-serve |
+--------+----------+---------+--------+
         |          |         | (optional: --features web)
         v          v         v
+--------+--+  +----+----+  +-+--------+
| crates/cli|  |crates/  |  |crates/web|
| (rslbp    |  |  core   |  | (axum /  |
|  frontend)|  |(domain) |  |  tokio)  |
+-----+-----+  +---------+  +----+-----+
      |              ^           |
      +--------------+-----------+
```

Every arrow is a legal Cargo dependency; every forbidden direction is physically
impossible to compile:

- **`crates/core` (`rs-launch-blueprint-core`):** pure synchronous domain models
  (`Project`, `CreateProjectInput`, `ProjectQuery`), driven port trait
  (`ProjectsPort: Send + Sync`), generic application service
  (`ProjectsService<P>`), shipped `InMemoryProjectsPort` and `RecordingPort<P>`,
  XDG `Paths`, layered TOML config, secret policy, diagnostics, idempotency
  store, and the `RSLB###` error/exit taxonomy. Depends on **no** CLI framework,
  HTTP server, async runtime, or `tracing-subscriber`.
- **`crates/cli` (`rs-launch-blueprint-cli`):** thin CLI presentation crate
  (`clap`, `tabled`, `inquire`, `indicatif`, `anstream`, `shlex`). Depends only
  on `crates/core` — never on `crates/web` or the root composition root.
- **`crates/web` (`rs-launch-blueprint-web`):** optional Axum + Tokio HTTP
  adapter compiled only when the root package enables `--features web` (or
  `--all-features`). Depends only on `crates/core` — never on `crates/cli`.
- **Root facade (`rs-launch-blueprint`, `src/`):** wires concrete adapters
  (`UreqProjectsAdapter`, `ArboardClipboard`, `KeychainCredentialStore`),
  initializes the single `tracing-subscriber` telemetry pipeline, re-exports the
  curated public library API in `src/lib.rs`, and hosts both `[[bin]] rslbp` and
  the feature-gated `[[bin]] rslbp-serve`.

## Driven-I/O Seam (`R01`, `R03`, `R05`)

1. **Dyn-compatible synchronous port:** `pub trait ProjectsPort: Send + Sync`
   exposes synchronous methods returning `Result<T, PortError>` or
   `Result<Option<T>, PortError>` with a blanket `impl<T: ProjectsPort + ?Sized> ProjectsPort for Arc<T>`.
2. **Absence vs. failure separation (`R03`):** `PortError` deliberately has no
   `NotFound` variant. HTTP `404` maps to `Ok(None)` in `UreqProjectsAdapter`,
   and `ProjectsService` translates `None` into `DomainError::NotFound`
   (`RSLB301`, CLI exit `3`, HTTP `404`).
3. **Sync core, async web (`R05`):** default builds pull zero async runtime
   crates (~38 dependencies). When `--features web` is enabled, Axum handlers
   invoke the synchronous `Arc<ErasedProjectsService>` inside
   `tokio::task::spawn_blocking`, preserving the current `tracing::Span`.

## Mechanical Boundary Enforcement (`R02`, `R04`, `R06`)

Architectural rules are enforced by tools rather than prose:

- **Cargo DAG + `deny.toml`:** `cargo deny --all-features check` blocks
  forbidden crates (`tokio`, `axum`, `clap`, `tracing-subscriber`, `anyhow`)
  from entering `crates/core`, `crates/cli`, or `crates/web` outside declared
  wrappers.
- **Fast local bleed guard:** `crates/core/clippy.toml` bans `std::env::var`,
  `std::process::exit`, and stdout/stderr printing macros inside domain code
  (`disallowed_methods = "deny"`).
- **Curated public API (`R04`):** root `Cargo.toml` denies `unreachable_pub`,
  `private_interfaces`, `private_bounds`, and `missing_docs`, backed by
  `compile_fail` doctests and `cargo-semver-checks` on release.
- **Safe-code floor (`R06`):** `[workspace.lints.rust] unsafe_code = "forbid"`
  is inherited by every crate via `[lints] workspace = true`.
- **Contract tests:** `tests/workspace_edges.rs`, `tests/ports_contract.rs`, and
  `tests/http_adapter_boundary.rs` assert these invariants on every test run.
