#!/usr/bin/env bash
# shellcheck disable=SC2016
#   File-wide: the quoted rule texts asserted below are literals taken verbatim
#   from the standard; they contain `backticks` and must never expand.
#
# R77 revision 2 — the only new evidence script. Revision 1's four scripts and
# six logs are carried BYTE-IDENTICAL and are not re-run; group D below pins
# that by sha256.
#
# Groups:
#   A  the owner ruling W2-REST, in this repository
#   B  the org REST API Design Standard v2.0.0 at the pinned blob: every rule
#      this revision quotes, asserted at its exact line
#   C  the conformance claims, the two moves and OVERRIDE (OV-04) in DECISION.md
#   D  revision 1's scripts and logs, unchanged, by sha256
#   E  revision-2 document discipline (H1, assumes lines, one re-verify line,
#      no Supersedes, OV-04 is the next free number)
#
# The standard lives outside this repository, so group B SKIPs by name when the
# clone or the blob is absent. Every other group is an in-repo FAIL if it fails.
set -euo pipefail
set -o pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
run="$here/../.."                      # research/runs/R77/<run-id>
root="$run/../../../.."                # repository root
decision="$here/../DECISION.md"

STD_REPO="$HOME/c/rest-standards"
STD_COMMIT=0850d43e45d919ef5e37f7174c4212b46013c49f
STD_BLOB=71bd813c1cf61286586b4ee41ed83ff065e5c8d9

pass=0; fail=0; skip=0
ok() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
no() { fail=$((fail+1)); printf 'FAIL %s\n' "$1"; }
sk() { skip=$((skip+1)); printf 'SKIP %s\n' "$1"; }
file_has() {
  if [ ! -f "$2" ]; then sk "$1 — $2 not present"; return; fi
  if /usr/bin/grep -qF -- "$3" "$2"; then ok "$1"; else
    no "$1"; printf '     %s does not contain: %s\n' "$2" "$3"; fi
}
file_lacks() {
  if [ ! -f "$2" ]; then sk "$1 — $2 not present"; return; fi
  if /usr/bin/grep -qF -- "$3" "$2"; then
    no "$1"; printf '     %s unexpectedly contains: %s\n' "$2" "$3"
  else ok "$1"; fi
}
count_is() {
  if [ "$2" = "$3" ]; then ok "$1 ($3)"; else
    no "$1"; printf '     expected: %s\n     actual:   %s\n' "$2" "$3"; fi
}

printf '# R77 revision 2 — REST standard conformance — %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '# /usr/bin/grep version: %s\n' "$(/usr/bin/grep --version | head -1)"

if [ -f "$root/docs/port/PARAMETERS.md" ] && [ -f "$root/research/CLAUDE.md" ]; then
  ok "repository root resolves from this script's own location"
else
  no "repository root did not resolve from this script's location (tried $root)"
  printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"
  exit 1
fi

############################################################################
echo
echo '## A — the owner ruling that makes the standard binding'
file_has "OWNER-REVIEW carries the W2-REST heading" \
  "$root/docs/port/OWNER-REVIEW.md" \
  "### 2026-09-18 — the REST API Design Standard binds the HTTP surface (W2-REST)"
file_has "W2-REST names this template's HTTP surface the way the CLI standard binds its CLI" \
  "$root/docs/port/OWNER-REVIEW.md" \
  "this template's optional HTTP surface the way the CLI Design Standard (ruling"
file_has "W2-REST names R77 among the items that design to the standard" \
  "$root/docs/port/OWNER-REVIEW.md" \
  "Every web item (R70 R72 R73 R74 R76 R77 R80 and the later R71 R83 R84)"
file_has "W2-REST requires departures as OVERRIDE (OV-nn) in the shape of section 1.9" \
  "$root/docs/port/OWNER-REVIEW.md" \
  "records any departure as an \`OVERRIDE (OV-nn)\` in the shape of the standard's"
file_has "W2-REST names the commit and blob this script pins" \
  "$root/docs/port/OWNER-REVIEW.md" "\`0850d43e45d919ef5e37f7174c4212b46013c49f\`"

############################################################################
echo
echo '## B — the standard at the pinned blob: each quoted rule at its line'
if [ -e "$STD_REPO/.git" ] && git -C "$STD_REPO" cat-file -e "$STD_BLOB" 2>/dev/null; then
  std=$(mktemp "${TMPDIR:-/tmp}/r77-rest.XXXXXX")
  git -C "$STD_REPO" cat-file -p "$STD_BLOB" > "$std"
  lines=$(/usr/bin/grep -c "" "$std")
  count_is "the blob is the 3427-line rest-api-standard.md the ruling names" 3427 "$lines"
  if git -C "$STD_REPO" cat-file -e "$STD_COMMIT" 2>/dev/null; then
    got=$(git -C "$STD_REPO" rev-parse "$STD_COMMIT:rest-api-standard.md")
    count_is "commit $STD_COMMIT carries exactly this blob as rest-api-standard.md" "$STD_BLOB" "$got"
  else
    sk "commit $STD_COMMIT not in the local clone (1 check)"
  fi
  got=$(/usr/bin/sed -n '3p' "$std")
  if printf '%s' "$got" | /usr/bin/grep -qF -- '**Version 2.0.0.**'; then
    ok "the blob declares Version 2.0.0 at line 3"
  else
    no "the blob does not declare Version 2.0.0 at line 3"; printf '     actual: %s\n' "$got"
  fi
  file_has "version 2.0.0 lists R8.10 among its nine amended rules" "$std" \
    "amended (\`R4.9\`, \`R8.10\`"

  # rule | line | verbatim substring that must sit on that line
  while IFS='|' read -r rule line text; do
    [ -n "$rule" ] || continue
    got=$(/usr/bin/sed -n "${line}p" "$std")
    if printf '%s' "$got" | /usr/bin/grep -qF -- "$text"; then
      ok "$rule quoted at line $line"
    else
      no "$rule is not at line $line"
      printf '     expected on that line: %s\n     actual:                %s\n' "$text" "$got"
    fi
  done <<'RULES'
R1.5 (§1.7 conformance tiers)|210|**R1.5** Every API declares one **conformance tier** in its conformance
R1.6 (§1.8 applicability switches)|229|**R1.6** Rules that only make sense for APIs with a given capability are
R1.6 switch vocabulary|237|The switch vocabulary: `webhooks` · `async-operations` · `bulk-operations` ·
R1.7 (§1.9 no silent deviation)|271|**R1.7 — No silent deviation.** An API deviates from this standard only in
R1.7 deviation-note line shape|291|- <rule ID> · <rule strength> · what differs · why · approver · date
R7.1 (§7.1 caching mechanism)|1259|**R7.1** Every response MUST carry an explicit `Cache-Control` header —
R7.2 (§7.1 shared-cache leak)|1271|**R7.2** Responses carrying user-specific or authenticated data MUST be
R7.3 (§7.2 caching posture)|1281|**R7.3** Within the mechanism above, the default posture is three-tier:
R8.1 (§8.1 TLS)|1317|**R8.1** APIs MUST be served only over TLS 1.2 or higher, preferring 1.3;
R8.2 (§8.1 tokens in URIs)|1323|**R8.2** Access tokens MUST NOT be accepted or emitted in URI query
R8.5 (§8.1 credential lifetime)|1348|**R8.5** Credentials SHOULD be scoped and expiring; long-lived unscoped
R8.10 (§8.3 deployment profile)|1387|**R8.10** Each axis below carries a ratified default and named
R8.10 rate-limit axis row|1397|Multi-dimensional tiered posture, published: per-principal sustained + token-bucket burst
R8.10 replay-window axis row|1398|300 s past / 60 s future, asymmetric + mandatory dedup cache held at least the past window
R8.12 (§8.5 redaction)|1422|**R8.12** Secrets, credentials, and PII MUST NOT appear in problem
R9.1 (§9.1 version marker)|1435|**R9.1** An API MUST use one uniform version-marker placement: the major
R10.1 (§10.1 async operations)|1546|**R10.1** Every `202 Accepted` MUST return an addressable operation
R10.6 (§10.3 webhook delivery)|1606|**R10.6** The provider MUST publish the acknowledgement timeout and the
R11.2 (§11.2 rate limiting)|1686|**R11.2** An API MUST apply rate limits and communicate exhaustion via
RULES

  # Two negative checks: the standard genuinely says nothing about an
  # environment-variable-selected profile or version. A check that cannot fail
  # is not evidence, so each is paired with a positive control above.
  n=$({ /usr/bin/grep -ci 'environment variable' "$std" || true; })
  if [ "$n" -eq 0 ]; then
    ok "the standard never makes a rule turn on an environment variable (0 occurrences of 'environment variable')"
  else
    no "the standard mentions 'environment variable' $n times; the conformance table's reading must account for each"
  fi
  rm -f "$std"
else
  sk "org REST API Design Standard blob $STD_BLOB — $STD_REPO absent or blob unknown (24 checks)"
fi

############################################################################
echo
echo '## C — the conformance claims, the two moves, and OVERRIDE (OV-04)'
for r in R1.5 R1.6 R1.7 R7.1 R7.2 R7.3 R8.1 R8.2 R8.5 R8.10 R8.12 R9.1 R10.1 R10.6 R11.2; do
  file_has "DECISION.md dispositions $r" "$decision" "| \`$r\` |"
done
file_has "DECISION.md records the override in the section 1.9 shape" "$decision" "OVERRIDE (OV-04)"
file_has "OV-04 carries an Argument"  "$decision" "**Argument:**"
file_has "OV-04 carries Options"      "$decision" "**Options:**"
file_has "OV-04 is against R8.1"      "$decision" "OV-04) — R8.1"
file_has "Move 1 is stated as a move, allowed before acceptance" "$decision" \
  "**Move 1 (R9.1)"
file_has "Move 2 is stated as a move, allowed before acceptance" "$decision" \
  "**Move 2 (R8.10 rate-limit axis, R11.2)"
file_has "the revision says plainly that moving is allowed before acceptance" "$decision" \
  "**Moving a recommendation before acceptance is allowed**, and this revision says so"
file_has "Move 1 forbids any version marker on the settings surface" "$decision" \
  "the version marker is never an environment variable"
file_has "Move 1 constrains ROOT_PATH to a mount prefix" "$decision" \
  "never replaces the version segment"
file_has "Move 2 reserves the rate-limit family" "$decision" "RSLBP_WEB_RATE_LIMIT_"
file_has "Move 2 records that no member default may disable limiting" "$decision" \
  "no member's default may disable rate limiting"
# The two forbidden names may appear ONLY on the line that forbids them. Any other
# occurrence would be a reservation, which is exactly what Move 1 rules out.
for forbidden in RSLBP_WEB_API_VERSION RSLBP_WEB_BASE_PATH; do
  total=$({ /usr/bin/grep -cF -- "$forbidden" "$decision" || true; })
  guarded=$({ /usr/bin/grep -F -- "$forbidden" "$decision" || true; } \
            | { /usr/bin/grep -cF -- "are outside the surface" || true; })
  if [ "$total" = "1" ] && [ "$guarded" = "1" ]; then
    ok "$forbidden appears once, on the line that puts it outside the surface"
  else
    no "$forbidden appears $total times, $guarded of them on a line placing it outside the surface (expected 1 and 1)"
  fi
done
file_has "the four applicability switches are declared off with a reason" "$decision" \
  "declared off with a stated reason"
file_has "the decision states that no setting may select a switch" "$decision" \
  "no environment variable may turn an applicability switch on"
file_has "the caching guard forbids a knob flipping a resource to public" "$decision" \
  "may never flip a resource from \`private\` or \`no-store\` to \`public\`"
file_has "the redaction reading is stated: the boot error precedes the listener" "$decision" \
  "precedes the listener"
file_has "the decision states the crate recommendation itself does not move" "$decision" \
  "The crate recommendation does not move"

############################################################################
echo
echo '## D — revision 1 evidence carried byte-identical (not re-run)'
while IFS='|' read -r name want; do
  [ -n "$name" ] || continue
  f="$here/$name"
  if [ ! -f "$f" ]; then no "revision-1 file $name is missing"; continue; fi
  got=$(shasum -a 256 "$f" | awk '{print $1}')
  count_is "revision-1 $name is unchanged" "$want" "$got"
done <<'SHAS'
figures.sh|d70b89cdd15898078182f696540bd992be7d17c9ba7262441bc4395d29dd25a6
sources.sh|a63bb281280bc3d530f7aacf24e3825994f94c2f980db4df7c0041cb9fe05f34
probes.sh|4af088a3945a2ba47ab7f60ef71f0714fd4075b9f01cfe81606edd45d1b62747
fetch-snapshots.sh|9c26e9ea96b101e88398b60baf3b709bc3b3e0aae28bfd8d9b77c4442e51c642
figures.log|493ba961663fbf19d28432610d38ff168558239e074026d02ced7bf28a58f086
sources.log|455841ce2b0d76cf94d46a5563d3a50a9144e454bf4f5218235ee32c1b3f3923
probes.log|fe848ea72828e4220f7030caca562c48517f16207565d9b05c6edf2a58672ae7
fetch-snapshots.log|8eae6a9c2af53ec40384968efed1ed40b16e5d7c7523240336fd7e25c84f5226
rerun-diff.log|d6b4d0fee8b741eb8850d00c38810ddf832d0c161f6f0d0cc4530e36dd96028a
archive-rerun.log|b341895ab9f790914d3475f70a34b4aa7aae0c07eaea39100a3f3b7e7ad15d1a
SHAS
file_has "the revision note records revision 1's own sha256" "$decision" \
  "b2b2e678a9866fd8f743d2431edcda2dc03a9e4ed03c9670457081360121b546"

############################################################################
echo
echo '## E — revision-2 document discipline'
if [ ! -f "$decision" ]; then
  sk "DECISION.md not present beside this script — document discipline (7 checks)"
else
  got=$(head -1 "$decision")
  count_is "H1 is the date-first revision-2 title" \
    "# 2026-09-18 — R77 — web-env-settings (crate, Focused) — decision (revision 2)" "$got"
  n=$(/usr/bin/grep -c '^## Supersedes' "$decision" || true)
  count_is "no Supersedes section" 0 "$n"
  n=$(/usr/bin/grep -c '^re-verify: ' "$decision" || true)
  count_is "exactly one re-verify line" 1 "$n"
  n=$(/usr/bin/grep -c '^- owns ' "$decision" || true)
  count_is "no owned parameter" 0 "$n"
  n=$(/usr/bin/grep -c '^- assumes ' "$decision" || true)
  count_is "exactly six assumes lines" 6 "$n"
  file_has "the revision history names revision 1 and revision 2" "$decision" "Revision history:"
  file_has "fitness gate 1 keeps the owner's exact ruling string" "$decision" \
    "inapplicable — owner ruling 2026-09-12 (Q7.B)"
  for p in msrv-policy rust-edition target-os-matrix license web-extra-surface error-taxonomy-exit-codes; do
    reg=$(python3 - "$root" "$p" <<'PY'
import sys
sys.path.insert(0, sys.argv[1] + "/scripts")
from pathlib import Path
from research_validation import _parse_parameters
v = _parse_parameters(Path(sys.argv[1]), [])
row = v.get(sys.argv[2])
print("- assumes %s = %s" % (sys.argv[2], row["value"] if row else "!!MISSING!!"))
PY
)
    dec=$(/usr/bin/grep -m1 "^- assumes $p = " "$decision" || true)
    if [ "$reg" = "$dec" ]; then
      ok "assumes $p still byte-identical to docs/port/PARAMETERS.md (${#reg} bytes)"
    else
      no "assumes $p differs from the registry row"
      printf '     registry: %s\n     decision: %s\n' "$reg" "$dec"
    fi
  done
fi

# OV-04 must be the next free number: no other file may already carry it.
others=$(find "$root/docs" "$root/research" -name '*.md' -type f -print0 2>/dev/null \
         | xargs -0 /usr/bin/grep -l 'OVERRIDE (OV-04)' 2>/dev/null \
         | /usr/bin/grep -v 'runs/R77/' || true)
if [ -z "$others" ]; then
  ok "OV-04 is unused elsewhere in docs/ and research/ — it is the next free number"
else
  no "OV-04 is already used by: $others"
fi
for taken in OV-01 OV-02 OV-03; do
  n=$(find "$root/docs" "$root/research" -name '*.md' -type f -print0 2>/dev/null \
      | xargs -0 /usr/bin/grep -l "OVERRIDE ($taken)" 2>/dev/null | /usr/bin/grep -c . || true)
  if [ "$n" -gt 0 ]; then
    ok "$taken is already taken ($n files) — the control that makes the OV-04 search meaningful"
  else
    no "$taken was expected to be in use; the next-free-number search is unproven"
  fi
done

printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"
[ "$fail" -eq 0 ] || exit 1
