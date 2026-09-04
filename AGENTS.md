# AGENTS.md — rs-launch-blueprint charter

Read, in order: `README.md`, `docs/port/README.md` (verdict vocabulary),
`research/CLAUDE.md` (research index) before touching anything.

- Research engineering principles and ecosystem best practices first (spec §2,
  owner amendment A5). Existing py/ts implementations are evidence, not winners
  by default. Preserve the intended outcomes using justified native designs.
- Track departures from recorded patterns as `OVERRIDE (OV-nn)` with
  `**Argument:**` and `**Options:**`; agreement alone is not evidence of fitness.
- Never assign a verdict from memory; cite the files in both source repos.
- Run `scripts/check-research-tree.sh` before opening a PR.
- Work in a worktree branched from `origin/main`; never commit to `main`.
