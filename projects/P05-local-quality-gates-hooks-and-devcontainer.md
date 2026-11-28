# P05 — Local quality gates hooks and devcontainer

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
- **Spec:** [RS implementation roadmap design](../docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md)
- **Plan:** [Rex serial chain contract](../docs/superpowers/plans/2026-11-27-rex-serial-chain-contract.md)
- **Depends on:** P04
- **Prior art:** [R29 non-code-file-formatting](../research/topics/29-non-code-file-formatting/DECISION.md)
- **Prior art:** [R31 standalone-security-analyzer](../research/topics/31-standalone-security-analyzer/DECISION.md)
- **Prior art:** [R37 hook-manager-distribution](../research/topics/37-hook-manager-distribution/DECISION.md)
- **Prior art:** [R38 commit-message-linter](../research/topics/38-commit-message-linter/DECISION.md)

**Status:** `[x]` completed (2026-11-27).

### Scope
Wire all local developer hygiene, git hooks, non-code formatting, static security rules, lockfile/large-file guards, DevContainer, and AI/editor furniture:
- `lefthook.yml` pinned to `lefthook 2.1.14` (`R37`), replacing the interim `.githooks/pre-commit` while preserving ShellCheck staged-file verification.
- `committed.toml` (`committed 1.1.11`, `R38`: 11 Conventional Commits types, 50/72/72 soft-line caps).
- `.gitleaks.toml` + `gitleaks 8.30.1` at pre-commit and pre-push (`R39`).
- `dprint.json` (`dprint 0.57.4`) with 4 checksum-pinned Wasm plugins for TOML, YAML, JSON, and Markdown (`R29`), wired into `Justfile` and `lefthook`.
- `ast-grep` (`0.45.3`, `R31`) with 5 template-owned `severity: error` security rules + positive/negative rule self-tests wired into `just security` and pre-commit.
- `scripts/check-large-files.sh` (>1 MiB, `.gitattributes` `large-file-ok`, `R14`), conditional unlocked `Cargo.lock` freshness check (`R41`), `.editorconfig` + `typos` auxiliary hooks (`R40`).
- Image-only `.devcontainer/devcontainer.json` pinned by index digest (`mcr.microsoft.com/devcontainers/rust:2.1.1-trixie`, `R44`, documenting optional Blaze Linux sandbox flag), `.vscode/` settings/extensions, `.claude/settings.json` `companyAnnouncements` (`R43`, no `.cursor/` or `.windsurf/` rule dirs), and updated `AGENTS.md`/`CLAUDE.md`.

### Out of scope
- CI workflow wiring for these tools (`P10`)
- Application domain, CLI, or web implementation (`P06`–`P09`)

### Tests & Tasks
- [x] [P05-TS01] Add automated tests for `scripts/check-large-files.sh` (over/under 1 MiB + `large-file-ok` exemption), `ast-grep` rule positive/negative fixtures (`R31`), `committed.toml` soft-line cases (`R38`), and lockfile freshness check (`R41`)
      2026-11-27: added `rules/security-tests/*.yml` (5 rule positive/negative fixtures), `scripts/test-check-large-files.sh`, `scripts/test-committed.sh`, `scripts/test-check-cargo-lock.sh`, `scripts/test-security-rules.sh`, and `tests/repo_hygiene.rs` (TDD red verified before implementation)
- [x] [P05-T01] Add `dprint.json` (`R29`), `.editorconfig`, `.gitattributes`, and `typos` config (`R40`) and wire into `Justfile`
      2026-11-27: added `dprint.json` (4 checksum-pinned Wasm plugins verified cold-cache against `plugins.dprint.dev`), `.editorconfig`, `.editorconfig-checker.json` (`v4.0.2`), `.yamllint` (`ryl` + `truthy: error`), `typos.toml`, and `.gitattributes`, formatted non-code template files with `dprint fmt`, and wired `format-files`, `check-files`, and `check-hygiene` into `Justfile`
- [x] [P05-T02] Add `ast-grep` configuration and 5 template-owned security rules (`R31`) plus `just security` recipe
      2026-11-27: added `sgconfig.yml` and 5 `severity: error` rules under `rules/security/` (`rs-shell-invocation`, `rs-sql-format`, `rs-weak-hash`, `rs-tls-verification-disabled`, `rs-predictable-temp`), wired `just security` with zero-file / zero-rule guards (`5 passed; 0 failed`, `215 files, 5 rules, 0 findings`)
- [x] [P05-T03] Add `scripts/check-large-files.sh` (`R14`), `.gitleaks.toml` (`R39`), `committed.toml` (`R38`), and lockfile freshness script (`R41`)
      2026-11-27: added executable POSIX `scripts/check-large-files.sh` (1 MiB blob guard + `large-file-ok`), `.gitleaks.toml` + header-only `.gitleaksignore`, `committed.toml` + `committed.bot.toml` + `.gitmessage`, and `scripts/check-cargo-lock.sh` (unlocked per-root resolve + index parity guard + restore)
- [x] [P05-T04] Add `lefthook.yml` (`R37`) integrating fmt, clippy, dprint, ast-grep, shellcheck, gitleaks, committed, typos, large-file guard, and opt-in pre-push test gate; update `just setup` / `Makefile` hook-check
      2026-11-27: added `lefthook.yml` (`min_version: 2.1.14`, `assert_lefthook_installed: true`, `pre-commit`/`commit-msg`/`pre-push`, `tags: [compiles]`), removed interim `.githooks/pre-commit` and `scripts/install-hooks.sh`, fixed `ubi-cli@0.12.0` bootstrap in `Justfile`, added `_lefthook-pin`/`hooks-install`/`hooks-run`/`hook-check` + `Makefile` report-only `hook-check`, and verified `lefthook run pre-commit` (0.38s) and `LEFTHOOK_EXCLUDE=compiles lefthook run pre-commit --all-files --no-auto-install --no-tty --fail-on-changes` (1.09s)
- [x] [P05-T05] Add `.devcontainer/devcontainer.json` (`R44`), `.vscode/` settings & extensions, verify `.claude/settings.json` (`R43`), and update `AGENTS.md` with canonical `just` commands
      2026-11-27: added digest-pinned image-only `.devcontainer/devcontainer.json` (`2.1.1-trixie` index digest + Blaze Linux sandbox note) + executable `.devcontainer/post-create.sh`, `.vscode/{settings,extensions,launch}.json` (`R28`), updated `.claude/settings.json` single-entry `companyAnnouncements` (`R43`, verified against `just --summary`), and updated `AGENTS.md` with canonical `just` commands and conventions (keeping `CLAUDE.md` as `@AGENTS.md` with zero vendor rule dirs)

### Deliverable
```bash
just check
just security
bash scripts/check-large-files.sh
```

### Automated Verification
- `just check`, `just security`, and `dprint check` exit 0
- `ast-grep test` passes on all positive and negative security rule fixtures
- `scripts/check-large-files.sh` and `committed` regression tests pass
- `bash scripts/check-shell.sh` and `bash scripts/check-research-tree.sh --require-owner-review` exit 0

### Manual Verification
- Run `lefthook run pre-commit` on a sample staged change and confirm all configured jobs execute cleanly
