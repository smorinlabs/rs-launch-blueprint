#!/usr/bin/env bash
# R76 empirical check, part 1 of 3: re-verify at the primary sources every
# registry, forge, advisory and crate-source claim this decision rests on.
# It queries endpoints and reads published .crate artifacts. It builds nothing
# and writes nothing outside its own temporary directory.
#
# Line prefixes and what each promises:
#   FIGURE  — a point-in-time counter or timestamp from an API. It does NOT
#             reproduce byte-for-byte; it carries its endpoint and this run's
#             UTC date, and the decision quotes it with that date.
#   PINNED  — content read from an immutable published artifact (a .crate file
#             whose sha256 is printed) or from a fixed advisory record.
#             Reproduces byte-for-byte for as long as the artifact exists.
#   HEAD    — content read from a moving default branch. The matched line is
#             quoted so the exact bytes relied on are in this log.
#   SNAP    — content read from the committed snapshot under snapshots/.
#             Reproduces byte-for-byte.
#   ASSERT  — a content assertion. `ASSERT FAIL` sets exit status 1.
#   SKIP    — a check that could not run, with the reason named.
#
# Needs: network; `gh` already authenticated (keyring). No token byte and no
# personal address is printed or sent. Needs no `.git`, so it runs unchanged
# from a clean `git archive HEAD` extraction.
#
# GitHub API calls are spaced at least 21 s apart (four calls, three waits).
#
# Revision 3 (2026-09-27) changed two sections and nothing else: section G adds
# the source lines showing tower-http applies Access-Control-Expose-Headers
# only on non-preflight responses (the ground of OVERRIDE (OV-08)), and
# section H reads rust-lang/crates.io's Cargo.toml at a resolved commit sha
# instead of at a moving default branch, so the cited line is addressable.

set -euo pipefail

GREP=/usr/bin/grep
HERE="$(cd "$(dirname "$0")" && pwd)"
UA="rs-launch-blueprint-r76-research (https://github.com/smorinlabs/rs-launch-blueprint)"

echo "=== R76 registry, forge and crate-source checks ==="
echo "date(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "grep: $("$GREP" --version | head -1)"
echo "curl: $(curl --version | "$GREP" -o '^curl [0-9.]*')"
echo "gh:   $(gh --version | "$GREP" '^gh version')"
echo "jq:   $(jq --version)"
echo

WORK=$(mktemp -d "${TMPDIR:-/tmp}/r76-registry.XXXXXX")
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

pass=0; failn=0; skipn=0
assert() { # assert <0|1> <description>
  if [ "$1" = "1" ]; then echo "ASSERT ok   $2"; pass=$((pass + 1))
  else echo "ASSERT FAIL $2"; failn=$((failn + 1)); fi
}
skip() { echo "SKIP        $1"; skipn=$((skipn + 1)); }
eq() { if [ "$1" = "$2" ]; then echo 1; else echo 0; fi; }
gt0() { if [ "$1" -gt 0 ] 2>/dev/null; then echo 1; else echo 0; fi; }

have_net=1
if ! curl -sS -A "$UA" -o "$WORK/probe.json" -m 30 "https://crates.io/api/v1/crates/tower-http"; then
  have_net=0
fi

# ---------------------------------------------------------------------------
echo "--- A. tower-http on crates.io: the version this decision pins ---"
if [ "$have_net" = "0" ]; then
  skip "A: crates.io unreachable, so no crates.io figure in this log was refreshed"
else
  cp "$WORK/probe.json" "$WORK/th.json"
  curl -sS -A "$UA" "https://crates.io/api/v1/crates/tower-http/versions" -o "$WORK/th-versions.json"
  echo "endpoint: GET https://crates.io/api/v1/crates/tower-http"
  R90=$(jq -r '.crate.recent_downloads' "$WORK/th.json")
  RALL=$(jq -r '.crate.downloads' "$WORK/th.json")
  echo "FIGURE crate.recent_downloads (90-day) = ${R90}"
  echo "FIGURE crate.downloads (all-time)      = ${RALL}"
  echo "endpoint: GET https://crates.io/api/v1/crates/tower-http/versions"
  NEWEST=$(jq -r '[.versions[] | select(.yanked==false)] | .[0].num' "$WORK/th-versions.json")
  CREATED=$(jq -r '[.versions[] | select(.yanked==false)] | .[0].created_at' "$WORK/th-versions.json")
  RUSTV=$(jq -r '[.versions[] | select(.yanked==false)] | .[0].rust_version' "$WORK/th-versions.json")
  C070=$(jq -r '.versions[] | select(.num=="0.7.0") | .created_at' "$WORK/th-versions.json")
  NONYANKED=$(jq -r '[.versions[] | select(.yanked==false)] | length' "$WORK/th-versions.json")
  ALLVER=$(jq -r '.versions | length' "$WORK/th-versions.json")
  echo "FIGURE newest non-yanked num       = ${NEWEST}"
  echo "FIGURE newest non-yanked created_at= ${CREATED}"
  echo "FIGURE newest non-yanked rust_version = ${RUSTV}"
  echo "FIGURE 0.7.0 created_at            = ${C070}"
  echo "FIGURE versions: ${NONYANKED} non-yanked of ${ALLVER} published"
  assert "$(eq "$NEWEST" "0.7.1")" \
    "the newest non-yanked tower-http version is 0.7.1 — the version this decision recommends"
  assert "$(eq "$CREATED" "2026-08-31T14:49:25.697237Z")" \
    "tower-http 0.7.1 was published 2026-08-31T14:49:25.697237Z, which is what the decision states"
  assert "$(eq "$C070" "2026-06-15T14:01:18.432430Z")" \
    "tower-http 0.7.0 was published 2026-06-15, before the owner reference's own 2026-09-16 date"
  assert "$(eq "$RUSTV" "1.65")" \
    "tower-http 0.7.1 declares rust-version 1.65, inside the 1.96 floor msrv-policy yields from rustc 1.98.0"
fi
echo

# ---------------------------------------------------------------------------
echo "--- B. the cors category on crates.io, enumerated rather than recalled ---"
if [ "$have_net" = "0" ]; then
  skip "B: crates.io unreachable, so the category enumeration was not refreshed"
else
  curl -sS -A "$UA" "https://crates.io/api/v1/crates?keyword=cors&per_page=30&sort=downloads" -o "$WORK/kw1.json"
  sleep 1
  curl -sS -A "$UA" "https://crates.io/api/v1/crates?keyword=cors&per_page=30&sort=downloads&page=2" -o "$WORK/kw2.json"
  sleep 1
  curl -sS -A "$UA" "https://crates.io/api/v1/crates?q=cors&per_page=40" -o "$WORK/q1.json"
  KWTOTAL=$(jq -r '.meta.total' "$WORK/kw1.json")
  N1=$(jq -r '.crates | length' "$WORK/kw1.json")
  N2=$(jq -r '.crates | length' "$WORK/kw2.json")
  QTOTAL=$(jq -r '.meta.total' "$WORK/q1.json")
  QN=$(jq -r '.crates | length' "$WORK/q1.json")
  echo "endpoint: GET https://crates.io/api/v1/crates?keyword=cors&per_page=30&sort=downloads (and &page=2)"
  echo "FIGURE keyword=cors meta.total = ${KWTOTAL}; page1 returned ${N1}, page2 returned ${N2}"
  echo "endpoint: GET https://crates.io/api/v1/crates?q=cors&per_page=40"
  echo "FIGURE q=cors meta.total = ${QTOTAL}; this run read the ${QN} highest-ranked"
  echo "--- every crate carrying the cors keyword, name / newest stable / 90-day / all-time ---"
  jq -r '.crates[] | "  \(.name) \(.max_stable_version) \(.recent_downloads) \(.downloads)"' \
    "$WORK/kw1.json" "$WORK/kw2.json"
  READ=$((N1 + N2))
  assert "$(eq "$READ" "$KWTOTAL")" \
    "every crate carrying the cors keyword was read in this run (${READ} of ${KWTOTAL}), so the category map is an enumeration"
  TH_IN_KW=$(jq -r '[.crates[].name] | index("tower-http") // "no"' "$WORK/kw1.json" "$WORK/kw2.json" | "$GREP" -c '^no$' || true)
  assert "$(eq "$TH_IN_KW" "2")" \
    "tower-http appears on neither keyword page — it was reached from the axum side, not from the keyword search, and the decision says so"
  # The recommendation must be the only keyword-or-name candidate that is a tower Layer.
  ROK=$(jq -r '[.crates[] | select(.name=="rok-cors")] | length' "$WORK/kw2.json")
  HYP=$(jq -r '[.crates[] | select(.name=="hyper-cors")] | length' "$WORK/kw2.json")
  assert "$(eq "$ROK" "1")" "rok-cors is on the enumerated list, so its exclusion is a disposition and not an omission"
  assert "$(eq "$HYP" "1")" "hyper-cors is on the enumerated list, so its exclusion is a disposition and not an omission"
fi
echo

# ---------------------------------------------------------------------------
echo "--- C. the declared MSRV of every candidate the decision excludes on gate 2 ---"
if [ "$have_net" = "0" ]; then
  skip "C: crates.io unreachable, so no candidate MSRV was refreshed"
else
  # crate | expected rust_version | why that value decides the gate
  while IFS='|' read -r c want why; do
    [ -n "$c" ] || continue
    curl -sS -A "$UA" "https://crates.io/api/v1/crates/$c/versions" -o "$WORK/v-$c.json"
    RV=$(jq -r '[.versions[] | select(.yanked==false)] | .[0].rust_version' "$WORK/v-$c.json")
    NUM=$(jq -r '[.versions[] | select(.yanked==false)] | .[0].num' "$WORK/v-$c.json")
    echo "FIGURE ${c} ${NUM}: rust_version = ${RV}   (GET https://crates.io/api/v1/crates/${c}/versions)"
    assert "$(eq "$RV" "$want")" "$why"
    sleep 1
  done <<'CANDIDATES'
axum_cors|null|axum_cors declares no rust-version, so gate 2 cannot be cleared
rok-cors|null|rok-cors declares no rust-version, so gate 2 cannot be cleared
cors-core|null|cors-core declares no rust-version, so gate 2 cannot be cleared
tower-http-cors-config|null|tower-http-cors-config declares no rust-version, so gate 2 cannot be cleared
lily_middleware|1.96.1|lily_middleware declares 1.96.1, above the 1.96 floor, so gate 2 fails the other way
hyper-cors|1.80|hyper-cors declares 1.80 and clears gate 2 - it is excluded on integration, not on MSRV
actix-cors|1.88|actix-cors declares 1.88 and clears gate 2 - it is excluded on gate 5 and on fit
CANDIDATES
fi
echo

# ---------------------------------------------------------------------------
echo "--- D. hyper-cors implements no tower Layer: read its dependency list ---"
if [ "$have_net" = "0" ]; then
  skip "D: crates.io unreachable, so hyper-cors's dependency list was not refreshed"
else
  curl -sS -A "$UA" "https://crates.io/api/v1/crates/hyper-cors/0.2.0/dependencies" -o "$WORK/hc-deps.json"
  DEPS=$(jq -r '[.dependencies[] | select(.kind=="normal") | .crate_id] | sort | join(", ")' "$WORK/hc-deps.json")
  echo "endpoint: GET https://crates.io/api/v1/crates/hyper-cors/0.2.0/dependencies"
  echo "FIGURE hyper-cors 0.2.0 normal dependencies = ${DEPS}"
  TOWERDEP=$(jq -r '[.dependencies[] | select(.crate_id=="tower-layer" or .crate_id=="tower-service" or .crate_id=="tower")] | length' "$WORK/hc-deps.json")
  assert "$(eq "$TOWERDEP" "0")" \
    "hyper-cors depends on no tower, tower-layer or tower-service crate, so axum::Router::layer cannot take it — the ground the decision excludes it on"
fi
echo

# ---------------------------------------------------------------------------
echo "--- E. advisories: RustSec on tower-http, with a control that must also answer ---"
if [ "$have_net" = "0" ]; then
  skip "E: rustsec.org unreachable, so the advisory state was not refreshed"
else
  TH_CODE=$(curl -sS -A "$UA" -o "$WORK/rustsec-tower-http.html" -w '%{http_code}' "https://rustsec.org/packages/tower-http.html")
  sleep 1
  AT_CODE=$(curl -sS -A "$UA" -o "$WORK/rustsec-atty.html" -w '%{http_code}' "https://rustsec.org/packages/atty.html")
  echo "endpoint: https://rustsec.org/packages/tower-http.html -> HTTP ${TH_CODE}"
  echo "endpoint: https://rustsec.org/packages/atty.html (control) -> HTTP ${AT_CODE}"
  assert "$(eq "$AT_CODE" "200")" \
    "the control page answers 200, so a 404 elsewhere would mean the site changed rather than that an advisory cleared"
  assert "$(eq "$TH_CODE" "200")" "RustSec serves a page for tower-http"
  IDS=$("$GREP" -o 'RUSTSEC-[0-9]\{4\}-[0-9]\{4\}' "$WORK/rustsec-tower-http.html" | sort -u | tr '\n' ' ')
  WITHDRAWN=$("$GREP" -c -i 'withdrawn' "$WORK/rustsec-tower-http.html" || true)
  echo "PINNED advisory ids listed for tower-http = ${IDS}"
  echo "FIGURE occurrences of the word 'withdrawn' on that page = ${WITHDRAWN}"
  assert "$(eq "$IDS" "RUSTSEC-2021-0135 RUSTSEC-2022-0043 ")" \
    "RustSec lists exactly two tower-http entries, which is the pair the decision dispositions"
  assert "$(gt0 "$WITHDRAWN")" "the page marks at least one entry withdrawn, which is RUSTSEC-2021-0135"
  sleep 1
  curl -sSL -A "$UA" "https://raw.githubusercontent.com/rustsec/advisory-db/main/crates/tower-http/RUSTSEC-2022-0043.md" -o "$WORK/adv.md"
  echo "PINNED RUSTSEC-2022-0043, the lines that decide whether 0.7.1 is exposed:"
  "$GREP" -n 'patched\|^os = \|ServeDir' "$WORK/adv.md" | head -4 | sed 's/^/  /'
  N=$("$GREP" -c 'patched = \[">= 0.2.1", ">= 0.1.3, < 0.2.0"\]' "$WORK/adv.md" || true)
  assert "$(gt0 "$N")" \
    "RUSTSEC-2022-0043 declares patched >= 0.2.1, so 0.7.1 is many minor lines past it"
  N=$("$GREP" -c '^os = \["windows"\]' "$WORK/adv.md" || true)
  assert "$(gt0 "$N")" \
    "RUSTSEC-2022-0043 is Windows-only, an operating system target-os-matrix does not name"
  N=$("$GREP" -c 'tower_http::services::fs::ServeDir' "$WORK/adv.md" || true)
  assert "$(gt0 "$N")" \
    "RUSTSEC-2022-0043 concerns ServeDir in the fs feature, which the cors-only dependency line never enables"
fi
echo

# ---------------------------------------------------------------------------
echo "--- F. what 0.7.0 changed for the cors module, read from the maintainers' changelog ---"
if [ "$have_net" = "0" ]; then
  skip "F: raw.githubusercontent.com unreachable, so the changelog was not refreshed"
else
  curl -sSL -A "$UA" "https://raw.githubusercontent.com/tower-rs/tower-http/main/tower-http/CHANGELOG.md" -o "$WORK/CHANGELOG.md"
  awk '/^# 0\.7\.0/{f=1} f&&/^# 0\.6\.11/{exit} f' "$WORK/CHANGELOG.md" > "$WORK/070.md"
  # shellcheck disable=SC2016  # the backticks are literal Markdown, not a command substitution
  CORS_LINES=$("$GREP" -c '^- `cors`' "$WORK/070.md" || true)
  BREAKING=$("$GREP" -c 'breaking:' "$WORK/070.md" || true)
  # shellcheck disable=SC2016  # literal Markdown backticks again
  BREAKING_CORS=$("$GREP" -c 'breaking:.*`cors`' "$WORK/070.md" || true)
  echo "HEAD  tower-http CHANGELOG.md, section '# 0.7.0' (default branch main)"
  echo "FIGURE entries beginning '- \`cors\`' in the 0.7.0 section = ${CORS_LINES}"
  echo "FIGURE entries carrying 'breaking:' in the 0.7.0 section = ${BREAKING}"
  echo "the cors entry, quoted:"
  # shellcheck disable=SC2016  # literal Markdown backticks again
  "$GREP" '^- `cors`' "$WORK/070.md" | sed 's/^/  /'
  echo "every breaking entry, quoted by its module:"
  "$GREP" 'breaking:' "$WORK/070.md" | sed 's/^/  /' | cut -c1-120
  assert "$(eq "$CORS_LINES" "1")" \
    "the 0.7.0 section carries exactly one cors entry — 'relax the Vary header defaults (#674)'"
  assert "$(eq "$BREAKING_CORS" "0")" \
    "no breaking entry in the 0.7.0 section names the cors module"
  assert "$(gt0 "$BREAKING")" \
    "the 0.7.0 section does carry breaking entries, so this check can fail; they land in other modules, which R75 must read for whatever features it adds"
fi
echo

# ---------------------------------------------------------------------------
echo "--- G. the shipped source: read the published .crate artifacts, not a branch ---"
if [ "$have_net" = "0" ]; then
  skip "G: static.crates.io unreachable, so the crate sources were not downloaded"
else
  for v in 0.6.11 0.7.1; do
    curl -sSL -A "$UA" "https://static.crates.io/crates/tower-http/tower-http-$v.crate" -o "$WORK/th-$v.crate"
    tar xzf "$WORK/th-$v.crate" -C "$WORK"
    echo "PINNED tower-http-$v.crate sha256 = $(shasum -a 256 "$WORK/th-$v.crate" | cut -d' ' -f1)"
    sleep 1
  done
  C="$WORK/tower-http-0.7.1"
  echo "PINNED tower-http-0.7.1/Cargo.toml feature declarations:"
  "$GREP" -n '^default = \|^cors = ' "$C/Cargo.toml" | sed 's/^/  /'
  N=$("$GREP" -c '^default = \[\]$' "$C/Cargo.toml" || true)
  assert "$(gt0 "$N")" \
    "tower-http declares default = [], so the dependency line must name cors explicitly and pulls in nothing else"
  N=$("$GREP" -c '^cors = \[\]$' "$C/Cargo.toml" || true)
  assert "$(gt0 "$N")" \
    "the cors feature activates no optional dependency at all, which is why it adds no async-runtime coupling"
  N=$("$GREP" -c '#!\[deny(unsafe_code)\]' "$C/src/lib.rs" || true)
  assert "$(gt0 "$N")" "tower-http declares #![deny(unsafe_code)] at the crate root"
  N=$("$GREP" -rc 'unsafe' "$C/src/cors" | "$GREP" -vc ':0$' || true)
  assert "$(eq "$N" "0")" "no file in the cors module contains the token 'unsafe'"
  N=$("$GREP" -c 'parts.method == Method::OPTIONS' "$C/src/cors/mod.rs" || true)
  assert "$(gt0 "$N")" \
    "Cors::call short-circuits on any OPTIONS request regardless of the allowlist — the source cause of the 405-to-200 change an unconditional install produces"
  N=$("$GREP" -c 'headers.extend(self.layer.vary.to_header());' "$C/src/cors/mod.rs" || true)
  assert "$(gt0 "$N")" \
    "Cors::call emits the derived Vary header on every response it handles, preflight or not"
  N=$("$GREP" -c 'fn ensure_usable_cors_rules' "$C/src/cors/mod.rs" || true)
  assert "$(gt0 "$N")" \
    "ensure_usable_cors_rules exists — the runtime assertion that panics when allow_credentials(true) meets a wildcard"
  N=$("$GREP" -c 'pub fn list<I>' "$C/src/cors/allow_origin.rs" || true)
  assert "$(gt0 "$N")" \
    "AllowOrigin::list takes a runtime iterator, so the allowlist is runtime-configured and not compile-time"
  N=$("$GREP" -c 'fn default() -> Self {' "$C/src/cors/allow_origin.rs" || true)
  assert "$(gt0 "$N")" "AllowOrigin carries a Default, which the bare-CorsLayer::new() case resolves through"
  N=$("$GREP" -c 'Self::List(Vec::new())' "$C/src/cors/allow_origin.rs" || true)
  assert "$(gt0 "$N")" \
    "OriginInner::default() is an empty List, not a Const — which is why a bare CorsLayer::new() still derives Vary: origin in 0.7.1"
  echo "PINNED what 0.7.1 changed in src/cors relative to 0.6.11 — the files that differ:"
  diff -rq "$WORK/tower-http-0.6.11/src/cors" "$C/src/cors" 2>/dev/null \
    | sed "s|$WORK/||g" | sed 's/^/  /' || true
  CHANGED=$(diff -rq "$WORK/tower-http-0.6.11/src/cors" "$C/src/cors" 2>/dev/null | "$GREP" -c 'differ' || true)
  echo "FIGURE files differing under src/cors between 0.6.11 and 0.7.1 = ${CHANGED}"
  assert "$(gt0 "$CHANGED")" \
    "the cors module did change between 0.6.11 and 0.7.1, so 'no change' would be the wrong claim; probe-checks.sh measures what the change is observable as"
  N=$("$GREP" -c 'fn update_vary_header' "$C/src/cors/mod.rs" || true)
  assert "$(gt0 "$N")" \
    "0.7.1 derives the Vary header in update_vary_header from whether each CORS response header is request-dependent — the #674 relaxation"
  N=$("$GREP" -c 'fn update_vary_header' "$WORK/tower-http-0.6.11/src/cors/mod.rs" || true)
  assert "$(eq "$N" "0")" \
    "0.6.11 has no such derivation: its Vary default is the fixed preflight_request_headers() list, which is the difference the probe measures"
  echo "PINNED tower-http-0.7.1/src/cors/mod.rs, where Cors::call splits preflight from non-preflight:"
  sed -n '715p;727,729p' "$C/src/cors/mod.rs" | sed 's/^/  /'
  assert "$(eq "$(sed -n '715p' "$C/src/cors/mod.rs")" '        if parts.method == Method::OPTIONS {')" \
    "mod.rs:715 branches on Method::OPTIONS, so every OPTIONS request takes the preflight path"
  assert "$(eq "$(sed -n '728,729p' "$C/src/cors/mod.rs" | tr -s ' ')" "$(printf ' // This header is applied only to non-preflight requests\n headers.extend(self.layer.expose_headers.to_header(&parts));')")" \
    "mod.rs:728-729 extend Access-Control-Expose-Headers only in the non-preflight branch, so no CorsLayer configuration puts the expose list on a preflight response — the structural ground of OVERRIDE (OV-08)"
fi
echo

# ---------------------------------------------------------------------------
echo "--- H. GitHub, through the authenticated CLI, one call every 21 s ---"
if ! gh auth status >/dev/null 2>&1; then
  skip "H: gh is not authenticated, so no GitHub figure in this log was refreshed"
else
  gh api "repos/tower-rs/tower-http" > "$WORK/gh-repo.json"
  STARS=$(jq -r '.stargazers_count' "$WORK/gh-repo.json")
  ARCH=$(jq -r '.archived' "$WORK/gh-repo.json")
  PUSHED=$(jq -r '.pushed_at' "$WORK/gh-repo.json")
  OIC=$(jq -r '.open_issues_count' "$WORK/gh-repo.json")
  echo "endpoint: GET https://api.github.com/repos/tower-rs/tower-http"
  echo "FIGURE stargazers_count = ${STARS}; archived = ${ARCH}; pushed_at = ${PUSHED}"
  echo "FIGURE open_issues_count = ${OIC}  (NOT used: it counts pull requests too, per the prompt's rule)"
  assert "$(eq "$ARCH" "false")" "tower-rs/tower-http is not archived"
  assert "$(gt0 "$STARS")" "the repository figure resolved rather than returning an empty body"
  sleep 21
  gh api "search/issues?q=repo:tower-rs/tower-http+is:issue+is:open&per_page=1" > "$WORK/gh-search.json"
  OPEN=$(jq -r '.total_count' "$WORK/gh-search.json")
  echo "endpoint: GET https://api.github.com/search/issues?q=repo:tower-rs/tower-http+is:issue+is:open"
  echo "FIGURE open issues (total_count, the field the prompt requires) = ${OPEN}"
  assert "$(gt0 "$OPEN")" "the open-issue search resolved; the decision quotes this number with today's date"
  sleep 21
  # Resolve the default branch to a commit first, then read the file AT that
  # commit, so the line number printed below addresses fixed bytes.
  gh api "repos/rust-lang/crates.io/commits/HEAD" > "$WORK/gh-cratesio-head.json"
  CIO_SHA=$(jq -r '.sha' "$WORK/gh-cratesio-head.json")
  echo "endpoint: GET https://api.github.com/repos/rust-lang/crates.io/commits/HEAD"
  echo "FIGURE rust-lang/crates.io default-branch commit = ${CIO_SHA}"
  sleep 21
  gh api "repos/rust-lang/crates.io/contents/Cargo.toml?ref=${CIO_SHA}" > "$WORK/gh-cratesio.json"
  jq -r '.content' "$WORK/gh-cratesio.json" | base64 -d > "$WORK/cratesio-Cargo.toml"
  echo "endpoint: GET https://api.github.com/repos/rust-lang/crates.io/contents/Cargo.toml?ref=${CIO_SHA}"
  echo "HEAD  the Rust project's own registry service pins tower-http at (Cargo.toml@${CIO_SHA}:<line>):"
  "$GREP" -n '^tower-http = ' "$WORK/cratesio-Cargo.toml" | sed "s|^|  Cargo.toml@${CIO_SHA}:|"
  N=$("$GREP" -c '^tower-http = { version = "=0.7.1"' "$WORK/cratesio-Cargo.toml" || true)
  assert "$(gt0 "$N")" \
    "rust-lang/crates.io pins tower-http at exactly =0.7.1 in production, which is the practice evidence for recommending the 0.7 line over the owner reference's 0.6"
fi
echo

# ---------------------------------------------------------------------------
echo "--- I. practice evidence: who activates the cors feature, and on what CI ---"
if [ "$have_net" = "0" ]; then
  skip "I: raw.githubusercontent.com unreachable, so no adopter manifest was refreshed"
else
  for pair in \
    "tokio-rs/axum:main:examples/cors/Cargo.toml" \
    "tokio-rs/console:main:console-subscriber/Cargo.toml" \
    "hyperium/tonic:master:tonic-web/Cargo.toml"; do
    repo=${pair%%:*}; rest=${pair#*:}; ref=${rest%%:*}; path=${rest#*:}
    curl -sSL -A "$UA" "https://raw.githubusercontent.com/${repo}/${ref}/${path}" -o "$WORK/m.toml"
    echo "HEAD  ${repo}/${path}:"
    "$GREP" -n '^tower-http = ' "$WORK/m.toml" | sed 's/^/  /' || echo "  (no tower-http line)"
    N=$("$GREP" -c '^tower-http = .*"cors"' "$WORK/m.toml" || true)
    assert "$(gt0 "$N")" "${repo} activates the tower-http cors feature in ${path}"
    sleep 1
  done
  curl -sSL -A "$UA" "https://raw.githubusercontent.com/tower-rs/tower-http/main/.github/workflows/CI.yml" -o "$WORK/CI.yml"
  echo "HEAD  tower-rs/tower-http .github/workflows/CI.yml, the OS and MSRV rows:"
  "$GREP" -n 'os: \[\|rust-toolchain@1\.' "$WORK/CI.yml" | sed 's/^/  /'
  N=$("$GREP" -c 'os: \[macos-latest, windows-latest\]' "$WORK/CI.yml" || true)
  assert "$(gt0 "$N")" \
    "upstream CI runs a macos-latest job, and its other jobs run on ubuntu-latest, so both members of target-os-matrix are covered upstream"
  N=$("$GREP" -c 'rust-toolchain@1.65' "$WORK/CI.yml" || true)
  assert "$(gt0 "$N")" "upstream CI tests the declared 1.65 MSRV, so the declaration is enforced and not decorative"
  sleep 1
  curl -sSL -A "$UA" "https://raw.githubusercontent.com/loco-rs/loco/master/src/controller/middleware/cors.rs" -o "$WORK/loco-cors.rs"
  curl -sSL -A "$UA" "https://raw.githubusercontent.com/loco-rs/loco/master/src/controller/middleware/mod.rs" -o "$WORK/loco-mod.rs"
  echo "HEAD  loco-rs/loco, the config-gated-middleware pattern this decision compares against:"
  "$GREP" -n 'pub enable: bool\|fn is_enabled\|cors.max_age' "$WORK/loco-cors.rs" "$WORK/loco-mod.rs" \
    | sed "s|$WORK/||g" | sed 's/^/  /'
  N=$("$GREP" -c 'fn is_enabled' "$WORK/loco-mod.rs" || true)
  assert "$(gt0 "$N")" \
    "loco's MiddlewareLayer trait carries is_enabled(), so a registry of switchable layers is a real named pattern in a 9k-star framework — the shape this decision hands to R75 rather than adopting for one layer"
  N=$("$GREP" -c 'cors.max_age(Duration::from_secs(max_age))' "$WORK/loco-cors.rs" || true)
  assert "$(gt0 "$N")" \
    "loco calls CorsLayer::max_age from deserialized config, corroborating the .max_age(600) call this decision recommends to match py's always-emitted max-age"
fi
echo

# ---------------------------------------------------------------------------
echo "--- J. issue responsiveness, recomputed from the committed snapshot ---"
SNAP="$HERE/snapshots/tower-http-issue-triage.json"
if [ ! -f "$SNAP" ]; then
  skip "J: snapshots/tower-http-issue-triage.json is absent, so responsiveness was not recomputed"
else
  echo "SNAP  $SNAP"
  python3 - "$SNAP" > "$WORK/triage.txt" <<'PY'
import json, sys, datetime
d = json.load(open(sys.argv[1]))
MAINT = {"OWNER", "MEMBER", "COLLABORATOR"}
def dt(s): return datetime.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ")
by = {}
for c in d["comments"]:
    by.setdefault(c["issue_number"], []).append(c)
answered, unanswered = [], []
print("fetched_utc: %s" % d["fetched_utc"])
print("comments page covers back to %s (%d comments)" % (d["comments_page_covers_from"], d["comments_page_size"]))
print("the 10 most recently opened non-PR issues: %s" % ", ".join("#%d" % i["number"] for i in d["issues"]))
for i in d["issues"]:
    n, opened, author = i["number"], dt(i["created_at"]), i["user_login"]
    cs = sorted(by.get(n, []), key=lambda c: c["created_at"])
    first = next((c for c in cs
                  if c["author_association"] in MAINT and c["user_login"] != author), None)
    if first:
        delta = (dt(first["created_at"]) - opened).total_seconds()
        answered.append(delta)
        print("  #%d opened %s by %s (%s) state=%s -> first maintainer reply after %.2f h (%.3f d)"
              % (n, i["created_at"], author, i["author_association"], i["state"], delta / 3600, delta / 86400))
    else:
        before = i["created_at"] < d["comments_page_covers_from"]
        unanswered.append((n, i["state"], before))
        print("  #%d opened %s by %s (%s) state=%s -> no maintainer comment on the fetched page%s"
              % (n, i["created_at"], author, i["author_association"], i["state"],
                 "  [opened BEFORE the comment page's window — absence not established]" if before else ""))
ds = sorted(answered)
med = (ds[len(ds)//2] if len(ds) % 2 else (ds[len(ds)//2 - 1] + ds[len(ds)//2]) / 2) if ds else None
print("answered_by_maintainer_comment=%d unanswered=%d" % (len(answered), len(unanswered)))
print("closed_without_a_maintainer_comment=%d" % sum(1 for _, s, _ in unanswered if s == "closed"))
print("outside_comment_page_window=%d" % sum(1 for _, _, b in unanswered if b))
print("median_over_answered_subset_hours=%.2f" % (med / 3600) if med is not None else "median=undefined")
print("median_over_answered_subset_days=%.3f" % (med / 86400) if med is not None else "")
PY
  sed 's/^/  /' "$WORK/triage.txt"
  A=$("$GREP" -o 'answered_by_maintainer_comment=[0-9]*' "$WORK/triage.txt" | cut -d= -f2)
  U=$("$GREP" -o 'unanswered=[0-9]*' "$WORK/triage.txt" | cut -d= -f2)
  CL=$("$GREP" -o 'closed_without_a_maintainer_comment=[0-9]*' "$WORK/triage.txt" | cut -d= -f2)
  OW=$("$GREP" -o 'outside_comment_page_window=[0-9]*' "$WORK/triage.txt" | cut -d= -f2)
  assert "$(eq "$A" "2")" \
    "2 of the 10 most recently opened issues carry a maintainer comment, which is why the decision reports two figures and not one median"
  assert "$(eq "$U" "8")" "8 of the 10 carry no maintainer comment on the fetched page"
  assert "$(eq "$CL" "4")" "4 of those 8 were nonetheless closed, which is the second figure"
  assert "$(gt0 "$OW")" \
    "at least one of the 8 was opened before the fetched comment page's window, so its silence is unproven rather than measured — a limit the decision states"
fi
echo

# ---------------------------------------------------------------------------
echo "=== RESULT ==="
echo "PASS=${pass} FAIL=${failn} SKIP=${skipn} TOTAL=$((pass + failn + skipn))"
if [ "$failn" -gt 0 ]; then echo "RESULT: FAIL"; exit 1; fi
echo "RESULT: PASS"
