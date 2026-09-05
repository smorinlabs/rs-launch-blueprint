# Runbook — executing the research tree

This file governs P02 research execution under design spec §10–§11 and owner
amendment A6. The owner approved the [tiered proposal](../docs/planning/p02/PROPOSAL.md)
on 2026-09-04; the [approval record](../docs/planning/p02/APPROVAL.md) states its scope.

## 1. Entry gates and research order

Local planning, prompt reconciliation, and offline runner validation may proceed
before the `v0.1.0` tag. Binding research waits for the P01 merge/tag gate, the
full baseline review below, and verified execution routes. Paid Doxa requests
also require an approved batch and budget. The method approval is not paid-run,
tag-push, or merge authorization. The owner's later direction on 2026-09-04
authorizes committing completed, validated changes to the working branch without
per-commit approval; paid research, tag publication and merging keep their
separate approval boundaries ([approval record](../docs/planning/p02/APPROVAL.md)).

P02-T01 reviews **every REUSE and ADOPT baseline**, not a sample. Record the
principle, intended agreement level, source evidence, present Rust fitness,
and affected research items. A retained mechanism needs a fit argument;
repository agreement alone is insufficient. Record unsupported or challenged
choices as `BASELINE-REVIEW: F### — principle — proposed change — evidence`.
Reconcile affected ledger rows, prompts and dependencies before dispatching
research that depends on them. Preserve the original rationale and OVERRIDE
history. New research scope or a change to an explicit owner requirement needs
that specific owner disposition. The planning packet's baseline samples are
leads, not completed adjudications.

A5 remains binding: research principles, native architectures, and ecosystem
practices before selecting libraries. Fixed parameters remain valued in
`docs/port/PARAMETERS.md`: Rust edition 2024, the recorded MSRV policy, Ubuntu
and macOS targets, and `MIT OR Apache-2.0`. Windows support is informative,
not a required fitness gate. The required web example uses OpenTelemetry;
feature selection must not turn that requirement into an optional outcome.

Compute research prerequisites from canonical prompts:

- Every `R##` on `- consumes:` is a hard prerequisite.
- A non-owner's `- related` mention of a parameter owner is also a prerequisite.
  An owner's mention of its consumers is not a reverse edge.
- `- acceptance-after:` records an integration prerequisite for acceptance,
  separately from research dispatch. The combined acceptance graph must be acyclic.

R58 now owns `logging-pipeline-contract`; R59, R75 and R78 consume it. R58 still
consumes R69. The resulting research graph has 69 edges and illustrative layers
of 32, 19, 13 and 20 items. Layers describe dependencies; they are not batch
barriers. Release each eligible item as soon as its own prerequisites have
current accepted evidence. Prioritize owners with waiting descendants, then
waiting age. R83 and R84 may research generic OpenAPI fixtures before R71,
but their integrated acceptance must use R71's accepted generated schema.

The [dependency reconciliation](../docs/planning/p02/dependency-reconciliation.md)
records semantic compatibility beyond registered parameters. An absent edge
does not prove independence. Conditional answers must state their assumptions;
the controller checks them against selected designs before acceptance.

## 2. Effort, actors, and capacity

`research/EXECUTION.json` is the machine-readable policy. Every prompt mirrors
its tier, engines, evidence checks, and acceptance prerequisites under
`## Couplings`. The index continues to own scope and item status.

| Tier | Items | Required initial reports |
|---|---:|---|
| Light | 6 | Codex/Luna research and a fresh Terra evidence check |
| Focused | 53 | Codex/Terra and Claude Opus research |
| Deep | 25 | Codex/Terra, Claude Opus, and Doxa research |

R38 is Focused but its first binding pilot requires all three engines. Light
items are R22, R23, R24, R41, R46 and R47. The exact remaining allocation is in
the policy. Every tier retains the complete answer fields, fitness gates,
source dates, empirical checks, and dual audits. Light reduces initial engine
count, not the burden of evidence. No parameter owner is Light.

| Role | Default actor and responsibility |
|---|---|
| Controller | Astra reconciles evidence, scope, dependencies, costs and acceptance |
| Research worker | Terra for substantive Codex research; Luna for bounded Light research |
| Execution wrapper | Luna submits or collects one authorized operation and saves the receipt |
| Synthesizer | Fresh Claude Fable context that produced none of the item's raw reports or evidence checks |
| Empirical auditor | Fresh Codex/Terra context from a different model family than the synthesizer; reruns the check |
| Judgment auditor | Fresh Claude Fable context; examines principle, design and evidence |

Both auditors are distinct actors, neither a raw producer nor the synthesizer.
Record actor IDs, actual resolved models, and model families. Astra, Terra and
Luna share the OpenAI family; a fresh context is independent work, not a new
model family. Doxa's provider models must be recorded rather than described as
one independent model. Embedded model labels do not establish CLI model IDs.

At most four Claude calls may be active across research, synthesis and audit
roles. This host also has four active agent seats including the controller.
Reserve capacity for collection and validation; stop new admissions when two
completed items await acceptance review. Initially run one empirical build at
a time. Five to ten in-flight jobs are possible only when external provider
jobs release local workers and provider limits permit. A provider-wide auth,
quota or outage failure pauses new submissions to that provider.

Upgrade an item when evidence gaps or coupled uncertainty justify more work;
record the reason and revised per-item metadata, and obtain any additional
paid budget before submission. Downgrades require owner approval. No upgrade
silently changes a fixed requirement.

## 3. Durable execution and recovery

Use `scripts/research_runner.py` as described in the
[runner guide](../docs/planning/p02/runner-guide.md). It is a local state store
and publisher; it has no live provider adapter. The verified routes and gaps
are recorded in [tool readiness](../docs/planning/p02/tool-readiness.md).

Each run has a unique `research/runs/R##/<run-id>/` directory. Save the exact
prompt to `inputs/prompt.md`, its hash, the policy and prerequisite snapshots,
actual model identity, authorization reference, budget, operation IDs, state,
and output hashes. A short worker returns the run path, state, and next action.
It does not retain a long research result in conversation while waiting.

The worker records submission intent before calling a provider and persists
the returned operation ID immediately. Another worker can later poll or
collect that exact operation. If submission might have succeeded but no ID
was received, record `unknown` and reconcile provider inventory. Do not submit
again merely because the caller timed out. Doxa's inspected OpenAI and Gemini
clients have internal create retries without proven idempotency, and the OpenAI
SDK adds two retries of its own. Every paid Doxa invocation therefore runs
through `scripts/doxa_no_retry.py` under the Doxa virtual environment with
`--config docs/planning/p02/doxa-pilot.config.toml`; the wrapper rebinds every
provider submit to a single attempt (`--verify` prints the effective settings).
A failed create is recorded and reconciled by the controller: Perplexity exposes
a list endpoint for its async requests; OpenAI and Gemini expose none, so their
inventories are reconciled from the provider dashboards and the Doxa checkpoint
list (`doxa list --all --json`) against the recorded baseline.

Preserve every original response and failure under its run directory. Accepted
raw reports use unique names under the topic's `raw/` directory, with their
hashes in `acceptance.json`. Normalized output is a separate artifact linked to
the original. Narrowed prompts live at `inputs/narrowed.md`, never as a second
`*.prompt.md` that would violate the index-to-prompt bijection.

| Observed state | Next action |
|---|---|
| Slow or disconnected operation with an ID | Resume polling or collection by ID; release the wrapper while waiting |
| Ambiguous submission without an ID | Reconcile inventory and billing records; no automatic resubmission |
| Provider-wide failure | Pause that provider's admissions; continue independent local work |
| Partial multi-provider result | Preserve successful reports; retry only a proven unsubmitted or failed subset within approval |
| Cosmetic format defect | Save a lossless normalization and recheck shape; retain the original |
| Missing substantive evidence | Request bounded supplementary research with a reason and budget record |
| Budget exhausted | Preserve state and report the exact remaining work; no further paid submission |
| Changed prompt, policy, parameter or prerequisite | Invalidate affected acceptance and revalidate against current inputs |

This replaces the old automatic unchanged-retry-then-narrow sequence. Any
approved narrowing still requires `narrowed: yes — <reason>` in the decision
and must cover every required field and acceptance criterion.

Doxa `--combined` concatenates local provider outputs; it is not another model
call or a synthesis. One `all_deep_research` operation starts three provider
jobs. Retries and follow-up requests can increase that number. Operation
counts and timeout settings do not establish a hard spending ceiling.

## 4. Conflicts and changed baselines

A raw answer records `CONFLICT: R## <param> — <needed value> — <reason>` when
its recommendation needs a registered value changed. Keep the consumer
`in-progress`. Append the line verbatim under a new `### Conflict from R##`
subsection at the end of the owner's existing `## Context`; do not add a ninth
H2. Reopen the owner and rerun it. A new dated decision cites the previous entry
under `## Supersedes`; preserve the prior entry verbatim. Publish the registry
change together with the accepted owner revision, then rerun the consumer.

The controller adjudicates `BASELINE-REVIEW:` findings with the affected decision
owners using source evidence and alternatives. Preserve classification history;
reconcile ledger, index, prompt and dependency changes together. A consumer never
adopts an unregistered value. Reopen or mark stale every affected descendant
before publishing a changed owner decision; a historical approving audit cannot
approve a new decision revision.

## 5. Raw answers and acceptance

Run `scripts/check-answer-shape.sh <file> <crate|pattern|bundle> [override]`
before synthesis. Required fields must be in order, outside fences, and have
nonempty bodies. Each bundle member is an H4 under `### Members` and repeats
the complete crate fields at H5. A shape pass is not evidence of factual quality.

A fresh synthesizer writes `DECISION.md` with these H2s:

- `## Decision`: recommendation, version where applicable, settled `F###` rows,
  `### Principles and implementation`, and `re-verify: <date or event>`.
- `## Parameters`: exact owned and assumed values, including fixed parameters.
- `## Empirical check`: toolchain and OS, command, working directory, and observed
  output. Configuration, command and version-pin recommendations must execute.
- `## Engines`: all reports and evidence checks, disagreements, and the evidence
  that resolved each disagreement. State uncertainty when evidence is incomplete.
- `## Supersedes`: only for a reversal, with the prior dated entry preserved.

The required OpenTelemetry web example exercises an incoming request, handler,
outbound operation, context propagation, actual export and useful metrics. It
also checks exporter failure and shutdown behavior. An import or successful
startup alone cannot satisfy that requirement. Applicable web decisions must
show that their selected components support the integrated path.

Both auditors review the exact decision revision and report an explicit verdict
and any unresolved findings. The empirical auditor reruns the check. Acceptance
requires two approving verdicts with no unresolved findings, current consumed
values and prerequisite decisions, and complete evidence in topic
`acceptance.json` under the [acceptance schema](../docs/planning/p02/acceptance-schema.md).
The checker verifies structure, recorded identities, content hashes, and current
inputs. Auditors and the controller verify execution truth, source quality,
semantic compatibility, and the sufficiency of the observed behavior.

Use one publisher for shared files. Stage decision, raw evidence, audit,
registry, ledger and index changes; validate the candidate tree; then compare
current content with the expected hashes before applying the reviewed manifest.
A journal permits recovery after interruption. Refuse a second writer, stale
inputs, path escapes and unresolved publication recovery. Readers and queue
admission must wait until any incomplete publication is recovered. Only then
may an item be `resolved`. Do not overwrite prior raw evidence.

## 6. Pilot, batches, and re-verification

The first binding item is R38. Exercise three engines, fresh synthesis, both
audits, empirical execution, strict validation and publication end to end.
Record exact invocations, actual models, start/end times, operation IDs, provider
outcomes, measured usage and any retry. The earlier conformance pilot remains
deferred; tool-free readiness probes do not satisfy this binding pilot.

After the pilot and entry gates, admit eligible keystones R01, R42, R49 and R67,
and bounded Light work such as R47. Confirm each paid batch's item IDs, models,
maximum authorized spend and retry policy before starting its Doxa requests.
The approved allocation implies 26 initial Doxa operations including R38, or
78 initial provider jobs, versus 84 operations and 252 initial provider jobs
under the old method. It implies 188 initial research reports, 6 Light evidence
checks, 84 syntheses and 168 audits. These are planning counts, excluding
readiness calls, retries, upgrades and follow-ups; they are not dollar estimates.

The repository controller checks re-verification triggers quarterly and when
relevant changes occur. Rerun the affected item through the same gates. Any
changed decision hash invalidates consumers' recorded prerequisite evidence;
revalidate or rerun them according to the changed assumption, even if the
registered parameter value happens to remain the same.
