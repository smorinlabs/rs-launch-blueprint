#!/usr/bin/env bash
# R69 evidence: does the recommended dev-tool version pin INSTALL and RUN on
# macOS, and does it expose the two capabilities F339 needs?
#
# Why this check exists: bacon's own CI is `ubuntu-latest` only
# (Canop/bacon .github/workflows/tests.yml at tag v3.25.0) and its v3.25.0
# GitHub release carries no binary assets, so fitness gate 4 (ubuntu + macOS) is
# not demonstrable from upstream evidence for macOS. This installs the exact pin
# from crates.io into a scratch root and prints the tool's OWN effective
# configuration. It builds a development TOOL, not the recommendation: no web
# crate, no server, no template scaffold.
set -o pipefail
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE/toolcheck"
BIN="$ROOT/bin/bacon"
mkdir -p "$ROOT"
rc=0
# strip ANSI so assertions run against text, not terminal escapes
strip() { sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g'; }

echo "host: $(uname -sm); rustc: $(rustc --version)"

echo "== 1. cargo install bacon --version 3.25.0 --locked =="
cargo install bacon --version 3.25.0 --locked --root "$ROOT" 2>&1 | tail -4
st=${PIPESTATUS[0]}; echo "exit=$st"; [ "$st" -eq 0 ] || { echo "FAIL: install"; rc=1; }

echo "== 2. the installed binary reports the pinned version =="
v="$("$BIN" --version 2>&1 | strip)"; st=$?
echo "$v"; echo "exit=$st"
[ "$v" = "bacon 3.25.0" ] || { echo "FAIL: expected 'bacon 3.25.0', got '$v'"; rc=1; }

echo "== 3. --list-jobs: the effective job set in a project with NO bacon.toml =="
jobs_out="$( cd "$ROOT" && "$BIN" --list-jobs 2>&1 | strip )"
echo "$jobs_out"
printf '%s' "$jobs_out" | grep -q 'run-long' \
  || { echo "FAIL: 'run-long' absent from the default job set"; rc=1; }
echo "OK: 'run-long' is a default job, so no bacon.toml is needed to reach it"

echo "== 4. the two flags F339's recipe depends on exist =="
help_out="$("$BIN" --help 2>&1 | strip)"
for flag in '--headless' '--features'; do
  printf '%s' "$help_out" | grep -q -- "$flag" \
    && echo "OK: $flag present" \
    || { echo "FAIL: $flag absent from --help"; rc=1; }
done
printf '%s' "$help_out" | grep -A1 -- '--headless' | head -3

echo "== 5. control: a flag that does not exist must NOT be reported present =="
printf '%s' "$help_out" | grep -q -- '--no-such-flag' \
  && { echo "FAIL: the grep matches text that is not there"; rc=1; } \
  || echo "OK: absent flag reported absent (the assertion can fail)"

echo "bacon-install-check rc=$rc"
exit $rc
