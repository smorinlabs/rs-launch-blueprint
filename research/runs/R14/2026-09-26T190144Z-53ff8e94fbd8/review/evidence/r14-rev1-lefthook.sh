#!/bin/sh
# r14-rev1-lefthook.sh - end-to-end two-tier contract through lefthook:
# hook rejects, --no-verify bypasses, CI range mode catches. Exit 0 iff all pass.
# Usage: sh r14-rev1-lefthook.sh
set -eu
EV=$(cd "$(dirname "$0")" && pwd)
GUARD="$EV/check-large-files.sh"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
SCRATCH=${TMPDIR:-/tmp}/r14-rev1-lefthook
rm -rf "$SCRATCH"; mkdir -p "$SCRATCH/r"
git -C "$SCRATCH/r" init -q -b main
git -C "$SCRATCH/r" config user.email t@t; git -C "$SCRATCH/r" config user.name t
git -C "$SCRATCH/r" commit -q --allow-empty -m init
fail=0
chk() { if [ "$2" = "$3" ]; then echo "$1 PASS expected=$2 got=$3 $4"; else echo "$1 FAIL expected=$2 got=$3 $4"; fail=1; fi; }
printf 'pre-commit:\n  jobs:\n    - name: large-files\n      run: sh %s --staged\n' "$GUARD" > "$SCRATCH/r/lefthook.yml"
git -C "$SCRATCH/r" add lefthook.yml; git -C "$SCRATCH/r" commit -qm hooks
base=$(git -C "$SCRATCH/r" rev-parse HEAD)
head -c 2097152 /dev/zero > "$SCRATCH/r/blob.bin"
git -C "$SCRATCH/r" add blob.bin

# L1: the hook rejects the commit and HEAD does not move.
set +e; (cd "$SCRATCH/r" && lefthook run pre-commit >/dev/null 2>&1); c=$?; set -e
chk L1a 1 "$c" "lefthook run rejects"
[ "$(git -C "$SCRATCH/r" rev-parse HEAD)" = "$base" ] && r=0 || r=1
chk L1b 0 "$r" "HEAD unchanged"

# L2: --no-verify commits it anyway.
set +e; (cd "$SCRATCH/r" && git commit -qm bypass --no-verify >/dev/null 2>&1); c=$?; set -e
chk L2 0 "$c" "--no-verify bypasses locally"

# L3: the CI-tier range check catches the bypassed commit.
set +e; (cd "$SCRATCH/r" && sh "$GUARD" --range "$base" HEAD >/dev/null 2>&1); c=$?; set -e
chk L3 1 "$c" "range mode catches bypass"

echo "lefthook failures: $fail"
exit "$fail"
