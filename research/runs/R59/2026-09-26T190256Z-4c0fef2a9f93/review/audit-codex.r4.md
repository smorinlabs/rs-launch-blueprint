decision-sha256: be55fb7821967a92c8df25a86d0707eb42f73caa33dcc798501e9967ec7eb1ff
actor: codex-empirical-r59-r4
model: claude-opus-5-5
family: anthropic
verdict: approve
unresolved-findings: none
execution-pin-sha256: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
seat: codex (the filename names the seat; the engine that ran this audit is Claude Opus 5.5, Anthropic)
audit-date: 2026-09-29 (UTC)
rerun-logs: /tmp/s87-r59-rerun/

# R59 — empirical rerun audit, revision 4 (Codex seat)

## Scope

This audit is a rerun only. It follows `research/RUNBOOK.md` §7 (Q23, round economy), which
was read for this audit. §7.3 makes the audit past revision 1 one empirical rerun worker whose
job is to report deltas honestly. §7.1 makes only BLOCKING findings cost a round. This audit
makes no judgment of the design and runs no verifier pair. The target is `review/DECISION.md`, revision 4. Its
sha256 was checked before any other read and again just before this file was written. Both
checks matched the expected value.

`research/EXECUTION.json` hashed to the S87 pin above. Drift against that pin is never a finding.

Of the priors, only `review/audit-codex.r2.md` and `review/audit-codex.r3vo.md` were opened. They
were used for context and for the header layout. The other prior audits and the r1–r3 snapshots
were not read; they were only hashed in the integrity manifest. The revision-4 decision is
authoritative.

## Which checks were rerun

The brief says "all 11 checks". The decision itself claims 13 checks and 137 assertions
(`DECISION.md:45`, `:843-844`). The two extra checks are K (`r59-reload-slot.sh`) and J
(`r59-contract-adopt.sh`), which are new in revision 4 (`DECISION.md:59`). Following the
decision, this audit reran all 13 checks. `r59-common.sh` is the shared helper, not a check
(`DECISION.md:829-831`).

Every script was run unmodified from the repository root, in the order listed at
`DECISION.md:837-841`. Each log went to `/tmp/s87-r59-rerun/r59-<check>.log`, never into the
checkout. Environment: `CARGO_HOME=/tmp/cargo-s87-r59`, `CARGO_TARGET_DIR=/tmp/cargo-s87-r59-target`,
network reachable, so no offline fallback was used. Host: `rustc 1.98.1` (Homebrew), plus
`rustup` toolchain 1.96.0 for check H.

## Rerun results

"Bytes" compares the fresh log with the committed log using `cmp`. "Stream" compares only the
`PASS`, `FAIL` and `SUMMARY` lines of the two logs.

| Check | Script | Exit | Pass / fail | Decision claims | Bytes | Stream |
|---|---|---|---|---|---|---|
| T | `r59-toolchain.sh` | 0 | 4 / 0 | 4/4 | differ, line 2 | identical |
| S | `r59-source-reads.sh` | 0 | 22 / 0 | 22/22 | differ, line 2 | identical |
| P | `r59-deps.sh` | 0 | 5 / 0 | 5/5 | differ, line 2 | identical |
| W | `r59-writer-contract.sh` | 0 | 29 / 0 | 29/29 | differ, line 2 | identical |
| A | `r59-floor.sh` | 0 | 11 / 0 | 11/11 | differ, line 2 | identical |
| E | `r59-ansi.sh` | 0 | 3 / 0 | 3/3 | differ, line 2 | identical |
| C | `r59-exit-durability.sh` | 0 | 4 / 0 | 4/4 | differ, line 2 | identical |
| G | `r59-precedence.sh` | 0 | 3 / 0 | 3/3 | differ, line 2 | identical |
| H | `r59-msrv.sh` | 0 | 4 / 0 | 4/4 | differ, line 2 | identical |
| D | `r59-bench.sh` | 0 | 3 / 0 | 3/3 | differ, line 2 | identical |
| L | `r59-live-figures.sh` | 0 | 22 / 0 | 22/22 | differ, line 2 | identical |
| K | `r59-reload-slot.sh` | 0 | 11 / 0 | 11/11 | differ, line 2 | identical |
| J | `r59-contract-adopt.sh` | 0 | 16 / 0 | 16/16 | differ, line 2 | identical |
| **Total** | 13 checks | all 0 | **137 / 0** | 137, 0 failed | 13 of 13 differ | 13 of 13 identical |

Line 2 of every log is `run (UTC): …`. That is the first expected difference named in the
decision's reproducibility paragraph (`DECISION.md:865-872`).

The other differences, checked with `diff`, are all in the classes that paragraph lists:

- Cargo target and registry paths: `cargo-s81-r59-r4` became `cargo-s87-r59`.
- Scratch paths and event timestamps: W, A, E and K.
- Test print order: G.
- Compile time: H, 14.93 s became 10.82 s.
- C's `non_blocking` lines on disk after exit, runs 1/2/3: `105 0 87` became `184 169 123`.
  These are still below 1,000, which is the only thing asserted.
- D's timings, in ms per 100,000 events:
  - owned, blocking: `233/210/212` became `199/193/195`;
  - `file-rotate` `BytesSurpassed`: `293/233/424` became `228/239/268`;
  - owned plus `non_blocking`: emit `46/47/48` became `46/46/47`, and totals `164/164/233`
    became `180/157/164`.
- L's live counters: `tracing-subscriber` recent/all-time downloads `148039380/630176174`
  became `148206368/631890803`. `tokio-rs/tracing` stars `6893` became `6895`, and open
  issues stayed at `630`. The other crates' download counters also moved.
- L's retrieval date became `2026-09-29`.

L's newest versions, `rust_version` fields and licences are unchanged. L's assertions all passed.

**No rerun contradicts a decision claim.** The stop trigger did not fire.

## shellcheck

- Version: `ShellCheck 0.11.0`.
- Command: `shellcheck -x research/runs/R59/2026-09-26T190256Z-4c0fef2a9f93/review/evidence/*.sh`,
  over 14 files: 13 checks plus `r59-common.sh`.
- Exit code: 0, with no finding. This matches `DECISION.md:843-844`.

## Claims confirmed at the cited lines

**1. Reload slot behavior.**

The decision cites `tracing-subscriber` `reload.rs:289-297` (`DECISION.md:632`, `:862`). In the
0.3.23 source that this rerun's check K fetched
(`/tmp/cargo-s87-r59/registry/src/index.crates.io-1949cf8c6b5b557f/tracing-subscriber-0.3.23/src/reload.rs`):

```
289	    /// [`Handle::reload`] cannot be used with the [`Filtered`] layer; use
290	    /// [`Handle::modify`] instead (see [this issue] for additional details).
```

The probe's `slot` scenario matches the sketch at `DECISION.md:643-644` and `:659-660`. In
`review/evidence/r59-check/src/main.rs`:

- `:321`: `"slot" => {`
- `:324`: `reload::Layer::<LevelFilter, Registry>::new(LevelFilter::OFF)`
- `:325`: `reload::Layer::<Body, Registry>::new(None)`
- `:330`: `try_init()`
- `:344`: `body_h.reload(Some(body))`
- `:345`: `filter_h.modify(|f| *f = LevelFilter::DEBUG)`

The rerun log `/tmp/s87-r59-rerun/r59-reload-slot.log` passes the claimed behavior:

- `:19` K01: `expected=[1] actual=[1]`.
- `:35` K03: the slot is empty and `current` is `warn`.
- `:37` K05: `Ok(())/Ok(())`.
- `:38` K06: after attach, `current` is `debug`.
- `:39` K07: `1/1/0`. The file holds the post-attach debug and warn events and no pre-attach
  event.

These match `DECISION.md:694-697` and `:862`.

**2. `JsonEvent` / `JsonFields`.**

The pinned R58 revision-2 snapshot hashed to `8dc8ce95…c8867aae`, the value check J pins (J01).
Its line `:633` reads: "`JsonFields` plus `JsonEvent` for the structured one." Rerun J15 passes
at `r59-contract-adopt.log:34`.

The decision uses them at `DECISION.md:657`:
`FileFormat::Json => l.event_format(JsonEvent).fmt_fields(JsonFields)…`. It also uses them at
`:765-766`, as working assumption 4.

**3. `telemetry::init`.**

`R58-r2:1485`, the owned value, contains all three of these phrases:

- "exactly one telemetry::init(Profile) -> Init in the root package's src/telemetry.rs, called
  first in each binary's main before anything that can log";
- "init never panics";
- "the structured profile uses a template-owned FormatEvent plus a template-owned JSON
  FormatFields".

The sink-slot promise is at `R58-r2:654-657`: "a second `Layer` with its own `MakeWriter` and
its own per-layer `Filter`". The early-logging need is at `R58-r2:474-477`.

The rerun's J05 (`:13`, `cmp` same), J07 (`:15`), J08 (`:16`), J10 (`:18`) and J11 (`:19`) all
pass. The decision claims these at `DECISION.md:680-683` and `:746`. There is exactly one
`re-verify:` line, at `DECISION.md:731` (J16).

## Checkout integrity

Before the reruns, a sha256 manifest of all 51 files in the run directory was taken. It was
retaken after this audit was written. `diff` between the two manifests shows exactly one
change: the added line for `review/audit-codex.r4.md`. No `target/` directory appeared under
`review/evidence/r59-check/`. No committed log, script, snapshot, prior audit or decision file
changed. No log was written under `review/`. The only file this audit adds is this one.

## Findings

BLOCKING: none.

## Observations (disclosed, not fixed)

- **OBS-1. Check count.** The brief says 11 checks. The revision-4 decision claims 13 checks and
  137 assertions (`DECISION.md:45`, `:844`). This audit reran 13 checks, as the decision
  specifies.
- **OBS-2. The run directory is untracked in git.** `git status` shows the whole run directory
  as `??`. `git ls-files` lists 0 files under it, and `git log` has no commit for it. The "committed" logs compared here are the bytes
  on disk at audit time, not bytes in git history.
- **OBS-3. The owned value describes the redacting formatters but does not name them.**
  `R58-r2:1485` contains zero occurrences of the names `JsonEvent`, `JsonFields` or
  `HumanFields`. It describes them structurally ("template-owned FormatEvent plus a
  template-owned JSON FormatFields"). The names are at `R58-r2:632-633`. Two places in the
  decision attribute the names to `:1485`:
  - `DECISION.md:604`, AC7: "(`R58-r2:1485`, redaction clause)";
  - `DECISION.md:863`, check J: "the owned text says … `JsonEvent`/`JsonFields`".

  J10 asserts the descriptive phrase, and J15 asserts the names at `:633`. Both pass, so no
  assertion outcome is affected. This is a citation-precision nit.
- **OBS-4. D8 direction.** In this rerun, `file-rotate` `BytesSurpassed` (228–268 ms) was again
  slower than owned code (193–199 ms). This is the same direction as the revision-4
  observation at `DECISION.md:82-86`. Only completion is asserted, so this is not a finding.
- **OBS-5. EXECUTION pin.** `research/EXECUTION.json` hashed to the S87 pin. No drift was
  observed, and drift is not a finding in any case.

## Totals

13 of 13 scripts exited 0, with 137 passed, 0 failed and 0 skipped. Byte comparison: 13 of 13
logs differ, all first at line 2 (`run (UTC)`). `PASS`/`FAIL`/`SUMMARY` streams: 13 of 13
identical. `shellcheck -x`: ShellCheck 0.11.0, exit 0.
