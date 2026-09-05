# PROJECTS.md — rs-launch-blueprint

## [ ] Project P01: Port research program (v0.1.0)
**Goal/Requirement**: Prepare evidence-based research that captures the shared engineering principles and agreement levels, then evaluates the Rust architectures and libraries that best preserve them — ending with a research index and one deep-research prompt per open item.
- Principles and agreement levels explicit (spec §2/A5); departures from recorded patterns labeled `OVERRIDE (OV-nn)` with argument and options
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
- [x] [P01-T07a] Phase 3.5 input — `docs/port/DIVERGENCE-ANALYSIS.md`: one row per research item giving the py state, the ts state, why they differ (cause class A–G), the Rust question, and the original cross-repo comparison scope (`harmonize`); feeds `OWNER-REVIEW.md`. Amendment A5 replaces the original one-value question with explicit agreement levels and evidence-backed native designs
- [x] [P01-T07] Phase 3.5 — owner technology-selection review: `docs/port/OWNER-REVIEW.md`, one row per item (not waivable); `scripts/check-research-tree.sh --require-owner-review` green
- [x] [P01-TS03] Phase 4 — independent reviewer agent spot-checks ≥15 `COMMON → REUSE` rows and sampled `path:line` citations against both repos, confirms `COVERAGE.md` complete, reads every non-REUSE row adversarially; findings fixed
- [ ] [P01-T05] Phase 5 — PR reviewed and merged; `v0.1.0` tag still absent (verified 2026-09-04). Retain `rs-launch-blueprint-research` and its untracked handoffs as the approved cleanup exception. Tag creation/push awaits explicit approval.
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
**Goal/Requirement**: Run every research item the owner accepted in Phase 3.5 under `research/RUNBOOK.md`, producing one audited `DECISION.md` per item and a filled `docs/port/PARAMETERS.md`. Each decision demonstrates the intended principle at its declared agreement level with an appropriate native design and a realistic acceptance example.
- Gate: binding research waits for P01 merged and tagged `v0.1.0`; local preparation is approved before that tag. Only items with disposition `accept`, `narrow` or `force` in `docs/port/OWNER-REVIEW.md` are run.
- Engines and invocation: `research/EXECUTION.json` and `research/RUNBOOK.md` §2 define the approved 6 Light / 53 Focused / 25 Deep allocation and three-engine R38 pilot. Durable wrappers save results to files; fresh contexts synthesize and audit. Doxa batches require separate spend approval.
- Approved execution method: `docs/planning/p02/PROPOSAL.md`, approval recorded in `docs/planning/p02/APPROVAL.md`; active contract is design amendment A6 and `research/RUNBOOK.md`. This supersedes the earlier instruction to defer all P02 planning until the tag.

**Out of Scope**
- Any Rust code, `Cargo.toml`, CI workflow, or template file (the port itself)
- Unrecorded changes to ledger verdicts; evidence-backed baseline corrections follow `RUNBOOK.md` §4 (A5), and OVERRIDE reversals follow P02-TS02
- Items dropped in Phase 3.5

### Tests & Tasks
- [x] [P02-T08] Review and approve the tiered execution method; owner approval 2026-09-04 (`docs/planning/p02/APPROVAL.md`)
- [x] [P02-T09] Reconcile spec, runbook, all prompts and policy; validate strict acceptance, durable recovery and shared publication locally; prepare the complete diff (`docs/planning/p02/implementation-review.md`, 100 tests passed); committed 2026-09-04 under the owner's commit direction, which replaced per-commit approval (`docs/planning/p02/APPROVAL.md` addendum)
- [~] [P02-T10] Verify execution routes, credentials and create-retry behavior; record and obtain a concrete paid readiness/pilot budget before Doxa submission
      2026-09-04: Claude Opus/Fable routes verified by CLI probe; Codex `gpt-6-astra`/`gpt-5.6-terra`/`gpt-5.6-luna` resolve by CLI header; Doxa provider keys present (env) and `o3-deep-research`/`deep-research-preview-04-2026` visible to the keys; create retries isolated by `scripts/doxa_no_retry.py` (tests in `scripts/test-doxa-no-retry.py`); envelope prepared in `docs/planning/p02/paid-envelope.md` — owner spend approval still open
- [~] [P02-T01] First review REUSE/ADOPT baselines for agreement-level mistakes and record/reconcile `BASELINE-REVIEW:` findings under A5; then run R38 as the pilot end-to-end
      2026-09-04: all 97 REUSE/ADOPT rows adjudicated (`docs/port/BASELINE-REVIEW.md`: 18 worker findings plus 11 challenges from the Codex gpt-6-astra adversarial sample, adjudicated by the controller); 28 ledger rows annotated (2 reclassified), 20 prompts and the dependency record reconciled; owner questions listed there. R38 pilot still waits on the `v0.1.0` tag and the paid-envelope approval (prompt → three raw answers in parallel → `scripts/check-answer-shape.sh` on each → synthesized `DECISION.md` with `## Engines` → both audits) — this run is binding, unlike P01-TS07
- [ ] [P02-T02] Run remaining items as their own prerequisites become current and accepted, under the approved tier policy and capacity limits; save original outputs in unique run directories and accepted reports under each topic's `raw/`
- [ ] [P02-T03] Resolve every `CONFLICT:` line by the `RUNBOOK.md` §4 rule (registry first, owner prompt re-run, consumer re-run)
- [ ] [P02-T04] Write `audit-codex.md` and `audit-fable.md` for every item; distinct fresh auditors approve the exact decision revision with no unresolved findings, and neither auditor produced raw evidence or synthesis
- [ ] [P02-T05] Copy every `owns <param> = <value>` into `docs/port/PARAMETERS.md` and set the row's `owner` value column
- [ ] [P02-T06] Flip every index row to `resolved`; `scripts/check-research-tree.sh --require-owner-review` exits 0
- [ ] [P02-T07] PR, owner review, merge (merge commit), `pull --ff-only`, tag `v0.2.0`
- [ ] [P02-TS01] Every `DECISION.md` has an `## Empirical check` whose command was actually executed and whose output is pasted
- [ ] [P02-TS02] A reviewer verifies the principle-to-design mapping and agreement level in every decision, then re-reads every OVERRIDE item's "Override justified" field; any `no` flips the ledger row back to the inherited verdict and records the reversal under `### OV-nn`
- [ ] Regression Test Status

### Deliverable
```bash
$ grep -c '| resolved |' research/CLAUDE.md          # equals the number of index rows
$ scripts/check-research-tree.sh --require-owner-review
OK: research tree structure valid
```

### Automated Verification
- `scripts/check-research-tree.sh --require-owner-review` exits 0 with every index row `resolved`
- Every raw answer in `research/topics/*/raw/*.md` passes `scripts/check-answer-shape.sh` for its item's kind (with `override` where the ledger says OVERRIDE).
- `scripts/check-research-tree.sh` validates policy, prompt shape, current acceptance hashes, recorded identities and approving audits through `scripts/research_validation.py`. P02-TS01 and reviewers separately establish actual execution, source quality and semantic fitness.
- `scripts/test-research-validation.py` and `scripts/test-research-runner.py` exercise malformed evidence, stale inputs, recovery and publication refusals using offline fixtures.

### Manual Verification
- Owner reads every OVERRIDE decision and every `audit-*.md` that disagrees with its decision
