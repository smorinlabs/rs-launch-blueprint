#!/usr/bin/env bash
# R69 revision 10 — assertions on the owned value `web-extra-surface`.
#
# What this script establishes, and what it does not. It asserts the exact bytes
# of the `- owns web-extra-surface` line in R69's revision-10 decision, that
# each of the six clauses owner ruling W1-R02 moved is present in its new form,
# that none of the superseded forms survives anywhere in the value, that each
# clause of R02's own `CONFLICT:` line is honoured, and that the five
# `- assumes` lines are byte-identical to the live registry. It asserts nothing
# about whether the recommendation is correct; that is the decision's own
# empirical section, whose scripts and logs this revision does not touch.
#
# Run from the repository root:  bash <this path>
# Every path below is repository-relative, and no clock, hostname, absolute
# path or scratch directory name is printed, so the output is byte-identical
# in place and from a clean `git archive` extraction.

set -euo pipefail

GREP=/usr/bin/grep
# A literal backtick, built rather than quoted: several needles below are Markdown
# code spans, and a raw backtick in a string makes shellcheck read it as a
# command substitution (SC2016).
BT=$(printf '\140')
PASS=0
FAIL=0
SKIP=0

DECISION=research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md
TOPIC=research/topics/69-web-framework-stack/DECISION.md
REGISTRY=docs/port/PARAMETERS.md
R02=research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md

# The supersession heading is assembled at run time. `check_history` splits a
# decision at the FIRST occurrence of this substring, so a script that carried
# the literal would put a copy of it into its own committed log and into any
# search that reads this file.
HEADING='## Supers'
HEADING="${HEADING}edes"

pass() { PASS=$((PASS + 1)); printf 'PASS %s: %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s: %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s: %s\n' "$1" "$2"; }

assert_eq() { # label expected actual description
  if [ "$2" = "$3" ]; then pass "$1" "$4 == $2"; else fail "$1" "$4: expected $2, got $3"; fi
}

printf '== R69 revision 10 — owned-value check ==\n'
printf 'grep: %s\n' "$("$GREP" --version | head -1)"
printf 'shasum: %s\n' "$(shasum --version)"
printf 'decision: %s\n' "$DECISION"
printf '\n-- 1. the file, and the one owned line --\n'

for path in "$DECISION" "$TOPIC" "$REGISTRY"; do
  if [ ! -f "$path" ]; then
    printf 'FATAL: required file absent: %s\n' "$path"
    exit 2
  fi
done

# The current entry is everything above the first supersession heading line.
HEAD_FILE=$(mktemp)
OWNS_FILE=$(mktemp)
MUTANT=$(mktemp)
trap 'rm -f "$HEAD_FILE" "$OWNS_FILE" "$MUTANT"' EXIT

heading_line=$("$GREP" -n -m1 -x -F "$HEADING" "$DECISION" | cut -d: -f1)
head -n $((heading_line - 1)) "$DECISION" >"$HEAD_FILE"
# V1a pins revision 10's own layout: any reflow of this decision moves the
# boundary and must be looked at rather than absorbed silently.
assert_eq V1a 2685 "$heading_line" 'supersession heading line number'

owns_count=$("$GREP" -c -F -- '- owns web-extra-surface = ' "$HEAD_FILE" || true)
assert_eq V1b 1 "$owns_count" 'owned lines in the current entry'
"$GREP" -m1 -F -- '- owns web-extra-surface = ' "$HEAD_FILE" >"$OWNS_FILE"

owns_sha=$(shasum -a 256 <"$OWNS_FILE" | cut -d' ' -f1)
assert_eq V2 60558d1ab01ae3f7efd60cda1cd3cbc24f6a6114880deb3286940b6bb06f7346 \
  "$owns_sha" 'sha256 of the owned line as grep emits it'

printf '\n-- 2. the six clauses owner ruling W1-R02 moved, in their new form --\n'
present() { # label needle description
  if "$GREP" -q -F -- "$2" "$OWNS_FILE"; then pass "$1" "$3"; else fail "$1" "$3 — not found"; fi
}
present V3a 'declared on the root package rs-launch-blueprint;' \
  'clause 1 — the feature is declared on the root package rs-launch-blueprint'
present V3b 'web = ["dep:rs-launch-blueprint-web"],' \
  'clause 2a — the feature enables the optional member, not two crates'
present V3c 'axum 0.8.9 declared non-optionally in crates/web/Cargo.toml and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing)' \
  'clause 2b — axum non-optional in crates/web, feature list byte-identical'
present V3d 'tokio 1.53.1 declared non-optionally in crates/web/Cargo.toml with features rt-multi-thread, net, signal, macros, time, sync' \
  'clause 2c — tokio non-optional in crates/web, feature list byte-identical'
present V3e '(1) the library module crates/web/src/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until' \
  'clause 3 — the gated tree reads crates/web/src/'
present V3f '(3) the web integration tests in crates/web/tests/, with no file-level #![cfg(feature = "web")] because the whole member is optional' \
  'clause 4 — the tests live in crates/web/tests/ with no file-level cfg'
present V3g "tower 0.5.3 is crates/web's dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature" \
  'clause 5 — tower is crates/web dev-dependency, still not gated'
present V3h 'as modules inside that same gated crates/web/src/ tree' \
  'clause 6a — later layers nest inside crates/web/src/'
present V3i 'path-based skip-gating keys on crates/web/**, the serve binary'\''s source file and the web test files' \
  'clause 6b — skip-gating keys on crates/web/**'

printf '\n-- 3. clauses that must NOT have moved --\n'
present V3j 'the feature gates exactly four things and nothing else' 'the four-gated-things count'
present V3k '(2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"]' \
  'the gated serve binary target shape'
present V3l 'which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none' \
  "R60's parser clause, deliberately verbatim"
present V3m '143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main' \
  "R67's exit integers as ExitCode"
present V3n 'otel = ["web", ...] for R78 and metrics = ["web", ...] for R79' 'the otel/metrics nesting'
present V3o 'the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency' \
  'bacon as a non-dependency'
present V3p 'consumers select the surface with --features web or --all-features and detect it by that feature name' \
  'the consumer-selection clause'

printf '\n-- 4. the superseded forms are gone from the value --\n'
absent() { # label needle description
  if "$GREP" -q -F -- "$2" "$OWNS_FILE"; then fail "$1" "$3 — still present"; else pass "$1" "$3"; fi
}
absent V4a 'src/web/' 'the src/web/ tree'
absent V4b 'dep:axum' 'the dep:axum feature entry'
absent V4c 'dep:tokio' 'the dep:tokio feature entry'
absent V4d 'whichever crate hosts the binary targets' 'the R02 deferral'
absent V4e 'gated file-level with' 'the file-level test cfg'
absent V4f 'is a dev-dependency only' 'the unqualified tower dev-dependency wording'
absent V4g 'axum 0.8.9 optional' 'the optional axum declaration'
absent V4h 'tokio 1.53.1 optional' 'the optional tokio declaration'

printf '\n-- 5. control: the V4 matcher must be able to fail --\n'
# Reinject one superseded form into a scratch copy of the owned line and require
# the same matcher to find it. Without this the eight zeros above are vacuous.
sed 's|crates/web/src/ containing|src/web/ containing|' "$OWNS_FILE" >"$MUTANT"
if cmp -s "$OWNS_FILE" "$MUTANT"; then
  fail V5a 'control: the mutation changed nothing, so the control proves nothing'
else
  pass V5a 'control: the mutated copy differs from the asserted line'
fi
if "$GREP" -q -F -- 'src/web/' "$MUTANT"; then
  pass V5b 'control: the V4a matcher finds src/web/ in the mutated copy, so V4a can fail'
else
  fail V5b 'control: the V4a matcher did not fire on a line that contains src/web/'
fi

printf '\n-- 6. every clause of R02 CONFLICT line is honoured --\n'
if [ -f "$R02" ]; then
  conflict=$("$GREP" -c -F -- 'CONFLICT: R69 web-extra-surface' "$R02" || true)
  assert_eq V6a 1 "$conflict" "CONFLICT: lines against web-extra-surface in R02's decision"
  for pair in \
    'web = ["dep:rs-launch-blueprint-web"]|V6b' \
    "declared on the root package ${BT}rs-launch-blueprint${BT}|V6c" \
    'declared non-optionally in|V6d' \
    'crates/web/src/|V6e' \
    'crates/web/tests/|V6f' \
    'crates/web/**|V6g' \
    "as ${BT}crates/web${BT}'s dev-dependency|V6h"
  do
    needle=${pair%|*}
    label=${pair##*|}
    if "$GREP" -F -- 'CONFLICT: R69 web-extra-surface' "$R02" | "$GREP" -q -F -- "$needle"; then
      pass "$label" "R02's CONFLICT line specifies: $needle"
    else
      fail "$label" "R02's CONFLICT line does not contain: $needle"
    fi
  done
else
  skip V6a "R02's run decision is absent from this tree: $R02"
  for label in V6b V6c V6d V6e V6f V6g V6h; do
    skip "$label" "R02's run decision is absent from this tree: $R02"
  done
fi

printf '\n-- 7. the five assumed lines diff empty against the live registry --\n'
MINE=$(mktemp)
THEIRS=$(mktemp)
trap 'rm -f "$HEAD_FILE" "$OWNS_FILE" "$MUTANT" "$MINE" "$THEIRS"' EXIT
"$GREP" -E '^- assumes [a-z0-9-]+ = ' "$HEAD_FILE" >"$MINE"
assumes_count=$(wc -l <"$MINE" | tr -d ' ')
assert_eq V7a 5 "$assumes_count" 'assumed lines in the current entry'
: >"$THEIRS"
while IFS= read -r line; do
  name=${line#- assumes }
  name=${name%% = *}
  row=$("$GREP" -m1 -E "^\| ${name} \| " "$REGISTRY" || true)
  if [ -z "$row" ]; then
    printf -- '- assumes %s = <NO REGISTRY ROW>\n' "$name" >>"$THEIRS"
    continue
  fi
  value=$(printf '%s\n' "$row" | awk -F' \\| ' '{print $4}')
  printf -- '- assumes %s = %s\n' "$name" "$value" >>"$THEIRS"
done <"$MINE"
if diff -u "$THEIRS" "$MINE" >/dev/null; then
  pass V7b 'diff of the five assumed lines against the registry rows is empty'
else
  fail V7b 'the assumed lines differ from the registry rows'
  diff -u "$THEIRS" "$MINE" || true
fi

printf '\n-- 8. the superseded forms survive above the heading only as marked quotations --\n'
# Every line of the current entry that carries a superseded form must carry a
# quotation marker on itself or within the two preceding lines. The expected
# counts are pinned, so a silent reintroduction changes a count and fails.
marked_forms() { # label form expected_count
  local label=$1 form=$2 expected=$3
  local hits count unmarked
  hits=$("$GREP" -n -F -- "$form" "$HEAD_FILE" | cut -d: -f1 || true)
  count=$(printf '%s' "$hits" | "$GREP" -c . || true)
  assert_eq "${label}-count" "$expected" "$count" "occurrences of '$form' in the current entry"
  unmarked=0
  for n in $hits; do
    local from=$((n - 2))
    [ "$from" -lt 1 ] && from=1
    if ! sed -n "${from},${n}p" "$HEAD_FILE" \
      | "$GREP" -q -E 'Revision 9|revision 9|superseded|Superseded|rather than|instead of|Corrected:|Path substitution|published file for'; then
      unmarked=$((unmarked + 1))
      printf '  UNMARKED line %s\n' "$n"
    fi
  done
  assert_eq "${label}-marked" 0 "$unmarked" "unmarked occurrences of '$form'"
}
marked_forms V8a 'src/web/' 10
marked_forms V8b 'web = ["dep:axum", "dep:tokio"]' 2
marked_forms V8c 'pub mod web' 4
marked_forms V8d '(optional, default features)' 1

printf '\n-- 9. the asserting sites now carry the new forms --\n'
site() { # label needle description
  if "$GREP" -q -F -- "$2" "$HEAD_FILE"; then pass "$1" "$3"; else fail "$1" "$3 — not found"; fi
}
site V9a "| ${BT}crates/web/Cargo.toml${BT} (new member) |" 'the file map has a crates/web manifest row'
site V9b "| ${BT}crates/web/src/lib.rs${BT} (new) |" 'the file map places the web library at crates/web/src/lib.rs'
site V9c "| ${BT}crates/web/src/routes/projects.rs${BT} (new) |" 'the file map places the route module under crates/web/src/'
site V9d "| ${BT}crates/web/tests/web_api.rs${BT} (new) |" 'the file map places the web tests under crates/web/tests/'
site V9e "${BT}[features] web = [\"dep:rs-launch-blueprint-web\"]${BT}" 'the root manifest row names the optional member'
site V9f "(non-optional in ${BT}crates/web${BT}, default features)" 'the member table marks axum non-optional inside crates/web'

printf '\n== SUMMARY ==\n'
printf 'CHECKS RUN: %s PASS: %s FAIL: %s SKIP: %s\n' "$((PASS + FAIL + SKIP))" "$PASS" "$FAIL" "$SKIP"
if [ "$FAIL" -ne 0 ]; then exit 1; fi
exit 0
