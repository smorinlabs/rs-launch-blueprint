actor: audit-fable-r84r2-2026-09-25
model: claude-opus-5-5
family: anthropic
decision-sha256: f762b4fc7bd7a809ada27bf61fa474b32c968551a78d8be631453ab89e5e6551
verdict: reject
unresolved-findings:
- J1 (load-bearing claims trace + internal consistency; failed claim: "Retrieval dates. 2026-09-25 (UTC) for everything this decision checked itself" together with every figure cited to `snapshots/registry-figures.json`; evidence: that file now says `"retrieved": "2026-09-26"` and `r84-registry-figures.log` says "retrieval date (UTC): 2026-09-26". Both files and `r84-registry-figures.sh` were rewritten at 2026-09-26T11:32–11:42-0700, after `DECISION.md` (2026-09-26T10:43:20-0700). The file no longer carries the decision's figures: all-time 46,127 → 46,592; 90-day 45,469 → 45,927; last release "0.17.0, 2026-09-14" → `0.19.0`, created 2026-09-26T14:29:43Z; 33 → 35 non-yanked versions; G6 "6 closed after a median 0.49 days and 4 … open six days later" → 10 of 10 closed, median 1.445 days; openapi-to-rust pushed 2026-09-25 → 2026-09-26; OpenAPI Generator stars 26,762 → 26,763; LanceDB 90-day 1,669,641 → 1,713,489. The regenerated file also shows that re-verify trigger 3 ("a newest non-yanked `num` of `0.18.0` or later") has fired. `0.19.0` was published at 14:29Z, before this revision was written (17:43Z). Root cause is in the decision's own harness: `r84-registry-figures.sh` writes to a fixed in-tree path (`R84_SNAPSHOT="$HERE/snapshots/registry-figures.json"`), so any in-place rerun, including the empirical audit's mandated rerun, overwrites the evidence the decision cites; repair: restore the decision-time `registry-figures.json`, `r84-registry-figures.sh` and `.log`, or re-cite every figure from the 2026-09-26 file with the new retrieval date; in either case, execute trigger 3 by rerunning `r84-openapi-to-rust-probe.sh` with `TOOL_VERSION` moved to the newest release, or record why the `>= 0.17.0, < 0.18.0` pin stands. Make both scripts write volatile output outside the cited evidence path when rerun.)
- J2 (load-bearing claims trace + internal consistency; failed claim: gate-6 cell for openapi-to-rust, "about 75 s for a first from-source `cargo install --locked` on this host", and the header's "the evidence scripts, logs and snapshots are unchanged"; evidence: no evidence file contains a 75 s figure. `r84-openapi-to-rust-probe.sh:76` writes a `cargo install openapi-to-rust … s` line to `snapshots/openapi-to-rust-timings.txt` only on a fresh install, and `:68` truncates that file on every run. The current file has no install line. It was written 2026-09-26T10:27:00-0700, after revision 1 and before this revision, which contradicts "snapshots are unchanged" at least by file time. Revision 2's timings repair (header item F3) therefore cites the snapshot for the 21 s and 16 s `cargo check` figures but leaves the install figure untraced; repair: drop the 75 s number, because gate 6 permits a qualitative statement, or cite the artifact that records it; then correct the header sentence to state which evidence files changed between revisions.)

# R84 judgment audit, revision 2 — `openapi-typed-client-generation`

**Verdict: reject, on two trace findings. Neither moves the recommendation.** The reasoning
supports `openapi-to-rust` behind `just client-rust`, the `OV-11` override, the exclusion of
progenitor, and the on-demand architecture. The two findings concern figures that no longer
trace to the evidence files the decision cites, or never did. Acceptance hashes those files.

## Scope and blindness

- **Target.** `review/DECISION.md`. I measured sha256
  `f762b4fc7bd7a809ada27bf61fa474b32c968551a78d8be631453ab89e5e6551` before reading, and it
  equals the expected value.
- **Read.** The decision, `inputs/prompt.md`, `inputs/prerequisites.json`,
  `inputs/parameters.json`, `research/RUNBOOK.md` sections 4 and 5, all three pinned raw
  reports, the four evidence logs and scripts as cited, both snapshot files, the prerequisite
  R69 decisions, `docs/port/PARAMETERS.md`, `docs/port/OWNER-REVIEW.md`,
  `docs/port/OWNER-ACCEPTANCES.md`, the owner reference input, and
  `rest-api-standard.md` at blob pin `0850d43e`.
- **Not opened.** `review/audit-fable.md`, `review/audit-claude.md`,
  `review/R84-r1-snapshot.md`, and anything under `research/topics/84-*/raw/`.
- **No git writes, no runner commands, no network access.** The only write is this file.

## Checks

| # | Check | Result | Evidence |
|---|---|---|---|
| JF-1 | Internal consistency | **Fails in two places (J1, J2).** Otherwise consistent. The six-question table, the section-12 table, the couplings and the triggers agree with each other. The date for trigger 8, 2027-03-14, is six months after 0.17.0's release on 2026-09-14 | decision text |
| JF-2 | Prompt questions answered | **Pass.** All six questions (three HIGH, two MEDIUM, one LOW) are answered, each with evidence. Every template field is present in substance under the RUNBOOK's H2 shape | prompt `## Questions`; decision `## Decision` |
| JF-3 | Engines fidelity | **Pass.** Muse: 499 lines; recommends `openapi-to-rust` with committed output and `--check`; progenitor is runner-up "if and when Oxide ships OpenAPI 3.1 support" (`:318`); `### Excluded by gate` says "None" (`:263`); "72 reverse deps" (`:68`); `CONFLICT: none` (`:351`); `Justfile:322` (`:87`). Opus: 735 lines; recommends OpenAPI Generator with `supportAsync=false`; `exclude = ["clients"]` (`:445`); `total_count: 0` (`:313`); no `BASELINE-REVIEW:` (`:153`). Doxa-OpenAI: `crates/api-client` (`:470`, `:530`); `target/tools` (`:444`); `BASELINE-REVIEW: F335` (`:304`); "zero candidates are fully evidence-complete" (`:378`). Perplexity: three `owns` lines (`:1188`, `:1192`, `:1196`); "relies on npm" (`:1100`). Gemini: `BASELINE-REVIEW: F335` and "`HARMONIZED`" (`:1570-1571`); ">120" stars and "~16,000" all-time downloads (`:1585-1586`); two `owns` lines (`:1645-1646`); "The web service can import these models" (`:1620`) | raw reports at the pinned hashes |
| JF-4 | Load-bearing claims trace | **Fails (J1, J2).** Everything else traces. The REST standard at the blob pin matches the cited lines: R1.7 `:272-273`, R4.1 `:742-747` naming the "generator", R4.2 `:754-755`, R5.12 `:1019-1021` "when the client requests it", section 12 at `:1767`, R12.6 `:1815-1817`. The W2-REST quote is at `OWNER-REVIEW.md:198-200`, and Q7.B is at `:47`. The owner reference matches at lines 50, 51, 90 and 426. `D14` matches `openapi-to-rust` 0.17.0 `src/client_generator.rs:1436-1447` in the local registry source. The source log (60 checks), the probe log (36 checks) and the progenitor log (6 checks) support every claim cited to them | files named |
| JF-5 | Couplings | **Pass.** Couplings to R42, R49, R02, R05, R11, R83 and R70 are stated rather than re-decided. R70 is `open` in the index, as coupling 7 says. `A06`–`A10` log the quoted R42, R49, R02 and R05 values | `research/CLAUDE.md`; source log |
| JF-6 | `- assumes` lines byte-equal to `docs/port/PARAMETERS.md` | **Pass.** All five values equal the live registry's value cell exactly and equal `inputs/parameters.json`. The one uncommitted `PARAMETERS.md` hunk touches `ci-job-structure`, which R84 does not consume. `owns:` is empty (`A01`), and the decision declares none | parsed cell comparison |
| JF-7 | Prerequisites | **Pass.** In `prerequisites.json`, the R69 `decision` hash `d4507f5b…` equals the published revision-9 `DECISION.md` (two runs share it), and the `acceptance` hash `48a7dce8…` equals `research/topics/69-web-framework-stack/acceptance.json`. The revision-10 claim holds. `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` has sha256 `d34ab6e8…`, `OWNER-ACCEPTANCES.md:60` accepts it, and line 1791 carries `web = ["dep:rs-launch-blueprint-web"]` | hashes measured |
| JF-8 | Evidence counts | **Pass as stated.** The log summary lines read 60/0/0 of 60, 31/0/5 of 36, 6/0/0 of 6 and 31/0/0 of 31, which equal the decision's table. `r84-archive-rerun.log` shows the single `A13` difference as described. Note: the 31/31 registry log was regenerated after the decision (J1) | logs |
| JF-9 | Decision shape | **Pass.** The file has `## Decision` with `### Principles and implementation`, a settled row (F335), and a `re-verify:` line; then `## Parameters`, `## Empirical check` and `## Engines`. `## Supersedes` is correctly absent, because nothing was published for R84. `OV-11` carries `**Argument:**` and `**Options:**` | RUNBOOK §5 |
| JF-10 | Recommendation follows evidence | **Pass on the reasoning.** R12.4 (MUST) is conformed through configuration (`R05`) and fails for OpenAPI Generator (`E04`, `E05`). progenitor cannot read 3.1 (`D01`–`D03`, `P02`). R42's crates.io channel and the edition fact (`E01`, `T09`) are independent grounds. The disagreements are settled on checks, not on vote counts. The pick would survive J1: the figures it relies on still hold in the regenerated file, namely 37 stars, 0 reverse dependencies, `meteora-api` at 20 downloads, 33 releases in the dated window, and 10 of 10 issues with no maintainer comment. What J1 changes is trigger 3's status, not the ranking | decision; logs |

## Notes that are not findings

- **Revision-2 repairs, judged without the r1 audit.** Two of the three repairs are sound
  as written. Disagreement 3 now states Muse's conditional runner-up, which matches Muse
  `:318` and `:263`. Option (a) now states its cost against R5.12's conditional obligation
  and adds coupling 7 to R70. The third repair, the timings quote, is only partial (J2).
- **"Committed" is used loosely.** The decision calls logs and snapshots "committed" while
  stating that the scripts are untracked. `git status` shows all of `review/` untracked. The
  meaning is clear in context, but publication must stage these exact files.
- **The 0.18.0 date is unknown.** The local evidence does not show when 0.18.0 was
  published, so I cannot tell whether trigger 3 had already fired at the 2026-09-25
  retrieval. `0.19.0` predates this revision in any case.
