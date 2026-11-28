# Troubleshooting

Use the built-in diagnostic commands first to gather a redacted snapshot of your
environment before filing an issue:

```bash
just debug-info                 # System, Rust toolchain, and all pinned dev-tool versions
rslbp diagnostics --bundle --json  # Redacted CLI config & credential status bundle
```

## Missing or Mismatched Dev Tools

If `just check` or a git hook fails because a tool is missing or pinned to a
different version:

```bash
just check-deps                 # Lists every missing tool or version mismatch with fix command
just setup                      # Installs missing pinned tools and re-wires lefthook hooks
```

Ensure `~/.local/bin` and `~/.cargo/bin` appear on your `PATH`.

## Formatting Failures (`rustfmt` / `dprint`)

- Run `just format` to format all Rust, TOML, JSON, YAML, and Markdown files.
- If `just format-check` reports an unreached `.rs` file, confirm the file is
  referenced by a module declaration in its crate so `cargo fmt --all` visits it.

## Git Hook Failures

- **Commit message rejected (`committed`):** ensure your header follows
  `type(scope): description`, uses one of the 11 allowed types in
  `committed.toml`, stays within 50 characters (soft-line), has no trailing
  period, and wraps body lines at 72 characters.
- **`Cargo.lock` freshness failed:** run `cargo check --workspace --all-features`
  and stage the updated `Cargo.lock`.
- **Large file rejected (>1 MiB):** remove accidental binary artifacts or, for
  an intentional large asset, add `<path> large-file-ok` to `.gitattributes`.
- **Bypass hooks in an emergency only:** `LEFTHOOK=0 git commit ...` (CI still
  enforces every gate on the pull request).

## Blaze Local Accelerator Issues

`blaze` is opt-in and builds with its own pinned nightly. If a Blaze invocation
fails on `crates/web`, `--features`, or a missing toolchain manifest:

```bash
just blaze-status               # Shows live compatibility probes vs. Cargo
just check                      # Authoritative Cargo-backed verification
```

See [Blaze Local Accelerator](../tools/blaze.md) for current upstream blocker
details and when to use `blaze test -p rs-launch-blueprint-core` vs. `bacon` /
`cargo`.

## OpenAPI Snapshot or Packaging Drift

- **OpenAPI test failed after route edit:** run `just export-openapi` and commit
  `openapi/openapi.json`.
- **Packed `.crate` guard failed (`R26`):** run `just check-packaging` to see
  the exact diff against `ci/expected-packed-files/` or
  `ci/expected-packaged-targets/`. If you intentionally added a source file,
  update the expectation file in the same commit.

## Documentation & Link Checks

- **`mdbook build` failed with missing chapter:** check `docs/SUMMARY.md` for a
  typo or deleted file (`create-missing = false`).
- **`just docs-check` (`lychee --offline`) failed:** fix broken relative paths
  to `.md` files (always include the `.md` suffix so GitHub and mdBook both
  resolve the target).
- **`just docs-api` failed:** inspect the rustdoc warning (commonly a broken
  intra-doc link or bare URL) and fix it — warnings are denied across all
  features and private items.

## GitHub Pages or CodeQL Workflow Notices

- **Pages deploy skipped on `main`:** enable **Settings -> Pages -> Source:
  GitHub Actions** per [Project Setup Checklist](../PROJECT_SETUP.md).
- **CodeQL advanced setup deferred:** disable GitHub's built-in **Code Scanning
  Default Setup** so `.github/workflows/codeql.yml` can upload SARIF results
  without conflict.
