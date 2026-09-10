decision-sha256: 91ca2e8691aed687715dbec9cacdb90d59558445cc6a5bfa425bd1b4b0c7949e
actor: audit-fable-2026-09-05T164357Z-eec460755121-r6
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: review/DECISION.md:351-352, :852 and :895 say two raw reports emitted `BASELINE-REVIEW:` lines; three did — `raw/doxa-openai.normalized.md:82`, `raw/doxa-gemini.normalized.md:29`, `raw/doxa-perplexity.normalized.md:71`. `## Engines` item 7 records doxa-perplexity's substance but does not identify it as a `BASELINE-REVIEW:` line, so the decision's own tally undercounts what runbook §4 asks the controller to adjudicate

## Principle and agreement level

The shared requirement is stated at the right altitude and in the right vocabulary. It is a
requirement on the *output* — the published version number must tell the consuming resolver the
truth about compatibility, in both directions (no silent breaking update, no compatible release
withheld) — not a requirement on a flag or a tool. Its source is named as ledger rows F063, F066 and
F073 plus the ts instantiation D-021(1) read from the pinned clone `cb1cbcb2`, not as "ts does it
this way".

The agreement level, **capability / standard**, is correct and is argued rather than asserted. What
must agree is an automated bumper whose output is correct under the host ecosystem's own
compatibility rule; what may vary is the flag setting, because each ecosystem's compatibility rule
is its own. The decision then does the harder half of the A5 test: it recommends the *same*
low-level value ts uses while showing that the value follows from Cargo's own documented convention
(`semver.html`, `specifying-dependencies.html`, both quoted verbatim with retrieval dates) and from
an independently built Rust-native tool that ships the same policy as its default and labels the
contrary setting a Cargo SemVer violation (release-plz `features_always_increment_minor`). Same
value, independent derivation — which is precisely what spec §2 and amendment A5 require before a
shared low-level value may be recommended.

The three-repository reconciliation is genuine analysis, not a tidy-up. py's absence of the flags is
diagnosed as *inherited state* — py adopted release-please already at `1.0.0` (commit `1bd0344`,
pinned clone `b08bccf`), and every branch the flags guard is gated on `Version.isPreMajor`, i.e.
`major < 1` — so adding them would change nothing. That distinguishes justified ecosystem difference
from accidental drift, which is the distinction the prompt's third HIGH question asks for. The
decision correctly declines to reclassify F070 and correctly declines to edit the ledger.

## Design and evidence

**The recommendation is sound, and it is sound independently of the five rounds spent on supporting
sentences.** Architecture alternatives were compared before any flag was chosen, and they are real
alternatives rather than three spellings of one: commit-derived with dampening; commit-derived
launched at `1.0.0` with the pre-major branch never taken; and API-diff-derived
(release-plz driving `cargo-semver-checks`). Alternative 3 is correctly ruled out of scope for
adoption by F063/F066/F073 and the prompt's `## Out of scope`, while its *policy* is admitted as
evidence and its checker is proposed — explicitly proposed, not decided — as a CI gate whose job
placement belongs to R11. That is the right line to draw.

Selection follows from evidence, not from agreement. All five engines converged on the same outcome,
and the decision says so and then refuses to treat the convergence as the argument: options A–E are
separated by a 36-cell executed matrix, and the two flags' semantics are established from the pinned
schema, the maintainers' prose and `DefaultVersioningStrategy` before the probe reproduces them. The
binding case is argued per shape, and the library shape is correctly made to govern: the C-STABLE
guideline is cited as a Rust Library Team checklist item rather than a toolchain rule, and its force
here — the template's likely public surface contains pre-1.0 crates that R53, R55, R58, R67 and R69
have not yet chosen — is a fact about the programme's current state, not a preference. The
runner-up's winning condition is stated as a conjunction of four checkable conditions, which is what
makes it a runner-up rather than a rejected option.

**Version outcomes are now conditioned, and the conditioning has not eaten the answer.** The decision
carries its exception in one place — **Override precedence**, with the four-step order in
`BaseStrategy.buildNewVersion` at pinned line numbers — and every outcome elsewhere points back to it
with the word *override*. Crucially it also bounds the exception in both directions: the recommended
config sets no `release-as` key, so the persistent path is not live under the recommendation as
written; and because the empty manifest makes the first run scan the whole default-branch history, a
footer anywhere in that history fires on the first Release PR. A reader can still act on this. The
recommendation table gives three artifacts and three exact values; the bump table gives per-commit-type
outcomes; the manifest cell gives both branches (`0.1.0` empty versus `0.1.1`/`0.2.0` seeded,
depending on the history) with the history that produces each. The hedging is scoped to the sentence
it belongs to rather than smeared across the recommendation.

**The prompt defect is handled honestly, and the narrowing is correct.** I checked
`docs/port/COMMONALITY.md:76` directly. The F070 cell reads *"whether rs-launch-blueprint starts
pre-1.0 (bump-minor-pre-major/bump-patch-for-minor-pre-major) or post-1.0 like py"* — it names both
flags and glosses neither, so it cannot state their roles in reverse. The decision's revision-5
narrowing from two documents to one is right on the evidence, it is recorded as a correction of its
own earlier claim rather than quietly dropped, and it names the surviving defect at a file-and-line
address (`research/topics/25-semver-bump-strategy/prompts/semver-bump-strategy.prompt.md` line 28,
reached here as `inputs/prompt.md:28`). I confirm the reversal: prompt line 28 glosses the pair as
"feat commits bump the minor digit, not major; fix commits bump patch even under a `0.x` minor",
while the pinned schema reads *"Breaking changes only bump semver minor if version < 1.0.0"* and
*"Feature changes only bump semver patch if version < 1.0.0"*. The decision does not edit the prompt,
which is correct; it records the defect for its owner.

**The unproven items are genuinely unproven and each names its proof.** Item 1 names the exact
command, the commit sequence, the batching it depends on and the expected outputs. Item 2 names the
first Release PR and adds the specific precondition P03 must check (no `Release-As:` footer anywhere
in the scanned history, no `release-as` value configured or passed), and separates the released
number from reaching crates.io, which it claims nowhere. Item 6 records issue responsiveness as
**not measured and not estimated** — the honest form, given the prompt's evidence table demands it.
Item 3's RustSec position is labelled an interpretation of an HTTP 404 rather than an affirmative
clearance, and the decision says it did not re-query. None of these is a conclusion dressed as a gap.
Nor does the decision implement its own recommendation: nothing was scaffolded, and the end-to-end
dry run is correctly declined as implementation rather than research.

## Completeness

`## Decision`, `### Principles and implementation`, `re-verify:`, `## Parameters`, `## Empirical
check` and `## Engines` are all present, in the runbook's order; `## Supersedes` is correctly absent
(no reversal). Settled ledger rows are named with their verdicts and the decision proposes no verdict
change and makes no ledger edit.

Parameters: `- owns: none` is correct — the prompt's `- owns:` line is empty and `research/CLAUDE.md`
records `—` for R25. The four `- assumes` lines carry bare values and I compared each against
`docs/port/PARAMETERS.md`: `msrv-policy`, `rust-edition`, `target-os-matrix` and `license` all match
the registry text character for character. No `CONFLICT:`
line is required: `## Couplings` lists no `consumes:` entries and none of the four owner-fixed values
is contradicted.

Fitness gates: all six are recorded as `inapplicable` with a per-gate reason rather than omitted,
which is what the tier guidance demands for a pattern item, and the reasons are correct — adopting a
JSON boolean adds no crate to the tree. The one tool the decision *proposes* is explicitly flagged as
not gated and not executed on either required runner, and that is carried into the unproven list
rather than left in the gates section.

`CONFLICT:` handling: correct, nothing to raise. `BASELINE-REVIEW:` handling: substantively correct
but miscounted — see Findings. No raw proposal was silently adopted, no other item was touched, and
the ledger was not edited; doxa-gemini's release-plz proposal (Engines item 4), doxa-openai's
wording correction (item 5) and doxa-perplexity's F070 reclassification (item 7) are each recorded
with a reason for non-adoption.

The revision-6 rerun is consistent with the decision: `audit-codex.md` records the same digest I
computed, confirms the corrected asymmetry against `manifest.ts:1403`, `bin/release-please.ts:290-293`,
`manifest.ts:1444-1462` and `commit.ts:262,284-293`, and confirms the four-hunk diff touched no
protected region and added no unconditioned outcome. I found nothing in revision 6 inconsistent with
that.

## Findings

1. **Reject — the tally of emitted `BASELINE-REVIEW:` lines is one short.** `review/DECISION.md:351-352`
   states: *"Two raw reports did emit `BASELINE-REVIEW:` lines — both are handled under `## Engines`,
   and neither is adopted."* The same count is repeated at `:852` and `:895`. Three raw reports emitted
   one each:
   - `raw/doxa-openai.normalized.md:82` — `BASELINE-REVIEW: F070 — resolver-aligned impact tiers …`
   - `raw/doxa-gemini.normalized.md:29` — `BASELINE-REVIEW: F066, F073 — Release tool orchestration — Replace release-please with release-plz`
   - `raw/doxa-perplexity.normalized.md:71` — `BASELINE-REVIEW: F070 — pre-1.0 semver dampening — reclassify as a common architectural pattern for new library-shaped blueprints — evidence: …`

   `raw/codex.md:26` and `raw/opus.md:124` contain the token only in the negative (*"No `BASELINE-REVIEW:`
   line is emitted"*), so the emitting set is exactly those three. `## Engines` items 4 and 5 name the
   first two as `BASELINE-REVIEW:` lines; item 7 records the third's substance accurately — *"proposes
   reclassifying F070 away from `DIVERGENT` and editing `docs/port/COMMONALITY.md`. Outside R25's
   authority; not done, and recorded here instead"* — but never identifies it as a `BASELINE-REVIEW:`
   line. Runbook §4 makes the controller the adjudicator of `BASELINE-REVIEW:` findings; a controller
   working from this decision's own tally would look for two and close on two, leaving the third
   unadjudicated. This is the sixth instance of the defect shape the five prior rejections found — a
   supporting sentence stated more precisely than the evidence supports — in a sentence class the
   revision-5 sweep was not designed to reach: that sweep enumerated *version-outcome* assertions, and
   a count of baseline-review lines is not one. No empirical audit examined this area
   (`grep` over `review/audit-codex.r1.md`–`.r5.md` and `review/audit-codex.md` returns no occurrence
   of `BASELINE-REVIEW`).

   Repair, which touches nothing else: change "Two" to "Three" at `:351`, `:852` and `:895`, and add the
   `BASELINE-REVIEW:` label to `## Engines` item 7 so the three items are countable against the raws.
   Nothing in the recommendation, the parameters, the evidence, the protected regions or the unproven
   list is affected.

## Assessment

Reject on one finding, and the finding is a label and a count, not the argument.

**The recommendation is right.** Launch at `0.1.0`, `release-type: rust`, both pre-major flags
`true`, manifest created empty. It is right for the reason the decision gives rather than the reason
the sources give: Cargo's compatibility rule makes the `0.y` digit the incompatibility boundary, only
the both-flags-`true` configuration maps commit types onto that boundary correctly, and the executed
36-cell matrix shows no other combination does. The two failure modes it avoids are concrete and
demonstrated in the table — a bot promoting the crate to `1.0.0` on the first breaking change under
(C)/(E), and a compatible feature release withheld behind `0.(y+1).0` under (C)/(D). The runner-up is
correctly identified as arithmetically identical above `1.0.0`, so its cost is a day-one claim about
code that does not exist, and the graduation path back to it is one documented commit footer. Five
rounds of correction never touched any of this, and nothing I checked disturbs it.

**The decision is honest about what it does not know.** It says in its first paragraph that nothing
has been implemented and that no owner acceptance is claimed. It labels A4 as argued-from-source
rather than executed. It records the check-3 method caveat (package-internal build paths) against
itself and explains why the result survives it. It records a defect in the ts decision record it
cannot fix, a defect in its own binding prompt it may not edit, and a figure it did not measure. Its
one method caveat, its one interpretation-not-clearance note and its seven unproven items each name
what would settle them.

**It is coherent, and a reader could act on it.** Six revisions of accreted correction is a real risk
and I looked for it specifically: the file could easily have become a record of its own audits with a
recommendation buried inside. It has not. The recommendation sits in a three-row table in the first
screen, the one exception that outranks every version outcome is stated once and in full and
referenced by a single consistent marker word, and the revision history is quarantined in
`## Engines` where it belongs. The `## Engines` changelogs are long, but they are the programme's own
required record of how each round's evidence resolved each disagreement, and every one of them names
what changed and what did not. I found no contradiction between the revision-6 correction and the
body: the asymmetric source counts at `:97-105`, `:745-746` and `:645-648` agree with each other and
with the pinned source.

**The controller was right not to escalate at the round limit.** The five rejections were strictly
decreasing in consequence — a publication claim, then a merge actor, then an unconditional `0.1.1`,
then an unconditioned outcome class, then a source count — and none reached the recommendation. This
sixth finding is smaller again: a tally, in a section no auditor had been pointed at, repairable in
four edits. That is convergence, not circling, and the ruling was recorded so it could be overturned,
which is the right way to have made it.

One process observation, offered once and not as a finding: the five empirical rounds and the
mechanical sweep were both aimed at version-outcome assertions, and this defect sat outside that
aim in a section the judgment role is specifically charged with checking. If a seventh round is run,
the cheap generalisation of revision 5's method is to sweep *counting* sentences — "two", "three",
"both", "all" — against the artifacts they count, the same way version literals were swept against
their conditions.

Two further observations, deliberately excluded from `unresolved-findings` because neither is a
defect in this decision:

- `docs/port/COMMONALITY.md:77` carries **F071**, *release-please bootstrap-sha pin* (`ADOPT`,
  no research item, *"mechanical: pin the commit release-please starts scanning from when first
  configured"*). The decision's implementation note and unproven item 5 route the bootstrap-sha
  question to F066/R24 on the ground that what the first changelog contains is changelog scope. That
  is true and it is not R25's to decide, but F071 is the row that owns the pin itself and is not
  named. Naming it would make P03's inheritance unambiguous.
- doxa-gemini's release-plz proposal challenges F066 and F073, both retained rows in
  `docs/port/BASELINE-REVIEW.md`. The decision correctly declines it as outside R25's authority and
  says a reopened release-tool choice would be a new item. That leaves a live controller action:
  adjudicate it under runbook §4 or close it explicitly. It is the controller's to carry, not this
  decision's to resolve.
