#!/usr/bin/env bash
# R73 — shape, parameter grammar and publication checks against this decision as
# committed. Run last. Revision 4: the expected H1 and revision note move to
# revision 4; no check is added, so the count stays 41 and the decision_sha256
# line binds revision 4. Revision 3: the expected H1 and revision note move to
# revision 3, and the D8 group asserts at source the three citations revision 3
# repairs (Gemini's concurrency position, the R02 revision-2 pin, and the §1.10
# dry_run locator) plus the preserved revision-2 snapshot. Revision 2: the
# raw-answer validator is no longer run on
# the decision (a DECISION.md is not a raw answer); the shape is compared with a
# published topic decision instead, and the tree check runs on a clean
# extraction so other sessions' uncommitted edits cannot be charged to R73.
#
# Works from a plain checkout and from a clean `git archive HEAD` extraction: it
# locates the repository root by walking up from this script, and never requires
# a .git directory. A worktree's .git is a FILE, so presence is tested with -e.
# Two single-quoted strings below carry literal backticks in prose and in a
# grep pattern; neither is meant to expand.
# shellcheck disable=SC2016

set -euo pipefail

GREP=/usr/bin/grep
HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REVIEW=$(dirname "$HERE")
RUN=$(dirname "$REVIEW")
DECISION="$REVIEW/DECISION.md"

ROOT="$RUN"
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/docs/port/PARAMETERS.md" ]; do
  ROOT=$(dirname "$ROOT")
done

PASS=0; FAIL=0; SKIP=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s — %s\n' "$1" "$2"; }

printf '== R73 decision shape ==\n'
printf 'grep: %s\n' "$("$GREP" --version | head -1)"
printf 'date_utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'repo_root: %s\n' "$ROOT"
printf 'in_git_worktree: %s\n' "$([ -e "$ROOT/.git" ] && echo yes || echo 'no — running from an extraction')"

if [ ! -f "$DECISION" ]; then
  fail D0-exists "no DECISION.md at $DECISION"
  printf '\nCHECKS RUN: %s PASS: %s FAIL: %s SKIP: %s\n' "$((PASS + FAIL + SKIP))" "$PASS" "$FAIL" "$SKIP"
  exit 1
fi
printf 'decision_sha256: %s\n' "$(shasum -a 256 "$DECISION" | cut -d' ' -f1)"

# --- title and heading shape --------------------------------------------------
printf '\n-- shape --\n'
TITLE=$(head -1 "$DECISION")
EXPECT_TITLE='# 2026-09-27 — R73 — idempotency-middleware (bundle, Deep) — decision (revision 4)'
if [ "$TITLE" = "$EXPECT_TITLE" ]; then
  pass D1-title 'the date-first H1 is exactly the revision-rules form'
else
  fail D1-title "the H1 is: $TITLE"
fi

H2S=$("$GREP" -n '^## ' "$DECISION" | sed 's/^[0-9]*://' | tr '\n' '|')
H2S_BARE=$H2S
if [ "$H2S" = '## Decision|## Parameters|## Empirical check|## Engines|' ]; then
  pass D1-h2 'exactly the four required H2 headings, in order, and nothing else'
else
  fail D1-h2 "the H2 set is: $H2S"
fi

if "$GREP" -q '^## Supersedes' "$DECISION"; then
  fail D1-supersedes 'a ## Supersedes section is present, but revision 4 reverses nothing and RUNBOOK §5 reserves it for a reversal'
else
  pass D1-supersedes 'no ## Supersedes section: revision 4 repairs revision 3 without reversing its recommendation, and RUNBOOK §5 reserves the section for a reversal'
fi

# The revision note sits between the H1 and ## Decision, as in published R11.
FIRST_H2=$("$GREP" -n '^## ' "$DECISION" | head -1 | cut -d: -f1)
if head -n "$FIRST_H2" "$DECISION" | "$GREP" -q '^\*\*Revision note, revision 4\.\*\*'; then
  pass D1-revnote 'a **Revision note, revision 4.** paragraph precedes ## Decision'
else
  fail D1-revnote 'no revision-4 note precedes ## Decision'
fi

# Peer shape: a published topic decision of the same kind and tier, revised
# several times without a reversal, must carry exactly the same H2 sequence.
PEER="$ROOT/research/topics/11-ci-workflow-job-structure/DECISION.md"
if [ -f "$PEER" ]; then
  PEER_H2S=$("$GREP" '^## ' "$PEER" | tr '\n' '|')
  PEER_H1=$(head -1 "$PEER")
  if [ "$PEER_H2S" = "$H2S_BARE" ]; then
    pass D1-peer "the H2 sequence equals published research/topics/11-ci-workflow-job-structure/DECISION.md ($PEER_H1)"
  else
    fail D1-peer "the H2 sequence differs from the published R11 peer: peer=$PEER_H2S here=$H2S_BARE"
  fi
  if "$GREP" -q '^re-verify: ' "$PEER" && [ "$("$GREP" -c '^- assumes ' "$PEER")" -ge 4 ]; then
    pass D1-peer-lines 'the peer carries a re-verify: line and its - assumes lines in the same grammar used here'
  else
    fail D1-peer-lines 'the peer does not carry the re-verify: and - assumes grammar this check compares against'
  fi
else
  skip D1-peer 'the published R11 peer decision is absent'
  skip D1-peer-lines 'the published R11 peer decision is absent'
fi

if "$GREP" -q '^### Principles and implementation$' "$DECISION"; then
  pass D1-h3 'the required ### Principles and implementation H3 is present'
else
  fail D1-h3 'the ### Principles and implementation H3 is missing'
fi

RV=$("$GREP" -c '^re-verify: ' "$DECISION")
if [ "$RV" -eq 1 ]; then
  pass D1-reverify 'exactly one re-verify: line'
else
  fail D1-reverify "there are $RV re-verify: lines; the rule is exactly one"
fi

H5=$("$GREP" -c '^##### ' "$DECISION" || true)
if [ "$H5" -eq 0 ]; then
  pass D1-h5 'no ##### heading anywhere, so the bundle Members-window rule cannot be violated'
else
  fail D1-h5 "$H5 ##### headings are present outside a ### Members window"
fi

if "$GREP" -q 'inapplicable — owner ruling 2026-09-12 (Q7.B)' "$DECISION"; then
  pass D1-gate1 'licence gate 1 is recorded as inapplicable with the owner ruling named, not deleted'
else
  fail D1-gate1 'gate 1 is not recorded in the required form'
fi

# --- parameters ---------------------------------------------------------------
printf '\n-- parameters --\n'
OWNS=$("$GREP" -c '^- owns ' "$DECISION" || true)
if [ "$OWNS" -eq 0 ]; then
  pass D2-owns 'no `- owns` line: the prompt declares no owned parameter and the index row carries an em dash'
else
  fail D2-owns "$OWNS - owns lines are present, but R73 owns no parameter"
fi

DECL=$(mktemp -t r73pa); REG=$(mktemp -t r73pb)
trap 'rm -f "$DECL" "$REG"' EXIT
"$GREP" '^- assumes ' "$DECISION" | sed 's/^- assumes //' | sort > "$DECL"
python3 - "$ROOT/docs/port/PARAMETERS.md" > "$REG" <<'PY'
import re, sys
want = {"msrv-policy", "rust-edition", "target-os-matrix", "license"}
for line in open(sys.argv[1], encoding="utf-8"):
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    if len(cells) >= 4 and cells[0] in want and cells[1] == "fixed":
        print(f"{cells[0]} = {cells[3]}")
PY
sort -o "$REG" "$REG"
COUNT=$(wc -l < "$DECL" | tr -d ' ')
if [ "$COUNT" -eq 4 ]; then
  pass D3-count 'exactly four - assumes lines, matching the four owner-fixed parameters'
else
  fail D3-count "there are $COUNT - assumes lines, expected 4"
fi
if diff -u "$REG" "$DECL" > /tmp/r73_paramdiff.txt 2>&1; then
  pass D3-params 'every - assumes value is byte-identical to its row in docs/port/PARAMETERS.md'
else
  fail D3-params 'an - assumes value differs from the registry:'
  sed 's/^/        /' /tmp/r73_paramdiff.txt
fi
# Revision 2: the snapshot is compared on the four fixed rows this decision
# assumes. Whole-file identity broke when R11 published ci-job-structure, a row
# R73 neither owns nor consumes; r73-muse-currency.sh K3-drift names that row.
if [ -f "$RUN/inputs/PARAMETERS.md" ]; then
  SNAPREG=$(mktemp -t r73pc)
  python3 - "$RUN/inputs/PARAMETERS.md" > "$SNAPREG" <<'PY'
import sys
want = {"msrv-policy", "rust-edition", "target-os-matrix", "license"}
for line in open(sys.argv[1], encoding="utf-8"):
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    if len(cells) >= 4 and cells[0] in want and cells[1] == "fixed":
        print(f"{cells[0]} = {cells[3]}")
PY
  sort -o "$SNAPREG" "$SNAPREG"
  if [ "$(wc -l < "$SNAPREG" | tr -d ' ')" -eq 4 ] && cmp -s "$SNAPREG" "$REG"; then
    pass D3-snapshot "the four fixed rows in this run's inputs/PARAMETERS.md equal the live registry's"
  else
    fail D3-snapshot "a fixed row in the run's PARAMETERS.md snapshot differs from the live registry"
  fi
  rm -f "$SNAPREG"
else
  skip D3-snapshot 'no inputs/PARAMETERS.md in this run'
fi
if "$GREP" -qE '^- assumes [a-z-]+ = .*`' "$DECISION"; then
  fail D3-grammar 'an - assumes line carries a backtick; the validator compares the bare value'
else
  pass D3-grammar 'no - assumes line carries a backtick, a citation or trailing commentary'
fi
if "$GREP" -q '^CONFLICT: ' "$DECISION"; then
  fail D3-conflict 'a CONFLICT: line is present but the decision states it raises none'
else
  pass D3-conflict 'no CONFLICT: line, consistent with the decision text'
fi

# --- override numbering -------------------------------------------------------
printf '\n-- override numbering --\n'
if "$GREP" -q 'OVERRIDE (OV-16)' "$DECISION"; then
  pass D4-ov-present 'the override is numbered OV-16, the number the controller allocated'
else
  fail D4-ov-present 'OVERRIDE (OV-16) is not present'
fi
for part in '\*\*Argument:\*\*' '\*\*Options:\*\*'; do
  if "$GREP" -q "$part" "$DECISION"; then
    pass D4-ov-parts "the override carries its ${part//\\/} section"
  else
    fail D4-ov-parts "the override is missing ${part//\\/}"
  fi
done
OTHER=$("$GREP" -o 'OVERRIDE (OV-[0-9]*)' "$DECISION" | sort -u | tr '\n' ' ')
if [ "$OTHER" = 'OVERRIDE (OV-16) ' ]; then
  pass D4-ov-single 'OV-16 is the only override number this decision declares'
else
  fail D4-ov-single "this decision declares more than one override number: $OTHER"
fi
# Uniqueness, with a non-vacuous control: OV-03 must be found elsewhere.
COLLIDE=0; CONTROL=0
if [ -d "$ROOT/research/runs" ]; then
  while IFS= read -r f; do
    [ "$f" = "$DECISION" ] && continue
    "$GREP" -q '^### OVERRIDE (OV-16)' "$f" && COLLIDE=$((COLLIDE + 1))
    "$GREP" -q '^### OVERRIDE (OV-03)' "$f" && CONTROL=$((CONTROL + 1))
  done < <(find "$ROOT/research/runs" "$ROOT/research/topics" -name DECISION.md 2>/dev/null)
fi
if [ "$COLLIDE" -eq 0 ]; then
  if [ "$CONTROL" -ge 1 ]; then
    pass D4-ov-unique "no other decision declares OV-16 by heading, and the control found $CONTROL declaring OV-03, so the zero is not vacuous"
  else
    fail D4-ov-unique 'the OV-16 zero is vacuous: the control found no decision declaring OV-03 either'
  fi
else
  fail D4-ov-unique "$COLLIDE other decisions declare OV-16 by heading"
fi

# --- hygiene ------------------------------------------------------------------
printf '\n-- hygiene --\n'
# Assembled at run time so the script does not contain the literal it searches for.
AT=$(printf '%s' '@')
MAIL="steve${AT}conceptm.com"
if "$GREP" -rqF "$MAIL" "$REVIEW"; then
  fail D5-email 'a personal email address appears under review/'
else
  pass D5-email 'no personal email address anywhere under review/'
fi
if "$GREP" -rqE '\b(gh[pousr]_[A-Za-z0-9]{16,}|ghs_[A-Za-z0-9]{16,})' "$REVIEW"; then
  fail D5-token 'a token-shaped string appears under review/'
else
  pass D5-token 'no token-shaped string under review/'
fi
if find "$REVIEW" -name target -type d | "$GREP" -q .; then
  fail D5-target 'a target/ directory is committed under review/'
else
  pass D5-target 'no target/ tree under review/'
fi
if find "$REVIEW" -name Cargo.lock | "$GREP" -q .; then
  fail D5-lock 'a Cargo.lock is committed under review/'
else
  pass D5-lock 'no Cargo.lock under review/'
fi
if find "$REVIEW" -name .git -mindepth 1 | "$GREP" -q .; then
  fail D5-nested 'a nested git repository is committed under review/'
else
  pass D5-nested 'no nested git repository under review/'
fi

# --- cited artifacts exist ----------------------------------------------------
printf '\n-- cited artifacts --\n'
MISSING=''
SCRIPTS='r73-standard-conformance r73-probe r73-sources r73-registry r73-muse-currency'
for f in $SCRIPTS; do
  [ -f "$HERE/$f.sh" ] || MISSING="$MISSING $f.sh"
  [ -f "$HERE/$f.log" ] || MISSING="$MISSING $f.log"
done
if [ -z "$MISSING" ]; then
  pass D6-artifacts 'every cited script and log is present'
else
  fail D6-artifacts "missing:$MISSING"
fi
TOTAL=0
for f in $SCRIPTS; do
  [ -f "$HERE/$f.log" ] || continue
  line=$(tail -1 "$HERE/$f.log")
  n=$(printf '%s' "$line" | sed -n 's/^CHECKS RUN: \([0-9]*\).*/\1/p')
  bad=$(printf '%s' "$line" | sed -n 's/.*FAIL: \([0-9]*\).*/\1/p')
  printf '  %-28s %s\n' "$f" "$line"
  if [ "${bad:-1}" != "0" ]; then
    fail "D6-$f" "that log does not report FAIL: 0"
  fi
  TOTAL=$((TOTAL + ${n:-0}))
done
if [ "$TOTAL" -eq 158 ]; then
  pass D6-total "the five logs sum to $TOTAL checks, the figure the decision cites"
else
  fail D6-total "the five logs sum to $TOTAL checks; the decision cites 158"
fi
if "$GREP" -qF '**158 checks, 158 pass, 0 fail, 0 skip**' "$DECISION"; then
  pass D6-cited 'the decision states the same 158-check total'
else
  fail D6-cited 'the decision does not state the 158-check total'
fi

# Every check label the decision cites in backticks must resolve to a log or script.
UNRESOLVED=''; SEEN=0
while IFS= read -r label; do
  SEEN=$((SEEN + 1))
  if ! "$GREP" -rqF "$label" "$HERE"/*.log "$HERE"/*.sh 2>/dev/null; then
    UNRESOLVED="$UNRESOLVED $label"
  fi
done < <("$GREP" -oE '`(C[0-9][0-9A-Za-z.-]*|P[0-9][0-9A-Za-z.-]*|S[0-9][0-9A-Za-z.-]*|E[0-9][0-9A-Za-z.-]*|D[0-9][0-9A-Za-z.-]*|M[0-9][0-9A-Za-z.-]*|K[0-9][0-9A-Za-z.-]*|[sw][0-9][0-9a-z]*)`' "$DECISION" |
        tr -d '`' | sort -u)
if [ "$SEEN" -lt 40 ]; then
  fail D6-labels-control "only $SEEN distinct check labels were scanned; the zero below would be vacuous"
else
  pass D6-labels-control "$SEEN distinct check labels scanned, so the resolution result below is not vacuous"
fi
if [ -z "$UNRESOLVED" ]; then
  pass D6-labels 'every check label the decision cites resolves to a committed log or script'
else
  fail D6-labels "these cited labels resolve to nothing:$UNRESOLVED"
fi

# --- revision-3 re-citations, asserted at source --------------------------------
# Each citation the revision-2 judgment audit found wrong is asserted here at the
# line revision 3 cites, so a later move fails closed rather than going stale.
printf '\n-- revision-3 re-citations --\n'
line_has() {
  local id=$1 file=$2 line=$3 expect=$4 why=$5 actual
  if [ ! -f "$file" ]; then
    fail "$id" "${file#"$ROOT"/} is absent"
    return
  fi
  actual=$(sed -n "${line}p" "$file")
  case "$actual" in
    *"$expect"*) pass "$id" "${file#"$ROOT"/}:$line carries \"$expect\" — $why" ;;
    *) fail "$id" "${file#"$ROOT"/}:$line does not carry \"$expect\"; it reads: ${actual:0:200}" ;;
  esac
}
R2SNAP="$REVIEW/R73-r2-snapshot.md"
R2SHA=842d48f67a140cb46b9909ac5e09de729fd267660bdf4f106aaa82ac2d99915e
if [ -f "$R2SNAP" ] && [ "$(shasum -a 256 "$R2SNAP" | cut -d' ' -f1)" = "$R2SHA" ]; then
  pass D8-r2 'review/R73-r2-snapshot.md is byte-identical to revision 2 (sha256 842d48f6…), the text both revision-2 audits judged'
else
  fail D8-r2 'review/R73-r2-snapshot.md is absent or not revision 2'
fi
GEM="$RUN/raw/doxa-gemini.normalized.md"
line_has D8-gemini-lock "$GEM" 23 'atomic `try_acquire_lock` method' 'Gemini proposes an atomic reserve-or-conflict primitive'
line_has D8-gemini-409 "$GEM" 109 'receive an `HTTP 409 Conflict`' 'Gemini plans a concurrent-request 409 check'
R02D="$ROOT/research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md"
R02SHA=9e8f8e8c11ffb9b383819b2de1b05eab71a32e3af358b75ea8475d48f3c9707f
# Matched by content, not line number: the acceptance table grows.
if "$GREP" -qF "| R02 | 2 | \`$R02SHA\` | accept |" "$ROOT/docs/port/OWNER-ACCEPTANCES.md"; then
  pass D8-r02-accept 'docs/port/OWNER-ACCEPTANCES.md records R02 accepted at revision 2 (9e8f8e8c…)'
else
  fail D8-r02-accept 'OWNER-ACCEPTANCES.md has no R02 revision-2 acceptance row at 9e8f8e8c…'
fi
if [ -f "$R02D" ] && [ "$(shasum -a 256 "$R02D" | cut -d' ' -f1)" = "$R02SHA" ] &&
   head -1 "$R02D" | "$GREP" -qF '(revision 2)'; then
  pass D8-r02-sha 'the R02 run decision is the accepted revision 2 (sha256 9e8f8e8c…, H1 "(revision 2)")'
else
  fail D8-r02-sha 'the R02 run decision is absent, or no longer the accepted revision 2'
fi
line_has D8-r02-workspace "$R02D" 22 'root-package workspace** of four packages' 'R02 revision 2 fixes the four-package workspace'
if sed -n 78p "$R02D" | "$GREP" -qF '`B1`/`B2`' && sed -n 251p "$R02D" | "$GREP" -qF '`B1`/`B2`'; then
  pass D8-r02-b1b2 'R02 revision 2 carries B1/B2 at :78 (the verified row) and :251 (the probe description)'
else
  fail D8-r02-b1b2 'R02 revision 2 no longer carries B1/B2 at :78 and :251'
fi
STANDARD_REPO=${R73_STANDARD_REPO:-/Users/stevemorin/c/rest-standards}
BLOB=71bd813c1cf61286586b4ee41ed83ff065e5c8d9
if [ -d "$STANDARD_REPO" ] && git -C "$STANDARD_REPO" cat-file -e "$BLOB" 2>/dev/null; then
  L338=$(git -C "$STANDARD_REPO" show "$BLOB" | sed -n 338p)
  case "$L338" in
    '| `dry_run` | Rehearse a mutation'*) pass D8-dryrun "rest-api-standard.md blob ${BLOB:0:8} line 338 is the §1.10 dry_run reservation row" ;;
    *) fail D8-dryrun "blob ${BLOB:0:8} line 338 is not the dry_run row; it reads: ${L338:0:120}" ;;
  esac
else
  skip D8-dryrun "the standard clone or blob ${BLOB:0:8} is unavailable at $STANDARD_REPO"
fi

# --- repository validators ----------------------------------------------------
# The raw-answer validator (validate_answer_text) is deliberately NOT run here: a
# DECISION.md follows the synthesizer's H2 contract, not the raw-answer field
# set, so D1-peer above is the shape check this document is held to.
printf '\n-- repository validators --\n'
if [ -x "$ROOT/scripts/check-research-tree.sh" ] && [ -e "$ROOT/.git" ] && command -v git > /dev/null 2>&1; then
  # (a) Clean extraction: the committed tree with only THIS run directory
  # overlaid from the working tree. Other sessions share this checkout, and
  # their uncommitted edits must not be charged to R73 (nor hide an R73 defect).
  XT=$(mktemp -d "${TMPDIR:-/tmp}/r73tree.XXXXXX")
  RUNREL=${RUN#"$ROOT"/}
  if git -C "$ROOT" archive HEAD | tar -x -C "$XT" && mkdir -p "$XT/$RUNREL" && cp -R "$RUN/." "$XT/$RUNREL/"; then
    if ( cd "$XT" && ./scripts/check-research-tree.sh . > /tmp/r73_tree_clean.log 2>&1 ); then
      pass D7-tree "scripts/check-research-tree.sh passes on git archive HEAD with this run directory overlaid ($(tail -1 /tmp/r73_tree_clean.log))"
    elif "$GREP" -q 'publication lock is active' /tmp/r73_tree_clean.log && [ "$("$GREP" -c '^FAIL' /tmp/r73_tree_clean.log)" -le 1 ]; then
      skip D7-tree 'the only diagnostic is an active publication lock held by another writer; rerun when it clears'
    else
      fail D7-tree 'scripts/check-research-tree.sh fails on the clean extraction:'
      # Revision 4: the listing is truncated by head, which can SIGPIPE sort;
      # under pipefail that aborted the script before its summary line.
      { "$GREP" '^FAIL' /tmp/r73_tree_clean.log | sort -u | head -15 | sed 's/^/        /'; } || true
    fi
  else
    fail D7-tree 'could not build the clean extraction'
  fi
  chmod -R u+w "$XT" 2> /dev/null || true
  rm -rf "${XT:?}"
  # (b) The live shared checkout, reported by scope: a failure that names R73
  # fails this check; failures naming only other items are listed, not hidden.
  if ( cd "$ROOT" && ./scripts/check-research-tree.sh . > /tmp/r73_tree_live.log 2>&1 ); then
    pass D7-tree-live 'scripts/check-research-tree.sh also passes in the live checkout'
  elif "$GREP" '^FAIL' /tmp/r73_tree_live.log | "$GREP" -q 'R73\|73-idempotency'; then
    fail D7-tree-live 'the live checkout reports a failure that names R73:'
    "$GREP" '^FAIL' /tmp/r73_tree_live.log | "$GREP" 'R73\|73-idempotency' | sort -u | sed 's/^/        /'
  else
    OTHERS=$("$GREP" '^FAIL' /tmp/r73_tree_live.log | "$GREP" -oE 'R[0-9]{2}' | sort -u | tr '\n' ' ')
    pass D7-tree-live "the live checkout fails only on other sessions' in-flight state, $("$GREP" -c '^FAIL' /tmp/r73_tree_live.log) FAIL lines naming ${OTHERS:-no item}and none naming R73"
  fi
else
  skip D7-tree 'no git checkout or tree checker available for a clean extraction'
  skip D7-tree-live 'no git checkout or tree checker available'
fi

printf '\nCHECKS RUN: %s PASS: %s FAIL: %s SKIP: %s\n' "$((PASS + FAIL + SKIP))" "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
