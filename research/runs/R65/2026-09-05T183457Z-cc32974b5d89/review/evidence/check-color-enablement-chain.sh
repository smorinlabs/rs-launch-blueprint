#!/usr/bin/env bash
# R65 color-enablement-chain — verification script.
# Verifies claims made in raw/codex-*.md and raw/opus-*.md. Implements nothing:
# no crate is scaffolded, no resolver is written, no template file is created.
#
# Every check asserts on expected CONTENT and prints PASS/FAIL. The script never
# reports success from an exit code alone.
set -o pipefail

UA='rs-launch-blueprint-R65-check'
PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TS_PIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
PY_REPO="$HOME/c/py-launch-blueprint"
TS_REPO="$HOME/c/ts-launch-blueprint"
RUN_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
EVID="$RUN_DIR/review/evidence"
REPO_ROOT="$(cd "$RUN_DIR/../../../.." && pwd)"
PASS=0
FAIL=0

ok()   { PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }
# assert <label> <expected-substring> <actual-text>
assert() {
  local label="$1" want="$2" got="$3"
  case "$got" in
    *"$want"*) ok "$label  [matched: $want]" ;;
    *)         bad "$label  [expected: $want] [got: $(printf '%s' "$got" | head -c 200)]" ;;
  esac
}
# assert_n <label> <expected-count> <actual-count>
assert_n() {
  local label="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then ok "$label  [count=$got]"; else bad "$label  [expected count $want, got $got]"; fi
}
# raw <owner/repo> <tag> <path>  -- immutable read at a git tag; empty on HTTP error
raw() {
  curl -sS -f -H "User-Agent: $UA" "https://raw.githubusercontent.com/$1/$2/$3" 2>/dev/null
}
tags() {
  git ls-remote --tags "https://github.com/$1" 2>/dev/null | awk '{print $2}' | sed 's#refs/tags/##' | grep -v '\^{}'
}

echo "=============================================================="
echo "R65 color-enablement-chain — claim verification"
echo "=============================================================="
echo

echo "## 0. Toolchain"
rustc --version
cargo --version
printf 'os: %s %s\n' "$(uname -s)" "$(uname -m)"
sw_vers 2>/dev/null | tr '\n' ' '; echo
echo

# --------------------------------------------------------------------------
echo "## 1. Pinned source repositories (git show <pin>:<path>, never a working tree)"
PY_CTX=$(git -C "$PY_REPO" show "$PY_PIN:src/py_launch_blueprint/cli/context.py" 2>/dev/null)
PY_OUT=$(git -C "$PY_REPO" show "$PY_PIN:src/py_launch_blueprint/cli/output.py" 2>/dev/null)
TS_COL=$(git -C "$TS_REPO" show "$TS_PIN:src/lib/colors.ts" 2>/dev/null)
TS_RTR=$(git -C "$TS_REPO" show "$TS_PIN:src/router.ts" 2>/dev/null)
assert "py context.py has _resolve_color signature (prompt cites :188)" \
  'def _resolve_color(no_color_flag: bool, config_color: str) -> str:' "$PY_CTX"
# py chain: flag > NO_COLOR > config. NO_COLOR must return BEFORE config_color is read.
PY_ORDER=$(printf '%s\n' "$PY_CTX" | grep -n 'NO_COLOR\|return config_color' | head -2 | tr '\n' ' ')
assert "py returns on NO_COLOR before consulting config (config CANNOT override NO_COLOR)" \
  'NO_COLOR' "$PY_ORDER"
PY_NOCOLOR_LN=$(printf '%s\n' "$PY_CTX" | grep -n 'os.environ.get("NO_COLOR")' | cut -d: -f1 | head -1)
PY_CONFIG_LN=$(printf '%s\n' "$PY_CTX" | grep -n 'return config_color' | cut -d: -f1 | head -1)
if [ -n "$PY_NOCOLOR_LN" ] && [ -n "$PY_CONFIG_LN" ] && [ "$PY_NOCOLOR_LN" -lt "$PY_CONFIG_LN" ]; then
  ok "py NO_COLOR line $PY_NOCOLOR_LN precedes config line $PY_CONFIG_LN"
else
  bad "py NO_COLOR/config ordering not established (NO_COLOR=$PY_NOCOLOR_LN config=$PY_CONFIG_LN)"
fi
assert "py builds BOTH consoles from the SAME nc/force pair (F289 one-gate shape)" \
  'self.out = Console(highlight=False, no_color=nc, force_terminal=force)' "$PY_OUT"
assert "py stderr console reuses the same nc/force" 'stderr=True, highlight=False, no_color=nc, force_terminal=force' "$PY_OUT"
assert "py styles its stdout result table (F289: stdout CAN carry colour)" 'header_style="bold cyan"' "$PY_OUT"
assert "py checks the stream's own isatty() apart from Rich is_terminal (F290)" \
  'def _isatty(console: Console) -> bool:' "$PY_OUT"
assert "ts colorEnabled gate exists (prompt cites :26)" 'export function colorEnabled(gate: ColorGate): boolean {' "$TS_COL"
assert "ts reads FORCE_COLOR (F288)" "const forceColor = gate.env['FORCE_COLOR'];" "$TS_COL"
assert "ts treats FORCE_COLOR='0' as NOT forcing" "forceColor !== '0'" "$TS_COL"
assert "ts falls through to a single injected isTTY" 'return gate.isTTY;' "$TS_COL"
assert "ts computes that gate from stderr TTY-ness only (F289 stderr-only shape)" 'isTTY: deps.stderrIsTTY,' "$TS_RTR"
assert "ts injects both stream flags on its deps object (F290 seam)" 'stdoutIsTTY: process.stdout.isTTY ?? false,' "$TS_RTR"
echo

# --------------------------------------------------------------------------
echo "## 2. Re-read at pinned tags every source the Opus raw disclosed as a default-branch read"
echo "     (raw disclosure (b)/(c): supports-color, console, owo-colors, clap, cargo, ripgrep, color-eyre)"

# 2a. The raw claims zkat/supports-color publishes no release tags. Test it.
SC_TAGS=$(tags zkat/supports-color)
SC_TAG_COUNT=$(printf '%s\n' "$SC_TAGS" | grep -c . )
SC_HAS_302=$(printf '%s\n' "$SC_TAGS" | grep -cx 'v3.0.2')
if [ "$SC_TAG_COUNT" -gt 0 ] && [ "$SC_HAS_302" -eq 1 ]; then
  ok "REFUTES raw disclosure (b): zkat/supports-color publishes $SC_TAG_COUNT tags and v3.0.2 exists; the inferred-identity caveat is unnecessary"
else
  bad "supports-color tag state unexpected (tags=$SC_TAG_COUNT v3.0.2=$SC_HAS_302)"
fi
for t in clap-rs/clap:v4.6.6 rust-lang/cargo:0.99.0 BurntSushi/ripgrep:15.2.0 \
         console-rs/console:0.16.6 owo-colors/owo-colors:v4.4.0 eyre-rs/eyre:color-eyre-v0.6.5 \
         BurntSushi/termcolor:1.4.1 polyfill-rs/is_terminal_polyfill:v1.70.2 \
         rust-cli/anstyle:anstream-v1.0.0 rust-cli/anstyle:anstyle-query-v1.1.5 \
         rust-cli/anstyle:colorchoice-v1.0.5 rust-cli/anstyle:v1.0.14 \
         colored-rs/colored:v3.1.1; do
  r=${t%%:*}; g=${t##*:}
  n=$(tags "$r" | grep -cx "$g")
  assert_n "tag exists: $r@$g" 1 "$n"
done
echo

# --------------------------------------------------------------------------
echo "## 3. CORE CLAIM — does any candidate ship the flag + config + environment tiers?"
echo "     Read at pinned tags. 'override input' = an explicit choice the application can hand in."

AQ=$(raw rust-cli/anstyle anstyle-query-v1.1.5 crates/anstyle-query/src/lib.rs)
assert_n "anstyle-query 1.1.5 lib.rs: occurrences of FORCE_COLOR" 0 "$(printf '%s\n' "$AQ" | grep -c 'FORCE_COLOR' | tr -d ' ')"
assert_n "anstyle-query 1.1.5 lib.rs: occurrences of CLICOLOR_FORCE" 3 "$(printf '%s\n' "$AQ" | grep -c 'CLICOLOR_FORCE' | tr -d ' ')"
assert "anstyle-query exposes no_color() probe" 'pub fn no_color() -> bool {' "$AQ"
assert "anstyle-query exposes clicolor_force() probe" 'pub fn clicolor_force() -> bool {' "$AQ"
assert "anstyle-query applies the no-color.org non-empty rule to NO_COLOR" \
  'non_empty(std::env::var_os("NO_COLOR").as_deref())' "$AQ"
assert_n "anstyle-query 1.1.5 lib.rs: occurrences of std::env::args (argv parsing)" 0 "$(printf '%s\n' "$AQ" | grep -c 'env::args' | tr -d ' ')"
echo "     anstyle-query probe list:"
printf '%s\n' "$AQ" | grep -E '^pub fn ' | sed 's/^/       /'
echo

AS_AUTO=$(raw rust-cli/anstyle anstream-v1.0.0 crates/anstream/src/auto.rs)
assert "anstream 1.0.0 exposes AutoStream::new(raw, choice)" 'pub fn new(raw: S, choice: ColorChoice) -> Self {' "$AS_AUTO"
assert "anstream 1.0.0 takes its override tier from the colorchoice process global" 'let choice = ColorChoice::global();' "$AS_AUTO"
assert_n "anstream 1.0.0 auto.rs: occurrences of FORCE_COLOR" 0 "$(printf '%s\n' "$AS_AUTO" | grep -c 'FORCE_COLOR' | tr -d ' ')"
echo "     anstream fn choice() precedence, verbatim at tag anstream-v1.0.0:"
printf '%s\n' "$AS_AUTO" | sed -n '198,222p' | sed 's/^/       /'
# order assertion: no_color() must be tested before clicolor_force()
NC_LN=$(printf '%s\n' "$AS_AUTO" | grep -n 'anstyle_query::no_color()' | cut -d: -f1 | tail -1)
CF_LN=$(printf '%s\n' "$AS_AUTO" | grep -n 'anstyle_query::clicolor_force()' | cut -d: -f1 | tail -1)
TTY_LN=$(printf '%s\n' "$AS_AUTO" | grep -n 'raw.is_terminal()' | cut -d: -f1 | tail -1)
if [ -n "$NC_LN" ] && [ -n "$CF_LN" ] && [ -n "$TTY_LN" ] && [ "$NC_LN" -lt "$CF_LN" ] && [ "$CF_LN" -lt "$TTY_LN" ]; then
  ok "anstream order NO_COLOR($NC_LN) < CLICOLOR_FORCE($CF_LN) < per-stream is_terminal($TTY_LN)"
else
  bad "anstream precedence order not established (no_color=$NC_LN clicolor_force=$CF_LN is_terminal=$TTY_LN)"
fi

CC=$(raw rust-cli/anstyle colorchoice-v1.0.5 crates/colorchoice/src/lib.rs)
assert "colorchoice 1.0.5 carries the override in ONE process-wide static" 'static USER: AtomicChoice = AtomicChoice::new();' "$CC"
assert "colorchoice 1.0.5 that static is an AtomicUsize underneath" 'pub(crate) struct AtomicChoice(AtomicUsize);' "$CC"
CC_LN=$(printf '%s\n' "$CC" | grep -n 'static USER: AtomicChoice' | cut -d: -f1 | head -1)
printf 'INFO  colorchoice global is at lib.rs:%s at tag colorchoice-v1.0.5 (the Opus raw cited :31-38,41 on the default branch)\n' "$CC_LN"
assert_n "colorchoice 1.0.5: occurrences of env:: (it reads no environment)" 0 "$(printf '%s\n' "$CC" | grep -c 'env::' | tr -d ' ')"

SC=$(raw zkat/supports-color v3.0.2 src/lib.rs)
assert "supports-color 3.0.2 DOES read FORCE_COLOR" 'fn env_force_color() -> usize {' "$SC"
assert "supports-color 3.0.2 evaluates force BEFORE no-color (inverts no-color.org / CPython / anstream / ts)" \
  'let force_color = env_force_color();' "$SC"
SC_F=$(printf '%s\n' "$SC" | grep -n 'let force_color = env_force_color();' | cut -d: -f1 | head -1)
SC_N=$(printf '%s\n' "$SC" | grep -n 'env_no_color()' | cut -d: -f1 | tail -1)
if [ -n "$SC_F" ] && [ -n "$SC_N" ] && [ "$SC_F" -lt "$SC_N" ]; then
  ok "supports-color 3.0.2 inversion confirmed at the TAG (force line $SC_F precedes no_color line $SC_N)"
else
  bad "supports-color ordering not established (force=$SC_F no_color=$SC_N)"
fi
assert_n "supports-color 3.0.2: occurrences of env::args (argv parsing)" 0 "$(printf '%s\n' "$SC" | grep -c 'env::args' | tr -d ' ')"

TC=$(raw BurntSushi/termcolor 1.4.1 src/lib.rs)
assert "termcolor 1.4.1 takes an override input (ColorChoice constructor argument)" 'pub enum ColorChoice {' "$TC"
assert "termcolor 1.4.1 reads NO_COLOR" 'env::var_os("NO_COLOR")' "$TC"
assert_n "termcolor 1.4.1: occurrences of FORCE_COLOR" 0 "$(printf '%s\n' "$TC" | grep -c 'FORCE_COLOR' | tr -d ' ')"
assert_n "termcolor 1.4.1: occurrences of CLICOLOR" 0 "$(printf '%s\n' "$TC" | grep -c 'CLICOLOR' | tr -d ' ')"

CO_U=$(raw console-rs/console 0.16.6 src/utils.rs)
CO_X=$(raw console-rs/console 0.16.6 src/unix_term.rs)
assert "console 0.16.6 exposes only a global override setter" 'pub fn set_colors_enabled(val: bool) {' "$CO_U"
assert "console 0.16.6 lets CLICOLOR_FORCE override NO_COLOR (opposite of anstream)" \
  '|| &env::var("CLICOLOR_FORCE").unwrap_or_else(|_| "0".into()) != "0"' "$CO_U"
assert "console 0.16.6 treats NO_COLOR= (set, empty) as disabling, against no-color.org" \
  'if env::var("NO_COLOR").is_ok() {' "$CO_X"
assert "console 0.16.6 reaches the terminal through unsafe libc::isatty, not std" \
  'unsafe { libc::isatty(out.as_raw_fd()) != 0 }' "$CO_X"
assert_n "console 0.16.6 utils.rs: occurrences of FORCE_COLOR (bare)" 0 \
  "$(printf '%s\n' "$CO_U" | grep -oE '(^|[^_])FORCE_COLOR' | grep -c . | tr -d ' ')"

OW_O=$(raw owo-colors/owo-colors v4.4.0 src/overrides.rs)
OW_C=$(raw owo-colors/owo-colors v4.4.0 Cargo.toml)
assert "owo-colors 4.4.0 keeps its override in a process global" 'pub(crate) struct Override(AtomicU8);' "$OW_O"
assert "owo-colors 4.4.0 global setter" 'pub fn set_override(enabled: bool) {' "$OW_O"
assert "owo-colors 4.4.0 delegates env detection to supports-color (inheriting its inverted order)" \
  'supports-color' "$OW_C"
echo "     No candidate parses argv (std::env::args occurrences, each at its tag):"
for pair in "anstream:$AS_AUTO" "colorchoice:$CC" "termcolor:$TC" "console-utils:$CO_U" "owo-colors-overrides:$OW_O"; do
  assert_n "  ${pair%%:*}: occurrences of env::args" 0 "$(printf '%s\n' "${pair#*:}" | grep -c 'env::args' | tr -d ' ')"
done
echo
echo "     SUMMARY of the tier audit (each read at the tag above):"
echo "       crate            argv/config tier   override input          FORCE_COLOR   NO_COLOR above force"
echo "       anstyle-query    no                 no (probes only)        no            n/a (no policy)"
echo "       anstream         no                 yes (global only)       no            yes"
echo "       colorchoice      no                 yes (global only)       no            n/a"
echo "       supports-color   no                 no                      yes           NO  (inverted)"
echo "       termcolor        no                 yes (ctor argument)     no            n/a (no force tier)"
echo "       console          no                 yes (global setter)     no            NO  (inverted)"
echo "       owo-colors       no                 yes (global only)       via supports-color  NO (inherited)"
echo "     => No candidate composes flag+config+env. No crate parses this application's argv or"
echo "        config file at all; that tier is application-owned by construction."
echo

# --------------------------------------------------------------------------
echo "## 4. The on-the-record statement that the FORCE_COLOR omission is deliberate, and"
echo "     exactly what the saved JSON establishes about who made it"
ISSUE="$EVID/anstyle-issue-192.json"
COMMENTS="$EVID/anstyle-issue-192-comments.json"
curl -sS -f -H "User-Agent: $UA" https://api.github.com/repos/rust-cli/anstyle/issues/192 -o "$ISSUE" \
  || bad "could not fetch rust-cli/anstyle#192"
curl -sS -f -H "User-Agent: $UA" "https://api.github.com/repos/rust-cli/anstyle/issues/192/comments?per_page=100" -o "$COMMENTS" \
  || bad "could not fetch rust-cli/anstyle#192 comments"
assert "issue #192 title" 'Supporting FORCE_COLOR as an alias to CLICOLOR_FORCE' "$(jq -r '.title' "$ISSUE")"
assert "issue #192 opened" '2024-06-02' "$(jq -r '.created_at' "$ISSUE")"
QUOTE="I didn't feel like arbitrating between parties arguing over 3 different implementations."
CMT=$(jq -r --arg q "$QUOTE" '.[] | select(.body | contains($q))' "$COMMENTS")
assert "the quoted sentence is present in a comment body" 'epage' "$(printf '%s' "$CMT" | jq -r '.user.login')"
assert "its author's association with the repo" 'COLLABORATOR' "$(printf '%s' "$CMT" | jq -r '.author_association')"
assert "comment timestamp cited by the raw" '2024-06-04T02:23:48Z' "$(printf '%s' "$CMT" | jq -r '.created_at')"
printf 'INFO  issue #192 state (VOLATILE — see note): %s\n' "$(jq -r '.state' "$ISSUE")"
# The role the decision attributes to that commenter, established from a first-party
# registry endpoint rather than inferred from author_association. Ownership is VOLATILE.
OWNERS="$EVID/crates-io-anstyle-query-owners.json"
curl -sS -f -H "User-Agent: $UA" https://crates.io/api/v1/crates/anstyle-query/owners -o "$OWNERS" \
  || bad "could not fetch crates.io owners of anstyle-query"
assert "the commenter is a crates.io OWNER of anstyle-query itself (VOLATILE: ownership can change)" \
  'epage' "$(jq -r '[.users[] | select(.kind=="user") | .login] | join(",")' "$OWNERS" 2>/dev/null)"
printf 'INFO  crates.io owners of anstyle-query: %s\n' \
  "$(jq -r '[.users[] | "\(.login)(\(.kind))"] | join(" ")' "$OWNERS" 2>/dev/null)"
# The same endpoint for clap does NOT name that commenter; the decision therefore claims
# no clap or cargo maintainer role for him.
CL_OWNERS="$EVID/crates-io-clap-owners.json"
sleep 3
curl -sS -f -H "User-Agent: $UA" https://crates.io/api/v1/crates/clap/owners -o "$CL_OWNERS" \
  || bad "could not fetch crates.io owners of clap"
assert_n "crates.io individual owners of clap that are 'epage' (0 — no clap-maintainer claim is made)" 0 \
  "$(jq -r '[.users[] | select(.kind=="user") | .login] | map(select(.=="epage")) | length' "$CL_OWNERS" 2>/dev/null)"
printf 'INFO  crates.io owners of clap: %s\n' \
  "$(jq -r '[.users[] | "\(.login)(\(.kind))"] | join(" ")' "$CL_OWNERS" 2>/dev/null)"
echo

# --------------------------------------------------------------------------
echo "## 5. The standards the chain is built on — READ FROM THE COMMITTED SNAPSHOTS, not live"
echo "     These three pages are unversioned and editable in place, so the decision's"
echo "     quotations are asserted against the snapshot files committed in this evidence"
echo "     directory. This section performs NO network fetch and never overwrites a snapshot."
echo "     Live re-verification is a separate, opt-in step: R65_REFRESH_SNAPSHOTS=1 writes"
echo "     <snapshot>-live.txt beside each snapshot, diffs it, and prints an INFO line."
SNAP_NOC="$EVID/snapshot-no-color.org.txt"
SNAP_FOC="$EVID/snapshot-force-color.org.txt"
SNAP_BIX="$EVID/snapshot-bixense-clicolors.txt"
for s in "$SNAP_NOC" "$SNAP_FOC" "$SNAP_BIX"; do
  if [ -s "$s" ]; then
    ok "snapshot read: $(basename "$s")  sha256=$(shasum -a 256 "$s" | cut -d' ' -f1)"
  else
    bad "snapshot missing or empty: $s"
  fi
done
NOC=$(cat "$SNAP_NOC" 2>/dev/null)
FOC=$(cat "$SNAP_FOC" 2>/dev/null)
BIX=$(cat "$SNAP_BIX" 2>/dev/null)
assert "no-color.org: NO_COLOR counts when present and non-empty" \
  'when present and not an empty string (regardless of its value), prevents the addition of ANSI color' "$NOC"
assert "no-color.org FAQ: config files and CLI arguments override NO_COLOR" \
  'User-level configuration files and per-instance command-line arguments should override the NO_COLOR environment variable' "$NOC"
assert "force-color.org: FORCE_COLOR counts on mere presence (regardless of value)" \
  'present and not an empty string (regardless of its value), it should force the addition of ANSI color' "$FOC"
assert "bixense CLICOLOR standard now marks itself deprecated" 'This standard is deprecated' "$BIX"
assert "bixense tells implementers to treat FORCE_COLOR as an alias for CLICOLOR_FORCE" \
  'treat FORCE_COLOR as an alias for CLICOLOR_FORCE' "$BIX"
# Opt-in live re-verification. Adds no assertion, so the pass/fail inventory of this
# script is the same with and without it; it only reports drift for the re-verify trigger.
refresh_one() {  # refresh_one <url> <snapshot-path>
  local url="$1" snap="$2" live="${2%.txt}-live.txt"
  if curl -sS -f "$url" | sed -e 's/<[^>]*>//g' | tr '\n' ' ' | tr -s ' ' > "$live"; then
    if diff -q "$snap" "$live" >/dev/null 2>&1; then
      printf 'INFO  live %s still matches %s\n' "$url" "$(basename "$snap")"
    else
      printf 'INFO  live %s DIFFERS from %s — re-verify the quotations (see %s)\n' \
        "$url" "$(basename "$snap")" "$(basename "$live")"
    fi
  else
    printf 'INFO  live %s could not be fetched; the snapshot above is unaffected\n' "$url"
  fi
}
if [ "${R65_REFRESH_SNAPSHOTS:-0}" = "1" ]; then
  echo "     R65_REFRESH_SNAPSHOTS=1 — live re-verification (not the source of any claim):"
  refresh_one https://no-color.org/ "$SNAP_NOC"
  refresh_one https://force-color.org/ "$SNAP_FOC"
  refresh_one https://bixense.com/clicolors/ "$SNAP_BIX"
else
  echo "     live re-verification not requested (set R65_REFRESH_SNAPSHOTS=1 to run it)"
fi
echo

# --------------------------------------------------------------------------
echo "## 6. Fitness gates — registry metadata (immutable per published version) and advisories"
# Each crate's /versions is fetched ONCE per run (crates.io rate-limits per client),
# retried on failure, snapshotted into evidence/, and every gate below is derived from
# that one response. An unavailable endpoint FAILS loudly; it is never treated as a pass.
fetch_versions() {  # fetch_versions <crate> -> writes evidence/crates-io-<crate>-versions.json
  local c="$1" out="$EVID/crates-io-$c-versions.json" i=0 wait=5
  while [ "$i" -lt 7 ]; do
    if curl -sS -f -H "User-Agent: $UA" "https://crates.io/api/v1/crates/$c/versions" -o "$out" 2>/dev/null \
       && [ -s "$out" ] && jq -e '.versions|length>0' "$out" >/dev/null 2>&1; then
      return 0
    fi
    i=$((i+1)); sleep "$wait"; [ "$wait" -lt 30 ] && wait=$((wait*2))
  done
  return 1
}
VFIELD() { jq -r "[.versions[] | select(.yanked==false)][0] | .$2" "$EVID/crates-io-$1-versions.json" 2>/dev/null; }
for c in anstream anstyle anstyle-query colorchoice colored; do
  if fetch_versions "$c"; then
    printf '      %-15s num=%s created=%s license=%s rust_version=%s edition=%s\n' "$c" \
      "$(VFIELD "$c" num)" "$(VFIELD "$c" created_at)" "$(VFIELD "$c" license)" \
      "$(VFIELD "$c" rust_version)" "$(VFIELD "$c" edition)"
  else
    bad "could not retrieve https://crates.io/api/v1/crates/$c/versions after 5 attempts"
  fi
  sleep 3
done
# Gate 1 (licence compatibility) is INAPPLICABLE per the owner ruling of 2026-09-12 (Q7.B):
# licence compatibility is not evaluated for any dependency or tool. The licence fields below
# are still fetched and asserted, because DECISION.md reports them as recorded facts -- but
# NO candidate is excluded by them, and no label here claims a gate verdict.
assert "licence field recorded (not a gate; ruling 2026-09-12 Q7.B) anstream"      'MIT OR Apache-2.0' "$(VFIELD anstream license)"
assert "licence field recorded (not a gate; ruling 2026-09-12 Q7.B) anstyle"       'MIT OR Apache-2.0' "$(VFIELD anstyle license)"
assert "licence field recorded (not a gate; ruling 2026-09-12 Q7.B) anstyle-query" 'MIT OR Apache-2.0' "$(VFIELD anstyle-query license)"
assert "licence field recorded (not a gate; ruling 2026-09-12 Q7.B) colorchoice"   'MIT OR Apache-2.0' "$(VFIELD colorchoice license)"
assert "licence field recorded (not a gate; colored is NOT excluded by it -- see section 11) colored" 'MPL-2.0' "$(VFIELD colored license)"
assert "gate 2 colored rust-version (colored fails no gate this decision evaluates)" '1.80' "$(VFIELD colored rust_version)"
assert_n "gate 3 colored has no RustSec page (404 = no advisories)" 404 \
  "$(curl -sS -o /dev/null -w '%{http_code}' https://rustsec.org/packages/colored.html)"
assert "gate 2 anstream rust-version"      '1.66.0' "$(VFIELD anstream rust_version)"
assert "gate 2 anstyle rust-version"       '1.66.0' "$(VFIELD anstyle rust_version)"
assert "gate 2 anstyle-query rust-version" '1.66.0' "$(VFIELD anstyle-query rust_version)"
assert "gate 2 colorchoice rust-version"   '1.66.0' "$(VFIELD colorchoice rust_version)"
assert "recommended anstream version is the newest non-yanked (VOLATILE)" '1.0.0' "$(VFIELD anstream num)"
assert "recommended anstyle version is the newest non-yanked (VOLATILE)"  '1.0.14' "$(VFIELD anstyle num)"
assert "recommended anstyle-query version is the newest non-yanked (VOLATILE)" '1.1.5' "$(VFIELD anstyle-query num)"
assert "recommended colorchoice version is the newest non-yanked (VOLATILE)"   '1.0.5' "$(VFIELD colorchoice num)"
AS_CT=$(raw rust-cli/anstyle anstream-v1.0.0 crates/anstream/Cargo.toml)
WS_CT=$(raw rust-cli/anstyle anstream-v1.0.0 Cargo.toml)
assert "anstream default features" 'default = ["auto", "wincon"]' "$AS_CT"
assert "anstream ships a dev-only test feature" 'Enable in `dev-dependencies` to make sure output is captured for tests' "$AS_CT"
assert "anstream bottoms out on is_terminal_polyfill, not atty/is-terminal" 'is_terminal_polyfill' "$AS_CT"
assert_n "anstream manifest: async runtime dependencies (tokio/async-std/futures)" 0 \
  "$(printf '%s\n' "$AS_CT" | grep -cE '^(tokio|async-std|futures)' | tr -d ' ')"
assert "anstyle workspace rust-version" 'rust-version = "1.66.0"' "$WS_CT"
POLY=$(raw polyfill-rs/is_terminal_polyfill v1.70.2 src/lib.rs)
assert "is_terminal_polyfill delegates to std::io::IsTerminal (adds no detection logic)" \
  'std::io::IsTerminal::is_terminal' "$POLY"
AQ_WIN=$(raw rust-cli/anstyle anstyle-query-v1.1.5 crates/anstyle-query/src/windows.rs)
assert "anstyle-query's Win32 module is gated behind #[cfg(windows)]" '#[cfg(windows)]' "$AQ_WIN"
assert "anstyle-query's Win32 module is where its unsafe lives" 'mod windows_console {' "$AQ_WIN"
assert_n "anstyle-query src/lib.rs: occurrences of unsafe (none outside the windows module)" 0 \
  "$(printf '%s\n' "$AQ" | grep -c 'unsafe' | tr -d ' ')"
echo "     anstream [dependencies] at tag anstream-v1.0.0 (gate 6, dependency footprint):"
printf '%s\n' "$AS_CT" | sed -n '/^\[dependencies\]/,/^$/p' | sed 's/^/       /'
printf '%s\n' "$AS_CT" | sed -n "/^\\[target..cfg(windows)...dependencies\\]/,/^$/p" | sed 's/^/       /'
for d in anstyle anstyle-parse colorchoice anstyle-query utf8parse is_terminal_polyfill; do
  assert "anstream [dependencies] includes $d" "$d = " "$(printf '%s\n' "$AS_CT" | sed -n '/^\[dependencies\]/,/^$/p')"
done
assert "anstream's Windows console adapter is a windows-only target dependency" \
  'anstyle-wincon = { version = "3.0.5", path = "../anstyle-wincon", optional = true }' "$AS_CT"
CI_YML=$(raw rust-cli/anstyle anstream-v1.0.0 .github/workflows/ci.yml)
assert "gate 4 anstyle CI covers ubuntu-latest and macos-latest" 'ubuntu-latest' "$CI_YML"
assert "gate 4 anstyle CI covers macos-latest" 'macos-latest' "$CI_YML"
printf '      rustsec anstream advisories: %s\n' "$(curl -sS https://rustsec.org/packages/anstream.html | grep -oE 'RUSTSEC-[0-9]{4}-[0-9]{4}' | sort -u | tr '\n' ' ')"
printf '      rustsec atty advisories:     %s\n' "$(curl -sS https://rustsec.org/packages/atty.html | grep -oE 'RUSTSEC-[0-9]{4}-[0-9]{4}' | sort -u | tr '\n' ' ')"
assert "gate 3 anstream's only advisory is the one patched at >=0.6.8" 'RUSTSEC-2024-0404' \
  "$(curl -sS https://rustsec.org/packages/anstream.html | grep -oE 'RUSTSEC-[0-9]{4}-[0-9]{4}' | sort -u | tr '\n' ' ')"
assert "RUSTSEC-2024-0404 is patched at >= 0.6.8" '0.6.8' \
  "$(curl -sS https://rustsec.org/advisories/RUSTSEC-2024-0404.html | sed -e 's/<[^>]*>//g' | tr -s ' \n' '  ')"
assert "gate 3 atty is excluded (unpatched advisories)" 'RUSTSEC-2021-0145' \
  "$(curl -sS https://rustsec.org/packages/atty.html | grep -oE 'RUSTSEC-[0-9]{4}-[0-9]{4}' | sort -u | tr '\n' ' ')"
assert_n "anstyle has no RustSec page (404 = no advisories)" 404 \
  "$(curl -sS -o /dev/null -w '%{http_code}' https://rustsec.org/packages/anstyle.html)"
echo

# --------------------------------------------------------------------------
echo "## 7. First-party practice at pinned tags (Compatibility + the per-stream shape)"
CG_MAN=$(raw rust-lang/cargo 0.99.0 Cargo.toml)
CG_SH=$(raw rust-lang/cargo 0.99.0 crates/cargo-util-terminal/src/shell.rs)
CG_CTX=$(raw rust-lang/cargo 0.99.0 src/cargo/util/context/mod.rs)
CL_MAN=$(raw clap-rs/clap v4.6.6 clap_builder/Cargo.toml)
assert "cargo 0.99.0 declares anstream 1.0.0"  'anstream = "1.0.0"'  "$CG_MAN"
assert "cargo 0.99.0 declares anstyle 1.0.14"  'anstyle = "1.0.14"'  "$CG_MAN"
assert "clap_builder v4.6.6 declares anstream 1.0.0 behind its color feature" 'anstream = { version = "1.0.0", optional = true }' "$CL_MAN"
assert "clap_builder v4.6.6 declares anstyle 1.0.14" 'anstyle = "1.0.14"' "$CL_MAN"
assert "cargo constructs ONE AutoStream PER STREAM with an explicitly resolved choice (stdout)" \
  'stdout: AutoStream::new(std::io::stdout(), stdout_choice),' "$CG_SH"
assert "cargo constructs ONE AutoStream PER STREAM with an explicitly resolved choice (stderr)" \
  'stderr: AutoStream::new(std::io::stderr(), stderr_choice),' "$CG_SH"
assert "cargo renders into a captured buffer with AutoStream::never (the deterministic-test seam)" \
  'ShellOut::Write(AutoStream::never(out))' "$CG_SH"
assert_n "cargo 0.99.0 shell.rs: calls to colorchoice write_global (it does NOT use the global)" 0 \
  "$(printf '%s\n' "$CG_SH" | grep -c 'write_global' | tr -d ' ')"
assert "cargo puts the --color FLAG above the [term] color CONFIG key, then defers to env+TTY" \
  'let color = color.or_else(|| term.color.as_deref());' "$CG_CTX"
printf '      cargo 0.99.0 flag>config, at src/cargo/util/context/mod.rs:\n'
printf '%s\n' "$CG_CTX" | grep -n 'let color = color.or_else\|self.shell().set_color_choice' | sed 's/^/        /'
printf '      cargo 0.99.0 per-stream construction, at crates/cargo-util-terminal/src/shell.rs:\n'
printf '%s\n' "$CG_SH" | grep -n 'AutoStream::new(std::io::std\|AutoStream::never' | sed 's/^/        /'
echo

# --------------------------------------------------------------------------
echo "## 8. BASELINE-REVIEW F286 evidence — the flag shape of the three cited tools, at tags"
CL_COL=$(raw clap-rs/clap v4.6.6 clap_builder/src/util/color.rs)
RG_DEF=$(raw BurntSushi/ripgrep 15.2.0 crates/core/flags/defs.rs)
assert "clap v4.6.6 ships a tri-state ColorChoice enum" 'pub enum ColorChoice {' "$CL_COL"
CL_VARIANTS=$(printf '%s\n' "$CL_COL" | grep -cE '^    (Auto|Always|Never),' | tr -d ' ')
assert_n "clap v4.6.6 ColorChoice variants Auto/Always/Never" 3 "$CL_VARIANTS"
assert "cargo 0.99.0 parses --color as always" '"always" => ColorChoice::Always,' "$CG_SH"
assert "cargo 0.99.0 parses --color as never"  '"never" => ColorChoice::Never,'   "$CG_SH"
assert "cargo 0.99.0 parses --color as auto"   '"auto" => ColorChoice::CargoAuto,' "$CG_SH"
assert "ripgrep 15.2.0 declares --color taking a WHEN value" 'Some("WHEN")' "$RG_DEF"
assert "cargo 0.99.0 accepts exactly three --color values, per its own error text" \
  'argument for --color must be auto, always, or ' "$CG_SH"
printf '      ripgrep 15.2.0 --color accepted values (crates/core/flags/defs.rs):\n'
printf '%s\n' "$RG_DEF" | sed -n '689,780p' | grep -oE '"(never|auto|always|ansi)"' | sort -u | tr '\n' ' ' | sed 's/^/        /'; echo
RG_VALUES=$(printf '%s\n' "$RG_DEF" | sed -n '689,780p' | grep -oE '"(never|auto|always|ansi)"' | sort -u | tr '\n' ' ')
assert "ripgrep's --color is NOT tri-state: it takes four values (ansi included)" '"ansi"' "$RG_VALUES"
assert "ripgrep 15.2.0 documents auto as the default setting for --color" \
  'The default setting is \fBauto\fP' "$(printf '%s\n' "$RG_DEF" | sed -n '689,730p')"
echo
echo "     Two further claims cited in the decision:"
ANSTYLE_LIB=$(raw rust-cli/anstyle v1.0.14 crates/anstyle/src/lib.rs)
ANSTYLE_MAN=$(raw rust-cli/anstyle v1.0.14 crates/anstyle/Cargo.toml)
AS_STRIP=$(raw rust-cli/anstyle anstream-v1.0.0 crates/anstream/src/adapter/strip.rs)
assert_n "anstyle 1.0.14 lib.rs: occurrences of unsafe" 0 "$(printf '%s\n' "$ANSTYLE_LIB" | grep -c 'unsafe' | tr -d ' ')"
assert_n "colorchoice 1.0.5 lib.rs: occurrences of unsafe" 0 "$(printf '%s\n' "$CC" | grep -c 'unsafe' | tr -d ' ')"
assert "anstyle 1.0.14 states keeping the formatting crate out of the public API as its use case" \
  'putting the text formatting crate in the public API' "$ANSTYLE_LIB"
assert_n "anstream 1.0.0 strip.rs: 'unsafe {' blocks" 2 \
  "$(printf '%s\n' "$AS_STRIP" | grep -c 'unsafe {' | tr -d ' ')"
assert "anstream's unsafe path demands a written safety justification" \
  'unsafe fn from_utf8_unchecked<'"'"'b>(bytes: &'"'"'b [u8], safety_justification: &'"'"'static str) -> &'"'"'b str {' "$AS_STRIP"
assert "anstream's unsafe path validates instead of assuming in debug builds" \
  'std::str::from_utf8(bytes).expect(safety_justification)' "$AS_STRIP"
assert_n "anstyle 1.0.14 manifest: [dependencies] entries (it is dependency-free)" 0 \
  "$(printf '%s\n' "$ANSTYLE_MAN" | awk '/^\[dependencies\]/{f=1;next} /^\[/{f=0} f && /=/ {c++} END{print c+0}')"
echo

# --------------------------------------------------------------------------
echo "## 9. Fixed parameters — generated from docs/port/PARAMETERS.md and diffed against DECISION.md"
PARAMS_MD="$REPO_ROOT/docs/port/PARAMETERS.md"
DECISION="$RUN_DIR/review/DECISION.md"
GEN="$EVID/params-generated.txt"
awk -F'|' '/^\| *(msrv-policy|rust-edition|target-os-matrix|license) *\|/ {
  gsub(/^[ \t]+|[ \t]+$/, "", $2); gsub(/^[ \t]+|[ \t]+$/, "", $5);
  printf "- assumes %s = %s\n", $2, $5
}' "$PARAMS_MD" > "$GEN"
echo "     generated from $PARAMS_MD:"
sed 's/^/       /' "$GEN"
if [ -f "$DECISION" ]; then
  grep '^- assumes ' "$DECISION" > "$EVID/params-in-decision.txt"
  if diff -u "$GEN" "$EVID/params-in-decision.txt" > "$EVID/params-diff.txt" 2>&1; then
    ok "DECISION.md '- assumes' lines are byte-identical to the registry-generated lines"
  else
    bad "DECISION.md '- assumes' lines differ from the registry"; sed 's/^/       /' "$EVID/params-diff.txt"
  fi
else
  bad "DECISION.md not found at $DECISION"
fi
echo

echo "## 10. Line-number ledger — every file:line cited in DECISION.md, checked at its tag/pin"
# ln <label> <text-blob> <line-number> <expected-substring-on-that-line>
ln_at() {
  local label="$1" blob="$2" n="$3" want="$4"
  local got; got=$(printf '%s\n' "$blob" | sed -n "${n}p")
  assert "$label (line $n)" "$want" "$got"
}
ln_at "py context.py R5.5 docstring"        "$PY_CTX"  189 'R5.5 precedence: --no-color flag > NO_COLOR env > config > auto.'
ln_at "py context.py NO_COLOR branch"       "$PY_CTX"  192 'if os.environ.get("NO_COLOR"):'
ln_at "py context.py config fall-through"   "$PY_CTX"  194 'return config_color'
ln_at "ts colors.ts FORCE_COLOR=0 carve-out" "$TS_COL"  35 "forceColor !== '0'"
ln_at "anstream AutoStream::new takes the resolved choice" "$AS_AUTO" 62 'pub fn new(raw: S, choice: ColorChoice) -> Self {'
ln_at "anstream new() delegates Auto to auto(raw)"         "$AS_AUTO" 65 'ColorChoice::Auto => Self::auto(raw),'
ln_at "anstream auto() is where the stream handle enters"  "$AS_AUTO" 78 'let choice = Self::choice(&raw);'
ln_at "anstream always_ansi() touches the handle (to enable ANSI, not to decide colour)" "$AS_AUTO" 95 'if raw.is_terminal() {'
ln_at "anstream always() touches the handle (to pick the wincon writer, not to decide colour)" "$AS_AUTO" 113 'let use_wincon = raw.is_terminal()'
ln_at "anstream choice() consults the colorchoice global first" "$AS_AUTO" 199 'let choice = ColorChoice::global();'
ln_at "anstream no_color tier"              "$AS_AUTO" 205 'anstyle_query::no_color()'
ln_at "anstream clicolor_force tier"        "$AS_AUTO" 207 'anstyle_query::clicolor_force()'
ln_at "anstream per-stream TTY tier"        "$AS_AUTO" 211 'raw.is_terminal()'
ln_at "colorchoice global static"           "$CC"       41 'static USER: AtomicChoice'
ln_at "colorchoice global underlying type"  "$CC"       44 'pub(crate) struct AtomicChoice(AtomicUsize);'
ln_at "supports-color force read first"     "$SC"       91 'let force_color = env_force_color();'
ln_at "supports-color no-color read second" "$SC"       94 'env_no_color()'
ln_at "console CLICOLOR_FORCE over NO_COLOR" "$CO_U"     18 'CLICOLOR_FORCE'
ln_at "console NO_COLOR is_ok (empty counts)" "$CO_X"    30 'env::var("NO_COLOR").is_ok()'
ln_at "owo-colors Override global"          "$OW_O"     78 'pub(crate) struct Override(AtomicU8);'
ln_at "cargo declares anstream"             "$CG_MAN"   21 'anstream = "1.0.0"'
ln_at "cargo declares anstyle"              "$CG_MAN"   22 'anstyle = "1.0.14"'
ln_at "cargo stdout AutoStream"             "$CG_SH"    53 'AutoStream::new(std::io::stdout(), stdout_choice)'
ln_at "cargo stderr AutoStream"             "$CG_SH"    54 'AutoStream::new(std::io::stderr(), stderr_choice)'
ln_at "cargo AutoStream::never test seam"   "$CG_SH"    71 'AutoStream::never(out)'
ln_at "cargo rebuilds stdout on set_color_choice" "$CG_SH" 262 'AutoStream::new(std::io::stdout(), stdout_choice)'
ln_at "cargo rebuilds stderr on set_color_choice" "$CG_SH" 263 'AutoStream::new(std::io::stderr(), stderr_choice)'
ln_at "cargo --color always"                "$CG_SH"   573 '"always" => ColorChoice::Always,'
ln_at "cargo --color never"                 "$CG_SH"   574 '"never" => ColorChoice::Never,'
ln_at "cargo --color auto"                  "$CG_SH"   576 '"auto" => ColorChoice::CargoAuto,'
ln_at "cargo flag-above-config"             "$CG_CTX" 1209 'let color = color.or_else(|| term.color.as_deref());'
ln_at "cargo hands result to set_color_choice" "$CG_CTX" 1210 'self.shell().set_color_choice(color)?;'
ln_at "clap ColorChoice enum"               "$CL_COL"    6 'pub enum ColorChoice {'
ln_at "clap ColorChoice::Auto"              "$CL_COL"   27 'Auto,'
ln_at "clap ColorChoice::Always"            "$CL_COL"   42 'Always,'
ln_at "clap ColorChoice::Never"             "$CL_COL"   57 'Never,'
ln_at "clap_builder anstream dep"           "$CL_MAN"   64 'anstream = { version = "1.0.0", optional = true }'
ln_at "clap_builder anstyle dep"            "$CL_MAN"   65 'anstyle = "1.0.14"'
ln_at "ripgrep --color long flag name"      "$RG_DEF"  698 '"color"'
ln_at "ripgrep --color metavariable WHEN"   "$RG_DEF"  701 'Some("WHEN")'
CE_MAN=$(raw eyre-rs/eyre color-eyre-v0.6.5 color-eyre/Cargo.toml)
ln_at "color-eyre depends on owo-colors (workspace-inherited)" "$CE_MAN" 25 'owo-colors = { workspace = true }'
CLR_LIB=$(raw colored-rs/colored v3.1.1 src/lib.rs)
CLR_CTL=$(raw colored-rs/colored v3.1.1 src/control.rs)
ln_at "colored Colorize method returns ColoredString"  "$CLR_LIB" 150 'fn red(self) -> ColoredString {'
ln_at "colored ColoredString Display impl"             "$CLR_LIB" 604 'impl fmt::Display for ColoredString {'
ln_at "colored Display consults has_colors() at format time" "$CLR_LIB" 606 'if !Self::has_colors() || self.is_plain() {'
ln_at "colored has_colors() reads the process global"  "$CLR_LIB" 384 'control::SHOULD_COLORIZE.should_colorize()'
ln_at "colored SHOULD_COLORIZE is one process-wide static" "$CLR_CTL" 86 'pub static SHOULD_COLORIZE: LazyLock<ShouldColorize> = LazyLock::new(ShouldColorize::from_env);'
ln_at "colored gate reads stdout's TTY-ness only"      "$CLR_CTL" 108 '&& io::stdout().is_terminal(),'
ln_at "colored checks CLICOLOR_FORCE before NO_COLOR"  "$CLR_CTL" 152 'if Self::normalize_env(clicolor_force) == Some(true) {'
ln_at "colored NO_COLOR tested second"                 "$CLR_CTL" 154 '} else if Self::normalize_env(no_color).is_some() {'
echo

# --------------------------------------------------------------------------
echo "## 11. Why colored 3.1.1 is excluded, now that gate 1 is inapplicable"
echo "     Read at tag colored-rs/colored@v3.1.1. The manifest is NEVER printed wholesale"
echo "     (it carries an author e-mail address); individual fields are asserted instead."
CLR_MAN=$(raw colored-rs/colored v3.1.1 Cargo.toml)
assert "colored manifest declares MPL-2.0 (recorded, no longer a gate)" 'license = "MPL-2.0"' "$CLR_MAN"
assert "colored manifest declares rust-version 1.80 (gate 2 passes)" 'rust-version = "1.80"' "$CLR_MAN"

# (a) What the API returns, and whether that type would cross a library's public surface.
assert "colored's styling entry point is the Colorize trait" 'pub trait Colorize: Sized {' "$CLR_LIB"
CLR_RET=$(printf '%s\n' "$CLR_LIB" | grep -c -- '-> ColoredString')
if [ "$CLR_RET" -ge 50 ]; then
  ok "every Colorize method returns ColoredString  [count of '-> ColoredString' in src/lib.rs = $CLR_RET]"
else
  bad "expected >=50 '-> ColoredString' returns in colored src/lib.rs, got $CLR_RET"
fi
assert "ColoredString is a public struct (it is what a pub fn would have to return)" 'pub struct ColoredString {' "$CLR_LIB"
assert "ColoredString's Display decides colour at format time, not at construction" \
  'if !Self::has_colors() || self.is_plain() {' "$CLR_LIB"
assert "has_colors() resolves against colored's process global" \
  'control::SHOULD_COLORIZE.should_colorize()' "$CLR_LIB"
assert_n "compute_style is private, so Display is the only styled-output path" 0 \
  "$(printf '%s\n' "$CLR_LIB" | grep -c 'pub fn compute_style')"
assert "SHOULD_COLORIZE is a single process-wide LazyLock static" \
  'pub static SHOULD_COLORIZE: LazyLock<ShouldColorize> = LazyLock::new(ShouldColorize::from_env);' "$CLR_CTL"

# (b) Can colored fill the stream-adapter role the recommended architecture needs?
CLR_WRITE_TOTAL=0
for f in lib.rs control.rs color.rs style.rs formatters.rs customcolors.rs error.rs; do
  body=$(raw colored-rs/colored v3.1.1 "src/$f")
  if [ -z "$body" ]; then bad "could not read colored src/$f at tag v3.1.1"; continue; fi
  n=$(printf '%s\n' "$body" | grep -cE 'io::Write|impl[^)]*\bWrite\b[^)]*for ')
  CLR_WRITE_TOTAL=$((CLR_WRITE_TOTAL + n))
  printf '      src/%-18s io::Write / Write-impl occurrences: %s\n' "$f" "$n"
done
assert_n "colored ships NO writer adapter anywhere in src/ (cannot fill the stream-adapter role)" 0 "$CLR_WRITE_TOTAL"

# (c) Per-stream gating: colored's gate is computed from stdout alone, process-wide.
assert "colored's env gate reads io::stdout().is_terminal()" '&& io::stdout().is_terminal(),' "$CLR_CTL"
assert_n "colored src/control.rs: occurrences of stderr (a stderr write is gated on stdout)" 0 \
  "$(printf '%s\n' "$CLR_CTL" | grep -c 'stderr')"
assert_n "colored src/lib.rs: occurrences of stderr" 0 \
  "$(printf '%s\n' "$CLR_LIB" | grep -c 'stderr')"
assert "colored's only escape hatch writes the same process-wide global (no per-stream override)" \
  'pub fn set_override(override_colorize: bool) {' "$CLR_CTL"

# (d) Same precedence defects as console 0.16.6 — recorded, not the load-bearing ground.
assert "colored lets CLICOLOR_FORCE win before NO_COLOR is tested" \
  'if Self::normalize_env(clicolor_force) == Some(true) {' "$CLR_CTL"
assert "colored treats any set NO_COLOR (including empty) as disabling" \
  '} else if Self::normalize_env(no_color).is_some() {' "$CLR_CTL"
assert "colored's normalize_env only excludes the literal \"0\"" \
  'env_res.map_or(None, |string| Some(string != "0"))' "$CLR_CTL"

# (e) Which raw report actually surveyed colored. Only Opus did; the Codex raw never names it.
CODEX_RAW="$RUN_DIR/raw/codex-5df6c0a31e49b8cfa8401fb94d64a97e9858516d0ec6962993df20d984362b94.md"
OPUS_RAW="$RUN_DIR/raw/opus-a92869ae8e70073d1a94ec2e3df1ef8d700d2cc91b324064903391fe3babfa33.md"
if [ -f "$CODEX_RAW" ] && [ -f "$OPUS_RAW" ]; then
  assert_n "the Codex raw never mentions colored (coverage gap, not a disagreement)" 0 \
    "$(grep -ci 'colored' "$CODEX_RAW")"
  OPUS_CLR=$(grep -ci 'colored' "$OPUS_RAW")
  if [ "$OPUS_CLR" -ge 5 ]; then
    ok "the Opus raw is the only one that surveyed colored  [occurrences=$OPUS_CLR]"
  else
    bad "expected >=5 'colored' occurrences in the Opus raw, got $OPUS_CLR"
  fi
else
  bad "raw reports not found at $CODEX_RAW / $OPUS_RAW"
fi
echo

echo "=============================================================="
printf 'TOTAL: %d passed, %d failed\n' "$PASS" "$FAIL"
echo "=============================================================="
[ "$FAIL" -eq 0 ]
