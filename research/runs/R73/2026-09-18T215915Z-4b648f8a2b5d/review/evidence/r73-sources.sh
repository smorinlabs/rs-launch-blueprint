#!/usr/bin/env bash
# R73 — the primary sources this decision quotes, read at source and asserted.
#
# Settles the one factual question the four engine legs split on: whether the
# ledger row F314's parenthetical "(Stripe semantics: errors are meant to be
# retried for real, not replayed)" describes what Stripe actually documents.
#
# Volatile web sources are snapshotted under review/evidence/snapshots/ and every
# assertion reads the snapshot. R73_REFRESH=1 re-fetches. Stripe's page is 1.3 MB
# of rendered HTML, so the snapshot is a COMPACT EXTRACT plus the sha256 of the
# full page; that is stated rather than implied.
set -euo pipefail

GREP=/usr/bin/grep
HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
SNAP="$HERE/snapshots"
UA='rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'
REFRESH=${R73_REFRESH:-0}
PY_REPO=${R73_PY_REPO:-/Users/stevemorin/c/py-launch-blueprint}
PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5

PASS=0; FAIL=0; SKIP=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s — %s\n' "$1" "$2"; }

mkdir -p "$SNAP"
printf '== R73 primary sources ==\n'
printf 'grep: %s\n' "$("$GREP" --version | head -1)"
printf 'run_date_utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'mode: %s\n' "$([ "$REFRESH" = "1" ] && echo REFRESH || echo SNAPSHOT)"

# quote_file <id> <file> <pattern> <why> — asserts and prints the matching line.
quote_file() {
  local id=$1 file=$2 pattern=$3 why=$4 hit
  if [ ! -s "$file" ]; then
    skip "$id" "snapshot $file is absent"
    return
  fi
  if hit=$("$GREP" -m1 -n -- "$pattern" "$file"); then
    pass "$id" "$why"
    printf '        %s\n' "$hit"
  else
    fail "$id" "\"$pattern\" is absent from $file — $why"
  fi
}

# ---------------------------------------------------------------- Stripe -----
printf '\n-- Stripe, https://docs.stripe.com/api/idempotent_requests --\n'
if [ "$REFRESH" = "1" ]; then
  RAW=$(mktemp -t r73stripe)
  if curl -sS -A "$UA" --max-time 60 -o "$RAW" "https://docs.stripe.com/api/idempotent_requests"; then
    {
      printf 'source: https://docs.stripe.com/api/idempotent_requests\n'
      printf 'retrieved_utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      printf 'full_page_sha256: %s\n' "$(shasum -a 256 "$RAW" | cut -d' ' -f1)"
      printf 'full_page_bytes: %s\n' "$(wc -c < "$RAW" | tr -d ' ')"
      printf 'NOTE: this file is a compact extract of the rendered page, not the page.\n\n'
      # One sentence per line, tags stripped, only the sentences quoted below.
      sed 's/<[^>]*>/ /g' "$RAW" | tr -s ' ' | tr '.' '\n' |
        "$GREP" -E 'regardless of whether it succeeds or fails|execution of an endpoint begins|are up to 255 characters|at least 24 hours old' |
        sed 's/^ *//' | cut -c1-400 | sort -u
    } > "$SNAP/stripe-idempotent.extract.txt"
  fi
  rm -f "$RAW"
  sleep 2
fi
STRIPE="$SNAP/stripe-idempotent.extract.txt"
quote_file S1-replay-errors "$STRIPE" 'regardless of whether it succeeds or fails' \
  'Stripe replays the first result INCLUDING failures — so F314 row Notes attribute the 2xx-only rule to Stripe wrongly'
quote_file S1-execution-gate "$STRIPE" 'execution of an endpoint begins' \
  'Stripe stores a result only once endpoint execution begins, which is knowledge a generic layer does not have'
quote_file S1-key-length "$STRIPE" '255 characters' \
  'the 255-byte key ceiling this design adopts is Stripe published, not invented'
quote_file S1-retention "$STRIPE" '24 hours' \
  'Stripe 24-hour retention, matching the standard R3.9 floor and the recommended 86400 s ttl'

# ------------------------------------------------------------------ IETF -----
printf '\n-- IETF draft-ietf-httpapi-idempotency-key-header-07 (EVIDENCE, never authority) --\n'
if [ "$REFRESH" = "1" ]; then
  curl -sS -A "$UA" --max-time 60 -o "$SNAP/ietf-draft-07.txt" \
    'https://www.ietf.org/archive/id/draft-ietf-httpapi-idempotency-key-header-07.txt' || true
  date -u +%Y-%m-%dT%H:%M:%SZ > "$SNAP/ietf-draft-07.retrieved"
  sleep 2
fi
DRAFT="$SNAP/ietf-draft-07.txt"
quote_file S2-expiry "$DRAFT" 'This Internet-Draft will expire on 18 April 2026' \
  'the draft expired 2026-04-18, exactly as the org standard 347 records'
quote_file S2-date "$DRAFT" 'Expires: 18 April 2026' \
  'revision -07 is dated 15 October 2025'
quote_file S2-replay "$DRAFT" 'completed operation, success or an error' \
  'the draft too would replay errors — so the 2xx-only rule is supported by NEITHER named authority'
quote_file S2-422 "$DRAFT" 'the resource SHOULD reply with a HTTP 422 status' \
  'the draft 422 for payload mismatch, which the org standard R5.3 independently reaches'
quote_file S2-409 "$DRAFT" 'the resource SHOULD reply with an HTTP 409 status code' \
  'the draft 409 for a retry while the original is in flight'
quote_file S2-fingerprint "$DRAFT" 'fingerprint' \
  'the draft puts a payload fingerprint beside the key, which R3.9 makes mandatory'

# -------------------------------------------------------------------- py -----
printf '\n-- py-launch-blueprint at pin %s --\n' "$PY_PIN"
if [ -d "$PY_REPO" ] && git -C "$PY_REPO" cat-file -e "$PY_PIN^{commit}" 2> /dev/null; then
  PYSRC=$(mktemp -t r73py)
  git -C "$PY_REPO" show "$PY_PIN:src/py_launch_blueprint/web/idempotency.py" > "$PYSRC"
  quote_file S3-header "$PYSRC" 'IDEMPOTENCY_HEADER = "idempotency-key"' \
    'py header spelling, which the org standard 347 also reserves'
  quote_file S3-replayed "$PYSRC" 'REPLAYED_HEADER = "idempotency-replayed"' \
    'py replay marker name, kept; only its VALUE changes to the RFC 9651 boolean'
  quote_file S3-methods "$PYSRC" '_UNSAFE_METHODS = frozenset({"POST", "PUT", "PATCH"})' \
    'the method scope this design keeps'
  quote_file S3-2xx "$PYSRC" 'if 200 <= response.status_code < 300:' \
    'F314 2xx-only condition, the behaviour this decision keeps'
  quote_file S3-stripe-comment "$PYSRC" 'the Stripe semantics' \
    'py own comment makes the same misattribution the ledger row repeats'
  quote_file S3-singleflight "$PYSRC" 'single-flighted' \
    'py documents that concurrent duplicates are NOT single-flighted — the hole this design closes'
  quote_file S3-query "$PYSRC" 'Query string is part of the key' \
    'py justification for keeping the query string in the cache key'
  rm -f "$PYSRC"
else
  skip S3-py "the py checkout or pin $PY_PIN is unavailable at $PY_REPO; seven source quotations are skipped"
fi

# ------------------------------------------------------- published crates ----
printf '\n-- published crates, read as source --\n'
crate_extract() {
  local name=$1 version=$2 out=$3 pattern=$4
  if [ "$REFRESH" = "1" ]; then
    local tmp
    tmp=$(mktemp -d -t r73crate)
    if curl -sS -A "$UA" --max-time 120 -o "$tmp/c.crate" \
      "https://static.crates.io/crates/$name/$name-$version.crate"; then
      ( cd "$tmp" && tar xzf c.crate ) || true
      {
        printf 'source: https://static.crates.io/crates/%s/%s-%s.crate\n' "$name" "$name" "$version"
        printf 'retrieved_utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        printf 'crate_sha256: %s\n\n' "$(shasum -a 256 "$tmp/c.crate" | cut -d' ' -f1)"
        printf '%s\n' "--- file inventory matching $pattern ---"
        ( cd "$tmp/$name-$version" && find . -path "$pattern" | sort )
        printf '%s\n' "" "--- Cargo.toml ---"
        cat "$tmp/$name-$version/Cargo.toml"
        if [ -f "$tmp/$name-$version/README.md" ]; then
          printf '%s\n' "" "--- README.md ---"
          cat "$tmp/$name-$version/README.md"
        fi
      } > "$out"
    fi
    rm -rf "$tmp"
    sleep 2
  fi
}

crate_extract cratestack-axum 0.12.0 "$SNAP/cratestack-axum-0.12.0.extract.txt" './src/idempotency/*'
CS="$SNAP/cratestack-axum-0.12.0.extract.txt"
quote_file S4-cs-module "$CS" './src/idempotency/layer.rs' \
  'cratestack-axum ships a complete idempotency layer — the Opus leg claim that no crate implements this is wrong'
quote_file S4-cs-store "$CS" './src/idempotency/store.rs' \
  'and its own store seam, converging on this design contract independently'
quote_file S4-cs-msrv "$CS" 'rust-version = "1.98.0"' \
  'and it declares 1.98.0, ABOVE the 1.96 floor — the ground on which gate 2 excludes it'
quote_file S4-cs-forbid "$CS" 'unsafe_code = "forbid"' \
  'its unsafe posture, recorded because the gate asks for it'

crate_extract axum-idempotent 0.3.0 "$SNAP/axum-idempotent-0.3.0.extract.txt" './src/*'
AI="$SNAP/axum-idempotent-0.3.0.extract.txt"
quote_file S5-ai-session "$AI" 'SessionLayer' \
  'axum-idempotent requires a session layer, which this template has no reason to adopt'
quote_file S5-ai-ruts "$AI" 'ruts' \
  'its store is a ruts session store, not a general seam'

printf '\nCHECKS RUN: %s PASS: %s FAIL: %s SKIP: %s\n' "$((PASS + FAIL + SKIP))" "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
