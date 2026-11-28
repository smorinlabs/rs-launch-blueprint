# `new-rust-project` Bootstrap Skill

This directory contains [`SKILL.md`](SKILL.md), the agent skill for creating and
stamping a new Rust repository from `smorinlabs/rs-launch-blueprint` with
Template Press.

## Project-scoped usage

Inside a checkout of `smorinlabs/rs-launch-blueprint`, the skill is already
discoverable by both Claude Code (`.claude/skills/new-rust-project`) and
Codex / agent harnesses (`.agents/skills/new-rust-project`).

## Global (user-scoped) installation

To invoke `new-rust-project` from any directory on your machine without opening
the blueprint repository first, symlink it into your user-level skill
directories from a local clone of `smorinlabs/rs-launch-blueprint`:

```bash
BLUEPRINT_DIR="${HOME}/c/rs-launch-blueprint"

mkdir -p ~/.claude/skills ~/.agents/skills
ln -sfn "${BLUEPRINT_DIR}/.claude/skills/new-rust-project" ~/.claude/skills/new-rust-project
ln -sfn "${BLUEPRINT_DIR}/.claude/skills/new-rust-project" ~/.agents/skills/new-rust-project
```

Verify both symlinks resolve to `SKILL.md`:

```bash
test -f ~/.claude/skills/new-rust-project/SKILL.md
test -f ~/.agents/skills/new-rust-project/SKILL.md
```

## After stamping

When Template Press stamps a child repository, `SKILL.md` is retired so agents
working inside the child repository never re-run initialization. Complete
human-only repository settings by following
[`docs/PROJECT_SETUP.md`](../../../docs/PROJECT_SETUP.md).
