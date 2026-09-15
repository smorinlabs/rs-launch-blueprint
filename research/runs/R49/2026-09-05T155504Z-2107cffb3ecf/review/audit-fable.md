decision-sha256: 319a535665318a120c9be3bdf61037f9f4ea8214d972de724dafe16902bec41d
actor: audit-fable-2026-09-05T155504Z-2107cffb3ecf-r7
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: F1 — `## Parameters` at `:882-883` claims R22 takes `env!("CARGO_PKG_VERSION")` "from the owned parameter above", a value the owned parameter does not carry and this item does not decide, contradicting the same decision's correct statement at `:560-562` that R22 reads the target directory layout; F2 — `### Principles and implementation` records no ranked runner-up, yet the re-verify trigger at `:842` refers to "the runner-up" with no antecedent, and the five raws name three different runner-ups (workspace split, `dist`, auto-discovery), so the reference has no determinate referent and the disagreement is absent from `## Engines`; F3 — the agreement-level summary at `:593` says agreement is required at the "capability and policy" level, naming two of the three levels its own B1-B4 table assigns, since B2 is labelled architectural pattern

## Principle and agreement level

The shared requirement is stated with its source and read at the programme pins.
F211 (`docs/port/COMMONALITY.md:215`, `COMMON → REUSE`) is the tool-free pattern
and F212 (`:216`, `COMMON → SUBSTITUTE`, owned by this item) is the tool row
under it; I read both lines and the decision quotes `:216` verbatim
(*"Cargo is Rust's native build system with no separate backend/bundler crate
needed"*). The F017 quotation at `COMMONALITY.md:23` is likewise verbatim.

The decomposition into four behaviors B1–B4 with a per-behavior agreement level
(B1 capability, B2 architectural pattern, B3 policy, B4 policy) matches the
three-level table in the spec's §2 governing rule, and each behavior carries py
and ts evidence read through `git show` at the pins `b08bccfb…` and `cb1cbcb2…`
rather than from a working tree (check 5, log
`review/evidence/source-pins.log`). §2's instruction that a shared architectural
pattern be fitness-tested in the target ecosystem is discharged explicitly:
*"B1, B2 and B4 do, unchanged. B3 survives but its mechanism collapses"*, with
the collapse argued from Cargo's own target reference — a `[[bin]]` `name` is
the output filename, so py's callable-reference wrapper and ts's shebang-bearing
built-file path have no Rust referent, which is why F217 (`OMIT`) is confirmed
rather than replaced.

The summary sentence that names the required level is nonetheless narrower than
the table it summarizes, and that is **F3** below.

`BASELINE-REVIEW:` handling is what `research/RUNBOOK.md` §4 requires: the
controller adjudicates such findings, and the decision carries both of them
unresolved in the prescribed
`F### — principle — proposed change — evidence` shape with affected items named,
stating that neither the ledger, index, prompt nor registry was edited. I
confirmed the provenance it claims: `raw/codex….md` raised F218 and
`raw/opus….md` raised F212, doxa/openai independently raised the same two
identifiers and no other, and no raw raised a third — so the carried set is
complete. `docs/port/BASELINE-REVIEW.md:102` classifies parent F211 `retained`,
which the decision does not disturb. The `CONFLICT:` position is correct: the
prompt's `- consumes:` line is empty, no raw raised one, and the decision says so
rather than leaving the reader to infer absence.

## Design and evidence

**The target matrix is argued from principles and against agreement, not from
it.** This is the test the item exists to pass, and on the three sub-decisions
where practice or the engines lean the other way the decision goes its own way
with a stated reason:

- `include` allow-list — decided **against** a measured 7:2 practice majority for
  `exclude` (check 7). Three grounds carry it: B4 fidelity (an allow-list is the
  literal form of the behavior ts encodes as `files: ["dist"]`), a difference in
  repository shape (the seven `exclude` users prune large asset trees; this
  template's non-shipping list grows while its shipping list does not), and the
  fail-open direction — under `exclude` or the default, a committed `.github/`,
  `docs/` or `research/` reaches every consumer, which is the F218 finding. The
  accepted failure mode is named plainly, bounded by check 4's verification
  rebuild for compile-time inputs, and the `include`-specific footgun (gitignore
  rules stop applying) is recorded from check A. Confidence is marked medium and
  the reversal cost is stated. This is the opposite of selection by agreement.
- names matching — decided **against** the 5-of-9 divergence rate, on a
  template-specific ground (a placeholder every fork replaces; a value carrying
  an open owner naming call cannot be published), with check 8 establishing that
  divergence costs no install-time flag in either direction, so the choice is not
  dressed up as a Cargo constraint. Both engine-proposed names (`rslbp`, `rsbp`)
  are correctly identified as naming proposals and declined.
- `autobins = false` — stated honestly as *"a policy choice rather than as
  documented advice"*, acknowledging that Cargo's reference calls disabling
  discovery a specialized need, and the asymmetry against `build = false` is
  argued from this item's own subject (an unreviewed `src/bin/*.rs` becomes a
  published, installed command; an accidental `build.rs` does not).

`[lib]` plus exactly one `[[bin]]` follows from B2 but is chosen among four
costed architectural alternatives with maintained reference implementations —
A1 mdBook (22,127 stars), A3 atuin (31,579) and typos (4,125), A2's cost being
the `required-features` skip verified in check 3, A4's being a third-party
dependency for a decision that is R68's plus `dist`'s documented pull toward a
second configuration file (check 10, read at the `v0.32.0` tag and refined from
the raw's "deprecated" to "deprecated but still supported"). A1 is selected and
the selection is shown to be shape-neutral to R02 and R69. The coupling
boundaries to R68 (F214), R50 (F221/F222), R26 (F039/F078), R69 and R82 are
respected, and check 3's verified fact is handed to R69 as input rather than
used to pre-empt it.

**MSRV.** `rust-version` in `[package]` is the mechanism the fixed `msrv-policy`
parameter names, so there is no alternative to compare — the policy is
owner-fixed and binding. The decision computes "stable minus 2 minor versions"
against the recorded `rustc 1.98.0` as **1.96**, which is arithmetically right,
and it keeps that number as a value computed at a date rather than baking it into
the owned parameter, because it moves every six weeks. That is why doxa/openai's
literal `rust-version = "1.96"` is correctly not adopted. The floor is consistent
with `edition = "2024"` (Rust 1.85.0 or newer), and gate 2's statement that the
recommended manifest *fields* impose no floor above the edition is true as
written and does not conflict with the declared 1.96.

**The lockfile condition (press point 2) is established exactly, and claimed
exactly.** I read `review/evidence/lockfile-inclusion-conditions.log` line by
line. It carries 13 content assertions and `RESULT all assertions passed`,
matching the figure the decision cites. The condition is proved in both
directions: `manifest.md@rust-1.98.0` scopes *"A minimized `Cargo.lock` is
automatically included"* to the `include`/`exclude` list, so no manifest field
can drop it; `cargo-package.md@rust-1.98.0` and the installed cargo's own
`--help` show `--exclude-lockfile` present and un-`-Z`-gated; `package.rs:89`
maps the flag to `include_lockfile`, `mod.rs:513/559/561` drop and re-add the
entry and generate an absent lockfile, `publish.rs:171` hardcodes
`include_lockfile: true`, and `cargo publish --help` yields 0 matching lines
asserted as an absence. The word *only* is discharged exhaustively rather than by
sampling: the whole tag tarball is searched, `include_lockfile` appears in
exactly three files and is assigned in exactly two, both sets asserted as exact
string equality. Three negative controls exit 1, so the check fails in both
directions. The decision's row-5 sentence, the owned parameter and AC3 claim
precisely this and no more, and defer the full statement to check L by reference.
The claim is scoped to cargo 1.98.0 by `## Empirical check` and governed by the
re-verify triggers; I do not fault the row for not repeating the version.

**Census discipline (press point 4).** I spot-checked three counts against their
logs and each is the recorded output of the named command, with the produced
lines shown rather than summarized. (1) Check 7's tallies —
`exclude` 7 of 9, `include` 2 of 9, Cargo default 0 of 9, explicit `[[bin]]` 7 of
9, explicit `[lib]` 2 of 9, name divergence 5 of 9 — all reproduce from
`practice-manifests.log`, including the per-project matched lines, the `[lib]`
block dump and a correction the author recorded rather than quietly fixed (the
first pass grepped only `crates/typos-cli/Cargo.toml` and would have contradicted
the Opus raw; the workspace root showed the allow-list is inherited). (2) Check
L's 13 assertions and the three-file / two-assignment enumeration, above. (3)
Check 6's one load-bearing figure, `cargo-make`'s absent `rust_version`, appears
in `registry-figures.log` as `rust_version field: None` on the newest non-yanked
0.37.24, and the decision's whole table reproduces that log row for row. Check
9's derived figures (logins 26/6 beside dependabot 63; 6 of 10 answered, median
0.190 days; 297 open issues from the search endpoint, as the prompt requires, not
`open_issues_count`) likewise reproduce. Where a source is live rather than
pinned — the nine default-branch manifests — the decision dates the fetch and the
log snapshots the matched lines, and byte-for-byte reproducibility is claimed
only for the three scripted artifacts where it was demonstrated. That
distinction is drawn correctly.

The licence apparatus is history, not ground. I checked every place a licence
fact appears and none functions as a ground for the recommendation: gate 1 is
`inapplicable` with the owner's 2026-09-12 (Q7.B) ruling named, `cargo-binstall`
is excluded by scope alone with the gate-1 half explicitly voided, check 6's
`license` column is stated as measured metadata *"evaluated against no gate"*,
and the Engines line records the Opus raw's two grounds while adopting only the
scope one. I read `raw/opus….md:353-356` and `:359-362` directly; both
quotations are verbatim and both line ranges are accurate.

`## Engines` names one line per raw with retrieval dates, and I verified the
vote counts against the raws rather than against the decision's summary of them.
Disagreement 2 (`include`: codex, doxa/openai, doxa/gemini; `exclude`: opus;
neither: doxa/perplexity), Disagreement 3 (match: codex, doxa/openai,
doxa/perplexity; diverge: opus `rslbp`, doxa/gemini `rsbp`) and Disagreement 4
(second `[[bin]]` now: doxa/perplexity, doxa/gemini; not now: codex, opus,
doxa/openai — doxa/openai's `rs-launch-blueprint-web` block being conditional on
R69) each match the raws exactly.

The programme's research-not-implementation boundary is kept: nothing was
scaffolded, built or published, the only `cargo package`/`cargo publish`
invocations were `--help` printings, AC1–AC6 are marked as not executed with the
reason, and what P03 must validate is listed. No latency, throughput,
binary-size or compile-time figure is asserted anywhere, and the absence is
recorded as an evidence gap rather than filled.

## Completeness

Present and correct: the four H2 sections in order with no others and no
`## Supersedes`; the recommendation (correctly *absent* rather than a crate and
version range, with the reason); the ledger rows settled (F212, F213, F216,
F218, F219, with F217 confirmed); the `### Principles and implementation` H3
carrying shared requirement, source, agreement level, essential behaviors,
must-agree versus may-vary, architectural alternatives, reference
implementations and acceptance criteria; the final line
`re-verify: 2027-03-10, or any earlier event listed immediately above`; all six
fitness gates answered before any popularity figure, each `inapplicable` one
carrying its reason; every prompt question answered; toolchain, working
directory, commands, observed output and evidence log paths in
`## Empirical check`; retrieval dates on the live sources and pinned tags or
commits on the rest.

Parameter lines: I extracted the text after `= ` on each of the four `- assumes`
lines and compared it against `docs/port/PARAMETERS.md` rows 7–10. All four are
byte-identical, with no backticks, citations or commentary on the value lines.
The owned `build-tool-output-shape` registry cell is still `—`, so there is
nothing yet to compare it against; the line's format matches the same rule.

The `audit-codex.md` rerun binds the same sha256 I bind, reports exit 0 in both
modes and exit 1 under the recorded mutation, and its narrative agrees with the
decision: seven pattern/blob pairs, 13 and 11 content assertions, eight `SKIP`
lines, the byte-identical `PAT_ID_FULL`, the reproduced 40 / 5 / 10 / 33 lists
and `582 605 606 608 609 611`, and the byte-identical `- owns`/`- assumes` lines.
I found no statement in it that the decision contradicts.

Not present, and the two findings below turn on it: no ranked runner-up, and one
downstream-facing consumption line that states a value the owned parameter does
not carry.

## Findings

**F1 — `## Parameters` hands R22 a value the owned parameter does not contain,
and omits the one it does.** `review/DECISION.md:882-883` reads *"Consuming
items get concrete values from the owned parameter above. R22
(`runtime-version-accessor`) reads `env!("CARGO_PKG_VERSION")`"*. That macro
appears nowhere in the owned parameter at `:852`; it derives from the
`[package] version` field, which this item does not decide. What R22's own
prompt registers as consuming is *"what the binary/library targets are called,
where `cargo build` places them"*
(`research/topics/22-runtime-version-accessor/prompts/runtime-version-accessor.prompt.md:18`),
and the owned parameter does supply exactly that — library crate name
`rs_launch_blueprint`, binary name `rs-launch-blueprint`, artifacts under
`target/debug/` and `target/release/`. So the sentence's claim is false for the
one item of the three where it matters: the parallel clauses for R32
(`env!("CARGO_BIN_EXE_rs-launch-blueprint")`) and R68
(`target/release/rs-launch-blueprint`) are both drawn from the owned parameter
and are correct. The decision already states R22's consumption correctly
elsewhere — `:560-562` reads *"the target directory layout in `## Parameters` is
the input R22's version accessor reads"*, which is exactly what R22's prompt
registers — so `:882-883` contradicts `:560-562` rather than merely being loose.
Remedy: make `:882` say what `:560` says.

**F2 — the decision records no ranked runner-up, then refers to "the runner-up"
as though it had.** The phrase occurs exactly once, at `:842`: *"R68 resolves
F214 to cross-compiled release binaries, which is the condition under which the
runner-up wins…"*. The four architectural alternatives at `:710-731` are costed
but never ranked, and `**A1 is selected**` is the only ordering statement in the
document; no other line in the file names a second choice. The referent is not
recoverable from the raws either, because they disagree about it: three of five
name the workspace split (doxa/openai `:251`, doxa/perplexity `:170-174`,
doxa/gemini `:92-96`), opus names `dist` 0.32.x (`:521-525`), and codex names
Cargo automatic target discovery (`:79-82`). Reading `dist` in the same clause
points at A4, which is opus's minority answer, while the decision routes the
majority's workspace split through a *different* trigger on the same line
(*"R02 resolves to a workspace"*) — so the sentence silently adopts one engine's
ranking without saying so. This also leaves a real engine disagreement out of
`## Engines`, which must record the disagreements and what settled each; five
are recorded and this sixth is not. The substance of each proposed runner-up is
engaged elsewhere (A3's cost is that it pre-empts R02; auto-discovery is the
`autobins = false` argument; A4 is costed with check 10), so this is a recording
defect, not a gap in the analysis. Remedy, either way and one clause long: name
the runner-up and its winning condition explicitly, or state that none is
recorded because the field is a dominant choice and restate the trigger without
the phrase.

**F3 — the agreement-level summary names two of the three levels its own table
assigns.** `:593` reads *"Agreement is required at the **capability and policy**
level, not at the level of sharing a backend library"*, but the B1–B4 table
immediately below assigns B2 (*"The consumable library and the executable are
declared as separate, named outputs"*) the level **architectural pattern**, which
the spec's §2 table defines as a distinct level with its own fitness obligation.
The per-behavior assignments in the table are correct and the fitness test §2
demands for a shared architectural pattern is carried out at `:609`, so no
analysis is missing; the summary sentence simply states less than the table
beside it. That is the same defect class as F1 — a sentence narrower than the
correct statement next to it — and this audit applies the standard evenly rather
than exempting it because the table carries the binding value. Remedy, one
clause: *"at the capability, architectural-pattern and policy levels"*.

## Assessment

**The recommendation itself follows from the evidence, and neither finding moves
it.** Declaring every build target in `Cargo.toml` and adding no build backend,
bundler or orchestration crate is established by the structure of the field
rather than by engine agreement: only one of the three bins contains a candidate
that declares a target at all, and checks 2, 4 and A show Cargo's manifest
already expresses B1–B4. The three sub-decisions that could have been taken from
agreement — the allow-list, the matching names, `autobins = false` — are each
taken *against* a measured majority or against Cargo's own general advice, with
the reason carrying the weight, the confidence marked, the accepted failure mode
named and the reversal cost stated. The MSRV treatment is the owner-fixed policy
expressed through the one field Cargo provides, computed rather than baked. The
lockfile condition is proved at the pinned toolchain in both directions and
claimed at exactly its proved width. The three counts I spot-checked reproduce
from their logs, and where a source is live the decision says so instead of
claiming a reproducibility it did not demonstrate.

Both findings sit in the recording layer around that conclusion: one line tells a
downstream item it receives something the owned parameter does not carry, and one
line invokes a ranked runner-up the document never ranks while the raws rank
three different ones. Neither touches the recommendation, the owned or assumed
parameter values, the gates, the empirical checks or the two carried
`BASELINE-REVIEW:` lines, and each is repairable in a single clause without
re-running anything. The role contract admits no partial verdict —
`approve` requires no unresolved findings — so the verdict is **reject**, with
the expectation that revision 8 changes two sentences and nothing else.
