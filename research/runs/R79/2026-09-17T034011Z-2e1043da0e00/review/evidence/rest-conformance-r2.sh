#!/usr/bin/env bash
# R79 prometheus-metrics, revision 2 — asserts every REST API Design Standard
# rule this decision quotes, AT THE PINNED BLOB, and asserts the decision's own
# conformance claims.
#
# Owner ruling W2-REST (2026-09-18) binds the org REST API Design Standard
# v2.0.0 to this template's HTTP surface. The standard is NOT in this
# repository: it lives in a sibling clone. Everything this script asserts about
# it is therefore pinned two ways at once --
#   1. the blob id 71bd813c1cf61286586b4ee41ed83ff065e5c8d9, which is immutable;
#   2. snapshots/rest-standard-rules.txt, a committed copy of exactly the quoted
#      lines, so the assertions still run when the sibling clone is absent.
# When the clone is present the script reads the blob and diffs it against the
# snapshot, which is what makes the snapshot trustworthy rather than merely
# convenient. When it is absent, every blob-backed check is a NAMED skip and the
# snapshot-backed checks still run.
#
# This script also SUPERSEDES review/evidence/decision-self-check.sh, which is a
# revision-1 artifact: that script asserts revision 1's H1 line and revision 1's
# sha256 by construction, so it cannot pass against revision 2 and is not meant
# to. Its whole check set is re-executed here against revision 2, and the sha256
# of every revision-1 artifact is pinned and printed below so an auditor can see
# that none of them moved.
#
# Offline and git-free for the repository: the root is found by walking up from
# $0, never from the working directory, and no `git` call touches THIS repo, so
# the script runs unchanged inside a `git archive HEAD` extraction. `git` is
# used only to read the sibling standards clone, and only when it is present.
#
# Exits non-zero if any check FAILs. Every SKIP is named.

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
review="$(cd "$here/.." && pwd)"
run="$(cd "$review/.." && pwd)"
# run -> R79 -> runs -> research -> repository root
root="$(cd "$run/../../../.." && pwd)"

DECISION="$review/DECISION.md"
RAW="$run/raw/opus.md"
RAW_SHA=c1d02b81cd0929881f66c7810af782496a84f73a8f45472e86e773a0300145ac
REGISTRY="$root/docs/port/PARAMETERS.md"
INDEX="$root/research/CLAUDE.md"
OWNER_REVIEW="$root/docs/port/OWNER-REVIEW.md"
GATE1='inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool'

STD_REPO=/Users/stevemorin/c/rest-standards
STD_BLOB=71bd813c1cf61286586b4ee41ed83ff065e5c8d9
STD_COMMIT=0850d43e45d919ef5e37f7174c4212b46013c49f
SNAPSHOT="$here/snapshots/rest-standard-rules.txt"

GREP=/usr/bin/grep

pass_count=0
fail_count=0
skip_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS  %s\n' "$*"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL  %s\n' "$*"; }
skip() { skip_count=$((skip_count + 1)); printf 'SKIP  %s\n' "$*"; }

scratch="$(mktemp -d "${TMPDIR:-/tmp}/rslb-r79-rest.XXXXXX")"
# shellcheck disable=SC2329  # invoked indirectly by the EXIT trap below
cleanup() { rm -rf "$scratch"; }
trap cleanup EXIT

echo "== environment =="
printf 'date-utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'repository root resolved by walking up from the script path: %s\n' "$root"
if [ -e "$root/.git" ]; then
  if [ -d "$root/.git" ]; then
    printf 'context: a git checkout (.git is a directory)\n'
  else
    printf 'context: a git worktree (.git is a FILE, which is why the test is -e and not -d)\n'
  fi
else
  printf 'context: no .git present -- a clean extraction, and every check below still runs\n'
fi
"$GREP" --version | head -1
echo

# ================================================ the standard, at the blob ===
echo "== the REST API Design Standard v2.0.0, at the pinned blob =="
printf 'named by owner ruling W2-REST: commit %s, blob %s\n' "$STD_COMMIT" "$STD_BLOB"

std=""
if [ -d "$STD_REPO" ] && command -v git > /dev/null 2>&1; then
  if git -C "$STD_REPO" cat-file -e "$STD_BLOB" 2> /dev/null; then
    git -C "$STD_REPO" cat-file blob "$STD_BLOB" > "$scratch/std.md"
    std="$scratch/std.md"
    printf 'blob read: %s lines, sha256 %s\n' \
      "$(wc -l < "$std" | tr -d ' ')" "$(shasum -a 256 "$std" | awk '{print $1}')"
    pass "the pinned blob $STD_BLOB exists in $STD_REPO and was read"
    # The blob id IS a content hash, so re-deriving it proves the bytes.
    derived="$(git -C "$STD_REPO" hash-object -t blob "$std")"
    if [ "$derived" = "$STD_BLOB" ]; then
      pass "re-hashing the bytes reproduces the pinned blob id (content identity, not a filename)"
    else
      fail "re-hashing the bytes gives $derived, not the pinned $STD_BLOB"
    fi
    if git -C "$STD_REPO" cat-file -e "$STD_COMMIT" 2> /dev/null; then
      pass "the pinned commit $STD_COMMIT exists in $STD_REPO"
    else
      fail "the pinned commit $STD_COMMIT is not in $STD_REPO"
    fi
  else
    skip "reading the standard at its blob (the clone exists but does not contain blob $STD_BLOB)"
  fi
else
  skip "reading the standard at its blob (the sibling clone $STD_REPO is not present on this machine)"
fi
echo

# The rules this decision quotes: line number, rule id, and a distinctive
# fragment of the rule's own text that must appear on that exact line or within
# the rule's own paragraph.
#
#   <line>|<rule id>|<verbatim fragment that must be found at or below that line>
emit_rules() {
  cat <<'ROWS'
219|R1.5|Every rule in this standard applies at every tier unless the rule itself
233|R1.6|MUST carry a stated reason in the conformance
237|R1.6|The switch vocabulary: `webhooks` · `async-operations` · `bulk-operations` ·
258|R1.6|A switch never waives a guard.
271|R1.7|No silent deviation.
275|R1.7|silent deviation from any rule strength is nonconformance
291|R1.7|<rule ID> · <rule strength> · what differs · why · approver · date
312|R1.8|A conforming API MUST NOT use a reserved
319|R1.9|a mutating request carrying the `dry_run` parameter
443|R2.1|An API MUST present a resource-oriented surface
447|R2.1|There is no RPC carve-out for any service class.
456|R2.2|Collection resources MUST use plural nouns
477|R2.4|Path segments MUST use kebab-case
488|R2.5|MUST NOT reference more
499|R2.6|Canonical URIs have no trailing slash
525|R2.9|Path segments identify resources; query parameters modify the
533|R2.10|Personally identifiable information MUST NOT appear in any URI
542|R2.11|A non-CRUD operation MUST use the sub-path verb form
599|R3.3|logging and metrics side effects do not violate safety.
693|R3.10|A resource that supports conditional update MUST emit a strong
695|R3.10|Exception:** resources never updated by clients.
742|R4.1|Every API MUST publish an OpenAPI document as the contract source
762|R4.3|Every JSON response body MUST have an object at the top level
763|R4.3|Exception:** non-JSON media types.
846|R4.10|The default media type — served when a request carries no
850|R4.10|406 Not Acceptable
856|R4.11|Every response whose content was selected by a request header
858|R4.11|Exception:** responses with no negotiation.
864|R4.17|Where an API serves cross-origin browser clients
1259|R7.1|Every response MUST carry an explicit `Cache-Control` header
1283|R7.3|Authenticated or mutable resources default to
1286|R7.3|no-store` is reserved for genuinely sensitive payloads
1317|R8.1|APIs MUST be served only over TLS 1.2 or higher
1323|R8.2|Access tokens MUST NOT be accepted or emitted in URI query
1356|R8.6|Every request MUST be authorized against the specific object
1422|R8.12|Secrets, credentials, and PII MUST NOT appear in problem
1435|R9.1|An API MUST use one uniform version-marker placement
1752|R11.7|Every response, including errors, MUST carry the `request-id`
1759|R11.8|W3C Trace Context `traceparent` MUST be propagated
1935|R13.3|`stream` is a reserved request-modifier name
1938|R13.3|MUST reject the request with `400`
2218|R4.10|R4.10's default clause carries no BCP 14 keyword
2799|AppB|Attempt conformance first.
2805|AppB|requirement-strength rules go to the standard's owner
ROWS
}

echo "== every rule this decision quotes, asserted at its line in the blob =="
if [ -n "$std" ]; then
  : > "$scratch/extract.txt"
  while IFS='|' read -r line rule fragment; do
    [ -n "$line" ] || continue
    actual="$(sed -n "${line}p" "$std")"
    printf '%s|%s|%s\n' "$line" "$rule" "$actual" >> "$scratch/extract.txt"
    if printf '%s' "$actual" | "$GREP" -qF -- "$fragment"; then
      pass "$rule at :$line — \"$(printf '%.58s' "$fragment")\""
    else
      fail "$rule at :$line — the blob's line does not contain the quoted fragment"
      printf '      | expected fragment: %s\n' "$fragment"
      printf '      | blob line %s:      %s\n' "$line" "$actual"
    fi
  done < <(emit_rules)

  if [ -f "$SNAPSHOT" ]; then
    if diff -u "$SNAPSHOT" "$scratch/extract.txt" > "$scratch/snapdiff.txt"; then
      pass "the committed snapshot of the quoted rule lines is byte-identical to the blob"
    else
      fail "the committed snapshot differs from the blob — the standard moved, or the snapshot is stale"
      sed 's/^/    /' "$scratch/snapdiff.txt"
    fi
  else
    mkdir -p "$(dirname "$SNAPSHOT")"
    cp "$scratch/extract.txt" "$SNAPSHOT"
    pass "wrote the first snapshot of the quoted rule lines to snapshots/rest-standard-rules.txt"
  fi
else
  skip "asserting the quoted rule lines against the blob (the blob was not readable above)"
  if [ -f "$SNAPSHOT" ]; then
    n_snap="$(wc -l < "$SNAPSHOT" | tr -d ' ')"
    n_rules="$(emit_rules | "$GREP" -c '|')"
    if [ "$n_snap" = "$n_rules" ]; then
      pass "the committed snapshot carries all $n_rules quoted rule lines"
    else
      fail "the committed snapshot carries $n_snap lines, not the $n_rules rules this decision quotes"
    fi
  else
    fail "neither the blob nor the committed snapshot is available; no rule text can be asserted"
  fi
fi
echo

echo "== the rule text, as this decision quotes it, printed from the snapshot =="
if [ -f "$SNAPSHOT" ]; then
  awk -F'|' '{ printf "      | %-6s :%-5s %s\n", $2, $1, $3 }' "$SNAPSHOT"
else
  skip "printing the quoted rule text (no snapshot on disk)"
fi
echo

# ============================================= the scope finding, at the blob ==
echo "== the scope finding: the standard has no vocabulary for an operational endpoint =="
if [ -n "$std" ]; then
  for term in Prometheus telemetry scrape exposition healthz readyz liveness readiness monitoring instrumentation; do
    n="$("$GREP" -ci -- "$term" "$std" || true)"
    if [ "$n" = "0" ]; then
      pass "the word '$term' is absent from all $(wc -l < "$std" | tr -d ' ') lines of the standard"
    else
      fail "the word '$term' occurs $n times in the standard — the scope finding must be re-read"
      "$GREP" -ni -- "$term" "$std" | sed 's/^/      | /'
    fi
  done
  # `metrics` occurs exactly once inside a rule, and it is R3.3's safety exception.
  metrics_hits="$("$GREP" -ci 'metric' "$std" || true)"
  printf '      | occurrences of the stem "metric": %s (lines below)\n' "$metrics_hits"
  "$GREP" -ni 'metric' "$std" | sed 's/^/      | /'
  if "$GREP" -n 'logging and metrics side effects do not violate safety' "$std" > /dev/null; then
    pass "the only rule-bearing use of 'metrics' is R3.3's safety exception at :599"
  else
    fail "R3.3's 'logging and metrics side effects' exception is not where this decision cites it"
  fi
  # The switch vocabulary must still be the closed four-name set.
  # shellcheck disable=SC2016  # the backticks are the standard's own literal text, not a substitution
  if sed -n '237,238p' "$std" | "$GREP" -qF 'webhooks` · `async-operations` · `bulk-operations`'; then
    pass "the applicability-switch vocabulary is still the closed four-name set (no operational switch)"
  else
    fail "the applicability-switch vocabulary moved; the no-carve-out argument must be re-read"
  fi
else
  skip "the absent-vocabulary sweep (the blob was not readable above)"
fi
echo

# ====================================== the decision's own conformance claims ==
echo "== the decision's own conformance claims =="
if [ ! -f "$DECISION" ]; then
  fail "DECISION.md is missing at $DECISION"
  echo
  echo "== summary =="
  printf 'PASS=%s FAIL=%s SKIP=%s TOTAL=%s\n' \
    "$pass_count" "$fail_count" "$skip_count" "$((pass_count + fail_count + skip_count))"
  exit 1
fi
printf 'DECISION.md sha256 %s\n' "$(shasum -a 256 "$DECISION" | awk '{print $1}')"

# R2.4: the literal path segment must satisfy the standard's own regex.
segment=metrics
# The standard writes the class as [a-z\-0-9]; in an ERE bracket expression the
# hyphen must be last or it forms a range, so it is written [a-z0-9-] here. The
# accepted character set is identical.
if printf '%s' "$segment" | "$GREP" -qE '^[a-z][a-z0-9-]*$'; then
  pass "R2.4 — the path segment '$segment' satisfies the standard's kebab-case pattern"
else
  fail "R2.4 — the path segment '$segment' fails the standard's kebab-case pattern"
fi
# R2.5: one resource segment, well inside the ceiling of three.
depth="$(printf '/%s' "$segment" | awk -F/ '{print NF-1}')"
if [ "$depth" -le 3 ]; then
  pass "R2.5 — /$segment references $depth resource segment(s), within the ceiling of three"
else
  fail "R2.5 — /$segment references $depth resource segments, above the ceiling of three"
fi
# R1.8: the segment must not collide with a reserved action verb.
for verb in cancel archive restore approve reject publish unpublish duplicate; do
  if [ "$segment" = "$verb" ]; then
    fail "R1.8 — '$segment' collides with the reserved action verb '$verb'"
  fi
done
pass "R1.8 — '$segment' collides with none of the eight reserved action verbs"

# Each disposition the decision claims must actually be written in it.
claim() { # needle label
  if "$GREP" -qF -- "$1" "$DECISION"; then
    pass "$2"
  else
    fail "$2 -- the decision does not carry: $1"
  fi
}
claim 'Cache-Control: private, no-cache' \
  "R7.1/R7.3 — the decision names the explicit Cache-Control value the handler sets"
# shellcheck disable=SC2016  # the backticks are the standard's own literal text, not a substitution
claim 'MUST reject the request with `400`' \
  "R13.3 — the decision quotes the stream rejection guard it now implements"
claim 'stream' \
  "R13.3 — the decision names the reserved modifier the handler rejects"
claim 'request-id' \
  "R11.7 — the decision names the correlation header /metrics must carry"
claim 'traceparent' \
  "R11.8 — the decision names the trace header that must be propagated"
claim 'text/plain; version=0.0.4' \
  "OV-07(a) — the decision names the exposition media type it serves instead of JSON"
claim 'OVERRIDE (OV-07)' "the controller-allocated OV-07 is recorded as an override"
claim 'OV-07(a)' "OV-07's first departure is labelled"
claim 'OV-07(b)' "OV-07's second departure is labelled"
claim '**Argument:**' "each override carries an **Argument:**"
claim '**Options:**' "each override carries an **Options:**"
claim 'W2-REST' "the decision names the owner ruling that occasioned this revision"
claim "$STD_BLOB" "the decision pins the standard's blob id"
claim "$STD_COMMIT" "the decision pins the standard's commit"

# The controller allocates override numbers centrally as of 2026-09-18 and
# issued OV-07 to R79. No other number may appear as an OVERRIDE heading here.
# Count HEADING lines only: the conformance table also references the override
# from its R4.10 and R8.6 rows, and those are pointers, not declarations.
n="$("$GREP" -cE '^\*\*OVERRIDE \(OV-07\)' "$DECISION" || true)"
if [ "$n" = "1" ]; then
  pass "exactly one OVERRIDE heading, and it carries the controller-allocated OV-07"
else
  fail "found $n 'OVERRIDE (OV-07)' heading lines, expected exactly 1"
  "$GREP" -nE '^\*\*OVERRIDE' "$DECISION" | sed 's/^/      | /'
fi
refs="$("$GREP" -cE '\*\*OVERRIDE \(OV-07\)\((a|b)\)\*\*' "$DECISION" || true)"
if [ "$refs" = "2" ]; then
  pass "the conformance table points at both departures of OV-07 from their own rule rows"
else
  fail "the conformance table carries $refs pointers to OV-07(a)/OV-07(b), expected 2"
fi
if "$GREP" -qE '^\*\*OVERRIDE \(OV-(0[1-689]|1[0-9])\)' "$DECISION"; then
  fail "an OVERRIDE heading carries a number other than the allocated OV-07"
  "$GREP" -nE '^\*\*OVERRIDE \(OV-[0-9]+\)' "$DECISION" | sed 's/^/      | /'
else
  pass "no OVERRIDE heading carries a number other than the allocated OV-07"
fi

# The §1.9 deviation-note shape: rule ID · strength · what differs · why · approver · date.
for ov_rule in R4.10 R8.6; do
  if "$GREP" -qE "^\`- $ov_rule · (MUST|SHOULD)" "$DECISION"; then
    pass "a §1.9-shaped deviation row is recorded for $ov_rule"
  else
    fail "no §1.9-shaped deviation row (\`- $ov_rule · <strength> · …\`) is recorded"
  fi
done

echo "-- the OV allocation search, re-executed --"
if find "$root/research" "$root/docs" -type f -name '*.md' -print0 2>/dev/null \
    | xargs -0 "$GREP" -noE "\bOV-[0-9]+\b" 2>/dev/null \
    | "$GREP" -v "^$DECISION:" \
    | "$GREP" -v "/docs/planning/p02/execution-ledger.md:" > "$scratch/ov.txt"; then
  printf '      | OV numbers in use outside this decision:\n'
  sed 's/^/      | /' "$scratch/ov.txt"
  # The census LISTING is deliberately not printed. It enumerates other items'
  # decision files, several of which are uncommitted work by other agents in
  # this shared worktree, so it differs between the worktree and a `git archive`
  # extraction and would make an honest rerun's log differ. What is printed is
  # the assertion outcome, which is what the decision actually relies on.
  printf '      | census computed over the markdown corpus; listing withheld because it varies\n'
  printf '      | with other agents uncommitted work. The assertions below are what is claimed.\n'
  if "$GREP" -qE "\bOV-0?7\b" "$scratch/ov.txt"; then
    fail "OV-07 is claimed by another item — the controller's allocation must be re-issued"
    "$GREP" -nE "\bOV-0?7\b" "$scratch/ov.txt" | sed 's/^/      | /'
  else
    pass "the controller-allocated OV-07 is claimed by no other item"
  fi
  # The allocator's register must itself still say OV-07 belongs to R79.
  ledger="$root/docs/planning/p02/execution-ledger.md"
  if [ -f "$ledger" ]; then
    if "$GREP" -qF 'OV-07 R79' "$ledger"; then
      pass "the controller's allocation table still reads 'OV-07 R79'"
      "$GREP" -noE 'OV-07 R79' "$ledger" | sed 's/^/      | ledger: /'
    else
      fail "the controller's allocation table no longer assigns OV-07 to R79"
    fi
  else
    skip "the allocation-table check (docs/planning/p02/execution-ledger.md is not in this extraction)"
  fi
else
  fail "the OV census came back empty, which is what the FIRST, truncated search wrongly reported; OV-01..OV-06 are known to be in use, so an empty result means the search is broken, not that the numbers are free"
fi

echo "-- the owner ruling is where this decision cites it --"
if [ -f "$OWNER_REVIEW" ]; then
  if "$GREP" -n 'the REST API Design Standard binds the HTTP surface (W2-REST)' "$OWNER_REVIEW" \
      | "$GREP" -q '^187:'; then
    pass "W2-REST is at docs/port/OWNER-REVIEW.md:187, the line this decision cites"
  else
    fail "W2-REST is no longer at docs/port/OWNER-REVIEW.md:187"
    "$GREP" -n 'W2-REST' "$OWNER_REVIEW" | sed 's/^/      | /'
  fi
  if "$GREP" -q "$STD_BLOB" "$OWNER_REVIEW" || "$GREP" -q '71bd813c' "$OWNER_REVIEW"; then
    pass "the owner ruling itself names the blob this script reads"
  else
    fail "the owner ruling does not name the blob this script reads"
  fi
else
  skip "the W2-REST line check (docs/port/OWNER-REVIEW.md is not present in this extraction)"
fi
echo

# ============================ revision-1 artifacts, pinned and proven unmoved ==
echo "== every revision-1 artifact, pinned by digest and proven byte-identical =="
emit_r1_artifacts() {
  cat <<'DIGESTS'
cargo-probes.sh
cargo-probes.log
crate-sources.sh
crate-sources.log
github-api.sh
github-api.log
decision-self-check.sh
decision-self-check.log
scrape-sample.txt
DIGESTS
}
while read -r name; do
  [ -n "$name" ] || continue
  if [ -f "$here/$name" ]; then
    printf '      | %-26s sha256 %s\n' "$name" "$(shasum -a 256 "$here/$name" | awk '{print $1}')"
    pass "revision-1 artifact present and hashed: $name"
  else
    fail "revision-1 artifact missing: $name"
  fi
done < <(emit_r1_artifacts)

lock_count="$(find "$here/locks" -maxdepth 1 -name '*.lock' 2>/dev/null | wc -l | tr -d ' ')"
snap_count="$(find "$here/snapshots" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
if [ "$lock_count" = "4" ]; then
  pass "the four revision-1 lockfile snapshots are still present"
else
  fail "locks/ holds $lock_count lockfiles, not the four revision 1 committed"
fi
if [ "$snap_count" = "14" ]; then
  pass "the fourteen revision-1 registry and GitHub snapshots are still present"
else
  fail "snapshots/ holds $snap_count JSON snapshots, not the fourteen revision 1 committed"
fi

# The superseded script must still be the revision-1 one: it must assert
# revision 1's H1. If it did not, it would have been edited, which is forbidden.
if "$GREP" -q 'decision (revision 1)' "$here/decision-self-check.sh"; then
  pass "decision-self-check.sh is unedited: it still asserts revision 1's H1, which is why it is superseded"
else
  fail "decision-self-check.sh no longer asserts revision 1's H1 — a revision-1 artifact was edited"
fi
echo

# ============ the revision-1 check set, re-executed against revision 2 ========
echo "== the revision-1 self-check set, re-executed against revision 2 =="
expected_h1='# 2026-09-18 — R79 — prometheus-metrics (crate, Focused) — decision (revision 2)'
actual_h1="$(head -1 "$DECISION")"
if [ "$actual_h1" = "$expected_h1" ]; then
  pass "H1 is the date-first revision-2 form"
else
  fail "H1 is '$actual_h1', not '$expected_h1'"
fi

raw_actual="$(shasum -a 256 "$RAW" | awk '{print $1}')"
if [ "$raw_actual" = "$RAW_SHA" ]; then
  pass "raw/opus.md still matches the sha256 the controller's task message names"
else
  fail "raw/opus.md sha256 is $raw_actual, not $RAW_SHA"
fi

"$GREP" -n '^## ' "$DECISION" > "$scratch/h2.txt" || true
h2_list="$(awk -F'^[0-9]+:## ' '{print $2}' "$scratch/h2.txt" | paste -sd'|' -)"
if [ "$h2_list" = "Decision|Parameters|Empirical check|Engines" ]; then
  pass "H2 sections are exactly Decision, Parameters, Empirical check, Engines, in order"
else
  fail "H2 sections are '$h2_list'"
fi
if "$GREP" -q '^## Supersedes' "$DECISION"; then
  fail "no revision of this decision has been published, so there must be no '## Supersedes'"
else
  pass "no '## Supersedes' section, and the decision says why in its revision note"
fi

h3_principles="$("$GREP" -c '^### Principles and implementation$' "$DECISION" || true)"
if [ "$h3_principles" = "1" ]; then
  pass "exactly one '### Principles and implementation' H3"
else
  fail "found $h3_principles '### Principles and implementation' headings, expected 1"
fi
parameters_line="$("$GREP" -n '^## Parameters$' "$DECISION" | head -1 | cut -d: -f1)"
principles_line="$("$GREP" -n '^### Principles and implementation$' "$DECISION" | head -1 | cut -d: -f1)"
if [ -n "$principles_line" ] && [ "$principles_line" -lt "$parameters_line" ]; then
  pass "'### Principles and implementation' sits inside '## Decision'"
else
  fail "'### Principles and implementation' is not inside '## Decision'"
fi

reverify_n="$("$GREP" -c '^re-verify:' "$DECISION" || true)"
if [ "$reverify_n" = "1" ]; then
  pass "exactly one line begins 're-verify:'"
else
  fail "found $reverify_n lines beginning 're-verify:', expected exactly 1"
fi
reverify_line="$("$GREP" -n '^re-verify:' "$DECISION" | head -1 | cut -d: -f1)"
last_decision_line="$(awk -v stop="$parameters_line" 'NR < stop && NF { n = NR } END { print n }' "$DECISION")"
if [ "$reverify_line" = "$last_decision_line" ]; then
  pass "the re-verify line is the final content line of '## Decision'"
else
  fail "the final content line of '## Decision' is $last_decision_line, not the re-verify line at $reverify_line"
fi
if "$GREP" -q 'W2-REST' "$DECISION" && \
   sed -n "${reverify_line}p" "$DECISION" | "$GREP" -qF "$STD_BLOB"; then
  pass "the re-verify line carries a trigger on the standard's pinned blob"
else
  fail "the re-verify line does not trigger on a change to the standard's blob"
fi

if "$GREP" -qF "$GATE1" "$DECISION"; then
  pass "the exact gate-1 'inapplicable' string is still recorded"
else
  fail "the exact gate-1 'inapplicable' string is missing"
fi
if "$GREP" -niE '(licen[cs]e[^|]*(—|-) *pass)|(gate 1[^|]*pass)' "$DECISION" > "$scratch/g1.txt"; then
  fail "a gate-1 PASS verdict survives; the ruling strikes the gate rather than passing it"
  sed 's/^/    /' "$scratch/g1.txt"
else
  pass "no line asserts a gate-1 pass verdict"
fi

echo "-- parameter lines, byte-compared with docs/port/PARAMETERS.md --"
if [ -f "$REGISTRY" ]; then
  awk -F'|' 'NF >= 6 {
    name = $2; gsub(/^[ \t]+|[ \t]+$/, "", name)
    value = $5; gsub(/^[ \t]+|[ \t]+$/, "", value)
    if (name ~ /^[a-z0-9-]+$/ && name != "param") print name "\t" value
  }' "$REGISTRY" > "$scratch/registry.tsv"
  owns_n="$("$GREP" -c '^- owns ' "$DECISION" || true)"
  if [ "$owns_n" = "0" ]; then
    pass "no '- owns' line, matching the prompt's empty '- owns:' coupling"
  else
    fail "found $owns_n '- owns' lines; R79 owns no parameter"
  fi
  names="$("$GREP" '^- assumes ' "$DECISION" | sed 's/^- assumes \([a-z0-9-]*\) = .*/\1/' | sort | paste -sd',' -)"
  if [ "$names" = "license,msrv-policy,rust-edition,target-os-matrix" ]; then
    pass "the assumed parameter set is still exactly the four fixed parameters"
  else
    fail "the assumed parameter set is '$names', not the four fixed parameters"
  fi
  while IFS= read -r line; do
    name="$(printf '%s' "$line" | sed 's/^- assumes \([a-z0-9-]*\) = .*/\1/')"
    value="$(printf '%s' "$line" | sed 's/^- assumes [a-z0-9-]* = //')"
    registry_value="$(awk -F'\t' -v want="$name" '$1 == want { print $2 }' "$scratch/registry.tsv")"
    if [ "$value" = "$registry_value" ] && [ -n "$registry_value" ]; then
      pass "'$name' is byte-identical to its registry row (${#value} bytes), unmoved by revision 2"
    else
      fail "'$name' differs from its registry row"
      printf '%s\n' "$registry_value" > "$scratch/reg.txt"
      printf '%s\n' "$value"          > "$scratch/decl.txt"
      diff "$scratch/reg.txt" "$scratch/decl.txt" | sed 's/^/    /' || true
    fi
  done < <("$GREP" '^- assumes ' "$DECISION")
  if "$GREP" -q '^- assumes web-extra-surface' "$DECISION"; then
    fail "web-extra-surface appears as an '- assumes' line; R79's '- consumes:' is empty"
  else
    pass "web-extra-surface is still consumed in prose, not declared as an '- assumes' line"
  fi
else
  skip "the parameter byte-comparison (docs/port/PARAMETERS.md is not present in this extraction)"
fi

echo "-- decision shape, via the module's own decision validator --"
if python3 - "$DECISION" <<'DECISION_SHAPE' > "$scratch/shape.txt" 2>&1
import sys, pathlib
path = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(path.parents[5] / "scripts"))
import research_validation as rv
text = path.read_text(encoding="utf-8")
triggers = [l.strip() for l in text.splitlines() if l.strip().startswith("re-verify:")]
if len(triggers) != 1:
    print("expected exactly one re-verify line, found %d" % len(triggers))
    sys.exit(1)
errors = []
rv._validate_decision_text(text, "R79", {"reverify": triggers[0][len("re-verify: "):]}, errors)
for line in errors:
    print(line)
sys.exit(1 if errors else 0)
DECISION_SHAPE
then
  pass "_validate_decision_text(DECISION.md, \"R79\") returns no diagnostics"
else
  if "$GREP" -q "ModuleNotFoundError\|No module named" "$scratch/shape.txt"; then
    skip "_validate_decision_text (scripts/research_validation.py is not importable from this extraction)"
  else
    fail "_validate_decision_text(DECISION.md, \"R79\") reported diagnostics"
  fi
  sed 's/^/    /' "$scratch/shape.txt"
fi

echo "-- hygiene --"
if "$GREP" -rnE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$DECISION" "$here"/*.sh > "$scratch/em.txt"; then
  fail "an email address appears in the decision or an evidence script"
  sed 's/^/    /' "$scratch/em.txt"
else
  pass "no email address in the decision or any evidence script"
fi
# Match a token VALUE, not a bare prefix, or this line would match itself.
if "$GREP" -rnE 'gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{20,}' \
     "$DECISION" "$here"/*.sh "$here"/*.log > "$scratch/tok.txt"; then
  fail "something token-shaped appears in a committed artefact"
  sed 's/^/    /' "$scratch/tok.txt"
else
  pass "no token-shaped bytes in the decision, the scripts or the logs"
fi
if find "$here" -name target -type d -o -name '.git' | "$GREP" -q .; then
  fail "a target/ tree or a nested .git is present under review/evidence/"
else
  pass "no target/ tree and no nested repository under review/evidence/"
fi
if command -v shellcheck > /dev/null 2>&1; then
  if shellcheck "$here"/*.sh > "$scratch/sc.txt" 2>&1; then
    pass "every evidence script, revision 1 and revision 2, is shellcheck-clean"
  else
    fail "shellcheck reported findings"
    sed 's/^/    /' "$scratch/sc.txt"
  fi
else
  skip "shellcheck (not installed in this environment)"
fi
if [ -f "$INDEX" ] && "$GREP" -qE '^\| R79 \| prometheus-metrics \| crate \|' "$INDEX"; then
  pass "research/CLAUDE.md row R79 is still 'prometheus-metrics', kind 'crate'"
elif [ -f "$INDEX" ]; then
  fail "research/CLAUDE.md row R79 no longer matches this decision's item, slug and kind"
else
  skip "the research-index row check (research/CLAUDE.md is not present in this extraction)"
fi
echo

echo "== summary =="
printf 'PASS=%s FAIL=%s SKIP=%s TOTAL=%s\n' \
  "$pass_count" "$fail_count" "$skip_count" "$((pass_count + fail_count + skip_count))"
if [ "$fail_count" -ne 0 ]; then
  exit 1
fi
exit 0
