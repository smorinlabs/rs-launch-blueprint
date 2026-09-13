#!/bin/bash
# R63 progress-spinner — decision-audit empirical check. Revision 2.
# Verifies claims made in the raw reports. Implements nothing: no crate is
# scaffolded, no spinner is written, no cargo build/test/audit is run and no
# terminal is driven.
#
# Revision 2 changes, answering review/audit-codex.r1.md:
#   * sections 12-18 are inline code in this script, not a commented-out
#     `supplements()` function, so one run emits every section the decision
#     cites (0-18 plus the DONE summary);
#   * `set -o pipefail` is on, and every `curl`/`git show`/`gh api` that used to
#     feed a pipe now writes a file first, so a failed fetch cannot be masked by
#     a succeeding `grep`/`head`;
#   * every claim is asserted on the CONTENT it expects (`chk`/`lit`/`cnt`/
#     `code` print PASS or FAIL) rather than on an exit code alone; recorded
#     grep exit codes are kept beside the assertions as raw observation, never
#     as the assertion;
#   * time-varying output carries a literal `VOLATILE: ` prefix and host-specific
#     output a literal `HOST: ` prefix, so a rerun is compared with:
#         diff <(grep -vE '^(VOLATILE|HOST): ' a.log) \
#              <(grep -vE '^(VOLATILE|HOST): ' b.log)
#   * the run ends with `checks: N pass / M fail` and exits non-zero on any
#     FAIL, so this check can fail.
#
# Rerun:  bash review/evidence/r63-spinner-claims.sh \
#           > review/evidence/r63-spinner-claims.log 2>&1
#         from the run directory
#         research/runs/R63/2026-09-05T183003Z-44e034fc1d72.
# Override the scratch directory with R63_WORK, the pinned checkouts with
# TS_REPO / PY_REPO.

set -u
set -o pipefail

UA='rs-launch-blueprint-research/R63'
W="${R63_WORK:-/private/tmp/claude-501/-Users-stevemorin-c-rs-launch-blueprint-p02-plan/b7c06b2f-d78d-4987-b237-63eeced4bd23/scratchpad/r63}"
TS=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
PY=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TSREPO="${TS_REPO:-$HOME/c/ts-launch-blueprint}"
PYREPO="${PY_REPO:-$HOME/c/py-launch-blueprint}"

mkdir -p "$W/src" "$W/fetch" && cd "$W" || exit 1

PASS=0
FAIL=0

hr(){ printf '\n===== %s =====\n' "$1"; }
sub(){ printf -- '--- %s\n' "$1"; }
vol(){ sed 's/^/VOLATILE: /'; }

ok(){  PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
bad(){ FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }

# chk <label> <expected> <actual> — assert an exact string equality.
chk(){ if [ "$2" = "$3" ]; then ok "$1 == $2"; else bad "$1: expected [$2], got [$3]"; fi; }

# lit <label> <file> <literal> — assert the file contains the literal.
lit(){
  if [ -f "$2" ] && grep -qF -- "$3" "$2"; then ok "$1"
  else bad "$1: literal absent from $2 -> $3"; fi
}

# nolit <label> <file> <literal> — assert the file does NOT contain the literal.
nolit(){
  if [ ! -f "$2" ]; then bad "$1: $2 missing"
  elif grep -qF -- "$3" "$2"; then bad "$1: literal unexpectedly present in $2 -> $3"
  else ok "$1"; fi
}

# cnt <label> <expected-count> <path> <extended-regex> — assert a match count,
# so an absence is asserted as "zero matches", not as "grep exited 1".
cnt(){
  local n
  n=$(grep -rE -- "$4" "$3" 2>/dev/null | wc -l | tr -d ' ')
  chk "$1 (match count)" "$2" "$n"
}

# fetch <label> <url> <outfile> — pipefail-safe fetch; asserts a non-empty body.
fetch(){
  local st
  curl -sS -A "$UA" -o "$3" "$2"; st=$?
  if [ "$st" -ne 0 ]; then bad "$1: curl exit $st for $2"; return 1; fi
  if [ ! -s "$3" ]; then bad "$1: empty body from $2"; return 1; fi
  ok "$1 (fetched, non-empty body)"
}

# code <label> <expected-http> <url> <outfile> — assert an HTTP status.
code(){
  local got
  got=$(curl -sS -o "$4" -w '%{http_code}' -A "$UA" "$3")
  chk "$1 HTTP" "$2" "$got"
}

# gitshow <label> <repo> <pin:path> <outfile>
gitshow(){
  local st
  git -C "$2" show "$3" > "$4"; st=$?
  if [ "$st" -ne 0 ]; then bad "$1: git show exit $st for $3"; return 1; fi
  if [ ! -s "$4" ]; then bad "$1: empty blob for $3"; return 1; fi
  ok "$1 (read at pin, $(wc -l < "$4" | tr -d ' ') lines)"
}

# json <label> <file> <python-expression-printing-result>
jsonval(){
  local out st
  out=$(python3 -c "$3" < "$2"); st=$?
  if [ "$st" -ne 0 ]; then bad "$1: python3 exit $st"; printf '%s\n' "$out"; return 1; fi
  printf '%s\n' "$out"
}

# ghapi <label> <endpoint> <jq> <outfile>
ghapi(){
  local st
  gh api "$2" --jq "$3" > "$4" 2>"$4.err"; st=$?
  if [ "$st" -ne 0 ]; then
    bad "$1: gh api exit $st"; sed -n '1,3p' "$4.err"; return 1
  fi
  ok "$1 (gh api ok)"
}

# ============================================================================
hr "0. TOOLCHAIN AND HOST"
rustc --version > fetch/rustc.txt 2>&1
lit "rustc reports a version" fetch/rustc.txt "rustc "
sed 's/^/HOST: /' fetch/rustc.txt
cargo --version > fetch/cargo.txt 2>&1
lit "cargo reports a version" fetch/cargo.txt "cargo "
sed 's/^/HOST: /' fetch/cargo.txt
printf 'HOST: os: macOS %s (%s)\n' "$(sw_vers -productVersion)" "$(uname -m)"
printf 'VOLATILE: date: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
fetch "stable channel manifest" https://static.rust-lang.org/dist/channel-rust-stable.toml fetch/channel.toml
lit "stable channel manifest has a [pkg.rust] table" fetch/channel.toml '[pkg.rust]'
STABLE=$(grep -A2 '^\[pkg.rust\]' fetch/channel.toml | grep -m1 '^version' | sed 's/.*= *"//; s/".*//')
if [ -n "$STABLE" ]; then ok "current stable channel version parsed"; else bad "current stable channel version could not be parsed"; fi
printf 'VOLATILE: current stable channel version: %s\n' "$STABLE"

# ============================================================================
hr "1. INHERITED CONTRACT AT THE ts PIN (gate predicate)"
gitshow "ts:src/commands/projects.ts @ pin" "$TSREPO" "$TS:src/commands/projects.ts" fetch/ts-projects.ts
sub "ts:src/commands/projects.ts lines 120-140 @ $TS"
sed -n '120,140p' fetch/ts-projects.ts | cat -n | sed 's/^/    /'
lit "ts pin: CI is read from the environment map" fetch/ts-projects.ts "const ci = deps.env['CI'];"
lit "ts pin: suppression predicate verbatim" fetch/ts-projects.ts "const spinnerEnabled = deps.stderrIsTTY && (ci === undefined || ci === '');"
lit "ts pin: the factory is invoked only when enabled" fetch/ts-projects.ts "const spinner = spinnerEnabled ? deps.spinner('Fetching projects...') : undefined;"

gitshow "ts:src/lib/adapters.ts @ pin" "$TSREPO" "$TS:src/lib/adapters.ts" fetch/ts-adapters.ts
sub "ts:src/lib/adapters.ts lines 25-72 @ $TS (SpinnerFactory + D-033 guard)"
sed -n '25,72p' fetch/ts-adapters.ts | cat -n | sed 's/^/    /'
lit "ts pin: D-033 zero-column guard present" fetch/ts-adapters.ts "if (!Number.isFinite(columns) || columns <= 0) {"
lit "ts pin: D-033 comment names the divide-by-width cause" fetch/ts-adapters.ts "divides the"
lit "ts pin: the caller owns the gating" fetch/ts-adapters.ts "caller owns the TTY/CI gating"

gitshow "ts:package.json @ pin" "$TSREPO" "$TS:package.json" fetch/ts-package.json
sub "ts:package.json spinner dependency @ $TS"
grep -n -i 'spinner\|ora' fetch/ts-package.json
lit "ts pin: yocto-spinner is the shipped spinner" fetch/ts-package.json '"yocto-spinner"'

gitshow "ts:docs/port/TS_PORT_DECISIONS.md @ pin" "$TSREPO" "$TS:docs/port/TS_PORT_DECISIONS.md" fetch/ts-decisions.md
sub "ts:docs/port/TS_PORT_DECISIONS.md D-016(5) / D-033 lines @ $TS"
grep -n 'progress=diagnostics\|yocto-spinner\|0-column\|0 column' fetch/ts-decisions.md | head -20
lit "ts pin: stderr-by-default rule stated as progress=diagnostics" fetch/ts-decisions.md "progress=diagnostics"
lit "ts pin: the stdout-pollution wart it repairs" fetch/ts-decisions.md "progress text polluted stdout"

# ============================================================================
hr "2. py PIN — IS THERE ANY PROGRESS INDICATOR?"
sub "git grep over *.py *.toml @ $PY"
git -C "$PYREPO" grep -il -e spinner -e tqdm -e progressbar -e 'rich.progress' -e 'Progress(' "$PY" -- '*.py' '*.toml' > fetch/py-progress.txt
PYGREP=$?
printf 'grep exit=%s (1 = no matches)\n' "$PYGREP"
cat fetch/py-progress.txt
chk "py pin: progress-indicator matches" "0" "$(wc -l < fetch/py-progress.txt | tr -d ' ')"
gitshow "py:pyproject.toml @ pin" "$PYREPO" "$PY:pyproject.toml" fetch/py-pyproject.toml
sub "py:pyproject.toml rich dependency @ $PY"
grep -n -i 'rich' fetch/py-pyproject.toml
lit "py pin: rich>=13.0.0 is declared" fetch/py-pyproject.toml '"rich>=13.0.0"'

# ============================================================================
hr "3. is_ci PREDICATE AT A PINNED VERSION"
fetch "is_ci versions endpoint" https://crates.io/api/v1/crates/is_ci/versions fetch/is_ci-versions.json
IS_CI_NEW=$(jsonval "is_ci newest unyanked" fetch/is_ci-versions.json 'import json,sys; d=json.load(sys.stdin)["versions"]; v=[x for x in d if not x["yanked"]][0]; print(v["num"])')
chk "is_ci newest unyanked version" "1.2.0" "$IS_CI_NEW"
jsonval "is_ci newest unyanked detail" fetch/is_ci-versions.json 'import json,sys; d=json.load(sys.stdin)["versions"]; v=[x for x in d if not x["yanked"]][0]; print("VOLATILE: newest unyanked:", v["num"], v["created_at"], "license:", v["license"], "rust_version:", v["rust_version"])'
fetch "is_ci 1.2.0 published artifact" https://static.crates.io/crates/is_ci/is_ci-1.2.0.crate src/is_ci-1.2.0.crate
tar -xzf src/is_ci-1.2.0.crate -C src || bad "is_ci 1.2.0 artifact did not unpack"
sub "is_ci-1.2.0/src/lib.rs (published artifact, not a branch)"
cat -n src/is_ci-1.2.0/src/lib.rs
lit "is_ci 1.2.0: CI compared by value equality" src/is_ci-1.2.0/src/lib.rs 'ci_var == Ok("true".into())'
lit "is_ci 1.2.0: the literal \"1\"" src/is_ci-1.2.0/src/lib.rs 'Ok("1".into())'
lit "is_ci 1.2.0: the literal \"woodpecker\"" src/is_ci-1.2.0/src/lib.rs 'Ok("woodpecker".into())'
lit "is_ci 1.2.0: check() is presence-only" src/is_ci-1.2.0/src/lib.rs 'std::env::var(name).is_ok()'
nolit "is_ci 1.2.0 does NOT test CI for emptiness" src/is_ci-1.2.0/src/lib.rs 'is_empty()'
CHECKVARS=$(grep -o 'check("[^"]*"' src/is_ci-1.2.0/src/lib.rs | sort -u | wc -l | tr -d ' ')
printf 'is_ci 1.2.0 distinct presence-checked variables besides CI: %s\n' "$CHECKVARS"
grep -o 'check("[^"]*"' src/is_ci-1.2.0/src/lib.rs | sed 's/check("//; s/"$//' | sort | tr '\n' ' '; echo
chk "is_ci 1.2.0 distinct presence-checked variables besides CI" "35" "$CHECKVARS"

# ============================================================================
hr "4. indicatif 0.18.6 — PUBLISHED ARTIFACT (license, MSRV, edition, stderr default)"
fetch "indicatif 0.18.6 published artifact" https://static.crates.io/crates/indicatif/indicatif-0.18.6.crate src/indicatif-0.18.6.crate
tar -xzf src/indicatif-0.18.6.crate -C src || bad "indicatif 0.18.6 artifact did not unpack"
sub "indicatif-0.18.6/Cargo.toml [package] head"
sed -n '1,40p' src/indicatif-0.18.6/Cargo.toml
lit "indicatif 0.18.6 rust-version" src/indicatif-0.18.6/Cargo.toml 'rust-version = "1.85"'
lit "indicatif 0.18.6 edition" src/indicatif-0.18.6/Cargo.toml 'edition = "2021"'
lit "indicatif 0.18.6 license" src/indicatif-0.18.6/Cargo.toml 'license = "MIT"'
sub "default features"
grep -n -A6 '^\[features\]' src/indicatif-0.18.6/Cargo.toml | head -20
# The published manifest writes the array across several lines, so the
# decision's inline rendering `default = ["unicode-width", "wasmbind"]` is the
# VALUE, not the literal text. Assert the value by parsing it.
if python3 - <<'PY'
import re
t=open('src/indicatif-0.18.6/Cargo.toml').read()
m=re.search(r'^default\s*=\s*(\[.*?\])', t, re.S|re.M)
if not m:
    print('FAIL detail: no default feature list in [features]'); raise SystemExit(1)
got=[x for x in re.findall(r'"([^"]+)"', m.group(1))]
print('indicatif 0.18.6 default feature list =', got)
raise SystemExit(0 if got == ["unicode-width","wasmbind"] else 1)
PY
then ok 'indicatif 0.18.6 default features are exactly ["unicode-width", "wasmbind"]'; else bad 'indicatif 0.18.6 default feature list is not ["unicode-width", "wasmbind"]'; fi
sub "optional async deps"
grep -n -B2 -A4 'tokio\|futures-core\|rayon' src/indicatif-0.18.6/Cargo.toml | head -40
for d in tokio futures-core rayon; do
  if python3 - "$d" <<'PY'
import re,sys
d=sys.argv[1]
t=open('src/indicatif-0.18.6/Cargo.toml').read()
m=re.search(r'\[dependencies\.'+re.escape(d)+r'\](.*?)(?=\n\[|\Z)', t, re.S)
sys.exit(0 if (m and 'optional = true' in m.group(1)) else 1)
PY
  then ok "indicatif 0.18.6: $d is optional"; else bad "indicatif 0.18.6: $d is NOT declared optional"; fi
done
sub "ProgressBar::new_spinner draw target"
grep -n -B6 -A8 'pub fn new_spinner' src/indicatif-0.18.6/src/progress_bar.rs
lit "new_spinner defaults to the stderr draw target" src/indicatif-0.18.6/src/progress_bar.rs 'Self::with_draw_target(None, ProgressDrawTarget::stderr())'
lit "new_spinner doc says it draws to stderr" src/indicatif-0.18.6/src/progress_bar.rs 'This spinner by default draws directly to stderr'
sub "ProgressDrawTarget::stderr / hidden / term"
grep -n -B8 -A10 'pub fn stderr()' src/indicatif-0.18.6/src/draw_target.rs
grep -n -B4 -A6 'pub fn hidden()' src/indicatif-0.18.6/src/draw_target.rs
grep -n -B6 -A8 'pub fn term(' src/indicatif-0.18.6/src/draw_target.rs
lit "stderr() is documented as the default draw target" src/indicatif-0.18.6/src/draw_target.rs 'This is the default draw target for progress bars'
lit "term() performs its own terminal test (why design D is rejected)" src/indicatif-0.18.6/src/draw_target.rs 'if !term.is_term() || is_dumb() {'
lit "hidden() exists as a first-class render-nothing value" src/indicatif-0.18.6/src/draw_target.rs 'pub fn hidden()'
sub "in_memory feature / InMemoryTerm"
grep -n 'in_memory' src/indicatif-0.18.6/Cargo.toml
grep -n 'pub fn contents\|impl TermLike for InMemoryTerm\|pub struct InMemoryTerm' src/indicatif-0.18.6/src/in_memory.rs
lit "in_memory feature is declared" src/indicatif-0.18.6/Cargo.toml 'in_memory = ["vt100"]'
lit "InMemoryTerm implements TermLike" src/indicatif-0.18.6/src/in_memory.rs 'impl TermLike for InMemoryTerm'
lit "InMemoryTerm::contents exists for assertions without a pty" src/indicatif-0.18.6/src/in_memory.rs 'pub fn contents'
sub "zero-width handling inside indicatif (codex claim: regression test at width 0)"
cnt "indicatif 0.18.6 zero-width regression test in src/" "0" src/indicatif-0.18.6/src/ 'draw_to_term_narrower_than_its_content'
grep -rn 'width == 0\|width() == 0\|\.max(1)' src/indicatif-0.18.6/src/*.rs | head -20
cnt "indicatif 0.18.6 explicit width==0 guard in src/" "0" src/indicatif-0.18.6/src/ 'width == 0|width\(\) == 0'
sub "unsafe count in indicatif src"
grep -rc 'unsafe' src/indicatif-0.18.6/src/*.rs | grep -v ':0$' || echo "no file contains 'unsafe'"
cnt "indicatif 0.18.6 occurrences of unsafe in src/" "0" src/indicatif-0.18.6/src/ 'unsafe'

# ============================================================================
hr "5. console 0.16.6 — ZERO-COLUMN FALLBACK (source read, NOT an executed pty test)"
fetch "console 0.16.6 published artifact" https://static.crates.io/crates/console/console-0.16.6.crate src/console-0.16.6.crate
tar -xzf src/console-0.16.6.crate -C src || bad "console 0.16.6 artifact did not unpack"
grep -n 'DEFAULT_WIDTH' src/console-0.16.6/src/unix_term.rs | head
grep -n -B6 -A12 'fn terminal_size' src/console-0.16.6/src/unix_term.rs
grep -n -B4 -A8 'pub fn size(&self)' src/console-0.16.6/src/term.rs
grep -n 'rust-version\|^license\|^edition' src/console-0.16.6/Cargo.toml
lit "console 0.16.6 DEFAULT_WIDTH is 80" src/console-0.16.6/src/unix_term.rs 'DEFAULT_WIDTH: u16 = 80'
lit "console 0.16.6 terminal_size requires positive dimensions" src/console-0.16.6/src/unix_term.rs 'if winsize.ws_row > 0 && winsize.ws_col > 0'
lit "console 0.16.6 Term::size falls back to (24, DEFAULT_WIDTH)" src/console-0.16.6/src/term.rs 'self.size_checked().unwrap_or((24, DEFAULT_WIDTH))'
lit "console 0.16.6 rust-version" src/console-0.16.6/Cargo.toml 'rust-version = "1.71"'
lit "console 0.16.6 license" src/console-0.16.6/Cargo.toml 'license = "MIT"'

# ============================================================================
hr "6. indicatif CI MATRIX AT TAG 0.18.6"
fetch "indicatif rust.yml at tag 0.18.6" https://raw.githubusercontent.com/console-rs/indicatif/0.18.6/.github/workflows/rust.yml fetch/indicatif-ci.yml
grep -n 'os:\|toolchain:\|rust:' fetch/indicatif-ci.yml | head -30
lit "indicatif CI matrix covers the required OS set" fetch/indicatif-ci.yml 'os: [ubuntu-latest, macos-latest, windows-latest]'
lit "indicatif CI has an MSRV job pinned to 1.85" fetch/indicatif-ci.yml 'toolchain: "1.85"'
lit "indicatif CI tests the stable channel" fetch/indicatif-ci.yml 'rust: [stable]'

# ============================================================================
hr "7. REGISTRY FIGURES (crates.io), retrieved now"
for c in indicatif console spinners spinoff cliclack spinach throbber-widgets-tui is_ci ci_info prodash; do
  fetch "crates.io crate record $c" "https://crates.io/api/v1/crates/$c" "fetch/crate-$c.json" || continue
  jsonval "crate record $c" "fetch/crate-$c.json" 'import json,sys; d=json.load(sys.stdin)["crate"]; print("VOLATILE: %-22s recent_downloads=%-12s downloads=%-12s max_stable=%s" % (d["name"], d.get("recent_downloads"), d.get("downloads"), d.get("max_stable_version")))'
done
sub "newest unyanked version + rust_version per candidate"
# Expected newest-unyanked version and declared rust_version, as the decision
# records them. A mismatch is not noise: it means the registry moved and the
# decision's gate-2 arithmetic is due for re-verification.
NEWEST_EXPECT="indicatif=0.18.6:1.85 spinners=4.2.0:None spinoff=0.8.0:None cliclack=0.5.6:None spinach=3.2.0:None prodash=31.0.0:1.74"
for c in indicatif spinners spinoff cliclack spinach prodash; do
  fetch "crates.io versions $c" "https://crates.io/api/v1/crates/$c/versions" "fetch/versions-$c.json" || continue
  jsonval "versions $c" "fetch/versions-$c.json" "import json,sys; vs=[v for v in json.load(sys.stdin)['versions'] if not v['yanked']]; v=vs[0]; print('VOLATILE: %-22s num=%-8s created_at=%-22s license=%-22s rust_version=%s' % ('$c', v['num'], v['created_at'], v['license'], v['rust_version']))"
  got=$(jsonval "newest $c" "fetch/versions-$c.json" "import json,sys; vs=[v for v in json.load(sys.stdin)['versions'] if not v['yanked']]; v=vs[0]; print('%s:%s' % (v['num'], v['rust_version']))")
  exp=$(printf '%s\n' $NEWEST_EXPECT | tr ' ' '\n' | grep "^$c=" | cut -d= -f2)
  chk "$c newest unyanked version:rust_version (registry moved if this fails)" "$exp" "$got"
done

# ============================================================================
hr "8. GITHUB REPO FIGURES + OPEN ISSUES (mandated total_count, not open_issues_count)"
for r in console-rs/indicatif fadeevab/cliclack FGRibreau/spinners ad4mx/spinoff GitoxideLabs/prodash zkat/is_ci; do
  slug=$(printf '%s' "$r" | tr '/' '-')
  ghapi "gh repo record $r" "repos/$r" '"\(.full_name) stars=\(.stargazers_count) archived=\(.archived) pushed_at=\(.pushed_at) open_issues_count(incl PRs)=\(.open_issues_count)"' "fetch/repo-$slug.txt" || { sleep 2; continue; }
  vol < "fetch/repo-$slug.txt"
  sleep 2
done
lit "console-rs/indicatif is not archived (maintenance rubric)" fetch/repo-console-rs-indicatif.txt 'archived=false'
lit "ad4mx/spinoff is not archived" fetch/repo-ad4mx-spinoff.txt 'archived=false'
ghapi "gh open-issue search for console-rs/indicatif" "search/issues?q=repo:console-rs/indicatif+is:issue+is:open" '"console-rs/indicatif open issues (search total_count) = \(.total_count)"' fetch/indicatif-issues.txt
vol < fetch/indicatif-issues.txt
ISSUES=$(sed 's/.*= //' fetch/indicatif-issues.txt)
if printf '%s' "$ISSUES" | grep -qE '^[0-9]+$'; then ok "open-issue total_count is a number (value on the VOLATILE line above)"; else bad "open-issue total_count is not a number: [$ISSUES]"; fi

# ============================================================================
hr "9. RUSTSEC PAGES + 404-MEANS-CLEAN CONTROL"
for p in indicatif console unicode-width portable-atomic unit-prefix libc is_ci ci_info spinners spinoff cliclack; do
  code "rustsec $p (404 expected = no advisory page)" 404 "https://rustsec.org/packages/$p.html" "$W/fetch/rustsec-$p.html"
done
sub "control: crates known to have advisories must return 200 with RUSTSEC- content"
for p in time openssl atty; do
  code "rustsec control $p" 200 "https://rustsec.org/packages/$p.html" "$W/fetch/rustsec-$p.html"
  n=$(grep -c 'RUSTSEC-' "$W/fetch/rustsec-$p.html" | tr -d ' ')
  printf 'VOLATILE: %-20s RUSTSEC- mentions=%s\n' "$p" "$n"
  if [ "${n:-0}" -gt 0 ]; then ok "rustsec control $p names at least one RUSTSEC- advisory"; else bad "rustsec control $p names no RUSTSEC- advisory, so 404 cannot be read as clean"; fi
done

# ============================================================================
hr "10. EXCLUDED-CANDIDATE CLAIMS AT PUBLISHED VERSIONS"
fetch "spinoff 0.8.0 published artifact" https://static.crates.io/crates/spinoff/spinoff-0.8.0.crate src/spinoff-0.8.0.crate
tar -xzf src/spinoff-0.8.0.crate -C src || bad "spinoff 0.8.0 artifact did not unpack"
sub "spinoff 0.8.0: default stream (opus claim: stdout)"
grep -n -B4 -A6 'stdout stream\|Stdout' src/spinoff-0.8.0/src/lib.rs | head -40
grep -n 'rust-version' src/spinoff-0.8.0/Cargo.toml || echo "spinoff 0.8.0 Cargo.toml: NO rust-version key"
nolit "spinoff 0.8.0 declares no rust-version (gate 2)" src/spinoff-0.8.0/Cargo.toml 'rust-version'
fetch "spinners 4.2.0 published artifact" https://static.crates.io/crates/spinners/spinners-4.2.0.crate src/spinners-4.2.0.crate
tar -xzf src/spinners-4.2.0.crate -C src || bad "spinners 4.2.0 artifact did not unpack"
sub "spinners 4.2.0: EPIPE panic claim + default stream + rust-version"
grep -n 'expect("IO Error")' src/spinners-4.2.0/src/lib.rs
grep -rn 'default\]' src/spinners-4.2.0/src/utils/stream.rs | head
grep -n 'rust-version' src/spinners-4.2.0/Cargo.toml || echo "spinners 4.2.0 Cargo.toml: NO rust-version key"
grep -n 'lazy_static\|maplit\|strum' src/spinners-4.2.0/Cargo.toml
lit "spinners 4.2.0 render loop panics on a write error" src/spinners-4.2.0/src/lib.rs 'stream.write(&frame, &message, start_time, stop_time).expect("IO Error")'
nolit "spinners 4.2.0 declares no rust-version (gate 2)" src/spinners-4.2.0/Cargo.toml 'rust-version'
sub "cliclack: rust_version across recent versions + CI presence"
jsonval "cliclack recent versions" fetch/versions-cliclack.json 'import json,sys; [print("VOLATILE:", v["num"], "rust_version=", v["rust_version"], "license=", v["license"]) for v in json.load(sys.stdin)["versions"][:4]]'
if python3 - <<'PY'
import json
vs=json.load(open('fetch/versions-cliclack.json'))['versions'][:4]
raise SystemExit(0 if all(v['rust_version'] is None for v in vs) else 1)
PY
then ok "cliclack: the four most recent versions all declare rust_version None"; else bad "cliclack: one of the four most recent versions now declares a rust-version"; fi
ghapi "gh cliclack repository contents" "repos/fadeevab/cliclack/contents" '[.[].name] | join(", ")' fetch/cliclack-contents.txt
cat fetch/cliclack-contents.txt
nolit "cliclack repository root has no .github directory (gate 4)" fetch/cliclack-contents.txt '.github'
CLICLACK_WF=$(gh api "repos/fadeevab/cliclack/contents/.github/workflows" > fetch/cliclack-workflows.txt 2>&1; echo "gh-exit=$?")
sed -n '1,3p' fetch/cliclack-workflows.txt
printf 'cliclack .github/workflows: %s (non-zero is the expected 404)\n' "$CLICLACK_WF"
lit "cliclack .github/workflows returns the expected 404" fetch/cliclack-workflows.txt '404'

# ============================================================================
hr "11. MSRV ARITHMETIC CHECK"
echo "policy floor = stable minus 2 minor versions; recommended tree maxima:"
TREE_EXPECT="indicatif=1.85 console=1.71 unicode-width=1.66 portable-atomic=1.34 unit-prefix=1.31.0"
for c in indicatif console unicode-width portable-atomic unit-prefix; do
  fetch "crates.io versions $c" "https://crates.io/api/v1/crates/$c/versions" "fetch/versions-$c.json" || continue
  jsonval "tree member $c" "fetch/versions-$c.json" "import json,sys; vs=[v for v in json.load(sys.stdin)['versions'] if not v['yanked']]; print('VOLATILE: %-18s newest=%s rust_version=%s license=%s' % ('$c', vs[0]['num'], vs[0]['rust_version'], vs[0]['license']))"
  got=$(jsonval "tree rust_version $c" "fetch/versions-$c.json" "import json,sys; vs=[v for v in json.load(sys.stdin)['versions'] if not v['yanked']]; print(vs[0]['rust_version'])")
  exp=$(printf '%s\n' $TREE_EXPECT | tr ' ' '\n' | grep "^$c=" | cut -d= -f2)
  chk "$c declared rust-version (gate 2 arithmetic)" "$exp" "$got"
done
# The floor is stable minus two minor versions. Assert the recommended tree's
# maximum declared rust-version (1.85) sits at or below it.
FLOOR=$(python3 - "$STABLE" <<'PY'
import sys,re
m=re.match(r'(\d+)\.(\d+)', sys.argv[1])
print('%s.%s' % (m.group(1), int(m.group(2))-2) if m else 'unparsed')
PY
)
printf 'VOLATILE: stable=%s -> policy floor=%s; recommended tree maximum declared rust-version=1.85\n' "$STABLE" "$FLOOR"
if python3 - "$FLOOR" <<'PY'
import sys
f=[int(x) for x in sys.argv[1].split('.')[:2]]
raise SystemExit(0 if f >= [1,85] else 1)
PY
then ok "the policy floor is at or above the tree maximum 1.85 (gate 2 passes)"; else bad "the policy floor is BELOW the tree maximum 1.85 — gate 2 no longer passes"; fi

# ============================================================================
# Sections 12-18 were follow-up checks in revision 1, run by hand and appended
# to the log. They are inline code here, in the same order and with the same
# section titles the cited log carries, so one run of this script emits every
# section the decision attributes to it.
# ============================================================================
hr "12. SUPPLEMENT: CLAIMS NOT RESOLVED BY THE FIRST PASS"
sub "spinoff 0.8.0 default stream (published artifact src/lib.rs)"
grep -n -i 'stdout' src/spinoff-0.8.0/src/lib.rs | head -20
lit "spinoff 0.8.0 documents stdout as its ordinary stream (section 10's grep missed it: the doc line brackets stdout in backticks)" src/spinoff-0.8.0/src/lib.rs 'This function outputs to the `stdout` stream.'
sub "spinners 4.2.0 default Stream variant"
sed -n '1,30p' src/spinners-4.2.0/src/utils/stream.rs
if python3 - <<'PY'
import re
t=open('src/spinners-4.2.0/src/utils/stream.rs').read()
m=re.search(r'#\[default\]\s*\n\s*(\w+)', t)
print('spinners 4.2.0 #[default] variant =', m.group(1) if m else 'NONE')
raise SystemExit(0 if (m and m.group(1)=='Stderr') else 1)
PY
then ok "spinners 4.2.0 defaults to Stderr (so it is excluded on gate 2 and the panic path, not on its stream)"; else bad "spinners 4.2.0 default Stream variant is not Stderr"; fi
sub "codex claim: indicatif regression test 'draw_to_term_narrower_than_its_content'"
echo "search in the PUBLISHED 0.18.6 artifact (all files):"
grep -rn 'draw_to_term_narrower_than_its_content' src/indicatif-0.18.6/; printf 'grep exit=%s (1 = not present in the published artifact)\n' "$?"
cnt "0.18.6 published artifact: zero-width regression test" "0" src/indicatif-0.18.6/ 'draw_to_term_narrower_than_its_content'
echo "files shipped in indicatif-0.18.6:"
find src/indicatif-0.18.6 -type f | sort
echo "search at the 0.18.6 GIT TAG (draw_target.rs):"
fetch "indicatif draw_target.rs at tag 0.18.6" https://raw.githubusercontent.com/console-rs/indicatif/0.18.6/src/draw_target.rs fetch/dt-tag.rs
grep -n 'draw_to_term_narrower_than_its_content' fetch/dt-tag.rs; printf 'grep exit=%s (1 = not at tag 0.18.6 either)\n' "$?"
cnt "0.18.6 git tag: zero-width regression test" "0" fetch/dt-tag.rs 'draw_to_term_narrower_than_its_content'
lit "the tag blob is the right file (sanity: it defines ProgressDrawTarget)" fetch/dt-tag.rs 'impl ProgressDrawTarget'
echo "search on the moving main branch (what the codex report read):"
fetch "indicatif draw_target.rs on main (moving branch)" https://raw.githubusercontent.com/console-rs/indicatif/main/src/draw_target.rs fetch/dt-main.rs
grep -n -A16 'fn draw_to_term_narrower_than_its_content' fetch/dt-main.rs | vol
printf 'VOLATILE: grep exit=%s\n' "$?"
lit "the zero-width regression test exists on main (the branch the codex raw cited)" fetch/dt-main.rs 'fn draw_to_term_narrower_than_its_content()'
lit "the main-branch test builds a NarrowTerm fake" fetch/dt-main.rs 'struct NarrowTerm'
sub "indicatif 0.18.6: any explicit zero-width guard in its own source?"
cnt "0.18.6 explicit zero-width guard" "0" src/indicatif-0.18.6/src/ 'width == 0|width\(\) == 0'
sub "console 0.16.6 terminal_size: the positive-dimension test (opus claim, line ~66)"
sed -n '53,80p' src/console-0.16.6/src/unix_term.rs
lit "console 0.16.6: a zero column count yields None, not a zero width" src/console-0.16.6/src/unix_term.rs 'if winsize.ws_row > 0 && winsize.ws_col > 0'

# ============================================================================
hr "13. SUPPLEMENT 2: THE WIDTH PATH AT 0.18.6"
sub "console 0.16.6: impl TermLike-equivalent width source for Term"
grep -rn 'impl TermLike for Term\|fn width(&self)' src/indicatif-0.18.6/src/*.rs
lit "indicatif 0.18.6 implements TermLike for console::Term" src/indicatif-0.18.6/src/term_like.rs 'impl TermLike for Term'
sub "indicatif 0.18.6 term_like.rs (how width reaches the draw code)"
sed -n '1,50p' src/indicatif-0.18.6/src/term_like.rs
lit "TermLike::width is the trait method the draw target consumes" src/indicatif-0.18.6/src/term_like.rs 'fn width(&self) -> u16;'
sub "indicatif 0.18.6: divisions by a width value (the ts flood hazard analogue)"
grep -rn '/ width\|div_ceil' src/indicatif-0.18.6/src/*.rs
cnt "0.18.6 divisions by a width value in src/" "1" src/indicatif-0.18.6/src/ '/ width as f64|div_ceil'
sub "indicatif 0.18.6 draw_target.rs: where width() is consumed"
grep -rn 'width()' src/indicatif-0.18.6/src/*.rs
sub "prodash 31.0.0 declared rust-version (codex asserted 1.85)"
jsonval "prodash newest unyanked" fetch/versions-prodash.json 'import json,sys; vs=[v for v in json.load(sys.stdin)["versions"] if not v["yanked"]]; print("VOLATILE: prodash newest unyanked", vs[0]["num"], "rust_version=", vs[0]["rust_version"], "license=", vs[0]["license"])'

# ============================================================================
hr "14. SUPPLEMENT 3: THE DIVIDE-BY-WIDTH SITE AT 0.18.6"
sub "indicatif 0.18.6 src/term_like.rs impl TermLike for Term (width source)"
grep -n -A12 'impl TermLike for Term' src/indicatif-0.18.6/src/term_like.rs
lit "Term's width is console::Term::size().1" src/indicatif-0.18.6/src/term_like.rs 'self.size().1'
sub "indicatif 0.18.6 src/draw_target.rs around the division (line 690-720)"
awk 'NR>=690 && NR<=720 {printf "%d\t%s\n", NR, $0}' src/indicatif-0.18.6/src/draw_target.rs
# The division and its cfg guard, asserted as text rather than as line numbers.
if python3 - <<'PY'
import re
t=open('src/indicatif-0.18.6/src/draw_target.rs').read().splitlines()
div=[i for i,l in enumerate(t) if '(unwrapped_width as f64 / width as f64).ceil()' in l]
if len(div)!=1:
    print('FAIL detail: expected exactly one division by width, found', len(div)); raise SystemExit(1)
i=div[0]
# walk back to the nearest cfg attribute above the enclosing fn
guard=None
for j in range(i, max(0,i-20), -1):
    if t[j].strip().startswith('#[cfg('):
        guard=t[j].strip(); break
print('division at 1-based line', i+1, 'guarded by', guard)
raise SystemExit(0 if guard == '#[cfg(not(feature = "unicode-width"))]' else 1)
PY
then ok "the only division by width sits under #[cfg(not(feature = \"unicode-width\"))]"; else bad "the division by width is not under the non-default unicode-width cfg arm"; fi
sub "and the same region at the moving main branch, for comparison"
grep -n -A22 '#\[cfg(not(feature = "unicode-width"))\]' fetch/dt-main.rs | sed -n '1,30p' | vol

# ============================================================================
hr "15. SUPPLEMENT 4: THE DEFAULT-FEATURE WIDTH PATH AT 0.18.6"
echo 'default features are ["unicode-width", "wasmbind"], so the cfg(feature="unicode-width") arm is the one compiled:'
awk 'NR>=655 && NR<=700 {printf "%d\t%s\n", NR, $0}' src/indicatif-0.18.6/src/draw_target.rs
if python3 - <<'PY'
t=open('src/indicatif-0.18.6/src/draw_target.rs').read().splitlines()
idx=[i for i,l in enumerate(t) if l.strip()=='#[cfg(feature = "unicode-width")]'
     and 'fn wrapped_metrics' in t[i+1]]
if len(idx)!=1:
    print('FAIL detail: expected one default-feature wrapped_metrics, found', len(idx)); raise SystemExit(1)
i=idx[0]
body=[]
for l in t[i+2:]:
    if l.strip().startswith('#[cfg('): break
    body.append(l)
body='\n'.join(body)
print('default-feature wrapped_metrics starts at 1-based line', i+1)
print('per-character loop present:', 'for ch in substr.chars()' in body)
print('division present in the default-feature arm:', '/ width' in body)
raise SystemExit(0 if ('for ch in substr.chars()' in body and '/ width' not in body) else 1)
PY
then ok "the default-feature width path is a per-character loop and contains no division"; else bad "the default-feature width path does not match the decision's reading"; fi

# ============================================================================
hr "16. SUPPLEMENT 5: DOES indicatif 0.18.6 READ ANY ENVIRONMENT VARIABLE?"
sub "env access in indicatif-0.18.6/src"
grep -rn 'env::var\|env!\|std::env' src/indicatif-0.18.6/src/; printf 'grep exit=%s (1 = no env access anywhere in indicatif src)\n' "$?"
cnt "indicatif 0.18.6 env accesses in src/" "0" src/indicatif-0.18.6/src/ 'env::var|env!|std::env'
sub "the string CI as a variable name in indicatif src"
grep -rn '"CI"' src/indicatif-0.18.6/src/; printf 'grep exit=%s (1 = indicatif never reads CI)\n' "$?"
cnt "indicatif 0.18.6 occurrences of the literal \"CI\" in src/" "0" src/indicatif-0.18.6/src/ '"CI"'
sub "is_dumb(): where the TERM read actually lives (console 0.16.6)"
grep -rn 'fn is_dumb\|"TERM"' src/console-0.16.6/src/*.rs src/indicatif-0.18.6/src/*.rs
lit "is_dumb() lives in console 0.16.6" src/console-0.16.6/src/term.rs 'pub fn is_dumb() -> bool {'
lit "is_dumb() reads TERM" src/console-0.16.6/src/term.rs 'env::var("TERM")'

# ============================================================================
hr "17. SUPPLEMENT 6: enable_steady_tick AND finish_and_clear AT 0.18.6"
grep -n -B14 -A6 'pub fn enable_steady_tick' src/indicatif-0.18.6/src/progress_bar.rs
grep -n -B4 -A6 'pub fn finish_and_clear' src/indicatif-0.18.6/src/progress_bar.rs
grep -n -B3 -A6 'pub fn is_hidden' src/indicatif-0.18.6/src/progress_bar.rs
lit "enable_steady_tick exists and takes a Duration" src/indicatif-0.18.6/src/progress_bar.rs 'pub fn enable_steady_tick(&self, interval: Duration) {'
lit "enable_steady_tick doc: spawns a background thread to tick" src/indicatif-0.18.6/src/progress_bar.rs 'Spawns a background thread to tick the progress bar'
lit "enable_steady_tick doc: advances bars that are very slow by themselves" src/indicatif-0.18.6/src/progress_bar.rs 'This is useful to advance progress bars that are very slow by themselves'
lit "finish_and_clear exists (the cleared-on-both-paths criterion)" src/indicatif-0.18.6/src/progress_bar.rs 'pub fn finish_and_clear(&self) {'
lit "is_hidden exists (a suppressed path is observable)" src/indicatif-0.18.6/src/progress_bar.rs 'pub fn is_hidden(&self) -> bool {'

# ============================================================================
hr "18. SUPPLEMENT 7: THE TWO CANDIDATES ONLY THE CODEX RAW SURVEYED"
sub "prodash: rust-version on the MOVING main branch vs the PUBLISHED 31.0.0 artifact"
fetch "prodash Cargo.toml on main (moving branch)" https://raw.githubusercontent.com/GitoxideLabs/prodash/main/Cargo.toml fetch/prodash-main-Cargo.toml
PRODASH_MAIN=$(grep -m1 'rust-version' fetch/prodash-main-Cargo.toml)
printf 'VOLATILE: main Cargo.toml: %s\n' "$PRODASH_MAIN"
fetch "prodash 31.0.0 published artifact" https://static.crates.io/crates/prodash/prodash-31.0.0.crate src/prodash-31.0.0.crate
tar -xzf src/prodash-31.0.0.crate -C src || bad "prodash 31.0.0 artifact did not unpack"
printf 'published 31.0.0 Cargo.toml: %s\n' "$(grep -m1 'rust-version' src/prodash-31.0.0/Cargo.toml)"
grep -m1 '^license' src/prodash-31.0.0/Cargo.toml
lit "prodash 31.0.0 published rust-version is 1.74 (not the 1.85 the codex raw read off main)" src/prodash-31.0.0/Cargo.toml 'rust-version = "1.74"'
lit "prodash 31.0.0 license is MIT (gate 1 passes)" src/prodash-31.0.0/Cargo.toml 'license = "MIT"'
lit "prodash main declares 1.85, which is where the codex figure came from" fetch/prodash-main-Cargo.toml 'rust-version = "1.85"'
sub "prodash CI matrix (gate 4: macOS required)"
fetch "prodash ci.yml on main (moving branch)" https://raw.githubusercontent.com/GitoxideLabs/prodash/main/.github/workflows/ci.yml fetch/prodash-ci.yml
grep -n -i 'runs-on\|os:\|macos\|ubuntu\|windows' fetch/prodash-ci.yml | vol
UBUNTU=$(grep -c 'runs-on: ubuntu-latest' fetch/prodash-ci.yml | tr -d ' ')
WINDOWS=$(grep -c 'runs-on: windows-latest' fetch/prodash-ci.yml | tr -d ' ')
MACOS=$(grep -ci 'macos' fetch/prodash-ci.yml | tr -d ' ')
printf 'VOLATILE: prodash CI jobs: ubuntu-latest=%s windows-latest=%s macos-mentions=%s\n' "$UBUNTU" "$WINDOWS" "$MACOS"
chk "prodash CI macOS mentions (gate 4 fails at 0)" "0" "$MACOS"
if [ "${UBUNTU:-0}" -gt 0 ]; then ok "prodash CI does run on ubuntu-latest, so the file was read"; else bad "prodash CI has no ubuntu-latest job — the workflow file is not what the decision read"; fi
sub "prodash default features (gate 5)"
grep -n -A12 '^\[features\]' src/prodash-31.0.0/Cargo.toml | head -20
lit "prodash 31.0.0 default features" src/prodash-31.0.0/Cargo.toml 'default = ["progress-tree"]'
sub "prodash RustSec"
code "rustsec prodash (404 expected = no advisory page)" 404 https://rustsec.org/packages/prodash.html "$W/fetch/rustsec-prodash.html"
sub "spinner (TheNeikos): license and archived state (codex excluded it on both)"
fetch "crates.io versions spinner" https://crates.io/api/v1/crates/spinner/versions fetch/versions-spinner.json
jsonval "spinner newest unyanked" fetch/versions-spinner.json 'import json,sys; v=[x for x in json.load(sys.stdin)["versions"] if not x["yanked"]][0]; print("VOLATILE: newest unyanked:", v["num"], v["created_at"], "license:", v["license"], "rust_version:", v["rust_version"])'
SPIN=$(jsonval "spinner license" fetch/versions-spinner.json 'import json,sys; v=[x for x in json.load(sys.stdin)["versions"] if not x["yanked"]][0]; print("%s:%s" % (v["num"], v["license"]))')
chk "spinner newest unyanked version:license (gate 1 fails on LGPL-3.0)" "0.5.0:LGPL-3.0" "$SPIN"
ghapi "gh repo record TheNeikos/spinner" repos/TheNeikos/spinner '"TheNeikos/spinner archived=\(.archived) stars=\(.stargazers_count) pushed_at=\(.pushed_at)"' fetch/repo-spinner.txt
vol < fetch/repo-spinner.txt
lit "TheNeikos/spinner is archived (maintenance rubric)" fetch/repo-spinner.txt 'archived=true'

# ============================================================================
hr "DONE"
printf 'checks: %d pass / %d fail\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf 'RESULT: FAIL — %d assertion(s) did not hold; the decision text that cites them is stale.\n' "$FAIL"
  exit 1
fi
printf 'RESULT: PASS — every asserted claim held at the pinned versions and recorded endpoints.\n'
exit 0
