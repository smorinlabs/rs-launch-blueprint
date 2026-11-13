#!/usr/bin/env bash
# The search patterns contain literal backticks by design (Markdown code spans), never expansions.
# shellcheck disable=SC2016
# R30 check D — the upstream text this decision quotes, fetched fresh through the GitHub
# contents endpoint (GET https://api.github.com/repos/<o>/<r>/contents/<path>), with the blob
# sha and the matching line numbers, so every quotation can be re-read at the cited line.
# Usage: bash r30-upstream-docs.sh > r30-upstream-docs.log 2>&1   (needs `gh` authenticated)
set -uo pipefail

echo "# r30-upstream-docs.sh  run $(date -u +%Y-%m-%dT%H:%M:%SZ)  gh $(gh --version | head -1 | cut -d' ' -f3)"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/r30-docs.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

fails=0
# show REPO PATH PATTERN... — fetch one file, print its blob sha, then every line matching each pattern
show() {
  local repo=$1 path=$2; shift 2
  local f sha
  f="$TMP/$(basename "$path")"
  echo
  echo "== $repo $path"
  if ! sha=$(gh api "repos/$repo/contents/$path" --jq .sha 2>&1); then
    echo "FETCH FAILED: $sha"; fails=$((fails+1)); return
  fi
  gh api -H 'Accept: application/vnd.github.raw' "repos/$repo/contents/$path" > "$f"
  echo "blob $sha, $(wc -l < "$f" | tr -d ' ') lines"
  local pat n
  for pat in "$@"; do
    n=$(grep -c -F -- "$pat" "$f")
    if (( n == 0 )); then echo "MISSING: $pat"; fails=$((fails+1)); continue; fi
    grep -n -F -- "$pat" "$f" | head -3 | cut -c1-240
  done
}

show rust-lang/cargo doc/book/src/guide/continuous-integration.md \
  '## Checking for warnings' \
  "Customarily, projects want to be" \
  'build.warnings = "deny"' \
  'can be used to fail a CI job' \
  'toolchain'
show rust-lang/cargo doc/book/src/reference/config.md \
  '#### `build.warnings`' \
  '`deny`'
show rust-lang/cargo doc/book/src/CHANGELOG.md \
  '## Cargo 1.97' \
  'Stabilize `build.warnings`' \
  '## Cargo 1.74' \
  'The `[lints]` table has been stabilized'
show rust-lang/cargo doc/book/src/reference/manifest.md \
  '## The `[lints]` section' \
  'priority'
show rust-lang/rust src/doc/rustc/src/lints/levels.md \
  '## expect' \
  'reason'
show rust-lang/rust-analyzer crates/rust-analyzer/src/config.rs \
  'check_command | checkOnSave_command: String' \
  'cargo_allTargets: bool' \
  'cargo_features: CargoFeaturesDef' \
  'check_workspace: bool' \
  'checkOnSave | checkOnSave_enable: bool' \
  'check_features | checkOnSave_features' \
  'cargo_targetDir | rust_analyzerTargetDir'

echo
echo "# summary: failures=$fails"
exit "$fails"
