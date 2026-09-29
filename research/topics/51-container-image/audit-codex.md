actor: codex
model: GPT-6
family: openai
decision-sha256: 6cc29e7badb1dbd8ad2c6434764706402f50843b2d577ba01b50e022e3c5bb47
verdict: approve
unresolved-findings: none

# R51 revision 5 empirical re-run

The target hash matched before any other read. I ran all four `review/evidence/r51-*.sh` scripts from the repository root with `CARGO_HOME=/tmp/cargo-s61-R51-evr` and `CARGO_TARGET_DIR=/tmp/cargo-s61-R51-evr-target`, after removing and recreating both directories. Fresh logs are under `/tmp/r51-codex-r5/`. Each command had a 1,100-second alarm. `cmp` found that every fresh log differs bytewise from its committed counterpart.

| Script and fresh log | Fresh result | Committed result | Comparison |
|---|---|---|---|
| `r51-container.sh` → `/tmp/r51-codex-r5/r51-container.log` | exit 0; `PASS=14 FAIL=0 SKIP=14 TOTAL=28` | `PASS=54 FAIL=0 SKIP=0 TOTAL=54` | Docker daemon unavailable. The 14 fixture and grammar checks pass; the Docker-dependent `C1`–`C14` groups skip. The decision discloses this host case at `DECISION.md:1457`–`:1469` and the earlier revision-3 attempt at `:1250`–`:1253`. |
| `r51-registries.sh` → `/tmp/r51-codex-r5/r51-registries.log` | exit 0; `PASS=0 FAIL=0 SKIP=32 TOTAL=32` | `PASS=32 FAIL=0 SKIP=0 TOTAL=32` | No network reach to the documented endpoints and no authenticated `gh`; all 32 checks skip. The decision discloses the no-network attempt at `:1250`–`:1253` and SKIP behavior at `:1457`–`:1469`. The committed digest and registry claims were not freshly exercised here. |
| `r51-sources.sh` → `/tmp/r51-codex-r5/r51-sources.log` | exit 1; `PASS=160 FAIL=2 SKIP=0 TOTAL=162` | `PASS=162 FAIL=0 SKIP=0 TOTAL=162` | Apart from timestamp and observed R68/R77 working-file lines, only `S10t` and `S10u` change verdict. Both pin R02 revision 2's live title and line 22; see OBS-2. |
| `r51-reproduce.sh` → `/tmp/r51-codex-r5/reproduction.log` | exit 1; both script comparisons differ; container check IDs and verdicts agree between the committed revision-1 and revision-2 logs | Committed `reproduction.log` ran `r51-sources` alone and ended `reproduction-exit: 0` | The no-argument run reports the environment skips, `S10t`/`S10u`, and a declared volatile R77 line; see OBS-1 to OBS-3. A separate invocation with `r51-sources` alone, `/tmp/r51-codex-r5/reproduction-sources.log`, also exits 1 and was byte-compared with the committed `reproduction.log`. |

`/opt/homebrew/bin/shellcheck -S warning` over all four scripts exited 0; its fresh output is `/tmp/r51-codex-r5/shellcheck.log`.

## Findings

- **OBS-1 — environment skips.** The Docker and registry reruns do not contradict a measured value or a check verdict: their dependent checks did not execute. `r51-container.log` records `SKIP C1`–`C14`; `r51-registries.log` records 32 SKIPs. The decision explicitly discloses both classes of unavailable-host result at `DECISION.md:1457`–`:1469`. Its earlier committed full runs and revision-4 empirical reruns remain the execution evidence; this seat could not independently repeat those Docker or network measurements.
- **OBS-2 — R02 live title and line drift.** The committed sources log says `PASS S10t` for R02 revision 2 at line 1 and `PASS S10u` for its four-package topology at line 22. Fresh output says `FAIL S10t` and `FAIL S10u` because R02's live `DECISION.md` is now revision 3 and line 22 is in its revision note. R02 revision 3 states at its lines 3–5 that the topology does not move, and its `## Decision` still recommends the four-package root-package workspace at line 36. R51's selected topology therefore still holds. This is title/line re-baselining under RUNBOOK §7.1 and §7.7, not a change to R51's recommendation.
- **OBS-3 — declared volatile R77 line escapes the reproduction filter.** `DECISION.md:1397`–`:1402` declares `observed-r77-live-*` volatile, but `r51-reproduce.sh:42` matches suffixes with `[a-z-]+`. It does not match `observed-r77-live-ov04-heading`, so the revision-4-to-5 line move (`959` → `989`) appears in the reproduction diff. The R77 observation is not asserted by a check and does not change the selected container mechanism. The other declared live R77 and R68 lines are filtered. This scoping defect explains one extra difference in the reproduction output and is recorded under the Q23 no-repin rule.

## Revision-note line checks

- Revision 5's volatile class 4 now names `measured-size-main`, the `C2g` message, and the under-40-MB range at `DECISION.md:1403`–`:1409`. Its quoted rerun distinction and the committed-run status of 12,302,310 B hold at `:1410`–`:1422`; the same correction is in the `r51-reproduce.sh` header. The current seat could not test new layer-size variation without Docker.
- The member-4 gap is explicit at `DECISION.md:747`–`:764`; the adopter qualification is at `:365`–`:369`, E4 at `:1543`, and the Engines gap at `:1666`–`:1675`. `raw/muse.md:220` and `raw/opus.md:894`–`:895` support the attributed gaps. The committed container log records `PASS C3c`–`C3f` and `PASS C13a`–`C13c`; this seat's Docker checks skipped.
- The revision-4 fail-closed gate repair still passes `S18a`–`S18h` and `S18l`. The revision-3 R68 binding and cache-alternative repairs pass `S10w`–`S10z` and `S17a`–`S17e`. The revision-2 evidence and decision-shape checks pass, including `S3a`, `S6a` and `S6b`. The only fresh source failures are OBS-2's `S10t` and `S10u`.

Q23 outcome check: zero BLOCKING findings. The frozen `research/EXECUTION.json` hash is `55f51017f3aba8c15d8e5dbb014aba012fb993246cf137034f46ba5ab4923c54` at this audit's read; no live-policy re-pin is requested.
