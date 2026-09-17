#!/usr/bin/env bash
# R17 secret-scanning-ci-workflow — revision 11 mutation harness.
#
# WHY THIS FILE EXISTS, AND WHAT IT CHANGES FROM mutations-r9.sh.
# Round 10 rejected revision 10 on one finding, F1: under the required no-credential scratch-HOME
# invocation, `mutations-r9.sh` exited 1. Mutation 1 failed its three targets AND
# `11c-gitleaks-action-license-not-osi`; mutation 2 failed `08e` AND `03a`, `03b`, `10a`-`10d` and
# `11c`. Nothing was wrong with either mutation. The parent check spends FIVE api.github.com core
# requests per run (`/rate_limit`, then four `api_fetch` calls), this harness runs the parent twice,
# and the auditor's anonymous budget stood at 8 of 60 — so the API-dependent assertions that the
# mutation does not target failed for want of budget, and the target-only proof could not hold.
# A falsifiability proof must not rest on a depletable shared resource.
#
# THE REPAIR — a seam run-checks-r8.sh already has, so that file is not modified, patched or read
# for this. It resolves its HTTP client with `resolve_tool curl`, taking the first `curl` on PATH
# that answers `--version`. This harness therefore installs `mutations-r11-curl-shim.sh` as
# `$WORK/bin/curl`, puts that directory first on the MUTANT's PATH, and the parent check resolves
# it and prints it in its own section-00 toolchain line. The shim serves the committed recorded
# responses in `fixtures-r11/` for the five api.github.com endpoints the non-mutated API assertions
# read, and passes EVERY OTHER HOST through to the real curl, live and unchanged.
#
# THE DEPENDENCY BOUNDARY, stated here because it is what makes this still a proof:
#   fixture-fed during mutant runs   00b (and the HAVE_NET / api-transport branch), 03a, 03b,
#                                    10a, 10b, 10c, 10d, 11c  — eight labels, all of them reading
#                                    api.github.com JSON, none of them touched by either mutation.
#   still live during mutant runs    06a-06e (raw.githubusercontent.com at the pinned tag),
#                                    11a and 11b (the gitleaks-action README at its pinned commit,
#                                    whose sha256 11b asserts), section 04's release artefacts
#                                    (github.com downloads, cached under $TH_DIR), 12a
#                                    (static.rust-lang.org), section 09's git clone, and ALL OF
#                                    SECTION 08 — which is the section both mutations target and
#                                    the only section this harness's verdict depends on.
# Freezing an assertion the mutation does not target cannot manufacture the result being proved:
# the proof is that the mutated labels FAIL and every other label does not, and a label served from
# a fixture can still fail — the shim refuses an unrecorded endpoint with exit 22 rather than
# inventing a body, and a fixture whose content stopped satisfying its assertion would fail it.
# What freezing removes is a source of failure that has nothing to do with the mutation.
#
# The live api.github.com anonymous budget is read and PRINTED at the start and at the end of every
# run, from the real curl, so a reader can see that the two mutant runs moved it by nothing.
# `/rate_limit` is not itself metered against the core budget, so those two reads are free.
#
# mutations-r9.sh, run-checks-r8.sh and every existing log are left byte-identical; they remain
# revisions 8 and 9's records.
#
# WHAT IT MUTATES — unchanged from revisions 8 and 9, and it is the point of the file. It mutates a
# COPY of run-checks-r8.sh under $TMPDIR, runs the copy, and prints that run's section-08 RESULT
# lines, its SKIPs by name and its closing summary. run-checks-r8.sh itself is never written to.
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
# Each mutant's FAILing labels are collected from its own output and compared AS A SET against the
# labels the mutation was built to break, so a mutation must break its targets and nothing else.
#
# Declared environment:
#   PY_REPO / TS_REPO / GH_TOKEN  passed straight through to the mutant; absent -> it SKIPs by name.
#   HOME                          replaced here by an empty scratch directory before anything is
#                                 resolved, as run-checks-r8.sh does; the mutant then replaces it
#                                 again with its own.
#   PATH                          the caller's, with $WORK/bin prepended for the MUTANT only.
#   /usr/bin/grep                 by absolute path, named beside every count.
# The mutant runs from $TMPDIR, so it is outside the repository: it is given DEC_NOW and REV2_FILE
# explicitly (the script supports both), and its 13q SKIPs by name for want of a .git directory.
# Every SKIP the mutant prints is reproduced here BY NAME rather than left as a count.
#
# Usage: bash mutations-r11.sh   (exit 0 = every mutation failed exactly the assertions it targeted)

set -u
set -o pipefail

GREP=/usr/bin/grep
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/run-checks-r8.sh"
SHIM_SRC="$SCRIPT_DIR/mutations-r11-curl-shim.sh"
FIXDIR="$SCRIPT_DIR/fixtures-r11"
RUN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/r17-mutate-r11.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

UA='User-Agent: rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'

# --- the caller's HOME is recorded and then replaced, before anything is resolved ---------------
CALLER_HOME="${HOME:-unset}"
CALLER_PATH="$PATH"
mkdir -p "$WORK/home" "$WORK/bin"
export HOME="$WORK/home"
unset XDG_CACHE_HOME XDG_CONFIG_HOME 2>/dev/null || true

# --- python3 and curl resolved by probe, not by PATH order (revision 9's F3 repair, kept) --------
tool_ok() { # tool_ok <path> <tool name>
  case "$2" in
    python3) [ "$("$1" -c 'print(7*6)' 2>/dev/null)" = 42 ] ;;
    curl)    "$1" --version >/dev/null 2>&1 ;;
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
REAL_CURL=$(resolve_tool curl || true)

echo "harness: $0"
echo "caller HOME (recorded, NOT used): $CALLER_HOME"
echo "HOME used by this harness: $HOME"
echo "counting binary for every count below: $GREP ($("$GREP" --version 2>/dev/null | head -1))"
echo "python3 and curl resolved by probing each candidate under the empty HOME above, not by PATH order:"
echo "   python3 used by this harness: ${PY3:-none}"
if [ -n "$PY3" ]; then printf '   its own version string: %s\n' "$("$PY3" --version 2>&1)"; fi
echo "   real curl used by this harness and by every non-api.github.com request below: ${REAL_CURL:-none}"
if [ -n "$REAL_CURL" ]; then printf '   its own version string: %s\n' "$("$REAL_CURL" --version 2>&1 | head -1)"; fi
report_bypass() { # report_bypass <name> <resolved path>
  local first; first=$(command -v "$1" 2>/dev/null || echo none)
  if [ "$first" != none ] && [ "$first" != "${2:-}" ]; then
    echo "   $1 first on PATH was BYPASSED: $first (it failed this harness's probe for $1 under the empty HOME in force)"
  else
    echo "   $1 first on PATH was NOT bypassed: $first passed the probe and is the binary above"
  fi
}
report_bypass python3 "$PY3"; report_bypass curl "$REAL_CURL"
echo "other helpers this harness calls, by the path the shell resolves, unprobed and named:"
printf '   shasum=%s cut=%s sed=%s sort=%s tr=%s head=%s\n' \
  "$(command -v shasum || echo none)" "$(command -v cut || echo none)" \
  "$(command -v sed || echo none)" "$(command -v sort || echo none)" \
  "$(command -v tr || echo none)" "$(command -v head || echo none)"

if [ -z "$PY3" ] || [ ! -s "$SRC" ] || [ ! -s "$SHIM_SRC" ]; then
  echo "cannot run: python3=${PY3:-none} source=$SRC shim=$SHIM_SRC"
  exit 2
fi

# --- the live anonymous budget, read before and after, from the REAL curl -----------------------
# /rate_limit is not metered against the core budget, so reading it costs nothing. The two mutant
# runs below make no api.github.com request at all, so this figure must not move because of them.
anon_core() { # anon_core -> "<limit> <remaining>" or "unavailable"
  local out
  [ -n "$REAL_CURL" ] || { echo unavailable; return; }
  "$REAL_CURL" -sS --max-time 30 -H "$UA" https://api.github.com/rate_limit -o "$WORK/rl-probe.json" 2>/dev/null || true
  [ -s "$WORK/rl-probe.json" ] || { echo unavailable; return; }
  out=$("$PY3" -c 'import json,sys;c=json.load(open(sys.argv[1]))["resources"]["core"];print(c["limit"],c["remaining"])' "$WORK/rl-probe.json" 2>/dev/null) || out=unavailable
  printf '%s\n' "$out"
}
BUDGET_BEFORE=$(anon_core)
echo "live anonymous api.github.com core budget BEFORE the mutant runs (limit remaining): $BUDGET_BEFORE"
echo "   read from the real curl above; /rate_limit is not metered against the core budget."

# --- install the fixture shim as the mutant's `curl` --------------------------------------------
cp "$SHIM_SRC" "$WORK/bin/curl"
chmod +x "$WORK/bin/curl"
echo "api.github.com fixture shim installed for the MUTANT runs only:"
echo "   source: $SHIM_SRC (sha256 $(shasum -a 256 < "$SHIM_SRC" | cut -d' ' -f1))"
echo "   placed at: $WORK/bin/curl, and \$WORK/bin is prepended to the mutant's PATH"
echo "   the mutant's own section-00 line will name it as the curl it resolved"
echo "   recorded responses, by endpoint and digest (the committed manifest is fixtures-r11/MANIFEST.txt):"
for f in "$FIXDIR"/*.json; do
  [ -s "$f" ] || { echo "   MISSING FIXTURE: $f"; exit 2; }
  printf '      %s  %s\n' "$(shasum -a 256 < "$f" | cut -d' ' -f1)" "$(basename "$f")"
done
echo "   FIXTURE-FED during the mutant runs: 00b, 03a, 03b, 10a, 10b, 10c, 10d, 11c"
echo "   STILL LIVE during the mutant runs:  06a-06e and 11a/11b (raw.githubusercontent.com at the"
echo "                                       pinned tag/commit, 11b asserting the README's sha256),"
echo "                                       section 04's release artefacts, 12a, section 09's clone,"
echo "                                       and the whole of section 08 — the section both mutations"
echo "                                       target and the only one this harness's verdict rests on."

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
  PATH="$WORK/bin:$CALLER_PATH" R11_REAL_CURL="$REAL_CURL" R11_FIXTURE_DIR="$FIXDIR" \
    DEC_NOW="$RUN_DIR/DECISION.md" REV2_FILE="$SCRIPT_DIR/rev2-DECISION.md" bash "$out" > "$log" 2>&1
  rc=$?
  echo "-- mutant exit status: $rc"
  echo "-- the curl the mutant resolved, from its own section-00 output:"
  { "$GREP" -E '^   python3=|^mutations-r11 api.github.com fixture shim' "$log" || true; } | sed 's/^/   /'
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
  local explist gotlist
  explist=$(printf '%s' "$expected" | tr ' ' '\n' | "$GREP" -v '^$' | sort | tr '\n' ' ')
  gotlist=$({ "$GREP" -oE '^RESULT [A-Za-z0-9-]+: FAIL' "$log" || true; } | sed -E 's/^RESULT //; s/: FAIL$//' | sort | tr '\n' ' ')
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

BUDGET_AFTER=$(anon_core)
printf '\nlive anonymous api.github.com core budget AFTER the mutant runs (limit remaining): %s\n' "$BUDGET_AFTER"
echo "   BEFORE was: $BUDGET_BEFORE"
if [ "$BUDGET_BEFORE" = "$BUDGET_AFTER" ]; then
  echo "   The two mutant runs moved the anonymous core budget by NOTHING, which is the point of the"
  echo "   fixture shim: round 10's F1 was that this harness's result depended on that budget."
else
  echo "   The figures differ. This harness makes no api.github.com core request, so a difference is"
  echo "   another process on this host or IP, or the hourly reset — it is reported, not explained away."
fi

printf '\nmutation-harness failures: %d\n' "$MUT_FAILS"
if [ "$MUT_FAILS" -eq 0 ]; then
  echo "RESULT: PASS (every mutated assertion failed, the failing set was exactly the targeted one, and every mutated run exited non-zero)"
  exit 0
fi
echo "RESULT: FAIL (a mutation did not break exactly the assertions it targeted, or a mutated run exited 0)"
exit 1
