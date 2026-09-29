actor: audit-claude-2026-09-18T215915Z-af997c2abb5a
model: claude-opus-5-5
family: anthropic
decision-sha256: ddc9e134392e7d7ca674cc794ea01bd434bcf7097fca23de3d199674c791e138
verdict: approve
unresolved-findings: none

# R72 — api-pagination — empirical audit of DECISION.md revision 5

## Seat and scope

This audit was filed from the **Claude seat**. The Claude seat is an approved fallback while the
OpenAI provider is quota-paused, under method amendment Q8.B. This is not a Codex audit. The
auditor had a fresh context. It is independent of the synthesizer and of the judgment auditor.

This audit judges **execution truth and evidence support only**:

- Do the commands run?
- Do the logs match the claims?
- Are the figures right?

It does not judge whether the recommendation is wise.

The following material was **not read**:

- `review/audit-fable*.md`
- `review/R72-r*-snapshot.md`
- `review/R72-r1-reconstructed.md`
- `research/topics/72-*/raw/`

The raw files were not opened by the auditor. `r72-inputs.sh`, which the task requires to be
rerun, computes their sha256 hashes for checks `I01`–`I03`; that hashing is the only contact.

One copy caveat applies to the clean extraction in step 3. The extraction copied the whole
untracked run directory into `/tmp`, byte for byte, and those files were among the copied bytes.
None of them was opened.

The auditor ran no git writes, no `scripts/research_runner.py` commands, and no paid or submitting
APIs. All scratch output went under `/tmp/r72audit/`, with one exception. Running `r72-figures.sh`
in place rewrote its own scratch file `review/evidence/snapshots/.deps-list.txt`, which script
line 270 regenerates on every run. The content is a pure function of the unchanged
`deps-paginator-axum.json` and is byte-identical to what the script produces from fresh data (see
observation 4).

## Environment

- **Host:** Darwin 25.4.0, `aarch64-apple-darwin`.
- **Working root:** `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`.
- **HEAD:** `e0b0d1c1762ee8aa4b28c62282a2225103e594eb`, which matches the commit the decision
  names.
- **Rust toolchains:** `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` on the host, and
  `rustc 1.96.0` as the floor. Both come from the probe's own environment block.
- **Retrieval date of this audit's network reruns:** 2026-09-23.

## 1. Hash check (run first)

```
$ shasum -a 256 research/runs/R72/2026-09-18T215915Z-af997c2abb5a/review/DECISION.md
ddc9e134392e7d7ca674cc794ea01bd434bcf7097fca23de3d199674c791e138  .../review/DECISION.md
```

The hash equals the expected value. `DECISION.md` has 1 227 lines and carries the revision-5
header.

## 2. The eleven scripts, rerun

All runs used `bash review/evidence/<script>.sh > /tmp/r72audit/<name>.log 2>&1` from the working
root. The five fetch scripts took a `/tmp` snapshot directory as their first argument, so no
committed snapshot was touched.

### The deterministic scripts: byte comparison against the committed logs

| Script | Exit | Observed totals | Claimed in the decision | `diff` against the committed `.log` |
|---|---|---|---|---|
| `r72-standard.sh` | 0 | PASS 82, FAIL 0, SKIP 0 | 82 / 0 / 0 | identical |
| `r72-inputs.sh` | 0 | PASS 89, FAIL 0, SKIP 0 | 89 / 0 / 0 | identical |
| `r72-figures.sh` | 0 | PASS 167, FAIL 0, SKIP 3 | 167 / 0 / 3 | identical |
| `r72-practice.sh` | 0 | PASS 65, FAIL 0, SKIP 0 | 65 / 0 / 0 | identical |
| `r72-probe.sh` | 0 | PASS 20, FAIL 0, SKIP 0 | 20 / 0 / 0 | identical |
| `r72-archive-rerun.sh` | 0 | PASS 5, FAIL 0 | 5 / 0 | only the tmp-directory names differ (see below) |

#### The probe

The probe's 20 checks break down as follows:

- `E01`–`E04` and `E06` are five environment and build checks.
- The fifteen `E05.p01`–`E05.p15` lines are the contract tests.

The decision's table calls those fifteen tests `P01`–`P15`, and the test names map one to one. The
log shows `test result: ok. 15 passed; 0 failed` on the host (log line 24) and at the floor (log
line 30).

The probe source was spot-checked against the decision's `P`-table:

- **`P02`:** `limit=101` is asserted to return `UNPROCESSABLE_ENTITY`, and `limit=100` to return
  `OK`.
- **`P03`:** `limit=0` is asserted to return `422`.
- **`P04`:** `limit=abc` is asserted to return `400`.
- **`P06`:** the pages are asserted as `prj_0000..0002` and then `prj_0003..0005`, with the cursor
  equal to `encode_cursor("prj_0002")`.
- **`P09`:** there is no `link` header and no `x-total-count` header, and the header set is
  exactly `["content-type", "content-length"]`.
- **`P12`:** the offset window is asserted to repeat `prj_0002` and to never return `prj_0005`.
- **`P15`:** `stream=true`, `stream=false` and `stream=` on `/v1/projects`, and `stream=true` on
  the second route, each return `400`. The same request without `stream` returns `200`.
- **`E06`:** the manifest line is
  `base64 = { version = "0.23.1", default-features = false, features = ["std"] }`.

#### The three figure skips

The three skips are the SPDX licence lines at `F18.c`, `F22.c` and `F24.c`. Each is asserted
literally at `F18.e`, `F22.e` and `F24.e`, and all three read `license = MIT OR Apache-2.0`. This
matches the decision's explanation.

#### The archive rerun

`r72-archive-rerun.sh` printed the following:

```
HEAD: e0b0d1c1762ee8aa4b28c62282a2225103e594eb
files extracted from HEAD: 7365
scripts copied into the extraction: 11
PASS r72-standard.log reproduces byte for byte from a clean git archive extraction
PASS r72-inputs.log reproduces byte for byte from a clean git archive extraction
PASS r72-figures.log reproduces byte for byte from a clean git archive extraction
PASS r72-practice.log reproduces byte for byte from a clean git archive extraction
PASS r72-probe.log reproduces byte for byte from a clean git archive extraction
PASS 5
FAIL 0
```

The rerun log differs from the committed `r72-archive-rerun.log` on two lines only. Both are the
printed `extraction:` paths, which contain the random `mktemp` suffix: `r72archive.oDJ3FT` in the
committed log and `r72archive.HJFke7` in the rerun. The decision's "7 365 files" figure matches the
extraction count.

### The network fetch scripts: endpoint counts

| Script | Exit | Observed totals | Claimed in the decision | Matches? |
|---|---|---|---|---|
| `r72-fetch.sh` | 0 | OK 59, GAP 0 | 59 answered, 0 gaps | yes |
| `r72-fetch-practice.sh` | 0 | OK 4, GAP 0 | 4 answered, 0 gaps | yes |
| `r72-fetch-revision2.sh` | 1 | OK 31, ABSENT 2, GAP 2 | 33 answered, 2 `ABSENT`, 0 gaps | see the note below |
| `r72-fetch-revision3.sh` | 0 | OK 32, GAP 0 | 32 answered, 0 gaps | yes |
| `r72-fetch-revision4.sh` | 0 | OK 5, GAP 0 | 5 answered, 0 gaps | yes |

**The two gaps in `r72-fetch-revision2.sh` come from this auditor's network, not from the
script.** Both gaps are the `archive.org/wayback/available` queries for
`99minutos/template-agents-rust`. On the rerun, both hit `curl: (28) Connection timed out`, after
40011 ms and 40002 ms.

Three later probes also timed out with `curl` exit 28:

- a direct retry of both URLs with a 60-second timeout;
- `https://archive.org/`, with a 30-second timeout;
- `https://web.archive.org/`, with a 30-second timeout.

archive.org was therefore unreachable from this host during the audit. No other endpoint failed.

The two `ABSENT` 404s for the missing template repository reproduced exactly. The committed
`tmpl-99minutos-wayback*.json` snapshots contain `"archived_snapshots": {}`, which `C31` asserts.
The auditor could not independently re-observe that value while archive.org was unreachable. It
is recorded here as re-verified from the committed snapshot only.

**Shell style.** `shellcheck` 0.11.0 was run on all 11 scripts with
`shellcheck review/evidence/*.sh`. It exited 0 with no output. This matches the decision's claim of
no findings.

## 3. Independent clean-extraction reproduction

The auditor built this extraction separately from `r72-archive-rerun.sh`:

1. Ran `git archive HEAD | tar x` into `/tmp/r72audit/extract.5VWE`.
2. Overlaid every untracked or modified file under
   `research/runs/R72/2026-09-18T215915Z-af997c2abb5a/`, using
   `git ls-files --others --modified --exclude-standard`. That listed 353 files.
3. Ran the five deterministic scripts from the extraction's `review/evidence/` directory.
4. Compared the PASS/FAIL/SKIP lines and the full logs against the committed ones.

| Script | Exit | PASS/FAIL/SKIP lines compared | Differences |
|---|---|---|---|
| `r72-standard.sh` | 0 | 85 identical | none; the full log is byte-identical |
| `r72-inputs.sh` | 0 | 92 identical | only log line 2, `root: <tree path>` |
| `r72-figures.sh` | 0 | 173 identical | only log line 3, `snapshots: <tree path>` |
| `r72-practice.sh` | 0 | 68 identical | none; the full log is byte-identical |
| `r72-probe.sh` | 0 | 23 identical | none; the full log is byte-identical |

The line counts include the three `PASS`/`FAIL`/`SKIP` total lines. **No PASS, FAIL or SKIP line
differs.** The only differing lines are the tree-path lines that the decision says legitimately
differ.

## 4. Load-bearing figures re-derived at source

The auditor merged the five fresh `/tmp` snapshot sets from step 2 into `/tmp/r72audit/snap-merged`.
The only committed files copied in were the two archive.org wayback files, because the fresh
fetch timed out. `base64-workflows.*` was absent from the merged directory, because no script
produces it, and both runs below still completed with the results shown.

The auditor then ran `r72-figures.sh` and `r72-practice.sh` against the merged directory, so the
decision's assertions were tested against data retrieved on 2026-09-23.

**`r72-practice.sh` against fresh data: PASS 65, FAIL 0, SKIP 0.** All of the following still hold
at source:

- the crates.io helper;
- dropshot;
- api-bones' envelopes;
- axum's extractor model;
- the `unsafe` census;
- `base64`'s CI list;
- the template facts.

**`r72-figures.sh` against fresh data: PASS 145, FAIL 22, SKIP 3.**

Every one of the 22 failures is a download counter:

- `recent_downloads`, checks `F01`–`F12` excluding `F06`;
- `downloads`, checks `F01.b`–`F12.b` excluding `F06.b`.

These counters move daily, and the fresh values sit within a normal drift of the
`2026-09-21T23:16:25Z` snapshot. For example:

| Crate | Check | Fresh value | Snapshot value |
|---|---|---|---|
| `base64` | `recent_downloads` | 330 736 739 | 329 396 349 |
| `paginator-rs` | `recent_downloads` | 7 550 | 8 119 |

One counter moved further. `api-bones` `recent_downloads` rose from 6 982 to 12 994. That is
consistent with ongoing adoption between retrievals. It cannot bear on the outcome: the
recommendation adopts no pagination crate, and `api-bones` is declined on contract grounds
(Disagreement 2 and alternative D), not on popularity.

**Every non-drifting figure still passes at source:**

- newest non-yanked versions;
- licence strings;
- `rust-version` presence, including `F73`;
- dependency trees;
- the RustSec advisory lookups;
- the revision-2 and revision-3 issue populations behind `F41`, `F42` and `F66`–`F72`;
- the revision-4 repository records, open-issue counts and README behind `F74`–`F79`.

The decision's figures are therefore correct as of their stated retrieval timestamps. The
decision already says which counts are snapshot-dated.

## Observations (non-blocking; no repair required for acceptance)

1. **An unreferenced snapshot file.** `review/evidence/snapshots/base64-workflows.json` and
   `base64-workflows.err` hold a GitHub `404 Not Found` record. No script, no log and no line of
   `DECISION.md` references them, so nothing is asserted from them. The file is consistent with
   the practice log's note that the `.github/workflows` path answers 404. It is a leftover from
   development, not evidence.
   The file's absence did not change any result when `r72-practice.sh` and `r72-figures.sh` ran
   against the fresh merged snapshot directory, which confirms that nothing depends on it.
2. **A stale script comment.** The header comment of `r72-archive-rerun.sh` says "The three fetch
   logs are deliberately not compared". There are five fetch logs. The decision's own text
   correctly says "five", so this is a stale comment inside the script, not a false claim in the
   decision.
3. **Check labels differ between the table and the log.** The decision's probe table labels the
   contract checks `P01`–`P15`. The log labels them `E05.p01_…`–`E05.p15_…`. The mapping is one to
   one by name, and the count of 20 is correct.

4. **The figures script writes into its snapshot directory.** `r72-figures.sh` line 270 writes
   `"$SNAP/.deps-list.txt"`. When the script runs against the committed `snapshots/`, it rewrites
   an evidence-directory file. The file's content after this audit's rerun is
   `['async-trait', 'axum', 'form_urlencoded', 'http', 'paginator-rs', 'paginator-utils', 'serde', 'serde_json', 'tokio']`,
   which is identical to the fresh-data regeneration. Only the file's modification time changed.
   The side effect does not alter any log or result. A `mktemp` scratch path would make the script
   strictly read-only.

## Verdict

**approve.** Every claimed count reproduces exactly, and every deterministic log reproduces. This
holds both in place and from two independent clean extractions:

- the decision's own `r72-archive-rerun.sh`;
- this auditor's `git archive` extraction overlaid with the untracked run files.

`shellcheck` is clean on all eleven scripts. All load-bearing figures except daily download
counters still hold against sources retrieved today.

The one non-reproduction is two archive.org endpoints in `r72-fetch-revision2.sh`. It is explained
by archive.org being unreachable from the auditor's host, not by a defect in the decision or the
script.
