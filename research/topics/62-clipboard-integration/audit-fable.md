decision-sha256: fb0a58c9556fdd19052e165d2f5a1d53e2766a84961ab86f9f2401500140d3c2
actor: audit-fable-2026-09-17T020715Z-7f97cd917c54-r2
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

This is the round-2 judgment audit of R62 revision 2 (commit `2547506`). I wrote
the round-1 audit, archived byte-identical at `review/audit-fable.r1.md`
(sha256 `9b7b5a106f7b88f546cc51426e3e98e671a9dcc5bf2a0cc82597b2575190b198` for
both files); I produced none of this item's raw reports, neither revision of the
decision, and none of its evidence. The empirical audit remains deferred, so
`review/audit-codex.md` does not exist and nothing here stands in for one —
acceptance still needs that second verdict under `research/RUNBOOK.md` §5.

I read the full revision-2 file, the complete `2547506~1..2547506` diff, the new
`review/evidence/verify-r2.sh` and `r62-clipboard-claims-r2.log`, and I re-read
at source every document the repairs newly depend on:
`research/topics/67-error-and-exit-code-contract/DECISION.md`,
`research/topics/06-unsafe-code-policy/DECISION.md`, `docs/port/PARAMETERS.md`,
`docs/port/OWNER-REVIEW.md` (both the 2026-09-12 and the 2026-09-14 entries),
the org CLI Design Standard at blob `f9de0437`, and the parts of `raw/opus.md`
that the new subsections quote. I reran nothing.

## Principle and agreement level

Unchanged and still correct. The requirement, its source, the capability-and-policy
agreement level and the five-row must-agree table are byte-identical to
revision 1, and the diff touches none of them. The prompt-gloss correction, the
`ts-only` ledger reading and the absence of a `BASELINE-REVIEW:` line all stand
as audited in round 1.

Revision 2 adds one thing at this level that improves it: the post-result
partial failure is now named as a *shape* — the command's requested result
delivered and correct, one additional requested side effect not performed — and
the must-agree row is cited as the reason neither output mode may withhold the
result. That is the principle doing work rather than being restated.

## Design and evidence

**The recommendation does not move, and I verified that mechanically rather than
on the synthesizer's word.** The diff is three files: `review/DECISION.md`, plus
two new additive artefacts (`review/evidence/verify-r2.sh`,
`review/evidence/r62-clipboard-claims-r2.log`). `verify.sh`, `spike-build.sh`,
`r62-clipboard-claims.log` and `r62-spike-build.log` do not appear in the diff at
all, so everything round 1 reproduced is untouched. The member table, the flag
spelling, the stderr note, the fatal policy sentence and the four `- assumes`
lines are absent from the deletion set, so they are byte-identical. The complete
list of deleted lines is exactly the seven passages my findings named, plus the
figures-table header row the responsiveness column replaces, the `re-verify:`
line, the logs paragraph, and the `copypasta` sentence that now carries the
countervailing figure. Nothing else was edited.

**JF-1 is resolved, and resolved consistently.** The three surfaces that
contradicted each other now agree. AC3 states that stdout carries the result
byte-identical to the same command run without `--copy` while stderr carries
exactly one `RSLB101` object; AC2 is unchanged and now agrees with it; the
must-agree ordering row is cited as the constraint that forces both. The new
subsection *"What a post-result failure puts on each stream, and the R67 clause
it meets"* states the two modes in a table with fd 1, fd 2 and the exit status,
and the superseded wording is quoted in place rather than silently removed —
both at AC3 and in the `## Parameters` sentence — so a reader of revision 2 can
see what revision 1 said and why it was wrong.

The standard is now read at each rule's own scope, which is the part I would
have pressed on. **R7.8**'s mid-stream clause and the absence of any
empty-stdout requirement carry the argument (checks `R01`, `R02`); **R7.1**
routes a mid-command diagnostic to stderr without withdrawing data already
written (`R03`, `R04`, `R04b`); **R8.2** supplies exit `1` (`R07`). **R6.3 is
explicitly demoted to a shape analogy** because its literal scope is "a command
operating on many items" (`R05`, `R06`) — the decision reached that on its own
and says so, and it is the correction I would otherwise have made, since
`raw/opus.md` had cited R6.3 as if it governed. Every one of those assertions
appears in the r2 log with text that matches the use the decision makes of it.

**Check A95 is no longer asked to carry what it does not assert.** `R12` records
exactly what A95 established (the envelope substring, nothing more), `R13` carries
the `hint`-omitted-not-`null` claim, and `R08`/`R09`/`R11` carry the byte-empty
clause. The `## Parameters` prose is rewritten to match.

**The R67 disposition is legitimate, and the form is right.** I tested it against
the alternatives rather than accepting it. Three things decide it.

First, the facts the decision states about R67 are exact. The clause *"stdout
stays byte-empty on the error path"* occurs in R67 exactly twice — inside the
`owns error-taxonomy-exit-codes` value and again in R67's own AC2 — so "two
locations, and the complete list" is right, and check `R08` is candid that the
clause sits **inside the registered value**, which is the fact that makes the
question hard rather than easy. R67's broken-pipe rule does separate the result
stream from the error path in R67's own words, so ground 1 is R67's text, not an
inference about it.

Second, a `CONFLICT:` line would assert something the decision has not
established and does not believe. Its grammar, in the prompt and in RUNBOOK §4
alike, fires when a recommendation *needs a registered value changed*. Under
R62's reading nothing changes: the clause was written for failures that produced
no result, which is every failure R67 itself had in view, and `RSLB101`, exit
`1`, the three keys, the `hint` rule and the `thiserror`/`anyhow` layering all
apply to R62 unchanged. Emitting a conflict would claim the opposite — that
R67's value must move — which R62 neither shows nor needs.

Third, and decisively for approval, the decision does not settle the question by
assertion. It writes out the exact substitute sentence R67 would need under the
unqualified reading, attaches the same qualification to R67's AC2, names that as
an R67 edit rather than an R62 one, makes it a `re-verify:` trigger on R67's
*Envelope* wording, and adds unproven row 7 stating in terms that the reading is
"this decision's, argued from the binding standard and from R67's own broken-pipe
rule, and it is not an owner ruling". A controller who reads the clause as
unqualified can overrule the disposition without re-deriving anything. That is a
genuine owner question raised *with* the research done and a recommendation
attached — the form the programme asks for — rather than a consumer quietly
reinterpreting a published owner-accepted value.

I record one acceptance-process consequence for the controller below; it is not
a defect in the decision and not an unresolved finding.

**JF-2 through JF-7 are closed, each with new evidence rather than new prose.**

| Finding | Closed by | Verified |
|---|---|---|
| JF-2 | Gate 3's posture half answered in full: `arboard` uses `unsafe` in platform FFI — 67 keyword lines across six surveyed sources (`R14`) — zero in the public error module (`R15`), with R06's scoping quoted | R06's decision text carries *"makes no claim about `unsafe` inside its dependency tree"* verbatim; the `forbid` sentence is now explicitly labelled first-party-only |
| JF-3 | The §7.6 column added and **computed here**, with a stated method (10 most recently opened non-PR items; first `OWNER`/`MEMBER`/`COLLABORATOR` comment that is not the author's; median over the answered subset, unanswered reported beside it) | 30 issues sampled across the three crates (`R18*`); figures 1.68 / 8 of 10, 0.02 / 1 of 10, 7.92 / 5 of 10 |
| JF-4 | Alternatives 2b and 3a defined with promotion condition and migration cost | `raw/opus.md` numbers the Member 2 runner-up **2b**, ranked above 2a and 2c — my round-1 narrative called it 2a, and the decision corrects me by name (`R25`) |
| JF-5 | R5.6 demoted to motivation; the operative reasons stated (`/proc/<pid>/cmdline` world-readability, `ARG_MAX`) | `R19`–`R21`: R5.6's title is *Secret redaction in output* and its text contains no `argv`, process listing or `/proc` — which matches the blob I read |
| JF-6 | "verbatim" replaced by the accurate claim about the dependency-line *shape*, pinned one patch earlier | `R23`, `R24`: zero 3.6.1 pins in nushell's manifest |
| JF-7 | The rejected warning policy recorded beside the fatal one, with its argument, the ground of rejection and the cost of flipping it | `R29`–`R31`, quoted from `raw/opus.md` |

JF-3's repair goes further than the finding asked. The figure it adds cuts
against the crate the decision selects — `copypasta` answers in about half an
hour and `arboard` leaves eight of ten recent issues unanswered — and the
decision says so in those terms, keeps the `at-risk` verdict on the two signals
responsiveness does not touch, and explicitly disclaims that the selection is a
claim of better maintenance on every axis. That is the honest handling of
countervailing evidence, not the minimum one.

## Completeness

The H2 set is unchanged and correct: `## Decision`, `## Parameters`,
`## Empirical check`, `## Engines`, with no `## Supersedes` — right, because
revision 2 revises an unpublished file in place and reverses no published entry,
and the revision note says exactly that. The `re-verify:` line still sits at the
end of `## Decision` immediately before `## Parameters`, matching R64 and R67.
The four `- assumes` lines remain byte-identical to `docs/port/PARAMETERS.md`.
No `owns` line, no `CONFLICT:` line, no `BASELINE-REVIEW:` line — all three
correct for an item whose `## Couplings` carries an empty `owns:` and an empty
`consumes:`.

The revision note, the finding-to-repair table and the revision history make the
round-1 verdict and every repair auditable from the file itself. The artefact
discipline is stated and holds: new check ids are prefixed `R` so they cannot
collide with revision 1's `A` and `S` ids, and I found no collision.

The new log's figures are stated within what it shows: 35 `PASS` lines, zero
`FAIL`, zero `SKIP`, and a summary reading `assertions run : 35 / failures : 0 /
skipped : 0`. Section C's description of what each section establishes matches
the log's own section banners and assertion text. The rerun disclosure is
precise in an unusually careful way — the filtered comparison is empty, the raw
diff happened to be two lines on this same-UTC-day rerun, and the decision
insists the filtered rule is still the operative one because the responsiveness
window moves.

The six unproven rows of revision 1 are intact and a seventh is added for the
R67 reading. `## Engines` gains an accurate new paragraph recording that both
raw reports carried the stdout contradiction, that revision 1 inherited it, and
that Codex's own acceptance criterion 2 reached the right shape without it.
Every figure still carries its endpoint and retrieval date.

## Findings

**No unresolved findings.** Every round-1 finding is closed on new evidence, the
repairs introduce no new claim I could not verify at source, and the diff is
only what the revision note says it is.

Two precision notes, recorded for the controller and deliberately **not** raised
as findings, on the treatment R18/R45 and R64 established: neither changes a
selection, an exclusion, a parameter, an acceptance criterion or the disposition,
and editing the decision for them would unbind this audit for a further round.

1. **An acceptance-process consequence, not a defect.** Accepting revision 2
   ratifies R62's reading of a clause that sits inside another item's registered,
   owner-accepted value — `docs/port/PARAMETERS.md` carries the
   `error-taxonomy-exit-codes` row with the byte-empty clause in it. The decision
   has done everything a decision can do: it states the clause is not literally
   satisfied, argues the scoping reading on three grounds, writes out the exact
   substitute wording the other reading would require of R67, addresses the
   controller by name, and records unproven row 7 saying the reading is its own
   and not an owner ruling. What remains is a controller act under RUNBOOK §4 —
   record the disposition with R67's owner at acceptance, or put the one-sentence
   qualification to the owner. I flag it so acceptance is a decision rather than
   a side effect; it is not something revision 3 should try to fix.
2. **One citation reads slightly ahead of its source.** The sentence *"The org
   standard binds above R67 (owner ruling 2026-09-14)"* cites an entry that
   confirms the standard "governs this template" and notes that R67 is published
   relying on its rule R6.1; the precedence over R67's own wording is R62's
   inference from those two facts, and a sound one. Unproven row 7 already labels
   the whole reading as this decision's rather than the owner's, so the honesty
   is present where it matters; only the parenthetical reads more directly than
   the entry does.

I also record, since it corrects my own round-1 text rather than the decision's:
`raw/opus.md` numbers Member 2's ranked runner-up **Alternative 2b**, not 2a as
my round-1 audit wrote when describing it. Revision 2 and check `R25` have it
right and say so explicitly.

## Assessment

Nothing moves. The three members, `arboard` 3.6.1 with `default-features = false`
and `wayland-data-control` optional behind a default-on `clipboard` feature, the
binary-crate-only placement, the library-side `ClipboardPort` and
`ClipboardError`, the `cfg(target_os = "linux")` probe-then-re-exec helper, the
fatal failure policy, the four `- assumes` lines and every verdict in `## Engines`
are exactly what revision 1 recommended. What changed is what the round-1 audit
asked to change and nothing else: one acceptance criterion, the prose that
repeated it, four citations corrected to what their sources actually say, three
omissions supplied, and one new subsection that states a cross-item tension the
programme had not previously had to face.

The blocking finding is fully answered. Revision 1 asserted two acceptance
criteria that could not both be satisfied and claimed conformance to a clause its
own design contradicts; revision 2 states the design's real stream behaviour,
proves it from the binding standard at each rule's own scope, quotes the R67
clause at both of its locations, takes a reasoned and overrulable position on it,
and writes down the edit that would be needed if the position is overruled. The
supporting repairs are evidenced rather than asserted, and JF-3's in particular
weighs a figure that tells against the recommendation instead of omitting it.

This decision approves. Acceptance additionally requires the deferred empirical
audit's verdict and the controller's disposition of precision note 1.
