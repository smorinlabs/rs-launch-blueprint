actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 942ea9d2ce7dfefd1657eb261340c287d4b18437428ebc9ae78d76c35363bee1
verdict: reject
unresolved-findings: JF3-1 (RUNBOOK §5 "useful metrics" leg of the required OpenTelemetry web example is not addressed, and R78's status is stated wrongly); JF3-2 (OV-07 numbering is presented as an open controller question that the controller ruled on 2026-09-18)

# R79 prometheus-metrics — judgment audit of revision 3

Target: `research/runs/R79/2026-09-17T034011Z-2e1043da0e00/review/DECISION.md`, revision 3.
The sha256 was recomputed with `shasum -a 256` before any other step. It equals the expected
value given by the controller, 942ea9d2…3bee1.

Read for this audit: the decision in full; `inputs/prompt.md` (sha256 206b3fad…, identical to the
live topic prompt and to `manifest.json` `input_hashes.prompt`); `research/RUNBOOK.md` §2, §4 and
§5; `raw/opus.md` and `raw/muse.md` (their line references spot-checked); R69's published
decision and acceptance; the live `docs/port/PARAMETERS.md` rows; and the evidence logs under
`review/evidence/`. No `review/audit-*.md` file of any seat or revision and no
`review/R79-r*-snapshot.md` was read.

The auditor did not run a script, write to git or call a paid API. Read-only `git show` was used
against the py pin and against repository history.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** (see JF3-1 and JF3-2) | The recommendation, the feature graph, the ten acceptance criteria, the migration table and the gate table agree with each other. The module quoted at `:402`–`:507` is byte-identical to `review/evidence/r3-obs-metrics.rs`; this was confirmed with `cmp`. Two statements conflict with facts the decision itself cites: `:628` says R78 has no run directory, yet `:97`–`:100` cites Q17.A, which places R78 in the active wave; and `:92`, `:712` and trigger (14) call OV-07 numbering open, although the ledger the decision cites records a ruling on it |
| JF-2 prompt questions and constraints | **fail** (JF3-1) | Every HIGH, MEDIUM and LOW question has a direct answer. Self-exclusion is answered at `:354`–`:357`, OpenAPI exclusion at `:581`–`:591`, on-by-default posture at `:555`–`:579`, cost at `:200`–`:213` and E3, and the cross-repo agreement table at `:266`–`:274`. The unmet constraint is RUNBOOK §5 `:208`–`:212`, together with the prompt's Context requirement that "the required web example must demonstrate it when that feature is enabled" and HIGH Q1's statement that "separate library choices do not excuse an incoherent observability example" (JF3-1) |
| JF-3 `## Engines` fidelity and adjudication | pass | The Opus claims spot-checked at source match `raw/opus.md`: 34 `unsafe` in `src/cow.rs` (`:371`, `:580`), `1,256,896 B → 1,617,952 B` (`:567`), "Twenty packages" (`:590`), "only family" (`:356`) and +8 s cold (`:568`). The Muse line references i–xiv resolve at `raw/muse.md` `:34`, `:41`, `:45`, `:51`, `:65`, `:71`, `:73`, `:75`, `:80`, `:84`, `:90`, `:96`, `:98`, `:99`, `:105`, `:126`, `:127`, `:129`, `:144`, `:148`, `:164` and `:167`, and each says what the decision attributes to it. Item vii is settled with a discriminating probe: in `rustsec-method-r3.log`, `metrics-util.html` answers 200 and names RUSTSEC-2021-0113. Every disagreement carries evidence |
| JF-4 load-bearing claims trace to sources | **fail** (JF3-1 and JF3-2 are stale claims) | Confirmed exact: py at `b08bccfb` (`settings.py:38`, `:44`, `:63`–`:64`; `app.py:148`–`:149`; `paths.py:58` `APP_NAME = "plbp"`; `pyproject.toml:56`, `:62`, `:64`; `telemetry.py:46`–`:48`); `COMMONALITY.md:330` and `:307`; R77 at `1e3cdb5b` `:663` and `:684`; the owner reference's line 111 metrics clause and lines 68–69; `OWNER-REVIEW.md:187` and `:198`; `execution-ledger.md:1073`–`:1074`; R80 `raw/opus.md:166`, `:357`, `:1030`–`:1034` and `:1084`ff. The merge line is at `:1091`, two lines past the cited `:1089`, which is harmless drift |
| JF-5 couplings hand over owned choices without deciding them | **fail** (JF3-1) | R69's `web` feature change goes out correctly as `BASELINE-REVIEW: F326`, not as an edit. R77's switch semantics are supplied while R77 keeps the name and the mechanism. R80 probe placement, the R71 exclusion condition, R75's request-id and traceparent placement, and R58 are all stated as requirements. The R78 coupling rests on a false premise and leaves the "useful metrics" leg of the shared example unowned (JF3-1) |
| JF-6 assumes lines vs live registry | pass | The four `- assumes` lines at `:851`–`:854` are byte-identical to the value column of the `msrv-policy`, `rust-edition`, `target-os-matrix` and `license` rows in `docs/port/PARAMETERS.md`. There is no `owns` line, which is correct because the prompt's owns line is empty. The decision explains why it has no `web-extra-surface` assumes line (`:859`–`:869`) |
| JF-7 no conflict with accepted or published values | **fail** (JF3-2) | The R69 pin in `inputs/prerequisites.json` resolves now: `research/topics/69-web-framework-stack/DECISION.md` has sha256 `d4507f5b…` and `acceptance.json` has `48a7dce8…`. Both match, and the decision designs against that published revision 9. The feature spelling `metrics = ["web", …]` matches the live registry row verbatim. The conflict is with the controller's committed OV-07 ruling (JF3-2) |
| JF-8 evidence scripts exist; counts match | pass | All six scripts exist, and each log's summary line matches the table at `:933`–`:940`: 54, 54, 66, 5, 9 and 316, each with 0 FAIL and 0 SKIP. The historical logs read 34, 66, 5, 70 and 122. Spot-checks in `cargo-probes-r3.log` match the decision: E2 37 and 81; E3 51 → 79 and 1,307,936 → 1,702,752 B on rustc 1.98.1; E4 79 graph crates, 78 of 78 joined, 12 undeclared and highest 1.85.0; E6 two route labels, `_count` 51 and unmatched 1; F1, F3 and F4 PASS lines; runner-up 82. `scrape-sample-r3.txt` has 41 lines |
| JF-9 decision shape | pass | The H2s are Decision, Parameters, Empirical check and Engines, in that order, with no Supersedes, which is correct because nothing has been published. There is exactly one `### Principles and implementation`, and one `re-verify:` line at `:847`, outside any fence. This matches `_validate_decision_text` in `scripts/research_validation.py` |
| JF-10 recommendation follows from evidence | pass on the crate choice | The pair, the `default-features = false` setting, structural self-exclusion, the `MatchedPath`-only label with an unmatched counter, and the upkeep ticker all follow from the executed probes and the source reads. JF3-1 affects how the decision coordinates with R78. It does not affect the crate pick |

## Findings

### JF3-1 — RUNBOOK §5's "useful metrics" leg of the required OpenTelemetry example is unaddressed, and the R78 premise is false

**Failed claims.**
- `DECISION.md:628`–`:631`: "**R78 (`opentelemetry-integration`).** **No run directory exists**; R78 is unresearched. … This decision therefore fixes the interface rather than the counterpart".
- By omission: the decision never cites RUNBOOK §5. It never says whether `/metrics` is the "useful metrics" of the `otel`-enabled web example, and it never builds or proposes a combined `metrics` plus `otel` configuration. A search of the decision for "useful metrics", "integrated path" and "§5" returns nothing.

**Evidence.**
- `research/RUNBOOK.md:208`–`:212` defines the contract: "The required OpenTelemetry web example exercises an incoming request, handler, outbound operation, context propagation, actual export and useful metrics. … Applicable web decisions must show that their selected components support the integrated path." Commit `9b60bb5e` introduced this text on 2026-09-04, so it predates every revision of this decision.
- The prompt's Context requires that "the required web example must demonstrate it when that feature is enabled". HIGH Q1 says that "separate library choices do not excuse an incoherent observability example".
- The claim about R78 is stale. `research/runs/R78/2026-09-26T190312Z-8cf4b61ddead/manifest.json` records `created_at` 2026-09-26T19:03:12Z. Its `raw/` directory holds five reports, and it has a `review/DECISION.md` with mtime 2026-09-26 21:31. This decision's mtime is 2026-09-27 00:12. The decision's own `:97`–`:100` cites Q17.A, which lists R78 in the active wave.
- Corroboration, from an uncommitted draft: R78's in-flight revision 1 (`review/DECISION.md:242`–`:244`) states that "The 'useful metrics' leg of RUNBOOK §5's required OpenTelemetry example … is R79's contribution; this item's probe does not exercise metrics and does not claim that leg." R78 hands the leg to R79, and R79 does not mention it. As things stand, no item covers it.

**Repair.** Keep the repair scoped so that it does not design against an unpublished sibling.
- (a) Correct `:628`: an R78 run exists and a revision 1 is under audit, but nothing is published.
- (b) Cite RUNBOOK §5, then state R79's position on the metrics leg of the `otel`-enabled example. One option is that the RED histogram served at `/metrics` by native scrape is that leg. If so, say how it meets "actual export". The alternative is to state what else is required and who owns it.
- (c) Add a combined `--features metrics,otel` build-and-scrape check to the "Unproven, left for P03" list, conditioned on R78 publishing. The check should show that the `metrics` global recorder and R78's tracer pipeline coexist and that `/metrics` still serves.
- (d) Reword re-verify trigger (6) so it also fires when R78 publishes any position on the metrics leg other than "metrics are R79's".

### JF3-2 — OV-07 numbering is presented as open, but the controller ruled on it nine days before revision 3

**Failed claims.**
- `DECISION.md:92`: "**OV-07 numbering**, still open from revision 2 (re-verify trigger 14)."
- `:712`–`:716`: "**A decision the controller owns:** either `OV-07` carries both rows, as written here, or R79 needs a second number."
- Re-verify trigger (14) at `:847`: "the controller rules on whether the single allocated number `OV-07` may carry both of R79's departures or whether a second number is issued, the open question recorded under the override".

**Evidence.** `docs/planning/p02/execution-ledger.md:1088` was committed in `6a0cae7d` at 2026-09-18 22:38 -0700, and that commit's subject is "rule OV-07 carries both R79 departures". The line reads: "Ruling: OV-07 may carry R79's two departures under the one number … The R79 synthesis agent's open question is thereby answered; no second number is allocated." The decision cites this same ledger at `:1073` and `:1074`, and its completion note says the second pass "verified every file-and-line citation". Line `:1088` was missed.

**Repair.**
- Replace `:92` and `:712`–`:716` with a citation of the ruling at `execution-ledger.md:1088` (commit `6a0cae7d`).
- Retire re-verify trigger (14).

The text already implements the ruled outcome, so no other change is needed.

## Observations (not findings)

- **Muse leg registration.** `operations/muse.json` is in state `submitting`, `raw/muse.md` is untracked (sha256 `15529e48…c378`, matching the value the decision states), and `manifest.json` still lists only `opus` under `operations`. Controller note (a) says this is expected; registration happens at pack time. The adjudication prose was judged on its merits and passes JF-3.
- **Gate 2 at dependency-tree level.** The E4 graph contains 12 crates that declare no `rust-version`. Four of them enter with the `metrics` feature: `evmap`, `hashbag`, `left-right` and `sketches-ddsketch`. No build ran on a 1.96 toolchain. The decision follows programme practice: the strict "no declaration fails" reading applies to candidates, and the tree is judged by its highest declared value (`raw/opus.md:590`–`:594`, and the accepted R69 decision at `:2467`–`:2469`). This is therefore not a finding. R69 states the limit explicitly: the figure is "a floor on what is declared, not a proof that the tree compiles at 1.96". R79 does not. Adding that sentence to the "Unproven" list would be cheap.
- **Sibling pins that moved.** R05 is cited as "revision 3". The live file is now revision 5, and the quoted sentence is still present in it, so the pin still resolves. The R69 revision-10 citation, `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791`, resolves to the `owns web-extra-surface` line. Neither is stale.
- **The prompt Context error is escalated, not edited.** The decision reports to the controller that the prompt's phrase "no env gate" is contradicted by py's `settings.py:64` and `app.py:148`, and it leaves the input unedited. py's source confirms the contradiction. Handling it this way is correct.
