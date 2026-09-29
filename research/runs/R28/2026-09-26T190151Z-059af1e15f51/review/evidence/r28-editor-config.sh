#!/usr/bin/env bash
# R28 revision 1 — editor surface. No VS Code runs here: this script checks
# the rust-analyzer server's own configuration schema on this host, records
# which toolchain the host's rust-analyzer and cargo resolve to, and parses the
# proposed .vscode files. Every case prints PASS or FAIL; exit 1 on any FAIL.
set -uo pipefail
export RUSTUP_AUTO_INSTALL=0

fails=0
pass() { printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s — %s\n' "$1" "$2"; fails=$((fails + 1)); }

echo "== tools on PATH"
echo "CARGO_HOME=${CARGO_HOME:-unset}"
command -v rust-analyzer cargo jq
rust-analyzer --version
cargo --version
cargo clippy --version
jq --version

scratch=$(mktemp -d "${TMPDIR:-/tmp}/r28-editor.XXXXXX")
trap 'rm -rf "$scratch"' EXIT

echo
echo "== V1 rust-analyzer's check command defaults to cargo check, not clippy"
echo '$ rust-analyzer --print-config-schema'
rust-analyzer --print-config-schema > "$scratch/schema.json"
defaults=$(jq -c '[.[] | .properties | to_entries[]
  | select(.key == "rust-analyzer.check.command" or .key == "rust-analyzer.checkOnSave")
  | {key, default: .value.default}]' "$scratch/schema.json")
echo "$defaults"
cmd=$(jq -r '[.[] | .properties["rust-analyzer.check.command"].default // empty][0]' "$scratch/schema.json")
cos=$(jq -r '[.[] | .properties["rust-analyzer.checkOnSave"].default // empty | tostring][0]' "$scratch/schema.json")
if [ "$cmd" = "check" ] && [ "$cos" = "true" ]; then
  pass V1 "check.command default \"$cmd\"; checkOnSave default $cos"
else
  fail V1 "check.command default '$cmd', checkOnSave '$cos'"
fi

echo
echo "== V2 on this host the rust-analyzer binary and the cargo that runs the gate come from different toolchains"
ra=$(rust-analyzer --version)
cl=$(cargo clippy --version)
echo "rust-analyzer: $ra   (resolved: $(command -v rust-analyzer))"
echo "clippy:        $cl   (resolved: $(command -v cargo))"
if [ -n "$ra" ] && [ -n "$cl" ]; then
  pass V2 "recorded (observation, not a pass/fail property of the recommendation)"
else
  fail V2 "a version probe returned nothing"
fi

echo
echo "== V3 proposed .vscode/extensions.json (R28-owned entries only) parses and names exactly the two Rust extensions"
cat > "$scratch/extensions.json" <<'EOF'
{
  "recommendations": [
    "rust-lang.rust-analyzer",
    "vadimcn.vscode-lldb"
  ]
}
EOF
cat "$scratch/extensions.json"
ids=$(jq -r '.recommendations | sort | join(",")' "$scratch/extensions.json")
if [ "$ids" = "rust-lang.rust-analyzer,vadimcn.vscode-lldb" ]; then
  pass V3 "$ids"
else
  fail V3 "got '$ids'"
fi

echo
echo "== V4 proposed .vscode/settings.json parses and holds exactly one key, a lint-visibility key, no version pin"
cat > "$scratch/settings.json" <<'EOF'
{
  "rust-analyzer.check.command": "clippy"
}
EOF
cat "$scratch/settings.json"
keys=$(jq -r 'keys | join(",")' "$scratch/settings.json")
val=$(jq -r '."rust-analyzer.check.command"' "$scratch/settings.json")
known=$(jq -r '[.[] | .properties | has("rust-analyzer.check.command")] | any' "$scratch/schema.json")
if [ "$keys" = "rust-analyzer.check.command" ] && [ "$val" = "clippy" ] && [ "$known" = "true" ]; then
  pass V4 "one key; the key exists in the server schema"
else
  fail V4 "keys '$keys', value '$val', in schema '$known'"
fi

echo
echo "== V5 proposed .vscode/launch.json parses; every configuration is CodeLLDB (type lldb) with a cargo build spec"
cat > "$scratch/launch.json" <<'EOF'
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "CLI: Launch",
      "type": "lldb",
      "request": "launch",
      "cargo": { "args": ["run", "--package", "<cli-package>", "--bin", "<cli-bin>"] },
      "cwd": "${workspaceFolder}",
      "sourceLanguages": ["rust"]
    },
    {
      "name": "CLI: Launch (With Args)",
      "type": "lldb",
      "request": "launch",
      "cargo": { "args": ["run", "--package", "<cli-package>", "--bin", "<cli-bin>"] },
      "args": ["--help"],
      "cwd": "${workspaceFolder}",
      "sourceLanguages": ["rust"]
    }
  ]
}
EOF
cat "$scratch/launch.json"
n=$(jq '.configurations | length' "$scratch/launch.json")
ok=$(jq '[.configurations[] | (.type == "lldb" and .request == "launch" and (.cargo.args | type) == "array")] | all' "$scratch/launch.json")
if [ "$n" -eq 2 ] && [ "$ok" = "true" ]; then
  pass V5 "$n configurations, all type lldb with cargo.args"
else
  fail V5 "count $n, shape $ok"
fi

echo
echo "== V6 the LLDB DAP runner-up needs a system lldb-dap: present on this macOS host through Xcode (observation; ubuntu-latest not checked)"
if dap=$(xcrun -f lldb-dap 2>/dev/null); then
  echo "xcrun -f lldb-dap -> $dap"
  pass V6 "recorded (observation, macOS only)"
else
  echo "xcrun -f lldb-dap -> not found"
  pass V6 "recorded as absent (observation, macOS only)"
fi

echo
echo "== summary: $fails failing case(s)"
[ "$fails" -eq 0 ]
