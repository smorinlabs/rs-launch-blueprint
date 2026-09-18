#!/usr/bin/env bash
# R54 revision 2 — the NEW assertions added to answer the round-1 judgment audit
# (review/audit-fable.md, findings JF-1 .. JF-4).
#
# Revision 1's `check.sh`, `check.log`, `check-rerun.log`, `shellcheck.log`,
# `walkup_probe.rs` and all thirteen files under `snapshots/` are CITED artifacts
# and stay byte-identical; group `B` below asserts that by sha256 rather than
# asserting it in prose. Every other check here is new.
#
# Like `check.sh`, each check asserts on CONTENT and prints one stable
# `PASS`/`FAIL`/`SKIP` line. There is no network access in this script at all, so
# its log is fully deterministic: rerunning it in place and rerunning it from a
# clean `git archive HEAD` extraction produce the same lines apart from the one
# check that needs a git history (`V08`), which names itself in a `SKIP`.
#
# Nothing is written outside this directory's own log files.

# shellcheck disable=SC2016  # the needles are literal quotations; `$` and backticks inside them must NOT expand.

set -u
set -o pipefail

GREP=/usr/bin/grep
FAILURES=0
SKIPPED=0

EVIDENCE_DIR="$(cd "$(dirname "$0")" && pwd)"
SNAP="$EVIDENCE_DIR/snapshots"
REPO_ROOT="$(cd "$EVIDENCE_DIR/../../../../../.." && pwd)"
RUN_DIR="$(cd "$EVIDENCE_DIR/../.." && pwd)"
DEC="$RUN_DIR/review/DECISION.md"
R55_DEC="$REPO_ROOT/research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/review/DECISION.md"
R55_AUDIT="$REPO_ROOT/research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/review/audit-fable.md"
OPENAI_RAW="$RUN_DIR/raw/doxa-openai.normalized.md"
OPUS_RAW="$RUN_DIR/raw/opus.md"
BASELINE="$REPO_ROOT/docs/port/BASELINE-REVIEW.md"
REG="$REPO_ROOT/docs/port/PARAMETERS.md"

pass() { echo "PASS $1 $2"; }
fail() { echo "FAIL $1 $2"; FAILURES=$((FAILURES + 1)); }
skip() { echo "SKIP $1 $2"; SKIPPED=$((SKIPPED + 1)); }

sha_of() { shasum -a 256 "$1" | awk '{print $1}'; }

# assert_contains <id> <file> <needle> <label>
assert_contains() {
  local id="$1" file="$2" needle="$3" label="$4" n
  if [ ! -s "$file" ]; then
    fail "$id" "$label (missing or empty input)"
    return
  fi
  n="$("$GREP" -c -F -- "$needle" "$file")"
  if [ "$n" -ge 1 ]; then
    pass "$id" "$label (/usr/bin/grep -c -F matches=$n)"
  else
    fail "$id" "$label (/usr/bin/grep -c -F matches=0)"
  fi
}

# assert_sha <id> <file> <expected> <label>
assert_sha() {
  local id="$1" file="$2" want="$3" label="$4" got
  if [ ! -f "$file" ]; then
    fail "$id" "$label (file absent)"
    return
  fi
  got="$(sha_of "$file")"
  if [ "$got" = "$want" ]; then
    pass "$id" "$label ($want)"
  else
    fail "$id" "$label (got $got, want $want)"
  fi
}

echo "=== R54 revision 2 evidence checks (JF-1 .. JF-4) ==="
echo "repo-root  $REPO_ROOT"
echo "run-dir    ${RUN_DIR#"$REPO_ROOT"/}"
echo "grep       $GREP ($($GREP --version | head -1))"
echo "network    none — every check reads a file already in the repository"
echo

# ---------------------------------------------------------------------------
# B — revision 1's cited artifacts are byte-identical. This is the addendum's
#     "everything the audit reproduced stays byte-identical" rule, asserted.
# ---------------------------------------------------------------------------
assert_sha B01 "$EVIDENCE_DIR/check.sh" 7e22e8ffc7c4ae15b87c587250e6dc8914c18ab2273be2c14127a7bfa13a1894 'revision 1 check.sh is unchanged'
assert_sha B02 "$EVIDENCE_DIR/check.log" a1f676c92f523faeecd5c2cd6c6e088cbed968950ec4fa085909acc4a2a3a9de 'revision 1 check.log is unchanged'
assert_sha B03 "$EVIDENCE_DIR/check-rerun.log" a1f676c92f523faeecd5c2cd6c6e088cbed968950ec4fa085909acc4a2a3a9de 'revision 1 check-rerun.log is unchanged (and still equal to check.log)'
assert_sha B04 "$EVIDENCE_DIR/walkup_probe.rs" faa0e5de7bf4f42e21c09c07ea1f3084c92b51244869efd9ae6a02a0128ec094 'revision 1 walkup_probe.rs is unchanged'
assert_sha B05 "$EVIDENCE_DIR/shellcheck.log" e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 'revision 1 shellcheck.log is unchanged (empty: shellcheck reported nothing)'
SNAPCOUNT="$(find "$SNAP" -type f | wc -l | tr -d ' ')"
SNAPDIGEST="$(cd "$SNAP" && shasum -a 256 -- * | sort | shasum -a 256 | awk '{print $1}')"
if [ "$SNAPCOUNT" = "13" ] && [ "$SNAPDIGEST" = "fa53d95ac8143ce41b223c2826f4ff366f82413063dbc0c0f5f2ec94c59878cf" ]; then
  pass B06 "all 13 revision-1 snapshots are unchanged (digest of the sorted sha256 manifest: $SNAPDIGEST)"
else
  fail B06 "snapshots moved (count=$SNAPCOUNT digest=$SNAPDIGEST)"
fi

# ---------------------------------------------------------------------------
# V — JF-1: R55's true state.
# ---------------------------------------------------------------------------
assert_contains V01 "$R55_DEC" '# 2026-09-17 — R55 — config-error-tolerance (bundle, Focused) — decision (revision 3)' 'JF-1: R55 is at revision 3, not revision 2'
assert_sha V02 "$R55_DEC" 5d358c1fda2a5ff2782b916f3ca81cf52bbbafd75748774b114345c72a6edd9b 'JF-1: revision 3 carries the sha256 that revision 1 already pinned at check D00b'
if "$GREP" -q -F 'PASS D00b 5d358c1fda2a5ff2782b916f3ca81cf52bbbafd75748774b114345c72a6edd9b' "$EVIDENCE_DIR/check.log"; then
  pass V03 "JF-1: revision 1's own check.log pinned that same sha256 — the synthesis hashed revision 3 and named it revision 2"
else
  fail V03 "JF-1: check.log does not pin 5d358c1f… at D00b"
fi
assert_contains V04 "$R55_DEC" '**The recommendation does not move**' 'JF-1: revision 3 preserves revision 2 recommendation'
assert_contains V05 "$R55_DEC" "the merge over sanitized tables in R54's order followed by" 'JF-1: the D01 sentence survives verbatim into revision 3'
assert_contains V06 "$R55_DEC" 'owns merge depth and precedence order' 'JF-1: the D02 sentence survives verbatim into revision 3'
assert_contains V07 "$R55_DEC" "validate each layer's leaves before precedence merge" 'JF-1: the D03 sentence survives verbatim into revision 3'
assert_contains V08 "$R55_AUDIT" 'verdict: approve' 'JF-1: R55 revision 3 was approved by its round-3 judgment audit'
assert_contains V09 "$R55_AUDIT" 'decision-sha256: 5d358c1fda2a5ff2782b916f3ca81cf52bbbafd75748774b114345c72a6edd9b' 'JF-1: that approval is against revision 3 exactly'

if [ -d "$REPO_ROOT/.git" ] || [ -f "$REPO_ROOT/.git" ]; then
  R55T="$(git -C "$REPO_ROOT" log -1 --format=%ct 439da7d 2>/dev/null)"
  R54T="$(git -C "$REPO_ROOT" log -1 --format=%ct 0bf66ee 2>/dev/null)"
  if [ -n "${R55T:-}" ] && [ -n "${R54T:-}" ] && [ "$R55T" -lt "$R54T" ]; then
    pass V10 "JF-1: R55 revision 3 (439da7d) was committed $(( (R54T - R55T) / 60 ))m$(( (R54T - R55T) % 60 ))s before this item's synthesis commit (0bf66ee)"
  else
    fail V10 "JF-1: could not establish that 439da7d precedes 0bf66ee (r55=${R55T:-unset} r54=${R54T:-unset})"
  fi
else
  skip V10 "JF-1 commit ordering — no git history here (a git archive HEAD extraction carries no commits)"
fi

# ---------------------------------------------------------------------------
# V — JF-2: the dissent is now recorded where the coupling bullet says it is.
# ---------------------------------------------------------------------------
assert_contains V11 "$DEC" '**Disagreement 7 — where the `$XDG_CONFIG_DIRS` list lives.' 'JF-2: `## Engines` carries the seventh disagreement'
assert_contains V12 "$DEC" 'a fifth `Paths` accessor' 'JF-2: the disputed disposition is named in the decision'
assert_contains V13 "$OPUS_RAW" 'R57 adds a fifth accessor to `Paths`, keeping one directory authority' 'JF-2: the dissent quoted in Disagreement 7 is `raw/opus.md`s own wording'

# ---------------------------------------------------------------------------
# V — JF-3: the Doxa/OpenAI owned-parameter declaration, counted from the twin.
# ---------------------------------------------------------------------------
OWNS_BLOCK="$(awk 'NR>=745 && NR<=759' "$OPENAI_RAW")"
OWNS_N="$(printf '%s\n' "$OWNS_BLOCK" | "$GREP" -c '^`owns ')"
if [ "$OWNS_N" = "8" ]; then
  pass V14 "JF-3: doxa-openai.normalized.md:745-759 declares exactly 8 answer-level \`owns\` parameters"
else
  fail V14 "JF-3: doxa-openai.normalized.md:745-759 declares $OWNS_N answer-level \`owns\` parameters (expected 8)"
fi
OWNS_NAMES="$(printf '%s\n' "$OWNS_BLOCK" | "$GREP" '^`owns ' | awk '{print $2}' | tr '\n' ' ')"
if [ "$OWNS_NAMES" = "config-discovery-scopes system-config-path system-config-order user-config-path project-config-path merge-semantics config-selector-env-alias config-selector-precedence " ]; then
  pass V15 "JF-3: the eight names are exactly those the decision now lists"
else
  fail V15 "JF-3: names read as [$OWNS_NAMES]"
fi
if printf '%s\n' "$OWNS_BLOCK" | "$GREP" -q '^`owns project-search'; then
  fail V16 "JF-3: project-search IS in the answer-level block after all"
else
  pass V16 "JF-3: project-search is NOT among the answer-level eight"
fi
if awk 'NR==401' "$OPENAI_RAW" | "$GREP" -q -F 'owns project-search = nearest ancestor containing <tool>_config.toml'; then
  pass V17 "JF-3: project-search is a member-level line at doxa-openai.normalized.md:401"
else
  fail V17 "JF-3: project-search not found at doxa-openai.normalized.md:401"
fi
assert_contains V18 "$DEC" 'declares **eight** owned parameters' 'JF-3: the decision now states eight'
# The superseded count must survive exactly once, and only inside the revision
# note's JF-3 row, where it is quoted as superseded wording rather than asserted.
V19_ALL="$("$GREP" -c -F 'declares four owned parameters' "$DEC")"
V19_NOTE="$("$GREP" -c -E '^\| \*\*JF-3\*\*.*declares four owned parameters' "$DEC")"
if [ "$V19_ALL" = "1" ] && [ "$V19_NOTE" = "1" ]; then
  pass V19 "JF-3: the superseded count survives exactly once, inside the revision note's JF-3 row, and nowhere as an assertion"
else
  fail V19 "JF-3: 'declares four owned parameters' occurs $V19_ALL times, $V19_NOTE of them in the JF-3 note row (expected 1 and 1)"
fi

# ---------------------------------------------------------------------------
# V — JF-4: the owner-question quotation belongs to BASELINE-REVIEW.md:193.
# ---------------------------------------------------------------------------
QUOTE="whether py's absoluteness check (\`src/py_launch_blueprint/core/paths.py:73\`) is part of the inherited contract or a py-only nuance"
if awk 'NR==193' "$BASELINE" | "$GREP" -q -F -- "$QUOTE"; then
  pass V20 "JF-4: the quoted sentence is verbatim at docs/port/BASELINE-REVIEW.md:193"
else
  fail V20 "JF-4: the quoted sentence is not at docs/port/BASELINE-REVIEW.md:193"
fi
if awk 'NR==113' "$BASELINE" | "$GREP" -q -F -- "$QUOTE"; then
  fail V21 "JF-4: the quoted sentence IS at :113 after all"
else
  pass V21 "JF-4: docs/port/BASELINE-REVIEW.md:113 does not contain that sentence"
fi
if awk 'NR==113' "$BASELINE" | "$GREP" -q -F 'blocked pending R54'; then
  pass V22 "JF-4: :113 is the F247 adjudication row, status 'blocked pending R54' — still the right citation for the pending row"
else
  fail V22 "JF-4: :113 is not the F247 adjudication row"
fi

# The two carried BASELINE-REVIEW: lines are preservation targets and must NOT
# have been edited by this revision, including the `:113` inside the F247 line.
for pair in "V23:201:F232" "V24:232:F247"; do
  id="${pair%%:*}"; rest="${pair#*:}"; line="${rest%%:*}"; label="${rest#*:}"
  needle="$(awk -v n="$line" 'NR==n' "$OPUS_RAW")"
  if [ -n "$needle" ] && "$GREP" -q -F -x -- "$needle" "$DEC"; then
    pass "$id" "the carried $label BASELINE-REVIEW: line is still byte-identical to raw/opus.md:$line"
  else
    fail "$id" "the carried $label BASELINE-REVIEW: line no longer matches raw/opus.md:$line"
  fi
done

# ---------------------------------------------------------------------------
# V — the five `- assumes` lines, re-asserted independently of check.sh.
# ---------------------------------------------------------------------------
i=0
for param in msrv-policy rust-edition target-os-matrix license error-taxonomy-exit-codes; do
  i=$((i + 1))
  want="$(awk -F' \\| ' -v p="$param" '$0 ~ "^\\| " p " \\|" {print $4}' "$REG")"
  got="$(awk -v p="$param" 'index($0, "- assumes " p " = ") == 1 {print substr($0, length("- assumes " p " = ") + 1)}' "$DEC")"
  if [ -n "$want" ] && [ "$want" = "$got" ]; then
    pass "V2$((4 + i))" "- assumes $param unchanged and byte-identical to docs/port/PARAMETERS.md (${#want} bytes)"
  else
    fail "V2$((4 + i))" "- assumes $param differs (registry ${#want} bytes, decision ${#got} bytes)"
  fi
done

# ---------------------------------------------------------------------------
# V — the revision-2 envelope itself.
# ---------------------------------------------------------------------------
assert_contains V30 "$DEC" '# 2026-09-18 — R54 — config-discovery-tiers (bundle, Deep) — decision (revision 2)' 'the decision is retitled to revision 2, date first'
for f in JF-1 JF-2 JF-3 JF-4; do
  assert_contains "V3${f#JF-}" "$DEC" "**$f" "the revision note names $f"
done
V35_N="$("$GREP" -c -E '^## Supersedes' "$DEC")"
if [ "$V35_N" = "0" ]; then
  pass V35 'no "## Supersedes" HEADING — this item is unpublished (the string appears only in the revision note, saying so)'
else
  fail V35 "a ## Supersedes heading is present ($V35_N)"
fi

echo
echo "failures=$FAILURES skipped=$SKIPPED"
if [ "$FAILURES" -ne 0 ]; then
  exit 1
fi
exit 0
