# P01 — Port research program

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
- **Design:** [RS port research program design](../docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md)
- **Plan:** [P01 research tree plan](../docs/superpowers/plans/2026-09-01-p01-research-tree.md)

**Status:** `[x]` shipped as `v0.1.0` (annotated tag `fd5e839`, 2026-09-05).

**Goal/Requirement**: Prepare evidence-based research that captures the shared engineering principles and agreement levels, then evaluates the Rust architectures and libraries that best preserve them — ending with a research index and one deep-research prompt per open item.
- Principles and agreement levels explicit (spec §2/A5); departures from recorded patterns labeled `OVERRIDE (OV-nn)` with argument and options
- Target shape: CLI + library + web service
- Plan tasks: Tasks 1–18 = Phases 1–5

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
- [x] [P01-T02] Phase 1 — 13 area survey agents, batches of 3–4, produce `docs/port/areas/<area>.md` (no verdicts; cross-area parameters as slugs; files read listed)
- [x] [P01-T03] Phase 2 — one area at a time then a reconciliation pass: `docs/port/COMMONALITY.md` (ID · Feature · Area · Origin · Verdict · Item · Notes; OV arguments), `PARAMETERS.md` (fixed values set by owner), `COVERAGE.md` (no uncovered file), `PY_INVENTORY.md`, `TS_INVENTORY.md`
- [x] [P01-T04] Phase 3 — `research/CLAUDE.md` index, `research/RUNBOOK.md`, one `<slug>.prompt.md` per item (crate / pattern / bundle)
- [ ] [P01-TS07] Phase 3 conformance pilot — after the first two prompts, one `/deep-research` run checked only for filling the answer template; content discarded — deferred 2026-09-02 to P02-T01 (`/deep-research` is owner-typed only; Doxa is paid); `scripts/check-answer-shape.sh` shipped by Task 14
- [x] [P01-TS02] `scripts/check-research-tree.sh` green on the real tree
- [x] [P01-T07a] Phase 3.5 input — `docs/port/DIVERGENCE-ANALYSIS.md`: one row per research item giving the py state, the ts state, why they differ (cause class A–G), the Rust question, and the original cross-repo comparison scope (`harmonize`); feeds `OWNER-REVIEW.md`. Amendment A5 replaces the original one-value question with explicit agreement levels and evidence-backed native designs
- [x] [P01-T07] Phase 3.5 — owner technology-selection review: `docs/port/OWNER-REVIEW.md`, one row per item (not waivable); `scripts/check-research-tree.sh --require-owner-review` green
- [x] [P01-TS03] Phase 4 — independent reviewer agent spot-checks ≥15 `COMMON → REUSE` rows and sampled `path:line` citations against both repos, confirms `COVERAGE.md` complete, reads every non-REUSE row adversarially; findings fixed
- [x] [P01-T05] Phase 5 — PR reviewed and merged; `v0.1.0` created and pushed 2026-09-05 under the owner's explicit authorization (annotated tag `fd5e839`, peeled to merge commit `2f3569051af2c2089f60f6cad129bc6e55482c30`, verified on origin). `rs-launch-blueprint-research` and its untracked handoffs retained as the approved cleanup exception.
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
