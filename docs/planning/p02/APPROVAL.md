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

## Addendum — tag, pilot spend and bulk spend (2026-09-05)

Owner answers recorded through the session's decision dialog
(authorization reference `OWNER-2026-09-05-P02-EXEC`, session
https://claude.ai/code/session_013Dvsi7FhLemRfUyFSQi87A):

- **Tag gate:** the owner authorized the controller to run the prepared
  `v0.1.0` tag commands (annotated tag pinned to
  `2f3569051af2c2089f60f6cad129bc6e55482c30`, push of that ref only).
- **Pilot batch `B0-R38`:** maximum authorized spend USD 40 for one
  `all_deep_research` operation (o3-deep-research, sonar-deep-research,
  deep-research-preview-04-2026), launched through `scripts/doxa_no_retry.py`
  with a single create attempt per provider and no automatic resubmission.
- **Provider caps:** not set. The owner chose the job-count boundary (envelope
  option B): exactly one operation, three provider jobs, single attempt each;
  exposure is bounded by the estimate, not by a provider cap.
- **Bulk Deep work:** a blanket ceiling of USD 300 in total for the remaining
  25 Deep-tier Doxa operations, run continuously as prerequisites clear; the
  controller stops new paid submissions and reports when recorded usage
  reaches the ceiling. Per-batch item IDs, models and retry policy are
  recorded in each run manifest instead of a separate approval.

Retry policy for all paid work: none automatic; a failed or ambiguous
provider job is recorded and re-approved individually. Merging remains a
separate approval.

## Controller ruling — OpenAI model substitution (2026-09-05)

OpenAI shut down `o3-deep-research` and `o4-mini-deep-research` on 2026-07-23
(announced 2026-04-22; https://developers.openai.com/api/docs/deprecations,
retrieved 2026-09-05) and names `gpt-5.6-sol` as the replacement. The first
pilot submission (Doxa checkpoint `research-20260905-082108-efa8d00fdd884231`)
failed at the OpenAI create call with `model_not_found` before any provider
job existed, so no paid work occurred. Under the recorded authorization
`OWNER-2026-09-05-P02-EXEC` and the unchanged USD 40 ceiling, the controller
substitutes `gpt-5.6-sol` (USD 4 per 1M input, USD 20 per 1M output; cheaper
than the shut-down model) for the OpenAI job of batch `B0-R38` and of every
later Deep operation, driven through `scripts/doxa_no_retry.py`'s shim. The
owner's acknowledgment of this substitution is requested in the session report;
Perplexity `sonar-deep-research` and Gemini `deep-research-preview-04-2026`
are unchanged.
