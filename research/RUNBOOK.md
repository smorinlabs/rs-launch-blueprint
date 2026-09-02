# Runbook — executing the research tree (spec §10–§11)

This file binds the session that runs the prompts (project P02). Nothing here is optional.

## 1. Run order
- Fixed parameters (`docs/port/PARAMETERS.md`, kind `fixed`) are already valued; never research them.
- An item runs only after every item named in its prompt's `- consumes:` line is `resolved` in `CLAUDE.md`.
- Compute the order from the prompts, do not hand-maintain it:
  ```bash
  # prints "item dependency" pairs; feed to tsort for a topological order
  for p in research/topics/*/prompts/*.prompt.md; do
    id=$(awk '/^- id:/{print $3; exit}' "$p")
    deps=$(awk '/^- consumes:/{sub(/^- consumes: */,""); print}' "$p" | tr ';' '\n' | awk -F: '/R[0-9][0-9]/{gsub(/ /,"",$1); print $1}' | sort -u)
    for d in $deps; do echo "$d $id"; done; echo "$id $id"
  done | tsort
  ```
- Items with no unresolved dependencies run in batches of **at most 4**; a batch finishes (all `resolved` or escalated) before the next starts.

## 2. Engine invocation
Verified by the Phase 3 conformance pilot (plan Task 14) on <date>: **<engine: /deep-research | doxa mode>**.
- Input: the item's `prompts/<slug>.prompt.md`, unmodified.
- Output path: `research/topics/<nn>-<slug>/raw/<engine>-<YYYY-MM-DD>.md` (raw engine output, committed as evidence).
- Invocation: <exact call recorded by Task 14>
- Before anyone reads the content, check the answer fills the template:
  ```bash
  scripts/check-answer-shape.sh research/topics/<nn>-<slug>/raw/<file>   # written by Task 14; exits 1 listing missing fields
  ```

## 3. Failure and retry
1. Engine error or a shape check failure → re-run once, unchanged.
2. Second failure → narrow the prompt to its `HIGH` questions only (edit a copy `prompts/<slug>.narrowed.prompt.md`; the original stays), re-run, and record `narrowed: yes — <reason>` in `DECISION.md ## Decision`.
3. Third failure → stop the item, set `status` to `in-progress`, and escalate to the owner with the three raw outputs.

## 4. Conflict rule
- An answer whose `Parameters` field contains `CONFLICT: R## <param> — <needed value> — <reason>`:
  1. the consuming item is **blocked** (status stays `in-progress`; no `DECISION.md`);
  2. the owner item `R##` is re-opened: append a `## Conflict from R<consumer>` block with the line verbatim to the **end of the owner prompt's `## Context`** (append-only), and re-run it;
  3. the owner's new `DECISION.md` entry cites the old one under `## Supersedes`;
  4. `PARAMETERS.md` is updated from the owner's new value; only then does the consumer re-run.
- A consumer never adopts a value the registry does not hold.

## 5. Answer → decision
`DECISION.md` in the topic directory has exactly these H2s (the checker enforces the first three):
- `## Decision` — the pick with version, the ledger rows (`F###`) it settles, and `narrowed:` if §3 applied.
- `## Parameters` — one line per owned parameter `- owns <param> = <value>` (copied verbatim into `PARAMETERS.md`) and per consumed parameter `- assumes <param> = <value>`.
- `## Empirical check` — toolchain (`rustc --version`, OS), the exact command run, and the observed result. A recommendation that is a configuration, command, or version pin is not accepted until this section shows it executed (spec §10).
- `## Supersedes` — only when reversing an earlier entry: the entry's date and what changed. Entries are never edited in place; a reversal is a new dated entry above the old one.
An item is `resolved` only when `audit-codex.md` (different model family; re-runs the empirical check) and `audit-fable.md` (judgment) both exist and are non-empty. The producer of an answer never writes its own audit.

## 6. Staleness
- Every `DECISION.md` ends its `## Decision` with `re-verify: <date or event>` copied from the answer's *Confidence & re-verify trigger* field.
- When a trigger fires, the owner of this repository re-runs that single item under §2–§5; consumers re-run only if the owner's `## Parameters` changed.
- A quarterly sweep (`grep -h 're-verify:' research/topics/*/DECISION.md`) lists triggers due.
