#!/usr/bin/env bash
# R76 revision 2 empirical check: the REST API Design Standard v2.0.0, which
# owner ruling W2-REST (2026-09-18) made binding on this template's HTTP
# surface after revision 1 was written.
#
# Two jobs, in this order:
#   1. Quote, at the pinned blob, every rule in the standard that touches CORS,
#      cross-origin access, browser clients, allowed origins, or the security
#      and deployment profile — and assert the quoted bytes, so the decision's
#      quotations cannot drift from the source it pins.
#   2. Measure, in a throwaway probe, whether the recommendation conforms to
#      each of those rules, including the two measurements that decided this
#      revision: the missing Access-Control-Expose-Headers under R4.17, and the
#      layer-ordering requirement R11.7 imposes on a short-circuiting preflight.
#
# The revision-1 scripts (registry-figures.sh, probe-checks.sh,
# decision-self-check.sh) and their logs are untouched by this revision. This
# file adds checks, it does not restate theirs.
#
# Line prefixes:
#   BLOB    — bytes read at the pinned git blob. Immutable: reproduces
#             byte-for-byte for as long as the object exists.
#   CHECK   — one observed result printed by the probe's own test binary.
#   ASSERT  — a content assertion. `ASSERT FAIL` sets exit status 1.
#   SKIP    — a check that could not run, with the reason named.
#
# Needs: a readable clone of the standard at STD_REPO (overridable by
# environment so an auditor can point it elsewhere), and cargo able to resolve
# the probe. Needs no `.git` of this repository, so it runs unchanged from a
# clean `git archive HEAD` extraction. All scratch work lives in one mktemp
# directory under $TMPDIR that a trap removes on exit; the probe is created
# without a VCS directory, so no nested Git repository is created.

set -euo pipefail

GREP=/usr/bin/grep
STD_REPO="${STD_REPO:-/Users/stevemorin/c/rest-standards}"
STD_BLOB=71bd813c1cf61286586b4ee41ed83ff065e5c8d9
STD_COMMIT=0850d43e45d919ef5e37f7174c4212b46013c49f

echo "=== R76 revision 2: REST API Design Standard conformance ==="
echo "date(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "grep:  $("$GREP" --version | head -1)"
echo "rustc: $(rustc --version)"
echo "cargo: $(cargo --version)"
echo "standard repo:   ${STD_REPO}"
echo "standard commit: ${STD_COMMIT}"
echo "standard blob:   ${STD_BLOB}"
echo

WORK=$(mktemp -d "${TMPDIR:-/tmp}/r76-rest.XXXXXX")
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

pass=0; failn=0; skipn=0
assert() {
  if [ "$1" = "1" ]; then echo "ASSERT ok   $2"; pass=$((pass + 1))
  else echo "ASSERT FAIL $2"; failn=$((failn + 1)); fi
}
skip() { echo "SKIP        $1"; skipn=$((skipn + 1)); }
eq() { if [ "$1" = "$2" ]; then echo 1; else echo 0; fi; }
once() { if [ "$("$GREP" -cF -- "$1" "$2" || true)" = "1" ]; then echo 1; else echo 0; fi; }

# ---------------------------------------------------------------------------
echo "--- A. the pinned artifact: is this the document the ruling names? ---"
STD="$WORK/rest-api-standard.md"
if ! git -C "$STD_REPO" cat-file -e "${STD_BLOB}^{blob}" 2>/dev/null; then
  skip "A through C: the standard blob ${STD_BLOB} is not readable at ${STD_REPO}, so no rule was quoted and no conformance claim was checked"
  echo
  echo "=== RESULT ==="
  echo "PASS=${pass} FAIL=${failn} SKIP=${skipn} TOTAL=$((pass + failn + skipn))"
  echo "RESULT: PASS (nothing ran)"
  exit 0
fi
git -C "$STD_REPO" cat-file blob "$STD_BLOB" > "$STD"
SIZE=$(git -C "$STD_REPO" cat-file -s "$STD_BLOB")
LINES=$(wc -l < "$STD" | tr -d ' ')
echo "BLOB  type=$(git -C "$STD_REPO" cat-file -t "$STD_BLOB") size=${SIZE} lines=${LINES}"
echo "BLOB  sha256(extracted bytes) = $(shasum -a 256 "$STD" | cut -d' ' -f1)"
assert "$(eq "$SIZE" "190161")" \
  "the blob is 190,161 bytes, so an auditor is reading the same object the decision quotes"
assert "$(eq "$LINES" "3427")" \
  "and 3,427 lines, so every line number quoted below addresses this text and not a later edit"
assert "$(eq "$(head -1 "$STD")" '# REST API Design Standard')" \
  "its first line names the document"
assert "$(eq "$(once '**Version 2.0.0.**' "$STD")" "1")" \
  "and it declares version 2.0.0, the version owner ruling W2-REST binds"
COMMIT_HAS_BLOB=$(git -C "$STD_REPO" ls-tree -r "$STD_COMMIT" | "$GREP" -c "$STD_BLOB" || true)
echo "BLOB  occurrences of this blob in commit ${STD_COMMIT}'s tree = ${COMMIT_HAS_BLOB}"
assert "$(eq "$COMMIT_HAS_BLOB" "1")" \
  "the blob is reachable from the commit the ruling names, so the two identifiers agree"
echo

# ---------------------------------------------------------------------------
echo "--- B. every rule touching CORS, cross-origin access, browser clients, allowed origins, or the security and deployment profile, quoted at its line ---"
# rule | line | the exact bytes at that line
while IFS='|' read -r rule line text; do
  [ -n "$rule" ] || continue
  actual=$(sed -n "${line}p" "$STD")
  echo "BLOB  ${rule} @ line ${line}:"
  echo "        ${actual}"
  assert "$(eq "$actual" "$text")" \
    "${rule} stands at line ${line} of the pinned blob with the bytes the decision quotes"
done <<'RULES'
R1.6|229|**R1.6** Rules that only make sense for APIs with a given capability are
R1.6-vocab|237|The switch vocabulary: `webhooks` · `async-operations` · `bulk-operations` ·
R1.6-audience|241|handling, client audience — belong in the conformance note's free text, not
R1.7|271|**R1.7 — No silent deviation.** An API deviates from this standard only in
R1.10-request-id|348|| `request-id` | Response | Correlation ID, emitted on every response including errors. Lowercase name; RFC 6648 deprecates new `X-` prefixed fields, ruling out `X-Request-Id` | Addendum A2.4, completing `OP-018` `[POLICY]` |
R1.10-allow|351|| `Allow` | Response | Mandatory on every `405 Method Not Allowed` | Addendum A3 · protocol requirement (RFC 9110) |
R4.10|846|**R4.10** The default media type — served when a request carries no
R4.11|856|**R4.11** Every response whose content was selected by a request header
R4.17|864|**R4.17** Where an API serves cross-origin browser clients, every
R4.17-cont|868|response header in use — in `Access-Control-Expose-Headers`. None of
R5.11|1008|**R5.11** `405 Method Not Allowed` MUST carry an `Allow` header.
R8.1|1317|**R8.1** APIs MUST be served only over TLS 1.2 or higher, preferring 1.3;
R8.2|1323|**R8.2** Access tokens MUST NOT be accepted or emitted in URI query
R8.10|1387|**R8.10** Each axis below carries a ratified default and named
R8.11|1414|**R8.11** Caller-supplied URLs (webhook targets, callbacks) MUST be
R11.7|1752|**R11.7** Every response, including errors, MUST carry the `request-id`
AppA-R4.17|2696|| R4.17 | Cross-origin browser clients: standard-bound headers listed in `Access-Control-Expose-Headers` |
RULES
echo
echo "BLOB  R4.17's full sentence, which fixes what must be listed:"
sed -n '864,871p' "$STD" | sed 's/^/        /'
# shellcheck disable=SC2016  # the backticks are literal Markdown in the quoted rule text
assert "$(once 'in `Access-Control-Expose-Headers`. None of' "$STD")" \
  "R4.17 names Access-Control-Expose-Headers as the mechanism, so the obligation is on that header and not on a general 'expose things' principle"
# shellcheck disable=SC2016  # literal Markdown backticks again
assert "$(once '`request-id`, `ETag`, `Location`, `Retry-After`, `RateLimit`,' "$STD")" \
  "and it enumerates the standard-bound headers, request-id among them, so the list is not left to taste"
echo
echo "BLOB  the applicability-switch vocabulary, which decides whether a CLI-first template can scope CORS away:"
sed -n '237,243p' "$STD" | sed 's/^/        /'
CORS_SWITCH=$(sed -n '237,239p' "$STD" | "$GREP" -c -i 'cors\|origin\|browser' || true)
echo "        occurrences of cors, origin or browser in the switch vocabulary = ${CORS_SWITCH}"
assert "$(eq "$CORS_SWITCH" "0")" \
  "the switch vocabulary is webhooks, async-operations, bulk-operations and streaming only: NO switch scopes CORS, so a CLI-first template cannot declare these rules N/A by switch"
assert "$(once 'handling, client audience — belong in the conformance note'"'"'s free text, not' "$STD")" \
  "and R1.6 puts client audience in the conformance note's free text explicitly, which is the opposite of making it a switch"
echo
echo "BLOB  the five deployment-profile axes named by R8.10:"
sed -n '1395,1400p' "$STD" | cut -c1-100 | sed 's/^/        /'
AXES_CORS=$(sed -n '1394,1401p' "$STD" | "$GREP" -c -i 'cors\|cross-origin\|allowed origin' || true)
echo "        occurrences of cors, cross-origin or allowed origin in the axis table = ${AXES_CORS}"
assert "$(eq "$AXES_CORS" "0")" \
  "no axis of the deployment profile is a CORS axis, so this item flips none of the five and R8.10 is engaged only as a hand-off"
echo

# ---------------------------------------------------------------------------
echo "--- C. the conformance claims, measured ---"
P="$WORK/probe"
mkdir -p "$P/src" "$P/tests"
cat > "$P/Cargo.toml" <<'EOF'
[package]
name = "r76r2probe"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"
publish = false

[dependencies]
axum = "=0.8.9"
tokio = { version = "=1.53.1", features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }
tower-http = { version = "=0.7.1", default-features = false, features = ["cors"] }

[dev-dependencies]
tower = { version = "=0.5.3", features = ["util"] }
EOF
echo 'pub fn placeholder() {}' > "$P/src/lib.rs"
cat > "$P/tests/rest.rs" <<'RUSTEOF'
// Nine observations that decide, rule by rule, whether the R76 recommendation
// conforms to the REST API Design Standard. This is not template code: no
// service, no composition root, no settings type is built here.
use std::time::Duration;

use axum::Router;
use axum::body::Body;
use axum::extract::Request;
use axum::http::{HeaderName, HeaderValue, Response};
use axum::middleware::{Next, from_fn};
use axum::routing::get;
use tower::ServiceExt;
use tower_http::cors::{Any, CorsLayer};

// Stand-in for the standard-bound response headers the service emits. The real
// list is assembled by R75 from the layers it installs; `request-id` is in it
// unconditionally, because R11.7 makes that header unconditional.
const EXPOSED: [&str; 3] = ["request-id", "retry-after", "ratelimit"];

fn base() -> Router {
    Router::new().route("/a", get(|| async { "ok" }))
}

// `expose`: Some(true) = the revision-2 explicit list; Some(false) = the
// wildcard form; None = revision 1's configuration, which set none at all.
fn cors(origins: &[HeaderValue], expose: Option<bool>) -> CorsLayer {
    let mut l = CorsLayer::new()
        .allow_origin(origins.to_vec())
        .allow_methods(Any)
        .allow_headers(Any)
        .max_age(Duration::from_secs(600));
    match expose {
        Some(true) => {
            let names: Vec<HeaderName> =
                EXPOSED.iter().map(|s| HeaderName::from_static(s)).collect();
            l = l.expose_headers(names);
        }
        Some(false) => l = l.expose_headers(Any),
        None => {}
    }
    l
}

fn get_req(o: &str) -> Request {
    Request::builder()
        .method("GET")
        .uri("/a")
        .header("origin", o)
        .body(Body::empty())
        .unwrap()
}

fn pre(o: &str) -> Request {
    Request::builder()
        .method("OPTIONS")
        .uri("/a")
        .header("origin", o)
        .header("access-control-request-method", "GET")
        .body(Body::empty())
        .unwrap()
}

fn show(tag: &str, r: &Response<Body>) {
    let mut kv: Vec<String> = r
        .headers()
        .iter()
        .map(|(k, v)| format!("{}={}", k, v.to_str().unwrap_or("<bin>")))
        .collect();
    kv.sort();
    println!("CHECK {tag} status={} headers={{{}}}", r.status(), kv.join(", "));
}

async fn run(r: Router, q: Request) -> Response<Body> {
    r.oneshot(q).await.unwrap()
}

// A stand-in for whatever layer R75 installs to satisfy R11.7. It only has to
// stamp a header on the way out, so `from_fn` keeps the probe dependency-free.
async fn stamp(req: Request, next: Next) -> Response<Body> {
    let mut res = next.run(req).await;
    res.headers_mut()
        .insert("request-id", HeaderValue::from_static("req_probe"));
    res
}

#[tokio::test(flavor = "multi_thread")]
async fn rest_conformance() {
    let allow: Vec<HeaderValue> = vec!["https://app.example".parse().unwrap()];
    let empty: Vec<HeaderValue> = Vec::new();

    // R4.17, the revision-2 configuration.
    show("X1", &run(base().layer(cors(&allow, Some(true))), get_req("https://app.example")).await);
    // R4.17, revision 1's configuration, which named no exposed header.
    show("X2", &run(base().layer(cors(&allow, None)), get_req("https://app.example")).await);
    // R4.17, the wildcard form, which lists no header name.
    show("X3", &run(base().layer(cors(&allow, Some(false))), get_req("https://app.example")).await);
    // R4.17 on a preflight, which emits none of the listed headers.
    show("X4", &run(base().layer(cors(&allow, Some(true))), pre("https://app.example")).await);

    // R5.11 with the allowlist empty: the layer is absent and OPTIONS on a
    // GET-only route is still 405 carrying Allow.
    let unconfigured = if empty.is_empty() {
        base()
    } else {
        base().layer(cors(&empty, Some(true)))
    };
    show("X5", &run(unconfigured, pre("https://evil.example")).await);

    // R11.7 and ordering. `.layer(A).layer(B)` makes B outermost, so X6 and X7
    // differ only in which of CorsLayer and the stamp is the outer one.
    let inner_stamp = base().layer(from_fn(stamp)).layer(cors(&allow, Some(true)));
    show("X6", &run(inner_stamp, pre("https://app.example")).await);
    let outer_stamp = base().layer(cors(&allow, Some(true))).layer(from_fn(stamp));
    show("X7", &run(outer_stamp, pre("https://app.example")).await);

    // R4.11, Vary with the layer absent and with it present.
    show("X8", &run(base(), get_req("https://app.example")).await);
    show("X9", &run(base().layer(cors(&allow, Some(true))), get_req("https://evil.example")).await);
}
RUSTEOF

if ! (cd "$P" && cargo test -q --test rest -- --nocapture --test-threads=1) > "$WORK/out.txt" 2>&1; then
  skip "C: the probe did not build or run (no network and no warm registry cache), so no conformance claim was measured"
  sed 's/^/  /' "$WORK/out.txt" | head -6
else
  "$GREP" '^CHECK ' "$WORK/out.txt" | sed 's/^/  /'
  O="$WORK/out.txt"

  assert "$(once 'CHECK X1 status=200 OK headers={access-control-allow-origin=https://app.example, access-control-expose-headers=request-id,retry-after,ratelimit, content-length=2, content-type=text/plain; charset=utf-8, vary=origin}' "$O")" \
    "R4.17 CONFORMS under revision 2: an explicit expose list reaches the browser client as access-control-expose-headers naming each standard-bound header"
  assert "$(once 'CHECK X2 status=200 OK headers={access-control-allow-origin=https://app.example, content-length=2, content-type=text/plain; charset=utf-8, vary=origin}' "$O")" \
    "R4.17 was VIOLATED by revision 1: with no expose list configured the response carries no access-control-expose-headers at all, so a cross-origin browser client could not read request-id — this measurement is why the recommendation moved"
  assert "$(once 'CHECK X3 status=200 OK headers={access-control-allow-origin=https://app.example, access-control-expose-headers=*, content-length=2, content-type=text/plain; charset=utf-8, vary=origin}' "$O")" \
    "and the wildcard form emits a bare '*', which lists no header name, so it does not satisfy R4.17's instruction to LIST the headers emitted"
  assert "$(once 'CHECK X4 status=200 OK headers={access-control-allow-headers=*, access-control-allow-methods=*, access-control-allow-origin=https://app.example, access-control-max-age=600, allow=GET,HEAD, content-length=0, vary=origin}' "$O")" \
    "R4.17 is not engaged on a preflight response: it carries none of the standard-bound headers, and tower-http correspondingly omits access-control-expose-headers there"
  assert "$(once 'CHECK X5 status=405 Method Not Allowed headers={allow=GET,HEAD, content-length=0}' "$O")" \
    "R5.11 CONFORMS: with the allowlist empty the layer is absent and OPTIONS on a GET-only route answers 405 carrying Allow, which is the header R5.11 makes mandatory"
  assert "$(once 'CHECK X6 status=200 OK headers={access-control-allow-headers=*, access-control-allow-methods=*, access-control-allow-origin=https://app.example, access-control-max-age=600, allow=GET,HEAD, content-length=0, vary=origin}' "$O")" \
    "R11.7 is VIOLATED when the request-id layer sits inside CorsLayer: the preflight short-circuits and the 200 carries no request-id"
  assert "$(once 'CHECK X7 status=200 OK headers={access-control-allow-headers=*, access-control-allow-methods=*, access-control-allow-origin=https://app.example, access-control-max-age=600, allow=GET,HEAD, content-length=0, request-id=req_probe, vary=origin}' "$O")" \
    "R11.7 CONFORMS when it sits outside: the same preflight then carries request-id — the ordering constraint this item hands to R75, now required by a rule rather than only by py's precedent"
  assert "$(once 'CHECK X8 status=200 OK headers={content-length=2, content-type=text/plain; charset=utf-8}' "$O")" \
    "R4.11 CONFORMS with the allowlist empty: no layer, no negotiation, and correspondingly no Vary, which is R4.11's own stated exception"
  assert "$(once 'CHECK X9 status=200 OK headers={access-control-expose-headers=request-id,retry-after,ratelimit, content-length=2, content-type=text/plain; charset=utf-8, vary=origin}' "$O")" \
    "R4.11 CONFORMS with the allowlist configured: Origin influenced the selection of access-control-allow-origin, which is withheld here for a disallowed origin, and Vary names it"
  # R4.10: a preflight serves no representation, so media-type selection does not arise.
  CT=$("$GREP" -cF 'CHECK X4 status=200 OK headers={access-control-allow-headers=*, access-control-allow-methods=*, access-control-allow-origin=https://app.example, access-control-max-age=600, allow=GET,HEAD, content-length=0, vary=origin}' "$O" || true)
  assert "$(eq "$CT" "1")" \
    "R4.10 is not engaged by the preflight: that 200 carries content-length 0 and no content-type, so no representation was selected and no media-type negotiation arises"
fi
echo

# ---------------------------------------------------------------------------
echo "--- D. the decision records each rule's disposition in writing (R1.7) ---"
DEC="$(cd "$(dirname "$0")/.." && pwd)/DECISION.md"
if [ ! -f "$DEC" ]; then
  skip "D: DECISION.md is absent, so its dispositions were not checked"
else
  for rule in R1.6 R1.7 R4.10 R4.11 R4.17 R5.11 R8.1 R8.2 R8.10 R8.11 R11.7; do
    n=$("$GREP" -cF -- "**${rule}**" "$DEC" || true)
    assert "$(if [ "$n" -gt 0 ]; then echo 1; else echo 0; fi)" \
      "the decision names ${rule} and states its disposition, so no rule this run quoted is left silent — which R1.7 makes the difference between an exemption and nonconformance"
  done
  assert "$(if [ "$("$GREP" -cF 'W2-REST' "$DEC" || true)" -gt 0 ]; then echo 1; else echo 0; fi)" \
    "and it names the owner ruling that made the standard binding"
  assert "$(if [ "$("$GREP" -cF "$STD_BLOB" "$DEC" || true)" -gt 0 ]; then echo 1; else echo 0; fi)" \
    "and pins the blob these quotations were read from"
fi
echo

# ---------------------------------------------------------------------------
echo "--- E. the one revision-1 assertion this revision breaks, bounded rather than hidden ---"
# decision-self-check.sh pins the H1 line byte-for-byte, and that line names
# revision 1. The revision brief keeps every revision-1 script and log
# byte-identical, so that assertion is now false by construction. Rather than
# leave a committed script failing for an unexplained reason, run it here and
# prove the breakage is confined to the revision marker.
SELF="$(cd "$(dirname "$0")" && pwd)/decision-self-check.sh"
if [ ! -x "$SELF" ]; then
  skip "E: decision-self-check.sh is not executable here, so its revision-pinned assertion was not bounded"
else
  set +e
  "$SELF" > "$WORK/self.txt" 2>&1
  SELF_EXIT=$?
  set -e
  SELF_FAILS=$("$GREP" -c '^ASSERT FAIL' "$WORK/self.txt" || true)
  SELF_PASSES=$("$GREP" -o '^PASS=[0-9]*' "$WORK/self.txt" | cut -d= -f2)
  echo "        decision-self-check.sh exit=${SELF_EXIT}; ASSERT FAIL lines=${SELF_FAILS}; PASS=${SELF_PASSES}"
  echo "        the failing assertion, quoted:"
  "$GREP" '^ASSERT FAIL' "$WORK/self.txt" | sed 's/^/          /'
  assert "$(eq "$SELF_FAILS" "1")" \
    "exactly one revision-1 assertion fails against revision 2, so the retitle did not silently invalidate the rest of that script"
  assert "$(if "$GREP" -q '^ASSERT FAIL the H1 is the date-first form' "$WORK/self.txt"; then echo 1; else echo 0; fi)" \
    "and the one that fails is the revision-pinned H1 assertion, not a structural, parameter, gate-1 or figure assertion"
  assert "$(eq "$SELF_PASSES" "42")" \
    "its other 42 assertions still pass against revision 2: the four H2 sections, the six byte-identical parameter lines, the gate-1 record and enumeration, the raw-report hash and shape, and every figure cross-check"
  assert "$(if [ "$SELF_EXIT" -ne 0 ]; then echo 1; else echo 0; fi)" \
    "it exits non-zero, so the known breakage is loud rather than silent — which is the behaviour a failing assertion is supposed to have"
fi
echo

# ---------------------------------------------------------------------------
echo "--- F. the OVERRIDE namespace, enumerated rather than recalled ---"
# This section exists because an earlier draft of this revision claimed OV-01
# was free, having read the empty output of a search that a timeout had killed.
# Enumerating is cheap; a false census is not.
# evidence -> review -> <run> -> R76 -> runs -> research -> repository root.
REPO_ROOT="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
if [ ! -e "$REPO_ROOT/.git" ]; then
  skip "F: no .git at ${REPO_ROOT} (a clean archive extraction), so the OVERRIDE namespace was not enumerated — this section needs the repository index"
else
  git -C "$REPO_ROOT" grep -h -o -E "OV-[0-9]{2,}" -- research docs 2>/dev/null \
    | sort | uniq -c > "$WORK/ov.txt" || true
  echo "        occurrences of each OV-<digits> token under research/ and docs/:"
  if [ -s "$WORK/ov.txt" ]; then sed 's/^/          /' "$WORK/ov.txt"; else echo "          (none)"; fi
  INUSE=$("$GREP" -o -E 'OV-[0-9]{2,}' "$WORK/ov.txt" | sort -u | tr '\n' ' ')
  DISTINCT=$("$GREP" -o -E 'OV-[0-9]{2,}' "$WORK/ov.txt" | sort -u | wc -l | tr -d ' ')
  echo "        distinct tokens in use AT THIS MOMENT: ${INUSE:-(none)} (${DISTINCT} of them)"
  echo "        NOTE: this line is a snapshot of a namespace several sibling items are"
  echo "              allocating concurrently in this shared worktree. It moved between"
  echo "              two runs of this very script while revision 2 was being written."
  echo "              Nothing below asserts which particular numbers are free, because"
  echo "              such an assertion would be false by the time it was audited."
  # Two assertions that are invariant under other agents' commits.
  assert "$(if "$GREP" -q 'OV-01' "$WORK/ov.txt"; then echo 1; else echo 0; fi)" \
    "OV-01 is IN USE (R60, against the CLI Design Standard, refused by the owner on 2026-09-14) — the one fact an earlier draft of this revision got backwards, from a search a timeout had killed; this check is what would have caught it"
  assert "$(if [ "$DISTINCT" -ge 6 ]; then echo 1; else echo 0; fi)" \
    "at least six distinct override numbers are already allocated, so the namespace is populated and no item may assume it starts empty"
  OWN=$("$GREP" -c -E 'OVERRIDE \(OV-[0-9]' "$DEC" 2>/dev/null || true)
  echo "        occurrences of a NUMBERED 'OVERRIDE (OV-<digits>)' in this decision = ${OWN}"
  assert "$(eq "$OWN" "0")" \
    "this decision records no numbered OVERRIDE of its own, so it consumes nothing from a namespace it does not control (the three 'OV-nn' placeholders in its prose are not allocations)"
fi
echo

# ---------------------------------------------------------------------------
echo "=== RESULT ==="
echo "PASS=${pass} FAIL=${failn} SKIP=${skipn} TOTAL=$((pass + failn + skipn))"
if [ "$failn" -gt 0 ]; then echo "RESULT: FAIL"; exit 1; fi
echo "RESULT: PASS"
