#!/usr/bin/env bash
# R49 revision 6 — which `grep` produced this item's line lists, and whether the
# two reachable implementations agree on them.
#
# WHY THIS EXISTS. Revision 5 asserted that `grep` on this machine's PATH is
# `ugrep 7.8.4`. That is false and the round-5 audit rejected it. The true
# situation:
#
#   * /usr/bin/grep -- the PATH binary -- is BSD grep 2.6.0-FreeBSD.
#   * In a Claude Code zsh session, a typed `grep` resolves FIRST to a shell
#     FUNCTION defined in that session's shell snapshot
#     (~/.claude/shell-snapshots/snapshot-zsh-*.sh). The function runs an ugrep
#     7.8.4 embedded inside the `claude` executable, adding -G --ignore-files
#     --hidden -I --exclude-dir=.git and friends.
#   * `ugrep` is not on PATH under its own name, and a `bash <script>` invocation
#     never sees the zsh function, so a script always gets /usr/bin/grep.
#
# So the divergence is not between machines; it is between a typed shell command
# and a script. An auditor's sandbox, CI, or a git-archive extraction has no
# snapshot at all and therefore only ever sees /usr/bin/grep.
#
# THIS LOG IS DELIBERATELY ENVIRONMENT-DEPENDENT and is the one artifact of this
# item that is NOT expected to reproduce byte-for-byte everywhere. What varies is
# exactly: the `retrieved:` timestamp; the `second implementation:` block, which
# is two lines when the embedded ugrep is reachable and one line when it is not;
# and every line marked `[2/2]`, together with the two `ASSERT` lines that run
# only inside a `[2/2]` branch. Everything marked `[1/1]`, and every other
# `ASSERT` line, is produced by /usr/bin/grep alone and must be identical
# everywhere. Compare across environments by dropping `retrieved:`, the
# `second implementation:` block and every `[2/2]`-guarded line; the remainder
# must match exactly, and the run must still exit 0.
#
# Assertions are on content. Any failure exits non-zero. A SKIP is printed as a
# SKIP and never counted as a pass.

set -o pipefail
set -u

REPO="$(git rev-parse --show-toplevel)" || exit 1
DEC="research/runs/R49/2026-09-05T155504Z-2107cffb3ecf/review/DECISION.md"
REV2_COMMIT="2ac02e1"
REV4_COMMIT="ddbee6a"
REV2_SHA="1b5a6b99ecedb88f7358d16a4567aa9b56838a2102e9e4feda99d00bc787513f"
REV4_SHA="7f088e512f1393896c043274a9f05f9ff65639433b23cd6b0e6b1b35b416fcc7"

GREP=/usr/bin/grep
GREP_VERSION_EXPECTED='grep (BSD grep, GNU compatible) 2.6.0-FreeBSD'

PAT_OLD='copyleft|agpl|[^a-z]gpl|mpl|mozilla|patent|permissive'
PAT_ID='copyleft|AGPL|LGPL|GPL|MPL|Mozilla|PERMISSIVE|permissive|patent'

TMP="$(mktemp -d)" || exit 1
trap 'rm -rf "$TMP"' EXIT

fail=0
assert_eq() { # label expected actual
  if [ "$2" = "$3" ]; then
    printf 'ASSERT ok   %s\n' "$1"
  else
    printf 'ASSERT FAIL %s\n  expected: %s\n  actual:   %s\n' "$1" "$2" "$3"
    fail=1
  fi
}

# Reach the embedded ugrep the way the shell snapshot's function does, but
# explicitly, so it is named rather than typed into existence.
UG_BIN=""
for cand in "${CLAUDE_CODE_EXECPATH:-}" "$HOME/.local/bin/claude"; do
  [ -n "$cand" ] && [ -x "$cand" ] && { UG_BIN="$cand"; break; }
done
ug() { # run the embedded ugrep with the snapshot function's own flags
  ( exec -a ugrep "$UG_BIN" -G --ignore-files --hidden -I \
      --exclude-dir=.git --exclude-dir=.svn --exclude-dir=.hg \
      --exclude-dir=.bzr --exclude-dir=.jj --exclude-dir=.sl "$@" )
}

printf 'retrieved: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'repo: %s\n' "$REPO"
echo

echo '## which programs are reachable here'
grep_version="$("$GREP" --version 2>&1 | head -1)"
printf 'PATH binary:           %s\n' "$GREP"
printf '  its --version:       %s\n' "$grep_version"
printf 'bare `grep` under this script interpreter (bash): %s\n' "$(command -v grep)"
if [ -n "$UG_BIN" ]; then
  ug_version="$(ug --version 2>&1 | head -1)"
  printf 'second implementation: embedded in %s\n' "$UG_BIN"
  printf '  its --version:       %s\n' "$ug_version"
else
  printf 'second implementation: absent in this environment\n'
fi
assert_eq "the PATH grep is the binary this item's lists name" \
  "$GREP_VERSION_EXPECTED" "$grep_version"

echo
echo '## the blobs under test'
git -C "$REPO" show "$REV2_COMMIT:$DEC" > "$TMP/rev2.md" || { echo "git show rev2 failed"; exit 1; }
git -C "$REPO" show "$REV4_COMMIT:$DEC" > "$TMP/rev4.md" || { echo "git show rev4 failed"; exit 1; }
assert_eq "revision-2 blob sha256" "$REV2_SHA" "$(shasum -a 256 "$TMP/rev2.md" | cut -d' ' -f1)"
assert_eq "revision-4 blob sha256" "$REV4_SHA" "$(shasum -a 256 "$TMP/rev4.md" | cut -d' ' -f1)"

# one comparison: assert the /usr/bin/grep result, then compare the other
# implementation against it when that implementation exists.
compare() { # label  expected-list  file  grep-args...
  local label="$1" expect="$2" f="$3"; shift 3
  local b u
  b="$("$GREP" "$@" "$f" | cut -d: -f1 | tr '\n' ' ' | sed 's/ $//')"
  printf '[1/1] %s\n      /usr/bin/grep -> %s\n' "$label" "$b"
  assert_eq "$label (/usr/bin/grep)" "$expect" "$b"
  if [ -n "$UG_BIN" ]; then
    u="$(ug "$@" "$f" | cut -d: -f1 | tr '\n' ' ' | sed 's/ $//')"
    if [ "$u" = "$b" ]; then
      printf '[2/2] %s -> SAME under the embedded ugrep\n' "$label"
    else
      printf '[2/2] %s -> DIFFERS under the embedded ugrep\n      ugrep -> %s\n' "$label" "$u"
      fail=1
    fi
  else
    printf '[2/2] %s -> SKIP (second implementation absent; nothing compared)\n' "$label"
  fi
}

echo
echo '## the same patterns under both implementations'
compare "revision-2, recorded revision-3 pattern" \
  "8 29 30 32 36 37 61 90 94 110 132 150 162 167 182 191 197 204 231 243 264 273 278 290 297 301 338 354 363 413 456 516 607 610 616 652 665 680 716 730" \
  "$TMP/rev2.md" -niE "$PAT_OLD"
compare "revision-2, corrected word-bounded pattern" \
  "182 363 607 610 616" "$TMP/rev2.md" -nwE "$PAT_ID"
compare "revision-4, corrected word-bounded pattern" \
  "12 29 70 92 298 489 733 736 745 794" "$TMP/rev4.md" -nwE "$PAT_ID"
compare "revision-4, licen" \
  "8 9 11 24 29 30 39 63 67 70 72 85 87 102 104 156 260 264 294 308 374 437 464 468 488 490 559 723 726 729 741 744 794" \
  "$TMP/rev4.md" -ni 'licen'

echo
echo '## where the two implementations genuinely disagree'
# The embedded ugrep is invoked with --ignore-files, so a RECURSIVE search
# silently omits ignore-listed files while /usr/bin/grep does not. Explicitly
# named files (including a shell-expanded glob) are unaffected: both read them.
# This is the failure mode this item was rejected for three times, so it is
# demonstrated rather than asserted in prose.
DEMO="$TMP/demo"
mkdir -p "$DEMO/ignored"
printf 'ignored/\n' > "$DEMO/.gitignore"
printf 'GPL-3.0-only\n' > "$DEMO/ignored/licence.md"
printf 'GPL-3.0-only\n' > "$DEMO/visible.md"
b_rec="$("$GREP" -rl 'GPL-3.0-only' "$DEMO" | sed "s|$DEMO/||" | sort | tr '\n' ' ' | sed 's/ $//')"
printf '[1/1] recursive search, /usr/bin/grep -> %s\n' "$b_rec"
assert_eq "recursive: /usr/bin/grep reads the ignore-listed file" \
  "ignored/licence.md visible.md" "$b_rec"
if [ -n "$UG_BIN" ]; then
  u_rec="$(ug -rl 'GPL-3.0-only' "$DEMO" | sed "s|$DEMO/||" | sort | tr '\n' ' ' | sed 's/ $//')"
  printf '[2/2] recursive search, embedded ugrep -> %s\n' "$u_rec"
  assert_eq "recursive: the embedded ugrep omits the ignore-listed file" \
    "visible.md" "$u_rec"
  b_named="$("$GREP" -l 'GPL-3.0-only' "$DEMO/ignored/licence.md" | sed "s|$DEMO/||")"
  u_named="$(ug -l 'GPL-3.0-only' "$DEMO/ignored/licence.md" | sed "s|$DEMO/||")"
  printf '[2/2] explicitly named ignore-listed file: /usr/bin/grep -> %s ; ugrep -> %s\n' \
    "$b_named" "$u_named"
  assert_eq "explicitly named files are read by both" "$b_named" "$u_named"
else
  printf '[2/2] recursive divergence -> SKIP (second implementation absent)\n'
fi

echo
if [ "$fail" -eq 0 ]; then
  echo 'RESULT: all assertions passed'
else
  echo 'RESULT: one or more assertions FAILED'
fi
exit "$fail"
