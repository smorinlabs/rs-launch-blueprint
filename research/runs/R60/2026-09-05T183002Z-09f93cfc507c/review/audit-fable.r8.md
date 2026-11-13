decision-sha256: 9407f1049d6127f4da80c399a2c9925f5a02a14c87e5c82b7050d20cc0b69342
actor: audit-fable-2026-09-05T183002Z-09f93cfc507c-r8
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: F8 — `## Empirical check` states that `r60-preservation-diff-r7.sh` run on the revision-8 tree exits `3` with `FAILURES: 3`, naming `C4k9` as a third failure and saying "The number is taken from the run"; the committed revision-8 text reruns it at exit `2`, `FAILURES: 2`, with `C4k9` passing — it passes because this decision quotes the superseded sentence the check matches, so the recorded measurement does not reproduce

This audit binds revision 8 at the full sha256 above, which I hashed from
`review/DECISION.md` before reading it. My round-7 report is archived
byte-identical at `review/audit-fable.r7.md` (sha256
`7e238e0ec9924d3360d39617cd1b1b5694b87529975f57d706b9d32bcde3426b`); nothing it
found is withdrawn, and all four of its findings are closed below. The round-8
empirical audit owns the reruns; I reran five scripts anyway, because three of
this revision's claims are claims *about* rerun results and one of them is the
finding below.

**F4, F5, F6 and F7 are all closed, and F6's repair moved the recommendation in
the direction the evidence pointed.** The single finding is a misstated rerun
result in `## Empirical check`. It touches no conclusion, no crate, no
parameter and not the `string` removal.

## Principle and agreement level

Nothing at this level moved, and nothing needed to. P1 through P7 stand as
revision 7 had them, with three citation corrections inside P3, P4 and P7 that
change which line is named and not what any rule says. I re-read each corrected
line in the committed pinned snapshot rather than taking the row: R4.1's
required global core is at `:238` and the `:237` heading names no tier; R3.8's
`--some-flag` ↔ `TOOL_SOME_FLAG` transform is at `:221` and the `:220` heading
carries none; R9.1's "for at least bash, zsh, and fish" is at `:484` and is
absent from the `:483` heading. Each correction keeps the wrong number in the
text and labels it wrong, which is the right disposition and the one this
document has used since revision 4.

The new material at this level is `wrap_help`'s ground, and it is a genuine
fitness argument rather than a restatement of practice. R7.3 `(SHOULD)` at
`:390` reads "A tool **SHOULD** detect whether stdout is a TTY and adjust
*presentation* accordingly" and R7.5 `(MUST)` at `:398` requires structured,
sectioned help; I verified both lines. The inferential step — that help *width*
is presentation — is the decision's own and it is made in the open rather than
smuggled, and it is joined to clap's documented behaviour rather than asserted:
`Command::term_width` says the width "Defaults to current terminal width when
`wrap_help` feature flag is enabled. If current width cannot be determined, the
default is 100" at `command.rs:1375-1376`, and `:1389` adds "**NOTE:** This
requires the `wrap_help` feature". Both lines are exactly where the decision
says they are in the hash-verified snapshot. This is the weakest of the three
surviving grounds, because R7.3's own examples of presentation are spinners,
pager and prompts rather than help width, and the decision does not pretend
otherwise — it argues the step. That is what spec §2 asks for when it says other
source choices "require a fitness argument", and it is a different kind of claim
from "`casey/just` ships exactly this feature set".

## Design and evidence

**The `string` removal is evidence-grounded, and I checked every link in the
chain rather than the summary.** The argument has two halves and both hold.

The first half is that the only reasons ever written for the feature are dead.
Opus gave two — "`string` because owned `String` values are needed for
`long_version` built at runtime and for any `mut_args` post-pass"
(`raw/opus.md:432-438`) — and this decision killed both in rulings made for
other reasons: `Command::long_version` left the stack when the owner selected
option (b) on 2026-09-14, and the F267 row now reads "**No
`Command::long_version`**"; the `mut_args` post-pass is what R5.4's `MUST NOT`
at `:322` excludes, and this decision says so explicitly while conceding clap
*can* express it. A feature whose only justification is an API the decision
forbids and an API the decision removed has no justification. That neither
removal noticed it was taking `string`'s ground with it is stated plainly
instead of being smoothed over.

The second half is the search for a replacement ground, and it is recorded as
checks rather than asserted. I reran `r60-feature-ground-r8.sh` myself: exit
`0`, `CHECKS RUN: 28 FAILURES: 0`, diffing empty against its committed log. Its
three reads are each true against the committed snapshots, which I verified
independently:

- `feature = "string"` occurs **exactly four times** in the committed
  `command.rs`, at `:264`, `:265`, `:395` and `:396` — two `#[cfg_attr(…)]`
  doctest pairs — and the APIs they document are `Command::mut_args` at `:296`
  and `Command::mut_subcommands` at `:426`, which are the API R5.4 excludes and
  its subcommand twin. I counted the occurrences and read both declarations.
- `clap_derive-4.6.4`'s `item.rs` gates **nothing** on the feature (I confirmed
  the count is zero) and routes `default_value_t` — the one derive attribute
  that turns a runtime value into a clap attribute — through a
  `static DEFAULT_VALUE: ::std::sync::OnceLock<String>` at `:588` narrowed by
  `let s: &'static str = &*s;` at `:593`, under the `MagicAttrName::DefaultValueT`
  arm at `:552`. All three lines read exactly as cited.
- `clap_complete 4.6.9` takes `clap` with `default-features = false` and
  `features = ["std"]`, so it pulls nothing in.

**The limit is stated where a weaker decision would have generalized.** The
claim is not that no API in `clap_builder` is gated on `string` — one file of
that crate is committed here — but that the two string-gated APIs in the
snapshotted file are the two this decision rules out, and that the three
mechanisms the design actually uses reach clap without an owned `String`. That
is the correct scope for the evidence held, and it is in the script's header as
well as the decision's prose. Against the design as decided the conclusion also
holds on inspection: the version string is `CARGO_PKG_VERSION`, the alias, the
env names, the subcommand names and `global = true` are all literals, so no
owned `String` reaches clap anywhere in this template.

**The removal is stated so the owner can decide it, which is the part that
matters most.** The revision note opens with it in bold — "THE RECOMMENDATION
MOVES, in exactly one place, and that place re-asks the owner rather than
re-binding his acceptance" — and then does four things that together make the
decision reviewable rather than announced. It quotes the governing rule from
`docs/port/OWNER-ACCEPTANCES.md:18-22`, which I read: a revision that "moves the
recommendation, a selected crate or version, or an owned parameter value stales
the acceptance and the item is re-asked". It names the accepted row and hash
(`:55`, revision 7 at `67d7a7d2…`, accepted 2026-09-15) — and that row already
carries "STALE from 2026-09-16: revision 8 removed the clap `string` feature (no
surviving ground); re-ask pending its audits", so the owner-facing record and
the decision agree. It quotes the superseded four-feature line verbatim so the
change is visible rather than silent, marks the stack-table row "three features
as of revision 8", and strikes `string` in the new feature table with "nothing"
in the column for what needs it. And it states the second consequence without
being asked: the `casey/just` practice evidence no longer shows identity but
containment, corrected in place beside the sentences that claimed identity.
An owner reading only the revision note can see what changed, why, what it
costs and that his acceptance is not being re-bound. I have no finding here.

The `clap-minimal` row F4's sibling finding named as omitted is now in
qualification 3 at 377 KiB / 2 s / 155 ms, cited to `raw/opus.md:209-215`, and
the decision does the harder thing with it: it reads the row *against* itself,
observing that dropping clap's defaults is a bigger lever (~219 KiB, ~2 s) than
either feature it adds, and then says why the defaults nonetheless stay —
`suggestions` is F272's mechanism, `help`/`usage`/`error-context` carry R7.5's
help and R67's messages. It also states that **no log in this run carries that
row**, which is the honest provenance and exactly the kind of limit a decision
is tempted to leave out.

**The two declared variances are real and honestly scoped. I reran both.**
`r60-standard-pin-r5.sh` exits `1` at `CHECKS RUN: 128 FAILURES: 1`, failing
`C16f` and nothing else; `C16f` requires `research/CLAUDE.md`'s R66 row to read
`| open |` and that row now reads `| resolved |`, which I confirmed at
`research/CLAUDE.md:71`. `r60-snapshot-provenance-r4.sh` exits `2` at
`CHECKS RUN: 17 FAILURES: 2 UNREACHABLE: 0 UNVERIFIABLE-HERE: 2`, failing the
two checks that require an anonymous fetch of a `ts-launch-blueprint` file to
return HTTP 404. Both failure sets are exactly what the decision says they are,
both causes are outside this item, and the scoping claim — that every
proposition either log is cited for is carried by a check that still passes,
and the three that fail assert facts about the outside world rather than about
the standard, the crate sources, the parameters or the owner's ruling — is
accurate as far as I could test it. The decision is also right that the
provenance change is the good direction: the two ts snapshots are now
refetchable by anyone, where before only their hash and pin stood behind them.
Leaving both scripts byte-identical is correct for the reason revision 6 gave.
Declaring this rather than letting the next auditor discover it on rerun is the
behaviour the item should have.

## Completeness

The four H2s are present and in order and `## Supersedes` is correctly absent.
The four `assumes` lines are byte-identical to `docs/port/PARAMETERS.md`, which
I re-diffed, and the decision's new assertion that the registry carries exactly
four `fixed` rows at `:7-10` is correct. Rows E14 and E15 are new and both name
the script, the log and the limit of what they establish. U9 is added for gate
2's unread CI half and is correctly worded; U2's feature set is corrected to
three. The `re-verify:` line gains the two mechanical triggers and keeps the
rest.

I reran the three new or reissued scripts. `standard-lines-r8.sh` exits `0` at
`49/0`, `r60-feature-ground-r8.sh` at `28/0`, and
`r60-preservation-diff-r8.sh` at `239/0`, **each diffing empty against the log
committed beside it**. `C1y`/`C1y0` extending the live-path prohibition to
`review/audit-fable.md` is the right call and is a class repair rather than an
instance one: that path did not exist when `C1x` was written, and writing a
control that named only the path which had already burned this item three times
would have been the same mistake a fourth time. Closing revision 7's declared
gap by reading the round-6 report at its now-archived name is likewise correct.

**F4 — closed, and over-delivered.** Row E5's scope is narrowed to exactly the
twelve specs `C8` reads, and the row now names which two of those twelve assert
a *heading* and says plainly that this is why the finding could be true while
the check passed. The class repair is the new `standard-lines-r8.sh`, which
reads each cited rule's body, asserts the proposition the decision rests on it,
and pairs each with a negative assertion that the heading above does not carry
that text — the negative half being what makes the check non-vacuous. `L20` is a
census over every rule id the document names, with a probe control, a minimum
count and an exemption list pinned at one entry. The decision states `L20`'s own
limit (it proves a body is read, not that it is read for the right proposition)
and records why a purely lexical citation census was tried and rejected. My
round-7 report named three wrong citations; this revision found and corrected
five, the two extra being R3.8 and R4.1. I verified all five.

**F5 — closed.** The unmeasurable sentence is kept and corrected in place, and
two triggers are appended to the `re-verify:` line in the same mechanical style
as its others: no `clap` release published by 2027-02-06, derived from `4.6.6`'s
`created_at` of 2026-08-06 and the prompt's own six-month rubric with the
endpoint and field named, and explicitly a trigger to investigate rather than a
verdict; and U2's `cargo build --timings` measurement showing the clap-family
crates on the critical path, which restores the trigger Opus set and the
synthesis had dropped, cited to `raw/opus.md:443-447`. Both say they reopen the
A-versus-D comparison and settle U7 first, and neither switches crates alone.

**F6 — closed; see `## Design and evidence` above.**

**F7 — closed, with a correction to my own count.** Qualification 5 states, in
the same words qualification 2 uses for gate 4, that no CI configuration was
read in this run; names every candidate passed on the declaration half alone;
and says what would discharge the clause per candidate. It states the asymmetry
in both directions, and the second direction is the part I had not spelled out
and it is right: reading the CI half could downgrade a pass but could never
overturn an exclusion, because a crate declaring no `rust-version` fails a
both-halves gate whatever its CI does. U9 carries it. The R64 citation is used
carefully — named as a rule R64 states about a crate it *excluded*, not as a
precedent for how a pass is granted. My report named five candidates passed on
the declaration half; there are six, `vergen 10.0.3` being the sixth, and the
decision corrects me rather than adopting my number.

## Findings

**F8 — the recorded result of rerunning `r60-preservation-diff-r7.sh` against
this text does not reproduce, and the paragraph that records it claims the
number came from the run.** `## Empirical check` states: "`bash
review/evidence/r60-preservation-diff-r7.sh` run on the revision-8 tree → **exit
3**, `CHECKS RUN: 183 FAILURES: 3`, failing exactly three checks", listing the
`clap 4.6.6 pin and its four features` preservation call, `C4h`, and third
`C4k9`, "which requires the unproven table's preamble to read 'U1–U7 are
unproven and are P03's to prove'". It emphasises that third one: "**This one was
not predicted**: the draft of this paragraph named two failures, and the run
named three. The number is taken from the run."

Run against the committed revision-8 text, that script exits **`2`** with
`CHECKS RUN: 183 FAILURES: 2`. The two failures are the preservation call,
reported as `CHANGED    clap 4.6.6 pin and its four features (1 of 1 revision-1
line(s) no longer verbatim)`, and `C4h`. **`C4k9` passes**, printing `PASS  C4k9
the unproven table says which rows are still unproven`.

The cause is this document's own supersession discipline, which is why the
finding is worth stating precisely rather than as a typo. `C4k9`
(`r60-preservation-diff-r7.sh:799-800`) matches the literal string `U1–U7 are
unproven and are P03's to prove` against the **flattened whole decision**. The
unproven table's preamble did change, to "U1–U7 and the new U9 are unproven and
are P03's to prove" at `:2251`. But revision 8 also quotes the superseded
sentence — correctly, per the charter's rule that a superseded record is
corrected in place and labelled — inside the very paragraph that reports this
rerun, at `:2008`. The check searches the whole document, finds the quotation,
and passes. The revision-8 script's `C4o28`, which requires that quotation to
stay beside the new wording, is what guarantees it will keep passing.

So the likeliest history is that the run was performed against a draft that did
not yet carry the quotation, the quotation was then added, and the paragraph was
not re-run. **That is finding F3's class in its second appearance** — a stated
failure set contradicted by the rerun — and this time it sits inside the
sentence asserting that the number was measured rather than predicted. The
irony is exact and should be recorded in the repair: the discipline that makes
this document trustworthy is what defeated the check, and only re-running after
the last edit would have caught it.

**Nothing else moves.** The first two failures are correct as stated, and the
reading placed on the first is right and worth keeping: the preservation call
failing is the recommendation moving, and it is the only failure in eight
revisions that is not a title check or a report path. **Repair:** rerun
`r60-preservation-diff-r7.sh` against the final committed text, record exit `2`
and `FAILURES: 2`, and replace the `C4k9` item with the reason it survives —
that the superseded sentence is quoted at `:2008` and the check reads the
flattened document — keeping the falsified three-failure sentence in place and
labelled, as this document does with every superseded claim. The `C4o28`
assertion already makes the survival a property the script guarantees, so the
corrected text can say so.

## Assessment

Reject on one finding, and it is a narrower rejection than any this item has
had. Revision 8 answers all four findings of the first judgment audit, and
answers three of them beyond what was asked: F4 was asked for a class repair and
got one plus two corrections I had missed; F5 was asked for a measurable trigger
and got two, both wired into the `re-verify:` line; F7 was asked for a stated
limit and got the limit, a U-row, the correct reasoning about what the unread
half can and cannot do, and a correction of my own count. F6 was asked for a
ground per feature and produced the right answer to a question that had a real
cost attached: one feature had no ground, so the feature is gone, the
recommendation moved, and the owner is re-asked rather than his acceptance
re-bound. Removing something because its justification did not survive scrutiny
— when keeping it would have been invisible and free — is the behaviour the
research mandate exists to produce, and the removal is grounded in reads I
repeated myself rather than in a summary I was asked to trust.

The variance declaration deserves the same note. Two scripts stopped
reproducing for reasons outside this item, and the decision found that itself,
reran both, reported the exact failing checks, explained each cause, scoped what
it does and does not cost, and left both artifacts byte-identical. I reran both
and the report is accurate.

F8 is the one place where a claim outran its evidence, and it is a claim about
evidence rather than about `clap`, the standard, the parameters or the owner's
ruling. It is a single paragraph to repair, it requires no new script — the
revision-8 script already guarantees the condition that makes `C4k9` pass — and
the corrected text should say what the miss teaches, which is that a rerun
recorded before the last edit is a prediction wearing a measurement's clothes.
Fix that paragraph and this item is done on judgment; the owner's re-ask on the
three-feature set is the only thing standing between revision 9 and publication.
