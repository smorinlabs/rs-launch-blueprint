#!/usr/bin/env bash
# Offline regression tests for scripts/check-cargo-lock.sh (R41).
# Uses local path-only workspaces (zero network / crates.io access) to test:
#   - skip when no Cargo resolution inputs are staged
#   - member version bump refusal + lockfile restoration
#   - leaf workspace member removal (orphan [[package]] entry that --locked misses)
#   - staged deletion of a member manifest
#   - index/worktree parity refusal before Cargo runs
#   - untracked non-ignored Cargo.toml refusal
#   - staged repaired lockfile passes
#   - --all unconditional mode catches bypassed stale lockfiles
#   - malformed manifest propagates Cargo's non-1 exit code (101)
#   - nested independent workspace detection & restoration
#   - missing Cargo.lock refusal & cleanup of generated file
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
script="$repo_root/scripts/check-cargo-lock.sh"

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

sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | cut -d' ' -f1
    else
        shasum -a 256 "$1" | cut -d' ' -f1
    fi
}

if [ ! -x "$script" ]; then
    bad "scripts/check-cargo-lock.sh exists and is executable"
    echo
    echo "$pass passed, $fail failed"
    exit 1
fi
ok "scripts/check-cargo-lock.sh exists and is executable"

new_ws() {
    local dir="$tmp_root/$1"
    mkdir -p "$dir/scripts" "$dir/crates/alpha/src" "$dir/crates/beta/src"
    cp "$script" "$dir/scripts/check-cargo-lock.sh"
    chmod +x "$dir/scripts/check-cargo-lock.sh"

    cat >"$dir/Cargo.toml" <<'EOF'
[workspace]
members = ["crates/alpha", "crates/beta"]
resolver = "3"
EOF
    cat >"$dir/crates/alpha/Cargo.toml" <<'EOF'
[package]
name = "alpha"
version = "0.1.0"
edition = "2024"
EOF
    printf 'pub fn a() -> u8 { 1 }\n' >"$dir/crates/alpha/src/lib.rs"

    cat >"$dir/crates/beta/Cargo.toml" <<'EOF'
[package]
name = "beta"
version = "0.1.0"
edition = "2024"
EOF
    printf 'pub fn b() -> u8 { 2 }\n' >"$dir/crates/beta/src/lib.rs"

    printf 'target/\n' >"$dir/.gitignore"
    (cd "$dir" && cargo update --workspace --offline >/dev/null 2>&1)

    git -C "$dir" init -q -b main
    git -C "$dir" config user.name "Test"
    git -C "$dir" config user.email "test@example.com"
    git -C "$dir" add -A
    git -C "$dir" commit -q -m "chore: seed workspace"
    echo "$dir"
}

# 1. Unrelated staged file skips Cargo completely
r=$(new_ws skip-unrelated)
printf 'hello\n' >"$r/README.md"
git -C "$r" add README.md
rc=0
out=$(cd "$r" && CARGO_BIN=/nonexistent/cargo bash scripts/check-cargo-lock.sh 2>&1) || rc=$?
if [ "$rc" -eq 0 ] && grep -q 'SKIP:' <<<"$out"; then
    ok "skips Cargo when no Cargo resolution inputs are staged"
else
    bad "skip unrelated failed (rc=$rc out=$out)"
fi

# 2. Comment-only staged edit passes
r=$(new_ws comment-edit)
printf '# harmless comment\n' >>"$r/Cargo.toml"
git -C "$r" add Cargo.toml
rc=0
(cd "$r" && bash scripts/check-cargo-lock.sh >/dev/null 2>&1) || rc=$?
if [ "$rc" -eq 0 ]; then
    ok "comment-only manifest edit passes"
else
    bad "comment-only manifest edit failed (rc=$rc)"
fi

# 3. Member version bump without lockfile update fails and restores Cargo.lock
r=$(new_ws version-bump)
before=$(sha256 "$r/Cargo.lock")
sed 's/version = "0.1.0"/version = "0.2.0"/' "$r/crates/alpha/Cargo.toml" >"$r/crates/alpha/Cargo.toml.new"
mv "$r/crates/alpha/Cargo.toml.new" "$r/crates/alpha/Cargo.toml"
git -C "$r" add crates/alpha/Cargo.toml
rc=0
out=$(cd "$r" && bash scripts/check-cargo-lock.sh 2>&1) || rc=$?
after=$(sha256 "$r/Cargo.lock")
if [ "$rc" -eq 1 ] && [ "$before" = "$after" ] && grep -q 'out of date' <<<"$out"; then
    ok "member version bump fails with exit 1 and restores Cargo.lock"
else
    bad "version bump (rc=$rc before=$before after=$after out=$out)"
fi

# 4. Removed leaf workspace member (orphan entry --locked misses) fails and restores Cargo.lock
r=$(new_ws orphan-member)
before=$(sha256 "$r/Cargo.lock")
cat >"$r/Cargo.toml" <<'EOF'
[workspace]
members = ["crates/alpha"]
resolver = "3"
EOF
git -C "$r" add Cargo.toml
rc=0
out=$(cd "$r" && bash scripts/check-cargo-lock.sh 2>&1) || rc=$?
after=$(sha256 "$r/Cargo.lock")
if [ "$rc" -eq 1 ] && [ "$before" = "$after" ] && grep -q 'out of date' <<<"$out"; then
    ok "orphan workspace member entry fails with exit 1 and restores Cargo.lock"
else
    bad "orphan member (rc=$rc before=$before after=$after out=$out)"
fi

# 5. Staged deletion of member manifest triggers check and fails without lock update
r=$(new_ws staged-delete)
cat >"$r/Cargo.toml" <<'EOF'
[workspace]
members = ["crates/alpha"]
resolver = "3"
EOF
git -C "$r" rm -rq crates/beta
git -C "$r" add Cargo.toml
rc=0
(cd "$r" && bash scripts/check-cargo-lock.sh >/dev/null 2>&1) || rc=$?
if [ "$rc" -eq 1 ]; then
    ok "staged deletion of member manifest fails without Cargo.lock update"
else
    bad "staged deletion (rc=$rc)"
fi

# 6. Repaired lockfile left unstaged is refused BEFORE Cargo runs
r=$(new_ws parity-guard)
sed 's/version = "0.1.0"/version = "0.2.0"/' "$r/crates/alpha/Cargo.toml" >"$r/crates/alpha/Cargo.toml.new"
mv "$r/crates/alpha/Cargo.toml.new" "$r/crates/alpha/Cargo.toml"
git -C "$r" add crates/alpha/Cargo.toml
(cd "$r" && cargo update --workspace --offline >/dev/null 2>&1)
rc=0
out=$(cd "$r" && CARGO_BIN=/nonexistent/cargo bash scripts/check-cargo-lock.sh 2>&1) || rc=$?
if [ "$rc" -eq 1 ] && grep -q 'differ from the index' <<<"$out"; then
    ok "unstaged repaired Cargo.lock refused before Cargo runs"
else
    bad "parity guard (rc=$rc out=$out)"
fi

# 7. Staging the repaired lockfile makes the check pass
git -C "$r" add Cargo.lock
rc=0
(cd "$r" && bash scripts/check-cargo-lock.sh >/dev/null 2>&1) || rc=$?
if [ "$rc" -eq 0 ]; then
    ok "staged repaired Cargo.lock passes"
else
    bad "staged repaired lockfile failed (rc=$rc)"
fi

# 8. Untracked non-ignored Cargo.toml refused before Cargo runs
r=$(new_ws untracked-manifest)
printf '# comment\n' >>"$r/Cargo.toml"
git -C "$r" add Cargo.toml
mkdir -p "$r/stray"
printf '[package]\nname = "stray"\nversion = "0.1.0"\nedition = "2024"\n' >"$r/stray/Cargo.toml"
rc=0
out=$(cd "$r" && CARGO_BIN=/nonexistent/cargo bash scripts/check-cargo-lock.sh 2>&1) || rc=$?
if [ "$rc" -eq 1 ] && grep -q 'untracked Cargo resolution inputs' <<<"$out"; then
    ok "untracked non-ignored Cargo.toml refused before Cargo runs"
else
    bad "untracked manifest (rc=$rc out=$out)"
fi

# 9. --all catches bypassed orphan entry when nothing is staged
r=$(new_ws all-mode)
before=$(sha256 "$r/Cargo.lock")
cat >"$r/Cargo.toml" <<'EOF'
[workspace]
members = ["crates/alpha"]
resolver = "3"
EOF
git -C "$r" add Cargo.toml
git -C "$r" commit -q --no-verify -m "test: bypass hook with orphan member"
rc=0
(cd "$r" && bash scripts/check-cargo-lock.sh --all >/dev/null 2>&1) || rc=$?
after=$(sha256 "$r/Cargo.lock")
if [ "$rc" -eq 1 ] && [ "$before" = "$after" ]; then
    ok "--all catches bypassed orphan lockfile and restores Cargo.lock"
else
    bad "--all orphan check (rc=$rc before=$before after=$after)"
fi

# 10. Malformed manifest propagates Cargo exit status (101), not stale-lock exit 1
r=$(new_ws malformed-manifest)
printf 'this is not valid toml =\n' >"$r/crates/alpha/Cargo.toml"
git -C "$r" add crates/alpha/Cargo.toml
rc=0
out=$(cd "$r" && bash scripts/check-cargo-lock.sh 2>&1) || rc=$?
if [ "$rc" -eq 101 ] && grep -q 'could not complete' <<<"$out"; then
    ok "malformed manifest propagates Cargo exit 101"
else
    bad "malformed manifest (rc=$rc out=$out)"
fi

# 11. Nested independent workspace is discovered, refused when stale, and restored
r=$(new_ws nested-ws)
mkdir -p "$r/nested/src"
cat >"$r/nested/Cargo.toml" <<'EOF'
[workspace]

[package]
name = "nested-tool"
version = "0.1.0"
edition = "2024"
EOF
printf 'pub fn n() -> u8 { 3 }\n' >"$r/nested/src/lib.rs"
(cd "$r/nested" && cargo update --workspace --offline >/dev/null 2>&1)
git -C "$r" add nested
git -C "$r" commit -q -m "chore: add nested workspace"
before_nested=$(sha256 "$r/nested/Cargo.lock")
sed 's/version = "0.1.0"/version = "0.2.0"/' "$r/nested/Cargo.toml" >"$r/nested/Cargo.toml.new"
mv "$r/nested/Cargo.toml.new" "$r/nested/Cargo.toml"
git -C "$r" add nested/Cargo.toml
rc=0
out=$(cd "$r" && bash scripts/check-cargo-lock.sh 2>&1) || rc=$?
after_nested=$(sha256 "$r/nested/Cargo.lock")
if [ "$rc" -eq 1 ] && [ "$before_nested" = "$after_nested" ] && grep -q 'nested/Cargo.lock' <<<"$out"; then
    ok "nested independent workspace stale lockfile refused and restored"
else
    bad "nested workspace (rc=$rc before=$before_nested after=$after_nested out=$out)"
fi

# 12. Missing Cargo.lock fails and removes the generated file
r=$(new_ws missing-lock)
git -C "$r" rm -q Cargo.lock
rc=0
out=$(cd "$r" && bash scripts/check-cargo-lock.sh 2>&1) || rc=$?
if [ "$rc" -eq 1 ] && [ ! -e "$r/Cargo.lock" ] && grep -q 'would create: Cargo.lock' <<<"$out"; then
    ok "missing Cargo.lock fails and cleans up created file"
else
    bad "missing Cargo.lock (rc=$rc exists=$(test -e "$r/Cargo.lock" && echo yes || echo no) out=$out)"
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
