actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: d07d74abb54cc9fe516b41edbc3e5b163e467808fb6314740537cf9c0f017da8
verdict: approve
unresolved-findings: none

# R68 — empirical audit of DECISION.md revision 4

Scope: execution truth and evidence support only. Judgment about the recommendation is out of
scope. Audit date: 2026-09-27 (UTC `08:26` for the reruns). Fresh context. No
`review/audit-*.md`, `review/R68-r*-snapshot.md` or `research/topics/NN-*/raw/` file was read.
The run's own `raw/codex.md` was read only to re-derive the figures `## Engines` quotes from it.

## 0. Target hash

`shasum -a 256 review/DECISION.md` →
`d07d74abb54cc9fe516b41edbc3e5b163e467808fb6314740537cf9c0f017da8`. This matches the expected
digest, so the audit proceeded.

## 1. Environment

- Host toolchain: `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc
  2026-08-05) (Homebrew)`, LLVM 22.1.8, `aarch64-apple-darwin`. These are resolved from
  `/opt/homebrew/bin`, which is the pinned toolchain the decision names.
- Probe host line: macOS 26.4 (25E246), Apple M4 Pro.
- `CARGO_HOME=/tmp/cargo-s36-R68-emp` is a private cargo home that differs from both the
  r2 and r4 homes. `TMPDIR` is the default macOS per-user directory.
- Working directory: `review/evidence/`. Every output was written to `/tmp`, and no file
  under `evidence/` was written.
- `artifact-sources.sh` and `decision-self-check.sh` ran first, one after the other. The
  probe then ran in the background, and part of its run overlapped with them. This may
  inflate the probe's wall-clock `TIME` lines. It cannot affect any asserted value.

## 2. Reruns

| Command (cwd `review/evidence/`) | Exit | Result line | ASSERT totals (pass / fail / skip) | Byte-compare against the committed paired log |
|---|---|---|---|---|
| `./artifact-sources.sh > /tmp/r68-audit-r4/artifact-sources.log 2>&1` | 0 | `RESULT: PASS — every assertion held` | 26 / 0 / 0 | vs `artifact-sources.r4.log`: `cmp` reports a difference first at line 2 (`date(UTC):`). See 2a. |
| `./decision-self-check.sh > /tmp/r68-audit-r4/decision-self-check.log 2>&1` | 0 | `RESULT: PASS — every assertion held` | **28** / 0 / 0 | vs `decision-self-check.r4.log`: only line 2 differs (`date(UTC): 2026-09-27T06:12:08Z` → `2026-09-27T08:26:06Z`). The byte count line (`decision: DECISION.md (75710 bytes)`) is identical, so the committed log was produced against the audited bytes. |
| `./profile-probe.sh > /tmp/r68-audit-r4-probe.log 2>&1` | 0 | `RESULT: PASS — every assertion held` | 21 / 0 / 0 | vs `profile-probe.r4.log`: line 2 differs, as do 13 `TIME` lines and one `SIZE` line. See 2c. |

### 2a. `artifact-sources.sh`

Apart from the date line, the rerun and `artifact-sources.r4.log` differ on three lines.
Each is a live counter in a `FIGURE` line:

```
< FIGURE cargo-dist: ... recent_downloads(90d)=19281 downloads(all-time)=178421
> FIGURE cargo-dist: ... recent_downloads(90d)=19305 downloads(all-time)=178445
< FIGURE cargo-binstall: ... recent_downloads(90d)=130014 downloads(all-time)=3507400
> FIGURE cargo-binstall: ... recent_downloads(90d)=130257 downloads(all-time)=3507641
< FIGURE cargo-bins/cargo-binstall: ... stars=2895 ...
> FIGURE cargo-bins/cargo-binstall: ... stars=2896 ...
```

The decision's *Reproduction rule* paragraph predicts drift of exactly this kind: "`FIGURE`
lines carry live counters (download totals, star counts …)". All 26 `ASSERT` lines and every
`PINNED` and `HEAD` line are byte-identical.

The decision also claims that "`artifact-sources.r4.log` differs from `artifact-sources.r2.log` in the
`date(UTC):` line only". I confirmed this with `diff artifact-sources.r2.log artifact-sources.r4.log`: the
only differing line is line 2.

### 2b. `decision-self-check.sh`: the 28-assertion claim

The rerun printed 28 `ASSERT ok` lines, with no failures and no skips. I compared them item
by item with the decision's description in `## Empirical check`, and each part of that
description matches an assertion:

- H2 set: 1 assertion.
- The H3 `Principles and implementation`: 1.
- No `## Supersedes` section: 1.
- The title names revision 4: 1.
- The r1, r2 and r3 snapshot hashes: 3.
- A `re-verify:` line is present: 1.
- The prompt's `- owns:` line is empty: 1.
- The registry records no R68-owned parameter: 1.
- The prompt consumes R49's `build-tool-output-shape`: 1.
- Five `- assumes` lines plus a no-backticks assertion: 6.
- `COMMONALITY.md` lines 218, 224 and 78: 3.
- Two owner-review sections: 2.
- Three owner-reference assertions: 3.
- The `profile-probe.r2.log` lockfile sha256, and that log ending `RESULT: PASS`: 2.
- No email address under `review/`: 1.

The total is 28. The r4 changes named in the revision note are present:
`the title line names revision 4`, and
`the revision-3 snapshot is byte-identical to the audited revision 3`.
`decision-self-check.sh` line 89 compares against
`bb55cf4acbc9ce3ab4fb9ea7b0d969c2a86a77253640b52df1690a792155d4c2`, which is the revision-3
digest stated in the revision note.

### 2c. `profile-probe.sh`

- The rerun reproduced every `DELTA` line, every `BACKTRACE` line and every `ASSERT` line of
  `profile-probe.r4.log` byte for byte. I checked this by diffing each prefix separately:
  all three are identical.
- The lockfile line is unchanged at sha256 `2756d45c…1082` with 85 packages. The dependency
  tree still has 52 unique lines at default features and 93 with all features.
- One `SIZE` line differs: `debug=line-tables-only` changed from 2242648 to 2242728 bytes,
  an increase of 80 bytes, and its `DELTA` is unchanged. This is the path effect the
  decision tabulates. `CARGO_HOME` differed between the two runs.
- `TIME` lines differ, and the script labels them "wall clock, does not reproduce". My clean
  build went from baseline to recommended in 23 s → 33 s. The marginal clean build from
  `thin`+cu1 to `fat`+cu1 took 28 s → 33 s (about 1.2×). The bin-only rebuild took
  1 s → 12 s. The incremental figure still shows about an order of magnitude of separation,
  which is the only build-time claim the decision makes.

The decision's reproduction rule requires every `ASSERT` outcome and every `BACKTRACE` line
to match exactly, and every `DELTA` to fall within ±2.5 pp. The rerun satisfies it with
0.0 pp of drift.

## 3. Load-bearing figures re-derived at source

| Claim in DECISION.md | Source checked | Result |
|---|---|---|
| Lockfile sha256 `2756d45c…1082` with 85 packages | `shasum` of `profile-probe.Cargo.lock`, plus a count of its `[[package]]` entries | matches (85) |
| The Subject B size table: every `rslbp` byte count, Δ, and after-strip figure | `SIZE` and `DELTA` lines in `profile-probe.r2.log` | all 12 rows match |
| Backtrace table (4/101, 4/101, 0/101, 2/134, 5/101); `at ./src/` lines 2 → 0 | `BACKTRACE` lines in `profile-probe.r2.log` | match |
| Build-time table, r4 row: 16 s → 25 s, 18 s → 25 s, 0 s → 12 s | `profile-probe.r4.log` lines 34, 42, 44, 103, 104 | match |
| The other five build-time rows | `TIME` lines in `profile-probe.log`, `profile-probe.r2.log`, `profile-probe.r2-rerun-same-env.log` and `profile-probe.r2-rerun-alt-paths.log`. Revision 1's run 2 has no log, by the decision's own statement. | the four kept rows match |
| Clean ratio "about 1.3× to 1.9×"; marginal ratio "about 1.2× to 1.6×" | computed from the rows above: clean ratios 1.35, 1.71, 1.47, 1.88, 1.33, 1.56; marginal ratios 1.28, 1.39, 1.58, 1.20, 1.39 | holds |
| r2 → r4: `debug = "line-tables-only"` grew 96 bytes, and every `DELTA`/`BACKTRACE`/`ASSERT` line is byte-identical | `diff profile-probe.r2.log profile-probe.r4.log`: 2242552 → 2242648, and apart from that one `SIZE` line only `TIME` and date lines differ | matches |
| Revision 1's `strip = "debuginfo"` size of 1 994 112 bytes | `profile-probe.log` lines 27 and 45 | matches |
| `## Engines` quotes Codex's figures: 28.22 s → 47.39 s, 7.35 s → 18.99 s, and a 29.04 s baseline | `raw/codex.md`, sha256 `297219ed…`, which matches the revision note. The figures are on lines 311, 584 and 588–589. | match |
| `profile-probe.r2.log` lines 42/44 are `thin+cu1` 18 s and `fat+cu1` 25 s; lines 102–104 hold the incremental figures | the cited lines of `profile-probe.r2.log` | match |

Not re-derived: one citation points to `review/audit-claude.r2.md` §1c ("~2.4×"). This audit
was forbidden to read that file.

## 4. Findings

None. All three scripts pass on rerun. The self-check's count of 28 assertions is confirmed.
The new sixth row of the build-time table, for revision 4, matches `profile-probe.r4.log`.
Every figure checked in §3 re-derives from its cited source.
