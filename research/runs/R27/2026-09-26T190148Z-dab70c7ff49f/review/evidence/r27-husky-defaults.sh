#!/usr/bin/env bash
# R27 revision 3, check F11 — one-shot read of cargo-husky's default feature set and the
# build.rs lines that add `cargo fmt --check`. Endpoint: api.github.com repos/<o>/<r>/contents
# only (the prompt's evidence table, as in r27-figures.sh). Each call runs exactly once;
# nothing polls. An API failure prints "NO DATA" and is never counted as a value.
# Observations only: no PASS/FAIL assertions.
set -uo pipefail
GH=/opt/homebrew/bin/gh
echo "== retrieved $(date -u +%Y-%m-%dT%H:%M:%SZ); $("$GH" --version | head -1)"
fetch() { # fetch <owner/repo> <path> -> decoded file on stdout, or empty
  "$GH" api "repos/$1/contents/$2" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null
}

echo
echo "-- F11a GET repos/rhysd/cargo-husky/contents/Cargo.toml: [features] table (numbered lines)"
cargo_toml=$(fetch rhysd/cargo-husky Cargo.toml)
if [ -z "$cargo_toml" ]; then echo "   NO DATA (Cargo.toml)"; else
  printf '%s\n' "$cargo_toml" | awk '/^\[/{f=($0=="[features]")} f{printf "   %d: %s\n", NR, $0}'
fi

echo
echo "-- F11b GET repos/rhysd/cargo-husky/contents/build.rs: lines 130-150 (numbered)"
build_rs=$(fetch rhysd/cargo-husky build.rs)
if [ -z "$build_rs" ]; then echo "   NO DATA (build.rs)"; else
  printf '%s\n' "$build_rs" | awk 'NR>=130 && NR<=150 {printf "   %d: %s\n", NR, $0}'
  echo "   hook-kind selection (every line naming a *-hook feature):"
  printf '%s\n' "$build_rs" | awk '/feature = "(pre|post)[a-z-]*-hook"/ {printf "   %d: %s\n", NR, $0}'
fi
