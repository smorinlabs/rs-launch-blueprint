#!/usr/bin/env bash
# R79 prometheus-metrics — synthesizer re-verification of the GitHub figures the
# Opus report cites for the five shortlisted repositories.
#
# Rate discipline: keyring-authenticated `gh api`, one call every 20 seconds, per
# the repository's standing instruction. Ten calls, so a full run takes about
# three and a half minutes.
#
# Reproducibility rule, stated because most of these are live counters:
# `full_name` and `archived` must be byte-equal to the snapshot under snapshots/,
# and `archived` flipping to true is exactly the maintenance signal this check
# exists to catch. `stargazers_count`, `pushed_at` and the issue search's
# `total_count` all move in both directions -- stars fall when people unstar and
# a force-push can move `pushed_at` backwards -- so those three are printed as
# direction of travel and none of them is asserted. Every figure carries its
# retrieval date.
#
# No token bytes and no personal email address are written by this script.
# Exits non-zero if any check FAILs. Every SKIP is named.

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
snaps="$here/snapshots"
mkdir -p "$snaps"

PACE=20

pass_count=0
fail_count=0
skip_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS  %s\n' "$*"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL  %s\n' "$*"; }
skip() { skip_count=$((skip_count + 1)); printf 'SKIP  %s\n' "$*"; }

scratch="$(mktemp -d "${TMPDIR:-/tmp}/rslb-r79-gh.XXXXXX")"
# shellcheck disable=SC2329  # invoked indirectly by the EXIT trap below
cleanup() { rm -rf "$scratch"; }
trap cleanup EXIT

echo "== environment =="
printf 'date-utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'pace: one gh api call every %s seconds\n' "$PACE"
if ! command -v gh > /dev/null 2>&1; then
  skip "every GitHub figure (the gh CLI is not installed on this machine)"
  echo
  echo "== summary =="
  printf 'PASS=%s FAIL=%s SKIP=%s TOTAL=%s\n' \
    "$pass_count" "$fail_count" "$skip_count" "$((pass_count + fail_count + skip_count))"
  exit 0
fi
if ! gh auth status > /dev/null 2>&1; then
  skip "every GitHub figure (gh is installed but not authenticated in this shell)"
  echo
  echo "== summary =="
  printf 'PASS=%s FAIL=%s SKIP=%s TOTAL=%s\n' \
    "$pass_count" "$fail_count" "$skip_count" "$((pass_count + fail_count + skip_count))"
  exit 0
fi
gh --version | head -1
echo

first=1
paced() { # run a command after the inter-call pause (skipped before the first call)
  if [ "$first" -eq 1 ]; then
    first=0
  else
    sleep "$PACE"
  fi
  "$@"
}

check_repo() { # owner/repo
  local slug="$1"
  local owner="${slug%%/*}"
  local repo="${slug##*/}"
  local repo_json="$scratch/${owner}__${repo}.repo.json"
  local issues_json="$scratch/${owner}__${repo}.issues.json"

  if ! paced gh api "repos/$slug" > "$repo_json" 2> "$scratch/err.txt"; then
    fail "GET https://api.github.com/repos/$slug failed"
    sed 's/^/      | /' "$scratch/err.txt"
    return
  fi
  # zsh globbing would eat an unquoted ? & + in this query string.
  if ! paced gh api "search/issues?q=repo:$slug+is:issue+is:open" > "$issues_json" 2> "$scratch/err.txt"; then
    fail "GET https://api.github.com/search/issues?q=repo:$slug+is:issue+is:open failed"
    sed 's/^/      | /' "$scratch/err.txt"
    return
  fi

  python3 - "$slug" "$repo_json" "$issues_json" "$snaps" <<'PY'
import json, os, sys
slug, repo_path, issues_path, snapdir = sys.argv[1:5]
repo = json.load(open(repo_path))
issues = json.load(open(issues_path))
row = {
    "full_name": repo["full_name"],
    "stargazers_count": repo["stargazers_count"],
    "archived": repo["archived"],
    "pushed_at": repo["pushed_at"],
    "open_issues_search_total": issues["total_count"],
    "open_issues_count_field": repo["open_issues_count"],
}
print("      | %-34s stars=%-6s archived=%-6s pushed_at=%s open issues (search total_count)=%s "
      "[the repo object's own open_issues_count, which the prompt forbids, is %s]" % (
          row["full_name"], row["stargazers_count"], row["archived"],
          row["pushed_at"], row["open_issues_search_total"], row["open_issues_count_field"]))
snap = os.path.join(snapdir, slug.replace("/", "__") + ".github.json")
problems = []
if os.path.exists(snap):
    old = json.load(open(snap))
    if old["full_name"] != row["full_name"]:
        problems.append("full_name changed %r -> %r" % (old["full_name"], row["full_name"]))
    if old["archived"] != row["archived"]:
        problems.append("archived changed %r -> %r" % (old["archived"], row["archived"]))
    # Stars fall when people unstar, and a force-push can move pushed_at
    # backwards. Both are printed as direction of travel and neither is
    # asserted; asserting them would make an honest rerun fail. `full_name`
    # and `archived` are the fields a rerun must reproduce, and `archived`
    # flipping is exactly the maintenance signal this check exists to catch.
    print("      |   since the snapshot: stars %+d, pushed_at %s -> %s (printed, not asserted)"
          % (row["stargazers_count"] - old["stargazers_count"],
             old["pushed_at"], row["pushed_at"]))
    if problems:
        print("MISMATCH " + slug + ": " + "; ".join(problems))
        sys.exit(3)
    print("SNAPCMP " + slug + ": full_name and archived equal to the snapshot")
else:
    with open(snap, "w") as handle:
        json.dump(row, handle, indent=2, sort_keys=True)
        handle.write("\n")
    print("SNAPNEW " + slug + ": snapshot written")
if row["archived"]:
    print("ARCHIVED " + slug)
    sys.exit(4)
PY
  case $? in
    0) pass "$slug: not archived, and its identity fields agree with the recorded snapshot" ;;
    4) fail "$slug is ARCHIVED -- the maintenance rubric verdict must be re-read" ;;
    *) fail "$slug: full_name or archived disagrees with the recorded snapshot" ;;
  esac
}

echo "== GitHub repository figures =="
echo "   endpoints: GET https://api.github.com/repos/<o>/<r>  (stargazers_count, archived, pushed_at)"
echo "              GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open  (total_count)"
echo "   The prompt requires total_count from the search endpoint and forbids open_issues_count;"
echo "   both are printed so the difference between them is visible rather than asserted."
echo
for slug in metrics-rs/metrics Ptrskay3/axum-prometheus tikv/rust-prometheus \
            prometheus/client_rust open-telemetry/opentelemetry-rust; do
  check_repo "$slug"
done
echo

echo "== summary =="
printf 'PASS=%s FAIL=%s SKIP=%s TOTAL=%s\n' \
  "$pass_count" "$fail_count" "$skip_count" "$((pass_count + fail_count + skip_count))"
if [ "$fail_count" -ne 0 ]; then
  exit 1
fi
exit 0
