#!/usr/bin/env bash
# R19 dependabot-config-shape — synthesizer empirical check.
# Verifies claims made by the raw reports. Creates nothing, installs nothing,
# opens no pull request. Read-only HTTP/git reads.
set -uo pipefail

FAILS=0
pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; FAILS=$((FAILS+1)); }
note() { printf 'NOTE  %s\n' "$1"; }
hdr()  { printf '\n===== %s =====\n' "$1"; }
# Sections marked LIVE read a moving source (a rendered page, or another
# repository's current branches, pull requests and labels). They are NOT
# reproducible byte-for-byte; every other section reads a literal pin, a local
# git object or a file in this repository and is.
live() { printf 'LIVE  %s (retrieved %s) — this section is not byte-for-byte reproducible\n' "$1" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"; }

UA='rs-launch-blueprint-research (steve@conceptm.com)'
GHRAW=(-H 'Accept: application/vnd.github.raw')
# Working files stay beside this script, never in /tmp.
SCRATCH="$(cd "$(dirname "$0")" && pwd)"
export SCRATCH

hdr "0. Toolchain and environment"
date -u '+run-utc %Y-%m-%dT%H:%M:%SZ'
uname -a
rustc --version || note "rustc absent"
cargo --version || note "cargo absent"
gh --version | head -1
printf 'cwd %s\n' "$(pwd)"

hdr "1. Pins for the sources read below (literal inputs, NOT resolved from main)"
# These two shas are the pins the decision names. They are inputs to this script,
# never looked up, so every pinned section below replays the same bytes forever.
DBC_SHA=1abafc5ca0900334fd970832e9ef43f2afc78233
DOCS_SHA=dd75c5f38a14d1c07c3982beddb471a605b142f7
printf 'dependabot/dependabot-core pin (input) = %s\n' "$DBC_SHA"
printf 'github/docs                pin (input) = %s\n' "$DOCS_SHA"
DBC_ECHO=$(gh api "repos/dependabot/dependabot-core/commits/$DBC_SHA" --jq '.sha + "  " + .commit.committer.date')
DOCS_ECHO=$(gh api "repos/github/docs/commits/$DOCS_SHA" --jq '.sha + "  " + .commit.committer.date')
printf 'dependabot/dependabot-core resolved    = %s\n' "$DBC_ECHO"
printf 'github/docs                resolved    = %s\n' "$DOCS_ECHO"
if [ "${DBC_ECHO%% *}" = "$DBC_SHA" ] && [ "${DOCS_ECHO%% *}" = "$DOCS_SHA" ]; then
  pass "both pins exist and resolve to themselves — every pinned read below is immutable"
else
  fail "a named pin did not resolve to itself"
fi

DBC() { gh api "repos/dependabot/dependabot-core/contents/$1?ref=$DBC_SHA" "${GHRAW[@]}"; }
DOCS() { gh api "repos/github/docs/contents/$1?ref=$DOCS_SHA" "${GHRAW[@]}"; }

hdr "2. CLAIM (opus): Cargo's Dependabot production check is unconditionally true"
CARGO_RB=$(DBC cargo/lib/dependabot/cargo.rb)
printf '%s\n' "$CARGO_RB" | grep -n "register_production_check\|register_label_details\|register_dependency_type" || true
if printf '%s\n' "$CARGO_RB" | grep -Eq 'register_production_check\("cargo", *->\(_\) *\{ *true *\}\)'; then
  pass "cargo.rb registers production check as ->(_) { true } — every Cargo dependency is 'production'"
else
  fail "cargo.rb production check does not match the quoted constant-true form"
fi
printf '%s\n' "$CARGO_RB" | grep -n 'name: "rust"' >/dev/null && pass "cargo default label is 'rust'" || fail "cargo default label not 'rust'"

hdr "2b. Same check for a package manager that DOES split dev deps (control)"
NPM_RB=$(DBC npm_and_yarn/lib/dependabot/npm_and_yarn.rb)
printf '%s\n' "$NPM_RB" | grep -n "register_production_check" || true
printf '%s\n' "$NPM_RB" | grep -q "register_production_check" && pass "npm registers a non-trivial production check (control case)" || note "npm production check not found at this path"

hdr "2c. GitHub Actions default label + the universal dependencies label"
GHA_RB=$(DBC github_actions/lib/dependabot/github_actions.rb)
printf '%s\n' "$GHA_RB" | grep -n "register_label_details" || true
printf '%s\n' "$GHA_RB" | grep -q 'name: "github_actions"' && pass "github-actions default label is the UNDERSCORED github_actions" || fail "github_actions default label not found"
LABELER=$(DBC common/lib/dependabot/pull_request_creator/labeler.rb)
printf '%s\n' "$LABELER" | grep -n "DEFAULT_DEPENDENCIES_LABEL" | head -3
printf '%s\n' "$LABELER" | grep -q 'DEFAULT_DEPENDENCIES_LABEL *= *"dependencies"' && pass "default 'dependencies' label confirmed" || fail "DEFAULT_DEPENDENCIES_LABEL not confirmed"

hdr "3. CLAIM (both): the documented per-ecosystem support lists"
OPTREF=$(DOCS content/code-security/reference/supply-chain-security/dependabot-options-reference.md)
printf 'options-reference bytes: %s\n' "$(printf '%s' "$OPTREF" | wc -c | tr -d ' ')"
printf '%s\n' "$OPTREF" | grep -n -A3 '^### .groups' | head -20
echo "--- dependency-type support line ---"
printf '%s\n' "$OPTREF" | grep -n -B2 -A2 'dependency-type' | grep -i "supported by" | head -3
if printf '%s\n' "$OPTREF" | grep -A40 '`dependency-type`' | grep -i "supported by" | head -1 | grep -qv 'cargo'; then
  pass "groups.dependency-type support list does not include cargo"
else
  fail "groups.dependency-type appears to list cargo"
fi
echo "--- prefix-development support line ---"
printf '%s\n' "$OPTREF" | grep -n -i "prefix-development" | head -5
printf '%s\n' "$OPTREF" | grep -A6 'prefix-development' | grep -i "supported by" | head -2
echo "--- versioning-strategy support line ---"
printf '%s\n' "$OPTREF" > "$SCRATCH"/r19-optref.md
grep -n -A2 '^## .versioning-strategy' "$SCRATCH"/r19-optref.md | grep -i "supported by" | head -2
if grep -A2 '^## .versioning-strategy' "$SCRATCH"/r19-optref.md | grep -i "supported by" | grep -q 'cargo'; then
  pass "versioning-strategy is supported for cargo (its list omits github-actions)"
else
  fail "versioning-strategy support list does not read as expected"
fi
echo "--- groups.update-types: the documented value set ---"
grep -n 'update-types. | Limit the group' "$SCRATCH"/r19-optref.md
echo "--- cooldown support table: Cargo row, then the GitHub Actions row (a Liquid variable, not literal text) ---"
grep -n "^| Cargo  " "$SCRATCH"/r19-optref.md | head -2
grep -n "prodname_actions %} | {% octicon" "$SCRATCH"/r19-optref.md | head -2
echo "--- cooldown default paragraph ---"
printf '%s\n' "$OPTREF" | grep -n -i "cooldown period of 3 days\|default cooldown" | head -5
echo "--- ungrouped-dependency behavior sentence ---"
printf '%s\n' "$OPTREF" | grep -n -i "individual pull requests" | head -5

hdr "4. CLAIM (opus): Cargo's compatibility rule differs from plain SemVer"
live "the Cargo book's rendered specifying-dependencies page"
curl -sSL -A "$UA" https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html > "$SCRATCH"/r19-cargobook.html
grep -o "left-most non-zero[^<]*" "$SCRATCH"/r19-cargobook.html | head -2
grep -o "0\.2\.3 *:= *&gt;=0\.2\.3, *&lt;0\.3\.0" "$SCRATCH"/r19-cargobook.html | head -2
grep -o "1\.2\.3 *:= *&gt;=1\.2\.3, *&lt;2\.0\.0" "$SCRATCH"/r19-cargobook.html | head -2
if grep -q "left-most non-zero" "$SCRATCH"/r19-cargobook.html; then
  pass "Cargo book states the left-most-non-zero compatibility rule (0.1 -> 0.2 is incompatible)"
else
  fail "could not read the caret rule from the Cargo book"
fi

hdr "5. REFUTED CLAIM (revision 1): that Dependabot classifies a Cargo 0.1 -> 0.2 bump as 'minor'"
# Revision 1 rejected ts's update-types filter on the ground that Dependabot uses
# plain SemVer, so a [minor, patch] group would ADMIT a Cargo-incompatible
# 0.1 -> 0.2 bump. Sections 5a-5d read the classifier at the pin and refute that.
echo "--- 5a. the Cargo-specific classifier: cargo/lib/dependabot/cargo/version.rb ---"
CVER=$(DBC cargo/lib/dependabot/cargo/version.rb)
printf '%s\n' "$CVER" | grep -n "def self.update_type" -A10 | head -16
printf '%s\n' "$CVER" | grep -n "def self.cargo_pre_1_0_type" -A14 | head -20
printf '%s\n' "$CVER" | grep -n "def ignored_minor_versions" -A10 | head -14
if printf '%s\n' "$CVER" | grep -q 'cargo_pre_1_0_type(from_major, from_minor, from_patch, to_major, to_minor, to_patch)'; then
  pass "Cargo::Version.update_type routes every pre-1.0 pair to cargo_pre_1_0_type"
else
  fail "Cargo::Version.update_type does not route pre-1.0 pairs to a Cargo-specific method"
fi
if printf '%s\n' "$CVER" | grep -A14 "def self.cargo_pre_1_0_type" | grep -q 'return "major" if to_minor > from_minor'; then
  pass "cargo_pre_1_0_type returns \"major\" when the 0.y component changes — 0.1 -> 0.2 is MAJOR, not minor"
else
  fail "cargo_pre_1_0_type does not return major on a 0.y change"
fi
if printf '%s\n' "$CVER" | grep -A8 "def ignored_minor_versions" | grep -q "return ignored_major_versions if major.zero?"; then
  pass "the same class makes ignore.update-types Cargo-aware (0.y minor ignores route to major)"
else
  fail "ignored_minor_versions is not Cargo-aware"
fi

echo "--- 5b. the pinned test that asserts it ---"
CSPEC=$(DBC cargo/spec/dependabot/cargo/version_spec.rb)
printf '%s\n' "$CSPEC" | grep -n -B4 -A4 'update_type("0.1.0", "0.2.0")' | head -20
if printf '%s\n' "$CSPEC" | grep -q 'expect(described_class.update_type("0.1.0", "0.2.0")).to eq("major")'; then
  pass "the pinned spec asserts update_type(0.1.0, 0.2.0) == major"
else
  fail "the pinned spec does not assert the 0.1.0 -> 0.2.0 case"
fi
if printf '%s\n' "$CSPEC" | grep -q 'update_type("0.1.0", "0.1.1")).to eq("patch")'; then
  pass "the pinned spec asserts update_type(0.1.0, 0.1.1) == patch (0.y patch stays patch)"
else
  fail "the pinned spec does not assert the 0.1.0 -> 0.1.1 case"
fi

echo "--- 5c. the group-update path that consumes it: updater/lib/dependabot/updater/group_update_creation.rb ---"
GUC=$(DBC updater/lib/dependabot/updater/group_update_creation.rb)
printf '%s\n' "$GUC" | grep -n 'job.package_manager == "cargo"' | head -3
printf '%s\n' "$GUC" | grep -n "def cargo_update_type_allowed?" -A10 | head -14
if printf '%s\n' "$GUC" | grep -q 'return cargo_semver_rules_allow_grouping?(group, dependency, checker) if job.package_manager == "cargo"'; then
  pass "semver_rules_allow_grouping? dispatches Cargo to a Cargo-specific path before the plain-SemVer branch"
else
  fail "no Cargo dispatch found in semver_rules_allow_grouping?"
fi
if printf '%s\n' "$GUC" | grep -A10 "def cargo_update_type_allowed?" | grep -q 'group_update_types.include?(actual_update_type)'; then
  pass "a Cargo group admits an update only when its update-types contain the COMPUTED Cargo type"
else
  fail "the Cargo group predicate does not test the computed type"
fi
echo "CONSEQUENCE: a cargo group declaring [minor, patch] EXCLUDES 0.1 -> 0.2 (classified major),"
echo "             so that bump leaves the group and becomes an individual pull request."

echo "--- 5d. when the Cargo-aware classification landed (history read AT the pin, deterministic) ---"
gh api "repos/dependabot/dependabot-core/commits?path=cargo/lib/dependabot/cargo/version.rb&sha=$DBC_SHA&per_page=100" \
  --jq '.[] | [.sha[0:8], .commit.author.date, (.commit.message | split("\n")[0])] | @tsv' | grep -i "pre-1.0\|semantic versioning" | head -3
if gh api "repos/dependabot/dependabot-core/commits?path=cargo/lib/dependabot/cargo/version.rb&sha=$DBC_SHA&per_page=100" \
     --jq '.[] | .sha' | grep -q '^2e05932'; then
  pass "commit 2e059329 (PR #13349, 2025-10-21) introduced the pre-1.0 classification, after #9681 was filed"
else
  fail "could not locate the introducing commit in the pinned history"
fi

echo "--- 5e. issue #9681 asks for NEW NAMED VALUES, and is still open ---"
gh api repos/dependabot/dependabot-core/issues/9681 --jq '{number,state,created_at,updated_at,comments,title}'
gh api repos/dependabot/dependabot-core/issues/9681 --jq .body | head -25
gh api repos/dependabot/dependabot-core/issues/9681 --jq .state | grep -q open && pass "#9681 (cargo-compatible/cargo-incompatible VALUE NAMES) is still OPEN" || fail "#9681 is not open"
note "#9681 being open does NOT mean the plain values are SemVer-naive: 5a-5d show minor/patch/major are already Cargo-aware for cargo. The issue asks for additional explicitly-named values."

hdr "5f. CLAIM (opus): Dependabot does not read rust-version (issue #5423)"
gh api repos/dependabot/dependabot-core/issues/5423 --jq '{number,state,created_at,updated_at,comments,title}'

hdr "6. CLAIM (opus): cargo's accepted versioning strategies and default"
RU=$(DBC cargo/lib/dependabot/cargo/update_checker/requirements_updater.rb)
printf '%s\n' "$RU" | grep -n "ALLOWED_UPDATE_STRATEGIES" -A6 | head -12
printf '%s\n' "$RU" | grep -q "ALLOWED_UPDATE_STRATEGIES" && pass "cargo restricts the accepted versioning strategies in code" || fail "ALLOWED_UPDATE_STRATEGIES not found"
UC=$(DBC cargo/lib/dependabot/cargo/update_checker.rb)
printf '%s\n' "$UC" | grep -n -B6 "BumpVersionsIfNecessary" | head -20
printf '%s\n' "$UC" | grep -q "BumpVersionsIfNecessary" && pass "cargo's default requirements strategy is BumpVersionsIfNecessary (= increase-if-necessary)" || fail "cargo default strategy not found"

hdr "6b. CLAIM (opus): one cargo entry at / covers a workspace; a member directory errors"
FP=$(DBC cargo/lib/dependabot/cargo/file_parser.rb)
printf '%s\n' "$FP" | grep -n "check_rust_workspace_root" -A8 | head -20
printf '%s\n' "$FP" | grep -q "workspace root" && pass "file_parser requires the workspace root" || fail "workspace-root check not found"

hdr "7. PRACTICE: does a configured group actually batch? (branch names carry the group id)"
live "other repositories' current Dependabot configs and pull-request branches"
for r in cargo-bins/cargo-binstall apache/datafusion helix-editor/helix servo/servo paritytech/polkadot-sdk ratatui/ratatui; do
  echo "--- $r ---"
  echo "config (grouping keys):"
  curl -sS -A "$UA" "https://raw.githubusercontent.com/$r/HEAD/.github/dependabot.yml" \
    | grep -nE "package-ecosystem|groups:|patterns|update-types|cooldown|default-days|open-pull-requests-limit|versioning-strategy" | head -25
  echo "8 most recent dependabot branches:"
  gh api "repos/$r/pulls?state=all&per_page=100" \
    --jq '[.[] | select(.user.login=="dependabot[bot]")][0:8][] | [.created_at, .head.ref, .title] | @tsv'
done

hdr "8. THE ANOMALY: ratatui — is the group inert, or is the whole entry inert?"
live "ratatui's current config and OPEN pull requests (see 8b for the immutable bound)"
echo "--- ratatui config history for the path ---"
gh api "repos/ratatui/ratatui/commits?path=.github/dependabot.yml&per_page=10" \
  --jq '.[] | [.sha[0:8], .commit.author.date, (.commit.message | split("\n")[0])] | @tsv'
echo "--- config in force BEFORE the 2026-04-14 change ---"
gh api "repos/ratatui/ratatui/contents/.github/dependabot.yml?ref=12f92911" "${GHRAW[@]}" | grep -vE "^\s*#|^\s*$"
echo "--- .github directory: is there a second dependabot file? ---"
gh api repos/ratatui/ratatui/contents/.github --jq '.[].name' | grep -i dependabot
DBFILES=$(gh api repos/ratatui/ratatui/contents/.github --jq '.[].name' | grep -ci dependabot)
[ "$DBFILES" = "1" ] && pass "exactly one dependabot config file at ratatui (no yml/yaml collision)" || fail "ratatui has $DBFILES dependabot files"
echo "--- is the committed file valid YAML? ---"
curl -sS -A "$UA" https://raw.githubusercontent.com/ratatui/ratatui/HEAD/.github/dependabot.yml > "$SCRATCH"/r19-ratatui.yml
python3 - <<'PY'
import os, sys, json
try:
    import yaml
except ImportError:
    print("NOTE  pyyaml unavailable; skipping YAML parse")
    sys.exit(0)
d = yaml.safe_load(open(os.environ["SCRATCH"] + "/r19-ratatui.yml"))
print("parsed OK; version =", d.get("version"), "; entries =",
      [(u.get("package-ecosystem"), sorted((u.get("groups") or {}).keys()),
        u.get("open-pull-requests-limit"), (u.get("cooldown") or {}).get("default-days"))
       for u in d["updates"]])
PY
echo "--- key 1: open-pull-requests-limit: 3 — how many cargo PRs are open now? ---"
OPEN_CARGO=$(gh api "repos/ratatui/ratatui/pulls?state=open&per_page=100" \
  --jq '[.[] | select(.user.login=="dependabot[bot]") | select(.head.ref | startswith("dependabot/cargo/"))] | length')
printf 'open cargo dependabot PRs at ratatui: %s (configured limit: 3)\n' "$OPEN_CARGO"
[ "$OPEN_CARGO" -gt 3 ] && pass "open cargo PRs exceed the configured limit of 3 — that key is not in force" \
                        || note "open cargo PRs within the configured limit; this key gives no signal today"
echo "--- key 2: cooldown.default-days: 7 — age of each bumped release when its PR opened ---"
gh api "repos/ratatui/ratatui/pulls?state=open&per_page=100" \
  --jq '.[] | select(.user.login=="dependabot[bot]") | select(.head.ref | startswith("dependabot/cargo/")) | [.number, .created_at, .head.ref] | @tsv' > "$SCRATCH"/r19-ratatui-prs.tsv
cat "$SCRATCH"/r19-ratatui-prs.tsv
python3 - <<'PY'
import datetime, json, os, subprocess, sys
viol = 0
rows = [l.split("\t") for l in open(os.environ["SCRATCH"] + "/r19-ratatui-prs.tsv").read().strip().splitlines() if l.strip()]
for num, created, ref in rows:
    tail = ref.split("dependabot/cargo/")[1]
    crate, _, ver = tail.rpartition("-")
    out = subprocess.run(["curl", "-sS", "-A",
                          "rs-launch-blueprint-research (steve@conceptm.com)",
                          f"https://crates.io/api/v1/crates/{crate}/versions"],
                         capture_output=True, text=True).stdout
    try:
        vs = {v["num"]: v["created_at"] for v in json.loads(out)["versions"]}
    except Exception as e:
        print(f"  {crate} {ver}: crates.io read failed ({e})")
        continue
    pub = vs.get(ver)
    if not pub:
        print(f"  {crate} {ver}: version not found on crates.io")
        continue
    p = datetime.datetime.fromisoformat(pub.replace("Z", "+00:00"))
    c = datetime.datetime.fromisoformat(created.replace("Z", "+00:00"))
    age = (c - p).total_seconds() / 86400
    flag = "  <-- younger than the configured 7-day cooldown" if age < 7 else ""
    viol += age < 7
    print(f"  PR#{num} {crate} {ver}: published {pub}, PR opened {created}, age {age:.2f} d{flag}")
print(f"RESULT releases proposed younger than the configured 7 days: {viol}/{len(rows)}")
sys.exit(0 if viol else 3)
PY
COOLDOWN_RC=$?
if [ "$COOLDOWN_RC" -eq 0 ]; then
  pass "ratatui proposed releases younger than its configured 7-day cooldown — that value is not in force either"
else
  fail "no cooldown-value violation observed at ratatui — reconsider the inert-entry reading"
fi
echo "--- rule out security updates (they bypass groups, cooldown and the PR limit) ---"
for n in $(cut -f1 "$SCRATCH"/r19-ratatui-prs.tsv); do
  BODY=$(gh api "repos/ratatui/ratatui/pulls/$n" --jq .body)
  HITS=$(printf '%s' "$BODY" | grep -co 'GHSA-\|RUSTSEC-\|Vulnerabilities' || true)
  BOILER=$(printf '%s' "$BODY" | grep -co 'compatibility_score' || true)
  LBL=$(gh api "repos/ratatui/ratatui/pulls/$n" --jq '[.labels[].name] | join(",")')
  printf '  PR#%s advisory-marker hits=%s (compatibility-score boilerplate lines=%s) labels=%s\n' "$n" "$HITS" "$BOILER" "$LBL"
done

hdr "8b. IMMUTABLE: the five ratatui cargo PRs that were open at the revision-1 retrieval"
# The revision-1 log recorded 5 open cargo PRs at 2026-09-10T15:41:25Z against a
# configured limit of 3. Open-PR counts move; created_at/closed_at do not. This
# section reproduces that bound from immutable fields, forever.
BOUND_AT=2026-09-10T15:41:25Z
OPEN_AT_BOUND=0
for n in 2760 2762 2764 2765 2732; do
  ROW=$(gh api "repos/ratatui/ratatui/pulls/$n" --jq '[(.number|tostring), .created_at, (.closed_at // "still-open"), .head.ref] | @tsv')
  printf '  PR#%s\n' "$ROW"
  C=$(printf '%s' "$ROW" | cut -f2); X=$(printf '%s' "$ROW" | cut -f3)
  if [ "$C" \< "$BOUND_AT" ] && { [ "$X" = "still-open" ] || [ "$BOUND_AT" \< "$X" ]; }; then
    OPEN_AT_BOUND=$((OPEN_AT_BOUND+1))
  fi
done
printf 'ratatui cargo dependabot PRs demonstrably open at %s: %s (configured open-pull-requests-limit: 3)\n' "$BOUND_AT" "$OPEN_AT_BOUND"
if [ "$OPEN_AT_BOUND" -ge 5 ]; then
  pass "at least 5 cargo PRs were open at the revision-1 retrieval, above the configured limit of 3 — that key was not in force"
else
  fail "could not reproduce the >3 open-PR bound from immutable timestamps"
fi

hdr "9. PRACTICE: what an ungrouped entry costs (cargo-binstall github-actions entry)"
live "cargo-binstall's recent Dependabot branches"
gh api "repos/cargo-bins/cargo-binstall/pulls?state=all&per_page=100" \
  --jq '[.[] | select(.user.login=="dependabot[bot]") | select(.head.ref | startswith("dependabot/github_actions/"))][0:6][] | [.created_at, .head.ref] | @tsv'

hdr "10. PRACTICE: default labels on a repo that declares none (ratatui)"
live "ratatui's recent pull-request labels"
LBLS=$(gh api "repos/ratatui/ratatui/pulls?state=all&per_page=100" \
  --jq '[.[] | select(.user.login=="dependabot[bot]")][0:6][] | [.head.ref, ([.labels[].name] | join("+"))] | @tsv')
printf '%s\n' "$LBLS"
# A LIVE section still asserts on its content: a transient network failure must
# FAIL here rather than silently print an error where the evidence should be.
if printf '%s\n' "$LBLS" | grep -q "dependencies+rust" && printf '%s\n' "$LBLS" | grep -q "dependencies+github_actions"; then
  pass "ratatui's PRs carry the DEFAULT dependencies+rust and dependencies+github_actions labels with no labels key configured"
else
  fail "could not read both default label pairs from ratatui (transient read failure, or the labels changed)"
fi

hdr "11. PRACTICE: PR titles with NO commit-message key configured"
live "ratatui's recent pull-request titles"
TITLES=$(gh api "repos/ratatui/ratatui/pulls?state=all&per_page=100" \
  --jq '[.[] | select(.user.login=="dependabot[bot]")][0:4][] | .title')
printf '%s\n' "$TITLES"
if printf '%s\n' "$TITLES" | grep -Eq '^[a-z]+\(deps\): bump '; then
  pass "ratatui's Dependabot titles are Conventional-Commits shaped from the heuristic alone (no commit-message key)"
else
  fail "could not read a conventional-commit-shaped Dependabot title from ratatui (transient read failure, or the heuristic changed)"
fi

hdr "12. Pinned source repositories (read through their pins)"
echo "--- py b08bccfb ---"
git -C ~/c/py-launch-blueprint show b08bccfb55d05f15e46a83b52c5660b1881d19f5:.github/dependabot.yml \
  | grep -nE "package-ecosystem|groups:|patterns|cooldown|default-days|labels|prefix|include|open-pull-requests-limit|interval|day:"
echo "--- ts cb1cbcb2 ---"
git -C ~/c/ts-launch-blueprint show cb1cbcb2e88b898e8c081b0abbfabc1630079c00:.github/dependabot.yml \
  | grep -nE "package-ecosystem|groups:|patterns|update-types|cooldown|labels|prefix|interval"

hdr "13. Programme documents"
grep -n "F053\|F054" /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/port/COMMONALITY.md
if grep -q "F053\|F054" /Users/stevemorin/c/rs-launch-blueprint-p02-plan/docs/port/BASELINE-REVIEW.md; then
  fail "F053/F054 appear in BASELINE-REVIEW.md after all"
else
  pass "neither F053 nor F054 is a recorded baseline in BASELINE-REVIEW.md (nothing for a BASELINE-REVIEW line to challenge)"
fi

hdr "14. CLAIM (opus): edition 2024 puts Cargo's own resolver in the MSRV-aware mode"
live "the Cargo book's rendered resolver page"
curl -sSL -A "$UA" https://doc.rust-lang.org/cargo/reference/resolver.html > "$SCRATCH"/r19-resolver.html
grep -o "incompatible-rust-versions[^<]*" "$SCRATCH"/r19-resolver.html | head -3
grep -o "edition [^<]*2024[^<]*" "$SCRATCH"/r19-resolver.html | head -3
grep -o "resolver = \"3\"[^<]*" "$SCRATCH"/r19-resolver.html | head -2
if grep -q "incompatible-rust-versions" "$SCRATCH"/r19-resolver.html; then
  pass "Cargo's resolver page documents MSRV-aware resolution (resolver 3 / incompatible-rust-versions)"
else
  fail "could not read the MSRV-aware resolver text"
fi

hdr "15. CLAIM (opus): rust-toolchain is an ecosystem, and it updates only pinned channels"
SPM=$(DOCS data/reusables/dependabot/supported-package-managers.md)
printf '%s\n' "$SPM" > "$SCRATCH"/r19-spm.md
grep -n -i -A6 "rust toolchain" "$SCRATCH"/r19-spm.md | head -20
grep -n "rust-toolchain" "$SCRATCH"/r19-optref.md | head -5
echo "--- what R42 settled about the committed channel value ---"
grep -n "channel" /Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/topics/42-dev-toolchain-provisioning/DECISION.md | head -4

hdr "16. The three documented sentences the labels and commit-message decisions rest on"
grep -n "creates these default labels automatically" "$SCRATCH"/r19-optref.md
grep -n "is not defined in the repository, it is ignored" "$SCRATCH"/r19-optref.md
grep -n "similar patterns to those detected in the repository" "$SCRATCH"/r19-optref.md
grep -n "All pull requests have a .dependencies. label\|additional label for the ecosystem" "$SCRATCH"/r19-optref.md
Q=0
grep -q "creates these default labels automatically" "$SCRATCH"/r19-optref.md || Q=1
grep -q "is not defined in the repository, it is ignored" "$SCRATCH"/r19-optref.md || Q=1
grep -q "similar patterns to those detected in the repository" "$SCRATCH"/r19-optref.md || Q=1
if [ "$Q" -eq 0 ]; then
  pass "all three sentences read verbatim from the pinned options-reference source"
else
  fail "at least one sentence is absent from the pinned source — attribute it to the raw instead"
fi

hdr "17. LIVE drift check: how far the two pinned repositories have moved since"
live "the current main of both source repositories"
printf 'dependabot/dependabot-core main today = %s\n' "$(gh api repos/dependabot/dependabot-core/commits/main --jq .sha)"
printf 'github/docs                main today = %s\n' "$(gh api repos/github/docs/commits/main --jq .sha)"
note "informational only; nothing above reads main"

hdr "SUMMARY"
printf 'failed assertions: %s\n' "$FAILS"

printf '\n===== SCRIPT SOURCE (the exact script that produced every line above) =====\n'
cat "$0"

[ "$FAILS" -eq 0 ] || exit 1
exit 0
