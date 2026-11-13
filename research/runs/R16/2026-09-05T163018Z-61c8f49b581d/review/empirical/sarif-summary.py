#!/usr/bin/env python3
"""Print (ruleId, file:line) for every result in a SARIF file, plus the rule set that ran."""
import json, sys
p = sys.argv[1]
d = json.load(open(p))
for run in d["runs"]:
    rules = [r["id"] for r in run["tool"]["driver"].get("rules", [])]
    for ext in run["tool"].get("extensions", []):
        rules += [r["id"] for r in ext.get("rules", [])]
    sec = sorted(r for r in rules if r.startswith("rust/"))
    print(f"rules present in SARIF (rust/*): {len(sec)}")
    for r in sec:
        print(f"  {r}")
    res = run.get("results", [])
    print(f"results: {len(res)}")
    for r in sorted(res, key=lambda r: (r["ruleId"], r["locations"][0]["physicalLocation"]["artifactLocation"]["uri"], r["locations"][0]["physicalLocation"]["region"]["startLine"])):
        loc = r["locations"][0]["physicalLocation"]
        print(f"  {r['ruleId']}  {loc['artifactLocation']['uri']}:{loc['region']['startLine']}")
