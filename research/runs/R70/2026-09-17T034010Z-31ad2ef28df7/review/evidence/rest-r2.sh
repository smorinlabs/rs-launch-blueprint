#!/usr/bin/env bash
# R70 revision 2 — the REST API Design Standard v2.0.0 checks.
#
# Group A: every rule this decision quotes is asserted AT ITS LINE in the
#          pinned blob, so a quotation cannot drift from its source.
# Group B: every revision-1 script and log is byte-identical, asserted by
#          sha256 rather than by inspection.  Revision 1's scripts are not
#          re-run by this script.
# Group C: the OVERRIDE numbering search, with a non-vacuous control.
#
# Asserts on CONTENT.  PASS/FAIL/SKIP counted and summed; non-zero on FAIL.
#
# shellcheck disable=SC2016  # the expected rule lines are quoted VERBATIM from
# the standard and contain backticks; expansion would corrupt the comparison.
set -euo pipefail
set -o pipefail

GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }
skip() { SKIP=$((SKIP+1)); printf 'SKIP  %s\n' "$1"; }
assert() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1: expected [$2] got [$3]"; fi; }

STD_REPO="${REST_STANDARDS_REPO:-$HOME/c/rest-standards}"
BLOB=71bd813c1cf61286586b4ee41ed83ff065e5c8d9
COMMIT=0850d43e45d919ef5e37f7174c4212b46013c49f

here="$(cd "$(dirname "$0")" && pwd)"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/r70-rest-r2.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
STD="$scratch/rest-api-standard.md"

printf '=== R70 revision 2 — REST standard conformance evidence ===\n'
printf 'date (UTC): %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'grep: %s\n' "$($GREP --version | head -1)"
printf 'standard repo: %s\n' "$STD_REPO"
printf 'blob: %s\n' "$BLOB"
printf 'commit: %s\n\n' "$COMMIT"

# has_phrase <file> <phrase>: whitespace-collapsing literal match, because the
# standard is hard-wrapped and a sentence spans line breaks.
has_phrase() { python3 -c '
import re, sys
text = re.sub(r"\s+", " ", open(sys.argv[1], encoding="utf-8").read())
sys.exit(0 if sys.argv[2] in text else 1)
' "$1" "$2"; }
phrase() { if has_phrase "$2" "$3"; then ok "$1"; else bad "$1 — phrase absent: $3"; fi; }
# at_line <label> <line> <expected exact line>
at_line() {
  local actual; actual="$(sed -n "${2}p" "$STD")"
  if [ "$actual" = "$3" ]; then ok "$1 (line $2)"; else bad "$1: line $2 is [$actual] not [$3]"; fi
}

############################################################
printf -- '--- A. the standard at the pinned blob\n'
############################################################
if [ ! -d "$STD_REPO/.git" ] && [ ! -e "$STD_REPO/.git" ]; then
  skip "the standard's clone is absent at $STD_REPO (set REST_STANDARDS_REPO)"
  printf '\n=== summary ===\nPASS %d  FAIL %d  SKIP %d  TOTAL %d\n' \
    "$PASS" "$FAIL" "$SKIP" "$((PASS+FAIL+SKIP))"
  exit 1
fi
assert "the blob exists and is a blob" "blob" "$(git -C "$STD_REPO" cat-file -t "$BLOB" 2>/dev/null || echo missing)"
git -C "$STD_REPO" show "$BLOB" > "$STD"
assert "the extracted file hashes back to the pinned blob" "$BLOB" \
  "$(git -C "$STD_REPO" hash-object "$STD")"
assert "the pinned commit carries this blob as rest-api-standard.md" "$BLOB" \
  "$(git -C "$STD_REPO" rev-parse "$COMMIT:rest-api-standard.md" 2>/dev/null || echo missing)"
assert "the standard declares version 2.0.0" "2.0.0" \
  "$($GREP -m1 -oE 'v?2\.0\.0' "$STD" | tr -d 'v' | head -1)"
printf 'lines in blob: %s\n' "$(wc -l < "$STD" | tr -d ' ')"

############################################################
printf -- '\n--- A1. section 1.4 / 1.8 / 1.9 / 1.10 — requirement language, switches, deviations, reserved names\n'
############################################################
at_line "R1.1 requirement language" 128 \
  '**R1.1** The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**,'
phrase "R1.1: BCP 14 keywords bind only when they appear in all capitals" "$STD" \
  "are to be interpreted as described in RFC 2119 and RFC 8174 when, and only when, they appear in all capitals"
at_line "R1.6 applicability switches" 229 \
  '**R1.6** Rules that only make sense for APIs with a given capability are'
phrase "R1.6: a switch declared off MUST carry a stated reason" "$STD" \
  'A declaration that a switch is off — taking its rules as not applicable — MUST carry a stated reason in the conformance note (the N/A-with-reason discipline): "N/A" with no reason is a deviation, not an exemption.'
phrase "R1.6: the switch vocabulary is four names" "$STD" \
  "The switch vocabulary: \`webhooks\` · \`async-operations\` · \`bulk-operations\` · \`streaming\`."
phrase "R1.6: a switch never waives a per-endpoint guard" "$STD" \
  "A rule whose whole purpose is to define what an API without the capability must do is not scoped by that capability's switch"
at_line "R1.7 no silent deviation" 271 \
  '**R1.7 — No silent deviation.** An API deviates from this standard only in'
phrase "R1.7: silent deviation at any strength is nonconformance" "$STD" \
  "silent deviation from any rule strength is nonconformance regardless of the deviation's merits"
at_line "R1.8 reservation discipline" 312 \
  '**R1.8 — Reservation discipline.** A conforming API MUST NOT use a reserved'
at_line "R1.9 dry_run rejection guard" 318 \
  '**R1.9 — `dry_run` rejection guard.** `dry_run` is reserved standard-wide:'
phrase "R1.9: dry_run to an endpoint that does not implement it MUST be rejected with 400" "$STD" \
  "a mutating request carrying the \`dry_run\` parameter — with any value — to an endpoint that does not implement dry-run MUST be rejected with \`400\`"
phrase "reserved response header: request-id on every response including errors" "$STD" \
  "Correlation ID, emitted on every response including errors"

############################################################
printf -- '\n--- A2. section 4.2 to 4.4 — representation, negotiation, extension hygiene\n'
############################################################
at_line "R4.3 object at the top level" 762 \
  '**R4.3** Every JSON response body MUST have an object at the top level —'
at_line "R4.4 snake_case body properties" 768 \
  '**R4.4** Body properties and query parameters MUST use snake_case — one'
phrase "R4.4: the body-property grammar" "$STD" \
  "enforced by pattern \`^[a-z_][a-z_0-9]*\$\` for body properties"
at_line "R4.8 null and omission" 818 \
  '**R4.8** The contract MUST state explicitly how null and omission are'
at_line "R4.10 default media type" 846 \
  '**R4.10** The default media type — served when a request carries no'
# The standard itself rules that R4.10's default clause carries no BCP 14
# keyword.  That is why this decision records NO override against it.
phrase "R4.10's default clause carries no BCP 14 keyword (the standard says so)" "$STD" \
  "R4.10's default clause carries no BCP 14 keyword, so this is a taxonomy hole rather than a live conflict."
at_line "R4.11 Vary on negotiated responses" 856 \
  '**R4.11** Every response whose content was selected by a request header'
phrase "R4.11's exception: responses with no negotiation" "$STD" \
  "**Exception:** responses with no negotiation."

############################################################
printf -- '\n--- A3. section 5.1 and 5.2 — status-code discipline and the operation map\n'
############################################################
at_line "R5.1 status matches the outcome" 916 \
  '**R5.1** The status code MUST match the registered semantics of the'
phrase "R5.1: a failed operation MUST NOT return 2xx" "$STD" \
  "A failed operation MUST NOT return 2xx."
at_line "R5.2 no unregistered status codes" 934 \
  '**R5.2** Unregistered status codes MUST NOT be defined or used.'
at_line "R5.3 the 422 / 409 / 400 split" 939 \
  '**R5.3** `422 Unprocessable Content` SHOULD be used for semantically'
phrase "R5.3: 400 remains correct for malformed syntax" "$STD" \
  "\`400 Bad Request\` remains correct for malformed syntax."
at_line "R5.9 401 versus 403" 994 \
  '**R5.9** `401 Unauthorized` means unauthenticated; `403 Forbidden` means'
phrase "R5.9: the two MUST NOT be conflated" "$STD" \
  "authenticated but unauthorized. The two MUST NOT be conflated."
at_line "R5.10 cross-tenant existence masking" 1000 \
  '**R5.10** An object-level authorization denial defaults to'
at_line "R5.11 Allow, 415, 428" 1008 \
  '**R5.11** `405 Method Not Allowed` MUST carry an `Allow` header.'
phrase "R5.11: 415 answers an unsupported request media type" "$STD" \
  "\`415 Unsupported Media Type\` is the response to an unsupported request media type"

############################################################
printf -- '\n--- A4. section 5.3 — the rules that move this recommendation\n'
############################################################
at_line "R5.12 every application error servable as problem+json" 1019 \
  '**R5.12** Every API MUST be capable of returning every error response the'
phrase "R5.12: the infrastructure carve-out MUST be documented as such" "$STD" \
  "errors emitted by infrastructure components outside application control — reverse proxies, CDNs, WAFs, rate limiters, load balancers terminating before application code — which MUST be documented as such"
phrase "R5.12: application/json mirroring is neither required nor forbidden" "$STD" \
  "this standard neither requires nor forbids it"
at_line "R5.13 the required member set" 1049 \
  '**R5.13** Every problem document **carried in an HTTP response** MUST carry'
phrase "R5.13: type, title, status and a stable machine-readable code" "$STD" \
  "MUST carry \`type\`, \`title\`, \`status\`, and a stable machine-readable \`code\` extension member"
phrase "R5.13.1: type is an https URI under a domain the provider controls" "$STD" \
  "\`type\` is a stable absolute \`https\` URI **under a domain the provider controls**"
phrase "R5.13.1: the fixed template binding type to code" "$STD" \
  "bound by the fixed template \`<https base>/<code, underscores to hyphens>\`"
phrase "R5.13.1: the code grammar" "$STD" \
  "The \`code\` grammar is \`^[a-z][a-z0-9_]*\$\` (snake_case, hyphens excluded), so the underscore-to-hyphen mapping is injective."
phrase "R5.13.2: neither type nor code may change once published" "$STD" \
  "Neither \`type\` nor \`code\` may change once published"
phrase "R5.13.3: dereferencing type is a courtesy, never a contract" "$STD" \
  "Dereferencing \`type\` is a courtesy, never a contract"
phrase "R5.13.4: human documentation lives in a separate documentation member" "$STD" \
  "Human documentation lives in a separate \`documentation\` member"
# The rule revision 1 violated.
phrase "R5.13.5: type MUST be present and about:blank MUST NOT be used" "$STD" \
  "\`type\` MUST be present on every problem document, and \`about:blank\` MUST NOT be used"
at_line "R5.14 RFC 7807 never cited" 1098 \
  '**R5.14** RFC 7807 MUST NOT be cited — it is obsoleted by RFC 9457.'
phrase "R5.14's exception: historical notes explicitly labeled as such" "$STD" \
  "**Exception:** historical notes explicitly labeled as such."
at_line "R5.15 field-level errors[]" 1105 \
  '**R5.15** A validation failure covering one or more fields SHOULD carry a'
phrase "R5.15: an array of pointer, code and detail entries" "$STD" \
  "an array whose entries each carry a JSON Pointer to the offending input location (\`pointer\`), a stable machine-readable \`code\`, and a human-readable \`detail\`"
at_line "R5.16 the published catalog" 1114 \
  '**R5.16** An API MUST publish a catalog of every problem `type`/`code`'
at_line "R5.17 no internal detail in a response body" 1120 \
  '**R5.17** No response body may expose stack traces, query fragments,'
phrase "R5.17: query fragments are named among the banned content" "$STD" \
  "No response body may expose stack traces, query fragments, internal hostnames, or dependency detail."

############################################################
printf -- '\n--- A5. section 8.5 and 12.3 — redaction and the client obligation\n'
############################################################
at_line "R8.12 redaction" 1422 \
  '**R8.12** Secrets, credentials, and PII MUST NOT appear in problem'
phrase "R8.12: echoed request input is named explicitly" "$STD" \
  "Secrets, credentials, and PII MUST NOT appear in problem \`detail\`, in echoed request input, or in any other response content."
at_line "R12.6 clients ask for problem+json" 1815 \
  '**R12.6** Clients SHOULD send `Accept: application/problem+json`'
at_line "R12.7 clients never rely on a problem document" 1819 \
  '**R12.7** Clients MUST NOT rely on every error being a problem document:'

############################################################
printf -- '\n--- A6. the standard'"'"'s own worked error body (appendix E)\n'
############################################################
# The shape this revision adopts is the standard's own example, not an
# interpretation of it.
for member in '"type": "https://problems.example.com/validation-failed"' \
              '"code": "validation_failed"' \
              '"documentation": "https://developers.example.com/errors#validation_failed"' \
              '"pointer": "/amount"' \
              '"code": "below_minimum"'; do
  contains_ok=no
  $GREP -qF -- "$member" "$STD" && contains_ok=yes
  if [ "$contains_ok" = yes ]; then ok "appendix E error body carries $member"; else bad "appendix E error body lacks $member"; fi
done
phrase "appendix E reading: the human link lives in documentation, not in type" "$STD" \
  "the human link lives in \`documentation\`, not in \`type\`"

############################################################
printf -- '\n--- B. revision 1 artifacts carried byte-identical\n'
############################################################
# Revision 1's scripts and logs are NOT re-run by revision 2; they are pinned.
while read -r want file; do
  [ -z "${want:-}" ] && continue
  if [ ! -f "$here/$file" ]; then bad "revision-1 artifact missing: $file"; continue; fi
  got="$(shasum -a 256 "$here/$file" | cut -d' ' -f1)"
  assert "revision-1 $file is byte-identical" "$want" "$got"
done <<'SHA'
a809a78f15967377ed66940c368ac37caeadad73b08db8b3f1db94e40a4ff644 registry.sh
36a8d9a11c512322c3ee5596f343935535470fd6708d11d602443bf1016bb266 registry.log
3c20aab7c90a408259d25f0db1a3d95b6494cf460889bbf05e8590f37bcef207 registry-figures.log
dcdce29e6d48f32c3d154a610cacd9fa569407226a858831e8a8d73d4fb45ffb probe.sh
ed0abb66056029d18aa16ea4849df0ad3dd942084526d22db87cc9a1136265b1 probe.log
f1e890029c44868021922adf270e56d33f9c4011c52971e2b370549fca62573d archive-check.sh
a272b4b9d18086684781acb299e286d286fec064891ca136113a52e88c98da21 archive-check.log
36a8d9a11c512322c3ee5596f343935535470fd6708d11d602443bf1016bb266 registry-archive.log
89bed9213c70279194850a380d96346d90d1c7b008c2bbe20fb90d79f83a3da3 probe-archive.log
SHA

############################################################
printf -- '\n--- C. OVERRIDE numbering\n'
############################################################
root="$(git -C "$here" rev-parse --show-toplevel)"
mine="research/runs/R70/2026-09-17T034010Z-31ad2ef28df7"
count_ov() {
  ( cd "$root" && $GREP -rl "OVERRIDE ($1)" --include="DECISION.md" docs/ research/ 2>/dev/null |
      $GREP -v "^$mine/" | sort -u | wc -l | tr -d ' ' )
}
# This revision declares NO override, so it claims no number.  The search is
# recorded anyway, so a later reader knows which number is free and does not
# have to redo it.  OV-04 was free when this analysis began and was taken by
# R80 while it ran, which is exactly why the number is recorded, not assumed.
for n in OV-01 OV-02 OV-03 OV-04; do
  c="$(count_ov $n)"
  if [ "$c" -ge 1 ]; then ok "$n is claimed by $c decision(s) outside this item"
  else bad "$n expected to be claimed and is not — the numbering search is broken"; fi
done
assert "OV-05 is the next free number: claimed by no decision outside this item" "0" "$(count_ov OV-05)"
assert "OV-06 is likewise free" "0" "$(count_ov OV-06)"
# This revision declares no override; assert that too, so the claim is checkable.
if [ -f "$here/../DECISION.md" ]; then
  n="$($GREP -c "OVERRIDE (OV-" "$here/../DECISION.md" || true)"
  printf 'NOTE  DECISION.md mentions "OVERRIDE (OV-" %s time(s) (headings are counted separately below)\n' "$n"
  h="$($GREP -c "^### OVERRIDE (OV-" "$here/../DECISION.md" || true)"
  assert "this decision declares no OVERRIDE heading" "0" "$h"
else
  skip "DECISION.md not present beside the evidence directory"
fi

printf '\n=== summary ===\n'
printf 'PASS %d  FAIL %d  SKIP %d  TOTAL %d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS+FAIL+SKIP))"
if [ "$FAIL" -ne 0 ]; then exit 1; fi
exit 0
