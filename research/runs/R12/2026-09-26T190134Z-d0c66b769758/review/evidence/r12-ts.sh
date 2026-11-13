#!/usr/bin/env bash
# R12 revision-2 evidence: ts's CI shape and queue state, asserted offline over
# the committed snapshots (no network). Grounds the corrected ts row, the
# restated Disagreement 7, the bun-lane handling in the ts follow-on, and the
# "P5 vacuous for ts until it uses a queue" wording.
set -euo pipefail
export PATH="/Users/stevemorin/.local/bin:/opt/homebrew/bin:$PATH"

ROOT="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
EV="$ROOT/research/runs/R12/2026-09-26T190134Z-d0c66b769758/review/evidence"
SNAP="$EV/snapshots"
TS="$HOME/c/ts-launch-blueprint"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "PASS $1"; }
bad() { FAIL=$((FAIL+1)); echo "FAIL $1 -- $2"; }

# The snapshot is what the pin says.
if git -C "$TS" show 'e5100b4:.github/workflows/ci.yml' | cmp -s - "$SNAP/r12-ts-ci.yml"; then
  ok "T-ts-pin snapshot r12-ts-ci.yml is byte-identical to ts e5100b4:.github/workflows/ci.yml"
else bad "T-ts-pin" "snapshot differs from the pinned file"; fi

# Job structure: exactly ci + bun-lane; ci matrixed over node-version; bun-lane advisory.
if python3 - "$SNAP/r12-ts-ci.yml" <<'EOF'
import sys, yaml
wf = yaml.safe_load(open(sys.argv[1]))
jobs = wf["jobs"]
print("jobs:", sorted(jobs))
assert sorted(jobs) == ["bun-lane", "ci"], sorted(jobs)
EOF
then ok "T-ts-jobs2 ts ci.yml has exactly two jobs: ci, bun-lane"; else bad "T-ts-jobs2" "job set differs"; fi

if python3 - "$SNAP/r12-ts-ci.yml" <<'EOF'
import sys, yaml
ci = yaml.safe_load(open(sys.argv[1]))["jobs"]["ci"]
nv = ci["strategy"]["matrix"]["node-version"]
print("ci name:", ci["name"], "node-version:", nv, "continue-on-error:", ci.get("continue-on-error"))
assert ci["name"] == "continuous-integration"
assert nv == ["24.x", "26.x"]
assert "continue-on-error" not in ci
EOF
then ok "T-ts-ci-matrix ci is continuous-integration over node-version [24.x, 26.x], no continue-on-error"; else bad "T-ts-ci-matrix" "unexpected ci shape"; fi

if python3 - "$SNAP/r12-ts-ci.yml" <<'EOF'
import sys, yaml
bl = yaml.safe_load(open(sys.argv[1]))["jobs"]["bun-lane"]
print("bun-lane name:", bl["name"], "continue-on-error:", bl.get("continue-on-error"), "needs:", bl.get("needs"))
assert bl["name"] == "bun-lane (advisory, non-gating)"
assert bl.get("continue-on-error") is True
assert "strategy" not in bl
EOF
then ok "T-ts-bunlane bun-lane is named advisory/non-gating with continue-on-error true, no matrix"; else bad "T-ts-bunlane" "unexpected bun-lane shape"; fi

# Voting set derived from the file alone (jobs minus continue-on-error: true) is {ci}.
if python3 - "$SNAP/r12-ts-ci.yml" <<'EOF'
import sys, yaml
jobs = yaml.safe_load(open(sys.argv[1]))["jobs"]
voting = sorted(j for j, b in jobs.items() if b.get("continue-on-error") is not True)
advisory = sorted(j for j, b in jobs.items() if b.get("continue-on-error") is True)
print("voting:", voting, "advisory:", advisory)
assert voting == ["ci"] and advisory == ["bun-lane"]
EOF
then ok "T-ts-voting jobs minus continue-on-error:true is exactly {ci}; advisory is exactly {bun-lane}"; else bad "T-ts-voting" "derivation differs"; fi

# Queue state: ts has no merge_group trigger and no merge_queue rule, so P5 is vacuous for ts today.
if python3 - "$SNAP/r12-ts-ci.yml" <<'EOF'
import sys, yaml
wf = yaml.safe_load(open(sys.argv[1]))
on = wf.get("on", wf.get(True))
print("triggers:", sorted(on))
assert "merge_group" not in on
EOF
then ok "T-ts-nomg ts triggers lack merge_group"; else bad "T-ts-nomg" "merge_group present"; fi

if python3 - "$SNAP/r12-ts-rules.json" <<'EOF'
import sys, json
types = sorted(r["type"] for r in json.load(open(sys.argv[1])))
print("ts rule types:", types)
assert "merge_queue" not in types
assert "required_status_checks" not in types
EOF
then ok "T-ts-noqueue ts main has no merge_queue and no required_status_checks rule"; else bad "T-ts-noqueue" "a queue or required rule exists"; fi

# F025 is an rs adoption of py's trigger, not an obligation already binding ts.
if grep -qF '| F025 | merge_group trigger so required checks report in the GitHub merge queue | ci-workflows | py-only | ADOPT | — |' "$ROOT/docs/port/COMMONALITY.md"; then
  ok "T-f025 COMMONALITY F025 is py-only ADOPT"
else bad "T-f025" "F025 row differs"; fi

echo "RESULT PASS=$PASS FAIL=$FAIL SKIP=0"
[ "$FAIL" -eq 0 ]
