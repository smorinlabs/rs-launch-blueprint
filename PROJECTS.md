# PROJECTS.md — rs-launch-blueprint

## [x] Project P01: Port research program (v0.1.0)
**Goal/Requirement**: Decide, with evidence, what a Rust launch blueprint inherits from py-launch-blueprint and ts-launch-blueprint, what gets a Rust tool substituted, and what (rarely) overrides the shared pattern — ending with a research index and one deep-research prompt per open item.
- Presumption of reuse; overrides labeled `OVERRIDE (OV-nn)` with argument and options
- Target shape: CLI + library + web service
- Design: `docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md`
- Plan: `docs/superpowers/plans/2026-09-01-p01-research-tree.md` (Tasks 1–18 = Phases 1–5)

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
- [x] [P01-T07a] Phase 3.5 input — `docs/port/DIVERGENCE-ANALYSIS.md`: one row per research item giving the py state, the ts state, why they differ (cause class A–G), the Rust question, and whether the right fix is one value for all three repos (`harmonize`); feeds the rationale column of `OWNER-REVIEW.md` and the "recommend one value for py, ts and rs" question added to harmonize-flagged prompts (owner decision 2026-09-02)
- [x] [P01-T07] Phase 3.5 — owner technology-selection review: `docs/port/OWNER-REVIEW.md`, one row per item (not waivable); `scripts/check-research-tree.sh --require-owner-review` green
- [x] [P01-TS03] Phase 4 — independent reviewer agent spot-checks ≥15 `COMMON → REUSE` rows and sampled `path:line` citations against both repos, confirms `COVERAGE.md` complete, reads every non-REUSE row adversarially; findings fixed
- [x] [P01-T05] Phase 5 — PR reviewed by owner, merged, `pull --ff-only`, worktree removed; tag v0.1.0
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

## [ ] Project P02: Execute research program (v0.2.0)
**Goal/Requirement**: Run every research item the owner accepted in Phase 3.5 under `research/RUNBOOK.md`, producing one audited `DECISION.md` per item and a filled `docs/port/PARAMETERS.md`.
- Gate: P01 merged and tagged `v0.1.0`; only items with disposition `accept`, `narrow` or `force` in `docs/port/OWNER-REVIEW.md` are run.
- Engine and invocation: exactly as recorded in `research/RUNBOOK.md` §2; Doxa runs are paid and each batch is confirmed by the owner before submission.
- Plan: written with `superpowers:writing-plans` after v0.1.0 — not part of P01's plan.

**Out of Scope**
- Any Rust code, `Cargo.toml`, CI workflow, or template file (the port itself)
- Re-opening ledger verdicts except through P02-TS02 (an OVERRIDE whose research answers "Override justified: no")
- Items dropped in Phase 3.5

### Tests & Tasks
- [ ] [P02-T01] Run the pilot item end-to-end (prompt → raw answer → `check-answer-shape.sh` → `DECISION.md` → both audits) — this run is binding, unlike P01-TS07
- [ ] [P02-T02] Run all remaining items in topological batches of at most 4 (`RUNBOOK.md` §1 order); raw answers saved under `topics/<nn>-<slug>/raw/`
- [ ] [P02-T03] Resolve every `CONFLICT:` line by the `RUNBOOK.md` §4 rule (registry first, owner prompt re-run, consumer re-run)
- [ ] [P02-T04] Write `audit-codex.md` and `audit-fable.md` for every item; the producer of a decision never audits it
- [ ] [P02-T05] Copy every `owns <param> = <value>` into `docs/port/PARAMETERS.md` and set the row's `owner` value column
- [ ] [P02-T06] Flip every index row to `resolved`; `scripts/check-research-tree.sh --require-owner-review` exits 0
- [ ] [P02-T07] PR, owner review, merge (merge commit), `pull --ff-only`, tag `v0.2.0`
- [ ] [P02-TS01] Every `DECISION.md` has an `## Empirical check` whose command was actually executed and whose output is pasted
- [ ] [P02-TS02] A reviewer re-reads every OVERRIDE item's "Override justified" field; any `no` flips the ledger row back to the inherited verdict and records the reversal under `### OV-nn`
- [ ] Regression Test Status

### Deliverable
```bash
$ grep -c '| resolved |' research/CLAUDE.md          # equals the number of index rows
$ scripts/check-research-tree.sh --require-owner-review
OK: research tree structure valid
```

### Automated Verification
- `scripts/check-research-tree.sh --require-owner-review` exits 0 with every index row `resolved`
- every `research/topics/*/DECISION.md` passes `scripts/check-answer-shape.sh` for its kind (with `override` where the ledger says OVERRIDE)

### Manual Verification
- Owner reads every OVERRIDE decision and every `audit-*.md` that disagrees with its decision
