#!/usr/bin/env bash
# R80 revision 4 — the audit repair, checked.
#
# Both revision-3 audits (review/audit-fable.md, review/audit-claude.md)
# returned reject. Revision 4 repairs every finding; this script asserts each
# repair at source rather than in prose.
#
#   V1       the current H1, and revisions 3, 4, 5 and 6 preserved byte-for-byte.
#   V2..V5   the engine set: the on-disk Muse leg (digest, bundle shape, the
#            uncollected operation), the codex->muse substitution in the
#            manifest, policy and RUNBOOK, the frozen prompt (I-prompt), and the
#            five disagreement anchors in raw/muse.md.
#   V6       R22 revision 1 accepted, its placement, and R69's facade->web
#            edge (revision 11, line 1885) that makes that placement
#            unreachable from web.
#   V7       R55 and R57 published at their accepted bytes.
#   V8       audit EA-3: no assertion pipes into an early-exiting grep
#            (repaired in revision 5 under audit EF-1 so it can fail).
#   V9       audit EA-4: committed lockfiles, --locked, the pinned tree.
#   V10      audits EA-2/EA-5: figures the prose states equal the logged ones.
#   V11      audit JF-8: the archive assertion-diff sizes the prose states.
#   V12      the single re-verify line carries the new triggers.
#   V13      every revision-4 evidence artifact, by sha256.
#   V14      the revision-3 script re-run into a separate file: 7 PASS, 0 FAIL.
#
# Usage: bash check-standard-r4.sh [repo-root]
# Exit status: 0 when no check FAILs, 1 otherwise.

# The quoted needles below are literal Markdown with backticks, never expansions.
# shellcheck disable=SC2016
set -euo pipefail

GREP=/usr/bin/grep
ROOT="${1:-}"
if [ -z "$ROOT" ]; then
  HERE0="$(cd "$(dirname "$0")" && pwd)"
  ROOT="$(cd "$HERE0/../../../../../.." && pwd)"
fi
HERE="$(cd "$(dirname "$0")" && pwd)"
RUN="research/runs/R80/2026-09-17T034011Z-74765d801b92"
DECISION="$ROOT/$RUN/review/DECISION.md"
H4='# 2026-09-27 — R80 — health-probe-endpoints (bundle, Focused) — decision (revision 4)'
H5='# 2026-09-27 — R80 — health-probe-endpoints (bundle, Focused) — decision (revision 5)'
H6='# 2026-09-27 — R80 — health-probe-endpoints (bundle, Focused) — decision (revision 6)'
H7='# 2026-09-27 — R80 — health-probe-endpoints (bundle, Focused) — decision (revision 7)'

PASS=0
FAIL=0
SKIP=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s — %s\n' "$1" "$2"; }
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
has() { $GREP -qF -- "$1" "$2"; } # literal needle, file

echo "=== R80 check-standard-r4.sh ==="
echo "date(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "grep: $($GREP --version | head -1)"
echo "python3: $(python3 --version 2>&1)"
if [ -e "$ROOT/.git" ]; then echo "git metadata: present"; else echo "git metadata: absent (archive extraction)"; fi

# ---------------------------------------------------------------- V1 --------
SNAP="$ROOT/$RUN/review/R80-r3-snapshot.md"
SNAP4="$ROOT/$RUN/review/R80-r4-snapshot.md"
SNAP5="$ROOT/$RUN/review/R80-r5-snapshot.md"
SNAP6="$ROOT/$RUN/review/R80-r6-snapshot.md"
H1=""
SNAP4_H1=""
SNAP5_H1=""
SNAP6_H1=""
[ -f "$DECISION" ] && { IFS= read -r H1 <"$DECISION" || true; }
[ -f "$SNAP4" ] && { IFS= read -r SNAP4_H1 <"$SNAP4" || true; }
[ -f "$SNAP5" ] && { IFS= read -r SNAP5_H1 <"$SNAP5" || true; }
[ -f "$SNAP6" ] && { IFS= read -r SNAP6_H1 <"$SNAP6" || true; }
if [ "$H1" = "$H7" ] && [ -f "$SNAP" ] &&
   [ "$(sha "$SNAP")" = 184d2b1714f8eb26a7b4df43b6020feb280662e85fcf3668a7fb0938d0d230c8 ] &&
   [ -f "$SNAP4" ] && [ "$SNAP4_H1" = "$H4" ] &&
   [ "$(sha "$SNAP4")" = f0320a3a8b61064ab5072aeafcf7f24a9a51e68cc2f76fe4073af0c46d3295b8 ] &&
   [ -f "$SNAP5" ] && [ "$SNAP5_H1" = "$H5" ] &&
   [ "$(sha "$SNAP5")" = 6ee8ad17642a847856766e914b45eac8727525f64a9f6f7159f6e1e7be97a6d9 ] &&
   [ -f "$SNAP6" ] && [ "$SNAP6_H1" = "$H6" ] &&
   [ "$(sha "$SNAP6")" = 4b63412a4dc1df4c2e31caa51fa20ca509c8e8cd430595f72b94de0843d4c204 ]; then
  pass V1 "the H1 is the date-first revision-7 title; review/R80-r6-snapshot.md holds revision 6 byte-for-byte (sha256 4b63412a…, the digest the revision-6 audits judged), review/R80-r5-snapshot.md holds revision 5 byte-for-byte (sha256 6ee8ad17…, the digest both revision-5 audits judged), review/R80-r4-snapshot.md holds revision 4 byte-for-byte (sha256 f0320a3a…, the digest both revision-4 audits judged) and review/R80-r3-snapshot.md holds revision 3 (sha256 184d2b17…)"
else
  fail V1 "the revision-7 H1, or the revision-6, revision-5, revision-4 or revision-3 snapshot, is not as stated"
fi

# ---------------------------------------------------------------- V2 --------
# The Muse leg is on disk. On 2026-09-27 its operation was not yet collected;
# collection by the controller is also accepted, provided it registers exactly
# the digest adjudicated here.
MUSE="$ROOT/$RUN/raw/muse.md"
MUSE_OP="$ROOT/$RUN/operations/muse.json"
if [ -f "$MUSE" ] && [ -f "$MUSE_OP" ]; then
  set +e
  V2_OUT="$(cd "$ROOT" && python3 - "$MUSE" "$MUSE_OP" <<'PY' 2>&1
import json, pathlib, sys
sys.path.insert(0, "scripts")
from research_validation import validate_answer_text
errors = validate_answer_text(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"), "bundle")
print("shape_errors=%d" % len(errors))
for error in errors:
    print(error)
op = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))
print("op_state=%s" % op.get("state"))
print("op_raw_sha256=%s" % op.get("raw_sha256", "absent"))
print("op_request_id=%s" % op.get("request_id"))
PY
)"
  V2_STATUS=$?
  set -e
  printf '%s\n' "$V2_OUT"
  MUSE_SHA="$(sha "$MUSE")"
  echo "raw/muse.md sha256: $MUSE_SHA"
  if [ "$V2_STATUS" -eq 0 ] &&
     [ "$MUSE_SHA" = 395c1426cd8db1e2d46588dcd364caac86a0beca6ca3119d5b7a56333672b012 ] &&
     $GREP -qxF 'shape_errors=0' <<<"$V2_OUT" &&
     has 'Retrieval date for all live figures: 2026-09-25.' "$MUSE" &&
     { { $GREP -qxF 'op_state=submitting' <<<"$V2_OUT" && $GREP -qxF 'op_raw_sha256=absent' <<<"$V2_OUT" && V2_BRANCH="uncollected: operations/muse.json is 'submitting' with no raw_sha256"; } ||
       { $GREP -qxF 'op_state=succeeded' <<<"$V2_OUT" && $GREP -qxF "op_raw_sha256=$MUSE_SHA" <<<"$V2_OUT" && V2_BRANCH="collected at exactly this digest"; }; }; then
    pass V2 "raw/muse.md is on disk at sha256 395c1426…, retrieved 2026-09-25, and passes validate_answer_text(\"bundle\") with 0 errors; operation state: $V2_BRANCH"
  else
    fail V2 "the Muse leg's digest, shape or operation state is not as the decision states"
  fi
else
  fail V2 "raw/muse.md or operations/muse.json is absent"
fi

# ---------------------------------------------------------------- V3 --------
# The engine set: muse + opus, codex substituted by the Q5.A migration event.
set +e
V3_OUT="$(cd "$ROOT" && python3 - "$RUN" <<'PY' 2>&1
import json, pathlib, sys
run = pathlib.Path(sys.argv[1])
m = json.loads((run / "manifest.json").read_text(encoding="utf-8"))
print("required_engines=%s" % ",".join(m["required_engines"]))
mig = [e["migration"] for e in m["events"] if "migration" in e]
print("migrations=%d" % len(mig))
for x in mig:
    print("migration from=%s to=%s reason=%s" % (x["from"], x["to"], x["reason"]))
    print("previous_required_engines=%s" % ",".join(x["previous_required_engines"]))
print("manifest_prompt_hash=%s" % m["input_hashes"]["prompt"])
p = json.loads(pathlib.Path("research/EXECUTION.json").read_text(encoding="utf-8"))
print("policy_override_R80=%s" % ",".join(p["engine_overrides"]["R80"]))
# No entry means the default seat, as scripts/research_validation.py reads it.
print("policy_empirical_auditor_R80=%s" % p.get("empirical_auditor_overrides", {}).get("R80", "codex"))
PY
)"
V3_STATUS=$?
set -e
printf '%s\n' "$V3_OUT"
RB="$ROOT/research/RUNBOOK.md"
if [ "$V3_STATUS" -eq 0 ] &&
   $GREP -qxF 'required_engines=muse,opus' <<<"$V3_OUT" &&
   $GREP -qxF 'migrations=1' <<<"$V3_OUT" &&
   $GREP -qxF 'migration from=codex to=muse reason=muse bulk substitution (owner decision Q5.A 2026-09-21)' <<<"$V3_OUT" &&
   $GREP -qxF 'previous_required_engines=codex,opus' <<<"$V3_OUT" &&
   $GREP -qxF 'policy_override_R80=muse,opus' <<<"$V3_OUT" &&
   $GREP -qxF 'policy_empirical_auditor_R80=codex' <<<"$V3_OUT" &&
   has 'Owner decision Q9.B retired Codex from P02' "$RB" &&
   has 'Q17.A (2026-09-27)' "$RB"; then
  pass V3 "the run requires muse + opus: the manifest's one migration event moves codex to muse under owner decision Q5.A (2026-09-21), the live engine_overrides row for R80 reads muse,opus, R80 has no empirical_auditor_overrides entry and so takes the default codex empirical seat, and RUNBOOK section 2 records Q9.B retiring Codex and Q17.A (2026-09-27) as the current override amendment"
else
  fail V3 "the engine substitution is not recorded as the decision states"
fi

# ---------------------------------------------------------------- V4 --------
# I-prompt: the frozen prompt is the live prompt, byte for byte, and names the
# muse + opus engine set. Informational lines report the other frozen inputs.
IN_PROMPT="$ROOT/$RUN/inputs/prompt.md"
LIVE_PROMPT="$ROOT/research/topics/80-health-probe-endpoints/prompts/health-probe-endpoints.prompt.md"
if [ -f "$IN_PROMPT" ] && [ -f "$LIVE_PROMPT" ]; then
  IN_SHA="$(sha "$IN_PROMPT")"; LIVE_SHA="$(sha "$LIVE_PROMPT")"
  echo "inputs/prompt.md sha256: $IN_SHA; live prompt: $LIVE_SHA"
  for pair in "inputs/EXECUTION.json research/EXECUTION.json" "inputs/CLAUDE.md research/CLAUDE.md" "inputs/PARAMETERS.md docs/port/PARAMETERS.md"; do
    read -r frozen live <<<"$pair"
    if cmp -s "$ROOT/$RUN/$frozen" "$ROOT/$live"; then
      echo "  info: $frozen equals $live"
    else
      echo "  info: $frozen differs from the live $live (re-freezing inputs/ is the controller's)"
    fi
  done
  if [ "$IN_SHA" = "$LIVE_SHA" ] &&
     $GREP -qxF "manifest_prompt_hash=$IN_SHA" <<<"$V3_OUT" &&
     $GREP -qxF -- '- engines: muse, opus' "$IN_PROMPT" &&
     has 'This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot; its mirrored `- engines:` line is authoritative.' "$IN_PROMPT"; then
    pass V4 "I-prompt: inputs/prompt.md is byte-identical to the live topic prompt and to the manifest's recorded prompt hash ($IN_SHA), and reads '- engines: muse, opus' with the substitution sentence"
  else
    fail V4 "I-prompt: the frozen prompt is not the live prompt, or does not name muse + opus"
  fi
else
  fail V4 "the frozen or the live prompt is absent"
fi

# ---------------------------------------------------------------- V5 --------
# The five disagreement anchors, at source in raw/muse.md, and the absence of a
# CONFLICT: line although its recommendation needs R49's clause changed.
if [ -f "$MUSE" ]; then
  MUSE_CONFLICTS="$($GREP -c '^CONFLICT:' "$MUSE" || true)"
  echo "raw/muse.md lines starting 'CONFLICT:': $MUSE_CONFLICTS"
  if has 'Adopt `built` 0.8.1 as a build-dependency' "$MUSE" &&
     has 'add `build.rs` calling `built::write_built_file()`' "$MUSE" &&
     has 'rustc_version: built_info::RUSTC_VERSION, git_sha: Option, uptime_seconds: u64' "$MUSE" &&
     has 'pub struct Check { pub name: String, pub ok: bool, pub detail: String }' "$MUSE" &&
     has '`built` passes all six fitness gates' "$MUSE" &&
     has 'No `CONFLICT:` lines — the recommendation fits all consumed values.' "$MUSE" &&
     has '`rustc --version` via `RUSTC_VERSION` is not built-in — it needs a build script' "$MUSE" &&
     [ "$MUSE_CONFLICTS" -eq 0 ] &&
     has 'no build.rs and no build-orchestration crate' "$ROOT/research/topics/49-build-target-declaration/DECISION.md"; then
    pass V5 "raw/muse.md recommends built 0.8.1 with a build.rs, a HealthzBody with rustc_version, git_sha and uptime_seconds, a two-state Check { ok: bool }, and says built passes all six gates — yet raises 0 CONFLICT: lines against R49's published 'no build.rs and no build-orchestration crate', and itself concedes rustc_version needs a build script"
  else
    fail V5 "an anchor for the Muse disagreements is not in raw/muse.md, or R49's clause moved"
  fi
else
  fail V5 "raw/muse.md is absent"
fi

# ---------------------------------------------------------------- V6 --------
# R22 revision 1 is owner-accepted; it places the constant in the facade's
# src/lib.rs; R69 revision 11 (line 1885) makes the facade depend on crates/web.
ACCEPT="$ROOT/docs/port/OWNER-ACCEPTANCES.md"
OWNERDEC="$ROOT/docs/planning/p02/owner-decisions.md"
R22_DIR="$ROOT/research/runs/R22/2026-09-17T020715Z-d93731e7353c/review"
R22_SHA=0e7ea78e64f6b9dc92a437973a76fb050352ddf64fd53b57c630d814d4c57f87
R22=""
for f in "$R22_DIR/DECISION.md" "$R22_DIR/R22-r1-snapshot.md"; do
  if [ -f "$f" ] && [ "$(sha "$f")" = "$R22_SHA" ]; then R22="$f"; break; fi
done
R22_LIVE_H1=""
[ -f "$R22_DIR/DECISION.md" ] && { IFS= read -r R22_LIVE_H1 <"$R22_DIR/DECISION.md" || true; }
echo "R22 accepted bytes at: ${R22#"$ROOT"/}"
echo "  info: R22's working DECISION.md H1 today: $R22_LIVE_H1"
R69R11="$ROOT/research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md"
R69_1885=""
[ -f "$R69R11" ] && R69_1885="$(sed -n '1885p' "$R69R11")"
if [ -n "$R22" ] &&
   has "| R22 | 1 | \`$R22_SHA\` | accept | 2026-09-18 |" "$ACCEPT" &&
   has '| W1-R22 | R22 runtime-version-accessor | A accept | 2026-09-18 |' "$OWNERDEC" &&
   has 'pub const VERSION: &str = env!("CARGO_PKG_VERSION");' "$R22" &&
   has "**Where it goes.** \`src/lib.rs\`" "$R22" &&
   has 'surface'"'"'s health/status response all read `rs_launch_blueprint::VERSION`' "$R22" &&
   has 're-verify: 2027-03-18, or earlier on any of — **R02 (`crate-boundary-enforcement`,' "$R22" &&
   has 'selecting a multi-crate workspace**' "$R22" &&
   $GREP -qF 'web = ["dep:rs-launch-blueprint-web"]' <<<"$R69_1885" &&
   $GREP -qF -- '- owns web-extra-surface = ' <<<"$R69_1885"; then
  pass V6 "R22 revision 1 (0e7ea78e…) is owner-accepted (OWNER-ACCEPTANCES row, W1-R22 option A) and puts pub const VERSION in the facade's src/lib.rs, read by the web surface's health response; its re-verify fires on R02 selecting a multi-crate workspace, which R02 revision 2 did; and R69 revision 11's owned value at line 1885 declares web = [\"dep:rs-launch-blueprint-web\"] on the facade, so crates/web cannot import the facade's constant without a cycle"
else
  fail V6 "R22's accepted text, its acceptance row, or R69 revision 11's facade->web edge is not as stated"
fi

# ---------------------------------------------------------------- V7 --------
R55P="$ROOT/research/topics/55-config-error-tolerance/DECISION.md"
R57P="$ROOT/research/topics/57-xdg-directory-set/DECISION.md"
INDEX="$ROOT/research/CLAUDE.md"
if [ -f "$R55P" ] && [ -f "$R57P" ] &&
   [ "$(sha "$R55P")" = 5d358c1fda2a5ff2782b916f3ca81cf52bbbafd75748774b114345c72a6edd9b ] &&
   [ "$(sha "$R57P")" = 44e945045f0e2c964520918801f5c8f3921a3cfefc4ef5c72b0bc497038139ba ] &&
   $GREP -q '^| R55 | config-error-tolerance |.*| resolved |$' "$INDEX" &&
   $GREP -q '^| R57 | xdg-directory-set |.*| resolved |$' "$INDEX"; then
  pass V7 "R55 (revision 3, 5d358c1f…) and R57 (revision 2, 44e94504…) are published: the topic DECISION.md files carry exactly the accepted bytes and the index marks both resolved"
else
  fail V7 "R55 or R57 is not published at its accepted bytes"
fi

# ---------------------------------------------------------------- V8 --------
# Audit EA-3: a variable piped into an early-exiting grep is a SIGPIPE race
# under `set -o pipefail`. The pattern is assembled from pieces so this script
# does not match itself. Revision 5 (audit EF-1 of revision 4): each
# alternative's leading pipe is escaped, so it is a literal pipe character and
# not an empty ERE alternative that BSD grep rejects; a grep status of 2 or
# more, or a non-numeric count, FAILs V8 instead of counting as 0; and a
# positive control built from a variable must count exactly 1.
PIPE_Q='\|[[:space:]]*\$GREP[[:space:]]+-[A-Za-z]*q'
PIPE_Q2='\|[[:space:]]*grep[[:space:]]+-[A-Za-z]*q'
V8_HITS=0
V8_ERR=0
BAR='|'
set +e
V8_CTRL="$($GREP -cE -- "$PIPE_Q|$PIPE_Q2" <<<"x $BAR grep -q y")"
V8_CTRL_RC=$?
set -e
echo "  positive control, one line piping into grep -q: count ${V8_CTRL:-none}, grep status $V8_CTRL_RC"
for s in check-offline.sh check-probe.sh check-live.sh check-standard-r2.sh check-standard-r3.sh check-standard-r4.sh; do
  set +e
  n="$($GREP -cE -- "$PIPE_Q|$PIPE_Q2" "$HERE/$s")"
  rc=$?
  set -e
  echo "  early-exit grep pipelines in $s: ${n:-none} (grep status $rc)"
  if [ "$rc" -ge 2 ] || ! [[ "$n" =~ ^[0-9]+$ ]]; then
    V8_ERR=$((V8_ERR + 1))
  else
    V8_HITS=$((V8_HITS + n))
  fi
done
if [ "$V8_CTRL_RC" -eq 0 ] && [ "$V8_CTRL" = 1 ] && [ "$V8_ERR" -eq 0 ] && [ "$V8_HITS" -eq 0 ]; then
  pass V8 "no line in the six scripts pipes into grep -q; every such assertion reads a here-string or a file, so no second writer can take SIGPIPE. The scan is falsifiable: its positive control counts 1, and all six scans exited without a grep error"
else
  fail V8 "positive control count ${V8_CTRL:-none} (status $V8_CTRL_RC), $V8_ERR scan(s) with a grep error, $V8_HITS early-exit grep pipeline(s)"
fi

# ---------------------------------------------------------------- V9 --------
LOCK_A="$HERE/probe/manifests-a/Cargo.lock"
LOCK_B="$HERE/probe/manifests-b/Cargo.lock"
lock_has() { # crate, version, lockfile — the two adjacent lines of one [[package]]
  python3 - "$1" "$2" "$3" <<'PY'
import sys
t = open(sys.argv[3], encoding="utf-8").read()
sys.exit(0 if 'name = "%s"\nversion = "%s"\n' % (sys.argv[1], sys.argv[2]) in t else 1)
PY
}
V9_BAD=0
for lock in "$LOCK_A" "$LOCK_B"; do
  if [ ! -f "$lock" ]; then echo "  MISSING ${lock#"$HERE"/}"; V9_BAD=$((V9_BAD + 1)); continue; fi
  for pin in "axum 0.8.9" "tokio 1.53.1" "serde 1.0.229" "serde_json 1.0.151" "tower 0.5.3" "hyper-util 0.1.20" "smallvec 1.16.1"; do
    read -r n v <<<"$pin"
    if lock_has "$n" "$v" "$lock"; then :; else echo "  ${lock#"$HERE"/} lacks $n $v"; V9_BAD=$((V9_BAD + 1)); fi
  done
done
for s in check-probe.sh check-standard-r2.sh; do
  if ! has 'CARGO_FLAGS=(--locked --offline)' "$HERE/$s" || ! has 'CARGO_FLAGS=(--locked)' "$HERE/$s"; then
    echo "  $s does not pass --locked on both paths"; V9_BAD=$((V9_BAD + 1))
  fi
done
if ! has "cargo network flags: '--locked" "$HERE/check-probe.log" ||
   ! has 'hyper-util v0.1.20' "$HERE/check-probe.log" ||
   ! has 'smallvec v1.16.1' "$HERE/check-probe.log" ||
   ! has "cargo network flags: '--locked" "$HERE/check-standard-r2.log"; then
  echo "  the recorded logs do not show the locked build and the pinned tree"; V9_BAD=$((V9_BAD + 1))
fi
if [ "$V9_BAD" -eq 0 ]; then
  pass V9 "both probe workspaces carry a committed Cargo.lock pinning axum 0.8.9, tokio 1.53.1, serde 1.0.229, serde_json 1.0.151, tower 0.5.3 and the two transitive crates at revision 1's measured hyper-util 0.1.20 and smallvec 1.16.1; both build scripts pass --locked on the offline and the online path, and both logs record it"
else
  fail V9 "$V9_BAD lockfile or --locked defect(s)"
fi

# --------------------------------------------------------------- V10 --------
# Audits EA-2 and EA-5: a figure the prose states must equal the one its own
# evidence recorded. Both are read from the logs, never transcribed here.
if [ -f "$DECISION" ]; then
  set +e
  V10_OUT="$(python3 - "$DECISION" "$HERE/check-live.log" "$HERE/snapshots/cratesio-search-liveness.json" <<'PY' 2>&1
import json, pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
live = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8")
snap = json.loads(pathlib.Path(sys.argv[3]).read_text(encoding="utf-8"))
ov = text.count("OVERRIDE (OV-05)")
stated = re.findall(r"`OVERRIDE \(OV-05\)`\s+appears\s+\*\*(\d+)\*\*\s+times", text)
print("ov05_count=%d stated=%s" % (ov, ",".join(stated)))
print("ov05_ok=%s" % (len(stated) == 1 and int(stated[0]) == ov))
ok = True
for q in ("health", "probe", "liveness"):
    m = re.search(r"q=%s: meta\.total=(\d+)" % q, live)
    val = int(m.group(1))
    fmt = "{:,}".format(val)
    # Prose wraps, so any run of whitespace may separate the parts.
    sites = len(re.findall(r"`q=%s`\s+[\d,]+\s+→\s+\*\*%s\*\*" % (q, re.escape(fmt)), text))
    quoted = len(re.findall(r"`q=%s`\s+[\d,]+\s+→\s+\*\*[\d,]+\*\*" % q, text))
    print("q=%s logged=%d prose_sites_matching=%d of %d" % (q, val, sites, quoted))
    ok = ok and sites >= 1 and sites == quoted
liveness_snapshot = snap["meta"]["total"] if "meta" in snap else snap.get("total")
print("liveness_snapshot=%s" % liveness_snapshot)
print("census_ok=%s" % (ok and "28,356" not in text and str(liveness_snapshot) == re.search(r"q=liveness: meta\.total=(\d+)", live).group(1)))
PY
)"
  V10_STATUS=$?
  set -e
  printf '%s\n' "$V10_OUT"
  if [ "$V10_STATUS" -eq 0 ] && $GREP -qxF 'ov05_ok=True' <<<"$V10_OUT" && $GREP -qxF 'census_ok=True' <<<"$V10_OUT"; then
    pass V10 "the OVERRIDE (OV-05) count the prose states equals the count in the file, and each of the three census denominators the prose quotes equals the one check-live.log recorded (the liveness figure also equals the committed snapshot); the unsupported 28,356 appears nowhere"
  else
    fail V10 "a stated figure differs from its evidence (see above)"
  fi
else
  fail V10 "DECISION.md is absent"
fi

# --------------------------------------------------------------- V11 --------
# Audit JF-8: of revision 1's three archive assertion diffs, two are empty and
# the live one carries only the mode banner.
A_OFF="$(wc -c <"$HERE/check-offline.archive.assertions.diff" | tr -d ' ')"
A_PRB="$(wc -c <"$HERE/check-probe.archive.assertions.diff" | tr -d ' ')"
A_LIV="$(wc -c <"$HERE/check-live.archive.assertions.diff" | tr -d ' ')"
echo "archive assertion diffs (bytes): offline $A_OFF, probe $A_PRB, live $A_LIV"
if [ "$A_OFF" -eq 0 ] && [ "$A_PRB" -eq 0 ] && [ "$A_LIV" -eq 96 ] &&
   $GREP -qF 'mode: ' "$HERE/check-live.archive.assertions.diff" &&
   has 'is **96 bytes**' "$DECISION"; then
  pass V11 "revision 1's archive assertion diffs are 0, 0 and 96 bytes; the 96 bytes are the live script's mode banner — the figures the revision-4 prose states"
else
  fail V11 "the archive assertion-diff sizes are not as the prose states"
fi

# --------------------------------------------------------------- V12 --------
RV="$($GREP -c '^re-verify: ' "$DECISION" || true)"
RVL="$($GREP '^re-verify: ' "$DECISION" || true)"
if [ "$RV" -eq 1 ] &&
   $GREP -qF 'when R02, R05 or R03 is re-bound to a new accepted revision' <<<"$RVL" &&
   $GREP -qF 'when R22 or R02 settles which package holds the VERSION constant' <<<"$RVL" &&
   $GREP -qF 'when the controller collects the Muse operation' <<<"$RVL"; then
  pass V12 "the decision carries exactly one re-verify line, and it now fires on a re-bind of R02, R05 or R03, on R22/R02 settling the constant's package, and on collection of the Muse operation"
else
  fail V12 "the re-verify line is missing a revision-4 trigger, or there is not exactly one"
fi

# --------------------------------------------------------------- V13 --------
# Every revision-4 evidence artifact, by digest: the restarted "unchanged
# since" promise for any later revision. Revisions 5, 6 and 7 re-baselined C2
# and R1 to their H1, so the revision-2 and revision-3 scripts and logs carry
# their revision-7 digests, as do check-offline.sh and its log, which revision 7
# moved to R69 revision 11 (O3, O5); the other 16 entries are revision 4's bytes. check-live.sh and check-live.log are
# revision 1's bytes, unchanged; the shellcheck logs of revisions 1-3 describe
# earlier script bytes and are kept as history.
declare -a R4_ARTIFACTS=(
  "fccff1b713954954766e3dc01a7be6ebe72fac99df7b4094116ab553db1ca82d check-offline.sh"
  "020fdbd7c299a18e790c4cdcf2ce629083afaf592e38f761eaa26bb9526cb759 check-offline.log"
  "6a8ffed8dfc3f9be69ecbdbc4805572641cd88111c556f8691b272bbaea75f51 check-probe.sh"
  "c2fb16f6322303049f25f91800d3592d75004236fcf9227429941a76bedb342d check-probe.log"
  "fb08bb557f110fd48c55bd591fdcfbe367442ce52c4a1dfd3351449297129f8f check-live.sh"
  "2a2183f8c15f651b70bdc0036c3385561be254b711dfb0200c25ca543541b749 check-live.log"
  "89b78f5f2883825bf8892844519e024c071749fe76cbf6d54ac234f48c008475 check-live.r4-fetch.log"
  "d19208cd189d763648181d94e70a17d36431b54f29d6de4459a7eea2e1b73022 check-live.r4-snapshots.log"
  "e74254d547eb78da768b2b4c9c83ba5ad863e277790d4054a4f2809484f5267f check-standard-r2.sh"
  "49ae8df9206f8b741805691a2ca1d25f9e7f4d09e0bbd7773364f235bf7ff3e6 check-standard-r2.log"
  "8609db0f10680741bdc03e530cc9f336af168358008d3487bcfbee25afa4db82 check-standard-r3.sh"
  "f7765cceb25bf5791147b1a5367ce5dbfa0c333b58f3d9e0fd9b8cd2221673f5 check-standard-r3.log"
  "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 shellcheck-r4.log"
  "faa6aaee900eaf01d229ca1af5105fd90976e36127f9786a0adcde2755bc0214 probe/manifests-a/Cargo.lock"
  "ea6fa7f6d886e4500af3b406d6efe5aedc068ac4d6f14664adb3a46ff459e3a9 probe/manifests-b/Cargo.lock"
  "8cec46b5155bb8bb721723139b21a5ae906357ac7affe30c1a93a1dbbd72aff0 probe/core-src/lib.rs"
  "77e1683ef45a8b464e8e8d7fd12b022ef1176e18d5f08529be66cb64da928399 probe/web-src/lib.rs"
  "419751b3de90f4caf26536b63b2d8ee66082ee1ed74f03c4bbb7dcd4c631a3b1 probe/web-tests/probes.rs"
  "e99cdf289ec32f4410284a0430de3c60b060b6d2386c93a985f5a698f08d03b6 probe/facade-src/lib.rs"
  "c9d539a22585de8bb9a4707bdd0fe10c6a1079bcf6ac3fc69dfd790e3743d364 probe/facade-tests/version_hazard.rs"
  "f227ee8602ab12b10e267d85b228fd65247d9b6218bea73859c9cee8c384239c probe-r2/web-src/lib.rs"
  "4542f02ea972c4cb15dec5a399b05f4770aa66160aad435d0f9b42b15865f80c probe-r2/web-tests/conformance.rs"
)
V13_BAD=0
for entry in "${R4_ARTIFACTS[@]}"; do
  read -r want path <<<"$entry"
  if [ ! -f "$HERE/$path" ]; then echo "  MISSING $path"; V13_BAD=$((V13_BAD + 1)); continue; fi
  got="$(sha "$HERE/$path")"
  if [ "$got" = "$want" ]; then
    printf '  pinned     %s\n' "$path"
  else
    printf '  CHANGED    %s (%s, expected %s)\n' "$path" "$got" "$want"
    V13_BAD=$((V13_BAD + 1))
  fi
done
if [ "$V13_BAD" -eq 0 ]; then
  pass V13 "all ${#R4_ARTIFACTS[@]} revision-4 evidence artifacts — five scripts and their paired logs, the two revision-4 live reruns, the shellcheck record, both lockfiles and all nine probe sources — hash to the digests recorded here, the offline, revision-2 and revision-3 scripts and logs at their revision-7 bytes"
else
  fail V13 "$V13_BAD revision-4 artifact(s) differ from the recorded digests"
fi

# --------------------------------------------------------------- V14 --------
# The revision-3 script re-run into a separate file; it nests the revision-2
# and offline re-runs, so one call exercises the whole cascade.
if [ -f "$HERE/check-standard-r3.sh" ]; then
  set +e
  bash "$HERE/check-standard-r3.sh" "$ROOT" >"$HERE/check-standard-r3.r4-rerun.log" 2>&1
  set -e
  V14_FAILS="$($GREP -c '^FAIL ' "$HERE/check-standard-r3.r4-rerun.log" || true)"
  V14_PASSES="$($GREP -c '^PASS ' "$HERE/check-standard-r3.r4-rerun.log" || true)"
  echo "  revision-3 script re-run into a separate file: $V14_PASSES PASS, $V14_FAILS FAIL"
  if [ "$V14_FAILS" -eq 0 ] && [ "$V14_PASSES" -eq 7 ]; then
    pass V14 "re-running the revision-3 script into check-standard-r3.r4-rerun.log yields 7 PASS and 0 FAIL, with its nested revision-2 (42) and offline (28) re-runs passing outright"
  else
    fail V14 "re-running the revision-3 script did not yield exactly 7 PASS and 0 FAIL ($V14_PASSES PASS, $V14_FAILS FAIL)"
  fi
else
  fail V14 "check-standard-r3.sh is absent"
fi

printf '\n=== %d PASS, %d FAIL, %d SKIP ===\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
