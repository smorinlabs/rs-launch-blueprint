# R76 cors-middleware — judgment audit of DECISION.md revision 2

actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 55d7df033a12683fff26d3e8e7d6199b56b31e1628a6e27d27afc25ee170baeb
verdict: reject
unresolved-findings:
1. JA-1 (JF-2, JF-3; blocking): the Muse engine report is not represented or adjudicated, and the engine set is stated wrongly against the current prompt.
2. JA-2 (JF-4, JF-1; blocking): the ground for "R4.17 not engaged on a preflight" is contradicted by the decision's own logs, so "Deviations: none" and "OV-08 stays unused" are unsupported as written.
3. JA-3 (JF-1; non-blocking alone): the decision says "six" acceptance criteria in five places, but its criteria table has seven.

## Scope and method

- Target: `research/runs/R76/2026-09-17T034010Z-d958540e8834/review/DECISION.md`, revision 2.
- Hash check: `shasum -a 256` gives `55d7df03…baeb`, which equals the expected value.
- Read in full: the decision (1,100 lines); `inputs/prompt.md`; `research/RUNBOOK.md` §2 and §5; `raw/opus.md`; `raw/muse.md`; the manifest and `operations/*.json`; `inputs/prerequisites.json`.
- Prerequisites read: R69's published decision (`research/topics/69-web-framework-stack/DECISION.md`, revision 9); R69 revision 10 in its run directory; `docs/port/OWNER-ACCEPTANCES.md`; `docs/port/PARAMETERS.md`.
- Also read: the REST API Design Standard, pinned blob `71bd813c…` (3,427 lines, 190,161 bytes, re-verified here).
- Not read, as instructed: any `review/audit-*.md` and any `review/Rxx-r*-snapshot.md`.
- Scripts were not rerun, because that is the empirical audit's job. Logs and cited sources were spot-checked.
- Judged against the current registry, prompt and prerequisites as of 2026-09-26.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** | See JA-2 (preflight "carries none of the standard-bound headers" against `X4`/`X7`) and JA-3 (six vs seven criteria). |
| JF-2 prompt questions and constraints | **fail** | All five questions are answered: HIGH ×3, MEDIUM via the py-vs-`tower-http` table, and LOW, which is answered negatively for templates. All six gates are addressed. The answer template's fields are carried. **But** the live prompt (`sha256 99e9acac…`, identical to `inputs/prompt.md`) sets `- engines: muse, opus` and says that line "is authoritative". The decision is synthesized from Opus alone. See JA-1. |
| JF-3 `## Engines` fidelity and disagreements | **fail** | `raw/muse.md` (sha256 `31be2e15…c5c7`, 20,628 bytes, retrieved 2026-09-25) exists. It is absent from `## Engines`, and at least six disagreements with the decision are unadjudicated. See JA-1. The single-engine adjudication of Opus (items 1–8 at lines 988–1068) is otherwise careful and honest. |
| JF-4 load-bearing claims trace to sources | **fail** (one claim) | Spot-checks that pass: `tower-http-0.7.1/Cargo.toml:117` `cors = []`, `:161` `default = []`, `src/lib.rs:200` `#![deny(unsafe_code)]`, `src/cors/mod.rs:820` `fn ensure_usable_cors_rules`, and zero `unsafe` in all ten `src/cors/*.rs`. These come from the published `.crate` fetched from static.crates.io. The standard's quotes are also confirmed at the blob: R4.17 at 864–868, §1.10 `request-id` at 348, `Allow` at 351, R11.7 at 1752–1753, and Appendix A R4.17 at 2696. The one claim that fails is the R4.17 preflight disposition. See JA-2. |
| JF-5 couplings hand over owned choices | pass | R75 keeps the order and the `expose_headers` list; R76 fixes only that the list exists, is explicit and has `request-id` as its floor. R77 keeps the name and the parse. R67's `RSLB203`→2 is consumed, not extended. R69's `tower` dev-dependency slot is left unpromoted. |
| JF-6 `- assumes` byte-identical to registry | pass | The repository's own comparator, `research_scan.parameter_mismatches` against `registry_values`, returns `[]` for all six lines on the live `docs/port/PARAMETERS.md`. |
| JF-7 no conflict with accepted/published prerequisites | pass | R69's published `DECISION.md` (`d4507f5b…`) and `acceptance.json` (`48a7dce8…`) equal `inputs/prerequisites.json`. The design's `crates/web/` paths come from R69 revision 10. Revision 10 is owner-accepted (`OWNER-ACCEPTANCES.md:60`, sha `d34ab6e8…`, which matches the run file), and its `- owns` line at `:1791` says axum/tokio are non-optional in `crates/web/Cargo.toml` and `tower` is `crates/web`'s dev-dependency, as the decision states. The decision discloses the published/accepted split (lines 589–603) and sets a re-verify trigger for it. R67 `RSLB203`→2 matches the registry. |
| JF-8 evidence scripts and counts | pass | All four scripts and logs exist. Their `RESULT: PASS` totals are 59/54/29/43, which match the decision at lines 636–641. The `ASSERT` line counts equal those totals. Spot-checks that match: `57`/`55` packages (`probe-checks.log:62`), `+166480` bytes (`:104`), `149725960`/`462114603` (`registry-figures.log:10–11`), `36` and `1452` (`:25`, `:27`), `total_count` `30` (`:161`), and triage 2/8/4 (`:211–213`). |
| JF-9 decision shape | pass | The four H2s are in contract order, with no `## Supersedes`. `### Principles and implementation` sits under `## Decision`. There is exactly one `re-verify:` line. Parameters use `- assumes` only, with no `- owns` line, consistent with the empty `- owns:` coupling. (What `## Engines` must contain is judged under JF-3.) |
| JF-10 recommendation follows from evidence | pass | `tower-http` `cors` behind a conditional `Router::layer` branch is supported by the category enumeration, the measured `Q2`/`Q3` falsification of unconditional install, and the source reading. Muse independently reaches the same crate and the same branch shape, so JA-1 is about fidelity, not the headline pick. |

## Findings

### JA-1 — Muse report unrepresented; engine set stated against a superseded prompt (JF-2, JF-3)

**Failed claims (quoted):**
- Line 882: "The only research report registered for this item."
- Line 890: "**Codex — absent, by the controller's deferral under owner ruling W1-CODEX3**".
- Lines 892–893: "This item is FOCUSED tier, whose engine set is `codex, opus`, so **this decision is synthesized from a single engine**".
- Lines 988–989: "With one engine there are no inter-engine disagreements to settle".

**Evidence:**
- The live prompt `research/topics/76-cors-middleware/prompts/cors-middleware.prompt.md` (sha256 `99e9acac…`) reads `- engines: muse, opus`. It adds: "This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot; its mirrored `- engines:` line is authoritative."
- The prompt hash the run was prepared under was `95610e37…`, recorded in the manifest's migration event of 2026-09-21T23:06:20Z (`from: codex`).
- `research/RUNBOOK.md` §2 lists R76 in the Muse substitution set and records Q9.B retiring Codex from P02.
- `raw/muse.md` exists (sha256 `31be2e15e942401a98031416eef2d7ab2043ddae1a343016c929b87ba88c67c5`). However, `operations/muse.json` is still `state: "submitting"` with no `raw_sha256`, the manifest `state` is `partial`, and `raw/muse.md` and `operations/muse.json` are untracked. So the leg is also uncollected.
- `raw/muse.md` disagrees with the decision on points the decision never adjudicates:
  1. **Runner-up.** Muse ranks `actix-cors` 0.7.2 as runner-up, conditional on R69 choosing actix-web. The decision ranks alternative B (unconditional install) as runner-up. R69 has resolved to axum, so Muse's condition is moot, but it must be dispositioned.
  2. **Gate status of `actix-cors`.** Muse says it passes every gate and shortlists two crates. The decision (lines 464–468) excludes it "on gate 5 and on fit". The prompt's gate 5 reads "default features and any async-runtime coupling stated", which is a disclosure gate. Using it as a disqualifier is contestable. The honest disposition may be "excluded on fit, not on a gate", which changes both `Qualified shortlist` and `Excluded by gate`.
  3. **Version requirement.** Muse recommends `version = "0.7"`; the decision recommends `"0.7.1"`. These are different floors.
  4. **Issue responsiveness.** Muse observed no maintainer first-response in its window, with #740 and #737 answered only by the reporter. The decision reports 2 of 10 answered.
  5. **Muse's `### Parameters`.** It carries `- assumes` lines naming non-registry parameters (`web-framework-stack`, `cors-allowlist-value`, `middleware-ordering`) with parenthetical values. These must not be carried forward and should be recorded as a report defect.
  6. **Figures.** Muse's 2026-09-25 figures are 918 stars, 32 open issues, 3,520 reverse dependencies, `pushed_at 2026-09-19T15:23:28Z`, 476,178,922 all-time and 154,784,730 90-day downloads. The decision's figures are from 2026-09-18: 913, 30, 3,486, `2026-09-13T22:53:22Z`, 462,114,603 and 149,725,960.

**Repair:**
1. The controller collects the Muse leg through the runner, so its hash is recorded in `operations/muse.json` and the manifest.
2. A revision-3 synthesis then:
   - lists Muse in `## Engines` with its sha256;
   - replaces the Codex/W1-CODEX3 single-engine framing with the current `muse, opus` engine set and the Q9.B/`engine_overrides` basis;
   - adjudicates items 1–6 above with evidence, deciding explicitly whether `actix-cors` is gate-excluded or fit-excluded, and adjusting `Qualified shortlist` and `Excluded by gate` to match;
   - reconsiders the "single-engine" uncertainty statement at lines 1082–1086.

### JA-2 — R4.17 preflight disposition rests on a false ground (JF-4, JF-1)

**Failed claims (quoted):**
- Line 221 (R4.10 row), citing `X4`: "A preflight response serves no representation …"
- Line 710 (`X4` row): "R4.17 not engaged on a preflight".
- `rest-conformance-r2.log`, section C ASSERT: "R4.17 is not engaged on a preflight response: it carries none of the standard-bound headers".
- Line 248: "*Deviations:* none. No `OVERRIDE (OV-nn)` is recorded by this item."
- Lines 31–33: "every quoted rule conforms or is not engaged … OV-08 stays unused".

**Evidence:**
- R4.17 (blob lines 864–868) reads: "every response MUST list the standard-bound response headers it emits — among `request-id`, … and any other §1.10 response header in use — in `Access-Control-Expose-Headers`."
- §1.10 registers `Allow` as a response header (blob line 351).
- The decision's own logs show the preflight carrying such headers with no expose list:
  - `rest-conformance-r2.log` `X4`: `allow=GET,HEAD`, no `access-control-expose-headers`.
  - `X7`, the ordering the decision *requires* of R75 for R11.7 (line 218): `request-id=req_probe`, no `access-control-expose-headers`.
- The gap is structural. `tower-http-0.7.1/src/cors/mod.rs:715–729` applies `expose_headers` only on the non-`OPTIONS` branch ("This header is applied only to non-preflight requests").
- So the recommended configuration emits standard-bound headers on every configured preflight without listing them. R1.7 (blob line 271) makes silent deviation nonconformance "regardless of the deviation's merits".

**Repair:**
1. Correct the false ground in the R4.17/R4.10 rows, the `X4` row, the revision-note claim, and the ASSERT text in `rest-conformance-r2.sh`.
2. Then do **one** of the following, and say which:
   - (a) record a written deviation for preflight responses, using the allocated OV-08 with `**Argument:**` and `**Options:**`, and add it to the conformance-note "Deviations" line; or
   - (b) argue non-engagement on a *true* ground. Example: under the Fetch Standard a preflight response is consumed by the browser and never exposed to script, so R4.17's operative clause "cannot read them at all" cannot arise. Also show that R1.7 accepts an interpretive scoping rather than requiring a written deviation.
3. Keep the claim consistent with R11.7's requirement that the preflight carry `request-id`.

### JA-3 — "six" criteria against a seven-row criteria table (JF-1)

**Failed claims (quoted):**
- Line 342: "All six criteria executed green".
- Lines 523–524: "the six acceptance criteria exercised".
- Line 861: "# 3. The six acceptance criteria, as ordinary integration tests."
- Line 870: "(3) all six criteria green".
- Lines 1090–1091: "(2) The six acceptance criteria as ordinary integration tests".

**Evidence:** The criteria table (lines 326–334) has seven rows. Row 7 was "added in revision 2 for R4.17", and line 564 says "criteria 1–7". P03's planned check (3) would therefore omit the R4.17 criterion.

**Repair:** Change each "six" to "seven". Make the P03 validation list and planned command (3) include criterion 7 (`X1`).
