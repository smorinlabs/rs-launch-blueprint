# Release Process

This repository automates semantic versioning, crates.io packaging guards, pre-built CLI binary
distribution, and GHCR container publication across four coordinated workflows:

| Workflow                                  | Trigger                               | Responsibility                                                                                                                                                                                                                            |
| ----------------------------------------- | ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.github/workflows/release-please.yml`    | Push to `main` (or manual dispatch)   | Maintains the Release PR; on merge, pushes tag `vX.Y.Z` and creates a **draft** GitHub Release (`R23`, `R24`, `R25`, `R68`).                                                                                                              |
| `.github/workflows/publish.yml`           | Tag `v*` (or manual dispatch on `v*`) | Verifies tag ancestry & version lockstep, runs all 4 packed `.crate` guards (`R26`), runs `cargo-semver-checks` (`R04`), dry-runs workspace publish, and publishes to crates.io in the protected `crates-io` environment.                 |
| `.github/workflows/release.yml`           | PRs (`dist plan`) and tag `v*`        | Runs `cargo-dist` (`dist` `0.33.0`) in follower mode (`create-release = false`): builds `rslbp` archives + shell installer + SHA-256 checksums for all 3 targets, uploads assets to the draft GitHub Release, and undrafts it (`R68`).    |
| `.github/workflows/publish-container.yml` | Published stable GitHub Release       | Builds, smoke-tests, and publishes `linux/amd64` `rslbp-serve` to `ghcr.io/smorinlabs/rs-launch-blueprint`, verifies anonymous pull + immutable `@sha256:` digest, and reconciles `:latest` (owner review-gate `1a-A` OVERRIDE of `R51`). |

---

## 1. Default End-to-End Flow (`release-please`)

1. Merge Conventional Commits (`feat:`, `fix:`, `perf:`, `revert:`, `docs:`, etc.) to `main`.
2. `release-please.yml` runs `release-type: "rust"` (`release-please-config.json`):
   - Updates all four literal `[package] version` fields (`Cargo.toml`, `crates/core/Cargo.toml`,
     `crates/cli/Cargo.toml`, `crates/web/Cargo.toml`), every intra-workspace `{ version, path }`
     dependency pin, `Cargo.lock` (via release-please's native `CargoLock` updater, with no
     duplicate `extra-files` entry per `R23`), `.release-please-manifest.json`, and `CHANGELOG.md`
     in a single atomic commit.
   - Pre-1.0 semver dampening (`R25`): both `bump-minor-pre-major: true` and
     `bump-patch-for-minor-pre-major: true` are enabled so `fix:` and non-breaking `feat:` bump
     patch (`0.1.z → 0.1.(z+1)`) while `feat!:` / `BREAKING CHANGE:` bumps minor (`0.1.z → 0.2.0`),
     matching Cargo's `0.y` compatibility rule. Reaching `1.0.0` requires an explicit human
     `Release-As: 1.0.0` commit footer.
   - Changelog section mapping (`R24`): total ordered 11-entry array matching `committed.toml`:
     - **Visible:** `feat` (_Features_), `fix` (_Bug Fixes_), `perf` (_Performance Improvements_),
       `revert` (_Reverts_), `docs` (_Documentation_).
     - **Hidden (rendered only if breaking):** `refactor` (_Code Refactoring_), `test` (_Tests_),
       `build` (_Build System_), `ci` (_Continuous Integration_), `style` (_Styles_), `chore`
       (_Miscellaneous Chores_).
3. Merge the Release PR (`chore(release): publish vX.Y.Z`). Because `draft: true` and
   `force-tag-creation: true` are set (`R68`), `release-please` creates a draft GitHub Release and
   immediately pushes the `vX.Y.Z` tag using the configured GitHub App token (or fallback PAT).
4. The `vX.Y.Z` tag triggers both `publish.yml` (crates.io) and `release.yml` (`cargo-dist`) in
   parallel.
5. Once `release.yml` uploads all binary archives and checksums to the draft release, it undrafts
   the release (`--draft=false`) using the release App token/PAT. Undrafting emits
   `release: published`, which triggers `publish-container.yml` to publish the `rslbp-serve` GHCR
   container image.

### First-Release Bootstrap Notes

- `.release-please-manifest.json` starts empty (`{}`) per `R25` so the first automated release-please
  PR proposes `0.1.0` matching `[package] version = "0.1.0"`.
- For an existing repository with pre-existing non-crate tags (such as research tags `v0.1.0` /
  `v0.2.0`), set `"bootstrap-sha"` in `release-please-config.json` (or seed
  `.release-please-manifest.json`) at cutover so release-please begins scanning from the first
  release-ready commit on `main`. Stamped child repositories inherit an empty
  `.release-please-manifest.json` and no `bootstrap-sha`.

---

## 2. Crates.io Packaging Guards & Publication (`publish.yml`)

Before anything can reach crates.io, the read-only `verify` job enforces:

1. **Tag ancestry and version lockstep (`F074`):** The workflow ref must be a `v*` tag whose commit
   is an ancestor of `origin/main`, and its version `X.Y.Z` must equal all four workspace
   `Cargo.toml` manifests and `.release-please-manifest.json`.
2. **All 4 first-party packed `.crate` content guards (`R26`):** Executed via
   `bash scripts/check-packed-artifacts.sh` (also runnable locally via `just check-packaging`):
   - **Element 1 (`F039` file-set allow-list):** `cargo package -p <pkg> --list --no-verify --offline --locked`
     diffed in byte order (`LC_ALL=C`) against `ci/expected-packed-files/<pkg>.txt`.
   - **Element 2 (`F078` packaged-metadata):** Packs freshly (removing any prior `.crate` and
     aborting on nonzero exit), greps stderr for silent target-pruning or `include`+`exclude`
     warnings, extracts the `.crate` archive, diffs the packaged `{name, kind}` targets against
     `ci/expected-packaged-targets/<pkg>.json`, verifies `Cargo.toml.orig` is byte-identical to
     source `Cargo.toml`, and diffs the publish-facing metadata projection between source and
     extracted archive.
   - **Element 3:** Runs `cargo publish --workspace --dry-run --locked`.
   - **Element 4:** Enforces explicit `[package] include` with no `[package] exclude` in every
     publishable crate manifest.
3. **Public-API SemVer check (`R04`):** Runs `obi1kenobi/cargo-semver-checks-action` against the
   most recent prior Rust crate release tag (`--feature-group only-explicit-features --features web`),
   skipping with a notice on the initial crate release when no prior Rust tag exists.
4. **Workspace publish (`F075`):** The `publish-crates-io` job runs in the protected `crates-io`
   GitHub Environment and publishes all four workspace crates in dependency order via
   `cargo publish --workspace --locked`.

---

## 3. Pre-Built CLI Binary Distribution (`cargo-dist` `0.33.0`, `R68`)

`dist-workspace.toml` configures `cargo-dist` (`dist` `0.33.0`) in **follower mode**:

- **Targets:** `x86_64-unknown-linux-gnu` (`ubuntu-latest`), `x86_64-apple-darwin`
  (`macos-latest`), and `aarch64-apple-darwin` (`macos-latest`).
- **Artifacts per release:** `rs-launch-blueprint-<triple>.tar.xz` + `.sha256` per target,
  `rs-launch-blueprint-installer.sh`, `source.tar.gz` + `.sha256`, `sha256.sum`, and
  `dist-manifest.json`.
- **CLI-only archive boundary:** `[dist.binaries]` restricts release archives to `rslbp`. The
  optional `web`-gated `rslbp-serve` binary is distributed as a container image rather than in CLI
  tarballs.
- **Release build profile (`R68` Subject B):** Root `Cargo.toml` sets `[profile.release]` to
  `lto = "fat"` and `codegen-units = 1` (deliberately leaving `opt-level`, `strip`, `panic`, and
  `debug` at Cargo defaults so end-user binaries retain panic backtraces and R67 exit semantics),
  and `[profile.dist]` inherits `release` with no `lto = "thin"` override. Downstream library
  consumers do not inherit `[profile.*]` tables from dependencies.
- **`cargo-binstall` compatibility:** No `[package.metadata.binstall]` block is required because
  `cargo-dist` archive names (`{name}-{target}.tar.xz`) and binary name (`rslbp`) match
  `cargo-binstall`'s built-in GitHub release defaults.

### End-User Install Commands (`F220`)

1. `cargo binstall rs-launch-blueprint` (pre-built binary via GitHub Release metadata)
2. Shell installer (`rs-launch-blueprint-installer.sh` attached to each GitHub Release):
   ```bash
   curl --proto '=https' --tlsv1.2 -LsSf \
     https://github.com/smorinlabs/rs-launch-blueprint/releases/latest/download/rs-launch-blueprint-installer.sh | sh
   ```
3. `cargo install --locked rs-launch-blueprint` (source compile from crates.io)

### Updating `dist-workspace.toml`

`dist-workspace.toml` sets `allow-dirty = ["ci"]` so our R08/R09/R20/zizmor-hardened
`.github/workflows/release.yml` is preserved. Verify changes locally with `dist plan` (using
`cargo-dist` `0.33.0`); pull requests also run `dist plan` automatically in `release.yml`.

---

## 4. Public Container Publishing (`GHCR`, Owner Override `1a-A` of `R51`)

> **Governance record:** On 2026-11-27, owner review-gate ruling **`1a-A`**
> (`docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md`) formally approved an
> **OVERRIDE of `R51` member 5** (which originally limited container support to a checked-in,
> CI-verified `Dockerfile` with no registry push) to publish the `rslbp-serve` image to GHCR on
> stable releases for full parity with `py-launch-blueprint` `v4.2.0` (`PR #529`, `#606`).

- **Registry image:** `ghcr.io/smorinlabs/rs-launch-blueprint` (stamped children publish under their
  own lowercase `ghcr.io/<owner>/<repo>`).
- **Supported platform:** `linux/amd64` (multi-stage distroless image from `Dockerfile`, running as
  `nonroot:nonroot` on port `8000`).

| Reference   | Meaning                                                                                                                                                |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `:X.Y.Z`    | Immutable image for published stable release `vX.Y.Z`. Existing tags are never overwritten; reruns reuse, re-verify labels/digest, and re-smoke-test.  |
| `:latest`   | Highest numeric stable `X.Y.Z` tag in GHCR, promoted by copying the exact manifest bytes without rebuilding (refuses regressions or digest conflicts). |
| `@sha256:…` | Immutable manifest digest recorded in the workflow output and `$GITHUB_STEP_SUMMARY`. Prefer digest pinning for deployments.                           |

Draft releases, prereleases, and standalone tag pushes do not publish containers. Pull requests and
merge queues continue to verify local container builds and runtime smoke checks via
`.github/workflows/docker-web.yml` without registry credentials.

### First Public GHCR Publication

GHCR creates new container packages as **Private** even for public repositories. The first stable
release run can therefore push `:X.Y.Z` successfully and then fail its anonymous pull check:

1. Open the repository on GitHub, select the container under **Packages**, and open **Package settings**.
2. Under **Danger Zone**, click **Change visibility**, choose **Public**, and confirm. (If an
   organization policy blocks public packages, an organization owner must enable it first.)
3. Rerun the failed `publish-container` workflow run from that release's Actions tab. It will reuse
   the uploaded `:X.Y.Z` manifest, pass anonymous pull verification, and promote `:latest`.

---

## 5. Required Credentials, Variables & GitHub Environments

Every workflow that relies on optional secrets uses a `credential-preflight` job so forks and
unprovisioned repositories stay green instead of failing on missing secrets.

| Surface                                      | Credential / Setting                                                                  | Required Permissions / Scope                                                                                    | Notes                                                                                                                                                                                                                                      |
| -------------------------------------------- | ------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `release-please.yml` & `release.yml` undraft | **GitHub App (preferred):** `RELEASE_PLEASE_CLIENT_ID` + `RELEASE_PLEASE_PRIVATE_KEY` | Repository **Contents: Read & Write**, **Pull requests: Read & Write**                                          | Mints short-lived installation token via `actions/create-github-app-token@v3`. Required so tags trigger `publish.yml`/`release.yml` and undrafting triggers `publish-container.yml`. `GITHUB_TOKEN` is never used by `release-please.yml`. |
| `release-please.yml` & `release.yml` undraft | **Fallback PAT:** `RELEASE_PLEASE_APP_TOKEN`                                          | Fine-grained PAT scoped to repo with **Contents** + **Pull requests: write**                                    | Used only if the GitHub App secrets are unset.                                                                                                                                                                                             |
| `publish.yml` (crates.io)                    | **GitHub Environment:** `crates-io`                                                   | Configure required reviewers if manual approval before upload is desired                                        | Must match the environment name configured on crates.io Trusted Publishing.                                                                                                                                                                |
| `publish.yml` (crates.io, preferred)         | **OIDC Trusted Publishing:** repo variable `CRATES_IO_TRUSTED_PUBLISHING=true`        | Register this repo, workflow `publish.yml`, and environment `crates-io` on crates.io for all 4 workspace crates | Mints a short-lived token via `rust-lang/crates-io-auth-action` (`id-token: write`); no long-lived token stored.                                                                                                                           |
| `publish.yml` (crates.io, fallback)          | **Token secret:** `CRATES_IO_TOKEN`                                                   | crates.io API token with `publish-new` / `publish-update` scope                                                 | Used only if `CRATES_IO_TRUSTED_PUBLISHING` is not `true`.                                                                                                                                                                                 |
| `publish-container.yml` (GHCR)               | Automatic `GITHUB_TOKEN`                                                              | Job-scoped `contents: read` + `packages: write`                                                                 | No stored GHCR secret needed. Flip package visibility to **Public** after the first push.                                                                                                                                                  |

### Opting Out (Downstream Projects)

- To disable PR-driven release automation, delete `.github/workflows/release-please.yml`.
- To disable crates.io publishing, delete `.github/workflows/publish.yml`.
- To disable pre-built binary releases, delete `.github/workflows/release.yml` and
  `dist-workspace.toml`.
- To disable GHCR container publishing while keeping PR container verification, delete
  `.github/workflows/publish-container.yml` and `scripts/publish_container.py`.
