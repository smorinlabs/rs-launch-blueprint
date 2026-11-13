actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 5985ee47d5c714fdc317d5b8a8c58aff9c01b3f552834de8ac0b9c5282bb92fd
verdict: reject
unresolved-findings:
  1. probes.sh P6 silently measures 0 bytes when CARGO_TARGET_DIR is set, and two of its size checks then pass on the missing binary (3 FAIL, 2 vacuous PASS).
  2. ov-allocation-r3.sh "no third item claims OV-04" FAILs in the live tree because its census counts every *.md that quotes the literal, including auditor reports.
  3. The reproducibility rule "Exactly three kinds of line vary … Nothing else differs" is refuted by this rerun.
  4. Registry drift: config 0.15.26 (rust-version 1.88.0) is now the newest release and falls inside the runner-up's range; the decision records 0.15.25 / 1.85.0.
  5. Registry drift: figment's `pushed_at` moved from 2024-09-13 to 2026-09-27, so a signal behind its "at-risk" maintenance label is stale.

# Empirical audit — R77 revision 3

Role: empirical auditor (fresh context; independent of the synthesizer and the judgment auditor).
Item: R77 web-env-settings (crate, Focused).
Decision: `research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md` (revision 3).

## Summary

The decision's substantive claims reproduce. Every revision-1 figure reproduces at its
snapshot. Every quotation and rule line reproduces. All six Rust probes reproduce once one
environment variable is removed. The measured stripped-size deltas that carry the argument
reproduce to within 16 B. Nothing found moves the recommendation (no crate; template code
over `std::env::vars_os`) or the ranking.

The verdict is **reject** on two grounds:

- Two evidence scripts fail when rerun as written. Each failure exposes a check that can
  pass or fail for reasons unrelated to the claim it guards. This is the same class of
  defect revision 3 reports in revision 2's OV check.
- The decision's stated reproducibility rule is contradicted by the rerun.

Findings 4 and 5 are expected nine-day registry drift. Each needs re-recording, and
neither changes the outcome.

## Environment of this audit

| Item | Value |
|---|---|
| Date | 2026-09-27 UTC (2026-09-26 Pacific) |
| Working directory | `/Users/stevemorin/c/rs-launch-blueprint-p02-plan` (shared worktree; branch `research/p02-execution`, HEAD `e0b0d1c1`) |
| Toolchain | `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)` |
| Decision's toolchain | `rustc 1.98.0` / `cargo 1.98.0`. This is one patch of toolchain drift. |
| Cargo environment | `CARGO_HOME=/tmp/cargo-s15-R77-emp` (private, initially empty); `CARGO_TARGET_DIR=/tmp/cargo-s15-R77-emp-target` (set by the audit harness) |
| Output | Every fresh log was written under `/tmp/r77audit/`. Nothing under `review/evidence/` was written. |

Hash check performed before any other step:
`shasum -a 256 …/review/DECISION.md` →
`5985ee47d5c714fdc317d5b8a8c58aff9c01b3f552834de8ac0b9c5282bb92fd`. This matches the expected
value.

## Currency determination for revision 3

`## Empirical check` states which scripts are current and what each is expected to report
at revision 3:

| Script | Status at revision 3 | Expected result per `## Empirical check` |
|---|---|---|
| `figures.sh`, `sources.sh`, `probes.sh` | revision 1, carried | exit 0; 121/0/0, 84/0/0, 34/0/0 |
| `rest-conformance-r2.sh` | revision 2, carried and unedited | **PASS=90 FAIL=1 SKIP=0**. The one FAIL is its own `H1 is the date-first revision-2 title` check, which fails by design against the revision-3 title. |
| `ov-allocation-r3.sh` | revision 3, new | 43/0/0 |
| `fetch-snapshots.sh` | not an evidence check; no assertions | Its committed log is the first fetch (9 crates). The script's current list has 11 crates. |

The table labels `rest-conformance-r2.sh` "exit **0**". That label contradicts the same
section's own 90/1/0 statement, because that script exits 1 at 90/1/0. The text is
explicit, so I treat 90/1/0 as the claimed current state. I record the table cell as a
minor inconsistency and not as a separate finding.

The paired logs `rest-conformance-r2.log` (91/0/0) and `archive-rerun-r2.log` /
`rerun-diff-r2.log` are, by the decision's own account, the record of revision 2's clean
run. They are not revision 3's current state. The current-state logs are
`ov-allocation-r3.log`, `archive-rerun-r3.log` and `rerun-diff-r3.log`.

## Reruns

Each script was run in place as `bash research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/evidence/<name> > /tmp/r77audit/<name> 2>&1`,
then compared with `cmp` against the committed log and with `diff` on any mismatch.

### `sources.sh`

- Command: in place. Exit **0**. Result: **PASS=84 FAIL=0 SKIP=0 TOTAL=84**.
- `cmp`: the logs differ at char 27, line 1.
- `diff`: only the timestamp header differs
  (`# R77 sources — 2026-09-18T23:32:38Z` → `2026-09-27T03:41:33Z`).
- Result: **reproduced.**

### `figures.sh` (network)

- Command: in place. Exit **0**. Result: **PASS=121 FAIL=0 SKIP=0 TOTAL=121**.
- `diff`: the timestamp header differs, plus 9 `DRIFT` lines (`crate.recent_downloads`
  moved). Examples: `envy … snapshot=3574490 live=3618072`; `figment … snapshot=10072166
  live=10612179`; `envious … snapshot=66319 live=63469`. The `envious` value went down;
  this is a rolling 90-day window, so a decrease is expected.
- No `SNAPSHOT` or asserted `LIVE` line changed. This is the script's own stated comparison
  rule.
- Result: **reproduced.**
- The header's rule says "a DRIFT line may move upward for a counter". `recent_downloads`
  is a rolling window and can fall. This is cosmetic because DRIFT lines are not asserted.

### `probes.sh` (cargo, network for crate download)

**Run 1, in place, audit-harness environment.** Exit **1**. Result:
**PASS=31 FAIL=3 SKIP=0 TOTAL=34**. First differing lines under P6:

```
< baseline                   8         286048
---
> baseline                   8              0
…
> FAIL P6 config(no-default) stripped-size delta was 0 B, expected > 50000
> FAIL P6 figment stripped-size delta was 0 B, expected > 50000
> PASS P6 envy costs under 50 KB of stripped binary (0 B) — it is not excluded on size
> PASS P6 confique costs under 50 KB of stripped binary (0 B) — it is not rejected on cost
> FAIL P6 config-default stripped-size delta was 0 B, expected > 100000
```

Cause: `CARGO_TARGET_DIR` sends every build to `/tmp/cargo-s15-R77-emp-target`. The script
reads `$W/c_$n/target/release/c_$n`, which does not exist. Its `stat … || echo 0` fallback
then reports 0 bytes without error. See finding 1.

**Run 2, `env -u CARGO_TARGET_DIR bash …/probes.sh`.** Exit **0**. Result:
**PASS=34 FAIL=0 SKIP=0**. `diff` against the committed log shows these differences:

- the timestamp header;
- the toolchain lines (`1.98.0` → `1.98.1`);
- the three cargo-captured lines (the scratch dir name and `Finished … in 12.72s`), which
  the decision anticipates;
- one absolute size, `confique 302528` → `302544`, with its delta `16480` → `16496`
  (+16 B).

Every other size is byte-identical: baseline 286048, envy 302624, config-no-default 369248,
figment 385968, config-default 418960. The P1–P5 PASS lines are identical. P4 passed 4
tests with 0 failures, against axum 0.8.9. All five thresholds hold.

Result: **reproduced**, except that the one confique delta has toolchain drift (see
finding 3).

### `rest-conformance-r2.sh`

- Command: in place. Exit **1**. Result: **PASS=90 FAIL=1 SKIP=0 TOTAL=91**. This is the
  decision's stated current state.
- The one FAIL is the named title check:

```
> FAIL H1 is the date-first revision-2 title
>      expected: # 2026-09-18 — R77 — web-env-settings (crate, Focused) — decision (revision 2)
>      actual:   # 2026-09-18 — R77 — web-env-settings (crate, Focused) — decision (revision 3)
```

- Two other kinds of line differ from the committed revision-2 log:
  - the timestamp header;
  - the three OV "control" lines, whose file counts grew as the tree grew:

```
< PASS OV-01 is already taken (13 files) …   > PASS OV-01 is already taken (19 files) …
< PASS OV-02 is already taken (3 files) …    > PASS OV-02 is already taken (10 files) …
< PASS OV-03 is already taken (7 files) …    > PASS OV-03 is already taken (8 files) …
```

- Result: **matches the claimed 90/1/0.** The count lines are not among the decision's
  "three kinds of line" (finding 3).

### `ov-allocation-r3.sh`

**In the live worktree.** Exit **1**. Result: **PASS=42 FAIL=1 SKIP=0 TOTAL=43**. This
contradicts the claimed 43/0/0. First differing lines:

```
17a18,21
> research/runs/R02/2026-09-17T033527Z-40929a603f91/review/audit-claude.md
> research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/audit-claude.md
> research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/audit-fable.md
> research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/audit-fable.md
21c25,27
< PASS no third item claims OV-04 (only this item, the ledger, and optionally R80's renumber note)
---
> FAIL a third item claims OV-04: research/runs/R02/…/review/audit-claude.md
> research/runs/R51/…/review/audit-claude.md
> research/runs/R51/…/review/audit-fable.md
24,26c30,32
< unresolved-path search: 2 files matched, 0 survived the revision-2 exclusion
> unresolved-path search: 6 files matched, 0 survived the revision-2 exclusion
< PASS the corrected search sees 1 OV-04 holder(s) outside this item …
> PASS the corrected search sees 4 OV-04 holder(s) outside this item …
```

`git status` shows that the three "stray" files are **untracked** in-flight auditor
reports:

- `?? research/runs/R02/…/review/audit-claude.md`
- `?? research/runs/R51/…/review/`

I did not open them, because the audit rules forbid it. My conclusions rest only on the
paths `grep -l` returned.

**From a clean extraction of committed HEAD.** Command:
`git archive HEAD | tar -x -C /tmp/r77audit/arch`, then running the script inside the
extraction. Exit **0**. Result: **PASS=43 FAIL=0 SKIP=0**. It differs from the committed
log only in three places:

- the timestamp header;
- the resolved root path;
- one extra holder line: R77's own committed `audit-fable.md`. That file is under
  `runs/R77/`, so the exclusion accepts it. It changes the unresolved-search count from 2 to
  3, which is still correctly "0 survived".

Result: **reproduced at the committed tree; FAILS in the live tree** (finding 2). The
group-C assertions pass in both runs: the sha256 pins of the fourteen carried files, and
the re-run of `rest-conformance-r2.sh` at exactly 90/1/0 with the one expected FAIL line.
So revision 1 and revision 2 evidence is byte-identical to what was accepted.

### `fetch-snapshots.sh` (network; GitHub REST at the script's 21-second spacing)

- Command: I copied the script to `/tmp/r77audit/fetch/`, so that its `$here/snapshots`
  output could not overwrite `review/evidence/snapshots/`. I ran it from there. Exit **0**.
- It wrote 37 files. The committed directory also holds 37 files.
- `diff` of the logs shows only the documented differences:
  - the start and finish timestamps;
  - four extra `wrote` lines for `pathdiff` and `winnow`. The decision explains these: the
    committed log is the 9-crate first fetch, and the script's list was later extended
    to 11.
- Result: **reproduced as described.**

I then compared the fresh snapshots field by field against the committed ones, for every
field `figures.sh` cites:

| Field | Result |
|---|---|
| newest non-yanked `num` / `created_at` / `rust_version` / `license`, 10 of 11 crates | unchanged |
| `config` | **changed:** `0.15.25 / 2026-06-26 / 1.85.0` → `0.15.26 / 2026-09-21 / 1.88.0` (finding 4) |
| `channel-rust-stable.toml` `[pkg.rust] version` | unchanged, `1.98.1 (48a229cea 2026-09-01)` |
| open-issue `total_count` | unchanged except `serde-env`, 1 → 0 |
| `archived` | unchanged |
| stars | unchanged except `config-rs`, 3210 → 3214 |
| `pushed_at` | moved for `config-rs` (2026-09-15 → 2026-09-25), `serde-env` (2026-04-15 → 2026-09-19) and **`Figment` (2024-09-13 → 2026-09-27)** (finding 5) |

## Figures re-derived at source

- **Gate 2 (`rust-version`).** I re-read the fresh `/versions` snapshots.
  - `envy` 0.4.2, `figment` 0.10.19, `envconfig`, `serde-env` and `envious` still declare
    none. `figment`'s newest release is still 0.10.19, so its gate-2 exclusion stands.
  - `confique` still declares 1.68.2.
  - `config`'s newest now declares 1.88.0. That is still below the 1.96 floor, so the
    runner-up still passes gate 2.
- **The runner-up's range admits 0.15.26.** I measured `config = "=0.15.26"` with
  `default-features = false`, using the same program and release profile as probe P6:

  | Measure | 0.15.26 | 0.15.25 |
  |---|---|---|
  | `cargo tree -e normal` package count | 11 | 11 |
  | stripped size | 369,232 B | 369,248 B |
  | delta over the 286,048 B baseline | +83,184 B | +83,200 B |

  For `RSLBP_WEB_PORT=eighty`, 0.15.26 prints
  ``invalid type: string "eighty", expected an integer for key `port` in the environment``.
  That is verbatim the decision's line-276 string for 0.15.25.
- **Stripped-size deltas** (decision lines 329–333, 388, 562, 582, 594–595), at rustc 1.98.1:
  - reproduced exactly: envy +16,576 B, config-no-default +83,200 B, figment +99,920 B,
    config-default +132,912 B;
  - confique measured +16,496 B, against +16,480 B cited.
- **Stable Rust 1.98.1, so the floor is 1.96.** Reproduced from the channel file.

## Findings (all unresolved)

### 1. `probes.sh` P6 measures a missing binary as 0 bytes, so two size checks cannot fail

- **Failed claim.** `## Empirical check` says: "`probes.sh` **PASS=34 FAIL=0 SKIP=0**".
  Under the table "Re-verified in this run": "Package counts 8 / 9 / 12 / 11 / 16 / 55 |
  probe P6 … **reproduced exactly**". It also says `probes.sh` "asserts five size
  *thresholds*".
- **Evidence.** A plain in-place rerun with `CARGO_TARGET_DIR` set gave
  `PASS=31 FAIL=3`. `bytes=$(stat -f%z "$W/c_$n/target/release/c_$n" 2>/dev/null || … || echo 0)`
  turns a missing artifact into 0 without any error. As a result:
  - `PASS P6 envy costs under 50 KB of stripped binary (0 B)` passed;
  - `PASS P6 confique costs under 50 KB … (0 B)` passed.

  Both upper-bound checks therefore pass when nothing was built. The preceding
  `cargo build … >/dev/null 2>&1 || true` also discards any build failure. The same
  vacuous PASS would occur if the envy or confique build failed outright. With
  `env -u CARGO_TARGET_DIR`, the script gives 34/0/0.
- **Repair.**
  - Pass `--target-dir "$W/c_$n/target"` to every `cargo build`, `cargo test` and
    `cargo tree` in `probes.sh`, or `unset CARGO_TARGET_DIR` at the top.
  - Replace the `|| echo 0` fallback with an explicit FAIL when the binary is missing or
    has size 0.
  - Stop discarding `cargo build`'s exit status.
  - Add a negative control: point one build at a nonexistent path and assert that it
    FAILs.
  - Record the fix as a new revision-4 script. Leave revision 1's script unedited, as
    revision 3 did for revision 2's.

### 2. `ov-allocation-r3.sh`'s "no third item claims OV-04" treats any quotation as a claim

- **Failed claim.** `## Empirical check` says: "`ov-allocation-r3.sh` **PASS=43 FAIL=0
  SKIP=0**". The script's check reads: "no third item claims OV-04 (only this item, the
  ledger, and optionally R80's renumber note)".
- **Evidence.** A live-tree rerun gave `PASS=42 FAIL=1`, with
  `FAIL a third item claims OV-04: research/runs/R02/…/review/audit-claude.md`,
  `research/runs/R51/…/review/audit-claude.md` and
  `research/runs/R51/…/review/audit-fable.md`.

  The census is
  `find "$root/docs" "$root/research" -name '*.md' | xargs grep -l 'OVERRIDE (OV-04)'`.
  It counts every Markdown file that *mentions* the literal as an item that *claims* the
  number. That includes auditor reports, ledgers and notes.

  These three files are currently untracked, so a clean `git archive HEAD` still gives
  43/0/0. They are auditor reports of the kind that is committed at publication. Once
  they are committed, the check will fail at HEAD as well.

  The ledger's own rule (execution-ledger.md:1074) is: "census `OVERRIDE (OV-nn)` across
  research/topics and research/runs". Its intent is declarations in decisions, not
  every mention of the string.
- **Repair.**
  - Restrict the stray-holder census to decision files:
    `-name DECISION.md` under `research/runs` and `research/topics`. Better still, restrict
    it to a declaring heading, `^#+ OVERRIDE \(OV-04\)`.
  - Exclude `review/audit-*.md` explicitly.
  - Keep a positive control showing that the narrowed search still finds R77's own
    heading.
  - Separately, add a note to the decision's `## Empirical check`. The note should say
    that the corrected-search count ("sees 1 OV-04 holder(s) outside this item") is a live
    tree census and not a fixed figure; it was 4 in this rerun.

### 3. The stated reproducibility rule is refuted

- **Failed claim.** `## Empirical check` says: "Exactly three kinds of line vary, and this
  is the rule for comparing across a re-run: … Nothing else differs." It also says of
  `rest-conformance-r2.sh`: "every input it reads is a committed file or a git blob, with
  no counter".
- **Evidence.** This rerun found four further kinds of varying line:
  - `rest-conformance-r2.log`: `OV-01 … (13 files)` → `(19 files)`, `OV-02 (3)` → `(10)`,
    `OV-03 (7)` → `(8)`. These are live-tree census counts that grow as other items
    publish.
  - `ov-allocation-r3.log`: the holder list, `unresolved-path search: 2 files matched` →
    `6`, and `corrected search sees 1` → `4`.
  - `probes.log`: the `# rustc:` / `# cargo:` version lines (1.98.0 → 1.98.1), and one
    absolute size line, `confique 302528` → `302544`, with its PASS line
    (`16480 B` → `16496 B`). The decision cites the delta "+16,480 B" as a measured figure
    at lines 330, 388, 562 and 594.
  - `figures.log`: the header's "a DRIFT line may move upward for a counter" is not true
    of `recent_downloads`, which is a rolling window (`envious` 66319 → 63469).
- **Repair.**
  - Amend the comparison rule to list, as varying by design:
    - tree-census counts;
    - toolchain version lines and toolchain-sensitive absolute sizes;
    - rolling-window counters, which may move either way.
  - Or make the census checks count declarations in a pinned tree, which finding 2's
    repair also achieves.
  - State the size deltas as "measured on rustc 1.98.0" at their first use, or report
    confique as "≈ +16.5 KB". The decision already asserts only thresholds, so no check
    changes.
  - Fix the `## Empirical check` table cell that labels `rest-conformance-r2.sh`
    "exit **0**". It exits 1 at 90/1/0.

### 4. Registry drift: `config` 0.15.26 is now newest, inside the runner-up's range

- **Failed claims.**
  - Lines 380, 445, 455 and 1176 identify the runner-up as `config` 0.15.25.
  - The re-verify clause (line 934) says "neither `config`'s 1.85.0 nor `confique`'s
    1.68.2 is near".
  - The runner-up clause is "**`config >= 0.15.25, < 0.16.0`**".
- **Evidence.** A fresh `GET https://crates.io/api/v1/crates/config/versions` (via
  `fetch-snapshots.sh` into `/tmp`) gives the newest non-yanked release as `0.15.26`,
  `created_at` 2026-09-21, `rust_version` `1.88.0`. The runner-up range admits this
  version, but no decision evidence measured it. My measurement of 0.15.26:
  - 11 packages;
  - +83,184 B;
  - the identical error string for `RSLBP_WEB_PORT=eighty`.

  So the runner-up's measured claims hold. Its recorded MSRV and newest-version figures
  are stale.
- **Repair.** Re-record the `config` rows at 0.15.26:
  - `rust_version` 1.88.0, which still passes gate 2 against the 1.96 floor;
  - re-run P3 and P6 against `=0.15.26`, or pin the runner-up to `=0.15.25` explicitly;
  - update the re-verify clause's "`config`'s 1.85.0" to 1.88.0;
  - add "a new `config` 0.15.x release" as a re-verify trigger.
  - `figures.sh` passed 121/0/0 despite this drift. Its live half asserts fields of the
    *pinned* version only, never the newest non-yanked release. Add a live `DRIFT` line per
    crate for the newest non-yanked `num` and `rust_version`, so the script itself surfaces
    this drift.

### 5. Registry drift: Figment's `pushed_at` is no longer 2024-09-13

- **Failed claim.** Line 411 says: "Maintenance **at-risk**: no release in 2 years 4
  months, `pushed_at` **2024-09-13**". Line 1200 says every `pushed_at` figure was
  "**reproduced exactly**".
- **Evidence.** A fresh `gh api repos/SergioBenitez/Figment` returns `pushed_at`
  `2026-09-27T00:54:08Z`. Also, `serde-env` open issues went from 1 to 0, and its
  `pushed_at` moved to 2026-09-19. The newest figment release is still 0.10.19 with no
  `rust-version`. So the gate-2 exclusion, which is what decides figment, is unaffected.
- **Repair.**
  - Re-record `figment`'s `pushed_at` and the `serde-env` open-issue count.
  - Reassess whether figment's "at-risk" label survives, given renewed repository
    activity without a release.
  - Add "a new `figment` release" to the re-verify triggers. The existing trigger "when
    `envy` or `figment` declares a `rust-version` in a new release" already partly covers
    this.

## What is not in dispute

These points passed in every run:

- the recommendation;
- gate 2's exclusions;
- the axum `FromRef` test (4/0);
- the edition-2024 `set_var` probe and its control;
- the `const fn` prefix probe;
- the `confique` non-literal rejection;
- the five `Display` strings;
- the injection-seam results;
- all nineteen REST-standard rule quotations at their lines;
- the sha256 byte-identity of revision 1 and revision 2 evidence;
- revision 3's reproduction of revision 2's vacuous OV check. Its unresolved-path search
  still discards every match.

Findings 1–3 are evidence-integrity repairs. Findings 4–5 are re-recordings. None of the
five, once repaired, is expected to move the decision.
