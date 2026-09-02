#!/usr/bin/env bash
# Structural checks for the port research tree (spec §8).
# Usage: scripts/check-research-tree.sh [repo-root]   (default: repo containing this script)
set -u
root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
index="$root/research/CLAUDE.md"
ledger="$root/docs/port/COMMONALITY.md"
topics="$root/research/topics"
fail=0
err() { printf 'FAIL: %s\n' "$*"; fail=1; }
prompts() { [ -d "$topics" ] && find "$topics" -name '*.prompt.md' | sort; }

# 1. index <-> prompt files, both directions
if [ ! -f "$index" ]; then
  err "missing $index"
else
  linked="$(grep -oE 'topics/[^) ]+\.prompt\.md' "$index" | sort -u)"
  for p in $linked; do
    [ -f "$root/research/$p" ] || err "index links missing prompt: research/$p"
  done
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    rel="${f#"$root/research/"}"
    printf '%s\n' "$linked" | grep -Fxq "$rel" || err "prompt not linked from index: research/$rel"
  done < <(prompts)
fi

# 2. every prompt has the eight H2 sections (spec §7)
sections=("## Objective" "## Context" "## Out of scope" "## Couplings" "## Questions" "## Required evidence" "## Answer template" "## Constraints")
while IFS= read -r f; do
  [ -n "$f" ] || continue
  for s in "${sections[@]}"; do
    grep -Fxq "$s" "$f" || err "${f#"$root/"}: missing section '$s'"
  done
done < <(prompts)

# 3. couplings: every parameter owned by exactly one prompt; every consumed pair has that owner (spec §6.3)
#    prompt lines:  - owns: a, b        - consumes: R03: async-runtime
owners=""   # lines "param<TAB>R##"
while IFS= read -r f; do
  [ -n "$f" ] || continue
  id="$(grep -oE '^- id: R[0-9]{2}' "$f" | head -1 | sed 's/^- id: //')"
  [ -n "$id" ] || { err "${f#"$root/"}: Couplings section has no '- id: R##' line"; continue; }
  for p in $(grep -E '^- owns:' "$f" | sed 's/^- owns://' | tr ',' ' '); do
    owners="$owners$p	$id
"
  done
done < <(prompts)
printf '%s' "$owners" | cut -f1 | sort | uniq -d | while IFS= read -r dup; do
  err "parameter owned by more than one item: $dup ($(printf '%s' "$owners" | awk -F'\t' -v p="$dup" '$1==p{print $2}' | paste -sd, -))"
done
while IFS= read -r f; do
  [ -n "$f" ] || continue
  grep -E '^- consumes:' "$f" | sed 's/^- consumes://' | tr ';' '\n' | while IFS= read -r c; do
    c="$(printf '%s' "$c" | sed 's/^ *//;s/ *$//')"; [ -n "$c" ] || continue
    rid="${c%%:*}"; par="$(printf '%s' "${c#*:}" | sed 's/^ *//;s/ *$//')"
    printf '%s' "$owners" | grep -Fxq "$par	$rid" || err "${f#"$root/"}: consumes '$c' but $rid does not own '$par'"
  done
done < <(prompts)

# 4. ledger verdicts are from the closed set; OVERRIDE rows have argument sections
if [ ! -f "$ledger" ]; then
  err "missing $ledger"
else
  # verdict is the 3rd cell of every data row (| feature | origin | verdict | ...)
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
  done < <(awk -F'|' '/^\|/ { gsub(/^ +| +$/,"",$4); if ($4!="" && $4!="Verdict" && $4 !~ /^-+$/) print $4 }' "$ledger")
fi

# 5. index rows marked resolved have DECISION.md + both audit files in the topic dir (spec §10)
if [ -f "$index" ]; then
  while IFS= read -r line; do
    link="$(printf '%s' "$line" | grep -oE 'topics/[^) ]+\.prompt\.md' | head -1)"; [ -n "$link" ] || continue
    status="$(printf '%s' "$line" | awk -F'|' '{gsub(/^ +| +$/,"",$(NF-1)); print $(NF-1)}')"
    [ "$status" = "resolved" ] || continue
    tdir="$root/research/${link%/prompts/*}"
    for need in DECISION.md audit-codex.md audit-fable.md; do
      [ -f "$tdir/$need" ] || err "index: ${link%%/prompts/*} is resolved but lacks $need"
    done
  done < <(grep -E '^\| *R[0-9]{2} *\|' "$index")
fi

[ "$fail" -eq 0 ] && echo "OK: research tree structure valid"
exit "$fail"
