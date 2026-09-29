actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: c607a34e01f36673d0be729a826ee10fdd5ed77c94a31dcde3726ab2cd7e8519
verdict: approve
unresolved-findings: none

# R28 linter-and-editor-tooling — empirical audit of revision 3

Seat: empirical auditor, fresh context, independent of the synthesizer and the
judgment auditor. Audited on 2026-09-27. Scope: execution truth and evidence
support only, per `research/RUNBOOK.md` section 5 ("The empirical auditor
reruns the check").

## Target identity

`shasum -a 256 research/runs/R28/2026-09-26T190151Z-059af1e15f51/review/DECISION.md`
→ `c607a34e01f36673d0be729a826ee10fdd5ed77c94a31dcde3726ab2cd7e8519`, which
equals the expected hash. The file's title line reads "(revision 3)".

## Rerun

Host: macOS arm64 (`Darwin 25.4.0`), the same host as the decision records.
`CARGO_HOME=/tmp/cargo-s38-R28-emp` (a private cargo home; the committed logs
show `/tmp/cargo-s9-R28`). Working directory:
`research/runs/R28/2026-09-26T190151Z-059af1e15f51/review/evidence/`.
Command per script, output to scratch only:

```
bash r28-<name>.sh > /tmp/r28-emp-r3/r28-<name>.log 2>&1
```

Nothing under `evidence/` was written. Each fresh log was compared with
`cmp` against the committed paired log. When the bytes differed, the full
`diff` was read, and the `PASS`/`FAIL`/`SKIP` lines were compared separately.

| Script | Exit | Fresh PASS / FAIL / SKIP | Committed PASS / FAIL / SKIP | `cmp` | Verdict lines |
|---|---|---|---|---|---|
| `r28-autofix.sh` | 0 | 5 / 0 / 0 | 5 / 0 / 0 | differ | identical |
| `r28-editor-config.sh` | 0 | 6 / 0 / 0 | 6 / 0 / 0 | differ | identical |
| `r28-floor.sh` | 0 | 5 / 0 / 0 | 5 / 0 / 0 | differ | identical |
| `r28-inputs.sh` | 0 | 157 / 0 / 0 | 157 / 0 / 0 | **byte-identical** | identical |
| `r28-lint-table.sh` | 0 | 13 / 0 / 0 | 13 / 0 / 0 | differ | identical |
| `r28-live-figures.sh` | 0 | 7 / 0 / 0 | 7 / 0 / 0 | differ | identical |
| `r28-ruff-fix-default.sh` | 0 | 2 / 0 / 0 | 2 / 0 / 0 | differ | identical |
| `r28-sources.sh` | 0 | 10 / 0 / 0 | 10 / 0 / 0 | differ | identical |
| `r28-test-relaxation.sh` | 0 | 11 / 0 / 0 | 11 / 0 / 0 | differ | identical |
| **Total** | all 0 | **216 / 0 / 0** | **216 / 0 / 0** | | |

The fresh total, 216 PASS, equals the committed total the decision claims.
The claim "59 PASS, 0 FAIL" for the eight scripts other than `r28-inputs.sh`
also holds (216 − 157 = 59).

### Every byte difference is run-local

The first differing lines, quoted from `diff <committed> <fresh>`:

- All five cargo scripts: line 2, `< CARGO_HOME=/tmp/cargo-s9-R28` versus
  `> CARGO_HOME=/tmp/cargo-s38-R28-emp`. This is the private cargo home.
- The `mktemp` scratch names, for example `r28-autofix.Du0fSj` versus
  `r28-autofix.fylQPC`, and the paths cargo prints from them.
- Cargo timings, for example `Finished … in 0.17s` versus `in 0.13s`.
- `r28-autofix.log` line 27: the scratch commit hash, `cb98542` versus
  `6b8c32b`. A new `git commit` in a new directory at a new time gets a new hash.
- `r28-test-relaxation.log` line 28: the committed log has
  `warning: build failed, waiting for other jobs to finish...` and the fresh
  log does not. That line is cargo's parallel-job scheduling message. It
  appears inside a case that expects a failing build, and the case's verdict
  line is identical.
- `r28-sources.log` line 1 and `r28-live-figures.log` line 1: the retrieval
  timestamps, `2026-09-27T01:11:15Z` and `2026-09-27T01:11:29Z` committed
  versus `08:13:53Z` and `08:13:49Z` fresh.
- `r28-live-figures.log`: `rust-lang/rust-clippy` `pushed_at` moved from
  `2026-09-24T14:26:18Z` to `2026-09-27T07:45:16Z`. Its open-issue count moved
  from 2,506 to 2,507. The crates.io `clippy` shim's downloads moved from
  95,559 recent and 2,067,318 all-time to 95,952 and 2,067,711. These are the
  same two download figures the decision's "Revision-3 rerun" paragraph
  reports. Stars (13,536), `archived: false`, the rust-analyzer and codelldb
  figures, both rustsec HTTP 404 results, and the shim's `0.0.302` (created
  2018-10-05) with the crate created 2015-05-09 are unchanged.

None of these differences changes a case outcome or a figure the decision
quotes as the committed value. The decision states that its figures are the
committed log's and names these drifts.

## Load-bearing cases, re-observed in the fresh logs

- L9: "pedantic warning passes without -D warnings (exit 0) and fails with it (exit 101)".
- L10: "Muse table local exit 101 (error); recommended local exit 0 (warning); recommended gate exit 101".
- L12: "root-only run exit 0 misses crates/core/tests; --workspace run exit 101 catches the deny-by-default lint".
- L13: "missing_safety_doc warns with no group enabled (exit 0)".
- T9 and T10: `approx_constant` is an error inside the test module (exit 101).
  With the blanket allow, the gate passes with the `3.14` literal present (exit 0).
- F4 in `r28-autofix.log`: "needless_return rewritten (exit 0)".
- F0 in `r28-floor.log`: "cargo, clippy and rustc are all the 1.96 floor".
  This check guards against the `PATH` trap the decision describes.
- V2 in `r28-editor-config.log`: recorded as an observation.

## Figures re-derived at source

- `raw/muse.md`: 946 lines, sha256 `729bc9fc…4c3c8`. `raw/opus.md`: 943
  lines, sha256 `7e7c8f1d…d314`. Both match `## Engines`. They were checked
  with `wc -l` and `shasum`; the run's `raw/` directory is not the forbidden
  `research/topics/[NN]-*/raw/` directory.
- `manifest.json` `.operations` is `{}`. This matches "no operation receipt".
- In `inputs/EXECUTION.json`, R28 is `{"tier":"focused","engines":["codex","opus"],…}`.
  This matches "lists R28 engines `codex, opus`". The provenance block
  (Muse not authorized, Codex absent) is therefore stated accurately. Deciding
  that provenance belongs to the controller, not to this audit.
- `research/topics/11-ci-workflow-job-structure/DECISION.md:268` contains
  "`-D warnings` is on both clippy steps".
- `research/topics/11-ci-workflow-job-structure/DECISION.md:320` contains
  "the web member depends on the core member and the root package that hosts
  the serve binary depends on every member". This supports the decision's
  workspace-shape reading. The `I7` fragment for this line checks only the
  line's opening, so this reading was confirmed directly.
- `research/topics/42-dev-toolchain-provisioning/DECISION.md:26` contains
  `components = ["rustfmt", "clippy"]`, as Disagreement 6 cites.
- The decision's table sums to 13 + 11 + 5 + 5 + 6 + 10 + 7 + 2 + 157 = 216.

## Not rerun, and why

The decision's own "Not executed" list was not rerun: no VS Code session is
available (A7, A8), there was no ubuntu-latest run, and no marketplace
counts were collected. The decision labels these gaps accurately and assigns
them to P03. They do not contradict any claim.

## Verdict

approve — all nine scripts exit 0 on rerun with 216 PASS, 0 FAIL and 0 SKIP.
`r28-inputs.sh` reproduces its revision-3 log byte for byte. The other eight
differ only in run-local bytes. Every figure and case checked above is
supported by the evidence.
