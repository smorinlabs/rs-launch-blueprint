# R82 revision 2 empirical re-run audit

actor: codex-r82-r2-empirical
model: gpt-6
family: openai
decision-sha256: edd8134100747cece06310b69bcb394e08538ea055c3213f52ed8210e0876502
verdict: approve
unresolved-findings: none

## Re-execution

The target SHA-256 was verified before reading or running evidence. From the run directory, I reran all four `review/evidence/*.sh` scripts with `CARGO_HOME=/tmp/cargo-s73-R82-evr` and `CARGO_TARGET_DIR=/tmp/cargo-s73-R82-evr-target`. Each successful rerun exited 0. Complete stdout and stderr were captured in `/tmp/R82-r2-*-rerun.log`; `diff -u` compared every byte with the corresponding committed log. The first upstream attempt could not reach `api.github.com` under the default network sandbox; the full rerun succeeded with network access and is the output compared below.

## Findings

- **OBS O1 — rustdoc log drift.** The run timestamp changed from `2026-09-27T03:05:10Z` to `2026-09-28T05:28:50Z`. One extra `warning: build failed, waiting for other jobs to finish...` appeared in floor-toolchain case `G4a`. The full diff contains no other changes. All `G0`–`G10` case results, including `G4a` exit 101 and `G4b`/`G4c` exit 0 on both toolchains, match the committed log.
- **OBS O2 — lychee log drift.** The run timestamp changed from `2026-09-28T04:36:11Z` to `2026-09-28T05:29:21Z`; `L1` elapsed time changed from 2 ms to 3 ms. The full diff contains no other changes. `L0` still verifies lychee 0.24.2 and the identical release digest; `L1`, `L1v`, `L2`, `L3`, and `L4` retain the documented exit codes and link outcomes.
- **OBS O3 — upstream sample drift.** The run timestamp changed from `2026-09-27T03:09:04Z` to `2026-09-28T05:29:11Z`. In the ten most recently opened lychee issues, new unanswered issue `#2310` replaced unanswered issue `#2275`. The complete diff shows no other change. The decision's `U8` claim remains exactly `7/10` maintainer answers and median `0.09` days; all other upstream outputs match.
- **OBS O4 — integrity log drift.** Only the run timestamp changed, from `2026-09-28T04:38:17Z` to `2026-09-28T05:29:29Z`. The complete diff shows no other change; the rerun reports `RESULT: PASS (0 failures, 65 citations)` and the target decision SHA-256.

## Revision-note checks

- The revision-2 repair for judgment finding 1 is present at `review/DECISION.md:385-387`, `:396-402`, `:540-552`, and the F349/F350 confidence lines at `:319-337`. The rerun confirms the cited `L` cases and the stated limits: no GitHub Actions run, `.gitignore` test, or real external-host test.
- The revision-2 repair for judgment finding 2 is present at `review/DECISION.md:112-122`. The rerun confirms `G4a` exits 101 without the feature, while `G4b` and `G4c` exit 0 with it, on both toolchains. The decision expressly accepts the feature-off strict-doc failure and describes the unexecuted mitigation.

No BLOCKING finding arose from the reruns or the revision-note checks.
