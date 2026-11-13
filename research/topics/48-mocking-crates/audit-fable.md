actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 95a06ce150d7cdde5c671470d872bebab23ed4696cc21c2dc39819a1be9fa5ef
verdict: approve
unresolved-findings: none

# R48 mocking-crates — judgment audit of DECISION.md revision 6

Scope: reasoning and fidelity of `review/DECISION.md` revision 6. The empirical rerun is a
separate audit. The decision's sha256 was recomputed with `shasum -a 256` before any other
read. It matched the expected value above. No `review/audit-*.md` of any seat or revision and
no `review/R48-r*-snapshot.md` was read. No git write, no runner command and no paid or
submitting API was used.

Inputs read: the decision (all 954 lines); `inputs/prompt.md`; `research/RUNBOOK.md`;
`inputs/prerequisites.json`; `raw/codex.md` (sha256 `b5bf9725…`, matches `## Engines`);
`raw/opus.md` (sha256 `7d40a913…`, matches); the five evidence logs, the spike script, and
`r48-r4-archive-rerun.log`; `research/topics/01-ports-and-adapters-seam/DECISION.md`;
`research/topics/04-public-api-surface-enforcement/DECISION.md` and
`research/topics/69-web-framework-stack/DECISION.md` (coupling spot-checks);
`docs/port/PARAMETERS.md` (working tree); `docs/planning/p02/revision-rules.md` and
`judgment-revision-addendum.md`.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | pass | The revision-6 note (line 14) claims three edits. All three are present: the adjudication table and paragraph (lines 891–913), the pointer sentence in the maintenance paragraph (lines 464–466), and the `## Engines` introduction caveat (lines 801–804). Revision 5's sentence is quoted and marked superseded at lines 917–921. The D01 relabel is carried consistently at lines 76, 596, 702, 877 and 932. The C14 narrowing is carried consistently at lines 305–315, 685 and 938. The members, versions, gate dispositions and parameter values are the same in `## Decision`, `## Parameters` and `## Engines`. Three non-blocking observations are listed below. |
| JF-2 prompt questions and constraints | pass | HIGH 1 (fakes versus `mockall`, ergonomics, compile cost): answered by F119 alternatives A and B, and by gate-6 cells stated qualitatively. HIGH 2 (`wiremock` versus `mockito`: API, async/sync, maintenance): answered by the C12 reconciliation, C11, and the maintenance paragraph. HIGH 3 (principles and agreement level): answered by the F119/F120 requirement table, B1–B6, and "what must agree". MEDIUM, the closure-injection branch: made moot because R01 resolved to the trait seam (C17 pin). The reversal case is stated in `re-verify:`: member 3 retires, and members 1 and 2 are unconditional. MEDIUM, the R05 coupling: flagged but not decided (ground 2). LOW, the equivalent of `@responses.activate`: answered by F120 alternative C, which says Rust has no in-process interception, so the template uses a server object plus a constructor base URL. Gate 1 is recorded as `inapplicable — owner ruling 2026-09-12 (Q7.B)` with its reason. Every other gate is answered per candidate. Member 1 states `inapplicable` with a reason. |
| JF-3 engine fidelity and adjudication | pass | This is the revision-6 change, and the cited lines match. `raw/codex.md:93` gives "ten latest open non-PR issues", median 4.98 days, one unanswered, endpoint `issues?state=open&sort=created&direction=desc&per_page=40`, retrieved 2026-09-16. `raw/opus.md:660-664` gives "10 most recently opened issues", `state=all`, median 1.18 days, 0 of 10 unanswered, window 2025-10-02 → 2026-08-20, retrieved 2026-09-17. `inputs/prompt.md:55` defines the rubric as "10 most recently opened issues", so settling the disagreement for opus follows the prompt's own rule. The claim about the direction of the sampling effect is explicitly labeled as reasoning, not measurement. The claim that the one-day gap is not the cause is supported by the window end date. Opus used `state=all` for every responsiveness figure (`raw/opus.md:1046`, `:1236`), so the maintenance paragraph's single endpoint is faithful for the other crates' figures as well. The other numbered items were spot-checked: codex's positions at `raw/codex.md:61`, `:115` and `:127`, and the struck licence phrase at `:53`, are all quoted accurately. |
| JF-4 load-bearing claims trace to sources | pass | Spot-checked items: R01's F121 row wording (R01 `DECISION.md:17`); "needs no HTTP-mocking crate" (R01 `:154`); "or a bound test listener" (R01 `:261`); the `crates_io_github` reservation (R01 `:23`); R01 precedent line 93. The `mockall` maintenance figures match opus Sources `:652-667`. `wiremock`'s PR count and dates match opus `:1049-1050`. docs.rs status matches opus `:896`. |
| JF-5 couplings | pass | Each coupling is handed to its owner without being decided. R05 async model: flagged, not decided. R32/R11 CI lane placement: "only that some lane exists". R69 `axum-test` and R33 `insta`: handed off. R69 itself defers `wiremock` to other items (R69 `DECISION.md:2298`). R02 crate naming, R04 public-surface policy, and R67 error vocabulary are each named as the owner. `BASELINE-REVIEW: F120` narrows R01's wording only. It leaves R01's owned value unchanged and adds no `CONFLICT:`. The constructor base URL is presented as a consequence for R01's adapter. R01 itself leaves the HTTP client to other items (`:118`). |
| JF-6 assumes lines against the live registry | pass | I compared all five `- assumes` lines against column 4 of the working-tree `docs/port/PARAMETERS.md`. All five match byte-for-byte: `msrv-policy`, `rust-edition`, `target-os-matrix`, `license`, `http-transport-injection-seam`. The file's uncommitted diff changes only the `ci-job-structure` row. |
| JF-7 no conflict with prerequisites | pass | The current R01 `DECISION.md` sha256 is `44bf9ae9…12d82`. It equals `inputs/prerequisites.json` `R01.decision`, so the pinned read is still the published read. R01 records `mockall` as `active` with a median of 1.19 days and 0 of 10 unanswered, retrieved 2026-09-05. This agrees with the adjudicated opus figure. R04's single root `pub use` block in `src/lib.rs` is consistent with re-exporting `RecordingPort` there. R69 does not select any HTTP mocking crate. |
| JF-8 evidence scripts and counts | pass | All five scripts and logs exist. The PASS counts are 20, 6, 5, 4 and 3, for a total of 38, with 5 `RESULT: all checks passed (0 FAIL)` lines and 0 FAIL or SKIP lines. These equal the table at lines 635–639 and `r48-r4-archive-rerun.log`, which has 38 PASS and 5 RESULT lines. The committed C14 and D01 lines keep their old wording exactly as the decision says: C14 still says "resolve in one lockfile" and D01 still says "mockall's and httpmock's". G01 asserts 0 `Compiling mockall` lines, G02 asserts 1, H01 asserts co-declaration, and H02 asserts `truncated = false` with 0 `Cargo.lock` paths. Each narrowed prose claim therefore rests on a check that asserts it directly. |
| JF-9 decision shape | pass | The H2s follow RUNBOOK §5: `## Decision`, which holds `### Principles and implementation` and `re-verify:` at line 559, then `## Parameters`, `## Empirical check` and `## Engines`. The decision has no `## Supersedes`, which is correct because the item is unpublished. The revision note quotes the finding label, and the revision history is extended with the revision-5 sha256. |
| JF-10 recommendation follows | pass | Member 1 alone preserves F119. Member 2 is a gated escape hatch whose gates 2 and 4 are closed by executed D02 and D03. Member 3 is forced because the R01 condition fires. It wins over `mockito` on gate 4 (C09 is its own macOS CI), and `wiremock` is excluded on gate 2 (C03, E04). The revision-6 adjudication moves no verdict: `mockall` is `active` under either engine's figure. |

## Non-blocking observations (not findings)

These are recorded under the precedent of the round-3 numeral observation. None of them moves a member, a gate, a value or the adjudication.

1. **Lines 452–453.** The sentence says every maintenance figure "comes from one of three endpoints". Lines 474 and 476 then cite a fourth endpoint (`/pulls?state=open…`) and a fifth (`docs.rs …/status.json`) inline. Provenance is intact: both are opus 2026-09-17, at `raw/opus.md:1049` and `:896`. The opening sentence is too broad; no figure lacks a source. A later tidy could say "three endpoints, plus the two cited inline".
2. **Line 908.** "27 days before either retrieval" is exact for 2026-09-16 and is 28 days for 2026-09-17. Either gap supports the argument, so "at least 27 days" would be precise.
3. **Line 390 against line 702.** The `mockall` gate-2 cell cites "(D01, D02)" for its dependency tree. Line 702 says that D01 "establishes nothing about `mockall`'s tree". The spike script deletes `Cargo.lock` (`r48-r2-msrv-macos-spike.sh:164`) before D01. The D01 run then performs the MSRV-aware resolve, which includes the optional `mockall` ("Locking 113 packages to latest Rust 1.96.0 compatible versions", log line 19), and D02 compiles against that resolve. Citing D01 for the *resolution* and D02 for the *compile* is therefore a defensible reading, not a contradiction. Line 702's "nothing" is best read as "nothing about compiling it".
