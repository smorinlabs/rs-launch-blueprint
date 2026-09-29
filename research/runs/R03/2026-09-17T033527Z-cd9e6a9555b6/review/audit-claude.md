actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 610e33381016a64c05efd6a1ba1196eb37807abb18d18c68e0d4e7d987586226
verdict: reject
unresolved-findings:
  1. EA-1 — `r03-contract.sh:207` has a quoting bug, and the decision describes its log falsely
  2. EA-2 — the §1.3 "exactly one differing registry row" assertion breaks on unrelated registry publications

# R03 port-absence-vs-failure-contract — empirical audit of DECISION.md revision 1

Audited 2026-09-26 by a fresh Claude Opus context (`claude-opus-5-5`). This
context is independent of the synthesizer and of the judgment auditor. It read
`DECISION.md` (`## Decision`, `## Empirical check`, `## Engines`), `research/RUNBOOK.md`
§5, the three evidence scripts, and the committed logs. It read no
`review/audit-*.md`, no `research/topics/*/raw/` file and no snapshot file. It
made no git writes and no runner calls, and it used no paid or submitting API.

## Verdict summary

**Reject, with two cheap repairs.** Every load-bearing assertion reruns green:
contract 32 PASS, probe 9 PASS, practice 21 PASS, and 0 FAIL in each script.
These counts match the decision's §1, §2 and §3 headings. The rejection has two
causes, and neither says the research conclusion is wrong:

- **EA-1:** one script line is broken, and the decision describes its log
  inaccurately.
- **EA-2:** one assertion is too brittle to survive expected registry drift.

## Identity and currency

- `shasum -a 256 DECISION.md` →
  `610e33381016a64c05efd6a1ba1196eb37807abb18d18c68e0d4e7d987586226`. This
  matches the expected hash, which was checked before any other step.
- Repository `HEAD` is `e0b0d1c1762ee8aa4b28c62282a2225103e594eb`. The evidence
  directory was last changed by `55c1dd13` and `40f611b8`. `evidence/` in the
  working tree is byte-identical to `git archive HEAD` (`diff -r` was empty).
  `DECISION.md` is also identical in both.
- **Currency determination.** `## Empirical check` names three scripts and their
  paired logs as revision 1's evidence: `r03-contract`, `r03-probe` and
  `r03-practice`. All three are current at `HEAD`. The current scripts reproduce
  the committed logs, with one qualification for `r03-contract.log` (EA-1).
- **Uncommitted working-tree edits outside revision 1.** The working tree carries
  in-flight edits:
  - The frozen inputs now read `- engines: muse, opus, doxa`.
  - `operations/muse.json` and `raw/muse.md` are untracked.
  - The `ci-job-structure` row (owned by R11) in `docs/port/PARAMETERS.md` has
    changed.

  These edits are not part of revision 1 and are not judged here. EA-2 records
  how they affect one assertion.

## Method

`r03-probe.sh` writes `toolchain.txt` and `snap/probe-*.txt` into `evidence/`,
and `r03-practice.sh` writes into `snap/`. To avoid overwriting committed
evidence, every rerun ran from a copy:

- `/tmp/r03-emp/head/`: a `git archive HEAD` extraction, the primary run.
- `/tmp/r03-emp/wt/`: the same extraction overlaid with the working tree's
  modified tracked files.
- `/tmp/r03-emp/refetch/`: `evidence/` with `snap/` deleted, which forces a live
  re-fetch.

Every script resolves its own paths from `$0`, so it ran from its copied
`evidence/` directory without any change. Fresh logs went to `/tmp/r03-emp/out-*`
and were compared with `cmp` against the committed logs in the repository.

Toolchain for this audit: `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`,
`cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, `Darwin 25.4.0 arm64`, macOS
26.4, and `shellcheck` 0.11.0. The environment set a private `CARGO_HOME=/tmp/cargo-s15-R03-emp`.

## Reruns

| # | Command (cwd = the copy's `review/evidence`) | Exit | PASS / FAIL / SKIP | `cmp` against the committed log |
|---|---|---|---|---|
| 1 | `bash r03-contract.sh > out-head/r03-contract.log 2> out-head/r03-contract.err` | 0 | 32 / 0 / 0 | **differ: char 5398, line 84.** See EA-1. |
| 1b | `bash r03-contract.sh > out-head/r03-contract.merged.log 2>&1` | 0 | 32 / 0 / 0 | **identical** |
| 2 | `bash r03-practice.sh > out-head/r03-practice.log` (committed `snap/`) | 0 | 21 / 0 / 0 | **identical** |
| 3a | `bash r03-probe.sh > out-head/r03-probe.log` (private `CARGO_HOME`, empty cache) | 0 | 0 / 0 / 2 | differs: the designed skip path ran. See the probe notes below. |
| 3b | the same, after `cargo fetch` of `thiserror = "=2.0.20"` into the private `CARGO_HOME` | 0 | 9 / 0 / 0 | **identical** |
| 4 | `r03-practice.sh` in `refetch/` with `snap/` deleted, so every source is re-fetched live | 0 | 21 / 0 / 0 | differs only in the three `thiserror` figure lines. See D-2. |
| 5 | `bash r03-contract.sh > … 2>&1` in the working-tree overlay | **1** | 31 / **1** / 0 | differs. See EA-2. |
| 6 | `shellcheck r03-contract.sh r03-probe.sh r03-practice.sh` | 0 | no output | The decision's "`shellcheck` … clean" claim holds. |

**Probe notes (rows 3a and 3b).** Row 3a printed:

```
SKIP probe — thiserror =2.0.20 is not in the local cargo registry cache and --offline forbids fetching
SKIPPED (offline dependency unavailable)
```

This is the documented skip behavior, not a failure. After a read-only public
`cargo fetch` in a scratch crate, row 3b reproduced every committed line
byte-for-byte:

- `cargo build --offline` exits `0`, and the lockfile pins `thiserror 2.0.20`.
- `test result: ok. 7 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out`,
  with the seven test names quoted in §2.2.
- `error[E0308]: `?` operator has incompatible types` … `expected `Project`, found `Option<Project>``.
- `error[E0277]: the `?` operator can only be used on `Result`s, not `Option`s, in a function that returns `Result`.`

**Live re-fetch notes (row 4).** Every snapshot fetched at an immutable ref is
byte-identical after the re-fetch: `option.rs`, `io-error.rs` and `path.rs` at
`rust-lang/rust` tag `1.96.0`; `crates_io_github.rs` at `3a31e6c8`;
`sqlx-executor.rs` and `sqlx-error.rs` at `b54008a3`; `objstore-lib.rs` at
`279572ea`; and `jj-backend.rs` at `e6dd2c0d`. Only `thiserror.json` and
`RETRIEVED.txt` differ. Two live checks in §3.6 also re-ran green:

- `gh api repos/smorinlabs/{py,ts,rs}-launch-blueprint` reports `.private = false`.
- The three URLs cited by `raw/doxa-openai` each return HTTP 200 unauthenticated.

## Figures re-derived at source

- **§1.6.** `research/topics/01-*/DECISION.md:117` reads "`src/core/ports.rs`
  (new) — `pub trait ProjectsPort: Send + Sync`, the port error type (vocabulary
  R67's, absence shape R03's) …". `absence shape R03` occurs 2 times in that file,
  as the decision claims. The claim is supported.
- **§1.7.** `docs/port/COMMONALITY.md:18` is
  `| F012 | Port absence-vs-failure contract | workspace-architecture | different | DIVERGENT | R03 | …`.
  The claim is supported.
- **§1.3 at `HEAD`.** `docs/port/PARAMETERS.md` has `ci-job-structure` = `—`.
  The only differing row between the inputs and the registry is
  `web-extra-surface`. The claim is supported as of `HEAD`.
- **§3.5.** The live values are `recent_downloads` 379,666,892, `downloads`
  1,518,978,905 and `max_stable_version` 2.0.21. The decision recorded
  362,994,715, 1,470,911,701 and 2.0.20, dated 2026-09-17. The dated claim
  remains true, and D-2 records the drift.

## Unresolved findings

### EA-1 — `r03-contract.sh:207` has a quoting bug, and the decision describes its log falsely

- **Failed claim** (`## Empirical check`): "Each log in the table is the complete
  stdout of its script: each script was re-run after its log was written and
  `bash <script> | diff - <log>` was empty".
- **Evidence.** A stdout-only rerun of `r03-contract.sh` gives
  `cmp: … differ: char 5398, line 84`. The committed `r03-contract.log` lines
  84–86 are stderr, not stdout:

  ```
  grep: absence: No such file or directory
  grep: shape: No such file or directory
  grep: R03s): No such file or directory
  ```

  Only a `2>&1` rerun is byte-identical. The cause is `r03-contract.sh:207`:

  ```
  $GREP -n -m1 -F 'the port error type (vocabulary R67's, absence shape R03's)' "$R01" | cut -c1-240
  ```

  The apostrophes in `R67's` and `R03's` close the single-quoted string early.
  grep therefore searches for `the port error type (vocabulary R67s,` and treats
  `absence`, `shape` and `R03s)` as file names. As a result, the context line
  that should be quoted from R01 never prints, even though that line exists at
  R01 `DECISION.md:117`. The load-bearing assertion beside it,
  `R01 reserves this items slot … (expected 2, got 2)`, uses a separate
  `count` call and is unaffected. `shellcheck` 0.11.0 does not flag this line.
- **Repair.**
  1. Double-quote the pattern on line 207:
     `"the port error type (vocabulary R67's, absence shape R03's)"`.
  2. Re-record the log with `bash r03-contract.sh > r03-contract.log 2>&1`.
     Confirm the log now contains the `117:` context line and no `grep:` lines.
  3. In `## Empirical check`, state the capture redirect that was actually used,
     for example "stdout and stderr, `2>&1`", or re-record stdout only and keep
     the current wording.

### EA-2 — the §1.3 "exactly one differing registry row" assertion breaks on unrelated registry publications

- **Failed claim** (§1.3): "`inputs/PARAMETERS.md` and `docs/port/PARAMETERS.md`
  differ on exactly one row, `web-extra-surface` …". The script enforces this as
  the assertion
  `differing rows all name web-extra-surface (expected 0 …)`.
- **Evidence.** In the working-tree overlay (row 5), the assertion fails:

  ```
  FAIL differing rows all name web-extra-surface (expected 0, got 2; binary: /usr/bin/grep)
  1 CHECK(S) FAILED
  ```

  The failure comes from an uncommitted, in-flight change to the
  `ci-job-structure` row, which R11 owns. R03 does not consume that row. The
  same run keeps the assertion R03 actually depends on green: all five
  consumed/fixed rows, including R67's `error-taxonomy-exit-codes`, are
  byte-identical between the two files. The assertion passes at `HEAD` today.
  However, the next registry publication by any item makes the script exit `1`
  even though R03's inputs have not moved. Registry drift of this kind is
  expected in this workflow.
- **Repair.** In `r03-contract.sh` §1.3, keep the byte-identity assertion on
  the five consumed/fixed rows, because that is the check that matters. Then
  choose one of these changes:
  - Replace the "all differing rows name `web-extra-surface`" count with an
    assertion that no consumed or fixed row appears in the diff.
  - Print the other differing row names as information only.

  Reword §1.3 to match, for example: "the consumed and fixed rows are
  byte-identical; other rows may differ as later items publish".

## Drift observed, with no failed claim (recorded, not unresolved)

| ID | What drifted | Effect on the evidence | Repair or tolerance already in place |
|---|---|---|---|
| D-1 | rustc/cargo moved from `1.98.0` to `1.98.1` | None: probe output is byte-identical (9 PASS). | `toolchain.txt` keeps toolchain text out of the logs. No repair needed. |
| D-2 | The crates.io `thiserror` figures moved. `max_stable_version` is now `2.0.21`. | The committed log reads the snapshot and stays reproducible. The live re-fetch differs only in the three figure lines, and the practice assertion, which checks the major version only, passes. | §3.5 is dated 2026-09-17 and snapshotted, and the `=2.0.20` pin belongs to R67. No repair is needed for R03. The template's `re-verify` should pick up 2.0.21. |
| D-3 | A fresh offline resolution picks transitive `syn 3.0.6`, `proc-macro2 1.0.107`, `quote 1.0.47` and `unicode-ident 1.0.26`. | None: probe output is byte-identical. | The optional hardening is to record the probe's generated `Cargo.lock` in `toolchain.txt`. |
| D-4 | A private `CARGO_HOME` without `thiserror 2.0.20` makes the probe skip. | The designed `SKIP` path ran, with exit 0 and no false PASS. | The optional hardening is to document the prerequisite (`cargo fetch` of `thiserror = "=2.0.20"`) in the script header. |

## What would flip this to approve

1. Fix `r03-contract.sh:207`, re-record `r03-contract.log`, and correct the
   capture wording (EA-1).
2. Relax the §1.3 count so it tolerates unrelated registry rows (EA-2).
3. Re-issue the decision as a new revision with the updated evidence.

No research conclusion, figure or recommendation in `## Decision` needs to change.
