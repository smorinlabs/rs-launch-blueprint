#!/usr/bin/env python3
"""Reconstruct the whole P02 research state from disk, and say what to do next.

The programme's state lives in the repository, not in any agent's memory. This
reads it back after any interruption -- a stopped session, a killed subagent, a
machine restart -- and prints, per item, what exists, what is in flight and what
the next action is. It reads only; it never contacts a provider and never writes.

    uv run --offline --no-project --no-python-downloads --no-cache \
        python3 scripts/research_scan.py [--json] [--item R01] [--todo]

Sources of truth, in order:
  research/CLAUDE.md              the index: which items are published
  research/EXECUTION.json         tier, required engines, evidence checks
  research/runs/<I>/<RUN>/        manifest.json, operations/, raw/, review/
  docs/planning/p02/execution-ledger.md   the narrative record (not parsed)

`--todo` prints only items needing action, which is what to read on return.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ITEM_RE = re.compile(r"^R\d\d$")
VERDICT_RE = re.compile(r"(?m)^verdict:\s*(\w+)\s*$")
FINDINGS_RE = re.compile(r"(?m)^unresolved-findings:\s*(.+?)\s*$")
DECSHA_RE = re.compile(r"(?m)^decision-sha256:\s*([0-9a-f]+)\s*$")
REV_RE = re.compile(r"revision (\d+)")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def index_status(root: Path) -> dict[str, str]:
    out = {}
    for line in (root / "research/CLAUDE.md").read_text().splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) == 8 and ITEM_RE.fullmatch(cells[0]):
            out[cells[0]] = cells[-1]
    return out


def audit_of(path: Path) -> dict | None:
    """Read an audit's header fields without loading its body twice."""
    if not path.is_file():
        return None
    head = path.read_text()[:4000]
    v = VERDICT_RE.search(head)
    f = FINDINGS_RE.search(head)
    d = DECSHA_RE.search(head)
    return {
        "verdict": v.group(1) if v else "?",
        "findings": (f.group(1) if f else "?")[:120],
        "decision_sha256": d.group(1) if d else None,
    }


def scan_run(run: Path) -> dict:
    manifest = json.loads((run / "manifest.json").read_text())
    review = run / "review"
    decision = review / "DECISION.md"
    info: dict = {
        "run_id": run.name,
        "state": manifest["state"],
        "tier": manifest.get("tier"),
        "required_engines": manifest.get("required_engines", []),
        "engines": {k: v["state"] for k, v in manifest["operations"].items()},
        "in_flight": {},
        "decision": None,
        "audits": {},
        "rounds": len([p for p in review.glob("audit-*.r*.md")]) if review.is_dir() else 0,
    }

    # engine operations that are not finished: outstanding jobs recoverable by id,
    # plus partial and failed ones, which a returning session must not overlook
    for engine, op in manifest["operations"].items():
        if op["state"] in {"submitting", "submitted", "running", "unknown", "partial", "failed"}:
            entry = {"state": op["state"], "operation_id": op.get("operation_id")}
            status = run / "operations/doxa-status-initial.json"
            if engine == "doxa" and status.is_file():
                try:
                    provs = json.loads(status.read_text())["data"]["providers"]
                    entry["provider_jobs"] = {k: v.get("job_id") for k, v in provs.items()}
                except Exception:
                    pass
            info["in_flight"][engine] = entry

    if decision.is_file():
        text = decision.read_text()
        m = REV_RE.search(text.split("\n", 1)[0])
        info["decision"] = {
            "sha256": sha256(decision),
            "revision": int(m.group(1)) if m else 1,
        }
        for kind, name in (("empirical", "audit-codex.md"), ("judgment", "audit-fable.md")):
            a = audit_of(review / name)
            if a:
                a["binds_current_decision"] = a["decision_sha256"] == info["decision"]["sha256"]
                info["audits"][kind] = a
    return info


def next_action(status: str, run: dict | None) -> str:
    if status == "resolved":
        return "done"
    if run is None:
        return "not admitted: run prepare"
    missing = [e for e in run["required_engines"] if run["engines"].get(e) != "succeeded"]
    if run["in_flight"]:
        which = ", ".join(f"{k} ({v['state']})" for k, v in run["in_flight"].items())
        return f"collect in-flight: {which}"
    if missing:
        return "research: " + ", ".join(missing)
    if run["decision"] is None:
        return "synthesize"
    emp, jud = run["audits"].get("empirical"), run["audits"].get("judgment")
    stale = [k for k, a in run["audits"].items() if not a["binds_current_decision"]]
    if stale:
        return f"audit is stale against the current decision: {', '.join(stale)}"
    if emp is None:
        return "empirical audit"
    if emp["verdict"] != "approve":
        return f"revise (round {run['rounds'] + 1}): empirical rejected"
    if jud is None:
        return "judgment audit"
    if jud["verdict"] != "approve":
        return f"revise (round {run['rounds'] + 1}): judgment rejected"
    return "package + publish"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--item")
    ap.add_argument("--todo", action="store_true", help="only items needing action")
    args = ap.parse_args()

    policy = json.loads((ROOT / "research/EXECUTION.json").read_text())["items"]
    status = index_status(ROOT)
    runs_dir = ROOT / "research/runs"

    report: dict[str, dict] = {}
    for item in sorted(policy):
        if args.item and item != args.item:
            continue
        d = runs_dir / item
        run = None
        if d.is_dir():
            candidates = sorted(p for p in d.iterdir() if (p / "manifest.json").is_file())
            if candidates:
                run = scan_run(candidates[-1])
        report[item] = {
            "tier": policy[item]["tier"],
            "index": status.get(item, "?"),
            "run": run,
            "next": next_action(status.get(item, "?"), run),
        }

    if args.json:
        json.dump(report, sys.stdout, indent=1)
        print()
        return 0

    rows = [(k, v) for k, v in report.items() if not (args.todo and v["next"] == "done")]
    print(f"{'item':5} {'tier':8} {'index':10} {'rev':>3} {'rnds':>4}  next action")
    for item, v in rows:
        run, dec = v["run"], (v["run"] or {}).get("decision")
        rev = dec["revision"] if dec else ""
        rnds = run["rounds"] if run else ""
        print(f"{item:5} {v['tier']:8} {v['index']:10} {str(rev):>3} {str(rnds):>4}  {v['next']}")

    counts: dict[str, int] = {}
    for v in report.values():
        key = "done" if v["next"] == "done" else v["next"].split(":")[0]
        counts[key] = counts.get(key, 0) + 1
    print("\nsummary: " + " · ".join(f"{k} {n}" for k, n in sorted(counts.items(), key=lambda kv: -kv[1])))

    flight = {i: v["run"]["in_flight"] for i, v in report.items() if v["run"] and v["run"]["in_flight"]}
    if flight:
        print("\nunfinished engine operations, recoverable by recorded identifier:")
        for item, engines in flight.items():
            for engine, e in engines.items():
                print(f"  {item} {engine} {e['state']} op={e.get('operation_id')}")
                for prov, job in (e.get("provider_jobs") or {}).items():
                    print(f"        {prov}: {job}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
