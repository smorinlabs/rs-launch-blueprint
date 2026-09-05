# P02 local implementation review

The approved tiered method is implemented and locally validated on
`docs/p02-execution-plan-review`, based on
`2f3569051af2c2089f60f6cad129bc6e55482c30`. The changes are committed under the
owner's 2026-09-04 commit direction (no per-commit approval; see
[APPROVAL.md](APPROVAL.md)). No binding research item has run or been resolved.

## What changed

- Amendment A6, the runbook, project tracking, execution policy and all 84
  prompts now agree on 6 Light, 53 Focused and 25 Deep items, with three engines
  for the R38 pilot. Full evidence fields and both audits remain required.
- R58 owns the logging contract consumed by R59/R75/R78. R83/R84 have a separate
  R71 acceptance prerequisite. The research graph has 69 edges and no cycle.
  The compatibility inventory preserves explicit assumptions for later research.
- Short workers can preserve input snapshots, operation IDs, failures and raw
  files, then exit. Another worker can collect the same operation. The offline
  runner never calls a provider. Astra reviewed the state and publication logic;
  Terra and Luna handled the bounded implementation and prompt work.
- Resolved decisions require current evidence hashes, complete raw shapes,
  parameter values, fresh recorded actors, empirical evidence, and two approving
  audits of the exact revision. Fenced or historical fields cannot fill missing
  current evidence. Reviewers still establish factual and architectural quality.
- Publication validates the complete staged tree and compares current hashes
  before applying a journaled update. Recovery preflights all files before any
  write. Participating readers share its lock. Published receipts allow reopened
  items to return to the queue while preserving their prior reports and decisions.
- P01/P01-T05 are correctly incomplete because their tag gate remains open.
  The retained research worktree and its three handoffs are preserved.

## Verification

All 100 tests across six suites passed: 53 structural, 10 acceptance, nine
Markdown/history, three reader-lock, 19 runner integration and six generator
tests. Six deliberately disabled runner safeguards each caused a failing test.
Sixteen CLI cases checked help, version, JSON streams, invalid flags, config
root, quiet and debug behavior. The current tree passes the owner-review gate.

The runner tests publish the first synthetic R38 acceptance in a temporary copy
of the complete 84-item tree and run the full structural checker afterward.
That proves local integration; it is not the binding research pilot. The
[runner review](evidence/runner-adversarial-review.md),
[prompt verification](evidence/prompt-migration-verification.md), and
[verification record](implementation-verification.json) retain the evidence.

## Remaining execution gates

The owner-approved method does not authorize a tag push, merge or paid
submission; the owner's later 2026-09-04 direction authorizes commits of
completed, validated changes. [publication-plan.md](publication-plan.md) records
the preparation commit and the exact missing P01 tag action for later approval.

Full REUSE/ADOPT baseline adjudication remains open. The existing samples are
research leads. Execution routes still need research-capable validation; Doxa
credentials, a concrete spend envelope and its ambiguous-create retry behavior
remain unresolved. The three-engine R38 pilot must pass before bulk research.
The [readiness record](tool-readiness.md) distinguishes tested routes from gaps.
Its dated re-inspection section records which of these gaps were closed later
the same day.

Capacity limits, waiting age, acceptance backlog and paid budgets remain
controller policy. The local runner does not enforce a provider's spending
ceiling. Locks coordinate participating tools; physical power loss and unrelated
programs bypassing the protocol were not tested. No confirmed local review
finding remains open within the implemented scope.
