# R61 — empirical audit of DECISION.md revision 3

actor: audit-claude-2026-09-17T020714Z-98ef5e1e7d37-r3
model: claude-opus-5-5
family: anthropic
decision-sha256: 1310e0c4d6ccafd9126bc396ca138b3822dfeb0fc1e3a9365d75851df1573346
verdict: approve
unresolved-findings: none

## Seat and scope

- This audit ran on the Claude seat, as the approved fallback while the OpenAI provider is quota-paused (method amendment Q8.B). It is not a Codex audit.
- It judges execution truth and evidence support only: whether the commands run, whether the logs match the claims, and whether the figures are right. It does not judge whether the recommendation is wise.
- It did not read `review/audit-fable*.md`, `review/audit-claude.md`, `review/audit-claude.r2.md`, `review/R61-r*-snapshot.md` or `research/topics/61-*/raw/`.
- It made no git writes, ran no `scripts/research_runner.py` command, and made no paid or submitting API call. All scratch output went under `/tmp`.
- Seat state during the audit: `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, macOS on Darwin arm64, and py venv `Python 3.12.12`.
- Run date: 2026-09-23T06:34:19Z (UTC), which is 2026-09-22 Pacific.

## 1. Target identity

```
$ shasum -a 256 research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/DECISION.md
1310e0c4d6ccafd9126bc396ca138b3822dfeb0fc1e3a9365d75851df1573346  …/review/DECISION.md
```

This equals the expected revision-3 hash. The evidence files at audit time hashed as follows:

- `r61-claims.sh`: `f5aeba20d3a99d98c8082a55fcf92c61d7f38a42920126ebd5883a2a64954360`
- retained `r61-claims.log`: `b44d04b187956aae438ee4ed1c29823e3f0b03e8742852d99ffc897c0c00c80f`

The retained log hashed the same before and after the rerun, so the rerun did not touch it.

## 2. Rerun of the empirical check

```
$ cd research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/evidence
$ bash r61-claims.sh > /tmp/r61-audit-r3.log 2>&1 ; echo "exit=$?"
exit=0
TOTAL  pass=109  fail=0  skip=4
```

This matches the claim: 109 pass, 0 fail, 4 skip, exit 0. The script exits with its failure count, so `exit=0` means zero failed assertions. There are no `FAIL` lines. The only `SKIP` lines are `C13c`–`C13f`.

`diff r61-claims.log /tmp/r61-audit-r3.log` produced 26 lines, and every difference is in a field the decision lists as "varies by design":

- the `executed at` header (`06:05:39Z` → `06:34:19Z`);
- the six section-10 `recent_downloads` / `downloads` lines;
- the two `$TMPDIR` PID paths inside `cargo tree -d` (`r61-claims-36083` → `r61-claims-29283`).

Nothing in the decision's "must not vary" list differed, and section 18 is byte-identical.

The retained `r61-claims-rerun.diff` also matches its description. It has 53 lines including headers and exactly 10 changed lines:

- the timestamp (`06:05:39Z` → `06:06:54Z`, 75 s apart);
- `run directory` and section 14's `generated from`, both pointing into the `/tmp/r61-arch3` extraction;
- the two `$TMPDIR` paths;
- the all-time `downloads` figures for `inquire`, `dialoguer`, `crossterm`, `console` and `cliclack`.

## 3. The four case-B SKIPs are genuinely environmental

The script (`r61-claims.sh`, section 13) skips only when `tty-b.txt` contains `pty_unavailable errno=1 `. Any other outcome, including another errno, falls through to the four real assertions. My rerun log shows the probe output `pty_unavailable errno=1 (Operation not permitted)` before the SKIP lines.

I confirmed the refusal independently of the script:

```
$ python3 -c 'import os; os.openpty()'      -> openpty errno 1 Operation not permitted
$ script -q /dev/null true                  -> script: openpty: Operation not permitted (exit 1)
```

The system's own `/usr/bin/script` is refused a pty too. The refusal belongs to this seat's sandbox and is not an artifact of the script.

The fallback evidence is honest:

- **`C3a`–`C3f` pass in my rerun.** These assert the `/dev/tty` fallbacks in `crossterm`'s `tty_fd()` and `console`'s `Input::unbuffered()`.
- **Case A (`C13a`/`C13b`) passes in my rerun.** The observed output is `stdin_is_terminal=false`, `dialoguer_guard_term_stderr_is_term=false`, `crossterm_enable_raw_mode=Err kind=Uncategorized raw_os_error=Some(6)`.
- **The revision-1 log records case B actually executing.** `r61-claims-r1.log` has `stdin_is_terminal=false`, `stderr_is_terminal=true`, `dialoguer_guard_term_stderr_is_term=true`, `crossterm_enable_raw_mode=Ok  (a terminal was acquired)`, `child_exit_status=0`, and `PASS C13c`/`C13d`/`C13e`.
- **The revision-1 log is authentic.** `git show da52246c:…/evidence/r61-claims.log | shasum -a 256` gives `154abce2…829a`, identical to the working-tree `r61-claims-r1.log`. That is the commit the SKIP reason cites (`da52246c fix(research): correct the R61 demand checksum and harden two R61 checks`).

The decision's section-13 row says case B was executed in revision 1 and SKIPped on this seat in revisions 2 and 3. That is accurate. U-list re-execution on a pty-capable seat is correctly requested.

## 4. The new `--dry-run` acceptance case executes the claimed behaviour

The script's section 18 passes `C18a`–`C18p` in my rerun. I then re-executed the cases by hand, outside the script, against a fresh `git archive b08bccfb55d05f15e46a83b52c5660b1881d19f5` extraction under `/tmp/r61-aud3/py`. I used the py venv's `plbp` with `env -i HOME=… PATH=/usr/bin:/bin PYTHONPATH=/tmp/r61-aud3/py/src`. Each case started from a config file containing `output.color = "never"`.

| Case | Exit | Config file | stderr |
|---|---|---|---|
| `config set output.color always --dry-run --no-input` | `0` | unchanged | ` would set output.color = always in …` |
| `config set output.color always --no-input` (control) | `1` | unchanged | `Error: refusing to proceed without confirmation (--no-input): Overwrite output.color (never → always) … (PLBP001)` |
| `config init --dry-run --no-input` | `1` | unchanged | `Error: config init cannot prompt (--no-input set) (PLBP001)` |
| `config set output.color always --yes --no-input` (my extra positive control) | `0` | **changed** to `color = "always"` | — |

The positive control shows that the "unchanged" results are real no-writes and not a harness that cannot write.

The imported module was `/tmp/r61-aud3/py/src/py_launch_blueprint/cli/commands/config.py`, the extraction and not an installed copy. This agrees with `C18f`.

The cited source lines of the extracted `config.py` read exactly as the decision quotes them:

- `:94` `chosen[dotted] = click.prompt(`
- `:101` `if dry_run:`
- `:181` `if dry_run:`
- `:182` `app.renderer.message(f"[dry-run] would set …")`
- `:183` `app.renderer.render(ConfigValue(…, source="dry-run"))`
- `:184` `return`
- `:196` `and not confirm(`

For `config set`, `--dry-run` therefore returns before the confirm. For `config init`, the guided prompt is refused before `--dry-run` is read. This is the per-command order that revision 3 states.

The observation that `rich` consumes the `[dry-run]` prefix is also true: the stderr line begins with a space and has no `[dry-run]` text.

## 5. Load-bearing figures re-derived at source (outside the script)

- **Raw hashes.** `raw/codex.md` hashes to `a22fcc08…2e`, and `raw/opus.md` hashes to `162d21ed…a7`. Both equal the values in the decision.
- **Tarball checksum.** For `inquire` 0.9.4, the crates.io API `version.checksum` and the sha256 of the downloaded `static.crates.io` tarball both equal `6654738b8024300cf062d04a1c13c10c8e2cea598ec1c47dc9b6641159429756`.
- **RustSec control.** `rustsec.org/packages/inquire.html` returns 404 and `…/dialoguer.html` returns 404. `…/atty.html` returns 200, and `RUSTSEC-2021-0145` appears on 2 lines of its body (`grep -c`).
- **Revision-1 retrieval instant and toolchain.** The header of `r61-claims-r1.log` reads `executed at   : 2026-09-17T05:43:30Z (UTC)`, `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)` and `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`. These match the decision's `**Dates.**` instant and its section-1 toolchain line for revision 1.
- **Target still current at hand-off.** I recomputed the `DECISION.md` sha256 after writing this audit, and it was unchanged at `1310e0c4…1573346`.
- **OV-02 collision count.** `/usr/bin/grep -rlF 'OV-02' docs/port/ research/topics/*/DECISION.md` hits only `docs/port/OWNER-ACCEPTANCES.md`. Its sole matching line is 68, whose item column is `R61`. That is R61's own acceptance row, which `C15a` excludes by design, so the count of 0 is correct.
- **F360.** `docs/port/BASELINE-REVIEW.md` has 0 rows whose first column is `F360`. `docs/port/COMMONALITY.md:364` lists F360 as `DIVERGENT`, owned by `R61`.
- **Rerun figures that equal the decision's section table:**
  - 6/6 checksums;
  - CLI standard blob sha256 `9fb05d3d…463f`, 773 lines;
  - 0 `stdout` files under `inquire-0.9.4/src`;
  - package counts 9 / 35 / 11, with a max `rust_version` of 1.85.0 (`unicode-segmentation`);
  - `inquire` newest commit `2026-02-24T17:21:29Z`, 30 open PRs;
  - rerun toolchain `rustc 1.98.1`.

## Non-blocking observation (not a finding)

The claim is true, but it is incomplete about stdout. Under `config set --dry-run`, py also renders a `Key/Value/Source` table on **stdout**, with the `Source` column reading `dry-run`. Section 18's log shows this table, and my hand run captured 406 bytes of it.

The decision says "the preview on stderr". That statement is correct, and nothing in revision 3 claims py's stdout is empty. Criterion 10 constrains rs, not py. No repair is required.

## Verdict

**approve.** Every executed claim reproduces:

- the script exits `0` with 109 pass, 0 fail and 4 skip;
- the four SKIPs are a genuine `openpty` `EPERM` on this seat, with passing fallback evidence and a git-authenticated earlier execution of case B;
- the new `--dry-run` case behaves as claimed when re-executed independently against the pin;
- the re-derived figures equal the decision's.
