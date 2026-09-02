#!/usr/bin/env bash
# Structural checks for the port research tree (spec §8).
# Usage: scripts/check-research-tree.sh [repo-root]   (default: repo containing this script)
set -u
root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
index="$root/research/CLAUDE.md"
ledger="$root/docs/port/COMMONALITY.md"
fail=0
err() { printf 'FAIL: %s\n' "$*"; fail=1; }

# 1. index <-> prompt files, both directions
if [ ! -f "$index" ]; then
  err "missing $index"
else
  linked="$(grep -oE 'topics/[^) ]+\.prompt\.md' "$index" | sort -u)"
  for p in $linked; do
    [ -f "$root/research/$p" ] || err "index links missing prompt: research/$p"
  done
  if [ -d "$root/research/topics" ]; then
    while IFS= read -r f; do
      rel="${f#"$root/research/"}"
      printf '%s\n' "$linked" | grep -Fxq "$rel" || err "prompt not linked from index: research/$rel"
    done < <(find "$root/research/topics" -name '*.prompt.md' | sort)
  fi
fi

# 2. every prompt has the five H2 sections
sections=("## Context" "## Question" "## Required evidence" "## Answer template" "## Constraints")
if [ -d "$root/research/topics" ]; then
  while IFS= read -r f; do
    for s in "${sections[@]}"; do
      grep -Fxq "$s" "$f" || err "${f#"$root/"}: missing section '$s'"
    done
  done < <(find "$root/research/topics" -name '*.prompt.md' | sort)
fi

# 3. ledger verdicts are from the closed set; OVERRIDE rows have argument sections
if [ ! -f "$ledger" ]; then
  err "missing $ledger"
else
  # verdict is the 3rd cell of every data row in the ledger tables (| feature | origin | verdict | ...)
  while IFS= read -r v; do
    case "$v" in
      "COMMON → REUSE"|"COMMON → SUBSTITUTE"|"DIVERGENT"|"RUST-ONLY"|"OMIT") ;;
      "COMMON → OVERRIDE (OV-"[0-9][0-9]")")
        ov="${v#*(}"; ov="${ov%)}"
        if ! grep -Fxq "### $ov" "$ledger"; then
          err "ledger: $v has no '### $ov' section"
        else
          body="$(awk -v h="### $ov" '$0==h{p=1;next} /^### /{p=0} p' "$ledger")"
          printf '%s\n' "$body" | grep -Fq '**Argument:**' || err "ledger: $ov lacks **Argument:**"
          printf '%s\n' "$body" | grep -Fq '**Options:**'  || err "ledger: $ov lacks **Options:**"
        fi ;;
      *) err "ledger: verdict outside closed set: '$v'" ;;
    esac
  done < <(awk -F'|' '/^\|/ && NR>0 { gsub(/^ +| +$/,"",$4); if ($4!="" && $4!="Verdict" && $4 !~ /^-+$/) print $4 }' "$ledger")
fi

[ "$fail" -eq 0 ] && echo "OK: research tree structure valid"
exit "$fail"
