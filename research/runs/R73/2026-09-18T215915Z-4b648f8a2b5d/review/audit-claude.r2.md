actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 842d48f67a140cb46b9909ac5e09de729fd267660bdf4f106aaa82ac2d99915e
verdict: approve
unresolved-findings: none

# R73 — idempotency-middleware — empirical audit of DECISION.md revision 2

Seat: empirical auditor, fresh context, independent of the synthesizer and the
judgment auditor. Scope: execution truth and evidence support only. No prior
audit, raw topic folder, or revision snapshot was read.

## Identity

`shasum -a 256 review/DECISION.md` →
`842d48f67a140cb46b9909ac5e09de729fd267660bdf4f106aaa82ac2d99915e`, equal to the
expected revision-2 hash. Audit proceeded.

## Environment

- `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, Darwin 25.4.0 arm64 —
  the toolchain the decision's `## Empirical check` names.
- Working directory for every run:
  `research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/evidence/`.
- Every fresh log was written to `/tmp/r73a/<script>.log`. The committed
  `evidence/` directory listing (names, sizes, mtimes) was unchanged after all
  six runs.
- Run date: 2026-09-27, ~08:16–08:18 UTC.

## Reruns

| # | Command | Exit | Fresh total | Committed total | Byte comparison with the committed `.log` |
|---|---|---|---|---|---|
| 1 | `./r73-standard-conformance.sh > /tmp/r73a/r73-standard-conformance.log 2>&1` | 0 | 45 run, 45 pass, 0 fail, 0 skip | 45/45/0/0 | `cmp`: differ at line 3 only — `< date_utc: 2026-09-27T06:28:50Z` / `> date_utc: 2026-09-27T08:16:36Z` |
| 2 | `./r73-sources.sh > /tmp/r73a/r73-sources.log 2>&1` | 0 | 23/23/0/0 | 23/23/0/0 | line 3 only — `run_date_utc` `06:28:50Z` → `08:16:37Z` |
| 3 | `./r73-registry.sh > /tmp/r73a/r73-registry.log 2>&1` | 0 | 17/17/0/0 | 17/17/0/0 | line 3 only — `run_date_utc` `06:28:50Z` → `08:16:38Z` |
| 4 | `./r73-muse-currency.sh > /tmp/r73a/r73-muse-currency.log 2>&1` | 0 | 46/46/0/0 | 46/46/0/0 | line 3 only — `run_date_utc` `06:28:55Z` → `08:16:43Z` |
| 5 | `./r73-probe.sh > /tmp/r73a/r73-probe.log 2>&1` | 0 | 27/27/0/0 | 27/27/0/0 | differs; see below |
| 6 | `./r73-decision-shape.sh > /tmp/r73a/r73-decision-shape.log 2>&1` (run last) | 0 | 33/33/0/0 | 33/33/0/0 | differs at lines 3 and 56; see below |

Sum for scripts 1–5: 45 + 27 + 23 + 17 + 46 = **158 checks, 158 pass**, as the
decision states. Script 6 is counted separately, as the decision states.

**Script 5 (`r73-probe.sh`) diff.** Every difference falls in a category the
decision declares variable: `date_utc` (line 3), the `mktemp` work directory
(`r73probe.rtEoAe` → `r73probe.HRgsuB`, lines 7 and 25), test execution order
in both suites, `s08 ns_per_op=1113` → `1222` (debug), cargo's `finished in
0.15s` → `0.16s`, and the release figure `release ns_per_op=184` → `201`. The
decision records 184 ns/op for the revision-2 log and a prior 179–373 range;
201 is inside that range and three orders of magnitude below 1 ms, so `P5-bench`
still passes. Every stable element named in the decision is byte-identical:
each `PASS` line, the check count, the `Locking 62 packages` line, the nine
dependency-tree totals with resolved versions (51; 59 `sha2 =0.11.0`; 54
`hashlink`; 56 `lru =0.18.4`; 54 `lru =0.18.5`; 60 `quick_cache`; 62
`mini-moka`; 65 `moka`; 88 `axum-idempotent` stack), `store` 10 passed and
`web` 18 passed.

**Script 6 (`r73-decision-shape.sh`) diff.** Line 3 is the date. Line 56
changed from `PASS D7-tree-live — the live checkout fails only on other
sessions' in-flight state, 5 FAIL lines naming R11 R55 R57 R62 R72 and none
naming R73` to `PASS D7-tree-live — scripts/check-research-tree.sh also passes
in the live checkout`. The shared checkout became cleaner since record time;
R73 is clean in both. `D7-tree` (clean extraction) passes, and the log-total
checks read the committed five logs and agree with the fresh totals above.

## Figures re-derived at source

| Claim in the decision | Re-derivation | Result |
|---|---|---|
| Opus raw sha256 `a909a140…` | `shasum -a 256 raw/opus.md` | match |
| Doxa raw sha256 `da390324…` | `shasum -a 256 raw/doxa.md` | match |
| Muse raw sha256 `aca32803…`, 291 lines | `shasum`, `wc -l raw/muse.md` | match; 291 |
| `engine_overrides.R73` = `["muse","opus","doxa"]` | read `research/EXECUTION.json` | match |
| manifest `required_engines` is the same | read `manifest.json` | match |
| Ledger pins `:1114` Q5.A, `:1121` Q9.B, `:1160` R73 Muse collected 2026-09-23, `:1215` Q17.A 2026-09-27 | `sed -n` each line of `docs/planning/p02/execution-ledger.md` | each line carries the cited record (pins resolve now) |
| `operations/muse.json` still reads `state: submitting` | read the file | match (disclosed discrepancy is real) |
| Muse header dates its live figures 2026-09-25 | `raw/muse.md:3` | match |
| Opus probe workspace deleted (`raw/opus.md:1081`, `:1261-1262`) | read those lines | match |
| RustSec: `sha2` page 200 with only RUSTSEC-2021-0100; `moka` 404; `atty` control 200 | live read-only `curl` today | match |
| `sha2` newest 0.11.0, 2026-03-25, `rust-version` 1.85 | live `crates.io` API today | match |
| `lru` 0.18.5 published 2026-09-23 | live `crates.io` API today | match |
| `cratestack-axum` still declares `rust-version` 1.98.0 (gate-2 exclusion stands) | live `crates.io` API today: newest 0.14.0, 2026-09-27, `rust_version` 1.98.0 | match |
| `axum-idempotent` 0.4.0 published 2026-09-23 | live `crates.io` API today | match |

## Observations (not findings)

- `r73-muse-currency.sh` reads live repository files; the files it reads
  (`EXECUTION.json`, the ledger, `RUNBOOK.md`) carry uncommitted working-tree
  changes in this checkout. The checks pass against the current state, which is
  what the controller note asks for.
- The `axum-idempotent` 0.4.0 stack cost (+39) is carried from a revision-1
  audit and labelled as not re-snapshotted; the recommendation does not rest on
  it. Not re-derived here.

## Verdict

approve — all six scripts execute and pass with the stated totals (158/158 plus
33/33), every fresh log matches its committed log except in lines the decision
declares variable, and every load-bearing pin checked resolves at source today.
