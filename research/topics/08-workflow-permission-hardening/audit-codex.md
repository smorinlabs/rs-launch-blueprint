# R08 revision 4 empirical re-run — Codex

actor: codex-r08-r4-2026-09-27
model: gpt-6-sol
family: openai
decision-sha256: b1e27a4979495d56154088f155e249770465b79ce0b5325787fa1558b6eb3ef4
verdict: approve
unresolved-findings: none

The decision hash was recomputed with `shasum -a 256` before reading or running evidence. Working directory: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. The five evidence drivers were executed with output redirected to `/tmp/r08-codex-r4-rerun/`; the candidate script was also executed by the policy driver and separately against the comment-only control. No run input, snapshot, committed evidence log, or ledger was edited. The initially restricted source read stopped at `gh api user`; a network enabled rerun completed. The initially restricted zizmor run skipped its online case; a network enabled rerun passed it. The table below compares the completed runs.

| Script | Exit | Completed result | Committed log SHA-256 | Re-run log SHA-256 | Byte comparison |
|---|---:|---|---|---|---|
| `r08-refreeze.sh` | 0 | no-write path; `R-fresh` PASS | `dd7a4f3bfe6b08f35522917df087048597a8f570f7453735f868823a8c7c5af8` | `4b8e438e25fbbb3956a09b9e5d1fdd4838524f6e8e9c3f53deebfc0921893945` | different |
| `r08-inputs.sh` | 0 | 24 PASS, 0 FAIL | `db84965f25204b0150cb72ff73825907a58b0a5ae48ead653a859e58c83acbb0` | `2321182c538bbac570886cf11d8de60724f13439126ccda09788a8ac58e2a061` | different |
| `r08-policy.sh` | 0 | 28 PASS, 0 FAIL | `f685df445edcdbc9b2a0bf4323709ed6c25e15c166059f6141b4dfeb77772339` | `3293effe76f9424e27aac28957f9cc84ffb3f7c60fa0cff209c3e37cafa6e7ab` | different |
| `r08-zizmor.sh` | 0 | 32 PASS, 0 FAIL, including online P0 | `8c11fa298ecfe5ce22be08a9cdabffcc705e964c575016f8416a0a398e279504` | `75337195927f9b83b0318a9ed103aff790889bb15d41ad7b869a8b8749d42766` | different |
| `r08-sources.sh` | 0 | 460 lines; pinned excerpts reproduced | `19e8378bb15117ea550d526b68df626587dce129789e17e1615d7317bccb7214` | `811b24b6854d233694e08d2cf8e196069c4a196c77d68e888e804ab1e97cb410` | different |

Every `cmp` reported a byte difference; SHA-256 values are above. `shasum -a 256 -c review/evidence/SHA256SUMS`, run from the evidence directory, passed all 32 entries. The candidate's recomputed SHA-256 is `6176af764c467e5b1dc00a7c5e65198b573bbf3ef9f046cda5858f00e9f1357b`, matching `DECISION.md:487-488`. The manifest SHA-256 remains `be4b7ccc9d85cfabaed1164fdc05a9d194c4414a69e9d2a8788057646b81eb27`; the refreeze output says `already re-frozen: required_engines matches the live policy; no write`.

## Revision 4 repair checks

- **JF-1 — counts:** `DECISION.md:489-500` says “py needs 31 checkout edits and 6 top-level rewrites” and “ts needs 1 checkout edit, 1 top-level rewrite”; it also says `difftree-pr-comment.yml` “stays exempt.” Re-run `r08-policy.log:49-56` names exactly six py and one ts top-level failures. The py and ts source censuses still show 7 of 19 and 2 of 8 workflows without top-level `{}`, respectively; the extra file in each is the exempt difftree workflow.
- **F1 — shared input drift:** `DECISION.md:17` says `I-policy-live` compares `items.R08`, `engine_overrides.R08`, and `empirical_auditor_overrides.R08`, and scopes `I-other-CLAUDE.md` to R08's row. Re-run `r08-inputs.log:51-53` prints identical frozen and live R08 slices and `PASS I-policy-live`; `:65-67` prints the R08 row and `PASS I-other-CLAUDE.md`. `:74` prints `PASS R-fresh`. The frozen and live whole-file hashes differ, as disclosed.
- **F2 — comment check:** `DECISION.md:281-288` says “CI does not check what the comment says” and explicitly says `persist-credentials: true # ok` passes. The candidate header at lines 8-15 and 35-37 assigns comment meaning to review; line 74 checks only for a nonempty trailing comment. A scratch workflow with `persist-credentials: true # ok` and no later step exited 0 with no output. This matches the decision's narrower enforcement claim. The re-run policy log has 28 PASS and 0 FAIL.

## Findings

- **OBS — expected re-run log differences.** All five logs have a new timestamp. The re-freeze log also differs in its before-state and reports its idempotent no-write path instead of the historical write. `r08-policy.log` and `r08-zizmor.log` have no other byte difference from their committed versions. These deltas leave their assertions unchanged.
- **OBS — point-in-time shared-file drift.** The decision's revision note says “6 keys frozen, 37 live” (`DECISION.md:17`), which describes its 2026-09-27 rerun. The current live policy hash is `fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c` and has 12 empirical override keys; R08 is absent from both frozen and live override maps. The live research index hash also changed, while its R08 row remains identical. The Q23 seat freeze and no-repin rule in `research/RUNBOOK.md` §7.7 makes this a dated observation, not a re-pin request.
- **OBS — live zizmor counters moved.** `DECISION.md:616-619` dates the standing figures to 2026-09-27. The committed source log at lines 230-234 has 6,580 stars, 137 open issues, and 47,504 / 247,294 recent / total downloads; the re-run has 6,586 stars, 139 open issues, and 47,696 / 247,486 downloads. `pushed_at`, version, pinned source excerpts, and the 460-line layout are unchanged. These live counters do not carry the permission recommendation.

No BLOCKING finding was observed. `unresolved-findings: none` applies the Q23 outcome bar in `research/RUNBOOK.md` §7.1; controller S1 triages after handoff.
