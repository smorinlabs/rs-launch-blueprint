actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 6a99c4116fd38fb8a3d57eb46e04681c0d48a1aea89851f716dc257bf9340f54
verdict: reject
unresolved-findings:
  1. `S10h` fails on the current tree; `r51-sources.sh` exits 1 and `r51-reproduce.sh` exits 1 (R68 citation not bound to a revision).
  2. The container log's declared volatile classes are incomplete, and the stated cause of byte-figure drift is contradicted by a same-BuildKit rerun.

# R51 container-image — empirical audit, decision revision 2

Scope: execution truth and evidence support only. The audit is independent of the
synthesizer and the judgment auditor. I read `DECISION.md` (`## Empirical check`,
`## Engines`, and the citations these sections point to) and `research/RUNBOOK.md` §5.
I did not read any `review/audit-*.md`, any `review/Rxx-r*-snapshot.md`, or any
`research/topics/*/raw/`.

## Identity of the target

`shasum -a 256 review/DECISION.md` →
`6a99c4116fd38fb8a3d57eb46e04681c0d48a1aea89851f716dc257bf9340f54`. This hash matches the
expected revision-2 hash. I recomputed it after all reruns and immediately before writing
this file, and it was unchanged.

## Host

The host is `Darwin 25.4.0 arm64`. It runs Docker server `29.8.0`, a BuildKit `v0.32.2`
`docker-container` builder created by the script, and `/usr/bin/grep (BSD grep, GNU
compatible) 2.6.0-FreeBSD`. `cargo` and `rustc` resolve at `/opt/homebrew/bin`. `gh` is
authenticated. Docker and BuildKit versions match the committed revision-2 run. Working
directory for every script:
`research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/evidence`. Every fresh log was
written to `/tmp/r51-audit/`. Nothing under `evidence/` was written.

## Reruns

| # | Command (from `evidence/`) | Fresh start (UTC) | Exit | Fresh totals | Committed totals | `cmp` against the committed log |
|---|---|---|---|---|---|---|
| 1 | `./r51-container.sh > /tmp/r51-audit/r51-container.log 2>&1` | 2026-09-27T03:19:44Z | 0 | `PASS=54 FAIL=0 SKIP=0 TOTAL=54` | `PASS=54 FAIL=0 SKIP=0 TOTAL=54` | differs at char 48, line 2 (see below) |
| 2 | `./r51-registries.sh > /tmp/r51-audit/r51-registries.log 2>&1` | 2026-09-27T03:19:45Z | 0 | `PASS=32 FAIL=0 SKIP=0 TOTAL=32` | `PASS=32 FAIL=0 SKIP=0 TOTAL=32` | differs at char 47, line 2; volatile lines only |
| 3 | `./r51-sources.sh > /tmp/r51-audit/r51-sources.log 2>&1` | 2026-09-27T03:21:00Z | **1** | **`PASS=131 FAIL=1 SKIP=0 TOTAL=132`** | `PASS=132 FAIL=0 SKIP=0 TOTAL=132` | differs at char 55, line 2; **one non-volatile verdict differs** |
| 4 | `./r51-reproduce.sh > /tmp/r51-audit/reproduction.log 2>&1` | 2026-09-27T03:23:10Z | **1** | **`reproduction-exit: 1`** | `reproduction-exit: 0` | differs at char 51, line 2 |

Container run 1 took `3:01.35` of wall time. After the run, `docker ps -a`, `docker buildx ls`
and `docker images` showed no object whose name contains `r51`. The script's cleanup
therefore held.

### 1. `r51-container.sh`: passes, but lines outside the declared volatile classes drift

The full `diff` of the committed log against the fresh log is below, abbreviated by
category.

- Declared volatile (class i): `date-utc:`, `scratch:`, `builder:`.
- Declared volatile (class ii): `C1b` (70 s → 35 s), `measured-wall-incremental-with-mounts`
  (10s → 15s), `measured-wall-incremental-no-mounts` (17s → 20s). The `C5c` message line
  (`10s < 17s` → `15s < 20s`) embeds these figures. Its ordering assertion still passes.
- **Not declared volatile:**
  ```
  < #1 pulling image moby/buildkit:buildx-stable-1 1.1s done
  < #1 creating container buildx_buildkit_r51-rehduv0
  ...
  < measured-disk-usage-main: 57769769
  > measured-disk-usage-main: 57769762
  < PASS  C9a — the busybox probe costs 812604 B (under 2 MB)
  > PASS  C9a — the busybox probe costs 812601 B (under 2 MB)
  < measured-size-noprobe: 11489706
  > measured-size-noprobe: 11489709
  < measured-size-busybox-delta: 812604
  > measured-size-busybox-delta: 812601
  < PASS  C9b — debian-slim + curl is 36869229 B, +199% over the selected 12302310 B
  > PASS  C9b — debian-slim + curl is 36869244 B, +199% over the selected 12302310 B
  < measured-size-debian-slim: 36869229
  > measured-size-debian-slim: 36869244
  < measured-disk-usage-debian-slim: 166539349
  > measured-disk-usage-debian-slim: 166539364
  ```
- Identical: `measured-size-main: 12302310` and `measured-binary-size: 1271368`. The check-id
  and verdict sequence (`PASS|FAIL|SKIP` plus id) is identical in the two runs.

See Finding 2.

### 2. `r51-registries.sh`: reproduces

`diff` shows only `date-utc:` and the four `gh-call-*-utc:` lines, all in class (i). `D3c`
(6156 tags) and `D5e` (`recent_downloads 1036172, downloads 4360576`) are unchanged. All
three pinned digests resolve (`D1a`, `D2a`, `D3a` PASS), and the all-zero control returns
404 (`D1e`).

### 3. `r51-sources.sh`: FAILS

```
100c100
< PASS  S10h — R68's premise that this item's answer must honour or hand back (DECISION.md:32)
---
> FAIL  S10h — R68's premise that this item's answer must honour or hand back: DECISION.md:32 does not contain [the web surface's delivery vehicle is R51's container image]
142c142
< SUMMARY: PASS=132 FAIL=0 SKIP=0 TOTAL=132
---
> SUMMARY: PASS=131 FAIL=1 SKIP=0 TOTAL=132
```

The other differences are declared volatile (class iii): `override-scan-files` and `S9c`
changed from 156 to 169, and `date-utc:` changed. See Finding 1.

### 4. `r51-reproduce.sh`: FAILS, with the same root cause as rerun 3

```
> fresh exit code: 1
> fresh    SUMMARY: PASS=131 FAIL=1 SKIP=0 TOTAL=132
> RESULT r51-sources: DIFFERS outside the volatile classes:
> 95c95
> < PASS  S10h — ... (DECISION.md:32)
> ---
> > FAIL  S10h — ...: DECISION.md:32 does not contain [the web surface's delivery vehicle is R51's container image]
...
> reproduction-exit: 1
```

`RESULT r51-registries` again reads "identical outside the volatile classes". `RESULT
container` again reads "the same check ids carry the same verdicts in both runs". This
script compares only the committed revision-1 and revision-2 container logs and does not
rebuild.

## Figures re-derived at source

| Figure in the decision | Re-derivation | Holds? |
|---|---|---|
| Selected image 12,302,310 B | fresh container run: `measured-size-main: 12302310` | yes, byte-identical |
| busybox costs 812,604 B | 12,302,310 − 11,489,706 = 812,604 (committed); fresh 812,601 | yes within 3 B; asserted by range (`C9a` < 2 MB) |
| debian-slim variant +199 % | 36,869,229 / 12,302,310 − 1 = 1.9969 (committed); fresh 36,869,244 | yes; asserted by range |
| rev-1 vs rev-2 main image within 0.1 % | (12,312,852 − 12,302,310) / 12,312,852 = 0.086 % | yes |
| rev-1 debian-slim ratio stays above +190 % | 40,163,283 / 12,302,310 − 1 = 2.26 | yes |
| First rev-2 run measured 57,769,770 B and failed `C2g`, `C9a` (`PASS=52 FAIL=2`) | `r51-container.r2-inspect-size.log` carries exactly those lines | yes |
| 0 third-party crates rebuilt with mounts, 50 without (`C4b`, `C5b`) | fresh run: `C4b` … `0`; `C5b` PASS | yes |
| `gh-call-*-utc` stamps, ≥ 21 s apart | committed log 00:48:33 / :54 / 00:49:16 / :37; fresh calls also 21–22 s apart | yes |
| R68 revision 1 `DECISION.md:32` carries "the web surface's delivery vehicle is R51's container image" | `git show HEAD:research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md`, line 32: present | yes at the committed revision; **no on the working tree** (Finding 1) |
| R68 `[profile.release]` = `lto = "fat"`, `codegen-units = 1` (used in the fixture) | committed R68 r1 `:51–53` and working-tree R68 r2 `:93–95` both carry it; fixture `r51-container.sh:218–220` matches | yes |

## Findings

### Finding 1: `S10h` fails; the R68 citation is not bound to a revision

- **Failed claims.** The first is the parameter citation "R68 revision 1
  (`research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md:32`)" (`DECISION.md:1326`),
  whose line `S10h` checks. The second is the `## Engines` re-verification row "R77, R80, R11,
  R02 and the ledger at the lines cited | `S9b`–`S9g`, `S10e`–`S10u` | every line holds at
  the revision named". The third is the `## Empirical check` result
  `./r51-sources.sh … # → SUMMARY: PASS=132 FAIL=0 SKIP=0 TOTAL=132, exit 0` together with
  `r51-reproduce.sh … # → reproduction-exit: 0`.
- **Evidence.** A fresh `r51-sources.sh` exits 1 with `SUMMARY: PASS=131 FAIL=1 SKIP=0
  TOTAL=132`. The single failure is `FAIL  S10h — … DECISION.md:32 does not contain [the web
  surface's delivery vehicle is R51's container image]`. A fresh `r51-reproduce.sh` ends
  `RESULT r51-sources: DIFFERS outside the volatile classes` and `reproduction-exit: 1`.
  - **Cause.** The working tree now holds an uncommitted R68 **revision 2**. Its title line
    reads `… decision (revision 2)`, and its mtime is 2026-09-26 18:20 PDT. R51's committed
    sources log is from 18:10 PDT. In revision 2 the quoted sentence moved to `:74`.
  - **Substance.** The premise itself survives in R68 revision 2 (`:74`), and
    `[profile.release]` is unchanged. The claim is true at the committed revision 1 (`git
    show HEAD:…:32`).
  - **Why the tree does not detect this.** The decision pins R77 and R80 by header line
    (`:1`), so a revision change fails distinctly. It pins R68 only by line number, and no
    `re-verify:` trigger names an R68 revision change. The existing R68 trigger ("when R68
    publishes or changes `[profile.release]` or its follower-mode release flow") has not
    fired. The only signal is this line-number failure.
- **Repair.**
  1. Bind R68 to a revision as R77 and R80 are bound: add a header-line assertion on R68's
     `DECISION.md:1`. Then re-point `S10h` and the `:1326` citation to the revision it binds.
     That is revision 2 at `:74` if R68 revision 2 is the current input, or else the
     preserved revision-1 bytes.
  2. Add "when R68 moves off the cited revision" to `re-verify:`.
  3. Rerun `r51-sources.sh` and `r51-reproduce.sh`, and update the recorded totals.
  4. Restate the `## Engines` row as true at the revision named after the re-point.

### Finding 2: container volatile classes are incomplete, and the drift explanation is contradicted

- **Failed claims.**
  - `## Empirical check`, "Reproduction, and exactly what varies": the three declared
    classes are "(i) the `date-utc`, `gh-call-*-utc`, `scratch:` and `builder:` lines …;
    (ii) every wall-clock figure …; (iii) live counters asserted by range …: `D3c` …, `D5e`
    …, and the sources script's file counts".
  - The same section's explanation of the rev-1 → rev-2 byte movement: "these are
    layer-archive differences between two BuildKit exporters, not content changes".
- **Evidence.** A same-host rerun on the **same** Docker 29.8.0 and BuildKit v0.32.2 moved
  several lines that no declared class covers:
  - `measured-size-noprobe`: 11489706 → 11489709.
  - `measured-size-busybox-delta`: 812604 → 812601.
  - `measured-size-debian-slim`: 36869229 → 36869244.
  - Both `measured-disk-usage-*` lines: 57769769 → 57769762 and 166539349 → 166539364.
  - The `C9a` and `C9b` message lines, which embed these figures.
  - The four buildx `#1 …` builder-creation progress lines, which carry the mktemp-derived
    builder name and a timing.

  Because the exporter version was identical, exporter version cannot explain the
  noprobe/busybox drift. The cause is run-to-run layer-archive variation. Not load-bearing:
  `measured-size-main` reproduced byte-identically (12,302,310). Every drifted figure is
  asserted by range (`C9a` "under 2 MB", `C9b` "+199 %"), and all 54 verdicts are unchanged.
  Separately, `r51-reproduce.sh`'s `VOLATILE` regex also filters `override-numbers-in-use:`,
  which the decision's stated classes do not list. Its value was unchanged in both runs, so
  there is no diff impact.
- **Repair.**
  1. Extend the declared volatile classes to name `measured-size-noprobe`,
     `measured-size-busybox-delta`, `measured-size-debian-slim`, `measured-disk-usage-*`, the
     `C9a`/`C9b`/`C5c` message lines, and BuildKit `#N` progress lines. Declare them as
     range-asserted or unasserted.
  2. Add `override-numbers-in-use:` to the stated classes, or drop it from the script's
     filter.
  3. Replace "differences between two BuildKit exporters" with the observed fact: run-to-run
     variation of a few bytes in re-exported layers even on the same BuildKit, with the
     selected image reproducing exactly.

## What reproduced cleanly

- The selected image's size, binary size, non-root PID 1, `healthy`/`unhealthy` probe
  paths, `ExitCode=143` drain, `/bin/sh` absence, and the 0-vs-50 cache-mount count all
  reproduce. All 54 container checks pass on a fresh build.
- All 32 registry and GitHub checks reproduce, with only declared-volatile lines differing.
- 131 of the 132 source checks reproduce. The exception is `S10h`.
