actor: codex
model: gpt-6
family: openai
decision-sha256: 30cf468b330706b01887b6f74b89558d2813724f66973ec5ab4f00e7a6a3825d
verdict: approve
unresolved-findings: none

# R39 revision 3 empirical re-run

The pinned `DECISION.md` passed the first gate: `shasum -a 256` returned the `decision-sha256` above. This is the single Q23 empirical worker report. The seat policy hash `fd746cb86e54` is cited as the controller's point-in-time value; this audit did not read or repin live `research/EXECUTION.json`.

The working directory was `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. All rerun output and the network refresh were written under `/tmp/r39-codex-r3-gpeX5y`. No evidence script wrote to the research tree. Each shell execution completed in less than 1,200 seconds.

| Script or check | Exit | Fresh result | Byte comparison with committed log |
|---|---:|---|---|
| `r39-staged.sh` | 0 | `TOTAL PASS=16 FAIL=0` | differs |
| `r39-range.sh` | 0 | `TOTAL PASS=41 FAIL=0` | differs |
| `r39-config.sh` | 0 | `TOTAL PASS=24 FAIL=0` | differs |
| `r39-ignore.sh` | 0 | `TOTAL PASS=13 FAIL=0` | differs |
| `r39-selfscan.sh` | 0 | `TOTAL PASS=4 FAIL=0` | identical |
| `r39-sources.sh`, against committed snapshots | 0 | `TOTAL PASS=52 FAIL=0` | identical |
| `r39-inputs.sh` | 1 | `TOTAL PASS=87 FAIL=2` | differs |
| `r39-snapshot.sh`, copied into `/tmp` | 0 | 25 fresh snapshots | differs |
| `shellcheck -x r39-*.sh` | 0 | version 0.11.0; clean | identical |

The seven assertion scripts produced 237 PASS and 2 FAIL. Their committed logs contain 239 PASS and 0 FAIL. `r39-lib.sh` is a sourced helper, not an independent evidence run. The first network attempt was denied by the sandbox; a read-only retry with network access captured all 25 snapshots in `/tmp`.

## Findings

1. **OBS F1 — live runbook citation moved.** The decision says `r39-inputs.sh` had `PASS=89 FAIL=0` and its rev-note says `r39-inputs.log` was regenerated. That committed log does have `TOTAL PASS=89 FAIL=0`, including `PASS IN7b`, `PASS IN18c`, `PASS IN24`, `PASS IN25`, and `PASS IN26`. The fresh run differs only at `IN18b` and `IN18c`: `FAIL IN18b  RUNBOOK.md:88 contains: | Synthesizer | Fresh Claude Fable context  (expected=yes observed=no)` and `FAIL IN18c  RUNBOOK synthesizer row, content-anchored  (expected=88 observed=90)`. Live `research/RUNBOOK.md:90` still says `| Synthesizer | Fresh Claude Fable context that produced none of the item's raw reports or evidence checks |`. The role's content holds; the row moved two lines. Q23 §7.1 and §7.7 classify live-policy citation drift as an observation with no repin.
2. **OBS F2 — nondeterministic behavioural log bytes.** `cmp` differs for the staged, range, config, and ignore logs. The decision discloses throwaway repositories and runtime-generated fake tokens. Their fresh PASS/FAIL totals and check IDs match the committed logs; the complete `PASS` lines are byte-identical for staged, range, and config. The ignore log's generated commit hash changes its `I3b` PASS line, but the same path-form and commit-form checks pass. The raw differences include execution times, scanner timing, fixture entropy, temporary paths, and generated commit hashes. These differences do not contradict the recorded behaviours.
3. **OBS F3 — disclosed live snapshot drift.** The decision says: `Rerunning it refreshes live figures such as stars and issue counts, so r39-sources.sh assertions on those figures are expected to move`. The fresh `r39-snapshot.sh` log differs bytewise from the committed log. Ten of 26 captured files, counting `PROVENANCE.tsv`, differ from the committed snapshots. On the fresh snapshots, `r39-sources.sh` reports `FAIL SRC9  gitleaks stars (live figure)  (expected=29499 observed=29521)` and `TOTAL PASS=51 FAIL=1`; its integrity check and all other source assertions pass. Against the committed, SHA-256-guarded snapshots, the script and log reproduce exactly at `PASS=52 FAIL=0`. The moved star count is the disclosed type of live figure and does not alter a load-bearing recommendation claim.

## Revision-note repair checks

- **Revision 2 R42 hand-off and trigger hold.** The scanner row says `the stack's provenance is an unverified HTTPS download pinned by version, not verified bytes` and `The checksum requirement revision 1 handed over is dropped`. R42's published decision line 29 says `Name **\`ubi\` 0.12.0**`; lines 1701–1702 give `ubi --project <owner>/<repo> --in ./bin`. Fresh `IN24`, `IN25`, and offline `SRC42`–`SRC46` pass. The `re-verify:` line names future changes, including `R42 revising its residue backend, or \`ubi\` gaining checksum verification`.
- **Revision 2 prompt, seat, and policy citation hold at the recorded point.** Fresh `IN3`, `IN7`, `IN7b`, `IN8`, and `IN26` pass. The first-seat amendment is recorded in `inputs/`; the live Q17.A paragraph still names R39. The only moved citation is F1 above. The decision's pre-amendment `manifest.json` description remains explicitly labeled a dispatch record.
- **Revision 3 evidence-log and count repairs hold as committed.** The committed `r39-inputs.log` has `TOTAL PASS=89 FAIL=0`; the decision table has `| **total** | **239** | **PASS=239 FAIL=0** |`. The seven committed script counts sum to 239, and the regenerated `shellcheck.log` is byte-identical to the fresh ShellCheck result. Fresh `IN9` confirms the revision-3 title; the five added raw-line checks resolve to Opus lines 517, 518, 1085, 1100, and 1101. F1 explains the current 237/2 rerun.
- **Revision 3 Opus split and release-only wording hold.** Opus lines 517–518 say `with SHA-256 verification` and `ubi is not installed on this host`; lines 1100–1101 say its checksum behaviour was not confirmed. The decision's `## Engines` agreement paragraph says both legs required verification and that the synthesis departs from them; row 8 calls the backend confirmed and verification refuted. The scanner row names ripsecrets as the one crates.io-published candidate, citing `SRC37`, and labels Kingfisher's crates.io absence **carried** from Opus line 1085. Fresh `SRC35`–`SRC37` pass against the guarded snapshots.

No BLOCKING finding changes the recommendation, a load-bearing claim, or the sufficiency of the recorded behavioural evidence. Verdict: `approve`.
