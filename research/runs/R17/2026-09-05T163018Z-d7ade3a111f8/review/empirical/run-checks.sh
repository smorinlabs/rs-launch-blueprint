#!/usr/bin/env bash
# R17 secret-scanning-ci-workflow — empirical verification of the raw reports' claims.
# This script VERIFIES CLAIMS. It builds no workflow, no template and no repository
# scaffold. Fixtures are two throwaway directories created under $TMPDIR at runtime and
# deleted at the end; the scanner binary is cached outside the run directory.
#
# Synthetic credentials: the fixtures contain deterministically generated, non-live
# strings shaped like a GitHub PAT and an AWS key pair. They are never printed in full —
# scans run with --redact and only summary lines are echoed — so this log carries no
# secret-shaped text of its own.
#
# Usage: bash run-checks.sh    (exit 0 = every assertion held)

set -u
set -o pipefail

PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TS_PIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
PY_REPO="${PY_REPO:-$HOME/c/py-launch-blueprint}"
TS_REPO="${TS_REPO:-$HOME/c/ts-launch-blueprint}"
TH_TAG=v3.95.9            # the TruffleHog action tag py pins
KF_TAG=v2.2.0             # the Kingfisher release under test
GHDOCS_PIN=078b5832caa5cde591c2babb389ef447a0ef66eb   # github/docs, resolved from main 2026-09-12;
                          # pinned because assertions 10h-10i read it, and a docs reorg on a moving
                          # ref would turn them into failures rather than a printed drift
KF_DIR="${KF_DIR:-${TMPDIR:-/tmp}/r17-kingfisher}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/r17-work.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
SKIP=0
say() { printf '\n===== %s =====\n' "$*"; }
assert() { # assert <label> <expected> <actual>
  if [ "$2" = "$3" ]; then printf 'RESULT %s: PASS (expected=%s actual=%s)\n' "$1" "$2" "$3"; PASS=$((PASS+1));
  else printf 'RESULT %s: FAIL (expected=%s actual=%s)\n' "$1" "$2" "$3"; FAIL=$((FAIL+1)); fi
}
skip() { # skip <label> <reason> — never counted as a pass; a check that cannot fail is not evidence
  printf 'RESULT %s: SKIP (%s)\n' "$1" "$2"; SKIP=$((SKIP+1));
}

say "00 toolchain and host"
rustc --version
cargo --version
uname -a
gh --version | head -1
curl --version | head -1
date -u +'UTC now: %Y-%m-%dT%H:%M:%SZ'

say "01 py secret-scan workflow at pin $PY_PIN (read through the pin, not the worktree)"
git -C "$PY_REPO" show "$PY_PIN:.github/workflows/secret-scan.yml"
GUARD_CITED=$(git -C "$PY_REPO" show "$PY_PIN:.github/workflows/secret-scan.yml" \
  | grep -c 'BASE and HEAD commits are')
assert 01a-py-comment-names-the-tool-error 1 "$GUARD_CITED"
TH_PIN_USED=$(git -C "$PY_REPO" show "$PY_PIN:.github/workflows/secret-scan.yml" \
  | grep -c 'trufflesecurity/trufflehog@v3.95.9')
assert 01b-py-pins-trufflehog-v3.95.9 1 "$TH_PIN_USED"

say "02 ts workflow inventory at pin $TS_PIN — no CI-tier secret scanner"
git -C "$TS_REPO" ls-tree -r --name-only "$TS_PIN" .github/workflows/
TS_HITS=0
for f in $(git -C "$TS_REPO" ls-tree -r --name-only "$TS_PIN" .github/workflows/); do
  n=$(git -C "$TS_REPO" show "$TS_PIN:$f" \
      | grep -icE 'trufflehog|gitleaks|kingfisher|detect-secrets|secret-scan' || true)
  TS_HITS=$((TS_HITS + n))
done
assert 02a-ts-has-no-ci-secret-scanner 0 "$TS_HITS"
echo "-- manual-pr-security-scan.yml is an OSV dependency scan, not a secret scanner:"
git -C "$TS_REPO" show "$TS_PIN:.github/workflows/manual-pr-security-scan.yml" \
  | grep -nE 'on:|workflow_dispatch|osv-scanner|environment' | head -8

say "03 TruffleHog action.yml at $TH_TAG — the equal-base/head guard and the container call"
curl -sSL --max-time 60 "https://raw.githubusercontent.com/trufflesecurity/trufflehog/$TH_TAG/action.yml" -o "$WORK/action.yml"
shasum -a 256 "$WORK/action.yml"
echo "-- guard:"
grep -n -A2 'if \[ "\$base_commit" == "\$head_commit" \]' "$WORK/action.yml"
echo "-- the guard is entered only when base or head is non-empty:"
grep -n 'if \[ -n "\$BASE" \] || \[ -n "\$HEAD" \]' "$WORK/action.yml"
echo "-- the action's own else-branch derives the range from the event, incl. the all-zeros first push:"
grep -n -A6 'github.event_name }}" == "push"' "$WORK/action.yml" | head -12
echo "-- terminal command:"
grep -n -A3 'docker run --rm' "$WORK/action.yml"
GUARD=$(grep -c 'BASE and HEAD commits are the same' "$WORK/action.yml")
DOCKER=$(grep -c 'docker run --rm' "$WORK/action.yml")
COMPOSITE=$(grep -c 'using: "composite"' "$WORK/action.yml")
assert 03a-guard-exists-at-tag 1 "$GUARD"
assert 03b-action-shells-out-to-docker 1 "$DOCKER"
assert 03c-action-is-composite-not-container 1 "$COMPOSITE"

say "04 incumbent repository figures (authenticated REST)"
gh api repos/trufflesecurity/trufflehog \
  --jq '{repo:.full_name,stars:.stargazers_count,archived,license:.license.spdx_id,pushed_at}'
gh api repos/trufflesecurity/trufflehog/releases --jq '.[:3][] | "\(.tag_name) \(.published_at)"'
TH_LICENSE=$(gh api repos/trufflesecurity/trufflehog --jq '.license.spdx_id')
assert 04a-trufflehog-cli-license-agpl AGPL-3.0 "$TH_LICENSE"
gh api repos/gitleaks/gitleaks-action \
  --jq '{repo:.full_name,stars:.stargazers_count,license:.license.spdx_id,pushed_at}'
GLA_LICENSE=$(gh api repos/gitleaks/gitleaks-action --jq '.license.spdx_id')
assert 04b-gitleaks-action-license-not-osi NOASSERTION "$GLA_LICENSE"
curl -sSL --max-time 60 https://raw.githubusercontent.com/gitleaks/gitleaks-action/master/README.md \
  | grep -nE 'GITLEAKS_LICENSE \(required|license has changed from MIT' | head -4

say "05 Kingfisher repository, release assets, manifest and its own CI runners"
gh api repos/mongodb/kingfisher \
  --jq '{repo:.full_name,stars:.stargazers_count,archived,license:.license.spdx_id,created_at,pushed_at,language}'
gh api repos/mongodb/kingfisher/releases --jq '.[:4][] | "\(.tag_name) \(.published_at)"'
gh api "repos/mongodb/kingfisher/releases/tags/$KF_TAG" --jq '.assets[] | "\(.name) \(.size)"'
KF_ARCHIVED=$(gh api repos/mongodb/kingfisher --jq '.archived')
KF_LICENSE=$(gh api repos/mongodb/kingfisher --jq '.license.spdx_id')
KF_DARWIN=$(gh api "repos/mongodb/kingfisher/releases/tags/$KF_TAG" --jq '[.assets[].name | select(startswith("kingfisher-darwin"))] | length')
KF_LINUX=$(gh api "repos/mongodb/kingfisher/releases/tags/$KF_TAG" --jq '[.assets[].name | select(startswith("kingfisher-linux"))] | length')
assert 05a-kingfisher-not-archived false "$KF_ARCHIVED"
assert 05b-kingfisher-license-apache Apache-2.0 "$KF_LICENSE"
assert 05c-macos-release-assets-exist 2 "$KF_DARWIN"
assert 05d-linux-release-assets-exist 6 "$KF_LINUX"
echo "-- workspace manifest at $KF_TAG:"
curl -sSL --max-time 60 "https://raw.githubusercontent.com/mongodb/kingfisher/$KF_TAG/Cargo.toml" \
  | sed -n '/\[workspace.package\]/,/^$/p'
echo "-- Kingfisher's own CI runners:"
curl -sSL --max-time 60 "https://raw.githubusercontent.com/mongodb/kingfisher/$KF_TAG/.github/workflows/ci.yml" \
  | grep -nE 'runs-on' | head -6
echo "-- documented exit codes and the --only-valid alias:"
curl -sSL --max-time 60 "https://raw.githubusercontent.com/mongodb/kingfisher/$KF_TAG/docs/USAGE.md" -o "$WORK/USAGE.md"
echo "   docs/USAGE.md at $KF_TAG, sha256: $(shasum -a 256 < "$WORK/USAGE.md")"
# The whole "## Exit Codes" section, not just its heading: the previous range
# expression stopped at the blank line that immediately follows the heading, so the
# table never reached the log. Section 10 asserts on what this prints.
awk '/^## Exit Codes/{f=1} f&&/^## /&&!/^## Exit Codes/{exit} f' "$WORK/USAGE.md" | head -12
grep -n -m2 -- '--only-valid` is a compatibility alias' "$WORK/USAGE.md"

say "06 crates.io trap — 'kingfisher' on crates.io is an unrelated project"
curl -sSL --max-time 60 -H 'User-Agent: rs-launch-blueprint-research (steve@conceptm.com)' \
  https://crates.io/api/v1/crates/kingfisher \
  | python3 -c 'import json,sys;d=json.load(sys.stdin)["crate"];print({k:d.get(k) for k in ["name","newest_version","repository","recent_downloads","downloads"]})' \
  > "$WORK/kf-crate.txt"
cat "$WORK/kf-crate.txt"
CRATE_REPO=$(grep -c 'mongrov/kingfisher' "$WORK/kf-crate.txt")
assert 06a-cratesio-kingfisher-is-a-different-project 1 "$CRATE_REPO"
PUBLISH_FALSE=$(curl -sSL --max-time 60 "https://raw.githubusercontent.com/mongodb/kingfisher/$KF_TAG/Cargo.toml" | grep -c '^publish = false')
assert 06b-mongodb-kingfisher-is-not-published-to-cratesio 1 "$PUBLISH_FALSE"

say "07 download the macOS release, verify its build provenance, run it"
mkdir -p "$KF_DIR"
if [ ! -x "$KF_DIR/kingfisher" ]; then
  curl -sSL --max-time 300 -o "$KF_DIR/kingfisher-darwin-arm64.tgz" \
    "https://github.com/mongodb/kingfisher/releases/download/$KF_TAG/kingfisher-darwin-arm64.tgz"
  tar xzf "$KF_DIR/kingfisher-darwin-arm64.tgz" -C "$KF_DIR"
fi
shasum -a 256 "$KF_DIR/kingfisher-darwin-arm64.tgz"
LOCAL_DIGEST=$(shasum -a 256 "$KF_DIR/kingfisher-darwin-arm64.tgz" | cut -d' ' -f1)
# `gh attestation verify` initialises its Sigstore verifier from TUF trusted-root metadata that it
# refreshes into $XDG_CACHE_HOME/gh/.sigstore (default $HOME/.cache/gh/.sigstore). If that path is
# not writable the verifier cannot be built and gh exits 1 with
# "no valid Sigstore verifiers could be initialized" — before it looks at the artifact at all.
# Revision 1 of this script inherited whatever $HOME the caller had, so the check passed in a
# permissive shell and failed under a sandbox whose writes are confined to the workspace and
# $TMPDIR. The cache is therefore redirected into $WORK, which every such sandbox can write.
# Network egress to api.github.com, tuf-repo-cdn.sigstore.dev and tuf-repo.github.com, and an
# authenticated gh, are still required; 07f below records the failure mode as executed evidence.
GH_SIGSTORE_CACHE="$WORK/gh-cache"
mkdir -p "$GH_SIGSTORE_CACHE"
XDG_CACHE_HOME="$GH_SIGSTORE_CACHE" \
  gh attestation verify "$KF_DIR/kingfisher-darwin-arm64.tgz" --repo mongodb/kingfisher --format json \
  > "$WORK/att.json" 2>"$WORK/att.err"
ATT_EXIT=$?
assert 07a-slsa-provenance-verifies 0 "$ATT_EXIT"
ATT_DIGEST=""; ATT_SIGNER=""
if [ -s "$WORK/att.json" ]; then
  python3 - "$WORK/att.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
c=d[0]["verificationResult"]["signature"]["certificate"]
s=d[0]["verificationResult"]["statement"]["subject"][0]
print("attestations:",len(d))
print("subject:", s["name"], s["digest"])
print({k:c.get(k) for k in ["sourceRepositoryURI","sourceRepositoryDigest","buildSignerURI","runnerEnvironment"]})
PY
  ATT_DIGEST=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))[0]["verificationResult"]["statement"]["subject"][0]["digest"]["sha256"])' "$WORK/att.json")
  ATT_SIGNER=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))[0]["verificationResult"]["signature"]["certificate"]["buildSignerURI"])' "$WORK/att.json")
else
  echo "-- gh produced no attestation JSON; its stderr follows:"
  sed -n '1,10p' "$WORK/att.err"
fi
KF_VERSION=$("$KF_DIR/kingfisher" --version | tr -d '\n')
echo "-- macOS execution: $KF_VERSION"
assert 07b-macos-binary-runs "kingfisher 2.2.0" "$KF_VERSION"
RULE_COUNT=$("$KF_DIR/kingfisher" rules list --format json 2>/dev/null | python3 -c 'import json,sys;print(len(json.load(sys.stdin)))')
echo "-- built-in rules listed: $RULE_COUNT (total rules; the listing exposes no validator flag,"
echo "   so this is NOT comparable to TruffleHog's stated 700+ actively-verifying detectors)"
assert 07c-rules-listed-and-counted 485 "$RULE_COUNT"
assert 07d-attested-subject-digest-equals-the-downloaded-file "$LOCAL_DIGEST" "$ATT_DIGEST"
echo "-- the signer workflow below is READ FROM the certificate, not enforced by the flags used:"
echo "   --repo mongodb/kingfisher constrains the repository identity only; enforcing the workflow"
echo "   path needs --signer-workflow or --cert-identity, which this check does not pass."
assert 07e-signer-workflow-observed-in-certificate \
  "https://github.com/mongodb/kingfisher/.github/workflows/release.yml@refs/heads/main" "$ATT_SIGNER"
echo "-- negative control: the same command with a non-writable Sigstore trusted-root cache."
if [ "$(id -u)" -eq 0 ]; then
  skip 07f-verifier-fails-without-a-writable-sigstore-cache "running as uid 0; mode 0500 does not constrain root, so this control cannot be exercised"
else
  RO_CACHE="$WORK/ro-cache"; mkdir -p "$RO_CACHE"; chmod 500 "$RO_CACHE"
  XDG_CACHE_HOME="$RO_CACHE" \
    gh attestation verify "$KF_DIR/kingfisher-darwin-arm64.tgz" --repo mongodb/kingfisher --format json \
    > "$WORK/att-ro.json" 2>"$WORK/att-ro.err"
  RO_EXIT=$?
  chmod 700 "$RO_CACHE"
  echo "   gh stderr (wording is gh 2.98.0's):"; sed -n '1,3p' "$WORK/att-ro.err"
  RO_MSG=$(grep -c 'no valid Sigstore verifiers could be initialized' "$WORK/att-ro.err")
  assert 07f-verifier-fails-without-a-writable-sigstore-cache "1 1" "$RO_EXIT $RO_MSG"
fi
echo "-- second prerequisite: the command needs an authenticated gh, so P03's install step needs a token."
NOAUTH_HOME="$WORK/noauth-home"; mkdir -p "$NOAUTH_HOME"
env -i PATH="$PATH" HOME="$NOAUTH_HOME" \
  gh attestation verify "$KF_DIR/kingfisher-darwin-arm64.tgz" --repo mongodb/kingfisher --format json \
  > "$WORK/att-noauth.json" 2>"$WORK/att-noauth.err"
NOAUTH_EXIT=$?
echo "   gh stderr (wording is gh 2.98.0's):"; sed -n '1,2p' "$WORK/att-noauth.err"
NOAUTH_MSG=$(grep -c 'gh auth login' "$WORK/att-noauth.err")
assert 07g-verifier-requires-an-authenticated-gh "4 1" "$NOAUTH_EXIT $NOAUTH_MSG"

say "08 verified-only behaviour on non-live, template-shaped credentials (fixture A)"
python3 - "$WORK/fixA" <<'PY'
import os,random,string,sys
d=sys.argv[1]; os.makedirs(d,exist_ok=True)
random.seed(17)
ghp='ghp_'+''.join(random.choice(string.ascii_letters+string.digits) for _ in range(36))
akia='AKIA'+''.join(random.choice(string.ascii_uppercase+string.digits) for _ in range(16))
sk=''.join(random.choice(string.ascii_letters+string.digits+'/+') for _ in range(40))
open(os.path.join(d,'.env.example'),'w').write(
  f"DATABASE_URL=postgres://user:password@localhost:5432/appdb\nAWS_ACCESS_KEY_ID={akia}\nAWS_SECRET_ACCESS_KEY={sk}\nGITHUB_TOKEN={ghp}\n")
print("fixture A written: .env.example with 1 synthetic PAT-shaped value, 1 synthetic AWS key pair,")
print("one localhost postgres URI; values are deterministic, non-live and are not printed here.")
PY
"$KF_DIR/kingfisher" scan "$WORK/fixA" --only-valid --redact --no-update-check \
  --format json --output "$WORK/fixA.json" > "$WORK/fixA.pretty" 2>&1
A_EXIT=$?
grep -E 'Findings|Validations|Rules Applied|Blobs Scanned' "$WORK/fixA.pretty"
python3 - "$WORK/fixA.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
print("json report findings array length:", len(d["findings"]))
print("json summary:", {k:d["metadata"]["summary"][k] for k in
  ["findings","active_findings","successful_validations","failed_validations","rules_applied"]})
PY
A_JSON=$(python3 -c 'import json,sys;print(len(json.load(open(sys.argv[1]))["findings"]))' "$WORK/fixA.json")
assert 08a-only-valid-empties-the-report 0 "$A_JSON"
assert 08b-but-exit-code-is-still-200-not-0 200 "$A_EXIT"
echo "-- same scan, same flags, pretty format instead of json:"
"$KF_DIR/kingfisher" scan "$WORK/fixA" --only-valid --redact --no-update-check \
  > "$WORK/fixA.pretty2" 2>&1
A2_EXIT=$?
grep -E '^ \|Findings|^ \|__Successful|^ \|__Failed' "$WORK/fixA.pretty2"
A2_COUNT=$(grep -cE '^ \|Findings\.+: 1$' "$WORK/fixA.pretty2")
assert 08c-pretty-summary-counts-the-filtered-candidate 1 "$A2_COUNT"
assert 08d-pretty-run-exit-also-200 200 "$A2_EXIT"
echo "   The two formats disagree for one scan: pretty prints the pre-filter count (1),"
echo "   the JSON report prints the post-filter count (0). A gate must read the exit code"
echo "   or the JSON/SARIF findings array, never the pretty summary."

say "09 full-history scanning with no --since-commit (fixture B)"
mkdir -p "$WORK/fixB" && cd "$WORK/fixB" || exit 1
git init -q .
git config user.email r17@example.invalid
git config user.name r17
python3 -c "
import random,string
random.seed(99)
tok='ghp_'+''.join(random.choice(string.ascii_letters+string.digits) for _ in range(36))
open('leak.txt','w').write('token='+tok+'\n')
print('fixture B: one synthetic PAT-shaped value committed then deleted (value not printed)')
"
git add -A && git commit -qm "add synthetic token"
rm leak.txt && git commit -qam "remove synthetic token"
echo "-- working tree after deletion:"; ls -A | grep -v '^\.git$' || echo "(no tracked files remain)"
"$KF_DIR/kingfisher" scan . --redact --no-update-check > "$WORK/fixB.pretty" 2>&1
B_EXIT=$?
grep -E 'Findings|Validations|Blobs Scanned' "$WORK/fixB.pretty"
assert 09a-history-scan-finds-deleted-blob-without-since-commit 200 "$B_EXIT"
B_FIND=$(grep -cE '^ \|Findings\.+: 1$' "$WORK/fixB.pretty")
assert 09b-exactly-one-history-finding 1 "$B_FIND"
cd "$WORK" || exit 1

say "10 the documented exit-code set, and the codes outside it"
# The gate rule this decision states is an allow-list, so two things have to be
# executed rather than asserted: that the documented set is exactly what the decision
# names, and that codes outside it are reachable — which is what makes a gate written
# as "fail on 205" fail open when the scanner never scanned.
KF_CODES=$(awk '/^## Exit Codes/{f=1} f&&/^## /&&!/^## Exit Codes/{exit} f' "$WORK/USAGE.md" \
  | awk -F'|' '/^\| *[0-9]+ *\|/{gsub(/[[:space:]]/,"",$2); printf "%s%s", (n++?" ":""), $2} END{print ""}')
echo "-- documented exit codes, in table order: [$KF_CODES]"
assert 10a-documented-exit-code-set-is-exactly-0-200-205 "0 200 205" "$KF_CODES"
# The other three places the tool could document exit behaviour, checked so the set
# above can be called "the documented set" and not "one table's contents".
KF_HELP_EXIT=$("$KF_DIR/kingfisher" --help 2>&1 | grep -c -i 'exit')
assert 10b-top-level-help-documents-no-exit-code 0 "$KF_HELP_EXIT"
KF_SCANHELP_EXIT=$("$KF_DIR/kingfisher" scan --help 2>&1 | grep -c -i 'exit')
assert 10c-scan-help-documents-no-exit-code 0 "$KF_SCANHELP_EXIT"
curl -sSL --max-time 60 "https://raw.githubusercontent.com/mongodb/kingfisher/$KF_TAG/README.md" -o "$WORK/KF-README.md"
KF_README_EXIT=$(grep -c -i 'exit' "$WORK/KF-README.md")
assert 10d-readme-documents-no-exit-code 0 "$KF_README_EXIT"
# Two reachable tool-error codes. No pipe on the invocation: a pipeline reports its
# last command's status, and these assertions are about the scanner's status.
"$KF_DIR/kingfisher" --definitely-not-a-real-flag > "$WORK/badflag.out" 2>&1
BADFLAG_EXIT=$?
echo "-- rejected flag, first line: $(head -1 "$WORK/badflag.out")"
assert 10e-rejected-flag-exits-2 2 "$BADFLAG_EXIT"
"$KF_DIR/kingfisher" scan no-such-scan-target --no-update-check > "$WORK/badpath.out" 2>&1
BADPATH_EXIT=$?
echo "-- unreadable scan target, last line: $(tail -1 "$WORK/badpath.out")"
assert 10f-unreadable-target-exits-1 1 "$BADPATH_EXIT"
IN_SET=$(printf '%s\n' "$BADFLAG_EXIT" "$BADPATH_EXIT" | grep -c -E '^(0|200|205)$')
assert 10g-neither-tool-error-code-is-in-the-documented-set 0 "$IN_SET"
# Why an implementer handles the code by hand at all: GitHub's default shell for a
# run: step is bash -e, so an uncaptured 200 aborts the step before any handler runs.
# Read at the pinned github/docs commit, and the assertions read the two literal
# command strings, never the surrounding prose or table layout.
curl -sSL --max-time 60 "https://raw.githubusercontent.com/github/docs/$GHDOCS_PIN/data/reusables/actions/supported-shells.md" -o "$WORK/gh-shells.md"
echo "   github/docs at $GHDOCS_PIN, supported-shells.md sha256: $(shasum -a 256 < "$WORK/gh-shells.md")"
GH_DEFAULT_SHELL=$(grep -c -- '`bash -e {0}`' "$WORK/gh-shells.md")
assert 10h-github-default-run-shell-is-bash-dash-e 1 "$GH_DEFAULT_SHELL"
GH_BASH_SHELL=$(grep -c -- '`bash --noprofile --norc -eo pipefail {0}`' "$WORK/gh-shells.md")
assert 10i-explicit-shell-bash-also-sets-errexit 1 "$GH_BASH_SHELL"

say "11 not executed, and why"
cat <<'NOTE'
- Kingfisher exit code 205 ("validated findings discovered") was NOT exercised: proving it needs a
  genuinely live third-party credential, which this research will not create. 205 rests on
  docs/USAGE.md's exit-code table only. P03 must prove it with a throwaway live credential.
- No workflow step was run, so the gate itself is NOT executed here. Section 10 proves the set the
  gate must allow-list and proves two codes outside it, but whether a real scan step fails when the
  scanner cannot run is P03's acceptance check 5 (replace the binary with `false`, or pass a
  rejected flag, and assert the job fails).
- TruffleHog's CLI was NOT downloaded or run. Its exit-183-on-verified behaviour, its 700+
  actively-verifying detector count, and whether `--since-commit` with an empty value consumes the
  following `--branch` flag are all documented-not-executed here.
- No benchmark was reproduced. Every comparative runtime, network-request and binary-size figure in
  the raw reports comes from MongoDB's own docs/COMPARISON.md and stays vendor-authored.
- No workflow file, template or repository scaffold was created by this script.
- Whether `gh attestation verify` succeeds inside a GitHub Actions job was NOT executed: no CI exists
  for this template yet. Section 07 proves the command on a developer machine with a writable
  Sigstore cache, network egress to api.github.com / tuf-repo-cdn.sigstore.dev / tuf-repo.github.com,
  and an authenticated gh (assertions 07f and 07g execute both prerequisites as negative controls),
  so P03's install step needs GH_TOKEN in its environment. Whether a GitHub-hosted runner satisfies
  all three is an acceptance check for P03, not a settled fact here.
NOTE

printf '\nsummary: PASS=%d FAIL=%d SKIP=%d\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ] && { echo "RESULT: PASS"; exit 0; } || { echo "RESULT: FAIL"; exit 1; }
