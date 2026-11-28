# P12 — Template Press bootstrap skill and community files

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
- **Spec:** [RS implementation roadmap design](../docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md)
- **Plan:** [Rex serial chain contract](../docs/superpowers/plans/2026-11-27-rex-serial-chain-contract.md)
- **Depends on:** P11
- **Prior art:** [R07 contributors-bot-trigger-cadence](../research/topics/07-contributors-bot-trigger-cadence/DECISION.md)
- **Prior art:** [R15 template-drift-receipt-guard](../research/topics/15-template-drift-receipt-guard/DECISION.md)
- **Prior art:** [R21 contributors-bot-credential-source](../research/topics/21-contributors-bot-credential-source/DECISION.md)
- **Prior art:** [R47 contributors-recipe-mode](../research/topics/47-contributors-recipe-mode/DECISION.md)

**Status:** `[x]` completed.

### Scope
Deliver the full `template-press` stamping subsystem, global + project-scoped `new-rust-project` bootstrap skill, end-to-end stamped child-project acceptance test, and repository community governance files:
- `template-press` (`4.1+`, `R15` + py `P07`/`#618`): `press/press-source.toml`, `press/press-rules.toml` (including `[rules] keep_names = ["smorinlabs/difftree-action"]` so stamped children inherit `.github/workflows/difftree-pr-comment.yml` intact, plus `[[remove]]` for template-only research/planning/chain artifacts and `[[reset]]` via `press/stubs/*`), `.github/workflows/press-verify.yml`, `.github/workflows/template-receipt-guard.yml`, and `.github/workflows/bootstrap-acceptance.yml`.
- Global + project-scoped `.claude/skills/new-rust-project/SKILL.md` + `README.md` (mirroring `py-launch-blueprint`'s `new-python-project` `PR #616`), symlinked under `.agents/skills/new-rust-project`, plus `docs/PROJECT_SETUP.md` (human checklist for secrets, Pages, branch ruleset, crates.io, GHCR) and `docs/POST_INIT.md`.
- Community & contributors automation: `.github/CONTRIBUTING.md` (with `R45` re-review instructions, no PR-template bot `@`-mentions), `.github/CODE_OF_CONDUCT.md`, `.github/SECURITY.md`, `.github/CODEOWNERS`, `.github/ISSUE_TEMPLATE/{bug,feature,docs}.yml`, `.github/pull_request_template.md` (`R45`), `.contributors.yml`, `CONTRIBUTORS.md`, `.github/workflows/update-contributors.yml` (`R07`, `R21`), and `just update-contributors` (`R47`).

### Out of scope
- Full `mdBook` documentation corpus, `EXAMPLECLI.md`, `EXAMPLEWEB.md`, and final 360-row parity audit (`P13`)

### Tests & Tasks
- [x] [P12-TS01] Add bootstrap & press acceptance tests verifying `template-press verify` passes, stamping a fresh child repo into a temp dir rebrands `rs-launch-blueprint`/`rslbp`, keeps `difftree-pr-comment.yml`, strips template-only dirs, and passes `just check` in the stamped child (`R15`, py `P07`/`#616`/`#618`)
- [x] [P12-T01] Author `press/press-source.toml`, `press/press-rules.toml`, and `press/stubs/*` (readme, post-init, projects, security, docs-index, bootstrap-provenance, retired-bootstrap)
- [x] [P12-T02] Author `.github/workflows/press-verify.yml`, `template-receipt-guard.yml`, and `bootstrap-acceptance.yml`
- [x] [P12-T03] Author global + project-scoped `.claude/skills/new-rust-project/SKILL.md` + `.agents/skills/new-rust-project` symlink, `docs/PROJECT_SETUP.md`, and `docs/POST_INIT.md`
- [x] [P12-T04] Author `.github/CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CODEOWNERS`, issue templates, `pull_request_template.md` (`R45`), `.contributors.yml`, `update-contributors.yml` (`R07`, `R21`), and `just update-contributors` (`R47`)
- [x] [P12-T05] Verify `press verify`, bootstrap acceptance test (stamped child `just check`), `actionlint`, `zizmor`, and live PR `ci-ok` all pass green

### Deliverable
```bash
uvx --from template-press press verify
just check
```

### Automated Verification
- `press verify` exits 0 with zero undeclared template leaks
- End-to-end bootstrap acceptance test stamps a clean child repo (with `difftree-pr-comment.yml` preserved) and passes `just check`
- `actionlint`, `zizmor`, and live PR `ci-ok` pass green

### Manual Verification
- Walk through `.claude/skills/new-rust-project/SKILL.md` and `docs/PROJECT_SETUP.md` to confirm every placeholder and command is accurate
