#!/usr/bin/env bash
# R74 — the org REST API Design Standard v2.0.0 rules this decision relies on, each
# asserted to exist at the line the decision cites, in the pinned blob.
#
# Binding input: owner ruling W2-REST (docs/port/OWNER-REVIEW.md, 2026-09-18).
# Pin: repo https://github.com/smorinlabs/rest-standards, commit
# 0850d43e45d919ef5e37f7174c4212b46013c49f, file blob 71bd813c1cf61286586b4ee41ed83ff065e5c8d9.
#
# It reads the SNAPSHOT (snapshots/rest-api-standard.md) so the line numbers this decision
# cites cannot drift under it, and separately re-reads the blob from the local clone when
# one is present, asserting the two are byte-identical. Output is reproducible byte-for-byte
# except for the one line that names the local clone's presence, which is a SKIP when absent.
#
# Revision 2 (judgment audit finding 2): revision 1 labelled section numbers as rule IDs.
# §1.8 (line 227) carries rule R1.6, §1.9 (line 269) carries R1.7, and §1.10 (line 301)
# carries R1.8; no rule R1.10 exists. The labels below are corrected, the section headings
# and rule IDs are themselves asserted, and R1.7's full sentence is asserted so the
# 'regardless of the deviation's merits' clause is read as scoped to silent deviation.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="$HERE/snapshots/rest-api-standard.md"
STD_REPO="/Users/stevemorin/c/rest-standards"
STD_BLOB="71bd813c1cf61286586b4ee41ed83ff065e5c8d9"
STD_COMMIT="0850d43e45d919ef5e37f7174c4212b46013c49f"

PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); echo "PASS  $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL  $1"; }
skip() { SKIP=$((SKIP+1)); echo "SKIP  $1"; }

# at <label> <line> <substring>  — the substring must appear on exactly that line
at() {
  local label="$1" line="$2" needle="$3" actual
  actual="$(sed -n "${line}p" "$SNAP")"
  if printf '%s' "$actual" | /usr/bin/grep -qF -- "$needle"; then
    ok "$label  line $line carries: $needle"
  else
    bad "$label  line $line does NOT carry [$needle]; it reads: ${actual:0:120}"
  fi
}

echo "grep: $(/usr/bin/grep --version | head -1)"
if [ ! -f "$SNAP" ]; then
  echo "FATAL: $SNAP is absent; run r74-fetch-snapshots.sh"
  exit 1
fi
echo "snapshot: $SNAP ($(/usr/bin/grep -c . "$SNAP") non-empty lines of $(wc -l < "$SNAP" | tr -d ' ') total)"
echo

echo "=== 0. the pin ==="
if [ -e "$STD_REPO/.git" ]; then
  if git -C "$STD_REPO" cat-file -e "$STD_BLOB" 2>/dev/null; then ok "P0a blob $STD_BLOB exists in the local clone"; else bad "P0a blob $STD_BLOB not found"; fi
  if [ "$(git -C "$STD_REPO" rev-parse "$STD_COMMIT" 2>/dev/null)" = "$STD_COMMIT" ]; then ok "P0b commit $STD_COMMIT exists in the local clone"; else bad "P0b commit $STD_COMMIT not found"; fi
  if [ "$(git -C "$STD_REPO" rev-parse "$STD_COMMIT:rest-api-standard.md" 2>/dev/null)" = "$STD_BLOB" ]; then ok "P0c rest-api-standard.md at that commit IS that blob"; else bad "P0c the commit's rest-api-standard.md is a different blob"; fi
  if git -C "$STD_REPO" cat-file blob "$STD_BLOB" | diff -q - "$SNAP" > /dev/null 2>&1; then ok "P0d the snapshot is byte-identical to the pinned blob"; else bad "P0d the snapshot has drifted from the pinned blob"; fi
else
  skip "P0a-d — $STD_REPO is not a git clone here; the snapshot is the only copy"
fi
# Control: the reader must be able to fail. A line that does not carry a needle must be reported.
if sed -n '1p' "$SNAP" | /usr/bin/grep -qF 'R11.2 An API MUST apply rate limits'; then
  bad "P0-control line 1 unexpectedly carries an R11.2 string — the locator is not discriminating"
else
  ok  "P0-control line 1 does not carry R11.2's text, so the locators below are positional and can fail"
fi

echo
echo "=== 1. rules this decision CONFORMS to ==="
at "R11.2"      1686 'An API MUST apply rate limits and communicate exhaustion via'
at "R11.2b"     1687 '429 Too Many Requests'
at "R11.2c"     1688 'deliberate tightening of RFC 6585'
at "R11.3"      1701 'in the syntax of'
at "R11.3b"     1702 'draft-ietf-httpapi-ratelimit-headers-11'
at "R11.3c"     1703 'unpublished Internet-Draft, not a standard'
at "R11.4"      1707 'Any proprietary quota headers MUST be documented explicitly'
at "R11.5"      1724 '429` signals quota exhaustion'
at "R11.5b"     1725 'both MUST carry'
at "R5.12"      1019 'MUST be capable of returning every error response the'
at "R5.12-carve" 1023 'reverse proxies, CDNs, WAFs, rate limiters, load balancers terminating'
at "R5.13"      1049 'MUST carry'
at "R5.14"      1098 'RFC 7807 MUST NOT be cited'
at "R5.16"      1114 'MUST publish a catalog of every problem'
at "R12.2"      1784 'Clients MUST honor'
at "R1.8-sec"   301  '### 1.10 Reserved names'
at "R1.8"       312  '**R1.8 — Reservation discipline.** A conforming API MUST NOT use a reserved'
at "R1.8-hdr"   352  'Mandatory on'
at "R1.8-rl"    353  'SHOULD advertise quota state'
at "R1.8-noX"   362  'No new'
at "R1.6-sec"   227  '### 1.8 Applicability switches'
at "R1.6"       229  '**R1.6** Rules that only make sense for APIs with a given capability are'
at "R1.6b"      231  'A rule scoped to a switch binds only'
at "R1.6-vocab" 237  'The switch vocabulary:'

echo
echo "=== 2. the rule this decision DEPARTS from, and the deviation shape ==="
at "R8.10"      1387 'Each axis below carries a ratified default and named'
at "R8.10b"     1388 'threat-model flip triggers. An API MUST adopt each axis default unless a'
at "R8.10c"     1389 'named trigger applies, and MUST record any flip in its conformance note.'
at "R8.10-axis" 1397 'Multi-dimensional tiered posture, published: per-principal sustained + token-bucket burst'
at "R8.10-num"  1397 '100 rps/account, 25 rps/endpoint'
at "R8.10-unauth" 1397 'unauthenticated per-IP an order of magnitude lower'
at "R1.7-sec"   269  '### 1.9 Deviations and the conformance note'
at "R1.7"       271  '**R1.7 — No silent deviation.**'
at "R1.7b"      273  'A deviation from a **MUST** makes the API'
at "R1.7c"      274  'nonconformant unless it is recorded as an approved exception in the'
at "R1.7d"      275  'silent deviation from any rule strength is nonconformance'
at "R1.7e"      276  "regardless of the deviation's merits."
at "R1.9-shape" 291  'rule strength'

echo
echo "=== 3. the §1.8 (R1.6) switch vocabulary has no rate-limiting member ==="
# R11.2 is NOT switch-scoped, which is why off-by-default cannot be an N/A-with-reason.
if sed -n '1684,1740p' "$SNAP" | /usr/bin/grep -qE 'scoped by|applicability switch'; then
  bad "S3a §11.2's block mentions an applicability switch — R11.2 may be switch-scoped after all"
else
  ok  "S3a §11.2 carries no applicability-switch scoping, so R11.2 binds unconditionally"
fi
if sed -n '237,238p' "$SNAP" | /usr/bin/grep -qiE 'rate|throttl'; then
  bad "S3b the switch vocabulary names a rate-limiting switch"
else
  ok  "S3b the switch vocabulary (webhooks, async-operations, bulk-operations, streaming) has no rate-limiting member"
fi

echo
echo "=== 4. the standard's own 429 example, for the body this item renders through R70 ==="
at "E9a" 3198 'HTTP/1.1 429 Too Many Requests'
at "E9b" 3199 'Retry-After: 30'
at "E9c" 3208 'rate_limit_exceeded'
# R5.13's `code` grammar, which R67's RSLB### catalog does not match. Recorded, not resolved here.
if /usr/bin/grep -qF 'grammar is' "$SNAP" && /usr/bin/grep -qF '[a-z][a-z0-9_]*' "$SNAP"; then
  ok "S4a R5.13 fixes the problem-code grammar as the snake_case regex [a-z][a-z0-9_]*"
else
  bad "S4a the R5.13 code grammar string was not found"
fi

echo
echo "CHECKS RUN: $((PASS + FAIL + SKIP))  PASS: $PASS  FAILURES: $FAIL  SKIPPED: $SKIP"
[ "$FAIL" -eq 0 ]
