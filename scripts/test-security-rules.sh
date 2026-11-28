#!/usr/bin/env bash
# Regression tests for ast-grep security rules and `just security` (R31).
# Verifies rule self-tests, seeded findings in shipped code, test/bench/fuzz
# exclusions, inline suppression comments, and zero-file / zero-rule guards.
set -euo pipefail

export PATH="${HOME}/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:${PATH}"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
pass=0
fail=0
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

ok() {
    echo "ok   $1"
    pass=$((pass + 1))
}

bad() {
    echo "FAIL $1" >&2
    fail=$((fail + 1))
}

command -v ast-grep >/dev/null 2>&1 || {
    echo "FAIL ast-grep binary not found on PATH" >&2
    exit 1
}

if [ ! -f "$repo_root/sgconfig.yml" ]; then
    bad "sgconfig.yml exists at repository root"
    echo
    echo "$pass passed, $fail failed"
    exit 1
fi
ok "sgconfig.yml exists at repository root"

# 1. ast-grep self-tests pass across all 5 rule test fixtures
rc=0
out=$(cd "$repo_root" && ast-grep test --skip-snapshot-tests 2>&1) || rc=$?
if [ "$rc" -eq 0 ]; then
    ok "ast-grep test --skip-snapshot-tests passes"
else
    bad "ast-grep test failed (rc=$rc out=$out)"
fi

# 2. Seeded file in src/ triggers all 5 security rule IDs
work="$tmp_root/seeded"
mkdir -p "$work/src" "$work/tests" "$work/benches" "$work/fuzz"
cp "$repo_root/sgconfig.yml" "$work/"
cp -R "$repo_root/rules" "$work/"

cat >"$work/src/seeded.rs" <<'EOF'
fn seeded_findings() {
    let _ = std::process::Command::new("sh").arg("-c").arg("echo hi");
    let _ = diesel::sql_query(format!("SELECT * FROM t WHERE id = {}", 1));
    let _ = md5::compute(b"data");
    let _ = builder.danger_accept_invalid_certs(true);
    let _ = std::env::temp_dir().join("app.lock");
}
EOF

rc=0
out=$(cd "$work" && ast-grep scan --error src/seeded.rs 2>&1) || rc=$?
missing_ids=""
for id in rs-shell-invocation rs-sql-format rs-weak-hash rs-tls-verification-disabled rs-predictable-temp; do
    if ! grep -q "$id" <<<"$out"; then
        missing_ids="${missing_ids:+$missing_ids }$id"
    fi
done
if [ "$rc" -ne 0 ] && [ -z "$missing_ids" ]; then
    ok "seeded src/ file triggers all 5 security rule IDs"
else
    bad "seeded src/ scan failed (rc=$rc missing=$missing_ids)"
fi

# 3. Identical seeded findings under tests/, benches/, and fuzz/ are ignored
cp "$work/src/seeded.rs" "$work/tests/seeded.rs"
cp "$work/src/seeded.rs" "$work/benches/seeded.rs"
cp "$work/src/seeded.rs" "$work/fuzz/seeded.rs"
rm -f "$work/src/seeded.rs"

rc=0
out=$(cd "$work" && ast-grep scan --error tests/seeded.rs benches/seeded.rs fuzz/seeded.rs 2>&1) || rc=$?
if [ "$rc" -eq 0 ]; then
    ok "findings under tests/, benches/, and fuzz/ are ignored"
else
    bad "ignored dirs scan failed (rc=$rc out=$out)"
fi

# 4. Inline ast-grep-ignore suppresses only the annotated site
cat >"$work/src/suppressed.rs" <<'EOF'
fn hash_check() {
    // ast-grep-ignore: rs-weak-hash -- test fixture verifying inline suppression
    let _ = md5::compute(b"legacy-checksum");
}
EOF
rc=0
out=$(cd "$work" && ast-grep scan --error src/suppressed.rs 2>&1) || rc=$?
if [ "$rc" -eq 0 ]; then
    ok "inline ast-grep-ignore comment suppresses annotated finding"
else
    bad "inline suppression failed (rc=$rc out=$out)"
fi

# 5. just security exits 0 on the clean repository and scans >0 files with >=5 rules
rc=0
out=$(cd "$repo_root" && just security 2>&1) || rc=$?
if [ "$rc" -eq 0 ] && grep -Eq 'security: [1-9][0-9]* files, [5-9][0-9]* rules, 0 findings' <<<"$out"; then
    ok "just security passes on clean repository with files and rules guards"
else
    bad "just security failed (rc=$rc out=$out)"
fi

# 6. Zero-files and zero-rules guards fail closed
empty_files="$tmp_root/zero-files"
mkdir -p "$empty_files"
cp "$repo_root/sgconfig.yml" "$repo_root/Justfile" "$empty_files/"
cp -R "$repo_root/rules" "$empty_files/"
rc=0
out=$(cd "$empty_files" && just security 2>&1) || rc=$?
if [ "$rc" -ne 0 ] && grep -q 'scanned 0 files' <<<"$out"; then
    ok "just security fails closed when 0 files are scanned"
else
    bad "zero-files guard failed (rc=$rc out=$out)"
fi

empty_rules="$tmp_root/zero-rules"
mkdir -p "$empty_rules/src" "$empty_rules/rules/security" "$empty_rules/rules/security-tests"
cp "$repo_root/sgconfig.yml" "$repo_root/Justfile" "$empty_rules/"
printf 'pub fn ok() {}\n' >"$empty_rules/src/lib.rs"
rc=0
out=$(cd "$empty_rules" && just security 2>&1) || rc=$?
if [ "$rc" -ne 0 ] && grep -q 'loaded 0 rules' <<<"$out"; then
    ok "just security fails closed when 0 rules are loaded"
else
    bad "zero-rules guard failed (rc=$rc out=$out)"
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
