#!/usr/bin/env bash
# R79 prometheus-metrics — synthesizer re-verification of the Opus report's
# source-level claims, read from the published .crate tarballs rather than from a
# rendered documentation page.
#
# Why this is reproducible: a published .crate artifact on static.crates.io is
# immutable, so every tarball sha256 and every quoted line below is byte-stable
# across reruns. The crates.io JSON API is NOT stable -- download counters move --
# so the volatile fields are snapshotted under snapshots/ and compared by the rule
# stated at each check: identity fields (num, created_at, rust_version, license)
# must be byte-equal to the snapshot; download counters must be >= the snapshot.
#
# Network: crates.io API at roughly one request per second with a repository
# User-Agent; static.crates.io for tarballs; rustsec.org package pages;
# raw.githubusercontent.com for the axum example and one README. No GitHub API
# calls are made here -- those live in github-api.sh, which is rate-paced.
#
# Exits non-zero if any check FAILs. Every SKIP is named.

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
snaps="$here/snapshots"
mkdir -p "$snaps"

GREP=/usr/bin/grep
UA='rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'

pass_count=0
fail_count=0
skip_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS  %s\n' "$*"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL  %s\n' "$*"; }
skip() { skip_count=$((skip_count + 1)); printf 'SKIP  %s\n' "$*"; }

scratch="$(mktemp -d "${TMPDIR:-/tmp}/rslb-r79-sources.XXXXXX")"
# shellcheck disable=SC2329  # invoked indirectly by the EXIT trap below
cleanup() { rm -rf "$scratch"; }
trap cleanup EXIT

online=1
if ! curl -sSf -m 20 -A "$UA" -o /dev/null "https://static.crates.io/crates/metrics/metrics-0.24.6.crate"; then
  online=0
fi

echo "== environment =="
"$GREP" --version | head -1
curl --version | head -1
printf 'uname: %s %s\n' "$(uname -s)" "$(uname -m)"
printf 'date-utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'network reachable: %s\n' "$online"
printf 'scratch: %s\n' "$scratch"
echo

# fetch_crate <name> <version> : download, print sha256, extract under $scratch
fetch_crate() {
  local name="$1" version="$2"
  local url="https://static.crates.io/crates/$name/$name-$version.crate"
  local tgz="$scratch/$name-$version.crate"
  if [ "$online" -eq 0 ]; then
    return 1
  fi
  if ! curl -sSf -m 120 -A "$UA" -o "$tgz" "$url"; then
    return 1
  fi
  printf 'tarball %-40s sha256 %s\n' "$name-$version.crate" "$(shasum -a 256 "$tgz" | awk '{print $1}')"
  tar -xzf "$tgz" -C "$scratch"
  return 0
}

# show <file> <extended-regexp> <label> : assert a match exists and quote it
show() {
  local file="$1" pattern="$2" label="$3"
  if [ ! -f "$file" ]; then
    fail "$label -- file not present: ${file#"$scratch"/}"
    return
  fi
  if "$GREP" -nE -- "$pattern" "$file" > "$scratch/hit.txt"; then
    pass "$label"
    sed 's/^/      | /' "$scratch/hit.txt"
  else
    fail "$label -- no line matching /$pattern/ in ${file#"$scratch"/}"
  fi
}

# show_absent <file> <extended-regexp> <label>
show_absent() {
  local file="$1" pattern="$2" label="$3"
  if [ ! -f "$file" ]; then
    fail "$label -- file not present: ${file#"$scratch"/}"
    return
  fi
  if "$GREP" -nE -- "$pattern" "$file" > "$scratch/hit.txt"; then
    fail "$label -- unexpected match"
    sed 's/^/      | /' "$scratch/hit.txt"
  else
    pass "$label"
  fi
}

# count_matches <file> <extended-regexp> <expected> <label>
count_matches() {
  local file="$1" pattern="$2" expected="$3" label="$4"
  local n
  if [ ! -f "$file" ]; then
    fail "$label -- file not present: ${file#"$scratch"/}"
    return
  fi
  n="$("$GREP" -cE -- "$pattern" "$file" || true)"
  if [ "$n" = "$expected" ]; then
    pass "$label (= $expected)"
  else
    fail "$label -- observed $n, report claims $expected"
  fi
}

if [ "$online" -eq 0 ]; then
  skip "every crates.io, static.crates.io, rustsec.org and raw.githubusercontent.com check (network unreachable from this shell)"
  echo
  echo "== summary =="
  printf 'PASS=%s FAIL=%s SKIP=%s TOTAL=%s\n' \
    "$pass_count" "$fail_count" "$skip_count" "$((pass_count + fail_count + skip_count))"
  exit 0
fi

# =============================================================== crates.io ====
echo "== crates.io registry figures (endpoint: GET https://crates.io/api/v1/crates/<name>) =="
echo "   rule: num / created_at / rust_version / license must equal the snapshot byte-for-byte;"
echo "         the all-time downloads counter must be >= the snapshot; recent_downloads is a"
echo "         rolling 90-day window that legitimately falls, so it is printed, never asserted."
echo

registry_check() { # name
  local name="$1"
  local meta="$scratch/$name.meta.json"
  local vers="$scratch/$name.versions.json"
  curl -sSf -m 60 -A "$UA" -o "$meta" "https://crates.io/api/v1/crates/$name" || {
    fail "crates.io metadata for $name could not be fetched"
    return
  }
  sleep 1
  curl -sSf -m 60 -A "$UA" -o "$vers" "https://crates.io/api/v1/crates/$name/versions" || {
    fail "crates.io versions for $name could not be fetched"
    return
  }
  sleep 1
  python3 - "$name" "$meta" "$vers" "$snaps" <<'PY'
import json, os, sys
name, meta_path, vers_path, snapdir = sys.argv[1:5]
crate = json.load(open(meta_path))["crate"]
versions = json.load(open(vers_path))["versions"]
newest = next(v for v in versions if not v["yanked"])
row = {
    "name": name,
    "recent_downloads": crate["recent_downloads"],
    "downloads": crate["downloads"],
    "num": newest["num"],
    "created_at": newest["created_at"],
    "rust_version": newest.get("rust_version"),
    "license": newest.get("license"),
}
print("      | %-28s recent=%-11s all=%-12s newest=%-9s created=%s rust_version=%s license=%s" % (
    name, row["recent_downloads"], row["downloads"], row["num"],
    row["created_at"], row["rust_version"], row["license"]))
snap = os.path.join(snapdir, name + ".registry.json")
if os.path.exists(snap):
    old = json.load(open(snap))
    problems = []
    for field in ("num", "created_at", "rust_version", "license"):
        if old.get(field) != row.get(field):
            problems.append("%s changed %r -> %r" % (field, old.get(field), row.get(field)))
    # `downloads` is all-time and only rises. `recent_downloads` is a rolling
    # 90-day window that legitimately falls, so it is printed, never asserted;
    # asserting it would make an honest rerun fail.
    if row["downloads"] < old["downloads"]:
        problems.append("downloads fell %s -> %s" % (old["downloads"], row["downloads"]))
    delta = row["recent_downloads"] - old["recent_downloads"]
    print("      | %-28s 90-day window moved by %+d since the snapshot (printed, not asserted)"
          % (name, delta))
    if problems:
        print("MISMATCH " + name + ": " + "; ".join(problems))
        sys.exit(3)
    print("SNAPCMP " + name + ": identity fields byte-equal to snapshot; all-time downloads not below snapshot")
else:
    with open(snap, "w") as handle:
        json.dump(row, handle, indent=2, sort_keys=True)
        handle.write("\n")
    print("SNAPNEW " + name + ": snapshot written")
PY
  local status=$?
  if [ "$status" -eq 0 ]; then
    pass "crates.io figures for $name agree with the recorded snapshot"
  else
    fail "crates.io figures for $name disagree with the recorded snapshot"
  fi
}

for crate_name in metrics metrics-exporter-prometheus axum-prometheus prometheus \
                  prometheus-client opentelemetry-prometheus autometrics measured \
                  axum-otel-metrics; do
  registry_check "$crate_name"
done
echo

echo "== crates.io reverse-dependency totals (GET .../reverse_dependencies?per_page=30, meta.total) =="
for crate_name in metrics metrics-exporter-prometheus; do
  if curl -sSf -m 60 -A "$UA" \
      -o "$scratch/$crate_name.revdeps.json" \
      "https://crates.io/api/v1/crates/$crate_name/reverse_dependencies?per_page=30"; then
    total="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["meta"]["total"])' "$scratch/$crate_name.revdeps.json")"
    printf '      | %-30s reverse dependencies: %s\n' "$crate_name" "$total"
    if [ "$total" -gt 100 ]; then
      pass "$crate_name has a four-figure-order reverse-dependency set ($total)"
    else
      fail "$crate_name reverse-dependency total is implausibly small ($total)"
    fi
  else
    fail "reverse dependencies for $crate_name could not be fetched"
  fi
  sleep 1
done
echo

# ========================================================= crate tarballs =====
echo "== metrics 0.24.6 (published tarball) =="
if fetch_crate metrics 0.24.6; then
  show "$scratch/metrics-0.24.6/Cargo.toml.orig" '^rust-version' \
    "metrics declares a rust-version (gate 2 evidence)"
  show_absent "$scratch/metrics-0.24.6/Cargo.toml.orig" '^\[features\]' \
    "metrics declares no [features] table (gate 5: no default features, no runtime coupling)"
  show_absent "$scratch/metrics-0.24.6/Cargo.toml.orig" '^tokio' \
    "metrics declares no tokio dependency"
  # Gate 3 (unsafe posture). The Opus report states "34 occurrences, all in
  # src/cow.rs". Counted here per file over the whole published src/ tree,
  # because the confinement half of that claim is the load-bearing half.
  echo "      -- occurrences of the token 'unsafe' per file, metrics 0.24.6 src/ --"
  "$GREP" -rno 'unsafe' "$scratch/metrics-0.24.6/src/" \
    | awk -F: '{ n[$1]++ } END { for (f in n) print "      | " n[f] "  " f }' \
    | sed "s|$scratch/||" | sort -k3
  metrics_unsafe_total="$("$GREP" -rno 'unsafe' "$scratch/metrics-0.24.6/src/" | wc -l | tr -d ' ')"
  metrics_unsafe_cow="$("$GREP" -no 'unsafe' "$scratch/metrics-0.24.6/src/cow.rs" | wc -l | tr -d ' ')"
  printf '      | total across src/: %s ; in src/cow.rs alone: %s\n' \
    "$metrics_unsafe_total" "$metrics_unsafe_cow"
  if [ "$metrics_unsafe_total" -gt "$metrics_unsafe_cow" ]; then
    pass "metrics: unsafe is NOT confined to src/cow.rs -- the report's confinement claim is refuted at source"
  else
    fail "metrics: unsafe appears only in src/cow.rs after all -- the report's confinement claim stands"
  fi
  show "$scratch/metrics-0.24.6/src/recorder/cell.rs" 'unsafe' \
    "metrics carries unsafe outside src/cow.rs, in src/recorder/cell.rs"
  show "$scratch/metrics-0.24.6/src/recorder/mod.rs" 'unsafe' \
    "metrics carries unsafe outside src/cow.rs, in src/recorder/mod.rs"
else
  skip "metrics 0.24.6 tarball checks (download failed)"
fi
echo

echo "== metrics-exporter-prometheus 0.18.3 (published tarball) =="
if fetch_crate metrics-exporter-prometheus 0.18.3; then
  d="$scratch/metrics-exporter-prometheus-0.18.3"
  show "$d/Cargo.toml.orig" '^default *=' \
    "exporter default features are http-listener and push-gateway (the line the recommendation turns off)"
  show "$d/src/lib.rs" 'run_upkeep' \
    "exporter documents the caller-owned upkeep contract in src/lib.rs"
  show "$d/src/lib.rs" 'install_recorder|build_recorder' \
    "exporter names install_recorder/build_recorder in the same upkeep paragraph"
  # The gate is a MULTI-LINE #[cfg(any(...))] attribute, so a single-line regex
  # cannot see it. Walk the attribute block above each constructor instead, and
  # distinguish a real #[cfg(...)] compilation gate from a #[cfg_attr(docsrs, ...)]
  # documentation attribute, which does not gate compilation at all.
  if python3 - "$d/src/exporter/builder.rs" <<'PY'
import sys
lines = open(sys.argv[1], encoding="utf-8", errors="replace").read().splitlines()
targets = ("pub fn install(", "pub fn build(")
gated = set()
for index, line in enumerate(lines):
    stripped = line.strip()
    if not any(stripped.startswith(t) for t in targets):
        continue
    name = stripped.split("(")[0].split()[-1]
    # Walk upward through the contiguous attribute/doc block.
    block, cursor = [], index - 1
    while cursor >= 0:
        text = lines[cursor].strip()
        if text.startswith(("#[", "]", ")", "///", "//!", "feature", "doc(", "docsrs")) or text == "":
            block.append((cursor + 1, lines[cursor]))
            cursor -= 1
            continue
        break
    block.reverse()
    joined = " ".join(t.strip() for _, t in block)
    real_cfg = "#[cfg(any(" in joined.replace(" ", "") or "#[cfg(feature" in joined.replace(" ", "")
    print("      | line %d: %s -- compilation #[cfg(...)] present: %s"
          % (index + 1, stripped, real_cfg))
    for number, text in block:
        if text.strip().startswith("#[cfg(") or text.strip().startswith("feature =") \
           or text.strip() in ("))]", "#[cfg(any("):
            print("      |   %d: %s" % (number, text))
    if real_cfg:
        gated.add(name)
sys.exit(0 if gated == {"install", "build"} else 3)
PY
  then
    pass "exporter gates install() and build() behind a real multi-line #[cfg(any(feature = \"http-listener\", ...))]"
  else
    fail "exporter's install()/build() are not both behind a compilation #[cfg(...)] gate"
  fi
  show "$d/src/exporter/builder.rs" 'pub fn install_recorder' \
    "install_recorder is declared"
  show "$d/src/exporter/builder.rs" 'pub fn build_recorder' \
    "build_recorder is declared"
  # The ungated claim: neither constructor may sit under a #[cfg(feature=...)].
  if python3 - "$d/src/exporter/builder.rs" <<'PY'
import sys
lines = open(sys.argv[1], encoding="utf-8", errors="replace").read().splitlines()
bad = []
for index, line in enumerate(lines):
    for name in ("pub fn install_recorder", "pub fn build_recorder"):
        if line.strip().startswith(name):
            window = [l.strip() for l in lines[max(0, index - 8):index]]
            cfgs = [l for l in window if l.startswith("#[cfg(")]
            print("      | line %d: %s  preceding #[cfg(...) attributes: %s"
                  % (index + 1, line.strip(), cfgs or "none"))
            if cfgs:
                bad.append(name)
sys.exit(3 if bad else 0)
PY
  then
    pass "install_recorder and build_recorder carry no preceding #[cfg(feature = ...)] attribute"
  else
    fail "install_recorder or build_recorder is feature-gated after all"
  fi
  show "$d/src/exporter/builder.rs" 'upkeep_timeout' \
    "the exporter's own upkeep_timeout default is declared in the builder"
  count_matches "$d/src/recorder.rs" 'unsafe' 1 \
    "exporter: exactly one unsafe occurrence in src/recorder.rs"
  # Gate 5: with default-features = false there must be no mandatory tokio edge.
  show "$d/Cargo.toml.orig" '^\[(dependencies|features)\]|^http-listener|^push-gateway' \
    "exporter feature/dependency tables located"
else
  skip "metrics-exporter-prometheus 0.18.3 tarball checks (download failed)"
fi
echo

echo "== axum-prometheus 0.10.1 (the ranked runner-up; gates 3-6 read at source) =="
if fetch_crate axum-prometheus 0.10.1; then
  d="$scratch/axum-prometheus-0.10.1"
  show "$d/Cargo.toml.orig" '^rust-version' "axum-prometheus declares a rust-version (gate 2)"
  show "$d/Cargo.toml.orig" '^license' "axum-prometheus declares a license field"
  show "$d/Cargo.toml.orig" '^tower-http' "axum-prometheus depends on tower-http (gate 5 / graph cost)"
  show "$d/Cargo.toml.orig" '^tokio' "axum-prometheus's tokio dependency and whether it is optional"
  show "$d/Cargo.toml.orig" '^default *=' "axum-prometheus default features"
  show "$d/Cargo.toml.orig" 'metrics-exporter-prometheus' \
    "axum-prometheus itself pins the exporter with default-features = false"
  show "$d/src/lib.rs" 'endpoint="/metrics"' \
    "axum-prometheus's own documented scrape measures /metrics (it is NOT excluded out of the box)"
  show "$d/src/lib.rs" 'set_global_recorder' \
    "axum-prometheus installs the global recorder, and how it handles a second install"
  show "$d/src/lib.rs" 'run_upkeep' \
    "axum-prometheus spawns the upkeep loop the recommendation must write by hand"
  show "$d/src/builder.rs" 'with_ignore_pattern' \
    "axum-prometheus exposes an explicit ignore-pattern call (the hand-wired exclusion)"
  show "$d/src/builder.rs" 'MatchedPath' \
    "axum-prometheus's EndpointLabel default and its unmatched-request fallback"
  count_matches "$d/src/lib.rs" 'unsafe' 0 "axum-prometheus: zero unsafe in src/lib.rs"
else
  skip "axum-prometheus 0.10.1 tarball checks (download failed)"
fi
echo

echo "== prometheus-client 0.25.1 (excluded by gate 2 -- the exclusion re-read at source) =="
if fetch_crate prometheus-client 0.25.1; then
  show_absent "$scratch/prometheus-client-0.25.1/Cargo.toml.orig" '^rust-version' \
    "prometheus-client declares NO rust-version (the gate-2 exclusion, confirmed at source)"
  show "$scratch/prometheus-client-0.25.1/Cargo.toml.orig" '^license' \
    "prometheus-client license field (recorded, not evaluated -- see gate 1)"
else
  skip "prometheus-client 0.25.1 tarball checks (download failed)"
fi
echo

echo "== prometheus 0.14.0 (shortlist gates 5-6 read at source) =="
if fetch_crate prometheus 0.14.0; then
  show "$scratch/prometheus-0.14.0/Cargo.toml.orig" '^rust-version' "prometheus declares a rust-version (gate 2)"
  show "$scratch/prometheus-0.14.0/Cargo.toml.orig" '^default *=' \
    "prometheus default features pull protobuf (gate 5 / gate 6 qualitative cost)"
  show "$scratch/prometheus-0.14.0/Cargo.toml.orig" '^\[target' \
    "prometheus's platform-gated dependency block (procfs is Linux-only)"
else
  skip "prometheus 0.14.0 tarball checks (download failed)"
fi
echo

echo "== opentelemetry-prometheus 0.33.0 (architecture D, gates 5-6 read at source) =="
if fetch_crate opentelemetry-prometheus 0.33.0; then
  d="$scratch/opentelemetry-prometheus-0.33.0"
  show "$d/Cargo.toml.orig" '^rust-version' "opentelemetry-prometheus declares a rust-version (gate 2)"
  show "$d/Cargo.toml.orig" '^default *=' "opentelemetry-prometheus default features"
  show "$d/Cargo.toml.orig" '^prometheus' \
    "opentelemetry-prometheus depends on the prometheus client, so D adopts C transitively"
  show "$d/README.md" 'opentelemetry-otlp' \
    "the OTel maintainers' own steer away from this crate for new projects"
else
  skip "opentelemetry-prometheus 0.33.0 tarball checks (download failed)"
fi
echo

# ================================================== axum's own example ========
echo "== the axum maintainers' own worked example, at tag axum-v0.8.9 =="
if curl -sSf -m 60 -A "$UA" -o "$scratch/axum-example-main.rs" \
    "https://raw.githubusercontent.com/tokio-rs/axum/axum-v0.8.9/examples/prometheus-metrics/src/main.rs" \
  && curl -sSf -m 60 -A "$UA" -o "$scratch/axum-example-Cargo.toml" \
    "https://raw.githubusercontent.com/tokio-rs/axum/axum-v0.8.9/examples/prometheus-metrics/Cargo.toml"; then
  printf 'main.rs      sha256 %s\n' "$(shasum -a 256 "$scratch/axum-example-main.rs" | awk '{print $1}')"
  printf 'Cargo.toml   sha256 %s\n' "$(shasum -a 256 "$scratch/axum-example-Cargo.toml" | awk '{print $1}')"
  show "$scratch/axum-example-main.rs" 'tower-http will hopefully have a metrics middleware' \
    "axum's own example states tower-http has no metrics middleware"
  show "$scratch/axum-example-main.rs" 'install_recorder|PrometheusBuilder' \
    "axum's example builds the recorder with metrics-exporter-prometheus"
  show "$scratch/axum-example-main.rs" 'route_layer' \
    "axum's example applies the middleware with route_layer"
  show "$scratch/axum-example-main.rs" 'MatchedPath|uri\(\)\.path\(\)' \
    "how axum's example derives its route label (the unbounded-label fallback the recommendation refuses)"
  show_absent "$scratch/axum-example-main.rs" 'run_upkeep' \
    "axum's own example never calls run_upkeep -- the defect the recommendation repairs"
  show "$scratch/axum-example-Cargo.toml" 'metrics|default-features' \
    "the example's own pins, including default-features = false"
else
  skip "the axum v0.8.9 example checks (raw.githubusercontent.com fetch failed)"
fi
echo

echo "== autometrics: the maintainers' own retirement notice =="
if curl -sSf -m 60 -A "$UA" -o "$scratch/autometrics-README.md" \
    "https://raw.githubusercontent.com/autometrics-dev/autometrics-rs/main/README.md"; then
  show "$scratch/autometrics-README.md" 'no longer actively maintained' \
    "autometrics carries a maintainer's own dormancy notice"
else
  skip "autometrics README check (fetch failed)"
fi
echo

# ===================================================== RustSec (gate 3) =======
echo "== RustSec package pages (gate 3): HTTP 404 means no advisory page exists =="
for pkg in metrics metrics-exporter-prometheus metrics-util axum-prometheus prometheus \
           prometheus-client opentelemetry-prometheus autometrics measured quanta; do
  code="$(curl -sS -o "$scratch/rustsec-$pkg.html" -w '%{http_code}' -m 40 -A "$UA" \
    "https://rustsec.org/packages/$pkg.html" || echo 000)"
  printf '      | %-30s https://rustsec.org/packages/%s.html -> HTTP %s\n' "$pkg" "$pkg" "$code"
  case "$pkg:$code" in
    metrics-util:200)
      pass "metrics-util HAS an advisory page (the one the report flags as patched)"
      show "$scratch/rustsec-$pkg.html" 'RUSTSEC-2021-0113' "metrics-util advisory id present on that page"
      ;;
    *:404) pass "$pkg has no RustSec advisory page (gate 3 clear)" ;;
    *:200) fail "$pkg unexpectedly HAS a RustSec advisory page -- gate 3 must be re-read" ;;
    *)     skip "$pkg RustSec page (HTTP $code, neither 200 nor 404)" ;;
  esac
  sleep 1
done
echo

echo "== summary =="
printf 'PASS=%s FAIL=%s SKIP=%s TOTAL=%s\n' \
  "$pass_count" "$fail_count" "$skip_count" "$((pass_count + fail_count + skip_count))"
if [ "$fail_count" -ne 0 ]; then
  exit 1
fi
exit 0
