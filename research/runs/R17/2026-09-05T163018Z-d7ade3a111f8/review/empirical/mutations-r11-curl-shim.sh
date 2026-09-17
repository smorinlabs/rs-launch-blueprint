#!/usr/bin/env bash
# R17 — the api.github.com fixture shim used ONLY by mutations-r11.sh's two mutant runs.
#
# WHY IT EXISTS. Round 10 rejected revision 9's mutation evidence (finding F1): under the required
# no-credential scratch-HOME invocation, `mutations-r9.sh` exited 1 because the anonymous
# api.github.com core budget was down to 8 of 60 requests. Each mutant run of the parent check
# spends five core requests (`/rate_limit`, and four `api_fetch` calls), and the harness runs the
# parent twice, so on a depleted budget the live API-dependent assertions 03a, 03b, 10a-10d and 11c
# failed alongside the mutation's intended targets. The target-only proof then could not hold —
# not because a mutation misbehaved, but because an unrelated, depletable resource ran out.
#
# WHAT IT DOES. `run-checks-r8.sh` resolves its HTTP client with `resolve_tool curl`, which takes
# the first `curl` on PATH that answers `--version`. `mutations-r11.sh` therefore puts a copy of
# this file on the mutant's PATH under the name `curl`, and the parent check resolves it and names
# it in its own section-00 toolchain line. run-checks-r8.sh is NOT modified, read, or patched for
# this: the seam is the PATH lookup the script already performs.
#
# THE BOUNDARY, exactly. Requests to host `api.github.com` are served from the committed, recorded
# responses in `fixtures-r11/`, spending no live budget:
#   /rate_limit                                                   -> 00b (and HAVE_NET / the transport branch)
#   /repos/trufflesecurity/trufflehog/releases/tags/v3.97.4       -> 03a, 03b
#   /repos/trufflesecurity/trufflehog                             -> 10a, 10b
#   /repos/mongodb/kingfisher                                     -> 10c, 10d
#   /repos/gitleaks/gitleaks-action                               -> 11c
# EVERY OTHER HOST IS PASSED THROUGH to the real curl, unchanged and live: raw.githubusercontent.com
# (section 06's TruffleHog README and main.go at the pinned tag; section 11's gitleaks-action README
# at its pinned commit, whose sha256 11b asserts), github.com release downloads (section 04), and
# static.rust-lang.org (12a). Those hosts are not metered by the GitHub core budget, which is the
# resource round 10's F1 named.
#
# An api.github.com path with no recorded fixture is REFUSED with exit 22 and nothing written, so a
# new endpoint cannot be silently satisfied: the parent check then FAILs the assertion that reads
# it, and mutations-r11.sh's failing-set assertion reports the extra label.
#
# Environment, both set by mutations-r11.sh:
#   R11_REAL_CURL    absolute path to the real curl, resolved by probe before this shim is on PATH
#   R11_FIXTURE_DIR  absolute path to the committed fixtures-r11 directory

set -u

REAL="${R11_REAL_CURL:-}"
FIXDIR="${R11_FIXTURE_DIR:-}"

url=""
outfile=""
have_auth=no
prev=""
for a in "$@"; do
  case "$a" in
    http://*|https://*) [ -z "$url" ] && url="$a" ;;
    Authorization:*|*"Authorization: Bearer"*) have_auth=yes ;;
  esac
  [ "$prev" = "-o" ] && outfile="$a"
  prev="$a"
done

# No URL at all: this is the `--version` probe run-checks-r8.sh uses to resolve its HTTP client.
# Name this shim on the first line, because that is the line the parent check prints.
if [ -z "$url" ]; then
  echo "mutations-r11 api.github.com fixture shim (api.github.com served from recorded fixtures; every other host passed through to ${REAL:-<unset>})"
  [ -n "$REAL" ] && exec "$REAL" "$@"
  exit 0
fi

host=${url#*://}
host=${host%%/*}
if [ "$host" != api.github.com ]; then
  [ -n "$REAL" ] || { echo "mutations-r11 shim: R11_REAL_CURL is unset and $url is not api.github.com" >&2; exit 2; }
  exec "$REAL" "$@"
fi

path=${url#*://}
path=${path#*/}
case "$path" in
  rate_limit)
    if [ "$have_auth" = yes ]; then fixture=api-rate_limit-token.json
    else fixture=api-rate_limit-anonymous.json; fi ;;
  repos/trufflesecurity/trufflehog/releases/tags/v3.97.4)
    fixture=api-repos-trufflesecurity-trufflehog-releases-tags-v3.97.4.json ;;
  repos/trufflesecurity/trufflehog)
    fixture=api-repos-trufflesecurity-trufflehog.json ;;
  repos/mongodb/kingfisher)
    fixture=api-repos-mongodb-kingfisher.json ;;
  repos/gitleaks/gitleaks-action)
    fixture=api-repos-gitleaks-gitleaks-action.json ;;
  *)
    echo "mutations-r11 shim: no recorded fixture for https://api.github.com/$path — refusing rather than inventing one" >&2
    exit 22 ;;
esac

src="$FIXDIR/$fixture"
if [ ! -s "$src" ]; then
  echo "mutations-r11 shim: fixture missing or empty: $src" >&2
  exit 22
fi

if [ -n "$outfile" ]; then
  cat "$src" > "$outfile" || exit 23
else
  cat "$src" || exit 23
fi
exit 0
