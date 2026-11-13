#!/usr/bin/env bash
# R76 revision 3 empirical check: the evidence that settles each point on which
# the Muse research report (raw/muse.md) disagrees with this decision, plus the
# engine-set record that makes Muse a required engine for this item.
#
# Revision 2 was synthesized from the Opus report alone and never adjudicated
# raw/muse.md. The judgment audit of revision 2 (JA-1) listed six unsettled
# disagreements; this script gathers the primary-source evidence for each, so
# that no adjudication in ## Engines rests on either report's word.
#
# Sections:
#   A  the engine set and the Muse artifact (local files only)
#   B  the version floor: "0.7" (Muse) against "0.7.1" (this decision)
#   C  actix-cors 0.7.2, gate by gate: is it gate-excluded or fit-excluded?
#   D  rocket_cors: the concrete signal behind Muse's "at-risk"
#   E  reverse-dependency counts, which the two reports quote differently
#   F  tower-http issue responsiveness as of this revision, over both windows
#   G  repository figures quoted by the decision that no other log carries
#
# Line prefixes:
#   LOCAL   — bytes read from a file in this repository, with its sha256.
#   FIGURE  — a point-in-time counter or timestamp from an API, with endpoint.
#   PINNED  — content read from an immutable published .crate artifact.
#   HEAD    — content read from a moving default branch; the bytes are quoted.
#   SNAP    — content read from a snapshot committed under snapshots/.
#   LOCK    — a committed lockfile used for a resolve-only probe.
#   ASSERT  — a content assertion. `ASSERT FAIL` sets exit status 1.
#   SKIP    — a check that could not run, with the reason named.
#
# Needs: network; `gh` already authenticated (keyring); cargo able to download
# the crates the committed lockfile names. No token byte and no personal address
# is printed or sent. Section A needs the repository's research/ and docs/
# trees; it needs no `.git`. GitHub API calls are spaced at least 21 s apart.
#
# Set R76_RECORD=1 to regenerate the two committed snapshots this script reads
# (snapshots/actix-cors-probe.Cargo.lock and
# snapshots/tower-http-issue-triage-2026-09-27.json) from the live sources.
# That is how they were first written; a normal run only reads them.

set -euo pipefail
unset CARGO_TARGET_DIR CARGO_BUILD_TARGET_DIR

GREP=/usr/bin/grep
HERE="$(cd "$(dirname "$0")" && pwd)"
REVIEW="$(cd "$HERE/.." && pwd)"
RUN="$(cd "$REVIEW/.." && pwd)"
# research/runs/R76/<run>/ -> repository root is four levels up from the run.
ROOT="$(cd "$RUN/../../../.." && pwd)"
UA="rs-launch-blueprint-r76-research (https://github.com/smorinlabs/rs-launch-blueprint)"
RECORD="${R76_RECORD:-0}"

echo "=== R76 revision 3: the Muse report's disagreements, settled at source ==="
echo "date(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "grep:  $("$GREP" --version | head -1)"
echo "curl:  $(curl --version | "$GREP" -o '^curl [0-9.]*')"
echo "gh:    $(gh --version | "$GREP" '^gh version')"
echo "jq:    $(jq --version)"
echo "cargo: $(cargo --version)"
echo "mode:  $([ "$RECORD" = "1" ] && echo 'RECORD (snapshots regenerated from live sources)' || echo 'normal (snapshots read, not written)')"
echo

WORK=$(mktemp -d "${TMPDIR:-/tmp}/r76-muse.XXXXXX")
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

pass=0; failn=0; skipn=0
assert() {
  if [ "$1" = "1" ]; then echo "ASSERT ok   $2"; pass=$((pass + 1))
  else echo "ASSERT FAIL $2"; failn=$((failn + 1)); fi
}
skip() { echo "SKIP        $1"; skipn=$((skipn + 1)); }
eq() { if [ "$1" = "$2" ]; then echo 1; else echo 0; fi; }
gt0() { if [ "$1" -gt 0 ] 2>/dev/null; then echo 1; else echo 0; fi; }
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
# Spacing for GitHub API calls: the first call goes immediately, every later
# call waits 21 s.
GH_CALLS=0
gh_get() { # gh_get <endpoint> <outfile>
  if [ "$GH_CALLS" -gt 0 ]; then sleep 21; fi
  GH_CALLS=$((GH_CALLS + 1))
  gh api "$1" > "$2"
}

# ---------------------------------------------------------------------------
echo "--- A. the engine set this item requires, and the Muse artifact ---"
PROMPT="$ROOT/research/topics/76-cors-middleware/prompts/cors-middleware.prompt.md"
FROZEN="$RUN/inputs/prompt.md"
POLICY="$ROOT/research/EXECUTION.json"
RUNBOOK="$ROOT/research/RUNBOOK.md"
MUSE="$RUN/raw/muse.md"
MUSEOP="$RUN/operations/muse.json"
MANIFEST="$RUN/manifest.json"
for f in "$PROMPT" "$FROZEN" "$POLICY" "$RUNBOOK" "$MUSE" "$MUSEOP" "$MANIFEST"; do
  if [ -f "$f" ]; then echo "LOCAL sha256 $(sha "$f")  ${f#"$ROOT"/}"; else echo "LOCAL absent ${f#"$ROOT"/}"; fi
done
if [ ! -f "$PROMPT" ] || [ ! -f "$POLICY" ] || [ ! -f "$MUSE" ]; then
  skip "A: the prompt, the policy or raw/muse.md is not reachable from this extraction"
else
  assert "$(eq "$(sha "$PROMPT")" "$(sha "$FROZEN")")" \
    "the run's frozen inputs/prompt.md is byte-identical to the live topic prompt, so the engine line read below is the one the run was prepared under"
  assert "$(eq "$("$GREP" -c '^- engines: muse, opus$' "$PROMPT" || true)" "1")" \
    "the live prompt's Couplings block reads '- engines: muse, opus'"
  # shellcheck disable=SC2016  # backticks are literal Markdown in the quoted prompt text
  assert "$(eq "$("$GREP" -cF 'This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot; its mirrored `- engines:` line is authoritative.' "$PROMPT" || true)" "1")" \
    "and it states that the mirrored engines line is authoritative under the engine_overrides pilot"
  R76POL=$(jq -c '.engine_overrides.R76' "$POLICY")
  echo "LOCAL research/EXECUTION.json engine_overrides.R76 = ${R76POL}"
  assert "$(eq "$R76POL" '["muse","opus"]')" \
    "the policy's engine_overrides entry for R76 is exactly muse and opus: Codex is not a required engine for this item"
  RB=$("$GREP" -n 'R76, R77, R79, R80, R83 and R86. Owner decision Q9.B retired Codex from P02' "$RUNBOOK" | cut -d: -f1 || true)
  echo "LOCAL research/RUNBOOK.md line ${RB:-none}: $(sed -n "${RB:-1}p" "$RUNBOOK")"
  assert "$(gt0 "${RB:-0}")" \
    "RUNBOOK section 2 lists R76 in the Muse substitution set in the same sentence that records Q9.B retiring Codex from P02"
  MIG=$(jq -r '[.events[]? // empty | select(.migration != null) | .migration | "\(.from)->\(.to) \(.reason)"] | join("; ")' "$MANIFEST" 2>/dev/null || true)
  if [ -z "$MIG" ]; then
    MIG=$(jq -r '[.. | objects | select(has("migration")) | .migration | "\(.from)->\(.to) \(.reason)"] | join("; ")' "$MANIFEST")
  fi
  echo "LOCAL manifest.json migration record: ${MIG}"
  assert "$(if printf '%s' "$MIG" | "$GREP" -q 'codex->muse muse bulk substitution (owner decision Q5.A 2026-09-21)'; then echo 1; else echo 0; fi)" \
    "the run's own manifest records the codex-to-muse migration under owner decision Q5.A of 2026-09-21"
  MSHA=$(sha "$MUSE")
  assert "$(eq "$MSHA" "31be2e15e942401a98031416eef2d7ab2043ddae1a343016c929b87ba88c67c5")" \
    "raw/muse.md hashes to the value ## Engines cites"
  echo "LOCAL operations/muse.json (live state, printed, not asserted — the controller's collection step changes it):"
  jq -c '{state, request_id, raw_sha256: (.raw_sha256 // null)}' "$MUSEOP" | sed 's/^/        /'
  echo "LOCAL manifest.json state = $(jq -r '.state' "$MANIFEST")"
  if [ -f "$ROOT/scripts/research_validation.py" ]; then
    python3 - "$ROOT" "$MUSE" > "$WORK/shape.txt" <<'PY'
import sys
sys.path.insert(0, sys.argv[1] + "/scripts")
from research_validation import validate_answer_text
errs = validate_answer_text(open(sys.argv[2], encoding="utf-8").read(), "crate")
print("errors=%d" % len(errs))
for e in errs:
    print("  " + e)
PY
    sed 's/^/        /' "$WORK/shape.txt"
    assert "$(eq "$("$GREP" -c '^errors=0$' "$WORK/shape.txt" || true)" "1")" \
      "validate_answer_text(raw/muse.md, 'crate') reports no shape error: all fifteen H3 fields, in order, each with a body"
  else
    skip "A: scripts/research_validation.py is not reachable, so the Muse report's shape was not re-validated"
  fi
  # Muse's ### Parameters names parameters that are not registry rows.
  REG="$ROOT/docs/port/PARAMETERS.md"
  "$GREP" '^- assumes ' "$MUSE" | sed 's/^- assumes \([^ ]*\) = .*/\1/' > "$WORK/muse-params.txt"
  echo "LOCAL parameter names on raw/muse.md's '- assumes' lines: $(tr '\n' ' ' < "$WORK/muse-params.txt")"
  NOTREG=0
  while read -r name; do
    if "$GREP" -q "^| ${name} |" "$REG"; then echo "        ${name}: a registry row"
    else echo "        ${name}: NOT a row of docs/port/PARAMETERS.md"; NOTREG=$((NOTREG + 1)); fi
  done < "$WORK/muse-params.txt"
  assert "$(eq "$NOTREG" "3")" \
    "all three of Muse's '- assumes' names (web-framework-stack, cors-allowlist-value, middleware-ordering) are absent from the registry, so none can be carried forward: a report defect recorded under ## Engines, not a parameter"
  assert "$(eq "$("$GREP" -cF 'Proposed, not executed (no commands run in this research pass)' "$MUSE" || true)" "1")" \
    "the Muse report states that it executed no command, so none of its behavioural claims is measured evidence"
fi
echo

# ---------------------------------------------------------------------------
echo "--- B. the version floor: 0.7 (Muse) or 0.7.1 (this decision)? ---"
curl -sS -A "$UA" "https://crates.io/api/v1/crates/tower-http/versions" -o "$WORK/th-versions.json"
echo "endpoint: GET https://crates.io/api/v1/crates/tower-http/versions"
for v in 0.7.0 0.7.1; do
  echo "FIGURE tower-http ${v}: $(jq -r --arg v "$v" '.versions[] | select(.num==$v) | "created_at=\(.created_at) yanked=\(.yanked) rust_version=\(.rust_version)"' "$WORK/th-versions.json")"
done
assert "$(eq "$(jq -r '.versions[] | select(.num=="0.7.0") | .yanked' "$WORK/th-versions.json")" "false")" \
  "0.7.0 is not yanked, so a caret requirement of \"0.7\" admits it as a resolution for downstream consumers of the published crates/web library"
for v in 0.7.0 0.7.1; do
  curl -sSL -A "$UA" "https://static.crates.io/crates/tower-http/tower-http-$v.crate" -o "$WORK/th-$v.crate"
  echo "PINNED tower-http-$v.crate sha256 = $(sha "$WORK/th-$v.crate")"
  tar -xzf "$WORK/th-$v.crate" -C "$WORK"
  sleep 1
done
DIFFS=$(diff -rq "$WORK/tower-http-0.7.0/src/cors" "$WORK/tower-http-0.7.1/src/cors" 2>/dev/null | "$GREP" -c 'differ\|Only in' || true)
echo "FIGURE files differing under src/cors between 0.7.0 and 0.7.1 = ${DIFFS}"
assert "$(eq "$DIFFS" "0")" \
  "src/cors is byte-identical between 0.7.0 and 0.7.1, so the floor question is not about CORS behaviour"
awk '/^# 0\.7\.1/{f=1; next} /^# 0\.7\.0/{f=0} f' "$WORK/tower-http-0.7.1/CHANGELOG.md" > "$WORK/cl071.txt"
# shellcheck disable=SC2016  # backticks are literal Markdown in the changelog
CL_CORS=$("$GREP" -c '`cors`' "$WORK/cl071.txt" || true)
echo "FIGURE changelog entries naming \`cors\` in the 0.7.1 section = ${CL_CORS}"
echo "HEAD  the 0.7.1 section's Fixed entries that name a regression:"
"$GREP" -n 'regressed in 0.7.0' "$WORK/cl071.txt" | sed 's/^/        /' || true
assert "$(eq "$CL_CORS" "0")" \
  "the 0.7.1 changelog section names cors nowhere, consistent with the byte-identical source"
assert "$(gt0 "$("$GREP" -c 'regressed in 0.7.0' "$WORK/cl071.txt" || true)")" \
  "and 0.7.1 does fix a regression introduced in 0.7.0 (in decompression, a module this dependency line does not enable) — so 0.7.0 is not simply 0.7.1 with an older date"
echo

# ---------------------------------------------------------------------------
echo "--- C. actix-cors 0.7.2, gate by gate ---"
curl -sS -A "$UA" "https://crates.io/api/v1/crates/actix-cors" -o "$WORK/ac.json"
curl -sS -A "$UA" "https://crates.io/api/v1/crates/actix-cors/versions" -o "$WORK/ac-versions.json"
echo "endpoint: GET https://crates.io/api/v1/crates/actix-cors (and /versions)"
AC_NUM=$(jq -r '[.versions[] | select(.yanked==false)] | .[0].num' "$WORK/ac-versions.json")
echo "FIGURE actix-cors newest non-yanked = ${AC_NUM}, created_at = $(jq -r '[.versions[] | select(.yanked==false)] | .[0].created_at' "$WORK/ac-versions.json"), rust_version = $(jq -r '[.versions[] | select(.yanked==false)] | .[0].rust_version' "$WORK/ac-versions.json")"
echo "FIGURE actix-cors crate.recent_downloads (90-day) = $(jq -r '.crate.recent_downloads' "$WORK/ac.json"); crate.downloads (all-time) = $(jq -r '.crate.downloads' "$WORK/ac.json")"
assert "$(eq "$AC_NUM" "0.7.2")" "actix-cors 0.7.2 is still the newest non-yanked release, the version both reports name"
sleep 1
curl -sS -A "$UA" "https://crates.io/api/v1/crates/actix-cors/0.7.2/dependencies" -o "$WORK/ac-deps.json"
echo "endpoint: GET https://crates.io/api/v1/crates/actix-cors/0.7.2/dependencies"
AC_DEPS=$(jq -r '[.dependencies[] | select(.kind=="normal" and .optional==false) | .crate_id] | sort | join(", ")' "$WORK/ac-deps.json")
echo "FIGURE actix-cors 0.7.2 required normal dependencies = ${AC_DEPS}"
assert "$(if printf '%s' "$AC_DEPS" | "$GREP" -qw 'actix-web'; then echo 1; else echo 0; fi)" \
  "gate 5, stated: actix-cors requires actix-web — its runtime coupling is a whole second HTTP framework, which is a fact to state, not a gate failure"
sleep 1
curl -sSL -A "$UA" "https://static.crates.io/crates/actix-cors/actix-cors-0.7.2.crate" -o "$WORK/ac.crate"
echo "PINNED actix-cors-0.7.2.crate sha256 = $(sha "$WORK/ac.crate")"
tar -xzf "$WORK/ac.crate" -C "$WORK"
AC="$WORK/actix-cors-0.7.2"
echo "PINNED actix-cors-0.7.2/Cargo.toml [features]:"
awk '/^\[features\]/{f=1; print; next} /^\[/{f=0} f && NF' "$AC/Cargo.toml" | sed 's/^/        /'
echo "PINNED actix-cors-0.7.2/src/lib.rs unsafe-code lint:"
"$GREP" -n 'unsafe_code' "$AC/src/lib.rs" | sed 's/^/        /' || true
AC_UNSAFE=$("$GREP" -rw 'unsafe' "$AC/src" | "$GREP" -vc 'unsafe_code' || true)
echo "FIGURE occurrences of the token 'unsafe' in actix-cors-0.7.2/src outside the lint attribute = ${AC_UNSAFE}"
assert "$(gt0 "$("$GREP" -c 'forbid(unsafe_code)' "$AC/src/lib.rs" || true)")" \
  "gate 3, unsafe posture: actix-cors forbids unsafe code at its crate root"
assert "$(eq "$AC_UNSAFE" "0")" "and contains no unsafe block"
AC_RS=$(curl -sS -A "$UA" -o /dev/null -w '%{http_code}' "https://rustsec.org/packages/actix-cors.html")
sleep 1
CTRL=$(curl -sS -A "$UA" -o /dev/null -w '%{http_code}' "https://rustsec.org/packages/atty.html")
echo "FIGURE https://rustsec.org/packages/actix-cors.html -> HTTP ${AC_RS}; control https://rustsec.org/packages/atty.html -> HTTP ${CTRL}"
assert "$(if [ "$AC_RS" = "404" ] && [ "$CTRL" = "200" ]; then echo 1; else echo 0; fi)" \
  "gate 3, advisories: RustSec has no page for actix-cors while the atty control still answers 200, so the 404 means no advisory rather than a changed site"
# Gate 2 over the tree: a resolve-only probe, never built.
P="$WORK/acprobe"
mkdir -p "$P/src"
cat > "$P/Cargo.toml" <<'EOF'
[package]
name = "r76acprobe"
version = "0.0.0"
edition = "2024"
publish = false

[dependencies]
actix-cors = "=0.7.2"
EOF
echo 'pub fn placeholder() {}' > "$P/src/lib.rs"
ACLOCK="$HERE/snapshots/actix-cors-probe.Cargo.lock"
if [ "$RECORD" = "1" ]; then
  (cd "$P" && cargo generate-lockfile -q)
  cp "$P/Cargo.lock" "$ACLOCK"
  echo "RECORD wrote snapshots/actix-cors-probe.Cargo.lock from the registry"
elif [ -f "$ACLOCK" ]; then
  cp "$ACLOCK" "$P/Cargo.lock"
fi
if [ ! -f "$P/Cargo.lock" ]; then
  skip "C: snapshots/actix-cors-probe.Cargo.lock is missing, so actix-cors's dependency-tree MSRV was not resolved"
elif ! (cd "$P" && cargo metadata --locked --format-version 1 --all-features 2>/dev/null) > "$WORK/ac-md.json"; then
  skip "C: cargo could not fetch the locked actix-cors tree, so its dependency-tree MSRV was not resolved"
else
  echo "LOCK  snapshots/actix-cors-probe.Cargo.lock sha256 = $(sha "$P/Cargo.lock")"
  RVSORT='[.packages[] | select(.rust_version != null) | select(.name != "r76acprobe")
           | {n: .name, v: .rust_version, k: (.rust_version | split(".") | map(tonumber) | . + [0, 0, 0] | .[0:3])}]
          | sort_by(.k)'
  AC_N=$(jq -r '.packages | length' "$WORK/ac-md.json")
  AC_MAX=$(jq -r "$RVSORT"' | .[-1] | "\(.v) (\(.n))"' "$WORK/ac-md.json")
  AC_OK=$(jq -r "$RVSORT"' | if (.[-1].k <= [1, 96, 0]) then 1 else 0 end' "$WORK/ac-md.json")
  echo "FIGURE actix-cors 0.7.2 resolved tree (locked, all features): ${AC_N} packages; maximum declared rust-version = ${AC_MAX}"
  assert "$AC_OK" \
    "gate 2 over the tree: the highest declared rust-version in actix-cors 0.7.2's locked tree is at or below the 1.96 floor, compared numerically"
  AC_RT=$(jq -r '[.packages[] | select(.name=="actix-rt" or .name=="tokio") | "\(.name) \(.version)"] | sort | join(", ")' "$WORK/ac-md.json")
  echo "FIGURE runtime crates in actix-cors's tree: ${AC_RT}"
  assert "$(if printf '%s' "$AC_RT" | "$GREP" -q 'actix-rt'; then echo 1; else echo 0; fi)" \
    "gate 5, stated: the tree carries actix-rt, actix's own runtime wrapper, so adopting actix-cors means adopting actix-web's executor model beside R69's axum on tokio"
fi
if ! gh auth status >/dev/null 2>&1; then
  skip "C: gh is not authenticated, so actix-extras's CI matrix was not read"
else
  gh_get "repos/actix/actix-extras/contents/.github/workflows/ci.yml" "$WORK/ac-ci.json"
  jq -r '.content' "$WORK/ac-ci.json" | base64 -d > "$WORK/ac-ci.yml"
  echo "endpoint: GET https://api.github.com/repos/actix/actix-extras/contents/.github/workflows/ci.yml (default branch)"
  echo "HEAD  target and version matrix lines:"
  "$GREP" -n -E '\{ name: (Linux|macOS|Windows|msrv)' "$WORK/ac-ci.yml" | sed 's/^/        /'
  # The macOS row lives in a second job; read which steps that job runs.
  MACJOB=$(awk '/os: macos-latest/{f=1} f' "$WORK/ac-ci.yml" | "$GREP" -E '^ +- name: ' | sed 's/^ *- name: //' | tr '\n' ';')
  echo "HEAD  steps of the job whose matrix carries macos-latest: ${MACJOB}"
  assert "$(if "$GREP" -q 'os: ubuntu-latest' "$WORK/ac-ci.yml" && "$GREP" -q 'os: macos-latest' "$WORK/ac-ci.yml"; then echo 1; else echo 0; fi)" \
    "gate 4: actix-extras's CI runs on both members of target-os-matrix, ubuntu-latest and macos-latest"
  MACTEST=$(printf '%s' "$MACJOB" | tr ';' '\n' | "$GREP" -c '^tests' || true)
  echo "FIGURE test steps (named 'tests…') in the macOS/Windows job = ${MACTEST}"
fi
echo

# ---------------------------------------------------------------------------
echo "--- D. rocket_cors: the concrete signal behind Muse's at-risk ---"
curl -sS -A "$UA" "https://crates.io/api/v1/crates/rocket_cors/versions" -o "$WORK/rc-versions.json"
echo "endpoint: GET https://crates.io/api/v1/crates/rocket_cors/versions"
echo "FIGURE rocket_cors newest non-yanked = $(jq -r '[.versions[] | select(.yanked==false)] | .[0] | "\(.num) created_at=\(.created_at) rust_version=\(.rust_version)"' "$WORK/rc-versions.json")"
if gh auth status >/dev/null 2>&1; then
  gh_get "repos/lawliet89/rocket_cors" "$WORK/rc-repo.json"
  echo "endpoint: GET https://api.github.com/repos/lawliet89/rocket_cors"
  RC_PUSHED=$(jq -r '.pushed_at' "$WORK/rc-repo.json")
  echo "FIGURE lawliet89/rocket_cors pushed_at = ${RC_PUSHED}; archived = $(jq -r '.archived' "$WORK/rc-repo.json"); stargazers_count = $(jq -r '.stargazers_count' "$WORK/rc-repo.json")"
  gh_get "repos/lawliet89/rocket_cors/issues/118" "$WORK/rc-118.json"
  echo "endpoint: GET https://api.github.com/repos/lawliet89/rocket_cors/issues/118"
  echo "FIGURE rocket_cors#118 created_at = $(jq -r '.created_at' "$WORK/rc-118.json"); state = $(jq -r '.state' "$WORK/rc-118.json"); comments = $(jq -r '.comments' "$WORK/rc-118.json")"
  assert "$(if [[ "$RC_PUSHED" < "2024-09-27" ]]; then echo 1; else echo 0; fi)" \
    "no push to lawliet89/rocket_cors in the two years before this run — a concrete signal of the kind the rubric's at-risk requires, which the decision records beside its fit exclusion"
else
  skip "D: gh is not authenticated, so rocket_cors's repository was not read"
fi
echo

# ---------------------------------------------------------------------------
echo "--- E. reverse-dependency counts ---"
for c in tower-http actix-cors; do
  curl -sS -A "$UA" "https://crates.io/api/v1/crates/$c/reverse_dependencies?per_page=1" -o "$WORK/rd-$c.json"
  echo "FIGURE ${c} reverse_dependencies meta.total = $(jq -r '.meta.total' "$WORK/rd-$c.json")   (GET https://crates.io/api/v1/crates/${c}/reverse_dependencies)"
  sleep 1
done
assert "$(gt0 "$(jq -r '.meta.total' "$WORK/rd-tower-http.json")")" "the tower-http reverse-dependency count resolved rather than returning an empty body"
echo

# ---------------------------------------------------------------------------
echo "--- F. tower-http issue responsiveness as of this revision, over both windows ---"
SNAP="$HERE/snapshots/tower-http-issue-triage-2026-09-27.json"
if [ "$RECORD" = "1" ]; then
  gh_get "repos/tower-rs/tower-http/issues?state=all&sort=created&direction=desc&per_page=100" "$WORK/issues.json"
  gh_get "repos/tower-rs/tower-http/issues/comments?sort=created&direction=desc&per_page=100" "$WORK/comments.json"
  python3 - "$WORK/issues.json" "$WORK/comments.json" "$SNAP" <<'PY'
import json, sys, datetime
items = json.load(open(sys.argv[1]))
comments = json.load(open(sys.argv[2]))
def num(url): return int(url.rstrip("/").split("/")[-1])
snap = {
    "_note": "Field-projected snapshot. Comment and issue bodies are deliberately omitted; only number, kind, timestamps, state, author login and author_association are kept.",
    "fetched_utc": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "endpoints": [
        "GET https://api.github.com/repos/tower-rs/tower-http/issues?state=all&sort=created&direction=desc&per_page=100",
        "GET https://api.github.com/repos/tower-rs/tower-http/issues/comments?sort=created&direction=desc&per_page=100",
    ],
    "comments_page_covers_from": min(c["created_at"] for c in comments),
    "comments_page_size": len(comments),
    "items": [{"number": i["number"], "is_pull_request": "pull_request" in i,
               "created_at": i["created_at"], "state": i["state"],
               "user_login": i["user"]["login"], "author_association": i["author_association"]}
              for i in items],
    "comments": [{"issue_number": num(c["issue_url"]), "created_at": c["created_at"],
                  "user_login": c["user"]["login"], "author_association": c["author_association"]}
                 for c in comments],
}
json.dump(snap, open(sys.argv[3], "w"), indent=2)
open(sys.argv[3], "a").write("\n")
PY
  echo "RECORD wrote snapshots/tower-http-issue-triage-2026-09-27.json from the live API"
fi
if [ ! -f "$SNAP" ]; then
  skip "F: snapshots/tower-http-issue-triage-2026-09-27.json is absent, so responsiveness was not recomputed"
else
  echo "SNAP  $SNAP sha256 = $(sha "$SNAP")"
  python3 - "$SNAP" > "$WORK/triage.txt" <<'PY'
import json, sys, datetime
d = json.load(open(sys.argv[1]))
MAINT = {"OWNER", "MEMBER", "COLLABORATOR"}
def dt(s): return datetime.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ")
by = {}
for c in d["comments"]:
    by.setdefault(c["issue_number"], []).append(c)
print("fetched_utc: %s" % d["fetched_utc"])
print("comments page covers back to %s (%d comments)" % (d["comments_page_covers_from"], d["comments_page_size"]))
def window(label, rows):
    print("%s: %s" % (label, ", ".join("#%d%s" % (i["number"], "(PR)" if i["is_pull_request"] else "") for i in rows)))
    answered, unanswered = [], []
    for i in rows:
        n, opened, author = i["number"], dt(i["created_at"]), i["user_login"]
        cs = sorted(by.get(n, []), key=lambda c: c["created_at"])
        first = next((c for c in cs if c["author_association"] in MAINT and c["user_login"] != author), None)
        others = sum(1 for c in cs if c["user_login"] == author)
        if first:
            delta = (dt(first["created_at"]) - opened).total_seconds()
            answered.append(delta)
            print("  #%d opened %s (%s) state=%s -> first maintainer reply after %.2f h"
                  % (n, i["created_at"], i["author_association"], i["state"], delta / 3600))
        else:
            before = i["created_at"] < d["comments_page_covers_from"]
            unanswered.append((n, i["state"], before))
            print("  #%d opened %s (%s) state=%s -> no maintainer comment on the fetched page; reporter comments=%d%s"
                  % (n, i["created_at"], i["author_association"], i["state"], others,
                     "  [opened BEFORE the comment page's window]" if before else ""))
    ds = sorted(answered)
    med = (ds[len(ds)//2] if len(ds) % 2 else (ds[len(ds)//2 - 1] + ds[len(ds)//2]) / 2) if ds else None
    key = label.split(":")[0].replace(" ", "_")
    by_maint = sum(1 for i in rows if i["author_association"] in MAINT)
    print("%s answered=%d unanswered=%d closed_unanswered=%d outside_window=%d opened_by_maintainer=%d median_answered_h=%s"
          % (key, len(answered), len(unanswered), sum(1 for _, s, _ in unanswered if s == "closed"),
             sum(1 for _, _, b in unanswered if b), by_maint, "%.2f" % (med / 3600) if med is not None else "undefined"))
issues = [i for i in d["items"] if not i["is_pull_request"]][:10]
window("rubric window: the 10 most recently opened non-PR issues", issues)
items10 = d["items"][:10]
window("muse window: the non-PR issues among the 10 most recently created items", [i for i in items10 if not i["is_pull_request"]])
PY
  sed 's/^/  /' "$WORK/triage.txt"
  RUB=$("$GREP" -c '^rubric_window answered=' "$WORK/triage.txt" || true)
  assert "$(eq "$RUB" "1")" "the rubric's window (10 most recently opened non-PR issues) was computed from the snapshot"
  MW=$("$GREP" -c '^muse_window answered=' "$WORK/triage.txt" || true)
  assert "$(eq "$MW" "1")" "and so was the narrower window the Muse report used, so the two reports' figures can be compared like for like"
fi
echo

# ---------------------------------------------------------------------------
echo "--- G. repository figures the decision quotes that no other log carries ---"
if ! gh auth status >/dev/null 2>&1; then
  skip "G: gh is not authenticated, so no repository figure was read"
else
  for r in actix/actix-extras loco-rs/loco tokio-rs/console; do
    gh_get "repos/$r" "$WORK/repo.json"
    echo "FIGURE ${r}: stargazers_count = $(jq -r '.stargazers_count' "$WORK/repo.json"); archived = $(jq -r '.archived' "$WORK/repo.json"); pushed_at = $(jq -r '.pushed_at' "$WORK/repo.json")   (GET https://api.github.com/repos/${r})"
  done
  gh_get "search/issues?q=repo:actix/actix-extras+is:issue+is:open&per_page=1" "$WORK/ax-search.json"
  AX_OPEN=$(jq -r '.total_count' "$WORK/ax-search.json")
  echo "FIGURE actix/actix-extras open issues (search/issues total_count; the WHOLE monorepo, not actix-cors alone) = ${AX_OPEN}"
  assert "$(gt0 "$AX_OPEN")" "the actix-extras open-issue search resolved rather than returning an empty body"
fi
echo

# ---------------------------------------------------------------------------
echo "=== RESULT ==="
echo "PASS=${pass} FAIL=${failn} SKIP=${skipn} TOTAL=$((pass + failn + skipn))"
if [ "$failn" -gt 0 ]; then echo "RESULT: FAIL"; exit 1; fi
echo "RESULT: PASS"
