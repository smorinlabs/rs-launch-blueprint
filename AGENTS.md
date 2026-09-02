# AGENTS.md — rs-launch-blueprint charter

Read, in order: `README.md`, `docs/port/README.md` (verdict vocabulary),
`research/CLAUDE.md` (research index) before touching anything.

- Presumption of reuse: py and ts agreement is the default. Overrides are
  labeled `OVERRIDE (OV-nn)` with `**Argument:**` and `**Options:**`.
- Never assign a verdict from memory; cite the files in both source repos.
- Run `scripts/check-research-tree.sh` before opening a PR.
- Work in a worktree branched from `origin/main`; never commit to `main`.
