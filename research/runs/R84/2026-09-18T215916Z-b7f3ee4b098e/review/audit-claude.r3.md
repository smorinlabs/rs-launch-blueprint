actor: audit-claude-r84r3-s4w2
model: claude-opus-5-5
family: anthropic
decision-sha256: 9422d1d10c8a534c43b62d615d8a17f065bd889f1eb04244ca5d61d2b9b636d9
verdict: reject
unresolved-findings:
1. EF-1 — the `TOOL_VERSION=0.19.0` leg does not reproduce from the documented recipe (see Findings).
2. EF-2 — `r84-source-claims.sh` fails `A14` on the current working tree (see Findings).

# R84 revision 3 — empirical audit (Claude seat)

Scope: execution truth and evidence support only. The recommendation's wisdom is not
judged here. This auditor read no other audit, snapshot or `raw/` file.

## Target

- `research/runs/R84/2026-09-18T215916Z-b7f3ee4b098e/review/DECISION.md`, revision 3.
- `shasum -a 256` before any work: `9422d1d10c8a534c43b62d615d8a17f065bd889f1eb04244ca5d61d2b9b636d9`.
  This matches the expected hash. The same hash was recomputed after all reruns.
- Repository HEAD during the audit: `e0b0d1c1762ee8aa4b28c62282a2225103e594eb`.
- The `review/evidence/` tree was hashed file by file before and after the reruns. The two
  censuses are identical, so no committed evidence was overwritten.

## Host

`rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`,
rustup toolchain `1.96.0` present, `just 1.57.0`, `grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`,
Darwin arm64. `CARGO_HOME=/tmp/cargo-s4w2-R84-emp` (private). Runs started 2026-09-26 about
19:00 PDT, which is 2026-09-27 UTC.

One host difference matters. **This shell allows loopback TCP binds.** The synthesizer's shell
refused them. The probe's HTTP checks `R06`–`R10` therefore ran here instead of printing `SKIP`.

## Reruns

All volatile output went to `O=/tmp/r84-s4w2`, with `TMPDIR=$O`, `R84_TIMINGS` and
`R84_SNAPSHOT` redirected there as in the DECISION's block. `E` is
`research/runs/R84/2026-09-18T215916Z-b7f3ee4b098e/review/evidence`.

### shellcheck

`shellcheck "$E/$s.sh"` for all five scripts: every run exited 0 with no output. This
**matches** the DECISION.

### Per-script results

| # | Command (from repo root) | rc | Observed Pass/Fail/Skip (Total) | Committed | `cmp` vs committed log |
|---|---|---:|---|---|---|
| 1 | `R84_TIMINGS=$O/timings.txt R84_SNAPSHOT=$O/registry-figures.json TMPDIR=$O $E/r84-source-claims.sh` | 1 | 59/**1**/0 (60) | 60/0/0 | differs at line 22 (`A14`) — **EF-2** |
| 2 | same redirects, `$E/r84-openapi-to-rust-probe.sh` | 0 | 36/0/0 (36) | 31/0/5 | differs only in `R06`–`R10` (host) |
| 3 | same redirects, `$E/r84-progenitor-probe.sh` | 0 | 6/0/0 (6) | 6/0/0 | **IDENTICAL** |
| 4 | same redirects, `$E/r84-registry-figures.sh` | 0 | 31/0/0 (31) | 31/0/0 | differs only at line 2 (UTC date) |
| 5 | `TOOL_VERSION=0.19.0 R84_TIMINGS=$O/probe-0.19.0-timings.txt TMPDIR=$O $E/r84-openapi-to-rust-probe.sh`, run after 1–4 as the recipe orders it | 2 | 34/**2**/0 (36) | 31/0/5 | differs at `T01`, `T10` — **EF-1** — plus the `R06`–`R10` host lines |
| 5b | as 5, plus `R84_CACHE=$O/cache-019` (an empty tool cache) | 0 | 36/0/0 (36) | 31/0/5 | differs only in `R06`–`R10` (host) |
| 6 | `TMPDIR=$O $E/r84-archive-rerun.sh r84-source-claims r84-openapi-to-rust-probe r84-progenitor-probe r84-registry-figures` | 0 | source-claims 59/0/1; probe 36/0/0; progenitor 6/0/0; registry 31/0/0 | see below | differs at line 11 (host and date only) |

### Rerun 1 — source claims: first differing lines

```text
22,23c22,24
<       files outside research/runs/R84/ declaring OVERRIDE (OV-11): none
< PASS  A14 no other decision declares OVERRIDE (OV-11) (census over research/topics and research/runs)
---
>       files outside research/runs/R84/ declaring OVERRIDE (OV-11): research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/evidence/r51-sources.log
> research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/evidence/reproduction.log
> FAIL  A14 no other decision declares OVERRIDE (OV-11) (census over research/topics and research/runs)
91c92
< PASS=60 FAIL=0 SKIP=0 TOTAL=60
---
> PASS=59 FAIL=1 SKIP=0 TOTAL=60
```

The other 59 checks match the committed log byte for byte.

### Reruns 2 and 5b — the probe at 0.17.0 and at 0.19.0 (fresh cache)

Both diffs against their committed logs are the same host block and nothing else:

```text
60c60,64
<       RT_BIND=refused PermissionDenied
---
>       RT_200=typed id=p1 state=Custom("suspended") visibility=Custom("internal")
>       RT_404_PROBLEM=api status=404 typed_status404=true
>       RT_404_NON_PROBLEM=api status=404 typed_none=true parse_error_some=true body=upstream proxy says no
>       RT_ACCEPT_SENT=application/json
>       RT_CALLER_DEADLINE=elapsed
64,68c68,72
< SKIP  R06 end-to-end typed 200 — this shell refused a loopback TCP bind, ...
---
> PASS  R06 end to end over HTTP: the 200 body with an unknown field and two unknown values deserializes into the typed Project
> PASS  R07 R12.7 a problem+json 404 is branched on status and parsed into the typed Status404(Problem)
> PASS  R08 R12.7 a text/plain 404 from 'infrastructure' still surfaces as status 404 with the raw body, typed=None, parse_error kept
> PASS  R09 R12.6 DEPARTS (SHOULD): even with a caller-supplied Accept, only 'application/json' reaches the server — OVERRIDE (OV-11)
> PASS  R10 R12.3 is met by the caller: tokio::time::timeout around a call to a never-answering listener elapses
```

`T01`–`T22`, `R01`–`R05`, `R11`–`R13` and `AU*` are byte-identical. That includes the verbatim
`DEFAULT_UNKNOWN_FIELD`, `DEFAULT_UNKNOWN_STATE` and `RECIPE_UNKNOWN_VALUES` lines that the
DECISION quotes. The committed 0.17.0 and 0.19.0 logs differ from each other only in `T01`,
as the DECISION states.

### Rerun 4 — registry figures

```text
2c2
< retrieval date (UTC): 2026-09-26
---
> retrieval date (UTC): 2026-09-27
```

This is the UTC date rollover, not a defect.

### Rerun 5 — 0.19.0 by the recipe's order

```text
9c9
< PASS  T01 the installed tool reports 'openapi-to-rust 0.19.0'
---
> FAIL  T01 the installed tool reports 'openapi-to-rust 0.19.0'
36c36
< PASS  T10 no hand-written Rust file: every .rs file under clients/rust carries the generator's own header
---
> FAIL  T10 no hand-written Rust file: every .rs file under clients/rust carries the generator's own header
...
< PASS=31 FAIL=0 SKIP=5 TOTAL=36
---
> PASS=34 FAIL=2 SKIP=0 TOTAL=36
```

### Rerun 6 — the archive harness against the committed `r84-archive-rerun.log`

- `archive HEAD: e0b0d1c1762ee8aa4b28c62282a2225103e594eb`: this matches the log.
- The `r84-source-claims` block reproduces byte for byte. `A13` is `SKIP` in the extraction, and
  the summary reads `PASS=59 FAIL=0 SKIP=1`. `A14` passes in the extraction because the R51 files
  behind EF-2 are untracked.
- `r84-progenitor-probe: rc=0 IDENTICAL` matches the log.
- The fresh log differs from the committed one starting at line 11. On this host
  `r84-openapi-to-rust-probe` reports `DIFFERS`, carrying the `R06`–`R10` host block shown above.
  `r84-registry-figures` reports `DIFFERS`, carrying only the UTC-date line. Neither difference is
  an evidence defect.

## Figures re-derived at source

The committed `snapshots/registry-figures.json` was compared with a fresh snapshot fetched
from crates.io and GitHub the same evening.

| Figure (DECISION line) | Committed | Fresh | Verdict |
|---|---|---|---|
| `openapi-to-rust` all-time downloads (426, 714) | 46,601 | 46,648 | matches; normal drift |
| `openapi-to-rust` 90-day downloads (426) | 45,945 | 45,988 | matches; normal drift |
| `gpu-cli/openapi-to-rust` stars (182, 426, 714) | 37 | 37 | exact |
| non-yanked releases (182) | 35 | 35 | exact |
| reverse dependencies, `F03` (182, 426) | 0 | 0 | exact |
| newest non-yanked (426) | 0.19.0 | 0.19.0, `created_at` 2026-09-26T14:29:43Z | exact |
| `meteora-api` all-time downloads, `F06` | 20 | 20 | exact |

- No `DECISION.md` outside R84 contains `OVERRIDE (OV-11)`.
  Command: `grep -rl --include=DECISION.md 'OVERRIDE (OV-11)' research/topics research/runs`,
  run outside `research/runs/R84/`. It returned no files.
- The claim `A14` asserts is therefore true in substance. See EF-2.

## Informational (not findings)

- **The HTTP half of section 12 executed on this host.** The DECISION's "does not prove (2)"
  says checks `R06`–`R10` were skipped. On this Darwin host, loopback binds are allowed, and all
  five checks pass at both 0.17.0 and 0.19.0. `R09` confirms the `OVERRIDE (OV-11)` departure:
  only `application/json` reaches the server. Linux (AC9) remains unproven.
- **The `A13` skip in the archive extraction reproduces exactly as the DECISION describes.**

## Findings

### EF-1 — the 0.19.0 leg does not reproduce from the DECISION's recipe

- **Failed claim:** the `## Empirical check` table row "`r84-openapi-to-rust-probe.sh` with
  `TOOL_VERSION=0.19.0` … 36 | 31 | 0 | 5". The same section also says the 0.19.0 log
  "reproduces from the last command in the block above and differs from the committed `0.17.0`
  log only in `T01`."
- **Evidence:** the block runs the four base scripts first. Their tool cache is
  `${TMPDIR:-/tmp}/r84-synth-cache/o2r`, and those runs install `openapi-to-rust 0.17.0` into it.
  The 0.19.0 command then runs with the same `TMPDIR`, so it uses the same cache. In
  `r84-openapi-to-rust-probe.sh`, lines 78–83 install only `if [ ! -x "$BIN" ]`. That guard
  ignores the version, so the 0.19.0 install is skipped. After the run,
  `$O/r84-synth-cache/o2r/.crates.toml` still lists `openapi-to-rust 0.17.0`, and
  `openapi-to-rust --version` prints `openapi-to-rust 0.17.0`. Observed result: `FAIL  T01`,
  `FAIL  T10`, and `PASS=34 FAIL=2 SKIP=0 TOTAL=36`, with rc 2.
- **Cross-check:** with an empty cache (`R84_CACHE=$O/cache-019`, rerun 5b), 0.19.0 installs and
  every check passes (36/0/0). The underlying fact holds; the documented procedure does not
  produce it. The committed logs' timestamps agree: the 0.17.0 log is dated 13:49 and the 0.19.0
  log 13:52. The 0.19.0 leg evidently did not reuse the same populated cache.
- **Repair:** make the script's cache version-keyed. Use `$CACHE/o2r-$TOOL_VERSION` for both the
  `--root` argument and `BIN`. Alternatively, add `R84_CACHE=<fresh dir>` to the 0.19.0 line of the
  DECISION's command block. Then rerun that leg from the block as written, reinstall
  `r84-openapi-to-rust-probe-0.19.0.log`, and update the row if it changes.

### EF-2 — `r84-source-claims.sh` fails `A14` on the current tree

- **Failed claim:** the table row "`r84-source-claims.sh` … 60 | 60 | 0 | 0", and the committed
  log line `PASS  A14 no other decision declares OVERRIDE (OV-11) (census over research/topics
  and research/runs)`.
- **Evidence:** the census is
  `grep -rl 'OVERRIDE (OV-11)' research/topics research/runs | grep -v '^research/runs/R84/'`.
  It matches any file that mentions the string, not only decisions. On the current working
  tree it hits two untracked R51 evidence logs, both written about 18:10 on 2026-09-26, after
  the synthesizer's 13:49 run:
  - `r51-sources.log:58`
  - `reproduction.log:35,40`

  In both files the matching lines are `override-numbers-in-use:` enumerations, which list every
  OV number in use. These are mentions, not declarations. Observed result: `FAIL  A14`, then
  `PASS=59 FAIL=1 SKIP=0 TOTAL=60`, rc 1. No `DECISION.md` outside R84 contains the string. The
  assertion is true, but the check proving it is a raw substring census that a sibling item's
  log can break.
- **Repair:** limit the census to decision files, for example `grep -rl --include=DECISION.md
  'OVERRIDE (OV-11)' …`. Alternatively, exclude `review/evidence/` and `*.log`. Then rerun the
  script and reinstall `r84-source-claims.log`. Also rerun the archive harness if its log would
  change.
