#!/usr/bin/env bash
# R12 evidence (revision 4): run inputs are what the DECISION claims, the
# Muse-for-Codex seat and the Claude empirical-audit seat have recorded
# authorities (Q17.A; empirical_auditor_overrides), every cited check ID
# resolves, and the DECISION shape matches the published contract.
set -euo pipefail
export PATH="/Users/stevemorin/.local/bin:/opt/homebrew/bin:$PATH"

ROOT="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
RUN="$ROOT/research/runs/R12/2026-09-26T190134Z-d0c66b769758"
TOPIC="$ROOT/research/topics/12-aggregate-required-status-check"
EV="$RUN/review/evidence"
DEC="$RUN/review/DECISION.md"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "PASS $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL $1 -- $2"; }
info() { echo "INFO $1"; }

has() { # $1 id $2 file $3 fixed-string
  if grep -qF -- "$3" "$2"; then ok "I-$1"; else bad "I-$1" "$2 lacks: $3"; fi
}
hasre() { # $1 id $2 file $3 regex
  if grep -qE -- "$3" "$2"; then ok "I-$1"; else bad "I-$1" "$2 lacks /$3/"; fi
}

# ---- run inputs ----
if diff -q "$RUN/inputs/prompt.md" "$TOPIC/prompts/aggregate-required-status-check.prompt.md" >/dev/null; then
  ok "I-prompt run prompt is byte-identical to the published prompt"
else bad "I-prompt" "prompt drift"; fi
has "prompt-engines" "$RUN/inputs/prompt.md" '- engines: muse, opus'
if cmp -s "$RUN/inputs/EXECUTION.json" "$ROOT/research/EXECUTION.json"; then
  ok "I-policy run policy snapshot is byte-identical to the live research/EXECUTION.json"
else bad "I-policy" "policy drift"; fi
POLICY_SHA="$(shasum -a 256 "$RUN/inputs/EXECUTION.json" | cut -d' ' -f1)"
has "policy-hash-stated" "$DEC" "$POLICY_SHA"
if python3 - "$ROOT/research/EXECUTION.json" <<'EOF'
import json, sys
e = json.load(open(sys.argv[1]))
ov = e["engine_overrides"]["R12"]; it = e["items"]["R12"]["engines"]
print("engine_overrides.R12:", ov, "items.R12.engines:", it)
assert ov == ["muse", "opus"] and it == ["muse", "opus"]
EOF
then ok "I-override live engine_overrides and items engines for R12 are [muse, opus]"; else bad "I-override" "R12 engines differ"; fi
if python3 - "$ROOT/research/EXECUTION.json" <<'EOF'
import json, sys
e = json.load(open(sys.argv[1]))
eao = e["empirical_auditor_overrides"]["R12"]
print("empirical_auditor_overrides.R12:", eao)
assert eao == "claude"
EOF
then ok "I-auditor-override live empirical_auditor_overrides for R12 is claude"; else bad "I-auditor-override" "R12 empirical seat differs"; fi
if sed -n '98,103p' "$ROOT/research/RUNBOOK.md" | tr '\n' ' ' | grep -qE 'listed in .empirical_auditor_overrides. runs its empirical audit on +the named seat instead'; then
  ok "I-runbook-eao RUNBOOK.md:98-103 carries the empirical_auditor_overrides rule"
else bad "I-runbook-eao" "RUNBOOK.md:98-103 lacks the empirical_auditor_overrides rule"; fi
if sed -n '73,76p' "$ROOT/research/RUNBOOK.md" | tr '\n' ' ' | grep -qE 'Q17\.A \(2026-09-27\).*extends the substitution to the research wave.* R12,'; then
  ok "I-runbook-q17a RUNBOOK.md:73-76 names Q17.A and lists R12"
else bad "I-runbook-q17a" "RUNBOOK.md:73-76 does not carry Q17.A with R12"; fi
if python3 - "$RUN/manifest.json" <<'EOF'
import json, sys
m = json.load(open(sys.argv[1]))
print("manifest required_engines:", m["required_engines"], "input_hashes.prompt:", m["input_hashes"]["prompt"])
assert m["required_engines"] == ["codex", "opus"]
assert m["input_hashes"]["prompt"] == "3da9f7d26af89f1406eb86f608d1add3b0f31e6876a4328998fb16de154dabe8"
EOF
then ok "I-manifest-dispatch manifest still records the pre-amendment dispatch (codex, opus; prompt 3da9f7d2)"; else bad "I-manifest-dispatch" "manifest changed"; fi
if [ "$(shasum -a 256 "$RUN/review/R12-r1-snapshot.md" | cut -d' ' -f1)" = "a27c0e056bc4d6ed94bf01a54e30fb6e85a66c7b61f3567922a217e491e84137" ]; then
  ok "I-r1-snapshot revision 1 preserved byte-for-byte"
else bad "I-r1-snapshot" "snapshot hash differs"; fi
if [ "$(shasum -a 256 "$RUN/review/R12-r2-snapshot.md" | cut -d' ' -f1)" = "56bb55f9830c61c9cec9838203f5a60135de96cb6706fdf3a7a6ac8fa45907dd" ]; then
  ok "I-r2-snapshot revision 2 preserved byte-for-byte"
else bad "I-r2-snapshot" "snapshot hash differs"; fi
if [ "$(shasum -a 256 "$RUN/review/R12-r3-snapshot.md" | cut -d' ' -f1)" = "e755e0b2cd138ba5e304609fca005744888071bda2b7eb7ebe049c9e2d65258c" ]; then
  ok "I-r3-snapshot revision 3 preserved byte-for-byte"
else bad "I-r3-snapshot" "snapshot hash differs"; fi
has "params-r11" "$RUN/inputs/parameters.json" '"param": "ci-job-structure"'
has "params-fixed" "$RUN/inputs/parameters.json" '"param": "target-os-matrix"'
has "prereq-r11" "$RUN/inputs/prerequisites.json" '"R11"'
has "prereq-hash" "$RUN/inputs/prerequisites.json" '410e88e5195a08def126037e9c451988633b1e48437ac82edca0a08c7a62418c'
hasre "manifest-tier" "$RUN/manifest.json" '"tier": "focused"'
has "manifest-id" "$RUN/manifest.json" '2026-09-26T190134Z-d0c66b769758'
has "index-owns" "$ROOT/research/CLAUDE.md" '| R12 | aggregate-required-status-check | pattern | py-only | DIVERGENT | — |'
has "f041" "$ROOT/docs/port/COMMONALITY.md" '| F041 | Single aggregate required-status-check job folding in all other job results | ci-workflows | py-only | DIVERGENT | R12 |'

# ---- prerequisite: R11 revision 7 ----
R11="$ROOT/research/topics/11-ci-workflow-job-structure/DECISION.md"
has "r11-handover" "$R11" "either \`plan\` is itself a required check, or, if R12 chooses an aggregate"
has "r11-plan-needs" "$R11" "the aggregate includes \`plan\` in its \`needs:\`"
has "r11-crit13" "$R11" "A forced \`plan\` failure, for example an unreachable \`BASE_SHA\`, leaves the pull request unmergeable"
has "r11-slot" "$R11" 'if R12 aggregates this file'"'"'s jobs'
has "r11-owns" "$R11" 'owns ci-job-structure = one .github/workflows/ci.yml'
has "r11-jobs" "$R11" "\`plan\`, \`hygiene\`, \`workflow-lint\`, \`msrv-floor\` and \`install-smoke\` are single-runner"

# ---- raw legs exist with the reported identities ----
MUSE="$RUN/raw/muse.md"; OPUS="$RUN/raw/opus.md"
has "muse-id" "$MUSE" 'research-muse-2026-09-26T190134Z-d0c66b769758'
has "opus-id" "$OPUS" 'claude-opus-5-5'
has "muse-rec" "$MUSE" 'always-on aggregate required check'
has "opus-rec" "$OPUS" 'Adopt **Option A**'
has "opus-baseline" "$OPUS" 'BASELINE-REVIEW: F041'
has "muse-nobaseline" "$MUSE" "No \`BASELINE-REVIEW:\` finding"

# ---- this DECISION's shape (run after drafting) ----
if [ ! -f "$DEC" ]; then bad "I-dec-missing" "DECISION.md absent"; echo "RESULT PASS=$PASS FAIL=$FAIL SKIP=0"; exit 1; fi
has "dec-header" "$DEC" '# 2026-09-27 — R12 — aggregate-required-status-check (pattern, Focused) — decision (revision 4)'
has "dec-revnote1" "$DEC" '**Revision note, revision 1.**'
has "dec-revnote" "$DEC" '**Revision note, revision 2.**'
has "dec-revnote3" "$DEC" '**Revision note, revision 3.**'
has "dec-revnote4" "$DEC" '**Revision note, revision 4.**'
has "dec-actor" "$DEC" "Actor \`synth-s66-2026-09-26T190134Z-d0c66b769758-r4\`, model \`claude-opus-5-5\`"
has "dec-h2-decision" "$DEC" '## Decision'
has "dec-h2-params" "$DEC" '## Parameters'
has "dec-h2-emp" "$DEC" '## Empirical check'
has "dec-h2-eng" "$DEC" '## Engines'
has "dec-h3-prin" "$DEC" '### Principles and implementation'
has "dec-reverify" "$DEC" 're-verify: 2027-03-27'
has "dec-ownsnone" "$DEC" "No \`owns <param> = <value>\` lines."
has "dec-noconflict" "$DEC" "No \`CONFLICT:\` line is raised."
has "dec-baseline" "$DEC" 'BASELINE-REVIEW: F041'
if grep -q '^## Supersedes' "$DEC"; then bad "I-dec-nosup" "nothing published, so no Supersedes"; else ok "I-dec-nosup"; fi
H2ORDER="$(grep -E '^## (Decision|Parameters|Empirical check|Engines|Supersedes)' "$DEC" | tr '\n' '|')"
if [ "$H2ORDER" = '## Decision|## Parameters|## Empirical check|## Engines|' ]; then ok "I-dec-h2order"; else bad "I-dec-h2order" "$H2ORDER"; fi
N_ASSUMES="$(grep -c '^- assumes ' "$DEC")"
if [ "$N_ASSUMES" -eq 5 ]; then ok "I-dec-assumes5"; else bad "I-dec-assumes5" "found $N_ASSUMES"; fi
if python3 - "$RUN/inputs/parameters.json" "$DEC" <<'EOF'
import json, sys
params = json.load(open(sys.argv[1]))
dec = open(sys.argv[2]).read()
for p in params:
    line = f"- assumes {p['param']} = {p['value']}"
    assert line in dec, f"assumes line missing or inexact: {p['param']}"
print("all assumes lines byte-exact")
EOF
then ok "I-dec-assumes-exact every assumes line byte-identical to inputs/parameters.json"; else bad "I-dec-assumes-exact" "mismatch"; fi

# Every check ID cited in DECISION resolves to a PASS in the evidence logs.
if python3 - "$DEC" "$EV/r12-lint.log" "$EV/r12-verdict.log" "$EV/r12-sources.log" "$EV/r12-ts.log" "$EV/r12-citations.log" "$EV/r12-inputs.sh" <<'EOF'
import re, sys
dec = open(sys.argv[1]).read()
srcs = sys.argv[2:7]
self_src = sys.argv[7]
logs = "".join(open(f).read() for f in srcs)
self_src_text = open(self_src).read()
self_ids = set("I-" + n for n in re.findall(r'(?:has|hasre) "([A-Za-z0-9-]+)"', self_src_text))
self_ids |= set(re.findall(r'(?:ok|bad) "(I-[A-Za-z0-9-]+)"', self_src_text))
toks = set(t for t in re.findall(r'`([A-Za-z][A-Za-z0-9._*-]*)`', dec)
           if re.match(r'^(?:[LVG][0-9A-Za-z]|S-|I-|S[0-9]|T-|C-)', t))
# ranges written `A`–`B` yield both endpoints as tokens already; wildcards keep '*'
missing = []
for t in sorted(toks):
    if t.startswith("I-"):
        stem = t[2:].rstrip("*")
        if not any(i[2:].startswith(stem) for i in self_ids):
            missing.append(t)
    elif t.endswith("*"):
        if f"PASS {t[:-1]}" not in logs:
            missing.append(t)
    elif "*" in t:  # S-*-ruleset
        pat = re.compile(r"PASS " + t.replace("*", r"[A-Za-z0-9-]+"))
        if not pat.search(logs):
            missing.append(t)
    else:
        if f"PASS {t}" not in logs and f"PASS {t} " not in logs:
            missing.append(t)
print(f"check tokens cited: {len(toks)}")
assert not missing, f"unresolved: {missing}"
print("all check IDs resolve")
EOF
then ok "I-dec-checks every cited check ID resolves to a PASS"; else bad "I-dec-checks" "unresolved check ID"; fi

echo "RESULT PASS=$PASS FAIL=$FAIL SKIP=0"
[ "$FAIL" -eq 0 ]
