#!/usr/bin/env bash
# R28 revision 1 — upstream claims the decision rests on, read at the exact
# commits raw/opus.md cites (S18, S20, S27), through the named endpoint host
# api.github.com/repos/<o>/<r> (contents API, raw media type). Ten requests.
# Every fetched file's sha256 is printed so a rerun can detect drift; the
# commits are pinned, so the bytes should not move.
# Every case prints PASS or FAIL; exit 1 on any FAIL.
# Patterns below are literal upstream text containing backticks, so single
# quotes are intended throughout.
# shellcheck disable=SC2016
set -uo pipefail

fails=0
pass() { printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s — %s\n' "$1" "$2"; fails=$((fails + 1)); }

echo "== retrieved $(date -u +%Y-%m-%dT%H:%M:%SZ)"
command -v gh jq shasum

RA=86493cee4d8902389c3217d8e95a3aae9368fd98
CL=62def434dc22c1d77d4837c4d99cddef7ac3338f
RUFF=51f3437d0344b1909007acf42fe6b124369f8439
UV=136ef97330781a0f5f2be6613aac4382ebbcecea
CARGO=07b80494920f3824e2515e536b76ff282e23993e

scratch=$(mktemp -d "${TMPDIR:-/tmp}/r28-sources.XXXXXX")
trap 'rm -rf "$scratch"' EXIT

# fetch <owner/repo> <path> <commit> <local-name>
fetch() {
  echo
  echo "GET https://api.github.com/repos/$1/contents/$2?ref=$3"
  if gh api -H 'Accept: application/vnd.github.raw' "repos/$1/contents/$2?ref=$3" > "$scratch/$4" 2>"$scratch/$4.err"; then
    printf 'sha256 %s  bytes %s\n' "$(shasum -a 256 < "$scratch/$4" | cut -d' ' -f1)" "$(wc -c < "$scratch/$4" | tr -d ' ')"
    return 0
  fi
  cat "$scratch/$4.err"
  return 1
}

echo
echo "== S1-S3 rust-analyzer VS Code extension settings schema @ ${RA:0:8}"
if fetch rust-lang/rust-analyzer editors/code/package.json "$RA" ra-package.json; then
  props=$(jq -c '[.contributes.configuration[]? | .properties // {} | to_entries[]
    | select(.key == "rust-analyzer.server.path" or .key == "rust-analyzer.check.command" or .key == "rust-analyzer.debug.engine")
    | {key, default: .value.default, enum: .value.enum, description: (.value.markdownDescription // .value.description)}]' "$scratch/ra-package.json")
  jq . <<<"$props"
  if jq -e '.[] | select(.key == "rust-analyzer.server.path") | .description | test("points to bundled binary by default")' <<<"$props" >/dev/null; then
    pass S1 "server.path: the extension runs its bundled server by default"
  else fail S1 "server.path description differs"; fi
  if jq -e '.[] | select(.key == "rust-analyzer.check.command") | .default == "check"' <<<"$props" >/dev/null; then
    pass S2 "check.command defaults to \"check\""
  else fail S2 "check.command default differs"; fi
  if jq -e '.[] | select(.key == "rust-analyzer.debug.engine") | (.default == "auto" and .enum[1] == "llvm-vs-code-extensions.lldb-dap" and .enum[2] == "vadimcn.vscode-lldb")' <<<"$props" >/dev/null; then
    pass S3 "debug.engine default auto; lldb-dap listed before vscode-lldb"
  else fail S3 "debug.engine schema differs"; fi
else
  fail S1 "fetch failed"; fail S2 "fetch failed"; fail S3 "fetch failed"
fi

echo
echo "== S4 rust-analyzer's auto debug engine takes the first installed entry of knownEngines, and lldb-dap is first"
if fetch rust-lang/rust-analyzer editors/code/src/debug.ts "$RA" debug.ts; then
  grep -n 'engine === "auto"\|for (const engineId in knownEngines)\|^const knownEngines\|^    "llvm-vs-code-extensions.lldb-dap": {\|^    "vadimcn.vscode-lldb": {' "$scratch/debug.ts"
  first=$(awk '/^const knownEngines/ { inside = 1 } inside && /^    "[^"]+": \{$/ { print; exit }' "$scratch/debug.ts" | tr -d ' ')
  echo "first knownEngines entry: $first"
  if grep -q 'for (const engineId in knownEngines)' "$scratch/debug.ts" && [ "$first" = '"llvm-vs-code-extensions.lldb-dap":{' ]; then
    pass S4 "auto prefers lldb-dap when installed (rust-analyzer's own Debug lens, not launch.json)"
  else fail S4 "auto order differs (first: $first)"; fi
else
  fail S4 "fetch failed"
fi

echo
echo "== S5-S6 CodeLLDB cargo launch support @ ${CL:0:8}"
if fetch vadimcn/codelldb CHANGELOG.md "$CL" CHANGELOG.md; then
  grep -n '^# 1.11.6$\|use `cargo: \["run"\]` instead of `cargo: \["build"\]`' "$scratch/CHANGELOG.md"
  if grep -q 'use `cargo: \["run"\]` instead of `cargo: \["build"\]`' "$scratch/CHANGELOG.md"; then
    pass S5 "cargo: [\"run\", ...] is accepted since 1.11.6"
  else fail S5 "changelog line absent"; fi
else
  fail S5 "fetch failed"
fi
if fetch vadimcn/codelldb MANUAL.md "$CL" MANUAL.md; then
  grep -n 'replace the `program` property in your launch configuration with `cargo`\|"sourceLanguages": \["rust"\]' "$scratch/MANUAL.md"
  if grep -q 'replace the `program` property in your launch configuration with `cargo`' "$scratch/MANUAL.md" \
     && grep -q 'add `"sourceLanguages": \["rust"\]` into your launch configuration' "$scratch/MANUAL.md"; then
    pass S6 "cargo replaces program; sourceLanguages rust loads the Rust formatters"
  else fail S6 "manual text differs"; fi
else
  fail S6 "fetch failed"
fi

echo
echo "== S7 astral-sh/ruff commits the one-key lint-visibility setting and recommends only rust-analyzer @ ${RUFF:0:8}"
ok=1
if fetch astral-sh/ruff .vscode/settings.json "$RUFF" ruff-settings.json; then
  cat "$scratch/ruff-settings.json"; echo
  grep -q '"rust-analyzer.check.command": "clippy"' "$scratch/ruff-settings.json" || ok=0
else ok=0; fi
if fetch astral-sh/ruff .vscode/extensions.json "$RUFF" ruff-extensions.json; then
  cat "$scratch/ruff-extensions.json"; echo
  [ "$(jq -c .recommendations "$scratch/ruff-extensions.json")" = '["rust-lang.rust-analyzer"]' ] || ok=0
else ok=0; fi
if [ "$ok" -eq 1 ]; then pass S7 "check.command = clippy; recommendations = [rust-analyzer]"; else fail S7 "ruff files differ"; fi

echo
echo "== S8 rust-lang/rust-analyzer recommends CodeLLDB for its own contributors @ ${RA:0:8}"
if fetch rust-lang/rust-analyzer .vscode/extensions.json "$RA" ra-extensions.json; then
  grep -n '"recommendations"' "$scratch/ra-extensions.json"
  if grep -q '"recommendations": \["vadimcn.vscode-lldb"\]' "$scratch/ra-extensions.json"; then
    pass S8 "recommendations = [vadimcn.vscode-lldb]"
  else fail S8 "recommendations differ"; fi
else
  fail S8 "fetch failed"
fi

echo
echo "== S9 astral-sh/uv: pedantic at warn with a curated allow-list @ ${UV:0:8}"
if fetch astral-sh/uv Cargo.toml "$UV" uv-Cargo.toml; then
  grep -n '^pedantic = \|^# Allowed pedantic lints\|^# Disallowed restriction lints' "$scratch/uv-Cargo.toml"
  allows=$(awk '/^# Allowed pedantic lints/ { inside = 1; next } /^# / { inside = 0 } inside && / = "allow"$/ { n++ } END { print n + 0 }' "$scratch/uv-Cargo.toml")
  echo "allow entries in the 'Allowed pedantic lints' block: $allows"
  if grep -q '^pedantic = { level = "warn", priority = -2 }$' "$scratch/uv-Cargo.toml" && [ "$allows" -ge 10 ]; then
    pass S9 "pedantic warn at priority -2 with $allows allowed pedantic lints"
  else fail S9 "shape differs (allows $allows)"; fi
else
  fail S9 "fetch failed"
fi

echo
echo "== S10 rust-lang/cargo relaxes tests through clippy.toml values @ ${CARGO:0:8}"
if fetch rust-lang/cargo clippy.toml "$CARGO" cargo-clippy.toml; then
  grep -n '^allow-.*-in-tests' "$scratch/cargo-clippy.toml"
  if grep -q '^allow-print-in-tests = true$' "$scratch/cargo-clippy.toml" && grep -q '^allow-dbg-in-tests = true$' "$scratch/cargo-clippy.toml"; then
    pass S10 "allow-print-in-tests and allow-dbg-in-tests are set"
  else fail S10 "keys differ"; fi
else
  fail S10 "fetch failed"
fi

echo
echo "== summary: $fails failing case(s)"
[ "$fails" -eq 0 ]
