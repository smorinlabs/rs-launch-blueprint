actor: audit-claude-2026-09-17T020714Z-98ef5e1e7d37-r2
model: claude-opus-5-5
family: anthropic
decision-sha256: 3e4e126cc0ffdba61a7e2368dec0183414e3f3908a7316ffc4ccdc550d18da9a
verdict: approve
unresolved-findings: none

# R61 interactive-prompts — empirical audit of DECISION.md revision 2

**Seat.** This audit ran on the Claude seat, as the approved fallback while the OpenAI provider is quota-paused (method amendment Q8.B). It is not a Codex audit. The auditor is a fresh context and did not read `review/audit-claude.md`, `review/audit-fable.md`, `review/audit-fable.r2.md`, `review/R61-r1-snapshot.md`, or `research/topics/61-*/raw/`.

**Scope.** Execution truth and evidence support only: do the commands run, does the log match the claims, and are the figures right. The recommendation's merit is not judged here.

**Audit instant.** 2026-09-23T05:27Z (UTC); 2026-09-22 Pacific. Machine: `Darwin arm64`, macOS 26.4, `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`.

## 1. Decision identity

```
$ shasum -a 256 research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/DECISION.md
3e4e126cc0ffdba61a7e2368dec0183414e3f3908a7316ffc4ccdc550d18da9a  …/review/DECISION.md
```

This matches the expected hash, so the audit proceeded. Revision 1's hash `3131e895…6281`, named in the revision-2 note, is corroborated without reading the forbidden snapshot: `docs/port/OWNER-ACCEPTANCES.md:68` records that exact hash against R61 revision 1 (`/usr/bin/grep -c` of the hash in that file returns `1`).

## 2. Rerun of the empirical check

Command, working directory `research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/evidence`. Output went to `/tmp`, so the committed log was not overwritten:

```
$ bash r61-claims.sh > /tmp/r61-audit-rerun.log 2>&1 ; echo "exit=$?"
exit=0
$ tail -2 /tmp/r61-audit-rerun.log
TOTAL  pass=93  fail=0  skip=4
```

The only `FAIL`/`SKIP` lines are `SKIP C13c`, `SKIP C13d`, `SKIP C13e` and `SKIP C13f`. This matches the decision's claim for revision 2: "`exit=0` — 93 pass, 0 fail, 4 skip".

**Comparison with the committed log.**

```
$ diff r61-claims.log /tmp/r61-audit-rerun.log
4c4     executed at   : 2026-09-23T05:14:20Z  →  2026-09-23T05:23:49Z
310c310 …/T/r61-claims-99037/spike-a  →  …/T/r61-claims-87834/spike-a
315c315 …/T/r61-claims-99037/spike-a  →  …/T/r61-claims-87834/spike-a
$ diff <(grep -E '^(PASS|FAIL|SKIP)' r61-claims.log) <(grep -E '^(PASS|FAIL|SKIP)' /tmp/r61-audit-rerun.log)
(no output — assertion lines identical)
```

Three lines differ. All three are in the decision's "varies by design" list: the timestamp, and the two `$TMPDIR` paths that carry the script's PID. None of the 97 assertion lines differs.

**`review/evidence/r61-claims-rerun.diff`.** `wc -l` reports 36 lines, as claimed. The file is in unified format. Reading it shows five changed lines: `run directory`, `executed at`, two `$TMPDIR` spike paths, and section 14's `generated from`. This matches the decision's "five lines changed" and its explanation that one run was in a `/tmp/r61-arch` extraction.

**Script hygiene.** `shellcheck r61-claims.sh` (`/Users/stevemorin/.local/bin/shellcheck`) exits `0` with no output, which confirms the "shellcheck-clean" claim.

## 3. The four case-B SKIPs are environmental

**The seat is refused a pseudo-terminal, both inside and outside the sandbox.**

```
$ python3 -c 'import os; os.openpty()'      # sandboxed shell
errno 1 Operation not permitted
$ python3 -c 'import os; os.openpty()'      # dangerouslyDisableSandbox=true
errno 1 Operation not permitted
$ script -q /dev/null true
script: openpty: Operation not permitted     (exit 1)
$ ls -la /dev/ptmx
crw-rw-rw-  1 root  tty  0xf000056 … /dev/ptmx
```

`/dev/ptmx` exists and is world-writable, yet `openpty` returns `EPERM` even with the tool sandbox disabled. Case B therefore cannot run on this seat. The skip is not one that "could run here".

**The skip path is narrow.** In `r61-claims.sh` section 13, the Python probe prints `pty_unavailable errno=<n>` and exits 3 only when `os.openpty()` raises. The script skips only when the output contains the fixed string `pty_unavailable errno=1 ` (errno 1 is `EPERM`). Any other outcome, including another errno, falls to the `else` branch, which runs `assert_contains` for C13c–C13f and can fail. The rerun log shows the probe's line `pty_unavailable errno=1 (Operation not permitted)` immediately before the four SKIPs.

**The fallback evidence the SKIP message names is real.**

- `C3a`–`C3f` pass in this rerun. They assert that `crossterm`'s `tty_fd()` and `console`'s `Input::unbuffered()` open `/dev/tty` when stdin is not a terminal, and that `enable_raw_mode()` is built on `tty_fd()`.
- `C13a`/`C13b` (case A) pass in this rerun. The observed line is `crossterm_enable_raw_mode=Err kind=Uncategorized raw_os_error=Some(6)`, which matches the decision's "`raw_os_error = Some(6)`".
- `r61-claims-r1.log` is byte-identical to `git show da52246c:…/review/evidence/r61-claims.log` (`cmp` silent). Its header reads `executed at   : 2026-09-17T05:43:30Z (UTC)`, which confirms the corrected instant in the decision's `**Dates.**` paragraph. That log shows case B executed with `stdin_is_terminal=false`, `dialoguer_guard_term_stderr_is_term=true`, `crossterm_enable_raw_mode=Ok  (a terminal was acquired)` and `child_exit_status=0`, with C13c–C13f passing and `TOTAL  pass=97  fail=0  skip=0`. These are exactly the case-B values the decision cites.

**Limit.** Case B was not re-executed by this auditor, because the seat cannot allocate a pty. The case-B observation therefore rests on the retained revision-1 log plus the passing source assertions. The decision states this limit openly and asks a pty-capable seat to re-run case B.

## 4. The narrowed C15a scope still catches real collisions

**Method.** The section 15 counting block (from `OVDIRS=""` through the `OVCOUNT=` line) was extracted verbatim from `r61-claims.sh` into `/tmp/r61-c15-audit/run.sh`. It ran against scratch copies of `docs/port/` and every `research/topics/*/DECISION.md`, with one collision injected per test.

| Test | Injected change | `OVCOUNT` | Expected |
|---|---|---|---|
| baseline | none (only the live R61 row at `OWNER-ACCEPTANCES.md:68` quotes OV-02) | 0 | 0 |
| T1 | an `OWNER-ACCEPTANCES.md` row for **R62** quoting `OV-02` | 1 (`OWNER-ACCEPTANCES.md`) | caught |
| T2 | `OV-02` appended to `docs/port/OWNER-REVIEW.md` | 1 | caught |
| T3 | `OV-02` appended to `research/topics/01-ports-and-adapters-seam/DECISION.md` | 1 | caught |
| T4 | `OV-02` in a `research/topics/61-…/DECISION.md` (R61's own item) | 0 | excluded by design |
| T5 | `OV-02` in a new file `docs/port/sub/x.md` | 1 | caught |

The exclusion is exactly as narrow as the revision-2 note claims. Only `OWNER-ACCEPTANCES.md` lines matching `^\| R61 \|` and R61's own topic decision are excluded. Another item's acceptance row (T1) still counts. The live repository has one `OV-02` mention across `docs/port/` and the topic decisions: `OWNER-ACCEPTANCES.md:68`, which is R61's own acceptance row. The rerun's `PASS C15a … [= 0]` therefore reflects no real collision.

## 5. Figures re-derived at source

| Claim in the decision | Re-derivation | Result |
|---|---|---|
| `inquire` 0.9.4 checksum `6654738b…9756` | `GET https://crates.io/api/v1/crates/inquire/0.9.4` → `version.checksum` | `6654738b8024300cf062d04a1c13c10c8e2cea598ec1c47dc9b6641159429756` — matches |
| `dialoguer` 0.12.0 checksum `25f104b5…ad96` | same endpoint for `dialoguer/0.12.0` | `25f104b501bf2364e78d0d3974cbc774f738f5865306ed128e1e0d7499c0ad96` — matches |
| RustSec: 404 for the candidates, 200 for the `atty` control naming `RUSTSEC-2021-0145` | `curl -w '%{http_code}'` on `https://rustsec.org/packages/<n>.html` | `inquire 404`, `dialoguer 404`, `atty 200`; the `atty` body contains `RUSTSEC-2021-0145` (2 matches) |
| Tree maximum `rust_version` 1.85.0 comes from `unicode-segmentation`, not `inquire` | crates.io `rust_version` for `inquire` 0.9.4 | `1.80.0`, consistent with the claim |
| Package counts 9 / 35 / 11; the "24-package gap" | rerun section 12 | `spike-base: 9`, `spike-a: 35`, `spike-b: 11`; 35 − 11 = 24 |
| CLI standard blob hash `9fb05d3d…463f`, 773 lines | rerun section 8 | `9fb05d3dfaa5ea11fbf66422e988b0ae8c050e22a39b9fc6dd9688734f02463f, 773 lines` |
| `inquire` newest commit `2026-02-24T17:21:29Z`, 30 open PRs | rerun section 10 | `2026-02-24T17:21:29Z`; `open PRs=30` |
| Zero files under `inquire-0.9.4/src` mention `stdout` in any case | rerun section 5 | `0`, `PASS C5f` |
| Revision-2 toolchain `rustc 1.98.1` / `cargo 1.98.1` | header of `r61-claims.log` | `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1` — matches the toolchain paragraph |

All re-derived figures agree with the decision.

## 6. Non-blocking observation (not an unresolved finding)

- **Stale table cell.** In `## Empirical check`, the "What the check establishes" table row for § 1 still reads "`rustc 1.98.0`, `cargo 1.98.0`". The table header cites `review/evidence/r61-claims.log`, and that log (revision 2) records `rustc 1.98.1` and `cargo 1.98.1`. The cell describes the revision-1 run. This is not a false figure: the **Toolchain and platform** paragraph directly above the table states that the revision-2 rerun ran on `rustc 1.98.1` / `cargo 1.98.1`, and assertion `C1a` checks only for the 1.9x series. No recommendation, figure or assertion depends on the cell. It is recorded so that a later revision can refresh the cell; it does not block acceptance.

## Verdict

**approve.** The check reruns with `exit=0` and `TOTAL  pass=93  fail=0  skip=4`, as claimed. The rerun differs from the committed log only in the fields the decision declares volatile. The four SKIPs are genuinely environmental: `openpty` returns `EPERM` on this seat even outside the tool sandbox, the skip condition is limited to that errno, and the named fallback evidence passes or is retained byte-for-byte in git. The narrowed `C15a` still catches every injected collision except R61's own rows. Every figure re-derived at source matches.
