decision-sha256: 0309754689dc338010858e46a59f7b6f52ed8859464b9ac1dfc564d5a537ed5f
actor: audit-fable-2026-09-17T020714Z-f9e4f950ea82-r1
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: JF-1 (blocking): `wiremock` 0.6.5 is kept on the qualified shortlist at rank three with gate 2 recorded as "passes on substance, fails on declaration" and engine item 3 settling that it "fails no applicable gate", while `double`, `stubr` and `rvcr` are excluded on gate 2 in the same paragraph for the identical absent `rust-version` and `mry` is not — the programme withdrew the permissive reading at `docs/planning/p02/execution-ledger.md:414` ("insufficient evidence to PASS a gate the prompt says must be passed") and applied the strict one at `:640`, so codex's `raw/codex.md:115` exclusion was right, `wiremock` belongs under *Excluded by gate*, and the C12 reversal condition's "commits on `LukeMathWalker/wiremock-rs` after 2025-08-24" branch cannot clear gate 2; JF-2 (blocking): `mockall` 0.15.0's gate 4 is recorded as "**passes** by adopter evidence" from an adopter carrying 0.13.0 with macOS support for 0.15.0 conceded as "**inferred, not observed**", the same claim appears in the unproven table as "**Unproven**", `mockito` in the same evidentiary position is labelled "unverified for macOS test execution, not failed", and codex's contrary position at `raw/codex.md:61` is absent from the six numbered engine items — this is the one finding under which the recommendation moves, because an uncleared gate 4 removes member 2 from the stack; JF-3 (blocking): all thirteen URLs in the decision sit in the C01–C20 endpoint column, so every figure outside the check table is uncited, including the three adopter claims that are the entire basis for three gate-4 dispositions (`tokio-rs/tokio`, `matrix-org/matrix-rust-sdk`, `apache/iceberg-rust`) and `httptest`'s "35 stars and 55 reverse dependencies", which carries no retrieval date either, against the prompt's "Every claim carries a source URL and retrieval date; every number carries its endpoint"; JF-4 (blocking): `mockall`'s gate-2 cell says "its six required dependencies are pure Rust and older-MSRV (C08)" where C08 asserts only the dependency-name set and "no tokio, no hyper", and the dependency-tree half of gate 2 is established for no candidate and recorded as unproven for none; JF-5 (non-blocking): the BASELINE-REVIEW quotes R01's F121 row as "called from `tests/` once per adapter" and omits its next clause, "no parametrization or mocking crate", which a reader meets as a contradiction of member 3; JF-6 (non-blocking): member 1 is a pattern with no crate and receives no gate or figure statement, where the prompt requires `inapplicable` with its reason rather than silent omission; JF-7 (non-blocking): the claim that the script "passes `shellcheck` with no findings" appears in neither committed log and the script invokes no `shellcheck`; JF-8 (non-blocking): "No download counter, star count, open-issue count or active repository's `pushed_at` literal is printed anywhere" is true of the log and false of the decision body, which prints `httptest`'s star count and `mockall`'s and `httpmock`'s `pushed_at` dates

## Principle and agreement level

The decision states the shared requirement at the right level and cites it correctly.
F119 is stated as a **capability** — "A test can replace a collaborator with a
programmable stand-in and can afterwards assert *what the code under test asked of it*"
— sourced to `docs/port/areas/testing-coverage.md:9` and
`docs/port/DIVERGENCE-ANALYSIS.md:177`. I read both lines. Line 177 is the R48/F119
sub-row, cause class **B**, `harmonize: no`, and its cause column reads verbatim
"D-019(5): same DI-and-spy pattern, only the framework-native tool differs" — the exact
phrase the decision quotes as its ground for holding agreement at capability and letting
the mechanism vary. F120 is stated as a capability too — hermetic upstream control,
explicitly not mechanism — sourced to `testing-coverage.md:10` and
`DIVERGENCE-ANALYSIS.md:178`, which is cause class **F**, `harmonize: no`, and whose
cause column names "hermetic-boundary intent". The ledger rows the decision claims to
settle are the rows it owns: `docs/port/COMMONALITY.md:125` is F119 and `:126` is F120,
both `DIVERGENT`, both assigned to R48. F121 sits at `:127` and is R01's; the decision
cites it as evidence and mints no finding against it, which is correct.

The three justified mechanism differences (nominal `impl` instead of `unittest.mock`
over a `Protocol`; a hand-written spy because libtest ships none; a real loopback socket
instead of py's in-process transport patch) are each argued from a property of the
target ecosystem rather than from repository agreement. The third carries its structural
consequence explicitly — the HTTP adapter's base URL becomes a constructor parameter —
and names it as "the single structural change this item forces on R01's design". That is
the right disclosure at the right place.

**The BASELINE-REVIEW F120 disposition is a legitimate narrowing, not a covert change.**
R01's sentence exists where the decision says it is: `research/topics/01-ports-and-adapters-seam/DECISION.md:76`
reads "gives R48 the same conclusion this decision gives: **the recommended seam needs no
HTTP-mocking crate** because the transport sits behind an injected port", and `:154`
routes it to this item — "R48 receives 'the recommended seam needs no HTTP-mocking crate'
for F120". The narrowing adds "**at the port seam**" and leaves R01's owned parameter,
recommendation and crate selections untouched. I verified the parameter is untouched by
byte-comparison (see `## Completeness`) and verified R01 is the pinned revision: the
sha256 of `research/topics/01-ports-and-adapters-seam/DECISION.md` is
`44bf9ae9f55060ed56256dbad4d9a0814b3bd63112602dabe932acb7bfb12d82`, which equals
`inputs/prerequisites.json` `R01.decision`. The two supports the decision leans on are
both real: R01:17 commits the template to a contract function "called from `tests/` once
per adapter", and R01:261 asks for "A template integration test that starts the real
upstream (or a bound test listener)". `BASELINE-REVIEW:` rather than `CONFLICT:` is the
right vehicle — the prompt reserves `CONFLICT:` for a consumed parameter that must
change, and none must. The finding carries feature ID, principle, proposed change,
affected items and evidence, which is the form the prompt and the answer template
require. One omission in how it quotes R01 is recorded as JF-5, which is non-blocking
and does not make the narrowing covert.

## Design and evidence

**The architecture alternatives were genuinely compared, and before crates.** Five
shapes for F119 (hand-written fake, derive-macro crate, struct mocking, closure
injection, universal mock type) and five for F120 (loopback server, transport injection,
in-process interception, cassettes, no HTTP test). Each rejection turns on a property of
this template rather than on adoption: `faux` cannot produce a `ProjectsPort`
implementor; `responses`-style interception has no Rust equivalent because there is no
run-time patching of a linked crate; alternative B is recorded as a *complement* for the
one failure class a real socket cannot reach, which is the honest disposition rather
than a dismissal. The recommendation follows from this comparison: member 1 is the
default because the language supplies the substitute, member 2 is gated because it adds
terseness and no capability, member 3 exists because F121 needs an upstream to answer a
real adapter. That chain holds.

**Four of the six engine items are settled on grounds, and I checked each against the
raws.**

1. *Does the HTTP condition fire?* Codex `raw/codex.md:127` reads "Do not add an
   HTTP-mocking dependency for R01's registered trait/fake branch"; opus puts `httpmock`
   in the stack. Settled for opus on R01's own F121 row and its bound-test-listener line,
   both of which I read at the pinned revision. This is evidence, not a vote.
2. *Where `mockall` is declared.* Settled on a language and Cargo constraint, not a
   preference: integration tests under `tests/` link the library as an external crate, so
   a mock gated by `#[cfg(test)]` is invisible to them, and an optional dependency that
   `dep:mockall` can name cannot live in `[dev-dependencies]`. Both are true, and the
   decision states the narrow case in which codex's shape is sound. Correctly settled.
3. *How `wiremock` leaves the shortlist.* Settled for opus, with codex "recorded as
   overstated". **This is the one settlement decided on the wrong rule** — see JF-1.
4. *What a RustSec 404 means.* Codex recorded advisory status as unverified
   (`raw/codex.md:179`, "Every queried RustSec package URL returned HTTP 404, so advisory
   status is unverified"); the decision settles it by adding a control. C07 in the log
   reads "rustsec.org control lock_api = HTTP 200 (RUSTSEC-2020-0070 exists), candidates
   mockall=404 httpmock=404 wiremock=404 mockito=404 — the probe distinguishes". A
   control that discriminates in the same run is exactly what converts a 404 from a
   possibly-broken probe into a negative result. This settlement is sound, and it is the
   strongest piece of empirical work in the item.

Items 5 and 6 are corrections to opus, and both are real. `raw/opus.md:830-831` does
state `unsafe_code = "forbid"` and `edition = "2024"` read from master, and master is
0.9.0; C06 re-read the v0.8.3 tag and found "0 unsafe_code lines and edition = '2021'".
`raw/opus.md:842` does say 26 dependencies; C19 re-read all three in one pass and found
25. Both corrections are carried into the rows they affect rather than only noted.

**The unproven rows are honest and complete on the substance the decision claims.** The
decision says plainly, three times, that nothing was compiled, and the seven-row unproven
table names the falsifying test for each claim, including the one that would falsify the
recommendation (the F121 suite passing for both adapters from one seed set). It declines
to implement its own recommendation, which is correct for this role and is not a defect.
No performance figure is offered and the refusal is argued from the absence of the
workload. Nothing in the prose overstates the two logs I read, with one exception
recorded as JF-4: a gate-2 sentence cites C08 for a dependency-tree MSRV property that
C08 does not assert.

**The C12 reconciliation honours section 11 in form but not in ground.** Owner decision
11 makes the reference "an owner-supplied research input, not a binding standard and not
a pre-decision", and requires a differing item to state its ground. The decision differs,
states two grounds, re-verifies both at primary sources (C11 for async-only from the
maintainer's own README, C13 and C03 for maintenance and the absent `rust-version`), and
states a reversal condition. The reference row itself is where the decision says it is: I
read line 72 (the C12 Testing row naming wiremock), line 117 ("Mock outbound HTTP with
**wiremock**") and line 197 (`wiremock = "0.6"`). The process note about owner decision
11 assigning C12 to R32 while R48 owns F119 and F120 is accurate and correctly raised to
the controller rather than minted as a finding. What is wrong is that the decisive ground
is missing and the reversal condition is stated too weakly, both consequences of JF-1.

## Completeness

**H2 set and order.** `## Decision`, `## Parameters`, `## Empirical check`, `## Engines`
— exactly the four the synthesizer role requires, in order, with no others and no
`## Supersedes`. The required `### Principles and implementation` H3 is present, and the
final line of `## Decision` is `re-verify:` with a date and a list of earlier triggers.

**`## Parameters` grammar.** Five `- assumes` lines, no `- owns` line, matching the
prompt's empty `owns:`. I extracted each value and compared it byte-for-byte against
column 4 of the matching `docs/port/PARAMETERS.md` row with a string equality test, not
by eye: `msrv-policy`, `rust-edition`, `target-os-matrix`, `license` and
`http-transport-injection-seam` are all **identical**. No backticks, no citation, no
commentary on any value line; the prose about how each parameter bears on the decision
follows the list, which is where the role doc puts it. The absence of `CONFLICT:` lines
is correct — neither raw emitted one (`raw/codex.md:163`, `raw/opus.md:1132`).

**Fitness gates.** Gate 1 is stated `inapplicable — owner ruling 2026-09-12 (Q7.B)` for
every candidate, licences are recorded as facts only, and codex's licence sentence is
recorded as struck rather than as a pass. I read
`docs/port/OWNER-REVIEW.md:47` and confirm the ruling and its scope, and I raise no
licence finding. Gates 2 to 6 are answered per candidate for the four shortlisted crates
in one table and in prose for each excluded candidate. Two defects remain: the gate
dispositions are not applied by one consistent rule (JF-1, JF-2), and member 1 — a
pattern, not a crate — receives no gate or figure statement at all (JF-6).

**Empirical check.** Toolchain, host, working directory, the exact command and the
evidence log path are all present, and the section says explicitly that nothing was
compiled. I read both logs and did not rerun them. `r48-claims-check.log` carries
twenty `PASS` lines, C01 through C20, and `RESULT: all checks passed (0 FAIL)`, which
matches the decision's "20 checks, 20 PASS, 0 FAIL, 0 SKIP". The two logs are identical
line-for-line apart from the retrieval timestamp in the `# ` header, which is exactly
the reproducibility rule the decision states, and `r48-archive-rerun.log` records
`exit 0` from a clean `git archive HEAD` extraction. The C-table gives an endpoint for
every check. Two checks are declared as designed to fail later, which is a legitimate
tripwire and is tied to the recorded re-verify triggers.

**Where completeness fails.** Every figure the decision states that is *not* covered by
a check carries no endpoint (JF-3); one gate cell cites a check that does not establish
it and the dependency-tree half of gate 2 is addressed for no candidate (JF-4); and one
executed claim appears in neither log (JF-7).

## Findings

**JF-1 — blocking. `wiremock` is kept on the qualified shortlist under a gate-2 reading
the programme withdrew, and engine disagreement 3 is settled the wrong way in
consequence.**

Quoted, from the fitness-gate table: `wiremock` 0.6.5 column 2 reads "**passes on
substance, fails on declaration** — it declares **no** `rust-version` at all (C03), so
the MSRV-aware resolver offers no protection". Quoted, from engine item 3: "**Settled for
opus, and codex's framing is recorded as overstated.** `wiremock` fails no applicable
gate: gate 2 passes on substance". Quoted, from *Excluded by gate*: "`unimock` 0.6.8 and
`mry` 0.14.0 fail no applicable gate (`unimock` declares 1.70; `mry` declares none)".

The problem. The programme settled this reading against the decision.
`docs/planning/p02/execution-ledger.md:414` records the owner's withdrawal in terms:
"RULING WITHDRAWN: fitness gate 2 is read strictly … an unknown effective version is not
evidence of incompatibility, as I said, but it is insufficient evidence to PASS a gate
the prompt says must be passed. That distinction is the part I got wrong: I treated the
gate as a test the candidate could fail, when the prompt writes it as a bar the candidate
must clear." `execution-ledger.md:640` shows the strict reading applied to a crate in
exactly `wiremock`'s position — "watchexec-cli 2.7.2 still fails gate 2 (no declared
rust-version)" — and `docs/planning/p02/owner-decisions.md:456-458` records the same
outcome for the owner. Under that rule an absent `rust-version` does not clear gate 2,
and the prompt's own instruction is that "a failed gate lists the candidate under
*Excluded by gate*". Codex was therefore right at `raw/codex.md:115` ("its release
metadata declares no `rust_version`; this fails the evidence gate for macOS/MSRV") and
the decision records a correct reading as overstated. The decision also applies the
strict rule to three other candidates in the same paragraph — `double` and `stubr`
excluded on "gates 2 and 6" for "no declared `rust-version`", `rvcr` excluded "on **gate
2** (no declared `rust-version`)" — so the document reads the same gate two ways
internally, with `mry` on the permissive side and `rvcr` on the strict side.

What resolves it. Apply the strict reading uniformly: move `wiremock` 0.6.5 from the
qualified shortlist to *Excluded by gate* on gate 2 with C03 as its evidence, restate
engine item 3 as settled for codex on the gate and for opus only on the ranking prose
that survives, correct the `mry` clause, and rewrite the C12 reversal condition — as
written it allows `wiremock` to win on "commits on `LukeMathWalker/wiremock-rs` after
2025-08-24", which cannot clear gate 2; only the second branch, "a released 0.6.6+ that
declares `rust-version`", can. The fitness ground stated in the reconciliation should
name the gate failure first, since it is decisive where the two fit grounds are not.

**JF-2 — blocking. `mockall`'s gate 4 is recorded as a pass on evidence the same
document records as unproven, and on a rule the document applies more strictly to
`mockito`.**

Quoted, from the gate table, `mockall` 0.15.0 column 4: "**passes by adopter evidence.**
Its own CI is `ubuntu-latest` only; closed by `tokio-rs/tokio` … **Version caveat: that
adopter evidence is for 0.13.0, not 0.15.0** … macOS support for 0.15.0 specifically is
**inferred, not observed**". Quoted, from the same table, `mockito` column 4:
"**unverified for macOS test execution, not failed**". Quoted, from the unproven table:
"`mockall` 0.15.0 builds and tests on macOS | **Unproven.** Inferred from an adopter
carrying **0.13.0** on a macOS matrix".

The problem. Three things are wrong together. First, the document calls the same claim a
gate *pass* in one table and *unproven* in another. Second, `mockito` is in the same
evidentiary position — its own CI carries no macOS lane and only adopter evidence is
available — and receives the weaker label, while the decision then uses the gap between
the two labels as a discriminator elsewhere. Third, this is an unenumerated engine
divergence: `raw/codex.md:61` records that `mockall`'s "public CI shown on Ubuntu
stable/MSRV does not demonstrate the required macOS lane, so the template must prove its
own Ubuntu/macOS test matrix before acceptance", which contradicts the table's "passes"
and is not among the six numbered items, although `## Engines` is where the role doc
requires the disagreements and their settling evidence. Under JF-1's strict reading —
a gate is a bar to clear, and inferred evidence does not clear it — the cell as written
cannot stand.

What resolves it, and this is the one finding under which the recommendation moves.
Either close the gate with executed evidence in the way R01 closed the identical gap for
`serde` (it compiled the pin on this Darwin host; the synthesizer role permits "confirm a
version pin exists and installs", which is not building the recommendation), or find an
adopter running 0.15.0 on a macOS matrix; or relabel gate 4 for `mockall` exactly as
`mockito`'s is labelled, add codex's position to the numbered items, and state the
consequence — under the strict reading an uncleared gate 4 puts `mockall` under
*Excluded by gate* and member 2 leaves the stack. Members 1 and 3 are unaffected either
way, and the decision already states member 2's cost as terseness only ("dropping it
costs the template no capability"), so the consequence is bounded and already priced.

**JF-3 — blocking. Load-bearing figures carry no endpoint, and one carries no retrieval
date.**

Quoted: "`tokio-rs/tokio` carries `mockall` as a dev dependency and runs its test matrix
on `macos-latest`"; "`matrix-org/matrix-rust-sdk`, which runs its full suite against
`wiremock = "0.6.5"` on `macos-latest`"; "the best adopter evidence, `apache/iceberg-rust`,
runs macOS in its `build` matrices but its `tests` job on `ubuntu-latest` only";
"`httptest` 0.16.4 … not adopted, because 35 stars and 55 reverse dependencies make it an
unsuitable default"; "`double` 0.2.4 — excluded on **gates 2 and 6**: last release
2019-09-22"; "`stubr` 0.6.2 — excluded on **gates 2 and 6** (no declared `rust-version`,
last release 2023-06-29)"; "its master branch moves to 1.85"; "median 1.18 days to first
maintainer response over the ten most recently opened issues".

The problem. I extracted every URL in the decision: there are thirteen distinct ones and
all thirteen are in the C01–C20 endpoint column. Every figure outside that table is
therefore uncited. The prompt's Constraints require "Every claim carries a source URL and
retrieval date; every number carries its endpoint", its Required-evidence table pins each
figure class to a named endpoint and requires adopter evidence to carry a "name + source
link", and the synthesizer role says to "Cite sources with URLs and retrieval dates
carried over from the raws you relied on". This is not pedantry here: the first three
quotations are the entire evidentiary basis for three gate-4 dispositions, one of them
for a selected member, and none can be checked from the decision. The `httptest` figure
carries neither endpoint nor retrieval date and is the sole stated ground for not
adopting a candidate the decision says fails no gate.

What resolves it. Carry the endpoints from the raws, as R01's decision does in its own
**Sources.** paragraph, or state the figures with a per-figure endpoint at the point of
use. The raws hold the URLs already — `raw/codex.md` cites each figure inline — so this
is transcription, not new retrieval. The recommendation does not move.

**JF-4 — blocking. A gate-2 sentence cites a check that does not establish it, and the
dependency-tree half of gate 2 is answered for no candidate and recorded as unproven for
none.**

Quoted, from `mockall`'s gate-2 cell: "**passes** — declares `rust-version = "1.77.0"`
(C01), enforced by a CI job pinned to that image; its six required dependencies are pure
Rust and older-MSRV (C08)".

The problem. C08 in the log asserts one thing: "mockall 0.15.0 required normal
dependencies are exactly: cfg-if downcast fragile mockall_derive predicates
predicates-tree — no tokio, no hyper, no async runtime". It says nothing about any
dependency's MSRV, and the script's C08 block tests only the dependency-name set and the
HTTP status. "Pure Rust and older-MSRV (C08)" therefore attributes to the check a
property the check does not carry — the exact defect shape the synthesizer contract warns
about. The wider gap is that gate 2 as the prompt writes it is "crate **and
dependency-tree** MSRV", and no candidate's tree MSRV is established anywhere in the
decision, nor listed in the unproven table with what would prove it. Both raws saw this:
`raw/codex.md:61` records "the resolved dependency-tree MSRV is unverified and must be
checked after the template fixes `rust-version`".

What resolves it. Drop the "(C08)" attribution or extend C08 to assert what the sentence
claims, and add a row to the unproven table for dependency-tree MSRV with its proof — a
resolved lockfile the synthesizer role does not permit this run to produce, which is the
disposition R33 reached for the same obstacle. The recommendation does not move.

**JF-5 — non-blocking. The BASELINE-REVIEW quotes half of R01's F121 row, and the omitted
half reads as contradicting member 3.**

Quoted, from the decision: "R01's own F121 row commits the template to one contract
function 'called from `tests/` once per adapter' and names two adapters". The full row at
`research/topics/01-ports-and-adapters-seam/DECISION.md:17` reads "called from `tests/`
once per adapter; **no parametrization or mocking crate**".

The problem. A reader checking the narrowing against R01 meets a clause that appears to
forbid what member 3 adds. The decision has the answer already — R01's clause governs the
*suite mechanism* (a mock programmed per test compares nothing, which is why alternative
B "cannot serve F121"), whereas `httpmock` stubs the upstream the real adapter talks to
and does not touch the suite's mechanism. Quoting the row in full and saying that in one
sentence is what makes the narrowing visibly legitimate rather than selective.

What resolves it. Quote the full row and add the distinguishing sentence.

**JF-6 — non-blocking. Member 1 receives no gate or figure statement, and the omission is
not declared.**

The problem. The tier guidance in the prompt is explicit: "If a metric is inapplicable to
this item kind, state `inapplicable` and the reason in the answer; do not omit it
silently", and "pattern candidates use the pattern fields and explain why crate figures do
not apply". Member 1 is a pattern with no crate; the fitness-gate table and the
maintenance paragraph cover only the four candidate crates, and nothing says why. R01 set
the precedent at its line 93: "Fitness gates 2 to 6 for the language-feature members …
are `inapplicable` — no crate exists to fail an MSRV, advisory, platform, feature or
build-cost gate".

What resolves it. One sentence stating the gates and figures `inapplicable` for member 1
with the reason.

**JF-7 — non-blocking. An executed claim appears in neither log.**

Quoted: the script "passes `shellcheck` with no findings".

The problem. I read the script rather than rerunning it: it contains no `shellcheck`
invocation, and neither `r48-claims-check.log` nor `r48-archive-rerun.log` records a
`shellcheck` run or its output. The synthesizer contract addresses this case directly —
"if you run a follow-up by hand, add it to the script before you cite it, because an
auditor reruns the script and counts". Every other property asserted in the same sentence
is verifiable by reading the script and is true (`set -uo pipefail` at line 28,
`/usr/bin/grep` by absolute path, per-command status capture, no personal address in the
`User-Agent`), which makes the one unrecorded claim the odd element. The adjacent claim
that C18 "prints `SKIP` by name where that clone is absent" is sound: the `skip()` helper
is at line 46 and the C18 comment at line 22 documents the branch.

What resolves it. Fold the `shellcheck` run into the script and its result into the log,
or drop the clause.

**JF-8 — non-blocking. A scoping sentence is true of the log and false of the decision
body.**

Quoted: "No download counter, star count, open-issue count or active repository's
`pushed_at` literal is printed anywhere, because those drift by the hour."

The problem. Read against the log the sentence holds. Read against the decision it does
not: "35 stars and 55 reverse dependencies" is a star count, and "`mockall` **active**
(not archived; pushed 2026-09-02 …)" and "`httpmock` **active** (not archived; pushed
2026-09-14 …)" are `pushed_at` literals for two repositories the same paragraph calls
active. "Anywhere" is the word doing the damage.

What resolves it. Scope the sentence to the script's output, and give the three body
figures their endpoint and retrieval date under JF-3.

## Assessment

Reject. JF-1 and JF-2 each turn on a fitness gate read differently in different rows of
one document, and the programme has already settled which reading governs; JF-3 and JF-4
leave gate dispositions that a reader cannot check against a source. Any one of the four
is sufficient to send the item back.

The recommendation itself is well argued and I expect it to survive. Members 1 and 3
stand under every finding: nothing here touches the case for hand-written fakes plus
`RecordingPort<P>` as the default, and JF-1 strengthens rather than weakens the case for
`httpmock` 0.8.3 over the crate the owner reference names, because a gate failure is a
firmer ground than the two fit grounds the decision currently leads with. **Member 2 is
the one part that can move**: if gate 4 cannot be closed for `mockall` 0.15.0 on macOS
with observed evidence, the strict reading puts it under *Excluded by gate* and the stack
becomes two members. That consequence is bounded and the decision has already priced it,
recording that member 2 "adds only terseness" and that dropping it "costs the template no
capability". No other finding moves any selection; JF-3 and JF-4 are citation and
attribution repairs, and JF-5 through JF-8 are wording.

Two procedural notes. The role doc lists `review/audit-codex.md` among my inputs; it did
not exist when I read the run directory, so the empirical audit of this revision is not
reflected here and my judgment rests on the decision, the two raws, the two committed
logs, the check script, and the repository documents named in my task. There was no prior
`review/audit-fable.md` to archive. I did not rerun either log and I did not edit the
decision.
