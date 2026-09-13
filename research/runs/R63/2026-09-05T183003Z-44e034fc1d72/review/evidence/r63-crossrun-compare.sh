#!/usr/bin/env bash
# R63 progress-spinner — cross-run comparison check (revision 3).
#
# WHY THIS EXISTS. Revision 2 stated a difference rule — "a rerun may differ
# from the cited log only in lines carrying the `VOLATILE: ` or `HOST: ` prefix"
# — and then cited a log that did not satisfy it. The revision-2 auditor's rerun
# differed from the revision-2 cited log at two UNPREFIXED regions, both emitted
# through `sort`: the presence-checked variable list of section 3, and the
# shipped-file listing of section 12. The cause was collation: the cited log was
# produced under `en_US.UTF-8` and the rerun under the C locale. The rule was
# not reproducible under its own terms.
#
# WHAT THIS SCRIPT DOES. It makes the rule testable instead of asserted. It
# reruns the archived check `review/evidence/r63-spinner-claims.sh` under three
# environments, classifies EVERY differing line into a named, enumerated
# difference class with a fixed set of allowed line positions, and asserts that
# nothing is left unclassified and nothing is out of position. It then runs
# negative controls proving the classifier REJECTS an unclassified difference,
# an out-of-position difference of each class shape, and a line-count change.
#
# THE DIFFERENCE RULE, STATED PRECISELY AND IN FULL.
#   Let CITED be `review/evidence/r63-spinner-claims.log`. A conforming rerun R
#   of `review/evidence/r63-spinner-claims.sh` satisfies ALL of:
#     (R1) `wc -l R` equals `wc -l CITED`. The check emits a fixed number of
#          lines by construction: every block quoted from a moving branch or a
#          live endpoint passes through `volk <K>`, which always emits exactly
#          K+1 lines. A line-count change therefore means the SCRIPT changed,
#          and is a rejection, not a tolerated drift.
#     (R2) For each line index i, either R[i] == CITED[i], or the difference
#          falls in exactly one of these two classes:
#            V — live-figure drift. BOTH R[i] and CITED[i] begin with the
#                literal 8-byte prefix `VOLATILE: `. These are the download,
#                star, open-issue, `pushed_at`, wall-clock-date and
#                moving-branch lines, whose values move between runs and decide
#                no gate. Allowed positions: exactly the line numbers at which
#                CITED itself carries that prefix.
#            H — host identity. BOTH R[i] and CITED[i] begin with the literal
#                6-byte prefix `HOST: `. These are the `rustc`/`cargo` version,
#                the operating system, and the ambient locale of the machine
#                that ran the check. Allowed positions: exactly the line
#                numbers at which CITED itself carries that prefix.
#     (R3) A differing line that matches a class shape at a line number outside
#          that class's allowed positions is a VIOLATION, not an allowed
#          difference. A differing line matching no class shape, including one
#          where only ONE side carries a prefix, is UNCLASSIFIED.
#   The rule admits nothing else. In particular it does NOT admit a reordered
#   `sort` output: revision 3's check pins `LC_ALL=C`, so collation is fixed.
#
# SCOPE OF WHAT IS DEMONSTRATED HERE, HONESTLY. Both classes are OBSERVED, each
# at a SMALL SUBSET of its allowed positions: class V at the wall-clock date
# line, class H at the line recording the ambient locale, which run 3 unsets.
# The other allowed positions of each class are admitted by construction and are
# exercised only by the labelled SYNTHETIC in-position control of phase H2. The
# environments exercised are three locales and three fresh scratch directories
# on one macOS arm64 host. No Linux run and no second host is claimed.
#
# Publishes nothing, builds nothing, compiles no Rust. It invokes the archived
# check, diff, grep, sed, awk and python3 only.
#
# Run from the run directory:
#   bash review/evidence/r63-crossrun-compare.sh \
#     > review/evidence/r63-crossrun-compare.log 2>&1
# It reads only committed files, so it reruns unchanged after the commit.
# Requires the same access the check requires: network, an authenticated `gh`,
# and the two pinned checkouts (override with TS_REPO / PY_REPO).

set -u
set -o pipefail

FAILS=0
assert_eq() { # assert_eq <label> <expected> <actual>
  if [ "$2" = "$3" ]; then printf 'PASS %s (%s)\n' "$1" "$3"
  else printf 'FAIL %s (expected %s, got %s)\n' "$1" "$2" "$3"; FAILS=$((FAILS + 1)); fi
}
hr() { printf '\n===== %s =====\n' "$1"; }

CHECK=review/evidence/r63-spinner-claims.sh
CITED=review/evidence/r63-spinner-claims.log
NEGCTL=review/evidence/r63-spinner-claims-negative-control.log
R2_CHECK=review/evidence/r63-spinner-claims.r2.sh
R2_CITED=review/evidence/r63-spinner-claims.r2.log
R2_AUDIT=review/evidence/audit-r63-spinner-r2.log

for f in "$CHECK" "$CITED" "$NEGCTL" "$R2_CHECK" "$R2_CITED" "$R2_AUDIT"; do
  [ -f "$f" ] || { echo "missing required file: $f"; exit 2; }
done

WORK="${TMPDIR:-/tmp}/r63-crossrun.$$"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

# --------------------------------------------------------------------------
# The classifier. Compares two logs index by index, places every differing line
# into class V or class H or leaves it UNCLASSIFIED, and checks each classified
# line against that class's allowed positions, which are read from the cited log.
CLASSIFY="$WORK/classify.py"
cat > "$CLASSIFY" <<'PY'
import sys

# classify.py <cited> <fileA> <fileB>
# Allowed positions for each class are derived from <cited>: class V may differ
# only where <cited> carries 'VOLATILE: ', class H only where it carries 'HOST: '.
# Prints one line per class (always, present or absent), one UNCLASSIFIED line
# per unplaceable difference, then the summary line
#   classified=<n> unclassified=<n> violations=<n> classes=<c1,c2,...>

PREFIX = {"V-live-figure": "VOLATILE: ", "H-host-identity": "HOST: "}

def lines(p):
    return open(p, encoding="utf-8", errors="replace").read().split("\n")

cited, a, b = lines(sys.argv[1]), lines(sys.argv[2]), lines(sys.argv[3])

cand = {name: {i + 1 for i, l in enumerate(cited) if l.startswith(pre)}
        for name, pre in PREFIX.items()}

if len(a) != len(b):
    print(f"UNCLASSIFIED line-count {len(a)} vs {len(b)}")
    for name in sorted(PREFIX):
        print(f"{name} lines=")
    print("classified=0 unclassified=1 violations=1 classes=")
    sys.exit(0)

cls, rest = {}, []
for i in range(len(a)):
    if a[i] == b[i]:
        continue
    for name, pre in PREFIX.items():
        if a[i].startswith(pre) and b[i].startswith(pre):
            cls.setdefault(name, []).append(i + 1)
            break
    else:
        rest.append(i)

violations = 0
for name in sorted(PREFIX):
    got = sorted(cls.get(name, []))
    bad = sorted(set(got) - cand[name])
    violations += len(bad)
    suffix = f" OUTSIDE-ALLOWED-POSITIONS={','.join(map(str, bad))}" if bad else ""
    print(f"{name} lines={','.join(map(str, got))}{suffix}")
for i in rest:
    print(f"UNCLASSIFIED line {i + 1}: {a[i]!r} -> {b[i]!r}")
n = sum(len(v) for v in cls.values())
print(f"classified={n} unclassified={len(rest)} violations={violations} "
      f"classes={','.join(sorted(cls))}")
PY

OBSERVED="$WORK/observed-classes.txt"
: > "$OBSERVED"

compare() { # compare <label> <fileA> <fileB> [expect-unclassified] [expect-violations]
  local label="$1" fa="$2" fb="$3" eu="${4:-0}" ev="${5:-0}"
  echo "--- $label"
  python3 "$CLASSIFY" "$CITED" "$fa" "$fb" > "$WORK/c.out"
  cat "$WORK/c.out"
  grep -o 'classes=.*' "$WORK/c.out" | sed 's/classes=//' | tr ',' '\n' | grep -v '^$' >> "$OBSERVED"
  assert_eq "$label/unclassified" "$eu" \
    "$(sed -n 's/.*unclassified=\([0-9]*\).*/\1/p' "$WORK/c.out")"
  assert_eq "$label/violations" "$ev" \
    "$(sed -n 's/.*violations=\([0-9]*\).*/\1/p' "$WORK/c.out")"
}

shape() { # shape <label> <log> — the invariants a conforming rerun must hold
  local label="$1" f="$2"
  assert_eq "$label/line-count" "$CITED_LINES" "$(wc -l < "$f" | tr -d ' ')"
  assert_eq "$label/pass-lines" "$CITED_PASS" "$(grep -c '^PASS  ' "$f" | tr -d ' ')"
  assert_eq "$label/fail-lines" 0 "$(grep -c '^FAIL  ' "$f" | tr -d ' ')"
  assert_eq "$label/summary-line" 1 \
    "$(grep -c "^checks: $CITED_PASS pass / 0 fail\$" "$f" | tr -d ' ')"
  assert_eq "$label/unprefixed-block-identical" "same" \
    "$(diff -q <(grep -vE '^(VOLATILE|HOST): ' "$CITED") \
                <(grep -vE '^(VOLATILE|HOST): ' "$f") >/dev/null && echo same || echo differs)"
}

# ==========================================================================
hr "PHASE A — preconditions and the allowed-position map"
uname -sm
sw_vers 2>/dev/null | tr '\n' ' '; echo
rustc --version
cargo --version
echo "ambient locale: LANG=${LANG:-unset} LC_ALL=${LC_ALL:-unset} LC_COLLATE=${LC_COLLATE:-unset}"
for f in "$CHECK" "$CITED" "$NEGCTL" "$R2_CHECK" "$R2_CITED" "$R2_AUDIT"; do
  printf '%-58s sha256 %s\n' "$f" "$(shasum -a 256 "$f" | awk '{print $1}')"
done

CITED_LINES=$(wc -l < "$CITED" | tr -d ' ')
CITED_PASS=$(grep -c '^PASS  ' "$CITED" | tr -d ' ')
V_CAND=$(grep -c '^VOLATILE: ' "$CITED" | tr -d ' ')
H_CAND=$(grep -c '^HOST: ' "$CITED" | tr -d ' ')
echo "cited log: $CITED_LINES lines; $CITED_PASS PASS lines"
echo "allowed positions: class V = $V_CAND lines; class H = $H_CAND lines"
# Hardcoded so that swapping in a different cited log is caught here, not later.
assert_eq "pre/cited-line-count" 1071 "$CITED_LINES"
assert_eq "pre/cited-pass-count" 168 "$CITED_PASS"
assert_eq "pre/cited-fail-count" 0 "$(grep -c '^FAIL  ' "$CITED" | tr -d ' ')"
assert_eq "pre/class-V-allowed-positions" 126 "$V_CAND"
assert_eq "pre/class-H-allowed-positions" 4 "$H_CAND"
assert_eq "pre/check-pins-collation" 1 "$(grep -c '^export LC_ALL=C$' "$CHECK" | tr -d ' ')"
assert_eq "pre/check-has-pipefail" 1 "$(grep -c '^set -o pipefail$' "$CHECK" | tr -d ' ')"
assert_eq "pre/compare-has-pipefail" 1 \
  "$(grep -c '^set -o pipefail$' review/evidence/r63-crossrun-compare.sh | tr -d ' ')"
assert_eq "pre/no-personal-email-in-check" 0 \
  "$(grep -cE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$CHECK" | tr -d ' ')"
assert_eq "pre/check-user-agent-names-the-repository" 1 \
  "$(grep -c 'https://github.com/smorinlabs/rs-launch-blueprint' "$CHECK" | tr -d ' ')"
shape "pre/cited-against-itself" "$CITED"

# ==========================================================================
hr "PHASE B — three reruns of the archived check, three environments"
echo "run 1: fresh scratch, ambient locale (LANG=${LANG:-unset})"
R63_WORK="$WORK/scratch1" bash "$CHECK" > "$WORK/run1.log" 2>&1
assert_eq "run1/exit" 0 "$?"
echo "run 2: fresh scratch, LC_ALL=en_US.UTF-8 forced in the environment"
R63_WORK="$WORK/scratch2" LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 bash "$CHECK" > "$WORK/run2.log" 2>&1
assert_eq "run2/exit" 0 "$?"
echo "run 3: fresh scratch, LC_ALL=C with every LC_* and LANG unset in the environment"
env -u LANG -u LC_COLLATE -u LC_CTYPE -u LC_MESSAGES -u LC_MONETARY -u LC_NUMERIC -u LC_TIME \
    -u LC_ALL R63_WORK="$WORK/scratch3" bash "$CHECK" > "$WORK/run3.log" 2>&1
assert_eq "run3/exit" 0 "$?"
for r in 1 2 3; do shape "run$r" "$WORK/run$r.log"; done

# ==========================================================================
hr "PHASE C — classify every differing line"
compare "cited-vs-run1-ambient"      "$CITED"          "$WORK/run1.log"
compare "cited-vs-run2-en_US.UTF-8"  "$CITED"          "$WORK/run2.log"
compare "cited-vs-run3-C-locale"     "$CITED"          "$WORK/run3.log"
compare "run1-vs-run2"               "$WORK/run1.log"  "$WORK/run2.log"
compare "run2-vs-run3"               "$WORK/run2.log"  "$WORK/run3.log"

# ==========================================================================
hr "PHASE D — which classes were actually observed"
sort -u "$OBSERVED"
assert_eq "coverage/V-live-figure-observed" 1 \
  "$(grep -cx 'V-live-figure' "$OBSERVED" >/dev/null 2>&1 && echo 1 || echo 0)"
assert_eq "coverage/H-host-identity-observed" 1 \
  "$(grep -cx 'H-host-identity' "$OBSERVED" >/dev/null 2>&1 && echo 1 || echo 0)"
echo "Both classes were observed, but only at a FEW of their allowed positions,"
echo "and the comparisons above name exactly which. Class V differed only at the"
echo "wall-clock date line, because these runs are minutes apart and no registry"
echo "or GitHub counter moved inside that window; a rerun days later will differ"
echo "at more of its $V_CAND allowed positions, and the rule admits that. Class H"
echo "differed only where run 3's environment differs from this host's ambient"
echo "one. The remaining allowed positions of each class are exercised by the"
echo "synthetic in-position control in phase H2, not by these runs."

# ==========================================================================
hr "PHASE E — the revision-2 defect, demonstrated from committed files"
echo "Revision 2's rule was: remove VOLATILE:/HOST: lines from both logs, and the"
echo "diff must be empty. Applied to revision 2's OWN cited log and the revision-2"
echo "auditor's archived rerun of revision 2's script, it is not empty:"
diff <(grep -vE '^(VOLATILE|HOST): ' "$R2_CITED") \
     <(grep -vE '^(VOLATILE|HOST): ' "$R2_AUDIT") > "$WORK/r2-filtered.diff"
R2_DIFF_STATUS=$?
sed -n '1,12p' "$WORK/r2-filtered.diff"
echo "(filtered diff: $(wc -l < "$WORK/r2-filtered.diff" | tr -d ' ') lines, diff exit $R2_DIFF_STATUS)"
assert_eq "r2/filtered-diff-is-non-empty" 1 \
  "$([ -s "$WORK/r2-filtered.diff" ] && echo 1 || echo 0)"
assert_eq "r2/variable-list-line-differs" 1 \
  "$(grep -c '^< APPVEYOR bamboo.buildKey ' "$WORK/r2-filtered.diff" | tr -d ' ')"
assert_eq "r2/shipped-file-listing-moved" 4 \
  "$(grep -cE '^[<>] src/indicatif-0\.18\.6/(LICENSE|README\.md)$' "$WORK/r2-filtered.diff" | tr -d ' ')"
echo "Under revision 3's rule those same two logs are rejected explicitly:"
python3 "$CLASSIFY" "$R2_CITED" "$R2_CITED" "$R2_AUDIT" > "$WORK/r2-classified.out"
sed -n '1,8p' "$WORK/r2-classified.out"
assert_eq "r2/rejected-as-unclassified" 21 \
  "$(sed -n 's/.*unclassified=\([0-9]*\).*/\1/p' "$WORK/r2-classified.out")"
echo "Revision 3's cited log has no such region: both are now C-collated."
assert_eq "r3/variable-list-is-C-collated" 1 \
  "$(grep -c ' WERCKER bamboo.buildKey $' "$CITED" | tr -d ' ')"
assert_eq "r2/variable-list-was-not-C-collated" 1 \
  "$(grep -c '^APPVEYOR bamboo.buildKey ' "$R2_CITED" | tr -d ' ')"

# ==========================================================================
hr "PHASE F — the mechanism: the two pipelines, with and without the fix"
echo "The two regions revision 2 got wrong are the only sort-ordered output in"
echo "the check. Run each pipeline UNFIXED under two locales, from run 1's"
echo "unpacked artifacts, and the orders differ; run it with LC_ALL=C pinned, as"
echo "revision 3's check does, and they agree."
S1="$WORK/scratch1"
assert_eq "mech/artifact-present-is_ci" 1 \
  "$([ -f "$S1/src/is_ci-1.2.0/src/lib.rs" ] && echo 1 || echo 0)"
assert_eq "mech/artifact-present-indicatif" 1 \
  "$([ -d "$S1/src/indicatif-0.18.6" ] && echo 1 || echo 0)"

varlist() { # varlist <locale-assignment...>  — the section-3 pipeline, unpinned
  env "$@" bash -c "grep -o 'check(\"[^\"]*\"' '$S1/src/is_ci-1.2.0/src/lib.rs' \
    | sed 's/check(\"//; s/\"\$//' | sort | tr '\n' ' '"
}
filelist() { # filelist <locale-assignment...> — the section-12 pipeline, unpinned
  env "$@" bash -c "cd '$S1' && find src/indicatif-0.18.6 -type f | sort"
}

varlist_pinned() { # the same pipeline with LC_ALL=C exported inside, as the check does
  env "$@" bash -c "export LC_ALL=C; grep -o 'check(\"[^\"]*\"' '$S1/src/is_ci-1.2.0/src/lib.rs' \
    | sed 's/check(\"//; s/\"\$//' | sort | tr '\n' ' '"
}

varlist LC_ALL=en_US.UTF-8 > "$WORK/vars-utf8.txt"
varlist LC_ALL=C           > "$WORK/vars-c.txt"
filelist LC_ALL=en_US.UTF-8 > "$WORK/files-utf8.txt"
filelist LC_ALL=C           > "$WORK/files-c.txt"
echo "unfixed variable list, en_US.UTF-8 (first 90 bytes): $(cut -c1-90 < "$WORK/vars-utf8.txt")"
echo "unfixed variable list, C locale    (first 90 bytes): $(cut -c1-90 < "$WORK/vars-c.txt")"
assert_eq "mech/varlist-differs-across-locales" "differs" \
  "$(diff -q "$WORK/vars-utf8.txt" "$WORK/vars-c.txt" >/dev/null && echo same || echo differs)"
echo "unfixed file listing, positions of LICENSE and README.md:"
for f in "$WORK/files-utf8.txt" "$WORK/files-c.txt"; do
  printf '  %-12s LICENSE=%s README.md=%s\n' "$(basename "$f")" \
    "$(grep -n '/LICENSE$' "$f" | cut -d: -f1)" "$(grep -n '/README.md$' "$f" | cut -d: -f1)"
done
assert_eq "mech/filelist-differs-across-locales" "differs" \
  "$(diff -q "$WORK/files-utf8.txt" "$WORK/files-c.txt" >/dev/null && echo same || echo differs)"
echo "and the SAME pipelines with LC_ALL=C pinned inside, as revision 3's check does:"
assert_eq "mech/varlist-agrees-once-pinned" "same" \
  "$(diff -q <(varlist_pinned LC_ALL=en_US.UTF-8) <(varlist_pinned LC_ALL=C) >/dev/null \
     && echo same || echo differs)"
echo "which is why run 2 (en_US.UTF-8) and run 3 (C) agree on every unprefixed line."
assert_eq "mech/run2-vs-run3-unprefixed-identical" "same" \
  "$(diff -q <(grep -vE '^(VOLATILE|HOST): ' "$WORK/run2.log") \
              <(grep -vE '^(VOLATILE|HOST): ' "$WORK/run3.log") >/dev/null \
     && echo same || echo differs)"

# ==========================================================================
hr "PHASE G — negative control 1: an UNCLASSIFIED difference is rejected"
echo "Mutate one PASS line of run 1 — a line that carries neither prefix — and"
echo "the classifier must refuse to place it."
sed 's/^PASS  indicatif 0.18.6 rust-version$/PASS  indicatif 0.18.6 rust-version MUTATED/' \
  "$WORK/run1.log" > "$WORK/neg1.log"
assert_eq "neg1/mutation-applied" 1 \
  "$(diff "$WORK/run1.log" "$WORK/neg1.log" | grep -c '^> PASS  indicatif 0.18.6 rust-version MUTATED$' | tr -d ' ')"
compare "neg1-unclassified-difference" "$WORK/run1.log" "$WORK/neg1.log" 1 0
echo "and the same mutation defeats the plain filtered-diff form of the rule too:"
assert_eq "neg1/filtered-diff-differs" "differs" \
  "$(diff -q <(grep -vE '^(VOLATILE|HOST): ' "$WORK/run1.log") \
              <(grep -vE '^(VOLATILE|HOST): ' "$WORK/neg1.log") >/dev/null \
     && echo same || echo differs)"

hr "PHASE G2 — negative control 2: a line-count change is rejected"
sed '$d' "$WORK/run1.log" > "$WORK/neg2.log"
assert_eq "neg2/one-line-shorter" 1 \
  "$(( $(wc -l < "$WORK/run1.log") - $(wc -l < "$WORK/neg2.log") ))"
compare "neg2-line-count-change" "$WORK/run1.log" "$WORK/neg2.log" 1 1

# ==========================================================================
hr "PHASE H — negative control 3: a CLASS-SHAPED difference OUT OF POSITION"
echo "A differing line of the right shape at a line number the rule does not"
echo "allow must be counted as a violation, not waved through. Pick an"
echo "unprefixed line of the cited log and make two copies differ there, once"
echo "with class-V shape and once with class-H shape."
OUTPOS=$(grep -vnE '^(VOLATILE|HOST): ' "$CITED" | grep -m1 '^[0-9]*:PASS  indicatif' | cut -d: -f1)
echo "chosen line $OUTPOS of the cited log (carries neither prefix):"
sed -n "${OUTPOS}p" "$CITED"
assert_eq "negH/chosen-line-is-unprefixed" 0 \
  "$(sed -n "${OUTPOS}p" "$CITED" | grep -cE '^(VOLATILE|HOST): ' | tr -d ' ')"

for klass in V:VOLATILE H:HOST; do
  name=${klass%%:*}; pre=${klass##*:}
  sed "${OUTPOS}s|.*|${pre}: synthetic ${name} line alpha|" "$CITED" > "$WORK/out-$name-a.log"
  sed "${OUTPOS}s|.*|${pre}: synthetic ${name} line beta|"  "$CITED" > "$WORK/out-$name-b.log"
  compare "negH-class-$name-out-of-position" "$WORK/out-$name-a.log" "$WORK/out-$name-b.log" 0 1
done

hr "PHASE H2 — positive control: the SAME shapes IN position are classified"
echo "The mirror of phase H. At an allowed position each class must be"
echo "classified with zero violations — otherwise phase H would only be showing"
echo "that the classifier rejects everything."
for klass in V:VOLATILE H:HOST; do
  name=${klass%%:*}; pre=${klass##*:}
  # The LAST allowed position of the class, which is not one of the positions
  # phase C observed differing, so this control exercises a fresh one.
  INPOS=$(grep -n "^${pre}: " "$CITED" | tail -1 | cut -d: -f1)
  echo "class $name allowed position $INPOS: $(sed -n "${INPOS}p" "$CITED")"
  sed "${INPOS}s|.*|${pre}: synthetic ${name} line alpha|" "$CITED" > "$WORK/in-$name-a.log"
  sed "${INPOS}s|.*|${pre}: synthetic ${name} line beta|"  "$CITED" > "$WORK/in-$name-b.log"
  compare "negH2-class-$name-in-position" "$WORK/in-$name-a.log" "$WORK/in-$name-b.log" 0 0
done

# ==========================================================================
hr "PHASE I — the check itself can still fail (archived negative control)"
echo "Reproduced with: R63_WORK=<fresh dir> TS_REPO=/nonexistent-repo bash $CHECK"
tail -3 "$NEGCTL"
assert_eq "negctl/summary" "checks: 155 pass / 13 fail" \
  "$(grep -m1 '^checks: ' "$NEGCTL")"
assert_eq "negctl/fail-lines" 13 "$(grep -c '^FAIL  ' "$NEGCTL" | tr -d ' ')"
assert_eq "negctl/result-line" 1 "$(grep -c '^RESULT: FAIL' "$NEGCTL" | tr -d ' ')"

hr "PHASE I2 — nolit rejects an unreadable file instead of passing it"
echo "The revision-2 auditor's second finding: an absence must be a zero MATCH"
echo "COUNT, and a read error must fail loudly. Drive revision 3's helper"
echo "directly, against a file that does not exist and against a file that does"
echo "contain the literal."
NOLIT_PROBE="$WORK/nolit-probe.sh"
{
  printf 'set -u\nset -o pipefail\nPASS=0\nFAIL=0\n'
  printf 'ok(){  PASS=$((PASS+1)); printf "PASS  %%s\\n" "$1"; }\n'
  printf 'bad(){ FAIL=$((FAIL+1)); printf "FAIL  %%s\\n" "$1"; }\n'
  printf 'chk(){ if [ "$2" = "$3" ]; then ok "$1 == $2"; else bad "$1: expected [$2], got [$3]"; fi; }\n'
  awk '/^nolit\(\)\{$/,/^\}$/' "$CHECK"
  printf 'printf "x\\n" > "%s/present.txt"\n' "$WORK"
  printf 'nolit "probe: absent literal in a readable file" "%s/present.txt" "y"\n' "$WORK"
  printf 'nolit "probe: PRESENT literal must fail" "%s/present.txt" "x"\n' "$WORK"
  # A fixed absolute path that cannot exist, NOT one under $WORK: $WORK carries
  # this process's pid, and the FAIL message prints the path, so using it would
  # make this script's own log differ between runs — the very defect this
  # comparator exists to catch.
  printf 'nolit "probe: unreadable file must fail" "/nonexistent-dir/r63-nolit-probe.txt" "x"\n'
  printf 'printf "probe: %%d pass / %%d fail\\n" "$PASS" "$FAIL"\n'
} > "$NOLIT_PROBE"
bash "$NOLIT_PROBE" > "$WORK/nolit-probe.out" 2>&1
cat "$WORK/nolit-probe.out"
assert_eq "nolit/lifted-from-the-archived-check" 1 \
  "$(awk '/^nolit\(\)\{$/,/^\}$/' "$CHECK" | grep -c 'grep -cF' | tr -d ' ')"
assert_eq "nolit/absent-literal-passes" 1 \
  "$(grep -c '^PASS  probe: absent literal in a readable file' "$WORK/nolit-probe.out" | tr -d ' ')"
assert_eq "nolit/present-literal-fails" 1 \
  "$(grep -c '^FAIL  probe: PRESENT literal must fail' "$WORK/nolit-probe.out" | tr -d ' ')"
assert_eq "nolit/unreadable-file-fails" 1 \
  "$(grep -c '^FAIL  probe: unreadable file must fail: /nonexistent-dir/r63-nolit-probe.txt missing or unreadable$' "$WORK/nolit-probe.out" | tr -d ' ')"
# This script's own log must not carry its scratch path either, or a rerun of
# the comparator would differ from the cited comparator log for the same reason
# revision 2's check did.
assert_eq "compare/own-log-is-scratch-path-free" 0 \
  "$(grep -c 'r63-crossrun\.' "$WORK/nolit-probe.out" | tr -d ' ')"
assert_eq "nolit/probe-summary" "probe: 1 pass / 2 fail" \
  "$(grep -m1 '^probe: ' "$WORK/nolit-probe.out")"
assert_eq "nolit/no-exit-status-branch-remains" 0 \
  "$(awk '/^nolit\(\)\{$/,/^\}$/' "$CHECK" | grep -c 'grep -qF' | tr -d ' ')"

# ==========================================================================
hr "DONE"
echo "failed assertions: $FAILS"
if [ "$FAILS" -gt 0 ]; then
  echo "RESULT: FAIL — the difference rule stated in review/DECISION.md does not hold."
  exit 1
fi
echo "RESULT: PASS — every rerun conformed to the rule; every negative control was rejected."
exit 0
