#!/usr/bin/env bash
# shellcheck disable=SC2016
#   File-wide: the asserted strings are Markdown literals and contain `backticks`.
# R77 revision 4 — the self-check the decision cites.
#
#   H  identities: the revision-3 snapshot, both raw reports, the prompt and its
#      frozen input copy (read only; nothing here writes outside a mktemp dir)
#   D  the decision's shape: exactly the four H2 sections, in order
#   R  each revision-4 repair, one block per audit finding: the repaired text is
#      present and the text the auditors quoted is gone. The finding table at the
#      top of the file quotes the old text on purpose, so absence is tested on the
#      body with those table rows removed, and two phrases that the body quotes
#      once as "revision 3 said …" are asserted to occur exactly once, in that
#      quotation
#   P  every carried evidence file (revisions 1-3) and review/evidence/snapshots/
#      pinned by sha256
#   M  the Muse report cites no rule of the REST standard: REST, R8.1, R9.1 and
#      R11.2 each occur 0 times in raw/muse.md; the same search finds each in this
#      decision (positive control); and the raw lines the decision cites say what
#      it says they say
#   I  the policy inputs that were uncommitted when revision 4 was written: the
#      engine line of both prompts, both EXECUTION.json entries, the RUNBOOK
#      paragraph, ledger lines 1173 and 1215, the manifest's migration event, and
#      the Muse operation still recorded as submitting (the stated gap)
#   C  coupled items at the revisions read: R74 and R58 (untracked working-tree
#      files) pinned by sha256; R80 revision 3 read from its landed commit; each
#      cited line asserted. R74 and R80 are being revised in parallel, so a later
#      pin FAIL means "re-verify", not "the decision was wrong when written".
#      Also the published-decision lines the Engines table cites (R53, R54, R57,
#      owner-decisions, the prompt's rubric line)
#   L  the totals line of every revision-4 log, and the figures the decision
#      quotes from them
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
review=$(cd -- "$here/.." && pwd)
run=$(cd -- "$review/.." && pwd)
root=$(cd -- "$run/../../../.." && pwd)
dec="$review/DECISION.md"
muse="$run/raw/muse.md"

pass=0; fail=0; skip=0
ok() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
no() { fail=$((fail+1)); printf 'FAIL %s\n' "$1"; }
sk() { skip=$((skip+1)); printf 'SKIP %s\n' "$1"; }
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1 ($3)"; else
    no "$1"; printf '     expected: %s\n     actual:   %s\n' "$2" "$3"; fi
}
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
pin() { # label file expected-sha
  if [ ! -f "$2" ]; then no "$1 — missing: $2"; return; fi
  assert_eq "$1" "$3" "$(sha "$2")"
}
S=$(mktemp -d "${TMPDIR:-/tmp}/r77-r4c.XXXXXX")
trap 'rm -rf "$S"' EXIT
# flat <file>: the file on one line, runs of whitespace squeezed, so a phrase
# wrapped across lines is still one phrase
flat() { tr -s '\n\t ' '   ' < "$1"; }
count() { # count <flat-file> <literal>
  /usr/bin/grep -oF -- "$2" "$1" | /usr/bin/grep -c . || true
}
has()    { if [ "$(count "$2" "$3")" -ge 1 ]; then ok "$1"; else no "$1"; printf '     missing: %s\n' "$3"; fi; }
hasnt()  { local n; n=$(count "$2" "$3"); if [ "$n" -eq 0 ]; then ok "$1"; else no "$1"; printf '     still present %s time(s): %s\n' "$n" "$3"; fi; }
line_has() { # label file lineno literal
  if sed -n "${3}p" "$2" | /usr/bin/grep -qF -- "$4"; then ok "$1 (line $3)"; else
    no "$1 (line $3)"; printf '     line %s of %s does not contain: %s\n' "$3" "$2" "$4"; fi
}

printf '# R77 revision 4 self-check — %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '# decision sha256 at this run: %s\n' "$(sha "$dec")"

flat "$dec" > "$S/all"
# the body: the decision without the revision-4 finding-table rows
/usr/bin/grep -vE '^\| (fable|claude) ' "$dec" > "$S/body.md"
flat "$S/body.md" > "$S/body"

echo
echo '## H — identities'
pin "revision-3 snapshot is untouched" "$review/R77-r3-snapshot.md" \
  5985ee47d5c714fdc317d5b8a8c58aff9c01b3f552834de8ac0b9c5282bb92fd
pin "raw/muse.md is the collected Muse report" "$muse" \
  a2e9a208f6e8bb269ac396ea1f1bff605cb549c403ce676539cbb61dc2123426
assert_eq "raw/muse.md line count" 204 "$(wc -l < "$muse" | tr -d ' ')"
pin "raw/opus.md" "$run/raw/opus.md" \
  a81c6372fe084f805fa4058c68e60af7064b354de69a2a0da0360b9c2a0ac533
pin "the registered Opus copy" \
  "$run/raw/opus-a81c6372fe084f805fa4058c68e60af7064b354de69a2a0da0360b9c2a0ac533.md" \
  a81c6372fe084f805fa4058c68e60af7064b354de69a2a0da0360b9c2a0ac533
prompt="$root/research/topics/77-web-env-settings/prompts/web-env-settings.prompt.md"
pin "the live prompt" "$prompt" 48610c1abe76d1c54c3ca0f7584f6c656e2a6471fc24b7bd6ed8f801182172c4
pin "inputs/prompt.md is byte-identical to the live prompt" "$run/inputs/prompt.md" \
  48610c1abe76d1c54c3ca0f7584f6c656e2a6471fc24b7bd6ed8f801182172c4

echo
echo '## D — decision shape'
assert_eq "H2 sections, in order" "## Decision|## Parameters|## Empirical check|## Engines" \
  "$(/usr/bin/grep -E '^## ' "$dec" | paste -sd '|' -)"
line_has "H1 names revision 4" "$dec" 1 "— decision (revision 4)"
has "one Principles and implementation subsection" "$S/all" "### Principles and implementation"
has "a re-verify line" "$S/all" "re-verify: if the controller reallocates"
hasnt "no unfilled placeholder" "$S/all" "R4C_PASS"
hasnt "no unfilled placeholder" "$S/all" "R3_TOTALS"

echo
echo '## R — revision-4 repairs, per finding'
echo '### fable F1 — both engines, the migration, the disagreements'
has  "F1 lists the Muse report"               "$S/body" '- muse `raw/muse.md` — Muse (Meta), model `muse-spark`'
has  "F1 gives the Muse sha256 in full"       "$S/body" a2e9a208f6e8bb269ac396ea1f1bff605cb549c403ce676539cbb61dc2123426
has  "F1 records the migration event"         "$S/body" '"from": "codex"`, `"to": "muse"`'
has  "F1 has the disagreements subsection"    "$S/body" "#### Disagreements between the engines, and what settled each"
for row in "| 1 | Recommendation |" "| 2 | Fitness gate 2 |" "| 3 | Maintenance labels" \
           "| 4 | Error shape |" "| 5 | Placement |" "| 6 | Figures |" "| 7 | Loader shape |" \
           "| 8 | Prefix derivation |" "| 9 | Tests |" "| 10 | Gate 1 |"; do
  has "F1 adjudicates ${row}" "$S/body" "$row"
done
hasnt "F1 the 'codex — absent' bullet is gone"          "$S/body" 'codex — **absent.**'
hasnt "F1 the old required_engines quotation is gone"   "$S/body" 'required_engines: [codex, opus]'
hasnt "F1 'synthesized from a single engine' is gone"   "$S/body" "synthesized from a single engine"
hasnt "F1 'no inter-engine disagreements' is gone"      "$S/body" "no inter-engine disagreements"
hasnt "F1 'neither engine had' is gone"                 "$S/body" "neither engine had"
has  "F1 the REST-standard sentence is restated"        "$S/body" "No engine report cites the org REST API Design Standard v2.0.0"

echo '### fable F2 — no floor on R74'"'"'s membership'
assert_eq "F2 'at least four members' occurs once, as a quotation of revision 3" 1 \
  "$(count "$S/body" 'at least four members')"
has  "F2 that one occurrence is the quotation"  "$S/body" 'Revision 3 said the family has "at least four members". That floor constrained a choice R74 owns and is withdrawn.'
hasnt "F2 'is still twelve' is gone"            "$S/body" "is still twelve"
has  "F2 no floor is set"                       "$S/body" "this item sets no floor"
has  "F2 the field count is restated"           "$S/body" "eleven py-derived scalar fields, plus one field per rate-limit member R74 publishes, plus the readiness pause"
has  "F2 AC14 points at R74's published membership" "$S/body" "The member list is checked against R74's *published* membership"
has  "F2 the re-verify line points at R74's publication" "$S/body" 'when R74 publishes the membership and defaults of the `RSLBP_WEB_RATE_LIMIT_*` family'

echo '### fable F3 — the readiness pause has an owner'
has  "F3 subsection"                            "$S/body" "#### The readiness-propagation pause — R80's requirement, accepted"
has  "F3 the variable is named"                 "$S/body" 'Name:** `RSLBP_WEB_READINESS_PAUSE_SECONDS`'
has  "F3 default 0"                             "$S/body" '**Default: `0`.**'
has  "F3 the budget rule"                       "$S/body" 'the pause must be strictly less than `RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS`'
has  "F3 R80 cited at 314–318"                  "$S/body" "says at lines 314–318"
has  "F3 R80 cited at 750–752"                  "$S/body" "At lines 750–752"
assert_eq "F3 'R80 decides the split' occurs once, as a quotation of revision 3" 1 \
  "$(count "$S/body" 'R80 decides the split')"
has  "F3 that one occurrence is the quotation"  "$S/body" 'Revision 3 of this decision instead quoted R80'"'"'s raw report ("R77 owns the window'"'"'s value…") and said "R80 decides the split".'
hasnt "F3 the old re-verify clause is gone"     "$S/body" "when R80 publishes and fixes a readiness-propagation pause"
has  "F3 AC15"                                   "$S/body" '| AC15 | With defaults, the readiness pause is 0 s'

echo '### fable F4 — the start of main'
has  "F4 handshake stated"                      "$S/body" '**The start of `main`, reconciled with R58.**'
has  "F4 telemetry reads no variable"           "$S/body" 'receives `settings.log_level` and `settings.log_format` as arguments and reads no environment variable'
has  "F4 AC16"                                   "$S/body" '| AC16 | In the serve binary, `WebSettings::from_env()` runs before `telemetry::init`'
has  "F4 re-verify names AC16"                   "$S/body" "as AC16 requests"

echo '### fable F5 — stale self-descriptions'
has  "F5 revision 2 labelled by commit"         "$S/body" '**Revision 2** (2026-09-18, commit `d36492b`) — the W2-REST conformance pass above'
hasnt "F5 the '(this file)' label on revision 2 is gone" "$S/body" "**Revision 2** (2026-09-18, this file)"
assert_eq "F5 only revision 5 is called 'this file'" 1 "$(count "$S/body" "this file)")"
has  "F5 the one 'this file' label is revision 5's" "$S/body" "**Revision 5** (2026-09-27, this file)"
hasnt "F5 R80 is not called published"          "$S/body" "R80 has since published"
has  "F5 R80 described as landed"               "$S/body" 'R80'"'"'s revision 3 has since landed (commit `53b13f45`; R80 is not published)'
has  "F5 the rest-conformance bullet is qualified" "$S/body" '(this group-E check was vacuous; superseded by `ov-allocation-r3.sh` group B)'

echo '### fable F6 and claude 4 — config 0.15.26'
has  "F6 gate-2 cell records both versions"     "$S/body" '**1.85.0** at 0.15.25; **1.88.0** at 0.15.26'
has  "F6 re-verify says 1.88.0"                  "$S/body" 'neither `config` 0.15.26'"'"'s 1.88.0'
hasnt "F6 the old 1.85.0 trigger text is gone"   "$S/body" 'neither `config`'"'"'s 1.85.0'
has  "F6 a new 0.15.x release is a trigger"      "$S/body" 'when `config` publishes a new 0.15.x release'
has  "F6 0.15.26 measured row"                   "$S/body" '| `config` 0.15.26, `default-features = false` (revision 4, rustc 1.98.1) | 11 (+3) | +83,200 B |'

echo '### claude 1 — P6 superseded'
has  "c1 probes-r4.sh unsets the variable"       "$here/probes-r4.sh" "unset CARGO_TARGET_DIR"
has  "c1 probes-r4.sh passes an explicit target dir" "$here/probes-r4.sh" "--target-dir"
has  "c1 probes-r4.sh has the negative control"  "$here/probes-r4.sh" "## N — negative control"
has  "c1 the decision cites the rerun log"       "$S/body" "probes-rerun-r4.log"
has  "c1 the P6 caveat is in Empirical check"    "$S/body" 'Revision 1'"'"'s P6 sizes are therefore valid only with `CARGO_TARGET_DIR` unset'

echo '### claude 2 — declarations-only census'
has  "c2 ov-allocation-r4.sh searches DECISION.md only" "$here/ov-allocation-r4.sh" "-name DECISION.md"
has  "c2 ov-allocation-r4.sh matches headings only"     "$here/ov-allocation-r4.sh" '^#+ .*OVERRIDE'
has  "c2 the OV section cites the r4 log"               "$S/body" '(`review/evidence/ov-allocation-r4.log`)'

echo '### claude 3 — the reproducibility rule'
hasnt "c3 'Exactly three kinds of line vary' is gone" "$S/body" "Exactly three kinds of line vary"
hasnt "c3 'Nothing else differs.' is gone"             "$S/body" "Nothing else differs."
has  "c3 the rule lists tree-census counts"            "$S/body" "5. tree-census counts:"
has  "c3 the rule lists toolchain lines"               "$S/body" "3. toolchain version lines"
has  "c3 the rule lists two-way rolling counters"      "$S/body" "which may move in either direction"
rc_row=$(/usr/bin/grep -F '| `review/evidence/rest-conformance-r2.sh` | 2,' "$dec" || true)
if printf '%s' "$rc_row" | /usr/bin/grep -qF 'exit **1** at 90/1/0'; then
  ok "c3 the rest-conformance-r2.sh table cell says exit 1 at 90/1/0"
else no "c3 the rest-conformance-r2.sh table cell"; printf '     row: %s\n' "$rc_row"; fi

echo '### claude 5 — Figment pushed_at'
has  "c5 the new pushed_at is recorded"          "$S/body" "**2026-09-27T00:54:08Z**"
has  "c5 the commits snapshot is cited"          "$S/body" "gh-commits-SergioBenitez__Figment-since-2024-09-14.json"
assert_eq "c5 zero default-branch commits since 2024-09-14" 0 \
  "$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))))' \
     "$here/snapshots-r4/gh-commits-SergioBenitez__Figment-since-2024-09-14.json")"
has  "c5 a new figment release is a trigger"     "$S/body" 'when `envy` or `figment` publishes a new release'

echo
echo '## P — carried evidence, byte-identical'
while read -r want f; do
  pin "carried $f" "$here/$f" "$want"
done <<'EOF'
d70b89cdd15898078182f696540bd992be7d17c9ba7262441bc4395d29dd25a6 figures.sh
493ba961663fbf19d28432610d38ff168558239e074026d02ced7bf28a58f086 figures.log
a63bb281280bc3d530f7aacf24e3825994f94c2f980db4df7c0041cb9fe05f34 sources.sh
455841ce2b0d76cf94d46a5563d3a50a9144e454bf4f5218235ee32c1b3f3923 sources.log
4af088a3945a2ba47ab7f60ef71f0714fd4075b9f01cfe81606edd45d1b62747 probes.sh
fe848ea72828e4220f7030caca562c48517f16207565d9b05c6edf2a58672ae7 probes.log
9c26e9ea96b101e88398b60baf3b709bc3b3e0aae28bfd8d9b77c4442e51c642 fetch-snapshots.sh
8eae6a9c2af53ec40384968efed1ed40b16e5d7c7523240336fd7e25c84f5226 fetch-snapshots.log
d6b4d0fee8b741eb8850d00c38810ddf832d0c161f6f0d0cc4530e36dd96028a rerun-diff.log
b341895ab9f790914d3475f70a34b4aa7aae0c07eaea39100a3f3b7e7ad15d1a archive-rerun.log
1db52d4d926f026987bc3970c6301fcb01ac1aeeb966ba3d4e7b2e08133beafa rest-conformance-r2.sh
a7c3370352af8b148c023161078c45026fae921531485f74d1c56025c8b25739 rest-conformance-r2.log
1ea5e4b24aba3ff7624ea1727de78558d5d1b5c9c4be7aae08906d559c832aee rerun-diff-r2.log
8715c9b5bf715c1c242bea7d30a5e4443b30f6ab3079d81ac62772d0d20d5b92 archive-rerun-r2.log
0a5f166384053afbfd53d828ce2f4d5a64112692af7d1e057ec55e5d311dcc69 ov-allocation-r3.sh
afda05844debadfc6b96e80aa34a9ebde0f6f7ae1e37e1338e6bb3612aef49b1 ov-allocation-r3.log
937a39d1ff8cf01495c267e0a73eff21724618d7c274e2e82cbd353e6271b1b1 rerun-diff-r3.log
9b90b7314d5a1f3bc6bd0a5820d1ecd675913ead3449c512e391201a5ab66e03 archive-rerun-r3.log
EOF
assert_eq "snapshots/ holds 37 files" 37 "$(find "$here/snapshots" -type f | /usr/bin/grep -c .)"
assert_eq "snapshots/ content (sha256 over the sorted per-file sha256 list)" \
  7f2eeb92765aab81fcbf640e85eb4a4a90ece92f83b4533da5d40c03dbcebbb3 \
  "$(cd "$here/snapshots" && find . -type f | LC_ALL=C sort | xargs shasum -a 256 | shasum -a 256 | cut -d' ' -f1)"

echo
echo '## M — the Muse report and the REST standard'
flat "$muse" > "$S/muse"
for s in REST R8.1 R9.1 R11.2; do
  assert_eq "raw/muse.md occurrences of $s" 0 "$(count "$S/muse" "$s")"
  n=$(count "$S/all" "$s")
  if [ "$n" -ge 1 ]; then ok "positive control: the same search finds $s in this decision ($n)"
  else no "positive control: $s not found in this decision"; fi
done
line_has "muse cites the executed config Display string"  "$muse" 53  'expected an integer for key'
line_has "muse's app-name constant"                      "$muse" 65  'pub const APP_NAME: &str = "rs_launch_blueprint";'
line_has "muse's runtime prefix derivation"              "$muse" 68  'format!("{}_WEB", APP_NAME.to_uppercase())'
line_has "muse's loader sets the separator"              "$muse" 71  '.separator("_")'
line_has "muse's trailing-underscore observation"        "$muse" 77  'takes the prefix *without* the trailing separator'
line_has "muse's reuse premium is conditional on R53"    "$muse" 112 'if R53 also selects `config`'
line_has "muse places settings in the library crate"     "$muse" 113 'live in the library crate'
line_has "muse rates figment stable-quiet on 1/10, 185 days" "$muse" 88 'responsiveness 1/10 answered, 185 days'
line_has "muse's envy window was partly unretrievable"   "$muse" 89  'responsiveness window partially unretrievable'
line_has "muse's lenient gate-2 reading"                 "$muse" 94  'construction age plus current-toolchain evidence'
line_has "muse excludes nothing by gate"                 "$muse" 102 'None. All three shortlisted candidates passed every applicable fitness gate'
line_has "muse's recommendation"                         "$muse" 121 'config = { version = "0.15", default-features = false }'
line_has "muse verified 0.15.26 / 1.88.0"                "$muse" 125 'verified against 0.15.26, released 2026-09-21; `rust-version 1.88.0`'
line_has "muse's runner-up"                              "$muse" 129 '`envy` 0.4 (verified 0.4.2'

echo
echo '## I — policy inputs (uncommitted when revision 4 was written)'
line_has "live prompt engine line"     "$prompt" 24 "- engines: muse, opus"
line_has "frozen prompt engine line"   "$run/inputs/prompt.md" 24 "- engines: muse, opus"
line_has "the prompt's at-risk rubric" "$prompt" 61 '`at-risk` needs a concrete signal'
for f in "$root/research/EXECUTION.json" "$run/inputs/EXECUTION.json"; do
  rel=${f#"$root"/}
  assert_eq "$rel engine_overrides.R77" "muse,opus" \
    "$(python3 -c 'import json,sys; print(",".join(json.load(open(sys.argv[1]))["engine_overrides"]["R77"]))' "$f")"
  assert_eq "$rel items.R77.engines" "muse,opus" \
    "$(python3 -c 'import json,sys; print(",".join(json.load(open(sys.argv[1]))["items"]["R77"]["engines"]))' "$f")"
done
rb="$root/research/RUNBOOK.md"
if sed -n '69,75p' "$rb" | tr -s '\n ' '  ' | /usr/bin/grep -qF 'R76, R77, R79, R80'; then
  ok "RUNBOOK lines 69-75 list R77 in the Muse substitution set"
else no "RUNBOOK lines 69-75 list R77 in the Muse substitution set"; fi
if sed -n '69,75p' "$rb" | /usr/bin/grep -qF 'Q17.A (2026-09-27)'; then
  ok "RUNBOOK lines 69-75 name Q17.A"
else no "RUNBOOK lines 69-75 name Q17.A"; fi
ledger="$root/docs/planning/p02/execution-ledger.md"
line_has "ledger records the Muse collection" "$ledger" 1173 \
  "R77 MUSE LEG COLLECTED, 2026-09-25: sha a2e9a208 (204 lines, crate OK)"
line_has "ledger records Q17.A"               "$ledger" 1215 "Q17.A IMPLEMENTED (2026-09-27)"
mf="$run/manifest.json"
assert_eq "manifest required_engines" "muse,opus" \
  "$(python3 -c 'import json,sys; print(",".join(json.load(open(sys.argv[1]))["required_engines"]))' "$mf")"
assert_eq "manifest migration event" "codex>muse|codex,opus|muse bulk substitution (owner decision Q5.A 2026-09-21)" \
  "$(python3 -c 'import json,sys
m=json.load(open(sys.argv[1]))
e=[x["migration"] for x in m.get("events",[]) if "migration" in x][0]
print("%s>%s|%s|%s" % (e["from"], e["to"], ",".join(e["previous_required_engines"]), e["reason"]))' "$mf")"
assert_eq "operations/muse.json (the stated gap: not yet registered)" "submitting|muse-spark" \
  "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["state"]+"|"+d["model"])' "$run/operations/muse.json")"

echo
echo '## C — coupled and cited decisions, at the revisions read'
r74="$root/research/runs/R74/2026-09-18T215916Z-14066395aaea/review/DECISION.md"
pin "R74 revision 2 (working tree) as read" "$r74" \
  68e19cf3d99567dce2b6864ac968d652f1ae93d116c5f43e187fac82fbb6e246
line_has "R74 member 1" "$r74" 511 '`RSLBP_WEB_RATE_LIMIT_PER_IP`'
line_has "R74 member 2" "$r74" 512 '`RSLBP_WEB_RATE_LIMIT_PER_IP_BURST`'
line_has "R74 member 3" "$r74" 513 '`RSLBP_WEB_RATE_LIMIT_MAX_ENTRIES`'
line_has "R74 cites OV-17"       "$r74" 515 '`OVERRIDE (OV-17)` ships one dimension'
line_has "R74 hands R77 three fields" "$r74" 560 'Three fields for the `RSLBP_WEB_RATE_LIMIT_*` family'
r58="$root/research/runs/R58/2026-09-18T215915Z-184041b91674/review/DECISION.md"
pin "R58 revision 1 (working tree) as read" "$r58" \
  d06a6961d5b4f583182ea3d90de3b6222c3a9bbf955144e6c896339657ba5ed9
line_has "R58 claims the serve binary's first statement" "$r58" 1405 \
  'first statement of `main`: `telemetry::init(Profile::Service { .. })` with level and format from `RSLBP_WEB_LOG_LEVEL` and `RSLBP_WEB_LOG_FORMAT`'
r80_rel="research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md"
if git -C "$root" cat-file -e "53b13f45:$r80_rel" 2>/dev/null; then
  git -C "$root" show "53b13f45:$r80_rel" > "$S/r80.md"
  pin "R80 revision 3 at its landed commit 53b13f45" "$S/r80.md" \
    184d2b1714f8eb26a7b4df43b6020feb280662e85fcf3668a7fb0938d0d230c8
  line_has "R80 revision 3 title" "$S/r80.md" 1 "decision (revision 3)"
  line_has "R80: inert at zero"   "$S/r80.md" 313 "The mechanism is inert"
  line_has "R80: no owner today"  "$S/r80.md" 314 "no item owns its value today"
  line_has "R80: a requirement, not a fact" "$S/r80.md" 318 "hands R77 a requirement rather than citing a fact"
  line_has "R80: hand-off heading" "$S/r80.md" 750 '**R77 (`web-env-settings`) — the readiness-propagation pause.**'
  line_has "R80: if R77 declines"  "$S/r80.md" 752 "hands R77 the requirement; if R77 declines it, the pause needs an owner."
  line_has "R80 withdraws its raw sentence" "$S/r80.md" 1197 '*"R77 owns the window'"'"'s value"*'
  line_has "R80 declares OV-05"   "$S/r80.md" "$(/usr/bin/grep -nE '^#+ .*OVERRIDE \(OV-05\)' "$S/r80.md" | head -1 | cut -d: -f1)" "OVERRIDE (OV-05)"
  if cmp -s "$S/r80.md" "$root/$r80_rel"; then
    printf 'DRIFT R80 live file is still revision 3 at 53b13f45\n'
  else
    printf 'DRIFT R80 live file has moved past 53b13f45 (a re-verify trigger)\n'
  fi
else
  sk "R80 group — commit 53b13f45 is not in this repository (for example, a git archive)"
fi
line_has "R53 recommends serde and no validation crate" \
  "$root/research/topics/53-config-schema-validation/DECISION.md" 67 '**`serde` with the `derive` feature'
line_has "R53: no dedicated validation crate" \
  "$root/research/topics/53-config-schema-validation/DECISION.md" 68 'and no dedicated validation'
line_has "R53: no dependency added" \
  "$root/research/topics/53-config-schema-validation/DECISION.md" 81 '**No dependency is added by this item.**'
line_has "R54 rejects a layer-merging engine" \
  "$root/research/runs/R54/2026-09-17T033527Z-8dfef31d60fc/review/DECISION.md" 303 \
  '`config` 0.15.25 or `figment` 0.10.19 takes a source list'
line_has "R57's TOOL_NAME" "$root/research/topics/57-xdg-directory-set/DECISION.md" 254 \
  'pub const TOOL_NAME: &str = "rslbp";'
line_has "owner withdrew the lenient gate-2 reading" "$root/docs/planning/p02/owner-decisions.md" 460 \
  "The ruling is withdrawn."

echo
echo '## L — revision-4 logs, and the figures the decision quotes from them'
tot() { /usr/bin/grep -E '^PASS=[0-9]+ FAIL=' "$here/$1" | tail -1; }
assert_eq "drift-r4.log totals"          "PASS=32 FAIL=0 SKIP=0 TOTAL=32" "$(tot drift-r4.log)"
assert_eq "probes-r4.log totals"         "PASS=37 FAIL=0 SKIP=0 TOTAL=37" "$(tot probes-r4.log)"
assert_eq "ov-allocation-r4.log totals"  "PASS=10 FAIL=0 SKIP=0 TOTAL=10" "$(tot ov-allocation-r4.log)"
assert_eq "probes-rerun-r4.log totals"   "PASS=6 FAIL=0 SKIP=0 TOTAL=6"   "$(tot probes-rerun-r4.log)"
assert_eq "probes-rerun-r4.log run 1 (as written)" "  | PASS=31 FAIL=3 SKIP=0 TOTAL=34" \
  "$(/usr/bin/grep -E '^  \| PASS=' "$here/probes-rerun-r4.log" | sed -n 1p)"
assert_eq "probes-rerun-r4.log run 2 (variable removed)" "  | PASS=34 FAIL=0 SKIP=0 TOTAL=34" \
  "$(/usr/bin/grep -E '^  \| PASS=' "$here/probes-rerun-r4.log" | sed -n 2p)"
r3tot=$(tot ov-allocation-r3-rerun-r4.log)
has "the decision states ov-allocation-r3.sh's live-tree totals as logged" "$S/all" \
  "\`ov-allocation-r3.sh\` reports **${r3tot}** in the live tree"
assert_eq "ov-allocation-r3-rerun-r4.log fails exactly the census and the three revision-3 text checks" \
  "FAIL a third item claims OV-04:|FAIL H1 is the date-first revision-3 title|FAIL the revision history names all three revisions|FAIL the substance of revision 2 is declared unmoved" \
  "$(/usr/bin/grep -E '^FAIL ' "$here/ov-allocation-r3-rerun-r4.log" | sed 's/^\(FAIL a third item claims OV-04:\).*/\1/' | paste -sd '|' -)"
has "ov-allocation-r3-rerun-r4.log: group C's 90/1/0 rerun still passes" "$here/ov-allocation-r3-rerun-r4.log" \
  "PASS revision 2's script still runs, now 90/1/0"
assert_eq "fetch-snapshots-r4.log wrote 27 files" 27 \
  "$(/usr/bin/grep -c '^wrote snapshots-r4/' "$here/fetch-snapshots-r4.log")"
assert_eq "snapshots-r4/ holds those 27 files" 27 "$(find "$here/snapshots-r4" -type f | /usr/bin/grep -c .)"
has "probes-r4: config 0.15.26 measured at 11 packages, 369248 B" "$here/probes-r4.log" "confignodefault26         11         369248"
has "probes-r4: the deltas the decision quotes" "$here/probes-r4.log" \
  "envy=16576 confique=16496 config-0.15.25-no-default=83200 figment=99920 config-0.15.25-default=132912 config-0.15.26-no-default=83200"
has "probes-r4: P7.2" "$here/probes-r4.log" "PASS P7.2 Muse's .separator(\"_\") shape silently drops the multi-word field to its default"
has "probes-r4: 3 set, 8 read under Muse's loader" "$here/probes-r4.log" "p7-muse-shape | OK | Multi { port: 9000, graceful_shutdown_seconds: 8 }"
has "probes-r4: P3r4.1 verbatim string" "$here/probes-r4.log" \
  'p3-process | ERR | invalid type: string "eighty", expected an integer for key `port` in the environment'
has "drift-r4: config 0.15.26 / 1.88.0" "$here/drift-r4.log" "PASS S config newest release on 2026-09-27 (0.15.26|2026-09-21|1.88.0)"
has "drift-r4: Figment pushed_at 2026-09-27" "$here/drift-r4.log" "PASS S Figment pushed_at on 2026-09-27 (2026-09-27T00:54:08Z)"
has "drift-r4: Figment zero commits" "$here/drift-r4.log" "PASS S Figment default-branch commits since 2024-09-14 (0)"
has "drift-r4: serde-env open issues 0" "$here/drift-r4.log" "PASS S serde-env open issues on 2026-09-27 (0)"
has "drift-r4: config-rs stars 3214" "$here/drift-r4.log" "PASS S config-rs stars on 2026-09-27 (3214)"
has "ov-allocation-r4: this decision is the only OV-04 declarer" "$here/ov-allocation-r4.log" \
  "PASS exactly one decision declares OV-04, and it is this one"

printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"
[ "$fail" -eq 0 ] || exit 1
