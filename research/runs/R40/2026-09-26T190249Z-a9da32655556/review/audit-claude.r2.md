actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: d7db6f1d42936f72787084913a3f19c4d285ef6313fff82ed9238abed107a9f4
verdict: reject
unresolved-findings:
1. EF-1 — assertion helpers race under `set -o pipefail`; the claimed 192/192 green does not reproduce.
2. EF-2 — `r40-citations.sh` fails its policy-snapshot `cmp` against the current `research/EXECUTION.json`.

# R40 empirical audit — revision 2

Scope: execution truth and evidence support for
`research/runs/R40/2026-09-26T190249Z-a9da32655556/review/DECISION.md`,
revision 2. This audit reran all 10 evidence scripts and byte-compared every
fresh log against its committed pair. It does not judge the recommendation's
merit.

## Identity and method

- **Decision hash.** `shasum -a 256 review/DECISION.md` printed
  `d7db6f1d42936f72787084913a3f19c4d285ef6313fff82ed9238abed107a9f4`. That equals
  the expected hash, so the audit proceeded.
- **Read.** The decision's header, `## Parameters` tail, `## Empirical check`,
  `## Engines`, and `research/RUNBOOK.md` §5 "Raw answers and acceptance". I read
  no `review/audit-*.md` file, no `review/R40-r1-snapshot.md`, and nothing under
  `research/topics/[NN]-*/raw/`.
- **Host.** macOS, `Darwin 25.4.0 arm64`, the same host class as the decision.
  Private `CARGO_HOME=/tmp/cargo-s29-R40-emp` and
  `CARGO_TARGET_DIR=/tmp/cargo-s29-R40-emp-target`.
- **Individual reruns.** From the repository root, run as
  `bash <evidence>/r40-<name>.sh > /tmp/r40-audit/r40-<name>.log 2>&1`, one
  script at a time in the decision's order. `install` ran first because the
  other scripts depend on its tools.
- **`r40-rerun-all.sh`.** That script writes its logs into `evidence/` by design.
  To leave `evidence/` untouched, I ran it inside a `/tmp/r40-audit/mirror/`
  copy of `docs/`, `research/` (without `runs/`) and this run directory.
  Every copied file was `cmp`-verified against the live tree. The one exception
  was `research/topics/13-…/prompts/…prompt.md`, which changed during the copy
  and which R40 does not read. The command was
  `cd /tmp/r40-audit/mirror && bash research/runs/R40/…/review/evidence/r40-rerun-all.sh > /tmp/r40-audit/r40-rerun-all.log 2>&1`.
- **Nothing written to `evidence/`.** The only file this audit wrote in the
  repository is this one.

## Rerun record

### First individual pass, 2026-09-27T06:53:41Z–07:00Z UTC

| Script | Exit | Fresh totals | Committed totals | `cmp` against the committed log |
|---|---|---|---|---|
| `r40-install.sh` | 0 | records (last line `DONE`) | records | differs: line 6, benign (see table below) |
| `r40-ec.sh` | 0 | PASS=14 FAIL=0 | 14/0 | **identical** |
| `r40-yaml.sh` | 0 | PASS=19 FAIL=0 | 19/0 | **identical** |
| `r40-typos.sh` | 0 | PASS=11 FAIL=0 | 11/0 | **identical** |
| `r40-actionlint.sh` | **1** | PASS=16 **FAIL=1** | 17/0 | differs: line 61; one assertion flip (EF-1) |
| `r40-insta.sh` | 0 | PASS=8 FAIL=0 | 8/0 | differs: line 8, benign |
| `r40-compose.sh` | **1** | PASS=18 **FAIL=1** | 19/0 | differs: line 3; one assertion flip (EF-1) |
| `r40-figures.sh` | 0 | records (last line `DONE`) | records | differs: line 1, benign |
| `r40-citations.sh` | **1** | PASS=103 **FAIL=1** | 104/0 | differs: line 9 (EF-2) |

First-pass totals: 192 assertions ran, which matches the committed count.
189 passed (14 + 19 + 11 + 16 + 8 + 18 + 103), 3 failed, and 0 were skipped.
The 3 failures are `A7-synth-shape-ran`, `C3-ryl-key-duplicates` and the
`EXECUTION.json` `cmp` check.

The first differing lines of the three failures:

```text
r40-actionlint.log  < PASS A7-synth-shape-ran (output contains: synth-shape ❯)
                    > FAIL A7-synth-shape-ran (output lacks: synth-shape ❯)
r40-compose.log     < PASS C3-ryl-key-duplicates (output contains: key-duplicates)
                    > FAIL C3-ryl-key-duplicates (output lacks: key-duplicates)
r40-citations.log   < PASS run policy snapshot is byte-identical to research/EXECUTION.json
                    > FAIL run policy snapshot differs from research/EXECUTION.json
```

### `r40-rerun-all.sh` in the mirror, 2026-09-27T07:02:55Z–07:05:35Z UTC

Exit 1. The full log follows:

```text
started_at=2026-09-27T07:02:55Z
== reset scratch tools
== shellcheck
shellcheck: clean over 10 scripts
r40-install.sh exit=0 TOTAL n/a (no assertions; last line: DONE)
r40-ec.sh exit=0 TOTAL PASS=14 FAIL=0
r40-yaml.sh exit=0 TOTAL PASS=19 FAIL=0
r40-typos.sh exit=0 TOTAL PASS=11 FAIL=0
r40-actionlint.sh exit=0 TOTAL PASS=17 FAIL=0
r40-insta.sh exit=0 TOTAL PASS=8 FAIL=0
r40-compose.sh exit=0 TOTAL PASS=19 FAIL=0
r40-figures.sh exit=0 TOTAL n/a (no assertions; last line: DONE)
r40-citations.sh exit=1 TOTAL PASS=103 FAIL=1
finished_at=2026-09-27T07:05:35Z
```

That is 191 PASS, 1 FAIL and 0 skipped. The mirror's `r40-citations.log` names
the same failure: `FAIL run policy snapshot differs from research/EXECUTION.json`.
Against the committed `r40-rerun-all.log`, `cmp` reports
`differ: char 24, line 1`. The differing lines are the two timestamps; a
missing `(CARGO_HOME/bin empty)` line, which is benign because `ls` on an
existing empty directory prints nothing and the `echo` fallback does not fire;
and `r40-citations.sh exit=1 TOTAL PASS=103 FAIL=1` in place of
`exit=0 TOTAL PASS=104 FAIL=0`.

### Repeat runs of the two racing scripts

I ran each script 4 more times, with logs at `/tmp/r40-audit/rep{1..4}-r40-*.log`.
That makes 6 runs of each script in total: the first pass, 4 repeats and the
mirror pass.

| Script | Runs | Runs with a spurious FAIL | Which assertion |
|---|---|---|---|
| `r40-actionlint.sh` | 6 | 2 | `A7-synth-shape-ran` (first pass), `A6-opus-shape-skipped` (rep2) |
| `r40-compose.sh` | 6 | 1 | `C3-ryl-key-duplicates` (first pass) |

In every one of these runs, the searched text is present in the same fresh
log. The run prints each command's output before it checks for the text.

### Byte-compare drift, classified

The controller asked that every drift be treated as a finding. I report the
logs that differ below. Only the substantive rows are findings.

| Drift | Logs | Class |
|---|---|---|
| timestamps (`retrieved_at`, `started_at`, `finished_at`) | figures, rerun-all | benign |
| private `CARGO_HOME` path (`/tmp/cargo-r40r2` → `/tmp/cargo-s29-R40-emp`) | install, compose, insta | benign |
| `mktemp` directory names, thread ids, test and hook durations | insta, actionlint, compose | benign |
| crates.io download counts and GitHub star counts | figures | benign: the volatile counts are not load-bearing (for example, `typos-cli` went from 1002583 to 1003022) |
| build wall times: `typos-cli` 84 s → 113 s, `ryl` 68 s → 129 s | install | benign: they depend on host load, and the decision reports them as a record, not as a threshold |
| lefthook's parallel job output order | compose, actionlint | benign in itself, but it is the trigger for EF-1 |
| missing `(CARGO_HOME/bin empty)` line | rerun-all | benign |
| three assertion flips from PASS to FAIL | actionlint, compose | **substantive: EF-1** |
| policy snapshot `cmp` from PASS to FAIL | citations, rerun-all | **substantive: EF-2** |

`r40-ec.log`, `r40-yaml.log` and `r40-typos.log` are byte-identical to their
committed pairs.

## Figures re-derived

- **Quoted output lines.** Each of the 13 lines quoted under
  `**Observed output**` is present in the fresh logs. `r40-citations.sh`'s
  `log_has` block also passes against the mirror's fresh logs.
- **`actionlint` activity, re-derived at source.** Two REST calls:
  - `gh api "repos/rhysd/actionlint/commits?sha=main&since=2026-04-20T00:00:00Z&per_page=5" --jq length`
    printed `0`.
  - The newest commit on `main` is dated `2026-04-19T14:46:58Z`.

  Both agree with the decision's "0 commits on `main` since 2026-04-20
  (newest 2026-04-19)".
- **Issue figures.** The fresh `r40-figures.log` repeats the decision's issue
  figures unchanged:
  - `actionlint` issues: `non-maintainer issues=10 responded=0 unanswered=10`.
  - `ryl` issues: `non-maintainer issues=7 responded=1 unanswered=6`, which is
    the decision's "6 of 7 recent non-owner issues unanswered".
- **Versions.** `max_stable_version` is unchanged: `typos-cli` 1.50.3 and
  `ryl` 0.22.0.
- **Missing `ec` executable.** `r40-install.sh` again reports that the 4.0.2
  `darwin-all` tarball holds no executable named `ec`. This is the fact behind
  Disagreement 2.
- **Behavioural claims.** The fresh logs reproduce every behavioural claim that
  settles a disagreement:
  - the `"4.0.2"` pin refused and the `"v4.0.2"` pin accepted (`E0`, `E1`, `E6`);
  - `truthy` reported as a warning with exit 0, then as an error with exit 1
    (`Y4`, `Y4e`);
  - `files walked containing .github: 0` (`T2a`);
  - the three hook shapes (`A5`–`A7`), whenever the helper did not race;
  - the insta snapshot failing after an editor trim (`I3`), and `.snap` as a
    default exclude (`I5n`).

The findings below concern whether the evidence reproduces reliably and
whether the inputs are current. No finding contradicts a figure or a behaviour
that the decision relies on.

## Findings

### EF-1: the assertion helpers race under `set -o pipefail`

**Failed claim.** `## Empirical check`, "Totals of the fresh pass": "All 9
evidence scripts exited 0, and the 7 asserting scripts passed 192 of 192
assertions … No assertion failed." The claim also covers the table rows
`r40-actionlint.sh | 17/17` and `r40-compose.sh | 19/19`. The claim was true
for one pass. It does not reproduce reliably.

**Mechanism.** Both scripts run under `set -euo pipefail`. Their `expect_in`
helpers test for the text with a pipe:

```bash
# r40-actionlint.sh:33 and r40-compose.sh:33
if printf '%s\n' "$3" | grep -qF -- "$2"; then …PASS… else …FAIL…
```

1. `grep -q` exits as soon as it finds a match.
2. If `printf` has not finished writing, `printf` then receives SIGPIPE.
3. Under `pipefail`, SIGPIPE makes the pipeline's status 141.
4. The `if` treats status 141 as "not found", so the helper reports FAIL even
   though the text is present.

Whether step 2 happens depends on how lefthook's parallel job output is ordered
and on scheduler timing.

**Evidence.**

- **The text is present in the same log that reports its absence.**
  - Fresh `r40-actionlint.log`: line 101 is `┃  synth-shape ❯`, yet line 107 is
    `FAIL A7-synth-shape-ran (output lacks: synth-shape ❯)`.
  - Fresh `r40-compose.log`: line 29 contains
    `duplication of key "schedule" in mapping  (key-duplicates)`, yet line 57 is
    `FAIL C3-ryl-key-duplicates (output lacks: key-duplicates)`.
  - `rep2-r40-actionlint.log`: line 79 is `│  opus-shape (skip) no matching staged files`,
    yet line 92 is `FAIL A6-opus-shape-skipped (output lacks: opus-shape (skip))`.
- **The failures are intermittent.** Of 12 runs, 3 produced a spurious FAIL
  (see the repeat table above).
- **The mechanism is demonstrated.** `/tmp/r40-audit/sigpipe-demo.sh` puts the
  needle on the first line of a 20,000-line string and runs the same pipe under
  `pipefail`. It printed
  `text present in all 50; grep -q under pipefail reported found=0 not-found=50`.
- **Exposure.** The `ran` and `skipped` helpers (`r40-actionlint.sh:41-42`)
  delegate to `expect_in`, so every `A5`–`A7` shape check is exposed. So is
  every `C3` and `C6` `expect_in` check in `r40-compose.sh`.
- **No false pass today.** `expect_not_in` (`r40-actionlint.sh:37`) uses the
  same pipe. For a negative assertion, the race would turn a real "contains"
  into a spurious PASS. It has **no call sites**, so no assertion in the
  committed 192 could have passed falsely; the hazard is latent. The race can
  only produce false FAILs, so the committed green is not falsified. It is
  not reproducible.
- **Same pattern, low exposure.** `r40-citations.sh:24`, `:29` and `:154` use
  the same pattern on single short lines, so their exposure is negligible.
  `r40-typos.sh:42` and `:44` pipe tool output into `grep -q` for recorded
  (non-asserting) lines.

**Repair.**

1. Test without a pipe:
   - in `expect_in` and `expect_not_in` (`r40-actionlint.sh:33`, `:37`), and
     in `expect_in` (`r40-compose.sh:33`), replace
     `printf '%s\n' "$3" | grep -qF -- "$2"` with
     `grep -qF -- "$2" <<< "$3"`, or with `[[ "$3" == *"$2"* ]]`;
   - apply the same change at `r40-citations.sh:24`, `:29`, `:154` and
     `r40-typos.sh:42`, `:44` for consistency.

   The fix is also what makes `expect_not_in` sound, if it is ever called.
2. Rerun `r40-rerun-all.sh`.
3. Re-commit the logs.
4. Update the `## Empirical check` totals only if they change.

### EF-2: the policy snapshot is no longer byte-identical to `research/EXECUTION.json`

**Failed claim.** `r40-citations.log` line 9 says
`PASS run policy snapshot is byte-identical to research/EXECUTION.json`. The
decision's revision note also says that the controller "re-froze …
`inputs/EXECUTION.json` against the live tree". That check now fails in both
the individual run and the mirror run:
`FAIL run policy snapshot differs from research/EXECUTION.json`.

**Evidence.**

- `diff inputs/EXECUTION.json research/EXECUTION.json` adds entries to
  `empirical_auditor_overrides` only. The additions include `"R40": "claude"`
  and entries for about 50 other items. The additions are the whole diff.
- Hashes and state:

  | File | sha256 | State |
  |---|---|---|
  | `inputs/EXECUTION.json` (frozen snapshot) | `c670184d…` | modified `Sep 26 21:23:55 2026` |
  | `research/EXECUTION.json` (live) | `acdcbfff…` | modified `Sep 26 23:30:19 2026` local; uncommitted (`M` in `git status`) |

  The live file changed after the decision was written (its `DECISION.md`
  mtime is 21:32).
- `engine_overrides.R40` is `["muse","opus"]` in both files, and `items.R40` is
  identical in both. The engine-provenance assertion still passes.

This finding is a controller edit made after the freeze, not a synthesis
defect. It changes nothing that the decision relies on. It still blocks
acceptance, for two reasons. RUNBOOK §5 requires "current consumed values and
prerequisite decisions" and "current inputs". And the rerun of the committed
script fails.

**Repair.**

1. The controller re-freezes `inputs/EXECUTION.json` from the current
   `research/EXECUTION.json`.
2. The controller reruns `r40-citations.sh` and `r40-rerun-all.sh` to green.

A durable fix needs one more change, because seating an auditor edits this
same file. Without the change, every future seating breaks whole-file byte
identity again, and revision 3 would repeat this failure. Choose one:

- change `r40-citations.sh:38` to compare only the R40-relevant subset
  (`.engine_overrides.R40`, `.items.R40`, `.pilot`) with `jq`; or
- freeze the snapshot after auditors are seated.

## What was not established

- No run on `ubuntu-latest`, and no build at the 1.96 MSRV floor. The decision
  itself lists both as items for P03.
- I did not rerun `raw/opus.md`'s 16-repository survey. The decision labels it
  as carried from the raws without re-execution.
