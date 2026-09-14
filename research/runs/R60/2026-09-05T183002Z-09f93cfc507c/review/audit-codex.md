decision-sha256: 14f66259aad6063f9506410735e61e9a58a026fc24200cb048b9bbc71bbc2100
actor: audit-codex-2026-09-05T183002Z-09f93cfc507c-r3
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

argv: `bash <archive>/review/evidence/r60-standard-pin-r3.sh`; `bash <archive>/review/evidence/r60-preservation-diff-r3.sh`; `bash <archive>/review/evidence/r60-snapshot-provenance-r3.sh`.

cwd: `/private/tmp`; toolchain: `git archive`, `tar`, `bash`, `curl`, `diff`, and `shasum` on macOS. I archived commit `d642814cddfd3f1756fc56cd38738904440d9141` into an empty directory with no `.git`, then ran the three scripts from that extracted copy. All three exited `0`; complete output is `review/evidence/audit-cli-parsing-framework-r3.log`.

Output match: the two offline scripts diffed empty against their committed logs. The provenance script diffed empty in the history-bearing checkout. In the archive it differed only in the two declared self-baseline Git-object rows and their resulting totals: `CHECKS RUN: 12 ... UNVERIFIABLE-HERE: 4`, rather than `14 ... 2`.

## Findings

None. The archive provenance rerun re-fetched and hash-verified the standard, two crate tarballs and extracted files, and two Python snapshots; it also verified the two TypeScript privacy probes as HTTP 404. Each C0 control emitted its deliberate failure and the harness recorded it before resetting counters. The numeric inverse control confirmed `count=10` does not satisfy `count=0`; count expectations in the revision-3 scripts use labelled values. Gate 1 is correctly recorded as inapplicable under Q7.B, and the four exclusions are all explicitly gate-2 missing-`rust-version` exclusions.

## Assessment

The revision-2 post-commit rerunnability failure is corrected. The decision's stated evidence limits remain accurate: this audit verifies the recorded evidence apparatus and citations, not a non-existent template implementation.
