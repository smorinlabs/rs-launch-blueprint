# R30 revision 3 empirical re-run — Codex

SUPERSEDES review/audit-codex.r3.md (blocked on evidence-sufficiency only, no contradiction — same DECISION rev, re-run under the standing evr rule).

actor: Codex
model: gpt-6
family: openai
decision-sha256: 163ba8334d75debd3add4d620269e8608bf2164c5b0cd6fc464147fca9eb6cf5
execution-pin-sha256: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
verdict: blocked
unresolved-findings: B-1, B-2

## Re-run record

The decision hash was verified before reading. The point-in-time `research/EXECUTION.json` pin was independently recomputed and matches both the live and frozen policy files. All re-run outputs were directed to `/tmp/r30-r3b-*.log`, with no evidence log overwritten.

| Evidence script | Re-run result | Byte comparison with committed log | Outcome comparison |
|---|---|---|---|
| `r30-lints.sh` | exit 0 | different | same 14 PASS, 0 FAIL |
| `r30-scope.sh` | exit 0 | different | same 20 PASS, 0 FAIL |
| `r30-severity.sh` | exit 0 | different | same 17 PASS, 0 FAIL |
| `r30-suppression.sh` | exit 0 | different | same 16 PASS, 0 FAIL |
| `r30-upstream-docs.sh` | exit 0 after a network-enabled read-only retry | different | same six upstream files found, 0 MISSING, 0 failures |
| `r30-inputs.sh` | exit 4 | different | 39 PASS, 4 FAIL versus committed 43 PASS, 0 FAIL |
| `r30-wiring-cost.sh` | not run | unavailable | see B-1 |
| `r30-wiring-severity.sh` | not run | unavailable | see B-2 |

The first upstream-docs attempt could not connect to `api.github.com` and exited 6. The network-enabled retry succeeded; the result above uses that successful retry. Its Cargo 1.97 changelog text still says `Stabilize \`build.warnings\` config.` at current line 564, versus committed line 399. The script's six source checks found no missing text.

Revision-note repairs hold at the lines read: R42 `research/topics/42-dev-toolchain-provisioning/DECISION.md:26` defers the `channel` value to R27; R27 `research/topics/27-formatter-config-surface/prompts/formatter-config-surface.prompt.md:14` claims it under F103. This decision routes the Cargo ≥ 1.97 constraint to R27 at `review/DECISION.md:43`, `:51`, `:226-229`, `:247`, and `:369`; the re-verify trigger appears at `:232`. The committed timing lines support the revised 16.01 s cold and 0.49–0.69 s real-hook figures at `review/evidence/r30-wiring-cost.log:35`, `:168`, and `:184`, matching `review/DECISION.md:6`, `:124`, `:193-194`, and `:380-381`. The re-run input script passed `I-r42-channel`, `I-r27-f103`, `I-r2-snapshot`, and `I-jf5` (`/tmp/r30-r3b-inputs.log:20-22`, `:65`). Independent timing reproduction remains B-1.

## Findings

- **B-1 (BLOCKING):** `review/DECISION.md:281` claims the recipe, hook, and CI command identity (`H1`), measured cost (`H2`), real hook commits (`H3`), and clippy behavior (`H4`). `review/evidence/r30-wiring-cost.sh:145`, `:170-182`, and `:190` invoke Git writes, including `git init`, `git add`, `git commit`, `git reset`, and `git checkout`. The script creates its Git repository under `/tmp`, but the instruction forbids Git writes without a scratch exception. Read-only inspection of the script and committed log cannot independently reproduce the load-bearing H1–H4 output. No contradictory output was observed.
- **B-2 (BLOCKING):** `review/DECISION.md:282` claims a warning fails the real Justfile and lefthook commands (`V1`) and that the hook rejects a stale lockfile (`V3`). `review/evidence/r30-wiring-severity.sh:73`, `:77-106` invoke Git writes in a scratch repository. The same explicit prohibition prevents the script's Git-dependent scenarios from running. Read-only inspection of the script and committed log cannot independently reproduce V1–V3. No contradictory output was observed.
- **OBS-1 (OBS):** The four completed local probe logs differ byte for byte from their committed logs, while all 67 case outcomes match. `review/DECISION.md:262` and `:414` disclose run-to-run timing and load variation; headers and scratch paths also vary.
- **OBS-2 (OBS):** The successful upstream-docs log differs in timestamp and Cargo changelog blob and line numbers. The quoted stabilization text remains present. The point-in-time citation rule and `review/DECISION.md:43`'s recorded source line explain the drift; no re-pin is requested.
- **OBS-3 (OBS):** `r30-inputs.sh` now reports `I-eao-r30`, `I-runbook-q17a`, `I-manifest-dispatch`, and `I-live-CLAUDE` failures (`/tmp/r30-r3b-inputs.log:12-24`). RUNBOOK Q17.A and override text moved from the script's fixed line slices to `research/RUNBOOK.md:73-78` and `:100-106`; R30 remains named and the frozen override remains `claude`. The manifest now records the amended prompt hash, while `review/DECISION.md:352` described its earlier dispatch hash. The live research index also changed after freezing. These are control-file and point-in-time record drift; the actual prompt and `EXECUTION.json` still compare byte-identical (`/tmp/r30-r3b-inputs.log:2`, `:5`), and the decision's gate recommendation does not depend on the old manifest hash.
