decision-sha256: f03dbef4a1246902bce8c7f81d324829d7b6df38acddb5bc14406de049a25782
actor: audit-fable-2026-09-17T033527Z-8dfef31d60fc-r2
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: JF-5 (non-blocking) the sentence repairing JF-3 introduces a new wrong count — `project-search` is called "one of eight member-level `owns` lines" where `raw/doxa-openai.normalized.md` carries twelve (`:398-401`, `:536-539`, `:678-681`), and no check asserts that number

# Judgment audit — R54 config-discovery-tiers, revision 2 (round 2)

Round 1 of this audit is preserved byte-identically at `review/audit-fable.r1.md`
(sha256 `144a21e11369b8e526217e4772397e0c6201694bd4ecda75bb0bb4729071f6b6`, verified
with `cmp`); it bound revision 1 at sha256
`b0fb750daeabd9697002d5dd3eebd5b6efd67f2d7cb2eb78e4e8b3f6fe964797` and returned
`reject` on JF-1 and JF-2 blocking, JF-3 and JF-4 non-blocking. This round judges
revision 2 at the sha above, which arrived as commits `0bce85f` ("answer the
round-1 judgment audit (JF-1..JF-4)") and `3ee43ee` ("record the r2 checks and the
clean-archive rerun"). The empirical (Codex) audit is still deferred under
`W1-CODEX`, so this round again ran alone and acceptance still needs a second
approving verdict.

Every repair was checked against the primary artifact, not against the
synthesizer's report of it and not against revision 2's own new log alone: the
sibling decisions and their audits at their current bytes, the Doxa/OpenAI twin
and `raw/opus.md` at the lines cited, `docs/port/BASELINE-REVIEW.md` at the lines
cited, the git history for the commit-ordering claim, and the revision-1 evidence
files re-digested by me.

## Principle and agreement level

Unchanged, and still correct. No hunk in the revision-1-to-revision-2 diff touches
the shared requirement, the `R5.1`/`R5.2` quotations, the C1–C6 agreement table,
the six-rung table, the force labels `J1`–`J4`, the A1–A5 comparison, the
`BASELINE-REVIEW:` dispositions, AC1–AC11, the `## Parameters` section or the
figures. I read the complete diff rather than sampling it: it consists of the new
revision note, the JF-4 sentence in the F247 disposition, the R55 coupling bullet,
the `re-verify:` line, a new paragraph in `## Empirical check` describing
`check-r2.sh`, the Disagreement 1 addendum, the rewritten Disagreement 6 sentence
and the new Disagreement 7 — and nothing else. The five `- assumes` lines are
untouched in the diff and `V25`–`V29` re-assert their byte-identity.

## Design and evidence

**JF-1 is closed at every site.** Three sites carried the false label and all three
are repaired: the R55 coupling bullet now reads "**revision 3**, judgment-approved
and unpublished" (`:338`); Disagreement 1 now reads "R55 is at **revision 3**
(judgment-approved, unpublished)" (`:633`); and the `re-verify:` trigger now reads
"**R55 being revised past revision 3**" (`:382`). The only surviving "revision 2"
strings about R55 are historical by construction — the revision note's superseded-
wording column and the new self-critique at `:644` ("Revision 1 named R55
'revision 2' while its own check `D00b` pinned revision 3's sha256") — so nothing
asserts the stale label. I verified the underlying facts independently of
`check-r2.sh`: R55's decision states revision 3 in its title, its current sha256 is
`5d358c1fda2a5ff2782b916f3ca81cf52bbbafd75748774b114345c72a6edd9b` (the value
revision 1's `D00b` pinned), its round-3 judgment audit carries
`verdict: approve` bound to that same sha (commit `2466d90`), and it is unpublished
(`research/CLAUDE.md` still shows R55 `open`, and `docs/planning/p02/owner-decisions.md`
section 13 carries no `W1-R55` row). The commit-ordering claim is exact: `439da7d`
at 2026-09-17T08:23:21-07:00 against `0bf66ee` at 08:36:01-07:00 is 12m40s, and the
decision says so while noting my round-1 text rounded it to thirteen minutes. The
disclosure that the trigger had already fired, and the statement that it had no
effect on the composition, are both carried where a reader meets the trigger.

**JF-2 is closed, and Disagreement 7 is a settlement rather than a restatement.**
`## Engines` now carries a seventh disagreement, and the R57 coupling bullet's
cross-reference is true. The dissent is quoted from the raw report rather than
paraphrased, and the quotation is faithful: normalizing line wrapping, the 288
characters the decision quotes occur verbatim in `raw/opus.md` (I compared the
strings, not the check). The settlement then does three things a restatement would
not. It answers the single-authority argument on its own terms — `XDG_CONFIG_DIRS`
is a different environment variable from `XDG_CONFIG_HOME`, so disposition (b)
creates no second authority for the variable R57's `Paths` resolves. It names the
third ground decisive and grounds it in R57's own fixed surface (`D04`). And it
bounds the stakes honestly: only where roughly eight lines live changes, never what
they do, and `etcetera` stays R57's single declared dependency either way. It also
declines to decide for R57, which is what `raw/opus.md` itself asks ("R57 owns the
choice … records it as a coupling rather than a decision").

**JF-4 is closed on the right side of the preservation rule.** The disposition
paragraph now attributes the owner-question sentence to `docs/port/BASELINE-REVIEW.md:193`,
where I confirmed it is verbatim, and keeps `:113` for what that line is — the F247
adjudication row, status `blocked pending R54`. The carried `BASELINE-REVIEW:`
lines were not edited, including the `:113` inside the F247 line: I re-ran my own
whole-line comparison against `raw/opus.md:201` and `:232` rather than relying on
`V23`/`V24`, and each line still occurs in the decision exactly once, byte for
byte. That is the correct outcome — those lines are quotations of another engine's
finding and repairing them would have been the worse error.

**The new evidence is real, and revision 1's is provably untouched.**
`check-r2.sh` reads only files already in the repository — no `curl`, no `gh`, no
URL — so its determinism claim holds by construction. Its log prints 41 assertions
(6 group `B` plus `V01`–`V35`) with `failures=0 skipped=0`, which matches the
decision's "41 checks, 41 PASS, 0 FAIL, 0 SKIP". Group `B` re-asserts revision 1's
artifacts by digest, and I recomputed all six independently: `check.sh`
`7e22e8ff…`, `check.log` and `check-rerun.log` both `a1f676c9…`, `walkup_probe.rs`
`faa0e5de…`, `shellcheck.log` the empty-file digest `e3b0c442…`, and the sorted
snapshot manifest `fa53d95a…` — every value matches the log, and
`git diff 486aad1 HEAD` over those paths and `snapshots/` is empty, so the
byte-identity claim is true in two independent ways. The clean-archive rerun
behaves as described: `check-r2-archive.log` differs from `check-r2.log` in exactly
three lines — the `repo-root` header, `V10` degrading to a **named** `SKIP` because
the extraction carries no git history, and the `skipped=` total. A named skip for
the one check that needs a commit history is the honest form, and the decision says
so rather than reporting 41/41 from the archive. `r2-rerun.diff` and
`shellcheck-r2.log` are both zero bytes, consistent with what they claim.

**The V-checks are checks, not decoration.** `V16` and `V21` are written to fail if
the claim is false rather than to confirm a search that cannot miss, `V19` guards
against the superseded "four" surviving anywhere except the revision note's own row
(I confirmed it occurs exactly once in the file), and `V35` distinguishes a
`## Supersedes` heading from the string appearing in prose. `V02`/`V03` are the
sharp ones: they prove the synthesis hashed revision 3 while naming revision 2,
which is the finding rather than a paraphrase of it.

## Completeness

The title is `# 2026-09-18 — R54 — config-discovery-tiers (bundle, Deep) — decision
(revision 2)`, date first. The four H2 sections are unchanged and
`### Principles and implementation` is still present and nonempty. No
`## Supersedes` section is added, correctly: the item is unpublished, and the
revision note says so. The revision note names all four findings with the
superseded wording quoted beside each repair, which is the form that lets a later
reader audit the repair without reconstructing revision 1 — and revision 1 remains
recoverable at `git show 0bce85f~1:<run>/review/DECISION.md`. My round-1
observation about A1 reading `config` 0.15.20's feature list while naming 0.15.25
is left unrepaired and the revision note says so explicitly, with the reason; that
is the right disposition for something I labelled not a finding, and I do not
raise it now.

`## Parameters` is unchanged: no `- owns` line, one consumed parameter (R67's), and
five `- assumes` lines whose byte-identity I verified independently in round 1 and
which this revision's diff does not touch.

## Findings

**JF-5 (non-blocking) — the sentence repairing JF-3 introduces a new wrong count.**
At `:716` the decision reads: "`project-search` is **not** among them — it is one
of eight *member-level* `owns` lines, at `:401` (`V16`, `V17`)."
`raw/doxa-openai.normalized.md` carries **twelve** member-level `owns` lines, not
eight: `:398`–`:401` (`system-config-roots`, `user-config-root`,
`config-relative-path`, `project-search`), `:536`–`:539` (`table-merge`,
`leaf-merge`, `array-merge`, `source-order`) and `:678`–`:681`
(`config-selector-cli`, `config-selector-env`, `selector-precedence`,
`cli-data-overrides`). An anchored count of lines beginning "- \`owns " in that file
returns 12, against 8 for the answer-level form. No check asserts the number:
`V17` pins only that `project-search` sits at `:401`, and `V14`–`V16` are about the
answer-level block, so this is the one claim in the revision whose only support is
the sentence itself. Everything load-bearing around it is correct — eight
answer-level parameters at `:745-759`, the eight names exactly as listed,
`project-search` absent from that block and present at `:401` — and the disposition
("both rejected as out of contract") does not depend on the figure at all. The
repair is one line and needs no change to any check: write "one of twelve
member-level `owns` lines (`:398-401`, `:536-539`, `:678-681`)", or drop the count
and keep "it is a member-level line at `:401`".

Nothing else in revision 2 is unresolved. JF-1, JF-2, JF-3 and JF-4 are closed at
every site I could find them, and I looked for each at its own sites rather than
accepting the revision note's account.

## Assessment

The recommendation does **not** move, and nothing in revision 2 moves it: the
six-rung chain, `etcetera` 0.11.0 through R57's `Paths`, the two `std` resolvers,
the `clap` `env` attribute plus emptiness filter, the A2′ merge, `J1`–`J4`,
AC1–AC11 and all five parameter values are identical to revision 1, which the diff
shows and group `B` and `V25`–`V29` re-assert. JF-5 is a decorative figure in a
sentence whose checked facts are all correct.

This round is otherwise clean, and the repairs are better than the minimum: the
`V02`/`V03` pair proves the JF-1 defect instead of asserting its absence, group `B`
converts "nothing else changed" from a promise into six digests, the clean-archive
rerun names its skip rather than hiding it, and Disagreement 7 argues the
disposition rather than recording that a disagreement exists. The verdict is
`reject` only because the role doc admits no unresolved finding and JF-5 is a false
numeric fact in the current text — in the very sentence that repairs a false
numeric fact, where the decision itself writes "the bar is the same in both
directions". Applying a lower bar in round 2 than in round 1 would make that
sentence untrue. A revision 3 confined to that one line should close this audit.
