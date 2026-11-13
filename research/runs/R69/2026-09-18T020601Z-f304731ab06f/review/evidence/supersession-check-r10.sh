#!/usr/bin/env bash
# R69 revision 10 — assertions on the supersession section and the carried run.
#
# What this script establishes, and what it does not. It asserts that revision
# 10's decision carries the published revision-9 topic bytes verbatim as the
# tail of the file, that the section heading appears exactly once above them and
# nowhere earlier in any form, that the H2 order of the current entry is
# unchanged, and that every byte this run carried forward from the run that
# published revision 9 is identical to that run's copy. It asserts nothing about
# whether the decision's content is correct; the owned value is
# `owned-value-check-r10.sh`'s subject, and the recommendation's own evidence is
# the six checks this revision did not touch.
#
# Run from the repository root:  bash <this path>
# No clock, hostname, absolute path or scratch directory name is printed, so the
# output is byte-identical in place and from a clean `git archive` extraction of
# the same commit.

set -euo pipefail

GREP=/usr/bin/grep
PASS=0
FAIL=0
SKIP=0

RUN=research/runs/R69/2026-09-18T020601Z-f304731ab06f
SOURCE_RUN=research/runs/R69/2026-09-17T014646Z-d5b96f477092
DECISION=$RUN/review/DECISION.md
TOPIC=research/topics/69-web-framework-stack/DECISION.md
TOPIC_SHA=d4507f5b2ca4201d9837caf013de16f30070cb3e2f5558eb66f7ded9dfd2c10d

# Assembled at run time for the same reason the sibling script assembles it:
# `check_history` splits a decision at the FIRST occurrence of this substring,
# and a script that carried the literal would write a copy into its own log.
HEADING='## Supers'
HEADING="${HEADING}edes"

pass() { PASS=$((PASS + 1)); printf 'PASS %s: %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s: %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s: %s\n' "$1" "$2"; }

assert_eq() { # label expected actual description
  if [ "$2" = "$3" ]; then pass "$1" "$4 == $2"; else fail "$1" "$4: expected $2, got $3"; fi
}

printf '== R69 revision 10 — supersession and carried-run check ==\n'
printf 'grep: %s\n' "$("$GREP" --version | head -1)"
printf 'shasum: %s\n' "$(shasum --version)"
printf 'decision: %s\n' "$DECISION"

for path in "$DECISION" "$TOPIC"; do
  if [ ! -f "$path" ]; then
    printf 'FATAL: required file absent: %s\n' "$path"
    exit 2
  fi
done

HEAD_FILE=$(mktemp)
TAIL_FILE=$(mktemp)
MUTANT=$(mktemp)
trap 'rm -f "$HEAD_FILE" "$TAIL_FILE" "$MUTANT"' EXIT

printf '\n-- 1. the published bytes this revision supersedes --\n'
topic_sha=$(shasum -a 256 <"$TOPIC" | cut -d' ' -f1)
assert_eq S1 "$TOPIC_SHA" "$topic_sha" 'sha256 of the published topic decision'

printf '\n-- 2. exactly one section heading, and nothing above it --\n'
heading_lines=$("$GREP" -c -x -F "$HEADING" "$DECISION" || true)
assert_eq S2a 1 "$heading_lines" 'lines equal to the section heading'
heading_line=$("$GREP" -n -m1 -x -F "$HEADING" "$DECISION" | cut -d: -f1)
head -n $((heading_line - 1)) "$DECISION" >"$HEAD_FILE"
above=$("$GREP" -c -F "$HEADING" "$HEAD_FILE" || true)
assert_eq S2b 0 "$above" 'occurrences of the heading text above the heading (any form)'
below=$("$GREP" -c -F "$HEADING" "$DECISION" || true)
assert_eq S2c 8 "$below" 'occurrences in the whole file (the heading plus 7 preserved mentions)'

printf '\n-- 3. the dated current entry check_history requires --\n'
dated=$("$GREP" -c -E '^#(##)? [0-9]{4}-[0-9]{2}-[0-9]{2}([[:space:]]|$)' "$HEAD_FILE" || true)
if [ "$dated" -ge 1 ]; then
  pass S3a "date-first headings above the section: $dated"
else
  fail S3a 'no date-first heading above the section; check_history would refuse'
fi
first_line=$(head -1 "$DECISION")
assert_eq S3b '# 2026-09-17 — R69 — web-framework-stack — decision (revision 10)' \
  "$first_line" 'the title line'

printf '\n-- 4. H2 order of the current entry --\n'
h2=$("$GREP" -E '^## ' "$HEAD_FILE" | tr '\n' '/' || true)
assert_eq S4 '## Decision/## Parameters/## Empirical check/## Engines/' "$h2" \
  'the H2 headings of the current entry, in order'

printf '\n-- 5. the tail is the published bytes, verbatim --\n'
topic_bytes=$(wc -c <"$TOPIC" | tr -d ' ')
tail -c "$topic_bytes" "$DECISION" >"$TAIL_FILE"
tail_sha=$(shasum -a 256 <"$TAIL_FILE" | cut -d' ' -f1)
assert_eq S5a "$TOPIC_SHA" "$tail_sha" "sha256 of the decision's last $topic_bytes bytes"
if cmp -s "$TAIL_FILE" "$TOPIC"; then
  pass S5b 'cmp of that tail against the published topic decision reports no difference'
else
  fail S5b 'the tail differs from the published topic decision'
fi

printf '\n-- 6. control: the tail comparison must be able to fail --\n'
# Change one byte of the tail on a scratch copy and require both S5 matchers to
# reject it. Without this, S5a and S5b could be passing on a comparison that
# cannot distinguish anything.
{ printf 'x'; tail -c $((topic_bytes - 1)) "$TAIL_FILE"; } >"$MUTANT"
mutant_sha=$(shasum -a 256 <"$MUTANT" | cut -d' ' -f1)
if [ "$mutant_sha" = "$TOPIC_SHA" ]; then
  fail S6a 'control: a one-byte mutation did not change the digest'
else
  pass S6a 'control: a one-byte mutation changes the digest, so S5a can fail'
fi
if cmp -s "$MUTANT" "$TOPIC"; then
  fail S6b 'control: cmp reported no difference against a mutated copy'
else
  pass S6b 'control: cmp rejects the mutated copy, so S5b can fail'
fi

printf '\n-- 7. the raw reports match the bytes published for revision 9 --\n'
raw_pair() { # label run_file topic_file
  if [ ! -f "$2" ] || [ ! -f "$3" ]; then
    skip "$1" "raw report absent from this tree: $2 or $3"
    return
  fi
  if cmp -s "$2" "$3"; then pass "$1" "$2 == $3"; else fail "$1" "$2 differs from $3"; fi
}
raw_pair S7a "$RUN/raw/codex.md" \
  research/topics/69-web-framework-stack/raw/codex-2026-09-17T014646Z-d5b96f477092.md
raw_pair S7b "$RUN/raw/opus.md" \
  research/topics/69-web-framework-stack/raw/opus-2026-09-17T014646Z-d5b96f477092.md
# research_package.py's source_file prefers a `.normalized.md` twin beside the
# raw, so the bytes published as the doxa report are the twin's, not doxa.md's.
raw_pair S7c "$RUN/raw/doxa.normalized.md" \
  research/topics/69-web-framework-stack/raw/doxa-2026-09-17T014646Z-d5b96f477092.md
if [ -f "$RUN/raw/doxa.md" ]; then
  pass S7d 'the collected doxa.md is carried beside its normalized twin'
else
  fail S7d 'the collected doxa.md is missing'
fi

printf '\n-- 8. every carried byte is identical to the publishing run copy --\n'
# Walked from THIS run outward, so the count is the number of files this run
# claims to have carried and every one of them is compared. The publishing run
# also holds untracked, git-ignored regeneration output under
# review/evidence/sources/ and review/empirical/, which is deliberately not
# carried; walking from the source would report those as missing.
if [ ! -d "$SOURCE_RUN/review/evidence" ]; then
  skip S8a "the publishing run is absent from this tree: $SOURCE_RUN"
  skip S8b "the publishing run is absent from this tree: $SOURCE_RUN"
  skip S8c "the publishing run is absent from this tree: $SOURCE_RUN"
else
  carried=0
  differing=0
  missing=0
  while IFS= read -r file; do
    relative=${file#"$RUN/"}
    case $relative in
      review/DECISION.md | review/CARRIED-FROM.md | review/evidence/*-r10*) continue ;;
    esac
    carried=$((carried + 1))
    if [ ! -f "$SOURCE_RUN/$relative" ]; then
      missing=$((missing + 1))
      printf '  NOT IN SOURCE %s\n' "$relative"
    elif ! cmp -s "$file" "$SOURCE_RUN/$relative"; then
      differing=$((differing + 1))
      printf '  DIFFERS %s\n' "$relative"
    fi
  done <<EOF
$(find "$RUN/raw" "$RUN/review" -type f | sort)
EOF
  printf '  carried files compared: %s\n' "$carried"
  assert_eq S8a 309 "$carried" 'files this run carried forward'
  assert_eq S8b 0 "$missing" 'carried files with no counterpart in the publishing run'
  assert_eq S8c 0 "$differing" 'carried files differing from the publishing run'
fi

printf '\n-- 9. the round-9 audits are NOT carried --\n'
for name in audit-codex.md audit-fable.md; do
  if [ -e "$RUN/review/$name" ]; then
    fail "S9-$name" "review/$name is present; it binds revision 9 and must not be carried"
  else
    pass "S9-$name" "review/$name is absent; revision 10 gets fresh audits"
  fi
done

printf '\n-- 10. the carried evidence scripts are unmoved in git --\n'
# A worktree's .git is a FILE, not a directory, so the guard uses -e. A clean
# `git archive` extraction has neither, and these three checks SKIP by name.
if [ ! -e .git ]; then
  for label in S10a S10b S10c; do
    skip "$label" 'no .git in this tree (a git archive extraction); git blob comparison not possible'
  done
else
  scripts=0
  moved=0
  untracked=0
  for script in "$RUN"/review/evidence/*.sh; do
    name=$(basename "$script")
    case $name in
      *-r10.sh) continue ;;
    esac
    scripts=$((scripts + 1))
    local_hash=$(git hash-object "$script")
    head_hash=$(git ls-tree HEAD -- "$SOURCE_RUN/review/evidence/$name" | awk '{print $3}')
    if [ -z "$head_hash" ]; then
      untracked=$((untracked + 1))
      printf '  NO HEAD BLOB %s\n' "$name"
    elif [ "$local_hash" != "$head_hash" ]; then
      moved=$((moved + 1))
      printf '  MOVED %s\n' "$name"
    fi
  done
  printf '  carried evidence scripts compared: %s\n' "$scripts"
  assert_eq S10a 7 "$scripts" 'carried evidence scripts'
  assert_eq S10b 0 "$untracked" "carried scripts with no blob at HEAD's source path"
  assert_eq S10c 0 "$moved" "carried scripts whose bytes differ from HEAD's blob"
fi

printf '\n== SUMMARY ==\n'
printf 'CHECKS RUN: %s PASS: %s FAIL: %s SKIP: %s\n' "$((PASS + FAIL + SKIP))" "$PASS" "$FAIL" "$SKIP"
if [ "$FAIL" -ne 0 ]; then exit 1; fi
exit 0
