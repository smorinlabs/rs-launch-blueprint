#!/usr/bin/env bash
# R46 empirical check runner (synthesizer synth-fable-2026-09-05T160304Z-5cba7fe96ae4, 2026-09-05).
# Copies fixture/, lowq/, controls/, acceptance.sh and checker.sh into a work directory
# ($R46_WORK, default ./.work; CARGO_TARGET_DIR lives inside it) and runs:
#   S1  acceptance.sh  - raw/codex.md lines 414-498 verbatim, from the fixture root
#   S2  checker.sh     - raw/codex.md lines 428-482 verbatim, on each control file
#   S3  several files through one xargs/awk invocation (per-file transition logic)
#   S4  whole-tree inverse control: one form (a) file under src/ must make S1 fail
#   S5  cargo metadata: every workspace package resolves license = "MIT OR Apache-2.0"
#   S6  package-content review: which .crate archives carry LICENSE-APACHE / LICENSE-MIT
#   S7  the CLI binary prints the expression it was compiled with
#   S8  `//!` placement probe: header-before-docs and docs-only both build, pass
#       `cargo fmt --check`, and render crate docs; the header-bearing file is caught by the checker
# Writes only to stdout/stderr and the work directory. Exit 0 iff FAIL=0.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work="${R46_WORK:-$here/.work}"
PASS=0
FAIL=0
ok() { PASS=$((PASS + 1)); printf 'PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf 'FAIL  %s\n' "$1"; }
expect_exit() { if [[ "$2" == "$3" ]]; then ok "$1 -> exit $3"; else bad "$1 -> expected exit $2, observed $3"; fi; }
expect_grep() { if grep -q -F -- "$2" "$3"; then ok "$1 -> found '$2'"; else bad "$1 -> missing '$2'"; fi; }
section() { printf '\n=== %s ===\n' "$1"; }
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1; }
indent() { sed 's/^/    /'; }

section "S0 toolchain and host"
date -u +%Y-%m-%dT%H:%M:%SZ
uname -a
sw_vers 2>/dev/null || lsb_release -ds 2>/dev/null || head -2 /etc/os-release
rustc --version
cargo --version
cargo fmt --version 2>/dev/null || echo "rustfmt: absent"
awk --version 2>/dev/null | head -1 || awk -W version 2>&1 | head -1
xargs --version 2>/dev/null | head -1 || echo "xargs: BSD xargs (no --version flag)"
jq --version
bash --version | head -1
echo "runner:  $here"
echo "work:    $work"
echo "checker.sh sha256:    $(sha "$here/checker.sh")"
echo "acceptance.sh sha256: $(sha "$here/acceptance.sh")"
echo "LICENSE-APACHE sha256: $(sha "$here/fixture/LICENSE-APACHE")"
echo "LICENSE-MIT sha256:    $(sha "$here/fixture/LICENSE-MIT")"

rm -rf "$work"
mkdir -p "$work"
cp -R "$here/fixture" "$here/lowq" "$here/controls" "$work/"
cp "$here/acceptance.sh" "$here/checker.sh" "$work/"
export CARGO_TARGET_DIR="$work/target"
fx="$work/fixture"

section "S1 recommended acceptance sequence (acceptance.sh, verbatim) from the fixture root"
( cd "$fx" && bash "$work/acceptance.sh" ) > "$work/s1.out" 2>&1
s1=$?
indent < "$work/s1.out"
expect_exit "S1 acceptance.sh on the header-free fixture" 0 "$s1"

section "S2 checker controls (checker.sh, verbatim; one NUL-delimited path each)"
# shellcheck disable=SC1091
source "$work/checker.sh"
run_checker() { printf '%s\0' "$@" | r46_check_headers 2>&1; }
control() {
  local out st
  out=$(run_checker "$3"); st=$?
  [[ -n "$out" ]] && printf '%s\n' "$out" | indent
  expect_exit "S2 $1" "$2" "$st"
}
control "clean: leading //! docs"                          0 "$work/controls/clean.rs"
control "empty (0-byte) file"                              0 "$work/controls/empty.rs"
control "form (a) SPDX-License-Identifier line"            1 "$work/controls/form-a.rs"
control "form (b) MIT boilerplate first line"              1 "$work/controls/form-b.rs"
control "form (c) Apache appendix boilerplate line"        1 "$work/controls/form-c.rs"
control "form (d) Apache title then Version line"          1 "$work/controls/form-d.rs"
control "form (e) MIT title then Copyright (c)"            1 "$work/controls/form-e.rs"
control "runner-up REUSE two-line header"                  1 "$work/controls/reuse-two-line.rs"
control "boundary: SPDX marker on line 41"                 0 "$work/controls/after-40.rs"
control "boundary: Apache title, Version 4 lines later"    0 "$work/controls/not-d.rs"
control "boundary: MIT title, Copyright 3 lines later"     0 "$work/controls/not-e.rs"
control "root LICENSE-APACHE text fed as a source path"    1 "$fx/LICENSE-APACHE"
control "root LICENSE-MIT text fed as a source path"       1 "$fx/LICENSE-MIT"
control "missing path"                                     1 "$work/controls/does-not-exist.rs"

section "S3 several files through one xargs/awk invocation"
out=$(run_checker "$work/controls/clean.rs" "$fx/src/lib.rs" "$fx/src/main.rs" "$fx/crates/r46-web/src/lib.rs" "$work/controls/empty.rs"); st=$?
[[ -n "$out" ]] && printf '%s\n' "$out" | indent
expect_exit "S3 five clean files (one empty) in one batch" 0 "$st"
out=$(run_checker "$work/controls/clean.rs" "$work/controls/form-a.rs" "$fx/src/main.rs"); st=$?
printf '%s\n' "$out" | indent
expect_exit "S3 clean, form (a), clean in one batch" 1 "$st"
if printf '%s\n' "$out" | grep -q 'form-a.rs:1:(a)'; then ok "S3 diagnostic names the offending file and line"; else bad "S3 diagnostic missing"; fi
if printf '%s\n' "$out" | grep -q -E 'clean.rs:|main.rs:'; then bad "S3 a clean file was reported"; else ok "S3 no clean file reported"; fi

section "S4 whole-tree inverse control: one form (a) file under src/ must fail acceptance.sh"
bad_fx="$work/fixture-bad"
cp -R "$fx" "$bad_fx"
cp "$work/controls/form-a.rs" "$bad_fx/src/header.rs"
( cd "$bad_fx" && bash "$work/acceptance.sh" ) > "$work/s4.out" 2>&1
s4=$?
indent < "$work/s4.out"
expect_exit "S4 acceptance.sh with src/header.rs carrying form (a)" 1 "$s4"
expect_grep "S4 diagnostic" "src/header.rs:1:(a) SPDX-License-Identifier:" "$work/s4.out"
expect_grep "S4 failure message" "unexpected prohibited per-file license form or header-check failure" "$work/s4.out"

section "S5 cargo metadata: every workspace package resolves the fixed expression"
( cd "$fx" && cargo metadata --no-deps --format-version 1 | jq -r '.packages[] | "\(.name) \(.version) license=\(.license) edition=\(.edition) rust-version=\(.rust_version)"' ) | indent
( cd "$fx" && cargo metadata --no-deps --format-version 1 | jq -e '[.packages[].license] | length == 2 and all(. == "MIT OR Apache-2.0")' >/dev/null ); st=$?
expect_exit "S5 both packages report license = MIT OR Apache-2.0" 0 "$st"

section "S6 package-content review: which archives carry the license texts"
for pkg in r46-fixture r46-web; do
  echo "--- cargo package -p $pkg --allow-dirty --no-verify --list ---"
  ( cd "$fx" && cargo package -p "$pkg" --allow-dirty --no-verify --list ) > "$work/s6-$pkg.list" 2> "$work/s6-$pkg.err"
  st=$?
  indent < "$work/s6-$pkg.list"
  sed 's/^/    stderr: /' "$work/s6-$pkg.err"
  expect_exit "S6 cargo package -p $pkg --list" 0 "$st"
done
expect_grep "S6 root package archive lists LICENSE-APACHE" "LICENSE-APACHE" "$work/s6-r46-fixture.list"
expect_grep "S6 root package archive lists LICENSE-MIT" "LICENSE-MIT" "$work/s6-r46-fixture.list"
if grep -q -E '^LICENSE-(APACHE|MIT)$' "$work/s6-r46-web.list"; then
  echo "OBSERVED: the crates/r46-web archive includes the root LICENSE-APACHE / LICENSE-MIT"
else
  echo "OBSERVED: the crates/r46-web archive does NOT include the root LICENSE-APACHE / LICENSE-MIT (root-only files do not reach a crates/ member's .crate)"
fi
ok "S6 member archive content recorded (observation, not a gate)"
echo "--- archives written by S1 (\$CARGO_TARGET_DIR/package) ---"
for crate in "$CARGO_TARGET_DIR"/package/*.crate; do
  [[ -e "$crate" ]] || { echo "    (no .crate archives found)"; break; }
  echo "    ${crate#$work/}:"; tar -tzf "$crate" | sed 's/^/        /'
done

section "S7 the CLI binary prints the expression it was compiled with"
outp=$( cd "$fx" && cargo run --quiet --bin r46-fixture 2>/dev/null ); st=$?
echo "    stdout: $outp"
expect_exit "S7 cargo run --bin r46-fixture" 0 "$st"
if [[ "$outp" == "MIT OR Apache-2.0" ]]; then ok "S7 binary output is MIT OR Apache-2.0"; else bad "S7 binary output was '$outp'"; fi

section "S8 //! placement probe (prompt LOW question)"
for v in header-first docs-only; do
  d="$work/lowq/$v"
  echo "--- $v: first lines of src/lib.rs ---"; head -2 "$d/src/lib.rs" | indent
  ( cd "$d" && cargo build --quiet ); expect_exit "S8 $v cargo build" 0 "$?"
  ( cd "$d" && cargo fmt --all -- --check ); expect_exit "S8 $v cargo fmt --all -- --check" 0 "$?"
  ( cd "$d" && cargo doc --no-deps --quiet ); expect_exit "S8 $v cargo doc --no-deps" 0 "$?"
  html="$CARGO_TARGET_DIR/doc/${v//-/_}/index.html"
  marker="R46_LOWQ_$(echo "$v" | tr 'a-z-' 'A-Z_')"
  expect_grep "S8 $v crate docs rendered (${html#$work/})" "$marker" "$html"
done
out=$(run_checker "$work/lowq/header-first/src/lib.rs"); st=$?
printf '%s\n' "$out" | indent
expect_exit "S8 header-first src/lib.rs is rejected by the checker" 1 "$st"
out=$(run_checker "$work/lowq/docs-only/src/lib.rs"); st=$?
expect_exit "S8 docs-only src/lib.rs passes the checker" 0 "$st"

section "summary"
printf 'summary: PASS=%d FAIL=%d\n' "$PASS" "$FAIL"
if [[ "$FAIL" -eq 0 ]]; then echo "RESULT: PASS"; exit 0; else echo "RESULT: FAIL"; exit 1; fi
