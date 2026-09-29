#!/usr/bin/env bash
# R29 revision 1 — the Muse leg's TOML pick (taplo-cli 0.10.0) run on the same
# TOML inputs as r29-dprint-stack.sh, to adjudicate Disagreement A/H with
# behaviour rather than download counts. taplo 0.10.0 is the binary already on
# this host's PATH; no .taplo.toml is committed, so the defaults are measured
# unless a check names a config. Needs r29-provision.sh (for the dprint cross-check).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
plugins="${PLUGIN_OUT:-/tmp/r29-plugins/out}"
: "${CARGO_HOME:?a private CARGO_HOME must be set}"
export PATH="$CARGO_HOME/bin:$PATH"
scratch="$(mktemp -d /tmp/r29-taplo.XXXXXX)"
export DPRINT_CACHE_DIR="$scratch/dprint-cache"
w="$scratch/tree"
pass=0 fail=0
ok()  { pass=$((pass + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
bad() { fail=$((fail + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
expect_exit() {
  local id="$1" desc="$2" want="$3" got=0; shift 3
  "$@" >"$scratch/last.out" 2>&1 || got=$?
  if [ "$got" = "$want" ]; then ok "$id" "$desc (exit $got)"; else bad "$id" "$desc (exit $got, wanted $want)"; sed 's/^/    | /' "$scratch/last.out" | head -20; fi
}
g() { git -c user.email=r29@example.invalid -c user.name=r29 "$@"; }
order() { # file section -> comma-joined key order
  python3 - "$1" "$2" <<'EOF'
import re, sys
sec, keys = None, {}
for line in open(sys.argv[1]):
    m = re.match(r"^\[([^\]]+)\]\s*$", line)
    if m: sec = m.group(1); keys[sec] = []; continue
    m = re.match(r"^([A-Za-z0-9_-]+)\s*=", line)
    if m and sec: keys[sec].append(m.group(1))
print(",".join(keys.get(sys.argv[2], [])))
EOF
}

cp -R "$here/fixtures/tree" "$w"
cp "$here/fixtures/gitignore.fixture" "$w/.gitignore"
mkdir -p "$w/target/debug"
printf 'a   =   1\n' >"$w/target/debug/decoy.toml"
cd "$w"
g init -q && g add -A && g commit -qm authored
echo "taplo: $(command -v taplo) -> $(taplo --version)"
if [ "$(taplo --version)" = "taplo 0.10.0" ]; then ok T0 "taplo 0.10.0 (the Muse leg's pin)"; else bad T0 "$(taplo --version)"; fi

# T1 — what the default configuration collects
taplo format --check >"$scratch/collect.out" 2>&1 || true
files="$(sed -n 's/.*collect_files: found files total=[0-9]* excluded=[0-9]* files=\[\(.*\)\] cwd.*/\1/p' "$scratch/collect.out" | tr ',' '\n' | sed 's/[" ]//g' | sed "s#^$(pwd -P)/##; s#^$w/##" | sort | tr '\n' ' ')"
echo "    default collection: $files"
if [ "$files" = "Cargo.toml rust-toolchain.toml rustfmt.toml target/debug/decoy.toml " ]; then ok T1 "default collection: the 3 TOML files plus the gitignored target/debug/decoy.toml; Cargo.lock never matched"; else bad T1 "collection: $files"; fi
expect_exit T2 "taplo format --check on the authored tree" 1 taplo format --check

# T3 — taplo's default formatting of the Style-Guide-violating manifest
expect_exit T3 "taplo format rewrites" 0 taplo format
pkg="$(order Cargo.toml package)"; deps="$(order Cargo.toml dependencies)"
echo "    taplo [package]: $pkg; [dependencies]: $deps"
if [ "$pkg" = "description,edition,license,name,rust-version,version,include" ] && [ "$deps" = "serde,anyhow,clap" ]; then ok T3b "defaults keep the authored key order: Style Guide [package] and dependency order are not applied"; else bad T3b "order changed"; fi
if [ "$(cat target/debug/decoy.toml)" = "a = 1" ]; then ok T3c "taplo rewrote target/debug/decoy.toml (default walk ignores .gitignore; a template .taplo.toml would need an exclude)"; else bad T3c "decoy untouched"; fi
g add -A && g commit -qm taplo-formatted
taplo format >/dev/null 2>&1
if g diff --quiet; then ok T4 "taplo format is idempotent"; else bad T4 "second taplo format changed files"; fi

# T5 — can taplo's configuration express the Style Guide's [package] rule?
cat >"$scratch/global.taplo.toml" <<'EOF'
[formatting]
reorder_keys = true
EOF
cp Cargo.toml "$scratch/Cargo.global.toml"
taplo format --config "$scratch/global.taplo.toml" "$scratch/Cargo.global.toml" >/dev/null 2>&1
pkg_global="$(order "$scratch/Cargo.global.toml" package)"
echo "    reorder_keys=true [package]: $pkg_global"
if [ "$(printf '%s' "$pkg_global" | cut -d, -f1)" = description ]; then ok T5 "global reorder_keys sorts [package] alphabetically (description first), contradicting cargo.md:11-15"; else bad T5 "global reorder: $pkg_global"; fi
cat >"$scratch/deps.taplo.toml" <<'EOF'
[[rule]]
keys = ["dependencies", "dev-dependencies", "workspace.dependencies"]
[rule.formatting]
reorder_keys = true
EOF
cp Cargo.toml "$scratch/Cargo.deps.toml"
taplo format --config "$scratch/deps.taplo.toml" "$scratch/Cargo.deps.toml" >/dev/null 2>&1
echo "    scoped rule: [package]: $(order "$scratch/Cargo.deps.toml" package); [dependencies]: $(order "$scratch/Cargo.deps.toml" dependencies)"
if [ "$(order "$scratch/Cargo.deps.toml" dependencies)" = "anyhow,clap,serde" ] && [ "$(order "$scratch/Cargo.deps.toml" package)" = "$pkg" ]; then ok T5b "a rule scoped to dependency tables sorts them and leaves [package] as authored (rustup's shape)"; else bad T5b "scoped rule"; fi

# T6 — the two tools on each other's output (editor format-on-save interplay)
python3 - "$plugins" <<'EOF'
import re, sys
p = sys.argv[1]
names = {"toml-0.8.0": "toml", "json-0.24.0": "json", "markdown-0.24.0": "markdown", "g-plane/pretty_yaml-v0.6.0": "pretty_yaml"}
s = open("dprint.json").read()
for url, local in names.items():
    s = re.sub(r'"https://plugins\.dprint\.dev/' + re.escape(url) + r'\.wasm@[0-9a-f]{64}"', '"%s/%s.wasm"' % (p, local), s)
open("dprint.json", "w").write(s)
EOF
expect_exit T6 "dprint check on taplo's output: Cargo.toml fails on key order only" 20 dprint check Cargo.toml rust-toolchain.toml rustfmt.toml
dprint check --list-different Cargo.toml rust-toolchain.toml rustfmt.toml 2>/dev/null | sed "s#^$(pwd -P)/##; s#^$w/##" >"$scratch/l" || true
if [ "$(cat "$scratch/l")" = Cargo.toml ]; then ok T6b "only Cargo.toml differs"; else bad T6b "listed: $(cat "$scratch/l")"; fi
dprint fmt Cargo.toml rust-toolchain.toml rustfmt.toml >/dev/null 2>&1
expect_exit T6c "taplo format --check on dprint's output (default config) accepts it unchanged" 0 taplo format --check Cargo.toml rust-toolchain.toml rustfmt.toml

cd /
rm -rf "$scratch"
printf 'r29-taplo-compare: PASS=%d FAIL=%d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
