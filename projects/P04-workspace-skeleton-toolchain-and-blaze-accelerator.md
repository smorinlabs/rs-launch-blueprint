# P04 — Workspace skeleton toolchain and Blaze accelerator

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
- **Spec:** [RS implementation roadmap design](../docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md)
- **Plan:** [Rex serial chain contract](../docs/superpowers/plans/2026-11-27-rex-serial-chain-contract.md)
- **Depends on:** P03
- **Prior art:** [R02 crate-boundary-enforcement](../research/topics/02-crate-boundary-enforcement/DECISION.md)
- **Prior art:** [R42 dev-toolchain-provisioning](../research/topics/42-dev-toolchain-provisioning/DECISION.md)
- **Prior art:** [R49 build-target-declaration](../research/topics/49-build-target-declaration/DECISION.md)

**Status:** `[ ]` scoped, not started.

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
- [ ] [P04-TS01] Add workspace boundary, public-API barrel (`compile_fail` doctest), `VERSION` constant, `unsafe_code = "forbid"` verification, and `Justfile` recipe-contract tests (including Blaze fallback behavior when `blaze` is absent or present)
- [ ] [P04-T01] Scaffold 4-package Cargo root workspace (`Cargo.toml`, `Cargo.lock`, `src/lib.rs`, `src/main.rs`, `src/bin/serve.rs`, `crates/core`, `crates/cli`, `crates/web` stub) matching `R02`, `R04`, `R06`, `R22`, `R46`, and `R49`
- [ ] [P04-T02] Commit `rust-toolchain.toml`, `rustfmt.toml`, workspace `[workspace.lints]` (`R27`, `R28`), and `deny.toml` (`R02`)
- [ ] [P04-T03] Author `Makefile` (L1 bootstrap) and `Justfile` (L2 setup, `[parallel]` `check`, `fmt`, `lint`, `typecheck`, `test`, `deny`, `debug-info`) per `R30`, `R42`, and py `P11`
- [ ] [P04-T04] Add opt-in Blaze local-accelerator recipes (`blaze-check`, `blaze-test`, `blaze-run`, `blaze-status`, `install-blaze`) and empirically verify `blaze check` and `blaze test` succeed on the default workspace on Apple Silicon
- [ ] [P04-T05] Verify `cargo check --workspace --no-default-features`, `--features web`, `cargo clippy --workspace --all-targets -- -D warnings`, `cargo fmt --all --check`, `cargo deny --all-features check`, `just check`, and `scripts/check-shell.sh` all exit 0

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
