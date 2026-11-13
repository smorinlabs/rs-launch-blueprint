# Resumable Doxa research, and what it lets us parallelize

Owner question, 2026-09-10: is Doxa research resumable for all three providers,
are we recording the identifiers needed to resume, and if so what plan does that
enable for running non-dependent research concurrently?

Answer: **yes for all three, validated today**, with three constraints that shape
the plan. Concurrency is limited by Perplexity, not by disconnection.

## 1. What was validated

Every test below ran from a **fresh process**, using only identifiers already
committed to git, against the oldest jobs in the record: the R38 pilot operation
submitted 2026-09-08T22:38 local, about 27 hours earlier.

| Provider | Call | Result |
|---|---|---|
| OpenAI | `GET /v1/responses/{id}` | `status: completed`, `store: true`, `expires_at: null`, `background: true`; 44,533 characters of answer recovered |
| Perplexity | `GET /async/chat/completions/{id}` | `status: COMPLETED`; 62,548 characters recovered |
| Gemini | `interactions.get(id)` | `status: completed`; 22,745 characters recovered |
| Doxa | `status <operation-id>` | `completed`, all three providers `completed`, output paths listed, nothing created |

The owner's specific concern was OpenAI: background research used to be
resumable and may not be any more. It still is. `background: true` and
`store: true` are both set on the stored response, `expires_at` is null, and the
full answer body came back a day later from a process that never saw the
submission.

Two further proofs come from the session record rather than a dedicated test:

- **Cross-process resume already happened, repeatedly.** Both bulk batches were
  submitted by one short-lived process and then polled by roughly twenty
  separate `resume --async` processes, each of which saved any newly completed
  provider result. No submitting process was alive at collection time.
- **Provider-direct recovery works when Doxa itself fails.** R66's operation was
  aborted by Doxa after its OpenAI job had already been created. That orphan was
  collected in full through `GET /v1/responses/{id}` with no Doxa involvement.

## 2. What we already record durably

Per operation, committed to git under `research/runs/<ITEM>/<RUN>/operations/`:

| File | Carries |
|---|---|
| `doxa-submit.json` | the Doxa operation id, from the submission envelope |
| `doxa-status-initial.json` | all three provider job ids, structured, captured seconds after submission |
| `doxa.json` | runner state, operation id, and the job ids in `actual_provider` |
| `manifest.json` | the state machine: `submitting` → `submitted` → `succeeded`/`partial`/`failed` |

That is enough to resume without Doxa's help. It matters, because **Doxa's own
checkpoint store is machine-local** at `~/.local/state/doxa/checkpoints` and is
not in git. Lose the machine and `doxa resume` cannot work, but the provider job
ids are in the repository, so direct retrieval still can.

## 3. The three real constraints

1. **Perplexity limits concurrency.** It refused the fifth simultaneous
   `sonar-deep-research` submission with "API rate limit exceeded" while four
   were in progress. This, not disconnection, is what caps parallel submission.
2. **Doxa aborts a whole operation when any provider's submit fails**, after
   earlier providers have already been created. That is how R66 produced a paid
   orphan. Any batch large enough to trip the Perplexity limit will leave one.
3. **OpenAI and Gemini expose no list endpoint.** An unrecorded job is
   unrecoverable, because nothing can enumerate it. Perplexity alone can be
   reconciled after the fact. This is why intent must be recorded before
   submission and the returned ids captured immediately, every time, without
   exception.

Retention beyond about a day is unverified. OpenAI sets no expiry on the stored
response. Perplexity and Gemini were not checked past 27 hours. Treat a week as
the safe window and collect sooner.

## 4. The plan

**Principle: the repository is the state, agents are disposable.** No subagent
owns an operation. A subagent either submits and records, or collects and
records. If it dies, nothing is lost, because the identifiers are on disk before
the work begins.

**Submission.** Batches of at most three concurrent Doxa operations, spaced
thirty seconds apart, which keeps Perplexity's in-flight count under its limit
and avoids the abort that creates orphans. For each item, in order: record
intent, submit asynchronously, capture the operation id, take one status pass to
capture all three provider job ids, record them, commit. Never submit again for
an item whose operation is in any state other than failed.

**A sweeper replaces babysitting.** One script scans every run manifest for Doxa
operations in `submitted` or `running` state, polls each by its recorded
operation id, saves whatever has newly completed, and reports what is still
outstanding. It is idempotent, creates nothing, and needs no agent and no memory
of what launched the work. Run it on return from any interruption, including a
machine restart. Where Doxa's local checkpoint is missing, it falls back to
per-provider retrieval using the job ids from git.

**Relaunch from state, not from memory.** After an interruption, the sweeper's
report says exactly which items are collected, which are still running, and
which never got a report. Subagents are then dispatched for the gaps only. This
is what makes agent death cheap: today three agents were killed mid-task by
credit exhaustion, and every one of them was recovered by re-reading state.

## 5. What this enables

With resumability proven, the batch size no longer has to be small enough to
watch. It only has to respect Perplexity's limit.

| Stage after the current one | Items admissible together | Of those, Deep |
|---|---|---|
| next | 28 | 10 |
| following | 27 | 10 |
| after that | 20 | 4 |

Ten Deep items at three per batch is four batches, roughly two hours of wall
clock, entirely unattended, with collection whenever we return. The eighteen
non-Deep items in the same stage need no Doxa at all and are limited only by
Claude and Codex seats.

## 6. What to build before the next big batch

1. The sweeper described above, as a committed script rather than a scratch file,
   with a per-provider fallback path that does not need Doxa's checkpoint.
2. A single in-flight index the sweeper writes, so the state of every operation
   is visible in one place instead of thirty manifests.
3. A reconciliation step for Perplexity, the only provider that can be
   enumerated, to catch any job created but not recorded.

None of these is required for correctness today, because the per-run records are
already sufficient. They make recovery a single command instead of a manual
sweep.
