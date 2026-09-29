actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 68e19cf3d99567dce2b6864ac968d652f1ae93d116c5f43e187fac82fbb6e246
verdict: reject
unresolved-findings:
1. EA-r2-1 (observed failure): `r74-citations.sh` fails 4 of 134 checks, because R80's decision has moved to revision 4, so the R80 citation is stale.
2. EA-r2-2 (evidence support, low): "crate first published 2026-08-06" for `tower-rate-limiter` does not match the snapshot, and no check asserts it.

# R74 revision 2 — empirical audit (claude seat)

Scope: execution truth and evidence support only. The target is
`review/DECISION.md` revision 2. Its sha256 was verified before any other step, and
it matched the expected value `68e19cf3…6fe246`. Sources read: `## Empirical check`,
`## Engines`, the `## Parameters` and hand-off prose that cites the scripts, and
`research/RUNBOOK.md` §5. I read no audit file, no `raw/` topic directory and no
revision snapshot.

## Environment

- `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1`, macOS 26.4 arm64.
- `CARGO_HOME=/tmp/cargo-s37-R74-emp`. It was **empty** when the probe started: `ls`
  printed nothing.
- `TMPDIR=/tmp/r74-audit/tmp/` for the probe's scratch crates.
- Working directory for every script:
  `research/runs/R74/2026-09-18T215916Z-14066395aaea/review/evidence/`.
- Every fresh log went to `/tmp/r74-audit/<script>.log`.
- I hashed every file under `evidence/` before and after the reruns. The two hash
  lists were identical ("EVIDENCE UNCHANGED"): no script wrote into `evidence/`,
  including `probe-locks/`.
- Note: `evidence/` is untracked in git (`?? …/review/evidence/`). "Committed log"
  below therefore means the on-disk log that revision 2 cites.

## Reruns

| # | Command (from `evidence/`) | Exit | Totals observed | Compared with the on-disk log |
|---|---|---|---|---|
| 1 | `TMPDIR=/tmp/r74-audit/tmp/ bash r74-probe-r2.sh > /tmp/r74-audit/r74-probe-r2.log 2>&1` | 0 | `CHECKS RUN: 87  PASS: 87  FAILURES: 0  SKIPPED: 0` | Not byte-identical, as the decision predicts (EA-4 rule); details below |
| 2 | `bash r74-registry-figures-r2.sh > /tmp/r74-audit/r74-registry-figures-r2.log` | 0 | `CHECKS RUN: 130  PASS: 130  FAILURES: 0  SKIPPED: 0` | `cmp` reports no difference: **byte-identical** |
| 3 | `bash r74-rest-conformance.sh > /tmp/r74-audit/r74-rest-conformance.log` | 0 | `CHECKS RUN: 48  PASS: 48  FAILURES: 0  SKIPPED: 0` | **byte-identical** |
| 4 | `bash r74-citations.sh > /tmp/r74-audit/r74-citations.log` | **1** | `CHECKS RUN: 134  PASS: 130  FAILURES: 4  SKIPPED: 0` | **differs** at char 1445, line 15 (finding EA-r2-1) |
| 5 | `bash r74-registry-figures.sh > /tmp/r74-audit/r74-registry-figures.log` (the drift baseline) | 0 | `CHECKS RUN: 88  PASS: 88  FAILURES: 0  SKIPPED: 0` | **byte-identical**, which confirms the decision's claim at `:624-626` |
| 6 | `bash r74-decision-shape.sh > /tmp/r74-audit/r74-decision-shape.log`, run **last** | 0 | `CHECKS RUN: 96  PASS: 96  FAILURES: 0  SKIPPED: 0` | **byte-identical** |

Not rerun, as instructed:

- `r74-probe.sh` is revision 1's probe, which `r74-probe-r2.sh` supersedes.
- `r74-fetch-snapshots.sh` is the network fetcher and asserts nothing.

`r74-decision-shape.sh` still passes `S6`, even though the citations script now
fails. `S6` reads the **on-disk** `r74-citations.log` and checks its
`FAILURES: 0` line. It does not rerun the citations script. The shape pass
therefore does not mask EA-r2-1.

### `r74-probe-r2.sh`: comparison under the decision's EA-4 rule

EA-4 is the decision's rule for comparing probe logs across runs. It names
the lines that must match and the lines that may differ.

- **Lines that must match (97):**
  - 87 `PASS` lines;
  - the `CHECKS RUN:` line;
  - `baseline=50 design=50 tracing=50 tg_nodefault=87 tg_default=99`;
  - the eight lockfile sha256 lines.

  I filtered both logs to these lines. All 97 are identical.
- **Every other line:** I removed the categories that EA-4 excludes (`toolchain:`,
  `cargo:`, `workdir:`, `cargo home:`, and cargo's `Compiling`, `Finished`, `Running`
  and download lines). After that removal, the only difference between the two logs
  was ordering. libtest printed `test settings_values_tune_but_never_disable ... ok` at
  a different position among the parallel test results. This is scheduling
  nondeterminism, not a content change.
  - Minor observation (not a finding): EA-4's excluded list does not name libtest's
    per-test lines, which can reorder. The 97-line claim that must match is true
    as written.
- **Cold cache: this closes a gap the decision left open.** The decision lists "a
  cold-cache run of `r74-probe-r2.sh` in a fully empty `CARGO_HOME`" as unproven
  (`:804-809`). This rerun started from an empty private `CARGO_HOME`.
  - Section L fetched all eight lockfiles online under `--locked`.
  - Every later `--offline` phase succeeded.
  - The recorded result was 87 PASS in 40.0 s wall time.

  Section L's cold-cache behaviour is therefore now observed, not only argued from
  the script's construction.

### Fetcher log

`r74-fetch-snapshots-r2.log` has 89 lines. It ends with `Snapshot manifest:` followed by
40 lines: a header and **39 rows**. Those 40 lines are byte-identical (`cmp`) to
`snapshots-r2/MANIFEST.tsv`, which also has 40 lines.

- `snapshots-r2/` holds 40 files: 39 payloads plus the manifest.
- No file name is duplicated in the manifest.
- The retrieval window runs from `2026-09-27T06:26:22Z` (the first row) to
  `06:30:16Z`. This matches the decision.

## Figures re-derived at source

The crate sources below were read from the cold `CARGO_HOME` that the probe filled.
The registry figures were read from `snapshots-r2/` with `jq`.

| Claim in the decision | Where I checked it | Result |
|---|---|---|
| `axum-governor` truncates `Retry-After` (`:907`) | `axum-governor-2.1.0/src/service.rs:496-497` reads `let delta = wait.as_secs();` then `let retry_after = delta.max(1);` | confirmed |
| `tower_governor` inserts `retry-after`, and the value is computed with `as_secs()` | `tower_governor-0.8.0/src/lib.rs:127,144,295,313` | confirmed |
| `tower-rate-limiter` 0.1.6 declares edition 2024, `rust-version` `1.96.0` and `MIT OR Apache-2.0` | its `Cargo.toml:13,14,43` | confirmed |
| `axum-governor` 2.1.0 declares `rust-version` `1.95` | its `Cargo.toml:14` | confirmed |
| `governor` 0.10.4 and `tower_governor` 0.8.0 declare no `rust-version` | the crates' `Cargo.toml` files contain no `rust-version` line | confirmed |
| `tower-rate-limiter`'s store is a fixed window (`E3`) | `src/limiter/store.rs:26` reads `/// An asynchronous fixed-window rate-limit store.` | confirmed |
| `tower-rate-limiter` has 296 all-time downloads and 0 reverse dependencies | `cio-crate-…` has `downloads` 296; `cio-revdeps-…` has `meta.total` 0 | confirmed |
| `tower-rate-limiter` has 7 stars and its repository was created 2026-08-02 | `gh-repo-nivek-ph-…`: `stargazers_count` 7, `created_at` `2026-08-02T15:41:21Z`, `full_name` `nivek3/tower-rate-limiter` | confirmed |
| `governor` has 489 reverse dependencies and `tower_governor` has 82 | `cio-revdeps-governor.json` and `cio-revdeps-tower_governor.json` report `meta.total` 489 and 82 | confirmed |
| Adding `tower-rate-limiter` adds 18 crates, including `moka`; the dependency counts are 50, 50, 50, 87 and 99 | fresh probe log: checks `E5` and `E6`, and the `baseline=` line with checks `C0`–`C5` | confirmed |
| The `tower-rate-limiter` crate was "first published **2026-08-06**" (`:288`, `:865`) | `cio-crate-tower-rate-limiter.json` `created_at` and `cio-versions-…` | **does not hold as worded**, see finding EA-r2-2 |

Controller note on R77 and R79: both citations resolve **now**. The working copies of
R77 (header "revision 4") and R79 (header "revision 3") hash to the values the
decision pins:

- R77: `7e0cc569…f884`, check `P77` passes;
- R79: `942ea9d2…bee1`, check `P79` passes.

Every cited R77 line (`R77-*`, 11 checks) and R79 line (`R79-*`, 6 checks) passes in the
fresh run. The R70, R73, R69 and R02 citations and the programme-document citations
also all pass. **R80 is the only sibling that moved.**

## Findings

### EA-r2-1: the R80 citation is stale, and `r74-citations.sh` fails (observed failure; reject)

**Failed claim.**

- `DECISION.md:488-491`: "R80 revision 3 (sha256
  `184d2b1714f8eb26a7b4df43b6020feb280662e85fcf3668a7fb0938d0d230c8`) records the
  probe-reachability problem as *"an input to R75, not a decision for it"* (`:760-761`)".
- `DECISION.md:1106-1107`, the same pin under Sources.
- `DECISION.md:620` and `:770-772`: `r74-citations.log` "134 PASS" and
  "Byte-identical on rerun".

**Evidence.** The fresh run exits 1 with
`CHECKS RUN: 134  PASS: 130  FAILURES: 4  SKIPPED: 0`. It first differs from the
on-disk log at line 15:

```
FAIL  P80 R80 revision 3 sha256 of research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md: expected [184d2b1714f8eb26a7b4df43b6020feb280662e85fcf3668a7fb0938d0d230c8] got [f0320a3a8b61064ab5072aeafcf7f24a9a51e68cc2f76fe4073af0c46d3295b8]
FAIL  P80h: research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md:1 does not carry [decision (revision 3)]
FAIL  R80-r75a: research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md:760 does not carry [and keep a catch-panic layer outside them. Recorded as an input to R75, not a]
FAIL  R80-r75b: research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md:761 does not carry [decision for it.]
```

**What changed in R80.**

- R80's working file was rewritten at 00:41 local time, after this revision's logs
  (00:19). Its line 1 now reads `… — decision (revision 4)`, and its sha256 is
  `f0320a3a8b61064ab5072aeafcf7f24a9a51e68cc2f76fe4073af0c46d3295b8`.
- Revision 3 survives only as git `HEAD`: `git show HEAD:<path> | shasum` returns
  `184d2b17…30c8`. `HEAD` itself is `e0b0d1c1`.
- **The substance is intact.** Revision 4's note says *"an audit repair; the
  recommendation does not move"*. The cited sentence appears verbatim at
  **`:839-840`**, where line 839 carries "…Recorded as an input to R75, not a" and
  line 840 carries "decision for it."
- The citation is therefore stale by pin and by line, not by meaning.
- Under RUNBOOK §5, acceptance requires current prerequisite decisions, and the
  decision's own script now fails.

**Repair.**

1. Re-pin R80 to revision 4 (`f0320a3a…95b8`, lines `:839-840`) at both
   `DECISION.md:488-491` and `:1106-1107`.
2. Update `r74-citations.sh` to match:
   - `P80`: the new sha256;
   - `P80h`: `decision (revision 4)`;
   - `R80-r75a` and `R80-r75b`: lines 839 and 840.
3. Regenerate `r74-citations.log`, then rerun `r74-decision-shape.sh` last.
4. R80 revision 4 is still an uncommitted working-tree edit. If it changes again
   before R74 is accepted, the pin will need repeating. An alternative is to pin R80
   by its owner-acceptance row once one exists.

### EA-r2-2: the `tower-rate-limiter` first-publish date is unsupported and misstates the snapshot (evidence support; low)

**Failed claim.** `DECISION.md:288` reads "crate first published 2026-08-06 and repo
created 2026-08-02 (`F2-dlall`, `F3`, `F5k`, `F5l`)". `:865` reads "its crate was first
published **2026-08-06**".

**Evidence.**

- None of the four cited checks asserts a first-publish date:
  - `F2-dlall` asserts downloads;
  - `F3` asserts reverse dependencies;
  - `F5k` asserts stars;
  - `F5l` asserts the repository's `created_at`.
- `F2-date` asserts only the **newest** non-yanked release (2026-08-13).
- The snapshot `cio-crate-tower-rate-limiter.json` gives `.crate.created_at` =
  `2026-08-05T17:39:14.701300Z`.
- `cio-versions-tower-rate-limiter.json` lists these early releases:
  - `0.1.0-alpha.0` on `2026-08-05T17:39:14Z`, `yanked=true`: the crate's first
    publication;
  - `0.1.0` on `2026-08-06T11:35:28Z`: the first **non-yanked** release.
- The decision's date is therefore true only of the first non-yanked release, and
  that qualifier is not stated.

**Impact.** No verdict turns on this. The practice-evidence exclusion stands on 296
downloads, 0 reverse dependencies and 7 stars, all of which are confirmed.

**Repair.**

1. Reword both sites to one of these two statements:
   - "first published 2026-08-05 (0.1.0-alpha.0, since yanked)";
   - "first non-yanked release 0.1.0 on 2026-08-06".
2. Add a `r74-registry-figures-r2.sh` check that reads the chosen date from the
   snapshot. For example, assert `.crate.created_at[0:10] == 2026-08-05`, or the
   earliest non-yanked `created_at` in the versions snapshot.
3. Cite that check at both sites.

## Verdict

**reject.** Five of the six reruns reproduce. Every load-bearing figure I
re-derived holds at source. The cold-cache gap is now closed by observation.

One asserting script fails on the current tree: `r74-citations.sh`, with
4 FAIL, because sibling R80 moved to revision 4 after this revision was pinned. That
failure is a stale-citation finding, and it needs a mechanical re-pin. One further
date claim is unsupported by its cited checks. Neither finding moves the
recommendation. Both repairs are mechanical.
