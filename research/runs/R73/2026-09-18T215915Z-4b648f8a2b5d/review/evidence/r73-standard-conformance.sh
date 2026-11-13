#!/usr/bin/env bash
# R73 — quotes every org REST API Design Standard rule this decision relies on,
# at its line, out of the pinned blob, and asserts the text it is relied on for.
#
# Binding pin (owner ruling W2-REST, 2026-09-18):
#   repo   /Users/stevemorin/c/rest-standards
#   commit 0850d43e45d919ef5e37f7174c4212b46013c49f
#   blob   71bd813c1cf61286586b4ee41ed83ff065e5c8d9  (rest-api-standard.md)
# Single quotes below are deliberate: the expected substrings are markdown that
# contains literal backticks, which must not be read as command substitution.
# shellcheck disable=SC2016

set -euo pipefail

GREP=/usr/bin/grep
STANDARD_REPO=${R73_STANDARD_REPO:-/Users/stevemorin/c/rest-standards}
COMMIT=0850d43e45d919ef5e37f7174c4212b46013c49f
BLOB=71bd813c1cf61286586b4ee41ed83ff065e5c8d9

PASS=0; FAIL=0; SKIP=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s — %s\n' "$1" "$2"; }

printf '== R73 standard conformance ==\n'
printf 'grep: %s\n' "$("$GREP" --version | head -1)"
printf 'date_utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'standard_repo: %s\n' "$STANDARD_REPO"

SNAPSHOT=$(mktemp -t r73std)
trap 'rm -f "$SNAPSHOT"' EXIT

if [ ! -d "$STANDARD_REPO" ]; then
  skip C0-repo "the standard clone is absent at $STANDARD_REPO; every C-check below is skipped"
  skip C0-blob "blob identity unverifiable without the clone"
  printf '\nCHECKS RUN: %s PASS: %s FAIL: %s SKIP: %s\n' "$((PASS + FAIL + SKIP))" "$PASS" "$FAIL" "$SKIP"
  exit 0
fi

# --- identity -----------------------------------------------------------------
if git -C "$STANDARD_REPO" cat-file -e "$COMMIT^{commit}" 2>/dev/null; then
  pass C0-commit "commit $COMMIT exists in the standard clone"
else
  fail C0-commit "commit $COMMIT is absent"
fi

if git -C "$STANDARD_REPO" show "$BLOB" > "$SNAPSHOT" 2>/dev/null && [ -s "$SNAPSHOT" ]; then
  pass C0-blob "blob $BLOB reads back $(wc -l < "$SNAPSHOT" | tr -d ' ') lines"
else
  fail C0-blob "blob $BLOB does not read back"
  printf '\nCHECKS RUN: %s PASS: %s FAIL: %s SKIP: %s\n' "$((PASS + FAIL + SKIP))" "$PASS" "$FAIL" "$SKIP"
  exit 1
fi

ACTUAL_BLOB=$(git -C "$STANDARD_REPO" rev-parse "$COMMIT:rest-api-standard.md" 2>/dev/null || echo none)
if [ "$ACTUAL_BLOB" = "$BLOB" ]; then
  pass C0-bind "rest-api-standard.md at $COMMIT is exactly blob $BLOB"
else
  fail C0-bind "rest-api-standard.md at $COMMIT is $ACTUAL_BLOB, not $BLOB"
fi

if "$GREP" -q '^\*\*Version 2\.0\.0\.\*\*' "$SNAPSHOT"; then
  pass C0-version "the pinned blob declares Version 2.0.0"
else
  fail C0-version "the pinned blob does not declare Version 2.0.0"
fi

# --- quoting helper -----------------------------------------------------------
# quote <check-id> <line> <expected-substring> <why>
# Reads the pinned blob at exactly that line and asserts the substring is there.
# Fails when the line moved, so a standard revision cannot silently invalidate a
# citation.
quote() {
  local id=$1 line=$2 expect=$3 why=$4 actual
  actual=$(sed -n "${line}p" "$SNAPSHOT")
  if [ -z "$actual" ]; then
    fail "$id" "line $line of the pinned blob is empty"
    return
  fi
  case "$actual" in
    *"$expect"*)
      pass "$id" "line $line carries \"$expect\" — $why"
      printf '        :%s: %s\n' "$line" "$actual"
      ;;
    *)
      fail "$id" "line $line does not carry \"$expect\"; it reads: $actual"
      ;;
  esac
}

printf '\n-- 1.6 / 1.7 / 1.8 / 1.9 applicability, deviation, reserved names --\n'
quote C1-R1.6 229 'Rules that only make sense for APIs with a given capability' 'switch vocabulary governs the streaming scope declaration'
quote C1-R1.7 271 'An API deviates from this standard only in' 'no silent deviation; a SHOULD departure is recorded'
quote C1-R1.8 312 'MUST NOT use a reserved' 'reservation discipline, which Idempotency-Key is inside'
quote C1-R1.9 318 '`dry_run` is reserved standard-wide' 'the dry-run guard the layer must not consume a key for'
quote C1-hdr 347 '`Idempotency-Key` | Request |' 'the reserved request header this layer reads'
quote C1-draft 347 'never cite it as a standard' 'the expired IETF draft is evidence, never authority'

printf '\n-- 3.1 / 3.2 method semantics --\n'
quote C2-R3.1 582 'MUST be' 'method and status semantics are cited from RFC 9110/9111'
quote C2-R3.3 597 'registered safety and idempotence' 'the scope rule for which methods carry a key'

printf '\n-- 3.4 idempotency keys: the directly-on-point section --\n'
quote C3-head 649 '### 3.4 Idempotency keys' 'the section heading is where this decision says it is'
quote C3-R3.9a 651 'MUST accept an idempotency key' 'accepting the key is mandatory on non-idempotent state change'
quote C3-R3.9b 652 '`Idempotency-Key` request header' 'the header spelling is fixed by the standard'
quote C3-R3.9c 653 'the server fingerprints the request payload' 'a payload fingerprint is mandatory, not optional'
# Revision 2: the "(Stripe semantics)" parenthetical sits on the same line and is
# bounded by the colon that follows it — fingerprint, replay, reject. It names
# the key-and-replay shape, not a status allow-list, so 2xx-only conforms.
quote C3-R3.9-stripe 653 '(Stripe semantics): the server fingerprints' 'the parenthetical is defined by the three duties after its colon, none of which is a status rule'
quote C3-R3.9d 654 'the stored response for a genuine retry' 'replay is the required behaviour'
quote C3-R3.9e 655 'a different payload' 'a reused key with a different payload is rejected'
quote C3-exempt 661 '**Header exemption.**' 'the URI-names-the-work relaxation, not used here'
quote C3-retain 668 'The stated retention window MUST be at least' 'the 24-hour retention floor'
quote C3-stream 671 'For a streaming request' 'the streaming clause, scoped by the §1.8 streaming switch'
quote C3-policy 673 '`[POLICY]` This convention has no standards backing' 'the section is house policy, not protocol'
quote C3-expired 674 'expired 2026-04-18' 'the draft expiry the standard itself records'
quote C3-redact 675 'cited as a standard' 'the draft must not be cited as a standard'

printf '\n-- 3.6 dry-run --\n'
quote C4-R3.12 716 'A mutating endpoint that offers a rehearsal' 'the dry-run contract'
quote C4-key 728 'MUST NOT consume an' 'a rehearsal never consumes a key'

printf '\n-- 4.2 / 4.4 representation and extension hygiene --\n'
quote C5-R4.3 762 'object at the top level' 'error bodies are objects, which R70 owns'
quote C5-R4.12 880 'RFC 9651 structured' 'new header fields use structured field types'
quote C5-R4.17 868 'Access-Control-Expose-Headers' 'the CORS exposure duty handed to R76'

printf '\n-- 5.1 / 5.2 / 5.3 statuses and errors --\n'
quote C6-R5.1 916 'MUST match the registered semantics' 'the status matches the outcome known when generated'
quote C6-R5.1b 918 'operation MUST NOT return 2xx' 'why a failure is never stored as a replayable 2xx'
quote C6-R5.2 934 'Unregistered status codes MUST NOT' 'every status used here is registered'
quote C6-R5.3a 939 '`422 Unprocessable Content` SHOULD be used for semantically' 'the 422 assignment, derived from the standard not the draft'
quote C6-R5.3b 941 'current resource state' 'the 409 assignment'
quote C6-R5.3c 941 '`400 Bad Request` remains correct for malformed' 'the 400 assignment'
quote C6-R5.6 967 '`201 Created` with a `Location` header' 'a replayed create must still carry Location'
quote C6-R5.12 1020 'as `application/problem+json`' 'error bodies are R70 problem documents'
quote C6-R5.13 1049 'MUST carry' 'the problem-document member set R70 owns'
quote C6-R5.13-5 1076 '5. `type` MUST be present on every problem document, and `about:blank`' 'the point R70 revision 1 missed and R70 revision 4 now meets (move M-1)'

printf '\n-- 11 retryability and observability --\n'
quote C7-R11.6 1743 'MUST document which failure classes are retryable' 'the 2xx-only rule is what this documents'
quote C7-R11.7 1752 'MUST carry the `request-id`' 'why a replay must not carry a stale correlation id'

# --- the one MUST-level tension, asserted as content --------------------------
printf '\n-- derived conformance assertions --\n'
if sed -n '668,670p' "$SNAPSHOT" | tr '\n' ' ' | "$GREP" -q 'MUST be at least[[:space:]]*24 hours'; then
  pass C8-retention 'the retention floor is 24 hours, which the recommended entry ttl of 86400 s meets exactly'
else
  fail C8-retention 'the 24-hour retention floor did not read back from lines 668-670'
fi

if sed -n '651,659p' "$SNAPSHOT" | tr '\n' ' ' | "$GREP" -q 'naturally idempotent operations (PUT'; then
  pass C8-put 'R3.9 exempts a representation-storing PUT, so including PUT in scope is a permitted superset'
else
  fail C8-put 'the PUT exception did not read back from R3.9'
fi

# A control: a rule this decision does NOT rely on must still be findable, so a
# failure above cannot be a blanket read failure of the snapshot.
quote C9-control 1098 'RFC 7807 MUST NOT be cited' 'control — an unrelated rule reads back, so the quoting mechanism works'

printf '\nCHECKS RUN: %s PASS: %s FAIL: %s SKIP: %s\n' "$((PASS + FAIL + SKIP))" "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
