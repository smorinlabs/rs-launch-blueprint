#!/bin/bash
# R64 pager-integration — decision empirical check (revision 2).
#
# Verifies the claims the raw reports and DECISION.md make. It IMPLEMENTS NOTHING:
# no crate is scaffolded, no pager is wired, no Cargo.toml is written, nothing is built.
#
# Section numbering 0..14 is revision 1's numbering, kept byte-identical so every
# "section N" citation in DECISION.md still resolves. Section 13 ("done") keeps its
# revision-1 position between 12 and 14 for the same reason. Sections 15 and 16 are new
# in revision 2: 15 carries the gate-2 declared-version evidence the strict gate reading
# makes load-bearing, and 16 is the assertion summary.
#
# Every check that matters asserts on the CONTENT it expected, through assert_has /
# assert_eq / assert_absent, and each failure increments FAILURES, which is this script's
# exit status. A pipeline's status is its last command's, so pipefail is on.
#
# Usage: bash verify.sh > <run-dir>/review/evidence/r64-pager-claims.log 2>&1

set -uo pipefail

UA='rs-launch-blueprint-research/R64'
PY=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TS=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
PYREPO="$HOME/c/py-launch-blueprint"
TSREPO="$HOME/c/ts-launch-blueprint"
REPO="$HOME/c/rs-launch-blueprint-p02-plan"
OUTPY=src/py_launch_blueprint/cli/output.py
W=${R64_WORKDIR:-/private/tmp/claude-501/-Users-stevemorin-c-rs-launch-blueprint-p02-plan/b7c06b2f-d78d-4987-b237-63eeced4bd23/scratchpad/r64}

mkdir -p "$W/src" || exit 99
cd "$W" || exit 99

FAILURES=0
ASSERTS=0
RESULTS=""

hr() { printf '\n\n========== %s ==========\n' "$1"; }
sub() { printf '\n--- %s ---\n' "$1"; }

_record() { # id verdict text
  ASSERTS=$((ASSERTS + 1))
  RESULTS="${RESULTS}$1 $2 $3
"
  printf '[%s %s] %s\n' "$1" "$2" "$3"
  [ "$2" = PASS ] || FAILURES=$((FAILURES + 1))
}

# assert_has <id> <needle> <file> <what>
assert_has() {
  if grep -qF -- "$2" "$3"; then _record "$1" PASS "$4"; else _record "$1" FAIL "$4 — expected to find: $2"; fi
}
# assert_hasre <id> <regex> <file> <what>
assert_hasre() {
  if grep -qE -- "$2" "$3"; then _record "$1" PASS "$4"; else _record "$1" FAIL "$4 — expected to match: $2"; fi
}
# assert_absent <id> <regex> <file> <what>
assert_absent() {
  if grep -qE -- "$2" "$3"; then _record "$1" FAIL "$4 — did NOT expect a match for: $2"; else _record "$1" PASS "$4"; fi
}
# assert_eq <id> <expected> <actual> <what>
assert_eq() {
  if [ "$2" = "$3" ]; then _record "$1" PASS "$4 = $3"; else _record "$1" FAIL "$4 — expected [$2], observed [$3]"; fi
}
# assert_count <id> <expected-count> <actual-count> <what>
assert_count() { assert_eq "$1" "$2" "$3" "$4"; }

fetch() { # url outfile  -> prints [HTTP <code>]
  local code
  code=$(curl -sS -A "$UA" -o "$2" -w '%{http_code}' "$1")
  printf '[HTTP %s] %s\n' "$code" "$1"
  printf '%s' "$code" > "$2.code"
}
http_code() { cat "$1.code"; }

hr "0. toolchain and host"
rustc --version
cargo --version
sw_vers | tr '\n' ' '; echo
uname -m
echo "current published stable channel:"
fetch https://static.rust-lang.org/dist/channel-rust-stable.toml channel.toml
grep -A2 '^\[pkg.rustc\]' channel.toml
assert_eq S00 200 "$(http_code channel.toml)" "stable channel manifest reachable"
assert_hasre S01 '^version = "1\.9[0-9]\.[0-9]+ ' channel.toml "current stable rustc is a 1.9x release (the MSRV floor is computed from it)"
echo "also of record, because sections 4 and 5 depend on them:"
less --version | head -1
git --version

hr "1. py-launch-blueprint at pin $PY — the two BASELINE-REVIEW subjects"
git -C "$PYREPO" show "$PY:$OUTPY" > py-output.py
assert_eq S02 0 "$?" "py output.py readable at the pin"

sub "1a. output.py, numbered, the pager region (lines 50-110)"
cat -n py-output.py | sed -n '50,110p'

sub "1b. output.py, numbered, the paging gate + height gate + subprocess (lines 165,205)"
cat -n py-output.py | sed -n '165,205p'

sub "1c. exact line numbers of the load-bearing statements"
grep -n -E 'DEFAULT_PAGER = |Pager precedence|for var in \("PLBP_PAGER"|return DEFAULT_PAGER|an empty value disables|if not \(self\.paging|with self\.out\.capture|text\.count|subprocess\.run' py-output.py \
  > py-loadbearing.txt
cat py-loadbearing.txt
assert_has S03 '56:DEFAULT_PAGER = "less -FRX"' py-loadbearing.txt "py default pager string at output.py:56"
assert_has S04 '88:    for var in ("PLBP_PAGER", "PAGER"):' py-loadbearing.txt "py two-tier resolution at output.py:88"
assert_has S05 '91:    return DEFAULT_PAGER' py-loadbearing.txt "the only path to the -FRX default is output.py:91"
assert_has S06 '177:        if not (self.paging and self.out.is_terminal and _isatty(self.out)):' py-loadbearing.txt "py paging gate at output.py:177"
assert_has S07 '184:        with self.out.capture() as capture:' py-loadbearing.txt "py capture buffer at output.py:184"
assert_has S08 '187:        if text.count("\n") < self.out.size.height:' py-loadbearing.txt "py height gate at output.py:187"
assert_has S09 '194:            subprocess.run(  # noqa: S603 # nosec B603' py-loadbearing.txt "py pager invocation at output.py:194"
echo "the value returned for a user-set variable, read at output.py:90:"
sed -n '90p' py-output.py
assert_has S10 'return os.environ[var].strip()' <(sed -n '90p' py-output.py) "py returns the bare user value, unflagged"

sub "1d. ADR 0008 — the recorded reason for the height check"
git -C "$PYREPO" show "$PY:docs/adr/0008-pager-for-long-text-output.md" > adr0008.md
grep -n -E 'PLBP_PAGER. > .PAGER|for the height check|Always page on TTY' adr0008.md
assert_has S11 'rejected: `less -F` would' adr0008.md "ADR 0008 concedes the less -F half of the height check"
assert_has S12 'non-less pagers would page one-line results' adr0008.md "ADR 0008's stated reason for the height gate"

sub "1e. does py inject LESS/LV into the pager child? (expect: no match)"
grep -n -E 'LESS|LV=|env=' py-output.py; rc=$?
printf '[grep exit=%s, expected=1 (no env injection in py)]\n' "$rc"
assert_absent S13 '(LESS|LV=|env=)' py-output.py "py injects nothing into the pager child"

hr "2. ts-launch-blueprint at pin $TS — the py-only claim"
git -C "$TSREPO" grep -il -e 'pager' -e 'less -F' "$TS" -- src docs package.json > ts-pager.txt; rc=$?
cat ts-pager.txt
printf '[git grep exit=%s, expected=1 (ts ships no pager integration)]\n' "$rc"
assert_count S14 0 "$(wc -l < ts-pager.txt | tr -d ' ')" "ts files matching pager/less -F at the pin"

hr "3. less on this host, and the flag semantics the default command depends on"
command -v less
less --version | head -3
sub "3a. man less: -F, -R, -X, -K and the LESS environment variable"
MANWIDTH=80 man less 2>/dev/null | col -b \
  | grep -A3 -E '^       -F or|^       -K or|^       -R or|^       -X or' > man-less.txt
cat man-less.txt
assert_has S15 'Causes less to automatically exit if the entire file can be' man-less.txt "less(1) defines -F as quit-if-one-screen"
assert_has S16 '-F or --quit-if-one-screen' man-less.txt "the -F long name"
assert_has S17 '-R or --RAW-CONTROL-CHARS' man-less.txt "the -R long name"
assert_has S18 '-K or --quit-on-intr' man-less.txt "the -K long name, the jj-default fallback"
assert_has S19 '-X or --no-init' man-less.txt "the -X long name"

hr "4. OBSERVED: does a bare pager assignment lose colour, and does LESS= restore it?"
echo "Each capture below is taken under a pseudo-terminal with script(1), with the exact argv"
echo "printed above it, and rendered through cat -v. These are the argv the revision-1 audit"
echo "published in review/evidence/audit-pager-integration-r1.log."

sub "4a. control: the bytes we are paging"
printf 'A\033[31mRED\033[0m B\n' | cat -v

sub "4b. 'less -F' with LESS unset — what the user sees (cat -v of the pty capture)"
echo "argv: env -u LESS script -q /dev/null sh -c 'printf \"A\\033[31mRED\\033[0m B\\n\" | less -F'"
env -u LESS script -q /dev/null sh -c 'printf "A\033[31mRED\033[0m B\n" | less -F' < /dev/null \
  | cat -v > cap-less-F.txt
printf 'exit: %s\n' "$?"
cat cap-less-F.txt
assert_has S20 'ESC' cap-less-F.txt "bare less -F renders the escape byte visibly instead of acting on it"
assert_hasre S21 'ESC.*\[31mRED' cap-less-F.txt "bare less -F leaves [31m as literal text"
assert_absent S22 '\^\[\[31mRED' cap-less-F.txt "bare less -F does NOT pass the raw SGR sequence through"

sub "4c. 'less -FR' — -R given on the command line"
echo "argv: env -u LESS script -q /dev/null sh -c 'printf \"A\\033[31mRED\\033[0m B\\n\" | less -FR'"
env -u LESS script -q /dev/null sh -c 'printf "A\033[31mRED\033[0m B\n" | less -FR' < /dev/null \
  | cat -v > cap-less-FR.txt
printf 'exit: %s\n' "$?"
cat cap-less-FR.txt
assert_has S23 '^[[31mRED^[[0m B' cap-less-FR.txt "less -FR passes the raw SGR sequence through"
assert_absent S24 'ESC\^\[\[27m' cap-less-FR.txt "less -FR does not render an escape placeholder"

sub "4d. bare 'less', no arguments, with LESS=FRX injected (git's mechanism)"
echo "argv: LESS=FRX script -q /dev/null sh -c 'printf \"A\\033[31mRED\\033[0m B\\n\" | less'"
LESS=FRX script -q /dev/null sh -c 'printf "A\033[31mRED\033[0m B\n" | less' < /dev/null \
  | cat -v > cap-less-env.txt
printf 'exit: %s\n' "$?"
cat cap-less-env.txt
assert_has S25 '^[[31mRED^[[0m B' cap-less-env.txt "a bare less under LESS=FRX passes the raw SGR sequence through"

hr "5. OBSERVED: what git's environment injection actually does"
git --version

sub "5a. the pager child's own environment, git run under a pty with core.pager=env"
echo "argv: env -i PATH=\$PATH HOME=\$HOME TERM=xterm-256color LANG=C script -q /dev/null sh -c \"git -c core.pager='env | grep -E \\\"^(LESS|LV)=\\\"' log -1\""
env -i PATH="$PATH" HOME="$HOME" TERM=xterm-256color LANG=C \
  script -q /dev/null sh -c "cd '$REPO' && git -c core.pager='env | grep -E \"^(LESS|LV)=\"' log -1" < /dev/null \
  | tr -d '\r' | grep -oE '(LESS|LV)=[-A-Za-z]*' | sort > git-child-env.txt; rc=$?
cat git-child-env.txt
printf '[grep -o exit=%s, expected=0; the pty prefixes the first captured line, so the match is unanchored]\n' "$rc"
assert_has S26 'LESS=FRX' git-child-env.txt "git injects LESS=FRX into the pager child when the parent leaves it unset"
assert_has S27 'LV=-c' git-child-env.txt "git injects LV=-c on the same condition"

sub "5b. and with LESS already set in the parent — is it overridden?"
echo "argv: same, with LESS=Q LV=Z added to the parent environment"
env -i PATH="$PATH" HOME="$HOME" TERM=xterm-256color LANG=C LESS=Q LV=Z \
  script -q /dev/null sh -c "cd '$REPO' && git -c core.pager='env | grep -E \"^(LESS|LV)=\"' log -1" < /dev/null \
  | tr -d '\r' | grep -oE '(LESS|LV)=[-A-Za-z]*' | sort > git-child-env-set.txt; rc=$?
cat git-child-env-set.txt
printf '[grep -o exit=%s, expected=0; the pty prefixes the first captured line, so the match is unanchored]\n' "$rc"
assert_has S28 'LESS=Q' git-child-env-set.txt "git does not override a parent-set LESS"
assert_has S29 'LV=Z' git-child-env-set.txt "git does not override a parent-set LV"
assert_absent S30 'LESS=FRX' git-child-env-set.txt "no FRX appears when the parent set LESS"

sub "5c. git's own source at tag v2.51.0"
fetch https://raw.githubusercontent.com/git/git/v2.51.0/Makefile git-makefile
grep -n 'PAGER_ENV' git-makefile
fetch https://raw.githubusercontent.com/git/git/v2.51.0/pager.c git-pager.c
cat -n git-pager.c | sed -n '80,132p'
assert_eq S31 200 "$(http_code git-makefile)" "git Makefile at v2.51.0 reachable"
assert_eq S32 200 "$(http_code git-pager.c)" "git pager.c at v2.51.0 reachable"
assert_has S33 'PAGER_ENV = LESS=FRX LV=-c' git-makefile "git's build-time PAGER_ENV value"
assert_has S34 'if (!getenv(argv[i]))' git-pager.c "git applies PAGER_ENV only when the variable is unset"
assert_has S35 'if (!*pager || !strcmp(pager, "cat"))' git-pager.c "git treats an empty value and cat as no pager"
assert_has S36 '#define DEFAULT_PAGER "less"' git-pager.c "git's built-in default command is the bare string less"
assert_has S37 'if (!stdout_is_tty)' git-pager.c "git returns no pager when stdout is not a tty"

hr "6. crates.io figures (GET https://crates.io/api/v1/crates/<name>, retrieved today)"
for c in shell-words shlex pager minus sapling-streampager terminal_size grep-cli bat; do
  sub "$c"
  fetch "https://crates.io/api/v1/crates/$c" "crate-$c.json" > /dev/null
  python3 - "crate-$c.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
c = d["crate"]
for k in ("recent_downloads", "downloads", "max_stable_version", "repository"):
    print(f"crate.{k} = {c.get(k)}")
PY
  fetch "https://crates.io/api/v1/crates/$c/versions" "versions-$c.json" > /dev/null
  python3 - "versions-$c.json" "newest-$c.txt" <<'PY'
import json, sys
vs = [v for v in json.load(open(sys.argv[1]))["versions"] if not v["yanked"]]
v = vs[0]
line = (f'newest unyanked: {v["num"]} {v["created_at"]} | license: {v["license"]}'
        f' | rust_version: {v["rust_version"]} | edition: {v.get("edition")}')
print(line)
print("features:", v.get("features"))
open(sys.argv[2], "w").write(line + "\n")
PY
done
assert_hasre S38 '^newest unyanked: 1\.1\.1 ' newest-shell-words.txt "shell-words newest unyanked version is 1.1.1"
assert_has S39 'rust_version: None' newest-shell-words.txt "shell-words 1.1.1 declares NO rust-version on crates.io"
assert_hasre S40 '^newest unyanked: 2\.0\.1 ' newest-shlex.txt "shlex newest unyanked version is 2.0.1"
assert_has S41 'rust_version: 1.46.0' newest-shlex.txt "shlex 2.0.1 declares rust-version 1.46.0 on crates.io"
assert_has S42 'license: MIT OR Apache-2.0' newest-shlex.txt "shlex 2.0.1 licence expression"
assert_has S43 'license: MIT/Apache-2.0' newest-shell-words.txt "shell-words 1.1.1 licence expression (old slash spelling)"

hr "7. GitHub figures (via gh api — authenticated with the user token, not anonymous)"
for r in tmiasko/shell-words comex/rust-shlex sharkdp/bat dandavison/delta jj-vcs/jj AMythicDev/minus; do
  sub "$r"
  gh api "repos/$r" --jq '{archived: .archived, license: .license.spdx_id, pushed_at: .pushed_at, stars: .stargazers_count}' \
    | tee "gh-${r//\//-}.json"
  gh api "search/issues?q=repo:$r+is:issue+is:open" --jq '{open_issues_total_count: .total_count}'
  sleep 2
done
assert_hasre S44 '"archived":false' gh-tmiasko-shell-words.json "shell-words repository is not archived"
assert_hasre S45 '"archived":false' gh-comex-rust-shlex.json "shlex repository is not archived"

sub "shell-words repository tree — is there any CI at all?"
gh api "repos/tmiasko/shell-words/git/trees/master?recursive=1" --jq '.tree[].path' > sw-tree.txt
cat sw-tree.txt
assert_absent S46 '^\.github' sw-tree.txt "shell-words has no .github directory, so no CI is evidenced"

sub "shlex CI workflow read INSIDE the published 2.0.1 artifact (not at a moving branch)"
[ -f shlex-2.0.1.crate ] || fetch https://static.crates.io/crates/shlex/shlex-2.0.1.crate shlex-2.0.1.crate
echo "the release commit the artifact was cut from:"
tar -xOzf shlex-2.0.1.crate shlex-2.0.1/.cargo_vcs_info.json; echo
echo "files the published artifact ships (note the workflow):"
tar tzf shlex-2.0.1.crate
tar -xOzf shlex-2.0.1.crate shlex-2.0.1/.github/workflows/test.yml > shlex-ci.yml
cat shlex-ci.yml
assert_has S47 '"sha1"' <(tar -xOzf shlex-2.0.1.crate shlex-2.0.1/.cargo_vcs_info.json) "the 2.0.1 artifact records its own release commit"
assert_has S48 'rustup toolchain install 1.46' shlex-ci.yml "shlex's CI installs toolchain 1.46 — at 2.0.1 the declared MSRV is tested in CI, read from the release artifact"
assert_hasre S49 'name: Test \(MSRV\)' shlex-ci.yml "shlex 2.0.1 ships a named MSRV job"
assert_absent S50 'macos' shlex-ci.yml "shlex's CI at 2.0.1 has NO macOS job"
echo "runs-on values in that workflow:"
grep -c 'runs-on: ubuntu-latest' shlex-ci.yml
assert_eq S51 4 "$(grep -c 'runs-on: ubuntu-latest' shlex-ci.yml)" "shlex CI jobs running on ubuntu-latest (and that is every job)"

hr "8. RustSec (gate 3), with a control proving 404 means 'no advisory page'"
for c in shell-words shlex pager minus sapling-streampager terminal_size time; do
  code=$(curl -sS -A "$UA" -o "rustsec-$c.html" -w '%{http_code}' "https://rustsec.org/packages/$c.html")
  printf '%s' "$code" > "rustsec-$c.html.code"
  n=$(grep -o 'RUSTSEC-' "rustsec-$c.html" | wc -l | tr -d ' ')
  printf '%-22s HTTP %s  RUSTSEC- mentions: %s\n' "$c" "$code" "$n"
done
assert_eq S52 404 "$(http_code rustsec-shell-words.html)" "no RustSec advisory page for shell-words"
assert_eq S53 200 "$(http_code rustsec-shlex.html)" "shlex HAS a RustSec advisory page"
assert_eq S54 200 "$(http_code rustsec-time.html)" "control: the time crate's advisory page is HTTP 200, so 404 means absence and not a failed retrieval"

sub "every advisory listed on the shlex package page"
python3 - rustsec-shlex.html shlex-adv-ids.txt <<'PY'
import re, sys
html = open(sys.argv[1], encoding="utf-8", errors="replace").read()
ids = sorted(set(re.findall(r"RUSTSEC-\d{4}-\d{4}", html)))
print("advisory ids on the page:", ids)
open(sys.argv[2], "w").write("\n".join(ids) + "\n")
PY
assert_eq S55 "RUSTSEC-2024-0006" "$(tr -d '\n' < shlex-adv-ids.txt)" "the shlex page lists exactly one advisory id"

sub "RUSTSEC-2024-0006 — affected range and affected functions (does it touch shlex::split?)"
fetch https://raw.githubusercontent.com/rustsec/advisory-db/main/crates/shlex/RUSTSEC-2024-0006.md rustsec-2024-0006.md
sed -n '1,40p' rustsec-2024-0006.md
assert_eq S56 200 "$(http_code rustsec-2024-0006.md)" "the advisory's own TOML is readable"
assert_has S57 'patched = [">= 1.3.0"]' rustsec-2024-0006.md "the advisory is patched at >= 1.3.0, so 2.0.1 is outside the affected range"
assert_has S58 '"shlex::quote" = ["< 1.2.1"]' rustsec-2024-0006.md "affected function quote"
assert_has S59 '"shlex::join" = ["< 1.2.1"]' rustsec-2024-0006.md "affected function join"
assert_absent S60 '"shlex::split"' rustsec-2024-0006.md "shlex::split — the only function this design calls — is NOT in the advisory's affected set"

hr "9. published crate artifacts, read from static.crates.io (read-only; nothing built)"
for spec in shell-words:1.1.1 shlex:2.0.1; do
  name=${spec%%:*}; ver=${spec##*:}; dir="$name-$ver"
  sub "$name $ver"
  fetch "https://static.crates.io/crates/$name/$name-$ver.crate" "$dir.crate"
  rm -rf "src/$dir"; mkdir -p src
  tar xzf "$dir.crate" -C src
  echo "-- Cargo.toml (published manifest) --"
  grep -n -E '^\[package\]|^name|^version|^edition|^rust-version|^license|^repository|^\[features\]|^\[lib\]|^\[dependencies\]|^\[lints' "src/$dir/Cargo.toml"
  echo "-- every rust-version line in the published manifest (gate 2) --"
  grep -n '^rust-version' "src/$dir/Cargo.toml" > "rv-$name.txt"; rc=$?
  cat "rv-$name.txt"
  printf '[grep exit=%s; count=%s]\n' "$rc" "$(wc -l < "rv-$name.txt" | tr -d ' ')"
  echo "-- crate-level attributes --"
  grep -n '^#!\[' "src/$dir/src/lib.rs"
  echo "-- occurrences of the token 'unsafe' in src/ --"
  grep -rn 'unsafe' "src/$dir/src/" | sed "s|src/$dir/|$dir/|"
  echo "-- [dependencies] in the published manifest (expect: none for either crate) --"
  grep -n -A3 '^\[dependencies\]' "src/$dir/Cargo.toml"
  echo "[if nothing printed, the manifest declares no dependencies]"
  echo "-- the split entry point --"
  grep -n -E '^pub fn (split|quote|join)|    pub fn (join|quote)' "src/$dir/src/lib.rs"
  echo "-- line count of the whole crate source --"
  wc -l "src/$dir"/src/*.rs
done
assert_eq S61 200 "$(http_code shell-words-1.1.1.crate)" "shell-words 1.1.1 artifact downloaded"
assert_eq S62 200 "$(http_code shlex-2.0.1.crate)" "shlex 2.0.1 artifact downloaded"
assert_count S63 0 "$(wc -l < rv-shell-words.txt | tr -d ' ')" "rust-version lines in shell-words 1.1.1's published manifest"
assert_count S64 1 "$(wc -l < rv-shlex.txt | tr -d ' ')" "rust-version lines in shlex 2.0.1's published manifest"
assert_has S65 'rust-version = "1.46.0"' rv-shlex.txt "shlex 2.0.1's declared rust-version, read from the published manifest"
assert_has S66 '#![forbid(unsafe_code)]' src/shell-words-1.1.1/src/lib.rs "shell-words forbids unsafe outright"
assert_has S67 'pub fn split(s: &str) -> Result<Vec<String>, ParseError>' src/shell-words-1.1.1/src/lib.rs "shell-words' split signature"
assert_has S68 'pub fn split(in_str: &str) -> Option<Vec<String>>' src/shlex-2.0.1/src/lib.rs "shlex's split signature — the one call-site difference"
assert_has S69 'unsafe { String::from_utf8_unchecked(byte_word) }' src/shlex-2.0.1/src/lib.rs "the one unchecked UTF-8 conversion on shlex's split path"
assert_absent S70 '^\[dependencies\]' src/shell-words-1.1.1/Cargo.toml "shell-words declares no dependencies"
assert_absent S71 '^\[dependencies\]' src/shlex-2.0.1/Cargo.toml "shlex declares no dependencies"
assert_has S72 'edition = "2018"' src/shlex-2.0.1/Cargo.toml "shlex's declared edition"
assert_absent S73 '^edition' src/shell-words-1.1.1/Cargo.toml "shell-words declares no edition (the 2015 ruleset)"

hr "10. reference implementations at pinned tags — do they do what the raws say?"
sub "bat v0.26.1 Cargo.toml: shell-words, and the paging feature"
fetch https://raw.githubusercontent.com/sharkdp/bat/v0.26.1/Cargo.toml bat-cargo.toml > /dev/null
grep -n -E 'shell-words|^paging|minus|grep-cli' bat-cargo.toml
assert_has S74 'paging = [ "shell-words", "grep-cli", "minus"]' bat-cargo.toml "bat's paging feature pulls shell-words in"
assert_has S75 'shell-words = { version = "1.1.0", optional = true }' bat-cargo.toml "bat's shell-words requirement"

sub "bat v0.26.1 src/output.rs: spawn, fallback, Drop-time wait"
fetch https://raw.githubusercontent.com/sharkdp/bat/v0.26.1/src/output.rs bat-output.rs
grep -n -E 'no-init|stdin\(Stdio::piped\(\)\)|unwrap_or_else|fn drop|command.wait\(\)' bat-output.rs
assert_has S76 '.unwrap_or_else(|_| OutputType::stdout())' bat-output.rs "bat falls through to stdout in the same expression as the spawn"
assert_has S77 'fn drop(&mut self)' bat-output.rs "bat closes and waits in Drop"

sub "bat: does it measure terminal HEIGHT before paging? (expect: no match)"
grep -n -E 'terminal_size|height|ws_row|term_height|LINES' bat-output.rs; rc=$?
printf '[grep exit=%s, expected=1]\n' "$rc"
assert_absent S78 'terminal_size|height|ws_row|term_height|LINES' bat-output.rs "bat src/output.rs measures no terminal height"

sub "delta 0.19.2 src/utils/bat/output.rs"
fetch https://raw.githubusercontent.com/dandavison/delta/0.19.2/src/utils/bat/output.rs delta-output.rs
grep -n -E 'fn drop|command.wait\(\)|shell_words::split|stdin\(Stdio::piped\(\)\)' delta-output.rs
grep -n -E 'terminal_size|height|ws_row|term_height|LINES' delta-output.rs; rc=$?
printf '[grep exit=%s, expected=1]\n' "$rc"
assert_has S79 'shell_words::split' delta-output.rs "delta tokenizes the resolved pager command with shell_words::split"
assert_absent S80 'terminal_size|height|ws_row|term_height|LINES' delta-output.rs "delta's pager file measures no terminal height"

sub "delta 0.19.2 Cargo.toml + src/env.rs chain"
fetch https://raw.githubusercontent.com/dandavison/delta/0.19.2/Cargo.toml delta-cargo.toml > /dev/null
grep -n 'shell-words' delta-cargo.toml
fetch https://raw.githubusercontent.com/dandavison/delta/0.19.2/src/env.rs delta-env.rs > /dev/null
grep -n -E 'DELTA_PAGER|env::var\(DELTA_PAGER\)|get_pager_executable|set_var\("PAGER"' delta-env.rs
assert_has S81 'shell-words = "1.0.0"' delta-cargo.toml "delta's shell-words requirement"
assert_has S82 'const DELTA_PAGER' delta-env.rs "delta's app-specific pager variable sits above PAGER"

sub "jj v0.45.1 cli/src/ui.rs — spawn, wait, fallback; and its documented chain"
fetch https://raw.githubusercontent.com/jj-vcs/jj/v0.45.1/cli/src/ui.rs jj-ui.rs
grep -n -E 'spawning pager|stdin\(Stdio::piped\(\)\)\.spawn|child.wait\(\)|streampager' jj-ui.rs
grep -n -E 'terminal_size|ws_row|term_height|LINES' jj-ui.rs; rc=$?
printf '[grep exit=%s, expected=1]\n' "$rc"
fetch https://raw.githubusercontent.com/jj-vcs/jj/v0.45.1/cli/src/config/misc.toml jj-misc.toml > /dev/null
grep -n 'pager = ' jj-misc.toml
fetch https://raw.githubusercontent.com/jj-vcs/jj/v0.45.1/docs/config.md jj-config.md > /dev/null
grep -n -E 'JJ_PAGER|PAGER. environment variable is ignored|:builtin' jj-config.md | head -6
assert_has S83 'cmd.stdin(Stdio::piped()).spawn()?' jj-ui.rs "jj spawns its pager with a piped stdin"
assert_has S84 'child.wait()' jj-ui.rs "jj waits on the pager child"
assert_has S85 'pager = { command = ["less", "-FRXK"]' jj-misc.toml "jj's default pager command, the -FRXK fallback this decision names"
assert_has S86 'environment variable is ignored' jj-config.md "jj deliberately ignores the generic PAGER — the one dissenter on the chain"

sub "git v2.51.0 pager.c — does it measure terminal height? (expect: no match)"
grep -n -E 'terminal_size|ws_row|term_height|LINES' git-pager.c; rc=$?
printf '[grep exit=%s, expected=1]\n' "$rc"
grep -n -E 'DEFAULT_PAGER|GIT_PAGER|getenv\("PAGER"\)|strcmp\(pager, "cat"\)|isatty' git-pager.c
assert_absent S87 'terminal_size|ws_row|term_height|LINES' git-pager.c "git pager.c measures no terminal height"

hr "11. is 'less' present on the CI runners? (target-os-matrix = ubuntu-latest, macos-latest)"
sub "11a. this macOS host — OBSERVED"
command -v less
less --version | head -1

sub "11b. actions/runner-images Ubuntu 24.04 README — any mention of less?"
fetch https://raw.githubusercontent.com/actions/runner-images/main/images/ubuntu/Ubuntu2404-Readme.md ubuntu-readme.md
grep -oi -w 'less' ubuntu-readme.md | wc -l | tr -d ' '
echo "[match count above; expected=0 => README is SILENT on less]"
grep -c 'Installed apt packages' ubuntu-readme.md
echo "[the README does carry an apt-package section, so the silence is informative]"
assert_count S88 0 "$(grep -oi -w 'less' ubuntu-readme.md | wc -l | tr -d ' ')" "mentions of less in the Ubuntu 24.04 runner-image README"
assert_hasre S89 'Installed apt packages' ubuntu-readme.md "that README does enumerate apt packages, so its silence is informative"

sub "11c. actions/runner-images macOS 15 README — any mention of less?"
fetch https://raw.githubusercontent.com/actions/runner-images/main/images/macos/macos-15-Readme.md macos-readme.md
grep -oi -w 'less' macos-readme.md | wc -l | tr -d ' '
echo "[match count above; expected=0 => README is SILENT on less]"
assert_count S90 0 "$(grep -oi -w 'less' macos-readme.md | wc -l | tr -d ' ')" "mentions of less in the macOS 15 runner-image README"

sub "11d. does the Ubuntu image's own toolset install less explicitly?"
fetch https://raw.githubusercontent.com/actions/runner-images/main/images/ubuntu/toolsets/toolset-2404.json toolset-2404.json
python3 - toolset-2404.json toolset-less.txt <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
out = []
for key in ("vital_packages", "common_packages", "cmd_packages"):
    vals = d.get("apt", {}).get(key, d.get(key, []))
    out.append(f"{key} -> lists less: {'less' in (vals or [])}")
print("\n".join(out))
open(sys.argv[2], "w").write("\n".join(out) + "\n")
PY
assert_absent S91 'lists less: True' toolset-less.txt "the Ubuntu image toolset does not install less explicitly"

sub "11e. is less packaged for Ubuntu noble at all?"
fetch https://packages.ubuntu.com/noble/less ubuntu-less.html
python3 - ubuntu-less.html <<'PY'
import re, sys
html = open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r"Package: less \([^)]*\)", html)
print("packages.ubuntu.com noble says:", m.group(0) if m else "(no Package: less line)")
PY
assert_eq S92 200 "$(http_code ubuntu-less.html)" "packages.ubuntu.com/noble/less is HTTP 200"
assert_has S93 'Package: less' ubuntu-less.html "less is packaged for Ubuntu noble — packaged is not the same as installed on a runner"

hr "12. this repository — ledger rows, owner direction, couplings"
grep -n -E '^\| F28[45] ' "$REPO/docs/port/COMMONALITY.md"
grep -n -E '^\| F28[45] ' "$REPO/docs/port/areas/cli-framework-ux.md"
grep -n '^| R64 ' "$REPO/docs/port/OWNER-REVIEW.md"
grep -n 'R64 `pager-integration`' "$REPO/docs/port/REVIEW-PHASE4.md" 2>/dev/null | head -2
grep -n -E '^\| R64 pager-integration|^- R64 \(pager\)' "$REPO/docs/port/DIVERGENCE-ANALYSIS.md"

sub "does any registered parameter own an app env-var prefix? (expect: no match)"
grep -n -E 'short-name|env-prefix|app-short|app-env' "$REPO/docs/port/PARAMETERS.md"; rc=$?
printf '[grep exit=%s, expected=1]\n' "$rc"
assert_absent S94 'short-name|env-prefix|app-short|app-env' "$REPO/docs/port/PARAMETERS.md" "no registered parameter owns the application env-var prefix"

sub "R64 couplings — owns/consumes"
sed -n '/^## Couplings/,/^If your recommendation/p' \
  "$REPO/research/runs/R64/2026-09-05T183457Z-3c53ded23d05/inputs/prompt.md"

sub "the four fixed parameters, compared byte-for-byte with the registry"
for p in msrv-policy rust-edition target-os-matrix license; do
  reg=$(grep -E "^\| \`?$p\`? \|" "$REPO/docs/port/PARAMETERS.md" | head -1 | awk -F'|' '{print $5}' | sed 's/^ *//; s/ *$//; s/^`//; s/`$//')
  dec=$(grep -E "^- assumes $p = " "$REPO/research/runs/R64/2026-09-05T183457Z-3c53ded23d05/review/DECISION.md" | head -1 | sed "s/^- assumes $p = //")
  printf '%-17s registry=[%s]\n%-17s decision=[%s]\n' "$p" "$reg" "" "$dec"
  assert_eq "S95-$p" "$reg" "$dec" "assumes $p matches the registry byte-for-byte"
done

hr "13. done"
date -u +%Y-%m-%dT%H:%M:%SZ

hr "14. appendix: platform-conditional code in the two tokenizers, and the exact unsafe site on shlex::split"

sub "shell-words-1.1.1: every cfg( in src/"
grep -rn 'cfg(' src/shell-words-1.1.1/src/ | sed 's|src/shell-words-1.1.1/|shell-words-1.1.1/|'; rc=$?
printf '[grep exit=%s]\n' "$rc"
sub "shell-words-1.1.1: any windows/unix token in src/"
grep -rniE 'windows|unix' src/shell-words-1.1.1/src/ | sed 's|src/shell-words-1.1.1/|shell-words-1.1.1/|'; rc=$?
printf '[grep exit=%s; every hit above is prose, not a cfg]\n' "$rc"
assert_absent S96 'cfg\((target_os|unix|windows)' src/shell-words-1.1.1/src/lib.rs "shell-words has no platform-conditional code"

sub "shlex-2.0.1: every cfg( in src/"
grep -rn 'cfg(' src/shlex-2.0.1/src/ | sed 's|src/shlex-2.0.1/|shlex-2.0.1/|'; rc=$?
printf '[grep exit=%s]\n' "$rc"
sub "shlex-2.0.1: any windows/unix token in src/"
grep -rniE 'windows|unix' src/shlex-2.0.1/src/ | sed 's|src/shlex-2.0.1/|shlex-2.0.1/|'; rc=$?
printf '[grep exit=%s; the unix/windows hits are prose and one doc-comment cfg]\n' "$rc"
assert_absent S97 '^ *#\[cfg\((target_os|unix|windows)' src/shlex-2.0.1/src/lib.rs "shlex lib.rs has no platform-conditional code"
assert_absent S98 '^ *#\[cfg\((target_os|unix|windows)' src/shlex-2.0.1/src/bytes.rs "shlex bytes.rs has no platform-conditional code"

sub "shlex 2.0.1: split (lib.rs:100-104) and the Iterator::next it collects from (lib.rs:80-88)"
sed -n '78,105p' src/shlex-2.0.1/src/lib.rs

sub "shell-words 1.1.1: crate attributes and split signature"
sed -n '11,12p;120,132p' src/shell-words-1.1.1/src/lib.rs

hr "15. gate 2 under the strict reading — the declared versions, at the versions named"
echo "Fitness gate 2 quotes msrv-policy in full: 'declared as rust-version in Cargo.toml and"
echo "tested in CI'. The controller's ruling of 2026-09-11 reads it strictly, so a candidate"
echo "that declares nothing cannot clear it. Both candidates' declarations, at the exact"
echo "versions this decision names, from two independent sources each:"
printf '\n%-22s %-28s %s\n' "candidate" "published Cargo.toml" "crates.io versions endpoint"
printf '%-22s %-28s %s\n' "shell-words 1.1.1" \
  "$(grep -c '^rust-version' src/shell-words-1.1.1/Cargo.toml | tr -d ' ') rust-version lines" \
  "$(grep -o 'rust_version: [^|]*' newest-shell-words.txt)"
printf '%-22s %-28s %s\n' "shlex 2.0.1" \
  "$(grep '^rust-version' src/shlex-2.0.1/Cargo.toml | tr -d ' ')" \
  "$(grep -o 'rust_version: [^|]*' newest-shlex.txt)"
echo
echo "and the CI half of the same clause, read at the 2.0.1 release commit rather than master:"
grep -n -E 'name: Test \(MSRV\)|rustup toolchain install 1.46|rustup default 1.46|runs-on:' shlex-ci.yml
echo
echo "the floor the policy resolves to today, from the published stable channel:"
grep -A2 '^\[pkg.rustc\]' channel.toml | grep '^version'
echo "(stable minus 2 minor versions; 1.46.0 sits far below it, and gate 2 asks for the"
echo " declaration and the CI job, both of which shlex 2.0.1 has.)"

sub "the controller ruling this reading comes from"
grep -n 'RULING WITHDRAWN' "$REPO/docs/planning/p02/execution-ledger.md"
assert_hasre S99 'RULING WITHDRAWN: fitness gate 2 is read strictly' "$REPO/docs/planning/p02/execution-ledger.md" "the strict gate-2 reading is recorded in the execution ledger"

hr "16. assertion summary"
printf '%s' "$RESULTS"
printf '\nassertions: %s   failures: %s\n' "$ASSERTS" "$FAILURES"
printf 'retrieved: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
exit "$FAILURES"
