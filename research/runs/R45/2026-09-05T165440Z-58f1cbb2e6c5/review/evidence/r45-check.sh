#!/usr/bin/env bash
# R45 empirical check — verifies the three R18-derived claims the Opus raw's
# recommendation rests on, plus the two source-repo facts. Verification only:
# no source-repository, template or workflow file is written, no workflow is
# enabled and no bot is invoked. It writes its own stdout (redirected to the
# evidence log by the recorded command) and four intermediate downloads into a
# private mktemp -d directory removed on exit: action-v1.0.220.yml,
# trigger-v1.0.220.ts, greptile-llms-full.txt and greptile-err.txt.
set -uo pipefail
REPO=/Users/stevemorin/c/rs-launch-blueprint-p02-plan
PY=~/c/py-launch-blueprint
TS=~/c/ts-launch-blueprint
PYPIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TSPIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
ACTPIN=19dda84776b3518d98b8798e591daee763049ed3   # anthropics/claude-code-action v1.0.220
SCRATCH="$(mktemp -d)"                            # private temp dir; removed on exit
trap 'rm -rf "$SCRATCH"' EXIT

echo "# r18-trigger-phrase-pin.log"
echo "captured: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "host toolchain:"
rustc --version 2>&1 | sed 's/^/  /'
cargo --version 2>&1 | sed 's/^/  /'
echo "  OS: $(sw_vers -productName) $(sw_vers -productVersion) $(uname -m)"
echo "  gh: $(gh --version | head -1)"
echo "working directory: $REPO"
echo

echo "=== C1 — R18 claim 2: review lane trigger types (no 'synchronize') ==="
grep -n 'claude-code-review.yml' "$REPO/research/topics/18-ai-assisted-review-workflows/DECISION.md" \
  | head -1 | cut -c1-260
echo "--- R18's own statement of the consequence (DECISION.md:316) ---"
sed -n '316p' "$REPO/research/topics/18-ai-assisted-review-workflows/DECISION.md" | cut -c1-420
echo "--- assistant lane events (DECISION.md:12) ---"
sed -n '12p' "$REPO/research/topics/18-ai-assisted-review-workflows/DECISION.md" | cut -c1-200
echo

echo "=== C2 — R18 claim 1: which vendor bots R18 configures ==="
echo "grep -n -ci over R18/DECISION.md:"
for v in coderabbit greptile cubic; do
  printf '  %-12s hits=%s\n' "$v" "$(grep -o -i "$v" "$REPO/research/topics/18-ai-assisted-review-workflows/DECISION.md" | wc -l | tr -d ' ')"
done
echo "--- the only hit, DECISION.md:96 ---"
sed -n '96p' "$REPO/research/topics/18-ai-assisted-review-workflows/DECISION.md"
echo

echo "=== C3 — action.yml trigger_phrase input at the pin R18 names (v1.0.220 = $ACTPIN) ==="
gh api "repos/anthropics/claude-code-action/contents/action.yml?ref=$ACTPIN" --jq '.content' \
  | base64 -d > "$SCRATCH/action-v1.0.220.yml"
echo "GET repos/anthropics/claude-code-action/contents/action.yml?ref=$ACTPIN -> $(wc -c < "$SCRATCH/action-v1.0.220.yml" | tr -d ' ') bytes"
grep -n -A3 '^  trigger_phrase:' "$SCRATCH/action-v1.0.220.yml"
echo

echo "=== C4 — R18 claim 3: does the action scan pull-request BODIES for the trigger phrase, at the pin? ==="
gh api "repos/anthropics/claude-code-action/contents/src/github/validation/trigger.ts?ref=$ACTPIN" --jq '.content' \
  | base64 -d > "$SCRATCH/trigger-v1.0.220.ts"
echo "GET repos/anthropics/claude-code-action/contents/src/github/validation/trigger.ts?ref=$ACTPIN -> $(wc -c < "$SCRATCH/trigger-v1.0.220.ts" | tr -d ' ') bytes"
echo "--- automation-mode early return (prompt set => trigger phrase never consulted) ---"
sed -n '14,23p' "$SCRATCH/trigger-v1.0.220.ts"
echo "--- pull-request body/title scan ---"
sed -n '77,102p' "$SCRATCH/trigger-v1.0.220.ts"
echo

echo "=== C5 — is the PR-body scan reachable under R18's assistant lane shape? py claude.yml at $PYPIN ==="
git -C "$PY" show "$PYPIN:.github/workflows/claude.yml" | sed -n '1,20p'
echo "--- event names named in the on: block and in the job-level if: ---"
git -C "$PY" show "$PYPIN:.github/workflows/claude.yml" | grep -c "github.event_name == 'pull_request'" \
  | sed "s/^/  clauses matching github.event_name == 'pull_request' (exact): /"
echo

echo "=== C6 — source-repo templates at their pins (F204 divergence) ==="
echo "--- py .github/pull_request_template.md, the Review Trigger block ---"
git -C "$PY" show "$PYPIN:.github/pull_request_template.md" | grep -n -A7 '^## Review Trigger'
echo "--- ts .github/pull_request_template.md: any bot @-mention or Review Trigger heading? ---"
git -C "$TS" show "$TSPIN:.github/pull_request_template.md" \
  | grep -n -iE 'review trigger|@coderabbit|@greptile|@cubic|@claude' || echo "  (no match — ts ships no trigger block)"
echo

echo "=== C7 — Opus's 'documented but not wired' finding: py's vendor bot configs at $PYPIN ==="
git -C "$PY" ls-tree -r --name-only "$PYPIN" | grep -iE 'coderabbit|greptile|cubic' || echo "  (none)"
echo

echo "=== C8 — Greptile's currently documented handle (both raws assert @greptileai; not load-bearing) ==="
if curl -fsS --max-time 25 https://www.greptile.com/docs/llms-full.txt -o "$SCRATCH/greptile-llms-full.txt" 2>"$SCRATCH/greptile-err.txt"; then
  echo "GET https://www.greptile.com/docs/llms-full.txt -> $(wc -c < "$SCRATCH/greptile-llms-full.txt" | tr -d ' ') bytes"
  printf '  @greptileai occurrences:   %s\n' "$(grep -o '@greptileai' "$SCRATCH/greptile-llms-full.txt" | wc -l | tr -d ' ')"
  printf '  @greptile-apps occurrences: %s\n' "$(grep -o '@greptile-apps' "$SCRATCH/greptile-llms-full.txt" | wc -l | tr -d ' ')"
  grep -m3 -n '@greptileai' "$SCRATCH/greptile-llms-full.txt" | cut -c1-200
else
  echo "  fetch failed: $(cat "$SCRATCH/greptile-err.txt")"
  echo "  RECORDED AS UNVERIFIED HERE — the handle divergence is asserted by both raws and is not load-bearing"
fi
echo
echo "=== end of checks ==="
echo
echo "=== script source (emitted by this script, so the log is self-contained) ==="
cat "$0"
