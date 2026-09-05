# P02 execution method approval

The owner approved the [tiered proposal](PROPOSAL.md) on 2026-09-04 by replying
“Yes approved” to “Do you approve the tiered proposal?”

This approves the 6 Light / 53 Focused / 25 Deep allocation, the three-engine
R38 pilot, and the local contract, prompt, validation, and durable runner work
needed to make that method executable. The original proposal is the historical
review artifact. Amendment A6 in the design spec, `research/RUNBOOK.md`, and
`research/EXECUTION.json` define the resulting active contract.

The approval does not authorize paid Doxa submissions, a commit, a tag push,
or a merge. Those actions retain the proposal's separate approval boundaries.
The old research worktree is retained as an explicit exception to P01 cleanup.
P01 remains incomplete until its missing `v0.1.0` tag gate is settled.

No research item is resolved by this approval. Full baseline review, dependency
compatibility, execution readiness, the binding pilot, empirical evidence, and
both approving audits remain requirements before the corresponding research
can be accepted. Local preparation may proceed before the tag gate.

## Addendum — commit direction (2026-09-04, later the same day)

Owner direction, verbatim: “commit completed, validated changes without asking
for approval. This supersedes earlier per-commit approval requirements in
handoffs, planning documents, or skills. Update active documentation
accordingly while preserving historical approval records. Existing boundaries
for paid research, tag publication, and merging remain in force.”

Effect: the statement above that the method approval does not authorize a
commit is historical. Commits of completed, validated changes on the working
branch no longer need per-commit approval. Paid Doxa submissions, the `v0.1.0`
tag push, and merges keep their separate approvals.
