# Project Setup Checklist

Complete these human-only configuration steps after stamping a repository with
Template Press (`press/press-receipt.toml` committed and verified). Every step
below uses repository settings, credentials, or external services that
automation cannot safely configure on your behalf.

## 1. Local verification

Confirm your local toolchain, git hooks, and full verification suite are green:

```bash
make bootstrap
just setup
just check
just check-packaging
```

## 2. Branch protection and merge policy on `main`

Configure a repository ruleset targeting `main`:

- Require pull requests before merging.
- Require status checks to pass before merging:
  - `ci-ok`
  - `press-verify`
- Disable squash merges so merge commits and Conventional Commits history remain
  intact for Release Please and `commitlint`:

```bash
gh api --method PATCH "repos/{owner}/{repo}" \
  -F allow_merge_commit=true \
  -F allow_squash_merge=false \
  -F allow_rebase_merge=false
```

## 3. Code Scanning (CodeQL) default setup

This repository runs CodeQL via `.github/workflows/codeql.yml`. Disable GitHub's
built-in default CodeQL setup so workflows do not conflict:

```bash
gh api --method PATCH "repos/{owner}/{repo}/code-scanning/default-setup" \
  -f state=not-configured
```

Enable **Dependabot alerts** and **Dependabot security updates** under
**Settings -> Code security**.

## 4. Release Please credentials

`.github/workflows/release-please.yml` opens release PRs and creates `vX.Y.Z`
tags that trigger downstream CI, `cargo-dist`, crates.io publishing, and GHCR
image publishing. Configure **either** a dedicated GitHub App (preferred) **or**
a scoped PAT:

- **GitHub App (recommended):**
  - `RELEASE_PLEASE_CLIENT_ID` (Actions secret)
  - `RELEASE_PLEASE_PRIVATE_KEY` (Actions secret)
- **Fallback token:**
  - `RELEASE_PLEASE_APP_TOKEN` (Actions secret)

Do not rely on default `GITHUB_TOKEN` for Release Please tags if you want tags
to trigger downstream release workflows.

## 5. crates.io publishing and environments

Create the following GitHub Environments under **Settings -> Environments**:

- `crates-io` — restrict deployments to protected tags (`v*`) or require
  reviewer approval; used by `.github/workflows/publish.yml`.
- `security-review` — required reviewer gate for manual security workflows
  (`.github/workflows/manual-pr-security-scan.yml` and audit triage).

Configure crates.io authentication:

1. **One-time initial publish (required before Trusted Publishing):** crates.io
   Trusted Publishing attaches to crates that already exist on crates.io. For a
   brand-new project, first publish all four workspace crates in dependency
   order (`<repo>-core`, `<repo>-cli`, `<repo>-web`, and `<repo>`) using a
   short-lived publish-scoped crates.io API token. Performing this one-time
   bootstrap locally with `cargo publish --workspace --locked` avoids storing a
   repository-level `CRATES_IO_TOKEN` secret. If you prefer CI to run the
   initial `v0.1.0` publish instead, temporarily store `CRATES_IO_TOKEN` as a
   **repository-level** Actions secret (note: `.github/workflows/publish.yml`'s
   `credential-preflight` job runs outside the `crates-io` environment so
   unprovisioned repositories skip without waiting on environment reviewers,
   which means an environment-only secret is invisible to preflight and a
   repository-level secret is exposed to all repository workflows until
   removed).
2. **Trusted Publishing via OIDC (recommended after initial publish):** on
   crates.io, register this repository, `.github/workflows/publish.yml`, and
   environment `crates-io` as a Trusted Publisher for each of the four crates,
   then set repository variable `CRATES_IO_TRUSTED_PUBLISHING=true` and delete
   any temporary repository-level `CRATES_IO_TOKEN` secret.
3. **API token fallback:** if you prefer not to use OIDC, store a
   publish-scoped crates.io token as a **repository-level** `CRATES_IO_TOKEN`
   Actions secret so both `credential-preflight` and `publish-crates-io` can
   read it (prefer Trusted Publishing to avoid repository-wide token exposure).

See [RELEASE.md](RELEASE.md) for the full release and dry-run sequence.

## 6. Container registry (GHCR) visibility

`.github/workflows/publish-container.yml` publishes multi-arch container images
to **GHCR** (`ghcr.io/<owner>/<repo>`). After the first published tag:

1. Open the package page under **Packages** on GitHub.
2. Under **Package settings -> Danger Zone -> Change visibility**, switch the
   package to **Public** if anonymous `docker pull` is intended (verified by the
   anonymous-pull smoke check in `publish-container.yml`).

## 7. GitHub Pages (documentation publishing)

If you publish documentation with GitHub Pages:

1. Open **Settings -> Pages**.
2. Set **Build and deployment -> Source** to **GitHub Actions**.

## 8. Optional AI code review and audit triage credentials

All AI workflows skip cleanly when their credentials are absent:

- **Claude Code review & `@claude` follow-up:** set `ANTHROPIC_API_KEY` or
  `CLAUDE_CODE_OAUTH_TOKEN` (or configure OIDC federation variables
  `ANTHROPIC_FEDERATION_RULE_ID` and `ANTHROPIC_ORGANIZATION_ID`). Delete
  `.github/workflows/claude.yml` and `.github/workflows/claude-code-review.yml`
  to opt out permanently.
- **Codex review:** set `OPENAI_API_KEY`.
- **Meta Muse audit triage:** set `META_MUSE_CI_API_KEY`.

## 9. Optional Contributors Please automation

Template stamping removes the blueprint's contributor state and workflow so new
repositories start clean. To opt in for your project:

1. Create `.contributors.yml` and add `<!-- contributors-please:start -->` /
   `<!-- contributors-please:end -->` markers to `CONTRIBUTORS.md`.
2. Run `just update-contributors` locally to generate `.contributors.jsonl` and
   render `CONTRIBUTORS.md`.
3. Optionally add a workflow invoking
   `smorinlabs/contributors-please-action` on `push` to `main` (with
   `paths-ignore` on `CONTRIBUTORS.md` and `.contributors.jsonl`) and configure
   **either** credential option:
   - **GitHub App (recommended):** set `CONTRIBUTORS_PLEASE_CLIENT_ID` and
     `CONTRIBUTORS_PLEASE_PRIVATE_KEY` secrets.
   - **Fine-grained PAT (alternative):** set `CONTRIBUTORS_PLEASE_PAT` secret.

> **Important:** Do **not** pass `secrets.GITHUB_TOKEN` to
> `contributors-please-action`. Pull requests created with `GITHUB_TOKEN` do not
> trigger downstream status checks required by branch protection.
