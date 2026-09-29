#!/bin/sh
# check-large-files.sh - R14 reference: one rule, two tiers.
#   --staged           hook tier: every blob the index would commit (added or modified)
#   --range BASE HEAD  CI tier: every blob any commit in BASE..HEAD introduces;
#                      an empty or all-zero BASE checks all of HEAD's history
# Rule: a blob larger than 1048576 bytes (1 MiB) fails unless .gitattributes
# gives its path the attribute large-file-ok. Git LFS pointers are small blobs.
# Exit 0 pass, 1 violation, 2 usage or git error (fails closed).
set -eu
max=1048576
tmp=$(mktemp) || exit 2
trap 'rm -f "$tmp" "$tmp.sizes" "$tmp.objs"' EXIT

list_staged() {
  # :oldmode newmode oldsha newsha status<TAB>path ; gitlinks (160000) are not blobs
  git -c core.quotePath=false diff --cached --no-renames --no-ext-diff --raw \
    --diff-filter=AMT >"$tmp" || exit 2
  awk -F '\t' '{ split($1, m, " "); if (m[2] != "160000") print m[4] " " $2 }' "$tmp" >"$tmp.objs" || exit 2
  mv "$tmp.objs" "$tmp"
}

list_range() {
  base=$1 head=$2
  case "$base" in ''|0000000000000000000000000000000000000000) range=$head ;; *) range="$base..$head" ;; esac
  git -c core.quotePath=false rev-list --objects "$range" >"$tmp" || exit 2
}

case "${1:-}" in
  --staged) [ $# -eq 1 ] || exit 2; list_staged ;;
  --range) [ $# -eq 3 ] || exit 2; list_range "$2" "$3" ;;
  *) echo "usage: $0 --staged | --range BASE HEAD" >&2; exit 2 ;;
esac

git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' <"$tmp" >"$tmp.sizes" || exit 2
status=0
while IFS=' ' read -r type size path; do
  [ "$type" = blob ] && [ "$size" -gt "$max" ] || continue
  if [ "$(git check-attr --cached large-file-ok -- "$path" | sed 's/.*: large-file-ok: //')" = set ]; then
    echo "ALLOW: $path is $size bytes (large-file-ok)"
    continue
  fi
  echo "FAIL: $path is $size bytes (> $max). Remove it, track it with Git LFS, or mark it large-file-ok in .gitattributes." >&2
  status=1
done <"$tmp.sizes"
rm -f "$tmp.sizes"
exit "$status"
