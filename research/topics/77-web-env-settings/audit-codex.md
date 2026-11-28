# R77 revision 6 empirical re-run audit

actor: codex
model: gpt-6
family: openai
decision-sha256: dc17643915a6b915207154fa3d205712b5b242c4eea705a914809e60aa42aacc
execution-sha256-point-in-time: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
verdict: approve
unresolved-findings: none

## Re-execution and byte comparison

All twelve `review/evidence/*.sh` scripts were invoked. Their outputs and generated snapshots went to `/tmp/r77-codex-r6-rerun`; the two snapshot fetchers ran from copies there. Each rerun log was byte-compared with its corresponding committed evidence log. `sources.sh` was compared with `sources-r6.log`, the revision 6 record. No full log was byte-identical, starting with each run's timestamp header.

| Script | Rerun | Comparison with recorded log |
|---|---|---|
| `sources.sh` | 85 PASS, 0 FAIL, 0 SKIP | Identical after the timestamp header (`sources-r6.log`). |
| `figures.sh` | 121 PASS, 0 FAIL, 0 SKIP | Every assertion line identical; timestamp and nine live `DRIFT` counters differ. |
| `probes.sh` | 31 PASS, 3 FAIL, 0 SKIP | Its three P6 size failures reproduce the inherited `CARGO_TARGET_DIR` defect disclosed in `DECISION.md:79,1255,1379-1382`; `probes-r4.sh` supersedes P6. |
| `rest-conformance-r2.sh` | 88 PASS, 3 FAIL, 0 SKIP | Historical title, carried `sources.sh` hash, and registry comparison of `web-extra-surface` differ after revision 6. |
| `ov-allocation-r3.sh` | 34 PASS, 9 FAIL, 0 SKIP | Historical title/pins, the nested revision 2 check, R80's later revision, and the broad quotation census differ in the live tree. |
| `fetch-snapshots.sh` | Exit 0; 37 write lines | Current retrieval includes the two crates added after the recorded first fetch (33 write lines); timestamp and live data differ. Its copy wrote only under `/tmp`. |
| `fetch-snapshots-r4.sh` | Exit 0; 27 write lines | Same write lines; start and finish timestamps differ. Its copy wrote only under `/tmp`. |
| `drift-r4.sh` | 32 PASS, 0 FAIL, 0 SKIP | Identical after the timestamp header. |
| `probes-r4.sh` | 37 PASS, 0 FAIL, 0 SKIP | Identical after timestamp and inherited target-directory path. |
| `probes-rerun-r4.sh` | 6 PASS, 0 FAIL, 0 SKIP | Assertion lines identical; temporary paths, Cargo timing/output, and timestamps differ. Embedded `probes.sh` runs are 31/3/0 and 34/0/0. |
| `ov-allocation-r4.sh` | 9 PASS, 1 FAIL, 0 SKIP | The live census includes the published copy at `research/topics/77-web-env-settings/DECISION.md` as a second declaration by R77. |
| `r4-checks.sh` | 172 PASS, 13 FAIL, 0 SKIP | Exactly the 13 failures disclosed in `DECISION.md:34-38`: three revision-6 title/label/source-pin checks and ten live prompt, R74, and R58 checks. |

## Revision-note checks

- The decision still recommends template code over `std::env::vars_os` and `str::FromStr` (`DECISION.md:3-4`). Its revision 5 snapshot has the stated SHA-256 (`DECISION.md:5-6`; `review/R77-r5-snapshot.md`).
- The `web-extra-surface` value at `DECISION.md:1184` is byte-identical, after the prefix substitution, to R69 revision 11's owned value at `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1885`: 2,783 value bytes. R69's file has the SHA-256 quoted at `DECISION.md:11-14`. `sources.sh:261-275` checks that pinned source and the other five assumptions; the rerun confirms 85/0/0.
- The revised provenance and re-verification conditions are present at `DECISION.md:1167-1177,1203-1225`. The revision 5 repair descriptions at `DECISION.md:53-55` match the reproducibility rule at `DECISION.md:1415-1436` and the recorded historical counts at `DECISION.md:1364-1377`.
- `shellcheck review/evidence/sources.sh` exited 0. The revision 6 touched-source log differs from the committed `sources-r6.log` only in its timestamp.

## Findings

- **OBS-1:** Historical `rest-conformance-r2.sh` and `ov-allocation-r3.sh` now fail added source and registry pins because revision 6 deliberately changed `sources.sh` and copied R69's value before registry publication. The current `sources.sh` rerun passes all 85 checks; `DECISION.md:3-38,1173-1184` discloses the changed source and flag-day rule.
- **OBS-2:** `ov-allocation-r4.sh` reports two `OV-04` declaring files. The extra file is R77's published copy, headed as revision 5 at `research/topics/77-web-env-settings/DECISION.md:1` and declaring `OVERRIDE (OV-04)` at line 989; the allocation remains R77's.
- **OBS-3:** `figures.sh` live counters, fetcher timestamps/data, Cargo paths/timing, and inherited-target P6 failures differ from their historical logs. The assertion reruns for `figures.sh`, `drift-r4.sh`, `probes-r4.sh`, and `probes-rerun-r4.sh` match the recorded outcomes. `DECISION.md:1379-1382,1413-1436` describes these comparison classes.
- **OBS-4:** `r4-checks.sh` reproduces all 13 failures reported at `DECISION.md:34-38`; these are historical labels/pins and live coupled-file drift. Its result is 172/13/0, as disclosed.

No BLOCKING finding arose from the reruns or the revision 6 touched-source byte comparison.
