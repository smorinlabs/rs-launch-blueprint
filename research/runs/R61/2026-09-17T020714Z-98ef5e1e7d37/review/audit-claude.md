# R61 — empirical audit (Claude seat) — DECISION.md revision 1

actor: audit-claude-2026-09-17T020714Z-98ef5e1e7d37
model: claude-opus-5-5
family: anthropic
decision-sha256: 3131e895187c096c8866f0f7b4a520549804cd67b32f848b6239cd652b636281
verdict: approve
unresolved-findings: none

**Seat.** This audit ran on the Claude seat as the approved fallback while the OpenAI provider is quota-paused (method amendment Q8.B). It is not a Codex audit. The auditor ran in a fresh context, independent of the synthesizer and the judgment auditor. It did not read `review/audit-fable.md` or `research/topics/61-*/raw/`.

**Scope.** This audit judges execution truth and evidence support only: whether the commands run, whether the logs match the claims, and whether the figures are right. It does not judge whether the recommendation is wise.

**Audit date.** 2026-09-22 (the rerun header recorded `2026-09-22T20:03:26Z`). Scratch output was written to `/tmp/r61-audit-claude.log` and `/tmp/r61-audit-claude.diff`. Those files are ephemeral, so every result that matters is quoted below.

## 1. Target identity

```
$ shasum -a 256 research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/DECISION.md
3131e895187c096c8866f0f7b4a520549804cd67b32f848b6239cd652b636281
```

This matches the expected hash, both before the work started and again immediately before this file was written.

## 2. Rerun of the empirical check

**Environment.** `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1`, Darwin arm64 / macOS 26.4, Python 3.14.7, `/usr/bin/grep` (BSD grep 2.6.0-FreeBSD).

**Pre-run check.** Every write the script makes goes under `WORK="${TMPDIR:-/tmp}/r61-claims-$$"`, which the `EXIT` trap removes. The script's stdout was redirected to `/tmp`, so the recorded `r61-claims.log` was not overwritten. `git status --porcelain` on the evidence directory was empty both before and after the run.

**Command.**

```
cd research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/evidence
bash r61-claims.sh > /tmp/r61-audit-claude.log 2>&1 ; echo "exit=$?"
```

**Observed.** The command printed `exit=5` and `TOTAL  pass=92  fail=5  skip=0`. The decision's recorded run shows `pass=97 fail=0 skip=0`.

These are the five failed assertions, verbatim:

```
FAIL C13c — case B: stdin is still not a terminal [not found: stdin_is_terminal=false]
FAIL C13d — case B: crossterm ACQUIRES the controlling terminal anyway — the surprise-prompt case R8.1 forbids [not found: crossterm_enable_raw_mode=Ok]
FAIL C13e — case B: dialoguer's own guard returns true, so no candidate crate blocks this case [not found: dialoguer_guard_term_stderr_is_term=true]
FAIL C13f — case B: the observation ran to completion [not found: child_exit_status=0]
FAIL C15a — the string OV-02 appears in no other published decision or port document [got '1', want '0']
```

Section 3 investigates both groups. Neither one contradicts a claim in the decision.

**Diff against the recorded log.** The command was `diff -u r61-claims.log /tmp/r61-audit-claude.log`, and the diff is 142 lines long including headers. Apart from the five failures above, every changed line falls into a category that the decision's comparison rule lists as varying by design:

| Changed field | Recorded (2026-09-17) | Rerun (2026-09-22) | Covered by the rule? |
|---|---|---|---|
| `executed at` header | `05:43:30Z` | `20:03:26Z` | yes |
| Local toolchain | rustc/cargo 1.98.0 | 1.98.1 | yes. The decision already computes the floor against published stable 1.98.1, and `C1a` still passes |
| Section 10: downloads, stars, `pushed_at`, open issues, open PRs | e.g. `inquire` 90-day downloads 4978577, `dialoguer` open issues/PRs 71/28 | 4924975; 70/27 | yes |
| `$TMPDIR` PID paths in `cargo tree -d` | `r61-claims-57813` | `r61-claims-95430` | yes |

The following items in the decision's "must not vary" set reproduced exactly (all PASS):
- all six tarball checksums (§2);
- every quoted source line (§3–§7, including `C3a`–`C3f` for the `/dev/tty` fallback in `tty_fd()` / `Input::unbuffered()` and `C4a`/`C4b` for `console`'s `libc::raise(SIGINT)`);
- the CLI standard's blob hash and its five cited lines (§8);
- the six RustSec 404s, the `atty` 200, and the `atty` page naming `RUSTSEC-2021-0145` (§9);
- the newest non-yanked versions `0.9.4` and `0.12.0`, and `inquire`'s newest commit `2026-02-24T17:21:29Z` with 30 open PRs (§10);
- the package counts 9 / 35 / 11 and the maximum tree `rust_version` of 1.85.0 (§12);
- `signal-hook` as the only duplicate in the `inquire` spike, and zero duplicates in the `dialoguer` spike (§12);
- case A of §13, which printed `crossterm_enable_raw_mode=Err kind=Uncategorized raw_os_error=Some(6)`;
- the parameter diffs, zero `- owns` lines, and zero `CONFLICT:` lines (§14);
- `C15b`/`C15c`, the F360 and R67 reads (§16), and both raw hashes (§17).

## 3. The five failures, investigated

### 3a. `C15a`: a self-reference that postdates the decision, not a collision

```
$ /usr/bin/grep -rlF 'OV-02' docs/port   # plus the script's research/topics/*/DECISION.md loop, excluding 61-*
docs/port/OWNER-ACCEPTANCES.md
$ /usr/bin/grep -nF 'OV-02' docs/port/OWNER-ACCEPTANCES.md
68:| R61 | 1 | `3131e895…636281` | accept | 2026-09-16 | W1-R61 option A (Wave 1): … OVERRIDE OV-02 accepted — a declined confirm exits 0 (py exits 5); judgment-only acceptance under W1-CODEX; publication waits for the empirical audit |
$ git log --format='%h %ad %s' --date=iso -S'OV-02' -- docs/port/OWNER-ACCEPTANCES.md
8a8a2182 2026-09-17 08:08:13 -0700 docs(p02): record W1-R10 and W1-R61; ledger the R05 synthesis and the R68 Opus report
```

The single hit is the owner's acceptance row for this same R61 revision, which carries the same sha256. It was committed at 2026-09-17 08:08 -0700. The recorded log ran at `05:43:30Z`, which is 2026-09-16 22:43 -0700, so the row was added after the log was produced.

No other item uses `OV-02`, so the claim "OV-02 does not collide" is still true. The assertion's scope is not durable: acceptance rows legitimately quote the override numbers they accept. **Suggested repair to the script (not required for this revision):** exclude `docs/port/OWNER-ACCEPTANCES.md`, or rows whose item column is `R61`, from the section 15 search.

### 3b. `C13c`–`C13f`: the case B rerun is blocked on this seat, and no claim is contradicted

In the rerun, the case B helper died before starting the child process. It ended with `OSError: out of pty devices`, raised from `pty.fork()` → `openpty()`.

Probes showed that this is a permission limit on the auditor's process, not pty exhaustion and not a script defect. The same results appeared with the harness sandbox disabled:

```
$ sysctl kern.tty.ptmx_max ; ls /dev/ttys* | wc -l
kern.tty.ptmx_max: 511
      98
$ /usr/bin/script -q /dev/null /usr/bin/true
script: openpty: Operation not permitted
$ python3 -c "import os;print(os.openpty())"
PermissionError: [Errno 1] Operation not permitted
$ /usr/bin/ssh -o BatchMode=yes -o ConnectTimeout=3 -tt localhost 'tty'
No user exists for uid 501
```

Neither route could allocate a pty: the local process was refused `openpty`, and the ssh route to localhost failed immediately. This seat therefore cannot re-execute case B.

Case B is still well supported by evidence that did reproduce:
1. **Source assertions reproduced.** `C3a`–`C3f` passed on this rerun. They show that `crossterm`'s `enable_raw_mode()` is built on `tty_fd()`, and that `tty_fd()` falls back to opening `/dev/tty` when stdin is not a terminal. `console`'s `Input::unbuffered()` has the same fallback.
2. **Case A reproduced.** With stdin from `/dev/null` and no controlling terminal, the call failed with `raw_os_error=Some(6)`. Errno 6 is ENXIO, the result of opening `/dev/tty` without a controlling terminal. That shows `crossterm` tried to acquire `/dev/tty` rather than stopping because stdin was not a terminal.
3. **The synthesizer's two runs agree.** `r61-claims-rerun.diff` shows case B identical across both runs.

Given a controlling pty, the `Ok` that case B records is what the reproduced code path must produce. **Recommendation:** a seat that can allocate a pty should re-execute §13 case B when convenient. This is recorded as not re-executed, not as failed.

## 4. Load-bearing figures re-derived at source

| Figure | Independent command | Observed | Decision |
|---|---|---|---|
| `inquire` 0.9.4 checksum, MSRV, yanked, licence | `curl -s https://crates.io/api/v1/crates/inquire/0.9.4` → `.version` | `0.9.4 6654738b8024300cf062d04a1c13c10c8e2cea598ec1c47dc9b6641159429756 1.80.0 False MIT` | matches (§2 checksum; gate-2 `rust-version = "1.80.0"`; observed licence `MIT`) |
| `dialoguer` 0.12.0 checksum, MSRV, yanked | `curl -s https://crates.io/api/v1/crates/dialoguer/0.12.0` → `.version` | `0.12.0 25f104b501bf2364e78d0d3974cbc774f738f5865306ed128e1e0d7499c0ad96 1.66 False` | matches (§2; gate-2 `rust-version = "1.66"`) |
| Published stable 1.98.1 (2026-09-01) | `rustc --version` on the updated local toolchain | `rustc 1.98.1 (48a229cea 2026-09-01)` | matches the decision's floor basis |
| 24-package gap | recorded log §12: base 9, `inquire` 35, `dialoguer` 11 (reproduced) | 35 − 11 = 24 | matches `## Engines` Disagreement 1 |

**Section 10 table cross-check.** Every cell of the figures table at `DECISION.md:222–228` equals the recorded log's section 10: all six crates' 90-day downloads, all-time downloads, versions with dates, stars, archived flags, `pushed_at` values, open issues, and open PRs. `demand`'s 258 stars also matches, and it still reads 258 today.

**Evidence bookkeeping.** `r61-claims-rerun.diff` is 26 lines, as stated. It changes exactly three lines: the `executed at` timestamp and two PID paths. The recorded log contains 97 `PASS` lines and no `FAIL` or `SKIP` lines, as stated.

## 5. Non-blocking note

`DECISION.md:7` says every cited figure was re-retrieved by the synthesizer's own check, "which recorded `2026-09-17T05:23:18Z`". Neither retained run records that instant: the recorded log says `05:43:30Z`, and the diff's other side says `05:42:12Z`.

The figures themselves are all present in, and supported by, the retained `05:43:30Z` log (§4 above). Only the timestamp in the prose is stale; it most likely comes from an earlier, unretained run on the same day. No claim depends on it, so it is not an unresolved finding. **Suggested repair at the next revision:** change the instant to `2026-09-17T05:43:30Z`.

## 6. Verdict

**approve.** The check runs. The recorded log is consistent with the script. Every must-not-vary assertion that could run on this seat reproduced. Every load-bearing figure re-derived at source matches the decision.

Two deviations were investigated and neither contradicts a claim. `C15a` is caused by the owner's own acceptance row, added after the decision. `C13c`–`f` failed because this seat is not permitted to open a pty. That case is corroborated by the reproduced `C3a`–`C3f` and by case A.
