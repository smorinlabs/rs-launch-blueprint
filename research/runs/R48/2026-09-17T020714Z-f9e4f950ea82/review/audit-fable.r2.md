decision-sha256: 29e7c7cf1f207e564ec839db168258abe7d0a5e1cdb79959e0b3faf5992fb683
actor: audit-fable-2026-09-17T020714Z-f9e4f950ea82-r2
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: JF-9 (blocking): five prose locations and the committed `D01` log line credit check D01 with compiling **both** selected members' dependency trees at 1.96.0 — the revision note's JF-4 row, the `## Parameters` prose at line 506, the D01 row of the spike table at line 583, engine item 7 at line 747, and the unproven table at line 772, which names "`mockall`'s six crates and `httpmock`'s 25" as compiled under D01 — but D01 runs `cargo +1.96.0 test` with the feature **off**, and `mockall` and its six required dependencies do not appear in that run's compile list while `D05` in the same table proves their absence ("`cargo tree -i mockall` … did not match any packages"); `mockall`'s tree compiles under **D02**, so the fact is proven and only the attribution is wrong, which is the JF-4 defect shape recurring inside the JF-4 repair, and the `mockall` gate-2 cell at line 306 already cites "(D01, D02)" correctly, showing the intended form; JF-10 (blocking): two claims the revision's own `## Empirical check` labels superseded are still live in the document — `## Decision` at line 45 states "Nothing was built here and no Rust was compiled by either engine or by this synthesis", which line 528 contradicts in terms ("Revision 1 said 'nothing was compiled'; revision 2 compiles one thing"), and the `httpmock` gate-6 cell at line 307 ends "**No wall-clock figure: nothing was compiled**" where the parallel `mockall` cell at line 306 was correctly rewritten to "**No wall-clock figure is offered**: the spike compiles a two-method probe crate, not the template", and the spike log records three wall-clock figures (27.05s, 9.45s, 20.14s) for builds that include `httpmock`

## Principle and agreement level

Unchanged from revision 1 and unchanged in my assessment: F119 and F120 are stated as
capabilities, sourced to `docs/port/areas/testing-coverage.md:9-10` and
`docs/port/DIVERGENCE-ANALYSIS.md:177-178`, and the ledger rows the decision settles are
the two it owns at `docs/port/COMMONALITY.md:125-126`. I re-read none of this ground in
round 2 beyond confirming the text did not move; round 1 verified it line by line and
revision 2 does not touch it.

The `BASELINE-REVIEW: F120` finding stands as written and is now better supported. JF-5 is
closed: line 282 quotes R01's F121 row in full — "called from `tests/` once per adapter;
no parametrization or mocking crate" — and adds the distinguishing sentence I asked for,
"the row's second clause governs the suite's own mechanism — this finding proposes no
parametrization and no mocking crate in that suite, only an upstream for the adapter it
already runs against". That is the sentence that makes the narrowing visibly legitimate
rather than selective, and it forecloses the reading an empirical auditor would otherwise
have to raise.

## Design and evidence

**JF-1 is closed, and closed uniformly rather than locally.** I asked for the strict
gate-2 reading applied by one rule to every candidate. Revision 2 does exactly that, and
it does it from a single executed table rather than crate by crate: check E04 reads the
newest non-yanked version and declared `rust-version` for **all eleven** surveyed crates in
one pass, and the log line enumerates them — `mockall=0.15.0:1.77.0 httpmock=0.8.3:1.88.0
mockito=1.7.2:1.70 unimock=0.6.8:1.70 faux=0.1.13:1.65 wiremock=0.6.5:NONE
httptest=0.16.4:NONE mry=0.14.0:NONE double=0.2.4:NONE stubr=0.6.2:NONE rvcr=0.2.1:NONE`.
Five clear the gate, six do not, and the six are exactly the six now under *Excluded by
gate*. `wiremock` 0.6.5 and `httptest` 0.16.4 moved there, `mry`'s clause is corrected, and
every superseded sentence is quoted where it was replaced, which is what lets a reader
check the sweep rather than trust it. The rule's authority is cited at
`docs/planning/p02/execution-ledger.md:414` and `:640`, the two locations I named.

Three things raise this above a minimal compliance repair. First, the exclusion is stated
no harsher than the evidence: `wiremock`'s entry records that it fails **no other** gate,
with gate 3 (C07), gate 4 (E02), gate 5 (C11) and gate 6 (C19) each shown passing, so the
reader sees a crate excluded on one declaration rather than a crate disparaged. Second, the
decision adds a fact that settles whether the absence is an oversight: pull request #172 to
add a `rust-version` was closed unmerged on 2025-08-26, "so the absence is settled rather
than pending". Third, it resists the temptation to lean on C20 — it notes that an effective
floor inferred from a bug report "is exactly the 'unknown effective version' the ledger
rules insufficient", which is the correct reading of the rule against its own item.

Engine item 3 is flipped to codex on the gate, with `raw/codex.md:115` quoted and revision
1's sentence named as superseded, while everything of opus's that survives the gate is kept
and re-labelled as supporting rather than leading ground. That is a settlement on evidence
in both directions.

**The C12 reversal condition now holds.** Revision 1 allowed `wiremock` back on commit
activity alone. Revision 2 states the gate as the only door — "a released `wiremock` 0.6.6
or later that declares `rust-version` inside the floor — that is the gate, and nothing else
clears it" — and says explicitly that commit activity "would lift ground 3 only, leaving
grounds 1 and 2 standing". The `re-verify:` line carries the same asymmetry, and C13 is
re-described as lifting the maintenance ground only. The reconciliation also gains the
sentence that states the owner's actual choice plainly: "An owner who wants `wiremock` is
choosing to waive a gate, not to prefer a crate." That is the correct framing of a differ
from a standing owner input under owner decision 11.

**JF-2 is closed, and the observed compile is enough to close gate 4.** I named two
acceptable resolutions in round 1 and revision 2 took the stronger one. The evidence is a
throwaway probe crate — one two-method `ProbePort` trait, one `#[automock]`, two tests —
built in `/private/tmp/r48-r2-spike-AcA2km`, outside the repository, deleted on exit, and
asserted to be outside the tree by D00. This stays inside the role's boundary: it is the
"confirm a version pin exists and installs" check the synthesizer role permits, it is not a
seam, service, acceptance script or template scaffold, and R01 closed the identical macOS
gap for `serde` the same way. The decision draws the line itself and keeps the template-side
claims unproven, including the one that matters most — the generated mock is "**Still
unproven against R01's actual `ProjectsPort`**, whose method set and any async form differ".

On sufficiency: gate 4 asks that a candidate build and be tested on `ubuntu-latest` and
`macos-latest`, evidenced by a CI badge or a stated platform list. `mockall` now has
Ubuntu from its own CI at the `v0.15.0` tag and macOS from direct observation at the
recommended version — D02 expands `#[automock]`, erases the generated mock to
`Arc<dyn Trait>` and passes `.with(eq(7)).times(1)` at 1.96.0, and D03 repeats it at stable
1.98.0 against the same lockfile under `--locked`. A direct execution of the recommended
version on the required OS is stronger evidence than the badge the gate names as a
sufficient form, so the bar is cleared rather than inferred, which is precisely what the
strict reading demands. The decision is also honest about the residue: the probe ran on
"Darwin 26.4 aarch64 … the architecture `macos-latest` runs today, though not the GitHub
runner image itself", and codex's wider point is preserved in the unproven table as the
template's own two-OS lane. Engine item 7 records the disagreement I said was missing,
settles it **for codex on the reasoning**, and then closes it by evidence rather than by
demotion. Member 2 stays on grounds, not on preference.

**Provenance of the compile is fully recorded.** Toolchain: `cargo 1.96.0 (30a34c682
2026-05-25)` and `rustc 1.96.0 (ac68faa20 2026-05-25)` through `rustup` for the floor,
`cargo 1.98.0 (797e8a9bc 2026-08-05)` and `rustc 1.98.0 (88d9e12ae 2026-08-18)` for stable,
all four version strings in the decision and the log's own banner. Host: Darwin 26.4 arm64,
with the macOS product version printed. Command: `bash
review/evidence/r48-r2-msrv-macos-spike.sh`, named in the commands table with its result
and log path. Exit: 0, with `RESULT: all checks passed (0 FAIL)` and 6 PASS lines. The log
carries, in a `# `-prefixed appendix declared volatile, cargo's full compile output for all
three invocations, both `cargo tree` outputs, and the complete resolved lockfile as 114
name/version pairs, so a reader can check what was and was not built rather than taking the
assertion lines on trust. That transparency is what let me find JF-9.

**JF-3 is closed.** Every figure I named now carries an endpoint and a retrieval date, and
the repair is systemic rather than spot: a **Sources** paragraph groups them by endpoint
family, states which were executed by this synthesis and which are carried from the raws,
and spells out the responsiveness method down to the `author_association` filter and the
exclusion of the reporter. The three adopter claims that carried three gate-4 dispositions
are now checks — E01 (`tokio-rs/tokio`, and it records the pin as 0.13.0 and **not** the
recommended version), E02 (`matrix-org/matrix-rust-sdk`), E03 (`apache/iceberg-rust`, which
asserts the macOS mention and explicitly does **not** assert the build-only/tests-ubuntu
refinement it carries from opus). `httptest`'s 35 stars and 55 reverse dependencies, the
figure that had neither endpoint nor date, now has both. E01–E03 are also written to fail on
an upstream bump, which turns a carried citation into a maintained one.

**JF-4 is closed on the substance and reopened on the attribution.** The "(C08)" clause is
gone, and C08 is now explicitly limited — "cited only for the dependency **names** it
asserts, not for their MSRVs". Dependency-tree MSRV is executed for both selected members
and recorded as unproven for `mockito` with what would prove it, and the unproven row even
carries the right caveat about MSRV-aware resolution proving that "a satisfying resolution
exists, not that every newest transitive version is within the floor". What is wrong is
which check is credited, which is JF-9.

**Nothing in the recommendation moves.** The three members, their versions, their manifest
shapes and their roles are identical to revision 1; no parameter value changes; the
`BASELINE-REVIEW` stands. Neither new finding touches a selection, a gate disposition or a
member.

## Completeness

**Structure.** The four required H2s in order — `## Decision`, `## Parameters`,
`## Empirical check`, `## Engines` — with no others and no `## Supersedes`, which is right
for an unpublished item, and one `### Principles and implementation`. The revision note and
the finding-disposition table sit above `## Decision` as front matter rather than as a new
H2, which keeps the required set intact. The `re-verify:` line closes `## Decision`.

**`## Parameters`.** Five `- assumes` lines, no `- owns` line against the prompt's empty
`owns:`, no `CONFLICT:`. I re-extracted each value and compared it byte-for-byte against
column 4 of the matching `docs/port/PARAMETERS.md` row: all five are identical, unchanged
from revision 1. Values are bare, with the bearing-on-the-decision prose after the list.

**Fitness gates.** Gate 1 remains `inapplicable — owner ruling 2026-09-12 (Q7.B)`; I raise
no licence finding. Gates 2 to 6 are answered per candidate for the four shortlisted crates
and in prose for each excluded one, now under a single stated rule. JF-6 is closed: line 286
carries an explicit `inapplicable` statement for member 1 covering gates 1 to 6 **and** the
crate figures the prompt's evidence table requires, with the reason ("there is no registry
page and no repository to query") and the R01-style record that the language features
predate Rust 1.0. Both halves of gate 2 are now distinguished per candidate, which is an
improvement on the prompt's own granularity.

**Empirical check.** Three scripts, 31 checks, 31 PASS, exit 0 each. I read the three
committed logs and the clean-extraction rerun and did not rerun any of them.
`r48-r2-archive-rerun.log` carries 31 `PASS` lines and three `RESULT: all checks passed (0
FAIL)` lines from a `git archive HEAD` extraction, matching 20 + 6 + 5. Script 1 and its two
logs are byte-identical to revision 1, which the round-1 empirical audit reproduced in two
environments. Identifier spaces do not collide (`C01`–`C20`, `D00`–`D05`, `E01`–`E05`).
JF-7 is closed by E05, which runs `shellcheck` 0.11.0 over all three scripts and asserts
both a zero exit and zero lines of output, with the superseded prose claim named. JF-8 is
closed: the volatility sentence is scoped to "the scripts' output" and says in terms that
revision 1's claim "was true of the log and false of the document".

**Where completeness fails.** Two sentence-families were not carried through the sweep that
the revision's own facts changed: JF-9 and JF-10. Both are mechanical, both are repairable
against evidence this run already holds, and neither requires new retrieval or a new check.

## Findings

**JF-9 — blocking. Five prose locations and the committed log line credit D01 with a
compile D01 did not perform; D05, in the same table, proves it did not.**

Quoted, from the D01 row of the spike table at line 583: "`cargo test` with the feature
**off** exits 0 with exactly 1 passing integration test — **both selected members' whole
resolved dependency trees compile at the `msrv-policy` floor**, which is gate 2's tree half,
and the gated `mockall` test is correctly invisible without the feature". Quoted, from the
unproven table at line 772: "**Proven** (D01): the whole resolved tree, `mockall`'s six
crates and `httpmock`'s 25 including `tokio` and `hyper`, compiles at 1.96.0". Quoted, from
the committed log: "PASS D01: cargo +1.96.0 test (feature off) exit 0 … — mockall's and
httpmock's resolved dependency trees compile at the msrv-policy floor of 1.96.0 on this
macOS host".

The problem. D01's invocation is `cargo +1.96.0 test` with the `mock` feature off. I read
the log's `msrv-nofeature.txt` appendix: the only three lines in it matching `mockall` are
the probe crate's own name (`Compiling r48-mockall-probe`, `Running unittests …
r48_mockall_probe-…`, `Doc-tests r48_mockall_probe`), and `mockall`, `mockall_derive`,
`predicates`, `predicates-core`, `predicates-tree`, `downcast`, `fragile` and `termtree`
appear nowhere in it. They all appear in `msrv-feature.txt`, which is **D02**. D05 states
the same fact from the other side, one row below D01 in the same table: with the feature
off, "`cargo tree -i mockall`" reports "did not match any packages". So the D01 row asserts
that `mockall`'s tree compiled in a run that the adjacent row proves did not contain it,
and the row contradicts itself internally, since its own closing clause concedes the gated
`mockall` test is invisible there.

This matters beyond tidiness for three reasons. The underlying claim is *true* — both
members' trees do compile at 1.96.0, D01 for `httpmock` and D02 for `mockall` — so nothing
here is unsupported; but the unproven table is the one place a reader goes to learn what is
proven by what, and it names the wrong check. The log line is what an empirical auditor
reruns and reads, and a `PASS` line that asserts an outcome its command did not produce is
a check asserting more than it tests. And this is the JF-4 shape — attributing to a check a
property that check does not carry — recurring inside the repair for JF-4, which is the
failure mode the synthesizer contract names ("enumerate mechanically, never by reading").

What resolves it, and the correct form is already in the document. The `mockall` gate-2 cell
at line 306 gets it right: "*Dependency tree:* **executed** — the whole resolved tree
compiles and its test passes at 1.96.0 on this macOS host (D01, D02)". Apply that citation
at the five locations that name D01 alone — the revision note's JF-4 row (line 19), the
`## Parameters` prose (line 506), the D01 table row (line 583), engine item 7's closing
clause "and D01 does the same for the resolved trees of both selected members at the floor"
(line 747), and the unproven table (line 772) — and rewrite D01's assertion, in the table
and in the script, to state what that command established: `httpmock`'s resolved tree
compiles at the floor, the MSRV-aware resolve locked 113 packages to 1.96.0-compatible
versions, and the gated `mockall` test is absent, with D02 supplying `mockall`'s tree.
Re-run script 2 so the log carries the corrected line. The recommendation does not move.

**JF-10 — blocking. Two claims the revision's own `## Empirical check` declares superseded
are still live elsewhere in the document.**

Quoted, from `## Decision` at line 45: "Nothing was built here and no Rust was compiled by
either engine or by this synthesis: the template does not exist yet." Quoted, from the
`httpmock` gate-6 cell at line 307: "**No wall-clock figure: nothing was compiled**".

The problem. Revision 2's central repair is an executed compile, and the decision says so
at line 528 in terms that name the earlier wording as superseded: "Revision 1 said 'nothing
was compiled'; revision 2 compiles one thing and it is worth being exact about what". The
superseded wording is nevertheless still standing in `## Decision`, which is the section a
reader reads first and the section a publication carries, and it is categorical about this
synthesis specifically rather than about the template. The gate-6 case is the same miss in
miniature and is the clearer evidence that the sweep was done by reading: the parallel
`mockall` cell in the adjacent row *was* rewritten, to "**No wall-clock figure is offered**:
the spike compiles a two-method probe crate, not the template, so its timings would not
represent the template's cost", while the `httpmock` cell directly below kept the old
sentence — even though `httpmock`'s tree is the one thing D01 did compile, three times, and
the log prints the wall-clock figures (27.05s at the floor feature-off, 9.45s at the floor
feature-on, 20.14s at stable). The correct disposition is not that no figure exists but
that the figures that exist do not represent the template, which is exactly what the
`mockall` cell now says.

For the avoidance of doubt, one nearby sentence is **not** part of this finding and should
not be swept: `## Engines` at line 672 says the two raw reports "both report that nothing
was compiled", which is a true statement about codex and opus and must stay.

What resolves it. Rewrite line 45 so it says what is true of revision 2 — the template was
not built and its recommendation was not implemented, and the only Rust compiled was the
throwaway probe crate under `## Empirical check` — and give the `httpmock` gate-6 cell the
same treatment its `mockall` neighbour already has. The recommendation does not move.

## Assessment

Reject, on two mechanical findings and nothing else. I want to be explicit about the shape
of this round, because the difference from a circling item matters: revision 2 closed all
eight round-1 findings, and closed the hardest one the expensive way. JF-2 could have been
answered by demoting `mockall`'s gate-4 cell to match `mockito`'s and dropping member 2 —
the cheap path I left open — and instead the synthesis went and observed the thing, at the
recommended version, at both the floor and stable, on the required OS, and then kept
codex's residual point alive in the unproven table. JF-1's repair is broader than I asked
for: one executed table for all eleven crates, every superseded sentence quoted, and the
exclusion of the owner reference's crate stated without overstating what is wrong with it.
JF-3's repair is a Sources apparatus rather than a patch. That is a revision that engaged
with the findings rather than with the auditor.

JF-9 and JF-10 are both consequences of the same thing: the compile changed what is true
about this run, and two sentence-families did not follow it. Neither is an unsupported
claim — the facts are in the committed logs — and neither touches a member, a version, a
gate disposition or a parameter. **The recommendation does not move under either finding**,
and no new evidence gathering is required: JF-9 needs a citation changed from D01 to
(D01, D02) in five places, one assertion line rewritten in the table and in script 2, and
that script re-run so its log carries the corrected text; JF-10 needs two sentences brought
into line with the section that already supersedes them. Both should be done by the
mechanical enumeration the contract prescribes, from the searches this audit records — the
line numbers are given above — rather than by re-reading.

Procedural notes. `review/audit-codex.md` now exists for round 1 and I read it: it approves
revision 1 on empirical grounds, reproduced script 1 in two environments, and independently
re-derived the crates.io, RustSec, GitHub and `c2pa-rs` facts from their primary endpoints,
which corroborates the factual base both revisions rest on; it took no position on the gate
readings, which is my lane. No round-2 empirical audit exists — Codex is out of usage — so
this round is judgment only, and the two new scripts have not been independently reproduced
by another family; I read their logs and the clean-extraction rerun but did not run them.
Round 1's audit is archived byte-identical at `review/audit-fable.r1.md`, sha256
`1e02b647b2061ea693845fc3a03920f4d5a5da425143b0133ad1b1598748f292`. I did not edit the
decision.
