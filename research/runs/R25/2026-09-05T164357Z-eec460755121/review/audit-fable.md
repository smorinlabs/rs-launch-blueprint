decision-sha256: 978ec7075e1f33f9f186815ea2a2154a52ad52eb53b970aebe1a38ed69def4e8
actor: audit-fable-2026-09-05T164357Z-eec460755121-r7
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

Unchanged from revision 6 and re-checked, not inherited. The shared requirement is stated as a
requirement on the *output* — the published version number must tell the consuming resolver the
truth about compatibility in both directions — not on a flag or a tool, and its source is named as
ledger rows F063, F066 and F073 plus the ts instantiation D-021(1) from the pinned clone `cb1cbcb2`.

The agreement level, **capability / standard**, is argued rather than asserted: what must agree is
an automated bumper correct under the host ecosystem's own compatibility rule; what may vary is the
flag setting, because each ecosystem's rule is its own. I confirmed the harder half of the A5 test
myself. The decision recommends the same low-level value ts uses while deriving it from Cargo's own
documented convention (`semver.html`, `specifying-dependencies.html`, quoted verbatim with retrieval
dates) and from release-plz, an independently built Rust-native tool that ships the same policy as
its default and labels the contrary setting a Cargo SemVer violation. Same value, independent
derivation.

The three-repository reconciliation remains genuine analysis: py's absence of the flags is diagnosed
as *inherited state* — py adopted release-please already at `1.0.0` (commit `1bd0344`, pinned clone
`b08bccf`) and every branch the flags guard is gated on `Version.isPreMajor`, i.e. `major < 1` — so
adding them would change nothing. That distinguishes justified ecosystem difference from accidental
drift. The decision correctly declines to reclassify F070 and correctly declines to edit the ledger.

## Design and evidence

**The count correction is complete and correct. I read the three raw files myself rather than
accepting the decision's tally or the empirical audit's rerun.** `grep -Rn` over `raw/` returns
`BASELINE-REVIEW` in five report files. Exactly three emit a finding:

- `raw/doxa-openai.normalized.md:82` — `**BASELINE-REVIEW: F070 — resolver-aligned impact tiers …**`
- `raw/doxa-gemini.normalized.md:29` — `**BASELINE-REVIEW: F066, F073 — Release tool orchestration — Replace `release-please` with `release-plz`**`
- `raw/doxa-perplexity.normalized.md:71` — `> BASELINE-REVIEW: F070 — pre-1.0 semver dampening — reclassify as a common architectural pattern …`

The perplexity line is a blockquote rather than a bold heading, which is why a heading-anchored
pattern misses it and why the defect survived six rounds. The other hits are not emissions:
`raw/codex.md:26` and `raw/opus.md:124` carry the token only in the negative; `raw/opus.md:192` and
`:389` name the file `docs/port/BASELINE-REVIEW.md`, which has no trailing colon; and
`raw/doxa-gemini.normalized.md:53`, `:75` and `:99` are that report's own back-references to its one
proposal. So the emitting set is exactly the three the decision now names, and the three-item tally
is right.

All four edits the previous finding asked for landed. `:400-403` (was `:351-352`) now reads *"Three
raw reports did emit"* and names all three locations with their `## Engines` items 5, 4 and 7;
`:925` (was `:852`) and `:968` (was `:895`) read *"the three recorded-but-not-adopted"*; and
`## Engines` item 7 now opens with doxa-perplexity's `BASELINE-REVIEW:` line quoted and closes
*"This is the third of the three emitted `BASELINE-REVIEW:` lines, with items 4 and 5."* The three
items are now countable against the raws, which is what runbook §4 needs of the controller.

**The bootstrap-sha routing question is answered.** I asked the controller to consider naming the
ledger row that owns the pin itself, where revisions 1-6 routed the whole question to F066/R24.
Revision 7 names **F071** *release-please bootstrap-sha pin* at both routing locations — the
implementation note at `:539-543` and unproven item 5 at `:1126-1130` — and splits the two
questions correctly: the pin is F071's, the first changelog's contents are F066/R24's, neither is
R25's. I read `docs/port/COMMONALITY.md:77` directly: `| F071 | release-please bootstrap-sha pin |
release-versioning | py-only | ADOPT | — | mechanical: pin the commit release-please starts scanning
from when first configured |`. The line number, the verdict, the absent research item and the quoted
cell all match. P03's inheritance is now unambiguous.

**Revision 7's own new prose is accurate**, which matters because six rejections found defects in
exactly that class. I reconstructed revision 6 from commit `263ac5ee` and checked its claims
mechanically. `grep -n BASELINE-REVIEW` over revision 6 returns exactly six lines at `:349`, `:352`,
`:852`, `:895`, `:980` and `:989` — precisely the six the preamble reports. The diff is nine hunks
and every one is disclosed: the revision heading, the revision-7 preamble, the three corrected
counts, the item-7 label, the appended evidence record, and the F071 clarification at its two
locations. No undisclosed content changed. The appended evidence block exists at
`review/evidence/release-please-source-v17.11.2.log:497` under the banner it names, with the three
cited locations at `:527-529`. The preamble is also candid about its own method's limits: it states
that neither pattern could reach item 7, because the defect there was the *absence* of a token, and
that the label was found by walking each `## Engines` item against the raws instead.

**The recommendation is right, and it is right independently of the seven rounds.** I re-derived it
rather than endorsing it. Cargo resolves a bare `0.1` requirement as `>=0.1.0, <0.2.0`, so under
`0.y.z` the `y` digit is the incompatibility boundary and `z` is the compatible one; the required
mapping is therefore breaking → `y`, feature → `z`, fix → `z`. Read at the pin,
`bump-minor-pre-major` governs *breaking* changes (*"Breaking changes only bump semver minor if
version < 1.0.0"*) and `bump-patch-for-minor-pre-major` governs *feature* changes (*"Feature changes
only bump semver patch if version < 1.0.0"*), while `fix` always moves the patch digit. Only both
flags `true` produces the required mapping, and the 36-cell executed matrix shows no other
combination does. The two failure modes are concrete: under (C)/(E) the first breaking change
silently promotes the crate to `1.0.0` — an irreversible stability claim made by a bot — and under
(C)/(D) a compatible feature release is withheld behind `0.(y+1).0`, forcing a manifest edit across
every consumer for no reason. The library shape correctly governs, because a published crate's
version is a promise to code the maintainer will never see, and C-STABLE denies a `>=1.0.0` claim to
a crate whose public dependencies are themselves pre-1.0 — which the template's likely surface is,
and which R53, R55, R58, R67 and R69 have not yet settled. The runner-up (B) is correctly kept as a
runner-up rather than a rejected option: above `1.0.0` its arithmetic is identical, so its whole
cost is a day-one claim about code that does not exist, and the graduation path back to it is one
documented commit footer. I agree with the recommendation on this reasoning, not on the engines'
agreement.

Selection follows from evidence rather than convergence. All five engines reached the same outcome
and the decision says so, then refuses to treat the convergence as the argument: options A-E are
separated by an executed matrix, and the flag semantics are established from the pinned schema, the
maintainers' prose and `DefaultVersioningStrategy` before the probe reproduces them. Architecture
alternatives were compared before any flag was chosen and they are real alternatives; alternative 3
is correctly ruled out of scope for adoption by F063/F066/F073 and the prompt's `## Out of scope`
while its *policy* is admitted as evidence and its checker proposed — explicitly proposed, not
decided — as a CI gate whose placement belongs to R11.

**The unproven items remain genuinely unproven and each names its proof.** Item 1 names the command,
the commit sequence, the batching it depends on and the expected outputs. Item 2 names the first
Release PR and the specific precondition P03 must check, and separates the released number from
reaching crates.io, which it claims nowhere. Item 3 labels the RustSec position an interpretation of
an HTTP 404 rather than an affirmative clearance. Item 6 records issue responsiveness as not
measured and not estimated. None is a conclusion dressed as a gap, and the decision implements
nothing it recommends — the end-to-end dry run is correctly declined as implementation rather than
research.

## Completeness

`## Decision`, `### Principles and implementation`, `re-verify:`, `## Parameters`, `## Empirical
check` and `## Engines` are present in the runbook's order; `## Supersedes` is correctly absent.

Parameters, checked against the sources rather than the previous audit. I opened `inputs/prompt.md`:
its `## Couplings` `- owns:` line is empty and `- consumes:` is empty, and `research/CLAUDE.md`
records `—` for R25 — so `- owns: none` is right and no `CONFLICT:` line is required. The four
`- assumes` lines carry bare values; I compared each against `docs/port/PARAMETERS.md` rows 7-10 and
all four match the registry text character for character.

Fitness gates: all six recorded as `inapplicable` with a per-gate reason rather than omitted, which
is what the tier guidance requires for a pattern item, and the reasons hold — adopting a JSON boolean
adds no crate to the tree. The one tool the decision *proposes* is flagged as not gated and not
executed on either required runner, and that is carried into the unproven list rather than left in
the gates section.

`BASELINE-REVIEW:` handling is now correct and complete. I confirmed the underlying classification
independently: F070 does not appear in `docs/port/BASELINE-REVIEW.md` at all, so the decision is
right that there is no retained baseline for it to challenge and right to emit no line of its own.
F066 and F073 *are* retained rows there (`:55`, `:60`), so doxa-gemini's proposal genuinely is a
baseline challenge — correctly recorded, correctly not adopted as outside R25's authority, and
correctly left to the controller, who adjudicates such findings under runbook `:167`. No raw proposal
was silently adopted, no other item was touched, and the ledger was not edited.

The revision-7 codex rerun is consistent with the decision: it records the same digest I computed,
the same three emitting locations, the same nine-hunk accounting, and identical block digests for
every protected region. It ran on macOS only, because Lima could not start the `ubuntu` VM; that is
immaterial here, because revision 7's only new check is a grep over static files already inside this
run directory, which is platform-independent and reproducible byte-for-byte.

## Findings

No unresolved findings. Two observations follow, both **non-blocking** and neither a defect in the
recommendation, the evidence or the parameters. Acting on either changes the digest and makes a
revision 8 by the runbook's own logic, which is not warranted on their own account.

1. **A counting sentence the revision-7 sweep could not reach: `25` where the parallel sentence says
   `28`.** `:101` states *"every one of the **28** locations carries the word `override` in its
   governing sentence"*; `## Engines` item 2 at `:822` states *"Every one of the **25** locations
   carries the word `override` in its governing sentence"*. The `28` is right: I checked the three
   block-level locations the second pass added and all three carry the marker — architecture
   alternative 1 (*"except where a version override displaces it"*), the graduation clause in *What
   (A) gives up* (*"graduation is one override commit footer away"*), and revision 4's changelog item
   3 (*"omitting the version override that precedes the history entirely"*). So `:822` is a true but
   narrower subset claim, not a false one, and it misdirects no re-run: an auditor sweeping by either
   number finds no unmarked location. It is recorded here because it is the exact class my
   predecessor asked the seventh round to sweep — counting sentences against the artifacts they count
   — and revision 7's pattern 2 was restricted to a counting word standing before *raw*, *report*,
   *engine* or *doxa*, which cannot reach *"the 25 locations"*. Both sentences predate revision 7 and
   survived three empirical audits. Fix, if a revision 8 is cut for any other reason: `25` → `28` at
   `:822`.

2. **Where the revision history lives has drifted forward into `## Decision`.** The revision-5, -6
   and -7 changelogs now occupy `:14-118`, so the recommendation table sits at `:120` rather than in
   the first screen, and revision 5's changelog appears twice — abridged at `:78-118` and in full at
   `## Engines` `:785-846`. The two copies agree; this is placement, not contradiction. The concern
   is the trend: `## Engines` is where the runbook keeps the revision record and where revisions 1-4
   correctly sit, and each further round now adds roughly fifty lines above the recommendation. Fix,
   again only if a revision 8 is cut: move the revision-5/6/7 changelogs into `## Engines` alongside
   the others, so `## Decision` opens on the status paragraph and the recommendation table.

Carried forward for the controller, not a defect in this document and stated once: doxa-gemini's
`BASELINE-REVIEW: F066, F073` challenge is still a live adjudication under runbook `:167`. Revision 7
correctly declined to act on it. It is the one thing that can be lost between rounds.

## Assessment

Approve. The correction is complete, the correction's own prose is accurate, and the document is
coherent enough to implement from.

**On coherence, which is what seven revisions puts at risk.** I read the document as an implementer
and traced the path an implementer actually walks: the status paragraph says nothing was built; the
recommendation table gives three artifacts and three exact values; **Override precedence** states the
one mechanism that outranks every version outcome, once and in full, with pinned line numbers; the
bump table gives per-commit-type outcomes; A0-A4 state the acceptance criteria with their status;
the implementation note carries the bootstrap-sha pin and its owning row; `re-verify:` names the
trigger; the unproven list says what P03 must prove. That path is complete and nothing in it is
ambiguous. Crucially, the caveating has not eaten the answer: the three recommended values are
stated flatly, and the thing that can displace them is a deliberate human act — a mechanism of the
recommended tool, not a hedge about it — carried in one place and referenced elsewhere by a single
consistent marker word. A reader can act on this.

The cost of seven rounds is real but it is concentrated in one place and it is placement, not
substance: 105 lines of audit meta-history now stand between the section heading and the
recommendation. That is observation 2, and it is worth fixing the next time the file is opened for
any other reason — not worth opening the file for.

**On the recommendation, independent of the rounds.** Launch at `0.1.0`, `release-type: rust`, both
pre-major flags `true`, manifest created empty. I re-derived it from Cargo's compatibility rule and
the pinned schema rather than endorsing the prior audit, and it holds: the `0.y` digit is the
incompatibility boundary, only the both-flags-`true` configuration maps commit types onto that
boundary correctly, and the executed matrix shows no other combination does. Seven rounds of
correction never touched any of this.

**On the decision's honesty.** It says in its first paragraph that nothing was implemented and no
owner acceptance is claimed. It labels A4 argued-from-source rather than executed. It records the
check-3 method caveat against itself and explains why the result survives it. It records a defect in
the ts decision record it cannot fix, a defect in its own binding prompt it may not edit — which I
confirmed at `inputs/prompt.md:28`, where the gloss *"feat commits bump the minor digit, not major"*
reverses the pinned schema — and a figure it did not measure. Seven unproven items each name what
would settle them. None of that is a deficiency; it is the research programme's contract being kept.

**On the round count.** Six rejections, strictly decreasing in consequence, none reaching the
recommendation: a publication claim, a merge actor, an unconditional `0.1.1`, an unconditioned
outcome class, a source count, a tally. The seventh round repaired the tally, supplied the missing
label, answered the F071 question the sixth audit raised, disclosed every hunk, and introduced no
new claim I could fault. The two observations above are smaller again than the tally was and neither
is false. This has converged. It should be published as revision 7 and closed, with the gemini
F066/F073 challenge carried to the controller's own docket rather than back into this item.
