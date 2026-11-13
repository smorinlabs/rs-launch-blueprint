#!/usr/bin/env bash
# R11 check 5 - every programme claim this decision carries, asserted against
# the file it is carried from rather than from a raw report's summary. Each
# assertion names a path in this repository and a fixed string that must be in
# it. The last block reads this item's own DECISION.md and enforces the
# publication rules on its parameter lines; those assertions SKIP, by name,
# when the decision has not been written yet.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../../../../.." && pwd)"
DECISION="$HERE/../DECISION.md"
GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0

pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$*"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$*"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s\n' "$*"; }

printf 'INFO repository root: %s\n' "$ROOT"
printf 'INFO grep: %s\n' "$("$GREP" --version | head -1)"
if [ -e "$ROOT/.git" ]; then
  printf 'INFO .git is present (%s) - this is a checkout, not an extraction\n' \
    "$( [ -f "$ROOT/.git" ] && echo "a file, so a worktree" || echo "a directory" )"
else
  printf 'INFO .git is absent - this is a git archive extraction; no assertion below needs git\n'
fi

# expect <id> <path relative to root> <fixed string> <what it establishes>
expect() {
  e_id="$1"; e_rel="$2"; e_text="$3"; e_says="$4"
  e_path="$ROOT/$e_rel"
  if [ ! -f "$e_path" ]; then
    fail "$e_id $e_rel is missing"
    return
  fi
  if "$GREP" -qF "$e_text" "$e_path"; then
    pass "$e_id $e_rel: $e_says"
  else
    fail "$e_id $e_rel does NOT contain '$e_text' - $e_says"
  fi
}

R02=research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md
R05=research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md
R10=research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/review/DECISION.md
R44=research/runs/R44/2026-09-17T020715Z-ff8c50edbd69/review/DECISION.md
R50=research/runs/R50/2026-09-17T020715Z-b7ef95f12806/review/DECISION.md
R68=research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md
R69=research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md
R86=research/runs/R86/2026-09-17T033528Z-db9e2a74f9a0/review/DECISION.md
OWNREF=research/runs/R11/2026-09-18T215915Z-7fbece2a29a7/inputs/owner-reference-axum-companion-stack-2026-09-16.md

# --- R02: the topology and the check that governs this item's job shape -----
expect I01 "$R02" 'a **workspace-scoped** build compiles the web member with the feature off' \
  'check B3 - workspace membership, not the root package feature, decides which members are built, so a --workspace command on a CLI-only pull request already compiles axum and tokio'
expect I02 "$R02" 'rs-launch-blueprint-core     -> []' \
  'the four-package workspace projection, from which the root-scoped -p list in the fixture is taken'
# shellcheck disable=SC2016  # backticks here are markdown code spans inside quoted source text, not command substitutions
expect I03 "$R02" 'where R11 must also account for check `B3`' \
  "R02's own re-verify line hands check B3 to this item"
expect I04 "$R02" 'whether the manifest guard moves from pre-push to pre-commit' \
  'the F116 placement is provisional on a P03 measurement, so this item names a tier for it rather than fixing one'

# --- R05: the test commands whose job shape this item owns -----------------
expect I05 "$R05" '(R11 owns the job shape)' \
  'criterion 9 - cargo test and cargo test --features web on both runners, with the job shape left here'

# --- R10: the cache configuration and its consequences --------------------
expect I06 "$R10" 'Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2' \
  'the pinned action reference the fixture reproduces verbatim in every cache-bearing job'
# shellcheck disable=SC2016  # backticks here are markdown code spans inside quoted source text, not command substitutions
expect I07 "$R10" 'A toolchain change — including the MSRV floor job beside the' \
  'criterion A3 - a second toolchain must produce distinct cache entries, which a separate job id gets for free and a matrix leg does not'
# shellcheck disable=SC2016  # backticks here are markdown code spans inside quoted source text, not command substitutions
expect I08 "$R10" 'Gives each CI job id its own `target/` cache' \
  'add-job-id-key defaults to true, so the cache partition follows the job graph this item fixes'

# --- R50: the install-smoke job's shape -----------------------------------
# shellcheck disable=SC2016  # backticks here are markdown code spans inside quoted source text, not command substitutions
expect I09 "$R50" 'one job named `install-smoke` on `ubuntu-latest` only**, gated' \
  'one job, one runner - the shape the fixture hosts'
expect I10 "$R50" 'conditioned on R11' \
  "the web leg is a step of the same job conditioned on this item's web filter, which is what the fixture's second install step is"

# --- R69 revision 10: the skip-gating keys, accepted but not yet published --
expect I11 "$R69" 'path-based skip-gating keys on crates/web/**' \
  "revision 10's owned value moves the keys to crates/web/**, which is what the fixture's web key matches"
# shellcheck disable=SC2016  # backticks here are markdown code spans inside quoted source text, not command substitutions
expect I12 "$R69" 'a `--features web` axis and a `--no-default-features` build' \
  'R69 asks ci.yml for both, shape owned here, which is why the check job carries a --no-default-features step'
expect I13 docs/port/PARAMETERS.md 'path-based skip-gating keys on src/web/**' \
  "the LIVE registry still carries revision 9's src/web/** bytes, which is why the assumes line below reproduces them and the prose says revision 10 moves them"

# --- R49: the packaged-file allow-list that drives the packaging key -------
expect I14 research/topics/49-build-target-declaration/DECISION.md \
  '/src, /README.md, /LICENSE-MIT, /LICENSE-APACHE, /CHANGELOG.md' \
  "the [package] include allow-list - all five are packaging inputs, which is why none of them is skippable"

# --- R42, R20, R17, R44, R68, R86, R18: the slots and their owners ---------
expect I15 research/topics/42-dev-toolchain-provisioning/DECISION.md 'rust-toolchain.toml' \
  'the toolchain file the stable compile job depends on existing, so this item installs nothing for the stable leg'
# shellcheck disable=SC2016  # backticks here are markdown code spans inside quoted source text, not command substitutions
expect I16 research/topics/20-third-party-action-pinning-policy/DECISION.md \
  'whose owner is neither `actions` nor' \
  'the pin rule: actions/checkout@v7 may stay on a tag, Swatinem/rust-cache must carry a full SHA and a version comment - both as the fixture writes them'
expect I17 research/topics/17-secret-scanning-ci-workflow/DECISION.md \
  'Which runner OS the single scan job lands on (R11 owns this)' \
  'R17 hands its runner choice here, so this decision answers it'
expect I18 "$R44" 'owns whether the devcontainer check is its own job' \
  'R44 hands its job-versus-step question here too'
expect I19 "$R68" 'follower mode' \
  'the release flow is a separate workflow file, so no release job enters ci.yml'
# shellcheck disable=SC2016  # backticks here are markdown code spans inside quoted source text, not command substitutions
expect I20 "$R86" '`credential-preflight` job whose output a **positive** `needs` predicate' \
  "R86's preflight publishes a literal consumed by a positive predicate - the clause this item's detector mirrors"
expect I21 research/topics/18-ai-assisted-review-workflows/DECISION.md \
  "A skipped job's outputs are **empty**" \
  "R18 revision 6 found the fail-open negated gate in its own draft; this item reproduces the platform fact and adds that actionlint will not catch it"
expect I22 docs/planning/p02/execution-ledger.md \
  'the template adds a small always-run preflight job that prints the reason for skipping and gates the real job behind it' \
  "the owner's 2026-09-11 option-B ruling - the precedent that an always-run job gating dependents is this programme's accepted device"

# --- the ledger rows this item settles and the ones it must not -----------
expect I23 docs/port/COMMONALITY.md \
  '| F038 | Consolidated lint workflow' \
  'F038 is this item (DIVERGENT, py-only): CI-owned workflow-file structure plus path-filtered skip-gating'
expect I24 docs/port/COMMONALITY.md \
  '| F040 | A changes-detector job skips heavy jobs on docs-only PRs | ci-workflows | py-only | DIVERGENT | R11 |' \
  'F040 is this item'
expect I25 docs/port/COMMONALITY.md \
  '| F041 | Single aggregate required-status-check job folding in all other job results | ci-workflows | py-only | DIVERGENT | R12 |' \
  "F041 is R12's, not this item's - this file holds no aggregate job"
expect I26 docs/port/COMMONALITY.md \
  '| F049 | Always-on SCA audit as commented, uncomment-to-enable scaffolding inside the main CI workflow | ci-workflows | ts-only | DIVERGENT | R13 |' \
  "F049 is R13's; this item gives it a placement rule, not a decision"
# shellcheck disable=SC2016  # backticks here are markdown code spans inside quoted source text, not command substitutions
expect I27 docs/port/COMMONALITY.md \
  'whether the floor is a matrix leg or a separate job falls under `ci-job-structure` (R11)' \
  "F033's note assigns the floor mechanism here"

# --- BASELINE-REVIEW: what is settled and what stays the owner's ----------
expect I28 docs/port/BASELINE-REVIEW.md \
  'OS cross-product stays an owner question; R11 not widened' \
  'the reconciliation row: this item places the floor job on one runner as a default and does not widen to the OS cross-product'
expect I29 docs/port/BASELINE-REVIEW.md \
  'leaving the mechanism (a matrix leg versus a separate verification job) to R11' \
  "the restatement of F033 to 'floor plus current stable', with the mechanism left here"

# --- the owner records -----------------------------------------------------
expect I30 docs/port/OWNER-REVIEW.md \
  '2026-09-12 — no licence check for anything the template uses' \
  'the ruling under which fitness gate 1 is recorded inapplicable'
expect I31 docs/planning/p02/owner-decisions.md \
  '## 11. Owner-supplied reference architecture (2026-09-16) -- STANDING INPUT' \
  'the reference architecture is a standing research input, not a binding standard'

# --- the owner reference rows this item touches, row by row ---------------
# shellcheck disable=SC2016  # backticks here are markdown code spans inside quoted source text, not command substitutions
expect I32 "$OWNREF" \
  'CI runs: `cargo fmt --check` → `cargo clippy -D warnings` → `cargo sqlx prepare --check` → `cargo test` → `cargo deny check`' \
  'C12 row 1 of 6 - AGREE on the order, DIFFER on the packaging: fmt is lifted into a no-compile job; sqlx is inapplicable, this template has no database'
# shellcheck disable=SC2016  # backticks here are markdown code spans inside quoted source text, not command substitutions
expect I33 "$OWNREF" 'pin the toolchain with `rust-toolchain.toml`; enable clippy `-D warnings`' \
  'C14 row 2 of 6 - AGREE; R42 already commits the file and -D warnings is on both clippy steps'
# shellcheck disable=SC2016  # backticks here are markdown code spans inside quoted source text, not command substitutions
expect I34 "$OWNREF" 'Run generation in CI and `git diff --exit-code` so drift fails the build' \
  'C3 row 3 of 6 - AGREE as a slot: openapi-snap is gated on the web key; the command inside is R71/R84'
# shellcheck disable=SC2016  # backticks here are markdown code spans inside quoted source text, not command substitutions
expect I35 "$OWNREF" 'Build with cargo-chef (planner → `cargo chef cook` → build), run as `nonroot`' \
  'C15 row 4 of 6 - DIFFER as a hand-off: no container or deploy job enters ci.yml; R51 owns the image and R68 the release workflow'
# shellcheck disable=SC2016  # backticks here are markdown code spans inside quoted source text, not command substitutions
expect I36 "$OWNREF" 'Gate CI on `cargo deny`, sqlx offline check, OpenAPI/TS-client drift, and clippy `-D warnings`' \
  'Recommendations 7, row 5 of 6 - AGREE on three of four, each a named slot; the sqlx clause is inapplicable'
# shellcheck disable=SC2016  # backticks here are markdown code spans inside quoted source text, not command substitutions
expect I37 "$OWNREF" 'rust-version = "1.85"          # pin via rust-toolchain.toml' \
  "the reference Cargo.toml, row 6 of 6 - DIFFER by the owner's own precedence rule: rust-edition is 2024 and the floor follows msrv-policy"

# --- the fixture reproduces what it claims to reproduce -------------------
expect_fixture() {
  f_id="$1"; f_text="$2"; f_says="$3"
  if "$GREP" -qF "$f_text" "$HERE/ci.candidate.yml"; then
    pass "$f_id ci.candidate.yml: $f_says"
  else
    fail "$f_id ci.candidate.yml does NOT contain '$f_text' - $f_says"
  fi
}
expect_fixture I40 'Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2' \
  "R10's pinned reference appears verbatim"
expect_fixture I41 'cargo test --locked -p rs-launch-blueprint -p rs-launch-blueprint-core -p rs-launch-blueprint-cli' \
  "R02 check B3 is honoured: the feature-off test is root-scoped, so the property is proven rather than assumed"
expect_fixture I42 'cargo check --locked --no-default-features -p rs-launch-blueprint' \
  "R69's --no-default-features ask is an ordered step of the compile job"
expect_fixture I43 'merge_group:' \
  'the third trigger, without which a merge queue deadlocks at Expected'
expect_fixture I44 'permissions: {}' \
  "workflow-level deny-all with a per-job re-grant; the scopes are R08's"
if "$GREP" -qE '^\s+paths(-ignore)?:' "$HERE/ci.candidate.yml"; then
  fail "I45 the fixture carries an on.<event>.paths filter, which GitHub's own instruction forbids on a required workflow"
else
  pass "I45 ci.candidate.yml carries no on.<event>.paths or paths-ignore filter of any kind"
fi
NEG="$("$GREP" -c "outputs\..* != " "$HERE/ci.candidate.yml" || true)"
if [ "$NEG" -eq 0 ]; then
  pass "I46 the fixture contains zero negated needs-output predicates; every gate is a positive == 'true' test"
else
  fail "I46 the fixture contains $NEG negated needs-output predicate(s), the fail-open form NC2 shows actionlint will not catch"
fi

# --- this item's own DECISION.md, when it exists --------------------------
if [ ! -f "$DECISION" ]; then
  skip "I50 DECISION.md is not written yet - the H2 shape assertion is unrun"
  skip "I51 DECISION.md is not written yet - the re-verify count assertion is unrun"
  skip "I52 DECISION.md is not written yet - the H5 assertion is unrun"
  skip "I53 DECISION.md is not written yet - the licence-gate wording assertion is unrun"
  skip "I54 DECISION.md is not written yet - the owns-line format assertion is unrun"
  skip "I55 DECISION.md is not written yet - the five assumes lines are unchecked against the registry"
else
  H2S="$("$GREP" -E '^## ' "$DECISION" | tr '\n' '|')"
  if [ "$H2S" = "## Decision|## Parameters|## Empirical check|## Engines|" ]; then
    pass "I50 DECISION.md carries exactly the four H2 sections in order and no ## Supersedes, which a first revision must not have"
  else
    fail "I50 DECISION.md H2 sections are '$H2S', not the four in order"
  fi

  RV="$("$GREP" -c '^re-verify: ' "$DECISION" || true)"
  if [ "$RV" -eq 1 ]; then
    pass "I51 DECISION.md carries exactly one line beginning 're-verify: '"
  else
    fail "I51 DECISION.md carries $RV lines beginning 're-verify: ', expected exactly 1"
  fi

  H5="$("$GREP" -c '^##### ' "$DECISION" || true)"
  if [ "$H5" -eq 0 ]; then
    pass "I52 DECISION.md carries no ##### heading, so the bundle validator's members-window rule cannot be violated"
  else
    fail "I52 DECISION.md carries $H5 ##### heading(s) outside a ### Members window"
  fi

  expect I53 "research/runs/R11/2026-09-18T215915Z-7fbece2a29a7/review/DECISION.md" \
    'inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool' \
    'fitness gate 1 is recorded with the prescribed wording rather than deleted'

  OWNS="$("$GREP" -c '^- owns ci-job-structure = ' "$DECISION" || true)"
  OWNSBAD=0
  if [ "$OWNS" -ne 1 ]; then OWNSBAD=1; fi
  if "$GREP" '^- owns ci-job-structure = ' "$DECISION" | "$GREP" -q '[`|]'; then OWNSBAD=1; fi
  if [ "$OWNSBAD" -eq 0 ]; then
    pass "I54 exactly one '- owns ci-job-structure = ' line, and its bytes contain no backtick and no pipe, so the registry table cell and the byte-for-byte validator both accept it"
  else
    fail "I54 the owns line is absent, duplicated, or contains a backtick or a pipe ($OWNS line(s) found)"
  fi

  for param in msrv-policy rust-edition target-os-matrix license web-extra-surface; do
    REGV="$(awk -F'|' -v p=" $param " '$2 == p {print substr($0, index($0, $2) + length($2) + 1)}' \
      "$ROOT/docs/port/PARAMETERS.md" | awk -F'|' '{print $3}' | sed 's/^ //; s/ $//')"
    DECV="$("$GREP" "^- assumes $param = " "$DECISION" | sed "s/^- assumes $param = //")"
    if [ -z "$REGV" ]; then
      fail "I55-$param the registry row could not be parsed from docs/port/PARAMETERS.md"
    elif [ "$DECV" = "$REGV" ]; then
      pass "I55-$param the assumes line is byte-identical to the live registry row (${#REGV} bytes)"
    else
      fail "I55-$param the assumes line differs from the registry row: decision ${#DECV} bytes, registry ${#REGV} bytes"
    fi
  done
fi

printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
[ "$FAIL" -eq 0 ]
