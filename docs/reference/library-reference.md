# Standalone Library Reference (`rs-launch-blueprint`)

`rs-launch-blueprint` (Rust target `rs_launch_blueprint`) is a **standalone, runtime-agnostic
Rust library crate** (`[lib]`-only) published independently of the `rslbp` CLI (`crates/cli`)
and the optional `rslbp-serve` web service (`crates/web`).

It carries **zero** CLI frameworks, terminal UI libraries, HTTP servers, async runtimes,
`anyhow`, OpenTelemetry crates, or global `tracing-subscriber` initialization (`OV-18`).

## Adding the Library

Default features (`http` + `config`):

```bash
cargo add rs-launch-blueprint
```

Minimal domain-only footprint (no HTTP client, no TOML/XDG config crates):

```bash
cargo add rs-launch-blueprint --no-default-features
```

Select individual features explicitly:

```toml
[dependencies]
rs-launch-blueprint = { version = "0.1", default-features = false, features = ["http"] }
```

## Cargo Feature Matrix

Measured unique normal dependency counts (`cargo tree -e normal --prefix none`):

| Crate & Feature Configuration                     | Normal Crates | Included Capabilities                                                                                                                                                                                 |
| ------------------------------------------------- | ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `rs-launch-blueprint --no-default-features`       | **17**        | Domain models (`Project`, `ProjectQuery`), `ProjectsPort`, `ProjectsService`, `InMemoryProjectsPort`, `RecordingPort`, `ErrorCode`, `DomainError`, `Token`, `InMemoryCredentialStore`, `Diagnostics`. |
| `rs-launch-blueprint` (default: `http`, `config`) | **56**        | Adds synchronous `HttpProjectsPort` (`ureq`, `HeaderInjector`), XDG `Paths`, layered TOML config (`load_config`, `set_config_value`), `FileCredentialStore`.                                          |
| `rs-launch-blueprint --features mock`             | —             | Enables `mockall::automock` (`MockProjectsPort`) for unit tests (opt-in dev/test).                                                                                                                    |
| `rs-launch-blueprint --features keychain`         | —             | Enables `KeychainCredentialStore` backed by the OS native keyring (`keyring-core`).                                                                                                                   |
| `rs-launch-blueprint --all-features`              | **74**        | `http`, `config`, `mock`, and `keychain` (still zero CLI, web, Tokio, or OTel).                                                                                                                       |
| `rs-launch-blueprint-core --no-default-features`  | **16**        | Pure domain models, ports, errors, and secrets directly from the core crate.                                                                                                                          |

## Quick Usage Examples

### Minimal In-Memory Domain Service (`--no-default-features`)

```rust
use rs_launch_blueprint::{
    CreateProjectInput, ErrorCode, ProjectQuery, in_memory_service,
};

let service = in_memory_service([]);
let created = service.create_project(&CreateProjectInput {
    name: "Core Library".to_owned(),
    workspace: Some("platform".to_owned()),
})?;

let all = service.list_projects(&ProjectQuery::default())?;
assert_eq!(all.len(), 1);
assert_eq!(all[0].id, created.id);

let err = service.get_project("missing").unwrap_err();
assert_eq!(err.error_code(), ErrorCode::NotFound);
```

### Synchronous HTTP Client & Custom Header Injection (`http` feature)

`HttpProjectsPort` uses a shared synchronous `ureq::Agent` and maps HTTP `404` on by-id reads
to `Ok(None)` (`R03`, `R05`). Callers that want distributed trace propagation (such as W3C
`traceparent`) or tenant headers can attach a [`HeaderInjector`] callback without coupling the
library to OpenTelemetry:

```rust
use std::sync::Arc;
use rs_launch_blueprint::{HttpProjectsPort, ProjectsService, Token};

let port = HttpProjectsPort::new("https://api.example.com", Token::new("sk_live_..."))
    .with_header_injector(Arc::new(|| {
        vec![("x-request-source".to_owned(), "my-service".to_owned())]
    }));
let service = ProjectsService::new(port);
```

### Layered Configuration & Secret Policy (`config` feature)

- `Paths::resolve()` computes XDG `config`, `data`, `state`, and `cache` directories without
  touching the filesystem (`R57`).
- `load_config(&ConfigDiscoveryInputs { ... })` merges system, user, and ancestor project TOML
  layers recursively with provenance-aware tolerance (`R54`, `R55`).
- `set_config_value(path, key, value)` performs comment-preserving atomic `0600` TOML updates
  while refusing secret keys (`ErrorCode::ProhibitedSecretChannel`, `R52`, `R56`).
- `FileCredentialStore` and `resolve_token(&TokenResolutionInputs { ... })` isolate credentials
  in `0600` storage wrapped in `secrecy::SecretString` / `zeroize` (`R56`).

## Stability, SemVer & Public API Guarantees (`R04`, `OV-18`)

- **Curated facade (`src/lib.rs`):** All internal modules are private and explicitly re-exported
  at the crate root. `unreachable_pub`, `private_interfaces`, `private_bounds`, and
  `missing_docs` are compile-time errors (`deny`).
- **Safe-code guarantee (`R06`):** `unsafe_code = "forbid"` is enforced workspace-wide.
- **No subscriber hijacking (`R58`):** The library emits `tracing` spans/events only and never
  installs a global subscriber or depends on `tracing-subscriber`.
- **No process termination (`R67`):** The library returns typed `thiserror` errors
  (`DomainError`, `PortError`, `ConfigError`, `AuthError`) carrying append-only `ErrorCode`
  tokens (`RSLB000`–`RSLB903`) and never calls `std::process::exit`.
- **Automated API & consumer verification:**
  - `cargo-semver-checks` guards both `rs-launch-blueprint-core` and `rs-launch-blueprint` on
    pull requests (`ci.yml`) and release tags (`publish.yml`).
  - `just lib-check` (and CI `install-smoke`) packs the `.crate` archives, unpacks them outside
    the repository, and compiles/runs downstream consumers with default features,
    `default-features = false`, and a negative private-module visibility check.
  - Both published library crates declare `[package.metadata.docs.rs] all-features = true` so
    docs.rs renders the complete feature-annotated API reference.
