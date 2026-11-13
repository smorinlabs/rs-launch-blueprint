decision-sha256: b9c8303647a8098971ff9fec7116fba041c85f5db8a4c869960e9e18c89c8057
actor: audit-fable-2026-09-05T165440Z-3a8ca31664c3-r2
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

The decision states the shared requirement as one canonical, version-controlled
statement of how to work in the repository that any contributor's tool reaches
with no second place for the same policy to drift, plus a repository-scoped
greeting for a human. It then splits that requirement across four agreement
levels in a table (`## Decision`, `### Principles and implementation`) and holds
the split for the rest of the document: the single-policy-source pattern is an
architectural pattern that must agree (F197, already `COMMON → REUSE`, and not
re-decided here); which vendor rule paths are committed is policy/mechanism that
need not; the existence of a human welcome is a capability and an explicit owner
requirement that must agree, while its mechanism and its command names need not.

That is the right level, and the decision uses it rather than merely declaring
it. The recommendation lands on py's shape (no spokes) and removes ts's, and the
document forecloses the reading that py won by agreement: the removal is argued
from the vendors' current documentation and the practice census, with py's own
`fc8d944` cited as an independent arrival at the same shape rather than as the
reason for it. The converse restraint also holds — line 89 declines to recommend
a shared recipe list across the three repositories precisely because that would
be a shared low-level value with no evidence of the same tradeoff in all three
ecosystems. The one place agreement could have been overread is F197: the ledger
row carries a baseline-review note requiring the acceptance check to distinguish
a pointer file from a second policy source, and criterion A1 is written to that
note (`CLAUDE.md` contains an `@AGENTS.md` import **and no independent policy
statements**), carried as an assumed precondition rather than re-decided.

## Design and evidence

**Alternatives.** Four designs are compared before any file is named (D1 hub-only,
D2 hub plus thin spokes — the ts shape, D3 hub plus substantive vendor rules — the
`surrealdb/surrealdb` shape, D4 hub plus nested `AGENTS.md`), each with its file
count, its policy-source count and a verdict. D2 versus D1 is correctly identified
as the real question and decided on three stated grounds rather than on preference,
and D4 is held in reserve as the specific answer to the glob-scoping capability
that dropping ts's `Justfile`-scoped Windsurf rule gives up. D3 is excluded on
principle (it violates B2), which is a principle-first exclusion, not a popularity
one. No library is selected because no member is a crate; the fitness gates are
answered `Pass` or `inapplicable` with the reason stated per gate, and crates.io
and RustSec are recorded as deliberately not queried for want of a subject rather
than left silently empty.

**The Tier D premise, and whether the recommendation survives on it.** Dropping
the spokes is sound only if Cursor and Devin read the root hub. The decision does
not claim they do. It proves the documentation text (Tier V, quoted verbatim in
the evidence log), labels the product behaviour Tier D, and hands the behaviour to
P03 as U1 and A5 with the observation that would settle it. I judge the
recommendation sound on that footing for three reasons the decision itself supplies
and one it leaves implicit. The documented direction of travel is unanimous and
first-party: Cursor lists `AGENTS.md` among its four rule types and steers plain-
Markdown users to it; Devin Desktop calls a root `AGENTS.md` an always-on rule;
Devin CLI calls it the recommended approach and defaults `read_config_from.
agents_standard` to `true`. The path ts wrote to is demoted twice over — Windsurf
hostnames now redirect to Devin hostnames (Tier V), `.devin/` takes precedence over
`.windsurf/`, and memories are documented as applying to the legacy Cascade agent
only. And the practice evidence against the spokes is not thin: `.windsurf/` and
`.devin/` appear in zero of Opus's 50 repositories and zero of the 12 re-checked
here, with `.cursor/` in exactly one, which ships substantive rules rather than a
pointer. The implicit reason is asymmetry of cost: this recommendation errs in the
reversible direction. If P03 finds a build that does not read the hub, F198's row
already names the remedy in the vendor's current path with the current frontmatter
key (`.cursor/rules/hub.mdc` with `alwaysApply: true`, or `.devin/rules/hub.md`
with `trigger: always_on`), so the failure mode is a three-line file added later,
not research redone. The decision states that reversal path as a ranked runner-up
with an activation trigger, which is what makes the Tier D footing honest rather
than merely disclosed.

Settling the display question in the implementation phase is the right call, and
the only available one: `companyAnnouncements` display and vendor hub-loading are
observations of installed products, which no P02 check and no CI lane can make.
The decision says exactly that and does not pretend a check could substitute. A5
is specified tightly enough to be executable by a human — both vendors, both
profiles — rather than being a gesture at future work.

**Honesty about what the evidence does not reach.** Three passages argue against
the decision's own recommendation and are kept: `companyAnnouncements` has no Rust
reference implementation and the document says so rather than lending it the hub's
adopters; none of the four Rust `.claude/settings.json` files read sets the key;
and the announcement's basis is explicitly called weaker than the basis for
omitting the spokes. Where a raw report's finding is carried, it is attributed
(Opus's 50-repository census, with the 12 re-checked rows marked Tier V and the
other 38 marked as not re-derived); where a raw report is overruled, the evidence
that overrules it is named (F176, R42's resolved value, and checkability against
`just --summary` for the `just`-versus-`cargo` vocabulary).

## Completeness

Required H2s are present and correctly used: `## Decision` (recommendation, the
settled F198/F199 rows, `### Principles and implementation`, and a `re-verify:`
line carrying a date plus seven named triggers), `## Parameters`, `## Empirical
check` (toolchain, OS, verbatim command, working directory, exit status and
observed counts), `## Engines`. No `## Supersedes`, correctly: revision 2 corrects
a rejected revision in place and reverses no accepted decision, and the superseded
revision's sha256 and the nature of the error are recorded in the revision note.

Parameters: R43 owns and consumes nothing, so four `- assumes` lines for the fixed
registry rows and no `- owns` line is the correct shape, and the document explains
the absence rather than leaving it to inference. I regenerated the four values from
the `fixed` rows of `docs/port/PARAMETERS.md` and compared them to the decision's
four lines: all four match exactly. The prose paragraph that follows correctly
states that none of the four constrains the recommendation, and the three values
the recommendation does depend on (F176, R42's `package-manager-invocation`, F197)
are recorded as ledger and decision references rather than smuggled onto `- assumes`
lines that the packaging validator compares byte-for-byte.

`BASELINE-REVIEW:` handling is correct and, importantly, visible. Codex emitted two
lines (F198, F199); Opus emitted none; the decision forwards neither and says so in
disagreement 3 with its reason: `docs/port/BASELINE-REVIEW.md` scopes the mechanism
to `COMMON → REUSE` and `ADOPT` rows, and both F198 and F199 are `ts-only` /
`DIVERGENT` rows whose `Item` column names R43 (`docs/port/COMMONALITY.md:202-203`,
which I read). I confirm both the scope statement and the row ownership. Under
RUNBOOK §4 the controller adjudicates such findings with the affected decision
owner; here R43 is that owner, so settling them in the ledger table under
`## Decision` is adjudication, not suppression. No `CONFLICT:` line is required:
neither raw emitted one and nothing in the recommendation needs a registered value
changed.

Fitness gates are answered per member before popularity, with `inapplicable` plus a
reason where a crate figure has no subject. Source dates are present on every
fetched claim (2026-09-10) and on the two pins.

**Consistency with the empirical audit.** `review/audit-codex.md` audits this exact
sha256 and returns approve with no findings, so the r2 approval is not a historical
audit carried forward onto a new revision. Its rerun (exit 0, 37 `PASS`, 0 `FAIL`,
`failed checks: 0`) matches the decision's cited log; I diffed the decision's log
against the r2 audit log in full and filtered the known-variable categories; the
remainder is empty. The differences are the two run timestamps, the `mktemp`
pathname, the fetched-page byte counts, and the grep line offsets that follow from
those sizes. No asserted value differs. The r1 audit's single finding is
answered rather than argued away, and the r2 audit's F2 and F3 confirm the two
things a judgment auditor would otherwise have to take on trust — that #39998 is
merged-profile evidence, and that the recommendation block, the tier table, the four
`- assumes` lines and the check script are byte-identical between revisions.

## Findings

No blocking findings. Nothing below requires a revision or changes the verdict;
each is an optional wording tightening the controller may apply or decline.

**Optional wording notes — no revision required.**

1. **A4b's literal wording does not fit the decision's own example string.** A4b
   reads "Every `just <recipe>` token the string contains appears in the output of
   `just --summary`". The illustrative announcement ends "…; just --list for the
   rest", whose token is `--list`, which never appears in `just --summary` output.
   The recommendation itself distinguishes naming recipes from pointing at
   `just --list`, so the intent is unambiguous and P03 owns the implementation; one
   clause ("recipe tokens, excluding tokens beginning with `-`") would close the gap
   at the specification level rather than leaving it to the implementer.
2. **Line 243 states the #39998 contradiction without its boundary.** The closing
   paragraph says #22425 is "contradicted by a later report at v2.1.85" and omits
   the merged-profile limit that line 39, disagreement 2 and U2 all attach to that
   report. The limit is stated three times elsewhere and the sentence is a summary,
   so no claim rests on the omission; repeating "on a merged profile" would make the
   summary match the body.
3. **The scope discount on #22425 is the weakest of the three given it, and it runs
   in the report's favour.** Disagreement 2 discounts the report partly because "the
   body does not say at which scope the key was set". That is literally true, but the
   issue's own framing — 100+ repositories each with their own `.claude/` directory,
   and a proposed fix in project `.claude/settings.json` — makes project scope the
   plain reading. The operative use of the report gives it that stronger reading
   anyway: U2 records it as a report against project-scope display. The inconsistency
   therefore weakens a discount rather than a claim, and nothing turns on it.

## Assessment

**The correction is complete, and the weight is proportionate in both directions.**
Revision 1 dismissed Codex's caution by asserting that `anthropics/claude-code`
#22425 never names `companyAnnouncements`. The issue body does name it, under
`## Current Behavior`, at v2.1.21 — I read the committed snapshot
(`review/evidence/issue-22425.r2.json`) and confirm both the string and the
metadata. Revision 2 withdraws the assertion explicitly, names it as an error that
ran in the decision's own favour, and propagates the correction to all five places
the claim touched: the revision note, the Tier D corroboration paragraph under
`## Decision`, disagreement 2, U2, and the incomplete-evidence paragraph. I grepped
the file for residue: "never mentions" survives only inside the revision note and as
the quoted, withdrawn sentence in disagreement 2, with no live assertion anywhere,
and the Tier V label revision 1 wrongly attached to the direct `gh api` reads is
withdrawn alongside the claim it supported.

The countervailing report is handled symmetrically, which is the harder half. The
decision could have used #39998 to neutralise #22425 and close U2; it does not. It
bounds #39998 to the merged case in three places, on the correct reading of the
reporter's own words — enterprise `managed-settings.json` already sets the key, so a
clean profile was never observed — and I confirm that from
`review/evidence/issue-39998.r2.json`. Neither report is allowed to settle the
clean-profile case; U2 stays open and asks for both profiles; and Codex's derived
runner-up is reinstated rather than left dismissed, with the one correction research
is entitled to make to it — a negative U2 goes to the owner, because F199 is the
owner requirement recorded in D-024(6) and research decides the shape, not the
whether. The display claim stays Tier D throughout. This is a decision arguing
against its own earlier convenience, and it is the strongest thing in the document.

**The tier structure is used faithfully.** I checked the load-bearing sentences
against the three-tier table rather than accepting the table's own claim that no
sentence overreaches. The recommendation paragraph, the D1 row of the alternatives
table, both vendor-reading claims, the announcement's display claim, the census
figures and the ts frontmatter observations each carry a tier, and each carries the
tier its evidence supports: documentation text is Tier V, product behaviour is Tier
D, and the six Tier P items are enumerated with what would prove them. The
discipline holds in the place most likely to slip — ts's `globs` sequence and its
`./path` include form differ from Cursor's documented forms, and the decision
refuses to call that breakage, recording it as format drift against documentation
and drawing the narrower, more useful conclusion that a spoke's correctness can
never be gated in CI while a hub's format has no vendor frontmatter to drift. Two
sentences (lines 47 and 117) describe the merge-plus-random-selection failure mode
in the indicative without a tier tag, but both sit under an explicit statement that
they are consequences chained from two documented semantics, and #39998 independently
corroborates the "framed as a company message" half. I found no Tier D claim asserted
as Tier V.

**The announcement is worth its maintenance cost in a template, and research chose
the part it was entitled to choose.** Whether a repository welcome ships is not
research's decision: it is the owner requirement recorded through D-024(6), and the
decision says so instead of manufacturing an adoption case for a key with one adopter
in evidence. What research could decide was shape, and the shape it picked is the one
that converts the maintenance cost from silent rot into a visible failure: recipe
names are checkable against `just --summary` where a `cargo` command is not, so A4b
turns a stale welcome into a failing guard rather than a wrong instruction a newcomer
follows. Two further constraints bound the blast radius — exactly one entry, so the
template never multiplies a pool it shares with user and managed settings, and never
the only place a required instruction appears, so a welcome that is missed costs
nothing. The alternative Codex's staleness concern points at — a pointer-only string
naming no recipes — has zero staleness risk and close to zero onboarding value; the
decision argues that tradeoff and keeps the `just --list` index pointer from Codex
rather than assuming it away. Against that, the standing cost is one JSON key holding
three recipe names in a repository that already gates recipe names in CI. That is
proportionate.

**Fitness to publish.** The decision is a proposal and labels itself one; it
implements nothing, and its check implements nothing — no rule file, no settings
file, no guard script, no scaffold, and no vendor product launched. Under the
programme's division of labour that is correct, and declining to build what it
recommends is not a defect. The evidence is reproducible, the unproven claims are
enumerated with what would prove them and who acts on a negative, the parameter lines
match the registry byte-for-byte, and the empirical audit of this exact revision
approves with no findings. Approve.
