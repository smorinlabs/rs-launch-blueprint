#!/usr/bin/env python3
"""R07 empirical check: evaluate the recommended workflow's `on.push.paths-ignore`
filter against the real first-parent history of the two pinned source repos.

Rule implemented (GitHub workflow-syntax reference, retrieved 2026-09-08):
  "When all the path names match patterns in paths-ignore, the workflow will
   not run. If any path names do not match patterns in paths-ignore, even if
   some path names match the patterns, the workflow will run."
Pattern syntax implemented: `*` (no `/`), `**` (anything), `?`; a pattern must
match the whole path. Negation (`!`) is not implemented; the fixture does not
use it and the script refuses such a pattern.

Changed-file set per commit: `git diff --name-only <sha>^1 <sha>` (the
first-parent diff), because a PR merge to main is pushed as one merge commit
and GitHub compares the push's before/after. `git show --name-only` prints an
empty list for clean true-merge commits and would vacuously skip them, so it
is not used. Root commits use `git show`.

Usage: paths_filter.py <workflow.yml> <repo-dir> <pinned-sha> <out.json> [--since ISO]
"""

import argparse
import json
import re
import subprocess

import yaml


def pattern_to_regex(pat: str) -> re.Pattern:
    if pat.startswith("!"):
        raise SystemExit(f"negation pattern not supported: {pat}")
    out = []
    i = 0
    while i < len(pat):
        c = pat[i]
        if pat.startswith("**", i):
            out.append(".*")
            i += 2
            continue
        if c == "*":
            out.append("[^/]*")
        elif c == "?":
            out.append("[^/]")
        else:
            out.append(re.escape(c))
        i += 1
    return re.compile("^" + "".join(out) + "$")


def git(repo: str, *args: str) -> str:
    return subprocess.run(
        ["git", "-C", repo, *args], check=True, capture_output=True, text=True
    ).stdout


def changed_files(repo: str, sha: str) -> list[str]:
    parents = git(repo, "rev-list", "--parents", "-n", "1", sha).split()[1:]
    if not parents:
        out = git(repo, "show", "--name-only", "--format=", sha)
    else:
        out = git(repo, "diff", "--name-only", f"{sha}^1", sha)
    return [line for line in out.splitlines() if line]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("workflow")
    ap.add_argument("repo")
    ap.add_argument("pinned")
    ap.add_argument("json_out")
    ap.add_argument("--since", default=None)
    a = ap.parse_args()
    workflow, repo, pinned, since, json_out = a.workflow, a.repo, a.pinned, a.since, a.json_out

    with open(workflow) as fh:
        doc = yaml.safe_load(fh)
    # PyYAML parses the bare key `on` as boolean True (YAML 1.1).
    on = doc.get("on", doc.get(True))
    ignore = on["push"]["paths-ignore"]
    branches = on["push"]["branches"]
    regexes = [pattern_to_regex(p) for p in ignore]

    log_args = ["log", "--first-parent", "--format=%H%x09%cI%x09%s", pinned]
    if since:
        log_args.insert(3, f"--since={since}")
    rows = []
    for line in git(repo, *log_args).splitlines():
        sha, date, subject = line.split("\t", 2)
        files = changed_files(repo, sha)
        matched = [f for f in files if any(r.match(f) for r in regexes)]
        if not files:
            verdict = "EMPTY-DIFF"
        elif len(matched) == len(files):
            verdict = "SKIP"
        else:
            verdict = "RUN"
        rows.append(
            {
                "sha": sha,
                "date": date,
                "subject": subject,
                "files": len(files),
                "ignored_files": len(matched),
                "verdict": verdict,
            }
        )

    counts = {}
    for r in rows:
        counts[r["verdict"]] = counts.get(r["verdict"], 0) + 1

    print(f"workflow: {workflow}")
    print(f"repo: {repo} @ {pinned}" + (f" (since {since})" if since else ""))
    print(f"on.push.branches: {branches}")
    print(f"on.push.paths-ignore: {ignore}")
    print(f"first-parent commits evaluated: {len(rows)}")
    print(f"verdict counts: {json.dumps(counts, sort_keys=True)}")
    print("SKIP and EMPTY-DIFF commits (would NOT trigger the workflow):")
    for r in rows:
        if r["verdict"] != "RUN":
            print(
                f"  {r['verdict']:10} {r['sha'][:10]} {r['date'][:10]} "
                f"files={r['files']} ignored={r['ignored_files']} {r['subject']}"
            )
    print("sample RUN commits (would trigger the workflow):")
    for r in [r for r in rows if r["verdict"] == "RUN"][:5]:
        print(
            f"  {r['verdict']:10} {r['sha'][:10]} {r['date'][:10]} "
            f"files={r['files']} ignored={r['ignored_files']} {r['subject']}"
        )
    with open(json_out, "w") as fh:
        json.dump({"counts": counts, "commits": rows}, fh, indent=1)
    print(f"json: {json_out}")


if __name__ == "__main__":
    main()
