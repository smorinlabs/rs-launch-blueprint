#!/usr/bin/env bash
# R12 revision-1 evidence: the candidate aggregate shape lints, and the two
# load-bearing lines (if: always(), complete needs:) are NOT enforced by lint.
set -euo pipefail
export PATH="/Users/stevemorin/.local/bin:/opt/homebrew/bin:$PATH"

EV="$(cd "$(dirname "$0")" && pwd)"
FIX="$EV/ci.candidate.yml"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/r12-lint.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "PASS $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL $1 -- $2"; }
info() { echo "INFO $1"; }

info "fixture=$FIX"
info "bash=$BASH_VERSION"
command -v actionlint >/dev/null || { bad "L0" "actionlint not on PATH"; exit 1; }

# L0: tool identity — same actionlint R11 used.
if [ "$(command -v actionlint)" = "/opt/homebrew/bin/actionlint" ] && actionlint -version 2>&1 | grep -q '1\.7\.12'; then
  ok "L0 actionlint is /opt/homebrew/bin/actionlint 1.7.12"
else
  bad "L0" "actionlint is $(command -v actionlint) $(actionlint -version 2>&1 | head -1)"
fi

# L1: the candidate shape lints clean.
if [ ! -f "$FIX" ]; then bad "L1" "fixture missing"; else
  OUT="$TMP/l1.out"
  if actionlint "$FIX" >"$OUT" 2>&1; then
    if [ -s "$OUT" ]; then bad "L1" "exit 0 but diagnostics: $(cat "$OUT")"; else ok "L1 candidate lints clean (exit 0, no diagnostics)"; fi
  else
    bad "L1" "actionlint exit $? : $(cat "$OUT")"
  fi
fi

# L2: negative control — removing `if: always()` still lints (the naive trap).
# shellcheck disable=SC2016 # '${{' is literal fixture text, not expansion
grep -n 'if: ${{ always() }}' "$FIX" | grep -q . || bad "L2-setup" "always() line not found in fixture"
sed '/if: ${{ always() }}/d' "$FIX" >"$TMP/no-always.yml"
if actionlint "$TMP/no-always.yml" >"$TMP/l2.out" 2>&1; then
  ok "L2 naive shape (no always()) still lints — lint does not enforce the rule"
else
  bad "L2" "expected exit 0, got nonzero: $(cat "$TMP/l2.out")"
fi

# L3: negative control — dropping plan from needs: still lints.
sed 's/needs: \[plan, /needs: [/' "$FIX" >"$TMP/no-plan.yml"
grep -q 'needs: \[hygiene' "$TMP/no-plan.yml" || bad "L3-setup" "sed did not drop plan"
if actionlint "$TMP/no-plan.yml" >"$TMP/l3.out" 2>&1; then
  ok "L3 incomplete needs: (plan dropped) still lints — lint does not enforce completeness"
else
  bad "L3" "expected exit 0, got nonzero: $(cat "$TMP/l3.out")"
fi

# L4: both R12-owned run: bodies are shellcheck-clean (extracted, not retyped).
python3 - "$FIX" "$TMP" <<'EOF'
import sys, yaml
fix, tmp = sys.argv[1], sys.argv[2]
doc = yaml.safe_load(open(fix))
jobs = doc["jobs"]
guard = jobs["workflow-lint"]["steps"][1]["run"]
verdict = jobs["ci-ok"]["steps"][0]["run"]
open(f"{tmp}/guard.sh", "w").write("#!/usr/bin/env bash\n" + guard)
open(f"{tmp}/verdict.sh", "w").write("#!/usr/bin/env bash\n" + verdict)
print("extracted guard bytes:", len(guard), "verdict bytes:", len(verdict))
EOF
if shellcheck "$TMP/guard.sh" "$TMP/verdict.sh" >"$TMP/l4.out" 2>&1; then
  ok "L4 extracted guard + verdict bodies are shellcheck-clean"
else
  bad "L4" "$(cat "$TMP/l4.out")"
fi

# L5: fixture content — the exact R12-owned bytes the DECISION recommends.
check() { # $1 id $2 description $3... grep -q pattern file
  local id="$1" desc="$2"; shift 2
  if grep -q "$1" "$FIX"; then ok "L5-$id $desc"; else bad "L5-$id" "$desc (pattern: $1)"; fi
}
check "needs"   "ci-ok needs lists all six R11 ids incl plan" 'needs: \[plan, hygiene, workflow-lint, check, msrv-floor, install-smoke\]'
check "always"  "ci-ok carries if: always()" "if: \${{ always() }}"
check "perm"    "ci-ok carries permissions: {}" 'permissions: {}'
check "time"    "ci-ok carries timeout-minutes: 5" 'timeout-minutes: 5'
check "runner"  "ci-ok runs on ubuntu-latest" 'runs-on: ubuntu-latest'
check "name"    "ci-ok has explicit name: ci-ok" 'name: ci-ok'
check "merge"   "triggers include merge_group" '^  merge_group:'
check "env"     "verdict reads needs through env, not interpolation" "NEEDS_JSON: \${{ toJSON(needs) }}"
check "guard"   "guard step lives in workflow-lint" 'ci-ok folds in every other ci.yml job'
check "rule"    "verdict is the allow-list with length guard" 'length > 0 and all'
if grep -q 'paths-ignore' "$FIX" || grep -qE '^\s+paths:' "$FIX"; then
  bad "L5-nopaths" "fixture must carry no trigger-level path filter"
else
  ok "L5-nopaths no trigger-level paths/paths-ignore filter"
fi
N_POS=$(grep -c "needs.plan.outputs.*== 'true'" "$FIX")
if [ "$N_POS" -eq 4 ]; then ok "L5-pos four positive plan predicates (gated jobs)"; else bad "L5-pos" "expected 4 positive predicates, found $N_POS"; fi
# No ${{ }} expression may appear inside either run: body (injection surface).
# The env: line above each body legitimately carries one; check extracted bodies.
if grep -q "\${{" "$TMP/verdict.sh" || grep -q "\${{" "$TMP/guard.sh"; then
  bad "L5-nointerp" "verdict run body interpolates an expression"
else
  ok "L5-nointerp verdict run body carries no expression interpolation"
fi

echo "RESULT PASS=$PASS FAIL=$FAIL SKIP=0"
[ "$FAIL" -eq 0 ]
