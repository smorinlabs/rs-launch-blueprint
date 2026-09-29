#!/usr/bin/env bash
# R29 revision 1 — provision the recommended stack for the empirical checks:
# (1) the dprint 0.57.4 host from crates.io into the private CARGO_HOME
#     (`cargo install --locked`; skipped when that exact version is present —
#     the first, compiling run is kept at build/cargo-install-dprint.log);
# (2) the four recommended dprint Wasm plugins, built from source,
# because plugins.dprint.dev and GitHub release-asset downloads are outside the
# endpoints the R29 prompt names. Sources: the published .crate files from
# crates.io (json 0.24.0, markdown 0.24.0, toml 0.8.0, pretty_yaml 0.6.0) and,
# for pretty_yaml's unpublished `dprint_plugin` wrapper (publish = false), the
# three files at tag v0.6.0 snapshotted from api.github.com by r29-snapshots.sh.
# Toolchain: rustup 1.93.0, the only local toolchain carrying wasm32-unknown-unknown.
# Output: $PLUGIN_OUT/{json,markdown,toml,pretty_yaml}.wasm plus SHA256SUMS.
# These modules are built from the tagged sources; they are NOT the published
# release bytes, so their digests are not the checksum pins (see DECISION.md).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
work="${R29_WORK:-/tmp/r29-plugins}"
out="${PLUGIN_OUT:-$work/out}"
tc=1.93.0-aarch64-apple-darwin
ua='rs-launch-blueprint-R29-synthesis'
mkdir -p "$work/src" "$out"
: "${CARGO_HOME:?a private CARGO_HOME must be set}"
if [ "$("$CARGO_HOME/bin/dprint" --version 2>/dev/null)" != "dprint 0.57.4" ]; then
  env -u CARGO_TARGET_DIR /opt/homebrew/bin/cargo install dprint --version 0.57.4 --locked
fi
"$CARGO_HOME/bin/dprint" --version
export CARGO_TARGET_DIR="$work/target"
# `rustup run` resolves Homebrew's rustc under a private CARGO_HOME on this host,
# so the toolchain's own binaries are called by absolute path.
tcbin="$HOME/.rustup/toolchains/$tc/bin"
export RUSTC="$tcbin/rustc" PATH="$tcbin:$PATH"
"$tcbin/cargo" --version
"$RUSTC" --version
test -d "$("$RUSTC" --print sysroot)/lib/rustlib/wasm32-unknown-unknown/lib"

fetch_crate() { # name version -> $work/src/name-version
  local name="$1" ver="$2"
  if [ ! -d "$work/src/$name-$ver" ]; then
    curl -sSfL -A "$ua" "https://crates.io/api/v1/crates/$name/$ver/download" -o "$work/src/$name-$ver.crate"
    tar -xzf "$work/src/$name-$ver.crate" -C "$work/src"
  fi
  printf '%s\n' "$work/src/$name-$ver"
}

build_feature_wasm() { # name version outname
  local dir
  dir="$(fetch_crate "$1" "$2")"
  (cd "$dir" && rm -f Cargo.lock.orig && "$tcbin/cargo" build --release --target wasm32-unknown-unknown --features wasm --lib)
  cp "$CARGO_TARGET_DIR/wasm32-unknown-unknown/release/${1//-/_}.wasm" "$out/$3.wasm"
}

build_feature_wasm dprint-plugin-json 0.24.0 json
build_feature_wasm dprint-plugin-markdown 0.24.0 markdown
build_feature_wasm dprint-plugin-toml 0.8.0 toml

# pretty_yaml: published library crate + the tag's dprint_plugin wrapper files.
fetch_crate pretty_yaml 0.6.0 >/dev/null
py="$work/src/dprint_plugin_yaml-0.6.0"
mkdir -p "$py/src"
sed 's#^pretty_yaml = { path = "../pretty_yaml", #pretty_yaml = { version = "=0.6.0", #' \
  "$here/snapshots/pretty_yaml-dprint_plugin-Cargo.toml" >"$py/Cargo.toml"
grep -q '^pretty_yaml = { version = "=0.6.0", features = \["config_serde"\] }' "$py/Cargo.toml"
printf '\n[workspace]\n' >>"$py/Cargo.toml"
cp "$here/snapshots/pretty_yaml-dprint_plugin-lib.rs" "$py/src/lib.rs"
cp "$here/snapshots/pretty_yaml-dprint_plugin-config.rs" "$py/src/config.rs"
# lib.rs embeds include_str!("../../LICENSE"): the tag's root LICENSE, two levels up.
cp "$here/snapshots/pretty_yaml-LICENSE" "$work/src/LICENSE"
(cd "$py" && "$tcbin/cargo" build --release --target wasm32-unknown-unknown --lib)
cp "$CARGO_TARGET_DIR/wasm32-unknown-unknown/release/dprint_plugin_yaml.wasm" "$out/pretty_yaml.wasm"

(cd "$out" && shasum -a 256 json.wasm markdown.wasm toml.wasm pretty_yaml.wasm | tee SHA256SUMS)
ls -l "$out"
echo "r29-provision: OK"
