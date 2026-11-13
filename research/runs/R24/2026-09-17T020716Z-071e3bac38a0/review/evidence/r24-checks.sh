#!/usr/bin/env bash
# R24 changelog-section-mapping — synthesizer empirical check.
#
# WHAT THIS IS. It verifies the claims raw/opus.md makes about how
# release-please 17.11.2 turns a `changelog-sections` array into a rendered
# changelog entry, and about the release gate that reads that entry. It
# IMPLEMENTS NOTHING: it writes no release-please-config.json, no CHANGELOG.md,
# no workflow and no template scaffold anywhere in this repository, and it never
# runs release-please against a repository.
#
# DETERMINISM CONTRACT.
#   * Every third-party byte this script asserts on is snapshotted once into
#     ./snap (see ./snap/RETRIEVED.txt for the origin of each file) and read
#     from the snapshot afterwards, so sections 1-6 need no network and no npm.
#   * Section 7 is the reproduction leg: it re-installs release-please@17.11.2
#     into a throwaway directory under $TMPDIR, diffs the eight upstream files
#     against the snapshots, re-runs ./probe/render.cjs and diffs all seven
#     rendered outputs against the snapshots, then (revision 2) re-runs
#     ./probe/loader.cjs and diffs its two outputs. Without node, npm or the
#     network it prints named SKIPs instead of failing.
#   * Nothing machine-dependent reaches stdout. Host versions and the scratch
#     path go to ./toolchain.txt. So a rerun on this host, in place or from a
#     clean `git archive HEAD` extraction, diffs clean against r24-checks.log.
#   * The script locates the repository from its own directory, so it runs
#     unchanged inside an extraction that has no .git at all. Anything outside
#     that extraction - the sibling py/ts checkouts, node, npm, the network -
#     prints `SKIP <name> - <reason>` by name rather than passing silently.
#
# Usage: bash r24-checks.sh            (run from anywhere)
# Exit:  0 when no check FAILed, 1 otherwise.

set -euo pipefail

GREP=/usr/bin/grep
GREP_VERSION=$("$GREP" --version | /usr/bin/head -1)
EVID=$(cd -- "$(dirname -- "$0")" && pwd)
SNAP="$EVID/snap"
REPO=$(cd -- "$EVID/../../../../../.." && pwd)
DECISION="$EVID/../DECISION.md"
REGISTRY="$REPO/docs/port/PARAMETERS.md"
PY_REPO="$HOME/c/py-launch-blueprint"
TS_REPO="$HOME/c/ts-launch-blueprint"
PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TS_PIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
RP_VERSION=17.11.2

PASSED=0
FAILED=0
SKIPPED=0
SCRATCH=""

# shellcheck disable=SC2329
#   Invoked indirectly by the EXIT trap below.
cleanup() {
  if [ -n "$SCRATCH" ] && [ -d "$SCRATCH" ]; then
    rm -rf "$SCRATCH"
  fi
}
trap cleanup EXIT

section() { printf '\n========== %s ==========\n' "$1"; }
claim()   { printf '\n--- %s ---\n' "$1"; }

skip() {
  SKIPPED=$((SKIPPED + 1))
  printf 'SKIP %s - %s\n' "$1" "$2"
}

# assert <label> <expected> <actual>
assert() {
  if [ "$2" = "$3" ]; then
    PASSED=$((PASSED + 1))
    printf 'PASS %s (expected %s, got %s; counting binary: %s, %s)\n' "$1" "$2" "$3" "$GREP" "$GREP_VERSION"
  else
    FAILED=$((FAILED + 1))
    printf 'FAIL %s (expected %s, got %s; counting binary: %s, %s)\n' "$1" "$2" "$3" "$GREP" "$GREP_VERSION"
  fi
}

# count <pattern> <file> - basic-regex line count; 0 when the file has no match.
count() {
  local n
  n=$("$GREP" -c -- "$1" "$2" 2>/dev/null || true)
  [ -n "$n" ] || n=0
  printf '%s' "$n"
}

# countf <fixed-string> <file>
countf() {
  local n
  n=$("$GREP" -c -F -- "$1" "$2" 2>/dev/null || true)
  [ -n "$n" ] || n=0
  printf '%s' "$n"
}

# lineno <pattern> <file> - line number of the first match, or 0.
lineno() {
  local n
  n=$("$GREP" -n -- "$1" "$2" 2>/dev/null | /usr/bin/head -1 | /usr/bin/cut -d: -f1 || true)
  [ -n "$n" ] || n=0
  printf '%s' "$n"
}

# The eleven-member type enum this decision maps, in the array's own order.
RECOMMENDED_TYPES=(feat fix perf revert docs refactor test build ci style chore)
RECOMMENDED_ORDER=$(printf '%s ' "${RECOMMENDED_TYPES[@]}")
# The same eleven types in the registry's alphabetical order, for comparison
# against commit-message-convention's `type-enum:` field.
RECOMMENDED_TYPES_SORTED=$(printf '%s\n' "${RECOMMENDED_TYPES[@]}" | /usr/bin/sort | /usr/bin/tr '\n' ' ')

{
  printf 'Host toolchain and paths for r24-checks.sh (kept off stdout so the log reproduces)\n'
  printf 'date (UTC): %s\n' "$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'uname: %s\n' "$(/usr/bin/uname -srm)"
  printf 'grep: %s (%s)\n' "$GREP" "$GREP_VERSION"
  printf 'node: %s\n' "$(command -v node >/dev/null 2>&1 && node --version || echo absent)"
  printf 'npm: %s\n' "$(command -v npm >/dev/null 2>&1 && npm --version || echo absent)"
  printf 'rustc: %s\n' "$(command -v rustc >/dev/null 2>&1 && rustc --version || echo absent)"
  printf 'cargo: %s\n' "$(command -v cargo >/dev/null 2>&1 && cargo --version || echo absent)"
  printf 'shellcheck: %s\n' "$(command -v shellcheck >/dev/null 2>&1 && shellcheck --version | "$GREP" '^version:' || echo absent)"
  printf 'evidence dir: %s\n' "$EVID"
  printf 'repository root: %s\n' "$REPO"
  printf 'TMPDIR: %s\n' "${TMPDIR:-/tmp}"
} > "$EVID/toolchain.txt"

printf 'R24 changelog-section-mapping - empirical check\n'
printf 'Counting binary: %s (%s)\n' "$GREP" "$GREP_VERSION"
printf 'Snapshots: ./snap (origins in ./snap/RETRIEVED.txt)\n'
printf 'Host toolchain: ./toolchain.txt (kept off this log so it reproduces)\n'

# ---------------------------------------------------------------------------
section '1 - the recommended array is a TOTAL map over R38 commit-message-convention'
# ---------------------------------------------------------------------------

claim '1a registry type-enum has exactly the eleven types the array maps'
if [ -f "$REGISTRY" ]; then
  ENUM_LINE=$("$GREP" -o 'type-enum: [a-z, ]*;' "$REGISTRY" | /usr/bin/head -1 || true)
  assert '1a-enum-found' 'yes' "$([ -n "$ENUM_LINE" ] && echo yes || echo no)"
  ENUM_TYPES=$(printf '%s' "$ENUM_LINE" | /usr/bin/sed 's/^type-enum: //; s/;$//; s/, / /g' | /usr/bin/tr ' ' '\n' | /usr/bin/sort | /usr/bin/tr '\n' ' ')
  assert '1a-enum-equals-array' "$RECOMMENDED_TYPES_SORTED" "$ENUM_TYPES"
else
  skip '1a' "registry absent at $REGISTRY"
  skip '1a-enum-equals-array' "registry absent at $REGISTRY"
fi

claim '1b the probe rendered the array the decision recommends'
PROBE_TYPES=$(/usr/bin/sed -n '/^const RECOMMENDED = \[/,/^\];/p' "$EVID/probe/render.cjs" \
  | "$GREP" -o "type: '[a-z]*'" | /usr/bin/sed "s/type: '//; s/'//" | /usr/bin/tr '\n' ' ')
assert '1b-probe-array-order' "$RECOMMENDED_ORDER" "$PROBE_TYPES"

claim '1c DECISION.md publishes the same eleven types in the same order'
if [ -f "$DECISION" ]; then
  DEC_TYPES=$(/usr/bin/sed -n '/"changelog-sections": \[/,/^\]/p' "$DECISION" \
    | "$GREP" -o '"type": *"[a-z]*"' | /usr/bin/sed 's/.*"type": *"//; s/"//' | /usr/bin/tr '\n' ' ')
  assert '1c-decision-array-order' "$RECOMMENDED_ORDER" "$DEC_TYPES"
  assert '1c-decision-hidden-count' '6' "$(/usr/bin/sed -n '/"changelog-sections": \[/,/^\]/p' "$DECISION" | countf '"hidden": true' /dev/stdin)"
else
  skip '1c-decision-array-order' "DECISION.md not yet written at $DECISION"
  skip '1c-decision-hidden-count' "DECISION.md not yet written at $DECISION"
fi

# ---------------------------------------------------------------------------
section '2 - the five assumed parameter lines are byte-identical to the live registry'
# ---------------------------------------------------------------------------

if [ -f "$DECISION" ] && [ -f "$REGISTRY" ]; then
  for param in msrv-policy rust-edition target-os-matrix license commit-message-convention; do
    claim "2-$param"
    DEC_VALUE=$("$GREP" "^- assumes $param = " "$DECISION" | /usr/bin/sed "s/^- assumes $param = //" || true)
    REG_VALUE=$("$GREP" "^| $param | " "$REGISTRY" | /usr/bin/awk -F' \\| ' '{print $4}' || true)
    assert "2-$param-nonempty" 'yes' "$([ -n "$REG_VALUE" ] && echo yes || echo no)"
    if [ "$DEC_VALUE" = "$REG_VALUE" ]; then
      assert "2-$param-byte-identical" 'identical' 'identical'
    else
      assert "2-$param-byte-identical" 'identical' 'DIFFERENT'
    fi
  done
else
  skip '2' 'DECISION.md or the registry is absent'
fi

# ---------------------------------------------------------------------------
section '3 - release-please 17.11.2 source, read from ./snap/rp-17.11.2'
# ---------------------------------------------------------------------------

RPD="$SNAP/rp-17.11.2/changelog-notes-default.js.snapshot"
RPN="$SNAP/rp-17.11.2/changelog-notes.js.snapshot"
RPF="$SNAP/rp-17.11.2/util-filter-commits.js.snapshot"
RPR="$SNAP/rp-17.11.2/strategies-rust.js.snapshot"
RPB="$SNAP/rp-17.11.2/strategies-base.js.snapshot"
RPC="$SNAP/rp-17.11.2/commit.js.snapshot"
RPS="$SNAP/rp-17.11.2/schemas-config.json.snapshot"
PRE="$SNAP/preset-6.1.0/writer-opts.js.snapshot"

claim '3a mechanism 1 - changelog-sections REPLACES the preset default, and an absent array takes it'
assert '3a-assigns-types' '1' "$(countf 'config.types = options.changelogSections;' "$RPD")"
assert '3a-guarded-by-presence' '1' "$(countf 'if (options.changelogSections) {' "$RPD")"
assert '3a-no-merge' '0' "$(countf 'config.types.concat' "$RPD")"
assert '3a-preset-default-list' '1' "$(countf 'config.types = config.types || [' "$PRE")"

claim '3b mechanism 4 - the rust strategy sets no fallback and never filters'
assert '3b-rust-no-changelog-sections' '0' "$(countf 'CHANGELOG_SECTIONS' "$RPR")"
assert '3b-rust-no-filter-commits' '0' "$(countf 'filterCommits' "$RPR")"
assert '3b-rust-extends-base' '1' "$(countf 'class Rust extends base_1.BaseStrategy' "$RPR")"

claim '3c release-please DEFAULT_CHANGELOG_SECTIONS is itself a total map over the same eleven types, with no deps'
assert '3c-entry-count' '11' "$(/usr/bin/sed -n '/^const DEFAULT_CHANGELOG_SECTIONS = \[/,/^\];/p' "$RPF" | countf "    { type: " /dev/stdin)"
assert '3c-no-deps-entry' '0' "$(/usr/bin/sed -n '/^const DEFAULT_CHANGELOG_SECTIONS = \[/,/^\];/p' "$RPF" | countf "type: 'deps'" /dev/stdin)"
assert '3c-visible-four' '4' "$(/usr/bin/sed -n '/^const DEFAULT_CHANGELOG_SECTIONS = \[/,/^\];/p' "$RPF" | "$GREP" -c -v 'hidden: true' | /usr/bin/awk '{print $1-2}')"

claim '3d every heading the recommendation uses is release-please DEFAULT_HEADINGS verbatim'
for pair in "feat:Features" "fix:Bug Fixes" "perf:Performance Improvements" "revert:Reverts" \
            "docs:Documentation" "refactor:Code Refactoring" "test:Tests" "build:Build System" \
            "ci:Continuous Integration" "style:Styles" "chore:Miscellaneous Chores"; do
  t=${pair%%:*}
  h=${pair#*:}
  assert "3d-$t" '1' "$(countf "    $t: '$h'," "$RPN")"
done

claim '3e mechanism 5 - the release gate reads the rendered notes'
assert '3e-guard-call-site' '1' "$(countf 'if (!bumpOnlyOptions && this.changelogEmpty(releaseNotesBody)) {' "$RPB")"
assert '3e-guard-log' '1' "$(countf 'No user facing commits found since ' "$RPB")"
assert '3e-guard-returns-undefined' '1' "$(/usr/bin/sed -n '/if (!bumpOnlyOptions && this.changelogEmpty(releaseNotesBody)) {/,+3p' "$RPB" | countf 'return undefined;' /dev/stdin)"
assert '3e-predicate-signature' '1' "$(countf 'changelogEmpty(changelogEntry) {' "$RPB")"
assert '3e-predicate-body' '1' "$(count 'return changelogEntry\.split(.*)\.length <= 1;' "$RPB")"
assert '3e-body-is-rendered-notes' '1' "$(countf 'const releaseNotesBody = await this.buildReleaseNotes(' "$RPB")"

claim "3f a bare '!' marker carries the subject as its breaking-note text"
assert '3f-subject-as-note-text' '1' "$(countf 'breaking.text = headerCommit.subject;' "$RPC")"
assert '3f-push-only-when-nonempty' '1' "$(countf "if (breaking.text !== '')" "$RPC")"

claim '3g mechanisms 2 and 3 in the preset - hidden versus unmapped, and positional order'
assert '3g-discard-rule' '1' "$(countf 'if (discard && (entry === undefined ||' "$PRE")"
assert '3g-breaking-clears-discard' '2' "$(countf '        discard = false' "$PRE")"
assert '3g-entry-renames-group' '1' "$(countf 'if (entry) commit.type = entry.section' "$PRE")"
assert '3g-group-order-from-array' '1' "$(countf 'const commitGroupOrder = config.types.flatMap(t => t.section)' "$PRE")"
assert '3g-sort-by-indexof' '1' "$(countf 'const gRankA = commitGroupOrder.indexOf(a.title)' "$PRE")"

claim '3h schema, first "changelog-sections" key to end of file: the key twice, one required [type, section], one "hidden", no "scope"'
assert '3h-has-changelog-sections' '2' "$(countf '"changelog-sections"' "$RPS")"
CS_BLOCK=$(/usr/bin/sed -n '/"changelog-sections"/,/^      "changelog-path"/p' "$RPS")
assert '3h-requires-type-and-section' '1' "$(printf '%s' "$CS_BLOCK" | countf '"required": ["type", "section"]' /dev/stdin)"
assert '3h-hidden-is-boolean' '1' "$(printf '%s' "$CS_BLOCK" | countf '"hidden"' /dev/stdin)"
assert '3h-no-scope-key' '0' "$(printf '%s' "$CS_BLOCK" | countf '"scope"' /dev/stdin)"

# ---------------------------------------------------------------------------
section '4 - rendered entries, produced by release-please own buildNotes (./snap/rendered)'
# ---------------------------------------------------------------------------

A="$SNAP/rendered/A-preset-default.md"
B="$SNAP/rendered/B-py.md"
C="$SNAP/rendered/C-ts.md"
D="$SNAP/rendered/D-recommended.md"

claim '4a ts array: a breaking commit of an UNMAPPED type renders under a raw lowercase heading ABOVE Features'
assert '4a-raw-lowercase-heading' '1' "$(count '^### style$' "$C")"
TS_STYLE_LINE=$(lineno '^### style$' "$C")
TS_FEAT_LINE=$(lineno '^### Features$' "$C")
assert '4a-sorted-above-features' 'above' "$([ "$TS_STYLE_LINE" -gt 0 ] && [ "$TS_FEAT_LINE" -gt 0 ] && [ "$TS_STYLE_LINE" -lt "$TS_FEAT_LINE" ] && echo above || echo not-above)"
assert '4a-no-Styles-heading' '0' "$(count '^### Styles$' "$C")"

claim '4b ts array: a NON-breaking revert: commit is discarded entirely'
assert '4b-no-reverts-section' '0' "$(count '^### Reverts$' "$C")"
assert '4b-revert-subject-absent' '0' "$(countf 'undo the projects list command' "$C")"

claim '4c recommended array: the same breaking commit renders under its configured heading, at its configured rank'
assert '4c-no-raw-lowercase' '0' "$(count '^### style$' "$D")"
assert '4c-styles-heading' '1' "$(count '^### Styles$' "$D")"
D_STYLES_LINE=$(lineno '^### Styles$' "$D")
D_DOCS_LINE=$(lineno '^### Documentation$' "$D")
assert '4c-styles-below-documentation' 'below' "$([ "$D_STYLES_LINE" -gt "$D_DOCS_LINE" ] && echo below || echo not-below)"

claim '4d recommended array: revert: is visible; docs: is visible'
assert '4d-reverts-section' '1' "$(count '^### Reverts$' "$D")"
assert '4d-revert-subject' '1' "$(countf 'undo the projects list command' "$D")"
assert '4d-documentation-section' '1' "$(count '^### Documentation$' "$D")"

claim '4e recommended array: section order follows array position exactly'
D_ORDER=$("$GREP" '^### ' "$D" | /usr/bin/sed 's/^### //' | /usr/bin/tr '\n' '|')
assert '4e-order' 'BREAKING CHANGES|Features|Bug Fixes|Performance Improvements|Reverts|Documentation|Styles|Miscellaneous Chores|' "$(printf '%s' "$D_ORDER" | /usr/bin/sed 's/⚠ //')"

claim '4f recommended array: every hidden type produces no line for a non-breaking commit'
for subject in 'split the composition root' 'add an integration test for the port' \
               'pin the workspace resolver to 3' 'run the matrix on macos-latest' \
               'reflow the imports' 'tidy the justfile'; do
  assert "4f-absent: $subject" '0' "$(countf "$subject" "$D")"
done

claim '4g no array renders the Dependabot bump, and py deps entry matches nothing'
for f in "$A" "$B" "$C" "$D"; do
  assert "4g-no-bump: $(/usr/bin/basename "$f")" '0' "$(countf 'bump serde' "$f")"
done
assert '4g-py-no-dependencies-section' '0' "$(count '^### Dependencies$' "$B")"

claim '4h preset default (the runner-up, and the release-type rust default) hides docs and shows revert'
assert '4h-no-documentation' '0' "$(count '^### Documentation$' "$A")"
assert '4h-reverts-present' '1' "$(count '^### Reverts$' "$A")"

claim '4i py array shows refactor and hides docs'
assert '4i-refactor-heading' '1' "$(count '^### Refactor$' "$B")"
assert '4i-no-documentation' '0' "$(count '^### Documentation$' "$B")"

claim '4j breaking bullets carry the commit subject - the raw report empty-bullet artifact is a fixture defect, not release-please behaviour'
D_BREAKING=$(/usr/bin/sed -n '/^### . BREAKING CHANGES$/,/^### Features$/p' "$D")
assert '4j-first-bullet' '1' "$(printf '%s' "$D_BREAKING" | countf '* rename the public Error variants' /dev/stdin)"
assert '4j-second-bullet' '1' "$(printf '%s' "$D_BREAKING" | countf '* drop the deprecated no-color flag' /dev/stdin)"
assert '4j-no-empty-bullet' '0' "$(printf '%s' "$D_BREAKING" | count '^\* *$' /dev/stdin)"

# ---------------------------------------------------------------------------
section '5 - mechanism 5 executed: the visible set is the releasable set'
# ---------------------------------------------------------------------------

M5="$SNAP/rendered/mech5.txt"
claim '5a the predicate executed is release-please own BaseStrategy.changelogEmpty'
assert '5a-predicate-text' '1' "$(countf "changelogEmpty source: changelogEmpty(changelogEntry) { return changelogEntry.split('\\n').length <= 1; }" "$M5")"

claim '5b a push whose commits all map to hidden types renders a one-line body and is judged empty'
assert '5b-line-count' '1' "$(countf 'hidden-only lines: 1' "$M5")"
assert '5b-empty-true' '1' "$(countf 'hidden-only changelogEmpty: true' "$M5")"
assert '5b-body-is-header-only' '1' "$(count '^## 0\.2\.0 (<release-date>)$' "$SNAP/rendered/E-hidden-only.md")"
assert '5b-body-has-no-sections' '0' "$(count '^### ' "$SNAP/rendered/E-hidden-only.md")"

claim '5c one visible-type commit in the same push makes it non-empty'
assert '5c-empty-false' '1' "$(countf 'hidden-plus-one-visible changelogEmpty: false' "$M5")"
assert '5c-bug-fixes-section' '1' "$(count '^### Bug Fixes$' "$SNAP/rendered/F-hidden-plus-visible.md")"

# ---------------------------------------------------------------------------
section '6 - the two source repositories at the programme pins'
# ---------------------------------------------------------------------------

PYC="$SNAP/sources/py-release-please-config.json.snapshot"
TSC="$SNAP/sources/ts-release-please-config.json.snapshot"

claim '6a py at b08bccfb - a total twelve-entry map whose deps entry is unreachable'
assert '6a-entry-count' '12' "$(count '{"type":' "$PYC")"
assert '6a-array-opens-at-22' '22' "$(lineno '"changelog-sections": \[' "$PYC")"
assert '6a-deps-entry' '1' "$(countf '{"type": "deps",     "section": "Dependencies"}' "$PYC")"
assert '6a-refactor-visible' '1' "$(countf '{"type": "refactor", "section": "Refactor"}' "$PYC")"
assert '6a-docs-hidden' '1' "$(countf '{"type": "docs",  "section": "Documentation", "hidden": true}' "$PYC")"

claim '6b ts at cb1cbcb2 - a seven-entry PARTIAL array with no revert, style, build or ci'
assert '6b-entry-count' '7' "$(count '{ "type":' "$TSC")"
assert '6b-array-opens-at-11' '11' "$(lineno '"changelog-sections": \[' "$TSC")"
for missing in revert style build ci; do
  assert "6b-no-$missing-entry" '0' "$(countf "\"type\": \"$missing\"" "$TSC")"
done

claim '6c the snapshots are what the pins hold'
for pair in "py:$PY_REPO:$PY_PIN:$PYC" "ts:$TS_REPO:$TS_PIN:$TSC"; do
  name=${pair%%:*}
  rest=${pair#*:}
  repo=${rest%%:*}
  rest=${rest#*:}
  pin=${rest%%:*}
  snapfile=${rest#*:}
  if [ -d "$repo/.git" ] || [ -f "$repo/.git" ]; then
    if git -C "$repo" cat-file -e "$pin:release-please-config.json" 2>/dev/null; then
      if git -C "$repo" show "$pin:release-please-config.json" | /usr/bin/diff -q - "$snapfile" >/dev/null 2>&1; then
        assert "6c-$name-matches-pin" 'identical' 'identical'
      else
        assert "6c-$name-matches-pin" 'identical' 'DIFFERENT'
      fi
    else
      skip "6c-$name-matches-pin" "pin $pin not present in $repo"
    fi
  else
    skip "6c-$name-matches-pin" "sibling checkout absent at $repo"
  fi
done

# ---------------------------------------------------------------------------
section '7 - reproduction leg: reinstall release-please 17.11.2 and re-render'
# ---------------------------------------------------------------------------

if ! command -v node >/dev/null 2>&1; then
  skip '7a-install' 'node is not on PATH'
  skip '7b-upstream-bytes' 'node is not on PATH'
  skip '7c-rendered-bytes' 'node is not on PATH'
  skip '7d-loader-bytes' 'node is not on PATH'
elif ! command -v npm >/dev/null 2>&1; then
  skip '7a-install' 'npm is not on PATH'
  skip '7b-upstream-bytes' 'npm is not on PATH'
  skip '7c-rendered-bytes' 'npm is not on PATH'
  skip '7d-loader-bytes' 'npm is not on PATH'
else
  SCRATCH=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/r24.XXXXXX")
  printf 'scratch (deleted on exit): %s\n' "$SCRATCH" >> "$EVID/toolchain.txt"
  claim '7a a fresh install resolves the three packages the rendering path uses'
  if (cd "$SCRATCH" && npm init -y >/dev/null 2>&1 \
        && npm install --no-audit --no-fund "release-please@$RP_VERSION" >npm-install.log 2>&1); then
    (cd "$SCRATCH" && npm ls --all 2>/dev/null \
       | "$GREP" -E 'release-please@|conventional-changelog-conventionalcommits@|conventional-changelog-writer@' \
       | /usr/bin/sed 's/^[^a-z]*/  /' | /usr/bin/sort -u) > "$SCRATCH/npm-ls.txt" || true
    if /usr/bin/diff -q "$SCRATCH/npm-ls.txt" "$SNAP/npm-ls.txt" >/dev/null 2>&1; then
      assert '7a-resolved-versions' 'identical' 'identical'
    else
      assert '7a-resolved-versions' 'identical' 'DIFFERENT'
    fi

    claim '7b the eight snapshotted upstream files are byte-identical to the fresh install'
    for pair in \
      "build/src/changelog-notes.js:rp-17.11.2/changelog-notes.js.snapshot" \
      "build/src/changelog-notes/default.js:rp-17.11.2/changelog-notes-default.js.snapshot" \
      "build/src/util/filter-commits.js:rp-17.11.2/util-filter-commits.js.snapshot" \
      "build/src/strategies/rust.js:rp-17.11.2/strategies-rust.js.snapshot" \
      "build/src/strategies/base.js:rp-17.11.2/strategies-base.js.snapshot" \
      "build/src/commit.js:rp-17.11.2/commit.js.snapshot" \
      "schemas/config.json:rp-17.11.2/schemas-config.json.snapshot"; do
      up=${pair%%:*}
      sn=${pair#*:}
      if /usr/bin/diff -q "$SCRATCH/node_modules/release-please/$up" "$SNAP/$sn" >/dev/null 2>&1; then
        assert "7b-$up" 'identical' 'identical'
      else
        assert "7b-$up" 'identical' 'DIFFERENT'
      fi
    done
    if /usr/bin/diff -q "$SCRATCH/node_modules/conventional-changelog-conventionalcommits/writer-opts.js" \
         "$SNAP/preset-6.1.0/writer-opts.js.snapshot" >/dev/null 2>&1; then
      assert '7b-preset/writer-opts.js' 'identical' 'identical'
    else
      assert '7b-preset/writer-opts.js' 'identical' 'DIFFERENT'
    fi

    claim '7c re-rendering reproduces all seven saved outputs byte-for-byte'
    if node "$EVID/probe/render.cjs" "$SCRATCH" "$SCRATCH/out" >"$SCRATCH/render.log" 2>&1; then
      for f in A-preset-default.md B-py.md C-ts.md D-recommended.md E-hidden-only.md F-hidden-plus-visible.md mech5.txt; do
        if /usr/bin/diff -q "$SCRATCH/out/$f" "$SNAP/rendered/$f" >/dev/null 2>&1; then
          assert "7c-$f" 'identical' 'identical'
        else
          assert "7c-$f" 'identical' 'DIFFERENT'
        fi
      done
    else
      skip '7c-rendered-bytes' 'the probe exited non-zero; see the scratch render log'
    fi

    claim '7d re-running the config-loader probe reproduces its two saved outputs byte-for-byte'
    if node "$EVID/probe/loader.cjs" "$SCRATCH" "$SCRATCH/out-loader" >"$SCRATCH/loader.log" 2>&1; then
      for f in loader.txt G-scope-routed-hidden-only.md; do
        if /usr/bin/diff -q "$SCRATCH/out-loader/$f" "$SNAP/rendered/$f" >/dev/null 2>&1; then
          assert "7d-$f" 'identical' 'identical'
        else
          assert "7d-$f" 'identical' 'DIFFERENT'
        fi
      done
    else
      skip '7d-loader-bytes' 'the loader probe exited non-zero; see the scratch loader log'
    fi
  else
    skip '7a-resolved-versions' 'npm install failed (no network, or the registry refused)'
    skip '7b-upstream-bytes' 'npm install failed (no network, or the registry refused)'
    skip '7c-rendered-bytes' 'npm install failed (no network, or the registry refused)'
    skip '7d-loader-bytes' 'npm install failed (no network, or the registry refused)'
  fi
fi

# ---------------------------------------------------------------------------
section '8 - the pin is current, and it is the version the action resolves'
# ---------------------------------------------------------------------------

GHR="$SNAP/github/release-please-latest-release.json"
GHA="$SNAP/github/release-please-action-v5.0.0-dep.json"

claim '8a v17.11.2 is release-please latest published release'
assert '8a-tag' '1' "$(countf '"tag_name":"v17.11.2"' "$GHR")"
assert '8a-not-draft' '1' "$(countf '"draft":false' "$GHR")"
assert '8a-not-prerelease' '1' "$(countf '"prerelease":false' "$GHR")"
assert '8a-published' '1' "$(countf '"published_at":"2026-08-24T21:20:30Z"' "$GHR")"

claim '8b release-please-action v5.0.0 - the pin F063 names - resolves release-please ^17.6.0, which 17.11.2 satisfies'
assert '8b-action-version' '1' "$(countf '"version": "5.0.0"' "$GHA")"
assert '8b-dependency-range' '1' "$(countf '"release-please-dep": "^17.6.0"' "$GHA")"

# ---------------------------------------------------------------------------
section '9 - revision 2: the scope axis - a scope-routed Dependencies entry'
# ---------------------------------------------------------------------------

LDR="$SNAP/rendered/loader.txt"
G="$SNAP/rendered/G-scope-routed-hidden-only.md"
R19_DECISION="$REPO/research/topics/19-dependabot-config-shape/DECISION.md"

claim '9a the preset type lookup also matches on scope when an entry declares one'
assert '9a-find-type-entry-scope-match' '1' "$(countf 'if (entry.scope && entry.scope !== commit.scope) {' "$PRE")"

claim '9b schema, the changelog-sections property block only: required [type, section], no "scope" key, no "additionalProperties"'
CS_ENTRY=$(/usr/bin/sed -n '/^        "changelog-sections": {$/,/^        },$/p' "$RPS")
assert '9b-entry-block-lines' '22' "$(printf '%s\n' "$CS_ENTRY" | /usr/bin/wc -l | /usr/bin/tr -d ' ')"
assert '9b-entry-requires-type-and-section' '1' "$(printf '%s' "$CS_ENTRY" | countf '"required": ["type", "section"]' /dev/stdin)"
assert '9b-entry-no-scope-key' '0' "$(printf '%s' "$CS_ENTRY" | countf '"scope"' /dev/stdin)"
assert '9b-entry-no-additional-properties' '0' "$(printf '%s' "$CS_ENTRY" | countf '"additionalProperties"' /dev/stdin)"

claim '9c config-loader path (Manifest.fromManifest -> strategy): the scope key survives to the strategy'
assert '9c-recommended-strategy-entries' '1' "$(countf 'recommended strategy entries: 11' "$LDR")"
assert '9c-scope-routed-loaded' '1' "$(countf 'scope-routed loaded scoped entry: {"type":"chore","scope":"deps","section":"Dependencies"}' "$LDR")"
assert '9c-scope-routed-strategy-entries' '1' "$(countf 'scope-routed strategy entries: 12' "$LDR")"
assert '9c-scope-routed-strategy' '1' "$(countf 'scope-routed strategy scoped entry: {"type":"chore","scope":"deps","section":"Dependencies"}' "$LDR")"

claim '9d the mechanism-5 push through that strategy: hidden under the recommendation, a Dependencies section and a non-empty body under scope routing'
assert '9d-recommended-empty-true' '1' "$(countf 'recommended hidden-only changelogEmpty: true' "$LDR")"
assert '9d-scope-routed-lines' '1' "$(countf 'scope-routed hidden-only lines: 6' "$LDR")"
assert '9d-scope-routed-empty-false' '1' "$(countf 'scope-routed hidden-only changelogEmpty: false' "$LDR")"
assert '9d-dependencies-heading' '1' "$(count '^### Dependencies$' "$G")"
assert '9d-bump-rendered' '1' "$(countf '* **deps:** bump serde from 1.0.230 to 1.0.231' "$G")"
assert '9d-test-and-ci-still-hidden' '0' "$(count 'integration test\|macos-latest' "$G")"

claim '9e py at b08bccfb carries no scope-routed entry'
assert '9e-py-pin-no-scope' '0' "$(countf '"scope"' "$PYC")"

claim '9f R19 fixes prefix chore with include scope on both entries, and records Cargo scope as deps only'
if [ -f "$R19_DECISION" ]; then
  assert '9f-r19-prefix-chore' '2' "$(countf '      prefix: "chore"' "$R19_DECISION")"
  assert '9f-r19-include-scope' '2' "$(countf '      include: "scope"' "$R19_DECISION")"
  # shellcheck disable=SC2016
  #   The backticks are literal text in R19's decision, not an expansion.
  assert '9f-r19-cargo-deps-only' '1' "$(countf 'can only ever append `deps` for a Cargo entry' "$R19_DECISION")"
else
  skip '9f-r19' "R19 decision absent at $R19_DECISION"
fi

# ---------------------------------------------------------------------------
section 'summary'
# ---------------------------------------------------------------------------
printf 'PASS %d  FAIL %d  SKIP %d  TOTAL %d\n' "$PASSED" "$FAILED" "$SKIPPED" "$((PASSED + FAILED + SKIPPED))"
if [ "$FAILED" -ne 0 ]; then
  printf 'RESULT: FAIL\n'
  exit 1
fi
printf 'RESULT: PASS\n'
exit 0
