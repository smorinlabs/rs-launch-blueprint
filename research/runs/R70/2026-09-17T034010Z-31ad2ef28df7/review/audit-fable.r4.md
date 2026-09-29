# R70 http-problem-envelope — judgment audit of revision 4

actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 7a9345c67b42d504501e2039214fd42d9d31b69d61402c958c62c5bf7448a410
verdict: reject
unresolved-findings:
- F-1 (JF-1, JF-4): three sentences still attribute revision-2 proof to revision-1 criteria (`AC3`, `AC5`, `AC16`)
- F-2 (JF-3): `## Engines` credits the Opus report with rejecting a runtime type map, which it never does

## Scope and method

This audit judges the decision's reasoning and fidelity, not its execution. It
reviews `review/DECISION.md` at sha256 `7a9345c6…a410`, recomputed with
`shasum -a 256` before any other step; the hash equals the expected value.

Read in full: the decision (1,270 lines); `inputs/prompt.md` (sha256
`b47f8a26…`); `research/RUNBOOK.md` §§3 and 5; the relevant ranges of both
pinned engine reports (`raw/muse.md` sha256 `98972567…`, `raw/opus.md` sha256
`82538638…`, both recomputed). Also read: `inputs/prerequisites.json`;
`manifest.json`; `docs/port/PARAMETERS.md`; `docs/port/COMMONALITY.md:309-310`;
R67's published `DECISION.md` (sha256 `16947ab1…`, equal to the pinned
prerequisite); R69 revision 9 (published, `d4507f5b…`, equal to the pinned
prerequisite) and revision 10 (`d34ab6e8…`); R02 revision 2 (`9e8f8e8c…`); R03
revision 1 (`610e3338…`); `execution-ledger.md` and `owner-decisions.md` at the
cited lines; and the evidence scripts and logs under `review/evidence/`.

No audit file of any seat or revision was read, and neither was any
`R70-r*-snapshot.md`. No script was rerun, no git write was made, and no runner
command or paid API was used.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** → F-1 | Most count repairs hold: 13 carried + 11 new = 24 (`probe-r2.sh:895-1262` defines `R1`–`R24`); the "nine items" under "What these checks do not prove" count to nine (`:1038-1063`); two revision-1 bodies plus six revision-2 bodies (`:984-1009`). Three criterion labels remain stale; see F-1 |
| JF-2 every question answered, every constraint honored | **pass** | See "JF-2 in detail" below |
| JF-3 `## Engines` faithful and adjudicated | **fail** → F-2 | All 25 Muse line citations were checked and match (`:3, 13, 19, 25, 27, 29, 37, 41, 57, 61, 65, 73, 77, 81, 89, 124, 128, 136, 148, 160, 187, 188, 199, 209, 218`). The claim "It does not survey `problem_details` at all" holds, because `grep -c problem_details raw/muse.md` returns 0. Disagreements 1–3 are each adjudicated with evidence. One two-engine claim overstates Opus; see F-2 |
| JF-4 load-bearing claims trace to sources | **fail** (F-1 only) | Spot-checked and holding: `probe.log:46-48` (the `_` arm is unreachable within one crate and silent across a crate boundary); `registry.log:24` (0 versions of `http-api-problem` declare `rust_version`); `probe-r2.sh:349`/`:359` (`ProblemSource` trait and impl); manifest `operations.muse` has `state: submitting`, `raw_sha256: null` and `actual_model: null`, while opus is `claude-opus-5`; `execution-ledger.md:1114` (Q5.A) and `:1157` (R70 sha `98972567`); R67 `:136`, `:148-153`, `:653-662`, `:683-689`; R69 rev 10 `:214`, `:1393-1399`, `:1615`, `:1791`, `:2400`; `owner-decisions.md:398` (W0-R69c); R02 rev 2 `:29`; R03 `:168`; `raw/opus.md:737-738` (C1 swap); `RUNBOOK.md:72-73` (Q9.B). F-1 is the one misattributed proof |
| JF-5 couplings hand over owned choices | **pass** | R77 owns the base-URI variable name and its loading; R75 owns guard placement, `request-id` and caching; R76 owns the CORS exposure list; R81 owns the catalog's publication surface; R80 owns any fifth member; R74 owns its missing catalog row; R71 owns the schema; and C4 validation is explicitly left to the owner. None is decided here. EF-2 scope ruling below |
| JF-6 `assumes` lines byte-identical to the live registry | **pass** | A script compared each of the five `- assumes` values against column 4 of `docs/port/PARAMETERS.md`, and all five are IDENTICAL, including the 4,057-character `error-taxonomy-exit-codes` value. The working tree's one uncommitted edit to `PARAMETERS.md` touches only `ci-job-structure`, which this item does not assume |
| JF-7 no conflict with accepted or published prerequisites | **pass** | R67's decision hash equals the `prerequisites.json` pin. The published R69 is revision 9, which also equals its pin. The decision builds on revision 10's paths, which the owner accepted as `W0-R69c` but which are unpublished. It states that gap openly (`:791-805`) and makes R69's republication a re-verify trigger for file paths only; that is a disclosed dependency, not a conflict |
| JF-8 evidence scripts exist and counts match | **pass** | `review/evidence/` holds 17 files. That is the 13 files `rerun-r4.sh` hashes, plus the two revision-4 scripts and their logs. Summary lines: registry 65/0/0, probe 33/0/0, archive-check 11/0/0, rest-r2 79/0/0, probe-r2 25/0/0, engines-r4 75/0/0 and rerun-r4 30/0/0; all seven match the table at `:853-861`. `rerun-r4.log:60-62` pins archive-check at 9/2, with the two FAIL lines being exactly the IANA drift and the diff it causes, as `:885-894` states |
| JF-9 decision shape follows the published contract | **pass** | The four H2 sections RUNBOOK §5 requires are present: `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`. `### Principles and implementation` sits under `## Decision`, the `re-verify:` line is at `:762`, the settled rows F305/F306 are named (`:150-152`, confirmed at `COMMONALITY.md:309-310`), and there is correctly no `## Supersedes` for an unpublished item |
| JF-10 the recommendation follows from the evidence | **pass** | Gate 2 excludes `http-api-problem`, on an executed registry check. The `#[non_exhaustive]` behaviour is executed in both directions. The tree diff shows one added crate. The crate's single-maintainer risk is named and contained, because only `problems.rs` names the crate. Muse's contrary crate pick is refuted on the gate's own wording (`prompt.md:62`) together with Muse's own admission at `raw/muse.md:73` |

### JF-2 in detail

- **HIGH Q1** (does a crate exist, or is the envelope hand-rolled?) is answered
  by the bold recommendation (`:131-148`) and by M1/M4. Both say
  `problem_details` supplies the document, and the funnel is template code at
  four axum extension points.
- **HIGH Q2** (the mapping mechanism) is answered at `:295-312`, which compares
  `match`, trait method and derive.
- **MEDIUM Q3** (the validation-rejection hook) is answered at `:323-331`. The
  hook is an extractor newtype with `type Rejection = WebError`, needing no
  `macros` feature.
- **MEDIUM Q4** (can the design be generic?) has no labelled answer, but the
  answer is present and defensible:
  - `ProblemSource` (`probe-r2.sh:349-366`, listed in the migration table at
    `:819`) is the generic seam. Any domain error that implements
    `error_code() -> ErrorCode` is wired without redesign.
  - Disagreement 3, point 1 (`:1162-1165`) records that the question's premise
    has dissolved. The prompt says R67 is "not yet decided", but
    `prerequisites.json` pins R67's published decision.
  - Keying `http_status` on `ErrorCode` therefore keys it on the consumed
    parameter's own contract. It does not depend on an enum shape this item
    invented.
- **LOW Q5** (named templates or style guides) is answered at `:655-665`.
- **Constraints.** The fitness gates are answered per candidate (`:676-696`).
  Gate 1 is stated `inapplicable` with the owner ruling Q7.B. The stable-only,
  edition, MSRV and OS-matrix constraints are honored. No prior-art citation
  from the owner's other Rust repositories was found.

**EF-2's cycle fix is in scope.** Revision 4 moves
`impl ProblemSource for <domain error>` from `crates/core/src/error.rs` to
`crates/web/src/problems.rs`. That is in scope for four reasons:

- It moves an `impl` between files this item itself creates or edits.
- It follows R02's accepted topology, where `crates/web` "Depends on `core`
  only" (R02 revision 2 `:29`, confirmed). It cites that topology as the reason
  and decides nothing for R02.
- It matches what `probe-r2.sh:359` already compiled.
- It satisfies the orphan rule: the trait is local to `crates/web` and the type
  is foreign, which is legal.

The fix also removes an internal contradiction with the decision's own R02
coupling (`:508-510`). It moves no recommendation.

## Findings

### F-1 — revision-1 criterion labels still carry revision-2 proof (JF-1, JF-4)

Revision 2 replaced `AC1`–`AC16` with `R1`–`R24`, as the decision states at
`:1226-1227`: "which revision 2 replaced with `R1`–`R24`". The revision-4 note
claims to have closed JF-1(4)/EF-2, which was a lead-in that attributed bodies
to the wrong revision. Three sentences of the same kind survive.

1. **`:1011-1014`.** The claim reads: "The `/upstream` handler's domain message
   is `GET https://api.example.com/x?token=s3cret failed: 500`; AC5 asserts
   that neither `s3cret` nor `api.example.com` occurs anywhere in the response
   body, and neither does."
   - **Evidence.** The sentence sits directly under the block headed "Revision
     2's bodies, captured verbatim by `probe-r2.sh`" (`:991`), and it describes
     that block's `/upstream` body.
   - `AC5` is revision 1's test (`probe.sh:806-816`). It ran against the
     envelope that the decision itself says R5.13 has since forbidden (`:900`).
   - The proof for the body shown is `R8` (`probe-r2.sh:979-990`) plus the
     whole-file negative at `probe-r2.sh:1309`. This is the SEC-4/R8.12 proof
     that the decision calls load-bearing (`:82-87`).
   - **Repair.** Replace "AC5 asserts" with "`R8` asserts (`probe-r2.sh:979-990`),
     and a whole-file negative over every captured body confirms
     (`probe-r2.sh:1309`),". Optionally add "as revision 1's `AC5` did for its
     own envelope".
2. **`:1044`.** The claim reads: "**No route-walk over a real router.** AC16
   walks twelve hand-listed requests, not an enumeration of `build_router`'s
   routes."
   - **Evidence.** The current walk is `R24` (`probe-r2.sh:1225-1262`). It
     covers **fourteen** hand-listed requests and asserts
     `(failures, successes) == (12, 2)`.
   - The limitation itself still holds.
   - **Repair.** Change the sentence to "`R24` walks fourteen hand-listed
     requests (twelve failing, two succeeding), not an enumeration of
     `build_router`'s routes."
3. **`:449-450`.** The claim reads: "no code whose status is 5xx may be marked
   detail-public — executed here as AC3."
   - **Evidence.** The current executed form of this rule is `R3`
     (`probe-r2.sh:914`, "R3 — R5.17/R8.12: no 5xx code is detail-public").
   - `AC3` is the revision-1 test, `probe.sh:779`.
   - **Repair.** Change "executed here as AC3" to "executed here as `R3`",
     optionally adding "(revision 1's `AC3`)".

No evidence, count, verdict or recommendation moves. The repair touches prose
only.

The gate rows' "sixteen tests" (`:679`, `:681`) are **not** part of this
finding. They are revision-1 gate evidence that the decision explicitly labels
as carried from revision 1 (`:1231-1233`).

### F-2 — a two-engine agreement overstates the Opus report (JF-3)

- **Claim (`:1104-1106`).** "Both keep the status table hand-written and reject
  a derive and a runtime type map (`:136`)."
- **Evidence.** Only `raw/muse.md:136` rejects a runtime
  `HashMap<TypeId, StatusCode>`.
  - The Opus report's landscape for the table lists four mechanisms: an inline
    `match`, a trait method, a derive, and a free function
    (`raw/opus.md:864-872`).
  - It rejects the derive (`:288-289`, `:868-872`).
  - A runtime type map appears nowhere in it; a search for `TypeId`,
    `HashMap` and "type map" finds none in that sense.
  - The sentence also supports a two-engine claim with a citation to one
    report.
- **Repair.** Rewrite the sentence as "Both keep the status table hand-written
  and reject a derive (`raw/muse.md:136`; `raw/opus.md:288-289`, `:868-872`);
  Muse alone also rejects a runtime `HashMap<TypeId, StatusCode>` (`:136`),
  an option the Opus report does not consider."

Neither finding bears on the recommendation. Both are fidelity defects in prose,
and each needs a single sentence rewritten.
