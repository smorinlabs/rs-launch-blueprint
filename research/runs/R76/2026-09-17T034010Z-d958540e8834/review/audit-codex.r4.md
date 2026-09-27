actor: codex
model: gpt-6
family: openai
decision-sha256: c732bf24633eb386db07c186324af00a74c7d43f9932e4327c519a37aa40d641
verdict: approve
unresolved-findings: none

# R76 revision 4 empirical retry

The target SHA-256 matched before any other read. I ran all five evidence scripts unchanged from the repository root with `CARGO_HOME=/tmp/cargo-s61-R76-evr` and `CARGO_TARGET_DIR=/tmp/cargo-s61-R76-evr-target`, after removing and recreating both directories. Each invocation had an 1100-second alarm. The scripts' internal read-only Git calls were permitted. Fresh output went only to `/tmp`; each file was byte-compared with its committed log.

| Script | Fresh output in `/tmp` | Fresh result | `cmp` | Difference |
|---|---|---|---|---|
| `registry-figures.sh` | `R76-registry-figures.r4-retry.log` | 56 pass, 0 fail, 0 skip | different | UTC timestamp, downloads, `q=cors` search count, moving crates.io default-branch commit |
| `probe-checks.sh` | `R76-probe-checks.r4-retry.log` | 29 pass, 0 fail, 0 skip | different | UTC timestamp, scratch path, clean-build seconds; stripped sizes unchanged |
| `muse-adjudication.sh` | `R76-muse-adjudication.r4-retry.log` | 27 pass, 0 fail, 0 skip | different | UTC timestamp, live counters and stars, live policy hashes |
| `decision-self-check.sh` | `R76-decision-self-check.r4-retry.log` | 73 pass, 0 fail, 0 skip at 22:02:17 UTC | different | UTC timestamp only at first execution; a later rerun failed one R69 line check, described below |
| `rest-conformance-r2.sh` | `R76-rest-conformance-r2.r4-retry.log` | 64 pass, 2 fail, 0 skip | different | UTC timestamp, live override-token counts, and two failures inherited from its nested self-check of a moving R69 citation |

## Findings

- **OBS O1 — R69 citation moved during this retry.** The committed REST log says `decision-self-check.sh exit=0; ASSERT FAIL lines=0; PASS=73`; the fresh REST log says `exit=1; ASSERT FAIL lines=1; PASS=72`. Its two failed assertions are the nested self-check exit and absence of failed assertions. The nested failure expects `- owns web-extra-surface =` at R69 `DECISION.md:1791`. That line exists at 1791 in `review/R69-r10-snapshot.md`; the live R69 `DECISION.md` is now revision 11 and carries the same `web-extra-surface` value at line 1883. The standalone R76 self-check passed just before that change; a later standalone rerun reproduced the single citation failure. No CORS measurement or recommendation changed. This is a moving cross-item line citation under RUNBOOK §7.1 and §7.7, not an outcome-changing evidence gap.
- **OBS O2 — Probe timing and scratch drift.** The committed versus fresh clean-build seconds are `11.5/11.8` and `11.4/11.7` versus `9.0/8.3` and `9.0/9.6`; the scratch path and timestamp also changed. Both stripped sizes remain 502264 and 668728 bytes, all 29 assertions match, and `DECISION.md:1027-1041` says build seconds and scratch paths do not reproduce.
- **OBS O3 — Live registry and policy figures moved.** The registry and Muse logs differ in download/search/reverse-dependency/star counters, the crates.io default-branch SHA, timestamps, and the live `research/EXECUTION.json` and `research/RUNBOOK.md` hashes. Their 56 and 27 assertions, pinned-source lines, snapshots, and pass counts match. `DECISION.md:1034-1041` discloses point-in-time `FIGURE` and `HEAD` values; RUNBOOK §7.7 makes live policy citations point-in-time. The supplied frozen seat hash `55f51017f3ab` is a point-in-time citation, not a re-pin request.

## Revision-note repairs and outcome

- **EA-1 holds:** `DECISION.md:124` gives the expose-list floor as `request-id` and `allow`; `rest-conformance-r2.sh:216` defines both in the four-name `EXPOSED` list. The decision's option 2 at `:394-401` and `X10` row at `:917` match the fresh `CHECK X10`: the preflight has `access-control-expose-headers=request-id,allow,retry-after,ratelimit`, `allow=GET,HEAD`, and `request-id=req_probe`. The fresh `X10` and `X11` assertions pass.
- **Judgment finding 1 holds:** `DECISION.md:598-615` calls `hyper-cors` substrate-compatible but unproven, with no direct axum layer, 41 downloads, zero dependents, and remaining gates unevaluated. The qualified shortlist and `tower-http` 0.7.1 recommendation are unchanged.
- **Judgment finding 2 holds:** `DECISION.md:755` and `:903` describe the three Fetch Standard sentences, two quoted and one paraphrased. The fresh REST section G passes its three assertions.

The empirical behavior still supports conditional installation of `tower-http` 0.7.1 with the `cors` feature. The only failed checks target the moving R69 line number. There are zero BLOCKING findings under RUNBOOK §7.1, so the verdict is `approve`.
