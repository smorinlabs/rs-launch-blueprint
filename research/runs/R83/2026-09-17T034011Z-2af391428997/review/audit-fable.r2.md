actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: a6e3bfa5f128857185b930b50f1fc48b3da37a3f1bb3d8cee7725137c0bd3ec6
verdict: reject
unresolved-findings:
- JF2-3-1 (blocking): boundary-invalid generation is neither decided nor adjudicated. The prompt asks about "valid and boundary-invalid" payloads. The decision's P2 and its mapper cover only in-range values. The Muse report's "valid and boundary-invalid" design is absent from D1–D9. Details and the repair are under "Findings" below.

# R83 openapi-contract-fuzzing — judgment audit of revision 2

Auditor: fable (Claude Opus family), a fresh context that is independent of the synthesizer.
Date of audit: 2026-09-27.
Target: `research/runs/R83/2026-09-17T034011Z-2af391428997/review/DECISION.md`, revision 2.

Hash check, done first: `shasum -a 256` returned `a6e3bfa5f128857185b930b50f1fc48b3da37a3f1bb3d8cee7725137c0bd3ec6`. This equals the expected value.

Scope: this audit judges the decision's reasoning and fidelity. It does not judge execution. It read no `review/audit-*.md` file of any seat or revision and no `review/R83-r1-snapshot.md`. It ran no runner command and made no git write.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** (part of finding JF2-3-1) | Revision-note row F4 says "`limit=0` and `limit=101` must yield `422`, not 5xx". The Generation row (`:186`) fixes the `limit` boundary targets at `1` and `100` only. The mapper design never generates `0` or `101`. So the stated 422 contract lies in an input class the design cannot reach, and the decision does not say so. Every other cross-reference agrees: the revision note, the design table, `## Parameters`, the coupling bullets, the re-verify line and `## Engines` describe the same recommendation (`oas3 = "0.22.0"` dev-dependency, mapper in `tests/common/`, R32 owns placement). |
| JF-2 every question answered, every constraint honored | **fail** (finding JF2-3-1) | `inputs/prompt.md:36`, HIGH question 2, asks whether a candidate derives "both valid and boundary-invalid request payloads per operation … or would a Rust port require assembling that capability … and if so what is the assembly cost". The decision measures the assembly cost at 482 lines (`:127`, confirmed by `wc -l` = 482 on `contract-fuzz-probe/tests/contract_fuzz.rs`). It never states whether the assembled harness generates boundary-invalid inputs. P2 (`:96`) reads "including its declared boundary values". Declared boundaries are valid values. All other questions are answered: HIGH Q1 (landscape and A1–A5), HIGH Q3 (P1–P5 and the ts structural absence), MEDIUM checks (P3 plus the R5.2 and R4.3 oracles), MEDIUM discovery (served-first with snapshot fallback), and LOW maturity (gates and B-series). Constraints are honored: stable 1.98, edition 2024, gate 2 against the 1.96 floor, gate 1 `inapplicable` under Q7.B (`owner-decisions.md:157`–`:159`), and the Linux leg stated as unproven. |
| JF-3 `## Engines` fidelity and adjudication | **fail** (finding JF2-3-1) | Nine disagreements are represented faithfully. Each Muse line cite was checked against `raw/muse.md` (sha256 `dbd36128…`, 138 lines): `:25`, `:27`, `:35`, `:42`, `:43`, `:45`, `:47`, `:51`, `:64`, `:65`, `:69`, `:73`, `:85`–`:86`, `:91`–`:93`, `:105`, `:109`. Each disagreement is adjudicated with evidence. One disagreement is **not** adjudicated: Muse's generation scope. Muse says "valid and boundary-invalid" at `raw/muse.md:23`, `:25`, `:65` and `:93`. It is missing from D1–D9. The agreement list at `:579`–`:589` covers the **assertion** (no 5xx), not the **generation scope**. The Opus report and the Muse collection state are recorded accurately. `manifest.json` shows `state: partial`, `required_engines ["muse","opus"]`, a muse op with `request_id 2c70e838…` in state `submitting`, and a codex→muse migration at 2026-09-21T23:06:21Z by `controller-muse-spark`. `raw/muse.md` is untracked (`git ls-files --error-unmatch` fails). The decision adjudicates unpinned bytes, says so, and makes a different collected hash a trigger that voids the adjudication. That meets RUNBOOK §5's "state uncertainty when evidence is incomplete". |
| JF-4 load-bearing claims trace | pass | Each cite below was spot-checked at its line. R11 rev 7: `:202` "`web` now equals `code`"; `:278` "an ordered step of `check`, under `!cancelled()`"; `:282` the R32 slot default; `:320` "ONE job named check per entry of target-os-matrix … fail-fast false", "cargo test over the workspace with the feature on", "ordered steps sharing one target/". R72 `:154`–`:156` ("capped at 100", "`limit=0` and `limit=101` are rejected with `422`"). R33 `:27` (`proptest` 1.11.0). R69 rev 10 `:1791` (`crates/web/tests/`, "no file-level `#![cfg(feature = "web")]`"). R02 rev 2 `:128` (workspace membership builds the web member). Ledger `:1000` (W1-CODEX3) and `:1114` (Q5.A). Owner decisions `:488`. COMMONALITY `:307` (F303) and `:338` (F334). R70 rev 4 `:131`–`:139` (problem+json and `catalog_code`) and `:408` (infrastructure carve-out). R42 `:492` (the prefix prohibition quote). Owner reference `:50`, `:72`, `:377`. RUNBOOK `:70`–`:73` (R83 in the Muse bulk set; Q9.B). |
| JF-5 couplings hand off without deciding | pass | R71 gets three stated needs, with conditional outcomes. R32 gets the exclusion mechanism and the step-or-job placement. The decision states three requirements and chooses none of them (`:290`–`:296`). The CI row is now a requirement, not a placement (`:270`). R11's default is read, not changed. The Justfile spelling defers to R42 and R32. The `#[ignore]` in `M8` is explicitly labeled a stand-in, not a selection (`:509`). |
| JF-6 `assumes` lines byte-identical to the live registry | pass | A script split each of the five `- assumes <param> = <value>` lines and compared the value to the `value` cell of the matching row in `docs/port/PARAMETERS.md`. All 5 are exact string matches (column 3). `diff inputs/PARAMETERS.md docs/port/PARAMETERS.md` differs only on the `ci-job-structure` row, which R83 does not consume. This matches the decision's statement at `:375`–`:380`. |
| JF-7 no conflict with accepted or published prerequisite values | pass | `inputs/prerequisites.json` pins R69 decision `d4507f5b…`. That equals the sha256 of `research/topics/69-web-framework-stack/DECISION.md`, whose header reads "revision 9". The design uses revision-10 paths (`crates/web/tests/`). The decision records this transparently (`:358`–`:370`): it keeps the `assumes` line at the revision-9 bytes and makes R69's republication a trigger. That is a recorded pending publication, not a conflict. The `tower` observation (`:226`–`:232`) refines R69's value and does not contradict it. `proptest` 1.11.0 matches R33. The Muse range `>=1.9,<2` is correctly refused (D4). |
| JF-8 evidence scripts exist; counts match | pass | All four scripts and seven logs are present. The totals were grepped from the logs. `contract-fuzz-probe.log` 24/24. `registry-and-standard.log` 29/29. `muse-adjudication.log` 8/8. `registry-skip-paths.log` 12/12, with the inner `SKIP=6 TOTAL=6`. `registry-skip-paths.pre-fix.log` `PASS=5 FAIL=7`. `clean-extraction.log` 24/24 and 29/29. `r2-copy-rerun.log` 8/8, 12/12 and 29/29. The sum 24+29+8+12 = 73 matches `:422`. These named lines exist with PASS: A13–A15, A19–A21, B3, B5, B7, B9, B13, B22, B23, B27, M2, M4, M6, M7, M8. |
| JF-9 decision shape | pass | The four required H2s are present in order: `## Decision` (which contains `### Principles and implementation` and a `re-verify:` line at `:343`), `## Parameters`, `## Empirical check` and `## Engines`. There is no `## Supersedes`, which is correct because the recommendation did not reverse. The settled row F334 is named. |
| JF-10 the recommendation follows from the evidence | pass, with a qualification | `oas3` over `openapiv3` follows from B27 and M1–M5. In-process `oneshot` follows from the resident R69 idiom and A1–A15. Served-first discovery is argued from the py precedent and the R71 staleness test. The qualification belongs to finding JF2-3-1. The Tradeoffs sentence (`:335`) accepts the depth lost to the runner-up because it is "depth a first generated 3.1 document cannot exercise". That reason does not cover negative generation, because every bounded integer admits min−1 and max+1. The recommendation itself can stand once the finding is repaired. |

## Findings

### JF2-3-1 (blocking; JF-2, JF-3, with JF-1 and JF-10 consequences) — boundary-invalid generation is neither decided nor adjudicated

**Failed claims, quoted.**
- P2 (`DECISION.md:96`): "Inputs are generated from each operation's declared schema, including its declared boundary values".
- The Generation row (`:186`): "**explicit boundary bias** through `proptest::strategy::Union` over `{minimum, maximum, 0-if-in-range, uniform}` … For R72's published `limit` (`1..=100` …) the boundary targets are therefore `1` and `100`".
- The revision-note row F4: "`limit=0` and `limit=101` must yield `422`, not 5xx".
- Tradeoffs (`:335`): "the depth given up is depth a first generated 3.1 document cannot exercise".

**Evidence.**
1. The prompt requires this point to be answered. `inputs/prompt.md:36` asks whether candidates derive "both valid and boundary-invalid request payloads per operation directly from the schema … or would a Rust port require assembling that capability from lower-level pieces, and if so what is the assembly cost?"
2. The probe generates valid values only. In `review/evidence/contract-fuzz-probe/tests/contract_fuzz.rs:348`–`:355`, the integer `Union` is `Just(min)`, `Just(max)`, `Just(0)` only when 0 is in range, and a uniform draw over the declared range. There is no out-of-range arm, no wrong-type arm and no missing-required arm.
3. The Muse report takes the opposite position. `raw/muse.md:23`, `:25`, `:65` and `:93` all specify "valid and boundary-invalid" generation. D1–D9 do not mention it.
4. The py precedent's library generates invalid inputs by default. schemathesis is pinned at 4.21.5 in py `uv.lock` at `b08bccfb`; the copy installed in the local py checkout is the same version. Its `config/_generation.py:63` reads `self.modes = modes or list(GenerationMode)`, and `GenerationMode` has `POSITIVE` and `NEGATIVE` (`generation/modes.py:6`–`:12`). The py test at the pin overrides no generation mode (`tests/web/test_contract.py:21`–`:30`). This audit did not trace every path by which `@schema.parametrize()` reaches that default. The narrower claim is established: the library's default mode set includes negative generation, and py's test changes nothing.
5. The decision's own gap list is incomplete. The coverage-boundary paragraph (`:234`–`:247`) lists query, header and cookie parameters, `number`-as-`integer`, `format`, `pattern`, `oneOf`, `allOf`, `anyOf` and `discriminator`. It does not list negative generation. The runner-up win conditions (`:321`–`:325`) name `format`, `oneOf` and response conformance, but not negative testing. "Negative testing" appears only as a runner-up capability (`:320`).

**Why the finding blocks.** The prompt asks HIGH question 2 in exactly these terms, and it names "boundary-invalid" explicitly. The decision narrows P2 below that wording and below the precedent's default behavior without saying so. It also leaves the second engine's contrary position unadjudicated. R72's published `limit=0` and `limit=101` contract is the concrete input class that is lost.

**Repair.** The synthesizer must write down one of the two choices below. This audit requires that a choice be recorded; it does not require a particular choice.
- (a) **Adopt negative generation.** Widen P2 and the mapper design to include boundary-invalid arms: min−1 and max+1 for bounded numbers, length±1 for bounded strings, a wrong JSON type, and a missing required property. Keep the oracle unchanged at no 5xx, so that a `422` or `400` passes. Adjust the design element, the migration rows and acceptance criterion 7. State whether that part of the design is executed or proposed.
- (b) **Decline negative generation explicitly.** Keep P2 as it is. Add negative generation to the `:234` gap list. Justify the omission against py's default behavior; one possible ground is that axum extractors turn most such inputs into 4xx before the handler runs. Add negative generation to the runner-up win conditions. Remove or reword the F4 sentence so that it does not imply the harness exercises `limit=0` and `limit=101`.

Under either choice, add a D10 row to `## Engines` that quotes Muse's "valid and boundary-invalid" position (`raw/muse.md:23`, `:25`, `:65`) and settles it with evidence. Also answer HIGH question 2's "boundary-invalid" clause explicitly.

## What passed

Revision 1's findings F1–F5 are answered as the revision note claims. Specifically:
- The Muse leg is now represented.
- R11 is cited at revision 7's lines.
- The CI placement is handed to R32.
- R70 and R72 are current.
- The SKIP-label mismatch is fixed, and the new `B10` defect is demonstrated in `registry-skip-paths.pre-fix.log` (`HTTP 000000`).

The one blocking gap is JF2-3-1.
