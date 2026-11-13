#!/usr/bin/env bash
# R65 color-enablement-chain — SUPPLEMENTARY verification script, revision 4.
#
# The primary script, review/evidence/check-color-enablement-chain.sh, is unchanged
# byte-for-byte from revision 3 and its log still reproduces; this script asserts ONLY
# what revision 4 added, so that every file:line citation this decision makes in its own
# voice is still re-read at its tag or pin:
#
#   J1 — tier 7 is a three-way disjunction, and each operand's source:
#        crates/anstream/src/auto.rs:203,211,212,213,214        @ anstream-v1.0.0
#        crates/anstyle-query/src/lib.rs:55,61,63,123,128,134   @ anstyle-query-v1.1.5
#        and the one standards sentence revision 4 newly quotes, read from the committed
#        snapshot review/evidence/snapshot-no-color.org.txt (no fetch)
#   J3 — the value a consumer can read as "this stream will accept escape codes":
#        crates/anstream/src/auto.rs:184,186,187,189,190     @ anstream-v1.0.0
#        and the two assumptions R85 records on this item, quoted from its published
#        decision at research/topics/85-rich-terminal-row-niceties/DECISION.md
#
# It implements nothing: no crate is scaffolded, no resolver is written, no template file
# is created. Every check asserts on expected CONTENT and prints PASS/FAIL; the script
# never reports success from an exit code alone.
set -o pipefail

UA='rs-launch-blueprint-R65-check'
RUN_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
REPO_ROOT="$(cd "$RUN_DIR/../../../.." && pwd)"
R85_DECISION="$REPO_ROOT/research/topics/85-rich-terminal-row-niceties/DECISION.md"
PASS=0
FAIL=0

ok()  { PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }
# assert <label> <expected-substring> <actual-text>
assert() {
  local label="$1" want="$2" got="$3"
  case "$got" in
    *"$want"*) ok "$label  [matched: $want]" ;;
    *)         bad "$label  [expected: $want] [got: $(printf '%s' "$got" | head -c 200)]" ;;
  esac
}
# ln_at <label> <text-blob> <line-number> <expected-substring-on-that-line>
ln_at() {
  local label="$1" blob="$2" n="$3" want="$4"
  local got; got=$(printf '%s\n' "$blob" | sed -n "${n}p")
  assert "$label (line $n)" "$want" "$got"
}
# raw <owner/repo> <tag> <path> -- immutable read at a git tag; empty on HTTP error
raw() {
  curl -sS -f -H "User-Agent: $UA" "https://raw.githubusercontent.com/$1/$2/$3" 2>/dev/null
}
tag_exists() {
  git ls-remote --tags "https://github.com/$1" "refs/tags/$2" 2>/dev/null | grep -c "refs/tags/$2$"
}

echo "=============================================================="
echo "R65 color-enablement-chain — revision 4 supplementary checks"
echo "=============================================================="
echo

echo "## R4.0 Toolchain"
rustc --version
cargo --version
printf 'os: %s %s\n' "$(uname -s)" "$(uname -m)"
sw_vers 2>/dev/null | tr '\n' ' '; echo
echo

echo "## R4.1 Tags exist before any file is read from them"
for t in anstream-v1.0.0 anstyle-query-v1.1.5; do
  if [ "$(tag_exists rust-cli/anstyle "$t")" = "1" ]; then
    ok "tag rust-cli/anstyle@$t exists"
  else
    bad "tag rust-cli/anstyle@$t NOT found"
  fi
done
echo

AS_AUTO=$(raw rust-cli/anstyle anstream-v1.0.0 crates/anstream/src/auto.rs)
AQ_LIB=$(raw rust-cli/anstyle anstyle-query-v1.1.5 crates/anstyle-query/src/lib.rs)
if [ -z "$AS_AUTO" ]; then bad "anstream auto.rs could not be fetched at anstream-v1.0.0"; fi
if [ -z "$AQ_LIB" ]; then bad "anstyle-query lib.rs could not be fetched at anstyle-query-v1.1.5"; fi

echo "## R4.2 J1 — tier 7 is a DISJUNCTION: term_supports_color OR clicolor_enabled OR is_ci"
echo "     Verbatim, crates/anstream/src/auto.rs:211-214 @ anstream-v1.0.0:"
printf '%s\n' "$AS_AUTO" | sed -n '211,214p' | sed 's/^/       /'
ln_at "anstream tier 7 begins with this stream's own is_terminal()" "$AS_AUTO" 211 '} else if raw.is_terminal()'
ln_at "anstream tier 7 operand 1: term_supports_color()"            "$AS_AUTO" 212 '&& (anstyle_query::term_supports_color()'
ln_at "anstream tier 7 operand 2: clicolor_enabled"                 "$AS_AUTO" 213 '|| clicolor_enabled'
ln_at "anstream tier 7 operand 3: is_ci()"                          "$AS_AUTO" 214 '|| anstyle_query::is_ci())'
ln_at "anstream clicolor_enabled is CLICOLOR set to a non-0 value"  "$AS_AUTO" 203 'let clicolor_enabled = clicolor.unwrap_or(false);'
# The operands must be OR-ed, not AND-ed: assert the || tokens are present on 213 and 214
OPS=$(printf '%s\n' "$AS_AUTO" | sed -n '212,214p' | grep -c '||')
if [ "$OPS" = "2" ]; then
  ok "tier 7's three operands are joined by exactly two || tokens (a disjunction)  [count=2]"
else
  bad "expected 2 '||' tokens across auto.rs:212-214, got $OPS"
fi
ln_at "anstyle-query term_supports_color is a TERM test"   "$AQ_LIB" 55  'pub fn term_supports_color() -> bool {'
ln_at "anstyle-query returns false when TERM is unset"     "$AQ_LIB" 61  'None => return false,'
ln_at "anstyle-query returns false for TERM=dumb"          "$AQ_LIB" 63  'if k == "dumb" {'
ln_at "anstyle-query documents WHY the CI operand exists (the ground for declining a TERM tier)" \
  "$AQ_LIB" 123 '/// CI is a common environment where, despite being piped, ansi color codes are supported'
ln_at "anstyle-query is_ci signature"                      "$AQ_LIB" 128 'pub fn is_ci() -> bool {'
ln_at "anstyle-query is_ci tests PRESENCE of CI, not its value" "$AQ_LIB" 134 'std::env::var_os("CI").is_some()'
# is_ci must not compare CI against a value anywhere in its body
CI_BODY=$(printf '%s\n' "$AQ_LIB" | sed -n '128,136p')
case "$CI_BODY" in
  *'== "false"'*|*'== "0"'*) bad "is_ci() compares CI against a value; the decision says it tests presence" ;;
  *)                         ok  "is_ci() body compares CI against no value (presence test confirmed)" ;;
esac
echo

echo "## R4.3 J3 — the per-stream effective choice a consumer can read"
ln_at "anstream current_choice reports what is ACTIVE, not what was requested" "$AS_AUTO" 184 "This doesn't report what is requested but what is currently active."
ln_at "anstream current_choice is gated on the auto feature"                   "$AS_AUTO" 186 '#[cfg(feature = "auto")]'
ln_at "anstream current_choice signature"                                      "$AS_AUTO" 187 'pub fn current_choice(&self) -> ColorChoice {'
ln_at "anstream current_choice: a pass-through stream reports AlwaysAnsi"      "$AS_AUTO" 189 'StreamInner::PassThrough(_) => ColorChoice::AlwaysAnsi,'
ln_at "anstream current_choice: a stripping stream reports Never"              "$AS_AUTO" 190 'StreamInner::Strip(_) => ColorChoice::Never,'
echo

echo "## R4.4 J3 — the two assumptions R85 records on this item, quoted from its published decision"
if [ -f "$R85_DECISION" ]; then
  ok "R85 published decision found at $R85_DECISION"
  R85=$(tr '\n' ' ' < "$R85_DECISION" | tr -s ' ')
  assert "R85 assumption 1 — R65 must expose a readable 'accepts escape codes' value" \
    "**R65** must expose something the CLI can read as \"this stream will accept escape codes\"" "$R85"
  assert "R85 assumption 1 — the boolean composition R85 would use" \
    'color_enabled && supports_hyperlinks::on(Stdout)' "$R85"
  assert "R85 assumption 2 — FORCE_HYPERLINK, which R65 may not have scoped" \
    'R65 additionally acquires an input it may not have scoped: `FORCE_HYPERLINK`' "$R85"
  assert "R85 assumption 2 — honored independently of NO_COLOR/FORCE_COLOR" \
    'honors independently of `NO_COLOR`/`FORCE_COLOR` (`src/lib.rs:14,66`)' "$R85"
  assert "R85 repeats FORCE_HYPERLINK as its own P03 validation item" \
    '**`FORCE_HYPERLINK` in R65'"'"'s precedence chain.**' "$R85"
  assert "R85 is the resolved consumer that composes with this chain's colour choice" \
    'combined with whatever color choice R65' "$R85"
else
  bad "R85 published decision NOT found at $R85_DECISION"
fi
echo

echo "## R4.5 The one standards sentence revision 4 newly quotes, read from the COMMITTED snapshot"
echo "     (no network fetch; the snapshot is the evidence, as in the primary script's section 5)"
NC_SNAP="$RUN_DIR/review/evidence/snapshot-no-color.org.txt"
if [ -f "$NC_SNAP" ]; then
  printf '     sha256: %s\n' "$(shasum -a 256 "$NC_SNAP" | awk '{print $1}')"
  NC=$(tr '\n' ' ' < "$NC_SNAP" | tr -s ' ')
  assert "no-color.org argues against a TERM tier (the third ground for declining one)" \
    'Why not just set $TERM to dumb or xterm without color support?' "$NC"
  assert "no-color.org: the terminal should print colour when instructed" \
    'The terminal is capable of color and should be able to print color when instructed.' "$NC"
else
  bad "no-color.org snapshot NOT found at $NC_SNAP"
fi
echo

echo "## R4.6 This revision's own text carries the qualifications it claims"
DEC="$RUN_DIR/review/DECISION.md"
if [ -f "$DEC" ]; then
  DECT=$(tr '\n' ' ' < "$DEC" | tr -s ' ')
  assert "criterion 9 is scoped to CI and CLICOLOR both unset" \
    'with `CI` and `CLICOLOR` both unset** (not merely set to `0` — see `## Engines` item 2), nothing else set ⇒ no colour' "$DECT"
  assert "criterion 11 exercises the config tier against NO_COLOR" \
    'Config file `color = "always"`, `NO_COLOR=1` set' "$DECT"
  assert "criterion 12 exercises the config tier against the force tiers" \
    'Config file `color = "never"`, `FORCE_COLOR=1` and `CLICOLOR_FORCE=1` set' "$DECT"
  assert "the decision names R85 as a consumer" 'rich-terminal-row-niceties`, resolved,' "$DECT"
  assert "the decision rules FORCE_HYPERLINK out of this chain" \
    '**Ruled out of this chain, explicitly.**' "$DECT"
  assert "the decision declines a template-owned TERM tier and says so" \
    '**A template-owned `TERM` tier was considered and is declined.**' "$DECT"
else
  bad "DECISION.md not found at $DEC"
fi
echo

echo "=============================================================="
printf 'TOTAL: %d passed, %d failed\n' "$PASS" "$FAIL"
echo "=============================================================="
[ "$FAIL" -eq 0 ]
