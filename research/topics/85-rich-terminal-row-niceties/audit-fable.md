decision-sha256: 1a81ae3a6979b937771efae63be83f8db1593ee3561225b3e748b432be13e983
actor: audit-fable-2026-09-06T043455Z-beb2d764c756-r1
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

The four principles are stated at levels the evidence supports, not at the level the
source happens to be implemented. P1 (decoration is additive and format-scoped) and P2
(per-model, defaulted opt-in) are `architectural pattern`; P3 (off-terminal the row is
plain) and P4 (data cannot forge markup) are `capability/standard` with the guarantee
required to agree and the mechanism free to vary. That split is the spec §2 table applied
correctly: P3's py mechanism is Rich's own stripper, which no Rust table crate has, so
binding the mechanism would have imported a py-specific implementation as a requirement.
Each principle cites a pinned source line at `b08bccfb` — ADR 0010 for P1 and P3,
`core/models.py:59-67` for P2, ADR 0010 plus `tests/core/test_format.py:59-61` for P4 —
so no verdict is assigned from memory.

The two amendments are the load-bearing part and both are justified rather than asserted.
Amendment 1 (the hook takes resolved capability as a parameter) rests on a mechanism
argument — `anstream::AutoStream` strips after the table crate has measured, giving right
bytes and wrong alignment — corroborated by three independent projects that all decide
before emitting. Amendment 2 (the hook lives in the CLI crate) departs from ADR 0010's
`core` placement on py's own later finding, HEX-15, and converts a documented rule into a
compile-time one. Neither amendment weakens a concrete requirement into a vague goal.

Ledger handling is correct. `F359` is this item's own row at `COMMONALITY.md:363`, verdict
`DIVERGENT`, and it does not appear in `BASELINE-REVIEW.md`, whose scope is `COMMON →
REUSE` and `ADOPT` rows. A `BASELINE-REVIEW:` line challenges a *retained* baseline;
there is none here, so declining Codex's line (Disagreement 3) is right, and the decision
gives that reason rather than silently dropping it. `## Parameters` records `owns` and
`consumes` both empty with no `CONFLICT:` line, which matches the prompt's `## Couplings`
block and the parameter registry: R66 owns no registered parameter, so there is no
registered value to conflict with.

## Design and evidence

**The one question that could overturn the pick, and the honesty of its split.** The Opus
raw named the table crate's treatment of a zero-width OSC-8 escape as the single
unmeasured property capable of overturning its own recommendation (`opus.md:666-667`, "V4
— DECIDING CHECK … the check that can overturn the recommendation in favour of A3"). The
decision settled it in source at pinned published versions, and settled it *conditionally*:
true through `measure_text_width` / `get_line_width` with `comfy-table`'s `custom_styling`
or `tabled`/`papergrid`'s `ansi`, false under either crate's default features, and
unsettled for `comfy-table`'s `ContentArrangement::Dynamic` allocator, which calls
`unicode_width` directly at `dynamic.rs:463,469,476,478` regardless of the feature. The
split is honest in the strict sense: the decision states what the reading establishes, says
twice that it did not trace whether the `Dynamic` heuristic changes final layout and does
not claim it does, and declines to attribute issue #137's residual header symptom to that
path even though the symptom is consistent with it. The disabled
`measure_text_width_osc8_test` is reported as a counter-signal with its `cfg` contradiction
explained, not explained away.

The recommendation remains sound with the open half, for three reasons the decision
supplies rather than assumes. First, the failure mode is bounded and named: A3 is retained
as the documented fallback for exactly three triggers (a third crate with no such feature,
`comfy-table` in `Dynamic` mode where the assertion fails, or any other failure of that
assertion). Second, the open half is ordered first in `## Engines` item 1, so it is the
first thing P03 runs and the cheapest place to learn the answer. Third, one of the two
candidate crates has no analogous bypass — `tabled` 0.22.0 makes no direct `unicode_width`
use at all — so the unsettled branch is one mode of one candidate, not the whole space. I
would add, as a reading rather than a correction: `ContentArrangement::Dynamic` is a
common choice for a terminal-width-fitting table, so that branch is not remote, which is
precisely why running the check first is the right ordering and why keeping A3 documented
is not ceremony.

**Architecture before libraries.** A1/A2/A3 are compared on six criteria before any crate
is named, and A2 is rejected on a principle test (it recreates the model-to-renderer
type-switching ADR 0010 rejected by name), not on convenience. Library selection follows
the same discipline: `anstyle-hyperlink` is selected because Cargo declares it at the exact
commit this machine's `cargo --version` reports, and the decision says outright that the
convergence of Cargo, ripgrep and eza on decide-then-emit — "not any download figure" — is
what selects the mechanism. Codex's landscape missing `anstyle-hyperlink` entirely is
recorded as incomplete on that point rather than dressed up as a competing view, which is
the correct treatment of a survey gap.

**Performance.** No performance figure is asserted anywhere, and the decision says so twice
and gives the reason: no published benchmark exists for any candidate and none was run.
The item is still decidable without one, because nothing in the argument turns on speed —
the selection criteria are principle preservation, compile-time enforceability, escape
safety and a source-read width property. The only quantitative statement, the 5/URL/2 and
7 byte counts of the OSC-8 tags, is a size fact read from `Hyperlink`'s `Display`, framed
explicitly as qualitative, and it does not carry any comparative weight. No implicit cost
claim substitutes for the missing measurement.

**The R66 requirement.** It is stated as an obligation on R66, not as an existing state.
`## Decision` item 5 is titled "A requirement on R66 that this item's empirical check
produced" and says R66 "selects the table crate; this item requires that whichever it
selects be built with that feature on"; `## Parameters` repeats it as "must select a table
crate with an ANSI-aware width feature, enabled"; `## Engines` item 1 tells P03 to confirm
the feature is on "because neither is on by default". Nowhere is the feature described as
already enabled or R66 as already decided. The instrument is right too: R66 registers no
parameter, so `CONFLICT:` — which exists for changing a *registered* value — does not
apply, and the decision says that explicitly instead of leaving the omission unexplained.

**The two off-forge candidates.** `chrono-humanize` (GitLab) and `osc8` (Codeberg) have
their GitHub-sourced figures recorded `inapplicable` with the reason, per the tier
guidance's "state `inapplicable` and the reason … do not omit it silently". This does not
hide a gap, because the raws answered the underlying questions by another route rather
than letting the missing figures stand in for an answer: `osc8` is excluded on **gate 2**
(no declared MSRV and no adopter to evidence a current-stable build), a gate that does not
need GitHub at all; `chrono-humanize` is investigated under the maintenance rubric and
recorded `stable-quiet` with its staleness noted, with the decision explicitly refusing
`at-risk` because the rubric demands a concrete signal and none was found
(`opus.md:302-310`). Both crates' crates.io figures and licenses were collected normally.
The missing figures are host-specific popularity and responsiveness for two candidates
that were declined on other grounds, and no conclusion rests on them.

**Fit for the template's reader.** The recommendation is close to the cheapest thing that
delivers the capability: one trait with a provided method whose default body is
`self.rows()`, so a view type with nothing to decorate carries no code, plus two small
crates in the CLI crate only. The complexity that would not serve a template reader — a
markup grammar, a stream-level stripper, a hand-rolled capability database — is declined
with reasons. The decision is also candid that the weakest half is relative time: py's
`relative_time` is wired into no result model, so string parity pins a test rather than
shipped behaviour, and the decision demotes its own confidence accordingly and names
`timeago` 0.6.1 as the runner-up that wins if the owner does not require parity. Framing
that as an owner question rather than a research gap is correct; the prompt asks whether a
maintained crate exists and does not mandate parity.

## Completeness

`DECISION.md` carries the RUNBOOK §5 H2s in order and outside fences — `## Decision` with
`### Principles and implementation` and a `re-verify:` line at line 211, `## Parameters`,
`## Empirical check` with toolchain, working directory, command and observed output, and
`## Engines` with both reports, all four disagreements and the evidence that resolved each.
`## Supersedes` is correctly absent: this is not a reversal.

Parameters: all four fixed values are present with the registry's exact wording, and the
decision does more than restate them — it says how each bears on the recommendation,
including the one that actually bites, `supports-hyperlinks` being `Apache-2.0` only, whose
consequence (a downstream consumer of the binary cannot take the MIT arm; a `cargo-deny`
allowlist must include `Apache-2.0`) is stated with Cargo's own acceptance of the same
constraint as precedent. The four `assumes` lines were regenerated from
`docs/port/PARAMETERS.md` by script and byte-compared, exit 0.

Fitness gates: license, MSRV, advisories with `unsafe` posture, OS coverage, default
features and async coupling, and qualitative size/compile cost are all present for the two
recommended crates, and the raws record gate outcomes for every excluded candidate,
including the uniform rule applied to the four crates with no declared `rust-version`. The
`unsafe` disclosure — two `libc` FFI calls at `src/hostname.rs:35,53`, reachable only
through the `file` feature this decision enables — is consistent with R06's resolved
policy, which forbids `unsafe` in first-party code only and states that Cargo's
`--cap-lints allow` means the template makes no claim about its dependency tree. No
conflict with R06 arises and none needed recording.

Source dates: every figure carries an endpoint and a retrieval date, drift-prone JSON is
snapshotted under `snap/`, tarballs are sha256-pinned, and repository reads go through the
programme pins. `## Empirical check` ends with an explicit "what was not verified" list —
no Rust compiled, `shell.rs`/ripgrep/eza line numbers carried at HEAD rather than re-pinned,
responsiveness medians not re-queried — which is the right shape for a research-phase
decision.

Research-phase discipline: the decision does not implement its own recommendation, and
correctly should not. Its acceptance criteria are labelled "all *proposed*; none was run,
because the template does not exist yet", and `## Engines` lists six things P03 must
validate with the deciding one first. Nothing here is faulted for that.

Rerun consistency: `audit-codex.md` reviews this exact sha256, reran `r85-claims.sh` to a
byte-identical log at exit 0, and its five verified findings each attach to a claim this
decision actually makes — the conditional width result, the `Dynamic` exception, the
`cfg`-contradictory test, R66 as a dependency rather than a completed state, and the
absence of any performance figure. Its one recorded limitation, that the Linux leg could
not run because the sandbox blocked the Lima VM's write to `~/.lima/ubuntu/ha.stdout.log`,
does not touch the source-reading check, which is platform-independent. The empirical
audit is consistent with the decision.

## Findings

1. **The A3 comparison is inaccurate in both directions, and the two errors offset —
   resolved here, no change required.** The A3 column charges the runner-up with "every
   view type is rewritten onto `Cell` even when it decorates nothing", and Disagreement 1
   repeats it as A1 preserving "the defaulted opt-in without rewriting every view type".
   That cost follows from the decision's own formulation of A3 (`fn cells()` replacing
   `rows()`) but not from Codex's, which is `codex.md:61`: "a `TableRows` trait whose
   `text_rows()` default maps `plain_rows()` to `TextCell::Plain`, with opt-in `Link` and
   `RelativeTime` variants". Under that spelling a non-decorating view type writes no code
   at all and P2 is preserved exactly as well as under A1, so the stated cost overstates
   A3. The opposite error sits one row above: A3's "Depends on the table crate discounting
   OSC-8: **No**" is true as written but omits that A3 has a *different* table-crate
   dependency, stated in Codex's own runner-up condition (`codex.md:93`) — its primary
   shape needs a crate that "can accept typed cells or provide a final-cell emission hook
   after width calculation", because the escape must be applied after the crate has
   measured or the width problem simply returns. That is a harder property to obtain from
   `comfy-table` or `tabled` than turning on a feature flag. Correcting both, A1 still
   wins, and wins more clearly than the decision's own argument makes out: the accurate
   trade is a non-default feature flag plus one unsettled arrangement mode (A1) against a
   two-phase layout-then-emit API that neither candidate crate obviously exposes (A3). I
   record the corrected comparison here so a P03 reader taking the documented fallback
   knows the real condition it must satisfy. This is a finding resolved within this audit,
   not an unresolved one: the conclusion is unchanged, the correcting evidence is already
   in the run's own raw report, and the re-verify trigger fires when R66 publishes, which
   is when this comparison is re-examined against a real crate anyway.

No unresolved finding. Nothing in the decision claims more than its evidence establishes,
and the two places where a claim could have been stretched — the `Dynamic` bypass and the
historical failure of `measure_text_width_osc8_test` — are both explicitly left unclaimed.

## Assessment

Approve. The recommendation is sound and the reasoning supports it. The decision settles
the one question its own research named as capable of overturning it, settles it in source
at pinned versions, and is candid that it settled only part of it — carrying the remainder
as a named requirement on R66, a documented fallback architecture, and P03's first check.
That is the correct handling of a partially settled question, not a deficiency. It asserts
no performance figure and needs none, because nothing in the argument turns on cost. It
places its dependency on R66 as an obligation R66 must honour and never as an accomplished
fact. Its `inapplicable` figures for the two off-forge candidates are accompanied by
answers reached another way, so nothing is hidden. And the pattern it recommends costs a
template reader nothing for view types that decorate nothing, which is the property that
made py's hook worth porting in the first place.

**One controller action, outside this decision and not a defect in it.** The requirements
this decision places on its two related items are not yet visible in those items' inputs.
`research/topics/66-output-format-surface/prompts/output-format-surface.prompt.md:26` still
reads "R85 needs no registered parameter from this item, only its text-format row shape as
a starting point" — true for parameters, now incomplete for requirements, since R66's
table-crate selection must weigh ANSI-width feature support and its arrangement mode.
R65's prompt mentions R85 nowhere, yet this decision hands R65 two inputs: a readable
"this stream will accept escape codes" signal, and `FORCE_HYPERLINK`, which
`supports-hyperlinks` honours independently of `NO_COLOR`/`FORCE_COLOR`. `DECISION.md`
states both requirements plainly and can do no more from inside this item; annotating both
prompts before those items are admitted is the controller's step, and without it the
requirements can be missed silently.
