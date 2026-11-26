# AGENTS.md — rs-launch-blueprint charter

Read, in order: `README.md`, `docs/port/README.md` (verdict vocabulary),
`research/CLAUDE.md` (research index) before touching anything.

- Research engineering principles and ecosystem best practices first (spec §2,
  owner amendment A5). Existing py/ts implementations are evidence, not winners
  by default. Preserve the intended outcomes using justified native designs.
- Track departures from recorded patterns as `OVERRIDE (OV-nn)` with
  `**Argument:**` and `**Options:**`; agreement alone is not evidence of fitness.
- Never assign a verdict from memory; cite the files in both source repos.
- Returning to this work after any interruption, start with
  `uv run --offline --no-project --no-python-downloads --no-cache python3
  scripts/research_scan.py --todo`. It reconstructs every item's state from the
  repository, names the next action, and lists unfinished provider operations
  with the identifiers that recover them. Never rely on an agent's memory of
  what was running.
- Run `scripts/check-research-tree.sh` before opening a PR.
- Work in a worktree branched from `origin/main`; never commit to `main`.

- Run `bash scripts/check-shell.sh` before opening a PR. Install ShellCheck
  with `bash scripts/install-shellcheck.sh` and add `~/.local/bin` to PATH.

- Install the native pre-commit hook with `bash scripts/install-hooks.sh`.
  It checks staged shell content; preserve and integrate any existing hooks.

## project-harness — project workflow skills

This repo uses the `project-harness` plugin. Project state lives
in `PROJECTS.md` (the trunk) and `projects/P<NN>-*.md` (per-project
files). When the user mentions a project, plan, milestone, or
backlog, route through one of:

- `using-project-harness` — bootstrap and orientation
- `project-next` — what's in progress / next / recently touched
- `project-add` — capture an idea (≤4 questions, atomic ID reserve)
- `project-refine` — flesh out / scope / decompose / refine
  references
- `project-audit` — verify state matches conventions; fix per
  finding

**Schema (self-describing for external tools).** Trunk rows use
the standard markdown-link format
`- [<glyph>] **P<NN>** — [<title>](projects/P<NN>-<slug>.md)`.
Every non-`[?]` per-project file has a `**References**` block at
the top whose first bullet is
`- **Trunk:** [PROJECTS.md](../PROJECTS.md)` — the back-pointer
to the trunk — followed by canonical labels (`Spec`, `Design`,
`Plan`, `Depends on`, `Successor of`, `Tracking`, `Discussion`,
`Prior art`). Bidirectional links mean a tool that lands on
either file can navigate to the other without prior knowledge of
the conventions. See project-audit's references-block format
(project-audit skill, project-harness plugin) for the full format
and the discovery helper.
