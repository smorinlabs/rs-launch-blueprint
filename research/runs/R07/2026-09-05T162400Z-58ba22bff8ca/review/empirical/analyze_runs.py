#!/usr/bin/env python3
"""R07 empirical check, push-range analysis of py-launch-blueprint's real runs.

GitHub evaluates `paths-ignore` over the changed files of the whole push
(`before..after`), not per commit. Merges that land seconds apart are pushed
to `main` as one range and yield one run whose head_sha is the last commit.
So each `push` run is modelled as the range of first-parent commits after the
previous run's head up to and including its own head, and the filter is
evaluated over the union of those commits' first-parent diffs.

  A2'  no run's range is entirely ignored files (the loop guard never leaked);
  A1'  every first-parent commit with a non-ignored diff is inside some run's
       range (every qualifying merge produced a run).

Only commits after the guard reached `main` count (the first first-parent
commit whose workflow file contains `paths-ignore`, found by the script).
Before it the workflow had no paths-ignore, so bot merges firing runs there
is the loop the guard exists to prevent, reported separately.

Usage: analyze_runs.py <runs.json> <py-verdicts.json> <repo-dir>
"""

import json
import subprocess
import sys

IGNORE = {"CONTRIBUTORS.md", ".contributors.jsonl"}


def git(repo, *args):
    return subprocess.run(["git", "-C", repo, *args], check=True, capture_output=True, text=True).stdout


def files_of(repo, sha):
    return {f for f in git(repo, "diff", "--name-only", f"{sha}^1", sha).splitlines() if f}


def main():
    runs_path, verdicts_path, repo = sys.argv[1:4]
    runs = [r for r in json.load(open(runs_path)) if r["event"] == "push"]
    commits = json.load(open(verdicts_path))["commits"]  # newest first
    commits = list(reversed(commits))  # oldest first
    idx = {c["sha"]: i for i, c in enumerate(commits)}
    guard_i = next(
        i for i, c in enumerate(commits)
        if "paths-ignore" in subprocess.run(
            ["git", "-C", repo, "show", f"{c['sha']}:.github/workflows/update-contributors.yml"],
            capture_output=True, text=True).stdout
    )
    guard = commits[guard_i]["sha"]
    run_heads = {r["head_sha"]: r for r in runs if r["head_sha"] in idx}
    print(f"push runs with head on the pinned first-parent line: {len(run_heads)} of {len(runs)}")

    # Pre-guard: bot merges that fired a run (the loop without a guard).
    pre = [c for c in commits[:guard_i] if c["verdict"] == "SKIP" and c["sha"] in run_heads]
    print(f"before the guard ({guard[:10]}, {commits[guard_i]['date']}): bot-only commits that fired a push run: {len(pre)}")
    for c in pre:
        print(f"  {c['sha'][:10]} {c['date']} {c['subject']}")

    # Post-guard ranges.
    post = commits[guard_i + 1:]
    ranges = []
    cur = []
    for c in post:
        cur.append(c)
        if c["sha"] in run_heads:
            ranges.append(cur)
            cur = []
    tail = cur
    print(f"after the guard: first-parent commits {len(post)}, push runs {len(ranges)}, commits after the last run {len(tail)}")
    batched = [r for r in ranges if len(r) > 1]
    print(f"runs whose push range holds more than one commit (batched merges): {len(batched)}")
    leaked = []
    for rng in ranges:
        union = set()
        for c in rng:
            union |= files_of(repo, c["sha"])
        if union and union <= IGNORE:
            leaked.append(rng)
    print(f"A2': runs whose whole push range is ignored files only: {len(leaked)} (expected 0)")
    for rng in leaked:
        print("  LEAK " + ", ".join(f"{c['sha'][:10]} {c['subject']}" for c in rng))
    bot_in_ranges = [c for rng in ranges for c in rng if c["verdict"] == "SKIP"]
    bot_as_head = [c for c in bot_in_ranges if c["sha"] in run_heads]
    print(f"bot-only commits after the guard: {sum(1 for c in post if c['verdict'] == 'SKIP')}; "
          f"as a run head: {len(bot_as_head)} (each shares its push with a non-ignored commit, listed):")
    for c in bot_as_head:
        rng = next(r for r in ranges if r[-1]["sha"] == c["sha"])
        others = [x for x in rng if x["sha"] != c["sha"]]
        print(f"  {c['sha'][:10]} {c['subject']} <- pushed with " + ", ".join(f"{x['sha'][:10]} {x['subject']}" for x in others))
    uncovered = [c for c in tail if c["verdict"] == "RUN"]
    print(f"A1': qualifying commits not inside any run's range: {len(uncovered)} (expected 0; the tail after the newest retained run is the only place one could hide)")
    for c in uncovered:
        print(f"  {c['sha'][:10]} {c['date']} {c['subject']}")


if __name__ == "__main__":
    main()
