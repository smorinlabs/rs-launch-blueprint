#!/usr/bin/env bash
# R49 revision 5 — licence-enumeration completeness check.
#
# Every claim this script makes is about an immutable git blob, never about a
# working-tree file, so it stays rerunnable after the revision-5 commit lands.
#
#   REV2 = 2ac02e1  research/runs/R49/.../review/DECISION.md  (revision 2)
#   REV4 = ddbee6a  research/runs/R49/.../review/DECISION.md  (revision 4)
#
# It proves four things:
#   1. the revision-3 commit message's licence-identifier grep, re-run
#      untruncated on the revision-2 blob, returns 40 lines, not the 5 recorded;
#   2. every one of the 35 dropped lines matched through the bare `mpl`
#      alternative and through nothing else -- i.e. the omitted lines are
#      exactly the ordinary-word matches, which is the semantic filter that was
#      applied without being stated;
#   3. a corrected, word-bounded licence-identifier pattern returns on the
#      revision-2 blob exactly the 5 lines revision 3 acted on, with no
#      filtering, so revision 3 missed no licence-as-gate location;
#   4. widening that corrected pattern to the permissive SPDX identifiers finds
#      6 further licence locations that no revision-3 enumeration list carried;
#      this script prints them so they can be read.
#
# Assertions are on content, not on exit codes. Any failure exits non-zero.

set -o pipefail
set -u

REPO="$(git rev-parse --show-toplevel)" || exit 1
ITEM="research/runs/R49/2026-09-05T155504Z-2107cffb3ecf"
DEC="$ITEM/review/DECISION.md"

REV2_COMMIT="2ac02e1"
REV4_COMMIT="ddbee6a"
REV2_SHA="1b5a6b99ecedb88f7358d16a4567aa9b56838a2102e9e4feda99d00bc787513f"
REV4_SHA="7f088e512f1393896c043274a9f05f9ff65639433b23cd6b0e6b1b35b416fcc7"

# `grep` on the author's PATH is ugrep 7.8.4, not BSD or GNU grep. Every list
# below is produced with the system grep at an absolute path so the command is
# unambiguous; check 0 shows the two agree on the pattern that matters.
GREP=/usr/bin/grep

# The pattern recorded in the revision-3 commit message (7a08061).
PAT_OLD='copyleft|agpl|[^a-z]gpl|mpl|mozilla|patent|permissive'
# The corrected pattern: licence identifiers and licence-policy terms, matched
# case-sensitively and as whole words. Whole-word matching removes the substring
# matches that made the original pattern noisy; it does not make an ordinary-word
# match impossible in principle, because `permissive` and `patent` are ordinary
# words, so every line this pattern returns is printed below for the reader to
# check rather than merely counted.
PAT_ID='copyleft|AGPL|LGPL|GPL|MPL|Mozilla|PERMISSIVE|permissive|patent'
# The same, widened to the permissive SPDX identifiers this decision records.
PAT_ID_FULL='copyleft|AGPL|LGPL|GPL|MPL|Mozilla|PERMISSIVE|permissive|patent|Apache-2\.0|MIT|BSD|ISC|Unlicense|CC0'

TMP="$(mktemp -d)" || exit 1
trap 'rm -rf "$TMP"' EXIT

fail=0
assert_eq() { # label expected actual
  if [ "$2" = "$3" ]; then
    printf 'ASSERT ok   %s\n' "$1"
  else
    printf 'ASSERT FAIL %s\n  expected: %s\n  actual:   %s\n' "$1" "$2" "$3"
    fail=1
  fi
}

printf 'retrieved: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'repo: %s\n' "$REPO"
printf 'grep(PATH): %s\n' "$(command -v grep)"
printf 'grep(used): %s\n\n' "$GREP"

## 0. fix the two blobs and prove they are the revisions named
git -C "$REPO" show "$REV2_COMMIT:$DEC" > "$TMP/rev2.md" || { echo "git show rev2 failed"; exit 1; }
git -C "$REPO" show "$REV4_COMMIT:$DEC" > "$TMP/rev4.md" || { echo "git show rev4 failed"; exit 1; }
got2="$(shasum -a 256 "$TMP/rev2.md" | cut -d' ' -f1)"
got4="$(shasum -a 256 "$TMP/rev4.md" | cut -d' ' -f1)"
assert_eq "revision-2 blob sha256" "$REV2_SHA" "$got2"
assert_eq "revision-4 blob sha256" "$REV4_SHA" "$got4"

echo
echo '## 1. the recorded grep, re-run untruncated on the revision-2 blob'
echo "argv: $GREP -niE '$PAT_OLD' <revision-2 blob>"
old_lines="$("$GREP" -niE "$PAT_OLD" "$TMP/rev2.md" | cut -d: -f1 | tr '\n' ' ' | sed 's/ $//')"
old_count="$("$GREP" -ciE "$PAT_OLD" "$TMP/rev2.md")"
printf 'raw output, one line per match, line numbers only:\n%s\n' "$old_lines"
printf 'raw match count: %s\n' "$old_count"
assert_eq "untruncated licence-identifier grep returns 40 lines" "40" "$old_count"
assert_eq "recorded revision-3 list is NOT that raw output" \
  "differs" \
  "$([ "$old_lines" = "182 363 607 610 616" ] && echo same || echo differs)"
# the same pattern through the PATH grep, to show the 40 is not a grep artifact
path_count="$(grep -ciE "$PAT_OLD" "$TMP/rev2.md")"
assert_eq "PATH grep agrees on the count" "40" "$path_count"

echo
echo '## 2. the filter that was applied but not stated'
echo 'For each line in raw-output minus recorded-list, the tokens it matched:'
"$GREP" -niE "$PAT_OLD" "$TMP/rev2.md" | cut -d: -f1 | sort > "$TMP/old.set"
printf '182\n363\n607\n610\n616\n' | sort > "$TMP/recorded.set"
# `comm` compares byte-wise, so both operands here and below are sorted with the
# same plain `sort`; a numeric sort on one side silently yields an empty
# intersection, which this script did on its first run.
comm -23 "$TMP/old.set" "$TMP/recorded.set" > "$TMP/dropped.set"
dropped_count="$(wc -l < "$TMP/dropped.set" | tr -d ' ')"
assert_eq "35 lines were dropped from the reported list" "35" "$dropped_count"
sort -n "$TMP/dropped.set" > "$TMP/dropped.disp"
while read -r n; do
  toks="$(sed -n "${n}p" "$TMP/rev2.md" | "$GREP" -oiE "$PAT_OLD" | sort -u | tr '\n' ',' | sed 's/,$//')"
  printf '  line %-4s matched: %s\n' "$n" "$toks"
done < "$TMP/dropped.disp"
distinct="$(while read -r n; do sed -n "${n}p" "$TMP/rev2.md" | "$GREP" -oiE "$PAT_OLD"; done < "$TMP/dropped.disp" | sort -u | tr '\n' ' ' | sed 's/ $//')"
assert_eq "every dropped line matched through 'mpl' and nothing else" "mpl" "$distinct"
echo 'The ordinary words those `mpl` occurrences sit inside:'
while read -r n; do sed -n "${n}p" "$TMP/rev2.md"; done < "$TMP/dropped.disp" \
  | "$GREP" -oiE '[a-z]*mpl[a-z]*' | sort | uniq -c | sort -rn | sed 's/^/  /'
# none of the dropped lines is a licence location the `licen` grep would miss
"$GREP" -ni 'licen' "$TMP/rev2.md" | cut -d: -f1 | sort > "$TMP/licen2.set"
also_licen="$(comm -12 "$TMP/dropped.set" "$TMP/licen2.set" | sort -n | tr '\n' ' ' | sed 's/ $//')"
printf 'dropped lines that do carry licence text (all covered by the `licen` grep): %s\n' "$also_licen"
assert_eq "only the owned-parameter line among the dropped lines carries licence text" "338" "$also_licen"

echo
echo '## 3. corrected pattern: raw output equals the reported list, no filter'
echo "argv: $GREP -nwE '$PAT_ID' <revision-2 blob>"
id2="$("$GREP" -nwE "$PAT_ID" "$TMP/rev2.md" | cut -d: -f1 | tr '\n' ' ' | sed 's/ $//')"
printf 'raw output:\n%s\n' "$id2"
assert_eq "corrected pattern on revision 2 returns exactly the 5 lines revision 3 acted on" \
  "182 363 607 610 616" "$id2"
echo 'The five lines in full:'
"$GREP" -nwE "$PAT_ID" "$TMP/rev2.md" | sed 's/^/  /'
echo
echo "argv: $GREP -nwE '$PAT_ID' <revision-4 blob>"
id4="$("$GREP" -nwE "$PAT_ID" "$TMP/rev4.md" | cut -d: -f1 | tr '\n' ' ' | sed 's/ $//')"
printf 'raw output:\n%s\n' "$id4"
assert_eq "corrected pattern on revision 4 returns 10 lines" \
  "12 29 70 92 298 489 733 736 745 794" "$id4"
echo 'The ten lines in full:'
"$GREP" -nwE "$PAT_ID" "$TMP/rev4.md" | cut -c1-200 | sed 's/^/  /'

echo
echo '## 4. widened to the permissive SPDX identifiers'
echo "argv: $GREP -nwE '$PAT_ID_FULL' <revision-2 blob>"
full2="$("$GREP" -nwE "$PAT_ID_FULL" "$TMP/rev2.md" | cut -d: -f1 | tr '\n' ' ' | sed 's/ $//')"
printf 'raw output:\n%s\n' "$full2"
assert_eq "widened pattern on revision 2 returns 15 lines" \
  "53 182 338 342 363 364 582 605 606 607 608 609 610 611 616" "$full2"
echo "argv: $GREP -nwE '$PAT_ID_FULL' <revision-4 blob>"
full4="$("$GREP" -nwE "$PAT_ID_FULL" "$TMP/rev4.md" | cut -d: -f1 | tr '\n' ' ' | sed 's/ $//')"
printf 'raw output:\n%s\n' "$full4"
assert_eq "widened pattern on revision 4 returns 21 lines" \
  "12 29 70 92 102 156 298 464 468 489 490 708 731 732 733 734 735 736 737 745 794" "$full4"
# negative control: the widened pattern must not match OMIT, implementation or template
printf 'a F217 (OMIT)\nb implementation\nc template\nd GPL-3.0-only\ne MPL-2.0\nf LICENSE-MIT\ng C-PERMISSIVE\n' > "$TMP/control.txt"
ctrl="$("$GREP" -nwE "$PAT_ID_FULL" "$TMP/control.txt" | cut -d: -f1 | tr '\n' ' ' | sed 's/ $//')"
assert_eq "negative control: only the four real identifiers match" "4 5 6 7" "$ctrl"
echo 'The 6 licence locations no revision-3 enumeration list carried (revision-2 numbering):'
for n in 582 605 606 608 609 611; do
  printf '  %s: %s\n' "$n" "$(sed -n "${n}p" "$TMP/rev2.md" | cut -c1-150)"
done

echo
if [ "$fail" -eq 0 ]; then
  echo 'RESULT: all assertions passed'
else
  echo 'RESULT: one or more assertions FAILED'
fi
exit "$fail"
