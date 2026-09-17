decision-sha256: 62f5c9f799c008af0de12deb083276454808183cbc8313acbec6ce53e0ab0cf1
actor: audit-fable-2026-09-17T020714Z-d0b567b4b9f1-r1
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: JF-1 — fitness gate 3's `unsafe`-posture limb and gate 5's async-runtime-coupling limb are stated for no candidate, though the prompt forbids omitting a gate silently and `raw/opus.md` answers both

Judgment auditor for R53 (`config-schema-validation`, kind `crate`, Focused tier, owns
nothing), revision 1, run `2026-09-17T020714Z-d0b567b4b9f1`. I produced none of this item's
artifacts. The hash above was computed with `shasum -a 256` before I read the decision and
re-taken immediately before this file was written and again before it was committed; it did
not move, so this report binds exactly one version. The empirical (Codex) audit is deferred
because the Codex account is out of usage, so this is the only audit of revision 1.

Gate 1 (licence) is `inapplicable` here by the owner's ruling of 2026-09-12, recorded at
`docs/port/OWNER-REVIEW.md:47` under "2026-09-12 — no licence check for anything the template
uses (Q4, superseded and widened by Q7.B)". I raise no licence finding and treat the
decision's licence strings as the metadata it says they are.

## Principle and agreement level

The decision states the shared requirement as a behaviour, not a library, and states it in a
form a reader can test: "*no value read from that file reaches program logic until it has
been checked against a declared schema, and a value the schema rejects produces a report that
names the offending key*". It then fixes the level of required agreement explicitly — "an
**architectural pattern plus an observable standard**, not a library" — and grounds that in
the two ledger rows rather than asserting it. Both rows check out against the ledger at
source. `docs/port/COMMONALITY.md:232` carries F228 as `DIVERGENT` with owner `R53`, and
`:233` carries F229 as `COMMON → REUSE` with no research item, whose own Notes already read
"serde's typed deserialization preserves this same pattern, so this is a substitution in
spirit, not an override". The decision's conclusion that **no `OVERRIDE (OV-nn)` is opened**
follows from that Notes text and is correct: the F229 row anticipates the substitution, so
there is no departure from a recorded pattern to argue.

F229's recorded acceptance criterion — "validation-before-use with constrained types or
explicit checks, and representative rejected values" — is quoted accurately (the decision
uses the ledger's "and", where `raw/opus.md:417` paraphrased it as "with"; the decision
corrected its own raw rather than inheriting the slip). The criterion is met on the
decision's own evidence, at `S86` and `S87`: ``invalid value: integer `0`, expected a nonzero
u32`` and ``unknown variant `yaml`, expected one of `table`, `json`, `markdown`, `name` ``.

The native-design justification is the strongest part of the document and it is argued from
the ecosystems rather than from preference: "a Python `dict` or a JS object carries no
declared field types, so a schema library must re-declare them at runtime, and re-declaring
them is the natural place to also declare `.positive()`. Rust declares them at compile time,
so the constraint layer collapses into the type layer for everything a type can express."
The consequence drawn from it — "the port therefore moves work in the opposite direction from
the naive mapping — **less** library for constraints, **more** deliberate structure for
reporting" — is the outcome-preserving inversion the charter asks for, not a shortcut.

## Design and evidence

**The recommendation follows from the evidence as written.** Four architectural alternatives
are compared before any library is ranked, and the comparison column that decides between
them ("Type errors aggregated?") is an executed result in every row that this run could
execute. Alternative 3 is correctly placed out of scope as R52's seat rather than argued
against. The decisive row is alternative 2, and it was measured, not asserted: for a document
carrying `format = "yaml"` alongside two values `garde`'s own rules would reject,
`P2_GARDE_REACHED = false` and `P2_GARDE_REPORT_ENTRIES = 0` (`S74`, `S75`). The inference
drawn — "adding the crate changes the report from one error to one error" — is exactly what
those two lines support, no more.

**The decisive measurement's provenance is recorded to a standard I would want copied.** The
probe's toolchain is in the log's section 0 (`rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
`cargo 1.98.0`, macOS 26.4 25E246, Darwin 25.4.0 arm64); its pins are asserted by content at
`S91`–`S93` (`serde v1.0.229`, `toml v1.1.6`, `garde v0.23.0`) against the probe's own
`cargo tree -e normal`; its location is a `$TMPDIR` crate deleted by an `EXIT` trap, and the
decision says so and says why ("**Nothing was written into the repository and no template
file was created**"). That matters for this programme's rule against a decision implementing
its own recommendation: the probe runs the candidate crates over literal TOML strings to
settle an engine disagreement, which is verification, and it writes no template file, which
is the line the role doc draws. The decision is on the right side of it.

**The conclusion is stated inside what the probe measured, and the boundary is drawn
explicitly.** The scope paragraph is the model: "What was *measured* is `garde` 0.23.0 behind
`serde` 1.0.229 and `toml` 1.1.6, on this host, for one document", separated from what
"*follows structurally*", and then closed with the sentence that decides the honesty
question — "It was **not separately measured for `validator` or `serde_valid`**, and where
this decision says 'no serde-layered validator aggregates type errors' it means the inference
just stated, resting on the `garde` measurement plus serde's documented derive behaviour —
not four measurements." The same discipline appears where it costs the decision something:
the observation that serde's derive reported `color` rather than the file's first key is
labelled "**That is one observation on one document, not a rule**; no ordering guarantee is
claimed and none was tested across inputs." An auditor looking for overclaim finds the
decision has already flagged the places where it could have overclaimed.

**The lockfile census is a valid ground, not the appeal to popularity the mandate forbids.**
Three things settle this. First, the prompt requires it: `## Required evidence` step 3 is
"Practice evidence: survey what mainstream, well-regarded Rust projects use … and cite the
evidence that they are well regarded … rather than asserting it". A required survey limb is
not a forbidden appeal. Second, it is not load-bearing for the recommendation — the decision
heads the section "**Practice evidence, at the strength it actually supports**" and the
choice is already decided by `S74`/`S75` above it; remove the census and the recommendation
stands unchanged. Third, the census is a claim of *absence in a named cohort*, verified by
content: seven pinned `Cargo.lock` files, per-project counts at `S68-<project>` each `equal:
0` and `S69-<project>` each `1 >= 1` for `serde`, totals `S70` `equal: 7` and `S71`
`equal: 0`. The seven package counts sum to the stated 2,596 (292 + 428 + 337 + 538 + 517 +
273 + 211). The decision states the limit itself — "seven projects is a cohort, not a census
of the ecosystem" — and then records the counter-evidence, that the top reverse dependencies
of `garde` and `serde_valid` are HTTP request-body validators. Reading a lockfile rather than
a root `Cargo.toml` is the stronger form of the claim and the decision says why.

**The engine splits are settled on grounds, in all four cases.** Disagreement 1 is settled by
the probe, and Codex is not flattened: `garde` is kept as the ranked runner-up "on Codex's own
grounds", with `S77`–`S79` recorded "in `garde`'s favour". Disagreement 2 is settled by a
re-run query rather than by preferring a raw: `S64` and `S65` each `equal: 2`, the two
post-release default-branch commits, with the counter-evidence (unarchived, `S62`; no
advisory, `S59`; a single maintainer's batched release history) recorded beside it, and the
`at-risk` verdict correctly anchored to a concrete signal rather than to release age, which
the prompt's rubric calls "a trigger to investigate, never the verdict". Disagreement 3 is
the clearest: Codex wrote that "`garde`'s declared 1.87 is below the project floor but its
resolved dependency tree still requires P03 verification" (`raw/codex.md:70`, quoted
accurately), and the decision is right that this inverts the test — the floor is the oldest
Rust supported, so a declared `rust_version` at or below it passes, and `garde` 1.87,
`validator` 1.88 and `serde` 1.56 all clear a 1.96 floor. The floor itself is derived
correctly (stable 1.98.1 minus two minors). Disagreement 4 is settled by re-running Codex's
own objection with controls: six candidate crates at `S59-*` each `equal: 404`, three crates
with known advisories at `S60-*` each `equal: 200`, a nonexistent name at `S61` `equal: 404`.
The residual caveat is kept rather than glossed — "a 404 cannot distinguish 'no advisory' from
'name unknown to RustSec'" — which is the only defensible reading of that control set.

**The couplings are stated rather than re-decided, and each is true at source.** R52's
selection of `toml` 1.1.6 with default features and explicitly not `preserve_order` is
verified at `S25` and `S27`; R52's re-verify trigger 6 is quoted at `S28` and correctly
reported as not tripped, since the decision concludes `serde_spanned` suffices; and the
requirement `raw/opus.md` passed to R52 is discharged, not left outstanding, on
`serde_spanned v1.1.1` resolving as a non-optional dependency of `toml v1.1.6+spec-1.1.0` in
the probe's own `cargo tree` (log line 388, which I read).

## Completeness

**H2 set and order.** `## Decision`, `## Parameters`, `## Empirical check`, `## Engines` —
exactly the runbook's set for a first revision, in order, with `### Principles and
implementation` present inside `## Decision` and the `re-verify:` line as the final line of
that section. `## Supersedes` is correctly absent and the absence is explained.

**The five `- assumes` lines are byte-identical to the registry.** I compared each value
after `= ` against the matching `value` cell in `docs/port/PARAMETERS.md`: `msrv-policy` (118
characters), `rust-edition` (4), `target-os-matrix` (27), `license` (17) and
`error-taxonomy-exit-codes` (4,057) each match byte for byte. The grammar the synthesizer
role calls publication-blocking is respected: five `- assumes` lines, no backticks wrapping a
value, no citation and no commentary on any parameter line, with the bearing-on-the-decision
prose kept below the list. No `- owns` line appears, which is right: the prompt's
`## Couplings` block carries an empty `- owns:` line (`S01`) and the registry lists no `R53`
owner, and the decision says both.

**No `CONFLICT:` line.** I checked both of this item's raws directly — neither `raw/codex.md`
nor `raw/opus.md` contains a line beginning `CONFLICT:` — so the decision's "Neither raw
raised one" is accurate.

**The `117 checks run, 0 failures, 0 skips` claim is inside what the log shows.** I read
`review/evidence/r53-verify.log` without rerunning it. Its section 10 summary reads
`checks run:  117`, `failures:    0`, `skips:       0`, and an independent count of
line-initial `PASS ` / `FAIL ` / `SKIP ` records gives 117 / 0 / 0. Every one of the 80
`S##` identifiers the decision cites resolves to a result line in the log; there are no
dangling citations. Spot-checking the load-bearing ones, each is a content assertion rather
than a check that cannot fail — `S41` is recorded as "correctly found no match for" its
pattern, `S42` as `equal: 0`, `S47` as `equal: 1.56`.

**The standard's citations hold at the named blob.** `/Users/stevemorin/c/cli-standards/cli-design-standard.md`
hashes to `f9de0437baece3383e73ca2c5f48b7ab399b51c7`. R5.8's quoted sentence and its
`default-region` example are verbatim at `:339` and `:341`; R7.6's "lowercase-first, free of a
trailing period, name the offending input in quotes, and state a next step where possible" is
verbatim at `:422`; R7.8's single-JSON-object rule is at `:431`–`:432`; and the load-bearing
silence is real — `garde|serde_valid|validify|nutype|pydantic|zod` match zero times and
"validator" matches zero times case-insensitively across the whole document.

**Figures carry endpoint and retrieval date.** The maturity table is followed by an explicit
endpoint list naming the exact JSON fields, including the `search/issues` `.total_count`
rule the prompt requires over `open_issues_count`; the census rows carry pinned commits; the
RustSec, `channel-rust-stable.toml` and `gh api` figures each carry their URL or command;
and every figure is dated 2026-09-17, with the local-versus-UTC discrepancy disclosed in the
opening paragraph rather than left for a reader to notice.

**The unproven rows are honest.** "What this check does not prove" names the 1.96 MSRV floor,
the two-runner CI matrix, compile-time and binary-size cost, `serde`'s `unsafe` posture, and
`toml::Spanned`'s per-key offsets; `## Engines` closes with eight P03 validation items, each
a check that can fail, with items 5 and 6 explicitly marked **Unproven here** and each given
what would prove it. The type-state's "before use" property is correctly listed as unproven
rather than claimed from the code sketch, and the sketch itself is labelled "P03 writes this;
it does not exist."

**The BASELINE-REVIEW F229 disposition is a legitimate ledger disposition.** Runbook §4 puts
adjudication of `BASELINE-REVIEW:` findings on the controller with the affected owners, so the
decision's job is to carry each line with its disposition and leave the row alone — which is
what it does, saying so in terms: "**This decision edits no ledger, no prompt, no index and no
registry**". Codex's line is carried verbatim against `raw/codex.md:29` (the only departures
are the disclosed dropping of its trailing parenthetical citation and its backticks), and the
half-and-half disposition is correct on the merits: the "representative rejected values" half
is already F229's recorded criterion and is satisfied at `S86`/`S87`, while the "layer Garde"
half is the recommendation Disagreement 1 declines. Opus's line is carried and labelled
"verbatim in substance", which is the accurate label — it is compressed from
`raw/opus.md:417` — and adopting its added criterion as *this decision's proposal*, inside
the decision's own must-agree table and flagged as "an **addition** to F229's recorded
criteria", is the right handling: applied here, proposed to the owner, not written into the
row. I checked whether that unaccepted criterion is doing decisive work, since adopting one's
own proposal as a premise would be circular. It is not: even with aggregation struck from the
requirements, `garde` contributes nothing to a schema whose every constraint is a type, so
the recommendation survives without it.

## Findings

1. **JF-1 (blocking) — fitness gate 3's `unsafe`-posture limb and gate 5's
   async-runtime-coupling limb are answered for no candidate.** The prompt's gate list reads
   "3. no open RustSec advisory; `unsafe` posture stated" and "5. default features and any
   async-runtime coupling stated", and its tier guidance closes the escape route: "Apply every
   fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and
   the reason in the answer; do not omit it silently." The decision answers the advisory half
   of gate 3 thoroughly and says nothing about the `unsafe` posture of `serde`, `garde`,
   `validator` or `serde_valid`. The word `unsafe` appears twice in the whole document, and
   neither occurrence states a posture: once as "**`serde`'s own `unsafe` posture**, not
   audited here" in the not-proven list, and once in the not-re-read list as "`garde`'s and
   `validator`'s `unsafe` audits" being "carried from `raw/opus.md`". That second sentence is
   inaccurate as written — nothing is carried; the audits are referred to, not reproduced. The
   word `async` does not appear in the document at all. The problem is not that the evidence
   is missing from the run: `raw/opus.md:533-547` states the posture per candidate
   (`validator` — 0 matches; `garde` — a `transmute(&next.value)` at
   `garde/src/error/rc_list/mod.rs:93` on the default path, `unsafe impl<T> Send/Sync` at
   `garde/src/rules/pattern.rs:139-140`, `unsafe { p.as_ref() }` at `garde/src/i18n.rs:402`;
   `nutype` — behind an opt-in feature; `serde` — not audited, with its reason) and
   `raw/opus.md:563-570` states gate 5 ("Every candidate is synchronous and couples to **no**
   async runtime"). The omitted content is adverse to the runner-up specifically: a reader
   promoting `garde` under re-verify trigger 6 would never learn from this decision that the
   crate carries `unsafe` on its default path. That the sibling R52 decision of the same day
   answers the same gate in a per-gate table — "`unsafe` posture: the published `src/lib.rs`
   carries `#![forbid(unsafe_code)]` (`S66`)" — shows the standard is the programme's, not
   mine; I found no prior `audit-fable.md` in this tree that approved a decision with this
   limb absent. **What resolves it:** state the posture per candidate in `## Decision` or
   `## Engines`, attributed to `raw/opus.md` at its retrieval date (or re-verified), together
   with the reason no exclusion follows — R06 forbids `unsafe` only in the template's own code
   via `[workspace.lints.rust] unsafe_code = "forbid"` and makes no claim about the dependency
   tree — and add the one sentence that settles gate 5's async limb. Correct the not-re-read
   list so "carried" describes what the document actually does.

2. **JF-2 (non-blocking) — a quoted Codex sentence is truncated mid-sentence and closed with a
   full stop.** The decision quotes Codex as: "a malformed TOML value or wrong Rust type still
   fails during deserialization before Garde runs; Garde aggregates all semantic errors only
   after structure succeeds. That is a deliberate diagnostic boundary, not full Zod aggregate
   parity." In `raw/codex.md:13` that second sentence continues: "…not full Zod aggregate
   parity, and R55 decides how either class is tolerated". The dropped clause is not adverse —
   it agrees with this decision's own refusal to pre-decide R55 — so no meaning is bent; but a
   period where the source has a comma presents a partial quotation as a complete one.
   (The same quotation lowercases the raw's sentence-initial "A", which is ordinary quoting
   and is not part of this finding.) **What resolves it:** an ellipsis, or carry the clause.

3. **JF-3 (non-blocking) — three container-type claims that decide the runner-up ranking carry
   no evidence-check identifier and are not listed among the sources carried from the raws.**
   They are: that `toml::Table` is "`BTreeMap`-backed and iterates in sorted key order"; that
   `garde`'s "`Report` is an ordered `Vec<(Path, Error)>`"; and that "`validator`'s
   `ValidationErrors` is an unordered `HashMap` a CLI must sort before printing". None has an
   `S##` beside it, and none appears in the decision's otherwise scrupulous "Sources this
   synthesis relied on but did not itself re-read" enumeration, which lists `cargo-deny`'s
   trait, the `unsafe` audits, the workflow runner labels and the issue samples. Two of the
   three are traceable — `raw/opus.md:1094-1095` cites the docs.rs page giving
   `pub struct ValidationErrors(pub HashMap<Cow<'static, str>, ValidationErrorsKind>)`, and
   `:615` gives `garde`'s `into_inner() -> Vec<(Path, Error)>` — but the `BTreeMap` claim is
   sourced nowhere in either raw. It matters because the conclusion built on it is firm where
   its ground is not: "The report order is **deterministic and therefore snapshot-testable**,
   which `validator`'s `ValidationErrors(HashMap<…>)` is not." The probe's
   `P4_TABLE_KEY_ORDER = ["color", "format", "limit"]` (`S85`) corroborates sorted order on one
   document, which is evidence for the behaviour but not for the mechanism the sentence
   asserts. Nothing here moves the recommendation; it affects the `garde`-over-`validator`
   runner-up ranking. **What resolves it:** cite the three type shapes to their documentation
   at a retrieval date, or add them to the not-re-read list, and mark the determinism sentence
   as resting on the documented container type rather than on the single observation.

4. **JF-4 (non-blocking) — the reproducibility paragraph reports a comparison whose second
   input was not kept.** It states that "`verify.sh` was run twice back to back against the
   same tree and the two logs were diffed before this paragraph was written", and that "The
   **entire diff is four lines — two changed pairs**", citing log lines 315 and 357. I
   confirmed those two lines are the only occurrences of the PID-bearing `$TMPDIR` path in the
   committed log, which makes the claim plausible, and the role forbids me to rerun. But only
   one log is committed, so the diff itself is unverifiable from the record. **What resolves
   it:** label the double run as a process note rather than a measurement, or state the second
   log's disposition.

## Assessment

**The recommendation does not move under any finding above, JF-1 included.** `serde` with
`derive` and no validation crate wins on `P2_GARDE_REACHED = false` and
`P2_GARDE_REPORT_ENTRIES = 0` plus the fact that every constraint in the current schema is a
type; the `unsafe` posture of the candidates changes neither, because R06 scopes the
template's `unsafe` ban to first-party code and the decision excludes nothing on gate 3
anyway. If anything, supplying the missing posture strengthens the recommendation, since
`garde` — the crate not chosen — is the one carrying `unsafe` on its default path. JF-1 is a
completeness defect in a prompt-mandated per-candidate field, not a defect in the reasoning,
and it is repairable in a paragraph. The other three findings are provenance and quotation
precision and touch only the runner-up ranking and one process note.

**On R53's non-adjudication of R55's `CONFLICT:` — there is no contradiction with R55's own
rejection of it.** The runbook puts a `CONFLICT:` line on its raiser and the owning item: R53
is neither, being a sibling consumer of R67. R53 carries the line verbatim (matched against
`research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/raw/codex.md` at `S29`/`S30`), declares
"**this decision emits no `CONFLICT:` line of its own**", and disposes of it as "not
adjudicated here, and deliberately not foreclosed". R55's decision independently reaches
"No `CONFLICT:` line is raised … it is quoted, adjudicated and rejected under `## Engines`".
The two outcomes agree: neither item carries a conflict forward and neither asks R67 to
change. R53's mechanism is policy-neutral by construction — the issue list and the surviving
partial value are independent results (`S80`, `S84`) — so it supports warn-and-drop, a fatal
whole-file failure, or a split, whichever R55 and R67 settle on. One strengthening was
available and not taken: R67's own decision already states, at the passage ending "R55 and
R56 own whether a given condition is tolerated, warned about, or fatal; this item only
guarantees the entry and the code exist", which disposes of the conflict's ownership premise
from the prerequisite R53 consumes as published. Citing it would have let R53 say the
question is already owned rather than still open. That is a missed opportunity, not a defect,
and I raise no finding on it.

**On the empirical audit's absence.** With Codex out of usage, no second engine reran
`verify.sh`. I read the committed log and did not rerun it, as instructed. The claims I could
check against the log, the ledger, the registry, the standard at its blob, the two sibling
decisions and both raws all held. Acceptance still requires two approving verdicts under the
runbook, so the empirical audit remains outstanding independently of this verdict.

The decision is close to acceptance and its central argument is sound, measured and honestly
bounded. It is rejected on JF-1 alone, and a revision 2 that answers the two gate limbs — and,
if convenient, JF-2 through JF-4 — should clear this audit without disturbing the
recommendation.
