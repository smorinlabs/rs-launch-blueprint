actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: a6e3bfa5f128857185b930b50f1fc48b3da37a3f1bb3d8cee7725137c0bd3ec6
verdict: approve
unresolved-findings: none

# R83 openapi-contract-fuzzing — empirical audit of revision 2

**Seat.** Empirical auditor. This is a fresh context, independent of the synthesizer and of the
judgment auditor. **Scope.** Execution truth and evidence support only. **Date.** 2026-09-27 (UTC).
**Target.** `review/DECISION.md` revision 2. Before anything else ran, `shasum -a 256` returned
`a6e3bfa5f128857185b930b50f1fc48b3da37a3f1bb3d8cee7725137c0bd3ec6`, which matches the expected
hash. I did not read any `review/audit-*.md`, `review/R83-r1-snapshot.md` or
`research/topics/[NN]-*/raw/` file.

## Environment

- `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` and `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`.
- macOS (Darwin 25.4.0) on `arm64`.
- `CARGO_HOME=/tmp/cargo-s38-R83-emp` is a private cargo home. `TMPDIR` is the per-user
  `/var/folders/…/T/`.
- `gh` is logged in to `github.com` through the keyring.
- Working directory: `research/runs/R83/2026-09-17T034011Z-2af391428997/review/evidence/` in
  `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`, on branch `research/p02-execution`.

Script sha256 values at run time:

| Script | sha256 |
|---|---|
| `contract-fuzz-probe.sh` | `9193e33cebf5ef319618b755fb9931735d329fc9b73b877893d6827ef410e81c` |
| `muse-adjudication.sh` | `d6ff9b1a75051bf7d00435e6c77960b32c69bc8b08a00d914d2ff223eefeeae2` |
| `registry-and-standard.sh` | `2939478f29c0532bdc47512ba978059f4b0a5df6f2a2ea01afb57d7e9bf7f5e7` |
| `registry-skip-paths.sh` | `7cc317046f3b4374cd65a1b40e02b7b1d339d5a14dbd4b2a9a1d7d50658559b5` |

The last three hashes equal the ones printed in `r2-copy-rerun.log`.

## Reruns

Each rerun used this command, with scratch output only:

```
./<script>.sh > /tmp/r83-emp/<script>.log 2> /tmp/r83-emp/<script>.err
```

All four scripts ran concurrently. Every run exited `0`, and every `stderr` file is 0 bytes. The
comparison used `cmp <script>.log /tmp/r83-emp/<script>.log`, with `diff` on a mismatch.

"Committed log" below means the paired working-tree log that the decision cites. Those logs are not
committed yet. `muse-adjudication.log` and `registry-skip-paths.log` are untracked, and
`registry-and-standard.log` is modified relative to the index. All of them are pending the
controller's commit.

| Script | Exit | Fresh totals | Decision claims | `cmp` against cited working-tree log |
|---|---|---|---|---|
| `contract-fuzz-probe.sh` | 0 | `PASS=24 FAIL=0 SKIP=0 TOTAL=24` | 24/24, carried | differs at line 3 (toolchain only, see below) |
| `muse-adjudication.sh` | 0 | `PASS=8 FAIL=0 SKIP=0 TOTAL=8` | 8/8 | **byte-identical** |
| `registry-and-standard.sh` | 0 | `PASS=29 FAIL=0 SKIP=0 TOTAL=29` | 29/29 | differs at line 3 (timestamp only, see below) |
| `registry-skip-paths.sh` | 0 | `PASS=12 FAIL=0 SKIP=0 TOTAL=12` | 12/12 | **byte-identical** |

The fresh total is **73 PASS, 0 FAIL, 0 SKIP**, which matches the decision's sum.

**`contract-fuzz-probe.log` diff.** Only the toolchain lines differ:

```
3,4c3,4
< rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)
< cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)
---
> rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)
> cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)
```

The decision predicts this difference. It says the probe log "was not rerun, so it still records
1.98.0", and that the host has since moved to 1.98.1. Every other byte is identical on a newer
compiler. That includes all 24 PASS lines, the seeded-defect output, the `20/20` versus `2/20` seed
sweep, `validate_version` results, and the `60`/`141` package counts.

**`registry-and-standard.log` diff.** Only the timestamp line differs:

```
3c3
< retrieved: 2026-09-27T07:41:52Z
---
> retrieved: 2026-09-27T08:33:52Z
```

The whole `== stable assertions ==` section is identical, including B27. The
`== volatile figures ==` section also happened to be identical 52 minutes later:

- `openapi-fuzzer` shows 578 stars with `pushed_at=2024-01-29T11:19:08Z`.
- `oas3-rs` shows `pushed_at=2026-09-20T15:41:55Z`.

Guard assertions B23 and B24 pass on the fresh data.

**`muse-adjudication.log`.** The fresh run reproduces M1–M8 byte for byte:

- `openapiv3` 2.2.0 rejects the 3.1 type array (M2) and the numeric `exclusiveMinimum` (M4).
- `oas3` 0.22.0 accepts both (M3, M5).
- M6 shows that an integration test cannot see a `#[cfg(test)]` module in `src/`.
- M7 shows that a `src/` module using a dev-dependency does not build as a library.
- M8 shows that `tests/common/` with `1 passed` / `1 ignored` works.

**`registry-skip-paths.log`.** The fresh run reproduces S0–S6 byte for byte. The inner copy prints
`PASS=0 FAIL=0 SKIP=6 TOTAL=6`, and B10.* are SKIPped by name rather than FAILed. This confirms the
F5 fix (`|| true`) as exercised.

The decision claims byte-identical reproducibility for `muse-adjudication.sh` and
`registry-skip-paths.sh`. An independent run on a different day's scratch paths confirms that claim.

## Figures re-derived at source

Every item below was checked by reading the cited file directly, or by running the command shown.

- **Raw reports.**
  - `raw/opus.md` has sha256 `5c8efd3c…28741`, which matches the decision.
  - `raw/muse.md` has sha256 `dbd36128…c5df` and 138 lines. `git ls-files --error-unmatch` reports
    it as untracked.
  - `manifest.json` and `operations/muse.json` both show `request_id`
    `2c70e838ded84127bef9ddb00c07276e` with `state: submitting`.
  - Manifest `state` is `partial`, and `required_engines` is `['muse', 'opus']`.
  - `scripts/check-answer-shape.sh raw/muse.md crate` prints `OK: validation passed`.
  - These results match `## Engines` exactly.
- **Muse citations.**
  - `:42` carries "no 3.1/JSON-Schema drift handling".
  - `:47` carries "inferred from its stable-only serde-only dependency tree, not declared".
  - `:69` carries `proptest` with "`1` / `>=1.9,<2`".
  - `:93` carries `src/test_support/openapi_strategies.rs`.
  - `:105` carries "Executed results: none in this report".
  - `:109` carries "a 3.1-only output needs a different parser".
  - `:118` carries `openapiv3` with `rust_version null`.
  - The licence ground is AGPL-3.0 (`:59`, `:129`).
  - All of these support rows D1–D9 as quoted.
- **Prompt.**
  - `inputs/prompt.md:25` is `- engines: muse, opus`.
  - `:67` carries the gate-2 wording "declared as rust-version in Cargo.toml and tested in CI".
  - `:74` carries "its mirrored `- engines:` line is authoritative".
- **R11 revision 7** (`research/topics/11-ci-workflow-job-structure/DECISION.md`).
  - The header reads revision 7.
  - `:202` carries "`web` now equals `code`".
  - `:278` holds the partition rule and contains `!cancelled()`.
  - `:282` is the R32 row, which includes "whether a slow tier earns its own job".
  - `:320` is the `owns ci-job-structure` value.
- **Other published and run-tree items.**
  - R33 `:27` carries `proptest` 1.11.0 as `[dev-dependencies] proptest = "1.11.0"`.
  - R72 is at revision 5, and `:154`–`:156` carry `limit` capped at 100 with `limit=0` and
    `limit=101` returning `422`.
  - The R70 run tree is at revision 4, dated 2026-09-27, and `:131`–`:139` carry the problem+json
    invariant.
  - The R02 run tree is at revision 2, and `:128` carries the B3 finding.
  - R69 `:1791` carries `owns web-extra-surface`.
- **Ledger and owner rulings.**
  - `docs/port/COMMONALITY.md:338` is F334, with values `web-service`, `py-only`, `DIVERGENT` and
    `R83`.
  - `owner-decisions.md:157` is the Q7.B licence-gate heading, and `:488` is W1-CODEX3.
  - `execution-ledger.md:1000` is W1-CODEX2/3, and `:1114` is Q5.A.
  - `RUNBOOK.md:70`–`:73` list R83 in the Muse bulk set and state Q9.B.
- **Probe fixture.** `tests/contract_fuzz.rs` is 482 lines, which matches the D9 figure.
- **`oas3` API surface.** I read the `oas3-0.22.0` sources that my rerun unpacked under
  `$CARGO_HOME/registry/src/index.crates.io-1949cf8c6b5b557f/oas3-0.22.0/`.
  - `src/spec/mod.rs:205` is `pub fn operations(&self) -> impl Iterator<Item = (String, Method, &Operation)>`.
  - `src/spec/schema.rs:594` is `pub fn resolve(&self, spec: &Spec) -> Result<Self, RefError>`.
  - `src/spec/mod.rs:75` is `const OPENAPI_SUPPORTED_VERSION_RANGE: &str = "~3.1";`.
  - All three match `## Engines`.
- **Pre-fix log.** `registry-skip-paths.pre-fix.log` shows the following:
  - The outer totals are `PASS=5 FAIL=7 SKIP=0 TOTAL=12` with `exit=1`.
  - The inner copy reports `FAIL  B10.oas3 … (HTTP 000000 …)`, the same for `proptest` and
    `openapi-fuzzer`, and `PASS=0 FAIL=3 SKIP=3 TOTAL=6` with `exit=1`.
  - This matches the decision's `PASS=5 FAIL=7` claim and its quoted FAIL line. It also shows the
    "exits non-zero if any check fails" behaviour in practice.
- **Script hygiene.**
  - All four scripts install `trap cleanup EXIT`.
  - No `$TMPDIR/r83-*` directory from my runs remains. Three older directories are present
    (`r83-arch2-*` from 2026-09-22, and `r83-proto-*` and `r83-proto2-*` from 2026-09-27 00:38
    local time). None of them uses the scripts' `mktemp` prefixes, so they predate this audit and
    were not created by these scripts.
  - `registry-and-standard.sh:204` has `sleep 20` before the second `gh api` call.
  - `:23` sets the `User-Agent` to the repository URL.
  - `muse-adjudication.sh:18` carries the file-level `# shellcheck disable=SC2016`.
- **Lint.** `shellcheck` over all four `*.sh` files exits clean.

## Observations (non-blocking)

1. **Coming re-freeze.** The revision-2 inputs have not changed since 2026-09-21, and a controller
   re-freeze is queued. I judged the current pins as consistent with one another, and they are.
   `## Engines` states that the adjudication covers exactly the on-disk `raw/muse.md` bytes
   (`dbd36128…`), which are uncollected and unpinned. The decision names any change to those bytes
   as a re-verify trigger. When collection happens, the controller should confirm that the pinned
   hash equals `dbd36128…`.
2. **Carried-log commit state.** `clean-extraction.log` in the working tree (29/29, "`git archive
   <tree>`") differs from the `HEAD` blob `601cb4da` (26/26, "`git archive HEAD`"), and it is not
   staged. The staged `registry-and-standard.sh` blob hashes to `69951480…`, which is the
   revision-1 script the decision names. The working-tree log is therefore the one consistent with
   the decision's "24/24 and 29/29" claim. However, the revision-1 log the decision calls "carried"
   was never committed. The controller's commit should include it. As the decision states, the
   `git archive HEAD` clean-extraction rerun for revision 2 is still pending that commit;
   `r2-copy-rerun.log` stands in for it until then.
3. **Not verified here.** The revision-1 snapshot hash (`437ad0c9…`, `review/R83-r1-snapshot.md`)
   was not checked. That file is outside this seat's permitted reads.
4. **Toolchain drift.** The probe now passes identically on 1.98.1. This is extra evidence for the
   carried 24/24 claim, not a discrepancy.

## Verdict

**approve.** All four scripts execute with exit 0 at the claimed totals (24, 8, 29 and 12; 73 in
all). Two logs are byte-identical. The other two differ only in a toolchain version line and a
`retrieved:` timestamp, and the decision anticipates both. Every load-bearing figure and line
citation I re-derived at source matches.
