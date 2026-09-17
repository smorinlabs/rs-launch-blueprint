#!/usr/bin/env bash
# shellcheck disable=SC2016
# SC2016 is disabled for the whole file: the assertion needles are sibling decisions'
# own text, quoted verbatim, and several contain backticks. Single quotes are required
# precisely so nothing expands.
# R56 evidence — every claim this decision makes about a sibling item, checked against
# that sibling's own text inside this repository. Repo-internal only, so it runs
# unchanged from a `git archive HEAD` extraction with no .git and no network.
# Counts are produced by /usr/bin/grep, named beside each count, because a typed `grep`
# in these shells is `ugrep` and honours .gitignore.
set -euo pipefail
set -o pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../../../../../.." && pwd)"
cd "$root"

fail=0
ok()   { printf 'PASS %s — %s\n' "$1" "$2"; }
bad()  { printf 'FAIL %s — %s\n' "$1" "$2"; fail=$((fail + 1)); }
want() { if [ "$2" = "$3" ]; then ok "$1" "$3"; else bad "$1" "expected [$2], got [$3]"; fi; }
count() { /usr/bin/grep -c "$@" || true; }

printf 'date-utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'repo root: %s\n' "$root"

r67=research/topics/67-error-and-exit-code-contract/DECISION.md
r60=research/topics/60-cli-parsing-framework/DECISION.md
r52=research/topics/52-toml-crate/DECISION.md
r17=research/topics/17-secret-scanning-ci-workflow/DECISION.md
r53=research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/DECISION.md
r55=research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/review/DECISION.md
r57=research/runs/R57/2026-09-17T020714Z-8fdb5c2010e7/review/DECISION.md
r61=research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/DECISION.md

for f in "$r67" "$r60" "$r52" "$r17" "$r53" "$r55" "$r57" "$r61"; do
  if [ -f "$f" ]; then
    printf 'X0-detail %s sha256=%s\n' "$f" "$(shasum -a 256 "$f" | cut -d' ' -f1)"
  else
    bad 'X0 sibling-present' "$f is missing"
  fi
done

# --- R67 (published, owner-accepted): every failure state this policy produces has a
#     row already, so no CONFLICT is raised. Each code is asserted present by name.
for code in RSLB401 RSLB402 RSLB101 RSLB204 RSLB205; do
  n="$(count -- "$code" "$r67")"
  if [ "$n" -ge 1 ]; then ok "X1-${code}" "present in R67 ($n lines, binary /usr/bin/grep)"; else bad "X1-${code}" 'absent from R67'; fi
done
if /usr/bin/grep -q 'RSLB204` secret supplied through a prohibited channel → 2' "$r67"; then
  ok 'X2 RSLB204-text' 'R67 defines RSLB204 as "secret supplied through a prohibited channel → 2"'
else
  bad 'X2 RSLB204-text' 'the RSLB204 row does not read as quoted'
fi
if /usr/bin/grep -q 'RSLB401` credentials absent → 4' "$r67"; then
  ok 'X3 RSLB401-text' 'R67 defines RSLB401 as "credentials absent → 4"'
else
  bad 'X3 RSLB401-text' 'the RSLB401 row does not read as quoted'
fi

# --- R60 (owner-accepted rev 9, published): adding --token-file collides with nothing,
#     and no published sibling already declares a plain --token flag.
want 'X4 R60-has-no---token'  '0' "$(count -- '--token' "$r60")"
want 'X5 R67-has-no---token'  '0' "$(count -- '--token' "$r67")"
want 'X6 R52-has-no---token'  '0' "$(count -- '--token' "$r52")"
clap_version="$(/usr/bin/grep -o 'clap 4\.[0-9.]*' "$r60" | head -1 || true)"
printf 'X7-detail R60 names %s\n' "${clap_version:-<no clap version string found>}"

# --- R53 (owner-accepted rev 2): its schema declares no token field and its own
#     out-of-scope list hands that question to R56, so "the layered config file is never
#     a token source" agrees with the sibling rather than colliding with it.
if /usr/bin/grep -q 'Whether the schema carries a `token` field at all\* — R56' "$r53"; then
  ok 'X8 R53-defers-token-field' 'R53 lists "Whether the schema carries a token field at all" as R56 (F239/F240), out of its own scope'
else
  bad 'X8 R53-defers-token-field' 'R53 does not defer the token-field question to R56; the coupling must be restated'
fi
r53_token_decl="$(/usr/bin/grep -c 'token:' "$r53" || true)"
want 'X8b R53-declares-no-token-field' '0' "$r53_token_decl"

# --- R55 (revision 2, under judgment): the disposition this decision borrows for a
#     `token` key in a layer is R55's unknown-key rule, quoted from R55 itself.
if /usr/bin/grep -q 'Unknown keys warn and never fail, in every layer' "$r55"; then
  ok 'X9 R55-unknown-key-warns' 'R55 (live revision printed below) carries "Unknown keys warn and never fail, in every layer"'
else
  bad 'X9 R55-unknown-key-warns' 'R55 does not carry that clause; the borrowed disposition must be restated'
fi
# R55 is in flight and its revision number moves; the borrowed clause, not the number,
# is what this decision depends on. The live revision line is printed as a fact.
printf 'X10-detail R55 head: %s\n' "$(head -1 "$r55")"
want 'X10 R55-is-a-revision-of-R55' '1' \
  "$(/usr/bin/grep -c '^# .* — R55 — config-error-tolerance (bundle, Focused) — decision (revision ' "$r55" || true)"

# --- R57 (owner-accepted rev 2): the credential file's location builds on its state root.
if /usr/bin/grep -q 'pub fn state_dir(&self)' "$r57"; then
  ok 'X11 R57-state_dir-accessor' 'R57 exposes pub fn state_dir(&self) -> &Path on its template-owned Paths'
else
  bad 'X11 R57-state_dir-accessor' 'R57 exposes no state_dir accessor under that name'
fi
if /usr/bin/grep -q 'etcetera. 0\.11\.0' "$r57"; then
  ok 'X12 R57-etcetera' 'R57 resolves the roots over etcetera 0.11.0'
else
  bad 'X12 R57-etcetera' 'R57 does not name etcetera 0.11.0'
fi

# --- R61 (owner-accepted rev 1): the interactivity gate a stdin token read must respect,
#     and the gap that no masked/password prompt shape is selected.
if /usr/bin/grep -q 'inquire. 0\.9\.4' "$r61"; then
  ok 'X13 R61-inquire' 'R61 selects inquire 0.9.4 behind a template-owned Prompter trait'
else
  bad 'X13 R61-inquire' 'R61 does not name inquire 0.9.4'
fi
want 'X14 R61-selects-no-password-prompt' '0' "$(count -- 'Password' "$r61")"
isterm="$(count -- 'IsTerminal' "$r61")"
if [ "$isterm" -ge 1 ]; then
  ok 'X15 R61-interactivity-gate' "R61 gates interactivity on std::io::IsTerminal ($isterm lines, binary /usr/bin/grep)"
else
  bad 'X15 R61-interactivity-gate' 'R61 names no IsTerminal gate'
fi

# --- R17 (published): the CI secret scanner runs --only-verified, so it cannot backstop
#     a token-in-config policy for this template's own fictional credential.
if /usr/bin/grep -q -- '--only-verified' "$r17"; then
  ok 'X16 R17-only-verified' 'R17 ships TruffleHog with --only-verified, which passes anything it cannot live-verify'
else
  bad 'X16 R17-only-verified' 'R17 does not carry --only-verified'
fi

# --- this item owns no registry parameter, and the registry has no row naming R56.
want 'X17 R56-owns-nothing-in-index' '1' \
  "$(/usr/bin/grep -c '^| R56 | config-secret-policy | bundle | different | DIVERGENT | — |' research/CLAUDE.md || true)"
want 'X18 registry-has-no-R56-row' '0' "$(count -- '| R56 |' docs/port/PARAMETERS.md)"
prompt=research/runs/R56/2026-09-17T033528Z-785d25a9d608/inputs/prompt.md
want 'X19 prompt-owns-line-empty' '1' "$(count -x -- '- owns:' "$prompt")"
want 'X20 prompt-consumes-R67'    '1' "$(count -x -- '- consumes: R67: error-taxonomy-exit-codes' "$prompt")"

# --- the run's own engine inventory: Codex produced no report and said why.
raw=research/runs/R56/2026-09-17T033528Z-785d25a9d608/raw
want 'X21 no-codex-report' '0' "$(/bin/ls "$raw" | count -x -- 'codex.md')"
want 'X22 codex-exit'      '1' "$(cat "$raw/codex-exit.txt")"
if /usr/bin/grep -q 'usage limit' "$raw/codex-transcript.txt"; then
  ok 'X23 codex-refusal-recorded' 'raw/codex-transcript.txt records a usage-limit refusal, not an empty run'
else
  bad 'X23 codex-refusal-recorded' 'the transcript does not record why Codex produced nothing'
fi
want 'X24 opus-report-sha' 'c02aebdd90cb21ca36ce7626b27fba7ca03f0250d6b8501c1546cc3a85d93bef' \
  "$(shasum -a 256 "$raw/opus.md" | cut -d' ' -f1)"
want 'X25 doxa-report-sha' 'a2d31b37e504b3a7146d421cf3abb649fc3ed00da5cd18ea48dafe674c9c24d6' \
  "$(shasum -a 256 "$raw/doxa.md" | cut -d' ' -f1)"

printf 'CHECK_FAILURES=%s\n' "$fail"
[ "$fail" -eq 0 ]
