# Toolchain and Quality Gates

Every development tool in `rs-launch-blueprint` is pinned in one authoritative
table inside `Justfile` (`R42`) and invoked without provisioner prefixes:
`cargo <sub>` for `cargo-<sub>` executables (including `rustfmt` and `clippy`)
and bare `<tool>` on `PATH` for standalone binaries.

## Pinned Tool Inventory

| Tool                   | Pin / Channel                     | Acquisition Channel             | Role                                                               |
| ---------------------- | --------------------------------- | ------------------------------- | ------------------------------------------------------------------ |
| `rustc` / `cargo`      | `rust-toolchain.toml` (`1.100.1`) | `rustup`                        | Primary compiler, package manager, and `rustdoc` (`R42`, `R82`).   |
| `rustfmt` / `clippy`   | `rust-toolchain.toml` components  | `rustup`                        | Rust formatting (`R27`) and linting (`R28`).                       |
| `llvm-tools-preview`   | `rust-toolchain.toml` component   | `rustup`                        | Instrumentation runtime for `cargo-llvm-cov` (`R35`).              |
| `just`                 | `1.58.0` (CI) / Homebrew          | `make bootstrap`                | Level 2 task runner (`R42`).                                       |
| `cargo-deny`           | `0.20.2`                          | `cargo-binstall`                | Crate bans, advisories, licenses, sources (`R02`, `R13`).          |
| `cargo-audit`          | `0.22.2`                          | `cargo-binstall`                | RustSec `Cargo.lock` advisory scanner (`R13`).                     |
| `cargo-nextest`        | `0.9.146`                         | `cargo-binstall`                | Parallel isolated test runner with timeouts (`R32`).               |
| `cargo-insta`          | `1.48.0`                          | `cargo-binstall`                | Snapshot test review and verification (`R33`).                     |
| `cargo-llvm-cov`       | `0.9.1`                           | `cargo-binstall`                | Source-based LLVM coverage floors & reports (`R35`).               |
| `dprint`               | `0.57.4` (+ 4 SHA-pinned Wasm)    | `cargo-binstall`                | TOML, JSON/JSONC, YAML, Markdown formatter (`R29`).                |
| `ast-grep`             | `0.45.3`                          | `cargo-binstall`                | Template-owned AST security rules (`R31`).                         |
| `committed`            | `1.1.11`                          | `cargo-binstall`                | Conventional Commits linter (`R38`).                               |
| `typos` (`typos-cli`)  | `1.50.3`                          | `cargo-binstall`                | Fast source & docs spell checker (`R40`).                          |
| `ryl`                  | `0.22.0`                          | `cargo-binstall`                | Rust YAML linter honoring `.yamllint` (`R40`).                     |
| `mdbook`               | `0.5.4`                           | `cargo-binstall`                | Documentation site builder & preview server (`R81`).               |
| `lefthook`             | `2.1.14`                          | `ubi`                           | Parallel git hook manager (`R37`).                                 |
| `gitleaks`             | `8.30.1`                          | `ubi`                           | Pre-commit & pre-push secret scanner (`R39`).                      |
| `editorconfig-checker` | `4.0.2`                           | `ubi`                           | `.editorconfig` compliance checker (`R40`).                        |
| `actionlint`           | `1.7.12`                          | `ubi`                           | GitHub Actions workflow syntax & expression linter (`R09`, `R40`). |
| `zizmor`               | `1.30.1`                          | `ubi`                           | Static GitHub Actions security & SHA-pin auditor (`R08`, `R20`).   |
| `lychee`               | `0.24.2`                          | `ubi`                           | Offline internal & scheduled external link checker (`R82`).        |
| `shellcheck`           | `0.11.0`                          | `scripts/install-shellcheck.sh` | Static shell script analyzer (`scripts/check-shell.sh`).           |

Optional specialized tools (installed on demand when needed):

- `bacon 3.25.0` — live-reload watcher for `just serve` (`R69`)
- `oasdiff v1.32.1` — OpenAPI breaking-change check for `just api-breaking` (`R71`)
- `openapi-to-rust 0.17.0` — typed client generator for `just generate-client` (`R84`)
- `blaze` — opt-in local edit-loop accelerator (`just install-blaze`)

## Verification Commands

```bash
just check-deps        # Audit every pinned tool and rustup component
just check             # Run all 9 parallel read-only workspace quality gates
just check-workflows   # Run actionlint, zizmor, R08 permissions, and R20 pin checks
just check-packaging   # Run all 4 R26 packed .crate content and metadata guards
just docs-build        # Build mdBook site into book/
just docs-check        # Verify offline internal links with lychee
just docs-api          # Verify workspace rustdoc with -D warnings across all features
```
