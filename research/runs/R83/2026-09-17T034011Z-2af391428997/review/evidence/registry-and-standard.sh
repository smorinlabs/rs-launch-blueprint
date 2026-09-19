#!/usr/bin/env bash
# R83 synthesis evidence — the registry and standard claims this decision leans on.
#
# Re-verifies at source, rather than carrying from the raw report:
#   * that crates.io full-text search for `schemathesis` returns total 0 (the finding);
#   * that the search endpoint itself is working (the control for that zero);
#   * the declared `rust-version`, newest non-yanked release and yank state of the crates
#     the gate-2 verdicts rest on;
#   * that no RustSec advisory page exists for the two crates this decision names;
#   * the maintenance signals for the excluded `openapi-fuzzer` and the selected `oas3`;
#   * the exact text, at its line, of every REST API Design Standard rule quoted in the
#     decision, read out of the pinned blob rather than the working tree.
#
# GitHub is called through `gh api` (keyring credential, no token bytes in this file or
# its log) and never more often than once per 20 seconds.
#
# The `== stable assertions ==` section is byte-reproducible. The
# `== volatile figures ==` section is not: download counters, star counts and `pushed_at`
# move. Compare that section by re-reading it, not by diffing it.
set -euo pipefail

GREP=/usr/bin/grep
UA='rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'
STANDARD_REPO=/Users/stevemorin/c/rest-standards
STANDARD_BLOB=71bd813c1cf61286586b4ee41ed83ff065e5c8d9
STANDARD_COMMIT=0850d43e45d919ef5e37f7174c4212b46013c49f

PASS=0
FAIL=0
SKIP=0

ok()   { printf 'PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf 'FAIL  %s  (%s)\n' "$1" "$2"; FAIL=$((FAIL + 1)); }
skip() { printf 'SKIP  %s  (%s)\n' "$1" "$2"; SKIP=$((SKIP + 1)); }

expect_eq() { # expect_eq <name> <expected> <actual>
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected '$2', got '$3'"; fi
}

WORK="$(mktemp -d "${TMPDIR:-/tmp}/r83-registry-XXXXXX")"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

printf '== environment ==\n'
printf 'grep: %s\n' "$($GREP --version | head -1)"
printf 'retrieved: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

printf '\n== stable assertions ==\n'

# ---------------------------------------------------------------- crates.io ----------
if ! curl -sS -f -o "$WORK/search-schemathesis.json" \
      -H "User-Agent: $UA" \
      'https://crates.io/api/v1/crates?q=schemathesis&per_page=12' 2>"$WORK/curl.err"; then
  skip 'B1..B9 (every crates.io check)' 'crates.io could not be reached'
else
  TOTAL_SCHEMATHESIS=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["meta"]["total"])' "$WORK/search-schemathesis.json")
  printf 'GET https://crates.io/api/v1/crates?q=schemathesis&per_page=12 -> meta.total=%s\n' "$TOTAL_SCHEMATHESIS"
  expect_eq 'B1 crates.io full-text search for "schemathesis" returns nothing' '0' "$TOTAL_SCHEMATHESIS"

  # The control for B1: the same endpoint, a term that must match, so that a broken
  # endpoint cannot masquerade as an empty niche.
  curl -sS -f -o "$WORK/search-openapi-fuzz.json" -H "User-Agent: $UA" \
    'https://crates.io/api/v1/crates?q=openapi%20fuzz&per_page=12'
  TOTAL_OPENAPI_FUZZ=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["meta"]["total"])' "$WORK/search-openapi-fuzz.json")
  printf 'GET https://crates.io/api/v1/crates?q=openapi%%20fuzz&per_page=12 -> meta.total=%s\n' "$TOTAL_OPENAPI_FUZZ"
  if [ "$TOTAL_OPENAPI_FUZZ" -gt 0 ]; then
    ok 'B2 the same search endpoint does return hits for "openapi fuzz" (control for B1)'
  else
    bad 'B2 the search endpoint returned nothing for "openapi fuzz" too' 'B1 proves nothing'
  fi

  newest() { # newest <crate> -> "<num>|<created_at>|<rust_version>"
    curl -sS -f -H "User-Agent: $UA" "https://crates.io/api/v1/crates/$1/versions" \
      -o "$WORK/$1-versions.json"
    python3 - "$WORK/$1-versions.json" <<'PY'
import json, sys
versions = json.load(open(sys.argv[1]))["versions"]
live = [v for v in versions if not v["yanked"]]
newest = live[0]
print("%s|%s|%s" % (newest["num"], newest["created_at"][:10], newest.get("rust_version")))
PY
  }

  IFS='|' read -r OF_NUM OF_DATE OF_MSRV <<<"$(newest openapi-fuzzer)"
  printf 'openapi-fuzzer newest non-yanked: num=%s created_at=%s rust_version=%s\n' "$OF_NUM" "$OF_DATE" "$OF_MSRV"
  expect_eq 'B3 openapi-fuzzer newest non-yanked version is 0.2.0' '0.2.0' "$OF_NUM"
  expect_eq 'B4 openapi-fuzzer 0.2.0 was released 2023-08-30' '2023-08-30' "$OF_DATE"
  expect_eq 'B5 openapi-fuzzer declares no rust-version (fitness gate 2 FAIL)' 'None' "$OF_MSRV"

  IFS='|' read -r OAS3_NUM OAS3_DATE OAS3_MSRV <<<"$(newest oas3)"
  printf 'oas3 newest non-yanked: num=%s created_at=%s rust_version=%s\n' "$OAS3_NUM" "$OAS3_DATE" "$OAS3_MSRV"
  expect_eq 'B6 oas3 newest non-yanked version is 0.22.0' '0.22.0' "$OAS3_NUM"
  expect_eq 'B7 oas3 0.22.0 declares rust-version 1.87 (gate 2 PASS against the 1.96 floor)' '1.87' "$OAS3_MSRV"

  IFS='|' read -r PT_NUM PT_DATE PT_MSRV <<<"$(newest proptest)"
  printf 'proptest newest non-yanked: num=%s created_at=%s rust_version=%s\n' "$PT_NUM" "$PT_DATE" "$PT_MSRV"
  expect_eq 'B8 proptest newest non-yanked version is 1.11.0 (the version R33 published)' '1.11.0' "$PT_NUM"
  expect_eq 'B9 proptest 1.11.0 declares rust-version 1.85' '1.85' "$PT_MSRV"
fi

# ------------------------------------------------------------------ RustSec ----------
for crate in oas3 proptest openapi-fuzzer; do
  code=$(curl -sS -o /dev/null -w '%{http_code}' -H "User-Agent: $UA" \
    "https://rustsec.org/packages/$crate.html" || echo 000)
  printf 'GET https://rustsec.org/packages/%s.html -> %s\n' "$crate" "$code"
  case "$code" in
    404) ok "B10.$crate no RustSec advisory page exists for $crate (fitness gate 3)" ;;
    000) skip "B10.$crate" 'rustsec.org could not be reached' ;;
    *)   bad "B10.$crate an advisory page now exists for $crate" "HTTP $code — gate 3 must be re-evaluated" ;;
  esac
done

# --------------------------------------------- the REST API Design Standard ----------
if [ ! -e "$STANDARD_REPO/.git" ]; then
  skip 'B11..B22 (every standard quote and the Spectral cross-check)' "no clone of rest-standards at $STANDARD_REPO"
else
  HEAD_COMMIT=$(git -C "$STANDARD_REPO" rev-parse HEAD)
  printf 'rest-standards HEAD: %s\n' "$HEAD_COMMIT"
  expect_eq 'B11 the clone is at the commit the owner ruling W2-REST pins' "$STANDARD_COMMIT" "$HEAD_COMMIT"

  BLOB_AT_COMMIT=$(git -C "$STANDARD_REPO" rev-parse "$STANDARD_COMMIT:rest-api-standard.md")
  expect_eq 'B12 rest-api-standard.md at that commit is the blob the ruling names' "$STANDARD_BLOB" "$BLOB_AT_COMMIT"

  git -C "$STANDARD_REPO" show "$STANDARD_BLOB" > "$WORK/standard.md"
  RULES=$($GREP -c '^\*\*R[0-9]' "$WORK/standard.md")
  printf 'rules of the form **R<n>.<n>** in the blob: %s\n' "$RULES"
  expect_eq 'B13 the conformance surface is 145 rules' '145' "$RULES"

  quote() { # quote <check-name> <expected-line-number> <expected-text-fragment>
    local name="$1" line="$2" fragment="$3" actual
    actual=$(sed -n "${line}p" "$WORK/standard.md")
    printf 'rest-api-standard.md:%s: %s\n' "$line" "$actual"
    if printf '%s' "$actual" | $GREP -qF -- "$fragment"; then
      ok "$name"
    else
      bad "$name" "line $line does not contain '$fragment'"
    fi
  }

  quote 'B14 R4.1 is quoted at its line (the contract document is OpenAPI 3.1)' 742 \
    '**R4.1** Every API MUST publish an OpenAPI document as the contract source'
  quote 'B15 R5.2 is quoted at its line (unregistered status codes)' 934 \
    '**R5.2** Unregistered status codes MUST NOT be defined or used.'
  quote 'B16 R4.3 is quoted at its line (object at the JSON top level)' 762 \
    '**R4.3** Every JSON response body MUST have an object at the top level'
  quote 'B17 R1.5 is quoted at its line (conformance tiers)' 210 \
    '**R1.5** Every API declares one **conformance tier** in its conformance'
  quote 'B18 R1.7 is quoted at its line (no silent deviation)' 271 \
    '**R1.7 — No silent deviation.** An API deviates from this standard only in'
  quote 'B19 R5.1 is quoted at its line (status matches the outcome)' 916 \
    '**R5.1** The status code MUST match the registered semantics of the'
  quote 'B20 R5.12 is quoted at its line (problem+json capability)' 1019 \
    '**R5.12** Every API MUST be capable of returning every error response the'

  # What the static linter in the standard's own conformance/ directory covers, which is
  # the complement of what a runtime fuzz harness can carry.
  SPECTRAL_RULES=$($GREP -o 'R[0-9]\+\.[0-9]\+' "$STANDARD_REPO/conformance/spectral.yaml" | sort -u | tr '\n' ' ')
  printf 'rules mechanically checked by conformance/spectral.yaml: %s\n' "$SPECTRAL_RULES"
  if printf '%s' "$SPECTRAL_RULES" | $GREP -q 'R4.3'; then
    ok 'B21 R4.3 is also statically linted, so the runtime oracle is a second line, not the only one'
  else
    bad 'B21 R4.3 was expected in the standard'\''s Spectral ruleset' "found: $SPECTRAL_RULES"
  fi
  if printf '%s' "$SPECTRAL_RULES" | $GREP -q 'R5.2'; then
    bad 'B22 R5.2 was not expected to be statically linted' "found: $SPECTRAL_RULES"
  else
    ok 'B22 R5.2 is not in the Spectral ruleset: an unregistered status is only observable at runtime'
  fi
fi

# -------------------------------------------------------- GitHub, spaced 20 s --------
printf '\n== volatile figures (counters move; re-read rather than diff) ==\n'
if ! command -v gh >/dev/null 2>&1; then
  skip 'B23, B24 (both GitHub repositories)' 'the gh CLI is not on PATH'
elif ! gh auth status >/dev/null 2>&1; then
  skip 'B23, B24 (both GitHub repositories)' 'gh is not authenticated'
else
  repo_line() { # repo_line <owner/repo>
    gh api "repos/$1" --jq '"\(.full_name) stars=\(.stargazers_count) archived=\(.archived) pushed_at=\(.pushed_at)"'
  }
  if OF_REPO=$(repo_line matusf/openapi-fuzzer 2>"$WORK/gh1.err"); then
    printf '%s\n' "$OF_REPO"
    OF_PUSHED=${OF_REPO##*pushed_at=}; OF_PUSHED=${OF_PUSHED%% *}
    if [ "${OF_PUSHED:0:4}" -le 2024 ]; then
      ok 'B23 openapi-fuzzer has had no push since 2024 (maintenance: at-risk)'
    else
      bad 'B23 openapi-fuzzer was pushed after 2024' "pushed_at=$OF_PUSHED — re-evaluate its maintenance verdict"
    fi
  else
    skip 'B23' 'the GitHub API call for matusf/openapi-fuzzer failed'
  fi

  sleep 20 # GitHub is polled no more than once per 20 seconds.

  if OAS3_REPO=$(repo_line x52dev/oas3-rs 2>"$WORK/gh2.err"); then
    printf '%s\n' "$OAS3_REPO"
    OAS3_PUSHED=${OAS3_REPO##*pushed_at=}; OAS3_PUSHED=${OAS3_PUSHED%% *}
    if [ "${OAS3_PUSHED:0:4}" -ge 2026 ]; then
      ok 'B24 oas3 was pushed in 2026 or later (maintenance: active)'
    else
      bad 'B24 oas3 has not been pushed since 2025' "pushed_at=$OAS3_PUSHED — re-evaluate its maintenance verdict"
    fi
  else
    skip 'B24' 'the GitHub API call for x52dev/oas3-rs failed'
  fi
fi

if [ -f "$WORK/oas3-versions.json" ]; then
  curl -sS -f -H "User-Agent: $UA" 'https://crates.io/api/v1/crates/oas3' -o "$WORK/oas3.json" || true
  curl -sS -f -H "User-Agent: $UA" 'https://crates.io/api/v1/crates/openapi-fuzzer' -o "$WORK/of.json" || true
  for f in "$WORK/oas3.json" "$WORK/of.json"; do
    [ -f "$f" ] && python3 -c 'import json,sys
c = json.load(open(sys.argv[1]))["crate"]
print("%s: recent_downloads=%s downloads=%s" % (c["name"], c["recent_downloads"], c["downloads"]))' "$f"
  done
fi

printf '\n== totals ==\n'
printf 'PASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
[ "$FAIL" -eq 0 ]
