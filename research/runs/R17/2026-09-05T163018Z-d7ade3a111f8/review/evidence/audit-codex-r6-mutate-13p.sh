#!/usr/bin/env bash
# R17 secret-scanning-ci-workflow — empirical verification of the raw reports' claims (revision 6).
# This script VERIFIES CLAIMS. It builds no workflow, no template and no repository scaffold.
# Fixtures are throwaway directories created under $TMPDIR at runtime and deleted at the end;
# the scanner binary is cached outside the run directory.
#
# Synthetic credentials: the fixtures contain deterministically generated, non-live strings shaped
# like a GitHub PAT and an AWS key pair. They are never printed in full — scans run with --redact
# and only summary lines are echoed — so this log carries no secret-shaped text of its own.
#
# ---------------------------------------------------------------------------------------------
# EVERY ENVIRONMENTAL DEPENDENCY THIS SCRIPT HAS, DECLARED HERE AND PROBED IN SECTION 00.
# Revision 5 of this check was rejected because two of them were ambient: it read the caller's
# $HOME (for the two source-repository paths) and it inherited whatever `gh` login the caller
# happened to hold, so an assertion could pass on the author's machine for a reason the recorded
# command never named. Nothing below is read from the caller implicitly. Each dependency is
# probed, printed, and either exercised or SKIPped by name — never silently passed.
#
#   HOME              NOT USED. This script exports HOME=$WORK/home, a fresh empty directory under
#                     $TMPDIR, before any check runs. The caller's HOME is printed and never read.
#   PY_REPO           Declared input. Path to a py-launch-blueprint clone containing commit $PY_PIN.
#                     Absent  -> section 01 SKIPs by name. There is no $HOME-derived default.
#   TS_REPO           Declared input. Path to a ts-launch-blueprint clone containing commit $TS_PIN.
#                     Absent  -> section 02 SKIPs by name. There is no $HOME-derived default.
#   R17_GH_TOKEN      Declared input (falls back to GH_TOKEN, then GITHUB_TOKEN). A GitHub API
#   / GH_TOKEN        token. Supplied -> the GitHub API transport is authenticated and
#   / GITHUB_TOKEN    `gh attestation verify` can run (07a, 07d, 07e, 07f). Absent -> the transport
#                     is anonymous (60 requests/hour) and 07a/07d/07e/07f SKIP by name. Section 00
#                     asserts which of the two branches is in force, so an ambient login cannot
#                     turn a control into a pass. The token is never printed.
#   network egress    api.github.com, raw.githubusercontent.com, github.com release downloads,
#                     crates.io, and (for 07) tuf-repo-cdn.sigstore.dev / tuf-repo.github.com.
#                     Probed once; absent -> every network section SKIPs by name.
#   a gh CLI binary   Resolved by probing candidates under this script's own empty environment and
#                     keeping only one whose realpath is named `gh` and whose --version begins
#                     "gh version". A version-manager shim (mise/asdf/rtx) is rejected, not used as
#                     a fallback: revision 4 was rejected because such a shim aborted before the gh
#                     CLI started and the control reported a number that said nothing about
#                     authentication. Override with GH_BIN. Unresolved -> 07a-07i SKIP by name.
#   Darwin arm64      Sections that EXECUTE the downloaded macOS binary (07b, 07c, 08, 09, 10b,
#                     10c, 10e, 10f, 10g, 12c-12e) need `uname -s` = Darwin and `uname -m` = arm64.
#                     Other platforms SKIP those by name; every other section still runs.
#   .git history      NEEDED BY EXACTLY ONE ASSERTION, 13p, which checks the carried revision-2
#                     copy against git history. Section 13's fifteen other assertions read the
#                     carried copy and this decision by path and need no repository, so a clean
#                     `git archive HEAD` extraction runs the whole of section 13 except 13p, which
#                     SKIPs by name and can never mask a failure.
#   /usr/bin/grep     Every count below is produced by /usr/bin/grep by absolute path, named in
#                     section 00 and beside each printed count. A typed `grep` in an agent shell
#                     can be ugrep, which honours .gitignore and would silently undercount.
#   helper toolchain  python3, curl, git, tar, shasum, awk and sed are each resolved by PROBING
#                     candidates (`command -v`, then /opt/homebrew/bin, /usr/local/bin, /usr/bin,
#                     /bin) and keeping the first that actually performs a small operation, because
#                     a version-manager shim standing first on PATH fails under this script's own
#                     empty $HOME and would take every parse and count down with it. The resolved
#                     paths are printed; 00c asserts that the five without which nothing can run
#                     (python3, curl, shasum, awk, sed) resolved. The remaining POSIX utilities
#                     (head, tail, wc, cut, tr, basename, mktemp, env, id, uname, date, chmod,
#                     mkdir, cp, rm, ls, cat) are taken from PATH; none is version-manager-shimmed.
#
# Two rerun modes, both recorded in the decision:
#   repository : cd <repo>/research/runs/R17/<run>/review/empirical && \
#                GH_TOKEN=<token> PY_REPO=<path> TS_REPO=<path> bash run-checks-r6.sh
#   clean copy : git archive --format=tar HEAD | tar -xf - -C <dir> && \
#                cd <dir>/research/runs/R17/<run>/review/empirical && bash run-checks-r6.sh
#                (adding the declared inputs above runs the identical set bar 13p)
#
# Usage: bash run-checks-r6.sh    (exit 0 = no assertion FAILed; SKIPs are printed by name)
# ---------------------------------------------------------------------------------------------

set -u
set -o pipefail

GREP=/usr/bin/grep        # absolute path on purpose: see the declaration block above

PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TS_PIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
TH_TAG=v3.95.9            # the TruffleHog action tag py pins
KF_TAG=v2.2.0             # the Kingfisher release under test
GHDOCS_PIN=078b5832caa5cde591c2babb389ef447a0ef66eb   # github/docs, resolved from main 2026-09-12;
                          # pinned because assertions 10h-10i read it, and a docs reorg on a moving
                          # ref would turn them into failures rather than a printed drift
UA='User-Agent: rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'

# --- declared inputs, captured BEFORE HOME is replaced -----------------------------------------
CALLER_HOME="${HOME:-unset}"
PY_REPO_IN="${PY_REPO:-}"          # no $HOME default: an undeclared repository is a SKIP, not a pass
TS_REPO_IN="${TS_REPO:-}"
GH_TOKEN_IN="${R17_GH_TOKEN:-${GH_TOKEN:-${GITHUB_TOKEN:-}}}"
GH_BIN_IN="${GH_BIN:-}"
KF_DIR="${KF_DIR:-${TMPDIR:-/tmp}/r17-kingfisher}"

# --- paths resolved from this script's own location, never from git ----------------------------
# Section 13 reads the carried revision-2 copy and this decision by path, so it works identically
# inside a repository and inside a `git archive` extraction that has no .git directory at all.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEC_NOW="${DEC_NOW:-$RUN_DIR/DECISION.md}"
REV2_FILE="${REV2_FILE:-$SCRIPT_DIR/rev2-DECISION.md}"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/r17-work.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/home" "$WORK/noauth-home"
export HOME="$WORK/home"           # the caller's HOME is never read by anything below
NOAUTH_HOME="$WORK/noauth-home"    # a second empty home, used only by the 07g-07i controls
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

# --- the helper toolchain, resolved explicitly rather than taken from PATH -----------------------
# A version-manager shim standing first on PATH is not only a gh problem: with this script's own
# empty $HOME in force, a mise/asdf/rtx shim for python3 fails before the interpreter starts, and
# every JSON parse, probe and count downstream of it fails with it. Each helper is therefore probed
# by DOING something with it and the first candidate that actually works is used; the resolved
# paths are printed, so the log says which binary produced every figure in it.
tool_ok() { # tool_ok <path> <tool name>
  case "$2" in
    python3) [ "$("$1" -c 'print(7*6)' 2>/dev/null)" = 42 ] ;;
    curl|git|tar|shasum) "$1" --version >/dev/null 2>&1 ;;
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

say "00 declared inputs, environment probes, and the toolchain"
echo "-- counting binary for every count below: $GREP ($("$GREP" --version 2>/dev/null | head -1))"
echo "-- helper toolchain resolved by probing each candidate, not by PATH order alone:"
printf '   python3=%s curl=%s git=%s tar=%s shasum=%s awk=%s sed=%s\n' \
  "${PY3:-none}" "${CURL:-none}" "${GIT_BIN:-none}" "${TAR:-none}" "${SHASUM:-none}" "${AWK:-none}" "${SED:-none}"
report_bypass() { # report_bypass <name> <resolved path> — prints when PATH order was overruled
  local first; first=$(command -v "$1" 2>/dev/null || echo none)
  if [ "$first" != none ] && [ "$first" != "${2:-}" ]; then
    echo "   $1 first on PATH was BYPASSED: $first (it failed this script's probe for $1 under the empty HOME in force)"
  fi
}
report_bypass python3 "$PY3"; report_bypass curl "$CURL"; report_bypass git "$GIT_BIN"
report_bypass tar "$TAR"; report_bypass shasum "$SHASUM"; report_bypass awk "$AWK"; report_bypass sed "$SED"
RESOLVED=""
for t in "$PY3" "$CURL" "$SHASUM" "$AWK" "$SED"; do [ -n "$t" ] && RESOLVED="$RESOLVED$(basename "$t") "; done
assert 00c-the-helper-toolchain-this-script-cannot-run-without-resolved "python3 curl shasum awk sed " "$RESOLVED"
echo "-- caller HOME (recorded, NOT used): $CALLER_HOME"
echo "-- HOME used by this run: $HOME"
HOME_UNDER_WORK=0; case "$HOME" in "$WORK"/*) HOME_UNDER_WORK=1 ;; esac
HOME_ENTRIES=$(ls -A "$HOME" | wc -l | tr -d ' ')
assert 00a-home-is-this-scripts-own-empty-scratch-directory "1 0" "$HOME_UNDER_WORK $HOME_ENTRIES"

# platform
UNAME_S=$(uname -s); UNAME_M=$(uname -m)
KF_PLATFORM=no; [ "$UNAME_S" = Darwin ] && [ "$UNAME_M" = arm64 ] && KF_PLATFORM=yes

# git history — needed by 13p only
HAVE_GIT=no
if [ -n "$GIT_BIN" ] && "$GIT_BIN" -C "$SCRIPT_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
  HAVE_GIT=yes
  GIT_ROOT=$("$GIT_BIN" -C "$SCRIPT_DIR" rev-parse --show-toplevel)
else
  GIT_ROOT=none
fi

# declared source repositories: present only if the pinned commit is actually reachable there
HAVE_PY=no
if [ -n "$PY_REPO_IN" ] && "$GIT_BIN" -C "$PY_REPO_IN" cat-file -e "$PY_PIN^{commit}" 2>/dev/null; then HAVE_PY=yes; fi
HAVE_TS=no
if [ -n "$TS_REPO_IN" ] && "$GIT_BIN" -C "$TS_REPO_IN" cat-file -e "$TS_PIN^{commit}" 2>/dev/null; then HAVE_TS=yes; fi

# network + which API transport is in force. /rate_limit is not itself rate-limited, and its
# core limit is the discriminator: 60 is the anonymous ceiling, anything above it means a
# credential reached the transport. That is asserted, so an ambient login cannot go unrecorded.
HAVE_NET=no; GH_AUTH=none; CORE_LIMIT=0; CORE_REMAIN=0
if [ -n "$GH_TOKEN_IN" ]; then
  "$CURL" -sS --max-time 30 -H "Authorization: Bearer $GH_TOKEN_IN" -H "$UA" \
    https://api.github.com/rate_limit -o "$WORK/rl.json" 2>"$WORK/rl.err" && GH_AUTH=token
fi
if [ "$GH_AUTH" = none ]; then
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
gh_probe() { env -i PATH="$PATH" HOME="$NOAUTH_HOME" "$1" --version 2>/dev/null | head -1; }
GH_REAL=""; GH_REAL_V=""; GH_REAL_BASE=""; GH_REAL_STARTS=no
for c in $GH_BIN_IN /opt/homebrew/bin/gh /usr/local/bin/gh /usr/bin/gh /home/linuxbrew/.linuxbrew/bin/gh "$(command -v gh 2>/dev/null || true)"; do
  { [ -n "$c" ] && [ -x "$c" ]; } || continue
  c_real=$(realpath_of "$c"); c_v=$(gh_probe "$c")
  case "$c_v" in
    "gh version"*) : ;;
    *) echo "   candidate $c -> $c_real: does not start the gh CLI under an empty environment; rejected" ; continue ;;
  esac
  if [ "$(basename "$c_real")" != gh ]; then
    echo "   candidate $c -> $c_real: a version-manager launcher rather than the gh binary; rejected"
    continue
  fi
  GH_REAL="$c"; GH_REAL_V="$c_v"; GH_REAL_BASE=$(basename "$c_real"); GH_REAL_STARTS=yes; break
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

printf -- '-- MODE: PY_REPO=%s TS_REPO=%s token=%s network=%s api-transport=%s gh-cli=%s platform=%s/%s kingfisher-executable=%s git-history=%s\n' \
  "$( [ "$HAVE_PY" = yes ] && echo set || echo unset )" \
  "$( [ "$HAVE_TS" = yes ] && echo set || echo unset )" \
  "$( [ -n "$GH_TOKEN_IN" ] && echo supplied || echo absent )" \
  "$HAVE_NET" "$GH_AUTH" "${GH_REAL:-none}" "$UNAME_S" "$UNAME_M" "$KF_PLATFORM" "$HAVE_GIT"
echo "   git toplevel: $GIT_ROOT"
echo "   PY_REPO=${PY_REPO_IN:-<undeclared>}  TS_REPO=${TS_REPO_IN:-<undeclared>}"
echo "   decision under review: $DEC_NOW"
echo "   carried revision 2:    $REV2_FILE"

# one asserted precondition per authentication branch, so the branch in force is evidence
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
bash --version | head -1   # section 12 executes two shells, so the shell's own version is recorded
if [ -n "$GH_REAL" ]; then echo "gh: $GH_REAL_V ($GH_REAL)"; else echo "gh: no gh CLI resolved"; fi
"$CURL" --version | head -1
"$PY3" --version
date -u +'UTC now: %Y-%m-%dT%H:%M:%SZ'

say "01 py secret-scan workflow at pin $PY_PIN (read through the pin, not the worktree)"
if [ "$HAVE_PY" = no ]; then
  echo "-- PY_REPO is not declared, or does not contain $PY_PIN. Rerun with PY_REPO=<clone path>."
  skip 01a-py-comment-names-the-tool-error "PY_REPO undeclared or missing commit $PY_PIN"
  skip 01b-py-pins-trufflehog-v3.95.9 "PY_REPO undeclared or missing commit $PY_PIN"
else
  "$GIT_BIN" -C "$PY_REPO_IN" show "$PY_PIN:.github/workflows/secret-scan.yml"
  GUARD_CITED=$("$GIT_BIN" -C "$PY_REPO_IN" show "$PY_PIN:.github/workflows/secret-scan.yml" \
    | "$GREP" -c 'BASE and HEAD commits are')
  echo "-- count via $GREP: $GUARD_CITED"
  assert 01a-py-comment-names-the-tool-error 1 "$GUARD_CITED"
  TH_PIN_USED=$("$GIT_BIN" -C "$PY_REPO_IN" show "$PY_PIN:.github/workflows/secret-scan.yml" \
    | "$GREP" -c 'trufflesecurity/trufflehog@v3.95.9')
  echo "-- count via $GREP: $TH_PIN_USED"
  assert 01b-py-pins-trufflehog-v3.95.9 1 "$TH_PIN_USED"
fi

say "02 ts workflow inventory at pin $TS_PIN — no CI-tier secret scanner"
if [ "$HAVE_TS" = no ]; then
  echo "-- TS_REPO is not declared, or does not contain $TS_PIN. Rerun with TS_REPO=<clone path>."
  skip 02a-ts-has-no-ci-secret-scanner "TS_REPO undeclared or missing commit $TS_PIN"
else
  "$GIT_BIN" -C "$TS_REPO_IN" ls-tree -r --name-only "$TS_PIN" .github/workflows/
  TS_HITS=0
  for f in $("$GIT_BIN" -C "$TS_REPO_IN" ls-tree -r --name-only "$TS_PIN" .github/workflows/); do
    n=$("$GIT_BIN" -C "$TS_REPO_IN" show "$TS_PIN:$f" \
        | "$GREP" -icE 'trufflehog|gitleaks|kingfisher|detect-secrets|secret-scan' || true)
    TS_HITS=$((TS_HITS + n))
  done
  echo "-- count via $GREP across every workflow file: $TS_HITS"
  assert 02a-ts-has-no-ci-secret-scanner 0 "$TS_HITS"
  echo "-- manual-pr-security-scan.yml is an OSV dependency scan, not a secret scanner:"
  "$GIT_BIN" -C "$TS_REPO_IN" show "$TS_PIN:.github/workflows/manual-pr-security-scan.yml" \
    | "$GREP" -nE 'on:|workflow_dispatch|osv-scanner|environment' | head -8
fi

say "03 TruffleHog action.yml at $TH_TAG — the equal-base/head guard and the container call"
if [ "$HAVE_NET" = no ]; then
  skip 03a-guard-exists-at-tag "no network egress"
  skip 03b-action-shells-out-to-docker "no network egress"
  skip 03c-action-is-composite-not-container "no network egress"
else
  "$CURL" -sSL --max-time 60 "https://raw.githubusercontent.com/trufflesecurity/trufflehog/$TH_TAG/action.yml" -o "$WORK/action.yml"
  "$SHASUM" -a 256 "$WORK/action.yml"
  echo "-- guard:"
  "$GREP" -n -A2 'if \[ "\$base_commit" == "\$head_commit" \]' "$WORK/action.yml"
  echo "-- the guard is entered only when base or head is non-empty:"
  "$GREP" -n 'if \[ -n "\$BASE" \] || \[ -n "\$HEAD" \]' "$WORK/action.yml"
  echo "-- the action's own else-branch derives the range from the event, incl. the all-zeros first push:"
  "$GREP" -n -A6 'github.event_name }}" == "push"' "$WORK/action.yml" | head -12
  echo "-- terminal command:"
  "$GREP" -n -A3 'docker run --rm' "$WORK/action.yml"
  GUARD=$("$GREP" -c 'BASE and HEAD commits are the same' "$WORK/action.yml")
  DOCKER=$("$GREP" -c 'docker run --rm' "$WORK/action.yml")
  COMPOSITE=$("$GREP" -c 'using: "composite"' "$WORK/action.yml")
  echo "-- counts via $GREP: guard=$GUARD docker=$DOCKER composite=$COMPOSITE"
  assert 03a-guard-exists-at-tag 1 "$GUARD"
  assert 03b-action-shells-out-to-docker 1 "$DOCKER"
  assert 03c-action-is-composite-not-container 1 "$COMPOSITE"
fi

# --- the GitHub REST transport, declared rather than ambient -----------------------------------
# Six endpoints, each fetched exactly once into $WORK and parsed from the saved file, so the
# anonymous branch spends six of its sixty hourly requests rather than the fifteen revision 5
# spent through repeated `gh api` calls.
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

say "04 incumbent repository figures (transport: $GH_AUTH)"
if [ "$HAVE_NET" = no ]; then
  skip 04a-trufflehog-cli-license-agpl "no network egress"
  skip 04b-gitleaks-action-license-not-osi "no network egress"
else
  api_fetch repos/trufflesecurity/trufflehog "$WORK/th.json"
  "$PY3" - "$WORK/th.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
print({k:d.get(k) for k in ["full_name","stargazers_count","archived","pushed_at"]},
      "license:", (d.get("license") or {}).get("spdx_id"))
PY
  api_fetch repos/trufflesecurity/trufflehog/releases "$WORK/th-rel.json"
  "$PY3" - "$WORK/th-rel.json" <<'PY'
import json,sys
for r in json.load(open(sys.argv[1]))[:3]: print(r["tag_name"], r["published_at"])
PY
  TH_LICENSE=$(jget "$WORK/th.json" license.spdx_id)
  assert 04a-trufflehog-cli-license-agpl AGPL-3.0 "$TH_LICENSE"
  api_fetch repos/gitleaks/gitleaks-action "$WORK/gla.json"
  "$PY3" - "$WORK/gla.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
print({k:d.get(k) for k in ["full_name","stargazers_count","pushed_at"]},
      "license:", (d.get("license") or {}).get("spdx_id"))
PY
  GLA_LICENSE=$(jget "$WORK/gla.json" license.spdx_id)
  assert 04b-gitleaks-action-license-not-osi NOASSERTION "$GLA_LICENSE"
  "$CURL" -sSL --max-time 60 -H "$UA" https://raw.githubusercontent.com/gitleaks/gitleaks-action/master/README.md \
    | "$GREP" -nE 'GITLEAKS_LICENSE \(required|license has changed from MIT' | head -4
fi

say "05 Kingfisher repository, release assets, manifest and its own CI runners"
if [ "$HAVE_NET" = no ]; then
  for l in 05a-kingfisher-not-archived 05b-kingfisher-license-apache 05c-macos-release-assets-exist 05d-linux-release-assets-exist; do
    skip "$l" "no network egress"
  done
else
  api_fetch repos/mongodb/kingfisher "$WORK/kf.json"
  "$PY3" - "$WORK/kf.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
print({k:d.get(k) for k in ["full_name","stargazers_count","archived","created_at","pushed_at","language"]},
      "license:", (d.get("license") or {}).get("spdx_id"))
PY
  api_fetch repos/mongodb/kingfisher/releases "$WORK/kf-rel.json"
  "$PY3" - "$WORK/kf-rel.json" <<'PY'
import json,sys
for r in json.load(open(sys.argv[1]))[:4]: print(r["tag_name"], r["published_at"])
PY
  api_fetch "repos/mongodb/kingfisher/releases/tags/$KF_TAG" "$WORK/kf-tag.json"
  "$PY3" - "$WORK/kf-tag.json" <<'PY'
import json,sys
for a in json.load(open(sys.argv[1]))["assets"]: print(a["name"], a["size"])
PY
  KF_ARCHIVED=$(jget "$WORK/kf.json" archived)
  KF_LICENSE=$(jget "$WORK/kf.json" license.spdx_id)
  KF_DARWIN=$("$PY3" -c 'import json,sys;print(len([a for a in json.load(open(sys.argv[1]))["assets"] if a["name"].startswith("kingfisher-darwin")]))' "$WORK/kf-tag.json")
  KF_LINUX=$("$PY3" -c 'import json,sys;print(len([a for a in json.load(open(sys.argv[1]))["assets"] if a["name"].startswith("kingfisher-linux")]))' "$WORK/kf-tag.json")
  assert 05a-kingfisher-not-archived false "$KF_ARCHIVED"
  assert 05b-kingfisher-license-apache Apache-2.0 "$KF_LICENSE"
  assert 05c-macos-release-assets-exist 2 "$KF_DARWIN"
  assert 05d-linux-release-assets-exist 6 "$KF_LINUX"
  echo "-- workspace manifest at $KF_TAG (the upstream 'authors' line carries a named individual's"
  echo "   email address and is suppressed here; nothing this decision asserts reads it):"
  "$CURL" -sSL --max-time 60 -H "$UA" "https://raw.githubusercontent.com/mongodb/kingfisher/$KF_TAG/Cargo.toml" -o "$WORK/KF-Cargo.toml"
  "$SED" -n '/\[workspace.package\]/,/^$/p' "$WORK/KF-Cargo.toml" | "$GREP" -v '^authors = '
  echo "-- Kingfisher's own CI runners:"
  "$CURL" -sSL --max-time 60 -H "$UA" "https://raw.githubusercontent.com/mongodb/kingfisher/$KF_TAG/.github/workflows/ci.yml" \
    | "$GREP" -nE 'runs-on' | head -6
  echo "-- documented exit codes and the --only-valid alias:"
  "$CURL" -sSL --max-time 60 -H "$UA" "https://raw.githubusercontent.com/mongodb/kingfisher/$KF_TAG/docs/USAGE.md" -o "$WORK/USAGE.md"
  echo "   docs/USAGE.md at $KF_TAG, sha256: $("$SHASUM" -a 256 < "$WORK/USAGE.md")"
  # The whole "## Exit Codes" section, not just its heading: an earlier range expression stopped at
  # the blank line that immediately follows the heading, so the table never reached the log.
  "$AWK" '/^## Exit Codes/{f=1} f&&/^## /&&!/^## Exit Codes/{exit} f' "$WORK/USAGE.md" | head -12
  "$GREP" -n -m2 -- '--only-valid` is a compatibility alias' "$WORK/USAGE.md"
fi

say "06 crates.io trap — 'kingfisher' on crates.io is an unrelated project"
if [ "$HAVE_NET" = no ]; then
  skip 06a-cratesio-kingfisher-is-a-different-project "no network egress"
  skip 06b-mongodb-kingfisher-is-not-published-to-cratesio "no network egress"
else
  "$CURL" -sSL --max-time 60 -H "$UA" https://crates.io/api/v1/crates/kingfisher \
    | "$PY3" -c 'import json,sys;d=json.load(sys.stdin)["crate"];print({k:d.get(k) for k in ["name","newest_version","repository","recent_downloads","downloads"]})' \
    > "$WORK/kf-crate.txt"
  cat "$WORK/kf-crate.txt"
  CRATE_REPO=$("$GREP" -c 'mongrov/kingfisher' "$WORK/kf-crate.txt")
  echo "-- count via $GREP: $CRATE_REPO"
  assert 06a-cratesio-kingfisher-is-a-different-project 1 "$CRATE_REPO"
  PUBLISH_FALSE=$("$GREP" -c '^publish = false' "$WORK/KF-Cargo.toml")
  echo "-- count via $GREP: $PUBLISH_FALSE"
  assert 06b-mongodb-kingfisher-is-not-published-to-cratesio 1 "$PUBLISH_FALSE"
fi

say "07 download the macOS release, verify its build provenance, run it"
KF_TGZ="$KF_DIR/kingfisher-darwin-arm64.tgz"
KF_HAVE_TGZ=no; KF_RUNS=no
if [ "$HAVE_NET" = yes ]; then
  mkdir -p "$KF_DIR"
  # Both artefacts are checked: an earlier form of this cache test looked only at the unpacked
  # binary, so a cache holding the binary but not the tarball skipped the download and left 07a
  # verifying a file that was not there.
  if [ ! -s "$KF_TGZ" ] || [ ! -x "$KF_DIR/kingfisher" ]; then
    "$CURL" -sSL --max-time 300 -H "$UA" -o "$KF_TGZ" \
      "https://github.com/mongodb/kingfisher/releases/download/$KF_TAG/kingfisher-darwin-arm64.tgz"
    "$TAR" xzf "$KF_TGZ" -C "$KF_DIR"
  fi
  [ -s "$KF_TGZ" ] && KF_HAVE_TGZ=yes
fi
[ "$KF_HAVE_TGZ" = yes ] && [ "$KF_PLATFORM" = yes ] && [ -x "$KF_DIR/kingfisher" ] && KF_RUNS=yes
LOCAL_DIGEST=""
if [ "$KF_HAVE_TGZ" = yes ]; then
  "$SHASUM" -a 256 "$KF_TGZ"
  LOCAL_DIGEST=$("$SHASUM" -a 256 "$KF_TGZ" | cut -d' ' -f1)
  # Fitness gate 6 wants the size stated: printed, not asserted, because it is a property of the one
  # asset this script downloads. It is a per-job CI download and never a shipped artifact.
  echo "-- release tarball bytes: $(wc -c < "$KF_TGZ" | tr -d ' '); unpacked binary bytes: $(wc -c < "$KF_DIR/kingfisher" 2>/dev/null | tr -d ' ')"
fi

# `gh attestation verify` initialises its Sigstore verifier from TUF trusted-root metadata that it
# refreshes into $XDG_CACHE_HOME/gh/.sigstore (default $HOME/.cache/gh/.sigstore). If that path is
# not writable the verifier cannot be built and gh exits 1 with
# "no valid Sigstore verifiers could be initialized" — before it looks at the artifact at all.
# Revision 1 of this check inherited whatever $HOME the caller had, so it passed in a permissive
# shell and failed under a sandbox whose writes are confined to the workspace and $TMPDIR. The
# cache is therefore redirected into $WORK, which every such sandbox can write. The command also
# needs an authenticated gh: revision 5 satisfied that from the caller's ambient login without
# declaring it, which is what round 5 rejected. It is now supplied only from the declared token,
# and without one 07a/07d/07e/07f SKIP rather than passing on state the recorded command never named.
GH_SIGSTORE_CACHE="$WORK/gh-cache"
mkdir -p "$GH_SIGSTORE_CACHE"
ATT_READY=no
if [ "$KF_HAVE_TGZ" = yes ] && [ -n "$GH_REAL" ] && [ "$GH_AUTH" = token ]; then ATT_READY=yes; fi
if [ "$ATT_READY" = no ]; then
  echo "-- provenance verification not attempted. tarball=$KF_HAVE_TGZ gh-cli=${GH_REAL:-none} token=$GH_AUTH"
  echo "   Rerun with a declared token to execute it: R17_GH_TOKEN=<token> bash $(basename "$0")"
  for l in 07a-slsa-provenance-verifies 07d-attested-subject-digest-equals-the-downloaded-file \
           07e-signer-workflow-observed-in-certificate 07f-verifier-fails-without-a-writable-sigstore-cache; do
    skip "$l" "needs the release tarball, a resolved gh CLI and a DECLARED token (tarball=$KF_HAVE_TGZ gh=${GH_REAL:-none} token=$GH_AUTH)"
  done
else
  env -i PATH="$PATH" HOME="$HOME" XDG_CACHE_HOME="$GH_SIGSTORE_CACHE" GH_TOKEN="$GH_TOKEN_IN" \
    "$GH_REAL" attestation verify "$KF_TGZ" --repo mongodb/kingfisher --format json \
    > "$WORK/att.json" 2>"$WORK/att.err"
  ATT_EXIT=$?
  assert 07a-slsa-provenance-verifies 0 "$ATT_EXIT"
  ATT_DIGEST=""; ATT_SIGNER=""
  if [ -s "$WORK/att.json" ]; then
    "$PY3" - "$WORK/att.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
c=d[0]["verificationResult"]["signature"]["certificate"]
s=d[0]["verificationResult"]["statement"]["subject"][0]
print("attestations:",len(d))
print("subject:", s["name"], s["digest"])
print({k:c.get(k) for k in ["sourceRepositoryURI","sourceRepositoryDigest","buildSignerURI","runnerEnvironment"]})
PY
    ATT_DIGEST=$("$PY3" -c 'import json,sys;print(json.load(open(sys.argv[1]))[0]["verificationResult"]["statement"]["subject"][0]["digest"]["sha256"])' "$WORK/att.json")
    ATT_SIGNER=$("$PY3" -c 'import json,sys;print(json.load(open(sys.argv[1]))[0]["verificationResult"]["signature"]["certificate"]["buildSignerURI"])' "$WORK/att.json")
  else
    echo "-- gh produced no attestation JSON; its stderr follows:"
    "$SED" -n '1,10p' "$WORK/att.err"
  fi
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
    env -i PATH="$PATH" HOME="$HOME" XDG_CACHE_HOME="$RO_CACHE" GH_TOKEN="$GH_TOKEN_IN" \
      "$GH_REAL" attestation verify "$KF_TGZ" --repo mongodb/kingfisher --format json \
      > "$WORK/att-ro.json" 2>"$WORK/att-ro.err"
    RO_EXIT=$?
    chmod 700 "$RO_CACHE"
    echo "   gh stderr (wording is this gh build's):"; "$SED" -n '1,3p' "$WORK/att-ro.err"
    RO_MSG=$("$GREP" -c 'no valid Sigstore verifiers could be initialized' "$WORK/att-ro.err")
    echo "   count via $GREP: $RO_MSG"
    assert 07f-verifier-fails-without-a-writable-sigstore-cache "1 1" "$RO_EXIT $RO_MSG"
  fi
fi

if [ "$KF_RUNS" = no ]; then
  skip 07b-macos-binary-runs "needs a Darwin arm64 host with the unpacked binary (platform=$UNAME_S/$UNAME_M tarball=$KF_HAVE_TGZ)"
  skip 07c-rules-listed-and-counted "needs a Darwin arm64 host with the unpacked binary (platform=$UNAME_S/$UNAME_M tarball=$KF_HAVE_TGZ)"
else
  KF_VERSION=$("$KF_DIR/kingfisher" --version | tr -d '\n')
  echo "-- macOS execution: $KF_VERSION"
  assert 07b-macos-binary-runs "kingfisher 2.2.0" "$KF_VERSION"
  RULE_COUNT=$("$KF_DIR/kingfisher" rules list --format json 2>/dev/null | "$PY3" -c 'import json,sys;print(len(json.load(sys.stdin)))')
  echo "-- built-in rules listed: $RULE_COUNT (total rules; the listing exposes no validator flag,"
  echo "   so this is NOT comparable to TruffleHog's stated 700+ actively-verifying detectors)"
  assert 07c-rules-listed-and-counted 485 "$RULE_COUNT"
fi

echo "-- second prerequisite: the command needs an authenticated gh, so P03's install step needs a token."
# This control has to demonstrate gh REFUSING FOR WANT OF AUTHENTICATION, and a control that exits
# non-zero for some other reason is indistinguishable from it in a summary line. Revision 4 asserted
# the exit code 4 after invoking whatever `gh` PATH resolved, and its audit reran it on a host where
# `gh` on PATH is a mise shim: the empty environment made the shim re-read a configuration it no
# longer trusts, so it aborted with exit 1 before the gh CLI started at all — a control failing for
# the wrong reason, which proves nothing about authentication. The gh CLI is therefore resolved once
# in section 00, launchers are rejected rather than used as a fallback, and the control asserts the
# REFUSAL (a failing exit, gh's own `gh auth login` remedy, no attestation written) rather than an
# exit number. The number is then compared against the resolved gh's own documentation.
if [ -z "$GH_REAL" ] || [ "$KF_HAVE_TGZ" = no ]; then
  echo "   no gh CLI resolved under an empty environment, or no artifact to name, so a non-zero exit"
  echo "   here would say nothing about authentication. The prerequisite is unproven on this host and"
  echo "   stands on gh's own documentation (gh help exit-codes) until the control is rerun elsewhere."
  skip 07g-the-resolved-gh-is-the-cli-itself-not-a-launcher "no gh CLI starts under an empty environment on this host"
  skip 07h-unauthenticated-verify-is-refused-for-want-of-authentication "no gh CLI resolved, or no release tarball to verify"
  skip 07i-the-refusal-exit-matches-ghs-own-documented-authentication-code "no gh CLI resolved, or no release tarball to verify"
else
  echo "   gh CLI used for this control: $GH_REAL -> $(realpath_of "$GH_REAL") (reports '$GH_REAL_V')"
  # Falsifiable on a launcher-only host: the realpath basename must be gh and --version must begin
  # "gh version" under the empty environment the control itself uses.
  assert 07g-the-resolved-gh-is-the-cli-itself-not-a-launcher "gh yes" "$GH_REAL_BASE $GH_REAL_STARTS"
  env -i PATH="$PATH" HOME="$NOAUTH_HOME" \
    "$GH_REAL" attestation verify "$KF_TGZ" --repo mongodb/kingfisher --format json \
    > "$WORK/att-noauth.json" 2>"$WORK/att-noauth.err"
  NOAUTH_EXIT=$?
  echo "   gh stderr (wording is this gh build's):"; "$SED" -n '1,2p' "$WORK/att-noauth.err"
  NOAUTH_MSG=$("$GREP" -c 'gh auth login' "$WORK/att-noauth.err")
  NOAUTH_ATT=$(wc -c < "$WORK/att-noauth.json" | tr -d ' ')
  NOAUTH_FAILED=0; [ "$NOAUTH_EXIT" -ne 0 ] && NOAUTH_FAILED=1
  echo "   refused=$NOAUTH_FAILED (observed exit $NOAUTH_EXIT), 'gh auth login' in stderr=$NOAUTH_MSG (count via $GREP), attestation bytes written=$NOAUTH_ATT"
  assert 07h-unauthenticated-verify-is-refused-for-want-of-authentication "1 1 0" "$NOAUTH_FAILED $NOAUTH_MSG $NOAUTH_ATT"
  # The exit NUMBER is read from the resolved gh's own documentation rather than written into this
  # script, so the assertion compares the tool against itself; a gh build that changed the code would
  # move both sides together, and an unreadable topic skips loudly instead of passing on a literal.
  DOC_CODE=$(env -i PATH="$PATH" HOME="$NOAUTH_HOME" "$GH_REAL" help exit-codes 2>/dev/null \
    | "$SED" -n 's/.*requires authentication, the exit code will be \([0-9][0-9]*\).*/\1/p' | head -1)
  if [ -z "$DOC_CODE" ]; then
    skip 07i-the-refusal-exit-matches-ghs-own-documented-authentication-code "this gh build ships no 'help exit-codes' topic in the form this check reads"
  else
    echo "   gh help exit-codes documents $DOC_CODE for a command that requires authentication"
    assert 07i-the-refusal-exit-matches-ghs-own-documented-authentication-code "$DOC_CODE" "$NOAUTH_EXIT"
  fi
fi

say "08 verified-only behaviour on non-live, template-shaped credentials (fixture A)"
if [ "$KF_RUNS" = no ]; then
  for l in 08a-only-valid-empties-the-report 08b-but-exit-code-is-still-200-not-0 \
           08c-pretty-summary-counts-the-filtered-candidate 08d-pretty-run-exit-also-200; do
    skip "$l" "needs the Kingfisher binary running on this host (platform=$UNAME_S/$UNAME_M)"
  done
else
  "$PY3" - "$WORK/fixA" <<'PY'
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
  "$GREP" -E 'Findings|Validations|Rules Applied|Blobs Scanned' "$WORK/fixA.pretty"
  "$PY3" - "$WORK/fixA.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
print("json report findings array length:", len(d["findings"]))
print("json summary:", {k:d["metadata"]["summary"][k] for k in
  ["findings","active_findings","successful_validations","failed_validations","rules_applied"]})
PY
  A_JSON=$("$PY3" -c 'import json,sys;print(len(json.load(open(sys.argv[1]))["findings"]))' "$WORK/fixA.json")
  assert 08a-only-valid-empties-the-report 0 "$A_JSON"
  assert 08b-but-exit-code-is-still-200-not-0 200 "$A_EXIT"
  echo "-- same scan, same flags, pretty format instead of json:"
  "$KF_DIR/kingfisher" scan "$WORK/fixA" --only-valid --redact --no-update-check \
    > "$WORK/fixA.pretty2" 2>&1
  A2_EXIT=$?
  "$GREP" -E '^ \|Findings|^ \|__Successful|^ \|__Failed' "$WORK/fixA.pretty2"
  A2_COUNT=$("$GREP" -cE '^ \|Findings\.+: 1$' "$WORK/fixA.pretty2")
  echo "   count via $GREP: $A2_COUNT"
  assert 08c-pretty-summary-counts-the-filtered-candidate 1 "$A2_COUNT"
  assert 08d-pretty-run-exit-also-200 200 "$A2_EXIT"
  echo "   The two formats disagree for one scan: pretty prints the pre-filter count (1),"
  echo "   the JSON report prints the post-filter count (0). A gate must read the exit code"
  echo "   or the JSON/SARIF findings array, never the pretty summary."
fi

say "09 full-history scanning with no --since-commit (fixture B)"
if [ "$KF_RUNS" = no ] || [ -z "$GIT_BIN" ]; then
  skip 09a-history-scan-finds-deleted-blob-without-since-commit "needs the Kingfisher binary and a working git on this host"
  skip 09b-exactly-one-history-finding "needs the Kingfisher binary and a working git on this host"
else
  mkdir -p "$WORK/fixB" && cd "$WORK/fixB" || exit 1
  "$GIT_BIN" init -q .
  "$GIT_BIN" config user.email r17@example.invalid
  "$GIT_BIN" config user.name r17
  "$PY3" -c "
import random,string
random.seed(99)
tok='ghp_'+''.join(random.choice(string.ascii_letters+string.digits) for _ in range(36))
open('leak.txt','w').write('token='+tok+'\n')
print('fixture B: one synthetic PAT-shaped value committed then deleted (value not printed)')
"
  "$GIT_BIN" add -A && "$GIT_BIN" commit -qm "add synthetic token"
  rm leak.txt && "$GIT_BIN" commit -qam "remove synthetic token"
  echo "-- working tree after deletion:"; ls -A | "$GREP" -v '^\.git$' || echo "(no tracked files remain)"
  "$KF_DIR/kingfisher" scan . --redact --no-update-check > "$WORK/fixB.pretty" 2>&1
  B_EXIT=$?
  "$GREP" -E 'Findings|Validations|Blobs Scanned' "$WORK/fixB.pretty"
  assert 09a-history-scan-finds-deleted-blob-without-since-commit 200 "$B_EXIT"
  B_FIND=$("$GREP" -cE '^ \|Findings\.+: 1$' "$WORK/fixB.pretty")
  echo "   count via $GREP: $B_FIND"
  assert 09b-exactly-one-history-finding 1 "$B_FIND"
  cd "$WORK" || exit 1
fi

say "10 the documented exit-code set, and the codes outside it"
# The gate rule this decision states is an allow-list, so two things have to be executed rather than
# asserted: that the documented set is exactly what the decision names, and that codes outside it are
# reachable — which is what makes a gate written as "fail on 205" fail open when the scanner never ran.
if [ "$HAVE_NET" = no ]; then
  skip 10a-documented-exit-code-set-is-exactly-0-200-205 "no network egress: docs/USAGE.md not fetched"
  skip 10d-readme-documents-no-exit-code "no network egress"
  skip 10h-github-default-run-shell-is-bash-dash-e "no network egress"
  skip 10i-explicit-shell-bash-also-sets-errexit "no network egress"
else
  KF_CODES=$("$AWK" '/^## Exit Codes/{f=1} f&&/^## /&&!/^## Exit Codes/{exit} f' "$WORK/USAGE.md" \
    | "$AWK" -F'|' '/^\| *[0-9]+ *\|/{gsub(/[[:space:]]/,"",$2); printf "%s%s", (n++?" ":""), $2} END{print ""}')
  echo "-- documented exit codes, in table order: [$KF_CODES]"
  assert 10a-documented-exit-code-set-is-exactly-0-200-205 "0 200 205" "$KF_CODES"
  "$CURL" -sSL --max-time 60 -H "$UA" "https://raw.githubusercontent.com/mongodb/kingfisher/$KF_TAG/README.md" -o "$WORK/KF-README.md"
  KF_README_EXIT=$("$GREP" -c -i 'exit' "$WORK/KF-README.md")
  echo "-- count via $GREP: $KF_README_EXIT"
  assert 10d-readme-documents-no-exit-code 0 "$KF_README_EXIT"
  # Why an implementer handles the code by hand at all: GitHub's default shell for a run: step is
  # bash -e, so an uncaptured 200 aborts the step before any handler runs. Read at the pinned
  # github/docs commit, and the assertions read the two literal command strings only.
  "$CURL" -sSL --max-time 60 -H "$UA" "https://raw.githubusercontent.com/github/docs/$GHDOCS_PIN/data/reusables/actions/supported-shells.md" -o "$WORK/gh-shells.md"
  echo "   github/docs at $GHDOCS_PIN, supported-shells.md sha256: $("$SHASUM" -a 256 < "$WORK/gh-shells.md")"
  GH_DEFAULT_SHELL=$("$GREP" -c -- '`bash -e {0}`' "$WORK/gh-shells.md")
  GH_BASH_SHELL=$("$GREP" -c -- '`bash --noprofile --norc -eo pipefail {0}`' "$WORK/gh-shells.md")
  echo "-- counts via $GREP: default-shell=$GH_DEFAULT_SHELL explicit-bash=$GH_BASH_SHELL"
  assert 10h-github-default-run-shell-is-bash-dash-e 1 "$GH_DEFAULT_SHELL"
  assert 10i-explicit-shell-bash-also-sets-errexit 1 "$GH_BASH_SHELL"
fi
if [ "$KF_RUNS" = no ]; then
  for l in 10b-top-level-help-documents-no-exit-code 10c-scan-help-documents-no-exit-code \
           10e-rejected-flag-exits-2 10f-unreadable-target-exits-1 \
           10g-neither-tool-error-code-is-in-the-documented-set; do
    skip "$l" "needs the Kingfisher binary running on this host (platform=$UNAME_S/$UNAME_M)"
  done
else
  # The other three places the tool could document exit behaviour, checked so the set above can be
  # called "the documented set" and not "one table's contents".
  KF_HELP_EXIT=$("$KF_DIR/kingfisher" --help 2>&1 | "$GREP" -c -i 'exit')
  echo "-- count via $GREP: $KF_HELP_EXIT"
  assert 10b-top-level-help-documents-no-exit-code 0 "$KF_HELP_EXIT"
  KF_SCANHELP_EXIT=$("$KF_DIR/kingfisher" scan --help 2>&1 | "$GREP" -c -i 'exit')
  echo "-- count via $GREP: $KF_SCANHELP_EXIT"
  assert 10c-scan-help-documents-no-exit-code 0 "$KF_SCANHELP_EXIT"
  # Two reachable tool-error codes. No pipe on the invocation: a pipeline reports its last command's
  # status, and these assertions are about the scanner's status.
  "$KF_DIR/kingfisher" --definitely-not-a-real-flag > "$WORK/badflag.out" 2>&1
  BADFLAG_EXIT=$?
  echo "-- rejected flag, first line: $(head -1 "$WORK/badflag.out")"
  assert 10e-rejected-flag-exits-2 2 "$BADFLAG_EXIT"
  "$KF_DIR/kingfisher" scan no-such-scan-target --no-update-check > "$WORK/badpath.out" 2>&1
  BADPATH_EXIT=$?
  echo "-- unreadable scan target, last line: $(tail -1 "$WORK/badpath.out")"
  assert 10f-unreadable-target-exits-1 1 "$BADPATH_EXIT"
  IN_SET=$(printf '%s\n' "$BADFLAG_EXIT" "$BADPATH_EXIT" | "$GREP" -c -E '^(0|200|205)$')
  echo "-- count via $GREP of those two codes inside the documented set: $IN_SET"
  assert 10g-neither-tool-error-code-is-in-the-documented-set 0 "$IN_SET"
fi

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
  shell command lines that github/docs documents for a `run:` step, at the pinned commit, over an
  eight-line script that is the literal implementation of this decision's gate rule. What it
  establishes is a property of those shells, executed locally; what it does not establish is how a
  hosted runner behaves, which stays P03's acceptance check 5.
- Section 13 asserts on this decision's own text, not on any external source. It compares named
  lines of the current revision against revision 2, carried beside this script as an audited
  evidence artifact so the comparison needs no git repository. It proves nothing about the scanner.
- TruffleHog's CLI was NOT downloaded or run. Its exit-183-on-verified behaviour, its 700+
  actively-verifying detector count, and whether `--since-commit` with an empty value consumes the
  following `--branch` flag are all documented-not-executed here.
- No benchmark was reproduced. Every comparative runtime, network-request and binary-size figure in
  the raw reports comes from MongoDB's own docs/COMPARISON.md and stays vendor-authored.
- No workflow file, template or repository scaffold was created by this script.
- Whether `gh attestation verify` succeeds inside a GitHub Actions job was NOT executed: no CI exists
  for this template yet. Section 07 proves the command on a developer machine with a writable
  Sigstore cache, network egress to api.github.com / tuf-repo-cdn.sigstore.dev / tuf-repo.github.com,
  and a DECLARED token (07f executes the cache prerequisite as a negative control, and 07g-07i
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
if [ "$HAVE_NET" = no ]; then
  for l in 12a-default-shell-argv-read-from-the-pinned-docs 12b-explicit-shell-bash-argv-read-from-the-pinned-docs \
           12c-default-shell-piped-rejected-flag-PASSES-THE-JOB 12d-pipefail-shell-piped-rejected-flag-fails-the-job \
           12e-default-shell-unpiped-rejected-flag-fails-the-job 12f-default-shell-piped-missing-binary-PASSES-THE-JOB \
           12g-pipefail-shell-piped-missing-binary-fails-the-job 12h-default-shell-unpiped-missing-binary-fails-the-job; do
    skip "$l" "no network egress: the pinned github/docs shell command lines were not fetched"
  done
else
  DEF_SHELL=$("$GREP" -o -- '`bash -e {0}`' "$WORK/gh-shells.md" | head -1 | tr -d '`' | "$SED" 's/ {0}//')
  PF_SHELL=$("$GREP" -o -- '`bash --noprofile --norc -eo pipefail {0}`' "$WORK/gh-shells.md" | head -1 | tr -d '`' | "$SED" 's/ {0}//')
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
  "$SED" 's#2>&1 | tee "$STEPLOG"#> "$STEPLOG" 2>\&1#' "$WORK/gate-piped.sh" > "$WORK/gate-nopipe.sh"
  echo "-- the scan line, piped form:  $("$GREP" 'SCAN_ARGS' "$WORK/gate-piped.sh")"
  echo "-- the scan line, no pipeline: $("$GREP" 'SCAN_ARGS' "$WORK/gate-nopipe.sh")"
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
  if [ "$KF_RUNS" = no ]; then
    for l in 12c-default-shell-piped-rejected-flag-PASSES-THE-JOB 12d-pipefail-shell-piped-rejected-flag-fails-the-job \
             12e-default-shell-unpiped-rejected-flag-fails-the-job; do
      skip "$l" "case 1 runs the real binary with a rejected flag; needs the Kingfisher binary (platform=$UNAME_S/$UNAME_M)"
    done
  else
    echo "-- case 1: the scanner is the real binary but the flag is rejected (exit 2, proven in 10e)."
    gate_run gate-piped.sh "$KF_DIR/kingfisher" "--definitely-not-a-real-flag" $DEF_SHELL
    assert 12c-default-shell-piped-rejected-flag-PASSES-THE-JOB "0 0" "$GATE_RC $GATE_STEP_EXIT"
    gate_run gate-piped.sh "$KF_DIR/kingfisher" "--definitely-not-a-real-flag" $PF_SHELL
    assert 12d-pipefail-shell-piped-rejected-flag-fails-the-job "2 1" "$GATE_RC $GATE_STEP_EXIT"
    gate_run gate-nopipe.sh "$KF_DIR/kingfisher" "--definitely-not-a-real-flag" $DEF_SHELL
    assert 12e-default-shell-unpiped-rejected-flag-fails-the-job "2 1" "$GATE_RC $GATE_STEP_EXIT"
  fi
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
fi

say "13 which approved wording this revision preserved, and which it changed"
# Revision 3 claimed a set of already-approved regions stood "as revision 2 wrote them" and that was
# false for three of them; the audit rejected it on exactly that. This section stops the claim being
# a matter of assertion: it reads revision 2, checks that it is the revision the audit named by
# digest, and compares named anchor lines in both directions — regions claimed unchanged must be
# byte-identical, and regions this revision rewrote must NOT be.
#
# Revision 5's form of this section resolved the repository root with `git rev-parse` and read
# revision 2 with `git show`, which made the whole section unrunnable in a clean `git archive HEAD`
# extraction — round 5's finding F1. Revision 2 is therefore CARRIED beside this script as
# rev2-DECISION.md and read by path; the git history is used by one assertion only, 13p, which
# checks the carried copy against the commit it came from and SKIPs by name where there is no
# repository. Nothing else in this section can be masked by an absent .git directory.
REV2_COMMIT=10c6ee3
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
echo "   Neither its whole-file digest nor its length is printed or asserted here: this section runs"
echo "   while that file is being written, and printing either would make the log move with prose"
echo "   edits that no assertion reads. The fourteen anchor lines below are what is asserted."
assert 13a-the-carried-copy-is-the-revision-2-the-audit-named "$REV2_SHA_EXPECTED" "$REV2_SHA"
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
# The ONE assertion in this script that needs git history. In a clean archive extraction it SKIPs by
# name: it cannot mask a failure, because the fifteen assertions above have already read the carried
# copy and this decision by path and reported their own verdicts.
if [ "$HAVE_GIT" = no ]; then
  skip 13p-the-carried-copy-is-byte-identical-to-git-history-at-that-commit "no .git directory here (a clean archive extraction); the carried copy was checked by digest in 13a"
else
  "$GIT_BIN" -C "$GIT_ROOT" show "$REV2_COMMIT:$RUN_REL/review/DECISION.md" > "$WORK/rev2-from-git.md" 2>"$WORK/rev2.err" \
    || { echo "-- git show failed:"; "$SED" -n '1,3p' "$WORK/rev2.err"; : > "$WORK/rev2-from-git.md"; }
  GIT_SHA=$("$SHASUM" -a 256 < "$WORK/rev2-from-git.md" | cut -d' ' -f1)
  echo "-- revision 2 read from git at $REV2_COMMIT, sha256: $GIT_SHA"
  assert 13p-the-carried-copy-is-byte-identical-to-git-history-at-that-commit "$REV2_SHA" "$GIT_SHA"
fi

printf '\nsummary: PASS=%d FAIL=%d SKIP=%d\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ] && { echo "RESULT: PASS"; exit 0; } || { echo "RESULT: FAIL"; exit 1; }
