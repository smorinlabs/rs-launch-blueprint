#!/usr/bin/env bash
# R02 crate-boundary-enforcement -- ecosystem figures and engine-disagreement checks.
#
# Settles, against the recorded endpoints, the four places where the engines
# disagree about the Rust field, plus the registry values this decision assumes.
#
#   1. Does a maintained intra-crate layer-contract checker exist?  The Opus raw
#      says no such tool exists "in maintained form"; the Doxa/gemini leg names
#      `boundary` / `boundary-rust` 0.27.0.  This script resolves it.
#   2. cargo-deny's newest non-yanked version: Opus 0.20.2, gemini 0.19.0,
#      perplexity 0.18.3.
#   3. cargo-deny's RustSec page: Opus reports HTTP 404, gemini reports one open
#      advisory.
#   4. The `cargo_metadata` pin the Doxa/openai leg writes as `=0.23.1`.
#
# Every figure carries its endpoint and its retrieval date.  Payloads are
# snapshotted into snapshots/ and the assertions read the snapshot, so a rerun
# diffs against a fixed artifact.  Download counters are VOLATILE: they are
# printed and labelled, never asserted.  gh is used authenticated; no token or
# environment is printed.  This script reads no .git directory, so it runs
# unchanged from a clean `git archive HEAD` extraction; the one check that reads
# the repository reads a committed file (docs/port/PARAMETERS.md) and SKIPs by
# name when that file is absent.
#
# Exit 0 only when FAILURES is 0.

set -euo pipefail
set -o pipefail

GREP=/usr/bin/grep
UA='rs-launch-blueprint-p02-research'
RETRIEVED='2026-09-17'
HERE=$(cd "$(dirname "$0")" && pwd)
SNAP="$HERE/snapshots"
REPO_ROOT=$(cd "$HERE/../../../../../.." && pwd)
mkdir -p "$SNAP"

CHECKS=0
FAILURES=0
SKIPPED=0

note() { printf '\n=== %s ===\n' "$1"; }

ok() {
  local name="$1" what="$2" file="$3"
  shift 3
  CHECKS=$((CHECKS + 1))
  local pat missing=0
  for pat in "$@"; do
    if ! "$GREP" -qF -- "$pat" "$file"; then
      printf 'FAIL %s: %s -- missing substring: %s\n' "$name" "$what" "$pat"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    printf 'PASS %s: %s\n' "$name" "$what"
  else
    FAILURES=$((FAILURES + 1))
  fi
}

eq() {
  local name="$1" what="$2" got="$3" want="$4"
  CHECKS=$((CHECKS + 1))
  if [ "$got" = "$want" ]; then
    printf 'PASS %s: %s == %s\n' "$name" "$what" "$got"
  else
    printf 'FAIL %s: %s -- wanted %s, got %s\n' "$name" "$what" "$want" "$got"
    FAILURES=$((FAILURES + 1))
  fi
}

skip() {
  SKIPPED=$((SKIPPED + 1))
  printf 'SKIP %s: %s\n' "$1" "$2"
}

# crate NAME -> snapshots/crates-io-NAME.json
crate_snapshot() {
  local name="$1" out="$SNAP/crates-io-$1.json"
  curl -sS -A "$UA" "https://crates.io/api/v1/crates/$name" > "$out"
  printf '%s\n' "$out"
}
versions_snapshot() {
  local name="$1" out="$SNAP/crates-io-$1-versions.json"
  curl -sS -A "$UA" "https://crates.io/api/v1/crates/$name/versions" > "$out"
  printf '%s\n' "$out"
}

# field FILE JQ-ish python expression
jget() { python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));print(eval(sys.argv[2],{"d":d}))' "$1" "$2"; }

newest_unyanked() {
  python3 - "$1" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
for v in d["versions"]:
    if not v["yanked"]:
        print("%s %s %s" % (v["num"], v["created_at"], v.get("license")))
        break
PY
}

note "C0 environment"
printf 'retrieval date for every figure below: %s\n' "$RETRIEVED"
curl --version | head -1
python3 --version
printf 'gh authenticated: '
if gh auth status >/dev/null 2>&1; then printf 'yes\n'; else printf 'no\n'; fi

############################################################################
# 1. Does an intra-crate layer-contract checker exist?
############################################################################
note "1 boundary / boundary-rust -- GET https://crates.io/api/v1/crates/<name> ($RETRIEVED)"
B_CLI=$(crate_snapshot boundary)
B_LIB=$(crate_snapshot boundary-rust)
B_VER=$(versions_snapshot boundary-rust)
eq EF1a "crates.io serves a crate named boundary (no errors key)" \
  "$(jget "$B_CLI" '"errors" in d')" "False"
eq EF1b "its newest version" "$(jget "$B_CLI" 'd["crate"]["newest_version"]')" "0.27.0"
eq EF1c "its repository" "$(jget "$B_CLI" 'd["crate"]["repository"]')" \
  "https://github.com/rebelopsio/boundary"
eq EF1d "crates.io serves a crate named boundary-rust (the Rust analyzer member)" \
  "$(jget "$B_LIB" '"errors" in d')" "False"
newest_unyanked "$B_VER" > "$SNAP/boundary-rust-newest.txt"
printf 'boundary-rust newest non-yanked (num created_at license): %s\n' "$(cat "$SNAP/boundary-rust-newest.txt")"
ok EF1e "boundary-rust's newest non-yanked release and its licence" \
  "$SNAP/boundary-rust-newest.txt" "0.27.0" "2026-04-02" "MIT OR Apache-2.0"
eq EF1f "published release count -- this is an actively released crate, not a stub" \
  "$(jget "$B_VER" 'len(d["versions"])')" "30"
printf 'VOLATILE (not asserted), %s: boundary recent_downloads=%s downloads=%s ; boundary-rust recent_downloads=%s downloads=%s\n' \
  "$RETRIEVED" \
  "$(jget "$B_CLI" 'd["crate"]["recent_downloads"]')" \
  "$(jget "$B_CLI" 'd["crate"]["downloads"]')" \
  "$(jget "$B_LIB" 'd["crate"]["recent_downloads"]')" \
  "$(jget "$B_LIB" 'd["crate"]["downloads"]')"

note "1g rebelopsio/boundary -- GET https://api.github.com/repos/<o>/<r> ($RETRIEVED)"
gh api repos/rebelopsio/boundary > "$SNAP/github-rebelopsio-boundary.json"
eq EF1g "archived" "$(jget "$SNAP/github-rebelopsio-boundary.json" 'd["archived"]')" "False"
eq EF1h "stargazers_count -- the adoption figure that decides watch-not-adopt" \
  "$(jget "$SNAP/github-rebelopsio-boundary.json" 'd["stargazers_count"]')" "5"
eq EF1i "pushed_at -- last repository activity" \
  "$(jget "$SNAP/github-rebelopsio-boundary.json" 'd["pushed_at"]')" "2026-04-02T20:17:15Z"
gh api "search/issues?q=repo:rebelopsio/boundary+is:issue+is:open" \
  > "$SNAP/github-rebelopsio-boundary-open-issues.json"
eq EF1j "open issues by search total_count (never open_issues_count)" \
  "$(jget "$SNAP/github-rebelopsio-boundary-open-issues.json" 'd["total_count"]')" "1"

note "1k what boundary can actually express"
curl -sS "https://raw.githubusercontent.com/rebelopsio/boundary/main/README.md" \
  > "$SNAP/boundary-README.md"
ok EF1k "it declares Rust support, a layer-glob contract file and a failing exit mode" \
  "$SNAP/boundary-README.md" \
  "[x] Rust language support" \
  ".boundary.toml" \
  "[layers]" \
  'fail_on = "error"' \
  "boundary check /path/to/repo --fail-on error"
ok EF1l "and it records monorepo / multi-service support as an UNCHECKED roadmap item, which is what a Cargo workspace is" \
  "$SNAP/boundary-README.md" "[ ] Monorepo / multi-service support"

note "1m the ArchUnit ports the Opus raw excluded"
A_RS=$(crate_snapshot archunit_rs)
eq EF1m "archunit_rs is not published to crates.io" "$(jget "$A_RS" '"errors" in d')" "True"

############################################################################
# 2-3. cargo-deny
############################################################################
note "2 cargo-deny -- GET https://crates.io/api/v1/crates/cargo-deny[/versions] ($RETRIEVED)"
CD=$(crate_snapshot cargo-deny)
CDV=$(versions_snapshot cargo-deny)
newest_unyanked "$CDV" > "$SNAP/cargo-deny-newest.txt"
printf 'cargo-deny newest non-yanked (num created_at license): %s\n' "$(cat "$SNAP/cargo-deny-newest.txt")"
ok EF2a "cargo-deny's newest non-yanked release is 0.20.2 -- the Opus figure, not gemini's 0.19.0 or perplexity's 0.18.3" \
  "$SNAP/cargo-deny-newest.txt" "0.20.2" "2026-07-09" "MIT OR Apache-2.0"
eq EF2b "repository" "$(jget "$CD" 'd["crate"]["repository"]')" \
  "https://github.com/EmbarkStudios/cargo-deny"
gh api repos/EmbarkStudios/cargo-deny > "$SNAP/github-embarkstudios-cargo-deny.json"
eq EF2c "archived" "$(jget "$SNAP/github-embarkstudios-cargo-deny.json" 'd["archived"]')" "False"
printf 'VOLATILE (not asserted), %s: cargo-deny stars=%s pushed_at=%s recent_downloads=%s downloads=%s\n' \
  "$RETRIEVED" \
  "$(jget "$SNAP/github-embarkstudios-cargo-deny.json" 'd["stargazers_count"]')" \
  "$(jget "$SNAP/github-embarkstudios-cargo-deny.json" 'd["pushed_at"]')" \
  "$(jget "$CD" 'd["crate"]["recent_downloads"]')" \
  "$(jget "$CD" 'd["crate"]["downloads"]')"
CD_STARS=$(jget "$SNAP/github-embarkstudios-cargo-deny.json" 'd["stargazers_count"]')
CHECKS=$((CHECKS + 1))
if [ "$CD_STARS" -gt 1000 ]; then
  printf 'PASS EF2d: cargo-deny has %s stars, an order of magnitude above the 190 the gemini leg reported for what it labelled the "Actions repo"\n' "$CD_STARS"
else
  printf 'FAIL EF2d: expected cargo-deny stars > 1000, got %s\n' "$CD_STARS"
  FAILURES=$((FAILURES + 1))
fi

note "3 RustSec pages -- https://rustsec.org/packages/<name>.html ($RETRIEVED)"
for p in cargo-deny boundary boundary-rust cargo_metadata cargo-modules; do
  code=$(curl -sS -o "$SNAP/rustsec-$p.html" -w '%{http_code}' \
    "https://rustsec.org/packages/$p.html")
  printf '  %s -> HTTP %s\n' "$p" "$code"
  eq "EF3-$p" "RustSec HTTP status for $p" "$code" "404"
done
printf 'control: a package that DOES have a RustSec page must not also return 404\n'
ATTY=$(curl -sS -o "$SNAP/rustsec-atty.html" -w '%{http_code}' \
  "https://rustsec.org/packages/atty.html")
eq EF3-control "RustSec HTTP status for atty (positive control -- proves the 404s above are not a blanket failure)" \
  "$ATTY" "200"

############################################################################
# 4. The other engines' named crates
############################################################################
note "4 crates named by the Doxa legs -- GET https://crates.io/api/v1/crates/<name> ($RETRIEVED)"
for pair in "cargo_metadata:0.23.1" "cargo-depgraph-check:0.1.0" "dep_graph_rs:0.2.0" "hexser:0.6.0" "guppy:0.18.0"; do
  name=${pair%%:*}
  want=${pair##*:}
  f=$(crate_snapshot "$name")
  got=$(jget "$f" 'd["crate"]["newest_version"]')
  eq "EF4-$name" "newest version of $name" "$got" "$want"
  printf '  VOLATILE (not asserted), %s: %s recent_downloads=%s downloads=%s\n' \
    "$RETRIEVED" "$name" \
    "$(jget "$f" 'd["crate"]["recent_downloads"]')" \
    "$(jget "$f" 'd["crate"]["downloads"]')"
done

############################################################################
# 5. The registry values this decision writes into ## Parameters
############################################################################
note "5 registry values assumed by this decision"
REG="$REPO_ROOT/docs/port/PARAMETERS.md"
if [ ! -f "$REG" ]; then
  skip EF5 "docs/port/PARAMETERS.md is absent from this extraction"
else
  awk -F'|' 'NF>=6 && $3 ~ /fixed/ {gsub(/^ +| +$/,"",$2); gsub(/^ +| +$/,"",$5); print "- assumes "$2" = "$5}' \
    "$REG" > "$SNAP/registry-fixed.txt"
  cat "$SNAP/registry-fixed.txt"
  ok EF5 "the four fixed parameters, exactly as the DECISION.md ## Parameters list must write them" \
    "$SNAP/registry-fixed.txt" \
    "- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI" \
    "- assumes rust-edition = 2024" \
    "- assumes target-os-matrix = ubuntu-latest, macos-latest" \
    "- assumes license = MIT OR Apache-2.0"
  CHECKS=$((CHECKS + 1))
  n=$(wc -l < "$SNAP/registry-fixed.txt" | tr -d ' ')
  if [ "$n" = "4" ]; then
    printf 'PASS EF5b: the registry carries exactly 4 fixed parameters, so the assumes list is complete at 4 lines\n'
  else
    printf 'FAIL EF5b: expected 4 fixed registry parameters, got %s\n' "$n"
    FAILURES=$((FAILURES + 1))
  fi
  awk -F'|' 'NF>=6 {gsub(/^ +| +$/,"",$2); if ($2=="web-extra-surface") {gsub(/^ +| +$/,"",$5); print $5}}' \
    "$REG" > "$SNAP/registry-web-extra-surface.txt"
  ok EF5c "the R69 clause this decision CONFLICTs with is present in the live registry, quoted verbatim" \
    "$SNAP/registry-web-extra-surface.txt" \
    'declared on whichever crate hosts the binary targets (R02 decides which)' \
    'web = ["dep:axum", "dep:tokio"]' \
    '(1) the library module src/web/ containing AppState, build_router' \
    'path-based skip-gating keys on src/web/**'
  awk -F'|' 'NF>=6 {gsub(/^ +| +$/,"",$2); if ($2=="build-tool-output-shape") {gsub(/^ +| +$/,"",$5); print $5}}' \
    "$REG" > "$SNAP/registry-build-tool-output-shape.txt"
  ok EF5d "R49's clause that excludes an xtask boundary checker, quoted verbatim" \
    "$SNAP/registry-build-tool-output-shape.txt" \
    "no build.rs and no build-orchestration crate" \
    'name rslbp' \
    'CARGO_BIN_EXE_rslbp'
fi

############################################################################
# 6. OV number availability
############################################################################
note "6 next free OVERRIDE number"
if [ ! -d "$REPO_ROOT/docs/port" ]; then
  skip EF6 "docs/port is absent from this extraction"
else
  {
    "$GREP" -rlF -- 'OV-03' "$REPO_ROOT/docs/port" || true
    for f in "$REPO_ROOT"/research/topics/*/DECISION.md "$REPO_ROOT"/research/runs/*/*/review/DECISION.md; do
      [ -f "$f" ] || continue
      case "$f" in *"/R02/"*) continue ;; esac
      "$GREP" -lF -- 'OV-03' "$f" || true
    done
  } > "$SNAP/ov03-collisions.txt"
  n=$(wc -l < "$SNAP/ov03-collisions.txt" | tr -d ' ')
  eq EF6a "files claiming OV-03 outside this item (by $GREP over docs/port, every published topic DECISION.md and every run review DECISION.md)" \
    "$n" "0"
  {
    "$GREP" -rlF -- 'OV-02' "$REPO_ROOT/docs/port" || true
    for f in "$REPO_ROOT"/research/topics/*/DECISION.md "$REPO_ROOT"/research/runs/*/*/review/DECISION.md; do
      [ -f "$f" ] || continue
      case "$f" in *"/R02/"*) continue ;; esac
      "$GREP" -lF -- 'OV-02' "$f" || true
    done
  } > "$SNAP/ov02-holders.txt"
  cat "$SNAP/ov02-holders.txt"
  n2=$(wc -l < "$SNAP/ov02-holders.txt" | tr -d ' ')
  CHECKS=$((CHECKS + 1))
  if [ "$n2" -ge 1 ]; then
    printf 'PASS EF6b: OV-02 is taken (%s file(s)), so the zero above is not a vacuous search\n' "$n2"
  else
    printf 'FAIL EF6b: OV-02 should be taken by R61; the search found nothing, so the OV-03 zero is unreliable\n'
    FAILURES=$((FAILURES + 1))
  fi
  ok EF6c "and R61's run decision is where OV-02 lives" "$SNAP/ov02-holders.txt" \
    "research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/DECISION.md"
fi

note "SUMMARY"
printf 'CHECKS RUN: %s FAILURES: %s SKIPPED: %s\n' "$CHECKS" "$FAILURES" "$SKIPPED"
[ "$FAILURES" -eq 0 ]
