actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 942ea9d2ce7dfefd1657eb261340c287d4b18437428ebc9ae78d76c35363bee1
verdict: approve
unresolved-findings: none

# R79 prometheus-metrics — empirical audit of DECISION.md revision 3

Auditor: fresh Claude Opus context, independent of the synthesizer and the judgment
auditor. Date of reruns: 2026-09-27 (UTC). Scope: execution truth and evidence support
only. No review/audit-*.md, no review/Rxx-r*-snapshot.md content and no topics raw/
directory were read.

## Identity

`shasum -a 256 research/runs/R79/2026-09-17T034011Z-2e1043da0e00/review/DECISION.md` →
`942ea9d2ce7dfefd1657eb261340c287d4b18437428ebc9ae78d76c35363bee1`, equal to the expected
revision-3 hash. The H1 reads `… — decision (revision 3)`.

## Environment

`rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05)
(Homebrew)`, Darwin arm64, `/usr/bin/grep` = BSD grep 2.6.0-FreeBSD, `cargo-audit-audit
0.22.1`, `curl 8.7.1`, ShellCheck 0.11.0. Private `CARGO_HOME=/tmp/cargo-s37-R79-emp`;
`CARGO_TARGET_DIR=/tmp/cargo-s37-R79-emp-target` set in the session. These match the
decision's stated toolchain.

## Execution deviation, disclosed

The brief names `review/evidence/` as the working directory. `cargo-probes-r3.sh` writes
`scrape-sample-r3.txt` and (when missing) `locks-r3/*.lock` beside itself (its header,
lines 32–34, and line 633). Running it in place would overwrite committed evidence. I
therefore copied `evidence/` with `cp -Rp` to `/tmp/r79a-run1/evidence` and
`/tmp/r79a-run2/evidence` and ran each copy there. The network scripts ran from a third
copy, `/tmp/r79a-net/evidence`. `rest-conformance-r2.sh`, `decision-self-check.sh` and
`decision-self-check-r3.sh` resolve the repository root from their own path, so they ran
in place. I checked that these three write only to a `mktemp -d` scratch directory.
All output went to `/tmp/r79a-*.log`. The committed `evidence/` is untouched:
`scrape-sample-r3.txt` still has its 23:30 mtime, and `locks-r3/` still holds one file.

Two consequences of this setup:

1. Each copy already contained `locks-r3/baseB-msrv.lock`, so run 1 prints `lock: reused
   snapshot` where the committed first-run log prints `created`. The decision predicts
   this exact line at lines 1050–1052.
2. Runs 1 and 2 executed concurrently, sharing `CARGO_HOME`. That produced two extra lines
   in run 1, both on `volatile:` lines (see Observation O1).

## Reruns

| # | Command (cwd) | Output | PASS/FAIL/SKIP | Compared against | Result |
|---|---|---|---|---|---|
| 1 | `./cargo-probes-r3.sh` (`/tmp/r79a-run1/evidence`, `CARGO_TARGET_DIR` set) | `/tmp/r79a-probes-run1.log`, stderr empty | 54/0/0, exit 0 | `cargo-probes-r3.log` | pass: non-volatile lines identical except the predicted `created`→`reused` line |
| 2 | `env -u CARGO_TARGET_DIR ./cargo-probes-r3.sh` (`/tmp/r79a-run2/evidence`) | `/tmp/r79a-probes-run2.log`, stderr empty | 54/0/0, exit 0 | `cargo-probes-r3.run2.log` | pass: byte-identical except `volatile: date-utc` and `volatile: scratch` |
| 3 | `./crate-sources.sh` (`/tmp/r79a-net/evidence`) | `/tmp/r79a-crate-sources.log` | 66/0/0, exit 0 | `crate-sources-r3.log` | pass: only volatile, never-asserted fields differ (quoted below) |
| 4 | `./github-api.sh` (`/tmp/r79a-net/evidence`) | `/tmp/r79a-github.log` | 5/0/0, exit 0 | `github-api-r3.log` | pass: only `date-utc` differs |
| 5 | `./rustsec-method-r3.sh` (`/tmp/r79a-net/evidence`) | `/tmp/r79a-rustsec.log` | 9/0/0, exit 0 | `rustsec-method-r3.log` | pass: only `volatile: date-utc` differs |
| 6 | `./rest-conformance-r2.sh` (in place) | `/tmp/r79a-rest.log` | 120/2/0, exit 1 | expected 120/2/0 | pass as designed: exactly the two named failures |
| 7 | `./decision-self-check.sh` (in place; revision 1, superseded) | `/tmp/r79a-self-r1.log` | 72/2/0, exit 1 | expected 72/2/0 | informational: exactly the two failures the decision names |
| 8 | `./decision-self-check-r3.sh` (in place, last) | `/tmp/r79a-self-r3.log` | 316/0/0, exit 0 | `decision-self-check-r3.log` | pass: byte-identical except `volatile: date-utc`. The `volatile: DECISION.md sha256` line equals the committed log's line |

Totals across the eight reruns: 626 PASS, 4 FAIL, 0 SKIP. All four FAILs are the by-design
failures in rows 6 and 7.

### Row 1 — cargo probes, run 1, full diff against `cargo-probes-r3.log`

```text
6,8c6,8   volatile: date-utc, volatile: scratch, volatile: CARGO_TARGET_DIR value (/tmp/cargo-s27-R79-r3-target → /tmp/cargo-s37-R79-emp-target)
175c175   < lock: created snapshot locks-r3/baseB-msrv.lock
          > lock: reused snapshot locks-r3/baseB-msrv.lock
194a195   > volatile: audit | warning: directory /tmp/cargo-s37-R79-emp/advisory-db is locked, waiting for up to 300 seconds for it to become available
195a197   > (the same warning again)
```

The committed pair shows the same relationship. With `volatile:` lines removed,
`cargo-probes-r3.log` and `cargo-probes-r3.run2.log` differ in exactly line 165,
`created` against `reused`. This confirms the decision's claim at lines 1049–1053.

**Delta claims asserted on volatile lines.** Both reruns print these values:

- `stripped release binary, --features web : 1307936 B`
- `--features metrics : 1702752 B`
- `delta : 394816 B, 30.2%`

The values are identical to the decision (E3, line 996). The script also passes `E3 the
metrics delta is within +/-10% of revision 1's +378048 B (tolerance 340243..415853 B)`.
Other volatile values, identical to the decision:

- `Locking 118 packages to latest Rust 1.96 compatible versions`
- `Loaded 1271 security advisories`
- `Scanning Cargo.lock for vulnerabilities (119 crate dependencies)`

Load-bearing figures re-read in the rerun, all matching the decision:

| Check | Rerun value |
|---|---|
| E2 | 37 against 81 |
| E3 | 51 against 79; `tower-http` absent; `tower` present in both |
| E4 | 119 packages in the lock; 79 graph crates; `JOINED 78 of 78`; `HIGHEST 1.85.0 hashbrown 0.17.1`; `UNDECLARED 12 packages` (named: evmap, hashbag, httparse, left-right, matchit, mime, serde_urlencoded, sketches-ddsketch, smallvec, sync_wrapper, tower-layer, tower-service) |
| E5 | `RUSTSEC-2021-0113` does not apply |
| E6 | `_count` 51 on `/v1/projects/{id}`; `/v1/boom` 1; unmatched counter 1 |
| F1, F3, F4 | all PASS lines present |
| E8 | promtool 3.14.0 fetched; tarball sha256 `a9623f7f…dc01c`; `accepted`; no complaint |

The fresh verbatim captures (`/tmp/r79a-run{1,2}/evidence/scrape-sample-r3.txt`) are 41
lines each. They have the same `http_route` set as the committed capture, and zero
`http_route="/metrics"` series.

### Row 3 — `crate-sources.sh` volatile drift against `crate-sources-r3.log` (quoted)

```text
5c5   date-utc: 2026-09-27T06:22:21Z → 2026-09-27T08:38:05Z
7c7   scratch path
14    metrics                      recent=20785492 all=110521264 → recent=20827619 all=110563324 ; window +599734 → +641861
18    metrics-exporter-prometheus  recent=13418301 all=49050435  → recent=13444576 all=49076666  ; window +411136 → +437411
22    axum-prometheus              recent=1440448  all=5812213   → recent=1443196  all=5814954   ; window +52236 → +54984
26    prometheus                   recent=25183809 all=148301859 → recent=25231228 all=148349210 ; window +341263 → +388682
30    prometheus-client            recent=10017089 all=44519028  → recent=10035702 all=44537601  ; window +321330 → +339943
34    opentelemetry-prometheus     recent=2625129  all=14518497  → recent=2628541  all=14521906  ; window +106869 → +110281
38    autometrics                  recent=530287   all=4370008   → recent=531130   all=4370849   ; window -14362 → -13519
42    measured                     recent=563908   all=2173363   → recent=564188   all=2173643   ; window +75597 → +75877
46    axum-otel-metrics            recent=206069   all=423709    → recent=206232   all=423872    ; window +16906 → +17069
```

On every one of those lines, `newest`, `created`, `rust_version` and `license` are
byte-identical. No `tarball … sha256` line differed. No quoted source line differed. No
PASS line differed; the reverse-dependency PASS lines still read 1220 and 465. The
all-time counters rose, as the script's rule requires.

Against the revision-1 `crate-sources.log`, the PASS lines differ only in the two
reverse-dependency totals: 1199→1220 and 460→465. The decision states this movement at
line 956.

### Row 4 — `github-api.sh`

Against `github-api-r3.log`, only `date-utc` differs.

Against the revision-1 `github-api.log`, `full_name` and `archived=False` are unchanged
for all five repositories. The committed revision-3 log already shows this drift:

- `gh` version: 2.98.0 → 2.101.0.
- `metrics-rs/metrics`: `pushed_at` 2026-09-18T14:54:13Z → 2026-09-22T18:08:24Z; repository-object `open_issues_count` 83 → 84; search `total_count` stays 51.
- `prometheus/client_rust`: `pushed_at` → 2026-09-21T13:54:09Z; `open_issues_count` 65 → 66.
- `open-telemetry/opentelemetry-rust`: stars 2708 → 2719 (`stars +11`); `pushed_at` → 2026-09-25T08:11:20Z; search `total_count` 218 → 216; `open_issues_count` 258 → 254.

None of these fields is asserted by the script.

### Row 5 — RustSec method

The metrics-util page returns `HTTP 200` and names `RUSTSEC-2021-0113`. Seven crates
return `HTTP 404`: metrics, metrics-exporter-prometheus, axum-prometheus, prometheus,
opentelemetry-prometheus, autometrics and prometheus-client. This supports the settlement
of `## Engines` item vii. Two other probes also agree: the `crate-sources` rerun, which
covers nine crates plus metrics-util, and E5.

### Rows 6–7 — by-design failures, exact text

`rest-conformance-r2.sh` (120/2/0):

```text
FAIL  OV-07 is claimed by another item — the controller's allocation must be re-issued
FAIL  H1 is '# 2026-09-18 — R79 — prometheus-metrics (crate, Focused) — decision (revision 3)', not '... (revision 2)'
```

`decision-self-check.sh`, revision 1 (72/2/0):

```text
FAIL  the raw/ directory holds an unexpected number of engine reports
FAIL  H1 is '... (revision 3)', not '... (revision 1)'
```

Both match the decision's predictions at lines 962–965. No other check failed.

### Row 8 — literal-sha256 coverage of revision-1/2 history

`decision-self-check-r3.log` lines 14–44 assert a literal sha256 for each of these files.
I recomputed each with `shasum -a 256`, and each equals the full literal in
`decision-self-check-r3.sh`. For example, line 118 holds `cargo-probes.log|3c774ff4…f7340e`,
and line 44 holds `R2_SHA=1551c96d…e2215`.

| Group | Files |
|---|---|
| Revision-1/2 scripts | `cargo-probes.sh`, `crate-sources.sh`, `github-api.sh`, `decision-self-check.sh`, `rest-conformance-r2.sh` |
| Revision-1/2 logs | the logs of those five scripts |
| Other artifacts | `scrape-sample.txt`, the four `locks/*.lock`, all 15 `snapshots/*`, `review/R79-r2-snapshot.md` (`1551c96d…e2215`) |

The revision-1/2 summary lines read as follows, matching decision lines 942–944:

- `cargo-probes.log` 34/0/0
- `crate-sources.log` 66/0/0
- `github-api.log` 5/0/0
- `decision-self-check.log` 70/0/0
- `rest-conformance-r2.log` 122/0/0

## Re-derivation at source

I downloaded fresh tarballs from `static.crates.io`, with the repository URL as the
User-Agent, and paced the requests at about one per second.

| Claim | Decision location | Observed at source | Result |
|---|---|---|---|
| tarball sha256 of `metrics` 0.24.6 / exporter 0.18.3 / `axum-prometheus` 0.10.1 | `crate-sources-r3.log` 58/81/133 | `89550ee9…39fe2` / `1db0d8f1…f9108` / `27e29a21…4cdf0` | equal |
| `metrics` `unsafe`: 35 across three files (27/5/3) | gate 3, line 1091 | `grep -rcw unsafe src`: cow.rs 27, recorder/cell.rs 5, recorder/mod.rs 3 | equal |
| `metrics` `Cargo.toml.orig:5` = `rust-version = { workspace = true }`; no `[features]` table | gate 2 / 5 | exact line; no `[features]` table | equal |
| exporter: exactly one `unsafe`, in `src/recorder.rs`; `default = ["http-listener", "push-gateway"]` | gate 3 / 5 | `recorder.rs:38` `unsafe { evmap::new_assert_stable() }`; `Cargo.toml.orig:19` | equal |
| exporter `#[cfg(any(` at `:443` and `:531`, `install_recorder` `:506`, `build_recorder` `:605`, 5 s `upkeep_timeout` at `:88` | Engines line 1208 | `src/exporter/builder.rs`: each at the stated line | equal |
| `axum-prometheus` `Cargo.toml.orig` `:8`, `:18`, `:21`, `:32`; `src/lib.rs:889` `run_upkeep`, `:892` `set_global_recorder(...).expect(...)`; zero `unsafe` in `src/lib.rs` | lines 1125–1138 | each line as quoted; `grep -cw unsafe` → 0 | equal |
| py off switch at pin `b08bccfb` | Engines row xi | `git show`: `web/settings.py:64` `metrics_enabled: bool = True`, `web/app.py:148` `if settings.metrics_enabled:` | equal |
| raw report hashes | Engines, lines 1179–1184 | `raw/opus.md` `c1d02b81…145ac`, `raw/muse.md` `15529e48…c378` | equal |

## Controller notes applied

- **(a) Sibling pins.** Every pin in the self-check resolves now. The pins are: R69
  revision 9 `d4507f5b`, R69 revision 10's `:54`–`:61` and `:1791`, R77 revision 3 at
  `1e3cdb5b` (`:663`, `:684`) through `git show`, R80's raw-report lines, the
  COMMONALITY F303/F326 lines, the OWNER-REVIEW W2-REST lines, the execution-ledger
  `:1073`/`:1074` OV-07 allocation, the REST standard blob `71bd813c…` and commit
  `0850d43e…`, and py `b08bccfb`. There were 0 SKIPs. R77's working tree has moved to
  revision 4 (self-check volatile line: variable at `:758`, deferral at `:789`). The
  decision's committed revision-3 pin still resolves, and the working tree still names
  `RSLBP_WEB_METRICS_ENABLED`. This is not stale.
- **(b) Prompt sentence.** `inputs/prompt.md:8` still reads "on by default, no env gate",
  and `:40` still reads "no env var gates metrics collection". The live topic prompt says
  the same. The decision's fix is executed and evidenced, so I record the prompt as an
  observation only. The fix is py's default-true switch as `RSLBP_WEB_METRICS_ENABLED`.
  F1 proves it at execution: 404 at `/metrics`, 200 on `/v1/projects/7`, and no recorder
  installed. The self-check asserts the py source lines.

## Observations (not findings)

- **O1.** The decision (line 1046–1047) says the advisory-db path is redacted to
  `<advisory-db>`. Under concurrent runs sharing one `CARGO_HOME`, `cargo audit` printed a
  lock-wait warning that carries the raw path: `volatile: audit | warning: directory
  /tmp/cargo-s37-R79-emp/advisory-db is locked, …`. It is on a `volatile:` line, so it is
  exempt from byte-identity. It appears only under parallel execution, which my setup
  caused; a sequential rerun does not produce it.
- **O2.** `raw/` holds three files: `opus.md`, a byte-identical `opus-c1d02b81….md`, and
  `muse.md`. The decision speaks of two reports. The revision-3 self-check passes on this
  layout, and the revision-1 self-check's report-count failure is the one the decision
  predicts.
- **O3.** `manifest.json` still records the Muse operation `d4a2338f77114baba83a7670688fe894`
  as `state: submitting`, and `raw/muse.md` is untracked. The decision discloses this at
  lines 1185–1188 as re-verify trigger 17. This is a runner acceptance step, not an
  execution-truth defect of the decision.
- **O4.** Compile time (+8 s), the issue-responsiveness medians and the adopter manifests
  are carried on the engine's word. The decision labels them that way (lines 1229–1231);
  I did not re-measure them.

## Verdict

approve. Every rerun reproduced its committed log. Differences appear only on lines the
decision declares volatile, or on the one `created`/`reused` line that it predicts. Every
asserted field is byte-identical. The by-design failures are exactly the named ones, and
every load-bearing figure re-derived at source matches. unresolved-findings: none.
