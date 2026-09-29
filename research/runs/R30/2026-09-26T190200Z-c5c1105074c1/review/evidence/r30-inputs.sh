#!/usr/bin/env bash
# R30 evidence (revision 2, extended in revision 3): the run inputs are what the DECISION claims, the
# Muse-for-Codex seat has a recorded authority (Q17.A), every timing figure,
# timestamp and path quoted in the DECISION equals the pinned logs, every cited
# case ID exists in a log, and the DECISION shape matches the published contract.
# Reads only; writes nothing but stdout.
# Usage: bash r30-inputs.sh > r30-inputs.log 2>&1   (run after the other seven logs)
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
RUN="$ROOT/research/runs/R30/2026-09-26T190200Z-c5c1105074c1"
TOPIC="$ROOT/research/topics/30-type-check-gate"
EV="$RUN/review/evidence"
DEC="$RUN/review/DECISION.md"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "PASS $1"; }
bad() { FAIL=$((FAIL+1)); echo "FAIL $1 -- $2"; }

has() { # $1 id  $2 file  $3 fixed string
  if grep -qF -- "$3" "$2"; then ok "I-$1"; else bad "I-$1" "$2 lacks: $3"; fi
}

echo "# r30-inputs.sh  run $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ---- run inputs, re-frozen in revision 2 (prompt) and revision 3 (policy) ----
if cmp -s "$RUN/inputs/prompt.md" "$TOPIC/prompts/type-check-gate.prompt.md"; then
  ok "I-prompt run prompt is byte-identical to the live topic prompt"
else bad "I-prompt" "prompt drift"; fi
if [ "$(sed -n 25p "$RUN/inputs/prompt.md")" = "- engines: muse, opus" ]; then
  ok "I-prompt-engines inputs/prompt.md:25 reads '- engines: muse, opus'"
else bad "I-prompt-engines" "line 25 is: $(sed -n 25p "$RUN/inputs/prompt.md")"; fi
# shellcheck disable=SC2016  # literal backticks in the searched text
has "prompt-substitution" "$RUN/inputs/prompt.md" 'This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot'
if cmp -s "$RUN/inputs/EXECUTION.json" "$ROOT/research/EXECUTION.json"; then
  ok "I-policy run policy snapshot is byte-identical to the live research/EXECUTION.json"
else bad "I-policy" "policy drift"; fi
if python3 - "$ROOT/research/EXECUTION.json" <<'EOF'
import json, sys
e = json.load(open(sys.argv[1]))
ov = e["engine_overrides"]["R30"]; it = e["items"]["R30"]["engines"]
print("engine_overrides.R30:", ov, " items.R30.engines:", it)
assert ov == ["muse", "opus"] and it == ["muse", "opus"]
EOF
then ok "I-override live engine_overrides.R30 and items.R30.engines are [muse, opus]"
else bad "I-override" "R30 engines differ"; fi
if python3 - "$RUN/inputs/EXECUTION.json" "$ROOT/research/RUNBOOK.md" <<'EOF'
import json, sys
e = json.load(open(sys.argv[1])); eao = e["empirical_auditor_overrides"]
print("frozen empirical_auditor_overrides:", len(eao), "entries; R30 ->", eao.get("R30"))
assert eao.get("R30") == "claude"
rb = "".join(open(sys.argv[2]).readlines()[97:104])
assert "`empirical_auditor_overrides`" in rb and "anthropic identity" in rb, "RUNBOOK.md:98-104 moved"
EOF
then ok "I-eao-r30 frozen policy lists R30 -> claude in empirical_auditor_overrides; RUNBOOK.md:98-104 defines it"
else bad "I-eao-r30" "overrides entry or RUNBOOK definition missing"; fi
if sed -n '73,76p' "$ROOT/research/RUNBOOK.md" | tr '\n' ' ' | grep -qE 'Q17\.A \(2026-09-27\).*extends the substitution to the research wave.* R30,'; then
  ok "I-runbook-q17a RUNBOOK.md:73-76 names Q17.A and lists R30"
else bad "I-runbook-q17a" "RUNBOOK.md:73-76 does not carry Q17.A with R30"; fi
if python3 - "$RUN/manifest.json" <<'EOF'
import json, sys
m = json.load(open(sys.argv[1]))
print("manifest required_engines:", m["required_engines"], " input_hashes.prompt:", m["input_hashes"]["prompt"], " operations:", m["operations"])
assert m["required_engines"] == ["codex", "opus"]
assert m["input_hashes"]["prompt"] == "a883b22d7e0c51cff4f41e671729652d1a434445a8623d32092bcfb74cf560db"
assert m["operations"] == {}
EOF
then ok "I-manifest-dispatch manifest still records the pre-amendment dispatch (codex, opus; prompt a883b22d; no operations)"
else bad "I-manifest-dispatch" "manifest changed"; fi
if [ "$(shasum -a 256 "$RUN/review/R30-r1-snapshot.md" | cut -d' ' -f1)" = "bde05533efb747334a6f79755706c0ad964bb0e720adaa96d1c9a528c62ba45c" ]; then
  ok "I-r1-snapshot revision 1 preserved byte-for-byte"
else bad "I-r1-snapshot" "snapshot hash differs"; fi
if [ "$(shasum -a 256 "$RUN/review/R30-r2-snapshot.md" | cut -d' ' -f1)" = "d15d4cee636494fac69c6996017c9c099860dad8b1c205d1b45fbde7ac86d687" ]; then
  ok "I-r2-snapshot revision 2 preserved byte-for-byte"
else bad "I-r2-snapshot" "snapshot hash differs"; fi

# ---- the channel owner cited for member 3's Cargo >= 1.97 constraint (JF-5) ----
R42="$ROOT/research/topics/42-dev-toolchain-provisioning/DECISION.md"
# shellcheck disable=SC2016  # literal backticks in the searched text
if [ "$(shasum -a 256 "$R42" | cut -d' ' -f1)" = "a2504aa7e3ad210e788e41ef53fbf37505a5254f54fd31955f9d1d2b574f5e1c" ] \
   && sed -n 26p "$R42" | grep -qF 'The `channel` **value** is R27'"'"'s through F103/F190 and is not set here.' \
   && sed -n 439p "$R42" | grep -qF '`channel = "stable"`' \
   && sed -n 458p "$R42" | grep -qF '(channel per R27'; then
  ok "I-r42-channel R42 DECISION.md (a2504aa7) :26 defers the channel to R27; :439 channel = stable; :458 channel per R27"
else bad "I-r42-channel" "R42 DECISION.md changed or cited lines moved"; fi
# shellcheck disable=SC2016  # literal backticks in the searched text
if sed -n 14p "$TOPIC/../27-formatter-config-surface/prompts/formatter-config-surface.prompt.md" | grep -qF 'The file'"'"'s `channel` and `components` are decided here (F103)'; then
  ok "I-r27-f103 R27 prompt :14 claims the channel under F103"
else bad "I-r27-f103" "R27 prompt :14 moved"; fi
for f in PARAMETERS.md:docs/port/PARAMETERS.md CLAUDE.md:research/CLAUDE.md; do
  if cmp -s "$RUN/inputs/${f%%:*}" "$ROOT/${f#*:}"; then ok "I-live-${f%%.*} inputs/${f%%:*} equals live ${f#*:}"
  else bad "I-live-${f%%.*}" "inputs/${f%%:*} differs from ${f#*:}"; fi
done
has "prereq-hash" "$RUN/inputs/prerequisites.json" '410e88e5195a08def126037e9c451988633b1e48437ac82edca0a08c7a62418c'
if [ "$(shasum -a 256 "$ROOT/research/topics/11-ci-workflow-job-structure/DECISION.md" | cut -d' ' -f1)" = "410e88e5195a08def126037e9c451988633b1e48437ac82edca0a08c7a62418c" ]; then
  ok "I-r11-live R11 DECISION.md still matches prerequisites.json"
else bad "I-r11-live" "R11 DECISION.md changed"; fi

# ---- evidence logs: counts and headers ----
for spec in scope:20 severity:17 suppression:16 lints:14 wiring-cost:17 wiring-severity:8; do
  n=${spec%%:*}; want=${spec#*:}; log="$EV/r30-$n.log"
  got=$(grep -cE 'PASS$' "$log"); fl=$(grep -cE 'FAIL$' "$log")
  if [ "$got" = "$want" ] && [ "$fl" = 0 ] && [ "$(tail -1 "$log")" = "# summary: failures=0" ]; then
    ok "I-counts-$n $got PASS, 0 FAIL, failures=0"
  else bad "I-counts-$n" "PASS=$got (want $want) FAIL=$fl last='$(tail -1 "$log")'"; fi
done
if ! grep -q MISSING "$EV/r30-upstream-docs.log" && [ "$(tail -1 "$EV/r30-upstream-docs.log")" = "# summary: failures=0" ]; then
  ok "I-counts-upstream-docs 0 MISSING, failures=0"
else bad "I-counts-upstream-docs" "MISSING present or failures"; fi
for n in lints scope severity suppression wiring-cost; do
  if [ "$(sed -n 2p "$EV/r30-$n.log")" = "# CARGO_HOME=/tmp/cargo-s34-R30-r3" ]; then ok "I-hdr-cargo-home-$n"
  else bad "I-hdr-cargo-home-$n" "$(sed -n 2p "$EV/r30-$n.log")"; fi
done
if python3 - "$EV" "$DEC" <<'EOF'
import re, sys, glob, os
ev, dec = sys.argv[1], open(sys.argv[2]).read()
stamps = {}
for f in sorted(glob.glob(os.path.join(ev, "r30-*.log"))):
    if f.endswith("r30-inputs.log"): continue
    m = re.search(r" run (\S+Z)", open(f).readline())
    stamps[os.path.basename(f)] = m.group(1)
first = min(stamps.items(), key=lambda kv: kv[1]); last = max(stamps.items(), key=lambda kv: kv[1])
print("first", first, "last", last)
assert f"`run {first[1]}` (`{first[0]}:1`)" in dec, "first stamp not quoted"
assert f"`run {last[1]}` (`{last[0]}:1`)" in dec, "last stamp not quoted"
EOF
then ok "I-hdr-utc DECISION quotes the first and last log header stamps"
else bad "I-hdr-utc" "UTC range in DECISION differs from the logs"; fi

# ---- every timing figure in the DECISION equals the pinned log ----
if python3 - "$EV/r30-wiring-cost.log" "$DEC" <<'EOF'
import re, sys
log = open(sys.argv[1]).read().split("\n"); dec = open(sys.argv[2]).read()
wc, line_of, case = {}, {}, None
for i, l in enumerate(log, 1):
    m = re.match(r"== (H\d[a-z]) ", l)
    if m: case = m.group(1)
    m = re.search(r"wall-clock: (\d+\.\d\d) s", l)
    if m and case and case not in wc: wc[case] = m.group(1); line_of[case] = i
print("wall-clock by case:", wc)
def rng(*cs):
    v = sorted(float(wc[c]) for c in cs); return f"{v[0]:.2f}–{v[-1]:.2f} s"
checks = {
  "I-fig-cold":   [f"{wc['H2a']} s cold (`H2a`, `r30-wiring-cost.log:{line_of['H2a']}`)", f"{wc['H2a']} s cold once"],
  "I-fig-noop":   [rng("H2b","H2c") + " warm no-op"],
  "I-fig-incr":   [rng("H2d","H2e","H2f") + " incremental", rng("H2d","H2e","H2f") + " after an edit"],
  "I-fig-commit": [rng("H3e","H3f") + " wall-clock", f"`H3e` {wc['H3e']} s, `H3f` {wc['H3f']} s, `r30-wiring-cost.log:{line_of['H3e']}`, `:{line_of['H3f']}`"],
  "I-fig-clippy": [f"{wc['H4a']} s wall-clock (`H4a`, `r30-wiring-cost.log:{line_of['H4a']}`)"],
}
bad = 0
for cid, needles in checks.items():
    miss = [n for n in needles if n not in dec]
    print(("PASS " if not miss else "FAIL ") + cid + ("" if not miss else f" -- missing {miss}"))
    bad += bool(miss)
assert max(float(wc[c]) for c in ("H3e","H3f")) < 1.0, "'under 1 s' no longer true"
assert "wall-clock, under 1 s." in dec, "'under 1 s' sentence not found"
print("PASS I-fig-under-1 H3e/H3f wall-clock < 1 s, as the DECISION states")
# stale revision-1 and revision-2 figures may appear only inside the revision notes
a, rest = dec.split("**Revision note, revision 3.**", 1)
body = a + rest.split("**Revision note, revision 1.**", 1)[1]
for stale in ("6.11 s", "0.18–0.26 s", "0.26–0.56 s", "0.09 s", "cargo-s9-R30", "01:28Z", "01:35Z",
              "0.12–0.24 s", "0.25–0.48 s", "0.27 s", "5.53 s cold", "under 0.6 s", "done in 0.11 seconds",
              "done in 0.20 seconds", "cargo-s20-R30-r2", "04:48:55Z", "04:49:23Z"):
    if stale in body: print(f"FAIL I-fig-stale -- '{stale}' outside the revision notes"); bad += 1
print("PASS I-fig-stale no revision-1 or revision-2 figure outside the revision notes" if not bad else "")
# every quoted lefthook summary is on the cited line
q = re.search(r"read `done in (\d\.\d\d) seconds` and `done in (\d\.\d\d) seconds` \(`:(\d+)`, `:(\d+)`\)", dec)
assert q, "lefthook summary sentence not found"
for secs, ln in ((q.group(1), int(q.group(3))), (q.group(2), int(q.group(4)))):
    assert f"summary: (done in {secs} seconds)" == log[ln-1].strip(), f"lefthook line {ln}: {log[ln-1]!r}"
print(f"PASS I-fig-lefthook lefthook summaries at :{q.group(3)} and :{q.group(4)}")
sys.exit(1 if bad else 0)
EOF
then ok "I-fig-all every quoted timing equals its case's wall-clock value"
else bad "I-fig-all" "figure mismatch (see lines above)"; fi

# ---- every excerpt line occurs verbatim in a log ----
if python3 - "$EV" "$DEC" <<'EOF'
import re, sys, glob, os
ev, dec = sys.argv[1], open(sys.argv[2]).read()
logs = set()
for f in glob.glob(os.path.join(ev, "r30-*.log")):
    logs |= {l.rstrip() for l in open(f)}
block = dec.split("**Observed output, key cases**", 1)[1].split("```text\n", 1)[1].split("```", 1)[0]
lines = [l.rstrip() for l in block.split("\n") if l.strip()]
miss = [l for l in lines if l not in logs]
print(f"excerpt lines: {len(lines)}; not found: {miss}")
assert not miss
EOF
then ok "I-excerpt every excerpt line occurs verbatim in a log"
else bad "I-excerpt" "excerpt line not in any log"; fi

# ---- DECISION shape ----
has "dec-header" "$DEC" '# 2026-09-27 — R30 — type-check-gate (bundle, Focused) — decision (revision 3)'
has "dec-revnote3" "$DEC" '**Revision note, revision 3.**'
has "dec-revnote2" "$DEC" '**Revision note, revision 2.**'
has "dec-revnote1" "$DEC" '**Revision note, revision 1.**'
has "dec-reverify" "$DEC" 're-verify: 2027-03-26'
has "dec-h3-prin" "$DEC" '### Principles and implementation'
if grep -q '^## Supersedes' "$DEC"; then bad "I-dec-nosup" "nothing published, so no Supersedes"; else ok "I-dec-nosup"; fi
H2ORDER="$(grep -E '^## ' "$DEC" | tr '\n' '|')"
if [ "$H2ORDER" = '## Decision|## Parameters|## Empirical check|## Engines|' ]; then ok "I-dec-h2order"
else bad "I-dec-h2order" "$H2ORDER"; fi
PUB="$ROOT/research/topics/11-ci-workflow-job-structure/DECISION.md"
if [ "$(grep -E '^## (Decision|Parameters|Empirical check|Engines)$' "$PUB" | tr '\n' '|')" = '## Decision|## Parameters|## Empirical check|## Engines|' ]; then
  ok "I-dec-h2-published published R11 DECISION carries the same four H2s in the same order"
else bad "I-dec-h2-published" "published H2s differ"; fi
if python3 - "$ROOT/docs/port/PARAMETERS.md" "$DEC" <<'EOF'
import sys
rows = {}
for l in open(sys.argv[1]):
    c = [x.strip() for x in l.strip().strip("|").split("|")]
    if len(c) >= 5: rows[c[0]] = c[3]
dec = open(sys.argv[2]).read().split("\n")
got = [l for l in dec if l.startswith("- assumes ")]
assert len(got) == 5, len(got)
for l in got:
    k, v = l[len("- assumes "):].split(" = ", 1)
    assert rows.get(k) == v, f"assumes {k} differs from live registry"
print("5 assumes lines equal the live registry values")
EOF
then ok "I-dec-assumes five assumes lines byte-identical to docs/port/PARAMETERS.md"
else bad "I-dec-assumes" "assumes mismatch"; fi

# ---- JF-5: the pin and the >= 1.97 constraint go to R27, not R42 (outside the revision notes) ----
if python3 - "$DEC" <<'EOF'
import sys
dec = open(sys.argv[1]).read()
a, rest = dec.split("**Revision note, revision 3.**", 1)
body = a + rest.split("**Revision note, revision 1.**", 1)[1]
gone = ["the pin is R42's", "R42 leaving the CI or contributor toolchain unpinned",
        "**R42** (toolchain provisioning): the toolchain pin", "from the toolchain the template already requires"]
need = ["**R27** (formatter config surface; F103",
        "must carry Cargo ≥ 1.97, or `CARGO_BUILD_WARNINGS=deny` is inert",
        "R27 settling F103 on an unpinned `stable` channel",
        "on a channel whose Cargo is below 1.97",
        "toolchain whose `channel` R27 settles under F103"]
bad = [g for g in gone if g in body] + ["missing: " + n for n in need if n not in body]
print("JF-5 routing problems:", bad)
assert not bad
EOF
then ok "I-jf5 pin and Cargo >= 1.97 constraint routed to R27 (F103); no R42 pin routing outside the revision notes"
else bad "I-jf5" "JF-5 routing incomplete"; fi

# ---- every cited case ID exists in a log; every cited I- ID exists here ----
if python3 - "$EV" "$DEC" "$0" <<'EOF'
import re, sys, glob, os
ev, dec, me = sys.argv[1], open(sys.argv[2]).read(), open(sys.argv[3]).read()
heads = set()
for f in glob.glob(os.path.join(ev, "r30-*.log")):
    heads |= {m.group(1) for m in re.finditer(r"^== ([A-Z]\d+[a-z]?)\b", open(f).read(), re.M)}
toks = set(re.findall(r"`([SWXLHV]\d+[a-z]?)`", dec))
miss = [t for t in sorted(toks) if not any(h == t or (h.startswith(t) and h[len(t):].isalpha()) for h in heads)]
ids = set(re.findall(r"`(I-[A-Za-z0-9*-]+)`", dec))
mine = set(re.findall(r'"(I-[A-Za-z0-9-]+)', me)) | {"I-" + m for m in re.findall(r'has "([a-z0-9-]+)"', me)}
imiss = [i for i in sorted(ids) if not any(m.startswith(i.rstrip("*")) for m in mine)]
print(f"case IDs cited: {len(toks)}, unresolved: {miss}; I- IDs cited: {len(ids)}, unresolved: {imiss}")
assert not miss and not imiss
EOF
then ok "I-dec-cases every cited case ID and I- ID resolves"
else bad "I-dec-cases" "unresolved ID"; fi

echo "# summary: PASS=$PASS FAIL=$FAIL failures=$FAIL"
exit "$FAIL"
