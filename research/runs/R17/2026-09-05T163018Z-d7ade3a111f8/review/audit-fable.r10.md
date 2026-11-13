decision-sha256: a4ce36e4868ff1c6a7d5c345135ba14bdbf77530f856688e1a0592247710323e
actor: audit-fable-2026-09-05T163018Z-d7ade3a111f8-r10
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: JF-7 (blocking, not introduced by revision 10 but live in its text): the mutation harness's recorded target-only result is not reproducible without a declared GitHub token, because `mutations-r9.sh` runs each mutant end to end — six anonymous REST calls per run — while declaring neither network egress nor the live API budget, and revision 9's new failing-set assertion turns any rate-limited unrelated assertion into a harness failure; the round-10 empirical rerun began with `remaining 8` of the anonymous 60 and both mutants reported "the mutant FAILED a different set than the mutation targets", `mutation-harness failures: 2`, `RESULT: FAIL`, where measurement (9) records `exit 0` and `failures: 0` under the same no-token shape; JF-8 (non-blocking): the JF-6 repair sentence gives as its reason "only `run-checks-r8.sh` has a section 00" and then counts measurement (6) — the `…-r8-rev7-script-against-rev8.log`, produced by `run-checks-r7.sh` — among the five logs that carry a `UTC now:` line

## Principle and agreement level

Unchanged and re-checked rather than carried. Revision 10 edits six lines and adds eight, none of
them in `## Decision`'s recommendation, `### Principles and implementation`'s agreement-level
table, the gate rule, the runner-up, the `BASELINE-REVIEW:` line or the fitness-gate table. Part 2
remains the TruffleHog OSS CLI, `>= 3.97.0, < 4.0.0`, a pinned release binary in a `run:` step with
`--only-verified --fail`, under owner ruling W0-R17b; the passing set is still `0` alone of the
documented `{0,1,183}`; fitness gate 1 is still `inapplicable` under Q7.B and I raise no licence
finding. I confirmed by search that the `781feac`-to-`c5098e6` span touches none of section 13's
fourteen anchor prefixes and that the four `- assumes` lines are still byte-identical to
`docs/port/PARAMETERS.md` (rebuilt from that file's table rows and `diff`ed: empty).

## Design and evidence

**The three round-9 findings are closed, each verified at the log line the corrected text now
cites.**

*JF-4.* Line 166 now reads "**27,960 stars** … the star count **read at 2026-09-16T22:25:39Z** in
`review/evidence/secret-scanning-ci-workflow-r8-repo.log`, lines 240–242", and the section-10
evidence row (line 248) reads "Read at 2026-09-16T22:25:39Z, `…-r8-repo.log:240–242`:
`trufflesecurity/trufflehog` 27,960 stars … `mongodb/kingfisher` 1,233 stars". That log's line 240
is `-- counters below were read at: 2026-09-16T22:25:39Z`, line 241 carries
`stargazers_count: 27960`, line 242 carries `1233`. The superseded triple is quoted rather than
deleted and attributed to `…-r7-repo.log` lines 217–219, which is where `05:03:35Z`, `27941` and
`1232` actually sit. Two collateral claims in the new prose are true as well: `27941` returns zero
across all six revision-8 and all four revision-9 logs, and all five revision-8 run-checks logs
read 27,960 and 1,233 at their own section-10 instants, which span `22:22:48Z` to `22:28:54Z`.
**Closed.**

*JF-5.* Line 195 now reads "retrieved 2026-09-16T22:25:41Z (`12a`,
`review/evidence/secret-scanning-ci-workflow-r8-repo.log` lines 261–262)", and the section-12 row
(line 250) matches. That log's line 261 is
`-- manifest date: 2026-09-03; [pkg.rust] version: 1.98.1 (48a229cea 2026-09-01)` and line 262 is
`-- read at: 2026-09-16T22:25:41Z`. The superseded instant is quoted and attributed to
`…-r7-repo.log:239`, which is correct, and the value is unchanged because it was never wrong.
**Closed.**

*JF-6.* Line 214 now reads "**five** of revision 8's six recorded runs open at `UTC now:` instants,
and those five span `2026-09-16T22:22:17Z` to `2026-09-16T22:28:25Z`", names the five as
measurements (1), (2), (3), (4) and (6), says why `…-r8-mutations.log` and revision 9's four logs
carry none, and cites both endpoints to their lines. I counted `UTC now:` in all ten logs: exactly
the five named carry one, the other five carry none, `…-r8-rev7-script-against-rev8.log:29` is
`22:22:17Z` and `…-r8-archive-bare.log:29` is `22:28:25Z`. The sentence no longer contradicts
"**Nine runs are recorded**" nine lines below it, and it says so in its own parenthesis.
**Closed**, with the reason-clause defect at JF-8 below.

**The two deliberately-left lines are correctly left, and I checked each against the artifact it
quotes.** Line 39's `1,232` sits inside a verbatim quotation of round 6's finding F1 — "*they read
27,898 and 1,232*" — which is a statement about **revision 6's** logs, where 1,232 was the true
value; editing a figure inside a quotation of another document would falsify the quotation, and
`review/audit-fable.r6.md` confirms the quoted text. Line 61 is revision 9's own "no table figure
moves", true of revision 9, with line 67 stating plainly that revision 10 moves exactly two table
figures and why rewriting revision 9's record would falsify it. Both calls are right.

**The revision-10 enumeration is accurate, which is the check that the sweep and not only the
fixes was done.** Its eleven searches are stated with revision 9's line numbers; I reran the nine
that are searches over the decision against `git show c5098e6~1:…/DECISION.md` and every result
matches exactly: `27,941` at 160 and 240; `1,232` at 39, 160 and 240; `05:03:35Z` at 160 and 240;
`05:03:38Z` at 189 and 242; `1.98.1` at 39, 189, 196, 222 and 242; `stars` at 160 and 240;
`recorded runs` at 208 alone; `UTC now` at 208 and 216; `no table figure moves` at 61 alone; and
`22:2[0-9]:` at 208 alone before the edit. In the current text every surviving occurrence of a
superseded figure is in a quotation, a supersession record or the enumeration itself — lines 63,
65, 166, 233, 248 and 250, plus line 39's quotation — and none states a stale value as current.

**The scope claim holds.** `c5098e6` changes one file. `run-checks-r8.sh` is still `697ea3b1…`,
`mutations-r9.sh` `774eb8d4…`, `mutations-r8.sh` `0663adc4…`, and all ten recorded logs are
byte-identical to the digests I verified in round 9. No `RESULT` label, verdict or count moves.

**Where the evidence does not reach the claim.** One place, and it is not in anything revision 10
edited: the mutation harness's recorded result. It is JF-7 below.

## Completeness

| Required item | Status |
|---|---|
| `## Decision`, `### Principles and implementation`, `re-verify:`, `## Parameters`, `## Empirical check`, `## Engines` | present, in order |
| `## Supersedes` | correctly absent — unpublished revision |
| Owned / consumed parameters | none; the prompt's `- owns:` and `- consumes:` lines are empty |
| The four `- assumes` lines | byte-identical to `docs/port/PARAMETERS.md`, verified programmatically |
| Settled ledger row, `BASELINE-REVIEW:`, `CONFLICT:` | unchanged from revision 9 and correct: F050 named and not edited, the review carried verbatim and unresolved, no `CONFLICT:` owed |
| Six fitness gates | all six answered for both candidates; gate 1 `inapplicable` under Q7.B |
| Source dates and provenance | the defect round 9 named is repaired; every figure in the current text is either at its cited log line or explicitly marked superseded |
| Unproven material | six rows unchanged, including the adverse `localhost` database-URI row |
| audit-codex | round 9 (`review/audit-codex.r9.md`) bound `7e6ecd93…`, `verdict: approve`, `unresolved-findings: none`. Round 10 (`review/audit-codex.md`) binds this revision, `a4ce36e4…`, and **rejects** on its F1; I read its evidence log and judge the finding sound — see JF-7, which states it in my own terms and adds the mechanism. **The two round-10 audits are therefore consistent with each other and not with the decision** |

## Findings

Numbering continues from round 9's JF-4 to JF-6.

**JF-7 (blocking) — the mutation harness's target-only result depends on an undeclared, depletable
live-API budget, so the measurement the decision records as a no-credential reproduction does not
reproduce.** Measurement (9) at line 219 reads: "**(9) The audit's own invocation form**, run
because round 8's F3 was precisely that the recorded invocation did not reproduce under the
auditor's environment, and a repair asserted against a friendlier environment would settle nothing
… **Exit status 0**, `mutation-harness failures: 0`, `RESULT: PASS`", and it stresses that "**mode 9
deliberately supplies none**" — no token. The round-10 empirical rerun under that shape instead
reported, for both mutants, `MUTATION CHECK failing-set: the mutant FAILED a different set than the
mutation targets`, then `mutation-harness failures: 2` and `RESULT: FAIL`
(`review/evidence/audit-secret-scanning-ci-workflow-r10.log:351`, `:384`, `:389`, `:390`).

**The mechanism, which I read out of the harness and that log rather than inferring:**
`mutations-r9.sh` runs each mutant **end to end** — `bash "$out"` at its line 149 — not section 08
alone, so every mutant repeats the parent's six live GitHub REST calls (`03a`, `03b`, `10a`–`10d`,
`11a`–`11c`). On the no-token branch those calls come out of the anonymous 60-per-hour budget, and
the round-10 parent run began at `api.github.com core rate limit: 60 (remaining 8)` (that log's
line 22). Mutation 1's observed failing set was its three targets **plus** `11c`; mutation 2's was
its one target **plus** `03a`, `03b`, `10a`–`10d` and `11c` (`:353`, `:386`). Both mutants' section-08
verdicts were exactly right — `08h`/`08i`/`08j` failed under mutation 1, `08e` failed and `08f`
passed under mutation 2 — so the *mutations* still demonstrate what they were built to
demonstrate; what failed is the harness's verdict about them.

**Why this is the decision's defect and not the auditor's environment.** Two reasons, both
checkable in the committed files. *First*, the harness's own `Declared environment` block
(`mutations-r9.sh:48–52`) names only `PY_REPO`/`TS_REPO`/`GH_TOKEN` passthrough, the replaced
`HOME`, and `/usr/bin/grep`. It declares **no network egress and no API budget**, although it
re-runs a script whose own header declares thirteen dependencies including egress, and although it
spends that budget twice over. That under-declaration relative to the script it mutates is
verbatim the shape round 8's F3 rejected — "the mutation harness claims the same environment
discipline but does not implement it" — moved from `PATH` to the API budget. *Second*, the
assertion that breaks is the one **revision 9 added**: "each mutant's FAILing labels are collected
from its own output and compared **as a set** against the expected ones" (line 59). Revision 8's
weaker assertion would have passed this rerun. So the strengthening that makes the evidence better
is also what makes the recorded result environment-dependent, and the decision records it with no
condition attached. Line 222's comparison rule does not cover it either: it says "the `FAIL=`
figure and the printed `SKIP` names are what this document asserts on", which is silent about a
failing-set assertion that any rate-limited unrelated label can break.

*What resolves it — the decision's own doctrine points at the first family, which declares and
branches rather than weakens:* declare the live-API budget as a dependency of the harness, probe
and print the remaining count as the evidence script's `00b` does, and either require a declared
token for the mutation measurement or `SKIP` by name — never let a rate-limited unrelated
assertion be reported as a mutation-harness failure. The alternative family is to make the set
assertion measure what the mutation changed rather than an absolute set — compare each mutant's
failing set against an unmutated control run's in the same window, and assert on the difference —
which keeps the no-token mode runnable. Either way the recorded measurements must be re-run and
re-stated, because measurements (5), (7), (8) and (9) all rest on the same assertion.

**This is not a defect revision 10 introduced.** Revision 10 closed JF-4, JF-5 and JF-6 exactly and
touched no script, log or assertion. JF-7 is inherited from revision 9 and is live in the current
text, which is why it blocks this revision rather than waiting for the next one.

**JF-8 (non-blocking) — the JF-6 repair sentence gives a reason that excludes one of the five logs
it counts.** Line 214 reads: "Section 00 prints `UTC now:` and **only `run-checks-r8.sh` has a
section 00**, so the five are measurements (1), (2), (3), (4) and (6) — the repository, archive,
archive-bare, shim-path and rev7-script logs." Measurement (6) is not `run-checks-r8.sh`: line 219
records it as "**Revision 7's script, rerun unchanged against this revision's `DECISION.md`** —
`bash run-checks-r7.sh`", and line 220 says `…-r8-rev7-script-against-rev8.log` "is revision 7's
**unmodified** script run against this file". That log carries a `UTC now:` line at its line 29, and
that instant is the lower endpoint of the window the same sentence quotes. So `run-checks-r7.sh`
has a section 00 too, and the stated reason contradicts its own enumeration.

It is non-blocking because the enumeration is correct and line-cited, nothing downstream rests on
the reason clause, and the intended contrast — a `run-checks` script versus the mutation harness —
is carried by the next clause. *What resolves it:* "only a `run-checks` script has a section 00".

## Assessment

Revision 10 is a clean, narrow repair and I approve of everything it did. All three round-9
findings are closed at the log lines the corrected text cites; the superseded figures are quoted
and attributed rather than deleted, which makes the correction checkable instead of asking to be
believed; the enumeration of what was searched is accurate in all nine of its decision-side
searches when replayed against revision 9's text; the two lines left byte-identical are correctly
left, one because it quotes another document and one because it records what revision 9 did; and
the diff is exactly what was claimed, touching no script, log, anchor, `assumes` line or `RESULT`
verdict.

I nevertheless reject, and not on anything revision 10 changed. The round-10 empirical rerun shows
that the mutation harness's recorded target-only result does not reproduce under the no-credential
invocation the decision itself chose in order to prove it would. I read the harness and that audit's
log rather than taking the verdict: the mutants' section-08 behaviour is exactly as recorded, but
each mutant re-runs six live GitHub API calls on an anonymous budget the harness never declares,
and revision 9's own new failing-set assertion converts a rate-limited unrelated label into a
harness failure. That is this document's oldest defect in its newest location — an assertion whose
truth depends on an environmental condition the recorded command does not carry — now sitting in
the artifact built to prove the evidence can fail. The recommendation does not move under either
finding: JF-7 touches the falsifiability record for `08e` and `08h`–`08j`, not the tool, the install
shape, the passing set `{0}`, the runner-up or any parameter, and JF-8 is a one-word reason clause.
Declare the budget and branch on it, or make the set assertion measure the mutation's own
difference, then re-run and re-state measurements (5), (7), (8) and (9); fix the six-word clause at
line 214 while doing it.
