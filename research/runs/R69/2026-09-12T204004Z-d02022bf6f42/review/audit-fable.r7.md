decision-sha256: a64addcff304770e9c114d05d974da4aaa9395e9095dff2f86823a45a29dfcfe
actor: audit-fable-2026-09-12T204004Z-d02022bf6f42-r7
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

# R69 web-framework-stack — judgment audit (round 7, revision 7, 2026-09-16)

Round 6 (archived byte-identical at `review/audit-fable.r6.md`) rejected revision 6 on one
finding, JF-4, and recorded JF-1, JF-2 and JF-3 as closed with three observations marked
explicitly as *not* findings. This round audits revision 7 as a delta: I diffed it against
revision 6 (`git show 10a83c4:…/review/DECISION.md`, sha256
`d4d6a8d2a3297a6db488580142de6d651f33b8109e9023994f6cb9f5ecfd6a17`, recomputed here), confirmed
that the diff is only what the revision note claims, and carried forward round 6's conclusions
for every passage the diff does not touch.

## Principle and agreement level

Untouched by revision 7, and therefore as round 6 found it. The `unified diff` has six hunks —
the title, the new revision-7 note plus the revision-6 note's replaced heading, the synthesizer
line, the flag-surface paragraph, the `re-verify:` line, and the global-core row of the unproven
table. None of them reaches the capability-level framing, the `COMMONALITY.md` and
`DIVERGENCE-ANALYSIS.md` citations, the F330 and F331 analyses, either `BASELINE-REVIEW:` line,
the withdrawal of the opus raw's `F339` line, the absence of a `CONFLICT:` line, or the
owner-supplied document's recorded standing as an input rather than an authority. The owner
decision 11 reconciliation that round 6 checked row by row is byte-identical.

## Design and evidence

**JF-4 is closed, at all three locations the finding named and in the form round 6 asked for.**

1. *The flag-surface paragraph* (revision 6 line 908, now 990–996). The superseded wording is
   quoted — *"on a condition rather than as a present fact: the parser is R60's open choice, and
   whichever crate R60 selects for the CLI binary is a non-optional dependency of the package"* —
   labelled superseded, and replaced by the accepted fact cited to its record:
   `docs/port/OWNER-ACCEPTANCES.md` R60 revision 7, sha256
   `67d7a7d2a76c7d10c88edf9cd309c46484ada95a00074d902943a94410b8b9f2`, accepted 2026-09-15 as
   "W0-R60 option A; `clap` 4.6.6 derive, `clap_complete` 4.6.9, dependency-free `build.rs`",
   publication pending. I re-read that row and it matches the quotation. The paragraph now states
   the design consequence as a present fact and says the accepted answer strengthens rather than
   weakens it, which is the reading round 6 recorded.
2. *The unproven row* (revision 6 line 2105, now 2195). The row keeps **Unproven** and replaces
   the false second ground with a true one — "the R9.14 conformance fixture has not been
   written" — with the superseded wording quoted in a parenthetical and its supersession sourced.
   That is exactly the repair round 6 specified: correct the ground, do not promote the row.
3. *The `re-verify:` line* (revision 6 line 1378, now 1468). The fired clause is replaced rather
   than deleted. My diff of that line confirms the note's claim that every other clause is
   byte-identical; only the R60 clause changed.

**The new clause is meaningful and mechanical, and it is a better trigger than the one round 6
proposed.** It reads "when R60's published decision moves off its owner-accepted clap 4.6.6
derive selection for the CLI binary the serve binary's global core is parsed with". Round 6
suggested "when R60 publishes", matching the R58 and R02 verb; the clause as written is
narrower and more useful, because publication that carries the accepted selection changes
nothing here, while publication that carries a different parser would reach the R4.1 help layout
and the `-V` single-line format this decision binds to R60. It is checkable the same way its
neighbours are — read `research/topics/60-cli-parsing-framework/DECISION.md` when it exists and
compare its selected parser against `clap` 4.6.6 derive — and it is watching a live gap: R60's
run file is already at revision 8, past the accepted revision 7, which the note says and which I
confirmed (its current sha is `117f5273…`, not the accepted `67d7a7d2…`, and revision 8 still
reads "still `clap 4.6.6` with the `derive` API, `clap_complete` is still `4.6.9`").

**Nothing in the recommendation, the evidence or the gate answers moves, and I verified that
from the diff rather than from the note.** No hunk touches `## Parameters`, the member table,
the exclusions, the fitness-gate tables, the empirical-check narrative, the unproven table's
other ten rows, `## Engines`, or any script, log or snapshot. Both revision-7 commits
(`3e4c086`, `1187133`) change exactly one file, `review/DECISION.md`, so the note's "**No
evidence file is added, edited or replaced**" is verified at the commit level.

**The round-6 conclusions therefore stand unchanged**: JF-1 closed by the R67 process-contract
table and the append-only catalog request, verified at R67's published file at its cited sha;
JF-2 closed by the conditional alternative-E and `ntex` grounds; JF-3 closed against the CLI
Design Standard v1.4.14's own R4.1 required-global-core table; the drain-deadline clock rule, the
bacon SIGKILL override and the yanked-lookup and advisory-db pinning each stated with their
limits; the R01 coupling verified narrowly and labelled narrow.

## Completeness

- **Parameters.** I re-derived all five `- assumes` values from `docs/port/PARAMETERS.md` and
  compared them exactly: byte-identical, as in round 6. The `- owns web-extra-surface` line is
  unchanged by the diff and still carries no backtick, no markdown link, no double space and no
  leading or trailing whitespace. Round 6's ruling that the value's *"the parser crate R60
  selects for the CLI binary"* wording "survives the correction verbatim" is the ground the note
  gives for leaving it, and it is quoted accurately.
- **H2 set.** Exactly `## Decision`, `## Parameters`, `## Empirical check`, `## Engines`, in
  order, both fence-aware and by the naive `^## ` scan `parameters-check.sh` performs; no
  `## Supersedes`, correctly, since no revision has been published.
- **Check 6's claimed rerun is consistent by construction.** I read
  `review/empirical/parameters-check.sh`: it reads `review/DECISION.md` only through lines
  beginning `- assumes `, `- owns ` and `## `, and prints only those results plus two fixed path
  lines and a control. Revision 7 changes none of those inputs, so its output must diff empty
  against `review/evidence/parameters-check-r2.log`, which the note claims and which the
  round-7 empirical audit will execute. Leaving that log unchanged rather than writing an r7
  copy of identical bytes is the right call and is stated rather than left to inference.
- **The mechanical enumeration is exactly true, which I checked rather than accepted.** Running
  the note's two passes over revision 6 — `/usr/bin/grep -n R60` and a case-insensitive pass for
  `parser` — gives the union **469, 894, 895, 908, 1244, 1378, 1382, 1835, 2105**, precisely the
  nine the note lists. Re-running both passes over revision 7, every hit outside the revision-7
  note is one of those nine at its shifted line number (469→549, 894/895→976/977, 908→990–996,
  1244→1334, 1378→1468, 1382→1472, 1835→1925, 2105→2195) and no new hit appears anywhere else,
  which is what the note asserts. The six untouched locations each carry a stated ground, and
  each ground holds: 469 and 549 sit inside the retained revision-2 note and record what revision
  2 did, which remains true as history; 894/895 attribute who binds a behavior rather than
  asserting a selection state; 1244 and 1382 carry the wording round 6 ruled survives; 1835 is an
  evidence script's JSON parser.
- **The second commit's self-corrections are all improvements and all accurate.** Commit
  `1187133` changes six statements inside the revision-7 note, each from a recalled figure or an
  abbreviated citation to something a reader can check: the trigger count becomes "every other
  clause on that line is byte-identical, which a `diff` of the line shows rather than a count"
  (true, per my diff); "the other six checks read no part of this file" becomes "Checks 1
  through 5, and `yanked-control-r5.sh`" (correct — check 6 *is* `parameters-check.sh`); the
  round-6 empirical audit is now cited by actor, model, family and verdict, which I verified
  against `review/audit-codex.md` (actor `audit-codex-…-r6`, `gpt-5.6-terra`, openai, approve,
  no unresolved findings, bound to the revision-6 sha); the new `re-verify:` clause is quoted in
  full and unbackticked as that line is written; the "re-run after it" claim is made true; and
  "no clap feature list is named" is narrowed to "no clap feature set beyond `derive` is
  transcribed", which is correct — `derive` is itself a feature, and a scan of every `clap`
  occurrence in this file finds no other feature name. That is the discipline this programme
  asked for after revision 4, applied by the author to their own note before an auditor reached
  it.
- **The revision-6 note is retained as the record of that revision**, with its heading replaced
  to record the two round-6 verdicts and its body byte-identical — the same practice revisions
  3, 4 and 5 followed, and the diff confirms the body is untouched. The JF-4 text the revision-7
  note quotes is byte-verbatim from round 6's `unresolved-findings` field; I compared them
  programmatically.

## Findings

None. Revision 7 does what the single round-6 finding required, at the three locations it named,
and nothing else.

The three items round 6 recorded as observations rather than findings are unchanged and remain
observations: the owned value's "and 0 otherwise" clause, whose drain-deadline carve-out sits in
the same sentence (round 6 asked that it be reworded only if a future revision touched that line
for another reason — revision 7 correctly did not touch it); `axum-test`'s absence from
`## Decision`'s **Not selected** list; and the prose dates for issues #3809 and #3003 and pull
request #3745, which sit in the committed r6 snapshots but are not among the fields
`owner-reference-check-r6.sh` asserts. One new observation, also not a finding: the new
`re-verify:` clause's trailing relative clause now reads as attaching to "the CLI binary" rather
than to the parser, so "…selection for the CLI binary the serve binary's global core is parsed
with" scans awkwardly on a line that is deliberately unpunctuated; the event it names is
determinate, so nothing turns on it, and it is worth tidying only if that line is edited again.

## Assessment

Approve. The recommendation is where it was — `axum` 0.8.9 on `tokio` 1.53.1 behind one additive,
off-by-default `web` feature, `tower` 0.5.3 as a dev-dependency only, `bacon` 3.25.0 as the dev
watcher, `State` + `FromRef` over one `AppState`, a feature-gated `[[bin]]`, the `oneshot` test
idiom — and the `- owns web-extra-surface` value is byte-identical to revisions 2 through 6, so
the W0-R69 brief can be built on this sha without re-asking the recommendation question.

What revision 7 changes is a statement about a sibling item's settled state, and it changes it in
the direction that makes the surrounding claim stronger: the serve binary's R4.1 global core is
parsed with `clap` 4.6.6, a non-optional dependency of the package, so the `web` feature adds no
parser crate as a present fact rather than as a condition, and check 2's 12 → 52 delta stands by
construction. The repair is confined to the three locations, the six untouched `R60`/`parser`
locations each carry a ground that holds, the replaced `re-verify:` trigger is narrower and more
useful than the retirement round 6 proposed, and the author's own second commit corrected six
statements in the new note before an auditor saw them — including two counts written from recall,
the failure mode this programme rejected revision 4 for. Nothing in the text now overstates what
its evidence shows, and no finding remains open from any round.
