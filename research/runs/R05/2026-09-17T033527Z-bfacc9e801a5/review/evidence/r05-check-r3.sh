#!/usr/bin/env bash
# R05 sync-async-execution-model — revision 3 evidence checks (new file; r05-check.sh is untouched).
#
# Why this script exists.
#   The owner re-bound R69 at revision 10 (W0-R69c, 2026-09-18). That revision
#   keeps R69's conclusion and changes its mechanism: the root package's feature
#   is now web = ["dep:rs-launch-blueprint-web"], naming an optional workspace
#   MEMBER, and axum 0.8.9 and tokio 1.53.1 are declared NON-OPTIONALLY inside
#   crates/web/Cargo.toml. R05's decision was measured against R69 revision 9,
#   whose feature named the crates directly (web = ["dep:axum", "dep:tokio"]).
#   This script reads revision 10's owned value FROM ITS RUN FILE, not from the
#   registry (which still carries revision 9's text until R69 republishes), and
#   measures whether R05's conclusion survives the new mechanism.
#
# What it proves, and what it does not.
#   T01-T04 read R69 revision 10's own `- owns web-extra-surface` line, taken
#   from the CURRENT decision only - that file carries a `## Supersedes`
#   section holding the published revision verbatim, so a whole-file search
#   would find revision 9's superseded text as well. T05 is a
#   negative control: the same grep that finds revision 10's member-naming form
#   must NOT find revision 9's crate-naming form in that line, and MUST find it
#   in the registry row - which is the drift R05 revision 3's new re-verify
#   trigger keys on. T06 builds the revision-10 shape as a throwaway Cargo
#   workspace and measures whether a non-optional tokio inside an optional
#   member reaches the root package's default tree. T07 proves the revision-1
#   and revision-2 artifacts are unchanged. Nothing this decision recommends is
#   built: the probe is one root manifest with an empty main and one member
#   manifest with a one-line lib, created under a mktemp directory inside
#   $TMPDIR and deleted on exit. No .git is created anywhere, so no nested
#   repository can be committed.
#
# Reproducibility of the committed log (r05-check-r3.log).
#   Every line is byte-stable on rerun EXCEPT:
#     * "retrieved-on:" - prints today's UTC date, so it advances daily;
#     * T00's "HEAD =" - advances with every commit to this shared branch.
#   T06's counts resolve against the committed p_ws_rev10.Cargo.lock with
#   --locked, so they do not drift; this script prints no wall-clock timing and
#   no counter that moves on its own.
#
# Rerunning from a clean `git archive HEAD` extraction.
#   Supported. T00 is the only check that needs .git (a directory in a clone, a
#   file in a worktree); without it T00 reports SKIP by name and the run still
#   exits 0 when every other check passes.
#
# Requirements: bash, cargo (1.96 or newer), python3, shasum. Network access is
# required for T06's first run only; later runs resolve against the committed
# lockfile. This script prints no token and no environment.

set -o pipefail
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
ROOT="$(cd -- "${SCRIPT_DIR}/../../../../../.." && pwd)"
GREP=/usr/bin/grep

R69_RUN="${ROOT}/research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md"
R69_SHA="d34ab6e8339b6f416a510d070ee54daca38a9086a901a6bfbb9df0517f7fce0a"
REGISTRY="${ROOT}/docs/port/PARAMETERS.md"

PASSED=0
FAILED=0
SKIPPED=0

pass() { PASSED=$((PASSED + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { FAILED=$((FAILED + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
skip() { SKIPPED=$((SKIPPED + 1)); printf 'SKIP %s — %s\n' "$1" "$2"; }
note() { printf '     %s\n' "$1"; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/r05-check-r3.XXXXXX")" || { echo "cannot create work dir"; exit 2; }
# shellcheck disable=SC2329  # invoked indirectly by the EXIT trap below
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

printf '== R05 sync-async-execution-model — revision 3 evidence checks ==\n'
printf 'repository root: %s\n' "$ROOT"
printf 'run directory:   %s\n' "$RUN_DIR"
printf 'toolchain:       %s\n' "$(rustc --version)"
printf 'cargo:           %s\n' "$(cargo --version)"
printf 'host:            %s %s %s\n' "$(uname -s)" "$(uname -r)" "$(uname -m)"
printf 'retrieved-on:    %s (UTC; one of the two lines that advance on rerun)\n' "$(date -u +%Y-%m-%d)"
printf 'grep binary:     %s\n' "$GREP"
printf '\n'

# ---------------------------------------------------------------------------
# T00 — provenance of the tree the content assertions read.
# ---------------------------------------------------------------------------
if [ -e "${ROOT}/.git" ]; then   # a directory in a normal clone, a file in a git worktree
  HEAD_SHA="$(git -C "$ROOT" rev-parse HEAD)"
  rc=$?
  if [ "$rc" -eq 0 ] && [ -n "$HEAD_SHA" ]; then
    pass T00 "repository HEAD resolved"
    note "HEAD = ${HEAD_SHA}"
  else
    fail T00 "git rev-parse HEAD failed (exit ${rc})"
  fi
else
  skip T00 "no .git entry (git archive extraction); content checks T01-T05 and T07 still run"
fi

# ---------------------------------------------------------------------------
# T01 — the R69 revision-10 run file this revision reads, pinned by digest.
# ---------------------------------------------------------------------------
if [ -f "$R69_RUN" ]; then
  got_sha="$(shasum -a 256 "$R69_RUN" | awk '{print $1}')"
  if [ "$got_sha" = "$R69_SHA" ]; then
    pass T01 "R69 revision 10's run DECISION.md matches the owner-bound digest"
    note "file: research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md"
    note "sha256 = ${got_sha} (owner acceptance W0-R69c, 2026-09-18)"
  else
    fail T01 "digest mismatch: got ${got_sha}, expected ${R69_SHA}"
  fi
else
  fail T01 "R69 revision 10 run file not found at ${R69_RUN}"
fi

# Extract revision 10's owned line once, from the run file and not the registry,
# and from the CURRENT decision only. R69's revision-10 file carries a
# `## Supersedes` section holding the previously published decision verbatim, so
# a whole-file search finds two `- owns web-extra-surface` lines and the second
# is revision 9's superseded text. Everything below reads the first section only.
python3 - "$R69_RUN" "${WORK}/owns-line.txt" "${WORK}/owns-superseded.txt" > "${WORK}/owns-lineno.txt" <<'CURRENTOWNS'
import sys

path, current_out, superseded_out = sys.argv[1], sys.argv[2], sys.argv[3]
lines = open(path, encoding="utf-8").read().splitlines(keepends=True)
cut = len(lines)
for i, line in enumerate(lines):
    if line.rstrip("\n") == "## Supersedes":
        cut = i
        break
prefix = "- owns web-extra-surface = "
current = [(i + 1, l) for i, l in enumerate(lines[:cut]) if l.startswith(prefix)]
superseded = [(i + 1, l) for i, l in enumerate(lines[cut:], start=cut) if l.startswith(prefix)]
open(current_out, "w", encoding="utf-8").writelines(l for _, l in current)
open(superseded_out, "w", encoding="utf-8").writelines(l for _, l in superseded)
print(len(current), len(superseded), cut + 1, " ".join(str(n) for n, _ in current))
CURRENTOWNS
owns_rc=$?
read -r owns_hits owns_superseded_hits supersedes_lineno owns_lineno < "${WORK}/owns-lineno.txt"

# ---------------------------------------------------------------------------
# T02 — the feature now names the optional workspace MEMBER, not the crates.
# ---------------------------------------------------------------------------
member_form="$($GREP -c 'web = \["dep:rs-launch-blueprint-web"\]' "${WORK}/owns-line.txt")"
declared_on_root="$($GREP -c 'declared on the root package rs-launch-blueprint' "${WORK}/owns-line.txt")"
if [ "$owns_rc" -eq 0 ] && [ "$owns_hits" = "1" ] && [ "$owns_lineno" = "1791" ] \
   && [ "$member_form" = "1" ] && [ "$declared_on_root" = "1" ]; then
  pass T02 "R69 revision 10's feature is web = [\"dep:rs-launch-blueprint-web\"], declared on the root package"
  note "the current decision ends at the '## Supersedes' heading on line ${supersedes_lineno}; it carries exactly ${owns_hits} '- owns web-extra-surface' line, at line ${owns_lineno}, and the superseded section carries ${owns_superseded_hits}"
  note "${GREP} -c matches inside the current owned line: member-naming feature=${member_form}, 'declared on the root package'=${declared_on_root}"
else
  fail T02 "extraction rc=${owns_rc}; current owns lines=${owns_hits} (want 1) at line ${owns_lineno} (want 1791), member-naming feature=${member_form}, root-package clause=${declared_on_root}"
fi

# ---------------------------------------------------------------------------
# T03 — axum and tokio are NON-OPTIONAL, inside the member's own manifest.
# ---------------------------------------------------------------------------
axum_nonopt="$($GREP -c 'axum 0\.8\.9 declared non-optionally in crates/web/Cargo\.toml' "${WORK}/owns-line.txt")"
tokio_nonopt="$($GREP -c 'tokio 1\.53\.1 declared non-optionally in crates/web/Cargo\.toml with features rt-multi-thread, net, signal, macros, time, sync' "${WORK}/owns-line.txt")"
if [ "$axum_nonopt" = "1" ] && [ "$tokio_nonopt" = "1" ]; then
  pass T03 "axum 0.8.9 and tokio 1.53.1 are declared non-optionally in crates/web/Cargo.toml, at the same versions and the same six tokio features"
  note "${GREP} -c matches inside the owned line: non-optional axum=${axum_nonopt}, non-optional tokio with the six features=${tokio_nonopt}"
  note "consequence: R05's criterion 2 (a dep: clause requires an optional dependency) no longer applies to axum or tokio, because the feature no longer names them"
else
  fail T03 "non-optional axum=${axum_nonopt}, non-optional tokio=${tokio_nonopt}"
fi

# ---------------------------------------------------------------------------
# T04 — the gated tree moved into the member: handlers under crates/web/src/,
#       tests under crates/web/tests/, with no file-level cfg gate.
# ---------------------------------------------------------------------------
src_tree="$($GREP -c 'the library module crates/web/src/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until' "${WORK}/owns-line.txt")"
tests_tree="$($GREP -c 'the web integration tests in crates/web/tests/, with no file-level #!\[cfg(feature = "web")\] because the whole member is optional' "${WORK}/owns-line.txt")"
if [ "$src_tree" = "1" ] && [ "$tests_tree" = "1" ]; then
  pass T04 "the axum handlers live under crates/web/src/ and the web tests under crates/web/tests/, with the whole member optional instead of a file-level cfg gate"
  note "${GREP} -c matches inside the owned line: crates/web/src/ module clause=${src_tree}, crates/web/tests/ clause=${tests_tree}"
  note "consequence: R05's spawn_blocking bridge lives inside the optional member, which is where the handlers are"
else
  fail T04 "crates/web/src/ clause=${src_tree}, crates/web/tests/ clause=${tests_tree}"
fi

# ---------------------------------------------------------------------------
# T05 — NEGATIVE CONTROL. The same search that finds revision 10's member form
#       must NOT find revision 9's crate-naming form in revision 10's owned
#       line, and MUST still find it in the registry row. A grep that matched
#       everything would fail here; so would a claim that the registry has
#       already been rewritten.
# ---------------------------------------------------------------------------
python3 - "$REGISTRY" > "${WORK}/registry-cell.txt" <<'PYEOF'
import sys
for line in open(sys.argv[1], encoding="utf-8"):
    if line.startswith("| web-extra-surface |"):
        sys.stdout.write(line.split(" | ")[3])
        break
PYEOF
reg_rc=$?
rev9_in_rev10="$($GREP -c 'web = \["dep:axum", "dep:tokio"\]' "${WORK}/owns-line.txt")"
rev9_in_superseded="$($GREP -c 'web = \["dep:axum", "dep:tokio"\]' "${WORK}/owns-superseded.txt")"
rev9_in_registry="$($GREP -c 'web = \["dep:axum", "dep:tokio"\]' "${WORK}/registry-cell.txt")"
rev10_in_registry="$($GREP -c 'web = \["dep:rs-launch-blueprint-web"\]' "${WORK}/registry-cell.txt")"
if [ "$reg_rc" -eq 0 ] && [ "$rev9_in_rev10" = "0" ] && [ "$rev9_in_superseded" = "1" ] \
   && [ "$rev9_in_registry" = "1" ] && [ "$rev10_in_registry" = "0" ]; then
  pass T05 "negative control: revision 9's web = [\"dep:axum\", \"dep:tokio\"] is absent from revision 10's current owned line, and still present both in that file's superseded section and in the registry row"
  note "${GREP} -c counts for the revision-9 form: current owned line=${rev9_in_rev10} (want 0), superseded section=${rev9_in_superseded} (want 1), registry row=${rev9_in_registry} (want 1)"
  note "${GREP} -c count for the revision-10 form in the registry row=${rev10_in_registry} (want 0)"
  note "the control discriminates in two directions: a search that matched everything would find the revision-9 form in the current line, and a search that matched nothing would miss it in the two places it really is"
  note "consequence: the registry has NOT yet been rewritten, which is exactly what R05 revision 3's new re-verify trigger keys on - R05 check C02's registry read is re-run when R69 republishes"
else
  fail T05 "registry extraction rc=${reg_rc}; rev9-in-current=${rev9_in_rev10} (want 0), rev9-in-superseded=${rev9_in_superseded} (want 1), rev9-in-registry=${rev9_in_registry} (want 1), rev10-in-registry=${rev10_in_registry} (want 0)"
fi

# ---------------------------------------------------------------------------
# T06 — the measurement that matters: under revision 10's shape, does a
#       NON-OPTIONAL tokio inside an OPTIONAL member reach the root package's
#       default dependency tree? The probe transcribes revision 10's shape: a
#       root package whose only path to the web crates is an optional member
#       dependency named by the feature, and a member whose own manifest
#       declares axum and tokio non-optionally. Root dependencies otherwise
#       match R05 check C10's probe (ureq + serde + serde_json) so the
#       feature-off count is directly comparable with C10's 38.
# ---------------------------------------------------------------------------
mkdir -p "${WORK}/p_ws_rev10/src" "${WORK}/p_ws_rev10/crates/web/src"
cat > "${WORK}/p_ws_rev10/Cargo.toml" <<'EOF'
[package]
name = "rs-launch-blueprint"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"

[dependencies]
ureq = { version = "3.4.2", features = ["json"] }
serde = { version = "1.0.229", features = ["derive"] }
serde_json = "1.0.151"
rs-launch-blueprint-web = { path = "crates/web", optional = true }

[features]
web = ["dep:rs-launch-blueprint-web"]

[workspace]
members = ["crates/web"]
EOF
echo 'fn main() {}' > "${WORK}/p_ws_rev10/src/main.rs"
cat > "${WORK}/p_ws_rev10/crates/web/Cargo.toml" <<'EOF'
[package]
name = "rs-launch-blueprint-web"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"

[dependencies]
axum = "0.8.9"
tokio = { version = "1.53.1", features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }
EOF
echo 'pub fn build_router() {}' > "${WORK}/p_ws_rev10/crates/web/src/lib.rs"

if [ -f "${SCRIPT_DIR}/p_ws_rev10.Cargo.lock" ]; then
  cp "${SCRIPT_DIR}/p_ws_rev10.Cargo.lock" "${WORK}/p_ws_rev10/Cargo.lock"
else
  ( cd "${WORK}/p_ws_rev10" && cargo generate-lockfile -q 2>> "${WORK}/cargo.err" ) \
    && cp "${WORK}/p_ws_rev10/Cargo.lock" "${SCRIPT_DIR}/p_ws_rev10.Cargo.lock"
  note "first run: generated and snapshotted p_ws_rev10.Cargo.lock; later runs reuse it with --locked"
fi

( cd "${WORK}/p_ws_rev10" && cargo metadata --no-deps --format-version 1 ) > "${WORK}/ws-metadata.json" 2>> "${WORK}/cargo.err"
ws_parse_rc=$?
ws_off="$( ( cd "${WORK}/p_ws_rev10" && cargo tree --prefix none -e normal --locked 2>> "${WORK}/cargo.err" ) | sed 's/ (\*)$//' | awk 'NF' | sort -u | wc -l | tr -d ' ')"
ws_on="$( ( cd "${WORK}/p_ws_rev10" && cargo tree --prefix none -e normal --locked --features web 2>> "${WORK}/cargo.err" ) | sed 's/ (\*)$//' | awk 'NF' | sort -u | wc -l | tr -d ' ')"
( cd "${WORK}/p_ws_rev10" && cargo tree -i tokio -e normal --locked ) > "${WORK}/ws-tokio-off.txt" 2>&1
ws_tokio_off_rc=$?
( cd "${WORK}/p_ws_rev10" && cargo tree -i tokio -e normal --locked --features web ) > "${WORK}/ws-tokio-on.txt" 2>&1
ws_tokio_on_rc=$?
ws_tokio_on_hit="$($GREP -c '^tokio v1\.53\.1$' "${WORK}/ws-tokio-on.txt")"
( cd "${WORK}/p_ws_rev10" && cargo tree --prefix none -e normal --locked --features web 2>> "${WORK}/cargo.err" ) \
  | $GREP -c '^rs-launch-blueprint-web v0\.0\.0' > "${WORK}/member-on.txt"
ws_member_on="$(cat "${WORK}/member-on.txt")"
if [ "$ws_parse_rc" -eq 0 ] && [ "$ws_off" = "38" ] && [ "$ws_on" = "72" ] \
   && [ "$ws_tokio_off_rc" -ne 0 ] && [ "$ws_tokio_on_rc" -eq 0 ] && [ "$ws_tokio_on_hit" = "1" ] && [ "$ws_member_on" -ge 1 ]; then
  pass T06 "under R69 revision 10's shape the root package's default tree still carries no tokio, and --features web still pulls tokio v1.53.1"
  note "cargo metadata on the revision-10 manifest pair exit=${ws_parse_rc} (the dep:<member> clause is legal against an optional PATH member, and the member's own non-optional axum/tokio are not the feature's business)"
  note "cargo tree counts (unique normal deps, root included): feature-off=${ws_off}, feature-on=${ws_on}"
  note "cargo tree -i tokio: feature-off exit=${ws_tokio_off_rc} (not found), feature-on exit=${ws_tokio_on_rc} with ${GREP} matches for 'tokio v1.53.1'=${ws_tokio_on_hit}"
  note "the member crate rs-launch-blueprint-web appears in the feature-on tree ${ws_member_on} time(s) and is the whole of the +1 against R05 check C10's feature-on 71"
  note "the finding: R05's conclusion is unchanged by R69 revision 10 - the default tree is 38 crates with no runtime, exactly as C10 measured against revision 9, and criterion 1's cargo tree -i tokio -e normal on the root package remains the operative check"
else
  fail T06 "parse rc=${ws_parse_rc}; off=${ws_off} (want 38), on=${ws_on} (want 72), tokio-off-rc=${ws_tokio_off_rc}, tokio-on-rc=${ws_tokio_on_rc}, tokio-on-hit=${ws_tokio_on_hit}, member-on=${ws_member_on}"
  note "captured cargo stderr: $(head -3 "${WORK}/cargo.err" 2>/dev/null)"
fi

# ---------------------------------------------------------------------------
# T07 — the revision-1 and revision-2 artifacts are untouched by this revision.
# ---------------------------------------------------------------------------
artifacts_ok=1
while IFS=' ' read -r want name; do
  [ -n "$name" ] || continue
  if [ ! -f "${SCRIPT_DIR}/${name}" ]; then
    artifacts_ok=0
    note "missing prior artifact: ${name}"
    continue
  fi
  got="$(shasum -a 256 "${SCRIPT_DIR}/${name}" | awk '{print $1}')"
  note "${name} sha256=${got}"
  [ "$got" = "$want" ] || artifacts_ok=0
done <<'ARTIFACTS'
e036bb2833c4263cd680627754f5ef792c87d82dea94e0e3e401ead1d1779459 r05-check.sh
610bf43d97c41039c6929f5daf1702f23618af5f3df217a50dedb9e85593df1e r05-check.log
c961172b3cd6e657462acf93d43913ab7dc97f903dd777c5a0c5e5f541ed6da5 r05-check-archive-r2.log
abcfd78e46fd7f2ff89a7bb3d43d4d62510a3aed9cf098c72ed82eee991850a1 p_scen_sync.Cargo.lock
4be720643bfcf535430f70f8e652eda51d746dcd7bd62bb86cc13d4892efcef9 p_scen_async.Cargo.lock
48d4aa737bdafbc28bb606a09849c32265381bb0c0db4b38263210ee8729961b p_scen_async_defaults.Cargo.lock
ARTIFACTS
if [ "$artifacts_ok" = "1" ]; then
  pass T07 "the six revision-1 and revision-2 evidence artifacts are byte-identical to their committed digests"
else
  fail T07 "at least one prior artifact is missing or its digest moved; see the per-file lines above"
fi

printf '\n== summary ==\n'
printf 'passed=%d failed=%d skipped=%d\n' "$PASSED" "$FAILED" "$SKIPPED"
if [ "$FAILED" -gt 0 ]; then
  printf 'RESULT: FAIL\n'
  exit 1
fi
printf 'RESULT: PASS\n'
exit 0
