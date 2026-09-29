# R51 revision 6 empirical re-run audit

actor: codex
model: gpt-6
family: openai
decision-sha256: bbe83b8caba89078138ed6fc591bb7f1b25e463709cf14298ccfe6aa6e7b2465
execution-pin-sha256: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
verdict: approve
unresolved-findings: none

## Re-execution and byte comparison

I verified the decision hash before reading it. Every evidence script ran with its output directed to `/tmp/r51-codex-r6-*.log`; the scripts wrote their own scratch data under `/tmp`. I also ran `shellcheck -S warning` on all four scripts. No run evidence or input was edited.

| Evidence | Fresh result | Byte comparison with committed log |
|---|---|---|
| `r51-sources.sh` | exit 1; `PASS=156 FAIL=6 SKIP=0 TOTAL=162` | Same byte length; only `date-utc` differs from `r51-sources.log`. All check results and messages match. |
| `r51-reproduce.sh r51-sources` | exit 0; `RESULT r51-sources: identical outside the volatile classes`; `reproduction-exit: 0` | Only the record's `date-utc` and its echoed fresh timestamp differ from `reproduction.log`. |
| `r51-container.sh` | exit 0; `PASS=14 FAIL=0 SKIP=14 TOTAL=28` | Differs from `r51-container.log` because the Docker-dependent checks skipped. All 14 static fixture checks passed. |
| `r51-registries.sh` | exit 0; `PASS=0 FAIL=0 SKIP=32 TOTAL=32` | Differs from `r51-registries.log` because 22 HTTP checks and 10 GitHub checks skipped. |
| `shellcheck -S warning` | exit 0; no diagnostics | The committed `shellcheck.log` wraps the command and exit code with a date and version; the fresh diagnostic output is empty. |

The revision-note repairs hold at lines read in this audit. `review/DECISION.md:1` has the revision 6 title. `review/evidence/r51-sources.sh:117` checks that title; `:206` includes the revision 5 snapshot in the sweep; and `:373`–`:384` plus `:670`–`:671` read R69 revision 11 at line 1885. Those checks passed (`S3a`, `S6a`, `S6b`, `S10a`–`S10c`, `S18g`). The value at `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1885` equals `review/DECISION.md:1203` byte for byte after changing only `- owns` to `- assumes`. It contains `crates/web/src/` and the serve binary's "nothing beyond it" clause. R69's hash is `2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815`; `review/R51-r5-snapshot.md` matches the revision-note hash `6cc29e7badb1dbd8ad2c6434764706402f50843b2d577ba01b50e022e3c5bb47`. The live `research/EXECUTION.json` hash matches the point-in-time pin above.

## Findings

- **OBS-1:** The six source failures are the six disclosed at `review/DECISION.md:36`–`:48`: `S2c`, `S9a`, `S10t`, `S10u`, `S14e`, and `S18f`. Direct reads confirm the `web-extra-surface` registry lag (`review/DECISION.md:1203`, `docs/port/PARAMETERS.md`), the published run state (`manifest.json`), R02 revision 3's four-package sentence at `research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md:36`, and R69's serve-binary row at `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1702`. The older evidence table at `review/DECISION.md:1637` still says `S2c` had a "diff empty" result, while the rerun says `FAIL  S2c` and `review/DECISION.md:1216`–`:1218` explicitly says it is red. That stale table row does not alter the disclosed result or recommendation.
- **OBS-2:** Docker-dependent checks could not rerun: the script reports `SKIP  C1` through `C14` because this host has no usable Docker daemon. `r51-container.log` retains the earlier `PASS=54 FAIL=0` run, and the fresh static checks and `r51-reproduce.sh`'s committed container verdict comparison pass. I read the committed log, fixture, script, and pinned Python Dockerfile through read-only `git show`; the current image runtime behavior remains unmeasured here.
- **OBS-3:** Live registry checks could not rerun: the script reports no network reach for its 22 HTTP checks and no authenticated `gh` for its 10 GitHub checks. `r51-registries.log` retains the earlier `PASS=32 FAIL=0` run. I read that committed log and the registry script; current endpoint values remain unmeasured here.

No BLOCKING finding changes the recommendation, a load-bearing claim, or the evidence sufficiency for either under `research/RUNBOOK.md` §7.1.
