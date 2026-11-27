# Rex Serial Chain Execution Contract (`P02` → `P13`)

**Date:** 2026-11-27  
**Spec:** [RS implementation roadmap design](../specs/2026-11-27-rs-implementation-roadmap-design.md)  
**Launcher:** `scripts/chain-next.sh` (regression-tested by `scripts/test-chain-next.sh`)

---

## 1. Purpose

Execute the phased `rs-launch-blueprint` roadmap (`P02` closeout, `P03`, `P04`–`P13`) as a **long-running, strictly serial chain of autonomous Antigravity (`agy`) sessions**, each running in its own fresh Rex tab inside the shared `rs-launch-blueprint` Rex session (`session:01a21ec6-66aa-79bc-8d80-05f4f293e0a3`), in an isolated git worktree branched from freshly fast-forwarded `origin/main`.

Each link owns exactly **one project (`P<NN>`)** from start through verified PR merge (`pr-merge-flow`), local `main` fast-forward, worktree cleanup, and launching the next link `P<NN+1>`.

---

## 2. Topology & Invocation

- **Rex session:** Always reuse the existing `rs-launch-blueprint` Rex session (`--session` passed explicitly by `scripts/chain-next.sh`, defaulting to `$REX_SESSION` or session labeled `rs-launch-blueprint`).
- **One tab per phase:** `rex window new -s <session_id> "<PNN>-<slug>" -c "<worktree>" --focus=false --shell=none --json -- "$SHELL" -ilc '"$@"; exec "$0" -il' "$SHELL" agy --dangerously-skip-permissions -i "<brief>"`.
  - Wrapping in `"$@"; exec "$0" -il` keeps the tab open at an interactive login shell after `agy` exits so full scrollback remains inspectable.
- **Worktree location:** `/Users/smorin/wt/rs-launch-blueprint/<branch-slug>` branched from `origin/main` (never commit directly to `/Users/smorin/c/rs-launch-blueprint` `main`).
- **Single source of truth:** `PROJECTS.md` on `origin/main`. `scripts/chain-next.sh` always selects the first incomplete (`[~]` or `[ ]`) project in `PROJECTS.md` whose `**Depends on:**` projects are all `[x]`.

---

## 3. Mandatory Per-Link Lifecycle (Inside Each `agy` Tab)

Every chained `agy` session MUST execute these 7 steps in strict order:

### Step 1 — Orient & Verify Inputs
1. Read `AGENTS.md`, this contract, `docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md`, and `projects/P<NN>-*.md`.
2. Read every `research/topics/*/DECISION.md` item cited by `projects/P<NN>-*.md` and the corresponding `py-launch-blueprint` reference files when parity details matter.
3. Confirm you are in the project's dedicated worktree (not `main`), branched from the latest `origin/main`.

### Step 2 — Execute Project Tasks (TDD First)
1. Execute `[P<NN>-TS##]` test/verification tasks before `[P<NN>-T##]` implementation tasks (unless the project explicitly declares `**TDD: not applicable**`).
2. Flip each task checkbox from `[ ]` to `[x]` in `projects/P<NN>-*.md` as it completes.
3. Keep all edits strictly within `P<NN>`'s declared scope. If you discover out-of-scope follow-up work, note it cleanly rather than widening the PR.
4. Any departure from an accepted `R##` decision MUST be justified in writing as an `OVERRIDE` (only apply pre-approved overrides such as `1a-A` GHCR publishing; halt if a new unapproved architectural override is required).

### Step 3 — Run All Local Verification Gates
Before pushing, every applicable gate MUST pass with zero errors:
- `bash scripts/check-shell.sh`
- `bash scripts/test-check-shell.sh`
- `bash scripts/test-chain-next.sh` (whenever `scripts/chain-next.sh` exists)
- `bash scripts/check-research-tree.sh --require-owner-review` (while research tree checks remain in CI)
- `bash scripts/test-check-research-tree.sh` (if any research or validation file changed)
- Once `P04` lands: `just check` (fmt, clippy, typecheck, deny, tests, and any new gates introduced by `P05`–`P13`), plus `blaze check` / `blaze test` on default workspace when applicable.
- Verify all 11 `project-audit` checks pass on `PROJECTS.md` and `projects/P<NN>-*.md`.

### Step 4 — Finalize Project Tracking & Open PR
1. Confirm every `TS` and `T` task in `projects/P<NN>-*.md` is `[x]` (and check off `Regression Test Status` if present, or update Status summary).
2. Flip `P<NN>`'s trunk glyph in `PROJECTS.md` to `[x]`.
3. Commit with Conventional Commits (`type(scope): description`, header <= 50 chars soft-line, body <= 72 chars).
4. Push the worktree branch and open a pull request targeting `main` with a Conventional Commits title (`gh pr create --base main ...`).

### Step 5 — Drive PR to Verified Merge (`pr-merge-flow`)
1. Run full **`pr-merge-flow` in `--auto` mode** against the open PR:
   - Wait for CI checks and reviewer bots (bounded polling, 20–30s intervals).
   - Triage every review thread in a live ledger: verify claims empirically, fix valid in-scope bugs, refute invalid claims with evidence, decline nits below the value floor, defer out-of-scope findings. Never merge over an unresolved thread.
   - If CI fails, diagnose and repair via `ci-fix` discipline, push, and re-run bot-wait + review collection.
   - Merge using **`--merge`** with `--match-head-commit "$REVIEWED_HEAD"` (**NEVER `--squash`** — repository ruleset `merge-methods: no squash` forbids squash merges).
   - Verify `gh pr view <pr> --json state,mergeCommit` reports `state: MERGED`.

### Step 6 — Post-Merge Sync & Cleanup
1. `cd /Users/smorin/c/rs-launch-blueprint` (exit the worktree directory before removing it).
2. Verify main checkout is clean (`git status --porcelain` empty) and on `main`, then fast-forward:
   ```bash
   git pull --ff-only origin main
   ```
3. Verify the PR's merge commit is now an ancestor of `HEAD` (`git merge-base --is-ancestor "$MERGE_SHA" HEAD`) and `PROJECTS.md` shows `- [x] **P<NN>**`.
4. Remove the merged worktree and delete the merged local and remote branches:
   ```bash
   git worktree remove "$WORKTREE_PATH"
   git branch -d "$BRANCH"
   git push origin --delete "$BRANCH" || true
   ```

### Step 7 — Advance Chain to `P<NN+1>`
ONLY AFTER Step 6 succeeds completely:
```bash
bash /Users/smorin/c/rs-launch-blueprint/scripts/chain-next.sh \
  --repo /Users/smorin/c/rs-launch-blueprint \
  --session "${REX_SESSION:-session:01a21ec6-66aa-79bc-8d80-05f4f293e0a3}"
```
- If another incomplete project exists and `.chain-pause` is absent, `chain-next.sh` creates the next worktree and spawns the next Rex tab automatically.
- If `P13` just merged (no remaining `[~]`/`[ ]` projects), `chain-next.sh` reports `COMPLETE` and exits `0`.

---

## 4. Safety Rails, Pause Controls & Hard-Stop Policy

### Pausing & Resuming
- **Pause cleanly between phases:** `touch /Users/smorin/c/rs-launch-blueprint/.chain-pause`
  - The currently running phase finishes and merges cleanly, then stops before spawning the next tab.
- **Resume:** `rm -f /Users/smorin/c/rs-launch-blueprint/.chain-pause && bash /Users/smorin/c/rs-launch-blueprint/scripts/chain-next.sh`

### Hard-Stop Conditions (DO NOT merge and DO NOT call `chain-next.sh`)
Halt immediately, write a concise blocker handoff to `docs/handoffs/YYYY-MM-DD-p<NN>-blocker.md` (untracked or in the worktree), and print a clear final summary if any of the following occur:
1. Unrecoverable CI failure after bounded repair attempts (max 3 repair pushes per failure class).
2. `pr-merge-flow` encounters an escalated architectural review thread or exceeds its convergence bound (`4` review cycles or 2 consecutive ratcheted waves).
3. A required check or workflow fails due to a missing human-only GitHub repository setting/secret that cannot be credential-preflight gated.
4. Implementation reveals a genuine contradiction requiring a **new unapproved `OVERRIDE`** against an accepted `R##` decision or owner-locked parameter.
5. `git pull --ff-only origin main` fails because `main` diverged unexpectedly.

### Credential & External Service Policy
- Workflows added in `P10`–`P13` that rely on optional secrets (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `META_MUSE_CI_API_KEY`, `CRATES_IO_TOKEN`, GitHub App keys) MUST use credential-preflight skip-gating (`R18`, `R86`) so the chain never stalls on unprovisioned secrets.
- One-time human GitHub settings (branch protection ruleset for `ci-ok`, GitHub Pages source = GitHub Actions, crates.io trusted publisher, GHCR package visibility, repository secrets) are collected cleanly in `docs/PROJECT_SETUP.md` (`P12`) and reported at chain completion.
