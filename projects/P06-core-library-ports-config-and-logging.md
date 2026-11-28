# P06 — Core library ports config and logging

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
- **Spec:** [RS implementation roadmap design](../docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md)
- **Plan:** [Rex serial chain contract](../docs/superpowers/plans/2026-11-27-rex-serial-chain-contract.md)
- **Depends on:** P05
- **Prior art:** [R01 ports-and-adapters-seam](../research/topics/01-ports-and-adapters-seam/DECISION.md)
- **Prior art:** [R54 config-discovery-tiers](../research/topics/54-config-discovery-tiers/DECISION.md)
- **Prior art:** [R58 logging-pipeline-architecture](../research/topics/58-logging-pipeline-architecture/DECISION.md)
- **Prior art:** [R67 error-and-exit-code-contract](../research/topics/67-error-and-exit-code-contract/DECISION.md)

**Status:** `[x]` completed (2026-11-27).

### Scope
Implement `crates/core` and the root facade's composition/adapter/telemetry modules with full unit and contract test coverage:
- Domain models, dyn-compatible sync `pub trait ProjectsPort: Send + Sync` (`R01`, `R05`) returning `Result<Option<T>, PortError>` (`R03`), blanket impl for `Arc<T>`, `ProjectsService<P: ProjectsPort>`, `InMemoryProjectsPort`, `RecordingPort<P>` spy (`R48`), optional `mock` feature (`mockall 0.15.0`), and synchronous `ureq 3.4.2` HTTP production adapter in root composition (`R05`, `httpmock 0.8.3` dev tests).
- `error-contract/v1` (`R67`): `#[non_exhaustive]` `ErrorCode` (`RSLB000`–`RSLB903`, `const fn as_str`, `pub const ALL`), `#[repr(u8)] enum Exit`, `thiserror` domain/port/config errors (no `anyhow` in `crates/core`).
- `Paths` over `etcetera 0.11.0` (`R57`: config/data/state/cache namespaced `rslbp`).
- Layered config (`R52`–`R55`): `toml 1.1.6` read + `toml_edit 0.25.15` comment-preserving write, `serde` `Unvalidated`/`Valid` type-state, 6-rung precedence with ancestor `.rslbp/rslbp_config.toml` discovery stopping at `.git` or workspace `Cargo.toml`, provenance-aware two-phase error tolerance.
- Secret policy (`R56`): config file never supplies tokens (`RSLB204`/exit 2 on `config set token`), `secrecy 0.10.3` + `zeroize 1.9.0`, `0600 credentials.toml` under `state_dir()`, optional `keychain` feature (`keyring-core 1.0.0`).
- Logging pipeline (`R58`, `R59`): `tracing 0.1.44` across workspace, `tracing-subscriber 0.3.23` (`env-filter`, `json` feature off, no `local-time`) in root `src/telemetry.rs` only (enforced by `deny.toml`), owned redacting JSON/console `FormatEvent`/`FormatFields` (`OV-09`), `reload::Handle`, `Profile::Cli` & `Profile::Service`, and std-only `RotatingFile` CLI sink.

### Out of scope
- `clap` CLI argument parsing and rich terminal UX (`P07`)
- `crates/web` HTTP routes, middleware, and `axum` handlers (`P08`–`P09`)

### Tests & Tasks
- [x] [P06-TS01] Write contract tests for `ErrorCode::ALL` append-only invariants (`R67`), `ProjectsPort` absence-vs-failure contract (`R01`/`R03`), 6-rung config merge & error-tolerance cases (`R52`–`R55`), secret rejection & `0600` credentials (`R56`), and redacting structured/console log output + `RotatingFile` rotation (`R58`/`R59`)
      2026-11-27: added `tests/error_contract.rs`, `tests/ports_contract.rs`, `tests/http_adapter_boundary.rs`, `tests/config_and_secrets_contract.rs`, and `tests/telemetry_contract.rs` (TDD red verified before implementation)
- [x] [P06-T01] Implement `ErrorCode`, `Exit`, and `thiserror` domain/port/config error types in `crates/core` (`R67`, `R03`)
      2026-11-27: implemented `crates/core/src/error.rs` with `#[repr(u8)] Exit`, append-only `#[non_exhaustive] ErrorCode` (`RSLB000`–`RSLB903`, `pub const ALL`), `PortError` (no `NotFound` variant), `ConfigError`, `AuthError`, `DomainError`, and `ErrorEnvelope`/`ErrorBody`
- [x] [P06-T02] Implement domain models, `ProjectsPort`, `ProjectsService<P>`, `InMemoryProjectsPort`, `RecordingPort<P>`, optional `mockall` feature, and root `ureq` adapter with `httpmock` tests (`R01`, `R03`, `R05`, `R48`)
      2026-11-27: implemented `crates/core/src/{models,ports,service}.rs` (`ProjectsPort` + `Arc<T>` blanket + `InMemoryProjectsPort` + `RecordingPort<P>` + `assert_projects_port_contract` + `#[cfg(feature = "mock")] MockProjectsPort` + `ProjectsService<P>` / `ErasedProjectsService`) and `src/http_adapter.rs` (`HttpProjectsPort` over `ureq`, strict DTO decode, per-operation status mapping, `httpmock 0.8.3` contract & boundary tests)
- [x] [P06-T03] Implement `Paths` (`etcetera`, `R57`), 6-rung layered TOML config loader + `toml_edit` writer (`R52`–`R55`), and secret store + optional `keychain` feature (`R56`)
      2026-11-27: implemented `crates/core/src/paths.rs` (pure 4-dir `Paths`), `crates/core/src/config/{mod,schema,validate,discovery,loader,writer}.rs` (`UnvalidatedConfig`/`ValidConfig`, ancestor walk stopping at `.git` or `[workspace]` `Cargo.toml`, per-layer sanitization before recursive table merge, decor-preserving `toml_edit` atomic `0600` writer refusing `token` with `RSLB204`), `crates/core/src/secrets.rs` (`Token`, `FileCredentialStore`, `InMemoryCredentialStore`, 3-tier `resolve_token`, `0o077` permission checks), and `src/keychain.rs` (`#[cfg(feature = "keychain")] KeychainCredentialStore` over `keyring-core`)
- [x] [P06-T04] Implement root `src/telemetry.rs` (`tracing` + owned redacting JSON/console formatters, `reload::Handle`, level ladder, `Profile::Cli`/`Profile::Service`, `RotatingFile` sink, `R58`/`R59`) and root composition functions
      2026-11-27: implemented `src/telemetry.rs` (`HumanFields`, `JsonFields`, `JsonEvent` with UTC ISO-8601 timestamps & R58 key ordering, `SENSITIVE_KEY_PARTS` redaction & control-char escaping, 7-rung level ladder, `Profile::Cli`/`Profile::Service`, per-layer `reload::Handle`, reloadable `RotatingFile` sink + 8-case `resolve_log_file`, host-safe `init_telemetry`) and updated `src/composition.rs` + curated `src/lib.rs` / `crates/core/src/lib.rs` barrels
- [x] [P06-T05] Verify default dependency tree contains no `tokio`/`axum`/`anyhow` in `crates/core`, `cargo deny --all-features check` passes, and `blaze test` passes on the default workspace
      2026-11-27: verified `cargo tree -p rs-launch-blueprint-core` contains no `tokio`/`axum`/`anyhow`/`tracing-subscriber` and `cargo tree --no-default-features -p rs-launch-blueprint -e normal` contains no `tokio`/`axum`; `cargo deny --all-features check`, `just check`, and all 6 Cargo feature-matrix + doctest suites pass; `blaze check` / `just blaze-status` pass (0 warnings) and `blaze test -- --skip http_` passes all 47 non-`httpmock` tests (`tests/http_adapter_boundary.rs` remains Cargo-authoritative while `blaze` v0.20261127.0 hits upstream `async-lock` `easy_wrapper!` macro resolution, documented in `just blaze-status`)

### Deliverable
```bash
just check
cargo test --workspace --no-default-features
just blaze-test
```

### Automated Verification
- All unit, contract, `httpmock`, redaction, and rotation tests pass under `cargo test` and `blaze test`
- `cargo tree -p rs-launch-blueprint-core` contains no `tokio`, `anyhow`, or `tracing-subscriber`
- `cargo deny --all-features check` and `just check` exit 0

### Manual Verification
- Inspect sample JSON and console stderr log lines to verify `[REDACTED]` masking and UTC ISO-8601 timestamps
