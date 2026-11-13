#!/usr/bin/env bash
# R29 revision 1 — the recommended lefthook job (fixtures/tree/lefthook.yml) in a
# real commit flow: lefthook 2.1.14 installs the pre-commit hook in a scratch
# repository holding the dprint-formatted fixture, then commits are attempted.
# Also executes the two variants that show why the job carries both an
# `exclude:` list and `--allow-no-files`. Needs r29-provision.sh.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
plugins="${PLUGIN_OUT:-/tmp/r29-plugins/out}"
: "${CARGO_HOME:?a private CARGO_HOME must be set}"
export PATH="$CARGO_HOME/bin:$PATH"
scratch="$(mktemp -d /tmp/r29-lefthook.XXXXXX)"
export DPRINT_CACHE_DIR="$scratch/dprint-cache"
w="$scratch/tree"
pass=0 fail=0
ok()  { pass=$((pass + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
bad() { fail=$((fail + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
g() { git -c user.email=r29@example.invalid -c user.name=r29 "$@"; }
attempt() { # id desc want(0|nonzero) grep-pattern -- commit message
  local id="$1" desc="$2" want="$3" pat="$4" msg="$5" got=0
  g commit -qm "$msg" >"$scratch/commit.out" 2>&1 || got=$?
  sed 's/\x1b\[[0-9;]*m//g' "$scratch/commit.out" >"$scratch/commit.txt"
  if { [ "$want" = 0 ] && [ "$got" = 0 ]; } || { [ "$want" = nonzero ] && [ "$got" != 0 ]; }; then
    if grep -qF -- "$pat" "$scratch/commit.txt"; then ok "$id" "$desc (commit exit $got; hook output has '$pat')"; else bad "$id" "$desc: missing '$pat'"; sed 's/^/    | /' "$scratch/commit.txt" | tail -8; fi
  else
    bad "$id" "$desc (commit exit $got, wanted $want)"; sed 's/^/    | /' "$scratch/commit.txt" | tail -8
  fi
}

cp -R "$here/fixtures/tree" "$w"
cp "$here/fixtures/gitignore.fixture" "$w/.gitignore"
cd "$w"
python3 - "$plugins" <<'EOF'
import re, sys
p = sys.argv[1]
names = {"toml-0.8.0": "toml", "json-0.24.0": "json", "markdown-0.24.0": "markdown", "g-plane/pretty_yaml-v0.6.0": "pretty_yaml"}
s = open("dprint.json").read()
for url, local in names.items():
    s = re.sub(r'"https://plugins\.dprint\.dev/' + re.escape(url) + r'\.wasm@[0-9a-f]{64}"', '"%s/%s.wasm"' % (p, local), s)
open("dprint.json", "w").write(s)
EOF
dprint fmt >/dev/null 2>&1
g init -q && g add -A && g commit -qm formatted --no-verify
lefthook install >/dev/null 2>&1
if [ -x .git/hooks/pre-commit ]; then ok H0 "lefthook $(lefthook version) installed the pre-commit hook from the fixture lefthook.yml"; else bad H0 "no hook"; fi

# H1 — an unformatted nested workflow file is blocked (the glob reaches .github/workflows/)
sed -i '' 's/^name: ci$/name:    ci/' .github/workflows/ci.yml
g add .github/workflows/ci.yml
attempt H1 "staged unformatted .github/workflows/ci.yml blocks the commit" nonzero "exit status 20" "perturbed workflow"
g checkout -q HEAD -- .github/workflows/ci.yml

# H2 — a release-please-style commit touching only CHANGELOG.md passes
printf '\n## [0.1.1](https://example.invalid) (2026-09-27)\n\n\n### Bug Fixes\n\n* a fix ([aaa1111](https://example.invalid))\n' >>CHANGELOG.md
g add CHANGELOG.md
attempt H2 "a CHANGELOG.md-only commit passes: the job is skipped by exclude:" 0 "no files for inspection" "changelog only"

# H3 — a formatted change passes through dprint
printf '# Notes\n\nFormatted text.\n' >docs/notes.md
g add docs/notes.md
attempt H3 "a formatted docs/notes.md commit runs the job and passes" 0 "✔️ format-files" "formatted doc"

# H4/H5 — variants without the exclude list: --allow-no-files is what keeps H2 green
python3 - <<'EOF'
import re
s = open("lefthook.yml").read()
s2 = re.sub(r"      exclude:\n(        - .*\n)+", "", s)
assert s2 != s
open("lefthook.yml", "w").write(s2)
open("lefthook.no-allow.yml", "w").write(s2.replace("dprint check --allow-no-files {staged_files}", "dprint check {staged_files}"))
EOF
g add lefthook.yml lefthook.no-allow.yml && g commit -qm variants --no-verify
printf '\n* another ([bbb2222](https://example.invalid))\n' >>CHANGELOG.md
g add CHANGELOG.md
attempt H4 "without exclude:, --allow-no-files keeps a CHANGELOG.md-only commit green (job ran)" 0 "✔️ format-files" "changelog, allow-no-files"
cp lefthook.no-allow.yml lefthook.yml && g add lefthook.yml && g commit -qm no-allow --no-verify
printf '\n* third ([ccc3333](https://example.invalid))\n' >>CHANGELOG.md
g add CHANGELOG.md
attempt H5 "without exclude: and without --allow-no-files the same commit fails" nonzero "exit status 14" "changelog, no flag"

cd /
rm -rf "$scratch"
printf 'r29-lefthook: PASS=%d FAIL=%d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
