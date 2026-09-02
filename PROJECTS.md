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
- [x] [P01-T06] Review how the TS port researched (`docs/port/ts-research-method-review.md`); fold R1–R8 into the spec: couplings ownership, owner review Phase 3.5, empirical gate, dual audits, extended answer template, framing, dormancy, batched fan-out
- [x] [P01-TS04] Check script extended for 8 prompt sections, single-owner couplings, consumed-parameter resolution, resolved→audit files; proven red on each
- [x] [P01-TS05] Adversarial review of the revised spec by Codex (different model family); 25 findings triaged — 24 folded (spec §12), 1 rejected by owner (prior art; D6 kept)
- [x] [P01-TS06] Check script v3: process-substitution loops (exit status trustworthy), header-name column lookup, exact ordered H2 list outside fences, parameter registry, ledger↔index bijection, origin→verdict legality, owner-review flag; `scripts/test-check-research-tree.sh` 53/53 green
- [ ] [P01-T02] Phase 1 — 13 area survey agents, batches of 3–4, produce `docs/port/areas/<area>.md` (no verdicts; cross-area parameters as slugs; files read listed)
- [ ] [P01-T03] Phase 2 — one area at a time then a reconciliation pass: `docs/port/COMMONALITY.md` (ID · Feature · Area · Origin · Verdict · Item · Notes; OV arguments), `PARAMETERS.md` (fixed values set by owner), `COVERAGE.md` (no uncovered file), `PY_INVENTORY.md`, `TS_INVENTORY.md`
- [ ] [P01-T04] Phase 3 — `research/CLAUDE.md` index, `research/RUNBOOK.md`, one `<slug>.prompt.md` per item (crate / pattern / bundle)
- [ ] [P01-TS07] Phase 3 conformance pilot — after the first two prompts, one `/deep-research` run checked only for filling the answer template; content discarded
- [ ] [P01-TS02] `scripts/check-research-tree.sh` green on the real tree
- [ ] [P01-T07] Phase 3.5 — owner technology-selection review: `docs/port/OWNER-REVIEW.md`, one row per item (not waivable); `scripts/check-research-tree.sh --require-owner-review` green
- [ ] [P01-TS03] Phase 4 — independent reviewer agent spot-checks ≥15 `COMMON → REUSE` rows and sampled `path:line` citations against both repos, confirms `COVERAGE.md` complete, reads every non-REUSE row adversarially; findings fixed
- [ ] [P01-T05] Phase 5 — PR reviewed by owner, merged, `pull --ff-only`, worktree removed; tag v0.1.0
- [ ] Regression Test Status

### Deliverable
```bash
$ scripts/check-research-tree.sh --require-owner-review
OK: research tree structure valid
$ scripts/test-check-research-tree.sh | tail -1
53 passed, 0 failed
```

### Automated Verification
- `scripts/check-research-tree.sh --require-owner-review` exits 0
- `scripts/test-check-research-tree.sh` exits 0

### Manual Verification
- Every `OVERRIDE` row in `COMMONALITY.md` reads as a genuine Rust-specific argument, not a preference
