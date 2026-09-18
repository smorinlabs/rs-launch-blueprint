#!/usr/bin/env bash
# R70 — prove the two evidence scripts run from a CLEAN `git archive HEAD`
# extraction, not only from the live worktree, and that their deterministic
# output reproduces.
#
# Run this from the worktree AFTER the scripts are committed.  It extracts
# HEAD into $TMPDIR, runs the extracted copies there, and diffs their logs
# against the committed ones.
set -euo pipefail
set -o pipefail

GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }
# shellcheck disable=SC2329  # reserved: kept so the counter grammar matches the
# other two evidence scripts; no branch in this script skips today.
skip() { SKIP=$((SKIP+1)); printf 'SKIP  %s\n' "$1"; }

here="$(cd "$(dirname "$0")" && pwd)"
root="$(git -C "$here" rev-parse --show-toplevel)"
rel="${here#"$root"/}"

printf '=== R70 archive re-run ===\n'
printf 'date (UTC): %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'worktree:  %s\n' "$root"
printf 'evidence:  %s\n' "$rel"
printf 'HEAD:      %s\n' "$(git -C "$root" rev-parse HEAD)"
# A worktree's .git is a FILE, not a directory; test for existence, not type.
if [ -e "$root/.git" ]; then
  if [ -d "$root/.git" ]; then ok "repository marker present (.git directory)"
  else ok "repository marker present (.git file — this is a worktree)"; fi
else
  bad "no .git marker at the repository root"
fi

scratch="$(mktemp -d "${TMPDIR:-/tmp}/r70-archive.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/tree"
git -C "$root" archive HEAD | tar -x -C "$scratch/tree"
ok "git archive HEAD extracted to a clean tree"

ext="$scratch/tree/$rel"
if [ ! -d "$ext" ]; then
  bad "the evidence directory is absent from HEAD — commit it before running this"
  printf '\n=== summary ===\nPASS %d  FAIL %d  SKIP %d  TOTAL %d\n' \
    "$PASS" "$FAIL" "$SKIP" "$((PASS+FAIL+SKIP))"
  exit 1
fi
if [ -e "$scratch/tree/.git" ]; then
  bad "the extraction contains a .git — git archive should never emit one"
else
  ok "the extraction contains no nested repository"
fi

for script in registry.sh probe.sh; do
  if [ -x "$ext/$script" ]; then ok "$script is present and executable in HEAD"
  else bad "$script missing or not executable in HEAD"; fi
done

############################################################
printf -- '\n--- registry.sh from the extracted tree\n'
############################################################
if (cd "$ext" && ./registry.sh) > "$scratch/registry-archive.log" 2>&1; then
  ok "registry.sh exited 0 from the extracted tree"
else
  bad "registry.sh FAILED from the extracted tree"
  tail -20 "$scratch/registry-archive.log"
fi
cp "$scratch/registry-archive.log" "$here/registry-archive.log"
# The first three lines carry the run date and the tool banner; line 2 (the
# host date) is the only deterministic-section line that moves across days.
if diff <(tail -n +4 "$here/registry.log") <(tail -n +4 "$here/registry-archive.log") > "$scratch/registry.diff"; then
  ok "registry.log and registry-archive.log are identical below the banner"
else
  bad "registry.log differs from the archive rerun:"
  sed 's/^/      /' "$scratch/registry.diff"
fi

############################################################
printf -- '\n--- probe.sh from the extracted tree\n'
############################################################
if (cd "$ext" && ./probe.sh) > "$scratch/probe-archive.log" 2>&1; then
  ok "probe.sh exited 0 from the extracted tree"
else
  bad "probe.sh FAILED from the extracted tree"
  tail -30 "$scratch/probe-archive.log"
fi
cp "$scratch/probe-archive.log" "$here/probe-archive.log"
# probe.log's header carries the run date and the scratch directory name, and
# the resolver line is absent on a warm registry; compare the PASS/FAIL/SKIP
# lines and the captured bodies, which are what the decision cites.
verdicts() { $GREP -E '^(PASS|FAIL|SKIP)  |^      \{|^      (GET|POST|DELETE) ' "$1"; }
if diff <(verdicts "$here/probe.log") <(verdicts "$here/probe-archive.log") > "$scratch/probe.diff"; then
  ok "probe.log and probe-archive.log agree on every verdict and every captured body"
else
  bad "probe verdicts differ between the in-place run and the archive rerun:"
  sed 's/^/      /' "$scratch/probe.diff"
fi
for f in probe.log probe-archive.log; do
  if $GREP -q '^PASS 33  FAIL 0  SKIP 0  TOTAL 33$' "$here/$f"; then
    ok "$f summary is PASS 33  FAIL 0  SKIP 0"
  else
    bad "$f summary is not PASS 33 FAIL 0 SKIP 0: $($GREP -m1 '^PASS [0-9]' "$here/$f")"
  fi
done

printf '\n=== summary ===\n'
printf 'PASS %d  FAIL %d  SKIP %d  TOTAL %d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS+FAIL+SKIP))"
if [ "$FAIL" -ne 0 ]; then exit 1; fi
exit 0
