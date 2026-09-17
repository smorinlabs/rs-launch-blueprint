#!/usr/bin/env bash
# shellcheck disable=SC2016  # backticks inside single quotes are Markdown, quoted verbatim from
#                              the sources being asserted on; expansion here would corrupt the match.
# shellcheck disable=SC2329  # cleanup() is invoked indirectly, by the EXIT trap below.
#
# R61 interactive-prompts — empirical check for review/DECISION.md (revision 1).
#
# Verifies the claims the decision rests on. It never implements the
# recommendation: no prompt seam, no template scaffold, no CLI. The two cargo
# spikes below resolve dependency graphs and observe one library call; they are
# throwaway manifests written under $TMPDIR and removed by this script.
#
# Every assertion is on CONTENT, not on an exit status alone. Assertions that do
# read an exit status or an HTTP status are paired with a content assertion on
# the same artifact. The script counts its failures and exits with that count, so
# it is a check capable of failing.
#
# Rerunnable from a clean `git archive HEAD` extraction: checks that need the
# repository's .git directory, or a checkout outside this repository, SKIP by
# name instead of failing.
#
# Usage:  bash r61-claims.sh            (from anywhere; paths are derived)

set -u
set -o pipefail

GREP=/usr/bin/grep          # the BSD/GNU system grep, never a shell alias
SHASUM=/usr/bin/shasum
CURL=/usr/bin/curl
UA='rs-launch-blueprint-p02-research/1.0'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REVIEW_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RUN_DIR="$(cd "$REVIEW_DIR/.." && pwd)"
REPO_ROOT="$(cd "$RUN_DIR/../../../.." && pwd)"   # <repo>/research/runs/R61/<run> -> <repo>
DECISION="$REVIEW_DIR/DECISION.md"
WORK="${TMPDIR:-/tmp}/r61-claims-$$"
STANDARD_REPO=/Users/stevemorin/c/cli-standards
STANDARD_BLOB=f9de0437baece3383e73ca2c5f48b7ab399b51c7

PASS=0
FAIL=0
SKIP=0

ok()   { PASS=$((PASS+1)); printf 'PASS %s — %s\n' "$1" "$2"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP+1)); printf 'SKIP %s — %s\n' "$1" "$2"; }

# assert_contains <id> <file> <fixed-string> <description>
assert_contains() {
  if [ ! -f "$2" ]; then bad "$1" "$4 [file missing: $2]"; return; fi
  if "$GREP" -qF -- "$3" "$2"; then ok "$1" "$4"; else bad "$1" "$4 [not found: $3]"; fi
}

# assert_eq <id> <actual> <expected> <description>
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1" "$4 [= $3]"; else bad "$1" "$4 [got '$2', want '$3']"; fi
}

cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT
mkdir -p "$WORK/crates" "$WORK/snap"

echo "================================================================"
echo "R61 interactive-prompts — empirical check"
echo "run directory : $RUN_DIR"
echo "executed at   : $(date -u '+%Y-%m-%dT%H:%M:%SZ') (UTC)"
echo "retrieval date for every live figure below: the date on the line above"
echo "================================================================"

echo
echo "### Section 1 — toolchain and platform"
rustc --version || true
cargo --version || true
echo "os: $(uname -sm) / macOS $(sw_vers -productVersion 2>/dev/null || echo 'n/a')"
echo "python3: $(python3 --version 2>&1)"
echo "grep binary: $GREP  ($($GREP --version 2>/dev/null | head -1))"
RUSTC_V="$(rustc --version 2>/dev/null | awk '{print $2}')"
case "$RUSTC_V" in
  1.9[0-9]*) ok C1a "local rustc is in the 1.9x series (observed $RUSTC_V)";;
  *)         bad C1a "local rustc unexpected (observed '$RUSTC_V')";;
esac

echo
echo "### Section 2 — candidate tarballs, checksum-verified against crates.io"
echo "endpoint: GET https://static.crates.io/crates/<n>/<n>-<v>.crate"
echo "endpoint: GET https://crates.io/api/v1/crates/<n>/<v>   field: version.checksum"
for spec in inquire:0.9.4 dialoguer:0.12.0 crossterm:0.29.0 console:0.16.6 cliclack:0.5.6 demand:2.1.0; do
  n="${spec%%:*}"; v="${spec##*:}"
  $CURL -sSL -A "$UA" -o "$WORK/crates/$n-$v.crate" \
    "https://static.crates.io/crates/$n/$n-$v.crate"
  got="$($SHASUM -a 256 "$WORK/crates/$n-$v.crate" 2>/dev/null | cut -d' ' -f1)"
  want="$($CURL -sS -A "$UA" "https://crates.io/api/v1/crates/$n/$v" \
    | python3 -c 'import sys,json;print(json.load(sys.stdin)["version"]["checksum"])' 2>/dev/null)"
  if [ -n "$want" ] && [ "$got" = "$want" ]; then
    ok "C2-$n" "$n $v tarball sha256 equals crates.io version.checksum ($got)"
    tar xzf "$WORK/crates/$n-$v.crate" -C "$WORK/crates"
  else
    bad "C2-$n" "$n $v checksum mismatch or unavailable (got '$got', want '$want')"
  fi
done
CR="$WORK/crates"

echo
echo "### Section 3 — THE LOAD-BEARING FINDING: the prompt back-ends open /dev/tty"
echo "crossterm-0.29.0/src/terminal/sys/file_descriptor.rs, tty_fd():"
sed -n '122,140p' "$CR/crossterm-0.29.0/src/terminal/sys/file_descriptor.rs" 2>/dev/null
assert_contains C3a "$CR/crossterm-0.29.0/src/terminal/sys/file_descriptor.rs" \
  'pub fn tty_fd() -> io::Result<FileDesc<' "crossterm declares tty_fd()"
assert_contains C3b "$CR/crossterm-0.29.0/src/terminal/sys/file_descriptor.rs" \
  '.open("/dev/tty")?' "crossterm tty_fd() opens /dev/tty when stdin is not a terminal"
assert_contains C3c "$CR/crossterm-0.29.0/src/terminal/sys/file_descriptor.rs" \
  'libc::isatty(libc::STDIN_FILENO) == 1' "crossterm tty_fd() branches on isatty(STDIN_FILENO)"
echo "crossterm-0.29.0/src/terminal/sys/unix.rs, enable_raw_mode():"
sed -n '107,118p' "$CR/crossterm-0.29.0/src/terminal/sys/unix.rs" 2>/dev/null
assert_contains C3d "$CR/crossterm-0.29.0/src/terminal/sys/unix.rs" \
  'let tty = tty_fd()?;' "crossterm enable_raw_mode() is built on tty_fd()"
echo "console-0.16.6/src/unix_term.rs, Input::unbuffered():"
sed -n '87,99p' "$CR/console-0.16.6/src/unix_term.rs" 2>/dev/null
assert_contains C3e "$CR/console-0.16.6/src/unix_term.rs" \
  'fn unbuffered() -> io::Result<Self>' "console declares Input::unbuffered()"
assert_contains C3f "$CR/console-0.16.6/src/unix_term.rs" \
  '.open("/dev/tty")?;' "console Input::unbuffered() opens /dev/tty when stdin is not a terminal"

echo
echo "### Section 4 — console raises SIGINT to the process on ^C (the dialoguer path)"
sed -n '354,366p' "$CR/console-0.16.6/src/unix_term.rs" 2>/dev/null
assert_contains C4a "$CR/console-0.16.6/src/unix_term.rs" \
  'if the user hit ^C we want to signal SIGINT to ourselves' "console comments the self-signal"
assert_contains C4b "$CR/console-0.16.6/src/unix_term.rs" \
  'libc::raise(libc::SIGINT);' "console read_single_key raises SIGINT rather than returning a value"

echo
echo "### Section 5 — inquire 0.9.4 API facts"
sed -n '141,154p' "$CR/inquire-0.9.4/src/prompts/prompt.rs" 2>/dev/null
assert_contains C5a "$CR/inquire-0.9.4/src/prompts/prompt.rs" \
  'return Err(InquireError::OperationCanceled);' "inquire maps ESC (Action::Cancel) to OperationCanceled"
assert_contains C5b "$CR/inquire-0.9.4/src/prompts/prompt.rs" \
  'Action::Interrupt => return Err(InquireError::OperationInterrupted),' \
  "inquire maps ^C (Action::Interrupt) to OperationInterrupted — a value, not a signal"
assert_contains C5c "$CR/inquire-0.9.4/src/prompts/confirm/mod.rs" \
  'pub fn prompt_skippable(self) -> InquireResult<Option<bool>>' "Confirm::prompt_skippable exists"
assert_contains C5d "$CR/inquire-0.9.4/src/prompts/confirm/mod.rs" \
  'Err(InquireError::OperationCanceled) => Ok(None),' "prompt_skippable turns ESC into Ok(None)"
assert_contains C5e "$CR/inquire-0.9.4/src/terminal/crossterm.rs" \
  'io: IO::Std(stderr()),' "inquire's crossterm back-end writes to stderr"
STDOUT_HITS="$("$GREP" -rlF 'stdout' "$CR/inquire-0.9.4/src" 2>/dev/null | wc -l | tr -d ' ')"
echo "files under inquire-0.9.4/src containing the string 'stdout', counted by $GREP -rlF: $STDOUT_HITS"
assert_eq C5f "$STDOUT_HITS" "0" "inquire-0.9.4/src never names stdout (counted by $GREP)"
assert_contains C5g "$CR/inquire-0.9.4/src/prompts/multiselect/mod.rs" \
  'pub fn prompt(self) -> InquireResult<Vec<T>>' "MultiSelect::prompt returns the selected VALUES (Vec<T>)"
assert_contains C5h "$CR/inquire-0.9.4/src/ui/api/render_config.rs" \
  'NO_COLOR' "inquire's RenderConfig::default consults NO_COLOR (why R65 must pass an explicit config)"
INQ_RV="$("$GREP" -m1 '^rust-version' "$CR/inquire-0.9.4/Cargo.toml" | cut -d'"' -f2)"
assert_eq C5i "$INQ_RV" "1.80.0" "inquire declares rust-version (fitness gate 2, declaration half)"
echo "inquire [features] block:"
"$GREP" -A9 '^\[features\]' "$CR/inquire-0.9.4/Cargo.toml" 2>/dev/null | head -10
assert_contains C5j "$CR/inquire-0.9.4/Cargo.toml" '"one-liners",' "one-liners is a default feature this stack drops"
assert_contains C5k "$CR/inquire-0.9.4/Cargo.toml" '"fuzzy",' "fuzzy is a default feature this stack drops"

echo
echo "### Section 6 — dialoguer 0.12.0 API facts (the ranked runner-up)"
sed -n '148,151p;203,206p' "$CR/dialoguer-0.12.0/src/prompts/multi_select.rs" 2>/dev/null
assert_contains C6a "$CR/dialoguer-0.12.0/src/prompts/multi_select.rs" \
  'pub fn interact(self) -> Result<Vec<usize>>' "dialoguer MultiSelect returns INDICES (Vec<usize>), not values"
assert_contains C6b "$CR/dialoguer-0.12.0/src/prompts/multi_select.rs" \
  'if !term.is_term() {' "dialoguer guards on the OUTPUT Term, never on stdin"
assert_contains C6c "$CR/dialoguer-0.12.0/src/prompts/multi_select.rs" \
  'self.interact_on(&Term::stderr())' "dialoguer renders on stderr by default"
DIA_RV="$("$GREP" -m1 '^rust-version' "$CR/dialoguer-0.12.0/Cargo.toml" | cut -d'"' -f2)"
assert_eq C6d "$DIA_RV" "1.66" "dialoguer declares rust-version (fitness gate 2, declaration half)"

echo
echo "### Section 7 — fitness gate 2, read strictly: cliclack and demand declare no rust-version"
echo "(the strict reading is the controller's, docs/planning/p02/execution-ledger.md)"
for n in cliclack-0.5.6 demand-2.1.0; do
  if "$GREP" -q '^rust-version' "$CR/$n/Cargo.toml" 2>/dev/null; then
    bad "C7-$n" "$n unexpectedly declares rust-version"
  else
    RVLINES="$("$GREP" -c '^rust-version' "$CR/$n/Cargo.toml" 2>/dev/null || true)"
    ok "C7-$n" "$n Cargo.toml has no rust-version key (lines matching '^rust-version', counted by $GREP: ${RVLINES:-0}) — gate 2 not cleared"
  fi
done
echo "cliclack collapses ESC and ^C into one state:"
sed -n '95,112p' "$CR/cliclack-0.5.6/src/prompt/interaction.rs" 2>/dev/null
assert_contains C7c "$CR/cliclack-0.5.6/src/prompt/interaction.rs" \
  'State::Cancel => return Err(io::ErrorKind::Interrupted.into()),' "cliclack turns Cancel into one io error"
assert_contains C7d "$CR/cliclack-0.5.6/src/prompt/interaction.rs" \
  'Ok(Key::CtrlC) => state = State::Cancel,' "cliclack maps ^C to the same State::Cancel as ESC"
echo "demand installs a process-wide SIGINT handler:"
sed -n '1,12p' "$CR/demand-2.1.0/src/ctrlc.rs" 2>/dev/null
assert_contains C7e "$CR/demand-2.1.0/src/ctrlc.rs" 'consts::SIGINT,' "demand registers a real SIGINT handler (R67 forbids a prompt-local one)"

echo
echo "### Section 8 — the org CLI Design Standard at the pinned blob"
if [ -d "$STANDARD_REPO/.git" ]; then
  git -C "$STANDARD_REPO" cat-file blob "$STANDARD_BLOB" > "$WORK/cli-design-standard.md" 2>/dev/null
  if [ -s "$WORK/cli-design-standard.md" ]; then
    BLOB_SHA="$($SHASUM -a 256 "$WORK/cli-design-standard.md" | cut -d' ' -f1)"
    BLOB_LINES="$(wc -l < "$WORK/cli-design-standard.md" | tr -d ' ')"
    echo "blob $STANDARD_BLOB -> sha256 $BLOB_SHA, $BLOB_LINES lines"
    assert_eq C8a "$BLOB_SHA" "9fb05d3dfaa5ea11fbf66422e988b0ae8c050e22a39b9fc6dd9688734f02463f" \
      "the pinned blob's content hash is stable"
    echo "--- :253 (R4.2 global flag table, --no-input) ---"; sed -n '253p' "$WORK/cli-design-standard.md"
    echo "--- :381 (R7.1) ---";                               sed -n '381p' "$WORK/cli-design-standard.md"
    echo "--- :456 (R8.1) ---";                               sed -n '456p' "$WORK/cli-design-standard.md"
    echo "--- :461 (R8.2) ---";                               sed -n '461p' "$WORK/cli-design-standard.md"
    echo "--- :472 (R8.5) ---";                               sed -n '472p' "$WORK/cli-design-standard.md"
    L253="$(sed -n '253p' "$WORK/cli-design-standard.md")"
    L381="$(sed -n '381p' "$WORK/cli-design-standard.md")"
    L456="$(sed -n '456p' "$WORK/cli-design-standard.md")"
    L461="$(sed -n '461p' "$WORK/cli-design-standard.md")"
    L472="$(sed -n '472p' "$WORK/cli-design-standard.md")"
    case "$L253" in *'Never prompt; fail if input would be required.'*) ok C8b ":253 carries --no-input's definition";; *) bad C8b ":253 does not carry --no-input's definition";; esac
    case "$L381" in *'fd 2 (stderr) carries everything else: diagnostics, progress, prompts'*) ok C8c "R7.1 at :381 puts prompts on stderr";; *) bad C8c "R7.1 not at :381";; esac
    case "$L456" in *'SHOULD NOT'*'/dev/tty'*) ok C8d "R8.1 at :456 carries the /dev/tty prohibition";; *) bad C8d "R8.1 /dev/tty clause not at :456";; esac
    case "$L456" in *'MUST'*'fail rather than guess'*) ok C8e "R8.1 at :456 requires failure under --no-input with no bypass";; *) bad C8e "R8.1 fail-rather-than-guess clause not at :456";; esac
    case "$L461" in *'exit `2` when required non-auth input or consent is missing'*) ok C8f "R8.2 at :461 assigns exit 2 to missing required non-auth input or consent";; *) bad C8f "R8.2 exit-2 clause not at :461";; esac
    case "$L472" in *'Under `--no-input`, they **MUST** fail rather than prompt.'*) ok C8g "R8.5 at :472 makes an init flow fail under --no-input";; *) bad C8g "R8.5 clause not at :472";; esac
  else
    skip C8 "the pinned blob $STANDARD_BLOB is not present in $STANDARD_REPO"
  fi
else
  skip C8 "the cli-standards checkout is not on this machine at $STANDARD_REPO (SKIP by name, not a failure)"
fi

echo
echo "### Section 9 — advisories: the 404 means 'no advisory page', proven by a positive control"
echo "endpoint: GET https://rustsec.org/packages/<name>.html"
for n in inquire dialoguer crossterm console cliclack demand; do
  code="$($CURL -sS -o "$WORK/snap/rustsec-$n.html" -w '%{http_code}' "https://rustsec.org/packages/$n.html")"
  assert_eq "C9-$n" "$code" "404" "rustsec.org has no advisory page for $n"
done
CTL_CODE="$($CURL -sS -o "$WORK/snap/rustsec-atty.html" -w '%{http_code}' 'https://rustsec.org/packages/atty.html')"
assert_eq C9-ctl "$CTL_CODE" "200" "positive control: rustsec.org DOES serve a page for atty, so 404 is a real negative"
assert_contains C9-ctl-body "$WORK/snap/rustsec-atty.html" "RUSTSEC-2021-0145" "the atty control page names a real advisory"

echo
echo "### Section 10 — registry and repository figures (VOLATILE — see the comparison rule in DECISION.md)"
echo "endpoint: GET https://crates.io/api/v1/crates/<name>   fields: crate.recent_downloads, crate.downloads,"
echo "          newest versions[] entry with yanked=false -> num, created_at"
for n in inquire dialoguer crossterm console cliclack demand; do
  $CURL -sS -A "$UA" -o "$WORK/snap/crate-$n.json" "https://crates.io/api/v1/crates/$n"
  python3 - "$WORK/snap/crate-$n.json" "$n" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); c=d["crate"]
vs=[v for v in d["versions"] if not v["yanked"]]
vs.sort(key=lambda v: v["created_at"], reverse=True)
print(f"  {sys.argv[2]:<10} recent_downloads(90d)={c['recent_downloads']:<12} downloads(all)={c['downloads']:<12} newest_non_yanked={vs[0]['num']} created_at={vs[0]['created_at'][:10]}")
PY
done
NEWEST_INQ="$(python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));vs=[v for v in d["versions"] if not v["yanked"]];vs.sort(key=lambda v: v["created_at"],reverse=True);print(vs[0]["num"])' "$WORK/snap/crate-inquire.json" 2>/dev/null)"
assert_eq C10a "$NEWEST_INQ" "0.9.4" "the recommended version is still inquire's newest non-yanked release"
NEWEST_DIA="$(python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));vs=[v for v in d["versions"] if not v["yanked"]];vs.sort(key=lambda v: v["created_at"],reverse=True);print(vs[0]["num"])' "$WORK/snap/crate-dialoguer.json" 2>/dev/null)"
assert_eq C10b "$NEWEST_DIA" "0.12.0" "the runner-up version is still dialoguer's newest non-yanked release"

echo "endpoint: GET https://api.github.com/repos/<o>/<r>   fields: stargazers_count, archived, pushed_at"
echo "endpoint: GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open   field: total_count"
if command -v gh > /dev/null 2>&1; then
  for r in mikaelmello/inquire console-rs/dialoguer crossterm-rs/crossterm ast-grep/ast-grep; do
    f="$WORK/snap/gh-$(echo "$r" | tr / -).json"
    gh api "repos/$r" > "$f" 2>/dev/null
    python3 - "$f" "$r" <<'PY'
import json,sys
try: d=json.load(open(sys.argv[1]))
except Exception: print(f"  {sys.argv[2]}: unavailable"); raise SystemExit
print(f"  {sys.argv[2]:<26} stars={d['stargazers_count']:<7} archived={d['archived']} pushed_at={d['pushed_at'][:10]}")
PY
    sleep 2
  done
  INQ_ARCH="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["archived"])' "$WORK/snap/gh-mikaelmello-inquire.json" 2>/dev/null)"
  assert_eq C10c "$INQ_ARCH" "False" "mikaelmello/inquire is not archived"
  INQ_LAST="$(gh api 'repos/mikaelmello/inquire/commits?per_page=1' --jq '.[0].commit.committer.date' 2>/dev/null)"
  echo "  mikaelmello/inquire newest commit date (GET repos/<o>/<r>/commits?per_page=1, .[0].commit.committer.date): $INQ_LAST"
  case "$INQ_LAST" in
    2026-02-24*) ok C10d "the newest inquire commit is still 2026-02-24 — the at-risk quiet interval is unchanged";;
    "")          bad C10d "could not read mikaelmello/inquire's newest commit date";;
    *)           bad C10d "mikaelmello/inquire has a NEWER commit ($INQ_LAST) — the at-risk verdict must be re-argued";;
  esac
  sleep 2
  INQ_OI="$(gh api 'search/issues?q=repo:mikaelmello/inquire+is:issue+is:open' --jq '.total_count' 2>/dev/null)"
  sleep 2
  INQ_OP="$(gh api 'search/issues?q=repo:mikaelmello/inquire+is:pr+is:open' --jq '.total_count' 2>/dev/null)"
  echo "  mikaelmello/inquire open issues=$INQ_OI open PRs=$INQ_OP (search/issues total_count, never open_issues_count)"
  if [ -n "$INQ_OP" ] && [ "$INQ_OP" -ge 20 ] 2>/dev/null; then
    ok C10e "inquire's open-PR queue is still large ($INQ_OP >= 20) — at-risk signal (ii) holds"
  else
    bad C10e "inquire's open-PR queue is no longer large (got '$INQ_OP') — re-argue the at-risk verdict"
  fi
  echo "  stars, archived and pushed_at for the repositories not printed above:"
  for r in console-rs/console fadeevab/cliclack jdx/demand; do
    f="$WORK/snap/gh-$(echo "$r" | tr / -).json"
    gh api "repos/$r" > "$f" 2>/dev/null
    python3 - "$f" "$r" <<'PY'
import json,sys
try: d=json.load(open(sys.argv[1]))
except Exception: print(f"  {sys.argv[2]}: unavailable"); raise SystemExit
print(f"  {sys.argv[2]:<26} stars={d['stargazers_count']:<7} archived={d['archived']} pushed_at={d['pushed_at'][:10]}")
PY
    sleep 2
  done
  echo "  open issues and open PRs for every crate whose figures this decision tabulates:"
  for r in console-rs/dialoguer crossterm-rs/crossterm console-rs/console fadeevab/cliclack jdx/demand; do
    oi="$(gh api "search/issues?q=repo:$r+is:issue+is:open" --jq '.total_count' 2>/dev/null)"
    sleep 2
    op="$(gh api "search/issues?q=repo:$r+is:pr+is:open" --jq '.total_count' 2>/dev/null)"
    sleep 2
    printf '  %-26s open_issues=%-6s open_prs=%s\n' "$r" "${oi:-unavailable}" "${op:-unavailable}"
  done
else
  skip C10-gh "gh is not on PATH; the GitHub figures cannot be refreshed"
fi

echo
echo "### Section 11 — the shared adopter that proves R60's parser and this item's crate ship together"
$CURL -sS -o "$WORK/snap/ast-grep-cli-Cargo.toml" \
  'https://raw.githubusercontent.com/ast-grep/ast-grep/main/crates/cli/Cargo.toml'
"$GREP" -nE '^(clap|inquire|clap_complete) ' "$WORK/snap/ast-grep-cli-Cargo.toml" 2>/dev/null || true
assert_contains C11a "$WORK/snap/ast-grep-cli-Cargo.toml" 'inquire = ' "ast-grep's CLI crate declares inquire"
assert_contains C11b "$WORK/snap/ast-grep-cli-Cargo.toml" 'clap = { version = ' "the same manifest declares clap (R60's parser)"

echo
echo "### Section 12 — LIKE-FOR-LIKE dependency cost, resolved rather than asserted"
echo "Three throwaway manifests, each carrying R63's indicatif and R67's signal-hook, differing"
echo "only in the prompt crate. Counts are unique packages in the normal dependency tree for"
echo "x86_64-unknown-linux-gnu, EXCLUDING the spike's own root package."
if command -v cargo > /dev/null 2>&1; then
  mkspike() {
    d="$WORK/spike-$1"; mkdir -p "$d/src"; echo 'fn main() {}' > "$d/src/main.rs"
    { printf '[package]\nname = "spike%s"\nversion = "0.0.0"\nedition = "2024"\n\n[dependencies]\n' "$1"
      [ -n "$2" ] && printf '%s\n' "$2"
      printf 'indicatif = "0.18"\n\n[target.'"'"'cfg(unix)'"'"'.dependencies]\nsignal-hook = { version = "0.4.4", default-features = false }\n'
    } > "$d/Cargo.toml"
  }
  mkspike base ''
  mkspike a 'inquire = { version = "0.9.4", default-features = false, features = ["crossterm", "macros"] }'
  mkspike b 'dialoguer = { version = "0.12.0", default-features = false }'
  COUNT_BASE=0; COUNT_A=0; COUNT_B=0
  for s in base a b; do
    (cd "$WORK/spike-$s" && cargo generate-lockfile > /dev/null 2>&1)
    c="$(cd "$WORK/spike-$s" && cargo tree -e normal --target x86_64-unknown-linux-gnu --prefix none 2>/dev/null \
      | "$GREP" -v '^$' | sed 's/ (\*)$//' | sort -u | wc -l | tr -d ' ')"
    c=$((c-1))
    echo "  spike-$s: $c packages (unique, normal tree, cfg(unix) x86-64, root excluded)"
    case "$s" in base) COUNT_BASE=$c;; a) COUNT_A=$c;; b) COUNT_B=$c;; esac
  done
  echo "  marginal cost of inquire over the shared base : $((COUNT_A-COUNT_BASE)) packages"
  echo "  marginal cost of dialoguer over the same base : $((COUNT_B-COUNT_BASE)) packages"
  assert_eq C12a "$COUNT_BASE" "9"  "base (indicatif + signal-hook 0.4.4) resolves to 9 packages"
  assert_eq C12b "$COUNT_A"    "35" "base + inquire resolves to 35 packages"
  assert_eq C12c "$COUNT_B"    "11" "base + dialoguer resolves to 11 packages"
  echo "  highest declared rust-version anywhere in the inquire tree, and async-runtime scan:"
  (cd "$WORK/spike-a" && cargo metadata --format-version 1 --filter-platform x86_64-unknown-linux-gnu 2>/dev/null) \
    | python3 -c '
import sys,json
m=json.load(sys.stdin)
rv=[(p["name"],p["rust_version"]) for p in m["packages"] if p.get("rust_version")]
rv.sort(key=lambda t: tuple(int(x) for x in t[1].split(".")))
print("    max declared rust_version:", rv[-1][1], "("+rv[-1][0]+")")
rt=[p["name"] for p in m["packages"] if p["name"] in ("tokio","async-std","futures-executor","smol")]
print("    async runtimes in the tree:", rt if rt else "none")
' > "$WORK/meta-a.txt" 2>/dev/null
  cat "$WORK/meta-a.txt"
  assert_contains C12d "$WORK/meta-a.txt" "max declared rust_version: 1.85.0" \
    "the inquire tree's binding MSRV is 1.85.0, eleven minors under the 1.96 policy floor"
  assert_contains C12e "$WORK/meta-a.txt" "async runtimes in the tree: none" \
    "no async runtime is pulled in at any depth"
  echo "  duplicate resolutions in the inquire spike (cargo tree -d):"
  (cd "$WORK/spike-a" && cargo tree -d -e normal --target x86_64-unknown-linux-gnu 2>&1) > "$WORK/dup-a.txt"
  sed 's/^/    /' "$WORK/dup-a.txt"
  assert_contains C12f "$WORK/dup-a.txt" "signal-hook v0.3.18" "crossterm pins signal-hook 0.3.x"
  assert_contains C12g "$WORK/dup-a.txt" "signal-hook v0.4.4" "the template's own R67 signal-hook 0.4.4 stands beside it"
  DUP_A="$("$GREP" -c '^signal-hook v' "$WORK/dup-a.txt" 2>/dev/null || true)"
  assert_eq C12h "${DUP_A:-0}" "2" "signal-hook is the ONLY duplicated package (two majors, counted by $GREP)"
  echo "  duplicate resolutions in the dialoguer spike (cargo tree -d):"
  (cd "$WORK/spike-b" && cargo tree -d -e normal --target x86_64-unknown-linux-gnu 2>&1) > "$WORK/dup-b.txt"
  sed 's/^/    /' "$WORK/dup-b.txt"
  assert_contains C12i "$WORK/dup-b.txt" "nothing to print" "the dialoguer spike resolves with zero duplicates"
else
  skip C12 "cargo is not on PATH; the dependency-cost spike cannot run"
fi

echo
echo "### Section 13 — EXECUTED OBSERVATION: the /dev/tty fallback fires with stdin not a TTY"
echo "A throwaway binary calls crossterm::terminal::enable_raw_mode() and console's own guard"
echo "predicate, under two conditions. Nothing from the template is built; the crate is called."
if command -v cargo > /dev/null 2>&1; then
  d="$WORK/spike-tty"; mkdir -p "$d/src"
  cat > "$d/Cargo.toml" <<'TOML'
[package]
name = "spiketty"
version = "0.0.0"
edition = "2024"

[dependencies]
crossterm = "=0.29.0"
console = "=0.16.6"
TOML
  cat > "$d/src/main.rs" <<'RS'
use std::io::IsTerminal;
fn main() {
    println!("stdin_is_terminal={}", std::io::stdin().is_terminal());
    println!("stderr_is_terminal={}", std::io::stderr().is_terminal());
    // The exact predicate dialoguer 0.12.0 src/prompts/multi_select.rs:204-205 tests.
    println!("dialoguer_guard_term_stderr_is_term={}", console::Term::stderr().is_term());
    match crossterm::terminal::enable_raw_mode() {
        Ok(()) => {
            let _ = crossterm::terminal::disable_raw_mode();
            println!("crossterm_enable_raw_mode=Ok  (a terminal was acquired)");
        }
        Err(e) => println!(
            "crossterm_enable_raw_mode=Err kind={:?} raw_os_error={:?}",
            e.kind(),
            e.raw_os_error()
        ),
    }
}
RS
  if (cd "$d" && cargo build --quiet > /dev/null 2>&1); then
    BIN="$d/target/debug/spiketty"
    echo "  --- case A: NO controlling terminal, stdin redirected from /dev/null ---"
    "$BIN" < /dev/null > "$WORK/tty-a.txt" 2>&1
    sed 's/^/    /' "$WORK/tty-a.txt"
    assert_contains C13a "$WORK/tty-a.txt" "stdin_is_terminal=false" "case A: stdin is not a terminal"
    assert_contains C13b "$WORK/tty-a.txt" "crossterm_enable_raw_mode=Err" \
      "case A: with no controlling terminal the /dev/tty open fails — the negative control"
    cat > "$WORK/ptyspike.py" <<'PY'
import os, pty, sys, select
binary = sys.argv[1]
pid, fd = pty.fork()          # the child gets a new session whose controlling terminal is the pty
if pid == 0:
    devnull = os.open("/dev/null", os.O_RDONLY)
    os.dup2(devnull, 0)       # stdin is NOT a tty; stdout/stderr stay on the pty
    os.execv(binary, [binary])
    os._exit(127)
out = b""
while True:
    try:
        r, _, _ = select.select([fd], [], [], 10)
        if not r:
            break
        chunk = os.read(fd, 4096)
        if not chunk:
            break
        out += chunk
    except OSError:
        break
_, status = os.waitpid(pid, 0)
sys.stdout.write(out.decode(errors="replace").replace("\r\n", "\n"))
print("child_exit_status=%d" % os.waitstatus_to_exitcode(status))
PY
    echo "  --- case B: a controlling PTY IS present, stdin still redirected from /dev/null ---"
    python3 "$WORK/ptyspike.py" "$BIN" > "$WORK/tty-b.txt" 2>&1
    sed 's/^/    /' "$WORK/tty-b.txt"
    assert_contains C13c "$WORK/tty-b.txt" "stdin_is_terminal=false" "case B: stdin is still not a terminal"
    assert_contains C13d "$WORK/tty-b.txt" "crossterm_enable_raw_mode=Ok" \
      "case B: crossterm ACQUIRES the controlling terminal anyway — the surprise-prompt case R8.1 forbids"
    assert_contains C13e "$WORK/tty-b.txt" "dialoguer_guard_term_stderr_is_term=true" \
      "case B: dialoguer's own guard returns true, so no candidate crate blocks this case"
    assert_contains C13f "$WORK/tty-b.txt" "child_exit_status=0" "case B: the observation ran to completion"
  else
    skip C13 "the crossterm/console spike did not build (offline, or no registry access)"
  fi
else
  skip C13 "cargo is not on PATH; the /dev/tty observation cannot run"
fi

echo
echo "### Section 14 — the four fixed - assumes lines are byte-identical to the registry"
PARAM_REG="$REPO_ROOT/docs/port/PARAMETERS.md"
PARAM_IN="$RUN_DIR/inputs/PARAMETERS.md"
gen_params() {
  awk -F'|' '
    /^\| *(msrv-policy|rust-edition|target-os-matrix|license) *\|/ {
      name=$2; val=$5
      gsub(/^ +| +$/, "", name); gsub(/^ +| +$/, "", val)
      order[name]=1; value[name]=val
    }
    END {
      split("msrv-policy rust-edition target-os-matrix license", k, " ")
      for (i=1; i<=4; i++) if (k[i] in value) printf "- assumes %s = %s\n", k[i], value[k[i]]
    }' "$1"
}
if [ -f "$PARAM_REG" ]; then
  gen_params "$PARAM_REG" > "$WORK/params-registry.txt"
  echo "generated from $PARAM_REG:"; sed 's/^/  /' "$WORK/params-registry.txt"
  GENLINES="$(wc -l < "$WORK/params-registry.txt" | tr -d ' ')"
  assert_eq C14a "$GENLINES" "4" "four fixed parameter rows were extracted from the registry"
  if [ -f "$PARAM_IN" ]; then
    gen_params "$PARAM_IN" > "$WORK/params-inputs.txt"
    if diff -u "$WORK/params-registry.txt" "$WORK/params-inputs.txt" > "$WORK/params-inputs.diff" 2>&1; then
      ok C14b "the run's inputs/PARAMETERS.md fixed rows are byte-identical to the live registry"
    else
      bad C14b "inputs/PARAMETERS.md has drifted from the live registry"; sed 's/^/  /' "$WORK/params-inputs.diff"
    fi
  else
    skip C14b "the run has no inputs/PARAMETERS.md"
  fi
  if [ -f "$DECISION" ]; then
    "$GREP" '^- assumes ' "$DECISION" > "$WORK/params-decision.txt" 2>/dev/null || true
    echo "found in DECISION.md:"; sed 's/^/  /' "$WORK/params-decision.txt"
    if diff -u "$WORK/params-registry.txt" "$WORK/params-decision.txt" > "$WORK/params.diff" 2>&1; then
      ok C14c "DECISION.md's - assumes block is byte-identical to the registry, in registry order"
    else
      bad C14c "DECISION.md's - assumes block differs from the registry"; sed 's/^/  /' "$WORK/params.diff"
    fi
    OWNS="$("$GREP" -c '^- owns ' "$DECISION" 2>/dev/null || true)"
    assert_eq C14d "${OWNS:-0}" "0" "DECISION.md declares no owned parameter (the prompt's - owns: line is empty)"
    CONFLICTS="$("$GREP" -c '^CONFLICT:' "$DECISION" 2>/dev/null || true)"
    assert_eq C14e "${CONFLICTS:-0}" "0" "DECISION.md raises no CONFLICT: line"
  else
    skip C14c "DECISION.md is not present beside this script"
  fi
  echo "the prompt's Couplings block, which is what makes C14d and C14e the right expectations:"
  "$GREP" -n -A3 '^- owns:' "$RUN_DIR/inputs/prompt.md" 2>/dev/null | head -5
  assert_contains C14f "$RUN_DIR/inputs/prompt.md" '- owns:' "the prompt carries an - owns: line"
else
  skip C14 "docs/port/PARAMETERS.md not reachable from this script's location"
fi

echo
echo "### Section 15 — the OVERRIDE number does not collide"
OVDIRS=""
[ -d "$REPO_ROOT/docs/port" ] && OVDIRS="$REPO_ROOT/docs/port"
OVHITS="$WORK/ov-hits.txt"
: > "$OVHITS"
if [ -n "$OVDIRS" ]; then
  "$GREP" -rlF 'OVERRIDE (OV-02)' "$REPO_ROOT/docs/port" >> "$OVHITS" 2>/dev/null
fi
for f in "$REPO_ROOT"/research/topics/*/DECISION.md; do
  case "$f" in *"/61-"*) continue;; esac
  [ -f "$f" ] || continue
  "$GREP" -lF 'OVERRIDE (OV-02)' "$f" >> "$OVHITS" 2>/dev/null
done
OVCOUNT="$(wc -l < "$OVHITS" | tr -d ' ')"
echo "files declaring 'OVERRIDE (OV-02)' outside this item (docs/port/ and research/topics/*/DECISION.md, counted by $GREP): $OVCOUNT"
assert_eq C15a "${OVCOUNT:-0}" "0" "OV-02 is unused by any other published decision or port document"
assert_contains C15b "$REPO_ROOT/docs/port/OWNER-REVIEW.md" 'Override OV-01 is REFUSED.' \
  "OV-01 is taken: the owner refused it on 2026-09-14 (R60's CLI-standard waiver)"
assert_contains C15c "$REPO_ROOT/research/topics/60-cli-parsing-framework/DECISION.md" \
  'RETIRED OVERRIDE (OV-01)' "R60 retains OV-01's record rather than deleting it"

echo
echo "### Section 16 — F360's status, and R67's rows, read from the repository"
F360_BR="$("$GREP" -c '^| F360 ' "$REPO_ROOT/docs/port/BASELINE-REVIEW.md" 2>/dev/null || true)"
echo "rows whose first column is F360 in docs/port/BASELINE-REVIEW.md (counted by $GREP): ${F360_BR:-0}"
assert_eq C16a "${F360_BR:-0}" "0" "F360 is NOT an adjudicated baseline row — a BASELINE-REVIEW: line against it challenges no inherited baseline"
assert_contains C16b "$REPO_ROOT/docs/port/COMMONALITY.md" \
  '| F360 | `--no-input` behavior when a prompt would have been shown | cli-framework-ux | different | DIVERGENT | R61 |' \
  "F360 is DIVERGENT and owned by R61, so this item answers it directly"
assert_contains C16c "$REPO_ROOT/docs/port/COMMONALITY.md" \
  '| F277 | `--dry-run` mutation-safety flag | cli-framework-ux | py-only | ADOPT | — |' \
  "F277 is an ADOPT baseline this decision must preserve"
assert_contains C16d "$REPO_ROOT/docs/port/COMMONALITY.md" \
  '| F278 | `-y`/`--yes` mutation-safety flag | cli-framework-ux | py-only | ADOPT | — |' \
  "F278 is an ADOPT baseline this decision must preserve"
R67D="$REPO_ROOT/research/topics/67-error-and-exit-code-contract/DECISION.md"
assert_contains C16e "$R67D" \
  'required non-auth input or consent missing because prompting is disabled or unavailable' \
  "R67 RSLB205 covers exactly this item's three refusal triggers"
assert_contains C16f "$R67D" 'prompt interrupted by Ctrl-C' "R67 RSLB903 is the Ctrl-C-during-a-prompt row"
assert_contains C16h "$R67D" 'prompt-local Ctrl-C handler may be installed' \
  "R67 forbids a prompt-local Ctrl-C handler — the rule that rules out demand"
assert_contains C16i "$R67D" '`5` conflict' "R67 assigns exit 5 to conflict/precondition failed, which is why py's 5 cannot be reused"

echo
echo "### Section 17 — the raw reports this decision synthesizes"
for f in "$RUN_DIR/raw/codex.md" "$RUN_DIR/raw/opus.md"; do
  if [ -f "$f" ]; then
    echo "  $(basename "$f") sha256 $($SHASUM -a 256 "$f" | cut -d' ' -f1)"
  else
    echo "  $(basename "$f") MISSING"
  fi
done
CODEX_SHA="$($SHASUM -a 256 "$RUN_DIR/raw/codex.md" 2>/dev/null | cut -d' ' -f1)"
OPUS_SHA="$($SHASUM -a 256 "$RUN_DIR/raw/opus.md" 2>/dev/null | cut -d' ' -f1)"
assert_eq C17a "$CODEX_SHA" "a22fcc08990a3db262b3c950447646fac3d0293d284e55b484e2233320444f2e" "raw/codex.md is the shape-checked report"
assert_eq C17b "$OPUS_SHA" "162d21eddec4acbf60828bc9e92adc353c3bbc983c2e079b7ee35a199b323fa7" "raw/opus.md is the shape-checked report"
assert_contains C17c "$RUN_DIR/raw/codex.md" 'BASELINE-REVIEW: F360' "the Codex raw emits the F360 baseline-review line this decision carries"
assert_contains C17d "$RUN_DIR/raw/codex.md" 'dialoguer = { version = "0.12.0", default-features = false }' "the Codex raw recommends dialoguer"
assert_contains C17e "$RUN_DIR/raw/opus.md" 'inquire = { version = "0.9.4", default-features = false, features = ["crossterm", "macros"] }' "the Opus raw recommends inquire"
assert_contains C17f "$RUN_DIR/raw/opus.md" 'OVERRIDE (OV-01)' "the Opus raw numbered its override OV-01, which this decision renumbers to OV-02"

echo
echo "================================================================"
printf 'TOTAL  pass=%d  fail=%d  skip=%d\n' "$PASS" "$FAIL" "$SKIP"
echo "================================================================"
exit "$FAIL"
