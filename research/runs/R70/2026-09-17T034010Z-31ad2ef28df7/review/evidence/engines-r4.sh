#!/usr/bin/env bash
# R70 revision 4 — the source facts behind the repaired `## Engines` and the
# corrected counts, asserted at their cited lines.  Revision 5 rebinds the R80
# check to R80's published revision 6, replaces the manifest op-state checks with
# leg presence and shape, and adds group F for the /readyz carrier choice.
#
# Revision 3 said this item had one engine.  The pinned prompt names two
# (muse, opus) and a Muse report sits in raw/.  Every fact revision 4 cites
# about that report, its collection record, the three disagreements it raises,
# and the counts the audits corrected is asserted here rather than by reading.
#
# Read-only: no network, no build, nothing written outside stdout.
# Asserts on CONTENT.  PASS/FAIL/SKIP counted and summed; non-zero on FAIL.
set -euo pipefail
set -o pipefail

GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }
assert() { if [ "$2" = "$3" ]; then ok "$1 == $2"; else bad "$1: expected [$2] got [$3]"; fi; }
# at_line LABEL FILE LINE NEEDLE — NEEDLE occurs (fixed string) on exactly LINE.
at_line() {
  if sed -n "${3}p" "$2" | $GREP -qF -- "$4"; then ok "$1 (:$3)"
  else bad "$1 — line $3 of $2 lacks: $4"; fi
}
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }

here="$(cd "$(dirname "$0")" && pwd)"
root="$(git -C "$here" rev-parse --show-toplevel)"
run="$root/research/runs/R70/2026-09-17T034010Z-31ad2ef28df7"
dec="$run/review/DECISION.md"
muse="$run/raw/muse.md"
opus="$run/raw/opus.md"
prompt="$run/inputs/prompt.md"
manifest="$run/manifest.json"
ledger="$root/docs/planning/p02/execution-ledger.md"
r67="$root/research/topics/67-error-and-exit-code-contract/DECISION.md"
# R02 revision 2 as cited (sha256 9e8f8e8c…), via its committed byte-identical
# snapshot; R02's DECISION.md has since moved to revision 3.
r02="$root/research/runs/R02/2026-09-17T033527Z-40929a603f91/review/R02-r2-snapshot.md"
# R80 revision 6, published and immutable; never R80's mutable working file.
r80="$root/research/topics/80-health-probe-endpoints/DECISION.md"

printf '=== R70 revision 5: engines and counts ===\n'
printf 'date (UTC): %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'HEAD: %s\n' "$(git -C "$root" rev-parse HEAD)"
printf 'grep: %s\n' "$($GREP --version | head -1)"

############################################################
printf -- '\n--- A. which engines this item has, and on whose authority\n'
############################################################
assert "raw/muse.md sha256" \
  "989725675cb0f0c7d0dbb975435097d4d0f837e0ec32c137fc4cf64b3c4a7249" "$(sha "$muse")"
assert "raw/opus.md sha256" \
  "82538638b5f54017c22853eb9e52e6d4e6c71b78e35fad8ed6ea68be3fefe39e" "$(sha "$opus")"
assert "raw/opus.md is byte-identical to the collected raw/opus-82538638….md" \
  "$(sha "$opus")" "$(sha "$run/raw/opus-82538638b5f54017c22853eb9e52e6d4e6c71b78e35fad8ed6ea68be3fefe39e.md")"
assert "raw/muse.md line count" "218" "$(wc -l < "$muse" | tr -d ' ')"
assert "inputs/prompt.md sha256 equals manifest input_hashes.prompt" \
  "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["input_hashes"]["prompt"])' "$manifest")" \
  "$(sha "$prompt")"
at_line "prompt names the engines" "$prompt" 23 "- engines: muse, opus"
at_line "prompt states the Muse-for-Codex substitution" "$prompt" 69 \
  "This item substitutes Muse (Meta) for Codex under the \`engine_overrides\` pilot; its mirrored \`- engines:\` line is authoritative."
assert "EXECUTION.json engine_overrides.R70 / items.R70.engines" "muse,opus / muse,opus" \
  "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(",".join(d["engine_overrides"]["R70"]), "/", ",".join(d["items"]["R70"]["engines"]))' "$root/research/EXECUTION.json")"
assert "manifest required_engines" "muse,opus" \
  "$(python3 -c 'import json,sys; print(",".join(json.load(open(sys.argv[1]))["required_engines"]))' "$manifest")"
assert "manifest migration event (at / from / to / cites Q5.A)" \
  "2026-09-21T23:06:20Z codex muse True" \
  "$(python3 -c 'import json,sys
e=[x for x in json.load(open(sys.argv[1]))["events"] if "migration" in x][0]
print(e["at"], e["migration"]["from"], e["migration"]["to"], "owner decision Q5.A 2026-09-21" in e["migration"]["reason"])' "$manifest")"
at_line "ledger records owner decision Q5.A" "$ledger" 1114 \
  "Owner decision (2026-09-21, Q5.A): Muse-bulk all 17 remaining legs"
at_line "RUNBOOK records Q9.B retiring Codex" "$root/research/RUNBOOK.md" 72 \
  "Owner decision Q9.B retired Codex from P02"

############################################################
printf -- '\n--- B. both legs: collected per the ledger, present and well-shaped on disk\n'
############################################################
at_line "ledger entry heading for the collection" "$ledger" 1157 "R58 + R70 MUSE LEGS COLLECTED (retries), 2026-09-23"
at_line "ledger records R70's Muse sha prefix and content" "$ledger" 1157 \
  "R70 sha 98972567 (218 lines, bundle OK) — http-api-problem 0.60.0 envelope + HttpStatus trait"
case "$(sha "$muse")" in
  98972567*) ok "the ledger's 98972567 is the prefix of raw/muse.md's sha256" ;;
  *) bad "the ledger's 98972567 does not prefix raw/muse.md's sha256" ;;
esac
# Operation states are not asserted: the controller ruled them intent
# paperwork, with both legs verified on disk (execution-ledger.md:1380, commit
# 3b0d45a3).  What is asserted is that each leg is present and well-shaped.
assert "both legs present and non-empty (raw/muse.md / raw/opus.md)" "yes yes" \
  "$([ -s "$muse" ] && echo yes || echo no) $([ -s "$opus" ] && echo yes || echo no)"
oshape="$("$root/scripts/check-answer-shape.sh" "$opus" bundle 2>&1 || true)"
assert "check-answer-shape.sh raw/opus.md bundle" "OK: validation passed" "$oshape"
assert "manifest operations.opus.raw_sha256 equals raw/opus.md's sha256" "$(sha "$opus")" \
  "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["operations"]["opus"]["raw_sha256"])' "$manifest")"
shape="$("$root/scripts/check-answer-shape.sh" "$muse" bundle 2>&1 || true)"
assert "check-answer-shape.sh raw/muse.md bundle" "OK: validation passed" "$shape"
assert "raw/muse.md #### members" "2" "$($GREP -c '^#### ' "$muse")"
assert "raw/opus.md #### members" "4" "$($GREP -c '^#### ' "$opus")"

############################################################
printf -- '\n--- C. the Muse report, at every line revision 4 cites\n'
############################################################
at_line "engine and retrieval date" "$muse" 3 "Engine: muse (Meta). Retrieval date for all live figures: 2026-09-25."
at_line "problemdetails all-time figure" "$muse" 13 "48,464 all-time"
at_line "LOW question: negative result" "$muse" 19 \
  "No published Rust template found that names a \"one envelope for every non-2xx response\" policy verbatim"
at_line "no BASELINE-REVIEW" "$muse" 25 "No BASELINE-REVIEW finding"
at_line "404/405 via fallback; rejections reshaped" "$muse" 27 "framework 404/405 routed through the same envelope"
at_line "totality claimed at compile time" "$muse" 29 "adding a domain variant without a mapping fails to compile"
at_line "nothing executed" "$muse" 37 "Proposed, not executed (no commands run in this research pass)."
at_line "recommendation: one envelope" "$muse" 41 "adopt the single RFC 9457 \`application/problem+json\` envelope for every non-2xx response"
at_line "dominant choice http-api-problem" "$muse" 57 "\`http-api-problem\` v0.60.0 (created 2025-01-06"
at_line "problemdetails ranked runner-up" "$muse" 61 "Kept as ranked runner-up."
at_line "no candidate fails a gate" "$muse" 65 "None of the envelope-crate candidates fails a fitness gate."
at_line "http-api-problem declares no rust-version" "$muse" 73 "MSRV: crate declares no rust-version (None)"
at_line "member recommendation" "$muse" 77 "Use \`http-api-problem\` v0.60.0 as the envelope type"
at_line "runner-up named" "$muse" 81 "\`problemdetails\` v0.7.0"
at_line "no CONFLICT (envelope member)" "$muse" 89 "No CONFLICT."
at_line "exhaustive match, no wildcard arm" "$muse" 124 "exhaustive \`match\` over variants (no wildcard arm)"
at_line "trait impl on R67's error type" "$muse" 124 "\`impl HttpStatus for R67Error\` once R67 resolves"
at_line "trait is web-local" "$muse" 128 "template-owned in \`web::problems\`"
at_line "derive and runtime map excluded" "$muse" 136 "Runtime \`HashMap<TypeId, StatusCode>\` (literal ERROR_STATUS port): excluded by fit"
at_line "trait impl for R67 type" "$muse" 148 "\`impl HttpStatus for <R67 type>\`"
at_line "R67 treated as undecided (member)" "$muse" 160 "(R67 undecided;"
at_line "assumes placeholder for R67" "$muse" 187 "assumes error-taxonomy-exit-codes = (R67 undecided;"
at_line "assumes placeholder for R69" "$muse" 188 "assumes web-framework-stack = (R69 undecided;"
at_line "envelope field list for R71" "$muse" 199 "(\`type\`, \`title\`, \`status\`, \`detail\`, \`instance\`)"
at_line "planned negative check expects a compile error" "$muse" 209 "expected: compile error from the non-exhaustive match"
at_line "gap 5: nothing executed" "$muse" 218 "(5) no executed commands in this pass"

############################################################
printf -- '\n--- D. the evidence that settles each disagreement\n'
############################################################
at_line "gate 2 wording (D1)" "$prompt" 62 \
  "2. crate and dependency-tree MSRV within \`stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI\`;"
at_line "registry check: zero rust_version declarations (D1)" "$here/registry.log" 24 \
  "PASS  http-api-problem: versions declaring rust_version (gate 2 exclusion) == 0"
at_line "same-crate _ arm is unreachable (D2)" "$here/probe.log" 46 "PASS  same-crate match: the _ arm draws 'unreachable pattern'"
at_line "same-crate: no value can reach it (D2)" "$here/probe.log" 47 "PASS  same-crate match: compiler says no value can reach it"
at_line "cross-crate _ arm draws nothing (D2)" "$here/probe.log" 48 "PASS  cross-crate match: the same _ arm is reachable and draws no warning"
at_line "prompt calls R67 undecided (D2)" "$prompt" 34 "(not yet decided)"
assert "prerequisites.json pins R67's published decision (D2)" \
  "16947ab16f8a7bbfe8f911f7d3450b94ec1b4c0e2e6ca79175e1b0b90e649497" \
  "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["R67"]["decision"])' "$run/inputs/prerequisites.json")"
assert "R67 topic DECISION.md sha256 (D2)" \
  "16947ab16f8a7bbfe8f911f7d3450b94ec1b4c0e2e6ca79175e1b0b90e649497" "$(sha "$r67")"
at_line "R67: a different crate needs a _ arm (D2)" "$r67" 150 "crate — R70's web crate — cannot match exhaustively and needs a \`_ =>\` arm"
at_line "R67 prescribes the ALL coverage test (D2)" "$r67" 151 "R70's status table is coverage-tested by"
at_line "R67 Disagreement 7, inside the cited :653-662 (D2)" "$r67" 654 "**Disagreement 7 — catalog exhaustiveness versus semver.**"
at_line "R67 silent-refactor sentence is on the A4 row (EF-1)" "$r67" 136 "silent refactor"
if sed -n '135p' "$r67" | $GREP -qF "silent refactor"; then bad "R67 :135 carries the quote after all"
else ok "R67 :135 does not carry the silent-refactor sentence (EF-1)"; fi
assert "R02 revision 2 snapshot sha256 (D3)" \
  "9e8f8e8c11ffb9b383819b2de1b05eab71a32e3af358b75ea8475d48f3c9707f" "$(sha "$r02")"
at_line "R02: web depends on core only (D3)" "$r02" 29 "Depends on \`core\` only"
at_line "ProblemSource is a web-local trait (D3)" "$here/probe-r2.sh" 349 "pub trait ProblemSource {"
at_line "ProblemSource implemented in the web crate (D3)" "$here/probe-r2.sh" 359 "impl ProblemSource for DomainError {"

############################################################
printf -- '\n--- E. the counts the audits corrected\n'
############################################################
nums="$($GREP -oE 'fn r[0-9]+_' "$here/probe-r2.sh" | $GREP -oE '[0-9]+' | sort -n | tr '\n' ' ')"
printf 'NOTE  probe-r2.sh criterion numbers: %s\n' "$nums"
assert "distinct criteria R1..R24 in probe-r2.sh" "24" "$(printf '%s' "$nums" | wc -w | tr -d ' ')"
carried=0; for n in 1 2 3 7 8 9 10 12 13 14 15 16 17; do
  $GREP -qE "fn r${n}_" "$here/probe-r2.sh" && carried=$((carried+1)); done
assert "carried criteria present (R1-R3, R7-R10, R12-R17) (JF-1 1)" "13" "$carried"
new=0; for n in 4 5 6 11 18 19 20 21 22 23 24; do
  $GREP -qE "fn r${n}_" "$here/probe-r2.sh" && new=$((new+1)); done
assert "new criteria present (R4-R6, R11, R18-R24) (JF-1 1)" "11" "$new"
bullets="$(awk '/^\*\*What these checks do not prove/{f=1;next} /^## Engines/{f=0} f && /^- \*\*/{c++} END{print c+0}' "$dec")"
assert "bullets under 'What these checks do not prove' (JF-1 2)" "9" "$bullets"
r1b="$(awk '/^Revision 1.s bodies/{f=1} f && /^```$/{n++; if(n==2){exit}} f && n==1 && /^\{/{c++} END{print c+0}' "$dec")"
r2b="$(awk '/^Revision 2.s bodies/{f=1} f && /^```$/{n++; if(n==2){exit}} f && n==1 && /^\{/{c++} END{print c+0}' "$dec")"
assert "revision-1 bodies quoted (JF-1 4, EF-2)" "2" "$r1b"
assert "revision-2 bodies quoted (JF-1 4, EF-2)" "6" "$r2b"
# Table rows (the revision-4 note quotes the repaired text) are excluded.
prose() { $GREP -v '^|' "$dec"; }
assert "stale 'The four bodies' lead-in is gone outside the repair table (EF-2)" "0" "$(prose | $GREP -c 'The four bodies' || true)"
assert "rest-r2.sh makes no OV-05 assertion (JF-1 5)" "0" "$($GREP -c 'OV-05' "$here/rest-r2.sh" || true)"
at_line "rest-r2.sh asserts OV-06 free (JF-1 5)" "$here/rest-r2.sh" 260 "OV-06, allocated to this item, is claimed by no decision outside it"
assert "R80 published copy is revision 6" "1" "$(sed -n 1p "$r80" | $GREP -c -- '— decision (revision 6)' || true)"
at_line "R80 revision 6 claims OV-05 in its override heading (JF-1 5, EA-1)" "$r80" 790 "#### \`OVERRIDE (OV-05)\`"
assert "decision prose no longer says 'OV-05 and OV-06' (JF-1 5)" "0" "$(prose | $GREP -c 'OV-05 and OV-06' || true)"
at_line "decision header is revision 5" "$dec" 1 "— decision (revision 5)"

############################################################
printf -- '\n--- F. the /readyz diagnostic carrier (revision 5)\n'
############################################################
at_line "R80 rev 6 defers the carrier: requirement" "$r80" 860 "diagnostic report must be reachable from the 503 response. Three ways satisfy it"
at_line "R80 rev 6 defers the carrier: way (a)" "$r80" 861 "a second extension member named \`diagnostics\`"
at_line "R80 rev 6 defers the carrier: owner" "$r80" 863 "R70 owns the choice."
at_line "py carries the report as a diagnostics extension" "$r80" 853 'extensions={"diagnostics": report.model_dump(mode="json")})'
at_line "R80's executed T4 carries the report under diagnostics" "$r80" 1155 "body still carrying the report under \`diagnostics\`"
at_line "R80 builds the report's detail redacted at its source" "$r80" 1007 "built redacted at its source"
at_line "way (c) is barred: R3 forbids a detail-public 5xx" "$here/probe-r2.sh" 914 "R3 — R5.17/R8.12: no 5xx code is detail-public."
assert "stale 'R80's to justify' is gone outside the repair table" "0" "$(prose | $GREP -c "R80's to justify" || true)"
assert "stale 'Being researched in parallel' is gone" "0" "$(prose | $GREP -ic 'Being researched in parallel' || true)"
assert "stale 'R80 justifying a fifth extension member' trigger is gone outside the repair table" "0" \
  "$(prose | $GREP -c 'R80 justifying a fifth extension member' || true)"

printf '\n=== summary ===\nPASS %d  FAIL %d  SKIP %d  TOTAL %d\n' \
  "$PASS" "$FAIL" "$SKIP" "$((PASS+FAIL+SKIP))"
[ "$FAIL" -eq 0 ]
