decision-sha256: 44bf9ae9f55060ed56256dbad4d9a0814b3bd63112602dabe932acb7bfb12d82
actor: audit-fable-2026-09-05T155123Z-52a17c034dad-r3
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

This is a round-3 audit of a **published** decision. Revision 2 (sha256
`8025fd5b1a959b1e76fa9a738176071b418fd411aa2ba6ad5c6e4bffbd9a018f`) is live at
`research/topics/01-ports-and-adapters-seam/DECISION.md`, the owner accepted it on 2026-09-10, 38
items consume it transitively and R69 (`web-framework-stack`) consumes its owned parameter directly
in a run that is open right now. Revision 3 claims to be "a reasoning repair and nothing else" after
the owner's licence ruling of 2026-09-12 (Q7.B). The whole of this audit's weight therefore falls on
two questions: is the repair *correct*, and is it *nothing else*. Both were answered by diffing the
bytes myself rather than by reading the revision's account of itself. The prior `review/audit-fable.md`
bound revision 2 and is archived at `review/audit-fable.r2.md` (sha256
`55739951a35f3d04c2748071ccd299a972baa8d7a75a6710ccb08916855286ee`); this file replaces it.

## Principle and agreement level

The shared requirement (`## Decision`, *Principles and implementation*) is stated as an outcome, not
a mechanism: the use case depends on a named driven-I/O contract, is exercisable against a
substitutable implementation, that substitute is a shipped first-class artifact rather than a
per-test improvisation, one contract is asserted against every implementation, and both front ends
call one transport-neutral application contract emitting one shared data contract. The agreement
level is set per sub-row from `docs/port/DIVERGENCE-ANALYSIS.md` and not from engine consensus:
F001, F002 and F011 carry `harmonize: no` and are decided by Rust alone at the mechanism level;
F013, F018 and F121 carry `harmonize: yes` and are held at the capability level — a shipped double,
one suite against every implementation, one data contract for both front ends. What may vary is
named concretely in all three ecosystems (py's structural `Protocol` checked by `ty` at
`pyproject.toml:253`, ts's injected `CliDeps` record at `src/router.ts:31`, Rust's nominal trait),
and the decision declines to recommend a shared low-level value because neither an owner requirement
nor a same-tradeoff-in-all-three observation supports one. That is the correct refusal.

**This entire section is byte-identical to revision 2.** My diff of the two `## Decision` sections
(below) shows no change anywhere in it. I approved this framing at revision 2 on the merits and
re-read it here rather than deferring to that approval; nothing in the licence ruling touches an
agreement-level judgment, and nothing in it moved.

The native justification is likewise untouched and does not lean on py/ts agreement. Design E
(generic service, blanket `impl ProjectsPort for Arc<T>`, erased at the composition root) is carried
by Rust-native authority — the Reference's dyn-compatibility rules, the API Guidelines' C-OBJECT
"declare the trait dyn compatible once, that is the load-bearing decision", the Book ch. 10/18
monomorphization-versus-vtable material — plus three projects read at source and this run's own
compile-level check 1. The "is the shared pattern still appropriate in Rust?" paragraph argues the
pattern is *cheaper* in Rust than in either source because `rustc` proves satisfaction nominally
with the `impl` item and no tool in the loop, which is an argument from the language and not from
the two repositories agreeing. `BASELINE-REVIEW: F011` is carried in the required form, restates the
row's mechanism as compiler-enforced nominal satisfaction, names R30 as the affected item with the
instruction not to scope adapter-port conformance into a checker gate, and cites the observed E0046
and E0038. `CONFLICT:` handling is unchanged and remains correct: codex's R05 line is reproduced
verbatim and adjudicated as not a registry conflict under `research/RUNBOOK.md` §4, because R05
registers no parameter and the line names no registered value.

## Design and evidence

**Press point 1 — the three crates' surviving grounds.** Revision 3's central factual claim is that
each of `nject`, `faux` and `test-case` falls on a ground *already stated in the decision's own
outcome text*, so that removing the licence clause removes a redundant reason rather than the only
one. A ground first appearing in revision 3, or lifted from a provider-report column, would be new
reasoning and would break the "repair only" claim. I checked each against the `## Supersedes` copy
of revision 2 — which I separately established is byte-identical to the published file — and each
ground is present there, in a region my section diff shows was not touched:

| Crate | Surviving ground in revision 3 | Where it stands in revision 2 | Verdict |
|---|---|---|---|
| `test-case` | `at-risk`, "no push through two years of releases"; and varies *values* where F121 varies a *type* | Maintenance column of the crate table, verbatim, against that table's own 3.3.1 (2023-11-17) and last push 2024-05-12; the *Suite mechanism* paragraph ("`rstest`/`test-case` vary *values*… `jj` uses `test-case` only because its backend selector is a value") | Present in rev 2 |
| `faux` | `at-risk`, "liberal use of unsafe" per its docs; and mocks a concrete struct instead of implementing the port trait | Maintenance column, verbatim; the *Not selected* line names it as "struct mocking without a trait (`faux` 0.1.13)", and its Role column reads "struct mocking" | Present in rev 2 |
| `nject` | a DI container, the category alternative F rejects outright; 0 reverse dependencies | Alternative F names `nject` explicitly and gives the substantive reason (five ports and one root is not the problem containers solve; a wiring error becomes a resolution-time failure where Rust has a compile error; adoption negligible); the table's Maintenance column records "0 reverse deps" | Present in rev 2 |

No ground is newly asserted and none is a provider-report column. Two independent corroborations:
the programme's own licence review at `docs/planning/p02/execution-ledger.md:514-515` names the same
three grounds in the same terms ("one is at-risk with no push across two years of releases, one is
at-risk and makes liberal use of unsafe code, and one is a dependency-injection container the chosen
architecture rejects outright with zero reverse dependencies"), and the round-3 empirical audit
reached the same conclusion by rerunning the repair script. Note that alternative F's phrasing
"Rejected by all five engines" is agreement language, but the reason it carries is substantive and
Rust-specific, so `nject`'s exclusion does not rest on agreement alone.

**Press point 2 — does anything re-enter the comparison?** No. Revision 2's *Excluded by gate*
named exactly three crates with a licence clause and said in its own words that "each is also
excluded on fit or maintenance", and I verified that claim crate by crate above rather than taking
it. The three are also the complete set of MIT-only candidates in the crate table (`test-case` MIT,
`faux` MIT, `nject` MIT; `shaku` is "MIT/Apache-2.0", every other row is `MIT OR Apache-2.0`), so no
fourth candidate can have been excluded on a licence. I swept all eleven `licen`-bearing lines in
the revision-2 copy: five are the exclusion and gate lines revision 3 edits, two are Parameters
prose, one is the table header, and three are check-3's claim row, heading and finding. None is an
exclusion of any further candidate. Striking a gate can only remove an exclusion ground or an
admission ground; the two admission uses (`serde` "licence identical to the template's" and
`crates.io`'s own dual licence offered as compatibility evidence) were both *removed* by revision 3,
and `serde`'s admission survives on MSRV 1.56, feature posture, CI coverage plus this run's macOS
compile, and measured build cost. `teloc` keeps a gate-2/gate-6 exclusion that never involved a
licence. The comparison is therefore closed under the ruling, and "nothing else" survives this test.

**Press point 3 — the byte-identity claims.** I extracted the revision-3 and revision-2 `## Decision`
and `## Parameters` sections and diffed them. The complete set of differences is five hunks in
`## Decision` (the fitness-gate paragraph, the table's `Licence` → `Licence (recorded, not
evaluated)` header cell, the *Excluded by gate* paragraph, clause (2) of *Compatibility*, and one
sentence of *Validation strategy*) and two in `## Parameters` (the paragraph after the parameter
block and the consumed-parameters paragraph). Everything the revision claims is byte-identical, is:
the recommendation table and all six ledger-row settlements, the *Not selected* line, the
alternatives table A–F including the ranking of D as first runner-up, the six acceptance criteria,
the `BASELINE-REVIEW` line, the reference implementations, **every crate row and every version in
the figures table** (`serde` 1.0.229, `serde_json` 1.0.151, `async-trait` 0.1.92, `mockall` 0.15.0
and the rest — the header cell changed, no cell under it did), the migration file list, confidence
and the re-verify trigger. In `## Parameters`, the `- owns` line and all four `- assumes` lines
differ by no character. The owned value is additionally byte-identical to its registry row at
`docs/port/PARAMETERS.md:11` (both 764 bytes, diff clean), and the four assumed values match
`PARAMETERS.md` lines 7–10 verbatim. Nothing R69 consumes moved.

**Press point 4 — the `## Supersedes` copy.** I extracted lines 287–554 of the decision to a file
and hashed it: `8025fd5b1a959b1e76fa9a738176071b418fd411aa2ba6ad5c6e4bffbd9a018f`, exactly the
published revision-2 digest, and `diff` against
`research/topics/01-ports-and-adapters-seam/DECISION.md` is empty including the trailing byte. That
is the strongest available form of the verbatim requirement — not "the text looks the same" but "the
embedded tail is the published file". The prefatory note above the copy correctly states the digest,
the supersession date and the ruling that caused it.

**"Nothing else" across the remaining two sections.** The byte-identity claims cover `## Decision`
and `## Parameters`, but "a reasoning repair and nothing else" covers the whole entry, so I diffed
`## Empirical check` and `## Engines` too. `## Empirical check` differs in exactly six places, all
disclosed: the intro sentence, the working-directories sentence, check 3's claim row, check 3's
heading, check 3's finding, and the new check-5 row and paragraph — plus one consequential heading
rename, *What these four checks do not establish* → *What checks 1 to 4 do not establish*. Checks 1,
2 and 4 and every quoted log line are untouched. `## Engines` differs only by the three new
revision-3 paragraphs; the five engine entries, the revision-1 rejection history, **the entire
unproven table**, all eight disagreement items and the uncertainty paragraph are byte-identical. No
undisclosed change exists anywhere in the entry.

**Evidence and what it is claimed for.** The four original checks establish compile-level and
resolution-level facts only and are cited for nothing more: check 1 takes exactly one fact from a
whole-package compile ("`pub trait ProjectsPort: Send + Sync`, as declared, erased to
`Arc<dyn ProjectsPort>` without E0038"), check 2 supplies the two error codes the F011 answer rests
on, check 3 the pin resolution and the 1.71 subtree maximum, check 4 the `cargo audit` clearance the
raws could not fetch. Revision 3 re-ran none and withdrew none, which is right — the ruling voids a
gate, not a measurement. Check 5 is a genuine assertion rather than a description: twelve assertions
over the committed decision, anchored on the run's own Supersedes tail rather than on the topic path
(so it will not rot at publication), with a negative control that fails if the phrase list goes
stale, and a documented history of a keyword scan silently passing a reverted repair on this
document's long lines. The round-3 empirical auditor reran it from `/tmp` to a byte-identical log,
reran a simulated post-publication tree, and confirmed check 7 fails when a repair is reverted. The
check-3 handling is the part I weighed hardest: revision 2 asserted an acceptance criterion there
("every licence in it is permissive… none is copyleft"). Revision 3 does not delete it; it records
it as `inapplicable` in place and states the consequence for the downstream phase — "P03 inherits
from this check the resolution and MSRV clauses and does not inherit a licence clause". Withdrawing
a criterion silently would change what P03 must prove without saying so; recording it is correct.

**Unproven claims.** The six-row unproven table is unchanged and still carries the right things:
the production composition root, one erased service reaching both front ends, the live web request
path (blocked on R69), the two-leg CI matrix at the MSRV floor, the `async-trait` route, and the
vtable cost. Each is paired with the test that would settle it. Nothing in this run is asserted as
proven that the evidence did not show; the confidence paragraph explicitly scopes its "high" to the
parts as researched and not to their assembly. Revision 3 adds no claim to this table and removes
none. This is the correct posture for a research programme in which P03 builds the template.

## Completeness

Every required field is present and correctly placed: status, the recommendation with mechanism and
version per member, principles and agreement level, architecture alternatives compared before any
crate was weighed, members with landscape bins and figures, compatibility, migration implications,
validation strategy, confidence, sources with retrieval dates, the re-verify trigger, `## Parameters`
with one `- owns` and four `- assumes` and an empty `- consumes`, `## Empirical check`, `## Engines`,
and — required only because this edits a published decision — `## Supersedes`.

Fitness gates are complete and correctly dispositioned. Gate 1 is recorded as
`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any
dependency or tool`, naming the ruling, and is **recorded rather than deleted** — the right call,
since the binding prompt's sha256 is cited by the published acceptance record and cannot be edited,
and the prompt instructs that a gate be marked inapplicable rather than dropped silently. Per the
settled owner ruling this is correct and is not a finding. The paragraph also draws the two
boundaries the ruling leaves standing: the repository's own `license = MIT OR Apache-2.0` parameter,
and each crate's declared licence as a recorded fact. Gates 2–6 are `inapplicable` for the five
language-feature members with the reason given, and are evaluated for every crate member and
measured alternative. Source dates are present throughout (2026-09-05 for the practice and figure
evidence, 2026-09-09 for the openai authorities, 2026-09-12 for the ruling).

I verified the ruling citations at first hand. `docs/planning/p02/execution-ledger.md:495` carries
the wider ruling that the fixed licence "applies ONLY to the source code in this repository
directly"; `:505` is Q7.B striking gate 1 "including crates compiled into the shipped artifact",
recorded with the note that the owner was shown that linked crates' terms travel downstream and
chose the wider rule knowingly — which is exactly what the decision's opening paragraph attributes
to it. `:514-515` records R01 as AFFECTED with its recommendation not moving. All four `- assumes`
values match `docs/port/PARAMETERS.md` verbatim.

Two observations, neither a finding, both recorded so a later reader is not puzzled:

1. *What changed* opens "Ten locations in the current entry carried the struck reasoning, and all
   ten were edited". Nine of the ten carried voided reasoning; the tenth, the `## Parameters` prose,
   is a *boundary addition* saying what the fixed `license` value no longer constrains. The
   round-3 empirical audit states the decomposition more precisely as nine plus one. "Carried" is
   defensible — revision 2's sentence there did name `license = "MIT OR Apache-2.0"` as a value the
   check ran against — and the edit set itself is complete and correct, so this is imprecision in a
   bookkeeping sentence, not in reasoning.
2. The ledger's licence review anticipated "a reasoning edit at four named lines"; revision 3 edited
   ten. The divergence is toward completeness, not scope creep: the four extra reasoning locations
   (table header, `serde`'s gate claim, *Compatibility* clause 2, *Validation strategy*) and the two
   further check-3 locations all carried struck reasoning that a four-line repair would have left
   behind. A separate registry note — `PARAMETERS.md:10` still reads "candidate crates must be
   compatible (§7.6)" — is now stale against Q7.B, but it is the registry's row and not R01's to
   edit, and this decision asserts nothing that depends on it.

The revision also declines to repair the two non-blocking notes my revision-2 audit raised (that the
three reference projects cited for design E are all D-shaped by this decision's own citations, and
an awkward adjacency in *Excluded by gate*), stating that repairing them here would mix a reasoning
correction into a licence repair. Both were non-blocking then and remain so; holding them out of a
scoped repair to a published keystone is the right discipline, and they stay open.

The audit-codex rerun (`review/audit-codex.md`, actor
`audit-codex-2026-09-05T155123Z-52a17c034dad-r3`, gpt-5.6-terra) binds the same decision sha256,
approves with no findings, and is consistent with this decision: it independently reproduced checks
1–4, reran the repair script from a different directory and against a simulated published tree, and
confirmed by reversion that a reverted repair now fails. Its one deviation — `cargo audit` needing
an isolated advisory database in its sandbox — is an environment constraint, not a discrepancy in
the result.

## Findings

None.

## Assessment

Approve. **The recommendation still follows.** It follows at the right agreement level — capability
for F013, F018 and F121, mechanism for F001, F002 and F011, each taken from the divergence analysis
rather than from the two source repositories agreeing — and the seam design is justified natively,
by the Rust Reference's dyn-compatibility rules, the API Guidelines' C-OBJECT, and three current
projects read at source, with the "cheaper in Rust than in either source" argument resting on
`rustc` proving satisfaction nominally rather than on py/ts precedent. Design E's selection never
touched a licence at any point, so the struck gate cannot reach it.

The revision is what it says it is. I verified the three claims that could have falsified that,
each against the bytes: every surviving exclusion ground for `nject`, `faux` and `test-case` stands
in revision 2's own outcome text and none is new or borrowed from a provider report; no candidate
was excluded on a licence alone, so nothing re-enters the comparison; and the recommendation, every
crate and version, the owned parameter and all four assumed parameters differ by no character, with
the owned value also matching its registry row byte-for-byte. The `## Supersedes` copy is not merely
faithful but hashes to the published revision-2 digest. Extending the diff to `## Empirical check`
and `## Engines` — the two sections the byte-identity claim does not cover — turned up no
undisclosed change either.

Nothing R69 consumed reads differently under revision 3. R69's prompt consumes
`R01: http-transport-injection-seam`, whose value is unmoved, and the *Inputs to other items*
paragraph handing R69 the web state type `ProjectsService<Arc<dyn ProjectsPort>>`
(`Clone + Send + Sync + 'static`) and the instruction that handlers return the library's `serde`
types is inside the byte-identical region. R69 has no published decision yet, so there is nothing
downstream to re-read. R30's `BASELINE-REVIEW: F011` input and R48's "no HTTP-mocking crate needed"
input are likewise unchanged.

What the decision claims is bounded by what this run showed. The four original checks are
compile-level and resolution-level facts and are cited for nothing wider; check 5 asserts the
repair rather than describing it, with a negative control against a stale phrase list; the six-row
unproven table still carries the end-to-end assembly, the CI matrix, the async route and the
dispatch cost as P03's to prove, each with the test that would prove it. A published keystone that
38 items consume was corrected without moving a byte any of them depend on, and the correction can
be re-verified mechanically by anyone who reruns the script. Approve.
