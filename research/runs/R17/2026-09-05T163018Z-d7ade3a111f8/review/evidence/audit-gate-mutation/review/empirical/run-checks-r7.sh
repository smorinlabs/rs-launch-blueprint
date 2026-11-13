#!/usr/bin/env bash
# R17 secret-scanning-ci-workflow — empirical verification for revision 7 (the owner's ruling W0-R17b).
# This script VERIFIES CLAIMS. It builds no workflow, no template and no repository scaffold.
# Fixtures are throwaway directories created under $TMPDIR at runtime and deleted at the end;
# the scanner binary and the one public test corpus are cached outside the run directory.
#
# Revision 6's script (run-checks-r6.sh) and its four logs are UNTOUCHED and remain revision 6's
# record. This is a new file because the owner's ruling changed the recommended tool: the checks
# below are about the TruffleHog OSS CLI at $TH_CLI_TAG, not about Kingfisher.
#
# Synthetic credentials: the fixtures contain deterministically generated, NON-LIVE strings shaped
# like a GitHub PAT and an AWS key pair. TruffleHog has no --redact flag (section 08 executes that),
# so no scanner output is ever echoed into this log: section 08 prints OCCURRENCE COUNTS of the
# fixture's own bytes in each output format and never the output itself. Section 09 scans
# trufflesecurity/test_keys, TruffleHog's own published test corpus, which contains a credential the
# vendor intends to be verifiable; only the detector names, the verified COUNT and the exit code are
# printed — never a result's Raw/RawV2 field.
#
# ---------------------------------------------------------------------------------------------
# EVERY ENVIRONMENTAL DEPENDENCY THIS SCRIPT HAS, DECLARED HERE AND PROBED IN SECTION 00.
# Revision 5 of this item's check was rejected because two dependencies were ambient (the caller's
# $HOME and whatever `gh` login the caller held). Nothing below is read from the caller implicitly.
# Each dependency is probed, printed, and either exercised or SKIPped by name — never silently passed.
#
#   HOME              NOT USED. This script exports HOME=$WORK/home, a fresh empty directory under
#                     $TMPDIR, before any check runs. The caller's HOME is printed and never read.
#   PY_REPO           Declared input. Path to a py-launch-blueprint clone containing commit $PY_PIN.
#                     Absent  -> section 01 SKIPs by name. There is no $HOME-derived default.
#   TS_REPO           Declared input. Path to a ts-launch-blueprint clone containing commit $TS_PIN.
#                     Absent  -> section 02 SKIPs by name. There is no $HOME-derived default.
#   R17_GH_TOKEN      Declared input (falls back to GH_TOKEN, then GITHUB_TOKEN). A GitHub API
#   / GH_TOKEN        token. Supplied -> the REST transport is authenticated and 04g (the executed
#   / GITHUB_TOKEN    statement that TruffleHog publishes NO GitHub build attestation) can run.
#                     Absent -> the transport is anonymous (60 requests/hour) and 04g SKIPs by name.
#                     Section 00 asserts which branch is in force, so an ambient login cannot turn a
#                     control into a pass. The token is never printed.
#   network egress    api.github.com, raw.githubusercontent.com, github.com release downloads,
#                     static.rust-lang.org (section 12), and the credential issuers TruffleHog's
#                     verifiers call. The issuer calls are NOT confined to section 09: every scan
#                     run without --no-verification attempts live validation, so section 07's
#                     fixtures reach the issuers for the synthetic AWS and GitHub values too (they
#                     are not live, so nothing verifies and the report stays empty). Section 09 is
#                     only where a verification is EXPECTED to succeed. Probed once; absent ->
#                     every network section SKIPs by name.
#   a gh CLI binary   Resolved by probing candidates under this script's own empty environment and
#                     keeping only one whose realpath is named `gh` and whose --version begins
#                     "gh version". A version-manager shim (mise/asdf/rtx) is rejected rather than
#                     used as a fallback. Override with GH_BIN. Unresolved -> 04g SKIPs by name.
#   openssl           Needed by 04b-04f, which read the Sigstore certificate that signs TruffleHog's
#                     checksums file and verify the signature over it. Resolved by probing; absent
#                     -> those five assertions SKIP by name.
#   cosign            NOT required and NOT assumed. Full Sigstore verification (certificate chain to
#                     the Sigstore root plus Rekor transparency-log inclusion) needs cosign, which
#                     this host does not carry; 04h records that as a SKIP with the exact command
#                     P03 should run, never as a pass.
#   Darwin arm64      Sections that EXECUTE the downloaded macOS binary (05, 06e, 07, 08, 09) need
#                     `uname -s` = Darwin and `uname -m` = arm64. Other platforms SKIP those by
#                     name; every other section still runs.
#   .git history      NEEDED BY EXACTLY ONE ASSERTION, 13q, which checks the carried revision-2 copy
#                     against git history. Section 13's other assertions read the carried copy and
#                     this decision by path and need no repository, so a clean `git archive HEAD`
#                     extraction runs the whole of section 13 except 13q, which SKIPs by name.
#   /usr/bin/grep     Every count below is produced by /usr/bin/grep by absolute path, named in
#                     section 00 and beside each printed count. A typed `grep` in an agent shell
#                     can be ugrep, which honours .gitignore and would silently undercount.
#   helper toolchain  python3, curl, git, tar, shasum, awk and sed are each resolved by PROBING
#                     candidates and keeping the first that actually performs a small operation,
#                     because a version-manager shim standing first on PATH fails under this
#                     script's own empty $HOME and would take every parse and count down with it.
#                     00c asserts that the five without which nothing can run resolved.
#
# Two rerun modes, both recorded in the decision:
#   repository : cd <repo>/research/runs/R17/<run>/review/empirical && \
#                GH_TOKEN=<token> PY_REPO=<path> TS_REPO=<path> bash run-checks-r7.sh
#   clean copy : git archive --format=tar HEAD | tar -xf - -C <dir> && \
#                cd <dir>/research/runs/R17/<run>/review/empirical && bash run-checks-r7.sh
#                (adding the declared inputs above runs the identical set bar 13q)
#
# Usage: bash run-checks-r7.sh    (exit 0 = no assertion FAILed; SKIPs are printed by name)
# ---------------------------------------------------------------------------------------------

set -u
set -o pipefail

GREP=/usr/bin/grep        # absolute path on purpose: see the declaration block above

PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TS_PIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
TH_ACTION_TAG=v3.95.9     # the TruffleHog ACTION tag py pins
TH_CLI_TAG=v3.97.4        # the TruffleHog OSS CLI release under test (in >= 3.97.0, < 4.0.0)
TH_VER=3.97.4
KF_TAG=v2.2.0             # the Kingfisher release: the ranked runner-up's pin, printed in section 00
                          # for the record and NOT exercised anywhere in this script — revision 6's
                          # run-checks-r6.sh is where every Kingfisher assertion lives, and this
                          # revision cites that script's log for them rather than re-running them
GLA_PIN=bcfb9cce635345aac9996cedc19b2de8e01b894f   # gitleaks/gitleaks-action, resolved from master
                          # 2026-09-15 and pinned, because section 11 READS this file: on a moving
                          # ref a README reorganisation would turn 11a into a failure rather than a
                          # printed drift, and round 6's finding F2 was precisely a pattern that
                          # never matched the file it claimed to read.
UA='User-Agent: rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'

# --- declared inputs, captured BEFORE HOME is replaced -----------------------------------------
CALLER_HOME="${HOME:-unset}"
PY_REPO_IN="${PY_REPO:-}"          # no $HOME default: an undeclared repository is a SKIP, not a pass
TS_REPO_IN="${TS_REPO:-}"
GH_TOKEN_IN="${R17_GH_TOKEN:-${GH_TOKEN:-${GITHUB_TOKEN:-}}}"
GH_BIN_IN="${GH_BIN:-}"
TH_DIR="${TH_DIR:-${TMPDIR:-/tmp}/r17-trufflehog}"
TK_DIR="${TK_DIR:-${TMPDIR:-/tmp}/r17-test-keys}"

# --- paths resolved from this script's own location, never from git ----------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEC_NOW="${DEC_NOW:-$RUN_DIR/DECISION.md}"
REV2_FILE="${REV2_FILE:-$SCRIPT_DIR/rev2-DECISION.md}"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/r17-work-r7.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/home"
export HOME="$WORK/home"           # the caller's HOME is never read by anything below
unset XDG_CACHE_HOME XDG_CONFIG_HOME 2>/dev/null || true

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

# --- the helper toolchain, resolved explicitly rather than taken from PATH ----------------------
tool_ok() { # tool_ok <path> <tool name>
  case "$2" in
    python3) [ "$("$1" -c 'print(7*6)' 2>/dev/null)" = 42 ] ;;
    curl|git|tar|shasum) "$1" --version >/dev/null 2>&1 ;;
    openssl) "$1" version >/dev/null 2>&1 ;;
    awk)     [ "$(echo | "$1" '{print 42}' 2>/dev/null)" = 42 ] ;;
    sed)     [ "$(echo x | "$1" 's/x/42/' 2>/dev/null)" = 42 ] ;;
    *)       return 1 ;;
  esac
}
resolve_tool() { # resolve_tool <name> — echoes the first working candidate, or nothing
  local n="$1" c
  for c in "$(command -v "$n" 2>/dev/null || true)" /opt/homebrew/bin/"$n" /usr/local/bin/"$n" /usr/bin/"$n" /bin/"$n"; do
    { [ -n "$c" ] && [ -x "$c" ]; } || continue
    if tool_ok "$c" "$n"; then printf '%s\n' "$c"; return 0; fi
  done
  return 1
}
PY3=$(resolve_tool python3 || true)
CURL=$(resolve_tool curl || true)
GIT_BIN=$(resolve_tool git || true)
TAR=$(resolve_tool tar || true)
SHASUM=$(resolve_tool shasum || true)
AWK=$(resolve_tool awk || true)
SED=$(resolve_tool sed || true)
OPENSSL=$(resolve_tool openssl || true)
COSIGN=$(command -v cosign 2>/dev/null || true)

say "00 declared inputs, environment probes, and the toolchain"
echo "-- counting binary for every count below: $GREP ($("$GREP" --version 2>/dev/null | head -1))"
echo "-- helper toolchain resolved by probing each candidate, not by PATH order alone:"
printf '   python3=%s curl=%s git=%s tar=%s shasum=%s awk=%s sed=%s openssl=%s cosign=%s\n' \
  "${PY3:-none}" "${CURL:-none}" "${GIT_BIN:-none}" "${TAR:-none}" "${SHASUM:-none}" \
  "${AWK:-none}" "${SED:-none}" "${OPENSSL:-none}" "${COSIGN:-none}"
report_bypass() { # report_bypass <name> <resolved path> — prints when PATH order was overruled
  local first; first=$(command -v "$1" 2>/dev/null || echo none)
  if [ "$first" != none ] && [ "$first" != "${2:-}" ]; then
    echo "   $1 first on PATH was BYPASSED: $first (it failed this script's probe for $1 under the empty HOME in force)"
  fi
}
report_bypass python3 "$PY3"; report_bypass curl "$CURL"; report_bypass git "$GIT_BIN"
report_bypass tar "$TAR"; report_bypass shasum "$SHASUM"; report_bypass awk "$AWK"
report_bypass sed "$SED"; report_bypass openssl "$OPENSSL"
RESOLVED=""
for t in "$PY3" "$CURL" "$SHASUM" "$AWK" "$SED"; do [ -n "$t" ] && RESOLVED="$RESOLVED$(basename "$t") "; done
assert 00c-the-helper-toolchain-this-script-cannot-run-without-resolved "python3 curl shasum awk sed " "$RESOLVED"
echo "-- caller HOME (recorded, NOT used): $CALLER_HOME"
echo "-- HOME used by this run: $HOME"
HOME_UNDER_WORK=0; case "$HOME" in "$WORK"/*) HOME_UNDER_WORK=1 ;; esac
HOME_ENTRIES=$(find "$HOME" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
assert 00a-home-is-this-scripts-own-empty-scratch-directory "1 0" "$HOME_UNDER_WORK $HOME_ENTRIES"

UNAME_S=$(uname -s); UNAME_M=$(uname -m)
TH_PLATFORM=no; [ "$UNAME_S" = Darwin ] && [ "$UNAME_M" = arm64 ] && TH_PLATFORM=yes

HAVE_GIT=no
if [ -n "$GIT_BIN" ] && "$GIT_BIN" -C "$SCRIPT_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
  HAVE_GIT=yes
  GIT_ROOT=$("$GIT_BIN" -C "$SCRIPT_DIR" rev-parse --show-toplevel)
else
  GIT_ROOT=none
fi

HAVE_PY=no
if [ -n "$PY_REPO_IN" ] && [ -n "$GIT_BIN" ] && "$GIT_BIN" -C "$PY_REPO_IN" cat-file -e "$PY_PIN^{commit}" 2>/dev/null; then HAVE_PY=yes; fi
HAVE_TS=no
if [ -n "$TS_REPO_IN" ] && [ -n "$GIT_BIN" ] && "$GIT_BIN" -C "$TS_REPO_IN" cat-file -e "$TS_PIN^{commit}" 2>/dev/null; then HAVE_TS=yes; fi

# network + which API transport is in force. /rate_limit's core limit is the discriminator: 60 is
# the anonymous ceiling, anything above it means a credential reached the transport. Asserted, so
# an ambient login cannot go unrecorded.
HAVE_NET=no; GH_AUTH=none; CORE_LIMIT=0; CORE_REMAIN=0
if [ -n "$GH_TOKEN_IN" ] && [ -n "$CURL" ]; then
  "$CURL" -sS --max-time 30 -H "Authorization: Bearer $GH_TOKEN_IN" -H "$UA" \
    https://api.github.com/rate_limit -o "$WORK/rl.json" 2>"$WORK/rl.err" && GH_AUTH=token
fi
if [ "$GH_AUTH" = none ] && [ -n "$CURL" ]; then
  "$CURL" -sS --max-time 30 -H "$UA" https://api.github.com/rate_limit -o "$WORK/rl.json" 2>"$WORK/rl.err" || true
fi
if [ -s "$WORK/rl.json" ]; then
  CORE_LIMIT=$("$PY3" -c 'import json,sys;print(json.load(open(sys.argv[1]))["resources"]["core"]["limit"])' "$WORK/rl.json" 2>/dev/null || echo 0)
  CORE_REMAIN=$("$PY3" -c 'import json,sys;print(json.load(open(sys.argv[1]))["resources"]["core"]["remaining"])' "$WORK/rl.json" 2>/dev/null || echo 0)
  [ "$CORE_LIMIT" -gt 0 ] && HAVE_NET=yes
fi
[ "$HAVE_NET" = yes ] || GH_AUTH=none

# the gh CLI: resolved under this script's own empty environment, launchers rejected outright
realpath_of() { "$PY3" -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$1"; }
gh_probe() { env -i PATH="$PATH" HOME="$WORK/home" "$1" --version 2>/dev/null | head -1; }
GH_REAL=""; GH_REAL_V=""
for c in $GH_BIN_IN /opt/homebrew/bin/gh /usr/local/bin/gh /usr/bin/gh /home/linuxbrew/.linuxbrew/bin/gh "$(command -v gh 2>/dev/null || true)"; do
  { [ -n "$c" ] && [ -x "$c" ]; } || continue
  c_real=$(realpath_of "$c"); c_v=$(gh_probe "$c")
  case "$c_v" in
    "gh version"*) : ;;
    *) echo "   candidate $c -> $c_real: does not start the gh CLI under an empty environment; rejected"; continue ;;
  esac
  if [ "$(basename "$c_real")" != gh ]; then
    echo "   candidate $c -> $c_real: a version-manager launcher rather than the gh binary; rejected"
    continue
  fi
  GH_REAL="$c"; GH_REAL_V="$c_v"; break
done
GH_FIRST=$(command -v gh 2>/dev/null || echo none)
echo "   gh first on PATH: $GH_FIRST; gh CLI used by every gh call below: ${GH_REAL:-none}"
if [ "$GH_FIRST" != none ] && [ "$GH_FIRST" != "${GH_REAL:-}" ]; then
  gf_v=$(gh_probe "$GH_FIRST"); gf_real=$(realpath_of "$GH_FIRST" 2>/dev/null || true)
  case "$gf_v" in
    "gh version"*) gf_cls="starts the gh CLI" ;;
    *)             gf_cls="does NOT start the gh CLI under an empty environment" ;;
  esac
  echo "   the gh first on PATH was BYPASSED: $GH_FIRST -> ${gf_real:-<unresolvable>} ($gf_cls)"
fi

printf -- '-- MODE: PY_REPO=%s TS_REPO=%s token=%s network=%s api-transport=%s gh-cli=%s openssl=%s cosign=%s platform=%s/%s trufflehog-executable=%s git-history=%s\n' \
  "$( [ "$HAVE_PY" = yes ] && echo set || echo unset )" \
  "$( [ "$HAVE_TS" = yes ] && echo set || echo unset )" \
  "$( [ -n "$GH_TOKEN_IN" ] && echo supplied || echo absent )" \
  "$HAVE_NET" "$GH_AUTH" "${GH_REAL:-none}" "${OPENSSL:-none}" "${COSIGN:-none}" \
  "$UNAME_S" "$UNAME_M" "$TH_PLATFORM" "$HAVE_GIT"
echo "   git toplevel: $GIT_ROOT"
echo "   PY_REPO=${PY_REPO_IN:-<undeclared>}  TS_REPO=${TS_REPO_IN:-<undeclared>}"
echo "   decision under review: $DEC_NOW"
echo "   carried revision 2:    $REV2_FILE"
echo "   pins: trufflehog CLI $TH_CLI_TAG (exercised here) · trufflehog action $TH_ACTION_TAG (py's, read at pin) ·"
echo "         kingfisher $KF_TAG (the ranked runner-up: recorded, NOT exercised by this script) ·"
echo "         gitleaks-action README $GLA_PIN · py $PY_PIN · ts $TS_PIN"

if [ "$HAVE_NET" = no ]; then
  skip 00b-the-api-transport-branch-is-asserted "no network egress to api.github.com; every network section SKIPs below"
elif [ "$GH_AUTH" = token ]; then
  LIMIT_CLASS=anonymous; [ "$CORE_LIMIT" -gt 60 ] && LIMIT_CLASS=above-anonymous
  echo "   api.github.com core rate limit: $CORE_LIMIT (remaining $CORE_REMAIN)"
  assert 00b-token-branch-the-declared-token-reached-the-api "token above-anonymous" "$GH_AUTH $LIMIT_CLASS"
else
  echo "   api.github.com core rate limit: $CORE_LIMIT (remaining $CORE_REMAIN)"
  assert 00b-anonymous-branch-no-ambient-credential-reached-the-api "none 60" "$GH_AUTH $CORE_LIMIT"
fi

rustc --version 2>/dev/null || echo "rustc: absent (nothing here compiles)"
cargo --version 2>/dev/null || echo "cargo: absent (nothing here compiles)"
uname -a
bash --version | head -1
if [ -n "$GH_REAL" ]; then echo "gh: $GH_REAL_V ($GH_REAL)"; else echo "gh: no gh CLI resolved"; fi
[ -n "$OPENSSL" ] && "$OPENSSL" version
"$CURL" --version | head -1
"$PY3" --version
date -u +'UTC now: %Y-%m-%dT%H:%M:%SZ'

# --- the GitHub REST transport, declared rather than ambient -----------------------------------
api_fetch() { # api_fetch <path> <outfile>
  if [ "$GH_AUTH" = token ]; then
    "$CURL" -sSL --max-time 60 -H "Authorization: Bearer $GH_TOKEN_IN" \
      -H 'Accept: application/vnd.github+json' -H "$UA" "https://api.github.com/$1" -o "$2"
  else
    "$CURL" -sSL --max-time 60 -H 'Accept: application/vnd.github+json' -H "$UA" \
      "https://api.github.com/$1" -o "$2"
  fi
}
jget() { # jget <file> <dotted key path> — prints JSON scalars in JSON spelling (false, not False)
  "$PY3" - "$1" "$2" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
for k in sys.argv[2].split('.'):
    if d is None: break
    d = d[int(k)] if k.lstrip('-').isdigit() else d.get(k)
print(d if isinstance(d,str) else json.dumps(d))
PY
}

say "01 py runs TruffleHog in CI at pin $PY_PIN — the ground the owner's ruling W0-R17b names"
if [ "$HAVE_PY" = no ]; then
  for l in 01a-py-pins-the-trufflehog-action 01b-py-filters-to-verified-only 01c-py-runs-the-job-on-ubuntu-only; do
    skip "$l" "PY_REPO undeclared or commit $PY_PIN not present there (PY_REPO=${PY_REPO_IN:-<undeclared>})"
  done
else
  "$GIT_BIN" -C "$PY_REPO_IN" show "$PY_PIN:.github/workflows/secret-scan.yml" > "$WORK/py-secret-scan.yml"
  echo "-- py .github/workflows/secret-scan.yml at $PY_PIN, sha256: $("$SHASUM" -a 256 < "$WORK/py-secret-scan.yml")"
  cat "$WORK/py-secret-scan.yml"
  PY_ACTION=$("$GREP" -c "uses: trufflesecurity/trufflehog@$TH_ACTION_TAG" "$WORK/py-secret-scan.yml")
  PY_VERIFIED=$("$GREP" -c -- 'extra_args: --only-verified' "$WORK/py-secret-scan.yml")
  PY_UBUNTU=$("$GREP" -cF "RUNNER_UBUNTU || 'ubuntu-latest'" "$WORK/py-secret-scan.yml")
  PY_MACOS=$("$GREP" -c -i 'macos' "$WORK/py-secret-scan.yml")
  echo "-- counts via $GREP: action=$PY_ACTION only-verified=$PY_VERIFIED ubuntu=$PY_UBUNTU macos=$PY_MACOS"
  assert 01a-py-pins-the-trufflehog-action 1 "$PY_ACTION"
  assert 01b-py-filters-to-verified-only 1 "$PY_VERIFIED"
  assert 01c-py-runs-the-job-on-ubuntu-only "1 0" "$PY_UBUNTU $PY_MACOS"
fi

say "02 ts has no CI-tier secret scanner at pin $TS_PIN — the ruling's other ground"
if [ "$HAVE_TS" = no ]; then
  skip 02a-ts-has-no-secret-scanner-reference "TS_REPO undeclared or commit $TS_PIN not present there (TS_REPO=${TS_REPO_IN:-<undeclared>})"
else
  "$GIT_BIN" -C "$TS_REPO_IN" ls-tree -r --name-only "$TS_PIN" .github/workflows/ > "$WORK/ts-workflows.txt"
  echo "-- ts workflow files at $TS_PIN:"; cat "$WORK/ts-workflows.txt"
  TS_FILES=$(wc -l < "$WORK/ts-workflows.txt" | tr -d ' ')
  : > "$WORK/ts-all.yml"
  while IFS= read -r f; do "$GIT_BIN" -C "$TS_REPO_IN" show "$TS_PIN:$f" >> "$WORK/ts-all.yml"; done < "$WORK/ts-workflows.txt"
  TS_HITS=$("$GREP" -c -iE 'trufflehog|gitleaks|kingfisher|detect-secrets|secret-scan' "$WORK/ts-all.yml" || true)
  echo "-- $TS_FILES workflow files; scanner references counted via $GREP: $TS_HITS"
  assert 02a-ts-has-no-secret-scanner-reference "8 0" "$TS_FILES $TS_HITS"
fi

say "03 the TruffleHog OSS CLI release at $TH_CLI_TAG — assets, and what ships beside them"
if [ "$HAVE_NET" = no ]; then
  for l in 03a-release-ships-darwin-and-linux-tarballs 03b-release-ships-a-signed-checksums-file; do
    skip "$l" "no network egress"
  done
else
  api_fetch "repos/trufflesecurity/trufflehog/releases/tags/$TH_CLI_TAG" "$WORK/th-rel.json"
  "$PY3" - "$WORK/th-rel.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
print("tag:", d["tag_name"], "published:", d["published_at"])
for a in d["assets"]: print("  ", a["name"], a["size"])
PY
  TH_DARWIN=$("$PY3" -c 'import json,sys;print(len([a for a in json.load(open(sys.argv[1]))["assets"] if "_darwin_" in a["name"] and a["name"].endswith(".tar.gz")]))' "$WORK/th-rel.json")
  TH_LINUX=$("$PY3" -c 'import json,sys;print(len([a for a in json.load(open(sys.argv[1]))["assets"] if "_linux_" in a["name"] and a["name"].endswith(".tar.gz")]))' "$WORK/th-rel.json")
  TH_SUMS=$("$PY3" -c 'import json,sys;print(len([a for a in json.load(open(sys.argv[1]))["assets"] if a["name"].endswith("_checksums.txt")]))' "$WORK/th-rel.json")
  TH_SIG=$("$PY3" -c 'import json,sys;print(len([a for a in json.load(open(sys.argv[1]))["assets"] if a["name"].endswith(".sig") or a["name"].endswith(".pem")]))' "$WORK/th-rel.json")
  echo "-- darwin tarballs=$TH_DARWIN linux tarballs=$TH_LINUX checksums=$TH_SUMS sig+pem=$TH_SIG"
  assert 03a-release-ships-darwin-and-linux-tarballs "2 2" "$TH_DARWIN $TH_LINUX"
  assert 03b-release-ships-a-signed-checksums-file "1 2" "$TH_SUMS $TH_SIG"
fi

say "04 provenance of the pinned release — what TruffleHog actually publishes, and what it does not"
# Kingfisher's release carries a GitHub build attestation, which `gh attestation verify` checks in
# one command. TruffleHog's does not: it ships a checksums file signed with a Sigstore KEYLESS
# certificate (cosign's --output-certificate / --output-signature pair). The two forms are verified
# by different commands and give different guarantees, so both are executed here rather than assumed.
TH_TGZ="$TH_DIR/trufflehog_${TH_VER}_darwin_arm64.tar.gz"
TH_SUMS_F="$TH_DIR/trufflehog_${TH_VER}_checksums.txt"
TH_PEM_F="$TH_DIR/trufflehog_${TH_VER}_checksums.txt.pem"
TH_SIG_F="$TH_DIR/trufflehog_${TH_VER}_checksums.txt.sig"
BASE_URL="https://github.com/trufflesecurity/trufflehog/releases/download/$TH_CLI_TAG"
HAVE_ART=no
if [ "$HAVE_NET" = yes ]; then
  mkdir -p "$TH_DIR"
  # Every artefact is tested, not just the unpacked binary: a cache holding the binary but not the
  # tarball would otherwise leave 04a verifying a path that is not there.
  for f in "trufflehog_${TH_VER}_darwin_arm64.tar.gz" "trufflehog_${TH_VER}_checksums.txt" \
           "trufflehog_${TH_VER}_checksums.txt.pem" "trufflehog_${TH_VER}_checksums.txt.sig"; do
    [ -s "$TH_DIR/$f" ] || "$CURL" -sSL --max-time 900 -H "$UA" -o "$TH_DIR/$f" "$BASE_URL/$f"
  done
  if [ ! -x "$TH_DIR/trufflehog" ] && [ -s "$TH_TGZ" ]; then "$TAR" xzf "$TH_TGZ" -C "$TH_DIR"; fi
fi
{ [ -s "$TH_TGZ" ] && [ -s "$TH_SUMS_F" ] && [ -s "$TH_PEM_F" ] && [ -s "$TH_SIG_F" ]; } && HAVE_ART=yes
TH_RUNS=no
[ "$HAVE_ART" = yes ] && [ "$TH_PLATFORM" = yes ] && [ -x "$TH_DIR/trufflehog" ] && TH_RUNS=yes

if [ "$HAVE_ART" = no ]; then
  for l in 04a-tarball-digest-matches-the-published-checksums-file 04b-certificate-names-the-release-workflow-at-the-pinned-tag \
           04c-certificate-was-issued-by-sigstore 04d-checksums-signature-verifies-against-that-certificate \
           04e-negative-control-a-tampered-checksums-file-fails-verification \
           04f-negative-control-a-tampered-tarball-digest-does-not-match; do
    skip "$l" "release artefacts not present (network=$HAVE_NET dir=$TH_DIR)"
  done
else
  echo "-- release tarball bytes: $(wc -c < "$TH_TGZ" | tr -d ' '); unpacked binary bytes: $(wc -c < "$TH_DIR/trufflehog" 2>/dev/null | tr -d ' ')"
  LOCAL_DIGEST=$("$SHASUM" -a 256 "$TH_TGZ" | cut -d' ' -f1)
  PUBLISHED_DIGEST=$("$GREP" " trufflehog_${TH_VER}_darwin_arm64.tar.gz\$" "$TH_SUMS_F" | cut -d' ' -f1)
  echo "-- local sha256:     $LOCAL_DIGEST"
  echo "-- published sha256: $PUBLISHED_DIGEST (from trufflehog_${TH_VER}_checksums.txt, line located via $GREP)"
  assert 04a-tarball-digest-matches-the-published-checksums-file "$LOCAL_DIGEST" "$PUBLISHED_DIGEST"
  if [ -z "$OPENSSL" ]; then
    for l in 04b-certificate-names-the-release-workflow-at-the-pinned-tag 04c-certificate-was-issued-by-sigstore \
             04d-checksums-signature-verifies-against-that-certificate \
             04e-negative-control-a-tampered-checksums-file-fails-verification; do
      skip "$l" "no openssl resolved on this host"
    done
  else
    # cosign writes the certificate and the signature base64-ENCODED, so each is decoded first.
    base64 -d < "$TH_PEM_F" > "$WORK/th-cert.pem" 2>/dev/null || "$PY3" -c 'import base64,sys;sys.stdout.buffer.write(base64.b64decode(open(sys.argv[1],"rb").read()))' "$TH_PEM_F" > "$WORK/th-cert.pem"
    base64 -d < "$TH_SIG_F" > "$WORK/th-sig.bin" 2>/dev/null || "$PY3" -c 'import base64,sys;sys.stdout.buffer.write(base64.b64decode(open(sys.argv[1],"rb").read()))' "$TH_SIG_F" > "$WORK/th-sig.bin"
    echo "-- signing certificate (decoded from the published .pem):"
    "$OPENSSL" x509 -in "$WORK/th-cert.pem" -noout -issuer -ext subjectAltName -dates 2>/dev/null | "$SED" 's/^/   /'
    echo "   NOTE: the notBefore/notAfter window above is ten minutes wide. That is how Sigstore"
    echo "   keyless signing works — the certificate is ephemeral and is bound to the signing event,"
    echo "   not to a validity period a verifier waits inside. An expired window is NOT a failure."
    CERT_SAN=$("$OPENSSL" x509 -in "$WORK/th-cert.pem" -noout -ext subjectAltName 2>/dev/null | "$GREP" -o 'URI:.*' | "$SED" 's/^URI://')
    CERT_ISSUER=$("$OPENSSL" x509 -in "$WORK/th-cert.pem" -noout -issuer 2>/dev/null | "$SED" 's/^issuer=//')
    assert 04b-certificate-names-the-release-workflow-at-the-pinned-tag \
      "https://github.com/trufflesecurity/trufflehog/.github/workflows/release.yml@refs/tags/$TH_CLI_TAG" "$CERT_SAN"
    assert 04c-certificate-was-issued-by-sigstore "O=sigstore.dev, CN=sigstore-intermediate" "$CERT_ISSUER"
    "$OPENSSL" x509 -in "$WORK/th-cert.pem" -pubkey -noout > "$WORK/th-pub.pem" 2>/dev/null
    VERIFY_OUT=$("$OPENSSL" dgst -sha256 -verify "$WORK/th-pub.pem" -signature "$WORK/th-sig.bin" "$TH_SUMS_F" 2>&1)
    VERIFY_EXIT=$?
    echo "-- openssl dgst -sha256 -verify: $VERIFY_OUT (exit $VERIFY_EXIT)"
    assert 04d-checksums-signature-verifies-against-that-certificate "Verified OK 0" "$VERIFY_OUT $VERIFY_EXIT"
    # A check that cannot fail is not evidence: flip one byte of a COPY and show the verification breaks.
    # The flip is done by value, not by pattern: replacing the first byte with a DIFFERENT one
    # whatever it happens to be, so the control cannot degenerate into copying the file unchanged.
    "$PY3" - "$TH_SUMS_F" "$WORK/th-sums-tampered.txt" <<'PY'
import sys
b=bytearray(open(sys.argv[1],'rb').read())
b[0] = ord('0') if b[0] != ord('0') else ord('1')
open(sys.argv[2],'wb').write(bytes(b))
PY
    TAMPER_OUT=$("$OPENSSL" dgst -sha256 -verify "$WORK/th-pub.pem" -signature "$WORK/th-sig.bin" "$WORK/th-sums-tampered.txt" 2>&1)
    TAMPER_EXIT=$?
    TAMPER_DIFFERS=0; [ "$("$SHASUM" -a 256 < "$WORK/th-sums-tampered.txt")" != "$("$SHASUM" -a 256 < "$TH_SUMS_F")" ] && TAMPER_DIFFERS=1
    echo "-- tampered copy differs from the published file: $TAMPER_DIFFERS; openssl says: $TAMPER_OUT (exit $TAMPER_EXIT)"
    TAMPER_FAILED=0; [ "$TAMPER_EXIT" -ne 0 ] && TAMPER_FAILED=1
    assert 04e-negative-control-a-tampered-checksums-file-fails-verification "1 1" "$TAMPER_DIFFERS $TAMPER_FAILED"
  fi
  # The second negative control needs no openssl: a digest that is not the published one must not match.
  FAKE_DIGEST=$(printf 'not-the-artifact' | "$SHASUM" -a 256 | cut -d' ' -f1)
  MATCHES=0; [ "$FAKE_DIGEST" = "$PUBLISHED_DIGEST" ] && MATCHES=1
  assert 04f-negative-control-a-tampered-tarball-digest-does-not-match 0 "$MATCHES"
fi

# What TruffleHog does NOT publish, executed rather than inferred from a 404 in prose.
if [ "$HAVE_ART" = no ] || [ -z "$GH_REAL" ] || [ "$GH_AUTH" != token ]; then
  skip 04g-trufflehog-publishes-no-github-build-attestation \
    "needs the release tarball, a resolved gh CLI and a DECLARED token (artefacts=$HAVE_ART gh=${GH_REAL:-none} token=$GH_AUTH)"
else
  GH_SIGSTORE_CACHE="$WORK/gh-cache"; mkdir -p "$GH_SIGSTORE_CACHE"
  env -i PATH="$PATH" HOME="$HOME" XDG_CACHE_HOME="$GH_SIGSTORE_CACHE" GH_TOKEN="$GH_TOKEN_IN" \
    "$GH_REAL" attestation verify "$TH_TGZ" --repo trufflesecurity/trufflehog --format json \
    > "$WORK/th-att.json" 2>"$WORK/th-att.err"
  ATT_EXIT=$?
  echo "-- gh attestation verify exit: $ATT_EXIT; its stderr (wording is this gh build's):"
  "$SED" -n '1,3p' "$WORK/th-att.err" | "$SED" 's/^/   /'
  # gh reports the absence as the attestations endpoint's own 404 rather than in words, so the
  # pattern matches that endpoint specifically: a 404 from some other path would not satisfy it.
  ATT_NONE=$("$GREP" -c -iE 'no attestations found|HTTP 404: Not Found .*/attestations/sha256:' "$WORK/th-att.err")
  ATT_BYTES=$(wc -c < "$WORK/th-att.json" | tr -d ' ')
  ATT_FAILED=0; [ "$ATT_EXIT" -ne 0 ] && ATT_FAILED=1
  echo "   refused=$ATT_FAILED, attestations-endpoint 404 or 'no attestations found' in stderr=$ATT_NONE (count via $GREP), attestation bytes written=$ATT_BYTES"
  echo "   This is the executed statement that the pinned TruffleHog release carries NO GitHub build"
  echo "   attestation. It is falsifiable in the useful direction: if TruffleHog starts publishing one,"
  echo "   this assertion FAILS and the decision's provenance paragraph must be rewritten."
  assert 04g-trufflehog-publishes-no-github-build-attestation "1 1 0" "$ATT_FAILED $ATT_NONE $ATT_BYTES"
fi

if [ -z "$COSIGN" ]; then
  skip 04h-full-sigstore-verification-chain-and-rekor-inclusion \
    "cosign is not installed on this host; openssl above verifies the SIGNATURE against the published certificate but validates NO chain to the Sigstore root and checks NO Rekor inclusion. P03's install step should run: cosign verify-blob --certificate <pem> --signature <sig> --certificate-identity https://github.com/trufflesecurity/trufflehog/.github/workflows/release.yml@refs/tags/$TH_CLI_TAG --certificate-oidc-issuer https://token.actions.githubusercontent.com trufflehog_${TH_VER}_checksums.txt"
else
  echo "-- cosign is present at $COSIGN; running the full verification"
  env -i PATH="$PATH" HOME="$HOME" "$COSIGN" verify-blob \
    --certificate "$TH_PEM_F" --signature "$TH_SIG_F" \
    --certificate-identity "https://github.com/trufflesecurity/trufflehog/.github/workflows/release.yml@refs/tags/$TH_CLI_TAG" \
    --certificate-oidc-issuer https://token.actions.githubusercontent.com \
    "$TH_SUMS_F" > "$WORK/cosign.out" 2>&1
  COSIGN_EXIT=$?
  "$SED" -n '1,4p' "$WORK/cosign.out" | "$SED" 's/^/   /'
  assert 04h-full-sigstore-verification-chain-and-rekor-inclusion 0 "$COSIGN_EXIT"
fi

say "05 execute the pinned binary on this host"
if [ "$TH_RUNS" = no ]; then
  skip 05a-macos-binary-runs "needs a Darwin arm64 host with the unpacked binary (platform=$UNAME_S/$UNAME_M artefacts=$HAVE_ART)"
else
  TH_VERSION=$("$TH_DIR/trufflehog" --version 2>&1 | tr -d '\n')
  echo "-- macOS arm64 execution: $TH_VERSION"
  assert 05a-macos-binary-runs "trufflehog $TH_VER" "$TH_VERSION"
fi

say "06 the documented exit-code set at $TH_CLI_TAG, and the flags the ruling names"
if [ "$HAVE_NET" = no ]; then
  for l in 06a-documented-exit-code-set-is-exactly-0-1-183 06b-help-documents-fail-as-183 \
           06c-help-documents-fail-on-scan-errors 06d-only-verified-is-a-hidden-alias-for-results-verified; do
    skip "$l" "no network egress"
  done
else
  "$CURL" -sSL --max-time 60 -H "$UA" "https://raw.githubusercontent.com/trufflesecurity/trufflehog/$TH_CLI_TAG/README.md" -o "$WORK/TH-README.md"
  echo "-- README.md at $TH_CLI_TAG, sha256: $("$SHASUM" -a 256 < "$WORK/TH-README.md")"
  echo "-- the whole 'Exit Codes:' block, printed rather than summarised:"
  "$AWK" '/^Exit Codes:/{f=1} f&&/^## /{exit} f' "$WORK/TH-README.md" | head -10 | "$SED" 's/^/   /'
  TH_CODES=$("$AWK" '/^Exit Codes:/{f=1} f&&/^## /{exit} f' "$WORK/TH-README.md" \
    | "$SED" -n 's/^- \([0-9][0-9]*\):.*/\1/p' | tr '\n' ' ' | "$SED" 's/ $//')
  echo "-- documented exit codes, in README order: [$TH_CODES]"
  assert 06a-documented-exit-code-set-is-exactly-0-1-183 "0 1 183" "$TH_CODES"
  "$CURL" -sSL --max-time 60 -H "$UA" "https://raw.githubusercontent.com/trufflesecurity/trufflehog/$TH_CLI_TAG/main.go" -o "$WORK/TH-main.go"
  echo "-- main.go at $TH_CLI_TAG, sha256: $("$SHASUM" -a 256 < "$WORK/TH-main.go")"
  "$GREP" -n -E 'cli\.Flag\("only-verified"|cli\.Flag\("fail"|cli\.Flag\("fail-on-scan-errors"|os\.Exit\(183\)' "$WORK/TH-main.go" | "$SED" 's/^/   /'
  OV_HIDDEN=$("$GREP" -c -E 'cli\.Flag\("only-verified", "Only output verified results\."\)\.Hidden\(\)' "$WORK/TH-main.go")
  OV_MAPS=$("$AWK" '/if \*onlyVerified \{/{f=1} f&&/results = &r/{c++} f&&/\}/{f=0} END{print c+0}' "$WORK/TH-main.go")
  echo "-- counts via $GREP/awk over main.go: only-verified-hidden=$OV_HIDDEN maps-to-results-verified=$OV_MAPS"
  assert 06d-only-verified-is-a-hidden-alias-for-results-verified "1 1" "$OV_HIDDEN $OV_MAPS"
  if [ "$TH_RUNS" = no ]; then
    skip 06b-help-documents-fail-as-183 "needs the binary on this host"
    skip 06c-help-documents-fail-on-scan-errors "needs the binary on this host"
    skip 06e-the-shipped-binary-accepts-the-flags-the-owners-ruling-names "needs the binary on this host"
  else
    "$TH_DIR/trufflehog" --help > "$WORK/th-help.txt" 2>&1 || true
    "$GREP" -n -E 'fail-on-scan-errors|Exit with code 183|only-verified' "$WORK/th-help.txt" | "$SED" 's/^/   /'
    HELP_183=$("$GREP" -c -- 'Exit with code 183 if results are found' "$WORK/th-help.txt")
    HELP_FOSE=$("$GREP" -c -- '--\[no-\]fail-on-scan-errors' "$WORK/th-help.txt")
    HELP_OV=$("$GREP" -c -- '--\[no-\]only-verified' "$WORK/th-help.txt")
    echo "-- counts via $GREP over --help: fail-183=$HELP_183 fail-on-scan-errors=$HELP_FOSE only-verified=$HELP_OV"
    assert 06b-help-documents-fail-as-183 1 "$HELP_183"
    assert 06c-help-documents-fail-on-scan-errors 1 "$HELP_FOSE"
    # The owner's ruling names `--only-verified --fail`. The flag is HIDDEN at this pin (06d), so
    # --help does not list it: whether the shipped binary still ACCEPTS it has to be executed, and
    # the control is an unknown flag, which this binary rejects.
    mkdir -p "$WORK/flagprobe"; printf 'nothing here\n' > "$WORK/flagprobe/readme.txt"
    "$TH_DIR/trufflehog" filesystem "$WORK/flagprobe" --only-verified --fail --no-update >/dev/null 2>"$WORK/ov.err"
    OV_EXIT=$?
    OV_UNKNOWN=$("$GREP" -c "unknown long flag '--only-verified'" "$WORK/ov.err")
    "$TH_DIR/trufflehog" filesystem "$WORK/flagprobe" --definitely-not-a-flag >/dev/null 2>"$WORK/bad.err"
    BAD_EXIT=$?
    BAD_UNKNOWN=$("$GREP" -c "unknown long flag '--definitely-not-a-flag'" "$WORK/bad.err")
    echo "-- --only-verified accepted: unknown-flag-errors=$OV_UNKNOWN (exit $OV_EXIT); control flag rejected: unknown-flag-errors=$BAD_UNKNOWN (exit $BAD_EXIT)"
    assert 06e-the-shipped-binary-accepts-the-flags-the-owners-ruling-names "0 1 1" "$OV_UNKNOWN $BAD_UNKNOWN $BAD_EXIT"
  fi
fi

say "07 observed exit codes — the gate rule's allow-list, and the two ways this tool returns 0 unscanned"
if [ "$TH_RUNS" = no ] || [ -z "$GIT_BIN" ]; then
  for l in 07a-fake-credentials-pass-under-only-verified 07b-the-same-scan-unfiltered-exits-183 \
           07c-history-only-secret-is-found-with-no-since-commit 07d-history-only-secret-passes-under-only-verified \
           07e-a-single-commit-repository-scans-without-an-equal-base-head-error \
           07f-an-unknown-flag-exits-1 07g-a-missing-scan-target-exits-0-without-fail-on-scan-errors \
           07h-the-same-missing-target-exits-1-with-it 07i-a-partial-scan-error-is-swallowed-without-the-flag \
           07j-a-bad-since-commit-exits-0-having-scanned-nothing 07k-every-observed-code-is-in-the-documented-set; do
    skip "$l" "needs the TruffleHog binary and a working git on this host (platform=$UNAME_S/$UNAME_M artefacts=$HAVE_ART)"
  done
else
  TH_BIN="$TH_DIR/trufflehog"
  # --- fixture A: template-shaped, deterministically generated, NON-LIVE credentials -------------
  mkdir -p "$WORK/fixA"
  "$PY3" - "$WORK/fixA" <<'PY'
import os,random,string,sys
d=sys.argv[1]
random.seed(17)
ghp='ghp_'+''.join(random.choice(string.ascii_letters+string.digits) for _ in range(36))
akia='AKIA'+''.join(random.choice(string.ascii_uppercase+string.digits) for _ in range(16))
sk=''.join(random.choice(string.ascii_letters+string.digits+'/+') for _ in range(40))
open(os.path.join(d,'.env.example'),'w').write(
  f"DATABASE_URL=postgres://user:password@localhost:5432/appdb\nAWS_ACCESS_KEY_ID={akia}\nAWS_SECRET_ACCESS_KEY={sk}\nGITHUB_TOKEN={ghp}\n")
open(os.path.join(d,'.fixture-token'),'w').write(ghp)   # read by section 08's counts; never printed
print("fixture A written: .env.example with 1 synthetic PAT-shaped value, 1 synthetic AWS key pair")
print("and one localhost postgres URI. The values are deterministic, non-live and never printed.")
PY
  ( cd "$WORK/fixA" && "$GIT_BIN" init -q . && "$GIT_BIN" config user.email r17@example.invalid \
    && "$GIT_BIN" config user.name r17 && "$GIT_BIN" add .env.example && "$GIT_BIN" commit -qm "fixture A" )
  "$TH_BIN" git "file://$WORK/fixA" --only-verified --fail --no-update > "$WORK/a1.out" 2>"$WORK/a1.err"
  A1=$?
  "$TH_BIN" git "file://$WORK/fixA" --fail --no-update > "$WORK/a2.out" 2>"$WORK/a2.err"
  A2=$?
  echo "-- fixture A, --only-verified --fail: exit $A1; same scan unfiltered --fail: exit $A2"
  "$GREP" -oE '"unverified_secrets": ?[0-9]+' "$WORK/a2.err" | tail -1 | "$SED" 's/^/   /' || true
  assert 07a-fake-credentials-pass-under-only-verified 0 "$A1"
  assert 07b-the-same-scan-unfiltered-exits-183 183 "$A2"

  # --- fixture B: the secret exists only in history -----------------------------------------------
  mkdir -p "$WORK/fixB"
  ( cd "$WORK/fixB" && "$GIT_BIN" init -q . && "$GIT_BIN" config user.email r17@example.invalid && "$GIT_BIN" config user.name r17 )
  "$PY3" - "$WORK/fixB" <<'PY'
import os,random,string,sys
d=sys.argv[1]
random.seed(99)
tok='ghp_'+''.join(random.choice(string.ascii_letters+string.digits) for _ in range(36))
open(os.path.join(d,'leak.txt'),'w').write('token='+tok+'\n')
print("fixture B: one synthetic PAT-shaped value committed then deleted (value not printed)")
PY
  ( cd "$WORK/fixB" && "$GIT_BIN" add -A && "$GIT_BIN" commit -qm "add synthetic token" \
    && rm leak.txt && "$GIT_BIN" commit -qam "remove synthetic token" )
  echo "-- fixture B working tree after the deletion:"
  FIXB_LEFT=$(find "$WORK/fixB" -mindepth 1 -maxdepth 1 ! -name .git | wc -l | tr -d ' ')
  echo "   tracked entries left beside .git: $FIXB_LEFT"
  "$TH_BIN" git "file://$WORK/fixB" --fail --no-update > "$WORK/b1.out" 2>"$WORK/b1.err"
  B1=$?
  "$TH_BIN" git "file://$WORK/fixB" --only-verified --fail --no-update > "$WORK/b2.out" 2>"$WORK/b2.err"
  B2=$?
  "$GREP" -oE '"chunks": ?[0-9]+, ?"bytes": ?[0-9]+, ?"verified_secrets": ?[0-9]+, ?"unverified_secrets": ?[0-9]+' "$WORK/b1.err" | tail -1 | "$SED" 's/^/   scan metrics: /' || true
  echo "-- fixture B, no --since-commit: unfiltered exit $B1; --only-verified exit $B2"
  assert 07c-history-only-secret-is-found-with-no-since-commit 183 "$B1"
  assert 07d-history-only-secret-passes-under-only-verified 0 "$B2"

  # --- the failure py's workflow works around: the Action's equal base/head guard ------------------
  # The CLI has no such guard. A repository with exactly one commit — the shape of a template's
  # first push — is scanned without the "BASE and HEAD commits are the same" error.
  "$TH_BIN" git "file://$WORK/fixA" --only-verified --fail --no-update > "$WORK/c1.out" 2>"$WORK/c1.err"
  C1=$?
  C1_GUARD=$("$GREP" -c -i 'BASE and HEAD commits are the same' "$WORK/c1.err")
  ONE_COMMIT=$("$GIT_BIN" -C "$WORK/fixA" rev-list --count HEAD)
  echo "-- single-commit repository ($ONE_COMMIT commit): exit $C1, equal-base-head errors=$C1_GUARD (count via $GREP)"
  assert 07e-a-single-commit-repository-scans-without-an-equal-base-head-error "1 0 0" "$ONE_COMMIT $C1 $C1_GUARD"

  # --- codes outside the passing case ------------------------------------------------------------
  "$TH_BIN" git "file://$WORK/fixA" --not-a-real-flag >/dev/null 2>"$WORK/d1.err"; D1=$?
  echo "-- unknown flag: exit $D1"
  assert 07f-an-unknown-flag-exits-1 1 "$D1"

  # THE FAIL-OPEN THIS TOOL HAS AND KINGFISHER DOES NOT. A filesystem target that does not exist is
  # a NON-FATAL scan error: TruffleHog logs it and exits 0 unless --fail-on-scan-errors is passed.
  "$TH_BIN" filesystem "$WORK/does-not-exist" --only-verified --fail --no-update >/dev/null 2>"$WORK/e1.err"; E1=$?
  "$TH_BIN" filesystem "$WORK/does-not-exist" --only-verified --fail --no-update >/dev/null 2>"$WORK/e2.err"; E2=$?
  E1_ERR=$("$GREP" -c 'encountered errors during scan' "$WORK/e1.err")
  echo "-- missing filesystem target: exit $E1 WITHOUT --fail-on-scan-errors (scan errors logged=$E1_ERR, count via $GREP); exit $E2 WITH it"
  assert 07g-a-missing-scan-target-exits-0-without-fail-on-scan-errors "0 1" "$E1 $E1_ERR"
  assert 07h-the-same-missing-target-exits-1-with-it 1 "$E2"
  # The sharper version: one good target and one broken one. Without the flag the broken half is
  # swallowed entirely and the exit reports only what the good half found.
  "$TH_BIN" filesystem "$WORK/fixA" "$WORK/does-not-exist" --fail --no-update >/dev/null 2>"$WORK/f1.err"; F1X=$?
  "$TH_BIN" filesystem "$WORK/fixA" "$WORK/does-not-exist" --fail --fail-on-scan-errors --no-update >/dev/null 2>"$WORK/f2.err"; F2X=$?
  echo "-- one good + one missing target: exit $F1X without the flag, exit $F2X with it"
  assert 07i-a-partial-scan-error-is-swallowed-without-the-flag "183 1" "$F1X $F2X"
  # The second way this tool returns 0 having scanned nothing: a --since-commit the repository does
  # not contain. This is why the recommendation is single-mode full history with no --since-commit.
  "$TH_BIN" git "file://$WORK/fixB" --since-commit deadbeefdeadbeefdeadbeefdeadbeefdeadbeef --fail --no-update \
    >/dev/null 2>"$WORK/g1.err"; G1=$?
  G1_CHUNKS=$("$GREP" -oE '"chunks": ?[0-9]+' "$WORK/g1.err" | tail -1 | "$SED" 's/.*: *//')
  echo "-- git source with a --since-commit the repository does not contain: exit $G1, chunks scanned=${G1_CHUNKS:-unknown}"
  assert 07j-a-bad-since-commit-exits-0-having-scanned-nothing "0 0" "$G1 ${G1_CHUNKS:-unknown}"
  # Every code this section observed must be inside the documented set, or the allow-list is wrong.
  OUTSIDE=0
  for code in "$A1" "$A2" "$B1" "$B2" "$C1" "$D1" "$E1" "$E2" "$F1X" "$F2X" "$G1"; do
    case "$code" in 0|1|183) : ;; *) OUTSIDE=$((OUTSIDE+1)); echo "   code outside the documented set: $code" ;; esac
  done
  echo "-- observed codes: $A1 $A2 $B1 $B2 $C1 $D1 $E1 $E2 $F1X $F2X $G1; outside {0,1,183}: $OUTSIDE"
  assert 07k-every-observed-code-is-in-the-documented-set 0 "$OUTSIDE"
fi

say "08 what reaches the job log — TruffleHog has no --redact, executed by counting, never by printing"
if [ "$TH_RUNS" = no ] || [ ! -s "$WORK/fixA/.fixture-token" ]; then
  for l in 08a-default-output-prints-the-raw-secret 08b-json-output-prints-the-raw-secret \
           08c-github-actions-output-prints-no-secret-but-names-file-and-line 08d-github-actions-output-still-exits-183; do
    skip "$l" "needs the TruffleHog binary and fixture A on this host"
  done
else
  TOKEN_BYTES=$(cat "$WORK/fixA/.fixture-token")
  [ -s "$WORK/th-help.txt" ] || "$TH_DIR/trufflehog" --help > "$WORK/th-help.txt" 2>&1 || true
  NO_REDACT=$("$GREP" -c -i 'redact' "$WORK/th-help.txt" || true)
  echo "-- occurrences of 'redact' anywhere in --help (count via $GREP): $NO_REDACT"
  "$TH_BIN" git "file://$WORK/fixA" --fail --no-update > "$WORK/p.out" 2>"$WORK/p.err" || true
  "$TH_BIN" git "file://$WORK/fixA" --fail --json --no-update > "$WORK/j.out" 2>"$WORK/j.err" || true
  "$TH_BIN" git "file://$WORK/fixA" --fail --github-actions --no-update > "$WORK/g.out" 2>"$WORK/g.err"
  GA_EXIT=$?
  P_HITS=$("$GREP" -c -- "$TOKEN_BYTES" "$WORK/p.out" || true)
  J_HITS=$("$GREP" -c -- "$TOKEN_BYTES" "$WORK/j.out" || true)
  G_HITS=$("$GREP" -c -- "$TOKEN_BYTES" "$WORK/g.out" || true)
  GE_HITS=$("$GREP" -c -- "$TOKEN_BYTES" "$WORK/g.err" || true)
  GA_ANNOT=$("$GREP" -c -E '^::warning file=\.env\.example,line=[0-9]+' "$WORK/g.out")
  echo "-- occurrences of the fixture's own token bytes in each output (counts via $GREP; the outputs"
  echo "   themselves are NEVER echoed into this log): default=$P_HITS json=$J_HITS github-actions=$G_HITS (+stderr $GE_HITS)"
  echo "-- github-actions annotations naming file and line: $GA_ANNOT (fixture A carries two"
  echo "   detectable values, so two annotations are expected; the annotations themselves are not echoed)"
  assert 08a-default-output-prints-the-raw-secret "0 1" "$NO_REDACT $P_HITS"
  assert 08b-json-output-prints-the-raw-secret 1 "$J_HITS"
  assert 08c-github-actions-output-prints-no-secret-but-names-file-and-line "0 0 2" "$G_HITS $GE_HITS $GA_ANNOT"
  assert 08d-github-actions-output-still-exits-183 183 "$GA_EXIT"
fi

say "09 a VERIFIED detection against TruffleHog's own published test corpus"
# Revision 6 recorded "exit code on a genuinely live credential" as unproven because proving it
# needed a live credential this research will not create. TruffleHog publishes one: the repository
# trufflesecurity/test_keys, referenced from its README as the demo target, carries credentials its
# verifiers confirm against the issuing provider. Only the detector names, the verified COUNT and
# the exit code are printed — never a result's Raw or RawV2 field.
if [ "$TH_RUNS" = no ] || [ "$HAVE_NET" = no ] || [ -z "$GIT_BIN" ]; then
  skip 09a-a-verified-credential-is-detected-and-exits-183 \
    "needs the TruffleHog binary, git and network egress to the credential issuers (platform=$UNAME_S/$UNAME_M network=$HAVE_NET)"
else
  if [ ! -d "$TK_DIR/.git" ]; then
    "$GIT_BIN" clone -q https://github.com/trufflesecurity/test_keys "$TK_DIR" 2>"$WORK/tk-clone.err" || true
  else
    "$GIT_BIN" -C "$TK_DIR" fetch -q origin 2>/dev/null || true
    "$GIT_BIN" -C "$TK_DIR" reset -q --hard origin/HEAD 2>/dev/null || true
  fi
  if [ ! -d "$TK_DIR/.git" ]; then
    skip 09a-a-verified-credential-is-detected-and-exits-183 "could not clone trufflesecurity/test_keys"
  else
    TK_HEAD=$("$GIT_BIN" -C "$TK_DIR" rev-parse HEAD)
    echo "-- trufflesecurity/test_keys at HEAD $TK_HEAD (a moving ref: the corpus is upstream's to change)"
    "$TH_BIN" git "file://$TK_DIR" --only-verified --fail --json --no-update > "$WORK/tk.json" 2>"$WORK/tk.err"
    TK_EXIT=$?
    "$PY3" - "$WORK/tk.json" > "$WORK/tk-summary.txt" <<'PY'
import json,sys
n=0; dets=set()
for line in open(sys.argv[1]):
    line=line.strip()
    if not line: continue
    try: d=json.loads(line)
    except Exception: continue
    if d.get("Verified"):
        n+=1; dets.add(d.get("DetectorName"))
# Only the detector names and the count are emitted. The Raw/RawV2 fields of a VERIFIED credential
# are never read out of this file.
print(n, ",".join(sorted(dets)))
PY
    TK_N=$(cut -d' ' -f1 "$WORK/tk-summary.txt")
    TK_DETS=$(cut -d' ' -f2- "$WORK/tk-summary.txt")
    TK_AT_LEAST_ONE=no; [ "${TK_N:-0}" -ge 1 ] && TK_AT_LEAST_ONE=yes
    "$GREP" -o '"verified_secrets":[0-9]*' "$WORK/tk.err" | tail -1 | "$SED" 's/^/   scanner metric: /' || true
    echo "-- verified findings: $TK_N (detectors: $TK_DETS); exit $TK_EXIT"
    echo "   This is the acceptance criterion revision 6 could only propose: a credential the issuing"
    echo "   provider confirms is live, detected, and the process exiting at the documented code. It"
    echo "   is executed on a developer machine, NOT in a GitHub Actions job."
    assert 09a-a-verified-credential-is-detected-and-exits-183 "yes 183" "$TK_AT_LEAST_ONE $TK_EXIT"
  fi
fi

say "10 repository figures for both candidates, read at THIS run's instant (round 6 finding F1)"
# Round 6 rejected revision 6 because two star counts were attributed to logs that did not contain
# them: they were carried from the round-1/2 AUDIT logs and never re-read. The counters are printed
# with the instant they were read and are NEVER asserted on; the stable properties are asserted.
if [ "$HAVE_NET" = no ]; then
  for l in 10a-trufflehog-not-archived 10b-trufflehog-license-agpl 10c-kingfisher-not-archived 10d-kingfisher-license-apache; do
    skip "$l" "no network egress"
  done
else
  date -u +'-- counters below were read at: %Y-%m-%dT%H:%M:%SZ'
  api_fetch repos/trufflesecurity/trufflehog "$WORK/th.json"
  api_fetch repos/mongodb/kingfisher "$WORK/kf.json"
  "$PY3" - "$WORK/th.json" "$WORK/kf.json" <<'PY'
import json,sys
for p in sys.argv[1:]:
    d=json.load(open(p))
    print("  ", d["full_name"], "stargazers_count:", d["stargazers_count"],
          "archived:", json.dumps(d["archived"]), "created:", d["created_at"],
          "pushed:", d["pushed_at"], "license:", (d.get("license") or {}).get("spdx_id"))
PY
  assert 10a-trufflehog-not-archived false "$(jget "$WORK/th.json" archived)"
  assert 10b-trufflehog-license-agpl AGPL-3.0 "$(jget "$WORK/th.json" license.spdx_id)"
  assert 10c-kingfisher-not-archived false "$(jget "$WORK/kf.json" archived)"
  assert 10d-kingfisher-license-apache Apache-2.0 "$(jget "$WORK/kf.json" license.spdx_id)"
fi

say "11 the gitleaks-action organization-key requirement, EXECUTED (round 6 finding F2)"
# Round 6 rejected the provenance label on this fact: the only ground for excluding
# gitleaks/gitleaks-action that survives the owner's Q7.B ruling was called "verified, section 04",
# and revision 6's pattern was `GITLEAKS_LICENSE \(required`, which cannot match the README's
# backticked `GITLEAKS_LICENSE` (required ... form. The pattern is fixed here and the file is read
# at a PINNED commit, so the check reads the bytes it names.
if [ "$HAVE_NET" = no ]; then
  for l in 11a-gitleaks-action-requires-a-purchased-organization-key 11b-the-readme-read-here-is-the-pinned-one 11c-gitleaks-action-license-not-osi; do
    skip "$l" "no network egress"
  done
else
  "$CURL" -sSL --max-time 60 -H "$UA" "https://raw.githubusercontent.com/gitleaks/gitleaks-action/$GLA_PIN/README.md" -o "$WORK/gla-README.md"
  GLA_SHA=$("$SHASUM" -a 256 < "$WORK/gla-README.md" | cut -d' ' -f1)
  echo "-- gitleaks/gitleaks-action README.md at $GLA_PIN, sha256: $GLA_SHA"
  echo "-- matching lines, with their line numbers (pattern fixed; count via $GREP):"
  "$GREP" -nE 'GITLEAKS_LICENSE`? \(required|GITLEAKS_LICENSE: \$\{\{ secrets|license has changed from MIT' "$WORK/gla-README.md" \
    | cut -c1-200 | "$SED" 's/^/   /'
  GLA_REQ=$("$GREP" -cE 'GITLEAKS_LICENSE`? \(required|GITLEAKS_LICENSE: \$\{\{ secrets' "$WORK/gla-README.md")
  GLA_LINES=$("$GREP" -nE 'GITLEAKS_LICENSE`? \(required|GITLEAKS_LICENSE: \$\{\{ secrets' "$WORK/gla-README.md" | cut -d: -f1 | tr '\n' ' ' | "$SED" 's/ $//')
  GLA_MIT=$("$GREP" -c 'license has changed from MIT' "$WORK/gla-README.md")
  echo "-- organization-key lines: $GLA_REQ at lines [$GLA_LINES]; 'license has changed from MIT': $GLA_MIT"
  assert 11a-gitleaks-action-requires-a-purchased-organization-key "2 43 75 1" "$GLA_REQ $GLA_LINES $GLA_MIT"
  # The file is immutable at that commit, so its digest is asserted against a literal: a substituted
  # or truncated fetch fails here rather than silently changing the line numbers asserted above.
  assert 11b-the-readme-read-here-is-the-pinned-one \
    ac51aad2988ec6a2c6171bb4b3ba583db16fb7f8530692d69b252d61cfefdb75 "$GLA_SHA"
  api_fetch repos/gitleaks/gitleaks-action "$WORK/gla.json"
  assert 11c-gitleaks-action-license-not-osi NOASSERTION "$(jget "$WORK/gla.json" license.spdx_id)"
fi

say "12 current Rust stable, with the endpoint it came from (round 6 finding F3)"
# Round 6's F3: "a current stable of 1.98.1" carried no endpoint and no date. The version is read
# here from the Rust release channel manifest. The VALUE is printed, never asserted, because it
# moves every six weeks; what is asserted is that the manifest was read and parsed.
if [ "$HAVE_NET" = no ]; then
  skip 12a-rust-stable-read-from-the-release-channel-manifest "no network egress"
else
  "$CURL" -sSL --max-time 120 -H "$UA" https://static.rust-lang.org/dist/channel-rust-stable.toml -o "$WORK/rust-stable.toml"
  RUST_STABLE=$("$PY3" - "$WORK/rust-stable.toml" <<'PY'
import re,sys
s=open(sys.argv[1]).read()
i=s.index('[pkg.rust]')
m=re.search(r'version = "([^"]+)"', s[i:i+400])
print(m.group(1) if m else "unparsed")
PY
)
  RUST_DATE=$("$GREP" -m1 '^date = ' "$WORK/rust-stable.toml" | "$SED" 's/date = //; s/"//g')
  echo "-- https://static.rust-lang.org/dist/channel-rust-stable.toml (sha256 $("$SHASUM" -a 256 < "$WORK/rust-stable.toml" | cut -d' ' -f1))"
  echo "-- manifest date: $RUST_DATE; [pkg.rust] version: $RUST_STABLE"
  date -u +'-- read at: %Y-%m-%dT%H:%M:%SZ'
  SHAPE=no
  printf '%s' "$RUST_STABLE" | "$GREP" -qE '^1\.[0-9]+\.[0-9]+ \([0-9a-f]+ [0-9]{4}-[0-9]{2}-[0-9]{2}\)$' && SHAPE=yes
  assert 12a-rust-stable-read-from-the-release-channel-manifest yes "$SHAPE"
fi

say "13 which approved wording revision 7 preserved, and which the owner's ruling rewrote"
# Revision 3 claimed a set of already-approved regions stood "as revision 2 wrote them" and that was
# false for three of them. This section stops the claim being a matter of assertion: it reads
# revision 2 from a carried copy whose digest is asserted, and compares named anchor lines.
#
# Revision 7 differs from revision 6 in what it can assert. The owner's ruling W0-R17b swapped the
# recommended tool, so two of revision 6's anchors — which matched by literal line PREFIX — no longer
# exist in this document at all: `**Part 2 — implement it with the Kingfisher CLI` and
# `The ranked runner-up is the **TruffleHog OSS CLI`. A prefix that is gone cannot be compared, so
# those two regions are asserted as an ABSENT/PRESENT pair instead: revision 2's opener must be gone
# from this file and revision 7's opener must be here. That is falsifiable in both directions.
REV2_COMMIT=ed16bef14a4dd9cd5adb05cc969a9162f6bfb48a
REV2_SHA_EXPECTED=e2c3d588eaf1a098027b4c9ced4fa01ef1341fd27ef4cfdfa012bfc44a8321ec
RUN_REL="research/runs/R17/2026-09-05T163018Z-d7ade3a111f8"
if [ ! -s "$REV2_FILE" ]; then
  echo "-- the carried revision-2 copy is missing at $REV2_FILE"
  : > "$WORK/rev2-DECISION.md"
else
  cp "$REV2_FILE" "$WORK/rev2-DECISION.md"
fi
REV2_SHA=$("$SHASUM" -a 256 < "$WORK/rev2-DECISION.md" | cut -d' ' -f1)
echo "-- carried revision 2: $REV2_FILE ($(wc -c < "$WORK/rev2-DECISION.md" | tr -d ' ') bytes), sha256: $REV2_SHA"
echo "-- revision under review: $DEC_NOW"
assert 13a-the-carried-copy-is-the-revision-2-the-audit-named "$REV2_SHA_EXPECTED" "$REV2_SHA"
# shellcheck disable=SC2016  # the awk program is deliberately single-quoted: $0 is awk's, not the shell's
anchor_line() { "$AWK" -v p="$2" 'index($0,p)==1 {print; exit}' "$1"; }
cmp_anchor() { # cmp_anchor <label> <same|differ> <literal line prefix>
  local a b ha hb verdict
  a=$(anchor_line "$WORK/rev2-DECISION.md" "$3")
  b=$(anchor_line "$DEC_NOW" "$3")
  if [ -z "$a" ] || [ -z "$b" ]; then
    assert "$1" "$2" "anchor-not-found(rev2=${#a}B now=${#b}B)"; return
  fi
  ha=$(printf '%s' "$a" | "$SHASUM" -a 256 | cut -c1-12)
  hb=$(printf '%s' "$b" | "$SHASUM" -a 256 | cut -c1-12)
  if [ "$ha" = "$hb" ]; then verdict=same; else verdict=differ; fi
  printf '   rev2=%s now=%s %-7s %s\n' "$ha" "$hb" "$verdict" "$3"
  assert "$1" "$2" "$verdict"
}
moved_anchor() { # moved_anchor <label> <rev2 prefix, must be gone> <rev7 prefix, must be here>
  local old new verdict
  old=$(anchor_line "$DEC_NOW" "$2")
  new=$(anchor_line "$DEC_NOW" "$3")
  verdict="$( [ -z "$old" ] && echo absent || echo still-present ) $( [ -n "$new" ] && echo present || echo missing )"
  printf '   rev2-opener=%s rev7-opener=%s  %s\n' "$( [ -z "$old" ] && echo gone || echo PRESENT )" \
    "$( [ -n "$new" ] && echo found || echo MISSING )" "$3"
  assert "$1" "absent present" "$verdict"
}
cmp_anchor 13b-part-1-recommendation-byte-identical            same   '**Part 1 — keep a dedicated'
cmp_anchor 13c-f050-ledger-row-byte-identical                  same   '| F050 — Dedicated secret-scanning CI workflow'
cmp_anchor 13d-baseline-review-f050-byte-identical             same   'BASELINE-REVIEW: F050'
cmp_anchor 13e-equal-base-and-head-narrowing-byte-identical    same   '**The py split, verified at the pinned tag'
cmp_anchor 13f-equal-base-and-head-consequence-byte-identical  same   'What this changes about the item'
cmp_anchor 13g-assumes-msrv-policy-byte-identical              same   '- assumes msrv-policy = '
cmp_anchor 13h-assumes-rust-edition-byte-identical             same   '- assumes rust-edition = '
cmp_anchor 13i-assumes-target-os-matrix-byte-identical         same   '- assumes target-os-matrix = '
cmp_anchor 13j-assumes-license-byte-identical                  same   '- assumes license = '
cmp_anchor 13k-provenance-advantage-rewritten                  differ '**Shape C'
moved_anchor 13l-provenance-diagnosis-reopened-for-the-new-tool \
  '**The command is environment-dependent' '**The provenance command revision 6 used was environment-dependent'
cmp_anchor 13m-validity-filter-finding-rewritten               differ '**The finding that changes the design.**'
moved_anchor 13n-part-2-recommendation-replaced-by-the-owners-ruling \
  '**Part 2 — implement it with the Kingfisher CLI' '**Part 2 — implement it with the TruffleHog OSS CLI'
moved_anchor 13o-ranked-runner-up-replaced-by-the-owners-ruling \
  'The ranked runner-up is the **TruffleHog OSS CLI' 'The ranked runner-up is the **Kingfisher CLI'
echo "   Nine rows are asserted byte-identical to revision 2 and five are asserted to have moved:"
echo "   two rewritten in place (13k, 13m) and three whose opening words the ruling or its"
echo "   consequences replaced (13l, 13n, 13o). Asserting the change rather than permitting it"
echo "   means no later revision can restate any of these five as preserved."
if [ "$HAVE_GIT" = no ]; then
  skip 13q-the-carried-copy-is-byte-identical-to-git-history-at-that-commit "no .git directory here (a clean archive extraction); the carried copy was checked by digest in 13a"
else
  "$GIT_BIN" -C "$GIT_ROOT" show "$REV2_COMMIT:$RUN_REL/review/DECISION.md" > "$WORK/rev2-from-git.md" 2>"$WORK/rev2.err" \
    || { echo "-- git show failed:"; "$SED" -n '1,3p' "$WORK/rev2.err"; : > "$WORK/rev2-from-git.md"; }
  GIT_SHA=$("$SHASUM" -a 256 < "$WORK/rev2-from-git.md" | cut -d' ' -f1)
  echo "-- revision 2 read from git at $REV2_COMMIT, sha256: $GIT_SHA"
  assert 13q-the-carried-copy-is-byte-identical-to-git-history-at-that-commit "$REV2_SHA" "$GIT_SHA"
fi

printf '\nsummary: PASS=%d FAIL=%d SKIP=%d\n' "$PASS" "$FAIL" "$SKIP"
if [ "$FAIL" -eq 0 ]; then echo "RESULT: PASS"; exit 0; else echo "RESULT: FAIL"; exit 1; fi
