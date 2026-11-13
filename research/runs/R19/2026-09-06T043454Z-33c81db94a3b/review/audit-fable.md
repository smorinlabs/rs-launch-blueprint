decision-sha256: 178547307ca6000e9527fcea08af6c89fb5f23f25ef8e17938c0e5457791006d
actor: audit-fable-2026-09-06T043454Z-33c81db94a3b-r5
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

Read as a fresh context that produced none of this item's raw reports, its
decision or any of its five empirical audits. I read `inputs/prompt.md`, both
raws, `review/DECISION.md`, `review/audit-codex.md` (r5) and the four archived
Codex audits, my predecessor's `review/audit-fable.r4.md`,
`docs/port/PARAMETERS.md`, `docs/port/COMMONALITY.md` rows F053/F054,
`docs/port/BASELINE-REVIEW.md`, the synthesizer and judgment-auditor role
contracts, and the published decisions of R20, R34 and R41. What I executed is
stated where it bears. Revision 5 repairs exactly the two findings my
predecessor raised and changes no key; this audit is scoped to whether the
repairs hold and to re-confirming what four earlier rounds cleared.

## Principle and agreement level

Unchanged from revision 4 and still correct: the shared requirement is drawn
from both pinned source files rather than from either one's shape, and the
agreement level is taken from `docs/port/DIVERGENCE-ANALYSIS.md:103` (class
**A**, `harmonize: partly`) rather than asserted — **policy**, so the shape is
one org value while ecosystem keys and any key whose availability is
ecosystem-bound vary. Six essential behaviors and ten acceptance criteria are
declared, every one marked unexecuted, with A3 named as the check P03 runs
first and A10 built so its count is the falsifying test for the argument that
rejects alternative B. The decision declines to implement its own
recommendation and says so, which is correct for this programme.

**The cadence, and whether labelling it is enough (non-finding).** My
predecessor recorded that weekly/Monday is carried from py with no survey
argument, and explicitly declined to make it a finding. Revision 5 now labels
it in all four places it appears — `## Decision` line 15, the F054 ledger row,
the must-agree column, and a dedicated *Cadence* paragraph carrying the
explicit **"Status: carried, not researched"** — names the one contrary datum
the run produced (cargo-binstall's daily `github-actions` entry, main check §9)
and names the falsifier (A3's four weeks of Monday pull requests). The charter
rule is that existing py/ts implementations are evidence, not winners by
default; the defect it guards against is a value presented as won because a
source repository holds it. This decision presents the opposite: it says the
value is carried, shows the evidence pointing the other way, and hands P03 the
measurement. At an agreement level the programme's own document fixes as policy
for exactly this knob, that is sufficient. Requiring an argument now — after
the decision improved on the state my predecessor already accepted — would move
the goalposts rather than test fitness. Not a finding.

## Design and evidence

**F1 is closed, and the repair is a genuine evidence upgrade rather than a
relabelling.** The three sentences that settle the *configured* case are now
read at the pin the decision already named, asserted by bytes **and by line
number**, from a snapshot bound to `github/docs` commit `dd75c5f3` by the
file's own git blob sha. I verified this independently rather than taking
either audit's word:

- Offline, `git hash-object -t blob` over the committed snapshot file returns
  `01d39a3ada2b59a5c820d16facb465df52f22476`, the value `tree.tsv` records, and
  the file is 1174 lines.
- I read lines 185, 187, 196, 198, 539, 545 and 548 of that file myself. Line
  187 carries "The `cooldown` option is only available for _version_ updates,
  not _security_ updates."; 196 is the unconfigured default revisions 1–4
  quoted; 198 opens the configured branch; 545 carries the documented default
  of five open version-update pull requests; 548 carries the security-update
  exemption from the limit. Every quotation in the decision matches the bytes.
- I ran `r19-check-r5.sh` myself from `/tmp`: 12 PASS, `failed assertions: 0`,
  including the live re-read of the blob sha at the pin. §2c is a real
  non-vacuity control — `labels`, `groups`, `commit-message` and
  `versioning-strategy` all carry the `shield-check` octicon that `## cooldown`
  and `## open-pull-requests-limit` lack, so 2b/3a's absence is an asymmetry in
  the document and not a failed match. The negative control fails exactly two
  assertions (blob integrity and line 187) and no others.

**One correction to my predecessor, owned here.** r4's F1 located the
documented open-pull-request default at line 544. The pinned file carries it at
**545**; I checked. Revision 5 cites 545 and asserts the line number, so the
citation is now stronger than the finding that prompted it.

**F2 is closed, and the answer is the real one.** I read R20's published
decision rather than the decision's account of it. Every citation resolves:
`:139-146` carries "R19 owns the ecosystem list, schedule, grouping and any
cooldown" and the hand-off of the `claude-code-action` evidence to R19's
version-versus-security-only choice; `:231-232` is criterion 4, "advances the
SHA and the comment together (R19's deliverable; asserted here as a
prerequisite)"; `:287-289` is the re-verify trigger that fires only on the
security-only branch; `:679-687` is R20's own unproven item with `#7912` and
`#14716` named. The paragraph answers the choice explicitly — **version
updates** — and identifies which of R20's two branches that selects, so R20's
trigger is correctly reported as not fired. The freshness outcome, which
revision 4 asserted flatly, is qualified in place under *Ecosystem set* and
points at the relation paragraph.

The named failure mode is the real one. `#14716` is "GitHub Actions: SHA-pinned
actions updated to untagged branch HEAD commit when current SHA lacks a direct
tag, **leaving version comment stale**" and `#7912` is "Version comment in
SHA-pinned github actions is not updated if it's incorrect" — both stale-comment
modes after an advanced pin, which is precisely the first branch the decision
describes ("the workflow runs the new code under a label asserting the old
one"). The second branch (a dropped comment) is described as what R20's part
3.2 guards, not as observed bot behavior, which is accurate. The behavior is
added to the unproven list with both issue numbers, and the joint check is
recorded outside A1–A10 as R20's criterion rather than this item's. The two
documents now record the same gap.

**The adjacent-relations paragraph, also new in revision 5, checks out.** I
verified all three of its citations, none of which any earlier audit saw:
`research/topics/34-scheduled-freshness-lanes/DECISION.md:183` carries the
quoted clause verbatim; `research/topics/41-lockfile-freshness-check/DECISION.md:27`
carries "`cargo update --workspace` never upgrades a package that is already in
the lockfile" verbatim; and `file_updater.rb`, `lockfile_updater.rb` and
`manifest_updater.rb` are all three in `dependabot-core-1abafc5c/tree.tsv`
(rows 4–6), so the path citation names files the snapshot actually holds. The
decision correctly marks that one as a path citation rather than a reading of
those files' logic.

**The py correction is right, and it strengthens alternative C.** I read
`.github/dependabot.yml` at py's pin `b08bccfb` directly: its `github-actions`
entry declares `groups: github-actions: patterns: ["*"]`. Six groups total —
four name-keyed on `uv`, one pattern-keyed on `npm`, one catch-all on
`github-actions` — so revision 4's "four name-keyed groups" undercounted, and
the corrected count is the one in the file. Alternative A's evidence column now
reads "py's `uv` and `npm` entries … **not** its `github-actions` entry, which
is alternative C", and alternative C's column credits py's own entry. Both are
consistent with the source, and the correction removes an asymmetry rather than
creating one: the decision's own template-fit argument against A already turned
on py using `patterns: ["*"]` for the one ecosystem whose dependency names it
does not control. **One precision remark, not a finding:** py's group carries
`patterns: ["*"]` with no `applies-to`, while alternative C's *mechanism*
column lists `patterns: ["*"]`, `applies-to: version-updates`. That is
acceptable because `applies-to: version-updates` is the documented default and
the decision says so itself at line 156 when it explains why that key is
written out for the reader; py's entry is behaviorally the same shape. The
evidence column is precise about which two keys py actually sets.

Everything the four earlier rounds settled reproduces. The design still follows
from mechanism rather than repository agreement: A is rejected on a capability
`cargo` lacks, B on the volume consequence of a classifier revision 2 read
correctly after getting it backwards, D is derived rather than observed and
held as the recorded successor with its return conditions, and the decision
departs from the Opus raw on `labels`. The MSRV claim still rests on the
content-addressed `dependabot-core` snapshot, and the r5 Codex audit re-ran
that checker and its mutation as well.

## Completeness

Exactly the four H2 sections the synthesizer contract names, in order, with
`### Principles and implementation` carrying shared requirement, source,
agreement level, essential behaviors, acceptance criteria, must-agree/may-vary,
four compared alternatives, why the selected design preserves each behavior,
and reference implementations. The `re-verify:` line closes `## Decision`. The
new "Relation to R20" paragraph sits under `## Decision` after the ledger rows,
which adds no section.

**The claims of byte-identity to revision 4, verified rather than accepted.** I
diffed the committed revision-4 file (`f99d584`) against the current one
(`6340285`): the YAML block, the four `assumes` lines and the ten A1–A10 rows
are byte-identical, three diffs, no output. The four `assumes` values are
byte-identical to `docs/port/PARAMETERS.md` rows 7–10. No `owns` or consumed
lines are owed; no `CONFLICT:` line is owed and neither raw raised one.

**`BASELINE-REVIEW:` handling unchanged and still correct.** `grep 'F053\|F054'`
over `docs/port/BASELINE-REVIEW.md` returns zero matches, both rows are
`DIVERGENT` in `COMMONALITY.md:59-60`, and the Codex raw's `BASELINE-REVIEW:
F054` line is recorded with its non-carriage argued rather than passed over. No
`OVERRIDE (OV-nn)` is owed.

**Fitness gates — revision 5 did not address the labelling, and it remains a
non-finding.** Gate 1 is struck by the owner ruling of 2026-09-12 (Q7.B) and is
not at issue. Gates 2–6 still carry no `inapplicable` label; the word appears
nowhere in the decision. The reason that makes them inapplicable is still
stated at line 183 ("this item adds no crate to `Cargo.toml`, so nothing enters
the dependency tree or the licence graph"), gate 4 is answered in the same
sentence run, and both raws answer all six gates explicitly. The R20 and R34
judgment audits accepted the same shape, my predecessor recorded it as formal
looseness rather than a finding, and I treat it the same way. Recorded so the
owner can see it is unclosed by choice, not by oversight.

Source dates: every pinned read carries its commit sha and a retrieval date,
the three pins are literal script inputs echoed back, live reads carry
retrieval stamps, and the two un-stamped live issue reads in the main check are
still called out by name.

**Consistency with the empirical audit.** `review/audit-codex.md` binds the same
decision sha256, approves with no findings, re-ran `r19-check-r5.sh` plus reruns
from `/` and from a `git archive` extraction, exercised both negative controls,
reconstructed the main check byte-identically, and independently curled the
docs blob and issues #9681, #7912 and #14716. Its account agrees with the
decision and with my own re-execution; I found no statement in it that the
decision contradicts.

## Findings

None. Both revision-4 findings are closed: F1 by a committed, line-number-asserting
checker over a content-addressed snapshot of the pin, whose bytes I re-read and
whose run I reproduced; F2 by a relation paragraph whose every quotation and
line citation I checked against R20's published decision, which answers the
version-versus-security-only choice as **version updates**, names the real
stale-comment failure mode behind `#7912`/`#14716`, and records the
SHA-plus-comment behavior as unproven. The three remarks above — the carried
cadence, the unlabelled gates 2–6, and `applies-to` in alternative C's mechanism
column — are recorded as non-findings and none of them blocks.

## Assessment

**Approve revision 5. The recommendation follows from the evidence**, and it is
the same recommendation revision 4 made: no key, alternative, acceptance
criterion or parameter line moved, and I verified that rather than accepting it.

What changed is that the two keys the decision adds are now defended by the
sentences that describe the configuration it actually recommends, not by
sentences about its absence — read at a pin, asserted by bytes and line number,
with a control that proves the absence is real and a mutation that proves the
check can fail. And the one published sibling that assigned this item work by
name now gets its assignment recorded, its choice answered in its own terms,
and its live failure mode carried into this decision's unproven list instead of
an unqualified freshness claim. The third correction — py already configures
the selected shape for one ecosystem — makes the alternatives table agree with
the source file it cites, and it cuts in the decision's favour.

The recurring defect this programme keeps catching is a true statement whose
cited evidence covers a neighbouring case. Across five rounds this item has now
had that defect found in a mechanism claim, in a provenance account, in a
section classification, and in two documentation citations, and each time the
repair replaced the evidence rather than softening the claim. Nothing in
revision 5 narrows a claim to fit a check; the checks were built to reach the
claims. What remains unproven is what a research programme is supposed to leave
unproven — every acceptance criterion, the grouped-subject width interaction,
the expelled-bump volume, the SHA-plus-comment pair, and the cause of ratatui's
inert entry — each stated with what would prove it, and P03's order of work
written down.
