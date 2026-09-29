# R30 revision 3 — empirical re-run r3d (Codex seat)

This is a Q23 rerun-only audit (RUNBOOK §7.1, §7.3). It reruns the full eight-script evidence suite of `review/DECISION.md` revision 3 unmodified, runs shellcheck, and compares the outcomes with the decision's recorded claims and figures. It does not judge the decision, re-decide anything, or fix anything. New nits are recorded as observations (OBS-n) only.

decision-sha256: 163ba8334d75debd3add4d620269e8608bf2164c5b0cd6fc464147fca9eb6cf5
actor: codex-empirical-r30-r3d
model: claude-opus-5-5
family: anthropic
verdict: approve
unresolved-findings: none
execution-pin-sha256: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
rerun-date: 2026-09-29 (UTC log stamps 2026-09-29T18:08Z–18:09Z)

**Seat disclosure.** This audit files under the Codex seat name (`audit-codex.r3d.md`). The engine that executed it was `claude-opus-5-5` (Anthropic). The `model` and `family` lines state that true identity. The file name records the seat only. Whether the seat-family mismatch needs a §7.6 amendment is the controller's call (OBS-5).

## Verdict basis

No rerun contradicts a claim in the decision. All seven empirical scripts exit 0. Each reproduces its committed PASS count, and each committed case keeps its label, its exit code and its `units re-checked` count, in the same order. `r30-inputs.sh` exits 5. All five of its failures are drift in live or frozen inputs, a manifest re-snapshot, or line-number drift. Standing rule 1 makes that drift disclose-only (OBS-1). Timing figures moved in the direction of lower cost (OBS-2). The STOP trigger did not fire.

## Preliminaries

- `review/DECISION.md` sha256 was verified first, before anything else was read: `163ba833…6eb6cf5`, equal to the target. It was recomputed just before this file was written, with the same value.
- `research/EXECUTION.json` live sha256 is now `644fc3e7…29a7e9a8`, which differs from the S87 pin `fd746cb8…`. The pin is cited point-in-time. Under the no-repin rule (§7.7), drift from the pin is never a finding. The frozen `inputs/EXECUTION.json` equals the pin (`fd746cb8…`).
- Environment:
  - `CARGO_HOME=/tmp/cargo-s87-r30`, private and empty.
  - `CARGO_TARGET_DIR=/tmp/cargo-s87-r30-target`, which each script overrides with its own `<ws>/target`.
  - Host: Darwin 25.4.0, arm64, 14 CPUs.
  - `uptime` 1-minute load: 8.79 before the pass, 8.77 after it.
  - Tools: cargo and rustc 1.98.1; the 1.97.1 and 1.96.0 toolchains through rustup; `just` 1.57.0, `lefthook` 2.1.14, `git` 2.50.1, `gh` 2.101.0, shellcheck 0.11.0.
- Network: the registry was never needed, because every scratch workspace has zero registry dependencies. `r30-upstream-docs.sh` made its own read-only `gh api` GETs.
- Fixture git: `r30-wiring-cost.sh` and `r30-wiring-severity.sh` create their git repositories inside `mktemp -d` scratch under `$TMPDIR`. That is permitted by standing rule 2. After the pass, no `r30-*` scratch directory remained under `$TMPDIR`. No git write touched the checkout.
- Byte-identity: `review/*.md`, `review/identities.json` and `review/evidence/*` were hashed before and after the pass, and all were identical. Only this file was added under `review/`.

## Rerun record

Invocation from `review/evidence/`, sequential, with no added flags: `bash r30-<name>.sh > /tmp/s87-r30-rerun/r30-<name>.log 2>&1`. The order was lints, scope, severity, suppression, upstream-docs, wiring-cost, wiring-severity, then inputs, matching the decision's order at `:262`.

| Script | Exit | Rerun totals | Committed totals | Decision claim (`DECISION.md` line) | Outcome comparison | Byte comparison with committed log |
|---|---|---|---|---|---|---|
| `r30-lints.sh` | 0 | 14 PASS, `failures=0` | 14 PASS, `failures=0` | 14 / 14 PASS (`:280`) | 14 cases: labels, exits and unit counts identical | differs: header timestamp, `CARGO_HOME`, cargo parallel-output order (18 residual lines) |
| `r30-scope.sh` | 0 | 20 PASS, `failures=0` | 20 PASS, `failures=0` | 20 / 20 PASS (`:277`) | 20 cases identical | differs: same classes (9 residual lines) |
| `r30-severity.sh` | 0 | 17 PASS, `failures=0` | 17 PASS, `failures=0` | 17 / 17 PASS (`:278`) | 17 cases identical | differs: same classes (30 residual lines) |
| `r30-suppression.sh` | 0 | 16 PASS, `failures=0` | 16 PASS, `failures=0` | 16 / 16 PASS (`:279`) | 16 cases identical | differs: same classes (12 residual lines) |
| `r30-upstream-docs.sh` | 0 | no `MISSING`, `failures=0` | no `MISSING`, `failures=0` | 22 patterns found, 0 missing (`:283`) | every pattern found | differs: header timestamp; Cargo `CHANGELOG.md` blob and line numbers (OBS-3) |
| `r30-wiring-cost.sh` | 0 | 17 PASS, `failures=0` | 17 PASS, `failures=0` | 17 / 17 PASS (`:281`) | 17 cases identical; `H3e` HEAD unchanged (`HEAD subject after H3e …: H2 edits`), `H3f` accepted (`readme note`) | differs: timings, parallel-output order, lefthook durations (32 residual lines) |
| `r30-wiring-severity.sh` | 0 | 8 PASS, `failures=0` | 8 PASS, `failures=0` | 8 / 8 PASS (`:282`) | 8 cases identical | differs: same classes (26 residual lines) |
| `r30-inputs.sh` | 5 | 38 PASS, 5 FAIL, `failures=5` | 43 PASS, 0 FAIL | 43 / 43 PASS (`:284`) | 5 provenance checks fail; every figure, excerpt, count and case-ID check passes (OBS-1) | differs |

"Residual lines" counts the diff lines that remain after normalizing run timestamps, `wall-clock:` values, `CARGO_HOME` and lefthook durations. Each remaining line is cargo's per-unit `generated N warning` or `could not compile` lines printing in a different order, or a `cargo fix` hint moving between the `lib` and `lib test` units. Exit codes and diagnostic content do not change.

### shellcheck

`shellcheck r30-*.sh` (version 0.11.0) returned exit 0 with no output across all eight scripts. That confirms the decision's statement "All eight scripts are `shellcheck`-clean" (`:273`).

### Key figures, rerun compared with decision

| Case | Decision (`DECISION.md` line) | Rerun (`/tmp/s87-r30-rerun/r30-wiring-cost.log` line) |
|---|---|---|
| `H2a` cold, 29 units | 16.01 s (`:193`, `:318`) | 5.86 s (`:35`) |
| `H2b`/`H2c` warm no-op, 0 units | 0.12–0.14 s (`:124`, `:193`) | 0.09 s, 0.08 s (`:42`, `:49`) |
| `H2d`–`H2f` incremental, 5/2/5 units | 0.22–0.49 s (`:124`, `:193`) | 0.25, 0.18, 0.26 s (`:61`, `:70`, `:82`) |
| `H3e`/`H3f` real commit through the hook | 0.49–0.69 s, "under 1 s" (`:194`, `:381`) | 0.61 s, 0.27 s (`:168`, `:184`) |
| `H4a` clippy after the gate, 4 units | 0.62 s (`:168`) | 0.27 s (`:200`) |

The structural claims all hold in the rerun. The claims checked, with the case that shows each:

| Claim | Case |
|---|---|
| Both feature configurations are needed | `S4`–`S6` |
| `CARGO_BUILD_WARNINGS=deny` is inert on 1.96.0 and denies on 1.97.1 and 1.98.1 | `W1` |
| `build.warnings` changes no fingerprint | `W3b`, 0 units |
| `RUSTFLAGS` re-checks every unit | `W3d`, 2 units |
| A bare `#[expect]` fails under `--all-features` | `X8b` |
| `#![allow(warnings)]` passes | `X6` |
| Recipe, hook and CI commands are identical, and drift is detected | `H1a`–`H1c` |
| The real hook refuses the E0308 commit | `H3e` |
| `just` stops at its first failing line, while lefthook runs both jobs | `V2a`, `V2b` |
| `--locked` refuses an un-updated lockfile | `V3` |

## Findings

BLOCKING: none.

## Observations (not fixed; rerun only)

- **OBS-1: the five `r30-inputs.sh` failures are provenance drift, disclose-only under standing rule 1.** Each failure is traced to its cause:
  - `I-policy`: `inputs/EXECUTION.json` (now `fd746cb8…`, the S87 pin) differs from the live `research/EXECUTION.json` (`644fc3e7…`, a working-tree edit).
  - `I-eao-r30`: the frozen policy now carries 12 `empirical_auditor_overrides` entries, and R30 is not one of them. The live file carries 14, also without R30. This is consistent with the Q23 seat batch that moved unaccepted items to the Codex empirical seat (RUNBOOK §7.7). The decision's `:350` statement "The re-frozen policy lists R30 in `empirical_auditor_overrides`" was true of the `acdcbfff…` freeze it cites and is point-in-time now.
  - `I-runbook-q17a`: the script joins `research/RUNBOOK.md:73-76` and requires `Q17\.A \(2026-09-27\).*extends the substitution to the research wave.* R30,`. Two lines of text about the 2026-09-28 partial reversal were inserted above that passage. Q17.A now opens at `:75` and "extends the substitution to the research wave R08, R09, R12, R13, R14, R27," at `:76`. The item list continues past `:76`, so ` R30,` falls outside the fixed window and the match fails. Q17.A is still present.
  - `I-manifest-dispatch`: `manifest.json` now records `input_hashes.prompt` `2c83ee19…` instead of `a883b22d…`, and `required_engines` is still `["codex", "opus"]`. This is the controller re-snapshot that gap 8 (`:412`) flagged as the controller's step.
  - `I-live-CLAUDE`: `inputs/CLAUDE.md` differs from the live `research/CLAUDE.md`, which was last committed in `e41d89e3` (batch-5).

  None of these touches an empirical outcome. Every `I-fig-*`, `I-excerpt`, `I-hdr-*`, `I-counts-*` and `I-dec-*` check passes, and the `I-counts-*` checks re-verify the committed logs.
- **OBS-2: timing drift, toward lower cost.** The rerun ran at a 1-minute load of about 9, against 75–102 in the decision's pass. Cold `H2a` measured 5.86 s against the quoted 16.01 s. That is inside, and 0.33 s above the low end of, the decision's disclosed cross-pass range of 5.53–16.01 s (`:414`). Warm no-op measured 0.08–0.09 s, below the quoted 0.12–0.14 s. Incremental measured 0.18–0.26 s, which starts below the quoted 0.22–0.49 s range. The hook commits measured 0.61 s and 0.27 s. The first is inside the quoted 0.49–0.69 s range, the second is below it, and both are under the 1 s bound. `H4a` measured 0.27 s against 0.62 s. Every change lowers cost, so none can move the F106 pre-commit-tier resolution (D5). This is recorded, not re-quoted (§7.1).
- **OBS-3: the upstream Cargo `CHANGELOG.md` moved.** The blob changed from `7a188485…` (8,355 lines) to `9d3de1a1…` (8,520 lines). The cited sentences are unchanged and still present, now at `:559`/`:564` (Cargo 1.97, "Stabilize `build.warnings` config.") and `:4316`/`:4321` (Cargo 1.74 `[lints]`). The decision cites `CHANGELOG.md:394`, `:399`, `:4151` and `:4156` (`:43`, `:180`, `:368`). Those numbers are correct for the blob the committed log records. The drift is upstream and point-in-time. The other five upstream files printed the same blobs and line numbers as the committed log.
- **OBS-4: parallel output order.** cargo's per-unit `generated N warning` and `could not compile` lines, and the placement of its `cargo fix` hints, print in a different order from the committed logs in every cargo-running script. This is nondeterministic job scheduling. The same class was noted in r3c OBS-2.
- **OBS-5: seat-family mismatch.** The Codex empirical seat (§7.7, default family openai) was executed by an Anthropic model. This file reports the true identity: `model: claude-opus-5-5`, `family: anthropic`. The empirical-audit different-family check is therefore not met by this seat. That was also true of r3c, whose header labelled the family `openai` while it disclosed a Claude executor. The controller dispositions this; the audit does not.

## Totals

- Reruns: 8 of 8 completed. Seven empirical scripts exit 0 and reproduce their committed PASS counts. `r30-inputs.sh` exits 5 on provenance drift (OBS-1).
- shellcheck 0.11.0: exit 0 with no findings.
- The audit approves. It records no BLOCKING finding and five observations, OBS-1 to OBS-5.
- Rerun logs: `/tmp/s87-r30-rerun/r30-*.log`, `/tmp/s87-r30-rerun/shellcheck.log`. Nothing was written into the checkout except this file.
- This file's own sha256 cannot be embedded in the file. It is printed to stdout and appended to `/tmp/progress-s87-r30.log`.
