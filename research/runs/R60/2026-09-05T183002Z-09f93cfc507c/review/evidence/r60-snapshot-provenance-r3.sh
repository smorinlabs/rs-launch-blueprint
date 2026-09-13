#!/usr/bin/env bash
# R60 revision 3 — re-derive every committed snapshot from the pinned source it
# claims to come from, and re-test the one claim that is about live history: that
# the pinned commit is still the newest published commit to touch the standard.
#
# WHAT THIS IS FOR. `r60-standard-pin-r3.sh` and `r60-preservation-diff-r3.sh` read
# only committed files, which makes them rerunnable forever but leaves one question
# open: are those committed files really what `snapshots/MANIFEST.txt` says they
# are? This script answers that question over the network, and it is the only R60
# script that needs the network.
#
# REPRODUCIBILITY. Unlike the two offline logs, this log is reproducible ONLY while
# the network is reachable and only until the standard moves off its pinned commit
# — which is exactly the re-verify trigger recorded in `## Decision`. A run that
# cannot reach a source reports it as UNREACHABLE rather than as a pass or a
# failure, so an offline rerun is visibly incomplete instead of quietly green.
#
# THREE OUTCOMES, COUNTED SEPARATELY, because collapsing them would hide things:
#   FAILURE          the source was reached and does NOT match what is committed.
#   UNREACHABLE      the source could not be fetched (offline, or the endpoint is
#                    down). Nothing is proved and nothing is disproved.
#   UNVERIFIABLE-HERE the source has no public remote at all, so no rerun anywhere
#                    outside the owning organisation can check it. The committed
#                    snapshot is the evidence of record; the claim that there is no
#                    public remote is itself checked, by probing for it.
# The exit status is the FAILURE count alone.
#
# No absolute path is printed and `shasum` is fed on stdin, so the parts of this log
# that do not depend on the network are location-independent like the other two.
set -o pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="$HERE/snapshots"
RUN_DIR="$(cd "$HERE/../.." && pwd)"
REPO_ROOT="$(cd "$RUN_DIR/../../../.." && pwd)"

UA="https://github.com/smorinlabs/rs-launch-blueprint"
PIN_COMMIT="fb30a591c267a7ec1130ba4cda679eaee494b9d7"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fails=0; checks=0; unreachable=0; unverifiable=0

check() { # check <label> <expected> <actual>
  local label="$1" want="$2" got="$3"
  checks=$((checks + 1))
  if [ -z "$want" ]; then
    printf 'BUG   %s — empty expectation\n' "$label"; fails=$((fails + 1)); return
  fi
  if printf '%s' "$got" | grep -qF -- "$want"; then printf 'PASS  %s\n' "$label"
  else printf 'FAIL  %s\n      wanted: %s\n      got: %s\n' "$label" "$want" "$got"; fails=$((fails + 1)); fi
}

sha() { shasum -a 256 < "$1" | awk '{print $1}'; }

echo "=== C0. negative control: prove this harness can fail ==="
echo "--- the next FAIL line is deliberate ---"
check "C0 control (expected to FAIL)" "ABSENT-SUBSTRING" "present text"
if [ "$fails" -eq 1 ] && [ "$checks" -eq 1 ]; then
  echo "PASS  C0 harness detected the mismatch"
else
  echo "BUG   C0 harness does not register mismatches — results meaningless"; exit 99
fi
echo "--- control accounted for; counters reset ---"
fails=0; checks=0

echo "=== C1. every snapshot re-derived from the source MANIFEST.txt names ==="
while IFS= read -r row; do
  case "$row" in ''|'#'*) continue ;; esac
  IFS='|' read -r want_sha file kind origin inner tarsha <<<"$row"
  case "$kind" in
    raw)
      if ! curl -sSfL -A "$UA" -o "$WORK/fetched" "$origin" 2>/dev/null; then
        printf 'UNREACHABLE  %s — could not fetch its pinned URL\n' "$file"
        unreachable=$((unreachable + 1)); continue
      fi
      got="$(sha "$WORK/fetched")"
      printf '%s  %s (refetched)\n' "$got" "$file"
      check "C1 $file equals the bytes at its pinned URL" "$want_sha" "$got"
      ;;
    crate)
      tarball="$WORK/$(basename "$origin")"
      if [ ! -f "$tarball" ]; then
        if ! curl -sSfL -A "$UA" -o "$tarball" "$origin" 2>/dev/null; then
          printf 'UNREACHABLE  %s — could not fetch %s\n' "$file" "$(basename "$origin")"
          unreachable=$((unreachable + 1)); continue
        fi
      fi
      got="$(sha "$tarball")"
      printf '%s  %s (tarball)\n' "$got" "$(basename "$origin")"
      check "C1 $(basename "$origin") matches the checksum crates.io records" "$tarsha" "$got"
      rm -rf "$WORK/x"; mkdir -p "$WORK/x"
      if ! tar xzf "$tarball" -C "$WORK/x" "$inner" 2>/dev/null; then
        printf 'FAIL  C1 %s — %s is not in the tarball\n' "$file" "$inner"
        fails=$((fails + 1)); checks=$((checks + 1)); continue
      fi
      got="$(sha "$WORK/x/$inner")"
      printf '%s  %s (extracted)\n' "$got" "$file"
      check "C1 $file equals $inner inside that tarball" "$want_sha" "$got"
      ;;
    local)
      # No public remote. Prove that rather than assert it: an anonymous request
      # for the same path must come back 404. Then say plainly that the committed
      # snapshot is the evidence of record.
      repo="${origin%@*}"; ref="${origin#*@}"
      code="$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" \
        "https://raw.githubusercontent.com/$repo/$ref/$inner" 2>/dev/null)"
      if [ -z "$code" ] || [ "$code" = "000" ]; then
        printf 'UNREACHABLE  %s — the privacy probe itself could not run\n' "$file"
        unreachable=$((unreachable + 1)); continue
      fi
      printf 'anonymous fetch of %s in %s: HTTP %s\n' "$inner" "$repo" "$code"
      check "C1 $repo is not publicly readable, so this snapshot cannot be refetched" "404" "$code"
      printf 'UNVERIFIABLE-HERE  %s — private origin; the committed snapshot is the evidence of record\n' "$file"
      unverifiable=$((unverifiable + 1))
      ;;
    self)
      # An object in this repository. Checkable only where a .git directory is
      # present; a checkout exported without history (git archive, a release
      # tarball) legitimately cannot do it.
      # `.git` is a FILE, not a directory, in a linked worktree, so the presence of
      # history is tested by asking git rather than by looking for a directory.
      if ! git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        printf 'UNVERIFIABLE-HERE  %s — this checkout carries no git history; the committed snapshot is the evidence of record\n' "$file"
        unverifiable=$((unverifiable + 1)); continue
      fi
      obj="${origin#blob }"; obj="${obj#commit }"
      case "$origin" in
        blob*)   git -C "$REPO_ROOT" cat-file blob "$obj" > "$WORK/obj" 2>/dev/null ;;
        commit*) git -C "$REPO_ROOT" show "$obj:$inner" > "$WORK/obj" 2>/dev/null ;;
      esac
      if [ ! -s "$WORK/obj" ]; then
        printf 'UNREACHABLE  %s — the named git object is not in this clone\n' "$file"
        unreachable=$((unreachable + 1)); continue
      fi
      got="$(sha "$WORK/obj")"
      printf '%s  %s (from git history)\n' "$got" "$file"
      check "C1 $file equals the git object MANIFEST.txt names" "$want_sha" "$got"
      ;;
    *)
      printf 'FAIL  C1 %s — unknown origin kind %s\n' "$file" "$kind"
      fails=$((fails + 1)); checks=$((checks + 1))
      ;;
  esac
done < "$SNAP/MANIFEST.txt"

echo "=== C2. the pin is still the newest published commit for the standard ==="
# The live half of the re-verify trigger in '## Decision'. A new commit to
# cli-design-standard.md changes this answer and invalidates every ':<line>'
# citation into the pinned text, which is precisely what the trigger says.
api="https://api.github.com/repos/smorinlabs/cli-standards/commits?path=cli-design-standard.md&per_page=1"
if ! curl -sSfL -A "$UA" -o "$WORK/commits.json" "$api" 2>/dev/null; then
  printf 'UNREACHABLE  C2 — the GitHub commits endpoint could not be reached\n'
  unreachable=$((unreachable + 1))
else
  newest="$(tr ',' '\n' < "$WORK/commits.json" | grep -o '"sha"[[:space:]]*:[[:space:]]*"[0-9a-f]\{40\}"' | head -1 | grep -o '[0-9a-f]\{40\}')"
  echo "newest published commit touching cli-design-standard.md: $newest"
  check "C2a the newest commit for that path is still the pinned one" "$PIN_COMMIT" "$newest"
fi

echo
printf 'CHECKS RUN: %d   FAILURES: %d   UNREACHABLE: %d   UNVERIFIABLE-HERE: %d\n' \
  "$checks" "$fails" "$unreachable" "$unverifiable"
if [ "$unreachable" -gt 0 ]; then
  echo "NOTE: this run did not reach every pinned source, so it is incomplete rather than conclusive."
fi
if [ "$unverifiable" -gt 0 ]; then
  echo "NOTE: UNVERIFIABLE-HERE entries have no public remote by design; each one's privacy was itself checked above."
fi
if [ "$fails" -eq 0 ]; then echo "RESULT: no snapshot contradicts its recorded source"; else echo "RESULT: FAILED"; fi
exit "$fails"
