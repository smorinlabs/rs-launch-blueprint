actor: audit-claude-s32-r54r5
model: claude-opus-5-5
family: anthropic
decision-sha256: 7b5074c18b8d42d99458c73e4dfd5ed060993a1f18f56fa9f32e733b7ecaa9fe
verdict: approve
unresolved-findings: none

# R54 empirical audit — revision 5

Scope: execution truth and evidence support only, for
`research/runs/R54/2026-09-17T033527Z-8dfef31d60fc/review/DECISION.md`
at revision 5. I read `## Empirical check`, `## Engines` and
`research/RUNBOOK.md` section 5. I read no other seat's audit, no revision
snapshot, and nothing under `research/topics/54-*/raw/`. I made no git writes,
ran no `research_runner.py` command, and called no paid API. All fresh output is
under `/tmp/r54-audit-r5/`. Nothing under `review/evidence/` was written:
`find evidence -newer /tmp/r54-audit-r5/check-r5.fresh.log` printed nothing.

## Hash gate

```
$ shasum -a 256 review/DECISION.md
7b5074c18b8d42d99458c73e4dfd5ed060993a1f18f56fa9f32e733b7ecaa9fe  review/DECISION.md
```

This matches the expected hash.

## Host

`rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`,
`cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, Darwin 25.4.0 arm64. This is the
revision-5 toolchain the decision states.

## Reruns

Working directory: `review/evidence/`, unless a row says otherwise.

| # | Command | Observed | Totals | Result |
|---|---|---|---|---|
| 1 | `./check-r5.sh > /tmp/r54-audit-r5/check-r5.fresh.log 2>&1` | exit 0; `cmp check-r5.log <fresh>` found the files identical | 63 PASS, 0 FAIL, 0 SKIP (`failures=0 skipped=0`) | **pass**. Matches the claim "63 checks, 63 PASS, 0 FAIL, 0 SKIP, exit 0". |
| 2 | `./check-r5.sh > /tmp/r54-audit-r5/check-r5.rerun.log 2>&1; diff check-r5.log <rerun>` | exit 0; the diff is empty (0 bytes), like the committed `r5-rerun.diff` | 63 / 0 / 0 | **pass**. The in-place reproducibility leg reproduces. |
| 3 | `shellcheck check-r5.sh` | exit 0, no output. Matches the empty `shellcheck-r5.log`. | — | **pass** |
| 4 | `check.sh` in my own mirror, `/tmp/r54-audit-r5/mirror` (details below) → `/tmp/r54-audit-r5/check-on-r5-mirror.fresh.log` | exit 1 | 62 PASS, 2 FAIL (`U04`, `P06`), 0 SKIP (`failures=2 skipped=0`) | **pass**. Matches the claim "64 checks, 62 PASS, 2 FAIL, 0 SKIP; exit status 1", and the two FAILs are the ones the decision names. |
| 5 | `cmp check-on-r5-mirror.log <fresh mirror log>` | Differs at line 2. The full `diff` shows only the lines listed after this table. | — | **pass** under the decision's stated comparison rule. |
| 6 | `diff check.log <fresh mirror log>` | Changed lines: `repo-root`, `toolchain`, `F03`/`F04`/`F06` (counts only, all `PASS`), `U04` FAIL, `P06` FAIL, and `failures=2`. All other lines are byte-identical, including `Z01`–`Z04`, `D00a`–`D08`, `P01`–`P05` and the ten `PR1` probe cases with `PROBE-FAILURES 0`. | — | **pass**. This is exactly the set in the decision's diff table. |
| 7 | `diff check.log check-on-r5-mirror.log \| cmp - check-on-r5-mirror.diff` | identical | — | **pass**. The committed `.diff` is the true diff of the two committed logs. |
| 8 | `cmp check.log check-rerun.log` | identical | — | **pass**. This is the revision-1 in-place reproducibility claim. |
| 9 | `./check-r2.sh > /tmp/r54-audit-r5/check-r2-on-r5.fresh.log 2>&1` and `cmp` against the committed `check-r2-on-r5.log` | exit 1; identical | 40 PASS, 1 FAIL, 0 SKIP. The one FAIL is `FAIL V30 the decision is retitled to revision 2, date first (/usr/bin/grep -c -F matches=0)`. | **pass**. This is superseded-by-design: the FAIL is the title needle, as the decision claims. |
| 10 | `./check-r3.sh > /tmp/r54-audit-r5/check-r3-on-r5.fresh.log 2>&1` and `cmp` against the committed `check-r3-on-r5.log` | exit 1; identical | 31 PASS, 1 FAIL, 0 SKIP. The one FAIL is `FAIL E01 the decision is retitled to revision 3, date first (…matches=0)`. | **pass**. This is superseded-by-design: the FAIL is the title needle, as the decision claims. |

Each committed `-on-r5` log carries exactly one `FAIL`, and that `FAIL` is the
title needle. My fresh reruns of both scripts are byte-identical to the committed
logs.

Differences between rerun 5 (my mirror) and the committed mirror log:

```
2c2   repo-root  /tmp/r54-r5-mirror          →  /tmp/r54-audit-r5/mirror
32    F03 crate.downloads=900                →  901
33    F04 crate.downloads=69943              →  69949
34    F06 crate.downloads=113173002          →  113251804
```

The decision's comparison rule allows exactly these moves. The first is the
`repo-root` mirror-path line, which is "the mirror, not a finding". The other
three are the three live download counters, which only rise. Every
`PASS`/`FAIL` verdict matches, and each count stays on the same side of its
threshold (`F03` < 100000, `F04` < 1000000, and `F06` about three orders of
magnitude above both).

**How I built the mirror.** A leftover `/tmp/r54-r5-mirror` from the synthesizer
existed. I did not reuse it. My mirror copies, from the current working tree,
every path that `check.sh` reads:

- the run's `review/DECISION.md`, `review/evidence/`, `inputs/` and `raw/`;
- `docs/port/PARAMETERS.md`;
- the R53, R55 and R57 run decisions;
- the R52 and R67 topic decisions.

The `STANDARD_REPO` and `PY_REPO` absolute paths resolved to the live clones, so
`S*` and `Y*` ran rather than being skipped. `check.sh` wrote its snapshots only
inside the mirror.

## Re-derived at source

| Claim | Source check (2026-09-27) | Result |
|---|---|---|
| `etcetera` `max_stable_version` is 0.11.0 and no 0.12.x exists (Disagreement 4, `F01`/`F02`) | `GET crates.io/api/v1/crates/etcetera` returned `0.11.0`. `/versions` returned `['0.11.0','0.10.0','0.9.0',…]`. | holds |
| `xdg` latest is 3.0.0 (`F05`) | crates.io returned `3.0.0` | holds |
| `ruff/main/Cargo.toml:108` reads `etcetera = { version = "0.11.0", default-features = false }` (EF-4) | the live raw file, line 108, matches verbatim. It also matches `snapshots-r5/ruff-Cargo.toml`. | holds |
| `U01`: uv depends on etcetera 0.11.0 | live `uv/main/Cargo.toml:159` reads `etcetera = { version = "0.11.0", default-features = false }`. `U01`'s needle is the prefix `etcetera = { version = "0.11.0"`, so it still matches (`PASS` in rerun 4). | holds |
| `Q01`: inputs and registry differ only in `ci-job-structure` (EF-3) | `diff docs/port/PARAMETERS.md inputs/PARAMETERS.md` changes only row 12, `ci-job-structure`, owned by R11. | holds. The decision scopes this claim to the working tree. |
| Seven engine-table sha256 values (`## Engines`) | recomputed with `shasum -a 256` over `raw/muse.md`, `opus.md`, `doxa.md`, `doxa.normalized.md`, and the `doxa-openai`, `doxa-perplexity` and `doxa-gemini` normalized reports | all seven match |
| Muse leg: `succeeded`, `muse-spark`, collected 2026-09-22; `raw/codex-exit.txt` is `1` | `operations/muse.json`: `state=succeeded`, `model=muse-spark`, `2026-09-22T17:27:52Z`. `codex-exit.txt` is `1`. | holds |
| Bounded walk-up probe (`PR1`), 10 cases, `PROBE-FAILURES 0` | recompiled and run inside rerun 4; the output is byte-identical to the decision's quoted block | holds |

## Observations (non-blocking, not findings)

- `inputs/PARAMETERS.md`, `DECISION.md` and the revision-5 evidence files are
  uncommitted in this worktree (`git status` shows `M` or `??`). `Q01` and
  `check-r5.sh`'s `B` group certify the working-tree state, and the decision
  scopes `Q01` to the 2026-09-27 working tree. Publication must commit the
  bytes this audit hashed.
- Revision 5 of `check.sh` is expected to go red on `U04` and `P06`. The decision
  records and explains both FAILs. Their facts are carried forward by
  `check-r5.sh` `U04r5` and `Q01`, and both of those pass. They are therefore not
  findings.
