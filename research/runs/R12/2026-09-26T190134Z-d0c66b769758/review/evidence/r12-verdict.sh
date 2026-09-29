#!/usr/bin/env bash
# R12 revision-1 evidence: the recommended verdict rule (extracted from the
# fixture, not retyped) over nine needs-vectors, three contrast rules, the
# empty-needs trap, and the guard program over four job graphs.
set -euo pipefail
export PATH="/Users/stevemorin/.local/bin:/opt/homebrew/bin:$PATH"

EV="$(cd "$(dirname "$0")" && pwd)"
FIX="$EV/ci.candidate.yml"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/r12-verdict.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "PASS $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL $1 -- $2"; }
info() { echo "INFO $1"; }

command -v jq >/dev/null || { bad "V-setup" "jq not on PATH"; exit 1; }
info "jq=$(jq --version)"

# Extract the recommended rule + guard program from the fixture (not retyped).
python3 - "$FIX" "$TMP" <<'EOF'
import re, sys, yaml
fix, tmp = sys.argv[1], sys.argv[2]
doc = yaml.safe_load(open(fix))
verdict = doc["jobs"]["ci-ok"]["steps"][0]["run"]
guard = doc["jobs"]["workflow-lint"]["steps"][1]["run"]
m = re.search(r"jq -e '(.*)' <<<", verdict, re.S)
assert m, "verdict jq program not found"
open(f"{tmp}/rule.jq", "w").write(m.group(1))
m = re.search(r"jq -e '(.*)' > /dev/null", guard, re.S)
assert m, "guard jq program not found"
open(f"{tmp}/guard.jq", "w").write(m.group(1))
jobs = doc["jobs"]
import json
open(f"{tmp}/jobs.json", "w").write(json.dumps(jobs))
print("rule:", m.group(1)[:40] if False else open(f"{tmp}/rule.jq").read())
EOF
RULE="$(cat "$TMP/rule.jq")"
if [ "$RULE" = 'length > 0 and all(.[]; .result == "success" or .result == "skipped")' ]; then
  ok "V0-rule extracted rule is the allow-list with length guard"
else
  bad "V0-rule" "unexpected extracted rule: $RULE"
fi

# V0: jq all() over an empty object is true — the trap length>0 closes.
if echo '{}' | jq -e 'all(.[]; false)' >/dev/null 2>&1; then
  ok "V0-empty all() over {} is true (empty needs would pass without length>0)"
else
  bad "V0-empty" "all() over {} is not true on this jq"
fi

# Extract py's real ci-ok loop at its pinned commit; run it, not a retyping.
PYREPO="$HOME/c/py-launch-blueprint"
PYPIN="b55b8c2"
if [ -d "$PYREPO/.git" ] && git -C "$PYREPO" rev-parse --verify -q "$PYPIN^{commit}" >/dev/null; then
  git -C "$PYREPO" show "$PYPIN:.github/workflows/ci.yml" >"$TMP/py-ci.yml"
  python3 - "$TMP/py-ci.yml" "$TMP/py-loop.sh" <<'EOF'
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
steps = doc["jobs"]["ci-ok"]["steps"]
body = "\n".join(s["run"] for s in steps if "run" in s)
open(sys.argv[2], "w").write(body + "\n")
EOF
  info "py loop bytes: $(wc -c <"$TMP/py-loop.sh")"
  ok "V0-py extracted py ci-ok loop at $PYPIN"
else
  bad "V0-py" "py repo or pin $PYPIN unavailable"; echo "RESULT PASS=$PASS FAIL=$FAIL SKIP=0"; exit 1
fi

# Needs vectors: T1..T9 as JSON objects job -> {result}.
mk() { # $1 name, $2.. job=result pairs
  local name="$1"; shift
  local json="{"
  for pair in "$@"; do json="$json\"${pair%%=*}\":{\"result\":\"${pair#*=}\"},"; done
  json="${json%,}}"
  echo "$json" >"$TMP/$name.json"
}
mk T1 plan=success hygiene=success workflow-lint=success check=success msrv-floor=success install-smoke=success
mk T2 plan=success hygiene=success workflow-lint=skipped check=skipped msrv-floor=skipped install-smoke=skipped
mk T3 plan=failure hygiene=success workflow-lint=skipped check=skipped msrv-floor=skipped install-smoke=skipped
mk T4 plan=cancelled hygiene=success workflow-lint=skipped check=skipped msrv-floor=skipped install-smoke=skipped
mk T5 plan=success hygiene=success workflow-lint=success check=failure msrv-floor=success install-smoke=success
mk T6 plan=success hygiene=success workflow-lint=success check=cancelled msrv-floor=success install-smoke=success
mk T7 plan=success hygiene=failure workflow-lint=success check=success msrv-floor=success install-smoke=success
mk T8 plan=success hygiene=success workflow-lint=success check=success msrv-floor=success install-smoke=timed_out
echo '{}' >"$TMP/T9.json"

# Expected verdicts per rule: 0=PASS 1=FAIL. Columns: T1..T9.
REC_EXPECT="0 0 1 1 1 1 1 1 1"   # recommended allow-list
PY_EXPECT="0 0 1 1 1 1 1 0 0"    # py deny-list passes unknown + empty
NAIVE_EXPECT="0 0 1 0 1 0 1 0 0" # !contains(failure) misses cancelled/unknown/empty
CARGO_EXPECT="0 1 1 1 1 1 1 1 0" # all-success fails docs-only, passes empty

run_rec()   { jq -e "$RULE" "$1" >/dev/null 2>&1; echo $?; }
run_naive() { jq -e '[.[].result] | contains(["failure"]) | not' "$1" >/dev/null 2>&1; echo $?; }
run_cargo() { jq -e 'all(.[]; .result == "success")' "$1" >/dev/null 2>&1; echo $?; }
run_py() { # py's real loop over space-joined results, as its RESULTS env feeds it
  local results
  results="$(jq -r '[.[].result // empty] | join(" ")' "$1")"
  RESULTS="$results" bash "$TMP/py-loop.sh" >/dev/null 2>&1; echo $?;
}

i=1
for t in T1 T2 T3 T4 T5 T6 T7 T8 T9; do
  exp="$(echo "$REC_EXPECT" | cut -d' ' -f"$i")"
  got="$(run_rec "$TMP/$t.json")"
  if [ "$exp" = 0 ]; then want=PASS; else want=FAIL; fi
  if [ "$got" = "$exp" ]; then ok "V-rec-$t recommended->$want"; else bad "V-rec-$t" "expected $exp got $got"; fi
  exp="$(echo "$PY_EXPECT" | cut -d' ' -f"$i")"
  got="$(run_py "$TMP/$t.json")"
  if [ "$exp" = 0 ]; then want=PASS; else want=FAIL; fi
  if [ "$got" = "$exp" ]; then ok "V-py-$t py-loop->$want"; else bad "V-py-$t" "expected $exp got $got"; fi
  exp="$(echo "$NAIVE_EXPECT" | cut -d' ' -f"$i")"
  got="$(run_naive "$TMP/$t.json")"
  if [ "$exp" = 0 ]; then want=PASS; else want=FAIL; fi
  if [ "$got" = "$exp" ]; then ok "V-naive-$t naive->$want"; else bad "V-naive-$t" "expected $exp got $got"; fi
  exp="$(echo "$CARGO_EXPECT" | cut -d' ' -f"$i")"
  got="$(run_cargo "$TMP/$t.json")"
  if [ "$exp" = 0 ]; then want=PASS; else want=FAIL; fi
  if [ "$got" = "$exp" ]; then ok "V-cargo-$t all-success->$want"; else bad "V-cargo-$t" "expected $exp got $got"; fi
  i=$((i+1))
done

# Guard program over four job graphs. G1 is the fixture's real .jobs.
if jq -e -f "$TMP/guard.jq" "$TMP/jobs.json" >/dev/null 2>&1; then
  ok "G1 guard exits 0 on the unchanged fixture"
else
  bad "G1" "guard failed on the unchanged fixture"
fi
jq '. + {"semver-checks": {"runs-on": "ubuntu-latest"}}' "$TMP/jobs.json" >"$TMP/g2.json"
set +e
OUT="$(jq -e -f "$TMP/guard.jq" "$TMP/g2.json" 2>&1 >/dev/null)"; CODE=$?
set -e
if [ "$CODE" -ne 0 ] && echo "$OUT" | grep -q 'semver-checks'; then
  ok "G2 guard exits 1 naming the added job"
else
  bad "G2" "exit=$CODE out=$OUT"
fi
jq '.["ci-ok"].needs |= map(select(. != "plan"))' "$TMP/jobs.json" >"$TMP/g3.json"
set +e
OUT="$(jq -e -f "$TMP/guard.jq" "$TMP/g3.json" 2>&1 >/dev/null)"; CODE=$?
set -e
if [ "$CODE" -ne 0 ] && echo "$OUT" | grep -q '"plan"'; then
  ok "G3 guard exits 1 naming dropped plan"
else
  bad "G3" "exit=$CODE out=$OUT"
fi
jq '.["build"] = .["check"] | del(.["check"])' "$TMP/jobs.json" >"$TMP/g4.json"
set +e
OUT="$(jq -e -f "$TMP/guard.jq" "$TMP/g4.json" 2>&1 >/dev/null)"; CODE=$?
set -e
if [ "$CODE" -ne 0 ] && echo "$OUT" | grep -q '"build"' && echo "$OUT" | grep -q '"check"'; then
  ok "G4 guard exits 1 naming renamed job both ways"
else
  bad "G4" "exit=$CODE out=$OUT"
fi

echo "RESULT PASS=$PASS FAIL=$FAIL SKIP=0"
[ "$FAIL" -eq 0 ]
