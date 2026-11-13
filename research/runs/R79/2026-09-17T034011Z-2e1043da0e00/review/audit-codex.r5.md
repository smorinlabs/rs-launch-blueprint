actor: codex
model: gpt-6-sol
family: openai
decision-sha256: d1f4460e36a5a7c14e74cac8b8ecfc070bc40ffb1ef1c258841f277c33e27079
verdict: approve
unresolved-findings:

- **M1 — MECHANICAL.** Failed claim: `crate-sources.sh:426` prints `"axum's own example never calls run_upkeep -- the defect the recommendation repairs"`. Revision 5 instead calls the missing call an omission that matters between scrapes. Evidence: the current script and its fresh 66/0/0 log still contain that label; the published `metrics-exporter-prometheus` 0.18.3 source shows `render_to_write` calls `get_recent_metrics`, which drains histograms (`src/recorder.rs:91,125-139,142-143`). **Repair:** in the next evidence revision, change only the PASS label to `"axum's own example never calls run_upkeep -- an omission that matters between scrapes"`; refresh its paired log and affected digest pins. Preserve the `show_absent` assertion and the recommendation. Until then, identify the old label as historical in the decision's empirical-check text.

# Empirical audit of R79 revision 5

`shasum -a 256 research/runs/R79/2026-09-17T034011Z-2e1043da0e00/review/DECISION.md` was run from the repository root before any other audit operation and again before this file was written. Both returned the `decision-sha256` above. I read `README.md`, `docs/port/README.md`, `research/CLAUDE.md`, the decision, and `research/RUNBOOK.md` §5. I did not open any prior audit or revision snapshot. No repository evidence file was overwritten.

The commands below use `E=/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R79/2026-09-17T034011Z-2e1043da0e00/review/evidence` and `T=/tmp/r79-codex-r5.OIRNdm`. The five non-Cargo scripts ran with working directory `E`. `cargo-probes-r3.sh` writes `scrape-sample-r3.txt`, so each Cargo run used a byte-identical copy of the current `E` tree under `T`. All captured stdout and stderr went to `T`.

| Rerun command | Observed output and process exit | Assessment |
|---|---|---|
| `cp -R "$E" "$T/cargo-evidence"; (cd "$T/cargo-evidence" && ./cargo-probes-r3.sh > "$T/cargo-probes-r3.rerun.log" 2>&1)` | `PASS=54 FAIL=0 SKIP=0 TOTAL=54`; exit 0. E3: 51 web crates, 79 metrics crates. E4: 78/78 graph crates joined; highest declared `rust-version` 1.85.0. E6: route `_count` 51. E8: `promtool check metrics` accepted. | Pass |
| `cp -R "$E" "$T/cargo-evidence-run2"; (cd "$T/cargo-evidence-run2" && env -u CARGO_TARGET_DIR ./cargo-probes-r3.sh > "$T/cargo-probes-r3.run2.rerun.log" 2>&1)` | `PASS=54 FAIL=0 SKIP=0 TOTAL=54`; exit 0. The log prints `CARGO_TARGET_DIR in the environment = <unset>`. | Pass |
| `./crate-sources.sh > "$T/crate-sources.sh.rerun.log" 2>&1` | `PASS=66 FAIL=0 SKIP=0 TOTAL=66`; exit 0. All nine registry identity checks and every tarball/source assertion passed. | Pass |
| `./github-api.sh > "$T/github-api.sh.rerun.log" 2>&1` | `PASS=5 FAIL=0 SKIP=0 TOTAL=5`; exit 0. All five repository identities and `archived=False` checks passed. | Pass |
| `./rustsec-method-r3.sh > "$T/rustsec-method-r3.sh.rerun.log" 2>&1` | `PASS=9 FAIL=0 SKIP=0 TOTAL=9`; exit 0. The `metrics-util` positive control returned HTTP 200 and `RUSTSEC-2021-0113`; the surveyed candidate pages returned the expected HTTP 404. | Pass |
| `./decision-self-check-r3.sh > "$T/decision-self-check-r3.sh.rerun.log" 2>&1` | `PASS=315 FAIL=1 SKIP=0 TOTAL=316`; exit 1. The sole FAIL is H1 expecting `(revision 3)` instead of `(revision 5)`. | Pass: exact disclosed revision-bound result |
| `./rest-conformance-r2.sh > "$T/rest-conformance-r2.sh.rerun.log" 2>&1` | `PASS=120 FAIL=2 SKIP=0 TOTAL=122`; exit 1. The two FAILs are its OV-07 census and H1 expecting `(revision 2)`. | Pass: exact disclosed revision-bound result |

## Byte comparisons

I ran `cmp` between each fresh log and its paired `E/*.log`, then `diff -u` for every mismatch. None was byte-identical in full. The first differing lines are quoted below as committed → fresh; each diff is in `T`.

| Pair; `cmp` first difference | First differing lines | Remaining differences |
|---|---|---|
| `cargo-probes-r3.log`; byte 314, line 6 | `volatile: date-utc 2026-09-27T06:29:11Z` → `volatile: date-utc 2026-09-27T18:18:22Z` | Volatile scratch and target-directory lines; `lock: created snapshot locks-r3/baseB-msrv.lock` → `lock: reused snapshot locks-r3/baseB-msrv.lock`. All assertions and figures match. `T/cargo.diff`. |
| `cargo-probes-r3.run2.log`; byte 314, line 6 | `volatile: date-utc 2026-09-27T06:56:14Z` → `volatile: date-utc 2026-09-27T18:19:47Z` | Only the volatile scratch path also differs. `T/cargo-run2.diff`. |
| `crate-sources-r3.log`; byte 217, line 5 | `date-utc: 2026-09-27T06:22:21Z` → `date-utc: 2026-09-27T18:18:39Z` | Scratch path, rolling and all-time download counters, and their printed deltas differ. Every asserted `num`, `created_at`, `rust_version`, `license`, tarball SHA-256, and quoted source line is unchanged. `T/crate.diff`. |
| `github-api-r3.log`; byte 40, line 2 | `date-utc: 2026-09-27T06:23:04Z` → `date-utc: 2026-09-27T18:18:41Z` | The repository object's unasserted open-issue count for `open-telemetry/opentelemetry-rust` changed 254 → 256; the search API count, `full_name`, and `archived` did not. `T/github.diff`. |
| `rustsec-method-r3.log`; byte 91, line 2 | `volatile: date-utc 2026-09-27T06:26:50Z` → `volatile: date-utc 2026-09-27T18:18:39Z` | No other difference. `T/rustsec.diff`. |
| `decision-self-check-r3.log`; byte 106, line 2 | `volatile: date-utc 2026-09-27T07:12:24Z` → `volatile: date-utc 2026-09-27T18:18:48Z` | The disclosed H1 FAIL, decision digest, section line numbers, licence-subject line count, and summary change with revision 5. No other FAIL. `T/selfcheck.diff`. |
| `rest-conformance-r2.log`; byte 37, line 2 | `date-utc: 2026-09-19T01:33:00Z` → `date-utc: 2026-09-27T18:18:48Z` | The disclosed OV census and H1 FAILs, revision digest, and summary. The old census reads this item's later snapshots and audit mentions as another claimant; it is revision-bound, not evidence of another owner's claim. `T/rest.diff`. |

## Independent source checks and limit

- SHA-256 of the locally cached published tarballs was `89550ee9f79e88fef3119de263694973a8adb26c21d75322164fb8c493039fe2` for `metrics` 0.24.6 and `1db0d8f1fc9e62caebd0319e11eaec5822b0186c171568f0480b46a0137f9108` for `metrics-exporter-prometheus` 0.18.3. Both equal the fresh source log. The exporter's `Cargo.toml.orig:19` declares `default = ["http-listener", "push-gateway"]`; its `src/lib.rs:108-110` assigns upkeep to callers of `install_recorder`. `src/recorder.rs:91,125-139,142-143,312-315,413-418` confirms the revision-5 statement: render drains pending samples into cumulative distributions, while upkeep performs the same drain plus description publication. A failed or abandoned HTTP response does not discard those distributions while the process remains alive.
- At the py source pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, `src/py_launch_blueprint/web/settings.py:64` declares `metrics_enabled: bool = True`; `src/py_launch_blueprint/web/app.py:148-149` instruments only when enabled. This supports the default-true off switch.
- The Cargo rerun re-derived the load-bearing 51 → 79 runtime-crate count, the 119-package MSRV lock, the 78/78 exact-version metadata join, the two route-label values for 51 requests, and the parsed scrape. It did not run on Linux or build the unpublished R78 integration. The decision explicitly leaves those checks to P03, so neither is an unsupported claim.

No BLOCKING finding arose. M1 changes a test label, not its assertion or the recommended design.
