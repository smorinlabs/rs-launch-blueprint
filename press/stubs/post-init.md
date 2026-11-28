# Post-Initialization Checklist

This repository was stamped from the Rust launch blueprint and verified by
Template Press. Record of the stamping run lives in `press/press-receipt.toml`.

Complete the remaining human-only repository configuration in
[PROJECT_SETUP.md](PROJECT_SETUP.md):

1. Configure GitHub Actions secrets and environments (Release Please, crates.io,
   optional AI review keys, and optional Contributors Please credentials).
2. Enable GitHub Pages (Source: GitHub Actions) if publishing documentation.
3. Disable GitHub Code Scanning default setup so `.github/workflows/codeql.yml`
   runs without conflicts.
4. Configure branch rulesets on `main` requiring `ci-ok` and `press-verify`,
   with squash merges disabled (`allow_squash_merge=false`).
5. Replace the starter `README.md`, `PROJECTS.md`, and `.github/SECURITY.md`
   with project-specific details.
