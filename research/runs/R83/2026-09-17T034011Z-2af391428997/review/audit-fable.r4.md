actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 342b9874e93b8079b4c0cad9fc258676fdbf137e1cf54d53e702b329a62a7093
verdict: approve
unresolved-findings:
  - JF4-1-1 (MECHANICAL; JF-1) — acceptance criterion 7, first half, still claims per-run certainty for the valid mode
  - JF4-1-2 (MECHANICAL; JF-2/JF-1) — `## Engines` P03 item (6) names query parameters only

# R83 openapi-contract-fuzzing — judgment audit, revision 4

This is the judgment audit of `review/DECISION.md` revision 4. The sha256 was recomputed with
`shasum -a 256` before reading anything else, and it matches the expected
`342b9874…7a093`. This is an r2+ audit, so under the programme severity rule only BLOCKING
findings can reject. **No BLOCKING finding was found.** Two MECHANICAL findings are listed below
with their exact repairs, for S1 to fold into the same round.

Files read: the decision; `inputs/prompt.md`; `inputs/prerequisites.json`; `research/RUNBOOK.md`
(auditor roles, §2); `raw/muse.md` (spot lines); the evidence logs and the probe source under
`review/evidence/`; the prerequisite and coupled decisions at the cited lines. No
`review/audit-*.md` file of any seat or revision was read, and no `R83-r*-snapshot.md` was read.
Nothing was rerun. The separate empirical audit owns execution.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **pass, with one mechanical defect** (JF4-1-1) | The two r3 findings are repaired consistently. First, the Generation row (`:232`) now takes `in: path`, `in: query`, `in: header` and `in: cookie` parameters, and the `contract_fuzz.rs` and `common/mod.rs` migration rows (`:318`, `:319`) match it. Second, the boundary-invalid mode now enumerates one case per declared arm (`:232`, `:234`), which matches criterion 7's second half (`:130`–`:134`). The Tradeoffs statement (`:393`–`:395`) and the runner-up's "four arms" clause (`:376`–`:378`) agree with the new design. The coverage-boundary paragraph (`:281`–`:285`) describes the probe, not the design, and says so. The first half of criterion 7 is the residual defect; see JF4-1-1. |
| JF-2 prompt questions and constraints | **pass** | The Decision question is answered first: no `schemathesis` equivalent exists, and the named crate is `oas3 = "0.22.0"` (`:44`–`:67`). HIGH 1 is answered by A1–A5 and the gates. HIGH 2 has its own paragraph covering both modes and the cost (`:158`–`:188`). HIGH 3 (principles) is answered by P1–P5, the "may vary" list, and the ecosystem-difference paragraph. MEDIUM checks: P3 plus the two measured extra oracles (`:216`–`:223`). MEDIUM discovery: the Schema discovery row. LOW maturity: `B3`–`B9`, `B23`, `B24`. The out-of-scope items (R71, R84, R69, R32) are handed off, not decided. The item kind `crate` delivers a named crate with a version range. |
| JF-3 engines represented and adjudicated | **pass** | The Muse sha256 recomputes to `dbd36128…c5df`, 138 lines, matching `:651`. The manifest shows `state: partial`, `required_engines ['muse','opus']`, and `operations.muse.state: submitting` with request `2c70e838…`, matching `:629`–`:653`. Cited Muse lines were spot-checked: `:23`, `:25`, `:45`, `:47`, `:65`, `:73`, `:93`, `:105`, `:109` all say what D1, D6, D9 and D10 attribute to them. Each of D1–D10 has an evidence ground, and each ground is executed (`M1`–`M8`), sourced (R33 `:27`, R69 r10 `:1791`, owner ruling Q7.B), or plainly labelled as inference. |
| JF-4 load-bearing claims trace | **pass** | R72 `:154` reads "`limit` defaults to 50 and is capped at 100. `limit=0` and `limit=101` are **rejected with `422`**". R33 `:27` gives `proptest` 1.11.0. R11 `:202`, `:278`, `:282` and `:320` say what the CI row quotes. R02 r2 `:128` gives the workspace-membership sentence. R70 r4 `:131`–`:139` and `:407`–`:410` give the envelope and the carve-out. The probe's `contract_fuzz.rs:347`–`:355` holds the `Union` of `min`, `max`, uniform and `0`-if-in-range, with no invalid arm. The py pin checks out: `uv.lock:2257`–`:2258` at `b08bccfb` gives `schemathesis` 4.21.5, the `.venv` dist-info is 4.21.5, `_generation.py:63` reads `modes or list(GenerationMode)`, `modes.py` defines `POSITIVE` and `NEGATIVE`, `builder.py:103` reads `st.one_of(… for mode in generation.modes)`, `_projects.py:396`–`:418` returns `self.generation` when no config applies, and `tests/web/test_contract.py` sets only `max_examples=10`, `deadline` and `checks`. |
| JF-5 couplings hand over owned choices | **pass** | R32 keeps the exclusion mechanism and the step-or-job placement (`:237`, `:343`–`:349`). R71 keeps the generator, and the harness is conditioned on its three plausible outcomes (`:328`–`:342`). The exact `422` stays with R72 (`:232`, `:355`–`:359`). `proptest` and `tower` are cited as other items' values and not re-decided (D4). The `tower` normal-graph observation is recorded as a refinement, not a `CONFLICT:`. |
| JF-6 `assumes` lines byte-identical to the live registry | **pass** | A script compared each of the five `- assumes` values against the value column of `docs/port/PARAMETERS.md`. All five are equal. The set is the four fixed rows plus `web-extra-surface`, which is the prompt's only `- consumes:` entry. |
| JF-7 no conflict with accepted or published prerequisites | **pass** | `inputs/prerequisites.json` pins R69 `decision` `d4507f5b…c10d`, and `research/topics/69-web-framework-stack/DECISION.md` hashes to exactly that value. Its header reads "revision 9", which supports the decision's r9-registry / r10-pending note (`:418`–`:430`). The prerequisite values used (R33, R42, R72 r5, R11 r7) are consistent with the text cited. |
| JF-8 evidence scripts exist and counts match | **pass** | All four scripts are present. The logs print `PASS=24`, `PASS=29`, `PASS=8` and `PASS=12`, each with `FAIL=0 SKIP=0`, for a total of 73. That matches `:472`–`:482`. `pre-fix.log` prints `PASS=5 FAIL=7`, matching `:476`. `A2`, `A6`, `A7` and `A13`–`A15` are PASS lines at the cited meanings. The probe harness is 482 lines, matching `:141` and `:164`. |
| JF-9 decision shape follows the published contract | **pass** | The H2 set `## Decision`, `## Parameters`, `## Empirical check`, `## Engines` matches the published `research/topics/53-config-schema-validation/DECISION.md` exactly (lines 52, 549, 587, 736 there). The file also has a revision header, a `re-verify:` line and `assumes` lines. |
| JF-10 recommendation follows from the evidence | **pass** | No gate-passing Rust equivalent exists (`B1`, `B2`, `B3`–`B5`, `B23`). The assembled architecture was executed end to end (`A1`–`A15`). `oas3` beats `openapiv3` on gate 2 (`B27`) and on 3.1 parsing (`M2`–`M5`). Everything is dev-only (`A19`, `A20.*`). The r4 edits change text only, and the named crate, its range and the architecture follow unchanged. |

## Unresolved findings (MECHANICAL — approve-with-repair)

### JF4-1-1 (MECHANICAL; JF-1) — criterion 7's first half is a random-draw outcome, stated as a per-run guarantee

**Failed claim** (`:129`): "For each operation, the generator produced at least one valid case at
each declared boundary, …"

**Evidence.** The Case count row (`:234`) keeps the valid mode at
`Config { cases: 16, .. }`, which means 16 random draws. The Generation row (`:232`) and the probe
(`contract_fuzz.rs:347`–`:355`) draw each number from a `Union` over `{min, max, uniform,
0-if-in-range}`. Here is a worked number. For R72's `limit` (`1..=100`, so the `0` arm is absent),
each draw hits `1` with probability 1/3. The chance that 16 draws never hit `1` is
(2/3)^16 ≈ 0.15 %. That chance is small but not zero. It compounds across every bounded field,
every end of every bound, and every operation. The revision note itself says only that "the second
half holds by construction in the fuzz run itself" (`:16`). So the first half is not a per-run
guarantee, and a P03 assertion written from the criterion's wording would be flaky.

**Why this is MECHANICAL and not BLOCKING.** It has the same form as JF3-1-2, but not the same
consequence. At r3, the boundary-invalid mode could produce **no** out-of-bound value under any
draw, which the decision itself states (`:133`–`:134`). That was a structural impossibility. The
valid mode has explicit `Just(min)` and `Just(max)` arms, and their reach was measured at 20 of 20
seeds (`A14`). The design is sound. A P03 path already exists in `contract_mapper.rs` (Mapper
placement row, P03 item (9)). Only the criterion's wording over-claims.

**Repair.** Choose one:

- (a) Reword criterion 7's first half as a property of the mapper that `contract_mapper.rs`
  asserts: "the mapper's valid strategy contains a `Just` arm for each declared boundary, and
  `contract_mapper.rs` asserts that each boundary is generated". Leave the per-run claim to the
  second half only.
- (b) Enumerate the declared boundary values deterministically in the valid mode too, one case per
  boundary, alongside the 16 random cases. Then update the Case count row so the valid count reads
  "16 plus one per declared boundary". Option (b) mirrors the r4 fix to the invalid mode.

### JF4-1-2 (MECHANICAL; JF-2/JF-1) — `## Engines` P03 item (6) is narrower than the r4 Generation row

**Failed claim** (`:755`–`:756`): "(6) Query-parameter generation against R72's `cursor`/`limit`."

**Evidence.** Revision 4's Generation row (`:232`) now puts `in: header` and `in: cookie`
parameters in scope. The `## Empirical check` gap list (`:614`–`:616`) says P03 proves "Query,
header and cookie parameter generation". The P03 validation list is the enumerated hand-off to
P03, and it still names query parameters only.

**Repair.** Change item (6) to read: "(6) Query, header and cookie parameter generation, proved
against R72's `cursor`/`limit` for the query location."
