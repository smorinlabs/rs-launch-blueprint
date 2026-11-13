#!/usr/bin/env bash
# R12 revision-4 evidence: every file:line citation in DECISION.md resolves to
# the content it is cited for (content-anchored, not line-count-anchored), and
# no line citation in DECISION.md is left without a check here.
# shellcheck disable=SC2016  # backticks in the anchors are literal Markdown, not expansion
set -euo pipefail
export PATH="/Users/stevemorin/.local/bin:/opt/homebrew/bin:$PATH"

ROOT="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
RUN="$ROOT/research/runs/R12/2026-09-26T190134Z-d0c66b769758"
DEC="$RUN/review/DECISION.md"
MUSE="$RUN/raw/muse.md"; OPUS="$RUN/raw/opus.md"
R11="$ROOT/research/topics/11-ci-workflow-job-structure/DECISION.md"
COMM="$ROOT/docs/port/COMMONALITY.md"
RB="$ROOT/research/RUNBOOK.md"
DIV="$ROOT/docs/port/DIVERGENCE-ANALYSIS.md"
R17="$ROOT/research/topics/17-secret-scanning-ci-workflow/DECISION.md"
R38="$ROOT/research/topics/38-commit-message-linter/DECISION.md"
BR="$ROOT/docs/port/BASELINE-REVIEW.md"
BS="$ROOT/docs/planning/p02/baseline-samples.md"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "PASS $1"; }
bad() { FAIL=$((FAIL+1)); echo "FAIL $1 -- $2"; }

at() { # $1 id  $2 file  $3 first-line  $4 last-line  $5 fixed-string anchor
  if sed -n "$3,$4p" "$2" | grep -qF -- "$5"; then ok "$1"; else bad "$1" "$(basename "$2"):$3-$4 lacks: $5"; fi
}

# ---- raw/muse.md ----
at C-muse-30      "$MUSE" 30 30 'two jobs, `ci` (matrixed) and advisory `bun-lane` with `continue-on-error: true`'
at C-muse-52      "$MUSE" 52 52 'The `always()` is load-bearing'
at C-muse-56      "$MUSE" 56 56 'correctly excluded from gating'
at C-muse-60      "$MUSE" 60 60 'justified structural difference'
at C-muse-60b     "$MUSE" 60 60 'its advisory second lane is correctly non-voting'
at C-muse-60c     "$MUSE" 60 60 "No \`BASELINE-REVIEW:\` finding: F041 is this item's own \`DIVERGENT\` row, appointed to be decided here, not an inherited baseline."
at C-muse-76      "$MUSE" 76 76 '`ci` + advisory `bun-lane`'
at C-muse-92      "$MUSE" 92 92 'the same `ci.yml` gates all three'
at C-muse-94      "$MUSE" 94 94 '**CLI.**'
at C-muse-96      "$MUSE" 96 96 "R04's semver job and R35's coverage job"
at C-muse-98      "$MUSE" 98 98 'Under R11'"'"'s accepted design `web` is fail-closed'
at C-muse-102-111 "$MUSE" 102 111 'always-on aggregate required check'
at C-muse-102     "$MUSE" 102 102 'one job named `ci-ok` in `.github/workflows/ci.yml`, branch protection (or its'
at C-muse-107    "$MUSE" 107 107 'the py-verbatim loop — fail on `failure` or `cancelled`'
at C-muse-113-117 "$MUSE" 113 117 '### Ranked runner-up'
at C-muse-121     "$MUSE" 121 121 'Versus per-job required checks'
at C-muse-147     "$MUSE" 147 147 '`CONTRIBUTING.md`'

# ---- raw/opus.md ----
at C-opus-5       "$OPUS" 5 5 'should add one aggregate job, `ci-ok`'
at C-opus-50      "$OPUS" 50 50 'classic: **24 individual contexts**'
at C-opus-78      "$OPUS" 78 78 '@ `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`) has a single job, `ci`'
at C-opus-84      "$OPUS" 84 84 'BASELINE-REVIEW: F041'
at C-opus-130-136 "$OPUS" 130 136 '`always()` or `!cancelled()`'
at C-opus-198-205 "$OPUS" 198 205 'ci-ok folds in every other ci.yml job'
at C-opus-248     "$OPUS" 248 248 "length > 0 and all(.[]; .result == \"success\" or .result == \"skipped\")"
at C-opus-321-327 "$OPUS" 321 327 'need a token with read access to checks'
at C-opus-343     "$OPUS" 343 343 'All three shapes share one `ci.yml` (R11)'
at C-opus-345     "$OPUS" 345 345 'A failed `plan` would skip it'
at C-opus-346     "$OPUS" 346 346 '`check (ubuntu-latest)` and `check (macos-latest)`'
at C-opus-347     "$OPUS" 347 347 'a *step* conditioned on the `web` output'
at C-opus-351-363 "$OPUS" 351 363 '### Recommendation'
at C-opus-359     "$OPUS" 359 359 'fails unless `needs` is non-empty'
at C-opus-360     "$OPUS" 360 360 'Add the completeness guard as a step of R11'"'"'s `workflow-lint` job'
at C-opus-361     "$OPUS" 361 361 '`integration_id: 15368`'
at C-opus-373-380 "$OPUS" 373 380 'Option C — the same aggregate job computed by `re-actors/alls-green`'
at C-opus-381     "$OPUS" 381 381 'Second runner-up: **Option E, individual listing**'
at C-opus-423-438 "$OPUS" 423 438 'repos/<owner>/<repo>/rulesets'
at C-opus-545     "$OPUS" 545 545 'single job `ci`'

# ---- published prerequisite, ledger, runbook ----
at C-r11-180      "$R11" 180 180 'either `plan` is itself a required check'
at C-comm-31      "$COMM" 31 31 '| F025 | merge_group trigger'
at C-comm-47      "$COMM" 47 47 '| F041 | Single aggregate required-status-check job'
at C-runbook-73-76 "$RB" 73 76 'Q17.A (2026-09-27)'
at C-runbook-98-103 "$RB" 98 103 'An item listed in `empirical_auditor_overrides` runs its empirical audit on'

# ---- divergence analysis: the inherited class-E baseline for F041's ts absence ----
at C-div-91       "$DIV" 91 91 '| R12 aggregate-required-status-check | item |'
at C-div-91b      "$DIV" 91 91 'absent — no aggregator job | no recorded reason; inferred:'
at C-div-91c      "$DIV" 91 91 "ts's smaller job count doesn't | E |"
at C-div-251      "$DIV" 251 251 'R11 and R12 (F038/F040, F041) have no `D-0nn` recorded reason'
at C-div-251b     "$DIV" 251 251 'I classified both E'
at C-div-251c     "$DIV" 251 251 'based on inference from the tool counts, not a cited rationale'

# ---- published R17 and R38: the merge_group handover for other gating workflows ----
at C-r17-93      "$R17" 93 93 'triggered on `pull_request` and on `push` to `main`'
at C-r17-165     "$R17" 165 165 'no required status check for R12'
at C-r38-113     "$R38" 113 113 'merge_group:   # required-check no-op inside the merge queue (F025)'
if grep -q 'merge_group' "$R17"; then bad "C-r17-nomg" "R17 DECISION.md now mentions merge_group"; else ok "C-r17-nomg published R17 DECISION.md has no merge_group mention"; fi

# ---- programme pins for the py/ts source trees ----
at C-br-7-8      "$BR" 7 8 '(Python `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, TypeScript'
at C-br-7-8b     "$BR" 7 8 '`cb1cbcb2e88b898e8c081b0abbfabc1630079c00`'
at C-bs-6-8      "$BS" 6 8 'The source commits remain Python'

# ---- completeness: every line citation in DECISION has a check above ----
if python3 - "$DEC" "$0" <<'EOF'
import re, sys
dec = open(sys.argv[1]).read()
me = open(sys.argv[2]).read()
checked = set()
for m in re.finditer(r'^at (C-[a-z0-9]+)-([0-9]+(?:-[0-9]+)?)b?\s', me, re.M):
    checked.add((m.group(1), m.group(2)))
prefix = {"raw/muse.md": "C-muse", "raw/opus.md": "C-opus", "DECISION.md": "C-r11",
          "17-secret-scanning-ci-workflow/DECISION.md": "C-r17",
          "38-commit-message-linter/DECISION.md": "C-r38",
          "BASELINE-REVIEW.md": "C-br", "baseline-samples.md": "C-bs",
          "COMMONALITY.md": "C-comm", "RUNBOOK.md": "C-runbook",
          "DIVERGENCE-ANALYSIS.md": "C-div"}
missing = []
last = None
# explicit file:line cites, then bare `:N` cites that continue the last named file
for m in re.finditer(r'`([^`\s]*?(raw/muse\.md|raw/opus\.md|17-secret-scanning-ci-workflow/DECISION\.md|38-commit-message-linter/DECISION\.md|DECISION\.md|COMMONALITY\.md|RUNBOOK\.md|DIVERGENCE-ANALYSIS\.md|BASELINE-REVIEW\.md|baseline-samples\.md)):([0-9]+(?:-[0-9]+)?)`|`:([0-9]+(?:-[0-9]+)?)`', dec):
    if m.group(2):
        last = prefix[m.group(2)]; ln = m.group(3)
    else:
        ln = m.group(4)
        if last is None:
            missing.append(f"bare :{ln} with no preceding file"); continue
    if (last, ln) not in checked:
        missing.append(f"{last}-{ln}")
print("line citations checked:", len(checked))
assert not missing, f"uncovered: {sorted(set(missing))}"
print("every DECISION line citation is covered")
EOF
then ok "C-complete every file:line citation in DECISION.md has an anchored check"; else bad "C-complete" "uncovered citation"; fi

echo "RESULT PASS=$PASS FAIL=$FAIL SKIP=0"
[ "$FAIL" -eq 0 ]
