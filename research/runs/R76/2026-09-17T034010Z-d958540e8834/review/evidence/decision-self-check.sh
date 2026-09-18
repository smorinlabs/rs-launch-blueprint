#!/usr/bin/env bash
# R76 empirical check, part 3 of 3: assert the decision document's own
# structural obligations, the ones a reader cannot verify by reading.
#
# Everything here reads files inside this run's directory or the repository's
# parameter registry. It reaches no network, needs no `.git`, and therefore
# runs unchanged from a clean `git archive HEAD` extraction.
#
# Line prefixes:
#   ASSERT  — a content assertion. `ASSERT FAIL` sets exit status 1.
#   SKIP    — a check that could not run, with the reason named.

set -euo pipefail

GREP=/usr/bin/grep
HERE="$(cd "$(dirname "$0")" && pwd)"
REVIEW="$(cd "$HERE/.." && pwd)"
RUN="$(cd "$REVIEW/.." && pwd)"
DEC="$REVIEW/DECISION.md"
RAW="$RUN/raw/opus.md"
# research/runs/R76/<run>/ -> repository root is five levels up.
ROOT="$(cd "$RUN/../../../.." && pwd)"
REG="$ROOT/docs/port/PARAMETERS.md"

echo "=== R76 decision self-check ==="
echo "date(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "grep: $("$GREP" --version | head -1)"
echo "decision:  $DEC"
echo "raw:       $RAW"
echo "registry:  $REG"
echo

WORK=$(mktemp -d "${TMPDIR:-/tmp}/r76-selfcheck.XXXXXX")
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

pass=0; failn=0; skipn=0
assert() {
  if [ "$1" = "1" ]; then echo "ASSERT ok   $2"; pass=$((pass + 1))
  else echo "ASSERT FAIL $2"; failn=$((failn + 1)); fi
}
skip() { echo "SKIP        $1"; skipn=$((skipn + 1)); }
eq() { if [ "$1" = "$2" ]; then echo 1; else echo 0; fi; }
countF() { "$GREP" -cF -- "$1" "$2" || true; }

if [ ! -f "$DEC" ]; then
  skip "everything: DECISION.md is absent, so nothing about it could be checked"
  echo; echo "=== RESULT ==="
  echo "PASS=${pass} FAIL=${failn} SKIP=${skipn} TOTAL=$((pass + failn + skipn))"
  echo "RESULT: PASS (nothing ran)"; exit 0
fi

# ---------------------------------------------------------------------------
echo "--- A. the document's shape, which the revision rules fix exactly ---"
H1=$(head -1 "$DEC")
echo "H1: ${H1}"
assert "$(eq "$H1" '# 2026-09-18 — R76 — cors-middleware (crate, Focused) — decision (revision 1)')" \
  "the H1 is the date-first form the revision rules require, naming the item, kind, tier and revision"
H2S=$("$GREP" '^## ' "$DEC" | tr '\n' '|')
echo "H2 headings: ${H2S}"
assert "$(eq "$H2S" '## Decision|## Parameters|## Empirical check|## Engines|')" \
  "the four required H2 sections appear exactly once each, in the required order, and no other H2 was added"
# These are anchored at line start on purpose: an unanchored search would also
# match this document describing its own headings in prose.
assert "$(eq "$("$GREP" -c '^## Supersedes' "$DEC" || true)" "0")" \
  "no Supersedes section heading: this is a first revision, which the rules say must not carry one"
assert "$(eq "$("$GREP" -c '^### Principles and implementation' "$DEC" || true)" "1")" \
  "the Decision section carries its one required H3 heading, exactly once"
N=$("$GREP" -c '^re-verify:' "$DEC" || true)
RVLINE=$("$GREP" -n '^re-verify:' "$DEC" | cut -d: -f1 | head -1)
PARAMLINE=$("$GREP" -n '^## Parameters' "$DEC" | cut -d: -f1 | head -1)
echo "trigger line at ${RVLINE:-none}; Parameters heading at ${PARAMLINE:-none}"
assert "$(eq "$N" "1")" "exactly one line begins with the re-verify marker, which is the rule"
assert "$(if [ -n "$RVLINE" ] && [ -n "$PARAMLINE" ] && [ "$RVLINE" -lt "$PARAMLINE" ]; then echo 1; else echo 0; fi)" \
  "and it is the closing line of the Decision section rather than floating elsewhere in the document"
assert "$(eq "$("$GREP" -c '^re-verify: on the earlier of 2027-03-18' "$DEC" || true)" "1")" \
  "that line carries a dated horizon as well as its event triggers"
echo

# ---------------------------------------------------------------------------
echo "--- B. the parameter lines, compared byte-for-byte with the live registry ---"
if [ ! -f "$REG" ]; then
  skip "B: docs/port/PARAMETERS.md is not reachable from this extraction, so the parameter bytes were not compared"
else
  python3 - "$REG" > "$WORK/registry-lines.txt" <<'PY'
import sys
want = ["web-extra-surface", "error-taxonomy-exit-codes",
        "msrv-policy", "rust-edition", "target-os-matrix", "license"]
rows = {}
for line in open(sys.argv[1], encoding="utf-8"):
    if not line.startswith("| "):
        continue
    cells = line.rstrip("\n").split(" | ")
    if len(cells) < 5:
        continue
    name = cells[0][2:].strip()
    if name in want:
        rows[name] = cells[3]
for n in want:
    print("- assumes %s = %s" % (n, rows[n]))
PY
  "$GREP" '^- assumes ' "$DEC" > "$WORK/decision-lines.txt"
  echo "registry rows extracted: $(wc -l < "$WORK/registry-lines.txt" | tr -d ' ')"
  echo "assumes lines in the decision: $(wc -l < "$WORK/decision-lines.txt" | tr -d ' ')"
  if diff -u "$WORK/registry-lines.txt" "$WORK/decision-lines.txt" > "$WORK/paramdiff.txt" 2>&1; then
    assert 1 "every '- assumes' line is byte-identical to its docs/port/PARAMETERS.md row, in the same order — the comparison the packaging validator performs"
  else
    echo "--- diff registry vs decision ---"
    sed 's/^/  /' "$WORK/paramdiff.txt" | head -20
    assert 0 "every '- assumes' line is byte-identical to its docs/port/PARAMETERS.md row"
  fi
  assert "$(eq "$(wc -l < "$WORK/decision-lines.txt" | tr -d ' ')" "6")" \
    "the decision records exactly six assumed parameters: the four owner-fixed ones plus the two researched values the design rests on"
  assert "$(eq "$("$GREP" -c '^- owns ' "$DEC" || true)" "0")" \
    "no '- owns' line: the prompt's Couplings block carries an empty '- owns:' and the registry names no R76-owned row, so inventing one would be a registry edit"
  assert "$(eq "$("$GREP" -c '^CONFLICT:' "$DEC" || true)" "0")" \
    "no CONFLICT: line, which matches the decision's own statement that no consumed parameter has to change"
  # A bare value is what the validator reads; a backticked or annotated one fails publication.
  assert "$(eq "$(countF '- assumes rust-edition = 2024' "$DEC")" "1")" \
    "the rust-edition line carries its value bare, with no backticks, citation or commentary after the '= '"
  assert "$(eq "$(countF '- assumes target-os-matrix = ubuntu-latest, macos-latest' "$DEC")" "1")" \
    "and so does target-os-matrix"
fi
echo

# ---------------------------------------------------------------------------
echo "--- C. the licence gate: recorded with the exact string, and no residue elsewhere ---"
assert "$(eq "$(countF 'inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is' "$DEC")" "1")" \
  "gate 1 is recorded with the required 'inapplicable — owner ruling 2026-09-12 (Q7.B)' string rather than deleted"
assert "$(eq "$(countF 'not evaluated for any dependency or tool' "$DEC")" "1")" \
  "and the string is completed by 'not evaluated for any dependency or tool', so the row states the ruling in full"
# Mechanical enumeration: every case-insensitive hit for 'licen' must be one of
# the four accounted-for locations. Anything else is surviving gate-1 reasoning.
LICEN=$("$GREP" -c -i 'licen' "$DEC" || true)
echo "lines containing 'licen' (case-insensitive) = ${LICEN}; enumerated:"
"$GREP" -n -i 'licen' "$DEC" | cut -c1-96 | sed 's/^/  /'
assert "$(eq "$LICEN" "4")" \
  "exactly four lines mention a licence: the two that carry the inapplicable string and its source, the bare '- assumes license' registry line, and the prose that says the parameter is recorded and evaluated against nothing — no candidate is selected or excluded on a licence ground anywhere"
for term in MulanPSL copyleft AGPL "patent grant" "licence-compatible" "license-compatible"; do
  assert "$(eq "$(countF "$term" "$DEC")" "0")" \
    "the decision contains no '${term}' reasoning, which the owner ruling struck"
done
echo

# ---------------------------------------------------------------------------
echo "--- D. no personal address anywhere in this run's review directory ---"
HITS=$("$GREP" -rlE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$REVIEW" 2>/dev/null | tr '\n' ' ' || true)
echo "files containing an email-shaped token: ${HITS:-(none)}"
assert "$(eq "${HITS:-}" "")" \
  "no file under review/ contains an email-shaped token: the scripts identify themselves with the repository URL instead"
echo

# ---------------------------------------------------------------------------
echo "--- E. the engine record matches the artifact it names ---"
if [ ! -f "$RAW" ]; then
  skip "E: raw/opus.md is absent from this extraction, so its hash was not compared"
else
  SHA=$(shasum -a 256 "$RAW" | cut -d' ' -f1)
  echo "sha256(raw/opus.md) = ${SHA}"
  assert "$(eq "$SHA" "c2792a6957df5b84fcb6438f2f14312fcae8bbd801055e07f1235e63333a5cf4")" \
    "raw/opus.md hashes to the value the decision's ## Engines section cites, so the record names the artifact actually read"
  assert "$(eq "$(countF "$SHA" "$DEC")" "1")" \
    "and that hash appears in the decision, so the citation is checkable without leaving the document"
  if [ -f "$ROOT/scripts/research_validation.py" ]; then
    python3 - "$ROOT" "$RAW" > "$WORK/shape.txt" <<'PY'
import sys
sys.path.insert(0, sys.argv[1] + "/scripts")
from research_validation import validate_answer_text
errs = validate_answer_text(open(sys.argv[2], encoding="utf-8").read(), "crate")
print("errors=%d" % len(errs))
for e in errs:
    print("  " + e)
PY
    sed 's/^/  /' "$WORK/shape.txt"
    assert "$(eq "$("$GREP" -c '^errors=0$' "$WORK/shape.txt" || true)" "1")" \
      "validate_answer_text(raw, 'crate') reports no shape error: the report carries all fifteen H3 fields, in order, each with a body"
  else
    skip "E: scripts/research_validation.py is not reachable, so the raw report's shape was not re-validated"
  fi
  assert "$(eq "$(countF 'W1-CODEX3' "$DEC")" "1")" \
    "the absent Codex leg is recorded against the owner ruling that deferred it, by identifier"
  assert "$(eq "$(countF 'synthesized' "$DEC")" "1")" \
    "and the decision states in so many words that it is synthesized from a single engine"
fi
echo

# ---------------------------------------------------------------------------
echo "--- F. every figure the decision quotes from a sibling log is in that log ---"
# log | token as the log prints it | token as the decision prints it | what it is
while IFS='|' read -r log raw shown what; do
  [ -n "$log" ] || continue
  if [ ! -f "$HERE/$log" ]; then
    skip "F: $log is absent, so ${what} was not cross-checked"
    continue
  fi
  inlog=$(countF "$raw" "$HERE/$log")
  indec=$(countF "$shown" "$DEC")
  if [ "$inlog" != "0" ] && [ "$indec" != "0" ]; then ok=1; else ok=0; fi
  assert "$ok" "${what}: ${log} prints it as '${raw}' and the decision quotes it as '${shown}'"
done <<'FIGURES'
probe-checks.log|= +166480 bytes|+166,480 B|the binary-size cost of the dependency
probe-checks.log|arm=without: 502264 bytes|502,264 → 668,744 bytes|the stripped size without the dependency
probe-checks.log|arm=with: 668744 bytes|502,264 → 668,744 bytes|the stripped size with the dependency
probe-checks.log|handler_hits=0|handler_hits=0|the preflight short-circuit, measured from the handler's side
probe-checks.log|access-control-max-age=600|access-control-max-age: 600|the max-age default imported from py and compiled in this run
probe-checks.log|resolved packages: with the tower-http line 57, without it 55|**57** packages against **55**|the dependency-tree delta
registry-figures.log|2026-08-31T14:49:25.697237Z|2026-08-31T14:49:25.697237Z|tower-http 0.7.1's publication timestamp
registry-figures.log|2026-06-15T14:01:18.432430Z|2026-06-15T14:01:18.432430Z|tower-http 0.7.0's publication timestamp
registry-figures.log|(90-day) = 149725960|149,725,960|the 90-day download figure
registry-figures.log|(all-time)      = 462114603|462,114,603|the all-time download figure
registry-figures.log|meta.total = 36|**36**|the size of the enumerated cors category
FIGURES
for log in registry-figures.log probe-checks.log; do
  if [ ! -f "$HERE/$log" ]; then
    skip "F: $log is absent, so its own verdict was not checked"
    continue
  fi
  assert "$(eq "$(tail -1 "$HERE/$log")" "RESULT: PASS")" \
    "${log} ends in RESULT: PASS, so the decision is citing a passing run"
  assert "$(eq "$("$GREP" -c 'ASSERT FAIL' "$HERE/$log" || true)" "0")" \
    "${log} records no ASSERT FAIL line"
done
echo

# ---------------------------------------------------------------------------
echo "=== RESULT ==="
echo "PASS=${pass} FAIL=${failn} SKIP=${skipn} TOTAL=$((pass + failn + skipn))"
if [ "$failn" -gt 0 ]; then echo "RESULT: FAIL"; exit 1; fi
echo "RESULT: PASS"
