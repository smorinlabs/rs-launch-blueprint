# P10 — GitHub Actions CI security and AI workflows

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
- **Spec:** [RS implementation roadmap design](../docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md)
- **Plan:** [Rex serial chain contract](../docs/superpowers/plans/2026-11-27-rex-serial-chain-contract.md)
- **Depends on:** P09
- **Prior art:** [R11 ci-workflow-job-structure](../research/topics/11-ci-workflow-job-structure/DECISION.md)
- **Prior art:** [R12 aggregate-required-status-check](../research/topics/12-aggregate-required-status-check/DECISION.md)
- **Prior art:** [R18 ai-assisted-review-workflows](../research/topics/18-ai-assisted-review-workflows/DECISION.md)
- **Prior art:** [R86 codex-assisted-review-workflows](../research/topics/86-codex-assisted-review-workflows/DECISION.md)

**Status:** `[ ]` scoped, not started.

### Scope
Build the full GitHub Actions CI, security scanning, freshness canary, Dependabot, and AI review/triage workflow suite:
- Unified `.github/workflows/ci.yml` (`R11`, `R12`, `R08`, `R09`, `R10`, `R20`, `R50`, py `P10`/`P12`):
  - Tier 0 `plan` fail-closed change detector (`code`, `web`, `workflows`, `docs`, plus release-please version-bump fast-path per py `P12`).
  - Tier 1 `hygiene` (fmt, dprint, ast-grep, typos, shellcheck, action-pin comment check, `zizmor`, linkcheck slot) and `workflow-lint` (`actionlint`, `zizmor`, gated on `workflows`).
  - Tier 2 `check` OS matrix (`ubuntu-latest`, `macos-latest`) with `Swatinem/rust-cache` (`env-vars: ImageOS`), running clippy (feature-off & `--all-features`), no-default-features facade check, nextest feature-off, nextest `--all-features` (exercising `web`, `otel`, `metrics`), serve build, and `cargo doc` (`-D warnings`).
  - `msrv-floor` (`ubuntu-latest` declared `rust-version`), `install-smoke` (`R50`), coverage upload (`R35`), and always-on aggregate required check `ci-ok` (`R12`).
- Security & contract workflows: `dep-audit.yml` (`cargo-audit`, `cargo-deny`, OSV, `R13`), `dependency-review.yml`, `codeql.yml` + `.github/codeql/codeql-config.yml` (`R16`), `secret-scan.yml` (TruffleHog OSS CLI, `R17`), `large-file-guard.yml` (`R14`), `commitlint.yml` (`committed`, `R38`), `api-contract.yml` (`openapi.json` drift + `oasdiff`, `R71`), `docker-web.yml` (`R51`), `canary.yml` (weekly 3-leg freshness, `R34`), and 2-entry `.github/dependabot.yml` (`cargo` + `github-actions`, `R19`).
- AI review & triage workflows: `claude-code-review.yml` + `claude.yml` (`R18`), Codex PR review + `/codex` assistant (`R86`), and Muse `audit-triage.yml` (owner decision `1b-A`, `muse-spark-1.3-contributor`, credential-preflight gated on `META_MUSE_CI_API_KEY`).
- All non-`actions/`/`github/` actions full-SHA pinned with version comments (`R20`), uniform top-level `permissions: {}` with commented job re-grants (`R08`), and literal `ubuntu-latest`/`macos-latest` runners (`R09`).

### Out of scope
- `release-please.yml`, `publish.yml`, `publish-container.yml` (`P11`)
- `press-verify.yml`, `template-receipt-guard.yml`, `bootstrap-acceptance.yml`, `update-contributors.yml` (`P12`)
- Anthropic OSS Scanner enrollment (deferred post-`P13` per owner decision `1c-A`)

### Tests & Tasks
- [ ] [P10-TS01] Add workflow meta-tests validating top-level `permissions: {}` (`R08`), full-SHA action pinning + release comments (`R20`), `plan` path-filter fail-closed cases (`R11`), `ci-ok` coverage of all `ci.yml` jobs (`R12`), and credential-preflight gating on all AI/triage workflows (`R18`, `R86`, `1b-A`)
- [ ] [P10-T01] Author `.github/workflows/ci.yml` (`plan`, `hygiene`, `workflow-lint`, OS-matrix `check` incl. `--all-features`/OTel leg, `msrv-floor`, `install-smoke`, `ci-ok`) and retire standalone `shellcheck.yml` once covered by `hygiene`
- [ ] [P10-T02] Author security & contract workflows (`dep-audit.yml`, `dependency-review.yml`, `codeql.yml` + `.github/codeql/codeql-config.yml`, `secret-scan.yml`, `large-file-guard.yml`, `commitlint.yml`, `api-contract.yml`, `docker-web.yml`, `canary.yml`) and `.github/dependabot.yml`
- [ ] [P10-T03] Author AI review & triage workflows (`claude-code-review.yml`, `claude.yml`, `codex-code-review.yml`, `codex.yml`, and Muse `audit-triage.yml` + `.github/muse-audit-triage/` policy) with credential-preflight gating
- [ ] [P10-T04] Verify `actionlint`, `zizmor`, SHA-pin comment check, workflow meta-tests, and live GitHub Actions PR checks (including `ci-ok`) all pass green

### Deliverable
```bash
actionlint
zizmor .github/workflows/
just check
```

### Automated Verification
- `actionlint` and `zizmor` exit 0 with zero findings
- All workflow meta-tests pass
- Live GitHub Actions PR run finishes green with `ci-ok` passing and AI workflows skipping cleanly when secrets are absent

### Manual Verification
- Confirm `ci-ok` appears as a single clean status check on the PR ready for branch-protection ruleset binding
