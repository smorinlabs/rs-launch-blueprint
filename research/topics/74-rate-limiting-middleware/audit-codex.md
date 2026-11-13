# R74 revision 3 empirical re-run audit

actor: codex-empirical
model: gpt-6-astra
family: openai
decision-sha256: bb2451a3a8fb3e4ccf377b70ba75ff7f4beede719355afd76e938c8122eddcc5
execution-point-in-time-sha256: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
verdict: approve
unresolved-findings: none

## Scope and reruns

The target is `review/DECISION.md` revision 3. Its SHA-256 was recomputed before any other read and again before this audit. The execution pin is the 2026-09-28 S79 point-in-time hash above. All script output and fetched payloads went to `/tmp`; the evidence directory and the run's inputs and snapshots were read only. The initial `r74-probe-r2.sh` and fetcher attempts could not resolve crates.io in the default network sandbox. Both were rerun with network access; the successful results below are from those reruns. No record or snapshot was overwritten.

| Evidence script | Result | Comparison with committed log |
|---|---|---|
| `r74-registry-figures.sh` | 88 PASS, 0 FAIL, 0 SKIP | Byte identical to `r74-registry-figures.log` |
| `r74-registry-figures-r2.sh` | 130 PASS, 0 FAIL, 0 SKIP | Byte identical to `r74-registry-figures-r2.log` |
| `r74-rest-conformance.sh` | 48 PASS, 0 FAIL, 0 SKIP | Byte identical to `r74-rest-conformance.log` |
| `r74-citations.sh` | 134 PASS, 0 FAIL, 0 SKIP | Byte identical to `r74-citations.log` |
| `r74-probe-r2.sh` | 87 PASS, 0 FAIL, 0 SKIP | Full bytes differ. All 89 assertion and summary lines match; all eight lockfile hash lines match as a set, but their order differs. The work directory and Cargo home also differ. |
| `r74-probe.sh` | 54 PASS, 0 FAIL, 0 SKIP | Full bytes differ; all 56 assertion and summary lines match. This is the carried revision 1 probe. |
| `r74-fetch-snapshots.sh` | Completed, 39 payload rows | Full bytes differ from `r74-fetch-snapshots-r2.log`, as `DECISION.md:660,821-823` discloses for a live fetch. The revision 1 fetch log is historical output of an earlier script revision. |
| `r74-decision-shape.sh` | 96 PASS, 0 FAIL, 0 SKIP; run last | Byte identical to `r74-decision-shape.log` |

## Revision 3 repairs and pins

- `DECISION.md:20,439-445,1140-1154` uses the published topic copy where one exists and the run copy otherwise. `r74-citations.sh:59-72` checked all seven coupled decision hashes. Each matched the file read. In particular, R69 revision 11 at `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` hashes to `2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815`. Its `:1200` calls `axum::serve(listener, app)`, its `:1885` names `crates/web`, and its full text has no `ConnectInfo` or `into_make_service`. Those reads support `DECISION.md:448-467`.
- R70 revision 5 at `research/runs/R70/2026-09-17T034010Z-31ad2ef28df7/review/DECISION.md` hashes to `a8d4da0ba18bad9bb581aad51f6e11234b29f3db14e1bbb99d2cfeb5e14d4b85`. Its `:121-122` makes `type` mandatory and assigns `code` to R70; `:229,235` carry the corresponding fields; `:391-393` provide response headers; and `:606-611` assigns the missing rate-limit catalog row to R74 to raise. These are the contents cited at `DECISION.md:469-490`. The R70 re-pin described at `DECISION.md:26-34` therefore resolves.
- R80's published revision 6 hashes to `4b63412a4dc1df4c2e31caa51fa20ca509c8e8cd430595f72b94de0843d4c204`; its `:911-912` carries the R75 placement hand-off. This confirms the repair at `DECISION.md:20`. R73 revision 4 `:1287-1291` still proposes rate limiting outside idempotency and leaves the choice to R74. R77 revision 5 `:965-987` reserves `RSLBP_WEB_RATE_LIMIT_*` with the three stated constraints. The cited R79, R02, and RUNBOOK lines passed the same positional and hash checks in `r74-citations.sh`.
- Both revised first-publication statements at `DECISION.md:317,906` say `2026-08-05` for `tower-rate-limiter` 0.1.0-alpha.0. The saved `snapshots-r2/cio-crate-tower-rate-limiter.json` and `cio-versions-tower-rate-limiter.json` both give `2026-08-05T17:39:14.701300Z`. This confirms `DECISION.md:21`.

## Findings

- **OBS-1 — Lockfile line order.** `DECISION.md:815-817` says the eight lockfile SHA-256 lines must be identical across reruns, within a 97-line comparison. The successful `r74-probe-r2.sh` rerun has all eight identical filename/hash pairs, but a different order: the committed log prints `probe_tg_default.lock` before `probe_tg.lock`; the rerun prints `probe_tg.lock` first. All 87 checks, the summary, and the dependency-set figures match. This is a reproducibility wording shortfall, with no effect on the tested claim.
- **OBS-2 — Disclosed live registry drift.** `DECISION.md:660,821-823` discloses that the fetcher is live and its log cannot reproduce byte for byte. The `/tmp` fetch has 39 payload rows. Since the committed 2026-09-27 snapshots, `tower-rate-limiter` all-time downloads changed from 296 to 299; `governor` reverse dependencies changed from 489 to 492; and `tower_governor` reverse dependencies changed from 82 to 83. The newest version, release date, `rust_version`, and yanked status for every cited versions payload are unchanged. The REST standard blob and source-manifest payloads are byte identical. The changed counters do not overturn a candidate disposition.

There are zero BLOCKING findings. Under `research/RUNBOOK.md:262-272`, the verdict is `approve`.
