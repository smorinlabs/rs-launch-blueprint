# rs-launch-blueprint — port research program (design)

**Status:** approved design, 2026-09-01; revised the same day after a review of
how the TypeScript port's research was actually executed
(`docs/port/ts-research-method-review.md`). Governs Phase 0–5 of preparing a
Rust sibling of `py-launch-blueprint` and `ts-launch-blueprint`. The port itself
is out of scope; this program ends with a research tree whose prompts a later
session executes.

## 1. Purpose

Decide, with evidence, which parts of the two existing launch blueprints carry
over to a Rust template unchanged, which need a Rust tool substituted under the
same pattern, and which — rarely — justify changing the pattern. Every open
choice becomes one deep-research prompt with a fixed answer template so results
are comparable, and the prompts themselves are committed (the TS port kept only
its answers, so its questions are unauditable).

## 2. Governing rule — presumption of reuse

Anything `py-launch-blueprint` and `ts-launch-blueprint` do the same way is
inherited by `rs-launch-blueprint` by default. Deviating requires a very strong
Rust-specific reason. Every deviation is labeled **OVERRIDE** in
`docs/port/COMMONALITY.md` and in the item's decision record, and carries the
argument and the options that were considered.

Distinguish the **pattern** from the **tool**. "One formatter + one linter, run
in CI and in the pre-commit hook" is a pattern shared by both repos; `ruff` and
`oxlint`/`oxfmt` are the language-bound tools that implement it. Replacing the
tool is a **substitution**, not an override. Only a change to the pattern is an
override.

## 3. Verdict vocabulary (closed set)

| Verdict | Meaning | Research prompt |
|---|---|---|
| `COMMON → REUSE` | Same in py and ts; language-neutral | none |
| `COMMON → SUBSTITUTE` | Same pattern in both; tool is language-bound | yes — "top 5 Rust tools implementing this inherited pattern" |
| `COMMON → OVERRIDE (OV-nn)` | Same in both; a strong Rust-specific reason to change the pattern | yes — burden of proof on deviating |
| `DIVERGENT` | py and ts differ | yes — which precedent, and the Rust options |
| `RUST-ONLY` | No precedent in either repo | yes |
| `OMIT` | Python/TS-only, no Rust analogue | none |

`OV-nn` is a sequential id. Each one has a section `### OV-nn` under
`## Override arguments` in `COMMONALITY.md` containing `**Argument:**` and
`**Options:**` lines.

## 4. Decisions fixed in the interview (2026-09-01)

| # | Decision |
|---|---|
| D1 | Source of truth: both repos analyzed, then merged (Option C: area-first agents reading both repos plus `ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md` for their area) |
| D2 | Finish line: inventories + shell repo + research index + prompts. No research execution, no port code |
| D3 | Repo: `~/c/rs-launch-blueprint` → `smorinlabs/rs-launch-blueprint`, public, docs-only (no `cargo init`) |
| D4 | Granularity: one research item per choosable tool or pattern |
| D5 | Engine: `guided-research` tree layout; prompts shaped for `/deep-research`, runnable by Doxa. **Note:** the TS port never invoked `/deep-research` (it used fan-out agents with WebSearch), so the engine's output shape is untested for this template — see §10 pilot rule |
| D6 | Prior art (`difftree`, `audible-rs`): ignored — fresh ecosystem survey per item |
| D7 | Target shape: CLI + library + web service |
| D8 | Ranking evidence: crates.io downloads (90-day + all-time); GitHub stars, last release date, open-issue health; adoption by well-known Rust projects; blogs and published patterns with dates; recency weighted. **Dormancy is named explicitly:** a crate with high downloads but no stable release in 6+ months, or an unanswered maintainer-timeline issue, is marked *dormant* regardless of counts (the TS port's most consequential rejection, VitePress, turned on this and not on downloads). Every quantitative figure carries its source URL and retrieval date |
| D9 | Method: subagents survey areas in parallel; the main loop classifies and writes verdicts |

## 5. Repository layout

```text
rs-launch-blueprint/
├── README.md
├── LICENSE                          # MIT
├── PROJECTS.md                      # P01 = this program
├── AGENTS.md, CLAUDE.md             # thin charters
├── docs/port/
│   ├── README.md                    # method + verdict vocabulary
│   ├── ts-research-method-review.md # how the TS port researched; what to copy / avoid
│   ├── areas/<area>.md              # 12 raw side-by-side tables (evidence layer)
│   ├── COMMONALITY.md               # authoritative ledger, one row per feature
│   ├── PY_INVENTORY.md              # per-repo view derived from the area tables
│   └── TS_INVENTORY.md
├── docs/superpowers/specs/          # this document
├── research/
│   ├── CLAUDE.md                    # index: R## · slug · origin · verdict · owns · prompt · status
│   └── topics/<nn>-<slug>/
│       ├── prompts/<slug>.prompt.md # written in this program (Phase 3)
│       ├── DECISION.md              # written at execution time
│       ├── audit-codex.md           # empirical / adversarial lens (different model family)
│       └── audit-fable.md           # judgment lens
└── scripts/check-research-tree.sh   # structural checks (§8)
```

## 6. Pipeline

| Phase | Actor | Output |
|---|---|---|
| 0 Shell | main loop | repo created and pushed; worktree for everything after |
| 1 Area survey | 12 read-only agents (sonnet), **dispatched in batches of 3–4** (the TS port's 14-agent burst failed 13/14) | `docs/port/areas/<area>.md` |
| 2 Classify | main loop | `COMMONALITY.md`, `PY_INVENTORY.md`, `TS_INVENTORY.md`; a **shared-parameter registry** (§6.3) |
| 3 Derive items | main loop | `research/CLAUDE.md` + one prompt per SUBSTITUTE / OVERRIDE / DIVERGENT / RUST-ONLY row |
| 3.5 **Owner technology-selection review** — *not waivable* | owner | one line per item: `accept question` / `narrow to …` / `force <tool>` / `drop`; each answer recorded in the index. The TS port waived this gate and paid with four post-port reversals (pnpm, picocolors ×2, Bun lane, TS 7) |
| 4 Validate | `scripts/check-research-tree.sh` + one independent reviewer agent (opus) that produced none of the tables | findings fixed before PR |
| 5 Ship | main loop → owner | PR with diff for approval; merge; `pull --ff-only`; worktree removed |

### 6.1 Areas (12)

`ci-workflows`, `release-versioning`, `lint-format`, `static-analysis`,
`testing-coverage`, `cli-framework-ux`, `config-env-logging`, `docs-system`,
`git-hooks-commit-hygiene`, `packaging-distribution`, `web-service`,
`dev-experience-repo-hygiene`.

### 6.2 Area-agent contract

Input: both repo paths (read-only), the area name, the area's relevant files,
and `TS_PORT_DECISIONS.md`. Output: one markdown file with a table

`feature · py (files, how) · ts (files, how) · same / different / py-only / ts-only · TS decision refs · notes`

plus a list of language-bound tools in the area with the role each plays, and
a list of **cross-area parameters** the area depends on (e.g. "CI OS matrix",
"terminal color surface", "MSRV"). Agents report; they never assign verdicts.
Every file reference is `path:line`; the Phase 4 reviewer samples them, because
fan-out agents drift ±1 line systematically.

### 6.3 Shared-parameter registry (couplings)

The TS port's dominant research failure was cross-topic contradiction: color
was decided by two topics, the CI Node matrix by two topics, and one
recommendation silently depended on a compiler flag only another topic
mentioned (TS decisions D-025–D-027). To prevent it, every repo-wide parameter
has **exactly one owning item**. Phase 2 produces the registry (parameter →
owner `R##`); Phase 3 writes it into each prompt's `## Couplings` section; the
check script fails on any parameter owned by zero or two items, and on any
consumed parameter whose owner does not declare it.

## 7. Prompt template

Every `<slug>.prompt.md` has exactly these H2 sections, in order. The shape
follows the owner's strongest existing exemplar
(`py-launch-blueprint/research/topics/01-python-typing-best-practices/prompts/`)
plus the TS port's answer fields.

1. `## Objective` — who consumes the answer (the port's implementation plan),
   at what specificity (a named crate or a named pattern, with version), and the
   value test: what changes in the template if this answer is wrong.
2. `## Context` — target shape (CLI + lib + web); the inherited pattern quoted
   with `path:line` references from both repos; the verdict class; any existing
   decision from the area tables the researcher must not re-decide. Written to
   pre-empt clarifying questions so the run never stalls. OVERRIDE candidates
   add: *"The default is to keep pattern X. Argue whether Rust specifically
   justifies deviating; if not, say so."*
3. `## Out of scope` — what the search must not spend budget on.
4. `## Couplings` — `- owns: <param>, …` and `- consumes: R##: <param>` lines
   per §6.3; a recommendation that needs a consumed parameter changed records
   `CONFLICT: R## <param>` instead of changing it.
5. `## Questions` — the decision in one sentence, then sub-questions labeled
   `HIGH` / `MEDIUM` / `LOW` priority so a budget-limited run spends effort where
   answers are scarce.
6. `## Required evidence` — the D8 list including dormancy; every claim
   sourced and dated.
7. `## Answer template` — `Dominant choice` · `Top 5` table (name, role,
   90-day downloads, all-time downloads, stars, last release, notable adopters,
   one-line trade-off) · `Up-and-comers` · `Fit for this template` (CLI, lib,
   web) · `Recommendation` · `Ranked runner-up` (and the condition under which
   it wins) · `Tradeoffs` (what the pick gives up versus each runner-up, and why
   that cost is accepted) · `Migration implications` (file-level changes in the
   template) · `Validation strategy` (commands that prove the choice landed) ·
   `Confidence & re-verify trigger` · `Sources`.
8. `## Constraints` — fresh survey (no prior-art baseline); stable Rust; MSRV
   stated; cross-platform CI (macOS, Linux, Windows) as py and ts have.

## 8. Verification

`scripts/check-research-tree.sh` exits non-zero when:

- `research/CLAUDE.md` links a prompt path that does not exist, or a
  `*.prompt.md` exists that the index does not link;
- a prompt lacks any of the eight H2 sections of §7;
- a parameter is owned by zero or by two or more prompts, or a `consumes:`
  line names an `R##`/parameter pair that no prompt owns;
- a `COMMONALITY.md` table row has a verdict outside §3;
- an `OVERRIDE (OV-nn)` row has no `### OV-nn` section with both
  `**Argument:**` and `**Options:**`;
- an index row with status `resolved` lacks `DECISION.md`, `audit-codex.md`,
  or `audit-fable.md` in its topic directory.

The script is written in Phase 0 and is red until Phase 3 completes. The
reviewer agent in Phase 4 covers what the script cannot: spot-checking at least
15 `COMMON → REUSE` rows and a sample of `path:line` citations against both
repos, and reading every OVERRIDE argument adversarially.

## 9. Out of scope

Running the research; `cargo init`; the port contract (a future
`rust_port_process_prompt.md` / `goal.md` pair modeled on the TS port);
installing `difftree-pr-comment.yml` (nothing to diff yet); `.claude/settings.json`
welcome announcement (text to be confirmed by the owner first).

## 10. Conventions carried into the execution phase

These bind the later session that runs the prompts; they are recorded here so
the prompts and index are shaped for them.

- **Pilot first.** Run one item end-to-end (prompt → DECISION.md → both audits)
  before batch execution, because `/deep-research`'s output shape against this
  template is untested (D5 note).
- **Empirical gate.** A recommendation whose output is a configuration, a
  command, or a version pin is not accepted until it has been executed against
  the pinned toolchain and the observed result recorded in `DECISION.md`. (The
  py typing research's Codex audit found the recommended `ty` rule block named
  an unknown rule that made the proposed command exit 1 — undetectable by
  document review.)
- **Dual-lens audit.** `audit-codex.md` (different model family; runs the
  config) and `audit-fable.md` (judgment) both exist before an item is marked
  `resolved`.
- **Append-only decisions.** Reversing a decision adds a new entry that cites
  the old one; nothing is edited in place (TS `goal.md` §5 rule; it is what made
  the D-026 → D-038 double flip legible).
- **Producer never validates its own output.**
