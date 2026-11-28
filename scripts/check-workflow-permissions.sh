#!/usr/bin/env bash
# check-workflow-permissions.sh — enforce R08 workflow token hardening policy.
#
# Rule 1: Every workflow file in `.github/workflows/` must declare top-level
#         `permissions: {}` at column 0. Exact-basename exemption:
#         `difftree-pr-comment.yml` (vendor-canonical template, F062/R08/R20).
# Rule 2: Every explicit `persist-credentials` setting other than `false`
#         (any quoting, case, or expression) must carry a non-empty trailing
#         reason comment (`# ...`), and `persist-credentials` must not appear
#         inside a flow-style YAML mapping (`{ ... }`).
#         (Unset `persist-credentials` on `actions/checkout` is owned by zizmor
#         `artipacked` at the default persona.)
set -euo pipefail

dir="${1:-.github/workflows}"
if [ ! -d "$dir" ]; then
  echo "error: workflows directory not found: $dir" >&2
  exit 2
fi

status=0
found_any=0

shopt -s nullglob
for file in "$dir"/*.yml "$dir"/*.yaml; do
  [ -f "$file" ] || continue
  found_any=1
  base=$(basename "$file")

  # Rule 1: column-0 `permissions: {}` (exempting exact basename difftree-pr-comment.yml).
  if [ "$base" != "difftree-pr-comment.yml" ]; then
    if ! grep -Eq '^permissions:[[:space:]]*\{\}[[:space:]]*(#.*)?$' "$file"; then
      printf 'FAIL [R08 top-level permissions]: %s must declare column-0 "permissions: {}"\n' "$file" >&2
      status=1
    fi
  fi

  # Rule 2: check every non-comment line mentioning `persist-credentials`.
  lineno=0
  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))
    # Skip comment-only lines.
    if printf '%s\n' "$line" | grep -Eq '^[[:space:]]*#'; then
      continue
    fi
    if ! printf '%s\n' "$line" | grep -Eq '(^|[[:space:]{,])persist-credentials[[:space:]]*:'; then
      continue
    fi
    # Reject flow-style mappings containing persist-credentials.
    if printf '%s\n' "$line" | grep -Eq '\{[^#]*persist-credentials[[:space:]]*:'; then
      printf 'FAIL [R08 flow-style persist-credentials]: %s:%d: use block style for persist-credentials\n' "$file" "$lineno" >&2
      status=1
      continue
    fi
    # Extract value and optional trailing comment.
    rhs=$(printf '%s\n' "$line" | sed -E 's/^.*persist-credentials[[:space:]]*:[[:space:]]*//')
    val=$(printf '%s\n' "$rhs" | sed -E 's/[[:space:]]*#.*$//' | sed -E 's/[[:space:]]+$//')
    # Accept false / 'false' / "false" (case-insensitive) unconditionally.
    lower_val=$(printf '%s\n' "$val" | tr '[:upper:]' '[:lower:]')
    case "$lower_val" in
      false | "'false'" | '"false"')
        continue
        ;;
    esac
    # Any other explicit value requires a non-empty trailing `# ...` reason comment.
    if ! printf '%s\n' "$rhs" | grep -Eq '#[[:space:]]*[^[:space:]]'; then
      printf 'FAIL [R08 persist-credentials exception]: %s:%d: non-false persist-credentials (%s) requires a trailing reason comment\n' "$file" "$lineno" "$val" >&2
      status=1
    fi
  done <"$file"
done

if [ "$found_any" -eq 0 ]; then
  echo "error: no workflow files found in $dir" >&2
  exit 2
fi

exit "$status"
