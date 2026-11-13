#!/usr/bin/env bash
# R27 synthesis check C1 — the rustfmt.toml config surface (F087, F089, F091, F092).
# Runs the recommended five-key file, each disputed unstable key, the `edition`
# disagreement and the style behaviours on four rustfmt builds that exist on this host.
# No network: RUSTUP_AUTO_INSTALL=0 makes a missing toolchain an error, never a download.
set -uo pipefail
export PATH="$HOME/.cargo/bin:/usr/bin:/bin"
export RUSTUP_AUTO_INSTALL=0
mkdir -p "${TMPDIR:-/tmp}/r27s"
ROOT="$(cd "${TMPDIR:-/tmp}/r27s" && pwd -P)/config"
rm -rf "$ROOT" && mkdir -p "$ROOT"
PASS=0; FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  PASS $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
nocolor() { sed -e $'s/\x1b\\[[0-9;]*m//g' -e $'s/\x1b(B//g' -e "s|$ROOT/||g" -e "s|/private$ROOT/||g"; }

# Builds: label -> command prefix. Homebrew's rustfmt is the build shipped with rustc 1.98.1.
BUILDS=("rustup-1.94.0-stable" "rustup-1.96.0" "rustup-1.96.1" "homebrew-1.98.1")
fmt_cmd() {
  case "$1" in
    rustup-1.94.0-stable) echo "rustup run stable rustfmt" ;;
    rustup-1.96.0)        echo "rustup run 1.96.0 rustfmt" ;;
    rustup-1.96.1)        echo "rustup run 1.96 rustfmt" ;;
    homebrew-1.98.1)      echo "/opt/homebrew/bin/rustfmt" ;;
  esac
}

echo "== host: $(uname -srm); sw_vers $(sw_vers -productVersion 2>/dev/null)"
for b in "${BUILDS[@]}"; do
  # shellcheck disable=SC2046
  echo "== build $b: $($(fmt_cmd "$b") --version 2>&1)"
done
echo "== homebrew rustc: $(/opt/homebrew/bin/rustc --version)"

RECOMMENDED=$(cat <<'EOF'
# Rust source formatting (R27). Every key is stable: no nightly toolchain is needed.
edition = "2024"        # bare rustfmt callers parse 2024 syntax; cargo fmt passes Cargo.toml's edition
style_edition = "2024"  # the 2024 style edition
max_width = 100         # F087: rustfmt's default width, stated
newline_style = "Unix"  # F089: LF bytes on every OS; "Auto" keeps whatever a file already has
reorder_imports = true  # F092: the formatter owns import order (rustfmt's default, stated)
EOF
)

FORMATTED='use std::io::{Read, Write};

pub fn f(r: &mut impl Read, w: &mut impl Write) -> std::io::Result<()> {
    let mut s = String::new();
    r.read_to_string(&mut s)?;
    w.write_all(s.as_bytes())
}'

# probe <dir> <config-text> <build> -> sets RC and WARN (count of "can't set" lines)
probe() {
  local dir="$1" cfg="$2" b="$3"
  mkdir -p "$dir"
  printf '%s\n' "$cfg" > "$dir/rustfmt.toml"
  printf '%s\n' "$FORMATTED" > "$dir/lib.rs"
  local out
  # shellcheck disable=SC2046
  out=$( cd "$dir" && $(fmt_cmd "$b") --check --edition 2024 lib.rs 2>&1 ); RC=$?
  WARN=$(grep -c "can't set" <<<"$out")
  LAST_OUT="$out"
}

echo
echo "== C1.1 the recommended rustfmt.toml, byte for byte: exit 0 and zero warnings on every build"
printf '%s\n' "$RECOMMENDED" | sed 's/^/    | /'
echo "    sha256 of the file as written: $(printf '%s\n' "$RECOMMENDED" | shasum -a 256 | cut -c1-64)"
for b in "${BUILDS[@]}"; do
  probe "$ROOT/rec-$b" "$RECOMMENDED" "$b"
  if [ "$RC" -eq 0 ] && [ "$WARN" -eq 0 ] && [ -z "$LAST_OUT" ]; then ok "$b exit=$RC warnings=$WARN output=empty"
  else bad "$b exit=$RC warnings=$WARN"; printf '%s\n' "$LAST_OUT" | nocolor | sed 's/^/    | /'; fi
done

echo
echo "== C1.2 each stable key alone is silent (style_edition included; Configurations.md@v1.9.0 still marks it unstable per the Opus leg)"
for key in 'edition = "2024"' 'style_edition = "2024"' 'max_width = 100' 'newline_style = "Unix"' 'reorder_imports = true'; do
  for b in "${BUILDS[@]}"; do
    probe "$ROOT/stable-$b-${key%% *}" "$key" "$b"
    if [ "$RC" -eq 0 ] && [ "$WARN" -eq 0 ]; then ok "$b [$key] exit=0 warnings=0"
    else bad "$b [$key] exit=$RC warnings=$WARN"; fi
  done
done

echo
echo "== C1.3 each disputed unstable key: warned, ignored, and exit status still 0 on a formatted file"
for key in 'trailing_comma = "Never"' 'imports_granularity = "Crate"' 'group_imports = "StdExternalCrate"' 'imports_layout = "Vertical"' 'ignore = ["lib.rs"]'; do
  for b in "${BUILDS[@]}"; do
    probe "$ROOT/unstable-$b-${key%% *}" "$key" "$b"
    if [ "$RC" -eq 0 ] && [ "$WARN" -ge 1 ]; then ok "$b [$key] exit=0 warnings=$WARN"
    else bad "$b [$key] exit=$RC warnings=$WARN"; fi
  done
  echo "    | $(grep -m1 "can't set" <<<"$LAST_OUT")"
done
echo "-- C1.3b ignore = [\"lib.rs\"] on an UNFORMATTED lib.rs: the listed file is still checked (the key has no effect)"
for b in "${BUILDS[@]}"; do
  d="$ROOT/ignore-effect-$b"; mkdir -p "$d"
  printf 'ignore = ["lib.rs"]\n' > "$d/rustfmt.toml"; printf 'pub fn f( ) {}\n' > "$d/lib.rs"
  # shellcheck disable=SC2046
  out=$( cd "$d" && $(fmt_cmd "$b") --check --edition 2024 lib.rs 2>&1 ); rc=$?
  if [ "$rc" -eq 1 ] && grep -q "Diff in" <<<"$out"; then ok "$b ignore listed file still diffed, exit=1"
  else bad "$b exit=$rc"; fi
done

echo
echo "== C1.4 the \`edition\` key (Muse omits it, Opus sets it): bare rustfmt on edition-2024 syntax"
LETCHAIN='pub fn f(a: Option<u32>) -> bool {
    if let Some(x) = a && x > 1 { true } else { false }
}'
for cfg in "NONE" 'style_edition = "2024"' 'edition = "2024"'; do
  for b in rustup-1.96.0 homebrew-1.98.1; do
    d="$ROOT/edition-$b-${cfg%% *}"; mkdir -p "$d"
    if [ "$cfg" != "NONE" ]; then printf '%s\n' "$cfg" > "$d/rustfmt.toml"; fi
    printf '%s\n' "$LETCHAIN" > "$d/lib.rs"
    # bare rustfmt with NO --edition flag: what an editor plugin or a `rustfmt` pre-commit entry runs
    # shellcheck disable=SC2046
    out=$( cd "$d" && $(fmt_cmd "$b") --check lib.rs 2>&1 ); rc=$?
    if grep -q "let chains are only allowed in Rust 2024" <<<"$out"; then verdict="PARSE-ERROR"; else verdict="parsed"; fi
    echo "    config=[$cfg] $b: exit=$rc $verdict"
    case "$cfg" in
      NONE|style_edition*) if [ "$verdict" = "PARSE-ERROR" ]; then ok "[$cfg] $b bare rustfmt rejects 2024 syntax"; else bad "[$cfg] $b expected parse error"; fi ;;
      edition*)            if [ "$verdict" = "parsed" ]; then ok "[$cfg] $b bare rustfmt parses 2024 syntax"; else bad "[$cfg] $b expected parse"; fi ;;
    esac
  done
done
echo "-- C1.4b precedence: rustfmt.toml says edition = \"2021\", Cargo.toml says 2024; cargo fmt passes Cargo's edition"
d="$ROOT/edition-precedence"; mkdir -p "$d/src"
printf '[package]\nname = "p"\nversion = "0.1.0"\nedition = "2024"\n' > "$d/Cargo.toml"
printf 'edition = "2021"\n' > "$d/rustfmt.toml"
printf '%s\n' "$LETCHAIN" > "$d/src/lib.rs"
out=$( cd "$d" && rustup run 1.96.0 cargo fmt --all --check -v 2>&1 ); rc=$?
grep -m1 '^rustfmt ' <<<"$out" | nocolor | sed 's/^/    | /'
if ! grep -q "let chains are only allowed" <<<"$out" && grep -q -- '--edition 2024' <<<"$out"; then ok "cargo fmt ran rustfmt --edition 2024 over a 2021 rustfmt.toml; no parse error (exit=$rc, a layout diff only)"
else bad "precedence exit=$rc"; printf '%s\n' "$out" | nocolor | sed 's/^/    | /'; fi

echo
echo "== C1.5 behaviours under the recommended file (rustup 1.96.0 and homebrew 1.98.1)"
for b in rustup-1.96.0 homebrew-1.98.1; do
  d="$ROOT/behave-$b"; mkdir -p "$d"
  printf '%s\n' "$RECOMMENDED" > "$d/rustfmt.toml"
  # F089: CRLF file
  printf 'pub fn f() {}\r\n' > "$d/crlf.rs"
  # shellcheck disable=SC2046
  out=$( cd "$d" && $(fmt_cmd "$b") --check --edition 2024 crlf.rs 2>&1 ); rc=$?
  if [ "$rc" -eq 1 ] && grep -q "Incorrect newline style" <<<"$out"; then ok "$b F089 Unix: CRLF file -> 'Incorrect newline style', exit=1"; else bad "$b F089 Unix exit=$rc"; fi
  d2="$ROOT/behave-auto-$b"; mkdir -p "$d2"; printf 'newline_style = "Auto"\n' > "$d2/rustfmt.toml"; cp "$d/crlf.rs" "$d2/"
  # shellcheck disable=SC2046
  ( cd "$d2" && $(fmt_cmd "$b") --check --edition 2024 crlf.rs >/dev/null 2>&1 ); rc=$?
  if [ "$rc" -eq 0 ]; then ok "$b F089 Auto: the same CRLF file passes, exit=0"; else bad "$b F089 Auto exit=$rc"; fi
  # F092: import ordering (formatter-owned)
  printf 'use std::io::{Write, Read};\nuse std::fmt;\nuse std::collections::HashMap;\n' > "$d/imports.rs"
  # shellcheck disable=SC2046
  ( cd "$d" && $(fmt_cmd "$b") --edition 2024 imports.rs >/dev/null 2>&1 )
  got=$(tr '\n' '|' < "$d/imports.rs")
  if [ "$got" = "use std::collections::HashMap;|use std::fmt;|use std::io::{Read, Write};|" ]; then ok "$b F092 reorder: $got"; else bad "$b F092 got $got"; fi
  # F091: default trailing_comma = Vertical adds a trailing comma to a vertical list
  printf 'pub struct S { pub a: u32, pub b: u32 }\n' > "$d/tc.rs"
  # shellcheck disable=SC2046
  ( cd "$d" && $(fmt_cmd "$b") --edition 2024 tc.rs >/dev/null 2>&1 )
  if grep -q '^    pub b: u32,$' "$d/tc.rs"; then ok "$b F091 Vertical: '$(tr '\n' '|' < "$d/tc.rs")'"; else bad "$b F091 $(tr '\n' '|' < "$d/tc.rs")"; fi
  # F087: explicit max_width = 100 changes nothing relative to no file (it restates the default)
  long='pub fn g() -> u64 { let aaaaaaaaaaaaaaaa = 1u64; let bbbbbbbbbbbbbbbb = 2u64; aaaaaaaaaaaaaaaa + bbbbbbbbbbbbbbbb + aaaaaaaaaaaaaaaa * bbbbbbbbbbbbbbbb }'
  d3="$ROOT/width-none-$b"; d4="$ROOT/width-100-$b"; mkdir -p "$d3" "$d4"; printf 'max_width = 100\n' > "$d4/rustfmt.toml"
  printf '%s\n' "$long" > "$d3/w.rs"; printf '%s\n' "$long" > "$d4/w.rs"
  # shellcheck disable=SC2046
  ( cd "$d3" && $(fmt_cmd "$b") --edition 2024 w.rs >/dev/null 2>&1 ); ( cd "$d4" && $(fmt_cmd "$b") --edition 2024 w.rs >/dev/null 2>&1 )
  if cmp -s "$d3/w.rs" "$d4/w.rs"; then ok "$b F087 max_width = 100 output byte-identical to the default"; else bad "$b F087 outputs differ"; fi
done

echo
echo "== summary: $((PASS + FAIL)) checks, $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
