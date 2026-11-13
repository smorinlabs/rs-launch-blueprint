#!/usr/bin/env bash
# shellcheck disable=SC2015,SC2016,SC2329
#   SC2015 (`A && B || C` is not if-then-else) - every `&& echo OK || { echo FAIL; rc=1; }`
#          chain below is deliberate: B is an `echo` that cannot fail, so C runs only when A is
#          false.
#   SC2016 (expressions do not expand in single quotes) - the single-quoted `jq` programs must
#          reach jq unexpanded.
#   SC2329 (function never invoked) - `cleanup` is invoked indirectly, by `trap cleanup EXIT`.
#   These are the same three informational codes `feature-shape-check-r4.sh` and
#   `yanked-control-r5.sh` disable, and they are the only codes shellcheck raises against this
#   file. The repository runs shellcheck over every staged *.sh file from a pre-commit hook.
#   The directive is a comment: it changes no byte of this script's output.
#
# R69 evidence, revision 6: PRIMARY-SOURCE VERIFICATION OF THE OWNER-SUPPLIED REFERENCE
# ARCHITECTURE, for the rows revision 6 reconciles.
#
# WHY THIS SCRIPT EXISTS. Owner decision 11 (2026-09-16) folds
# `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` into R69 as an
# owner-supplied research INPUT, not a binding standard. That document's own closing caveat
# says its code patterns were "compiled in my head, not against the toolchain", and it flags
# several versions "verify". So every fact revision 6 takes from it is re-verified at a primary
# source - crates.io, the GitHub REST API, Google Cloud's own documentation, the Cargo Book -
# and this script ASSERTS those facts rather than leaving revision 6's prose to be believed.
#
# WHAT IT READS, AND WHY IT NEVER TOUCHES THE NETWORK. It reads only the reduced snapshots
# under `snapshots/r6/`, which ARE committed. `fetch-owner-reference-r6.sh` is the sibling
# fetcher that produced them; it is not a check and asserts nothing about this decision. Every
# retrieval it made is recorded in each snapshot's own `source`/`effective_url` field, and each
# was HTTP 200. Keeping the network out of THIS script is what makes it rerunnable offline,
# byte-identical on rerun, and reproducible from a clean `git archive HEAD` extraction after
# this decision is committed - the property R60 and revisions 2 through 5 of this item were
# each rejected for lacking.
#
# WHAT IT ASSERTS. Content, never an exit code alone. Section by section:
#
#   A. axum's published release list: the newest non-yanked version is 0.8.9, the registry's
#      max_version/max_stable_version/newest_version all read 0.8.9, and the set of published
#      versions at or above 0.9 is EMPTY. (Document row 1: "no 0.9/1.0 to worry about yet".)
#   B. Cargo's default version-requirement rule, quoted from the Cargo Book: a bare `"0.2.3"`
#      means `>=0.2.3, <0.3.0`, and leaving off the caret is equivalent to writing it. This is
#      what decides whether the document's `axum = "=0.8.9"` advice would change anything: a
#      bare `"0.8.9"` already excludes 0.9.
#   C. The axum-0.9 state as the repository actually records it: issue #3809 closed, its single
#      comment by a COLLABORATOR carrying the sentence the document paraphrases; release PR
#      #3745 CLOSED AND NOT MERGED while proposing `axum`: 0.8.9 -> 0.9.0 with breaking changes
#      named in `serve`, `Serve` and `WithGracefulShutdown`; and PR #3819, open in milestone
#      0.9, proposing to extract `axum::serve` into a separate crate.
#   D. axum-test, which the document ranks over `tower::ServiceExt::oneshot` at version 18: the
#      registry's newest non-yanked version under this item's own field rule, its newest stable
#      version, and the axum requirement each named release actually declares.
#   E. Google's Cloud Run container runtime contract: the 10-second SIGTERM-to-SIGKILL sentence
#      verbatim, for SERVICES, plus the neighbouring "within a few seconds" sentence that
#      belongs to JOBS - asserted together so the two cannot be conflated.
#   F. axum issue #3003: it exists, it is OPEN, and it says what the document says it says.
#   G. A DELIBERATE CONTROL that must FAIL, so that a check which cannot fail is visible as
#      such: the same absence test that passes for "no axum version >= 0.9" is applied to a
#      string the snapshot does demonstrably contain.
#
# This script decides nothing about the recommendation on its own: it establishes the facts on
# which revision 6 records agreement with, or a ground for differing from, the owner-supplied
# document. It is listed alongside `yanked-control-r5.sh` under `## Empirical check` as a
# further script rather than as a seventh check.
set -o pipefail
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="$HERE/snapshots/r6"
JQ="${JQ:-/opt/homebrew/bin/jq}"
GREP=/usr/bin/grep

rc=0

say() { printf '\n== %s ==\n' "$1"; }

# must <label> <expected> <actual>
must() {
  if [ "$2" = "$3" ]; then
    printf 'OK   %-56s %s\n' "$1" "$3"
  else
    printf 'FAIL %-56s expected=%s actual=%s\n' "$1" "$2" "$3"; rc=1
  fi
}

# has <label> <needle> <file>  — the needle must appear in the file
has() {
  if "$GREP" -qF -- "$2" "$3"; then
    printf 'OK   %-56s present\n' "$1"
  else
    printf 'FAIL %-56s absent: %s\n' "$1" "$2"; rc=1
  fi
}

echo "R69 revision 6 — owner-reference primary-source check"
echo "grep binary: /usr/bin/grep (the POSIX grep, invoked by absolute path; never a shell alias, never ugrep)"
echo "jq binary: $JQ"
echo "snapshot dir: <run>/review/evidence/snapshots/r6 (committed; written by fetch-owner-reference-r6.sh)"
echo "snapshots retrieved at: $(cat "$SNAP/RETRIEVED-AT.txt")"
echo "network: NOT used by this script; every assertion reads a committed snapshot"

for f in crates-axum-versions.json crates-axum-test.json gh-axum-issue-3809.json \
         gh-axum-issue-3003.json gh-axum-pr-3745.json gh-axum-pr-3819.json \
         gcp-cloudrun-container-contract.txt cargo-specifying-dependencies.txt; do
  [ -f "$SNAP/$f" ] && printf 'OK   %-56s present\n' "snapshot $f" \
    || { printf 'FAIL %-56s missing\n' "snapshot $f"; rc=1; }
done

# --------------------------------------------------------------------------- A
say "A. axum's published releases (document TL;DR and Key Finding 1; row 1)"
A="$SNAP/crates-axum-versions.json"
must "axum newest non-yanked num"          "0.8.9"  "$("$JQ" -r '.newest_non_yanked.num' "$A")"
must "axum newest non-yanked yanked flag"  "false"  "$("$JQ" -r '.newest_non_yanked.yanked' "$A")"
must "axum registry max_version"           "0.8.9"  "$("$JQ" -r '.max_version' "$A")"
must "axum registry max_stable_version"    "0.8.9"  "$("$JQ" -r '.max_stable_version' "$A")"
must "axum registry newest_version"        "0.8.9"  "$("$JQ" -r '.newest_version' "$A")"
must "axum published versions >= 0.9"      "0"      "$("$JQ" -r '.versions_0_9_or_later | length' "$A")"
must "axum published version count"        "94"     "$("$JQ" -r '.versions_total' "$A")"
must "axum newest non-yanked rust_version" "1.80"   "$("$JQ" -r '.newest_non_yanked.rust_version' "$A")"
echo "note: the decision's recommended pin 0.8.9 and its gate-2 figure 1.80 are unchanged by this check."

# --------------------------------------------------------------------------- B
say "B. Cargo's default version-requirement rule (row 1: caret vs an = pin)"
B="$SNAP/cargo-specifying-dependencies.txt"
has "cargo book: 0.2.3 := >=0.2.3, <0.3.0"        '0.2.3 := >=0.2.3, <0.3.0' "$B"
has "cargo book: caret is the default strategy"   'Caret requirements are the default version requirement strategy.' "$B"
has "cargo book: bare version == caret"           'Leaving off the caret is a simplified equivalent syntax to using caret requirements.' "$B"
has "cargo book: HTTP 200"                        'http_status: 200' "$B"
echo "consequence: a bare \"0.8.9\" is >=0.8.9, <0.9.0 and already cannot resolve to 0.9."

# --------------------------------------------------------------------------- C
say "C. the axum-0.9 state as tokio-rs/axum records it (row 1)"
C1="$SNAP/gh-axum-issue-3809.json"
must "axum#3809 state"                 "closed"        "$("$JQ" -r '.state' "$C1")"
must "axum#3809 is a pull request"     "false"         "$("$JQ" -r '.is_pull_request' "$C1")"
must "axum#3809 comment count"         "1"             "$("$JQ" -r '.comments | length' "$C1")"
must "axum#3809 commenter"             "mladedav"      "$("$JQ" -r '.comments[0].login' "$C1")"
must "axum#3809 commenter association" "COLLABORATOR"  "$("$JQ" -r '.comments[0].author_association' "$C1")"
has  "axum#3809 the no-timeline sentence"  "There isn't any set timeline." "$C1"
has  "axum#3809 its qualifier"             "We'd like to do it soon, but no promises" "$C1"

C2="$SNAP/gh-axum-pr-3745.json"
must "axum#3745 state"             "closed"           "$("$JQ" -r '.state' "$C2")"
must "axum#3745 merged"            "false"            "$("$JQ" -r '.merged' "$C2")"
must "axum#3745 merged_at"         "null"             "$("$JQ" -r '.merged_at' "$C2")"
must "axum#3745 proposed bump"     "0.8.9 -> 0.9.0"   "$("$JQ" -r '.proposed_axum_bump' "$C2")"
has  "axum#3745 breaks fn serve"        'function serve (3 -> 4 generic types)' "$C2"
has  "axum#3745 breaks trait Serve"     'trait Serve (3 -> 4 required generic types)' "$C2"
has  "axum#3745 breaks WithGracefulShutdown" 'trait WithGracefulShutdown (4 -> 5 required generic types)' "$C2"

C3="$SNAP/gh-axum-pr-3819.json"
must "axum#3819 state"      "open"  "$("$JQ" -r '.state' "$C3")"
must "axum#3819 milestone"  "0.9"   "$("$JQ" -r '.milestone' "$C3")"
has  "axum#3819 moves axum::serve" 'Extract `axum::serve` and friends into new `axum-serve` crate' "$C3"
echo "consequence: the unreleased 0.9 line's recorded breaking changes land on axum::serve and"
echo "             WithGracefulShutdown - the exact API this item's F338 mechanism uses."

# --------------------------------------------------------------------------- D
say "D. axum-test, the document's C12 pick (row 5)"
D="$SNAP/crates-axum-test.json"
must "axum-test newest non-yanked (this item's field rule)" "22.0.0-rc.1" "$("$JQ" -r '.newest_non_yanked.num' "$D")"
must "axum-test newest STABLE version"                      "21.1.0"      "$("$JQ" -r '.newest_stable.num' "$D")"
must "axum-test registry max_stable_version"                "21.1.0"      "$("$JQ" -r '.max_stable_version' "$D")"
must "axum-test 18.0.0 requires axum"  "^0.8.4"  "$("$JQ" -r '.axum_requirement["18.0.0"]' "$D")"
must "axum-test 18.3.0 requires axum"  "^0.8.7"  "$("$JQ" -r '.axum_requirement["18.3.0"]' "$D")"
must "axum-test 18.7.0 requires axum"  "^0.8.8"  "$("$JQ" -r '.axum_requirement["18.7.0"]' "$D")"
must "axum-test 21.1.0 requires axum"  "^0.8.9"  "$("$JQ" -r '.axum_requirement["21.1.0"]' "$D")"
must "axum-test 21.1.0 declared rust-version" "1.89" "$("$JQ" -r '.rust_version["21.1.0"]' "$D")"
echo "consequence: the document's 'axum-test 18 (requires axum >= 0.8.7)' is true only from"
echo "             18.3.0 onward - 18.0.0 declares ^0.8.4 - and the 18 line is three majors"
echo "             behind the registry's current 21.1.0, which declares ^0.8.9."

# --------------------------------------------------------------------------- E
say "E. Google's Cloud Run container runtime contract (row 4)"
E="$SNAP/gcp-cloudrun-container-contract.txt"
has "cloud run: HTTP 200"        'http_status: 200' "$E"
has "cloud run: effective URL"   'effective_url: https://docs.cloud.google.com/run/docs/container-contract' "$E"
has "cloud run: SERVICES 10-second sentence, verbatim" \
    'Before shutting down an instance, Cloud Run sends a SIGTERM signal to all the containers in an instance, indicating the start of a 10 second period before the actual shutdown occurs, at which point Cloud Run sends a SIGKILL signal.' "$E"
has "cloud run: JOBS sentence, which is NOT the services one" \
    "If the instance doesn't shut down on its own within a few seconds after receiving SIGTERM" "$E"
echo "consequence: on Cloud Run a drain deadline must be strictly under 10 s measured FROM THE"
echo "             SIGTERM, which is a datum for R77's default and is meaningful only under this"
echo "             item's clock-starts-at-the-signal rule."

# --------------------------------------------------------------------------- F
say "F. axum issue #3003, the WebSocket graceful-shutdown hazard (row 4)"
F="$SNAP/gh-axum-issue-3003.json"
must "axum#3003 state"                    "open"   "$("$JQ" -r '.state' "$F")"
must "axum#3003 is a pull request"        "false"  "$("$JQ" -r '.is_pull_request' "$F")"
must "axum#3003 reported against version" "axum 0.7.4" "$("$JQ" -r '.reported_against_version' "$F")"
has  "axum#3003 title"  'Graceful Shutdown ignores Websocket handler task' "$F"
has  "axum#3003 the claim the document cites" \
     'The task spawned in `ws.on_upgrade` is not connected to the graceful shutdown future at all.' "$F"
echo "consequence: the hazard is real and unfixed; it belongs to a later WebSocket layer, for"
echo "             which this programme has no P02 item. Nothing in this decision changes."

# --------------------------------------------------------------------------- G
say "G. control — the same absence test applied to a string that IS present"
ctl_expected_absent="0.8.9"
ctl_hits=$("$JQ" -r --arg n "$ctl_expected_absent" \
  '[.line_0_8_nums[] | select(. == $n)] | length' "$A")
if [ "$ctl_hits" = "0" ]; then
  printf 'FAIL %-56s control did not fail; the absence test cannot fail\n' "control"
  rc=1
else
  printf 'OK   %-56s control correctly reports %s present (%s hit)\n' \
    "control (expected to report a present string)" "$ctl_expected_absent" "$ctl_hits"
fi
echo "reading: section A asserts the >= 0.9 set is empty. This control applies the same"
echo "         membership test to 0.8.9, which the same snapshot field does contain, so the"
echo "         emptiness assertion above is capable of failing."

printf '\nowner-reference-check-r6 rc=%s\n' "$rc"
exit "$rc"
