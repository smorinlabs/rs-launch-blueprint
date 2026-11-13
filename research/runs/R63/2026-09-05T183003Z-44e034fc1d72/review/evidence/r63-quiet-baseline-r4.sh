#!/bin/bash
# R63 progress-spinner — revision 4 supplementary check: the `--quiet`
# suppression clause and the `BASELINE-REVIEW:` line it forces on F283.
#
# WHY THIS IS A SEPARATE FILE. `review/evidence/r63-spinner-claims.sh` and its
# cited log were reproduced by the r3 empirical audit and are NOT edited or
# rerun by revision 4; a new claim gets a new file. This script asserts only the
# facts revision 4 adds:
#   * the binding CLI Design Standard v1.4.14 states the two MUST-level
#     obligations revision 4 cites (R7.4 progress, R4.4 verbosity ladder);
#   * at ts pin cb1cbcb2 the CLI DEFINES `-q, --quiet` (router.ts:131) and
#     routes it to the log level only (router.ts:105), while the spinner gate
#     (projects.ts:128) consults stderr TTY-ness and `CI` alone, and neither
#     projects.ts nor adapters.ts contains the string `quiet` at all;
#   * at py pin b08bccfb the py CLI likewise already defines `-q, --quiet`
#     (options.py:82), which is what the follow-on rationale rests on.
#
# It reads only local files and pinned git blobs. It queries no network
# endpoint and records no host identity, no wall-clock time and no scratch
# path, so unlike the main check its output is byte-for-byte reproducible on
# any host that has the two checkouts at the pins and the standard at v1.4.14.
# There is no VOLATILE/HOST class here and no difference rule: a rerun either
# matches exactly or something it asserts has changed.
#
# Rerun:  bash review/evidence/r63-quiet-baseline-r4.sh \
#           > review/evidence/r63-quiet-baseline-r4.log 2>&1
#         from the run directory
#         research/runs/R63/2026-09-05T183003Z-44e034fc1d72.
# Override the checkouts with TS_REPO / PY_REPO and the standard with STD_FILE.

set -u
set -o pipefail
export LC_ALL=C

TS=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
PY=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TSREPO="${TS_REPO:-$HOME/c/ts-launch-blueprint}"
PYREPO="${PY_REPO:-$HOME/c/py-launch-blueprint}"
STD="${STD_FILE:-$HOME/c/cli-standards/cli-design-standard.md}"

W="${R63_QUIET_WORK:-$(mktemp -d "${TMPDIR:-/tmp}/r63-quiet-r4.XXXXXX")}"
mkdir -p "$W" || exit 1

PASS=0
FAIL=0
PPASS=0
PFAIL=0

hr(){ printf '\n===== %s =====\n' "$1"; }
sub(){ printf -- '--- %s\n' "$1"; }
ok(){  PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
bad(){ FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }

# chk <label> <expected> <actual> — exact string equality.
chk(){ if [ "$2" = "$3" ]; then ok "$1 == $2"; else bad "$1: expected [$2], got [$3]"; fi; }

# blob <label> <repo> <pin:path> <outfile> — read a pinned blob. Git's own
# stderr is discarded so that a failure prints a fixed message rather than a
# machine-specific path; an unreadable checkout, a missing pin and an empty
# blob are all one named FAIL.
blob(){
  if git -C "$2" show "$3" > "$4" 2>/dev/null && [ -s "$4" ]; then
    ok "$1 (read at pin, $(wc -l < "$4" | tr -d ' ') lines)"
  else
    bad "$1: cannot read $3 (checkout missing, pin missing, or empty blob)"
  fi
}

# lineis <label> <file> <lineno> <expected> — assert one numbered line is
# exactly the expected text, and echo the line that was read.
lineis(){
  local got
  if [ ! -r "$2" ]; then bad "$1: file missing or unreadable"; return 1; fi
  got=$(sed -n "${3}p" "$2")
  if [ "$got" = "$4" ]; then
    ok "$1: line $3 is exactly the recorded text"
    printf '      %s\n' "$got"
  else
    bad "$1: line $3 differs"
    printf '      got:      %s\n      expected: %s\n' "$got" "$4"
  fi
}

# has <label> <file> <literal> <expected-count> — assert the number of lines
# matching a literal, and echo them with their line numbers. A count of 0 is
# asserted as a count, never as a grep exit status; a read error (grep exit
# above 1) is a named FAIL rather than a passed absence.
has(){
  local n st
  if [ ! -r "$2" ]; then bad "$1: file missing or unreadable"; return 1; fi
  n=$(grep -cF -- "$3" "$2"); st=$?
  if [ "$st" -gt 1 ]; then bad "$1: grep read error (exit $st)"; return 1; fi
  chk "$1 (matching lines)" "$4" "$n"
  grep -nF -- "$3" "$2" | sed 's/^/      /'
  return 0
}

# probe <helper> <args...> — run an assertion helper in a subshell so its
# tally cannot reach the real one, prefix its output `probe-`, and count the
# verdict. The probes exist so that this check demonstrates its own failure
# path instead of asserting that it has one.
probe(){
  local out first
  out=$("$@" 2>&1)
  printf '%s\n' "$out" | sed 's/^/probe-/'
  first=$(printf '%s\n' "$out" | sed -n '1p')
  case "$first" in
    PASS*) PPASS=$((PPASS+1)) ;;
    FAIL*) PFAIL=$((PFAIL+1)) ;;
    *)     bad "probe produced neither PASS nor FAIL as its first line" ;;
  esac
}

# ============================================================================
hr "0  scope"
printf 'This check reads local files and pinned git blobs only. No network\n'
printf 'endpoint is queried, no host identity, wall-clock time or scratch path\n'
printf 'is recorded, and no Rust code is compiled or run. Its output is\n'
printf 'byte-for-byte reproducible; there is no difference rule.\n'
printf 'ts pin: %s\n' "$TS"
printf 'py pin: %s\n' "$PY"

# ============================================================================
hr "1  the binding standard: CLI Design Standard v1.4.14"
if [ -r "$STD" ]; then
  ok "standard readable"
else
  bad "standard missing or unreadable"
fi
chk "standard sha256" \
  "9fb05d3dfaa5ea11fbf66422e988b0ae8c050e22a39b9fc6dd9688734f02463f" \
  "$(shasum -a 256 "$STD" 2>/dev/null | awk '{print $1}')"
has "standard declares version 1.4.14" "$STD" '| **Version** | 1.4.14 |' 1
sub "R7.4 — the progress sentence revision 4 carries"
has "R7.4 heading" "$STD" '**R7.4 — Pager & progress. (SHOULD)**' 1
has "R7.4 progress obligation" "$STD" \
  'Progress indicators **MUST** go to stderr (R7.1) and **MUST** be suppressed when not a TTY or under `--quiet`.' 1
sub "R4.4 — the same obligation inside a MUST-labelled rule"
has "R4.4 heading" "$STD" '**R4.4 — Verbosity semantics. (MUST)**' 1
has "R4.4 quiet obligation" "$STD" \
  '`--quiet`/`-q` suppresses progress and informational diagnostics on stderr only' 1
sub "scope note: colour and NO_COLOR are out of the standard's scope (R65 owns them)"
has "standard excludes colour/NO_COLOR from its scope" "$STD" \
  'This document does not define color usage, `NO_COLOR`/`FORCE_COLOR`' 1

# ============================================================================
hr "2  ts pin cb1cbcb2: the CLI defines -q, --quiet"
blob "ts src/router.ts" "$TSREPO" "$TS:src/router.ts" "$W/router.ts"
lineis "router.ts defines -q, --quiet" "$W/router.ts" 131 \
  "    .option('-q, --quiet', 'only show warnings and errors', false)"
has "router.ts mentions quiet on exactly three lines" "$W/router.ts" 'quiet' 3
sub "and routes it to the log level, which is the only thing it feeds"
lineis "router.ts feeds quiet to resolveLevel" "$W/router.ts" 105 \
  "    resolveLevel({ verbose: opts.verbose, quiet: opts.quiet, debug: opts.debug }),"

# ============================================================================
hr "3  ts pin cb1cbcb2: the spinner gate does not consult it"
blob "ts src/commands/projects.ts" "$TSREPO" "$TS:src/commands/projects.ts" "$W/projects.ts"
lineis "projects.ts spinner gate" "$W/projects.ts" 128 \
  "  const spinnerEnabled = deps.stderrIsTTY && (ci === undefined || ci === '');"
lineis "projects.ts CI read" "$W/projects.ts" 127 \
  "  const ci = deps.env['CI'];"
has "projects.ts contains no occurrence of quiet" "$W/projects.ts" 'quiet' 0
blob "ts src/lib/adapters.ts" "$TSREPO" "$TS:src/lib/adapters.ts" "$W/adapters.ts"
has "adapters.ts contains no occurrence of quiet" "$W/adapters.ts" 'quiet' 0

# ============================================================================
hr "4  py pin b08bccfb: py already defines -q, --quiet and ships no spinner"
blob "py src/py_launch_blueprint/cli/options.py" "$PYREPO" \
  "$PY:src/py_launch_blueprint/cli/options.py" "$W/options.py"
lineis "options.py defines -q, --quiet" "$W/options.py" 82 \
  '        "-q", "--quiet", is_flag=True, help="Suppress non-essential stderr output."'

# ============================================================================
hr "5  controls — this check can fail"
sub "a numbered line asserted against the wrong text must FAIL"
probe lineis "control: router.ts:131 asserted as the wrong text" "$W/router.ts" 131 \
  "    .option('-q, --quiet', 'this is not what line 131 says', false)"
sub "an absence asserted where the literal is present must FAIL"
probe has "control: quiet asserted absent from router.ts" "$W/router.ts" 'quiet' 0
sub "an unreadable checkout must FAIL, not pass silently"
probe blob "control: blob read from a checkout that does not exist" /nonexistent-repo \
  "$TS:src/router.ts" "$W/control-missing.txt"
sub "and the same helper on a true statement must PASS, so the controls are not"
sub "merely showing that every probe is rejected"
probe has "control: quiet present on three lines of router.ts" "$W/router.ts" 'quiet' 3
chk "probe tally" "1 pass / 3 fail" "$PPASS pass / $PFAIL fail"

# ============================================================================
hr "DONE"
printf 'checks: %d pass / %d fail\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf 'RESULT: FAIL — %d assertion(s) did not hold; the decision text that cites them is stale.\n' "$FAIL"
  rm -rf "$W"
  exit 1
fi
printf 'RESULT: PASS — the standard states both obligations, ts defines -q/--quiet and gates the spinner without it, and py defines -q/--quiet.\n'
rm -rf "$W"
exit 0
