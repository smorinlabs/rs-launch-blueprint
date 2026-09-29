actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 802e5292157c97b8530445a7a5c637d8ebcb71c4a3fe232eadd882c7dea5cc8b
verdict: reject
unresolved-findings:
1. JF-3 — `## Engines` misstates the item's engine set and omits the Muse report and its disagreements.
2. JF-1 — five count or prose statements contradict the decision's own enumerations or the script they describe.
3. JF-2 — the LOW prompt question has no answer.

# R70 http-problem-envelope — judgment audit (fable), revision 3

Target: `research/runs/R70/2026-09-17T034010Z-31ad2ef28df7/review/DECISION.md`.
The sha256 was recomputed with `shasum -a 256` before any reading. It equals the
expected `802e5292…`.

Scope: this audit judges the decision's reasoning and fidelity. It does not judge
execution, so no script was rerun. The auditor did not read any `review/audit-*.md`
file or the `R70-r2-snapshot.md` snapshot; the snapshot was only hashed.

## Verdict summary

**Reject.** The design recommendation is well-supported. Its evidence refutes every
position on which the Muse report differs, so JF-10 passes. However, revision 3
states that the item has one engine and no disagreements. The pinned inputs
contradict that statement. A Muse report is present in `raw/`, and the decision
neither represents it nor adjudicates it. The RUNBOOK §5 contract requires
`## Engines` to cover "all reports … disagreements, and the evidence that resolved
each disagreement". The repair is prose only; no research needs to be redone.

| Check | Result |
|---|---|
| JF-1 internal consistency | **fail** (finding 2) |
| JF-2 prompt questions and constraints | **fail** (finding 3) |
| JF-3 engines faithfully represented | **fail** (finding 1) |
| JF-4 claims trace to sources | pass |
| JF-5 couplings hand over owned choices | pass |
| JF-6 assumes lines byte-identical to registry | pass |
| JF-7 no conflict with prerequisite values | pass, with a caveat the decision itself states |
| JF-8 evidence scripts and counts | pass, with one prose overstatement (in finding 2) |
| JF-9 decision shape | pass |
| JF-10 recommendation follows from evidence | pass |

## Findings

### Finding 1 — JF-3: `## Engines` misstates the engine set and omits the Muse report

**Failed claims** (`## Engines`, lines 978–983):

> "**The Codex leg is absent by the controller's deferral under owner ruling
> W1-CODEX3 (2026-09-18)** … This item's policy tier is Focused, whose engines are
> `codex` and `opus`, so **this decision is synthesized from a single engine and
> there are no inter-engine disagreements to settle.**"

Line 405 repeats the claim: "This decision is synthesized from **one** engine (the
Codex leg is deferred under owner ruling W1-CODEX3)".

**Evidence:**

- The pinned prompt `inputs/prompt.md` has sha256 `b47f8a26…`, which equals
  `manifest.input_hashes.prompt`. That prompt reads `- engines: muse, opus` and
  states: "This item substitutes Muse (Meta) for Codex under the
  `engine_overrides` pilot; its mirrored `- engines:` line is authoritative."
- `research/EXECUTION.json` lists R70's engines as `["muse", "opus"]`. RUNBOOK §2
  names R70 in the Muse bulk-substitution set.
- `manifest.json` records the following:
  - `required_engines`: `["muse", "opus"]`.
  - A migration event dated 2026-09-21T23:06:20Z, from `codex` to `muse`, citing
    "owner decision Q5.A 2026-09-21".
  - A Muse operation with `state: submitting`, request `bd54932d…`, and no
    `raw_sha256`.
  - Overall run state `partial`.
- `raw/muse.md` exists. It has 218 lines, sha256 `989725675cb0…`, file mtime
  2026-09-24 23:17, and a stated retrieval date of 2026-09-25. It is a complete
  bundle-shaped answer.
- Revision 3 was written at 2026-09-26 20:26 -0700 (file mtime), after all of
  these events. Its revision note does not mention Muse.
- The Muse report disagrees with this decision on three load-bearing points. The
  decision addresses none of them as an engine disagreement:

| # | Muse position (`raw/muse.md`) | Decision's position | Evidence already in the decision that settles it |
|---|---|---|---|
| D1 | `http-api-problem` 0.60.0 is the dominant envelope crate. Muse reports "None of the envelope-crate candidates fails a fitness gate". `problemdetails` is runner-up; `problem_details` is not surveyed. | `problem_details` 0.10.0 is recommended. `http-api-problem` fails gate 2 because no published version declares `rust_version`. | `registry.log` asserts that zero versions declare `rust_version`. Muse concedes "crate declares no rust-version (None)" but does not apply gate 2. |
| D2 | The status table is an exhaustive `match` with "no wildcard arm", and totality is enforced at compile time. | This is impossible across the crate boundary because R67's `ErrorCode` is `#[non_exhaustive]`. Totality is instead enforced by a test over `ErrorCode::ALL`. | `probe.log` §5 shows both directions. R67 `DECISION.md:148-153` and Disagreement 7 at `:653-662` state the same constraint. |
| D3 | The seam is a trait method (`HttpStatus::status_code`) implemented on R67's type. | The trait method is rejected on layering grounds because it would put `http::StatusCode` in `crates/core`. The decision uses a free `const fn`. | R02 revision 2 topology (`:29`). J4's testability argument. |

Muse also states that no commands were executed ("Proposed, not executed"). Its
figures are dated 2026-09-25 and differ from the decision's figures dated
2026-09-18. For example, Muse lists `problemdetails` at 48,464 all-time
downloads. These figure differences are not load-bearing for the decision.

**Why this fails JF-3.** RUNBOOK §5 requires `## Engines` to cover "all reports
and evidence checks, disagreements, and the evidence that resolved each
disagreement". The decision instead asserts that there are zero disagreements, on
an engine premise the pinned inputs contradict. A reader of revision 3 cannot
tell that a second model family answered the prompt and reached a different crate
choice.

**Repair.** Take branch (a) or branch (b).

- **(a) The Muse report counts as the leg.** Rewrite the engine paragraph to name
  `muse` and `opus` as the item's engines and to cite the substitution (Q5.A,
  `engine_overrides`). List `raw/muse.md` with its sha256 and the resolved model.
  Add D1–D3 as disagreements, each settled by the evidence cited in the table
  above. Withdraw "no inter-engine disagreements", and withdraw or requalify the
  single-engine weakening paragraph at lines 983–987 and line 405.
- **(b) The Muse leg is not collected** (the manifest shows `submitting`). State
  that in the manifest's own terms: Muse is a required engine, the run is
  `partial`, and a report file exists without a collection receipt. Cite the
  controller authority for synthesizing on a partial run (RUNBOOK §3, "Partial
  multi-provider result"). Replace the Codex/W1-CODEX3 framing, which the pinned
  prompt supersedes.

Under either branch, the recommendation does not need to change. The three Muse
positions are each refuted by evidence the decision already carries.

### Finding 2 — JF-1: five count or prose statements contradict the decision's own enumerations or the script they describe

The revision-2 audit set a sentence-level bar for JF-1, so each statement is
listed separately.

1. **Carried and new criteria counts.** Lines 557–560 say "Twelve carry revision 1's
   behaviour forward unchanged (`R1`–`R3`; `R7`–`R10` and `R12`–`R17` …)". Lines
   560–561 say "**Twelve are new**". Line 797 says "carries revision 1's twelve
   surviving behaviours forward as `R1`–`R3`, `R7`–`R10` and `R12`–`R17`".
   - Evidence: the carried ranges contain 3 + 4 + 6 = **13** criteria. The new
     list (`R4`, `R5`, `R6`, `R11`, `R18`–`R24`) contains **11**. The total of 24
     is correct. `probe-r2.sh:895-1160` defines `r1_`…`r24_` with this
     partition.
   - Repair: change the counts to "Thirteen" and "Eleven". Alternatively, move one
     criterion between the lists so that the ranges match "twelve".
2. **"Five items" that are nine.** Line 1022 says "The five items under 'What these
   checks do not prove' above".
   - Evidence: that list, at lines 935–960, has **nine** bullets.
   - Repair: change "five" to "nine", or name the bullets meant.
3. **Revision-1 criterion count in J6.** Line 390 (J6) says "The fourteen executed
   criteria prove one envelope can cover domain, router, extractor and panic
   failures".
   - Evidence: revision 2 and revision 3 rest on the twenty-four criteria
     `R1`–`R24`. Fourteen is the raw report's revision-1 count.
   - Repair: change the count to "twenty-four" (`R1`–`R24`), or label the
     sentence as revision-1 history.
4. **Body count in the evidence section.** Line 877 says "The four bodies, captured
   verbatim by this run:".
   - Evidence: the block that follows shows **two** revision-1 bodies, followed by
     six revision-2 bodies.
   - Repair: delete the line, or make it match the blocks it introduces.
5. **Override-number control.** Lines 808–810 describe Group C as having "OV-01
   through OV-04 asserted **claimed** as the non-vacuous control for OV-05 and
   OV-06 being free".
   - Evidence: `rest-r2.sh:255-264` and `rest-r2.log:98-103` assert only that OV-06
     is free. The script contains no OV-05 assertion. OV-05 is now claimed by R80
     (`research/runs/R80/…/review/DECISION.md:20,58`).
   - Repair: drop "OV-05 and", so the prose describes what the script asserts.

### Finding 3 — JF-2: the LOW prompt question has no answer

**Failed claim.** None; the answer is absent. The prompt's LOW question asks: "Do
any published Rust web-service templates or style guides document this 'one
envelope for every non-2xx response' pattern by name, and where?"

**Evidence.** A search of the decision for templates, style guides, "by name" and
the LOW question found no answer. J1 cites adopting projects (`divviup/janus`,
`oxidecomputer/dropshot`), which are practice evidence, not templates or style
guides. `raw/opus.md` also does not answer the question. `raw/muse.md` answers it
as a stated negative result: "No published Rust template found that names a 'one
envelope for every non-2xx response' policy verbatim".

**Repair.** Add one sentence answering the question. For example: no published
Rust template was found naming the pattern (Muse, negative result, 2026-09-25).
The org REST API Design Standard v2.0.0 R5.12 (`:1019`) is a style guide that
requires it, and it binds this template under W2-REST.

## Passing checks, with evidence

- **JF-4 (claims trace to sources).** The following spot-checks all passed:
  - R67 `DECISION.md:135` is the quoted derive-rename sentence.
  - R67 `:148-153` is the `ALL` coverage-test compensation.
  - R67 `:653-662` is Disagreement 7.
  - R67 `:683-689` is the misfiled-review-label passage.
  - R69 revision 10 `:1396-1399` is the `code` question handed to R70.
  - R69 `:214` is the `axum-extra` hand-off. This confirms correction C2.
  - R69 `:1615` is "Not created by this item: `problems.rs` (R70)".
  - Claimed hashes match on recomputation: revision 1 (`git show f010b8e8`)
    = `ad568a68…`; `R70-r2-snapshot.md` = `fe895588…`; R69 revision 10 =
    `d34ab6e8…`; R67 = `16947ab1…`.
  - The rulings W2-REST, Q7.B and W1-CODEX3 exist in
    `docs/planning/p02/owner-decisions.md`. W2-REST and Q7.B also exist in
    `docs/port/OWNER-REVIEW.md`.
- **JF-5 (couplings).** Each coupling hands over ownership without deciding the
  other item's choice:
  - The environment-variable name and its loading go to R77.
  - Guard placement goes to R75.
  - CORS exposure goes to R76.
  - The catalog's publication surface goes to R81.
  - The fifth extension member is R80's to justify.
  - The 429 catalog gap is R74's to raise.
  - C4 validation ownership is explicitly left to the owner.
  - No `CONFLICT:` is raised, and the decision explains why (`RSLB201` plus the
    framework's own status).
- **JF-6 (assumes lines).** Each of the five `- assumes` values was split out and
  compared as an exact string to the value cell of the live
  `docs/port/PARAMETERS.md` row. All five match exactly. The uncommitted
  working-tree change to `PARAMETERS.md` touches only the `ci-job-structure` row.
- **JF-7 (prerequisite values).**
  - R67: the published hash equals `prerequisites.json` (`16947ab1…`), and the
    decision follows R67's values, including the envelope, `ALL`, the layering
    rule and `hint` semantics.
  - R69 caveat: the file paths follow R69 revision 10 (`d34ab6e8…`), which is
    owner-accepted per `OWNER-ACCEPTANCES.md:60` but unpublished. The published
    R69 revision 9 (`d4507f5b…`, pinned in `prerequisites.json`) still carries
    `web = ["dep:axum", "dep:tokio"]`. The decision states this difference at
    lines 725–739, argues that it is not a conflict, and records it as a
    re-verify trigger. That treatment is acceptable.
- **JF-8 (evidence).** All five scripts and all seven logs exist. The summary lines
  match the claimed counts: `registry` 65, `probe` 33, `archive-check` 11,
  `rest-r2` 79, `probe-r2` 25, all with FAIL 0 and SKIP 0. The archive reruns show
  65 and 33. The only mismatch with a script is the OV-05 prose, which is item 5
  of finding 2.
- **JF-9 (shape).** The file has the H2 sections `## Decision` (with
  `### Principles and implementation` and a bindable `re-verify:` line),
  `## Parameters`, `## Empirical check` and `## Engines`. `## Supersedes` is
  correctly absent because the item is unpublished. There is no `owns` line,
  because the prompt's `- owns:` is empty.
- **JF-10 (recommendation follows from evidence).** The recommendation follows from
  the evidence:
  - The single-envelope decision follows from the RFC 9457 status, py
    precedent, and the W2-REST standard (R5.12/R5.13).
  - The crate choice follows from the gate results (gate 2 excludes
    `http-api-problem` and `http-problem`), the measured one-crate tree addition,
    and the containment escape hatch.
  - The table mechanism follows from the cross-crate `#[non_exhaustive]` proof.
  - The `code`/`catalog_code` split is forced by R5.13.1's grammar.
  - The Muse disagreements (finding 1) do not overturn any of these conclusions.
