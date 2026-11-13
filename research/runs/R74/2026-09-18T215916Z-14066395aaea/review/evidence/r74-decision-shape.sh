#!/usr/bin/env bash
# R74 — shape, parameter-grammar, hygiene and citation-currency checks against this run's
# review/DECISION.md. Run LAST. Touches no network.
#
# Revision 2 (audit EA-1 and judgment finding 4): the four brittle matchers that failed
# against revision 1 are repaired — S1g matches the gate-1 phrase on one line, S2g anchors on
# the BASELINE-REVIEW filing line, S4d excludes negated mentions, S4f anchors on the
# migration-table row. Revision 1's section S7 ran scripts/research_validation.py's raw-answer
# validator against this decision; that validator checks raw answers, not decisions, so S7 now
# compares this decision's shape with a published topic decision instead. S6 checks that the
# totals the decision's Empirical-check table states equal the logs' own summary lines. S8 runs
# the raw-answer shape check on the raw legs, which is what it is for.
#
# Revision 3: S1a and S1j/S1k assert the revision-3 title and revision note; the revision-2 note
# and its table stay in the decision, and S1n still checks that table's rows.
#
# Reproducible byte-for-byte for as long as DECISION.md, the files it reads and the sibling
# logs are unchanged.
# shellcheck disable=SC2016  # backticks in patterns are literal Markdown, not expansions
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REVIEW="$(cd "$HERE/.." && pwd)"
RUN="$(cd "$REVIEW/.." && pwd)"
DEC="$REVIEW/DECISION.md"

PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); echo "PASS  $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL  $1"; }
skip() { SKIP=$((SKIP+1)); echo "SKIP  $1"; }
chk()  { if [ "$2" = "$3" ]; then ok "$1 == $2"; else bad "$1: expected [$2] got [$3]"; fi; }
cnt()  { /usr/bin/grep -c -- "$1" "$2" || true; }
cntE() { /usr/bin/grep -cE -- "$1" "$2" || true; }

ROOT="$RUN"
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/docs/port/PARAMETERS.md" ]; do ROOT="$(dirname "$ROOT")"; done
PUB="$ROOT/research/topics/53-config-schema-validation/DECISION.md"

echo "grep: $(/usr/bin/grep --version | head -1)"
echo "decision: review/DECISION.md"
echo "published comparator: research/topics/53-config-schema-validation/DECISION.md"
echo

if [ ! -f "$DEC" ]; then echo "FATAL: $DEC absent"; exit 1; fi

# ---------------------------------------------------------------------------
echo "=== S1. title, H2 set, and the revision rules ==="
chk "S1a title line" \
  "# 2026-09-27 — R74 — rate-limiting-middleware (bundle, Deep) — decision (revision 3)" \
  "$(sed -n '1p' "$DEC")"
h2s="$(/usr/bin/grep '^## ' "$DEC" | tr '\n' '|')"
chk "S1b the four H2 headings, in order and nothing else" \
  "## Decision|## Parameters|## Empirical check|## Engines|" "$h2s"
chk "S1c exactly one '### Principles and implementation'" "1" "$(cnt '^### Principles and implementation$' "$DEC")"
chk "S1d no '## Supersedes' (nothing published for R74)" "0" "$(cnt '^## Supersedes' "$DEC")"
chk "S1e exactly one 're-verify:' line" "1" "$(cnt '^re-verify: ' "$DEC")"
rv_line="$(/usr/bin/grep -n '^re-verify: ' "$DEC" | cut -d: -f1)"
par_line="$(/usr/bin/grep -n '^## Parameters$' "$DEC" | cut -d: -f1)"
dec_line="$(/usr/bin/grep -n '^## Decision$' "$DEC" | cut -d: -f1)"
chk "S1f 're-verify:' is the final content line of ## Decision" "2" "$((par_line - rv_line))"
chk "S1g gate 1 is recorded as inapplicable with the owner ruling, on one line" "1" \
  "$(cnt 'inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool' "$DEC")"
chk "S1h no '#####' heading anywhere" "0" "$(cnt '^##### ' "$DEC")"
chk "S1i no '### Members' section" "0" "$(cnt '^### Members$' "$DEC")"
chk "S1j exactly one revision note, for revision 3" "1" "$(cnt '^\*\*Revision note (revision 3)\.\*\*' "$DEC")"
rn_line="$(/usr/bin/grep -n '^\*\*Revision note (revision 3)\.\*\*' "$DEC" | cut -d: -f1)"
if [ -n "$rn_line" ] && [ "$rn_line" -lt "$dec_line" ]; then ok "S1k the revision note precedes ## Decision"; else bad "S1k the revision note does not precede ## Decision"; fi
R1SHA=84c01ec019f9ba68b731b56ad846dece449ddecdf8fb6d548530f2dc1b4b3056
chk "S1l revision 1's sha256 is named" "1" "$(sed -n '1,12p' "$DEC" | /usr/bin/grep -c "$R1SHA" || true)"
if [ -f "$REVIEW/R74-r1-snapshot.md" ]; then
  chk "S1m review/R74-r1-snapshot.md is revision 1, byte for byte" "$R1SHA" "$(shasum -a 256 "$REVIEW/R74-r1-snapshot.md" | cut -c1-64)"
else
  bad "S1m review/R74-r1-snapshot.md is missing"
fi
# every audit finding ID appears in the revision-note table
for f in "fable 1, JF-3/JF-9" "fable 2, JF-4" "fable 3, JF-4" "fable 4 and claude EA-1" "fable 5, JF-4/JF-5" "fable 6, JF-1" "claude EA-2" "claude EA-3" "claude EA-4" "claude EA-5"; do
  chk "S1n the revision-note table has a row for '$f'" "1" "$(sed -n "1,${dec_line}p" "$DEC" | /usr/bin/grep -c "^| $f" || true)"
done

# ---------------------------------------------------------------------------
echo
echo "=== S2. the override and the baseline finding ==="
chk "S2a exactly one OVERRIDE heading" "1" "$(cnt '^### OVERRIDE (OV-' "$DEC")"
chk "S2b it is OV-17" "1" "$(cnt '^### OVERRIDE (OV-17) ' "$DEC")"
chk "S2c the override carries an Argument" "1" "$(cnt '^\*\*Argument\.\*\*' "$DEC")"
chk "S2d the override carries Options" "1" "$(cnt '^\*\*Options\.\*\*' "$DEC")"
chk "S2e the §1.9 deviation line shape is used (approver + date)" "1" "$(cnt 'approver: pending owner review · date: 2026-09-18$' "$DEC")"
for n in OV-04 OV-11; do
  chk "S2f no '### OVERRIDE ($n)' heading" "0" "$(cnt "^### OVERRIDE ($n) " "$DEC")"
done
chk "S2g exactly one BASELINE-REVIEW filing, for F323 (anchored on the filing line)" "1" \
  "$(cnt '^\*\*`BASELINE-REVIEW: F323 — ' "$DEC")"

# ---------------------------------------------------------------------------
echo
echo "=== S3. parameters: byte-identity with the live registry ==="
TMPD="$(mktemp -d "${TMPDIR:-/tmp}/r74-shape.XXXXXXXX")"
trap 'rm -rf "$TMPD"' EXIT
python3 - "$ROOT/docs/port/PARAMETERS.md" > "$TMPD/registry-assumes" <<'PY'
import sys
rows = [l for l in open(sys.argv[1], encoding='utf-8') if l.startswith('| ')]
for want in ('msrv-policy', 'rust-edition', 'target-os-matrix', 'license'):
    for r in rows:
        f = r.split('|')
        if len(f) > 4 and f[1].strip() == want and f[2].strip() == 'fixed':
            print('- assumes %s = %s' % (want, f[4].strip()))
            break
PY
/usr/bin/grep '^- assumes ' "$DEC" > "$TMPD/decision-assumes" || true
if diff "$TMPD/registry-assumes" "$TMPD/decision-assumes" > "$TMPD/assumes.diff" 2>&1; then
  ok "S3a the four '- assumes' lines are byte-identical to the live registry's fixed rows (diff empty)"
else
  bad "S3a '- assumes' lines differ from the registry"; cat "$TMPD/assumes.diff"
fi
chk "S3b exactly four '- assumes' lines" "4" "$(cnt '^- assumes ' "$DEC")"
chk "S3c no '- owns' line (the prompt's owns list is empty)" "0" "$(cnt '^- owns ' "$DEC")"
chk "S3d no 'CONFLICT:' line" "0" "$(cnt '^CONFLICT: ' "$DEC")"
chk "S3-control the registry extractor found four fixed rows" "4" "$(/usr/bin/grep -c . "$TMPD/registry-assumes" || true)"
if /usr/bin/grep '^- assumes ' "$DEC" | /usr/bin/grep -q '`'; then bad "S3e an '- assumes' line carries a backtick"; else ok "S3e no '- assumes' line carries a backtick"; fi

# ---------------------------------------------------------------------------
echo
echo "=== S4. the mechanical enumeration this revision owes ==="
n_off="$(/usr/bin/grep -ci 'off by default\|off-by-default' "$DEC" || true)"
echo "     'off by default' / 'off-by-default' occurrences: $n_off (each describes py, the prompt, Muse, R69's Cargo feature or the conditional evidence form — never this limiter's shipped default)"
if [ "$n_off" -ge 1 ]; then ok "S4a the moved default is discussed explicitly rather than silently"; else bad "S4a the decision never names the default it moved"; fi
mv_line="$(/usr/bin/grep -n 'The shipped default moves from off to on' "$DEC" | head -1 | cut -d: -f1)"
if [ -n "$mv_line" ] && [ "$mv_line" -lt "$dec_line" ]; then ok "S4b the move is stated before ## Decision (line $mv_line)"; else bad "S4b the move is not stated before ## Decision"; fi
chk "S4c 'RFC 7807' appears only where R5.14's ban and the gemini leg's breach are discussed" "3" "$(cnt 'RFC 7807' "$DEC")"
chk "S4d 'standards-compliant' is never claimed (negated mentions excluded)" "0" \
  "$(/usr/bin/grep 'standards-compliant' "$DEC" | /usr/bin/grep -vcE 'never|neither|not ' || true)"
# each mention, read with the line before it (sentences wrap), must name revision 9's registry bytes
n_srcweb=0; n_bad=0
while IFS=: read -r ln _; do
  n_srcweb=$((n_srcweb+1))
  if ! sed -n "$((ln-1)),${ln}p" "$DEC" | /usr/bin/grep -qE 'revision 9|registry bytes'; then n_bad=$((n_bad+1)); echo "     src/web/ at line $ln does not name revision 9's registry bytes"; fi
done < <(/usr/bin/grep -n 'src/web/' "$DEC")
chk "S4e 'src/web/' appears only where R69 revision 9's registry bytes are named (mentions: $n_srcweb)" "0" "$n_bad"
chk "S4f 'crates/web' is the layout used: the migration-table row for rate_limit.rs" "1" \
  "$(cnt '^| `crates/web/src/rate_limit.rs` | \*\*New\.\*\*' "$DEC")"
chk "S4g no engine bullet for codex" "0" "$(cnt '^- codex' "$DEC")"
chk "S4h one engine bullet for muse, naming raw/muse.md" "1" "$(cnt '^- muse `raw/muse.md`' "$DEC")"
chk "S4i the Muse leg's sha256 is stated" "1" "$(cnt '^- muse .*c3e018cfd5f7df4f4887d4c04d2464fbd0280e749a42d7a69e48a8684c2690dd' "$DEC")"
chk "S4j no nonexistent rule ID R1.10 from ## Decision on (the revision note names the old label)" "0" \
  "$(sed -n "${dec_line},\$p" "$DEC" | /usr/bin/grep -c 'R1\.10' || true)"
chk "S4k no '§1.7 line 273' citation (R1.7 lives in §1.9)" "0" "$(cnt '§1.7 line 273' "$DEC")"
chk "S4l the shipped signature takes a policy, not an Option" "1" "$(cnt '^    policy: RateLimitPolicy,$' "$DEC")"
chk "S4m R1.6 is in the re-verify rule list" "1" "$(/usr/bin/grep '^re-verify: ' "$DEC" | /usr/bin/grep -c 'amending R1.6, R1.7, R1.8,' || true)"
chk "S4n no stale R77 revision 2 pin" "0" "$(cnt '46b2a05f40f6a3ea27b5fdef415c50adccd27ade5ed6fa94f83ed933503d7f68' "$DEC")"
chk "S4o no citation of R73's raw report for the placement" "0" "$(cnt 'R73/2026-09-18T215915Z-4b648f8a2b5d/raw/opus.md' "$DEC")"
chk "S4p no 'Decided:' wording for the R73 placement" "0" "$(cnt 'Decided: the rate limiter sits outside' "$DEC")"

# ---------------------------------------------------------------------------
echo
echo "=== S5. hygiene ==="
AT='@'
if /usr/bin/grep -qE "[A-Za-z0-9._%+-]+${AT}[A-Za-z0-9.-]+\.[A-Za-z]{2,}" "$DEC"; then bad "S5a an email-shaped string appears in the decision"; else ok "S5a no email-shaped string in the decision"; fi
n_mail=0
for f in "$HERE"/r74-*.log "$HERE"/r74-*.sh; do
  if /usr/bin/grep -qE "[A-Za-z0-9._%+-]+${AT}[A-Za-z0-9.-]+\.[A-Za-z]{2,}" "$f"; then n_mail=$((n_mail+1)); echo "     email-shaped string in $(basename "$f")"; fi
done
chk "S5b no email-shaped string in any evidence script or log" "0" "$n_mail"
if printf 'someone%sexample.com\n' "$AT" | /usr/bin/grep -qE "[A-Za-z0-9._%+-]+${AT}[A-Za-z0-9.-]+\.[A-Za-z]{2,}"; then ok "S5-control the email detector fires on a synthetic address"; else bad "S5-control the email detector does not fire"; fi
GH='gh'; UP='_'
if /usr/bin/grep -qE "${GH}[pousr]${UP}[A-Za-z0-9]{30,}" "$DEC"; then bad "S5c a token-shaped string appears"; else ok "S5c no token-shaped string in the decision"; fi
for pat in '*.rs' 'Cargo.toml' 'Cargo.lock'; do
  chk "S5d no $pat anywhere under the run directory" "0" "$(find "$RUN" -name "$pat" | /usr/bin/grep -c . || true)"
done
for d in target src; do
  chk "S5e no $d/ directory anywhere under the run directory" "0" "$(find "$RUN" -type d -name "$d" | /usr/bin/grep -c . || true)"
done
chk "S5f no nested .git (file or directory) under the run directory" "0" "$(find "$RUN" -name '.git' | /usr/bin/grep -c . || true)"
chk "S5g the eight committed probe lockfiles" "8" "$(find "$HERE/probe-locks" -name '*.lock' | /usr/bin/grep -c . || true)"

# ---------------------------------------------------------------------------
echo
echo "=== S6. the sibling logs this decision cites, and the totals it states ==="
for pair in "r74-probe-r2 87" "r74-registry-figures-r2 130" "r74-rest-conformance 48" "r74-citations 134" "r74-registry-figures 88"; do
  read -r base n <<< "$pair"
  log="$HERE/$base.log"
  if [ -f "$log" ]; then
    chk "S6 $base.log records FAILURES: 0" "1" "$(/usr/bin/grep -c 'FAILURES: 0 ' "$log" || true)"
    chk "S6 $base.log records CHECKS RUN: $n" "1" "$(/usr/bin/grep -c "CHECKS RUN: $n " "$log" || true)"
  else
    bad "S6 $base.log absent"; bad "S6 $base.log absent"
  fi
done
for pair in "r74-probe-r2 87" "r74-registry-figures-r2 130" "r74-rest-conformance 48" "r74-citations 134"; do
  read -r base n <<< "$pair"
  chk "S6t the Empirical-check table states $n checks, all passing, for $base.sh" "1" \
    "$(cnt "^| \`$base.sh\` | $n | $n PASS, 0 FAIL, 0 SKIP" "$DEC")"
done
for s in r74-probe-r2.sh r74-registry-figures-r2.sh r74-rest-conformance.sh r74-citations.sh r74-fetch-snapshots.sh r74-probe.sh r74-registry-figures.sh; do
  if [ -x "$HERE/$s" ]; then ok "S6x $s is present and executable"; else bad "S6x $s is missing or not executable"; fi
done
for m in snapshots/MANIFEST.tsv snapshots-r2/MANIFEST.tsv; do
  if [ -f "$HERE/$m" ]; then ok "S6m $m is present"; else bad "S6m $m is missing"; fi
done
if [ -f "$HERE/r74-fetch-snapshots-r2.log" ]; then ok "S6f the revision-2 fetch log is present"; else bad "S6f r74-fetch-snapshots-r2.log is missing"; fi

# ---------------------------------------------------------------------------
echo
echo "=== S7. shape parity with a published topic decision ==="
if [ -f "$PUB" ]; then
  TRE='^# [0-9]{4}-[0-9]{2}-[0-9]{2} — R[0-9]+ — [a-z0-9-]+ \((bundle|crate|pattern), (Light|Focused|Deep)\) — decision \(revision [0-9]+\)$'
  chk "S7a both titles match the dated revision-title grammar" "1 1" \
    "$(sed -n 1p "$DEC" | /usr/bin/grep -cE "$TRE" || true) $(sed -n 1p "$PUB" | /usr/bin/grep -cE "$TRE" || true)"
  chk "S7b the H2 sequence equals the published decision's" "$(/usr/bin/grep '^## ' "$PUB" | tr '\n' '|')" "$h2s"
  p_dec="$(/usr/bin/grep -n '^## Decision$' "$PUB" | cut -d: -f1)"
  p_par="$(/usr/bin/grep -n '^## Parameters$' "$PUB" | cut -d: -f1)"
  p_rv="$(/usr/bin/grep -n '^re-verify: ' "$PUB" | cut -d: -f1)"
  chk "S7c both place 're-verify:' two lines above ## Parameters" "2 2" "$((p_par - p_rv)) $((par_line - rv_line))"
  p_pr="$(/usr/bin/grep -n '^### Principles and implementation$' "$PUB" | cut -d: -f1)"
  d_pr="$(/usr/bin/grep -n '^### Principles and implementation$' "$DEC" | cut -d: -f1)"
  if [ "$p_pr" -gt "$p_dec" ] && [ "$p_pr" -lt "$p_par" ] && [ "$d_pr" -gt "$dec_line" ] && [ "$d_pr" -lt "$par_line" ]; then
    ok "S7d both carry '### Principles and implementation' inside ## Decision"
  else
    bad "S7d '### Principles and implementation' is outside ## Decision in one of the two"
  fi
  p_rn="$(/usr/bin/grep -n '^\*\*Revision note' "$PUB" | head -1 | cut -d: -f1)"
  if [ -n "$p_rn" ] && [ "$p_rn" -lt "$p_dec" ] && [ "$rn_line" -lt "$dec_line" ]; then ok "S7e both carry a revision note before ## Decision"; else bad "S7e revision-note placement differs"; fi
  n_same=0
  while IFS= read -r line; do
    if /usr/bin/grep -qxF -- "$line" "$PUB"; then n_same=$((n_same+1)); fi
  done < "$TMPD/decision-assumes"
  chk "S7f each of the four '- assumes' lines appears verbatim in the published decision" "4" "$n_same"
else
  for l in S7a S7b S7c S7d S7e S7f; do skip "$l published comparator absent"; done
fi

# ---------------------------------------------------------------------------
echo
echo "=== S8. the raw legs pass the raw-answer shape check (the check's own target) ==="
if [ -x "$ROOT/scripts/check-answer-shape.sh" ] || [ -f "$ROOT/scripts/check-answer-shape.sh" ]; then
  for pair in "S8a muse" "S8b opus"; do
    read -r id leg <<< "$pair"
    if out="$(bash "$ROOT/scripts/check-answer-shape.sh" "$RUN/raw/$leg.md" bundle 2>&1)"; then
      ok "$id raw/$leg.md passes scripts/check-answer-shape.sh … bundle ($out)"
    else
      bad "$id raw/$leg.md fails the shape check: $out"
    fi
  done
else
  skip "S8a scripts/check-answer-shape.sh not found"; skip "S8b scripts/check-answer-shape.sh not found"
fi

echo
echo "CHECKS RUN: $((PASS + FAIL + SKIP))  PASS: $PASS  FAILURES: $FAIL  SKIPPED: $SKIP"
[ "$FAIL" -eq 0 ]
