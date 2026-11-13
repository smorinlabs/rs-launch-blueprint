#!/usr/bin/env bash
# R47 contributors-recipe-mode — acceptance runner.
#
# Builds throwaway git repositories under .work/, runs the fixture Justfile's
# `contributors-update` recipe against contributors-please@1.4.3, and asserts
# every case listed in review/DECISION.md "## Empirical check". Exits 0 only
# when every assertion holds. Needs: just, node >= 24, npx (registry access or a
# warm npx cache), git, python3, bun (case 11 only). Needs NO GitHub access: the
# bootstrap cases talk to fake-github.mjs on 127.0.0.1.
set -u
cd "$(dirname "$0")" || exit 2
FIX=$(pwd)
WORK="$FIX/.work"
PORT=${FAKE_GITHUB_PORT:-47470}
SERVER="http://127.0.0.1:$PORT"
RUNNER="npx --yes contributors-please@1.4.3"
API_PATH="/api/v3/repos/smorinlabs/rs-launch-blueprint/contributors?per_page=100"
NOREPLY="users.noreply.127.0.0.1:$PORT"   # GitHubClient host incl. port -> deriveNoReplyDomain
PASS=0; FAIL=0
unset GITHUB_REPOSITORY GITHUB_TOKEN GITHUB_SERVER_URL

say()  { printf '%s\n' "$*"; }
ok()   { PASS=$((PASS+1)); say "  ok   $1"; }
bad()  { FAIL=$((FAIL+1)); say "  FAIL $1"; }
assert_eq()   { if [ "$2" = "$3" ]; then ok "$1 = $2"; else bad "$1: expected [$2] got [$3]"; fi; }
assert_grep() { if grep -q -e "$2" "$3"; then ok "$1 matches /$2/"; else bad "$1: /$2/ not found in $3"; fi; }
assert_nogrep() { if grep -q -e "$2" "$3"; then bad "$1: /$2/ unexpectedly present in $3"; else ok "$1 lacks /$2/"; fi; }
assert_absent() { if [ -e "$2" ]; then bad "$1: $2 exists"; else ok "$1: $2 absent"; fi; }
assert_present() { if [ -e "$2" ]; then ok "$1: $2 present"; else bad "$1: $2 missing"; fi; }
assert_same()  { if cmp -s "$2" "$3"; then ok "$1: byte-identical"; else bad "$1: files differ"; diff "$2" "$3" | head -20; fi; }
sha()  { shasum -a 256 "$1" | cut -d' ' -f1; }
reqs() { curl -s "$SERVER/__requests"; }
reqcount() { reqs | python3 -c 'import json,sys;print(json.load(sys.stdin)["count"])'; }

# A fixture repository: config, marked CONTRIBUTORS.md, Justfile, and two commits
# by alice (one code path, one docs path) whose no-reply email joins to the
# login the fake API lists. With_ledger=1 also commits the seed ledger.
mkrepo() {
  local dir=$1 with_ledger=$2
  rm -rf "$dir"; mkdir -p "$dir/src" "$dir/docs"
  git -C "$dir" init -q -b main
  git -C "$dir" config user.name "Alice Example"
  git -C "$dir" config user.email "alice@$NOREPLY"
  cp "$FIX/.contributors.yml" "$FIX/CONTRIBUTORS.md" "$FIX/Justfile" "$dir/"
  printf 'pub fn hello() -> &%sstatic str { "hello" }\n' "'" > "$dir/src/lib.rs"
  git -C "$dir" add -A && git -C "$dir" commit -q -m "feat: add hello"
  printf '# Guide\n' > "$dir/docs/guide.md"
  git -C "$dir" add -A && git -C "$dir" commit -q -m "docs: add guide"
  if [ "$with_ledger" = 1 ]; then
    cp "$FIX/seed/.contributors.jsonl" "$dir/.contributors.jsonl"
    git -C "$dir" add -A && git -C "$dir" commit -q -m "chore: bootstrap contributors"
  fi
}

say "== R47 acceptance run: $(date -u +%Y-%m-%dT%H:%M:%SZ) =="
say "fixture: $FIX"
say "-- toolchain --"
rustc --version; cargo --version
say "node $(node --version); npx $(npx --version); just $(just --version); $(git --version); bun $(bun --version)"
say "$(uname -srm); macOS $(sw_vers -productVersion 2>/dev/null || echo n/a)"
say "runner: $RUNNER"

rm -rf "$WORK"; mkdir -p "$WORK"
FAKE_GITHUB_PORT=$PORT node "$FIX/fake-github.mjs" > "$WORK/fake-github.out" 2>&1 &
FAKE_PID=$!
trap 'kill $FAKE_PID 2>/dev/null' EXIT
i=0; until curl -s "$SERVER/__requests" >/dev/null 2>&1; do i=$((i+1)); [ $i -ge 40 ] && { say "fake-github did not start"; exit 2; }; sleep 0.25; done
say "fake-github: $(cat "$WORK/fake-github.out")"

say "-- case 01: version pin resolves --"
out=$($RUNNER --version 2>"$WORK/c01.err"); rc=$?
assert_eq "c01 exit" 0 "$rc"; assert_eq "c01 version" "1.4.3" "$out"

say "-- case 02: steady-state render via just (committed ledger + marked CONTRIBUTORS.md) --"
curl -s -X POST "$SERVER/__reset" >/dev/null
A="$WORK/A"; mkrepo "$A" 1
before=$(sha "$A/.contributors.jsonl")
(cd "$A" && just contributors-update) > "$WORK/c02.out" 2>&1; rc=$?
cat "$WORK/c02.out" | sed 's/^/    | /'
assert_eq "c02 exit" 0 "$rc"
assert_grep "c02 stdout" "contributors-please rendered 1 contributor" "$WORK/c02.out"
assert_grep "c02 CONTRIBUTORS.md" "^- \[Alice Example\](https://github.com/alice) - Code Contributor (2 commits)$" "$A/CONTRIBUTORS.md"
assert_nogrep "c02 CONTRIBUTORS.md" "dependabot" "$A/CONTRIBUTORS.md"
assert_eq "c02 ledger sha unchanged" "$before" "$(sha "$A/.contributors.jsonl")"
assert_eq "c02 fake-github requests" 0 "$(reqcount)"
say "   direct engine render in a copy, for byte comparison"
A2="$WORK/A2"; rm -rf "$A2"; cp -R "$A" "$A2"; git -C "$A2" checkout -q -- CONTRIBUTORS.md
(cd "$A2" && $RUNNER render --config-file .contributors.yml) > "$WORK/c02b.out" 2>&1; rc=$?
assert_eq "c02b direct render exit" 0 "$rc"
assert_same "c02b recipe output vs direct render" "$A/CONTRIBUTORS.md" "$A2/CONTRIBUTORS.md"
assert_eq "c02b git status of A (only CONTRIBUTORS.md changed)" " M CONTRIBUTORS.md" "$(git -C "$A" status --porcelain)"

say "-- case 03: projection determinism (second recipe run) --"
cp "$A/CONTRIBUTORS.md" "$WORK/c03.before"
(cd "$A" && just contributors-update) > "$WORK/c03.out" 2>&1; rc=$?
assert_eq "c03 exit" 0 "$rc"
assert_same "c03 second run" "$WORK/c03.before" "$A/CONTRIBUTORS.md"
assert_eq "c03 ledger sha unchanged" "$before" "$(sha "$A/.contributors.jsonl")"
assert_eq "c03 fake-github requests" 0 "$(reqcount)"

say "-- case 04: missing ledger -> recipe bootstraps via init (fake GitHub on 127.0.0.1) --"
B="$WORK/B"; mkrepo "$B" 0
(cd "$B" && GITHUB_SERVER_URL="$SERVER" just contributors-update) > "$WORK/c04.out" 2>&1; rc=$?
cat "$WORK/c04.out" | sed 's/^/    | /'
assert_eq "c04 exit" 0 "$rc"
assert_grep "c04 stdout" "contributors-please initialized 1 contributor" "$WORK/c04.out"
assert_present "c04 ledger created" "$B/.contributors.jsonl"
say "    ledger: $(cat "$B/.contributors.jsonl")"
fields=$(python3 -c '
import json,sys
r=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]
a=[x for x in r if x["login"]=="alice"]
print(len(r), len(a), a[0]["commits"], ",".join(a[0]["categories"]), a[0]["source"], a[0]["pinned"], a[0]["profile"], a[0]["title"], sep="|")' "$B/.contributors.jsonl")
assert_eq "c04 ledger records|alice|commits|categories|source|pinned|profile" "1|1|2|code,docs|commit|False|$SERVER/alice" "${fields%|*}"
say "    observed title: ${fields##*|}"
# The fake API row has no `name`, so the engine falls back to the login (identity-join: api.name ?? git name).
assert_grep "c04 CONTRIBUTORS.md" "^- \[alice\]($SERVER/alice) - .* Contributor (2 commits)$" "$B/CONTRIBUTORS.md"
say "    rendered: $(grep -e '^- \[' "$B/CONTRIBUTORS.md")"
assert_eq "c04 fake-github requests" 1 "$(reqcount)"
assert_eq "c04 request" "GET $API_PATH" "$(reqs | python3 -c 'import json,sys;print(json.load(sys.stdin)["log"][0])')"
assert_eq "c04 git status of B (ledger + output untracked/modified, nothing else)" "$(printf ' M CONTRIBUTORS.md\n?? .contributors.jsonl')" "$(git -C "$B" status --porcelain)"

say "-- case 05: guard flips to render once the ledger exists (no discovery) --"
b_ledger=$(sha "$B/.contributors.jsonl"); cp "$B/CONTRIBUTORS.md" "$WORK/c05.before"
(cd "$B" && GITHUB_SERVER_URL="$SERVER" just contributors-update) > "$WORK/c05.out" 2>&1; rc=$?
assert_eq "c05 exit" 0 "$rc"
assert_grep "c05 stdout" "contributors-please rendered 1 contributor" "$WORK/c05.out"
assert_same "c05 output unchanged" "$WORK/c05.before" "$B/CONTRIBUTORS.md"
assert_eq "c05 ledger sha unchanged" "$b_ledger" "$(sha "$B/.contributors.jsonl")"
assert_eq "c05 fake-github requests (still 1)" 1 "$(reqcount)"

say "-- case 06: inverse control — bootstrap without owner fails loudly, writes nothing --"
C="$WORK/C"; mkrepo "$C" 0; cp "$C/CONTRIBUTORS.md" "$WORK/c06.before"
(cd "$C" && GITHUB_SERVER_URL="$SERVER" just --set contributors_owner "" contributors-update) > "$WORK/c06.out" 2>&1; rc=$?
cat "$WORK/c06.out" | sed 's/^/    | /'
assert_eq "c06 exit" 1 "$rc"
assert_grep "c06 stderr" "Provide --owner and --repo, or set GITHUB_REPOSITORY" "$WORK/c06.out"
assert_absent "c06 no ledger" "$C/.contributors.jsonl"
assert_same "c06 output untouched" "$WORK/c06.before" "$C/CONTRIBUTORS.md"
assert_eq "c06 fake-github requests (still 1)" 1 "$(reqcount)"

say "-- case 07: GitHub API failure during bootstrap -> nonzero, no fabricated ledger --"
D="$WORK/D"; mkrepo "$D" 0; cp "$D/CONTRIBUTORS.md" "$WORK/c07.before"
pre=$(reqcount)
curl -s -X POST "$SERVER/__fail/500" >/dev/null
(cd "$D" && GITHUB_SERVER_URL="$SERVER" just contributors-update) > "$WORK/c07.out" 2>&1; rc=$?
curl -s -X POST "$SERVER/__ok" >/dev/null
cat "$WORK/c07.out" | sed 's/^/    | /'
assert_eq "c07 exit" 1 "$rc"
assert_eq "c07 the failing discovery call was made (requests +1)" "$((pre+1))" "$(reqcount)"
assert_grep "c07 stderr" "GitHub API request failed: 500" "$WORK/c07.out"
assert_absent "c07 no ledger" "$D/.contributors.jsonl"
assert_same "c07 output untouched" "$WORK/c07.before" "$D/CONTRIBUTORS.md"

say "-- case 08: direct render with no ledger (Codex negative control reproduced) --"
E="$WORK/E"; mkrepo "$E" 0
(cd "$E" && $RUNNER render --config-file .contributors.yml) > "$WORK/c08.out" 2>&1; rc=$?
cat "$WORK/c08.out" | sed 's/^/    | /'
assert_eq "c08 exit" 1 "$rc"
assert_grep "c08 stderr" "ENOENT.*\.contributors\.jsonl" "$WORK/c08.out"

say "-- case 09: ledger present but CONTRIBUTORS.md absent (in_place precondition) --"
F="$WORK/F"; mkrepo "$F" 1; rm -f "$F/CONTRIBUTORS.md"
(cd "$F" && just contributors-update) > "$WORK/c09.out" 2>&1; rc=$?
cat "$WORK/c09.out" | sed 's/^/    | /'
assert_eq "c09 exit" 1 "$rc"
assert_grep "c09 stderr" "ENOENT.*CONTRIBUTORS\.md" "$WORK/c09.out"

say "-- case 10: shallow clone cannot bootstrap (engine demands full history) --"
G="$WORK/G"; rm -rf "$G"
git clone -q --depth 1 "file://$B" "$G"
assert_eq "c10 clone is shallow" "true" "$(git -C "$G" rev-parse --is-shallow-repository)"
assert_absent "c10 clone has no ledger (never committed in B)" "$G/.contributors.jsonl"
(cd "$G" && GITHUB_SERVER_URL="$SERVER" just contributors-update) > "$WORK/c10.out" 2>&1; rc=$?
cat "$WORK/c10.out" | sed 's/^/    | /'
assert_eq "c10 exit" 1 "$rc"
assert_grep "c10 stderr" "requires a full checkout" "$WORK/c10.out"
assert_absent "c10 no ledger" "$G/.contributors.jsonl"

say "-- case 11: runner override (R42's parameter) leaves the recipe body and output unchanged --"
cp "$A/CONTRIBUTORS.md" "$WORK/c11.before"; pre=$(reqcount)
(cd "$A" && just --set contributors_runner "bun x contributors-please@1.4.3" contributors-update) > "$WORK/c11.out" 2>&1; rc=$?
cat "$WORK/c11.out" | sed 's/^/    | /'
assert_eq "c11 exit" 0 "$rc"
assert_same "c11 bun-x output vs npx output" "$WORK/c11.before" "$A/CONTRIBUTORS.md"
assert_eq "c11 fake-github requests unchanged" "$pre" "$(reqcount)"
assert_eq "c11 git status of A (no runner artifacts)" " M CONTRIBUTORS.md" "$(git -C "$A" status --porcelain)"

say "summary: PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -eq 0 ]; then say "RESULT: PASS"; exit 0; else say "RESULT: FAIL"; exit 1; fi
