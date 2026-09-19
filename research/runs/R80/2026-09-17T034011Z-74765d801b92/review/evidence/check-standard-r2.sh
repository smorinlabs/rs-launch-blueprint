#!/usr/bin/env bash
# R80 revision 2 — the REST API Design Standard conformance check.
#
# Owner ruling W2-REST (2026-09-18) makes the organisation's REST API Design
# Standard v2.0.0 binding on this template's HTTP surface. This script does
# three things and nothing else:
#
#   S1..S26  quote-assert every rule this decision relies on, at the PINNED
#            blob 71bd813c1cf61286586b4ee41ed83ff065e5c8d9 of
#            /Users/stevemorin/c/rest-standards, at its recorded line number.
#            A rule whose text moved is a FAIL, not a silent re-read.
#   P1..P6   measure axum 0.8.9's behaviour for the six rules that can only be
#            settled by running it, in an r2 probe workspace under $TMPDIR.
#   C1..C9   assert this decision's own revision-2 claims: the OVERRIDE block,
#            the conformance note, the moved recommendation, and — the rule the
#            revision contract imposes — that every revision-1 script, log and
#            probe source is still BYTE-IDENTICAL.
#
# Usage: bash check-standard-r2.sh [repo-root]
# Exit status: 0 when no check FAILs, 1 otherwise.

set -euo pipefail

GREP=/usr/bin/grep
ROOT="${1:-}"
if [ -z "$ROOT" ]; then
  HERE0="$(cd "$(dirname "$0")" && pwd)"
  ROOT="$(cd "$HERE0/../../../../../.." && pwd)"
fi
HERE="$(cd "$(dirname "$0")" && pwd)"
RUN="research/runs/R80/2026-09-17T034011Z-74765d801b92"
DECISION="$ROOT/$RUN/review/DECISION.md"

STD_REPO=/Users/stevemorin/c/rest-standards
STD_BLOB=71bd813c1cf61286586b4ee41ed83ff065e5c8d9
STD_COMMIT=0850d43e45d919ef5e37f7174c4212b46013c49f

PASS=0
FAIL=0
SKIP=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s — %s\n' "$1" "$2"; }

echo "=== R80 check-standard-r2.sh ==="
echo "date(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "grep: $($GREP --version | head -1)"
echo "standard: $STD_REPO blob $STD_BLOB (commit $STD_COMMIT)"

STD=""
if [ -d "$STD_REPO/.git" ] || [ -e "$STD_REPO/.git" ]; then
  STD="$(mktemp "${TMPDIR:-/tmp}/r80-standard.XXXXXXXX")"
  if git -C "$STD_REPO" show "$STD_BLOB" >"$STD" 2>/dev/null && [ -s "$STD" ]; then
    echo "blob lines: $(wc -l <"$STD" | tr -d ' ')"
    echo "blob sha256: $(shasum -a 256 "$STD" | cut -d' ' -f1)"
  else
    rm -f "$STD"; STD=""
  fi
fi
cleanup() { [ -n "${STD:-}" ] && rm -f "$STD"; [ -n "${WORK:-}" ] && rm -rf "$WORK"; return 0; }
trap cleanup EXIT

# rule <id> <line> <literal fragment> <why this decision needs it>
rule() {
  local id="$1" line="$2" needle="$3" why="$4" got
  if [ -z "$STD" ]; then
    skip "$id" "the rest-standards clone is not at $STD_REPO, so the pinned blob cannot be read"
    return 0
  fi
  got="$(sed -n "${line}p" "$STD")"
  if printf '%s' "$got" | $GREP -qF -- "$needle"; then
    printf '  %s @ line %s: %s\n' "$id" "$line" "$got"
    pass "$id" "$why"
  else
    printf '  %s @ line %s (UNEXPECTED): %s\n' "$id" "$line" "$got"
    fail "$id" "$why — line $line does not carry the quoted text"
  fi
}

echo "--- S: the rules, quoted at the pinned blob ---"
rule S1  229  '**R1.6** Rules that only make sense for APIs with a given capability are' \
  "R1.6 scopes rules by applicability switch and makes an off-switch declaration carry a reason — the discipline this decision's conformance note follows"
rule S2  271  '**R1.7 — No silent deviation.** An API deviates from this standard only in' \
  "R1.7 makes an unrecorded deviation nonconformance regardless of merit — the rule that forces OV-04 to exist in writing"
rule S3  312  '**R1.8 — Reservation discipline.** A conforming API MUST NOT use a reserved' \
  "R1.8 governs reserved names; neither healthz nor readyz is a reserved name, and the probes assign no reserved name a new meaning"
rule S4  443  '**R2.1** An API MUST present a resource-oriented surface: noun resources,' \
  "R2.1 requires a resource-oriented surface with no RPC carve-out — the rule the two probe paths do not satisfy"
rule S5  456  "**R2.2** Collection resources MUST use plural nouns (\`/customers\`," \
  "R2.2's singleton exception is the only shape under which a single-valued ops path could conform, and it requires a documented singleton noun"
rule S6  467  '**R2.3** Resource names MUST be unabbreviated, and each concept MUST have' \
  "R2.3 forbids abbreviated resource names — healthz and readyz are coinages, not the business domain's nouns"
rule S7  477  "**R2.4** Path segments MUST use kebab-case (\`/sales-order-items\`), pattern" \
  "R2.4 fixes the path-segment grammar; both probe segments satisfy it"
rule S8  487  '**R2.5** Nest a sub-resource only where the child cannot exist outside its' \
  "R2.5 caps path depth at three resources; each probe path has one segment"
rule S9  499  '**R2.6** Canonical URIs have no trailing slash. A trailing slash MUST NOT' \
  "R2.6 prefers a 308 redirect from the trailing-slash form — the SHOULD this decision deviates from, measured by P3"
rule S10 525  '**R2.9** Path segments identify resources; query parameters modify the' \
  "R2.9 keeps operation modifiers out of path segments; the probes take no parameter at all"
rule S11 542  '**R2.11** A non-CRUD operation MUST use the sub-path verb form' \
  "R2.11 fixes the action form for operations that resist CRUD, which is the alternative modeling OV-04 rejects"
rule S12 693  '**R3.10** A resource that supports conditional update MUST emit a strong' \
  "R3.10's exception — resources never updated by clients — is why the probes owe no ETag under R7.3 tier 1"
rule S13 846  '**R4.10** The default media type — served when a request carries no' \
  "R4.10 fixes application/json as the default and prefers 406 over a silent substitution — measured by P4"
rule S14 856  '**R4.11** Every response whose content was selected by a request header' \
  "R4.11's exception — responses with no negotiation — is why the probes owe no Vary"
rule S15 916  '**R5.1** The status code MUST match the registered semantics of the' \
  "R5.1 requires the status to match the outcome, which is what 503-on-not-ready does"
rule S16 934  '**R5.2** Unregistered status codes MUST NOT be defined or used.' \
  "R5.2 bans unregistered codes; 200, 405 and 503 are all registered"
rule S17 1008 "**R5.11** \`405 Method Not Allowed\` MUST carry an \`Allow\` header." \
  "R5.11 turns T7's observation into a standard-bound MUST — measured by P6"
rule S18 1019 '**R5.12** Every API MUST be capable of returning every error response the' \
  "R5.12 requires application/problem+json for every application-generated error, which /readyz's 503 is"
rule S19 1049 '**R5.13** Every problem document **carried in an HTTP response** MUST carry' \
  "R5.13 fixes the problem document's required members — the rule that sharpens this item's requirement on R70"
rule S20 1114 "**R5.16** An API MUST publish a catalog of every problem \`type\`/\`code\`" \
  "R5.16 requires a published catalog, so /readyz's 503 needs a catalogued code"
rule S21 1120 '**R5.17** No response body may expose stack traces, query fragments,' \
  "R5.17 forbids internal detail in any response body — the constraint on what a diagnostics report may carry"
rule S22 1259 "**R7.1** Every response MUST carry an explicit \`Cache-Control\` header —" \
  "R7.1 is the MUST that moved this recommendation: revision 1 emitted no Cache-Control"
rule S23 1271 '**R7.2** Responses carrying user-specific or authenticated data MUST be' \
  "R7.2's genuinely-public exception is why the probes need no private marker"
rule S24 1281 '**R7.3** Within the mechanism above, the default posture is three-tier:' \
  "R7.3 fixes the posture tiers and names blanket no-store an anti-pattern — the ground for choosing no-cache"
rule S25 1435 '**R9.1** An API MUST use one uniform version-marker placement: the major' \
  "R9.1 requires the major version in the path — the MUST that F308's unversioned ops paths do not satisfy"
rule S26 1752 "**R11.7** Every response, including errors, MUST carry the \`request-id\`" \
  "R11.7 binds the probe responses too, so R75's correlation middleware may not skip them — measured by P5"

# The standard names no health, readiness or liveness rule anywhere. That
# absence is load-bearing: it is why conformance has to be argued from the
# general rules above rather than read off an ops carve-out.
if [ -n "$STD" ]; then
  HEALTH_RULES="$($GREP -ciE '^\*\*R[0-9]+\.[0-9]+.*(health|readiness|liveness|probe endpoint)' "$STD" || true)"
  echo "  rule lines naming health/readiness/liveness: $HEALTH_RULES"
  if [ "$HEALTH_RULES" -eq 0 ]; then
    pass S27 "no rule in the standard names health, readiness or liveness (0 matching rule lines, counted with $($GREP --version | head -1)) — there is no ops carve-out, so the probe surface is judged by the general rules above"
  else
    fail S27 "the standard now carries $HEALTH_RULES rule line(s) naming health/readiness/liveness; this decision's argument-from-general-rules must be redone"
  fi
else
  skip S27 "the pinned blob could not be read"
fi

echo "--- P: axum 0.8.9 measured in an r2 probe workspace ---"
if ! command -v cargo >/dev/null 2>&1; then
  for id in P1 P2 P3 P4 P5 P6; do skip "$id" "no cargo on PATH; the r2 probe workspace cannot be built"; done
else
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/r80-probe-r2.XXXXXXXX")"
  echo "workspace: $WORK (deleted on exit)"
  mkdir -p "$WORK/src" "$WORK/crates/core/src" "$WORK/crates/web/src" "$WORK/crates/web/tests"
  cp "$HERE/probe/facade-src/lib.rs" "$WORK/src/lib.rs"
  cp "$HERE/probe/core-src/lib.rs" "$WORK/crates/core/src/lib.rs"
  # r2 handler source, and ONLY the r2 test file: revision 1's probes.rs is not
  # re-run here, so its own committed log stays the artifact it was produced from.
  cp "$HERE/probe-r2/web-src/lib.rs" "$WORK/crates/web/src/lib.rs"
  cp "$HERE/probe-r2/web-tests/conformance.rs" "$WORK/crates/web/tests/conformance.rs"
  cp "$HERE/probe/manifests-b/facade.toml" "$WORK/Cargo.toml"
  cp "$HERE/probe/manifests-b/core.toml" "$WORK/crates/core/Cargo.toml"
  cp "$HERE/probe/manifests-b/web.toml" "$WORK/crates/web/Cargo.toml"
  # The facade's dev-dependency test needs a file; supply the r1 one unchanged so
  # the manifest resolves, but never run it here.
  mkdir -p "$WORK/tests"
  cp "$HERE/probe/facade-tests/version_hazard.rs" "$WORK/tests/version_hazard.rs"

  CARGO_FLAGS="--offline"
  if ! (cd "$WORK" && cargo metadata $CARGO_FLAGS --format-version 1 >/dev/null 2>&1); then
    echo "NOTE: --offline metadata failed; retrying without it"
    CARGO_FLAGS=""
  fi
  set +e
  (cd "$WORK" && cargo test $CARGO_FLAGS -p probe-web --test conformance -- --nocapture --test-threads=1) \
    >"$WORK/p.log" 2>&1
  P_STATUS=$?
  set -e
  cat "$WORK/p.log"
  if [ "$P_STATUS" -ne 0 ]; then
    echo "NOTE: the r2 probe suite exited $P_STATUS"
  fi
  p_ok() { $GREP -qE "^test ${1} \.\.\. " "$WORK/p.log" &&
           $GREP -qF 'test result: ok. 6 passed; 0 failed; 0 ignored' "$WORK/p.log"; }

  if p_ok p1_liveness_carries_cache_control &&
     $GREP -qF 'P1 GET /healthz status=200 OK cache-control=Some("no-cache") content-type=Some("application/json")' "$WORK/p.log"; then
    pass P1 "R7.1 and R4.10 CONFORM after the move: GET /healthz answers 200 with Cache-Control: no-cache and Content-Type: application/json"
  else
    fail P1 "the moved liveness handler does not emit the asserted Cache-Control and Content-Type"
  fi

  if p_ok p2_readiness_carries_cache_control_on_both_branches &&
     $GREP -qF 'P2 GET /readyz 200-branch cache-control=Some("no-cache"); 503-branch status=503 Service Unavailable cache-control=Some("no-cache")' "$WORK/p.log"; then
    pass P2 "R7.1 CONFORMS on both readiness branches, including the 503 a cache must never serve stale"
  else
    fail P2 "the moved readiness handler does not emit Cache-Control on both branches"
  fi

  if p_ok p3_trailing_slash_is_not_redirected_by_axum &&
     $GREP -qF 'P3 GET /healthz/ status=404 Not Found location=None (R2.6 wants 308)' "$WORK/p.log"; then
    pass P3 "R2.6 DEVIATION measured, not assumed: axum 0.8.9 answers GET /healthz/ with 404 and no Location, where the rule's SHOULD prefers 308"
  else
    fail P3 "axum's trailing-slash behaviour is not what this decision records"
  fi

  if p_ok p4_unsatisfiable_accept_is_not_406 &&
     $GREP -qF 'P4 GET /healthz Accept: application/xml -> status=200 OK content-type=Some("application/json") (R4.10 wants 406)' "$WORK/p.log"; then
    pass P4 "R4.10 DEVIATION measured: axum 0.8.9's Json responder ignores an unsatisfiable Accept and serves JSON rather than the 406 the rule's SHOULD prefers"
  else
    fail P4 "axum's Accept handling is not what this decision records"
  fi

  if p_ok p5_no_request_id_header_is_emitted_by_the_handlers &&
     $GREP -qF 'request-id=None (R11.7 requires it)' "$WORK/p.log"; then
    pass P5 "R11.7's obligation is measured as unmet by the handlers alone — the correlation header is R75's middleware to add, and this decision records that it may not skip the two probe paths"
  else
    fail P5 "the request-id measurement is not what this decision records"
  fi

  if p_ok p6_method_not_allowed_still_carries_allow &&
     $GREP -qF 'P6 POST /healthz status=405 Method Not Allowed allow=Some("GET,HEAD") (R5.11 requires Allow on 405)' "$WORK/p.log"; then
    pass P6 "R5.11 CONFORMS: axum 0.8.9 supplies the Allow header the rule makes a MUST, with no code written for it"
  else
    fail P6 "the 405/Allow measurement is not what this decision records"
  fi
fi

echo "--- C: this decision's own revision-2 claims ---"

# C1 — every revision-1 script, log and probe source byte-identical.
declare -a R1_ARTIFACTS=(
  "895f21ed93212e065b33dce21a91ffe8bf06d2d08a23f627cb18b56936eaa612 check-offline.sh"
  "64fc4499d80e738477a1f8522c9dc0e4dbf504a647a87d4820c6aeaf3fd7b224 check-offline.log"
  "9af1a7554e7f91189289a79ac8e6bbb02ec66fc6e256cd1bb42818cdec4c3b8b check-probe.sh"
  "b7e074048b45e712ae13ada9f23f94f4222805ef7e00c3315ab7d727efa89c46 check-probe.log"
  "fb08bb557f110fd48c55bd591fdcfbe367442ce52c4a1dfd3351449297129f8f check-live.sh"
  "2a2183f8c15f651b70bdc0036c3385561be254b711dfb0200c25ca543541b749 check-live.log"
  "74e9db37ec4aad2348402b646fd6363f5c304095e8d29e4e3e6b454167f8eafc shellcheck.log"
  "8cec46b5155bb8bb721723139b21a5ae906357ac7affe30c1a93a1dbbd72aff0 probe/core-src/lib.rs"
  "77e1683ef45a8b464e8e8d7fd12b022ef1176e18d5f08529be66cb64da928399 probe/web-src/lib.rs"
  "419751b3de90f4caf26536b63b2d8ee66082ee1ed74f03c4bbb7dcd4c631a3b1 probe/web-tests/probes.rs"
  "e99cdf289ec32f4410284a0430de3c60b060b6d2386c93a985f5a698f08d03b6 probe/facade-src/lib.rs"
  "c9d539a22585de8bb9a4707bdd0fe10c6a1079bcf6ac3fc69dfd790e3743d364 probe/facade-tests/version_hazard.rs"
)
C1_BAD=0
for entry in "${R1_ARTIFACTS[@]}"; do
  read -r want path <<<"$entry"
  if [ ! -f "$HERE/$path" ]; then
    echo "  MISSING $path"; C1_BAD=$((C1_BAD + 1)); continue
  fi
  got="$(shasum -a 256 "$HERE/$path" | cut -d' ' -f1)"
  if [ "$got" = "$want" ]; then
    printf '  unchanged  %s\n' "$path"
  else
    printf '  CHANGED    %s (%s, expected %s)\n' "$path" "$got" "$want"
    C1_BAD=$((C1_BAD + 1))
  fi
done
if [ "$C1_BAD" -eq 0 ]; then
  pass C1 "all twelve revision-1 scripts, logs and probe sources are byte-identical to the bytes revision 1 was accepted-pending on — this revision adds files, it does not rewrite evidence"
else
  fail C1 "$C1_BAD revision-1 artifact(s) changed; a pre-audit revision must leave revision 1's evidence untouched"
fi

# C2..C8 — the decision text.
if [ -f "$DECISION" ]; then
  if head -1 "$DECISION" | $GREP -qF '# 2026-09-18 — R80 — health-probe-endpoints (bundle, Focused) — decision (revision 2)'; then
    pass C2 "the H1 is the date-first revision-2 title the revision rules prescribe"
  else
    fail C2 "the H1 is not the prescribed revision-2 title"
  fi

  if $GREP -qF 'W2-REST' "$DECISION" && $GREP -qF '71bd813c1cf61286586b4ee41ed83ff065e5c8d9' "$DECISION"; then
    pass C3 "the revision note names owner ruling W2-REST and pins the standard by blob"
  else
    fail C3 "the decision does not name W2-REST and the pinned blob"
  fi

  OV="$($GREP -c 'OVERRIDE (OV-04)' "$DECISION" || true)"
  ARG="$($GREP -c '^\*\*Argument:\*\*' "$DECISION" || true)"
  OPT="$($GREP -c '^\*\*Options:\*\*' "$DECISION" || true)"
  echo "  OVERRIDE (OV-04) mentions: $OV; Argument blocks: $ARG; Options blocks: $OPT"
  if [ "$OV" -ge 1 ] && [ "$ARG" -eq 1 ] && [ "$OPT" -eq 1 ]; then
    pass C4 "the decision records exactly one OVERRIDE (OV-04) with one **Argument:** and one **Options:** block, the shape AGENTS.md and the standard's section 1.9 require"
  else
    fail C4 "the override block is missing or malformed (OV-04 $OV, Argument $ARG, Options $OPT)"
  fi

  if $GREP -qF 'Standard: rest-api-standard v2.0.0' "$DECISION" &&
     $GREP -qF 'webhooks=off' "$DECISION" &&
     $GREP -qF 'async-operations=off' "$DECISION" &&
     $GREP -qF 'bulk-operations=off' "$DECISION" &&
     $GREP -qF 'streaming=off' "$DECISION"; then
    pass C5 "the decision carries a conformance note in the standard's own section 1.9 template, declaring all four applicability switches"
  else
    fail C5 "the conformance note or one of the four switch declarations is missing"
  fi

  if $GREP -qF 'Cache-Control: no-cache' "$DECISION" &&
     $GREP -qiF 'recommendation moves' "$DECISION"; then
    pass C6 "the decision states plainly that the recommendation moved, and names the header R7.1 forced onto it"
  else
    fail C6 "the moved recommendation is not stated plainly with its header"
  fi

  # Counted the way the publication validator counts: headings inside a fenced
  # block are not headings. The conformance note embeds the standard's own
  # section 1.9 template, whose first line is an H2 inside a fence, so a naive
  # `grep -c '^## '` reports one heading that does not exist.
  set +e
  C7_OUT="$(cd "$ROOT" && python3 - "$DECISION" <<'PYEOF' 2>&1
import sys, pathlib
sys.path.insert(0, "scripts")
from research_validation import _line_states, _current_decision, _headings_with_bodies
text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
h2 = [line for line, fenced in _line_states(text) if not fenced and line.startswith("## ")]
sup = [h for h in h2 if h == "## Supersedes"]
current = [name for name, _ in _headings_with_bodies(_current_decision(text), "## ")]
reverify = [line for line, fenced in _line_states(text)
            if not fenced and line.startswith("re-verify: ")]
print("h2_unfenced=%d" % len(h2))
print("supersedes=%d" % len(sup))
print("reverify=%d" % len(reverify))
print("current_h2=%s" % "|".join(current))
PYEOF
)"
  C7_STATUS=$?
  set -e
  echo "$C7_OUT"
  if [ "$C7_STATUS" -eq 0 ] &&
     printf '%s' "$C7_OUT" | $GREP -qF 'h2_unfenced=5' &&
     printf '%s' "$C7_OUT" | $GREP -qF 'supersedes=1' &&
     printf '%s' "$C7_OUT" | $GREP -qF 'reverify=1' &&
     printf '%s' "$C7_OUT" | $GREP -qF 'current_h2=Decision|Parameters|Empirical check|Engines'; then
    pass C7 "revision 2's shape is right, counted outside code fences as the publication validator counts: five H2 sections, one '## Supersedes', one 're-verify:' line, and the current entry's four H2s in the required order"
  else
    fail C7 "revision 2's shape is wrong (see the counts above)"
  fi

  ASSUMES="$($GREP -c '^- assumes ' "$DECISION" || true)"
  OWNS="$($GREP -c '^- owns ' "$DECISION" || true)"
  if [ "$ASSUMES" -eq 7 ] && [ "$OWNS" -eq 0 ]; then
    pass C8 "the parameter block is unchanged in shape: seven '- assumes' lines and no '- owns' line (their byte-identity against the live registry is check O3's, re-run unchanged)"
  else
    fail C8 "the parameter block moved: assumes $ASSUMES, owns $OWNS"
  fi
else
  for id in C2 C3 C4 C5 C6 C7 C8; do skip "$id" "DECISION.md is absent"; done
fi

# C9 — revision 1's own shape check, O25, was written for a FIRST revision:
# "no '## Supersedes', exactly four H2 sections". Revision 2 legitimately has
# both a Supersedes section and a fifth H2, so O25 must now fail. The revision-1
# script is not edited (C1 forbids it) and its log is not overwritten; instead
# this check asserts that re-running it today produces EXACTLY ONE failure and
# that it is O25 — so a second, real regression cannot hide behind the expected
# one. C7 above is the assertion that replaces O25 for revision 2.
if [ -x "$HERE/check-offline.sh" ] || [ -f "$HERE/check-offline.sh" ]; then
  set +e
  bash "$HERE/check-offline.sh" "$ROOT" >"$HERE/check-offline.r2-rerun.log" 2>&1
  set -e
  C9_FAILS="$($GREP -c '^FAIL ' "$HERE/check-offline.r2-rerun.log" || true)"
  C9_PASSES="$($GREP -c '^PASS ' "$HERE/check-offline.r2-rerun.log" || true)"
  echo "  revision-1 offline script re-run under revision 2: $C9_PASSES PASS, $C9_FAILS FAIL"
  $GREP '^FAIL ' "$HERE/check-offline.r2-rerun.log" | sed 's/^/    /' || true
  if [ "$C9_FAILS" -eq 1 ] && [ "$C9_PASSES" -eq 27 ] &&
     $GREP -q '^FAIL O25 — DECISION.md shape is wrong: re-verify lines 1, Supersedes 1, H2 sections 6' \
       "$HERE/check-offline.r2-rerun.log"; then
    pass C9 "re-running revision 1's unedited offline script against revision 2 yields 27 of its 28 checks PASS and exactly one FAIL — O25, whose first-revision shape rule (no Supersedes, four H2s) revision 2 is entitled to break and check C7 replaces. Every other revision-1 assertion, the seven byte-identical assumes lines included, still holds"
  else
    fail C9 "re-running the revision-1 offline script did not yield exactly 27 PASS and the single expected O25 failure ($C9_PASSES PASS, $C9_FAILS FAIL)"
  fi
else
  skip C9 "revision 1's check-offline.sh is absent"
fi

printf '\n=== %d PASS, %d FAIL, %d SKIP ===\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
