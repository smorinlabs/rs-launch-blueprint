actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: c0ac5f9a4790becab53dfd59def40122e1a5369eb89ac06774229ca00332acd4
verdict: approve
unresolved-findings: none

# R79 prometheus-metrics — empirical audit of DECISION.md revision 4

Target: `research/runs/R79/2026-09-17T034011Z-2e1043da0e00/review/DECISION.md`, revision 4.
The auditor recomputed its sha256 with `shasum -a 256` before doing anything else. The result
was `c0ac5f9a4790becab53dfd59def40122e1a5369eb89ac06774229ca00332acd4`, which equals the
expected value. The auditor recomputed it again after all reruns, and it was unchanged.

Scope: this audit judges execution truth and evidence support only. It does not judge the
recommendation's design merit.

## Script set confirmed from `## Empirical check`

The table in `## Empirical check` (lines 1002–1009) and the paragraph "Revision 4 changes no
evidence" (lines 1029–1046) define the current script set for revision 4:

| Script | Decision's expectation for revision 4 | Committed paired log |
|---|---|---|
| `cargo-probes-r3.sh` | 54 / 0 / 0 | `cargo-probes-r3.log`; second-run record `cargo-probes-r3.run2.log` |
| `crate-sources.sh` (rerun unchanged for r3) | 66 / 0 / 0 | `crate-sources-r3.log` |
| `github-api.sh` (rerun unchanged for r3) | 5 / 0 / 0 | `github-api-r3.log` |
| `rustsec-method-r3.sh` | 9 / 0 / 0 | `rustsec-method-r3.log` |
| `decision-self-check-r3.sh` | 315 / 1 / 0; the single FAIL is the H1 check, which expects `(revision 3)` | `decision-self-check-r3.log` (316/0/0 against r3) |
| `rest-conformance-r2.sh` | 120 / 2 / 0; the OV census and the H1 check | `rest-conformance-r2.log` (122/0/0 against r2) |

The superseded predecessors were not rerun and were not judged: `cargo-probes.sh` and
`decision-self-check.sh`, both revision 1. The decision's lines 1011–1015 and 1048–1053 say that
`decision-self-check-r3.sh` supersedes `decision-self-check.sh`.

## Environment

- `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` and `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`.
- macOS, Darwin arm64. `/usr/bin/grep` is BSD grep 2.6.0-FreeBSD.
- `CARGO_HOME=/tmp/cargo-s43-R79-emp`, a private cargo home.
- `CARGO_TARGET_DIR=/tmp/cargo-s43-R79-emp-target` was set. The probe script prints that it
  ignores this variable because every build passes `--target-dir`.
- No `promtool` is on PATH. The probe script fetched and verified Prometheus 3.14.0 itself.
- All reruns took place on 2026-09-27, between 16:24Z and about 16:30Z.
- All scratch output went to `/tmp/r79-audit-r4/`.

**Evidence protection.** `cargo-probes-r3.sh` rewrites `scrape-sample-r3.txt` beside itself
(its own header, lines 31–34). The auditor therefore ran it from a `/tmp` copy of `evidence/`
(`/tmp/r79-audit-r4/evcopy`). This copy is the same arrangement as the decision's `run2`
record. Every other script ran in place from `review/evidence/`, with stdout and stderr sent to
`/tmp`.

Before the reruns, the auditor recorded the sha256 and the modification time of all 42 files
under `evidence/`. After the reruns, both listings were byte-identical ("evidence-hashes-unchanged",
"evidence-mtimes-unchanged"). No file under `evidence/` was written.

## Reruns

| # | Command (cwd) | Output | PASS | FAIL | SKIP | Exit | Matches decision |
|---|---|---|---|---|---|---|---|
| 1 | `./cargo-probes-r3.sh` (in `/tmp/r79-audit-r4/evcopy`) | `/tmp/r79-audit-r4/cargo-probes-r3.fresh.log` | 54 | 0 | 0 | 0 | yes |
| 2 | `./crate-sources.sh` (in `review/evidence/`) | `/tmp/r79-audit-r4/crate-sources.fresh.log` | 66 | 0 | 0 | 0 | yes |
| 3 | `./github-api.sh` (in `review/evidence/`) | `/tmp/r79-audit-r4/github-api.fresh.log` | 5 | 0 | 0 | 0 | yes |
| 4 | `./rustsec-method-r3.sh` (in `review/evidence/`) | `/tmp/r79-audit-r4/rustsec-method-r3.fresh.log` | 9 | 0 | 0 | 0 | yes |
| 5 | `./decision-self-check-r3.sh` (in `review/evidence/`) | `/tmp/r79-audit-r4/decision-self-check-r3.fresh.log` | 315 | 1 | 0 | 1 | yes, disclosed |
| 6 | `./rest-conformance-r2.sh` (in `review/evidence/`) | `/tmp/r79-audit-r4/rest-conformance-r2.fresh.log` | 120 | 2 | 0 | 1 | yes, disclosed |

## Comparison with committed logs, under the decision's own per-file rules (lines 1126–1170)

### 1. `cargo-probes-r3.sh`

**Rule:** remove the lines that begin `volatile:`, then compare.

**Fresh against `cargo-probes-r3.run2.log`:** no difference; the logs are byte-identical.

**Fresh against `cargo-probes-r3.log`:** exactly one line differs.

```
< lock: created snapshot locks-r3/baseB-msrv.lock
> lock: reused snapshot locks-r3/baseB-msrv.lock
```

This is the one difference the decision predicts at line 1138. The first run created the lock
snapshot, and every later run reuses it.

**Volatile values observed in the fresh log.** Each equals the figure the decision states:

| Value | Fresh log | Decision |
|---|---|---|
| Stripped binary, `--features web` | 1,307,936 B | 1,307,936 B |
| Stripped binary, `--features metrics` | 1,702,752 B | 1,702,752 B |
| Delta | +394,816 B, 30.2% | +394,816 B, +30.2% |
| `Locking` line | `Locking 118 packages to latest Rust 1.96 compatible versions` | same |
| RustSec advisories loaded | 1,271 | 1,271 |
| Crate dependencies scanned | 119 | 119 |

**Asserted PASS lines re-observed.** Each line quoted below appears in the fresh log.

- E1: all three feature variants compiled.
- E2: `(= 37)` and `(= 81)`.
- E3: `(= 51)` and `(= 79)`; the delta lies within ±10% of +378,048 B.
- E4: the MSRV resolver ran; "every crate of the E4 graph was found in cargo metadata at its exact version (no silent drop)"; "highest declared rust-version in the graph (1.85.0)".
- E5: exit 0, no vulnerabilities, and `RUSTSEC-2021-0113` does not apply.
- E6: two route label values, `_count` 51, and the unmatched counter at 1.
- F1: `/metrics` is not registered, the business routes still serve, and no global recorder was installed.
- F3: `--features web` alone answers 404 at `/metrics`.
- F4: the HTTP-behaviour test passed.
- E7: the exporter is absent from the `--features web` graph.
- E8: 41 scrape lines; the tarball matches `sha256sums.txt` and the literal pin `a9623f7f…c01c`; `promtool check metrics` accepted the text with no complaint.
- Runner-up: `(= 82)`.

### 2. `crate-sources.sh`

**Rule:** `num`, `created_at`, `rust_version`, `license`, every tarball sha256 and every quoted
source line must be byte-identical. `recent_downloads` is printed and never asserted. The
reverse-dependency totals are volatile.

**Diff against `crate-sources-r3.log`:** only these lines differ.

- The `date-utc` line and the `scratch` line.
- The `recent=` and `all=` counters for all nine crates.
- The printed "90-day window moved by" lines.

The `newest`, `created`, `rust_version` and `license` fields on those same lines are identical.
For example, the committed log reads:

```
metrics  recent=20785492  all=110521264  newest=0.24.6  created=2026-05-13T17:50:59.032914Z rust_version=1.71.1 license=MIT
```

The fresh log reads:

```
metrics  recent=20882542  all=110618241  newest=0.24.6  created=2026-05-13T17:50:59.032914Z rust_version=1.71.1 license=MIT
```

Every tarball sha256 line and every quoted source line is identical. The reverse-dependency
totals, 1,220 and 465, are also unchanged from the committed r3 rerun. There is no drift on any
asserted field.

### 3. `github-api.sh`

**Rule:** only `full_name` and `archived` are asserted. Stars, `pushed_at` and the issue counts
are printed without assertion.

**Diff against `github-api-r3.log`:** two lines differ.

- The `date-utc` line.
- The repository object's `open_issues_count` for `open-telemetry/opentelemetry-rust`, which
  moved from 254 to 256. This is a printed field that the prompt forbids using.

The search `total_count` values and the stars are unchanged. All five `SNAPCMP` lines read
"full_name and archived equal to the snapshot". There is no drift on any asserted field.

### 4. `rustsec-method-r3.sh`

**Rule:** only the `volatile:` header lines may differ.

With `volatile:` lines removed, the fresh log is byte-identical to `rustsec-method-r3.log`.
`metrics-util.html` answers HTTP 200 and names `RUSTSEC-2021-0113`. The surveyed crates answer
HTTP 404.

### 5. `decision-self-check-r3.sh`

**Rule:** only `volatile:` lines may differ between reruns against the same revision. This
rerun ran against revision 4, which moved text.

With `volatile:` lines removed, the diff against `decision-self-check-r3.log` has four parts:

1. **The H1 check.** The committed log reads `PASS  H1 is the date-first revision-3 form`. The
   fresh log reads:

   ```
   FAIL  H1 is '# 2026-09-18 — R79 — prometheus-metrics (crate, Focused) — decision (revision 4)', not '# 2026-09-18 — R79 — prometheus-metrics (crate, Focused) — decision (revision 3)'
   ```

   This is the only FAIL line in the fresh log.
2. **Heading line numbers.** Several printed heading line numbers moved, for example
   `135:## Decision` became `159:## Decision`. The two structural checks that print them still
   PASS: `Principles` lies inside `Decision` (239 < 918), and the re-verify line is the last
   content line of `## Decision` (line 916).
3. **A printed count.** `lines carrying a licence subject` moved from 43 to 48. The script
   prints this count and does not assert it.
4. **The summary.** It changed from `PASS=316 FAIL=0` to `PASS=315 FAIL=1`.

This is exactly the single disclosed FAIL on the revision-bound H1 check (lines 1039 and
1044–1046). Every content check passes on revision 4, including `_validate_decision_text`, the
literal-sha256 assertions on the r1 and r2 artifacts, and the cross-item and py-pin citations.
It is judged as disclosed, not as a finding.

### 6. `rest-conformance-r2.sh`

**Result:** 120 / 2 / 0. The two FAIL lines are these:

- `FAIL  OV-07 is claimed by another item — the controller's allocation must be re-issued`
- `FAIL  H1 is '… decision (revision 4)', not '… decision (revision 2)'`

These are the same two checks the decision names at line 1041.

**Where the census hits come from.** The script prints every file it counts. The auditor
tallied the printed paths and did not open the files. Every hit lies inside this run's own
`review/` directory:

| File | Hits |
|---|---|
| `R79-r2-snapshot.md` | 17 |
| `R79-r3-snapshot.md` | 24 |
| `audit-fable.md` | 3 |
| `audit-fable.r3.md` | 9 |
| `audit-claude.r3.md` | 2 |

No other item claims `OV-07`. This confirms the explanation at lines 1051–1053 and 1059–1063.

**Other lines that differ from `rest-conformance-r2.log`.** Two other lines differ:

- the date line;
- the printed `DECISION.md sha256` line, which now shows the r4 hash.

The r2 script prints that sha256 without asserting it. The decision says the r3 port marks it
`volatile:`. That is consistent.

## Load-bearing figures re-derived at source

- **Revision history (lines 1398–1403).** Both hashes were computed with `shasum` only; the
  auditor did not open either snapshot file.
  - `review/R79-r3-snapshot.md` has sha256 `942ea9d2…3bee1`, which equals the revision-3 hash.
  - `review/R79-r2-snapshot.md` has sha256 `1551c96d…2e215`, which equals the revision-2 hash.
- **Carried-log claim (lines 1017–1023).** The decision says the carried r1 logs differ from
  their r3 reruns only in fields that are printed and never asserted. The auditor diffed both
  pairs of committed logs.
  - `crate-sources.log` against `crate-sources-r3.log`: the differences are only the date line,
    the scratch line, the `recent=` and `all=` counters, the 90-day lines, and the
    reverse-dependency totals (1,199 → 1,220 and 460 → 465). On every registry line,
    `newest`, `created`, `rust_version` and `license` are identical. Every tarball sha256 line
    and every quoted source line is identical.
  - `github-api.log` against `github-api-r3.log`: the differences are only the date, the `gh`
    version, `pushed_at`, stars, and the issue counts.

  The claim holds.
- **Engine report hashes (lines 1267–1276).**
  - `raw/opus.md` has sha256 `c1d02b81…45ac`, which equals the stated hash.
  - `raw/muse.md` has sha256 `15529e48…c056c378`, which equals the stated hash.
- **Shortlist figures (lines 1188–1194).** The 90-day and all-time download figures are
  reproduced from the carried `crate-sources.log` of 2026-09-18:

  | Crate | 90-day downloads | All-time downloads |
  |---|---|---|
  | `metrics` | 20,185,758 | 108,173,967 |
  | `metrics-exporter-prometheus` | 13,007,165 | 47,578,577 |
  | `axum-prometheus` | 1,388,212 | 5,658,682 |
  | `prometheus` | 24,842,546 | 145,764,833 |
  | `opentelemetry-prometheus` | 2,518,260 | 14,203,757 |

  The GitHub figures, as stars/issue `total_count`, are reproduced from the carried
  `github-api.log`: 1486/51, 92/10, 1181/66, 606/44 and 2708/218. The same log records 83 for
  the repository object's `open_issues_count` on `metrics-rs/metrics`.
- **Currency claims (lines 1025–1027).**
  - Reverse dependencies are 1,220 and 465 in the fresh rerun.
  - `metrics-rs/metrics` has a repository-object `open_issues_count` of 84 against a search
    `total_count` of 51 in the fresh rerun.
- **The JF3-2 citation.** `docs/planning/p02/execution-ledger.md:1088` reads "Ruling: OV-07 may
  carry R79's two departures under the one number …". This matches the quotation at lines
  113–116.
- **The RUNBOOK §5 citation.** `research/RUNBOOK.md:208`–`:212` contains the "useful metrics"
  sentence and the requirement that exporter failure and shutdown behaviour be checked. This
  matches the JF3-1 disposition's citation.

## Observations (non-blocking; no repair required for approval)

1. **Mislabelled PASS text in `crate-sources.sh`.**
   - **Where:** `crate-sources.sh:213–214`, a script that was carried unchanged since revision 1.
   - **What the code does:** it asserts `"$total" -gt 100`.
   - **What the PASS text says:** "has a four-figure-order reverse-dependency set". For
     `metrics-exporter-prometheus` the fresh log prints this text for a total of 465, which has
     three figures.
   - **Effect on the decision:** none of its figures depends on this label. The decision's own
     description at line 1159, "asserted only as an order of magnitude", is loose rather than
     false: the assertion is a floor of more than 100.
   - **Suggestion:** a later revision could reword the PASS text to "more than 100". This is
     optional.
2. **Two self-check logs are revision-bound.** Revision 4 wrote no revision-4 self-check. The
   committed `decision-self-check-r3.log` (316/0/0) therefore records revision 3, not
   revision 4. The decision discloses this at lines 1029–1046, and this rerun reproduces the
   predicted 315/1/0 exactly. No evidence claim is false. Note, however, that the one FAIL
   leaves the H1 check unexecuted in a passing form for revision 4.

## Verdict

**approve.** All six current scripts reran with the totals the decision predicts. The cargo
probes are byte-identical to `run2` outside `volatile:` lines. The network scripts drift only
in fields their rules name as printed and unasserted. The self-check failures are exactly the
disclosed revision-bound checks. Every load-bearing figure the auditor re-derived matches its
source.
