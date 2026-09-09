#!/usr/bin/env bash
# R07 empirical check orchestrator. Run from the review/empirical directory.
# Form (b) of the task's acceptable forms: `act` is not installed, so the
# recommended workflow is validated statically with actionlint, its
# paths-ignore filter is evaluated by an executed script against real commits
# of both pinned source repositories, and the result is cross-checked against
# the real GitHub Actions run history of the source repositories (REST).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
EVID="$HERE/../evidence"
mkdir -p "$EVID"
PY_REPO="$HOME/c/py-launch-blueprint"
PY_SHA=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TS_REPO="$HOME/c/ts-launch-blueprint"
TS_SHA=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
WF="$HERE/.github/workflows/update-contributors.yml"
status=0

echo "== toolchain =="
echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "os: $(sw_vers -productName) $(sw_vers -productVersion) $(uname -m)"
rustc --version; cargo --version
echo "actionlint: $(actionlint --version | head -1)"
python3 --version; python3 -c 'import yaml; print("pyyaml", yaml.__version__)'
echo "act: $(command -v act || echo 'not installed -> form (b)')"
echo "gh: $(gh --version | head -1)"
echo "cwd: $HERE"
echo

echo "== 1. actionlint on the recommended workflow (expect exit 0) =="
actionlint "$WF"; rc=$?; echo "exit: $rc"; [ $rc -eq 0 ] || status=1
echo

echo "== 2. actionlint on the ts-shape alternative, schedule + dispatch (expect exit 0: syntax does not decide the item) =="
actionlint "$HERE/alternatives/schedule-only.yml"; rc=$?; echo "exit: $rc"; [ $rc -eq 0 ] || status=1
echo

echo "== 3. actionlint on the negative fixture, paths-ignore under schedule (expect non-zero) =="
actionlint "$HERE/alternatives/schedule-with-paths-ignore.yml"; rc=$?; echo "exit: $rc"; [ $rc -ne 0 ] || status=1
echo

echo "== 4. paths-ignore filter evaluated against real first-parent commits =="
echo "-- py-launch-blueprint @ $PY_SHA, full history --"
python3 "$HERE/paths_filter.py" "$WF" "$PY_REPO" "$PY_SHA" "$EVID/py-paths-verdicts.json"; rc=$?; echo "exit: $rc"; [ $rc -eq 0 ] || status=1
echo
echo "-- ts-launch-blueprint @ $TS_SHA, full history --"
python3 "$HERE/paths_filter.py" "$WF" "$TS_REPO" "$TS_SHA" "$EVID/ts-paths-verdicts.json"; rc=$?; echo "exit: $rc"; [ $rc -eq 0 ] || status=1
echo

echo "== 5. cross-check against real GitHub Actions run history (REST, pages 20 s apart) =="
python3 "$HERE/real_runs.py" "$EVID/py-paths-verdicts.json" "$EVID"; rc=$?; echo "exit: $rc"; [ $rc -eq 0 ] || status=1
echo

echo "== 5b. push-range model of the same run history (merge-queue batching) =="
python3 "$HERE/analyze_runs.py" "$EVID/py-update-contributors-runs.json" "$EVID/py-paths-verdicts.json" "$PY_REPO"; rc=$?; echo "exit: $rc"; [ $rc -eq 0 ] || status=1
echo
echo "== 5c. why pushes are batched: rules on py main (REST, 1 call) =="
gh api repos/smorinlabs/py-launch-blueprint/rules/branches/main --jq '[.[] | .type] | unique'
echo

echo "== 6. pinned source on: blocks, quoted from the pinned trees =="
echo "-- py @ $PY_SHA lines 3-9 --"
git -C "$PY_REPO" show "$PY_SHA:.github/workflows/update-contributors.yml" | sed -n 3,9p
echo "-- ts @ $TS_SHA lines 33-39 and 49-52 --"
git -C "$TS_REPO" show "$TS_SHA:.github/workflows/update-contributors.yml" | sed -n '33,39p;49,52p'
echo
echo "overall status: $status"
exit $status
