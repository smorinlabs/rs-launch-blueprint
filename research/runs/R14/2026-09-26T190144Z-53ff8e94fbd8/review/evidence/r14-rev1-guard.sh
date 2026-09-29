#!/bin/sh
# r14-rev1-guard.sh - behavior matrix for review/evidence/check-large-files.sh.
# H-cases run under both /bin/sh (macOS) and /bin/dash (Ubuntu's /bin/sh);
# R-cases run once (shell-independent git logic). Exit 0 iff all pass.
# Usage: sh r14-rev1-guard.sh
set -eu
EV=$(cd "$(dirname "$0")" && pwd)
GUARD="$EV/check-large-files.sh"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
SCRATCH=${TMPDIR:-/tmp}/r14-rev1-guard
rm -rf "$SCRATCH"; mkdir -p "$SCRATCH"
fail=0; n=0
newrepo() { rm -rf "$SCRATCH/r"; mkdir -p "$SCRATCH/r"; git -C "$SCRATCH/r" init -q -b main; git -C "$SCRATCH/r" config user.email t@t; git -C "$SCRATCH/r" config user.name t; }
big() { head -c "$1" /dev/zero > "$SCRATCH/r/$2"; }
chk() { # id expected got note
  n=$((n+1))
  if [ "$2" = "$3" ]; then echo "$1 PASS expected=$2 got=$3 $4"; else echo "$1 FAIL expected=$2 got=$3 $4"; fail=1; fi
}
run_sh() { # shell args... -> prints exit code; stdout+stderr in $SCRATCH/out
  s=$1; shift; set +e; "$s" "$GUARD" "$@" >"$SCRATCH/out" 2>&1; c=$?; set -e; echo "$c"
}

for SH in /bin/sh /bin/dash; do
  tag=$(basename "$SH")
  # H1: nothing staged.
  newrepo; git -C "$SCRATCH/r" commit -q --allow-empty -m init
  c=$(cd "$SCRATCH/r" && run_sh "$SH" --staged); chk "H1[$tag]" 0 "$c" "nothing staged"
  # H2/H3: boundary.
  newrepo; git -C "$SCRATCH/r" commit -q --allow-empty -m init
  big 1048576 edge.bin; git -C "$SCRATCH/r" add edge.bin
  c=$(cd "$SCRATCH/r" && run_sh "$SH" --staged); chk "H2[$tag]" 0 "$c" "1048576 passes"
  big 1048577 edge.bin; git -C "$SCRATCH/r" add edge.bin
  c=$(cd "$SCRATCH/r" && run_sh "$SH" --staged); chk "H3[$tag]" 1 "$c" "1048577 fails"
  # H4: spaced name.
  newrepo; git -C "$SCRATCH/r" commit -q --allow-empty -m init
  big 2097152 "big file.bin"; git -C "$SCRATCH/r" add "big file.bin"
  c=$(cd "$SCRATCH/r" && run_sh "$SH" --staged)
  grep -q 'big file.bin' "$SCRATCH/out" && m=yes || m=no
  chk "H4[$tag]" 1 "$c" "spaced name fails msg-names=$m"
  # H5: modified file grown past threshold.
  newrepo; echo tiny > "$SCRATCH/r/grow.dat"; git -C "$SCRATCH/r" add grow.dat
  git -C "$SCRATCH/r" commit -qm init; big 2097152 grow.dat; git -C "$SCRATCH/r" add grow.dat
  c=$(cd "$SCRATCH/r" && run_sh "$SH" --staged); chk "H5[$tag]" 1 "$c" "modified grown fails"
  # H6: attribute exemption.
  newrepo; git -C "$SCRATCH/r" commit -q --allow-empty -m init
  big 2097152 media.bin; printf 'media.bin large-file-ok\n' > "$SCRATCH/r/.gitattributes"
  git -C "$SCRATCH/r" add .gitattributes media.bin
  c=$(cd "$SCRATCH/r" && run_sh "$SH" --staged)
  grep -q '^ALLOW: media.bin' "$SCRATCH/out" && m=yes || m=no
  chk "H6[$tag]" 0 "$c" "attribute exempt allow-line=$m"
  # H7a/H7b: staged blob, not worktree, is judged.
  newrepo; git -C "$SCRATCH/r" commit -q --allow-empty -m init
  echo small > "$SCRATCH/r/p.bin"; git -C "$SCRATCH/r" add p.bin; big 2097152 p.bin
  c=$(cd "$SCRATCH/r" && run_sh "$SH" --staged); chk "H7a[$tag]" 0 "$c" "staged small worktree big passes"
  newrepo; git -C "$SCRATCH/r" commit -q --allow-empty -m init
  big 2097152 p.bin; git -C "$SCRATCH/r" add p.bin; echo small > "$SCRATCH/r/p.bin"
  c=$(cd "$SCRATCH/r" && run_sh "$SH" --staged); chk "H7b[$tag]" 1 "$c" "staged big worktree small fails"
  # H10: unborn branch, first commit.
  newrepo; big 2097152 first.bin; git -C "$SCRATCH/r" add first.bin
  c=$(cd "$SCRATCH/r" && run_sh "$SH" --staged); chk "H10[$tag]" 1 "$c" "unborn branch fails"
done

# H8: LFS-tracked file stages a pointer blob.
if command -v git-lfs >/dev/null 2>&1; then
  newrepo; git -C "$SCRATCH/r" commit -q --allow-empty -m init
  git -C "$SCRATCH/r" lfs install --local >/dev/null 2>&1 || true
  git -C "$SCRATCH/r" lfs track '*.lfs' >/dev/null 2>&1 || true
  big 2097152 asset.lfs; git -C "$SCRATCH/r" add .gitattributes asset.lfs
  c=$(cd "$SCRATCH/r" && run_sh /bin/sh --staged); chk "H8[sh]" 0 "$c" "LFS pointer passes"
else
  echo "H8 SKIP git-lfs not installed"
fi

# H9: gitlink skipped.
newrepo; git -C "$SCRATCH/r" commit -q --allow-empty -m init
mkdir -p "$SCRATCH/sub"; git -C "$SCRATCH/sub" init -q -b main
git -C "$SCRATCH/sub" config user.email t@t; git -C "$SCRATCH/sub" config user.name t
git -C "$SCRATCH/sub" commit -q --allow-empty -m init
git -C "$SCRATCH/r" -c protocol.file.allow=always submodule -q add "$SCRATCH/sub" vendor/sub >/dev/null 2>&1 || true
c=$(cd "$SCRATCH/r" && run_sh /bin/sh --staged); chk "H9[sh]" 0 "$c" "gitlink skipped"

# R1: blob added then deleted inside the range fails.
newrepo; git -C "$SCRATCH/r" commit -q --allow-empty -m init
base=$(git -C "$SCRATCH/r" rev-parse HEAD)
big 2097152 temp.bin; git -C "$SCRATCH/r" add temp.bin; git -C "$SCRATCH/r" commit -qm add
git -C "$SCRATCH/r" rm -q temp.bin; git -C "$SCRATCH/r" commit -qm del
c=$(cd "$SCRATCH/r" && run_sh /bin/sh --range "$base" HEAD); chk "R1" 1 "$c" "added-then-deleted fails"

# R3/R3e: all-zero and empty base check all history (fail closed).
c=$(cd "$SCRATCH/r" && run_sh /bin/sh --range 0000000000000000000000000000000000000000 HEAD)
chk "R3" 1 "$c" "all-zero base fails closed"
c=$(cd "$SCRATCH/r" && run_sh /bin/sh --range "" HEAD); chk "R3e" 1 "$c" "empty base fails closed"

# R4: modified file grown past threshold fails in range mode.
newrepo; echo tiny > "$SCRATCH/r/g.dat"; git -C "$SCRATCH/r" add g.dat; git -C "$SCRATCH/r" commit -qm init
base=$(git -C "$SCRATCH/r" rev-parse HEAD)
big 2097152 g.dat; git -C "$SCRATCH/r" commit -qam grow
c=$(cd "$SCRATCH/r" && run_sh /bin/sh --range "$base" HEAD); chk "R4" 1 "$c" "modified grown fails"

# R5: spaced filename in range mode.
newrepo; git -C "$SCRATCH/r" commit -q --allow-empty -m init
base=$(git -C "$SCRATCH/r" rev-parse HEAD)
big 2097152 "sp ace.bin"; git -C "$SCRATCH/r" add "sp ace.bin"; git -C "$SCRATCH/r" commit -qm add
c=$(cd "$SCRATCH/r" && run_sh /bin/sh --range "$base" HEAD); chk "R5" 1 "$c" "spaced name fails"

# R6: large blob already in base is not re-reported.
c=$(cd "$SCRATCH/r" && run_sh /bin/sh --range "$(git -C "$SCRATCH/r" rev-parse HEAD)" HEAD)
chk "R6" 0 "$c" "empty range passes"

# R7/R8: unknown base and usage are exit 2.
newrepo; git -C "$SCRATCH/r" commit -q --allow-empty -m init
c=$(cd "$SCRATCH/r" && run_sh /bin/sh --range deadbeefdeadbeefdeadbeefdeadbeefdeadbeef HEAD)
chk "R7" 2 "$c" "unknown base errors closed"
c=$(cd "$SCRATCH/r" && run_sh /bin/sh --bogus); chk "R8" 2 "$c" "usage error"

# R9: clean range passes.
newrepo; echo a > "$SCRATCH/r/a.txt"; git -C "$SCRATCH/r" add a.txt; git -C "$SCRATCH/r" commit -qm init
base=$(git -C "$SCRATCH/r" rev-parse HEAD)
echo b > "$SCRATCH/r/b.txt"; git -C "$SCRATCH/r" add b.txt; git -C "$SCRATCH/r" commit -qm more
c=$(cd "$SCRATCH/r" && run_sh /bin/sh --range "$base" HEAD); chk "R9" 0 "$c" "clean range passes"

echo "guard checks: $n failures: $fail"
exit "$fail"
