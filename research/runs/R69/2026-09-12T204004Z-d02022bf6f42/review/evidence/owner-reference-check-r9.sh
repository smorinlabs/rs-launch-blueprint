#!/usr/bin/env bash
# shellcheck disable=SC2015,SC2016,SC2329
#   SC2015 (`A && B || C` is not if-then-else) - every `&& echo OK || { echo FAIL; rc=1; }`
#          chain below is deliberate: B is an `echo` that cannot fail, so C runs only when A is
#          false.
#   SC2016 (expressions do not expand in single quotes) - the single-quoted `jq` programs must
#          reach jq unexpanded.
#   SC2329 (function never invoked) - `cleanup` is invoked indirectly, by `trap cleanup EXIT`.
#   These are the same three informational codes `feature-shape-check-r4.sh`,
#   `yanked-control-r5.sh` and `owner-reference-check-r6.sh` disable, and they are the only
#   codes shellcheck raises against this file. The repository runs shellcheck over every staged
#   *.sh file from a pre-commit hook. The directive is a comment: it changes no byte of output.
#
# R69 evidence, revision 9: PRIMARY-SOURCE VERIFICATION FOR THE THREE OWNER-REFERENCE ROWS
# THAT REVISION 6 MISSED.
#
# WHY THIS SCRIPT EXISTS. Revision 6 reconciled eight rows of the owner-supplied reference
# architecture under owner decision 11. The brief drafter's report found three further rows of
# the reference `Cargo.toml` carrying no disposition at all:
#
#   A. `tokio = { version = "1", features = ["full"] }` — against the six named tokio features
#      this decision selects.
#   B. `axum-extra = { version = "0.12.6", features = ["cookie","cookie-private","typed-header"] }`
#      — a crate this decision's stack does not contain.
#   C. `[profile.release] lto = "thin" / codegen-units = 1` — a manifest section no part of
#      this decision mentions.
#
# Revision 9 adds exactly those three rows. This script asserts the facts they rest on.
#
# WHAT IT READS. Sections A and B read only the reduced snapshots under `snapshots/r9/`, which
# ARE committed and were written by the sibling fetcher `fetch-owner-reference-r9.sh`; this
# script never touches the network, which is what makes it rerunnable offline and
# byte-identical from a clean `git archive HEAD` extraction after this decision is committed.
# Section C reads committed files of THIS repository — the research index and every item's
# binding prompt — because the question it answers is which P02 item owns a subject, and that
# is a fact about this repository rather than about an upstream project.
#
# It does NOT touch `owner-reference-check-r6.sh`, `yanked-control-r5.sh`, the six checks, or
# any snapshot outside `snapshots/r9/`. Every one of those files is byte-identical after
# revision 9.
#
# WHAT IT ASSERTS. Content, never an exit code alone:
#
#   A. tokio 1.53.1's own `[features]` map: `default = []`; `full` expands to twelve names;
#      `rt-multi-thread` implies `rt`; the six features this decision selects, plus that
#      implied `rt`, cover seven of the twelve; and the five `full` adds beyond them are
#      `fs`, `io-util`, `io-std`, `parking_lot` and `process`. It further asserts that
#      `parking_lot` is an OPTIONAL DEPENDENCY of tokio, which is why enabling it costs a crate
#      in the resolved tree rather than only a code path — the cost gate 6 measures.
#   B. axum-extra 0.12.6: it is the newest non-yanked and the newest stable version, its
#      licence and declared `rust-version`, and that the three features the reference enables
#      pull `cookie` and `headers` in as optional dependencies.
#   C. The ownership question for `[profile.release]`, answered against this repository rather
#      than asserted: NO binding prompt of ANY research item, and no row of the commonality
#      ledger, names `[profile`, `lto`, `codegen-units` or `opt-level`. The searches are run
#      over the complete prompt set and their denominator is printed, so the claim is a census
#      and not a sample. It also asserts the two positive facts that make R68 the nearest
#      consumer and R49 not the owner.
#   D. A DELIBERATE CONTROL that must FAIL, so that a check which cannot fail is visible as
#      such: the same census test that reports zero prompts naming `[profile` is applied to a
#      string every prompt does contain.
#
# This script decides nothing about the recommendation: it establishes the facts on which
# revision 9's three rows record agreement, a ground for differing, or a hand-off. It is listed
# alongside `yanked-control-r5.sh` and `owner-reference-check-r6.sh` under `## Empirical check`
# as a further script rather than as a seventh check.
set -o pipefail
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="$HERE/snapshots/r9"
# <run>/review/evidence -> review -> <run> -> R69 -> runs -> research  (five levels)
RESEARCH="$(cd "$HERE/../../../../.." && pwd)"
JQ="${JQ:-/opt/homebrew/bin/jq}"
GREP=/usr/bin/grep

rc=0

say() { printf '\n== %s ==\n' "$1"; }

# must <label> <expected> <actual>
must() {
  if [ "$2" = "$3" ]; then
    printf 'OK   %-58s %s\n' "$1" "$3"
  else
    printf 'FAIL %-58s expected=%s actual=%s\n' "$1" "$2" "$3"; rc=1
  fi
}

# has <label> <needle> <file>
has() {
  if "$GREP" -qF -- "$2" "$3"; then
    printf 'OK   %-58s present\n' "$1"
  else
    printf 'FAIL %-58s absent: %s\n' "$1" "$2"; rc=1
  fi
}

echo "R69 revision 9 — owner-reference rows A, B and C primary-source check"
echo "grep binary: /usr/bin/grep (the POSIX grep, invoked by absolute path; never a shell alias, never ugrep)"
echo "jq binary: $JQ"
echo "snapshot dir: <run>/review/evidence/snapshots/r9 (committed; written by fetch-owner-reference-r9.sh)"
echo "snapshots retrieved at: $(cat "$SNAP/RETRIEVED-AT.txt")"
echo "repository tree read for section C: <repo>/research (index and every item's prompt, committed)"
echo "network: NOT used by this script; sections A and B read committed snapshots, section C reads committed files"

for f in crates-tokio-features.json crates-axum-extra.json; do
  [ -f "$SNAP/$f" ] && printf 'OK   %-58s present\n' "snapshot $f" \
    || { printf 'FAIL %-58s missing\n' "snapshot $f"; rc=1; }
done

# --------------------------------------------------------------------------- A
say "A. tokio 1.53.1: what \`full\` is, against the six this decision selects (row A)"
A="$SNAP/crates-tokio-features.json"
must "tokio version snapshotted"              "1.53.1" "$("$JQ" -r '.num' "$A")"
must "tokio default feature set is empty"     "0"      "$("$JQ" -r '.default_feature | length' "$A")"
must "tokio \`full\` expands to N features"     "12"     "$("$JQ" -r '.full_feature_count' "$A")"
must "features this decision selects"          "6"      "$("$JQ" -r '.selected_count' "$A")"
must "rt-multi-thread implies rt"              "rt"     "$("$JQ" -r '.rt_multi_thread_expands_to[0]' "$A")"
must "of \`full\`, covered by the six plus rt"   "7"      \
  "$("$JQ" -r '(.full_feature_count) - (.full_adds_beyond_selected | length)' "$A")"
must "what \`full\` adds beyond them, count"     "5"      "$("$JQ" -r '.full_adds_beyond_selected | length' "$A")"
must "what \`full\` adds beyond them, names"     "fs,io-util,io-std,parking_lot,process" \
  "$("$JQ" -r '.full_adds_beyond_selected | join(",")' "$A")"
must "parking_lot is an optional DEPENDENCY"   "true"   \
  "$("$JQ" -r '.optional_dependency_additions.parking_lot.optional' "$A")"
must "parking_lot dependency requirement"      "^0.12.0" \
  "$("$JQ" -r '.optional_dependency_additions.parking_lot.req' "$A")"
echo "consequence: \`full\` is not a superset this decision declined for taste. It names five"
echo "             capabilities nothing in F338 uses, one of which (parking_lot) is an optional"
echo "             dependency and therefore lands in the resolved tree gate 6 measures."

# --------------------------------------------------------------------------- B
say "B. axum-extra 0.12.6, which this decision's stack does not contain (row B)"
B="$SNAP/crates-axum-extra.json"
must "axum-extra version snapshotted"         "0.12.6" "$("$JQ" -r '.num' "$B")"
must "axum-extra is not yanked"               "false"  "$("$JQ" -r '.yanked' "$B")"
must "axum-extra newest stable version"       "0.12.6" "$("$JQ" -r '.max_stable_version' "$B")"
must "axum-extra licence"                     "MIT"    "$("$JQ" -r '.license' "$B")"
must "axum-extra declared rust-version"       "1.80"   "$("$JQ" -r '.rust_version' "$B")"
must "axum-extra requires axum"               "^0.8.9" "$("$JQ" -r '.requirements.axum.req' "$B")"
must "cookie is an optional dependency"       "true"   "$("$JQ" -r '.requirements.cookie.optional' "$B")"
must "headers is an optional dependency"      "true"   "$("$JQ" -r '.requirements.headers.optional' "$B")"
must "the reference's \`cookie\` feature"       "dep:cookie" \
  "$("$JQ" -r '.features_the_reference_enables.cookie | join(",")' "$B")"
must "the reference's \`typed-header\` feature" "dep:headers" \
  "$("$JQ" -r '.features_the_reference_enables["typed-header"] | join(",")' "$B")"
echo "consequence: the three features the reference enables are exactly two extra crates —"
echo "             cookie jars and typed headers — neither of which any behaviour this item"
echo "             owns asks for. The version the reference names is current, not stale."

# --------------------------------------------------------------------------- C
say "C. which P02 item owns \`[profile.release]\` — answered against this repository (row C)"
PROMPTS=$(find "$RESEARCH/topics" -name '*.prompt.md' | wc -l | "$GREP" -o '[0-9]*')
echo "prompt files searched (the complete set): $PROMPTS"
must "the prompt set is non-empty"            "yes" "$([ "$PROMPTS" -gt 0 ] && echo yes || echo no)"

profile_hits=$(find "$RESEARCH/topics" -name '*.prompt.md' -exec \
  "$GREP" -l -E '\[profile|lto = |codegen-units|opt-level' {} + 2>/dev/null | wc -l | "$GREP" -o '[0-9]*')
must "prompts naming [profile/lto/codegen-units/opt-level" "0" "$profile_hits"

LEDGER="$RESEARCH/../docs/port/COMMONALITY.md"
must "the commonality ledger is readable"                 "yes" \
  "$([ -r "$LEDGER" ] && echo yes || echo no)"
ledger_hits=$("$GREP" -c -E '\[profile|lto|codegen-units|opt-level' "$LEDGER" 2>/dev/null)
must "commonality-ledger rows naming those keys"           "0" "${ledger_hits:-unreadable}"

R68P="$RESEARCH/topics/68-release-binary-artifacts/prompts/release-binary-artifacts.prompt.md"
R49D="$RESEARCH/runs/R49/2026-09-05T155504Z-2107cffb3ecf/review/DECISION.md"
has "R68 is scoped to distribution artifact TYPES" \
    'this item decides only which distribution channels/artifact *types* beyond the base `.crate` file get built and shipped' "$R68P"
has "R68 puts manifest declarations in R49's scope" \
    'The Cargo manifest'"'"'s build-target declarations' "$R68P"
has "R49 owns the manifest as the declaration surface" \
    'no build backend or bundler crate; Cargo'"'"'s own manifest is the entire declaration surface' "$R49D"
has "R49 names R68 as the consumer of target/release" \
    'R68'"'"'s release matrix uploads the filename `target/release/rslbp`' "$R49D"
r49_profile_keys=$("$GREP" -c -E '\[profile\.|lto = |codegen-units' "$R49D" 2>/dev/null)
must "R49 sets any [profile.*] key"                        "0" "${r49_profile_keys:-unreadable}"
echo "consequence: no item's prompt and no ledger row claims release-profile settings, so this"
echo "             row is a hand-off whose owner is not yet fixed. R68 is the nearest consumer"
echo "             because the release binary's size and build time are what the profile"
echo "             governs and what R68's own questions weigh; R49 owns the manifest's"
echo "             declaration surface but sets no profile key. Recorded as the controller's"
echo "             reading with the gap named, not as a settled ownership."

# --------------------------------------------------------------------------- D
say "D. control — the same census test applied to a string every prompt DOES contain"
ctl_hits=$(find "$RESEARCH/topics" -name '*.prompt.md' -exec \
  "$GREP" -l -F 'Research mandate' {} + 2>/dev/null | wc -l | "$GREP" -o '[0-9]*')
if [ "$ctl_hits" = "0" ]; then
  printf 'FAIL %-58s control did not fail; the census test cannot fail\n' "control"
  rc=1
else
  printf 'OK   %-58s control reports %s of %s prompts\n' \
    "control (expected to report a present string)" "$ctl_hits" "$PROMPTS"
fi
echo "reading: section C asserts zero prompts name [profile. This control runs the identical"
echo "         find/grep -l census over the identical file set for a string the prompts do"
echo "         carry, so the zero above is capable of being non-zero."

printf '\nowner-reference-check-r9 rc=%s\n' "$rc"
exit "$rc"
