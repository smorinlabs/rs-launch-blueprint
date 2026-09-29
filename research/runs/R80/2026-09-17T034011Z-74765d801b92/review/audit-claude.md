actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 184d2b1714f8eb26a7b4df43b6020feb280662e85fcf3668a7fb0938d0d230c8
verdict: reject
unresolved-findings:
1. EA-1 (observed script failure) — O17 pins a mutable file; check-offline, check-standard-r2 and check-standard-r3 all FAIL in the current repository state (claim, evidence and repair under `### EA-1` below).
2. EA-2 (evidence support) — the `q=liveness` census figure the decision states is not the figure its own evidence recorded (detail under `### EA-2`).
3. EA-3 (observed script failure) — O27, and every other `printf '%s' "$VAR" | $GREP -q…` assertion, is racy under `set -o pipefail`; observed as a false FAIL (detail under `### EA-3`).
4. EA-4 (reproducibility drift) — the probe workspaces carry no committed `Cargo.lock`; the "`--offline` from the warm registry cache" build does not reproduce, and transitive versions drift (detail under `### EA-4`).
5. EA-5 (evidence support) — the decision's `OVERRIDE (OV-05)` count (10) disagrees with the count its own check logged (11) (detail under `### EA-5`).

# R80 health-probe-endpoints — empirical audit of revision 3

Auditor: claude (`claude-opus-5-5`, anthropic), a fresh context independent of the
synthesizer and of the judgment auditor. Audit date 2026-09-26 (US Pacific). Target:
`research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md`, revision 3.

## Identity

`shasum -a 256 DECISION.md` →
`184d2b1714f8eb26a7b4df43b6020feb280662e85fcf3668a7fb0938d0d230c8`, equal to the
expected hash. The file is clean against `HEAD` (`53b13f45 fix(research): R80
revision 3 — renumber the override to OV-05`).

## Currency determination

`## Empirical check` names five scripts and five paired logs as the revision-3
evidence, 99 checks in total:

| Script | Paired log | Revision | Claimed |
|---|---|---|---|
| `check-offline.sh` | `check-offline.log` | 1 | 28 PASS |
| `check-probe.sh` | `check-probe.log` | 1 | 13 PASS |
| `check-live.sh` | `check-live.log` | 1 | 9 PASS |
| `check-standard-r2.sh` | `check-standard-r2.log` | 2 | 42 PASS |
| `check-standard-r3.sh` | `check-standard-r3.log` | 3 | 7 PASS |

The decision states that the revision-1 and revision-2 logs are current for
revision 3 unchanged, with check `R6` proving by digest that they were not rewritten.
The decision does not treat `check-offline.r2-rerun.log` and
`check-standard-r2.r3-rerun.log` as paired logs. Those two files are deliberate
expected-failure reruns asserted by `C9` and `R7`. I followed that determination:
the five logs in the table are the ones compared below. Check `R6` passed in both of
my `check-standard-r3.sh` runs, so the seventeen revision-1 and revision-2 artifacts
are byte-identical to the digests recorded in the script.

## Method

- **Host.** macOS 26.4 (`Darwin 25.4.0`), arm64.
- **Toolchain.** `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` and
  `cargo 1.98.1 (797e8a9bc 2026-08-05)`. The decision recorded 1.98.0, so this is a
  toolchain drift.
- **Other tools.** `/usr/bin/grep` is BSD grep 2.6.0-FreeBSD; ShellCheck is 0.11.0.
- **Cargo home.** A private, empty-cache `CARGO_HOME`, as supplied by the environment.

Three scripts write inside their own directory:

- `check-live.sh` refreshes `./snapshots` in fetch mode.
- `check-standard-r2.sh` writes `check-offline.r2-rerun.log`.
- `check-standard-r3.sh` writes `check-standard-r2.r3-rerun.log`.

To keep `evidence/` untouched, every script ran from a copy. Nothing under
`evidence/` was written. I ran two configurations:

- **WT (working tree).** `evidence/` copied to `/tmp/r80audit/evidence`, and each
  script run as `bash /tmp/r80audit/evidence/<script> /Users/stevemorin/c/rs-launch-blueprint-p02-plan`
  with the repository root as `$1`. This reads the live working tree, including its
  uncommitted changes to other items.
- **HEAD.** `git archive HEAD | tar -x -C /tmp/r80audit/head`, a read-only
  extraction, with each script run from inside it against that root.

Fresh logs went to `/tmp/r80audit/*.log`. Each was compared with `cmp`, then `diff`.

## Reruns

| Script | Config | Exit | Observed totals | Committed totals | Byte-identical? |
|---|---|---|---|---|---|
| `check-offline.sh` | WT, run 1 | 1 | **25 PASS, 3 FAIL, 0 SKIP** (O17, O25, O27) | 28/0/0 | no |
| `check-offline.sh` | WT, runs 2–6 | 1 | **26 PASS, 2 FAIL, 0 SKIP** (O17, O25) | 28/0/0 | no |
| `check-offline.sh` | HEAD, ×21 | 1 | **27 PASS, 1 FAIL, 0 SKIP** (O25) in all 21 | 28/0/0 | no |
| `check-probe.sh` | WT | 0 | **13 PASS, 0 FAIL, 0 SKIP** | 13/0/0 | no (assertion lines identical) |
| `check-probe.sh` | HEAD | 0 | **13 PASS, 0 FAIL, 0 SKIP** | 13/0/0 | no (assertion lines identical) |
| `check-live.sh` (fetch) | WT | 0 | **9 PASS, 0 FAIL, 0 SKIP** | 9/0/0 | no (counters only) |
| `check-live.sh --snapshots` | HEAD | 0 | **9 PASS, 0 FAIL, 0 SKIP** | 9/0/0 | no (banner and date only) |
| `check-standard-r2.sh` | WT | 1 | **39 PASS, 3 FAIL, 0 SKIP** (C2, C4, C9) | 42/0/0 | no |
| `check-standard-r2.sh` | HEAD | 1 | **40 PASS, 2 FAIL, 0 SKIP** (C2, C4) | 42/0/0 | no |
| `check-standard-r3.sh` | WT | 1 | **6 PASS, 1 FAIL, 0 SKIP** (R7) | 7/0/0 | no |
| `check-standard-r3.sh` | HEAD | 0 | **7 PASS, 0 FAIL, 0 SKIP** | 7/0/0 | differs only on `git metadata: present` → `absent (archive extraction)` |
| `shellcheck` on all five | — | 0 | no output | exit 0 | — |

The decision predicts three of these failures, and they are not findings:

- **O25.** A first-revision shape rule, which revision 2 is entitled to break.
- **C2 and C4.** They pin the revision-2 H1 and the old override name that revision 3
  renames; `R7` measures them.

At `HEAD`, with the flake excluded, every script reproduces the decision's design
exactly: offline 27/1 with only O25, r2 40/2 with only C2 and C4, and r3 7/0/0.
The problems are in reproducibility and in the stated figures, not in the recommendation.

### Diff detail

**`check-offline.log`, WT.** `cmp` reports `differ: char 49, line 2`, the date
stamp. The first differing assertion lines are:

```
33c33
< PASS O17 — the accepted-but-unpublished inputs stand at R02 revision 2 (evidence-only re-bind of revision 1), R05 revision 3 and R03 revision 1 — raw/opus.md cites R02 r1 and R05 r2, which this decision corrects
---
> FAIL O17 — the coupled decisions are not at the revisions this decision cites
40c40
< PASS O27 — py's run_diagnostics builds all four named checks (python, platform, config-file, token) and exactly one of them — python, gated on MIN_PYTHON = (3, 12) — can be error (counted with grep (BSD grep, GNU compatible) 2.6.0-FreeBSD); Rust has no runtime-toolchain analogue to port
---
> FAIL O27 — py's check set is not the four named checks with exactly one error-capable status (names found: 4 of 4, error-capable: 1)
```

O25 also flips from PASS to FAIL, as expected. At HEAD the diff is the date, the
repo-root line, `git metadata: present` → `absent (archive extraction)`, and O25.

**`check-probe.log`.** The assertion lines (`PASS`/`FAIL`/`SKIP`/`===`) are
identical: both sets hash to `sha1 02d44bac56bf…`. The whole-log diff is 189 lines
in WT and 129 at HEAD. Beyond the date, the `mktemp` path and cargo progress lines,
the diff contains these non-progress lines:

```
< rustc: rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)
< cargo network flags: '--offline'
> rustc: rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)
> NOTE: --offline metadata failed; retrying without it
> error: no matching package named `serde` found
> cargo network flags: '<online>'
<     │   │   ├── smallvec v1.16.1
>     │   │   ├── smallvec v1.16.2
<     │   ├── hyper-util v0.1.20
>     │   ├── hyper-util v0.1.21
```

The direct pins all hold: `axum v0.8.9`, `tokio v1.53.1`, `serde v1.0.229`,
`serde_json v1.0.151` and `tower v0.5.3`. The only version drift across the whole
`cargo tree` output is those two transitive crates (see EA-4).

**`check-live.log`, fetch mode.** 48 diff lines. Every one is one of the following:

- the date stamp;
- a download counter;
- a crates.io search denominator — `q=health` 6488→6655, `q=probe` 5273→5561,
  `q=liveness` 28347→29566;
- `rocket_healthz` recent downloads, 1281→1276;
- a GitHub `pushed_at` or star count — `lukaslueg/built` `pushed_at`
  2026-06-07→2026-09-24; `rustyhorde/vergen` stars 473→475.

Every pin, `rust_version` null-ness, HTTP status and quoted sentence that L1–L9
assert still holds. That is the decision's stated design ("structure and pins, never
a counter"), and it held after 9 days. The `--snapshots` run at HEAD differs from the
committed fetch-mode log only on the `mode:` banner and the date.

**`check-standard-r2.log`, HEAD.** The diff is the date, cargo progress lines, the
same `--offline` fallback note, the test-duration `0.01s`→`0.00s`, and the
expected C2/C4 flips. **WT** adds C9, which the O17 failure cascades into:

```
<   revision-1 offline script re-run under revision 2: 27 PASS, 1 FAIL
>   revision-1 offline script re-run under revision 2: 26 PASS, 2 FAIL
>     FAIL O17 — the coupled decisions are not at the revisions this decision cites
> FAIL C9 — re-running the revision-1 offline script did not yield exactly 27 PASS and the single expected O25 failure (26 PASS, 2 FAIL)
```

**`check-standard-r3.log`, WT.**

```
<   revision-2 script re-run under revision 3: 40 PASS, 2 FAIL
>   revision-2 script re-run under revision 3: 39 PASS, 3 FAIL
> FAIL R7 — re-running the revision-2 script did not yield exactly 40 PASS and the two expected C2/C4 failures (39 PASS, 3 FAIL)
< === 7 PASS, 0 FAIL, 0 SKIP ===
> === 6 PASS, 1 FAIL, 0 SKIP ===
```

## Figures re-derived at source

- `GET https://crates.io/api/v1/crates/axum` → `max_stable_version` `0.8.9`. The pin holds.
- `DECISION.md` contains 7 `- assumes` lines, 0 `- owns` lines, and exactly 1
  `re-verify:` line. This matches R5.
- The pinned py source `b08bccfb…:src/py_launch_blueprint/core/diagnostics.py`
  contains `MIN_PYTHON = (3, 12)` at line 40. O27's substantive claim is true; its
  failure is the harness race described in EA-3.
- The owner-acceptance row in `docs/port/OWNER-ACCEPTANCES.md` line 75 is R05 at
  revision 3, sha `3ca4b81a…`, `accept`, 2026-09-18. The row is the same at HEAD
  and in the working tree. R80's citation of R05 revision 3 is therefore still the
  accepted one today. EA-1 concerns how the check binds to that citation.
- `grep -c 'OVERRIDE (OV-05)' DECISION.md` → `11` (see EA-5).
- `cratesio-search-liveness.json` snapshot → `"total": 28347` (see EA-2).

## Findings

### EA-1 (observed script failure) — O17 reads the mutable R05 file, so three scripts fail today

**Failed claim.** In `## Empirical check`, `check-offline.sh` reports "**28 PASS,
0 FAIL, 0 SKIP**". The decision says the r2 and r3 reruns yield "exactly one
failure, which is `O25`" and "exactly **two** of its 42 checks now fail … `C2` …
and `C4`".

**Evidence.**

- `check-offline.sh` line 315 asserts `head -1 "$R05" | $GREP -qF '(revision 3)'`
  against the live file `research/runs/R05/…/review/DECISION.md`.
- In the working tree, that file carries an uncommitted R05 revision 4. Its H1 is
  `… decision (revision 4)`, a narrow repair answering a round-3 judgment rejection
  of revision 3. So O17 FAILs on every WT run, 6 of 6.
- The failure cascades. `C9` in `check-standard-r2.sh` gets 26/2 instead of 27/1.
  `R7` in `check-standard-r3.sh` then gets 39/3 instead of 40/2.
- Result: three of the five scripts exit non-zero in the repository as it stands.
- At `HEAD`, R05's H1 still reads revision 3, and all three scripts reproduce as
  designed.
- When R05 revision 4 is committed and accepted, the failures become permanent.
  R80's prose citations of "R05 revision 3" then also go stale: lines 384, 388 and
  507, plus `## Engines` disagreement 2, which cites sha `3ca4b81a…`.
- The `re-verify:` line has only one R05 trigger: "when R05 is reopened to an async
  core". It has no trigger for a narrow R05 revision.

**Repair.**

1. Bind O17 to identity, not to a mutable header. Either assert the sha256 of the
   cited R05, R02 and R03 revisions against the owner-acceptance rows in
   `docs/port/OWNER-ACCEPTANCES.md`, or read the files with `git show <pinned
   commit>:<path>`.
2. Add a `re-verify:` trigger: "when R05, R02 or R03 is re-bound to a new accepted
   revision".
3. The order matters. If R05 revision 4 is accepted before R80's next revision,
   re-citing R05 at lines 384, 388 and 507 becomes mandatory, not optional. Either
   way, when R05 revision 4 is accepted, re-record the O17 and C9 logs with the new
   revision and sha as an evidence-only revision, and re-cite R05 at lines 384, 388
   and 507.

### EA-2 (evidence support) — the decision states a census figure its evidence contradicts

**Failed claim.** `## Empirical check`, lines 1092–1093: "The three census
denominators had already moved … on the same day: … `q=liveness` 28,351 →
**28,356**". `## Engines`, line 1213, repeats `28,351→28,356`. The surrounding
sentence argues that "crates.io download counters and search denominators advance
continuously".

**Evidence.**

- The committed `evidence/check-live.log` line 46 reads `q=liveness:
  meta.total=28347`.
- `check-live.archive-snapshots.log` line 46 reads the same value.
- The committed snapshot `evidence/snapshots/cratesio-search-liveness.json` has
  `"total": 28347`.
- The other two figures match their logs: 6,488 and 5,273.
- So the stated 28,356 is supported by no artifact.
- The recorded value, 28,347, is a *decrease* from `raw/opus.md`'s 28,351. That
  contradicts the "advance continuously" gloss the figure illustrates.
- Today's live value is 29,566. The figure is not load-bearing for the
  recommendation, but it is a stated observation that the evidence does not support.

**Repair.** Change `28,356` to `28,347` at both sites. Replace "advance
continuously" with "move in both directions (the liveness denominator fell by 4)".
Better still, generate the three quoted denominators from the log instead of
transcribing them.

### EA-3 (observed script failure) — O27, and every `printf | grep -q` assertion, is racy

**Failed claim.** The scripts' checks are presented as deterministic ("Each asserts
on content"). `check-offline.log` reproduces "byte-for-byte" apart from the
normalised lines.

**Evidence.**

- WT run 1 of `check-offline.sh` FAILed O27 even though its own diagnostic line
  printed the passing values: `py distinct check names found: 4 of 4; error-capable
  statuses: 1; unconditional error statuses: 0`.
- The only remaining condition is line 391:
  `printf '%s' "$DIAG" | $GREP -qF 'MIN_PYTHON = (3, 12)'`.
- `$DIAG` is 4713 bytes, and the needle sits in its first 4096 bytes. The observed
  behaviour is consistent with a SIGPIPE race under `set -o pipefail`: `grep -q`
  exits on its first match, a later `printf` write can get SIGPIPE, and `pipefail`
  reports the pipeline as failed. I did not capture `${PIPESTATUS[0]}` = 141
  directly; the finding rests on the observed false-failure rate below, not on the
  mechanism.
- Reproduced in isolation: **12 false failures in 3000** iterations under CPU load.
  In quiet conditions there were 0 in 200, and 0 in 20 further full-script runs.
- The same construct appears **19 times** in `check-offline.sh` (O3, O5, O20–O22,
  O27 and others), **6 times** in `check-standard-r2.sh` and **8 times** in
  `check-standard-r3.sh`. Any of them can fail spuriously once its input exceeds one
  pipe write.

**Repair.** Replace every `printf '%s' "$X" | $GREP -q…` with a form that has no
second writer, then re-record the logs:

- a here-string, `$GREP -qF -- 'needle' <<<"$X"`, or
- `[[ $X == *"needle"* ]]`.

For the `head -1 file | $GREP -q` cases, use `$GREP -m1 … file` or read the line
into a variable first.

### EA-4 — no committed lockfile; the `--offline` build claim does not reproduce

**Failed claim.** `## Empirical check`: the probe "resolves **axum 0.8.9 · tokio
1.53.1 · serde 1.0.229 · serde_json 1.0.151 · tower 0.5.3** … and builds
`--offline` from the warm registry cache".

**Evidence.**

- `evidence/probe/` and `evidence/probe-r2/` contain manifests and sources but no
  `Cargo.lock`.
- With a clean cargo home, both `check-probe.sh` and `check-standard-r2.sh` print
  `NOTE: --offline metadata failed; retrying without it` and resolve online.
- The WT error was `no matching package named serde found`. The HEAD error was
  `failed to download wasi v0.11.1+wasi-snapshot-preview1`.
- The fresh resolution moved two transitive crates: `hyper-util 0.1.20 → 0.1.21`
  and `smallvec 1.16.1 → 1.16.2`.
- The toolchain moved from `rustc 1.98.0` to `1.98.1`.
- All assertions still pass, and the five direct pins hold. So this is
  reproducibility drift, not a changed result. But the tree that was measured cannot
  be rebuilt from the committed evidence.

**Repair.**

1. Commit the `Cargo.lock` produced for each probe workspace: manifests-a,
   manifests-b and the r2 workspace.
2. Copy the lockfile in and build with `--locked`, so transitive versions are fixed.
   Online resolution is then acceptable.
3. State in `## Empirical check` that the offline path depends on a warm local
   cache, and that the online fallback is expected.
4. Record the toolchain as `rust-version = "1.96"`-compatible. Optionally add a
   `rust-toolchain.toml` pin, or state the exact compiler as observed rather than
   required.

### EA-5 — the stated `OVERRIDE (OV-05)` count disagrees with the logged count

**Failed claim.** `## Empirical check`, line 1022: "the old override heading
appears **0** times and `OVERRIDE (OV-05)` appears 10, its own H4 included".

**Evidence.**

- The committed `evidence/check-standard-r3.log` line 7 reads `'OVERRIDE (OV-04)'
  occurrences: 0; 'OVERRIDE (OV-05)': 11`.
- R2's pass line in that log says "11 times".
- `grep -c` on the target revision today gives 11.
- R2 asserts only `NEW_HEAD -ge 1`, so it could not catch this prose discrepancy.

**Repair.** Change "appears 10" to "appears 11". Tighten R2 to assert the exact
count the prose states, so the prose and the log cannot diverge again.

## What is sound

- Execution at `HEAD` reproduces the designed outcome for all five scripts, and
  every assertion line is byte-identical where the decision says it should be.
- Live checks L1–L9 pass nine days later against moving counters, which is exactly
  the drift-tolerant design the decision claims.
- The snapshots mode is deterministic.
- `shellcheck` is clean on all five scripts.
- R6 proves the revision-1 and revision-2 artifacts unmodified.

The rejection rests on the two observed script failures:

- **EA-1.** Three of the five scripts fail in the repository's current state, and
  will keep failing once R05 revision 4 lands.
- **EA-3.** A check FAILed spuriously in my first rerun, and the same construct
  appears at 33 sites across three scripts.

EA-2 and EA-5 are evidence-support findings: stated figures that their own logs
contradict. EA-4 is reproducibility drift. Under RUNBOOK section 5, every
unresolved finding blocks acceptance, so all five should be repaired in one
evidence-only revision.
