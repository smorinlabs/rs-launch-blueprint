actor: audit-claude-2026-09-17T020714Z-98ef5e1e7d37-r6
model: claude-opus-5-5
family: anthropic
decision-sha256: 1ecf07f26d946e98c77a20d020fcd094ea0b53362965e7406cb313ac3d053c0c
verdict: approve
unresolved-findings: none

# R61 interactive-prompts — empirical audit of DECISION.md revision 6

**Seat.** Claude seat (Anthropic, `claude-opus-5-5`), running as the approved fallback for the empirical auditor while the OpenAI provider is quota-paused (method amendment Q8.B). This is not a Codex audit. It is independent of the synthesizer and of the judgment auditor. I read no `review/audit-fable*.md`, no `review/audit-claude*.md` below r6, no `review/R61-r*-snapshot.md`, and nothing under `research/topics/61-*/raw/`.

**Scope.** This audit judges execution truth and evidence support only: whether the commands run, whether the logs match the claims, and whether the cited figures are right. It does not judge whether the recommendation is wise.

**Result.** The empirical check reproduces: exit `0`, 109 pass, 0 fail, 4 skip. The four SKIPs (`C13c`–`C13f`) are genuinely environmental, and their fallback evidence is honest. Every load-bearing figure I re-derived at source matches. No finding blocks approval.

## 1. Target identity

```
$ shasum -a 256 research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/DECISION.md
1ecf07f26d946e98c77a20d020fcd094ea0b53362965e7406cb313ac3d053c0c  …/review/DECISION.md
```

This matches the expected hash, so the audit proceeded.

## 2. Rerun of the empirical check

The script writes only under `$TMPDIR/r61-claims-$$` and removes that directory in its `EXIT` trap. I therefore ran it in place and sent its output to `/tmp` so that the retained log was not overwritten. `git status --porcelain` on the evidence directory was identical before and after the run.

```
$ cd research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/evidence
$ bash r61-claims.sh > /tmp/r61-audit6/run1.log 2>&1 ; echo "exit=$?"
exit=0
$ tail -3 /tmp/r61-audit6/run1.log
================================================================
TOTAL  pass=109  fail=0  skip=4
================================================================
```

The run executed at `2026-09-23T12:28:08Z` (UTC) on `rustc 1.98.1` / `cargo 1.98.1`, Darwin arm64.

**Comparison with the retained `r61-claims.log`** (`executed at 2026-09-23T10:44:13Z`), using `diff r61-claims.log /tmp/r61-audit6/run1.log`:

- The PASS/FAIL/SKIP label and assertion ID lists are identical: 109 `PASS` lines in each file, and the same four SKIP IDs.
- The only lines that differ belong to the decision's "varies by design" list:
  - the `executed at` timestamp;
  - the six all-time `downloads` figures in section 10 (the `recent_downloads(90d)` figures did not change);
  - `ast-grep/ast-grep` stars, `16006` → `16009`;
  - `crossterm-rs/crossterm` open PRs, `78` → `79`;
  - the two `$TMPDIR` paths inside the `cargo tree -d` output.
- No line from the decision's "must not vary" list changed.

## 3. The four case-B SKIPs are genuinely environmental

- **The script's condition is narrow.** In `r61-claims.sh`, section 13's Python helper first probes `os.openpty()`. If the probe raises, the helper prints `pty_unavailable errno=<n>` and exits `3`. The shell records `C13c`–`C13f` as SKIP only when the output contains the fixed string `pty_unavailable errno=1 `. Any other outcome, including a different errno, runs the four assertions, and those assertions can fail. This matches the decision's claim.
- **My run hit exactly that condition.** Log line 336 reads `pty_unavailable errno=1 (Operation not permitted)`.
- **Independent probe on this seat:** `python3 -c 'import os; os.openpty()'` printed `openpty errno 1 Operation not permitted`. The refusal is real and belongs to the seat, not the script.
- **The fallback evidence is honest.**
  - `C3a`–`C3f` passed in my run. These checks cover the `/dev/tty` fallback in `crossterm`'s `tty_fd()` and in `console`'s `Input::unbuffered()`, and the fact that `enable_raw_mode()` is built on `tty_fd()`.
  - `C13a` and `C13b` (case A: `raw_os_error=Some(6)`, `ENXIO`) passed in my run.
  - The r1 log that the SKIP text cites is byte-identical to its committed form. `git show da52246c:…/r61-claims.log | shasum -a 256` and `shasum -a 256 r61-claims-r1.log` both give `154abce209c78953cc560d04d91426ab3a4678abfe343e25ffde2b16b914829a`.
  - That log records case B actually executing, at lines 336–344: `stdin_is_terminal=false`, `dialoguer_guard_term_stderr_is_term=true`, `crossterm_enable_raw_mode=Ok  (a terminal was acquired)`, and `PASS C13c`–`C13f`.
- **Limit.** Case B was not re-executed on this seat, and it cannot be. The decision already states this and asks a pty-capable seat to re-run case B. The claim therefore rests on the r1 execution plus the source reads, as the decision says.

## 4. Log-history and rerun-diff claims under `## Empirical check`

| Claim | Observed | Match |
|---|---|---|
| r1 `05:43:30Z`, 97/0/0 | `r61-claims-r1.log`: `2026-09-17T05:43:30Z`, `pass=97 fail=0 skip=0` | yes |
| r3 `06:05:39Z`, r4 `06:59:22Z`, r5 `07:31:45Z`: each 109/0/4 | the headers and `TOTAL` lines of `r61-claims-r3.log`, `-r4.log` and `-r5.log` | yes |
| r6 `10:44:13Z`, 109/0/4 | `r61-claims.log` | yes |
| `r61-claims-rerun.diff`: 36 lines; five lines changed (timestamp, two `$TMPDIR` paths, `run directory`, `generated from`); 350 s apart | `wc -l` gives 36; the diff has 5 `-` and 5 `+` content lines, exactly those five fields; the two timestamps are `10:44:13Z` and `10:50:03Z`, 350 s apart | yes |
| r5 → r6 worktree log differs only in the timestamp, the two `$TMPDIR` paths, `ast-grep` 16,004→16,006 and `cliclack` 369→370 | `diff r61-claims-r5.log r61-claims.log` shows exactly those five changes | yes |

## 5. Load-bearing figures re-derived at source

| Figure in the decision | How I re-derived it | Result |
|---|---|---|
| Raw hashes: `a22fcc08…2e` (Codex) and `162d21ed…a7` (Opus) | `shasum -a 256 raw/codex.md raw/opus.md` | both match |
| Like-for-like tree sizes 9 / 35 / 11; "24-package gap"; max `rust_version` 1.85.0 | my rerun, section 12 (`C12a`–`C12c`); 35 − 11 = 24 | match |
| `inquire` newest commit `2026-02-24T17:21:29Z`; 30 open PRs | my rerun, section 10 (`C10d`) | match |
| py pin `b08bccfb`: `CONFIG = 1`, `AUTH = 2`, `INTERRUPT = 5`, `PLBP004`; `ConfigError.exit_code = ExitCode.CONFIG` (`errors.py:41-42,45,55,79-82`) | `git -C ../py-launch-blueprint show b08bccfb:src/py_launch_blueprint/core/errors.py` | lines read as cited |
| py `config.py:82-83` (`if assume_yes: chosen = current`), `:94` (`click.prompt`), `:101` and `:181` (`if dry_run:`), `:184` (`return`), `:196` (`and not confirm(`) | `git show b08bccfb:…/cli/commands/config.py` at those lines | lines read as cited |
| ts pin `cb1cbcb2`: `projects.ts:147` computes the three-input conjunction; `:164-166` is `} else {` / `selected = projects;` / `}` | `git -C ../ts-launch-blueprint show cb1cbcb2:src/commands/projects.ts` | lines read as cited |
| `C15a`: `OV-02` appears in no other published decision or port document | `/usr/bin/grep -rlF 'OV-02' docs/port research/topics/*/DECISION.md`, excluding topic 61. The only hit is `docs/port/OWNER-ACCEPTANCES.md:68`, whose item column is `R61`. That is the documented exclusion. `C15a` passed in my rerun | match |

Also confirmed by assertion in my rerun: the six tarball checksums against the crates.io `version.checksum` values (section 2), the CLI standard blob hash and its cited lines (`C8a` and the other section-8 checks), the six RustSec 404s alongside the `atty` 200 control naming `RUSTSEC-2021-0145` (section 9), and section 18's three executed py-pin cases: `config set --dry-run --no-input` exits `0`, the control exits `1`, and `config init --dry-run --no-input` exits `1`.

## 6. Non-blocking observations

- **Section-10 figures keep moving.** The `ast-grep` star count (16,009 in my run) and the other section-10 figures continue to drift. The decision classifies these as volatile and does not rest a ranking on their exact values, so this is expected drift, not a defect.
- **The worktree evidence is not yet committed.** In this worktree, `r61-claims.log`, `r61-claims.sh` and `r61-claims-rerun.diff` are modified but uncommitted. `r61-claims-r1.log`, `-r3.log`, `-r4.log` and `-r5.log` are untracked. This audit ran against the on-disk bytes, and the decision hash above binds only `DECISION.md`. The publisher must stage these evidence files exactly as they are on disk.
