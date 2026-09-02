# How the TypeScript port researched — review for the Rust program

Produced 2026-09-01 by an independent review agent reading
`ts-launch-blueprint/docs/port/` (goal.md, typescript_port_process_prompt.md,
TS_PORT_RESEARCH.md, TS_EXISTING_REPO_REVIEW.md, TS_PORT_DECISIONS.md,
TS_PORT_LOG.md) and `py-launch-blueprint/research/`. Path prefixes:
`TS/` = `ts-launch-blueprint/docs/port/`, `PY/` = `py-launch-blueprint/research/`.
The recommendations were folded into the design spec the same day.

## 1. Method as executed

- **Roles.** Planning, classification, gate adjudication: Fable in the main
  loop, never delegated (`TS/goal.md:21`). Research legwork: sub-agents, never
  the main loop (`TS/goal.md:22`). Validation: sub-agents that did not produce
  the work (`TS/goal.md:24`).
- **`/deep-research` was never invoked.** D-003 is titled "/deep-research
  prompting for research phases" (`TS/TS_PORT_DECISIONS.md:22-25`), but Phase 3
  ran "workflow fan-out, one agent per repo… with deep-research-*style*
  prompting" (`TS/TS_PORT_LOG.md:182-186`) and Phase 4 "one deep-research agent
  per topic… with WebSearch/WebFetch" (`TS/TS_PORT_LOG.md:256-257`), workflow
  `wf_09df6180-960` (`:280`). "Deep research" meant a discipline (verify every
  claim against primary sources, cite path+line, separate observed fact from
  inference), not a tool. By contrast the py typing research ran a real engine:
  "deep-research run `wf_0c1ce514-5dd` (104 agents, 22 sources, 25 claims
  verified → 23 confirmed / 2 refuted)" (`PY/topics/01-python-typing-best-practices/DECISION.md:5-6`).
- **Topic selection was closed, not free-form.** Fourteen topics came from
  three sources: every domain-spec research area, every `Needs research` item in
  the INDEX, and the 7 tie-breaks the Phase 3 synthesis raised
  (`TS/TS_PORT_LOG.md:243-245`). Scope was one topic per tool-choice *cluster*.
- **Per-topic answer template — 11 fields**, present in 14/14 topics
  (`TS/typescript_port_process_prompt.md:307-329`): Source Python tool or pattern
  · Purpose in the original project · Existing repo decision, if any · Decision
  classification · Options considered · Recommended choice · Rationale ·
  Tradeoffs · Migration implications · Validation strategy · Decision status.
- **Decision classification was a closed set of six**
  (`TS/typescript_port_process_prompt.md:237-244`); T01 applied it per
  sub-decision rather than per topic (`TS/TS_PORT_RESEARCH.md:64-70`).
- **Evidence bar:** latest version + publish date + maintenance recency +
  primary-source URL + verification date. "All tool maturity facts verified
  against primary web sources on 2026-07-07 — no choice settled from memory
  (D-003)" (`TS/TS_PORT_RESEARCH.md:6-7`). 116 URLs (github.com 35,
  registry.npmjs.org 11). Download counts appear in only 10 places; GitHub
  stars nowhere. The discriminating signal was **dormancy**: VitePress was
  rejected on "~11 months without a stable release… no maintainer response…
  re-verified 2026-07-07" (`TS/TS_PORT_RESEARCH.md:1456`) despite 601,969
  weekly downloads, more than the winner.
- **Decision path.** Research produced *Proposed* only
  (`TS/TS_PORT_RESEARCH.md:32-33`); two validators per recommendation
  (`TS/goal.md:178`) — one re-fetching cited URLs, one checking consistency
  against the repo review; Fable adjudicated at the gate; adjudications became
  new decision entries D-025–D-028 (`TS/goal.md:121-123`).
- **Research → plan.** Each topic → one decision entry, cited as `D-0NN(k)`
  (`TS/TS_PORT_RESEARCH.md:11-13`); every plan slice cites decision ids;
  validators flag orphans (`TS/goal.md:179`).

## 2. What worked (copy)

1. Prior-decision review as a hard prerequisite: "Do not create
   `TS_PORT_RESEARCH.md` before reviewing relevant existing repos"
   (`TS/typescript_port_process_prompt.md:659`); it produced a named conflict
   list (`TS/TS_EXISTING_REPO_REVIEW.md:603-611`) that became the topic list.
2. Skipped repos recorded with reasons (`TS/TS_EXISTING_REPO_REVIEW.md:34-44`).
3. `Tradeoffs` names the *accepted cost*: "**vs pnpm**: gives up faster
   installs, strict node_modules isolation… Accepted because…"
   (`TS/TS_PORT_RESEARCH.md:110`).
4. `Migration implications` is a file-level change list (`:119-125`).
5. `Validation strategy` is executable: "`npm ci` + `git diff --exit-code
   package-lock.json` proves the committed lockfile is authoritative" (`:132`).
6. Append-only supersession (`TS/goal.md:122-123`); D-026 → D-038 is legible
   as a double flip because nothing was rewritten.
7. Producer never validates own work; validators verify against primary
   sources, not summaries (`TS/goal.md:76-77`, `:82-84`).

## 3. What went wrong

- **Cross-topic contradiction was the dominant failure**, not sourcing:
  validators passed on facts except one, but "surfaced 3 cross-topic
  contradictions. 4 blocking findings total" (`TS/TS_PORT_LOG.md:296-299`).
  Color decided twice (T06 picocolors vs T08 `node:util` styleText — D-026,
  `TS/TS_PORT_DECISIONS.md:353-357`); CI Node matrix decided twice (T01 vs T12 —
  D-027, `:359-363`); T02's tsdown pick silently depended on
  `isolatedDeclarations`, mentioned only by T02 (D-025, `:347-351`). Two more
  surfaced at the plan gate (D-031 `:383-387`, D-032 `:389-393`).
- **One factual error survived to validation:** T14 called
  `contributor-assistant/github-action` actively maintained; it is
  `archived=true` (D-028, `:365-369`). One in 97 recommendations.
- **Four owner reversals after "PORT COMPLETE"** (`TS/TS_PORT_LOG.md:479`): on
  2026-07-10 the owner switched to pnpm 10 (D-035), color back to picocolors
  (D-038), added a Bun lane (D-036), pre-approved TypeScript 7 (D-037). Cost:
  three swap branches, one spike, "~25 files" for pnpm alone (`:501`).
- **Root cause: the owner gate was waived.** `TS/goal.md:143-150` requires
  owner approval of `TS_PORT_RESEARCH.md`; "User approvals: waived throughout
  per the recorded 2026-07-06 instruction" (`TS/TS_PORT_LOG.md:488`). The
  picocolors item flipped twice on a zero-dependency premise the owner never
  shared.
- **Anchoring cut both ways.** The one place research overturned org precedent
  (Oxlint+Oxfmt over Biome, `TS/TS_PORT_LOG.md:283-284`) survived; the
  org-uniform npm pick was the one the owner reversed.
- **Operational:** Phase 4's first dispatch "13/14 agents failed; re-run in
  batches of 3–4 via workflow resume" (`TS/TS_PORT_LOG.md:291-293`); Phase 3
  cost 449k tokens for 8 agents (`:206`); "~45 minors (citation offsets,
  wording precision)" accepted unfixed (`:316-318`) — fan-out agents drift ±1
  on line citations.
- **The prompts were never committed.** Only the 11-field answers exist; the
  questions that produced them are unauditable.

## 4. Rust design versus TS practice

Stronger in the Rust design: prompts are the deliverable; quantitative ranking
evidence (D8); a mechanical structural check; a closed verdict set with an
override ledger; a named independent reviewer.

Weaker before revision (now addressed in the spec): no shared-parameter
ownership (→ §6.3 couplings); no `Tradeoffs` / `Migration implications` /
`Validation strategy` / confidence / runner-up fields (→ §7.7); no "existing
decision, do not re-decide" field (→ §7.2); no owner review slot (→ Phase 3.5,
not waivable); no empirical verification (→ §10); 12-agent burst (→ batches of
3–4); no citation sampling (→ §8).

## 5. Recommendations adopted

| # | Recommendation | Where it landed |
|---|---|---|
| R1 | Couplings / single ownership of shared parameters, script-enforced | spec §6.3, §7.4, §8; `check-research-tree.sh` step 3 |
| R2 | Owner technology-selection review as a non-waivable phase | spec §6 Phase 3.5 |
| R3 | Empirical gate before a DECISION is accepted | spec §10 |
| R4 | Dual-lens audit files (`audit-codex.md`, `audit-fable.md`) before `resolved` | spec §5, §10; script step 5 |
| R5 | `Ranked runner-up`, `Tradeoffs`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger` in the answer template | spec §7.7 |
| R6 | Framing: objective with value test, out-of-scope list, prioritized questions | spec §7.1, §7.3, §7.5 |
| R7 | Dormancy named in D8; every figure dated and sourced | spec D8 |
| R8 | Batch fan-out 3–4; reviewer samples `path:line` citations | spec §6 Phase 1, §6.2, §8 |

Best existing prompt exemplar for §7's shape:
`PY/topics/01-python-typing-best-practices/prompts/01-python-typing.prompt.md`
(Objective naming the consumer and specificity · Context pre-empting clarifying
questions · priority-labeled questions · output shape leading with a
decision-ready summary).
