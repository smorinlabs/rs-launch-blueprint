# Runbook — executing the research tree (spec §10–§11)

This file binds the session that runs the prompts (project P02). Nothing here is optional.

Owner review (Phase 3.5, 2026-09-04): every index item is `accept` in `docs/port/OWNER-REVIEW.md`. Its later clarification (spec §2/A5) binds every run: research engineering principles, architectures, and ecosystem practices; select the libraries that best realize the intended outcomes. Existing implementations supply evidence and lessons. A shared principle may require different designs in different ecosystems. The 60 cross-repo questions assess that distinction; they do not require one value. Earlier owner quotations remain historical evidence, interpreted under the later clarification.

Before bulk execution, P02-T01 reviews the REUSE and ADOPT baselines for mechanisms that were treated as requirements merely because a source repo used them. Record the principle, evidence of present fitness, and any affected research item. Unsupported or challenged choices receive a `BASELINE-REVIEW: F### — principle — proposed change — evidence` finding. Reconcile affected ledger rows, prompts and dependencies using the existing verdict vocabulary before dispatching dependent research; a new item still requires the owner's disposition. Do not assume that a green structural checker proves architectural fitness.

## 1. Run order
- Fixed parameters (`docs/port/PARAMETERS.md`, kind `fixed`) are already valued; never research them.
- Order is computed from the prompts, never hand-maintained, by two edge rules (owner direction 2026-09-04): (a) **registry dependency** — every `R##` on an item's `- consumes:` line is a hard edge; (b) **keystone dependency** — an item that owns no parameter and names a parameter owner on a `- related` line runs after that owner. Parameter owners today: R01, R11, R38, R42, R49, R67, R69 (`- owns:` non-empty). Mutual mentions and an owner's mentions of its consumers are not edges. On the current tree the rules are acyclic and give four waves — 33 · 19 · 15 · 17 items — with the critical path R01 → R69 → R11 → the CI-wired tooling items. R58 (`logging-pipeline-architecture`) is a hub three web items lean on without a registry edge; the P02 plan decides whether to promote it to a parameter owner.
- An item runs only after every item it has an edge to is `resolved`. Items in the same wave are independent and run **in parallel**, limited only by §2's concurrency cap; keystones go first within their wave because the most items wait on them.
- Script (prints "item dependency" pairs; feed to `tsort` for a topological order; a cycle is a tree defect, fix the prompts):
  ```bash
  owners=$(for p in research/topics/*/prompts/*.prompt.md; do awk '/^- id:/{id=$3} /^- owns:/ && NF>2 {print id}' "$p"; done | sort -u)
  for p in research/topics/*/prompts/*.prompt.md; do
    id=$(awk '/^- id:/{print $3; exit}' "$p")
    hard=$(awk '/^- consumes:/' "$p" | grep -oE 'R[0-9]{2}' | sort -u)
    soft=""
    if ! printf '%s\n' "$owners" | grep -qx "$id"; then
      soft=$(awk '/^- related/' "$p" | grep -oE 'R[0-9]{2}' | sort -u | grep -xF -f <(printf '%s\n' "$owners") | grep -vx "$id")
    fi
    for d in $hard $soft; do echo "$d $id"; done; echo "$id $id"
  done | tsort
  ```

## 2. Engine invocation
Every item is researched by **every configured engine, in parallel, each run as its own subagent** (owner direction 2026-09-04); no engine's answer is the decision by itself.

| engine | how it runs | raw output |
|---|---|---|
| Claude Opus | `Agent` tool subagent, model `opus`, with web access; given the prompt file path and told to fill the answer template | `raw/opus-<YYYY-MM-DD>.md` |
| Codex | Codex companion job (`codex-companion.mjs`), out of process, collected with `status <job> --wait` | `raw/codex-<YYYY-MM-DD>.md` |
| Doxa deep research | `doxa ask --mode all_deep_research --prompt-file <prompt> --output-dir raw/doxa --combined --async --json` (`doxa-research` skill); paid — the owner confirms each wave before submission | `raw/doxa-<YYYY-MM-DD>.md` |

- Input: the item's `prompts/<slug>.prompt.md`, unmodified, for every engine. The owner-typed `/deep-research` skill may be added as a fourth engine by the owner; it is not required.
- Concurrency cap (owner decision 2026-09-04): at most **4 Claude subagents** at once (spec §6 burst rule); Codex and Doxa jobs run out of process and do not count, so a wave fans out per engine.
- Before anyone reads a raw answer's content, check it fills the template:
  ```bash
  scripts/check-answer-shape.sh research/topics/<nn>-<slug>/raw/<file> <crate|pattern|bundle> [override]   # exits 1 listing missing fields
  ```
- Synthesis: a subagent that produced none of the raws writes `DECISION.md` (§5) from all of them, recording under `## Engines` which engines ran, where they disagreed, and which evidence settled it. The producer rule for audits (§5) still holds.
- The first real run (P02-T01) records the exact invocations, models and dates here.

## 3. Failure and retry
1. Engine error or a shape check failure → re-run once, unchanged.
2. Second failure of the same engine → narrow the prompt to its `HIGH` questions only (edit a copy `prompts/<slug>.narrowed.prompt.md`; the original stays), re-run, and record `narrowed: yes — <reason>` in `DECISION.md ## Decision`.
3. Third failure → stop the item, set `status` to `in-progress`, and escalate to the owner with the three raw outputs.

## 4. Conflict rule
- An answer whose `Parameters` field contains `CONFLICT: R## <param> — <needed value> — <reason>`:
  1. the consuming item is **blocked** (status stays `in-progress`; no `DECISION.md`);
  2. the owner item `R##` is re-opened: append a `### Conflict from R<consumer>` subsection with the line verbatim to the **end of the owner prompt's `## Context`** (append-only), and re-run it;
  3. the owner's new `DECISION.md` entry cites the old one under `## Supersedes`;
  4. `PARAMETERS.md` is updated from the owner's new value; only then does the consumer re-run.
- A consumer never adopts a value the registry does not hold.
- A `BASELINE-REVIEW:` finding is adjudicated by the controller with the affected decision owners, using the cited evidence and alternatives. Preserve the original classification and rationale in the decision history; update the ledger, index, prompts and dependency order together before affected decisions become `resolved`. Explicit owner requirements are not changed by this process. If new research scope or an owner requirement must change, bring that specific decision to the owner.

## 5. Answer → decision
`DECISION.md` in the topic directory has exactly these H2s (the checker enforces the first three):
- `## Decision` — the pick with version, the ledger rows (`F###`) it settles, and `narrowed:` if §3 applied.
- `## Parameters` — one line per owned parameter `- owns <param> = <value>` (copied verbatim into `PARAMETERS.md`) and per consumed parameter `- assumes <param> = <value>`.
- `## Empirical check` — toolchain (`rustc --version`, OS), the exact command run, and the observed result. A recommendation that is a configuration, command, or version pin is not accepted until this section shows it executed (spec §10).
- `## Supersedes` — only when reversing an earlier entry: the entry's date and what changed. Entries are never edited in place; a reversal is a new dated entry above the old one.
- `## Engines` — one line per engine run (`<engine> raw/<file>`), the disagreements between them, and the evidence that settled each (§2 synthesis).
The synthesized decision retains the answer template's `### Principles and implementation` under `## Decision`: outcomes and acceptance criteria, architecture alternatives, library selection rationale, useful ecosystem differences, and reference examples. For web and observability decisions, the empirical check exercises a real request path using the selected libraries, including the applicable trace propagation, export, metrics and failure behavior. A successful import or startup alone is insufficient. Auditors assess this substance in addition to field presence.
An item is `resolved` only when `audit-codex.md` (different model family; re-runs the empirical check) and `audit-fable.md` (judgment) both exist and are non-empty. The producer of an answer never writes its own audit.

## 6. Staleness
- Every `DECISION.md` ends its `## Decision` with `re-verify: <date or event>` copied from the answer's *Confidence & re-verify trigger* field.
- When a trigger fires, the owner of this repository re-runs that single item under §2–§5; consumers re-run only if the owner's `## Parameters` changed.
- A quarterly sweep (`grep -h 're-verify:' research/topics/*/DECISION.md`) lists triggers due.
