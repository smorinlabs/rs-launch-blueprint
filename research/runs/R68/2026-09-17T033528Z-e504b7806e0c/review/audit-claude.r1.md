actor: audit-claude-r68r1-s4
model: claude-opus-5-5
family: anthropic
decision-sha256: 070b7ae10b4a3de48d8b1a1d7cb4799c18d4bfec92713f7d30776128e4578fd7
verdict: reject
unresolved-findings:
1. EA-1 — `profile-probe.sh` fails as committed on the documented host (exit 1), and gives no route to the toolchain it demands.
2. EA-2 — the stated byte-for-byte reproduction rule for `profile-probe.sh` is false for an independent rerun at the same rustc version; the probe's dependency graph and toolchain distribution are unpinned.

# R68 revision 1 — empirical audit (seat claude)

Target: `research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md`.
`shasum -a 256` recomputed `070b7ae10b4a3de48d8b1a1d7cb4799c18d4bfec92713f7d30776128e4578fd7`,
equal to the expected revision-1 hash. Scope: execution truth and evidence support only
(RUNBOOK §5); the recommendation's wisdom is not judged. No `review/audit-*.md`, no
`raw/`, and no snapshot file was read.

## Host of this rerun

2026-09-26, macOS 26.4 (25E246), Apple M4 Pro, `aarch64`, the same machine model the
decision names. Host toolchain on `PATH`: `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`,
`cargo 1.98.1`. `gh version 2.101.0`. Private `CARGO_HOME=/tmp/cargo-s4-r68-emp`.
Every script was run from `review/evidence/` with output redirected to `/tmp/s4-r68-emp-*.log`;
nothing under `evidence/` was written.

## Reruns

| # | Command (cwd `review/evidence/`) | Exit | Totals | cmp against committed log |
|---|---|---|---|---|
| 1 | `./decision-self-check.sh > /tmp/s4-r68-emp-decision-self-check.log 2>&1` | 0 | 22 ok / 0 fail / 0 skip, `RESULT: PASS` | differs at line 2 only: `date(UTC): 2026-09-17T15:43:01Z` vs `2026-09-26T22:25:55Z`. The `DECISION.md` byte-count line is identical, so the self-check ran against the audited bytes |
| 2 | `./artifact-sources.sh > /tmp/s4-r68-emp-artifact-sources.log 2>&1` | 0 | 26 ok / 0 fail, `RESULT: PASS` | differs only on volatile line classes the decision predicts: `date(UTC)`, the `gh:` version header (2.98.0 → 2.101.0), one `HEAD` sha (cargo-binstall `SUPPORT.md`, `94dc7fe4…` → `422f3094…`), and `FIGURE` counters (lines 169–175, 196). Every `PINNED` and `ASSERT` line is byte-identical; `registry-gap-present=1` still holds |
| 3a | `./profile-probe.sh > /tmp/s4-r68-emp-profile-probe.as-is.log 2>&1` (host toolchain) | **1** | 0 ok / 1 fail | aborts at the toolchain guard: `ASSERT FAIL: rustc is not rustc 1.98.0` |
| 3b | same, with `PATH` led by a rustup-installed `1.98.0-aarch64-apple-darwin` in `RUSTUP_HOME=/tmp/s4-r68-emp-rustup` (`--profile minimal`) | 1 | 19 ok / 2 fail | invalid run, recorded for honesty: that toolchain's `rust-objcopy` could not load `@rpath/libLLVM.dylib`, so Cargo's stripping step failed with `signal: 6 (SIGABRT)` and every size was inflated (baseline 2 095 912 B; `strip=symbols` `-0.0%`, frames=4). Caused by my scratch toolchain, not by the script |
| 3c | as 3b after symlinking `lib/libLLVM.dylib` into `lib/rustlib/aarch64-apple-darwin/lib/` of the scratch toolchain | 0 | 21 ok / 0 fail, `RESULT: PASS` | differs: header lines (`(Homebrew)` suffix absent), `thiserror 2.0.20` → `2.0.21`, every `SIZE` line, and several `DELTA`/`ASSERT` lines (below). All `BACKTRACE` lines and the `at ./src/` 2→0 line are byte-identical |
| 3d | a `/tmp` copy of the probe, identical except `cargo update thiserror@2.0.21 --precise 2.0.20` after `generate-lockfile`, same toolchain as 3c | 0 | 21 ok / 0 fail | `SIZE` lines still differ (e.g. baseline 1 993 872 vs 1 994 112; recommended 1 488 064 vs 1 504 576), so the `thiserror` drift is not the whole cause |

Re-derived figures, run 3c/3d against the decision's table (same deltas in both runs):

| Row | Decision | This rerun |
|---|---|---|
| `lto="thin"` | −1.3% | −1.3% |
| `lto="fat"` | −19.8% | −19.8% |
| `codegen-units=1` | −14.9% | −14.8% |
| `thin`+`cu1` (owner reference) | −16.0% | −16.8% |
| `fat`+`cu1` (recommended) | −24.5% | −25.4% |
| `opt-level="s"` / `"z"` | +13.0% / +21.8% | +13.0% / +21.8% |
| `strip="symbols"` | −22.9% | −22.9% |
| `strip="debuginfo"` | byte-identical no-op | byte-identical no-op (1 993 872 == 1 993 872) |
| `panic="abort"` | −20.3% | −20.2% |
| `debug="line-tables-only"` | +12.5% | +14.5% |
| backtrace frames / exit (baseline, recommended, strip, abort, line-tables) | 4/101, 4/101, 0/101, 2/134, 5/101 | identical |

Arithmetic check of the committed log: every `DELTA` recomputes from its `SIZE` pair
(e.g. (1 504 576 − 1 994 112) / 1 994 112 = −24.55%). Cargo Book profiles page, fetched
2026-09-26: `strip` "The default is "none"", and the `release` defaults block lists
`strip = "none"` — the decision's documented-default column holds. The COMMONALITY line
citations (218, 224, 78), the owner-review sections, and the owner-reference quotes are
asserted by run 1 and hold.

**Evidence support, net.** Every directional claim and every threshold `ASSERT` the
decision rests on (fat beats thin; `s`/`z` larger; `strip=symbols` empties the backtrace;
`strip=debuginfo` a no-op; abort exits 134; line tables do not travel; thin+cu1 short of
−20%; fat+cu1 past −20%) reproduced. The Subject A endpoint claims reproduced. The two
findings concern the executability and reproduction statements of `profile-probe.sh`,
not the direction of any measurement.

## Findings

### EA-1 — the probe fails as committed on the documented host

- **Failed claim.** `## Empirical check`: "`./profile-probe.sh > profile-probe.log 2>&1   # exit 0, RESULT: PASS, 21 assertions`", and re-verify trigger (4): "re-run `review/evidence/profile-probe.sh` at the new toolchain".
- **Evidence.** Run 3a, same host model, 9 days later: exit 1, `ASSERT FAIL: rustc is not rustc 1.98.0`. The host's Homebrew rust moved to 1.98.1 and Homebrew keeps no 1.98.0. The guard is sound, but neither the script nor the decision says how to obtain the pinned toolchain; an auditor must improvise one (runs 3b–3c), and a rustup `--profile minimal` 1.98.0 then needs a manual `libLLVM.dylib` fix before its builds are valid. Re-verify trigger (4) itself asks for a rerun "at the new toolchain", which this guard refuses by construction.
- **Repair.** Make the pinned toolchain obtainable from the script: select it explicitly (for example `cargo +1.98.0` / `rustup run 1.98.0`, with a stated `rustup toolchain install 1.98.0` prerequisite) or accept a toolchain argument; name the distribution the committed log came from (Homebrew); and reconcile trigger (4) with the guard (a toolchain override that relabels the output, or state that a new-toolchain rerun produces a new log rather than a comparison).

### EA-2 — the byte-for-byte reproduction rule does not hold for an independent rerun

- **Failed claim.** Script header: "every `SIZE`, `DELTA`, `BACKTRACE` and `ASSERT` line reproduces byte-for-byte on a rerun at the same toolchain". `## Empirical check`, reproduction rule: "`profile-probe.log` was re-run once: **every `SIZE`, `DELTA`, `BACKTRACE` and `ASSERT` line reproduced byte-for-byte**", on which the decision rests "this decision states size deltas as measurements".
- **Evidence.** `profile-probe.sh:215` runs `cargo generate-lockfile` at run time, so the dependency graph floats with crates.io: run 3c resolved `thiserror 2.0.21` where the log records `2.0.20`. With that pinned back (run 3d) at rustc 1.98.0 (rustup distribution, different `CARGO_HOME` and `TMPDIR` paths), `SIZE` lines still differed and three `DELTA`s moved: `thin`+`cu1` −16.0% → −16.8%, recommended −24.5% → −25.4%, `debug="line-tables-only"` +12.5% → +14.5%, with matching `ASSERT` text changes. Run 3d pinned only `thiserror`; every other package in the 52-line (93 with all features) graph was resolved fresh, and the log prints only direct-dependency versions, so transitive drift is not visible. The residual difference therefore has at least three candidate causes that this audit did **not** separate: transitive dependency drift, toolchain distribution (rustup vs Homebrew build of 1.98.0), and absolute paths embedded in the binary (`CARGO_HOME`, probe root). What is established is that byte identity depends on more than the rustc version, and that the unpinned lockfile is one proven cause. The decision's headline figures are thus one host's measurement, reproducible in direction and to within about 1 percentage point (2.0 pp for line tables), not byte-for-byte.
- **Repair.** First-order: pin the probe's whole graph (embed the `Cargo.lock` the committed log was produced from and build with `--locked`). Second-order, not established by this audit: record the environment inputs that change bytes (toolchain distribution, `CARGO_HOME`, probe-root path, or apply `--remap-path-prefix` / `trim-paths` to remove path dependence); and restate the reproduction rule in the script header and in `## Empirical check` as what an independent rerun can meet — directions and `ASSERT` outcomes exact, `DELTA` within a stated tolerance — or show that byte identity holds once those inputs are pinned.
