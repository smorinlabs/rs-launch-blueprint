# rs-launch-blueprint — port research program (design)

**Status:** approved design, 2026-09-01; revised the same day twice: first after
a review of how the TypeScript port's research was actually executed
(`docs/port/ts-research-method-review.md`), then after an adversarial review by
Codex (different model family; disposition of its 25 findings in §12). Governs
Phase 0–5 of preparing a Rust sibling of `py-launch-blueprint` and
`ts-launch-blueprint`. The port itself is out of scope; this program ends with
a research tree whose prompts a later session executes under the contract in
§11.

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

The ledger makes this boundary structural rather than a matter of wording
(Codex finding 8): a pattern and the tool that implements it are **separate
rows**. A `SUBSTITUTE` row names its pattern row with `parent: F###` in Notes,
so a tool swap cannot be described as a free-standing feature, and an
`OVERRIDE` can only sit on a pattern row, where the displaced pattern is the
row itself. Composite features are split into atomic rows before classification.

Agreement between the two repos is **correlated, not independent** — the TS
template was ported from the Python one (Codex finding 9). A `REUSE` row is
therefore still gated: its Notes carry `rust-ok: yes` (the classifier confirmed
the convention applies unchanged in a Cargo workspace) and `live: YYYY-MM` (the
most recent release or commit of any language-neutral tool involved, or
`live: n/a` for tool-free conventions). A tool that is archived, deprecated, or
under an unpatched advisory cannot be `REUSE`; it becomes `SUBSTITUTE` under
the same pattern row.

## 3. Verdict vocabulary (closed set)

Origin comes from the area tables: `same` (both repos, same way), `different`
(both repos, different ways), `py-only`, `ts-only`, `none` (no precedent).
The verdict must be legal for the origin; the check script enforces the table.

| Verdict | Legal origin | Meaning | Research item |
|---|---|---|---|
| `COMMON → REUSE` | `same` | Language-neutral; inherited unchanged. Notes carry `rust-ok: yes` and `live:` | none |
| `COMMON → SUBSTITUTE` | `same` | Same pattern; tool is language-bound. Notes carry `parent: F###` (the pattern row) | yes |
| `COMMON → OVERRIDE (OV-nn)` | `same` | A strong Rust-specific reason to change the pattern | yes — burden of proof on deviating |
| `ADOPT` | `py-only`, `ts-only` | One-sided precedent, language-neutral; taken as-is | none |
| `DIVERGENT` | `different`, `py-only`, `ts-only` | Precedents disagree or only one exists and Rust needs a decision | yes |
| `RUST-ONLY` | `none` | No precedent in either repo | yes |
| `OMIT` | any except `none` | No Rust analogue | none |

Precedence when a row seems to fit two verdicts: `none` → `RUST-ONLY`; one
repo only → `ADOPT` if nothing needs choosing, else `DIVERGENT`; both differ →
`DIVERGENT`; both same and the tool is language-bound → `SUBSTITUTE` under a
`REUSE` pattern row; both same and language-neutral → `REUSE`; both same but
the pattern must change → `OVERRIDE`. If a row fits two of these at once it is
composite — split it.

`OV-nn` is a sequential id used by exactly one row. Each one has a section
`### OV-nn` under `## Override arguments` in `COMMONALITY.md` containing
non-empty `**Argument:**` and `**Options:**` lines.

Rows whose verdict needs research (`SUBSTITUTE`, `OVERRIDE`, `DIVERGENT`,
`RUST-ONLY`) name their item in the `Item` column (`R##`); all other rows carry
`—`. Every open item in the index maps to at least one ledger row; a jointly
chosen stack may map several rows to one **bundle** item (§4 D4).

## 4. Decisions fixed in the interview (2026-09-01)

| # | Decision |
|---|---|
| D1 | Source of truth: both repos analyzed, then merged (Option C: area-first agents reading both repos plus `ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md` for their area) |
| D2 | Finish line: inventories + shell repo + research index + prompts + the execution contract (§11). No research execution beyond the one non-binding conformance pilot in Phase 3, no port code |
| D3 | Repo: `~/c/rs-launch-blueprint` → `smorinlabs/rs-launch-blueprint`, public, docs-only (no `cargo init`) |
| D4 | Granularity: one research item per **decision**. A tool or pattern chosen on its own is one `crate` or `pattern` item; a stack that is only ever chosen jointly (e.g. web framework + middleware + server) is one `bundle` item covering several ledger rows, so cross-item contradiction — the TS port's dominant failure — cannot arise inside the bundle |
| D5 | Engine: `guided-research` tree layout; prompts shaped for `/deep-research`, runnable by Doxa. **Note:** the TS port never invoked `/deep-research` (it used fan-out agents with WebSearch), so the engine's output shape is untested for this template — hence the Phase 3 conformance pilot |
| D6 | Prior art (`difftree`, `audible-rs`): ignored — fresh ecosystem survey per item. Re-confirmed by the owner on 2026-09-01 after Codex finding 24 proposed a post-survey comparison; the owner chose to keep the survey anchor-free |
| D7 | Target shape: CLI + library + web service |
| D8 | Ranking evidence: crates.io downloads (90-day + all-time); GitHub stars, last release date, open-issue health; adoption by well-known Rust projects; blogs and published patterns with dates; recency weighted — collected under the protocol in §7.6 so two researchers produce the same numbers. **Maintenance state is a rubric, not a counter** (§7.6): no release in 6 months is the trigger to investigate, never the verdict. Every quantitative figure carries its source URL and retrieval date |
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
│   ├── areas/<area>.md              # 13 raw side-by-side tables (evidence layer)
│   ├── COVERAGE.md                  # every source file of both repos → feature ids or an exclusion (§6.4)
│   ├── COMMONALITY.md               # authoritative ledger: ID · Feature · Area · Origin · Verdict · Item · Notes
│   ├── PARAMETERS.md                # shared-parameter registry: param · kind · owner · value · description (§6.3)
│   ├── OWNER-REVIEW.md              # Phase 3.5 dispositions: item · disposition · rationale · date
│   ├── PY_INVENTORY.md              # per-repo view derived from the ledger
│   └── TS_INVENTORY.md
├── docs/superpowers/specs/          # this document
├── research/
│   ├── CLAUDE.md                    # index: id · slug · kind · origin · verdict · owns · prompt · status
│   ├── RUNBOOK.md                   # execution contract for the later session (§11)
│   └── topics/<nn>-<slug>/
│       ├── prompts/<slug>.prompt.md # written in this program (Phase 3)
│       ├── DECISION.md              # written at execution time (§11 shape)
│       ├── audit-codex.md           # empirical / adversarial lens (different model family)
│       └── audit-fable.md           # judgment lens
└── scripts/
    ├── check-research-tree.sh       # structural checks (§8)
    └── test-check-research-tree.sh  # regression suite: valid fixture + one mutation per rule
```

All pipe tables above follow one dialect: one table per file, leading and
trailing pipes on every row, no `|` inside a cell, columns found by header
name. The check script rejects anything else rather than guessing.

## 6. Pipeline

| Phase | Actor | Output |
|---|---|---|
| 0 Shell | main loop | repo created and pushed; worktree for everything after |
| 1 Area survey | 13 read-only agents (sonnet), **dispatched in batches of 3–4** (the TS port's 14-agent burst failed 13/14) | `docs/port/areas/<area>.md`; the file manifest each agent covered |
| 2 Classify | main loop, **one area at a time**, then one reconciliation pass over disputed rows | `COMMONALITY.md`, `PARAMETERS.md`, `COVERAGE.md`, `PY_INVENTORY.md`, `TS_INVENTORY.md` |
| 3 Derive items | main loop | `research/CLAUDE.md`, `research/RUNBOOK.md`, one prompt per item. **Conformance pilot** after the first two prompts: run one through `/deep-research` (or Doxa) and check only that the answer fills the §7.7 template; the technology content is discarded, not committed, and binds nothing. A template that the engine cannot fill is fixed before the remaining prompts are written |
| 3.5 **Owner technology-selection review** — *not waivable* | owner | `OWNER-REVIEW.md`, one row per item: `accept` / `narrow` / `force` / `drop` with rationale and date; state transitions in §6.5. The TS port waived this gate and paid with four post-port reversals (pnpm, picocolors ×2, Bun lane, TS 7) |
| 4 Validate | `scripts/check-research-tree.sh --require-owner-review` + one independent reviewer agent (opus) that produced none of the tables | findings fixed before PR |
| 5 Ship | main loop → owner | PR with diff for approval; merge; `pull --ff-only`; worktree removed |

### 6.1 Areas (13)

`ci-workflows`, `release-versioning`, `lint-format`, `static-analysis`,
`testing-coverage`, `cli-framework-ux`, `config-env-logging`, `docs-system`,
`git-hooks-commit-hygiene`, `packaging-distribution`, `web-service`,
`dev-experience-repo-hygiene`, `workspace-architecture`.

`workspace-architecture` (added on Codex finding 14) owns crate boundaries and
the ports-and-adapters rule the Python template enforces
(`py-launch-blueprint/docs/adr/0017-hexagonal-core-and-boundary-enforcement.md`),
dependency direction, Cargo feature topology (the web service must stay an
optional feature of the workspace as `pyproject.toml` keeps web dependencies
optional), the sync/async boundary, and public-API stability. Platform facts
that are not researched — MSRV policy, edition, target OS matrix, license —
are **fixed parameters** in the registry (§6.3), not an area.

**Primary assignment.** Every ledger row has exactly one `Area`. Where areas
overlap (CI runs the linter; hooks run the tests), the row lives in the area
that *decides* the thing, and the other areas reference it by `F###`. The
main loop resolves duplicates in the Phase 2 reconciliation pass; two rows for
one feature is a defect.

### 6.2 Area-agent contract

Input: both repo paths (read-only), the area name, the area's relevant files,
and `TS_PORT_DECISIONS.md`. Output: one markdown file with a table

`feature · py (files, how) · ts (files, how) · same / different / py-only / ts-only · TS decision refs · notes`

plus a list of language-bound tools in the area with the role each plays, a
list of **cross-area parameters** the area depends on as lowercase-kebab slugs
(`ci-os-matrix`, `terminal-color-surface`, `msrv-policy`), and the list of
source files the agent read (for `COVERAGE.md`). Agents report; they never
assign verdicts. Every file reference is `path:line`; the Phase 4 reviewer
samples them, because fan-out agents drift ±1 line systematically.

### 6.3 Shared-parameter registry (couplings)

The TS port's dominant research failure was cross-topic contradiction: color
was decided by two topics, the CI Node matrix by two topics, and one
recommendation silently depended on a compiler flag only another topic
mentioned (TS decisions D-025–D-027). To prevent it, every repo-wide parameter
is registered once in `docs/port/PARAMETERS.md` with columns
`param · kind · owner · value · description`:

- `param` is a lowercase-kebab slug (`^[a-z0-9]+(-[a-z0-9]+)*$`), so prompts
  can name it without whitespace or shell-metacharacter ambiguity;
- `kind: fixed` — decided by the owner before research starts, `owner` is the
  literal `owner`, `value` is filled in. Required fixed parameters:
  `msrv-policy`, `rust-edition`, `target-os-matrix`, `license`;
- `kind: researched` — `owner` is the one `R##` whose answer sets it; `value`
  is `—` until that item resolves, then copied from its `DECISION.md`.

Each prompt's `## Couplings` section declares `- id: R##`, `- owns: a, b`
(researched parameters this item alone decides — must match the registry) and
`- consumes: R##: param; owner: param` (what it depends on). The check script
fails on any owned parameter that is unregistered, fixed, or registered to a
different owner; on any researched parameter its owner's prompt does not
declare; on any consumed pair the named owner does not hold; and on an item
consuming its own parameter. Because the registry is the universe, a
parameter that nobody owns is visible (Codex finding 3).

A single owner is a **decision authority, not the only source of
constraints** (Codex finding 5): consumers may discover that the owner's value
is infeasible for them. That is handled at execution time by the conflict rule
in §11, never by a consumer silently choosing a different value.

### 6.4 Coverage manifest

The Phase 4 reviewer can only sample rows that exist; a file no survey agent
read disappears from every derived document (Codex finding 16; the TS method
prompt warned that security, dependency management, error handling, fixtures
and embedded behaviors need feature-level discovery, not filename mapping).
Phase 2 therefore builds `docs/port/COVERAGE.md` from `git ls-files` of both
repos: one row per file, `repo · path · feature ids | EXCLUDED: reason`. A
file with neither is a Phase 2 defect. Generated assets and lockfiles are
excluded by a stated rule, not one by one.

### 6.5 Owner review dispositions (Phase 3.5)

| Disposition | Effect on the tree |
|---|---|
| `accept` | none |
| `narrow` | the prompt's `## Out of scope` and `## Questions` are edited to the owner's rationale; the ledger row is unchanged |
| `force <tool>` | the prompt is rewritten as a fitness check of the named tool (still executed; the empirical gate and both audits still apply); `## Objective` states that the choice is forced |
| `drop` | index status becomes `dropped`; every ledger row that pointed at the item is re-verdicted to a non-research verdict with Item `—`; the prompt stays as history |

The check script, run with `--require-owner-review`, fails until every index
item has exactly one review row with a valid disposition, a non-empty
rationale and a date, and until `drop` rows and `dropped` statuses agree.

## 7. Prompt template

Every `<slug>.prompt.md` has exactly these eight H2 sections, in this order,
and no other H2 outside fenced code. The shape follows the owner's strongest
existing exemplar
(`py-launch-blueprint/research/topics/01-python-typing-best-practices/prompts/`)
plus the TS port's answer fields.

1. `## Objective` — who consumes the answer (the port's implementation plan),
   at what specificity (a named crate or a named pattern, with version), the
   item kind (`crate`, `pattern`, `bundle`) and the value test: what changes in
   the template if this answer is wrong.
2. `## Context` — target shape (CLI + lib + web); the inherited pattern quoted
   with `path:line` references from both repos; the verdict class; any existing
   decision from the area tables the researcher must not re-decide. Written to
   pre-empt clarifying questions so the run never stalls. OVERRIDE candidates
   add: *"The default is to keep pattern X. Argue whether Rust specifically
   justifies deviating; if not, say so."*
3. `## Out of scope` — what the search must not spend budget on.
4. `## Couplings` — `- id:`, `- owns:`, `- consumes:` lines per §6.3; a
   recommendation that needs a consumed parameter changed records
   `CONFLICT: R## <param> — <needed value> — <reason>` in the answer's
   `Parameters` field instead of changing it.
5. `## Questions` — the decision in one sentence, then sub-questions labeled
   `HIGH` / `MEDIUM` / `LOW` priority so a budget-limited run spends effort where
   answers are scarce.
6. `## Required evidence` — the protocol in §7.6 and the fitness gates; every
   claim sourced and dated.
7. `## Answer template` — the fields in §7.7 for the item's kind.
8. `## Constraints` — fresh survey (no prior-art baseline); stable Rust; the
   fixed parameters quoted by value; cross-platform CI (macOS, Linux, Windows)
   as py and ts have.

### 7.6 Evidence protocol and fitness gates

Numbers are collected the same way by every run, or they are not comparable
(Codex finding 20). Each figure carries its endpoint and retrieval date.

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` (crates.io's trailing-90-day figure) |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest version with `yanked: false`: `num`, `created_at` |
| Stars, archived flag | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues (issues only) | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` — never `open_issues_count`, which mixes in pull requests |
| Issue responsiveness | the 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open (unpatched) advisories; `cargo audit` output when a fixture exists |
| Adopters | the crate's reverse dependencies page and the named projects' `Cargo.toml` | project name + link; "well-known" means a project the reader can name without looking it up |

**Maintenance state** is one of `active`, `stable-quiet`, `at-risk`,
`dormant`, `archived`, assigned by rubric (Codex finding 23): a mature crate
with a stable API and no open bugs is `stable-quiet`, not `dormant`, however
long since its last release; `at-risk` needs a concrete signal (single
maintainer silent 6+ months, unanswered maintainer-timeline issue, failing
against current stable); `dormant` needs an unpatched advisory, a broken build
on current stable, or an explicit "looking for maintainer"; `archived` is the
GitHub flag or a deprecation notice. The VitePress rejection in the TS port
would be `at-risk` under this rubric — the label that mattered, reached by
evidence rather than by a date threshold.

**Fitness gates** (Codex finding 22) are answered per candidate *before*
popularity is weighed; a candidate that fails a gate is listed with the failing
gate and excluded from the shortlist:

- license compatible with the repo's `license` parameter (MIT, Apache-2.0, or
  dual);
- MSRV of the crate and of its dependency tree within `msrv-policy`
  (`cargo msrv` or the crate's `rust-version`);
- no open RustSec advisory; `unsafe` posture stated (`forbid(unsafe_code)`,
  audited unsafe, or unknown);
- builds and is tested on Windows (CI badge or a stated platform list);
- default features and any async-runtime coupling stated, so a CLI-only
  build does not pull the web stack (`workspace-architecture` owns the
  topology, but every crate item reports its own);
- binary-size and compile-time cost stated qualitatively; measured only for
  the recommended pick, at execution time, under the empirical gate (§10).

### 7.7 Answer template by item kind

**`crate` items:** `Dominant choice` · `Qualified shortlist` — up to five
entries that passed the gates (fewer is a finding, not a failure; Codex
finding 21) with name, role, 90-day downloads, all-time downloads, stars, last
release, maintenance state, notable adopters, one-line trade-off ·
`Excluded by gate` (name + failing gate) · `Up-and-comers` · `Fit for this
template` (CLI, lib, web) · `Recommendation` · `Ranked runner-up` (and the
condition under which it wins) · `Tradeoffs` (what the pick gives up versus
each runner-up, and why that cost is accepted) · `Parameters` (value for every
owned parameter; value assumed for every consumed one; any `CONFLICT:` lines)
· `Migration implications` (file-level changes in the template) · `Validation
strategy` (commands that prove the choice landed) · `Confidence & re-verify
trigger` · `Sources`.

**`pattern` items:** as above, but the shortlist is an `Options` table (name,
where documented, adopters that practice it, date of the most recent
authoritative write-up) with no download columns, and `Fit` is argued per
target shape.

**`bundle` items:** one `Recommendation` for the stack, then the `crate`
fields for each member, then a `Compatibility` field proving the members are
tested together (a shared adopter, a shared example repo, or a version matrix).

**OVERRIDE items** additionally end with (Codex finding 10): `Inherited
default` (the pattern as py and ts have it) · `Rust-specific argument` ·
`Options rejected` · `Override justified: yes | no` · `Resulting verdict` —
and a `no` sends the ledger row back to `REUSE` or `SUBSTITUTE` at execution
time under the append-only rule.

## 8. Verification

`scripts/check-research-tree.sh [--require-owner-review]` exits non-zero when:

- `research/CLAUDE.md`, `research/RUNBOOK.md`, `docs/port/COMMONALITY.md` or
  `docs/port/PARAMETERS.md` is missing, or the index has no `R##` rows;
- an index row has a malformed id, a duplicate id, a `kind` outside
  `crate|pattern|bundle`, a `status` outside `open|in-progress|resolved|dropped`,
  a prompt link that does not resolve, or a prompt whose `- id:` differs from
  the row; or a `*.prompt.md` exists that no row links;
- a prompt's H2 headings outside fenced code are not exactly the eight of §7
  in order;
- the registry has a non-slug or duplicate parameter, a `kind` outside
  `fixed|researched`, a fixed parameter without a value or not owned by
  `owner`, a researched parameter whose owner is not in the index, or lacks
  any of `msrv-policy`, `rust-edition`, `target-os-matrix`, `license`;
- a prompt owns an unregistered, fixed, or foreign parameter; a researched
  parameter is not declared by its owner; a `consumes:` pair is not held by
  the named owner; an item consumes its own parameter; two prompts own one
  parameter;
- a ledger row has a malformed or duplicate `ID`, an `Area` outside §6.1, an
  `Origin` outside §3, a verdict outside §3 or illegal for its origin, an
  `Item` missing where research is required or present where it is not, an
  item that is not in the index or is `dropped`; a `REUSE` row lacks
  `rust-ok: yes`; a `SUBSTITUTE` row lacks `parent: F###` or names a parent
  that does not exist; an `OV-nn` is used by two rows, has no `### OV-nn`
  section, has two, or has an empty `**Argument:**` / `**Options:**` line; an
  open index item has no ledger row;
- an index row with status `resolved` lacks a non-empty `DECISION.md`
  (with `## Decision`, `## Parameters`, `## Empirical check`),
  `audit-codex.md`, or `audit-fable.md` in its topic directory;
- with `--require-owner-review`: `docs/port/OWNER-REVIEW.md` is missing, an
  item has other than exactly one row, a row has an invalid disposition, empty
  rationale or malformed date, or `drop` / `dropped` disagree.

`scripts/test-check-research-tree.sh` builds a valid fixture, asserts it
passes, then applies one mutation per rule above and asserts **exit status 1**
plus the expected message. Every loop in the checker that can fail reads from
process substitution, never from a pipe, because the previous version reported
`FAIL` from a subshell and exited 0 (Codex finding 1).

The script is written in Phase 0 and is red until Phase 3 completes. The
reviewer agent in Phase 4 covers what the script cannot: spot-checking at least
15 `COMMON → REUSE` rows and a sample of `path:line` citations against both
repos, confirming `COVERAGE.md` has no uncovered file, and reading **every
non-`REUSE` row** — not only the OVERRIDEs — for a departure dressed as a
`DIVERGENT`, `RUST-ONLY` or `OMIT`.

## 9. Out of scope

Running the research beyond the Phase 3 conformance pilot; `cargo init`; the
port contract (a future `rust_port_process_prompt.md` / `goal.md` pair
modeled on the TS port); installing `difftree-pr-comment.yml` (nothing to diff
yet); `.claude/settings.json` welcome announcement (text to be confirmed by
the owner first).

## 10. Conventions carried into the execution phase

These bind the later session that runs the prompts; they are recorded here and
in `research/RUNBOOK.md` so the prompts and index are shaped for them.

- **Pilot first.** Run one item end-to-end (prompt → DECISION.md → both audits)
  before batch execution.
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

## 11. Execution contract (`research/RUNBOOK.md`)

The tree ships with the control flow a later session needs, so it does not
reconstruct it (Codex finding 25). `RUNBOOK.md` is written in Phase 3 and
contains:

1. **Run order.** Fixed parameters are already valued. Researched items run in
   topological order of `consumes`: an item runs only after every item it
   consumes is `resolved`; items with no dependencies run in batches of ≤4.
2. **Engine invocation.** The exact `/deep-research` (or Doxa) call per item,
   the output path, and the check that the answer fills the §7.7 template
   before anyone reads its content.
3. **Failure and retry.** One retry on an engine failure; a second failure
   narrows the prompt (`## Questions` HIGH only) and records that in the
   decision; a third is escalated to the owner.
4. **Conflict rule.** A `CONFLICT: R## <param>` line in an answer blocks the
   consuming item and re-opens the owner item with the conflict appended to
   its prompt context; the owner item re-runs and its new `DECISION.md` entry
   cites the old one (append-only). Consumers never adopt a value the registry
   does not hold.
5. **Answer → decision.** `DECISION.md` has H2 sections `## Decision` (the
   pick, version, and the ledger rows it settles), `## Parameters` (every owned
   parameter's value — copied into `PARAMETERS.md` — and every consumed value
   assumed), `## Empirical check` (toolchain, command, observed result), and
   `## Supersedes` when it reverses an earlier entry. An item is `resolved`
   only when both audits exist; the check script enforces the files and
   sections.
6. **Staleness.** Each decision's `re-verify trigger` (a date or an event such
   as a major release) is listed; the runbook says who re-runs what when a
   trigger fires.

## 12. Adversarial review disposition (Codex, 2026-09-01)

Codex reviewed the revised spec and checker and returned 25 ranked findings.
Their disposition (24 folded, 1 rejected by the owner):

| # | Finding (short) | Disposition | Where |
|---|---|---|---|
| 1 | coupling `FAIL` did not change exit status | fixed; regression asserts exit code | script, test suite, §8 |
| 2 | no ledger↔index bijection; header-only tree passed | fixed | §3 `Item` column, §8 |
| 3 | no parameter universe | fixed | `PARAMETERS.md`, §6.3 |
| 4 | parameter parser split on whitespace | fixed | slug rule §6.3 |
| 5 | single owner vs negotiated constraints | folded | §6.3 last paragraph, §11.4 |
| 6 | couplings constrain metadata, not answers | folded | `Parameters` field §7.7, §11.4–5 |
| 7 | verdict set not exhaustive | fixed | origin legality + `ADOPT`, §3 |
| 8 | pattern/tool boundary gameable | fixed | `parent:` rows §2, review of all non-REUSE rows §8 |
| 9 | correlated agreement preserves defects | folded | `rust-ok` / `live` gate §2 |
| 10 | OVERRIDE lacks burden-of-proof result | fixed | §7.7 OVERRIDE fields |
| 11 | sections not checked for order/extras/fences | fixed | script, §8 |
| 12 | ledger dialect loose; empty OV bodies | fixed | dialect note §5, script |
| 13 | status by `$(NF-1)`; empty files pass | fixed | header-name lookup, `-s`, DECISION sections |
| 14 | no architecture / topology area | fixed | `workspace-architecture` §6.1; fixed platform params |
| 15 | area overlap without primary rule | fixed | primary assignment §6.1 |
| 16 | missing features invisible | fixed | `COVERAGE.md` §6.4 |
| 17 | granularity fragments joint stacks; unbatched Phase 2 | fixed | `bundle` D4; per-area Phase 2 |
| 18 | Phase 3.5 unenforceable | fixed | `OWNER-REVIEW.md` §6.5, `--require-owner-review` |
| 19 | engine pilot only after everything ships | fixed | Phase 3 conformance pilot |
| 20 | no reproducible evidence protocol | fixed | §7.6 table |
| 21 | fixed Top 5 favors popularity | fixed | qualified shortlist, gates first, per-kind templates §7.7 |
| 22 | no Rust fitness gates | fixed | §7.6 gates |
| 23 | dormancy rule false positives | fixed | maintenance rubric §7.6, D8 |
| 24 | D6 discards owner's own Rust evidence | rejected by owner (keep D6: anchor-free survey) | D6 |
| 25 | no executable handoff | fixed | §11, `RUNBOOK.md` |
