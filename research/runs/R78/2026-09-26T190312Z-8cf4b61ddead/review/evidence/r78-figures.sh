#!/usr/bin/env bash
# R78 synthesis evidence 1 of 3 — registry, GitHub and RustSec figures, and the
# version-compatibility edges the four engine reports disagree on.
#
# Endpoints (the prompt's named figure sources only):
#   https://crates.io/api/v1/crates/<name>                  crate.recent_downloads, crate.downloads
#   https://crates.io/api/v1/crates/<name>/versions         newest yanked:false num, created_at, rust_version, license, features
#   https://crates.io/api/v1/crates/<name>/<ver>/dependencies  dependency requirements
#   https://crates.io/api/v1/crates/<name>/reverse_dependencies meta.total
#   https://api.github.com/repos/<o>/<r>                    stargazers_count, archived, pushed_at
#   https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open  total_count
#   https://api.github.com/repos/<o>/<r>/issues (+ /comments) the 10 most recently opened issues
#   https://rustsec.org/packages/<name>.html                open advisories
#
# Usage: bash r78-figures.sh > r78-figures.log 2>&1   (from any directory)
# Exit status: number of failed checks (0 = all passed).

set -uo pipefail

UA='rs-launch-blueprint-research R78 synthesis (steve@conceptm.com)'
CRATES='https://crates.io/api/v1/crates'
GREP=/usr/bin/grep
PASS=0
FAIL=0
N=0

check() { # check <id> <description> <command...>
  local id=$1 desc=$2
  shift 2
  N=$((N + 1))
  if "$@"; then
    PASS=$((PASS + 1))
    printf 'PASS %s %s\n' "$id" "$desc"
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL %s %s\n' "$id" "$desc"
  fi
}

crates_get() { # crates_get <path-after-/crates/>
  sleep 1
  curl -fsS -A "$UA" "$CRATES/$1"
}

WORK=$(mktemp -d "${TMPDIR:-/tmp}/r78-figures.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

echo "# r78-figures — run $(date -u +%Y-%m-%dT%H:%M:%SZ) (UTC)"
echo "# host: $(uname -srm); curl: $(curl --version | head -n 1); jq: $(jq --version); gh: $(gh --version | head -n 1)"
echo

echo "## 1. Crate figures (crates.io)"
printf '%-44s %12s %13s %-10s %-10s %-8s %s\n' crate 90d-dl all-time-dl newest date rust_ver license
for c in opentelemetry opentelemetry_sdk opentelemetry-otlp opentelemetry-http tracing-opentelemetry \
  opentelemetry-appender-tracing opentelemetry-stdout opentelemetry-zipkin opentelemetry-jaeger \
  axum-tracing-opentelemetry tracing-opentelemetry-instrumentation-sdk init-tracing-opentelemetry \
  reqwest-tracing tracing-otel fastrace fastrace-opentelemetry minitrace tracing tracing-subscriber; do
  crates_get "$c" > "$WORK/$c.json" || { echo "fetch failed: $c"; continue; }
  crates_get "$c/versions" > "$WORK/$c.versions.json" || { echo "fetch failed: $c/versions"; continue; }
  jq -r --slurpfile v "$WORK/$c.versions.json" --arg c "$c" '
    ($v[0].versions | map(select(.yanked == false)) | .[0]) as $n |
    [$c, (.crate.recent_downloads|tostring), (.crate.downloads|tostring), $n.num,
     ($n.created_at|.[0:10]), ($n.rust_version // "none"), ($n.license // "none")] | @tsv' \
    "$WORK/$c.json" | awk -F'\t' '{printf "%-44s %12s %13s %-10s %-10s %-8s %s\n",$1,$2,$3,$4,$5,$6,$7}'
done
echo

newest() { jq -r '[.versions[] | select(.yanked == false)][0].num' "$WORK/$1.versions.json"; }
newest_date() { jq -r '[.versions[] | select(.yanked == false)][0].created_at' "$WORK/$1.versions.json"; }

check C01 "tracing-opentelemetry newest non-yanked is 0.34.0" test "$(newest tracing-opentelemetry)" = 0.34.0
check C02 "tracing-opentelemetry 0.34.0 published 2026-09-23" test "$(newest_date tracing-opentelemetry | cut -c1-10)" = 2026-09-23
for c in opentelemetry opentelemetry_sdk opentelemetry-otlp opentelemetry-http opentelemetry-appender-tracing; do
  check "C03-$c" "$c newest non-yanked is 0.33.0 (2026-09-18)" \
    test "$(newest "$c") $(newest_date "$c" | cut -c1-10)" = "0.33.0 2026-09-18"
done
for c in opentelemetry opentelemetry_sdk opentelemetry-otlp opentelemetry-http tracing-opentelemetry; do
  rv=$(jq -r '[.versions[] | select(.yanked == false)][0].rust_version' "$WORK/$c.versions.json")
  check "C04-$c" "$c newest declares rust_version 1.75.0 (<= the 1.96 floor)" test "$rv" = 1.75.0
done
echo

echo "## 2. Version-compatibility edges (crates.io /<ver>/dependencies, normal kind)"
edge() { # edge <crate> <version> <dep> -> prints req
  crates_get "$1/$2/dependencies" |
    jq -r --arg d "$3" '[.dependencies[] | select(.crate_id == $d and .kind == "normal") | .req] | join(",")'
}
tro34=$(edge tracing-opentelemetry 0.34.0 opentelemetry)
tro33=$(edge tracing-opentelemetry 0.33.0 opentelemetry)
trs34=$(edge tracing-opentelemetry 0.34.0 tracing-subscriber)
tr34=$(edge tracing-opentelemetry 0.34.0 tracing)
echo "tracing-opentelemetry 0.34.0 -> opentelemetry $tro34 ; tracing-subscriber $trs34 ; tracing $tr34"
echo "tracing-opentelemetry 0.33.0 -> opentelemetry $tro33"
check V01 "bridge 0.34.0 requires opentelemetry ^0.33.0" test "$tro34" = '^0.33.0'
check V02 "bridge 0.33.0 requires opentelemetry ^0.32.0 (the previous pairing)" test "$tro33" = '^0.32.0'
check V03 "bridge 0.34.0 requires tracing-subscriber ^0.3.22" test "$trs34" = '^0.3.22'

atov=$(newest axum-tracing-opentelemetry)
ato_ot=$(edge axum-tracing-opentelemetry "$atov" opentelemetry)
ato_tro=$(edge axum-tracing-opentelemetry "$atov" tracing-opentelemetry)
ato_axum=$(edge axum-tracing-opentelemetry "$atov" axum)
echo "axum-tracing-opentelemetry $atov -> opentelemetry '$ato_ot' ; tracing-opentelemetry '$ato_tro' ; axum '$ato_axum'"
tosv=$(newest tracing-opentelemetry-instrumentation-sdk)
tos_ot=$(edge tracing-opentelemetry-instrumentation-sdk "$tosv" opentelemetry)
tos_tro=$(edge tracing-opentelemetry-instrumentation-sdk "$tosv" tracing-opentelemetry)
echo "tracing-opentelemetry-instrumentation-sdk $tosv -> opentelemetry '$tos_ot' ; tracing-opentelemetry '$tos_tro'"
check V04 "axum-tracing-opentelemetry newest still requires the 0.32 generation (not ^0.33)" \
  bash -c "[[ '$ato_ot$tos_ot' != *0.33* && '$tos_ot' == *0.32* ]]"
itov=$(newest init-tracing-opentelemetry)
ito_ot=$(edge init-tracing-opentelemetry "$itov" opentelemetry)
echo "init-tracing-opentelemetry $itov -> opentelemetry '$ito_ot'"
fov=$(newest fastrace-opentelemetry)
fo_ot=$(edge fastrace-opentelemetry "$fov" opentelemetry)
echo "fastrace-opentelemetry $fov -> opentelemetry '$fo_ot'"
check V05 "fastrace-opentelemetry newest requires opentelemetry 0.32 (not 0.33)" \
  bash -c "[[ '$fo_ot' == *0.32* && '$fo_ot' != *0.33* ]]"
totv=$(newest tracing-otel)
tot_ot=$(edge tracing-otel "$totv" opentelemetry)
echo "tracing-otel $totv -> opentelemetry '$tot_ot'"
rtv=$(newest reqwest-tracing)
rt_feats=$(jq -r '[.versions[] | select(.yanked == false)][0].features | keys | map(select(startswith("opentelemetry_"))) | join(" ")' \
  "$WORK/reqwest-tracing.versions.json")
echo "reqwest-tracing $rtv opentelemetry_* features: $rt_feats"
check V06 "reqwest-tracing newest offers no opentelemetry_0_33 feature" \
  bash -c "[[ ' $rt_feats ' != *' opentelemetry_0_33 '* && ' $rt_feats ' == *' opentelemetry_0_32 '* ]]"
# reqwest enters the otel tree through opentelemetry-otlp's reqwest-blocking-client.
otlp_rq=$(crates_get "opentelemetry-otlp/0.33.0/dependencies" | jq -r '[.dependencies[] | select(.crate_id == "reqwest" and .kind == "normal") | "\(.req) optional=\(.optional)"] | join(",")')
rq_th=$(crates_get "reqwest/0.13.5/dependencies" | jq -r '[.dependencies[] | select(.crate_id == "tower-http" and .kind == "normal") | "\(.req) optional=\(.optional)"] | join(",")')
echo "opentelemetry-otlp 0.33.0 -> reqwest $otlp_rq ; reqwest 0.13.5 -> tower-http $rq_th"
check V07 "reqwest 0.13.5 depends on tower-http ^0.6.8 non-optionally (otel brings tower-http 0.6)" \
  test "$rq_th" = '^0.6.8 optional=false'
echo

echo "## 3. Default features and the metrics side effect (crates.io /versions features map)"
feat() { jq -r --arg v "$2" --arg f "$3" '.versions[] | select(.num == $v) | .features[$f] // [] | join(",")' "$WORK/$1.versions.json"; }
echo "opentelemetry-otlp 0.33.0 default    = [$(feat opentelemetry-otlp 0.33.0 default)]"
echo "opentelemetry-otlp 0.33.0 http-proto = [$(feat opentelemetry-otlp 0.33.0 http-proto)]"
echo "opentelemetry-otlp 0.33.0 retry-ish features: $(jq -r '.versions[] | select(.num=="0.33.0") | .features | keys | map(select(test("retry"))) | join(" ")' "$WORK/opentelemetry-otlp.versions.json")"
echo "opentelemetry_sdk 0.33.0 default     = [$(feat opentelemetry_sdk 0.33.0 default)]"
echo "opentelemetry_sdk 0.33.0 has testing = $(jq -r '.versions[] | select(.num=="0.33.0") | .features | has("testing")' "$WORK/opentelemetry_sdk.versions.json")"
echo "tracing-opentelemetry 0.34.0 default = [$(feat tracing-opentelemetry 0.34.0 default)]"
check F01 "otlp 0.33.0 default includes http-proto and reqwest-blocking-client" \
  bash -c "[[ ',$(feat opentelemetry-otlp 0.33.0 default),' == *,http-proto,* && ',$(feat opentelemetry-otlp 0.33.0 default),' == *,reqwest-blocking-client,* ]]"
check F02 "otlp 0.33.0 default does not include grpc-tonic" \
  bash -c "[[ ',$(feat opentelemetry-otlp 0.33.0 default),' != *,grpc-tonic,* ]]"
check F03 "otlp 0.33.0 http-proto feature itself enables metrics" \
  bash -c "[[ ',$(feat opentelemetry-otlp 0.33.0 http-proto),' == *,metrics,* ]]"
check F04 "bridge 0.34.0 default features are metrics + tracing-log" \
  test "$(feat tracing-opentelemetry 0.34.0 default | tr ',' '\n' | sort | paste -sd, -)" = "metrics,tracing-log"
echo

echo "## 4. Reverse dependencies (crates.io reverse_dependencies meta.total)"
for c in opentelemetry_sdk opentelemetry-otlp tracing-opentelemetry axum-tracing-opentelemetry reqwest-tracing fastrace-opentelemetry; do
  printf '%-32s %s\n' "$c" "$(crates_get "$c/reverse_dependencies?per_page=1" | jq -r '.meta.total')"
done
echo

echo "## 5. GitHub repository figures (authenticated gh api)"
printf '%-50s %7s %-8s %-20s %s\n' repo stars archived pushed_at open_issues
for r in open-telemetry/opentelemetry-rust tokio-rs/tracing-opentelemetry tokio-rs/tracing \
  davidB/tracing-opentelemetry-instrumentation-sdk fast/fastrace TrueLayer/reqwest-middleware; do
  gh api "repos/$r" > "$WORK/repo.json" 2>/dev/null || { echo "repo fetch failed: $r"; continue; }
  oi=$(gh api "search/issues?q=repo:$r+is:issue+is:open&per_page=1" --jq '.total_count' 2>/dev/null || echo NA)
  jq -r --arg r "$r" --arg oi "$oi" '[$r, (.stargazers_count|tostring), (.archived|tostring), .pushed_at, $oi] | @tsv' "$WORK/repo.json" |
    awk -F'\t' '{printf "%-50s %7s %-8s %-20s %s\n",$1,$2,$3,$4,$5}'
  [ "$r" = tokio-rs/tracing-opentelemetry ] && bridge_stars=$(jq -r .stargazers_count "$WORK/repo.json")
  [ "$r" = tokio-rs/tracing ] && tracing_stars=$(jq -r .stargazers_count "$WORK/repo.json")
done
check G01 "bridge repo has under 1,000 stars (Gemini's 6.9k is not the bridge's figure)" test "${bridge_stars:-99999}" -lt 1000
check G02 "tokio-rs/tracing has over 5,000 stars (the figure Gemini's 6.9k matches in magnitude)" test "${tracing_stars:-0}" -gt 5000
echo

echo "## 6. Issue responsiveness — 10 most recently opened issues (PRs excluded)"
echo "#    first response = first comment whose author_association is OWNER, MEMBER or COLLABORATOR"
for r in open-telemetry/opentelemetry-rust tokio-rs/tracing-opentelemetry; do
  gh api "repos/$r/issues?state=all&sort=created&direction=desc&per_page=100" \
    --jq '[.[] | select(.pull_request == null)][0:10][] | [.number, .created_at, .comments] | @tsv' > "$WORK/issues.tsv" 2>/dev/null
  : > "$WORK/days.txt"
  unanswered=0
  while IFS=$'\t' read -r num created _ncom; do
    first=$(gh api "repos/$r/issues/$num/comments?per_page=100" \
      --jq '[.[] | select(.author_association == "OWNER" or .author_association == "MEMBER" or .author_association == "COLLABORATOR")][0].created_at // ""' 2>/dev/null)
    if [ -z "$first" ]; then
      unanswered=$((unanswered + 1))
      printf '  #%-6s created %s  no maintainer comment\n' "$num" "$created"
    else
      d=$(jq -n --arg a "$created" --arg b "$first" '(($b|fromdateiso8601) - ($a|fromdateiso8601)) / 86400 | . * 10 | round / 10')
      echo "$d" >> "$WORK/days.txt"
      printf '  #%-6s created %s  first maintainer response after %s days\n' "$num" "$created" "$d"
    fi
  done < "$WORK/issues.tsv"
  med=$(sort -n "$WORK/days.txt" | awk '{a[NR]=$1} END {if (NR==0) print "n/a"; else if (NR%2) print a[(NR+1)/2]; else print (a[NR/2]+a[NR/2+1])/2}')
  echo "$r: sampled $(wc -l < "$WORK/issues.tsv" | tr -d ' ') issues; median first response ${med} days over answered; unanswered ${unanswered}"
done
echo

echo "## 7. RustSec package pages (HTTP status and advisory IDs on the page)"
for c in opentelemetry opentelemetry_sdk opentelemetry-otlp opentelemetry-http tracing-opentelemetry \
  opentelemetry-jaeger minitrace atty; do
  code=$(curl -sS -A "$UA" -o "$WORK/rs.html" -w '%{http_code}' "https://rustsec.org/packages/$c.html")
  ids=$($GREP -o 'RUSTSEC-[0-9]\{4\}-[0-9]\{4\}' "$WORK/rs.html" | sort -u | paste -sd' ' -)
  printf '%-32s HTTP %s  %s\n' "$c" "$code" "${ids:-no advisory id on page}"
  eval "rs_code_${c//-/_}=$code"
  eval "rs_ids_${c//-/_}='$ids'"
done
# shellcheck disable=SC2154
{
  check R01 "control atty page is HTTP 200 with advisories (validates the 404 reading)" test "$rs_code_atty" = 200 -a -n "$rs_ids_atty"
  check R02 "opentelemetry-jaeger carries RUSTSEC-2025-0123" bash -c "[[ '$rs_ids_opentelemetry_jaeger' == *RUSTSEC-2025-0123* ]]"
  check R03 "minitrace carries RUSTSEC-2024-0390" bash -c "[[ '$rs_ids_minitrace' == *RUSTSEC-2024-0390* ]]"
  for c in opentelemetry opentelemetry_sdk opentelemetry_otlp opentelemetry_http tracing_opentelemetry; do
    v="rs_code_$c"
    check "R04-$c" "$c has no RustSec package page (HTTP 404 = no advisory)" test "${!v}" = 404
  done
}
echo

echo "# TOTAL checks=$N pass=$PASS fail=$FAIL"
exit "$FAIL"
