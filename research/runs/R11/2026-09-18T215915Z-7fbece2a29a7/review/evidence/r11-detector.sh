#!/usr/bin/env bash
# R11 check 2 - the plan job's detector body, EXTRACTED FROM THE FIXTURE rather
# than retyped, driven against fourteen synthetic changed-file lists. The only
# edit made to the extracted body is replacing its one `git diff` line with the
# test's input, and that edit is asserted to have applied.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
FIXTURE="$HERE/ci.candidate.yml"
GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0

pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$*"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$*"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s\n' "$*"; }

TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/r11-detector.XXXXXX")"
trap 'rm -rf "$TMPROOT"' EXIT

if [ ! -f "$FIXTURE" ]; then
  fail "D0a the candidate fixture is missing at $FIXTURE"
  printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
  exit 1
fi

# --- extract the body between the fixture's own markers --------------------
RAW="$TMPROOT/body.raw"
sed -n '/# R11-DETECTOR-BEGIN/,/# R11-DETECTOR-END/p' "$FIXTURE" \
  | sed '1d;$d' | sed 's/^          //' > "$RAW"
if [ -s "$RAW" ]; then
  pass "D0a the detector body extracted from the fixture is $(wc -l < "$RAW" | tr -d ' ') lines"
else
  fail "D0a extraction between R11-DETECTOR-BEGIN and R11-DETECTOR-END produced nothing"
  printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
  exit 1
fi

if [ "$("$GREP" -c 'git diff --no-ext-diff --no-textconv --name-only' "$RAW")" -eq 1 ]; then
  pass "D0b the extracted body contains exactly one git diff line, the one the driver replaces"
else
  fail "D0b the extracted body does not contain exactly one git diff line"
fi

BODY="$TMPROOT/body.sh"
# shellcheck disable=SC2016  # the $ signs below are sed regex anchors and a literal replacement, not shell expansions
sed 's|^changed="\$(git diff .*)"$|changed="${CHANGED_INPUT}"|' "$RAW" > "$BODY"
if cmp -s "$RAW" "$BODY"; then
  fail "D0c the git-diff substitution did not apply, so this script would be testing an unrunnable body"
  printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
  exit 1
else
  pass "D0c the git-diff line was replaced by the driver input; every other line is the fixture's"
fi

DRIVER="$TMPROOT/driver.sh"
{
  printf 'set -euo pipefail\n'
  cat "$BODY"
} > "$DRIVER"

if shellcheck --shell=bash --severity=warning "$DRIVER" >"$TMPROOT/sc.out" 2>&1; then
  pass "D0d the extracted detector body is shellcheck-clean at severity=warning"
else
  if command -v shellcheck >/dev/null 2>&1; then
    fail "D0d shellcheck reports on the extracted body: $(head -3 "$TMPROOT/sc.out" | tr '\n' ' ')"
  else
    skip "D0d shellcheck is not on PATH - the extracted body was not linted"
  fi
fi

# run_case <id> <event> <changed-files-newline-list> <expected "code web workflows docs"> <what it shows>
run_case() {
  c_id="$1"; c_event="$2"; c_changed="$3"; c_want="$4"; c_says="$5"
  c_out="$TMPROOT/$c_id.out"
  : > "$c_out"
  set +e
  GITHUB_OUTPUT="$c_out" EVENT_NAME="$c_event" BASE_SHA="0000000" \
    CHANGED_INPUT="$c_changed" bash "$DRIVER" > "$TMPROOT/$c_id.log" 2>&1
  c_exit=$?
  set -e
  if [ "$c_exit" -ne 0 ]; then
    fail "$c_id the detector body exited $c_exit: $(head -2 "$TMPROOT/$c_id.log" | tr '\n' ' ')"
    return
  fi
  c_got="$("$GREP" -E '^(code|web|workflows|docs)=' "$c_out" | sort \
    | sed 's/^code=/1 /;s/^web=/2 /;s/^workflows=/3 /;s/^docs=/4 /' | sort | cut -d' ' -f2 | tr '\n' ' ')"
  c_got="${c_got% }"
  if [ "$c_got" = "$c_want" ]; then
    pass "$c_id code/web/workflows/docs = $c_got - $c_says"
  else
    fail "$c_id code/web/workflows/docs = '$c_got', expected '$c_want' - $c_says"
  fi
}

run_case D0 push 'docs/guide.md' 'true true true true' \
  "a non-pull_request event is never skip-gated, so a push to main and a merge_group entry run every job"
run_case D1 pull_request 'docs/guide.md
docs/adr/0001.md' 'false false false true' \
  "a docs-only pull request skips the whole compile tier"
run_case D2 pull_request 'README.md' 'true false false true' \
  "README.md is a packaging input (R49's [package] include), so it is NOT skippable"
run_case D2b pull_request 'CHANGELOG.md' 'true false false true' \
  "CHANGELOG.md is in the same include allow-list, so it is NOT skippable either - the correction this decision makes to the Opus raw, whose skip-list let it through on the .md rule"
run_case D2c pull_request 'LICENSE-MIT' 'true false false false' \
  "LICENSE-MIT is in the same allow-list - the Opus raw skip-listed it by name"
run_case D3 pull_request 'crates/core/src/lib.rs' 'true false false false' \
  "a core source change runs the compile tier and nothing web-only"
run_case D4 pull_request 'crates/web/src/routes.rs
crates/web/tests/web_api.rs' 'true true false false' \
  "R69 revision 10's crates/web/** keys drive the web output"
run_case D5 pull_request 'src/bin/rslbp-serve.rs' 'true true false false' \
  "the serve binary's own source file also sets web, per R69's second key"
run_case D6 pull_request '.github/workflows/ci.yml' 'true true true false' \
  "a workflow edit sets workflows; it also sets code and web because a workflow file is not on the skip-list, which is the conservative direction"
run_case D7 pull_request 'Cargo.lock' 'true false false false' \
  "a lockfile change is a compile input"
run_case D8 pull_request '' 'false false false false' \
  "the degenerate empty diff skips every gated job, all of which then report Success"
run_case D9 pull_request 'docs/a.md
crates/cli/src/main.rs' 'true false false true' \
  "a mixed pull request pays for the compile tier; docs and code are independent keys, not a partition"
run_case D10 pull_request '.vscode/settings.json' 'false false false false' \
  "editor furniture is skippable and does not set docs"
run_case D11 pull_request '.github/ISSUE_TEMPLATE/bug.yml' 'false false false false' \
  "an issue template is skippable and does NOT set workflows, because the workflows key matches .github/workflows/ only"

# --- the correction, executed against the raw report's own skip-list --------
# Rebuild the body with the Opus raw's skip-list and packaging rule and show
# that LICENSE-MIT and CHANGELOG.md come out code=false under it.
OLD="$TMPROOT/old.sh"
sed -e "s|^skip=.*|skip='^docs/\|^\\\\.vscode/\|\\\\.md\$\|^LICENSE-MIT\$\|^LICENSE-APACHE\$\|^\\\\.github/ISSUE_TEMPLATE/'|" \
    -e "s|^packaging=.*|packaging='^README\\\\.md\$'|" "$DRIVER" > "$OLD"
if cmp -s "$DRIVER" "$OLD"; then
  fail "D12a the raw-report skip-list substitution did not apply"
else
  pass "D12a the raw report's skip-list and README-only packaging rule were substituted into a second driver"
  for pair in "LICENSE-MIT:D12b" "CHANGELOG.md:D12c"; do
    f="${pair%%:*}"; cid="${pair##*:}"
    o="$TMPROOT/$cid.out"; : > "$o"
    GITHUB_OUTPUT="$o" EVENT_NAME=pull_request BASE_SHA=0 CHANGED_INPUT="$f" bash "$OLD" >/dev/null 2>&1
    got="$("$GREP" -E '^code=' "$o" | cut -d= -f2)"
    if [ "$got" = "false" ]; then
      pass "$cid under the raw report's skip-list a $f-only pull request yields code=false, so install-smoke and the packaged-content gate never run on a change to a packaged file - the defect this decision's packaging rule fixes"
    else
      fail "$cid expected code=false under the raw report's skip-list for $f, got '$got'"
    fi
  done
fi

printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
[ "$FAIL" -eq 0 ]
