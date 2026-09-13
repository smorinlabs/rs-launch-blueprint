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
# Resolved here, before any section changes directory: sections 09 and 12 run inside $WORK, which is
# under $TMPDIR and not inside the repository, so section 13 cannot ask git where it is by then.
START_DIR="$(pwd)"
REPO_ROOT="${REPO_ROOT:-$(git -C "$START_DIR" rev-parse --show-toplevel 2>/dev/null || echo /nonexistent)}"
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
bash --version | head -1   # section 12 executes two shells, so the shell's own version is recorded
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
curl -sSL --max-time 60 -H 'User-Agent: rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)' \
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
# Fitness gate 6 wants the size stated: printed, not asserted, because it is a property of the one
# asset this macOS-only script downloads. It is a per-job CI download and never a shipped artifact.
echo "-- release tarball bytes: $(wc -c < "$KF_DIR/kingfisher-darwin-arm64.tgz" | tr -d ' '); unpacked binary bytes: $(wc -c < "$KF_DIR/kingfisher" | tr -d ' ')"
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
# This control has to demonstrate gh REFUSING FOR WANT OF AUTHENTICATION, and a control that exits
# non-zero for some other reason is indistinguishable from it in a summary line. Revision 4's form of
# this check asserted the exit code 4 after invoking whatever `gh` PATH resolved; the audit of that
# revision reran it on a host where `gh` on PATH is a version-manager shim (mise), and the empty
# environment made the shim re-read a configuration it no longer trusts, so it aborted with exit 1
# before the gh CLI started at all — a control failing for the wrong reason, which proves nothing
# about authentication. The control therefore now (1) resolves an executable that IS the gh CLI
# rather than a launcher, (2) asserts that it is the same build the checks above used, and (3)
# asserts the REFUSAL — a failing exit, gh's own `gh auth login` remedy, and no attestation written —
# instead of an exit number that depends on the gh build the host happens to provide. The number is
# then compared against the resolved gh's own documentation rather than against a literal here.
GH_OUTER_V=$(gh --version 2>/dev/null | head -1)
NOAUTH_HOME="$WORK/noauth-home"; mkdir -p "$NOAUTH_HOME"
realpath_of() { python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$1"; }
gh_probe() { env -i PATH="$PATH" HOME="$NOAUTH_HOME" "$1" --version 2>/dev/null | head -1; }
GH_REAL=""; GH_REAL_V=""; GH_LAUNCHER=""; GH_LAUNCHER_V=""
for c in ${GH_BIN:-} /opt/homebrew/bin/gh /usr/local/bin/gh /usr/bin/gh /home/linuxbrew/.linuxbrew/bin/gh "$(command -v gh 2>/dev/null || true)"; do
  { [ -n "$c" ] && [ -x "$c" ]; } || continue
  c_real=$(realpath_of "$c")
  c_v=$(gh_probe "$c")
  case "$c_v" in
    "gh version"*) : ;;
    *) echo "   candidate $c -> $c_real: does not start the gh CLI under an empty environment; skipped"; continue ;;
  esac
  if [ "$(basename "$c_real")" != "gh" ]; then
    echo "   candidate $c -> $c_real: a version-manager launcher rather than the gh binary; kept only as a fallback"
    [ -z "$GH_LAUNCHER" ] && { GH_LAUNCHER="$c"; GH_LAUNCHER_V="$c_v"; }
    continue
  fi
  GH_REAL="$c"; GH_REAL_V="$c_v"; break
done
if [ -z "$GH_REAL" ] && [ -n "$GH_LAUNCHER" ]; then GH_REAL="$GH_LAUNCHER"; GH_REAL_V="$GH_LAUNCHER_V"; fi
echo "   gh first on PATH: $(command -v gh 2>/dev/null || echo none) (reports '$GH_OUTER_V' in the caller's environment)"
if [ -z "$GH_REAL" ]; then
  echo "   no executable on this host starts the gh CLI under an empty environment, so a non-zero exit"
  echo "   here would say nothing about authentication. The prerequisite is unproven on this host and"
  echo "   stands on gh's own documentation (gh help exit-codes) until the control is rerun elsewhere."
  skip 07g-the-control-runs-the-same-gh-build-as-the-checks-above "no gh CLI starts under an empty environment on this host"
  skip 07h-unauthenticated-verify-is-refused-for-want-of-authentication "no gh CLI starts under an empty environment on this host"
  skip 07i-the-refusal-exit-matches-ghs-own-documented-authentication-code "no gh CLI starts under an empty environment on this host"
else
  echo "   gh CLI used for this control: $GH_REAL -> $(realpath_of "$GH_REAL") (reports '$GH_REAL_V')"
  assert 07g-the-control-runs-the-same-gh-build-as-the-checks-above "$GH_OUTER_V" "$GH_REAL_V"
  env -i PATH="$PATH" HOME="$NOAUTH_HOME" \
    "$GH_REAL" attestation verify "$KF_DIR/kingfisher-darwin-arm64.tgz" --repo mongodb/kingfisher --format json \
    > "$WORK/att-noauth.json" 2>"$WORK/att-noauth.err"
  NOAUTH_EXIT=$?
  echo "   gh stderr (wording is gh 2.98.0's):"; sed -n '1,2p' "$WORK/att-noauth.err"
  NOAUTH_MSG=$(grep -c 'gh auth login' "$WORK/att-noauth.err")
  NOAUTH_ATT=$(wc -c < "$WORK/att-noauth.json" | tr -d ' ')
  NOAUTH_FAILED=0; [ "$NOAUTH_EXIT" -ne 0 ] && NOAUTH_FAILED=1
  echo "   refused=$NOAUTH_FAILED (observed exit $NOAUTH_EXIT), 'gh auth login' in stderr=$NOAUTH_MSG, attestation bytes written=$NOAUTH_ATT"
  assert 07h-unauthenticated-verify-is-refused-for-want-of-authentication "1 1 0" "$NOAUTH_FAILED $NOAUTH_MSG $NOAUTH_ATT"
  # The exit NUMBER is read from the resolved gh's own documentation rather than written into this
  # script, so the assertion compares the tool against itself; a gh build that changed the code would
  # move both sides together, and an unreadable topic fails or skips loudly instead of passing on a
  # literal this script remembered.
  DOC_CODE=$(env -i PATH="$PATH" HOME="$NOAUTH_HOME" "$GH_REAL" help exit-codes 2>/dev/null \
    | sed -n 's/.*requires authentication, the exit code will be \([0-9][0-9]*\).*/\1/p' | head -1)
  if [ -z "$DOC_CODE" ]; then
    skip 07i-the-refusal-exit-matches-ghs-own-documented-authentication-code "this gh build ships no 'help exit-codes' topic in the form this check reads"
  else
    echo "   gh help exit-codes documents $DOC_CODE for a command that requires authentication"
    assert 07i-the-refusal-exit-matches-ghs-own-documented-authentication-code "$DOC_CODE" "$NOAUTH_EXIT"
  fi
fi

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
- Section 12 is NOT a GitHub Actions job either, and it creates no workflow file. It runs the two
  shell command lines that github/docs documents for a `run:` step, at the pinned commit, over a
  three-line script that is the literal implementation of this decision's gate rule. What it
  establishes is a property of those shells, executed locally; what it does not establish is how a
  hosted runner behaves, which stays P03's acceptance check 5.
- Section 13 asserts on this decision's own text, not on any external source. It compares named
  lines of revision 4 against revision 2 read out of git history, so it records which approved
  wording this revision preserved and which it changed. It proves nothing about the scanner.
- TruffleHog's CLI was NOT downloaded or run. Its exit-183-on-verified behaviour, its 700+
  actively-verifying detector count, and whether `--since-commit` with an empty value consumes the
  following `--branch` flag are all documented-not-executed here.
- No benchmark was reproduced. Every comparative runtime, network-request and binary-size figure in
  the raw reports comes from MongoDB's own docs/COMPARISON.md and stays vendor-authored.
- No workflow file, template or repository scaffold was created by this script.
- Whether `gh attestation verify` succeeds inside a GitHub Actions job was NOT executed: no CI exists
  for this template yet. Section 07 proves the command on a developer machine with a writable
  Sigstore cache, network egress to api.github.com / tuf-repo-cdn.sigstore.dev / tuf-repo.github.com,
  and an authenticated gh (07f executes the cache prerequisite as a negative control, and 07g-07i
  execute the authentication one), so P03's install step needs GH_TOKEN in its environment. Whether
  a GitHub-hosted runner satisfies all three is an acceptance check for P03, not a settled fact here.
NOTE

say "12 the gate rule's shell dependency — an executed fail-open, and the two shells that decide it"
# Section 10 showed that exit codes outside the documented set are reachable. This section shows
# something narrower and more dangerous: "capture the exit code, then allow-list it" is NOT safe on
# its own. GitHub's DEFAULT run: shell is `bash -e {0}` (10h) and carries no pipefail, so when the
# scanner is the non-final element of a pipeline — teeing the scan to a step log, or piping the
# report to jq, both ordinary things to write — the captured status is the LAST command's, which is
# 0. The allow-list then PASSES the job although the scanner never ran. The explicit `shell: bash`
# form (10i) carries pipefail and does not. The two shell command lines below are extracted from the
# pinned github/docs file fetched in section 10, not typed from memory.
DEF_SHELL=$(grep -o -- '`bash -e {0}`' "$WORK/gh-shells.md" | head -1 | tr -d '`' | sed 's/ {0}//')
PF_SHELL=$(grep -o -- '`bash --noprofile --norc -eo pipefail {0}`' "$WORK/gh-shells.md" | head -1 | tr -d '`' | sed 's/ {0}//')
echo "-- default run: shell, argv from the pinned docs: [$DEF_SHELL]"
echo "-- explicit 'shell: bash', argv from the pinned docs: [$PF_SHELL]"
assert 12a-default-shell-argv-read-from-the-pinned-docs "bash -e" "$DEF_SHELL"
assert 12b-explicit-shell-bash-argv-read-from-the-pinned-docs "bash --noprofile --norc -eo pipefail" "$PF_SHELL"
mkdir -p "$WORK/fix12"      # an empty directory: nothing real is ever scanned by this section
# The gate exactly as this decision states it, as a workflow step's script would be written.
cat > "$WORK/gate-piped.sh" <<'GATE'
rc=0
"$SCANNER" $SCAN_ARGS 2>&1 | tee "$STEPLOG" || rc=$?
echo "$rc" > "$RCFILE"
case "$rc" in
  0|200) echo "gate verdict: PASS the job (captured rc=$rc)"; exit 0 ;;
  205)   echo "gate verdict: FAIL the job, validated finding (captured rc=$rc)"; exit 1 ;;
  *)     echo "gate verdict: FAIL the job, tool error (captured rc=$rc)"; exit 1 ;;
esac
GATE
# The same gate with no pipeline, so the pipeline is isolated as the mechanism rather than assumed.
sed 's#2>&1 | tee "$STEPLOG"#> "$STEPLOG" 2>\&1#' "$WORK/gate-piped.sh" > "$WORK/gate-nopipe.sh"
echo "-- the scan line, piped form:  $(grep 'SCAN_ARGS' "$WORK/gate-piped.sh")"
echo "-- the scan line, no pipeline: $(grep 'SCAN_ARGS' "$WORK/gate-nopipe.sh")"
gate_run() { # gate_run <gate-file> <scanner> <args> <shell-words...>
  local gate="$1" scanner="$2" args="$3" tail_line
  shift 3
  rm -f "$WORK/step12.rc"
  SCANNER="$scanner" SCAN_ARGS="$args" STEPLOG="$WORK/step12.log" RCFILE="$WORK/step12.rc" \
    "$@" "$WORK/$gate" > "$WORK/step12.out" 2>&1
  GATE_STEP_EXIT=$?
  if [ -f "$WORK/step12.rc" ]; then GATE_RC=$(cat "$WORK/step12.rc"); else GATE_RC="not-reached"; fi
  tail_line=$(tail -1 "$WORK/step12.out")
  printf '   %-14s scanner=%-22s shell=[%s]\n      -> captured rc=%s, step exit=%s  |  %s\n' \
    "$gate" "$(basename "$scanner")" "$*" "$GATE_RC" "$GATE_STEP_EXIT" "$tail_line"
}
MISSING_SCANNER="$WORK/no-such-kingfisher-binary"   # deliberately absent: the scanner cannot run
echo "-- case 1: the scanner is the real binary but the flag is rejected (exit 2, proven in 10e)."
gate_run gate-piped.sh "$KF_DIR/kingfisher" "--definitely-not-a-real-flag" $DEF_SHELL
assert 12c-default-shell-piped-rejected-flag-PASSES-THE-JOB "0 0" "$GATE_RC $GATE_STEP_EXIT"
gate_run gate-piped.sh "$KF_DIR/kingfisher" "--definitely-not-a-real-flag" $PF_SHELL
assert 12d-pipefail-shell-piped-rejected-flag-fails-the-job "2 1" "$GATE_RC $GATE_STEP_EXIT"
gate_run gate-nopipe.sh "$KF_DIR/kingfisher" "--definitely-not-a-real-flag" $DEF_SHELL
assert 12e-default-shell-unpiped-rejected-flag-fails-the-job "2 1" "$GATE_RC $GATE_STEP_EXIT"
echo "-- case 2: the scanner binary is absent altogether, which is what a failed install leaves."
echo "   The captured value itself is shell-dependent (bash 3.2 under errexit reports 1 for an"
echo "   absent path where a plain shell reports 127), so only the job verdict is asserted."
gate_run gate-piped.sh "$MISSING_SCANNER" "scan $WORK/fix12" $DEF_SHELL
assert 12f-default-shell-piped-missing-binary-PASSES-THE-JOB 0 "$GATE_STEP_EXIT"
gate_run gate-piped.sh "$MISSING_SCANNER" "scan $WORK/fix12" $PF_SHELL
assert 12g-pipefail-shell-piped-missing-binary-fails-the-job 1 "$GATE_STEP_EXIT"
gate_run gate-nopipe.sh "$MISSING_SCANNER" "scan $WORK/fix12" $DEF_SHELL
assert 12h-default-shell-unpiped-missing-binary-fails-the-job 1 "$GATE_STEP_EXIT"
echo "   Read together: the allow-list is only as good as the status it is handed. Under the"
echo "   default shell a pipeline hands it the wrong status and the security gate passes a job in"
echo "   which no scan ran. The rule therefore has to fix the step's shell and forbid an unguarded"
echo "   pipeline around the scanner, not merely enumerate the scanner's codes."

say "13 which approved wording this revision preserved, and which it changed"
# Revision 3 claimed a set of already-approved regions stood "as revision 2 wrote them" and that was
# false for three of them; the audit rejected it on exactly that. This section stops the claim being
# a matter of assertion: it reads revision 2 out of git, checks that it is the revision the audit
# named by digest, and compares named anchor lines in both directions — regions claimed unchanged
# must be byte-identical, and regions this revision rewrote must NOT be.
REV2_COMMIT=ed16bef14a4dd9cd5adb05cc969a9162f6bfb48a
REV2_SHA_EXPECTED=e2c3d588eaf1a098027b4c9ced4fa01ef1341fd27ef4cfdfa012bfc44a8321ec
RUN_REL="research/runs/R17/2026-09-05T163018Z-d7ade3a111f8"
DEC_NOW="$REPO_ROOT/$RUN_REL/review/DECISION.md"   # $REPO_ROOT was resolved at the top, before any cd
git -C "$REPO_ROOT" show "$REV2_COMMIT:$RUN_REL/review/DECISION.md" > "$WORK/rev2-DECISION.md" 2>"$WORK/rev2.err" \
  || { echo "-- git show failed:"; sed -n '1,3p' "$WORK/rev2.err"; : > "$WORK/rev2-DECISION.md"; }
REV2_SHA=$(shasum -a 256 < "$WORK/rev2-DECISION.md" | cut -d' ' -f1)
echo "-- repo root: $REPO_ROOT"
echo "-- revision 2 read from $REV2_COMMIT, sha256: $REV2_SHA"
echo "-- revision under review: $DEC_NOW, sha256 of its current bytes is NOT asserted here (this"
echo "   section runs while that file is being written); the anchor lines below are."
assert 13a-revision-2-is-the-decision-the-audit-named "$REV2_SHA_EXPECTED" "$REV2_SHA"
anchor_line() { awk -v p="$2" 'index($0,p)==1 {print; exit}' "$1"; }
cmp_anchor() { # cmp_anchor <label> <same|differ> <literal line prefix>
  local a b ha hb verdict
  a=$(anchor_line "$WORK/rev2-DECISION.md" "$3")
  b=$(anchor_line "$DEC_NOW" "$3")
  if [ -z "$a" ] || [ -z "$b" ]; then
    assert "$1" "$2" "anchor-not-found(rev2=${#a}B now=${#b}B)"; return
  fi
  ha=$(printf '%s' "$a" | shasum -a 256 | cut -c1-12)
  hb=$(printf '%s' "$b" | shasum -a 256 | cut -c1-12)
  if [ "$ha" = "$hb" ]; then verdict=same; else verdict=differ; fi
  printf '   rev2=%s now=%s %-7s %s\n' "$ha" "$hb" "$verdict" "$3"
  assert "$1" "$2" "$verdict"
}
cmp_anchor 13b-part-1-recommendation-byte-identical            same   '**Part 1 — keep a dedicated'
cmp_anchor 13c-f050-ledger-row-byte-identical                  same   '| F050 — Dedicated secret-scanning CI workflow'
cmp_anchor 13d-baseline-review-f050-byte-identical             same   'BASELINE-REVIEW: F050'
cmp_anchor 13e-equal-base-and-head-narrowing-byte-identical    same   '**The py split, verified at the pinned tag'
cmp_anchor 13f-equal-base-and-head-consequence-byte-identical  same   'What this changes about the item'
cmp_anchor 13g-provenance-advantage-byte-identical             same   '**Shape C'
cmp_anchor 13h-provenance-diagnosis-rewritten                  differ '**The command is environment-dependent'
cmp_anchor 13i-assumes-msrv-policy-byte-identical              same   '- assumes msrv-policy = '
cmp_anchor 13j-assumes-rust-edition-byte-identical             same   '- assumes rust-edition = '
cmp_anchor 13k-assumes-target-os-matrix-byte-identical         same   '- assumes target-os-matrix = '
cmp_anchor 13l-assumes-license-byte-identical                  same   '- assumes license = '
cmp_anchor 13m-part-2-recommendation-rewritten                 differ '**Part 2 — implement it with the Kingfisher CLI'
cmp_anchor 13n-ranked-runner-up-rewritten                      differ 'The ranked runner-up is the **TruffleHog OSS CLI'
cmp_anchor 13o-validity-filter-finding-rewritten               differ '**The finding that changes the design.**'
echo "   Four rows are asserted to differ: the three the revision-3 audit named, and the provenance"
echo "   diagnosis, which revision 5 rewrote because its unauthenticated-prerequisite sentence"
echo "   carried the environment-dependent exit code that revision's audit rejected. They are"
echo "   asserted to differ rather than merely allowed to, so this section fails if a later revision"
echo "   quietly reverts them or if the claim about them is restated as preservation."

printf '\nsummary: PASS=%d FAIL=%d SKIP=%d\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ] && { echo "RESULT: PASS"; exit 0; } || { echo "RESULT: FAIL"; exit 1; }
