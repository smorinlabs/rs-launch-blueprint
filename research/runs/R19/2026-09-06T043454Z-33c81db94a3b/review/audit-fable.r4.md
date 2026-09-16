decision-sha256: 6eb66faf2432e3c72f3e65c50fec9bc62621f74bc59ce3fc8fd8fb16cc99dd6c
actor: audit-fable-2026-09-06T043454Z-33c81db94a3b-r4
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: F1 essential behavior 4 and the open-PR budget are supported only by sentences about Dependabot's *unconfigured* defaults, and the pinned sentences that settle the recommended configuration were read by no check section; F2 R20's published handoff to this item — the `github-actions` version-versus-security-only choice, and the SHA-plus-comment deliverable it records as unproven — is neither recorded nor answered

Read as a fresh context that produced none of this item's raw reports, its
decision or any of its four empirical audits. I read `inputs/prompt.md`, both
raws, `review/DECISION.md`, `review/audit-codex.r1.md`, `.r2.md`, `.r3.md` and
`review/audit-codex.md` in that order, `docs/port/PARAMETERS.md`, the
synthesizer and judgment-auditor role contracts, `docs/port/COMMONALITY.md`
rows F053/F054, and the published decisions of R20, R34 and R41. I re-ran
parts of the revision-4 check myself; what I executed is stated where it bears.

## Principle and agreement level

The shared requirement is stated at the right level and sourced. The principle —
dependency and workflow-action versions refreshed automatically, on a fixed
cadence, in a small number of reviewable pull requests that are themselves
subject to the repository's own commit contract — is drawn from both pinned
source files rather than from either one's shape, and the agreement level is
taken from `docs/port/DIVERGENCE-ANALYSIS.md:103` (class **A**, `harmonize:
partly`) rather than asserted: **policy**, so the *shape* is one org value while
ecosystem keys and any key whose availability is ecosystem-bound vary. The
must-agree / may-vary table honours that split, and it puts the grouping
*predicate* in the may-vary column with a reason that is a fact about the
platform (Dependabot computes the update level per ecosystem), not a preference.

Six essential behaviors and ten acceptance criteria (A1–A10) are declared, every
one of them marked unexecuted, with A3 named as the first check P03 runs and A10
constructed so that its count is the falsifying test for the argument that
rejects alternative B. That is correct for a research programme: the decision
declines to build its own recommendation and says so.

The one place the agreement level is applied without an ecosystem argument is
the weekly/Monday cadence. It is carried from py at `b08bccfb` because the
policy shape is one org value; the 14-repository survey is never asked what
cadence well-regarded Rust projects use, even though the check observed a daily
`github-actions` entry at cargo-binstall (§9). At policy level that is defensible
and it is not a finding, but the survey could have been asked and was not.

## Design and evidence

**The design follows from mechanism, not from repository agreement, and I could
not make the opposite case.** Alternative A (py's role taxonomy) is rejected on a
capability the `cargo` ecosystem does not have — `register_production_check("cargo",
->(_) { true })` at the pin, with the documented support lists for
`groups.<id>.dependency-type` and `commit-message.prefix-development` both
omitting `cargo` — and separately on template fit (a name-keyed group rots the
day a consumer swaps a crate). Alternative B (ts's `update-types` filter) is
rejected on the pull-request volume produced by the *correct* Cargo
classification, after revision 2 read the classifier and reversed revision 1's
false claim. Alternative C is selected on GitHub's own wildcard-first guidance
plus group branches observed at cargo-binstall and datafusion. Alternative D —
which neither source repository nor any surveyed project configures — is derived
from the classifier, decided on its merits, and recorded as the successor with
the terms of its return. The decision departs from the Opus raw on `labels`
(settling for Codex), adds `versioning-strategy` that neither source carries and
justifies it from `ALLOWED_UPDATE_STRATEGIES` at the pin, and declines the live
`rust-toolchain` ecosystem on R27's open channel value. Agreement between py and
ts is nowhere the ground of a choice.

**The F1 lineage across three rejections is a true escalating repair, not a claim
narrowed until its check cannot fail.** I checked each round against the next:
r1's F1 reversed a load-bearing mechanism claim (`update-types` would *admit* a
Cargo-incompatible `0.1 → 0.2`; the pinned classifier says it *excludes* it), and
revision 2 changed the claim's direction, re-argued B from scratch and added D;
r2's F1 was a false provenance account, and revision 3 rewrote it from the
artifacts that exist; r3's F1 was a misclassification of section 5f as a pinned
read, and revision 4 **replaced the evidence rather than relabelling it** —
withdrawing 5f entirely and moving the MSRV claim onto a content-addressed
snapshot of the pin with an asserting checker.

I verified that the replacement can fail, three ways, rather than taking the
r4 audit's word for it:

- Offline, I re-derived all 21 `git hash-object -t blob` values from
  `dependabot-core-1abafc5c/tree.tsv`: 21 read, 0 defects, and the directory
  holds exactly those 21 files.
- To break the self-hashing circle, I fetched the pin's own recursive tree from
  GitHub (`repos/dependabot/dependabot-core/git/trees/1abafc5c…?recursive=1`)
  and diffed the 21 `cargo/lib/` + `package_latest_version_finder.rb`
  path/blob-sha pairs against the committed `tree.tsv`: identical. The snapshot
  is the pin's bytes, not a dated copy.
- I ran my own mutation in a scratch copy, appending `# rust-version` to
  `cargo/lib/dependabot/cargo/file_parser.rb`: assertion 3b's hit count goes
  0 → 1 and that file's blob sha diverges from its recorded value, so the
  integrity check and the zero-occurrence check both fail. The corpus is 20
  files / 207,445 bytes, and §3c's non-vacuity control (known strings
  `BumpVersionsIfNecessary`, `cargo_pre_1_0_type` present) is a real control,
  not a grep compared against itself.

The MSRV claim is also correctly bounded where it stops: `latest_version` is the
crates.io candidate path, `latest_resolvable_version` shells out to real Cargo
(`cargo update -p … -vv`, no `--precise`), and what Cargo's own MSRV-aware
resolver does inside that shell-out is named as outside the check. Issue #5423 is
demoted to dated corroboration with its mutable fields explicitly not asserted.

**Where the evidence does not reach the claim — finding F1.** The decision adds
two keys whose safety it then argues from documentation about *not* having them.
I read the pinned options-reference source at `github/docs` commit
`dd75c5f38a14d1c07c3982beddb471a605b142f7` myself. Its `## cooldown` section
separates two states: the unconfigured default (line 196, "Apply a **default
cooldown period of 3 days** … **This default cooldown does not apply to security
updates.**") and the configured case (line 198, "When **`cooldown`** is
defined:" followed by five numbered steps that state no security exemption). The
decision quotes only line 196 and then recommends `cooldown.default-days: 5`,
which puts it in the other state. The sentence that settles the configured case
is line 187 of the same pinned file — "The `cooldown` option is only available
for _version_ updates, not _security_ updates" — reinforced by the `## cooldown`
header carrying only the version-updates octicon where every neighbouring key
carries both. **The conclusion is true; I verified it. The cited evidence does
not establish it, and neither the decision nor any check section reads line 187**
(§3 prints lines 196, 198 and 223 and the support table, and nothing else).

The same gap runs through the PR budget. The decision quotes "_Security update_
pull requests are not subject to this limit and do not count toward it" as
"(same source)"; that is line 548 of the pinned file and it is accurate, but it
appears in no log section — `grep 'not subject to this limit'` over both cited
logs returns nothing. The documented default of five open version-update PRs,
which is what makes `open-pull-requests-limit: 5` "the default open-PR budget
written out" in `## Decision` and in the F054 row, is line 544 and was likewise
never read; §3's only `open-pull-requests-limit` hits are other repositories'
configuration files. Line 308's "security PRs would bypass all three keys" is the
same premise a third time, unsourced. So essential behavior 4 and the budget
half of essential behavior 2 rest on sentences the run never collected, and on
one sentence about a configuration the recommendation does not use. The
synthesizer contract is explicit here: "if you run a follow-up by hand, add it to
the script before you cite it, because an auditor reruns the script and counts."

Two properties of the main check that the decision itself discloses are worth
recording as accepted rather than as findings. Sections 12 and 15 are unasserted
pinned reads and 7 and 9 are unasserted live reads; the decision names all four,
names the `LIVE`-stamp trap that produced revision 3's miscount, and tells P03 to
give them content assertions. I confirmed §12 did read — py's and ts's pinned
`dependabot.yml` bodies are present in the cited log — so nothing rests on an
unnoticed blank today. And §7's empty `apache/datafusion` listing is the check's
own fail-open caught and corrected by a page-2 query, with the one-page limit
recorded as a real limitation. That is a defect disclosed, not hidden.

## Completeness

Required fields are present and correct. Exactly the four H2 sections the
synthesizer contract names, in order, with no extras and no `## Supersedes`
(correct: no revision was published). `### Principles and implementation` is
present with shared requirement, source, agreement level, essential behaviors,
acceptance criteria, must-agree/may-vary, four compared alternatives, why the
selected design preserves each behavior, and reference implementations. The
`re-verify:` line closes `## Decision`. Both ledger rows F053 and F054 are
settled with values, and the absence of a `BASELINE-REVIEW:` line is justified
by evidence (§13: neither row appears in `docs/port/BASELINE-REVIEW.md`) rather
than by silence; Codex's `BASELINE-REVIEW: F054` line is recorded and its
non-carriage argued. No `OVERRIDE (OV-nn)` is owed — `DIVERGENT` rows carry no
common baseline to depart from.

Parameters: the prompt's `- owns:` and `- consumes:` lines are empty and the
decision states so; there are no `owns` lines, and the four fixed `assumes` lines
are byte-identical to `docs/port/PARAMETERS.md` (I compared them
programmatically against the registry table, four of four exact, bare values with
no backticks or commentary on the line). No `CONFLICT:` line is owed: no
registered parameter needs a changed value.

Fitness gates: gate 1 is struck by the owner ruling of 2026-09-12 (Q7.B) and is
not at issue. Gates 2–6 are not labelled `inapplicable` in the decision, but the
reason that makes them inapplicable is stated at line 170 — "this item adds no
crate to `Cargo.toml`, so nothing enters the dependency tree or the licence
graph" — and gate 4 is answered in the same sentence run (Dependabot runs on
GitHub's infrastructure, and every PR it opens is gated by the matrix). Both
raws answer all six gates explicitly (`raw/codex.md:45-47,107-109`,
`raw/opus.md:343-344,381-386,510-511`). This is the formal looseness the R20
judgment audit recorded as a recommendation rather than a finding, and the R34
judgment audit accepted in the same shape; I treat it the same way. Attaching
the word to gates 2, 3, 5 and 6 would close it.

Source dates: every pinned read carries its commit sha and a retrieval date, the
two `dependabot-core` and `github/docs` pins are literal script inputs echoed
back with committer dates, live reads carry retrieval stamps, and the two
un-stamped live issue reads are called out by name.

Consistency with the empirical audit: the revision-4 Codex audit reran the
checker, replayed the snapshot from an independent scratch copy, exercised the
negative control and spot-checked six pinned files, reaching approve with no
findings. Its rerun record is consistent with the decision and with my own
re-execution. One sentence of it is inaccurate and does not affect its verdict:
"The owner-directed licence gate is absent from R19" — R19's `inputs/prompt.md`
does list gate 1 among its fitness gates; the gate is struck by owner ruling, not
absent from the prompt.

## Findings

### F1 — essential behavior 4 and the open-PR budget are argued from the wrong configuration state, and the sentences that settle them were never read

`## Decision` recommends `cooldown.default-days: 5` and
`open-pull-requests-limit: 5` on both entries. `### Principles and
implementation`, *Why C preserves each behavior*, supports essential behavior 4
("Security updates are never delayed or batched behind the routine cadence")
with one quotation — "**This default cooldown does not apply to security
updates**" — which the pinned source attaches to the *default* cooldown that
applies "even when `cooldown` is not configured" (line 196). The recommendation
configures `cooldown`, and the configured branch of that section (line 198 and
its five numbered steps) states no security exemption. The decisive sentence is
line 187 of the same pinned file at commit `dd75c5f3`: "The `cooldown` option is
only available for _version_ updates, not _security_ updates." No section of
either check reads it; §3 prints lines 196, 198 and 223 and the cooldown support
table and stops.

The budget half is the same defect. "_Security update_ pull requests are not
subject to this limit and do not count toward it" is quoted verbatim in the
decision as "(same source)" and is line 548 of the pinned file, but
`grep 'not subject to this limit'` returns nothing in either
`dependabot-config-shape.r2.log` or `.r3.log`. The documented default of five
open version-update pull requests — which is what licenses the phrase "the
default open-PR budget written out" in `## Decision` and the F054 row — is line
544 and was never read either; §3's only `open-pull-requests-limit` matches are
other repositories' configuration files. `## Engines`, disagreement 5, repeats
the premise a third time without a source ("security PRs would bypass all three
keys").

I verified against the pinned document that all three statements are **true**.
This is an evidence-coverage finding, not a correctness one: the recommendation
does not change, and no YAML key moves. What must change is that the claims for
behavior 4 and for the budget be carried by asserted reads of the pinned source
that cover the configuration actually recommended — the `cooldown` section's own
version-updates-only sentence, the budget default, and the security-update
exemption note — and that line 308's premise cite one of them. The decision's own
rule against editing the main script (its three logs' shared identity) means the
natural home is a committed checker alongside `r19-check-5f.sh`, which is the
form revision 4 already established for exactly this situation.

### F2 — R20's published handoff to this item is neither recorded nor answered

`## Decision` states that this item "owns nothing and consumes nothing", and in
the registry sense that is correct. But `research/topics/20-third-party-action-pinning-policy/DECISION.md`
is published and hands R19 two things by name:

1. The `github-actions` **version-versus-security-only** choice. R20 lines
   139–146: "R19 owns the ecosystem list, schedule, grouping and any cooldown …
   [the `claude-code-action` evidence] bears on R19's *version-versus-security-only*
   choice and is handed to R19 rather than decided here." R20's own re-verify
   trigger turns on the answer: "R19 concluding that the `github-actions`
   ecosystem gets security-only updates removes the freshness leg, and the
   pattern must then be re-argued rather than patched." R19's configuration
   answers it implicitly — a weekly entry with `applies-to: version-updates` —
   but the decision never names the handoff, never states the answer as an
   answer, and never says which of R20's two branches it selects.
2. The deliverable **"a Dependabot `github-actions` pull request advances the SHA
   and the comment together"**, which R20 states as "R19's deliverable; asserted
   here as a prerequisite" (lines 231–232) and carries in its own unproven list
   as "`#7912` and `#14716` are open, so the failure mode is live … Depends on
   R19" (lines 679–687). R19's only sentence on the subject is the affirmative
   `github-actions` "is what keeps R20's SHA-pinned actions fresh, so omitting it
   strands that policy" (line 153), with no caveat, and neither the acceptance
   criteria A1–A10 nor the unproven list mentions the comment-rewrite behavior or
   those two open issues.

`inputs/prerequisites.json` is `{}` and R20 resolved after this run opened, so
this is not a claim that the synthesizer ignored a named input — the decision
already reaches outside its inputs for R38, R11, R42 and R27, and it does cite
R20 once. The defect is that a P03 reader following R20's "Depends on R19" finds
no answer, and that R19 asserts R20's freshness outcome in a place where the
published sibling records live counter-evidence. The programme already has the
repair shape: R41's decision carries a "Relation to R23" paragraph for exactly
this situation, written after R23 attributed work to it. A short relation
paragraph naming both handoffs, stating the version-updates answer explicitly,
and adding the SHA-plus-comment behavior to the unproven list with #7912/#14716
named would close it. `research/topics/34-scheduled-freshness-lanes/DECISION.md:183`
records the R19 relation from its side and would be worth one reciprocal clause
in the same paragraph; R41 does not couple — Dependabot writes `Cargo.lock` and
manifest together and `cargo update --workspace` does not upgrade entries already
in the lockfile — and saying so costs a sentence.

## Assessment

**Reject revision 4 on F1 and F2. The recommendation itself follows from the
evidence and I would approve the same YAML once both findings are closed** —
neither requires a key to change, an alternative to be re-argued, or a parameter
line to move.

What the decision gets right is the part three rounds of empirical audit were
pressing on, and it now holds under independent test. The catch-all,
two-ecosystem shape is chosen against py's taxonomy on a capability the `cargo`
ecosystem demonstrably lacks, against ts's filter on a volume consequence of a
classifier this revision read correctly after getting it backwards, and for
itself on GitHub's written guidance plus observed group branches — with the
fourth shape neither source configures derived, decided, and held in reserve with
its return conditions written down. The MSRV claim that three audits chased is
now carried by a content-addressed snapshot of the pin whose 21 blobs I
re-derived offline, whose tree I matched against GitHub's copy of the pin, and
whose central assertion I flipped to `FAIL` with my own mutation. Nothing here is
a check that cannot fail, and the claim did not shrink across the revisions: it
reversed, then was re-sourced, then was replaced by a stronger mechanism.

What is missing is narrower and of one kind. Two keys the decision adds —
`cooldown` and `open-pull-requests-limit` — are defended for behaviors 2 and 4 by
sentences describing Dependabot's behavior when those keys are *absent*, and the
three sentences in the already-pinned source that settle the configured case were
read by no section of either check (F1). And the one published sibling that
assigned this item work by name gets an affirmative outcome claim in return and
no record of the assignment, the answer, or the live failure mode it flagged
(F2). Both are the programme's recurring defect in its quieter form: not a false
statement, but a true statement whose cited evidence covers a neighbouring case.
The repairs are a committed checker section and a relation paragraph.
