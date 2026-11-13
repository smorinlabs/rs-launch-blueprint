decision-sha256: b9c8303647a8098971ff9fec7116fba041c85f5db8a4c869960e9e18c89c8057
actor: audit-codex-2026-09-05T165440Z-3a8ca31664c3-r2
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

- argv: `bash "$PWD/research/runs/R43/2026-09-05T165440Z-3a8ca31664c3/review/evidence/r43-claims-check.sh" > "$PWD/research/runs/R43/2026-09-05T165440Z-3a8ca31664c3/review/evidence/audit-r43-r2.log" 2>&1`
- cwd: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`
- toolchain: macOS fallback. `/opt/homebrew/bin/limactl` was callable, but `limactl shell ubuntu -- bash -lc ...` reported that `ubuntu` is stopped, so the requested Linux shell was unavailable. The saved probe records `rustc`, `cargo`, `curl`, `jq`, `git`, and `gh` versions.
- exit code: `0`
- log: `review/evidence/audit-r43-r2.log`
- output match: yes for the substantive result. The decision log and this rerun each have the same 37 `PASS`/`FAIL` lines, all `PASS`, and `failed checks: 0`; run timestamps necessarily differ. The rerun also fetched the current first-party documentation endpoints with `curl`.

## Findings

### F1 resolved — issue #22425 now has the right meaning and weight

My direct `gh api repos/anthropics/claude-code/issues/22425` read confirms that its `## Current Behavior` says “`companyAnnouncements` also doesn't display visibly” and identifies Claude Code `v2.1.21`. Its later comments address `SessionStart` output and do not withdraw that statement. Revision 2 accurately calls it one user's historical report, limits it to one version with unknown configuration scope, and leaves U2 open for clean and merged profiles. The former dismissal survives only as a quoted, explicitly withdrawn revision-1 error; no conclusion rests on it.

### F2 confirmed — issue #39998 is countervailing merged-profile evidence, not clean-profile evidence

My direct read of #39998 confirms its reporter had enterprise `managed-settings.json` announcements, then created a project settings `companyAnnouncements` entry and saw the project entry at startup, framed as a company message. That is evidence that a project entry displayed in the managed-plus-project configuration. It does not observe a clean profile. Revision 2 states that boundary in the decision, disagreement 2, and U2.

### F3 confirmed — protected content and evidence integrity

Against the revision-1 decision blob, the recommendation block, the three-tier table, and all four `- assumes` lines are byte-identical. The claim-check script is the same Git blob (`16b25c32d356715652a0878c457d4e14d2f5ff13`) in both revisions and contains 37 assertion calls. The four assumptions also byte-match the values in `docs/port/PARAMETERS.md`. `issue-39998.r2.json` is now 5,823 bytes and byte-matches a fresh `gh api repos/anthropics/claude-code/issues/39998` response.

## Assessment

Revision 2 corrects the self-favouring factual error without widening either historical report beyond what its body establishes. It preserves the recommendation and evidence boundaries: documented behaviour remains Tier D and product behaviour remains Tier P for P03 to observe. The direct issue evidence is now present, reproducible, and appropriately bounded. Approve.
