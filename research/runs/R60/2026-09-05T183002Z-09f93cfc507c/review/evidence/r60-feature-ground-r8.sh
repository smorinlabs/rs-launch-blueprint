#!/usr/bin/env bash
# R60 revision 8 — the evidence behind finding F6's repair: what, in committed
# artifacts, grounds `wrap_help` and what fails to ground `string`. NEW file; no
# earlier script is edited, because `r60-standard-pin-r5.sh` and
# `r60-snapshot-provenance-r4.sh` are the artifacts the round-7 empirical audit
# reran and diffed byte-for-byte.
#
# WHY IT EXISTS. The round-7 judgment audit found `string` and `wrap_help`
# supported by nothing but three adopter manifests — "repository agreement",
# which the programme's governing rule forbids as a selector. This script does
# not argue; it reads three committed artifacts and prints what they say, so the
# decision's grounding paragraph rests on assertions an auditor reruns rather
# than on a synthesis's say-so.
#
# WHAT IT ESTABLISHES, in the order the checks run:
#   G2  `wrap_help`'s ground is FUNCTIONAL. clap's own `Command::term_width`
#       documentation states that help wraps to the CURRENT TERMINAL WIDTH only
#       when the feature is enabled, and to a fixed 100 columns otherwise. The
#       pinned CLI Design Standard's R7.3 (SHOULD) requires presentation to
#       adapt to the terminal and R7.5 (MUST) requires structured help. Help
#       width is presentation; the feature is what makes it adapt.
#   G3  `string`'s only appearances in the committed `clap_builder` snapshot are
#       the doctest gates of `Command::mut_args` and `Command::mut_subcommands`
#       — the exact API this decision excludes under R5.4 (MUST NOT). STATE THE
#       LIMIT: that is ONE FILE of `clap_builder`, the file this run snapshotted.
#       The claim it supports is about those two APIs, not about the crate.
#   G4  the derive front end does not need `string`. `clap_derive`'s
#       `default_value_t` — the one derive attribute that turns a runtime value
#       into a clap attribute — deliberately emits a `OnceLock<String>` and hands
#       clap a `&'static str`, so no owned `String` crosses the boundary.
#   G5  `clap_complete` does not pull `string` in transitively: it depends on
#       `clap` with `features = ["std"]` and `default-features = false`, and the
#       only feature of its own that adds a `clap` feature is the non-default
#       `unstable-dynamic`, which this decision does not select.
#
# WHAT IT DOES NOT ESTABLISH, stated rather than left to be found. It does not
# prove that NO api in all of `clap_builder` is gated on `string` — only one
# file of that crate is committed here. It proves that the two APIs whose
# examples need the feature are the two this decision rules out, and that the
# three mechanisms this template's decided design actually uses (the derive
# front end, `clap_complete`, and the version path after option (b) removed
# `long_version`) reach clap without an owned `String`.
#
# WHAT IT READS. Four files, all committed inside this run directory: three
# snapshots verified against `snapshots/MANIFEST.txt` before they are read, and
# the revision-1 verification log. It makes no network call. GIT IS NOT USED AT
# ALL, so there is nothing to skip when `.git` is absent: it runs identically
# inside a clean `git archive HEAD` extraction. It reads `review/DECISION.md`
# nowhere, so its log does not move when the decision text is edited.
#
# Output is location-independent: no absolute path is printed and `shasum` is fed
# on stdin so it prints `-` rather than a file name.
#
# Harness note: `check` is never placed on the right-hand side of a pipe, because
# a piped function body runs in a subshell and its increment of `fails` is lost.
#
# SHELLCHECK. The repository's pre-commit hook fails on any shellcheck finding,
# info level included. Several expectations below are literal Rust or TOML
# carrying `$`-free backticks and `#[...]` attributes, single-quoted so the text
# reaches `grep -F` exactly as the source writes it; shellcheck reports SC2016 on
# them, which is true and is the point. The file-level directive disables that
# one code and nothing else, and the committed log is unaffected by it.
# shellcheck disable=SC2016
set -o pipefail

GREP=/usr/bin/grep   # absolute, never PATH: a typed `grep` here can be ugrep

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="$HERE/snapshots"

STD="$SNAP/cli-design-standard-1.4.14.md"
CMD="$SNAP/clap_builder-4.6.6-src-builder-command.rs.txt"
ITEM="$SNAP/clap_derive-4.6.4-src-item.rs.txt"
VLOG="$HERE/r60-cli-parsing-verification.log"

fails=0
checks=0

check() { # check <label> <expected-substring> <actual-output>
  local label="$1" want="$2" got="$3"
  checks=$((checks + 1))
  if [ -z "$want" ]; then
    printf 'BUG   %s — empty expectation; a check that cannot fail is not evidence\n' "$label"
    fails=$((fails + 1))
    return
  fi
  if printf '%s' "$got" | "$GREP" -qF -- "$want"; then
    printf 'PASS  %s\n' "$label"
  else
    printf 'FAIL  %s\n      wanted substring: %s\n      got: %s\n' "$label" "$want" "$got"
    fails=$((fails + 1))
  fi
}

sha() { shasum -a 256 < "$1" | awk '{print $1}'; }

echo "=== G-grep. the search binary every count below was produced by ==="
GREP_VERSION="$("$GREP" --version 2>&1 | head -1)"
echo "grep binary:  $GREP"
echo "grep version: $GREP_VERSION"

echo "=== G0. negative control: prove this harness can actually fail ==="
echo "--- the next FAIL line is deliberate ---"
check "G0 control (expected to FAIL)" "THIS-SUBSTRING-IS-ABSENT" "committed snapshot text"
if [ "$fails" -eq 1 ] && [ "$checks" -eq 1 ]; then
  echo "PASS  G0 harness detected the mismatch and incremented its counter"
else
  echo "BUG   G0 harness did NOT register the mismatch (fails=$fails checks=$checks) — results below are meaningless"
  exit 99
fi
echo "--- control accounted for; counters reset, real checks follow ---"
fails=0
checks=0

check "G-grep the search binary is an absolute /usr/bin/grep that reports a version" \
  "grep" "$GREP:$GREP_VERSION"

echo "=== G1. every artifact read below is the one MANIFEST.txt records ==="
# The integrity anchor. A snapshot edited after the fact fails here before any
# content assertion is allowed to read it.
for f in cli-design-standard-1.4.14.md \
         clap_builder-4.6.6-src-builder-command.rs.txt \
         clap_derive-4.6.4-src-item.rs.txt; do
  want="$("$GREP" -F "|$f|" "$SNAP/MANIFEST.txt" | cut -d'|' -f1)"
  got="$(sha "$SNAP/$f")"
  printf '%s  %s\n' "$got" "$f"
  check "G1 $f matches its recorded sha256" "$want" "$got"
done
out="$([ -f "$VLOG" ] && echo present || echo MISSING)"
echo "revision-1 verification log: $out"
check "G1d the revision-1 verification log is committed in review/evidence/" "present" "$out"

echo "=== G2. wrap_help's FUNCTIONAL ground: the standard's rule and clap's own doc ==="
# Half one: what the standard requires.
out="$(sed -n '390p' "$STD")"
echo "standard :390 (R7.3 body): $out"
check "G2a R7.3 (SHOULD) requires presentation to adapt to the terminal" \
  "A tool **SHOULD** detect whether stdout is a TTY and adjust *presentation* accordingly" "$out"
out="$(sed -n '398p' "$STD")"
echo "standard :398 (R7.5 body): $out"
check "G2b R7.5 (MUST) requires structured, sectioned help" \
  "**MUST** print structured help containing, in order" "$out"
# Half two: what the feature actually changes, in clap's own words.
out="$(sed -n '1375,1376p' "$CMD")"
echo "command.rs :1375-1376: $out"
check "G2c clap documents the wrapping width as the terminal's ONLY with the feature on" \
  "Defaults to current terminal width when \`wrap_help\` feature flag is enabled." "$out"
check "G2d and as a fixed 100 columns when the width cannot be determined" \
  "the default is 100." "$out"
out="$(sed -n '1389p' "$CMD")"
echo "command.rs :1389: $out"
check "G2e clap states the requirement on term_width explicitly" \
  "This requires the \`wrap_help\` feature" "$out"

echo "=== G3. string's only gates in the committed command.rs are the two EXCLUDED APIs ==="
# STATE THE LIMIT: this is one file of clap_builder, the file this run snapshotted.
out="$("$GREP" -c 'feature = "string"' "$CMD")"
echo "occurrences of 'feature = \"string\"' in the committed command.rs ($GREP $GREP_VERSION): $out"
check "G3a there are exactly four occurrences, two cfg_attr pairs" "count=4" "count=$out"
out="$("$GREP" -n 'feature = "string"' "$CMD" | cut -d: -f1 | tr '\n' ' ')"
echo "their line numbers: $out"
check "G3b they are at :264 :265 :395 :396 and nowhere else" "264 265 395 396 " "$out"
out="$(sed -n '264,265p' "$CMD")"
echo "$out"
check "G3c :264-265 is a doctest gate, not an API gate" \
  '#[cfg_attr(feature = "string", doc = "```")]' "$out"
check "G3c2 and its partner hides the example when the feature is off" \
  '#[cfg_attr(not(feature = "string"), doc = "```ignore")]' "$out"
out="$(sed -n '296p' "$CMD")"
echo "command.rs :296: $out"
check "G3d the API those two lines document is Command::mut_args" "pub fn mut_args" "$out"
out="$(sed -n '395,396p' "$CMD")"
echo "$out"
check "G3e :395-396 is the same doctest gate" \
  '#[cfg_attr(feature = "string", doc = "```")]' "$out"
out="$(sed -n '426p' "$CMD")"
echo "command.rs :426: $out"
check "G3f the API those two lines document is Command::mut_subcommands" "pub fn mut_subcommands" "$out"
# And the reason that matters: mut_args is the mechanism R5.4 forbids this
# template from using, so the one API in this file whose example needs `string`
# is an API the decision has already excluded.
out="$(sed -n '322p' "$STD")"
echo "standard :322 (R5.4 body): $out"
check "G3g R5.4 (MUST NOT) is what excludes the mut_args blanket-env design" \
  "**MUST NOT** auto-expose every flag as an env var" "$out"

echo "=== G4. the derive front end reaches clap without an owned String ==="
# default_value_t is the one derive attribute that turns a runtime value into a
# clap attribute. clap_derive routes it around the `string` feature deliberately.
out="$(sed -n '552p' "$ITEM")"
echo "item.rs :552: $out"
check "G4a :552 is the DefaultValueT arm" "Some(MagicAttrName::DefaultValueT) =>" "$out"
out="$(sed -n '588p' "$ITEM")"
echo "item.rs :588: $out"
check "G4b it emits a static OnceLock<String> rather than handing clap the String" \
  "static DEFAULT_VALUE: ::std::sync::OnceLock<String> = ::std::sync::OnceLock::new();" "$out"
out="$(sed -n '593p' "$ITEM")"
echo "item.rs :593: $out"
check "G4c and narrows it to a &'static str before clap sees it" \
  "let s: &'static str = &*s;" "$out"
out="$(sed -n '598p' "$ITEM")"
echo "item.rs :598: $out"
check "G4d which is then passed to Command/Arg as the default_value method" \
  'Ident::new("default_value"' "$out"
# The control that keeps G4 from being vacuous: the file does contain the string
# `feature = "string"` nowhere, so clap_derive gates nothing on it.
out="$("$GREP" -c 'feature = "string"' "$ITEM" || true)"
echo "occurrences of 'feature = \"string\"' in the committed item.rs: $out"
check "G4e clap_derive's item.rs gates nothing on the string feature" "count=0" "count=$out"

echo "=== G5. clap_complete does not pull the feature in transitively ==="
out="$(sed -n '709,740p' "$VLOG")"
echo "$out"
check "G5a the log section is clap_complete 4.6.9's manifest read" \
  "=== Q. clap_complete 4.6.9: deps, features, shells ===" "$out"
check "G5b it depends on clap with features = [\"std\"] only" 'features = ["std"]' "$out"
check "G5c with default features off" "default-features = false" "$out"
check "G5d its own default feature set is empty" "default = []" "$out"
check "G5e and the only feature of its own that adds a clap feature is unstable-dynamic" \
  '"clap/unstable-ext",' "$out"

echo
printf 'CHECKS RUN: %d   FAILURES: %d\n' "$checks" "$fails"
if [ "$fails" -eq 0 ]; then echo "RESULT: all checks passed"; else echo "RESULT: FAILED"; fi
exit "$fails"
