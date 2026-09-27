actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 35620b8ed243da9dff00b7f236521093e71a59209f435b7fd2790b9e33d37cfe
verdict: reject
unresolved-findings:
1. The declared reproduction contract omits `measured-size-main` and the `C2g` message line, and a same-host rerun moved both.
   - Failed claim (`## Empirical check`, volatile class 4, DECISION.md:1350–1354): "**Re-exported layer sizes**, which vary by a few bytes from run to run on the **same** Docker and BuildKit: `measured-size-noprobe`, `measured-size-busybox-delta`, `measured-size-debian-slim`, both `measured-disk-usage-*` lines, and the `C9a` and `C9b` message lines that embed them." DECISION.md:1363–1364: "Every other line — every `PASS`/`FAIL` verdict, every digest and every figure asserted by value — must be identical." DECISION.md:1359–1361 cites `measured-size-main` (**12,302,310 B**) as having "reproduced exactly". The `r51-reproduce.sh` header makes the same claim: "measured-size-main and measured-binary-size reproduced exactly in the empirical audit's rerun".
   - Evidence: I reran `./r51-container.sh` on the same host (Docker 29.8.0, BuildKit v0.32.2 builder), 2026-09-27T08:37Z. Result: `SUMMARY: PASS=54 FAIL=0 SKIP=0 TOTAL=54`, exit 0, all 54 check ids with unchanged verdicts. `diff` against the committed `r51-container.log` shows two lines outside every declared volatile class:
     ```
     < PASS  C2g — image size 12302310 B (under the 40 MB ceiling the debian-slim alternative exceeds)
     < measured-size-main: 12302310
     ---
     > PASS  C2g — image size 12302307 B (under the 40 MB ceiling the debian-slim alternative exceeds)
     > measured-size-main: 12302307
     ```
     `measured-binary-size: 1271368` reproduced exactly. The selected image therefore moved by 3 B, with the binary unchanged. This is the class-4 re-export variance the decision already describes, and it also reaches the selected image.
   - Impact: the claim about reproduction fails, but no conclusion changes. `C2g` asserts by range (under 40 MB) and still passes. The `C9b` ratio in my rerun is 36,869,261 B / 12,302,307 B = +199.7 %, above the +190 % floor.
   - Repair: (a) Add `measured-size-main` and the `C2g` message line to volatile class 4 at DECISION.md:1350–1354, and state that `C2g` asserts by range. (b) Restate DECISION.md:1359–1361 so it says `measured-size-main` reproduced exactly in the revision-1 audit's rerun and moved 3 B (12,302,310 → 12,302,307) in the revision-4 audit's rerun, while `measured-binary-size` reproduced exactly in both. (c) Make the same correction in the `r51-reproduce.sh` header comment. (d) If any sentence treats 12,302,310 B as an exact reproducible figure, word it as that run's measurement. No check and no recommendation needs to change.

## Scope and inputs

- Target: `research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/DECISION.md`, revision 4. `shasum -a 256` returned `35620b8ed243da9dff00b7f236521093e71a59209f435b7fd2790b9e33d37cfe`, which matches the expected hash.
- Read: `## Empirical check` (DECISION.md:1179–1433), `## Engines` (DECISION.md:1435–1707) and `research/RUNBOOK.md` section 5.
- Not read, as instructed: any `review/audit-*.md`, any `review/R51-r*-snapshot.md` and anything under `research/topics/*/raw/`. DECISION.md:1200–1201 and :1287 cite `review/audit-claude.r3.md` reruns. Checking those citations is outside my permitted scope, so they are **not verified** here. My own reruns below replace them.
- Host: macOS Darwin 25.4.0 arm64, Docker server 29.8.0, cargo at `/opt/homebrew/bin/cargo`. Working directory for every script: `research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/evidence`. Every fresh log was written under `/tmp/r51-audit-r4/`, and nothing under `evidence/` was written.

## Reruns

| # | Command | Fresh result | Byte comparison with the committed log |
|---|---|---|---|
| 1 | `./r51-container.sh > /tmp/r51-audit-r4/r51-container.log 2>&1` (2 min 53 s) | `SUMMARY: PASS=54 FAIL=0 SKIP=0 TOTAL=54`, exit 0 | `cmp`: differs at char 48, line 2 (`date-utc`). Remaining differences: the `scratch:` line, the `builder:` line, the `#1` buildx progress lines, `C1b` (70 s → 34 s), wall-clock mounts 10s/17s → 12s/18s with the `C5c` message line, `measured-disk-usage-*`, `measured-size-noprobe` 11,489,706 → 11,489,707, `measured-size-busybox-delta` 812,604 → 812,600 (`C9a` message), `measured-size-debian-slim` 36,869,229 → 36,869,261 (`C9b` message). All of these are declared volatile. **Not declared volatile:** `measured-size-main` and the `C2g` line (finding 1). Check id and verdict comparison: identical for all 54. |
| 2 | `./r51-registries.sh > /tmp/r51-audit-r4/r51-registries.log 2>&1` | `SUMMARY: PASS=32 FAIL=0 SKIP=0 TOTAL=32`, exit 0 | `cmp`: differs at char 47, line 2. `diff`: `date-utc`, the four `gh-call-*-utc` lines (08:37:25Z, 08:37:46Z, 08:38:08Z, 08:38:32Z, each at least 21 s apart), and `D5e` counters (recent_downloads 1036172 → 1037977, downloads 4360576 → 4362378). All are declared volatile (classes 1 and 3). |
| 3 | `./r51-sources.sh > /tmp/r51-audit-r4/r51-sources.log 2>&1` | `SUMMARY: PASS=162 FAIL=0 SKIP=0 TOTAL=162`, exit 0 | `cmp`: differs at char 55, line 2. `diff`: only `date-utc` (07:36:40Z → 08:37:00Z). All class-3 counters and `observed-*-live-*` lines were unchanged. |
| 4 | `./r51-reproduce.sh > /tmp/r51-audit-r4/reproduction.log 2>&1` (no arguments, networked host) | exit 0. `RESULT r51-registries: identical outside the volatile classes`, `RESULT r51-sources: identical outside the volatile classes`, `RESULT container: the same check ids carry the same verdicts in both runs`, `reproduction-exit: 0` | This is the full no-argument reproduction that DECISION.md:1291–1292 leaves to the empirical audit. It passes. |
| 5 | `./r51-reproduce.sh r51-sources > /tmp/r51-audit-r4/reproduction-sources.log 2>&1` | exit 0, `reproduction-exit: 0` | `diff` against the committed `reproduction.log`: only the two `date-utc` lines (07:36:45Z → 08:40:03Z). |

Totals across the three check scripts: 248 PASS, 0 FAIL, 0 SKIP, matching the committed 54 + 32 + 162.

## Load-bearing figures re-derived

- The dependency-caching mechanism for member 1 holds. `C4b` found 0 third-party crates recompiled with cache mounts, and `C5b` found 50 without them. Both are identical in the fresh run.
- The MSRV floor was exercised: the fresh lockfile line reads "Locking 54 packages to latest Rust 1.96 compatible versions".
- The runtime properties hold, all identical: `C3a` PID 1 at uid 65532; `C13a`–`C13c` unhealthy, FailingStreak 2, exit 1; `C14a` `/bin/sh` absent; `C12a` healthy on `cc-debian12`.
- `measured-binary-size: 1271368` is byte-identical.
- The size ratio for member 3 holds at +199 % (36,869,261 / 12,302,307 in the fresh run).
- Every live registry figure (`D1a`–`D6b`) and every GitHub figure (`G1a`–`G3a`) carries the same verdict and the same asserted value.

## Sibling snapshot pins

| Item | Snapshot | sha256 (recomputed) | Resolves to committed bytes | Live file |
|---|---|---|---|---|
| R77 r3 | `research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/R77-r3-snapshot.md` | `5985ee47…82bb92fd`, matching DECISION.md:1702 | yes: equals `DECISION.md` at `1e3cdb5b` ("R77 revision 3 — re-ground OV-04…") | revision 4, uncommitted (sha256 prefix `7e0cc569`) |
| R80 r3 | `research/runs/R80/2026-09-17T034011Z-74765d801b92/review/R80-r3-snapshot.md` | `184d2b17…0c8d230c8`, matching DECISION.md:1704 | yes: equals `DECISION.md` at `53b13f45`, as the decision states | revision 4, uncommitted (sha256 prefix `f0320a3a`) |
| R68 r1 | `research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/R68-r1-snapshot.md` | `070b7ae1…4578fd7`, matching DECISION.md:1700 | not traced to a commit; hash matches | not examined |

All three snapshot files are untracked (`??`) in this worktree. The pinned R77 line `:678` (defaults `127.0.0.1`, `8000`), the pinned R77 line `:931` (the R51 `Dockerfile` sets `RSLBP_WEB_HOST=0.0.0.0`) and the pinned R80 line `:548` (the standard names no health-probe rule) read as the decision quotes them.

## Observations (not findings)

- **Drift in the mid-resynth siblings.** Both live files are at an unaudited revision 4, as the decision discloses. The cited content still holds verbatim, but the line numbers have moved: R77 `:678` → `:782`, R77 `:931` → `:1091`, R80 `:548` → `:627`. The sources script logs these moves as `observed-r77-live-*` and `observed-r80-live-*` (class 3) and does not assert them. This is expected movement and no decision defect. If R77 or R80 is later accepted at revision 4, the pins and line numbers need rebinding.
- **Registries script not rerun by revision 4.** The decision discloses this. My rerun (rerun 2) confirms that the committed log still reproduces outside the declared volatile lines.
- **Tree check not run.** `scripts/check-research-tree.sh` was not run by this audit, and the decision makes no claim about it.
