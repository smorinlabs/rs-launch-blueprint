# Blaze Local Accelerator (Opt-In)

`rs-launch-blueprint` integrates [`indexable-inc/blaze`](https://github.com/indexable-inc/blaze)
strictly as an **opt-in local edit-loop accelerator** with automatic fallback
to Cargo when `blaze` is not installed.

## Authority Contract

- **Opt-in only:** `blaze` is never required by `make bootstrap`, `just setup`,
  `just check`, git hooks, or CI.
- **Cargo stays sole authority:** CI, MSRV (`rust-version = "1.98"`), `clippy`,
  `rustfmt`, `cargo-deny`, `cargo-audit`, `cargo-nextest`, `cargo-llvm-cov`,
  `cargo-semver-checks`, packaging, and releases always run through Cargo and
  `rust-toolchain.toml`.
- **Toolchain caveat:** Blaze v2 compiles with its own pinned nightly toolchain
  (for example `nightly-2026-10-27` in `blaze 0.20261127.0`), ignoring
  `rust-toolchain.toml`, `RUSTUP_TOOLCHAIN`, and `rust-version`. Its
  content-addressed `~/.blaze/v2` cache is shared across checkouts and git
  worktrees.
- **Supported platforms:** macOS Apple Silicon (`arm64`) and Linux
  (`x86_64` / `arm64`, glibc >= 2.34).

## `Justfile` Recipes

```bash
just install-blaze          # Print official installer instructions and caveats
just install-blaze apply    # Run `curl -fsSL https://ix.dev/blaze | sh`
just blaze-status           # Compare Blaze vs. rust-toolchain.toml and run live probes
just blaze-check            # Run `blaze check` (falls back to `cargo check` if absent)
just blaze-test             # Run `blaze test` (falls back to `cargo test` if absent)
just blaze-run -- --version # Run `rslbp` via Blaze (falls back to `cargo run` if absent)
```

## Live Compatibility Matrix (`blaze 0.20261127.0`)

Empirical probes recorded in `just blaze-status` show the exact surfaces where
Blaze accelerates work today versus where Cargo / `bacon` remain required:

| Surface / Command                                         | Status (`blaze 0.20261127.0`)                                                 | Recommended Loop                             |
| --------------------------------------------------------- | ----------------------------------------------------------------------------- | -------------------------------------------- |
| `blaze test -p rs-launch-blueprint-core`                  | **PASS**                                                                      | Fast local domain unit-test loop             |
| `blaze build -p rs-launch-blueprint --bin rslbp`          | **PASS**                                                                      | Fast local CLI binary rebuild                |
| Workspace-wide `blaze check` / `blaze test`               | **Blocked** (`utoipa-axum 0.3.0` `routes!` macro in `crates/web`)             | Fall back to `cargo` / `just check`          |
| `--features web`, `--features metrics`, `--features otel` | **Unsupported by CLI** (`blaze` rejects `--features`)                         | Use `cargo` / `bacon` (`just serve`)         |
| `tests/http_adapter_boundary.rs`                          | **Blocked** (`async-lock` `easy_wrapper!` macro)                              | Use `just test --test http_adapter_boundary` |
| Built-binary CLI / `insta` / `proptest` suites            | **Cargo-authoritative** (`ring` C objects & virtualized `CARGO_MANIFEST_DIR`) | Use `just test`                              |

> [!NOTE]
> Isolated crate probes show upstream `indexable-inc/blaze#598` (`utoipa-gen
> 6.0.1`) and `indexable-inc/blaze#1826` (`metrics 0.24.6` +
> `metrics-exporter-prometheus 0.18.3`) resolved in `v0.20261127.0`. Run
> `just blaze-status` after upgrading Blaze to re-probe workspace and feature
> compatibility live.

## Coexistence with `bacon`

Use `blaze` for fast `crates/core` and `rslbp` edit-compile loops and `bacon`
(`bacon.toml`, `just serve`) for continuous Clippy and `crates/web` live-reload
development. Always finish with `just check` before committing or opening a
pull request.
