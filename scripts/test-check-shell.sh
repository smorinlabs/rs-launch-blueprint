#!/usr/bin/env bash
# Regression tests for check-shell.sh's frozen-evidence baseline.
# Each case builds a throwaway git repository holding a copy of the checker.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
pass=0; fail=0
evidence="research/runs/R01/run/review/evidence/check.sh"
# A recorded evidence script with a ShellCheck finding (SC2148: no shebang).
finding='echo "recorded evidence"'

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
  else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

fresh() {
  t="$(mktemp -d)"
  mkdir -p "$t/scripts" "$t/$(dirname "$evidence")"
  cp "$here/check-shell.sh" "$t/scripts/check-shell.sh"
  printf '%s\n' "$finding" > "$t/$evidence"
  : > "$t/scripts/shellcheck-evidence-baseline.txt"
  git -C "$t" init -q
}

baseline() {
  printf '%s  %s\n' "$(sha256 "$t/$1")" "$1" >> "$t/scripts/shellcheck-evidence-baseline.txt"
}

run_check() {
  git -C "$t" add -A
  (cd "$t" && bash scripts/check-shell.sh >/dev/null 2>&1)
}

expect() {
  local want="$1" name="$2" rc=0
  run_check || rc=$?
  if { [ "$want" = ok ] && [ "$rc" -eq 0 ]; } || { [ "$want" = fail ] && [ "$rc" -ne 0 ]; }; then
    echo "ok   $name"; pass=$((pass+1))
  else
    echo "FAIL $name (exit $rc, wanted $want)"; fail=$((fail+1))
  fi
  rm -rf "$t"
}

fresh; expect fail "unlisted evidence script is linted"
fresh; baseline "$evidence"; expect ok "listed evidence script with unchanged bytes is skipped"
fresh; baseline "$evidence"; printf '%s\n' "$finding" >> "$t/$evidence"
expect fail "listed evidence script whose bytes changed is linted"
fresh; baseline "$evidence"; printf '%s\n' "$finding" > "$t/$(dirname "$evidence")/new.sh"
expect fail "new evidence script beside a listed one is linted"
fresh; printf '%s\n' "$finding" > "$t/scripts/tool.sh"; baseline scripts/tool.sh; baseline "$evidence"
expect fail "baseline entries outside research/runs/ are ignored"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
