actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 72bd7972c748e529a1b226db5940e7ade4b5a2adf8e98588b137479bb6d3c5c8
verdict: approve
unresolved-findings: none

# R68 — empirical audit of DECISION.md revision 2

Seat: empirical auditor. I was independent of the synthesizer and of the judgment auditor. This audit
judges only execution truth and evidence support. It does not judge whether the recommendation is fit.

Audited file: `review/DECISION.md`, revision 2. I recomputed its digest with
`shasum -a 256` before starting and again before writing. Both times it was
`72bd7972c748e529a1b226db5940e7ade4b5a2adf8e98588b137479bb6d3c5c8`, the expected value.

Audit date: 2026-09-26 (Pacific), 2026-09-27 UTC.

## Environment

| Property | Value |
|---|---|
| `rustc` | `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, commit `48a229ceaefd4985c50990b14116b6d856af0985` |
| `cargo` | `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)` |
| LLVM | 22.1.8 |
| Host | macOS 26.4 (25E246), Apple M4 Pro, `aarch64-apple-darwin` |
| `CARGO_HOME` | `/tmp/cargo-s12-R68-emp`, a private cargo home. The committed run used `/tmp/cargo-s8-R68-r2`, so by the decision's own classification this rerun is an other-paths rerun. |
| `TMPDIR` | the default macOS `$TMPDIR` |

The environment also sets `CARGO_TARGET_DIR`. The probe overrides it on every build: see
`profile-probe.sh` lines 287, 437 and 441. The environment value therefore did not affect any row.

Working directory for every script: `review/evidence/`. All output went to `/tmp/r68-audit-r2/`.
Nothing under `evidence/` was written.

## 1. Reruns

### 1a. `artifact-sources.sh`

Command: `./artifact-sources.sh > /tmp/r68-audit-r2/artifact-sources.fresh.log 2>&1`.

- The script exited 0 and ended with `RESULT: PASS — every assertion held`.
- Totals: 26 `ASSERT ok`, 0 fail, 0 skip.
- `cmp` against `artifact-sources.r2.log` reported `differ: char 59, line 2`.
- `diff` showed exactly one differing line, the date:

```
2c2
< date(UTC): 2026-09-27T01:15:28Z
---
> date(UTC): 2026-09-27T03:26:19Z
```

Every `ASSERT`, `PINNED`, `HEAD` and `FIGURE` line was byte-identical. This includes
`registry-gap-present=1` and the live `FIGURE` counters, which had not moved within about two hours.

### 1b. `decision-self-check.sh`

Command: `./decision-self-check.sh > /tmp/r68-audit-r2/decision-self-check.fresh.log 2>&1`.

- The script exited 0 and ended with `RESULT: PASS`.
- Totals: 26 `ASSERT ok`, 0 fail, 0 skip.
- `cmp` against `decision-self-check.r2.log` reported `differ: char 56, line 2`.
- `diff` showed only the `date(UTC):` line:

```
2c2
< date(UTC): 2026-09-27T01:20:43Z
---
> date(UTC): 2026-09-27T03:26:39Z
```

The byte count the log prints, `decision: DECISION.md (57901 bytes)`, is also unchanged. This confirms
that the committed self-check log was produced against the audited bytes of `DECISION.md`.

**Extraction without `.git`.** I also ran the self-check in a copy of the repository that has no
`.git` directory. The copy was built at `/tmp/r68-audit-r2/extract` from two sources:

- `git ls-files`, excluding `research/topics/*/raw/`
- the untracked `review/` files of this run

In that copy the script exited 0 with the same 26 passes. Its output differed from the fresh log only
in the `date(UTC):` line. This supports the decision's claim that the script runs from an extraction
and needs no `.git`.

### 1c. `profile-probe.sh`

Command: `./profile-probe.sh > /tmp/r68-audit-r2/profile-probe.fresh.log 2>&1`.

- The script exited 0 and ended with `RESULT: PASS — every assertion held`.
- Totals: 21 `ASSERT ok`, 0 fail, 0 skip. The log has no `NOTE` line and no `UNPINNED` line.

Under the decision's reproduction rule, this rerun is compared with `profile-probe.r2.log` on
assertion outcomes, backtrace lines and deltas, not on bytes. `cmp` differs at line 2, which is
expected.

| Compared item | Result |
|---|---|
| `ASSERT` outcomes and labels, with parenthesized figures stripped | **identical**, 21 of 21, all `ok` |
| `BACKTRACE` lines, including `'at ./src/' lines in tree=2, … target/=0` | **byte-identical** |
| `DELTA` lines | **byte-identical on all 12 rows**. The largest difference is 0.0 percentage points (pp), against the ±2.5 pp tolerance. |
| Lockfile sha256 `2756d45c…1082`, `packages pinned … 85`, `default=52 all-features=93`, and the nine direct-dependency versions | **identical** |
| `SIZE` lines | one differs: `debug=line-tables-only` is 2242552 bytes in r2 and **2242728** bytes here (+176 B). Its after-external-strip size (1628280) and its `DELTA` (+12.5%) are unchanged. All other `SIZE` lines are byte-identical. |

The single moved `SIZE` line fits the decision's statement that absolute paths alone move sizes. In
the decision's alt-paths control, the same row grew by 576 B with an unchanged `DELTA`.

**Build times from this rerun.** These are wall-clock figures and do not reproduce.

| Build | Baseline | Recommended (`fat+cu1`) | Ratio |
|---|---|---|---|
| Clean build | 17 s | 41 s | about 2.4× |
| Bin-only rebuild | 2 s | 19 s | about 10× |

The bin-only rebuild keeps the order-of-magnitude separation that the decision claims.

The clean-build ratio of about 2.4× falls outside the 1.3×–1.9× spread the decision tabulates for its
five runs. That is **not a finding**. The decision explicitly makes no numeric clean-build claim; it
says only "materially longer, once per release" and records the question as unsettled. This run adds
a sixth data point, taken while other processes were running on the host. It widens the spread
toward Opus's "roughly doubles".

### 1d. The decision's own controls, checked against their committed logs

**`profile-probe.r2.log` against `profile-probe.r2-rerun-same-env.log`.** Only the `date(UTC):` line
and `TIME` lines differ. This confirms the decision's "0.0 pp, byte-identical `SIZE`/`DELTA`/
`BACKTRACE`/`ASSERT`" row.

**`profile-probe.r2.log` against `profile-probe.r2-rerun-alt-paths.log`.** Besides the date and `TIME`
lines, exactly these lines differ:

- `SIZE lto=fat`: 1598560 → 1615072 bytes
- `DELTA lto=fat`: −19.8% → −19.0%. This is the stated 0.8 pp.
- the `lto=fat` `ASSERT` text, whose outcome stays `ok`
- `SIZE debug=line-tables-only`: 2242552 → 2243128 bytes. This is the stated +576 B, with an unchanged `DELTA`.

The decision's claims about this control are confirmed.

**Build-time table.** I re-derived it from the three r2 logs and `profile-probe.log`:

| Run | Clean build | Bin-only rebuild |
|---|---|---|
| r2 | 17 → 25 s | 1 → 12 s |
| same-env | 16 → 30 s | 1 → 13 s |
| alt-paths | 18 → 24 s | 1 → 12 s |
| r1 run 1 (`profile-probe.log`) | 17 → 23 s | 1 → 11 s |

These ratios span 1.33× to 1.88×. The decision's "about 1.3× to 1.9×" is correct.

### 1e. `R68_TOOLCHAIN` route, exercised without a download

The decision states that this route was written but not run (lines 628–635). My first reading stopped
at line 597, so I briefly suspected that the revision note's pointer to `## Engines` was false. That
suspicion was an artifact of the truncated read: the disclosure is present at lines 628–635.

I ran `R68_TOOLCHAIN=1.97.1 RUSTUP_AUTO_INSTALL=0 ./profile-probe.sh`, using a rustup toolchain that
was already installed. The script exited 1. The log shows three things:

- `toolchain selected by: rustup run 1.97.1`
- `rustc: rustc 1.97.1 (8bab26f4f 2026-07-14)`
- the documented guard message: `ASSERT FAIL: rustc/cargo is not 1.98.1. Install it with
  `rustup toolchain install 1.98.1` and rerun with R68_TOOLCHAIN=1.98.1, …`

So the function-shadowing route and the guard work as described. What remains unexercised is a full
probe on rustup's 1.98.1 distribution. That run still needs `static.rust-lang.org`, as the decision
states.

## 2. Load-bearing figures re-derived at source

**Size deltas.** I recomputed every row from the `SIZE` lines of `profile-probe.r2.log`. Each result
rounds to the tabulated `DELTA`:

| Row | Recomputed delta |
|---|---|
| `lto=thin` | −1.259% |
| `lto=fat` | −19.833% |
| `codegen-units=1` | −14.884% |
| `thin+cu1` | −15.963% |
| `fat+cu1` | −24.548% |
| `opt-level=s` | +12.939% |
| `opt-level=z` | +21.774% |
| `strip=symbols` | −22.900% |
| `strip=debuginfo` | 0.000% (1994032 == 1994032) |
| `panic=abort` | −20.243% |
| `debug=line-tables-only` | +12.463% |

**Threshold margins.** All four are correct:

| Assertion | Margin |
|---|---|
| `fat+cu1` below the 20% line | 4.5 pp past it |
| `thin+cu1` short of the 20% line | 4.0 pp |
| `lto=thin` inside its 5% bound | 3.7 pp |
| `strip=symbols` past its 15% bound | 7.9 pp |

**Revision-1 column.** It matches `profile-probe.log` on every row. The r1-to-r2 maximum difference is
0.1 pp, on `opt-level=s` (13.0 → 12.9) and `panic=abort` (20.3 → 20.2). The r1 baseline was 1994112
bytes, and its `strip=debuginfo` row was byte-identical to that baseline, as the decision states.

**Lockfile.** `shasum -a 256 profile-probe.Cargo.lock` gives `2756d45c…1082`. The file has 85
`[[package]]` entries, and `thiserror` is `2.0.20`. All three match the decision.

**Cited source lines.** Each cited source line is present in the fresh `artifact-sources` log:

| Source | Line or figure |
|---|---|
| dist `config.md` | line 1277, undrafting sentence |
| dist `github.rs` | `ubuntu-latest` count 0 |
| dist `CHANGELOG.md` | line 2274 under `# Version 0.0.3 (2023-02-27)` |
| dist `v0.33.0` release | 23 assets |
| cargo-binstall `SUPPORT.md` | lines 124, 148 and 149 |
| upload-rust-binary-action | `$bin-$target` default |
| release-please manifest reference | lines 217–221 |
| crates.io | cargo-binstall `1.24.0` with `rust_version=1.79.0`; cargo-dist newest `0.32.0` |

**Other claims.**

- **`shellcheck`.** `shellcheck` 0.11.0 reports nothing on `profile-probe.sh` or
  `decision-self-check.sh` (exit 0).
- **Revision-1 logs unchanged.** `git status` shows the three revision-1 logs as unmodified:
  `profile-probe.log`, `artifact-sources.log` and `decision-self-check.log`.
- **`re-verify:` line.** It is present at line 296.

## 3. Not re-derived, and why

**Rows from sources this seat may not read.** Two rows of the reproduction-rule table come from
sources outside my permission:

- the row against `raw/opus.md` lines 463–476 (1.0 pp)
- the row against `review/audit-claude.r1.md` runs 3c/3d (2.0 pp)

The ±2.5 pp tolerance is derived from that 2.0 pp figure, which I did not re-derive. The decision
labels the tolerance an estimate, not a measured bound. Every delta in my rerun was within 0.0 pp, so
the tolerance was not tested near its edge here.

**Row that cannot be verified.** The "revision 1, run 2 (log not kept)" build-time row cannot be
verified by construction, because its log was not kept.

**Claims outside this seat's scope.** Claims about `dist`, the release-please hand-off and binstall
inference in a real release were not executed. The decision itself lists them as unproven, for P03
to prove.

## 4. Notes, not findings

- `decision-self-check.sh` labels two sections `--- 6.` (the lockfile check and the privacy check).
  This is a numbering defect only; it does not affect any assertion.
- This audit changed no files other than this one.
- I ran no git write, no `scripts/research_runner.py` command, and no paid or submitting API call.
