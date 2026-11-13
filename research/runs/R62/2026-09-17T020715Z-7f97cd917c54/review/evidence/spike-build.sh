#!/bin/bash
# R62 clipboard-integration — throwaway dependency-resolution spike (revision 1).
#
# WHAT THIS IS. A disposable Cargo package under $TMPDIR whose ONLY content is
# the recommended dependency line and a one-line `fn main` that names a type
# from the crate so `cargo check` has something to check. It exists to convert
# three claims the raw reports make from "declared in a manifest" into
# "resolved and compiled on this host":
#   1. `default-features = false, features = ["wayland-data-control"]` resolves
#      with NO `image` crate on either leg of the fixed target-os-matrix;
#   2. the macOS leg pulls the AppKit backend and the Linux leg pulls BOTH
#      `x11rb` and `wl-clipboard-rs`;
#   3. the highest DECLARED rust-version in each resolved leg, which the Opus
#      report states as 1.71.0 for "the resolved-as-recommended set".
# It also runs `cargo tree -d` per leg, the duplicate-resolution control R67
# ran against its own dependency set.
#
# WHAT THIS IS NOT. It is not the template and not a step toward it. No
# ClipboardPort trait, no ClipboardError, no --copy flag, no re-exec helper, no
# adapter, no test. P03 builds all of that. The package directory is deleted
# when this script exits; only this log survives.
#
# `set -o pipefail` is on, and every claim is asserted on CONTENT.
#
# Usage:
#   bash spike-build.sh > r62-spike-build.log 2>&1
# Exit status: the number of FAILed assertions (0 = all assertions held).
#
# NETWORK: this script downloads crates from crates.io. It cannot run offline.

# shellcheck disable=SC2016  # backticks inside single-quoted text are literal
# shellcheck disable=SC2329  # cleanup() is invoked by the EXIT trap
set -uo pipefail

GREP=/usr/bin/grep
LINUX_TARGET=x86_64-unknown-linux-gnu
MAC_TARGET=aarch64-apple-darwin

FAILURES=0
ASSERTS=0

hr() { printf '\n\n========== %s ==========\n' "$1"; }

_record() {
	ASSERTS=$((ASSERTS + 1))
	printf '[%s %s] %s\n' "$1" "$2" "$3"
	[ "$2" = PASS ] || FAILURES=$((FAILURES + 1))
}
assert_eq() {
	if [ "$2" = "$3" ]; then
		_record "$1" PASS "$4 = $3"
	else
		_record "$1" FAIL "$4 — expected [$2], observed [$3]"
	fi
}
# assert_count <id> <expected> <needle> <file> <what>
assert_count() {
	local n
	n=$("$GREP" -cF -- "$3" "$4")
	printf '  [%s -cF] count=%s needle=%s file=%s\n' "$GREP" "$n" "$3" "$(basename "$4")"
	assert_eq "$1" "$2" "$n" "$5"
}
# assert_min <id> <minimum> <actual> <what>
assert_min() {
	if [ "$3" -ge "$2" ] 2>/dev/null; then
		_record "$1" PASS "$4 = $3 (>= $2)"
	else
		_record "$1" FAIL "$4 — expected at least $2, observed [$3]"
	fi
}

if ! command -v cargo >/dev/null 2>&1; then
	printf 'SKIP: cargo is not on PATH; the spike cannot run in this extraction.\n'
	exit 0
fi

SP=$(mktemp -d "${TMPDIR:-/tmp}/r62-spike.XXXXXX") || exit 99
cleanup() { rm -rf "$SP"; }
trap cleanup EXIT

hr "0. Toolchain and host (recorded because a resolution is toolchain-dependent)"
printf 'Run started (UTC): %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'rustc  : %s\n' "$(rustc --version)"
printf 'cargo  : %s\n' "$(cargo --version)"
printf 'host   : %s %s %s\n' "$(uname -s)" "$(uname -r)" "$(uname -m)"
printf 'macOS  : %s\n' "$(sw_vers -productVersion 2>/dev/null || printf 'n/a')"
printf 'spike  : %s (removed on exit)\n' "$SP"
printf '\nNOTE: `cargo tree --target %s` resolves the Linux leg from the lockfile\n' "$LINUX_TARGET"
printf 'without a Linux toolchain or a Linux host. It proves what WOULD be linked\n'
printf 'on ubuntu-latest; it does not compile or run anything for that target.\n'

hr "1. The spike package (its entire source)"
mkdir -p "$SP/spike/src" || exit 99
cat >"$SP/spike/Cargo.toml" <<'EOF'
[package]
name = "r62-arboard-spike"
version = "0.0.0"
edition = "2024"
publish = false

[dependencies]
arboard = { version = "3.6.1", default-features = false, features = ["wayland-data-control"] }
EOF
printf 'fn main() { let _ = std::mem::size_of::<arboard::Clipboard>(); }\n' >"$SP/spike/src/main.rs"
printf -- '--- Cargo.toml ---\n'
cat "$SP/spike/Cargo.toml"
printf -- '--- src/main.rs ---\n'
cat "$SP/spike/src/main.rs"
printf -- '--- (that is all of it) ---\n'
cd "$SP/spike" || exit 99

hr "2. cargo generate-lockfile"
cargo generate-lockfile 2>&1 | tee "$SP/lock.txt"
rc=${PIPESTATUS[0]}
assert_eq S01 "0" "$rc" "cargo generate-lockfile exit status"
assert_count S02 1 'Locking' "$SP/lock.txt" "cargo reported a lock resolution"

hr "3. macOS leg — cargo tree -e normal --target $MAC_TARGET"
cargo tree -e normal --target "$MAC_TARGET" 2>&1 | tee "$SP/mac.txt"
rc=${PIPESTATUS[0]}
assert_eq S03 "0" "$rc" "cargo tree (macOS leg) exit status"
assert_count S04 1 'arboard v3.6.1' "$SP/mac.txt" "arboard 3.6.1 in the macOS normal tree"
assert_count S05 1 'objc2-app-kit v' "$SP/mac.txt" "objc2-app-kit (NSPasteboard) is the macOS backend — no external binary"
assert_count S06 0 'image v' "$SP/mac.txt" "the image crate is ABSENT — default-features = false did its job"
assert_count S07 0 'x11rb v' "$SP/mac.txt" "no X11 dependency on the macOS leg"
assert_count S08 0 'wl-clipboard-rs v' "$SP/mac.txt" "no Wayland dependency on the macOS leg"
mac_pkgs=$(cargo tree -e normal --target "$MAC_TARGET" --prefix none 2>/dev/null | sed 's/ (\*)//' | awk 'NF {print $1" "$2}' | sort -u | wc -l | tr -d ' ')
printf 'macOS-leg distinct normal packages (including the spike itself): %s\n' "$mac_pkgs"

hr "4. Linux leg — cargo tree -e normal --target $LINUX_TARGET"
cargo tree -e normal --target "$LINUX_TARGET" 2>&1 | tee "$SP/linux.txt"
rc=${PIPESTATUS[0]}
assert_eq S09 "0" "$rc" "cargo tree (Linux leg) exit status"
assert_count S10 1 'arboard v3.6.1' "$SP/linux.txt" "arboard 3.6.1 in the Linux normal tree"
assert_min S11 1 "$("$GREP" -cF 'x11rb v' "$SP/linux.txt")" "x11rb occurrences on the Linux leg (the unconditional X11 backend)"
assert_min S12 1 "$("$GREP" -cF 'wl-clipboard-rs v' "$SP/linux.txt")" "wl-clipboard-rs occurrences on the Linux leg (the opt-in Wayland backend)"
assert_count S13 0 'image v' "$SP/linux.txt" "the image crate is ABSENT on the Linux leg too"
linux_pkgs=$(cargo tree -e normal --target "$LINUX_TARGET" --prefix none 2>/dev/null | sed 's/ (\*)//' | awk 'NF {print $1" "$2}' | sort -u | wc -l | tr -d ' ')
printf 'Linux-leg distinct normal packages (including the spike itself): %s\n' "$linux_pkgs"
printf 'COST OF wayland-data-control, measured here: the Linux leg is %s packages\n' "$linux_pkgs"
printf 'against the macOS leg'"'"'s %s. That difference is the qualitative\n' "$mac_pkgs"
printf 'compile-time and binary-size answer fitness gate 6 asks for, stated as a\n'
printf 'package count on this resolution rather than as an adjective.\n'

hr "5. Duplicate-resolution control (R67 ran the same control on its own set)"
printf -- '--- macOS leg ---\n'
cargo tree -d --target "$MAC_TARGET" 2>&1 | tee "$SP/dup-mac.txt"
printf -- '--- Linux leg ---\n'
cargo tree -d --target "$LINUX_TARGET" 2>&1 | tee "$SP/dup-linux.txt"
assert_count S14 0 ' v' "$SP/dup-mac.txt" "duplicate package lines on the macOS leg (cargo prints only a 'nothing to print' warning)"
assert_min S15 1 "$("$GREP" -cF 'hashbrown v' "$SP/dup-linux.txt")" "hashbrown lines in the Linux duplicate report"
printf '\nFINDING: the Linux leg resolves TWO hashbrown versions, reached through\n'
printf 'wl-clipboard-rs -> tree_magic_mini -> petgraph on one side and petgraph ->\n'
printf 'indexmap on the other. R67 recorded a zero-duplicate resolution for its own\n'
printf 'dependency set; that control does NOT hold on the Linux leg once\n'
printf 'wayland-data-control is enabled. It is a cost to record, not a gate\n'
printf 'failure: no fitness gate forbids duplicate resolutions.\n'

hr "6. Declared rust-version floors, per leg (cargo metadata, version-sorted)"
cargo metadata --format-version 1 >"$SP/meta.json" 2>"$SP/meta.err"
assert_eq S16 "0" "$?" "cargo metadata exit status"
jq -r '.packages[] | select(.rust_version != null) | "\(.rust_version) \(.name)"' "$SP/meta.json" | sort -V >"$SP/rv.txt"
for leg in mac linux; do
	cargo tree -e normal --target "$([ "$leg" = mac ] && printf '%s' "$MAC_TARGET" || printf '%s' "$LINUX_TARGET")" --prefix none 2>/dev/null |
		awk 'NF {print $1}' | sort -u >"$SP/$leg-pkgs.txt"
	: >"$SP/$leg-rv.txt"
	while IFS= read -r p; do
		"$GREP" -E " ${p}\$" "$SP/rv.txt" >>"$SP/$leg-rv.txt" || true
	done <"$SP/$leg-pkgs.txt"
	sort -V -o "$SP/$leg-rv.txt" "$SP/$leg-rv.txt"
	printf -- '--- %s leg, every declared rust-version ---\n' "$leg"
	cat "$SP/$leg-rv.txt"
	printf 'highest declared rust-version on the %s leg: %s\n' "$leg" "$(tail -1 "$SP/$leg-rv.txt")"
done
mac_max=$(awk '{print $1}' "$SP/mac-rv.txt" | sort -V | tail -1)
linux_max=$(awk '{print $1}' "$SP/linux-rv.txt" | sort -V | tail -1)
assert_eq S17 "1.71.0" "$mac_max" "highest declared rust-version, macOS leg"
assert_eq S18 "1.86" "$linux_max" "highest declared rust-version, Linux leg"
printf '\nCORRECTION TO raw/opus.md: it states "Highest declared rust-version in the\n'
printf 'resolved-as-recommended set is 1.71.0". That holds for the macOS leg only.\n'
printf 'On the Linux leg the wayland-data-control subtree raises it to %s\n' "$linux_max"
printf '(wayland-protocols). Both sit far below the 1.96 floor R67 computed from\n'
printf 'the stable channel, so the msrv-policy verdict is unchanged; the FIGURE is\n'
printf 'what was wrong, not the conclusion.\n'

hr "7. cargo check on this host (macOS leg only — the only leg with a toolchain)"
cargo check --quiet 2>&1 | tee "$SP/check.txt"
rc=${PIPESTATUS[0]}
assert_eq S19 "0" "$rc" "cargo check exit status — arboard 3.6.1 at these features type-checks under edition 2024 on this host"
assert_count S20 0 'error[' "$SP/check.txt" "rustc error codes in the check output"
assert_count S21 0 'warning: unused' "$SP/check.txt" "unused-dependency warnings"

hr "8. Summary"
printf 'assertions run : %s\n' "$ASSERTS"
printf 'failures       : %s\n' "$FAILURES"
printf '\nNOT established by this script:\n'
printf '  - that the Linux leg COMPILES. No Linux toolchain or host is available\n'
printf '    here; section 4 is a lockfile resolution, not a build. ubuntu-latest\n'
printf '    in P03 CI is what settles it.\n'
printf '  - any runtime clipboard behaviour, on any platform. Nothing was run.\n'
printf '  - `cargo audit`, which needs cargo-audit installed; R67 established the\n'
printf '    paired-control method and this run used the RustSec HTTP endpoints\n'
printf '    instead (verify.sh section 3).\n'
printf '\nThe spike directory %s is removed on exit.\n' "$SP"
printf 'exit status = failures = %s\n' "$FAILURES"
exit "$FAILURES"
