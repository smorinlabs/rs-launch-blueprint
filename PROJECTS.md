# PROJECTS.md — rs-launch-blueprint

## [~] Project P01: Port research program (v0.1.0)
**Goal/Requirement**: Decide, with evidence, what a Rust launch blueprint inherits from py-launch-blueprint and ts-launch-blueprint, what gets a Rust tool substituted, and what (rarely) overrides the shared pattern — ending with a research index and one deep-research prompt per open item.
- Presumption of reuse; overrides labeled `OVERRIDE (OV-nn)` with argument and options
- Target shape: CLI + library + web service
- Design: `docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md`

**Out of Scope**
- Executing the research prompts
- `cargo init` or any Rust code
- The port contract (`rust_port_process_prompt.md` / `goal.md`)

### Tests & Tasks
- [x] [P01-T01] Shell repo: README, LICENSE, PROJECTS.md, AGENTS.md, docs/port/README.md, spec; pushed to smorinlabs/rs-launch-blueprint
- [x] [P01-TS01] `scripts/check-research-tree.sh` written first; proven green on a valid fixture and red on orphan prompt, missing section, out-of-set verdict, dangling OV id, missing Options
- [ ] [P01-T02] Phase 1 — 12 area survey agents produce `docs/port/areas/<area>.md` (no verdicts)
- [ ] [P01-T03] Phase 2 — `docs/port/COMMONALITY.md` with verdicts and OV arguments; derive `PY_INVENTORY.md`, `TS_INVENTORY.md`
- [ ] [P01-T04] Phase 3 — `research/CLAUDE.md` index + one `<slug>.prompt.md` per SUBSTITUTE / OVERRIDE / DIVERGENT / RUST-ONLY row
- [ ] [P01-TS02] `scripts/check-research-tree.sh` green on the real tree
- [ ] [P01-TS03] Phase 4 — independent reviewer agent spot-checks ≥15 `COMMON → REUSE` rows against both repos and reads every OVERRIDE argument adversarially; findings fixed
- [ ] [P01-T05] Phase 5 — PR reviewed by owner, merged, `pull --ff-only`, worktree removed; tag v0.1.0
- [ ] Regression Test Status

### Deliverable
```bash
$ scripts/check-research-tree.sh
OK: research tree structure valid
$ grep -c '^| R' research/CLAUDE.md     # one row per research item
```

### Automated Verification
- `scripts/check-research-tree.sh` exits 0

### Manual Verification
- Every `OVERRIDE` row in `COMMONALITY.md` reads as a genuine Rust-specific argument, not a preference
