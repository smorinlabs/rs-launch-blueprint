actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 844506614cbf6ff2a7ef4a816a7b3eea9e2d6804c34191d097e35209fb27b612
verdict: approve
unresolved-findings: none

# R10 empirical audit — revision 6

**Criterion applied.** A byte difference counts as a finding only if it falsifies
a claim the decision makes. The decision declares two surfaces variable in
advance. The first is section A0 of `r10-pinned-sources.log`: the host `rustc`,
`cargo`, `gh`, OS and `/usr/bin/grep` versions, plus the repository root. The
second is all of `r10-live-figures.log`, which the decision calls "explicitly
**not** byte-reproducible" and does not cite; it cites the `figures/*.json`
snapshots instead. Observed:

- 0 assertion lines differ.
- 0 cited snapshot values differ.
- 0 `ERROR` lines appear.
- Every byte difference falls in one of the two declared surfaces.

If the controller intended the literal "any byte drift = reject" rule, every
difference is quoted below so they can override this verdict. Under that rule,
though, `r10-live-figures.log` could never pass, because it records its own
retrieval date.

Decision hash verified first: `shasum -a 256 .../review/DECISION.md` →
`844506614cbf6ff2a7ef4a816a7b3eea9e2d6804c34191d097e35209fb27b612` (matches expected).

Host at audit time: `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`,
`cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, `gh version 2.101.0 (2026-09-15)`,
ShellCheck 0.11.0, macOS arm64. Working directory:
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. Rerun time: 2026-09-27 ~06:5x UTC (local date 2026-09-26).

## Rerun 1 — `r10-pinned-sources.sh` (unmodified vs HEAD)

```
E=research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/review/evidence
$E/r10-pinned-sources.sh > /tmp/r10r6/pinned.log 2>&1        # exit 0
cmp $E/r10-pinned-sources.log /tmp/r10r6/pinned.log
  → differ: char 111, line 3
```

Tail of the fresh log: `checks: 60 passed, 0 failed, 0 skipped` / `VERDICT: PASS`.
Line counts from `/usr/bin/grep -c`: 60 lines start with `PASS`, and 0 start with
`FAIL` or `SKIP`. The pattern `control fired` also counts 4, which means all four
A13 negative controls (A13.1–A13.4) fired.

Full `diff` (every differing line), all in A0, the declared host surface:

```
3,4c3,4
< rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)
< cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)
---
> rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)
> cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)
6c6
< gh version 2.98.0 (2026-08-20)
---
> gh version 2.101.0 (2026-09-15)
```

All 60 assertion lines are byte-identical to the committed log. That includes:

- the unpinned A8 `runner-images` reads;
- A9.1, which checks that the R42 `DECISION.md` hashes to `a2504aa7…`;
- both A11 raw-report hash checks.

The r2 and r4 rerun paragraphs predict exactly these three A0 differences.

## Rerun 2 — `r10-live-figures.sh` (working-tree version, modified vs HEAD)

```
(cd $E/figures && shasum -a 256 *) > /tmp/r10r6/figs-before.sha      # 17 files
R10_FIGURES_OUT=/tmp/r10r6/figs $E/r10-live-figures.sh > /tmp/r10r6/live.log 2>&1   # exit 0
(cd $E/figures && shasum -a 256 *) | cmp - /tmp/r10r6/figs-before.sha  → identical
git diff --stat -- $E/figures/                                          → empty
ls /tmp/r10r6/figs | wc -l                                              → 17
/usr/bin/grep -c ERROR /tmp/r10r6/live.log                              → 0
cmp $E/r10-live-figures.log /tmp/r10r6/live.log  → differ: char 123, line 4
```

Both logs are 82 lines. Every differing line is quoted below with the surface it
belongs to:

| Committed (2026-09-17) | Fresh (2026-09-27) | Surface |
|---|---|---|
| `gh version 2.98.0 (2026-08-20)` | `gh version 2.101.0 (2026-09-15)` | host version |
| `retrieval date: 2026-09-17 (UTC)` | `retrieval date: 2026-09-27 (UTC)` | retrieval date (now from `date -u`) |
| `snapshot directory: …/review/evidence/figures` | `snapshot directory: /tmp/r10r6/figs` | output path (override) |
| `Swatinem/rust-cache … 1917` | `… 1923` | live stars |
| `actions/cache … 5550` | `… 5559` | live stars |
| `actions-rust-lang/setup-rust-toolchain … 403` | `… 406` | live stars |
| `Swatinem/rust-cache open issues: 69` | `open issues: 70` | live count |
| `actions/cache open issues: 163` | `open issues: 162` | live count |
| `ten most recent issues: 381 375 374 370 369 352 348 344 341 337` | `ten most recent issues: 388 381 … 341` | live population |
| (absent) | `#388 open 0 2026-09-19T11:35:41Z none` | live population |
| `#337 closed 3 2026-05-11T11:07:28Z 0.115 d` | (absent) | live population |
| `maintainer replied on 3 of 10; unanswered by the maintainer: 7` | `… 2 of 10; … 8` | derived from population |
| `median … AMONG THE ANSWERED = 0.115` | `… = 1.171` | derived from population |
| `sccache crate.recent_downloads (90-day) = 129817` | `= 132718` | live counter (90-day window) |
| `sccache crate.downloads (all-time) = 1335826` | `= 1352410` | live counter |
| `…snapshots under …/review/evidence/figures are the citable artifacts.` | `…under /tmp/r10r6/figs…` | output path |

Apart from these, the line structure is identical. The working-tree script
differs from HEAD in exactly two ways: `RETRIEVED` now comes from `date -u`, and
the new `R10_FIGURES_OUT` override sets the output directory. Neither change
alters the log's shape or any unchanged value. The drift matches the decision's
revision-2, revision-3 and revision-4 enumerations figure for figure:

- stars 1917 → 1923, 5550 → 5559 and 403 → 406;
- open issues 69 → 70 and 163 → 162;
- #388 displaces #337, so 3-of-10 becomes 2-of-10 and the median moves 0.115 d → 1.171 d.

The `sccache` counters moved past the r4 values of 132 520 and 1 352 212. The
decision warns that the 90-day window moves between reruns. The releases,
`pushed_at` values, licences and #341 row did not change.

## Cited figures re-derived at source (committed snapshots)

All 17 snapshots carry `retrieved 2026-09-17 (UTC)`. Every value that the
decision's `## Empirical check` tables and prose cite matches its snapshot:

- **Stars:** 1917, 5550, 403, 206 and 133.
- **Repository fields:** `archived` is false on all five. The `pushed_at` values
  are 2026-09-07T21:44:07Z, 2026-07-15T18:13:46Z, 2026-09-07T22:03:58Z,
  2026-09-10T22:20:34Z and 2026-03-19T17:30:54Z.
- **Licences:** LGPL-3.0, MIT, MIT, Apache-2.0 and `null`.
- **Open issues:** 69, 163, 3 and 16.
- **Latest releases:** v2.9.2 at 2026-08-06T06:26:27Z, v6.1.0 at
  2026-06-26T19:17:06Z, v2.0.0 at 2026-09-07T21:53:31Z, and v0.0.11 at
  2026-07-29T11:19:11Z.
- **`sccache` crate:** `recent_downloads` 129817 and `downloads` 1335826. The
  newest unyanked version is 0.18.0, created 2026-09-16T14:34:17.177895Z, with
  licence Apache-2.0 and `rust_version` 1.91.0.
- **Issue #341:** closed, 5 comments, created 2026-05-13T21:29:13Z and closed
  2026-05-29T18:54:53Z.
- **Responsiveness:** 3 answered and 7 unanswered. The answered issues are #375
  at 0.025 d, #370 at 1.171 d and #337 at 0.115 d. The median among the answered
  is 0.115 d, and the median over all ten is undefined.
- **RustSec:** `rust-cache 404`, `sccache 404`, `atty 200` and `serde 404`.

## Secondary checks

- R42 hash binding: `shasum -a 256 research/topics/42-dev-toolchain-provisioning/DECISION.md`
  prints `a2504aa7e3ad210e788e41ef53fbf37505a5254f54fd31955f9d1d2b574f5e1c`.
  That equals `inputs/prerequisites.json:4` and the value the decision cites.
- `research/topics/11-ci-workflow-job-structure/DECISION.md:219` supports the
  decision's statement: 4 cache-bearing job ids on `ubuntu-latest` and 5
  job-runner pairs once R04's semver job is included.
- `shellcheck` 0.11.0 exited 0 with no findings on each script.
- `## Engines` claims are consistent with the rerun. The A11 hashes
  `74afacbc…` and `49b673ae…` equal the raw report filenames. A6.1–A6.3 (the
  delegation, the `cache` default and the absent `env-vars`) passed. The
  unproven rows U1–U14 are recorded as unproven and are not asserted as
  observed, which matches the "no CI run" statement.

## Findings

None. Both scripts execute and exit 0. The pinned-sources verdict is
`60 passed, 0 failed, 0 skipped`, and every cited figure is supported by its
committed snapshot. Every byte difference falls in one of the two variable
surfaces that the decision declares in advance.
