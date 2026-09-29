actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: e247adb5d35e6076cebe58db9603d0909f56617aed03fb6a99c34c37c7800540
verdict: reject
unresolved-findings:
1. EA3-1 — `r35-sources.sh` fails `S2a` on rerun; the decision's cargo-tarpaulin release figures are stale.
   - Failed claim: `DECISION.md:163` "(2) `cargo-tarpaulin` 0.37.4: ... last release 2026-09-21; ... `rust_version` undeclared (`S2a`)". The same version is stale in the ranked runner-up (`:168`) and in the collector table header (`:121`). The Empirical-check `r35-sources.sh` row (`:286`) and total row (`:289`) were true when the synthesizer's rerun ran. They are no longer reproducible, so the repair must re-state them.
   - Evidence: the fresh `r35-sources.sh` run (2026-09-27T08:22:43Z) prints `INFO crates.io cargo-tarpaulin recent_downloads=296308 downloads=3049454 newest: 0.37.5 2026-09-27T08:13:55.127691Z rust_version=null license=MIT OR Apache-2.0`, then `FAIL S2a — cargo-tarpaulin newest non-yanked is 0.37.4 created 2026-09-21 with no rust_version declared`, and ends `SUMMARY PASS=24 FAIL=1`. The synthesizer's own rerun (`review/evidence/rerun-2026-09-27/r35-sources.log`, 07:39Z–07:42Z) still saw 0.37.4. The release therefore landed about 30 minutes after that rerun. When the synthesizer wrote the claim, it was true.
   - Mitigation (not a finding): the tarpaulin README at tag 0.37.5 (`GET repos/xd009642/tarpaulin/contents/README.md?ref=0.37.5`, fetched 2026-09-27T08:24Z) is byte-identical to `snapshots/cargo-tarpaulin-0.37.4-README.md`. Every `S12` claim therefore holds for 0.37.5. `rust_version` is still undeclared (null), and the recommendation (`cargo-llvm-cov` 0.9.1) does not depend on the runner-up's version.
   - Repair: rerun `r35-sources.sh`, and update `S2a` to assert the observed newest release (0.37.5, 2026-09-27, rust_version null). Update `:163` (version, last-release date, live counts), `:121`, and `:168` to 0.37.5. Alternatively, state explicitly that the ranking is pinned to 0.37.4 and that 0.37.5 has an identical README. Either way, re-state the Empirical-check rows `:286` and `:289` from the fresh log. Adding an `S12` line that shows the 0.37.5 README equals the 0.37.4 snapshot would keep the runner-up's README citations current.

## Hash check

`shasum -a 256 research/runs/R35/2026-09-26T190217Z-be98e8907e97/review/DECISION.md` gave `e247adb5d35e6076cebe58db9603d0909f56617aed03fb6a99c34c37c7800540`. This equals the expected revision-3 hash.

## Rerun

- Host: Darwin 25.4.0 arm64. Private `CARGO_HOME=/tmp/cargo-s38-R35-emp`, fresh and empty before `r35-install.sh` populated it.
- Working directory: the repository root. Run date: 2026-09-27, 08:20Z–08:23Z.
- `r35-install.sh`, `r35-sources.sh`, `r35-tarpaulin.sh` and `r35-flags.sh` ran from a `/tmp/r35emp/evidence` copy. The first three write snapshots or `SHA256SUMS-sources` next to themselves, so running them in place would have overwritten evidence. The other three (`r35-coverage.sh`, `r35-toolchain.sh`, `r35-inputs.sh`) are read-only and ran in place.
- Every log went to `/tmp/r35emp/logs/`. `find <run dir> -newer <first fresh log>` returned nothing, so nothing in the run directory was written.

| Script | Command | Committed | Fresh | `cmp` | Differing lines (PASS/FAIL level) |
|---|---|---|---|---|---|
| install | `bash /tmp/r35emp/evidence/r35-install.sh` | 8/0 | 8/0 | differ at line 1 | timestamp, `CARGO_HOME` path, `I1` wall clock `47s` → `54s`; PASS set identical otherwise |
| coverage | `bash <E>/r35-coverage.sh` | 29/0 | 29/0 | differ at line 1 | timestamp, `mktemp` fixture path, `C2a` `12s cold` → `16s cold`; PASS set identical otherwise |
| flags | `bash /tmp/r35emp/evidence/r35-flags.sh` | 29/0 | 29/0 | differ at line 1 | timestamp only |
| toolchain | `bash <E>/r35-toolchain.sh` | 7/0 | 7/0 | differ at line 1 | timestamp only |
| sources | `bash /tmp/r35emp/evidence/r35-sources.sh` | 25/0 | **24/1** | differ at line 1 | timestamp; rolling downloads (llvm-cov 90-day 1,682,448 → 1,685,922; tarpaulin 295,600 → 296,308; grcov 180,875 → 181,364); tarpaulin newest `0.37.4 2026-09-21` → `0.37.5 2026-09-27`; tarpaulin `pushed_at`; grcov stars 1368 → 1367; **`S2a` PASS → FAIL** |
| tarpaulin | `bash /tmp/r35emp/evidence/r35-tarpaulin.sh` | 7/0 | 7/0 | differ at line 1 | timestamp only; the 0.37.4-tag README is byte-identical to the committed snapshot |
| inputs | `bash <E>/r35-inputs.sh` | 128/0 | 128/0 | differ at line 1 | timestamp only |
| **total** | | **233/0** | **232/1** | | |

In the table, `<E>` means `research/runs/R35/2026-09-26T190217Z-be98e8907e97/review/evidence`.

The differing lines match what the decision predicts: timestamps, scratch paths, cold wall clock and rolling counts. The one exception is `S2a`. The fresh ratio is 1,685,922 / 296,308 = 5.69, the same value the decision quotes, so `S1b` still passes.

## Figures re-derived at source

- Raw report hashes: `raw/muse.md` = `583d7df2…1c638` (225 lines) and `raw/opus.md` = `68841401…d09cc1fd` (456 lines). Both match `## Engines`.
- Muse placeholders: 43 distinct `S_*` tokens on 26 lines. This matches `X3` and `## Engines`.
- The ratio 1,682,448 / 295,600 = 5.69 matches `S1b` and `:162`.
- Committed snapshots: all entries pass `shasum -c SHA256SUMS-sources`. The fresh `/tmp` snapshots differ only in the eight live crates.io and GitHub JSON bodies (downloads and push time).
- The `rerun-2026-09-27/r35-sources.log` file records 0.37.4 and `S2a` PASS. This confirms that the decision's "every PASS/FAIL line matched" was true at 07:4xZ.

## Judgement on everything else

`r35-coverage.sh`, `r35-flags.sh`, `r35-toolchain.sh`, `r35-install.sh`, `r35-tarpaulin.sh` and `r35-inputs.sh` reproduce their committed PASS/FAIL sets exactly. The only differences are the stated wall-clock drift of `C2a` and `I1`. The decision already describes those two timings as single-host, cold, non-comparative figures. The executed recipe claims hold on this host:

- the `--workspace` defect (`C4e`)
- the doc-test and branch-coverage rejections on stable (`F4`, `F5`)
- the 95/95/90 versus lines-80 discriminator (`C8b`, `C8c`)
- LLVM-tools discovery (`T1`–`T3`)

EA3-1 is the sole unresolved finding. It comes from upstream drift, not from an error in the synthesis. Under the rule that a failing script is a finding, however, the decision cannot be approved until its live figures and totals are re-stated against a passing `r35-sources.sh`.
