actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: ba104e3c2891b076d93c938c1ebc1c36a749315addce76ea5f37d28062fcf440
verdict: approve
unresolved-findings: none

# R78 — opentelemetry-integration — empirical audit of DECISION.md revision 1

Seat: fresh empirical auditor (Claude Opus family, `claude-opus-5-5`), independent of the
synthesizer and the judgment auditor. Scope: execution truth and evidence support only.
Audit date: 2026-09-27 UTC (US Pacific 2026-09-26).

## Binding

`shasum -a 256 research/runs/R78/2026-09-26T190312Z-8cf4b61ddead/review/DECISION.md` →
`ba104e3c2891b076d93c938c1ebc1c36a749315addce76ea5f37d28062fcf440`, equal to the expected hash.
The audit proceeded against that revision.

Read: the whole `DECISION.md` (869 lines), `research/RUNBOOK.md` §5, the three evidence scripts
and their committed logs, `inputs/prompt.md` (engines line only) and `manifest.json` (engines and
state only). Not read: any `review/audit-*.md`, any `raw/` report, any snapshot file.

## Environment

- Host: `Darwin 25.4.0 arm64`, macOS 26.4.
- Toolchain: `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1`, `rustup run 1.96.0` →
  `rustc 1.96.0 (ac68faa20 2026-05-25)`.
- Private `CARGO_HOME=/tmp/cargo-s22-R78-emp` and `CARGO_TARGET_DIR=/tmp/cargo-s22-R78-emp-target`
  (fresh, not the synthesizer's `/tmp/cargo-s13-R78`). The probe pins its own target dir inside
  its `$TMPDIR` workspace.
- Before running, each script was read for write targets. All three write only under
  `mktemp -d "${TMPDIR:-/tmp}/…"` and remove that directory on exit. None writes into `evidence/`.

## Reruns

Working directory for every command:
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R78/2026-09-26T190312Z-8cf4b61ddead/review/evidence`

| Script | Command | Exit | Fresh totals | Committed totals | `cmp` against committed log |
|---|---|---:|---|---|---|
| `r78-source-census.sh` | `bash r78-source-census.sh > /tmp/r78-emp/r78-source-census.log 2>&1` | 0 | `# TOTAL checks=26 pass=26 fail=0`; 0 skip | 26 / 26 / 0 | differ at char 41, line 1 |
| `r78-figures.sh` | `bash r78-figures.sh > /tmp/r78-emp/r78-figures.log 2>&1` | 0 | `# TOTAL checks=33 pass=33 fail=0`; 0 skip | 33 / 33 / 0 | differ at char 35, line 1 |
| `r78-probe.sh` | `bash r78-probe.sh > /tmp/r78-emp/r78-probe.log 2>&1` | 0 | `# TOTAL checks=41 pass=41 fail=0`; 0 skip | 41 / 41 / 0 | differ at char 33, line 1 |

Totals: **100 checks, 100 pass, 0 fail, 0 skip**, matching the decision's `## Empirical check`
table (33 + 26 + 41). No `SKIP` line appears in any fresh log.

The decision also claims that `shellcheck` exits 0 with no finding on all three scripts. Rerun:
`shellcheck r78-figures.sh r78-source-census.sh r78-probe.sh` (`/opt/homebrew/bin/shellcheck`,
ShellCheck 0.11.0) printed nothing and exited 0. Confirmed.

### What the byte differences are

Every `cmp` mismatch was inspected with `diff`. Each difference is a value the decision's
*Reproducibility* paragraph declares volatile. No `PASS`/`FAIL` line, no version, no dependency
edge and no source line differs.

**`r78-source-census.log`** — 2 hunks, both paths or timestamps:

```text
< # r78-source-census — run 2026-09-27T04:17:15Z (UTC)
> # r78-source-census — run 2026-09-27T06:13:26Z (UTC)
< # host: …; CARGO_HOME=/tmp/cargo-s13-R78
> # host: …; CARGO_HOME=/tmp/cargo-s22-R78-emp
```

Lines 102–104 (the `S19` `unsafe` listing) differ only in the `CARGO_HOME` prefix. The three
matches are identical: `filtered.rs:172`, `filtered.rs:176` and `layer.rs:1557`.

**`r78-figures.log`** — 2 hunks:

```text
< # r78-figures — run 2026-09-27T04:27:30Z (UTC)
> # r78-figures — run 2026-09-27T06:13:30Z (UTC)
< open-telemetry/opentelemetry-rust                     2718 false    2026-09-25T08:11:20Z 216
> open-telemetry/opentelemetry-rust                     2719 false    2026-09-25T08:11:20Z 216
```

One star count moved, from 2,718 to 2,719, in about two hours. Every download count,
reverse-dependency count, version, release date, `rust_version` and dependency requirement is
byte-identical.

**`r78-probe.log`** — only volatile values differ:

- run timestamp, `CARGO_HOME`, log-line timestamps and listening port;
- random span IDs, and the readiness probe's random root trace ID. The four spans in the fixed
  incoming trace `4bf92f3577b34da6a3ce929d0e0e4736` reproduce with the same shape: server
  `/demo` span parented on `00f067aa0ba902b7`; `demo.work` and the client span parented on it;
  `/downstream` server span parented on the client span;
- debug binary sizes: `svc-web` 12,592,488 → 12,593,096 bytes, `svc-otel` 16,960,824 →
  16,961,624 bytes;
- smoke timings: flag-off 1,705 → 1,725 ms, unreachable collector 1,729 → 1,709 ms,
  SIGTERM-to-exit 454 → 477 ms against the 2,000 ms budget, `otel_shutdown_ok elapsed_ms`
  442 → 469.

Deterministic observations reproduced exactly:

- exit 143 after SIGTERM in every scenario;
- 0 spans before SIGTERM, then 4 spans in the incoming trace;
- `D05`: 12 spans on `127.0.0.1:4318`;
- `D06`: 9 spans exported with `OTEL_SDK_DISABLED=true` and the guard off; `D07`: 0 with the guard on;
- the `otel_unavailable` message, verbatim;
- `retries=3` exhaustion lines;
- `syn v2.0.119;syn v3.0.6` as the only duplicate roots;
- `T05` metrics activation count 1;
- `strings | grep -c opentelemetry` equal to 0.

The decision's claim that 1,705 ms vs 1,729 ms shows "unchanged latency" holds up on rerun. The
order flipped (1,725 flag-off vs 1,709 exporting), which is noise, as the decision's "smoke
comparison, not a workload" framing says.

## Load-bearing figures re-derived at source

Each item was checked independently of the scripts' assertion logic. Crate sources were read
from the fresh `CARGO_HOME` registry extraction; registry data was fetched directly.

| Decision claim | Independent check | Result |
|---|---|---|
| `tracing-opentelemetry` 0.34.0 requires `opentelemetry ^0.33.0` and `tracing-subscriber ^0.3.22`; published 2026-09-23; `rust_version` 1.75.0 (`V01`, `V03`, `C02`, `C04`) | `curl https://crates.io/api/v1/crates/tracing-opentelemetry/0.34.0/dependencies` and `/versions` | `opentelemetry ^0.33.0`, `tracing-subscriber ^0.3.22`; `0.34.0 2026-09-23T08:25:46Z rv=1.75.0`; 0.33.0 dated 2026-05-18. Confirmed. |
| Unconfigured exporter defaults to `http://localhost:4318` at `exporter/mod.rs:55` (`S01`) | `sed -n 55p opentelemetry-otlp-0.33.0/src/exporter/mod.rs` | `const OTEL_EXPORTER_OTLP_HTTP_ENDPOINT_DEFAULT: &str = "http://localhost:4318";`. Confirmed at the cited line. |
| No crate in the set reads `OTEL_SDK_DISABLED` (`S03`) | recursive `/usr/bin/grep` over the `*.rs` files of all five crate sources | 0 matches. Confirmed. |
| `http-proto` pulls in `metrics`; otlp defaults include `logs` and `metrics` (`F01`, `F03`) | `opentelemetry-otlp-0.33.0/Cargo.toml` | `default = [http-proto, reqwest-blocking-client, trace, metrics, logs, internal-logs]`; `http-proto = [prost, opentelemetry-http, opentelemetry-proto/gen-tonic-messages, http, httpdate, trace, metrics]`. Confirmed verbatim. |
| Bounded queue of 2,048 spans (`S08`) | `opentelemetry_sdk-0.33.0/src/trace/span_processor.rs:63` | `pub const OTEL_BSP_MAX_QUEUE_SIZE_DEFAULT: usize = 2_048;`. Confirmed. |
| Default global propagator is `NoopTextMapPropagator` (`S14`) | `opentelemetry-0.33.0/src/global/propagation.rs:10` | `static DEFAULT_TEXT_MAP_PROPAGATOR: OnceLock<NoopTextMapPropagator>`. Confirmed. |
| `global::shutdown_tracer_provider` is absent in 0.33.0 (`S06`, Disagreement 6) | `grep 'fn shutdown_tracer_provider' opentelemetry-0.33.0/src` | 0 matches. Confirmed. |
| `tower-http` 0.6 enters through the exporter's blocking client (`V07`) | `reqwest-blocking-client = ["reqwest/blocking", …]` in the otlp manifest; `reqwest-0.13.5/Cargo.toml:436-440` | `tower-http` `version = "0.6.8"`, not optional, on every non-wasm32 target. Confirmed: the edge is unconditional for this template's targets. |
| The `unsafe` count in the bridge is three lines (`S19`, Disagreement 8) | fresh census listing | Same three lines at the same file:line locations. Confirmed. |

## Observations (not findings)

**O1 — engine-list staleness (controller note a).** `inputs/prompt.md:27` reads
`- engines: codex, opus, doxa`. `manifest.json` reads
`{"required_engines":["codex","opus","doxa"],"state":"ready"}`. The run collected a Muse leg
under Q17.A. The decision already flags this itself (context flags 2–4; Gaps 2–3). It is not a
synthesis defect. Repair: the controller re-freezes the inputs and cites Q17.A. The controller
also records the Muse leg's resolved model ID, which the decision reports as absent.

**O2 — conditional on R58 (controller note b).** The decision declares
`assumes logging-pipeline-contract = —` and lists five explicit conditions on R58. The probe's
`fmt` layer and `Option<L>` composition show that those conditions are achievable. They cannot
show what R58 will choose, and the decision states this (*What this check does not prove*, item
4). Acceptance waits on R58 publishing; that is controller business.

**O3 — the `tower-http` coupling with R75 (controller note c).** The decision states the tension
correctly. The `otel` tree carries `tower-http` 0.6.11 through `reqwest` 0.13.5. That edge is
unconditional on native targets, which the source check above confirmed. A `tower-http` 0.7.x
pick in R75 would therefore duplicate `tower-http` in `web,otel` builds. The decision routes the
issue to R75, adds it as a re-verify trigger, and adds P03 check 6. It is handled, not
mishandled.

**O4 — the probe's `web` baseline is wider than R69's `web`.** `r78-probe.sh:78` declares
`web = ["dep:axum", "dep:tokio", "dep:reqwest"]`. R69's registered `web` is
`["dep:axum", "dep:tokio"]`. The probe adds `reqwest` so that `/demo` can make its outbound call
in a web-only build. This has three consequences:

- The committed log's line `tower-http in the web-only tree: tower-http v0.6.11` describes the
  probe's tree, not R69's.
- The `+4.37 MB` debug delta (gate 6 row, *Representative cost*) is measured over a baseline that
  already contains `reqwest` 0.13.5 and its non-optional native client dependencies, such as
  `hyper-util` (`reqwest-0.13.5/Cargo.toml:347`, which has no `optional` key). It therefore understates `otel`'s increment over
  the template's real `web` build.
- The absence claims `T01` and `T06` stay valid a fortiori, because the probe's web tree is a
  superset of R69's.

The decision labels the size figure "not a release-profile size and … not a template figure".
Its qualitative note that `otel` "adds … blocking `reqwest`" is correct for the template. The
widening is disclosed only in the script's comment, not in the decision's prose. No conclusion
depends on it. Suggested clarification for a later revision, not required for this verdict: one
sentence in `## Empirical check` noting that the probe's `web` includes `reqwest` for the
outbound demo.

**O5 — single-host evidence.** Everything ran on macOS arm64 only. The decision says so
explicitly (Confidence; *What this check does not prove*, items 1–3). The `ubuntu-latest` leg,
a real Collector and release-profile cost are correctly left as P03 obligations.

## Verdict

**approve.** All three evidence scripts rerun green (100/100, 0 fail, 0 skip). Their logs
reproduce the committed logs except for volatile fields the decision itself names. Every
load-bearing source and registry figure checked above matches at the cited version and line.
The executed end-to-end path covers the RUNBOOK §5 elements R78 claims:

- an incoming request and its handler;
- an outbound operation;
- W3C propagation in and out;
- export decoded at a real OTLP/HTTP receiver;
- exporter failure;
- shutdown.

The metrics element is correctly disclaimed as R79's. No claim in the decision was found
unsupported by its cited evidence.
