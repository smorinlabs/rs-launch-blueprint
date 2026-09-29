#!/usr/bin/env bash
# R35 revision 3 — the DECISION's own integrity (first written for revision 1).
#   R*: every file:line citation in review/DECISION.md resolves to text that
#       says what the DECISION says it says (one distinctive phrase per cite);
#   P*: the prerequisite R11 decision is the exact bytes prerequisites.json pins;
#   X*: raw-report hashes, answer-shape results and the Muse placeholder count;
#       the DECISION's H2 order, single Principles H3, single re-verify line,
#       Parameters lines byte-identical to the registry, the fenced recipe equal
#       to the executed one, every cited check ID present as a PASS line, and
#       (X14) no unix-signal claim in the Muse report; (X15) the quoted rerun
#       figures present in rerun-2026-09-27/.
# Usage: bash r35-inputs.sh   (reads only this run, the R11 prerequisite, and the
#        repository's scripts/check-answer-shape.sh)
# shellcheck disable=SC2016  # file-wide: every single-quoted phrase is literal Markdown (backticks) or a bash -c body reading "$1"; nothing is meant to expand
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
run="$(cd "$here/../.." && pwd)"
root="$(cd "$run/../../../.." && pwd)"
dec="$run/review/DECISION.md"
r11="$root/research/topics/11-ci-workflow-job-structure/DECISION.md"
snap="$here/snapshots"

pass=0; fail=0
ok()  { pass=$((pass + 1)); echo "PASS $1 — $2"; }
bad() { fail=$((fail + 1)); echo "FAIL $1 — $2"; }
info() { echo "INFO $*"; }
check() { local id="$1" desc="$2"; shift 2; if "$@"; then ok "$id" "$desc"; else bad "$id" "$desc"; fi; }
# cite <id> <file> <first> <last> <phrase>: the phrase occurs within those lines.
cite() {
  local id="$1" file="$2" first="$3" last="$4" phrase="$5"
  if sed -n "${first},${last}p" "$file" | /usr/bin/grep -q -F -- "$phrase"; then
    ok "$id" "${file#"$root"/}:$first-$last contains \"$phrase\""
  else
    bad "$id" "${file#"$root"/}:$first-$last lacks \"$phrase\""
  fi
}
M="$run/raw/muse.md"; O="$run/raw/opus.md"; PR="$run/inputs/prompt.md"; PA="$run/inputs/PARAMETERS.md"
info "date_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ) root=$root"

# --- Muse raw citations ------------------------------------------------------
cite R-M3   "$M" 3 3 'research/topics/33-property-and-snapshot-testing/raw/opus-2026-09-17T012441Z-a1424f847040.md:3'
cite R-M5   "$M" 5 5 'S_STABLE'
cite R-M24  "$M" 24 24 'S_ADOPTERS'
cite R-M27  "$M" 27 27 'S_ADOPTERS_DETAIL'
cite R-M33  "$M" 33 33 'capability + policy'
cite R-M41  "$M" 41 41 '1,696,594'
cite R-M45  "$M" 45 45 'No check in this report was executed'
cite R-M47  "$M" 47 47 '**BASELINE-REVIEW findings:** none'
cite R-M51a "$M" 51 51 "Doc-tests are included via the tool's \`--doc\` flag (S_DOC_NOTE)"
cite R-M51b "$M" 51 51 'terminal summary + `lcov.info` artifact in CI'
cite R-M72  "$M" 72 72 'S_G_STATE'
cite R-M84  "$M" 84 84 'the ts two-file convention is preserved as the documented `--ignore-filename-regex` escape hatch'
cite R-M88  "$M" 88 88 '`cargo llvm-cov --workspace --lcov --output-path lcov.info --fail-under-lines 80`'
cite R-M37a "$M" 37 37 'compiler-inserted counters, source-accurate regions/branches'
cite R-M37b "$M" 37 37 'less accurate on optimized/inlined code'
cite R-M96  "$M" 96 96 'source-accurate regions/branches'
cite R-M104a "$M" 104 104 'recipe mirroring the CI flags'
cite R-M104b "$M" 104 104 '`.gitignore` gains `lcov.info`'
cite R-M125 "$M" 125 125 '#### coverage-threshold-and-gate'
cite R-M133a "$M" 133 133 'the flag and the failure are the same process exit code'
cite R-M133b "$M" 133 133 "the only *enforced* numeric threshold in either source repo is py's 80% (patch)"
cite R-M141 "$M" 141 141 'S_CODECOV_TOKENLESS_SHORT'
cite R-M154 "$M" 154 154 "the tool's own CI proves both runners"
cite R-M158 "$M" 158 158 '`--fail-under-lines 80` in the required `coverage` CI job'
cite R-M158b "$M" 158 158 'Required-check status (blocking the PR) is part of this recommendation'
cite R-M174 "$M" 174 174 'any second threshold declaration that could drift from the flag'
cite R-M178 "$M" 178 178 'grep -r fail-under-lines'
cite R-M225 "$M" 225 225 'research/topics/33-property-and-snapshot-testing/raw/opus-2026-09-17T012441Z-a1424f847040.md:3'
cite R-M199 "$M" 199 199 'assumes ci-job-structure = one .github/workflows/ci.yml'

# --- Opus raw citations ------------------------------------------------------
cite R-O5   "$O" 5 5 '**Evidence drift:**'
cite R-O7   "$O" 7 7 'Rust 1.98.1 (48a229cea 2026-09-01)'
cite R-O9   "$O" 9 9 'Nothing in this leg was executed against coverage tooling.'
cite R-O23  "$O" 23 23 '`actions/upload-code-coverage` (GitHub)'
cite R-O26  "$O" 26 26 'The Rust annual survey does not ask about coverage tooling'
cite R-O35  "$O" 35 35 'of 28 projects'
cite R-O51  "$O" 51 51 '**6 use `cargo-llvm-cov`**'
cite R-O53  "$O" 52 52 '**None of the 8 uses an in-repo `--fail-under` gate.**'
cite R-O59  "$O" 59 59 '**Shared requirement.**'
cite R-O63  "$O" 63 63 'test code is not counted (F135)'
cite R-O86  "$O" 86 86 'Recommendation: **A as the gate**'
cite R-O92  "$O" 92 92 'Linux x86_64 default: ptrace breakpoints'
cite R-O94  "$O" 94 94 '`--fail-under <PERCENTAGE>` (line only'
cite R-O95  "$O" 95 95 '| Branch metric on stable |'
cite R-O96  "$O" 96 96 '| Doc tests on stable |'
cite R-O99a "$O" 99 99 '| Accuracy notes | precise line/region data (README:11)'
cite R-O99b "$O" 99 99 'ptrace: "may still contain minor inaccuracies", signals interfere'
cite R-O106 "$O" 106 106 'One file holds the values (AC4)'
cite R-O110 "$O" 110 110 '**This is expected behavior, not verified in this leg**'
cite R-O112 "$O" 112 112 '`--fail-under-lines 95`, `--fail-under-functions 95`, `--fail-under-regions 90`'
cite R-O115 "$O" 112 116 '`branches 90` → **regions 90**'
cite R-O119 "$O" 119 119 'this item only guarantees the job fails'
cite R-O121 "$O" 121 121 '**F138 — report formats.**'
cite R-O123 "$O" 123 123 'On stable, doc tests are **not** covered'
cite R-O135 "$O" 135 140 '    cargo llvm-cov report --html'
cite R-O140 "$O" 135 140 '    cargo llvm-cov report --show-missing-lines {{coverage_fail_under}}'
cite R-O143 "$O" 143 143 '`--all-features` turns on the one feature the template declares'
cite R-O167 "$O" 167 167 'failed to find llvm-tools-preview, please install llvm-tools-preview, or set LLVM_COV and LLVM_PROFDATA environment variables'
cite R-O169 "$O" 169 169 'deliberately does **not** add `llvm-tools-preview`'
cite R-O213 "$O" 213 213 'Gate 2 is **undeclared**'
cite R-O219 "$O" 219 219 '**macOS is tested, but on nightly only**'
cite R-O225 "$O" 225 229 '`at-risk`'
cite R-O234 "$O" 234 234 '`actions/upload-code-coverage`'
cite R-O276 "$O" 276 276 '`.gitignore`: nothing new'
cite R-O305 "$O" 305 305 '#### llvm-tools-preview'
cite R-O388 "$O" 388 388 '**Shared adopters:**'
cite R-O397 "$O" 397 397 "assumes ci-job-structure = R11's registered value"
cite R-O398 "$O" 398 398 'assumes package-manager-invocation ='
cite R-O399 "$O" 399 399 'assumes web-extra-surface ='

# --- prompt and registry snapshot -------------------------------------------
cite R-P4   "$PR" 4 4 'the coverage-tool dev-dependency'
cite R-P8   "$PR" 8 8 'Ledger rows: F134, F135, F136, F137, F138'
cite R-P9a  "$PR" 9 9 '`.codecov.yml:14` (`target: auto`, project)'
cite R-P9b  "$PR" 9 9 '`.codecov.yml:18` (`target: 80%`, patch)'
cite R-P9c  "$PR" 9 9 '`vitest.config.ts:20` (in-repo `thresholds`: 95/95/90/95'
cite R-P9d  "$PR" 9 9 '`.github/workflows/ci.yml:95` (`run: just test`, no `--coverage`'
cite R-P9e  "$PR" 9 9 '`vitest.config.ts:19` (`exclude` two thin I/O-adapter files)'
cite R-P11  "$PR" 11 11 'thresholds lines 95 / functions 95 / branches 90 / statements 95 enforced in CI'
cite R-P31  "$PR" 31 31 'instrumentation mechanisms (LLVM source-based coverage vs. ptrace-based), accuracy, and CI-runtime-cost'
check R-P20 "inputs/prompt.md:20 is the empty owns line" test "$(sed -n 20p "$PR")" = '- owns:'
check R-P21 "inputs/prompt.md:21 consumes only R11's ci-job-structure" test "$(sed -n 21p "$PR")" = '- consumes: R11: ci-job-structure'
cite R-PA12 "$PA" 12 12 '| ci-job-structure | researched | R11 |'
cite R-PA12b "$PA" 12 12 "needing its own toolchain, its own runner or a target/ it must not share"
cite R-PA14 "$PA" 14 14 'rustup component list --installed for a tool rustup installs, never command -v for a rustup component'
cite R-PA17b "$PA" 17 17 'otel = ["web", ...] for R78 and metrics = ["web", ...] for R79'
cite R-PA17 "$PA" 17 17 'consumers select the surface with --features web or --all-features'

# --- the R11 prerequisite -----------------------------------------------------
want="$(jq -r .R11.decision "$run/inputs/prerequisites.json")"
have="$(shasum -a 256 "$r11" | cut -d' ' -f1)"
check P1 "R11 DECISION.md sha256 equals prerequisites.json ($want)" test "$have" = "$want"
cite R-11-82  "$r11" 82 82 'owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool'
cite R-11-86  "$r11" 86 86 '**proposal validated in the implementation phase** (owner ruling, 2026-09-10)'
cite R-11-278 "$r11" 278 278 'counted against a ceiling of roughly six cache-bearing job ids per runner'
cite R-11-283 "$r11" 283 283 'a failed `plan` must fail a required check'
cite R-11-290 "$r11" 290 290 'one more cache-bearing id on `ubuntu-latest`'
cite R-11-291 "$r11" 291 291 '| R35 coverage-tooling | the `coverage` slot |'
cite R-11-407 "$r11" 407 407 "against this design's 3 and 4"

# --- snapshots cited by line ----------------------------------------------------
cite R-S-ci57 "$snap/sources/cargo-llvm-cov-ci.yml" 57 57 "- rust: '1.87'"
cite R-S-ci62 "$snap/sources/cargo-llvm-cov-ci.yml" 61 62 'os: macos-latest'
cite R-S-ci73 "$snap/sources/cargo-llvm-cov-ci.yml" 73 73 "runs-on: \${{ matrix.os || 'ubuntu-24.04' }}"
cite R-S-ci90 "$snap/sources/cargo-llvm-cov-ci.yml" 90 90 'name: Test cargo llvm-cov nextest'
cite R-S-ci94 "$snap/sources/cargo-llvm-cov-ci.yml" 90 99 'cargo llvm-cov nextest --text --fail-under-lines 50'
T="$snap/cargo-tarpaulin-0.37.4-README.md"
cite R-T14  "$T" 14 14 'may still contain  minor inaccuracies'
cite R-T19  "$T" 19 21 'default tracing backend is still Ptrace'
cite R-T21  "$T" 19 21 'For Mac and Windows, this is the default collection'
cite R-T73  "$T" 73 73 'This is now the default behaviour'
cite R-T113 "$T" 113 119 '### Note on tests using signals'
cite R-T115 "$T" 115 116 'may not work with'
cite R-T118 "$T" 113 119 '`--forward` option results in forwarding the signals'
cite R-T123 "$T" 123 123 'Despite generally being far more accurate'
cite R-S-rd14  "$snap/cargo-llvm-cov-0.9.1-README.md" 14 14 'requires nightly'
cite R-S-rd618 "$snap/cargo-llvm-cov-0.9.1-README.md" 618 618 '`aarch64-pc-windows-msvc`'
cite R-S-rd917 "$snap/cargo-llvm-cov-0.9.1-README.md" 917 917 'Support for doc tests is unstable'
cite R-S-cc49  "$snap/sources/codecov-action-README.md" 49 49 'Tokenless uploading is unsupported. However, PRs made from forks to the upstream public repos will support tokenless'
cite R-S-rb125 "$snap/sources/rustc-book-instrument-coverage.md" 125 125 'This component is the recommended path'

# --- raw reports: hashes, shape, placeholders ------------------------------------
for leg in muse opus; do
  h="$(shasum -a 256 "$run/raw/$leg.md" | cut -d' ' -f1)"
  check "X0-$leg" "the Engines table records raw/$leg.md's sha256 ($h)" /usr/bin/grep -q "$h" "$dec"
done
shape() { bash "$root/scripts/check-answer-shape.sh" "$1" bundle 2>&1; }
check X1 "check-answer-shape.sh raw/muse.md bundle prints OK" bash -c '[ "$1" = "OK: validation passed" ]' _ "$(shape "$M")"
check X2 "check-answer-shape.sh raw/opus.md bundle prints OK" bash -c '[ "$1" = "OK: validation passed" ]' _ "$(shape "$O")"
distinct="$(/usr/bin/grep -o 'S_[A-Z_]*' "$M" | sort -u | wc -l | tr -d ' ')"
onlines="$(/usr/bin/grep -c 'S_[A-Z_]*' "$M")"
info "Muse placeholders: $distinct distinct tokens on $onlines lines"
check X3 "raw/muse.md carries 43 distinct S_* placeholder tokens on 26 lines" test "$distinct/$onlines" = "43/26"

# --- DECISION shape -----------------------------------------------------------------
unfenced() { awk '/^```/ {f = !f; next} !f' "$dec"; }
h2="$(unfenced | /usr/bin/grep '^## ' | tr '\n' '|')"
check X4 "H2s are exactly Decision, Parameters, Empirical check, Engines, in order (no Supersedes)" \
  test "$h2" = "## Decision|## Parameters|## Empirical check|## Engines|"
decision_part() { unfenced | awk '/^## Decision$/ {on=1; next} /^## / {on=0} on'; }
check X5 "exactly one '### Principles and implementation' inside Decision" \
  test "$(decision_part | /usr/bin/grep -c '^### Principles and implementation$')" = 1
check X6 "exactly one line beginning 're-verify:' inside Decision" \
  test "$(decision_part | /usr/bin/grep -c '^re-verify:')" = 1
revs="$(/usr/bin/grep -o -E '^\*\*Revision note, revision [0-9]+\.\*\*' "$dec" | /usr/bin/grep -o -E '[0-9]+' | tr '\n' ' ')"
nrev="$(wc -w <<<"$revs" | tr -d ' ')"
seqrev=""; for ((i = 1; i <= nrev; i++)); do seqrev+="$i "; done
info "revision notes found: $revs(N=$nrev)"
revs_ok() { [ "$nrev" -ge 1 ] && [ "$revs" = "$seqrev" ]; }
check X7a "the revision notes run 1..N in order with no gap (N=$nrev)" revs_ok
check X7 "the first line is the dated title of revision N=$nrev" \
  test "$(head -n 1 "$dec")" = "# 2026-09-26 — R35 — coverage-tooling (bundle, Focused) — decision (revision $nrev)"
params_part() { unfenced | awk '/^## Parameters$/ {on=1; next} /^## / {on=0} on'; }
check X8 "Parameters carries no owns line" bash -c '! /usr/bin/grep -q "^- owns " <<<"$1"' _ "$(params_part)"
expected="$(jq -r '.[] | "- assumes \(.param) = \(.value)"' "$run/inputs/parameters.json" | sort)"
actual="$(params_part | /usr/bin/grep '^- assumes ' | sort)"
check X9 "the five assumes lines are byte-identical to inputs/parameters.json" test "$actual" = "$expected"
check X10 "no @@ template token remains in the DECISION" bash -c '! /usr/bin/grep -q "@@" "$1"' _ "$dec"

# --- the fenced recipe is the executed recipe -----------------------------------------
fenced_recipe="$(awk '/^```make$/ {on=1; next} /^```$/ {on=0} on' "$dec" | /usr/bin/grep -E '^(coverage_fail_under|    cargo llvm-cov)')"
fixture_recipe="$(/usr/bin/grep -E '^(coverage_fail_under|    cargo llvm-cov)' "$here/r35-coverage.sh")"
check X11 "the DECISION's recipe lines equal the Justfile r35-coverage.sh executed" test "$fenced_recipe" = "$fixture_recipe"
info "recipe lines compared: $(wc -l <<<"$fenced_recipe" | tr -d ' ')"

# --- every cited check ID is a PASS line in a committed log -----------------------------
ids="$(/usr/bin/grep -o -E '`[CFSIT][0-9]{1,2}[a-z]?`' "$dec" | tr -d '`' | sort -u)"
missing=""
for id in $ids; do
  /usr/bin/grep -q -h -E "^PASS ${id}([a-z]| |-)" "$here"/r35-install.log "$here"/r35-coverage.log \
    "$here"/r35-flags.log "$here"/r35-toolchain.log "$here"/r35-sources.log "$here"/r35-tarpaulin.log || missing="$missing $id"
done
info "check IDs cited: $(wc -w <<<"$ids" | tr -d ' ')"
check X12 "every check ID the DECISION cites is a PASS line in a committed log${missing:+ (missing:$missing)}" test -z "$missing"
check X13 "no committed evidence log carries a FAIL line" \
  bash -c '! /usr/bin/grep -q -h "^FAIL " "$@"' _ "$here"/r35-install.log "$here"/r35-coverage.log "$here"/r35-flags.log "$here"/r35-toolchain.log "$here"/r35-sources.log "$here"/r35-tarpaulin.log

no_unix_signal_claim() { ! /usr/bin/grep -q -i -E 'SIGINT|SIGTRAP|unix signal|signals? interfere|--forward|ptrace.{0,40}signal|signal.{0,40}ptrace' "$M"; }
check X14 "raw/muse.md makes no unix-signal claim (every 'signal' in it means evidence, e.g. 'adoption signal')" no_unix_signal_claim

# X15: every figure the Empirical check quotes from the 2026-09-27 rerun is in a committed rerun log.
rr="$here/rerun-2026-09-27"
rerun_figures() {
  /usr/bin/grep -q -F 'PASS C2a — just test (uninstrumented cargo test --locked --workspace --all-features) exits 0 in 13s cold' "$rr/r35-coverage.log" &&
  /usr/bin/grep -q -F 'PASS C3a — just coverage exits 0 on the fixture in 11s' "$rr/r35-coverage.log" &&
  /usr/bin/grep -q -F 'succeeded in 49s' "$rr/r35-install.log" &&
  /usr/bin/grep -q -F 'crates.io cargo-llvm-cov recent_downloads=1685922 ' "$rr/r35-sources.log" &&
  /usr/bin/grep -q -F 'crates.io cargo-tarpaulin recent_downloads=296308 ' "$rr/r35-sources.log" &&
  /usr/bin/grep -q -F 'github mozilla/grcov stars=1367 ' "$rr/r35-sources.log" &&
  ! /usr/bin/grep -q -h '^FAIL ' "$rr"/r35-*.log
}
check X15 "the rerun figures the DECISION quotes (13 s, 11 s, 49 s, 1685922, 296308, 1367) are in rerun-2026-09-27/ logs, which carry no FAIL line" rerun_figures

echo "SUMMARY PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
