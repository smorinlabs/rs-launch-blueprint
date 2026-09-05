# Prepared Git publication actions

The owner's direction on 2026-09-04 authorizes committing completed, validated
changes without per-commit approval; it supersedes the earlier requirement in
this plan and the handoffs for a reviewed diff and explicit approval before each
commit. Tag creation and push, merge, and paid Doxa submission keep their
separate approvals. The historical requirement is retained in
[APPROVAL.md](APPROVAL.md).

## P02 preparation commit

Worktree: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`.
Branch: `docs/p02-execution-plan-review`.
Base: `2f3569051af2c2089f60f6cad129bc6e55482c30`.

Commit subject: `feat(research): add tiered execution and durable acceptance`
(executed 2026-09-04 under the commit direction above; the commit ID is in
`git log` and in the readiness record that follows it).
Scope: the approved planning packet, amended spec/runbook/project tracking,
84 prompt metadata updates, execution policy and R58 registry ownership,
strict validation, offline durable runner, and their local regression checks.
Preserve the old worktree's three handoffs and all source repositories.

## P01 tag (executed 2026-09-05)

The owner authorized the controller to run the prepared commands on
2026-09-05 (`docs/planning/p02/APPROVAL.md` addendum). Result: annotated tag
`fd5e83943aad8a329de5092bd2794d33fb3cca4a` pushed as `refs/tags/v0.1.0`,
peeled object `2f3569051af2c2089f60f6cad129bc6e55482c30`, verified with
`ls-remote` against origin. The prepared text below is retained as the record
of what was run.

The historical Task 18 annotation is retained. Pin the tag explicitly to the
P01 merge commit so a later P02 commit cannot move the intended release point.
After separate approval, the prepared operations are:

```bash
git -C /Users/stevemorin/c/rs-launch-blueprint tag -a v0.1.0 2f3569051af2c2089f60f6cad129bc6e55482c30 -m "P01: port inventories, commonality ledger, research index and prompts"
git -C /Users/stevemorin/c/rs-launch-blueprint push https://github.com/smorinlabs/rs-launch-blueprint.git refs/tags/v0.1.0
git -C /Users/stevemorin/c/rs-launch-blueprint ls-remote --tags https://github.com/smorinlabs/rs-launch-blueprint.git refs/tags/v0.1.0 'refs/tags/v0.1.0^{}'
```

Recheck local and remote tag absence before creation. Verify the remote peeled
tag resolves to the exact commit above. An existing tag is a condition to
inspect, never a reason to overwrite it automatically. Retain the old research
worktree as approved, regardless of the tag result.

Git publication and paid Doxa execution remain separate approvals. Creating
the tag alone does not satisfy the baseline review or research readiness gates.
