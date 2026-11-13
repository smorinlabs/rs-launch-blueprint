#!/usr/bin/env bash
# R17 secret-scanning-ci-workflow — revision 8 mutation harness.
#
# WHY THIS FILE EXISTS. Round 7 rejected revision 7 because two section-08 claims were stated more
# absolutely than the commands that were recorded could establish. Revision 8 replaces them with
# executed assertions. "A check that cannot fail is not evidence", so this harness DEMONSTRATES that
# the new assertions fail when the fact they assert is taken away, rather than asserting that they
# would. It mutates a COPY of run-checks-r8.sh under $TMPDIR, runs the copy, and prints that run's
# section-08 RESULT lines and closing summary. run-checks-r8.sh itself is never written to.
#
# MUTATION 1 (finding F2, the per-value output-safety assertions). The three per-value checks are
# pointed at the `--json` output — which 08b asserts prints every detected value verbatim — instead
# of the `--github-actions` output. 08h, 08i and 08j must FAIL, and the whole run must exit 1.
#
# MUTATION 2 (finding F1, the executed `--redact` rejection). Both `--redact` invocations are given
# `--no-verification` instead, a flag this binary accepts. 08e must FAIL, because the binary no
# longer refuses anything. This is also the control for 08f: it shows that the accepted flag really
# does exit differently from the rejected one, on the same two targets.
#
# Declared environment, same discipline as run-checks-r8.sh:
#   PY_REPO / TS_REPO / GH_TOKEN  passed straight through to the mutant; absent -> it SKIPs by name.
#   HOME                          the mutant sets its own empty HOME, as the unmutated script does.
#   /usr/bin/grep                 by absolute path, named beside every count.
# The mutant runs from $TMPDIR, so it is outside the repository: it is given DEC_NOW and REV2_FILE
# explicitly (the script supports both), and its 13q SKIPs by name for want of a .git directory.
# That skip is the mutant's, never this harness's evidence.
#
# Usage: bash mutations-r8.sh   (exit 0 = every mutation failed the assertions it was built to break)

set -u
set -o pipefail

GREP=/usr/bin/grep
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/run-checks-r8.sh"
RUN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/r17-mutate-r8.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PY3=$(command -v python3 || true)
if [ -z "$PY3" ] || [ ! -s "$SRC" ]; then
  echo "cannot run: python3=${PY3:-none} source=$SRC"
  exit 2
fi

echo "harness: $0"
echo "source under mutation: $SRC (sha256 $(shasum -a 256 < "$SRC" | cut -d' ' -f1))"
echo "counting binary for every count below: $GREP"
echo "mutant workspace: $WORK"

MUT_FAILS=0

mutate_and_run() { # mutate_and_run <name> <expected failing labels, space separated> <from> <to> [<from> <to> ...]
  local name="$1" expected="$2"; shift 2
  local out="$WORK/$name.sh" log="$WORK/$name.log" rc
  "$PY3" - "$SRC" "$out" "$@" <<'PY'
import sys
src, out = sys.argv[1], sys.argv[2]
pairs = sys.argv[3:]
if len(pairs) % 2:
    sys.exit("odd number of from/to arguments")
s = open(src).read()
for i in range(0, len(pairs), 2):
    a, b = pairs[i], pairs[i + 1]
    n = s.count(a)
    if n != 1:
        sys.exit("MUTATION TARGET MATCHED %d TIMES (expected exactly 1): %s" % (n, a))
    s = s.replace(a, b)
    print("   replaced: %s" % a)
    print("         by: %s" % b)
open(out, "w").write(s)
PY
  if [ ! -s "$out" ]; then
    echo "MUTATION $name: COULD NOT BE APPLIED"
    MUT_FAILS=$((MUT_FAILS+1))
    return
  fi
  DEC_NOW="$RUN_DIR/DECISION.md" REV2_FILE="$SCRIPT_DIR/rev2-DECISION.md" bash "$out" > "$log" 2>&1
  rc=$?
  echo "-- mutant exit status: $rc"
  echo "-- the mutant run's section-08 RESULT lines, printed whole:"
  "$GREP" -n 'RESULT 08' "$log" | "$GREP" -v '^$' | sed 's/^/   /'
  "$GREP" -E '^summary: |^RESULT: ' "$log" | sed 's/^/   /'
  local label got
  for label in $expected; do
    got=$("$GREP" -c "RESULT $label: FAIL" "$log" || true)
    if [ "$got" = 1 ]; then
      echo "   MUTATION CHECK $label: the assertion FAILED under mutation, as it must (count via $GREP: $got)"
    else
      echo "   MUTATION CHECK $label: DID NOT FAIL under mutation — the assertion cannot fail (count via $GREP: $got)"
      MUT_FAILS=$((MUT_FAILS+1))
    fi
  done
  if [ "$rc" -eq 0 ]; then
    echo "   MUTATION CHECK exit-status: the mutated run exited 0 — the script does not fail on a FAIL"
    MUT_FAILS=$((MUT_FAILS+1))
  else
    echo "   MUTATION CHECK exit-status: the mutated run exited $rc, so a FAIL reaches the caller"
  fi
}

printf '\n===== MUTATION 1: the per-value output-safety checks read the --json output =====\n'
echo "Round-7 F2 asked for a separate, falsifiable assertion per credential value. Pointing the three"
echo "github-actions stdout counts at the --json output — the format 08b asserts prints every detected"
echo "value verbatim — must break 08h, 08i and 08j. It is pointed at --json and not at the default"
echo "output deliberately: 08a records that the default output does NOT carry the AWS secret key, so a"
echo "default-output mutation would leave 08j passing and would prove nothing about it."
# shellcheck disable=SC2016  # deliberate: these arguments are LITERAL source text from
# run-checks-r8.sh, matched byte-for-byte by the mutator. Expanding $WORK or $TH_BIN here would
# search for this harness's own values and find nothing, and the mutator fails loudly on that.
mutate_and_run mutation-1 \
  "08h-github-actions-prints-no-occurrence-of-the-synthetic-github-pat 08i-github-actions-prints-no-occurrence-of-the-synthetic-aws-access-key-id 08j-github-actions-prints-no-occurrence-of-the-synthetic-aws-secret-access-key" \
  'G_PAT=$(vcount github-pat "$WORK/g.out")' 'G_PAT=$(vcount github-pat "$WORK/j.out")' \
  'G_AKIA=$(vcount aws-access-key-id "$WORK/g.out")' 'G_AKIA=$(vcount aws-access-key-id "$WORK/j.out")' \
  'G_SK=$(vcount aws-secret-access-key "$WORK/g.out")' 'G_SK=$(vcount aws-secret-access-key "$WORK/j.out")'

printf '\n===== MUTATION 2: the --redact probes are given a flag this binary accepts =====\n'
echo "Round-7 F1 asked for an executed assertion that the pinned binary rejects --redact. Replacing"
echo "--redact with --no-verification on both source kinds must break 08e, because there is then no"
echo "refusal to observe. 08f, the control, goes on passing: that is what makes the pair meaningful."
# shellcheck disable=SC2016  # deliberate: these arguments are LITERAL source text from
# run-checks-r8.sh, matched byte-for-byte by the mutator. Expanding $WORK or $TH_BIN here would
# search for this harness's own values and find nothing, and the mutator fails loudly on that.
mutate_and_run mutation-2 \
  "08e-the-pinned-binary-rejects-redact-on-both-source-kinds" \
  '"$TH_BIN" filesystem "$WORK/redactprobe" --redact --no-update' \
  '"$TH_BIN" filesystem "$WORK/redactprobe" --no-verification --no-update' \
  '"$TH_BIN" git "file://$WORK/fixA" --redact --no-update' \
  '"$TH_BIN" git "file://$WORK/fixA" --no-verification --no-update'

printf '\nmutation-harness failures: %d\n' "$MUT_FAILS"
if [ "$MUT_FAILS" -eq 0 ]; then
  echo "RESULT: PASS (every mutated assertion failed, and every mutated run exited non-zero)"
  exit 0
fi
echo "RESULT: FAIL (an assertion survived the mutation that should have broken it)"
exit 1
