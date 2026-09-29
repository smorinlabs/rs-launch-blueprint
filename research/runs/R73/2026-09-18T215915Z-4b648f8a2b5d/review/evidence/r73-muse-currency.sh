#!/usr/bin/env bash
# R73 revision 2 — the Muse leg and the drift the revision-1 audits found.
#
#   M-checks  the Muse (Meta) leg: its identity, the policy that makes it a
#             required leg in place of Codex, and each factual claim of it that
#             this decision adjudicates.
#   K-checks  currency of what revision 1 cited: the F314 Stripe text's true
#             location, R70's current revision, the PARAMETERS.md snapshot, the
#             revision-1 snapshot's hash, and the LOW question's sources.
#
# Volatile web sources are snapshotted under review/evidence/snapshots/muse-*
# and every assertion reads the snapshot, so a rerun reproduces this log except
# its run_date_utc line. R73_REFRESH=1 re-fetches (crates.io, zero2prod.com,
# and one keyring-authenticated `gh api` call); nothing else touches the network.
# Repository files are read live: a K-check failing is a citation that moved.
# Single-quoted patterns below carry literal backticks; none is meant to expand.
# shellcheck disable=SC2016

set -euo pipefail

GREP=/usr/bin/grep
HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REVIEW=$(dirname "$HERE")
RUN=$(dirname "$REVIEW")
SNAP="$HERE/snapshots"
UA='rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'
REFRESH=${R73_REFRESH:-0}

ROOT="$RUN"
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/docs/port/PARAMETERS.md" ]; do
  ROOT=$(dirname "$ROOT")
done

PASS=0; FAIL=0; SKIP=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s — %s\n' "$1" "$2"; }

mkdir -p "$SNAP"
printf '== R73 Muse leg and revision-1 currency ==\n'
printf 'grep: %s\n' "$("$GREP" --version | head -1)"
printf 'run_date_utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'mode: %s\n' "$([ "$REFRESH" = "1" ] && echo REFRESH || echo SNAPSHOT)"

# at_line <id> <file> <line> <expected-substring> <why>
at_line() {
  local id=$1 file=$2 line=$3 expect=$4 why=$5 actual
  if [ ! -f "$file" ]; then
    fail "$id" "${file#"$ROOT"/} is absent"
    return
  fi
  actual=$(sed -n "${line}p" "$file")
  case "$actual" in
    *"$expect"*)
      pass "$id" "${file#"$ROOT"/}:$line carries \"$expect\" — $why"
      ;;
    *)
      fail "$id" "${file#"$ROOT"/}:$line does not carry \"$expect\"; it reads: ${actual:0:200}"
      ;;
  esac
}

MUSE="$RUN/raw/muse.md"

# --- M0: the leg exists, and policy makes it required ------------------------
printf '\n-- M0 identity and authority --\n'
MUSE_SHA=$(shasum -a 256 "$MUSE" | cut -d' ' -f1)
if [ "$MUSE_SHA" = 'aca328034d31b0280241da56ec8f603e21c3230a299023dc00d0b9bac2870536' ]; then
  pass M0-raw "raw/muse.md is sha256 $MUSE_SHA, $(wc -l < "$MUSE" | tr -d ' ') lines — the leg the ledger recorded as collected on 2026-09-23"
else
  fail M0-raw "raw/muse.md is sha256 $MUSE_SHA, not the collected aca32803…"
fi
python3 - "$RUN/operations/muse.json" "$RUN/manifest.json" "$ROOT/research/EXECUTION.json" > /tmp/r73_m0.txt <<'PY'
import json, sys
op, man, pol = (json.load(open(p)) for p in sys.argv[1:4])
print("op", op.get("model"), op.get("request_id"), op.get("state"))
print("req", ",".join(man.get("required_engines", [])))
print("pol", ",".join(pol.get("engine_overrides", {}).get("R73", [])))
PY
read -r _ OP_MODEL OP_REQ OP_STATE < <("$GREP" '^op ' /tmp/r73_m0.txt)
REQ=$("$GREP" '^req ' /tmp/r73_m0.txt | cut -d' ' -f2)
POL=$("$GREP" '^pol ' /tmp/r73_m0.txt | cut -d' ' -f2)
if [ "$OP_MODEL" = 'muse-spark' ] && [ "$OP_REQ" = '511e5c1c36164801b65a8c5383665aa3' ]; then
  pass M0-op "operations/muse.json records model $OP_MODEL, request $OP_REQ (state field reads '$OP_STATE'; the leg itself is on disk, see M0-raw)"
else
  fail M0-op "operations/muse.json records model $OP_MODEL, request $OP_REQ"
fi
if [ "$POL" = 'muse,opus,doxa' ]; then
  pass M0-policy "research/EXECUTION.json engine_overrides.R73 = [$POL]: Muse is required and Codex is not"
else
  fail M0-policy "research/EXECUTION.json engine_overrides.R73 = [$POL]"
fi
if [ "$REQ" = 'muse,opus,doxa' ]; then
  pass M0-manifest "manifest.json required_engines = [$REQ]"
else
  fail M0-manifest "manifest.json required_engines = [$REQ]"
fi
TOPIC_PROMPT="$ROOT/research/topics/73-idempotency-middleware/prompts/idempotency-middleware.prompt.md"
if cmp -s "$TOPIC_PROMPT" "$RUN/inputs/prompt.md"; then
  pass M0-prompt-frozen 'inputs/prompt.md is byte-identical to the current topic prompt, so the frozen input already carries the Muse substitution'
else
  fail M0-prompt-frozen 'inputs/prompt.md differs from the current topic prompt'
fi
at_line M0-prompt-engines "$TOPIC_PROMPT" 25 '- engines: muse, opus, doxa' 'the mirrored engines line the prompt calls authoritative'
if "$GREP" -q 'R76, R77, R79, R80, R83 and R86. Owner decision Q9.B retired Codex from P02' "$ROOT/research/RUNBOOK.md" &&
   "$GREP" -q 'R02, R03, R05, R24, R51, R54, R56, R58, R70, R73, R74,' "$ROOT/research/RUNBOOK.md" &&
   "$GREP" -q 'and Q17.A (2026-09-27)' "$ROOT/research/RUNBOOK.md"; then
  pass M0-runbook 'RUNBOOK.md §2 lists R73 in the Muse bulk set, records Q9.B retiring Codex from P02, and records Q17.A (2026-09-27)'
else
  fail M0-runbook 'RUNBOOK.md §2 no longer carries the R73 bulk listing, Q9.B and Q17.A'
fi
LEDGER="$ROOT/docs/planning/p02/execution-ledger.md"
for pat in 'Owner decision (2026-09-21, Q5.A): Muse-bulk all 17 remaining legs' \
           'Codex is retired from P02 (legs Muse, synthesis/judgment/empirical Claude)' \
           'Q17.A IMPLEMENTED (2026-09-27)' \
           'R73 MUSE LEG COLLECTED, 2026-09-23: sha aca32803'; do
  if "$GREP" -qF "$pat" "$LEDGER"; then
    pass M0-ledger "execution-ledger.md:$("$GREP" -nF "$pat" "$LEDGER" | head -1 | cut -d: -f1) records \"$pat\""
  else
    fail M0-ledger "execution-ledger.md does not record \"$pat\""
  fi
done

# --- M1: what the Muse leg claims, quoted at its line -------------------------
printf '\n-- M1 the Muse positions this decision adjudicates --\n'
at_line M1-none-exists "$MUSE" 25 'none exists for any leading framework' 'Muse: no published middleware exists'
at_line M1-tower-dep   "$MUSE" 87 '`tower = "0.5"`' 'Muse: tower as a direct dependency'
at_line M1-moka        "$MUSE" 140 '`moka` 0.12.16 with feature `sync`' 'Muse: a moka sync::Cache store'
at_line M1-body-key    "$MUSE" 185 'body_hash: [u8; 32]' 'Muse: the body hash folded into the cache key'
at_line M1-async-trait "$MUSE" 87 '`IdempotencyStore` async trait' 'Muse: an async store trait'
at_line M1-replayed    "$MUSE" 23 '`Idempotency-Replayed: true`' 'Muse: the replay marker as the token true'
at_line M1-stripe      "$MUSE" 21 'only 2xx outcomes are cached so genuine errors are retried for real (Stripe semantics)' 'Muse: 2xx-only attributed to Stripe'
at_line M1-z2p-author  "$MUSE" 15 'Luke Maxwell, *Zero to Production in Rust*' 'Muse: the Zero To Production author as named'
at_line M1-sha2-default "$MUSE" 209 '`sha2` 0.11.0, default features.' 'Muse: sha2 with default features'
at_line M1-gap-g1      "$MUSE" 291 '(G1) no mainstream Rust template documents in-memory idempotency middleware' 'Muse: the LOW-question gap it records'
N_409=$("$GREP" -c '409' "$MUSE" || true)
N_422=$("$GREP" -c '422' "$MUSE" || true)
N_FLIGHT=$("$GREP" -ci 'in-flight\|in flight\|inflight' "$MUSE" || true)
if [ "$N_409" -eq 0 ] && [ "$N_422" -eq 0 ] && [ "$N_FLIGHT" -eq 0 ]; then
  pass M1-no-concurrency 'raw/muse.md contains no 409, no 422 and no in-flight state anywhere, so its design never rejects a concurrent duplicate or a reused key with a different body'
else
  fail M1-no-concurrency "raw/muse.md mentions 409 x$N_409, 422 x$N_422, in-flight x$N_FLIGHT — the decision says it has none"
fi
N_CS=$("$GREP" -ci 'cratestack' "$MUSE" || true)
N_AI=$("$GREP" -ci 'axum-idempotent' "$MUSE" || true)
if [ "$N_CS" -eq 0 ] && [ "$N_AI" -eq 0 ]; then
  pass M1-missed 'raw/muse.md never names cratestack-axum or axum-idempotent, both of which are published (registry checks E4-cratestack-exists and E1 rows)'
else
  fail M1-missed "raw/muse.md names cratestack x$N_CS, axum-idempotent x$N_AI"
fi

# --- M2: the registry facts behind those claims -------------------------------
printf '\n-- M2 crates.io: GET https://crates.io/api/v1/crates/<name> --\n'
fetch_crate() {
  local name=$1 raw code
  if [ "$REFRESH" = "1" ]; then
    raw=$(mktemp -t r73mfetch)
    code=$(curl -sS -A "$UA" --max-time 40 -o "$raw" -w '%{http_code}' "https://crates.io/api/v1/crates/$name" || echo 000)
    printf '%s\n' "$code" > "$SNAP/muse-crates-$name.status"
    {
      date -u +%Y-%m-%dT%H:%M:%SZ
      printf 'endpoint https://crates.io/api/v1/crates/%s\n' "$name"
      printf 'full_response_sha256 %s\n' "$(shasum -a 256 "$raw" | cut -d' ' -f1)"
      printf 'full_response_bytes %s\n' "$(wc -c < "$raw" | tr -d ' ')"
    } > "$SNAP/muse-crates-$name.retrieved"
    python3 -c '
import json, sys
raw, out = sys.argv[1], sys.argv[2]
try:
    d = json.load(open(raw))
except Exception:
    raise SystemExit
c = d.get("crate") or {}
keep = {k: c.get(k) for k in ("id", "name", "max_version", "recent_downloads", "downloads")}
vs = [{k: v.get(k) for k in ("num", "created_at", "rust_version", "yanked")} for v in d.get("versions") or []][:6]
json.dump({"crate": keep, "versions": vs}, open(out, "w"), indent=1, sort_keys=True)
' "$raw" "$SNAP/muse-crates-$name.json" || true
    rm -f "$raw"
    sleep 2
  fi
}
crate_field() {
  python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
f = sys.argv[2]
if f == "newest_unyanked":
    vs = [v for v in d["versions"] if not v.get("yanked")]
    print(vs[0]["num"] + " " + vs[0]["created_at"][:10] if vs else "NONE")
else:
    print(d["crate"].get(f))
' "$1" "$2"
}

for name in idempotency tower-idempotency axum-idempotency idempotency-key; do
  fetch_crate "$name"
  if [ -s "$SNAP/muse-crates-$name.status" ]; then
    st=$(cat "$SNAP/muse-crates-$name.status")
    if [ "$st" = '404' ]; then
      pass "M2-404-$name" "crates.io $name is HTTP 404 ($(head -1 "$SNAP/muse-crates-$name.retrieved")) — this Muse probe reproduces"
    else
      fail "M2-404-$name" "crates.io $name is HTTP $st, not the 404 Muse reported"
    fi
  else
    skip "M2-404-$name" "no snapshot for $name"
  fi
done
for name in minco-plugin-idempotency lru; do
  fetch_crate "$name"
done
if [ -s "$SNAP/muse-crates-minco-plugin-idempotency.json" ]; then
  MINCO_ALL=$(crate_field "$SNAP/muse-crates-minco-plugin-idempotency.json" downloads)
  if [ "$MINCO_ALL" -lt 5000 ]; then
    pass M2-minco "minco-plugin-idempotency has $MINCO_ALL all-time downloads (Muse said 869 on 2026-09-25) — a framework plugin with negligible adoption, as Muse says"
  else
    fail M2-minco "minco-plugin-idempotency has $MINCO_ALL all-time downloads"
  fi
else
  skip M2-minco 'no minco-plugin-idempotency snapshot'
fi
if [ -s "$SNAP/muse-crates-lru.json" ]; then
  LRU_NEW=$(crate_field "$SNAP/muse-crates-lru.json" newest_unyanked)
  case "$LRU_NEW" in
    '0.18.5 2026-09-23')
      pass M2-lru "lru newest unyanked is $LRU_NEW — published after revision 1's 2026-09-19 retrieval; it is why revision 1's caret-pinned P6-lru stopped reproducing (probe P6-lru-latest)" ;;
    *)
      fail M2-lru "lru newest unyanked is $LRU_NEW, not 0.18.5 of 2026-09-23" ;;
  esac
else
  skip M2-lru 'no lru snapshot'
fi

# --- M3: Zero To Production — the LOW question and the author Muse misnames --
printf '\n-- M3 Zero To Production --\n'
if [ "$REFRESH" = "1" ]; then
  raw=$(mktemp -t r73mz2p)
  curl -sS -L -A "$UA" --max-time 40 -o "$raw" -w '%{http_code}\n' 'https://www.zero2prod.com/' > "$SNAP/muse-zero2prod.status" || true
  {
    date -u +%Y-%m-%dT%H:%M:%SZ
    printf 'endpoint https://www.zero2prod.com/\n'
    printf 'full_response_sha256 %s\n' "$(shasum -a 256 "$raw" | cut -d' ' -f1)"
    printf 'full_response_bytes %s\n' "$(wc -c < "$raw" | tr -d ' ')"
  } > "$SNAP/muse-zero2prod.retrieved"
  # A compact extract: only the text naming the author, either spelling.
  "$GREP" -oE '.{0,40}(Luca Palmieri|Luke Maxwell).{0,40}' "$raw" | sed 's/^[[:space:]]*//' | sort -u | head -5 > "$SNAP/muse-zero2prod.extract.txt" || true
  rm -f "$raw"
  if command -v gh > /dev/null 2>&1; then
    gh api 'repos/LukeMathWalker/zero-to-production/contents/src/idempotency' \
      --jq '[.[] | .name] | join(" ")' > "$SNAP/muse-gh-z2p-idempotency.txt" 2> /dev/null || : > "$SNAP/muse-gh-z2p-idempotency.txt"
    date -u +%Y-%m-%dT%H:%M:%SZ > "$SNAP/muse-gh-z2p-idempotency.retrieved"
    sleep 21
  fi
fi
if [ -s "$SNAP/muse-zero2prod.extract.txt" ]; then
  if "$GREP" -q 'Luca Palmieri' "$SNAP/muse-zero2prod.extract.txt" && ! "$GREP" -q 'Luke Maxwell' "$SNAP/muse-zero2prod.extract.txt"; then
    pass M3-author 'https://www.zero2prod.com/ names the author Luca Palmieri and never "Luke Maxwell" — the Muse attribution is wrong'
  else
    fail M3-author 'the zero2prod.com extract does not name Luca Palmieri, or does name Luke Maxwell'
  fi
else
  skip M3-author 'no zero2prod.com snapshot'
fi
if [ -s "$SNAP/muse-gh-z2p-idempotency.txt" ]; then
  Z=$(cat "$SNAP/muse-gh-z2p-idempotency.txt")
  case " $Z " in
    *' persistence.rs '*)
      pass M3-z2p-module "GET repos/LukeMathWalker/zero-to-production/contents/src/idempotency lists: $Z — the book's companion repository carries the pattern as a named module, DB-backed" ;;
    *)
      fail M3-z2p-module "the Zero To Production idempotency module lists: $Z" ;;
  esac
else
  skip M3-z2p-module 'no GitHub snapshot of the Zero To Production idempotency module'
fi
OPUS="$RUN/raw/opus.md"
at_line M3-opus-z2p "$OPUS" 41 '`LukeMathWalker/zero-to-production` `src/idempotency/{key,persistence,mod}.rs`' 'the Opus leg read the same module at source'
at_line M3-opus-bin "$OPUS" 24 '*Zero To Production in Rust* `src/idempotency/` (Postgres, actix-web)' 'the Opus leg files it as a pattern, not a crate or template'

# --- K1: the F314 Stripe text, at its true location ---------------------------
printf '\n-- K1 F314 citation --\n'
at_line K1-webservice "$ROOT/docs/port/areas/web-service.md" 20 'Stripe semantics: errors are meant to be retried for real, not replayed.' 'the F314 Notes text the controller request targets'
at_line K1-webservice-row "$ROOT/docs/port/areas/web-service.md" 20 '| F314 |' 'that line is the F314 row'
at_line K1-prompt "$RUN/inputs/prompt.md" 9 '(Stripe semantics: errors are meant to be retried for real, not replayed)' "the prompt's per-row evidence line carries it too"
at_line K1-ledger-row "$ROOT/docs/port/COMMONALITY.md" 318 '| F314 |' 'COMMONALITY.md:318 is the F314 row'
if sed -n '318p' "$ROOT/docs/port/COMMONALITY.md" | "$GREP" -qi 'stripe'; then
  fail K1-ledger-nostripe 'COMMONALITY.md:318 does carry Stripe text'
else
  pass K1-ledger-nostripe 'COMMONALITY.md:318 carries no Stripe text, so revision 1 cited the wrong file'
fi

# --- K2: R70's current revision -----------------------------------------------
# R70 is under active revision by another session, so its live DECISION.md moves.
# The stable anchor is R70-r3-snapshot.md, which the revision protocol freezes:
# its lines are asserted exactly. The live file is checked by CONTENT only, and
# its revision number is printed so a reader sees which one this run observed.
printf '\n-- K2 R70 currency --\n'
R70DIR="$ROOT/research/runs/R70/2026-09-17T034010Z-31ad2ef28df7/review"
R70S="$R70DIR/R70-r3-snapshot.md"
if [ -f "$R70S" ] && [ "$(shasum -a 256 "$R70S" | cut -d' ' -f1)" = '802e5292157c97b8530445a7a5c637d8ebcb71c4a3fe232eadd882c7dea5cc8b' ]; then
  pass K2-r70-r3 'R70-r3-snapshot.md is the frozen revision 3 (sha256 802e5292…)'
else
  fail K2-r70-r3 'R70-r3-snapshot.md is absent or no longer sha256 802e5292…'
fi
at_line K2-r70-m1 "$R70S" 36 '`type` becomes **mandatory** and template-bound' 'R70 revision 3 move M-1 makes type mandatory under R5.13 point 5'
at_line K2-r70-field "$R70S" 134 '**always present**, never `about:blank`' 'R70 revision 3 envelope field table forbids about:blank'
at_line K2-r70-r73 "$R70S" 497 '**R73** hands over five bodies' 'R70 revision 3 already records the five bodies this item hands it'
R70L="$R70DIR/DECISION.md"
R70REV=$(head -1 "$R70L" | sed -n 's/.*(revision \([0-9]*\)).*/\1/p')
if [ "${R70REV:-0}" -ge 3 ] && "$GREP" -qF 'becomes **mandatory**' "$R70L" && "$GREP" -qF 'never `about:blank`' "$R70L"; then
  pass K2-r70-live "the live R70 DECISION.md is revision $R70REV and still makes type mandatory and forbids about:blank, so the conflict revision 1 flagged is resolved at R70"
else
  fail K2-r70-live "the live R70 DECISION.md (revision ${R70REV:-?}) no longer carries the mandatory-type fix"
fi

# --- K3: the PARAMETERS.md snapshot -------------------------------------------
printf '\n-- K3 registry snapshot --\n'
rows() {
  python3 - "$1" <<'PY'
import sys
for line in open(sys.argv[1], encoding="utf-8"):
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    if len(cells) >= 4 and cells[1] in ("fixed", "researched", "open"):
        print(cells[0] + "\t" + cells[1] + "\t" + cells[3])
PY
}
LIVE=$(rows "$ROOT/docs/port/PARAMETERS.md"); SNAPP=$(rows "$RUN/inputs/PARAMETERS.md")
FIX_LIVE=$(printf '%s\n' "$LIVE" | awk -F'\t' '$2=="fixed"')
FIX_SNAP=$(printf '%s\n' "$SNAPP" | awk -F'\t' '$2=="fixed"')
if [ -n "$FIX_LIVE" ] && [ "$FIX_LIVE" = "$FIX_SNAP" ]; then
  pass K3-fixed "the $(printf '%s\n' "$FIX_LIVE" | wc -l | tr -d ' ') fixed rows are identical in inputs/PARAMETERS.md and the live registry — the only rows this decision assumes"
else
  fail K3-fixed 'a fixed row differs between inputs/PARAMETERS.md and the live registry'
fi
DIFFS=$( { diff <(printf '%s\n' "$SNAPP") <(printf '%s\n' "$LIVE") || true; } | { "$GREP" '^[<>]' || true; } | cut -f1 | sed 's/^[<>] //' | sort -u | tr '\n' ' ')
if [ "$DIFFS" = 'ci-job-structure ' ]; then
  pass K3-drift 'the snapshot and the live registry differ in exactly one row, ci-job-structure (R11, researched) — a value this item neither owns nor consumes'
else
  fail K3-drift "the snapshot and the live registry differ in rows: ${DIFFS:-none}"
fi

# --- K4: the preserved revision-1 snapshot ------------------------------------
printf '\n-- K4 revision-1 snapshot --\n'
R1="$REVIEW/R73-r1-snapshot.md"
if [ -f "$R1" ] && [ "$(shasum -a 256 "$R1" | cut -d' ' -f1)" = 'b7368070722f08e4a7a879896bf19bc929b5c823379060aa962d2fd6a5f37f40' ]; then
  pass K4-r1 'review/R73-r1-snapshot.md is byte-identical to revision 1 (sha256 b7368070…), the text both audits judged'
else
  fail K4-r1 'review/R73-r1-snapshot.md is absent or not revision 1'
fi

printf '\nCHECKS RUN: %s PASS: %s FAIL: %s SKIP: %s\n' "$((PASS + FAIL + SKIP))" "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
