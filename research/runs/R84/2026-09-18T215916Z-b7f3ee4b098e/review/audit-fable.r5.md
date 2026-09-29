# R84 — judgment audit of DECISION.md revision 5

actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 4c8951837f0b31eedf908b2fe9a65cfce02078708168d047dd5eba78bca82f4b
verdict: reject
unresolved-findings:
- JF-2-A — the fitness gates were not answered for four of the five bin-3 candidates, and
  the qualified-shortlist sentence claims a result about candidates that were never gated.
  This finding does not move the recommendation. Full text under `## Findings`.

Scope: reasoning and fidelity of `research/runs/R84/2026-09-18T215916Z-b7f3ee4b098e/review/DECISION.md`
revision 5, judged against ten checks (JF-1 to JF-10). Execution truth belongs to the
empirical audit; this seat spot-checked evidence and reran no script. Per the seat's
instructions, it read no `review/audit-*.md` and no `review/R84-r*-snapshot.md`.

Hash check. `shasum -a 256` on the decision gave
`4c8951837f0b31eedf908b2fe9a65cfce02078708168d047dd5eba78bca82f4b`, which equals the
expected value. The three raw reports hash to the values in the decision's report table
(`caecee02…`, `76781e70…`, `9f01d68b…`).

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **pass** (one note) | The r5 repair is consistent. `0.19.0` was created `2026-09-26T14:29:43Z` (`snapshots/registry-figures.json`). Six months after that is 2027-03-26. That date is used by the `re-verify:` line and by trigger 8 ("after 2027-03-26"). The "or earlier" list names seven events, one per trigger 1–7. The header's counts (60/0/0, 31/0/5, 6/0/0, 31/0/0, 31/0/5) match the five log summary lines. The figures in the question table, the maintenance paragraph and the shortlist agree with each other and with the snapshot: 37 stars, 46,601 all-time downloads, 45,945 90-day downloads, 35 live versions of which 33 fall in 2026-02-13..2026-09-14, 0 reverse dependencies. **Note:** the header says revision 5 changed "only the `re-verify:` line". This seat cannot verify that claim, because reading the r4 snapshot is forbidden. It is accepted on the header's word, and the empirical auditor's diff is the check. The internal contradiction in the shortlist sentence is filed under JF-2-A, not here. |
| JF-2 prompt questions and constraints | **fail** → JF-2-A | All six prompt questions are answered in the question table (`DECISION.md:217-226`), and the cross-repo principle question is answered by the agreement-level table (`:381-387`). The mechanism constraints are honored: stable Rust, edition 2024, the 1.96 floor, and the licence gate recorded as inapplicable under Q7.B. One required-evidence rule is not honored. `prompt.md:63` says "Fitness gates, answered per candidate **before** popularity is weighed". The gate table (`:451-455`) has rows for only three candidates. The bin-3 candidates `spargen`, `ploidy`, `openapi-nexus` and `oas3-gen` are disposed of on adoption alone (`:493-497`). |
| JF-3 `## Engines` fidelity | **pass** | Spot-checked against the raw reports. Muse recommends `openapi-to-rust` 0.17 with committed output and a `--check` CI gate. Its runner-up is progenitor, "if and when Oxide ships OpenAPI 3.1 support", then OpenAPI Generator. It lists nothing under Excluded by gate, has `CONFLICT: none` and emits no `BASELINE-REVIEW:` (Muse raw `:175`, `:351`). Opus recommends OpenAPI Generator 7.25.0 with `supportAsync=false` and `exclude = ["clients"]`, names `openapi-to-rust` as runner-up, and has the "`total_count: 0`" claim. Doxa-OpenAI proposes committed `crates/api-client` (`doxa` raw `:470`, `:530`), excludes OpenAPI Generator as "Not a Rust crate" (`:392`), writes "zero candidates are fully evidence-complete" (`:378`) and emits `BASELINE-REVIEW: F335` (`:304`). Doxa-Perplexity has three `owns` lines (`:1188-1196`) and the "npm-based CLI" claim (`:1094`). Doxa-Gemini has the `time 0.1` / RUSTSEC-2020-0071 exclusion, ">120" stars, "~16,000" downloads and two `owns` lines (Gemini section `:284-300`, `:344-345`). All four disagreements are adjudicated with cited checks. The disagreement over spargen's shape is not adjudicated; it is folded into JF-2-A. |
| JF-4 load-bearing claims trace | **fail** (same defect) → JF-2-A | Spot-checks that passed: R4.1 at `rest-api-standard.md:742-747`, R5.12 at `:1019-1021` ("when the client requests it"), R12.6 at `:1815-1817` and R12.7 at `:1819-1822`, all read from blob `0850d43e:rest-api-standard.md`. `openapi-to-rust` 0.17.0 `src/client_generator.rs:1436-1447` skips a caller's `accept` header and sets `ACCEPT` to `#media_type` (the check prints `:1436-1446`; the one-line difference is the closing brace and is immaterial). The R69 C3 TS-client row is at `research/topics/69-web-framework-stack/DECISION.md:2188`, and R69 revision 10's `owns web-extra-surface` line is at run `DECISION.md:1791`. Owner-reference rows `:50` and `:51` are the OpenAPI and TS-client rows. The median issue-closure time, recomputed from the snapshot's ten `closed_after_days` values, is 1.445 days. The G6 timings (116 s, 44 s, 16 s) match `snapshots/openapi-to-rust-timings.txt`. The one untraceable claim is the shortlist sentence (JF-2-A). |
| JF-5 couplings | **pass** | R71 receives N1–N4 as requirements, "not decisions made for it". R70 keeps the question of what its server emits when `Accept` omits `problem+json` (coupling 7). R11 gets no CI job request. R42 gets one row through its own mechanism. R49 gets no `build.rs`. R02 and R05 values are quoted, not re-decided. R83 is left unconstrained. The decision declines R69's routing of the C3 TypeScript-client row to R84 and labels the row "pending owner scoping". That leaves the row with the owner rather than deciding it. |
| JF-6 `assumes` lines vs live registry | **pass** | A script compared all five `- assumes` lines, byte for byte, against the `value` column of `docs/port/PARAMETERS.md` and against `inputs/parameters.json`. All five matched both. The `web-extra-surface` row at `HEAD:docs/port/PARAMETERS.md` has the same text. |
| JF-7 prerequisite conflicts | **pass** | `research/topics/69-web-framework-stack/DECISION.md` hashes to `d4507f5b…` and its `acceptance.json` to `48a7dce8…`, both equal to `inputs/prerequisites.json`. R69 revision 10, R02 revision 2 and R05 revision 3 are recorded as `accept` in `OWNER-ACCEPTANCES.md` (`:60`, `:71`, `:75`), which matches the decision's "accepted, unpublished" labels. Published R42 and R49 values in the registry carry the quoted clauses: bare invocation, `command -v`, and "no build.rs and no build-orchestration crate". No `CONFLICT:` is needed. |
| JF-8 evidence scripts and counts | **pass** | All five scripts and six logs exist under `review/evidence/`. Summary lines: source-claims 60/0/0, probe 31/0/5, 0.19.0 probe 31/0/5, progenitor 6/0/0, registry 31/0/0. Every check ID the decision cites exists in a log (the T01–T22, R01–R13, AU01, P01–P05/P02b, F/RS/M/CB/G and A–E ranges). `diff` between the 0.17.0 and 0.19.0 probe logs is exactly the `T01` line. `r84-archive-rerun.log` shows `A13` PASS→SKIP and 60/0/0→59/0/1 for source-claims, and only the retrieval-date line for the registry log. This matches the decision's text at `:671-677`. |
| JF-9 decision shape | **pass** | H2s: `## Decision` (with `### Principles and implementation`, settled row F335, and a `re-verify:` line), `## Parameters`, `## Empirical check` (toolchain, OS, working directory, commands, observed output), and `## Engines`. There is no `## Supersedes`, which is correct because nothing for R84 is published. This matches RUNBOOK §5. |
| JF-10 recommendation follows from evidence | **pass** | `openapi-to-rust` behind `just client-rust` follows from the recorded evidence. Only it and OpenAPI Generator are shown to read 3.1. OpenAPI Generator cannot meet R12.4, a MUST (`E04`, `E05`), and progenitor refuses 3.1 (`D01`–`D03`, `P02`). The `OV-11` SHOULD departure is argued with options. JF-2-A leaves the pick unchanged: no bin-3 alternative has evidence that would displace it. It does leave the shortlist and the gate record incomplete. |

## Findings

### JF-2-A — bin-3 candidates were never gated, yet the shortlist claims they fail the gates

**Failed claim** (`DECISION.md:468-469`): "Qualified shortlist — two candidates, and the
shortness is a finding. Only two surveyed tools can read the 3.1 document R4.1 requires and
clear every applicable gate."

**Evidence.**

1. The prompt's rules. The prompt requires gates "answered per candidate **before**
   popularity is weighed; a failed gate lists the candidate under *Excluded by gate*"
   (`prompt.md:63`). The shortlist is "Up to five that passed every gate (fewer is a
   finding)" (`:86`). The bin map is the candidate pool (`:42`).
2. What the decision gated. The bin-3 row lists five candidates: `openapi-to-rust`,
   `spargen`, `ploidy`, `openapi-nexus` and `oas3-gen` (`DECISION.md:429`). The gate table
   has rows for `openapi-to-rust`, OpenAPI Generator and progenitor only (`:451-455`). The
   other four receive no gate answer. They are dismissed in the Up-and-comers paragraph on
   adoption: "no located adopter", and "None has enough adoption or independent verification
   to carry a template" (`:493-497`). That is popularity weighed without gates. It is also a
   bar the pick itself barely clears: 0 reverse dependencies, and one adopter with 20
   downloads.
3. `spargen`. The decision's own facts show it reads 3.1: "3.1/3.2 only", `rust 1.88`, and
   licence `MIT OR Apache-2.0` (`:493-494`). crates.io describes it as "A compile-time-correct
   Rust client generator for OpenAPI 3.1.x and 3.2.x" (public read, 2026-09-27). The engines
   disagree about its shape. Muse says it has "`build.rs`/macro modes" and "no recipe-shaped
   file emission story" (Muse raw `:42`, `:337`). If that is right, R49's clause excludes it,
   the same way the decision excludes `openapi_gen` and `toac-build` (`:490-491`). Doxa-OpenAI
   says it "recommends checked-in CLI generation" and "provides `--check`" (doxa raw
   `:386`). If that is right, it may clear every gate. The decision adopts Doxa-OpenAI's
   description ("a `--check` mode") and does not adjudicate the conflict. It marks spargen
   "not probed", so the claim that it cannot clear the gates has no support.
4. `oas3-gen`. crates.io describes it as "A rust type generator for OpenAPI v3.1.x
   specification" (public read, 2026-09-27). It reads 3.1, and if it generates types only,
   it is out of category. The decision applies that rule to `openapi-model-generator` (`:431-432`)
   and to architecture E (`:445`), but it lists `oas3-gen` in bin 3 without the disposition.
5. `ploidy` and `openapi-nexus`. They have no stated 3.1 capability and no gate answer.
   (crates.io: "An OpenAPI compiler for large and complex specs"; "OpenAPI 3.x
   multi-language code generator".)

The sentence therefore asserts a gate result for four candidates that the decision never
evaluated. For at least `spargen`, the decision's own evidence points the other way.

**Effect.** The recommendation does not move. No bin-3 alternative has evidence that would
displace `openapi-to-rust`. The defect is that the shortlist and the gate record, which
P03 and later re-verification rely on, overstate what was established.

**Repair** (prose and landscape only; no script needs to change):

- Give each of `spargen`, `ploidy`, `openapi-nexus` and `oas3-gen` a per-gate disposition:
  a row in the gate table, or one line each. Where a gate was not evaluated, write
  `not evaluated` and name the gate. Do not imply a failure.
- For `spargen`, record the Muse versus Doxa-OpenAI disagreement about recipe-shaped
  emission under `## Engines`, and settle it from spargen's README. If it is
  `build.rs`/macro-only, move it to *Excluded by gate* under R49's clause, next to
  `openapi_gen`. Otherwise either admit it to the shortlist with its figures, or state that
  its gates were not evaluated.
- Dispose of `oas3-gen` as out of category (types only) if its documentation confirms that,
  or give it gate answers.
- Reword `:468-469` to claim only what was evaluated. For example: "Two candidates were
  gated and qualify; `spargen`, `ploidy`, `openapi-nexus` and `oas3-gen` were not gated
  here (dispositions above), so the shortlist's length reflects evaluation coverage as well
  as the field."

## Seat notes

- This seat made read-only public queries to `crates.io/api/v1/crates/<name>` for four
  crates on 2026-09-27 UTC. All four succeeded.
- This seat made no git writes, ran no `scripts/research_runner.py` command, made no paid
  call, and wrote no file other than this one.
