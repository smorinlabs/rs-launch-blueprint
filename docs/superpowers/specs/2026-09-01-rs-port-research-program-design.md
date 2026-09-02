# rs-launch-blueprint — port research program (design)

**Status:** approved design, 2026-09-01. Governs Phase 0–5 of preparing a Rust
sibling of `py-launch-blueprint` and `ts-launch-blueprint`. The port itself is
out of scope; this program ends with a research tree whose prompts a later
session executes.

## 1. Purpose

Decide, with evidence, which parts of the two existing launch blueprints carry
over to a Rust template unchanged, which need a Rust tool substituted under the
same pattern, and which — rarely — justify changing the pattern. Every open
choice becomes one deep-research prompt with a fixed answer template so results
are comparable.

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
| D5 | Engine: `guided-research` tree layout; prompts shaped for `/deep-research`, runnable by Doxa |
| D6 | Prior art (`difftree`, `audible-rs`): ignored — fresh ecosystem survey per item |
| D7 | Target shape: CLI + library + web service |
| D8 | Ranking evidence: crates.io downloads (90-day + all-time); GitHub stars, last release, open-issue health; adoption by well-known Rust projects; blogs and published patterns with dates; recency weighted |
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
│   ├── areas/<area>.md              # 12 raw side-by-side tables (evidence layer)
│   ├── COMMONALITY.md               # authoritative ledger, one row per feature
│   ├── PY_INVENTORY.md              # per-repo view derived from the area tables
│   └── TS_INVENTORY.md
├── docs/superpowers/specs/          # this document
├── research/
│   ├── CLAUDE.md                    # index: R## · item · origin · verdict · prompt · status
│   └── topics/<nn>-<slug>/prompts/<slug>.prompt.md
└── scripts/check-research-tree.sh   # structural checks (§8)
```

## 6. Pipeline

| Phase | Actor | Output |
|---|---|---|
| 0 Shell | main loop | repo created and pushed; worktree `feat/port-research` for everything after |
| 1 Area survey | 12 parallel read-only agents (sonnet), one per area | `docs/port/areas/<area>.md` |
| 2 Classify | main loop | `COMMONALITY.md`, `PY_INVENTORY.md`, `TS_INVENTORY.md` |
| 3 Derive items | main loop | `research/CLAUDE.md` + one prompt per SUBSTITUTE / OVERRIDE / DIVERGENT / RUST-ONLY row |
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

plus a list of language-bound tools in the area with the role each plays.
Agents report; they never assign verdicts.

## 7. Prompt template

Every `<slug>.prompt.md` has exactly these H2 sections, in order:

1. `## Context` — target shape (CLI + lib + web), the inherited pattern quoted
   with file references, the verdict class. OVERRIDE candidates add: *"The
   default is to keep pattern X. Argue whether Rust specifically justifies
   deviating; if not, say so."*
2. `## Question` — one decision in one sentence.
3. `## Required evidence` — D8 list; every claim sourced and dated.
4. `## Answer template` — `Dominant choice` · `Top 5` table (name, role,
   90-day downloads, all-time downloads, stars, last release, notable adopters,
   one-line trade-off) · `Up-and-comers` · `Fit for this template` (CLI, lib,
   web) · `Recommendation` · `Sources`.
5. `## Constraints` — fresh survey (no prior-art baseline); stable Rust; MSRV
   stated; cross-platform CI (macOS, Linux, Windows) as py and ts have.

## 8. Verification

`scripts/check-research-tree.sh` exits non-zero when:

- `research/CLAUDE.md` links a prompt path that does not exist, or a
  `*.prompt.md` exists that the index does not link;
- a prompt lacks any of the five H2 sections of §7;
- a `COMMONALITY.md` table row has a verdict outside §3;
- an `OVERRIDE (OV-nn)` row has no `### OV-nn` section with both
  `**Argument:**` and `**Options:**`.

The script is written in Phase 0 and is red until Phase 3 completes. The
reviewer agent in Phase 4 covers what the script cannot: spot-checking at least
15 `COMMON → REUSE` rows against both repos and reading every OVERRIDE argument
adversarially.

## 9. Out of scope

Running the research; `cargo init`; the port contract (a future
`rust_port_process_prompt.md` / `goal.md` pair modeled on the TS port);
installing `difftree-pr-comment.yml` (nothing to diff yet); `.claude/settings.json`
welcome announcement (text to be confirmed by the owner first).
