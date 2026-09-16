decision-sha256: 85beea991e84be1321b6b8cc55cd934c7049f621c38591394e2fa795234710a4
actor: audit-codex-2026-09-05T162400Z-58ba22bff8ca-r2
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: `## Supersedes` is not byte-verbatim to the required published revision 1; the claimed maximum 31-day staleness/retry bound is not established and is contradicted as a guarantee by GitHub's documented dropped-schedule possibility

## Rerun

- argv: `bash ./run-check-r2.sh`, exactly the decision's recorded script, from `research/runs/R07/2026-09-05T162400Z-58ba22bff8ca/review/empirical/r2`.
- cwd: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R07/2026-09-05T162400Z-58ba22bff8ca/review/empirical/r2`.
- toolchain: macOS 26.4 arm64; `actionlint 1.7.12`; Python 3.14.7 with PyYAML 6.0.3; Rust 1.98.0; `act` absent, form (b).
- exit code: 0. Complete rerun log: `review/evidence/audit-contributors-bot-trigger-cadence-r2.log`.
- output match: yes. `diff -u` of the saved `review/evidence/r07-empirical-r2.log` and the audit rerun after removal of only their `date:` lines exited 0. The rerun reproduced all six checks, including the 134 post-guard push-run total and `failure: 12`, `success: 122`.
- falsifiability: a temporary outside-repository copy with the recommended cron changed to `0 6 * * 1` exited 1 and emitted the expected structural `ASSERT-FAIL` lines; the copy was discarded.

## Findings

1. **Required byte-verbatim supersession is false.** The published file `research/topics/07-contributors-bot-trigger-cadence/DECISION.md` hashes to the mandated `0b3dde8f9a15f22e60a01542065c53c122881e8c48bf3ee6c172ba5b70499346`. The payload after `## Supersedes` instead hashes to `1469280072fd615a85c1f883e42d8117d4ac7e79c832ec2aac1c48dee4de261d`. A direct diff shows added explanatory paragraphs plus opening and closing ````markdown` fences. The embedded text may be unaltered, but the required `## Supersedes` content is not the published decision byte-for-byte. Remove the wrapper so the section payload itself is exactly the published bytes.

2. **The 31-day maximum is an unsupported guarantee.** A6 and the decision prose state that a failed or absent push is retried within, and the list is stale for at most, 31 days. Check 2 proves only the cron expression, while the decision explicitly says no scheduled run has executed. The live GitHub scheduled-events documentation still says that sufficiently high load can cause queued jobs to be dropped; an expiring or revoked credential can also make the scheduled retry fail, and the decision correctly documents that the whole workflow can be disabled. The design can truthfully state that it schedules a monthly retry attempt, not a maximum staleness or successful-retry bound.

3. **Verified, not a finding:** six live `curl` checks returned HTTP 200 for the cited workflow-syntax, scheduled-events, disable-and-enable, REST-workflows, action README, and repository API sources. The live pages retain the 60-day and public-fork rules, the workflow-level required `state` enum (`active`, `deleted`, `disabled_fork`, `disabled_inactivity`, `disabled_manually`), the workflow-wide disabling sentence, and `gh workflow enable WORKFLOW`; the API says rs is public. Thus revision 2 correctly rejects the controller premise: adding `schedule` exposes the whole workflow, including `push` and `workflow_dispatch`, and A7 plus behavior 5 state that consequence as bounded/documented/recoverable rather than claiming the push half survives.

## Assessment

The empirical script is reproducible, content-asserting, and falsifiable; the revision-1 script and log retain their commit-`2460629` hashes, and the published revision-1 parameter section is byte-identical. Gate 1 is correctly recorded as `inapplicable` because R07 selects no crate. However, the explicitly required supersession representation fails its byte identity condition, and the decision overstates what its cron syntax and documentation establish. Both require a decision edit before approval.
