# Standing rules for every P02 revision agent (2026-09-13)

Working directory: /Users/stevemorin/c/rs-launch-blueprint-p02-plan
This is a git worktree on branch `research/p02-execution`. TEN agents are working
in it concurrently. Every rule below exists because it was broken before.

## Read first, in this order
1. `AGENTS.md`
2. `docs/superpowers/plans/p02-roles/synthesizer.md` — your role contract
3. Your run's `inputs/prompt.md` (the binding prompt)
4. Your run's current `review/DECISION.md`
5. Your run's `review/audit-codex*.md` and `review/audit-fable*.md`
6. Every report in your run's `raw/`
7. `docs/port/PARAMETERS.md`

## Git discipline — ALL of these are hard rules
- Commit ONLY your own item's paths: `git add research/runs/<ITEM>/...`.
  NEVER `git add -A`, `git add -a`, `git add .`, or `git commit -a`.
- NEVER `git commit --amend`. An amend by one agent rewrote another agent's
  commit in this worktree already. There is no exception.
- NEVER rebase, reset, stash, checkout a branch, or create a worktree.
- If git reports `index.lock` exists, wait 10 seconds and retry ONCE. If it
  fails again, stop and report — another agent holds it.
- Commit messages: Conventional Commits, via `git commit -F -` with a heredoc.
  Unescaped quotes in `-m` broke a commit here before.

## Files you must NOT touch
- `docs/planning/p02/execution-ledger.md` (controller records)
- `research/CLAUDE.md`, `docs/port/PARAMETERS.md`, `docs/port/OWNER-REVIEW.md`
- Anything under `research/topics/` (the publisher publishes; you may READ)
- Any other item's run directory

## The owner's licence ruling — the reason most of you are here
OWNER RULING, 2026-09-12 (Q4 as superseded by Q7.B):

> We don't need to check the licensing for any tool we use. Zero license check.
> That accounts for other tools and libraries we're including. The license we
> have only applies to the source code in the repo itself directly, not anything
> it includes or depends on.

Q7.B extended this knowingly to crates COMPILED INTO the shipped artifact, after
the owner was shown that linked crates' terms travel downstream. Fitness gate 1
("license compatible with `MIT OR Apache-2.0`") is struck from every item's
evaluation.

**What the ruling does NOT touch:**
- The repository's OWN declared licence expression (`license = MIT OR Apache-2.0`)
  and per-file licence headers. That is this repo's own source. It stands.
- A rule forbidding third-party copyleft files from being COMMITTED INTO this
  repository. Those files would then be this repo's own source.
- A tool's USAGE TERMS restricting where it may lawfully run. That is a
  functional availability constraint, not a licence-compatibility check.
- An attribution/distribution notice owed on shipped CONTENT. That is a
  distribution duty, not a compatibility check.

**How to record gate 1 — do this, do not delete the row.** The binding prompts
still contain gate 1 and their sha256 hashes are cited by published acceptance
records, so the prompts cannot be edited. Where your decision reports gate 1,
record it as:

`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`

with the reason. The prompt itself says to state `inapplicable` and the reason
rather than omitting a gate silently. Deleting the row makes the decision look
like it skipped a gate its own prompt required.

## Mechanical enumeration before editing — required, and it has failed before
Before you edit anything, `grep -n` your decision for EVERY location touching
the thing you are changing (licence, copyleft, AGPL, GPL, MPL, gate 1, permissive,
patent grant, as applicable). Write the line-number list into your report. Edit
each one. If you deliberately leave one byte-identical, say which and why.
A previous revision edited six of seven locations and only caught it by enumerating.

## Parameters — publication fails on this
`- owns <param> = <value>` and every `- assumes <param> = <value>` line must stay
BYTE-IDENTICAL to the current revision unless your task message says a consumed
value changed. The validator reads everything after `= ` as the value and compares
byte-for-byte with `docs/port/PARAMETERS.md`: bare value, no backticks, no
citation, no commentary on that line. Run a diff of those lines old-vs-new and
paste it in your report.

## Evidence rules
- `set -o pipefail` at the top of every evidence script. A pipeline reports its
  LAST command's status, so a failing check can print success. One decision was
  rejected because `git show <bad path> | head` printed `exit=0`.
- A check that cannot fail is not evidence. Assert on CONTENT, not just exit code.
- If you claim a log reproduces, RERUN it and DIFF it. Do not assert reproduction.
- Evidence scripts must still be rerunnable AFTER your revision is committed
  (R60 was rejected for exactly this: scripts that only worked pre-commit).
- **No personal email addresses** in any new script, User-Agent header, or log.
  Use the repository URL `https://github.com/smorinlabs/rs-launch-blueprint`.
  R42 revision 7 set this precedent.

## Honesty contract
If the licence ruling does NOT change your recommendation, say so plainly and
make only the reasoning repair. If it DOES change it, say that too. If striking
gate 1 leaves a question genuinely unanswered, answer it with real research —
do not paper over it. Report every correction you make beyond your assigned
findings rather than fixing it quietly.

## When you finish
Report to the controller: the new revision number, the decision's sha256, the
enumeration line-list, the parameter-line diff, what changed, what did NOT
change and why, anything you corrected beyond your brief, and anything you
could not verify.
