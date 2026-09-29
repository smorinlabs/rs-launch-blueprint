#!/usr/bin/env bash
# R84 revision 1 — rerun evidence scripts from a clean `git archive HEAD`
# extraction and byte-compare each fresh log with the committed one.
# The scripts and fixture are untracked when this is first run, so they are
# copied into the extraction at their own relative path before running.
# Usage: r84-archive-rerun.sh <script-name-without-.sh>...
set -uo pipefail
HERE=$(unset CDPATH; cd -- "$(dirname -- "$0")" && pwd)
REPO=$(cd "$HERE/../../../../../.." && pwd)
REL=research/runs/R84/2026-09-18T215916Z-b7f3ee4b098e/review/evidence
X=$(mktemp -d "${TMPDIR:-/tmp}/r84-archive.XXXXXX")
trap 'rm -rf "$X"' EXIT
git -C "$REPO" archive HEAD | tar -x -C "$X"
mkdir -p "$X/$REL"
cp "$REPO/$REL"/*.sh "$X/$REL/"
cp -R "$REPO/$REL/fixtures" "$X/$REL/"
echo "archive HEAD: $(git -C "$REPO" rev-parse HEAD)"
for s in "$@"; do
  (cd "$X" && "./$REL/$s.sh" > "$X/$REL/$s.log" 2>&1); rc=$?
  if cmp -s "$X/$REL/$s.log" "$REPO/$REL/$s.log"; then
    echo "$s: rc=$rc IDENTICAL"
  else
    echo "$s: rc=$rc DIFFERS"
    diff "$REPO/$REL/$s.log" "$X/$REL/$s.log"
  fi
done
