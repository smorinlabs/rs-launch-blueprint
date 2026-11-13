actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 7b936d861827d81e7f9bff2023b29511980864ec9c7d593b8034ba433ab7a4e5
verdict: approve
unresolved-findings: none

# R75 http-middleware-stack — empirical audit of DECISION.md revision 1

Seat: empirical auditor (fresh context; independent of the synthesizer and the judgment
auditor). Target `research/runs/R75/2026-09-26T190305Z-54dc44c45419/review/DECISION.md`,
revision 1. `shasum -a 256` printed
`7b936d861827d81e7f9bff2023b29511980864ec9c7d593b8034ba433ab7a4e5`. That equals the expected
hash, so the audit proceeded. The decision-shape rerun's own header line reports the same hash
(688 lines).

Scope: execution truth and evidence support only. Not read: any `review/audit-*.md`, any
`research/topics/[NN]-*/raw/`, or any `review/Rxx-r*-snapshot.md`. Made: no git writes, no
`scripts/research_runner.py` calls, no paid or submitting API calls.

## Environment

- macOS, `Darwin arm64`. Host `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`; floor
  `rustc 1.96.0 (ac68faa20 2026-05-25)` via `rustup run 1.96.0`.
- Private `CARGO_HOME=/tmp/cargo-s22-R75-emp`. It started empty, so `probe-crate.sh` resolved
  and downloaded fresh from crates.io.
- Probe directory `R75_PROBE_DIR=/tmp/r75-audit-probe`. This is independent of the
  synthesizer's `$TMPDIR/r75-synth-probe`.
- Fresh logs are in `/tmp/r75-audit/`; `evidence/` was not written.
- Working directory for every command: the run directory
  `research/runs/R75/2026-09-26T190305Z-54dc44c45419`.

## Reruns

Every command ran as
`R75_PROBE_DIR=/tmp/r75-audit-probe bash review/evidence/<script>.sh > /tmp/r75-audit/<script>.log 2> /tmp/r75-audit/<script>.err`,
followed by `cmp` and `diff` against `review/evidence/<script>.log`. Every script exited 0, and
every stderr file was empty.

| Script | Exit | Totals observed | `cmp` result | Diff content |
|---|---|---|---|---|
| `probe-crate.sh` | 0 | resolves; `Cargo.lock` sha256 `5e89a57d3a9d8513487aeee2fa4e2f07afde2eddc7c3584ae90c3be7b01d43cb` (**identical to the decision**); 58 unique normal-tree packages; 5 only through `tower-http` (`bitflags`, `cfg-if`, `getrandom`, `tower-http`, `uuid`); highest dependency `rust-version` 1.85; `hyper` features `default`/`http1`/`server` | differs at line 1, char 22 | Lines 1–2 (probe path, timestamp) and lines 37/40/44/55 (`r75probe v0.0.0 ($TMPDIR/r75-synth-probe)` → `(/private/tmp/r75-audit-probe)`). Everything else is byte-identical, including all six source sha256s and the resolved versions |
| `stack-acceptance.sh` (E1) | 0 | `== host: 15 pass, 0 fail`; `== 1.96.0: 15 pass, 0 fail` | differs at line 1, char 40 | Timestamp; per-request UUIDs; `duration_ms` values (A01b: committed 0.051 ms, rerun 0.057 ms. A12: committed 202.0 ms on the host and 202.2 ms on 1.96.0, rerun 202.0 ms and 202.5 ms, all ≥ 200 ms). Every PASS/FAIL label is identical |
| `negative-controls.sh` (E2) | 0 | `== 12 pass, 0 fail`; `test result: ok. 6 passed` | differs at line 1, char 41 | Timestamp; UUIDs in N01b, N03, N06; `finished in 0.01s` vs `0.00s`. N03 still shows `header=Some("original-111")` against a fresh event UUID |
| `framework-log-foldin.sh` (E3) | 0 | `== 4 pass, 0 fail`; tally `axum::serve TRACE 7`, `r75probe::http_access INFO 3`, `tower_http::catch_panic ERROR 1`; one std panic-hook line | differs at line 1, char 44 | Timestamp only |
| `figures.sh` (E4) | 0 | every endpoint answered; RustSec http 200/200/404/404 | differs at line 1, char 41 | Timestamp, and line 24: `REPO tower-rs/tower stars=4302` → `stars=4303`. Every download count, version, date, licence, `rust_version`, issue count and responsiveness figure is identical |
| `practice-check.sh` (E5) | 0 | 6 upstream files read at the same commit SHAs; `unsafe` census unchanged | differs at line 1, char 38 | Timestamp only |
| `decision-shape-check.sh` (E6) | 0 | `== 126 pass, 0 fail` | differs at line 1, char 44 | Timestamp, and C26–C37 cargo-home path prefix (`/tmp/cargo-s13-R75/` → `/tmp/cargo-s22-R75-emp/`). Every assertion is identical |

Result: all seven scripts reproduce. The only differences are the expected nondeterminism
(timestamps, random UUIDs, wall-clock durations, and the cargo-home and probe paths) plus one
GitHub star count that moved by one. None changes a PASS/FAIL outcome, a total, or a figure the
decision relies on.

## Load-bearing claims re-derived at source

| Decision claim | Re-derivation | Holds |
|---|---|---|
| Stock `PropagateRequestIdLayer` keeps an existing response id (`tower-http-0.7.1/src/request_id.rs:454-461`) | E6 C26 matches `if let Some(current_id) = response.headers()`; N03 rerun shows `original-111` echoed | yes |
| `Router::layer` wraps the fallback; its layer bounds are `Clone + Send + Sync` (`axum-0.8.9/src/routing/mod.rs:303-316`) | E6 C33/C34 pass on a freshly downloaded crate source; A06/A07 rerun log the 404s once | yes |
| `tower-http` declares `rust-version = "1.65"`, `#![deny(unsafe_code)]`, and its one `unsafe` site is a Windows-only fs test | E6 C29/C30; `grep` finds exactly one site, `src/services/fs/serve_dir/tests.rs:1246` (`GetFileType`) | yes |
| E1 passes on the 1.96.0 floor | rerun: `== 1.96.0: 15 pass, 0 fail` | yes |
| crates.io applies `from_fn(log_request::log_requests)` immediately outside `CatchPanicLayer` (`src/middleware.rs` 47–48 @ `30c4ed7f`) | E5 rerun: same SHA `30c4ed7fd9b7…`; lines 47–48 sit in a `ServiceBuilder`, where the first layer is outermost, so the log layer is outside `CatchPanicLayer` | yes |
| crates.io pins `axum = "=0.8.9"` and `tower-http = "=0.7.1"` with `catch-panic` and `timeout`; the timeout is 30 s and axum's example uses 10 s, both with `REQUEST_TIMEOUT` | E5 rerun: `Cargo.toml` lines 83 and 169; `middleware.rs` 88–90; `graceful-shutdown` line 43 | yes |
| Figures table (downloads, versions, dates, licences, MSRVs, stars, open issues, RustSec) | E4 rerun: identical except `tower` stars 4302 → 4303 | yes |
| tower-http responsiveness 2/10 answered, median 0.1 days; tracing 0/10 answered | E4 rerun: identical `RESPONSIVENESS` lines | yes |
| R69 `DECISION.md:1586` makes `tower` "a dev-dependency only" and writes `web = ["dep:axum", "dep:tokio"]` | read at source: both present on line 1586, plus "R72 to R76's middleware" inside the `web` tree | yes |
| R69 `DECISION.md:943-944` hands the per-request timeout to R75; `:1424` reserves `middleware.rs`; `:2197` hands C11 to R75 | read at source | yes |
| Run prompt snapshot and canonical prompt differ in exactly two lines (26 and 76) | `diff` shows only lines 26 and 76 | yes |
| The snippet mirrors the executed probe (`if_not_present`, HSTS `max-age=63072000; includeSubDomains`, overwrite echo, template exclusion list) | `/tmp/r75-audit-probe/src/lib.rs` lines 21, 32, 38, 44–48, 56 | yes |

## Observations (not findings)

1. **Engine swap (controller note a).** The run's `inputs/prompt.md` line 26 reads
   `- engines: codex, opus, doxa`, and `manifest.json` `required_engines` is
   `["codex","opus","doxa"]`. The canonical prompt names Muse, and `research/RUNBOOK.md:72-77`
   records Q17.A extending the substitution to R75. The decision discloses this itself (record
   note; gap 9), and no evidence script fails because of it. Repair: the controller re-freezes
   the inputs and cites Q17.A.
2. **Template-size wording is inconsistent.** Line 53 says "about 75 lines … (the header table
   and four functions)". Line 202 says "the header table and the two functions are the whole of
   the template code". The code block shows four functions (`security_headers`,
   `echo_request_id`, `access_log`, `apply_middleware`). The executed probe's `src/lib.rs` is
   105 lines including imports. This is editorial and affects no check or choice.
3. **The tower-http version coupling with R78 (controller note c) is not discussed.** R78
   reports that the OTel tree already contains `tower-http` 0.6.11, while R75 pins 0.7.1. The
   decision reserves slot L4 for R78 and lists R78's span decision as a re-verify trigger. It
   does not mention a possible 0.6/0.7 duplicate in the combined tree. The decision does not
   mishandle anything it states, so this is recorded for the controller to reconcile when R78
   is accepted. The probe tree contains no OTel crates, so E0's duplicate census cannot show
   the coupling.
4. **ubuntu-latest was not executed, and E4/E5 are network re-observations.** The decision
   states both limits itself. They are recorded here only for completeness.
5. **Inherited py facts.** py `setdefault` at `web/middleware.py:120`, the HSTS value, and py's
   order are marked inherited by the decision. The decision names them for this seat, but this
   seat's read scope did not include the py repository. They remain as the decision labels
   them: unverified, with N05/A13 showing that the alternative is a one-constructor switch.
   This limits this audit's coverage and is not a defect in the decision's evidence.
6. **The A12 duration quoted in the decision does not appear in its log.** Decision line 532
   quotes A12 `duration_ms` **201.2**. The committed `stack-acceptance.log` records
   `duration_ms=202.0` on the host and `duration_ms=202.2` on 1.96.0, and
   `grep -c 'duration_ms=201.2'` returns 0. The assertion is `duration_ms >= 200`, and it holds
   in every run, so no conclusion changes. Optional repair: quote 202.0 ms from the log.
7. **Evidence integrity.** `git status` lists `review/` as wholly untracked, so it cannot show
   whether `evidence/` changed. Two facts establish that it did not: every file in `evidence/`
   keeps its pre-audit modification time (20:57–21:11 on 2026-09-26), and every `cmp` difference
   is the nondeterminism described above. This file is the only one this seat wrote.

## Verdict

**approve.** Every committed check reran green on a fresh cargo home and a fresh probe
directory: E1 15/15 on 1.98.1 and 15/15 on 1.96.0, E2 12/12, E3 4/4, and E6 126/126. E0, E4 and
E5 reproduce their figures, and the lockfile hash is identical. Each load-bearing claim checked
at source holds. No unresolved findings.
