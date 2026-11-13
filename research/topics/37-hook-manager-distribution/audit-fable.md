actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: b172133d641c90157f3fb562281981e118cfd7397a382d23f209a56aec520c73
verdict: approve
unresolved-findings: none

# R37 — hook-manager-distribution — directed verification, revision 4

**Scope.** This is a directed verification of `review/DECISION.md` revision 4. It confirms or disputes only the four repairs enumerated from `review/audit-fable.r3.md` (M1) and `review/audit-codex.r3.md` (findings 1–3). It did not look for new findings.

**Seat disclosure.** This seat is labelled `fable` but ran on `claude-opus-5-5`, the same model as the synthesizer.

**Files read.**
- `review/audit-fable.r3.md` and `review/audit-codex.r3.md`
- `review/R37-r3-snapshot.md` and `review/DECISION.md`
- The cited evidence lines

I read no other audit file.

## Hash and precondition checks

- `shasum -a 256 review/DECISION.md` returned `b172133d641c90157f3fb562281981e118cfd7397a382d23f209a56aec520c73`, which matches the expected hash. I ran this check before any other step.
- `review/audit-fable.r4vo.md` did not exist before this write.
- `diff R37-r3-snapshot.md DECISION.md` shows exactly seven hunks:
  1. The header now says revision 4, followed by a new revision note (new `:1-17`).
  2. The actor line changed from `-r3` to `-r4`, and "Revision 3" became "Revision 4" (`:53-54`).
  3. The stars figure is now dated (`:260-261`).
  4. The M1 locator changed (`:287`).
  5. A rerun-drift paragraph was added (`:351-358`).
  6. A wiring-log note was added (`:391-398`).
  7. The engine note was rewritten (`:409-415`).
- **Prose only, confirmed.** No hunk touches a figure, a verdict, a parameter, or the candidate YAML. `ls -laT review/evidence/` shows that all seven evidence files were last modified between Sep 26 18:57:16 and 19:05:51 local time. That is before the revision-3 snapshot (Sep 27 11:35) and before revision 4 (Sep 27 11:38). The run directory is untracked (`git status` shows `??`), so the timestamps are the only available change record. `git diff` has nothing to compare against.

## Per-fix confirmations

**M1: confirmed.** New `:287` reads `(`DECISION.md:1288-1289`; the same point at `:368`)`, which is the repair text as directed. `grep -n "carried a checksum"` on `research/topics/42-dev-toolchain-provisioning/DECISION.md` matches `:368` and `:1289`. Lines `:1288-1289` read "codex's shape / carried a checksum and this one does not". Both halves of the new citation hold.

The other `:368` citations are preserved unchanged: new `:138` (old `:122`) and new `:438` and `:440` (old `:399-402`). None of them falls inside a diff hunk.

**Codex finding 2 (dating and drift note): confirmed.**
- New `:260-261` dates the figure: "8,856 stars as retrieved at `2026-09-27T01:57:16Z` UTC (`r37-endpoints.log:1`, `:13`)".
- `r37-endpoints.log:1` is `retrieved_at_utc 2026-09-27T01:57:16Z`.
- `r37-endpoints.log:13` is `FIGURE E05 evilmartians/lefthook stargazers_count=8856 …`.
- `r37-endpoints.log:69` is `TOTAL pass=17 fail=0`.
- New `:351-357` records the following details, each matching the revision-3 empirical audit's finding 2:
  - the rerun time `2026-09-27T17:45:30Z`
  - the rerun figure `stargazers_count=8857`
  - drift in crates.io download counts and in issue #1526's comment count
  - `cmp` returning 1
  - all 17 assertions passing
- The committed log is kept as the historical observation.

**Codex finding 1 (wiring note): confirmed.** New `:391-397` states that raw wiring logs vary in three respects: scratch paths, elapsed times, and the rendered hook glyph. It states that reproducibility is judged on the `PASS`, `FAIL` and `TOTAL` lines. It records the 26-pass, 0-fail match and says that the raw mismatch is retained in the audit.

The cited banner is at `r37-wiring.log:10`: `│ 🥊 lefthook  v2.1.14   hook:  pre-commit │`. Line `:9` is the `╭───…╮` box border. The decision's locator `:10` is therefore correct, and the audit's `:9` was off by one. `r37-wiring.log:86` is `TOTAL pass=26 fail=0`.

**Codex finding 3 (engine note): confirmed.** New `:409-415` distinguishes the captured input (R37 absent from `engine_overrides`) from the current working-tree policy (Muse/Opus). It leaves reconciliation to the controller. I checked each part of that claim:

| What I checked | Result |
|---|---|
| `inputs/EXECUTION.json` → `engine_overrides.R37` | none |
| `inputs/EXECUTION.json:5` | `"engine_overrides": {` |
| Working-tree `research/EXECUTION.json` → `engine_overrides.R37` and `items.R37.engines` | both `['muse', 'opus']` |
| `HEAD:research/EXECUTION.json` → `engine_overrides.R37` | none, so the override is uncommitted |
| Q17.A citation | `research/RUNBOOK.md:75-78` sits within §2 (`:57`), and R37 is listed among the "muse+opus" research-wave items |

The note cites keys rather than line numbers, which suits an uncommitted file.

**Revision note and header: confirmed.** The note is at `:3-17`. Its disposition table matches the diff.

## Observations (noticed, not findings)

1. The repairer was right that M1's premise was partly wrong. The quoted sentence appears verbatim on R42 `:368` as well, at the end of the table row: "…because codex's shape carried a checksum and this one does not". The original `:368` locator was therefore defensible. The repaired citation is still accurate, so no change is needed. The revision-note table's phrase "was located at `DECISION.md:368` only" summarizes the audit's claim, not a fact about R42.
2. As noted under codex finding 1, the audit cited `r37-wiring.log:9`, but the banner is at `:10`. The decision cites `:10` correctly.
3. `research/RUNBOOK.md:73` dates the partial reversal of Q9.B "2026-09-28", which is one day after today (2026-09-27). This is outside R37's scope.
