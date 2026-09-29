actor: claude
model: claude-opus-5-5
family: anthropic
role: empirical auditor
item: R73 idempotency-middleware (bundle, Deep)
decision: research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/DECISION.md, revision 1
decision-sha256: b7368070722f08e4a7a879896bf19bc929b5c823379060aa962d2fd6a5f37f40
audit-date-utc: 2026-09-27
verdict: reject
unresolved-findings:
1. P6-lru fails on rerun: `lru 0.18` now adds +3 packages, not the +5 the decision states.
2. The committed `r73-decision-shape.log` records a failing check (`D7-tree`, 29/30) and was never re-recorded.

# R73 revision 1 — empirical audit (claude)

## Identity check

`shasum -a 256 DECISION.md` →
`b7368070722f08e4a7a879896bf19bc929b5c823379060aa962d2fd6a5f37f40`, equal to the
expected hash. The audit proceeded against that exact revision.

## Currency determination

`## Empirical check` names **four** scripts as the evidence for revision 1:
`r73-standard-conformance.sh` (43), `r73-probe.sh` (26), `r73-sources.sh` (23)
and `r73-registry.sh` (17), totalling **109** checks. It states the comparison
rule: the three snapshot-mode logs must be identical except the single
`date_utc:` / `run_date_utc:` line, and `r73-probe.log` is stable only in its
`PASS`/`FAIL` lines, check count, eight dependency-tree totals and the
`Locking 62 packages` line. The fifth script, `r73-decision-shape.sh`, is not
cited in the decision; its header says "Run last", and it checks shape and
re-reads the four logs. All five were rerun. The four cited scripts are judged
under the decision's own comparison rule; the shape script is judged as
committed evidence.

## Environment

- `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, Darwin 25.4.0 arm64.
  The decision recorded `rustc 1.98.0`; that is toolchain drift, and every build, clippy and test check still passed under 1.98.1.
- Private `CARGO_HOME=/tmp/cargo-s15-R73-emp`.
- Every script ran from `review/evidence/`, with output to `/tmp/r73audit/<script>.log`.
  No file under `evidence/` was written; all scripts ran in the default `SNAPSHOT` mode, not `R73_REFRESH=1`.

## Reruns

| Script | Command | Exit | Totals (fresh) | `cmp` against committed log | Result under the decision's rule |
|---|---|---|---|---|---|
| `r73-standard-conformance.sh` | `bash ./r73-standard-conformance.sh > /tmp/r73audit/r73-standard-conformance.log` | 0 | 43 run, 43 pass, 0 fail, 0 skip | differs at line 3 only: `date_utc: 2026-09-19T01:36:34Z` → `2026-09-27T03:31:05Z` | **pass** |
| `r73-sources.sh` | `bash ./r73-sources.sh > /tmp/r73audit/r73-sources.log` | 0 | 23 / 23 / 0 / 0 | differs at line 3 only: `run_date_utc:` | **pass** |
| `r73-registry.sh` | `bash ./r73-registry.sh > /tmp/r73audit/r73-registry.log` | 0 | 17 / 17 / 0 / 0 | differs at line 3 only: `run_date_utc:` | **pass** |
| `r73-probe.sh` | `bash ./r73-probe.sh > /tmp/r73audit/r73-probe.log` (43 s wall) | **1** | 26 run, **25 pass, 1 fail**, 0 skip | differs from line 3 (volatile lines expected); **non-volatile difference at lines 79–80 and 92** | **fail** (finding 1) |
| `r73-decision-shape.sh` (live checkout) | `bash ./r73-decision-shape.sh > /tmp/r73audit/r73-decision-shape.log` | 1 | 30 run, 28 pass, 2 fail, 0 skip | differs at lines 3, 21, 55–57 | environmental — see below |
| `r73-decision-shape.sh` (clean extraction) | `git archive HEAD` extracted to `/tmp/r73audit/clean`, R73 run directory copied in from the working tree, script run there | 0 | **30 / 30 / 0 / 0** | differs at lines 3–5 (date, root, `in_git_worktree`) and 54–57: committed `FAIL D7-tree` → fresh `PASS D7-tree` | **pass**; the committed log is stale (finding 2) |

### Probe detail

The stable parts of `r73-probe.log` reproduce, except one line:

- `Locking 62 packages to latest Rust 1.96 compatible versions`: reproduced.
- `P1-*`, `P2-build`, `P2-clippy`, `P2-tower-edge`: all PASS.
- `P3-store`: 10 passed, 0 failed. `P4-web`: 18 passed, 0 failed.
- `P5-bench`: release **183 ns/op** (committed 275 ns/op). This is inside the decision's stated 179–373 ns/op spread and far below 1 ms. The figure is not asserted equal, so this is not a finding.
- `P6-baseline` 51, `P6-sha2` +8, `P6-hashlink` +3, `P6-quickcache` +9, `P6-minimoka` +11, `P6-moka` +14, `P6-axumidem` +37, `P6-axumidem-raw`, `P6-axumidem-versions`: all reproduce.
- **`P6-lru` fails.** First differing non-volatile lines:

```
< (committed)  lru 0.18               total=56   delta=+5   raw-report-claimed=+5
< (committed) PASS P6-lru — lru 0.18 adds +5 packages, reproducing the raw report's +5
> (fresh)      lru 0.18               total=54   delta=+3   raw-report-claimed=+5
> (fresh)     FAIL P6-lru — lru 0.18 adds +3 packages; the raw report claimed +5 — the raw figure does not reproduce
< CHECKS RUN: 26 PASS: 26 FAIL: 0 SKIP: 0
> CHECKS RUN: 26 PASS: 25 FAIL: 1 SKIP: 0
```

**Root cause, re-derived at source.**

1. `r73-probe.sh` declares `lru = "0.18"`, a caret requirement, in `mk_delta lru`, and it commits no lockfile.
2. `GET https://crates.io/api/v1/crates/lru/versions`, read on 2026-09-27, shows `0.18.5` published `2026-09-23T02:33:10Z`, unyanked, `rust_version 1.85.0`. That is four days after the decision's 2026-09-19 retrieval.
3. A scratch copy of the delta crate in `/tmp/r73audit/lru` resolves `lru v0.18.5 → hashbrown v0.17.1 → foldhash v0.2.0`. Its unique normal-graph count is 54, which is +3 over the baseline of 51.
4. `cargo update -p lru --precise 0.18.4` restores `hashbrown` → `allocator-api2 v0.2.21`, `equivalent v1.0.2` and `foldhash v0.2.0`. The count returns to **56**, which is +5.

The committed figure was therefore true for `lru 0.18.4`. The script's unpinned requirement is the defect.

### Shape-script detail

In the live checkout the fresh run fails `D3-snapshot` and `D7-tree`. Both failures come from uncommitted edits made by other sessions in this shared worktree, not from R73:

- **`D3-snapshot`.** `docs/port/PARAMETERS.md` is modified in the working tree: the R11 `ci-job-structure` value is filled in. `git show HEAD:docs/port/PARAMETERS.md | diff -q - <run>/inputs/PARAMETERS.md` reports the snapshot identical to HEAD.
- **`D7-tree`.** `check-research-tree.sh` reports acceptance failures for R55, R57, R62 and R72, for example `R72 audits[0] empirical family must be openai`. None of them concerns R73.

In the clean extraction of HEAD plus the R73 run directory, all 30 checks pass. These live-checkout failures are therefore not charged to the decision. The committed log is a separate issue (finding 2).

## Load-bearing figures re-derived at source (read-only public queries, 2026-09-27)

| Claim in the decision | Re-derived | Status |
|---|---|---|
| `sha2` 0.11.0 is the newest unyanked version, `rust-version` 1.85 | crates.io: `0.11.0 2026-03-25 1.85`; 90-day downloads 267,420,372 | holds (a download counter moving is expected) |
| `sha2` has no open advisory | `https://rustsec.org/packages/sha2.html` lists only `RUSTSEC-2021-0100`, patched at >= 0.9.8, as `E5-sha2` asserts | holds |
| `cratestack-axum` is excluded by gate 2 at `rust-version = "1.98.0"` | newest is now `0.14.0` (2026-09-27), still `rust_version 1.98.0` | exclusion holds; the version in the table is stale |
| `axum-idempotent` newest unyanked is 0.3.0; its stack costs +37 | newest is now `0.4.0` (2026-09-23). A scratch tree with `axum-idempotent = "0.4.0"`, `ruts = "0.10"`, `tower-cookies = "0.11"` counts 90 (+39) and pulls `ruts v0.11.1` | the argument (+37/+39 against +8) holds; the table is stale. The probe's `"0.3.0"` requirement excludes 0.4.0, so the check stays stable |
| Baseline 51; `sha2` +8 | reproduced by the fresh probe (`P6-baseline`, `P6-sha2`) | holds |
| Hit path "far below 1 ms" | 183 ns/op | holds |

Stale registry rows in a table dated "retrieved 2026-09-19" are recorded here for re-verification. They are not findings, because the decision dates them and none moves the recommendation.

## Findings

### 1. `P6-lru` fails: the `lru` tree delta no longer reproduces

- **Failed claim.** `## Empirical check`, `cargo tree -e normal` deltas row: "`+lru` 56 (+5)". Also the `### Principles and implementation` tally: "lru **+5** … checks `P6-moka` through `P6-hashlink`". Also the headline "**109 checks, 109 pass, 0 fail, 0 skip**".
- **Evidence.** The fresh `r73-probe.sh` exits 1 with `FAIL P6-lru — lru 0.18 adds +3 packages; the raw report claimed +5` and `CHECKS RUN: 26 PASS: 25 FAIL: 1 SKIP: 0`. The cause is `lru 0.18.5` (published 2026-09-23), selected by the unpinned `lru = "0.18"`. Pinning `0.18.4` restores 56/+5.
- **Impact.** The conclusion is not affected: `lru` is not recommended, and the "Dropped as unnecessary: a dedicated in-process cache crate" agreement holds at +3. The defect is that a cited check fails, and the executed-count claim is false today.
- **Repair (choose one).**
  - (a) Pin every delta requirement in `mk_delta` to the exact version measured: `lru = "=0.18.4"`, and likewise `hashlink`, `quick_cache`, `mini-moka`, `ruts` and `tower-cookies`, which are also caret today. Name the versions in the decision's delta row.
  - (b) Re-record at `lru 0.18.5`: set the expected delta to +3, and correct `DECISION.md` lines 352 and 538 and the `lru` registry row (newest `0.18.5`, 2026-09-23).
  - Recommendation: (a). It makes the check deterministic against future releases without a committed lockfile. Re-run and re-record `r73-probe.log`, then `r73-decision-shape.log`.

### 2. The committed `r73-decision-shape.log` records a failing check

- **Failed claim.** The evidence set is complete and passing. The paired log `evidence/r73-decision-shape.log` ends `CHECKS RUN: 30 PASS: 29 FAIL: 1 SKIP: 0`, with `FAIL D7-tree — scripts/check-research-tree.sh . failed: FAIL: publication lock is active; retry after its owner completes`.
- **Evidence.** The same script passes 30/30 on a clean extraction of HEAD plus this run directory, with `PASS D7-tree — scripts/check-research-tree.sh . passes`. The committed failure was lock contention at record time, and the log was never re-recorded.
- **Repair.** Re-run `r73-decision-shape.sh` after finding 1 is repaired, with no publication lock held. Commit the passing log.
  - Optional hardening: make `D7-tree` report `SKIP` rather than `FAIL` when the only diagnostic is the publication-lock message, so lock contention cannot be recorded as a defect.
  - Optional: name the shape script and its count in `## Empirical check`, so the evidence set the decision cites matches the directory.

## Non-blocking observations

- The toolchain drifted from `rustc 1.98.0` to `1.98.1`, and every build, clippy and test check passed under it. If exact toolchain reproduction matters, record it with a `rust-toolchain.toml` in the probe.
- Unit tests ran in a different order (libtest parallelism) and timings changed. Both are listed as volatile by the decision.
- The seven "Not executed, and carried as unproven" items remain unexecuted, and they are honestly labelled as such.
