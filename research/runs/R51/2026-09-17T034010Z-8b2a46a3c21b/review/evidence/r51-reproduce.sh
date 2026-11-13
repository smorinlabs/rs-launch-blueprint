#!/usr/bin/env bash
# R51 container-image — reproduction check for the committed evidence logs.
#
# Reruns r51-registries.sh and r51-sources.sh into a scratch directory and diffs
# each fresh log against the committed one, after removing the lines the
# decision declares volatile. The container script is not rerun here (one run
# costs several minutes of builds); instead its committed revision-2 log is
# compared with revision 1's log, run eight days earlier on an older Docker.
#
# Arguments (revision 3): the check scripts to rerun, by stem; default both,
# r51-registries and r51-sources. A host whose sandbox has no network reach
# names r51-sources alone, and the record's "scripts rerun" line says so.
#
# The container comparison is by check id and verdict only. Its byte figures
# are not compared: besides the timestamp, scratch and builder lines, the
# compressed sizes of re-exported layers (measured-size-main,
# measured-size-noprobe, measured-size-busybox-delta,
# measured-size-debian-slim), the measured-disk-usage-* lines, the
# C2g/C9a/C9b/C5c message lines that embed those figures, the wall-clock lines
# and buildx's "#N" progress lines vary by a few bytes or seconds from run to
# run on the SAME Docker and BuildKit. Every such figure is asserted by range
# or not asserted (C2g: under 40 MB). measured-size-main reproduced exactly in
# the rerun of the empirical audit of revision 2 (audit-claude.r1.md) and
# moved 3 B (12302310 -> 12302307) in the revision-4 audit's rerun
# (audit-claude.r4.md); measured-binary-size reproduced exactly in both.
#
# Output is the reproduction record; nothing under evidence/ is written.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
GREP=/usr/bin/grep
TMP="$(mktemp -d "${TMPDIR:-/tmp}/r51-reproduce.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
STATUS=0

echo "=== R51 reproduction record"
echo "date-utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "grep:     $($GREP --version | head -1)"

# Volatile by declaration: timestamps, scratch paths, live counters. Every
# other line, including every PASS/FAIL verdict, must be identical.
VOLATILE='^(date-utc:|gh-call-[0-9a-z]+-utc:|scratch:|builder:|override-scan-files:|override-numbers-in-use:|observed-r(68|77|80)-live-[a-z-]+:)|^PASS  (D3c|D5e|S9c|S6c) '

filtered() { $GREP -v -E "$VOLATILE" "$1" || true; }

if [ "$#" -gt 0 ]; then SCRIPTS=("$@"); else SCRIPTS=(r51-registries r51-sources); fi
echo "scripts rerun: ${SCRIPTS[*]}"
for s in "${SCRIPTS[@]}"; do
  echo
  echo "--- $s.sh: fresh run against the committed $s.log"
  set +e
  "$HERE/$s.sh" > "$TMP/$s.log" 2>&1
  code=$?
  set -e
  echo "fresh exit code: $code"
  echo "fresh    $($GREP -E '^SUMMARY:' "$TMP/$s.log" || echo 'no SUMMARY line')"
  echo "committed $($GREP -E '^SUMMARY:' "$HERE/$s.log" || echo 'no SUMMARY line')"
  filtered "$HERE/$s.log" > "$TMP/$s.committed.f"
  filtered "$TMP/$s.log" > "$TMP/$s.fresh.f"
  if diff "$TMP/$s.committed.f" "$TMP/$s.fresh.f" > "$TMP/$s.diff"; then
    echo "RESULT $s: identical outside the volatile classes"
  else
    echo "RESULT $s: DIFFERS outside the volatile classes:"
    cat "$TMP/$s.diff"
    STATUS=1
  fi
  echo "volatile lines, committed then fresh:"
  { $GREP -E "$VOLATILE" "$HERE/$s.log" || true; } | sed 's/^/  c: /'
  { $GREP -E "$VOLATILE" "$TMP/$s.log" || true; } | sed 's/^/  f: /'
done

echo
echo "--- r51-container.log (the revision-2 run, carried unchanged) against r51-container.r1.log (revision 1)"
for f in r51-container.log r51-container.r1.log; do
  echo "$f: $($GREP -E '^SUMMARY:' "$HERE/$f")  $($GREP -E '^docker:' "$HERE/$f")"
done
ids() { $GREP -E '^(PASS|FAIL|SKIP)  ' "$1" | awk '{print $1, $2}'; }
if diff <(ids "$HERE/r51-container.r1.log") <(ids "$HERE/r51-container.log") > "$TMP/ids.diff"; then
  echo "RESULT container: the same check ids carry the same verdicts in both runs"
else
  echo "RESULT container: verdicts differ:"
  cat "$TMP/ids.diff"
  STATUS=1
fi
echo "measured lines, revision 1 then revision 2 (not compared; see the header):"
TAB="$(printf '\t')"
join -t "$TAB" -a1 -a2 -e '-' -o 0,1.2,2.2 \
  <($GREP -E '^measured-' "$HERE/r51-container.r1.log" | sed "s/: /$TAB/" | sort) \
  <($GREP -E '^measured-' "$HERE/r51-container.log" | sed "s/: /$TAB/" | sort) \
  | sed 's/^/  /'

echo
echo "reproduction-exit: $STATUS"
exit "$STATUS"
