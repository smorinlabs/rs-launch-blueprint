#!/usr/bin/env bash
# R75 check E6 — the decision's shape, its assumes lines, and every file:line citation.
#  S: H2 structure matches the published R69 decision; title, revision line, one re-verify.
#  P: each `- assumes` line is byte-identical to the registry row in inputs/parameters.json
#     and inputs/PARAMETERS.md; no `- owns` line; no line-initial CONFLICT:. Compared with awk
#     through ENVIRON: macOS BSD grep 2.6.0 exits 2 ("out of memory") on a fixed-string
#     pattern as long as R58's 6,796-character value.
#  C: every `raw/<f>:<n>`, `inputs/<f>:<n>`, R69 `DECISION.md:<n>` and crate-source
#     `<crate>-<ver>/<path>:<n>` citation resolves to an existing line, and the load-bearing
#     ones contain the text the decision attributes to them.
# Run from anywhere; paths resolve relative to this script.
# The t() helper evals its condition, so conditions are single-quoted on purpose and the
# variables they name are read only inside that eval:
# shellcheck disable=SC2016,SC2034
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
run="$(cd "$here/../.." && pwd)"
repo="$(cd "$run/../../../.." && pwd)"
dec="$run/review/DECISION.md"
r69="$repo/research/topics/69-web-framework-stack/DECISION.md"
reg="$(find "$CARGO_HOME/registry/src" -mindepth 1 -maxdepth 1 -type d | head -1)"
pass=0 fail=0
ok() { pass=$((pass + 1)); echo "PASS $1 $2"; }
ko() { fail=$((fail + 1)); echo "FAIL $1 $2"; }
t() { if eval "$2"; then ok "$1" "$3"; else ko "$1" "$3"; fi; }

echo "== E6 decision-shape-check — $(date -u +%Y-%m-%dT%H:%M:%SZ) (UTC)"
echo "== DECISION sha256 $(shasum -a 256 "$dec" | cut -d' ' -f1), $(wc -l < "$dec" | tr -d ' ') lines"

# --- S: shape -------------------------------------------------------------------------
mine="$(grep -E '^## ' "$dec" | tr '\n' '|')"
theirs="$(grep -E '^## ' "$r69" | tr '\n' '|')"
t S01 '[[ "$mine" == "$theirs" ]]' "H2 set equals published R69's: $mine"
t S02 '[[ "$(sed -n 1p "$dec")" =~ ^#\ 2026-09-27\ —\ R75\ —\ http-middleware-stack\ \(bundle,\ Deep\)\ —\ decision\ \(revision\ 3\)$ ]]' "title line"
t S03 'grep -qE "^Revision 1: actor \`synth-opus-[^\`]+\`, model \`claude-opus-5-5\`" "$dec"' "revision-1 actor/model line"
t S04 '[[ $(grep -c "^re-verify: " "$dec") -eq 1 ]]' "exactly one re-verify: line"
t S05 'awk "/^## Decision/{d=1} /^## Parameters/{d=0} d && /^### Principles and implementation$/{f=1} END{exit !f}" "$dec"' "### Principles and implementation inside ## Decision"
t S06 '! grep -qE "^## Supersedes" "$dec"' "no ## Supersedes (nothing published)"
t S07 'grep -q "Settled ledger rows: F317, F318, F319, F320, F321, F327" "$dec"' "settled F rows stated"
t S08 '! grep -q "/Users/" "$dec"' "no home-directory path in the decision"

# --- P: parameters ----------------------------------------------------------------------
while IFS=$'\t' read -r p v; do
  line="- assumes $p = $v"
  t "P-$p" 'L="$line" awk '"'"'$0 == ENVIRON["L"] {f = 1} END {exit !f}'"'"' "$dec"' "byte-identical to inputs/parameters.json"
  t "P-$p-md" 'P="| $p | " V="| $v |" awk '"'"'index($0, ENVIRON["P"]) == 1 && index($0, ENVIRON["V"]) {f = 1} END {exit !f}'"'"' "$run/inputs/PARAMETERS.md"' "value matches inputs/PARAMETERS.md row"
done < <(jq -r '.[] | [.param, .value] | @tsv' "$run/inputs/parameters.json")
t P10 '[[ $(grep -c "^- assumes " "$dec") -eq $(jq length "$run/inputs/parameters.json") ]]' "assumes-line count equals consumed+fixed parameter count"
t P11 '! grep -qE "^- owns " "$dec"' "no owns line (prompt owns: empty)"
t P12 '! grep -qE "^CONFLICT:" "$dec"' "no CONFLICT: line"

# --- C: citations resolve -----------------------------------------------------------------
resolve() { # id file first-line [regex]
  local id="$1" f="$2" n="$3" re="${4:-}" len
  if [[ ! -f "$f" ]]; then ko "$id" "missing file ${f#"$repo"/}"; return; fi
  len="$(wc -l < "$f" | tr -d ' ')"
  if (( n < 1 || n > len )); then ko "$id" "${f#"$repo"/}:$n beyond $len lines"; return; fi
  if [[ -n "$re" ]] && ! sed -n "${n},$((n + 8))p" "$f" | grep -qE -- "$re"; then
    ko "$id" "${f#"$repo"/}:$n lacks /$re/"; return
  fi
  ok "$id" "${f#"$repo"/}:$n${re:+ ~ /$re/}"
}
# Every raw/ and inputs/ citation in the decision, mechanically.
while read -r ref; do
  f="${ref%%:*}"; rest="${ref#*:}"
  for n in $(tr ',' ' ' <<< "$rest" | grep -oE '[0-9]+(-[0-9]+)?' | cut -d- -f1); do
    resolve "C-auto" "$run/$f" "$n"
  done
done < <(grep -oE '(raw|inputs)/[a-z.-]+\.(md|json):[0-9]+(-[0-9]+)?' "$dec" | sort -u)
# Every R69 DECISION.md:<n> citation, mechanically.
while read -r n; do resolve "C-r69" "$r69" "$n"; done \
  < <(grep -oE '`DECISION\.md:[0-9]+' "$dec" | grep -oE '[0-9]+$' | sort -un)
# Content at the load-bearing citations.
resolve C01 "$run/inputs/prompt.md" 9 'response.headers\["x-request-id"\] = request_id'
resolve C02 "$run/inputs/prompt.md" 9 'set unconditionally, including HSTS over plain http in dev'
resolve C03 "$run/inputs/prompt.md" 23 '^- owns:$'
resolve C04 "$run/inputs/prompt.md" 24 '^- consumes: R58: logging-pipeline-contract'
resolve C05 "$run/raw/muse.md" 181 'Sees every response'
resolve C06 "$run/raw/muse.md" 174 'overriding'
resolve C07 "$run/raw/opus.md" 538 'setdefault.*middleware.py:120'
resolve C08 "$run/raw/opus.md" 290 'innermost'
resolve C09 "$run/raw/opus.md" 291 'TraceLayer. \*\*outside\*\*'
resolve C10 "$run/raw/opus.md" 391 'BASELINE-REVIEW: F317'
resolve C11 "$run/raw/opus.md" 397 'BASELINE-REVIEW: F321'
resolve C12 "$run/raw/opus.md" 379 'BASELINE-REVIEW: F327'
resolve C13 "$run/raw/doxa-openai.normalized.md" 95 'does not overwrite'
resolve C14 "$run/raw/doxa-openai.normalized.md" 108 'Do not substitute .if_not_present'
resolve C15 "$run/raw/doxa-openai.normalized.md" 138 'Uri::path'
resolve C16 "$run/raw/doxa-gemini.normalized.md" 223 'owns web-middleware-stack'
resolve C17 "$run/raw/doxa-gemini.normalized.md" 224 'assumes rust-version = 1.80'
resolve C18 "$run/raw/doxa-gemini.normalized.md" 53 'outside\* of the tracing middleware'
resolve C19 "$r69" 694 "tower-http. \(R75's to select\)"
resolve C20 "$r69" 943 "per-request layer is R75's to decide"
resolve C21 "$r69" 1586 'web = \["dep:axum", "dep:tokio"\]'
resolve C22 "$r69" 1586 'tower 0.5.3 is a dev-dependency only'
resolve C23 "$r69" 2197 '^\| C11 \| Middleware order'
resolve C24 "$r69" 2210 'owner ruling 2026-09-12 \(Q7.B\)'
resolve C25 "$r69" 1424 'middleware.rs. \(R75\)'
resolve C26 "$reg/tower-http-0.7.1/src/request_id.rs" 454 'if let Some\(current_id\) = response.headers\(\)'
resolve C27 "$reg/tower-http-0.7.1/src/set_header/response/mod.rs" 174 'SetMultipleResponseHeadersLayer'
resolve C28 "$reg/tower-http-0.7.1/src/set_header/response/multiple_headers.rs" 69 'pub fn if_not_present'
resolve C29 "$reg/tower-http-0.7.1/src/lib.rs" 200 'deny\(unsafe_code\)'
resolve C30 "$reg/tower-http-0.7.1/Cargo.toml" 14 'rust-version = "1.65"'
resolve C31 "$reg/tower-http-0.7.1/src/timeout/service.rs" 145 'Response::new\(B::default\(\)\)'
resolve C32 "$reg/tower-http-0.7.1/src/catch_panic.rs" 351 'INTERNAL_SERVER_ERROR'
resolve C33 "$reg/axum-0.8.9/src/routing/mod.rs" 311 'fallback_router: this.fallback_router.layer'
resolve C34 "$reg/axum-0.8.9/src/routing/mod.rs" 303 'L: Layer<Route> \+ Clone \+ Send \+ Sync'
resolve C35 "$reg/axum-0.8.9/src/serve/listener.rs" 156 'error!\("accept error'
resolve C36 "$reg/axum-0.8.9/src/serve/mod.rs" 369 'trace!\("connection'
resolve C37 "$reg/axum-0.8.9/src/docs/middleware.md" 61 'bottom to top'
canon="$repo/research/topics/75-http-middleware-stack/prompts/http-middleware-stack.prompt.md"
resolve C38 "$canon" 26 '^- engines: muse, opus, doxa$'
resolve C39 "$run/inputs/prompt.md" 26 '^- engines: codex, opus, doxa$'
resolve C50 "$repo/research/RUNBOOK.md" 72 'Q17.A'
t C51 '[[ $(diff "$run/inputs/prompt.md" "$canon" | grep -c "^[<>]") -eq 4 && $(diff "$run/inputs/prompt.md" "$canon" | grep -cE "^[0-9]+c[0-9]+$") -eq 2 ]]' "snapshot vs canonical prompt: exactly two changed lines"
t C52 '[[ "$(diff "$run/inputs/prompt.md" "$canon" | grep -E "^[0-9]+c[0-9]+$" | tr "\n" " ")" == "26c26 76c76 " ]]' "the changed lines are 26 and 76"
# Evidence-log facts the decision quotes.
ev="$run/review/evidence"
t C40 'grep -q "== host: 16 pass, 0 fail" "$ev/stack-acceptance.log" && grep -q "== 1.96.0: 16 pass, 0 fail" "$ev/stack-acceptance.log"' "E1 16/16 on both toolchains"
t C41 'grep -q "== 12 pass, 0 fail" "$ev/negative-controls.log"' "E2 12/12"
t C42 'grep -q "== 6 pass, 0 fail" "$ev/framework-log-foldin.log" && grep -q "TALLY target=axum::serve level=TRACE count=7" "$ev/framework-log-foldin.log"' "E3 6/6 and the axum::serve TRACE tally"
t C43 '! grep -q "^GAP" "$ev/figures.log" && grep -q "CRATE tower-http newest_non_yanked=0.7.1" "$ev/figures.log"' "E4 no gaps; tower-http 0.7.1 newest"
t C44 'grep -q "unique packages in the normal tree: 58" "$ev/probe-crate.log" && [[ $(sed -n "/ONLY through tower-http/,\$p" "$ev/probe-crate.log" | grep -c " v[0-9]") -eq 5 ]]' "E0 58 packages, 5 only via tower-http"
t C45 'grep -q "5e89a57d3a9d8513487aeee2fa4e2f07afde2eddc7c3584ae90c3be7b01d43cb" "$ev/probe-crate.log" && grep -q "5e89a57d3a9d8513487aeee2fa4e2f07afde2eddc7c3584ae90c3be7b01d43cb" "$dec"' "lockfile hash in log and decision agree"
t C46 'grep -q "CRATESIO-MIDDLEWARE 89:.*REQUEST_TIMEOUT" "$ev/practice-check.log" && grep -q "AXUM-GRACEFUL 43:.*REQUEST_TIMEOUT" "$ev/practice-check.log"' "408 precedent in axum example and crates.io"
t C47 'grep -q "TOWER-HTTP-CI 82:.*macos-latest" "$ev/practice-check.log"' "tower-http CI covers macos-latest"
t C48 'for s in "$ev"/*.sh; do [[ -f "${s%.sh}.log" ]] || exit 1; done' "every evidence .sh has a .log"
t C49 'shellcheck "$ev"/*.sh' "every evidence .sh is shellcheck-clean"
# R58r2, the published prerequisite revision 3 adopts (pinned by sha; cited as R58r2 `:<n>`).
r58="$repo/research/topics/58-logging-pipeline-architecture/DECISION.md"
t C53 '[[ "$(shasum -a 256 "$r58" | cut -d" " -f1)" == 8dc8ce955c58abd508d45bd74a6b2c3f9eb96bde5c43ae20538f2439c8867aae ]]' "R58r2 sha256 is the adopted revision"
resolve C54 "$r58" 246 'ruling out `X-Request-Id`'
resolve C55 "$r58" 252 'R11.7 \(MUST\).*`request-id` correlation header'
resolve C56 "$r58" 253 'R11.8 \(MUST\).*traceparent. MUST be propagated'
resolve C57 "$r58" 276 'must still accept and forward'
resolve C58 "$r58" 105 '\(R75, F320, F327\)'
resolve C59 "$r58" 658 'R75 owns F320 and F327'
resolve C60 "$r58" 1175 "F327 is R75's row"
resolve C61 "$r58" 1249 'named \*\*`request_id`\*\*'
t C62 'O="$(sed -n 1485p "$r58")" awk '"'"'index(ENVIRON["O"], "- owns logging-pipeline-contract = ") == 1 && $0 == "- assumes logging-pipeline-contract = " substr(ENVIRON["O"], 36) {f = 1} END {exit !f}'"'"' "$dec"' "assumes line equals R58r2 :1485 owned value"

echo "== $pass pass, $fail fail"
(( fail == 0 ))
