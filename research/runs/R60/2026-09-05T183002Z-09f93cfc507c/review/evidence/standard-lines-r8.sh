#!/usr/bin/env bash
# R60 revision 8 — read the BODY of every CLI Design Standard line this decision
# cites for a proposition, and assert the proposition rather than the heading
# above it. This script is finding F4's repair and is NEW; no earlier script is
# edited, because `r60-standard-pin-r5.sh` is the artifact the round-7 empirical
# audit reran and diffed.
#
# WHY IT EXISTS. `C8` of `r60-standard-pin-r5.sh` carries exactly twelve
# `<line>|<expected>` specs, and two of them — `:270` (R4.5) and `:275` (R4.6) —
# assert a markdown HEADING. A heading assertion passes while saying nothing
# about the rule underneath it, so the check was vacuous for the propositions
# those lines were cited for. The round-7 judgment audit (finding F4) found two
# citations that were wrong for exactly that reason: R9.1's "at least bash, zsh,
# and fish" is at :484, not the :483 heading; R4.5's `-o`/`--output` spelling is
# at :271, not the :270 heading. Revision 4 had already found and fixed the same
# defect in R4.6 (:275 heading, :276 rule) — for that one rule only. This script
# closes the class instead of the instance.
#
# WHAT IT ASSERTS, AND THE TWO SHAPES IT ASSERTS IN.
#   POSITIVE  the rule BODY line carries the exact words this decision quotes or
#             relies on.
#   NEGATIVE  the HEADING line above it does NOT carry them. That is what makes
#             an off-by-one citation detectable rather than merely unasserted,
#             and it is why the wrong line numbers are quoted here as false
#             rather than silently replaced.
#   L20       a CLASS control: every rule this decision names by ID has its rule
#             BODY read by some committed check. A rule cited later whose body no
#             check reads fails L20a instead of going unnoticed, which is the
#             instance-versus-class failure the round-7 audit named. Why the
#             control is shaped this way rather than as a census of `:<line>`
#             tokens is argued at L20 itself.
#
# WHAT IT READS. Only two files, both committed inside this run directory:
#   * `snapshots/cli-design-standard-1.4.14.md`, verified against the sha256 in
#     `snapshots/MANIFEST.txt` AND against the pinned blob's content hash before
#     a single line is read; and
#   * `../DECISION.md`, for the L20 rule-id census only — no line of the decision
#     is asserted here; only the set of rule ids it names is read.
# It makes no network call and reads nothing outside this run directory. GIT IS
# NOT USED AT ALL, so there is nothing for this script to skip when `.git` is
# absent: it runs identically inside a clean `git archive HEAD` extraction.
#
# Output is location-independent: no absolute path is printed and `shasum` is
# fed on stdin so it prints `-` rather than a file name. That is what lets the
# committed log be diffed byte-for-byte against a rerun in any directory.
#
# Harness note, carried from the earlier scripts: `check` is never placed on the
# right-hand side of a pipe, because a piped function body runs in a subshell and
# its increment of `fails` is lost.
#
# SHELLCHECK. The repository's pre-commit hook runs `shellcheck` on staged shell
# content and fails on any finding, info level included. Three of this script's
# expectation strings are literal markdown carrying backticks and a `$`-free
# `--output`/`-o` spelling, quoted single so the text reaches `grep -F` exactly
# as the standard writes it; shellcheck reports each as SC2016 ("expressions
# don't expand in single quotes"), which is true and is the point. The directive
# below disables that one info for this file rather than rewriting the
# expectations, because rewriting an expectation changes what the check asserts.
# It is file-level and names one code; nothing else is suppressed, and the log
# below is unaffected by it.
# shellcheck disable=SC2016
set -o pipefail

GREP=/usr/bin/grep   # absolute, never PATH: a typed `grep` here can be ugrep

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="$HERE/snapshots"
RUN_DIR="$(cd "$HERE/../.." && pwd)"

STD="$SNAP/cli-design-standard-1.4.14.md"
DEC="$RUN_DIR/review/DECISION.md"
PIN_SHA256="9fb05d3dfaa5ea11fbf66422e988b0ae8c050e22a39b9fc6dd9688734f02463f"

fails=0
checks=0

check() { # check <label> <expected-substring> <actual-output>
  local label="$1" want="$2" got="$3"
  checks=$((checks + 1))
  if [ -z "$want" ]; then
    printf 'BUG   %s — empty expectation; a check that cannot fail is not evidence\n' "$label"
    fails=$((fails + 1))
    return
  fi
  if printf '%s' "$got" | "$GREP" -qF -- "$want"; then
    printf 'PASS  %s\n' "$label"
  else
    printf 'FAIL  %s\n      wanted substring: %s\n      got: %s\n' "$label" "$want" "$got"
    fails=$((fails + 1))
  fi
}

absent() { # absent <label> <substring-that-must-NOT-occur> <actual-output>
  local label="$1" bad="$2" got="$3"
  checks=$((checks + 1))
  if [ -z "$bad" ]; then
    printf 'BUG   %s — empty expectation\n' "$label"
    fails=$((fails + 1))
    return
  fi
  if printf '%s' "$got" | "$GREP" -qF -- "$bad"; then
    printf 'FAIL  %s\n      must NOT contain: %s\n      got: %s\n' "$label" "$bad" "$got"
    fails=$((fails + 1))
  else
    printf 'PASS  %s (absent: %s)\n' "$label" "$bad"
  fi
}

sha() { shasum -a 256 < "$1" | awk '{print $1}'; }   # stdin, so no path is printed
stdline() { sed -n "$1p" "$STD"; }

echo "=== L-grep. the search binary every count below was produced by ==="
GREP_VERSION="$("$GREP" --version 2>&1 | head -1)"
echo "grep binary:  $GREP"
echo "grep version: $GREP_VERSION"

echo "=== L0. negative controls: prove this harness can actually fail ==="
echo "--- the next two FAIL lines are deliberate ---"
check "L0a control (expected to FAIL)" "THIS-SUBSTRING-IS-ABSENT" "the pinned standard"
absent "L0b control (expected to FAIL)" "pinned" "the pinned standard"
if [ "$fails" -eq 2 ] && [ "$checks" -eq 2 ]; then
  echo "PASS  L0 harness detected both mismatches and incremented its counter"
else
  echo "BUG   L0 harness did NOT register both mismatches (fails=$fails checks=$checks) — results below are meaningless"
  exit 99
fi
echo "--- controls accounted for; counters reset, real checks follow ---"
fails=0
checks=0

check "L-grep the search binary is an absolute /usr/bin/grep that reports a version" \
  "grep" "$GREP:$GREP_VERSION"

echo "=== L1. the text read below IS the pinned blob, by content hash ==="
out="$(sha "$STD")"
echo "$out"
check "L1a the snapshot's sha256 is the pinned blob's, $PIN_SHA256" "$PIN_SHA256" "$out"
out="$("$GREP" -F "cli-design-standard-1.4.14.md" "$SNAP/MANIFEST.txt")"
echo "MANIFEST row for the standard: $out"
check "L1b MANIFEST.txt records that same sha256 for it" "$PIN_SHA256" "$out"
out="$(wc -l < "$STD" | tr -d ' ')"
echo "lines in the pinned standard: $out"
check "L1c the pinned standard is 773 lines, so every line read below is in range" "lines=773" "lines=$out"

echo "=== L2. R1.1 — the Standard-profile noun-verb MUST (cited as :124) ==="
# The decision rests P2 and architecture C's exclusion on R1.1 being a MUST for a
# subcommand tool. `C8` asserts the :124 HEADING; the obligation is at :125.
out="$(stdline 124)"; echo "124: $out"
check  "L2a :124 is R1.1's heading" "**R1.1 — Noun-verb ordering. (MUST, Standard profile)**" "$out"
out="$(stdline 125)"; echo "125: $out"
check  "L2b :125 is R1.1's rule body and carries the noun-verb MUST" \
  "A command path **MUST** read *resource then action*" "$out"
absent "L2c the :124 heading carries no obligation text, so citing it proves nothing" \
  "resource then action" "$(stdline 124)"

echo "=== L3. R1.2 — nesting depth (cited as :129) ==="
out="$(stdline 129)"; echo "129: $out"
check  "L3a :129 is R1.2's heading" "**R1.2 — Nesting depth. (SHOULD)**" "$out"
out="$(stdline 130)"; echo "130: $out"
check  "L3b :130 is R1.2's rule body and bounds the depth" \
  "**SHOULD NOT** exceed three path elements" "$out"
absent "L3c the :129 heading bounds nothing" "three path elements" "$(stdline 129)"

echo "=== L4. R3.8 — flag/env/config name parity (cited as :220) ==="
# The decision's principle P4 cites `:220` for the deterministic transform
# `--some-flag` <-> `TOOL_SOME_FLAG`. That text is on :221. Revision 8 corrects
# the citation to :221 and keeps :220 quoted as the wrong number.
out="$(stdline 220)"; echo "220: $out"
check  "L4a :220 is R3.8's heading, which is what revisions 1-7 cited" \
  "**R3.8 — Flag / env / config name parity. (MUST)**" "$out"
out="$(stdline 221)"; echo "221: $out"
check  "L4b :221 is R3.8's rule body and carries the MUST" \
  "**MUST** use the same name across flag, environment variable, and config key" "$out"
check  "L4c :221 carries the deterministic transform this decision quotes" \
  '`--some-flag` ↔ `TOOL_SOME_FLAG`' "$out"
absent "L4d the :220 heading carries no transform, so the old citation was vacuous" \
  "TOOL_SOME_FLAG" "$(stdline 220)"

echo "=== L5. R3.10 — no prefix abbreviation (cited as :229-230) ==="
out="$(stdline 229)"; echo "229: $out"
check  "L5a :229 is R3.10's heading" "**R3.10 — No prefix abbreviation. (MUST)**" "$out"
out="$(stdline 230)"; echo "230: $out"
check  "L5b :230 is R3.10's rule body and forbids prefix abbreviation" \
  "**MUST** require an exact match" "$out"
check  "L5c :230 carries the reason this decision quotes" \
  "adding a flag later silently breaks scripts that relied on the shorter form" "$out"
absent "L5d the :229 heading carries no rule text" "exact match" "$(stdline 229)"

echo "=== L6. R4.1 — the required global core (cited as :237) ==="
out="$(stdline 237)"; echo "237: $out"
check  "L6a :237 is R4.1's heading, which is what revisions 1-7 cited" \
  "**R4.1 — Standard option tiers. (MUST)**" "$out"
out="$(stdline 238)"; echo "238: $out"
check  "L6b :238 is R4.1's rule body and carries the required-global-core MUST" \
  "Every CLI **MUST** implement the **required global core**" "$out"
absent "L6c the :237 heading never names the required global core" \
  "required global core" "$(stdline 237)"

echo "=== L7. R4.5 — global vs command-local flags (cited as :270 — WRONG) ==="
# Finding F4, citation 2. The decision cited `:270` for the `-o`/`--output`
# spelling and for the before/after-the-verb rule. Both are on :271.
out="$(stdline 270)"; echo "270: $out"
check  "L7a :270 is R4.5's heading — the line revisions 1-7 cited" \
  "**R4.5 — Global vs command-local flags. (SHOULD)**" "$out"
out="$(stdline 271)"; echo "271: $out"
check  "L7b :271 is R4.5's rule body and spells the result-output option -o/--output" \
  '(`--output`/`-o`, `--json`)' "$out"
check  "L7c :271 carries the before-the-verb MUST this decision's P5 quotes" \
  "Global flags **MUST** be accepted before the subcommand and **SHOULD** also be accepted after it." "$out"
absent "L7d the :270 heading does not spell --output, so the old citation was vacuous" \
  "--output" "$(stdline 270)"

echo "=== L8. R5.4 — environment variables (cited as :321) ==="
out="$(stdline 321)"; echo "321: $out"
check  "L8a :321 is R5.4's heading" "**R5.4 — Environment variables. (MUST)**" "$out"
out="$(stdline 322)"; echo "322: $out"
check  "L8b :322 is R5.4's rule body and carries the MUST NOT F269 rests on" \
  "**MUST NOT** auto-expose every flag as an env var" "$out"
absent "L8c the :321 heading carries no prohibition" "auto-expose" "$(stdline 321)"

echo "=== L13. R6.1 — the exit-code scheme R67 and this decision both rest on ==="
out="$(stdline 351)"; echo "351: $out"
check  "L13a :351 is R6.1's heading" "**R6.1 — Exit-code scheme. (MUST)**" "$out"
out="$(stdline 352)"; echo "352: $out"
check  "L13b :352 is R6.1's rule body and carries the exit-code MUST" \
  "A CLI **MUST** use the following scheme. Unlisted failures collapse to \`1\`." "$out"
absent "L13c the :351 heading carries no scheme" "following scheme" "$(stdline 351)"

echo "=== L9. R7.3 — TTY-aware presentation, the ground for wrap_help (F6) ==="
out="$(stdline 389)"; echo "389: $out"
check  "L9a :389 is R7.3's heading" "**R7.3 — TTY-aware behavior. (SHOULD / MUST)**" "$out"
out="$(stdline 390)"; echo "390: $out"
check  "L9b :390 is R7.3's rule body and carries the presentation SHOULD" \
  "A tool **SHOULD** detect whether stdout is a TTY and adjust *presentation* accordingly" "$out"
absent "L9c the :389 heading carries no obligation" "**SHOULD** detect" "$(stdline 389)"

echo "=== L10. R7.5 — help text format, the second ground for wrap_help (F6) ==="
out="$(stdline 397)"; echo "397: $out"
check  "L10a :397 is R7.5's heading" "**R7.5 — Help text format. (MUST)**" "$out"
out="$(stdline 398)"; echo "398: $out"
check  "L10b :398 is R7.5's rule body and requires structured, sectioned help" \
  "**MUST** print structured help containing, in order" "$out"
absent "L10c the :397 heading requires nothing" "structured help" "$(stdline 397)"

echo "=== L11. R9.1 — completion shells (cited as :483 — WRONG) ==="
# Finding F4, citation 1. P7 and AC4 rest on "at least bash, zsh, and fish",
# which is on :484. :483 is the heading and names no shell.
out="$(stdline 483)"; echo "483: $out"
check  "L11a :483 is R9.1's heading — the line revisions 1-7 cited" \
  "**R9.1 — Completion, man pages & help topics. (SHOULD / MAY)**" "$out"
out="$(stdline 484)"; echo "484: $out"
check  "L11b :484 is R9.1's rule body and names the three shells" \
  "for at least bash, zsh, and fish" "$out"
check  "L11c :484 also carries the completion-command spelling this decision's F268 follows" \
  'ship shell completion (`acme completion <shell>`)' "$out"
absent "L11d the :483 heading names no shell, so the old citation was vacuous" \
  "bash, zsh, and fish" "$(stdline 483)"

echo "=== L12. R9.3 — interface stability (cited as :491-493 — OVERRUNS) ==="
# Finding F4, citation 3: the quoted clause is on :492; :491 is the heading and
# :493 is blank, the same two-line overrun class revision 4 fixed for R4.6.
out="$(stdline 491)"; echo "491: $out"
check  "L12a :491 is R9.3's heading" "**R9.3 — Interface stability & versioning. (MUST)**" "$out"
out="$(stdline 492)"; echo "492: $out"
check  "L12b :492 is R9.3's rule body and carries the public-contract list verbatim" \
  "command names, flag names, exit codes, env-var names, and machine-readable output shape" "$out"
out="$(stdline 493)"
printf '493: [%s]\n' "$out"
check  "L12c :493 is blank, so R9.3's body ends at :492" "blank=yes" \
  "blank=$([ -z "$out" ] && echo yes || echo no)"
absent "L12d the :491 heading carries no list" "env-var names" "$(stdline 491)"

echo "=== L20. CLASS CONTROL: every rule the decision names by id has its BODY read ==="
# The instance-versus-class repair, and the shape it takes matters.
#
# A PURELY LEXICAL CENSUS OF `:<n>` TOKENS DOES NOT WORK HERE, and saying so is
# part of the evidence. This document cites the standard as a bare backticked
# line reference (`:271`) AND cites clap's own sources the same way once a file
# has been named (`command.rs:2664-2666` then `:2666`), so `:264` is a
# `clap_builder` line while `:271` is a standard line and no regular expression
# separates them. A census over that pattern would report dozens of false
# uncovered lines and prove nothing.
#
# WHAT IS MECHANICAL, AND IS THE ACTUAL DEFECT'S SHAPE. Every rule this decision
# leans on, it names by ID — `R4.5`, `R9.1`, `R3.8`. Finding F4's defect is a
# rule cited by id whose RULE BODY no committed check reads, which is what made
# an off-by-one citation survive seven rounds. So: extract every `R<n>.<m>` id
# from the decision, locate that rule's heading in the pinned standard by
# searching for the heading itself, take heading+1 as the body line, and require
# that body line to be read by a committed check.
#
# THE READ SET, and which committed check reads each line:
#   this script     125 130 221 230 238 271 322 352 390 398 484 492
#   `C4` of r5      134  (R1.3's rule text, read as part of :133-137)
#   `C9` of r5      147  (R1.6's rule text, read as part of :146-149)
#   `C7c` of r5     177  (R2.2's rule text, asserted by line number)
#   `C8b1`-`C8b5`   276  (R4.6's rule text, the eight checks revision 4 added)
#
# THE ONE EXEMPTION, stated rather than hidden: R4.7. The decision names it only
# to say that its HEADING at :279 is one of the two lines the old `:275-279`
# range overran; it rests no proposition on R4.7's body, and `C8b8` asserts that
# heading. An exemption that grew silently would defeat the control, so the list
# is a literal below and L20d asserts its size.
#
# THE LIMIT, stated: this proves that a committed check READS each cited rule's
# body, not that the check reads it for the proposition the decision cites it
# for. That correctness is what L2-L13 assert, one rule at a time.
READ_BODIES=" 125 130 134 147 177 221 230 238 271 276 322 352 390 398 484 492 "
EXEMPT_IDS=" R4.7 "
ids="$("$GREP" -oE 'R[0-9]+\.[0-9]+' "$DEC" | sort -u -V | tr '\n' ' ')"
echo "rule ids named in review/DECISION.md: $ids"
unread=""
n_ids=0
for id in $ids; do
  n_ids=$((n_ids + 1))
  case "$EXEMPT_IDS" in *" $id "*) printf '  %-6s exempt (heading-only citation; C8b8 asserts it)\n' "$id"; continue ;; esac
  head_ln="$("$GREP" -nF -- "**$id — " "$STD" | head -1 | cut -d: -f1)"
  if [ -z "$head_ln" ]; then
    printf '  %-6s NO HEADING FOUND IN THE PINNED STANDARD\n' "$id"
    unread="$unread $id(no-heading)"
    continue
  fi
  body_ln=$((head_ln + 1))
  case "$READ_BODIES" in
    *" $body_ln "*) printf '  %-6s heading :%s  body :%s  READ\n' "$id" "$head_ln" "$body_ln" ;;
    *) printf '  %-6s heading :%s  body :%s  NOT READ\n' "$id" "$head_ln" "$body_ln"
       unread="$unread $id(:$body_ln)" ;;
  esac
done
echo "rules named by the decision whose body no committed check reads:[$unread]"
check "L20a every rule the decision names by id has its body read by a committed check" \
  "unread=[]" "unread=[$unread]"
echo "rule ids found: $n_ids"
check "L20b the id census is live: it found at least 15 distinct rule ids" "live=yes" \
  "live=$([ "$n_ids" -ge 15 ] && echo yes || echo no)"
# Negative control for the membership test: a body line deliberately outside the
# read set must be reported as not read, so the test is shown to discriminate.
probe=772
case "$READ_BODIES" in *" $probe "*) probe_result='read' ;; *) probe_result='not-read' ;; esac
check "L20c the membership test discriminates: :$probe is correctly reported not-read" \
  "probe=not-read" "probe=$probe_result"
n_exempt="$(printf '%s' "$EXEMPT_IDS" | wc -w | tr -d ' ')"
echo "exempt rule ids: $n_exempt"
check "L20d exactly one rule id is exempt, so the exemption list cannot grow unnoticed" \
  "exempt=1" "exempt=$n_exempt"

echo
printf 'CHECKS RUN: %d   FAILURES: %d\n' "$checks" "$fails"
if [ "$fails" -eq 0 ]; then echo "RESULT: all checks passed"; else echo "RESULT: FAILED"; fi
exit "$fails"
