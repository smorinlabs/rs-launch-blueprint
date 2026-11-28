# Post-Initialization Notes

After stamping a new repository from this blueprint with Template Press:

1. Inspect `press/press-receipt.toml` to confirm
   `verified = true` and verify the target identity fields.
2. Work through [`PROJECT_SETUP.md`](PROJECT_SETUP.md) to configure GitHub
   Actions secrets, environments, branch protection rulesets, crates.io
   publishing, GHCR visibility, GitHub Pages, and Code Scanning setup.
3. Run `just setup && just check` locally and verify `ci-ok` and `press-verify`
   are green on the initialization pull request.
