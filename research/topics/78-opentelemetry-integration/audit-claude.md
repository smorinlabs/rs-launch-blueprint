# R78 opentelemetry-integration — empirical re-run audit, revision 3 (Codex seat, Q23 §7.3)

decision-sha256: 35c4b50a71c6ef6109e27b646d1c5b51bed757f05b9b8ed6fcd6ad04927b1a9c
actor: codex-empirical-r78-r3
model: claude-opus-5-5
family: anthropic
verdict: approve
unresolved-findings: none
execution-pin-sha256: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
run-utc: 2026-09-29T17:59Z to 2026-09-29T18:03Z

## Seat and identity

The filename names the Codex empirical seat. The engine that performed this audit is Anthropic's
Claude Opus 5.5 (`claude-opus-5-5`), not an OpenAI model; the `model:` and `family:` lines
above report that true identity. The controller should weigh this in any family-diversity check.

## Scope

This is an empirical re-run of the three committed evidence scripts, performed under the Q23
box in RUNBOOK §7.1–§7.3. It includes no judgment audit and no verifier pair. Nothing was
fixed. The decision hash was verified before any other file was read, and recomputed just
before this file was written. Both values were
`35c4b50a71c6ef6109e27b646d1c5b51bed757f05b9b8ed6fcd6ad04927b1a9c`.
The `research/EXECUTION.json` hash equals the S87 pin above. Drift from the pin is not a
finding (no-repin rule, §7.7).

**Method.** Each script was run unmodified from `review/evidence/`, the working directory the
decision's `## Empirical check` names. Each ran in the foreground as `bash <script> >
/tmp/s87-r78-rerun/<script>.log 2>&1`, with `CARGO_HOME=/tmp/cargo-s87-r78` and
`CARGO_TARGET_DIR=/tmp/cargo-s87-r78-target`, both freshly created. `r78-probe.sh` pins its own
target directory inside its `$TMPDIR` workspace by design. The network was live, and no
offline registry copy was needed.

**Byte-identity.** The sha256 of all three scripts, all three committed logs, and all six
priors was taken before the reruns and re-checked afterwards. Every hash was unchanged.

| File | sha256 (before = after) |
|---|---|
| `r78-figures.sh` | `babfa9c324f26f75fcfec12ea7a844c1692e589bb03883d1e4cf1b19c0b9e6bd` |
| `r78-source-census.sh` | `aaaae3fb87754ea85e56c96fa7d65af39a42b33c83bcf225089b02ed6e2fdc38` |
| `r78-probe.sh` | `cc600139c545b452b2a048b73ee4c41d3cbc070449cfaec2029d55e83e84d03a` |
| `r78-figures.log` (committed) | `8a34007996c07ecdeecdf0c5c2710a120f8cadeb32426e6f415e56064fe08d53` |
| `r78-source-census.log` (committed) | `38e7ff187216f316a264b2a95e3ce9c15cf94dcce410d8f7bc1c4a2429ce793e` |
| `r78-probe.log` (committed) | `2cc5610e0f651d37a64589f95738cc9e76cf0634ee9a685b69480c1568f999f5` |

## Rerun totals

| Script | Exit | Committed | Fresh | Byte compare against the committed log | Fresh log (sha256) |
|---|---:|---|---|---|---|
| `r78-figures.sh` | 1 | 33/33 pass | **32/33 pass**, `FAIL V04` | differs | `/tmp/s87-r78-rerun/r78-figures.log` (`a35cf790…`) |
| `r78-source-census.sh` | 0 | 26/26 pass | 26/26 pass; every PASS line is byte-identical | differs only in the header and scratch paths | `/tmp/s87-r78-rerun/r78-source-census.log` (`57b86b05…`) |
| `r78-probe.sh` | 0 | 41/41 pass | 41/41 pass; the same check IDs and statuses | differs only in nondeterministic values | `/tmp/s87-r78-rerun/r78-probe.log` (`56d81549…`) |

Across the three scripts, 99 of 100 assertions pass. The one failure is `V04`, the
pre-accepted OBS-1 described below.

**shellcheck.** ShellCheck 0.11.0 (`/opt/homebrew/bin/shellcheck`) exits 0 with empty output on
`r78-figures.sh`, `r78-source-census.sh` and `r78-probe.sh`. This agrees with the decision's
statement that shellcheck exits 0 with no finding on all three scripts.

## Comparison with the decision's claims

The fresh results reproduce every load-bearing claim of the decision:

- **The recommended pairing.** `V01` passes: the bridge 0.34.0 requires `opentelemetry ^0.33.0`.
  `V02` passes: the bridge 0.33.0 requires `^0.32.0`. The probe resolved `opentelemetry v0.33.0`
  and `tracing-opentelemetry v0.34.0`, a single generation (`T02`–`T04`). The tree compiled
  under Rust 1.96.0 (`M01`).
- **The runner-up's winning condition is still unmet.** `V06` passes: the newest
  `reqwest-tracing` release (0.7.1) still offers no `opentelemetry_0_33` feature.
- **The source census matches.** All 26 checks pass, including the localhost default (`S01`),
  the invalid-endpoint `Err` (`S02`), `OTEL_SDK_DISABLED` not being read (`S03`), default
  retries (`S04`), and the OS-thread batch export (`S07`). The three `unsafe` lines appear at
  the same sites in `tracing-opentelemetry` 0.34.0 (`layer.rs:1557`, `layer/filtered.rs:172`,
  `:176`).
- **The degrade contract matches.** The four-span chain came back with the fixed incoming
  trace ID `4bf92f3577b34da6a3ce929d0e0e4736` and the parent `00f067aa0ba902b7`. The collector
  held 0 spans before SIGTERM and all 4 afterwards, and the exit code was 143 (`E01`–`E13`).
  With no endpoint set, 12 spans arrived on `127.0.0.1:4318` (`D05`). With
  `OTEL_SDK_DISABLED=true`, the SDK alone exported 9 spans and the guarded build exported 0
  (`D06`, `D07`). An invalid endpoint produced exactly one `otel_unavailable` warning, with the
  same error text as the committed log (`D08`, `D09`). With a dead collector, 100/100 requests
  returned 200, and each exhausted batch logged the same WARN and ERROR lines (`D10`–`D14`). A
  web-only build with OTLP variables set logged the `otel_ignored` warning (`W01`–`W03`).
- **Binary sizes.** The debug, unstripped binaries were 12,592,488 bytes (`web`) and
  16,960,824 bytes (`web,otel`), identical to the committed log.

No fresh outcome contradicts a claim of the decision. The STOP trigger did not fire.

## Findings

**BLOCKING:** none.

## Observations (disclose-only; nothing was fixed)

- **OBS-1 — `V04` is still FAIL. This is the pre-accepted OBS-1 of `review/audit-codex.r2.md`.**
  - *Status:* `axum-tracing-opentelemetry` 0.42.1 and `tracing-opentelemetry-instrumentation-sdk`
    0.42.1 (both released 2026-09-27) require `opentelemetry ^0.33` and
    `tracing-opentelemetry ^0.34`. `init-tracing-opentelemetry` 0.43.0 requires `^0.33`.
  - *Consistency with revision 3:* this is exactly the 32/33 result that revision 3's own
    note discloses (ruling 5, `DECISION.md:19`), and no further glue release appeared.
  - *What is superseded:* the body's present-tense "pins 0.32" wording is superseded for these
    crates (`DECISION.md:351`, `:463`, `:500`).
  - *Why it does not block:* the runner-up needs `reqwest-tracing` as well, and `V06` still
    passes. It also needs macOS evidence for the server glue, which remains uncorroborated.
    `review/audit-fable.r2.md` accepted this item as the decision's re-verify trigger, not a
    new round.
- **OBS-2 — live counters moved, as the decision discloses at `DECISION.md:702-707`.** The
  following figures changed since the committed log:
  - download counts;
  - stars: `opentelemetry-rust` 2,718 → 2,722, `tracing-opentelemetry` 409 → 411;
  - reverse dependencies: `opentelemetry_sdk` 1,294 → 1,302, `opentelemetry-otlp` 1,003 → 1,007,
    `tracing-opentelemetry` 1,056 → 1,059, `reqwest-tracing` 108 → 109;
  - push times;
  - open-issue counts: `opentelemetry-rust` 216 → 217.

  The `opentelemetry-rust` responsiveness sample also moved. The decision records 3 answered
  issues with a median of 0.1 days and 7 unanswered (`DECISION.md:435-438`). The fresh sample
  has 6 answered with a median of 2.3 days and 4 unanswered. This does not change the
  maintenance verdict, for three reasons:
  - the rubric verdict **active** rests on push recency and release date (`DECISION.md:434-435`);
  - the decision excludes the unanswered count from the rubric (`:437`);
  - the decision discloses the responsiveness sample as time-varying (`:703`).
- **OBS-3 — census scratch paths differ.** Only the UTC header, `CARGO_HOME`, the registry
  source root, and the three absolute `unsafe` paths differ (`/tmp/cargo-s13-R78` →
  `/tmp/cargo-s87-r78`). All 26 check lines are byte-identical.
- **OBS-4 — probe nondeterminism.** The run time, `CARGO_HOME`, build wall time (30 s → 35 s),
  generated span IDs, the readiness-probe trace ID, the listener port, and log timestamps
  differ. Timings also moved:

  | Timing | Committed | Fresh |
  |---|---:|---:|
  | Flag-off baseline, 100 requests | 1,705 ms | 1,733 ms |
  | Unreachable collector, 100 requests | 1,729 ms | 1,750 ms |
  | SIGTERM-to-exit | 454 ms | 495 ms |
  | Shutdown with a dead collector (`otel_shutdown_ok`) | 442 ms | 478 ms |
  | Clean shutdown | 11 ms | 10 ms |

  The decision discloses all of these as varying per run (`DECISION.md:704-706`). Unlike the
  r2 rerun, the binary sizes this time were byte-identical to the committed log.
- **OBS-5 — the evidence scripts are untracked in git at HEAD `491e47e6`.**
  `git status` lists the three `r78-*.sh` files as `??`, while the committed logs are tracked.
  The prior `review/R78-r2-snapshot.md` is also untracked (`??`); its byte-identity was
  verified regardless. Commit `1d34556c` is the last commit to touch `r78-figures.log`. Its
  message says that evidence scripts were excluded from that batch. That R78's scripts were
  excluded for the same reason is an inference from the message, not something it states. The
  rerun used the on-disk bytes, whose hashes are recorded above. "As committed" therefore means as present in
  the run directory. The pre-existing working-tree changes under this run's `inputs/`,
  `manifest.json` and `DECISION.md` were not touched, and are inputs drift under standing rule 1.

## Constraint compliance

No git write was made to the checkout, and no runner, ledger, `inputs/` or `EXECUTION.json`
write was made. No script, log, snapshot or prior was modified. The only file this audit adds to
the checkout is `review/audit-codex.r3.md`. Fresh logs are under `/tmp/s87-r78-rerun/`. No
paid or submitting API was called; the scripts made only their own read-only public HTTP
queries.
