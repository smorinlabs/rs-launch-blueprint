actor: audit-claude-s32-r22r5
model: claude-opus-5-5
family: anthropic
decision-sha256: 6094af5a98bd4b18066be9431adfa91295683e0045fe86951f974c4b2c1f65bb
verdict: approve
unresolved-findings: none

# R22 — empirical audit of DECISION.md revision 5

Scope: execution truth and evidence support only. The decision was hashed
before any other action with
`shasum -a 256 research/runs/R22/2026-09-17T020715Z-d93731e7353c/review/DECISION.md`.
The result was `6094af5a98bd4b18066be9431adfa91295683e0045fe86951f974c4b2c1f65bb`,
which matches the expected revision-5 hash. It was re-hashed after all reruns
and was unchanged.

## Environment

- Repository `HEAD` `e0b0d1c1`. Revisions 2–5 of the R22 evidence exist only in
  the working tree, not at `HEAD`. "Committed log" below therefore means the
  paired `.log` that the decision cites in `review/evidence/`, not the `HEAD`
  blob. The `HEAD` blobs are the revision-1 logs.
- `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` and
  `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, both at `/opt/homebrew/bin`.
  macOS on Darwin arm64. These match the decision's toolchain line.
- `CARGO_HOME=/tmp/cargo-s32-r22-emp` is a private, empty Cargo home with no
  `config.toml`. `~/.cargo/config*` does not exist. This satisfies the
  decision's stated precondition that no `build.target-dir` or `build.target`
  config key is set.
- The inherited session environment already had
  `CARGO_TARGET_DIR=/tmp/cargo-s32-r22-emp-target`.
- Working directory for every script run: `review/evidence/`. Output went to
  `/tmp/aud-r22r5/`.
- The sha256 values of the seven `r22-*.log` and `r22-*.sh` files in
  `review/evidence/` were identical before and after all runs. For example,
  `r22-cargo-probe.log` hashed to `21f1ef71…` both times. No `.a3.tmp` or
  `.a9.tmp` file was left behind.

## Reruns

| # | Command (cwd `review/evidence/`) | Exit | Totals | Compared with the paired log |
|---|---|---|---|---|
| R1 | `env -u CARGO_TARGET_DIR -u CARGO_BUILD_TARGET_DIR -u CARGO_BUILD_TARGET bash r22-cargo-probe.sh > /tmp/aud-r22r5/clean-cargo-probe.log` | 0 | `CHECKS RUN: 24  PASS: 24  FAIL: 0  SKIP: 0` | `cmp`: differs at line 2 only. `diff` shows only `run-started-utc: 2026-09-27T06:53:09Z` vs `2026-09-26T19:04:03Z`. stderr was empty. |
| R2 | the same `env -u …` prefix with `bash r22-sources.sh` | 0 | `CHECKS RUN: 75  PASS: 75  FAIL: 0  SKIP: 0` | Differs at line 2 only: `run-started-utc: 2026-09-27T06:53:17Z` vs `2026-09-27T02:29:35Z`. |
| R3 | the same `env -u …` prefix with `bash r22-live-recheck.sh` | 0 | `CHECKS RUN: 10  PASS: 10  FAIL: 0  SKIP: 0` | Differs on line 2 (`run-started-utc`) and on the three `DRIFT` lines 12, 14 and 16 (counters only; for example built `19051118 65403623` vs `19130879 65316258`). The 10 `PASS`/`FAIL` lines are identical, per E3's rule. |
| R4 | `CARGO_TARGET_DIR=/tmp/aud-r22r5/ctd bash r22-cargo-probe.sh` | 0 | 24/24/0/0 | Only line 2 differs from R1 and from the paired log. `/tmp/aud-r22r5/ctd` was still empty afterwards. |
| R5 | `CARGO_TARGET_DIR=/tmp/aud-r22r5/ctd bash r22-sources.sh` | 0 | 75/75/0/0 | Only line 2 differs from R2 and from the paired log. |
| R6 | `CARGO_TARGET_DIR=/tmp/aud-r22r5/ctd bash r22-live-recheck.sh` | 0 | 10/10/0/0 | Only line 2 differs from R3; the `DRIFT` numbers were identical within this session. Against the paired log it shows the same four-line difference as R3. The 10 `PASS`/`FAIL` lines are identical. |
| R7 | `CARGO_TARGET_DIR=/tmp/aud-r22r5/ctd CARGO_BUILD_TARGET_DIR=/tmp/aud-r22r5/cbtd CARGO_BUILD_TARGET=aarch64-apple-darwin bash r22-cargo-probe.sh` | 0 | 24/24/0/0 | Only line 2 differs from the paired log. `/tmp/aud-r22r5/cbtd` was never created, and `ctd` stayed empty. |
| R8 | pre-fix control: the probe script from `HEAD`, extracted with `git show HEAD:<path>/r22-cargo-probe.sh > /tmp/aud-r22r5/prefix-probe.sh` (read-only), then `CARGO_TARGET_DIR=/tmp/aud-r22r5/ctd2 bash prefix-probe.sh` | **127** | no summary line (`CHECKS RUN` count 0) | Printed `prefix-probe.sh: line 95: …/r22-probe.wXtExW/pkga/target/debug/show: No such file or directory` and left `debug/` in `ctd2`. This reproduces EF4-1 exactly as the revision-5 table describes. |

With-versus-without comparison: for every script, the clean-environment output
(R1–R3) and the `CARGO_TARGET_DIR`-set output (R4–R6) differ **only** on the
`run-started-utc:` line. The fix is therefore proven.

- Without the fix, `CARGO_TARGET_DIR` makes the probe fail with exit 127 (R8).
- With the fix, the probe's output is independent of `CARGO_TARGET_DIR`,
  `CARGO_BUILD_TARGET_DIR` and `CARGO_BUILD_TARGET` (R4 and R7), and no build
  output escapes into the relocated directory.

`git diff HEAD -- r22-cargo-probe.sh` shows that the only change is the
7-line comment-plus-`unset` block after `set -euo pipefail`. That block accounts
for the stated line shift from line 95 to line 102. Line 102 of the current
script is `OUT1="$("$SCRATCH/pkga/target/debug/show")"`. The block prints
nothing, which is consistent with the byte-identical probe output.

## Other claims re-derived

- `shellcheck r22-*.sh` is clean.
- `snapshots/SHA256SUMS.txt` has 25 entries. `shasum -a 256 -c` reports 0
  non-`OK` entries.
- A11a/A11b: `raw/codex.md` and `raw/codex-6ebf723a….md` both hash to
  `6ebf723a4e5b801e2c787bc388779e68a2c714c9377c4f9407a7e211bae32915`.
- E4 (archive rerun) holds.
  - With `run-started-utc:` filtered, the archive log's sources section
    (lines 10–106) differs from the current `r22-sources.log` on exactly the
    four claimed lines: `A0b` (line 6), `A6i` and `A6j` (lines 52–53), and
    `A11d` (line 90).
  - The archive log's probe section differs from the current probe log only
    on the `rustc:` and `cargo:` header lines (1.98.0 → 1.98.1).
  - Both archive runs record exit 0 at 75/75 and 24/24.
- Crate-candidate repository figures (JF4-1 repair): `raw/codex.md:52-54`
  carries the stars, `archived`, `pushed_at`, median and unanswered figures.
  `:113` lists the `api.github.com` repository and search endpoints.
  `raw/evidence-terra.md` rows `:126-128` (repository state), `:144-146`
  (medians) and `:70-71` (adopters) say what the decision attributes to them.
- The three medians were recomputed from Terra's per-issue days:
  - `built`: the 8 values sort to a middle pair of 0.120 and 0.183, so the
    median is 0.1515 days.
  - `shadow-rs`: the three answered issues give a median of 3.915 days.
  - `vergen`: (0.054 + 0.399) / 2 = 0.2265 days.
  - The unanswered counts of 0, 5 and 2 match the decision.
- Public read-only queries on 2026-09-27 UTC. All values below are current
  observations; none contradicts the decision:
  - `crates.io/api/v1/crates/built/versions`: the newest non-yanked version is
    `0.8.1` with `rust_version` `1.87` (A2d).
  - `channel-rust-stable.toml`: `[pkg.rust] version = "1.98.1 (48a229cea 2026-09-01)"`
    (A2a–A2c; floor 1.96).
  - GitHub `repos/*`, as stars / `archived` / `pushed_at`:
    - `lukaslueg/built`: 198 / false / `2026-09-24T16:33:51Z`.
    - `baoyachi/shadow-rs`: 703 / false / `2026-05-19T05:48:53Z`.
    - `rustyhorde/vergen`: 475 / false / `2026-09-06T16:53:07Z`.
  - The drift in `built`'s `pushed_at` and the one- and two-star moves are
    expected. The decision dates its table to the report's 2026-09-16
    retrieval and Terra's 2026-09-20 re-query, and states that these figures
    are not load-bearing and are not snapshotted.

## Findings

None. Every rerun command exited 0 at the stated totals (24/24, 75/75,
10/10). Every comparison moved only the lines that the decision's own rules
exempt: `run-started-utc`, plus `DRIFT` counters for the live log under the
`PASS`/`FAIL`-only rule. The EF4-1 repair is demonstrated in both directions:
the old script fails with exit 127, and the fixed script produces
environment-invariant output. The revision-5 claim that no paired log needed
replacing is correct.
