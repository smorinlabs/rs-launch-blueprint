# P04 — Workspace skeleton toolchain and Blaze accelerator

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
- **Spec:** [RS implementation roadmap design](../docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md)
- **Plan:** [Rex serial chain contract](../docs/superpowers/plans/2026-11-27-rex-serial-chain-contract.md)
- **Depends on:** P03
- **Prior art:** [R02 crate-boundary-enforcement](../research/topics/02-crate-boundary-enforcement/DECISION.md)
- **Prior art:** [R42 dev-toolchain-provisioning](../research/topics/42-dev-toolchain-provisioning/DECISION.md)
- **Prior art:** [R49 build-target-declaration](../research/topics/49-build-target-declaration/DECISION.md)

**Status:** `[x]` completed (2026-11-27).

### Scope
Bootstrap the Rust 4-package Cargo root workspace, pinned native toolchain, `Makefile` (L1) + parallel `Justfile` (L2), workspace lints/formatting/bans, and opt-in `indexable-inc/blaze` local edit-loop accelerator:
- 4-package root workspace (`R02`, `OV-03`): root facade `rs-launch-blueprint` (`[lib] src/lib.rs`, `[[bin]] rslbp`, `[[bin]] rslbp-serve` gated by `required-features = ["web"]`, `autobins = false`, explicit `[package] include` allow-list per `R49`), `crates/core`, `crates/cli`, and optional `crates/web` stub behind `web = ["dep:rs-launch-blueprint-web"]`.
- Fixed parameters (`docs/port/PARAMETERS.md`): `edition = "2024"`, `rust-version` at MSRV (`stable - 2`), `license = "MIT OR Apache-2.0"`, root `LICENSE` + `LICENSE-MIT` (no per-file headers per `R46`).
- `pub const VERSION: &str = env!("CARGO_PKG_VERSION")` (`R22`), private-module root barrel (`R04`), workspace `unsafe_code = "forbid"` (`R06`), `rustfmt.toml` (`R27`), workspace `[workspace.lints.clippy]` (`R28`), `deny.toml` crate-boundary & license/advisory rules (`R02`).
- `rust-toolchain.toml` (`profile = "minimal"`, `components = ["rustfmt", "clippy"]`, `R42`), `Makefile` (L1 bootstrap), `Justfile` (L2 `setup`, `[parallel]` `check` per py `P11`, `fmt`, `lint`, `typecheck` per `R30`, `test`, `deny`, `debug-info`), plus opt-in Blaze local accelerator recipes (`blaze-check`, `blaze-test`, `blaze-run`, `blaze-status`, `install-blaze`) with graceful Cargo fallback.

### Out of scope
- Git hooks (`lefthook`), `dprint`, `ast-grep`, DevContainer (`P05`)
- Domain logic, config, secrets, logging (`P06`), full CLI (`P07`), or web implementation (`P08`–`P09`)
- GitHub Actions CI workflows beyond existing `shellcheck.yml` and `difftree-pr-comment.yml` (`P10`)

### Tests & Tasks
- [x] [P04-TS01] Add workspace boundary, public-API barrel (`compile_fail` doctest), `VERSION` constant, `unsafe_code = "forbid"` verification, and `Justfile` recipe-contract tests (including Blaze fallback behavior when `blaze` is absent or present)
      2026-11-27: added `tests/workspace_edges.rs` (9 tests: intra-workspace edges, core external allow-list, fixed parameters, target/feature contract, `VERSION`, `unsafe_code = "forbid"` manifest + live `E0453` compiler probe, R46 license checks, `rslbp --version`), `tests/justfile_contract.rs` (4 tests incl. Blaze present & absent Cargo fallback), and `compile_fail,E0603` doctests in `src/lib.rs` and `crates/{core,cli,web}/src/lib.rs`
- [x] [P04-T01] Scaffold 4-package Cargo root workspace (`Cargo.toml`, `Cargo.lock`, `src/lib.rs`, `src/main.rs`, `src/bin/serve.rs`, `crates/core`, `crates/cli`, `crates/web` stub) matching `R02`, `R04`, `R06`, `R22`, `R46`, and `R49`
      2026-11-27: scaffolded root facade `rs-launch-blueprint` (`[lib]`, `[[bin]] rslbp`, `[[bin]] rslbp-serve` with `required-features = ["web"]`, `autobins = false`, `default-run = "rslbp"`, explicit `[package] include`) + `crates/{core,cli,web}` on Edition 2024, MSRV `1.98`, `MIT OR Apache-2.0`
- [x] [P04-T02] Commit `rust-toolchain.toml`, `rustfmt.toml`, workspace `[workspace.lints]` (`R27`, `R28`), and `deny.toml` (`R02`)
      2026-11-27: committed `rust-toolchain.toml` (`1.100.1`, `profile = "minimal"`, `components = ["rustfmt", "clippy"]`), `rustfmt.toml` (5 stable keys), `clippy.toml`, `crates/core/clippy.toml` (`disallowed-types`/`disallowed-methods`), `[workspace.lints]` (`R04`/`R06`/`R28`/`R30`), and `deny.toml` (`R02`/`R58`/`R67`)
- [x] [P04-T03] Author `Makefile` (L1 bootstrap) and `Justfile` (L2 setup, `[parallel]` `check`, `fmt`, `lint`, `typecheck`, `test`, `deny`, `debug-info`) per `R30`, `R42`, and py `P11`
      2026-11-27: authored L1 `Makefile` and L2 `Justfile` with single tool table, `check-deps` component-state check, generic `install-tool`, R27 `format-check`/`fmt`, R28 `lint`/`lint-fix`, R30 `typecheck`, `test`, `deny`, `check-shell`, `debug-info`, and `[parallel]` `check`
- [x] [P04-T04] Add opt-in Blaze local-accelerator recipes (`blaze-check`, `blaze-test`, `blaze-run`, `blaze-status`, `install-blaze`) and empirically verify `blaze check` and `blaze test` succeed on the default workspace on Apple Silicon
      2026-11-27: verified on Apple Silicon with `blaze 0.20261127.0 (nightly-2026-10-27)` — `just blaze-status` PASS, `just blaze-check` (2.4 ms), `just blaze-test` (12 passed + 2 cached, 0 failed), `just blaze-run --version` (`rslbp 0.1.0`); also verified absent-Blaze Cargo fallback via `tests/justfile_contract.rs`
- [x] [P04-T05] Verify `cargo check --workspace --no-default-features`, `--features web`, `cargo clippy --workspace --all-targets -- -D warnings`, `cargo fmt --all --check`, `cargo deny --all-features check`, `just check`, and `scripts/check-shell.sh` all exit 0
      2026-11-27: all Rust, Clippy, rustfmt, cargo-deny, `[parallel]` `just check`, `cargo metadata`, `cargo package --list`, `scripts/check-shell.sh`, `scripts/test-check-shell.sh` (5/5), `scripts/test-chain-next.sh` (14/14), `scripts/check-research-tree.sh --require-owner-review`, and all 11 `project-audit` checks pass cleanly

### Deliverable
```bash
just check
cargo deny --all-features check
just blaze-status
```

### Automated Verification
- `just check` exits 0 (including `[parallel]` legs and `compile_fail` doctests)
- `cargo clippy --workspace --all-targets --all-features -- -D warnings` and `cargo fmt --all --check` exit 0
- `just blaze-check` and `just blaze-test` pass on default workspace (and fall back cleanly when `blaze` is absent)
- `bash scripts/check-shell.sh` and `bash scripts/check-research-tree.sh --require-owner-review` exit 0

### Manual Verification
- Confirm `cargo metadata --no-deps` shows the exact 4 workspace packages and `rslbp` / `rslbp-serve` binary targets
