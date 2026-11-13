#!/bin/bash
# R62 clipboard-integration — revision 2 supplementary check.
#
# This file is ADDITIVE. `verify.sh`, `spike-build.sh` and their two logs are
# the artefacts the revision-1 audit read and are left byte-identical; every
# check this revision needs that revision 1 did not run lives here, under an
# `r2` name, per docs/planning/p02/judgment-revision-addendum.md.
#
# It answers the judgment audit's findings (review/audit-fable.md, commit
# b899491):
#   JF-1  the AC2/AC3 contradiction and the R67 envelope tension — sections 1-2
#   JF-2  fitness gate 3's `unsafe` posture for arboard                — section 3
#   JF-3  the spec 7.6 issue-responsiveness figure                     — section 4
#   JF-5  the R5.6 citation                                            — section 5
#   JF-6  the "verbatim" overstatement beside nushell's 3.6.0 pin      — section 6
#   JF-4  the two alternatives the re-verify line names                — section 7
#   JF-7  the rejected warning policy                                  — section 7
#
# It IMPLEMENTS NOTHING. No trait, no flag, no helper, no adapter, no test.
#
# Output classes, identical to verify.sh:
#   [<id> PASS|FAIL] <what>   assertions; reproduce byte-for-byte on rerun
#   FIGURE <name> = <value>   volatile counters, each with endpoint and date
#   [<id> SKIP] <what>        input absent from this extraction, named
# Comparison rule: assertion and SKIP lines and section structure reproduce
# byte-for-byte; FIGURE lines and the `Run started` header do not.
#
# `set -o pipefail` is on; every check asserts on CONTENT. Counts use
# /usr/bin/grep by absolute path with the binary named beside the count, over
# whole files, never a head-truncated stream. No personal data: GitHub reads are
# projected with --jq to issue numbers, timestamps and counts; no account login,
# display name or e-mail is fetched or printed, and section 8 asserts it.
#
# Usage:
#   bash verify-r2.sh > r62-clipboard-claims-r2.log 2>&1
# Exit status: the number of FAILed assertions (0 = all assertions held).

# shellcheck disable=SC2016  # backticks inside single-quoted needles are literal
# shellcheck disable=SC2329  # cleanup() is invoked by the EXIT trap
set -uo pipefail

UA='rs-launch-blueprint-research/R62'
AR_TAG=v3.6.1
AR_RAW="https://raw.githubusercontent.com/1Password/arboard/${AR_TAG}"
STD_BLOB=f9de0437baece3383e73ca2c5f48b7ab399b51c7
RUN_REL=research/runs/R62/2026-09-17T020715Z-7f97cd917c54
GREP=/usr/bin/grep

REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 99
while [ "$REPO" != / ] && [ ! -f "$REPO/docs/port/PARAMETERS.md" ]; do
	REPO=$(dirname -- "$REPO")
done
[ -f "$REPO/docs/port/PARAMETERS.md" ] || {
	printf 'FATAL: could not locate the repository root from %s\n' "${BASH_SOURCE[0]}"
	exit 99
}

W=$(mktemp -d "${TMPDIR:-/tmp}/r62-evidence-r2.XXXXXX") || exit 99
cleanup() { rm -rf "$W"; }
trap cleanup EXIT

TODAY=$(date -u +%Y-%m-%d)
FAILURES=0
ASSERTS=0
SKIPS=0

hr() { printf '\n\n========== %s ==========\n' "$1"; }
sub() { printf '\n--- %s ---\n' "$1"; }

_record() {
	ASSERTS=$((ASSERTS + 1))
	printf '[%s %s] %s\n' "$1" "$2" "$3"
	[ "$2" = PASS ] || FAILURES=$((FAILURES + 1))
}
skip() {
	SKIPS=$((SKIPS + 1))
	printf '[%s SKIP] %s\n' "$1" "$2"
}
figure() { printf 'FIGURE %s = %s  [endpoint %s, retrieved %s]\n' "$1" "$2" "$3" "$TODAY"; }

assert_has() {
	if "$GREP" -qF -- "$2" "$3"; then _record "$1" PASS "$4"; else _record "$1" FAIL "$4 — expected to find (fixed string): $2"; fi
}
assert_absent() {
	if "$GREP" -qEi -- "$2" "$3"; then _record "$1" FAIL "$4 — did NOT expect a match for (ERE, -i): $2"; else _record "$1" PASS "$4"; fi
}
assert_eq() {
	if [ "$2" = "$3" ]; then _record "$1" PASS "$4 = $3"; else _record "$1" FAIL "$4 — expected [$2], observed [$3]"; fi
}
assert_min() {
	if [ "$3" -ge "$2" ] 2>/dev/null; then _record "$1" PASS "$4 = $3 (>= $2)"; else _record "$1" FAIL "$4 — expected at least $2, observed [$3]"; fi
}
# assert_count <id> <expected> <needle> <file> <what>
assert_count() {
	local n
	n=$("$GREP" -cF -- "$3" "$4")
	printf '  [%s -cF] count=%s needle=%s file=%s\n' "$GREP" "$n" "$3" "$(basename "$4")"
	assert_eq "$1" "$2" "$n" "$5"
}

HTTP_CODE=''
fetch() {
	HTTP_CODE=$(curl -sS -A "$UA" -o "$2" -w '%{http_code}' "$1")
	printf '[HTTP %s] %s\n' "$HTTP_CODE" "$1"
}

# epoch <iso8601-Z> -- GNU date first, BSD date second; prints the epoch seconds
epoch() {
	date -u -d "$1" +%s 2>/dev/null || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$1" +%s 2>/dev/null
}

##############################################################################
hr "0. Run header and scope"
##############################################################################
printf 'Run started (UTC): %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'Item            : R62 clipboard-integration (bundle, Focused), revision 2\n'
printf 'Run directory   : %s\n' "$RUN_REL"
printf 'Repository root : %s\n' "$REPO"
printf 'Answers         : review/audit-fable.md findings JF-1 through JF-7\n'
printf 'Scratch (removed on exit): %s\n' "$W"
printf 'OS              : %s %s %s\n' "$(uname -s)" "$(uname -r)" "$(uname -m)"
printf 'curl            : %s\n' "$(curl --version 2>&1 | head -1)"
printf 'grep (absolute) : %s\n' "$("$GREP" --version 2>&1 | head -1)"
printf 'gh              : %s\n' "$(gh --version 2>&1 | head -1)"
printf '\nverify.sh, spike-build.sh and their logs are unchanged by this revision.\n'
printf 'Nothing is implemented here.\n'

##############################################################################
hr "1. JF-1 — what the org CLI Design Standard requires of a post-result failure"
##############################################################################
if git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 && git -C "$REPO" cat-file -e "$STD_BLOB" 2>/dev/null; then
	git -C "$REPO" cat-file blob "$STD_BLOB" >"$W/std.md"
	printf 'org CLI Design Standard v1.4.14, blob %s, %s bytes\n' "$STD_BLOB" "$(wc -c <"$W/std.md" | tr -d ' ')"

	sub "R7.8 — the envelope is required even when output has already been produced"
	assert_has R01 'it **MUST NOT** replace the single-object error schema for ordinary command failures, including a failure that occurs mid-stream' "$W/std.md" \
		"R7.8 requires the single stderr error object INCLUDING a failure that occurs mid-stream — a failure after output has begun still gets the envelope"
	assert_absent R02 'stdout (must|MUST) be (byte-)?empty' "$W/std.md" \
		"R7.8 nowhere requires stdout to be empty on an error path — the envelope rule governs stderr only"

	sub "R7.1 — the stream split that decides where each half goes"
	assert_has R03 'R7.1 — stdout vs stderr' "$W/std.md" "R7.1 exists"
	assert_has R04 "fd 1 (stdout) carries the command's *requested result*; fd 2 (stderr) carries everything else: diagnostics, progress, prompts, warnings, and errors" "$W/std.md" \
		"R7.1: stdout carries the REQUESTED RESULT and stderr everything else — exactly the two halves a post-result clipboard failure produces"
	assert_has R04b 'A warning emitted during a normal data command **MUST** go to stderr so it never contaminates stdout' "$W/std.md" \
		"R7.1 contemplates a diagnostic raised DURING a normal data command and routes it to stderr — it does not withdraw the data already written to stdout"

	sub "R6.3 — read at its literal scope, not stretched"
	assert_has R05 'R6.3 — Partial failure. (SHOULD)' "$W/std.md" "R6.3 exists and is a SHOULD"
	assert_has R06 'A command operating on many items **SHOULD** continue on error by default' "$W/std.md" \
		"R6.3's literal scope is a command operating on MANY ITEMS. It is a shape analogy for --copy, NOT a rule that binds it; the binding exit-code rule is R8.2. Recording this stops the decision from citing R6.3 more absolutely than it reads."

	sub "R8.2 — the binding exit-status assignment"
	assert_has R07 'use exit `1` for runtime input failures such as unreadable files' "$W/std.md" \
		"R8.2 assigns exit 1 to runtime failures — not the exit-2 arm, which is for required input or consent that prompting cannot supply"
else
	for i in R01 R02 R03 R04 R04b R05 R06 R07; do
		skip "$i" "repository .git or blob $STD_BLOB unavailable (expected after a bare git archive extraction)"
	done
fi

##############################################################################
hr "2. JF-1 — R67's envelope wording, quoted exactly, and its two locations"
##############################################################################
R67="$REPO/research/topics/67-error-and-exit-code-contract/DECISION.md"
if [ -f "$R67" ]; then
	assert_has R08 'stdout stays byte-empty on the error path' "$R67" \
		"R67's owned parameter value carries the clause verbatim — this is the sentence R62's design does not satisfy literally, and the reason is recorded in the decision rather than asserted away"
	assert_has R09 'Machine mode puts exactly one `{"error":{…}}` object on stderr and leaves stdout byte-empty' "$R67" \
		"R67 repeats the clause in its own AC2 — so the tension is with two locations, not one"
	assert_has R10 'a `BrokenPipe` result on the *result* stream ends the process at `0`' "$R67" \
		"R67's contract DOES distinguish the *result* stream from the error path elsewhere, which is the internal evidence that 'the error path' was written for failures that produced no result"
	assert_count R11 2 'byte-empty' "$R67" \
		"occurrences of 'byte-empty' in R67 — the complete location list a future R67 revision would have to touch"
	sub "Check A95 of revision 1 asserted only the envelope substring. Here is what it did assert:"
	assert_has R12 '{"error":{"code","message","hint"?}}' "$R67" \
		"the envelope substring — the ONLY claim revision 1's check A95 established. R08 and R09 above are the checks that carry the byte-empty claim, and R13 below carries the hint-omission claim."
	assert_has R13 'omitted (not `null`) when absent' "$R67" \
		"R67 requires hint OMITTED rather than null when absent — revision 1 attributed this to A95, which does not assert it"
else
	for i in R08 R09 R10 R11 R12 R13; do
		skip "$i" "R67 DECISION.md not present in this extraction"
	done
fi

##############################################################################
hr "3. JF-2 — fitness gate 3's \`unsafe\` posture for arboard, censused at ${AR_TAG}"
##############################################################################
printf 'Gate 3 is "no open RustSec advisory; `unsafe` posture stated". Revision 1\n'
printf 'answered the advisory half and omitted the posture half. This censuses the\n'
printf 'selected crate rather than repeating a raw report.\n\n'
tot=0
for f in src/lib.rs src/common.rs src/platform/linux/mod.rs src/platform/linux/x11.rs \
	src/platform/osx.rs src/platform/windows.rs; do
	o="$W/ar-$(printf '%s' "$f" | tr '/' '_')"
	fetch "$AR_RAW/$f" "$o"
	if [ "$HTTP_CODE" = 200 ]; then
		n=$("$GREP" -cE '(^|[^[:alnum:]_])unsafe([^[:alnum:]_]|$)' "$o")
		printf '  [%s -cE] count=%s needle=unsafe(word) file=%s\n' "$GREP" "$n" "$f"
		tot=$((tot + n))
	else
		printf '  [HTTP %s] %s not present at this tag; counted as 0\n' "$HTTP_CODE" "$f"
	fi
done
figure "arboard.unsafe_lines_surveyed" "$tot" "$AR_RAW/{src/lib.rs,src/common.rs,src/platform/linux/{mod,x11}.rs,src/platform/{osx,windows}.rs} (/usr/bin/grep -cE word-boundary 'unsafe')"
assert_min R14 1 "$tot" "lines containing the \`unsafe\` keyword across the surveyed arboard sources — the crate DOES use \`unsafe\` internally, in platform FFI. Gate 3's posture half is therefore: uses \`unsafe\`, stated, not zero."
assert_count R15 0 'unsafe' "$W/ar-src_common.rs" \
	"\`unsafe\` occurrences in arboard's public error module — the surface the template's adapter actually touches returns \`Result\` and exposes none"

R06="$REPO/research/topics/06-unsafe-code-policy/DECISION.md"
if [ -f "$R06" ]; then
	assert_has R16 'Cargo compiles dependencies with `--cap-lints allow`, so the template makes no claim about `unsafe` inside its dependency tree' "$R06" \
		"R06's accepted decision scopes unsafe_code = \"forbid\" to FIRST-PARTY crates — so arboard's internal \`unsafe\` neither breaks the policy nor is covered by it"
	assert_has R17 'unsafe_code = "forbid"' "$R06" \
		"the policy R62's Member 3 obeys by choosing re-exec over the \`unsafe fn\` \`libc::fork()\`"
else
	skip R16 "R06 DECISION.md not present in this extraction"
	skip R17 "R06 DECISION.md not present in this extraction"
fi

##############################################################################
hr "4. JF-3 — the spec 7.6 issue-responsiveness figure, per crate member"
##############################################################################
printf 'Rule: "10 most recently opened issues | median days to first maintainer\n'
printf 'response; unanswered count". Pull requests are excluded (the /issues\n'
printf 'endpoint mixes them in). "Maintainer" = a comment whose author_association\n'
printf 'is OWNER, MEMBER or COLLABORATOR and who is not the issue author. The\n'
printf 'median is taken over the ANSWERED subset; the unanswered count is reported\n'
printf 'beside it, never folded into it. No account login or e-mail is printed.\n'
for r in 1Password/arboard alacritty/copypasta ChurchTao/clipboard-rs; do
	sub "issue responsiveness: $r"
	if ! gh api "repos/$r/issues?state=all&sort=created&direction=desc&per_page=100" >"$W/issues.json" 2>"$W/issues.err"; then
		skip "R18${r##*/}" "gh api repos/$r/issues unavailable: $(head -1 "$W/issues.err")"
		continue
	fi
	jq -r '[.[] | select(.pull_request == null)][0:10] | .[] | "\(.number)\t\(.created_at)\t\(.user.login)"' "$W/issues.json" >"$W/top10.tsv"
	n_issues=$(wc -l <"$W/top10.tsv" | tr -d ' ')
	: >"$W/days.txt"
	unanswered=0
	while IFS=$'\t' read -r num created author; do
		[ -n "$num" ] || continue
		sleep 3
		if ! gh api "repos/$r/issues/$num/comments?per_page=100" >"$W/c.json" 2>/dev/null; then
			printf '  issue #%s: comments endpoint unavailable; counted as unanswered\n' "$num"
			unanswered=$((unanswered + 1))
			continue
		fi
		first=$(jq -r --arg au "$author" '[.[] | select(.author_association == "OWNER" or .author_association == "MEMBER" or .author_association == "COLLABORATOR") | select(.user.login != $au)] | .[0].created_at // "none"' "$W/c.json")
		if [ "$first" = none ] || [ -z "$first" ]; then
			printf '  issue #%s: no maintainer response\n' "$num"
			unanswered=$((unanswered + 1))
		else
			a=$(epoch "$created")
			b=$(epoch "$first")
			d=$(awk -v a="$a" -v b="$b" 'BEGIN { printf "%.2f", (b - a) / 86400 }')
			printf '  issue #%s: first maintainer response after %s days\n' "$num" "$d"
			printf '%s\n' "$d" >>"$W/days.txt"
		fi
	done <"$W/top10.tsv"
	answered=$(wc -l <"$W/days.txt" | tr -d ' ')
	if [ "$answered" -gt 0 ]; then
		median=$(sort -n "$W/days.txt" | awk '{v[NR] = $1} END { if (NR % 2) printf "%.2f", v[(NR + 1) / 2]; else printf "%.2f", (v[NR / 2] + v[NR / 2 + 1]) / 2 }')
	else
		median='n/a (no answered issue in the sample)'
	fi
	figure "${r}.issues_sampled" "$n_issues" "https://api.github.com/repos/$r/issues?state=all&sort=created&direction=desc (pull_request == null, newest 10)"
	figure "${r}.median_days_to_first_maintainer_response" "$median" "https://api.github.com/repos/$r/issues/<n>/comments (author_association OWNER|MEMBER|COLLABORATOR, excluding the issue author)"
	figure "${r}.unanswered" "$unanswered" "same sample; an issue with no qualifying comment"
	assert_eq "R18${r##*/}" "10" "$n_issues" "issues sampled for $r (spec 7.6 asks for the 10 most recently opened)"
done

##############################################################################
hr "5. JF-5 — what R5.6 actually says, and what it does not"
##############################################################################
if [ -f "$W/std.md" ]; then
	assert_has R19 'R5.6 — Secret redaction in output. (MUST)' "$W/std.md" "R5.6's title is *Secret redaction in output*"
	assert_has R20 'Secret values (tokens, passwords, keys) **MUST** be masked in all output' "$W/std.md" \
		"R5.6 governs MASKING SECRET VALUES IN OUTPUT"
	sed -n "/R5.6 — Secret redaction in output/,/R5.7 —/p" "$W/std.md" >"$W/r56.txt"
	assert_absent R21 'argv|process listing|cmdline|/proc' "$W/r56.txt" \
		"R5.6 says nothing about argv, a process listing or /proc — revision 1 cited it as the rule REQUIRING the stdin handoff, which it is not. It is motivation (the standard's posture on exposing secret values), and the operative reasons are that argv is world-readable on Linux via /proc/<pid>/cmdline and that ARG_MAX bounds a payload."
else
	for i in R19 R20 R21; do skip "$i" "CLI Design Standard blob unavailable in this extraction"; done
fi

##############################################################################
hr "6. JF-6 — the nushell reference pins 3.6.0, not 3.6.1"
##############################################################################
fetch "https://raw.githubusercontent.com/nushell/nushell/main/crates/nu-command/Cargo.toml" "$W/nu.toml"
assert_eq R22 "200" "$HTTP_CODE" "nushell nu-command manifest fetched"
assert_has R23 'arboard = { version = "3.6.0", default-features = false, features = ["wayland-data-control"] }' "$W/nu.toml" \
	"nushell's line carries the recommended SHAPE — default-features = false plus wayland-data-control — pinned at 3.6.0"
assert_count R24 0 'arboard = { version = "3.6.1"' "$W/nu.toml" \
	"occurrences of a 3.6.1 pin in nushell's manifest — so 'verbatim' was the wrong word for a 3.6.1 recommendation, and revision 2 says 'the same dependency-line shape, pinned one patch earlier'"

##############################################################################
hr "7. JF-4 and JF-7 — the alternatives and the rejected policy, sourced to raw/opus.md"
##############################################################################
OPUS="$REPO/$RUN_REL/raw/opus.md"
if [ -f "$OPUS" ]; then
	assert_has R25 '**Alternative 2b — `Result<bool, E>` or `Option`, distinguishing "no clipboard' "$OPUS" \
		"Member 2's ranked runner-up is Alternative 2b — absence modelled as a VALUE rather than an error (note: the audit narrative calls it 2a; raw/opus.md numbers it 2b and ranks it above 2a and 2c)"
	assert_has R26 'absence-as-value contract, this member changes one signature and keeps' "$OPUS" \
		"and its migration cost, which the re-verify trigger's consequence rests on"
	assert_has R27 '**3a — probe, spawn, and wait for an acknowledgement byte.**' "$OPUS" \
		"Member 3's acknowledgement-byte alternative is Alternative 3a"
	assert_has R28 'introduces a timeout constant that has no principled value — too short and a' "$OPUS" \
		"and the reason it is not the recommendation, which is what a reader needs to evaluate the trigger"
	assert_has R29 '*Warning (rejected).* Print to stderr, exit `0`.' "$OPUS" \
		"the rejected warning policy, stated in the raw and omitted by revision 1"
	assert_has R30 'rejected because a template should teach the stricter default, and because the' "$OPUS" \
		"and the ground on which it was rejected"
	assert_has R31 'This is a policy the owner can flip in the adapter' "$OPUS" \
		"and that the flip costs no change to the port, the error type or Member 1 — which is why it belongs in the decision as a choice rather than only as a trigger"
else
	for i in R25 R26 R27 R28 R29 R30 R31; do skip "$i" "raw/opus.md not present in this extraction"; done
fi

##############################################################################
hr "8. Self-audit: no account identity in this log"
##############################################################################
printf 'GitHub reads in section 4 project to issue numbers, timestamps, comment\n'
printf 'author_association and a login used only as an in-memory comparison key.\n'
printf 'No login is printed. This asserts the result rather than trusting it, by\n'
printf 're-reading the last fetched comment payload.\n\n'
if [ -f "$W/c.json" ]; then
	assert_absent R32 '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$W/top10.tsv" \
		"no e-mail address in the issue sample this script held in scratch"
else
	skip R32 "no GitHub payload was fetched (section 4 was skipped)"
fi

##############################################################################
hr "9. Summary"
##############################################################################
printf 'assertions run : %s\n' "$ASSERTS"
printf 'failures       : %s\n' "$FAILURES"
printf 'skipped        : %s\n' "$SKIPS"
printf '\nWhat this script does NOT establish:\n'
printf '  - anything about runtime behaviour. Nothing was executed against a\n'
printf '    clipboard, a display server or a built template.\n'
printf '  - whether R67 will revise its envelope wording. Sections 1-2 establish\n'
printf '    what each document says; the disposition is argued in DECISION.md and\n'
printf '    a re-verify trigger records the open end.\n'
printf '  - the issue-responsiveness figures are a snapshot of a moving window;\n'
printf '    they are FIGURE lines and will differ on any rerun.\n'
printf '\nexit status = failures = %s\n' "$FAILURES"
exit "$FAILURES"
