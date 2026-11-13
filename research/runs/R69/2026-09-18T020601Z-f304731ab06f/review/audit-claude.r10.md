actor: audit-claude-s32-r69r10
model: claude-opus-5-5
family: anthropic
decision-sha256: d34ab6e8339b6f416a510d070ee54daca38a9086a901a6bfbb9df0517f7fce0a
verdict: reject
unresolved-findings:
  1. EF-1 — `supersession-check-r10.sh` exits 1 on the committed tree at HEAD (details below).

# R69 revision 10 — empirical audit (round 10, Claude seat)

**Scope.** Execution truth and evidence support for
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` at revision 10. I read the
revision-10 entry above the supersession heading and `research/RUNBOOK.md` section 5. I read the
preserved revision-9 bytes below the heading only to verify what the supersession check
asserts. I did not open any `review/audit-*.md` of any seat or revision, anything under
`research/topics/69-*/raw/`, or any snapshot file named `R69-r*-snapshot.md`. I made no git
write, ran no `scripts/research_runner.py` command and called no paid API. All fresh output
went to `/tmp/r69a10/`.

**Environment.** macOS (Darwin 25.4.0, arm64). `/usr/bin/grep` prints
`grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`. `shellcheck` 0.11.0 is at
`/opt/homebrew/bin/shellcheck`. The working tree is at HEAD `e0b0d1c1`. The decision's own
commit is `c6b7d2b1` (2026-09-17 19:33 -0700). `git show c6b7d2b1:<decision>`, `c76584a6` and
HEAD all hash to `d34ab6e8…`, so the decision bytes are unchanged since that commit.

## Hash gate

`shasum -a 256 review/DECISION.md` →
`d34ab6e8339b6f416a510d070ee54daca38a9086a901a6bfbb9df0517f7fce0a`. This equals the expected
value, so the audit proceeded.

## Reruns

The decision's stated comparison rule (revision-10 note): three of the four recorded diffs are
empty; the fourth, `supersession-check-r10.sh`'s archive leg, differs only by S10a/S10b/S10c
SKIP by name, the absent progress line, and the summary `PASS: 20 FAIL: 0 SKIP: 3`. I applied
that rule as written.

Neither r10 script invokes another script; I read both in full. The carried scripts cited in
`## Empirical check` are earlier revisions' evidence and were not rerun as current, as the
brief directs.

### `owned-value-check-r10.sh` — reproduces in every leg

| Leg | Command (from the named cwd) | Exit | Summary | Comparison |
|---|---|---|---|---|
| in place, run 1 | `bash <E>/owned-value-check-r10.sh` (repo root) | 0 | `CHECKS RUN: 53 PASS: 53 FAIL: 0 SKIP: 0` | `cmp` against `owned-value-check-r10.log`: clean |
| in place, run 2 | same | 0 | same | `cmp`: clean |
| rerun diff | `diff <committed log> <run 1>` | — | — | empty; `cmp` against the committed empty `owned-value-check-r10-rerun.diff`: identical |
| archive of `c6b7d2b1` | `git archive c6b7d2b1 \| tar -x`, then the same command in the extraction | 0 | `53 / 53 / 0 / 0` | diff empty; identical to committed empty `owned-value-check-r10-archive.diff` |
| archive of HEAD | same with `HEAD` | 0 | `53 / 53 / 0 / 0` | diff empty; identical to committed empty diff |

`<E>` is `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/evidence`.

### `supersession-check-r10.sh` — reproduces at the decision's commit, fails at HEAD

| Leg | Tree | Exit | Summary | Comparison |
|---|---|---|---|---|
| in place, runs 1 and 2 | working tree at HEAD | **1** | `CHECKS RUN: 23 PASS: 20 FAIL: 3 SKIP: 0` | `cmp` against `supersession-check-r10.log`: `differ: char 2166, line 36`; rerun diff is **not** empty |
| archive | `git archive HEAD` extraction | **1** | `CHECKS RUN: 23 PASS: 17 FAIL: 3 SKIP: 3` | not the designed difference |
| archive | `git archive c6b7d2b1` extraction | 0 | `CHECKS RUN: 23 PASS: 20 FAIL: 0 SKIP: 3` | exactly the designed difference (below) |
| in place, equivalent | the `c6b7d2b1` extraction with a `.git` file `gitdir: <this worktree's git dir>` added, removed afterwards | 0 | `CHECKS RUN: 23 PASS: 23 FAIL: 0 SKIP: 0` | `cmp` against `supersession-check-r10.log`: **clean** |

The `c6b7d2b1` archive leg differs from the committed log only in these lines:

```text
46,49c46,48
<   carried evidence scripts compared: 7
< PASS S10a: carried evidence scripts == 7
< PASS S10b: carried scripts with no blob at HEAD's source path == 0
< PASS S10c: carried scripts whose bytes differ from HEAD's blob == 0
---
> SKIP S10a: no .git in this tree (a git archive extraction); git blob comparison not possible
> SKIP S10b: no .git in this tree (a git archive extraction); git blob comparison not possible
> SKIP S10c: no .git in this tree (a git archive extraction); git blob comparison not possible
52c51
< CHECKS RUN: 23 PASS: 23 FAIL: 0 SKIP: 0
---
> CHECKS RUN: 23 PASS: 20 FAIL: 0 SKIP: 3
```

The committed `supersession-check-r10-archive.diff` is in `diff -u` format with scratch paths
and timestamps in its header; mine is plain `diff`. I therefore compared **hunk content**, not
bytes: the removed and added lines are the same eight lines in both.

The in-place leg at HEAD differs from the committed log as follows (first differing line is
36):

```text
36,37c36,38
<   carried files compared: 309
< PASS S8a: files this run carried forward == 309
---
>   DIFFERS review/audit-fable.md
>   carried files compared: 310
> FAIL S8a: files this run carried forward: expected 309, got 310
39c40
< PASS S8c: carried files differing from the publishing run == 0
---
> FAIL S8c: carried files differing from the publishing run: expected 0, got 1
43c44
< PASS S9-audit-fable.md: review/audit-fable.md is absent; revision 10 gets fresh audits
---
> FAIL S9-audit-fable.md: review/audit-fable.md is present; it binds revision 9 and must not be carried
52c53
< CHECKS RUN: 23 PASS: 23 FAIL: 0 SKIP: 0
---
> CHECKS RUN: 23 PASS: 20 FAIL: 3 SKIP: 0
```

**Cause, identified without opening the file.** `git log -- <run>` shows that
`review/audit-fable.md` was added by `c76584a6` (subject
`chore(research): R69 revision 10 judgment audit — approve (round 10)`), after the decision's
commit `c6b7d2b1`. Its sha256 is `824870fc…`. The round-9 copy in the publishing run
`research/runs/R69/2026-09-17T014646Z-d5b96f477092/review/audit-fable.md` hashes to
`d6a20bd6…`. The file is therefore the fresh round-10 judgment audit, not a carried round-9
audit. I established this from git metadata and hashes only; I did not read the file.

## Findings

**EF-1 — the supersession check cannot pass once the revision-10 audits exist.**

- **Failed claim** (revision-10 note, lines 123–126): "`review/evidence/supersession-check-r10.sh`
  re-establishes that on every run — check `S8c` compares all 309 against the publishing run's
  copies". The note's results table (line 134) also records the script as
  "**exit 0**, `CHECKS RUN: 23 PASS: 23 FAIL: 0 SKIP: 0`". The same note (lines 117–121) says
  that "revision 10 gets fresh" audits.
- **Evidence.** On the committed tree at HEAD the script exits **1** with
  `CHECKS RUN: 23 PASS: 20 FAIL: 3 SKIP: 0`. The failing checks are
  `FAIL S8a: files this run carried forward: expected 309, got 310`,
  `FAIL S8c: carried files differing from the publishing run: expected 0, got 1` and
  `FAIL S9-audit-fable.md: review/audit-fable.md is present; it binds revision 9 and must not
  be carried`. The script reproduces 23/23 byte-identically on the decision's own commit
  `c6b7d2b1`, so the recorded log was true when written. The defect is structural:
  - Section 8 walks every file under `raw/` and `review/`. It excludes only `DECISION.md`,
    `CARRIED-FROM.md` and `evidence/*-r10*`. Any audit file written into `review/` is counted as
    "carried" and reported as `DIFFERS` or `NOT IN SOURCE`.
  - S9 tests whether `review/audit-fable.md` and `review/audit-codex.md` are **present**. It
    does not test whether they are byte-identical to the round-9 copies. It therefore cannot
    tell the fresh revision-10 audit the note calls for from a carried revision-9 audit.
  - The same walk includes `review/identities.json`. The note (line 121) says its `audits.*`
    entries "are replaced when the revision-10 audits exist". That replacement will trip S8c
    in the same way.
  - The failure grows as the acceptance flow proceeds; see the post-write rerun below.
- **Repair.** In `supersession-check-r10.sh` (or an `-r10b` successor), build the section-8
  file set from the 309 rows of `review/CARRIED-FROM.md` instead of from the live directory.
  That makes the count literally "the files this run claims to have carried", and it stops
  audit files and a replaced `identities.json` from entering the comparison. Change S9 to
  assert that any present `review/audit-codex.md` or `review/audit-fable.md` is byte-**different**
  from the publishing run's round-9 copy, instead of asserting absence. Rerun the script in place and from an archive extraction.
  Replace `supersession-check-r10.log`, `supersession-check-r10-rerun.diff` and
  `supersession-check-r10-archive.diff`. Update the revision-10 note's results table, and its
  "on every run" sentence if the repaired script still cannot honour it. This changes the
  decision's bytes, so both audit seats must review the new revision.

## Verified at source (no finding)

| Claim | How verified | Result |
|---|---|---|
| Owned line sha256 `60558d1a…` (V2) | `/usr/bin/grep -m1 -F -- '- owns web-extra-surface = ' <decision> \| shasum -a 256` | `60558d1ab01ae3f7efd60cda1cd3cbc24f6a6114880deb3286940b6bb06f7346` |
| Only the six clauses moved | Applied the eight superseded→new substitutions from the note's table to the revision-9 line in `research/topics/69-web-framework-stack/DECISION.md` (each occurs exactly once) | Result equals the revision-10 line byte-for-byte |
| The `CONFLICT:` quote at lines 38–48 is R02's line word for word | Stripped `> `, joined the lines with spaces, `cmp` against R02's `CONFLICT: R69 web-extra-surface` line | identical |
| R02 `CONFLICT:` line unchanged since the decision's commit | sha256 of that line at `c6b7d2b1` and in the working tree | both `c66211f0…` (R02's run decision itself moved to revision 2 since; the line did not) |
| R02 accepted at revision 1, sha `78788f7f…`, on 2026-09-17 | `git log -S` on `docs/port/OWNER-ACCEPTANCES.md` → `c07ac61f` (2026-09-17 15:50 -0700); the row at `c6b7d2b1` reads `R02 \| 1 \| 78788f7f… \| accept \| 2026-09-17`; R02's decision at `c6b7d2b1` hashes to `78788f7f…` | confirmed (re-bound to revision 2 on 2026-09-18 by `3ac0b5e1`, after this decision) |
| Five `- assumes` lines equal the registry | Own extraction and `diff` against `docs/port/PARAMETERS.md` in the working tree (which carries one uncommitted change) and, via V7 in the archive legs, against the committed file | empty in both |
| Tail is the published revision-9 bytes | `wc -c` of the topic decision → 228,667; `tail -c 228667 <decision> \| shasum -a 256` | `d4507f5b…`, equal to the topic file and to `git show 28909ac:<topic>` |
| Supersession heading once, nothing above it | `/usr/bin/grep -n -x -F` → line 2685 only; 8 occurrences in the file; 0 in lines 1–2684 | matches S2a/S2b/S2c and V1a |
| Seven carried `.sh` files | `ls <E>/*.sh`, excluding `r10` | 7 |
| shellcheck-clean with no directive | `shellcheck` 0.11.0 on both r10 scripts; count of `shellcheck disable` | exit 0; 0 and 0 |
| Revision 9 published at `28909ac` "on 2026-09-17" | `git log -1 28909ac` → 2026-09-16 20:38:04 -0700, which is 2026-09-17 03:38 UTC | consistent with the UTC date `OWNER-ACCEPTANCES.md` also uses; not a finding |

## Post-write rerun

After this file was written into `review/`, I reran `bash <E>/supersession-check-r10.sh` from
the repository root. It exited **1**, and this file became a fourth failure:

```text
  NOT IN SOURCE review/audit-claude.r10.md
  DIFFERS review/audit-fable.md
  carried files compared: 311
FAIL S8a: files this run carried forward: expected 309, got 311
FAIL S8b: carried files with no counterpart in the publishing run: expected 0, got 1
FAIL S8c: carried files differing from the publishing run: expected 0, got 1
FAIL S9-audit-fable.md: review/audit-fable.md is present; it binds revision 9 and must not be carried
CHECKS RUN: 23 PASS: 19 FAIL: 4 SKIP: 0
```

Every later audit or `identities.json` update adds to this count until the EF-1 repair lands.
