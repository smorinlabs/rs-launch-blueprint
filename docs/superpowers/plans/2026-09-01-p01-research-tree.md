# P01 Port Research Tree — Implementation Plan (Phases 1–5)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce the complete, checker-green research tree for `rs-launch-blueprint`: 13 area surveys, the commonality ledger with verdicts, the parameter registry, the coverage manifest, the research index, one deep-research prompt per open item, the execution runbook, and the owner's review — ending in a merged PR tagged `v0.1.0`.

**Architecture:** Docs-only program in one worktree. Read-only sonnet agents survey both source repos per area (Phase 1); the main loop classifies one area at a time into `docs/port/COMMONALITY.md` and derives the registry, coverage, inventories and the index (Phase 2); the main loop writes `research/RUNBOOK.md` and one prompt per item, piloting the engine after the first two (Phase 3); the owner disposes every item (Phase 3.5); `scripts/check-research-tree.sh --require-owner-review` plus an independent opus reviewer gate the PR (Phase 4); merge and tag (Phase 5). Research execution is **P02**, not this plan.

**Tech Stack:** bash 3.2 (`/bin/bash`), python3 (stdlib only), `gh` REST API, Claude Code `Agent` tool (sonnet surveyors, opus reviewer), `/deep-research` or `uvx doxa-research` for the single pilot run.

**Spec:** `docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md` (sections cited as §n below).

**Authority during execution:** This plan records P01 preparation. Later approved spec amendments and owner dispositions take precedence over its original examples. P02 uses the current `PROJECTS.md`, `research/RUNBOOK.md`, and prompts; the P02 block below records the initial scope, not a replacement for those maintained files.

## Global Constraints

- Worktree: `~/c/rs-launch-blueprint-research`, branch `docs/p01-research-tree`, based on `origin/main`. Never edit `~/c/rs-launch-blueprint` (the live checkout). Push and fetch by explicit HTTPS URL `https://github.com/smorinlabs/rs-launch-blueprint.git` (ssh-agent is flaky on this machine).
- Source repos are read-only and pinned: `~/c/py-launch-blueprint @ b08bccf` (297 tracked files), `~/c/ts-launch-blueprint @ cb1cbcb` (122 tracked files). Every citation is `path:line` against these SHAs. If either repo has moved, `git -C <repo> checkout <sha>` is **not** allowed (live checkout); use `git -C <repo> worktree add ../<repo>-pin <sha>` and cite from the pin.
- Areas (13, §6.1): `ci-workflows`, `release-versioning`, `lint-format`, `static-analysis`, `testing-coverage`, `cli-framework-ux`, `config-env-logging`, `docs-system`, `git-hooks-commit-hygiene`, `packaging-distribution`, `web-service`, `dev-experience-repo-hygiene`, `workspace-architecture`. One `Area` per ledger row (primary assignment §6.1).
- Origins (§3): `same | different | py-only | ts-only | none`. Verdicts (§3): `COMMON → REUSE`, `COMMON → SUBSTITUTE`, `COMMON → OVERRIDE (OV-nn)`, `ADOPT`, `DIVERGENT`, `RUST-ONLY`, `OMIT`, legal per the §3 table. `Item` = `R##` for SUBSTITUTE/OVERRIDE/DIVERGENT/RUST-ONLY, `—` otherwise.
- Parameter slugs match `^[a-z0-9]+(-[a-z0-9]+)*$`. Required fixed parameters: `msrv-policy`, `rust-edition`, `target-os-matrix`, `license` (§6.3).
- Prompt files have exactly these H2s in order outside fences (§7): `## Objective`, `## Context`, `## Out of scope`, `## Couplings`, `## Questions`, `## Required evidence`, `## Answer template`, `## Constraints`.
- Verification: filtered checker output is diagnostic while the tree is incomplete; it never proves the whole-tree gate passed. Preserve the checker exit status when displaying filtered output. Run every final gate unfiltered, and stop on failure before closing tasks or committing.
- Table dialect (§5): one pipe table per file, leading and trailing pipes, no `|` in cells, columns by header name.
- Agent fan-out: batches of **≤4** parallel agents (§6). Surveyors are `sonnet`, the Phase 4 reviewer is `opus`, classification stays in the main loop (§4 D9, CLAUDE.md model matrix).
- Commits: Conventional Commits, one commit per area/batch, trailer `Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV`.
- Prior art (`difftree`, `audible-rs`) is never consulted or cited (§4 D6).
- Decisions reserved for the owner: the four fixed parameter values (Task 7) and every Phase 3.5 disposition (Task 16). Nothing in this plan pre-empts them.

## Additions to the spec §5 layout (tooling only, all committed)

| File | Why |
|---|---|
| `docs/port/areas/SURVEY-PROMPT.md` | the survey agents' prompt, committed so Phase 4 can audit what the agents were asked (§1: prompts are committed) |
| `scripts/check-area-file.sh` | structural check of each `areas/<area>.md` (header, origin enum, `path:line` cells, files-read list); Phase 1 gate |
| `scripts/derive-port-docs.py` | derives `COVERAGE.md` and `PY_INVENTORY.md` / `TS_INVENTORY.md` from the area files and the ledger, so they cannot drift from their sources |

## File map

```text
docs/port/areas/SURVEY-PROMPT.md          Task 2   (survey prompt, one placeholder set)
docs/port/areas/<area>.md ×13             Tasks 3–6 (evidence; Phase 2 adds an `id` column)
docs/port/PARAMETERS.md                   Task 7 (fixed rows) · Task 10 (researched rows)
docs/port/COMMONALITY.md                  Task 8 (skeleton + first area) · Task 9 · Task 10
research/CLAUDE.md                        Task 10 (draft index) · Task 15 (final)
docs/port/COVERAGE.md, PY_INVENTORY.md,
  TS_INVENTORY.md                         Task 11 (derived)
research/RUNBOOK.md                       Task 12
research/topics/<nn>-<slug>/prompts/
  <slug>.prompt.md                        Tasks 13, 15
docs/port/OWNER-REVIEW.md                 Task 16
PROJECTS.md                               Tasks 1, 14, 18
scripts/check-area-file.sh                Task 2
scripts/derive-port-docs.py               Task 11
```

---

### Task 1: Research worktree and draft PR

**Files:**
- Create: worktree `~/c/rs-launch-blueprint-research` on branch `docs/p01-research-tree`
- Modify: `PROJECTS.md` (P01-T02 flips to `[~]`)

**Interfaces:**
- Produces: the working directory every later task runs in; the draft PR number `<PR>` that later tasks push to.

- [ ] **Step 1: Confirm the live checkout is clean and current, then create the worktree**

```bash
git -C ~/c/rs-launch-blueprint status --porcelain          # expected: empty (report anything, never stage it)
git -C ~/c/rs-launch-blueprint fetch https://github.com/smorinlabs/rs-launch-blueprint.git main:refs/remotes/origin/main
git -C ~/c/rs-launch-blueprint worktree add ../rs-launch-blueprint-research -b docs/p01-research-tree origin/main
cd ~/c/rs-launch-blueprint-research && git log --oneline -1
```
Expected: HEAD is the merge commit of PR #2 or later (`git log -1` shows `.claude/settings.json` present: `test -f .claude/settings.json`).

- [ ] **Step 2: Verify the checker suite is green before touching anything**

Run: `bash scripts/test-check-research-tree.sh`
Expected: `53 passed, 0 failed`

- [ ] **Step 3: Verify the checker is red on the empty tree (this is the failing test for the whole program)**

Run: `bash scripts/check-research-tree.sh; echo "exit=$?"`
Expected: `FAIL: missing research/CLAUDE.md` … `exit=1`

- [ ] **Step 4: Flip P01-T02 to in progress and commit**

```bash
python3 - <<'PY'
p='PROJECTS.md'; s=open(p).read()
s=s.replace('- [ ] [P01-T02] Phase 1','- [~] [P01-T02] Phase 1',1); open(p,'w').write(s)
PY
git add PROJECTS.md
git commit -m "docs: start P01 Phase 1 (area survey)" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
git push https://github.com/smorinlabs/rs-launch-blueprint.git docs/p01-research-tree
```

- [ ] **Step 5: Open the draft PR that accumulates the whole program (marked ready in Task 18)**

```bash
gh api repos/smorinlabs/rs-launch-blueprint/pulls -f title="docs: P01 port research tree (phases 1-5)" -f head=docs/p01-research-tree -f base=main -F draft=true -f body="Accumulates the P01 research tree per docs/superpowers/plans/2026-09-01-p01-research-tree.md. Marked ready at Phase 5.

https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV" --jq '.number'
```
Expected: a PR number; record it as `<PR>`.

---

### Task 2: Survey prompt and area-file checker

**Files:**
- Create: `docs/port/areas/SURVEY-PROMPT.md`
- Create: `scripts/check-area-file.sh`

**Interfaces:**
- Produces: `check-area-file.sh <file>` → exit 0 and `OK: <file>` or exit 1 with `FAIL:` lines. Area file shape consumed by Tasks 3–6, 8–11 and by `derive-port-docs.py`:
  - one pipe table with header exactly `| feature | py | ts | origin | ts-decisions | notes |` (Phase 2 prepends an `id` column, see Task 8);
  - `py` / `ts` cells: `` `path:line` — how `` (one or more citations, each `path:line`), or `—` when the origin says that repo has no instance;
  - `origin` ∈ `same | different | py-only | ts-only` (surveyors never write `none`);
  - `## Language-bound tools` bullet list `- \`tool\` (py|ts) — role`;
  - `## Cross-area parameters` bullet list `- \`slug\` — why`;
  - `## Files read` with lines `- py: \`path\`` and `- ts: \`path\``, optionally suffixed ` — no feature: <reason>`.

- [ ] **Step 1: Write the failing check — a minimal bad area file must fail, a minimal good one must pass**

```bash
mkdir -p "$CLAUDE_JOB_DIR/tmp/af"
cat > "$CLAUDE_JOB_DIR/tmp/af/good.md" <<'MD'
# Area: lint-format

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|
| one formatter and one linter run in CI and in the pre-commit hook | `justfile:12` — `just lint` runs ruff | `package.json:31` — `oxlint` script | same | D-014 | pattern row |
| formatter tool | `pyproject.toml:40` — ruff format | `package.json:32` — oxfmt | same | D-014 | tool row |
| TOML formatter | `justfile:20` — taplo | — | py-only | — | |

## Language-bound tools
- `ruff` (py) — linter and formatter
- `oxlint` (ts) — linter

## Cross-area parameters
- `ci-os-matrix` — lint runs on every OS in the matrix

## Files read
- py: `justfile`
- py: `pyproject.toml`
- ts: `package.json`
- ts: `.editorconfig` — no feature: identical to py copy, covered by dev-experience-repo-hygiene
MD
sed 's/| same | D-014 | pattern row |/| both | D-014 | pattern row |/' "$CLAUDE_JOB_DIR/tmp/af/good.md" > "$CLAUDE_JOB_DIR/tmp/af/bad-origin.md"
sed 's/`justfile:12` — `just lint` runs ruff/justfile — just lint/' "$CLAUDE_JOB_DIR/tmp/af/good.md" > "$CLAUDE_JOB_DIR/tmp/af/bad-cite.md"
grep -v '^- ts:' "$CLAUDE_JOB_DIR/tmp/af/good.md" > "$CLAUDE_JOB_DIR/tmp/af/bad-files.md"
```

- [ ] **Step 2: Run the checker to confirm it does not exist yet**

Run: `bash scripts/check-area-file.sh "$CLAUDE_JOB_DIR/tmp/af/good.md"; echo "exit=$?"`
Expected: `No such file or directory` … `exit=127`

- [ ] **Step 3: Write `scripts/check-area-file.sh`**

```bash
cat > scripts/check-area-file.sh <<'SH'
#!/usr/bin/env bash
# Structural check for one docs/port/areas/<area>.md survey file (spec §6.2).
# Usage: scripts/check-area-file.sh <file>   → exit 0 "OK: <file>" or exit 1 with FAIL lines.
set -uf
f="${1:?usage: check-area-file.sh <file>}"; fail=0
err() { printf 'FAIL: %s: %s\n' "$f" "$*"; fail=1; }
[ -s "$f" ] || { err "missing or empty"; exit 1; }
hdr='| feature | py | ts | origin | ts-decisions | notes |'
hdr_id='| id | feature | py | ts | origin | ts-decisions | notes |'
grep -qxF -- "$hdr" "$f" || grep -qxF -- "$hdr_id" "$f" || err "table header must be exactly: $hdr (or with a leading id column after Phase 2)"
[ "$(grep -c '^|' "$f")" -gt 2 ] || err "table has no data rows"
# data rows: skip header and separator; awk -F'|' gives leading empty field
while IFS= read -r line; do
  case "$line" in '| feature |'*|'| id |'*|'|---'*) continue ;; esac
  n=$(printf '%s' "$line" | awk -F'|' '{print NF-2}')
  if [ "$n" -eq 7 ]; then off=1; elif [ "$n" -eq 6 ]; then off=0; else err "row has $n cells, want 6 (or 7 with id): $line"; continue; fi
  feat=$(printf '%s' "$line" | awk -F'|' -v o="$off" '{gsub(/^ +| +$/,"",$(2+o)); print $(2+o)}')
  py=$(printf '%s' "$line"   | awk -F'|' -v o="$off" '{gsub(/^ +| +$/,"",$(3+o)); print $(3+o)}')
  ts=$(printf '%s' "$line"   | awk -F'|' -v o="$off" '{gsub(/^ +| +$/,"",$(4+o)); print $(4+o)}')
  org=$(printf '%s' "$line"  | awk -F'|' -v o="$off" '{gsub(/^ +| +$/,"",$(5+o)); print $(5+o)}')
  [ -n "$feat" ] || err "empty feature cell: $line"
  case "$org" in same|different|py-only|ts-only) ;; *) err "origin '$org' not in same|different|py-only|ts-only: $feat" ;; esac
  cite='`[^`]*:[0-9][0-9]*`'
  case "$org" in
    same|different) printf '%s' "$py" | grep -Eq "$cite" || err "py cell needs \`path:line\`: $feat"
                    printf '%s' "$ts" | grep -Eq "$cite" || err "ts cell needs \`path:line\`: $feat" ;;
    py-only) printf '%s' "$py" | grep -Eq "$cite" || err "py cell needs \`path:line\`: $feat"; [ "$ts" = "—" ] || err "ts cell must be — for py-only: $feat" ;;
    ts-only) printf '%s' "$ts" | grep -Eq "$cite" || err "ts cell needs \`path:line\`: $feat"; [ "$py" = "—" ] || err "py cell must be — for ts-only: $feat" ;;
  esac
done < <(grep '^|' "$f")
for s in '## Language-bound tools' '## Cross-area parameters' '## Files read'; do grep -qxF -- "$s" "$f" || err "missing section '$s'"; done
grep -q '^- py: `' "$f" || err "Files read: no '- py:' line"
grep -q '^- ts: `' "$f" || err "Files read: no '- ts:' line"
while IFS= read -r p; do
  printf '%s' "$p" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' || err "cross-area parameter '$p' is not a lowercase-kebab slug"
done < <(awk '/^## Cross-area parameters/{on=1;next} /^## /{on=0} on && /^- `/{sub(/^- `/,""); sub(/`.*/,""); print}' "$f")
[ "$fail" -eq 0 ] && echo "OK: $f"; exit "$fail"
SH
chmod +x scripts/check-area-file.sh
```

- [ ] **Step 4: Run the checker on the four samples**

```bash
for x in good bad-origin bad-cite bad-files; do bash scripts/check-area-file.sh "$CLAUDE_JOB_DIR/tmp/af/$x.md" >/dev/null 2>&1; echo "$x exit=$?"; done
```
Expected: `good exit=0`, `bad-origin exit=1`, `bad-cite exit=1`, `bad-files exit=1`.

- [ ] **Step 5: Write `docs/port/areas/SURVEY-PROMPT.md`**

The placeholders `{{AREA}}`, `{{STARTER_FILES}}` and `{{SCOPE}}` are filled per area in Tasks 3–6; nothing else changes between agents.

````markdown
# Area survey prompt (Phase 1) — filled per area

You are a read-only surveyor. You report; you never assign verdicts.

## Inputs
- `~/c/py-launch-blueprint` at commit `b08bccf` and `~/c/ts-launch-blueprint` at commit `cb1cbcb`. Read only. Do not run their tooling.
- `~/c/ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md` — the log that explains why the TS repo differs from the Python one. Cite ids (`D-014`) in the `ts-decisions` column.
- Your area: **{{AREA}}** — {{SCOPE}}
- Starter files (expand from here; grep both repos for anything else your area decides): {{STARTER_FILES}}

## Output — write exactly one file: `docs/port/areas/{{AREA}}.md`

```
# Area: {{AREA}}

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|
```

Rules for the table:
1. One row per **atomic** feature. Split "pattern" from "tool": the row "one formatter and one linter, run in CI and in the pre-commit hook" is a pattern; the rows "formatter tool = ruff / oxfmt" and "linter tool = ruff / oxlint" are tools. If a row could be described two ways, split it.
2. `py` and `ts` cells: one or more citations `` `path:line` `` followed by ` — ` and how it is done, in ten words or fewer. Use `—` only when that repo has no instance of the feature.
3. `origin`: `same` (both repos, same way — the tool may differ, the pattern is the same), `different` (both repos, different ways), `py-only`, `ts-only`. Never `none`.
4. `ts-decisions`: the `D-###` ids that explain a difference, or `—`.
5. No `|` inside a cell. Leading and trailing pipes on every row. One table in the file.
6. Do not assign verdicts, recommend crates, or mention Rust tooling. Do not consult any other repository.

After the table, three sections with exactly these headings:

```
## Language-bound tools
- `<tool>` (py|ts) — <role it plays in this area>

## Cross-area parameters
- `<lowercase-kebab-slug>` — <why this area depends on a value decided elsewhere>

## Files read
- py: `<path>`
- ts: `<path>`
```

`Files read` lists **every** file you opened, one per line. A file you read that yielded no row gets ` — no feature: <reason>` appended. This list is the coverage manifest; an unlisted file is treated as unread.

Line numbers must be exact for the pinned commits — verify each with `sed -n '<line>p' <file>` before you write it. Do not estimate.

When done, run `bash scripts/check-area-file.sh docs/port/areas/{{AREA}}.md` and fix every FAIL before you finish. Reply with: the row count, the number of files read per repo, and any feature you were unsure how to split.
````

- [ ] **Step 6: Commit**

```bash
git add scripts/check-area-file.sh docs/port/areas/SURVEY-PROMPT.md
git commit -m "docs: add area survey prompt and area-file checker" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
```

---

### Task 3: Phase 1 survey — batch 1 (`workspace-architecture`, `ci-workflows`, `release-versioning`, `lint-format`)

**Files:**
- Create: `docs/port/areas/workspace-architecture.md`, `docs/port/areas/ci-workflows.md`, `docs/port/areas/release-versioning.md`, `docs/port/areas/lint-format.md` (written by the agents)

**Interfaces:**
- Consumes: `docs/port/areas/SURVEY-PROMPT.md` (Task 2) with the per-area values below.
- Produces: four area files passing `scripts/check-area-file.sh`.

**Per-area values for all 13 areas** (used here and in Tasks 4–6; `STARTER_FILES` are relative to each repo root and are starting points, not limits):

| AREA | SCOPE | STARTER_FILES |
|---|---|---|
| `workspace-architecture` | module/package boundaries, ports-and-adapters rule, dependency direction, optional web dependencies, sync/async boundary, public-API stability | py: `docs/adr/0017-*.md`, `docs/adr/0018-*.md`, `docs/adr/0013-*.md`, `pyproject.toml`, `src/**/__init__.py`; ts: `docs/port/TS_PORT_DECISIONS.md`, `package.json`, `src/**/index.ts`, `tsconfig*.json` |
| `ci-workflows` | every `.github/workflows/*.yml` job, triggers, OS/version matrix, caching, security scanning, permissions | py+ts: `.github/workflows/*.yml`, `.github/dependabot.yml`, `.github/*.md` |
| `release-versioning` | version source of truth, changelog, release tooling and its config, tags, publish trigger | py: `pyproject.toml`, `release-please-config.json`, `.release-please-manifest.json`, `CHANGELOG.md`; ts: same names plus `package.json` `version` |
| `lint-format` | formatter(s), linter(s), their config, which files each covers, how they run locally and in CI | py: `pyproject.toml` `[tool.ruff]`, `justfile`, `.pre-commit-config.yaml`, `taplo.toml`; ts: `package.json` scripts, `oxlint*.json`, `.oxfmtrc*`, `justfile` |
| `static-analysis` | type checking, dead-code/complexity/security scanners, boundary enforcement, how failures gate CI | py: `pyproject.toml` `[tool.ty]`/`[tool.mypy]`, `justfile`, `docs/adr/0018-*.md`; ts: `tsconfig*.json`, `package.json` `typecheck` script |
| `testing-coverage` | test runner, layout, fixtures, coverage tool and threshold, snapshot/property/e2e tests, CLI tests | py: `tests/**`, `pyproject.toml` `[tool.pytest*]`/`[tool.coverage*]`, `docs/adr/0019-*.md`; ts: `tests/**` or `src/**/*.test.ts`, `vitest.config.*`, `package.json` |
| `cli-framework-ux` | command parsing, help, colors/TTY detection, prompts, clipboard, pager, did-you-mean, error codes and hints, exit codes | py: `src/**/cli*.py`, `docs/adr/0006-*.md`, `docs/adr/0007-*.md`, `docs/adr/0008-*.md`; ts: `src/cli/**`, `src/**/commands/**` |
| `config-env-logging` | config file discovery and precedence, env vars, XDG/Windows paths, secrets rule, logging pipeline and profiles, crash log | py: `src/**/config*.py`, `src/**/logging*.py`, `docs/adr/0002-*.md`, `docs/adr/0004-*.md`, `docs/adr/0011-*.md`, `docs/adr/0015-*.md`; ts: `src/config/**`, `src/logging/**` |
| `docs-system` | docs generator, site config, ADR system and template, README structure, doc lint, publish workflow | py: `docs/**`, `mkdocs.yml` or equivalent, `docs/adr/template.md`; ts: `docs/**`, docs generator config |
| `git-hooks-commit-hygiene` | hook manager, hook list, commit message linting, branch rules, `.gitattributes`, `.gitignore` conventions | py: `.pre-commit-config.yaml`, `.gitignore`, `.gitattributes`, commitlint config; ts: `lefthook.yml` or `.husky/**`, `commitlint*`, `.gitignore` |
| `packaging-distribution` | build backend, artifact types, publish target and auth, install methods (pipx/npx/binary), entry points, version pin files | py: `pyproject.toml` `[build-system]`/`[project.scripts]`, publish workflow; ts: `package.json` `bin`/`files`/`exports`, `tsup*`/`tsdown*` config, publish workflow |
| `web-service` | web framework, server, routing layout, health endpoints, OpenAPI, middleware, how the web extra stays optional | py: `docs/adr/0013-*.md`, `src/**/web/**`, `pyproject.toml` optional deps; ts: `src/web/**`, `package.json` optional/peer deps |
| `dev-experience-repo-hygiene` | task runner and recipes, toolchain pinning (`mise`/`flox`), `make check`, editor config, devcontainer, templates for issues/PRs, doctor command | py: `justfile`, `Makefile`, `.mise.toml`, `.flox/**`, `.editorconfig`, `.github/ISSUE_TEMPLATE/**`, `docs/adr/0005-*.md`, `docs/adr/0012-*.md`; ts: `justfile`, `Makefile`, `.mise.toml`, `.editorconfig`, `.github/ISSUE_TEMPLATE/**` |

- [ ] **Step 1: Confirm the four target files do not exist and the checker fails on them**

Run: `for a in workspace-architecture ci-workflows release-versioning lint-format; do bash scripts/check-area-file.sh docs/port/areas/$a.md; done; echo "exit=$?"`
Expected: four `FAIL: … missing or empty` lines, `exit=1`.

- [ ] **Step 2: Dispatch four sonnet agents in one message**

For each of the four areas, build the prompt by substituting the row above into `docs/port/areas/SURVEY-PROMPT.md`, then call the `Agent` tool with `subagent_type: "general-purpose"`, `model: "sonnet"`, `description: "Survey area <AREA>"`, and the filled prompt as `prompt`. All four calls go in the same message so they run concurrently; do not start batch 2 until all four have returned.

- [ ] **Step 3: Gate each returned file**

```bash
for a in workspace-architecture ci-workflows release-versioning lint-format; do bash scripts/check-area-file.sh docs/port/areas/$a.md; done
```
Expected: four `OK:` lines. A `FAIL` goes back to the same agent by `SendMessage` with the FAIL text; do not fix survey files by hand (the surveyor owns the citations).

- [ ] **Step 4: Spot-check three citations per file against the pinned commits**

```bash
# pick three `path:line` cells at random from each file and print the cited line
for a in workspace-architecture ci-workflows release-versioning lint-format; do
  grep -o '`[^`]*:[0-9][0-9]*`' docs/port/areas/$a.md | tr -d '`' | sort -u | awk 'BEGIN{srand()} {print rand()"\t"$0}' | sort | head -3 | cut -f2 |
  while IFS=: read -r p l; do
    for repo in py-launch-blueprint ts-launch-blueprint; do [ -f ~/c/$repo/$p ] && printf '%s %s:%s → ' "$a" "$p" "$l" && sed -n "${l}p" ~/c/$repo/$p; done
  done
done
```
Expected: each printed line plausibly matches the row's "how" text. A miss by ±1 line means the agent estimated; send the file back with the mismatching citations.

- [ ] **Step 5: Commit the batch**

```bash
git add docs/port/areas/workspace-architecture.md docs/port/areas/ci-workflows.md docs/port/areas/release-versioning.md docs/port/areas/lint-format.md
git commit -m "docs: survey areas workspace-architecture, ci-workflows, release-versioning, lint-format" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
```

---

### Task 4: Phase 1 survey — batch 2 (`static-analysis`, `testing-coverage`, `cli-framework-ux`)

**Files:**
- Create: `docs/port/areas/static-analysis.md`, `docs/port/areas/testing-coverage.md`, `docs/port/areas/cli-framework-ux.md`

**Interfaces:**
- Consumes: `SURVEY-PROMPT.md` filled from the Task 3 table rows for these three areas.
- Produces: three area files passing `scripts/check-area-file.sh`.

- [ ] **Step 1: Confirm the checker fails on the three missing files**

Run: `for a in static-analysis testing-coverage cli-framework-ux; do bash scripts/check-area-file.sh docs/port/areas/$a.md; done; echo "exit=$?"`
Expected: three `FAIL: … missing or empty`, `exit=1`.

- [ ] **Step 2: Dispatch three sonnet agents in one message** — `Agent` tool, `subagent_type: "general-purpose"`, `model: "sonnet"`, `description: "Survey area <AREA>"`, prompt = `SURVEY-PROMPT.md` with `{{AREA}}`, `{{SCOPE}}`, `{{STARTER_FILES}}` substituted from the Task 3 table. Wait for all three.

- [ ] **Step 3: Gate**

Run: `for a in static-analysis testing-coverage cli-framework-ux; do bash scripts/check-area-file.sh docs/port/areas/$a.md; done`
Expected: three `OK:`. FAILs go back to the owning agent via `SendMessage`.

- [ ] **Step 4: Spot-check three citations per file**

```bash
for a in static-analysis testing-coverage cli-framework-ux; do
  grep -o '`[^`]*:[0-9][0-9]*`' docs/port/areas/$a.md | tr -d '`' | sort -u | awk 'BEGIN{srand()} {print rand()"\t"$0}' | sort | head -3 | cut -f2 |
  while IFS=: read -r p l; do
    for repo in py-launch-blueprint ts-launch-blueprint; do [ -f ~/c/$repo/$p ] && printf '%s %s:%s → ' "$a" "$p" "$l" && sed -n "${l}p" ~/c/$repo/$p; done
  done
done
```
Expected: printed lines match the rows' "how" text; ±1 drift is returned to the agent.

- [ ] **Step 5: Commit**

```bash
git add docs/port/areas/static-analysis.md docs/port/areas/testing-coverage.md docs/port/areas/cli-framework-ux.md
git commit -m "docs: survey areas static-analysis, testing-coverage, cli-framework-ux" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
```

---

### Task 5: Phase 1 survey — batch 3 (`config-env-logging`, `docs-system`, `git-hooks-commit-hygiene`)

**Files:**
- Create: `docs/port/areas/config-env-logging.md`, `docs/port/areas/docs-system.md`, `docs/port/areas/git-hooks-commit-hygiene.md`

**Interfaces:**
- Consumes: `SURVEY-PROMPT.md` filled from the Task 3 table rows for these three areas.
- Produces: three area files passing `scripts/check-area-file.sh`.

- [ ] **Step 1: Confirm the checker fails on the three missing files**

Run: `for a in config-env-logging docs-system git-hooks-commit-hygiene; do bash scripts/check-area-file.sh docs/port/areas/$a.md; done; echo "exit=$?"`
Expected: three `FAIL: … missing or empty`, `exit=1`.

- [ ] **Step 2: Dispatch three sonnet agents in one message** — same `Agent` call shape as Task 4 Step 2 with these three areas' rows. Wait for all three.

- [ ] **Step 3: Gate**

Run: `for a in config-env-logging docs-system git-hooks-commit-hygiene; do bash scripts/check-area-file.sh docs/port/areas/$a.md; done`
Expected: three `OK:`.

- [ ] **Step 4: Spot-check three citations per file**

```bash
for a in config-env-logging docs-system git-hooks-commit-hygiene; do
  grep -o '`[^`]*:[0-9][0-9]*`' docs/port/areas/$a.md | tr -d '`' | sort -u | awk 'BEGIN{srand()} {print rand()"\t"$0}' | sort | head -3 | cut -f2 |
  while IFS=: read -r p l; do
    for repo in py-launch-blueprint ts-launch-blueprint; do [ -f ~/c/$repo/$p ] && printf '%s %s:%s → ' "$a" "$p" "$l" && sed -n "${l}p" ~/c/$repo/$p; done
  done
done
```
Expected: matches; drift returned to the agent.

- [ ] **Step 5: Commit**

```bash
git add docs/port/areas/config-env-logging.md docs/port/areas/docs-system.md docs/port/areas/git-hooks-commit-hygiene.md
git commit -m "docs: survey areas config-env-logging, docs-system, git-hooks-commit-hygiene" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
```

---

### Task 6: Phase 1 survey — batch 4 (`packaging-distribution`, `web-service`, `dev-experience-repo-hygiene`) and Phase 1 close

**Files:**
- Create: `docs/port/areas/packaging-distribution.md`, `docs/port/areas/web-service.md`, `docs/port/areas/dev-experience-repo-hygiene.md`
- Modify: `PROJECTS.md` (P01-T02 → `[x]`)

**Interfaces:**
- Produces: all 13 area files green; the union of their `## Files read` lists is the input to `COVERAGE.md` (Task 11).

- [ ] **Step 1: Confirm the checker fails on the three missing files**

Run: `for a in packaging-distribution web-service dev-experience-repo-hygiene; do bash scripts/check-area-file.sh docs/port/areas/$a.md; done; echo "exit=$?"`
Expected: three `FAIL: … missing or empty`, `exit=1`.

- [ ] **Step 2: Dispatch three sonnet agents in one message** — same `Agent` call shape as Task 4 Step 2 with these three areas' rows. Wait for all three.

- [ ] **Step 3: Gate**

Run: `for a in packaging-distribution web-service dev-experience-repo-hygiene; do bash scripts/check-area-file.sh docs/port/areas/$a.md; done`
Expected: three `OK:`.

- [ ] **Step 4: Spot-check three citations per file**

```bash
for a in packaging-distribution web-service dev-experience-repo-hygiene; do
  grep -o '`[^`]*:[0-9][0-9]*`' docs/port/areas/$a.md | tr -d '`' | sort -u | awk 'BEGIN{srand()} {print rand()"\t"$0}' | sort | head -3 | cut -f2 |
  while IFS=: read -r p l; do
    for repo in py-launch-blueprint ts-launch-blueprint; do [ -f ~/c/$repo/$p ] && printf '%s %s:%s → ' "$a" "$p" "$l" && sed -n "${l}p" ~/c/$repo/$p; done
  done
done
```
Expected: matches; drift returned to the agent.

- [ ] **Step 5: Phase 1 exit check — all 13 files green and unread-file count known**

```bash
for f in docs/port/areas/*.md; do case "$f" in *SURVEY-PROMPT.md) continue;; esac; bash scripts/check-area-file.sh "$f"; done | grep -c '^OK:'
# files tracked in both repos that no surveyor listed under "Files read" (informational here; resolved in Task 11)
{ git -C ~/c/py-launch-blueprint ls-files | sed 's|^|py:|'; git -C ~/c/ts-launch-blueprint ls-files | sed 's|^|ts:|'; } | sort > "$CLAUDE_JOB_DIR/tmp/all-files"
grep -h '^- \(py\|ts\): `' docs/port/areas/*.md | sed 's/^- \(py\|ts\): `\([^`]*\)`.*/\1:\2/' | sort -u > "$CLAUDE_JOB_DIR/tmp/read-files"
comm -23 "$CLAUDE_JOB_DIR/tmp/all-files" "$CLAUDE_JOB_DIR/tmp/read-files" | wc -l
```
Expected: first command prints `13`; second prints the unread count (record it in the commit message body).

- [ ] **Step 6: Flip P01-T02, commit, push**

```bash
python3 - <<'PY'
p='PROJECTS.md'; s=open(p).read()
s=s.replace('- [~] [P01-T02] Phase 1','- [x] [P01-T02] Phase 1',1); open(p,'w').write(s)
PY
git add docs/port/areas/packaging-distribution.md docs/port/areas/web-service.md docs/port/areas/dev-experience-repo-hygiene.md PROJECTS.md
git commit -m "docs: survey areas packaging-distribution, web-service, dev-experience-repo-hygiene; close Phase 1" -m "Unread files after survey: <n> (resolved in COVERAGE.md)" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
git push https://github.com/smorinlabs/rs-launch-blueprint.git docs/p01-research-tree
```

---

### Task 7: Fixed parameters — owner decision, then `PARAMETERS.md`

**Files:**
- Create: `docs/port/PARAMETERS.md`

**Interfaces:**
- Produces: the four required `fixed` rows (§6.3). Every prompt's `## Constraints` quotes these values (Tasks 13, 15); the checker requires all four.

- [ ] **Step 1: Confirm the checker still wants the registry**

Run: `bash scripts/check-research-tree.sh 2>&1 | grep -c 'PARAMETERS.md'`
Expected: `1` (the "missing docs/port/PARAMETERS.md" line).

- [ ] **Step 2: Gather the evidence the owner needs from the area files**

```bash
grep -h 'os-matrix\|runs-on\|ubuntu\|macos\|windows' docs/port/areas/ci-workflows.md | head -20
grep -h 'license\|LICENSE' docs/port/areas/*.md | head; cat LICENSE | head -3
```
Expected: the py/ts CI OS matrix rows and the license evidence, to quote in the question.

- [ ] **Step 3: Ask the owner — one `AskUserQuestion` call, four questions, evidence written inline immediately before the call**

The four questions, each with the recommended option first:

| param | Recommended | Alternatives | Why the recommendation |
|---|---|---|---|
| `msrv-policy` | `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` | `latest stable only`; `pinned N.NN for 12 months` | matches how py (python floor) and ts (node LTS floor) both declare a floor and test it; keeps most crates eligible under the §7.6 MSRV gate |
| `rust-edition` | `2024` | `2021` | current edition; no reason to start a new template on the previous one |
| `target-os-matrix` | whatever `ci-workflows.md` shows both source repos use (expected `ubuntu-latest, macos-latest, windows-latest`) | drop Windows; add `ubuntu-24.04-arm` | §7 Constraints require cross-platform CI "as py and ts have"; deviating would itself be an OVERRIDE |
| `license` | `MIT` | `MIT OR Apache-2.0` (the Rust ecosystem's dual default) | the repo's `LICENSE` file is MIT and both source repos are MIT; dual licensing is a real option for a Rust *library* and is the one alternative worth putting in front of the owner |

- [ ] **Step 4: Write the registry with the owner's answers**

```bash
cat > docs/port/PARAMETERS.md <<'MD'
# Shared parameters

Registry of every repo-wide parameter (spec §6.3). `fixed` rows are owner decisions made before research; `researched` rows are owned by exactly one `R##` and get their value from that item's `DECISION.md` during P02.

| param | kind | owner | value | description |
|---|---|---|---|---|
| msrv-policy | fixed | owner | <answer> | minimum supported Rust version rule; every crate item is gated on it (§7.6) |
| rust-edition | fixed | owner | <answer> | Cargo edition for every workspace member |
| target-os-matrix | fixed | owner | <answer> | CI runners; every tool must run on all of them |
| license | fixed | owner | <answer> | repository license; candidate crates must be compatible (§7.6) |
MD
```
Replace each `<answer>` with the owner's chosen value verbatim (no `|` in the value).

- [ ] **Step 5: Verify the registry passes its own checks (the tree is still red for other reasons)**

Run: `bash scripts/check-research-tree.sh 2>&1 | grep -i 'param\|registry'; echo "---"; bash scripts/check-research-tree.sh 2>&1 | grep -c 'required fixed parameter'`
Expected: no registry FAIL lines; the count is `0`.

- [ ] **Step 6: Commit**

```bash
git add docs/port/PARAMETERS.md
git commit -m "docs: register the four fixed parameters (owner decision 2026-09-xx)" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
```

---

### Task 8: Phase 2 — ledger skeleton and the first area (`workspace-architecture`)

**Files:**
- Create: `docs/port/COMMONALITY.md`
- Modify: `docs/port/areas/workspace-architecture.md` (prepend `id` column)
- Modify: `PROJECTS.md` (P01-T03 → `[~]`)

**Interfaces:**
- Produces: ledger table `| ID | Feature | Area | Origin | Verdict | Item | Notes |`, `## Override arguments` section; the classification procedure that Task 9 repeats for the other 12 areas. `F###` ids are sequential across the whole ledger; `R##` and `OV-nn` ids are allocated sequentially in the order first needed.
- Consumes: the area file (Task 3), the verdict table (§3), the precedence rule (§3), the primary-assignment rule (§6.1).

`workspace-architecture` goes first because it owns the Cargo feature topology and the sync/async boundary; the `bundle` decisions in `web-service` and `cli-framework-ux` depend on rows it creates.

- [ ] **Step 1: Confirm the ledger is the next missing file**

Run: `bash scripts/check-research-tree.sh 2>&1 | grep COMMONALITY`
Expected: `FAIL: missing docs/port/COMMONALITY.md`

- [ ] **Step 2: Write the ledger skeleton**

```bash
cat > docs/port/COMMONALITY.md <<'MD'
# Commonality ledger

Authoritative verdicts for every atomic feature of `py-launch-blueprint` (b08bccf) and `ts-launch-blueprint` (cb1cbcb), per `docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md` §2–§3. Evidence for each row is the matching `id` in `areas/<Area>.md`. A tool row names its pattern row with `parent: F###`; `REUSE` rows carry `rust-ok: yes` and `live: YYYY-MM`.

| ID | Feature | Area | Origin | Verdict | Item | Notes |
|---|---|---|---|---|---|---|

## Override arguments
MD
```

- [ ] **Step 3: Classify every row of `areas/workspace-architecture.md` — the procedure**

For each data row of the area table, in file order:

1. **Atomic?** If the row names both a pattern and the tool that implements it, split it: a pattern row and one tool row per tool. Edit the area file so evidence rows and ledger rows are one-to-one.
2. **Allocate `F###`** (next unused, zero-padded to three digits) and prepend it to the area row: `| F017 | <feature> | … |`. Change the area table header to `| id | feature | py | ts | origin | ts-decisions | notes |` the first time.
3. **Origin** is copied from the area row. Add `none` rows only for things Rust must decide that neither repo has (an async runtime, `unsafe` policy, workspace layout) — write them into the area file too, with `—` in both `py` and `ts` cells and `none` as origin, so the checker still sees their evidence line (`check-area-file.sh` accepts `—` for both cells only when origin is `none`; extend the case statement in `scripts/check-area-file.sh` with `none) [ "$py" = "—" ] && [ "$ts" = "—" ] || err "none rows have no citations: $feat" ;;` before the first such row and commit that with the area).
4. **Verdict** by the §3 precedence: `none` → `RUST-ONLY`; one repo only → `ADOPT` if nothing needs choosing, else `DIVERGENT`; both differ → `DIVERGENT`; both same, language-bound tool → `SUBSTITUTE` under its pattern row; both same, language-neutral → `REUSE`; both same but the pattern must change → `OVERRIDE (OV-nn)`. Anything with no Rust analogue → `OMIT`.
5. **Notes**: `REUSE` → `rust-ok: yes; live: YYYY-MM` (the month of the newest release or commit of any language-neutral tool involved, checked on crates.io / GitHub now, or `live: n/a`). `SUBSTITUTE` → `parent: F###`. `OVERRIDE` → `see OV-nn` plus a `### OV-nn` section with one-line `**Argument:**` and `**Options:**` under `## Override arguments`. Never a `|` in Notes.
6. **Item**: allocate the next `R##` for `SUBSTITUTE` / `OVERRIDE` / `DIVERGENT` / `RUST-ONLY`. When several rows are only ever decided together (the web framework, its server and its middleware), give them the **same** `R##` and note `bundle` in Notes; that item's kind becomes `bundle` in Task 10. Everything else gets `—`.
7. **Primary assignment**: if this feature is *decided* by another area (CI merely runs the linter), do not create a row here; add `see F###` to the area row's notes once that row exists (Task 10 fixes forward references).

- [ ] **Step 4: Verify the area file still passes and the ledger rows parse**

```bash
bash scripts/check-area-file.sh docs/port/areas/workspace-architecture.md
bash scripts/check-research-tree.sh 2>&1 | grep -E 'ledger|F[0-9]{3}|OV-' || echo "no ledger FAILs"
```
Expected: `OK:` for the area file; only ledger FAILs of the kind "item R## is not in the index" (the index does not exist until Task 10) — no malformed-row, enum, legality, `parent:`, `rust-ok`, or OV FAILs.

- [ ] **Step 5: Commit the area**

```bash
python3 - <<'PY'
p='PROJECTS.md'; s=open(p).read()
s=s.replace('- [ ] [P01-T03] Phase 2','- [~] [P01-T03] Phase 2',1); open(p,'w').write(s)
PY
git add docs/port/COMMONALITY.md docs/port/areas/workspace-architecture.md scripts/check-area-file.sh PROJECTS.md
git commit -m "docs: classify workspace-architecture (F001-F0nn)" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
```

---

### Task 9: Phase 2 — classify the remaining 12 areas, one commit each

**Files:**
- Modify: `docs/port/COMMONALITY.md` (append rows and OV sections)
- Modify: `docs/port/areas/<area>.md` (prepend `id` column, splits, `none` rows)

**Interfaces:**
- Consumes: the seven-step procedure in Task 8 Step 3, unchanged.
- Produces: a ledger row for every evidence row of all 13 areas.

Order (dependencies first): `ci-workflows`, `release-versioning`, `lint-format`, `static-analysis`, `testing-coverage`, `git-hooks-commit-hygiene`, `dev-experience-repo-hygiene`, `packaging-distribution`, `config-env-logging`, `cli-framework-ux`, `web-service`, `docs-system`.

For **each** area in that order:

- [ ] **Step 1: Run the Task 8 Step 3 procedure over every row of `docs/port/areas/<area>.md`**, appending ledger rows with the next `F###` ids and any `### OV-nn` sections.

- [ ] **Step 2: Gate**

```bash
bash scripts/check-area-file.sh docs/port/areas/<area>.md
bash scripts/check-research-tree.sh 2>&1 | grep -E 'ledger|F[0-9]{3}|OV-' | grep -v 'is not in the index' || echo "no ledger FAILs"
```
Expected: `OK:`; `no ledger FAILs`.

- [ ] **Step 3: Commit**

```bash
git add docs/port/COMMONALITY.md docs/port/areas/<area>.md
git commit -m "docs: classify <area> (F0nn-F0mm)" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
```

After the twelfth area:

- [ ] **Step 4: Phase 2 row census, recorded for the Phase 4 reviewer**

```bash
awk -F'|' '/^\| F[0-9][0-9][0-9] /{gsub(/^ +| +$/,"",$6); v[$6]++} END{for(k in v) printf "%4d  %s\n", v[k], k}' docs/port/COMMONALITY.md | sort -rn
grep -c '^| F' docs/port/COMMONALITY.md
```
Expected: counts per verdict and the total; there must be at least 15 `COMMON → REUSE` rows (the §8 reviewer sample size) — fewer means the pattern/tool split was not applied and Task 10 must revisit.

---

### Task 10: Phase 2 — reconciliation pass, researched parameters, draft index

**Files:**
- Modify: `docs/port/COMMONALITY.md`, `docs/port/areas/*.md`
- Modify: `docs/port/PARAMETERS.md` (append `researched` rows)
- Create: `research/CLAUDE.md`
- Create: `research/RUNBOOK.md` (placeholder header only; Task 12 writes the body)

**Interfaces:**
- Produces: the index table `| id | slug | kind | origin | verdict | owns | prompt | status |` with one row per `R##`, `status = open`, `prompt` linking `topics/<nn>-<slug>/prompts/<slug>.prompt.md` (files created in Tasks 13/15); `researched` registry rows with `owner = R##`, `value = —`.
- Consumes: the area files' `## Cross-area parameters` lists (the candidate researched parameters).

- [ ] **Step 1: Duplicate and composite sweep**

```bash
# near-duplicate features across areas (same first four words)
awk -F'|' '/^\| F[0-9]{3} /{gsub(/^ +| +$/,"",$3); split(tolower($3),w," "); k=w[1]" "w[2]" "w[3]" "w[4]; print k"\t"$2"\t"$4}' docs/port/COMMONALITY.md | sort | awk -F'\t' '$1==p{print prev; print} {p=$1; prev=$0}'
# SUBSTITUTE rows whose parent is not REUSE/OVERRIDE
awk -F'|' '/^\| F[0-9]{3} /{gsub(/^ +| +$/,"",$2); gsub(/^ +| +$/,"",$6); v[$2]=$6; if($6 ~ /SUBSTITUTE/ && match($8,/parent: F[0-9]{3}/)) print $2, substr($8,RSTART+8,4)}' docs/port/COMMONALITY.md | while read -r r p; do case "$(awk -F'|' -v id="$p" '$2 ~ id {gsub(/^ +| +$/,"",$6); print $6}' docs/port/COMMONALITY.md)" in *REUSE*|*OVERRIDE*) ;; *) echo "parent of $r ($p) is not a pattern row";; esac; done
```
Expected: an empty duplicate list (or duplicates resolved by deleting the row in the non-deciding area and adding `see F###` there); no bad parents. Fix, then rerun until both are empty.

- [ ] **Step 2: Every `OVERRIDE` reread against §2** — for each `### OV-nn`, the `**Argument:**` must name a Rust-specific fact (ownership/borrowing, `cargo` semantics, crates.io policy, MSRV, binary distribution), not a preference. An argument that is a preference is downgraded to `SUBSTITUTE` (tool) or `REUSE`; its `OV-nn` section is deleted and later ids are **not** renumbered (gaps are fine; the checker only requires each used id to have exactly one section).

- [ ] **Step 3: Researched parameters** — union the 13 `## Cross-area parameters` lists, deduplicate, drop the four fixed ones, and for each remaining slug decide the single owning `R##` (the item whose answer sets the value; §6.3). Append to `docs/port/PARAMETERS.md`:

```
| <slug> | researched | R## | — | <what the value is and who consumes it> |
```
A slug no item can own is either a fixed parameter (ask the owner, one `AskUserQuestion`, evidence inline) or a misnamed feature (fold into a row).

- [ ] **Step 4: Write the draft index** — one row per distinct `R##` in the ledger, in `R##` order. `slug` is lowercase-kebab from the feature (or the bundle's name); `kind` is `bundle` when the item covers more than one ledger row that is not a pattern/tool pair, `pattern` when its rows are pattern rows, else `crate`; `origin` and `verdict` copy the (shared) ledger values; `owns` lists this item's researched parameters comma-separated or `—`; `prompt` is `[prompt](topics/<nn>-<slug>/prompts/<slug>.prompt.md)` with `<nn>` = the two digits of `R##`; `status` is `open`.

```bash
mkdir -p research
cat > research/CLAUDE.md <<'MD'
# Research index

One row per research item (spec §3 `Item`, §4 D4). `kind` ∈ crate | pattern | bundle; `status` ∈ open | in-progress | resolved | dropped. Ledger rows in `../docs/port/COMMONALITY.md` name their item in `Item`. Execution contract: `RUNBOOK.md`.

| id | slug | kind | origin | verdict | owns | prompt | status |
|---|---|---|---|---|---|---|---|
MD
printf '# Runbook\n\nWritten in Phase 3 (plan Task 12).\n' > research/RUNBOOK.md
```
Then append the rows.

- [ ] **Step 5: Verify — the checker's only remaining complaints are missing prompts and the runbook body**

```bash
bash scripts/check-research-tree.sh > "$CLAUDE_JOB_DIR/tmp/tree-check.log" 2>&1; tree_status=$?
grep -v 'links missing prompt' "$CLAUDE_JOB_DIR/tmp/tree-check.log" || :
printf 'checker exit=%s\n' "$tree_status"
```
Expected: no FAIL lines other than `links missing prompt` for every index row (filtered out above, so the output is empty) — in particular no `is not in the index`, `not declared by '- owns:'` is expected to appear **once per researched parameter** and is resolved in Task 15; note the count.

- [ ] **Step 6: Commit and push**

```bash
git add docs/port/COMMONALITY.md docs/port/areas docs/port/PARAMETERS.md research/CLAUDE.md research/RUNBOOK.md
git commit -m "docs: reconcile ledger; register researched parameters; draft research index (R01-R<nn>)" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
git push https://github.com/smorinlabs/rs-launch-blueprint.git docs/p01-research-tree
```

---

### Task 11: Phase 2 — derived documents: `COVERAGE.md`, `PY_INVENTORY.md`, `TS_INVENTORY.md`

**Files:**
- Create: `scripts/derive-port-docs.py`
- Create: `docs/port/COVERAGE.md`, `docs/port/PY_INVENTORY.md`, `docs/port/TS_INVENTORY.md`
- Modify: `PROJECTS.md` (P01-T03 → `[x]`)

**Interfaces:**
- Produces: `python3 scripts/derive-port-docs.py coverage|inventories [--check]` — `coverage` writes `docs/port/COVERAGE.md` from the recorded Git trees of both source repos (`git ls-tree -r --name-only <pinned-sha>`), the `id`-bearing citations in `docs/port/areas/*.md`, the `## Files read` lists, and the exclusion rules in `docs/port/COVERAGE.md`'s own `## Exclusion rules` bullet list; it exits 1 and prints `UNCOVERED: <repo>:<path>` for any file with neither a feature id nor an exclusion. `inventories` writes the two per-repo views from the ledger. `--check` compares regenerated content in memory and exits 1 if the committed output is missing or differs (Phase 4 uses this).
- Consumes: area files (`id` column, Task 8/9), ledger (Task 10).

- [ ] **Step 1: Write the failing test — a fixture with one uncovered file must make `coverage` exit 1**

```bash
mkdir -p "$CLAUDE_JOB_DIR/tmp/dp/docs/port/areas" && cd "$CLAUDE_JOB_DIR/tmp/dp"
cat > docs/port/areas/lint-format.md <<'MD'
# Area: lint-format

| id | feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|---|
| F001 | linter runs in CI | `justfile:12` — just lint | `package.json:31` — oxlint | same | — | |

## Language-bound tools
- `ruff` (py) — linter

## Cross-area parameters
- `ci-os-matrix` — runs everywhere

## Files read
- py: `justfile`
- ts: `package.json`
- ts: `README.md` — no feature: prose only
MD
cat > docs/port/COMMONALITY.md <<'MD'
# Commonality ledger

| ID | Feature | Area | Origin | Verdict | Item | Notes |
|---|---|---|---|---|---|---|
| F001 | linter runs in CI | lint-format | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-08 |
| F002 | py-only thing | docs-system | py-only | ADOPT | — | |
MD
printf 'py:justfile\npy:pyproject.toml\nts:package.json\nts:README.md\nts:pnpm-lock.yaml\n' > files.txt
cat > docs/port/COVERAGE.md <<'MD'
# Coverage manifest

## Exclusion rules
- `*-lock.yaml` — lockfile, generated
MD
cd - >/dev/null
```
(`files.txt` supplies an explicit fixture listing; the script accepts `--files <path>` for tests. Without it, the generator reads the two pinned commit trees, independent of live checkout or index changes.)

- [ ] **Step 2: Run to confirm the script does not exist**

Run: `python3 scripts/derive-port-docs.py coverage --root "$CLAUDE_JOB_DIR/tmp/dp" --files "$CLAUDE_JOB_DIR/tmp/dp/files.txt"; echo "exit=$?"`
Expected: `No such file or directory`, `exit=2`.

- [ ] **Step 3: Write `scripts/derive-port-docs.py`**

```python
#!/usr/bin/env python3
"""Derive docs/port/COVERAGE.md and the per-repo inventories from the area files and the ledger.

usage: derive-port-docs.py coverage    [--root DIR] [--files LIST] [--check]
       derive-port-docs.py inventories [--root DIR] [--check]
COVERAGE.md keeps its hand-written '## Exclusion rules' bullets (- `glob` — reason); the table is regenerated.
Exit 1 on UNCOVERED files or, with --check, on drift between committed and regenerated output.
"""
import argparse, fnmatch, pathlib, re, subprocess, sys

REPOS = {"py": pathlib.Path.home() / "c/py-launch-blueprint", "ts": pathlib.Path.home() / "c/ts-launch-blueprint"}
SOURCE_REVISIONS = {
    "py": "b08bccfb55d05f15e46a83b52c5660b1881d19f5",
    "ts": "cb1cbcb2e88b898e8c081b0abbfabc1630079c00",
}
CITE = re.compile(r"`([^`:]+):(\d+)`")
ROW = re.compile(r"^\|\s*(F\d{3})\s*\|(.*)\|\s*$")

def rows(table_file):
    """Yield (cells) for data rows of the single pipe table in table_file, header first."""
    out = []
    for line in table_file.read_text().splitlines():
        if line.startswith("|") and not line.startswith("|---"):
            out.append([c.strip() for c in line.strip().strip("|").split("|")])
    return out

def list_files(files_arg):
    if files_arg:
        return [l.strip() for l in pathlib.Path(files_arg).read_text().splitlines() if l.strip()]
    acc = []
    for tag, repo in REPOS.items():
        # Read the recorded tree, independent of the live checkout and its index.
        revision = SOURCE_REVISIONS[tag]
        try:
            ls = subprocess.run(["git", "-C", str(repo), "ls-tree", "-r", "--name-only", revision],
                                check=True, capture_output=True, text=True).stdout
        except subprocess.CalledProcessError as error:
            sys.exit(f"FAIL: cannot read pinned source {tag} at {revision} in {repo}: {error.stderr.strip()}")
        acc += [f"{tag}:{p}" for p in ls.splitlines() if p]
    return acc

def coverage(root, files_arg, check):
    areas = sorted((root / "docs/port/areas").glob("*.md"))
    feat = {}      # "py:path" -> set(F###)
    read_note = {} # "py:path" -> reason for a read-but-featureless file
    for a in areas:
        if a.name == "SURVEY-PROMPT.md":
            continue
        cells = rows(a)
        hdr = cells[0]
        if hdr[0] != "id":
            sys.exit(f"{a}: area table has no id column (run Phase 2 first)")
        ipy, its = hdr.index("py"), hdr.index("ts")
        for r in cells[1:]:
            for tag, i in (("py", ipy), ("ts", its)):
                for path, _ in CITE.findall(r[i]):
                    feat.setdefault(f"{tag}:{path}", set()).add(r[0])
        for line in a.read_text().splitlines():
            m = re.match(r"^- (py|ts): `([^`]+)`(?: — no feature: (.*))?$", line)
            if m and m.group(3):
                read_note[f"{m.group(1)}:{m.group(2)}"] = m.group(3).strip()
    cov = root / "docs/port/COVERAGE.md"
    text = cov.read_text() if cov.exists() else "# Coverage manifest\n\n## Exclusion rules\n"
    rules = re.findall(r"^- `([^`]+)` — (.+)$", text.split("## Exclusion rules", 1)[1], re.M) if "## Exclusion rules" in text else []
    lines = ["| repo | path | features |", "|---|---|---|"]
    uncovered = []
    for f in list_files(files_arg):
        tag, path = f.split(":", 1)
        if f in feat:
            val = " ".join(sorted(feat[f]))
        elif f in read_note:
            val = f"EXCLUDED: {read_note[f]}"
        else:
            reason = next((why for glob, why in rules if fnmatch.fnmatch(path, glob) or fnmatch.fnmatch(pathlib.Path(path).name, glob)), None)
            if reason is None:
                uncovered.append(f); val = "UNCOVERED"
            else:
                val = f"EXCLUDED: {reason}"
        lines.append(f"| {tag} | {path} | {val} |")
    table = "\n".join(lines) + "\n"
    previous = re.search(r"^\| repo \| path \| features \|\n(?:\|[^\n]*\|\n?)*", text, re.M)
    # Replace only the generated table; preserve rules and prose on either side.
    out = (text[:previous.start()] + table + text[previous.end():]
           if previous else text.rstrip() + "\n\n" + table)
    return write_or_check(cov, out, check, uncovered)

def inventories(root, check):
    led = rows(root / "docs/port/COMMONALITY.md")
    hdr = led[0]; io, iv = hdr.index("Origin"), hdr.index("Verdict")
    rc = 0
    for tag, name, origins in (("py", "PY_INVENTORY.md", {"same", "different", "py-only"}), ("ts", "TS_INVENTORY.md", {"same", "different", "ts-only"})):
        lines = [f"# {tag}-launch-blueprint inventory (derived from COMMONALITY.md — do not edit)", "",
                 "| ID | Feature | Area | Verdict | Item |", "|---|---|---|---|---|"]
        for r in led[1:]:
            if r[io] in origins:
                lines.append(f"| {r[0]} | {r[1]} | {r[2]} | {r[iv]} | {r[hdr.index('Item')]} |")
        rc |= write_or_check(root / "docs/port" / name, "\n".join(lines) + "\n", check, [])
    return rc

def write_or_check(path, out, check, uncovered):
    for u in uncovered:
        print(f"UNCOVERED: {u}")
    if check:
        if not path.exists():
            print(f"DRIFT: {path} is missing"); return 1
        current = path.read_text()
        if current == out and not uncovered:
            print(f"OK: {path} is current"); return 0
        print(f"DRIFT: {path} differs from regenerated output" if current != out else f"OK: {path} content current")
        return 1 if (uncovered or current != out) else 0
    path.write_text(out)
    print(f"wrote {path} ({out.count(chr(10))} lines)")
    return 1 if uncovered else 0

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["coverage", "inventories"])
    ap.add_argument("--root", default=str(pathlib.Path(__file__).resolve().parent.parent))
    ap.add_argument("--files"); ap.add_argument("--check", action="store_true")
    a = ap.parse_args(); root = pathlib.Path(a.root)
    sys.exit(coverage(root, a.files, a.check) if a.cmd == "coverage" else inventories(root, a.check))
```

- [ ] **Step 4: Run against the fixture — expect exactly one UNCOVERED and exit 1, then fix the fixture and expect 0**

```bash
python3 scripts/derive-port-docs.py coverage --root "$CLAUDE_JOB_DIR/tmp/dp" --files "$CLAUDE_JOB_DIR/tmp/dp/files.txt"; echo "exit=$?"
printf -- '- `pyproject.toml` — test exclusion\n' >> "$CLAUDE_JOB_DIR/tmp/dp/docs/port/COVERAGE.md"
python3 scripts/derive-port-docs.py coverage --root "$CLAUDE_JOB_DIR/tmp/dp" --files "$CLAUDE_JOB_DIR/tmp/dp/files.txt"; echo "exit=$?"
python3 scripts/derive-port-docs.py inventories --root "$CLAUDE_JOB_DIR/tmp/dp"; grep -c '^| F' "$CLAUDE_JOB_DIR/tmp/dp/docs/port/PY_INVENTORY.md" "$CLAUDE_JOB_DIR/tmp/dp/docs/port/TS_INVENTORY.md"
```
Expected: `UNCOVERED: py:pyproject.toml` then `exit=1`; then `wrote … exit=0` with `pnpm-lock.yaml` and `README.md` rows reading `EXCLUDED: …`; inventories: `PY_INVENTORY.md:2`, `TS_INVENTORY.md:1`.

- [ ] **Step 5: Run on the real tree, writing the exclusion rules by category (never file by file)**

```bash
cat > docs/port/COVERAGE.md <<'MD'
# Coverage manifest

Every tracked file of `py-launch-blueprint` (b08bccf) and `ts-launch-blueprint` (cb1cbcb) mapped to the ledger rows it evidences, or excluded by one of the rules below (spec §6.4). Regenerate with `python3 scripts/derive-port-docs.py coverage`; verify with `--check`.

## Exclusion rules
- `*.lock` — lockfile, generated
- `*-lock.yaml` — lockfile, generated
- `*.png` — image asset
- `*.svg` — image asset
- `LICENSE` — license text, not a feature
- `CHANGELOG.md` — generated by the release tool (feature is the tool row)
MD
python3 scripts/derive-port-docs.py coverage; echo "exit=$?"
```
Expected: initially `UNCOVERED:` lines and `exit=1`. For each uncovered file either (a) a surveyor missed it — send the file to the area's surveyor agent (Tasks 3–6 `SendMessage`) to add a row or a `no feature` line, then re-run Tasks 8–10's procedure for the new rows, or (b) it belongs to a category — add one rule. Repeat until `exit=0`. Rules must stay categorical; a rule matching exactly one file is a smell to explain in its reason.

- [ ] **Step 6: Generate inventories, close Phase 2, commit, push**

```bash
python3 scripts/derive-port-docs.py inventories
python3 scripts/derive-port-docs.py coverage --check && python3 scripts/derive-port-docs.py inventories --check
python3 - <<'PY'
p='PROJECTS.md'; s=open(p).read()
s=s.replace('- [~] [P01-T03] Phase 2','- [x] [P01-T03] Phase 2',1); open(p,'w').write(s)
PY
git add scripts/derive-port-docs.py docs/port/COVERAGE.md docs/port/PY_INVENTORY.md docs/port/TS_INVENTORY.md docs/port/areas docs/port/COMMONALITY.md PROJECTS.md
git commit -m "docs: coverage manifest and per-repo inventories; close Phase 2" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
git push https://github.com/smorinlabs/rs-launch-blueprint.git docs/p01-research-tree
```
Expected: both `--check` runs print `OK: … is current`.

---

### Task 12: Phase 3 — `research/RUNBOOK.md` (execution contract, §11)

**Files:**
- Modify: `research/RUNBOOK.md` (replace the placeholder)
- Modify: `PROJECTS.md` (P01-T04 → `[~]`)

**Interfaces:**
- Produces: the six numbered sections of §11 with concrete commands; Task 14 fills in the verified engine invocation in section 2; P02 executes from this file.
- Consumes: `research/CLAUDE.md` (`consumes` come from prompts, Task 13/15 — the run order is computed, not hand-listed).

- [ ] **Step 1: Confirm the placeholder is what the tree has**

Run: `cat research/RUNBOOK.md`
Expected: `# Runbook` and the "Written in Phase 3" line only.

- [ ] **Step 2: Write the runbook**

````markdown
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
  2. the owner item `R##` is re-opened: append a `### Conflict from R<consumer>` subsection with the line verbatim to the **end of the owner prompt's `## Context`** (append-only), and re-run it;
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
````

- [ ] **Step 3: Verify the checker no longer flags the runbook and the file has six H2s**

Run: `grep -c '^## [1-6]\.' research/RUNBOOK.md; bash scripts/check-research-tree.sh 2>&1 | grep -c RUNBOOK`
Expected: `6` and `0`.

- [ ] **Step 4: Commit**

```bash
python3 - <<'PY'
p='PROJECTS.md'; s=open(p).read()
s=s.replace('- [ ] [P01-T04] Phase 3','- [~] [P01-T04] Phase 3',1); open(p,'w').write(s)
PY
git add research/RUNBOOK.md PROJECTS.md
git commit -m "docs: research runbook (execution contract, spec §11)" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
```

---

### Task 13: Phase 3 — prompt template and the first two prompts

**Files:**
- Create: `research/PROMPT-TEMPLATE.md` (the eight-section skeleton with the per-kind answer fields; copied, never linked, into each prompt)
- Create: `research/topics/01-<slug>/prompts/<slug>.prompt.md` and `research/topics/02-<slug>/prompts/<slug>.prompt.md` for `R01` and `R02`

**Interfaces:**
- Consumes: index rows (Task 10), registry (Tasks 7, 10), ledger rows for the item, area evidence rows, fixed parameter values.
- Produces: prompts that pass the checker's section, id and coupling rules; the pilot input (Task 14).

- [ ] **Step 1: Confirm the checker wants exactly these two files first**

Run: `bash scripts/check-research-tree.sh 2>&1 | grep 'links missing prompt' | head -2`
Expected: two lines naming `topics/01-…` and `topics/02-…`.

- [ ] **Step 2: Write `research/PROMPT-TEMPLATE.md`**

Everything in `<angle brackets>` is filled per item; every other line is copied verbatim. The `## Answer template` block below contains all three kinds — a prompt keeps only its own kind's list (plus the OVERRIDE tail when its verdict is `COMMON → OVERRIDE`).

````markdown
# Deep-research prompt — <item title> (<R##>, <kind>)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver <a named crate with a version range | a named pattern with a reference implementation | a named stack of crates with versions> for: <the decision in one sentence>. Item kind: `<crate|pattern|bundle>`. Value test: if this answer is wrong, <what in the template changes — files, CI jobs, public API>.

## Context
- Inherited pattern (spec §2, presumption of reuse): <pattern text>. Evidence: py `<path:line>` — <how>; ts `<path:line>` — <how>. Ledger rows: <F###, F###> (`docs/port/COMMONALITY.md`), verdict `<verdict>`.
- Already decided, do not re-open: <values from the area tables / fixed parameters relevant here, each with its source>.
- <OVERRIDE items only:> The default is to keep pattern <X>. Argue whether Rust specifically justifies deviating; if not, say so.
- Prior decisions of the TypeScript port that explain the current shape: <D-### refs or "none">.

## Out of scope
- <what the search must not spend budget on, one bullet each — e.g. "no async runtime comparison; R0n owns `async-runtime`">
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: <R##>
- owns: <param, param | —>
- consumes: <R##: param; owner: param | —>
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: <one sentence>.
- HIGH: <question whose answer is scarce or decisive>
- HIGH: <…>
- MEDIUM: <…>
- LOW: <…>

## Required evidence
Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + link; "well-known" = nameable without lookup |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `<license value>`;
2. crate and dependency-tree MSRV within `<msrv-policy value>`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on Windows;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

## Answer template
Use exactly these field names as H3 headings, in this order.

<crate:>
### Dominant choice
### Qualified shortlist
Up to five that passed every gate (fewer is a finding): name · role · 90-day downloads · all-time downloads · stars · last release · maintenance state · notable adopters · one-line trade-off.
### Excluded by gate
### Up-and-comers
### Fit for this template
CLI · library · web, separately.
### Recommendation
### Ranked runner-up
And the condition under which it wins.
### Tradeoffs
What the pick gives up versus each runner-up and why that cost is accepted.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the choice landed.
### Confidence & re-verify trigger
### Sources

<pattern:> as `crate`, except *Qualified shortlist* is replaced by
### Options
name · where documented · adopters that practice it · date of the most recent authoritative write-up — no download columns; and *Fit for this template* argues per target shape.

<bundle:>
### Recommendation
One stack.
### Members
The full `crate` field set for each member.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
then *Parameters*, *Migration implications*, *Validation strategy*, *Confidence & re-verify trigger*, *Sources* as above.

<OVERRIDE items append:>
### Inherited default
### Rust-specific argument
### Options rejected
### Override justified
`yes` or `no`.
### Resulting verdict

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Stable Rust only; edition `<rust-edition value>`; MSRV policy `<msrv-policy value>`; license `<license value>`.
- CI on `<target-os-matrix value>` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
````

- [ ] **Step 3: Write the `R01` and `R02` prompts from the template**

For each: create `research/topics/<nn>-<slug>/prompts/<slug>.prompt.md` where `<nn>` and `<slug>` are exactly the index row's; fill every `<…>`; keep only the item's kind in `## Answer template`; `- id:`, `- owns:`, `- consumes:` copy the index and registry exactly (`owns` = the registry rows whose owner is this item, or `—`; `consumes` names only parameters the named owner holds).

- [ ] **Step 4: Verify the two prompts pass every prompt rule**

```bash
bash scripts/check-research-tree.sh 2>&1 | grep -E 'topics/0[12]-|R0[12]\b' ; echo "---"
for p in research/topics/0[12]-*/prompts/*.prompt.md; do awk '/^```/{f=!f;next} !f&&/^## /' "$p" | tr '\n' '|'; echo; done
```
Expected: no FAIL lines mentioning these two items; each prompt prints exactly `## Objective|## Context|## Out of scope|## Couplings|## Questions|## Required evidence|## Answer template|## Constraints|`.

- [ ] **Step 5: Commit**

```bash
git add research/PROMPT-TEMPLATE.md research/topics/01-* research/topics/02-*
git commit -m "docs: prompt template and prompts R01, R02" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
```

---

### Task 14: Phase 3 — conformance pilot (P01-TS07) and the answer-shape checker

**Files:**
- Create: `scripts/check-answer-shape.sh`
- Modify: `research/RUNBOOK.md` §2 (engine, invocation, date)
- Modify: `PROJECTS.md` (P01-TS07 → `[x]`)
- Pilot output: `$CLAUDE_JOB_DIR/tmp/pilot/` only — **never committed** (§6 Phase 3: content discarded, binds nothing)

**Interfaces:**
- Produces: `check-answer-shape.sh <answer.md> <kind> [override]` → exit 0 or exit 1 listing missing `### <field>` headings; the verified engine call in the runbook.
- Consumes: the `R01` prompt (Task 13).

- [ ] **Step 1: Write the failing test for the shape checker**

```bash
mkdir -p "$CLAUDE_JOB_DIR/tmp/pilot"
printf '### Dominant choice\nx\n### Qualified shortlist\nx\n### Recommendation\nx\n' > "$CLAUDE_JOB_DIR/tmp/pilot/partial.md"
bash scripts/check-answer-shape.sh "$CLAUDE_JOB_DIR/tmp/pilot/partial.md" crate; echo "exit=$?"
```
Expected: `No such file or directory`, `exit=127`.

- [ ] **Step 2: Write `scripts/check-answer-shape.sh`**

```bash
cat > scripts/check-answer-shape.sh <<'SH'
#!/usr/bin/env bash
# Does an engine answer fill the §7.7 template? Usage: check-answer-shape.sh <answer.md> <crate|pattern|bundle> [override]
set -uf
f="${1:?answer file}"; kind="${2:?kind}"; ov="${3:-}"; fail=0
common="Recommendation|Ranked runner-up|Tradeoffs|Parameters|Migration implications|Validation strategy|Confidence & re-verify trigger|Sources"
case "$kind" in
  crate)   want="Dominant choice|Qualified shortlist|Excluded by gate|Up-and-comers|Fit for this template|$common" ;;
  pattern) want="Dominant choice|Options|Excluded by gate|Up-and-comers|Fit for this template|$common" ;;
  bundle)  want="Recommendation|Members|Compatibility|Parameters|Migration implications|Validation strategy|Confidence & re-verify trigger|Sources" ;;
  *) echo "FAIL: kind '$kind' not crate|pattern|bundle"; exit 1 ;;
esac
[ "$ov" = override ] && want="$want|Inherited default|Rust-specific argument|Options rejected|Override justified|Resulting verdict"
while IFS= read -r field; do
  grep -qx "### $field" "$f" || { printf 'FAIL: missing field "### %s"\n' "$field"; fail=1; }
done < <(printf '%s' "$want" | tr '|' '\n')
[ "$fail" -eq 0 ] && echo "OK: $f fills the $kind template${ov:+ (+override)}"; exit "$fail"
SH
chmod +x scripts/check-answer-shape.sh
bash scripts/check-answer-shape.sh "$CLAUDE_JOB_DIR/tmp/pilot/partial.md" crate; echo "exit=$?"
```
Expected: FAIL lines for the missing fields (e.g. `Excluded by gate`), `exit=1`.

- [ ] **Step 3: Pick the engine — in this order, stop at the first that works**

1. **`/deep-research` built-in**: invoke the `Skill` tool with `skill: "deep-research"` and the `R01` prompt file path as `args`. If the skill is not listed, it is unavailable in this session — go to 2.
2. **Doxa** via the `doxa-research` skill: this is a **paid** run. Before submitting, tell the owner: 1 prompt, the selected provider and mode (single provider, deep-research mode), output dir `$CLAUDE_JOB_DIR/tmp/pilot/doxa/`, blocking or `--async`, number of provider calls (1). Proceed only on an explicit yes (`AskUserQuestion`, evidence inline, options: "run it (1 paid call)" / "skip the pilot — record as untested").
3. Neither → record `engine: none available on 2026-09-xx; pilot deferred to P02 Task 01` in the runbook §2 and PROJECTS.md, keep P01-TS07 unchecked, skip Steps 4–5, and continue with Task 15 (the template is then untested; P02's pilot item is the first real check).

- [ ] **Step 4: Run the pilot on `R01` and check only the shape**

Save the raw answer to `$CLAUDE_JOB_DIR/tmp/pilot/R01-answer.md`, then:
```bash
bash scripts/check-answer-shape.sh "$CLAUDE_JOB_DIR/tmp/pilot/R01-answer.md" <kind of R01> [override]; echo "exit=$?"
```
Expected: `OK:`. On `FAIL`, the template — not the engine — is fixed: adjust the field wording in `research/PROMPT-TEMPLATE.md` and both existing prompts so the engine can fill it, re-run once, re-check. Do **not** read or act on the technology content; delete the directory when done (`rm -rf "$CLAUDE_JOB_DIR/tmp/pilot"`).

- [ ] **Step 5: Only after Step 4 passes, record the verified invocation and close TS07**

This step is conditional on an actual pilot answer passing `scripts/check-answer-shape.sh`. A deferred or failed pilot leaves P01-TS07 unchecked. Replace the three `<…>` placeholders in `research/RUNBOOK.md` §2 (engine, date, exact invocation) with what actually ran; commit.
```bash
python3 - <<'PY'
p='PROJECTS.md'; s=open(p).read()
s=s.replace('- [ ] [P01-TS07] Phase 3 conformance pilot','- [x] [P01-TS07] Phase 3 conformance pilot',1); open(p,'w').write(s)
PY
git add scripts/check-answer-shape.sh research/RUNBOOK.md research/PROMPT-TEMPLATE.md research/topics PROJECTS.md
git commit -m "docs: conformance pilot passed on R01; answer-shape checker; engine recorded in runbook" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
```

---

### Task 15: Phase 3 — remaining prompts and a green checker (P01-T04, P01-TS02)

**Files:**
- Create: `research/topics/<nn>-<slug>/prompts/<slug>.prompt.md` for every index row from `R03` on
- Modify: `PROJECTS.md` (P01-T04, P01-TS02 → `[x]`)

**Interfaces:**
- Consumes: `research/PROMPT-TEMPLATE.md` as fixed by the pilot; index; registry; ledger; area evidence.
- Produces: `scripts/check-research-tree.sh` exit 0 (without the owner-review flag).

- [ ] **Step 1: Count what is missing**

Run: `bash scripts/check-research-tree.sh 2>&1 | grep -c 'links missing prompt'`
Expected: the number of index rows minus 2.

- [ ] **Step 2: Write prompts in batches of one area at a time** (index order within the area). For each prompt follow Task 13 Step 3 exactly. After each area's batch:

```bash
bash scripts/check-research-tree.sh > "$CLAUDE_JOB_DIR/tmp/tree-check.log" 2>&1; tree_status=$?
grep -vE 'links missing prompt' "$CLAUDE_JOB_DIR/tmp/tree-check.log" || :
printf 'checker exit=%s\n' "$tree_status"
git add research/topics
git commit -m "docs: prompts for <area> (R0n-R0m)" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
```
Expected after every batch: no FAIL line other than `links missing prompt` for prompts not yet written — in particular no `owns unregistered parameter`, no `does not own`, no `H2 sections are`.

- [ ] **Step 3: Whole-tree green**

Run: `bash scripts/check-research-tree.sh`
Expected: `OK: research tree structure valid`, exit 0. Stop on any failure.

- [ ] **Step 4: Cross-check the index against the ledger by hand-readable counts**

```bash
echo "index items: $(grep -c '^| R' research/CLAUDE.md)"
echo "ledger rows needing research: $(awk -F'|' '/^\| F[0-9]{3} /{gsub(/ /,"",$7); if($7 ~ /^R[0-9][0-9]$/) print $7}' docs/port/COMMONALITY.md | sort -u | wc -l)"
```
Expected: the two numbers are equal.

- [ ] **Step 5: Close T04 and TS02, commit, push**

```bash
python3 - <<'PY'
p='PROJECTS.md'; s=open(p).read()
for a,b in (('- [~] [P01-T04] Phase 3','- [x] [P01-T04] Phase 3'),('- [ ] [P01-TS02]','- [x] [P01-TS02]')): s=s.replace(a,b,1)
open(p,'w').write(s)
PY
git add PROJECTS.md
git commit -m "docs: close Phase 3 — research tree checker green" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
git push https://github.com/smorinlabs/rs-launch-blueprint.git docs/p01-research-tree
```

---

### Task 16: Phase 3.5 — owner review of every item (P01-T07)

**Files:**
- Create: `docs/port/OWNER-REVIEW.md`
- Modify: `research/CLAUDE.md`, `docs/port/COMMONALITY.md`, `docs/port/PARAMETERS.md` (disposition effects), `PROJECTS.md` (P01-T07 → `[x]`)

**Interfaces:**
- Consumes: the green tree (Task 15).
- Produces: `docs/port/OWNER-REVIEW.md` with one row per index item, `| item | disposition | rationale | date |`, disposition ∈ `accept|narrow|force|drop` (spec §6.5); `scripts/check-research-tree.sh --require-owner-review` exit 0.

This is an owner-reserved decision: the executor prepares evidence and a suggested disposition per item, but writes nothing into `OWNER-REVIEW.md` the owner did not confirm.

- [ ] **Step 1: Confirm the flag is currently red for the right reason**

```bash
bash scripts/check-research-tree.sh --require-owner-review > "$CLAUDE_JOB_DIR/tmp/tree-check.log" 2>&1; tree_status=$?
tail -3 "$CLAUDE_JOB_DIR/tmp/tree-check.log"
printf 'checker exit=%s\n' "$tree_status"
test "$tree_status" -eq 1
```
Expected: `FAIL: --require-owner-review set but docs/port/OWNER-REVIEW.md is missing` (or the checker's equivalent wording), non-zero exit.

- [ ] **Step 2: Build the review table for chat**

```bash
python3 - <<'PY'
import re
rows=[l for l in open('research/CLAUDE.md') if re.match(r'\| R\d\d ',l)]
print('| item | slug | kind | verdict | owns | suggested | why |'); print('|---|---|---|---|---|---|---|')
for l in rows:
    c=[x.strip() for x in l.strip().strip('|').split('|')]
    print(f'| {c[0]} | {c[1]} | {c[2]} | {c[4]} | {c[5]} | accept | |')
PY
```
Fill `suggested` and `why` by hand from the ledger before presenting — the suggestion rules are: `accept` by default; `narrow` when the item's Questions contain more than four HIGH lines or it owns more than three parameters (too broad for one engine run); `force` only when the owner said so earlier (none expected); `drop` never suggested by the executor (it removes work the classification found necessary — the owner alone can decide that).

- [ ] **Step 3: Present the table inline and ask for exceptions**

Print the filled table as visible text, then one `AskUserQuestion` (header `Dispositions`): "All items default to the suggested disposition. Reply with exceptions as `R## <disposition> — <rationale>`, one per line, or accept all." Options: "Accept all suggested (Recommended)" / "I have exceptions (I'll list them)". Read the exceptions from the "Other" text.

- [ ] **Step 4: Write `docs/port/OWNER-REVIEW.md`**

```markdown
# Owner review — research items (spec §6.5)

Every index item has a disposition, with the effects spec §6.5 defines: `accept` = no effect on the tree; `narrow` = the prompt's `## Out of scope` and `## Questions` are edited to the owner's rationale, ledger row unchanged; `force <tool>` = the prompt is rewritten as a fitness check of the named tool, `## Objective` states the choice is forced; `drop` = index status `dropped`, every ledger row that pointed at the item re-verdicted to a non-research verdict with Item `—`, prompt kept as history.

| item | disposition | rationale | date |
|---|---|---|---|
| R01 | accept | <owner's words or "default"> | 2026-09-xx |
…
```
One row per index item, dates as `YYYY-MM-DD`.

- [ ] **Step 5: Apply the effects**

- `narrow`: edit the existing prompt's `## Out of scope` and `## Questions` to the owner's rationale; leave the ledger unchanged.
- `drop`: keep the index row with status `dropped` and preserve the prompt as history. Re-verdict every linked ledger row to a legal non-research verdict with `Item` set to `—`. Reconcile any owned parameters and consumers with the owner before running dependent items.
- `force <tool>`: rewrite the existing item's prompt as a fitness check of that tool and state the forced choice in `## Objective`; retain the empirical gate and both audits. This disposition does not create research items for REUSE rows.
- `accept`: none.

- [ ] **Step 6: Green with the flag, close T07, commit, push**

```bash
bash scripts/check-research-tree.sh --require-owner-review || exit "$?"
python3 - <<'PY'
p='PROJECTS.md'; s=open(p).read(); s=s.replace('- [ ] [P01-T07]','- [x] [P01-T07]',1); open(p,'w').write(s)
PY
git add docs/port/OWNER-REVIEW.md research docs/port PROJECTS.md
git commit -m "docs: owner review dispositions for all research items (Phase 3.5)" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
git push https://github.com/smorinlabs/rs-launch-blueprint.git docs/p01-research-tree
```
Expected: `OK: research tree structure valid`, `exit=0`.

---

### Task 17: Phase 4 — independent reviewer (P01-TS03)

**Files:**
- Create: `docs/port/REVIEW-PHASE4.md` (the reviewer's findings and their resolution)
- Modify: whatever the findings require; `PROJECTS.md` (P01-TS03 → `[x]`)

**Interfaces:**
- Consumes: the whole branch as of Task 16.
- Produces: a findings file with every finding marked `fixed` or `accepted (reason)`; the tree still green with the flag.

- [ ] **Step 1: Dispatch one reviewer** — `Agent`, `subagent_type: "general-purpose"`, `model: "opus"`, `description: "Phase 4 review of research tree"`, prompt:

```
You are the Phase 4 reviewer for ~/c/rs-launch-blueprint-research (branch docs/p01-research-tree). Read docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md §2, §3, §6.4, §8 first. You produced none of these files; be adversarial. Report findings as a markdown table `| # | file:line | rule | finding | severity(high|med|low) |` — nothing else. Checks, all mandatory:
1. Run `bash scripts/check-research-tree.sh --require-owner-review` and `bash scripts/test-check-research-tree.sh` — report non-zero exits as high.
2. Run `python3 scripts/derive-port-docs.py coverage --check` and `python3 scripts/derive-port-docs.py inventories --check` — drift is high.
3. Count ledger rows with verdict `COMMON → REUSE`; fewer than 15 is high (spec §6.4).
4. Sample 30 `path:line` citations at random across docs/port/areas/*.md (`sed -n "<line>p"` in ~/c/py-launch-blueprint or ~/c/ts-launch-blueprint, which are pinned at b08bccf and cb1cbcb — verify with `git -C <repo> rev-parse HEAD`). Any citation whose line does not evidence the feature is high.
5. For EVERY ledger row whose verdict is not `COMMON → REUSE`: is the verdict legal for its origin (spec §3 table)? For OVERRIDE rows: does `### OV-nn` give a Rust-specific argument and at least two options, and would §2 call the argument a preference rather than a constraint? A preference-grade argument is high.
6. For every `DIVERGENT` row: does the Notes cell name both sides' evidence?
7. For every index item: does its prompt's `## Context` cite the ledger rows it claims, and does `## Out of scope` name the owning item for each excluded topic?
8. Anything that reads as a placeholder (`TBD`, `TODO`, `<…>`, `xx`) outside code fences — high.
Do not edit any file.
```

- [ ] **Step 2: Triage and fix**

Write the reviewer's table verbatim into `docs/port/REVIEW-PHASE4.md` under `## Findings`, add a `resolution` column: `fixed <commit>` or `accepted — <reason>`. Every `high` must be `fixed`; `med`/`low` may be `accepted` with a reason. Fixes follow the producer rule: citation fixes go back through the area file (and `check-area-file.sh`), verdict fixes through the ledger and, if the Item changes, the index and prompts.

- [ ] **Step 3: Re-run every gate**

```bash
bash -e <<'SH'
bash scripts/check-research-tree.sh --require-owner-review
bash scripts/test-check-research-tree.sh
for a in docs/port/areas/*.md; do
  [ "${a##*/}" = SURVEY-PROMPT.md ] && continue
  bash scripts/check-area-file.sh "$a"
done
python3 scripts/derive-port-docs.py coverage --check
python3 scripts/derive-port-docs.py inventories --check
SH
```
Expected: exit 0, `53 passed, 0 failed`, and every tree, area, coverage and inventory check reports success. The survey prompt is a template, not an area evidence file; the loop excludes it. Stop before Step 4 on any failure.

- [ ] **Step 4: Close TS03, commit, push**

```bash
python3 - <<'PY'
p='PROJECTS.md'; s=open(p).read(); s=s.replace('- [ ] [P01-TS03]','- [x] [P01-TS03]',1); open(p,'w').write(s)
PY
git add -A
git commit -m "docs: Phase 4 review findings resolved" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
git push https://github.com/smorinlabs/rs-launch-blueprint.git docs/p01-research-tree
```

---

### Task 18: Phase 5 — ship v0.1.0 (P01-T05)

**Files:**
- Modify: `PROJECTS.md` (P01 → `[x]`, P01-T05 → `[x]`), `docs/port/README.md` (link every generated doc)

**Interfaces:**
- Consumes: the reviewed branch (Task 17), the draft PR `<PR>` opened in Task 1.
- Produces: tag `v0.1.0` on `main`; `~/c/rs-launch-blueprint` fast-forwarded; worktree removed.

- [ ] **Step 1: Final PROJECTS.md and README edits**

In `PROJECTS.md`: flip `## [~] Project P01` to `## [x] Project P01`, `- [ ] [P01-T05]` to `- [x] [P01-T05]`, and leave P02's header at `[ ]` (scoped, not started). In `docs/port/README.md` add one bullet per file under `docs/port/` (areas, COMMONALITY, PARAMETERS, COVERAGE, PY_INVENTORY, TS_INVENTORY, OWNER-REVIEW, REVIEW-PHASE4) and one for `research/CLAUDE.md`, `research/RUNBOOK.md`, `research/PROMPT-TEMPLATE.md`.

```bash
git add PROJECTS.md docs/port/README.md
git commit -m "docs: close P01 research tree; index all port documents" -m "Claude-Session: https://claude.ai/code/session_014W5murKc9M98GyzVGn7JCV"
git push https://github.com/smorinlabs/rs-launch-blueprint.git docs/p01-research-tree
```

- [ ] **Step 2: Mark the draft PR ready and hand off for review**

```bash
gh api -X PATCH "repos/smorinlabs/rs-launch-blueprint/pulls/<PR>" -f draft=false >/dev/null 2>&1 \
  || gh pr ready <PR> --repo smorinlabs/rs-launch-blueprint
git rev-parse HEAD   # record as <sha>
```
(The REST draft flip needs the GraphQL-only `convertPullRequestToDraft` inverse on some `gh` versions; `gh pr ready` is the fallback.) Then stop: present the PR URL and a summary of the branch (commit list, file counts, `wc -l` of the ledger and index) and wait for the owner's review — merges wait for the user's PR review.

- [ ] **Step 3: Merge (merge commit), fast-forward, clean up** — only after the owner says merge

```bash
gh pr merge <PR> --repo smorinlabs/rs-launch-blueprint --merge --match-head-commit <sha>
git -C ~/c/rs-launch-blueprint fetch origin main
git -C ~/c/rs-launch-blueprint pull --ff-only
git -C ~/c/rs-launch-blueprint worktree remove ../rs-launch-blueprint-research
git -C ~/c/rs-launch-blueprint worktree prune
git -C ~/c/rs-launch-blueprint branch -d docs/p01-research-tree   # refusal = merge did not land as expected; stop and report
```

- [ ] **Step 4: Tag v0.1.0 on the merge commit and push it over HTTPS**

```bash
cd ~/c/rs-launch-blueprint
git tag -a v0.1.0 -m "P01: port inventories, commonality ledger, research index and prompts"
git push https://github.com/smorinlabs/rs-launch-blueprint.git v0.1.0
git ls-remote --tags https://github.com/smorinlabs/rs-launch-blueprint.git v0.1.0
```
Expected: the last command prints one line ending in `refs/tags/v0.1.0`.

- [ ] **Step 5: Report** — PR URL, merge SHA, tag, and the P02 entry as the next project.

---

## P02 entry in PROJECTS.md (shipped with this plan, not by a task)

The owner chose option A: research execution is a follow-on project. This block is already in `PROJECTS.md` on the plan branch so that P02 exists before P01's execution starts; it is reproduced here because P02's tasks name files this plan creates (`scripts/check-answer-shape.sh`, `RUNBOOK.md` sections, `OWNER-REVIEW.md` dispositions).

~~~markdown
## [ ] Project P02: Execute research program (v0.2.0)
**Goal/Requirement**: Run every research item the owner accepted in Phase 3.5 under `research/RUNBOOK.md`, producing one audited `DECISION.md` per item and a filled `docs/port/PARAMETERS.md`.
- Gate: P01 merged and tagged `v0.1.0`; only items with disposition `accept`, `narrow` or `force` in `docs/port/OWNER-REVIEW.md` are run.
- Engine and invocation: exactly as recorded in `research/RUNBOOK.md` §2; Doxa runs are paid and each batch is confirmed by the owner before submission.
- Plan: written with `superpowers:writing-plans` after v0.1.0 — not part of P01's plan.

**Out of Scope**
- Any Rust code, `Cargo.toml`, CI workflow, or template file (the port itself)
- Re-opening ledger verdicts except through P02-TS02 (an OVERRIDE whose research answers "Override justified: no")
- Items dropped in Phase 3.5

### Tests & Tasks
- [ ] [P02-T01] Run the pilot item end-to-end (prompt → raw answer → `scripts/check-answer-shape.sh` → `DECISION.md` → both audits) — this run is binding, unlike P01-TS07
- [ ] [P02-T02] Run all remaining items in topological batches of at most 4 (`RUNBOOK.md` §1 order); raw answers saved under `topics/<nn>-<slug>/raw/`
- [ ] [P02-T03] Resolve every `CONFLICT:` line by the `RUNBOOK.md` §4 rule (registry first, owner prompt re-run, consumer re-run)
- [ ] [P02-T04] Write `audit-codex.md` and `audit-fable.md` for every item; the producer of a decision never audits it
- [ ] [P02-T05] Copy every `owns <param> = <value>` into `docs/port/PARAMETERS.md` and set the row's `owner` value column
- [ ] [P02-T06] Flip every index row to `resolved`; `scripts/check-research-tree.sh --require-owner-review` exits 0
- [ ] [P02-T07] PR, owner review, merge (merge commit), `pull --ff-only`, tag `v0.2.0`
- [ ] [P02-TS01] Every `DECISION.md` has an `## Empirical check` whose command was actually executed and whose output is pasted
- [ ] [P02-TS02] A reviewer re-reads every OVERRIDE item's "Override justified" field; any `no` flips the ledger row back to the inherited verdict and records the reversal under `### OV-nn`
- [ ] Regression Test Status

### Deliverable
```bash
$ grep -c '| resolved |' research/CLAUDE.md          # equals the number of index rows
$ scripts/check-research-tree.sh --require-owner-review
OK: research tree structure valid
```

### Automated Verification
- `scripts/check-research-tree.sh --require-owner-review` exits 0 with every index row `resolved`
- Every raw answer in `research/topics/*/raw/*.md` passes `scripts/check-answer-shape.sh` for its item's kind (with `override` where the ledger says OVERRIDE).
- `scripts/check-research-tree.sh` checks decision structure and audit-file presence. P02-TS01 separately requires review of the executed empirical check.

### Manual Verification
- Owner reads every OVERRIDE decision and every `audit-*.md` that disagrees with its decision
~~~

---

## Self-review record

Spec coverage — every H2 of the spec maps to a task: §2 presumption of reuse → Tasks 8, 10 (verdict precedence, OV reread); §3 verdict set → Task 8 Step 4 and the checker; §4 D1–D9 → D2 finish line = Tasks 6/10/11/13/14/15, D4 kinds = index `kind` column (Task 10), D5 engine = Task 14, D6 no prior art = Global Constraints + template `## Constraints`, D8 evidence = template `## Required evidence`; §5 layout → File map + additions; §6 pipeline → Tasks 3–6 (surveys), 8–11 (classification, registry, coverage), 12–15 (runbook, prompts, pilot), 16 (3.5), 17 (Phase 4), 18 (Phase 5); §7 prompt sections and §7.6/§7.7 → Task 13 template and Task 14 shape checker; §8 checker rules → gates in every task; §10 conventions → pilot first (14), empirical gate and dual audits (P02), append-only conflicts (runbook §4), producer never validates own output (Task 3 SendMessage rule, Task 17 reviewer); §11 runbook → Task 12; §12 Codex dispositions → carried into spec v3, no separate task.

Placeholder scan — angle-bracket tokens in this plan are either executor-filled values named at their first use (`<PR>`, `<sha>`, `<AREA>`, `<kind of R01>`) or template slots inside code fences that Task 13 says to fill; no `TBD`/`TODO`.

Name consistency — `scripts/check-area-file.sh` (Tasks 2, 3–6, 8, 17), `scripts/derive-port-docs.py coverage|inventories [--check]` (Tasks 11, 17), `scripts/check-answer-shape.sh <file> <kind> [override]` (Tasks 14, P02), `research/PROMPT-TEMPLATE.md` (13, 14, 15, 18), worktree `~/c/rs-launch-blueprint-research` / branch `docs/p01-research-tree` (1, 6, 10, 11, 15–18).
