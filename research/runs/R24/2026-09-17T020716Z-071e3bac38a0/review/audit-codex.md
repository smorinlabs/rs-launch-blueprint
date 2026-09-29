actor: codex
model: gpt-6
family: openai
decision-sha256: bc5dcafa1ac0a864ce458bdc45dee92f02385cb28ebde7e8af364a5b04683a52
verdict: approve
unresolved-findings: none

# R24 empirical verification

## Target and currency

`sha256sum review/DECISION.md` returned `bc5dcafa1ac0a864ce458bdc45dee92f02385cb28ebde7e8af364a5b04683a52` before any other read or run. `review/audit-codex.md` was absent. The decision's `## Empirical check` names the current `evidence/r24-checks.sh`, primary `evidence/r24-checks.log`, and restricted-PATH `evidence/r24-checks-skip-control.log`. The evidence tree contains exactly one shell check script: `r24-checks.sh`. The decision reports 125 PASS / 0 FAIL / 0 SKIP for the primary and 109 PASS / 0 FAIL / 3 SKIP for the control, both at exit 0.

## Rerun method and results

I copied `review/evidence/`, `review/DECISION.md`, and `docs/port/PARAMETERS.md` beneath `/tmp/r24audit-codex.GFO5iG/live/`, preserving their repository-relative depths. I made a second copy beneath `/tmp/r24audit-codex.GFO5iG/head/`, with `docs/port/PARAMETERS.md` supplied by `git show HEAD:docs/port/PARAMETERS.md`, because the working-tree registry has uncommitted changes. All script output and its rewritten `toolchain.txt` remained in `/tmp`. For primary runs I set `npm_config_cache` to a scratch cache and allowed npm registry access. `cmp` below compares each rerun log with its corresponding committed evidence log; `identical` means exit 0 from `cmp -s`.

| Registry | Command in scratch `review/evidence/` | Exit | Totals line | `cmp` |
|---|---|---:|---|---|
| Working tree | `bash r24-checks.sh` | 0 | `PASS 125  FAIL 0  SKIP 0  TOTAL 125` | identical to `r24-checks.log` |
| Working tree | `PATH=/usr/bin:/bin:/usr/sbin:/sbin bash r24-checks.sh` | 0 | `PASS 109  FAIL 0  SKIP 3  TOTAL 112` | identical to `r24-checks-skip-control.log` |
| `HEAD` | `bash r24-checks.sh` | 0 | `PASS 125  FAIL 0  SKIP 0  TOTAL 125` | identical to `r24-checks.log` |
| `HEAD` | `PATH=/usr/bin:/bin:/usr/sbin:/sbin bash r24-checks.sh` | 0 | `PASS 109  FAIL 0  SKIP 3  TOTAL 112` | identical to `r24-checks-skip-control.log` |

The control printed these three lines verbatim:

```text
SKIP 7a-install - node is not on PATH
SKIP 7b-upstream-bytes - node is not on PATH
SKIP 7c-rendered-bytes - node is not on PATH
```

## Primary assertion counts by decision row

I counted `PASS` assertion identifiers in the successful working-tree primary rerun and compared every row with the decision's per-section table. The final summary line was excluded from the assertion count.

| Section | Decision | Rerun |
|---|---:|---:|
| 1a–1c | 5 | 5 |
| 2 | 10 | 10 |
| 3a | 4 | 4 |
| 3b | 3 | 3 |
| 3c | 3 | 3 |
| 3d | 11 | 11 |
| 3e | 6 | 6 |
| 3f | 2 | 2 |
| 3g | 5 | 5 |
| 3h | 4 | 4 |
| 4a–4b | 5 | 5 |
| 4c–4e | 7 | 7 |
| 4f | 6 | 6 |
| 4g | 5 | 5 |
| 4h–4i | 4 | 4 |
| 4j | 3 | 3 |
| 5a–5c | 7 | 7 |
| 6a–6c | 13 | 13 |
| 7a–7c | 16 | 16 |
| 8a–8b | 6 | 6 |
| **Total** | **125** | **125** |

## Load-bearing figures re-derived at source

| Source read | Re-derived result |
|---|---|
| `gh api repos/googleapis/release-please/releases/latest` | `tag_name=v17.11.2`, `published_at=2026-08-24T21:20:30Z`, `draft=false`, `prerelease=false` |
| `npm view release-please dist-tags --json` | `latest=17.11.2` |
| `gh api 'repos/googleapis/release-please-action/contents/package.json?ref=v5.0.0'` | `name=release-please-action`, `version=5.0.0`, dependency `release-please=^17.6.0`; this range admits `17.11.2` |
| `git -C /Users/stevemorin/c/py-launch-blueprint show b08bccfb55d05f15e46a83b52c5660b1881d19f5:release-please-config.json` | `changelog-sections` opens on line 22 and has 12 entries, including `deps`; `refactor` is visible and `docs` is hidden |
| `git -C /Users/stevemorin/c/ts-launch-blueprint show cb1cbcb2e88b898e8c081b0abbfabc1630079c00:release-please-config.json` | `changelog-sections` opens on line 11 and has 7 entries: `feat`, `fix`, `perf`, `docs`, `test`, `refactor`, `chore` |

The two GitHub REST reads were more than 20 seconds apart. The script's section 6 also compared each pinned source with its snapshot, and section 7 compared a fresh npm install and rendering output with their snapshots; all corresponding assertions passed.

## Drift and environment observations

| Tag | Observation | Effect on assertions |
|---|---|---|
| OBS | The scratch primary `toolchain.txt` differs from the committed one in UTC timestamp, scratch/evidence/repository paths, Node `v26.9.0` versus `v26.5.0`, Rust `1.98.1` versus `1.98.0`, Cargo `1.98.1` versus `1.98.0`, and the ephemeral npm install path. Host, grep, npm, and shellcheck versions agree. | No assertion moved; the primary log is byte-identical. This toolchain drift is not a finding. |
| OBS | The first primary attempt under the default network sandbox ended with the script's three named npm-install SKIPs. A fresh run with npm registry access and a scratch npm cache executed all 125 assertions. | The successful, fully executed rerun is the verdict basis. |
| OBS | The working-tree parameter registry has unrelated uncommitted changes. Both working-tree and `HEAD` copies produced byte-identical primary and control logs. | No assertion moved; no registry file was written. |

## Verdict

**Approve, for empirical facts only.** Both faithful primary reruns executed all 125 assertions at exit 0 and matched the committed primary log byte for byte. Both named-skip controls matched their committed log byte for byte. Every decision section count and every requested load-bearing figure re-derived. There are no BLOCKING findings. This audit does not adjudicate another reviewer's judgment or the decision's architectural recommendation.
