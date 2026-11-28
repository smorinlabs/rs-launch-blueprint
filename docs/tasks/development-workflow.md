# Development Workflow

`rs-launch-blueprint` uses a two-level task model (`R42`): `Makefile` handles
Level 1 base toolchain installation (`rustup` + `just`), and `Justfile` handles
every day-to-day task using bare executables on `PATH` and `cargo <sub>`
subcommands.

## Daily Edit Loop

1. **Format before checking:**
   ```bash
   just format          # cargo fmt --all && dprint fmt
   ```
2. **Run all read-only quality gates in parallel (`[parallel] @check`):**
   ```bash
   just check
   ```
   `just check` executes `format-check`, `check-files`, `security`,
   `check-hygiene`, `check-shell`, `lint`, `typecheck`, `test`, and `deny`
   without modifying any file.
3. **Optional fast local loops:**
   - Core/CLI iteration with opt-in Blaze (`just blaze-status`,
     `blaze test -p rs-launch-blueprint-core`, `just blaze-check`). See
     [Blaze Local Accelerator](../tools/blaze.md).
   - Web service hot reload with `bacon` (`just serve`) or foreground runs
     (`just serve-once`).

## Git Hooks (`lefthook`, `R37`–`R41`)

`just setup` wires `lefthook.yml` and sets `git config commit.template .gitmessage`:

- **`pre-commit` (parallel):** `cargo fmt --all --check`, `dprint check`,
  `cargo clippy --workspace --all-targets --locked -- -D warnings` (tagged
  `compiles`, when `.rs` or `.toml` files are staged), `ast-grep scan --error`,
  ShellCheck (`scripts/check-shell.sh`), `gitleaks` staged scan,
  `scripts/check-large-files.sh --staged` (`1 MiB`),
  `scripts/check-cargo-lock.sh`, `editorconfig-checker`, `ryl`, `typos`, and
  `actionlint`. Run `just check-openapi` separately after changing web routes or
  schemas to verify `openapi/openapi.json` has not drifted.
- **`commit-msg`:** `committed --fixup --wip --commit-file {1}` enforcing
  Conventional Commits (11 allowed types, 50/72/72 soft-line caps).
- **`pre-push`:** `gitleaks` unpushed commit-range scan, plus an opt-in
  `just test` run when `RS_PROJECTS_PREPUSH_TESTS=1` is set (skipped by default
  so pushes remain fast; `cargo clippy` runs in `pre-commit` under
  `tags: [compiles]`).

Run the entire pre-commit suite across all tracked files at any time:

```bash
just hooks-run
just hook-check        # Report-only readiness check for hook binaries
```

## DevContainer (`R44`) & VS Code (`R28`)

- `.devcontainer/devcontainer.json` uses a digest-pinned Debian Trixie Rust
  image (`mcr.microsoft.com/devcontainers/rust:2.1.1-trixie@sha256:...`) and
  runs `.devcontainer/post-create.sh` (`rustup toolchain install`,
  `make bootstrap`, `just setup`).
- `.vscode/` configures `rust-analyzer` with Clippy as its check command,
  recommends `rust-lang.rust-analyzer` and `vadimcn.vscode-lldb`, and provides a
  ready-to-run LLDB launch profile for `rslbp`.

## Updating Dependencies & Packaging Checks

After editing `Cargo.toml` or workspace member manifests:

```bash
just check-lockfile     # Verify Cargo.lock is synchronized across workspace roots
just deny               # Check bans, advisories, licenses, and sources
just check-packaging    # Run all 4 R26 packed .crate content and metadata guards
just install-check      # Pack -> extract -> cargo install into throwaway root -> --version
just install-check web  # Same smoke check with --features web (verifies rslbp-serve)
```
