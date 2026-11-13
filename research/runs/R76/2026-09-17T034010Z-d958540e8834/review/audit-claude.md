actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 55d7df033a12683fff26d3e8e7d6199b56b31e1628a6e27d27afc25ee170baeb
verdict: reject
unresolved-findings:
1. probe-checks.sh gate-2 assertion FAILS on rerun (hyper-util 0.1.21 raised the tree's maximum rust-version to 1.85).
2. The probe's binary-size figures drifted (+166,480 B claimed; +166,464 B observed), although the decision says the byte sizes are identical across runs.
3. probe-checks.sh is not hermetic to a caller's CARGO_TARGET_DIR: it aborts in section E before printing RESULT.
4. The committed rest-conformance-r2.log was not produced from the audited decision bytes (OV-08 line count 3 in the log, 4 in the file).
5. Point-in-time registry/GitHub figures and one cited line number (crates.io `Cargo.toml:170`) drifted.

# R76 cors-middleware — empirical audit of DECISION.md revision 2

## Scope and identity

- Target: `research/runs/R76/2026-09-17T034010Z-d958540e8834/review/DECISION.md`.
- `shasum -a 256` result: `55d7df033a12683fff26d3e8e7d6199b56b31e1628a6e27d27afc25ee170baeb`. This equals the expected hash.
- The same bytes are committed at `1228ae55` ("record R76's controller-allocated override number OV-08"). The working tree is unmodified for `review/`.
- Scope: execution truth and evidence support only. This audit makes no judgment on design merit.
- Read: `## Empirical check`, `## Engines`, and `research/RUNBOOK.md` §5.

## Host for this rerun (2026-09-27 UTC)

| Tool | Decision's host (2026-09-18) | This rerun |
|---|---|---|
| rustc | `1.98.0 (88d9e12ae 2026-08-18)` | `1.98.1 (48a229cea 2026-09-01) (Homebrew)` |
| cargo | `1.98.0 (797e8a9bc 2026-08-05)` | `1.98.1 (797e8a9bc 2026-08-05)` |
| gh | `2.98.0` | `2.101.0 (2026-09-15)` |
| grep | `BSD grep, GNU compatible 2.6.0-FreeBSD` | same |

- OS: macOS, arm64.
- Cargo home: private `CARGO_HOME=/tmp/cargo-s15-R76-emp`.
- The environment also sets `CARGO_TARGET_DIR=/tmp/cargo-s15-R76-emp-target`; see finding 3.

## Currency determination

`## Empirical check` names which scripts are current for revision 2:

- `rest-conformance-r2.sh` is the new check for revision 2.
- `registry-figures.sh`, `probe-checks.sh` and `decision-self-check.sh` are retained byte-identical from revision 1 (commit `3b933872`).
  - Their claims still underlie revision 2, which states that "every gate result, every figure … byte-identical to revision 1".
  - All four scripts are therefore current evidence for revision 2, and all four were rerun.
- `decision-self-check.sh` is **predicted** to fail on exactly one assertion: the H1 names revision 1.
  - `rest-conformance-r2.sh` section E bounds that failure.
  - That failure is therefore **not** a finding. It was confirmed as predicted (see rerun 1).

## Reruns

Working directory for every rerun:
`research/runs/R76/2026-09-17T034010Z-d958540e8834/review/evidence/`.
All output went to `/tmp/r76-audit/`. Nothing under `evidence/` was written.

### 1. `./decision-self-check.sh > /tmp/r76-audit/decision-self-check.log 2>&1`

- Exit 1. Result `PASS=42 FAIL=1 SKIP=0 TOTAL=43`, `RESULT: FAIL`.
- `cmp` reports a difference: `char 52, line 2`.
- The only failure is `ASSERT FAIL the H1 is the date-first form the revision rules require, naming the item, kind, tier and revision`.
  - Observed H1: `# 2026-09-18 — R76 — cors-middleware (crate, Focused) — decision (revision 2)`.
  - The committed log shows `(revision 1)`.
- The remaining `diff` hunks are expected and immaterial:
  - the `date(UTC)` line;
  - line-number shifts from revision 2's added text (`trigger line at 571; Parameters heading at 573` against `481`/`483`);
  - the gate-1 occurrence lines, renumbered (`151`, `153`, `587`, `611` against `111`, `113`, `497`, `521`).
- Verdict on this script: **matches the decision's prediction exactly.**
  - Exactly one FAIL, on the H1, with 42 passing.
  - `rest-conformance-r2.sh` section E independently asserted the same result on this rerun: `decision-self-check.sh exit=1; ASSERT FAIL lines=1; PASS=42`.
- Not a finding.

### 2. `./registry-figures.sh > /tmp/r76-audit/registry-figures.log 2>&1`

- Exit 0. Result `PASS=54 FAIL=0 SKIP=0 TOTAL=54`, `RESULT: PASS`.
- `cmp` reports a difference: `char 72, line 2`.
- Every `ASSERT` line is identical in text and verdict. The `diff` touches only `date(UTC)`, the `gh` version, and `FIGURE` or enumeration lines. See finding 5 for those.

### 3. `./probe-checks.sh > /tmp/r76-audit/probe-checks.log 2>&1` (inherited env, `CARGO_TARGET_DIR` set)

- Exit 1. The script aborted under `set -e` before printing a RESULT line.
- Last lines of the log:
  - `FIGURE clean release build, arm=without, run 2: 0.3 s`
  - `cp: /var/folders/…/r76-probe.vG2ji3/without/target/release/r76probe: No such file or directory`
- It also printed `ASSERT FAIL gate 2 over the tree …` at log line 74.

### 3b. `env -u CARGO_TARGET_DIR ./probe-checks.sh > /tmp/r76-audit/probe-checks.notarget.log 2>&1`

- Exit 1. Result `PASS=28 FAIL=1 SKIP=0 TOTAL=29`, `RESULT: FAIL`.
- First differing lines after the date and toolchain lines:

```
70d69
<   1.71.0 log
73,74c72,74
< FIGURE maximum declared rust-version in the resolved dependency tree = 1.80
< ASSERT ok   gate 2 over the tree, not just the crate: the highest declared rust-version among the dependencies is axum 0.8.9's 1.80, well inside the 1.96 floor
---
>   1.85 hyper-util
> FIGURE maximum declared rust-version in the resolved dependency tree = 1.85
> ASSERT FAIL gate 2 over the tree, not just the crate: the highest declared rust-version among the dependencies is axum 0.8.9's 1.80, well inside the 1.96 floor
```

- Also differing: the binary-size figures (finding 2), the `mktemp` path in the `cargo tree` line, and the build-second figures. The last two are declared variable and never asserted.
- All 13 behavioural `CHECK` observations reproduced:
  - `A`, `Q1`, `Q2-get`/`Q2-options`, `Q3-get`/`Q3-options`, `C`, `D`, `E` (including `access-control-max-age: 600`), `R1`, `P2`/`P3`, `H`;
  - the section C 0.6.11 re-run, where the sole difference is the `vary` value;
  - the dependency delta: 57 against 55 packages, adding exactly `tower-http 0.7.1` and `bitflags 2.13.2`;
  - the nine packages declaring no `rust-version`;
  - the facts about where `tower` sits in the graph.

### 4. `./rest-conformance-r2.sh > /tmp/r76-audit/rest-conformance-r2.log 2>&1`

- Exit 0. Result `PASS=59 FAIL=0 SKIP=0 TOTAL=59`, `RESULT: PASS`.
- `cmp` reports a difference: `char 81, line 2`.
- Sections A through E are byte-identical apart from `date(UTC)` and the rustc/cargo lines. This covers:
  - the blob identity (190,161 bytes, 3,427 lines, version 2.0.0);
  - all 17 quotations and both zero-counts;
  - the nine probe observations `X1` through `X9`;
  - the 11-rule naming loop;
  - the bounded failure of revision 1's self-check.
- Section F (the live `OVERRIDE` snapshot) moved as the decision predicted:
  - 15 distinct tokens became 17 (`OV-16` and `OV-17` added);
  - every assertion still holds.
- One section F line is not explained by live-state movement; see finding 4:

```
177c179
<         lines naming this item's controller-allocated number OV-08 = 3
---
>         lines naming this item's controller-allocated number OV-08 = 4
```

### Totals

| Script | Committed log | This rerun | `cmp` |
|---|---|---|---|
| `decision-self-check.sh` | 43/0/0 PASS | 42/1/0 FAIL (predicted, bounded) | differs |
| `registry-figures.sh` | 54/0/0 PASS | 54/0/0 PASS | differs (FIGURE lines only) |
| `probe-checks.sh` | 29/0/0 PASS | 28/1/0 FAIL (unset target dir); aborted (inherited env) | differs |
| `rest-conformance-r2.sh` | 59/0/0 PASS | 59/0/0 PASS | differs (date, toolchain, section F) |

Counts are PASS/FAIL/SKIP. Across all four scripts: 183 PASS, 2 FAIL, 0 SKIP. One FAIL is predicted and bounded. The other is unpredicted and is finding 1.

## Re-derived at source

- `hyper-util`'s published versions, fetched from `https://crates.io/api/v1/crates/hyper-util/versions?per_page=6`:
  - `0.1.21 2026-09-24T17:47:59.783880Z rust_version=1.85 yanked=false`
  - `0.1.20 2026-02-02T14:17:16.623245Z rust_version=1.64`
  - The drift in finding 1 is therefore caused by an upstream release **six days after** the evidence was recorded. It is not a fault in the original run.
- `OV-08` usage, from `git grep -n 'OV-08' -- research docs`:
  - No decision other than R76's uses `OV-08` as an override.
  - R79's decision line 620 records "`OV-08` through `OV-15` are reserved to R76".
  - The claim "OV-08 stays unused" is supported.
- `OV-08` count in the file, via `git show <c>:DECISION.md | grep -c OV-08`:
  - Commit `1228ae55` (the audited sha): 4 lines.
  - Commits `9861e066` and `46c2a531`: 0 lines.

## Findings

### 1. probe-checks.sh gate-2 assertion fails (unpredicted FAIL)

- **Failed claim.**
  - DECISION.md:167: "`rust-version` among the dependencies is **1.80** (`axum` 0.8.9)".
  - :779: "maximum declared dependency `rust-version` **1.80**".
  - :873: "(4) succeeds, since the measured tree maximum is 1.80".
  - :1005: "maximum 1.80".
  - The script asserts equality with that value: `assert "$(eq "$MAXRV" "1.80")"` at `probe-checks.sh:330`.
- **Evidence.**
  - Rerun 3b prints `1.85 hyper-util`, `FIGURE maximum declared rust-version in the resolved dependency tree = 1.85`, and `ASSERT FAIL gate 2 over the tree …`, giving `PASS=28 FAIL=1`.
  - Cause: crates.io published `hyper-util 0.1.21` on 2026-09-24 with `rust_version=1.85`. The probe pins `axum`, `tokio`, `tower-http` and `tower` exactly but leaves transitive dependencies unpinned and commits no lockfile, so it resolves the new release.
  - The substantive gate still holds, because 1.85 is at or below the 1.96 floor. The committed evidence script nevertheless fails, and the decision's quoted figure no longer reproduces.
- **Repair.** Do both of the following.
  - (a) Make the probe deterministic. Either commit the resolved `Cargo.lock` for each probe arm as an evidence snapshot and build with `--locked`, or add `cargo update -p hyper-util --precise 0.1.20` (and any other transitives that moved) after generation.
  - (b) Change the gate-2 assertion to the property the gate actually requires: `MAXRV` ≤ `1.96`, compared by version order. Print the maximum as a dated `FIGURE`.
  - Then reword DECISION.md lines 167, 779, 873 and 1005 as "1.80 as resolved on 2026-09-18 (1.85 after hyper-util 0.1.21, 2026-09-24); gate is ≤ 1.96". Re-record `probe-checks.log`.

### 2. Binary-size figures drifted despite "identical across runs"

- **Failed claim.**
  - DECISION.md:198–199 and :785: "**502,264 → 668,744 bytes** … **+166,480 B**".
  - The decision also says: "The two stripped byte sizes … were identical across runs."
- **Evidence.** Rerun 3b shows `FIGURE stripped release binary, arm=with: 668728 bytes` and `FIGURE binary-size cost of the CORS layer on this probe = +166464 bytes`. The without-arm is unchanged at 502,264.
- **Context.** The gate-6 assertions still pass, because the cost is positive and under 400 kB.
- **Cause.** Unpinned transitive dependencies (see finding 1) and the change from rustc 1.98.0 to 1.98.1.
- **Repair.**
  - Qualify the figures as bound to toolchain and lockfile: "rustc 1.98.0, lockfile as of 2026-09-18". State the reproducibility claim only under the finding-1 lockfile pin.
  - Alternatively, pin the toolchain with `rustup run 1.98.0` or a `rust-toolchain.toml` in the probe.
  - Then re-record.

### 3. probe-checks.sh breaks under an inherited `CARGO_TARGET_DIR`

- **Failed claim.** The script is self-contained: everything it writes lives under one `mktemp` directory ("runs unchanged from a clean `git archive HEAD` extraction").
- **Evidence.**
  - Rerun 3 aborted with `cp: …/r76-probe.vG2ji3/without/target/release/r76probe: No such file or directory`. The copy is at `probe-checks.sh:414`, which hard-codes `$WORK/$arm/target`.
  - The second "clean release build" printed `0.3 s`, because both arms shared the caller's target directory. Builds are then neither clean nor isolated.
  - The script makes no SKIP and prints no RESULT line; `set -e` terminates it.
- **Repair.** Add `unset CARGO_TARGET_DIR` near the top of the script, or `export CARGO_TARGET_DIR="$WORK/$arm/target"` per arm. Also consider `unset CARGO_BUILD_TARGET_DIR`. Then re-record.

### 4. Committed rest-conformance-r2.log does not match the audited decision bytes

- **Failed claim.** "`rest-conformance-r2.log` reproduces byte-for-byte apart from its header `date(UTC)` line and section F's namespace snapshot".
  - This implicitly claims the log was produced against this decision.
- **Evidence.**
  - The committed log line 177 reads `lines naming this item's controller-allocated number OV-08 = 3`.
  - The audited file, committed at `1228ae55`, has 4 such lines: DECISION.md:32, 701, 970 and 971. The fresh rerun prints `= 4`.
  - The count reads the decision file, which is not live namespace state. The committed log therefore observed a different text from the one under audit: its header `date(UTC): 2026-09-19T01:27:20Z` precedes that commit at 01:28:58Z.
  - The assertions pass either way, because the check is ≥ 2 lines.
- **Repair.** Re-run `rest-conformance-r2.sh` against the final revision-2 bytes (sha `55d7df03…`) and commit that log. Record in the log header the decision sha it read.

### 5. Point-in-time figures and one cited line number drifted (all asserts still pass)

- **Failed claims.**
  - DECISION.md:501 and :992–1003: "90-day **149,725,960**, all-time **462,114,603** … **913** stars … `pushed_at 2026-09-13T22:53:22Z`, **30** open issues … `open_issues_count` **37**".
  - :437 and :722: "`q=cors` reporting **1,452**".
  - :132 and :1003: "`rust-lang/crates.io` … `Cargo.toml:170`".
- **Evidence.** Rerun 2 printed each of the following:
  - `recent_downloads = 155129876` and `downloads = 479026426`;
  - `stargazers_count = 918`, `pushed_at = 2026-09-26T12:33:00Z` and `open_issues_count = 40`;
  - open issues `total_count = 32`;
  - `q=cors meta.total = 1476`;
  - the pin now at `168:tower-http = { version = "=0.7.1", …`, where the decision cites line 170;
  - several enumerated crates at new versions, for example `reinhardt-middleware 0.3.20`, `fandhe-backend-plugin-cors 0.4.1`, `toxi-middleware 3.1.1` and `apollo-cors 0.4.0`.
- **Context.** The decision itself labels these figures volatile. Every `ASSERT`, including `tower-http` 0.7.1 still being the newest release and the `=0.7.1` pin still present, reproduced.
- **Repair.**
  - Label each quoted figure "as of 2026-09-18" where it appears in `## Decision` and the Engines tables.
  - Cite the `rust-lang/crates.io` pin by commit sha plus content, for example `Cargo.toml@<sha>`, instead of a bare line number that moves.
  - No script change is needed.

## Not findings

- `decision-self-check.sh`'s single H1 failure. It was predicted, located and bounded by `rest-conformance-r2.sh` section E, and confirmed exactly on rerun.
- Section F's growth of the `OVERRIDE` namespace from 15 to 17 tokens. The decision declares this snapshot live, and its assertions survive the change.
