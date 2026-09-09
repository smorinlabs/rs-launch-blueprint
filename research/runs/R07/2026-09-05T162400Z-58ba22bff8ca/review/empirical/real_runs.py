#!/usr/bin/env python3
"""R07 empirical check, real-event cross-check.

Reads the GitHub Actions run history of py-launch-blueprint's push-triggered
`update-contributors.yml` (REST, `gh api`, pages 20 s apart) and compares it
with the paths-ignore verdicts computed by paths_filter.py from git history:

  A2  no run has a head_sha equal to a SKIP commit;
  A1  every RUN commit inside the retained-run window has a `push` run whose
      head_sha is that commit.
Both are the naive per-commit model. GitHub evaluates the filter per push
(before..after), and py's main uses a merge queue that lands several PRs in
one push, so analyze_runs.py re-evaluates the same data per push range.

Also reads ts-launch-blueprint's schedule-triggered history and reports each
run's delay from the cron slot `17 6 * * 1` (Monday 06:17 UTC).

Usage: real_runs.py <py-verdicts.json> <out-dir>
"""

import datetime as dt
import json
import subprocess
import sys
import time

PY = "smorinlabs/py-launch-blueprint"
TS = "smorinlabs/ts-launch-blueprint"
WF = "actions/workflows/update-contributors.yml/runs"


def gh_api(path: str) -> dict:
    return json.loads(
        subprocess.run(
            ["gh", "api", path], check=True, capture_output=True, text=True
        ).stdout
    )


def fetch_all(repo: str, out_path: str) -> list[dict]:
    runs = []
    page = 1
    while True:
        data = gh_api(f"repos/{repo}/{WF}?per_page=100&page={page}")
        batch = data["workflow_runs"]
        runs.extend(batch)
        print(f"  {repo} page {page}: {len(batch)} runs (total_count={data['total_count']})")
        if len(runs) >= data["total_count"] or not batch:
            break
        page += 1
        time.sleep(20)
    slim = [
        {k: r.get(k) for k in ("id", "event", "head_sha", "head_branch", "conclusion", "created_at", "run_started_at")}
        for r in runs
    ]
    with open(out_path, "w") as fh:
        json.dump(slim, fh, indent=1)
    return slim


def main() -> None:
    verdicts_path, out_dir = sys.argv[1:3]
    verdicts = json.load(open(verdicts_path))["commits"]

    print("== py-launch-blueprint: push-triggered history (REST) ==")
    py_runs = fetch_all(PY, f"{out_dir}/py-update-contributors-runs.json")
    by_event = {}
    for r in py_runs:
        by_event[r["event"]] = by_event.get(r["event"], 0) + 1
    print(f"retained runs: {len(py_runs)} by event: {json.dumps(by_event, sort_keys=True)}")
    oldest = min(r["created_at"] for r in py_runs)
    newest = max(r["created_at"] for r in py_runs)
    print(f"retained window: {oldest} .. {newest}")

    run_shas = {r["head_sha"] for r in py_runs if r["event"] == "push"}
    skip = [c for c in verdicts if c["verdict"] == "SKIP"]
    leaked = [c for c in skip if c["sha"] in run_shas]
    print(f"A2: SKIP commits in git history: {len(skip)}; with a push run in production: {len(leaked)}")
    for c in leaked:
        print(f"  LEAK {c['sha'][:10]} {c['subject']}")

    window_start = oldest
    in_window = [c for c in verdicts if c["date"] >= window_start]
    run_expected = [c for c in in_window if c["verdict"] == "RUN"]
    fired = [c for c in run_expected if c["sha"] in run_shas]
    missing = [c for c in run_expected if c["sha"] not in run_shas]
    skip_in_window = [c for c in in_window if c["verdict"] == "SKIP"]
    print(
        f"A1: first-parent commits inside the retained window: {len(in_window)}; "
        f"RUN verdicts: {len(run_expected)}; with a matching push run: {len(fired)}; "
        f"without: {len(missing)}; SKIP verdicts in window: {len(skip_in_window)}"
    )
    for c in missing[:5]:
        print(f"  NO-RUN {c['sha'][:10]} {c['date'][:10]} {c['subject']}")
    if len(missing) > 5:
        print(f"  ... {len(missing) - 5} more; per-commit matching is the naive model, see analyze_runs.py for the push-range model")

    print()
    print("== ts-launch-blueprint: schedule-triggered history (REST) ==")
    time.sleep(20)
    ts_runs = fetch_all(TS, f"{out_dir}/ts-update-contributors-runs.json")
    by_event = {}
    for r in ts_runs:
        by_event[r["event"]] = by_event.get(r["event"], 0) + 1
    print(f"retained runs: {len(ts_runs)} by event: {json.dumps(by_event, sort_keys=True)}")
    print("cron '17 6 * * 1' = Monday 06:17 UTC; delay of each schedule run from its slot:")
    for r in sorted(ts_runs, key=lambda r: r["created_at"]):
        if r["event"] != "schedule":
            continue
        created = dt.datetime.fromisoformat(r["created_at"].replace("Z", "+00:00"))
        slot = created.replace(hour=6, minute=17, second=0, microsecond=0)
        if slot > created:
            slot -= dt.timedelta(days=1)
        while slot.weekday() != 0:
            slot -= dt.timedelta(days=1)
        delay = created - slot
        print(
            f"  {r['created_at']} {r['conclusion']:8} delay={delay} "
            f"(weekday={created.strftime('%a')})"
        )


if __name__ == "__main__":
    main()
