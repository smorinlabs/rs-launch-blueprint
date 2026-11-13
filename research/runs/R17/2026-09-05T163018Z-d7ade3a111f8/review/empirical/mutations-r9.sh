#!/usr/bin/env bash
# R17 secret-scanning-ci-workflow — revision 9 mutation harness.
#
# WHY THIS FILE EXISTS, AND WHAT IT CHANGES FROM mutations-r8.sh.
# Round 8 rejected revision 8 on one finding, F3: `mutations-r8.sh` took its Python interpreter from
# `PY3=$(command -v python3 || true)` — PATH order alone, no probe. On this host
# `~/.local/share/mise/shims/python3` is a version-manager shim that RUNS under the caller's own
# $HOME and FAILS under an empty one ("Config files in ~/.config/mise/config.toml are not trusted"),
# so revision 8's harness passed for its author and, for an auditor running with HOME=<scratch>,
# printed `MUTATION mutation-1: COULD NOT BE APPLIED`, `MUTATION mutation-2: COULD NOT BE APPLIED`,
# `mutation-harness failures: 2`, `RESULT: FAIL` — before either intended falsification ran.
# The mutation evidence therefore did not reproduce under its own recorded ordinary invocation.
#
# THE REPAIR, and it is the mechanism run-checks-r8.sh already uses rather than a new one:
#   (a) this harness replaces $HOME with its own empty scratch directory BEFORE resolving anything,
#       exactly as run-checks-r8.sh does, so the interpreter it selects does not depend on the
#       caller's home directory — the single variable that separated author from auditor;
#   (b) python3 is then resolved by PROBING candidates in PATH order and keeping the first that
#       actually evaluates `print(7*6)` to 42, so a shim that cannot start an interpreter is
#       BYPASSED rather than accepted; and
#   (c) the interpreter finally used, its `--version`, and any bypass are PRINTED in the log, so a
#       reader can see which binary performed the mutation instead of inferring it from PATH.
# python3 is the only tool this harness resolves by probe because it is the only one shimmed here;
# every other helper it calls is printed by absolute path in the same block, unprobed and named.
#
# mutations-r8.sh and every revision-8 log are left byte-identical; they remain revision 8's record.
#
# WHAT IT MUTATES — unchanged from revision 8, and it is the point of the file. "A check that cannot
# fail is not evidence", so this harness DEMONSTRATES that revision 8's new section-08 assertions
# fail when the fact they assert is taken away. It mutates a COPY of run-checks-r8.sh under $TMPDIR,
# runs the copy, and prints that run's section-08 RESULT lines and closing summary.
# run-checks-r8.sh itself is never written to.
#
# MUTATION 1 (round-7 finding F2, the per-value output-safety assertions). The three per-value checks
# are pointed at the `--json` output — which 08b asserts prints every detected value verbatim —
# instead of the `--github-actions` output. 08h, 08i and 08j must FAIL, and the run must exit 1.
#
# MUTATION 2 (round-7 finding F1, the executed `--redact` rejection). Both `--redact` invocations are
# given `--no-verification` instead, a flag this binary accepts. 08e must FAIL, because the binary no
# longer refuses anything. This is also the control for 08f: it shows that the accepted flag really
# does exit differently from the rejected one, on the same two targets.
#
# ONE ASSERTION ADDED BEYOND revision 8's harness: each mutant's FAILing labels are collected from
# its own output and compared AS A SET against the labels the mutation was built to break, so the
# harness now shows that a mutation broke exactly its targets and nothing else. Revision 8 asserted
# only that the targets failed, which a mutation with collateral damage would also have satisfied.
#
# Declared environment:
#   PY_REPO / TS_REPO / GH_TOKEN  passed straight through to the mutant; absent -> it SKIPs by name.
#   HOME                          replaced here by an empty scratch directory (see (a) above); the
#                                 mutant then replaces it again with its own, as it always does.
#   /usr/bin/grep                 by absolute path, named beside every count.
# The mutant runs from $TMPDIR, so it is outside the repository: it is given DEC_NOW and REV2_FILE
# explicitly (the script supports both), and its 13q SKIPs by name for want of a .git directory.
# That skip is the mutant's, never this harness's evidence. Every SKIP the mutant prints is
# reproduced here BY NAME rather than left as a count in its summary line, so nothing is counted away.
#
# Usage: bash mutations-r9.sh   (exit 0 = every mutation failed exactly the assertions it targeted)

set -u
set -o pipefail

GREP=/usr/bin/grep
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/run-checks-r8.sh"
RUN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/r17-mutate-r9.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# --- the caller's HOME is recorded and then replaced, before anything is resolved ---------------
CALLER_HOME="${HOME:-unset}"
mkdir -p "$WORK/home"
export HOME="$WORK/home"
unset XDG_CACHE_HOME XDG_CONFIG_HOME 2>/dev/null || true

# --- python3 resolved by probe, not by PATH order: the F3 repair ---------------------------------
tool_ok() { # tool_ok <path> <tool name>
  case "$2" in
    python3) [ "$("$1" -c 'print(7*6)' 2>/dev/null)" = 42 ] ;;
    *)       return 1 ;;
  esac
}
resolve_tool() { # resolve_tool <name> — echoes the first candidate that performs the operation
  local n="$1" c
  for c in "$(command -v "$n" 2>/dev/null || true)" /opt/homebrew/bin/"$n" /usr/local/bin/"$n" /usr/bin/"$n" /bin/"$n"; do
    { [ -n "$c" ] && [ -x "$c" ]; } || continue
    if tool_ok "$c" "$n"; then printf '%s\n' "$c"; return 0; fi
  done
  return 1
}
PY3=$(resolve_tool python3 || true)

echo "harness: $0"
echo "caller HOME (recorded, NOT used): $CALLER_HOME"
echo "HOME used by this harness: $HOME"
echo "counting binary for every count below: $GREP ($("$GREP" --version 2>/dev/null | head -1))"
echo "python3 resolved by probing each candidate under the empty HOME above, not by PATH order:"
echo "   python3 used by this harness: ${PY3:-none}"
if [ -n "$PY3" ]; then
  printf '   its own version string: %s\n' "$("$PY3" --version 2>&1)"
fi
PY_FIRST=$(command -v python3 2>/dev/null || echo none)
if [ "$PY_FIRST" != none ] && [ "$PY_FIRST" != "${PY3:-}" ]; then
  echo "   python3 first on PATH was BYPASSED: $PY_FIRST (it failed this harness's probe for python3 under the empty HOME in force)"
else
  echo "   python3 first on PATH was NOT bypassed: $PY_FIRST passed the probe and is the interpreter above"
fi
echo "other helpers this harness calls, by the path the shell resolves, unprobed and named:"
printf '   shasum=%s cut=%s sed=%s sort=%s tr=%s head=%s\n' \
  "$(command -v shasum || echo none)" "$(command -v cut || echo none)" \
  "$(command -v sed || echo none)" "$(command -v sort || echo none)" \
  "$(command -v tr || echo none)" "$(command -v head || echo none)"

if [ -z "$PY3" ] || [ ! -s "$SRC" ]; then
  echo "cannot run: no python3 passed the probe (python3=${PY3:-none}) or source missing ($SRC)"
  exit 2
fi

echo "source under mutation: $SRC (sha256 $(shasum -a 256 < "$SRC" | cut -d' ' -f1))"
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
  echo "-- every SKIP the mutant printed, named in full (the mutant's environment, never this harness's evidence):"
  { "$GREP" -E '^RESULT [A-Za-z0-9-]+: SKIP' "$log" || true; } | sed 's/^/   /'
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
  # New in revision 9: the mutation must break its targets AND NOTHING ELSE. The mutant's own
  # FAILing labels are collected from its output and compared as a set with the expected ones.
  local explist gotlist
  explist=$(printf '%s' "$expected" | tr ' ' '\n' | "$GREP" -v '^$' | sort | tr '\n' ' ')
  gotlist=$("$GREP" -oE '^RESULT [A-Za-z0-9-]+: FAIL' "$log" | sed -E 's/^RESULT //; s/: FAIL$//' | sort | tr '\n' ' ' || true)
  if [ "$gotlist" = "$explist" ]; then
    echo "   MUTATION CHECK failing-set: the mutant's FAILing labels are exactly the targeted ones (via $GREP over its output)"
    echo "      expected: $explist"
    echo "      observed: $gotlist"
  else
    echo "   MUTATION CHECK failing-set: the mutant FAILED a different set than the mutation targets"
    echo "      expected: $explist"
    echo "      observed: $gotlist"
    MUT_FAILS=$((MUT_FAILS+1))
  fi
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
  echo "RESULT: PASS (every mutated assertion failed, the failing set was exactly the targeted one, and every mutated run exited non-zero)"
  exit 0
fi
echo "RESULT: FAIL (a mutation did not break exactly the assertions it targeted, or a mutated run exited 0)"
exit 1
