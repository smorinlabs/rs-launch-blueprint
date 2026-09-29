#!/usr/bin/env bash
# R27 synthesis check C4 — the rust-toolchain.toml channel (F103/F190): numeric pin (Opus)
# versus channel = "stable" (Muse). Exercises the recommended file shape at exact channels
# installed on this host, shows what "stable" resolves to here, shows the recommended value
# 1.98.1 cannot be exercised offline, and compares formatter output across four rustfmt builds.
# No network: RUSTUP_AUTO_INSTALL=0 turns a missing toolchain into an error, never a download.
set -uo pipefail
export PATH="$HOME/.cargo/bin:/usr/bin:/bin"
export RUSTUP_AUTO_INSTALL=0 NO_COLOR=1
mkdir -p "${TMPDIR:-/tmp}/r27s"
ROOT="$(cd "${TMPDIR:-/tmp}/r27s" && pwd -P)/pin"
rm -rf "$ROOT" && mkdir -p "$ROOT"
PASS=0; FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  PASS $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL $1"; }
clean() { sed -e "s|$ROOT/||g"; }

crate() { # crate <dir> <channel>
  mkdir -p "$1/src"
  printf '[package]\nname = "p"\nversion = "0.1.0"\nedition = "2024"\nrust-version = "1.91"\n' > "$1/Cargo.toml"
  printf 'pub fn run() {}\n' > "$1/src/lib.rs"
  printf '[toolchain]\nchannel = "%s"\nprofile = "minimal"\ncomponents = ["rustfmt", "clippy"]\n' "$2" > "$1/rust-toolchain.toml"
}

echo "== $(rustup --version 2>/dev/null | head -1); host $(uname -srm)"
echo "== installed toolchains: $(rustup toolchain list | tr '\n' ';')"

echo
echo "== C4.1 exact pins that are installed with both components: the file is honoured"
for ch in 1.93.0 1.96; do
  d="$ROOT/exact-$ch"; crate "$d" "$ch"
  act=$(cd "$d" && rustup show active-toolchain 2>&1)
  fv=$(cd "$d" && cargo fmt --version 2>&1)
  cv=$(cd "$d" && cargo clippy --version 2>&1)
  comps=$(cd "$d" && rustup component list --installed 2>&1 | grep -E '^(rustfmt|clippy)-' | tr '\n' ' ')
  echo "    channel=\"$ch\": active=[$(clean <<<"$act")] fmt=[$fv] clippy=[$cv] installed=[$comps]"
  if grep -q "overridden by '.*rust-toolchain.toml'" <<<"$act" && grep -q '^rustfmt ' <<<"$fv" && grep -q '^clippy ' <<<"$cv" && [ "$(wc -w <<<"$comps")" -eq 2 ]; then
    ok "channel \"$ch\" + profile minimal + [rustfmt, clippy]: override active, both components present (R42's presence test passes)"
  else bad "channel $ch"; fi
  ( cd "$d" && cargo fmt --all --check >/dev/null 2>&1 ); rc=$?
  if [ "$rc" -eq 0 ]; then ok "channel \"$ch\": cargo fmt --all --check exit=0"; else bad "channel $ch check rc=$rc"; fi
done

echo
echo "== C4.2 channel = \"stable\" resolves to whatever this machine last installed as stable"
d="$ROOT/stable"; crate "$d" stable
act=$(cd "$d" && rustup show active-toolchain 2>&1); fv=$(cd "$d" && cargo fmt --version 2>&1); rv=$(cd "$d" && rustc --version 2>&1)
echo "    channel=\"stable\": active=[$(clean <<<"$act")] rustc=[$rv] fmt=[$fv]"
if grep -q '^rustc 1.94.0' <<<"$rv"; then ok "\"stable\" here is rustc 1.94.0 — four minor releases behind the 1.98.1 release (see r27-figures.log F1); the same file names a different toolchain on each machine"; else bad "stable resolved to $rv"; fi

echo
echo "== C4.3 the recommended value channel = \"1.98.1\" is not installed under rustup here"
d="$ROOT/v1981"; crate "$d" 1.98.1
out=$(cd "$d" && cargo fmt --version 2>&1); rc=$?
echo "    $(head -1 <<<"$out")"
if [ "$rc" -ne 0 ] && grep -q "is not installed" <<<"$out"; then ok "1.98.1 pin fails closed with RUSTUP_AUTO_INSTALL=0 (exit=$rc): the value itself is not exercised on this host"; else bad "rc=$rc"; fi

echo
echo "== C4.4 PATH hazard (R42's): Homebrew's cargo-fmt ahead of the rustup proxy ignores the file"
d="$ROOT/exact-1.93.0"
fv=$(cd "$d" && PATH="/opt/homebrew/bin:$PATH" cargo fmt --version 2>&1)
act=$(cd "$d" && PATH="/opt/homebrew/bin:$PATH" rustup show active-toolchain 2>&1)
echo "    in a dir pinning 1.93.0 with /opt/homebrew/bin first: fmt=[$fv]; rustup still reports [$(clean <<<"$act")]"
if [ "$fv" = "rustfmt 1.9.0" ]; then ok "the pin is bypassed when a non-rustup cargo-fmt resolves first (rustup build would print 1.8.0-stable)"; else bad "got $fv"; fi

echo
echo "== C4.5 does the rustfmt build change the output? (RFC 2437's promise for default options)"
SAMPLE='use std::collections::HashMap;
use std::io::{self, Read, Write};

pub struct Config {
    pub name: String,
    pub values: HashMap<String, Vec<u64>>,
}

pub fn load(mut r: impl Read, w: &mut impl Write) -> io::Result<Config> {
    let mut s = String::new();
    r.read_to_string(&mut s)?;
    let values = s
        .lines()
        .filter_map(|l| l.split_once(\x27=\x27))
        .map(|(k, v)| (k.trim().to_owned(), v.split(\x27,\x27).filter_map(|n| n.trim().parse().ok()).collect()))
        .collect();
    if let Some(first) = s.lines().next() && !first.is_empty() {
        writeln!(w, "first line: {first}")?;
    }
    Ok(Config { name: String::from("sample"), values })
}'
sums=""
for b in "1.93.0" "stable" "1.96" "homebrew"; do
  d="$ROOT/out-$b"; mkdir -p "$d"
  printf 'edition = "2024"\nstyle_edition = "2024"\nmax_width = 100\nnewline_style = "Unix"\nreorder_imports = true\n' > "$d/rustfmt.toml"
  printf '%b\n' "$SAMPLE" > "$d/lib.rs"
  if [ "$b" = homebrew ]; then ( cd "$d" && /opt/homebrew/bin/rustfmt lib.rs ); v=$(/opt/homebrew/bin/rustfmt --version)
  else ( cd "$d" && rustup run "$b" rustfmt lib.rs ); v=$(rustup run "$b" rustfmt --version); fi
  s=$(shasum -a 256 "$d/lib.rs" | cut -c1-16); sums="$sums $s"
  echo "    $b [$v]: formatted sha256 $s"
done
if [ "$(tr ' ' '\n' <<<"$sums" | sed '/^$/d' | sort -u | wc -l | tr -d ' ')" = 1 ]; then ok "byte-identical output from rustfmt 1.8.0 (two builds) and 1.9.0 (two builds) under the recommended file"; else bad "outputs differ:$sums"; fi

echo
echo "== C4.6 what else the channel carries: clippy's lint set, per toolchain (cargo clippy -- -W help)"
d="$ROOT/lints"; mkdir -p "$d/src"
printf '[package]\nname = "p"\nversion = "0.1.0"\nedition = "2021"\n' > "$d/Cargo.toml"; printf 'pub fn f() {}\n' > "$d/src/lib.rs"
for t in 1.93.0 stable 1.96; do
  ( cd "$d" && rustup run "$t" cargo clippy -q -- -W help 2>/dev/null ) \
    | awk '$1 ~ /^clippy::/ {print $1, $2}' | sort -u > "$ROOT/lints-$t.txt"
  echo "    $t [$(rustup run "$t" cargo clippy --version)]: clippy lints=$(wc -l < "$ROOT/lints-$t.txt" | tr -d ' '); warn-by-default=$(awk '$2 == "warn"' "$ROOT/lints-$t.txt" | wc -l | tr -d ' ')"
done
new_warn=$(comm -13 <(awk '$2 == "warn" {print $1}' "$ROOT/lints-stable.txt") <(awk '$2 == "warn" {print $1}' "$ROOT/lints-1.96.txt"))
echo "    warn-by-default lints in 1.96.1 that 1.94.0 lacks: $(wc -l <<<"$new_warn" | tr -d ' ') — $(tr '\n' ' ' <<<"$new_warn")"
if [ -n "$new_warn" ]; then ok "the channel changes clippy's default warn set between 1.94.0 and 1.96.1 (a -D warnings step can turn red with no repository change)"; else bad "no new warn-by-default lints"; fi

echo
echo "== summary: $((PASS + FAIL)) checks, $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
