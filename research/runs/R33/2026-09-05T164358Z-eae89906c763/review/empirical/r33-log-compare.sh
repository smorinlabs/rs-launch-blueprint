#!/usr/bin/env bash
# R33 — the log comparison rule of `## Empirical check`, as a runnable script.
#
# `review/DECISION.md` claims two diffs are empty. An auditor should not have to
# reconstruct the normalization from prose, so it lives here. Revision 4 added
# this file; revision 3 described the same comparisons in prose only.
#
# Usage:
#   bash r33-log-compare.sh rerun   <other-log>   # saved log vs another run of
#                                                 # the SAME (revision-4) script
#   bash r33-log-compare.sh published             # saved log vs revision 2's
#                                                 # published log
#
# Exit status is diff's: 0 means the two logs are identical under the rule.
# The diff itself goes to stdout.
set -u
set -o pipefail

SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SAVED="$SELF_DIR/../evidence/property-and-snapshot-testing.log"
PUBLISHED="$SELF_DIR/../../../../../topics/33-property-and-snapshot-testing/evidence/2026-09-05T164358Z-eae89906c763-property-and-snapshot-testing.log"

# Tier 1: lines excluded from EVERY comparison.
#   * the per-section `-- run at <timestamp>` headers;
#   * check 4's six crates.io counter lines;
#   * the twelve `RATIO live`/`FLOOR live` lines check 4 derives from them.
# Check 4b's RATIO/FLOOR/MOVE lines are deliberately NOT excluded: they are
# computed from committed files and must reproduce exactly.
tier1() {
  grep -vE '^-- run at |^  (proptest|quickcheck|insta|cargo-insta|snapbox|expect-test): recent_downloads=|^  RATIO live |^  FLOOR live '
}

# drop_section <regex matching the section banner> — removes that `===== CHECK`
# banner and everything up to the next `=====` banner.
drop_section() { awk -v pat="$1" '/^===== /{ drop = ($0 ~ pat) } !drop'; }

case "${1:-}" in
  rerun)
    OTHER="${2:?usage: r33-log-compare.sh rerun <other-log>}"
    test -f "$SAVED"  || { echo "missing saved log: $SAVED" >&2; exit 2; }
    test -f "$OTHER"  || { echo "missing other log: $OTHER" >&2; exit 2; }
    diff <(tier1 < "$SAVED") <(tier1 < "$OTHER")
    ;;
  published)
    test -f "$SAVED"     || { echo "missing saved log: $SAVED" >&2; exit 2; }
    test -f "$PUBLISHED" || { echo "missing published log: $PUBLISHED" >&2; exit 2; }
    # Structural differences that are not drift and must be set aside first:
    #   * the revision-2 log has a section 14, struck in revision 3;
    #   * the revision-4 log has a section 4b and check 4's live-ratio block,
    #     both added in revision 4;
    #   * one blank separator line inside check 4, added with that block.
    # Everything surviving those exclusions is text both scripts produce the
    # same way, so a difference there is real upstream drift.
    diff \
      <(drop_section '^===== CHECK 14 ' < "$PUBLISHED" | tier1 | grep -v '^$') \
      <(drop_section '^===== CHECK 4b ' < "$SAVED" | tier1 \
          | grep -vE '^-- the six ratios, DERIVED|^   durable floors\)|^   one-decimal rounding|^   asserted: an exact|^  STATUS OK   collect the six live figure lines|^  STATUS OK   derive the six live ratios|^  ASSERT OK   every live ratio is printed in derived form|^  ASSERT OK   live: ' \
          | grep -v '^$')
    ;;
  *)
    echo "usage: r33-log-compare.sh {rerun <other-log>|published}" >&2
    exit 2
    ;;
esac
