# P13 — Documentation corpus examples and final parity audit

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
- **Spec:** [RS implementation roadmap design](../docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md)
- **Plan:** [Rex serial chain contract](../docs/superpowers/plans/2026-11-27-rex-serial-chain-contract.md)
- **Depends on:** P12
- **Prior art:** [COMMONALITY.md](../docs/port/COMMONALITY.md)
- **Prior art:** [R81 docs-delivery-model](../research/topics/81-docs-delivery-model/DECISION.md)
- **Prior art:** [R82 docs-correctness-gate](../research/topics/82-docs-correctness-gate/DECISION.md)

**Status:** `[ ]` scoped, not started.

### Scope
Deliver the user-facing documentation corpus, `mdBook` + GitHub Pages publishing pipeline, link/rustdoc correctness gates, CLI/Web example guides, and final end-to-end parity audit:
- Single CommonMark/GFM `docs/` corpus rendered natively on GitHub **and** built with `mdbook 0.5.4` (`book.toml`, `docs/SUMMARY.md`) deployed via `.github/workflows/docs.yml` to GitHub Pages (`R81`).
- Documentation correctness gates (`R82`): `lychee 0.24.2` internal/relative link check wired into `ci.yml`'s `hygiene` job, scheduled weekly external link check workflow, and `RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --all-features`.
- Top-level & reference guides matching `py-launch-blueprint`: production `README.md` (badges, quick start, CLI, Web, Blaze local accelerator, Template Press), `EXAMPLECLI.md` (`rslbp` walkthrough), `EXAMPLEWEB.md` (`rslbp-serve` walkthrough), and `docs/about/design-decisions.md` indexing all `R01`–`R86` decisions, approved overrides, and Blaze compatibility.
- Final comprehensive parity audit (`docs/port/FINAL-PARITY-AUDIT.md`) verifying every single one of the 360 `F###` rows in `COMMONALITY.md` + post-`b08bccf` `py-launch-blueprint` `v4.2.0` delta items + Blaze local accelerator status + final human setup checklist (`docs/PROJECT_SETUP.md`).

### Out of scope
- Publishing a public `v1.0.0` release or changing live GitHub repo settings (documented in the final human checklist)
- Anthropic OSS Scanner enrollment (deferred per owner decision `1c-A`)

### Tests & Tasks
- [ ] [P13-TS01] Add documentation verification checks (`mdbook build`, `lychee` internal links, `RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --all-features`, and automated parity-audit script checking all 360 `F###` rows are accounted for)
- [ ] [P13-T01] Configure `book.toml`, `docs/SUMMARY.md`, `.github/workflows/docs.yml` (GitHub Pages deploy), and `lychee` internal/scheduled linkcheck jobs (`R81`, `R82`)
- [ ] [P13-T02] Author `README.md`, `EXAMPLECLI.md`, `EXAMPLEWEB.md`, and `docs/about/design-decisions.md` (covering `R01`–`R86`, Blaze local accelerator, `bacon`, and approved overrides)
- [ ] [P13-T03] Author core `docs/` reference and task pages (architecture, CLI reference, web API reference, config/secrets/logging, testing, CI/CD, Blaze local acceleration, troubleshooting)
- [ ] [P13-T04] Run final 360-row `COMMONALITY.md` + post-`b08bccf` parity audit, write `docs/port/FINAL-PARITY-AUDIT.md`, re-verify `press verify` + stamped child `just check` + `just check` + `blaze test`

### Deliverable
```bash
mdbook build
lychee --offline docs/ README.md EXAMPLECLI.md EXAMPLEWEB.md
RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --all-features
just check
```

### Automated Verification
- `mdbook build`, `lychee` internal link check, and `cargo doc --no-deps --all-features` with `-D warnings` exit 0
- `press verify`, bootstrap acceptance test, `just check`, `actionlint`, `zizmor`, and live PR `ci-ok` all pass green
- `docs/port/FINAL-PARITY-AUDIT.md` accounts for 360/360 `F###` rows + all approved post-`b08bccf` delta items

### Manual Verification
- Review `README.md`, `EXAMPLECLI.md`, `EXAMPLEWEB.md`, and the final human GitHub setup checklist (Pages source, branch protection `ci-ok`, secrets, crates.io, GHCR)
