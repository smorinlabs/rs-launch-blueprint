actor: codex
model: gpt-6
family: openai
decision-sha256: f3d4f8c72d2a73dc95649d15e8d7b46e2edbb9b61e3a1b047cd1f5e67c512948
verdict: approve
unresolved-findings: none

# R79 revision 6 — directed empirical verification

The decision hash matched before review and again before this file was written. I read the two revision-5 audits and diffed `review/R79-r5-snapshot.md` against `review/DECISION.md`. The substantive changes address the two enumerated repairs.

## Repair confirmations

- **JF5-1 — confirmed.** `DECISION.md:414` contains the exact requested text: “the registry is in memory and a pull exporter has no sink to flush to, so any histogram samples not yet drained, and every observation after the last scrape, are lost”. The shutdown row remains marked **design statement, not executed**. Its wording now agrees with the pending-sample drain described by the exporter-failure row at `:413`.
- **M1 — confirmed.** `DECISION.md:1087`–`:1098` identifies the `crate-sources.sh:426` PASS label as historical, explains that the missing `run_upkeep` call matters between scrapes, cites line 234 of both recorded source logs, and defers relabeling to the next evidence revision. The `show_absent` assertion at `crate-sources.sh:425`–`:426` is unchanged and passed in the fresh run. The exact old label appears at script line 426, at line 234 of `crate-sources.log` and `crate-sources-r3.log`, and at line 234 of the fresh log.

## Rerun record

Working directory for both scripts: `review/evidence/`. Output and scratch were under `/tmp`.

| Command | Result |
|---|---|
| `bash ./crate-sources.sh` → `/tmp/r79-codex-r6vo-crate.3wij538r/crate-sources.rerun.log` | Exit 0; `PASS=66 FAIL=0 SKIP=0 TOTAL=66`. Script SHA-256 before and after: `b37596e6b2b081a5e7348038a89b6da8697ac17fadcfa94e31fac5edfc0b420f`. |
| `cmp crate-sources-r3.log /tmp/r79-codex-r6vo-crate.3wij538r/crate-sources.rerun.log` | Exit 1; first difference at byte 217, line 5. |
| `diff -u crate-sources-r3.log /tmp/r79-codex-r6vo-crate.3wij538r/crate-sources.rerun.log` → `/tmp/r79-codex-r6vo-crate.3wij538r/crate-sources.diff` | Exit 1. Only the timestamp, scratch path, rolling and all-time download counters, and their printed deltas changed. All asserted identity fields, source quotations, PASS labels, and totals match. |
| `bash ./decision-self-check-r3.sh` → `/tmp/r79-codex-r6vo-self.46bfjfuc/decision-self-check-r3.rerun.log` | Exit 1; `PASS=315 FAIL=1 SKIP=0 TOTAL=316`. Its sole FAIL is H1 expecting `(revision 3)` while the decision says `(revision 6)`, as `DECISION.md:1095`–`:1098` records. Script SHA-256 before and after: `a3519c5003f4f885c8449521c82e886c6b94b67da8f5367f3f43a2aad217c37f`. |

**Observation.** Automatic approval review rejected the first networked crate-script launch before execution because the script can create missing snapshots under `review/evidence/`. A preflight confirmed that all nine registry snapshots already existed as regular, non-symlink files; the reviewed script takes its read-only snapshot-comparison branch. The subsequent rerun completed with output under `/tmp`. This observation does not change the verdict.
