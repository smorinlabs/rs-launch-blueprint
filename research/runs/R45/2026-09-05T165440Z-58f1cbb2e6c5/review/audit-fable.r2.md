decision-sha256: 1e7fe24926e11fa5b40bedb3c42f187af05e161e4bec0b7ad4ea548b0fae6816
actor: audit-fable-2026-09-05T165440Z-58f1cbb2e6c5-r2
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

The shared requirement is stated as an outcome, not as a mechanism: *after a contributor
pushes a fix, obtaining a fresh automated review is a documented, discoverable act rather
than folklore.* Its source is named at a pin (py `b08bccfb`, `.github/pull_request_template.md:90-97`,
C6) plus ledger row F204, and the must-agree / may-vary split is recorded before the
alternatives are compared, as spec §2 requires rather than inferred from how py happens to
be implemented.

The declared level is **policy** — specifically a documentation-location policy — with the
reasons for excluding the other two levels given: the capability belongs to R18, and no
architecture is involved. That label is defensible under the §2 table even though the file
may vary per repository, because the decision does not leave the file to taste: it derives
it from a rule ("the correct file follows from which surface the command uses"). A
per-repository difference that falls out of a shared rule is a derivation, not a variation,
so the policy is not drained by clause (d). The alternative reading — capability/standard —
would not change any conclusion in the file, since what may vary is identical under both.

The three essential behaviors and the three acceptance criteria (A1 handle resolution, A2
who may use the trigger, A3 no template claim the workflows contradict) are observable, and
A1 is identified as the mechanically checkable one with its check routed to P03. Nothing is
weakened into a vague goal.

## Design and evidence

**The R18 branch claim, tested rather than accepted.** The decision's load-bearing structural
claim is that its PR-template answer is invariant across the two branches of an owner
acceptance that is not on record, and that only the `CONTRIBUTING.md` half is conditional. I
tested it in both directions.

- Branch B is not this item's invention: R18 revision 5 (`DECISION.md:7`) states its own
  fallback in those words — "If the owner withholds that acceptance, the documented runner-up
  is what ships: delete both files and publish the opt-in recipe." The two branches are
  exhaustive of the owner question R18 poses (acceptance recorded, or withheld).
- Under branch A the case for no block stands on four grounds that are each about rs: no bot
  py names is configured by R18's file set (C2); the review lane omits `synchronize`, so py's
  "Bots also auto-review on push" sentence would be false if copied (C1); the one available
  trigger is author-gated, so a command pasted into every rendered body would instruct most
  outside contributors to do something that starts no job; and the template is the
  description surface, which is the one surface the action's trigger scan reads (C4).
- Under branch B grounds one and two hold a fortiori — nothing is configured at all, so a
  block would name bots the repository does not have and would fail A1 on its face.
- Neither branch's argument is doing the other branch's work. The conclusion is reached twice,
  by different routes, not once and then asserted to carry. There is no quiet single-branch
  dependence, which is the defect the claim had to avoid.

The decision also does not overclaim the invariance: the branch table marks the
`CONTRIBUTING.md` row as differing, the runner-up paragraph repeats that the difference is
confined there, and the residual conditionality that remains under branch A — P03's
`synchronize` choice, and R18's unproven `U12` — is recorded under "What P03 must validate"
rather than absorbed. I verified `U12` and `U2` exist in R18 with the content R45 attributes
to them (R18 `DECISION.md:18`, `:32`).

**The latent-not-live refinement.** It is load-bearing, and at the right strength. It is what
keeps fact 3 from becoming a security claim the evidence does not support: the pinned source
shows the body scan exists (`trigger.ts:78-102`, C4), and the same file shows the review lane
never reaches it because `prompt` short-circuits at `:20-23`, while the assistant lane lists
no `pull_request` event (R18 `DECISION.md:12`); C5 adds that py's four-clause `if:`, which R18
adopts unchanged, carries zero `pull_request` clauses, so a later revision would need both the
event and a matching clause. The decision states the consequence in the only form that follows:
the rule is adopted "because it costs nothing and closes the exposure ahead of that revision,
not because the exposure is live today." That is a precaution argued as a precaution, and it
is narrower than either raw's framing — the decision records that it narrowed both, and names
the pinned `trigger.ts` rather than the `main` docs wording the Opus raw quoted.

**The handle count.** The discipline is right, not over-hedged. "Three separate fetches … one
of them by a different actor" is immediately qualified in the same paragraph — two are the
same script on the same host, the third is the r1 auditor's own fetch — so the word
"independent" is not carrying weight it has not earned. The `What it does not establish`
paragraph rules out four specific over-readings (that `@greptile-apps review` fails; when the
divergence began; that agreement across one day implies corpus stability; anything about rs)
and each exclusion names what would have been needed to claim it. The test that separates
honest hedging from evasion is whether the hedge costs the recommendation anything, and the
decision answers it explicitly: "if the count were reversed tomorrow, the recommendation would
not change." The count is corroboration for a policy reached on the surface argument and on
C2, and it is placed as such.

**Removing what the source has.** The removal is argued from rs, not from py's defects. The
four grounds above are all about what this template would ship; the py observations — Greptile
handle drift (C8) and an instruction to comment `@cubic-dev-ai review` in a repository with no
cubic configuration (C7) — are fenced where they are introduced: "Both observations are about
py's inlined block; neither is evidence about rs." The ecosystem evidence is used at the right
altitude too: zero adopters of the inlined shape among twelve surveyed Rust projects is
reported with its own limit (non-documentation at repository level, not non-use, because an
org-level app install is invisible to a repository's files), and the Rust project's deliberate
template/guide split is cited as the positive reference implementation rather than as mere
popularity. The removal's cost is named and accepted, not elided: copy-paste at the point of
need, and multi-bot coverage the template cannot honestly keep true.

**Alternatives.** Five designs are compared on a stated axis — who owns the string that can
drift — with a verified adopter per row, including the two source precedents and the native-UI
option that would make documentation unnecessary. The decision declines both precedents and
says why neither transfers, which is the §2 result the mandate contemplates.

## Completeness

- Required H2s present and in order: `## Decision` (carrying `### Principles and implementation`
  and the `re-verify:` line), `## Parameters`, `## Empirical check`, `## Engines`. No
  `## Supersedes`, correctly — this is a revision of an unpublished decision, not a reversal.
- Parameters: `owns` and `consumes` are both empty in the prompt, and the decision says so and
  owns nothing. The four `assumes` lines match `docs/port/PARAMETERS.md` in name and value, and
  each is explained as inapplicable with a reason rather than listed and left. No `CONFLICT:`
  line is needed and none is invented.
- Fitness gates: all six answered `inapplicable`, each with its own reason, as the tier
  guidance requires for a pattern item; none is silently omitted. Gate 3 additionally records
  the nearest security-shaped consideration and names where the actual trust gate lives (R18's
  `author_association` prefilter), rather than treating "inapplicable" as "nothing to say".
- `BASELINE-REVIEW:` handled as the runbook requires: Opus's F204 line is carried verbatim in
  substance, routed and not acted on, with the ledger untouched and verdict assignment left to
  the controller. Codex's competing F204 line is recorded with the reason it is not carried
  (it presupposes a block this decision does not create, and it predates R18's result by five
  days) rather than dropped in silence.
- Ledger facts check out: `docs/port/COMMONALITY.md:208` is F204, `py-only`, `DIVERGENT`, item
  R45, annotated `standalone`, exactly as cited; F203 is named as out of scope and nothing in
  the decision touches a checklist line. F204 carries no BASELINE-REVIEW.md row, so there is no
  recorded agreement level for this item's label to contradict.
- Source dates and pins are present throughout, and carried-not-refetched citations are
  labelled as such (the four Rust/GitHub URLs, CodeRabbit and cubic references) rather than
  presented as this run's observations.
- The decision does not implement its own recommendation and should not: the A1 check is routed
  to P03 with its wiring assigned to R11, and the Opus prototype's two limits are carried
  forward. The `Status` paragraph states the proposal/validation boundary and disclaims owner
  acceptance.
- Consistency with the empirical audits: `audit-codex.r1.md` rejected revision 1 on two claims
  about how the file described its own check (log reproducibility; write scope), and both are
  answered in the artifact I read — the script is saved at `review/evidence/r45-check.sh` with
  its sha256, it emits its own source, and the four scratch writes are enumerated.
  `audit-codex.md` (r2) confirms by rerun that the checks region is byte-identical across
  revision 1, revision 2 and its own run, so no observation moved; its five other passes concern
  claims I did not need to re-derive and none of them conflicts with anything above. The r1
  audit's three passing findings cover the same three inherited facts and the same branch claim
  I tested here, and it reached the same reading.

## Findings

1. **Pass — the branch-invariance claim survives the test it invites.** The PR-template
   recommendation is independently reached under each branch of R18's open owner question, the
   branch-B fallback is R18's own stated runner-up, and the conditional half is confined to
   `CONTRIBUTING.md` and labelled there.
2. **Pass — the latent-not-live refinement is load-bearing and correctly bounded.** Two
   independent unreachability reasons are verified at the pin, and the rule that follows is
   argued as a cheap precaution rather than as a live-exposure fix.
3. **Pass — the handle count resolves the inherited claim without over-reading it.** The
   corroboration is disclosed for what it is, the four exclusions are specific, and the
   recommendation is stated to be indifferent to the count's outcome.
4. **Pass — the removal is argued from evidence about this template.** py's two defects are
   fenced as evidence about py; the rs-specific grounds stand alone, and the removal's costs
   are named and accepted.
5. **Pass — required fields, parameters, gates, ledger handling and the P02/P03 boundary are
   complete and correct**, and the decision records its unproven rows with what would prove
   them and who owns them.

## Assessment

This is a decision whose value rests on a structural claim, and the claim holds: the answer it
records for `.github/pull_request_template.md` does not depend on an owner decision that has not
been taken. It reaches that answer twice by different routes, states the one half that is
conditional as conditional, narrows two inherited claims against pinned sources rather than
repeating its raws, and declines to assert the things it did not test. Approve, with no
unresolved findings.

Two precision notes for the controller, neither a finding and neither blocking publication:

- `## Engines`, disagreement 1 restates fact 3 unqualified — "the one reviewer R18 configures
  reads the description for its trigger phrase (C4)". Read literally that is live behavior,
  whereas C4 establishes the action's code path and fact 3 establishes that no lane R18
  configures reaches it. Disagreements 2 and 3 both carry a pointer back to their narrowing;
  this one does not. The paragraph's conclusion does not depend on it — it stands on C2's empty
  row set and on the comment-versus-description surface convention — so a clause tightening it
  ("the action that reviewer is built on reads the description; see `## Decision` fact 3 for why
  no configured lane reaches that branch") would close the last gap between the two statements.
- The closing uncertainty paragraph lists C7 and C8 among the reasons the PR-template half is
  over-determined, while `## Decision` says of those same observations that "neither is evidence
  about rs". Both are true under the reading the decision itself supplies elsewhere — they are
  evidence about the inlined-vendor-string *pattern*, which is what rs would be adopting, and
  essential behavior (3) is where that link is made — but the second mention does not restate
  it, so the two sentences read as if they disagree.
