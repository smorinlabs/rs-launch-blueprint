# P02 execution preparation

The owner approved the tiered method on 2026-09-04. Local implementation and integration review are complete and committed
under the owner's later 2026-09-04 commit direction; tag push and merge await separate approval. No binding research item has
run or been resolved.

| Artifact | Purpose and status |
|---|---|
| [implementation-review.md](implementation-review.md) | Final scope, verification and remaining gates |
| [implementation-verification.json](implementation-verification.json) | Machine-readable final verification record |
| [APPROVAL.md](APPROVAL.md) | Exact approval and retained action boundaries |
| [PROPOSAL.md](PROPOSAL.md) | Historical proposal the owner reviewed |
| [research/RUNBOOK.md](../../../research/RUNBOOK.md) | Active execution contract under design amendment A6 |
| [research/EXECUTION.json](../../../research/EXECUTION.json) | Active allocation and acceptance prerequisites for all 84 items |
| [acceptance-schema.md](acceptance-schema.md) | Required acceptance evidence and validator interface |
| [cli-contract.md](cli-contract.md) | Scope and command/error behavior for the local Python tools |
| [publication-plan.md](publication-plan.md) | Executed preparation commit and the prepared tag action awaiting its approval |
| [runner-guide.md](runner-guide.md) | Local state and publication commands; no provider adapter |
| [dependency-reconciliation.md](dependency-reconciliation.md) | Compatibility review accompanying the prompt migration |
| [tool-readiness.md](tool-readiness.md) | Observed tool routes; the dated re-inspection records what became verified |
| [doxa-usage-guide.md](doxa-usage-guide.md) | How to run paid Doxa calls: the launcher, config key placement, per-engine cost and latency, recovery by operation ID |
| [paid-envelope.md](paid-envelope.md) | Prepared R38 pilot spend envelope, price references and the exact approval needed |
| [doxa-pilot.config.toml](doxa-pilot.config.toml) | Doxa configuration for the pilot, always launched through `scripts/doxa_no_retry.py` |
| [baseline-samples.md](baseline-samples.md) | Source-backed leads; full baseline adjudication is still open |
| [current-plan.md](current-plan.md), [contract-review.md](contract-review.md) | Captured old plan and findings against it |
| [item-schedule.md](item-schedule.md), [dependencies.json](dependencies.json), [dependency-review.md](dependency-review.md) | Historical comparison of the old graph with the approved R58 proposal |

The historical dependency and defect-reproduction scripts are pinned to
`2f3569051af2c2089f60f6cad129bc6e55482c30`. Re-running them reproduces the review
baseline instead of silently treating the amended checkout as the old contract.
Current validation is performed by the scripts linked from the runbook.

Binding execution still requires the missing P01 tag gate, full REUSE/ADOPT
baseline review and reconciliation, verified research routes, and the R38
pilot. Doxa credentials and a concrete paid-run budget remain unresolved.
Local method approval does not authorize tag pushes, merges or paid submissions;
the owner's later 2026-09-04 direction authorizes commits of completed, validated changes.

`verification.json` records the historical pre-approval packet checks.
`implementation-verification.json` records the completed local implementation.
