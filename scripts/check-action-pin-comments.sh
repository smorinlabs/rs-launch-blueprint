#!/usr/bin/env bash
# check-action-pin-comments.sh — enforce R20 part 3.2 version-comment grammar.
#
# Every active (non-commented) `uses:` clause carrying a 40-hex commit SHA pin
# in `.github/workflows/` must end with a release-version comment matching:
#   @[0-9a-f]{40}[[:space:]]+#[[:space:]]v?[0-9]+(\.[0-9]+)*[[:space:]]*$
set -euo pipefail

dir="${1:-.github/workflows}"
if [ ! -d "$dir" ]; then
  echo "error: workflows directory not found: $dir" >&2
  exit 2
fi

comment_re='^[[:space:]]*#'
sha_uses_re='^[[:space:]]*(-[[:space:]]+)?uses:[[:space:]]*[^#]*@[0-9a-f]{40}([[:space:]]|$|#)'
pin_re='@[0-9a-f]{40}[[:space:]]+#[[:space:]]v?[0-9]+(\.[0-9]+)*[[:space:]]*$'
status=0
found_any=0

shopt -s nullglob
for file in "$dir"/*.yml "$dir"/*.yaml; do
  [ -f "$file" ] || continue
  found_any=1
  lineno=0
  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))
    # Skip comment-only lines.
    if [[ "$line" =~ $comment_re ]]; then
      continue
    fi
    # Match active `uses:` clauses that carry a 40-hex SHA pin.
    if [[ "$line" =~ $sha_uses_re ]]; then
      if ! [[ "$line" =~ $pin_re ]]; then
        printf 'FAIL [R20 pin comment]: %s:%d: SHA-pinned uses clause must end with "# vX.Y.Z" (matching %s): %s\n' \
          "$file" "$lineno" "$pin_re" "$line" >&2
        status=1
      fi
    fi
  done <"$file"
done

if [ "$found_any" -eq 0 ]; then
  echo "error: no workflow files found in $dir" >&2
  exit 2
fi

exit "$status"
