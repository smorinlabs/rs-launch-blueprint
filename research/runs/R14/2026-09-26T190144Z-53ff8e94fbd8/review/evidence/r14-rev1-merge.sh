#!/bin/sh
# r14-rev1-merge.sh - an add-then-delete blob survives a merge commit and the
# guard's range mode sees it. Exit 0 iff all pass.
# Usage: sh r14-rev1-merge.sh
set -eu
EV=$(cd "$(dirname "$0")" && pwd)
GUARD="$EV/check-large-files.sh"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
SCRATCH=${TMPDIR:-/tmp}/r14-rev1-merge
rm -rf "$SCRATCH"; mkdir -p "$SCRATCH/r"
git -C "$SCRATCH/r" init -q -b main
git -C "$SCRATCH/r" config user.email t@t; git -C "$SCRATCH/r" config user.name t
git -C "$SCRATCH/r" commit -q --allow-empty -m init
fail=0
chk() { if [ "$2" = "$3" ]; then echo "$1 PASS expected=$2 got=$3 $4"; else echo "$1 FAIL expected=$2 got=$3 $4"; fail=1; fi; }

git -C "$SCRATCH/r" checkout -q -b feature
head -c 2097152 /dev/zero > "$SCRATCH/r/temp.bin"
git -C "$SCRATCH/r" add temp.bin; git -C "$SCRATCH/r" commit -qm add
blob=$(git -C "$SCRATCH/r" rev-parse HEAD:temp.bin)
git -C "$SCRATCH/r" rm -q temp.bin; git -C "$SCRATCH/r" commit -qm del
base=$(git -C "$SCRATCH/r" rev-parse main)

# M1a: blob unreachable from main before the merge.
git -C "$SCRATCH/r" merge-base --is-ancestor "$blob" main 2>/dev/null && r=1 || r=0
chk M1a 0 "$r" "blob unreachable from pre-merge main"
# M1b: after merge --no-ff the blob is reachable from main ...
git -C "$SCRATCH/r" checkout -q main
git -C "$SCRATCH/r" merge -q --no-ff feature -m merge
git -C "$SCRATCH/r" cat-file -e "$blob^{}" 2>/dev/null
git -C "$SCRATCH/r" rev-list --objects main | grep -q "^$blob" && r=1 || r=0
chk M1b 1 "$r" "blob reachable from post-merge main"
# M1c: ... although absent from main's tree.
git -C "$SCRATCH/r" ls-tree -r --name-only main | grep -q temp.bin && r=1 || r=0
chk M1c 0 "$r" "blob absent from main tree"
# M1d: range mode over base..HEAD fails on it.
set +e; (cd "$SCRATCH/r" && sh "$GUARD" --range "$base" HEAD >/dev/null 2>&1); c=$?; set -e
chk M1d 1 "$c" "guard range mode catches the merged blob"

echo "merge failures: $fail"
exit "$fail"
