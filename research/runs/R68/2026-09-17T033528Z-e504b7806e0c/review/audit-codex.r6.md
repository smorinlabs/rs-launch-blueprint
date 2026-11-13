actor: codex
model: gpt-6-sol
family: openai
decision-sha256: bf71fda79b6b51278c5c54f945f2154606b7ba762d1e49578e4dcc64b0cbb900
verdict: approve
unresolved-findings:

1. **MECHANICAL — probe CPU header drift.** **Failed reproduced line:** `cpu: Apple M4 Pro` in the paired `profile-probe.r4.log`. The fresh log instead prints `sysctl: sysctl fmt -1 1024 1: Operation not permitted` and `cpu: `, because this sandbox denies `sysctl -n machdep.cpu.brand_string`. `system_profiler SPHardwareDataType` independently returned `Chip: Apple M4 Pro`. All 21 assertions passed; every `DELTA`, `BACKTRACE`, and `ASSERT` line matched byte for byte. **Repair:** make `profile-probe.sh` fall back to `system_profiler` or explicitly label an unavailable CPU field, and document that header variance in the reproduction rule. No measured direction changes.
2. **MECHANICAL — stale R50 source revision and locators.** **Failed claim:** the R50 hand-off cites its in-flight `DECISION.md` as “revision 6” with `--debug` at “lines 7, 116 and 335,” the dev-profile explanation at “line 433,” the R68 release-profile statement at “line 981,” and trigger (13) at “line 564”; the same revision-6 citation recurs in R68's build-time and engine paragraphs. The current R50 file is revision **7** (line 1). It still proposes `--debug` (lines 7, 111, 331), calls it a dev-profile compile (line 429), names R68's release compile (line 977), and lists trigger (13) (line 560). **Repair:** refresh all three R50 passages in R68 to revision 7 and these current locators, retaining the conditional, unaccepted status. This source drift does not change the profile recommendation.
3. **MECHANICAL — dist bootstrap version described too specifically.** **Failed claim:** the tool-and-pin row says dist's own generated workflow installs dist from “that GitHub Release's `cargo-dist-installer.sh`,” implying the workflow at `ref=v0.33.0` fetches `v0.33.0`. Its pinned `.github/workflows/release.yml` line 67 actually fetches `v0.32.0/cargo-dist-installer.sh`. The `v0.33.0` release has its own installer asset, and the same tag's `book/src/reference/config.md` lines 163–176 says release CI fetches the configured `cargo-dist-version`; the `0.33.0` pin remains supported. **Repair:** say that the self-release workflow demonstrates a GitHub Release installer bootstrap, cite the configuration rule and `v0.33.0` installer asset for the selected pin, and make the evidence check print the actual bootstrap version. The crate-registry gap still does not force a crates.io install.

## Scope and reruns

I verified the decision's SHA-256 with `shasum -a 256` before reading it, and again before writing this audit; both reads matched the header. I read `research/RUNBOOK.md` section 5 and the decision's `## Empirical check` and `## Engines`. I did not read any audit file, topic `raw/` directory, or review snapshot. The working directory for all three reruns was `/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/evidence`; output went only to `/tmp`. The inherited `CARGO_HOME` was `/tmp/cargo-s52-r68-emp`; the selected compiler and Cargo were the pinned Homebrew 1.98.1 builds. No toolchain or lockfile override was set.

| Command, run from that working directory | Fresh observed output | Paired current log and byte comparison |
|---|---|---|
| `./artifact-sources.sh > /tmp/r68-codex-r6-artifact-sources.log 2>&1` | exit 0; `RESULT: PASS`; **26 `ASSERT ok`, 0 `ASSERT FAIL`**; 23 release assets; `registry-gap-present=1` | `artifact-sources.r4.log`: `cmp` differs at byte 58, line 2. `diff -u` shows the UTC date, live download counters, and one star count only. Filtered `ASSERT`, `PINNED`, and `HEAD` lines are byte-identical. |
| `./profile-probe.sh > /tmp/r68-codex-r6-profile-probe.log 2>&1` | exit 0; `RESULT: PASS`; **21 `ASSERT ok`, 0 `ASSERT FAIL`**; lockfile SHA-256 `2756d45c172e38e05192d18dfc98cb028ff112dd1164b1f6a58d3cfc21ec1082` | `profile-probe.r4.log`: `cmp` differs at byte 49, line 2. `diff -u` shows the UTC date, denied CPU-header query, wall-clock `TIME` lines, and one `SIZE` line. Filtered `DELTA`, `BACKTRACE`, and `ASSERT` lines are byte-identical. |
| `./decision-self-check.sh > /tmp/r68-codex-r6-decision-self-check.log 2>&1` | exit 0; `RESULT: PASS`; **30 `ASSERT ok`, 0 `ASSERT FAIL`**; decision byte count 86,775 | `decision-self-check.r6.log`: `cmp` differs at byte 56, line 2. `diff -u` shows only the UTC date; all 30 assertion lines match. |

The first changed lines in the full-log diffs were:

```diff
artifact-sources.r4.log: -date(UTC): 2026-09-27T06:05:08Z
fresh artifact log:     +date(UTC): 2026-09-27T18:25:08Z
profile-probe.r4.log:   -date(UTC): 2026-09-27T06:05:22Z
fresh profile log:      +date(UTC): 2026-09-27T18:25:33Z
decision-self-check.r6.log: -date(UTC): 2026-09-27T17:12:01Z
fresh self-check log:       +date(UTC): 2026-09-27T18:24:59Z
```

The first substantive differences were `FIGURE cargo-dist ... recent_downloads(90d)=19281 downloads(all-time)=178421` versus `19312` and `178452` in the source log, and the denied CPU query in the profile log. The latter also changed `SIZE debug=line-tables-only` from **2,242,648** to **2,242,728 bytes** (+80 bytes), within the documented path-sensitive size behavior. Clean and incremental `TIME` lines varied; the script explicitly labels those wall-clock values non-reproducible. No asserted source content or profile outcome drifted. Fresh-log SHA-256 values, in command order above, were `11b7efd0d62b4820c3166c14daa0d455b966eb7293ddaa29fa579d2bc6c3bfb1`, `8c9c9032e5b5176fa03b8658ea4354cfe2baad9f7fd889b884b55b3b675d6128`, and `4bb242c666eecfb4f1d1ea657c20bc7151d06e785810f79dd2181276a778c270`.

## Load-bearing source checks

- The fresh probe measured a **1,994,032-byte** baseline, **1,675,728 bytes** for `lto = "thin"` plus one codegen unit, and **1,504,528 bytes** for `lto = "fat"` plus one unit. These rederive the decision's rounded **−16.0%** and **−24.5%** deltas and the **171,200-byte** marginal saving. The recommended build retained four backtrace frames; `strip = "symbols"` retained zero. `strip = "debuginfo"` remained byte-identical to baseline. The fresh `debug = "line-tables-only"` delta remained **+12.5%**, with two in-tree source-location lines and zero after the binary traveled.
- The fresh source log still shows GitHub release `v0.33.0` (published 2026-09-11T05:40:23Z), crates.io stable `0.32.0`, 23 `v0.33.0` assets including `cargo-dist-installer.sh`, and `registry-gap-present=1`. Its pinned follower-mode, runner-map, archive-naming, and installer evidence matched the committed log. `raw/codex.md` lines 588–589 independently contain the decision's **28.22 → 47.39 seconds** clean and **7.35 → 18.99 seconds** edit-rebuild figures for the `thin`-to-`fat` comparison.
- I fetched both `ref=v0.33.0` updater pages into `/tmp`. `book/src/reference/config.md` hashed to `1b45ad791749e55df2ed18267f5dcd104e961170cec3402c994bce3482d2d2a6`; `book/src/installers/updater.md` hashed to `b63bd80f0b60991197eac77a923309d03ce733c0e0508d8950ca3cca3729503c`. Both equal the decision's recorded body hashes. The former states `install-updater` defaults to `false` and installs a standalone updater alongside the program (lines 911–927); the latter distinguishes that executable from using `axoupdater` as an in-program library (lines 7–24). The revision-6 correction is supported.

**Assessment:** the reruns support the release-artifact and Cargo-profile directions. Dist execution, the release-please hand-off, binstall inference on a real release, and the shipped Linux binary remain explicit P03 acceptance checks in `## Engines`; the decision does not present them as completed. The three findings above are mechanical repairs under the revision-6 severity rule, so the verdict is **approve**.
