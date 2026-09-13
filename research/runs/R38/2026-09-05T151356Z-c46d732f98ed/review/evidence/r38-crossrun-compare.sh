#!/usr/bin/env bash
# R38 commit-message-linter — cross-run comparison check (revision 7).
#
# WHY THIS EXISTS. Revision 6 wrote that its cited evaluation log and an
# immediate rerun "differ in one line, line 1, the UTC timestamp", listed three
# further predictable differences in prose, and then said "every other line is
# reproducible byte-for-byte". The revision-6 empirical auditor reran the check
# from a fresh copy under `/private/tmp` and found a FOURTH real difference the
# claim did not account for: the `C23-ctl` diagnostic line. The control binary
# `committed` echoes back the path it is handed, revision 6 handed it the
# absolute `$WORK/upper-bad.txt`, and that path is the location of whichever
# copy of the fixture is running. The auditor recorded the difference in
# `review/evidence/audit-r6-evaluation-stable.diff` and rejected revision 6 on
# it. A claim checked only by re-reading prose is not a check.
#
# WHAT REVISION 7 DID, AND WHAT THIS SCRIPT PROVES.
#   (1) It removed the cause. `evaluate.sh` now invokes the control from inside
#       the work directory with a bare relative file name, so the diagnostic
#       reads `upper-bad.txt: error Disallowed type ...` wherever the fixture
#       lives. `--config` stays absolute, so the configuration read and the
#       asserted exit status are unchanged. PHASE E demonstrates the mechanism
#       from committed files rather than asserting it.
#   (2) It re-took the cited log from a COLD tree — `tools/` is gitignored, so a
#       fresh checkout of this repository has no provisioned binaries and prints
#       the provisioning preamble, exactly as the cited log now does.
#   (3) It replaced the prose claim with the rule below and made the rule
#       testable: this script reruns `evaluate.sh` under three environments,
#       sorts EVERY differing line into a NAMED class with its allowed line
#       positions, asserts `unclassified=0 violations=0`, and then runs negative
#       controls proving the classifier REJECTS an unclassified difference, a
#       class-shaped difference out of position, a line-count change, and — the
#       control that matters here — the revision-6 absolute-path line itself.
#
# THE DIFFERENCE RULE, STATED PRECISELY AND IN FULL.
#   Let CITED be `review/evidence/conventional_commits_linter-0.17.1-evaluation.log`.
#   Segment any log of this check at two fixed anchor lines: the marker line
#   `--- figures [volatile section: ...` and the `summary: ` line. HEAD is
#   everything up to and including the marker, FIGURES is what lies between the
#   marker and the `summary: ` line, TAIL is the `summary: ` line and what
#   follows. A conforming rerun R of `evaluate.sh` satisfies ALL of:
#     (R1) HEAD comparison is preceded by peeling class I from BOTH sides:
#            I — provisioning preamble. A line matching `^provisioning ` or
#                `^cargo install exit=`. Printed only when the run has to
#                install a binary, so a COLD tree prints four such lines and a
#                WARM tree prints none; this is a line-count difference and is
#                admitted for that reason alone. Allowed positions: strictly
#                between the `host: ` line and the `A1 ` line. An I-shaped line
#                anywhere else is a VIOLATION, not an allowed difference.
#          After peeling, the two HEADs must have equal line counts. An unequal
#          count is UNCLASSIFIED: the check emits a fixed number of lines
#          otherwise, so a change means the SCRIPT changed.
#     (R2) For each peeled-HEAD index i, either R[i] == CITED[i], or the
#          difference falls in exactly one of these three classes, where BOTH
#          sides must carry the class shape:
#            T — wall-clock timestamp. Matches
#                `^conventional_commits_linter evaluation, date \(UTC\): .*\[volatile line\]$`.
#                One line, which the check itself marks `[volatile line]`.
#            H — host identity. Matches `^host: `. The `uname`, `rustc` and
#                `cargo` of whichever machine ran the check.
#            S — provisioned binary size. Matches
#                `^ +candidate size: .*\[volatile line\]$`. The byte size of the
#                binary this host's toolchain produced, also marked
#                `[volatile line]`.
#          Allowed positions of each class: exactly the peeled-HEAD line numbers
#          at which CITED itself carries that class's shape. A class-shaped
#          difference outside them is a VIOLATION.
#     (R3) FIGURES is class F and is compared as a BLOCK, not line by line, and
#          its line count may differ. Every line in it is a live counter —
#          `recent_downloads`, `downloads`, `stargazers_count`, `pushed_at`,
#          open-issue and code-search totals, the ten most recently opened
#          issues — which moves with no change upstream, and a rate-limited
#          `gh` call can drop a line outright. The check asserts nothing in this
#          block and neither does the decision; the marker line says so.
#     (R4) TAIL admits NO class. Every line from `summary: ` onward must be
#          byte-identical. That is where `PASS=55 FAIL=0 CONTRACT_VIOLATIONS=3`
#          and `RESULT: PASS` live.
#   The rule admits nothing else. In particular it does NOT admit a path: the
#   cited log contains no absolute path at all, and PHASE A asserts that.
#
# WHAT IS NOT COVERED, STATED PLAINLY. The rule tolerates no drift in any
# asserted line, so a new RustSec advisory against the candidate's locked tree,
# a new crates.io release, or a change to the upstream release assets or CI
# workflow will make `evaluate.sh` FAIL loudly (exit 1) rather than drift
# quietly. That is the intended behaviour and it is why the decision carries a
# `re-verify:` trigger; it is not a difference class.
#
# SCOPE OF WHAT IS DEMONSTRATED HERE, HONESTLY. Classes T and I are observed
# LIVE by the reruns below; PHASE D prints exactly which classes were observed.
# Class F is observed only when a live counter moves inside this script's
# few-minute window — none did in the cited run — and is otherwise exercised by
# the synthetic control of PHASE H3. Classes H and S cannot be observed here:
# every rerun happens on one host with one toolchain, so both lines come out
# identical, and they are exercised only by the labelled SYNTHETIC in-position
# control of PHASE H2. The
# environments exercised are three fresh copies of the fixture at three
# different absolute paths of three different lengths, one of them invoked from
# an unrelated working directory (`/`), on one macOS arm64 host. No Linux run
# and no second host is claimed.
#
# COST. Run 1 provisions both binaries from source; runs 2 and 3 and the two
# whole-script controls reuse run 1's binaries. Expect a few minutes.
#
# Publishes nothing and builds nothing except the two pinned tool binaries the
# check itself installs. It invokes the archived check, git, diff, grep, sed,
# awk and python3.
#
# Run from the run directory:
#   bash review/evidence/r38-crossrun-compare.sh \
#     > review/evidence/r38-crossrun-compare.log 2>&1
# It reads only committed files, so it reruns unchanged after the commit.
# Requires the same access the check requires: network, an authenticated `gh`,
# and a Rust toolchain.

set -u
set -o pipefail

FAILS=0
# One asserted row of the check's output: `<id> expected=<...> observed=<...> PASS|FAIL <text>`.
# Matching on the row shape and not on a bare ` PASS ` keeps the trailing
# `RESULT: PASS (...)` line out of the count.
ROW='^[A-Za-z0-9-]+ +expected=.*'
assert_eq() { # assert_eq <label> <expected> <actual>
  if [ "$2" = "$3" ]; then printf 'PASS %s (%s)\n' "$1" "$3"
  else printf 'FAIL %s (expected %s, got %s)\n' "$1" "$2" "$3"; FAILS=$((FAILS + 1)); fi
}
hr() { printf '\n===== %s =====\n' "$1"; }

CHECK=review/empirical/conventional-commits-linter-eval/evaluate.sh
CITED=review/evidence/conventional_commits_linter-0.17.1-evaluation.log
R6LOG=review/evidence/conventional_commits_linter-0.17.1-evaluation.r6.log
EMPIRICAL=review/empirical
CTLCFG_REL=review/empirical/committed.toml
# The revision-6 `evaluate.sh`, addressed by its git blob id so PHASE E can
# recover the exact bytes that produced the rejected log, forever, from history.
R6_BLOB=a6e6641ea13c7e4b173cf7e0932fd682f794b28d

for f in "$CHECK" "$CITED" "$R6LOG" "$CTLCFG_REL"; do
  [ -f "$f" ] || { echo "missing required file: $f"; exit 2; }
done
[ -d "$EMPIRICAL/messages" ] || { echo "missing required directory: $EMPIRICAL/messages"; exit 2; }

WORK="${TMPDIR:-/tmp}/r38-crossrun.$$"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT
# Nothing below prints "$WORK" unredacted: this script's own log must not carry
# a pid-bearing scratch path, or a rerun of the comparator would differ from the
# cited comparator log for the same reason revision 6's check did.
redact() { sed "s|$WORK|<scratch>|g"; }
CTLCFG_ABS="$PWD/$CTLCFG_REL"

# --------------------------------------------------------------------------
# The classifier. Segments both logs at the two anchors, peels class I, places
# every differing HEAD line into class T, H or S or leaves it UNCLASSIFIED,
# checks each classified line against that class's allowed positions (read from
# the cited log), reports FIGURES as class F, and requires TAIL to be identical.
CLASSIFY="$WORK/classify.py"
cat > "$CLASSIFY" <<'PY'
import re, sys

# classify.py <cited> <fileA> <fileB>
# Prints one line per class (always, present or absent), one UNCLASSIFIED line
# per unplaceable difference, then the summary line
#   classified=<n> unclassified=<n> violations=<n> classes=<c1,c2,...>

MARKER = "--- figures [volatile section"
SUMMARY = "summary: "
IPAT = re.compile(r"^(provisioning |cargo install exit=)")
SHAPE = {
    "T-timestamp": re.compile(
        r"^conventional_commits_linter evaluation, date \(UTC\): .*\[volatile line\]$"),
    "H-host-identity": re.compile(r"^host: "),
    "S-binary-size": re.compile(r"^ +candidate size: .*\[volatile line\]$"),
}

def read(p):
    return open(p, encoding="utf-8", errors="replace").read().split("\n")

def seg(lines, path):
    m = s = None
    for i, l in enumerate(lines):
        if m is None and l.startswith(MARKER):
            m = i
        if s is None and l.startswith(SUMMARY):
            s = i
    if m is None or s is None or s < m:
        sys.exit(f"anchors not found in {path}: marker={m} summary={s}")
    return lines[:m + 1], lines[m + 1:s], lines[s:]

def peel(head, path):
    """Return (kept_lines, i_positions, i_out_of_window). Positions are 1-based
    indices into the UNPEELED head."""
    host = a1 = None
    for i, l in enumerate(head):
        if host is None and l.startswith("host: "):
            host = i
        if a1 is None and l.startswith("A1 "):
            a1 = i
    if host is None or a1 is None:
        sys.exit(f"class-I window anchors not found in {path}: host={host} A1={a1}")
    kept, pos, bad = [], [], []
    for i, l in enumerate(head):
        if IPAT.match(l):
            pos.append(i + 1)
            if not (host < i < a1):
                bad.append(i + 1)
        else:
            kept.append(l)
    return kept, pos, bad

cited_raw, a_raw, b_raw = (read(p) for p in sys.argv[1:4])
ch, _, _ = seg(cited_raw, sys.argv[1])
ah, af, at = seg(a_raw, sys.argv[2])
bh, bf, bt = seg(b_raw, sys.argv[3])

chk, _, _ = peel(ch, sys.argv[1])
ahk, apos, abad = peel(ah, sys.argv[2])
bhk, bpos, bbad = peel(bh, sys.argv[3])

allowed = {name: {i + 1 for i, l in enumerate(chk) if pat.match(l)}
           for name, pat in SHAPE.items()}

cls, rest, violations = {}, [], 0
seen = []

# ---- class I ----------------------------------------------------------------
violations += len(abad) + len(bbad)
suffix = ""
if abad or bbad:
    suffix = " OUTSIDE-ALLOWED-WINDOW A=%s B=%s" % (
        ",".join(map(str, abad)), ",".join(map(str, bbad)))
print("I-provisioning-preamble A=%d%s B=%d%s%s" % (
    len(apos), "@" + ",".join(map(str, apos)) if apos else "",
    len(bpos), "@" + ",".join(map(str, bpos)) if bpos else "", suffix))
if len(apos) != len(bpos) or abad or bbad:
    seen.append("I-provisioning-preamble")

# ---- HEAD -------------------------------------------------------------------
if len(ahk) != len(bhk):
    print("UNCLASSIFIED head line-count after peeling class I: %d vs %d"
          % (len(ahk), len(bhk)))
    rest.append(-1)
    violations += 1
else:
    for i in range(len(ahk)):
        if ahk[i] == bhk[i]:
            continue
        for name, pat in SHAPE.items():
            if pat.match(ahk[i]) and pat.match(bhk[i]):
                cls.setdefault(name, []).append(i + 1)
                break
        else:
            rest.append(i)
for name in sorted(SHAPE):
    got = sorted(cls.get(name, []))
    bad = sorted(set(got) - allowed[name])
    violations += len(bad)
    s = " OUTSIDE-ALLOWED-POSITIONS=%s" % ",".join(map(str, bad)) if bad else ""
    print("%s lines=%s%s" % (name, ",".join(map(str, got)), s))
    if got:
        seen.append(name)

# ---- FIGURES ----------------------------------------------------------------
same = "yes" if af == bf else "no"
print("F-figures-block A=%d B=%d identical=%s" % (len(af), len(bf), same))
if same == "no":
    seen.append("F-figures-block")

# ---- TAIL -------------------------------------------------------------------
if len(at) != len(bt):
    print("UNCLASSIFIED tail line-count: %d vs %d" % (len(at), len(bt)))
    rest.append(-2)
    violations += 1
else:
    for i in range(len(at)):
        if at[i] != bt[i]:
            print("UNCLASSIFIED tail line %d: %r -> %r" % (i + 1, at[i], bt[i]))
            rest.append(-3)

for i in rest:
    if i >= 0:
        print("UNCLASSIFIED head line %d: %r -> %r" % (i + 1, ahk[i], bhk[i]))

n = sum(len(v) for v in cls.values())
print("classified=%d unclassified=%d violations=%d classes=%s"
      % (n, len(rest), violations, ",".join(sorted(set(seen)))))
PY

OBSERVED="$WORK/observed-classes.txt"
: > "$OBSERVED"

compare() { # compare <label> <fileA> <fileB> [expect-unclassified] [expect-violations]
  local label="$1" fa="$2" fb="$3" eu="${4:-0}" ev="${5:-0}"
  echo "--- $label"
  python3 "$CLASSIFY" "$CITED" "$fa" "$fb" > "$WORK/c.out" 2>&1
  redact < "$WORK/c.out"
  grep -o 'classes=.*' "$WORK/c.out" | sed 's/classes=//' | tr ',' '\n' | grep -v '^$' >> "$OBSERVED"
  assert_eq "$label/unclassified" "$eu" \
    "$(sed -n 's/.*unclassified=\([0-9]*\).*/\1/p' "$WORK/c.out")"
  assert_eq "$label/violations" "$ev" \
    "$(sed -n 's/.*violations=\([0-9]*\).*/\1/p' "$WORK/c.out")"
}

shape() { # shape <label> <log> — the invariants a conforming rerun must hold
  local label="$1" f="$2"
  assert_eq "$label/pass-rows" "$CITED_PASS" "$(grep -cE "$ROW PASS " "$f" | tr -d ' ')"
  assert_eq "$label/fail-rows" 0 "$(grep -cE "$ROW FAIL " "$f" | tr -d ' ')"
  assert_eq "$label/summary-line" "summary: PASS=55 FAIL=0 CONTRACT_VIOLATIONS=3" \
    "$(grep -m1 '^summary: ' "$f")"
  assert_eq "$label/result-line" 1 "$(grep -c '^RESULT: PASS ' "$f" | tr -d ' ')"
  assert_eq "$label/no-absolute-path" 0 \
    "$(grep -cE '(^|[^A-Za-z0-9_.-])/(Users|private|home|tmp|var)/' "$f" | tr -d ' ')"
}

seed() { # seed <destdir> <cold|warm> — a fresh copy of the fixture tree
  local dest="$1" mode="$2"
  mkdir -p "$dest"
  cp -R "$EMPIRICAL" "$dest/empirical"
  rm -rf "$dest/empirical/conventional-commits-linter-eval/.work" \
         "$dest/empirical/repo-hygiene/target" \
         "$dest/empirical/.audit-cargo-home" \
         "$dest/empirical/conventional-commits-linter-eval/.audit-cargo-home"
  if [ "$mode" = cold ]; then
    rm -rf "$dest/empirical/tools" "$dest/empirical/conventional-commits-linter-eval/tools"
  fi
}

# ==========================================================================
hr "PHASE A — preconditions, anchors and the allowed-position map"
uname -sm
sw_vers 2>/dev/null | tr '\n' ' '; echo
rustc --version
cargo --version
git --version
for f in "$CHECK" "$CITED" "$R6LOG"; do
  printf '%-72s sha256 %s\n' "$f" "$(shasum -a 256 "$f" | awk '{print $1}')"
done

CITED_LINES=$(wc -l < "$CITED" | tr -d ' ')
CITED_PASS=$(grep -cE "$ROW PASS " "$CITED" | tr -d ' ')
echo "cited log: $CITED_LINES lines; $CITED_PASS PASS rows"
# Hardcoded so that swapping in a different cited log is caught here, not later.
assert_eq "pre/cited-line-count" 153 "$CITED_LINES"
assert_eq "pre/cited-pass-rows" 55 "$CITED_PASS"
assert_eq "pre/cited-fail-rows" 0 "$(grep -cE "$ROW FAIL " "$CITED" | tr -d ' ')"
assert_eq "pre/cited-summary" "summary: PASS=55 FAIL=0 CONTRACT_VIOLATIONS=3" \
  "$(grep -m1 '^summary: ' "$CITED")"
assert_eq "pre/class-T-allowed-positions" 1 \
  "$(grep -cE '^conventional_commits_linter evaluation, date \(UTC\): .*\[volatile line\]$' "$CITED" | tr -d ' ')"
assert_eq "pre/class-H-allowed-positions" 1 "$(grep -c '^host: ' "$CITED" | tr -d ' ')"
assert_eq "pre/class-S-allowed-positions" 1 \
  "$(grep -cE '^ +candidate size: .*\[volatile line\]$' "$CITED" | tr -d ' ')"
assert_eq "pre/class-I-lines-in-cited" 4 \
  "$(grep -cE '^(provisioning |cargo install exit=)' "$CITED" | tr -d ' ')"
assert_eq "pre/figures-anchor" 1 \
  "$(grep -c '^--- figures \[volatile section' "$CITED" | tr -d ' ')"
# THE FINDING, killed directly: the cited log quotes no absolute path anywhere.
assert_eq "pre/cited-has-no-absolute-path" 0 \
  "$(grep -cE '(^|[^A-Za-z0-9_.-])/(Users|private|home|tmp|var)/' "$CITED" | tr -d ' ')"
# ... and the revision-6 log it replaces has exactly one, at C23-ctl.
assert_eq "pre/r6-log-had-one-absolute-path" 1 \
  "$(grep -cE '(^|[^A-Za-z0-9_.-])/(Users|private|home|tmp|var)/' "$R6LOG" | tr -d ' ')"
assert_eq "pre/r6-absolute-path-was-the-C23-diagnostic" 1 \
  "$(grep -cE '^ +[|] .*/[.]work/upper-bad[.]txt: error Disallowed type' "$R6LOG" | tr -d ' ')"
assert_eq "pre/check-has-pipefail" 1 "$(grep -c 'pipefail' "$CHECK" | tr -d ' ')"
assert_eq "pre/compare-has-pipefail" 1 \
  "$(grep -c '^set -o pipefail$' review/evidence/r38-crossrun-compare.sh | tr -d ' ')"
assert_eq "pre/no-personal-email-in-check" 0 \
  "$(grep -cE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$CHECK" | tr -d ' ')"
assert_eq "pre/check-user-agent-names-the-repository" 1 \
  "$(grep -c 'https://github.com/smorinlabs/rs-launch-blueprint' "$CHECK" | tr -d ' ')"
shape "pre/cited-against-itself" "$CITED"
compare "pre/cited-vs-itself" "$CITED" "$CITED"

# ==========================================================================
hr "PHASE B — three reruns of the archived check, three fresh locations"
# Three destination paths of three different lengths, so a length-sensitive
# difference (column alignment, truncation) would show up too.
D1="$WORK/a"
D2="$WORK/bbbbbbbbbbbbbbbbbbbbbbbb"
D3="$WORK/cccccccccccccccccccccccccccccccccccccccccccccccc"
echo "run 1: fresh COLD copy (no provisioned tools/), invoked with the working directory set to /"
seed "$D1" cold
( cd / && bash "$D1/empirical/conventional-commits-linter-eval/evaluate.sh" ) > "$WORK/run1.log" 2>&1
assert_eq "run1/exit" 0 "$?"
echo "run 2: fresh WARM copy seeded with run 1's binaries, longer path, invoked from the run directory"
seed "$D2" cold
cp -R "$D1/empirical/tools" "$D2/empirical/tools"
cp -R "$D1/empirical/conventional-commits-linter-eval/tools" \
      "$D2/empirical/conventional-commits-linter-eval/tools"
bash "$D2/empirical/conventional-commits-linter-eval/evaluate.sh" > "$WORK/run2.log" 2>&1
assert_eq "run2/exit" 0 "$?"
echo "run 3: fresh WARM copy, longer path still, invoked from inside its own copy"
seed "$D3" cold
cp -R "$D1/empirical/tools" "$D3/empirical/tools"
cp -R "$D1/empirical/conventional-commits-linter-eval/tools" \
      "$D3/empirical/conventional-commits-linter-eval/tools"
( cd "$D3" && bash "$D3/empirical/conventional-commits-linter-eval/evaluate.sh" ) > "$WORK/run3.log" 2>&1
assert_eq "run3/exit" 0 "$?"
for r in 1 2 3; do shape "run$r" "$WORK/run$r.log"; done

# ==========================================================================
hr "PHASE C — classify every differing line"
compare "cited-vs-run1-cold-cwd-slash"  "$CITED"         "$WORK/run1.log"
compare "cited-vs-run2-warm-longpath"   "$CITED"         "$WORK/run2.log"
compare "cited-vs-run3-warm-longerpath" "$CITED"         "$WORK/run3.log"
compare "run1-vs-run2"                  "$WORK/run1.log" "$WORK/run2.log"
compare "run2-vs-run3"                  "$WORK/run2.log" "$WORK/run3.log"

# ==========================================================================
hr "PHASE D — which classes were actually observed"
sort -u "$OBSERVED"
for k in T-timestamp I-provisioning-preamble; do
  assert_eq "coverage/$k-observed" 1 "$(grep -cx "$k" "$OBSERVED" > /dev/null && echo 1 || echo 0)"
done
echo "Classes T and I were observed live. Class F was observed only if a live"
echo "counter moved inside this script's few-minute window; its identity across"
echo "these runs is a property of the window, not a guarantee, which is why the"
echo "rule compares that block rather than asserting it. Classes H and S cannot"
echo "be observed here — every run above is the same host and the same toolchain,"
echo "so both lines come out identical — and are exercised by the synthetic"
echo "in-position control of PHASE H2 instead."
echo "run2 vs run3: two WARM runs minutes apart at different paths. The only"
echo "differences either carries are class T and, if a counter moved, class F."

# ==========================================================================
hr "PHASE E — the revision-6 defect and its cause, from committed files"
echo "The revision-6 evaluate.sh, recovered from git by blob id $R6_BLOB,"
echo "handed the control an ABSOLUTE path; revision 7 invokes it from inside the"
echo "work directory with a bare relative name:"
git cat-file blob "$R6_BLOB" > "$WORK/evaluate.r6.sh" 2>"$WORK/blob.err"
assert_eq "r6/blob-recovered" 0 "$?"
assert_eq "r6/blob-is-the-evaluation-script" 1 \
  "$(grep -c '^# Evaluation (not the acceptance check) of conventional_commits_linter 0.17.1$' "$WORK/evaluate.r6.sh" | tr -d ' ')"
echo "revision 6:"; grep -n 'commit-file "\$WORK/upper-bad.txt"' "$WORK/evaluate.r6.sh" | sed 's/^/  /'
echo "revision 7:"; grep -n 'commit-file upper-bad.txt' "$CHECK" | sed 's/^/  /'
assert_eq "r6/used-the-absolute-path" 1 \
  "$(grep -c 'commit-file "\$WORK/upper-bad.txt"' "$WORK/evaluate.r6.sh" | tr -d ' ')"
assert_eq "r7/uses-a-relative-name-from-inside-the-work-directory" 1 \
  "$(grep -c 'cd "\$WORK" && "\$CTL" --config "\$CTLCFG" --commit-file upper-bad.txt' "$CHECK" | tr -d ' ')"
assert_eq "r7/absolute-form-is-gone" 0 \
  "$(grep -c 'commit-file "\$WORK/upper-bad.txt"' "$CHECK" | tr -d ' ')"

echo
echo "The mechanism, driven directly: the same message file placed at two"
echo "different absolute locations, read by the same control binary, under the"
echo "revision-6 invocation form and then under the revision-7 form."
CTLBIN="$D1/empirical/tools/bin/committed"
assert_eq "mech/control-binary-present" 1 "$([ -x "$CTLBIN" ] && echo 1 || echo 0)"
for d in "$WORK/loc-one" "$WORK/loc-two-is-a-much-longer-directory-name"; do
  mkdir -p "$d"
  printf 'WIBBLE(cli): add --json output flag\n' > "$d/upper-bad.txt"
done
old_form() { "$CTLBIN" --config "$CTLCFG_ABS" --commit-file "$1/upper-bad.txt" 2>&1; }
new_form() { ( cd "$1" && "$CTLBIN" --config "$CTLCFG_ABS" --commit-file upper-bad.txt 2>&1 ); }
old_form "$WORK/loc-one" > "$WORK/old-1.txt"; OLD1=$?
old_form "$WORK/loc-two-is-a-much-longer-directory-name" > "$WORK/old-2.txt"; OLD2=$?
new_form "$WORK/loc-one" > "$WORK/new-1.txt"; NEW1=$?
new_form "$WORK/loc-two-is-a-much-longer-directory-name" > "$WORK/new-2.txt"; NEW2=$?
echo "revision-6 form, location one: $(redact < "$WORK/old-1.txt")"
echo "revision-6 form, location two: $(redact < "$WORK/old-2.txt")"
echo "revision-7 form, location one: $(cat "$WORK/new-1.txt")"
echo "revision-7 form, location two: $(cat "$WORK/new-2.txt")"
assert_eq "mech/old-form-differs-across-locations" "differs" \
  "$(diff -q "$WORK/old-1.txt" "$WORK/old-2.txt" > /dev/null && echo same || echo differs)"
assert_eq "mech/new-form-identical-across-locations" "same" \
  "$(diff -q "$WORK/new-1.txt" "$WORK/new-2.txt" > /dev/null && echo same || echo differs)"
assert_eq "mech/new-form-quotes-no-absolute-path" 0 \
  "$(grep -cE '(^|[^A-Za-z0-9_.-])/(Users|private|home|tmp|var)/' "$WORK/new-1.txt" | tr -d ' ')"
assert_eq "mech/new-form-text-is-the-bare-file-name" 1 \
  "$(grep -c '^upper-bad.txt: error Disallowed type `WIBBLE` used' "$WORK/new-1.txt" | tr -d ' ')"
echo "and the exit status the check asserts is unchanged by the change of form:"
printf 'old-form exits: %s %s   new-form exits: %s %s\n' "$OLD1" "$OLD2" "$NEW1" "$NEW2"
assert_eq "mech/exit-status-unchanged" "1 1 1 1" "$OLD1 $OLD2 $NEW1 $NEW2"

# ==========================================================================
hr "PHASE F — negative control 1: an UNCLASSIFIED difference is rejected"
echo "Mutate one asserted PASS row of run 1 — a line carrying no class shape —"
echo "and the classifier must refuse to place it."
sed 's/^A2       expected=committed 1.1.11/A2       expected=committed 9.9.9 /' \
  "$WORK/run1.log" > "$WORK/neg1.log"
assert_eq "neg1/mutation-applied" 1 \
  "$(diff "$WORK/run1.log" "$WORK/neg1.log" | grep -c '^> A2       expected=committed 9.9.9' | tr -d ' ')"
compare "neg1-unclassified-difference" "$WORK/run1.log" "$WORK/neg1.log" 1 0

hr "PHASE F2 — negative control 2: the revision-6 C23 line is rejected"
echo "The control that matters. Put the revision-6 absolute-path diagnostic back"
echo "into one copy of run 1 and the classifier must call it UNCLASSIFIED — this"
echo "is the exact difference the revision-6 auditor found and revision 6's"
echo "byte-for-byte sentence did not account for."
R6C23=$(grep -E '^ +[|] .*/[.]work/upper-bad[.]txt: error Disallowed type' "$R6LOG")
assert_eq "neg2/r6-line-recovered" 1 "$([ -n "$R6C23" ] && echo 1 || echo 0)"
python3 - "$WORK/run1.log" "$WORK/neg2.log" "$R6C23" <<'PY'
import sys
src, dst, repl = sys.argv[1], sys.argv[2], sys.argv[3]
out = []
for l in open(src, encoding="utf-8", errors="replace").read().split("\n"):
    out.append(repl if l.startswith("       | upper-bad.txt: error Disallowed type") else l)
open(dst, "w", encoding="utf-8").write("\n".join(out))
PY
assert_eq "neg2/substitution-applied" 1 \
  "$(grep -cE '^ +[|] .*/[.]work/upper-bad[.]txt: error Disallowed type' "$WORK/neg2.log" | tr -d ' ')"
compare "neg2-revision-6-absolute-path-line" "$WORK/run1.log" "$WORK/neg2.log" 1 0

hr "PHASE F3 — negative control 3: a TAIL line-count change is rejected"
sed '$d' "$WORK/run1.log" > "$WORK/neg3.log"
assert_eq "neg3/one-line-shorter" 1 \
  "$(( $(wc -l < "$WORK/run1.log") - $(wc -l < "$WORK/neg3.log") ))"
compare "neg3-tail-line-count-change" "$WORK/run1.log" "$WORK/neg3.log" 1 1

hr "PHASE F4 — negative control 4: a HEAD line-count change is rejected"
grep -v '^B1       expected=0  ' "$WORK/run1.log" > "$WORK/neg4.log"
assert_eq "neg4/one-head-line-removed" 1 \
  "$(( $(wc -l < "$WORK/run1.log") - $(wc -l < "$WORK/neg4.log") ))"
compare "neg4-head-line-count-change" "$WORK/run1.log" "$WORK/neg4.log" 1 1

# ==========================================================================
hr "PHASE G — negative control 5: class-shaped differences OUT OF POSITION"
echo "A differing line of the right shape at a line number the rule does not"
echo "allow is a VIOLATION, not an allowed difference. Pick an asserted row of"
echo "the cited log that carries no class shape and make two copies differ there"
echo "with class-T, class-H and class-S shapes in turn."
OUTPOS=$(grep -n '^C01      expected=' "$CITED" | head -1 | cut -d: -f1)
echo "chosen line $OUTPOS of the cited log: $(sed -n "${OUTPOS}p" "$CITED")"
T_SHAPE='conventional_commits_linter evaluation, date (UTC): 2000-01-01T00:00:0%sZ   [volatile line]'
H_SHAPE='host: synthetic-%s'
S_SHAPE='         candidate size:  %s bytes   [volatile line]'
for k in T:"$T_SHAPE" H:"$H_SHAPE" S:"$S_SHAPE"; do
  name=${k%%:*}; fmt=${k#*:}
  # shellcheck disable=SC2059
  awk -v n="$OUTPOS" -v s="$(printf "$fmt" 1)" 'NR==n{print s; next}{print}' "$CITED" > "$WORK/out-$name-a.log"
  # shellcheck disable=SC2059
  awk -v n="$OUTPOS" -v s="$(printf "$fmt" 2)" 'NR==n{print s; next}{print}' "$CITED" > "$WORK/out-$name-b.log"
  compare "negG-class-$name-out-of-position" "$WORK/out-$name-a.log" "$WORK/out-$name-b.log" 0 1
done

hr "PHASE G2 — negative control 6: a class-I line OUT OF ITS WINDOW"
echo "Class I is admitted only strictly between the host line and the A1 row."
echo "Insert a provisioning-shaped line after A1 instead."
awk '{print} /^A1 /{print "provisioning something out of its window ..."}' "$CITED" > "$WORK/out-I-a.log"
awk '{print} /^A1 /{print "provisioning something else out of its window ..."}' "$CITED" > "$WORK/out-I-b.log"
assert_eq "negG2/lines-inserted" 1 \
  "$(( $(wc -l < "$WORK/out-I-a.log") - $(wc -l < "$CITED") ))"
compare "negG2-class-I-out-of-window" "$WORK/out-I-a.log" "$WORK/out-I-b.log" 0 2

hr "PHASE H2 — positive control: the SAME shapes IN position are classified"
echo "The mirror of PHASE G. At an allowed position each class must be"
echo "classified with zero violations — otherwise PHASE G would only be showing"
echo "that the classifier rejects everything. This is also where classes H and S"
echo "are exercised at all, since one host cannot vary them."
for k in T:"$T_SHAPE" H:"$H_SHAPE" S:"$S_SHAPE"; do
  name=${k%%:*}; fmt=${k#*:}
  case "$name" in
    T) INPOS=$(grep -nE '^conventional_commits_linter evaluation, date \(UTC\): ' "$CITED" | head -1 | cut -d: -f1) ;;
    H) INPOS=$(grep -n '^host: ' "$CITED" | head -1 | cut -d: -f1) ;;
    S) INPOS=$(grep -nE '^ +candidate size: ' "$CITED" | head -1 | cut -d: -f1) ;;
  esac
  echo "class $name allowed position $INPOS: $(sed -n "${INPOS}p" "$CITED")"
  # shellcheck disable=SC2059
  awk -v n="$INPOS" -v s="$(printf "$fmt" 1)" 'NR==n{print s; next}{print}' "$CITED" > "$WORK/in-$name-a.log"
  # shellcheck disable=SC2059
  awk -v n="$INPOS" -v s="$(printf "$fmt" 2)" 'NR==n{print s; next}{print}' "$CITED" > "$WORK/in-$name-b.log"
  compare "negH2-class-$name-in-position" "$WORK/in-$name-a.log" "$WORK/in-$name-b.log" 0 0
done

hr "PHASE H3 — positive control: class F may differ freely"
echo "Two copies whose figures blocks differ in content AND in line count must"
echo "classify cleanly, because no assertion reads that block."
awk '/^ *[|] crates[.]io recent_downloads=/{print "       | crates.io recent_downloads=1 downloads=2 max_stable_version=0.17.1"; next}{print}' \
  "$CITED" > "$WORK/fig-a.log"
awk '/^ *[|] github code search, /{next}{print}' "$CITED" > "$WORK/fig-b.log"
assert_eq "negH3/figures-line-dropped" 1 \
  "$(( $(wc -l < "$CITED") - $(wc -l < "$WORK/fig-b.log") ))"
compare "negH3-figures-block-differs" "$WORK/fig-a.log" "$WORK/fig-b.log" 0 0

# ==========================================================================
hr "PHASE I — the check itself can still fail"
echo "A check that cannot fail is not evidence. Break ONE recorded expectation in"
echo "a warm copy of the script — C23's expected exit status — and the check must"
echo "exit 1 with a FAIL row and RESULT: FAIL."
seed "$WORK/negrun" cold
cp -R "$D1/empirical/tools" "$WORK/negrun/empirical/tools"
cp -R "$D1/empirical/conventional-commits-linter-eval/tools" \
      "$WORK/negrun/empirical/conventional-commits-linter-eval/tools"
NEGSCRIPT="$WORK/negrun/empirical/conventional-commits-linter-eval/evaluate.sh"
sed -i.bak 's/^ok C23 1 "\$rc"/ok C23 0 "$rc"/' "$NEGSCRIPT"
assert_eq "negrun/mutation-applied" 1 "$(grep -c '^ok C23 0 "\$rc"' "$NEGSCRIPT" | tr -d ' ')"
bash "$NEGSCRIPT" > "$WORK/negrun.log" 2>&1
NEGRUN_EXIT=$?
tail -2 "$WORK/negrun.log" | redact
assert_eq "negrun/exit" 1 "$NEGRUN_EXIT"
assert_eq "negrun/fail-rows" 1 "$(grep -cE "$ROW FAIL " "$WORK/negrun.log" | tr -d ' ')"
assert_eq "negrun/summary" "summary: PASS=54 FAIL=1 CONTRACT_VIOLATIONS=3" \
  "$(grep -m1 '^summary: ' "$WORK/negrun.log")"
assert_eq "negrun/result-line" 1 "$(grep -c '^RESULT: FAIL$' "$WORK/negrun.log" | tr -d ' ')"

# ==========================================================================
hr "PHASE J — this comparator's own log carries no scratch path"
echo "Asserted by the caller, not here: this script writes its log to a path the"
echo "caller chooses. What it CAN assert is that nothing it printed above came"
echo "out of \$WORK unredacted, which is checked by the caller's grep of the log"
echo "and, here, by re-checking every file this script printed from."
for f in "$WORK/new-1.txt" "$WORK/new-2.txt"; do
  assert_eq "selflog/$(basename "$f")-is-scratch-path-free" 0 \
    "$(grep -cE '(^|[^A-Za-z0-9_.-])/(Users|private|home|tmp|var)/' "$f" | tr -d ' ')"
done

hr "DONE"
echo "failed assertions: $FAILS"
if [ "$FAILS" -gt 0 ]; then
  echo "RESULT: FAIL — the difference rule stated in review/DECISION.md does not hold."
  exit 1
fi
echo "RESULT: PASS — every rerun conformed to the rule; every negative control was rejected."
exit 0
