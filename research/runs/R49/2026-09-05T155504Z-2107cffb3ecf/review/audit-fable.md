decision-sha256: 86b7f925ef89ac682ea00bb0b6fea8a809c1abc712d9e0e0ced8e5082990d948
actor: audit-fable-2026-09-05T155504Z-2107cffb3ecf-r8
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

The shared requirement is stated with its source and read at the programme pins,
and revision 8 repairs the one defect the round-7 audit found here. F211
(`docs/port/COMMONALITY.md:215`, `COMMON → REUSE`) is the tool-free pattern and
F212 (`:216`, `COMMON → SUBSTITUTE`, owned by this item) is the tool row under
it; I read both lines this round and the decision's quotation of `:216`
(*"Cargo is Rust's native build system with no separate backend/bundler crate
needed"*) is verbatim, as is the F017 quotation at `COMMONALITY.md:23`.
`docs/port/BASELINE-REVIEW.md:102` classifies parent F211 `retained`, which
revision 8 does not disturb.

**F3 is closed exactly as its remedy specified.** The summary sentence now reads
*"Agreement is required at the **capability, architectural-pattern and policy**
levels — the three the B1–B4 table below assigns, B1 capability, B2
architectural pattern, B3 and B4 policy — and not at the level of sharing a
backend library."* That names all three levels the table beside it assigns and,
beyond the remedy, spells out the per-behavior mapping so the summary and the
table cannot drift apart again. The B1–B4 decomposition, its py and ts evidence
read through `git show` at the pins `b08bccfb…` and `cb1cbcb2…` (check 5), and
the §2 fitness test of the shared architectural pattern (*"B1, B2 and B4 do,
unchanged. B3 survives but its mechanism collapses"*) are untouched by this
revision and stand as the round-7 audit confirmed them.

`BASELINE-REVIEW:` handling is unchanged and still what `research/RUNBOOK.md` §4
requires: both lines are carried unresolved in the prescribed
`F### — principle — proposed change — evidence` shape with affected items named,
and neither the ledger, index, prompt nor registry was edited. I confirmed
against the revision-7 blob (`bc1794b`) that neither line moved a byte. The
`CONFLICT:` position is unchanged and correct.

## Design and evidence

**F2 is closed by the first of the two remedies offered, and A4 is genuinely the
ranked runner-up rather than a label attached to fill the gap.** Three things had
to hold and each does.

- *The rank is stated where the alternatives are compared.* A new paragraph,
  *"The ranked runner-up is A4, and its winning condition is stated rather than
  implied"*, sits immediately below the A1–A4 comparison and names A4 (Cargo plus
  a `dist` orchestration layer) as second, with the two costs that keep it from
  first — a third-party dependency taken on for a decision that is R68's, and the
  documented pull toward `dist-workspace.toml`, which is what behavior B1 forbids.
- *The winning condition is sourced, not invented.* It is the opus raw's own, and
  I read the raw rather than the decision's summary of it: that report carries an
  explicit `### Ranked runner-up` heading at
  `raw/opus-93a5d89f571b19ea2bc7cdb9ccb956052b1a414c82a9256bb31a0a71454d3059.md:521`,
  names `cargo-dist` 0.32.x at `:523-524`, and states the condition at `:526-531`
  in the words the decision quotes — *"if **R68 resolves F214 to 'cross-compiled
  binaries attached to GitHub Releases, with generated installer scripts'** …
  the alternative — hand-writing a release matrix that duplicates the target
  list — is worse. It does **not** win if R68 chooses crates.io-only
  distribution"*. The give-up list quoted at `:569-570` is verbatim. So the
  runner-up is opus's ranking, adopted with attribution, which is what the
  round-7 finding said was missing.
- *The condition is consistent with the re-verify trigger.* The trigger list now
  reads *"R68 resolves F214 to cross-compiled release binaries, which is the
  condition under which the ranked runner-up **A4** … wins"*, replacing the
  bare "the runner-up" that had no antecedent. Trigger and ranking state the
  same condition in the same words, and the trigger points the reader at the
  paragraph that ranks it.

**The three-way engine split is now recorded, and the counts are right.** I
checked Disagreement 6 against the five raws rather than against the decision's
summary. Three name the workspace split — doxa/openai (`### Ranked runner-up` at
`:251`, *"Cargo workspace split"* at `:253`), doxa/perplexity (`:170-174`,
winning *"where modularity or independent versioning is required"*) and
doxa/gemini (`:92-96`, winning on a divergent MSRV or edition for the web
surface); opus names `dist` (`:521-525`); codex names Cargo automatic target
discovery (`:79-82`, *"only if the implementation intentionally adopts Cargo's
conventional … layout, forbids `src/bin/`, and accepts automatic discovery as the
package boundary"*). Every attribution is correct and every quotation verbatim.
The settlement is argued on ownership rather than on the 3:1:1 vote — the
majority's workspace split is R02's question and is routed to its own trigger,
codex's auto-discovery is the counter-position inside the `autobins = false`
sub-decision — which is the same ground Disagreement 4 is settled on, so the
document is internally consistent about when a majority is set aside.

One ellipsis in that argument, recorded rather than faulted: *"A4 is therefore
the only one of the four costed alternatives this item could itself have chosen
second"* is supportable, because A2 (a second binary carrying
`required-features`) is R69's to choose under Disagreement 4 and the
optional-web-surface paragraph, but the local paragraph explains only A3 and
codex's proposal and leaves A2 to be recovered from elsewhere in the document.
The statement is true; its support is two sections away.

**F1 is closed, and the repair goes past the remedy in the right direction.** The
`## Parameters` consuming clause now says R22 reads *"the **target directory
layout and the target names** — library crate `rs_launch_blueprint`, binary
`rslbp`, artifacts under `target/debug/` and `target/release/`"*, quotes R22's own
prompt for the registered scope, and states that `env!("CARGO_PKG_VERSION")`
derives from the `[package] version` field, which this item does not decide. I
read `research/topics/22-runtime-version-accessor/prompts/runtime-version-accessor.prompt.md:18`
directly: the quotation is byte-exact and the line the decision cites is the line
that carries it. The clause now agrees with `### Principles and implementation`
(*"the target directory layout in `## Parameters` is the input R22's version
accessor reads"*) instead of contradicting it, and the contradiction is disclosed
rather than quietly removed.

**Everything the round-7 audit cleared, re-confirmed against this revision.** I
diffed revision 7 (`bc1794b`, sha256 `319a5356…`) against revision 8 and read
every changed hunk, so "unchanged" here is a diff result, not a re-reading.

- The `include` allow-list argument and its three grounds — B4 fidelity, the
  difference in repository shape, and the fail-open direction of a deny-list —
  are byte-identical, as are the named accepted failure mode, the `include`
  gitignore footgun from check A, the medium confidence and the stated reversal
  cost. The decision still goes against the measured 7:2 practice majority.
- `autobins = false` is byte-identical, still stated as *"a policy choice rather
  than as documented advice"*, with the asymmetry against `build = false` intact.
- The MSRV treatment is byte-identical: `rust-version` in `[package]` as the
  mechanism the fixed `msrv-policy` names, "stable minus 2 minor versions"
  computed against `rustc 1.98.0` as 1.96 and kept as a value at a date rather
  than baked into the owned parameter, consistent with `edition = "2024"`.
- The lockfile condition at cargo 1.98.0 is byte-identical — check L, its script
  (sha256 `4ed6818f…`), its log, the 13 content assertions, the three-file /
  two-assignment exhaustive enumeration and the three negative controls. No
  evidence script and no evidence log changed in this revision; I confirmed that
  from the diff, not from the decision's claim about itself.
- Gate 1 stays `inapplicable` under the owner's 2026-09-12 ruling (Q7.B), the
  settled position, and the other five gate rows are byte-identical.

## Completeness

**Every required field is present.** The four H2 sections in order with no others
and no `## Supersedes`; the recommendation (correctly *absent* rather than a
crate and version range); the ledger rows settled (F212, F213, F216, F218, F219,
with F217 confirmed), F219 now recording divergence *"by the owner's ruling
W0-R49n rather than by a research finding"*; the `### Principles and
implementation` H3 with shared requirement, source, agreement level, essential
behaviors, must-agree versus may-vary, architectural alternatives, reference
implementations and acceptance criteria; the closing line
`re-verify: 2027-03-10, or any earlier event listed immediately above`; all six
fitness gates answered before any popularity figure; toolchain, working
directory, commands, observed output and evidence log paths in
`## Empirical check`.

**Parameters.** I extracted the text after `= ` on each of the four `- assumes`
lines and compared it byte-for-byte against `docs/port/PARAMETERS.md` rows 7–10:
all four match, and all four are byte-identical to revision 7. The owned
`build-tool-output-shape` line carries a value with no backticks, citation or
commentary; a word-level diff against revision 7 shows it changed in exactly one
clause — `name rs-launch-blueprint, matching the package name` became `name
rslbp, a different string from the package name rs-launch-blueprint` — with
`CARGO_BIN_EXE_rs-launch-blueprint` becoming `CARGO_BIN_EXE_rslbp` and the
installed-command string following. The registry cell for that parameter is still
`—`, so there is nothing yet to compare the owned value against; publication is
what fills it.

**The rename, enumerated with `/usr/bin/grep` by this audit rather than taken
from the decision's account of itself.** `rslbp` occurs 34 times. Every one of
the enumerated locations the decision claims carries it does carry it:
decision-table row 3 (`:693`) and row 6 (`:696`), the F219 ledger sentence
(`:703-705`), the rewritten names paragraph (`:953-988`), AC2 (`:1022`), AC6
(`:1034`), the `- owns` line (`:1059`), the R22/R32/R68 consumer clauses
(`:1091`, `:1104`, `:1105`), the re-verify trigger list (`:1050`), Disagreement 3
(`:1427-1441`) and the P03-validation paragraph (`:1488-1496`).

**Nothing that must stay `rs-launch-blueprint` was renamed.** The 16 remaining
occurrences are each accounted for by the decision's own left-unchanged list and
I checked them one at a time: the crate, package and distribution name (row 6,
the F219 sentence, the names paragraph, the owned parameter); the planning
repository's name at `:666` and its working-directory path at `:1118`;
doxa/perplexity's proposed second binary `rs-launch-blueprint-web` at `:1405`;
and the revision-note prose that quotes the ruling. The `[lib]` crate name
`rs_launch_blueprint` is unchanged in decision-table row 2, in the owned
parameter and in the R22 clause; py's `module-name = "py_launch_blueprint"` is
unchanged in the B1–B4 table and in check 5; and every generic
`CARGO_BIN_EXE_<name>` in a quoted Cargo-reference string is untouched
(`:729`, `:1198`, `:1449`).

**Every consequence the decision itself listed for a divergent pair is carried.**
The README sentence (*"the README must say `cargo install rs-launch-blueprint`
installs the command `rslbp`"*, `:982-984`); the `cargo-binstall` `bin-dir`
`{ bin }`-rather-than-`{ name }` note (`:984-987`), which is sourced — the opus
raw states it at `:411-412` and `:486-487`, so it is a carried research fact, not
a new claim; R32's `env!("CARGO_BIN_EXE_rslbp")` (`:1104`, AC6, and the P03
negative control at `:1496`); and R68's `target/release/rslbp` (`:1105`, AC2, and
the P03 paragraph at `:1488`).

**The claim that the rename touches no executed check is true, and I proved it
rather than accepting it.** No `review/evidence/check-*.sh` script contains
`rs-launch-blueprint`, `rslbp` or `CARGO_BIN_EXE` at all (zero matches). The
three cited script logs contain `rs-launch-blueprint` only in their `repo:`
header path. Searching the whole evidence directory for the string with the
repository path excluded returns exactly two lines, both auditor-produced and
both exactly the ones the decision names: `audit-provenance-r4.log:111`, which
quotes the revision-4 `- owns` line, and `audit-six-locations-r5.log:219`, which
matches only through `rs-launch-blueprint-web`. So the decision's census of its
own evidence tree is exact, and leaving those two round-4 and round-5 artifacts
unedited is right — they were accurate for the revisions they bound.

**The owner record says what the decision says it says.** `docs/port/OWNER-REVIEW.md`
section *"2026-09-15 — R49 binary name: `rslbp` (W0-R49n)"* (`:107-119`) is quoted
in full and verbatim. The Wave 0 acceptances row at `:153` records revision 7 at
sha256 `319a5356…`, `accept`, 2026-09-15, *"W0-R49 option A; W0-R49n … re-bound
at revision 8"* — so the decision's statement that the acceptance re-binds at
revision 8 reports the controller's record rather than declaring it, and the
status paragraph's replacement of *"No owner acceptance is claimed or implied"*
is required rather than optional. That correction is disclosed as a fourth change
rather than made quietly.

**The audit-codex rerun is consistent with the decision.** `review/audit-codex.md`
(actor `audit-codex-2026-09-05T155504Z-2107cffb3ecf-r8`, model `gpt-5.6-terra`)
binds the same sha256 I bind, approves with no unresolved finding, reports exit 0
for both check scripts with empty normalized diffs, and independently reaches the
conclusions I reach on the revision scope (one changed path), the two-log stale
match, the byte-identical `- assumes` values, the R22 clause repair, the A4
ranking and Disagreement 6, and the three-level summary. I found no statement in
it that the decision contradicts, and no statement of mine that contradicts it.

**Two citation imprecisions, recorded because I found them and judged them, not
because they change anything.** Under Disagreement 6, doxa/openai is cited as
`:251` for the quoted phrase *"Cargo workspace split"*, which is at `:253`;
`:251` is that section's `### Ranked runner-up` heading. Every sibling citation in
the same sentence starts at the same heading and gives a range, so this is a
range with its end omitted, not a wrong line: the attribution is correct, the
quotation verbatim and the referent unambiguous. Likewise the opus condition is
cited `:525-531` where `:525` is blank and the quoted text begins at `:526`; the
range contains the quotation. Neither is a claim whose truth-value is wrong,
which is the class every finding in this chain has belonged to, so neither is a
finding.

## Findings

None. The three findings the round-7 judgment audit raised are closed, each by
the remedy it named:

- **F1 closed.** The `## Parameters` clause no longer hands R22
  `env!("CARGO_PKG_VERSION")`; it hands R22 the target directory layout and the
  target names, quotes R22's registering prompt line, and states where the
  version macro actually comes from. The prompt quotation checks out at the cited
  line.
- **F2 closed by the first remedy, both halves.** A4 is recorded as the ranked
  runner-up with its winning condition sourced to the opus raw's own
  `### Ranked runner-up` section, the trigger sentence names A4 instead of an
  antecedentless "the runner-up", and the three-way engine split is recorded as
  Disagreement 6 with each raw's proposal and line reference, all of which I
  verified against the raws.
- **F3 closed verbatim.** The sentence now reads *"at the capability,
  architectural-pattern and policy levels"* and adds the per-behavior mapping.

## Assessment

**The recommendation follows from the evidence, and revision 8 does not move
it.** Declaring every build target in `Cargo.toml` and adding no build backend,
bundler or orchestration crate is established by the structure of the field
rather than by engine agreement: only one of the three bins holds a candidate
that declares a target at all, and checks 2, 4 and A show Cargo's manifest
already expresses B1–B4. The sub-decisions that could have been taken from
agreement are still taken against a measured majority or against Cargo's own
general advice — the `include` allow-list against 7:2 practice, `autobins = false`
against the reference's "specialized situations" caveat — with the reason
carrying the weight, the confidence marked, the accepted failure mode named and
the reversal cost stated. The research-not-implementation boundary is kept:
nothing was scaffolded, built or published, AC1–AC6 are recorded as not executed
with the reason, and what P03 must validate is listed. That treatment is correct
for this programme and is not a defect.

The two things revision 8 does are both recording work, and both are done to the
standard this chain has been rejected for missing. The owner's ruling on the
binary name is an owner direction, so the moved value inside the owned parameter
is authorised rather than a departure; the decision implements it at every
enumerated location, keeps the crate, package, distribution and `[lib]` names
where the ruling leaves them, carries all four consequences it had itself
recorded for a divergent pair, and proves — rather than asserts — that no
executed check made any assertion about the name. It also separates what the
research established from what the owner decided instead of retro-fitting the
research to the ruling, which is why Disagreement 3 can record the majority's
*ground* as answered rather than overturned. The three clause repairs are each
made as their remedy specified, and the one correction beyond them, the stale
"no owner acceptance is claimed" sentence, is disclosed rather than fixed
silently. The two citation imprecisions I found are range-end omissions around
correct attributions of verbatim quotations, of a different class from anything
this item has been rejected for, and are recorded above rather than raised.

No unresolved finding remains. The verdict is **approve**.
