#!/usr/bin/env bash
# Structural checks for the port research tree (spec §8).
# Usage: scripts/check-research-tree.sh [--require-owner-review] [repo-root]
#
# Table dialect (spec §8): one pipe table per file; every row has leading and
# trailing pipes; no '|' inside a cell; a header row, then a |---| separator.
# Columns are located by header name, never by position.
# Every loop that calls err() reads from process substitution, never from a
# pipe, so fail=1 is set in this shell and the exit status is trustworthy.
set -uf
require_review=0
[ "${1:-}" = "--require-owner-review" ] && { require_review=1; shift; }
root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
index="$root/research/CLAUDE.md"
ledger="$root/docs/port/COMMONALITY.md"
registry="$root/docs/port/PARAMETERS.md"
review="$root/docs/port/OWNER-REVIEW.md"
runbook="$root/research/RUNBOOK.md"
topics="$root/research/topics"
US=$'\037'   # cell separator inside this script (tabs collapse under IFS)
fail=0
err() { printf 'FAIL: %s\n' "$*"; fail=1; }
rel() { printf '%s' "${1#"$root/"}"; }
trim() { printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }
in_set() { case " $2 " in *" $1 "*) return 0 ;; esac; return 1; }
prompts() { [ -d "$topics" ] && find "$topics" -name '*.prompt.md' | sort; }

slug_re='^[a-z0-9]+(-[a-z0-9]+)*$'
areas="ci-workflows release-versioning lint-format static-analysis testing-coverage cli-framework-ux config-env-logging docs-system git-hooks-commit-hygiene packaging-distribution web-service dev-experience-repo-hygiene workspace-architecture"
fixed_required="msrv-policy rust-edition target-os-matrix license"
want_sections="## Objective|## Context|## Out of scope|## Couplings|## Questions|## Required evidence|## Answer template|## Constraints"

# ttsv FILE COL... — for every data row of FILE's table, print the named columns separated by $US
ttsv() { local f="$1"; shift; awk -F'|' -v names="$*" -v US="$US" '
  BEGIN { n = split(names, want, " ") }
  /^\|/ { if (!h) { h = 1; for (i = 2; i < NF; i++) { c = $i; gsub(/^ +| +$/, "", c); idx[c] = i }; next }
          if (!s) { s = 1; next }
          out = ""; for (j = 1; j <= n; j++) { c = (want[j] in idx) ? $(idx[want[j]]) : ""; gsub(/^ +| +$/, "", c); out = out (j > 1 ? US : "") c }
          print out }' "$f"; }
# theader FILE COL... — err for every named column missing from FILE's table header
theader() { local f="$1" hdr c; shift
  hdr="$(awk -F'|' '/^\|/ { for (i = 2; i < NF; i++) { c = $i; gsub(/^ +| +$/, "", c); printf " %s", c }; print ""; exit }' "$f")"
  for c in "$@"; do in_set "$c" "$hdr" || err "$(rel "$f"): table lacks column '$c'"; done; }

for f in "$index" "$ledger" "$registry" "$runbook"; do [ -f "$f" ] || err "missing $(rel "$f")"; done

# 1. index: columns, ids, enums, prompt links in both directions, prompt id agreement
index_ids=""   # lines: id US status US link
idx_status() { printf '%s' "$index_ids" | awk -F"$US" -v i="$1" '$1==i {print $2; exit}'; }
if [ -f "$index" ]; then
  theader "$index" id slug kind origin verdict owns prompt status
  n=0
  while IFS="$US" read -r id kind prompt status; do
    n=$((n + 1))
    printf '%s' "$id" | grep -qE '^R[0-9]{2}$' || err "index: bad id '$id'"
    in_set "$kind" "crate pattern bundle" || err "index $id: kind '$kind' not in crate|pattern|bundle"
    in_set "$status" "open in-progress resolved dropped" || err "index $id: status '$status' not in open|in-progress|resolved|dropped"
    link="$(printf '%s' "$prompt" | grep -oE 'topics/[^) ]+\.prompt\.md' | head -1)"
    if [ -z "$link" ]; then err "index $id: prompt cell has no topics/…/*.prompt.md link"
    elif [ ! -f "$root/research/$link" ]; then err "index $id: links missing prompt research/$link"
    else
      pid="$(grep -oE '^- id: R[0-9]{2}$' "$root/research/$link" | head -1 | sed 's/^- id: //')"
      [ "$pid" = "$id" ] || err "index $id: prompt research/$link declares '- id: ${pid:-<none>}'"
    fi
    index_ids="$index_ids$id$US$status$US$link
"
  done < <(ttsv "$index" id kind prompt status)
  [ "$n" -gt 0 ] || err "index: no R## rows"
  while IFS= read -r dup; do [ -n "$dup" ] && err "index: duplicate id $dup"; done < <(printf '%s' "$index_ids" | cut -d"$US" -f1 | sort | uniq -d)
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    printf '%s' "$index_ids" | cut -d"$US" -f3 | grep -Fxq "${f#"$root/research/"}" || err "prompt not linked from index: $(rel "$f")"
  done < <(prompts)
fi

# 2. every prompt has exactly the eight H2 sections of §7, in order, outside fenced code
while IFS= read -r f; do
  [ -n "$f" ] || continue
  got="$(awk '/^```/ { fence = !fence; next } !fence && /^## / { printf "%s%s", (n++ ? "|" : ""), $0 }' "$f")"
  [ "$got" = "$want_sections" ] || err "$(rel "$f"): H2 sections are [$got], expected [$want_sections]"
done < <(prompts)

# 3. parameter registry (spec §6.3): slugs, kinds, owners, required fixed parameters
reg=""   # lines: param US kind US owner US value
reg_field() { printf '%s' "$reg" | awk -F"$US" -v p="$1" -v k="$2" '$1==p {print $k; exit}'; }
if [ -f "$registry" ]; then
  theader "$registry" param kind owner value description
  while IFS="$US" read -r p k o v; do
    printf '%s' "$p" | grep -qE "$slug_re" || err "registry: parameter '$p' is not a lowercase-kebab slug"
    case "$k" in
      fixed)
        [ "$o" = "owner" ] || err "registry $p: fixed parameters are owned by 'owner', not '$o'"
        { [ -n "$v" ] && [ "$v" != "—" ]; } || err "registry $p: fixed parameter has no value" ;;
      researched)
        printf '%s' "$o" | grep -qE '^R[0-9]{2}$' || err "registry $p: researched parameter needs an R## owner, got '$o'"
        [ -n "$(idx_status "$o")" ] || err "registry $p: owner $o is not in the index" ;;
      *) err "registry $p: kind '$k' not in fixed|researched" ;;
    esac
    reg="$reg$p$US$k$US$o$US$v
"
  done < <(ttsv "$registry" param kind owner value)
  while IFS= read -r dup; do [ -n "$dup" ] && err "registry: parameter '$dup' registered twice"; done < <(printf '%s' "$reg" | cut -d"$US" -f1 | sort | uniq -d)
  for p in $fixed_required; do [ "$(reg_field "$p" 2)" = fixed ] || err "registry: required fixed parameter '$p' missing"; done
fi

# 4. couplings (spec §6.3): '- owns:' slugs are registered researched parameters owned by this item;
#    every researched parameter is declared by its owner's prompt; every '- consumes:' pair resolves
owned=""   # lines: param US R##
while IFS= read -r f; do
  [ -n "$f" ] || continue
  id="$(grep -oE '^- id: R[0-9]{2}$' "$f" | head -1 | sed 's/^- id: //')"
  [ -n "$id" ] || { err "$(rel "$f"): Couplings has no '- id: R##' line"; continue; }
  while IFS= read -r p; do
    p="$(trim "$p")"; [ -n "$p" ] || continue
    printf '%s' "$p" | grep -qE "$slug_re" || { err "$(rel "$f"): owned parameter '$p' is not a lowercase-kebab slug"; continue; }
    case "$(reg_field "$p" 2)" in
      researched) [ "$(reg_field "$p" 3)" = "$id" ] || err "$(rel "$f"): owns '$p' but the registry names $(reg_field "$p" 3) as owner" ;;
      fixed) err "$(rel "$f"): owns '$p', which is a fixed (owner-decided) parameter" ;;
      *) err "$(rel "$f"): owns unregistered parameter '$p'" ;;
    esac
    owned="$owned$p$US$id
"
  done < <(grep -E '^- owns:' "$f" | sed 's/^- owns://' | tr ',' '\n')
  while IFS= read -r c; do
    c="$(trim "$c")"; [ -n "$c" ] || continue
    rid="$(trim "${c%%:*}")"; par="$(trim "${c#*:}")"
    case "$rid" in
      owner) [ "$(reg_field "$par" 2)" = fixed ] || err "$(rel "$f"): consumes 'owner: $par' but '$par' is not a fixed parameter" ;;
      R[0-9][0-9])
        [ "$rid" != "$id" ] || err "$(rel "$f"): consumes its own parameter '$par'"
        [ "$(reg_field "$par" 3)" = "$rid" ] || err "$(rel "$f"): consumes '$c' but $rid does not own '$par'" ;;
      *) err "$(rel "$f"): consumes '$c' — expected 'R##: param' or 'owner: param'" ;;
    esac
  done < <(grep -E '^- consumes:' "$f" | sed 's/^- consumes://' | tr ';' '\n')
done < <(prompts)
while IFS= read -r dup; do [ -n "$dup" ] && err "parameter owned by more than one prompt: $dup"; done < <(printf '%s' "$owned" | cut -d"$US" -f1 | sort | uniq -d)
while IFS="$US" read -r p k o v; do
  [ "$k" = researched ] || continue
  printf '%s' "$owned" | grep -Fxq "$p$US$o" || err "registry: researched parameter '$p' is not declared by '- owns:' in $o's prompt"
done < <(printf '%s' "$reg")

# 5. ledger (spec §3): ids, areas, origin→verdict legality, item bijection, REUSE/SUBSTITUTE notes, OV sections
if [ -f "$ledger" ]; then
  theader "$ledger" ID Feature Area Origin Verdict Item Notes
  lrows=""     # lines: ID US item US ov
  parents=""   # lines: ID US parent
  while IFS="$US" read -r fid area origin verdict item notes; do
    printf '%s' "$fid" | grep -qE '^F[0-9]{3}$' || err "ledger: bad ID '$fid'"
    in_set "$area" "$areas" || err "ledger $fid: area '$area' is not one of the 13 areas"
    in_set "$origin" "same different py-only ts-only none" || err "ledger $fid: origin '$origin' not in same|different|py-only|ts-only|none"
    ov=""; research=0; legal=""
    case "$verdict" in
      "COMMON → REUSE")
        legal="same"
        printf '%s' "$notes" | grep -Fq 'rust-ok: yes' || err "ledger $fid: REUSE row lacks 'rust-ok: yes' in Notes" ;;
      "COMMON → SUBSTITUTE")
        legal="same"; research=1
        parent="$(printf '%s' "$notes" | grep -oE 'parent: F[0-9]{3}' | head -1 | sed 's/parent: //')"
        if [ -n "$parent" ]; then parents="$parents$fid$US$parent
"; else err "ledger $fid: SUBSTITUTE row lacks 'parent: F###' in Notes"; fi ;;
      "COMMON → OVERRIDE (OV-"[0-9][0-9]")") legal="same"; research=1; ov="${verdict#*(}"; ov="${ov%)}" ;;
      "ADOPT")     legal="py-only ts-only" ;;
      "DIVERGENT") legal="different py-only ts-only"; research=1 ;;
      "RUST-ONLY") legal="none"; research=1 ;;
      "OMIT")      legal="same different py-only ts-only" ;;
      *) err "ledger $fid: verdict outside closed set: '$verdict'" ;;
    esac
    [ -z "$legal" ] || in_set "$origin" "$legal" || err "ledger $fid: verdict '$verdict' is not legal for origin '$origin'"
    if [ "$research" = 1 ]; then
      if printf '%s' "$item" | grep -qE '^R[0-9]{2}$'; then
        st="$(idx_status "$item")"
        [ -n "$st" ] || err "ledger $fid: item $item is not in the index"
        [ "$st" != dropped ] || err "ledger $fid: item $item is dropped; re-verdict the row"
      else err "ledger $fid: '$verdict' needs an R## item, got '$item'"; fi
    else
      [ "$item" = "—" ] || err "ledger $fid: '$verdict' takes no research item; Item must be '—', got '$item'"
    fi
    lrows="$lrows$fid$US$item$US$ov
"
  done < <(ttsv "$ledger" ID Area Origin Verdict Item Notes)
  while IFS= read -r dup; do [ -n "$dup" ] && err "ledger: duplicate ID $dup"; done < <(printf '%s' "$lrows" | cut -d"$US" -f1 | sort | uniq -d)
  while IFS="$US" read -r fid parent; do
    [ -n "$fid" ] || continue
    printf '%s' "$lrows" | cut -d"$US" -f1 | grep -Fxq "$parent" || err "ledger $fid: parent $parent does not exist"
  done < <(printf '%s' "$parents")
  while IFS= read -r dup; do [ -n "$dup" ] && err "ledger: $dup used by more than one row"; done < <(printf '%s' "$lrows" | cut -d"$US" -f3 | grep -v '^$' | sort | uniq -d)
  while IFS= read -r ov; do
    [ -n "$ov" ] || continue
    c="$(grep -cx "### $ov" "$ledger")"
    if [ "$c" = 0 ]; then err "ledger: no '### $ov' section"; continue; fi
    [ "$c" = 1 ] || err "ledger: '### $ov' appears $c times"
    body="$(awk -v h="### $ov" '$0==h{p=1;next} /^### /{p=0} p' "$ledger")"
    printf '%s\n' "$body" | grep -qE '^\*\*Argument:\*\* *[^[:space:]]' || err "ledger: $ov lacks a non-empty '**Argument:**' line"
    printf '%s\n' "$body" | grep -qE '^\*\*Options:\*\* *[^[:space:]]'  || err "ledger: $ov lacks a non-empty '**Options:**' line"
  done < <(printf '%s' "$lrows" | cut -d"$US" -f3 | grep -v '^$' | sort -u)
  while IFS="$US" read -r id st link; do
    [ -n "$id" ] || continue; [ "$st" = dropped ] && continue
    printf '%s' "$lrows" | cut -d"$US" -f2 | grep -Fxq "$id" || err "index $id: no COMMONALITY.md row maps to it"
  done < <(printf '%s' "$index_ids")
fi

# 6. resolved items carry DECISION.md (with its three sections) and both audits, all non-empty (spec §10–§11)
while IFS="$US" read -r id st link; do
  [ "$st" = resolved ] || continue
  tdir="$root/research/${link%/prompts/*}"
  for need in DECISION.md audit-codex.md audit-fable.md; do
    [ -s "$tdir/$need" ] || err "index $id: resolved but $(rel "$tdir")/$need is missing or empty"
  done
  if [ -s "$tdir/DECISION.md" ]; then
    for s in "## Decision" "## Parameters" "## Empirical check"; do
      grep -Fxq "$s" "$tdir/DECISION.md" || err "index $id: DECISION.md lacks '$s'"
    done
  fi
done < <(printf '%s' "$index_ids")

# 7. owner review (Phase 3.5) — enforced only with --require-owner-review
if [ "$require_review" = 1 ]; then
  if [ ! -f "$review" ]; then err "missing $(rel "$review") (--require-owner-review)"
  else
    theader "$review" item disposition rationale date
    rv=""   # lines: item US disposition
    while IFS="$US" read -r item disp rat date; do
      in_set "$disp" "accept narrow force drop" || err "owner review $item: disposition '$disp' not in accept|narrow|force|drop"
      [ -n "$rat" ] || err "owner review $item: empty rationale"
      printf '%s' "$date" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || err "owner review $item: date '$date' is not YYYY-MM-DD"
      st="$(idx_status "$item")"
      if [ -z "$st" ]; then err "owner review: $item is not in the index"
      elif [ "$disp" = drop ] && [ "$st" != dropped ]; then err "owner review $item: disposition drop but index status is '$st'"
      elif [ "$disp" != drop ] && [ "$st" = dropped ]; then err "owner review $item: index status is dropped but disposition is '$disp'"; fi
      rv="$rv$item$US$disp
"
    done < <(ttsv "$review" item disposition rationale date)
    while IFS="$US" read -r id st link; do
      [ -n "$id" ] || continue
      c="$(printf '%s' "$rv" | cut -d"$US" -f1 | grep -cx "$id")"
      [ "$c" = 1 ] || err "owner review: $id has $c rows, expected exactly 1"
    done < <(printf '%s' "$index_ids")
  fi
fi

[ "$fail" -eq 0 ] && echo "OK: research tree structure valid"
exit "$fail"
