# Contributing Guide

Thank you for contributing to `rs-launch-blueprint`. Every contributor follows
one streamlined workflow enforced equally by local `lefthook` hooks and GitHub
Actions (`ci-ok`).

## Before You Open a Pull Request

1. **Bootstrap once per clone:**
   ```bash
   make bootstrap
   just setup
   ```
2. **Work on a topic branch** branched from `origin/main` (never commit
   directly to `main`).
3. **Write tests first where applicable** and keep domain code inside
   `crates/core` free of CLI, web, and async framework imports (`R02`, `R05`).
4. **Run the full local quality suite:**
   ```bash
   just format
   just check
   just docs-build
   just docs-check
   just docs-api
   ```
5. **If you changed web routes or schemas**, regenerate and commit the OpenAPI
   snapshot:
   ```bash
   just export-openapi
   just check-openapi
   ```
6. **If you changed workflows or package manifests**, run:
   ```bash
   just check-workflows
   just check-packaging
   ```

## Commit Message Rules (`R38`)

Every commit must follow **Conventional Commits** (`committed.toml`, verified
at `commit-msg` time and in CI):

- **Allowed types (11):** `build`, `chore`, `ci`, `docs`, `feat`, `fix`,
  `perf`, `refactor`, `revert`, `style`, `test`
- **Header length:** `<= 50` characters (soft-line), lowercase description, no
  trailing period (e.g., `feat(cli): add markdown output flag`)
- **Body & footer wrap:** `<= 72` characters (soft-line)
- **Merge strategy:** pull requests merge with standard merge commits — squash
  merges are disabled so commit history stays intact for Release Please.

## Pull Requests & Re-Reviews (`R45`)

- Complete the pre-flight checklist in `.github/pull_request_template.md`.
- Do not add bot `@`-mentions to the PR template or description.
- To request an additional Claude review on a PR (when repository credentials
  are configured), an `OWNER`, `MEMBER`, or `COLLABORATOR` can comment
  `@claude please re-review` as documented in `.github/CONTRIBUTING.md`.
- When filing a bug report, include the output of `just debug-info` (and
  `rslbp diagnostics --bundle --json` for runtime issues).

## Community Standards & Security

- **Code of Conduct:** all participation is governed by the Contributor
  Covenant in `.github/CODE_OF_CONDUCT.md`.
- **Vulnerability reporting:** never open a public issue for a security
  vulnerability; follow the private reporting process in `.github/SECURITY.md`.
- **Licensing (`R46`):** contributions are dual-licensed under `MIT OR
  Apache-2.0`; do not add per-file copyright or SPDX headers to source files.
- **Contributor License Agreement (`F208`):** see [CLA FAQ](cla-faq.md) and
  [CLA Assistant](../tools/cla-assistant.md) for optional CLA setup and DCO
  contingencies.
