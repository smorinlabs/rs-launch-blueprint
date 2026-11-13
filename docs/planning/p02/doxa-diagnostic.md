# Doxa research: full diagnostic, 2026-09-11

Owner question: research was paid for and should be resumable, we built logs to
make it resumable, and the impression is that it was kicked off, forgotten
across a disconnection, and never picked back up. How much is still open, what
failed, and what worked?

Everything below is reconstructed from disk and from the providers' own APIs,
not from any session's memory.

## The headline

**No paid Doxa research is uncollected, and none was lost.** Nine operations
were ever submitted. Eight succeeded, and all eight results are on disk,
integrated into their decisions and cited by them. The ninth is R66, whose
failure is known and whose one paid job was recovered.

**But the parallelism was nothing like what you expected, and the reason is not
disconnection.** Only nine of the twenty-six items that require Doxa have ever
been admitted to the programme at all. The other seventeen sit behind the Wave 0
review gate, which is your decision, not a lost job.

**The thing that genuinely failed is the reporting, and that is mine.** For two
days my status line described R66's failed operation as "collect in-flight",
which reads as work in progress. A failed operation and a running one looked the
same in every report I gave you.

## 1. Every Doxa operation ever submitted

| Item | Submitted (UTC) | Collected (UTC) | State |
|---|---|---|---|
| R38 | 2026-09-09 05:38 | 2026-09-09 05:53 | succeeded |
| R01 | 2026-09-09 07:12 | 2026-09-09 07:29 | succeeded |
| R67 | 2026-09-09 07:13 | 2026-09-09 07:31 | succeeded |
| R42 | 2026-09-09 07:13 | 2026-09-09 07:31 | succeeded |
| R18 | 2026-09-09 07:32 | 2026-09-09 07:46 | succeeded |
| R25 | 2026-09-09 07:32 | 2026-09-09 07:48 | succeeded |
| R49 | 2026-09-09 07:32 | 2026-09-10 00:54 | succeeded |
| R60 | 2026-09-09 07:33 | 2026-09-09 07:47 | succeeded |
| R66 | 2026-09-09 07:33 | 2026-09-09 07:34 | partial |

That is the complete list. There is no tenth operation.

## 2. Integration: all eight results landed

Every succeeded operation's report is present on disk, between 236 KB and
312 KB, and every one of the eight decisions cites its Doxa evidence. Nothing
was collected and then dropped, and nothing was paid for and left unread.

## 3. The two orphans, and what each cost

An orphan here means a provider job that Doxa created before the operation
failed, so Doxa itself will not collect it.

**The 2026-09-05 attempt at R38.** An operation with our prompt failed that day
and left one OpenAI job. I queried it read-only today. It **failed with
`credit_balance_exhausted` and recorded zero input and output tokens.** It
produced nothing and cost nothing. R38 was re-run successfully on 2026-09-08 and
is published. Nothing to recover.

**R66, 2026-09-09.** Perplexity refused its submission against a concurrency
limit and Doxa aborted the operation after the OpenAI job had already been
created. Gemini was never attempted. I queried the OpenAI job read-only today:
**completed, 175,816 tokens.** It was recovered at the time without letting Doxa
re-create anything, and its report is on disk and normalized. So the money spent
there bought a report we have.

## 4. Did resumption actually work?

Yes, and there is one clean proof of it. R49's operation completed around
08:1x UTC on 2026-09-09 and its results were collected at 00:54 UTC on
2026-09-10, roughly sixteen and a half hours later, by a process that had not
submitted it. That is exactly the property we validated: identifiers recorded in
git, results retrievable later from a cold start.

The earlier validation pass also retrieved a day-old job from each of the three
providers from a fresh process, using only identifiers already committed.

So the mechanism is sound. What it was not used for is the thing you expected:
there was never a large batch left running across a disconnection, because there
was never a large batch.

## 5. Why only nine, when twenty-six items need Doxa

| Group | Count |
|---|---|
| Items whose policy requires Doxa | 26 |
| Of those, admitted to the programme (have a run directory) | 9 |
| Of those admitted, Doxa submitted | 9 (all of them) |
| Admitted but Doxa never submitted | 0 |
| Never admitted, so never submitted | 17 |

Every item that was admitted got its Doxa run. The seventeen that did not are
Wave 1 and later. They are not admitted because of the review gate you set:
no Wave 1 item is admitted until you review the Wave 0 keystones. That is
decision 1 in `owner-decisions.md`.

So the answer to "we should have kicked off all the unblocked work in parallel"
is that within Wave 0 we did. Wave 0 contains nine Doxa items and all nine ran.
The seventeen that look missing are blocked on you, not on a lost job.

## 6. What did constrain the parallelism

Perplexity refuses a fifth simultaneous `sonar-deep-research` submission, and
when any provider's submission fails, Doxa aborts the whole operation **after**
earlier providers have already been created. That is precisely how R66's orphan
happened. The working rule became at most three operations per batch, spaced,
which is why the nine ran as three batches rather than one.

That limit is real and will apply again to the seventeen remaining items. At
three per batch, seventeen items is six batches.

## 7. Recorded spend

Between USD 36.5 and USD 61.5 of the USD 300 blanket ceiling, the range being
Gemini's usage, which is estimated rather than read back. Nine operations, single
attempt each, no duplicate submissions.

## 8. Where the process failed

1. **A failed operation was reported as in flight.** My scanner's next-action
   line said "collect in-flight: doxa (partial)" for R66 from the moment it
   failed. Two days of status reports described a dead operation as pending work.
2. **The same scanner hid that R66 was short two engines, not one.** It named
   the in-flight engine and stopped. Fixed on 2026-09-10 to name engines that
   never started.
3. **No Doxa inventory existed until now.** There was per-run state, which is
   why nothing was lost, but no single view answering "what did we submit, what
   came back, what is outstanding". Your question is what produced one.
4. **The checkpoint store is useless as an inventory and I should have said so
   plainly.** It holds 1,084 files, of which 838 are test noise from a sibling
   repository's test suite and almost all the rest are unrelated usage. Exactly
   nine are ours. The repository is the system of record; Doxa's own store is
   not, and it is also machine-local, so it would not survive this machine.

## 9. What is actually open right now

**One item: R66.** It has its Codex report, its Opus report, and the recovered
single-provider Doxa report. It needs either your approval to re-run the two
refused providers, or your acceptance of the evidence it has. My recommendation
is to accept, because R66's strongest finding came from reading commits in the
pinned sources rather than from provider breadth.

Nothing else is waiting on Doxa. No job is running. No result is uncollected.

## 10. What to do differently for the remaining seventeen

1. **Lift the gate or admit the items deliberately.** The seventeen cannot start
   while the Wave 0 gate holds, and that is the single biggest lever on
   throughput in the whole programme.
2. **Submit in batches of three, spaced,** because of the Perplexity limit, and
   record each operation's provider job identifiers before starting the next
   batch. Six batches covers all seventeen.
3. **Never submit a batch without the intent record landing first.** It already
   works this way and it is why nothing has been lost.
4. **Add a Doxa inventory command** so this document does not have to be
   reconstructed by hand next time. It should list every operation, its state,
   its age, and any provider job Doxa created but did not collect, and it should
   call a failed operation failed.
