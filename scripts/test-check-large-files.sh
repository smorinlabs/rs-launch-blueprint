#!/usr/bin/env bash
# Regression tests for scripts/check-large-files.sh (R14).
# Exercises boundary sizes (1048576 vs 1048577) in both --staged and --range
# modes, .gitattributes large-file-ok exemption, add-then-delete blob scope,
# modified-file growth, spaced filenames, staged-vs-worktree isolation,
# fail-closed bases/errors, and single-source-of-truth threshold placement.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
script="$repo_root/scripts/check-large-files.sh"

pass=0
fail=0
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1

ok() {
    echo "ok   $1"
    pass=$((pass + 1))
}

bad() {
    echo "FAIL $1" >&2
    fail=$((fail + 1))
}

check_rc() {
    local want="$1" name="$2"
    shift 2
    local rc=0
    "$@" >/dev/null 2>&1 || rc=$?
    if [ "$rc" -eq "$want" ]; then
        ok "$name"
    else
        bad "$name (exit $rc, wanted $want)"
    fi
}

make_bytes() {
    local size="$1" out="$2"
    dd if=/dev/zero of="$out" bs=1024 count=$((size / 1024)) 2>/dev/null
    local rem=$((size % 1024))
    if [ "$rem" -gt 0 ]; then
        dd if=/dev/zero bs=1 count="$rem" >>"$out" 2>/dev/null
    fi
}

new_repo() {
    local dir="$tmp_root/$1"
    mkdir -p "$dir/scripts"
    cp "$script" "$dir/scripts/check-large-files.sh"
    chmod +x "$dir/scripts/check-large-files.sh"
    git -C "$dir" init -q -b main
    git -C "$dir" config user.name "Test"
    git -C "$dir" config user.email "test@example.com"
    printf 'seed\n' >"$dir/README.md"
    git -C "$dir" add README.md scripts/check-large-files.sh
    git -C "$dir" commit -q -m "chore: seed"
    echo "$dir"
}

if [ ! -x "$script" ]; then
    bad "scripts/check-large-files.sh exists and is executable"
    echo
    echo "$pass passed, $fail failed"
    exit 1
fi
ok "scripts/check-large-files.sh exists and is executable"

# 1 & 2: --staged boundary (1048576 passes, 1048577 fails)
r=$(new_repo staged-boundary)
make_bytes 1048576 "$r/exact.bin"
git -C "$r" add exact.bin
check_rc 0 "--staged allows exact 1048576-byte blob" sh -c "cd '$r' && sh scripts/check-large-files.sh --staged"

make_bytes 1048577 "$r/over.bin"
git -C "$r" add over.bin
check_rc 1 "--staged rejects 1048577-byte blob" sh -c "cd '$r' && sh scripts/check-large-files.sh --staged"

# 3 & 4: --range boundary (1048576 passes, 1048577 fails)
r=$(new_repo range-boundary)
base=$(git -C "$r" rev-parse HEAD)
make_bytes 1048576 "$r/exact.bin"
git -C "$r" add exact.bin
git -C "$r" commit -q -m "test: exact 1 MiB"
head_exact=$(git -C "$r" rev-parse HEAD)
check_rc 0 "--range allows exact 1048576-byte blob" sh -c "cd '$r' && sh scripts/check-large-files.sh --range '$base' '$head_exact'"

make_bytes 1048577 "$r/over.bin"
git -C "$r" add over.bin
git -C "$r" commit -q -m "test: 1 MiB + 1"
head_over=$(git -C "$r" rev-parse HEAD)
check_rc 1 "--range rejects 1048577-byte blob" sh -c "cd '$r' && sh scripts/check-large-files.sh --range '$head_exact' '$head_over'"

# 5: large-file-ok exemption in .gitattributes (both tiers, emits ALLOW:)
r=$(new_repo exemption)
base=$(git -C "$r" rev-parse HEAD)
printf 'fixtures/big.bin large-file-ok\n' >"$r/.gitattributes"
mkdir -p "$r/fixtures"
make_bytes 1048577 "$r/fixtures/big.bin"
git -C "$r" add .gitattributes fixtures/big.bin
out=""
rc=0
out=$(cd "$r" && sh scripts/check-large-files.sh --staged 2>&1) || rc=$?
if [ "$rc" -eq 0 ] && grep -q 'ALLOW: fixtures/big.bin' <<<"$out"; then
    ok "--staged honors .gitattributes large-file-ok with ALLOW message"
else
    bad "--staged large-file-ok (rc=$rc out=$out)"
fi
git -C "$r" commit -q -m "test: exempted large file"
head_ex=$(git -C "$r" rev-parse HEAD)
out=""
rc=0
out=$(cd "$r" && sh scripts/check-large-files.sh --range "$base" "$head_ex" 2>&1) || rc=$?
if [ "$rc" -eq 0 ] && grep -q 'ALLOW: fixtures/big.bin' <<<"$out"; then
    ok "--range honors .gitattributes large-file-ok with ALLOW message"
else
    bad "--range large-file-ok (rc=$rc out=$out)"
fi

# 6: add-then-delete inside a range still fails --range (blob scope)
r=$(new_repo add-then-delete)
base=$(git -C "$r" rev-parse HEAD)
make_bytes 1048577 "$r/transient.bin"
git -C "$r" add transient.bin
git -C "$r" commit -q -m "test: add large blob"
git -C "$r" rm -q transient.bin
git -C "$r" commit -q -m "test: delete large blob"
head_del=$(git -C "$r" rev-parse HEAD)
check_rc 1 "--range catches add-then-delete oversize blob" sh -c "cd '$r' && sh scripts/check-large-files.sh --range '$base' '$head_del'"

# 7: modified file grown past 1 MiB fails both tiers
r=$(new_repo modified-growth)
printf 'small\n' >"$r/grow.bin"
git -C "$r" add grow.bin
git -C "$r" commit -q -m "test: add small file"
base=$(git -C "$r" rev-parse HEAD)
make_bytes 1048577 "$r/grow.bin"
git -C "$r" add grow.bin
check_rc 1 "--staged catches modified file grown past 1 MiB" sh -c "cd '$r' && sh scripts/check-large-files.sh --staged"
git -C "$r" commit -q -m "test: grow file"
head_grow=$(git -C "$r" rev-parse HEAD)
check_rc 1 "--range catches modified file grown past 1 MiB" sh -c "cd '$r' && sh scripts/check-large-files.sh --range '$base' '$head_grow'"

# 8: spaced filename fails both tiers safely
r=$(new_repo spaced-name)
base=$(git -C "$r" rev-parse HEAD)
make_bytes 1048577 "$r/file with spaces.bin"
git -C "$r" add "file with spaces.bin"
check_rc 1 "--staged catches spaced filename > 1 MiB" sh -c "cd '$r' && sh scripts/check-large-files.sh --staged"
git -C "$r" commit -q -m "test: spaced large file"
head_sp=$(git -C "$r" rev-parse HEAD)
check_rc 1 "--range catches spaced filename > 1 MiB" sh -c "cd '$r' && sh scripts/check-large-files.sh --range '$base' '$head_sp'"

# 9: staged-vs-worktree isolation (checks index blob, not worktree)
r=$(new_repo staged-vs-worktree)
printf 'tiny\n' >"$r/iso.bin"
git -C "$r" add iso.bin
make_bytes 1048577 "$r/iso.bin"
check_rc 0 "--staged measures index blob, ignoring larger unstaged worktree" sh -c "cd '$r' && sh scripts/check-large-files.sh --staged"

# 10 & 11: fail-closed bases and usage errors
r=$(new_repo fail-closed)
make_bytes 1048577 "$r/history.bin"
git -C "$r" add history.bin
git -C "$r" commit -q -m "test: large blob in history"
head_fc=$(git -C "$r" rev-parse HEAD)
check_rc 1 "--range with all-zero base scans full history (fail-closed)" sh -c "cd '$r' && sh scripts/check-large-files.sh --range 0000000000000000000000000000000000000000 '$head_fc'"
check_rc 1 "--range with empty base scans full history (fail-closed)" sh -c "cd '$r' && sh scripts/check-large-files.sh --range '' '$head_fc'"
check_rc 2 "--range with unknown base fails closed with exit 2" sh -c "cd '$r' && sh scripts/check-large-files.sh --range nonexistent-ref '$head_fc'"
check_rc 2 "missing arguments exits 2" sh -c "cd '$r' && sh scripts/check-large-files.sh"

# 12: single source of truth — 1048576 lives in scripts/check-large-files.sh only
if grep -q '1048576' "$script" \
    && ! grep -q '1048576' "$repo_root/Justfile" \
    && { [ ! -f "$repo_root/lefthook.yml" ] || ! grep -q '1048576' "$repo_root/lefthook.yml"; }; then
    ok "1048576 threshold defined once in scripts/check-large-files.sh"
else
    bad "1048576 threshold duplicated outside scripts/check-large-files.sh"
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
