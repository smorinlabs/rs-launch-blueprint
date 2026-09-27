actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 1551c96d483f7be26ca0d50d1df2caa32d4542ccf66e0423ad40e5827ae2e215
verdict: reject
unresolved-findings:
1. EA-1 — `cargo-probes.sh` aborts under a set `CARGO_TARGET_DIR`, with no FAIL line and no summary.
2. EA-2 — E4's "12 packages declare no rust-version" does not reproduce (11 now). The E4 join silently drops crates whose versions drifted.
3. EA-3 — The stripped-binary byte figures are not toolchain-stable. The claim that they are "exact because the Cargo.lock is snapshotted" is false.
4. EA-4 — `rest-conformance-r2.sh` does not re-execute "the whole" revision-1 check set, and it does not assert the digests it calls "pinned".
5. EA-5 — `cargo-probes.log` is not "byte-reproducible except for two header lines".
6. EA-6 — The script rerun does not reproduce E8 (`promtool` is not installed, so E8 is a named SKIP). E8 does hold when executed by hand.

# R79 prometheus-metrics — empirical audit of DECISION.md revision 2

## Summary

**Verdict: reject.** The rejection rests on execution truth and on evidence-support claims. It does
not rest on the recommendation itself. Every load-bearing figure I re-derived at source matched the
decision, or drifted within a bound this audit names:

- Tarball sha256 values; the `unsafe` counts of 27, 5 and 3.
- `rust-version = { workspace = true }`; RustSec HTTP 404 pages.
- The `promtool` acceptance; the crate counts 37→81, 51→79 and 82.
- The 118-package lock; the highest declared rust-version, `hashbrown 0.17.1` at `1.85.0`.
- `cargo audit` reporting no vulnerabilities.

The rejection stands because two conditions fail:

- The designated probe script does not run to completion in the supplied environment.
- In a corrected environment, the probe script does not reproduce its committed 34/0/0.

Three of the decision's reproducibility claims are also false as written. The crate pair, versions,
feature graph, metric names and labels are not in question.

**Decision hash.** Recomputed with `shasum -a 256` before any other step:
`1551c96d483f7be26ca0d50d1df2caa32d4542ccf66e0423ad40e5827ae2e215`. This equals the expected value.

## Currency determination

`## Empirical check` states: "The script an auditor reruns for revision 2 is
`rest-conformance-r2.sh`; `decision-self-check.log` stands as the record of the revision-1 run". It
also calls `decision-self-check.sh` "superseded". I accept that determination. The four other
revision-1 scripts (`cargo-probes.sh`, `crate-sources.sh`, `github-api.sh`,
`decision-self-check.sh`) are declared byte-identical to revision 1. I verified that independently:
`git diff --stat fca40a5 HEAD -- …/review/evidence/` lists exactly three new files and no modified
file. The three new files are `rest-conformance-r2.sh`, `rest-conformance-r2.log` and
`snapshots/rest-standard-rules.txt`. I still reran every script, as the task requires. For the
superseded `decision-self-check.sh`, the failure on the revision-1 H1 is by design and is not a
finding; its other failure is not by design (see EA-4).

## Execution record

**Environment.**

| Item | Value |
|---|---|
| Date | 2026-09-27 UTC |
| Host | macOS on Darwin arm64 |
| Toolchain | `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05)`; the decision recorded 1.98.0 |
| Other tools | `cargo-audit-audit 0.22.1`, `gh version 2.101.0 (2026-09-15)`; the decision recorded 2.98.0 |
| grep | `/usr/bin/grep` BSD 2.6.0-FreeBSD |
| Cargo | private `CARGO_HOME=/tmp/cargo-s15-R79-emp`, with `CARGO_TARGET_DIR=/tmp/cargo-s15-R79-emp-target` set by the environment |
| `promtool` | not on PATH |

**Execution setup.** The scripts write beside themselves: `cargo-probes.sh` rewrites
`scrape-sample.txt`, and every script resolves the repository root by walking up from its own path.
To keep `evidence/` untouched, every script ran from a mirror at `/tmp/r79-emp-claude/mirror`. The
mirror is a copy of the **working tree**, not of `git archive HEAD`. It contains:

- `docs/`, `scripts/`, the top-level files, and every `research/**/*.md`;
- the full `research/runs/R79/` directory, verified byte-identical with `diff -r`.

Because the mirror copies the working tree, it includes other agents' uncommitted edits to files
such as `docs/port/PARAMETERS.md` and the execution ledger. It has no `.git`, so the header lines
of both self-check logs read "no .git present". Every log went to `/tmp/r79-emp-claude/out/`.
After the runs, `git status --short …/review` in the real worktree was empty apart from this file.

**Timing note.** `rest-conformance-r2.sh` and `decision-self-check.sh` ran while the first
`cargo-probes.sh` run (run 1) was in flight. Run 1 aborted before E6, so it never rewrote the
mirror's `scrape-sample.txt` during those two runs. The digest the r2 script printed for that file
equals the committed one.

| # | Command (cwd = mirror `…/review/evidence/`) | PASS | FAIL | SKIP | Exit | `cmp` against the committed log |
|---|---|---|---|---|---|---|
| 1 | `./cargo-probes.sh > out/cargo-probes.log 2>&1` | 15 printed before the abort | 0 | 0 | **1** | differs at line 2 (`rustc 1.98.1`); the log is truncated at 212 lines, with no `== summary ==` |
| 2 | `env -u CARGO_TARGET_DIR ./cargo-probes.sh > out/cargo-probes.run2.log 2>&1` | **32** | 0 | **1** | 0 | differs; see EA-2, EA-3, EA-5 and EA-6 (committed: 34/0/0) |
| 3 | `./crate-sources.sh > out/crate-sources.log 2>&1` | 66 | 0 | 0 | 0 | differs only in declared-volatile fields: header, `recent`/`all` downloads, reverse-dependency totals |
| 4 | `./github-api.sh > out/github-api.log 2>&1` | 5 | 0 | 0 | 0 | differs only in declared-volatile fields: header, `gh` version, `pushed_at`, stars, issue counts |
| 5 | `./decision-self-check.sh > out/decision-self-check.log 2>&1` (superseded) | 69 | **2** | 0 | 1 | differs (committed: 70/0/0); see below |
| 6 | `./rest-conformance-r2.sh > out/rest-conformance-r2.log 2>&1` | **122** | 0 | 0 | 0 | differs **only** in header lines 2–4: date, resolved root, `.git` context |
| 7 | a copy of `cargo-probes.sh` with only `trap cleanup EXIT` changed to `trap - EXIT`, run with `env -u CARGO_TARGET_DIR` to keep the scratch directory for diagnosis; the copy was deleted afterwards and its scratch directory removed | 32 | 0 | 1 | 0 | same results as run 2 |

**Run 5 failures, quoted.**

- `FAIL  H1 is '# 2026-09-18 — R79 — prometheus-metrics (crate, Focused) — decision (revision 2)', not '… (revision 1)'`.
  This failure is by design and is disclosed in the decision.
- `FAIL  the raw/ directory holds an unexpected number of engine reports`. The cause is an
  untracked `raw/muse.md`, dated 2026-09-25, together with `operations/muse.json`
  (`"state": "submitting"`, `at 2026-09-21T23:06:57Z`). Both files post-date revision 2.

The line `DECISION.md sha256 …` is printed, not asserted: `decision-self-check.sh:72` is a
`printf`. See EA-4.

**Independent re-derivations at source.** Each was run by me, outside the scripts.

| Figure | Command | Result |
|---|---|---|
| `metrics` 0.24.6 tarball | `curl -sSfL https://static.crates.io/crates/metrics/metrics-0.24.6.crate` | sha256 `89550ee9f79e88fef3119de263694973a8adb26c21d75322164fb8c493039fe2`; equals `crate-sources.log:58` |
| `unsafe` posture of `metrics` | `grep -rc unsafe metrics-0.24.6/src` | `cow.rs:27`, `recorder/cell.rs:5`, `recorder/mod.rs:3`, which matches the decision's corrected 27/5/3 |
| `rust-version` literal | `grep -n rust-version metrics-0.24.6/Cargo.toml.orig` | `5:rust-version = { workspace = true }`, as claimed |
| RustSec page for `metrics` | `curl -w '%{http_code}' https://rustsec.org/packages/metrics.html` | `404`, as claimed |
| E8 exposition parse | Downloaded `prometheus-3.14.0.darwin-arm64.tar.gz`. Its sha256 `a9623f7f4fe65b1b171b423c1a72bbf23dfdf41a171dcb33e7dd302af80dc01c` equals the release's `sha256sums.txt`. `promtool --version` prints revision `d7598b7141418fa35be2b5ec5d0fefb634199610`, the same build the committed log records. Ran `promtool check metrics < scrape-sample.txt` on the committed sample and on the fresh sample from run 7 | both exit 0 with no output; the committed sample is 41 lines with 0 `http_route="/metrics"` series |
| E2, E3 and runner-up crate counts | runs 2 and 7 | 37→81, 51→79 (+28, the same 28 names), and 82 all reproduce exactly |
| E4 lock size and highest rust-version | runs 2 and 7 | 118 packages; `hashbrown 0.17.1` at 1.85.0 reproduces |
| E5 audit | runs 2 and 7 | no vulnerabilities; 119 crate dependencies; `metrics-util v0.20.4`; the `RUSTSEC-2021-0113` check passes |
| E6 acceptance test | runs 2 and 7 | reproduces: the named test is ok, two `http_route` values, `_count` 51, unmatched 1 |
| Registry invariants (`num`, `created_at`, `rust_version`, `license`, tarball sha256 values, quoted source lines) | run 3 | byte-identical to the committed log |

## Findings

### EA-1 — `cargo-probes.sh` aborts under a set `CARGO_TARGET_DIR`, silently

- **Failed claim.** "Each script exits non-zero on any FAIL, asserts on content rather than on an
  exit code alone, carries `set -euo pipefail` … names every SKIP". Also: "`cargo-probes.log` is
  byte-reproducible except for two header lines".
- **Evidence.** Run 1 was made in the environment as supplied, with
  `CARGO_TARGET_DIR=/tmp/cargo-s15-R79-emp-target` set. Its log ends:
  ```
  PASS  E7 the exporter is absent with the feature off
  stat: illegal option -- c
  usage: stat [-FLnq] [-f format | -l | -r | -s | -x] [-t timefmt] [file ...]
  ```
  The exit status was 1. There is no FAIL line and no `== summary ==`.

  Cause: `cargo-probes.sh:479`–`:480` runs `cargo build`, and the build succeeds. The script then
  reads the binary size from the hard-coded path `"$d/target/release/probe-serve"`. Cargo wrote
  the binary under `$CARGO_TARGET_DIR`, so the file does not exist. BSD `stat -f %z` fails, and the
  GNU fallback `stat -c %s` is an illegal option on macOS. `set -e` then kills the script inside
  the command substitution, which bypasses the pass/fail accounting.
- **Repair.**
  1. Pin the target directory. Add `--target-dir "$d/target"` to every `cargo build`/`test`/`check`
     in the script, or read the directory from
     `cargo metadata --format-version 1 | jq -r .target_directory`.
  2. Make an unreadable binary size a counted `fail`, not an abort. For example:
     `size_off="$(… || true)"; [ -n "$size_off" ] || fail "E7 binary not found at …"`.
  3. Re-record the log.

### EA-2 — E4's "12 packages declare no rust-version" does not reproduce; the join silently drops drifted crates

- **Failed claims.**
  - E4 row: "**12** packages in that graph declare none".
  - The "Claims found wrong" row: "**12**, in the `cargo tree -e normal --features metrics`
    runtime graph".
  - Also: "Every crate count, package name and binary byte figure is exact, because each probe
    package's resolved `Cargo.lock` is snapshotted under `review/evidence/locks/`".
- **Evidence.** Runs 2 and 7 both print `UNDECLARED 11 packages declare no rust-version`. The
  committed log has 12.

  E4 is the one probe that is **not** lock-pinned. `cargo-probes.sh` runs
  `( cd "$e4" && cargo generate-lockfile )` live, and there is no `locks/baseB-msrv.lock`. The
  script then joins the fresh `cargo metadata` output against `treeB-on.txt`, which comes from the
  **snapshotted** `baseB.lock`. The join is on exact `(name, version)` and skips non-matches without
  reporting them.

  In the preserved scratch directory from run 7, five crates had taken patch releases since
  2026-09-18. Each was dropped from the walk:

  | Crate | Version in `baseB.lock` | Version in the fresh E4 lock |
  |---|---|---|
  | `hyper-util` | 0.1.20 | 0.1.21 |
  | `smallvec` | 1.16.1 | 1.16.2 |
  | `thiserror` | 2.0.20 | 2.0.21 |
  | `thiserror-impl` | 2.0.20 | 2.0.21 |
  | `zerocopy` | 0.8.57 | 0.8.59 |

  The same silent drop would hide the `HIGHEST` crate if that crate took a patch bump. That makes
  this a defect in the gate-2 (MSRV) measurement, not only a wobble in a count.
- **Repair.**
  1. Snapshot the E4 lock as `locks/baseB-msrv.lock` and reuse it with `--locked`, as E1–E3 do.
  2. Make the join `fail` on any `(name)` whose version differs between the two sources, instead
     of skipping it.
  3. Re-record the log, and restate the figure with its scope in both places the decision cites it.

### EA-3 — The stripped-binary bytes are not toolchain-stable

- **Failed claim.** "Every crate count, package name and binary byte figure is exact, because each
  probe package's resolved `Cargo.lock` is snapshotted". The E3 figures are "stripped binary
  **1,307,968 B → 1,686,016 B** (**+378,048 B, +28.9%**)".
- **Evidence.** Runs 2 and 7 are identical to each other, so the result is deterministic, not
  noise:

  | Toolchain | Feature off | Feature on | Delta |
  |---|---|---|---|
  | `rustc 1.98.1` (this audit, runs 2 and 7) | 1,307,936 B | 1,685,952 B | +378,016 B |
  | `rustc 1.98.0` (committed log) | 1,307,968 B | 1,686,016 B | +378,048 B |

  A lockfile pins crates, not the compiler. A patch-level toolchain change moves these bytes. The
  percentage (+28.9%) and the order of magnitude are unaffected.
- **Repair.** Choose one:
  - Write a `rust-toolchain.toml` with `channel = "1.98.0"` into each probe package and print
    `rustc -V` beside the figures.
  - Or restate the byte figures as toolchain-bound, give a stated tolerance, and assert the delta
    against that tolerance instead of quoting it as exact.

  Then re-record the log.

### EA-4 — `rest-conformance-r2.sh` does not carry "the whole" revision-1 check set, and it does not assert its digests

- **Failed claims.**
  - Revision note: "`rest-conformance-r2.sh` re-executes its whole check set against revision 2 …
    so nothing the r1 script proved is lost".
  - `## Empirical check`: "Its whole check set is re-executed inside `rest-conformance-r2.sh`".
  - Revision note: the revision-1 artifacts' "sha256 values are pinned and printed by the new
    script so an auditor does not take that on trust".
  - Log section heading: "every revision-1 artifact, pinned by digest and proven byte-identical".
  - Revision note: rerunning `decision-self-check.sh` "fails on exactly those two checks", meaning
    revision 1's H1 and revision 1's sha256.
- **Evidence.**
  - Comparing the section lists of the two rerun logs shows what the r2 script's "revision-1
    self-check set" section (run 6, lines 183–210) omits:
    - the whole 25-check block "every measured figure the decision quotes, cross-checked with its
      own log" (binary bytes, E2–E5 counts, the runner-up count, the highest rust-version,
      reverse-dependency totals, download figures, the corrected `unsafe` figures);
    - the raw engine-report count;
    - `validate_answer_text(raw/opus.md, "crate")`;
    - the promtool-EXECUTED and `scrape-sample.txt`-present checks;
    - the network User-Agent check;
    - the F326-at-`COMMONALITY.md:330` check.
  - The digest block (`rest-conformance-r2.sh`, loop over `emit_r1_artifacts`) runs
    `printf … shasum` and then `pass "revision-1 artifact present and hashed"`. No pinned value is
    compared, so a modified artifact would still PASS.
  - `decision-self-check.sh:72` only `printf`s the DECISION sha256. In run 5 the two FAILs are the
    H1 and **the raw engine count** (caused by the untracked `raw/muse.md`), not the sha256.
  - Mitigation: I independently established byte-identity with `git diff --stat fca40a5 HEAD`,
    which shows only three new files. The omitted figure checks still pass when the superseded
    script runs against revision 2: 69 PASS. The underlying facts therefore hold; the stated proof
    does not.
- **Repair.**
  1. Port the omitted blocks into `rest-conformance-r2.sh`: the figure cross-check, the raw engine
     count, the raw validator, F326, the User-Agent check and the promtool record.
  2. Or narrow both claims to what the script actually re-executes.
  3. Turn the digest loop into an assertion against literal pinned sha256 values.
  4. Correct "fails on exactly those two checks" to name the H1 check only, since the sha256 is
     printed and not asserted.

### EA-5 — `cargo-probes.log` is not byte-reproducible outside its two header lines

- **Failed claim.** "`cargo-probes.log` is **byte-reproducible except for two header lines: the
  `$TMPDIR` scratch path and the UTC timestamp.**"
- **Evidence.** Run 2's `diff` against the committed log also differs in these lines:
  - The toolchain lines (`rustc 1.98.1`, `cargo 1.98.1`).
  - `Loaded 1251 security advisories (from /Users/stevemorin/.cargo/advisory-db)` became
    `Loaded 1271 security advisories (from /tmp/cargo-s15-R79-emp/advisory-db)`. The RustSec
    database is live, and the line embeds the `CARGO_HOME` path.
  - Four cargo progress lines appear, which a fresh `CARGO_HOME` emits:
    `Updating crates.io index`, `Downloading crates ...`, `Downloaded axum-prometheus v0.10.1`,
    `Downloaded tower-http v0.7.1`.
  - The E3, E4 and E8 differences described in EA-2, EA-3 and EA-6.

  The script filters only `Blocking waiting for file lock`.
- **Repair.**
  1. Filter cargo's `Updating`/`Downloading`/`Downloaded` progress lines, as the `Blocking` line
     already is, or pass `--quiet`.
  2. Redact the advisory-db path.
  3. Declare the advisory count volatile: print it, and assert only "no vulnerabilities" and "does
     not include `RUSTSEC-2021-0113`".
  4. Declare the toolchain lines as the pin that EA-3 introduces.
  5. Restate the reproducibility sentence to match.

### EA-6 — The script rerun does not reproduce E8 (`promtool` not installed)

- **Failed claim.** The table row "Cargo probes | `./cargo-probes.sh` | 34 | 0 | 0", and E8
  "**accepted**".
- **Evidence.** The script behaved honestly. Run 2 printed
  `SKIP  E8 promtool check metrics (no promtool on PATH and none at $PROMTOOL; install Prometheus or set PROMTOOL=<path> to run it)`,
  and the count fell to 32/0/1. I then executed E8 by hand with the pinned release (see the
  re-derivations table). Both the committed and the fresh sample parse with exit 0. **The
  underlying claim holds; the script cannot re-execute it on a stock host.**
- **Repair.**
  1. Have the script download and checksum-verify `prometheus-3.14.0.<os>-<arch>.tar.gz` against
     the release's `sha256sums.txt` when `promtool` is absent.
  2. Or document the `PROMTOOL=<path>` prerequisite in `## Empirical check` beside the 34/0/0
     figure.

## Observations (recorded, not blocking)

- **Reverse-dependency totals.** `metrics` moved 1,199 → 1,220 and `metrics-exporter-prometheus`
  moved 460 → 465. The `## Engines` table calls these "exact". Neither total is named in the
  decision's list of volatile-field comparison rules. The script asserts only the order of
  magnitude, so the rerun still passes. The volatile-field list should name these totals.
- **Muse leg.** An untracked Muse leg now exists for this run: `raw/muse.md`, plus
  `operations/muse.json` in state `submitting`. It post-dates revision 2 and is outside this audit.
  If it is collected, the statement "one of the two ran" in `## Engines` and the premise of the raw
  engine-count check both go stale. The controller should reconcile them before acceptance.
- **Header-only differences.** The `rest-conformance-r2.sh` rerun (122/0/0) differs from its
  committed log **only** in header lines 2–4. The REST-standard blob
  `71bd813c1cf61286586b4ee41ed83ff065e5c8d9` and commit `0850d43e…` are both present in
  `/Users/stevemorin/c/rest-standards`; the r2 script re-derives the blob id from the bytes. The
  45-rule snapshot diff is clean. The r2 script's own checks are sound; EA-4 concerns only what the
  decision says the script covers.
