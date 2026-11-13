#!/usr/bin/env bash
# R70 revision 4 — rerun every earlier evidence script without writing over
# any committed log.
#
# rest-r2.sh group B pins nine revision-1 artifacts by sha256, and registry.sh
# and archive-check.sh write beside themselves.  So nothing runs in place that
# writes in place:
#   - archive-check.sh (which itself reruns registry.sh and probe.sh from a
#     `git archive HEAD` extraction and diffs them against the committed logs)
#     runs inside a throwaway clone of HEAD under $TMPDIR;
#   - probe-r2.sh and rest-r2.sh write nothing beside themselves, so they run
#     in place with their output captured under $TMPDIR.  rest-r2.sh must run
#     in place: its group C reads the CURRENT DECISION.md.
# Every committed log is hashed before and after, and must not move.
#
# Network: only what registry.sh already reaches (crates.io, static.rust-lang.org,
# rustsec.org, advisory-db, datatracker/RFC Editor, IANA, and five `gh api`
# reads at one per 20 s).  Cargo uses whatever CARGO_HOME the caller set.
#
# Asserts on CONTENT.  PASS/FAIL/SKIP counted and summed; non-zero on FAIL.
set -euo pipefail
set -o pipefail

GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }
assert() { if [ "$2" = "$3" ]; then ok "$1 == $2"; else bad "$1: expected [$2] got [$3]"; fi; }
summary_of() { $GREP -E '^PASS [0-9]+  FAIL [0-9]+  SKIP [0-9]+  TOTAL [0-9]+$' "$1" | tail -1; }
# Verdict, section, body and catalog lines: everything but the moving banner.
verdicts() { $GREP -E '^(PASS|FAIL|SKIP)  |^      |^--- |^=== summary|^PASS [0-9]' "$1"; }

here="$(cd "$(dirname "$0")" && pwd)"
root="$(git -C "$here" rev-parse --show-toplevel)"
rel="${here#"$root"/}"
head_sha="$(git -C "$root" rev-parse HEAD)"

printf '=== R70 revision 4: rerun of every earlier evidence script ===\n'
printf 'date (UTC): %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'os: %s %s (%s)\n' "$(sw_vers -productName 2>/dev/null || uname -s)" \
  "$(sw_vers -productVersion 2>/dev/null || uname -r)" "$(uname -m)"
printf 'host rustc: %s\n' "$(rustc --version)"
printf 'host cargo: %s\n' "$(cargo --version)"
printf 'CARGO_HOME: %s\n' "${CARGO_HOME:-<unset>}"
printf 'HEAD: %s\n' "$head_sha"

# Resolve symlinks (macOS $TMPDIR sits under /var -> /private/var): archive-check.sh
# strips `git rev-parse --show-toplevel` from its own directory, which only works
# when both spellings agree.
scratch="$(mktemp -d "${TMPDIR:-/tmp}/r70-rerun-r4.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
scratch="$(cd "$scratch" && pwd -P)"
printf 'scratch: %s (deleted on exit)\n' "$scratch"

committed="registry.sh registry.log registry-figures.log probe.sh probe.log
archive-check.sh archive-check.log registry-archive.log probe-archive.log
rest-r2.sh rest-r2.log probe-r2.sh probe-r2.log"

############################################################
printf -- '\n--- 0. the committed evidence is what HEAD holds, hashed before any run\n'
############################################################
for f in $committed; do
  if git -C "$root" diff --quiet HEAD -- "$rel/$f"; then ok "$f is unmodified against HEAD"
  else bad "$f differs from HEAD — a clone of HEAD would not run these bytes"; fi
done
( cd "$here" && for f in $committed; do shasum -a 256 "$f"; done ) > "$scratch/before.sha"

############################################################
printf -- '\n--- 1. archive-check.sh (reruns registry.sh and probe.sh) in a clone of HEAD\n'
############################################################
git clone -q --no-checkout "$root" "$scratch/clone"
git -C "$scratch/clone" -c advice.detachedHead=false checkout -q "$head_sha"
assert "clone is at HEAD" "$head_sha" "$(git -C "$scratch/clone" rev-parse HEAD)"
cev="$scratch/clone/$rel"
# The clone carries HEAD's committed archive logs; remove them so the summaries
# below can only come from this rerun.
rm -f "$cev/registry-archive.log" "$cev/probe-archive.log"
# archive-check.sh exits non-zero on the one known drift below; the exit status
# is recorded, and the content assertions decide.
if (cd "$cev" && ./archive-check.sh) > "$scratch/archive-check.log" 2>&1; then
  printf 'NOTE  archive-check.sh exited 0\n'
else
  printf 'NOTE  archive-check.sh exited non-zero (expected only for the IANA drift asserted below)\n'
fi
printf -- '--- archive-check.sh output (verdict and diff lines)\n'
$GREP -E '^(PASS|FAIL|SKIP)  |^      [<>]|^PASS [0-9]' "$scratch/archive-check.log" | sed 's/^/    /'
# Known drift, 2026-09-27: IANA's application.csv now spells the reference
# "[RFC 9457]" (with a space); registry.sh line 251 greps the literal "RFC9457".
# The rerun may differ from the committed registry.log on that one verdict and
# on the summary line, and nowhere else.
assert "archive-check.sh summary" "PASS 9  FAIL 2  SKIP 0  TOTAL 11" "$(summary_of "$scratch/archive-check.log")"
assert "archive-check.sh FAIL lines are exactly the registry exit and the registry diff" \
  "FAIL  registry.sh FAILED from the extracted tree|FAIL  registry.log differs from the archive rerun:|" \
  "$($GREP -E '^FAIL  ' "$scratch/archive-check.log" | tr '\n' '|')"
assert "the registry.log diff is exactly the IANA citation verdict and the summary line" \
  "      < PASS  IANA problem+json cites RFC9457|      > FAIL  IANA problem+json does not cite RFC9457|      < PASS 65  FAIL 0  SKIP 0  TOTAL 65|      > PASS 64  FAIL 1  SKIP 0  TOTAL 65|" \
  "$($GREP -E '^      [<>] ' "$scratch/archive-check.log" | tr '\n' '|')"
assert "registry.sh (rerun from the extraction) summary" "PASS 64  FAIL 1  SKIP 0  TOTAL 65" \
  "$(summary_of "$cev/registry-archive.log")"
assert "registry.sh rerun: its only FAIL is the IANA citation literal" \
  "FAIL  IANA problem+json does not cite RFC9457|" \
  "$($GREP -E '^FAIL  ' "$cev/registry-archive.log" | tr '\n' '|')"
assert "probe.sh (rerun from the extraction) summary" "PASS 33  FAIL 0  SKIP 0  TOTAL 33" \
  "$(summary_of "$cev/probe-archive.log")"
# The substance of the IANA claim, re-fetched with a whitespace-tolerant match.
iana_code="$(curl -sS -m 40 -A 'https://github.com/smorinlabs/rs-launch-blueprint' \
  -o "$scratch/iana.csv" -w '%{http_code}' https://www.iana.org/assignments/media-types/application.csv || true)"
assert "IANA application media types CSV HTTP" "200" "$iana_code"
for t in json xml; do
  row="$($GREP -E "^problem\\+$t,application/problem\\+$t," "$scratch/iana.csv" || true)"
  printf 'NOTE  IANA row: %s\n' "$row"
  if printf '%s' "$row" | $GREP -qE 'RFC ?9457'; then ok "IANA problem+$t cites RFC 9457 (whitespace-tolerant)"
  else bad "IANA problem+$t does not cite RFC 9457"; fi
done

############################################################
printf -- '\n--- 2. probe-r2.sh, in place, output captured\n'
############################################################
if "$here/probe-r2.sh" > "$scratch/probe-r2.log" 2>&1; then ok "probe-r2.sh exited 0"
else bad "probe-r2.sh exited non-zero"; tail -40 "$scratch/probe-r2.log"; fi
assert "probe-r2.sh summary" "PASS 25  FAIL 0  SKIP 0  TOTAL 25" "$(summary_of "$scratch/probe-r2.log")"
if diff <(verdicts "$here/probe-r2.log") <(verdicts "$scratch/probe-r2.log") > "$scratch/probe-r2.diff"; then
  ok "probe-r2.sh verdict, body and catalog lines are identical to the committed probe-r2.log"
else
  bad "probe-r2.sh verdict lines differ from the committed log:"; sed 's/^/    /' "$scratch/probe-r2.diff"
fi
printf -- '--- probe-r2.sh banner (moves by design)\n'
sed -n '2,5p' "$scratch/probe-r2.log" | sed 's/^/    /'

############################################################
printf -- '\n--- 3. rest-r2.sh, in place against the current DECISION.md\n'
############################################################
if "$here/rest-r2.sh" > "$scratch/rest-r2.log" 2>&1; then ok "rest-r2.sh exited 0"
else bad "rest-r2.sh exited non-zero"; tail -40 "$scratch/rest-r2.log"; fi
assert "rest-r2.sh summary" "PASS 79  FAIL 0  SKIP 0  TOTAL 79" "$(summary_of "$scratch/rest-r2.log")"
if diff <(verdicts "$here/rest-r2.log") <(verdicts "$scratch/rest-r2.log") > "$scratch/rest-r2.diff"; then
  ok "rest-r2.sh verdict lines are identical to the committed rest-r2.log"
else
  bad "rest-r2.sh verdict lines differ from the committed log:"; sed 's/^/    /' "$scratch/rest-r2.diff"
fi
printf -- '--- rest-r2.sh group C, this run\n'
sed -n '/^--- C\./,/^=== summary/p' "$scratch/rest-r2.log" | sed 's/^/    /'

############################################################
printf -- '\n--- 4. no committed log moved\n'
############################################################
( cd "$here" && for f in $committed; do shasum -a 256 "$f"; done ) > "$scratch/after.sha"
if diff "$scratch/before.sha" "$scratch/after.sha" > "$scratch/sha.diff"; then
  ok "all $(wc -l < "$scratch/after.sha" | tr -d ' ') committed evidence files are byte-identical after the reruns"
else
  bad "a committed evidence file changed:"; sed 's/^/    /' "$scratch/sha.diff"
fi

printf '\n=== summary ===\nPASS %d  FAIL %d  SKIP %d  TOTAL %d\n' \
  "$PASS" "$FAIL" "$SKIP" "$((PASS+FAIL+SKIP))"
[ "$FAIL" -eq 0 ]
