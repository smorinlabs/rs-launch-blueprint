#!/usr/bin/env bash
# R54 revision 3 — the NEW assertions added to answer the round-2 judgment audit
# (review/audit-fable.md, finding JF-5).
#
# JF-5: revision 2's JF-3 repair called `project-search` "one of eight member-level
# `owns` lines" in `raw/doxa-openai.normalized.md`, which carries TWELVE, and no
# check asserted the number — `V17` pinned only that `project-search` sits at :401.
# Group `M` below makes the count checkable at its three ranges.
#
# Revision 1's and revision 2's cited artifacts are preservation targets and stay
# byte-identical; group `B` re-asserts every one of them by sha256 rather than in
# prose. Every other check here is new.
#
# Each check asserts on CONTENT and prints one stable `PASS`/`FAIL`/`SKIP` line.
# `/usr/bin/grep` is invoked by absolute path and its version is printed beside
# every count it produces. There is no network access and no git history is
# required, so this script produces the same lines run in place and run from a
# clean `git archive HEAD` extraction, apart from the `repo-root` header naming
# the extraction directory.
#
# Nothing is written outside this directory's own log files.

# shellcheck disable=SC2016  # the needles are literal quotations; `$` and backticks inside them must NOT expand.

set -u
set -o pipefail

GREP=/usr/bin/grep
GREPV="$(/usr/bin/grep --version | head -1)"
FAILURES=0
SKIPPED=0

EVIDENCE_DIR="$(cd "$(dirname "$0")" && pwd)"
SNAP="$EVIDENCE_DIR/snapshots"
REPO_ROOT="$(cd "$EVIDENCE_DIR/../../../../../.." && pwd)"
RUN_DIR="$(cd "$EVIDENCE_DIR/../.." && pwd)"
DEC="$RUN_DIR/review/DECISION.md"
OPENAI_RAW="$RUN_DIR/raw/doxa-openai.normalized.md"
REG="$REPO_ROOT/docs/port/PARAMETERS.md"

pass() { echo "PASS $1 $2"; }
fail() { echo "FAIL $1 $2"; FAILURES=$((FAILURES + 1)); }
# Retained deliberately though unused: every check in this script reads a tracked
# file, so none has a skippable precondition and `skipped=` is 0 in both the
# in-place and the clean-archive run. Keeping the helper keeps that a measured
# total rather than a literal.
# shellcheck disable=SC2329
skip() { echo "SKIP $1 $2"; SKIPPED=$((SKIPPED + 1)); }

sha_of() { shasum -a 256 "$1" | awk '{print $1}'; }

# assert_contains <id> <file> <needle> <label>
assert_contains() {
  local id="$1" file="$2" needle="$3" label="$4" n
  if [ ! -s "$file" ]; then
    fail "$id" "$label (missing or empty input)"
    return
  fi
  n="$("$GREP" -c -F -- "$needle" "$file")"
  if [ "$n" -ge 1 ]; then
    pass "$id" "$label (/usr/bin/grep [$GREPV] -c -F matches=$n)"
  else
    fail "$id" "$label (/usr/bin/grep [$GREPV] -c -F matches=0)"
  fi
}

# assert_sha <id> <file> <expected> <label>
assert_sha() {
  local id="$1" file="$2" want="$3" label="$4" got
  if [ ! -f "$file" ]; then
    fail "$id" "$label (file absent)"
    return
  fi
  got="$(sha_of "$file")"
  if [ "$got" = "$want" ]; then
    pass "$id" "$label ($want)"
  else
    fail "$id" "$label (got $got, want $want)"
  fi
}

echo "=== R54 revision 3 evidence checks (JF-5) ==="
echo "repo-root  $REPO_ROOT"
echo "run-dir    ${RUN_DIR#"$REPO_ROOT"/}"
echo "grep       $GREP ($GREPV) — invoked by absolute path; its version is printed beside every count below"
echo "network    none, and no git history is required — every check reads a file already in the repository"
echo

# ---------------------------------------------------------------------------
# B — every revision-1 and revision-2 cited artifact is byte-identical.
# ---------------------------------------------------------------------------
assert_sha B01 "$EVIDENCE_DIR/check.sh" 7e22e8ffc7c4ae15b87c587250e6dc8914c18ab2273be2c14127a7bfa13a1894 'revision 1 check.sh is unchanged'
assert_sha B02 "$EVIDENCE_DIR/check.log" a1f676c92f523faeecd5c2cd6c6e088cbed968950ec4fa085909acc4a2a3a9de 'revision 1 check.log is unchanged'
assert_sha B03 "$EVIDENCE_DIR/check-rerun.log" a1f676c92f523faeecd5c2cd6c6e088cbed968950ec4fa085909acc4a2a3a9de 'revision 1 check-rerun.log is unchanged'
assert_sha B04 "$EVIDENCE_DIR/walkup_probe.rs" faa0e5de7bf4f42e21c09c07ea1f3084c92b51244869efd9ae6a02a0128ec094 'revision 1 walkup_probe.rs is unchanged'
assert_sha B05 "$EVIDENCE_DIR/shellcheck.log" e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 'revision 1 shellcheck.log is unchanged (empty)'
SNAPCOUNT="$(find "$SNAP" -type f | wc -l | tr -d ' ')"
SNAPDIGEST="$(cd "$SNAP" && shasum -a 256 -- * | sort | shasum -a 256 | awk '{print $1}')"
if [ "$SNAPCOUNT" = "13" ] && [ "$SNAPDIGEST" = "fa53d95ac8143ce41b223c2826f4ff366f82413063dbc0c0f5f2ec94c59878cf" ]; then
  pass B06 "all 13 revision-1 snapshots are unchanged (digest of the sorted sha256 manifest: $SNAPDIGEST)"
else
  fail B06 "snapshots moved (count=$SNAPCOUNT digest=$SNAPDIGEST)"
fi
assert_sha B07 "$EVIDENCE_DIR/check-r2.sh" 165bd08d38273c655ecce1c8be8eae6157e12a9995af230254955d6ae614fa62 'revision 2 check-r2.sh is unchanged'
assert_sha B08 "$EVIDENCE_DIR/check-r2.log" 41aea179be46dc5c1cd4072f365ef89bc86c08bcb4261190c5c25281a53dd5fc 'revision 2 check-r2.log is unchanged'
assert_sha B09 "$EVIDENCE_DIR/check-r2-archive.log" 3dcb5981dd114a11c7deae47e6b8966580857a2ae56fbce211bd4b5f39566102 'revision 2 check-r2-archive.log is unchanged'
assert_sha B10 "$EVIDENCE_DIR/r2-rerun.diff" e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 'revision 2 r2-rerun.diff is unchanged (empty: the rerun matched byte-for-byte)'
assert_sha B11 "$EVIDENCE_DIR/shellcheck-r2.log" e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 'revision 2 shellcheck-r2.log is unchanged (empty)'

# ---------------------------------------------------------------------------
# M — JF-5: the member-level `owns` count in the Doxa/OpenAI twin.
# ---------------------------------------------------------------------------
MEMBER_N="$("$GREP" -c '^- `owns ' "$OPENAI_RAW")"
if [ "$MEMBER_N" = "12" ]; then
  pass M01 "JF-5: raw/doxa-openai.normalized.md carries 12 member-level \`owns\` lines (/usr/bin/grep [$GREPV] -c '^- \`owns ' = $MEMBER_N)"
else
  fail M01 "JF-5: member-level \`owns\` count is $MEMBER_N, expected 12 (/usr/bin/grep [$GREPV] -c '^- \`owns ')"
fi

MEMBER_LINES="$("$GREP" -n '^- `owns ' "$OPENAI_RAW" | awk -F: '{print $1}' | tr '\n' ' ')"
if [ "$MEMBER_LINES" = "398 399 400 401 536 537 538 539 678 679 680 681 " ]; then
  pass M02 "JF-5: those 12 lines fall in exactly the three ranges :398-401, :536-539 and :678-681"
else
  fail M02 "JF-5: member-level \`owns\` lines are at [$MEMBER_LINES], expected 398-401, 536-539, 678-681"
fi

for range in "M03:398:401:4" "M04:536:539:4" "M05:678:681:4"; do
  id="${range%%:*}"; rest="${range#*:}"; a="${rest%%:*}"; rest="${rest#*:}"; b="${rest%%:*}"; want="${rest##*:}"
  n="$(awk -v a="$a" -v b="$b" 'NR>=a && NR<=b' "$OPENAI_RAW" | "$GREP" -c '^- `owns ')"
  if [ "$n" = "$want" ]; then
    pass "$id" "JF-5: lines :$a-$b hold $n member-level \`owns\` lines (/usr/bin/grep [$GREPV] -c '^- \`owns ')"
  else
    fail "$id" "JF-5: lines :$a-$b hold $n member-level \`owns\` lines, expected $want"
  fi
done

MEMBER_NAMES="$("$GREP" '^- `owns ' "$OPENAI_RAW" | awk '{print $3}' | tr '\n' ' ')"
if [ "$MEMBER_NAMES" = "system-config-roots user-config-root config-relative-path project-search table-merge leaf-merge array-merge source-order config-selector-cli config-selector-env selector-precedence cli-data-overrides " ]; then
  pass M06 "JF-5: the twelve member-level names are exactly those the audit lists"
else
  fail M06 "JF-5: member-level names read as [$MEMBER_NAMES]"
fi

ANSWER_N="$("$GREP" -c '^`owns ' "$OPENAI_RAW")"
if [ "$ANSWER_N" = "8" ]; then
  pass M07 "the answer-level form is a different count and still 8, so the eight-versus-twelve distinction the sentence draws is real (/usr/bin/grep [$GREPV] -c '^\`owns ' = $ANSWER_N)"
else
  fail M07 "answer-level \`owns\` count is $ANSWER_N, expected 8"
fi

# ---------------------------------------------------------------------------
# M — JF-5: the decision now states twelve, with the three ranges.
# ---------------------------------------------------------------------------
assert_contains M08 "$DEC" 'one of **twelve** *member-level* `owns` lines (`:398-401`, `:536-539`, `:678-681`)' 'JF-5: the corrected sentence carries twelve and its three ranges'
SUP_ALL="$("$GREP" -c -F 'one of eight *member-level* `owns` lines' "$DEC")"
SUP_NOTE="$("$GREP" -c -E '^\| \*\*JF-5\*\*.*one of eight \*member-level\*' "$DEC")"
if [ "$SUP_ALL" = "1" ] && [ "$SUP_NOTE" = "1" ]; then
  pass M09 "JF-5: the superseded wording survives exactly once, inside the revision note's JF-5 row, and nowhere as an assertion (/usr/bin/grep [$GREPV] -c: all=$SUP_ALL note=$SUP_NOTE)"
else
  fail M09 "JF-5: 'one of eight *member-level* \`owns\` lines' occurs $SUP_ALL times, $SUP_NOTE of them in the JF-5 note row (expected 1 and 1)"
fi
DECLINE="$("$GREP" -n -F 'one of **twelve** *member-level* `owns` lines' "$DEC" | awk -F: '{print $1}')"
if [ -n "$DECLINE" ]; then
  pass M10 "JF-5: the corrected sentence is at DECISION.md:$DECLINE — the audit found the wrong count at :716 of revision 2"
else
  fail M10 "JF-5: the corrected sentence was not located in DECISION.md"
fi

# ---------------------------------------------------------------------------
# P — the five `- assumes` lines, re-asserted independently of the other scripts.
# ---------------------------------------------------------------------------
i=0
for param in msrv-policy rust-edition target-os-matrix license error-taxonomy-exit-codes; do
  i=$((i + 1))
  want="$(awk -F' \\| ' -v p="$param" '$0 ~ "^\\| " p " \\|" {print $4}' "$REG")"
  got="$(awk -v p="$param" 'index($0, "- assumes " p " = ") == 1 {print substr($0, length("- assumes " p " = ") + 1)}' "$DEC")"
  if [ -n "$want" ] && [ "$want" = "$got" ]; then
    pass "P0$i" "- assumes $param unchanged and byte-identical to docs/port/PARAMETERS.md (${#want} bytes)"
  else
    fail "P0$i" "- assumes $param differs (registry ${#want} bytes, decision ${#got} bytes)"
  fi
done

# ---------------------------------------------------------------------------
# E — the revision-3 envelope.
# ---------------------------------------------------------------------------
assert_contains E01 "$DEC" '# 2026-09-18 — R54 — config-discovery-tiers (bundle, Deep) — decision (revision 3)' 'the decision is retitled to revision 3, date first'
assert_contains E02 "$DEC" '**Revision note (revision 3).**' 'the revision note is present'
assert_contains E03 "$DEC" '**JF-5**' 'the revision note names JF-5'
assert_contains E04 "$DEC" '**Revision 3**, 2026-09-18:' 'the revision history is extended'
SUPER_N="$("$GREP" -c -E '^## Supersedes' "$DEC")"
if [ "$SUPER_N" = "0" ]; then
  pass E05 'no "## Supersedes" HEADING — this item is unpublished'
else
  fail E05 "a ## Supersedes heading is present ($SUPER_N)"
fi
H2S="$("$GREP" -c -E '^## (Decision|Parameters|Empirical check|Engines)$' "$DEC")"
H2X="$("$GREP" -c -E '^## ' "$DEC")"
if [ "$H2S" = "4" ] && [ "$H2X" = "4" ]; then
  pass E06 "the H2 set is exactly Decision, Parameters, Empirical check, Engines (/usr/bin/grep [$GREPV] -c: matched=$H2S total=$H2X)"
else
  fail E06 "H2 set wrong (matched=$H2S total=$H2X)"
fi

echo
echo "failures=$FAILURES skipped=$SKIPPED"
if [ "$FAILURES" -ne 0 ]; then
  exit 1
fi
exit 0
