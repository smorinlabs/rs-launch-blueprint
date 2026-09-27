actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: f3d4f8c72d2a73dc95649d15e8d7b46e2edbb9b61e3a1b047cd1f5e67c512948
verdict: approve
unresolved-findings: none

# Directed verification of R79 revision 6 (JF5-1, M1)

Scope: this is a directed verification, not a fresh audit. The first operation was
`shasum -a 256 review/DECISION.md`, and it returned the sha256 above, equal to the target.
The inputs were `review/audit-fable.r5.md`, `review/audit-codex.r5.md`,
`review/R79-r5-snapshot.md` and `diff R79-r5-snapshot.md DECISION.md`. No other audit or
snapshot was opened. Git and the runner were not used.

## Diff scope

`diff` shows exactly five hunks:

1. H1 `(revision 5)` → `(revision 6)`.
2. A new revision-6 note with a disposition table (:6–:20). The revision-5 note is kept as
   "kept as history".
3. The shutdown row (:414): JF5-1.
4. A new paragraph in `## Empirical check` (:1087–:1098): M1.
5. Revision-history row 5 now carries its sha, and row 6 was added (:1457–:1458).

Hunks 1, 2 and 5 are the conventional updates. No other line changed. **Confirmed.**

## JF5-1 — confirmed

- The replacement text is verbatim at `DECISION.md:414`: "the registry is in memory and a pull
  exporter has no sink to flush to, so any histogram samples not yet drained, and every
  observation after the last scrape, are lost". It matches the repair at
  `audit-fable.r5.md:12` character for character.
- The conclusion "which is ordinary Prometheus pull semantics" is unchanged. The status
  **design statement, not executed** is unchanged.
- It agrees with the untouched "exporter failure" row (:413). That row says a scrape drains
  pending histogram samples (`:91`, `:125`–`:139`). The shutdown row now says samples not yet
  drained are lost.
- It agrees with the upkeep paragraph (:458–:476, drain at :462–:467). That paragraph says pending samples
  accumulate until a scrape or `run_upkeep` drains them. The row no longer claims that nothing
  is buffered, so the contradiction is gone.

## M1 — confirmed

- The paragraph is at `DECISION.md:1087`–`:1098` (a blank line at :1086) and calls the old label "historical".
- It cites `crate-sources.sh:426`. That line still prints `"axum's own example never calls
  run_upkeep -- the defect the recommendation repairs"`.
- It cites line 234 of both `crate-sources.log` and `crate-sources-r3.log`. Both lines read
  `PASS  axum's own example never calls run_upkeep -- the defect the recommendation repairs`.
  Both citations are accurate.
- It states that the `show_absent` assertion is unaffected and still passes.
- It defers the relabel, the paired log and the digest pins to the next evidence revision. It
  cites `audit-codex.r5.md` M1, which asks for exactly this interim step.
- The evidence is stable. `find review/evidence -type f -newer review/audit-fable.r5.md`
  (written 2026-09-27 11:20:59) returns 0 files. The newest evidence file is
  `decision-self-check-r3.log`, dated 2026-09-27 00:12:38. So neither the script, the logs
  nor any digest-pinned file changed after the round-4 audits.

## Observations (non-blocking)

- O1: `R79-r5-snapshot.md` has sha256 `d1f4460e…9d79`. This matches the revision-6 note and
  revision-history row 5.
- O2: The self-check result that `:1096`–`:1098` reports was not rerun in this verification.
  That result is 315 / 1 / 0, with the only FAIL being the H1 check, which expects
  `(revision 3)`. The expected FAIL follows from the H1 change and is outside this directed
  scope.
