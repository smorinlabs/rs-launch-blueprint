#!/usr/bin/env bash
# R80 health-probe-endpoints — empirical check, part 1 of 3: the offline
# repository assertions.
#
# Re-verifies at source every load-bearing claim of raw/opus.md that can be
# settled without the network: the registered report's digest and shape, the
# byte-identity of this decision's `- assumes` lines against the live registry,
# the clauses of the coupled decisions the recommendation rests on, the ledger
# rows, and the pinned py/ts source precedent.
#
# Usage: bash check-offline.sh [repo-root]
# Exit status: 0 when no check FAILs, 1 otherwise.

set -euo pipefail

GREP=/usr/bin/grep
ROOT="${1:-}"
if [ -z "$ROOT" ]; then
  HERE="$(cd "$(dirname "$0")" && pwd)"
  ROOT="$(cd "$HERE/../../../../../.." && pwd)"
fi
RUN="research/runs/R80/2026-09-17T034011Z-74765d801b92"
RAW="$ROOT/$RUN/raw/opus.md"
DECISION="$ROOT/$RUN/review/DECISION.md"
REGISTRY="$ROOT/docs/port/PARAMETERS.md"

PASS=0
FAIL=0
SKIP=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s — %s\n' "$1" "$2"; }

want() { # id, file, literal-needle, description
  if [ ! -f "$2" ]; then
    fail "$1" "$4 (file absent: $2)"
  elif $GREP -qF -- "$3" "$2"; then
    pass "$1" "$4"
  else
    fail "$1" "$4 (needle absent: $3)"
  fi
}

echo "=== R80 check-offline.sh ==="
echo "date(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "repo root: $ROOT"
echo "grep: $($GREP --version | head -1)"
echo "python3: $(python3 --version 2>&1)"
# A worktree's .git is a FILE, not a directory; -e covers both.
if [ -e "$ROOT/.git" ]; then echo "git metadata: present"; else echo "git metadata: absent (archive extraction)"; fi

# --------------------------------------------------------------- O1 ----------
EXPECTED_RAW_SHA=dd3bdeae9566ae10ea300c1c2e6727264075523cb2ccce1e95eea9eccc06a0fb
if [ ! -f "$RAW" ]; then
  fail O1 "the registered opus report is missing at $RAW"
else
  ACTUAL_RAW_SHA="$(shasum -a 256 "$RAW" | cut -d' ' -f1)"
  if [ "$ACTUAL_RAW_SHA" = "$EXPECTED_RAW_SHA" ]; then
    pass O1 "raw/opus.md digests to the sha256 the manifest registers ($EXPECTED_RAW_SHA)"
  else
    fail O1 "raw/opus.md digests to $ACTUAL_RAW_SHA, not $EXPECTED_RAW_SHA"
  fi
fi

# --------------------------------------------------------------- O2 ----------
# The registered report must satisfy the bundle answer shape, including the
# '### Members' window rule that keeps every H5 field inside a named member.
if [ -f "$RAW" ] && [ -f "$ROOT/scripts/research_validation.py" ]; then
  set +e
  O2_OUT="$(cd "$ROOT" && python3 - "$RAW" <<'PY' 2>&1
import sys, pathlib
sys.path.insert(0, "scripts")
from research_validation import validate_answer_text
errors = validate_answer_text(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"), "bundle")
print("errors=%d" % len(errors))
for error in errors:
    print(error)
PY
)"
  O2_STATUS=$?
  set -e
  echo "$O2_OUT"
  if [ "$O2_STATUS" -eq 0 ] && [ "$(printf '%s' "$O2_OUT" | head -1)" = "errors=0" ]; then
    pass O2 "validate_answer_text(raw/opus.md, \"bundle\") returns no shape errors"
  else
    fail O2 "validate_answer_text reported shape errors or did not run (exit $O2_STATUS)"
  fi
else
  skip O2 "raw/opus.md or scripts/research_validation.py is absent"
fi

# --------------------------------------------------------------- O3 ----------
# Every '- assumes <param> = <value>' line in THIS decision must be byte-identical
# to the live registry's value column. Publication fails on any divergence.
if [ -f "$DECISION" ] && [ -f "$REGISTRY" ]; then
  set +e
  O3_OUT="$(python3 - "$DECISION" "$REGISTRY" <<'PY' 2>&1
import pathlib, sys
decision = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8").splitlines()
registry = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8").splitlines()
rows = {}
for line in registry:
    if line.startswith("| ") and line.count("|") >= 6:
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) >= 5 and cells[1] in ("fixed", "researched"):
            rows[cells[0]] = cells[3]
claimed = []
for line in decision:
    if line.startswith("- assumes ") and " = " in line:
        name, value = line[len("- assumes "):].split(" = ", 1)
        claimed.append((name.strip(), value))
print("assumes_lines=%d" % len(claimed))
bad = 0
for name, value in claimed:
    if name not in rows:
        print("MISSING-ROW %s" % name); bad += 1
    elif rows[name] != value:
        print("MISMATCH %s" % name)
        print("  decision: %s" % value[:160])
        print("  registry: %s" % rows[name][:160])
        bad += 1
    else:
        print("BYTE-IDENTICAL %s (%d chars)" % (name, len(value)))
print("mismatches=%d" % bad)
PY
)"
  O3_STATUS=$?
  set -e
  echo "$O3_OUT"
  if [ "$O3_STATUS" -eq 0 ] &&
     printf '%s' "$O3_OUT" | $GREP -qF 'assumes_lines=7' &&
     printf '%s' "$O3_OUT" | $GREP -qF 'mismatches=0'; then
    pass O3 "all seven '- assumes' values in DECISION.md are byte-identical to their docs/port/PARAMETERS.md rows"
  else
    fail O3 "the '- assumes' lines do not match the registry, or there are not seven of them"
  fi
else
  skip O3 "DECISION.md or docs/port/PARAMETERS.md is absent"
fi

# --------------------------------------------------------------- O4 ----------
# R80 owns no parameter: its prompt's '- owns:' line is empty and the index row
# carries an em dash. A stray '- owns' line in the decision would be a defect.
if [ -f "$DECISION" ]; then
  OWNS_COUNT="$($GREP -c '^- owns ' "$DECISION" || true)"
  if [ "$OWNS_COUNT" -eq 0 ]; then
    pass O4 "DECISION.md carries 0 '- owns' lines, matching the prompt's empty '- owns:' coupling (counted with $($GREP --version | head -1))"
  else
    fail O4 "DECISION.md carries $OWNS_COUNT '- owns' line(s); R80 owns no registry parameter"
  fi
else
  skip O4 "DECISION.md is absent"
fi

# --------------------------------------------------------------- O5 ----------
# The web-extra-surface publication lag: the live registry still carries revision
# 9's `src/web/` form while R69 revision 10 (owner-accepted, unpublished) moves
# the tree to `crates/web/`. Both halves are asserted so the prose note is earned.
R69R10="$ROOT/research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md"
if [ -f "$R69R10" ] && [ -f "$REGISTRY" ]; then
  R69_OWNS="$($GREP -n '^- owns web-extra-surface = ' "$R69R10" | head -1 || true)"
  R69_LINE="${R69_OWNS%%:*}"
  if [ "$R69_LINE" = "1791" ] &&
     printf '%s' "$R69_OWNS" | $GREP -qF 'crates/web/Cargo.toml' &&
     printf '%s' "$R69_OWNS" | $GREP -qF 'web = ["dep:rs-launch-blueprint-web"]' &&
     $GREP -q '^| web-extra-surface | researched | R69 |.*src/web/' "$REGISTRY"; then
    pass O5 "R69 revision 10's '- owns web-extra-surface' sits at line 1791 and names crates/web/, while the live registry row still carries revision 9's src/web/ form — the publication lag this decision records in prose"
  else
    fail O5 "the R69 revision-10 owns line or the registry's src/web/ form is not where this decision says it is (owns line: ${R69_LINE:-none})"
  fi
else
  skip O5 "R69 revision 10 or the registry is absent"
fi

# --------------------------------------------------------------- O6 ----------
want O6 "$ROOT/research/topics/49-build-target-declaration/DECISION.md" \
  'no build.rs and no build-orchestration crate' \
  "R49's published build-tool-output-shape carries the no-build.rs clause that excludes built, vergen and shadow-rs on fit"

# --------------------------------------------------------------- O7 ----------
if [ -f "$ROOT/docs/port/COMMONALITY.md" ]; then
  if $GREP -q '^| F308 |.*| ADOPT | — |' "$ROOT/docs/port/COMMONALITY.md" &&
     $GREP -q '^| F328 | liveness endpoint reports version + runtime info |.*| DIVERGENT | R80 |' "$ROOT/docs/port/COMMONALITY.md" &&
     $GREP -q '^| F329 | readiness endpoint runs the same diagnostics as the CLI doctor command |.*| DIVERGENT | R80 |' "$ROOT/docs/port/COMMONALITY.md"; then
    pass O7 "the ledger rows are as the prompt states: F308 ADOPT owned by no item, F328 and F329 DIVERGENT and owned by R80"
  else
    fail O7 "F308/F328/F329 are not classified as the decision states"
  fi
else
  skip O7 "docs/port/COMMONALITY.md is absent"
fi

# --------------------------------------------------------------- O8 ----------
# R60 selected option (b) for the extended version data, NOT option (c), the
# `doctor` verb. So `doctor` is not R60's to carry today.
R60="$ROOT/research/topics/60-cli-parsing-framework/DECISION.md"
if [ -f "$R60" ]; then
  if $GREP -qF 'The ruling was (b).' "$R60" &&
     $GREP -qF "extended data moved to a \`doctor\` verb" "$R60"; then
    pass O8 "R60's published decision records the owner ruling as option (b) (--version -o json), with the 'doctor' verb only as unselected option (c) — so the CLI doctor subcommand is owned by no item"
  else
    fail O8 "R60's decision does not record ruling (b) with the doctor verb as option (c)"
  fi
else
  skip O8 "R60's published decision is absent"
fi

# --------------------------------------------------------------- O9 ----------
# R55 and R57 are owner-accepted (unpublished), NOT open as raw/opus.md states.
OWNERDEC="$ROOT/docs/planning/p02/owner-decisions.md"
if [ -f "$OWNERDEC" ]; then
  MISSING=""
  for row in "| W1-R55 |" "| W1-R57 |" "| W1-R02 |" "| W1-R05 |" "| W1-R03 |" "| W1-R56 |"; do
    $GREP -qF "$row" "$OWNERDEC" || MISSING="$MISSING $row"
  done
  if [ -z "$MISSING" ]; then
    pass O9 "owner-decisions section 13 records acceptances for R55, R57, R02, R05, R03 and R56 — so R55 and R57 are accepted-but-unpublished, not open"
  else
    fail O9 "missing acceptance rows:$MISSING"
  fi
else
  skip O9 "docs/planning/p02/owner-decisions.md is absent"
fi

# -------------------------------------------------------------- O10 ----------
want O10 "$OWNERDEC" \
  'W1-CODEX3' \
  "the controller's deferral of the Codex leg is recorded as owner ruling W1-CODEX3 (2026-09-18)"

# -------------------------------------------------------------- O11 ----------
# The licence gate is struck for every dependency and tool.
want O11 "$ROOT/docs/port/OWNER-REVIEW.md" \
  "don't need to check the licensing for any tool we use. Zero license" \
  "the owner's 2026-09-12 licence ruling (Q7.B) is on the record, which is what makes fitness gate 1 inapplicable here"

# -------------------------------------------------------------- O12 ----------
# R70 is being researched in parallel. Its raw report chooses ONE extension
# member and no more, which is a live constraint on /readyz's 503 body.
R70RAW="$ROOT/research/runs/R70/2026-09-17T034010Z-31ad2ef28df7/raw/opus.md"
if [ -f "$R70RAW" ]; then
  if $GREP -qF 'this item adds one extension member and no more' "$R70RAW" &&
     $GREP -qF "\`/readyz\`'s failure body is R80's" "$R70RAW"; then
    pass O12 "R70's in-flight raw report both reserves the envelope to one extension member ('code') and hands /readyz's failure body to R80 — the coupling this decision states and does not decide"
  else
    fail O12 "R70's raw report does not carry the one-extension-member clause and the /readyz hand-off"
  fi
else
  skip O12 "R70's parallel raw report is absent"
fi

# -------------------------------------------------------------- O13 ----------
R51RAW="$ROOT/research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/raw/opus.md"
if [ -f "$R51RAW" ]; then
  if $GREP -qF 'busybox' "$R51RAW" && $GREP -qF 'HEALTHCHECK' "$R51RAW" && $GREP -qF '/healthz' "$R51RAW"; then
    pass O13 "R51's in-flight raw report answers the shell-free-probe question with a static busybox applet and an exec-form HEALTHCHECK against /healthz — stated here, decided by R51"
  else
    fail O13 "R51's raw report does not carry a busybox HEALTHCHECK against /healthz"
  fi
else
  skip O13 "R51's parallel raw report is absent"
fi

# -------------------------------------------------------------- O14 ----------
R79RAW="$ROOT/research/runs/R79/2026-09-17T034011Z-2e1043da0e00/raw/opus.md"
if [ -f "$R79RAW" ]; then
  if $GREP -qF "/metrics\`, \`/healthz\`, \`/readyz\`" "$R79RAW"; then
    pass O14 "R79's in-flight raw report names a three-path ops exclusion set (/metrics, /healthz, /readyz), so a third unversioned ops route is coming"
  else
    fail O14 "R79's raw report does not name the three-path exclusion set"
  fi
else
  skip O14 "R79's parallel raw report is absent"
fi

# -------------------------------------------------------------- O15 ----------
# raw/opus.md says "R77 owns the window's value" for a pre-drain readiness
# propagation pause. R77's own in-flight report owns a drain DEADLINE and names
# no such pause. The absence is the finding, so it is asserted positively (the
# deadline variable exists) and negatively (no propagation pause).
R77RAW="$ROOT/research/runs/R77/2026-09-17T034011Z-5884fd6b6366/raw/opus.md"
if [ -f "$R77RAW" ]; then
  PAUSE_HITS="$($GREP -ciE 'readiness.propagation|propagation delay|pre-drain' "$R77RAW" || true)"
  if $GREP -qF 'RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS' "$R77RAW" && [ "$PAUSE_HITS" -eq 0 ]; then
    pass O15 "R77's in-flight raw report owns the drain deadline (RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS) and mentions a readiness-propagation or pre-drain pause on 0 lines (counted with $($GREP --version | head -1)) — so no item owns that value today"
  else
    fail O15 "R77's raw report does not match the stated state (deadline present, propagation pause hits: $PAUSE_HITS)"
  fi
else
  skip O15 "R77's parallel raw report is absent"
fi

# -------------------------------------------------------------- O16 ----------
# R67's accepted catalog offers no diagnostics row; the two nearest are named.
R67="$ROOT/research/topics/67-error-and-exit-code-contract/DECISION.md"
if [ -f "$R67" ]; then
  DIAG_ROWS="$($GREP -ciE 'RSLB[0-9]{3} (doctor|diagnostic)' "$R67" || true)"
  if $GREP -qF 'RSLB104' "$R67" && $GREP -qF 'RSLB203' "$R67" && [ "$DIAG_ROWS" -eq 0 ]; then
    pass O16 "R67's append-only catalog carries RSLB104 and RSLB203 and 0 rows naming a doctor or diagnostics code (counted with $($GREP --version | head -1)) — the CLI doctor exit code is unassigned"
  else
    fail O16 "R67's catalog does not match the stated state (diagnostics rows: $DIAG_ROWS)"
  fi
else
  skip O16 "R67's published decision is absent"
fi

# -------------------------------------------------------------- O17 ----------
# The accepted revision numbers of the four unpublished inputs this decision
# rests on. raw/opus.md cites R02 revision 1 and R05 revision 2, both superseded
# by evidence-only re-binds.
R02="$ROOT/research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md"
R05="$ROOT/research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md"
R03="$ROOT/research/runs/R03/2026-09-17T033527Z-cd9e6a9555b6/review/DECISION.md"
if [ -f "$R02" ] && [ -f "$R05" ] && [ -f "$R03" ]; then
  if head -1 "$R02" | $GREP -qF '(revision 2)' &&
     head -1 "$R05" | $GREP -qF '(revision 3)' &&
     head -1 "$R03" | $GREP -qF '(revision 1)' &&
     $GREP -qF 'Revision 2 is evidence-only' "$R02"; then
    pass O17 "the accepted-but-unpublished inputs stand at R02 revision 2 (evidence-only re-bind of revision 1), R05 revision 3 and R03 revision 1 — raw/opus.md cites R02 r1 and R05 r2, which this decision corrects"
  else
    fail O17 "the coupled decisions are not at the revisions this decision cites"
  fi
else
  skip O17 "one of R02/R05/R03's run decisions is absent"
fi

# -------------------------------------------------------------- O18 ----------
want O18 "$R02" 'crates/core' \
  "R02 revision 2's four-package workspace names crates/core, the only member both front ends can reach"

# -------------------------------------------------------------- O19 ----------
want O19 "$R05" 'spawn_blocking' \
  "R05 revision 3 routes the web feature's async handlers to the synchronous core through tokio::task::spawn_blocking"

# ----------------------------------------------------- O20..O24: py/ts pins ---
PY_REPO="$HOME/c/py-launch-blueprint"
PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TS_REPO="$HOME/c/ts-launch-blueprint"
TS_PIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00

py_show() { git -C "$PY_REPO" show "$PY_PIN:$1" 2>/dev/null; }

if [ -d "$PY_REPO/.git" ] || [ -e "$PY_REPO/.git" ]; then
  set +e
  APP="$(py_show src/py_launch_blueprint/web/app.py)"; APP_STATUS=$?
  DIAG="$(py_show src/py_launch_blueprint/core/diagnostics.py)"; DIAG_STATUS=$?
  TEST="$(py_show tests/web/test_app.py)"; TEST_STATUS=$?
  CLI="$(py_show src/py_launch_blueprint/cli/main.py)"; CLI_STATUS=$?
  set -e
  if [ $APP_STATUS -eq 0 ] && printf '%s' "$APP" | $GREP -qF '@app.get("/healthz"' &&
     printf '%s' "$APP" | $GREP -qF 'async def readyz(' &&
     printf '%s' "$APP" | $GREP -qF 'status_code=503'; then
    pass O20 "py at $PY_PIN serves /healthz and a readyz that answers 503 — the source precedent F328/F329 record"
  else
    fail O20 "py's web/app.py at the pin does not carry /healthz, readyz and the 503 (git show exit $APP_STATUS)"
  fi

  if [ $DIAG_STATUS -eq 0 ] && [ $CLI_STATUS -eq 0 ] &&
     printf '%s' "$DIAG" | $GREP -qF 'def run_diagnostics(' &&
     printf '%s' "$APP" | $GREP -qF 'run_diagnostics' &&
     printf '%s' "$CLI" | $GREP -qF 'run_diagnostics'; then
    pass O21 "py's run_diagnostics is defined once in core/diagnostics.py and called from BOTH web/app.py and cli/main.py — the 'one source of truth with the CLI' pattern this item ports"
  else
    fail O21 "py's shared-diagnostics pattern is not as stated (diagnostics exit $DIAG_STATUS, cli exit $CLI_STATUS)"
  fi

  # raw/opus.md asserts "there is no test in that file for the 503 branch".
  # That is WRONG, and this check records what is actually there: py tests the
  # 503 branch, but only by SUBSTITUTING run_diagnostics, which is itself the
  # evidence that no real environment reaches it.
  if [ $TEST_STATUS -eq 0 ] &&
     printf '%s' "$TEST" | $GREP -qF 'Missing token/config are warnings, not errors, so readiness holds' &&
     printf '%s' "$TEST" | $GREP -qF 'def test_readyz_failure_is_a_problem_with_diagnostics(' &&
     printf '%s' "$TEST" | $GREP -qF 'monkeypatch.setattr(app_module, "run_diagnostics", lambda _config: failing)' &&
     printf '%s' "$TEST" | $GREP -qF 'assert response.status_code == 503'; then
    pass O22 "py's web test DOES cover the 503 branch (test_readyz_failure_is_a_problem_with_diagnostics), and reaches it only by monkeypatching run_diagnostics with a hand-built failing report — raw/opus.md's claim that no such test exists is wrong, while its underlying point (no real environment reaches the branch) is what the substitution demonstrates"
  else
    fail O22 "py's tests/web/test_app.py does not carry both readyz tests in the form stated (git show exit $TEST_STATUS)"
  fi

  # The error-capable check count, which is the claim that actually carries the
  # design argument: of py's four checks, exactly one can be `error`.
  if [ $DIAG_STATUS -eq 0 ]; then
    PY_NAMES=0
    for check_name in python platform config-file token; do
      if printf '%s' "$DIAG" | $GREP -qF "name=\"$check_name\""; then PY_NAMES=$((PY_NAMES + 1)); fi
    done
    PY_ERROR="$(printf '%s' "$DIAG" | $GREP -cF 'status="ok" if py_ok else "error"' || true)"
    PY_OTHER_ERROR="$(printf '%s' "$DIAG" | $GREP -cE 'status="error"' || true)"
    echo "py distinct check names found: $PY_NAMES of 4; error-capable statuses: $PY_ERROR; unconditional error statuses: $PY_OTHER_ERROR"
    if [ "$PY_NAMES" -eq 4 ] && [ "$PY_ERROR" -eq 1 ] && [ "$PY_OTHER_ERROR" -eq 0 ] &&
       printf '%s' "$DIAG" | $GREP -qF 'MIN_PYTHON = (3, 12)'; then
      pass O27 "py's run_diagnostics builds all four named checks (python, platform, config-file, token) and exactly one of them — python, gated on MIN_PYTHON = (3, 12) — can be error (counted with $($GREP --version | head -1)); Rust has no runtime-toolchain analogue to port"
    else
      fail O27 "py's check set is not the four named checks with exactly one error-capable status (names found: $PY_NAMES of 4, error-capable: $PY_ERROR)"
    fi
  else
    fail O27 "py's core/diagnostics.py could not be read at the pin (git show exit $DIAG_STATUS)"
  fi
else
  skip O20 "no py-launch-blueprint clone at $PY_REPO; the pinned source precedent cannot be read"
  skip O21 "no py-launch-blueprint clone at $PY_REPO"
  skip O22 "no py-launch-blueprint clone at $PY_REPO"
  skip O27 "no py-launch-blueprint clone at $PY_REPO"
fi

if [ -d "$TS_REPO/.git" ] || [ -e "$TS_REPO/.git" ]; then
  set +e
  TS_HITS="$(git -C "$TS_REPO" grep -lniE 'healthz|readyz' "$TS_PIN" -- src 2>/dev/null | wc -l | tr -d ' ')"
  TS_STATUS=$?
  set -e
  if [ "$TS_STATUS" -eq 0 ] || [ -n "$TS_HITS" ]; then
    if [ "${TS_HITS:-0}" -eq 0 ]; then
      pass O23 "ts at $TS_PIN matches healthz|readyz in 0 files under src/ — F303's 'ts has no web service' holds, so nothing cross-repo is owed to ts here"
    else
      fail O23 "ts matches healthz|readyz in $TS_HITS file(s); F303's record would need revisiting"
    fi
  else
    fail O23 "the ts pin could not be searched (git grep exit $TS_STATUS)"
  fi
else
  skip O23 "no ts-launch-blueprint clone at $TS_REPO"
fi

# -------------------------------------------------------------- O24 ----------
# The owner-supplied reference architecture's C15 row, quoted rather than
# paraphrased, and its edition, which the fixed parameter overrides.
REF="$ROOT/$RUN/inputs/owner-reference-axum-companion-stack-2026-09-16.md"
if [ -f "$REF" ]; then
  if $GREP -qF "expose \`/healthz\` (liveness) and \`/readyz\` (readiness, checks DB)" "$REF" &&
     $GREP -qF 'edition = "2021"' "$REF"; then
    pass O24 "the owner reference's C15 row asks for /healthz and /readyz with a DB check, and its Cargo.toml declares edition 2021 — the two rows this decision agrees with and differs from"
  else
    fail O24 "the owner reference does not carry the C15 probe sentence and the edition 2021 line"
  fi
else
  skip O24 "the owner reference input is absent"
fi

# -------------------------------------------------------------- O28 ----------
# This decision states that neither R55's nor R57's owner-accepted decision
# defines a diagnostics check. That is an absolute claim, so it is counted rather
# than read: neither file may name run_diagnostics, doctor, readyz or CheckStatus.
R55="$ROOT/research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/review/DECISION.md"
R57="$ROOT/research/runs/R57/2026-09-17T020714Z-8fdb5c2010e7/review/DECISION.md"
if [ -f "$R55" ] && [ -f "$R57" ]; then
  R55_HITS="$($GREP -ciE 'run_diagnostics|doctor|readyz|CheckStatus' "$R55" || true)"
  R57_HITS="$($GREP -ciE 'run_diagnostics|doctor|readyz|CheckStatus' "$R57" || true)"
  echo "R55 diagnostics-term hits: $R55_HITS; R57: $R57_HITS"
  if [ "$R55_HITS" -eq 0 ] && [ "$R57_HITS" -eq 0 ]; then
    pass O28 "neither R55 revision 3 nor R57 revision 2 names run_diagnostics, doctor, readyz or CheckStatus on any line (0 and 0, counted with $($GREP --version | head -1)) — the check list that could reach CheckStatus::Error is unowned, not merely unpublished"
  else
    fail O28 "R55 or R57 does name a diagnostics term (R55 $R55_HITS, R57 $R57_HITS); the unowned-check-list claim must be softened"
  fi
else
  skip O28 "R55's or R57's accepted decision is absent"
fi

# -------------------------------------------------------------- O25 ----------
# The decision must carry exactly one re-verify line and must not carry a
# Supersedes section (this is revision 1).
if [ -f "$DECISION" ]; then
  RV="$($GREP -c '^re-verify: ' "$DECISION" || true)"
  SUP="$($GREP -c '^## Supersedes' "$DECISION" || true)"
  H2="$($GREP -c '^## ' "$DECISION" || true)"
  if [ "$RV" -eq 1 ] && [ "$SUP" -eq 0 ] && [ "$H2" -eq 4 ]; then
    pass O25 "DECISION.md carries exactly one 're-verify:' line, no '## Supersedes' and exactly four H2 sections (counted with $($GREP --version | head -1))"
  else
    fail O25 "DECISION.md shape is wrong: re-verify lines $RV, Supersedes $SUP, H2 sections $H2"
  fi
else
  skip O25 "DECISION.md is absent"
fi

# -------------------------------------------------------------- O26 ----------
# Fitness gate 1 must be recorded inapplicable, never answered per candidate.
if [ -f "$DECISION" ]; then
  if $GREP -qF 'inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool' "$DECISION"; then
    pass O26 "DECISION.md records fitness gate 1 in the exact form the revision rules require"
  else
    fail O26 "DECISION.md does not record gate 1 as inapplicable in the required wording"
  fi
else
  skip O26 "DECISION.md is absent"
fi

printf '\n=== %d PASS, %d FAIL, %d SKIP ===\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
