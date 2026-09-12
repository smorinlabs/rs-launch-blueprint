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


def registry_values(root: Path) -> dict[str, str]:
    """Fixed-parameter values, parsed the way the publication validator parses them."""
    values: dict[str, str] = {}
    header = None
    for line in (root / "docs/port/PARAMETERS.md").read_text().splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if {"param", "kind", "owner", "value"}.issubset(cells):
            header = {name: i for i, name in enumerate(cells)}
        elif header and len(cells) >= len(header) and cells[header["param"]]:
            values[cells[header["param"]]] = cells[header["value"]]
    return values


def parameter_mismatches(decision: Path, registry: dict[str, str]) -> list[str]:
    """Parameter lines whose value would not match the registry at publication.

    The validator reads everything after "= " as the value and compares it
    byte-for-byte, so a backticked value or a trailing citation fails even when
    the value itself is right. Publication refuses the bundle, and because any
    edit to the decision unbinds its audits, the fix costs a full audit round.
    Catching it here, before the audits run, is the whole point.
    """
    bad = []
    for m in re.finditer(r"(?m)^- assumes\s+`?([a-z-]+)`?\s*=\s*(.+?)\s*$", decision.read_text()):
        name, value = m.group(1), m.group(2)
        if name in registry and value != registry[name]:
            bad.append(name)
    return bad


def provider_jobs(run: Path) -> dict[str, str]:
    """Provider job ids recorded for a Doxa operation, whatever the file is called.

    Attempts after the first are numbered (`doxa-status3-initial.json`), and a
    failed operation records a checkpoint copy instead, whose providers sit at
    the top level rather than under `data`. Read every candidate and merge, so a
    rescan never depends on one filename or one shape.
    """
    jobs: dict[str, str] = {}
    ops = run / "operations"
    if not ops.is_dir():
        return jobs
    for f in sorted(ops.glob("doxa-*.json")):
        try:
            doc = json.loads(f.read_text())
        except Exception:
            continue
        provs = doc.get("providers") or (doc.get("data") or {}).get("providers") or {}
        if isinstance(provs, dict):
            for name, v in provs.items():
                if isinstance(v, dict) and v.get("job_id"):
                    jobs.setdefault(name, v["job_id"])
    return jobs


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
            # A failed or partial operation is NOT in flight. Reporting it as
            # pending work made a dead R66 operation look live for two days.
            entry = {"state": op["state"], "operation_id": op.get("operation_id")}
            if engine == "doxa":
                jobs = provider_jobs(run)
                if jobs:
                    entry["provider_jobs"] = jobs
            info["in_flight"][engine] = entry

    if decision.is_file():
        text = decision.read_text()
        m = REV_RE.search(text.split("\n", 1)[0])
        info["decision"] = {
            "sha256": sha256(decision),
            "revision": int(m.group(1)) if m else 1,
        }
        info["parameter_mismatches"] = parameter_mismatches(decision, registry_values(ROOT))
        info["has_identities"] = (review / "identities.json").is_file()
        info["published_sha"] = published_decision_sha(manifest["item"], ROOT)
        for kind, name in (("empirical", "audit-codex.md"), ("judgment", "audit-fable.md")):
            a = audit_of(review / name)
            if a:
                a["binds_current_decision"] = a["decision_sha256"] == info["decision"]["sha256"]
                info["audits"][kind] = a
    return info


def published_decision_sha(item: str, root: Path) -> str | None:
    """sha256 of the published copy of an item's decision, if one exists."""
    hits = sorted((root / "research/topics").glob(f"*/DECISION.md"))
    for path in hits:
        head = path.read_text()[:200]
        if head.lstrip().startswith(f"# {item} ") or f"# {item} " in head:
            return sha256(path)
    return None


def next_action(status: str, run: dict | None) -> str:
    if status == "resolved":
        # A resolved index row is not proof the work is finished. An item
        # reopened for a revision keeps its resolved row until the revision
        # republishes, so comparing the run's decision with the published copy
        # is the only way to see it. R18 read as "done" for a whole session
        # while an unpublished revision 6 sat in its run.
        if run and run.get("decision") and run.get("published_sha"):
            if run["decision"]["sha256"] != run["published_sha"]:
                return f"REOPENED: run is at revision {run['decision']['revision']}, published copy differs"
        return "done"
    if run is None:
        return "not admitted: run prepare"
    missing = [e for e in run["required_engines"] if run["engines"].get(e) != "succeeded"]
    if run["in_flight"]:
        dead = {"partial", "failed", "unknown"}
        live = {k: v for k, v in run["in_flight"].items() if v["state"] not in dead}
        stopped = {k: v for k, v in run["in_flight"].items() if v["state"] in dead}
        parts = []
        if live:
            parts.append("collect in-flight: " + ", ".join(f"{k} ({v['state']})" for k, v in live.items()))
        if stopped:
            parts.append("STOPPED, needs a decision: " + ", ".join(f"{k} ({v['state']})" for k, v in stopped.items()))
        which = "; ".join(parts)
        # Name the engines that have not reported at all as well. An item can be
        # short several engines while one of them is in flight, and reporting only
        # the in-flight one hides the rest: R66 was short both Opus and Doxa and
        # read as though it were waiting on Doxa alone.
        also = [e for e in missing if e not in run["in_flight"]]
        rest = f"; not started: {', '.join(also)}" if also else ""
        return f"{which}{rest}"
    if missing:
        return "research: " + ", ".join(missing)
    if run["decision"] is None:
        return "synthesize"
    if run.get("parameter_mismatches"):
        return "fix parameter lines before auditing: " + ", ".join(run["parameter_mismatches"])
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
    if not run.get("has_identities"):
        # The packager refuses without it, and no earlier step writes it: the
        # empirical block must name the empirical auditor's own replay, because
        # the validator requires that executor to be the empirical auditor and
        # its family to differ from the synthesis family.
        return "write review/identities.json, then package + publish"
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
