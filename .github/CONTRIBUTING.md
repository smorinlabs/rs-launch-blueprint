# Contributing to Rs Launch Blueprint

Thank you for contributing! This guide covers local setup, quality gates,
commit conventions, and how pull-request reviews work in this repository.

## Development setup

Bootstrap the base Rust toolchain and `just`, install pinned dev tools and git
hooks, and run the full verification suite:

```bash
make bootstrap
just setup
just check
```

Useful day-to-day commands:

- `just --list` — list all task recipes
- `just format` — format Rust (`rustfmt`) and non-Rust (`dprint`) files
- `just check` — run formatting, security, hygiene, ShellCheck, Clippy,
  typecheck, nextest/doctest, and `cargo deny`
- `just check-packaging` — verify packed `.crate` contents and metadata
- `just debug-info` — collect environment and toolchain versions for bug reports
- `make hook-check` — inspect local pre-commit hook tool availability

## Commit message conventions

Commits are validated locally by `lefthook` (`committed`) and in CI by
`commitlint.yml`. Follow [Conventional Commits](https://www.conventionalcommits.org/):

- Format: `<type>(<optional scope>): <description>`
- Allowed types: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`,
  `refactor`, `revert`, `style`, `test`
- Header length: maximum 50 characters, no trailing period
- Body and footer lines: wrap at 72 characters

## Pull requests

1. Branch from `main` and keep changes focused on a single concern.
2. Run `just check` locally before opening or updating your PR.
3. Ensure `ci-ok` and `press-verify` are green before requesting merge.
4. This repository uses merge commits (squash merges are disabled).

## Requesting another review

Automated AI review runs when a pull request is first opened and does **not**
re-run automatically on subsequent pushes.

- To request a follow-up review after addressing feedback, post a PR comment
  containing `@claude please re-review`.
- Review and mention workflows use an R18 credential-presence preflight checking
  `ANTHROPIC_API_KEY`, `CLAUDE_CODE_OAUTH_TOKEN`,
  `ANTHROPIC_FEDERATION_RULE_ID`, and `ANTHROPIC_ORGANIZATION_ID`; when none are
  configured, the workflow skips cleanly without failing CI. Repositories that
  want to opt out completely can delete `.github/workflows/claude.yml`.
- Only repository `OWNER`, `MEMBER`, and `COLLABORATOR` authors pass the
  author-association prefilter for automated comment triggers.

## Code of Conduct

Participation in this project is governed by the
[Code of Conduct](CODE_OF_CONDUCT.md). Security vulnerabilities should be
reported privately per [SECURITY.md](SECURITY.md).
