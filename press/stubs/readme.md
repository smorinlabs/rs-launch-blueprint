# Project README

> Replace this starter README with your project's overview, library API examples,
> and CLI/web usage notes. See [docs/PROJECT_SETUP.md](docs/PROJECT_SETUP.md) to finish
> repository configuration (secrets, branch protection, publishing, and Pages).

## Quick start

```bash
make bootstrap
just setup
just check
```

## Workspace layout

- `Cargo.toml` / `src/` — standalone `[lib]`-only Rust library crate (zero CLI or web dependencies)
- `crates/core/` — pure synchronous domain models, ports, services, config, secrets, and error catalog
- `crates/cli/` — command-line binary and terminal front end
- `crates/web/` — optional internal Axum HTTP service (`publish = false`)
- `docs/` — library reference, setup checklist, release guide, and project documentation

## Common commands

```bash
just --list           # list all available task recipes
just format           # format Rust and non-Rust files
just check            # run all read-only quality, lint, security, and test gates
just lib-check        # verify packed standalone library consumption (default + minimal features)
just check-packaging  # verify packed `.crate` contents and metadata
```

## License

Dual-licensed under MIT or Apache-2.0. See [LICENSE](LICENSE) and [LICENSE-MIT](LICENSE-MIT).
