#!/usr/bin/env bash
# R28 revision 1 — the py precedent behind BASELINE-REVIEW F093 (raw/opus.md
# E10), rerun offline. It shows what `fix = true` does to a `ruff check` gate:
# a fully fixable violation is rewritten and the run exits 0. The ruff binary
# is an already-installed mise build; RUFF defaults to that path and may be
# overridden. Every case prints PASS or FAIL; exit 1 on any FAIL.
set -uo pipefail

fails=0
pass() { printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s — %s\n' "$1" "$2"; fails=$((fails + 1)); }

RUFF=${RUFF:-$HOME/.local/share/mise/installs/ruff/0.15.15/ruff-aarch64-apple-darwin/ruff}
echo "== ruff: $RUFF"
"$RUFF" --version || { echo "FAIL R0 — ruff not runnable"; exit 1; }

scratch=$(mktemp -d "${TMPDIR:-/tmp}/r28-ruff.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
cd "$scratch" || exit 1
echo "== scratch: $scratch (outside any repository)"

cat > pyproject.toml <<'EOF'
[tool.ruff]
fix = true

[tool.ruff.lint]
select = ["F"]
EOF
printf 'import os\n' > m.py

echo
echo "== R1 with fix = true, 'ruff check .' rewrites the file and exits 0"
echo '$ ruff check .'
out=$("$RUFF" check --no-cache . 2>&1); rc=$?
printf '%s\n' "$out"
size=$(wc -c < m.py | tr -d ' ')
echo "m.py size after: $size bytes"
if [ "$rc" -eq 0 ] && grep -q 'Found 1 error (1 fixed, 0 remaining)' <<<"$out" && [ "$size" -eq 0 ]; then
  pass R1 "exit $rc; the unused import was removed"
else
  fail R1 "exit $rc, size $size"
fi

echo
echo "== R2 control: --no-fix reports the same violation and exits 1"
printf 'import os\n' > m.py
echo '$ ruff check --no-fix .'
out=$("$RUFF" check --no-cache --no-fix . 2>&1); rc=$?
printf '%s\n' "$out" | tail -n 3
if [ "$rc" -eq 1 ] && grep -q 'F401' <<<"$out"; then
  pass R2 "exit $rc"
else
  fail R2 "exit $rc"
fi

echo
echo "== summary: $fails failing case(s)"
[ "$fails" -eq 0 ]
