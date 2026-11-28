# Bootstrap Provenance

This repository was created and initialized using the Template Press Rust
bootstrap workflow.

- **Stamping receipt:** [`press/press-receipt.toml`](../../press/press-receipt.toml)
- **Active identity manifest:** [`press/press-source.toml`](../../press/press-source.toml)
- **Remaining repository setup:** [`docs/PROJECT_SETUP.md`](../PROJECT_SETUP.md)

The bootstrap skill itself was retired during stamping so it does not trigger
re-initialization inside this project. To verify that no template identity tokens
have drifted back into the repository, run `press verify` (also enforced in CI by
`.github/workflows/press-verify.yml`).
