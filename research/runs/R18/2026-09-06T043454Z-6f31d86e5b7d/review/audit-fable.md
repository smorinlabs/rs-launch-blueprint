decision-sha256: c9e44318abbdf4131d0d8b575d318c442c8a89ff9fc8c573c8d92c5ecb441f2e
actor: audit-fable-2026-09-06T043454Z-6f31d86e5b7d-r7
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

The file under audit still titles itself "revision 6". The controller ruled that
the number does not matter and the hash does. I bound the hash above: the file
at `review/DECISION.md` hashes to `c9e44318abbdf4131d0d8b575d318c442c8a89ff9fc8c573c8d92c5ecb441f2e`,
which is the hash my task named, and every statement below is read from those
bytes. I refer to the entry as "revision 6" throughout, matching its own title.

## Principle and agreement level

Unchanged from revision 6 and unchanged by the JA-06 correction, which touched
no part of the principle argument. The level is **policy or mechanism** under
spec §2, cited to the §2 table with its definition quoted and argued from §2's
"with its owner decision or evidence" clause rather than from a rank. My
predecessor examined that assignment at the revision-6 hash and found it
defensible: the owner's 2026-09-12 direction settles how the `rs` template gates
the two files without registering the pair as a value deliberately shared across
`py`, `ts` and `rs`, and `ts-launch-blueprint` still ships neither file. The
correction's fifteen hunks are fully enumerated below and none of them lies in
that argument, so the assignment and observation 1 that depends on it stand as
approved.

The guard contract is still the thing held to agree. Clause (b) is true of both
lanes; clause (d) is the owner's deliberate choice of `author_association` over
a write-permission check, and what `author_association` does not do is still
stated alongside it. The correction adds one clause to what an adopter is told —
that the guard contract can be entered with no act of acceptance at all — which
strengthens rather than weakens the honesty of that handling.

## Design and evidence

**Does the JA-06 fix close the gap it names, or only document it?** It does both,
in the only division of labour this programme permits, and it is explicit about
which half is which.

What it closes: the decision no longer *claims* the gap is absent. Round 6
rejected on three claims that were false for an adopter whose repository already
carries `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` for an unrelated
purpose. All three are now qualified in place, and the qualifications are
accurate:

1. The recommendation's "installing a credential is itself the act of
   acceptance" now carries, in the same sentence block, "**One case that
   sentence does not cover** … an adopter whose repository already holds
   `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` for an unrelated purpose
   takes no act of acceptance at all, sees nothing printed, and gets both lanes
   live on the next qualifying event."
2. "puts that statement where the person installing the credential will see it"
   is followed, in the same paragraph, by "**One case defeats the two sentences
   above** … **and it is stated next rather than left implicit.**" I word-diffed
   that paragraph against the revision-6 bytes: the edit is purely additive, one
   appended sentence, with nothing removed and nothing softened. The concluding
   owner-risk sentence — "Whether a bounded, unremovable exposure on a
   write-capable lane is acceptable is an owner risk judgement, not an
   engineering-fitness one" — survives untouched.
3. The preflight description's unconditional "It prints through both channels a
   reader actually sees" is now scoped: "**On the `shape = none` branch, and only
   there**", with the other branch's single line of ordinary log text named and a
   cross-reference to the new paragraph.

What it documents rather than closes: the exposure itself. That is correct and
not evasion. The owner's direction is unchanged and this exposure is its
consequence, so the decision's job is to state it truthfully, not to legislate
around it. It states it as the **larger of the two new costs** — adopting round
6's own framing — and names who owns the residual in it: "it is taken **by
default rather than by choice**, and it is owned by whoever created the
repository from the template rather than by anyone who made a decision about
these two files."

Most creditable, and the reason I do not treat this as documentation-only: the
decision refuses to pretend its own remedy reaches this adopter. It says in
plain words that "The only surviving channel is the fixture header, which is the
one file this adopter has no reason to open," and that "the stated opt-out,
deleting the file, cannot be chosen by someone who does not know there is
anything to refuse." A revision that wanted credit for a fix would not write
that sentence. The actual closing fix — printing on the `else` branch — is
routed to P03 as "a one-line change to a printed string, changing no gate and no
permission", which is exactly the form round 6 offered it in and exactly what the
programme rule requires of a research phase.

**Is it in the place an adopter will actually see?** The fixture headers are what
gets copied, so I read both. Each gained six comment lines inside the
`WHAT AN ADOPTER ACCEPTS BY INSTALLING A CREDENTIAL` block, identical in both
files:

```
#   AND IF THE CREDENTIAL IS ALREADY THERE, NOBODY ACCEPTS ANYTHING: a
#   repository that already holds ANTHROPIC_API_KEY or CLAUDE_CODE_OAUTH_TOKEN
#   as a secret for any other purpose gets this lane live on the next
#   qualifying event with no act of acceptance taken and nothing printed — the
#   notice below fires only when NO credential is found — so everything listed
#   here is accepted by default rather than by choice.
```

That is the block's most prominent possible placement for this fact: it sits
inside the block whose title it contradicts and corrects the title in place. It
is one entry in each fixture, as round 6's remedy specified.

**Is the claim reported rather than reasoned?** Yes, and I checked the report
against the artifact. `actionlint.log` block R6-10 extracts the preflight's
detecting step from the review-lane fixture and runs it twice under a shell that
mimics the runner, with separate empty `GITHUB_OUTPUT` and `GITHUB_STEP_SUMMARY`
files per case so both are measured rather than inferred. With no credential:
`credential=none`, one `::notice` line, 544-byte step summary. With a
pre-existing `ANTHROPIC_API_KEY`: `credential=static`, **zero** notice lines,
**zero** bytes of summary. The block's own `diff` proves the extracted script is
the fixture's step body (exit 0). I confirmed the source lines myself: the step
body is lines 136–160 of `candidate-claude-code-review.r5.yml`, the
`if [ "${shape}" = none ]; then` is line 145, the `else` is 158, the ordinary log
line is 159 and the `fi` is 160 — which is the citation the decision prints and
the reason its "one line of ordinary log text and nothing else" is exact rather
than approximate. And I confirmed the gate the fixture body carries:
`needs.credential-preflight.outputs.credential == 'static' || … == 'federation'`,
which is true on `static`. The finding was executed, not argued.

**Is there an eighth unqualified copy?** The sweep paragraph claims exactly seven
locations carry the acceptance claim, that six were edited and that fact (2) was
deliberately left byte-identical with the qualification naming it instead. That
is the shape this programme has rejected on before, so I swept independently
rather than accepting the count, over the current entry only (everything before
the first `## Supersedes` line), for `act of acceptance`, `whoever installs`,
`will see it`, `moment they install`, `is itself the acceptance`,
`installing a credential is`, `the switch` and `ACCEPTS BY INSTALLING`. Ten lines
match, and every one is accounted for: the recommendation (9), the section
opening (57), fact (2) (60), the "Given (1) to (4)" paragraph (64), the new JA-06
paragraph (66), B4 (112), the directory-change paragraph's mention of the header
block by name (293), change-table row 7 (349), the sweep paragraph itself (357)
and `## Engines` disagreement 1 (374). The preflight description does not match
these patterns because its wording is different; I read it directly and it is
scoped. **No unqualified copy survives.** Fact (2) is byte-identical to its
revision-6 form, which is what the decision says it did and why.

**Byte-preservation — verified, not accepted.** This programme has rejected two
decisions for false byte claims, so I ran every one of these rather than reading
them:

| Claim | How I checked it | Result |
|---|---|---|
| Both fixtures' YAML bodies byte-identical from the `name:` line onward | `awk 'f||/^name:/{f=1;print}'` on the current file and on the pre-correction blob `c9bf1c4`, `shasum -a 256` on each | review lane `054ebd1a…` = `054ebd1a…`; assistant lane `da416f18…` = `da416f18…` |
| Only the comment headers changed | full-file `diff` against the `c9bf1c4` blob | one hunk per file, six added comment lines each, **nothing removed**, no YAML key, expression, permission, trigger or pin touched |
| The `## Supersedes` block is the published revision verbatim | extracted from the preserved entry's `# R18 …(revision 5, 2026-09-10)` heading to EOF, hashed, and `diff`ed against `research/topics/18-ai-assisted-review-workflows/DECISION.md` | 371 lines, **152,934 bytes**, `b45a17a342bfa49689c3571e71c14ab55c2fa64e0f9337032876739babdae205`, **`diff` exit 0** |
| The three residual spans are unchanged | extracted from the current entry and from the published revision-5 bytes by the log's own opening and closing anchor text, hashed | span A **1133** bytes `57bc88e3…`, span B **1302** bytes `bdd98b1a…`, span C **328** bytes `6cbb9ac2…` — each **identical** in both, and identical to the pre-correction entry |
| The four `- assumes` lines are byte-identical and now at 211–214 | `grep -n '^- assumes '` | 211–214 in the current entry and 623–626 in the preserved one, values matching `docs/port/PARAMETERS.md` rows 7–10 |
| The cited fixture line numbers are post-edit | `sed -n '145p;160p'` on both fixtures | both print `if [ "${shape}" = none ]; then` and `fi` |
| No stale `<fixture>:<line>` reference survives | `grep -o 'r5\.yml:[0-9-]*'` over the current entry | no output, exit 1 — the zero-match result the decision reports, and it reports it as such rather than as a printed zero |

Every byte-preservation claim in this revision is true. The pin, both `on:`
lists and both real jobs' `permissions:` blocks follow from the body-hash
identity above and are re-checked directly in `actionlint.log` R6-9, which also
reproduces the bot-check counts of 2 and 5 against the edited files.

**What the correction deleted.** A revision that answers a finding by adding
prose can also quietly remove a caveat, and the residual-span and `## Supersedes`
checks above would not catch that, because they cover three anchored spans, the
four `- assumes` lines and the preserved entry — not the fourteen paragraphs the
correction replaced. So I word-diffed the whole correction rather than reading the
added text and inferring the rest:
`git diff --word-diff=porcelain 4a863d8 957d515 -- review/DECISION.md | grep '^-'`
returns **twelve** deletions across the entire correction. Ten are word-level
adjustments forced by the additions — `It`→`On the shape = none branch … it`,
tense changes `stands`→`stood` and `created`→the superseded wording, `rows**,`→
`rows** at revision 6`, `R6-1–R6-4 and`→the three-capture list, and the comma
position where the `.r5` explanation was inserted. One is the editorial fix round
6 named, `**revision-5**`→`**revision-6**`.

The twelfth is the whole of `## Empirical check` row 20, and it is the one
deletion worth reading. I word-diffed that row in isolation: the only text
removed is the figure `207–210` and the fragment around it. The old row said the
four `- assumes` lines "moved from lines 179–182 to 207–210"; the log's own
`grep -n` prints **209–212**, so the figure written in the revision-6 text did not
match the evidence it cited. The correction fixes it, states that it was wrong —
"the figure `207–210` written here before the JA-06 correction did not match its
own log, which is corrected rather than left standing" — and adds the post-edit
figure **211–214**, which I confirmed independently. Everything else in that row
survives: the `b45a17a3…` blob hash, the P1–P8 results, the three span byte
counts and the P4 whole-file-versus-current-entry explanation with both counts.

**No caveat, quotation, evidence result or limitation was removed anywhere in the
correction.** The single substantive deletion is a wrong number the decision
caught in its own text and disclosed as wrong, which is the behaviour this
programme's byte checks exist to elicit.

**The two new acceptance criteria.** B4's added branch requires a repository that
"already holds `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN` as a repository
secret installed for an unrelated purpose *before* these two files land, and with
no other configuration performed", and asserts four things on the next qualifying
event: `credential=static`; the real job at `conclusion == "success"` **rather
than** `"skipped"`; **no** `::notice` annotation; and **no** `$GITHUB_STEP_SUMMARY`
block. U2's restatement asks for the same experiment and names it "the opposite
outcome".

Each of the four assertions is the strict negation of what the no-credential path
produces — `credential=none`, `skipped`, one notice, a 544-byte summary — as the
R6-10 execution measured. The criterion is therefore **not satisfiable by the
no-credential path**, and it is falsifiable in every clause: any one of the four
coming out otherwise fails it. It is a criterion, not a formality, and it is
scoped to the path round 6 said B4 did not reach.

**Recommendation, architecture, library selection, evidence handling.** Untouched
by the correction and approved twice before. The four architectures are still
compared before the vendor choice on transferability; the runner-up is an
alternative rather than a demoted option; nothing rests on repository agreement;
`doxa-gemini`'s "Python is the definitive reference architecture" framing is still
rejected as the failure the mandate exists to prevent while still being routed.
Check 21 remains turned on the decision's own attributions. No claim is made from
memory.

## Completeness

Required H2s are present, in order, with `re-verify:` the last line of
`## Decision` and `## Supersedes` last. I read the two governing anchors rather
than carrying the citation: the spec's line 516 lists `## Supersedes` as the one
H2 permitted "for reversals", and `RUNBOOK.md` line 190 reads "`## Supersedes`:
only for a reversal, with the prior dated entry preserved." The prior dated entry
is preserved verbatim, which is the condition I verified by hash and `diff` above.

`## Parameters` declares `owns — none`, consistent with R18's empty `owns:`
column in `research/CLAUDE.md`, and four assumed values that I compared against
`docs/port/PARAMETERS.md` rows 7–10 this round rather than inheriting the
comparison: `msrv-policy = stable minus 2 minor versions, raised only in a minor
release, declared as rust-version in Cargo.toml and tested in CI`,
`rust-edition = 2024`, `target-os-matrix = ubuntu-latest, macos-latest` and
`license = MIT OR Apache-2.0` each match the registry's fixed owner value
byte-for-byte, and match the chosen options recorded at `PARAMETERS.md` lines
24, 28, 32 and 36.
**No `CONFLICT:` line is emitted and none is owed**: the item consumes nothing and
challenges no owner-fixed value, and the decision says so at the point where the
line would go. R18 owns no parameter, so no descendant needs reopening for this
republication. Seven `BASELINE-REVIEW:` lines are carried in the required
`F### — principle — proposed change — evidence` form, including the seventh that
an anchored grep cannot see because `doxa-gemini` wrote it inside backticks; both
rejects are routed identically to both adopts; `doxa-openai`'s ledger-split ask is
routed as a ledger ask against F051 and F052 at `docs/port/COMMONALITY.md:57-58`
rather than answered. None of these was touched by the correction.

The bookkeeping the correction forces is done and each piece is verified rather
than asserted. The unproven list moves from eighteen rows to **nineteen** with
U19 added; I counted `U1`–`U19` in the current entry, and with U2 restated as B4
and U8 closed, **seventeen** remain open, which is what the decision says. The
`## Empirical check` table now prints rows in order — round 6's editorial defect
that row 21 preceded row 20 is fixed, and I confirmed rows 8–21 are sequential.
The minimal-example paragraph now calls the fixtures "the two **revision-6** lint
fixtures" and explains that "the `.r5` suffix is a fixture-generation counter, not
a revision number" — the second editorial defect round 6 named, fixed with the
explanation rather than only the label. Check 19 gains the third capture; check 20
records the `- assumes` line numbers moving again, to 211–214, which I confirmed.

Nothing implements the recommendation. There is no `.github/workflows/` tree in
the repository (block P8's failing `ls`), and both fixtures live under
`review/evidence/` with headers saying so. Declining to build the template is
correct and is not a deficiency.

**The empirical audit is consistent with the decision.** `review/audit-codex.md`
binds the same hash, approves, and its reproduced numbers match `actionlint.log`
R6-10 exactly: `credential=none` with one `::notice` and 544 bytes, against
`credential=static` with zero notice lines, a zero-byte summary and a true
`static || federation` predicate. It independently confirms that both fixture
changes are leading comments only, that each YAML body from `name:` onward is
byte-identical, that `check_history` accepts the preserved predecessor, that both
fixtures lint clean under `actionlint 1.7.12` with one `v1.0.220` pin each and no
negative predicate, and that the adopter-block entry is present in each copied
fixture. Its one environment limitation — the Lima VM could not start, so the
probe ran on macOS — is an environment fact, disclosed, and it bears on no claim
I rely on; it is the same limitation round 6 accepted. It correctly refuses to
present the fixture probe as a live GitHub Actions run, which is the distinction
B4 and U2 exist to preserve.

**Role-contract inputs I did not re-read, disclosed rather than left silent.**
`inputs/prompt.md` beyond its question list, the five raw reports in `raw/`,
`docs/port/PARAMETERS.md` beyond rows 7–10 and the option lines at 24–36, spec §2
beyond the level table and line 516, and `docs/port/BASELINE-REVIEW.md`. My
justification is stronger than a general appeal to the prior round. The
correction's diff against the twice-approved revision-6 hash is **fully
enumerated** — fifteen hunks, fourteen replaced lines and twenty added. I read
every added line in full, and I established the removals not by reading the
replaced lines but by word-diffing the entire correction, which is the stronger
instrument: the twelve deletions are itemised above and none of them removes a
claim, a caveat or an evidence result. No hunk lies in the raw-report synthesis,
the parameter block, the `BASELINE-REVIEW:` lines or the principle argument; the
four `- assumes` lines and all seven `BASELINE-REVIEW:` lines are byte-identical
to the revision-6 text. The correction makes no new claim about any raw report.
Everything the correction does change, I read from the bytes and checked against
the artifacts it cites.

## Findings

**None.** Round 6's finding JA-06 is answered, in the form round 6 specified: the
paragraph under "What installing a credential costs the owner", one entry in each
fixture's adopter block, and B4 scoped to require the pre-existing-credential
path. The optional part of that remedy — printing on the `else` branch — is routed
to P03 with the exact change named, which round 6 offered as an option rather than
a condition and which the programme rule protects.

Three non-blocking observations, recorded so the record carries them and **not**
as conditions of approval.

**(i) U19 and the privileged job's condition — see my explicit judgement in
`## Assessment` below.** Recording it as unproven and leaving it for P03 is
adequate.

**(ii) B4's activation assertion is over-strict in the safe direction.** The
pre-existing-credential branch asserts the real job reaches
`conclusion == "success"`. A credential installed for an unrelated purpose may be
expired, scoped elsewhere, or a placeholder; in that case both lanes still go live
with nothing printed — the finding is confirmed exactly — and the job finishes
red, so B4 as written fails on a run that demonstrated what B4 exists to
demonstrate. P03 should assert `conclusion != "skipped"` as the activation test
and record success or failure separately. This makes the criterion harder to pass
than the fact it tests, not easier, so it cannot hide the exposure and does not
change the verdict.

**(iii) The fixture block's title and its new entry disagree, by design.** The
block is titled `WHAT AN ADOPTER ACCEPTS BY INSTALLING A CREDENTIAL` and now
contains an entry beginning `AND IF THE CREDENTIAL IS ALREADY THERE, NOBODY
ACCEPTS ANYTHING`. The entry corrects the title in place and in the most visible
position available to it. Editorial only, and the contradiction arguably does more
work where it is than a retitled block would.

Both remaining residuals my predecessor recorded are carried forward unchanged and
neither is reopened: automation running under a User-type machine account is not a
`Bot` type and is bounded only by clause (d), and `## Engines` §2's "catches every
bot without enumeration" is true of Bot-type actors only. Both predate revision 6.

## Assessment

Approve, with no unresolved findings.

**Explicit judgement on U19 — the architectural note is adequately handled as an
unproven item, and is not a defect that must be fixed before acceptance.** Five
reasons, in descending weight.

First, **the gate is sound today; U19 is about a future editor, not a live hole.**
I verified the predicate on both fixtures:
`needs.credential-preflight.outputs.credential == 'static' || … == 'federation'`.
It is false for the empty string a skipped job publishes and false for `'none'`,
so the real job fails closed on a skipped preflight, a failed preflight and a
preflight that detected nothing — and `needs:` skip-propagation is a second,
independent leg. Every actor-trust clause does sit on the unprivileged job, and I
confirmed that directly: the review lane's preflight carries the fork, `draft ==
false` and two bot clauses, the assistant lane's carries five bot clauses and four
`author_association` branches, and each privileged job's `if:` carries only the
credential comparison. That is exactly what U19 says, stated without softening.
But the protection holds as written. A finding must name something the artifact
gets wrong now.

Second, **round 6 classified this as non-blocking observation (i), and no new
evidence has arrived since.** Its words were "this is a hardening recommendation
for P03 rather than a defect… Non-blocking; P03 builds the thing." The correction
did precisely what that observation asked — recorded it where it does not live
only in an audit — and cited the same evidence round 6 cited, the fixtures' own
corrected predicate. Escalating an observation to a blocking defect on a later
round, on the identical evidence, because the decision complied with it, would
make compliance costly and the classification meaningless.

Third, **duplication is not unambiguously the better fix, so deciding it in P03 is
the correct disposition rather than a deferral.** Two copies of a four-clause
actor test can drift silently in either direction — edited on one job and not the
other — and nothing detects that; `actionlint` can prove the duplicated condition
legal but, as the decision itself says, "cannot prove it equivalent to the
preflight's". The accompanying control U19 specifies —
`grep -c "outputs.credential != "` returning `0` for both files as a gate in the
template's own CI — fails **loudly**, which is the property the original error
lacked. U19 records both halves, which is the right shape for a recommendation
whose better variant is not yet settled.

Fourth, **the mediation is already documented at the edit site**, which partially
answers the "later hand" concern without any change. The review fixture's comment
directly above the privileged job's `if:` reads that if the preflight is "SKIPPED
— which is what a rejected trigger, fork, draft or bot guard does to it — then
`needs.credential-preflight.outputs.credential` is the EMPTY" string. Someone
editing that condition is told, in the file, what the condition is load-bearing
for.

Fifth, **the programme rule settles the remainder.** P03 builds the template; a
claim recorded as unproven with what would prove it is correct, and a decision
must not implement its own recommendation. U19 asserts nothing as proven. It says
in terms "**Not implemented in the fixtures at this correction**", gives the
reason, and names the P03 action and the CI gate that goes with it. Implementing
it here would be the defect — a design change to each real job's condition, made
at a phase that cannot validate its equivalence, in fixtures that are not the
template.

What remains true of this revision overall is what my predecessor found and I
re-verified: the residual is stated at full strength and its three spans are
byte-identical to the published predecessor; the bounding list names credential
presence in the removed flag's place rather than pretending the flag survived;
the preserved revision-5 entry is the published bytes exactly, 152,934 of them;
the preflight fails closed through the value as well as through the dependency;
and B4 and B10 assert the real job's conclusion rather than the preflight's. The
one thing that was missing is now present, in the decision and in both files that
get copied, and the decision is candid that the header is a channel this
particular adopter will not open. A decision that states the cost of the owner's
design accurately, refuses to overclaim its own remedy, and converts the gap into
a falsifiable criterion P03 must prove is what this phase is for.
