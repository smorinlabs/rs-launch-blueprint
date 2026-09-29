# R72 — api-pagination — judgment audit of DECISION.md revision 5

actor: audit-fable-r72r5-2026-09-22
model: claude-opus-5-5
family: anthropic
decision-sha256: ddc9e134392e7d7ca674cc794ea01bd434bcf7097fca23de3d199674c791e138
verdict: approve
unresolved-findings: none

## Scope and method

- **Target.** `research/runs/R72/2026-09-18T215915Z-af997c2abb5a/review/DECISION.md`, revision 5.
  I recomputed its sha256 with `shasum -a 256` before reading anything else. It equals the
  expected `ddc9e134…c791e138`.
- **What this audit judges.** Reasoning and fidelity only. Execution truth belongs to the
  empirical audit. I spot-checked logs, snapshots and cited lines; I did not rerun the
  scripts. The exceptions are `shellcheck` and a `git ls-tree` file count, both read-only.
- **Inputs read.**
  - The decision, `inputs/prompt.md`, `inputs/prerequisites.json` and `research/RUNBOOK.md`.
  - The three pinned raws: `raw/muse-1079…a079.md`, `raw/opus-95db…32d0.md` and
    `raw/doxa-6f73…a540.md`. All three hashes match their filenames.
  - The REST standard, as blob `71bd813c` at `/Users/stevemorin/c/rest-standards` commit
    `0850d43e`, extracted with `git show` to `/tmp/r72std.md`.
  - Prerequisites: published `research/topics/69-web-framework-stack/DECISION.md` (sha256
    `d4507f5b…`, equal to the `prerequisites.json` pin); published R01; R03's accepted
    run decision (sha256 `610e3338…`, equal to the `OWNER-ACCEPTANCES.md` row); and
    `docs/port/PARAMETERS.md`, `COMMONALITY.md:314-315` and `OWNER-REVIEW.md` (`:47`, `:187`).
- **Blindness.** I read no `review/audit-fable*.md` below r5, no `R72-r*-snapshot.md` and no
  `R72-r1-reconstructed.md`. Disclosure: while tracing the OV-10 allocation, I read
  `execution-ledger.md` lines 1073–1133. Those controller entries include one-line summaries
  of earlier audit verdicts. Every check below rests on primary sources, not on those summaries.
- **Writes.** This file only. No git writes, no runner commands and no paid APIs.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **pass** | The tally holds as written: twenty-two rows, of which fourteen are `conforms`, seven are `N/A with reason` and one is `moved`. I counted each row. "Thirteen run against the real route" equals `P01`–`P11` plus `P14` and `P15`. The probe's "20 checks" equals `E01`–`E04`, `E06` and the fifteen `E05.pNN` lines in `r72-probe.log`. The status story agrees everywhere: `422` for out-of-range `limit`; `400` for `limit=abc`, an undecodable cursor and `stream`. The `P09` exact-set assertion is marked probe-scoped in the Migration table, in Validation strategy item 1 and in the `P09` row. The five retrieval timestamps agree with `snapshots/RETRIEVED*.txt`. `2026-09-23T05:20:39Z` is not in the future: the file mtime is 22:20 PDT on 09-22, and UTC now is 06:47Z. The `2026-12-20` re-verify date is 90 days after the 2026-09-21 snapshot. |
| JF-2 prompt questions and constraints | **pass** | Both HIGH questions are answered: no such crate exists (the empty "industry standard" bin), and registration is per-route extraction with the policy declared once through `FromRef` (F311, `P11`). MEDIUM: items stay the caller's own `T` (`P08`). MEDIUM: OpenAPI is derive-ready on a plain `serde` struct (`C03`), and Appendix D is moved to R71. LOW: answered "no", from the three templates Muse named, read at source (`C29`–`C48`). Gate 1 is struck by the owner ruling; I confirmed that `OWNER-REVIEW.md`'s section at `:47` carries "struck from every item's evaluation". Gates 2–6 are answered per candidate, and gaps are labelled as gaps. Every figure field the prompt requires is present for `base64`, the only crate member. Issue responsiveness covers all nine repositories. The probe's manifest declares `edition = "2024"` and `rust-version = "1.96"` (`r72-probe.sh:47-48`). The out-of-scope boundaries are honoured: the framework, R70's error rendering and R71's schema are all deferred. |
| JF-3 `## Engines` fidelity | **pass** | **Opus.** Lines `:168`, `:278`, `:437` and `:1093`–`:1094` say `400`, as quoted. The lead sentence now excludes that status, and Disagreement 7 adjudicates it on R5.3. Opus's parameters block has six `assumes` lines (`:989`–`:994`). Its paths use `crates/web`, and it names `base64` 0.23.1 (`:293`). **Muse.** Its raw shows `page`/`limit` in, `Page<T> { items, total, page, limit, total_pages }` out, a default of 20, clamping, the claimed small-collection exception, W2-REST cited (`:50`, `:140`–`:146`, `:300`–`:305`), and the three templates at `:93-101` and `:196-200`. **Doxa.** The leg headers are at `:15`, `:1074` and `:1758`. `BASELINE-REVIEW:` lines appear at `:483`, `:1337` and `:2025`. `CONFLICT: none` is at `:749`. The four `CONFLICT:` lines are at `:1420`, `:1636`, `:2105` and `:2151`; I confirmed with `diff` that `:2105` and `:2151` are identical. The `total` positions are at `:299`, `:1341`, `:1398` and `:2067`. The claim that the Doxa legs were never shown the standard also holds: the prompt names neither the standard nor W2-REST, and the Doxa raw never cites either one. Each disagreement is adjudicated with cited evidence. |
| JF-4 load-bearing claims trace to sources | **pass** | I read each of these at its source. **Standard:** R5.3 at `:939`, R6.1–R6.10 at `:1133`–`:1244`, R11.1 at `:1678`, R11.7 at `:1752`, R12.5 at `:1807`, the §13 switch scope at `:1896`–`:1899`, R13.3 at `:1935`, Appendix C/D rows, and E.4 with its example cursor. **Ledger and ruling:** the W2-REST ruling text at `OWNER-REVIEW.md:187`, and F310/F311 at `COMMONALITY.md:314-315` (`DIVERGENT`, owner R72). **Prerequisites:** R69's full `axum-extra` sentence at `DECISION.md:2340-2345`; the sentence starts on `:2341`, and the extra line is immaterial. R01 behavior 6 at `:53`. **Logs:** `C05`, `C07`, `C19`–`C21` and `C25` in `r72-practice.log`; `F12`, `F13`, `F24`, `F25`, `F42`, `F73` and `F74.c` in `r72-figures.log`; `S30`, `S59` and `S80` in `r72-standard.log`; `I71`–`I86` in `r72-inputs.log`. **OV-10:** `execution-ledger.md:1107` does say "OV-10 pre-allocated" for this dispatch. |
| JF-5 REST-standard dispositions; OV-10 | **pass** (one observation, below) | Every §6 rule has a row, and each row's disposition matches the rule text. R6.3 is a SHOULD. Its contractual reading of *non-constructable* is argued from the standard's own text: `:1175` names R12.5 as the client half, AC-013 maps to both R6.3 and R12.5 (`:2497`), and the E.4 example cursor is plain base64 (`S59`). R5.3 is met with `422`. R13.3 is correctly treated as unscoped by the switch and binding per endpoint, and `P15` exercises it. R7.1 and R11.7 are whole-API response-header rules, and the row assigns them away with evidence (`I76`–`I78`). R1.9 binds only mutating requests, so a `GET` collection owes it nothing. **No rule needed OV-10.** No MUST is departed from, and no SHOULD is departed from under the readings stated. |
| JF-6 `assumes` lines; R69r10 in prose only | **pass** | I extracted the value column of `PARAMETERS.md` rows 7–10, rewrote each row as an `assumes` line, and ran `diff` against the decision's four `assumes` lines: identical. No `assumes web-extra-surface` line exists. The string `crates/web` appears only in prose: coupling 1, Disagreement 9 and re-verify trigger 1. Every migration path is under `src/web/`. |
| JF-7 no conflict with prerequisite values | **pass** | Published R69's hash equals the pin, and the probe resolves axum 0.8.9. R69's value leaves `serde` ungated ("it does not gate … serde, serde_json"), and the r5 sentence matches that. R03's rule 1 is cited at its accepted hash, and no port signature changes. R01's behavior 6 is reconciled in prose: the observable changes form, and the principle is preserved by `P08`. R01 owns only `http-transport-injection-seam`, so no registered value moves. The one contestable point is adding `dep:base64` to the `web` array literal, which R69's value spells `["dep:axum", "dep:tokio"]`. The decision presents this openly as a reading, not a quotation. Its ground is also sound: R69's clause (4) names R72 inside `web` and requires every thing-(4) layer to be "on when web is on and absent when it is off". The decision also names the corrective instrument if the owner reads the literal as closed: a `CONFLICT:` line, never a separate feature. |
| JF-8 evidence scripts and counts | **pass** | Every cited log exists beside its script, eleven scripts in all. The log totals match the decision's table: 82/0/0, 89/0/0, 167/0/3, 65/0/0, 20/0/0, fetch 59, 4, 33+2 ABSENT, 32 and 5 with 0 gaps, and archive rerun 5/0. `shellcheck` reports nothing on all eleven scripts. `git ls-tree -r e0b0d1c1` lists 7 365 files, as claimed. |
| JF-9 decision shape | **pass** | Judged against the published contract in RUNBOOK §5, not against the raw-answer template in the prompt, which governs raws. The H2s are `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`, in that order. There is no `## Supersedes`, which is correct because nothing is published for R72. `## Decision` carries the recommendation with its version, the settled F310/F311, `### Principles and implementation` and a `re-verify:` line. `## Empirical check` states the toolchain, OS, command, working directory and observed output. |
| JF-10 recommendation follows the evidence | **pass** | The contract comes first and follows from W2-REST plus §6. The crate refusals rest on source-read contract defects (`F54`–`F60`, `C49`–`C63`), with maturity weighed afterwards. The one added crate is justified by production precedent (`C07`) and by an unsafe-free feature selection (`C19`–`C22`, `E06`). The architectural alternatives A–F are compared before any library is weighed. |

## Observations (non-blocking; not findings)

1. **§4 representation rules have no row.** R4.3 requires a top-level object, which is
   subsumed by R6.1's row. R4.4 requires snake_case body properties and query parameters,
   and it constrains the names this item chooses: `items`, `next_cursor`, `cursor` and
   `limit`. All four comply. R4.8 with R3.8 makes null equivalent to absence, which the
   last page's `"next_cursor": null` respects.
   - **Why this is not a finding.** The completeness claim is scoped to "every rule of §6
     that binds this item", and that is true as written. No §4 rule is violated or
     misdisposed, and none bears on OV-10.
   - **What a future revision could add.** One row, "R4.3/R4.4 — conforms", at lines
     `762`–`772`. Its "may vary: the continuation member's spelling" entry could also note
     that R4.4 requires snake_case.
2. **OV-13 is also reserved for R72.** The ledger's allocation table (`:1073`, restated at
   `:1074`) reserves OV-13 for R72, and `:1107` later pre-allocates OV-10 to R72. The
   decision cites `:1107` accurately, and both numbers go unused. This is controller
   bookkeeping, not a defect of the decision.
3. **R03 has no re-verify trigger.** The decision relies on R03's rule 1, which is accepted
   but unpublished, yet it has no re-verify trigger for R03's publication or revision. The
   RUNBOOK §6 rule on changed decision hashes covers that case mechanically, so this is not
   a defect.
