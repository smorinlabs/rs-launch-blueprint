#!/usr/bin/env bash
# R82 revision 1 synthesis (revision 2: title and L cases): structural integrity of review/DECISION.md.
#   I1 every `- assumes` line is byte-identical to inputs/parameters.json, and none is missing
#   I2 the prerequisite decisions on disk hash to inputs/prerequisites.json
#   I3 the H2 set and order match a published decision (Decision, Parameters, Empirical check, Engines)
#   I4 every executed-case id (G.., L..) and upstream-check id (U..) cited exists in its log
#   I5 every repository file:line citation resolves to a non-blank line; the line is printed for review
# Usage (from the run directory): bash review/evidence/r82-decision-integrity.sh > review/evidence/r82-decision-integrity.log 2>&1
set -euo pipefail

run_dir="$(cd "$(dirname "$0")/../.." && pwd)"
repo="$(cd "$run_dir/../../../.." && pwd)"
cd "$run_dir"

echo "# r82-decision-integrity — run $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "# DECISION sha256 $(shasum -a 256 review/DECISION.md | cut -c1-64), $(wc -l < review/DECISION.md | tr -d ' ') lines"

python3 - "$run_dir" "$repo" <<'PY'
import json, hashlib, re, sys, pathlib
run, repo = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
dec = (run / "review/DECISION.md").read_text()
fail = 0
def bad(msg):
    global fail
    fail += 1
    print("FAIL", msg)

print("\n## I1 assumes lines")
params = {p["param"]: p["value"] for p in json.loads((run / "inputs/parameters.json").read_text())}
seen = {}
for line in dec.splitlines():
    m = re.match(r"^- assumes ([a-z-]+) = (.*)$", line)
    if m:
        seen[m.group(1)] = m.group(2)
for k, v in params.items():
    if k not in seen:
        bad(f"missing assumes {k}")
    elif seen[k] != v:
        bad(f"assumes {k} differs from parameters.json")
    else:
        print(f"ok   assumes {k} byte-identical ({len(v)} chars)")
for k in seen:
    if k not in params:
        bad(f"assumes {k} not in parameters.json")
if re.search(r"^- owns ", dec, re.M):
    bad("an owns line exists")
else:
    print("ok   no owns line")

print("\n## I2 prerequisite decision hashes")
prereq = json.loads((run / "inputs/prerequisites.json").read_text())
slug = {"R11": "11-ci-workflow-job-structure", "R69": "69-web-framework-stack"}
for item, h in prereq.items():
    got = hashlib.sha256((repo / "research/topics" / slug[item] / "DECISION.md").read_bytes()).hexdigest()
    print(("ok  " if got == h["decision"] else "FAIL"), item, got)
    if got != h["decision"]:
        fail += 1

print("\n## I3 H2 structure")
h2 = re.findall(r"^## (.+)$", dec, re.M)
print("H2:", h2)
if h2 != ["Decision", "Parameters", "Empirical check", "Engines"]:
    bad("H2 set/order")
if not re.match(r"^# \d{4}-\d{2}-\d{2} — R82 — docs-correctness-gate \(bundle, Focused\) — decision \(revision 2\)$", dec.splitlines()[0]):
    bad("title line")
else:
    print("ok   title line")
rv = [l for l in dec.splitlines() if l.startswith("re-verify: ")]
print(("ok  " if len(rv) == 1 else "FAIL"), f"re-verify lines: {len(rv)}")
fail += len(rv) != 1

print("\n## I4 case and check ids")
glog = (run / "review/evidence/r82-rustdoc-gate.log").read_text()
ulog = (run / "review/evidence/r82-upstream-reads.log").read_text()
gids = sorted(set(re.findall(r"`(G\d+[a-d]?)`", dec)) | set(re.findall(r"\| (G\d+[a-d]?)\b", dec)))
for g in gids:
    ok = re.search(rf"^{g}\s", glog, re.M) is not None or (re.fullmatch(r"G\d+", g) and f"### {g} " in glog)
    print(("ok  " if ok else "FAIL"), g)
    fail += not ok
llog = (run / "review/evidence/r82-lychee-offline.log").read_text()
lids = sorted(set(re.findall(r"`(L\d+v?)`", dec)) | set(re.findall(r"\| (L\d+v?) \|", dec)))
for l in lids:
    ok = re.search(rf"^{l}\s", llog, re.M) is not None or f"## {l} " in llog
    print(("ok  " if ok else "FAIL"), l)
    fail += not ok
uids = sorted(set(re.findall(r"`(U\d+b?)`", dec)) | set(re.findall(r"\| (U\d+b?) \|", dec)))
for u in uids:
    ok = f"## {u} " in ulog
    print(("ok  " if ok else "FAIL"), u)
    fail += not ok

print("\n## I5 file:line citations (first cited line shown)")
files = {
    "raw/muse.md": run / "raw/muse.md",
    "raw/opus.md": run / "raw/opus.md",
    "prompt": repo / "research/topics/82-docs-correctness-gate/prompts/docs-correctness-gate.prompt.md",
    "research/RUNBOOK.md": repo / "research/RUNBOOK.md",
    "research/topics/11-ci-workflow-job-structure/DECISION.md": repo / "research/topics/11-ci-workflow-job-structure/DECISION.md",
    "research/topics/53-config-schema-validation/DECISION.md": repo / "research/topics/53-config-schema-validation/DECISION.md",
}
cites = []
for m in re.finditer(r"(raw/(?:muse|opus)\.md|research/RUNBOOK\.md|research/topics/(?:11-ci-workflow-job-structure|53-config-schema-validation)/DECISION\.md):(\d+)(?:-(\d+))?", dec):
    cites.append((m.group(1), int(m.group(2)), int(m.group(3) or m.group(2))))
    # continuation tokens such as , `:418` inside the same parenthesis
    tail = dec[m.end():m.end() + 80].split(")")[0]
    for c in re.finditer(r"`:(\d+)(?:-(\d+))?`", tail):
        cites.append((m.group(1), int(c.group(1)), int(c.group(2) or c.group(1))))
for m in re.finditer(r"prompt line (\d+)", dec):
    cites.append(("prompt", int(m.group(1)), int(m.group(1))))
for f, a, b in sorted(set(cites), key=lambda t: (t[0], t[1], t[2])):
    lines = files[f].read_text().splitlines()
    if not (1 <= a <= b <= len(lines)) or not lines[a - 1].strip():
        bad(f"{f}:{a}-{b} does not resolve (file has {len(lines)} lines)")
        continue
    print(f"ok   {f}:{a}{'-' + str(b) if b != a else ''} | {lines[a - 1].strip()[:110]}")

print(f"\nRESULT: {'PASS' if fail == 0 else 'FAIL'} ({fail} failures, {len(set(cites))} citations)")
sys.exit(1 if fail else 0)
PY
