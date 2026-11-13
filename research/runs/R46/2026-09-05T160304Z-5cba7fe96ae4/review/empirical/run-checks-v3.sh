#!/usr/bin/env bash
# R46 empirical check runner, revision 3 (synthesizer synth-fable-2026-09-05T160304Z-5cba7fe96ae4, 2026-09-08).
# Same shape as run-checks-v2.sh (revision 2, kept unmodified for the r2 logs and the r2 audit rerun) but
# uses acceptance-v3.sh (all-package license assertion, audit-codex r2 F1) and checker-v3.sh (byte-identical
# function to checker-v2.sh). Copies fixture/, lowq/, controls/, acceptance-v3.sh, checker-v3.sh and, for the
# defect reproduction only, acceptance-v2.sh and checker-v2.sh into $R46_WORK (default ./.work; CARGO_TARGET_DIR inside it):
#   S0  toolchain and tool provenance; verbatim proofs (check_file == raw/codex.md:430-460; r46_check_headers == checker-v2.sh)
#   S1  acceptance-v3.sh from the fixture root
#   S2  checker controls: r1 forms and boundaries, the auditors' counterexamples, clap's live header,
#       block/shebang/blank/four-slash headers, ©/ⓒ/(c), a pointer, bounded license names, passes-by-design, false-positive costs
#   S3  several files through one xargs/awk invocation (fixture files must pass)
#   S4  whole-sequence inverse controls on fixture copies: clap's header and form (a) under src/; a divergent member
#       manifest (the r2 auditor's exact mutation, also reproduced through acceptance-v2.sh as the F1 defect); a member
#       without any license key; a root expression change; a missing root license file; and the pass-by-design member
#       that declares the expression directly instead of inheriting it
#   S5  cargo metadata listing and the all-package predicate (informational; S1/S4 are the enforcement)
#   S6  package-content review; S7 CLI output; S8 `//!` placement probe
# Writes only to stdout/stderr and the work directory. Exit 0 iff FAIL=0.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work="${R46_WORK:-$here/.work}"
raw="${R46_RAW:-$here/../../raw/codex.md}"
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
echo "awk resolves to: $(command -v awk)"
echo "rustc resolves to: $(command -v rustc)"
echo "cargo resolves to: $(command -v cargo)"
echo "cargo-fmt resolves to: $(command -v cargo-fmt 2>/dev/null || echo absent)"
echo "jq resolves to: $(command -v jq)"
xargs --version 2>/dev/null | head -1 || echo "xargs: BSD xargs (no --version flag)"
jq --version
bash --version | head -1
echo "runner:  $here"
echo "work:    $work"
echo "checker-v3.sh sha256:    $(sha "$here/checker-v3.sh")"
echo "acceptance-v3.sh sha256: $(sha "$here/acceptance-v3.sh")"
echo "run-checks-v3.sh sha256: $(sha "$here/run-checks-v3.sh")"
echo "checker-v2.sh sha256:    $(sha "$here/checker-v2.sh") (revision 2, defect reproduction only)"
echo "acceptance-v2.sh sha256: $(sha "$here/acceptance-v2.sh") (revision 2, defect reproduction only)"
echo "LICENSE-APACHE sha256:   $(sha "$here/fixture/LICENSE-APACHE")"
echo "LICENSE-MIT sha256:      $(sha "$here/fixture/LICENSE-MIT")"
echo "controls/clap-header.rs sha256: $(sha "$here/controls/clap-header.rs")"
if [[ -r "$raw" ]]; then
  if diff <(sed -n '430,460p' "$raw") <(sed -n '/^      function check_file/,/^      }$/p' "$here/checker-v3.sh") >/dev/null; then
    ok "S0 layer 1 check_file is byte-identical to raw/codex.md lines 430-460"
  else
    bad "S0 layer 1 check_file differs from raw/codex.md lines 430-460"
  fi
else
  echo "S0 raw/codex.md not readable at $raw; verbatim proof skipped here (see the macOS log)"
fi
if diff <(sed -n '/^r46_check_headers() {/,$p' "$here/checker-v2.sh") <(sed -n '/^r46_check_headers() {/,$p' "$here/checker-v3.sh") >/dev/null; then
  ok "S0 r46_check_headers in checker-v3.sh is byte-identical to checker-v2.sh (both layers unchanged)"
else
  bad "S0 r46_check_headers in checker-v3.sh differs from checker-v2.sh"
fi

rm -rf "$work"
mkdir -p "$work"
cp -R "$here/fixture" "$here/lowq" "$here/controls" "$work/"
cp "$here/acceptance-v3.sh" "$here/checker-v3.sh" "$here/acceptance-v2.sh" "$here/checker-v2.sh" "$work/"
export CARGO_TARGET_DIR="$work/target"
fx="$work/fixture"

section "S1 recommended acceptance sequence (acceptance-v3.sh) from the fixture root"
( cd "$fx" && bash "$work/acceptance-v3.sh" ) > "$work/s1.out" 2>&1
s1=$?
indent < "$work/s1.out"
expect_exit "S1 acceptance-v3.sh on the header-free fixture" 0 "$s1"
expect_grep "S1 resolved license printed for the root package" "package r46-fixture license=MIT OR Apache-2.0" "$work/s1.out"
expect_grep "S1 resolved license printed for the member package" "package r46-web license=MIT OR Apache-2.0" "$work/s1.out"

section "S2 checker controls (checker-v3.sh; one NUL-delimited path each)"
# shellcheck disable=SC1091
source "$work/checker-v3.sh"
run_checker() { printf '%s\0' "$@" | r46_check_headers 2>&1; }
control() {
  local out st
  out=$(run_checker "$3"); st=$?
  [[ -n "$out" ]] && printf '%s\n' "$out" | indent
  expect_exit "S2 $1" "$2" "$st"
}
echo "--- revision-1 controls (layer 1 forms, boundaries, texts) ---"
control "clean: leading //! docs"                                   0 "$work/controls/clean.rs"
control "empty (0-byte) file"                                       0 "$work/controls/empty.rs"
control "form (a) SPDX-License-Identifier line"                     1 "$work/controls/form-a.rs"
control "form (b) MIT boilerplate first line (layer 1 only)"        1 "$work/controls/form-b.rs"
control "form (c) Apache appendix boilerplate line"                 1 "$work/controls/form-c.rs"
control "form (d) Apache title then Version line"                   1 "$work/controls/form-d.rs"
control "form (e) MIT title then Copyright (c)"                     1 "$work/controls/form-e.rs"
control "runner-up REUSE two-line header"                           1 "$work/controls/reuse-two-line.rs"
control "boundary: SPDX marker on line 41 (both layers cap at 40)"  0 "$work/controls/after-40.rs"
control "r1 boundary not-d: now caught by layer 2 (f) at line 1"    1 "$work/controls/not-d.rs"
control "r1 boundary not-e: now caught by layer 2 (f) at line 1"    1 "$work/controls/not-e.rs"
control "root LICENSE-APACHE text as a source path (layer 1 only)"  1 "$fx/LICENSE-APACHE"
control "root LICENSE-MIT text as a source path (layer 1 only)"     1 "$fx/LICENSE-MIT"
control "missing path"                                              1 "$work/controls/does-not-exist.rs"
echo "--- layer-1 title-window boundaries re-exercised after a //! line (layer 2 does not apply) ---"
control "l1: //! then Apache title + adjacent Version line"          1 "$work/controls/l1-d-after-docs.rs"
control "l1: //! then Apache title, Version 4 lines later"           0 "$work/controls/l1-not-d-after-docs.rs"
control "l1: //! then MIT title + adjacent Copyright (c)"            1 "$work/controls/l1-e-after-docs.rs"
control "l1: //! then MIT title, Copyright (c) 3 lines later"        0 "$work/controls/l1-not-e-after-docs.rs"
control "l1: //! SPDX-License-Identifier in a doc comment"           1 "$work/controls/doc-spdx.rs"
echo "--- layer-2 negative controls (expect 1) ---"
control "audit-fable counterexample: // Licensed under the MIT license (see LICENSE)" 1 "$work/controls/ff-licensed.rs"
control "audit-codex counterexample: // Copyright … / // Licensed under MIT"          1 "$work/controls/ff-copyright-licensed.rs"
control "clap_builder/src/lib.rs lines 1-6 verbatim (MIT-only header)"                1 "$work/controls/clap-header.rs"
control "pointer: // See LICENSE-MIT and LICENSE-APACHE"                              1 "$work/controls/pointer.rs"
control "copyright sign: // © 2026"                                                   1 "$work/controls/copyright-sign.rs"
control "circled c: // ⓒ 2026"                                                        1 "$work/controls/circled-c.rs"
control "paren c: // (c) 2026"                                                        1 "$work/controls/paren-c.rs"
control "block comment header /* … Copyright … Licensed … */"                         1 "$work/controls/block-header.rs"
control "one-line block comment with SPDX tag (layers 1 and 2)"                       1 "$work/controls/block-oneline.rs"
control "shebang line then // Licensed under MIT"                                     1 "$work/controls/shebang-header.rs"
control "blank lines then // Licensed under MIT"                                      1 "$work/controls/blank-header.rs"
control "//// (four-slash plain comment) Licensed under MIT"                          1 "$work/controls/four-slash-header.rs"
control "false-positive cost: // Parses driver license plates."                       1 "$work/controls/fp-word.rs"
echo "--- layer-2 license-name terms (bounded) ---"
control "name: // Released under MIT"                                                 1 "$work/controls/name-released-mit.rs"
control "name: // MIT OR Apache-2.0 (bare expression)"                                1 "$work/controls/name-bare-expression.rs"
control "name: // Distributed under the Apache-2.0 terms"                             1 "$work/controls/name-apache-terms.rs"
control "false-positive cost: // BSD sockets wrapper"                                 1 "$work/controls/fp-bsd.rs"
control "bound: // Commit hook helpers (mit inside commit)"                           0 "$work/controls/bound-commit.rs"
control "bound: // Template for new modules (mpl inside template)"                    0 "$work/controls/bound-template.rs"
control "bound: // Misc helpers (isc inside misc)"                                    0 "$work/controls/bound-misc.rs"
control "bound: // Simple parser (mpl inside simple)"                                 0 "$work/controls/bound-simple.rs"
echo "--- passes by design (expect 0; each is a stated non-claim) ---"
control "license sentence inside //! crate docs"                                      0 "$work/controls/doc-license-mention.rs"
control "header after an inner attribute line"                                        0 "$work/controls/after-attribute.rs"
control "header after a code line"                                                    0 "$work/controls/after-code.rs"
control "legitimate leading comment: // Generated by build.rs"                        0 "$work/controls/leading-plain-comment.rs"

section "S3 several files through one xargs/awk invocation"
out=$(run_checker "$work/controls/clean.rs" "$fx/src/lib.rs" "$fx/src/main.rs" "$fx/crates/r46-web/src/lib.rs" "$fx/tests/license_metadata.rs" "$fx/examples/print_license.rs" "$work/controls/empty.rs"); st=$?
[[ -n "$out" ]] && printf '%s\n' "$out" | indent
expect_exit "S3 all five fixture .rs files plus clean and empty in one batch" 0 "$st"
out=$(run_checker "$work/controls/clean.rs" "$work/controls/clap-header.rs" "$fx/src/main.rs"); st=$?
printf '%s\n' "$out" | indent
expect_exit "S3 clean, clap header, clean in one batch" 1 "$st"
if printf '%s\n' "$out" | grep -q 'clap-header.rs:1:(f)'; then ok "S3 diagnostic names the offending file, line 1"; else bad "S3 diagnostic missing"; fi
if printf '%s\n' "$out" | grep -q 'clap-header.rs:2:(f)'; then ok "S3 diagnostic also names line 2"; else bad "S3 line-2 diagnostic missing"; fi
if printf '%s\n' "$out" | grep -q -E 'clean.rs:|main.rs:'; then bad "S3 a clean file was reported"; else ok "S3 no clean file reported"; fi

section "S4 whole-sequence inverse controls on fixture copies (acceptance-v3.sh must fail; one pass-by-design)"
no_later_steps() {  # $1 label, $2 output file: nothing after the failed step may have run
  if grep -q -E 'Compiling|Packaging|Diff in' "$2"; then bad "S4 $1: cargo fmt/test/package ran after the failed step"; else ok "S4 $1: no cargo fmt/test/package step ran after the failed step"; fi
}
no_header_check() {  # $1 label, $2 output file: the header check must not have run either
  if grep -q -E ':[0-9]+:\([a-f]\)' "$2"; then bad "S4 $1: the header check ran after the failed manifest step"; else ok "S4 $1: the header check did not run (manifest step failed first)"; fi
}
echo "--- header controls (revision 2 set, unchanged) ---"
for pair in "clap-header.rs:src/header.rs:1:(f)" "form-a.rs:src/header.rs:1:(a)"; do
  ctl="${pair%%:*}"; want="${pair#*:}"
  bad_fx="$work/fixture-bad-${ctl%.rs}"
  rm -rf "$bad_fx"; cp -R "$fx" "$bad_fx"
  cp "$work/controls/$ctl" "$bad_fx/src/header.rs"
  ( cd "$bad_fx" && bash "$work/acceptance-v3.sh" ) > "$work/s4-$ctl.out" 2>&1
  s4=$?
  indent < "$work/s4-$ctl.out"
  expect_exit "S4 acceptance-v3.sh with src/header.rs = $ctl" 1 "$s4"
  expect_grep "S4 diagnostic for $ctl" "$want" "$work/s4-$ctl.out"
  expect_grep "S4 failure message for $ctl" "unexpected prohibited per-file license form or header-check failure" "$work/s4-$ctl.out"
  no_later_steps "$ctl" "$work/s4-$ctl.out"
done

echo "--- manifest controls (revision 3; audit-codex r2 F1 and behavior (5)) ---"
# (1) The r2 auditor's exact admitted mutation: the member declares GPL-3.0-only and its own unit-test
#     assertion is changed to match; the root manifest stays MIT OR Apache-2.0. Only the all-package
#     metadata assertion can catch this.
bad_fx="$work/fixture-bad-member-gpl"
rm -rf "$bad_fx"; cp -R "$fx" "$bad_fx"
sed 's/^license.workspace = true$/license = "GPL-3.0-only"/' "$fx/crates/r46-web/Cargo.toml" > "$bad_fx/crates/r46-web/Cargo.toml"
sed 's/assert_eq!(env!("CARGO_PKG_LICENSE"), "MIT OR Apache-2.0")/assert_eq!(env!("CARGO_PKG_LICENSE"), "GPL-3.0-only")/' "$fx/crates/r46-web/src/lib.rs" > "$bad_fx/crates/r46-web/src/lib.rs"
echo "    mutated crates/r46-web/Cargo.toml:"; grep -n '^license' "$bad_fx/crates/r46-web/Cargo.toml" | indent
echo "    mutated crates/r46-web/src/lib.rs:"; grep -n 'CARGO_PKG_LICENSE' "$bad_fx/crates/r46-web/src/lib.rs" | indent
echo "    root Cargo.toml unchanged:"; grep -n '^license' "$bad_fx/Cargo.toml" | indent
( cd "$bad_fx" && bash "$work/acceptance-v3.sh" ) > "$work/s4-member-gpl.out" 2>&1
s4=$?
indent < "$work/s4-member-gpl.out"
expect_exit "S4 acceptance-v3.sh with crates/r46-web declaring license = GPL-3.0-only (root unchanged, member test assertion matched)" 1 "$s4"
expect_grep "S4 divergent member named" "r46-web " "$work/s4-member-gpl.out"
expect_grep "S4 divergent member's manifest path named" "crates/r46-web/Cargo.toml license=GPL-3.0-only" "$work/s4-member-gpl.out"
expect_grep "S4 failure message for the divergent member" 'workspace package license is not "MIT OR Apache-2.0" (packages: 2)' "$work/s4-member-gpl.out"
no_header_check "member-gpl" "$work/s4-member-gpl.out"
no_later_steps "member-gpl" "$work/s4-member-gpl.out"
echo "    --- the same copy through revision 2's acceptance-v2.sh (F1 defect reproduction; expected exit 0) ---"
( cd "$bad_fx" && bash "$work/acceptance-v2.sh" ) > "$work/s4-member-gpl-v2.out" 2>&1
s4v2=$?
grep -E '^license|Packaged|test result|error' "$work/s4-member-gpl-v2.out" | indent
expect_exit "S4 F1 reproduced: acceptance-v2.sh admits the divergent member" 0 "$s4v2"
( cd "$bad_fx" && cargo metadata --no-deps --format-version 1 | jq -r '.packages[] | "\(.name) license=\(.license)"' ) | indent

# (2) A member with no license key at all (`.license` is null in cargo metadata).
bad_fx="$work/fixture-bad-member-none"
rm -rf "$bad_fx"; cp -R "$fx" "$bad_fx"
grep -v '^license' "$fx/crates/r46-web/Cargo.toml" > "$bad_fx/crates/r46-web/Cargo.toml"
echo "    mutated crates/r46-web/Cargo.toml (no license key):"; indent < "$bad_fx/crates/r46-web/Cargo.toml"
( cd "$bad_fx" && bash "$work/acceptance-v3.sh" ) > "$work/s4-member-none.out" 2>&1
s4=$?
indent < "$work/s4-member-none.out"
expect_exit "S4 acceptance-v3.sh with crates/r46-web carrying no license key" 1 "$s4"
expect_grep "S4 member without a license key named with license=null" "crates/r46-web/Cargo.toml license=null" "$work/s4-member-none.out"
no_header_check "member-none" "$work/s4-member-none.out"
no_later_steps "member-none" "$work/s4-member-none.out"

# (3) Root expression changed (behavior (5) "the manifest expression changes"): the grep -Fx
#     prerequisite fails silently under set -e, before the metadata assertion.
bad_fx="$work/fixture-bad-root-mit"
rm -rf "$bad_fx"; cp -R "$fx" "$bad_fx"
sed 's/^license = "MIT OR Apache-2.0"$/license = "MIT"/' "$fx/Cargo.toml" > "$bad_fx/Cargo.toml"
echo "    mutated root Cargo.toml:"; grep -n '^license' "$bad_fx/Cargo.toml" | indent
( cd "$bad_fx" && bash "$work/acceptance-v3.sh" ) > "$work/s4-root-mit.out" 2>&1
s4=$?
indent < "$work/s4-root-mit.out"
expect_exit "S4 acceptance-v3.sh with the root expression changed to MIT" 1 "$s4"
if grep -q '^package ' "$work/s4-root-mit.out"; then bad "S4 root-mit: the metadata step ran after the failed grep"; else ok "S4 root-mit: failed at the grep -Fx prerequisite (silent exit 1 under set -e; no package line printed)"; fi
no_header_check "root-mit" "$work/s4-root-mit.out"
no_later_steps "root-mit" "$work/s4-root-mit.out"

# (4) A root license text missing (behavior (5) "a root file is missing").
bad_fx="$work/fixture-bad-no-license-mit"
rm -rf "$bad_fx"; cp -R "$fx" "$bad_fx"
rm "$bad_fx/LICENSE-MIT"
( cd "$bad_fx" && bash "$work/acceptance-v3.sh" ) > "$work/s4-no-license-mit.out" 2>&1
s4=$?
indent < "$work/s4-no-license-mit.out"
expect_exit "S4 acceptance-v3.sh with LICENSE-MIT removed" 1 "$s4"
if grep -q -E '^license = |^package ' "$work/s4-no-license-mit.out"; then bad "S4 no-license-mit: a later prerequisite ran"; else ok "S4 no-license-mit: failed at test -s LICENSE-MIT (silent exit 1 under set -e)"; fi
no_later_steps "no-license-mit" "$work/s4-no-license-mit.out"

# (5) Pass by design: a member that declares the expression directly instead of inheriting it.
#     The assertion checks the resolved value, so this is permitted ("inherit or directly declare").
ok_fx="$work/fixture-ok-member-direct"
rm -rf "$ok_fx"; cp -R "$fx" "$ok_fx"
sed 's/^license.workspace = true$/license = "MIT OR Apache-2.0"/' "$fx/crates/r46-web/Cargo.toml" > "$ok_fx/crates/r46-web/Cargo.toml"
echo "    mutated crates/r46-web/Cargo.toml:"; grep -n '^license' "$ok_fx/crates/r46-web/Cargo.toml" | indent
( cd "$ok_fx" && bash "$work/acceptance-v3.sh" ) > "$work/s4-member-direct.out" 2>&1
s4=$?
grep -E '^license|^package|Packaged|test result' "$work/s4-member-direct.out" | indent
expect_exit "S4 pass by design: member declares license = \"MIT OR Apache-2.0\" directly" 0 "$s4"
expect_grep "S4 member-direct resolved value printed" "package r46-web license=MIT OR Apache-2.0" "$work/s4-member-direct.out"

section "S5 cargo metadata listing and the all-package predicate (informational; enforced by acceptance-v3.sh in S1/S4)"
( cd "$fx" && cargo metadata --no-deps --format-version 1 | jq -r '.packages[] | "\(.name) \(.version) license=\(.license) edition=\(.edition) rust-version=\(.rust_version)"' ) | indent
( cd "$fx" && cargo metadata --no-deps --format-version 1 | jq -e '.packages | length > 0 and all(.license == "MIT OR Apache-2.0")' >/dev/null ); st=$?
expect_exit "S5 all packages (length > 0) report license = MIT OR Apache-2.0" 0 "$st"

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
expect_exit "S8 header-first src/lib.rs is rejected by the checker (forms a and f)" 1 "$st"
out=$(run_checker "$work/lowq/docs-only/src/lib.rs"); st=$?
expect_exit "S8 docs-only src/lib.rs passes the checker" 0 "$st"

section "summary"
printf 'summary: PASS=%d FAIL=%d\n' "$PASS" "$FAIL"
if [[ "$FAIL" -eq 0 ]]; then echo "RESULT: PASS"; exit 0; else echo "RESULT: FAIL"; exit 1; fi
