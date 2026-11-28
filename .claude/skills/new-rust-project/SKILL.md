---
name: new-rust-project
description: Bootstrap a new Rust CLI, library, and optional web repository from smorinlabs/rs-launch-blueprint using Template Press, verify all workspace gates, and open the initialization PR.
---

# New Rust Project Bootstrap

Create and initialize a new Rust workspace repository from
`smorinlabs/rs-launch-blueprint`, rebrand every identity token deterministically
with Template Press, verify all workspace quality and packaging gates, and open
the initialization pull request.

## Safety guardrails

Before changing any files:

1. **Never run stamping inside the blueprint repository itself.** Verify that
   `git remote get-url origin` does **not** point to
   `smorinlabs/rs-launch-blueprint`.
2. **Never re-stamp an already stamped repository.** If
   `press/press-receipt.toml` already exists, stop and direct the user to
   `docs/PROJECT_SETUP.md`.
3. **Never commit `press/press-answers.toml` or `.venv/`.** Both are
   gitignored transient files; remove them before committing.
4. **Always commit `press/press-receipt.toml` in the stamped child repository.**
   The receipt arms `.github/workflows/press-verify.yml` so CI continuously
   guards against template identity drift.

## Step 1 — Gather project identity

Collect and confirm all seven Template Press identity fields with the user:

- `repo_name` — GitHub repository and root Cargo package name in kebab-case
  (for example, `harbor-sample`)
- `package_name` — Rust library crate target name in snake_case, equal to
  `repo_name` with `-` replaced by `_` (for example, `harbor_sample`)
- `app_name` — primary CLI executable name (short, lowercase, word-disjoint,
  for example `harborctl`; optional web binary becomes `<app_name>-serve`)
- `owner` — GitHub organization or user owning the new repository
- `author` — primary author or organization display name for `Cargo.toml`
- `email` — contact email for `Cargo.toml`
- `display_name` — human-readable project title (for example, `Harbor Sample`)
- Visibility — `--public` or `--private`

Validate before continuing:

- `package_name` equals `repo_name` with `-` replaced by `_` and starts with an
  ASCII letter.
- `app_name` matches `^[a-z][a-z0-9-]*$` and does not collide with common Rust
  keywords or shell built-ins.

## Step 2 — Verify local prerequisites

Confirm the required tools are installed and authenticated:

```bash
gh auth status
git --version
uv --version
rustc --version
cargo --version
just --version
make --version
```

If `rustup`, `cargo`, or `just` is missing, run `make bootstrap` after cloning.

## Step 3 — Create and clone the new repository from the template

Instantiate the new repository directly from `smorinlabs/rs-launch-blueprint`:

```bash
gh repo create <owner>/<repo_name> \
  --template smorinlabs/rs-launch-blueprint \
  --private \
  --clone
cd <repo_name>
```

(Pass `--public` instead of `--private` when requested.)

Verify this is a fresh, unstamped repository on default branch `main` (both
`.github/workflows/ci.yml` and `.github/workflows/press-verify.yml` run
`pull_request` checks targeting `main`; if your organization creates new
repositories with a different default branch, rename it to `main` first):

```bash
test ! -f press/press-receipt.toml
test "$(git symbolic-ref --short HEAD)" = "main"
```

Create an initialization branch off `main` so `main` stays clean for PR review:

```bash
git switch -c chore/initialize-template
```

## Step 4 — Fetch Cargo cache and provision pinned Template Press (`template-press==5.0.0`)

Pre-populate the local Cargo registry cache from the committed `Cargo.lock` so
Template Press's offline `cargo update --workspace --offline` regeneration
succeeds even on a machine with an empty Cargo cache:

```bash
cargo fetch --locked
```

Install the hash-pinned `template-press==5.0.0` release declared in
`press/requirements.txt` into a local virtual environment:

```bash
uv venv --python 3.13 .venv
uv pip sync --python .venv/bin/python press/requirements.txt
.venv/bin/press check-tools --target .
```

## Step 5 — Preview clean and rebrand (`--dry-run`)

Write the transient `press/press-answers.toml` file (gitignored):

```toml
[answers]
package_name = "<package_name>"
repo_name = "<repo_name>"
app_name = "<app_name>"
author = "<author>"
email = "<email>"
owner = "<owner>"
display_name = "<display_name>"
```

Preview both cleanup and rebrand without mutating tracked files:

```bash
.venv/bin/press clean --target . --show
.venv/bin/press rebrand --target . --config press/press-answers.toml --dry-run
git status --short
```

Confirm `git status --short` is empty after `--dry-run`.

## Step 6 — Apply Template Press clean and rebrand

Apply cleanup and rebranding, regenerate `Cargo.lock` offline, write
`press/press-receipt.toml`, and remove transient files:

```bash
.venv/bin/press clean --target .
.venv/bin/press rebrand --target . --config press/press-answers.toml
rm -f press/press-answers.toml
```

Verify the generated receipt records `verified = true` and the exact target
identity:

```bash
cat press/press-receipt.toml
```

## Step 7 — Run setup, formatting, verification, and packaging gates

Restore the empty `projects/` directory, install pinned dev tools and git hooks,
format, and run every read-only quality and packaging gate:

```bash
just setup
just format
git add --all
git diff --cached --check
just check
just lib-check
just check-packaging
.venv/bin/press verify --target .
rm -rf .venv
```

## Step 8 — Smoke-test the standalone library, CLI, and optional web service

`just lib-check` (above) already verifies downstream consumption of the standalone
library crate (`<repo_name>`) under default and `--no-default-features`. If the
new repository is **library-only**, follow the opt-out steps in
`docs/RELEASE.md` to drop `crates/cli` and/or `crates/web`.

Verify both compiled binary entrypoints under the rebranded binary names:

```bash
cargo run --locked --bin <app_name> -- --version
cargo run --locked --bin <app_name> -- --help
```

Start the optional web service on an ephemeral local port and verify `/healthz`:

```bash
cargo run --locked -p <repo_name>-web --bin <app_name>-serve
```

In a separate check (or by binding an explicit free port such as
`127.0.0.1:18080`), verify `curl -fsS http://127.0.0.1:18080/healthz` returns
HTTP 200 with `"status":"ok"`, then stop the server with `SIGINT`/`SIGTERM`.

## Step 9 — Commit, push, open initialization PR, and hand off setup

Commit the stamped repository state with a Conventional Commit message (note
`press/press-receipt.toml` is intentionally included):

```bash
git add --all
git commit -m "chore: initialize repository from template"
git push -u origin chore/initialize-template
gh pr create \
  --base main \
  --title "chore: initialize repository from template" \
  --body "Stamps the repository with Template Press and verifies \`just check\`, \`just check-packaging\`, and \`press verify\`."
```

Wait for `ci-ok` and `press-verify` to pass on the PR, then hand the user
[`docs/PROJECT_SETUP.md`](../../../docs/PROJECT_SETUP.md) to complete
human-only repository settings (secrets, branch protection rulesets, crates.io,
GHCR visibility, GitHub Pages, and Code Scanning setup).
