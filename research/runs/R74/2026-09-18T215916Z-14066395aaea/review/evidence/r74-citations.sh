#!/usr/bin/env bash
# R74 revision 3 — every cross-file citation the decision makes, asserted at the cited line.
#
# Revision 3 (audit EA-r2-1 and the S1 full re-cite): every coupled decision is re-pinned under
# one policy — the published topic copy where the item is published, otherwise the run copy.
# R70 is re-pinned to its revision-5 run copy by the revision-3 retry (R70 settled at revision 5).
#
# Answers judgment-audit finding 5 (coupled-decision citations had drifted). Each coupled
# decision is pinned by sha256, so a sibling item that moves fails here instead of leaving a
# stale line number in this decision. Also asserts the engine-substitution authority chain,
# the Muse leg's identity and the Muse line references the decision adjudicates, and the py
# precedent at the pin (read from the local clone; no network).
#
# Reproducible byte-for-byte for as long as the cited files are unchanged.
# shellcheck disable=SC2016  # backticks in needles are literal Markdown, not expansions
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN="$(cd "$HERE/../.." && pwd)"
ROOT="$RUN"
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/docs/port/PARAMETERS.md" ]; do ROOT="$(dirname "$ROOT")"; done
PY_REPO="$HOME/c/py-launch-blueprint"
PY_PIN="b08bccfb"

PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); echo "PASS  $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL  $1"; }
skip() { SKIP=$((SKIP+1)); echo "SKIP  $1"; }
chk()  { if [ "$2" = "$3" ]; then ok "$1 == $2"; else bad "$1: expected [$2] got [$3]"; fi; }
# at <label> <repo-relative file> <line> <needle>
at() {
  local f="$ROOT/$2"
  if [ ! -f "$f" ]; then bad "$1: $2 is absent"; return; fi
  if sed -n "${3}p" "$f" | /usr/bin/grep -qF -- "$4"; then ok "$1  $2:$3"; else bad "$1: $2:$3 does not carry [$4]"; fi
}
# pin <label> <repo-relative file> <sha256>
pin() {
  local f="$ROOT/$2"
  if [ ! -f "$f" ]; then bad "$1: $2 is absent"; return; fi
  chk "$1 sha256 of $2" "$3" "$(shasum -a 256 "$f" | cut -c1-64)"
}

echo "grep: $(/usr/bin/grep --version | head -1)"
echo "root: $ROOT"
echo

R69=research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md
R70=research/runs/R70/2026-09-17T034010Z-31ad2ef28df7/review/DECISION.md
R73=research/runs/R73/2026-09-18T215915Z-4b648f8a2b5d/review/DECISION.md
R77=research/topics/77-web-env-settings/DECISION.md
R79=research/topics/79-prometheus-metrics/DECISION.md
R80=research/topics/80-health-probe-endpoints/DECISION.md
R02=research/topics/02-crate-boundary-enforcement/DECISION.md
R74RUN=research/runs/R74/2026-09-18T215916Z-14066395aaea
MUSE=$R74RUN/raw/muse.md
PROMPT=research/topics/74-rate-limiting-middleware/prompts/rate-limiting-middleware.prompt.md

echo "=== P. coupled decisions, pinned by revision and sha256 ==="
pin "P69 R69 revision 11 (run copy)" "$R69" 2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815
at  "P69h" "$R69" 1 'decision (revision 11)'
pin "P70 R70 revision 5" "$R70" a8d4da0ba18bad9bb581aad51f6e11234b29f3db14e1bbb99d2cfeb5e14d4b85
at  "P70h" "$R70" 1 'decision (revision 5)'
pin "P73 R73 revision 4 (run copy)" "$R73" 9e5aaf13544bc41f5ca56cac563a5c0e1dfd7bb9f9373afec6302de34e0ff775
at  "P73h" "$R73" 1 'decision (revision 4)'
pin "P77 R77 revision 5 (published)" "$R77" a3c2dc6ca904b80f8e565f9ad0999cb3a0ab3f78f5d0f9e8d53c1b9d97765b55
at  "P77h" "$R77" 1 'decision (revision 5)'
pin "P79 R79 revision 6 (published)" "$R79" f3d4f8c72d2a73dc95649d15e8d7b46e2edbb9b61e3a1b047cd1f5e67c512948
at  "P79h" "$R79" 1 'decision (revision 6)'
pin "P80 R80 revision 6 (published)" "$R80" 4b63412a4dc1df4c2e31caa51fa20ca509c8e8cd430595f72b94de0843d4c204
at  "P80h" "$R80" 1 'decision (revision 6)'
pin "P02 R02 revision 3 (published; accepted at revision 2, OA-R02)" "$R02" d8c64f7c36663f0c92dcc83cc444a56f203f6c4f52d3fff2a64de9f611cfd2e7
at  "P02h" "$R02" 1 'decision (revision 3)'

echo
echo "=== R69 revision 11 (run copy) ==="
at "R69-serve"   "$R69" 1200 'axum::serve(listener, app)'
at "R69-salvo"   "$R69" 1586 'two minors of headroom against the 1.96 floor'
at "R69-warp"    "$R69" 1588 '`warp`'
at "R69-tide"    "$R69" 1591 '`tide`'
at "R69-rv"      "$R69" 1881 're-verify:'
at "R69-owns"    "$R69" 1885 '- owns web-extra-surface = one additive, off-by-default Cargo feature named web'
at "R69-owns-b"  "$R69" 1885 'crates/web'
at "R69-audit-a" "$R69" 2362 '`cargo audit`'
at "R69-audit-b" "$R69" 2370 'This scan does not refresh the crates.io index'
chk "R69-zero no ConnectInfo or into_make_service anywhere in R69 revision 11" "0" "$(/usr/bin/grep -c 'ConnectInfo\|into_make_service' "$ROOT/$R69" || true)"

echo
echo "=== R70 revision 5 ==="
at "R70-M1"     "$R70" 121 '`type` becomes **mandatory**'
at "R70-M2"     "$R70" 122 '`code` becomes a **snake_case code this item owns**'
at "R70-type"   "$R70" 229 'never `about:blank`'
at "R70-cat"    "$R70" 235 '| `catalog_code` |'
at "R70-table"  "$R70" 279 '| R67 `catalog_code` | HTTP `code` | `type` (under the declared base) | status |'
at "R70-hdr-a"  "$R70" 391 '`WebError` carries `headers: Vec<(HeaderName, HeaderValue)>`'
at "R70-hdr-b"  "$R70" 392 'with a `with_header` builder, and `IntoResponse` inserts them after the body is'
at "R70-gap-a"  "$R70" 606 '**R74**'
at "R70-gap-b"  "$R70" 608 "rate-limit row, and that gap is R74's to raise, not this item's"
at "R70-gap-c"  "$R70" 611 '`rate_limit_exceeded`'
chk "R70-norow R70's code table rows (lines 281-297) carry no rate-limit code" "0" "$(sed -n '281,297p' "$ROOT/$R70" | /usr/bin/grep -ci 'rate_limit\|rate-limit\|429' || true)"

echo
echo "=== R73 revision 4 (run copy) ==="
at "R73-root"  "$R73" 90  'composition root and erased to `Arc<dyn IdempotencyStore>`'
at "R73-mem"   "$R73" 87  '`std::sync::Mutex<HashMap<CacheKey, Slot>>`'
at "R73-port"  "$R73" 115  '`trait IdempotencyStore` in `crates/core`'
at "R73-r74a"  "$R73" 1287 '**R74 (`rate-limiting-middleware`) — proposed, not fixed.** Place rate'
at "R73-r74b"  "$R73" 1288 'limiting **outside** idempotency'
at "R73-r74c"  "$R73" 1291 'R74 owns the decision.'

echo
echo "=== R77 revision 5 (published) ==="
at "R77-empty"  "$R77" 324 '*An exported-but-empty variable is unset.*'
at "R77-cred"   "$R77" 319 '`WebSettings` declares no credential of any kind'
at "R77-idem"   "$R77" 787 '`RSLBP_WEB_IDEMPOTENCY_MAX_ENTRIES`'
at "R77-move2"  "$R77" 966 '`RSLBP_WEB_RATE_LIMIT` is withdrawn as a reserved name'
at "R77-nofl"   "$R77" 971 "1. **The family's size is whatever R74 publishes; this item sets no floor.**"
at "R77-nodis"  "$R77" 978 "2. **No member's default may disable rate limiting.**"
at "R77-port"   "$R77" 979 '`None`-means-off default is not portable into a conformant template'
at "R77-fix"    "$R77" 980 'R74 fixes which members exist, their'
at "R77-memb-a" "$R77" 985 'If R74 publishes a posture'
at "R77-memb-b" "$R77" 986 'that needs a different member set, the family prefix still holds and only the membership'
at "R77-memb-c" "$R77" 987 'moves.'

echo
echo "=== R79 revision 6 (published) ==="
at "R79-two"    "$R79" 229 '**Two instruments, not three'
at "R79-merge"  "$R79" 428 '`/metrics` is registered on a router **merged after**'
at "R79-merge2" "$R79" 429 '`route_layer` has been applied, so the middleware is not in its service stack at all.'
at "R79-r117"   "$R79" 788 "R75's request-id layer must be applied with \`.layer()\` to the **merged** router"
at "R79-optin"  "$R79" 662 "It stays deliberately unlike R74's opt-in rate limiting, whose default"
at "R79-optin2" "$R79" 663 'is off.'

echo
echo "=== R80 revision 6 (published) ==="
at "R80-r75a" "$R80" 911 'and keep a catch-panic layer outside them. Recorded as an input to R75, not a'
at "R80-r75b" "$R80" 912 'decision for it.'

echo
echo "=== R02, published topics, and programme documents ==="
at "R02-web"    "$R02" 43 '| `rs-launch-blueprint-web` | `crates/web/` |'
at "R02-root"   "$R02" 40 'the composition root'
at "R01-seam"   research/topics/01-ports-and-adapters-seam/DECISION.md 138 'erased at the composition root'
at "R67-cat"    research/topics/67-error-and-exit-code-contract/DECISION.md 383 '**Catalog** — `RSLB` + three digits'
at "IDX-R74"    research/CLAUDE.md 79 '| R74 | rate-limiting-middleware | bundle | py-only | DIVERGENT | — |'
at "PAR-17"     docs/port/PARAMETERS.md 17 'the library module src/web/'
at "PAR-17b"    docs/port/PARAMETERS.md 17 'web = ["dep:axum", "dep:tokio"]'
at "OR-W2"      docs/port/OWNER-REVIEW.md 187 'the REST API Design Standard binds the HTTP surface (W2-REST)'
at "OA-R69"     docs/port/OWNER-ACCEPTANCES.md 60 '| R69 | 10 | `d34ab6e8339b6f416a510d070ee54daca38a9086a901a6bfbb9df0517f7fce0a` | accept |'
at "OA-R02"     docs/port/OWNER-ACCEPTANCES.md 71 '| R02 | 2 | `9e8f8e8c11ffb9b383819b2de1b05eab71a32e3af358b75ea8475d48f3c9707f` | accept |'
at "OA-R05"     docs/port/OWNER-ACCEPTANCES.md 75 '| R05 | 3 |'
at "OA-R05b"    docs/port/OWNER-ACCEPTANCES.md 75 'async confined to R69'
at "OD-gate2"   docs/planning/p02/owner-decisions.md 459 'unknown version is insufficient to clear a bar the prompt says must be cleared.'
at "OD-s11"     docs/planning/p02/owner-decisions.md 421 'R72–R76 (C11 middleware, rate'
at "CM-F316"    docs/port/COMMONALITY.md 320 '| F316 | rate-limit store is in-memory, single-instance by design |'
at "CM-F317"    docs/port/COMMONALITY.md 321 '| F317 | middleware ordering is a contract'
at "CM-F323"    docs/port/COMMONALITY.md 327 '| F323 | rate limiting is wired but off by default, one env var enables it |'
at "WS-ts"      docs/port/areas/web-service.md 7 'No web/HTTP-server code, dependency, or test exists anywhere in the ts repo'
at "WS-F316"    docs/port/areas/web-service.md 22 '| F316 |'
at "WS-F317"    docs/port/areas/web-service.md 23 'app.add_middleware(SecurityHeadersMiddleware)` added last (outermost)'
at "WS-F323"    docs/port/areas/web-service.md 29 '| F323 |'
at "RM-vocab"   docs/port/README.md 61 '## Verdict vocabulary'
at "OREF-70"    "$R74RUN/inputs/owner-reference-axum-companion-stack-2026-09-16.md" 70 'tower_governor'
at "OREF-333"   "$R74RUN/inputs/owner-reference-axum-companion-stack-2026-09-16.md" 333 'axum::serve(listener, app)'
chk "OREF-zero no ConnectInfo or into_make_service in the owner reference" "0" "$(/usr/bin/grep -c 'ConnectInfo\|into_make_service' "$ROOT/$R74RUN/inputs/owner-reference-axum-companion-stack-2026-09-16.md" || true)"

echo
echo "=== Q. the engine substitution: authority chain and the frozen prompt ==="
if cmp -s "$ROOT/$PROMPT" "$ROOT/$R74RUN/inputs/prompt.md"; then ok "Q0 the live topic prompt is byte-identical to inputs/prompt.md"; else bad "Q0 the live topic prompt differs from inputs/prompt.md"; fi
at "Q1 prompt engines line"            "$PROMPT" 25 '- engines: muse, opus, doxa'
at "Q2 prompt substitution sentence"   "$PROMPT" 71 'This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot'
at "Q3 RUNBOOK engine_overrides pilot" research/RUNBOOK.md 70 "policy's \`engine_overrides\` pilot substitutes Muse (Meta) for Codex"
at "Q4 RUNBOOK bulk set names R74"     research/RUNBOOK.md 71 'R73, R74,'
at "Q5 RUNBOOK Q9.B"                   research/RUNBOOK.md 72 'Owner decision Q9.B retired Codex from P02'
at "Q6 RUNBOOK Q17.A"                  research/RUNBOOK.md 75 'Q17.A (2026-09-27)'
chk "Q7 EXECUTION.json override row for R74" '["muse","opus","doxa"]' "$(jq -c '.engine_overrides.R74' "$ROOT/research/EXECUTION.json")"
chk "Q8 EXECUTION.json item row for R74"     '["muse","opus","doxa"]' "$(jq -c '.items.R74.engines' "$ROOT/research/EXECUTION.json")"
chk "Q9 manifest migration codex -> muse under Q5.A" 'codex|muse|muse bulk substitution (owner decision Q5.A 2026-09-21)' \
  "$(jq -r '.events[]|select(.migration)|.migration|"\(.from)|\(.to)|\(.reason)"' "$ROOT/$R74RUN/manifest.json")"
chk "Q10 manifest required_engines" '["muse","opus","doxa"]' "$(jq -c '.required_engines' "$ROOT/$R74RUN/manifest.json")"

echo
echo "=== M. the Muse leg: identity, registration state, and the lines the decision cites ==="
chk "M1 raw/muse.md sha256" c3e018cfd5f7df4f4887d4c04d2464fbd0280e749a42d7a69e48a8684c2690dd "$(shasum -a 256 "$ROOT/$MUSE" | cut -c1-64)"
chk "M2 raw/muse.md line count" "337" "$(wc -l < "$ROOT/$MUSE" | tr -d ' ')"
chk "M3 operations/muse.json model|state|request" 'muse-spark|submitting|e762efa45fe34c2db2a4efd1fa28f85c' \
  "$(jq -r '"\(.model)|\(.state)|\(.request_id)"' "$ROOT/$R74RUN/operations/muse.json")"
chk "M4 manifest operations.muse.state (present on disk, not yet registered)" "submitting" "$(jq -r '.operations.muse.state' "$ROOT/$R74RUN/manifest.json")"
chk "M0a the prompt never mentions W2-REST, R11.2 or the REST standard" "0" \
  "$(/usr/bin/grep -c 'W2-REST\|R11\.2\|REST API Design Standard' "$ROOT/$PROMPT" || true)"
chk "M0b raw/muse.md never mentions W2-REST, R11.2 or the REST standard" "0" \
  "$(/usr/bin/grep -c 'W2-REST\|R11\.2\|REST API Design Standard\|rest-standards' "$ROOT/$MUSE" || true)"
at "M19 loco is_enabled claim"           "$MUSE" 19  'fn is_enabled(&self) -> bool'
at "M25 off by default (B1), one value (B2)" "$MUSE" 25 '(B1) off by default — with the setting unset, unbounded request counts all succeed and no limiter state exists'
at "M25b"                                "$MUSE" 25  '(B2) one value turns it on'
at "M33 tower_governor source readings"  "$MUSE" 33  '`src/lib.rs:125-127` and `:293-295`'
at "M35 tower-rate-limiter verdict"      "$MUSE" 35  'Verdict: watch, do not adopt.'
at "M35b fixed window over-states"       "$MUSE" 35  'which over-states the wait for every request but the last'
at "M37 crates pulled, no count"         "$MUSE" 37  'pulls `governor`, `dashmap`, `quanta`, `parking_lot`, `rand` and both `thiserror` majors'
at "M45 owner reference rows"            "$MUSE" 45  'Owner reference architecture, row by row'
at "M47 no BASELINE-REVIEW"              "$MUSE" 47  'No `BASELINE-REVIEW:` finding is raised.'
at "M47b preserves exactly"              "$MUSE" 47  'wired, off by default, one variable'
at "M51 recommendation"                  "$MUSE" 51  'with the layer simply not registered when unset'
at "M116 tracing is R58's"               "$MUSE" 116 "\`tracing\` for the warn-once is R58's to declare"
at "M138 single-parameter interval"      "$MUSE" 138 'with emission interval `T = period / burst`'
at "M138b fixed window overstating"      "$MUSE" 138 'overstating the wait for every request but the last'
at "M149 fixed window rejected on B6"    "$MUSE" 149 'the reported wait is the window end for every refused request, violating B6'
at "M166 recommendation arithmetic"      "$MUSE" 166 '`emission_interval = period / burst`'
at "M179 one string"                     "$MUSE" 179 'because F323 records that **one** variable enables the capability'
at "M209 dashmap advisory"               "$MUSE" 209 'RUSTSEC-2022-0002, **patched in ≥ 5.1.0**'
at "M250 capacity is not the gate"       "$MUSE" 250 'the gate is the single policy variable F323 records'
at "M295 settings fields"                "$MUSE" 295 '`rate_limit: Option<RateLimitPolicy>` (default `None`)'
at "M337 G2 nothing executed"            "$MUSE" 337 '(G2) This engine executed nothing'

echo
echo "=== Y. py precedent at the pin (local clone, no network) ==="
if git -C "$PY_REPO" cat-file -e "$PY_PIN" 2>/dev/null; then
  APP="$(mktemp "${TMPDIR:-/tmp}/r74-app.XXXXXXXX")"; SET="$(mktemp "${TMPDIR:-/tmp}/r74-set.XXXXXXXX")"
  git -C "$PY_REPO" show "$PY_PIN:src/py_launch_blueprint/web/app.py" > "$APP"
  git -C "$PY_REPO" show "$PY_PIN:src/py_launch_blueprint/web/settings.py" > "$SET"
  # yat <label> <file> <line> <needle> — reported against the file's name at the pin, not the temp copy
  yat() {
    local shown="app.py"; [ "$2" = "$SET" ] && shown="settings.py"
    if sed -n "${3}p" "$2" | /usr/bin/grep -qF -- "$4"; then ok "$1  $PY_PIN:$shown:$3"; else bad "$1: $shown:$3 does not carry [$4]"; fi
  }
  yat "Y1 settings.py:70 rate_limit is optional, default None" "$SET" 70  'rate_limit: str | None = None'
  yat "Y2 app.py:128 comment: RequestID + SecurityHeaders outermost" "$APP" 128 'RequestID + SecurityHeaders go LAST so they are OUTERMOST'
  yat "Y3 app.py:129 comment: CORS preflights and slowapi 429s short-circuit" "$APP" 129 'preflights and slowapi 429s short-circuit'
  yat "Y4 app.py:131 IdempotencyMiddleware added first" "$APP" 131 'app.add_middleware('
  yat "Y4b app.py:132" "$APP" 132 'IdempotencyMiddleware,'
  yat "Y5 app.py:136 CORS registered before the limiter" "$APP" 136 'if settings.cors_origins:'
  yat "Y6 app.py:143 the gate" "$APP" 143 'if settings.rate_limit:'
  yat "Y7 app.py:144 the limiter is installed after CORS" "$APP" 144 '_install_rate_limiting(app, settings.rate_limit)'
  yat "Y8 app.py:145 SecurityHeaders" "$APP" 145 'app.add_middleware(SecurityHeadersMiddleware)'
  yat "Y9 app.py:146 RequestID is added last, so outermost" "$APP" 146 'app.add_middleware(RequestIDMiddleware)'
  yat "Y10 app.py:220 no storage_uri" "$APP" 220 'Limiter('
  rm -f "$APP" "$SET"
else
  for l in Y1 Y2 Y3 Y4 Y4b Y5 Y6 Y7 Y8 Y9 Y10; do skip "$l — $PY_REPO has no commit $PY_PIN here"; done
fi

echo
echo "CHECKS RUN: $((PASS + FAIL + SKIP))  PASS: $PASS  FAILURES: $FAIL  SKIPPED: $SKIP"
[ "$FAIL" -eq 0 ]
