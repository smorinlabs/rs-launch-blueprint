actor: audit-claude-2026-09-17T020714Z-98ef5e1e7d37-r5
model: claude-opus-5-5
family: anthropic
decision-sha256: cd98f95e77add388bf04084ca0db496ead309cbce4124a3a45e30b03a30d7743
verdict: approve
unresolved-findings: none

# R61 empirical audit — revision 5

**Role.** Empirical auditor, fresh context, on the Claude seat. This seat is an approved fallback while the OpenAI provider is quota-paused (method amendment Q8.B). It is not Codex. This audit judges only execution truth and evidence support. It does not judge whether the recommendation is wise.

**Not read, as the task requires:** any `review/audit-fable*.md`; any `review/audit-claude*.md` below r5; `research/topics/61-*/raw/`; any `review/R61-r*-snapshot.md`. **Not done:** no git writes, no `scripts/research_runner.py` calls, no paid or submitting APIs. The script's own read-only public queries (crates.io, GitHub REST, rustsec.org, static.crates.io) ran as part of the rerun.

## 1. Target hash

```
$ shasum -a 256 research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/DECISION.md
cd98f95e77add388bf04084ca0db496ead309cbce4124a3a45e30b03a30d7743
```

This equals the expected hash, so the audit proceeded.

## 2. Rerun of the empirical check

Command, run from `review/evidence/`. The output went to `/tmp`, so the committed log was not overwritten:

```
bash r61-claims.sh > /tmp/r61a5-rerun.log 2>&1 ; echo "exit=$?"
```

Observed output (started `2026-09-23T07:45:06Z`):

```
exit=0
TOTAL  pass=109  fail=0  skip=4
```

- **Toolchain on this rerun:** `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, `Darwin arm64 / macOS 26.4`. This matches the decision's toolchain paragraph.
- **Assertion count:** there are 113 `PASS`/`FAIL`/`SKIP` lines with no duplicated check IDs, which matches the decision's "113 named assertions". Counts per section: C1 1, C2 6, C3 6, C4 2, C5 13, C6 4, C7 5, C8 7, C9 8, C10 5, C11 2, C12 9, C13 6, C14 6, C15 3, C16 8, C17 6, C18 16. The section-table counts under `## Empirical check` match: §3 six, §5 thirteen, §6 four, §8 seven, §18 `C18a`–`C18p`.
- **Repository untouched:** `git status --porcelain -- research/runs/R61` was identical before and after the rerun.
- **Exit semantics:** the script ends with `exit "$FAIL"`, so exit 0 means zero failed assertions. `shellcheck r61-claims.sh` (`~/.local/bin/shellcheck`) returned rc 0 with no output, which confirms "shellcheck-clean".
- **Sandbox note:** `ps` was refused by the sandbox (`operation not permitted`) while I checked progress. This has no bearing on any result.

**Diff of the rerun against the committed `review/evidence/r61-claims.log` (run at `2026-09-23T07:31:45Z`).** The diff has four hunks:

| Line | What changed | In the decision's vary-by-design set? |
|---|---|---|
| 4 | the `executed at` timestamp | yes |
| 273 | `fadeevab/cliclack` stars, 369 → 370 | yes (stars) |
| 310, 315 | the `$TMPDIR` PID path in the `cargo tree -d` output (`r61-claims-83573` → `r61-claims-39118`) | yes |

Nothing in the decision's must-not-vary list moved. That list covers the checksums, quoted source lines, section 18 exits and file hashes, the blob hash, the RustSec results, the versions, the commit date, the 9/35/11 package counts, the 1.85.0 MSRV, the single duplicate, the parameter diffs, the OV-02 count, the F360 count and the raw hashes.

## 3. Case B SKIPs (`C13c`–`C13f`)

- **The environmental cause is real on this seat.** I ran an independent probe: `python3 -c 'import os; m,s=os.openpty()'` → `PermissionError: [Errno 1] Operation not permitted`. The rerun log agrees: `pty_unavailable errno=1 (Operation not permitted)`.
- **The skip is narrow.** The script SKIPs only when `pty_unavailable errno=1 ` is present. Any other outcome runs the four assertions, and they can fail (script lines 468–483).
- **The fallback evidence passes in this rerun:**
  - `C3a`–`C3f` all PASS. They show that `crossterm`'s `tty_fd()` and `console`'s `Input::unbuffered()` open `/dev/tty` when stdin is not a terminal, and that `enable_raw_mode()` is built on `tty_fd()`.
  - `C13a` and `C13b` PASS. Case A printed `crossterm_enable_raw_mode=Err kind=Uncategorized raw_os_error=Some(6)`.
- **Revision 1's case B execution is genuine and preserved:**
  - `review/evidence/r61-claims-r1.log` lines 335–341 show `stdin_is_terminal=false`, `dialoguer_guard_term_stderr_is_term=true`, `crossterm_enable_raw_mode=Ok  (a terminal was acquired)` and `child_exit_status=0`, with `C13c`–`C13f` all PASS.
  - `git show da52246c:…/review/evidence/r61-claims.log` is byte-identical to `r61-claims-r1.log` (`diff` produced no output).
- **The decision is honest about the gap.** It labels case B as executed in revision 1 and skipped in revisions 2–5 because of `openpty` `EPERM`. It asks a pty-capable seat to re-run case B, and U5 records what remains unproven.

## 4. Rerun-and-diff claims under `## Empirical check`

- `review/evidence/r61-claims-rerun.diff` is 36 lines including headers, with 10 `-`/`+` body lines, which is five changed lines. They are exactly the ones the decision names:
  - the `run directory` path;
  - the `executed at` timestamp;
  - two `$TMPDIR` PID paths;
  - the section-14 `generated from` path.
- The two timestamps are `07:31:45Z` and `07:33:02Z`, which is 77 seconds apart, as stated.
- `diff r61-claims-r4.log r61-claims.log` shows only the timestamp, `ast-grep/ast-grep` stars 16005 → 16004, and the two PID paths, as stated.

## 5. Load-bearing figures re-derived at source

- **Registry and repository table under `## Decision`.** All six crates' downloads, versions and dates, the stars, `pushed_at`, open issues and open PRs match `r61-claims-r1.log` section 10 exactly. So does `ast-grep`'s 15,932. The decision attributes that table to the r1 run.
- **Current-rerun values of the must-not-vary figures:**
  - `C12a`/`C12b`/`C12c`: 9 / 35 / 11 packages;
  - `C12d`: MSRV 1.85.0;
  - `C10d`: newest `inquire` commit `2026-02-24`;
  - `C10e`: 30 open PRs;
  - `C5f`: zero `stdout` files;
  - `C8a`: blob hash `9fb05d3d…463f`;
  - `C15a`: OV-02 count 0;
  - `C16a`: F360 row count 0;
  - `C18g`/`C18j`: `config set --dry-run --no-input` exits 0, file unchanged;
  - `C18k`/`C18n`: py `ConfigError` exit 1.
- **Revision 5's new `errors.py` citation**, read with `git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/core/errors.py`. File line numbers: 41 `CONFIG = 1`; 42 `AUTH = 2`; 45 `INTERRUPT = 5`; 55 `ERROR_CODE_INTERRUPT = "PLBP004"`; 79 `class ConfigError(PyError):`; 82 `exit_code = ExitCode.CONFIG`. These support "`exit_code` is `ExitCode.CONFIG = 1` … where `2` is `AUTH`" and the OV-02 citation `errors.py:45,55`.
- **Two `config.py` citations that section 18 does not read**, checked at pin `b08bccfb`:
  - `:82-83` reads `if assume_yes:` / `chosen = current`.
  - `:193-203` is the `not confirm(…)` overwrite branch, ending `raise SystemExit(int(ExitCode.INTERRUPT))`.
  - Both read as cited.
- **`options.py:265-278`** is `confirm()`. Under `app.no_input` without `assume_yes` it raises `ConfigError("refusing to proceed without confirmation (--no-input): …", hint="pass --yes to confirm non-interactively")`, as cited.
- **ts pin `cb1cbcb2`:**
  - `src/commands/projects.ts:147` is `const interactive = opts.input !== false && deps.stdinIsTTY && deps.stderrIsTTY;`. This supports revision 5's corrected gate citation.
  - `:170-174` is the empty-selection no-op (`No projects selected` on stderr, then `return`), as cited.

## 6. Non-blocking observation (no repair required)

The F360 paragraph (DECISION.md line 102) cites `ts: src/commands/projects.ts:146,166-168` for ts's select-all behaviour, while line 66 cites `:147` for the gate. Line 146 is the comment stating that behaviour ("skips the prompt and selects all (D-016(6))"). The citation is therefore not wrong, only inconsistent with line 66. No figure or claim depends on it.

## Result

Every command I reran executed. The committed log reproduces, apart from fields the decision itself declares volatile. The four SKIPs are environmental on this seat, and the decision states them honestly with preserved fallback evidence. Every figure I re-derived matches its cited source. **Verdict: approve. Unresolved findings: none.**
