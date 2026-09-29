actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 16c4dcfed204473e62c9891489623c78c7c9c63140f918721e15e647d1e89098
verdict: approve
unresolved-findings: none

# R84 empirical audit — revision 4 (openapi-typed-client-generation)

Role: fresh empirical auditor, independent of the synthesizer and the judgment
auditor. Scope: execution truth and evidence support only. No prior audit, raw
topic report or revision snapshot was read.

## Target

`research/runs/R84/2026-09-18T215916Z-b7f3ee4b098e/review/DECISION.md`, revision 4.
`shasum -a 256` gave `16c4dcfed204473e62c9891489623c78c7c9c63140f918721e15e647d1e89098`
before any run and again immediately before this file was written. It matches the
expected hash.

## Environment

- Host: Darwin arm64. `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1`,
  `just 1.57.0`, rustup toolchain `1.96.0` for the floor check. `shellcheck` from
  `/opt/homebrew/bin`.
- Repository HEAD `e0b0d1c1762ee8aa4b28c62282a2225103e594eb`.
- Private `CARGO_HOME=/tmp/cargo-s18-r84-emp` in the shell. The scripts set their own
  private `CARGO_HOME` under the cache.
- Every volatile output was routed to `/tmp`. Nothing under `review/evidence/` was
  written.
- Run window: 2026-09-27 UTC (2026-09-26 Pacific).

## Commands

These commands follow the decision's `## Empirical check` block. The only change is
that `$O` is set explicitly instead of through `${TMPDIR:-/tmp}/r84-rerun`:

```bash
cd /Users/stevemorin/c/rs-launch-blueprint-p02-plan
E=research/runs/R84/2026-09-18T215916Z-b7f3ee4b098e/review/evidence
O=/tmp/r84-audit-claude-r4; mkdir -p "$O"; export TMPDIR="$O"
for s in r84-source-claims r84-openapi-to-rust-probe r84-progenitor-probe r84-registry-figures; do
  shellcheck "$E/$s.sh"
  R84_TIMINGS="$O/timings.txt" R84_SNAPSHOT="$O/registry-figures.json" "$E/$s.sh" > "$O/$s.log" 2>&1
done
shellcheck "$E/r84-archive-rerun.sh"
TOOL_VERSION=0.19.0 R84_CACHE="$O/cache-0.19.0" R84_TIMINGS="$O/probe-0.19.0-timings.txt" \
  "$E/r84-openapi-to-rust-probe.sh" > "$O/r84-openapi-to-rust-probe-0.19.0.log" 2>&1
"$E/r84-archive-rerun.sh" r84-source-claims r84-openapi-to-rust-probe r84-progenitor-probe r84-registry-figures \
  > "$O/r84-archive-rerun.log" 2>&1
# then each fresh log was compared: cmp "$O/<leg>.log" "$E/<leg>.log"
```

`shellcheck` exited 0 with no output on all five scripts.

## Results per leg

| Leg | Fresh summary (run/pass/fail/skip) | rc | `cmp` against committed log |
|---|---|---:|---|
| (a) `r84-source-claims.sh` | 60 / 60 / 0 / 0 | 0 | **IDENTICAL** |
| (b) `r84-openapi-to-rust-probe.sh`, first pass | 36 / 29 / 2 / 5 | 2 | differs: `T11`, `AU01`, summary line (host network; see below) |
| (b) `r84-openapi-to-rust-probe.sh`, retry, unchanged command | 36 / 31 / 0 / 5 | 0 | **IDENTICAL** |
| (c) `r84-progenitor-probe.sh` | 6 / 6 / 0 / 0 | 0 | **IDENTICAL** |
| (d) `r84-registry-figures.sh` | 31 / 30 / 0 / 1 | 0 | differs: UTC date line and `M01` (host network; see below) |
| (e) probe with `TOOL_VERSION=0.19.0`, own `R84_CACHE` | 36 / 31 / 0 / 5 | 0 | **IDENTICAL** |
| (f) `r84-archive-rerun.sh` over the four scripts | see below | 0 | differs from `r84-archive-rerun.log` only by the `M01` hunk |

### Leg (b): first-pass failure, diagnosed and retried

The first pass printed:

```text
FAIL  T11 the generated package compiles on current stable
FAIL  AU01 cargo audit over the generated client's resolved lockfile reports a finding
PASS=29 FAIL=2 SKIP=5 TOTAL=36
```

The committed log reads `PASS  T11 … (1.98.1)`, `PASS  AU01 … no vulnerability` and
`PASS=31 FAIL=0 SKIP=5 TOTAL=36`. In the same pass, `T12` (the 1.96.0 floor) and every
other check passed.

The script discards stderr for both checks. To see the error, I ran a diagnostic copy of
the script in `/tmp` with those two redirects removed. This shell's egress proxy was
refusing crates.io at that moment:

```text
warning: spurious network error (3 tries remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
warning: spurious network error (3 tries remaining): [56] Failure when receiving data from the peer (CONNECT tunnel failed, response 403)
error: failed to get `futures-util` as a dependency of package `rs-launch-blueprint-client v0.0.0 (...)`
  unable to update registry `crates-io`
  download of config.json failed
```

`AU01` then failed with `I/O operation failed: entity not found`. The reason is that
`cargo generate-lockfile` could not reach the index, so no `Cargo.lock` existed for
`cargo audit` to read. The advisory database was not the cause. Its HEAD was
`e2111519ba6d14a5da59a7b2e5c8083ae8a37c01`, the same commit as the synthesizer's
timings file. The first-pass stable check also took 181 s, against 44 s in the
committed timings. That duration matches cargo's retry-and-timeout pattern.

When crates.io was reachable again, `https://index.crates.io/config.json` returned `200`.
I then reran the unchanged leg command with the same cache. It exited 0, and its log was
**byte-identical** to `r84-openapi-to-rust-probe.log`. The same recipe also reproduced
byte for byte inside the clean-archive leg (f), which prints
`r84-openapi-to-rust-probe: rc=0 IDENTICAL`. **Conclusion:** the first-pass `FAIL`s were
caused by this host's network, not by the recipe. They are not a finding.

### Leg (d): `M01` does not reproduce from this host

```text
< PASS  M01 Maven Central is reachable from this host (openapi-generator-cli maven-metadata.xml)
> SKIP  M01 Maven Central is unreachable from this host, so OpenAPI Generator 7.25.0 could not be downloaded or executed here
```

An independent `curl` to
`https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/maven-metadata.xml`
from this shell timed out after 30 s (`curl: (28)`). A retry outside the command
sandbox was refused by this session's permission layer, so I could not settle
reachability another way. This is the status of that retry, not an inference.

The decision dates `M01` as `PASS` on 2026-09-26. It also states that `M01` "verifies
Maven Central metadata reachability only", that no JVM leg exists, and that no
disposition rests on `M01`. Every other registry, RustSec, GitHub and Cargo Book check
passed. The only other changed line is the UTC date (`2026-09-26` committed, `2026-09-27`
fresh), and the decision already discloses that difference. **Conclusion:** `M01` is a
host condition on a check that bears no load. It is not a finding.

### Leg (f): archive rerun

The archive was extracted from HEAD `e0b0d1c1762ee8aa4b28c62282a2225103e594eb`. Results:

- `r84-openapi-to-rust-probe: rc=0 IDENTICAL`.
- `r84-progenitor-probe: rc=0 IDENTICAL`.
- `r84-source-claims: rc=0 DIFFERS`. The only differences are the `A13` line
  (`PASS` becomes `SKIP`) and the summary line (`PASS=59 FAIL=0 SKIP=1 TOTAL=60`).
  This is exactly the difference the decision predicts.
- `r84-registry-figures: rc=0 DIFFERS`. The differences are the UTC date line and the
  same `M01` host condition described under leg (d).

My fresh archive log matches the committed `r84-archive-rerun.log` up to line 17. It then
adds one hunk, the `M01` hunk. That hunk is host-dependent for the reasons given under
leg (d).

## Claims re-derived at source

- **`A13` (the allocation line is present in the working tree and absent at HEAD).** The
  script searches for the exact string `OV allocation: OV-10 to R72, OV-11 to R84`. That
  string occurs 1 time in the working-tree `docs/planning/p02/execution-ledger.md` and
  0 times in `git show HEAD:docs/planning/p02/execution-ledger.md`. HEAD's ledger
  contains other `OV-11` lines, but not the allocation line. The decision's claim that
  HEAD "has 0 occurrences of it" is correct.
- **0.19.0 log against the 0.17.0 log.** `diff` shows exactly one changed line:
  `T01 … 'openapi-to-rust 0.17.0'` becomes `'openapi-to-rust 0.19.0'`. This matches the
  decision.
- **Section-12 probe output.** The four verbatim lines quoted in the decision appear
  unchanged in the fresh log:
  - `DEFAULT_UNKNOWN_FIELD`
  - `DEFAULT_UNKNOWN_STATE … line 1 column 44`
  - `RECIPE_UNKNOWN_VALUES=accepted state=Custom("suspended") visibility=Custom("internal")`
  - `RT_BIND=refused PermissionDenied`

  This shell also refused the loopback bind, so `R06`–`R10` printed `SKIP` by name, as
  the decision states.
- **Checks behind the disagreements.** All passed in the fresh logs:
  - `A06` and `A07` (R42's tool channel).
  - `B04`–`B06` (py pin: no `clients/` path, no ignore entry, no CI mention).
  - `D01`–`D03` (progenitor admits only `3.0.`).
  - `P02` and `P02b` (a real 3.1 document is refused while parsing).
  - `E01`–`E07`: `edition = "2021"` with no `rust-version`; `E04` closed enums;
    `E03` no `time` crate; `E06` "(beta)"; `E07` 3.1 beta warning.
  - `T09`, `T12`, `T13` (edition 2024 and rust-version 1.96; the 1.96.0 floor compiles;
    one workspace member).
  - `CB01` (Cargo Book guidance).
- **Volatile figures.** The committed snapshot `snapshots/registry-figures.json`
  (retrieved 2026-09-26) records the following for `openapi-to-rust`:
  46,601 all-time downloads, newest version 0.19.0, 37 GitHub stars. For `meteora-api`
  it records 20 downloads. These match the decision's `46,601`, `37 stars` and
  `20 downloads`. A live read-only query on 2026-09-27 returned 46,648 downloads,
  newest and max-stable version 0.19.0, and 37 stars with `archived: false`. That is
  consistent with a monotone download count and an unchanged star count.
- **Results table.** Each run/pass/fail/skip row in `## Empirical check` matches the
  committed logs. Each row except `M01`'s registry row is reproduced by a fresh run
  (the retry, for leg (b)).

## Verdict

**approve.** Each of the six legs either reproduced its committed log byte for byte or
differed only as follows:

- In ways the decision itself discloses: `A13` in the archive; the UTC date line.
- In ways traced to this host's network, on checks that bear no load (`M01`) or that
  passed on an unchanged retry (`T11`, `AU01`).

Every load-bearing figure and quotation I checked is supported by its evidence. I found
no unresolved finding about execution truth or evidence support.
