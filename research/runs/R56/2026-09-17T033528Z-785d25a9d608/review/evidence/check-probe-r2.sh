#!/usr/bin/env bash
# shellcheck disable=SC2016
# SC2016 is disabled for the whole file: one assertion needle is the probe's own warning
# text, which contains a backtick-quoted key name, and one message names $TMPDIR literally.
# Single quotes are required precisely so nothing expands.
# R56 evidence, revision 2 — a NEW check added to close JF-1 and JF-2 from the round-1
# judgment audit. Revision 1's five scripts, their logs and its probe are NOT edited and
# NOT rerun by this file; they stay byte-identical as the record of what revision 1 ran.
#
#   JF-1  revision 1's acceptance criterion 4 labelled "a set RSLBP_TOKEN outranks the
#         stored credential" executed via C1 and C3, and neither call exercised that rung
#         (C1 passed stored = None, C3 passed an empty env). E0-E4 below execute it.
#   JF-2  revision 1's acceptance criterion 1 labelled "that warning names the file"
#         executed via B1-B4, and its scanner took a document string and named no file.
#         F1-F6 below execute it with the scanner given the layer's path.
#
# The fixture credentials sk_live_R56R2_STORED_DO_NOT_LOG and sk_live_R56R2_CONFIG_DO_NOT_LOG
# must never appear in this log; the leak census below asserts that with /usr/bin/grep,
# named beside the count.
set -euo pipefail
set -o pipefail

here="$(cd "$(dirname "$0")" && pwd)"
fail=0
ok()   { printf 'PASS %s — %s\n' "$1" "$2"; }
bad()  { printf 'FAIL %s — %s\n' "$1" "$2"; fail=$((fail + 1)); }
want() { if [ "$2" = "$3" ]; then ok "$1" "$3"; else bad "$1" "expected [$2], got [$3]"; fi; }

if ! command -v cargo > /dev/null 2>&1; then
  printf 'SKIP check-probe-r2 — cargo is not on PATH; this check needs a Rust toolchain\n'
  exit 0
fi

printf 'toolchain: %s\n' "$(rustc --version)"
printf 'toolchain: %s\n' "$(cargo --version)"
printf 'host: %s %s (macOS %s)\n' "$(uname -s)" "$(uname -m)" "$(sw_vers -productVersion 2> /dev/null || echo n/a)"
printf 'date-utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

work="$(mktemp -d "${TMPDIR:-/tmp}/r56probe-r2-XXXXXX")"
trap 'rm -rf "$work"' EXIT
cp -R "$here/probe-r2/." "$work/"
cd "$work"

# 1. The committed lockfile still resolves exactly, at the MSRV floor the manifest declares.
lock_errors="$(cargo generate-lockfile --locked 2>&1 | /usr/bin/grep -c 'error' || true)"
want 'Q0 lockfile-is-current' '0' "$lock_errors"
# 18 `[[package]]` entries = the 17 dependencies cargo reports locking, plus the root package.
want 'Q1 locked-package-count' '18' "$(/usr/bin/grep -c '^name = ' Cargo.lock)"

# 2. It builds on the current stable toolchain.
if cargo build --locked --quiet 2> "$work/build.err"; then
  ok 'Q2 build' 'cargo build --locked succeeded'
else
  bad 'Q2 build' "$(tail -3 "$work/build.err")"
fi

# 3. The probe's own assertions. Both streams are captured for the leak census.
set +e
./target/debug/r56probe_r2 > "$work/out.txt" 2> "$work/err.txt"
probe_status=$?
set -e
cat "$work/out.txt"
sed 's/^/stderr: /' "$work/err.txt"
want 'Q3 probe-exit' '0' "$probe_status"
want 'Q4 probe-failures' 'PROBE_R2_FAILURES=0' "$(/usr/bin/grep -o 'PROBE_R2_FAILURES=[0-9]*' "$work/out.txt")"
want 'Q5 probe-assertion-count' '11' "$(/usr/bin/grep -c '^PASS ' "$work/out.txt")"

# 4. The two findings are closed by name, so an auditor can read the closure off this log
#    rather than inferring it from the assertion ids.
want 'Q6 JF-1-closed' '4' "$(/usr/bin/grep -c '^PASS E[1-4] ' "$work/out.txt")"
want 'Q7 JF-1-control-present' '1' "$(/usr/bin/grep -c '^PASS E0 CONTROL stored-tier-is-reachable' "$work/out.txt")"
want 'Q8 JF-2-closed' '6' "$(/usr/bin/grep -c '^PASS F[1-6] ' "$work/out.txt")"
if /usr/bin/grep -q 'rslbp_config.toml: key `token` is ignored' "$work/err.txt"; then
  ok 'Q9 JF-2-emitted-warning-names-a-file' 'the echoed warning opens with the scanned layer path (run-specific $TMPDIR prefix replaced by a placeholder inside the probe, so this log stays diffable)'
else
  bad 'Q9 JF-2-emitted-warning-names-a-file' 'the echoed warning names no file'
fi

# 5. Leak census over the probe's combined stdout and stderr. Binary: /usr/bin/grep.
# The assertion ids are numbered rather than named, so this log can never match its own
# search on a later rerun — a self-reference that would make the check fail the second time.
i=0
for fixture in sk_live_R56R2_STORED_DO_NOT_LOG sk_live_R56R2_CONFIG_DO_NOT_LOG; do
  i=$((i + 1))
  n="$(cat "$work/out.txt" "$work/err.txt" | /usr/bin/grep -c "$fixture" || true)"
  want "Q10.${i} leak-census-fixture-absent" '0' "$n"
done

printf 'CHECK_FAILURES=%s\n' "$fail"
[ "$fail" -eq 0 ]
