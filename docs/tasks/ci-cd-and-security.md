# CI/CD and Security Workflows

Every workflow in `.github/workflows/` follows uniform hardening rules (`R08`,
`R09`, `R20`): top-level `permissions: {}` with minimal per-job re-grants,
`persist-credentials: false` on every `actions/checkout`, literal GitHub-hosted
runner labels (`ubuntu-latest` / `macos-latest`), and 40-hex SHA pinning with
version comments (`# vX.Y.Z`) on all third-party actions.

Validate all workflows locally before pushing:

```bash
just check-workflows    # actionlint + zizmor + R08 permissions + R20 pin comments
```

## Main Pull-Request Pipeline (`ci.yml`, `R11`, `R12`)

`ci.yml` never uses trigger-level `paths:` filters (which leave required checks
stuck in `Pending`). Instead, a fast, fail-closed `plan` job computes literal
`true`/`false` outputs (`code`, `web`, `workflows`, `docs`, `release`) so
unrelated jobs skip cleanly and report success:

| Tier   | Job             | Trigger / Condition                                | Purpose                                                                                                                                                      |
| ------ | --------------- | -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Tier 0 | `plan`          | Always                                             | Fail-closed path detector (`--no-renames`) + verified `release-please` fast path.                                                                            |
| Tier 1 | `hygiene`       | Always (no `needs:`)                               | `rustfmt`, `dprint`, `ast-grep`, `editorconfig-checker`, `ryl`, `typos`, ShellCheck, `zizmor`, R08/R20/R14 guards, `lychee --offline`.                       |
| Tier 1 | `workflow-lint` | `workflows == 'true'`                              | `actionlint`, `zizmor`, R09 runner-label guard, R12 `ci-ok` completeness guard.                                                                              |
| Tier 2 | `check`         | `code == 'true'` (`ubuntu-latest`, `macos-latest`) | `cargo-deny`, Clippy (off/web/all), `--no-default-features`, strict `cargo check`, `nextest` (off/web/all), doctests, `rslbp-serve` build, strict `rustdoc`. |
| Tier 2 | `msrv-floor`    | `code == 'true'` (`ubuntu-latest`)                 | Verifies `Cargo.toml` declared `rust-version` (`1.98`) compiles across all targets/features.                                                                 |
| Tier 2 | `install-smoke` | `code == 'true' \|\| release == 'true'`            | `just install-check` (+ `web` leg when `web` or `release` is `true`, `R50`).                                                                                 |
| Tier 2 | `coverage`      | `code == 'true'` (`ubuntu-latest`)                 | `just coverage` (`cargo-llvm-cov`) + artifact upload (`R35`).                                                                                                |
| Gate   | `ci-ok`         | Always (`needs:` every job above)                  | Single required branch-protection check folding all jobs via positive `jq` allow-list (`R12`).                                                               |

## Security & Contract Workflows

- **`dep-audit.yml` (`R13`):** weekly Monday (`05:00 UTC`) `cargo-audit`,
  `cargo-deny`, and OSV-Scanner audit (`weekly-audit`).
- **`dependency-review.yml` (`F046`):** blocks PRs introducing vulnerable Cargo
  dependencies on public repositories.
- **`codeql.yml` (`R16`):** Rust CodeQL (`build-mode: none`, `security-extended`
  via `.github/codeql/codeql-config.yml`), guarded against default-setup
  conflicts and private repos.
- **`secret-scan.yml` (`R17`):** full-history cosign-verified TruffleHog OSS CLI
  (`--only-verified --fail --fail-on-scan-errors`).
- **`large-file-guard.yml` (`R14`) & `commitlint.yml` (`R38`):** PR-range 1 MiB
  blob guard and `committed` Conventional Commits check (with width-relaxed
  `committed.bot.toml` for Dependabot PRs).
- **`manual-pr-security-scan.yml` (`F047`):** environment-gated
  (`security-review`) manual workflow-dispatch security scan.
- **`api-contract.yml` (`R71`) & `docker-web.yml` (`R51`):** `oasdiff`
  breaking-change check against `openapi/openapi.json` and non-root distroless
  container build + `/healthz` + `SIGTERM` `143` smoke tests.
- **`docs.yml` (`R81`) & `canary.yml` (`R34`, `R82`):** `mdbook build` + GitHub
  Pages deployment, weekly freshness canary, and scheduled external URL check.

## Optional AI Review & Audit-Triage Workflows (`R18`, `R86`, `1b-A`)

Every AI workflow uses a positive `credential-preflight` job so repositories and
forks without API secrets stay green and never fail:

- **Claude (`claude-code-review.yml`, `claude.yml`):** automated PR review and
  `@claude` follow-ups when `ANTHROPIC_API_KEY`, `CLAUDE_CODE_OAUTH_TOKEN`, or
  OIDC federation variables are set.
- **Codex (`codex-code-review.yml`, `codex.yml`):** three-job split (`preflight`
  -> `:read-only` `drop-sudo` model job -> credential-free poster job) gated on
  `OPENAI_API_KEY`.
- **Muse Audit Triage (`audit-triage.yml`):** Organization-gated triage of
  `weekly-audit` failures gated on `META_MUSE_CI_API_KEY`.

Delete any unused AI workflow file to opt out permanently. For the full release
pipeline (`release-please.yml`, `publish.yml`, `release.yml`,
`publish-container.yml`), see [Release Process](../RELEASE.md).
