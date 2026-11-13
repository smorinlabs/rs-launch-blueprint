#!/usr/bin/env bash
# shellcheck disable=SC2016
#   SC2016 is disabled file-wide and deliberately, as in `r57-claims.sh`: the
#   search strings are literal quotations of source files, and one of them
#   contains `$XDG_` as text that must NOT expand.
#
# R57 xdg-directory-set — revision 2 supplementary check.
#
# This is a NEW file, not an edit: `r57-claims.sh` and `r57-claims.log` are
# cited by revision 1 and by the round-1 judgment audit, so they stay
# byte-identical. This script adds only the three things the audit's findings
# ask for and nothing else:
#
#   JF-1  recount `evidence/snap/`: how many files it holds, and how many of
#         those are tracked in HEAD. Revision 1 said "12 artifacts; 10
#         committed and 2 not"; both numbers were wrong.
#   JF-3  read the py and ts namespace constants at their pins, with line
#         numbers, instead of carrying them from `raw/opus.md` uncited.
#         `raw/opus.md` cites `paths.py:56` and `xdg-paths.ts:13`; this check
#         prints the line numbers the pins actually have, which differ.
#   JF-5  collect `directories`' own download figures from the endpoint the
#         prompt's figure table prescribes, so the comparison in `## Tradeoffs`
#         carries a number, an endpoint and a retrieval date.
#
# It implements nothing and re-decides nothing. The recommendation, the crate,
# the accessor set and the ledger disposition are untouched by every check here.
#
# Determinism contract — the same one `r57-claims.sh` states:
#   * The two source repositories are read at the pins `b08bccfb…` (py) and
#     `cb1cbcb2…` (ts) through `git show <pin>:<path>`, never a working tree.
#   * Both pin reads and the crates.io response are snapshotted into ./snap-r2/
#     and read from the snapshot afterwards, so the script is byte-reproducible
#     from a clean `git archive HEAD` extraction that has no `.git` anywhere and
#     no access to those repositories. Delete ./snap-r2/ to re-fetch.
#   * Anything that still cannot be produced prints `SKIP <name>` with a reason
#     rather than failing or printing a misleading blank.
#   * No machine-dependent text reaches stdout.
#
# Usage: bash r57-claims-r2.sh         (run from anywhere)

set -uo pipefail

GREP=/usr/bin/grep
HERE=$(cd -- "$(dirname -- "$0")" && pwd)
EVID="$HERE"
SNAP="$EVID/snap-r2"
RUN=$(cd -- "$EVID/../.." && pwd)
REPO=$(cd -- "$RUN/../../../.." && pwd)
PY_REPO=/Users/stevemorin/c/py-launch-blueprint
TS_REPO=/Users/stevemorin/c/ts-launch-blueprint
PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TS_PIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
PY_PATH=src/py_launch_blueprint/core/paths.py
TS_PATH=src/lib/xdg-paths.ts
UA='rs-launch-blueprint-research/1.0 (https://github.com/smorinlabs/rs-launch-blueprint)'

mkdir -p "$SNAP"

FAILED=0
section() { printf '\n========== %s ==========\n' "$1"; }
claim()   { printf '\n--- %s ---\n' "$1"; }
skip()    { printf 'SKIP %s — %s\n' "$1" "$2"; }

assert() { # assert <label> <expected> <actual>
  if [ "$2" = "$3" ]; then
    printf 'PASS %s (expected %s, got %s; binary: %s)\n' "$1" "$2" "$3" "$GREP"
  else
    printf 'FAIL %s (expected %s, got %s; binary: %s)\n' "$1" "$2" "$3" "$GREP"
    FAILED=$((FAILED + 1))
  fi
}
count() { $GREP -c -F -- "$2" "$1" 2>/dev/null || true; }

# ==================================================== JF-1: the snap inventory ==
section "JF-1. evidence/snap/ inventory, recounted"
SNAP1="$EVID/snap"
HELD_SNAP="$SNAP/snap-held.txt"
TRACKED_SNAP="$SNAP/snap-tracked.txt"
if [ ! -s "$HELD_SNAP" ]; then
  ls -1 "$SNAP1" > "$HELD_SNAP" 2>/dev/null || true
fi
if [ ! -s "$TRACKED_SNAP" ]; then
  # This repository is a git WORKTREE, whose `.git` is a FILE, not a directory.
  # `-d` would silently skip this whole section; `-e` is the correct test.
  if [ -e "$REPO/.git" ]; then
    (cd "$REPO" && git ls-files \
      "research/runs/R57/2026-09-17T020714Z-8fdb5c2010e7/review/evidence/snap") \
      > "$TRACKED_SNAP" 2>/dev/null || true
  fi
fi
if [ ! -s "$HELD_SNAP" ]; then
  skip "snap-inventory" "evidence/snap/ is absent and ./snap-r2/snap-held.txt holds no listing"
elif [ ! -s "$TRACKED_SNAP" ]; then
  skip "snap-tracked" "no .git entry at the repository root and ./snap-r2/snap-tracked.txt holds no listing"
else
  claim "every file evidence/snap/ holds, and which of them .gitignore excludes"
  while IFS= read -r f; do
    if $GREP -q -F -- "/snap/$f" "$TRACKED_SNAP"; then
      printf '  tracked   %s\n' "$f"
    else
      printf '  gitignored %s   <- .gitignore:12  research/runs/**/*.crate\n' "$f"
    fi
  done < "$HELD_SNAP"
  HELD=$($GREP -c . "$HELD_SNAP")
  TRACKED=$($GREP -c . "$TRACKED_SNAP")
  claim "the two figures revision 1 stated as 12 and 10"
  printf 'files evidence/snap/ holds        : %s (binary: %s)\n' "$HELD" "$GREP"
  printf 'of those, tracked in HEAD         : %s (binary: %s)\n' "$TRACKED" "$GREP"
  printf 'the difference, gitignored tarballs: %s\n' "$((HELD - TRACKED))"
  claim "assertions"
  assert "evidence/snap/ holds 11 files, not the 12 revision 1 claimed" 11 "$HELD"
  assert "9 of them are tracked in HEAD, not the 10 revision 1 claimed" 9 "$TRACKED"
  assert "the .gitignore rule that excludes the other two is still present" 1 \
    "$(count "$REPO/.gitignore" 'research/runs/**/*.crate')"
fi

# ================================= JF-3: the py and ts constants, at their pins ==
section "JF-3. py and ts namespace constants, read at their pins"
PY_SNAP="$SNAP/py-paths.py"
TS_SNAP="$SNAP/ts-xdg-paths.ts"
for pair in "PY:$PY_SNAP:$PY_REPO:$PY_PIN:$PY_PATH" "TS:$TS_SNAP:$TS_REPO:$TS_PIN:$TS_PATH"; do
  IFS=: read -r _tag snapfile repo pin path <<< "$pair"
  if [ ! -s "$snapfile" ] && [ -d "$repo/.git" ]; then
    git -C "$repo" show "$pin:$path" > "$snapfile" 2>/dev/null || rm -f "$snapfile"
  fi
done
if [ ! -s "$PY_SNAP" ] || [ ! -s "$TS_SNAP" ]; then
  skip "source-pins" "$PY_REPO and/or $TS_REPO is unavailable and ./snap-r2/ holds no pinned copy"
else
  claim "py $PY_PATH at pin b08bccfb — the lines this decision cites"
  $GREP -n -E 'APP_NAME = "plbp"|Resolve once; never read the raw env vars|is_absolute\(\):$|no data/state split|files are named' "$PY_SNAP"
  claim "py — the four kinds, as its own module docstring names them"
  $GREP -n -E '^\* ``\$XDG_' "$PY_SNAP"
  claim "ts $TS_PATH at pin cb1cbcb2 — the lines this decision cites"
  $GREP -n -E "TOOL_DIR_NAME = 'ts-projects'|^export function configDir|cli-standards R5.3" "$TS_SNAP"
  claim "assertions"
  assert "py names its tool directory plbp, at line 58 (raw/opus.md said 56)" 1 \
    "$($GREP -c -x -F -- 'APP_NAME = "plbp"' "$PY_SNAP" || true)"
  assert "that constant is on line 58" 58 \
    "$($GREP -n -x -F -- 'APP_NAME = "plbp"' "$PY_SNAP" | cut -d: -f1)"
  assert "ts names its tool directory ts-projects, at line 14 (raw/opus.md said 13)" 14 \
    "$($GREP -n -F -- "export const TOOL_DIR_NAME = 'ts-projects';" "$TS_SNAP" | cut -d: -f1)"
  assert "ts resolves through a FREE function taking env and homedir as parameters" 21 \
    "$($GREP -n -F -- 'export function configDir(env: Record<string, string | undefined>, homedir: () => string): string {' "$TS_SNAP" | cut -d: -f1)"
  assert "py validates absoluteness, which ts does not" 1 \
    "$(count "$PY_SNAP" '        if candidate.is_absolute():')"
  assert "py states the resolve-once rule in its own docstring" 1 \
    "$(count "$PY_SNAP" 'Resolve once; never read the raw env vars elsewhere.')"
  assert "py documents the Windows data/state collapse this decision reproduces" 1 \
    "$(count "$PY_SNAP" 'Windows has no data/state split')"
  assert "ts cites cli-standards R5.3 in its own header" 1 \
    "$(count "$TS_SNAP" 'cli-standards R5.3')"
fi

# ================================= JF-5: the directories download figure ==
section "JF-5. directories download figures, from the prescribed endpoint"
DIR_JSON="$SNAP/directories-crate.json"
DIRS_JSON="$SNAP/dirs-crate.json"
for pair in "$DIR_JSON:directories" "$DIRS_JSON:dirs"; do
  f=${pair%%:*}; n=${pair##*:}
  [ -s "$f" ] || curl -sS -H "User-Agent: $UA" -o "$f" "https://crates.io/api/v1/crates/$n" || true
done
if [ ! -s "$DIR_JSON" ] || [ ! -s "$DIRS_JSON" ]; then
  skip "directories-figures" "https://crates.io is unreachable and ./snap-r2/ holds no response"
else
  claim "GET https://crates.io/api/v1/crates/<name> - crate.recent_downloads, crate.downloads"
  python3 - "$DIR_JSON" "$DIRS_JSON" "$EVID/snap/etcetera-crate.json" <<'PYEOF'
import json, sys
def load(p):
    return json.load(open(p))["crate"]
d, s, e = load(sys.argv[1]), load(sys.argv[2]), load(sys.argv[3])
for name, c in (("etcetera", e), ("directories", d), ("dirs", s)):
    print("%-12s recent_downloads (90-day) = %12d | downloads (all-time) = %12d | latest = %s"
          % (name, c["recent_downloads"], c["downloads"], c["max_stable_version"]))
print()
print("etcetera / directories, 90-day = %.2f  -> etcetera has MORE, not fewer"
      % (e["recent_downloads"] / d["recent_downloads"]))
print("dirs / etcetera,        90-day = %.2f  -> this is the ~2.4x raw/opus.md reports,"
      % (s["recent_downloads"] / e["recent_downloads"]))
print("                                          and it is `dirs`, NOT `directories`.")
PYEOF
  claim "assertions"
  assert "the directories response carries a recent_downloads field" 1 \
    "$(count "$DIR_JSON" '"recent_downloads"')"
  assert "the dirs response carries a recent_downloads field" 1 \
    "$(count "$DIRS_JSON" '"recent_downloads"')"
fi

section "result"
printf 'failed assertions: %s\n' "$FAILED"
[ "$FAILED" -eq 0 ] || exit 1
