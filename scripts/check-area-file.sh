#!/usr/bin/env bash
# Structural check for one docs/port/areas/<area>.md survey file (spec §6.2).
# Usage: scripts/check-area-file.sh <file>   → exit 0 "OK: <file>" or exit 1 with FAIL lines.
set -uf
f="${1:?usage: check-area-file.sh <file>}"; fail=0
err() { printf 'FAIL: %s: %s\n' "$f" "$*"; fail=1; }
[ -s "$f" ] || { err "missing or empty"; exit 1; }
hdr='| feature | py | ts | origin | ts-decisions | notes |'
hdr_id='| id | feature | py | ts | origin | ts-decisions | notes |'
grep -qxF -- "$hdr" "$f" || grep -qxF -- "$hdr_id" "$f" || err "table header must be exactly: $hdr (or with a leading id column after Phase 2)"
[ "$(grep -c '^|' "$f")" -gt 2 ] || err "table has no data rows"
has_id=0; grep -qxF -- "$hdr_id" "$f" && has_id=1
# data rows: skip header and separator; awk -F'|' gives leading empty field
while IFS= read -r line; do
  case "$line" in '| feature |'*|'| id |'*|'|---'*) continue ;; esac
  n=$(printf '%s' "$line" | awk -F'|' '{print NF-2}')
  if [ "$n" -eq 7 ] && [ "$has_id" -eq 1 ]; then off=1; elif [ "$n" -eq 6 ]; then off=0; else err "row has $n cells, want 6 (or 7 with id): $line"; continue; fi
  feat=$(printf '%s' "$line" | awk -F'|' -v o="$off" '{gsub(/^ +| +$/,"",$(2+o)); print $(2+o)}')
  py=$(printf '%s' "$line"   | awk -F'|' -v o="$off" '{gsub(/^ +| +$/,"",$(3+o)); print $(3+o)}')
  ts=$(printf '%s' "$line"   | awk -F'|' -v o="$off" '{gsub(/^ +| +$/,"",$(4+o)); print $(4+o)}')
  org=$(printf '%s' "$line"  | awk -F'|' -v o="$off" '{gsub(/^ +| +$/,"",$(5+o)); print $(5+o)}')
  [ -n "$feat" ] || err "empty feature cell: $line"
  case "$org" in
    same|different|py-only|ts-only) ;;
    none) [ "$py" = "—" ] && [ "$ts" = "—" ] || err "none rows have no citations: $feat" ;;
    *) err "origin '$org' not in same|different|py-only|ts-only|none: $feat" ;;
  esac
  cite='`[^`]*:[0-9][0-9]*`'
  case "$org" in
    same|different) printf '%s' "$py" | grep -Eq "$cite" || err "py cell needs \`path:line\`: $feat"
                    printf '%s' "$ts" | grep -Eq "$cite" || err "ts cell needs \`path:line\`: $feat" ;;
    py-only) printf '%s' "$py" | grep -Eq "$cite" || err "py cell needs \`path:line\`: $feat"; [ "$ts" = "—" ] || err "ts cell must be — for py-only: $feat" ;;
    ts-only) printf '%s' "$ts" | grep -Eq "$cite" || err "ts cell needs \`path:line\`: $feat"; [ "$py" = "—" ] || err "py cell must be — for ts-only: $feat" ;;
  esac
done < <(grep '^|' "$f")
for s in '## Language-bound tools' '## Cross-area parameters' '## Files read'; do grep -qxF -- "$s" "$f" || err "missing section '$s'"; done
grep -q '^- py: `' "$f" || err "Files read: no '- py:' line"
grep -q '^- ts: `' "$f" || err "Files read: no '- ts:' line"
while IFS= read -r p; do
  printf '%s' "$p" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' || err "cross-area parameter '$p' is not a lowercase-kebab slug"
done < <(awk '/^## Cross-area parameters/{on=1;next} /^## /{on=0} on && /^- `/{sub(/^- `/,""); sub(/`.*/,""); print}' "$f")
[ "$fail" -eq 0 ] && echo "OK: $f"; exit "$fail"
