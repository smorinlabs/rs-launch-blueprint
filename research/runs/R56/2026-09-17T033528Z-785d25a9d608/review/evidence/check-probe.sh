#!/usr/bin/env bash
# R56 evidence — build and run the throwaway probe in probe/ under a $TMPDIR copy and
# assert its output. The probe is NOT the recommendation implemented; it exercises the
# four behavioural claims the raw reports make (0600-at-O_CREAT, the mode & 0o077 mask,
# a dropped `token` key, three-tier ordering, Debug redaction) and measures the
# dependency trees the keychain member is judged on. The committed Cargo.lock is what
# makes the package counts reproducible; the build runs --locked so a drifting registry
# fails the check instead of silently changing the numbers.
# The fixture credential sk_live_R56PROBE_DO_NOT_LOG must never appear in this log; the
# leak census below asserts that with /usr/bin/grep (binary named beside the count).
set -euo pipefail
set -o pipefail

here="$(cd "$(dirname "$0")" && pwd)"
fail=0
ok()   { printf 'PASS %s — %s\n' "$1" "$2"; }
bad()  { printf 'FAIL %s — %s\n' "$1" "$2"; fail=$((fail + 1)); }
want() { if [ "$2" = "$3" ]; then ok "$1" "$3"; else bad "$1" "expected [$2], got [$3]"; fi; }

if ! command -v cargo > /dev/null 2>&1; then
  printf 'SKIP check-probe — cargo is not on PATH; this check needs a Rust toolchain\n'
  exit 0
fi

printf 'toolchain: %s\n' "$(rustc --version)"
printf 'toolchain: %s\n' "$(cargo --version)"
printf 'host: %s %s (macOS %s)\n' "$(uname -s)" "$(uname -m)" "$(sw_vers -productVersion 2> /dev/null || echo n/a)"
printf 'date-utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

work="$(mktemp -d "${TMPDIR:-/tmp}/r56probe-XXXXXX")"
trap 'rm -rf "$work"' EXIT
cp -R "$here/probe/." "$work/"
cd "$work"

# 1. The committed lockfile still resolves exactly, at the MSRV floor the manifest declares.
lock_line="$(cargo generate-lockfile --locked 2>&1 | /usr/bin/grep -c 'error' || true)"
want 'P0 lockfile-is-current' '0' "$lock_line"
# 106 `[[package]]` entries = the 105 dependencies `cargo generate-lockfile` reports
# locking, plus the root package r56probe itself.
packages_locked="$(/usr/bin/grep -c '^name = ' Cargo.lock)"
want 'P1 locked-package-count' '106' "$packages_locked"

# 2. It builds on the current stable toolchain.
if cargo build --locked --quiet 2> "$work/build.err"; then
  ok 'P2 build' 'cargo build --locked succeeded'
else
  bad 'P2 build' "$(tail -3 "$work/build.err")"
fi

# 3. The probe's own assertions. Both streams are captured for the leak census.
set +e
./target/debug/r56probe > "$work/out.txt" 2> "$work/err.txt"
probe_status=$?
set -e
cat "$work/out.txt"
sed 's/^/stderr: /' "$work/err.txt"
want 'P3 probe-exit' '0' "$probe_status"
want 'P4 probe-failures' 'PROBE_FAILURES=0' "$(/usr/bin/grep -o 'PROBE_FAILURES=[0-9]*' "$work/out.txt")"
want 'P5 probe-assertion-count' '15' "$(/usr/bin/grep -c '^PASS ' "$work/out.txt")"

# 4. Leak census over the probe's combined stdout and stderr. Binary: /usr/bin/grep.
leaks="$(cat "$work/out.txt" "$work/err.txt" | /usr/bin/grep -c 'sk_live_R56PROBE_DO_NOT_LOG' || true)"
want 'P6 leak-census-/usr/bin/grep' '0' "$leaks"

# 5. Dependency-tree size, which is the whole argument for keeping the keychain tier
#    behind a non-default feature. Unique package count, duplicate (*) markers folded.
count_tree() { cargo tree --locked -e normal --prefix none "$@" | sed 's/ (\*)//' | sort -u | /usr/bin/grep -c .; }
want 'P7 tree-default'            '10' "$(count_tree)"
want 'P8 tree-keychain-macos'     '13' "$(count_tree --features keychain)"
want 'P9 tree-keychain-linux'     '89' "$(count_tree --features keychain --target x86_64-unknown-linux-gnu)"

# 6. The Linux keychain tree pulls a second async runtime. Named, not inferred.
linux_tree="$(cargo tree --locked -e normal --prefix none --features keychain --target x86_64-unknown-linux-gnu)"
for crate in zbus secret-service async-executor async-io blocking polling event-listener; do
  if printf '%s\n' "$linux_tree" | /usr/bin/grep -q "^${crate} v"; then
    ok "P10.${crate}" "present in the Linux keychain tree"
  else
    bad "P10.${crate}" 'absent'
  fi
done
if printf '%s\n' "$linux_tree" | /usr/bin/grep -q '^tokio v'; then
  bad 'P11 no-tokio' 'tokio appeared; the second-runtime argument needs restating'
else
  ok 'P11 no-tokio' 'no tokio in the Linux keychain tree — the runtime pulled is the smol family'
fi

# 7. Highest declared rust-version across each resolved DEPENDENCY tree, against the
#    1.96 floor. The root package r56probe is excluded: its own rust-version is the
#    floor being tested, so including it would make the check assert itself.
max_msrv() {
  cargo metadata --locked --format-version 1 "$@" \
    | python3 -c 'import json,sys;print(max(((p.get("rust_version") or "0") for p in json.load(sys.stdin)["packages"] if p["name"] != "r56probe"), key=lambda v:[int(x) for x in v.split(".")]))'
}
# hashbrown 0.17.1 declares its floor with a patch component, as the literal string
# "1.85.0"; every other tight package declares "1.85". Both are under the 1.96 floor.
want 'P12 msrv-max-default'  '1.85.0' "$(max_msrv --filter-platform aarch64-apple-darwin)"
want 'P13 msrv-max-keychain' '1.88' "$(max_msrv --features keychain --filter-platform x86_64-unknown-linux-gnu)"
printf 'P12-detail tightest default-tree package: %s\n' \
  "$(cargo metadata --locked --format-version 1 --filter-platform aarch64-apple-darwin \
     | python3 -c 'import json,sys;ps=[p for p in json.load(sys.stdin)["packages"] if p["name"]!="r56probe"];p=max(ps,key=lambda p:[int(x) for x in (p.get("rust_version") or "0").split(".")]);print(p["name"],p["version"],p["rust_version"])')"

printf 'CHECK_FAILURES=%s\n' "$fail"
[ "$fail" -eq 0 ]
