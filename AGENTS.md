# AGENTS.md — rs-launch-blueprint charter

`AGENTS.md` is the single canonical AI-assistant instruction hub for this
repository (read directly by Cursor, Devin, Codex, and Antigravity, and
imported via `@AGENTS.md` in `CLAUDE.md`; no `.cursor/`, `.windsurf/`, or
`.devin/` rule directories are committed per `R43`).

Read, in order: `README.md`, `docs/port/README.md` (verdict vocabulary),
`research/CLAUDE.md` (research index) before touching anything.

## Governing Principles

- Research engineering principles and ecosystem best practices first (spec §2,
  owner amendment A5). Existing py/ts implementations are evidence, not winners
  by default. Preserve the intended outcomes using justified native designs.
- Track departures from recorded patterns as `OVERRIDE (OV-nn)` with
  `**Argument:**` and `**Options:**`; agreement alone is not evidence of fitness.
- Never assign a verdict from memory; cite the files in both source repos.
- Work in a worktree branched from `origin/main`; never commit to `main`.
- Returning to P01/P02 research maintenance after an interruption, start with
  `uv run --offline --no-project --no-python-downloads --no-cache python3 scripts/research_scan.py --todo`.
  Run `bash scripts/check-research-tree.sh --require-owner-review` before opening a PR.

## Canonical Development Commands (`just`)

Two-level setup (`R42`): `Makefile` is Level 1 bootstrap (`rustup` + `just`);
`Justfile` is Level 2 for every day-to-day task.

- `make bootstrap` — install Level 1 base toolchain (`rustup` + `just`)
- `make check` / `make hook-check` — verify base toolchain / report-only git-hook readiness
- `just setup` — activate pinned toolchain, install declared dev tools, wire `lefthook` hooks, and configure `.gitmessage`
- `just check-deps` — verify all pinned dev tools and `rustup` components
- `just check` — run all read-only quality gates in parallel (`format-check`, `check-files`, `security`, `check-hygiene`, `check-shell`, `lint`, `typecheck`, `test`, `deny`)
- `just format` / `just format-files` — format Rust (`cargo fmt`) and non-code files (`dprint fmt`)
- `just security` — run `ast-grep` security rule self-tests and full-tree scan (`R31`)
- `just check-hygiene` — run `editorconfig-checker`, `ryl`, `typos`, and `actionlint` (`R40`)
- `just check-large-files` / `just check-lockfile` — run the 1 MiB blob guard (`R14`) / `Cargo.lock` freshness guard (`R41`)
- `just hooks-install` / `just hooks-run` — wire `lefthook` hooks / run pre-commit suite over all files
- `just docs-build` / `just docs-dev` / `just docs-clean` — build, live-serve, or clean the `mdBook` documentation site (`R81`)
- `just docs-check` / `just docs-api` — verify offline Markdown links (`lychee`) and build strict rustdoc API docs across all features (`R82`)
- `just blaze-check` / `just blaze-test` / `just blaze-status` — opt-in Blaze local edit-loop accelerator (automatic Cargo fallback)
- `just debug-info` — print environment, toolchain, and workspace diagnostics
- `just --list` — list every recipe and alias

## `Justfile` Conventions (`R42`, `R43`)

- Invoke `cargo-<sub>` executables (including `rustfmt` and `clippy`) as `cargo <sub>` and all other dev tools as bare executables on `PATH`. Never add provisioner prefixes (`mise exec`, `cargo bin`, `uv run`) or Cargo `[alias]` entries.
- Keep one authoritative tool table in `Justfile`; every recipe carries a `[group(...)]` attribute and concise comment.
- Keep `[parallel] @check` strictly read-only (`format-check` first, `check-files` second, ahead of compile-heavy legs).
- Opt-in fixers (`format`, `lint-fix`) stay separate from check-only gates.

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
