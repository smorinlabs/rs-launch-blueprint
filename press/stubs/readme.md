# Project README

> Replace this starter README with your project's overview, architecture notes,
> and usage examples. See [docs/PROJECT_SETUP.md](docs/PROJECT_SETUP.md) to finish
> repository configuration (secrets, branch protection, publishing, and Pages).

## Quick start

```bash
make bootstrap
just setup
just check
```

## Workspace layout

- `Cargo.toml` / `src/` — root crate, library façade, CLI binary, and optional web binary
- `crates/core/` — domain models, ports, services, and error catalog
- `crates/cli/` — command-line presentation layer
- `crates/web/` — optional Axum HTTP service (`--features web`)
- `docs/` — setup checklist, release guide, and project documentation

## Common commands

```bash
just --list        # list all available task recipes
just format        # format Rust and non-Rust files
just check         # run all read-only quality, lint, security, and test gates
just check-packaging  # verify packed `.crate` contents and metadata
```

## License

Dual-licensed under MIT or Apache-2.0. See [LICENSE](LICENSE) and [LICENSE-MIT](LICENSE-MIT).
