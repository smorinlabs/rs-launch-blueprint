# P02 execution proposal: proportionate research and durable parallel work

> Historical review text: approved 2026-09-04. See [APPROVAL.md](APPROVAL.md)
> for scope and [README.md](README.md) for the active implementation artifacts.
> References below to a proposed or unchanged contract describe the review baseline.

Status: proposed for owner review on 2026-09-04. The approved contract remains
`PROJECTS.md`, `research/RUNBOOK.md` and the design spec at
`2f3569051af2c2089f60f6cad129bc6e55482c30`. This document neither launches P02
nor amends those files. All 84 research items remain open.

Recommendation: use Astra for prioritization and exceptions, Terra for most
substantive research, and Luna for bounded verification and execution wrappers.
Store all working evidence and operation state in files. Reserve paid Doxa
research for decisions with material uncertainty, architectural consequences,
or unresolved conflicting evidence. Keep independent synthesis, two audits,
and executed acceptance checks for every decision.

This replaces a uniform process with a process whose research depth follows
the consequences of being wrong. It requires an explicit amendment to the
current three-engine requirement. The owner has authorized planning and smart
delegation; a proposed reduction in required research engines is not yet an
approved change to the binding acceptance contract.

## 1. Review packet and evidence

| File | Reader purpose |
|---|---|
| [contract-review.md](contract-review.md) | Exact failure scenarios, source lines and proposed repairs |
| [item-schedule.md](item-schedule.md) | All 84 provisional effort assignments, prerequisites and acceptance examples |
| [dependency-review.md](dependency-review.md) | Recomputed graph and proposed logging dependency changes |
| [dependencies.json](dependencies.json) | Machine-readable graph evidence |
| [tool-readiness.md](tool-readiness.md) | Installed, tested, untested and blocked capabilities |
| [baseline-samples.md](baseline-samples.md) | Pinned Python/TypeScript examples showing why baseline review remains necessary |
| [probes/](probes/) | Exact minimal Claude probe invocations and observed results |

The current P02 task list and full runbook were printed in the conversation
before evaluation. They are preserved separately in [current-plan.md](current-plan.md).
The older P01 document is a preparation plan, not a detailed P02 execution plan.

## 2. Current process compared with this proposal

| Concern | Current contract | Proposed behavior | Benefit and cost |
|---|---|---|---|
| Research depth | Every item receives Opus, Codex and Doxa deep research | Light, Focused and Deep levels, with explicit evidence and escalation rules | Removes unnecessary deep jobs; requires careful classification and contract amendment |
| Model roles | Research engines specified; local orchestration roles unspecified | Astra adjudicates, Terra investigates, Luna submits/collects/checks; scripts handle deterministic work | Expensive context is spent on judgment; receipts and schema checks become essential |
| Scheduling | Four dependency waves with possible barrier interpretation | Dispatch each ready item as capacity becomes free | A slow unrelated item cannot hold an eligible consumer; scheduler must validate dependency snapshots |
| Capacity | Four Claude subagents; other engines outside that count | Count local agent seats, Claude calls, Doxa operations, provider requests, empirical processes and validation backlog separately | Makes 5–10 in-flight items a conditional target; requires measured limits |
| Waiting | Out-of-process jobs mentioned; lifecycle incomplete | Persist operation IDs, release the submitting agent, later collect the same operation | No resident reasoning agent is needed during provider waits; durable recovery state is mandatory |
| Retry | Repeat whole engine run, then narrow | First classify failure; resume existing jobs; retry only failed work within approved budget | Preserves partial success and avoids accidental duplicate charges; ambiguous submissions can block one item |
| Synthesis | Fresh non-producer | Retained, with reserved capacity and explicit contributor identities | Prevents self-validation and accumulated raw-report backlog |
| Audits | Codex empirical audit and Fable judgment audit | Retained; named identities and model families are recorded | Cheaper models do not erase independence requirements |
| Shared files | No writer coordination specified | One controller publishes registry/index/ledger changes after validation | Prevents inconsistent assumptions; publication is intentionally serialized |
| P01 status | Complete markers despite missing tag | Record remaining tag and retained-worktree exception explicitly | Execution starts from truthful release state; historical handoffs stay available |

## 3. Effort rubric and acceptance contract

Classify impact, uncertainty, reversibility, ecosystem maturity, dependencies
and downstream influence separately. Do not add them into a score that lets
several low values cancel one architectural or security consequence.

Deep is required when consequential impact is coupled with unresolved
architectural uncertainty, expensive reversal or uncertain compatibility across
subsystems. Public contracts, runtime and crate boundaries, and security
behavior require that explicit assessment. Their presence alone does not make
a mature, documented setting a deep-research problem. Applying an established
standard under settled upstream decisions can be Focused when a discriminating
fixture establishes fit. Credible conflicting sources on a consequential
choice require Deep. A parameter owner is never Light. Zero recorded consumers
does not establish low impact: it can expose a missing dependency.

Focused applies when several viable options need a bounded integration
comparison, but the architecture and required outcome are sufficiently fixed.
Light requires low uncertainty, a mature mechanism, a local reversible effect,
and no unresolved consequential disagreement. The item table is provisional;
the pre-dispatch controller review can raise depth without new scope, within
the approved spend envelope. Lowering depth requires a recorded rationale.

| Level | Proposed research coverage | Minimum evidence | Example and stopping rule |
|---|---|---|---|
| Light | Luna produces a sourced answer; a fresh Terra worker independently checks the answer against primary evidence | Landscape and agreement level; applicable first-party documentation; relevant implementation example; explicit alternatives or justified absence; all applicable fitness gates; exact acceptance command | A local contributors-recipe option can stop when the documented behavior and fixture agree, the runner-up is explained and no material question remains. Escalate on nonlocal effects, contrary sources or a failed check. |
| Focused | Terra and Claude Opus independently investigate the same approved input packet | Significant alternatives; current primary evidence and relevant adoption; compatibility and failure behavior; maintained example and discriminating fixture | A bounded test/tooling choice stops after the fixture distinguishes the recommended option from the strongest alternative and all required questions are answered. Escalate if the choice changes runtime, topology or other items' assumptions. |
| Deep | Terra, Claude Opus and Doxa; Doxa provider outputs retained separately | Architectural alternatives; current authoritative/practice evidence; critical fitness gates; compatibility demonstration; realistic end-to-end example and failure cases | HTTP transport architecture or OTel integration stops only when the choice and runner-up condition are actionable, material disagreements have evidence-based dispositions, and the acceptance example passes. An exhausted budget yields blocked work, never a weaker answer labeled complete. |

The final provisional allocation is 6 Light, 53 Focused and 25 Deep items.
Light is an explicit per-item assignment, never a default inferred from zero
graph descendants. The Light set is R22 version accessor, R23 lockfile version
sync, R24 changelog mapping, R41 lockfile freshness, R46 license-header format,
and R47 contributors-recipe mode. R38 is Focused but runs all three engines
once as the pilot exception.

At these assignments, P02 requests 26 Doxa operations: the 25 Deep items and
the R38 pilot. That means 78 initial provider research jobs, compared with
252 for 84 three-provider operations under the original contract. Readiness,
escalations, retries, helper calls and provider-internal work are excluded from
both counts. This is a workload comparison, not a measured cost reduction.
There are 188 research-answer jobs and 6 separate Light evidence-check jobs,
for 194 initial report-producing jobs including the pilot exception. The 84
syntheses and 168 audits remain required.

Luna and Terra belong to the same OpenAI model family. Their separate Light
passes are separate contexts, not independent model families. The retained
Claude synthesis and judgment audit provide a different family's review.
Provider count is not a vote count: Doxa may itself use OpenAI, and multiple
engines can cite the same source. Evidence resolves disagreement.

Every level retains the named Landscape and Principles and implementation
fields, all applicable answer fields, source dates, explicit runner-up,
parameter assumptions, immutable raw evidence, independent synthesis, both
audits and a re-verification trigger. Pattern answers do not need invented
crate-download metrics. A reduced evidence protocol must name exactly which
metrics become inapplicable and why; it must be propagated into prompts and
the answer checker before any run uses it. Page count is not an acceptance rule.

If the owner retains three engines for every item, use the same scheduling,
durability and role changes but keep Opus, Codex and Doxa on every item.
Shorter prompts alone do not guarantee cheaper Doxa deep-research operations.

## 4. Agent roles and file handoffs

| Role | Preferred executor | Receives | Writes and returns |
|---|---|---|---|
| Controller | Astra | Contract, graph, bounded receipts and exceptions | Queue decisions, approved run packets, shared-file publication; reads full reports only for unresolved issues |
| Deterministic work | Script first; Luna when judgment is limited | Exact command, allowed paths, explicit completion conditions | Logs, exit status, parsed metadata, file hashes; no research conclusion |
| Research | Terra by default; Luna for Light; Opus and Doxa by tier | Prompt path plus frozen dependencies and evidence requirements | Full report to unique file; receipt with result state and evidence path |
| Submission/collection | Luna or script | Approved run manifest and exact output directory or operation ID | Submission envelope or status update; exits while provider work continues |
| Synthesis | Fresh Claude Fable worker | Shape-valid raw reports and approved input snapshot | Draft decision, empirical plan, disagreement dispositions; never produced a raw for that item |
| Empirical audit | Fresh Terra/Codex worker | Candidate decision and reproducible fixture | Re-executed command/output and accept/block verdict; OpenAI family differs from Fable synthesis |
| Judgment audit | Fresh Claude Fable worker | Decision and evidence | Principle/design/alternatives review with accept/block verdict; distinct from all producers |

The named audit files remain `audit-codex.md` and `audit-fable.md`. A filename
does not prove identity: record agent/session ID, provider, resolved model,
family, inputs and produced artifacts. A raw producer cannot audit that item's
decision. A synthesizer cannot write either audit. An agent that merely submits
a fixed command is an operator; if it chooses claims or edits conclusions,
record it as a producer. Rotate workers by item to satisfy these rules.

Do not carry the full conversation into simple workers. Give them a bounded
task packet with absolute working directory, exact source revision, input
paths, output ownership, acceptance criteria, permitted actions and stopping
conditions. A research worker needs enough context to understand the question;
saving tokens must not remove owner constraints or competing alternatives.

Each run gets a unique directory such as
`research/runs/R01/2026-09-04T120000Z-<unique-id>/`. Store inputs under `inputs/`,
raw engine outputs under `raw/`, operation state under `operations/`, and audit
drafts under `review/`. These paths are proposed until checker reconciliation.
Use `inputs/prompt.md` or `inputs/narrowed.md`, avoiding unindexed
`*.prompt.md` copies that the existing tree checker discovers.

The input manifest contains: item ID, run ID, authorization reference and
remaining budget, repository and source commits, prompt hash, effort level,
required engines, parameter values, owner-decision hashes, acceptance fixture,
allowed output paths and prior-run relationship. Preserve the exact input
bytes. Supply the same input packet to independent engines.

A worker returns this short receipt after writing its artifacts:

```json
{
  "item": "R01",
  "run_id": "unique-run-id",
  "state": "collected",
  "manifest": "research/runs/R01/unique-run-id/manifest.json",
  "artifacts": ["research/runs/R01/unique-run-id/raw/terra.md"],
  "operation_id": null,
  "exit_code": 0,
  "shape_check": "pass",
  "blockers": []
}
```

The controller uses the receipt to locate evidence; it does not accept the
worker's `pass` assertion without checking the recorded command and artifact.
Receipts contain no credentials or unnecessary account information.

## 5. Queue, capacity and failure recovery

The dependency graph is a directed acyclic graph: arrows point from a required
decision to its consumer. Recompute it from the prompts and registry after
every approved dependency change. Graph depth describes ordering, not elapsed
time. The measured slowest chain can only be identified after actual work.

An item becomes eligible when all recorded and approved semantic prerequisites
are resolved at the exact versions captured for its run. Among eligible items,
prioritize unresolved owners that unlock consequential work, then depth and
downstream influence, then waiting age. Independent early landscape gathering
is allowed, but remains provisional and cannot choose assumed parameter values.

The lifecycle below shows where an agent can exit while durable state remains:

```mermaid
flowchart LR
  A[Eligible item and approved budget] --> B[Write immutable input manifest]
  B --> C[Submit engine jobs and persist IDs]
  C --> D[Remote jobs running; submitting worker exits]
  D --> E[Collect each existing operation]
  E --> F[Shape and coverage checks]
  F --> G[Fresh synthesis and empirical execution]
  G --> H[Independent empirical and judgment audits]
  H --> I[One writer checks assumptions and publishes]
  E --> J[Partial failure: retain successes and reconcile state]
  J --> E
```

Only publication releases consumers. Finishing provider research does not
resolve an item. Each transition records its timestamp, actor, input hashes,
outputs and result. Internal states may include `ready`, `submitting`,
`submitted`, `running`, `partial`, `collected`, `shape-failed`, `synthesizing`,
`auditing`, `blocked`, `stale` and `resolved`. The existing index continues to
use its four allowed statuses; internal blocked/stale work maps to
`in-progress`, with the reason held in the run manifest.

Current host limit: four agent slots total, including the controller. This
allows three concurrent child agents, not ten. Five to ten research items can
be in flight only if external provider jobs continue after workers exit.
No provider concurrency quota has been inferred from the host's slot count.

Initial proposed limits are operating safeguards, not measured provider quotas:

- Keep the existing maximum of four concurrent Claude calls, counting Opus
  research, Fable synthesis and Fable judgment audits together. Start below
  that limit until tool-enabled runs are tested.
- Begin with one Doxa operation in the readiness test and pilot. Expand only
  after partial-result recovery and provider coverage pass and a paid batch is
  approved. Count each provider separately and count any combining-model calls.
- Reserve a local worker for collection and validation once reports finish.
  If two decisions await synthesis/audit, pause new submissions and drain them.
  The threshold is provisional and should be replaced using pilot measurements.
- Start with one empirical build process to avoid competing cargo locks and
  distorted timings. Grow only after measuring local resource use.
- Increase the in-flight item target from five toward ten only after two
  complete batches finish without authentication/quota faults, lost state or a
  growing validation backlog. The owner's paid envelope still bounds dispatch.

Before submission, atomically record `submitting` with a unique request ID.
Capture the returned operation ID and submission envelope before releasing the
worker. If the process dies between remote acceptance and ID persistence, mark
the submission `unknown`; reconcile with the provider operation inventory or
request identifier. Never infer failure and automatically submit again.

Polling and resuming an existing operation are separate from a paid retry.
Use short collector runs at a proposed 30–60 second interval with provider
backoff; do not hold a reasoning worker asleep. Polling cost and API limits
must also be verified. A deadline stops new local work and alerts the
controller; it does not prove the remote job stopped billing. Cancellation
needs the provider's supported mechanism and the agreed cancellation policy.

| Failure | Recovery |
|---|---|
| Authentication, quota or provider-wide fault | Stop new submissions for that provider; retain other completed results |
| Slow or interrupted job with an ID | Status/resume the same ID; no fresh ask |
| Partial multi-provider completion | Preserve successes and provider states; retry only the missing provider when the capability is supported and verified, with explicit remaining authorization. Otherwise block for a reviewed replacement run definition that discloses repeated work and cost. |
| Malformed answer shape | Keep raw report; determine whether deterministic normalization is lossless; otherwise use a bounded repair pass with provenance before considering fresh research |
| Truncated answer or substantive evidence gap | Target the missing evidence; if scope narrows, record it and retain all applicable acceptance gates |
| Stale dependency snapshot | Quarantine the draft; decide which reports depend on the changed value and rerun affected work |
| Crash during shared-file publication | Recover or roll back the entire staged publication from its journal; never expose a partly updated registry/index/ledger |

Exact raw bytes remain immutable. Normalized answers get their own paths and
hashes linking them to the raw input. Shape-valid text still needs substantive
review. Evidence of failure counts toward the retry history; it is never lost
when an adapter or synthesis worker changes.

At publication, place each accepted engine report under its topic's canonical
`raw/` directory using an engine name and unique run ID. Link it to the original
run artifact and any normalization diff. Keep failed and malformed attempts in
the durable run archive so the existing “all canonical raw reports pass” gate
does not reject retained failure evidence. Update `## Engines` and checker
path rules together; never overwrite an earlier canonical report.

## 6. Controlled publication and conflicts

Only one writer edits the shared registry, index and ledger. Workers write
isolated drafts. Immediately before publication, the writer compares the
manifest's prompt and dependency hashes with the current approved versions.
If anything material changed, publication is refused until the draft is
revalidated. Stage a patch, validate it, then apply a journaled publication.

The full publication predicate is: required engine coverage is complete;
substantive and shape checks pass; the acceptance command was executed with
captured output; both independent audits approve the exact decision hash;
no blocker or conflict remains; current prerequisite values and hashes match;
and the re-verification trigger is recorded. A nonempty audit saying REJECT
cannot satisfy acceptance. The structural checker alone does not establish
this predicate.

For a parameter conflict, preserve the existing conflict history rule: append
the exact line under an H3 in the owner's Context, reopen the owner, record a
new decision entry referencing the old decision, update the registry and rerun
the affected consumer. Never add a ninth prompt H2 section. Block descendants
that used a changed owner value until revalidated. A scheduler event log
records the difference between a text-only update and a changed parameter.

## 7. Reconcile the executable contract before binding research

| File or family | Concrete change to prepare after proposal approval |
|---|---|
| `docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md` | Add explicit amendments to A2/§11 engine coverage, A3 queue semantics, retry/normalization rules, approved semantic dependencies, provenance and audit identities. Align stale Windows wording with the fixed Ubuntu/macOS policy. |
| `research/RUNBOOK.md` | Replace invocation table with verified commands and role separation; document tier rules, budget manifests, durable lifecycle, failure classes, queue capacities and publication transaction. |
| `PROJECTS.md` | Link the approved P02 plan and verified writing-plans skill location; make P01 tag status truthful; refine T01–T06 execution/acceptance checks without prematurely checking them off. |
| `research/PROMPT-TEMPLATE.md` | Put effort-specific scope and acceptance in existing H2 sections; retain required field names and record prerequisite snapshots in the run packet. |
| All 84 canonical prompts | Propagate approved tier/evidence clauses and corrected constraints; modify affected couplings together. Do not rely on this proposal as hidden engine context. |
| `docs/port/PARAMETERS.md`, `research/CLAUDE.md` | Add only approved owners and dependencies; keep current statuses until binding execution passes. |
| `docs/port/COMMONALITY.md` and affected area/derived documents | Reconcile adjudicated baseline findings with preserved source evidence and verdict history; do not infer scope changes from convenience. |
| `scripts/check-answer-shape.sh` | Define tier-specific applicable evidence, provenance and normalization validation without confusing raw shape with decision correctness. |
| `scripts/check-research-tree.sh` and meaningful regression fixtures | Cover run-input placement, cycle detection, resolved acceptance evidence, model-family/producer metadata and parameter consistency as applicable. Preserve all current failure-exit safeguards. |
| Proposed runner and state store | Implement only after plan approval; exercise crash recovery, partial provider failure, duplicate submission refusal, stale snapshots and writer contention with local fake providers before paid use. |

The planning output does not implement the runner. The audit identifies its
required observable behavior so the implementation is reviewable before paid
dispatch. Tests must discriminate broken behavior, rather than mirror a state
label returned by the same implementation.

## 8. P01 gate and approval boundaries

Local and remote `main` were checked at `2f3569051af2c2089f60f6cad129bc6e55482c30`.
`git ls-remote --heads --tags origin main v0.1.0 'v0.1.0^{}'` returned only
`refs/heads/main`: no remote tag. The existing complete markers are inaccurate.

Recommended reconciliation: retain the historical research worktree to protect
its three handoffs, record that retention as an explicit exception, and restore
P01/P01-T05 to an incomplete state until the release tag is published and
verified. Prepare the tag at the P01 merge commit above, with the historical
Task 18 annotation. Present the concrete tag operation for approval before
publishing it. The new planning branch is based on merged main and does not
reuse the completed P01 branch.

After this proposal is reviewed, prepare the contract diff and runner, perform
relevant local checks, and request the commit approval required by the handoff.
The run contract and Doxa budget are separate authorizations. No proposal
approval implies an unlimited research budget, a commit, a tag push or a merge.

## 9. Recomputed dependencies and remaining semantic review

The recorded graph has 84 nodes and 66 edges. Its four layers contain 33, 19,
15 and 17 items. A longest chain is R01 transport seam → R69 web surface →
R11 CI job structure → R08 workflow permissions. There are other equally long
chains; none is a measured elapsed-time critical path.

R01 has 37 unique downstream items and R11 has 17. However, 77 of the 84 nodes
have zero recorded descendants. The graph deliberately models only registered
ownership relations, so it is not proof that those other decisions are
independent. The item table treats runtime, public API and security consequences
separately from graph counts.

Proposed minimum R58 amendment: register `logging-pipeline-contract`, the
logging architecture's initialization/extension interface, structured fields,
redaction behavior, host ownership, CLI/web profiles and OTel boundary. R58
owns that value; R59 file sink, R75 HTTP middleware and R78 OTel integration
consume it. The value must describe the selected native design without
presupposing a particular crate or subscriber implementation.

R58 already consumes R69. The amendment adds three edges and gives 69 total
edges, still acyclic. Layers become 32, 19, 13 and 20 items; the longest depth
remains three edges. Both R01 → R69 → R11 and R01 → R69 → R58 now lead to
third-level consumers. This is one specific fix, not a claim that semantic
dependency review is complete.

Before binding dispatch, review all prompt statements that say “depends on”,
“uses”, “after” or otherwise assume an undecided design. Classify each as a
research prerequisite, an integration-acceptance prerequisite, or contextual
evidence. Publish those explicit dependencies before scheduling affected work.
For example, R84 typed-client generation can investigate against a generic
schema early, but cannot pass its integrated acceptance against the chosen
schema until R71 OpenAPI generation is accepted. Treat R71 as an acceptance
prerequisite for R84, without adding a blanket research edge through unrelated
CI work. Recheck R01/R05 transport/runtime boundaries before R01 is finalized.

No item may be marked resolved using an unfinished prerequisite's hypothetical
fixture. If a generic fixture is useful early, label the result provisional
and rerun the integrated acceptance and relevant audits after the dependency
resolves. Temporary fixtures belong outside the Rust template source; P02 does
not implement the template itself.

## 10. Readiness, bounded pilot and first parallel batch

Readiness outcome: the embedded Terra/Luna/Astra workers executed successfully.
Claude Opus and Fable passed actual tool-free nonce requests. Doxa is locally
callable, but authenticated provider access and asynchronous collection remain
unverified. This is enough to prepare the plan, not enough to authorize bulk
execution.

The Claude probes used one prompt each and a `--max-budget-usd 0.10` limit per
CLI invocation. They returned `P02_READY_20260904` with `is_error: false`.
Resolved models were `claude-opus-5` and `claude-fable-5-1`. Measured wall times
were 3.705 and 7.786 seconds; these tiny tests do not forecast research duration.
The combined reported list-price usage was `$0.072418`, including Haiku helper
usage. These are CLI-reported accounting values, not verified invoice charges.
Normal `claude auth status` reported no login, so readiness is established for
the exact successful `--safe-mode` launch route only. Web/tool-enabled research,
background recovery and longer prompts remain pilot requirements.

The missing `codex-companion.mjs` was located at
`/Users/stevemorin/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs`.
It has task/status/result commands, but its background lifecycle was not run.
The host's Terra/Luna aliases are not proven CLI model names. Prefer the
demonstrated embedded worker route for Codex work until companion model access
and recovery are tested. The writing-plans skill also exists in plugin caches;
its absence in the earlier catalog does not mean the file is unavailable.

Doxa's direct executable is
`/Users/stevemorin/c/doxa-research/.venv/bin/doxa`. It imports source at
`ba423be7e96461962ae0fde21373e5e10aeecae2`, whose project version is `3.2.0`,
but reports stale installed metadata `3.1.2`. Record both facts. Resolve a
reproducible package/source and dependency pin before a binding run; do not
silently describe this as a clean 3.2.0 installation or modify that source
checkout, which has two local commits ahead of its tracking ref.

The normal research-checkout credential check and a read-only resolution check
of the legacy Doxa configuration found no usable OpenAI, Perplexity or Gemini
credential. Only presence and resolution state were recorded; no values were
printed. The pending user question asks for an existing credential source path,
not key values. Installed/configured commands are not authenticated access.

The inspected `all_deep_research` mode requests these logical jobs:

| Unit | Requested model | Intended new research jobs per operation |
|---|---|---:|
| OpenAI | `o3-deep-research` | 1 |
| Perplexity | `sonar-deep-research` | 1 |
| Gemini | `deep-research-preview-04-2026` | 1 |
| Combined report | Local concatenation in the inspected source | 0 |

Those are initial logical research-job counts, not a limit on internal model
calls, HTTP requests, token usage or dollars. Doxa submits the three provider
jobs sequentially; remote execution can overlap. OpenAI and Gemini create
retries can duplicate jobs after ambiguous timeouts. Before paid readiness,
disable automatic create retries where supported or use a reviewed adapter
that records an unknown submission without repeating it. A wrapper around an
unchanged client cannot prevent hidden SDK or provider-client retries. Verify
the effective behavior with a fake accepted-then-timeout provider.

**Prepared Doxa readiness test:** one prompt,
[`probes/doxa-readiness.prompt.txt`](probes/doxa-readiness.prompt.txt), submitted
once through `all_deep_research --combined --async --json`. Intended providers:
OpenAI, Perplexity and Gemini. Intended jobs: three. Output root:
`docs/planning/p02/probes/doxa-readiness-01/`, with checkpoints under the same
approved run tree. Preserve the submission envelope and exit, then use a
fresh collector process to status/resume the recorded ID and verify all three
reports plus the combined file. The test does not resolve a P02 item.

No paid Doxa run is approved or submitted. The inspected client has no hard
dollar ceiling across these three deep-research providers. A short prompt and
30-minute wait limit do not cap spend. Once credentials and retry behavior are
settled, present one exact paid-run definition with either an enforceable
provider spending limit or an explicit owner-approved job-count boundary whose
variable cost is understood. Do not invent a dollar estimate from the tiny
Claude probes. If the owner requires a hard dollar limit and it cannot be
enforced, the paid test remains blocked.

**First binding pilot:** R38 commit-message convention, after full baseline
review, contract reconciliation, tag completion and readiness approval. R38
owns a real parameter, has no research prerequisites, and supports explicit
valid/invalid header/body/footer fixtures. It exercises parameter publication
without first requiring unresolved HTTP/runtime architecture. Run Terra,
Opus and Doxa on the same canonical R38 packet. Doxa requests one operation
and three provider jobs; combining requests no extra model job in the inspected
version. A fresh Fable worker synthesizes, a fresh Terra auditor reruns the
fixture, and a separate Fable auditor judges the rationale. Publish only when
both approve that exact decision revision. The pilot's Doxa spend needs its
own approved envelope; readiness approval does not cover it.

**First batch after the pilot:** five currently independent items:

| Item | Decision | Proposed effort | Why this batch |
|---|---|---|---|
| R01 | Transport injection seam | Deep | Starts the longest recorded dependency chains |
| R42 | Developer tool provisioning | Deep | Owns invocation assumptions consumed by tooling decisions |
| R49 | Build targets and artifact shape | Deep | Owns artifact assumptions for testing and release |
| R67 | Error taxonomy and process exit codes | Deep | Owns error behavior consumed by configuration and HTTP decisions |
| R47 | Contributors-recipe mode | Light | Exercises the small-item path alongside architectural work |

The four Deep items request four Doxa operations and 12 initial provider jobs.
R47 requests none under the proposed tier amendment. The batch also requests
four Opus research jobs, four Terra Deep research jobs, one Luna Light answer
and one independent Terra Light check. Each item still has one fresh synthesis
and two audits: five syntheses and ten audits across the batch. These counts
exclude helper calls, retries and acceptance-process invocations. They are
work volumes, not concurrent-slot claims. Start R01 first; interleave the
remaining work with the available slots and the approved Doxa envelope.

Measure submission latency, provider completion time, successful provider
coverage, active worker time, output tokens/usage, shape-repair frequency,
synthesis wait and duration, empirical duration, audit duration and revision
count, and peak validation backlog. Capture timing from submission through
resolution, including waits. If Light work repeatedly escalates, raise the
entry threshold. If synthesis or audits accumulate, lower admission rather
than merely adding research jobs. Publish no speedup or cost-saving percentage
until comparable complete items have measured results.

## 11. Proposed next execution sequence

These are proposed tasks, not work completed in this planning session.

1. Review the tier amendment and per-item table with the owner. Apply accepted
   changes to the contract, then reconcile the baseline review and semantic
   prerequisites. Keep newly discovered scope separate for owner disposition.
2. Resolve the P01 tag/status discrepancy and pin the research tool execution
   environments. Verify credential sources without exposing values.
3. Implement and locally validate durable operation state, retry behavior,
   worker receipts and controlled publication. Inject partial failure,
   accepted-then-timeout, process restart, stale assumptions and writer
   contention before any live paid job.
4. Present the concrete paid readiness definition, secure any missing approval,
   then run and recover one Doxa operation. Complete web/tool-enabled Claude
   and selected Codex execution-path checks while remote work runs.
5. Present the R38 pilot envelope. After approval, run it through all engines,
   empirical validation, independent synthesis/audits and parameter publication.
   Gate further research on successful recovery and acceptance evidence.
6. Present the five-item batch envelope. After approval, dispatch eligible
   work incrementally with validation capacity reserved. Use measurements to
   decide whether five to ten items in flight is sustainable.
7. Continue accepted items, resolve conflicts and perform revision-bound
   acceptance. Run the final structural gate and substantive audit inventory.
   Present reviewed commits, PR, merge and v0.2.0 release actions under the
   owner's existing approval rules.

## 12. Owner decision

Adopt the tiered engine coverage with empirical checks and both audits retained,
or keep the original three-engine coverage while adopting the queue, role and
recovery improvements. Recommendation: the tiered proposal. It concentrates
deep research on consequential uncertainty while every accepted decision still
receives independent validation. The alternative retains broader raw-engine
coverage and the original Doxa volume. The owner may revise individual tiers
or coverage rules before either contract is applied.

Exact response requested: approve the tiered proposal, retain three engines,
or identify the rule/items to change. This decision does not approve a paid
batch, commit, tag push or merge.
