#!/usr/bin/env bash
# R70 — re-verification of every load-bearing external figure in raw/opus.md.
# Single-engine synthesis: the Codex leg is deferred (owner ruling W1-CODEX3),
# so every published figure the decision relies on is re-fetched here.
#
# Deterministic PASS/FAIL/SKIP lines go to stdout (this log reproduces
# byte-for-byte while upstream does not publish a new release).  Moving
# counters (download counts, star counts, pushed_at, open-issue totals) are
# written to registry-figures.log instead, which is a point-in-time snapshot
# and is NOT expected to reproduce.
set -euo pipefail
set -o pipefail

UA="https://github.com/smorinlabs/rs-launch-blueprint"
GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0

here="$(cd "$(dirname "$0")" && pwd)"
FIGURES="$here/registry-figures.log"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/r70-registry.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT

ok()   { PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }
skip() { SKIP=$((SKIP+1)); printf 'SKIP  %s\n' "$1"; }

# assert <label> <expected> <actual>
assert() {
  if [ "$2" = "$3" ]; then ok "$1 == $2"; else bad "$1: expected [$2] got [$3]"; fi
}

# fetch <url> <outfile> -> prints HTTP status, returns non-zero on transport error
fetch() {
  curl -sS -m 40 -A "$UA" -o "$2" -w '%{http_code}' "$1"
}

jq_py() { local code="$1"; shift; python3 -c "$code" "$@"; }

# has_phrase <file> <phrase> -> exit 0 when the phrase occurs in the file after
# collapsing every run of whitespace.  RFC bodies are hard-wrapped at 72
# columns, so a sentence that spans a line break is invisible to a line-oriented
# grep; this compares the sentence, not the wrapping.
has_phrase() { python3 -c '
import re, sys
text = re.sub(r"\s+", " ", open(sys.argv[1], encoding="utf-8", errors="replace").read())
sys.exit(0 if sys.argv[2] in text else 1)
' "$1" "$2"; }

# phrase <label> <file> <phrase>
phrase() {
  if has_phrase "$2" "$3"; then ok "$1"; else bad "$1 — phrase not found: $3"; fi
}

: > "$FIGURES"
printf 'R70 registry figures — point-in-time snapshot, NOT reproducible.\n' >> "$FIGURES"
printf 'retrieved: %s\n\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$FIGURES"

printf '=== R70 registry re-verification ===\n'
printf 'host date (UTC): %s\n' "$(date -u +%Y-%m-%d)"
printf 'curl: %s\n' "$(curl --version | head -1)"
printf 'grep: %s\n' "$($GREP --version | head -1)"
printf 'python3: %s\n\n' "$(python3 --version 2>&1)"

############################################################
printf -- '--- 1. crates.io: problem_details (the recommended envelope crate)\n'
############################################################
code=$(fetch "https://crates.io/api/v1/crates/problem_details" "$scratch/pd.json") || true
assert "crates.io /crates/problem_details HTTP" "200" "$code"
if [ "$code" = "200" ]; then
  assert "problem_details max_stable_version" "0.10.0" \
    "$(jq_py 'import json,sys;print(json.load(open(sys.argv[1]))["crate"]["max_stable_version"])' "$scratch/pd.json")"
  # moving counters -> figures file only
  jq_py 'import json,sys
d=json.load(open(sys.argv[1]))["crate"]
print("problem_details recent_downloads(90d) =", d["recent_downloads"])
print("problem_details downloads(all-time)  =", d["downloads"])' "$scratch/pd.json" >> "$FIGURES"
else
  skip "problem_details crate figures (endpoint unavailable)"
fi

code=$(fetch "https://crates.io/api/v1/crates/problem_details/versions" "$scratch/pdv.json") || true
assert "crates.io /crates/problem_details/versions HTTP" "200" "$code"
if [ "$code" = "200" ]; then
  read -r num created rustv lic <<EOF
$(jq_py 'import json,sys
vs=[v for v in json.load(open(sys.argv[1]))["versions"] if not v["yanked"]]
v=vs[0]
print(v["num"], v["created_at"], v.get("rust_version"), v.get("license"))' "$scratch/pdv.json")
EOF
  assert "problem_details newest non-yanked num" "0.10.0" "$num"
  assert "problem_details 0.10.0 created_at (second precision)" "2026-08-16T14:36:14" "${created:0:19}"
  assert "problem_details 0.10.0 rust_version (gate 2)" "1.85" "$rustv"
  # gate 1 is inapplicable (owner ruling 2026-09-12 Q7.B); the licence string is
  # recorded as a figure only, never as a gate result.
  printf 'problem_details 0.10.0 license (recorded, not gated) = %s\n' "$lic" >> "$FIGURES"
else
  skip "problem_details version figures (endpoint unavailable)"
fi

code=$(fetch "https://crates.io/api/v1/crates/problem_details/0.10.0/dependencies" "$scratch/pdd.json") || true
assert "crates.io /problem_details/0.10.0/dependencies HTTP" "200" "$code"
if [ "$code" = "200" ]; then
  assert "problem_details 0.10.0 non-optional normal deps" "http" \
    "$(jq_py 'import json,sys
ds=json.load(open(sys.argv[1]))["dependencies"]
print(",".join(sorted({d["crate_id"] for d in ds if d["kind"]=="normal" and not d["optional"]})))' "$scratch/pdd.json")"
  assert "problem_details 0.10.0 optional deps (frameworks and encoders, gated by feature)" "actix-web,axum,http-serde,poem,quick-xml,serde,serde_json,utoipa" \
    "$(jq_py 'import json,sys
ds=json.load(open(sys.argv[1]))["dependencies"]
print(",".join(sorted({d["crate_id"] for d in ds if d["kind"]=="normal" and d["optional"]})))' "$scratch/pdd.json")"
  assert "problem_details 0.10.0 axum req (does not widen R69 features)" "^0.8|false|json" \
    "$(jq_py 'import json,sys
ds=json.load(open(sys.argv[1]))["dependencies"]
d=[x for x in ds if x["crate_id"]=="axum" and x["kind"]=="normal"][0]
print("%s|%s|%s" % (d["req"], str(d["default_features"]).lower(), ",".join(d["features"])))' "$scratch/pdd.json")"
else
  skip "problem_details dependency figures (endpoint unavailable)"
fi

############################################################
printf -- '\n--- 2. crates.io: the rest of the category\n'
############################################################
for c in problemdetails http-api-problem http-problem rfc7807; do
  code=$(fetch "https://crates.io/api/v1/crates/$c/versions" "$scratch/$c.json") || true
  assert "crates.io /crates/$c/versions HTTP" "200" "$code"
  if [ "$code" != "200" ]; then skip "$c version figures"; continue; fi
  jq_py 'import json,sys
vs=[v for v in json.load(open(sys.argv[1]))["versions"] if not v["yanked"]]
v=vs[0]
print("%s newest non-yanked: %s %s rust_version=%s license=%s" % (sys.argv[2], v["num"], v["created_at"], v.get("rust_version"), v.get("license")))' "$scratch/$c.json" "$c" >> "$FIGURES"
done

# The two exclusions the decision carries rest on gate 2 (declared MSRV), so
# they are asserted, not merely printed.
if [ -s "$scratch/http-api-problem.json" ]; then
  assert "http-api-problem: versions declaring rust_version (gate 2 exclusion)" "0" \
    "$(jq_py 'import json,sys
vs=json.load(open(sys.argv[1]))["versions"]
print(sum(1 for v in vs if v.get("rust_version")))' "$scratch/http-api-problem.json")"
  assert "http-api-problem newest non-yanked num" "0.60.0" \
    "$(jq_py 'import json,sys
vs=[v for v in json.load(open(sys.argv[1]))["versions"] if not v["yanked"]]
print(vs[0]["num"])' "$scratch/http-api-problem.json")"
fi
if [ -s "$scratch/http-problem.json" ]; then
  assert "http-problem: versions declaring rust_version (gate 2 exclusion)" "0" \
    "$(jq_py 'import json,sys
vs=json.load(open(sys.argv[1]))["versions"]
print(sum(1 for v in vs if v.get("rust_version")))' "$scratch/http-problem.json")"
fi
if [ -s "$scratch/problemdetails.json" ]; then
  assert "problemdetails newest non-yanked rust_version (runner-up, gate 2)" "1.85.1" \
    "$(jq_py 'import json,sys
vs=[v for v in json.load(open(sys.argv[1]))["versions"] if not v["yanked"]]
print(vs[0].get("rust_version"))' "$scratch/problemdetails.json")"
fi

code=$(fetch "https://crates.io/api/v1/crates/http-problem/0.3.0/dependencies" "$scratch/hpd.json") || true
assert "crates.io /http-problem/0.3.0/dependencies HTTP" "200" "$code"
if [ "$code" = "200" ]; then
  assert "http-problem 0.3.0 requires an http 0.x (cannot join an http 1.5 tree)" "^0.2.8" \
    "$(jq_py 'import json,sys
ds=json.load(open(sys.argv[1]))["dependencies"]
print([d["req"] for d in ds if d["crate_id"]=="http" and d["kind"]=="normal"][0])' "$scratch/hpd.json")"
  assert "http-problem 0.3.0 axum req" "^0.6" \
    "$(jq_py 'import json,sys
ds=json.load(open(sys.argv[1]))["dependencies"]
print([d["req"] for d in ds if d["crate_id"]=="axum" and d["kind"]=="normal"][0])' "$scratch/hpd.json")"
fi

############################################################
printf -- '\n--- 3. MSRV floor: the current stable channel\n'
############################################################
code=$(fetch "https://static.rust-lang.org/dist/channel-rust-stable.toml" "$scratch/stable.toml") || true
assert "static.rust-lang.org stable channel HTTP" "200" "$code"
if [ "$code" = "200" ]; then
  stable=$($GREP -A2 '^\[pkg.rust\]' "$scratch/stable.toml" | $GREP '^version' | head -1 | sed -E 's/.*"([0-9]+\.[0-9]+)\.[0-9]+ .*/\1/')
  assert "current stable minor" "1.98" "$stable"
  floor=$(python3 -c "print('1.%d' % (int('${stable#1.}') - 2))")
  assert "stable-minus-2 MSRV floor" "1.96" "$floor"
  $GREP -m1 '^date' "$scratch/stable.toml" >> "$FIGURES"
fi

############################################################
printf -- '\n--- 4. RustSec: advisories (gate 3)\n'
############################################################
for c in problem_details problemdetails http-api-problem http-problem http-serde; do
  code=$(curl -sS -m 40 -A "$UA" -o /dev/null -w '%{http_code}' "https://rustsec.org/packages/$c.html") || true
  assert "rustsec.org/packages/$c.html (404 == no advisory)" "404" "$code"
done
code=$(fetch "https://rustsec.org/packages/http.html" "$scratch/http.html") || true
assert "rustsec.org/packages/http.html (has advisories)" "200" "$code"
if [ "$code" = "200" ]; then
  for adv in RUSTSEC-2019-0033 RUSTSEC-2019-0034; do
    if $GREP -q "$adv" "$scratch/http.html"; then ok "http advisory $adv listed"; else bad "http advisory $adv missing"; fi
  done
  # The tree resolves http 1.5.0; both advisories are patched in >= 0.1.20.
  code=$(fetch "https://raw.githubusercontent.com/rustsec/advisory-db/main/crates/http/RUSTSEC-2019-0033.md" "$scratch/a33.md") || true
  if [ "$code" = "200" ] && $GREP -q 'patched = \[">= 0.1.20"\]' "$scratch/a33.md"; then
    ok 'RUSTSEC-2019-0033 patched_versions = [">= 0.1.20"] (http 1.5.0 unaffected)'
  else
    bad "RUSTSEC-2019-0033 patched range not as reported (HTTP $code)"
  fi
fi

############################################################
printf -- '\n--- 5. RFC 9457 and its IANA registration (the standard this item adopts)\n'
############################################################
code=$(fetch "https://datatracker.ietf.org/doc/rfc9457/doc.json" "$scratch/9457.json") || true
assert "datatracker rfc9457 doc.json HTTP" "200" "$code"
if [ "$code" = "200" ]; then
  assert "RFC 9457 std_level" "Proposed Standard" \
    "$(jq_py 'import json,sys;print(json.load(open(sys.argv[1]))["std_level"])' "$scratch/9457.json")"
  assert "RFC 9457 stream" "IETF" \
    "$(jq_py 'import json,sys;print(json.load(open(sys.argv[1]))["stream"])' "$scratch/9457.json")"
  assert "RFC 9457 title" "Problem Details for HTTP APIs" \
    "$(jq_py 'import json,sys;print(json.load(open(sys.argv[1]))["title"])' "$scratch/9457.json")"
fi

code=$(fetch "https://www.rfc-editor.org/rfc/rfc9457.txt" "$scratch/9457.txt") || true
assert "rfc-editor rfc9457.txt HTTP" "200" "$code"
if [ "$code" = "200" ]; then
  # 3.1.1 "type": an absent member is assumed to be "about:blank", so omitting
  # it is conformant -- the ground for the envelope contract's omission rule.
  phrase 'RFC 9457 3.1.1: an absent "type" has the value "about:blank" (omission conformant)' \
    "$scratch/9457.txt" 'When this member is not present, its value is assumed to be "about:blank".'
  # 3.2 Extension Members: the ground for carrying R67's token as "code".
  phrase "RFC 9457 3.2: a problem type MAY extend the object with additional members" \
    "$scratch/9457.txt" "Problem type definitions MAY extend the problem details object with additional members that are specific to that problem type."
  phrase "RFC 9457 3.2: names an \"errors\" extension by example (the field-error carrier)" \
    "$scratch/9457.txt" 'the "validation error" example defines an "errors" extension'
  # Section numbering: raw/opus.md cites 3.1.2 for "title" and 3.1.3 for
  # "status".  The RFC numbers them the other way round; this pins the true
  # order so the correction in the decision is checkable.
  for pair in '3.1.1:type' '3.1.2:status' '3.1.3:title' '3.1.4:detail' '3.1.5:instance'; do
    sec=${pair%%:*}; mem=${pair##*:}
    if $GREP -q "^$sec\.  \"$mem\"$" "$scratch/9457.txt"; then
      ok "RFC 9457 section $sec is the \"$mem\" member"
    else
      bad "RFC 9457 section $sec is not \"$mem\""
    fi
  done
fi

code=$(fetch "https://www.iana.org/assignments/media-types/application.csv" "$scratch/iana.csv") || true
assert "IANA application media types CSV HTTP" "200" "$code"
if [ "$code" = "200" ]; then
  for row in 'problem+json,application/problem+json' 'problem+xml,application/problem+xml'; do
    if $GREP -q "^$row" "$scratch/iana.csv"; then ok "IANA registers $row"; else bad "IANA row $row not found"; fi
  done
  if $GREP "^problem+json,application/problem+json" "$scratch/iana.csv" | $GREP -q 'RFC9457'; then
    ok "IANA problem+json cites RFC9457"
  else
    bad "IANA problem+json does not cite RFC9457"
  fi
fi

############################################################
printf -- '\n--- 6. RFC 9110: the two header obligations the funnel must not drop\n'
############################################################
code=$(fetch "https://www.rfc-editor.org/rfc/rfc9110.txt" "$scratch/9110.txt") || true
assert "rfc-editor rfc9110.txt HTTP" "200" "$code"
if [ "$code" = "200" ]; then
  phrase "RFC 9110 15.5.2: a 401 MUST send WWW-Authenticate with at least one challenge" \
    "$scratch/9110.txt" "The server generating a 401 response MUST send a WWW-Authenticate header field (Section 11.6.1) containing at least one challenge"
  phrase "RFC 9110 15.5.6: an origin server MUST generate Allow in a 405" \
    "$scratch/9110.txt" "The origin server MUST generate an Allow header field in a 405 response containing a list of the target resource's currently supported methods."
  # 401 vs 403: the decision puts RSLB402 (credentials rejected) on 401, not 403.
  phrase "RFC 9110 15.5.2: rejected credentials are a 401 (the RSLB402 row)" \
    "$scratch/9110.txt" "If the request included authentication credentials, then the 401 response indicates that authorization has been refused for those credentials."
  phrase "RFC 9110 15.5.4: 403 is for credentials the server considers insufficient (no such catalog code yet)" \
    "$scratch/9110.txt" "the server considers them insufficient to grant access"
  # The line numbers raw/opus.md cites for these three sections.
  for pair in '7548:15.5.2.  401 Unauthorized' '7569:15.5.4.  403 Forbidden' '7601:15.5.6.  405 Method Not Allowed'; do
    ln=${pair%%:*}; heading=${pair#*:}
    actual=$(sed -n "${ln}p" "$scratch/9110.txt")
    assert "rfc9110.txt line $ln" "$heading" "$actual"
  done
fi

############################################################
printf -- '\n--- 7. GitHub REST (keyring gh; one call per 20 s)\n'
############################################################
if ! command -v gh >/dev/null 2>&1; then
  skip "GitHub REST checks: gh not installed"
elif ! gh auth status >/dev/null 2>&1; then
  skip "GitHub REST checks: gh not authenticated"
else
  gh_api() { sleep 20; gh api "$1" > "$2" 2>"$scratch/gh.err"; }
  if gh_api "repos/frenetisch-applaudierend/problem-details-rs" "$scratch/repo.json"; then
    assert "problem-details-rs archived (gate: not abandoned)" "False" \
      "$(jq_py 'import json,sys;print(json.load(open(sys.argv[1]))["archived"])' "$scratch/repo.json")"
    assert "problem-details-rs default_branch" "main" \
      "$(jq_py 'import json,sys;print(json.load(open(sys.argv[1]))["default_branch"])' "$scratch/repo.json")"
    jq_py 'import json,sys
d=json.load(open(sys.argv[1]))
print("problem-details-rs stars=%s pushed_at=%s subscribers=%s" % (d["stargazers_count"], d["pushed_at"], d["subscribers_count"]))' "$scratch/repo.json" >> "$FIGURES"
  else
    skip "repos/frenetisch-applaudierend/problem-details-rs ($(head -1 "$scratch/gh.err" 2>/dev/null))"
  fi

  if gh_api "search/issues?q=repo:frenetisch-applaudierend/problem-details-rs+is:issue+is:open" "$scratch/issues.json"; then
    jq_py 'import json,sys
print("problem-details-rs open issues (search/issues total_count) =", json.load(open(sys.argv[1]))["total_count"])' "$scratch/issues.json" >> "$FIGURES"
    ok "search/issues open-issue count retrieved (moving figure -> registry-figures.log)"
  else
    skip "search/issues for problem-details-rs ($(head -1 "$scratch/gh.err" 2>/dev/null))"
  fi

  # The report's practice evidence: ISRG's janus uses the EXCLUDED crate.
  if gh_api "repos/divviup/janus/contents/Cargo.toml" "$scratch/janus.json"; then
    python3 -c "
import base64, json, sys
d = json.load(open(sys.argv[1]))
open(sys.argv[2], 'wb').write(base64.b64decode(d['content']))" "$scratch/janus.json" "$scratch/janus.toml"
    if $GREP -q 'http-api-problem' "$scratch/janus.toml"; then
      ok "divviup/janus Cargo.toml declares http-api-problem ($($GREP -m1 'http-api-problem' "$scratch/janus.toml" | tr -s ' '))"
    else
      bad "divviup/janus Cargo.toml no longer declares http-api-problem"
    fi
  else
    skip "repos/divviup/janus/contents/Cargo.toml ($(head -1 "$scratch/gh.err" 2>/dev/null))"
  fi

  # The deliberate counter-example: Oxide's dropshot ships a bespoke body.
  if gh_api "repos/oxidecomputer/dropshot/contents/dropshot/src/error.rs" "$scratch/drop.json"; then
    python3 -c "
import base64, json, sys
d = json.load(open(sys.argv[1]))
open(sys.argv[2], 'wb').write(base64.b64decode(d['content']))" "$scratch/drop.json" "$scratch/dropshot.rs"
    if $GREP -q 'pub struct HttpErrorResponseBody' "$scratch/dropshot.rs" &&
       ! $GREP -qi 'problem+json' "$scratch/dropshot.rs"; then
      ok "oxidecomputer/dropshot: HttpErrorResponseBody present and no problem+json (bespoke body)"
    else
      bad "dropshot error.rs no longer matches the reported counter-example"
    fi
  else
    skip "repos/oxidecomputer/dropshot/contents/dropshot/src/error.rs ($(head -1 "$scratch/gh.err" 2>/dev/null))"
  fi

  # The crate's CI: the gate-4 gap the decision records (no macOS runner).
  if gh_api "repos/frenetisch-applaudierend/problem-details-rs/contents/.github/workflows/rust.yml" "$scratch/ci.json"; then
    python3 -c "
import base64, json, sys
d = json.load(open(sys.argv[1]))
open(sys.argv[2], 'wb').write(base64.b64decode(d['content']))" "$scratch/ci.json" "$scratch/rust.yml"
    if $GREP -q 'runs-on: ubuntu-latest' "$scratch/rust.yml" && ! $GREP -qi 'macos' "$scratch/rust.yml"; then
      ok "problem-details-rs CI runs ubuntu-latest and has NO macOS runner (gate 4 gap, as reported)"
    else
      bad "problem-details-rs CI no longer matches the reported ubuntu-only shape"
    fi
    if $GREP -q '1.85' "$scratch/rust.yml"; then
      ok "problem-details-rs CI pins an MSRV job at 1.85"
    else
      bad "problem-details-rs CI MSRV pin 1.85 not found"
    fi
  else
    skip "problem-details-rs .github/workflows/rust.yml ($(head -1 "$scratch/gh.err" 2>/dev/null))"
  fi
fi

############################################################
printf '\n=== summary ===\n'
printf 'PASS %d  FAIL %d  SKIP %d  TOTAL %d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS+FAIL+SKIP))"
if [ "$FAIL" -ne 0 ]; then exit 1; fi
exit 0
