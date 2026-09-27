actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 90bc90e8254dea3be6046d95f0de6791b2005c3694d41a0ace01498d5ecbb209
verdict: approve
unresolved-findings: none

# R83 openapi-contract-fuzzing — directed verification of revision 5

This is a directed verification, not a fresh audit. It confirms or disputes the four repairs
that revision 5 makes in answer to the two revision-4 audits. It does not look for new findings.

**Method.** `shasum -a 256 review/DECISION.md` was run first. It printed the expected value above.
Four files were then read: `review/audit-fable.r4.md`, `review/audit-codex.r4.md`,
`review/R83-r4-snapshot.md` and `review/DECISION.md`. `diff R83-r4-snapshot.md DECISION.md` was
run over the whole file. No other audit or snapshot file was read, and nothing was rerun.

## Diff scope

The diff contains exactly nine hunks. Each one is either an enumerated repair or a conventional
update:

| Old lines | New lines | What changed | Class |
|---|---|---|---|
| `:1` | `:1` | Title now says "revision 5" | header |
| `:3`–`:11` | `:3`–`:12` | Revision note rewritten for revision 5; cites the r4 sha `342b9874…a7093` and the r4 snapshot | revision note |
| `:15`–`:16` | `:16`–`:19` | Disposition rows for JF3-1-1 and JF3-1-2 replaced by rows for JF4-1-1, JF4-1-2 and the two codex findings | disposition |
| `:32` | `:35`–`:40` | History paragraph records revision 4 and its audits | history |
| `:129`–`:131` | `:137`–`:141` | Criterion 7 first half reworded | repair 1 |
| `:507` | `:517` | "this revision carries" becomes "revision 4 carried" | history |
| after `:508` | `:519`–`:525` | New "Revision 5 ran nothing new either" paragraph | history |
| `:585`–`:591` | `:602`–`:620` | Probe and registry reproducibility sentences scoped, with the rerun recorded | repairs 3 and 4 |
| `:755`–`:756` | `:784`–`:785` | P03 item (6) widened | repair 2 |

No hunk falls outside this list.

## Per-repair confirmations

### 1. JF4-1-1, option (a): CONFIRMED

The new text is at `:137`–`:141`, with the disposition row at `:16`.

- `:137`–`:138` reads "The mapper's valid strategy contains a `Just` arm for each declared
  boundary, and `contract_mapper.rs` asserts that each boundary is generated". This matches
  option (a) in `audit-fable.r4.md` verbatim.
- `:138`–`:139` reads "the 16 random valid cases of one run are not promised to hit every
  boundary". This is the explicit non-promise that was requested.
- The per-run claim now appears only in the second half, at `:139`–`:141`: "For each operation in
  each run, the boundary-invalid mode enumerated exactly one case for every declared constraint
  arm". So the second half still enumerates one case per declared arm.
- The disposition row at `:16` names option (a) and gives a reason for not taking option (b).

### 2. JF4-1-2: CONFIRMED

`:784`–`:785` reads "(6) Query, header and cookie parameter generation, proved against R72's
`cursor`/`limit` for the query location." This is byte-for-byte the repair wording in
`audit-fable.r4.md`.

### 3. Codex finding 1, probe log byte drift: CONFIRMED

- `:602`–`:604` scopes the byte-identity claim to "revision 1", on "the same toolchain,
  `rustc 1.98.0`".
- `:607`–`:608` adds "That byte-identity holds for the original same-toolchain pair only."
- The rerun at `:608`–`:611` records `PASS=24 FAIL=0 SKIP=0 TOTAL=24`, script exit 0, and `cmp`
  returning 1. The first differing lines are `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`
  versus `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, then `cargo 1.98.0` versus
  `cargo 1.98.1`.
- `:612`–`:613` states "All 24 assertions and the final totals match" and "The committed log is
  kept as the historical 1.98.0 record."

Every figure matches `audit-codex.r4.md:7` and the rerun-table row at `:16` verbatim. The citation
`review/audit-codex.r4.md:16`, `:21` points at the right lines.

### 4. Codex finding 2, registry log byte drift: CONFIRMED

- `:613`–`:615` scopes "the only difference anywhere in that original pair" and adds "That holds
  for the original pair only."
- The rerun at `:615`–`:620` records `PASS=29 FAIL=0 SKIP=0 TOTAL=29`, script exit 0, and `cmp`
  returning 1.
- The recorded deltas are:
  - `retrieved: 2026-09-27T07:41:52Z` versus `retrieved: 2026-09-27T18:16:14Z`;
  - `oas3` downloads `997209 / 2239368` → `1000779 / 2242938`;
  - `openapi-fuzzer` downloads `39 / 11730` → `40 / 11731`, labelled "(recent / all-time)".
- `:619`–`:620` states "The entire stable-assertions section and all 29 `PASS` lines match" and
  "The committed log is kept unchanged."

Every figure matches `audit-codex.r4.md:8` and the rerun-table row at `:17` verbatim. The citation
`:17`, `:21` is correct.

## Criterion-7 cross-references

Each remaining reference to criterion 7 still reads true against the new wording:

| Line | What it says | Why it still holds |
|---|---|---|
| `:243` | The Mapper placement row says `contract_mapper.rs` carries criterion 7's guarantee for the valid boundaries and for the boundary-invalid neighbours | The new first half is exactly that mapper assertion |
| `:319` | "Acceptance criterion 7 exists to keep both guarantees" | Both halves are still present |
| `:330` | The `contract_mapper.rs` migration row asserts that every declared boundary is generated | This is consistent with the first half |
| `:646` | "criterion 7's second half" means boundary-invalid generation | The second half still covers boundary-invalid generation |
| `:780` | P03 item (1) says "plus criterion 7" | This is a generic reference and still holds |
| `:787` | P03 item (9) says `contract_mapper.rs` fails when a declared boundary stops being generated | This is the mechanism the first half now names |

`:11`, `:16` and `:519` describe the repair itself and are accurate.

## Observations (non-blocking)

- **O1.** The disposition row at `:16` says the `Just(min)` and `Just(max)` arms "were measured
  reaching the boundary under 20 of 20 seeds (`A14`)". The text at `:313`–`:314` describes `A14`
  as measuring only the declared boundary `0`, so the measurement covered one boundary, not both
  arms. This slightly overstates the evidence. The reasoning is not affected, because the
  first half no longer relies on a per-run outcome.
- **O2.** `:16` paraphrases revision 4's reason for rejecting option (a) as "a draw over the
  declared range could never leave it". The r4 snapshot worded that reason as the 16-case run
  being unable to promise that `limit=0` and `limit=101` are generated. The two describe the same
  underlying point, and the paraphrase is fair.
- **O3.** Two edited source lines, `:613` and `:620`, run long because new text was spliced into
  existing lines without re-wrapping. This affects formatting only.
