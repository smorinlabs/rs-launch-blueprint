actor: codex
model: gpt-6
family: openai
decision-sha256: a5879b95aeff19ea292f414f83d0757f7c1fedc147344f54eecfb0d4a1d86bc2
verdict: approve
unresolved-findings: none

# R14 revision 3 empirical re-run

The decision hash above was recomputed with `sha256sum` before reading or running evidence. This is the Q23 empirical seat. It reports execution and byte comparisons for revision 3; S1 owns finding triage.

## Re-run and comparison

All six committed evidence scripts ran in the foreground from the repository root. Each command exited 0 and wrote its script output only to `/tmp/r14-codex-r3-<name>.log`. The committed logs add three header lines (`UTC now`, `host`, `cmd`) and a final `exit=0` line around that output. Removing only those four wrapper lines from each committed log gives a byte-identical `cmp` against the corresponding rerun output.

| Script suffix | Passing checks | Script exit | Output comparison |
|---|---:|---:|---|
| `inputs` | 27 | 0 | byte-identical |
| `guard` | 29 | 0 | byte-identical |
| `merge` | 4 | 0 | byte-identical |
| `pybody` | 5 (`BODY`, `P1`–`P4`) | 0 | byte-identical |
| `workflow` | 9 | 0 | byte-identical |
| `lefthook` | 4 | 0 | byte-identical |
| **Total** | **78** | | **0 failures** |

`shasum -a 256 -c SHA256SUMS` passed for all 14 committed evidence files. The current decision's revision-3 note says the inputs log was re-recorded and the other five logs differ from later reruns only by the UTC wrapper line. The byte comparisons above confirm that their script output has not drifted.

## Revision-note repairs checked

- `JF4-1`: `DECISION.md:108-123` names the seven template-shaped repositories, limits the 2.08× headroom claim to those repositories and growing generated files, identifies intentional assets separately, and cites `raw/opus.md` `### Landscape`.
- `JF4-2`: `DECISION.md:88` cites `check-large-files.sh:10` for `max=1048576` and line 37 for the shared comparison. `/usr/bin/grep -c 1048576 check-large-files.sh ci.hygiene-with-guard.yml` returned `check-large-files.sh:2` and `ci.hygiene-with-guard.yml:0`, matching `DECISION.md:283-286`. `DECISION.md:245-247` proposes the missing committed grep and range-boundary checks for P03.
- `JF2-1`: `DECISION.md:30-35` records the Q17.A Muse-for-Codex substitution and the revised prompt hash.
- `EA-1`: `r14-rev1-inputs.sh:18` pins `8ea107a4f7098eb2039650a249af28b71ad564513e3a522a5c85e3f43245765a`; rerun `I1` passed with that exact hash. The re-recorded inputs log and all 14 evidence digests verify.
- Revision-2 repairs remain present: `DECISION.md:178` has a single column-zero `re-verify:` line; `DECISION.md:221` counts `BODY` plus four `P` checks; `DECISION.md:200-203` scopes the two-shell and macOS-only cases as the rerun guard output shows.

## Findings

- **OBS-1 (OBS):** The committed log wrappers retain their original UTC capture times. The six reruns captured script output without those wrappers. After stripping the committed wrappers, all six byte comparisons match; this is the timestamp-only drift disclosed in the revision-3 note, with no contradictory check output.

No BLOCKING finding was observed. The `approve` verdict follows the Q23 zero-BLOCKING rule.
