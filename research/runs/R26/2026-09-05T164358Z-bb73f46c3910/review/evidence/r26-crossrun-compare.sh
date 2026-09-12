#!/usr/bin/env bash
# R26 packed-artifact-content-guard — cross-run comparison check (revision 3).
#
# Purpose: prove the comparison rule stated in review/DECISION.md. It reruns the
# archived empirical check `review/evidence/r26-check.sh` under the four
# environments a rerun can legitimately present, classifies every line that
# differs from the cited log `review/evidence/packed-artifact-guard.log` into one
# of four named difference classes, and asserts that nothing is left over.
#
# Publishes nothing. It invokes only r26-check.sh, diff, sed, grep and python3;
# `cargo publish` is never invoked, in any form, including `--dry-run`.
#
# Run from the run directory:
#   bash review/evidence/r26-crossrun-compare.sh
#
# Difference classes (the rule):
#   C1 diff-header          `---`/`+++` lines from `diff -u`: absolute $SCRATCH
#                           path plus wall-clock mtime.
#   C2 compressed-size      the parenthesized compressed size in Cargo's
#                           `Packaged N files, X (Y compressed)` line.
#   C3 packaging-path       the absolute probe path in Cargo's
#                           `Packaging <pkg> v<ver> (<path>)` line.
#   C4 listing-collation    the relative order of `src` and `STRAY.txt` in phase
#                           2's `ls -1` listing, which follows the runner
#                           shell's collation locale.
set -u
set -o pipefail

FAILS=0
assert_eq() { # assert_eq <label> <expected> <actual>
  if [ "$2" = "$3" ]; then
    printf 'PASS %s (%s)\n' "$1" "$3"
  else
    printf 'FAIL %s (expected %s, got %s)\n' "$1" "$2" "$3"
    FAILS=$((FAILS + 1))
  fi
}
hr() { printf '\n===== %s =====\n' "$1"; }

CHECK=review/evidence/r26-check.sh
CITED=review/evidence/packed-artifact-guard.log
AUDIT_R2=review/evidence/audit-packed-artifact-content-guard-r2.log
AUDIT_R1=review/evidence/audit-packed-artifact-content-guard-r1.log
R1_CITED_COMMIT=1b42a99   # the commit whose blob is revision 1's cited log
R1_CITED_PATH=research/runs/R26/2026-09-05T164358Z-bb73f46c3910/review/evidence/packed-artifact-guard.log

# The check script's own SCRATCH, read from the script so the two cannot drift.
BASE_SCRATCH=$(sed -n 's/^SCRATCH="\(.*\)"$/\1/p' "$CHECK")
WORK="${TMPDIR:-/tmp}/r26-crossrun.$$"
ALT="$WORK/alt-scratch"
rm -rf "$WORK"; mkdir -p "$WORK" "$ALT"
trap 'rm -rf "$WORK"' EXIT

CLASSIFY="$WORK/classify.py"
cat > "$CLASSIFY" <<'PY'
import re, sys
# classify.py <fileA> <fileB> [firstN]
# Compares index by index. Prints one line per difference class observed and one
# UNCLASSIFIED line per line it cannot place, then a summary line
# "classified=<n> unclassified=<n> violations=<n> classes=<c1,c2,...>".
# A "violation" is a classified line outside its class's fixed candidate set:
# the rule names not only the kinds of line that may differ but the exact lines
# of this 377-line log at which each kind occurs.
a = open(sys.argv[1], encoding="utf-8", errors="replace").read().split("\n")
b = open(sys.argv[2], encoding="utf-8", errors="replace").read().split("\n")
if len(sys.argv) > 3:
    n = int(sys.argv[3]); a, b = a[:n], b[:n]
if len(a) != len(b):
    print(f"UNCLASSIFIED line-count {len(a)} vs {len(b)}")
    print("classified=0 unclassified=1 violations=1 classes=")
    sys.exit(0)

# The lines of review/evidence/packed-artifact-guard.log at which each class may
# occur. A differing line of the right shape at any other line number is a
# violation, not an allowed difference.
CANDIDATES = {
    "C1-diff-header": {113, 114, 134, 135, 157, 158},
    "C2-compressed-size": {89, 130, 178},
    "C3-packaging-path": {88, 128, 177},
    "C4-listing-collation": {62, 63},
}

HDR = re.compile(r"^(---|\+\+\+) /.*\t\d{4}-\d\d-\d\d \d\d:\d\d:\d\d$")
PACKAGED = re.compile(r"^\s*Packaged \d+ files, [\d.]+(?:B|KiB|MiB) \([\d.]+(?:B|KiB|MiB) compressed\)$")
PACKAGED_SUB = re.compile(r"\([\d.]+(?:B|KiB|MiB) compressed\)")
PACKAGING = re.compile(r"^\s*Packaging \S+ v\S+ \(/.*\)$")
PACKAGING_SUB = re.compile(r"\(/.*\)$")
COLLATED = {"src", "STRAY.txt"}

diff_ix = [i for i in range(len(a)) if a[i] != b[i]]
cls = {}
unclassified = []
for i in diff_ix:
    x, y = a[i], b[i]
    if HDR.match(x) and HDR.match(y):
        cls.setdefault("C1-diff-header", []).append(i + 1)
    elif PACKAGED.match(x) and PACKAGED.match(y) and \
            PACKAGED_SUB.sub("()", x) == PACKAGED_SUB.sub("()", y):
        cls.setdefault("C2-compressed-size", []).append(i + 1)
    elif PACKAGING.match(x) and PACKAGING.match(y) and \
            PACKAGING_SUB.sub("()", x) == PACKAGING_SUB.sub("()", y):
        cls.setdefault("C3-packaging-path", []).append(i + 1)
    else:
        unclassified.append(i)

# C4 is a reciprocal transposition of `src` and `STRAY.txt` at adjacent indices.
rest = set(unclassified)
for i in sorted(rest):
    j = i + 1
    if j in rest and a[i] == b[j] and a[j] == b[i] and {a[i], a[j]} == COLLATED:
        cls.setdefault("C4-listing-collation", []).extend([i + 1, j + 1])
        rest.discard(i); rest.discard(j)

violations = 0
# Every class is printed on every comparison, present or absent, so the log's
# line count does not move with what a given pair of runs happened to differ in.
for name in sorted(CANDIDATES):
    got = sorted(cls.get(name, []))
    bad = sorted(set(got) - CANDIDATES[name])
    violations += len(bad)
    suffix = f" OUTSIDE-CANDIDATES={','.join(str(n) for n in bad)}" if bad else ""
    print(f"{name} lines={','.join(str(n) for n in got)}{suffix}")
for i in sorted(rest):
    print(f"UNCLASSIFIED line {i + 1}: {a[i]!r} -> {b[i]!r}")
n_cls = sum(len(v) for v in cls.values())
print(f"classified={n_cls} unclassified={len(rest)} violations={violations} "
      f"classes={','.join(sorted(cls))}")
PY

OBSERVED="$WORK/observed-classes.txt"
: > "$OBSERVED"

compare() { # compare <label> <fileA> <fileB> [firstN]
  local label="$1" fa="$2" fb="$3" n="${4:-}"
  echo "--- $label"
  python3 "$CLASSIFY" "$fa" "$fb" ${n:+"$n"} > "$WORK/c.out"
  sed -E 's#/private/tmp/[^ )[:space:]]*#<PATH>#g; s#'"$WORK"'#<WORK>#g' "$WORK/c.out"
  grep -o 'classes=.*' "$WORK/c.out" | sed 's/classes=//' | tr ',' '\n' | grep -v '^$' >> "$OBSERVED"
  assert_eq "$label/unclassified" 0 "$(sed -n 's/.*unclassified=\([0-9]*\).*/\1/p' "$WORK/c.out")"
  assert_eq "$label/outside-candidate-lines" 0 \
    "$(sed -n 's/.*violations=\([0-9]*\).*/\1/p' "$WORK/c.out")"
}

shape() { # shape <label> <log> — the invariants a conforming rerun must hold
  local label="$1" f="$2"
  assert_eq "$label/line-count" 377 "$(wc -l < "$f" | tr -d ' ')"
  assert_eq "$label/pass-lines" 22 "$(grep -c '^PASS ' "$f")"
  assert_eq "$label/fail-lines" 0 "$(grep -c '^FAIL ' "$f")"
  assert_eq "$label/failed-assertions-line" 1 "$(grep -c '^failed assertions: 0$' "$f")"
  assert_eq "$label/pass-block-identical" "same" \
    "$(diff -q <(grep '^PASS ' "$CITED") <(grep '^PASS ' "$f") >/dev/null && echo same || echo differs)"
}

hr "PHASE A — preconditions"
cargo --version
rustc --version
uname -sm
sw_vers | tr '\n' ' '; echo
echo "check script:   $CHECK  sha256 $(shasum -a 256 "$CHECK" | awk '{print $1}')"
echo "cited log:      $CITED  sha256 $(shasum -a 256 "$CITED" | awk '{print $1}')"
echo "base SCRATCH:   $BASE_SCRATCH"
echo "ambient locale: LANG=${LANG:-unset} LC_ALL=${LC_ALL:-unset} LC_COLLATE=${LC_COLLATE:-unset}"
for f in toml_mod.rs pkg_mod.rs book-CHANGELOG.md; do
  assert_eq "pre/pinned-input-present:$f" 1 "$([ -f "$BASE_SCRATCH/$f" ] && echo 1 || echo 0)"
  cp "$BASE_SCRATCH/$f" "$ALT/$f" 2>/dev/null || true
  assert_eq "pre/pinned-input-copied-to-alt:$f" 1 "$([ -f "$ALT/$f" ] && echo 1 || echo 0)"
done
shape "pre/cited" "$CITED"

hr "PHASE B — five reruns of the archived check"
echo "run 1 (as archived, ambient locale)"
bash "$CHECK" > "$WORK/run1.log" 2>&1; assert_eq "run1/exit" 0 "$?"
echo "run 2 (as archived, ambient locale, immediately after run 1)"
bash "$CHECK" > "$WORK/run2.log" 2>&1; assert_eq "run2/exit" 0 "$?"
echo "run 3 (SCRATCH repointed to <work>/alt-scratch)"
sed "s|^SCRATCH=.*|SCRATCH=\"$ALT\"|" "$CHECK" | bash > "$WORK/run3.log" 2>&1
assert_eq "run3/exit" 0 "$?"
echo "run 4 (as archived, LC_ALL=C)"
env -u LANG -u LC_COLLATE -u LC_CTYPE -u LC_MESSAGES -u LC_MONETARY -u LC_NUMERIC \
  -u LC_TIME LC_ALL=C bash "$CHECK" > "$WORK/run4.log" 2>&1
assert_eq "run4/exit" 0 "$?"
echo "run 5 (SCRATCH repointed AND LC_ALL=C — the revision-2 auditor's environment)"
sed "s|^SCRATCH=.*|SCRATCH=\"$ALT\"|" "$CHECK" \
  | env -u LANG -u LC_COLLATE -u LC_CTYPE -u LC_MESSAGES -u LC_MONETARY -u LC_NUMERIC \
      -u LC_TIME LC_ALL=C bash > "$WORK/run5.log" 2>&1
assert_eq "run5/exit" 0 "$?"
for r in 1 2 3 4 5; do shape "run$r" "$WORK/run$r.log"; done

hr "PHASE C — recover revision 1's cited log and the archived audit reruns"
git show "$R1_CITED_COMMIT:$R1_CITED_PATH" > "$WORK/r1-cited.log"
assert_eq "phaseC/r1-cited-recovered" 363 "$(wc -l < "$WORK/r1-cited.log" | tr -d ' ')"
assert_eq "phaseC/audit-r2-present" 377 "$(wc -l < "$AUDIT_R2" | tr -d ' ')"
assert_eq "phaseC/audit-r1-present" 234 "$(wc -l < "$AUDIT_R1" | tr -d ' ')"
shape "phaseC/audit-r2" "$AUDIT_R2"

hr "PHASE D — classify every differing line against the cited log"
compare "cited-vs-run1" "$CITED" "$WORK/run1.log"
compare "run1-vs-run2" "$WORK/run1.log" "$WORK/run2.log"
compare "cited-vs-run3-altscratch" "$CITED" "$WORK/run3.log"
compare "cited-vs-run4-clocale" "$CITED" "$WORK/run4.log"
compare "cited-vs-run5-altscratch-clocale" "$CITED" "$WORK/run5.log"
compare "cited-vs-audit-r2-rerun" "$CITED" "$AUDIT_R2"
echo "--- phases 0-7 only (first 233 lines), against the revision-1 logs:"
compare "cited-vs-r1-cited-phases0to7" "$CITED" "$WORK/r1-cited.log" 233
compare "cited-vs-audit-r1-phases0to7" "$CITED" "$AUDIT_R1" 233

hr "PHASE E — the rule is not vacuous: each class was actually observed"
sort -u "$OBSERVED"
for c in C1-diff-header C2-compressed-size C3-packaging-path C4-listing-collation; do
  assert_eq "coverage/$c" 1 "$(grep -cx "$c" "$OBSERVED" >/dev/null 2>&1 && echo 1 || echo 0)"
done

hr "PHASE E2 — the observed spread of the C2 compressed-size class"
echo "The three 'Packaged' lines of each log, at cited-log lines 89, 130 and 178."
echo "Their compressed sizes are what class C2 admits; the rest of each line is fixed."
for f in "$CITED" "$AUDIT_R1" "$AUDIT_R2" "$WORK"/run[1-5].log; do
  printf '%-34s %s\n' "$(basename "$f")" \
    "$(grep -oE 'Packaged [0-9]+ files, [0-9.]+(B|KiB|MiB) \([0-9.]+(B|KiB|MiB) compressed\)' "$f" \
       | sed -E 's/Packaged [0-9]+ files, [0-9.]+(B|KiB|MiB) \(([0-9.]+(B|KiB|MiB)) compressed\)/\2/' \
       | tr '\n' ' ')"
done
for ln in 89 130 178; do
  assert_eq "spread/cited-line-$ln-is-C2-shaped" 1 \
    "$(sed -n "${ln}p" "$CITED" \
       | grep -cE '^\s*Packaged [0-9]+ files, [0-9.]+(B|KiB|MiB) \([0-9.]+(B|KiB|MiB) compressed\)$')"
done

hr "PHASE F — negative control: the classifier does catch a real difference"
sed '1,$s/^PASS phase9\/edition (\"2024\")$/PASS phase9\/edition ("2023")/' \
  "$WORK/run1.log" > "$WORK/mutated.log"
assert_eq "negctl/mutation-applied" 1 \
  "$(diff "$WORK/run1.log" "$WORK/mutated.log" | grep -c '^> PASS phase9/edition')"
python3 "$CLASSIFY" "$WORK/run1.log" "$WORK/mutated.log" > "$WORK/neg.out"
sed -E 's#/private/tmp/[^ )[:space:]]*#<PATH>#g' "$WORK/neg.out"
assert_eq "negctl/unclassified" 1 "$(sed -n 's/.*unclassified=\([0-9]*\).*/\1/p' "$WORK/neg.out")"
assert_eq "negctl/pass-block-differs" "differs" \
  "$(diff -q <(grep '^PASS ' "$CITED") <(grep '^PASS ' "$WORK/mutated.log") >/dev/null \
     && echo same || echo differs)"
echo "--- second negative control: a class-shaped difference at a line the rule does not allow"
sed '60s|.*|   Packaging rsguard v0.1.0 (/probe-one)|' "$WORK/run1.log" > "$WORK/shaped-a.log"
sed '60s|.*|   Packaging rsguard v0.1.0 (/probe-two)|' "$WORK/run1.log" > "$WORK/shaped-b.log"
python3 "$CLASSIFY" "$WORK/shaped-a.log" "$WORK/shaped-b.log" > "$WORK/neg2.out"
grep -E 'OUTSIDE-CANDIDATES|^classified=' "$WORK/neg2.out"
assert_eq "negctl2/unclassified" 0 "$(sed -n 's/.*unclassified=\([0-9]*\).*/\1/p' "$WORK/neg2.out")"
assert_eq "negctl2/outside-candidate-lines" 1 \
  "$(sed -n 's/.*violations=\([0-9]*\).*/\1/p' "$WORK/neg2.out")"

hr "PHASE G — publish safety"
assert_eq "safety/no-publish-invocation-in-check" 0 \
  "$(grep -cE '(^|[;&|[:space:]])cargo[[:space:]]+publish' "$CHECK")"
assert_eq "safety/no-publish-invocation-in-compare" 0 \
  "$(grep -cE '(^|[;&|[:space:]])cargo[[:space:]]+publish' review/evidence/r26-crossrun-compare.sh)"

hr "DONE"
echo "failed assertions: $FAILS"
exit "$FAILS"
