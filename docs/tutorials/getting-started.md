# Getting Started

This tutorial walks through a fresh clone of `rs-launch-blueprint`, verifying
the full quality gate suite, running both `rslbp` and `rslbp-serve`, and
optionally stamping a new downstream repository.

## 1. Prerequisites

Supported developer platforms match the CI matrix (`ubuntu-latest` and
`macos-latest`):

- Git and Bash
- A C linker (`xcode-select --install` on macOS, `build-essential` on Linux)
- `curl` (used by `make bootstrap` to install `rustup` and `just` if absent)

## 2. Two-Level Bootstrap (`R42`)

```bash
git clone https://github.com/smorinlabs/rs-launch-blueprint.git
cd rs-launch-blueprint

# Level 1: verify/install base toolchain (rustup + just)
make bootstrap

# Level 2: activate rust-toolchain.toml, install pinned dev tools, wire lefthook hooks
just setup

# Verify every tool and rustup component is present
just check-deps
```

> [!TIP]
> You can also open the repository in VS Code or GitHub Codespaces using the
> image-only `.devcontainer/devcontainer.json` environment (`R44`), which runs
> `rustup toolchain install`, `make bootstrap`, and `just setup` automatically.

## 3. Run the Full Quality Suite

```bash
just check
```

`just check` runs all nine read-only gates in parallel (`format-check`,
`check-files`, `security`, `check-hygiene`, `check-shell`, `lint`, `typecheck`,
`test`, and `deny`).

To verify the documentation build and strict rustdoc as well:

```bash
just docs-build
just docs-check
just docs-api
```

## 4. Exercise the CLI (`rslbp`)

```bash
cargo run --bin rslbp -- --version
cargo run --bin rslbp -- diagnostics --json
cargo run --bin rslbp -- config init --dry-run --yes
cargo run --bin rslbp -- project list --json
```

See [CLI Reference](../reference/cli-reference.md) for every flag, output
format, config rung, and `RSLB###` error code.

## 5. Run the Optional Web Service (`rslbp-serve`)

```bash
just serve-once
```

In another terminal, probe liveness, readiness, and `/v1/projects`:

```bash
curl -s http://127.0.0.1:8000/healthz
curl -s http://127.0.0.1:8000/readyz
curl -s -X POST http://127.0.0.1:8000/v1/projects \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: tutorial-1" \
  -d '{"name":"Demo","workspace":"Core"}'
```

For hot-reloading while editing `crates/web`, install `bacon` (`cargo binstall
--locked bacon`) and run `just serve`.

## 6. Create Your Own Project from This Template

To stamp a new Rust repository with your own crate, binary, owner, and package
identity:

1. Follow the [Bootstrap Skill Guide](../skills/new-rust-project.md) (or ask
   Claude Code / Codex to _"create a new Rust project from rs-launch-blueprint"_).
2. Review the generated `press/press-receipt.toml` and complete the one-time
   repository settings in [Project Setup Checklist](../PROJECT_SETUP.md).
